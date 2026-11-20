// The plan of Repaso's games (page 15): which words, which game, which sentence, which tiles; on the real data file.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/repaso_course.dart';

final course = RepasoTestCourse();
final RepasoData data = realRepaso;

FakeProgressStore learner(String json, {int now = curseNow}) =>
    FakeProgressStore(clock: FakeClock(now), json: json);

RepasoPlanner planner(
  ProgressStore p, {
  int seed = 7,
  Map<String, String>? last,
}) => RepasoPlanner(
  data: data,
  progress: p,
  pairs: course.pairs,
  rng: Mulberry32(seed),
  lastAsked: last,
);

/// The ear record of [w] in [json] changed by [f].
String withEar(String json, String w, void Function(Map<String, dynamic> e) f) {
  final j = jsonDecode(json) as Map<String, dynamic>;
  f(((j['palabras'] as Map)[w] as Map)['ear'] as Map<String, dynamic>);
  return jsonEncode(j);
}

/// Every check of a wrong tile [m] beside [s] for [target]: the rules of page 15 and order 27.
void expectFair(RepasoWord target, RepasoSentence s, String m) {
  final why = '${target.word} | ${s.text} | $m';
  expect(m, isNot(target.word), reason: why);
  expect(s.forbidden, isNot(contains(m)), reason: why);
  expect(target.apart, isNot(contains(m)), reason: why);
  for (final x in s.forbidden) {
    expect(data.word(x)!.apart, isNot(contains(m)), reason: why);
  }
  final inSentence = foldedTokens(s.text).toSet();
  for (final t in foldedTokens(m)) {
    expect(inSentence, isNot(contains(t)), reason: why);
  }
}

