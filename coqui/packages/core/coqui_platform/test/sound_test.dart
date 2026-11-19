import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_graph.dart';
import 'support/sfx.dart';

/// The expected calls: juego.js run in node on a recording AudioContext (tool/juego_sonido.mjs).
final Map<String, dynamic> _fixture =
    jsonDecode(File('test/fixtures/juego_sonido.json').readAsStringSync())
        as Map<String, dynamic>;

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
        return Uint8List.fromList(u.pathSegments.last.split('.').first.codeUnits);
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
      () => _scenario('SFX.trueno then SFX.lluvia (one noise buffer)', (
        r,
      ) async {
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
      expect(b.channel(0).every((v) => v == -.5), isTrue); // random() = .25 here
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
      () => _scenario('playClip while muted, then the sound button', (
        r,
      ) async {
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
    test('preload fetches and decodes each clip once, from base + url', () async {
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
    });
    test('a clip whose file cannot be had gives false; a later call tries again', () async {
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
    });
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
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
