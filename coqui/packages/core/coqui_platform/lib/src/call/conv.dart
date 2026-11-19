/// The ElevenLabs client as llamada.js uses it: `window.ELConv` (the module's `Conversation`), its
/// `startSession(options)`, and the conversation it gives. The web's is the real client by interop
/// (src/web/el_conv.dart); `CallStub` is the old page's stub, ported; the tests have their own.
abstract interface class ConvLibrary {
  /// llamada.js: precarga. True once the client is there. After a failed try the next call tries again.
  Future<bool> load();

  /// Null before the first try has ended; then whether the last try loaded it.
  bool? get loaded;

  /// `ELConv.startSession(options)`. Throws [ConvStartError] when it is refused.
  Future<Conv> startSession(ConvOptions options);
}

/// What the page passes to `startSession` (llamada.js, inicia). The callbacks get what the client gives,
/// as Dart values (a Map for an object, a String, or null).
class ConvOptions {
  ConvOptions({
    required this.agentId,
    required this.connectionType,
    required this.dynamicVariables,
    required this.clientTools,
    required this.onConnect,
    required this.onDisconnect,
    required this.onError,
    required this.onMessage,
    required this.onModeChange,
  });

  final String agentId;
  final String connectionType;
  final Map<String, String> dynamicVariables;

  /// name -> the tool; what it returns is the tool's answer.
  final Map<String, Object? Function(Object? parameters)> clientTools;
  final void Function(Object? details) onConnect;
  final void Function(Object? details) onDisconnect;
  final void Function(Object? error) onError;
  final void Function(Object? message) onMessage;
  final void Function(Object? mode) onModeChange;
}

/// The conversation `startSession` gives.
abstract interface class Conv {
  void sendUserMessage(String text);
  void endSession();
  double getInputVolume();
  double getOutputVolume();

  /// `setVolume({volume})`; nothing where the client has none (the old stub).
  void setVolume(double v);
}

/// `startSession` refused: the error's name and message (a refused microphone is "NotAllowedError").
class ConvStartError implements Exception {
  const ConvStartError(this.name, this.message);
  final String name;
  final String message;

  @override
  String toString() => '$name: $message';
}