void main() {
  test('the data: 156 words; each word that has a picture pair in the course has its own sentence first', () {
    expect(data.words, hasLength(156));
    for (final w in data.words) {
      final p = course.pairs.where((x) => x.word == w.word).toList();
      if (w.pairLines.isNotEmpty) expect(w.pairLines.first.clip, p.last.say);
    }
  });

  test('N: the words the session takes are exactly the words the shared rule serves (the counts outside Repaso ask the same rule)', () {
    for (final json in [seedJson('curso'), everythingJson(data)]) {
      final p = learner(json);
      final serving = repasoServing(course, p)!;
      final pl = planner(p);
      // every word of the data: the planner says what the rule says
      for (final w in data.words) {
        expect(pl.servable(w), serving.canServe(w.word), reason: w.word);
      }
      // and the due words the session takes are the due words the rule counts, up to the cap
      final counted = [
        for (final w in p.due(Skill.ear))
          if (serving.canServe(w)) w,
      ];
      expect([
        for (final w in pl.sessionWords().words) w.word,
      ], counted.take(repasoCap).toList());
    }
    // the rule serves words with no picture pair: Repaso's count is not only the pair words
    final p = learner(everythingJson(data));
    final serving = repasoServing(course, p)!;
    final noPair = [
      for (final w in data.words)
        if (course.pairs.every((x) => x.word != w.word) &&
            serving.canServe(w.word))
          w.word,
    ];
    expect(noPair, isNotEmpty);
  });

  test('wrong tiles: over EVERY ¿Qué oyes? sentence of the data file, never a forbidden word, and two found', () {
    final all = learner(everythingJson(data));
    final pl = planner(all);
    var n = 0, none = 0;
    for (final w in data.words) {
      for (final k in w.sentences) {
        final s = data.sentences[k];
        if (!s.forHearing) continue;
        n++;
        // every word that could be offered is fair, not only the two picked
        for (final m in pl.wrongTileChoices(w, s)) {
          expectFair(w, s, m.word);
        }
        final two = pl.wrongTiles(w, s);
        if (two == null) {
          none++;
          continue;
        }
        expect(two[0].word, isNot(two[1].word));
        expect(two[0].apart, isNot(contains(two[1].word)));
        for (final m in two) {
          expectFair(w, s, m.word);
        }
        // the same place first, when the place has two
        final same = pl
            .wrongTileChoices(w, s)
            .where((m) => m.place == w.place)
            .length;
        if (same >= 2) expect(two[0].place, w.place, reason: s.text);
      }
    }
    expect(n, greaterThan(1400));
    expect(none, 0);
  });

  test('Arma la frase: over every sentence usable for it, the two extra tiles are fair and not words of it', () {
    final all = learner(everythingJson(data));
    final pl = planner(all);
    var n = 0;
    for (final w in data.words) {
      for (final k in w.sentences) {
        final s = data.sentences[k];
        if (!s.forBuilding) continue;
        final two = pl.wrongTiles(w, s, singleWords: true);
        if (two == null) continue;
        n++;
        for (final m in two) {
          expectFair(w, s, m.word);
          expect(foldedTokens(m.word), hasLength(1));
          expect(s.tokens, isNot(contains(RepasoPlanner.tileForm(m.word))));
        }
      }
    }
    expect(n, greaterThan(200));
  });

  test('the same seed gives the same plan; another seed may not', () {
    String plan(int seed) {
      final p = learner(seedJson('curso'));
      final pl = planner(p, seed: seed);
      final ws = pl.sessionWords();
      return [
        for (final q in pl.queue(ws.words))
          q.slot
              ? 'slot'
              : '${q.item!.kind.name}:${q.item!.word}:${q.item!.clip}:'
                    '${q.item is HearItem ? (q.item as HearItem).tiles.join('/') : ''}',
      ].join('\n');
    }

    expect(plan(3), plan(3));
    expect({for (var s = 1; s < 6; s++) plan(s)}.length, greaterThan(1));
  });

  group('a seeded learner (mid-course, 15 stories played)', () {
    late FakeProgressStore p;
    late RepasoPlanner pl;
    late List<RepasoWord> words;
    late List<QueueEntry> q;
    setUp(() {
      p = learner(seedJson('curso'));
      pl = planner(p, seed: 11);
      final s = pl.sessionWords();
      expect(s.practice, isFalse);
      words = s.words;
      q = pl.queue(words);
    });

    test(
      'ten words, due first and most overdue first, each served by a game',
      () {
        expect(words, hasLength(10));
        final due = p.due(Skill.ear);
        final servable = [
          for (final w in due)
            if (data.word(w) != null && pl.servable(data.word(w)!)) w,
        ];
        expect([for (final w in words) w.word], servable.take(10).toList());
      },
    );

    test(
      'one scored item per word in that order, a play slot after every third',
      () {
        expect([for (final e in q) e.slot ? '+' : 's'].join(), 'sss+sss+sss+s');
        final scored = [
          for (final e in q)
            if (!e.slot) e.item!,
        ];
        expect(
          [for (final i in scored) i.word],
          [for (final w in words) w.word],
        );
        for (final i in scored) {
          expect(i.scored, isTrue);
          final w = data.word(i.word)!;
          final n = p.word(i.word)!.ear.n;
          final hasCual = pl.cualLines(w).isNotEmpty;
          final hasHear = pl.hearSentences(w).isNotEmpty;
          final want = !hasHear
              ? GameKind.cual
              : !hasCual
              ? GameKind.hear
              : (n.isEven ? GameKind.cual : GameKind.hear);
          expect(i.kind, want, reason: '${i.word} n=$n');
        }
        // the session has both scored games
        expect(
          {for (final i in scored) i.kind},
          {GameKind.cual, GameKind.hear},
        );
        // no two scored items share a sentence
        expect({for (final i in scored) i.clip}.length, scored.length);
      },
    );

    test('every sentence is from a story he has finished', () {
      for (final e in q) {
        final i = e.item;
        if (i is HearItem) {
          expect(storyFinished(p, i.sentence.story), isTrue);
        }
        if (i is CualItem && i.line.story != null) {
          expect(storyFinished(p, i.line.story!), isTrue);
        }
      }
    });

    test('the play slots: kinds in turn, none of a scored item\'s sentences, and at least three kinds in all', () {
      final kinds = <GameKind>[];
      for (var i = 0; i < q.length; i++) {
        if (!q[i].slot) continue;
        final it = pl.playItem(words, canSay: true);
        expect(it, isNotNull);
        kinds.add(it!.kind);
      }
      expect(kinds, [GameKind.build, GameKind.match, GameKind.where]);
      final scored = {
        for (final e in q)
          if (!e.slot) e.item!.clip,
      };
      // the play items' sentences (made after the scored ones) are not theirs
      expect(pl.used.length, greaterThan(scored.length));
      expect(
        {GameKind.cual, GameKind.hear, ...kinds}.length,
        greaterThanOrEqualTo(3),
      );
    });

    test('a kind with no material is skipped: Dilo off, and no ¿Dónde? material, go on to the next kind', () {
      final it = [
        for (var i = 0; i < 6; i++) pl.playItem(words, canSay: false)?.kind,
      ];
      expect(it, isNot(contains(GameKind.say)));
      expect(it.first, GameKind.build);
    });
  });

  group('which game, which sentence', () {
    final everything = everythingJson(data);
    // a word with a pair and many sentences of both kinds
    final w = data.word('bola')!;

    test('even count ¿Cuál?, odd ¿Qué oyes?; after a miss ¿Cuál?', () {
      for (var n = 0; n < 6; n++) {
        final p = learner(withEar(everything, 'bola', (e) => e['n'] = n));
        expect(
          planner(p).scoredKind(w),
          n.isEven ? GameKind.cual : GameKind.hear,
          reason: 'n=$n',
        );
        final miss = learner(
          withEar(everything, 'bola', (e) {
            e['n'] = n;
            e['fallos'] = 1;
          }),
        );
        expect(planner(miss).scoredKind(w), GameKind.cual, reason: 'miss n=$n');
      }
      // the third miss parks it and clears fallos: still a miss
      final parked = learner(
        withEar(everything, 'bola', (e) {
          e['n'] = 3;
          e['ultima'] = 1000;
          e['aparcada'] = 1000 + 7 * 86400000;
        }),
      );
      expect(planner(parked).scoredKind(w), GameKind.cual);
    });

    test('a word with no pair is ¿Qué oyes? only; a word with no sentence ¿Cuál? only', () {
      final p = learner(everything);
      final pl = planner(p);
      final noPair = data.words.firstWhere(
        (x) => x.pairLines.isEmpty && pl.hearSentences(x).isNotEmpty,
      );
      final noSentence = data.words.firstWhere(
        (x) => x.pairLines.isNotEmpty && pl.hearSentences(x).isEmpty,
      );
      for (var n = 0; n < 4; n++) {
        final q = learner(withEar(everything, noPair.word, (e) => e['n'] = n));
        expect(planner(q).scoredKind(noPair), GameKind.hear);
        final r = learner(
          withEar(everything, noSentence.word, (e) => e['n'] = n),
        );
        expect(planner(r).scoredKind(noSentence), GameKind.cual);
      }
      // the two words no game can serve are never asked
      for (final x in data.words.where(
        (x) => x.scoring == RepasoScoring.none,
      )) {
        expect(pl.servable(x), isFalse, reason: x.word);
      }
    });

    test('rotation: two reviews running are never the same sentence, for every word that has more than one', () {
      final rng = Mulberry32(5);
      var checked = 0, forcedRepeats = 0;
      for (final x in data.words) {
        var json = everything;
        final last = <String, String>{};
        String? before;
        final seen = <String>{};
        final p0 = planner(learner(json));
        final pool = {
          for (final l in p0.cualLines(x)) l.clip,
          for (final s in p0.hearSentences(x)) s.clip,
        };
        if (pool.length < 2) continue;
        checked++;
        for (var r = 0; r < 16; r++) {
          final p = learner(json);
          final pr = planner(p, seed: r, last: last);
          final it = pr.scoredItem(x);
          if (before != null) {
            // the one case it cannot be helped: ¿Cuál? after a miss (page 15), and ¿Cuál? has that sentence only
            final lines = pr.cualLines(x);
            final forced =
                it.kind == GameKind.cual &&
                lines.length == 1 &&
                lines.single.clip == before;
            if (forced) {
              forcedRepeats++;
            } else {
              expect(it.clip, isNot(before), reason: '${x.word}, review $r');
            }
          }
          seen.add(it.clip!);
          before = it.clip;
          last[x.word] = it.clip!;
          // he answers, right or wrong; the store's count moves on as the record would
          final ok = rng.next() < .7;
          json = withEar(json, x.word, (e) {
            e['n'] = (e['n'] as int) + 1;
            if (ok) e['bien'] = (e['bien'] as int) + 1;
            e['fallos'] = ok ? 0 : (e['fallos'] as int) + 1;
          });
        }
        // and the sentences take turns: more than one of them comes up
        expect(seen.length, greaterThan(1), reason: x.word);
      }
      expect(checked, greaterThan(100));
      // ignore: avoid_print
      printOnFailure('forced repeats: $forcedRepeats');
    });

    test('only the sentences of finished stories: none finished, only the pair\'s own sentence', () {
      final j = jsonDecode(everything) as Map<String, dynamic>;
      j['cuentos'] = {};
      final p = learner(jsonEncode(j));
      final pl = planner(p);
      for (final x in data.words) {
        expect(pl.hearSentences(x), isEmpty, reason: x.word);
        expect([
          for (final l in pl.cualLines(x)) l.story,
        ], x.pairLines.isEmpty ? <String?>[] : <String?>[null]);
      }
      // a story the level check only presumed is not finished
      j['cuentos'] = {
        'la-lluvia': {'n': 1, 'primera': 1, 'presunto': 1},
      };
      expect(storyFinished(learner(jsonEncode(j)), 'la-lluvia'), isFalse);
      j['cuentos'] = {
        'la-lluvia': {'n': 2, 'primera': 1, 'presunto': 1},
      };
      expect(storyFinished(learner(jsonEncode(j)), 'la-lluvia'), isTrue);
      // a picture story heard to its end is
      j['oidos'] = {'d-toc-toc': 1};
      expect(storyFinished(learner(jsonEncode(j)), 'd-toc-toc'), isTrue);
    });

    test('practice: nothing due, the words he has heard in a mixed order, up to ten', () {
      final j = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
      final p = learner(jsonEncode(j), now: 1700000000000);
      expect(p.due(Skill.ear), isEmpty);
      final s = planner(p).sessionWords();
      expect(s.practice, isTrue);
      expect(s.words, hasLength(10));
      final heard = {for (final r in p.words) r.w};
      for (final w in s.words) {
        expect(heard, contains(w.word));
      }
    });
  });

  test('findWord lights the word, a phrase, a plural, with accents folded', () {
    String lit(String text, String w) {
      final r = findWord(text, w);
      return r == null ? '-' : text.substring(r.start, r.end);
    }

    expect(lit('Abuela abre la puerta.', 'puerta'), 'puerta');
    expect(lit('¡No hay leche!', 'no hay'), 'No hay');
    expect(lit('Las flores son rojas.', 'flor'), 'flores');
    expect(lit('El bebé bebe.', 'bebe'), 'bebe');
    expect(lit('El bebé bebe.', 'bebé'), 'bebé');
    expect(lit('Bebe agua.', 'bebé'), 'Bebe');
    expect(lit('¿Y tú?', '¿y tú?'), 'Y tú');
    expect(lit('Una floreria.', 'flor'), '-');
  });
}
