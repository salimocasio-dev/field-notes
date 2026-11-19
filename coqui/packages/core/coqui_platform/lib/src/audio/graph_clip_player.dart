import 'dart:async';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';

/// Finds a clip's [ClipInfo] (the shell passes `CourseCatalog.clip`).
typedef ClipLookup = ClipInfo? Function(String clipId);

/// Fetches a file as bytes.
typedef FetchBytes = Future<Uint8List> Function(Uri url);

/// The [ClipPlayer] of the web: every sound through one [AudioGraph] (the browser's Web Audio), as
/// juego.js plays it. A clip's file is `base.resolve(ClipInfo.url)`; it is fetched and decoded once
/// ([preload], or the first [play]) and played from its start mark to its end mark.
class GraphClipPlayer implements ClipPlayer {
  GraphClipPlayer({
    required this.core,
    required this.clipInfo,
    required this.base,
    required this.fetch,
    this.onUnlock,
  });

  final SoundCore core;
  final ClipLookup clipInfo;
  final Uri base;
  final FetchBytes fetch;

  /// Runs inside [unlock], before the context is made or resumed (web: the iPhone audio session).
  final void Function()? onUnlock;

  final Map<String, Future<GraphClip?>> _loading = {};

  @override
  Future<void> unlock() async {
    onUnlock?.call();
    try {
      await core.ac().resume();
    } catch (_) {}
  }

  /// Fetches and decodes [clipId] once. Null when the clip is unknown or its file cannot be had; a later
  /// call tries again.
  Future<GraphClip?> load(String clipId) {
    final have = core.clips[clipId];
    if (have != null) return Future.value(have);
    final going = _loading[clipId];
    if (going != null) return going;
    final f = _loading[clipId] = _load(clipId);
    unawaited(
      f.whenComplete(() {
        if (identical(_loading[clipId], f)) _loading.remove(clipId);
      }),
    );
    return f;
  }

  Future<GraphClip?> _load(String id) async {
    try {
      final info = clipInfo(id);
      if (info == null) return null;
      final bytes = await fetch(base.resolve(info.url));
      final buf = await core.ac().decodeAudioData(bytes);
      return core.clips[id] = GraphClip(
        buf,
        info.startMs / 1000,
        info.endMs / 1000,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> preload(Iterable<String> clipIds) async {
    await Future.wait([for (final id in clipIds) load(id)]);
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    if (core.clips[clipId] == null && await load(clipId) == null) return false;
    return core.playClip(clipId, limit: limit);
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => core.tone(hz, at, dur, wave, vol, toHz);

  @override
  void noiseBurst({double vol = 1}) => core.trueno(vol);

  /// 'rain' is the only loop juego.js has (SFX.lluvia on, SFX.calla off). Other names do nothing.
  @override
  void loop(String name, bool on) {
    if (name != 'rain') return;
    on ? core.lluvia() : core.calla();
  }

  @override
  bool get muted => core.muted;

  @override
  set muted(bool m) => core.muted = m;

  /// Every clip playing stops and gives false (juego.js: hush). Tones already made and the rain go on.
  @override
  Future<void> stop() async => core.hush();
}
