import 'dart:typed_data';

import 'package:coqui_platform/src/audio/graph.dart';

/// An [AudioGraph] that writes down every call, in the form `tool/juego_sonido.mjs` writes juego.js's
/// calls on its stub AudioContext. Its clock stands at [currentTime].
class RecordingGraph implements AudioGraph {
  RecordingGraph(this.log, {this.currentTime = 3.25, this.sampleRate = 44100}) {
    log.add(['new', 'context']);
  }

  final List<List<Object?>> log;
  final Map<String, int> _count = {};
  final List<RecSource> sources = [];
  int resumes = 0;

  @override
  double currentTime;

  @override
  final double sampleRate;

  @override
  String state = 'running';

  String _name(String k) => '$k${_count[k] = (_count[k] ?? 0) + 1}';

  @override
  final AudioNodeH destination = RecNode._dest();

  @override
  OscillatorH createOscillator() => RecOsc(this, _name('osc'));

  @override
  GainH createGain() => RecGain(this, _name('gain'));

  @override
  BiquadH createBiquadFilter() => RecBiquad(this, _name('biquad'));

  @override
  BufferSourceH createBufferSource() {
    final s = RecSource(this, _name('source'));
    sources.add(s);
    return s;
  }

  @override
  AudioBufferH createBuffer(int channels, int length, double rate) {
    final n = _name('buffer');
    log.add(['new', n, channels, length, rate]);
    return RecBuffer(n, length, rate);
  }

  /// How many files were decoded, and from what bytes.
  final List<Uint8List> decoded = [];

  @override
  Future<AudioBufferH> decodeAudioData(Uint8List bytes) async {
    decoded.add(bytes);
    return RecBuffer('decoded_${String.fromCharCodes(bytes)}', 1, sampleRate);
  }

  @override
  Future<void> resume() async {
    resumes++;
  }
}

class RecNode implements AudioNodeH {
  RecNode(this.g, this.name) {
    g!.log.add(['new', name]);
  }
  RecNode._dest() : g = null, name = 'destination';

  final RecordingGraph? g;
  final String name;

  @override
  void connect(AudioNodeH to) =>
      g!.log.add([name, 'connect', (to as RecNode).name]);
}

class RecParam implements ParamH {
  RecParam(this.log, this.name);
  final List<List<Object?>> log;
  final String name;

  @override
  set value(double v) => log.add([name, '=', v]);

  @override
  void setValueAtTime(double v, double t) =>
      log.add([name, 'setValueAtTime', v, t]);

  @override
  void exponentialRampToValueAtTime(double v, double t) =>
      log.add([name, 'exponentialRampToValueAtTime', v, t]);
}

class RecOsc extends RecNode implements OscillatorH {
  RecOsc(super.g, super.name);

  @override
  set type(String t) => g!.log.add([name, 'type', t]);

  @override
  late final ParamH frequency = RecParam(g!.log, '$name.frequency');

  @override
  void start(double when) => g!.log.add([name, 'start', when]);

  @override
  void stop(double when) => g!.log.add([name, 'stop', when]);
}

class RecGain extends RecNode implements GainH {
  RecGain(super.g, super.name);

  @override
  late final ParamH gain = RecParam(g!.log, '$name.gain');
}

class RecBiquad extends RecNode implements BiquadH {
  RecBiquad(super.g, super.name);

  @override
  set type(String t) => g!.log.add([name, 'type', t]);

  @override
  late final ParamH frequency = RecParam(g!.log, '$name.frequency');
}

class RecSource extends RecNode implements BufferSourceH {
  RecSource(super.g, super.name);

  void Function()? ended;

  @override
  late final ParamH playbackRate = RecParam(g!.log, '$name.playbackRate');

  @override
  set buffer(AudioBufferH b) =>
      g!.log.add([name, 'buffer', (b as RecBuffer).name]);

  @override
  set loop(bool v) => g!.log.add([name, 'loop', v]);

  @override
  set onended(void Function()? f) => ended = f;

  @override
  void start([double? when, double? offset, double? duration]) =>
      g!.log.add([name, 'start', ?when, ?offset, ?duration]);

  @override
  void stop([double? when]) => g!.log.add([name, 'stop', ?when]);
}

class RecBuffer implements AudioBufferH {
  RecBuffer(this.name, this.length, this.sampleRate) : _d = Float32List(length);
  final String name;
  final Float32List _d;

  @override
  final int length;

  @override
  final double sampleRate;

  @override
  double get duration => length / sampleRate;

  @override
  Float32List channel(int c) => Float32List.fromList(_d);

  @override
  void fill(int c, Float32List data) => _d.setAll(0, data);
}
