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
