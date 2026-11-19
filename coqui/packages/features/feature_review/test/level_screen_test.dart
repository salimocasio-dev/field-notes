// The level check screen on the fakes: one test for each thing historia/tools/nivel_check.py looks at (the items
// asked, the result, the card on the end screen, the records), the old script's name for it in the test's name;
// and the module's two routes.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/feature_review.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/lab.dart';

void main() {
  Future<Lab> open(
    WidgetTester t, {
    LevelOptions o = const LevelOptions(),
  }) async {
    setPhone(t, 412, 915, 2.625);
    final lab = Lab(t, db: dbJson([]));
    await lab.openLevel(options: o);
    return lab;
  }

  Future<Lab> played(
    WidgetTester t,
    bool Function(int story, int k) right, {
    LevelOptions o = const LevelOptions(),
  }) async {
    final lab = await open(t, o: o);
    await lab.start();
    await lab.driveLevel(right);
    expect(lab.lv.screen, LessonScreen.end);
    return lab;
  }

  group('nivel_check', () {
    testWidgets(
      'nivel_check: the start screen says Level check and how long: 16 pictures · about 3 min, 16 segments',
      (t) async {
        await open(t);
        expect(find.text('Level check'), findsOneWidget);
        expect(find.text('16 pictures · about 3 min'), findsOneWidget);
        expect(
          t
              .widget<LessonProgressDashes>(find.byType(LessonProgressDashes))
              .segments,
          16,
        );
        expect(find.byType(LessonStartButton), findsOneWidget);
      },
    );

    testWidgets(
      'nivel_check: all right: the items asked go up the list by 4 (PASO) from the first',
      (t) async {
        final lab = await played(t, (s, k) => true);
        final idx = [for (final a in lab.lv.answers) a.i];
        expect(lab.lv.upStep, 4);
        expect(idx.take(11).toList(), [
          0,
          4,
          8,
          12,
          16,
          20,
          24,
          28,
          32,
          36,
          40,
        ]);
        expect(lab.lv.answers.every((a) => a.ok), isTrue);
      },
    );

    testWidgets(
      'nivel_check: all right: it stops when the last two items are right (before 16 items), the result is the first 32 stories',
      (t) async {
        final lab = await played(t, (s, k) => true);
        expect(lab.lv.answers.length, lessThan(16));
        expect(lab.lv.result!.frontier, 32);
      },
    );

    testWidgets(
      'nivel_check: four pictures to an item, one of them the one that fits; a touch shows a white ring on the touched one only (no right or wrong)',
      (t) async {
        final lab = await open(t);
        await lab.start();
        await lab.until(() => lab.lv.ready);
        expect(lab.choices.length, 4);
        expect(lab.lv.panels!.where((p) => p.right).length, 1);
        await lab.touchPicture(2);
        await lab.advance(100);
        expect(
          [for (final c in lab.choices) c.ring],
          [
            ChoiceRing.none,
            ChoiceRing.none,
            ChoiceRing.selected,
            ChoiceRing.none,
          ],
        );
        expect(
          lab.choices.any((c) => c.check || c.dim != ChoiceDim.none),
          isFalse,
        );
      },
    );

    testWidgets(
      'the four cells ask for pictures of 96 x 106, animated, the refs coqui_ui makes for the item (PictureRef.ofLevel)',
      (t) async {
        final lab = await open(t);
        await lab.start();
        await lab.until(() => lab.lv.ready);
        final panels = lab.lv.panels!;
        expect(panels.length, 4);
        final asked = [
          for (final a in lab.pictures.asked)
            if (panels.any((p) => identical(p.ref, a.ref))) a,
        ];
        expect(asked.length, 4, reason: 'one picture for each cell');
        for (final a in asked) {
          expect((a.width, a.height, a.animated), (96, 106, true));
        }
        final byWord = {for (final p in course.pairs) p.word: p};
        for (final p in panels) {
          // `nivel.<word>.<index>`: the item and the picture of it the cell shows
          final parts = p.ref.name!.split('.');
          expect(parts.first, 'nivel');
          final item = course.levelItems.firstWhere((q) => q.word == parts[1]);
          expect(
            p.ref,
            PictureRef.ofLevel(item, int.parse(parts[2]), pairs: byWord),
          );
        }
        // the four are the four pictures of one item, each once
        expect({for (final p in panels) p.ref.name!.split('.')[1]}.length, 1);
        expect(
          [for (final p in panels) int.parse(p.ref.name!.split('.')[2])]
            ..sort(),
          [0, 1, 2, 3],
        );
        // the pictures of the item that can come next were made ready the same way
        expect(lab.pictures.warmed, isNotEmpty);
        expect(
          lab.pictures.warmed.every((r) => r.name!.startsWith('nivel.')),
          isTrue,
        );
      },
    );

    testWidgets('nivel_check: touches before the sentence ends do not count', (
      t,
    ) async {
      final lab = await open(t);
      await lab.start();
      await lab.until(() => lab.lv.panels != null);
      await lab.touchPicture(0);
      await lab.touchPicture(3);
      expect(lab.lv.answers, isEmpty);
      expect(lab.choices.every((c) => c.ring == ChoiceRing.none), isTrue);
    });

    testWidgets(
      'nivel_check: right on the items of stories up to 11: the card says You already understand the first 11 stories., button To the map',
      (t) async {
        await played(t, (s, k) => s <= 11);
        expect(find.text('Level check done'), findsOneWidget);
        expect(
          find.text('You already understand the first 11 stories.'),
          findsOneWidget,
        );
        expect(find.text('To the map'), findsOneWidget);
      },
    );

    testWidgets('nivel_check: right on story 1 only: one story, singular', (
      t,
    ) async {
      await played(t, (s, k) => s <= 1);
      expect(
        find.text('You already understand the first 1 story.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'nivel_check: wrong every time: it stops after three misses and says You start at the beginning.',
      (t) async {
        final lab = await played(t, (s, k) => false);
        expect(lab.lv.answers.length, 3);
        expect(find.text('You start at the beginning.'), findsOneWidget);
        expect(lab.lv.result!.frontier, 0);
      },
    );

    testWidgets(
      "nivel_check: the button is the app's blue main action, and leads to the map",
      (t) async {
        final lab = await played(t, (s, k) => s <= 11);
        expect(
          t.widget<LessonButton>(find.byType(LessonButton)).kind,
          LessonButtonKind.blue,
        );
        await t.tap(find.text('To the map'));
        await t.pump();
        expect(lab.nav.last, const TabRoute('map'));
      },
    );

    testWidgets(
      "nivel_check: records: the words of the first 11 stories are presumed (ear stage 3), those stories count as played",
      (t) async {
        final lab = await played(t, (s, k) => s <= 11);
        final r = lab.lv.result!;
        expect(r.stories.length, 11);
        expect(r.words, isNotEmpty);
        for (final w in r.words) {
          expect(lab.store.word(w)!.ear.etapa, 3);
          expect(lab.store.word(w)!.ear.presunta, 1);
        }
        for (final id in r.stories) {
          expect(lab.store.played(id), isTrue);
        }
        expect(lab.store.levelResult!['historias'], 11);
        final presume = lab.store.calls
            .where((c) => c['op'] == 'presume')
            .toList();
        expect(presume.length, 1);
      },
    );

    testWidgets(
      'nivel_check: wrong every time: no word is presumed, no story counted (PAL.presume with nothing)',
      (t) async {
        final lab = await played(t, (s, k) => false);
        expect(lab.store.words, isEmpty);
        expect(lab.store.levelResult!['historias'], 0);
      },
    );

    testWidgets(
      'nivel_check: todo=1: every item of the list is asked, in order (48), 48 segments',
      (t) async {
        final lab = await played(
          t,
          (s, k) => true,
          o: const LevelOptions(all: true),
        );
        expect(lab.lv.answers.length, 48);
        expect([
          for (final a in lab.lv.answers) a.i,
        ], List<int>.generate(48, (i) => i));
        expect(
          t
              .widget<LessonProgressDashes>(find.byType(LessonProgressDashes))
              .segments,
          48,
        );
      },
    );

    testWidgets(
      'nivel_check: the close X goes back to where it was opened from',
      (t) async {
        final lab = await open(t);
        await t.tap(find.byType(LessonCloseButton));
        await t.pump();
        expect(lab.nav.backs, 1);
      },
    );

    testWidgets('nivel_check: no page errors', (t) async {
      await played(t, (s, k) => s <= 6);
      expect(t.takeException(), isNull);
    });
  });

  group('the module', () {
    const module = ReviewModule();

    testWidgets(
      'answers ReviewRoute and LevelCheckRoute, has no tab, and is nobody else\'s',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final l = Lab(t, db: dbJson([]));
        expect(module.id, 'review');
        expect(module.tab(l.services), isNull);
        expect(
          module.screenFor(const ReviewRoute(), l.services),
          isA<ReviewScreen>(),
        );
        expect(
          module.screenFor(const ReviewRoute(practice: true), l.services),
          isA<ReviewScreen>(),
        );
        expect(
          module.screenFor(const LevelCheckRoute(), l.services),
          isA<LevelCheckScreen>(),
        );
        expect(module.screenFor(const TabRoute('words'), l.services), isNull);
        expect(module.screenFor(const StoryRoute('x'), l.services), isNull);
      },
    );

    testWidgets(
      'Repaso: the X goes to Palabras (cual.js: SALIDA) and stops the sound; the disc wakes the audio',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final d = dueRecs(3, kNow);
        final l = Lab(t, db: dbJson(d.recs));
        await l.openReview();
        await l.start();
        await l.until(() => l.s.speaking > 0);
        await t.tap(find.byType(LessonCloseButton));
        await t.pump();
        expect(l.nav.last, const TabRoute('words'));
        expect(l.clips.stops, isNotEmpty);
      },
    );

    testWidgets('the sound button mutes and unmutes the clip player', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final l = Lab(t, db: dbJson([]));
      await l.openReview();
      expect(l.clips.muted, isFalse);
      await t.tap(find.byType(LessonSoundButton));
      await t.pump();
      expect(l.clips.muted, isTrue);
      await t.tap(find.byType(LessonSoundButton));
      await t.pump();
      expect(l.clips.muted, isFalse);
    });

    testWidgets(
      'the next ask\'s pictures are made ready while a sentence plays (PictureSource.warm)',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final d = dueRecs(3, kNow);
        final l = Lab(t, db: dbJson(d.recs));
        await l.openReview();
        await l.start();
        await l.until(() => l.s.speaking > 0);
        expect(l.pictures.warmed.length, 2);
      },
    );
  });
}
