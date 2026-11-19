// The six tests. Each writes its result lines into its card; the page shows them and mirrors them to
// window.__results (for scripts) and to the "Copy results" text.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'browser.dart';
import 'plugin_audio.dart';
import 'speech.dart';
import 'web_audio.dart';

const kBuild = 'v=1';

/// Ten lines story 1 (La lluvia) opens with, in its order.
const kLines = [
  'esta_casa',
  'mira_casa',
  'puedes_casa',
  'muy_bien',
  'esta_puerta',
  'cerrada',
  'donde_puerta',
  'mira_ventana',
  'tambien_cerrada',
  'toca_ventana',
];
const kAsk = 'hola_quien'; // "Abuela dice: ¡Hola, hola! ¿Quién es?" (test 2, before he speaks)
const kAfter = 'muy_bien'; // "¡Muy bien!" (test 2, after he speaks)
const kSilent = 'es_abuela'; // "¡Mira! Es abuela." (test 4)
const kAll = [...kLines, kAsk, kSilent];

const kMarkerKey = 'coqui.prueba.marca';
const kWordsKey = 'coqui.palabras.v1';

String clipPath(String id) => '../historia/audio/$id.mp3';
Uri clipUri(String id) => Uri.parse(web.document.baseURI).resolve(clipPath(id));

class Clip {
  Clip(this.id);
  final String id;
  Uint8List? bytes;
  Marks?
  offline; // decoded at 48 kHz with an OfflineAudioContext, before any tap
  web.AudioBuffer? buf; // decoded in the live context (after the first tap)
  Marks? live;
  String error = '';
}

class Card {
  Card(this.n, this.title, this.hint);
  final int n;
  final String title, hint;
  List<String> lines = [];
  String status = 'not run'; // not run / running / done
}

class Ask {
  Ask(this.question, this.options);
  final String question;
  final List<String> options;
  final Completer<String> answer = Completer<String>();
}

