@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/pcm_graph.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/web/web_audio_graph.dart';
import 'package:coqui_platform/src/web/web_platform.dart' show browserFacts;
import 'package:coqui_platform/src/web/web_recognizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

// The interop parts, in Chrome: `flutter test --platform chrome`.

class _Voice implements PcmVoice {
  @override
  set volume(double v) {}
  @override
  void stop() {}
  @override
  Future<void> get done => Completer<void>().future;
}

class _Sink implements PcmSink {
  final List<Float32List> got = [];
  @override
  PcmVoice play(
    Float32List pcm, {
    required int rate,
    required Duration delay,
    required bool loop,
    required double volume,
    required String key,
  }) {
    got.add(pcm);
    return _Voice();
  }
}

class _Zero extends Stopwatch {
  @override
  int get elapsedMicroseconds => 0;
}

/// The browser's own rendering of [sound] (an OfflineAudioContext at 44.1 kHz) and the phone build's
/// (a PcmGraph), from the same juego.js code.
Future<(Float32List, Float32List)> _both(
  void Function(SoundCore c) sound,
  double seconds,
) async {
  const rate = 44100;
  final n = (seconds * rate).ceil();
  final oc = web.OfflineAudioContext(1.toJS, n, rate);
  sound(SoundCore(() => WebAudioGraph(oc), random: math.Random(7).nextDouble));
  final web.AudioBuffer b = await oc.startRendering().toDart;
  final browser = b.getChannelData(0).toDart;
  final sink = _Sink();
  sound(
    SoundCore(
      () => PcmGraph(sink, sampleRate: rate.toDouble(), clock: _Zero()),
      random: math.Random(7).nextDouble,
    ),
  );
  await Future<void>.delayed(Duration.zero);
  final phone = Float32List(n);
  // the phone's voices, mixed at their start (all start at 0 here, or at their own `at`)
  for (final p in sink.got) {
    for (var i = 0; i < p.length && i < n; i++) {
      phone[i] += p[i];
    }
  }
  return (Float32List.fromList(browser), phone);
}

/// The difference as a share of the browser's signal (root mean square).
double _rel(Float32List a, Float32List b) {
  var d = 0.0, s = 0.0;
  for (var i = 0; i < a.length; i++) {
    d += (a[i] - b[i]) * (a[i] - b[i]);
    s += a[i] * a[i];
  }
  return math.sqrt(d / s);
}

void main() {
  group('the phone\'s rendering matches the browser\'s live formulas', () {
    final tones = <String, (double, double, String, double, double?)>{
      'SFX.right (triangle)': (784, .1, 'triangle', .14, null),
      'SFX.blip (sine, a rising ramp)': (520, .06, 'sine', .07, 640),
      'SFX.hop (square)': (320, .07, 'square', .025, 520),
      'SFX.creak (sawtooth)': (210, .5, 'sawtooth', .025, 120),
      'SFX.swoop (sine, falling)': (1800, .35, 'sine', .04, 600),
      'SFX.bonk (square, falling)': (600, .06, 'square', .05, 200),
    };
    for (final e in tones.entries) {
      test(e.key, () async {
        final (f0, dur, wave, vol, f1) = e.value;
        final (browser, phone) = await _both(
          (c) => c.tone(f0, 0, dur, wave, vol, f1),
          dur + .02,
        );
        final r = _rel(browser, phone);
        printOnFailure(
          '${e.key}: rms difference ${(r * 100).toStringAsFixed(2)} %',
        );
        expect(r, lessThan(.02));
      });
    }
    test(
      'SFX.trueno (the noise through the moving lowpass, its envelope)',
      () async {
        final (browser, phone) = await _both((c) => c.trueno(), 1.6);
        final r = _rel(browser, phone);
        printOnFailure(
          'trueno: rms difference ${(r * 100).toStringAsFixed(2)} %',
        );
        expect(r, lessThan(.02));
      },
    );
  });

  group('Web Audio by interop', () {
    test('a clip decodes, and its marks are its ClipInfo\'s', () async {
      final ctx = web.OfflineAudioContext(1.toJS, 44100, 44100);
      final core = SoundCore(() => WebAudioGraph(ctx));
      final wavBytes = _wav(44100, 1.0);
      final p = GraphClipPlayer(
        core: core,
        clipInfo: (id) => ClipInfo(
          id: id,
          who: 'narr',
          text: '',
          startMs: 100,
          endMs: 900,
          url: 'audio/$id.wav',
        ),
        base: Uri.parse('https://example.test/'),
        fetch: (_) async => wavBytes,
      );
      await p.preload(['a']);
      final c = core.clips['a']!;
      expect(c.t0, .1);
      expect(c.t1, .9);
      expect(c.buf.duration, closeTo(1, .01));
    });
  });

  group('speech recognition by interop', () {
    test('the browser has a recogniser here', () {
      expect(webRecognizerClass(), isNotNull);
    });
    test('a recognition in this browser ends with a clear result inside its limit', () async {
      final l = createSpeechListener();
      final sw = Stopwatch()..start();
      final t = l.listen(locale: 'es-US', limit: const Duration(seconds: 2));
      final r = await t.result.timeout(const Duration(seconds: 6));
      printOnFailure(
        'error ${r.error}, alternatives ${r.alternatives}, ${sw.elapsedMilliseconds} ms',
      );
      expect(r.error != null || r.alternatives.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(2000 + 2500 + 500));
    });
  });

  group('storage, haptics, AppInfo', () {
    test(
      'localStorage: the old keys are read where the old app left them',
      () async {
        web.window.localStorage.setItem('coqui.juego.ult', '{"x":"b"}');
        web.window.localStorage.setItem('coqui.palabras.v1', '{"v":1}');
        final s = await openStorage();
        expect(s.space('juego').read('ult'), '{"x":"b"}');
        expect(s.progress.read('coqui.palabras.v1'), '{"v":1}');
        await s.space('leer').write('tam', '2');
        expect(web.window.localStorage.getItem('coqui.leer.tam'), '2');
        expect(web.window.localStorage.getItem('coqui.juego.ult'), '{"x":"b"}');
      },
    );
    test('AppInfo and a tick, in this browser', () {
      final i = createAppInfo();
      expect(i.isWeb, isTrue);
      expect(i.isIos, isFalse);
      expect(i.installed, browserFacts().standalone);
      createHaptics().tick();
    });
  });
}

/// A mono 16-bit WAV of a 440 Hz tone.
Uint8List _wav(int rate, double seconds) {
  final n = (rate * seconds).round();
  final b = ByteData(44 + n * 2);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    b.setInt16(
      44 + 2 * i,
      (8000 * math.sin(2 * math.pi * 440 * i / rate)).round(),
      Endian.little,
    );
  }
  return b.buffer.asUint8List();
}
