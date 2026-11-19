// The scripted call of coqui_testing, wrapped so that a test or the dev entry can also have the learner or Danny say
// a line of its own choosing, count the starts, and make `start` fail the way the platform's does.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';

class ScriptedCall implements CallSession {
  ScriptedCall({
    Set<String> stub = const {},
    bool available = true,
    this.startError,
  }) : fake = FakeCallSession(stub: stub, available: available) {
    fake.events.listen(out.add);
  }

  /// The scripted call of coqui_testing: `sent`, `log`, `ended`, `go`, `names`.
  final FakeCallSession fake;

  /// What `start` throws, 400 ms after it is called, instead of starting (null: it starts).
  final Object? startError;

  /// How many times `start` was called (the old check: the call was started once, from the tap).
  int starts = 0;

  /// Every event the controller can hear: the fake's, and what [emit] adds.
  final StreamController<CallEvent> out = StreamController.broadcast();

  /// Has an event come now, as if from the connection.
  void emit(CallEvent e) => out.add(e);

  @override
  bool get available => fake.available;

  @override
  Stream<CallEvent> get events => out.stream;

  @override
  Future<void> start(CallBrief brief, Map<String, String> variables) {
    starts++;
    final err = startError;
    if (err != null) {
      return Future<void>.delayed(
        const Duration(milliseconds: 400),
        () => throw err,
      );
    }
    return fake.start(brief, variables);
  }

  @override
  void send(String text) => fake.send(text);

  @override
  void setVolume(double v) => fake.setVolume(v);

  @override
  double inputVolume() => fake.inputVolume();

  @override
  double outputVolume() => fake.outputVolume();

  @override
  Future<void> end() => fake.end();

  /// What `start` was given.
  Map<String, String>? get variables => fake.variables;
  CallBrief? get brief => fake.brief;
  List<String> get sent => fake.sent;
  List<String> get log => fake.log;
  bool get ended => fake.ended;

  /// Steps the scripted call by hand (`stub=manual`).
  void go(String step) => fake.go(step);

  void dispose() => fake.dispose();
}
