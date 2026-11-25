import 'dart:async';
import 'dart:typed_data';

import 'package:coqui_platform/src/audio/graph.dart';
import 'package:coqui_platform/src/audio/pcm.dart';

/// Plays rendered sound: the phone build's audio plugin, or a test's recorder.
abstract interface class PcmSink {
  /// Plays [pcm] (mono, [rate] Hz) [delay] from now, once or looped, at [volume]. [key] is the same
  /// for the same sound, so a sink can keep what it made from it.
  PcmVoice play(
    Float32List pcm, {
    required int rate,
    required Duration delay,
    required bool loop,
    required double volume,
    required String key,
  });
}

abstract interface class PcmVoice {
  set volume(double v);
  void stop();

  /// When it has played to its end, or was stopped.
  Future<void> get done;
}

/// An [AudioGraph] for the phone builds. Nothing plays live: when a source starts, its chain is
/// rendered by the Web Audio formulas (pcm.dart) into one short buffer, kept by what it is, and
/// handed to the [PcmSink] to play at its start time.
///
/// A gain with no automation (only its value set: the master gain, the rain's 0.03) is not rendered
/// in: it is the voice's volume, and follows its value while the voice plays, as the master gain does
/// when the sound button is pressed. Decoding a file is not done here (a phone build plays clips
/// through the plugin itself).
class PcmGraph implements AudioGraph {
  PcmGraph(this.sink, {this.sampleRate = 44100, Stopwatch? clock})
    : _clock = clock ?? (Stopwatch()..start());

  final PcmSink sink;
  final Stopwatch _clock;

  @override
  final double sampleRate;

  final Map<String, Float32List> _rendered = {};

  /// How many distinct sounds have been rendered (each only once).
  int get renders => _rendered.length;

  @override
  double get currentTime => _clock.elapsedMicroseconds / 1e6;

  @override
  String get state => 'running';

  @override
  final AudioNodeH destination = _Dest();

  @override
  OscillatorH createOscillator() => PcmOsc(this);

  @override
  GainH createGain() => PcmGain();

  @override
  BiquadH createBiquadFilter() => PcmBiquad();

  @override
  BufferSourceH createBufferSource() => PcmSource(this);

  @override
  AudioBufferH createBuffer(int channels, int length, double rate) =>
      PcmBuffer(length, rate);

  @override
  Future<AudioBufferH> decodeAudioData(Uint8List bytes) => Future.error(
    UnsupportedError('a phone build plays files through the plugin'),
  );

  @override
  Future<void> resume() async {}

  /// The longest a source with no stop and no end is rendered for.
  static const longest = 5.0;

  void _launch(_PcmScheduled s) {
    if (s.stopped && s.stopAt == null) return;
    // The chain: the source, then every node it reaches, up to the speaker.
    final baked = <_PcmNode>[];
    final live = <PcmGain>[];
    _PcmNode? n = s.out;
    var reaches = false;
    while (n != null) {
      if (n is _Dest) {
        reaches = true;
        break;
      }
      if (n is PcmGain && !n.timeline.automated) {
        live.add(n);
      } else {
        baked.add(n);
      }
      n = n.out;
    }
    if (!reaches) return;
    final start = s.startAt ?? 0;
    final loop = s is PcmSource && s.looping;
    double len;
    if (s is PcmSource && s.looping) {
      len = s.buf!.duration;
    } else {
      final natural = s is PcmSource
          ? s.buf!.duration - (s.offset ?? 0)
          : longest;
      final play = s is PcmSource && s.playFor != null ? s.playFor! : natural;
      len = play < natural ? play : natural;
      final stop = s.stopAt;
      if (stop != null && stop - start < len) len = stop - start;
    }
    if (len <= 0) return;
    // (less a hair: a stop at t + dur + .02 comes out .12000000000000011 s after t, not .12)
    final frames = (len * sampleRate - 1e-6).ceil();
    final key = [
      s.key(start),
      for (final b in baked) b.key(start),
      '$frames',
    ].join('>');
    final pcm = _rendered[key] ??= _render(s, baked, start, frames, loop);
    var vol = 1.0;
    for (final g in live) {
      vol *= g.timeline.intrinsic;
    }
    final delay = start - currentTime;
    final v = sink.play(
      pcm,
      rate: sampleRate.round(),
      delay: Duration(microseconds: delay <= 0 ? 0 : (delay * 1e6).round()),
      loop: loop,
      volume: vol,
      key: key,
    );
    s.voice = v;
    final follow = _Follow(v, live);
    for (final g in live) {
      g._voices.add(follow);
    }
    unawaited(
      v.done.then((_) {
        for (final g in live) {
          g._voices.remove(follow);
        }
        s.ended?.call();
      }),
    );
  }

  Float32List _render(
    _PcmScheduled s,
    List<_PcmNode> chain,
    double start,
    int frames,
    bool loop,
  ) {
    // Every time is taken from the source's start, so the same sound renders the same at any start.
    final dt = -start;
    if (loop) {
      // A looped buffer: rendered twice through its chain and the second pass kept, so the filters
      // are already running where the loop joins.
      final src = (s as PcmSource).samples(0, frames * 2, loop: true);
      _through(src, chain, dt);
      return Float32List.fromList(src.sublist(frames));
    }
    final Float32List x;
    if (s is PcmOsc) {
      x = renderOscillator(
        type: s.waveType,
        frequency: s.timeline.shifted(dt),
        start: 0,
        n: frames,
        rate: sampleRate,
      );
    } else {
      x = (s as PcmSource).samples(
        ((s.offset ?? 0) * sampleRate).round(),
        frames,
        loop: false,
      );
    }
    _through(x, chain, dt);
    return x;
  }

