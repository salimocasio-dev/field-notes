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

/// The call with Danny (llamada.js: startSession and the conversation it returns).
abstract interface class CallSession {
  bool get available; // false in a phone build until there is a token server
  /// Starts the session. Throws when it cannot start: the microphone is refused, or the call fails.
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
