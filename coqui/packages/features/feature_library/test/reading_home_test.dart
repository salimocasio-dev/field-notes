import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/motion.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:feature_library/src/wording.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show Rig, TestCourse, settle;

const List<Size> _viewports = [Size(390, 844), Size(412, 915)];

bool get _captureShots => Platform.environment['CAPTURE_LIBRARY_SHOTS'] == '1';

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

Future<void> _saveScreenshot(WidgetTester tester, String filename) async {
  final boundary = tester.renderObject(
    find.byType(RepaintBoundary).first,
  ) as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1.0));
  final byteData = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  final outFile = File('test/screenshots/$filename');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Services services,
  required Size size,
  bool showAddYourOwn = true,
  bool withTabBar = false,
  bool disableAnimations = false,
  StoryGenerator? generator,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final lang = services.course.language;
  final Widget home = withTabBar
      ? ColoredBox(
          color: NocheColors.ground,
          child: Stack(
            children: [
              Positioned.fill(
                child: ReadingHome(
                  services: services,
                  showAddYourOwn: showAddYourOwn,
                  generator: generator,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: NocheTabBar(
                  selectedId: NocheTabs.library,
                  tabNames: lang.tabNames,
                  script: lang.script,
                  languageCode: lang.code,
                  onTap: (_) {},
                ),
              ),
            ],
          ),
        )
      : ReadingHome(
          services: services,
          showAddYourOwn: showAddYourOwn,
          generator: generator,
        );

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: home,
    ),
  );
  await settle(tester);
}

StoryGenerator _simpleGenerator() => StoryGenerator([
  (
    title: 'La casa',
    beats: [
      ['La casa es azul.'],
    ],
  ),
]);

void _learnWords(FakeProgressStore store, Iterable<String> words) {
  final snapshot = store.raw;
  store.import(
    jsonEncode({
      ...snapshot,
      'palabras': {
        ...?snapshot['palabras'] as Map?,
        for (final w in words)
          w: WordRecord(w: w, primera: 0, ear: SkillRecord(etapa: 4)).toJson(),
      },
    }),
  );
}

class _SlowStoryGenerator extends StoryGenerator {
  _SlowStoryGenerator(this.responses)
    : super([
        (
          title: 'La casa',
          beats: [
            ['La casa es azul.'],
          ],
        ),
        (
          title: 'Otra casa',
          beats: [
            ['La casa azul.'],
          ],
        ),
      ]);

  final List<Completer<StoryDraft?>> responses;
  int _index = 0;

  @override
  Future<StoryDraft?> writeStory({
    required ReadingVocabulary vocabulary,
    required List<String> focus,
    required Iterable<String> due,
    required Set<String> previous,
    required Rng rng,
  }) => responses[_index++].future;
}

class _FailingWriteStore extends FakeKeyValueStore {
  bool failWrites = false;

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage full');
    await super.write(key, value);
  }
}

class _RtlCatalog extends TestCourse implements LanguageCatalog {
  _RtlCatalog({required this.language});

  @override
  final Language language;
}

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

