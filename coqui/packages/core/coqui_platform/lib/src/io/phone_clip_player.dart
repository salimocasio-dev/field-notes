import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/io/just_audio_sink.dart';
import 'package:just_audio/just_audio.dart';

/// Minimal playback surface of [AudioPlayer] used by [PhoneClipPlayer], allowing
/// tests to inject a fake without platform audio channels.
abstract interface class PhoneAudioPlayer {
  Future<void> setClip(String path, Duration start, Duration end);
  Future<void> setSpeed(double speed);
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> stop();
  Stream<bool> get completed;
}

class _JustAudioClipPlayer implements PhoneAudioPlayer {
  _JustAudioClipPlayer(this._player);
  final AudioPlayer _player;

  @override
  Future<void> setClip(String path, Duration start, Duration end) =>
      _player.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.file(path),
          start: start,
          end: end,
        ),
      );

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<bool> get completed => _player.processingStateStream
      .where((s) => s == ProcessingState.completed)
      .map((_) => true);
}

class _PhonePlayerPool {
  _PhonePlayerPool(this._make);
  final PhoneAudioPlayer Function() _make;
  final List<PhoneAudioPlayer> _idle = [];

  PhoneAudioPlayer take() => _idle.isNotEmpty ? _idle.removeLast() : _make();

  Future<void> give(PhoneAudioPlayer p) async {
    try {
      await p.stop();
    } catch (_) {}
    _idle.add(p);
  }
}

/// The [ClipPlayer] of a phone build. The made sounds are juego.js's own code ([SoundCore]) on a
/// [PcmGraph] (each rendered once, then played by the plugin). A clip's file is fetched once into the
/// phone's temporary storage ([preload], or the first [play]) and played by just_audio from its start
/// mark to its end mark (at least 50 ms, as juego.js's `Math.max(.05, t1 - t0)`).
class PhoneClipPlayer implements ClipPlayer {
  PhoneClipPlayer({
    required this.effects,
    required this.clipInfo,
    required this.base,
    HttpClient? http,
    PhoneAudioPlayer Function()? makePlayer,
  }) : _http = http ?? HttpClient(),
       _pool = _PhonePlayerPool(
         makePlayer ?? (() => _JustAudioClipPlayer(AudioPlayer())),
       );

  /// The made sounds (on a PcmGraph).
  final SoundCore effects;
  final ClipLookup clipInfo;
  final Uri base;
  final HttpClient _http;
  final _PhonePlayerPool _pool;
  final Map<String, File> _files = {};
  final Map<String, Future<File?>> _loading = {};
  final Set<_Playing> _live = {};
  late final Directory _dir = cacheDir('clips');

  @override
  Future<void> unlock() async {}

  Future<File?> _load(String id) {
    final have = _files[id];
    if (have != null) return Future.value(have);
    final going = _loading[id];
    if (going != null) return going;
    final f = _loading[id] = _fetch(id);
    unawaited(
      f.whenComplete(() {
        if (identical(_loading[id], f)) _loading.remove(id);
      }),
    );
    return f;
  }

  Future<File?> _fetch(String id) async {
    try {
      final info = clipInfo(id);
      if (info == null) return null;
      final url = base.resolve(info.url);
      final rq = await _http.getUrl(url);
      final rs = await rq.close();
      if (rs.statusCode != 200) {
        await rs.drain<void>();
        return null;
      }
      final bytes = <int>[];
      await rs.forEach(bytes.addAll);
      final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${_dir.path}/$safe.mp3');
      await file.writeAsBytes(bytes, flush: true);
      return _files[id] = file;
    } catch (_) {
      return null;
    }
  }

  /// Fetches each clip's file once and gives back the ids that are not ready, in the order given and
  /// without duplicates: no [ClipInfo], a file that cannot be had (the phone decodes at [play], not
  /// here). A clip already fetched is not reported. Never throws for a clip that fails.
  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    final ids = {...clipIds}.toList();
    final files = await Future.wait([for (final id in ids) _load(id)]);
    return [
      for (var i = 0; i < ids.length; i++)
        if (files[i] == null) ids[i],
    ];
  }

  @override
  Future<bool> play(String clipId, {Duration? limit, double rate = 1.0}) async {
    if (!rate.isFinite || rate <= 0) {
      throw ArgumentError.value(rate, 'rate', 'must be finite and positive');
    }
    final info = clipInfo(clipId);
    if (info == null) return false;
    final file = await _load(clipId);
    if (file == null) return false;
    final p = _pool.take();
    final playing = _Playing(p);
    _live.add(playing);
    StreamSubscription<bool>? sub;
    Timer? lim;
    try {
      final len = math.max(50, info.endMs - info.startMs);
      await p.setClip(
        file.path,
        Duration(milliseconds: info.startMs),
        Duration(milliseconds: info.startMs + len),
      );
      await p.setSpeed(rate);
      await p.setVolume(muted ? 0 : 1);
      if (!playing.done.isCompleted) {
        sub = p.completed.listen((done) {
          if (done) playing.end(true);
        });
        if (limit != null) lim = Timer(limit, () => playing.end(false));
        unawaited(p.play().catchError((Object _) {}));
      }
      return await playing.done.future;
    } catch (_) {
      playing.end(false);
      return false;
    } finally {
      lim?.cancel();
      unawaited(sub?.cancel());
      _live.remove(playing);
      unawaited(_pool.give(p));
    }
  }

  Future<bool> playAtRate(
    String clipId, {
    double rate = 1.0,
    Duration? limit,
  }) => play(clipId, limit: limit, rate: rate);

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => effects.tone(hz, at, dur, wave, vol, toHz);

  @override
  void noiseBurst({double vol = 1}) => effects.trueno(vol);

  @override
  void loop(String name, bool on) {
    if (name != 'rain') return;
    on ? effects.lluvia() : effects.calla();
  }

  @override
  bool get muted => effects.muted;

  @override
  set muted(bool m) {
    effects.muted = m;
    for (final l in _live) {
      unawaited(l.player.setVolume(m ? 0 : 1).catchError((Object _) {}));
    }
  }

  @override
  Future<void> stop() async {
    for (final l in [..._live]) {
      l.end(false);
    }
  }
}

class _Playing {
  _Playing(this.player);
  final PhoneAudioPlayer player;
  final Completer<bool> done = Completer();

  void end(bool v) {
    if (!done.isCompleted) done.complete(v);
  }
}
