# Request: CallToken, CallTokenSource, and token-server CallStartFailure kinds in coqui_contracts

## What I need

In `coqui/packages/core/coqui_contracts/lib/src/call.dart`:

1. Add `CallToken` holding the server-minted credential and session metadata defined by `docs/proyecto/25-call-token-server.md` (#248):
   ```dart
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
       // Validates:
       // - non-null signedUrl / conversationToken are non-blank
       // - exactly one of signedUrl or conversationToken is non-null
       // - connectionType is non-blank
       // - signedUrl requires connectionType == 'websocket'
     }

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

     final String? signedUrl;
     final String? conversationToken;
     final String connectionType;
     final DateTime? expiresAt;
     final int? maxDurationSeconds;
     final int? dailyLimit;
     final int? remainingToday;
   }
   ```

2. Add `abstract interface class CallTokenSource`:
   ```dart
   abstract interface class CallTokenSource {
     Future<CallToken> fetchToken(
       CallBrief brief, {
       List<String> wordsOpen = const [],
       List<String> wordsHeard = const [],
     });
   }
   ```

3. Add the token-server `CallStartFailure` enum values designed in `docs/proyecto/25-call-token-server.md` (`dailyLimit`, `authRequired`, `serviceBusy`) alongside the existing `microphone`, `library`, `failed`, and `unavailable` kinds, with matching default error names in `CallStartError`, so `CallTokenSource` implementations and `feature_speaking` can render the calm in-app states cleanly without scraping error text.

## Why

Issue #249 (`CallSession accepts a signed link`, implementing the client half of `docs/proyecto/25-call-token-server.md` from #248) updates `ConvCallSession` and `createCallSession` in `coqui_platform` to accept an optional `CallTokenSource`. When present, `CallSession.start` requests a short-lived `CallToken` (`signedUrl` or `conversationToken`) and passes it to ElevenLabs `startSession` without `agentId` or client-supplied `dynamicVariables`.

Because `coqui_contracts` is the shared interface package owned by the architecture lane and `lane:coqui_platform` may not edit `coqui_contracts` directly, these types need to be promoted into `coqui_contracts` so the app shell, future HTTP token client, and `feature_speaking` can share one contract.

## What I am using meanwhile

A local provisional copy of `CallToken` and `CallTokenSource` in `coqui/packages/core/coqui_platform/lib/src/call/call_token.dart`, re-exported from `coqui/packages/core/coqui_platform/lib/coqui_platform.dart`. `ConvCallSession.start` already rethrows any `CallStartError` from `CallTokenSource.fetchToken` intact, so once `dailyLimit`, `authRequired`, and `serviceBusy` land in `coqui_contracts`, `coqui_platform` can drop its local copy and re-export/use `coqui_contracts` with no behavior change.

## Order and branch

- Order: 249 (`CallSession accepts a signed link`)
- Branch: `lane/coqui_platform/249`
