import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_platform/src/audio/graph.dart';

/// Starts a timer (`setTimeout`). Tests pass their own.
typedef StartTimer = Timer Function(Duration d, void Function() f);

Timer _timer(Duration d, void Function() f) => Timer(d, f);

/// A clip ready to play: its decoded sound and its marks, in s (juego.js: CLIPS[id], `{buf, t0, t1}`).
class GraphClip {
  GraphClip(this.buf, this.t0, this.t1);
  final AudioBufferH buf;
  final double t0, t1;
}

/// juego.js, "sound: effects, and the recorded voice", ported line for line onto an [AudioGraph]:
/// the context made on first use (`ac`), the master gain (`out`), `tone`, the noise buffer (`noise`),
/// `SFX.trueno`, `SFX.lluvia`, `SFX.calla`, `playClip` and `hush`.
///
/// What juego.js does around it is not here: which clips a story loads, and `trim` (the marks now come
/// with the clip, from marcas.json, made by the same rule).
class SoundCore {
  SoundCore(this._make, {double Function()? random, StartTimer? startTimer})
    : _random = random ?? math.Random().nextDouble,
      _startTimer = startTimer ?? _timer;

  final AudioGraph Function() _make;
  final double Function() _random;
  final StartTimer _startTimer;

  AudioGraph? _ac;

  /// The context, if it has been made.
  AudioGraph? get context => _ac;

  // juego.js: ac
  AudioGraph ac() => _ac ??= _make();

  GainH? _master;

  /// The master gain, if it has been made (every clip, the thunder and the rain go through it).
  GainH? get master => _master;

  bool _muted = false;

  bool get muted => _muted;

  // juego.js line 417, the sound button: `muted=!muted; if(master) master.gain.value = muted?0:1`
  set muted(bool m) {
    _muted = m;
    final g = _master;
    if (g != null) g.gain.value = m ? 0 : 1;
  }

  // juego.js: out
  GainH out() {
    final a = ac();
    var g = _master;
    if (g == null) {
      g = _master = a.createGain();
      g.connect(a.destination);
    }
    g.gain.value = _muted ? 0 : 1;
    return g;
  }

  // juego.js: tone(f0, at, dur, type, vol, f1). Straight to the speaker, not through the master gain.
  void tone(
    double f0,
    double at,
    double dur,
    String? type,
    double? vol,
    double? f1,
  ) {
    if (_muted) return;
    try {
      final a = ac(), t = a.currentTime + at;
      final o = a.createOscillator(), g = a.createGain();
      o.type = (type == null || type.isEmpty) ? 'square' : type;
      o.frequency.setValueAtTime(f0, t);
      if (_truthy(f1)) o.frequency.exponentialRampToValueAtTime(f1!, t + dur);
      g.gain.setValueAtTime(_truthy(vol) ? vol! : .05, t);
      g.gain.exponentialRampToValueAtTime(.0008, t + dur);
      o.connect(g);
      g.connect(a.destination);
      o.start(t);
      o.stop(t + dur + .02);
    } catch (_) {}
  }

  AudioBufferH? _noise;
  BufferSourceH? _rain;

  /// The rain's source while it plays (juego.js: RAIN).
  BufferSourceH? get rain => _rain;

  // juego.js: noise. Two seconds of white noise, made once.
  AudioBufferH noise() {
    final a = ac();
    var n = _noise;
    if (n == null) {
      n = _noise = a.createBuffer(1, (a.sampleRate * 2).toInt(), a.sampleRate);
      final d = Float32List(n.length);
      for (var i = 0; i < d.length; i++) {
        d[i] = _random() * 2 - 1;
      }
      n.fill(0, d);
    }
    return n;
  }

  // juego.js: SFX.trueno(v)
  void trueno([double? v]) {
    try {
      final a = ac(),
          s = a.createBufferSource(),
          f = a.createBiquadFilter(),
          g = a.createGain(),
          t = a.currentTime;
      s.buffer = noise();
      f.type = 'lowpass';
      f.frequency.setValueAtTime(900, t);
      f.frequency.exponentialRampToValueAtTime(70, t + 1.3);
      g.gain.setValueAtTime((_truthy(v) ? v! : 1) * .5, t);
      g.gain.exponentialRampToValueAtTime(.001, t + 1.5);
      s.connect(f);
      f.connect(g);
      g.connect(out());
      s.start(t);
      s.stop(t + 1.6);
    } catch (_) {}
  }

  // juego.js: SFX.lluvia
  void lluvia() {
    try {
      if (_rain != null) return;
      final a = ac(),
          s = a.createBufferSource(),
          f = a.createBiquadFilter(),
          g = a.createGain();
      s.buffer = noise();
      s.loop = true;
      f.type = 'highpass';
      f.frequency.value = 1800;
      g.gain.value = .03;
      s.connect(f);
      f.connect(g);
      g.connect(out());
      s.start();
      _rain = s;
    } catch (_) {}
  }

  // juego.js: SFX.calla
  void calla() {
    try {
      _rain?.stop();
    } catch (_) {}
    _rain = null;
  }

  /// The clips ready to play (juego.js: CLIPS).
  final Map<String, GraphClip> clips = {};

  final Set<BufferSourceH> _live = {};
  final Map<BufferSourceH, void Function(bool)> _ends = {};

  /// How many clips are playing (juego.js: speaking).
  int get speaking => _live.length;

  // juego.js: playClip. [limit] is the time limit juego.js gives every clip after a speaking turn
  // (its length + 1 s, HAB.guard); here the caller says it. At the limit the clip is stopped and gives false.
  Future<bool> playClip(String id, {Duration? limit, double rate = 1.0}) {
    if (!rate.isFinite || rate <= 0) {
      throw ArgumentError.value(rate, 'rate', 'must be finite and positive');
    }
    final cl = clips[id];
    if (cl == null) return Future.value(false);
    final res = Completer<bool>();
    final s = ac().createBufferSource();
    Timer? lim;
    s.buffer = cl.buf;
    if (rate != 1.0) s.playbackRate.value = rate;
    s.connect(out());
    _live.add(s);
    var done = false;
    void end(bool v) {
      if (done) return;
      done = true;
      lim?.cancel();
      _live.remove(s);
      _ends.remove(s);
      res.complete(v);
    }

    _ends[s] = end;
    s.onended = () => end(true);
    s.start(0, cl.t0, math.max(.05, cl.t1 - cl.t0));
    if (limit != null) {
      lim = _startTimer(limit, () {
        try {
          s.stop();
        } catch (_) {}
        end(false);
      });
    }
    return res.future;
  }

  // juego.js: hush. Every clip playing stops and gives false.
  void hush() {
    for (final s in [..._live]) {
      try {
        s.stop();
      } catch (_) {}
      _ends[s]?.call(false);
    }
  }
}

/// JavaScript's truth for a number: null, 0 and NaN are false.
bool _truthy(double? v) => v != null && v != 0 && !v.isNaN;
