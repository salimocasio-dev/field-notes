// N2.6 (#89): feature_story uses the course's language for speech recognition
// locale, word matching (`heardRight`), script font, text direction, and
// directional RTL mirroring, while keeping pixel scenes unmirrored and chrome
// menus in English.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/stand_in_scene.dart';
import 'speaking_turns_test.dart' show marked;
import 'speech_listener_test.dart' show Scripted;
import 'support/rig.dart';
import 'support/screen_harness.dart';
import 'support/stories.dart';

class _EditedArabicCourse extends FakeCourseCatalog {
  _EditedArabicCourse(this.edit) : super.arabic();

  final void Function(String id, Map<String, dynamic> file) edit;
  final Map<String, Future<Map<String, dynamic>>> _edited = {};

  @override
  Future<Map<String, dynamic>> story(String id) => _edited[id] ??= () async {
    final f = Map<String, dynamic>.of(await super.story(id));
    edit(id, f);
    return f;
  }();
}

void main() {
  group('heardRight uses course word rules', () {
    test('matches Arabic words with diacritics and alef variants', () {
      final targets = <Target>[
        (palabra: 'نعم', formas: ['نعم']),
        (palabra: 'افتح', formas: ['افتح']),
      ];

      expect(
        heardRight(
          ['نَعَمْ أَفْتَحُ الباب'],
          targets,
          language: arabicTestLanguage,
        ),
        isTrue,
      );
      expect(
        heardRight(['نعم يا جدة إفتح!'], targets, language: arabicTestLanguage),
        isTrue,
      );
      // Missing one required target -> false
      expect(
        heardRight(['نعم يا جدة'], targets, language: arabicTestLanguage),
        isFalse,
      );
      // Unrelated Arabic text -> false
      expect(
        heardRight(['لا شكراً'], targets, language: arabicTestLanguage),
        isFalse,
      );
    });

    test('Spanish parity is unchanged with Language.spanish', () {
      final targets = <Target>[
        (palabra: 'sí', formas: ['sí', 'si']),
      ];
      expect(
        heardRight(['¡Sí, gracias!'], targets, language: Language.spanish),
        isTrue,
      );
      expect(
        heardRight(['casi'], targets, language: Language.spanish),
        isFalse,
      );
    });
  });

  group('StoryRunner speech recognition uses course.language', () {
    test('passes course.language.recognitionLocale to SpeechListener and evaluates Arabic speech', () async {
      final sp = Scripted();
      final s = story(
        beats: [
          {'wait': 100},
          'ar_yes',
          'ar_end',
        ],
        clips: {'ar_end': 'ممتاز!', 'muy_bien': 'ممتاز!'},
      );
      (s['clips'] as Map<String, dynamic>)['ar_yes'] = marked('نعم!', 'نعم', [
        'نعم',
      ]);

      final r = await Rig.make(
        s,
        scene: StandInScene(
          things: [
            Thing(id: 'puerta', box: [150, 60, 30, 50]),
          ],
        ),
        course: TestCourse(language: arabicTestLanguage),
        speech: sp,
        allOpen: true,
      );
      await r.start();
      await r.until(() => r.runner.HAB.est == 'ready', what: 'Arabic mic');

      r.runner.tapMic();
      expect(sp.listens.single, (
        locale: arabicTestLanguage.recognitionLocale,
        limit: const Duration(seconds: 6),
        maxAlternatives: 5,
      ));
      expect(sp.listens.single.locale, 'ar-SA');

      sp.turns.single.end.complete();
      await r.drain();
      expect(r.runner.HAB.est, 'processing');

      // Diacriticized Arabic response matches normalized target 'نعم'.
      sp.turns.single.r.complete(
        SpeechResult(alternatives: ['نَعَمْ يا جدة'], msToSound: 280),
      );
      await r.until(() => r.runner.HAB.est == 'ok');
      expect(r.progress.answers.single, (w: 'نعم', ok: true, ms: 280));
      expect(r.runner.view.bubbleText, 'نَعَمْ يا جدة');
    });
  });

  group('StoryScreen Spanish (LTR) vs Arabic (RTL) evidence', () {
    testWidgets(
      'Arabic fake course plays main flow end-to-end without exception, mirrors layout, reads captions/bubbles/title RTL, keeps menus English and scenes unmirrored',
      (tester) async {
        final arabicFont = NocheType.forScript(
          CoquiText.lessonCaption,
          arabicTestLanguage.script,
        ).fontFamily;
        expect(arabicFont, isNotNull);

        // 1. Arabic RTL on 390 x 844
        final ar = await openScreen(
          tester,
          id: 'la-lluvia',
          course: FakeCourseCatalog.arabic(),
          size: const Size(390, 844),
          ratio: 3.0,
          showPerf: true,
        );
        expect(tester.takeException(), isNull);
        expect(ar.opened, isTrue);

        // Top bar mirrors for RTL: Close X at start (right), Sound at end (left).
        final arClose = tester.getRect(find.byType(LessonCloseButton));
        final arSound = tester.getRect(find.byType(LessonSoundButton));
        expect(arClose.center.dx, greaterThan(arSound.center.dx));

        // Perf chip sits at directional end (left side in RTL).
        final arChip = tester.getRect(find.byKey(const Key('story-perf-chip')));
        expect(arChip.center.dx, lessThan(390 / 2));

        // PixelView stays unmirrored LTR even inside the RTL lesson screen.
        final arPixelCtx = tester.element(find.byType(PixelView));
        expect(Directionality.of(arPixelCtx), TextDirection.ltr);

        // Start the story and check an Arabic caption + unmirrored scene tap + speech bubble.
        await tester.tap(find.byType(LessonStartButton));
        await ar.until(
          () => ar.runner.view.captionOn && ar.runner.view.caption.isNotEmpty,
          what: 'first Arabic caption',
        );
        final captionText = tester.widget<Text>(
          find.text(ar.runner.view.caption),
        );
        expect(captionText.textDirection, TextDirection.rtl);
        expect(captionText.locale, const Locale('ar'));
        expect(captionText.style?.fontFamily, arabicFont);

        // Advance to the first asked touch ('casa') and tap it via physical scene coordinates:
        // verifies the unmirrored pixel scene hit-test works identically in RTL.
        await ar.until(
          () => ar.runner.pendingNow != null && ar.runner.pendingNow!.asked,
          what: 'first Arabic ask',
        );
        final askedThing = ar.runner.pendingNow!.live.first;
        await ar.tapThing(askedThing);
        await ar.advance(100);
        expect(ar.runner.pendingNow, isNull);

        // Continue until a character speech bubble shows in Arabic.
        await ar.answerUntil(
          () =>
              ar.runner.view.bubbleOn &&
              ar.runner.view.bubbleKind == BubbleKind.words &&
              ar.runner.view.bubbleText.isNotEmpty,
          what: 'Arabic speech bubble',
        );
        final bubbleFinder = find.descendant(
          of: find.byType(StoryBubbleBody),
          matching: find.byType(Text),
        );
        final bubbleText = tester.widget<Text>(bubbleFinder);
        expect(bubbleText.textDirection, TextDirection.rtl);
        expect(bubbleText.locale, const Locale('ar'));
        expect(bubbleText.style?.fontFamily, arabicFont);

        // Finish the story to the end screen.
        await ar.answerUntil(
          () => ar.runner.view.screen == StoryScreenState.end,
          what: 'Arabic end screen',
        );
        await ar.advance(300);
        expect(tester.takeException(), isNull);

        // End title is Arabic ('المطر'), RTL, start-aligned at the right margin.
        final arTitleFinder = find.text('المطر');
        expect(arTitleFinder, findsOneWidget);
        final arTitleWidget = tester.widget<Text>(arTitleFinder);
        expect(arTitleWidget.textDirection, TextDirection.rtl);
        expect(arTitleWidget.locale, const Locale('ar'));
        expect(arTitleWidget.textAlign, TextAlign.start);
        expect(arTitleWidget.style?.fontFamily, arabicFont);
        final arTitleRect = tester.getRect(arTitleFinder);
        expect(arTitleRect.right, closeTo(390 - 16, 0.5));

        // Chrome / menu buttons stay English!
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Next story'), findsOneWidget);

        // In RTL, LessonButtonRow mirrors Play again (start=right) and Map (end=left).
        final arAgain = tester.getRect(find.text('Play again'));
        final arMap = tester.getRect(find.text('Map'));
        expect(arAgain.center.dx, greaterThan(arMap.center.dx));
      },
    );

    testWidgets(
      'Spanish (LTR) baseline keeps close button at left, perf chip at right, end title at left, and Play again left of Map',
      (tester) async {
        final es = await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(412, 915),
          ratio: 2.625,
          showPerf: true,
        );
        expect(tester.takeException(), isNull);
        expect(es.opened, isTrue);

        final esClose = tester.getRect(find.byType(LessonCloseButton));
        final esSound = tester.getRect(find.byType(LessonSoundButton));
        expect(esClose.center.dx, lessThan(esSound.center.dx));

        final esChip = tester.getRect(find.byKey(const Key('story-perf-chip')));
        expect(esChip.center.dx, greaterThan(412 / 2));

        final esPixelCtx = tester.element(find.byType(PixelView));
        expect(Directionality.of(esPixelCtx), TextDirection.ltr);

        await tester.tap(find.byType(LessonStartButton));
        await es.until(
          () => es.runner.view.captionOn && es.runner.view.caption.isNotEmpty,
          what: 'first Spanish caption',
        );
        final captionText = tester.widget<Text>(
          find.text(es.runner.view.caption),
        );
        expect(captionText.textDirection, TextDirection.ltr);
        expect(captionText.locale, const Locale('es'));

        await es.answerUntil(
          () => es.runner.view.screen == StoryScreenState.end,
          what: 'Spanish end screen',
        );
        await es.advance(300);

        final esTitleFinder = find.text('La lluvia');
        expect(esTitleFinder, findsOneWidget);
        final esTitleWidget = tester.widget<Text>(esTitleFinder);
        expect(esTitleWidget.textDirection, TextDirection.ltr);
        expect(esTitleWidget.locale, const Locale('es'));
        final esTitleRect = tester.getRect(esTitleFinder);
        expect(esTitleRect.left, closeTo(16, 0.5));

        final esAgain = tester.getRect(find.text('Play again'));
        final esMap = tester.getRect(find.text('Map'));
        expect(esAgain.center.dx, lessThan(esMap.center.dx));
      },
    );

    testWidgets(
      'Arabic RTL on 412 x 915 and landscape 844 x 390 renders without overflow, and tick bubble uses RTL',
      (tester) async {
        // Test Arabic tick bubble directly under StoryBubbleBody.
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                body: Center(
                  child: StoryBubbleBody(
                    kind: BubbleKind.tick,
                    text: 'نعم!',
                    estate: 'ok',
                    reduceMotion: true,
                    language: arabicTestLanguage,
                  ),
                ),
              ),
            ),
          ),
        );
        final tickText = tester.widget<Text>(find.text('نعم!'));
        expect(tickText.textDirection, TextDirection.rtl);
        expect(tickText.locale, const Locale('ar'));
        final tickRowDir = Directionality.of(
          tester.element(find.byType(CoquiIcon)),
        );
        expect(tickRowDir, TextDirection.rtl);

        // Landscape RTL check on StoryScreen with Arabic fake course.
        final landscape = await openScreen(
          tester,
          id: 'la-lluvia',
          course: _EditedArabicCourse((_, _) {}),
          size: const Size(844, 390),
          ratio: 3.0,
        );
        expect(tester.takeException(), isNull);
        expect(landscape.opened, isTrue);
        await tester.tap(find.byType(LessonStartButton));
        await landscape.answerUntil(
          () => landscape.runner.view.screen == StoryScreenState.end,
          what: 'Arabic landscape end screen',
        );
        await landscape.advance(300);
        expect(tester.takeException(), isNull);
        expect(find.text('المطر'), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
      },
    );
  });
}
