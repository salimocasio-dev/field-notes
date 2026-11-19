import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_platform/src/audio/pcm.dart';
import 'package:coqui_platform/src/audio/pcm_graph.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _Played implements PcmVoice {
  _Played(this.pcm, this.rate, this.delay, this.loop, this.vol, this.key);
  final Float32List pcm;
  final int rate;
  final Duration delay;
  final bool loop;
  double vol;
  final String key;
  bool stopped = false;
  final Completer<void> _done = Completer();

  @override
  set volume(double v) => vol = v;

  @override
  void stop() {
    stopped = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}

class _Sink implements PcmSink {
  final List<_Played> played = [];

  @override
  PcmVoice play(
    Float32List pcm, {
    required int rate,
    required Duration delay,
    required bool loop,
    required double volume,
    required String key,
  }) {
    final p = _Played(pcm, rate, delay, loop, volume, key);
    played.add(p);
    return p;
  }
}

/// A clock that stands still.
class _Still extends Stopwatch {
  @override
  int get elapsedMicroseconds => 3250000;
}

void main() {
  group('AudioParam automation (Web Audio API, "Computation of Value")', () {
    test('an exponential ramp: v0 * (v1/v0)^((t-t0)/(t1-t0))', () {
      expect(expRamp(.14, .0008, 1, 1.1, 1), .14);
      expect(expRamp(.14, .0008, 1, 1.1, 1.1), closeTo(.0008, 1e-15));
      expect(
        expRamp(.14, .0008, 1, 1.1, 1.05),
        closeTo(math.sqrt(.14 * .0008), 1e-12),
      );
      expect(expRamp(0, 1, 0, 1, .5), 0); // v0 = 0 holds
      expect(expRamp(-1, 1, 0, 1, .5), -1); // opposite signs hold
    });
    test('the tone envelope: vol at the start, .0008 at the end of its time, then held', () {
      // juego.js tone(784, 0, .1, "triangle", .14) at t = 3.25
      final g = ParamTimeline(1)
        ..add(const ParamEvent(false, .14, 3.25))
        ..add(const ParamEvent(true, .0008, 3.35));
      expect(g.at(3.2), 1); // before its first event: the param's own value
      expect(g.at(3.25), .14);
      expect(g.at(3.35), .0008);
      expect(g.at(3.36), .0008);
      expect(g.at(3.30), closeTo(.14 * math.pow(.0008 / .14, .5), 1e-12));
      final f = ParamTimeline(440)
        ..add(const ParamEvent(false, 320, 0))
        ..add(const ParamEvent(true, 520, .07));
      expect(f.at(.035), closeTo(320 * math.pow(520 / 320, .5), 1e-9));
    });
  });

  group('the basic waveforms (Web Audio API, "Basic Waveform Phase")', () {
    test('their Fourier coefficients', () {
      expect(waveCoefficient('sine', 1), 1);
      expect(waveCoefficient('sine', 2), 0);
      expect(waveCoefficient('square', 3), closeTo(4 / (3 * math.pi), 1e-15));
      expect(waveCoefficient('square', 2), 0);
      expect(
        waveCoefficient('sawtooth', 2),
        closeTo(-2 / (2 * math.pi), 1e-15),
      );
      expect(waveCoefficient('sawtooth', 3), closeTo(2 / (3 * math.pi), 1e-15));
      expect(
        waveCoefficient('triangle', 3),
        closeTo(-8 / (9 * math.pi * math.pi), 1e-15),
      );
      expect(
        waveCoefficient('triangle', 5),
        closeTo(8 / (25 * math.pi * math.pi), 1e-15),
      );
    });
    test('normalised so the fullest table peaks at 1 (the square\'s overshoot comes off)', () {
      expect(waveNormalisation('sine', 44100), 1);
      expect(waveNormalisation('square', 44100), closeTo(1 / 1.179, .01));
      expect(waveNormalisation('sawtooth', 44100), closeTo(1 / 1.179, .01));
      expect(waveNormalisation('triangle', 44100), closeTo(1, .01));
    });
    test('the browser\'s tables: three per octave, the next one taken before a partial aliases', () {
      // 320 Hz at 44.1 kHz: 4096-sample tables from 10.77 Hz; 1 + 14.67 ranges up: tables 15 and 16
      final t = tablesFor(320, 44100);
      expect(
        t.more,
        64,
      ); // 2048 * 2^(-15/3): harmonics 1..63, the 63rd at 20160 Hz
      expect(t.fewer, 50); // 2048 * 2^(-16/3)
      expect(
        t.between,
        closeTo(1 + math.log(320 / (44100 / 4096)) / math.ln2 * 3 - 15, 1e-9),
      );
      expect(
        tablesFor(1e6, 44100).more,
        tablesFor(1e7, 44100).more,
      ); // the last table holds
    });
    test('a sine at a steady frequency is sin(2 pi f t) from phase 0', () {
      final f = ParamTimeline(440);
      final x = renderOscillator(
        type: 'sine',
        frequency: f,
        start: 0,
        n: 441,
        rate: 44100,
      );
      for (var i = 0; i < x.length; i++) {
        expect(x[i], closeTo(math.sin(2 * math.pi * 440 * i / 44100), 1e-5));
      }
    });
    test('the phase follows the frequency ramp (the sum of f / rate)', () {
      final f = ParamTimeline(440)
        ..add(const ParamEvent(false, 520, 0))
        ..add(const ParamEvent(true, 640, .06));
      final x = renderOscillator(
        type: 'sine',
        frequency: f,
        start: 0,
        n: 2646,
        rate: 44100,
      );
      var phase = 0.0;
      for (var i = 0; i < x.length; i++) {
        expect(x[i], closeTo(math.sin(2 * math.pi * phase), 1e-4));
        phase += f.at(i / 44100) / 44100;
      }
    });
    test('band-limited: nothing at or above half the rate', () {
      // a 1500 Hz square at 8 kHz: partials 1, 3 (1500, 4500 Hz is over 4000: only the first)
      final x = renderOscillator(
        type: 'square',
        frequency: ParamTimeline(1500),
        start: 0,
        n: 800,
        rate: 8000,
      );
      final s = waveNormalisation('square', 8000) * 4 / math.pi;
      for (var i = 0; i < x.length; i++) {
        expect(
          x[i],
          closeTo(s * math.sin(2 * math.pi * 1500 * i / 8000), 1e-4),
        );
      }
    });
  });

  group(
    'the biquad filters (Web Audio API: the Cookbook with Q in dB, Q = 1)',
    () {
      double steady(String type, double hz, double cutoff) {
        const rate = 44100.0;
        final x = Float32List(44100);
        for (var i = 0; i < x.length; i++) {
          x[i] = math.sin(2 * math.pi * hz * i / rate);
        }
        applyBiquad(x, type, ParamTimeline(cutoff), 0, rate);
        var peak = 0.0;
        for (var i = 22050; i < x.length; i++) {
          peak = math.max(peak, x[i].abs());
        }
        return peak;
      }

      test('lowpass passes the low and gives 10^(Q/20) at its cutoff', () {
        expect(steady('lowpass', 50, 900), closeTo(1, .01));
        expect(steady('lowpass', 900, 900), closeTo(math.pow(10, 1 / 20), .01));
        expect(steady('lowpass', 9000, 900), lessThan(.02));
      });
      test('highpass passes the high and gives 10^(Q/20) at its cutoff', () {
        expect(steady('highpass', 12000, 1800), closeTo(1, .02));
        expect(
          steady('highpass', 1800, 1800),
          closeTo(math.pow(10, 1 / 20), .01),
        );
        expect(steady('highpass', 100, 1800), lessThan(.01));
      });
      test('the coefficients for 900 Hz at 44.1 kHz', () {
        final c = biquadCoefficients('lowpass', 900, 1, 44100);
        final w = 2 * math.pi * 900 / 44100,
            a = math.sin(w) / (2 * math.pow(10, 1 / 20)),
            a0 = 1 + a;
        expect(c[0], closeTo((1 - math.cos(w)) / 2 / a0, 1e-15));
        expect(c[3], closeTo(-2 * math.cos(w) / a0, 1e-15));
        expect(c[4], closeTo((1 - a) / a0, 1e-15));
      });
    },
  );

  group('a phone build\'s made sounds (juego.js on a PcmGraph)', () {
    late _Sink sink;
    late PcmGraph graph;
    late SoundCore core;
    setUp(() {
      sink = _Sink();
      graph = PcmGraph(sink, clock: _Still());
      core = SoundCore(() => graph, random: math.Random(1).nextDouble);
    });

    test('a tone is rendered once, the length of its oscillator, and played at its time', () async {
      core.tone(784, .09, .1, 'triangle', .14, null);
      core.tone(784, .09, .1, 'triangle', .14, null);
      await Future<void>.delayed(Duration.zero);
      expect(sink.played, hasLength(2));
      expect(graph.renders, 1);
      final p = sink.played.first;
      expect(identical(p.pcm, sink.played.last.pcm), isTrue);
      expect(p.pcm.length, ((.1 + .02) * 44100).ceil());
      expect(p.delay, const Duration(milliseconds: 90));
      expect(p.vol, 1);
      expect(p.loop, isFalse);
    });
    test(
      'its samples: the wave times the gain envelope, by the formulas',
      () async {
        core.tone(520, 0, .06, 'sine', .07, 640); // SFX.blip
        await Future<void>.delayed(Duration.zero);
        final x = sink.played.single.pcm;
        final f = ParamTimeline(440)
          ..add(const ParamEvent(false, 520, 0))
          ..add(const ParamEvent(true, 640, .06));
        final g = ParamTimeline(1)
          ..add(const ParamEvent(false, .07, 0))
          ..add(const ParamEvent(true, .0008, .06));
        var phase = 0.0;
        for (var i = 0; i < x.length; i++) {
          final t = i / 44100;
          expect(x[i], closeTo(math.sin(2 * math.pi * phase) * g.at(t), 1e-6));
          phase += f.at(t) / 44100;
        }
        expect(
          x.last.abs(),
          lessThan(.0009),
        ); // after its 60 ms, the gain holds at .0008
      },
    );
    test('muted: no tone is made', () async {
      core.muted = true;
      core.tone(784, 0, .1, 'triangle', .14, null);
      await Future<void>.delayed(Duration.zero);
      expect(sink.played, isEmpty);
    });
    test('the thunder: 1.6 s through the moving lowpass and its envelope, at the master\'s volume', () async {
      core.trueno(.6);
      await Future<void>.delayed(Duration.zero);
      final p = sink.played.single;
      expect(p.pcm.length, (1.6 * 44100).ceil());
      expect(p.vol, 1);
      var early = 0.0, late = 0.0;
      for (var i = 0; i < 4410; i++) {
        early = math.max(early, p.pcm[i].abs());
      }
      for (var i = p.pcm.length - 4410; i < p.pcm.length; i++) {
        late = math.max(late, p.pcm[i].abs());
      }
      expect(early, lessThan(.6 * .5 * 1.2));
      expect(early, greaterThan(.05));
      expect(late, lessThan(.002));
      core.muted = true; // the sound button while it plays
      expect(p.vol, 0);
      core.muted = false;
      expect(p.vol, 1);
    });
    test(
      'a phone build\'s rain is idempotent too: off with none, on twice',
      () async {
        core.calla();
        core.lluvia();
        core.lluvia();
        await Future<void>.delayed(Duration.zero);
        expect(sink.played, hasLength(1));
        core.calla();
        core.calla();
        expect(sink.played.single.stopped, isTrue);
      },
    );
    test('the rain: one looped buffer, 2 s, at .03 times the master; calla stops it', () async {
      core.lluvia();
      core.lluvia();
      await Future<void>.delayed(Duration.zero);
      final p = sink.played.single;
      expect(p.loop, isTrue);
      expect(p.pcm.length, 88200);
      expect(p.vol, closeTo(.03, 1e-12));
      core.muted = true;
      expect(p.vol, 0);
      core.calla();
      expect(p.stopped, isTrue);
    });
    test('a sound stopped before it is rendered is not played', () async {
      final s = graph.createBufferSource();
      s.buffer = core.noise();
      s.connect(graph.destination);
      s.start();
      s.stop();
      await Future<void>.delayed(Duration.zero);
      expect(sink.played, isEmpty);
    });
    test('decoding a file is not done by the PcmGraph', () {
      expect(graph.decodeAudioData(Uint8List(4)), throwsUnsupportedError);
    });
  });

  test('a WAV file: 44-byte header, 16-bit mono', () {
    final b = wav(Float32List.fromList([0, 1, -1, .5, 2]), 44100);
    final d = ByteData.sublistView(b);
    expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(b.sublist(8, 12)), 'WAVE');
    expect(d.getUint32(24, Endian.little), 44100);
    expect(d.getUint32(40, Endian.little), 10);
    expect(
      [for (var i = 0; i < 5; i++) d.getInt16(44 + 2 * i, Endian.little)],
      [0, 32767, -32767, 16384, 32767],
    );
  });
}
