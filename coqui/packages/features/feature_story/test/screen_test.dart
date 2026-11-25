// The play screen, state by state: start, narrator caption, touch sign, speech
// bubble, wrong touch, end screens, Listen mode, TXT toggle, answer bubbles,
// NocheMic states (theySpeak, ready, listening, thinking, right, notYet), and
// showPerf chip.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/feature_story.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_not_ready.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';
import 'support/test_scene.dart';

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

  group('the Noche lesson frame around the picture', () {
    testWidgets(
      'start: the 64-high header (close X, five NocheDashes on lessonGround, TXT pill), the picture, the orange start disc',
      (tester) async {
        final s = await openScreen(tester);
        expect(find.byType(StoryHeader), findsOneWidget);
        expect(tester.getSize(find.byType(StoryHeader)).height, 64);
        expect(find.byType(NocheDashes), findsOneWidget);
        final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
        expect(dashes.onLessonGround, isTrue);
        expect(dashes.states, List.filled(5, NocheDashState.notYet));
        expect(find.byType(StoryCloseButton), findsOneWidget);
        expect(find.byType(StoryTxtToggle), findsOneWidget);
        expect(
          tester.widget<StoryTxtToggle>(find.byType(StoryTxtToggle)).on,
          isTrue,
        );
        expect(find.byType(PixelView), findsOneWidget);
        expect(find.byType(NochePlayDisc), findsOneWidget);
        expect(find.byType(NocheMic), findsNothing);
        expect(s.runner.view.screen, StoryScreenState.start);
        // the picture is whole-number scaled: 412 logical pixels at 2.625 are 1081.5 device pixels: 5 for each of the 196
        final size = tester.getSize(find.byType(PixelView));
        expect((size.width * 2.625).round(), 196 * 5);
        expect((size.height * 2.625).round(), 216 * 5);
      },
    );

    testWidgets('the story\'s dashes: a story that says how many it has', (
      tester,
    ) async {
      final s = await openScreen(tester, id: 'el-bizcocho');
      final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
      expect(dashes.states.length, 7);
      expect(s.runner.view.dots, 7);
    });

    testWidgets('the start disc plays: the dashes light as the story goes', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(NochePlayDisc));
      await tester.pump();
      expect(find.byType(NochePlayDisc), findsNothing);
      expect(s.runner.view.screen, StoryScreenState.play);
      await s.until(() => s.runner.view.dotsLit >= 1, what: 'the first dash');
      final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
      final done = dashes.states.where((d) => d == NocheDashState.done).length;
      expect(done, greaterThanOrEqualTo(1));
    });

    testWidgets('the X leaves: all sound stops and the app goes back', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(NochePlayDisc));
      await s.advance(200);
      await tester.tap(find.byType(StoryCloseButton));
      await tester.pump();
      expect(s.nav.backs, 1);
      await s.advance(1000);
      expect(
        s.runner.running,
        isTrue,
      ); // the play was left: nothing goes on, nothing is written
      expect(s.services.progress.played('la-lluvia'), isFalse);
    });

    testWidgets('the TXT pill toggles captions on and off', (tester) async {
      final s = await openScreen(tester);
      expect(s.runner.txtOn, isTrue);
      expect(
        tester.widget<StoryTxtToggle>(find.byType(StoryTxtToggle)).on,
        isTrue,
      );
      await tester.tap(find.byType(StoryTxtToggle));
      await tester.pump();
      expect(s.runner.txtOn, isFalse);
      expect(
        tester.widget<StoryTxtToggle>(find.byType(StoryTxtToggle)).on,
        isFalse,
      );
      await tester.tap(find.byType(StoryTxtToggle));
      await tester.pump();
      expect(s.runner.txtOn, isTrue);
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
        await tester.tap(find.byType(NochePlayDisc));
        await s.until(() => s.runner.W['spot'] != null, what: 'the sign');
        await s.advance(150);
        expect(s.runner.W['spot'], 'casa');
        expect(count(s, _gold), greaterThan(100));
      },
    );

    testWidgets(
      'a scene that is not converted yet: StoryNotReady with close X, the line and Back to the map',
      (tester) async {
        await openScreen(
          tester,
          id: 'la-lluvia',
          scenes: (id, rng) => scenesWithTestScene(testSceneId, rng),
        );
        expect(find.byType(StoryNotReady), findsOneWidget);
        expect(find.byType(StoryCloseButton), findsOneWidget);
        expect(find.byType(NochePlayDisc), findsNothing);
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
    testWidgets('the narrator\'s caption under the picture', (tester) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(NochePlayDisc));
      await s.until(() => s.runner.cap.isNotEmpty, what: 'a caption');
      expect(find.text(s.runner.cap), findsOneWidget);
      expect(s.runner.cap, line(s, 'esta_casa'));
    });

    testWidgets('a speech bubble beside the frog for his lines', (
      tester,
    ) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(NochePlayDisc));
      // the frog's first line is his "¡Ay, la lluvia!", after the first questions
      await s.answerUntil(() => s.runner.bubText.isNotEmpty, what: 'a bubble');
      expect(find.text(s.runner.bubText), findsOneWidget);
      expect(s.runner.view.bubbleWho, 'coqui');
      expect(s.runner.cap, '');
    });

    testWidgets('no text: the caption and the bubble never show', (
      tester,
    ) async {
      final s = await openScreen(tester, txt: TxtMode.no);
      expect(
        tester.widget<StoryTxtToggle>(find.byType(StoryTxtToggle)).on,
        isFalse,
      );
      await tester.tap(find.byType(NochePlayDisc));
      for (var i = 0; i < 50; i++) {
        await s.advance(500);
        expect(s.runner.cap, '');
        expect(s.runner.bubText, '');
      }
    });
  });

  group('the touch', () {
    testWidgets(
      'the big sign shows what to touch: the dimmed picture, the pulsing frame and the hand',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(NochePlayDisc));
        await s.until(() => s.runner.W['spot'] != null, what: 'the sign');
        await s.advance(150);
        expect(s.runner.W['spot'], 'casa');
        expect(count(s, _gold), greaterThan(100));
        // the hand over the view is white with a dark edge
        expect(count(s, 0xFFFFFFFF), greaterThan(50));
      },
    );

    testWidgets(
      'a tap on the picture is a touch on the thing there; a wrong one is poked',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(NochePlayDisc));
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
        await s.until(
          () => s.runner.pendingNow?.busy == false,
          what: 'the name',
        );
        expect(s.runner.W['spot'], 'casa');
        expect(s.runner.W['lost'], 0);
        await s.tapThing('casa');
        await s.until(() => s.runner.W['spot'] == null, what: 'the answer');
        expect(s.runner.W['spot'], isNull);
      },
    );

    testWidgets(
      'a story played through, answering rightly, ends on the end screen with its title',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(NochePlayDisc));
        await _answer(s, () => true);
        expect(s.runner.view.screen, StoryScreenState.end);
        expect(find.text('La lluvia'), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Next story'), findsOneWidget);
        final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
        expect(dashes.states.every((d) => d == NocheDashState.done), isTrue);
        expect(s.services.progress.played('la-lluvia'), isTrue);
      },
    );

    testWidgets(
      'one error: the same end screen, and the step lost is told to the progress store',
      (tester) async {
        final s = await openScreen(tester);
        await tester.tap(find.byType(NochePlayDisc));
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
        await tester.tap(find.byType(NochePlayDisc));
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
    testWidgets(
      'a next the course does not name: no Next story, Map is the NochePrimaryButton, Play again is NocheOutlineButton',
      (tester) async {
        final s = await openScreen(
          tester,
          course: EditedCourse((id, f) {
            if (id == 'la-lluvia') f['next'] = 'que-quieres';
          }),
        );
        expect(s.course.meta('que-quieres'), isNull);
        await tester.tap(find.byType(NochePlayDisc));
        await _answer(s, () => true);
        expect(s.runner.view.screen, StoryScreenState.end);
        expect(s.runner.S['next'], 'que-quieres');
        expect(find.text('Next story'), findsNothing);
        expect(find.byType(NocheOutlineButton), findsOneWidget);
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
        expect(find.widgetWithText(NochePrimaryButton, 'Map'), findsOneWidget);
        await tester.tap(find.text('Map'));
        expect(s.nav.routes, [const TabRoute('map')]);
      },
    );

    testWidgets(
      'a next the course names: Next story is NochePrimaryButton, Play again and Map are NocheOutlineButtons',
      (tester) async {
        final s = await openScreen(tester);
        expect(s.runner.S['next'], 'el-bizcocho');
        expect(s.course.meta('el-bizcocho'), isNotNull);
        await tester.tap(find.byType(NochePlayDisc));
        await _answer(s, () => true);
        expect(find.byType(NocheOutlineButton), findsNWidgets(2));
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(
          find.widgetWithText(NochePrimaryButton, 'Next story'),
          findsOneWidget,
        );
        expect(find.widgetWithText(NocheOutlineButton, 'Map'), findsOneWidget);
        await tester.tap(find.text('Next story'));
        expect(s.nav.routes, [const StoryRoute('el-bizcocho')]);
      },
    );
  });

  group('Listen mode', () {
    testWidgets(
      'the story goes through by itself; at the end Play again and Map, no Next story',
      (tester) async {
        final s = await openScreen(tester, listen: true);
        await tester.tap(find.byType(NochePlayDisc));
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

  group('the answer bubbles', () {
    testWidgets(
      'a question with answer bubbles: both are drawn in the picture while he chooses',
      (tester) async {
        final s = await openScreen(tester, id: 'el-bizcocho');
        await tester.tap(find.byType(NochePlayDisc));
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
        expect(count(s, 0xFFFFFFFF), greaterThan(2 * 40 * 36 ~/ 2));
      },
    );
  });

  group('the Noche mic', () {
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

    NocheMicState? micState(WidgetTester tester) {
      final f = find.byType(NocheMic);
      return f.evaluate().isEmpty ? null : tester.widget<NocheMic>(f).state;
    }

    testWidgets(
      'follows the turn through theySpeak, ready, listening, thinking, right, and notYet on a miss with English a11y labels',
      (tester) async {
        final s = await turns(tester, ['none', 'si', 'no', 'si gracias']);
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => micState(tester) == NocheMicState.theySpeak,
          what: 'theySpeak mic',
        );
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.micTheySpeak]!),
          findsOneWidget,
        );
        await s.answerUntil(
          () => micState(tester) == NocheMicState.ready,
          what: 'ready mic',
        );
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.micReady]!),
          findsOneWidget,
        );
        expect(find.byType(StoryHearAgainButton), findsOneWidget);

        // First attempt misses -> notYet ("Otra vez")
        await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
        await tester.pump();
        expect(micState(tester), NocheMicState.listening);
        await s.until(
          () => micState(tester) == NocheMicState.notYet,
          what: 'notYet after miss',
        );
        expect(find.text('Otra vez'), findsOneWidget);
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.micNotYet]!),
          findsOneWidget,
        );

        // Second attempt succeeds -> listening -> thinking -> right
        await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
        await tester.pump();
        expect(micState(tester), NocheMicState.listening);
        await s.until(
          () => micState(tester) == NocheMicState.thinking,
          what: 'thinking',
        );
        expect(find.text('Un momento'), findsOneWidget);
        await s.until(
          () => micState(tester) == NocheMicState.right,
          what: 'right',
        );
        expect(find.text('¡Muy bien!'), findsOneWidget);
      },
    );

    testWidgets(
      'the mic takes a tap only when ready or notYet (disabled during theySpeak)',
      (tester) async {
        final s = await turns(tester, ['si']);
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => micState(tester) == NocheMicState.theySpeak,
          what: 'theySpeak mic',
        );
        await tester.tap(
          find.byKey(const ValueKey('noche_mic_disc')),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(s.runner.HAB.est, 'dead');
        final handle = tester.ensureSemantics();
        await tester.pump();
        expect(
          tester.getSemantics(
            find.bySemanticsLabel(NocheA11y.english[NocheA11y.micTheySpeak]!),
          ),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            label: NocheA11y.english[NocheA11y.micTheySpeak]!,
          ),
        );
        handle.dispose();
      },
    );

    testWidgets('with motion on, listening bars animate', (tester) async {
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
      await tester.tap(find.byType(NochePlayDisc));
      await s.answerUntil(
        () => micState(tester) == NocheMicState.ready,
        what: 'ready mic',
      );
      await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
      await s.advance(100);
      expect(micState(tester), NocheMicState.listening);
      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group('showPerf: the bake time of the state on screen', () {
    testWidgets('off by default: no corner chip', (tester) async {
      await openScreen(tester);
      expect(find.byKey(const Key('story-perf-chip')), findsNothing);
      expect(find.textContaining('scene bake'), findsNothing);
    });

    testWidgets(
      'on: a corner chip under the 64-high header gives the bake of the state now drawn',
      (tester) async {
        final s = await openScreen(tester, showPerf: true);
        final chip = find.byKey(const Key('story-perf-chip'));
        expect(chip, findsOneWidget);
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
          greaterThanOrEqualTo(StoryHeader.height),
        );
        expect(find.byType(StoryHeader), findsOneWidget);
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
