// Services for widget tests: the fakes of coqui_testing on the whole course, at a phone's size.
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'call_rig.dart';
import 'scripted_call.dart';
import 'speaking_seeds.dart';

/// A phone: its size in CSS px and its device pixel ratio (the two references, and the two the old page was also checked at).
class Phone {
  const Phone(this.name, this.width, this.height, this.ratio);
  final String name;
  final double width;
  final double height;
  final double ratio;

  static const android = Phone('android 412x915', 412, 915, 2.625);
  static const iphone = Phone('iphone 390x844', 390, 844, 3);
  static const small = Phone('small 360x640', 360, 640, 3);
  static const side = Phone('on its side 844x390', 844, 390, 3);

  void use(WidgetTester tester) {
    tester.view.physicalSize = Size(width * ratio, height * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
  }
}

/// A world to run a screen in: the fakes, the progress of a reference picture, the call scripted.
class World {
  World._(
    this.clock,
    this.progress,
    this.course,
    this.call,
    this.nav,
    this.haptics,
    this.speech,
    this.services,
  );

  final FakeClock clock;
  final RecordingProgress progress;
  final FixtureCourse course;
  final ScriptedCall call;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final FakeSpeechListener speech;
  final Services services;

  /// [seed]: a progress state of the reference pictures (vacio, curso, casi, todo, nivel); none: empty.
  static Future<World> create({
    String? seed = 'todo',
    Set<String> stub = const {},
    bool callAvailable = true,
    FakeSpeechListener? speech,
    bool reduceMotion = false,
    ScriptedCall? call,
  }) async {
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    if (seed != null) {
      progress.import(speakingSeeds[seed]!);
    }
    final course = FixtureCourse();
    await course.load();
    final c = call ?? ScriptedCall(stub: stub, available: callAvailable);
    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final sp = speech ?? FakeSpeechListener();
    return World._(
      clock,
      progress,
      course,
      c,
      nav,
      haptics,
      sp,
      fakeServices(
        progress: progress,
        course: course,
        call: c,
        nav: nav,
        haptics: haptics,
        speech: sp,
        clock: clock,
        reduceMotion: reduceMotion,
      ),
    );
  }

  /// [screen] in a MaterialApp with the shared theme.
  Widget app(Widget screen) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: coquiTheme(),
    home: Scaffold(body: screen),
  );

  /// Moves the clock and the test's time on together, [step] ms at a time (the screen's own timer ticks).
  Future<void> elapse(WidgetTester tester, int ms, {int step = 50}) async {
    var left = ms;
    while (left > 0) {
      final d = left < step ? left : step;
      clock.advance(Duration(milliseconds: d));
      await tester.pump(Duration(milliseconds: d));
      left -= d;
    }
  }

  void dispose() => call.dispose();

  /// Takes the screen down (a live call it holds is ended, as it is when the screen leaves), then the fakes' timers.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    dispose();
  }
}
