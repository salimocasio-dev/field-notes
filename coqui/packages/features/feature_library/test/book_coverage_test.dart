import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/book_coverage.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

WordRecord _earRecord(String word, int stage) => WordRecord(
  w: word,
  primera: 0,
  ear: SkillRecord(etapa: stage),
);

Language _arabicLanguage() => Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Karim',
  callAgentId: 'agent_test_ar',
  micWords: const {
    'ready': 'تحدث',
    'listening': 'أستمع',
    'thinking': 'لحظة',
    'theySpeak': 'استمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تحدث',
    'me': 'أنا',
  },
);

Language _cyrillicLanguage() => Language(
  code: 'ru',
  englishName: 'Russian',
  nativeName: 'Русский',
  recognitionLocale: 'ru-RU',
  direction: LanguageDirection.ltr,
  script: 'Cyrl',
  partnerName: 'Ivan',
  callAgentId: 'agent_test_ru',
  micWords: const {
    'ready': 'Говори',
    'listening': 'Слушаю',
    'thinking': 'Минуту',
    'theySpeak': 'Слушай',
    'right': 'Отлично',
    'notYet': 'Ещё раз',
  },
  tabNames: const {
    'library': 'Библиотека',
    'words': 'Слова',
    'map': 'Карта',
    'speak': 'Говорить',
    'me': 'Я',
  },
);

ReaderDocument _docFromChapters(List<List<String>> chapters) => ReaderDocument(
  id: 'doc-1',
  title: 'Test Book',
  hasAudio: false,
  chapters: [
    for (var c = 0; c < chapters.length; c++)
      ReaderChapterDoc(
        title: 'Chapter ${c + 1}',
        paragraphs: [
          for (var p = 0; p < chapters[c].length; p++)
            ReaderParagraph([
              ReaderSentence(id: 'c${c}_p$p', text: chapters[c][p]),
            ]),
        ],
      ),
  ],
);

Widget _wrapSummary(
  BookCoverage value, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BookCoverageSummary(coverage: value),
      ),
    ),
  ),
);

