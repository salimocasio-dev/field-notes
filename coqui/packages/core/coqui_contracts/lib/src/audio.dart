/// The recorded lines and the made sounds (juego.js, "sound: effects, and the recorded voice").
abstract interface class ClipPlayer {
  Future<void> unlock(); // call inside the first tap

  /// Makes the clips ready to play, and returns the ids that could NOT be made ready (no recording, no
  /// marks, a failed fetch, a failed decode), in the order given and without duplicates. An empty list
  /// means every clip asked for is ready. It never throws for a clip that fails. A clip already loaded
  /// is not loaded again and is not reported. (juego.js: loadVoice and its VOICE flag)
  Future<List<String>> preload(Iterable<String> clipIds);
  Future<bool> play(
    String clipId, {
    Duration? limit,
  }); // true when it played to its end mark
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  });
  void noiseBurst({double vol = 1}); // thunder
  void loop(String name, bool on); // 'rain'
  abstract bool muted;
  Future<void> stop();
}

/// Optional interface for a [ClipPlayer] that supports variable playback speed
/// (for example `0.75×`, `0.9×`, or `1.0×` in the reader).
///
/// Kept separate from [ClipPlayer] (same pattern as `LanguageCatalog` and
/// `CallProgressStore`): adding an abstract member directly to [ClipPlayer]
/// would break players implemented in other packages. Players that do not
/// implement this fall back to [ClipPlayer.play] at normal speed via
/// [ClipPlayerSpeed.playAtRate].
abstract interface class VariableSpeedClipPlayer {
  /// Plays [clipId] at playback [rate] (`1.0` is normal speed).
  /// Returns `true` when the clip played to its end mark.
  Future<bool> playAtRate(String clipId, {double rate = 1.0, Duration? limit});
}

/// Playback-speed helper on [ClipPlayer], delegating to
/// [VariableSpeedClipPlayer] when implemented and falling back to [play]
/// otherwise.
extension ClipPlayerSpeed on ClipPlayer {
  /// Plays [clipId] at playback [rate] when this player implements
  /// [VariableSpeedClipPlayer], or falls back to `play(clipId, limit: limit)`
  /// otherwise.
  Future<bool> playAtRate(String clipId, {double rate = 1.0, Duration? limit}) {
    final p = this;
    return p is VariableSpeedClipPlayer
        ? (p as VariableSpeedClipPlayer).playAtRate(
            clipId,
            rate: rate,
            limit: limit,
          )
        : play(clipId, limit: limit);
  }
}
