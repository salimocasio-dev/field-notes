/// What one listening gave: the recogniser's alternatives, or an error code
/// (the Web Speech names: no-speech, not-allowed, network, aborted, ...), and the
/// ms from the start of listening to the first sound (juego.js, habEmpieza: `ms`).
class SpeechResult {
  SpeechResult({this.alternatives = const [], this.error, this.msToSound});

  List<String> alternatives;
  String? error;
  int? msToSound;
}

/// One listening, started by [SpeechListener.listen].
abstract interface class SpeechTurn {
  Future<SpeechResult> get result;
  Future<void> get speechEnd;
  void cancel();
}

/// Speech recognition (docs/hablar/01-decisiones.md).
abstract interface class SpeechListener {
  Future<bool> available();
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  });
}
