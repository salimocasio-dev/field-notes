# 19: coqui_platform needs coqui_contracts: why a call did not start

## What I need

A way for the call screen to know why `CallSession.start` failed, in coqui_contracts. For example:

```dart
enum CallStartFailure { microphone, library, failed, unavailable }
class CallStartError implements Exception { const CallStartError(this.failure, this.message); final CallStartFailure failure; final String message; }
```

with `start` documented as throwing it.

## Why

Order 19 ("start then throws as the contract says") and order 24 (the call screen). llamada.js shows a different line for each case:

- the microphone refused: "The microphone is off. Allow it in your browser to call." (it tests `NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied` against the error's name and message);
- the library did not load: "The voice part did not load. Check your connection and try again.";
- anything else: "The call did not start. Check your connection and try again.".

The contract only says that `start` throws, and a feature cannot import coqui_platform, so it cannot tell these apart by type.

## What I am using meanwhile

`CallStartException(name, message)` in coqui_platform. Its `toString()` is `<name>: <message>`:

- `NotAllowedError: Permission denied` for a refused microphone (the client's own error name and message);
- `LibraryError: ...` when the library did not load;
- `NotAvailable: ...` in a phone build or where calls are off;
- anything else is the client's own error.

So a call screen can apply llamada.js's own regex to `'$e'`. The coqui_testing fake throws `Exception('NotAllowedError: Permission denied')`, which reads the same under that regex.

Related, no change needed now: the old page loads the library ahead (precarga) when Hablar shows the open card. The contract has no preload, so reading `CallSession.available` on the web starts the load. A `preload()` member would make that moment explicit.

## Order and branch

Order 19, `lane/coqui_platform/19`.
