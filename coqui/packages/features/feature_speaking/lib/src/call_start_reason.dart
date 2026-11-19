/// Why `CallSession.start` threw, and the line each reason shows (llamada.js: inicia, desconecta).
library;

import 'package:feature_speaking/src/call_text.dart';

/// The ways a call can fail to start. They are the ones the contract is getting as `CallStartError.kind`
/// (request 19-coqui-platform-needs-coqui-contracts-call-start-reason).
enum CallStartReason { microphone, library, failed, unavailable }

// llamada.js, inicia: /NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied/i on the error's name and message.
final RegExp _micError = RegExp(
  'NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied',
  caseSensitive: false,
);

// llamada.js, desconecta: a narrower test on the text of an error that came through onError.
final RegExp _micErrorLate = RegExp(
  'microphone|permission',
  caseSensitive: false,
);

/// The one place that turns what `start` threw into a reason.
///
/// Until `CallStartError` (with its `kind`) is on main this reads the text, as llamada.js does: the error's
/// `toString()` is `<Name>: <message>` (a refused microphone is `NotAllowedError: ...`, a library that did not
/// load `LibraryError: ...`, a build with calls off `NotAvailable: ...`). When the contract has the type, only
/// this function changes: `error is CallStartError ? error.kind : ...`.
CallStartReason callStartReason(Object error) {
  final text = '$error';
  if (_micError.hasMatch(text)) return CallStartReason.microphone;
  if (text.startsWith('LibraryError')) return CallStartReason.library;
  if (text.startsWith('NotAvailable')) return CallStartReason.unavailable;
  return CallStartReason.failed;
}

/// The one plain line a reason shows. `unavailable` has no line of its own in llamada.js (a build with no
/// voice library did not load it): it shows the generic one, like `failed`.
String callStartLine(CallStartReason reason) => switch (reason) {
  CallStartReason.microphone => CallTexts.micOff,
  CallStartReason.library => CallTexts.libraryFailed,
  CallStartReason.failed || CallStartReason.unavailable => CallTexts.notStarted,
};

/// llamada.js, desconecta: the call dropped before it connected; was the microphone the cause?
String callDroppedLine(String lastError) =>
    _micErrorLate.hasMatch(lastError) ? CallTexts.micOff : CallTexts.notStarted;