double median(List<double> v) {
  if (v.isEmpty) return double.nan;
  final s = [...v]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

String gapsLine(List<double> g) {
  if (g.isEmpty) return 'no gaps measured';
  final mx = g.reduce((a, b) => a > b ? a : b);
  return '${g.map(ms).join(' ')} | max ${ms(mx)}, median ${ms(median(g))}';
}

/// docs/hablar/01-decisiones.md's normaliser and "heard right" rule.
String norm(String s) {
  var t = s.toLowerCase();
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final ch in t.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  t = b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  return ' $t ';
}

bool heardRight(List<String> alts, List<List<String>> targets) => targets.every(
  (forms) => forms.any((f) {
    final k = ' ${norm(f).trim()} ';
    return alts.any((a) => norm(a).contains(k));
  }),
);

class Lab extends ChangeNotifier {
  Lab({required this.mainMs, required this.sessionNote});
  final double mainMs; // Dart main() started, ms since navigation start
  final String sessionNote; // what navigator.audioSession did at start

  final wa = WebAudio();
  final plugin = PluginAudio();
  final speech = Speech();
  final clips = {for (final id in kAll) id: Clip(id)};
  final _clipsReady = Completer<void>();
  String clipsNote = 'loading';
  double? firstFrameDart; // first frame rasterized, seen from Dart

  final cards = [
    Card(
      1,
      'Lines',
      'Ten recorded lines back to back, twice: the audio plugin, then Web Audio. About 35 s.',
    ),
    Card(
      2,
      'Mic in stories',
      'Say "hola, abuela" when asked. Then 5 rounds: a line plays, tap MIC and say "hola", a line plays.',
    ),
    Card(3, 'Mic for a call', 'The microphone opens for 3 s. Say something.'),
    Card(
      4,
      'Silent switch',
      'iPhone: set the ring switch to SILENT first. A line plays; say if you heard it. Two or four times.',
    ),
    Card(5, 'Storage', 'Writes a marker and checks for the old progress.'),
    Card(6, 'Load', 'How long this page took to show.'),
  ];
  int? running;
  Ask? ask; // a question on screen (test 4), or the MIC button (test 2)
  bool micWanted = false;
  Completer<Future<Heard>>? _micTap;
  String copied = '';

  // ---------- start

  Future<void> start() async {
    _publish();
    unawaited(speech.init().then((_) => _publish()));
    unawaited(
      plugin.prepareUnlock(clipUri(kLines.first)).then((_) => _publish()),
    );
    try {
      await Future.wait(
        clips.values.map((c) async {
          try {
            c.bytes = await fetchBytes(clipPath(c.id))
                .timeout(const Duration(seconds: 20));
            c.offline = trim(
              await decodeOffline(c.bytes!)
                  .timeout(const Duration(seconds: 10)),
            );
          } catch (e) {
            c.error = errText(e);
          }
        }),
      );
      final bad = clips.values.where((c) => c.offline == null).toList();
      clipsNote = bad.isEmpty
          ? 'all ${clips.length} clips loaded'
          : '${bad.length} clips failed: ${bad.map((c) => '${c.id} (${c.error})').join(', ')}';
    } catch (e) {
      clipsNote = 'loading failed: ${errText(e)}';
    }
    _clipsReady.complete();
    _publish();
  }

  /// Every tap: unlock the audio inside it.
  void unlock() {
    wa.unlock();
    plugin.unlock();
  }

  void _say(Card c, List<String> lines) {
    c.lines = lines;
    _publish();
  }

  void _add(Card c, String line) {
    c.lines = [...c.lines, line];
    _publish();
  }

  void _publish() {
    notifyListeners();
    final st = {
      'running': running,
      'done': [
        for (final c in cards)
          if (c.status == 'done') c.n,
      ],
      'ask': ask?.question,
      'mic': micWanted,
      'clipsReady': _clipsReady.isCompleted,
    };
    mirror(resultsText(), jsonEncode(st));
  }

  /// Called from a button's tap. Runs one test; the others wait.
  void run(int n) {
    unlock();
    if (running != null) return;
    running = n;
    final c = cards[n - 1];
    c.status = 'running';
    c.lines = [];
    final f = switch (n) {
      1 => _test1(c),
      2 => _test2(c),
      3 => _test3(c),
      4 => _test4(c),
      5 => _test5(c),
      _ => _test6(c),
    };
    f
        .catchError((Object e) {
          _add(c, 'stopped by an error: ${errText(e)}');
        })
        .whenComplete(() {
          c.status = 'done';
          running = null;
          ask = null;
          micWanted = false;
          _publish();
        });
  }

  void answer(String a) {
    unlock();
    final q = ask;
    if (q != null && !q.answer.isCompleted) q.answer.complete(a);
  }

  /// The MIC button (test 2): start listening inside this tap.
  void micTapped() {
    unlock();
    final m = _micTap;
    if (m == null || m.isCompleted) return;
    micWanted = false;
    m.complete(speech.listen());
    _publish();
  }

  Future<String> _ask(String q, List<String> options, Duration limit) async {
    final a = ask = Ask(q, options);
    _publish();
    final r = await within(a.answer.future, limit);
    ask = null;
    _publish();
    return r ?? 'no answer within ${limit.inSeconds} s';
  }

  Future<bool> _clipsLoaded() async {
    await within(_clipsReady.future, const Duration(seconds: 25));
    final missing = [
      for (final c in clips.values)
        if (c.offline == null && c.bytes != null) c.id,
    ];
    if (missing.isNotEmpty && wa.ready) {
      // no OfflineAudioContext here: take the marks from the live context instead
      await _liveBuffers(missing);
      for (final id in missing) {
        clips[id]!.offline ??= clips[id]!.live;
      }
      clipsNote += '; marks for ${missing.length} clips from the live context';
    }
    return kAll.every((id) => clips[id]!.offline != null);
  }

  /// Decode the clips in the live context (juego.js does the same, and takes its marks from these).
  Future<String?> _liveBuffers(Iterable<String> ids) async {
    if (!wa.ready) return 'no audio context (${wa.error})';
    final errs = <String>[];
    await Future.wait(
      ids.map((id) async {
        final c = clips[id]!;
        if (c.buf != null) return;
        try {
          if (c.bytes == null) throw StateError('not fetched (${c.error})');
          final b = await wa
              .decode(c.bytes!)
              .timeout(const Duration(seconds: 10));
          c.buf = b;
          c.live = trim(b);
        } catch (e) {
          errs.add('$id: ${errText(e)}');
        }
      }),
    );
    return errs.isEmpty ? null : errs.join('; ');
  }

  // ---------- 1. Lines

  Future<void> _test1(Card c) async {
    _say(c, ['Loading the clips...']);
    if (!await _clipsLoaded()) {
      _say(c, ['Clips not loaded: $clipsNote']);
      return;
    }
    final out = <String>[];
    // Plugin run: one player, the ten clips (clipped to the marks) as its playlist; it moves on by itself.
    _say(c, ['Playing with the audio plugin...']);
    await plugin.unlockDone();
    final items = [for (final id in kLines) (clipUri(id), clips[id]!.offline!)];
    final le = await plugin.load(items);
    if (le != null) {
      out.add('Plugin: could not load the ten clips: $le');
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final total = kLines.fold<double>(
        0,
        (s, id) => s + clips[id]!.offline!.len,
      );
      final runStart = nowMs();
      mediaWatchStart();
      final pe = await plugin.playToEnd(
        Duration(milliseconds: (total * 1000).round() + 10000),
      );
      final samples = mediaWatchStop();
      final gaps = <double>[];
      var worst = 0.0, seek = 0.0, wobble = 0.0;
      var extrap = 0, missing = 0;
      for (var k = 0; k + 1 < kLines.length; k++) {
        final a = clipTimes(
          samples,
          kLines[k],
          clips[kLines[k]]!.offline!,
          after: runStart,
        );
        final b = clipTimes(
          samples,
          kLines[k + 1],
          clips[kLines[k + 1]]!.offline!,
          after: runStart,
        );
        if (a.endAt == null || b.startAt == null) {
          missing++;
          continue;
        }
        gaps.add(b.startAt! - a.endAt!);
        final err = (a.endErr ?? 0) + (b.startErr ?? 0);
        if (err > worst) worst = err;
        if ((b.seekOff ?? 0).abs() > seek) seek = (b.seekOff ?? 0).abs();
        final wb = b.startAt! - (b.firstMove ?? b.startAt!);
        if (wb > wobble) wobble = wb;
        if (a.endExtrapolated) extrap++;
      }
      out.add(
        'Plugin (just_audio, one <audio> element, the 10 clips as its playlist, clipped to the marks):',
      );
      if (pe != null) out.add('  playback: $pe');
      out.add('  gaps ms: ${gapsLine(gaps)}');
      out.add(
        '  from the element clock (${samples.length} samples), error up to +/-${ms(worst)} ms; '
        'seek within ${ms(seek)} ms of each start mark; clock moved up to ${ms(wobble)} ms before its steady line (not counted as sound)'
        '${extrap > 0 ? '; $extrap end(s) extrapolated' : ''}${missing > 0 ? '; $missing gap(s) not measurable' : ''}',
      );
    }
    _say(c, [...out, 'Playing with Web Audio...']);

    // Web Audio run: juego.js's sequence (the source's "ended", then a pause of 0 by timer, then the next start).
    final de = await _liveBuffers(kLines);
    if (de != null) {
      out.add('Web Audio: could not decode: $de');
      _say(c, out);
      return;
    }
    final meterOn = await wa.meterReady();
    wa.meterReset();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final calls = <double>[];
    var failed = '';
    for (final id in kLines) {
      final cl = clips[id]!;
      final ended = Completer<bool>();
      try {
        calls.add(
          wa.startNow(cl.buf!, cl.live!, () {
            if (!ended.isCompleted) ended.complete(true);
          }),
        );
      } catch (e) {
        failed = '$id: start() threw ${errText(e)}';
        break;
      }
      final ok = await within(
        ended.future,
        Duration(milliseconds: (cl.live!.len * 1000).round() + 1000),
      );
      if (ok == null && !ended.isCompleted) {
        failed =
            '$id gave no "ended" within its length + 1 s (context ${wa.state})';
        break;
      }
      await Future<void>.delayed(
        Duration.zero,
      ); // the pause of 0 asked for, by timer, as say(id, 0)
    }
    await Future<void>.delayed(
      const Duration(milliseconds: 150),
    ); // the meter's last messages
    final sr = wa.rate;
    final acoustic = <double>[], clock = <double>[];
    for (var k = 0; k + 1 < calls.length; k++) {
      final a = clips[kLines[k]]!.live!, b = clips[kLines[k + 1]]!.live!;
      clock.add((calls[k + 1] - (calls[k] + a.len)) * 1000);
      final x = (calls[k + 1] * sr).round();
      (int, int)? run;
      for (final r in wa.quietRuns) {
        if (r.$1 < x && r.$2 > x) run = r;
      }
      if (run != null) {
        acoustic.add(((run.$2 - run.$1) / sr - a.tail - b.lead) * 1000);
      }
    }
    out.add('Web Audio (interop, juego.js sequence, pause 0 asked for):');
    if (failed.isNotEmpty) out.add('  stopped: $failed');
    if (meterOn && acoustic.length == calls.length - 1 && calls.length > 1) {
      out.add('  gaps ms: ${gapsLine(acoustic)}');
      out.add('  measured on the output bus, frame by frame (+/-0.1 ms)');
      out.add('  cross-check from the context clock: ${gapsLine(clock)}');
    } else {
      out.add('  gaps ms: ${gapsLine(clock)}');
      out.add(
        '  from the context clock only (${meterOn ? 'meter matched ${acoustic.length} of ${calls.length - 1} gaps' : wa.meterNote}); '
        '+/-${(128 / (sr == 0 ? 48000 : sr) * 1000).toStringAsFixed(1)} ms',
      );
    }
    final dm = _markDiff(kLines);
    if (dm != null) {
      out.add(
        '  marks: decoded at ${sr.round()} Hz here vs 48000 Hz offline differ by at most $dm ms',
      );
    }
    _say(c, out);
  }

  String? _markDiff(List<String> ids) {
    var d = 0.0;
    for (final id in ids) {
      final a = clips[id]!.offline, b = clips[id]!.live;
      if (a == null || b == null) return null;
      d = [
        d,
        (a.t0 - b.t0).abs() * 1000,
        (a.t1 - b.t1).abs() * 1000,
      ].reduce((x, y) => x > y ? x : y);
    }
    return d.toStringAsFixed(1);
  }

  // ---------- 2. Mic in stories

  Future<void> _test2(Card c) async {
    // The first line listens inside the button's own tap: nothing may wait before this call.
    final first = speech.listen();
    _say(c, ['Say "hola, abuela" now (listening up to 6 s)...']);
    final h0 = await first;
    wa.resume(); // iPhone guard: resume the audio context after every recognition
    final out = <String>[
      'Settings: lang $kLang, no interim results, not continuous, listen 6 s; ${speech.settings()}',
      'Line "hola, abuela": ${h0.line()}; heard right: ${heardRight(h0.alts, [
            ['hola'],
            ['abuela'],
          ]) ? 'yes' : 'no'}',
    ];
    _say(c, out);
    if (!await _clipsLoaded()) {
      _say(c, [...out, 'Clips not loaded: $clipsNote']);
      return;
    }
    final de = await _liveBuffers([kAsk, kAfter]);
    if (de != null) {
      _say(c, [...out, 'Web Audio: could not decode: $de']);
      return;
    }
    await wa.meterReady(limit: const Duration(seconds: 3));
    await plugin.unlockDone();
    final ask = clips[kAsk]!, after = clips[kAfter]!;
    for (var r = 1; r <= 5; r++) {
      final le = await plugin.load([
        (clipUri(kAfter), after.offline!),
      ]); // ready before he speaks
      _say(c, [...out, 'Round $r: a line plays...']);
      final pa = await wa.play(ask.buf!, ask.live!, limit: _limit(ask.live!));
      // his turn: the MIC button, then he says "hola"
      _micTap = Completer<Future<Heard>>();
      micWanted = true;
      _say(c, [...out, 'Round $r: tap MIC, then say "hola"']);
      final tapped = await within(_micTap!.future, const Duration(seconds: 30));
      micWanted = false;
      _micTap = null;
      String heard;
      if (tapped == null) {
        heard = 'no tap on MIC within 30 s';
      } else {
        _say(c, [...out, 'Round $r: listening...']);
        final h = await tapped;
        heard = h.line();
      }
      wa.resume(); // iPhone guard
      _say(c, [
        ...out,
        'Round $r: a line plays (Web Audio, then the plugin)...',
      ]);
      final pb = await wa.play(
        after.buf!,
        after.live!,
        limit: _limit(after.live!),
      );
      // the same line with the plugin
      String plug;
      if (le != null) {
        plug = 'could not load: $le';
      } else {
        final t = nowMs();
        mediaWatchStart();
        final pe = await plugin.playToEnd(_limit(after.offline!));
        final ss = mediaWatchStop();
        final ct = clipTimes(ss, kAfter, after.offline!, after: t - 50);
        final reached =
            ct.maxCt >= after.offline!.t1 - .02 && !ct.endExtrapolated;
        plug = pe == null
            ? (reached
                  ? 'yes (completed; its clock reached the end mark)'
                  : 'completed, but its clock was not seen at the end mark')
            : 'no: $pe';
      }
      out.add('Round $r: line before: ${_played(pa, ask.live!)}');
      out.add('  $heard');
      out.add('  sound came back, Web Audio: ${_played(pb, after.live!)}');
      out.add('  sound came back, plugin: $plug');
      _say(c, out);
    }
  }

  Duration _limit(Marks m) =>
      Duration(milliseconds: (m.len * 1000).round() + 1000);

  /// Did a Web Audio clip play to its end? Not assumed: its own "ended" event, the context clock moving on by
  /// at least 90 % of its length, and loud samples on the output (the meter) must all agree.
  String _played(WaPlay p, Marks m) {
    final sound = p.loudFrames < 0
        ? 'no meter'
        : p.loudFrames > 0
        ? 'sound on the output'
        : 'NO sound on the output';
    final moved = p.ctxAdvance >= 0.9 * m.len;
    final ok = p.ended && moved && p.loudFrames != 0;
    return '${ok ? 'yes' : 'NO'} (${p.endedBy} after ${ms(p.wallMs)} ms of ${ms(m.len * 1000)}; '
        'context clock moved ${ms(p.ctxAdvance * 1000)} ms; $sound; context ${p.state})';
  }

  // ---------- 3. Mic for a call

  Future<void> _test3(Card c) async {
    _say(c, ['Opening the microphone (allow it if asked)...']);
    final out = <String>[];
    final ctx = wa.ctx;
    if (ctx == null) {
      _say(c, ['No audio context: ${wa.error}']);
      return;
    }
    web.MediaStream? stream;
    try {
      final md = web.window.navigator.mediaDevices;
      stream = await within(
        md.getUserMedia(web.MediaStreamConstraints(audio: true.toJS)).toDart,
        const Duration(seconds: 20),
      );
      if (stream == null) {
        _say(c, ['getUserMedia: no answer within 20 s']);
        return;
      }
    } catch (e) {
      _say(c, ['getUserMedia failed: ${errText(e)}']);
      return;
    }
    try {
      final tracks = stream.getAudioTracks().toDart;
      out.add(
        'tracks: ${tracks.length}${tracks.isEmpty ? '' : ' ("${tracks.first.label}", ${tracks.first.readyState})'}',
      );
      wa.resume();
      final src = ctx.createMediaStreamSource(stream);
      final an = ctx.createAnalyser();
      an.fftSize = 2048;
      final mute = ctx.createGain();
      mute.gain.value = 0;
      src.connect(an);
      an.connect(mute);
      mute.connect(ctx.destination);
      final buf = Float32List(2048);
      final jsBuf = buf.toJS;
      var peak = 0.0;
      var reads = 0;
      _say(c, [...out, 'Listening for 3 s...']);
      final end = nowMs() + 3000;
      while (nowMs() < end) {
        an.getFloatTimeDomainData(jsBuf);
        final d = jsBuf.toDart;
        for (var i = 0; i < d.length; i++) {
          final v = d[i].abs();
          if (v > peak) peak = v;
        }
        reads++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      src.disconnect();
      an.disconnect();
      mute.disconnect();
      out.add(
        'loudest level (peak, 0-1): ${peak.toStringAsFixed(3)} ($reads reads; context ${ctx.state})',
      );
    } catch (e) {
      out.add('error while listening: ${errText(e)}');
    } finally {
      for (final t in stream.getTracks().toDart) {
        t.stop();
      }
      out.add('tracks stopped; audio session now "${audioSessionType()}"');
    }
    _say(c, out);
  }

  // ---------- 4. Silent switch

  static const kSilentNote =
      'iPhone: do this test with the ring switch set to silent.';

  /// Where navigator.audioSession exists (iPhone), once per session type, "playback" then "play-and-record",
  /// so a "No" can be told apart from sound going to the earpiece; then the type goes back to
  /// "play-and-record" for the other tests. Elsewhere once, labelled "no audioSession".
  Future<void> _test4(Card c) async {
    _say(c, [kSilentNote, 'Loading...']);
    if (!await _clipsLoaded()) {
      _say(c, [kSilentNote, 'Clips not loaded: $clipsNote']);
      return;
    }
    final de = await _liveBuffers([kSilent]);
    await wa.meterReady(limit: const Duration(seconds: 3));
    final cl = clips[kSilent]!;
    final out = <String>[kSilentNote];
    final types = hasAudioSession()
        ? const ['playback', 'play-and-record']
        : const <String?>[null];
    try {
      for (final type in types) {
        final label = type ?? 'no audioSession';
        if (type != null) {
          final sw = await switchAudioSession(type);
          out.add(sw.line);
          wa.resume();
          if (!sw.ok) {
            out.add('[$label] skipped: the type did not take');
            _say(c, out);
            continue;
          }
        }
        // Web Audio
        if (de != null) {
          out.add('[$label, Web Audio] could not decode: $de');
        } else {
          _say(c, [...out, 'Playing a line ($label, Web Audio)...']);
          final p = await wa.play(cl.buf!, cl.live!, limit: _limit(cl.live!));
          final a = await _ask('Did you hear it? ($label, Web Audio)', [
            'Yes',
            'No',
          ], const Duration(seconds: 60));
          out.add(
            '[$label, Web Audio] heard: $a; the page detected: ${_played(p, cl.live!)}',
          );
        }
        _say(c, out);
        // the plugin
        await plugin.unlockDone();
        final le = await plugin.load([(clipUri(kSilent), cl.offline!)]);
        if (le != null) {
          out.add('[$label, plugin] could not load: $le');
        } else {
          _say(c, [...out, 'Playing a line ($label, the plugin)...']);
          final pe = await plugin.playToEnd(_limit(cl.offline!));
          final a = await _ask('Did you hear it? ($label, the plugin)', [
            'Yes',
            'No',
          ], const Duration(seconds: 60));
          out.add(
            '[$label, plugin] heard: $a; the page detected: ${pe == null ? 'it played to its end' : 'no: $pe'}',
          );
        }
        _say(c, out);
      }
    } finally {
      if (types.first != null) {
        final back = await switchAudioSession('play-and-record');
        out.add('after the test: ${back.line}');
        wa.resume();
        _say(c, out);
      }
    }
  }

  // ---------- 5. Storage

  Future<void> _test5(Card c) async {
    final out = <String>[];
    final hs = homeScreen();
    final prev = lsGet(kMarkerKey);
    if (prev == null) {
      out.add('earlier marker: none');
    } else {
      try {
        final m = jsonDecode(prev) as Map<String, dynamic>;
        out.add(
          'earlier marker: written ${m['t']} (${m['from']}, ${m['build']})',
        );
      } catch (_) {
        out.add(
          'earlier marker: present but unreadable (${prev.length} chars)',
        );
      }
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final we = lsSet(
      kMarkerKey,
      jsonEncode({
        't': now,
        'from': hs.standalone ? 'home screen' : 'browser',
        'build': kBuild,
      }),
    );
    final back = lsGet(kMarkerKey);
    out.add(
      we == null
          ? 'marker written $now; read back: ${back != null && back.contains(now) ? 'yes' : 'no'}'
          : 'marker could not be written: $we',
    );
    final w = lsGet(kWordsKey);
    out.add(
      '$kWordsKey visible: ${w == null ? 'no' : 'yes, ${w.length} chars'}',
    );
    final keys = lsKeys().where((k) => k.startsWith('coqui.')).toList()..sort();
    out.add(
      'coqui.* keys here: ${keys.length}${keys.isEmpty ? '' : ' (${keys.join(', ')})'}',
    );
    out.add(
      'opened from the home screen: ${hs.standalone ? 'yes' : 'no'} (${hs.detail})',
    );
    out.add(await storagePersisted());
    _say(c, out);
  }

  // ---------- 6. Load

  Future<void> _test6(Card c) async {
    final ff = firstFrameMs();
    _say(c, [
      'first frame: ${ff == null ? 'no "flutter-first-frame" event seen' : '${ms(ff)} ms'} after page start '
          '(Dart main at ${ms(mainMs)} ms; first frame rasterized, seen from Dart: '
          '${firstFrameDart == null ? '?' : '${ms(firstFrameDart!)} ms'})',
      navMarks(),
      loadedBytes(),
    ]);
  }

  // ---------- the text

  String header() {
    final hs = homeScreen();
    return [
      'Coquí phone test $kBuild',
      'userAgent: ${userAgent()}',
      'home screen: ${hs.standalone ? 'yes' : 'no'} (${hs.detail})',
      'audio session at start: $sessionNote; now "${audioSessionType()}"',
      'time: ${DateTime.now().toUtc().toIso8601String()} (local ${DateTime.now()})',
      'screen: ${web.window.innerWidth}x${web.window.innerHeight} css px, ratio ${web.window.devicePixelRatio}',
      '${wa.describe()}; ${safetyNet()}',
      'plugin element: ${plugin.unlockNote}; speech: ${speech.note}; clips: $clipsNote',
    ].join('\n');
  }

  String resultsText() {
    final b = StringBuffer(header());
    for (final c in cards) {
      b.write(
        '\n\n${c.n}. ${c.title}${c.status == 'done' ? '' : ' (${c.status})'}',
      );
      for (final l in c.lines) {
        b.write('\n$l');
      }
    }
    final errs = [...windowErrors(), ...plugin.errors.map((e) => 'plugin: $e')];
    b.write('\n\nerrors seen: ${errs.isEmpty ? 'none' : ''}');
    for (final e in errs) {
      b.write('\n$e');
    }
    return b.toString();
  }

  Future<void> copy() async {
    unlock();
    final text = resultsText();
    final err = await copyText(text);
    copied = err == null
        ? 'Copied. Paste it into the chat.'
        : 'Could not copy ($err). Select the text below and copy it.';
    _publish();
  }
}
