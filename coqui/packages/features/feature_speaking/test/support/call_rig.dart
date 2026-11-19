// What the call's tests run on: the scripted fake call of coqui_testing, a clock the test moves, a progress store
// that records every answer, and the sample course made whole (the ten places, the eleven stories of La casa).
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/course_fixture.dart';

/// The sample course with curso.json's ten places and the focus words of La casa's eleven stories (the three
/// the sample has, and the eight it has not: llamada.js reads every one of them).
class FixtureCourse extends FakeCourseCatalog {
  FixtureCourse({super.goodbyeWords})
    : super(
        fetch: (path) async {
          final m = RegExp(r'^cuentos/(.+)\.json$').firstMatch(path);
          final id = m?.group(1);
          if (id != null && fixtureCasaStories.containsKey(id)) {
            // the sample's own story where it has one (its clips and its title), else what llamada.js reads
            final own = sampleFiles[path];
            return own ?? fixtureCasaStories[id]!;
          }
          return sampleFile(path);
        },
      );

  late final List<Place> _all = [
    for (final l in jsonDecode(fixturePlacesJson) as List)
      Place.fromJson(l as Map<String, dynamic>),
  ];

  @override
  List<Place> get places => _all;
}

/// A progress store that keeps a list of every `answer`, as llamada.js's `PAL.responde` was called.
class RecordingProgress extends FakeProgressStore {
  RecordingProgress({super.clock});

  /// [word, skill, ok, ms] for each call.
  final List<List<Object?>> answers = [];

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    answers.add([w, skill.name, ok, ms]);
    return super.answer(w, skill, ok: ok, ms: ms, intro: intro);
  }
}

/// A call, its clock, its course and its store, with the call's controller on them.
class CallRig {
  CallRig._(this.clock, this.progress, this.call, this.course, this.clips);

  final FakeClock clock;
  final RecordingProgress progress;
  final FakeCallSession call;
  final FixtureCourse course;
  final FakeClipPlayer clips;
  late CallController controller;
  int closes = 0;

  /// A rig: [stub] is the fake call's `?stub=` options; [casa] the stories of La casa played (all by default).
  static Future<CallRig> create({
    Set<String> stub = const {},
    int casa = 11,
  }) async {
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    final course = FixtureCourse();
    await course.load();
    final rig = CallRig._(
      clock,
      progress,
      FakeCallSession(stub: stub),
      course,
      FakeClipPlayer(),
    );
    final stories = course.places.first.stories;
    for (final id in stories.take(casa)) {
      progress.storyFinished(
        StoryResult(
          id: id,
          focusWords: const [],
          backAgain: const [],
          lost: 0,
          log: const [],
        ),
      );
    }
    rig.controller = rig.newController();
    return rig;
  }

  CallController newController() => CallController(
    session: call,
    clock: clock,
    course: course,
    progress: progress,
    placeId: course.places.first.id,
    clips: clips,
    onClose: () => closes++,
  );

  Services services() => fakeServices(
    progress: progress,
    course: course,
    call: call,
    clock: clock,
    clips: clips,
  );

  /// Moves the clock and the test's fake time on together, [step] ms at a time, calling the controller's
  /// [CallController.tick] as the screen does while it [CallController.ticking].
  Future<void> elapse(WidgetTester tester, int ms, {int step = 50}) async {
    var left = ms;
    while (left > 0) {
      final d = left < step ? left : step;
      clock.advance(Duration(milliseconds: d));
      await tester.pump(Duration(milliseconds: d));
      if (controller.ticking) controller.tick();
      left -= d;
    }
  }

  /// Runs until [done] is true, at most [maxMs]; returns the ms it took.
  Future<int> until(
    WidgetTester tester,
    bool Function() done, {
    int maxMs = 60000,
    int step = 50,
  }) async {
    var t = 0;
    while (!done() && t < maxMs) {
      await elapse(tester, step, step: step);
      t += step;
    }
    return t;
  }

  /// The words llamada.js's matching finds in the stories of La casa, in order.
  List<String> get casaWords => <String>{
    for (final e in fixtureCasaStories.entries)
      ...((jsonDecode(e.value) as Map)['focus_words'] as List).cast<String>(),
  }.toList();

  void dispose() {
    controller.dispose();
    call.dispose();
  }
}
