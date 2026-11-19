import 'dart:math' as math;
import 'dart:typed_data';

/// The Web Audio formulas, in Dart, for the phone builds: a made sound is rendered once to a short
/// buffer by the same formulas the browser uses live (the Web Audio API spec: AudioParam automation,
/// the OscillatorNode's basic waveforms, the BiquadFilterNode's coefficients).

/// One automation event of an AudioParam.
class ParamEvent {
  const ParamEvent(this.exponential, this.value, this.time);

  /// false: setValueAtTime; true: exponentialRampToValueAtTime.
  final bool exponential;
  final double value, time;
}

/// An AudioParam's value over time: its own value ([intrinsic]) until the first event, then the events
/// (Web Audio API, "Computation of Value": a setValueAtTime holds from its time on; an exponential ramp
/// goes from the event before it to its own value and time, `v0 * (v1 / v0) ^ ((t - t0) / (t1 - t0))`,
/// and holds v0 when v0 and v1 differ in sign or v0 is 0).
class ParamTimeline {
  ParamTimeline(this.intrinsic);

  double intrinsic;
  final List<ParamEvent> events = [];

  bool get automated => events.isNotEmpty;

  void add(ParamEvent e) {
    // Kept in time order; an event at the same time as one before it goes after it.
    var i = events.length;
    while (i > 0 && events[i - 1].time > e.time) {
      i--;
    }
    events.insert(i, e);
  }

  double at(double t) {
    var v0 = intrinsic;
    double? t0;
    for (final e in events) {
      if (t < e.time) {
        if (e.exponential && t0 != null) {
          return expRamp(v0, e.value, t0, e.time, t);
        }
        return v0;
      }
      v0 = e.value;
      t0 = e.time;
    }
    return v0;
  }

  /// The same timeline, every time moved by [dt] (for a sound rendered from its own start).
  ParamTimeline shifted(double dt) {
    final p = ParamTimeline(intrinsic);
    for (final e in events) {
      p.events.add(ParamEvent(e.exponential, e.value, e.time + dt));
    }
    return p;
  }

  /// A text that is the same for two timelines that give the same values (times to the microsecond).
  String get key =>
      '$intrinsic${[for (final e in events) '|${e.exponential ? 'x' : 's'}${e.value},${(e.time * 1e6).round()}'].join()}';
}

/// Web Audio API, exponentialRampToValueAtTime.
double expRamp(double v0, double v1, double t0, double t1, double t) {
  if (v0 == 0 || (v0 < 0) != (v1 < 0)) return v0;
  if (t1 <= t0) return v1;
  return v0 * math.pow(v1 / v0, (t - t0) / (t1 - t0));
}

/// The Fourier sine coefficient b[k] of the OscillatorNode's basic waveforms (Web Audio API,
/// "Basic Waveform Phase"; the cosine terms are all 0). k >= 1.
double waveCoefficient(String type, int k) {
  switch (type) {
    case 'sine':
      return k == 1 ? 1 : 0;
    case 'square':
      return k.isOdd ? 4 / (k * math.pi) : 0;
    case 'sawtooth':
      return (k.isOdd ? 1 : -1) * 2 / (k * math.pi);
    case 'triangle':
      return k.isOdd
          ? (k % 4 == 1 ? 1 : -1) * 8 / (k * k * math.pi * math.pi)
          : 0;
  }
  throw ArgumentError.value(type, 'type');
}

/// The number of partials in the browser's fullest table for a wave (Chrome: half its PeriodicWave
/// size, 4096 samples for a context rate from 24 kHz to 88.2 kHz).
int fullPartials(double rate) =>
    rate <= 24000 ? 1024 : (rate <= 88200 ? 2048 : 8192);

final Map<String, double> _norm = {};

/// The scale the browser applies to a basic waveform so its fullest table peaks at 1 (the PeriodicWave
/// is normalised; "disableNormalization" is false for the built-in types).
double waveNormalisation(String type, double rate) {
  if (type == 'sine') return 1;
  return _norm['$type@${fullPartials(rate)}'] ??= () {
    final n = fullPartials(rate), size = 2 * n;
    // The table is the inverse transform at `size` points, as the browser builds it.
    final b = [for (var k = 1; k < n; k++) waveCoefficient(type, k)];
    var peak = 0.0;
    for (var i = 0; i < size; i++) {
      var s = 0.0;
      final w = 2 * math.pi * i / size;
      for (var k = 1; k < n; k++) {
        final c = b[k - 1];
        if (c != 0) s += c * math.sin(k * w);
      }
      if (s.abs() > peak) peak = s.abs();
    }
    return 1 / peak;
  }();
}

