// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture tests for N2.7 (#90):
// feature_review uses course.language (recognitionLocale, normalize, tokens, RTL direction,
// script styling, and English menus).
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/support/scripted_clips.dart';
import '../tool/support/virtual_time.dart';
import 'support/recording_store.dart';
import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

const int _now = 1795312800001;

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic RepasoData built over
// FakeCourseCatalog.arabic() clip IDs and words.
RepasoData _arabicRepasoData() => RepasoData(
  sentences: [
    RepasoSentence(
      clip: 'esta_casa',
      story: 'la-lluvia',
      text: 'هذا بيت جدة.',
      tokens: ['هذا', 'بيت', 'جدة'],
      forbidden: ['بيت', 'جدة'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'puerta',
      story: 'la-lluvia',
      text: 'هذا باب.',
      tokens: ['هذا', 'باب'],
      forbidden: ['باب'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'ventana',
      story: 'la-lluvia',
      text: 'هذه نافذة.',
      tokens: ['هذه', 'نافذة'],
      forbidden: ['نافذة'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'hola_abuela',
      story: 'la-lluvia',
      text: 'مرحباً يا جدة!',
      tokens: ['مرحباً', 'يا', 'جدة'],
      forbidden: ['مرحباً', 'جدة'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'n_casa_grande',
      story: 'la-lluvia',
      text: 'هذا بيت كبير.',
      tokens: ['هذا', 'بيت', 'كبير'],
      forbidden: ['بيت', 'كبير'],
      picture: null,
      forHearing: true,
      forBuilding: false,
    ),
    RepasoSentence(
      clip: 'es_pequena',
      story: 'la-lluvia',
      text: 'هو صغير.',
      tokens: ['هو', 'صغير'],
      forbidden: ['صغير'],
      picture: null,
      forHearing: true,
      forBuilding: false,
    ),
  ],
  words: [
    RepasoWord(
      word: 'بيت',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'esta_casa',
      sentences: [0],
      say: [
        RepasoSay(
          clip: 'esta_casa',
          story: 'la-lluvia',
          text: 'هذا بيت جدة.',
          forms: ['هذا بيت جدة'],
          before: 'mira_casa',
        ),
      ],
    ),
    RepasoWord(
      word: 'باب',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'puerta',
      sentences: [1],
      say: [
        RepasoSay(
          clip: 'puerta',
          story: 'la-lluvia',
          text: 'هذا باب.',
          forms: ['هذا باب'],
          before: 'esta_puerta',
        ),
      ],
    ),
    RepasoWord(
      word: 'نافذة',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'ventana',
      sentences: [2],
    ),
    RepasoWord(
      word: 'مرحباً',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'hola_abuela',
      sentences: [3],
      say: [
        RepasoSay(
          clip: 'hola_abuela',
          story: 'la-lluvia',
          text: 'مرحباً يا جدة!',
          forms: ['مرحباً يا جدة'],
          before: 'es_abuela',
        ),
      ],
    ),
    RepasoWord(
      word: 'كبير',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'n_casa_grande',
      sentences: [4],
    ),
    RepasoWord(
      word: 'صغير',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'es_pequena',
      sentences: [5],
    ),
  ],
);

String _arabicProgressJson(Iterable<String> words, {int now = _now}) {
  Map<String, dynamic> skill(int n) => {
    'etapa': 3,
    'paso': 1,
    'seguidas': 0,
    'fallos': 0,
    'gap': 1,
    'due': now - 1000,
    'aciertos': <int>[],
    'ultima': 0,
    'aparcada': 0,
    'marca': 0,
    'n': n,
    'bien': n,
  };
  return jsonEncode({
    'palabras': {
      for (final w in words)
        w: {
          'w': w,
          'primera': now - 86400000,
          'oida': 1,
          'ear': skill(1),
          'mouth': {...skill(0), 'etapa': 0, 'due': 0},
        },
    },
    'dias': {},
    'cuentos': {
      'la-lluvia': {'n': 1, 'primera': now - 86400000},
    },
    'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
    'minutos': 0,
    'v': 1,
  });
}

void main() {
  group('Arabic word rules (course.language)', () {
    test('foldedTokens keeps Arabic words and folds diacritics and alef', () {
      expect(foldedTokens('مرحباً يا جدة!', language: arabicTestLanguage), [
        'مرحبا',
        'يا',
        'جدة',
      ]);
      expect(
        foldedTokens('جدة أغلق باب البيت.', language: arabicTestLanguage),
        ['جدة', 'اغلق', 'باب', 'البيت'],
      );
    });

    test(
      'findWord locates Arabic words verbatim and across diacritics/alef',
      () {
        const sentence = 'تقول جدة: مرحباً! كيف حالك؟';
        final exact = findWord(
          sentence,
          'مرحباً',
          language: arabicTestLanguage,
        );
        expect(exact, isNotNull);
        expect(sentence.substring(exact!.start, exact.end), 'مرحباً');

        // Matches without tanween via Arabic normalization
        final folded = findWord(
          sentence,
          'مرحبا',
          language: arabicTestLanguage,
        );
        expect(folded, isNotNull);
        expect(sentence.substring(folded!.start, folded.end), 'مرحباً');

        // Alef variant folding
        const alefSentence = 'جدة أغلق باب البيت.';
        final alef = findWord(
          alefSentence,
          'اغلق',
          language: arabicTestLanguage,
        );
        expect(alef, isNotNull);
        expect(alefSentence.substring(alef!.start, alef.end), 'أغلق');

        // Multi-word Arabic phrase
        final phrase = findWord(
          alefSentence,
          'باب البيت',
          language: arabicTestLanguage,
        );
        expect(phrase, isNotNull);
        expect(alefSentence.substring(phrase!.start, phrase.end), 'باب البيت');
      },
    );

    test(
      'RepasoPlanner.tileForm strips punctuation while keeping Arabic letters',
      () {
        expect(
          RepasoPlanner.tileForm('مرحباً!', language: arabicTestLanguage),
          'مرحباً',
        );
        expect(
          RepasoPlanner.tileForm('بيت كبير؟', language: arabicTestLanguage),
          'بيت كبير',
        );
      },
    );

    test(
      'repasoHeardRight normalises Arabic alternatives via course.language',
      () {
        expect(
          repasoHeardRight(
            ['مرحبا يا جدة'],
            ['مرحباً يا جدة'],
            language: arabicTestLanguage,
          ),
          isTrue,
        );
        expect(
          repasoHeardRight(
            ['جدة اغلق باب البيت'],
            ['أغلق باب البيت'],
            language: arabicTestLanguage,
          ),
          isTrue,
        );
        expect(
          repasoHeardRight(
            ['هذا بيت كبير'],
            ['هذا باب'],
            language: arabicTestLanguage,
          ),
          isFalse,
        );
      },
    );
  });

  group(
    'Spanish parity (course.language vs RepasoServing and legacy rules)',
    () {
      test('foldedTokens matches repasoTokens on every realRepaso word, sentence, and punctuation edge case', () {
        for (final w in realRepaso.words) {
          expect(
            foldedTokens(w.word, language: Language.spanish),
            repasoTokens(w.word),
            reason: w.word,
          );
        }
        for (final s in realRepaso.sentences) {
          expect(
            foldedTokens(s.text, language: Language.spanish),
            repasoTokens(s.text),
            reason: s.clip,
          );
        }
        for (final sample in const [
          '¡Hola, Abuela!',
          '¿Cómo estás? —Bien, ¡gracias!',
          "d'agua auto-bus 123 niño pingüino",
          'el bebé bebe café',
          '   ',
        ]) {
          expect(
            foldedTokens(sample, language: Language.spanish),
            repasoTokens(sample),
            reason: sample,
          );
        }
      });

      test('tileForm matches legacy Spanish lower-case strip rule on every realRepaso word and edge cases', () {
        const allowed = '0123456789abcdefghijklmnopqrstuvwxyzáéíóúüñ ';
        String legacyTileForm(String w) {
          final out = StringBuffer();
          for (final ch in w.toLowerCase().split('')) {
            if (allowed.contains(ch)) out.write(ch);
          }
          return out.toString().trim();
        }

        for (final w in realRepaso.words) {
          expect(
            RepasoPlanner.tileForm(w.word, language: Language.spanish),
            legacyTileForm(w.word),
            reason: w.word,
          );
        }
        for (final (input, expected) in const [
          ('¡Hola!', 'hola'),
          ('¿Qué?', 'qué'),
          ('adiós', 'adiós'),
          ('no hay', 'no hay'),
          ('pingüino 2', 'pingüino 2'),
          ('¡Sí!', 'sí'),
        ]) {
          expect(
            RepasoPlanner.tileForm(input, language: Language.spanish),
            expected,
            reason: input,
          );
          expect(legacyTileForm(input), expected, reason: input);
        }
      });

      test('wrongTileChoices and wrongTileChoicesForLanguage agree 100% with RepasoServing across realRepaso', () {
        final course = RepasoTestCourse();
        final progress = FakeProgressStore(
          clock: FakeClock(curseNow),
          json: everythingJson(realRepaso),
        );
        final serving = repasoServing(course, progress)!;
        final planner = RepasoPlanner(
          data: realRepaso,
          progress: progress,
          pairs: course.pairs,
          rng: Mulberry32(7),
          language: Language.spanish,
        );
        var checked = 0;
        for (final w in realRepaso.words) {
          for (final k in w.sentences) {
            final s = realRepaso.sentences[k];
            if (!s.forHearing && !s.forBuilding) continue;
            checked++;
            for (final singleWords in const [false, true]) {
              final expected = [
                for (final m in serving.wrongTileChoices(
                  w,
                  s,
                  singleWords: singleWords,
                ))
                  m.word,
              ];
              expect(
                [
                  for (final m in planner.wrongTileChoices(
                    w,
                    s,
                    singleWords: singleWords,
                  ))
                    m.word,
                ],
                expected,
                reason: '${w.word}/${s.clip}/single=$singleWords (delegated)',
              );
              expect(
                [
                  for (final m in planner.wrongTileChoicesForLanguage(
                    w,
                    s,
                    singleWords: singleWords,
                  ))
                    m.word,
                ],
                expected,
                reason: '${w.word}/${s.clip}/single=$singleWords (language)',
              );
            }
          }
        }
        expect(checked, greaterThan(1400));
      });
    },
  );

  group('Arabic RepasoSession (logic)', () {
    test('plans Arabic Hear/Build/Match/Say items and uses ar-SA recognitionLocale in Dilo', () async {
      final data = _arabicRepasoData();
      final course = FakeCourseCatalog.arabic(repaso: data);
      await course.load();
      final vt = VirtualTime();
      final store = RecordingStore(
        vt,
        clock: FakeClock(_now),
        json: _arabicProgressJson([for (final w in data.words) w.word]),
      );
      final clips = ScriptedClips(vt);
      final speech = FakeSpeechListener(
        // Without tanween to verify Arabic normalization in repasoHeardRight
        results: ['مرحبا يا جدة'],
        isAvailable: true,
        instant: true,
      );
      final session = RepasoSession(
        data: data,
        rng: FakeRng(3),
        clock: vt,
        course: course,
        progress: store,
        clips: clips,
        wait: vt.wait,
        speech: speech,
      );
      session.prepare();

      // Single-word Arabic wrong tiles must work for Arma la frase (BuildItem)
      final buildExtras = session.planner.wrongTiles(
        data.words[0],
        data.sentences[0],
        singleWords: true,
      );
      expect(buildExtras, isNotNull);
      expect(buildExtras, hasLength(2));
      for (final extra in buildExtras!) {
        expect(
          foldedTokens(extra.word, language: arabicTestLanguage),
          hasLength(1),
        );
        expect(['بيت', 'جدة'], isNot(contains(extra.word)));
      }

      // Play a Dilo item and verify recognitionLocale comes from arabicTestLanguage
      final sayWord = data.words[3]; // مرحباً
      session.queue = [
        QueueEntry.play(SayItem(word: sayWord.word, line: sayWord.say.first)),
      ];
      final run = session.run();
      await vt.runUntil(() => session.mic == MicState.ready);
      session.pressMic();
      await vt.runUntil(() => session.heardRight && session.canNext);
      expect(speech.listens, hasLength(1));
      expect(
        speech.listens.single.locale,
        arabicTestLanguage.recognitionLocale,
      );
      expect(session.heardRight, isTrue);
      session.pressNext();
      await vt.runUntil(() => session.screen == LessonScreen.end);
      await run;
      final mouthCalls = store.calls.where(
        (c) => c['op'] == 'responde' && (c['args'] as List)[1] == 'mouth',
      );
      expect(mouthCalls, hasLength(1));
      expect((mouthCalls.single['args'] as List).sublist(0, 3), [
        'مرحباً',
        'mouth',
        true,
      ]);
    });
  });

  group('Arabic RepasoScreen (RTL cards, English menus, full flow)', () {
    for (final (label, w, h, dpr) in [
      ('390x844', 390.0, 844.0, 3.0),
      ('412x915', 412.0, 915.0, 2.625),
    ]) {
      testWidgets(
        'runs Hear, Build, Match, Dilo, and End on Arabic course at $label with RTL cards and English menus',
        (t) async {
          t.view.devicePixelRatio = dpr;
          t.view.physicalSize = Size(w * dpr, h * dpr);
          addTearDown(t.view.reset);
          t.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);

          final data = _arabicRepasoData();
          final course = FakeCourseCatalog.arabic(repaso: data);
          await course.load();
          final vt = VirtualTime(settler: t.idle);
          final store = RecordingStore(
            vt,
            clock: FakeClock(_now),
            json: _arabicProgressJson([for (final wd in data.words) wd.word]),
          );
          final clips = ScriptedClips(vt);
          final speech = FakeSpeechListener(
            results: ['مرحبا يا جدة'],
            isAvailable: true,
            instant: true,
          );
          final nav = FakeNavigator();
          final services = fakeServices(
            progress: store,
            course: course,
            clips: clips,
            clock: vt,
            rng: FakeRng(3),
            nav: nav,
            speech: speech,
            reduceMotion: true,
          );
          final key = GlobalKey<RepasoScreenState>();

          await t.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: RepasoScreen(
                key: key,
                services: services,
                data: data,
                wait: vt.wait,
                imageProvider: (_) => dotPicture,
              ),
            ),
          );
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);

          // Start screen: English hint stays English
          expect(find.text(RepasoStrings.startHint), findsOneWidget);

          // Build a deterministic queue covering Hear, Build, Match, and Dilo
          final session = key.currentState!.session;
          final hearItem = session.planner.hearItem(
            data.words[0],
            data.sentences[0],
          );
          final buildItem = BuildItem(
            word: data.words[0].word,
            sentence: data.sentences[0],
            order: data.sentences[0].tokens,
            pool: ['جدة', 'بيت', 'هذا', 'باب', 'نافذة'],
          );
          final matchItem = MatchItem(
            words: [
              data.words[0].word,
              data.words[1].word,
              data.words[2].word,
              data.words[5].word,
            ],
            sentences: [
              data.sentences[0],
              data.sentences[1],
              data.sentences[2],
              data.sentences[5],
            ],
            wordOrder: [1, 2, 3, 0],
          );
          final sayItem = SayItem(
            word: data.words[3].word,
            line: data.words[3].say.first,
          );
          session.queue = [
            QueueEntry.scored(hearItem),
            QueueEntry.play(buildItem),
            QueueEntry.play(matchItem),
            QueueEntry.play(sayItem),
          ];

          await t.tap(find.byType(LessonStartButton));
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));

          // 1) ¿Qué oyes? (HearItem)
          await vt.runUntil(() => session.yourTurn && session.item is HearItem);
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);
          // English instruction stays English LTR
          final hearInstr = find.text(gameInstruction(GameKind.hear));
          expect(hearInstr, findsOneWidget);
          expect(Directionality.of(t.element(hearInstr)), TextDirection.ltr);
          // Arabic WordTiles follow RTL direction and ar locale
          final hearTile = find.byType(WordTile).first;
          expect(Directionality.of(t.element(hearTile)), TextDirection.rtl);
          expect(t.widget<WordTile>(hearTile).language, arabicTestLanguage);
          final answerIdx = session.choices.indexWhere((c) => c.right);
          await t.tap(find.byType(WordTile).at(answerIdx));
          await vt.runUntil(() => session.canNext);
          await t.pump(const Duration(milliseconds: 50));
          // Reveal sentence is RTL with Locale('ar')
          final revealText = t.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('reveal')),
              matching: find.byType(Text),
            ),
          );
          expect(revealText.textDirection, TextDirection.rtl);
          expect(revealText.locale, const Locale('ar'));
          await t.tap(find.text(RepasoStrings.next));
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));

          // 2) Arma la frase (BuildItem)
          await vt.runUntil(
            () => session.yourTurn && session.item is BuildItem,
          );
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);
          expect(
            Directionality.of(
              t.element(find.text(gameInstruction(GameKind.build))),
            ),
            TextDirection.ltr,
          );
          final answerLineFinder = find.byKey(const ValueKey('answer-line'));
          expect(
            Directionality.of(t.element(answerLineFinder)),
            TextDirection.rtl,
          );
          for (final token in buildItem.order) {
            final k = session.choices.indexWhere(
              (c) => !c.done && c.label == token,
            );
            final tile = find
                .descendant(
                  of: find.byType(TileTray).last,
                  matching: find.byType(WordTile),
                )
                .at(k);
            await t.ensureVisible(tile);
            await t.tap(tile);
            await vt.settle();
            await t.pump(const Duration(milliseconds: 50));
          }
          // In RTL, the first placed Arabic word sits to the right of the second
          final placedTiles = find.descendant(
            of: answerLineFinder,
            matching: find.byType(WordTile),
          );
          expect(placedTiles, findsNWidgets(buildItem.order.length));
          expect(
            t.getRect(placedTiles.at(0)).left,
            greaterThan(t.getRect(placedTiles.at(1)).left),
            reason: 'RTL answer line places first word to the right of second',
          );
          await vt.runUntil(() => session.canNext);
          await t.pump(const Duration(milliseconds: 50));
          await t.tap(find.text(RepasoStrings.next));
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));

          // 3) Parejas (MatchItem)
          await vt.runUntil(
            () => session.yourTurn && session.item is MatchItem,
          );
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);
          expect(
            Directionality.of(
              t.element(find.text(gameInstruction(GameKind.match))),
            ),
            TextDirection.ltr,
          );
          // RTL Parejas row: speaker at start (right), word tile at end (left)
          final firstSpeaker = find.byType(SpeakerTile).first;
          final firstWord = find.byType(WordTile).first;
          expect(Directionality.of(t.element(firstWord)), TextDirection.rtl);
          expect(
            t.getRect(firstSpeaker).left,
            greaterThan(t.getRect(firstWord).left),
            reason: 'RTL Parejas places speaker at start (right) of word tile',
          );
          for (var i = 0; i < 4; i++) {
            await t.ensureVisible(find.byType(SpeakerTile).at(i));
            await t.tap(find.byType(SpeakerTile).at(i));
            await vt.settle();
            await t.pump(const Duration(milliseconds: 50));
            final wordTile = find
                .byType(WordTile)
                .at(matchItem.wordOrder.indexOf(i));
            await t.ensureVisible(wordTile);
            await t.tap(wordTile);
            await vt.settle();
            await t.pump(const Duration(milliseconds: 50));
          }
          await vt.runUntil(() => session.canNext);
          await t.pump(const Duration(milliseconds: 50));
          await t.tap(find.text(RepasoStrings.next));
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));

          // 4) Dilo (SayItem)
          await vt.runUntil(
            () => session.mic == MicState.ready && session.item is SayItem,
          );
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);
          // English label stays English LTR
          expect(
            Directionality.of(
              t.element(find.text(RepasoStrings.sayTargetWord)),
            ),
            TextDirection.ltr,
          );
          // Target word pill and sentence are RTL with Locale('ar')
          final pillText = t.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('say-target-word')),
              matching: find.text('مرحباً'),
            ),
          );
          expect(pillText.textDirection, TextDirection.rtl);
          expect(pillText.locale, const Locale('ar'));
          final saySentence = t.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('say-sentence')),
              matching: find.byType(Text),
            ),
          );
          expect(saySentence.textDirection, TextDirection.rtl);
          expect(saySentence.locale, const Locale('ar'));
          await t.ensureVisible(find.byType(RepasoMic));
          await t.tap(find.byType(RepasoMic));
          await vt.runUntil(() => session.heardRight && session.canNext);
          await t.pump(const Duration(milliseconds: 50));
          expect(speech.listens.single.locale, 'ar-SA');
          await t.tap(find.text(RepasoStrings.next));
          await vt.runUntil(() => session.screen == LessonScreen.end);
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull);

          // 5) End screen: English headings LTR, Arabic row RTL, course tab name on Back button
          expect(
            Directionality.of(t.element(find.text(RepasoStrings.doneTitle))),
            TextDirection.ltr,
          );
          final endWord = find.text(hearItem.word);
          expect(endWord, findsOneWidget);
          expect(Directionality.of(t.element(endWord)), TextDirection.rtl);
          expect(t.widget<Text>(endWord).locale, const Locale('ar'));
          expect(
            find.text('Back to ${arabicTestLanguage.tabNames['words']}'),
            findsOneWidget,
          );
        },
      );
    }
  });

  group('Arabic classic ReviewScreen and LevelCheckScreen', () {
    testWidgets(
      'ReviewScreen runs on FakeCourseCatalog.arabic() with RTL captions, RTL end grid, LTR pixel pictures, and English menus',
      (t) async {
        t.view.devicePixelRatio = 3;
        t.view.physicalSize = const Size(390 * 3, 844 * 3);
        addTearDown(t.view.reset);

        final course = FakeCourseCatalog.arabic();
        await course.load();
        final vt = VirtualTime(settler: t.idle);
        final dueWords = [for (final p in course.pairs.take(2)) p.word];
        final store = RecordingStore(
          vt,
          clock: FakeClock(_now),
          json: _arabicProgressJson(dueWords),
        );
        final clips = ScriptedClips(vt);
        final nav = FakeNavigator();
        final services = fakeServices(
          progress: store,
          course: course,
          clips: clips,
          clock: vt,
          rng: FakeRng(1),
          nav: nav,
          reduceMotion: true,
        );
        final key = GlobalKey<ReviewScreenState>();

        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: ReviewScreen(key: key, services: services, wait: vt.wait),
          ),
        );
        await vt.settle();
        await t.pump(const Duration(milliseconds: 50));
        expect(t.takeException(), isNull);
        expect(find.text(ReviewStrings.startHint), findsOneWidget);

        await t.tap(find.byType(LessonStartButton));
        await vt.settle();
        await t.pump(const Duration(milliseconds: 50));

        final session = key.currentState!.session;
        var sawArabicCaption = false;
        var acted = -1;
        for (
          var step = 0;
          step < 2000 && session.screen != LessonScreen.end;
          step++
        ) {
          if (!sawArabicCaption && session.caption.isNotEmpty) {
            await t.pump(const Duration(milliseconds: 50));
            final capFinder = find.text(session.caption);
            if (capFinder.evaluate().isNotEmpty) {
              final capWidget = t.widget<Text>(capFinder);
              expect(capWidget.textDirection, TextDirection.rtl);
              expect(capWidget.locale, const Locale('ar'));
              sawArabicCaption = true;
            }
          }
          if (session.panels != null &&
              session.ready &&
              acted != session.index) {
            acted = session.index;
            await t.pump(const Duration(milliseconds: 50));
            expect(t.takeException(), isNull);
            final right = session.panels!.indexWhere((p) => p.right);
            final pic = find.byType(PictureChoice).at(right);
            final g = await t.startGesture(t.getCenter(pic));
            await g.up();
            await vt.settle();
            await t.pump(const Duration(milliseconds: 50));
          } else {
            if (!vt.fireNext()) break;
            await vt.settle();
          }
        }
        await t.pump(const Duration(milliseconds: 50));
        expect(t.takeException(), isNull);
        expect(session.screen, LessonScreen.end);
        expect(sawArabicCaption, isTrue);

        // End screen: English headings LTR, Arabic word cells flow RTL, pictures stay LTR
        expect(
          Directionality.of(t.element(find.text(ReviewStrings.doneTitle))),
          TextDirection.ltr,
        );
        final firstCellText = find.text(dueWords[0]);
        final secondCellText = find.text(dueWords[1]);
        expect(firstCellText, findsOneWidget);
        expect(secondCellText, findsOneWidget);
        expect(Directionality.of(t.element(firstCellText)), TextDirection.rtl);
        expect(t.widget<Text>(firstCellText).locale, const Locale('ar'));
        expect(
          t.getRect(firstCellText).left,
          greaterThan(t.getRect(secondCellText).left),
          reason:
              'RTL end grid lays first Arabic word cell to the right of second',
        );
        expect(
          find.text('Back to ${arabicTestLanguage.tabNames['words']}'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'LevelCheckScreen runs on FakeCourseCatalog.arabic() with RTL caption and English chrome',
      (t) async {
        t.view.devicePixelRatio = 3;
        t.view.physicalSize = const Size(390 * 3, 844 * 3);
        addTearDown(t.view.reset);

        final baseCourse = FakeCourseCatalog.arabic();
        await baseCourse.load();
        final course = _ArabicLevelCourse(baseCourse);
        final vt = VirtualTime(settler: t.idle);
        final store = RecordingStore(
          vt,
          clock: FakeClock(_now),
          json: _arabicProgressJson(const []),
        );
        final clips = ScriptedClips(vt);
        final nav = FakeNavigator();
        final services = fakeServices(
          progress: store,
          course: course,
          clips: clips,
          clock: vt,
          rng: FakeRng(1),
          nav: nav,
          reduceMotion: true,
        );
        final key = GlobalKey<LevelCheckScreenState>();

        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: LevelCheckScreen(key: key, services: services, wait: vt.wait),
          ),
        );
        await vt.settle();
        await t.pump(const Duration(milliseconds: 50));
        expect(t.takeException(), isNull);
        expect(find.text(ReviewStrings.levelTitle), findsOneWidget);

        await t.tap(find.byType(LessonStartButton));
        await vt.settle();
        await t.pump(const Duration(milliseconds: 50));

        final session = key.currentState!.session;
        var sawArabicCaption = false;
        var acted = -1;
        for (
          var step = 0;
          step < 4000 && session.screen != LessonScreen.end;
          step++
        ) {
          if (!sawArabicCaption && session.caption.isNotEmpty) {
            await t.pump(const Duration(milliseconds: 50));
            final capFinder = find.text(session.caption);
            if (capFinder.evaluate().isNotEmpty) {
              final capWidget = t.widget<Text>(capFinder);
              expect(capWidget.textDirection, TextDirection.rtl);
              expect(capWidget.locale, const Locale('ar'));
              sawArabicCaption = true;
            }
          }
          if (session.panels != null &&
              session.ready &&
              acted != session.index) {
            acted = session.index;
            await t.pump(const Duration(milliseconds: 50));
            expect(t.takeException(), isNull);
            final right = session.panels!.indexWhere((p) => p.right);
            final pic = find.byType(PictureChoice).at(right);
            final g = await t.startGesture(t.getCenter(pic));
            await g.up();
            await vt.settle();
            await t.pump(const Duration(milliseconds: 50));
          } else {
            if (!vt.fireNext()) break;
            await vt.settle();
          }
        }
        await t.pump(const Duration(milliseconds: 50));
        expect(t.takeException(), isNull);
        expect(session.screen, LessonScreen.end);
        expect(sawArabicCaption, isTrue);
        expect(find.text(ReviewStrings.levelDoneTitle), findsOneWidget);
        expect(find.text(ReviewStrings.toTheMap), findsOneWidget);
      },
    );
  });
}

