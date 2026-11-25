// Issue #10 policy tests: no story screenshots or story-scene crops on flashcards; dedicated single-word
// word_assets/... pairs only; unpicturable words never tested with pictures.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/word_picture.dart';
import 'package:feature_review/src/ui/book_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

class _ForbidPictures implements PictureSource {
  @override
  Widget of(
    PictureRef ref, {
    int width = 196,
    int height = 104,
    bool animated = false,
  }) => fail('ScenePictures.of($ref) must never be called under #10');

  @override
  Future<void> warm(Iterable<PictureRef> refs) async =>
      fail('ScenePictures.warm($refs) must never be called under #10');
}

void main() {
  test('isDedicatedWordAssetPath and WordPictureAsset.isUsable enforce #10 path rules', () {
    expect(isDedicatedWordAssetPath('word_assets/puerta.png'), isTrue);
    expect(isDedicatedWordAssetPath(' word_assets/casa.png '), isTrue);
    expect(isDedicatedWordAssetPath(''), isFalse);
    expect(isDedicatedWordAssetPath('   '), isFalse);
    expect(isDedicatedWordAssetPath('word_assets/'), isFalse);
    expect(isDedicatedWordAssetPath('/word_assets/puerta.png'), isFalse);
    expect(isDedicatedWordAssetPath('img/la-lluvia-1.png'), isFalse);
    expect(isDedicatedWordAssetPath('libros/img/la-lluvia-1.png'), isFalse);
    expect(isDedicatedWordAssetPath('word_assets/../img/x.png'), isFalse);
    expect(isDedicatedWordAssetPath(r'word_assets\puerta.png'), isFalse);
    expect(isDedicatedWordAssetPath('word_assets/dir/'), isFalse);
    expect(isDedicatedWordAssetPath('word_assets//puerta.png'), isFalse);

    expect(
      const WordPictureAsset(
        word: 'puerta',
        yesAsset: 'word_assets/puerta.png',
        noAsset: 'word_assets/ventana.png',
      ).isUsable,
      isTrue,
    );
    expect(
      const WordPictureAsset(
        word: 'sí',
        yesAsset: 'word_assets/si.png',
        noAsset: 'word_assets/no.png',
        picturable: false,
      ).isUsable,
      isFalse,
    );
    expect(
      const WordPictureAsset(
        word: 'puerta',
        yesAsset: 'word_assets/puerta.png',
        noAsset: ' word_assets/puerta.png ',
      ).isUsable,
      isFalse,
    );
    expect(
      const WordPictureAsset(
        word: 'puerta',
        yesAsset: 'img/la-lluvia-1.png',
        noAsset: 'word_assets/ventana.png',
      ).isUsable,
      isFalse,
    );
    expect(
      const WordPictureAsset(
        word: 'puerta',
        yesAsset: 'word_assets/puerta.png',
        noAsset: 'libros/img/la-lluvia-2.png',
      ).isUsable,
      isFalse,
    );
  });

  test('unpicturable words never schedule CualItem even if given picturable: false or default empty wordAssets', () {
    final p = FakeProgressStore(
      clock: FakeClock(curseNow),
      json: everythingJson(realRepaso),
    );
    const unpicturable = ['sí', 'no', 'hola', 'adiós', 'gracias', 'bien'];
    for (final word in unpicturable) {
      final w = realRepaso.word(word)!;
      final plDefault = RepasoPlanner(
        data: realRepaso,
        progress: p,
        pairs: RepasoTestCourse().pairs,
        rng: Mulberry32(1),
      );
      expect(plDefault.cualLines(w), isEmpty, reason: word);
      expect(plDefault.scoredKind(w), GameKind.hear, reason: word);

      final plExplicitFalse = RepasoPlanner(
        data: realRepaso,
        progress: p,
        pairs: RepasoTestCourse().pairs,
        rng: Mulberry32(1),
        wordAssets: {
          word: WordPictureAsset(
            word: word,
            yesAsset: 'word_assets/${w.place}_yes.png',
            noAsset: 'word_assets/${w.place}_no.png',
            picturable: false,
          ),
        },
      );
      expect(plExplicitFalse.cualLines(w), isEmpty, reason: word);
      expect(plExplicitFalse.scoredKind(w), GameKind.hear, reason: word);
    }

    // Pair-only words (tengo hambre, tengo sed, listo, ya) have no native oyes sentences in repaso.json;
    // under #10 they still clear via text-only HearItem (zero pictures) so Map/Palabras due counts stay aligned,
    // and never pick an `apart` or in-sentence word as a wrong tile (even with minimal met-word fallback).
    for (final word in ['tengo hambre', 'tengo sed', 'listo', 'ya']) {
      final w = realRepaso.word(word)!;
      for (var seed = 1; seed <= 20; seed++) {
        final pl = RepasoPlanner(
          data: realRepaso,
          progress: p,
          pairs: RepasoTestCourse().pairs,
          rng: Mulberry32(seed),
        );
        expect(pl.cualLines(w), isEmpty, reason: word);
        expect(pl.servable(w), isTrue, reason: word);
        expect(pl.scoredKind(w), GameKind.hear, reason: word);
        final it = pl.scoredItem(w);
        expect(it, isA<HearItem>(), reason: word);
        final hear = it as HearItem;
        expect(hear.sentence.picture, isNull, reason: word);
        expect(hear.tiles, contains(word), reason: word);
        expect(hear.speakers, isTrue, reason: word);
        for (final apart in w.apart) {
          expect(
            hear.tiles,
            isNot(contains(apart)),
            reason: '$word seed=$seed',
          );
        }
      }
    }
    // Even if a learner has met only `tengo hambre`, the fallback pool respects `apart` (`tengo sed`) and in-sentence tokens.
    final minimalDb = jsonDecode(seedJson('vacio')) as Map<String, dynamic>;
    (minimalDb['palabras'] as Map)['tengo hambre'] = {
      'w': 'tengo hambre',
      'ear': {'n': 0, 'bien': 0, 'fallos': 0, 'due': 1, 'ultima': 0},
      'mouth': {'n': 0, 'bien': 0, 'fallos': 0, 'due': 0, 'ultima': 0},
    };
    final minimalProgress = FakeProgressStore(
      clock: FakeClock(curseNow),
      json: jsonEncode(minimalDb),
    );
    final hunger = realRepaso.word('tengo hambre')!;
    for (var seed = 1; seed <= 20; seed++) {
      final pl = RepasoPlanner(
        data: realRepaso,
        progress: minimalProgress,
        pairs: RepasoTestCourse().pairs,
        rng: Mulberry32(seed),
      );
      final hear = pl.scoredItem(hunger) as HearItem;
      expect(hear.tiles, contains('tengo hambre'));
      expect(hear.tiles, isNot(contains('tengo sed')));
      expect(hear.tiles.toSet(), hasLength(3));
    }
  });

  testWidgets(
    'default Repaso session (curso.json and everythingJson) has zero CualItem, zero WhereItem, zero BookImage, zero PictureChoice, and never calls PictureSource',
    (t) async {
      for (final json in [seedJson('curso'), everythingJson(realRepaso)]) {
        final sc = Screen(t, json: json, pictures: _ForbidPictures());
        await sc.open();
        await sc.play(
          each: (moment) async {
            final it = sc.s.item!;
            expect(it.kind, isNot(GameKind.cual), reason: moment);
            expect(it.kind, isNot(GameKind.where), reason: moment);
            expect(find.byType(BookImage), findsNothing, reason: moment);
            expect(find.byType(PictureChoice), findsNothing, reason: moment);
          },
        );
        expect(sc.s.screen, LessonScreen.end);
      }
    },
  );

  testWidgets(
    'dedicated WordPictureAsset activates CualItem for concrete words using word_assets/... URLs and never calls PictureSource',
    (t) async {
      final yesImg = await wordAssetStandIn(t, color: CoquiColors.lessonGreen);
      final noImg = await wordAssetStandIn(t, color: CoquiColors.lessonBlue);
      final requestedUrls = <String>[];

      final db = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
      final puerta = ((db['palabras'] as Map)['puerta'] as Map);
      final ear = puerta['ear'] as Map;
      ear['n'] = 0;

      const asset = WordPictureAsset(
        word: 'puerta',
        yesAsset: 'word_assets/puerta.png',
        noAsset: 'word_assets/ventana.png',
      );
      final sc = Screen(
        t,
        json: jsonEncode(db),
        pictures: _ForbidPictures(),
        wordAssets: {'puerta': asset},
      );
      await sc.open(
        imageProvider: (url) {
          requestedUrls.add(url);
          return url.contains('puerta.png') ? yesImg : noImg;
        },
      );
      final w = realRepaso.word('puerta')!;
      final pl = sc.s.planner;
      expect(pl.cualLines(w), isNotEmpty);
      expect(pl.scoredKind(w), GameKind.cual);

      final item = pl.scoredItem(w);
      expect(item, isA<CualItem>());
      expect((item as CualItem).asset, asset);

      sc.s.queue = [QueueEntry.scored(item)];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();

      expect(find.byType(PictureChoice), findsNWidgets(2));
      expect(find.byType(BookImage), findsNWidgets(2));
      expect(
        requestedUrls,
        containsAll([
          'libros/word_assets/puerta.png?v=39',
          'libros/word_assets/ventana.png?v=39',
        ]),
      );
      expect(requestedUrls.every((u) => u.contains('word_assets/')), isTrue);
    },
  );

  testWidgets(
    'defensive guards skip invalid/null/unpicturable CualItem and img/... WhereItem without stalling or mutating Ear progress, and strip HearItem/BuildItem reveal screenshots',
    (t) async {
      final w = realRepaso.word('puerta')!;
      final pair = RepasoTestCourse().pairFor('puerta')!;
      final line = w.pairLines.first;

      for (final badAsset in [
        null,
        const WordPictureAsset(
          word: 'puerta',
          yesAsset: 'word_assets/puerta.png',
          noAsset: 'word_assets/ventana.png',
          picturable: false,
        ),
        const WordPictureAsset(
          word: 'puerta',
          yesAsset: 'img/la-lluvia-1.png',
          noAsset: 'img/la-lluvia-2.png',
        ),
      ]) {
        final sc = Screen(t, pictures: _ForbidPictures());
        await sc.open();
        final earBefore = sc.store.word('puerta')!.ear.n;
        sc.s.queue = [
          QueueEntry.scored(
            CualItem(
              word: 'puerta',
              pair: pair,
              line: line,
              rightPanel: 0,
              asset: badAsset,
            ),
          ),
        ];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
        await sc.settle();
        expect(sc.s.screen, LessonScreen.end);
        expect(sc.s.played.where((q) => q.again), isEmpty);
        expect(sc.s.answers, isEmpty);
        expect(sc.s.barMarks, [DashMark.skipped]);
        expect(sc.store.calls.where((c) => c['op'] == 'responde'), isEmpty);
        expect(sc.store.word('puerta')!.ear.n, earBefore);
        expect(find.byType(PictureChoice), findsNothing);
        expect(find.byType(BookImage), findsNothing);
      }

      // WhereItem with img/... story screenshots skips cleanly with zero pictures and never stalls
      final whereSentence = realRepaso.sentences.firstWhere(
        (s) => s.picture != null && s.picture!.startsWith('img/'),
      );
      {
        final sc = Screen(t, pictures: _ForbidPictures());
        await sc.open();
        sc.s.queue = [
          QueueEntry.play(
            WhereItem(
              word: 'puerta',
              sentence: whereSentence,
              pictures: [whereSentence.picture!, 'img/la-lluvia-2.png'],
              answer: 0,
            ),
          ),
        ];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
        await sc.settle();
        expect(sc.s.screen, LessonScreen.end);
        expect(find.byType(PictureChoice), findsNothing);
        expect(find.byType(BookImage), findsNothing);
      }

      // HearItem and BuildItem reveals show text with zero BookImage even when sentence.picture is non-null
      final picSentence = realRepaso.sentences.firstWhere(
        (s) => s.picture != null && s.forHearing && s.forBuilding,
      );
      final targetWord = realRepaso.words.firstWhere(
        (x) => picSentence.tokens.contains(x.word) && x.sentences.isNotEmpty,
      );
      {
        final sc = Screen(t, pictures: _ForbidPictures());
        await sc.open();
        final hear = sc.s.planner.hearItem(targetWord, picSentence);
        sc.s.queue = [QueueEntry.scored(hear)];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await t.tap(find.byType(WordTile).at(hear.answer));
        await sc.vt.runUntil(() => sc.s.canNext);
        await sc.settle();
        expect(
          find.textContaining(picSentence.text, findRichText: true),
          findsOneWidget,
        );
        expect(find.byType(BookImage), findsNothing);
        sc.s.leave();
        await sc.vt.runUntil(() => false, limit: 5);
      }
      {
        final sc = Screen(t, pictures: _ForbidPictures());
        await sc.open();
        final build = BuildItem(
          word: targetWord.word,
          sentence: picSentence,
          order: picSentence.tokens,
          pool: [...picSentence.tokens.reversed],
        );
        sc.s.queue = [QueueEntry.play(build)];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        for (final w in build.order) {
          final k = sc.s.choices.indexWhere((c) => !c.done && c.label == w);
          final tile = find
              .descendant(
                of: find.byType(TileTray).last,
                matching: find.byType(WordTile),
              )
              .at(k);
          await t.ensureVisible(tile);
          await t.tap(tile);
          await sc.settle();
        }
        await sc.vt.runUntil(() => sc.s.canNext);
        await sc.settle();
        expect(
          find.textContaining(picSentence.text, findRichText: true),
          findsOneWidget,
        );
        expect(find.byType(BookImage), findsNothing);
      }
    },
  );

  test('boundary rule 9: lib/src/logic/word_picture.dart has no hardcoded Spanish strings', () {
    final src = File(
      '${repoRoot.path}/coqui/packages/features/feature_review/lib/src/logic/word_picture.dart',
    ).readAsStringSync();
    for (final literal in [
      "'sí'",
      '"sí"',
      "'no'",
      '"no"',
      "'puerta'",
      '"puerta"',
      "'casa'",
      '"casa"',
      "'hola'",
      '"hola"',
    ]) {
      expect(src, isNot(contains(literal)));
    }
  });

  test('thin course without two fair distractors degrades gracefully (servable=false, no crash) and stored nextKind=3 wraps safely', () {
    final thinData = RepasoData(
      sentences: const [],
      words: [
        RepasoWord(
          word: 'uno',
          place: 'casa',
          scoring: RepasoScoring.cual,
          solo: 'clip_uno',
          apart: const ['dos'],
          pairLines: [RepasoPairLine(clip: 'clip_uno', text: 'Uno.')],
        ),
        RepasoWord(
          word: 'dos',
          place: 'casa',
          scoring: RepasoScoring.cual,
          solo: 'clip_dos',
          apart: const ['uno'],
          pairLines: [RepasoPairLine(clip: 'clip_dos', text: 'Dos.')],
        ),
      ],
    );
    final thinPairs = [
      ReviewPair(
        word: 'uno',
        say: 'clip_uno',
        scene: 'frente',
        yes: PictureSpec(cam: const [0, 0, 10, 10]),
        no: PictureSpec(cam: const [1, 1, 10, 10]),
      ),
      ReviewPair(
        word: 'dos',
        say: 'clip_dos',
        scene: 'frente',
        yes: PictureSpec(cam: const [0, 0, 10, 10]),
        no: PictureSpec(cam: const [1, 1, 10, 10]),
      ),
    ];
    final db = jsonDecode(seedJson('vacio')) as Map<String, dynamic>;
    (db['palabras'] as Map)['uno'] = {
      'w': 'uno',
      'ear': {'n': 0, 'bien': 0, 'fallos': 0, 'due': 1, 'ultima': 0},
      'mouth': {'n': 0, 'bien': 0, 'fallos': 0, 'due': 0, 'ultima': 0},
    };
    final p = FakeProgressStore(
      clock: FakeClock(curseNow),
      json: jsonEncode(db),
    );
    final pl = RepasoPlanner(
      data: thinData,
      progress: p,
      pairs: thinPairs,
      rng: Mulberry32(1),
    );
    expect(pl.hearSentences(thinData.words.first), isEmpty);
    expect(pl.servable(thinData.words.first), isFalse);
    final ws = pl.sessionWords();
    expect(ws.words, isEmpty);
    expect(pl.queue(ws.words), isEmpty);

    // Pre-#10 storage may hold nextKind='3' (when playKinds had 4 entries including where).
    final kv = FakeKeyValueStore();
    kv.write(LastAsked.kindKey, '3');
    expect(LastAsked(kv).readKind(), 0);
    kv.write(LastAsked.kindKey, '5');
    expect(LastAsked(kv).readKind(), 2);
  });
}
