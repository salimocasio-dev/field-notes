import 'dart:typed_data';

/// The part of the browser's Web Audio that juego.js's sound code uses, and nothing more. The sound
/// code ([SoundCore], [GraphVoice]) is written against this, line for line as juego.js writes it
/// against `AudioContext`.
///
/// Three implementations: the browser's own (web), [PcmGraph] (phone builds: renders each sound to a
/// short buffer by the same formulas and plays it through the audio plugin), and the recording one the
/// tests use (its log has the form of `tool/juego_sonido.mjs`).
abstract interface class AudioGraph {
  /// The context's clock, in s.
  double get currentTime;
  double get sampleRate;

  /// "suspended", "running" or "closed".
  String get state;
  AudioNodeH get destination;
  OscillatorH createOscillator();
  GainH createGain();
  BiquadH createBiquadFilter();
  BufferSourceH createBufferSource();
  AudioBufferH createBuffer(int channels, int length, double rate);

  /// Decodes a whole file (mp3). The bytes are copied first.
  Future<AudioBufferH> decodeAudioData(Uint8List bytes);
  Future<void> resume();
}

abstract interface class AudioNodeH {
  void connect(AudioNodeH to);
}

abstract interface class ParamH {
  set value(double v);
  void setValueAtTime(double v, double t);
  void exponentialRampToValueAtTime(double v, double t);
}

abstract interface class OscillatorH implements AudioNodeH {
  set type(String t);
  ParamH get frequency;
  void start(double when);
  void stop(double when);
}

abstract interface class GainH implements AudioNodeH {
  ParamH get gain;
}

abstract interface class BiquadH implements AudioNodeH {
  set type(String t);
  ParamH get frequency;
}

abstract interface class BufferSourceH implements AudioNodeH {
  set buffer(AudioBufferH b);
  set loop(bool v);

  /// The source's "ended" event.
  set onended(void Function()? f);

  /// `start()`, `start(when)` or `start(when, offset, duration)`: only the arguments given are passed on.
  void start([double? when, double? offset, double? duration]);

  /// `stop()` (now) or `stop(when)`.
  void stop([double? when]);
}

abstract interface class AudioBufferH {
  double get duration;
  double get sampleRate;
  int get length;

  /// A copy of one channel's samples.
  Float32List channel(int c);

  /// Writes [data] into channel [c] (juego.js writes through `getChannelData`).
  void fill(int c, Float32List data);
}
