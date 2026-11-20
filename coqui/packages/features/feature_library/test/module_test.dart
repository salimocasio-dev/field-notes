// The module and the dev entry.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/images.dart';
import 'package:feature_library/src/reader.dart';
import 'package:feature_library/src/shelf.dart';
import 'package:feature_library/src/shelf_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/dev_main.dart';
import 'support.dart';

void main() {
  setUpAll(makeTestPicture);

  test('the module is library: one tab, and the screen of a book', () {
    final rig = Rig();
    const m = LibraryModule();
    expect(m.id, 'library');
    final tab = m.tab(rig.services)!;
    expect(tab.id, 'library');
    expect(tab.label, CoquiLabels.library);
    expect(
      m.screenFor(const BookRoute('uno'), rig.services),
      isA<BookReader>(),
    );
  });

  test('the module answers the book route and no other', () {
    final rig = Rig();
    const m = LibraryModule();
    for (final r in <AppRoute>[
      const StoryRoute('uno'),
      const StoryRoute('uno', listen: true),
      const ReviewRoute(),
      const LevelCheckRoute(),
      const CallRoute('casa'),
      const VoiceTestRoute(),
      const TabRoute('library'),
    ]) {
      expect(m.screenFor(r, rig.services), isNull, reason: '$r');
    }
  });

  test('the books\' pictures are asked for at the old site\'s relative path with its version tag, or where the shell says', () {
    expect(defaultBookImageUrl('img/uno-1.png'), 'libros/img/uno-1.png?v=39');
    final rig = Rig();
    final asked = <String>[];
    final m = LibraryModule(
      imageUrl: (p) => 'https://site.example/books/$p',
      imageProvider: (url) {
        asked.add(url);
        return rig.images.provider(url);
      },
    );
    final reader =
        m.screenFor(const BookRoute('uno'), rig.services)! as BookReader;
    expect(
      reader.imageUrl('img/uno-1.png'),
      'https://site.example/books/img/uno-1.png',
    );
    expect(reader.imageProvider('https://x/y.png'), isNotNull);
    expect(asked, ['https://x/y.png']);
    final shelf = m.tab(rig.services)!;
    expect(shelf, isNotNull);
  });

  testWidgets(
    'the shelf and the reader use the shell\'s address for a picture',
    (tester) async {
      final rig = Rig()..played(['uno']);
      final asked = <String>[];
      final m = LibraryModule(
        imageUrl: (p) => 'https://site.example/books/$p',
        imageProvider: (url) {
          asked.add(url);
          return rig.images.provider(url);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (c) => m.tab(rig.services)!.builder(c)),
        ),
      );
      await settle(tester);
      expect(asked, contains('https://site.example/books/img/uno-1.png'));
      asked.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) => m.screenFor(const BookRoute('uno'), rig.services)!,
          ),
        ),
      );
      await settle(tester);
      expect(asked, contains('https://site.example/books/img/uno-1.png'));
      expect(asked, contains('https://site.example/books/img/uno-2.png'));
    },
  );

  group('the dev entry (on the fakes)', () {
    testWidgets(
      'opens on the shelf of the sample course with the progress of a reference state',
      (tester) async {
        await tester.pumpWidget(devApp());
        await settle(tester);
        expect(find.byType(LibraryShelf), findsOneWidget);
        expect(
          find.text(CoquiLabels.library),
          findsWidgets,
        ); // the title and the tab bar's label
        // the seed "curso" has played the sample's three stories: a row each (order 27: one of them is also
        // named by the "Hear next" card, so the titles are looked for in the rows)
        Finder row(String t) => find.descendant(
          of: find.byType(ShelfEntry),
          matching: find.text(t),
        );
        expect(row('La lluvia'), findsOneWidget);
        expect(row('El bizcocho'), findsOneWidget);
        expect(row('¿Dónde está el pájaro?'), findsOneWidget);
      },
    );

    testWidgets('the empty state shows the plain line', (tester) async {
      await tester.pumpWidget(devApp(options: const DevOptions(seed: 'vacio')));
      await settle(tester);
      expect(
        find.text(
          'Play a story on the map. You can hear it again here and read it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Read opens the reader and Biblioteca comes back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915) * 2.625;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devApp());
      await settle(tester);
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) =>
                  w.runtimeType.toString() == 'ShelfButton' &&
                  (w as dynamic).label == 'Read',
            )
            .first,
      );
      await settle(tester);
      expect(find.byType(BookReader), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is LessonIconButton && w.semanticLabel == 'Close',
        ),
      );
      await settle(tester);
      expect(find.byType(LibraryShelf), findsOneWidget);
    });

    testWidgets('an address can start on a page of a book', (tester) async {
      tester.view.physicalSize = const Size(412, 915) * 2.625;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        devApp(
          options: DevOptions.fromQuery(const {
            'screen': 'book',
            'book': 'la-lluvia',
            'page': '5',
            'speed': '40',
          }),
        ),
      );
      await settle(tester);
      expect(find.text('5 / 9'), findsOneWidget);
    });

    test('the address says which state', () {
      final o = DevOptions.fromQuery(const {
        'seed': 'casi',
        'screen': 'book',
        'book': 'd-toc-toc',
        'page': '6',
        'hold': '3',
        'speed': '40',
        'big': '1',
        'card': '1',
        'scroll': 'end',
        'tab': '0',
        'content': 'real',
      });
      expect(
        (
          o.seed,
          o.screen,
          o.book,
          o.page,
          o.hold,
          o.speed,
          o.big,
          o.card,
          o.scrollEnd,
          o.tabBar,
          o.real,
        ),
        (
          'casi',
          'book',
          'd-toc-toc',
          6,
          3,
          40.0,
          true,
          true,
          true,
          false,
          true,
        ),
      );
      final d = DevOptions.fromQuery(const {});
      expect(
        (d.seed, d.screen, d.page, d.hold, d.tabBar, d.real),
        ('curso', 'shelf', 1, null, true, false),
      );
    });
  });
}
