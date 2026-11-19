@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/io/phone_clip_player.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_graph.dart';
import 'support/sfx.dart';

/// The expected calls: juego.js run in node on a recording AudioContext (tool/juego_sonido.mjs).
final Map<String, dynamic> _fixture = jsonDecode(
  File('test/fixtures/juego_sonido.json').readAsStringSync(),
) as Map<String, dynamic>;

List<Object?> _expected(String key) =>
    ((_fixture['scenarios'] as Map<String, dynamic>)[key] as List)
        .where((e) => (e as List).first != 'timer')
        .toList();

ClipInfo _info(String id, int startMs, int endMs) => ClipInfo(
  id: id,
  who: 'narr',
  text: '',
  startMs: startMs,
  endMs: endMs,
  url: 'audio/$id.mp3?v=7',
);

/// A player on a recording graph. Clips: ab_bien_y_tu (198..4462 ms, its marks in marcas.json) and x
/// (1..21 ms). Each fetched file's bytes are its id.
class _Rig {
  _Rig() {
    core = SoundCore(
      () => graph = RecordingGraph(log),
      random: () => .25,
      startTimer: (d, f) {
        timers.add((d, f));
        return Timer(const Duration(days: 1), () {});
      },
    );
    player = GraphClipPlayer(
      core: core,
      clipInfo: (id) => switch (id) {
        'ab_bien_y_tu' => _info(id, 198, 4462),
        'x' => _info(id, 1, 21),
        _ => null,
      },
      base: Uri.parse('https://example.test/historia/'),
      fetch: (u) async {
        fetched.add(u);
        return Uint8List.fromList(
          u.pathSegments.last.split('.').first.codeUnits,
        );
      },
    );
  }

  final List<List<Object?>> log = [];
  final List<Uri> fetched = [];
  final List<(Duration, void Function())> timers = [];
  RecordingGraph? graph;
  late final SoundCore core;
  late final GraphClipPlayer player;
  late final Map<String, void Function()> sfx = sfxTable(player);

  void endLast() => graph!.sources.last.ended!();
}

/// A graph whose decode fails for the files whose bytes (their id) are in [broken].
class _DecodeGraph extends RecordingGraph {
  _DecodeGraph(this.broken) : super([]);
  final Set<String> broken;

  @override
  Future<AudioBufferH> decodeAudioData(Uint8List bytes) {
    if (broken.contains(String.fromCharCodes(bytes))) {
      throw const FormatException('EncodingError: unable to decode audio data');
    }
    return super.decodeAudioData(bytes);
  }
}

/// A player whose clips are every id but 'none' (no ClipInfo); a fetch fails for the ids in [noFile], a
/// decode for the ids in [noDecode]. Each fetched file's bytes are its id.
class _Flaky {
  _Flaky() {
    player = GraphClipPlayer(
      core: SoundCore(() => graph),
      clipInfo: (id) => id == 'none' ? null : _info(id, 0, 1000),
      base: Uri.parse('https://example.test/'),
      fetch: (u) async {
        final id = u.pathSegments.last.split('.').first;
        fetched.add(id);
        if (noFile.contains(id)) throw const SocketExceptionLike();
        return Uint8List.fromList(id.codeUnits);
      },
    );
  }

  final Set<String> noFile = {}, noDecode = {};
  final List<String> fetched = [];
  late final _DecodeGraph graph = _DecodeGraph(noDecode);
  late final GraphClipPlayer player;
}

Future<void> _scenario(String key, Future<void> Function(_Rig r) f) async {
  final r = _Rig();
  await f(r);
  expect(r.log, _expected(key), reason: key);
}

