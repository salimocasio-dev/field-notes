import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show Rig, TestCourse, settle;

const List<Size> _viewports = [Size(390, 844), Size(412, 915)];

Future<void> _pumpHome(
  WidgetTester tester, {
  required Services services,
  required Size size,
  bool showAddYourOwn = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ReadingHome(services: services, showAddYourOwn: showAddYourOwn),
    ),
  );
  await settle(tester);
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

  group('ReadingHome empty shelf', () {
    for (final size in _viewports) {
      testWidgets(
        'renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          await _pumpHome(tester, services: rig.services, size: size);

          expect(tester.takeException(), isNull);
          expect(find.text('SPANISH'), findsOneWidget);
          expect(find.text('Library'), findsOneWidget);
          expect(find.text('+ Add your own'), findsNothing);
          expect(
            find.text('A NEW STORY AT YOUR LEVEL · ABOUT WHAT?'),
            findsOneWidget,
          );
          expect(find.text('Write my story'), findsOneWidget);
          expect(
            find.text('YOUR SHELF · READING COUNTS FROM A2'),
            findsOneWidget,
          );
          expect(find.text('All'), findsOneWidget);
          expect(find.text('Stories'), findsOneWidget);
          expect(find.text('Books'), findsOneWidget);
          expect(find.text('YouTube'), findsNothing);
          expect(
            find.text('Stories you make and books you add appear here.'),
            findsOneWidget,
          );
          expect(find.text('Continue reading'), findsNothing);
          expect(find.text('KEEP READING'), findsNothing);
        },
      );
    }
  });

  group('ReadingHome stories only', () {
    for (final size in _viewports) {
      testWidgets(
        'renders stories, scene/fallback, and filters at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          final services = rig.services;
          final store = ReadingStore(services.storage(ReadingStore.space));
          final withPair = await store.add(
            now: 100,
            title: 'La casa',
            body: 'La casa es azul.',
            generated: true,
          );
          final noPair = await store.add(
            now: 200,
            title: 'Sin dibujo',
            body: 'Un texto nuevo.',
            generated: true,
          );
          await store.markOpened(withPair.id, 300);
          await store.markOpened(noPair.id, 200);

          await _pumpHome(tester, services: services, size: size);

          expect(tester.takeException(), isNull);
          expect(find.text('Story'), findsNWidgets(2));
          expect(find.text('La casa'), findsOneWidget);
          expect(find.text('Sin dibujo'), findsOneWidget);
          expect(find.text('Continue reading'), findsNothing);
          expect(find.byType(NocheIcon), findsOneWidget);

          await tester.tap(find.text('Stories'));
          await settle(tester);
          expect(find.text('La casa'), findsOneWidget);
          expect(find.text('Sin dibujo'), findsOneWidget);

          await tester.tap(find.text('Books'));
          await settle(tester);
          expect(find.text('No books on your shelf yet.'), findsOneWidget);
          expect(find.text('La casa'), findsNothing);
        },
      );
    }
  });

  group('ReadingHome stories and books', () {
    for (final size in _viewports) {
      testWidgets(
        'orders by recent, filters, shows Keep reading, and hides when finished at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = Rig();
          final services = rig.services;
          final store = ReadingStore(services.storage(ReadingStore.space));
          final olderStory = await store.add(
            now: 100,
            title: 'Una casa',
            body: 'La casa es grande.',
            generated: true,
          );
          final activeBook = await store.add(
            now: 200,
            title: 'Cuentos de la isla',
            body: 'Uno. Dos. Tres. Cuatro. Cinco. Seis.',
            generated: false,
          );
          await store.markOpened(olderStory.id, 1000);
          await store.savePlace(
            activeBook.id,
            const ReadingPlace(page: 1, openedAt: 2000),
          );

          await _pumpHome(tester, services: services, size: size);

          expect(tester.takeException(), isNull);
          expect(find.text('Book'), findsOneWidget);
          expect(find.text('Story'), findsOneWidget);

          // Most recently opened (activeBook) appears before olderStory.
          final bookRect = tester.getRect(find.text('Book'));
          final storyRect = tester.getRect(find.text('Story'));
          expect(bookRect.left, lessThan(storyRect.left));

          // Covers: regular (90x120) on shelf + small (60x84) in Keep reading.
          final covers = tester
              .widgetList<NocheCover>(find.byType(NocheCover))
              .toList();
          expect(covers.map((c) => c.size).toSet(), {
            NocheCoverSize.regular,
            NocheCoverSize.small,
          });

          // Keep reading card details.
          expect(find.text('KEEP READING'), findsOneWidget);
          expect(
            find.text('Page 2 of 2 · 1 min left in the chapter'),
            findsOneWidget,
          );
          final progressBar = tester.widget<NocheProgressBar>(
            find.byType(NocheProgressBar),
          );
          expect(progressBar.value, 0.5);
          expect(find.text('Continue reading'), findsOneWidget);

          // Filter pills.
          await tester.tap(find.text('Stories'));
          await settle(tester);
          expect(find.text('Story'), findsOneWidget);
          expect(find.text('Book'), findsNothing);

          await tester.tap(find.text('Books'));
          await settle(tester);
          expect(find.text('Book'), findsOneWidget);
          expect(find.text('Story'), findsNothing);

          await tester.tap(find.text('All'));
          await settle(tester);
          expect(find.text('Book'), findsOneWidget);
          expect(find.text('Story'), findsOneWidget);

          // Continue reading navigates to BookRoute.
          await tester.tap(find.text('Continue reading'));
          await settle(tester);
          expect(rig.nav.routes.last, BookRoute(activeBook.id));

          // Mark finished -> Keep reading hides.
          await store.savePlace(
            activeBook.id,
            const ReadingPlace(page: 0, openedAt: 3000, finished: true),
          );
          await tester.pumpWidget(
            MaterialApp(home: ReadingHome(services: services)),
          );
          await settle(tester);
          expect(find.text('KEEP READING'), findsNothing);
          expect(find.text('Continue reading'), findsNothing);
        },
      );
    }
  });

  testWidgets('verified A2 hides reading counts from A2 suffix', (
    tester,
  ) async {
    final rig = Rig();
    rig.store.import(
      jsonEncode({
        ...rig.store.raw,
        'nivel': {'cefr': 'A2'},
      }),
    );
    await _pumpHome(tester, services: rig.services, size: _viewports.first);

    expect(find.text('YOUR SHELF'), findsOneWidget);
    expect(find.text('YOUR SHELF · READING COUNTS FROM A2'), findsNothing);
  });

  testWidgets(
    'showAddYourOwn displays + Add your own and navigates to ImportRoute',
    (tester) async {
      final rig = Rig();
      await _pumpHome(
        tester,
        services: rig.services,
        size: _viewports.first,
        showAddYourOwn: true,
      );

      expect(find.text('+ Add your own'), findsOneWidget);
      await tester.tap(find.text('+ Add your own'));
      await settle(tester);
      expect(rig.nav.routes, [const ImportRoute()]);
    },
  );

  testWidgets(
    'RTL course mirrors layout, shows englishName, and keeps scene picture LTR',
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
      await store.markOpened(story.id, 100);

      const module = LibraryModule();
      expect(module.tab(services).label, 'المكتبة');

      await _pumpHome(tester, services: services, size: _viewports.first);

      expect(tester.takeException(), isNull);
      expect(find.text('ARABIC'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);

      final libraryText = find.text('Library');
      expect(Directionality.of(tester.element(libraryText)), TextDirection.rtl);

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
}
