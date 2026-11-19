// What a widget test of the play screen needs: the screen on the fakes, a clock the test moves, clips that take their
// marks' length in the test's own time, and the runner and the frame to look inside.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart' show PixelView, Services;
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/screen/frame_renderer.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../tool/dev_scene.dart';

import 'package:feature_story/src/screen/scene_frame.dart';

/// A clip player whose lines take as long as their marks say, on the test's time.
class TimedClips extends FakeClipPlayer {
  TimedClips(CourseCatalog course)
    : super(
        lengthOf: (id) {
          final c = course.clip(id);
          return c == null ? null : c.endMs - c.startMs;
        },
      );

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    final len = lengthOf!(clipId);
    final ok = await super.play(clipId, limit: limit);
    if (len != null) {
      final cap = limit?.inMilliseconds;
      await Future<void>.delayed(
        Duration(milliseconds: cap != null && cap < len ? cap : len),
      );
    }
    return ok;
  }
}

/// The sample course with changes to a story file, for a check (as `habla_motor_check.py` marks clips in a scratch copy).
class EditedCourse extends FakeCourseCatalog {
  EditedCourse(this.edit);

  /// Changes a story file the first time it is read.
  final void Function(String id, Map<String, dynamic> file) edit;
  final Map<String, Future<Map<String, dynamic>>> _edited = {};

  @override
  Future<Map<String, dynamic>> story(String id) => _edited[id] ??= () async {
    final f = Map<String, dynamic>.of(await super.story(id));
    edit(id, f);
    return f;
  }();
}

class Screen {
  Screen(this.tester, this.clock, this.nav, this.course, this.services);

  final WidgetTester tester;
  final FakeClock clock;
  final FakeNavigator nav;
  final CourseCatalog course;
  final Services services;
  late StoryRunner runner;
  late FrameRenderer frame;

  /// The screen has told us its runner.
  bool opened = false;
  late Map<String, dynamic> story;

  /// Lets [ms] of time go by, in steps of 20 ms, the clock and the frames together.
  Future<void> advance(int ms) async {
    for (var t = 0; t < ms; t += 20) {
      clock.advance(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Goes on until [ok] is true; fails when [maxMs] pass first.
  Future<void> until(
    bool Function() ok, {
    int maxMs = 180000,
    String what = 'the condition',
  }) async {
    var t = 0;
    while (!ok()) {
      if (t >= maxMs) fail('$what never came (after $maxMs ms of the story)');
      await advance(20);
      t += 20;
    }
  }

  /// Goes on, answering each question rightly 700 ms after it is asked (and touching nothing while a turn is going on),
  /// until [ok] is true.
  Future<void> answerUntil(
    bool Function() ok, {
    int maxMs = 300000,
    String what = 'the condition',
  }) async {
    var t = 0;
    while (!ok()) {
      if (t >= maxMs) fail('$what never came (after $maxMs ms of the story)');
      final pn = runner.pendingNow;
      if (pn != null &&
          pn.asked &&
          pn.tEnd != null &&
          !pn.busy &&
          runner.speaking == 0 &&
          runner.HAB.est == '') {
        await advance(700);
        t += 700;
        if (ok()) return;
        if (identical(runner.pendingNow, pn) && !pn.done) {
          runner.tapThing(
            pn.kind == 'decide' && pn.pick != null ? pn.pick! : pn.live.first,
            100,
            100,
          );
          await tester.pump();
        }
      } else {
        await advance(20);
        t += 20;
      }
    }
  }

  /// Taps the picture where the scene's thing [k] is (the middle of its box).
  Future<void> tapThing(String k) async {
    final b = runner.bx(k);
    final z = runner.cam[2] == 98 ? 2 : 1;
    final tl = tester.getTopLeft(find.byType(PixelView));
    final size = tester.getSize(find.byType(PixelView));
    final px = ((b[0] + b[2] / 2) - runner.cam[0]) * z,
        py = ((b[1] + b[3] / 2) - runner.cam[1]) * z;
    await tester.tapAt(
      tl + Offset(px / 196 * size.width, py / 216 * size.height),
    );
    await tester.pump();
  }
}

/// Opens the screen on story [id] of the sample course (or of [course]).
Future<Screen> openScreen(
  WidgetTester tester, {
  String id = 'la-lluvia',
  bool listen = false,
  TxtMode txt = TxtMode.con,
  StoryOptions? options,
  EditedCourse? course,
  Size size = const Size(412, 915),
  double ratio = 2.625,
  bool reduceMotion = true,
  Object habla = 1,
  SceneFactory? scenes,
  bool showPerf = false,
}) async {
  tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  final clock = FakeClock();
  final nav = FakeNavigator();
  final c = course ?? EditedCourse((id, f) {});
  await tester.runAsync(c.load);
  final stories = <Map<String, dynamic>>[];
  for (final s in ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']) {
    stories.add(
      await tester.runAsync(() => c.story(s)) as Map<String, dynamic>,
    );
  }
  final progress = FakeProgressStore(clock: clock);
  progress.setSetting('habla', habla);
  final services = fakeServices(
    course: c,
    clock: clock,
    nav: nav,
    progress: progress,
    clips: TimedClips(c),
    reduceMotion: reduceMotion,
  );
  final screen = Screen(tester, clock, nav, c, services);
  await tester.pumpWidget(
    MaterialApp(
      home: StoryScreen(
        services: services,
        route: StoryRoute(id, listen: listen),
        scenes: scenes ?? fakeScenes(stories),
        txt: txt,
        session: SpeechSession(),
        options: options,
        showPerf: showPerf,
        onOpen: (r, f) {
          screen.runner = r;
          screen.frame = f;
          screen.opened = true;
        },
      ),
    ),
  );
  // the screen is open when it has told us (reading the story, the scene's sheet and baking its first set take real time);
  // a story whose scene cannot be made never tells: give it a moment
  for (var i = 0; i < 400 && !screen.opened; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  await tester.pump(); // the screen builds its frame once it has opened
  await tester.pump();
  screen.story = stories.firstWhere((s) => s['id'] == id);
  return screen;
}
