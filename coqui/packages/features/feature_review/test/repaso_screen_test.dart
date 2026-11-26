// Repaso's games on screen: the module's choice (the games, or today's ¿Cuál? when the data is missing), and a whole
// session played by touches on both phone sizes, with reduced motion and a larger text size: nothing overflows,
// every target is where a finger finds it.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/feature_review.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

void main() {
  testWidgets(
    'the module: the games when the course has read datos/repaso.json, today\'s ¿Cuál? when it has not',
    (t) async {
      final withData = fakeServices(course: RepasoTestCourse());
      final without = fakeServices(course: RepasoTestCourse(none: true));
      const m = ReviewModule();
      expect(m.screenFor(const ReviewRoute(), withData), isA<RepasoScreen>());
      expect(m.screenFor(const ReviewRoute(), without), isA<ReviewScreen>());
      // the fake course with no repaso.json in its sample: today's game
      expect(
        m.screenFor(const ReviewRoute(), fakeServices()),
        isA<ReviewScreen>(),
      );
      expect(
        m.screenFor(const LevelCheckRoute(), withData).runtimeType.toString(),
        'LevelCheckScreen',
      );
      // the picture's address goes through as LibraryModule's does
      final r =
          ReviewModule(
                imageUrl: (p) => 'x/$p',
                imageProvider: (u) => dotPicture,
              ).screenFor(const ReviewRoute(), withData)!
              as RepasoScreen;
      expect(r.imageUrl('img/a.png'), 'x/img/a.png');
    },
  );

  testWidgets('the start screen: Repaso, its line, the words and minutes', (
    t,
  ) async {
    final sc = Screen(t);
    await sc.open();
    expect(find.text(CoquiLabels.review), findsOneWidget);
    expect(find.text(RepasoStrings.startHint), findsOneWidget);
    expect(find.text('10 words · about 4 min'), findsOneWidget);
  });

  for (final (name, w, h, dpr, text) in [
    ('390 x 844', 390.0, 844.0, 3.0, 1.0),
    ('412 x 915', 412.0, 915.0, 2.625, 1.0),
    ('390 x 844, text 1.3x', 390.0, 844.0, 3.0, 1.3),
    ('412 x 915, text 1.6x', 412.0, 915.0, 2.625, 1.6),
  ]) {
    testWidgets(
      'a whole session by touches, $name, reduced motion: every game, nothing overflows',
      (t) async {
        final sc = Screen(t);
        await sc.open(w: w, h: h, dpr: dpr, text: text);
        final moments = <String>[];
        await sc.play(
          each: (m) async {
            moments.add(m);
            // the instruction line and the targets are on screen, inside it
            final it = sc.s.item!;
            expect(find.text(gameInstruction(it.kind)), findsOneWidget);
            final screen = Rect.fromLTWH(0, 0, w, h);
            for (final f in [
              find.byType(NocheWordTile),
              find.byType(NochePictureChoice),
              find.byType(NocheSpeakerTile),
            ]) {
              for (var i = 0; i < f.evaluate().length; i++) {
                final r = t.getRect(f.at(i));
                expect(r.width, greaterThan(0));
                // it can be scrolled to; the first tile of a game starts on screen
                if (i == 0) {
                  expect(screen.contains(r.topLeft), isTrue, reason: m);
                }
              }
            }
          },
        );
        expect(sc.s.screen, LessonScreen.end);
        expect(find.text('Done'), findsOneWidget);
        expect(find.text('9 of 10 words right the first time'), findsOneWidget);
        for (final k in [
          'turn hear',
          'turn build',
          'turn match',
          'next hear',
        ]) {
          expect(moments, contains(k));
        }
        expect(moments, isNot(contains('turn cual')));
        expect(moments, isNot(contains('turn where')));
        // the end lists each word with its sentence; a touch plays it
        final row = sc.s.end!.groups.first.rows.first;
        await t.tap(find.bySemanticsLabel('${row.word}: ${row.text}'));
        await sc.settle();
        expect(sc.clips.plays.last['id'], row.clip);
        await t.tap(find.text('Back to Palabras'));
        expect(sc.nav.routes.last, const TabRoute('words'));
      },
    );
  }

  testWidgets('the "N in a row" chip shows from three right in a row', (
    t,
  ) async {
    final sc = Screen(t);
    await sc.open();
    var seen = false;
    await sc.play(
      each: (m) async {
        final shown = find.textContaining('in a row').evaluate().isNotEmpty;
        expect(shown, sc.s.streak >= 3, reason: m);
        if (shown) {
          expect(find.text('${sc.s.streak} in a row'), findsOneWidget);
          seen = true;
        }
      },
    );
    expect(seen, isTrue);
  });

  testWidgets('Dilo on screen: the mic, "Can\'t speak now", what was heard', (
    t,
  ) async {
    final sc = Screen(t, heard: ['algo']);
    await sc.open();
    final w = realRepaso.words.firstWhere(
      (x) => x.say.isNotEmpty && x.say.first.story == 'la-lluvia',
    );
    sc.s.queue = [
      QueueEntry.play(SayItem(word: w.word, line: w.say.first)),
      QueueEntry.play(SayItem(word: w.word, line: w.say.first)),
    ];
    await t.tap(find.byType(NochePlayDisc));
    await sc.settle();
    await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
    await sc.settle();
    expect(find.text(gameInstruction(GameKind.say)), findsOneWidget);
    expect(find.byType(NocheMic), findsOneWidget);
    expect(find.text(RepasoStrings.cantSpeak), findsOneWidget);
    await t.tap(find.byType(NocheMic));
    await sc.settle();
    await sc.vt.runUntil(() => sc.s.heard.isNotEmpty);
    await sc.settle();
    // what the app heard, as "Heard: ..." in normal-size text, and "Try again" under the mic
    expect(find.text('Heard: algo'), findsOneWidget);
    expect(find.text(RepasoStrings.tryAgain), findsOneWidget);
    await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
    await sc.settle();
    await t.tap(find.text(RepasoStrings.cantSpeak));
    await sc.settle();
    await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
    await sc.settle();
    // off for the session: the second Dilo did not ask
    expect(sc.s.sayOff, isTrue);
    expect(sc.store.calls.where((c) => c['op'] == 'responde'), isEmpty);
  });
}
