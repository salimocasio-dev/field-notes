import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_platform/src/audio/pcm.dart';
import 'package:coqui_platform/src/audio/pcm_graph.dart';
import 'package:just_audio/just_audio.dart';

/// Players kept for reuse: one is taken for each sound and given back when it ends.
class PlayerPool {
  final List<AudioPlayer> _idle = [];

  AudioPlayer take() => _idle.isNotEmpty ? _idle.removeLast() : AudioPlayer();

  Future<void> give(AudioPlayer p) async {
    try {
      await p.stop();
    } catch (_) {}
    _idle.add(p);
  }
}

/// A folder in the phone's temporary storage for what this package keeps on disk.
Directory cacheDir(String name) {
  final d = Directory('${Directory.systemTemp.path}/coqui_platform/$name');
  if (!d.existsSync()) d.createSync(recursive: true);
  return d;
}

/// The phone build's [PcmSink]: each rendered sound is written once as a WAV file and played by the
/// audio plugin (just_audio) at its start time.
class JustAudioSink implements PcmSink {
  final PlayerPool _pool = PlayerPool();
  final Map<String, File> _files = {};
  late final Directory _dir = cacheDir('sounds');

  File _file(String key, Float32List pcm, int rate) => _files[key] ??= () {
    final f = File(
      '${_dir.path}/${_files.length}_${key.hashCode.toUnsigned(32)}.wav',
    );
    f.writeAsBytesSync(wav(pcm, rate));
    return f;
  }();

  @override
  PcmVoice play(
    Float32List pcm, {
    required int rate,
    required Duration delay,
    required bool loop,
    required double volume,
    required String key,
  }) {
    final v = _Voice(_pool, volume);
    final at = DateTime.now().add(delay);
    unawaited(v._run(_file(key, pcm, rate), at, loop));
    return v;
  }
}

class _Voice implements PcmVoice {
  _Voice(this._pool, this._volume);
  final PlayerPool _pool;
  double _volume;
  AudioPlayer? _p;
  final Completer<void> _done = Completer();

  bool get _over => _done.isCompleted;

  Future<void> _run(File f, DateTime at, bool loop) async {
    final p = _pool.take();
    StreamSubscription<ProcessingState>? sub;
    try {
      await p.setAudioSource(AudioSource.file(f.path));
      if (_over) return;
      await p.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      if (_over) return;
      await p.setVolume(_volume);
      final wait = at.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (_over) return;
      _p = p;
      sub = p.processingStateStream.listen((s) {
        if (s == ProcessingState.completed) _finish();
      });
      unawaited(p.play().catchError((Object _) {}));
      await _done.future;
    } catch (_) {
      // a sound that cannot play is a sound that has ended
    } finally {
      _finish();
      _p = null;
      unawaited(sub?.cancel());
      unawaited(_pool.give(p));
    }
  }

  void _finish() {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  set volume(double v) {
    _volume = v;
    unawaited(_p?.setVolume(v).catchError((Object _) {}));
  }

  @override
  void stop() => _finish();

  @override
  Future<void> get done => _done.future;
}
