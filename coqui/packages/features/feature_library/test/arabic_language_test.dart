// Arabic / RTL language coverage and package-wide language-routing audit for
// feature_library (issue #54).
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reader_page.dart';
import 'package:feature_library/src/reader_pagination.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_audio.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:feature_library/src/text_reader.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show TimedClips, settle;

WordRecord _known(String word, {int stage = 4}) => WordRecord(
  w: word,
  primera: 0,
  ear: SkillRecord(etapa: stage),
);

Language _unsupportedScriptLanguage() => Language(
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
    'thinking': 'Секунду',
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

class _ReadableArabicCatalog extends FakeCourseCatalog {
  _ReadableArabicCatalog({super.repaso}) : super.arabic();

  @override
  Future<Book?> book(String id) async {
    final b = await super.book(id);
    if (b != null) b.readable = true;
    return b;
  }

  @override
  ClipInfo? clip(String id) {
    if (id == 'solo-marhaba') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'مرحباً',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    if (id == 'solo-aghliq') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'أغلق',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    if (id == 'solo-akala') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'أَكَلَ',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    if (id == 'solo-ukila') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'أُكِلَ',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    return super.clip(id);
  }
}

class _SingleClipArabicCatalog extends FakeCourseCatalog {
  _SingleClipArabicCatalog({
    required this.bookId,
    required this.clipId,
    required this.clipText,
  }) : super.arabic();

  final String bookId;
  final String clipId;
  final String clipText;

  @override
  Future<Book?> book(String id) async => id == bookId
      ? Book(
          id: bookId,
          title: 'تجربة',
          readable: true,
          pages: [
            BookPage(image: 'img/1.png', clips: [clipId]),
          ],
        )
      : super.book(id);

  @override
  Future<Map<String, dynamic>> story(String id) async => id == bookId
      ? {
          'title': 'تجربة',
          'clips': {
            clipId: {'who': 'narr', 'text': clipText},
          },
        }
      : super.story(id);

  @override
  ClipInfo? clip(String id) => id == clipId
      ? ClipInfo(
          id: clipId,
          who: 'narr',
          text: clipText,
          startMs: 0,
          endMs: 400,
          url: 'audio/$clipId.mp3',
        )
      : super.clip(id);
}

Future<void> _loadNocheFonts() async {
  for (final entry in nocheFontFiles.entries) {
    for (final prefix in ['', 'packages/coqui_ui/']) {
      final loader = FontLoader('$prefix${entry.key}');
      for (final relPath in entry.value.values) {
        final file = File('../../core/coqui_ui/$relPath');
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
      await loader.load();
    }
  }
}

void main() {
  setUpAll(() async {
    await _loadNocheFonts();
  });

  group('Language routing in reading.dart, story_generator.dart, reading_audio.dart', () {
    test('readingWords, readingKey, and readingLines handle Arabic diacritics, alef variants, and Arabic question mark', () {
      expect(
        readingWords(
          'تقول جدة: مرحباً! أغلق الباب؟',
          language: arabicTestLanguage,
        ),
        ['تقول', 'جدة', 'مرحبا', 'اغلق', 'الباب'],
      );
      expect(
        readingKey('إلى بَيْت جدة', language: arabicTestLanguage),
        'الى بيت جدة',
      );
      expect(readingLines('هل هذا بيت؟ نعم هذا بيت.'), [
        'هل هذا بيت؟',
        'نعم هذا بيت.',
      ]);
    });

    test('ReadingVocabulary, readingCoverage, and StoryGenerator match Arabic across diacritics and alef variants and respect ؟ utterance boundaries', () {
      final vocabulary = ReadingVocabulary([
        _known('مرحباً'),
        _known('أغلق'),
        _known('بيت جدة'),
        _known('هذا'),
        _known('كبير'),
      ], language: arabicTestLanguage);

      // Diacritic and alef variants match known vocabulary.
      final cov1 = readingCoverage(
        'مرحبا! اغلق بيت جدة. هذا كبير.',
        vocabulary,
      );
      expect(cov1.unknown, isEmpty);
      expect(meetsReadingCoverage(cov1), isTrue);

      // Known phrase 'بيت جدة' must NOT match across Arabic question mark ؟.
      final cov2 = readingCoverage('هل هذا بيت؟ جدة هنا.', vocabulary);
      expect(cov2.unknown.keys, containsAll(['بيت', 'جدة']));

      // StoryGenerator prioritizes due words and requires focus words using Arabic normalization.
      final generator = StoryGenerator([
        (
          title: 'الباب',
          beats: [
            ['مرحباً! أغلق بيت جدة.'],
          ],
        ),
        (
          title: 'البيت',
          beats: [
            ['هذا بيت جدة كبير.'],
          ],
        ),
      ]);
      final byFocus = generator.generate(
        vocabulary: vocabulary,
        focus: ['اغلق'],
        due: const ['كبير'],
        previous: const {},
        rng: Mulberry32(1),
      );
      expect(byFocus?.title, 'الباب');

      final byDue = generator.generate(
        vocabulary: vocabulary,
        focus: const [],
        due: const ['كبير'],
        previous: const {},
        rng: Mulberry32(1),
      );
      expect(byDue?.title, 'البيت');
    });

    test('readingProgress counts Arabic words and splits on ؟', () {
      final text = ReadingText(
        id: 'biblioteca-ar-1',
        title: 'المطر',
        body: [
          List.filled(60, 'بيت').join(' '),
          List.filled(60, 'باب').join(' '),
          List.filled(60, 'جدة').join(' '),
          List.filled(61, 'مطر').join(' '),
        ].join('؟ '),
        generated: false,
      );
      expect(
        readingProgress(
          text,
          const ReadingPlace(page: 0),
          language: arabicTestLanguage,
        ),
        (page: 1, totalPages: 2, minutesLeft: 3),
      );
      expect(
        readingProgress(
          text,
          const ReadingPlace(page: 1),
          language: arabicTestLanguage,
        ),
        (page: 2, totalPages: 2, minutesLeft: 1),
      );
    });

    test(
      'ReadingAudio resolves Arabic word and line clips via course.language',
      () async {
        final course = _ReadableArabicCatalog(
          repaso: RepasoData(
            words: [
              RepasoWord(
                word: 'مرحباً',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-marhaba',
              ),
              RepasoWord(
                word: 'أغلق',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-aghliq',
              ),
              RepasoWord(
                word: 'أَكَلَ',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-akala',
              ),
              RepasoWord(
                word: 'أُكِلَ',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-ukila',
              ),
            ],
            sentences: [
              RepasoSentence(
                clip: 'esta_casa',
                story: 'la-lluvia',
                text: 'هذا بيت جدة.',
                tokens: ['هذا', 'بيت', 'جدة'],
                forbidden: const [],
                forHearing: true,
                forBuilding: false,
              ),
            ],
          ),
        );
        await course.load();
        final audio = ReadingAudio(course);

        // Matches both exact and diacritic/alef-normalized forms.
        expect(audio.word('مرحباً')?.clip, 'solo-marhaba');
        expect(audio.word('مرحبا')?.clip, 'solo-marhaba');
        expect(audio.word('اغلق')?.clip, 'solo-aghliq');
        expect(audio.line('هذا بيت جدة.'), 'esta_casa');

        // Separate recordings for vocalized minimal pairs stay distinct.
        expect(audio.word('أَكَلَ')?.clip, 'solo-akala');
        expect(audio.word('أَكَلَ')?.word, 'أَكَلَ');
        expect(audio.word('أُكِلَ')?.clip, 'solo-ukila');
        expect(audio.word('أُكِلَ')?.word, 'أُكِلَ');
        // Unvocalized spelling still resolves via normalized fallback.
        expect(audio.word('اكل'), isNotNull);
      },
    );

    test('unsupported script throws UnsupportedError across reading helpers (proves Language routing)', () {
      final unsupported = _unsupportedScriptLanguage();
      expect(
        () => readingWords('Привет', language: unsupported),
        throwsUnsupportedError,
      );
      expect(
        () => ReadingVocabulary([_known('Привет')], language: unsupported),
        throwsUnsupportedError,
      );
      expect(
        () => readingProgress(
          const ReadingText(
            id: 'biblioteca-ru-1',
            title: 'Дом',
            body: 'Привет мир',
            generated: false,
          ),
          const ReadingPlace(),
          language: unsupported,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => ReaderEarIndex([_known('Привет')], unsupported),
        throwsUnsupportedError,
      );
    });
  });

  group('ReadingHome in FakeCourseCatalog.arabic()', () {
    for (final size in const [Size(390, 844), Size(412, 915)]) {
      testWidgets(
        'renders RTL shelf, English menus, Arabic pair picture (LTR), and RTL prompt field at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final course = _ReadableArabicCatalog();
          await course.load();
          final pictures = FakePictureSource();
          final nav = FakeNavigator();
          final services = fakeServices(
            course: course,
            pictures: pictures,
            nav: nav,
          );
          final store = ReadingStore(services.storage(ReadingStore.space));

          final olderStory = await store.add(
            now: 100,
            title: 'بيت جدة',
            body: 'هذا بيت جدة الكبير.',
            generated: true,
          );
          final newerBook = await store.add(
            now: 200,
            title: 'قصة المطر',
            body: 'انظر! جاء المطر؟ هذا بيت جدة.\n\nالنافذة مغلقة.\n\nهذا باب.',
            generated: false,
          );
          await store.markOpened(olderStory.id, 1000);
          await store.savePlace(
            newerBook.id,
            const ReadingPlace(page: 1, openedAt: 2000),
          );

          const module = LibraryModule();
          expect(module.tab(services).label, 'المكتبة');

          await tester.pumpWidget(
            MaterialApp(home: ReadingHome(services: services)),
          );
          await settle(tester);

          expect(tester.takeException(), isNull);
          // Menus and chrome stay English; eyebrow uses language.englishName.
          expect(find.text('ARABIC'), findsOneWidget);
          expect(find.text('Library'), findsOneWidget);
          expect(find.text('Write my story'), findsOneWidget);
          expect(find.text('All'), findsOneWidget);
          expect(find.text('Stories'), findsOneWidget);
          expect(find.text('Books'), findsOneWidget);
          expect(find.text('KEEP READING'), findsOneWidget);
          expect(find.text('Continue reading'), findsOneWidget);

          // RTL shelf: most recently opened (Book) sits to the RIGHT of older item (Story).
          final bookRect = tester.getRect(find.text('Book'));
          final storyRect = tester.getRect(find.text('Story'));
          expect(bookRect.left, greaterThan(storyRect.left));

          // Story tile resolved the Arabic ReviewPair ('بيت') and kept its picture LTR.
          expect(pictures.shown, isNotEmpty);
          final pictureOverflow = find.byType(OverflowBox);
          expect(pictureOverflow, findsOneWidget);
          expect(
            Directionality.of(tester.element(pictureOverflow)),
            TextDirection.ltr,
          );

          // Open "Write my story" sheet: English chrome, RTL input for Arabic practice words.
          await tester.tap(
            find.widgetWithText(NocheOutlineButton, 'Write my story'),
          );
          await tester.pumpAndSettle();
          expect(find.text('Practice words (optional)'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.textDirection, TextDirection.rtl);

          // Enter Arabic words separated by Arabic comma (،) and submit cleanly.
          await tester.enterText(find.byType(TextFormField), 'بيت، باب');
          await tester.tap(
            find.widgetWithText(NochePrimaryButton, 'Write my story'),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('TextReader in FakeCourseCatalog.arabic()', () {
    testWidgets(
      'renders Arabic course book RTL, plays audio, credits Arabic words, and disables drop cap',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = _ReadableArabicCatalog();
        await course.load();
        final clips = TimedClips(length: const Duration(milliseconds: 80));
        final progress = FakeProgressStore();
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
        );

        expect(
          isDropCapEligible(
            paragraphIndex: 0,
            charStart: 0,
            paragraphText: 'هذا بيت جدة الكبير.',
            language: arabicTestLanguage,
          ),
          isFalse,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'la-lluvia'),
          ),
        );
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('المطر'), findsWidgets);
        expect(
          Directionality.of(tester.element(find.byType(ReaderPageView))),
          TextDirection.rtl,
        );

        // Course book with Arabic clips shows audio controls and credits normalized Arabic words.
        expect(find.byType(NochePlayDisc), findsOneWidget);
        await tester.tap(find.byType(NochePlayDisc));
        await tester.pump();
        expect(clips.played, isNotEmpty);

        await tester.pump(const Duration(milliseconds: 120));
        await settle(tester);
        // Stop playback before leaving.
        final pauseFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.pause),
        );
        if (pauseFinder.evaluate().isNotEmpty) {
          await tester.tap(pauseFinder);
          await settle(tester);
        }
        expect(progress.words, isNotEmpty);
      },
    );

    testWidgets(
      'crediting an unrecorded Arabic word prefers exact vocalized records and reuses existing diacritic records without duplicating',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = _SingleClipArabicCatalog(
          bookId: 'ar-dedup',
          clipId: 'c1',
          clipText: 'مرحبا أُكِلَ يا جدة.',
        );
        final clips = TimedClips(length: const Duration(milliseconds: 50));
        final progress = FakeProgressStore();
        progress.put(_known('مرحباً', stage: 2));
        progress.put(_known('أَكَلَ', stage: 2));
        progress.put(_known('أُكِلَ', stage: 2));
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'ar-dedup'),
          ),
        );
        await settle(tester);

        await tester.tap(find.byType(NochePlayDisc));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await settle(tester);

        final marhabaRecords = progress.words
            .where((r) => arabicTestLanguage.normalize(r.w).trim() == 'مرحبا')
            .toList();
        expect(marhabaRecords, hasLength(1));
        expect(marhabaRecords.single.w, 'مرحباً');
        expect(marhabaRecords.single.oida, 1);

        // Exact vocalized spelling 'أُكِلَ' is credited instead of earlier 'أَكَلَ'.
        expect(progress.word('أُكِلَ')?.oida, 1);
        expect(progress.word('أَكَلَ')?.oida, 0);
      },
    );

    testWidgets(
      'RTL multi-chapter Arabic book turns pages left=next/right=prev, taps Arabic words, skips Arabic digits, tracks A2 words, and renders Chapters sheet RTL',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = _ReadableArabicCatalog(
          repaso: RepasoData(
            words: [
              RepasoWord(
                word: 'مرحباً',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-marhaba',
              ),
            ],
            sentences: const [],
          ),
        );
        await course.load();
        final clips = TimedClips(length: const Duration(milliseconds: 50));
        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'nivel': {'cefr': 'A2'},
            'palabras': {
              'مرحباً': _known('مرحباً', stage: 2).toJson(),
              'بيت': _known('بيت', stage: 4).toJson(),
            },
          }),
        );
        final nav = FakeNavigator();
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          nav: nav,
        );
        final store = ReadingStore(services.storage(ReadingStore.space));

        final longArabicParagraph = List.filled(
          18,
          'هذا بيت جدة الكبير في المدينة القديمة والنافذة مفتوحة على البحر.',
        ).join(' ');
        final book = await store.add(
          now: 500,
          title: 'رحلة البيت',
          body:
              'مرحباً يا جدة ١٢٣.\n\n$longArabicParagraph\n\nالآن جدة عند باب البيت.',
          generated: false,
          chapters: [
            ReadingChapter(
              label: 'القسم الأول',
              title: 'بيت جدة',
              paragraphs: ['مرحباً يا جدة ١٢٣.', longArabicParagraph],
            ),
            const ReadingChapter(
              label: 'القسم الثاني',
              title: 'باب البيت',
              paragraphs: ['الآن جدة عند باب البيت.'],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 6),
            ),
          ),
        );
        await settle(tester);

        expect(tester.takeException(), isNull);
        final totalPages = store.place(book.id).totalPages!;
        expect(totalPages, greaterThan(2));
        expect(find.text('1 / $totalPages'), findsOneWidget);

        // Verified A2 records normalized Arabic encountered words (diacritic stripped).
        expect(store.place(book.id).words, containsAll(['مرحبا', 'جدة']));

        // Helper to locate a word inside the RTL RenderParagraph.
        Offset centerOfWord(String word) {
          final para = tester.renderObject(
            find.textContaining(word, findRichText: true).first,
          ) as RenderParagraph;
          final plain = para.text.toPlainText();
          final idx = plain.indexOf(word);
          final boxes = para.getBoxesForSelection(
            TextSelection(baseOffset: idx, extentOffset: idx + word.length),
          );
          return para.localToGlobal(boxes.first.toRect().center);
        }

        // Tap recorded Arabic word 'مرحباً' -> opens RTL bubble, plays solo clip, credits ear.
        await tester.tapAt(centerOfWord('مرحباً'));
        await tester.pump(const Duration(milliseconds: 100));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsOneWidget);
        expect(clips.played, ['solo-marhaba']);
        expect(progress.word('مرحباً')?.oida, 1);

        final bubbleText = tester.widget<Text>(
          find.descendant(
            of: find.byType(ReaderWordBubble),
            matching: find.text('مرحباً'),
          ),
        );
        expect(bubbleText.textDirection, TextDirection.rtl);
        expect(bubbleText.locale, const Locale('ar'));

        // Dismiss bubble by tapping the empty horizontal margin of the viewport.
        final readerRect = tester.getRect(find.byType(TextReader));
        await tester.tapAt(Offset(readerRect.left + 8, readerRect.center.dy));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap Arabic-Indic numerals '١٢٣' -> ignored (no word bubble).
        await tester.tapAt(centerOfWord('١٢٣'));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // RTL tap zones: tapping LEFT fifth advances forward (1 -> 2), RIGHT fifth goes back (2 -> 1).
        await tester.tapAt(Offset(readerRect.left + 20, readerRect.center.dy));
        await settle(tester);
        expect(find.text('2 / $totalPages'), findsOneWidget);

        await tester.tapAt(Offset(readerRect.right - 20, readerRect.center.dy));
        await settle(tester);
        expect(find.text('1 / $totalPages'), findsOneWidget);

        // RTL swipe: swiping RIGHT advances forward (1 -> 2), swiping LEFT goes back (2 -> 1).
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(300, 0),
          800,
        );
        await settle(tester);
        expect(find.text('2 / $totalPages'), findsOneWidget);

        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await settle(tester);
        expect(find.text('1 / $totalPages'), findsOneWidget);

        // Open Chapters sheet: English title 'Chapters', RTL Arabic chapter rows.
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.chapters)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chapters'), findsOneWidget);

        final secondChapterFinder = find.text('باب البيت');
        expect(secondChapterFinder, findsOneWidget);
        expect(
          Directionality.of(tester.element(secondChapterFinder)),
          TextDirection.rtl,
        );
        final secondChapterText = tester.widget<Text>(secondChapterFinder);
        expect(secondChapterText.textDirection, TextDirection.rtl);
        expect(secondChapterText.locale, const Locale('ar'));

        // Jump to Chapter 2 (last page) and tap LEFT fifth to finish book -> marks read & navigates back.
        await tester.tap(secondChapterFinder);
        await tester.pumpAndSettle();
        expect(find.text('$totalPages / $totalPages'), findsOneWidget);

        await tester.tapAt(Offset(readerRect.left + 20, readerRect.center.dy));
        await settle(tester);
        expect(progress.hasRead(book.id), isTrue);
        expect(nav.backs, 1);
      },
    );
  });

  group('Package-wide static language & directional layout audit', () {
    final dartFiles = [
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      ...Directory('tool')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('test/support.dart'),
    ];

    final forbidden = <String, RegExp>{
      'bare global normalize() call': RegExp(r'(?<!\.)\bnormalize\('),
      'hardcoded readingWordPattern': RegExp(r'\breadingWordPattern\b'),
      'non-directional EdgeInsets.fromLTRB': RegExp(r'EdgeInsets\.fromLTRB'),
      'non-directional EdgeInsets.only': RegExp(r'EdgeInsets\.only\('),
      'non-directional EdgeInsets.symmetric': RegExp(
        r'EdgeInsets\.symmetric\(',
      ),
      'non-directional Alignment.centerLeft/Right': RegExp(
        r'Alignment\.(?:center|top|bottom)(?:Left|Right)\b',
      ),
      'non-directional Positioned(left:/right:)': RegExp(
        r'Positioned\([^)]*\b(?:left|right):',
      ),
      'non-directional TextAlign.left/right': RegExp(
        r'TextAlign\.(?:left|right)\b',
      ),
      'direct flutter/material import': RegExp(
        r'package:flutter/material\.dart',
      ),
    };

    test('all lib/, tool/, and test/support.dart files pass language & directional audit', () {
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final entry in forbidden.entries) {
          expect(
            entry.value.hasMatch(source),
            isFalse,
            reason: '${file.path} must not contain ${entry.key}',
          );
        }
      }
    });
  });
}
