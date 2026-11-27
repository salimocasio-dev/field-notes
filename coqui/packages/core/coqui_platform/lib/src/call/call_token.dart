import 'package:coqui_contracts/coqui_contracts.dart';

/// A short-lived call credential minted by the call-token server (issue #249,
/// `docs/proyecto/25-call-token-server.md`).
///
/// Provisional copy in `coqui_platform` until `coqui_contracts` adds `CallToken`
/// (see `coqui/requests/249-coqui-platform-needs-coqui-contracts-call-token-source.md`).
///
/// Holds either [signedUrl] (WebSocket) or [conversationToken] (WebRTC by default),
/// never both and never neither.
class CallToken {
  CallToken({
    this.signedUrl,
    this.conversationToken,
    String? connectionType,
    this.expiresAt,
    this.maxDurationSeconds,
    this.dailyLimit,
    this.remainingToday,
  }) : connectionType =
           connectionType ?? (signedUrl != null ? 'websocket' : 'webrtc') {
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
    if ((signedUrl == null) == (conversationToken == null)) {
      throw ArgumentError(
        'Provide exactly one of signedUrl or conversationToken.',
      );
    }
    if (this.connectionType.trim().isEmpty) {
      throw ArgumentError.value(
        this.connectionType,
        'connectionType',
        'Must not be empty.',
      );
    }
    if (signedUrl != null && this.connectionType != 'websocket') {
      throw ArgumentError.value(
        this.connectionType,
        'connectionType',
        'signedUrl requires connectionType "websocket".',
      );
    }
  }

  /// Creates a token backed by a signed WebSocket URL.
  CallToken.signedUrl(
    String signedUrl, {
    String connectionType = 'websocket',
    DateTime? expiresAt,
    int? maxDurationSeconds,
    int? dailyLimit,
    int? remainingToday,
  }) : this(
         signedUrl: signedUrl,
         connectionType: connectionType,
         expiresAt: expiresAt,
         maxDurationSeconds: maxDurationSeconds,
         dailyLimit: dailyLimit,
         remainingToday: remainingToday,
       );

  /// Creates a token backed by a WebRTC conversation token.
  CallToken.conversationToken(
    String conversationToken, {
    String connectionType = 'webrtc',
    DateTime? expiresAt,
    int? maxDurationSeconds,
    int? dailyLimit,
    int? remainingToday,
  }) : this(
         conversationToken: conversationToken,
         connectionType: connectionType,
         expiresAt: expiresAt,
         maxDurationSeconds: maxDurationSeconds,
         dailyLimit: dailyLimit,
         remainingToday: remainingToday,
       );

  /// Short-lived signed WebSocket URL (`wss://...`). Mutually exclusive with [conversationToken].
  final String? signedUrl;

  /// Short-lived conversation token (WebRTC). Mutually exclusive with [signedUrl].
  final String? conversationToken;

  /// Connection transport passed to ElevenLabs `startSession` (`'websocket'` or `'webrtc'`).
  final String connectionType;

  /// When the minted token expires, if supplied by the server.
  final DateTime? expiresAt;

  /// Server-enforced hard duration cap for this call, in seconds.
  final int? maxDurationSeconds;

  /// Caller's daily call cap, if reported by the server.
  final int? dailyLimit;

  /// Remaining calls for the caller today, if reported by the server.
  final int? remainingToday;
}

/// Fetches a short-lived [CallToken] for a call from the token server.
///
/// Provisional copy in `coqui_platform` until `coqui_contracts` adds `CallTokenSource`
/// (see `coqui/requests/249-coqui-platform-needs-coqui-contracts-call-token-source.md`).
abstract interface class CallTokenSource {
  Future<CallToken> fetchToken(
    CallBrief brief, {
    List<String> wordsOpen = const [],
    List<String> wordsHeard = const [],
  });
}