/// An OscillatorNode from [start] (s, its first sample) for [n] samples at [rate]: the phase moves on
/// by the frequency at each sample; each sample is the sum of the wave's partials below half the rate.
Float32List renderOscillator({
  required String type,
  required ParamTimeline frequency,
  required double start,
  required int n,
  required double rate,
}) {
  final out = Float32List(n);
  final nyquist = rate / 2;
  final scale = waveNormalisation(type, rate);
  final coef = <double>[];
  var phase = 0.0; // in cycles
  for (var i = 0; i < n; i++) {
    final f = frequency.at(start + i / rate);
    if (type == 'sine') {
      out[i] = math.sin(2 * math.pi * phase);
    } else {
      final kMax = f <= 0 ? 0 : (nyquist / f).floor();
      while (coef.length < kMax) {
        coef.add(waveCoefficient(type, coef.length + 1));
      }
      var s = 0.0;
      final w = 2 * math.pi * phase;
      for (var k = 1; k <= kMax; k++) {
        final c = coef[k - 1];
        if (c != 0) s += c * math.sin(k * w);
      }
      out[i] = s * scale;
    }
    phase += f / rate;
    phase -= phase.floorToDouble();
  }
  return out;
}

/// Multiplies [x] by a GainNode's gain, sample by sample.
void applyGain(Float32List x, ParamTimeline gain, double start, double rate) {
  for (var i = 0; i < x.length; i++) {
    x[i] *= gain.at(start + i / rate);
  }
}

/// A BiquadFilterNode ("lowpass" or "highpass", Q 1, detune 0) over [x], in place. The coefficients
/// are the Web Audio API's (the Audio EQ Cookbook with Q in dB), worked out again at each sample while
/// the frequency moves.
void applyBiquad(
  Float32List x,
  String type,
  ParamTimeline frequency,
  double start,
  double rate,
) {
  if (type != 'lowpass' && type != 'highpass') {
    throw ArgumentError.value(type, 'type');
  }
  const q = 1.0;
  final nyquist = rate / 2;
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  double b0 = 0, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
  double? lastF;
  for (var i = 0; i < x.length; i++) {
    final f = frequency.at(start + i / rate).clamp(0, nyquist).toDouble();
    if (f != lastF) {
      lastF = f;
      final c = biquadCoefficients(type, f, q, rate);
      b0 = c[0];
      b1 = c[1];
      b2 = c[2];
      a1 = c[3];
      a2 = c[4];
    }
    final x0 = x[i];
    final y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = x0;
    y2 = y1;
    y1 = y0;
    x[i] = y0;
  }
}

/// [b0, b1, b2, a1, a2], divided by a0 (Web Audio API, "BiquadFilterNode": lowpass and highpass).
List<double> biquadCoefficients(String type, double f, double q, double rate) {
  final w0 = 2 * math.pi * f / rate;
  final cw = math.cos(w0);
  final alpha = math.sin(w0) / (2 * math.pow(10, q / 20));
  final a0 = 1 + alpha;
  final double b0, b1, b2;
  if (type == 'lowpass') {
    b0 = (1 - cw) / 2;
    b1 = 1 - cw;
    b2 = (1 - cw) / 2;
  } else {
    b0 = (1 + cw) / 2;
    b1 = -(1 + cw);
    b2 = (1 + cw) / 2;
  }
  return [b0 / a0, b1 / a0, b2 / a0, -2 * cw / a0, (1 - alpha) / a0];
}

/// A mono WAV file, 16-bit, of [x] (clipped to [-1, 1]).
Uint8List wav(Float32List x, int rate) {
  final data = x.length * 2;
  final b = ByteData(44 + data);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + data, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, data, Endian.little);
  for (var i = 0; i < x.length; i++) {
    final v = x[i].clamp(-1.0, 1.0);
    b.setInt16(44 + 2 * i, (v * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}
