import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/io/just_audio_sink.dart';
import 'package:just_audio/just_audio.dart';

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
  }) : _http = http ?? HttpClient();

  /// The made sounds (on a PcmGraph).
  final SoundCore effects;
  final ClipLookup clipInfo;
  final Uri base;
  final HttpClient _http;
  final PlayerPool _pool = PlayerPool();
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

  @override
  Future<void> preload(Iterable<String> clipIds) async {
    await Future.wait([for (final id in clipIds) _load(id)]);
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    final info = clipInfo(clipId);
    if (info == null) return false;
    final file = await _load(clipId);
    if (file == null) return false;
    final p = _pool.take();
    final playing = _Playing(p);
    _live.add(playing);
    StreamSubscription<ProcessingState>? sub;
    Timer? lim;
    try {
      final len = math.max(50, info.endMs - info.startMs);
      await p.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.file(file.path),
          start: Duration(milliseconds: info.startMs),
          end: Duration(milliseconds: info.startMs + len),
        ),
      );
      await p.setVolume(muted ? 0 : 1);
      if (!playing.done.isCompleted) {
        sub = p.processingStateStream.listen((s) {
          if (s == ProcessingState.completed) playing.end(true);
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
  final AudioPlayer player;
  final Completer<bool> done = Completer();

  void end(bool v) {
    if (!done.isCompleted) done.complete(v);
  }
}