/// Delegates to [FakeCourseCatalog.arabic] while ensuring [levelItems] only
/// reference pairs present in the 1-place sample course.
class _ArabicLevelCourse implements CourseCatalog, LanguageCatalog {
  _ArabicLevelCourse(this._base) : _levelItems = _validItems(_base);

  static List<LevelItem> _validItems(FakeCourseCatalog base) {
    final valid = [
      for (final q in base.levelItems)
        if (q.pictures.every((p) => base.pairs.any((x) => x.word == p[0]))) q,
    ];
    if (valid.isNotEmpty) return valid;
    final ps = base.pairs;
    return [
      for (var i = 0; i < 2; i++)
        LevelItem(
          word: ps[i].word,
          step: i + 1,
          pictures: [
            for (var k = 0; k < 4; k++)
              [ps[(i + k) % ps.length].word, ps[(i + k) % ps.length].yes],
          ],
        ),
    ];
  }

  final FakeCourseCatalog _base;
  final List<LevelItem> _levelItems;

  @override
  Language get language => _base.language;
  @override
  Future<void> load() => _base.load();
  @override
  List<Place> get places => _base.places;
  @override
  StoryMeta? meta(String id) => _base.meta(id);
  @override
  Future<Map<String, dynamic>> story(String id) => _base.story(id);
  @override
  Future<Book?> book(String id) => _base.book(id);
  @override
  List<ReviewPair> get pairs => _base.pairs;
  @override
  ReviewPair? pairFor(String word) => _base.pairFor(word);
  @override
  List<LevelItem> get levelItems => _levelItems;
  @override
  CallBrief? callFor(String placeId) => _base.callFor(placeId);
  @override
  ClipInfo? clip(String id) => _base.clip(id);
  @override
  String fixedClip(String role) => _base.fixedClip(role);
  @override
  List<String> get goodbyeWords => _base.goodbyeWords;
  @override
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  }) => _base.linesWith(word, storyIds, max: max);
}
