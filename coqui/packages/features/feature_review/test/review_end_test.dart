// The Repaso screen on the fakes, second half of historia/tools/repaso_check.py (end, clock, switches) and the
// plays of historia/tools/cual_check.py. One test for each check; the old script's name for it is in the test's name.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show SizedBox, Text, TextStyle, Visibility;

import 'support/lab.dart';

void main() {
  final words = pairWords();
  final d9 = dueRecs(9, kNow);
  final ws = d9.words;

  /// The session of repaso_check.py's t_end, played on a phone: by ask 0 wrong, 4 wrong (two scored misses).
  Future<Lab> endOn(
    WidgetTester t, {
    double w = 412,
    double h = 915,
    double dpr = 2.625,
    String plan = 'wrrrw',
  }) async {
    setPhone(t, w, h, dpr);
    final lab = Lab(t, db: dbJson(d9.recs));
    await lab.openReview();
    await lab.start();
    await lab.drive(plan);
    expect(lab.s.screen, LessonScreen.end);
    return lab;
  }

  List<String> upOf(Lab lab) => [
    for (final a in lab.s.answers)
      if (a.ok) a.word,
  ];
  List<String> soonOf(Lab lab) => [
    for (final a in lab.s.answers)
      if (!a.ok) a.word,
  ];

  double top(WidgetTester t, String text) => t.getTopLeft(find.text(text)).dy;
  double left(WidgetTester t, String text) => t.getTopLeft(find.text(text)).dx;
  TextStyle styleOf(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text)).style!;

  // ------------------------------------------------------------------ 5. end
  group('repaso_check t_end', () {
    testWidgets('end: two groups, Moving up then Coming back soon', (t) async {
      await endOn(t);
      expect(find.text('Moving up'), findsOneWidget);
      expect(find.text('Coming back soon'), findsOneWidget);
      expect(top(t, 'Moving up'), lessThan(top(t, 'Coming back soon')));
    });

    testWidgets(
      'end: Moving up holds the words right on the scored ask, in session order',
      (t) async {
        final lab = await endOn(t);
        expect(lab.s.end!.groups[0].words, upOf(lab));
        final shown = [for (final w in upOf(lab)) t.getTopLeft(find.text(w))];
        final sorted = [...shown]
          ..sort(
            (a, b) =>
                a.dy != b.dy ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx),
          );
        expect(shown, sorted);
      },
    );

    testWidgets('end: Coming back soon holds the missed ones (2)', (t) async {
      final lab = await endOn(t);
      expect(lab.s.end!.groups[1].words, soonOf(lab));
      expect(soonOf(lab).length, 2);
      for (final w in soonOf(lab)) {
        expect(top(t, w), greaterThan(top(t, 'Coming back soon')));
      }
    });

    testWidgets(
      'end: every word of the session is there once (9) and the end state is {up, soon, practica}',
      (t) async {
        final lab = await endOn(t);
        for (final w in ws) {
          expect(find.text(w), findsOneWidget);
        }
        expect(lab.s.end!.up, upOf(lab));
        expect(lab.s.end!.soon, soonOf(lab));
        expect(lab.s.end!.practice, isFalse);
      },
    );

    testWidgets(
      'end: a missed word that is right on its second ask is still under Coming back soon',
      (t) async {
        final lab = await endOn(t);
        expect(lab.s.secondAnswers.any((a) => a.ok), isTrue);
        for (final a in lab.s.secondAnswers) {
          if (a.ok) expect(lab.s.end!.soon, contains(a.word));
        }
      },
    );

    testWidgets(
      'end: each word has its picture (a 196 x 104 picture, its right side)',
      (t) async {
        final lab = await endOn(t);
        final grid = endGridFor(clientWidth: 412, padding: 32, dpr: 2.625);
        final boxes = find.byWidgetPredicate(
          (w) =>
              w is SizedBox &&
              w.width == grid.cellWidth &&
              w.height == grid.pictureHeightCss,
        );
        expect(boxes, findsNWidgets(9));
        for (final p in lab.s.end!.groups.expand((g) => g.pairs)) {
          expect(
            lab.pictures.shown.any(
              (r) =>
                  r.scene == (p.yes.scene ?? p.scene) &&
                  r.cam.join(',') == p.yes.cam.join(',') &&
                  identical(r.set, p.yes.set),
            ),
            isTrue,
          );
        }
      },
    );

    testWidgets(
      'end: pictures are scaled by a whole number of screen pixels (kd=1 at 2.625)',
      (t) async {
        await endOn(t);
        final grid = endGridFor(clientWidth: 412, padding: 32, dpr: 2.625);
        final cell = t.getSize(
          find
              .byWidgetPredicate(
                (w) =>
                    w is SizedBox &&
                    w.width == grid.cellWidth &&
                    w.height == grid.pictureHeightCss,
              )
              .first,
        );
        final kd = cell.width * 2.625 / 196;
        expect((kd - kd.round()).abs(), lessThan(.005));
        expect(kd.round(), greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'end: one summary line under the title: 7 moving up · 2 coming back soon',
      (t) async {
        final lab = await endOn(t);
        final line =
            '${upOf(lab).length} moving up · ${soonOf(lab).length} coming back soon';
        expect(lab.s.end!.summary, line);
        expect(find.text(line), findsOneWidget);
      },
    );

    testWidgets(
      'end: the only digits on the screen are in that line (no score)',
      (t) async {
        final lab = await endOn(t);
        final line = lab.s.end!.summary;
        final texts = t
            .widgetList<Text>(
              find.descendant(
                of: find.byType(ReviewEndScreen),
                matching: find.byType(Text),
              ),
            )
            // (the grey boxes of the fake picture source label themselves with their camera: not part of the screen)
            .where((x) => x.style?.fontSize != 10)
            .map((x) => x.data!)
            .where((x) => x != line);
        expect(texts.where((x) => RegExp(r'\d').hasMatch(x)), isEmpty);
      },
    );

    testWidgets("end: a grey line under each group heading", (t) async {
      await endOn(t);
      expect(find.text("You'll see these less often"), findsOneWidget);
      expect(find.text("You'll see these again soon"), findsOneWidget);
    });

    testWidgets('end: ...14 px, contrast 4.5 or more', (t) async {
      await endOn(t);
      for (final s in [
        "You'll see these less often",
        "You'll see these again soon",
      ]) {
        final st = styleOf(t, s);
        expect(st.fontSize, 14);
        expect(
          contrast(st.color!, NocheColors.lessonGround),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('end: no X and no sound button on the end screen', (t) async {
      await endOn(t);
      bool shown(Type type) => t
          .widget<Visibility>(
            find
                .ancestor(
                  of: find.byType(type),
                  matching: find.byType(Visibility),
                )
                .first,
          )
          .visible;
      expect(shown(NocheLessonCloseButton), isFalse);
      expect(shown(NocheLessonSoundButton), isFalse);
    });

    testWidgets(
      'end: the grid is centred, and the title and headings line up with its left edge',
      (t) async {
        final lab = await endOn(t);
        final grid = endGridFor(clientWidth: 412, padding: 32, dpr: 2.625);
        final first = left(t, lab.s.end!.groups[0].words.first);
        expect(first + grid.width / 2, closeTo(412 / 2, 1));
        expect(left(t, 'Done'), closeTo(first, 1));
        expect(left(t, 'Moving up'), closeTo(first, 1));
      },
    );

    testWidgets(
      'end: a cell is as wide as its picture and a word stays inside it (a long word wraps)',
      (t) async {
        await endOn(t);
        final grid = endGridFor(clientWidth: 412, padding: 32, dpr: 2.625);
        for (final w in ws) {
          expect(
            t.getSize(find.text(w)).width,
            lessThanOrEqualTo(grid.cellWidth + .5),
          );
        }
      },
    );

    testWidgets('end: the list fades out at both ends', (t) async {
      await endOn(t);
      final f = t.widget<FadingEdges>(find.byType(FadingEdges));
      expect([f.top, f.bottom], [16, 16]);
    });

    testWidgets(
      'end: the title is Done, the button says Back to Palabras and is 48 px or more high',
      (t) async {
        await endOn(t);
        expect(find.text('Done'), findsOneWidget);
        expect(find.text('Back to Palabras'), findsOneWidget);
        expect(
          t.getSize(find.byType(NochePrimaryButton)).height,
          greaterThanOrEqualTo(48),
        );
      },
    );

    testWidgets(
      'end: the button is NochePrimaryButton (next amber fill, onAccent ink)',
      (t) async {
        await endOn(t);
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(styleOf(t, 'Back to Palabras').color, NocheColors.onAccent);
      },
    );

    testWidgets(
      'end: sizes: title 24, group headings 18, words 16, button 18',
      (t) async {
        await endOn(t);
        expect(styleOf(t, 'Done').fontSize, 24);
        expect(styleOf(t, 'Moving up').fontSize, 18);
        expect(styleOf(t, ws.first).fontSize, 16);
        expect(styleOf(t, 'Back to Palabras').fontSize, 18);
      },
    );

    testWidgets(
      'end: contrast of the title, headings, words and button text is at least 4.5',
      (t) async {
        await endOn(t);
        for (final s in ['Done', 'Moving up', ws.first]) {
          expect(
            contrast(styleOf(t, s).color!, NocheColors.lessonGround),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          contrast(styleOf(t, 'Back to Palabras').color!, NocheColors.next),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    testWidgets('end: nothing runs sideways; the list ends above the button', (
      t,
    ) async {
      await endOn(t);
      expect(t.takeException(), isNull);
      final list = t.getBottomRight(find.byType(FadingEdges)).dy;
      expect(
        list,
        lessThanOrEqualTo(t.getTopLeft(find.byType(NochePrimaryButton)).dy + 1),
      );
    });

    testWidgets(
      'end: the progress bar has 9 segments (one per word, none for the second asks), all lit',
      (t) async {
        await endOn(t);
        final bar = t.widget<NocheDashes>(find.byType(NocheDashes));
        final done = bar.states.where((s) => s == NocheDashState.done).length;
        expect([bar.states.length, done], [9, 9]);
      },
    );

    testWidgets('end: Back to Palabras goes to Palabras', (t) async {
      final lab = await endOn(t);
      await t.tap(find.text('Back to Palabras'));
      await t.pump();
      expect(lab.nav.last, const TabRoute('words'));
    });

    testWidgets('end: no page errors', (t) async {
      await endOn(t);
      expect(t.takeException(), isNull);
    });

    testWidgets('end: all right: only Moving up, summary 9 moving up', (
      t,
    ) async {
      final lab = await endOn(t, plan: '');
      expect([for (final g in lab.s.end!.groups) g.title], ['Moving up']);
      expect(lab.s.end!.groups[0].words.length, 9);
      expect(lab.s.end!.summary, '9 moving up');
    });

    Future<Lab> practice(WidgetTester t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(
        t,
        db: dbJson([for (final w in ws) rec(w, kNow + 3 * kDay)]),
      );
      await lab.openReview(options: const ReviewOptions(cap: 6));
      await lab.start();
      await lab.drive('wrrrw');
      return lab;
    }

    testWidgets(
      'end: a practice session says Right and Missed, not Moving up and Coming back soon',
      (t) async {
        final lab = await practice(t);
        expect(
          [for (final g in lab.s.end!.groups) g.title],
          ['Right', 'Missed'],
        );
        expect(lab.s.end!.practice, isTrue);
        expect(lab.s.end!.soon.length, 2);
        expect(find.text('Right'), findsOneWidget);
        expect(find.text('Missed'), findsOneWidget);
      },
    );

    testWidgets(
      'end: a practice session: summary 4 right · 2 missed, and no grey line under the headings',
      (t) async {
        final lab = await practice(t);
        expect(lab.s.end!.summary, '${lab.s.end!.up.length} right · 2 missed');
        expect(find.text("You'll see these less often"), findsNothing);
        expect(find.text("You'll see these again soon"), findsNothing);
      },
    );

    testWidgets(
      'end: ...and the practice answers moved nothing (every answer is an intro: no schedule change)',
      (t) async {
        final lab = await practice(t);
        final calls = lab.answerCalls();
        expect(calls.length, 6);
        expect(calls.every((c) => (c['args'] as List)[4] == true), isTrue);
      },
    );

    testWidgets('end: no page errors (practice)', (t) async {
      await practice(t);
      expect(t.takeException(), isNull);
    });

    for (final (name, w, h, dpr) in [
      ('small phone 360x640 @3x', 360.0, 640.0, 3.0),
      ('landscape 844x390 @2x', 844.0, 390.0, 2.0),
      ('393x852 @3x', 393.0, 852.0, 3.0),
    ]) {
      testWidgets(
        'end: $name: whole-number scale, columns, no sideways run, button in view',
        (t) async {
          final lab = await endOn(t, w: w, h: h, dpr: dpr, plan: 'wrwrrwrr');
          final grid = endGridFor(clientWidth: w, padding: 32, dpr: dpr);
          final landscape = w > h && h <= 600;
          final cellW = landscape ? null : grid.cellWidth;
          final boxes = find.byWidgetPredicate(
            (x) =>
                x is SizedBox &&
                x.height != null &&
                (landscape ||
                    (x.width == cellW && x.height == grid.pictureHeightCss)) &&
                x.width != null &&
                x.width! > 60 &&
                x.width! < 200 &&
                (x.height! / x.width!) > .5 &&
                (x.height! / x.width!) < .6,
          );
          expect(boxes, findsWidgets);
          final kd = t.getSize(boxes.first).width * dpr / 196;
          expect(
            (kd - kd.round()).abs(),
            lessThan(.005),
            reason: 'whole-number scale',
          );
          expect(t.takeException(), isNull);
          final btn = t.getRect(find.byType(NochePrimaryButton));
          expect(btn.height, greaterThanOrEqualTo(48));
          expect(btn.bottom, lessThanOrEqualTo(h + 1));
          expect(lab.s.screen, LessonScreen.end);
          if (!landscape) expect(grid.columns, w == 360 ? 2 : 2);
        },
      );
    }
  });

  // ------------------------------------------------------------------ 6. clock
  group('repaso_check t_clock', () {
    final realNow = DateTime.utc(2026, 11, 19, 16).millisecondsSinceEpoch;

    testWidgets(
      "clock: the store's clock is ahead of Date.now(): the due words are asked as due, most overdue first",
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final now = realNow + 60 * kDay;
        final d = dueRecs(4, now);
        final lab = Lab(t, db: dbJson(d.recs), storeNow: now);
        await lab.openReview();
        await lab.start();
        expect(await lab.drive('rrrr'), d.words);
      },
    );

    testWidgets(
      "clock: ...and their right answers are scored by that clock (not intro)",
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final now = realNow + 60 * kDay;
        final d = dueRecs(4, now);
        final lab = Lab(t, db: dbJson(d.recs), storeNow: now);
        await lab.openReview();
        await lab.start();
        await lab.drive('rrrr');
        final calls = lab.answerCalls();
        expect(calls.length, 4);
        expect(
          calls.every(
            (c) =>
                (c['args'] as List)[2] == true &&
                (c['args'] as List)[4] == false,
          ),
          isTrue,
        );
      },
    );

    testWidgets('clock: no page errors', (t) async {
      setPhone(t, 412, 915, 2.625);
      final now = realNow + 60 * kDay;
      final lab = Lab(t, db: dbJson(dueRecs(4, now).recs), storeNow: now);
      await lab.openReview();
      await lab.start();
      await lab.drive('rrrr');
      expect(t.takeException(), isNull);
    });

    Future<Lab> behind(WidgetTester t) async {
      setPhone(t, 412, 915, 2.625);
      final now = realNow - 60 * kDay;
      final w4 = words.take(4).toList();
      final lab = Lab(
        t,
        db: dbJson([
          for (var i = 0; i < 4; i++) rec(w4[i], now + kDay * (i + 1)),
        ]),
        storeNow: now,
      );
      await lab.openReview(options: ReviewOptions(only: w4));
      await lab.start();
      await lab.drive('rrww');
      return lab;
    }

    testWidgets(
      'clock: the store is behind Date.now(): the same words are not due, so the answers are not scored (intro)',
      (t) async {
        final lab = await behind(t);
        // nothing is due by the store's clock: a practice session, whatever the solo switch
        expect(lab.s.practice, isTrue);
        final calls = lab.answerCalls();
        expect(calls.length, 4);
        expect(calls.every((c) => (c['args'] as List)[4] == true), isTrue);
      },
    );

    testWidgets('clock: ...yet each answer is still counted (n=1 each)', (
      t,
    ) async {
      final lab = await behind(t);
      for (final w in words.take(4)) {
        expect(lab.store.word(w)!.ear.n, 1);
      }
    });

    testWidgets('clock: no page errors (behind)', (t) async {
      await behind(t);
      expect(t.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------------ 7. switches
  group('repaso_check t_switches', () {
    final d12 = dueRecs(12, kNow);

    testWidgets('switches: ?n=4 asks 4 (of 12 due)', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: dbJson(d12.recs));
      await lab.openReview(options: const ReviewOptions(cap: 4));
      expect([for (final p in lab.s.list) p.word], d12.words.take(4).toList());
    });

    testWidgets('switches: ?solo= asks just those words', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: dbJson(d12.recs));
      await lab.openReview(
        options: const ReviewOptions(only: ['casa', 'puerta']),
      );
      expect([for (final p in lab.s.list) p.word]..sort(), ['casa', 'puerta']);
    });

    testWidgets('switches: ?todo=1&n=200 lists every pair', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: dbJson([]));
      await lab.openReview(options: const ReviewOptions(all: true, cap: 200));
      expect(lab.s.list.length, words.length);
    });

    testWidgets(
      'switches: nothing heard and nothing due: a practice list of up to 10',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final lab = Lab(t, db: dbJson([]));
        await lab.openReview();
        expect(lab.s.list.length, 10);
        expect(lab.s.practice, isTrue);
      },
    );

    testWidgets('switches: ?txt=no shows no sentence text during the session', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: dbJson(d12.recs));
      await lab.openReview(
        options: const ReviewOptions(only: ['casa']),
        captions: CaptionMode.never,
      );
      await lab.start();
      final caps = <String>{};
      for (var i = 0; i < 40; i++) {
        caps.add(lab.s.caption);
        await lab.advance(60);
      }
      expect(caps, {''});
    });

    testWidgets('switches: no page errors', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: dbJson(d12.recs));
      await lab.openReview(options: const ReviewOptions(only: ['casa']));
      await lab.start();
      await lab.advance(3000);
      expect(t.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------------ cual_check.py
  group('cual_check', () {
    Future<Lab> pass(WidgetTester t, String plan, int n) async {
      setPhone(t, 390, 844, 3);
      final d = dueRecs(n, kNow);
      final lab = Lab(t, db: dbJson(d.recs));
      await lab.openReview();
      await lab.start();
      await lab.drive(plan);
      return lab;
    }

    testWidgets(
      'cual_check: a missed word is asked a second time, three items later (asked: a b c a* d ...)',
      (t) async {
        final lab = await pass(t, 'wrrrrrrrrr', 10);
        final q = [
          for (final x in lab.s.queue) '${x.pair.word}${x.again ? '*' : ''}',
        ];
        final a = lab.s.list.first.word;
        expect(q.indexOf('$a*'), 3);
        expect(q.length, 11);
      },
    );

    testWidgets(
      'cual_check: answers, second asks and the end are what the plan made',
      (t) async {
        final lab = await pass(t, 'wrrrwrrrrr', 10);
        expect(lab.s.answers.length, 10);
        expect(lab.s.secondAnswers.length, 2);
        expect(lab.s.answers.where((a) => !a.ok).length, 2);
        expect(lab.s.end!.soon.length, 2);
        expect(lab.s.end!.up.length, 8);
      },
    );

    testWidgets(
      "cual_check: records: each asked word has one scored answer on its ear record (n=1)",
      (t) async {
        final lab = await pass(t, 'wrrrrrrrrr', 10);
        for (final p in lab.s.list) {
          expect(lab.store.word(p.word)!.ear.n, 1);
        }
        expect(lab.answerCalls().length, 10);
      },
    );
  });
}
