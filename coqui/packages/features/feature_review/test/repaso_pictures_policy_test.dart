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

    // ya / listo only have cual in current repaso.json; without dedicated assets they are not servable as pictures
    for (final word in ['ya', 'listo']) {
      final w = realRepaso.word(word)!;
      final pl = RepasoPlanner(
        data: realRepaso,
        progress: p,
        pairs: RepasoTestCourse().pairs,
        rng: Mulberry32(1),
      );
      expect(pl.cualLines(w), isEmpty, reason: word);
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
      final yesImg = await wordAssetStandIn(t, color: const Color(0xFF2E7D32));
      final noImg = await wordAssetStandIn(t, color: const Color(0xFF1565C0));
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
    'defensive UI guards block invalid/null/unpicturable CualItem, img/... WhereItem, and HearItem/BuildItem reveal screenshots',
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
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        expect(find.byType(PictureChoice), findsNothing);
        expect(find.byType(BookImage), findsNothing);
        sc.s.leave();
        await sc.vt.runUntil(() => false, limit: 5);
      }

      // WhereItem with img/... story screenshots renders zero pictures
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
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        expect(find.byType(PictureChoice), findsNothing);
        expect(find.byType(BookImage), findsNothing);
        sc.s.leave();
        await sc.vt.runUntil(() => false, limit: 5);
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
}