void main() {
  group('reading.dart pure helpers and ReadingPlace storage', () {
    test('readingProgress computes page, totalPages, and minutesLeft', () {
      const empty = ReadingText(
        id: 'biblioteca-0-0',
        title: 'Empty',
        body: '',
        generated: false,
      );
      expect(readingProgress(empty, const ReadingPlace()), (
        page: 1,
        totalPages: 1,
        minutesLeft: 1,
      ));

      final fourLines = ReadingText(
        id: 'biblioteca-1-0',
        title: 'Four lines',
        body: [
          List.filled(60, 'uno').join(' '),
          List.filled(60, 'dos').join(' '),
          List.filled(60, 'tres').join(' '),
          List.filled(61, 'cuatro').join(' '),
        ].join('\n'),
        generated: false,
      );
      // 4 lines -> 2 pages (3 + 1). Page 0: 241 words remaining -> 3 min.
      expect(readingProgress(fourLines, const ReadingPlace(page: 0)), (
        page: 1,
        totalPages: 2,
        minutesLeft: 3,
      ));
      // Page 1: 61 words remaining -> 1 min.
      expect(readingProgress(fourLines, const ReadingPlace(page: 1)), (
        page: 2,
        totalPages: 2,
        minutesLeft: 1,
      ));
      // Clamps out-of-range page index.
      expect(readingProgress(fourLines, const ReadingPlace(page: 99)), (
        page: 2,
        totalPages: 2,
        minutesLeft: 1,
      ));
      expect(readingProgress(fourLines, const ReadingPlace(page: -5)), (
        page: 1,
        totalPages: 2,
        minutesLeft: 3,
      ));
    });

    test(
      'sortShelfByRecent orders by openedAt descending with stable ties',
      () {
        const a = ReadingText(
          id: 'biblioteca-1-0',
          title: 'A',
          body: 'One.',
          generated: false,
        );
        const b = ReadingText(
          id: 'biblioteca-2-0',
          title: 'B',
          body: 'Two.',
          generated: true,
        );
        const c = ReadingText(
          id: 'biblioteca-3-0',
          title: 'C',
          body: 'Three.',
          generated: false,
        );
        const d = ReadingText(
          id: 'biblioteca-4-0',
          title: 'D',
          body: 'Four.',
          generated: true,
        );
        final places = {
          a.id: const ReadingPlace(openedAt: 100),
          b.id: const ReadingPlace(openedAt: 300),
          c.id: const ReadingPlace(openedAt: 100),
          d.id: const ReadingPlace(openedAt: 0),
        };
        final sorted = sortShelfByRecent([
          a,
          b,
          c,
          d,
        ], (id) => places[id] ?? const ReadingPlace());
        expect(sorted.map((t) => t.id).toList(), [b.id, a.id, c.id, d.id]);
      },
    );

    test('keepReadingBook selects most recent unfinished opened book only', () {
      const story = ReadingText(
        id: 'biblioteca-1-0',
        title: 'Story',
        body: 'A.',
        generated: true,
      );
      const unopened = ReadingText(
        id: 'biblioteca-2-0',
        title: 'Unopened',
        body: 'B.',
        generated: false,
      );
      const finished = ReadingText(
        id: 'biblioteca-3-0',
        title: 'Finished',
        body: 'C.',
        generated: false,
      );
      const readBook = ReadingText(
        id: 'biblioteca-4-0',
        title: 'Read',
        body: 'D.',
        generated: false,
      );
      const activeOlder = ReadingText(
        id: 'biblioteca-5-0',
        title: 'Active older',
        body: 'E.',
        generated: false,
      );
      const activeNewer = ReadingText(
        id: 'biblioteca-6-0',
        title: 'Active newer',
        body: 'F.',
        generated: false,
      );
      final places = {
        story.id: const ReadingPlace(page: 1, openedAt: 900),
        unopened.id: const ReadingPlace(page: 0, openedAt: 0),
        finished.id: const ReadingPlace(page: 0, openedAt: 800, finished: true),
        // Legacy record (openedAt == 0) with historical hasRead == true is excluded.
        readBook.id: const ReadingPlace(page: 1, openedAt: 0),
        activeOlder.id: const ReadingPlace(page: 1, openedAt: 200),
        activeNewer.id: const ReadingPlace(page: 0, openedAt: 500),
      };
      final picked = keepReadingBook(
        [story, unopened, finished, readBook, activeOlder, activeNewer],
        (id) => places[id] ?? const ReadingPlace(),
        (id) => id == readBook.id,
      );
      expect(picked?.id, activeNewer.id);

      // Re-reading a historically completed A2+ book (hasRead == true, openedAt > 0,
      // finished == false) still appears in Keep reading.
      final reread = keepReadingBook(
        [readBook, activeOlder],
        (id) => id == readBook.id
            ? const ReadingPlace(page: 1, openedAt: 700, finished: false)
            : const ReadingPlace(page: 1, openedAt: 200),
        (id) => id == readBook.id,
      );
      expect(reread?.id, readBook.id);

      // Legacy saved place with page > 0 and openedAt == 0 still qualifies when unread.
      final legacy = keepReadingBook(
        [unopened, activeOlder],
        (id) => id == activeOlder.id
            ? const ReadingPlace(page: 2, openedAt: 0)
            : const ReadingPlace(),
        (_) => false,
      );
      expect(legacy?.id, activeOlder.id);
    });

    test('keepReadingEyebrow omits chapter when 1 and includes when > 1', () {
      expect(keepReadingEyebrow(), 'Keep reading');
      expect(keepReadingEyebrow(chapter: 1, chapterCount: 1), 'Keep reading');
      expect(
        keepReadingEyebrow(chapter: 2, chapterCount: 5),
        'Keep reading · Chapter 2',
      );
    });

    test(
      'ReadingStore.place reads legacy JSON without openedAt/finished',
      () async {
        final kv = FakeKeyValueStore();
        await kv.write(
          'place:biblioteca-1-0',
          jsonEncode({
            'page': 2,
            'words': ['casa'],
          }),
        );
        final store = ReadingStore(kv);
        final place = store.place('biblioteca-1-0');
        expect(place.page, 2);
        expect(place.words, {'casa'});
        expect(place.openedAt, 0);
        expect(place.finished, isFalse);

        await store.markOpened('biblioteca-1-0', 12345);
        final opened = store.place('biblioteca-1-0');
        expect(opened.page, 2);
        expect(opened.words, {'casa'});
        expect(opened.openedAt, 12345);
        expect(opened.finished, isFalse);

        await store.savePlace(
          'biblioteca-1-0',
          const ReadingPlace(
            page: 0,
            words: {'casa'},
            openedAt: 12346,
            finished: true,
          ),
        );
        final done = store.place('biblioteca-1-0');
        expect(done.finished, isTrue);
        expect(done.openedAt, 12346);
      },
    );
  });

  group('ReadingHome empty shelf (zero words, locked slot)', () {
    for (final size in _viewports) {
      testWidgets(
        'renders bookcase with locked non-interactive slot at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          await _pumpHome(
            tester,
            services: rig.services,
            size: size,
            generator: _simpleGenerator(),
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('library-home')), findsOneWidget);
          expect(find.text('SPANISH'), findsOneWidget);
          expect(find.text(LibraryWording.libraryTitle), findsOneWidget);
          expect(find.text(LibraryWording.addYourOwnPill), findsOneWidget);
          expect(find.text('STORIES'), findsOneWidget);
          expect(find.text('BOOKS'), findsOneWidget);

          // Locked slot shows full reason in text color and is non-interactive.
          expect(find.text(LibraryWording.newStoryLocked), findsOneWidget);
          expect(find.byKey(const Key('library-slot-locked')), findsOneWidget);
          expect(find.byKey(const Key('library-write-story')), findsNothing);
          expect(find.text(LibraryWording.newStoryOpen), findsNothing);
          final lockedText = tester.widget<Text>(
            find.text(LibraryWording.newStoryLocked),
          );
          expect(lockedText.style?.color, NocheColors.text);

          // Tapping the locked slot cannot open the sheet (rule 7).
          await tester.tap(find.byKey(const Key('library-slot-locked')));
          await settle(tester);
          expect(find.text(LibraryWording.writeMyStory), findsNothing);
          expect(find.byType(TextFormField), findsNothing);

          // Removed elements from pre-N8.11 are absent.
          expect(find.text('Write my story'), findsNothing);
          expect(find.text('All'), findsNothing);
          expect(find.text('Stories'), findsNothing);
          expect(find.text('Books'), findsNothing);
          expect(find.text('Story'), findsNothing);
          expect(find.text('Book'), findsNothing);
          expect(find.textContaining('READING COUNTS FROM A2'), findsNothing);
          expect(find.textContaining('YOUR SHELF'), findsNothing);
          expect(find.text('Continue reading'), findsNothing);
          expect(find.textContaining('KEEP READING'), findsNothing);
          expect(find.byType(NocheCard), findsNothing);
          expect(find.byType(Image), findsNothing);
        },
      );
    }
  });

  group('ReadingHome stories only (open slot)', () {
    for (final size in _viewports) {
      testWidgets(
        'renders open slot first, then stories newest first with no captions or Reading now at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
          final services = rig.services;
          final store = ReadingStore(services.storage(ReadingStore.space));
          final older = await store.add(
            now: 100,
            title: 'Sin dibujo',
            body: 'Un texto nuevo.',
            generated: true,
          );
          final newer = await store.add(
            now: 200,
            title: 'La casa',
            body: 'La casa es grande.',
            generated: true,
          );

          await _pumpHome(
            tester,
            services: services,
            size: size,
            generator: _simpleGenerator(),
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('library-write-story')), findsOneWidget);
          expect(find.text(LibraryWording.newStoryOpen), findsOneWidget);
          expect(find.text(LibraryWording.newStoryLocked), findsNothing);
          expect(find.text('La casa'), findsOneWidget);
          expect(find.text('Sin dibujo'), findsOneWidget);
          expect(find.text('Story'), findsNothing);
          expect(find.text('Continue reading'), findsNothing);
          expect(find.textContaining('KEEP READING'), findsNothing);
          expect(find.byType(Image), findsNothing);

          // Order: open slot -> newest story -> older story.
          final slotRect = tester.getRect(
            find.byKey(const Key('library-write-story')),
          );
          final newerRect = tester.getRect(
            find.byKey(ValueKey('library-book:${newer.id}')),
          );
          final olderRect = tester.getRect(
            find.byKey(ValueKey('library-book:${older.id}')),
          );
          expect(slotRect.width, 132);
          expect(slotRect.height, 120);
          expect(slotRect.left, lessThan(newerRect.left));
          expect(newerRect.left, lessThan(olderRect.left));
        },
      );
    }
  });

  group('ReadingHome stories and books with Reading now', () {
    for (final size in _viewports) {
      testWidgets(
        'renders three shelves, 90x126 Reading now cover, text-colour bar, 120/132 book covers, and hides when finished at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
          final services = rig.services;
          final store = ReadingStore(services.storage(ReadingStore.space));
          final story = await store.add(
            now: 100,
            title: 'Una casa',
            body: 'La casa es grande.',
            generated: true,
          );
          final firstBook = await store.add(
            now: 150,
            title: 'Cuentos de la isla',
            body: 'Capítulo uno.',
            generated: false,
          );
          final activeBook = await store.add(
            now: 200,
            title: 'Un verano en Cabo Rojo',
            body: 'Uno. Dos. Tres. Cuatro. Cinco. Seis.',
            generated: false,
            chapters: const [
              ReadingChapter(title: 'Primero', paragraphs: ['Uno. Dos. Tres.']),
              ReadingChapter(
                title: 'Segundo',
                paragraphs: ['Cuatro. Cinco. Seis.'],
              ),
            ],
          );
          await store.markOpened(story.id, 1000);
          await store.savePlace(
            activeBook.id,
            const ReadingPlace(page: 1, openedAt: 2000, chapterIndex: 1),
          );

          await _pumpHome(
            tester,
            services: services,
            size: size,
            generator: _simpleGenerator(),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(Image), findsNothing);
          expect(find.text('Story'), findsNothing);
          expect(find.text('Book'), findsNothing);
          expect(
            find.byKey(ValueKey('library-book:${story.id}')),
            findsOneWidget,
          );
          expect(
            find.byKey(ValueKey('library-book:${firstBook.id}')),
            findsOneWidget,
          );
          expect(
            find.byKey(ValueKey('library-book:${activeBook.id}')),
            findsOneWidget,
          );

          // Reading now shelf: chapter eyebrow, page line wrapped in NocheLtr,
          // 90x126 cover, and progress bar in NocheColors.text.
          expect(find.text('KEEP READING · CHAPTER 2'), findsOneWidget);
          final pageProgress = find.text(
            'Page 2 of 2 · 1 min left in the chapter',
          );
          expect(pageProgress, findsOneWidget);
          expect(
            find.ancestor(of: pageProgress, matching: find.byType(NocheLtr)),
            findsWidgets,
          );

          final progressBar = tester.widget<NocheProgressBar>(
            find.byType(NocheProgressBar),
          );
          expect(progressBar.value, 0.5);
          expect(progressBar.color, NocheColors.text);

          // Verify Reading now cover is 90x126 and shelf book covers are 120 or 132 high.
          final coverRects = [
            for (final e in find.byType(NocheCover).evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ];
          expect(
            coverRects.any((r) => r.width == 90 && r.height == 126),
            isTrue,
          );
          final shelfBook1 = tester.getRect(
            find.byKey(ValueKey('library-book:${firstBook.id}')),
          );
          final shelfBook2 = tester.getRect(
            find.byKey(ValueKey('library-book:${activeBook.id}')),
          );
          expect(shelfBook1.height, anyOf(120, 132));
          expect(shelfBook2.height, anyOf(120, 132));

          // Pinned orange Continue reading button (56 high) navigates to BookRoute.
          final ctaFinder = find.widgetWithText(
            NochePrimaryButton,
            'Continue reading',
          );
          expect(ctaFinder, findsOneWidget);
          expect(tester.getSize(ctaFinder).height, 56);
          await tester.tap(ctaFinder);
          await settle(tester);
          expect(rig.nav.routes.last, BookRoute(activeBook.id));

          // Mark finished -> Reading now shelf and Continue reading button hide.
          await store.savePlace(
            activeBook.id,
            const ReadingPlace(page: 0, openedAt: 3000, finished: true),
          );
          await _pumpHome(
            tester,
            services: services,
            size: size,
            generator: _simpleGenerator(),
          );
          expect(find.textContaining('KEEP READING'), findsNothing);
          expect(find.text('Continue reading'), findsNothing);
        },
      );
    }
  });

  group('New-story slot motion (locked -> open in quick)', () {
    testWidgets(
      'fades lock out and open slot in over NocheMotion.quick when progress unlocks a story',
      (tester) async {
        final rig = Rig();
        await _pumpHome(
          tester,
          services: rig.services,
          size: _viewports.first,
          generator: _simpleGenerator(),
        );

        // Start: locked at opacity 1, open slot absent.
        expect(find.byKey(const Key('library-slot-locked')), findsOneWidget);
        expect(find.byKey(const Key('library-write-story')), findsNothing);
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('library-slot-locked-opacity')),
              )
              .opacity,
          1.0,
        );

        // Learn the plot words -> triggers progress.changes -> locked -> open.
        _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
        await tester.pump();
        await tester.pump();

        // At start (0 ms): locked 1.0, open 0.0.
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('library-slot-locked-opacity')),
              )
              .opacity,
          closeTo(1.0, 0.01),
        );
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('library-slot-open-opacity')),
              )
              .opacity,
          closeTo(0.0, 0.01),
        );

        // At middle (quick ~/ 2 = 70 ms): both mid-fade.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midLocked = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('library-slot-locked-opacity')),
            )
            .opacity;
        final midOpen = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('library-slot-open-opacity')),
            )
            .opacity;
        expect(midLocked, greaterThan(0.0));
        expect(midLocked, lessThan(1.0));
        expect(midOpen, greaterThan(0.0));
        expect(midOpen, lessThan(1.0));

        // At end: lock gone, open slot settled at 1.0 and interactive.
        await tester.pump(NocheMotion.quick);
        await tester.pump();
        expect(find.byKey(const Key('library-slot-locked')), findsNothing);
        expect(find.byKey(const Key('library-write-story')), findsOneWidget);
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('library-slot-open-opacity')),
              )
              .opacity,
          1.0,
        );

        // Open slot now opens the story sheet, and unmatched practice words show error in sheet.
        await tester.tap(find.byKey(const Key('library-write-story')));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'elefante');
        await tester.tap(find.byKey(const Key('library-write-story-submit')));
        await tester.pumpAndSettle();
        expect(find.text(LibraryWording.noStoryMatchFocused), findsOneWidget);
      },
    );

    testWidgets(
      'honours disableAnimations: true with a quick in-place cross-fade and no scaling',
      (tester) async {
        final rig = Rig();
        await _pumpHome(
          tester,
          services: rig.services,
          size: _viewports.first,
          disableAnimations: true,
          generator: _simpleGenerator(),
        );
        final slotElement = tester.element(
          find.byKey(const Key('library-slot-locked')),
        );
        expect(NocheMotion.of(slotElement).reduced, isTrue);

        _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
        await tester.pump();
        await tester.pump();

        // Midpoint of quick fade: opacities change in place.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midLocked = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('library-slot-locked-opacity')),
            )
            .opacity;
        final midOpen = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('library-slot-open-opacity')),
            )
            .opacity;
        expect(midLocked, greaterThan(0.0));
        expect(midLocked, lessThan(1.0));
        expect(midOpen, greaterThan(0.0));
        expect(midOpen, lessThan(1.0));

        // End of quick fade: settled open, Pressable keeps scale 1.0 under reduced motion.
        await tester.pump(NocheMotion.quick);
        await tester.pump();
        expect(find.byKey(const Key('library-write-story')), findsOneWidget);
        expect(find.byKey(const Key('library-slot-locked')), findsNothing);
      },
    );
  });

  testWidgets(
    'displays + Add your own by default, navigates to ImportRoute, and can be hidden',
    (tester) async {
      final rig = Rig();
      await _pumpHome(
        tester,
        services: rig.services,
        size: _viewports.first,
        generator: _simpleGenerator(),
      );

      expect(find.text(LibraryWording.addYourOwnPill), findsOneWidget);
      await tester.tap(find.text(LibraryWording.addYourOwnPill));
      await settle(tester);
      expect(rig.nav.routes, [const ImportRoute()]);

      await _pumpHome(
        tester,
        services: rig.services,
        size: _viewports.first,
        showAddYourOwn: false,
        generator: _simpleGenerator(),
      );
      expect(find.text(LibraryWording.addYourOwnPill), findsNothing);
    },
  );

  testWidgets(
    'RTL course mirrors bookcase, shows englishName, keeps page line NocheLtr and scene picture LTR',
    (tester) async {
      final rtlLang = _arabicLanguage();
      final course = _RtlCatalog(language: rtlLang);
      final pictures = FakePictureSource();
      final services = fakeServices(course: course, pictures: pictures);
      final store = ReadingStore(services.storage(ReadingStore.space));
      final story = await store.add(
        now: 100,
        title: 'casa',
        body: 'casa',
        generated: true,
      );
      final book = await store.add(
        now: 200,
        title: 'كتاب',
        body: 'Uno. Dos. Tres. Cuatro.',
        generated: false,
      );
      await store.markOpened(story.id, 100);
      await store.savePlace(
        book.id,
        const ReadingPlace(page: 1, openedAt: 200),
      );

      const module = LibraryModule();
      expect(module.tab(services).label, 'المكتبة');

      await _pumpHome(
        tester,
        services: services,
        size: _viewports.first,
        generator: _simpleGenerator(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ARABIC'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);

      final libraryText = find.text('Library');
      expect(Directionality.of(tester.element(libraryText)), TextDirection.rtl);

      // Page progress stays LTR inside RTL via NocheLtr.
      final progressLine = find.textContaining('min left in the chapter');
      expect(progressLine, findsOneWidget);
      expect(
        Directionality.of(tester.element(progressLine)),
        TextDirection.ltr,
      );

      // Scene picture inside the story tile stays LTR.
      final pictureOverflow = find.byType(OverflowBox);
      expect(pictureOverflow, findsOneWidget);
      expect(
        Directionality.of(tester.element(pictureOverflow)),
        TextDirection.ltr,
      );
      expect(pictures.shown, isNotEmpty);
    },
  );

  group('N8.11 Library bookcase screenshots', () {
    setUpAll(() async {
      if (_captureShots) await _loadNocheFonts();
    });

    Future<Services> buildServices({
      required bool open,
      required bool withStories,
      required bool withBooks,
      bool arabic = false,
    }) async {
      final progress = FakeProgressStore();
      if (open) {
        _learnWords(progress, [
          'la',
          'casa',
          'es',
          'azul',
          'هذا',
          'بيت',
          'جدة',
        ]);
      }
      final course = arabic ? FakeCourseCatalog.arabic() : TestCourse();
      await course.load();
      final services = fakeServices(
        progress: progress,
        course: course,
        pictures: FakePictureSource(),
      );
      final store = ReadingStore(services.storage(ReadingStore.space));
      if (withStories) {
        if (arabic) {
          final s1 = await store.add(
            now: 100,
            title: 'في المطبخ',
            body: 'هذا بيت جدة.',
            generated: true,
          );
          final s2 = await store.add(
            now: 200,
            title: 'يوم في البيت',
            body: 'بيت جدة كبير.',
            generated: true,
          );
          await store.markOpened(s1.id, 100);
          await store.markOpened(s2.id, 200);
        } else {
          final s1 = await store.add(
            now: 100,
            title: 'Tengo hambre',
            body: 'La hermana dice hola.',
            generated: true,
          );
          final s2 = await store.add(
            now: 200,
            title: 'Un día en el parque',
            body: 'La casa es grande.',
            generated: true,
          );
          await store.markOpened(s1.id, 100);
          await store.markOpened(s2.id, 200);
        }
      }
      if (withBooks) {
        if (arabic) {
          final b1 = await store.add(
            now: 301,
            title: 'حكايات الجزيرة',
            body: 'هذا بيت جدة.',
            generated: false,
          );
          final b2 = await store.add(
            now: 400,
            title: 'صيف على البحر',
            body: List.filled(36, 'هذا بيت جدة الكبير.').join('\n'),
            generated: false,
            chapters: const [
              ReadingChapter(title: '١', paragraphs: ['هذا بيت جدة.']),
              ReadingChapter(title: '٢', paragraphs: ['هذا بيت جدة الكبير.']),
            ],
          );
          await store.savePlace(b1.id, const ReadingPlace(openedAt: 300));
          await store.savePlace(
            b2.id,
            const ReadingPlace(
              page: 13,
              totalPages: 86,
              openedAt: 400,
              chapterIndex: 1,
            ),
          );
        } else {
          final b1 = await store.add(
            now: 301,
            title: 'Cuentos de la isla',
            body: 'La casa es grande.',
            generated: false,
          );
          final b2 = await store.add(
            now: 400,
            title: 'Un verano en Cabo Rojo',
            body: List.filled(120, 'La casa es grande en la isla.').join('\n'),
            generated: false,
            chapters: const [
              ReadingChapter(title: 'Uno', paragraphs: ['La casa es grande.']),
              ReadingChapter(title: 'Dos', paragraphs: ['El mar es azul.']),
            ],
          );
          await store.savePlace(b1.id, const ReadingPlace(openedAt: 300));
          await store.savePlace(
            b2.id,
            const ReadingPlace(
              page: 13,
              totalPages: 86,
              openedAt: 400,
              chapterIndex: 1,
            ),
          );
        }
      }
      return services;
    }

    final scenarios = [
      (
        name: 'library_locked',
        open: false,
        stories: true,
        books: true,
        arabic: false,
      ),
      (
        name: 'library_open',
        open: true,
        stories: true,
        books: true,
        arabic: false,
      ),
      (
        name: 'library_empty',
        open: false,
        stories: false,
        books: false,
        arabic: false,
      ),
      (
        name: 'library_stories',
        open: true,
        stories: true,
        books: false,
        arabic: false,
      ),
      (
        name: 'library_both',
        open: true,
        stories: true,
        books: true,
        arabic: false,
      ),
      (
        name: 'library_arabic',
        open: false,
        stories: true,
        books: true,
        arabic: true,
      ),
    ];

    for (final scenario in scenarios) {
      for (final size in _viewports) {
        final label =
            '${scenario.name}_${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('renders $label without overflow', (tester) async {
          final services = await buildServices(
            open: scenario.open,
            withStories: scenario.stories,
            withBooks: scenario.books,
            arabic: scenario.arabic,
          );
          final gen = scenario.arabic
              ? StoryGenerator([
                  (
                    title: 'قصة',
                    beats: [
                      ['هذا بيت جدة.'],
                    ],
                  ),
                ])
              : _simpleGenerator();
          await _pumpHome(
            tester,
            services: services,
            size: size,
            withTabBar: true,
            generator: gen,
          );
          expect(tester.takeException(), isNull);
          if (_captureShots) {
            await _saveScreenshot(tester, '$label.png');
          }
        });
      }
    }
  });

  group('N8.12 Writing a story', () {
    setUpAll(() async {
      await _loadNocheFonts();
    });

    test('ReadingText.isNew persists in ReadingStore and markOpened clears it even at now == 0', () async {
      final kv = FakeKeyValueStore();
      final store = ReadingStore(kv);
      final added = await store.add(
        now: 10,
        title: 'La casa',
        body: 'La casa es azul.',
        generated: true,
        isNew: true,
      );
      expect(added.isNew, isTrue);
      expect(store.text(added.id)?.isNew, isTrue);

      final old = await store.add(
        now: 5,
        title: 'El parque',
        body: 'El parque es grande.',
        generated: true,
      );
      expect(old.isNew, isFalse);
      expect(store.text(old.id)?.isNew, isFalse);

      // markOpened at clock == 0 still clears isNew.
      await store.markOpened(added.id, 0);
      expect(store.text(added.id)?.isNew, isFalse);
      expect(store.texts().firstWhere((t) => t.id == added.id).isNew, isFalse);
    });

    testWidgets(
      'sheet swaps in place at identical height, animates 3 dots, blocks dismissal while writing, and shows error on mismatch or save failure',
      (tester) async {
        final storage = _FailingWriteStore();
        final progress = FakeProgressStore();
        _learnWords(progress, ['la', 'casa', 'es', 'azul']);
        final services = fakeServices(
          progress: progress,
          course: TestCourse(),
          storage: (_) => storage,
        );
        final firstFail = Completer<StoryDraft?>();
        final secondSuccessThenStorageFail = Completer<StoryDraft?>();
        final generator = _SlowStoryGenerator([
          firstFail,
          secondSuccessThenStorageFail,
        ]);

        await _pumpHome(
          tester,
          services: services,
          size: _viewports.first,
          generator: generator,
        );

        await tester.tap(find.byKey(const Key('library-write-story')));
        await tester.pumpAndSettle();

        // Submit button is text-filled (NocheColors.text, NOT NocheColors.next),
        // and the sheet contains no NochePrimaryButton.
        final sheetFinder = find.byType(NocheSheet);
        expect(sheetFinder, findsOneWidget);
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.byType(NochePrimaryButton),
          ),
          findsNothing,
        );
        final submitFinder = find.byKey(
          const Key('library-write-story-submit'),
        );
        final submitBox = tester.widget<Container>(
          find.descendant(of: submitFinder, matching: find.byType(Container)),
        );
        expect((submitBox.decoration as BoxDecoration).color, NocheColors.text);

        // Measure sheet height BEFORE writing.
        final heightBefore = tester.getSize(sheetFinder).height;

        // Submit unmatched practice word -> swaps into writing view.
        await tester.enterText(find.byType(TextFormField), 'elefante');
        await tester.tap(submitFinder);
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.move);

        expect(find.text(LibraryWording.writingStoryTitle), findsOneWidget);
        expect(find.text(LibraryWording.writingStorySubtitle), findsOneWidget);
        final titleWidget = tester.widget<Text>(
          find.text(LibraryWording.writingStoryTitle),
        );
        expect(titleWidget.style?.fontSize, NocheType.sheetTitle.fontSize);

        // Three 12x12 dots in NocheColors.other whose opacities animate across frames.
        final opacitiesT0 = <double>[];
        for (var i = 0; i < 3; i++) {
          final dotFinder = find.byKey(
            ValueKey<String>('library-writing-dot-$i'),
          );
          expect(dotFinder, findsOneWidget);
          expect(tester.getSize(dotFinder), const Size(12, 12));
          final dotBox = tester.widget<DecoratedBox>(
            find.descendant(of: dotFinder, matching: find.byType(DecoratedBox)),
          );
          final deco = dotBox.decoration as BoxDecoration;
          expect(deco.color, NocheColors.other);
          expect(deco.shape, BoxShape.circle);
          opacitiesT0.add(tester.widget<Opacity>(dotFinder).opacity);
        }

        await tester.pump(const Duration(milliseconds: 150));
        final opacitiesT1 = [
          for (var i = 0; i < 3; i++)
            tester
                .widget<Opacity>(
                  find.byKey(ValueKey<String>('library-writing-dot-$i')),
                )
                .opacity,
        ];
        expect(opacitiesT1, isNot(equals(opacitiesT0)));

        // Measure sheet height DURING writing -> matches BEFORE.
        final heightDuring = tester.getSize(sheetFinder).height;
        expect(heightDuring, closeTo(heightBefore, 0.01));

        // Scrim tap, drag-down, and Navigator.maybePop all do NOT close while writing.
        await tester.tapAt(const Offset(20, 40));
        await tester.pump();
        expect(sheetFinder, findsOneWidget);

        await tester.drag(sheetFinder, const Offset(0, 140));
        await tester.pump();
        expect(sheetFinder, findsOneWidget);

        final sheetRoute = ModalRoute.of(tester.element(sheetFinder))!;
        expect(sheetRoute.popDisposition, RoutePopDisposition.doNotPop);
        final handled = await Navigator.maybePop(tester.element(sheetFinder));
        await tester.pump();
        expect(handled, isTrue);
        expect(sheetRoute.isCurrent, isTrue);
        expect(sheetFinder, findsOneWidget);

        // Complete slow generator with null -> swaps back to form with error above button.
        firstFail.complete(null);
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.move);

        expect(find.text(LibraryWording.noStoryMatchFocused), findsOneWidget);
        expect(submitFinder, findsOneWidget);
        final heightAfterError = tester.getSize(sheetFinder).height;
        expect(heightAfterError, closeTo(heightBefore, 0.01));

        // Storage-full failure also swaps back to form with storySaveFailed at same height.
        storage.failWrites = true;
        await tester.enterText(find.byType(TextFormField), '');
        await tester.tap(submitFinder);
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.move);
        expect(find.text(LibraryWording.writingStoryTitle), findsOneWidget);

        secondSuccessThenStorageFail.complete(
          const StoryDraft('La casa', 'La casa es azul.'),
        );
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.move);

        expect(find.text(LibraryWording.storySaveFailed), findsOneWidget);
        expect(tester.getSize(sheetFinder).height, closeTo(heightBefore, 0.01));

        // Scrim tap now DOES close the sheet once writing has failed and unlocked.
        await tester.tapAt(const Offset(20, 40));
        await tester.pumpAndSettle();
        expect(sheetFinder, findsNothing);
      },
    );

    testWidgets(
      'sheet slides down, waits 260ms, shifts existing stories, fades new story in with NEW badge, and clears NEW on tap',
      (tester) async {
        final rig = Rig();
        _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
        final services = rig.services;
        final store = ReadingStore(services.storage(ReadingStore.space));
        final existing = await store.add(
          now: 100,
          title: 'Sin dibujo',
          body: 'Un texto anterior.',
          generated: true,
        );
        await store.markOpened(existing.id, 100);

        final completer = Completer<StoryDraft?>();
        final generator = _SlowStoryGenerator([completer]);

        await _pumpHome(
          tester,
          services: services,
          size: _viewports.first,
          withTabBar: true,
          generator: generator,
        );

        final existingFinder = find.byKey(
          ValueKey('library-book:${existing.id}'),
        );
        final existingLeftBefore = tester.getRect(existingFinder).left;

        await tester.tap(find.byKey(const Key('library-write-story')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('library-write-story-submit')));
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.move);

        completer.complete(const StoryDraft('La casa', 'La casa es azul.'));
        await tester.pump();
        await tester.pump();

        // Sheet slides down over pageOut (200ms): mid-way at 100ms, gone by 201ms.
        await tester.pump(NocheMotion.pageOut ~/ 2);
        final surface = tester.widget<FractionalTranslation>(
          find.byKey(const ValueKey('noche_sheet_surface')),
        );
        expect(surface.translation.dy, greaterThan(0.0));
        expect(surface.translation.dy, lessThan(1.0));
        expect(find.text('La casa'), findsNothing);
        expect(tester.getRect(existingFinder).left, existingLeftBefore);

        await tester.pump(
          NocheMotion.pageOut ~/ 2 + const Duration(milliseconds: 1),
        );
        await tester.pump();
        expect(find.byType(NocheSheet), findsNothing);
        expect(find.text('La casa'), findsNothing);
        expect(tester.getRect(existingFinder).left, existingLeftBefore);

        // Pump past 260ms (remaining 59ms) -> insertion starts; travel partway at move ~/ 2.
        await tester.pump(const Duration(milliseconds: 59));
        await tester.pump();
        final newStory = store.texts().firstWhere((t) => t.title == 'La casa');
        expect(newStory.isNew, isTrue);

        await tester.pump(NocheMotion.move ~/ 2);
        final existingLeftMid = tester.getRect(existingFinder).left;
        expect(existingLeftMid, greaterThan(existingLeftBefore));
        expect(existingLeftMid, lessThan(existingLeftBefore + 116));

        final insertOpacityFinder = find.byKey(
          ValueKey('library-story-insert-opacity:${newStory.id}'),
        );
        expect(tester.widget<Opacity>(insertOpacityFinder).opacity, 0.0);

        // At 260ms + 160ms + move ~/ 2: new story is mid-fade (0 < opacity < 1).
        await tester.pump(LibraryMotion.shelfInsertFadeDelay);
        final midOpacity = tester.widget<Opacity>(insertOpacityFinder).opacity;
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        // Finish insertion and settle.
        await tester.pump(NocheMotion.move);
        await tester.pumpAndSettle();

        // Stayed on Library; order is [open slot, new story, existing story].
        expect(rig.nav.routes, isEmpty);
        expect(find.byType(NocheTabBar), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(ValueKey('library-book:${newStory.id}')),
            matching: find.byType(OverflowBox),
          ),
          findsOneWidget,
        );

        final slotRect = tester.getRect(
          find.byKey(const Key('library-write-story')),
        );
        final newRect = tester.getRect(
          find.byKey(ValueKey('library-book:${newStory.id}')),
        );
        final existingRectAfter = tester.getRect(existingFinder);
        expect(slotRect.left, lessThan(newRect.left));
        expect(newRect.left, lessThan(existingRectAfter.left));
        expect(existingRectAfter.left, closeTo(existingLeftBefore + 116, 0.5));

        // NEW badge renders with ground fill and labelStrong style.
        final badgeFinder = find.byKey(
          Key('library-story-new-tag:${newStory.id}'),
        );
        expect(badgeFinder, findsOneWidget);
        final badgeContainer = tester.widget<Container>(badgeFinder);
        expect(
          (badgeContainer.decoration as BoxDecoration).color,
          NocheColors.ground,
        );
        final badgeText = tester.widget<Text>(
          find.descendant(
            of: badgeFinder,
            matching: find.text(LibraryWording.newStoryTag.toUpperCase()),
          ),
        );
        expect(badgeText.style?.fontWeight, NocheType.labelStrong.fontWeight);
        expect(badgeText.style?.fontSize, NocheType.labelStrong.fontSize);

        // Tapping the new story navigates to BookRoute and removes the NEW tag.
        await tester.tap(find.byKey(ValueKey('library-book:${newStory.id}')));
        await settle(tester);
        expect(rig.nav.routes, [BookRoute(newStory.id)]);
        expect(badgeFinder, findsNothing);
        expect(store.text(newStory.id)?.isNew, isFalse);
      },
    );

    testWidgets(
      'honours disableAnimations: true with static dots at opacity 1.0 and instant space + quick fade-in on shelf',
      (tester) async {
        final rig = Rig();
        _learnWords(rig.store, ['la', 'casa', 'es', 'azul']);
        final services = rig.services;
        final store = ReadingStore(services.storage(ReadingStore.space));
        final existing = await store.add(
          now: 100,
          title: 'Sin dibujo',
          body: 'Un texto anterior.',
          generated: true,
        );
        await store.markOpened(existing.id, 100);

        final completer = Completer<StoryDraft?>();
        final generator = _SlowStoryGenerator([completer]);

        await _pumpHome(
          tester,
          services: services,
          size: _viewports.first,
          disableAnimations: true,
          generator: generator,
        );

        final existingFinder = find.byKey(
          ValueKey('library-book:${existing.id}'),
        );
        final existingLeftBefore = tester.getRect(existingFinder).left;

        await tester.tap(find.byKey(const Key('library-write-story')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('library-write-story-submit')));
        await tester.pump();
        await tester.pump(NocheMotion.swapAfter + NocheMotion.quick);

        // Three dots stay static at opacity 1.0 across multiple frames.
        for (final step in [
          Duration.zero,
          const Duration(milliseconds: 150),
          const Duration(milliseconds: 300),
        ]) {
          if (step != Duration.zero) await tester.pump(step);
          for (var i = 0; i < 3; i++) {
            expect(
              tester
                  .widget<Opacity>(
                    find.byKey(ValueKey<String>('library-writing-dot-$i')),
                  )
                  .opacity,
              1.0,
            );
          }
        }

        completer.complete(const StoryDraft('La casa', 'La casa es azul.'));
        await tester.pump();
        await tester.pump(LibraryMotion.shelfInsertAfter);
        await tester.pump();

        final newStory = store.texts().firstWhere((t) => t.title == 'La casa');
        final insertOpacityFinder = find.byKey(
          ValueKey('library-story-insert-opacity:${newStory.id}'),
        );

        // Space opens immediately (no travel of existing stories), new story fades in over quick.
        expect(
          tester.getRect(existingFinder).left,
          closeTo(existingLeftBefore + 116, 0.5),
        );
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOpacity = tester.widget<Opacity>(insertOpacityFinder).opacity;
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        await tester.pump(NocheMotion.quick);
        await tester.pumpAndSettle();
        expect(
          find.byKey(Key('library-story-new-tag:${newStory.id}')),
          findsOneWidget,
        );
      },
    );
  });
}
