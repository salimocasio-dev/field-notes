import 'package:coqui_contracts/src/course.dart';

/// What happens in a call with Danny (llamada.js: the session's handlers).
sealed class CallEvent {
  const CallEvent();
}

/// onConnect.
final class Connected extends CallEvent {
  const Connected();
}

/// onMessage from the agent: one of Danny's lines.
final class AgentLine extends CallEvent {
  const AgentLine(this.text);
  final String text;
}

/// onMessage from the user: what was heard of the learner.
final class Heard extends CallEvent {
  const Heard(this.text);
  final String text;
}

/// onModeChange.
// DECISION(order 02): the mode stays the string the session gives
// ('speaking' or 'listening'), as llamada.js reads `m.mode`.
final class Mode extends CallEvent {
  const Mode(this.mode);
  final String mode;
}

/// A client tool the agent called, with its arguments (llamada.js: show_picture, {picture}).
final class Tool extends CallEvent {
  const Tool(this.name, this.args);
  final String name;
  final Map<String, dynamic> args;
}

/// onError.
final class CallError extends CallEvent {
  const CallError(this.message);
  final String message;
}

/// onDisconnect, with its reason ('user', 'agent', ...).
final class Ended extends CallEvent {
  const Ended(this.reason);
  final String reason;
}

/// Why a call could not start (llamada.js, inicia, and the line its call screen shows for each).
enum CallStartFailure {
  /// The microphone was refused: startSession's error name and message match
  /// `/NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied/i`.
  /// "The microphone is off. Allow it in your browser to call."
  microphone,

  /// The voice library did not load (precarga gave false).
  /// "The voice part did not load. Check your connection and try again."
  library,

  /// startSession failed in any other way.
  /// "The call did not start. Check your connection and try again."
  failed,

  /// No calls here: a phone build, or a build with calls off (`AppInfo.callsAllowed`). The old page has no
  /// such case; the call screen is never opened there (the card says calls come later).
  unavailable,
}

/// What [CallSession.start] throws when the call cannot start (order 19b). Its text is `<name>: <message>`:
/// [name] is the client's own error name where there is one (a refused microphone is "NotAllowedError"),
/// so llamada.js's own test on the error's name and message still works on `'$e'`.
class CallStartError implements Exception {
  const CallStartError(this.kind, this.message, {String? name})
    : name =
          name ??
          (kind == CallStartFailure.microphone
              ? 'NotAllowedError'
              : kind == CallStartFailure.library
              ? 'LibraryError'
              : kind == CallStartFailure.unavailable
              ? 'NotAvailable'
              : 'Error');

  final CallStartFailure kind;
  final String message;

  /// The error's name: the client's own, or one for the kind.
  final String name;

  @override
  String toString() => '$name: $message';
}

/// The call with Danny (llamada.js: startSession and the conversation it returns).
abstract interface class CallSession {
  bool get available; // false in a phone build until there is a token server
  /// Starts the session. Throws [CallStartError], and nothing else, when the call cannot start: the
  /// microphone is refused, the voice library did not load, the call fails, or there are no calls here.
  Future<void> start(CallBrief brief, Map<String, String> variables);
  Stream<CallEvent> get events;
  void send(String text);
  void setVolume(double v);

  /// The learner's level now, 0 to 1 (llamada.js: conv.getInputVolume()).
  double inputVolume();

  /// Danny's level now, 0 to 1 (llamada.js: conv.getOutputVolume()).
  double outputVolume();
  Future<void> end();
}