void main() {
  group('coverage calculation', () {
    test('counts running words across stages 1-4, multi-chapters, and normalizes accents/case', () {
      // 71 heard running words (stage 1..4) and 29 unheard (stage 0 or missing) = 100 total.
      final chapter1Line = List.filled(20, 'casa').join(' '); // stage 1
      final chapter2Line1 = [
        ...List.filled(15, 'Árbol'), // stage 2 (stored as 'árbol')
        ...List.filled(16, 'NIÑO'), // stage 3 (stored as 'nino')
        ...List.filled(20, 'Agua'), // stage 4 (stored as 'agua')
      ].join(' ');
      final chapter2Line2 = [
        ...List.filled(10, 'perro'), // stage 0 -> not counted
        ...List.filled(19, 'desconocida'), // missing -> not counted
      ].join(' ');

      final doc = _docFromChapters([
        [chapter1Line],
        [chapter2Line1, chapter2Line2],
      ]);
      final records = [
        _earRecord('casa', 1),
        _earRecord('árbol', 2),
        _earRecord('nino', 3),
        _earRecord('agua', 4),
        _earRecord('perro', 0),
      ];

      final result = coverage(doc, records, Language.spanish);

      expect(result.heardWords, 71);
      expect(result.totalWords, 100);
      expect(result.percent, 71);
      expect(result.ratio, closeTo(0.71, 1e-9));
      expect(result.headline, "You've heard 71% of its words.");
      expect(result.phrase, coveragePhraseStretch);
    });

    test(
      'coverageOfText converts ReadingText via ReaderDocument.fromPersonal',
      () {
        const text = ReadingText(
          id: 'biblioteca-1',
          title: 'Mi libro',
          body: 'Casa casa árbol. Perro desconocido.',
          generated: false,
        );
        final records = [
          _earRecord('casa', 1),
          _earRecord('arbol', 2),
          _earRecord('perro', 0),
        ];

        final result = coverageOfText(text, records, Language.spanish);
        expect(result, const BookCoverage(heardWords: 3, totalWords: 5));
        expect(result.percent, 60);
      },
    );

    test('excludes numbers and other scripts from both numerator and denominator', () {
      final doc = _docFromChapters([
        ['Casa 1984 casa 42 3.14 ١٢٣ مرحبا привет 東京 árbol perro.'],
      ]);
      final records = [
        _earRecord('casa', 2),
        _earRecord('1984', 4),
        _earRecord('42', 4),
        _earRecord('مرحبا', 4),
        _earRecord('привет', 4),
        _earRecord('東京', 4),
        _earRecord('árbol', 1),
        _earRecord('perro', 0),
      ];

      final result = coverage(doc, records, Language.spanish);
      // Qualifying Spanish words: Casa, casa, árbol, perro (4 total; 3 heard).
      expect(result.heardWords, 3);
      expect(result.totalWords, 4);
      expect(result.percent, 75);
    });

    test('handles Arabic script normalization, tashkeel, alef variants, and exclusions', () {
      final arabic = _arabicLanguage();
      final doc = _docFromChapters([
        ['كِتَابُ إِسْلَام أَحْمَد آدَم اَلْبَيْت hola chapter 42 2026 ١٢٣.'],
      ]);
      final records = [
        _earRecord('كتاب', 1),
        _earRecord('اسلام', 2),
        _earRecord('احمد', 3),
        _earRecord('ادم', 4),
        _earRecord('hola', 4),
        _earRecord('42', 4),
      ];

      final result = coverage(doc, records, arabic);
      // Qualifying Arabic words: كِتَابُ, إِسْلَام, أَحْمَد, آدَم, اَلْبَيْت (5 total; 4 heard).
      expect(result.heardWords, 4);
      expect(result.totalWords, 5);
      expect(result.percent, 80);
    });

    test(
      'returns 0/0 and stretch phrase for empty or non-qualifying books',
      () {
        final emptyDoc = _docFromChapters([]);
        final emptyResult = coverage(emptyDoc, const [], Language.spanish);
        expect(emptyResult.heardWords, 0);
        expect(emptyResult.totalWords, 0);
        expect(emptyResult.percent, 0);
        expect(emptyResult.ratio, 0.0);
        expect(emptyResult.phrase, coveragePhraseStretch);

        final nonQualifyingDoc = _docFromChapters([
          ['1984 42 ٣٤٥ مرحبا привет 東京'],
        ]);
        final nonQualifyingResult = coverage(nonQualifyingDoc, [
          _earRecord('1984', 4),
          _earRecord('مرحبا', 4),
        ], Language.spanish);
        expect(
          nonQualifyingResult,
          const BookCoverage(heardWords: 0, totalWords: 0),
        );
        expect(nonQualifyingResult.percent, 0);
        expect(nonQualifyingResult.ratio, 0.0);
      },
    );

    test(
      'throws UnsupportedError for unsupported script even on empty book',
      () {
        final emptyDoc = _docFromChapters([]);
        expect(
          () => coverage(emptyDoc, const [], _cyrillicLanguage()),
          throwsUnsupportedError,
        );
      },
    );
  });

  group('BookCoverage value semantics and phrase boundaries', () {
    test('value equality, hashCode, and toString', () {
      const a = BookCoverage(heardWords: 71, totalWords: 100);
      const b = BookCoverage(heardWords: 71, totalWords: 100);
      const c = BookCoverage(heardWords: 72, totalWords: 100);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), 'BookCoverage(heardWords: 71, totalWords: 100)');
    });

    test('phrase boundaries use integer floor percent', () {
      expect(const BookCoverage(heardWords: 0, totalWords: 100).percent, 0);
      expect(
        const BookCoverage(heardWords: 0, totalWords: 100).phrase,
        coveragePhraseStretch,
      );

      expect(const BookCoverage(heardWords: 89, totalWords: 100).percent, 89);
      expect(
        const BookCoverage(heardWords: 89, totalWords: 100).phrase,
        coveragePhraseStretch,
      );

      expect(const BookCoverage(heardWords: 899, totalWords: 1000).percent, 89);
      expect(
        const BookCoverage(heardWords: 899, totalWords: 1000).phrase,
        coveragePhraseStretch,
      );

      expect(const BookCoverage(heardWords: 90, totalWords: 100).percent, 90);
      expect(
        const BookCoverage(heardWords: 90, totalWords: 100).phrase,
        coveragePhraseClose,
      );

      expect(const BookCoverage(heardWords: 97, totalWords: 100).percent, 97);
      expect(
        const BookCoverage(heardWords: 97, totalWords: 100).phrase,
        coveragePhraseClose,
      );

      expect(const BookCoverage(heardWords: 979, totalWords: 1000).percent, 97);
      expect(
        const BookCoverage(heardWords: 979, totalWords: 1000).phrase,
        coveragePhraseClose,
      );

      expect(const BookCoverage(heardWords: 98, totalWords: 100).percent, 98);
      expect(
        const BookCoverage(heardWords: 98, totalWords: 100).phrase,
        coveragePhraseEasy,
      );

      expect(const BookCoverage(heardWords: 100, totalWords: 100).percent, 100);
      expect(
        const BookCoverage(heardWords: 100, totalWords: 100).phrase,
        coveragePhraseEasy,
      );
    });
  });

  group('BookCoverageSummary widget', () {
    testWidgets('renders progress bar and exact text for <90%', (tester) async {
      const value = BookCoverage(heardWords: 71, totalWords: 100);
      await tester.pumpWidget(_wrapSummary(value));

      final bar = tester.widget<NocheProgressBar>(
        find.byType(NocheProgressBar),
      );
      expect(bar.value, closeTo(0.71, 1e-9));
      expect(bar.color, NocheColors.listening);
      expect(bar.semanticLabel, 'You know 71 percent of its words');

      expect(
        find.text(
          "You've heard 71% of its words. $coveragePhraseStretch",
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders close phrase for 90-97%', (tester) async {
      const value = BookCoverage(heardWords: 95, totalWords: 100);
      await tester.pumpWidget(_wrapSummary(value));

      final bar = tester.widget<NocheProgressBar>(
        find.byType(NocheProgressBar),
      );
      expect(bar.value, closeTo(0.95, 1e-9));
      expect(bar.color, NocheColors.listening);
      expect(
        find.text(
          "You've heard 95% of its words. $coveragePhraseClose",
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders easy phrase for >=98% and works in RTL', (
      tester,
    ) async {
      const value = BookCoverage(heardWords: 99, totalWords: 100);
      await tester.pumpWidget(
        _wrapSummary(value, direction: TextDirection.rtl),
      );

      final bar = tester.widget<NocheProgressBar>(
        find.byType(NocheProgressBar),
      );
      expect(bar.value, closeTo(0.99, 1e-9));
      expect(bar.color, NocheColors.listening);
      expect(
        find.text(
          "You've heard 99% of its words. $coveragePhraseEasy",
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
