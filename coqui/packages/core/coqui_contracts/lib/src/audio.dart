/// The recorded lines and the made sounds (juego.js, "sound: effects, and the recorded voice").
abstract interface class ClipPlayer {
  Future<void> unlock(); // call inside the first tap
  Future<void> preload(Iterable<String> clipIds);
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