  void _through(Float32List x, List<_PcmNode> chain, double dt) {
    for (final n in chain) {
      if (n is PcmGain) {
        applyGain(x, n.timeline.shifted(dt), 0, sampleRate);
      } else if (n is PcmBiquad) {
        applyBiquad(x, n.filterType, n.timeline.shifted(dt), 0, sampleRate);
      }
    }
  }
}

class _Follow {
  _Follow(this.voice, this.gains);
  final PcmVoice voice;
  final List<PcmGain> gains;

  void update() {
    var v = 1.0;
    for (final g in gains) {
      v *= g.timeline.intrinsic;
    }
    voice.volume = v;
  }
}

abstract class _PcmNode implements AudioNodeH {
  _PcmNode? out;

  @override
  void connect(AudioNodeH to) => out = to as _PcmNode;

  String key(double start);
}

class _Dest extends _PcmNode {
  @override
  String key(double start) => 'out';
}

class PcmParam implements ParamH {
  PcmParam(this.timeline, [this.onValue]);
  final ParamTimeline timeline;
  final void Function()? onValue;

  @override
  set value(double v) {
    timeline.intrinsic = v;
    onValue?.call();
  }

  @override
  void setValueAtTime(double v, double t) =>
      timeline.add(ParamEvent(false, v, t));

  @override
  void exponentialRampToValueAtTime(double v, double t) =>
      timeline.add(ParamEvent(true, v, t));
}

class PcmGain extends _PcmNode implements GainH {
  final ParamTimeline timeline = ParamTimeline(1);
  final Set<_Follow> _voices = {};

  @override
  late final ParamH gain = PcmParam(timeline, () {
    for (final v in [..._voices]) {
      v.update();
    }
  });

  @override
  String key(double start) => 'gain:${timeline.shifted(-start).key}';
}

class PcmBiquad extends _PcmNode implements BiquadH {
  final ParamTimeline timeline = ParamTimeline(350);
  String filterType = 'lowpass';

  @override
  set type(String t) => filterType = t;

  @override
  late final ParamH frequency = PcmParam(timeline);

  @override
  String key(double start) => '$filterType:${timeline.shifted(-start).key}';
}

abstract class _PcmScheduled extends _PcmNode {
  _PcmScheduled(this.graph);
  final PcmGraph graph;
  double? startAt, stopAt;
  bool started = false, stopped = false;
  PcmVoice? voice;
  void Function()? ended;

  void _start(double? when) {
    if (started) throw StateError('start() was already called');
    started = true;
    startAt = when ?? graph.currentTime;
    // Rendered once the calls that follow start() in the same turn (stop, as juego.js's tone makes
    // them) are in.
    scheduleMicrotask(() => graph._launch(this));
  }

  void _stop(double? when) {
    final v = voice;
    if (v != null) {
      final now = graph.currentTime;
      if (when == null || when <= now) {
        v.stop();
      } else {
        Timer(Duration(microseconds: ((when - now) * 1e6).round()), v.stop);
      }
      return;
    }
    stopped = true;
    stopAt = when ?? (started ? null : graph.currentTime);
  }
}

class PcmOsc extends _PcmScheduled implements OscillatorH {
  PcmOsc(super.graph);
  final ParamTimeline timeline = ParamTimeline(440);
  String waveType = 'sine';

  @override
  set type(String t) => waveType = t;

  @override
  late final ParamH frequency = PcmParam(timeline);

  @override
  void start(double when) => _start(when);

  @override
  void stop(double when) => _stop(when);

  @override
  String key(double start) => 'osc:$waveType:${timeline.shifted(-start).key}';
}

class PcmSource extends _PcmScheduled implements BufferSourceH {
  PcmSource(super.graph);
  PcmBuffer? buf;
  bool looping = false;
  double? offset, playFor;
  final ParamTimeline playbackRateTimeline = ParamTimeline(1);

  @override
  late final ParamH playbackRate = PcmParam(playbackRateTimeline);

  @override
  set buffer(AudioBufferH b) => buf = b as PcmBuffer;

  @override
  set loop(bool v) => looping = v;

  @override
  set onended(void Function()? f) => ended = f;

  @override
  void start([double? when, double? offset, double? duration]) {
    this.offset = offset;
    playFor = duration;
    _start(when);
  }

  @override
  void stop([double? when]) => _stop(when);

  Float32List samples(int from, int n, {required bool loop}) {
    final d = buf!.data, out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final j = from + i;
      if (loop) {
        out[i] = d[j % d.length];
      } else if (j < d.length) {
        out[i] = d[j];
      }
    }
    return out;
  }

  @override
  String key(double start) =>
      'buffer#${identityHashCode(buf)}:${looping ? 'loop' : '${offset ?? 0}'}';
}

class PcmBuffer implements AudioBufferH {
  PcmBuffer(this.length, this.sampleRate) : data = Float32List(length);
  final Float32List data;

  @override
  final int length;

  @override
  final double sampleRate;

  @override
  double get duration => length / sampleRate;

  @override
  Float32List channel(int c) => Float32List.fromList(data);

  @override
  void fill(int c, Float32List x) => data.setAll(0, x);
}
