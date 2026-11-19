// The Repaso screen on the fakes: one test for each check of historia/tools/repaso_check.py (the old script's name
// for the check is in the test's name), first half: cap, six, early, reask, reask_order, dim.
// The old script's "no page errors" is `tester.takeException()` being null: Flutter fails the test by itself on
// an error, and these tests say so too.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Visibility;

import 'support/lab.dart';

void main() {
  final words = pairWords();

  // ------------------------------------------------------------------ 1. cap
  group('repaso_check t_cap', () {
    late List<String> ws;
    late String db;
    setUp(() {
      final d = dueRecs(14, kNow);
      ws = d.words;
      db = dbJson(d.recs);
    });

    testWidgets('cap: 14 due, the session asks 10', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: db);
      await lab.openReview();
      expect(lab.s.list.length, 10);
    });

    testWidgets('cap: the 10 most overdue, most overdue first', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: db);
      await lab.openReview();
      expect([for (final p in lab.s.list) p.word], ws.take(10).toList());
    });

    testWidgets(
      'cap: the start line is for this session only: 10 words · about 2 min',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        await Lab(t, db: db).openReview();
        expect(find.text('10 words · about 2 min'), findsOneWidget);
      },
    );

    testWidgets('cap: the start screen title is Repaso', (t) async {
      setPhone(t, 412, 915, 2.625);
      await Lab(t, db: db).openReview();
      expect(find.text('Repaso'), findsOneWidget);
    });

    testWidgets(
      'cap: one line under the title says what to do: Listen, then touch the picture that fits.',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        await Lab(t, db: db).openReview();
        expect(
          find.text('Listen, then touch the picture that fits.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('cap: the X and the sound button show on the start screen', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      await Lab(t, db: db).openReview();
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
      expect(shown(LessonCloseButton), isTrue);
      expect(shown(LessonSoundButton), isTrue);
    });

    testWidgets('cap: the progress bar has 10 segments', (t) async {
      setPhone(t, 412, 915, 2.625);
      await Lab(t, db: db).openReview();
      expect(
        t
            .widget<LessonProgressDashes>(find.byType(LessonProgressDashes))
            .segments,
        10,
      );
    });

    testWidgets('cap: all 10 asked, once each, none of the 4 waiting', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: db);
      await lab.openReview();
      await lab.start();
      expect(await lab.drive(''), ws.take(10).toList());
    });

    testWidgets('cap: the 4 that wait are untouched', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: db);
      await lab.openReview();
      await lab.start();
      await lab.drive('');
      final answered = [
        for (final c in lab.answerCalls()) (c['args'] as List)[0],
      ];
      expect(answered.any(ws.skip(10).contains), isFalse);
      for (final w in ws.skip(10)) {
        expect(lab.store.word(w)!.ear.n, 0);
      }
    });

    testWidgets(
      'cap: the 10 asked were scored (one right answer each, scheduled by the store: not intro)',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final lab = Lab(t, db: db);
        await lab.openReview();
        await lab.start();
        await lab.drive('');
        final calls = lab.answerCalls();
        expect(calls.length, 10);
        for (var i = 0; i < 10; i++) {
          // PAL.responde(w, "ear", ok, ms, intro): a due word is not an intro
          expect((calls[i]['args'] as List).sublist(0, 3), [
            ws[i],
            'ear',
            true,
          ]);
          expect((calls[i]['args'] as List)[4], false);
        }
        for (final w in ws.take(10)) {
          expect(lab.store.word(w)!.ear.bien, 1);
        }
      },
    );

    testWidgets('cap: no page errors', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: db);
      await lab.openReview();
      await lab.start();
      await lab.drive('');
      expect(t.takeException(), isNull);
    });

    testWidgets('cap: 3 due, 3 asked, 3 words · about 1 min', (t) async {
      setPhone(t, 412, 915, 2.625);
      final d = dueRecs(3, kNow);
      final lab = Lab(t, db: dbJson(d.recs));
      await lab.openReview();
      expect([for (final p in lab.s.list) p.word], d.words);
      expect(find.text('3 words · about 1 min'), findsOneWidget);
    });

    testWidgets('order: most overdue first, whatever the order of the words', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final ws12 = words.take(12).toList();
      final recs = [
        for (var i = 0; i < 12; i++) rec(ws12[i], kNow - (i + 1) * 3600000),
      ];
      final lab = Lab(t, db: dbJson(recs));
      await lab.openReview();
      expect([
        for (final p in lab.s.list) p.word,
      ], ws12.reversed.take(10).toList());
    });
  });

  // ------------------------------------------------------------------ 2. six
  group('repaso_check t_six', () {
    String oneDue() => dbJson([rec('casa', kNow - 3600000)]);
    const one = ReviewOptions(only: ['casa'], cap: 1);

    Future<Lab> ready(
      WidgetTester t, {
      CaptionMode c = CaptionMode.during,
    }) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: oneDue());
      await lab.openReview(options: one, captions: c);
      await lab.start();
      await lab.until(() => lab.s.ready);
      return lab;
    }

    testWidgets('six: ?txt=no keeps the sentence text off the screen', (
      t,
    ) async {
      final lab = await ready(t, c: CaptionMode.never);
      expect(lab.s.caption, '');
      expect(find.text('Esta es la casa de abuela.'), findsNothing);
    });

    testWidgets(
      'six: 5 s of silence: the sentence has not played again, no ring',
      (t) async {
        final lab = await ready(t);
        final n0 = lab.clips.plays.length;
        await lab.advance(5000);
        expect(lab.clips.plays.length, n0);
        expect(lab.s.panels!.any((p) => p.sign), isFalse);
        expect(lab.choices.every((c) => c.ring == ChoiceRing.none), isTrue);
      },
    );

    testWidgets(
      'six: 6 s after the sentence ended it played again (5.9 to 6.5 s)',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.asks[0].rep != null);
        final a = lab.s.asks[0];
        expect((a.rep! - a.fin!) / 1000, inInclusiveRange(5.9, 6.5));
      },
    );

    testWidgets(
      'six: the two pictures ask for the default 196 x 104, animated, named after the pair and its side',
      (t) async {
        final lab = await ready(t);
        final panels = lab.s.panels!;
        expect(panels.length, 2);
        final asked = [
          for (final a in lab.pictures.asked)
            if (panels.any((p) => identical(p.ref, a.ref))) a,
        ];
        expect(asked.length, 2);
        for (final a in asked) {
          expect((a.width, a.height, a.animated), (196, 104, true));
        }
        final pair = lab.s.queue[lab.s.index].pair;
        final right = panels.firstWhere((p) => p.right);
        final wrong = panels.firstWhere((p) => !p.right);
        expect(right.ref, PictureRef.of(pair, pair.yes));
        expect(wrong.ref, PictureRef.of(pair, pair.no));
        expect(right.ref.name, '${pair.word}.si');
        expect(wrong.ref.name, '${pair.word}.no');
      },
    );

    testWidgets('six: the sentence was started again (audio)', (t) async {
      final lab = await ready(t);
      final n0 = lab.clips.plays.length;
      await lab.until(() => lab.s.asks[0].rep != null);
      await lab.advance(10);
      expect(lab.clips.plays.length, n0 + 1);
    });

    testWidgets(
      'six: while it plays again no picture is shown yet, and the pictures are at full brightness (a touch counts)',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.asks[0].rep != null);
        await lab.advance(10);
        expect(lab.s.panels!.any((p) => p.sign), isFalse);
        expect(lab.choices.every((c) => c.dim == ChoiceDim.none), isTrue);
      },
    );

    testWidgets(
      'six: 6 s after it ended again the right picture was shown (5.9 to 6.5 s)',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.asks[0].auto != null);
        final a = lab.s.asks[0];
        expect((a.auto! - a.repFin!) / 1000, inInclusiveRange(5.9, 6.5));
      },
    );

    testWidgets(
      'six: the right picture has the green ring and the sign, the other none',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.panels!.any((p) => p.sign));
        final r = lab.right;
        expect(lab.s.panels![r].sign, isTrue);
        expect(lab.s.panels![1 - r].sign, isFalse);
        expect(lab.choices[r].ring, ChoiceRing.right);
        expect(lab.choices[1 - r].ring, ChoiceRing.none);
      },
    );

    testWidgets(
      'six: it counts as a miss: recorded wrong (auto), a scored answer with ok false',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.panels!.any((p) => p.sign));
        final h = lab.s.answers;
        expect(h.length, 1);
        expect([h[0].word, h[0].ok, h[0].auto], ['casa', false, true]);
        final c = lab.answerCalls();
        expect((c[0]['args'] as List)[0], 'casa');
        expect((c[0]['args'] as List)[2], false);
        expect((c[0]['args'] as List)[4], false);
        expect(lab.store.word('casa')!.ear.bien, 0);
      },
    );

    testWidgets('six: he has to touch it: nothing moves on while he waits', (
      t,
    ) async {
      final lab = await ready(t);
      await lab.until(() => lab.s.panels!.any((p) => p.sign));
      await lab.advance(2500);
      expect(lab.s.panels!.any((p) => p.sign), isTrue);
      expect(lab.s.index, 0);
    });

    testWidgets('six: touching the other one does nothing', (t) async {
      final lab = await ready(t);
      await lab.until(() => lab.s.panels!.any((p) => p.sign));
      await lab.touchPicture(1 - lab.right);
      await lab.advance(300);
      expect(lab.s.panels!.any((p) => p.sign), isTrue);
    });

    testWidgets(
      'six: after the shown touch the word comes back once (the end of a one-word session)',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.panels!.any((p) => p.sign));
        await lab.touchPicture(lab.right);
        await lab.until(
          () => lab.s.queue.length == 2 && lab.s.index == 1 && lab.s.ready,
        );
        expect(
          [for (final q in lab.s.queue) (q.pair.word, q.again)],
          [('casa', false), ('casa', true)],
        );
      },
    );

    testWidgets('six: no page errors', (t) async {
      final lab = await ready(t);
      await lab.until(() => lab.s.panels!.any((p) => p.sign));
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'six (b): a touch while/after it plays again counts as an answer (right, no auto)',
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.asks[0].rep != null);
        await lab.touchPicture(lab.right);
        await lab.advance(1500);
        final h = lab.s.answers;
        expect(h.length, 1);
        expect([h[0].ok, h[0].auto], [true, false]);
        expect(lab.s.asks[0].auto, isNull);
      },
    );

    testWidgets(
      "six (b): ...and its time is from the end of the first sentence (>= 6 s)",
      (t) async {
        final lab = await ready(t);
        await lab.until(() => lab.s.asks[0].rep != null);
        await lab.touchPicture(lab.right);
        expect(lab.s.answers[0].ms, greaterThanOrEqualTo(6000));
      },
    );

    testWidgets('six (b): no page errors', (t) async {
      final lab = await ready(t);
      await lab.until(() => lab.s.asks[0].rep != null);
      await lab.touchPicture(lab.right);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'six (c): a touch before 6 s: no replay, a wrong touch is a plain miss (not auto)',
      (t) async {
        final lab = await ready(t);
        await lab.advance(3000);
        await lab.touchPicture(1 - lab.right);
        await lab.advance(1200);
        expect(lab.s.asks[0].rep, isNull);
        expect(lab.s.asks[0].auto, isNull);
        expect([lab.s.answers[0].ok, lab.s.answers[0].auto], [false, false]);
      },
    );
  });

  // ------------------------------------------------------------------ 3. early
  group('repaso_check t_early', () {
    String two() =>
        dbJson([rec('casa', kNow - 3600000), rec('puerta', kNow - 1800000)]);

    testWidgets('early: touches before the sentence ends are ignored', (
      t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: two());
      await lab.openReview();
      await lab.start();
      await lab.until(() => lab.s.panels != null);
      for (var i = 0; i < 8; i++) {
        await lab.touchPicture(0);
        await lab.touchPicture(1);
        await lab.advance(40);
      }
      expect(lab.s.answers.length, 0);
      expect(lab.s.ready, isFalse);
    });

    testWidgets(
      "early: the touch after it counts and goes into the word's ear record (progress.answer)",
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final lab = Lab(t, db: two());
        await lab.openReview();
        await lab.start();
        await lab.until(() => lab.s.ready);
        await lab.touchPicture(lab.right);
        final c = lab.answerCalls();
        expect(c.length, 1);
        final w = (c[0]['args'] as List)[0] as String;
        expect(lab.s.answers[0].ok, isTrue);
        expect(lab.store.word(w)!.ear.n, 1);
        expect(lab.store.word(w)!.ear.bien, 1);
      },
    );

    testWidgets('early: no page errors', (t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(t, db: two());
      await lab.openReview();
      await lab.start();
      await lab.until(() => lab.s.panels != null);
      await lab.touchPicture(0);
      expect(t.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------------ 4. reask
  group('repaso_check t_reask', () {
    late List<String> ws;
    late Lab lab;
    late List<String> seen;
    final bars = <(int, int, int)>[];
    late Map<String, Object?> before3;
    late Map<String, Object?> before8;
    late Map<String, Object?> after;

    Future<void> play(WidgetTester t) async {
      setPhone(t, 412, 915, 2.625);
      final d = dueRecs(7, kNow);
      ws = d.words;
      lab = Lab(t, db: dbJson(d.recs));
      await lab.openReview();
      await lab.start();
      bars.clear();
      // by ask: 0 a wrong, 1 b, 2 c, 3 a* right, 4 d, 5 e, 6 f wrong, 7 g, 8 f* wrong
      seen = await lab.drive(
        'wrrrrrwrw',
        every: (k) async {
          await t.pump(const Duration(milliseconds: 250));
          final bar = t.widget<LessonProgressDashes>(
            find.byType(LessonProgressDashes),
          );
          bars.add((k, bar.segments, bar.done));
          if (k == 3) before3 = lab.store.word(ws[0])!.toJson();
          if (k == 8) before8 = lab.store.word(ws[5])!.toJson();
        },
      );
      after = {
        'a': lab.store.word(ws[0])!.toJson(),
        'f': lab.store.word(ws[5])!.toJson(),
      };
    }

    testWidgets(
      'reask: the queue is a b c a* d e f g f* (a back three items later, f, the sixth of seven, at the end)',
      (t) async {
        await play(t);
        final (a, b, c, d, e, f, g) = (
          ws[0],
          ws[1],
          ws[2],
          ws[3],
          ws[4],
          ws[5],
          ws[6],
        );
        expect(seen, [a, b, c, '$a*', d, e, f, g, '$f*']);
      },
    );

    testWidgets(
      'reask: a missed word comes back once only (f* wrong: no third ask)',
      (t) async {
        await play(t);
        expect(seen.length, 9);
        expect(seen.where((x) => x == '${ws[5]}*').length, 1);
      },
    );

    testWidgets(
      'reask: the scored answers are the 7 words only (a wrong, f wrong, the rest right)',
      (t) async {
        await play(t);
        expect(
          [for (final h in lab.s.answers) (h.word, h.ok)],
          [
            (ws[0], false),
            (ws[1], true),
            (ws[2], true),
            (ws[3], true),
            (ws[4], true),
            (ws[5], false),
            (ws[6], true),
          ],
        );
      },
    );

    testWidgets('reask: the second asks are kept apart: a* right, f* wrong', (
      t,
    ) async {
      await play(t);
      expect(
        [for (final h in lab.s.secondAnswers) (h.word, h.ok)],
        [(ws[0], true), (ws[5], false)],
      );
    });

    testWidgets(
      "reask: a's record is the same before and after its second ask (unscored: nothing written)",
      (t) async {
        await play(t);
        // the second ask of a is ask 3: what was stored just before it is what is stored at the end
        expect(before3, after['a']);
      },
    );

    testWidgets(
      "reask: f's record is the same before and after its (wrong) second ask",
      (t) async {
        await play(t);
        expect(before8, after['f']);
      },
    );

    testWidgets(
      'reask: the miss itself was scored once: a n=1, f the same (progress.answer(ok: false), not an intro)',
      (t) async {
        await play(t);
        for (final w in [ws[0], ws[5]]) {
          expect(lab.store.word(w)!.ear.n, 1);
          final c = [
            for (final x in lab.answerCalls())
              if ((x['args'] as List)[0] == w) x,
          ];
          expect(c.length, 1);
          expect((c[0]['args'] as List)[2], false);
        }
      },
    );

    testWidgets('reask: the right ones were scored once (n=1, one right)', (
      t,
    ) async {
      await play(t);
      for (final w in [ws[1], ws[2], ws[3], ws[4], ws[6]]) {
        expect(lab.store.word(w)!.ear.n, 1);
        expect(lab.store.word(w)!.ear.bien, 1);
      }
    });

    testWidgets(
      'reask: the bar has one segment per word of the session (7) all the time, a second ask adds none; lit = words answered so far',
      (t) async {
        await play(t);
        expect(bars.length, 9);
        var scored = 0;
        for (final (k, n, on) in bars) {
          expect(n, 7, reason: 'ask $k');
          expect(on, scored, reason: 'ask $k');
          if (!seen[k].endsWith('*')) scored++;
        }
      },
    );

    testWidgets('reask: the bar is full at the end', (t) async {
      await play(t);
      final bar = t.widget<LessonProgressDashes>(
        find.byType(LessonProgressDashes),
      );
      expect([bar.segments, bar.done], [7, 7]);
    });

    testWidgets('reask: no page errors', (t) async {
      await play(t);
      expect(t.takeException(), isNull);
    });

    Future<(Map<String, int>, Map<String, int>, Lab)> tenMissed(
      WidgetTester t,
    ) async {
      setPhone(t, 412, 915, 2.625);
      final d = dueRecs(10, kNow);
      final lab = Lab(t, db: dbJson(d.recs));
      await lab.openReview(options: const ReviewOptions(cap: 10));
      await lab.start();
      final first = <String, int>{};
      final second = <String, int>{};
      await lab.drive(
        'w' * 20,
        every: (k) async {
          final q = lab.s.queue[k];
          (q.again ? second : first)[q.pair.word] = lab.right;
        },
      );
      return (first, second, lab);
    }

    testWidgets('reask_order: 10 missed words came back, each once', (t) async {
      final (_, second, lab) = await tenMissed(t);
      expect(second.length, 10);
      expect(lab.s.queue.length, 20);
    });

    testWidgets(
      'reask_order: the second ask draws the two pictures afresh (the same place in some of the 10, not in none and not in all)',
      (t) async {
        final (first, second, _) = await tenMissed(t);
        final same = second.keys.where((w) => second[w] == first[w]).length;
        expect(same, inExclusiveRange(0, 10));
      },
    );
  });

  // ------------------------------------------------------------------ 4b. dim
  group('repaso_check t_dim', () {
    Future<Lab> two(WidgetTester t) async {
      setPhone(t, 412, 915, 2.625);
      final lab = Lab(
        t,
        db: dbJson([
          rec('casa', kNow - 3600000),
          rec('puerta', kNow - 7200000),
        ]),
      );
      await lab.openReview(
        options: const ReviewOptions(only: ['casa', 'puerta']),
      );
      await lab.start();
      return lab;
    }

    testWidgets('dim: while the sentence plays both pictures are dimmed', (
      t,
    ) async {
      final lab = await two(t);
      await lab.until(() => lab.s.speaking > 0);
      await lab.advance(100);
      expect(lab.s.ready, isFalse);
      expect(lab.choices.length, 2);
      expect(
        lab.choices.every((c) => c.dim == ChoiceDim.whileSentence),
        isTrue,
      );
    });

    testWidgets('dim: when it ends they come to full brightness', (t) async {
      final lab = await two(t);
      await lab.until(() => lab.s.ready);
      await lab.advance(10);
      expect(lab.choices.every((c) => c.dim == ChoiceDim.none), isTrue);
    });

    testWidgets(
      'dim: right: the green ring and a check badge on the touched picture, none on the other',
      (t) async {
        final lab = await two(t);
        await lab.until(() => lab.s.ready);
        final r = lab.right;
        await lab.touchPicture(r);
        await lab.advance(250);
        expect(lab.choices[r].ring, ChoiceRing.right);
        expect(lab.choices[r].check, isTrue);
        expect(lab.choices[1 - r].ring, ChoiceRing.none);
        expect(lab.choices[1 - r].check, isFalse);
      },
    );

    testWidgets(
      'dim: right: the other picture dims, the right one stays bright',
      (t) async {
        final lab = await two(t);
        await lab.until(() => lab.s.ready);
        final r = lab.right;
        await lab.touchPicture(r);
        await lab.advance(250);
        expect(lab.choices[1 - r].dim, ChoiceDim.unchosen);
        expect(lab.choices[r].dim, ChoiceDim.none);
      },
    );

    testWidgets(
      'dim: the next ask starts dimmed again, and the badge of the last one is gone',
      (t) async {
        final lab = await two(t);
        await lab.until(() => lab.s.ready);
        await lab.touchPicture(lab.right);
        await lab.until(() => lab.s.index == 1 && lab.s.panels != null);
        await lab.advance(10);
        expect(
          lab.choices.every((c) => c.dim == ChoiceDim.whileSentence),
          isTrue,
        );
        expect(lab.choices.any((c) => c.check), isFalse);
      },
    );

    testWidgets(
      'dim: wrong: the touched picture has the red-orange ring and dims, no badge, nothing shown yet on the other',
      (t) async {
        final lab = await two(t);
        await lab.until(() => lab.s.ready);
        final r = lab.right;
        await lab.touchPicture(1 - r);
        await lab.advance(150);
        expect(lab.choices[1 - r].ring, ChoiceRing.wrong);
        expect(lab.choices[1 - r].dim, ChoiceDim.unchosen);
        expect(lab.choices.any((c) => c.check), isFalse);
        expect(lab.choices[r].ring, ChoiceRing.none);
      },
    );

    testWidgets(
      'dim: wrong, then the right one shows: green ring and the sign, no badge (as today)',
      (t) async {
        final lab = await two(t);
        await lab.until(() => lab.s.ready);
        final r = lab.right;
        await lab.touchPicture(1 - r);
        await lab.until(() => lab.s.panels!.any((p) => p.sign));
        expect(lab.choices[r].ring, ChoiceRing.right);
        expect(lab.s.panels![r].sign, isTrue);
        expect(lab.choices.any((c) => c.check), isFalse);
        expect(lab.choices[r].dim, ChoiceDim.none);
      },
    );

    testWidgets('dim: no page errors', (t) async {
      final lab = await two(t);
      await lab.until(() => lab.s.ready);
      expect(t.takeException(), isNull);
    });
  });
}
