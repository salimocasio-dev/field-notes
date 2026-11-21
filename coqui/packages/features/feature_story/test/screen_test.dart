// The play screen, state by state: the pictures of coqui/ref/pantallas/ that order 15 serves (the story page: start, the
// narrator's caption, the touch sign, a speech bubble, a wrong touch, the end screens, Listen mode, no text, the answer
// bubbles, the mic in each state). The screen is built on the fakes, with a scene of our own.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:feature_story/feature_story.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screen_harness.dart';

const _gold = 0xFF40E0FF; // "#FFE040", the touch sign's frame

int count(Screen s, int colour) {
  var n = 0;
  for (final p in s.frame.display) {
    if (p == colour) n++;
  }
  return n;
}

String line(Screen s, String id) =>
    ((s.story['clips'] as Map)[id] as Map)['text'] as String;

void main() {
  testWidgets(
    'the module answers a story route and nothing else; it has no tab',
    (tester) async {
      const m = StoryModule();
      final services = fakeServices();
      expect(m.id, 'story');
      expect(m.tab(services), isNull);
      expect(m.screenFor(const ReviewRoute(), services), isNull);
      expect(
        m.screenFor(const StoryRoute('la-lluvia'), services),
        isA<Widget>(),
      );
    },
  );

  testWidgets(
    'the module hands its TXT setting (when the words show) to the screen: con unless it is told, then the one it is told',
    (tester) async {
      final services = fakeServices();
      TxtMode shown(StoryModule m) =>
          (m.screenFor(const StoryRoute('la-lluvia'), services)! as StoryScreen)
              .txt;
      expect(shown(const StoryModule()), TxtMode.con);
      expect(shown(const StoryModule(txt: TxtMode.tras)), TxtMode.tras);
      expect(shown(const StoryModule(txt: TxtMode.no)), TxtMode.no);
    },
  );

  group('the lesson frame around the picture', () {
    testWidgets(
      'start (ref 130): the close X, five dashes none lit, the sound button, the picture, the green start disc',
      (tester) async {
        final s = await openScreen(tester);
        expect(find.byType(LessonFrame), findsOneWidget);
        expect(find.byType(LessonProgressDashes), findsOneWidget);
        final dashes = tester.widget<LessonProgressDashes>(
          find.byType(LessonProgressDashes),
        );
        expect((dashes.segments, dashes.done), (5, 0));
        expect(find.byType(LessonCloseButton), findsOneWidget);
        expect(find.byType(LessonSoundButton), findsOneWidget);
        expect(find.byType(PixelView), findsOneWidget);
        expect(find.byType(LessonStartButton), findsOneWidget);
        expect(find.byType(StoryMicButton), findsNothing);
        expect(s.runner.view.screen, StoryScreenState.start);
        // the picture is whole-number scaled: 380 logical pixels at 2.625 are 997 device pixels: 5 for each of the 196
        final size = tester.getSize(find.byType(PixelView));
        expect((size.width * 2.625).round(), 196 * 5);
        expect((size.height * 2.625).round(), 216 * 5);
      },
    );

    testWidgets('the story\'s dashes: a story that says how many it has', (
      tester,
    ) async {
      final s = await openScreen(tester, id: 'el-bizcocho');
      final dashes = tester.widget<LessonProgressDashes>(
        find.byType(LessonProgressDashes),
      );
      expect(dashes.segments, 7);
      expect(s.runner.view.dots, 7);
    });

    testWidgets('the start disc plays: the dashes light as the story goes', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(LessonStartButton));
      await tester.pump();
      expect(find.byType(LessonStartButton), findsNothing);
      expect(s.runner.view.screen, StoryScreenState.play);
      await s.until(() => s.runner.view.dotsLit >= 1, what: 'the first dash');
      final dashes = tester.widget<LessonProgressDashes>(
        find.byType(LessonProgressDashes),
      );
      expect(dashes.done, greaterThanOrEqualTo(1));
    });

    testWidgets('the X leaves: all sound stops and the app goes back', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(LessonStartButton));
      await s.advance(200);
      await tester.tap(find.byType(LessonCloseButton));
      await tester.pump();
      expect(s.nav.backs, 1);
      await s.advance(1000);
      expect(
        s.runner.running,
        isTrue,
      ); // the play was left: nothing goes on, nothing is written
      expect(s.services.progress.played('la-lluvia'), isFalse);
    });

    testWidgets('the sound button mutes and shows it', (tester) async {
      final s = await openScreen(tester);
      expect(
        tester.widget<LessonSoundButton>(find.byType(LessonSoundButton)).muted,
        isFalse,
      );
      await tester.tap(find.byType(LessonSoundButton));
      await tester.pump();
      expect(s.services.clips.muted, isTrue);
      expect(
        tester.widget<LessonSoundButton>(find.byType(LessonSoundButton)).muted,
        isTrue,
      );
    });
  });

  group('on the real El frente (order 14: the scenes package\'s registry)', () {
    testWidgets(
      'the set is baked and drawn, the frog starts where the sheet puts him, the first question shows the sign',
      (tester) async {
        final s = await openScreen(tester, scenes: registryScenes);
        // the picture is El frente's, not a flat one: many colours
        expect({...s.frame.display}.length, greaterThan(60));
        expect(s.frame.bakes, 1);
        final q = s.runner.W['cq'] as Map<String, dynamic>;
        expect((
          q['x'],
          q['y'],
          q['s'],
        ), isNot((150, 178, 1))); // the sheet's spot, not the old screen number
        await tester.tap(find.byType(LessonStartButton));
        await s.until(() => s.runner.W['spot'] != null, what: 'the sign');
        await s.advance(150);
        expect(s.runner.W['spot'], 'casa');
        expect(count(s, _gold), greaterThan(100));
      },
    );

    testWidgets(
      'a scene that is not converted yet: the lesson frame and its X, the line "This story is not in the new app yet." and the button "Back to the map" (it was the empty frame and a reported error: see not_converted_test.dart)',
      (tester) async {
        await openScreen(
          tester,
          id: 'la-lluvia',
          scenes: (id, rng) => registryScenes('lago', rng),
        );
        expect(find.byType(LessonFrame), findsOneWidget);
        expect(find.byType(LessonCloseButton), findsOneWidget);
        expect(find.byType(LessonStartButton), findsNothing);
        expect(
          find.text('This story is not in the new app yet.'),
          findsOneWidget,
        );
        expect(find.text('Back to the map'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('words on the screen', () {
    testWidgets('the narrator\'s caption under the picture (ref 131)', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(LessonStartButton));
      await s.until(() => s.runner.cap.isNotEmpty, what: 'a caption');
      expect(find.text(s.runner.cap), findsOneWidget);
      expect(s.runner.cap, line(s, 'esta_casa'));
    });

    testWidgets('a speech bubble beside the frog for his lines (ref 133)', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(LessonStartButton));
      // the frog's first line is his "¡Ay, la lluvia!", after the first questions
      await s.answerUntil(() => s.runner.bubText.isNotEmpty, what: 'a bubble');
      expect(find.text(s.runner.bubText), findsOneWidget);
      expect(s.runner.view.bubbleWho, 'coqui');
      expect(s.runner.cap, '');
    });

    testWidgets('no text (ref 138): the caption and the bubble never show', (
      tester,
    ) async {
      final s = await openScreen(tester, txt: TxtMode.no);
      await tester.tap(find.byType(LessonStartButton));
      for (var i = 0; i < 50; i++) {
        await s.advance(500);
        expect(s.runner.cap, '');
        expect(s.runner.bubText, '');
      }
    });
  });

  group('the touch', () {
    testWidgets(
      'the big sign shows what to touch: the dimmed picture, the pulsing frame and the hand (ref 132)',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(LessonStartButton));
        await s.until(() => s.runner.W['spot'] != null, what: 'the sign');
        await s.advance(150);
        expect(s.runner.W['spot'], 'casa');
        expect(count(s, _gold), greaterThan(100));
        // the hand over the view is white with a dark edge
        expect(count(s, 0xFFFFFFFF), greaterThan(50));
      },
    );

    testWidgets(
      'a tap on the picture is a touch on the thing there; a wrong one is poked (ref 134, 135)',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(LessonStartButton));
        await s.until(
          () => s.runner.pendingNow?.asked == true,
          what: 'the question',
        );
        final scene = s.runner.E as dynamic;
        await s.tapThing('palma'); // the palm; the house is asked
        expect(
          (s.runner.W['fx'] as List).any((e) => (e as Map)['t'] == 'star'),
          isTrue,
        );
        expect(scene.pokes, ['palma']);
        expect(s.runner.W['lost'], 0);
        // the question is asked again and the sign is still there
        await s.until(
          () => s.runner.pendingNow?.busy == false,
          what: 'the name',
        );
        expect(s.runner.W['spot'], 'casa');
        // before the door has a name the door is the house: touching it is the right answer
        expect(s.runner.W['lost'], 0);
        // the right thing
        await s.tapThing('casa');
        await s.until(() => s.runner.W['spot'] == null, what: 'the answer');
        expect(s.runner.W['spot'], isNull);
      },
    );

    testWidgets(
      'a story played through, answering rightly, ends on the end screen with its title (ref 137)',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(LessonStartButton));
        await _answer(s, () => true);
        expect(s.runner.view.screen, StoryScreenState.end);
        expect(find.text('La lluvia'), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Next story'), findsOneWidget);
        // the dashes are all lit
        final dashes = tester.widget<LessonProgressDashes>(
          find.byType(LessonProgressDashes),
        );
        expect(dashes.done, dashes.segments);
        expect(s.services.progress.played('la-lluvia'), isTrue);
      },
    );

    testWidgets(
      'one error (ref 136): the same end screen, and the step lost is told to the progress store',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(LessonStartButton));
        var wrong = true;
        await _answer(s, () {
          final w = wrong;
          wrong = false;
          return !w;
        });
        expect(find.text('La lluvia'), findsOneWidget);
        expect(find.text('Next story'), findsOneWidget);
        expect(s.services.progress.story('la-lluvia')?.perdido, isNotNull);
      },
    );

    testWidgets(
      'Next story goes to the next story; Map to the map tab; Play again plays again',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(LessonStartButton));
        await _answer(s, () => true);
        await tester.tap(find.text('Next story'));
        expect(s.nav.last, const StoryRoute('el-bizcocho'));
        await tester.tap(find.text('Map'));
        expect(s.nav.last, const TabRoute('map'));
        await tester.tap(find.text('Play again'));
        await tester.pump();
        expect(s.runner.view.screen, StoryScreenState.play);
        expect(find.text('Play again'), findsNothing);
      },
    );
  });

  group('Next story only where the course names the story', () {
    // The sample course's la-lluvia leads on to el-bizcocho, which the sample course names (the test above). Here the file
    // leads on to a story the course does not name, as the real jugo-de-china leads on to the staged que-quieres.
    testWidgets(
      'a next the course does not name: no Next story, Map is the main button (blue), Play again above it',
      (tester) async {
        final s = await openScreen(
          tester,
          course: EditedCourse((id, f) {
            if (id == 'la-lluvia') f['next'] = 'que-quieres';
          }),
        );
        expect(s.course.meta('que-quieres'), isNull);
        await tester.tap(find.byType(LessonStartButton));
        await _answer(s, () => true);
        expect(s.runner.view.screen, StoryScreenState.end);
        expect(s.runner.S['next'], 'que-quieres');
        expect(find.text('Next story'), findsNothing);
        expect(find.byType(LessonButton), findsNWidgets(2));
        expect(find.text('Play again'), findsOneWidget);
        expect(
          tester
              .widget<LessonButton>(find.widgetWithText(LessonButton, 'Map'))
              .kind,
          LessonButtonKind.blue,
        );
        await tester.tap(find.text('Map'));
        expect(s.nav.routes, [const TabRoute('map')]);
      },
    );

    testWidgets(
      'a next the course names: Next story is the green main button, the outline Map beside Play again, and it opens that story',
      (tester) async {
        final s = await openScreen(tester);
        expect(s.runner.S['next'], 'el-bizcocho');
        expect(s.course.meta('el-bizcocho'), isNotNull);
        await tester.tap(find.byType(LessonStartButton));
        await _answer(s, () => true);
        expect(find.byType(LessonButton), findsNWidgets(3));
        expect(
          tester
              .widget<LessonButton>(
                find.widgetWithText(LessonButton, 'Next story'),
              )
              .kind,
          LessonButtonKind.go,
        );
        expect(
          tester
              .widget<LessonButton>(find.widgetWithText(LessonButton, 'Map'))
              .kind,
          LessonButtonKind.outline,
        );
        await tester.tap(find.text('Next story'));
        expect(s.nav.routes, [const StoryRoute('el-bizcocho')]);
      },
    );
  });

  group('Listen mode (ref 140, 141)', () {
    testWidgets(
      'the story goes through by itself; at the end Play again and Map, no Next story',
      (tester) async {
        final s = await openScreen(tester, listen: true);
        await tester.tap(find.byType(LessonStartButton));
        await s.until(
          () => s.runner.view.screen == StoryScreenState.end,
          what: 'the end',
        );
        expect(s.runner.pendingNow, isNull);
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Next story'), findsNothing);
        expect(s.services.progress.raw['oidos'], isNotNull);
        expect(s.services.progress.played('la-lluvia'), isFalse);
      },
    );
  });

  group('the answer bubbles (ref 142)', () {
    testWidgets(
      'a question with answer bubbles: both are drawn in the picture while he chooses',
      (tester) async {
        final s = await openScreen(tester, id: 'el-bizcocho');
        await tester.tap(find.byType(LessonStartButton));
        await s.answerUntil(
          () => s.runner.W['resp'] != null,
          what: 'the bubbles',
        );
        await s.advance(150);
        final resp = (s.runner.W['resp'] as List).cast<String>();
        expect(resp, ['si', 'no']);
        for (final k in resp) {
          final b = s.runner.respBox(k)!;
          expect(b[2], 40);
          expect(b[3], 36);
        }
        // a white box, 40 by 36 picture pixels, at each
        expect(count(s, 0xFFFFFFFF), greaterThan(2 * 40 * 36 ~/ 2));
      },
    );
  });

  group('the mic (ref 144 to 150)', () {
    EditedCourse marked() => EditedCourse((id, f) {
      if (id != 'el-bizcocho') return;
      final c = Map<String, dynamic>.of(
        (f['clips'] as Map).cast<String, dynamic>(),
      );
      for (final k in ['cq_si', 'cq_no', 'cq_si_gracias', 'cq_no_gracias']) {
        final w = k.contains('si') ? 'sí' : 'no';
        final forms = k.contains('si') ? ['sí', 'si'] : ['no'];
        c[k] = {
          ...(c[k] as Map).cast<String, dynamic>(),
          'tu_turno': [
            {'palabra': w, 'formas': forms},
          ],
        };
      }
      f['clips'] = c;
    });

    Future<Screen> turns(WidgetTester tester, List<String> stub) => openScreen(
      tester,
      id: 'el-bizcocho',
      course: marked(),
      options: StoryOptions(micStub: stub, allOpen: true),
      reduceMotion: true,
    );

    StoryMicState? micState(WidgetTester tester) {
      final f = find.byType(StoryMicButton);
      return f.evaluate().isEmpty
          ? null
          : tester.widget<StoryMicButton>(f).state;
    }

    testWidgets(
      'grey while a line plays (dead), green when it is his turn (ready), coral while he is listened to, grey dots while the app thinks, a green tick when heard',
      (tester) async {
        final s = await turns(tester, ['si', 'no', 'si gracias']);
        await tester.tap(find.byType(LessonStartButton));
        await s.answerUntil(
          () => micState(tester) == StoryMicState.dead,
          what: 'the dead mic',
        );
        expect(find.bySemanticsLabel('Micrófono'), findsOneWidget);
        await s.answerUntil(
          () => micState(tester) == StoryMicState.ready,
          what: 'the ready mic',
        );
        // the bubble beside the frog holds only a mic
        expect(s.runner.view.bubbleKind, BubbleKind.mic);
        expect(s.runner.view.bubbleWho, 'coqui');
        await tester.tap(find.byType(StoryMicButton));
        await tester.pump();
        expect(micState(tester), StoryMicState.listening);
        await s.until(
          () => micState(tester) == StoryMicState.processing,
          what: 'processing',
        );
        expect(s.runner.view.bubbleKind, BubbleKind.dots);
        await s.until(
          () => micState(tester) == StoryMicState.ok,
          what: 'the tick',
        );
        expect(s.runner.view.bubbleKind, BubbleKind.tick);
        expect(find.text('si'), findsWidgets);
      },
    );

    testWidgets(
      'the frog is not on screen: the turn\'s bubble stands just above the mic button',
      (tester) async {
        final s = await turns(tester, ['si', 'no', 'si gracias']);
        await tester.tap(find.byType(LessonStartButton));
        await s.answerUntil(
          () => micState(tester) == StoryMicState.dead,
          what: 'the dead mic',
        );
        (s.runner.W['cq'] as Map<String, dynamic>)['vis'] =
            0; // he is off the picture before the bubble is placed
        await s.answerUntil(
          () => micState(tester) == StoryMicState.ready,
          what: 'the ready mic',
        );
        await s.advance(200);
        expect(s.runner.view.bubbleWho, 'mic');
        final mic = tester.getRect(find.byType(StoryMicButton));
        final body = tester.getRect(find.byType(StoryBubbleBody));
        // above the button, centred on it, clear of the listening rings (24 px, and the tail)
        expect(body.bottom, lessThanOrEqualTo(mic.top));
        expect(mic.top - body.bottom, closeTo(24 + 10, 3));
        expect(body.center.dx, closeTo(mic.center.dx, 2));
      },
    );

    testWidgets('the mic takes a tap only when it is ready (aria-disabled)', (
      tester,
    ) async {
      final s = await turns(tester, ['si']);
      await tester.tap(find.byType(LessonStartButton));
      await s.answerUntil(
        () => micState(tester) == StoryMicState.dead,
        what: 'the dead mic',
      );
      await tester.tap(find.byType(StoryMicButton), warnIfMissed: false);
      await tester.pump();
      expect(s.runner.HAB.est, 'dead');
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Micrófono')),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Micrófono',
        ),
      );
      handle.dispose();
    });

    testWidgets(
      'with motion on, listening and the app thinking move (ref 149, 150)',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: marked(),
          options: StoryOptions(
            micStub: ['si', 'no', 'si gracias'],
            allOpen: true,
          ),
          reduceMotion: false,
        );
        await tester.tap(find.byType(LessonStartButton));
        await s.answerUntil(
          () => micState(tester) == StoryMicState.ready,
          what: 'the ready mic',
        );
        await tester.tap(find.byType(StoryMicButton));
        await s.advance(100);
        expect(micState(tester), StoryMicState.listening);
        await s.until(
          () => micState(tester) == StoryMicState.processing,
          what: 'processing',
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.hasRunningAnimations, isTrue);
      },
    );
  });
  group('showPerf: the bake time of the state on screen', () {
    testWidgets('off by default: no corner chip', (tester) async {
      await openScreen(tester);
      expect(find.byKey(const Key('story-perf-chip')), findsNothing);
      expect(find.textContaining('scene bake'), findsNothing);
    });

    testWidgets(
      'on: a corner chip under the top bar gives the bake of the state now drawn, as the frame timed it',
      (tester) async {
        final s = await openScreen(tester, showPerf: true);
        final chip = find.byKey(const Key('story-perf-chip'));
        expect(chip, findsOneWidget);
        // every state baked so far was timed, and the chip shows the one now on screen
        expect(s.frame.bakeMs, isNotEmpty);
        expect(s.frame.bakeMs.length, s.frame.bakes);
        final now = s.frame.currentBakeMs.value!;
        expect(s.frame.bakeMs.values, contains(now));
        expect(
          find.descendant(
            of: chip,
            matching: find.text('scene bake ${now.toStringAsFixed(0)} ms'),
          ),
          findsOneWidget,
        );
        expect(tester.getTopRight(chip).dx, 412 - 4);
        expect(
          tester.getTopLeft(chip).dy,
          greaterThanOrEqualTo(CoquiMetrics.lessonTopBar),
        );
        // the picture and its frame are as without the chip
        expect(find.byType(LessonFrame), findsOneWidget);
        expect(find.byType(PixelView), findsOneWidget);
      },
    );
  });
}

/// Plays the story by answering each question when it is asked: [right] says whether to touch the right thing.
Future<void> _answer(Screen s, bool Function() right) async {
  var guard = 0;
  while (s.runner.view.screen != StoryScreenState.end) {
    if (guard++ > 4000) fail('the story did not end');
    final pn = s.runner.pendingNow;
    if (pn != null &&
        pn.asked &&
        pn.tEnd != null &&
        !pn.busy &&
        s.runner.speaking == 0) {
      await s.advance(700);
      final again = s.runner.pendingNow;
      if (again != null && identical(again, pn)) {
        final r = right();
        String k = pn.live.first;
        if (!r && pn.kind == 'decide') {
          k = pn.live.firstWhere(
            (x) => x != pn.pick,
            orElse: () => pn.live.first,
          );
        }
        s.runner.tapThing(k, 100, 100);
        await s.tester.pump();
      }
    } else {
      await s.advance(100);
    }
  }
}
