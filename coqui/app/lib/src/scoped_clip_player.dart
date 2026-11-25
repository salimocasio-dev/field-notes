/// Per-course clip-id scoping around a platform [ClipPlayer].
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart' show ClipLookup;

/// Separator between a course scope token and the raw clip id.
const String _scopeSeparator = '::';

/// Wraps a platform [ClipPlayer] so every clip id passed through [preload],
/// [play], and [ClipLookup] is namespaced by [scope] (`'$scope::$clipId'`).
///
/// On the web, `createClipPlayer` shares a single `webSoundCore` buffer cache
/// keyed by clip id across player instances. Scoping clip ids per loaded course
/// generation isolates cached recordings and in-flight loads when two courses
/// reuse the same clip id (such as `esta_casa`).
class ScopedClipPlayer implements ClipPlayer {
  ScopedClipPlayer({
    required String scope,
    required ClipLookup clipInfo,
    required ClipPlayer Function(ClipLookup scopedLookup) create,
  }) : _prefix = '$scope$_scopeSeparator' {
    _inner = create((scopedId) {
      if (!scopedId.startsWith(_prefix)) return null;
      return clipInfo(scopedId.substring(_prefix.length));
    });
  }

  /// Removes a [ScopedClipPlayer] prefix from [scopedId], returning the raw
  /// clip id (or [scopedId] unchanged when not scoped).
  static String unscope(String scopedId) {
    final sep = scopedId.indexOf(_scopeSeparator);
    return sep < 0
        ? scopedId
        : scopedId.substring(sep + _scopeSeparator.length);
  }

  final String _prefix;
  late final ClipPlayer _inner;

  String _encode(String clipId) => '$_prefix$clipId';

  String _decode(String scopedId) => scopedId.startsWith(_prefix)
      ? scopedId.substring(_prefix.length)
      : scopedId;

  @override
  Future<void> unlock() => _inner.unlock();

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    final failed = await _inner.preload(clipIds.map(_encode));
    return [for (final id in failed) _decode(id)];
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) =>
      _inner.play(_encode(clipId), limit: limit);

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => _inner.tone(hz, at: at, dur: dur, wave: wave, vol: vol, toHz: toHz);

  @override
  void noiseBurst({double vol = 1}) => _inner.noiseBurst(vol: vol);

  @override
  void loop(String name, bool on) => _inner.loop(name, on);

  @override
  bool get muted => _inner.muted;

  @override
  set muted(bool value) => _inner.muted = value;

  @override
  Future<void> stop() => _inner.stop();
}
