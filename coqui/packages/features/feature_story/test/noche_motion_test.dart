// N8.8 Story lesson motion tests (`docs/proyecto/24-noche-motion.md` Part 1 &
// N8.8, boards `Noche-Motion-Cuento`, `Noche-Motion-Tocar`, `Noche-Motion-Lugar`)
// plus stable integration keys and silent unrecorded-clip playback coverage.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/motion.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:feature_story/src/wording.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/rig.dart';
import 'support/screen_harness.dart';
import 'support/stories.dart';
import 'support/test_scene.dart';

/// Marks speaking turns on `el-bizcocho` for Spanish or Arabic fake courses.
class _MarkedCourse extends FakeCourseCatalog {
  _MarkedCourse({bool arabic = false})
    : super(
        fetch: arabic ? arabicSampleFile : sampleFile,
        language: arabic ? arabicTestLanguage : Language.spanish,
      );

  final Map<String, Future<Map<String, dynamic>>> _edited = {};

  @override
  Future<Map<String, dynamic>> story(String id) => _edited[id] ??= () async {
    final f = Map<String, dynamic>.of(await super.story(id));
    if (id == 'el-bizcocho') {
      final c = Map<String, dynamic>.of(
        (f['clips'] as Map).cast<String, dynamic>(),
      );
      final isAr = language.code == 'ar';
      c.putIfAbsent(
        'ahora_tu',
        () => {'who': 'narr', 'text': isAr ? 'دورك الآن.' : 'Ahora tú.'},
      );
      for (final k in ['cq_si', 'cq_no', 'cq_si_gracias', 'cq_no_gracias']) {
        final existing = (c[k] as Map).cast<String, dynamic>();
        final yes = k.contains('si');
        final word = isAr ? (yes ? 'نعم' : 'لا') : (yes ? 'sí' : 'no');
        final forms = isAr ? [word] : (yes ? ['sí', 'si'] : ['no']);
        c[k] = {
          ...existing,
          'tu_turno': [
            {'palabra': word, 'formas': forms},
          ],
        };
      }
      f['clips'] = c;
    }
    return f;
  }();
}

/// True when [c] looks like an error-red colour (high red channel, low green/blue).
bool _isRedColor(Color? c) {
  if (c == null || c.a < 0.05) return false;
  return c.r > 0.7 && c.g < 0.35 && c.b < 0.35;
}

/// Asserts that no [DecoratedBox] or [Container] decoration in the current
/// widget tree uses a red colour on fill or border.
void _expectNoRedDecorations(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final dec = box.decoration;
    if (dec is BoxDecoration) {
      expect(_isRedColor(dec.color), isFalse, reason: 'red fill on $box');
      final border = dec.border;
      if (border is Border) {
        expect(
          _isRedColor(border.top.color),
          isFalse,
          reason: 'red border on $box',
        );
      }
    }
  }
}

NocheMicState? _micState(WidgetTester tester) {
  final f = find.byType(NocheMic);
  return f.evaluate().isEmpty ? null : tester.widget<NocheMic>(f).state;
}