void main() {
  final names = (_fixture['sfx'] as List).cast<String>();

  group('the made sounds equal juego.js\'s calls on its AudioContext', () {
    test('juego.js has the 18 SFX names, and the table here has each', () {
      expect(names, hasLength(18));
      expect(sfxTable(_Rig().player).keys, names);
    });
    for (final n in names) {
      test('SFX.$n', () => _scenario('SFX.$n', (r) async => r.sfx[n]!()));
    }
    test(
      'SFX.trueno(0.6)',
      () => _scenario('SFX.trueno(0.6)', (r) async {
        r.player.noiseBurst(vol: .6);
      }),
    );
    test(
      'one noise buffer for the thunder and the rain',
      () =>
          _scenario('SFX.trueno then SFX.lluvia (one noise buffer)', (r) async {
            r.player.noiseBurst();
            r.player.loop('rain', true);
          }),
    );
    test(
      'the rain starts once and stops once',
      () => _scenario('SFX.lluvia twice, SFX.calla twice', (r) async {
        r.player.loop('rain', true);
        r.player.loop('rain', true);
        r.player.loop('rain', false);
        r.player.loop('rain', false);
      }),
    );
    test('loop is idempotent: rain off with no rain does nothing; rain on twice starts one rain', () {
      final r = _Rig();
      r.player.loop('rain', false);
      expect(r.log, isEmpty); // not even a context
      r.player.loop('rain', true);
      final made = r.graph!.sources.length;
      r.player.loop('rain', true);
      r.player.loop('rain', true);
      expect(r.graph!.sources.length, made);
      r.player.loop('rain', false);
      final n = r.log.length;
      r.player.loop('rain', false);
      expect(r.log.length, n);
      expect(r.core.rain, isNull);
      r.player.loop('rain', true); // and it can start again
      expect(r.graph!.sources.length, made + 1);
    });
    test(
      'tone\'s defaults',
      () => _scenario('tone(440,0,.1)', (r) async => r.player.tone(440)),
    );
    test(
      'tone: a zero volume is .05, a zero end frequency is no ramp',
      () => _scenario("tone(440,.25,.3,'sine',0,0)", (r) async {
        r.player.tone(440, at: .25, dur: .3, wave: 'sine', vol: 0, toHz: 0);
      }),
    );
    test('the noise is white noise in [-1, 1), two seconds of it', () {
      final r = _Rig();
      r.player.noiseBurst();
      final b = r.core.noise();
      expect(b.length, 88200);
      expect(
        b.channel(0).every((v) => v == -.5),
        isTrue,
      ); // random() = .25 here
    });
  });

  group('muted', () {
    test(
      'tones are not made; the thunder and the rain go through the master gain at 0',
      () => _scenario('muted: SFX.right, SFX.trueno, SFX.lluvia', (r) async {
        r.player.muted = true;
        r.sfx['right']!();
        r.sfx['trueno']!();
        r.sfx['lluvia']!();
      }),
    );
    test(
      'the sound button sets the master gain at once',
      () => _scenario('SFX.lluvia, then the sound button twice', (r) async {
        r.player.loop('rain', true);
        r.player.muted = true;
        r.player.muted = false;
      }),
    );
    test(
      'a clip played muted keeps its timing',
      () => _scenario('playClip while muted, then the sound button', (r) async {
        await r.player.preload(['ab_bien_y_tu']);
        r.player.muted = true;
        final p = r.player.play('ab_bien_y_tu');
        await Future<void>.delayed(Duration.zero);
        r.player.muted = false;
        r.endLast();
        r.log.add(['resolved', await p]);
      }),
    );
  });

  group('clips', () {
    test(
      'a clip plays from its start mark to its end mark, and gives true at its end',
      () => _scenario('playClip ab_bien_y_tu, to its end', (r) async {
        await r.player.preload(['ab_bien_y_tu']);
        final p = r.player.play('ab_bien_y_tu');
        await Future<void>.delayed(Duration.zero);
        r.endLast();
        r.log.add(['resolved', await p]);
      }),
    );
    test(
      'a clip shorter than 50 ms plays 50 ms',
      () => _scenario('playClip of a clip shorter than 50 ms', (r) async {
        await r.player.preload(['x']);
        final p = r.player.play('x');
        await Future<void>.delayed(Duration.zero);
        r.endLast();
        r.log.add(['resolved', await p]);
      }),
    );
    test(
      'stop ends every clip playing with false',
      () => _scenario('playClip, then hush', (r) async {
        await r.player.preload(['ab_bien_y_tu']);
        final p = r.player.play('ab_bien_y_tu');
        await Future<void>.delayed(Duration.zero);
        await r.player.stop();
        r.log.add(['resolved', await p]);
      }),
    );
    test(
      'with a time limit, the clip is stopped at the limit and gives false',
      () => _scenario('playClip after a speaking turn (the time limit fires)', (
        r,
      ) async {
        await r.player.preload(['ab_bien_y_tu']);
        final limit = Duration(
          microseconds: ((4462 - 198) / 1000 * 1000 + 1000).round() * 1000,
        );
        final p = r.player.play('ab_bien_y_tu', limit: limit);
        await Future<void>.delayed(Duration.zero);
        expect(r.timers.single.$1, limit);
        r.timers.single.$2();
        r.log.add(['resolved', await p]);
      }),
    );
    test(
      'an unknown clip gives false and makes nothing',
      () => _scenario('playClip of an unknown clip', (r) async {
        r.log.add(['resolved', await r.player.play('nada')]);
      }),
    );
    test(
      'preload fetches and decodes each clip once, from base + url',
      () async {
        final r = _Rig();
        await Future.wait([
          r.player.preload(['ab_bien_y_tu', 'x', 'ab_bien_y_tu']),
          r.player.preload(['x']),
        ]);
        await r.player.preload(['x']);
        expect(r.fetched.map((u) => '$u'), [
          'https://example.test/historia/audio/ab_bien_y_tu.mp3?v=7',
          'https://example.test/historia/audio/x.mp3?v=7',
        ]);
        expect(r.graph!.decoded, hasLength(2));
        expect(r.core.clips['ab_bien_y_tu']!.t0, .198);
        expect(r.core.clips['ab_bien_y_tu']!.t1, 4.462);
        final p = r.player.play('x');
        await Future<void>.delayed(Duration.zero);
        expect(r.fetched, hasLength(2));
        r.endLast();
        expect(await p, isTrue);
      },
    );
    test(
      'a clip whose file cannot be had gives false; a later call tries again',
      () async {
        var fail = true;
        final g = RecordingGraph([]);
        final p = GraphClipPlayer(
          core: SoundCore(() => g),
          clipInfo: (id) => _info(id, 0, 1000),
          base: Uri.parse('https://example.test/'),
          fetch: (u) async {
            if (fail) throw const SocketExceptionLike();
            return Uint8List.fromList([1]);
          },
        );
        expect(await p.play('a'), isFalse);
        fail = false;
        final f = p.play('a');
        await Future<void>.delayed(Duration.zero);
        g.sources.single.ended!();
        expect(await f, isTrue);
      },
    );
    test('unlock makes the context and resumes it', () async {
      final r = _Rig();
      var hook = 0;
      final p = GraphClipPlayer(
        core: r.core,
        clipInfo: (_) => null,
        base: Uri(),
        fetch: (_) async => Uint8List(0),
        onUnlock: () => hook++,
      );
      await p.unlock();
      await p.unlock();
      expect(hook, 2);
      expect(r.graph!.resumes, 2);
      expect(r.log.first, ['new', 'context']);
    });
  });

  group('preload gives back the clips that could not be made ready', () {
    test('every clip ready: an empty list', () async {
      final r = _Rig();
      expect(await r.player.preload(['ab_bien_y_tu', 'x']), isEmpty);
      expect(await r.player.preload(const []), isEmpty);
      expect(r.core.clips.keys, containsAll(['ab_bien_y_tu', 'x']));
    });
    test(
      'a clip with no ClipInfo is reported, and nothing is fetched for it',
      () async {
        final r = _Rig();
        expect(await r.player.preload(['nada']), ['nada']);
        expect(r.fetched, isEmpty);
      },
    );
    test(
      'a clip whose fetch fails is reported; the others are ready',
      () async {
        final f = _Flaky()..noFile.add('b');
        expect(await f.player.preload(['a', 'b', 'c']), ['b']);
        expect(f.fetched, ['a', 'b', 'c']);
        expect(f.player.core.clips.keys, ['a', 'c']);
      },
    );
    test(
      'a clip whose decode fails is reported; the others are ready',
      () async {
        final f = _Flaky()..noDecode.add('b');
        expect(await f.player.preload(['a', 'b', 'c']), ['b']);
        expect(f.fetched, ['a', 'b', 'c']);
        expect(f.player.core.clips.keys, ['a', 'c']);
      },
    );
    test('a retry after a failure tries again, and gives an empty list when it works', () async {
      final f = _Flaky()
        ..noFile.add('a')
        ..noDecode.add('b');
      expect(await f.player.preload(['a', 'b', 'c']), ['a', 'b']);
      expect(f.fetched, ['a', 'b', 'c']);
      expect(await f.player.preload(['a', 'b', 'c']), ['a', 'b']);
      expect(f.fetched, [
        'a',
        'b',
        'c',
        'a',
        'b',
      ]); // c is loaded: not fetched again
      f
        ..noFile.clear()
        ..noDecode.clear();
      expect(await f.player.preload(['a', 'b', 'c']), isEmpty);
      expect(f.fetched, ['a', 'b', 'c', 'a', 'b', 'a', 'b']);
      expect(
        f.graph.decoded,
        hasLength(3),
      ); // c, a, b: each decoded once, c not again
      expect(f.player.core.clips.keys, ['c', 'a', 'b']);
    });
    test('the ids come in the order given, each once', () async {
      final f = _Flaky()
        ..noFile.add('e')
        ..noDecode.add('d');
      expect(
        await f.player.preload([
          'e',
          'a',
          'none',
          'd',
          'e',
          'a',
          'none',
          'd',
          'b',
        ]),
        ['e', 'none', 'd'],
      );
      expect(f.fetched, ['e', 'a', 'd', 'b']);
    });
    test(
      'a clip already loaded is not loaded again and is not reported',
      () async {
        final f = _Flaky();
        expect(await f.player.preload(['a']), isEmpty);
        f.noFile.add('a');
        f.noDecode.add('a');
        expect(await f.player.preload(['a', 'a']), isEmpty);
        expect(f.fetched, ['a']);
        expect(f.graph.decoded, hasLength(1));
      },
    );
    test(
      'two preloads at once of a clip that fails: both report it, one fetch',
      () async {
        final f = _Flaky()..noFile.add('a');
        final both = await Future.wait([
          f.player.preload(['a', 'b']),
          f.player.preload(['a']),
        ]);
        expect(both, [
          ['a'],
          ['a'],
        ]);
        expect(f.fetched, ['a', 'b']);
      },
    );
    test('it takes any iterable, read once', () async {
      final f = _Flaky()..noFile.add('b');
      expect(await f.player.preload({'a', 'b'}.map((id) => id)), ['b']);
    });
  });

  group('PhoneClipPlayer.preload, against a server on this machine', () {
    // A file is had when its id starts with 'ok', refused (404) when it starts with 'no' (and when it
    // starts with 'late', until [lateReady]), cut off when it starts with 'cut' (200, then the connection
    // closes before the body).
    late HttpServer server;
    late Uri base;
    final hits = <String>[];
    var lateReady = false;

    PhoneClipPlayer make({Uri? at}) => PhoneClipPlayer(
      effects: SoundCore(() => RecordingGraph([])),
      clipInfo: (id) => id == 'none' ? null : _info(id, 0, 1000),
      base: at ?? base,
    );

    setUp(() async {
      hits.clear();
      lateReady = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}/historia/');
      server.listen((rq) async {
        final id = rq.uri.pathSegments.last.split('.').first;
        hits.add(id);
        if (id.startsWith('no') || (id.startsWith('late') && !lateReady)) {
          rq.response.statusCode = 404;
        } else if (id.startsWith('cut')) {
          final c = await rq.response.detachSocket(writeHeaders: false);
          c.write('HTTP/1.1 200 OK\r\ncontent-length: 100\r\n\r\nabc');
          await c.flush();
          c.destroy();
          return;
        } else {
          rq.response.add(id.codeUnits);
        }
        await rq.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    test('every clip had: an empty list', () async {
      final p = make();
      expect(await p.preload(['ok1', 'ok2']), isEmpty);
      expect(await p.preload(const []), isEmpty);
      expect(hits, ['ok1', 'ok2']);
    });
    test(
      'no ClipInfo, a refused file, a cut-off file: each reported',
      () async {
        final p = make();
        expect(await p.preload(['ok1', 'none', 'no1', 'cut1']), [
          'none',
          'no1',
          'cut1',
        ]);
        expect(
          hits,
          unorderedEquals(['ok1', 'no1', 'cut1']),
        ); // none: no request
      },
    );
    test('a server that cannot be reached: every clip reported', () async {
      final dead = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final gone = Uri.parse('http://127.0.0.1:${dead.port}/');
      await dead.close(force: true);
      expect(await make(at: gone).preload(['ok1', 'ok2']), ['ok1', 'ok2']);
    });
    test(
      'a retry after a refusal fetches again, and then the clip is ready',
      () async {
        final p = make();
        expect(await p.preload(['late1']), ['late1']);
        lateReady = true;
        expect(await p.preload(['late1']), isEmpty);
        expect(await p.preload(['late1']), isEmpty);
        expect(hits, ['late1', 'late1']);
      },
    );
    test('order, no duplicates, a loaded clip not fetched again, a retry fetches again', () async {
      final p = make();
      expect(await p.preload(['ok1']), isEmpty);
      expect(
        await p.preload(['no1', 'ok1', 'none', 'no2', 'no1', 'ok1', 'none']),
        ['no1', 'none', 'no2'],
      );
      expect(hits.where((h) => h == 'ok1'), hasLength(1));
      expect(hits.where((h) => h == 'no1'), hasLength(1));
      expect(await p.preload(['no2', 'no1']), ['no2', 'no1']);
      expect(hits.where((h) => h == 'no1'), hasLength(2));
      expect(hits.where((h) => h == 'no2'), hasLength(2));
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
