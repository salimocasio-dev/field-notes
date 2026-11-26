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

/// What the page passes to `startSession` (llamada.js, inicia; issue #249 signed link / token).
/// The callbacks get what the client gives, as Dart values (a Map for an object, a String, or null).
class ConvOptions {
  ConvOptions({
    this.agentId,
    this.signedUrl,
    this.conversationToken,
    required this.connectionType,
    this.dynamicVariables,
    required this.clientTools,
    required this.onConnect,
    required this.onDisconnect,
    required this.onError,
    required this.onMessage,
    required this.onModeChange,
  }) {
    if (agentId != null && agentId!.trim().isEmpty) {
      throw ArgumentError.value(agentId, 'agentId', 'Must not be empty.');
    }
    if (signedUrl != null && signedUrl!.trim().isEmpty) {
      throw ArgumentError.value(signedUrl, 'signedUrl', 'Must not be empty.');
    }
    if (conversationToken != null && conversationToken!.trim().isEmpty) {
      throw ArgumentError.value(
        conversationToken,
        'conversationToken',
        'Must not be empty.',
      );
    }
    final credentialCount =
        (agentId != null ? 1 : 0) +
        (signedUrl != null ? 1 : 0) +
        (conversationToken != null ? 1 : 0);
    if (credentialCount != 1) {
      throw ArgumentError(
        'Provide exactly one of agentId, signedUrl, or conversationToken.',
      );
    }
    if ((signedUrl != null || conversationToken != null) &&
        dynamicVariables != null) {
      throw ArgumentError.value(
        dynamicVariables,
        'dynamicVariables',
        'dynamicVariables must be omitted when using signedUrl or conversationToken.',
      );
    }
    if (connectionType.trim().isEmpty) {
      throw ArgumentError.value(
        connectionType,
        'connectionType',
        'Must not be empty.',
      );
    }
    if (signedUrl != null && connectionType != 'websocket') {
      throw ArgumentError.value(
        connectionType,
        'connectionType',
        'signedUrl requires connectionType "websocket".',
      );
    }
  }

  final String? agentId;
  final String? signedUrl;
  final String? conversationToken;
  final String connectionType;
  final Map<String, String>? dynamicVariables;

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