Future<void> _loadNocheFonts() async {
  for (final entry in nocheFontFiles.entries) {
    for (final prefix in ['', 'packages/coqui_ui/']) {
      final loader = FontLoader('$prefix${entry.key}');
      for (final path in entry.value.values) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('../../core/coqui_ui/$path').readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
  }
}

void main() {
  group('StoryMotion constants & hero tag', () {
    test('wait constants and shared storyWindowTag match N8.8 & N8.4', () {
      expect(StoryMotion.storyWindowTag('la-lluvia'), 'la-lluvia');
      expect(StoryMotion.lessonArriveDelay, const Duration(milliseconds: 160));
      expect(
        StoryMotion.controlsArriveDelay,
        const Duration(milliseconds: 300),
      );
      expect(StoryMotion.turnRowsDelay, const Duration(milliseconds: 160));
      expect(StoryMotion.missHold, const Duration(milliseconds: 900));
      expect(StoryMotion.rightDashDelay, const Duration(milliseconds: 600));
      expect(StoryMotion.rightNextTurnDelay, const Duration(milliseconds: 700));
      expect(StoryMotion.touchMissHold, const Duration(milliseconds: 1300));
      expect(StoryMotion.touchHitHold, const Duration(milliseconds: 900));
      expect(StoryMotion.endRowsDelay, const Duration(milliseconds: 200));
      expect(StoryMotion.endStageBarDelay, const Duration(milliseconds: 520));
      expect(StoryMotion.endMinutesBarDelay, const Duration(milliseconds: 700));
      expect(StoryMotion.endNextDelay, const Duration(milliseconds: 860));
    });
  });

  group('NocheWindow & lesson arrival', () {
    testWidgets(
      'NocheWindow wraps the 400-high scene with story id hero tag and controls arrive at 300 ms',
      (tester) async {
        await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: false,
        );

        final winFinder = find.byType(NocheWindow);
        expect(winFinder, findsOneWidget);
        final win = tester.widget<NocheWindow>(winFinder);
        expect(win.tag, 'la-lluvia');
        expect(find.byKey(NocheWindow.surfaceKey('la-lluvia')), findsOneWidget);

        final winRect = tester.getRect(winFinder);
        expect(winRect.top, closeTo(StoryHeader.height, 0.5));
        expect(winRect.height, closeTo(StoryScreen.sceneHeight, 0.5));

        // Lesson text rows arrive staggered at 160, 190, 220 ms (start, middle, end).
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryLessonText(
                language: Language.spanish,
                txtOn: true,
                speaker: 'Abuela',
                line: '¿Tienes hambre?',
                promptPrefix: 'Dile a Abuela: ',
                promptWords: 'Tengo hambre.',
                arriveDelay: StoryMotion.lessonArriveDelay,
                reduceMotion: false,
              ),
            ),
          ),
        );

        double dyOf(int i) => tester
            .widget<Transform>(find.byKey(ValueKey('noche_arrive_item_$i')))
            .transform
            .getTranslation()
            .y;

        // At 0 ms: all three rows wait at offset 8 (NocheMotion.row).
        expect(dyOf(0), closeTo(NocheMotion.row, 0.01));
        expect(dyOf(1), closeTo(NocheMotion.row, 0.01));
        expect(dyOf(2), closeTo(NocheMotion.row, 0.01));

        // At 200 ms (after 160 ms speaker start, 190 ms line start, before 220 ms prompt start):
        await tester.pump(const Duration(milliseconds: 200));
        expect(dyOf(0), lessThan(NocheMotion.row));
        expect(dyOf(1), lessThan(NocheMotion.row));
        expect(dyOf(2), closeTo(NocheMotion.row, 0.01));

        // At end (220 + 220 = 440 ms total): all three rows have landed at 0.
        await tester.pump(const Duration(milliseconds: 300));
        expect(dyOf(0), closeTo(0, 0.01));
        expect(dyOf(1), closeTo(0, 0.01));
        expect(dyOf(2), closeTo(0, 0.01));
      },
    );
  });

  group('TXT switch (quick fade)', () {
    testWidgets(
      'toggling TXT animates toggle fill/border and line opacity over quick (start, middle, end)',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: false,
        );
        await tester.tap(find.byKey(const Key('story-start-disc')));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );
        // Settle arrival animations.
        await s.advance(600);

        final lineText = s.runner.view.turnLine;
        expect(find.text(lineText), findsOneWidget);

        // Toggle TXT off: starts at opacity 1, mid-fade at quick ~/ 2, gone at quick.
        await tester.tap(find.byType(StoryTxtToggle));
        await tester.pump();
        final startOp = tester
            .widgetList<Opacity>(
              find.byKey(const ValueKey('story_txt_lines_opacity')),
            )
            .first
            .opacity;
        expect(startOp, closeTo(1.0, 0.05));

        await tester.pump(NocheMotion.quick ~/ 2);
        final midOp = tester
            .widgetList<Opacity>(
              find.byKey(const ValueKey('story_txt_lines_opacity')),
            )
            .first
            .opacity;
        expect(midOp, greaterThan(0.0));
        expect(midOp, lessThan(1.0));

        await tester.pump(NocheMotion.quick);
        await tester.pump();
        expect(find.text(lineText), findsNothing);
        // Speaker stays visible with TXT off.
        expect(
          find.text(s.runner.view.turnSpeaker.toUpperCase()),
          findsOneWidget,
        );
      },
    );
  });

  group('Speaking turn motion (miss, arrow spin, right, zero red)', () {
    testWidgets(
      'miss shows NocheColors.text outline with zero red, holds 900 ms then replays with spinning arrow -> theySpeak -> ready',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['none', 'si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: false,
        );
        await tester.tap(find.byKey(const Key('story-start-disc')));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );

        // Trigger a miss.
        await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
        await tester.pump();
        await s.until(
          () => _micState(tester) == NocheMicState.notYet,
          what: 'mic notYet on miss',
        );
        // Let quick state transition finish.
        await tester.pump(NocheMotion.quick);

        // Outline is NocheColors.text, zero red anywhere.
        final disc = tester.widget<Container>(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        final dec = disc.decoration! as BoxDecoration;
        expect((dec.border! as Border).top.color, NocheColors.text);
        _expectNoRedDecorations(tester);

        // Still notYet halfway through the 900 ms hold.
        await tester.pump(StoryMotion.missHold ~/ 2);
        expect(_micState(tester), NocheMicState.notYet);

        // After 900 ms total hold: line replays, arrow spins in settle, mic is theySpeak.
        await tester.pump(
          StoryMotion.missHold -
              (StoryMotion.missHold ~/ 2) +
              const Duration(milliseconds: 20),
        );
        expect(_micState(tester), NocheMicState.theySpeak);
        await tester.pump(NocheMotion.settle ~/ 2);
        final arrow = tester.widget<Transform>(
          find.byKey(const ValueKey('story_replay_arrow')),
        );
        // Mid-spin rotation matrix is not identity.
        expect(arrow.transform.storage[0], isNot(closeTo(1.0, 0.01)));

        // Once the replayed line ends, mic returns to ready.
        await s.until(
          () => _micState(tester) == NocheMicState.ready,
          what: 'mic returns to ready after post-miss replay',
        );
      },
    );

    testWidgets(
      'right speaking answer shows NocheColors.right disc, expanding ring in settle, and zero red',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: false,
        );
        await tester.tap(find.byKey(const Key('story-start-disc')));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );

        await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
        await tester.pump();
        await s.until(
          () => _micState(tester) == NocheMicState.right,
          what: 'mic right',
        );
        await tester.pump(NocheMotion.settle ~/ 2);
        expect(
          find.byKey(const ValueKey('noche_mic_right_ring')),
          findsOneWidget,
        );
        _expectNoRedDecorations(tester);
      },
    );
  });

  group(
    'Touch turn motion (miss outline, small level bars, right ring, zero red)',
    () {
      testWidgets(
        'touch miss draws 3 px NocheColors.text radius-12 outline (no red) and small level bars while replaying, then fades out in move; touch right draws NocheColors.right outline + expanding ring in settle',
        (tester) async {
          final s = await openScreen(
            tester,
            id: 'la-lluvia',
            size: const Size(390, 844),
            ratio: 3.0,
            reduceMotion: false,
          );
          await tester.tap(find.byKey(const Key('story-start-disc')));
          await s.until(
            () => s.runner.pendingNow?.asked == true && s.runner.speaking == 0,
            what: 'touch ask ready',
          );

          // Tap a wrong thing ('palma' when 'casa' is asked).
          await s.tapThing('palma');
          await tester.pump(NocheMotion.quick);

          final missFinder = find.byKey(const ValueKey('story_touch_outline'));
          expect(missFinder, findsOneWidget);
          final missDec =
              tester.widget<DecoratedBox>(missFinder).decoration
                  as BoxDecoration;
          expect((missDec.border! as Border).top.color, NocheColors.text);
          expect((missDec.border! as Border).top.width, 3);
          expect(missDec.borderRadius, BorderRadius.circular(12));
          if (s.runner.view.speakingNow) {
            expect(
              find.byKey(const ValueKey('story_touch_level_bars')),
              findsOneWidget,
            );
          }
          _expectNoRedDecorations(tester);

          // Wait for any active clip/replay to finish, then for the hold and
          // fade-out in `move` to complete.
          await s.until(
            () =>
                s.runner.pendingNow?.busy == false &&
                !s.runner.view.speakingNow,
            what: 'touch miss replay finished',
          );
          await s.advance(
            StoryMotion.touchMissHold.inMilliseconds +
                NocheMotion.move.inMilliseconds +
                100,
          );
          expect(
            find.byKey(const ValueKey('story_touch_outline')),
            findsNothing,
          );

          // Now tap the right thing ('casa').
          await s.tapThing('casa');
          await tester.pump(NocheMotion.quick);

          final rightFinder = find.byKey(const ValueKey('story_touch_outline'));
          expect(rightFinder, findsOneWidget);
          final rightDec =
              tester.widget<DecoratedBox>(rightFinder).decoration
                  as BoxDecoration;
          expect((rightDec.border! as Border).top.color, NocheColors.right);
          expect((rightDec.border! as Border).top.width, 3);
          expect(rightDec.borderRadius, BorderRadius.circular(12));
          expect(
            find.byKey(const ValueKey('story_touch_right_ring')),
            findsOneWidget,
          );
          _expectNoRedDecorations(tester);

          // Ring finishes expanding after settle.
          await tester.pump(NocheMotion.settle);
          expect(
            find.byKey(const ValueKey('story_touch_right_ring')),
            findsNothing,
          );
        },
      );
    },
  );

  group('End of story motion (NocheWindow 400->296, stage & minutes bars, plan next action)', () {
    testWidgets(
      'window closes 400 -> 296 and moves to top 0 in pageIn while PixelView scale stays constant; header fades in quick; summary shows story counter, new words stage bars, Today minutes bar, and Next story action',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: false,
        );
        final playPixelSize = tester.getSize(find.byType(PixelView));

        await tester.tap(find.byKey(const Key('story-start-disc')));
        await s.answerUntil(
          () => s.runner.view.screen == StoryScreenState.end,
          what: 'story end',
        );

        // Start of end transition (0 ms): window starts at 400 / top 64.
        final startWin = tester.getRect(find.byType(NocheWindow));
        expect(startWin.height, closeTo(StoryScreen.sceneHeight, 1.0));
        expect(startWin.top, closeTo(StoryHeader.height, 1.0));

        // Middle of pageIn (160 ms): window is strictly between 400 and 296,
        // and PixelView size (whole-number scale) has NOT changed!
        await tester.pump(NocheMotion.pageIn ~/ 2);
        final midWin = tester.getRect(find.byType(NocheWindow));
        expect(midWin.height, lessThan(StoryScreen.sceneHeight));
        expect(midWin.height, greaterThan(StoryScreen.endSceneHeight));
        expect(midWin.top, lessThan(StoryHeader.height));
        expect(midWin.top, greaterThan(0));
        expect(tester.getSize(find.byType(PixelView)), playPixelSize);

        // End of pageIn + summary settlement: window is 296 at top 0, scale still unchanged.
        await tester.pump(NocheMotion.pageIn);
        await tester.pump(const Duration(milliseconds: 1000));
        final endWin = tester.getRect(find.byType(NocheWindow));
        expect(endWin.height, closeTo(StoryScreen.endSceneHeight, 0.5));
        expect(endWin.top, closeTo(0, 0.5));
        expect(tester.getSize(find.byType(PixelView)), playPixelSize);

        // Header has faded out to opacity 0.
        final headerOp = tester.widget<AnimatedOpacity>(
          find.byKey(const ValueKey('story_header_opacity')),
        );
        expect(headerOp.opacity, 0.0);

        // Summary elements present: counter, title, new words + stage bars, Today + minutes bar.
        expect(find.textContaining('STORY '), findsOneWidget);
        expect(find.text('La lluvia'), findsOneWidget);
        expect(find.byType(NocheStageBar), findsWidgets);
        expect(find.text(StoryWording.todayHeading), findsOneWidget);
        expect(
          find.byKey(const ValueKey('story_end_minutes_bar')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('story-end-primary')), findsOneWidget);
        expect(find.byKey(const Key('story-end-replay')), findsOneWidget);
        expect(find.byKey(const Key('story-end-map')), findsOneWidget);
        expect(
          find.widgetWithText(
            NochePrimaryButton,
            StoryWording.nextStory('El bizcocho'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'end screen primary action shows "Next: review · <N> min" when words are due for review',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        // Seed a due review word that has a pair in the sample course.
        final pairWord = s.course.pairs.first.word;
        (s.services.progress as FakeProgressStore).put(
          WordRecord(
            w: pairWord,
            primera: 1000,
            oida: 2,
            ear: SkillRecord(etapa: 2, due: 1),
          ),
        );

        await tester.tap(find.byKey(const Key('story-start-disc')));
        await s.answerUntil(
          () => s.runner.view.screen == StoryScreenState.end,
          what: 'story end with due review',
        );
        await s.advance(200);

        expect(
          find.widgetWithText(NochePrimaryButton, StoryWording.nextReview(3)),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('story-end-primary')));
        expect(s.nav.last, const ReviewRoute());
      },
    );

    test('buildStoryEndSummary keeps today minutes at 0 when learner only has historical lifetime minutes', () async {
      final clock = FakeClock();
      final course = FakeCourseCatalog();
      await course.load();
      final progress = FakeProgressStore(clock: clock);
      // Log 100 minutes yesterday, then advance to the next UTC day.
      progress.addMinutes(100);
      clock.advance(const Duration(days: 1));
      final storyData = await course.story('la-lluvia');
      final summary = buildStoryEndSummary(
        storyId: 'la-lluvia',
        story: storyData,
        foot: const StoryFoot(next: true, again: true, home: false, map: true),
        listen: false,
        course: course,
        progress: progress,
        clock: clock,
        knownBefore: const {},
        beforeMinutes: 0,
      );
      expect(progress.minutes, 100);
      expect(summary.beforeMinutes, 0);
      expect(summary.afterMinutes, 0);
    });
  });

  group('Reduced motion & Arabic RTL', () {
    testWidgets(
      'disableAnimations: true eliminates travel, stagger, spin, right ring, and loops',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    StoryLessonText(
                      language: Language.spanish,
                      txtOn: true,
                      speaker: 'Abuela',
                      line: '¿Tienes hambre?',
                      promptPrefix: 'Dile: ',
                      promptWords: 'Tengo hambre.',
                      arriveDelay: StoryMotion.lessonArriveDelay,
                    ),
                    const StorySmallLevelBars(playing: true),
                    StoryHearAgainButton(
                      onPressed: () {},
                      language: Language.spanish,
                      replayCount: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // No vertical rise offset on arrival rows under reduced motion.
        for (var i = 0; i < 3; i++) {
          final dy = tester
              .widget<Transform>(find.byKey(ValueKey('noche_arrive_item_$i')))
              .transform
              .getTranslation()
              .y;
          expect(dy, 0.0);
        }

        // Small level bars stand still at middle height (0.6 * 24 = 14.4).
        await tester.pump(NocheMotion.quick);
        for (var i = 0; i < 3; i++) {
          final h = tester
              .getSize(find.byKey(ValueKey('story_touch_level_bar_$i')))
              .height;
          expect(h, closeTo(StorySmallLevelBars.barHeight * 0.6, 0.01));
        }

        // Replay arrow does not spin when replayCount increments under reduced motion.
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: StoryHearAgainButton(
                  onPressed: () {},
                  language: Language.spanish,
                  replayCount: 2,
                ),
              ),
            ),
          ),
        );
        await tester.pump(NocheMotion.settle ~/ 2);
        final arrow = tester.widget<Transform>(
          find.byKey(const ValueKey('story_replay_arrow')),
        );
        expect(arrow.transform.storage[0], closeTo(1.0, 0.001));
      },
    );

    testWidgets(
      'Arabic RTL end screen keeps number-leading English lines in NocheLtr and PixelView unmirrored',
      (tester) async {
        final ar = await openScreen(
          tester,
          id: 'la-lluvia',
          course: FakeCourseCatalog(
            fetch: arabicSampleFile,
            language: arabicTestLanguage,
          ),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byKey(const Key('story-start-disc')));
        await ar.answerUntil(
          () => ar.runner.view.screen == StoryScreenState.end,
          what: 'Arabic story end',
        );
        await ar.advance(300);

        expect(
          Directionality.of(tester.element(find.byType(PixelView))),
          TextDirection.ltr,
        );
        final minsFinder = find.textContaining('of 30 min');
        expect(minsFinder, findsOneWidget);
        expect(
          Directionality.of(tester.element(minsFinder)),
          TextDirection.ltr,
        );
        final counterFinder = find.textContaining('STORY ');
        expect(counterFinder, findsOneWidget);
        expect(
          Directionality.of(tester.element(counterFinder)),
          TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Stable keys contract & silent unrecorded-clip playback', () {
    testWidgets(
      'unconverted-scene fallback exposes story-unconverted, story-unconverted-back, and story-close-button keys',
      (tester) async {
        final s = await openScreen(
          tester,
          id: testStoryId,
          course: WithTestScene(),
          scenes: scenesWithTestScene,
        );
        expect(find.byKey(const Key('story-unconverted')), findsOneWidget);
        expect(find.byKey(const Key('story-unconverted-back')), findsOneWidget);
        expect(find.byKey(const Key('story-close-button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('story-unconverted-back')));
        await tester.pump();
        expect(s.nav.backs, 1);
      },
    );

    test('a story with an unrecorded clip plays silently via timed fallback to end screen without throwing', () async {
      final r = await Rig.make(
        story(
          beats: ['linea_1', 'linea_2'],
          clips: {'linea_1': 'Hola abuela', 'linea_2': 'Vamos ya'},
        ),
        course: TestCourse(missing: {'linea_2'}),
      );
      await r.finish((pn) => null);
      expect(r.runner.VOICE, isFalse);
      expect(r.clips, isEmpty);
      expect(r.runner.view.screen, StoryScreenState.end);
    });
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets(
      'capture N8.8 end-of-story screenshots (Spanish and Arabic fake) at 390x844 and 412x915',
      (tester) async {
        await _loadNocheFonts();
        final dir = Directory('test/screenshots')..createSync(recursive: true);

        Future<void> saveShot(GlobalKey key, String name, double dpr) async {
          // Let queued ui.decodeImageFromPixels callbacks from earlier frames
          // drain on the real worker thread so PixelView._image is populated
          // before pumping one paint frame and snapshotting.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 800)),
          );
          await tester.pump();
          final bytes = await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: dpr);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          File('${dir.path}/$name').writeAsBytesSync(bytes!);
        }

        for (final cfg in const [
          (tag: '390x844', size: Size(390, 844), dpr: 3.0),
          (tag: '412x915', size: Size(412, 915), dpr: 2.625),
        ]) {
          for (final arabic in const [false, true]) {
            tester.view.devicePixelRatio = cfg.dpr;
            tester.view.physicalSize = cfg.size * cfg.dpr;
            addTearDown(tester.view.reset);

            final clock = FakeClock();
            final nav = FakeNavigator();
            final course = FakeCourseCatalog(
              fetch: arabic ? arabicSampleFile : sampleFile,
              language: arabic ? arabicTestLanguage : Language.spanish,
            );
            await tester.runAsync(course.load);
            final progress = FakeProgressStore(clock: clock);
            progress.addMinutes(12);
            final services = fakeServices(
              course: course,
              clock: clock,
              nav: nav,
              progress: progress,
              clips: TimedClips(course),
              reduceMotion: true,
            );
            final screen = Screen(tester, clock, nav, course, services);
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundaryKey,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: coquiTheme(),
                  home: StoryScreen(
                    services: services,
                    route: const StoryRoute('el-bizcocho'),
                    scenes: registryScenes,
                    session: SpeechSession(),
                    onOpen: (r, f) {
                      screen.runner = r;
                      screen.frame = f;
                      screen.opened = true;
                    },
                  ),
                ),
              ),
            );
            for (var i = 0; i < 400 && !screen.opened; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 5)),
              );
              await tester.pump();
            }
            await tester.pump();
            await tester.pump();

            await tester.tap(find.byKey(const Key('story-start-disc')));
            await screen.answerUntil(
              () => screen.runner.view.screen == StoryScreenState.end,
              what: 'end shot (${cfg.tag}, arabic=$arabic)',
            );
            await screen.advance(1200);
            final fileName = arabic
                ? 'story_end_arabic_${cfg.tag}.png'
                : 'story_end_${cfg.tag}.png';
            await saveShot(boundaryKey, fileName, cfg.dpr);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
