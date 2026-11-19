// The shelf (Biblioteca): the checks of historia/tools/leer_check.py that are about it, and one test for each
// behaviour of app.html's `biblioteca` the script does not cover.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/shelf_row.dart';
import 'package:feature_library/src/strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

ShelfEntry entry(WidgetTester tester, String title) => tester
    .widgetList<ShelfEntry>(find.byType(ShelfEntry))
    .firstWhere((e) => e.title == title);

List<String> buttonLabels(WidgetTester tester, String title) => [
  for (final b in entry(tester, title).actions)
    if (b is ShelfButton) b.label,
];

Rect cardRect(WidgetTester tester, String title) {
  final row = find.byWidgetPredicate(
    (w) => w is ShelfEntry && w.title == title,
  );
  final rows = find.ancestor(of: row, matching: find.byType(DividedRows));
  // the card is the rows with 16 px of padding at each side
  return tester.getRect(rows.first).inflate(16);
}

void main() {
  setUpAll(makeTestPicture);

  testWidgets('leer_check: shelf empty: no rows, a plain line', (tester) async {
    final rig = Rig();
    await pumpShelf(tester, rig);
    expect(find.byType(ShelfEntry), findsNothing);
    expect(find.text(LibraryStrings.emptyShelf), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('leer_check: shelf lists only the played stories', (
    tester,
  ) async {
    final rig = Rig()..played(['uno', 'dos']);
    await pumpShelf(tester, rig);
    expect(rowTitles(tester), ['Uno', 'Dos']);
  });

  testWidgets('leer_check: shelf: grouped under the place name', (
    tester,
  ) async {
    final rig = Rig()..played(['uno', 'cuatro']);
    await pumpShelf(tester, rig);
    // an h2 for each place, in the order of the places, each above its own rows
    final casa = tester.getTopLeft(find.text('La casa'));
    final parque = tester.getTopLeft(find.text('El parque'));
    final uno = tester.getTopLeft(
      find.byWidgetPredicate((w) => w is ShelfEntry && w.title == 'Uno'),
    );
    final cuatro = tester.getTopLeft(
      find.byWidgetPredicate((w) => w is ShelfEntry && w.title == 'Cuatro'),
    );
    expect(casa.dy, lessThan(uno.dy));
    expect(uno.dy, lessThan(parque.dy));
    expect(parque.dy, lessThan(cuatro.dy));
  });

  testWidgets(
    'leer_check: shelf row: cover (first page), title, Listen and Read',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      expect(entry(tester, 'Uno').subtitle, 'about 2 min');
      expect(buttonLabels(tester, 'Uno'), ['Listen', 'Read']);
      // the cover is the book's first page, asked for with the old page's version tag
      expect(rig.images.asked, contains('libros/img/uno-1.png?v=39'));
      expect(
        find.descendant(
          of: find.byType(ShelfEntry),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('leer_check: shelf row: 48 px buttons', (tester) async {
    final rig = Rig()..played(['uno', 'tres']);
    await pumpShelf(tester, rig);
    for (final b in tester.widgetList<ShelfButton>(find.byType(ShelfButton))) {
      expect(tester.getSize(find.byWidget(b)).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets(
    'leer_check: shelf row: the Read button has a book icon, Listen a play icon, no bare check beside the title',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      final bs = entry(tester, 'Uno').actions.cast<ShelfButton>();
      expect(bs[0].icon, same(CoquiIcons.play));
      expect(bs[1].icon, same(CoquiIcons.read));
      expect(find.text(LibraryStrings.readCheck), findsNothing);
    },
  );

  testWidgets(
    'leer_check: shelf: Listen keeps the link (oir=1): a story is told straight through',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      await tester.tap(buttonOf('Listen', 'Uno'));
      expect(rig.nav.routes, [const StoryRoute('uno', listen: true)]);
      expect(rig.haptics.ticks, 1);
    },
  );

  testWidgets(
    'leer_check: shelf: Listen and Read sit inside the card (412, 390 and 360 px)',
    (tester) async {
      for (final w in [412.0, 390.0, 360.0]) {
        final rig = Rig()..played(['uno', 'tres'], read: ['uno']);
        await pumpShelf(tester, rig, size: Size(w, 800));
        final card = cardRect(tester, 'Uno');
        for (final b in tester.widgetList<ShelfButton>(
          find.byType(ShelfButton),
        )) {
          expect(
            tester.getRect(find.byWidget(b)).right,
            lessThanOrEqualTo(card.right - 16 + 1),
            reason: '$w px',
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('leer_check: shelf: the grey count line', (tester) async {
    final rig = Rig()..played(['uno']);
    await pumpShelf(tester, rig);
    // La casa: 2 stories to play, its picture story and routine; El parque: 2 stories
    expect(find.text('6 more open as you play the map'), findsOneWidget);
    final one = Rig()..played(['uno', 'dos', 'tres', 'cuatro']);
    await pumpShelf(tester, one);
    expect(find.text('1 more opens as you play the map'), findsOneWidget);
  });

  testWidgets(
    'leer_check: shelf: picture stories and routines of a finished place, Listen without oir',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres']);
      await pumpShelf(tester, rig);
      expect(rowTitles(tester), [
        'Uno',
        'Dos',
        'Tres',
        'Dibujo uno',
        'Haz uno',
      ]);
      expect(
        entry(tester, 'Dibujo uno').subtitle,
        'Cuento con dibujos · about 3 min',
      );
      await tester.tap(buttonOf('Listen', 'Dibujo uno'));
      expect(rig.nav.last, const StoryRoute('d-uno'));
    },
  );

  testWidgets(
    'leer_check: shelf: routines (Haz esto) show Listen only, no Read, no cover, the old link; no request for a routine\'s book',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres']);
      await pumpShelf(tester, rig, size: const Size(412, 1800));
      expect(buttonLabels(tester, 'Haz uno'), ['Listen']);
      expect(entry(tester, 'Haz uno').cover, isNull);
      expect(entry(tester, 'Haz uno').subtitle, 'Haz esto · about 1 min');
      await tester.tap(buttonOf('Listen', 'Haz uno'));
      expect(rig.nav.last, const StoryRoute('h-uno'));
      expect(rig.course.bookAsked, isNot(contains('h-uno')));
    },
  );

  testWidgets(
    'leer_check: shelf: a picture story of the finished place keeps its Read button when its book exists',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres']);
      await pumpShelf(tester, rig, size: const Size(412, 1800));
      expect(buttonLabels(tester, 'Dibujo uno'), ['Listen', 'Read']);
    },
  );

  testWidgets(
    'leer_check: shelf: a book whose verdict is lee:false shows Listen only and a plain cover tile (like a routine)',
    (tester) async {
      final rig = Rig()..played(['dos']);
      await pumpShelf(tester, rig);
      expect(buttonLabels(tester, 'Dos'), ['Listen']);
      expect(entry(tester, 'Dos').cover, isNull);
      // the tile is as wide as a cover and no less than 64 px
      final tile = find.descendant(
        of: find.byWidgetPredicate((w) => w is ShelfEntry && w.title == 'Dos'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(tile.first).width, greaterThanOrEqualTo(64));
    },
  );

  testWidgets(
    'leer_check: shelf: a book with lee:true has its cover and Read',
    (tester) async {
      final rig = Rig()..played(['tres']);
      await pumpShelf(tester, rig);
      expect(entry(tester, 'Tres').cover, isNotNull);
      expect(buttonLabels(tester, 'Tres'), ['Listen', 'Read']);
    },
  );

  testWidgets(
    'leer_check: Biblioteca: a read book\'s button says Read with a check, an unread one Read',
    (tester) async {
      final rig = Rig()..played(['uno', 'tres'], read: ['uno']);
      await pumpShelf(tester, rig);
      final uno = entry(tester, 'Uno').actions.cast<ShelfButton>()[1];
      final tres = entry(tester, 'Tres').actions.cast<ShelfButton>()[1];
      expect(uno.check, isTrue);
      expect(uno.semanticLabel, 'Read again: Uno');
      expect(tres.check, isFalse);
      expect(tres.semanticLabel, 'Read: Tres');
      expect(find.text(LibraryStrings.readCheck), findsOneWidget);
    },
  );

  testWidgets(
    'leer_check: the shelf shows the read check once the book was read (it is drawn again after a save)',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      expect(find.text(LibraryStrings.readCheck), findsNothing);
      rig.store.markRead('uno');
      await settle(tester);
      expect(find.text(LibraryStrings.readCheck), findsOneWidget);
    },
  );

  testWidgets(
    'leer_check: 390 px and 360 px: Read with its check sits beside Listen, inside the card',
    (tester) async {
      for (final w in [390.0, 360.0]) {
        final rig = Rig()..played(['uno'], read: ['uno']);
        await pumpShelf(tester, rig, size: Size(w, 800), textScale: 0.55);
        final listen = tester.getRect(buttonOf('Listen', 'Uno'));
        final read = tester.getRect(buttonOf('Read again', 'Uno'));
        expect(
          (listen.top - read.top).abs(),
          lessThan(2),
          reason: '$w px: one row',
        );
        expect(
          read.right,
          lessThanOrEqualTo(cardRect(tester, 'Uno').right - 16 + 1),
        );
      }
    },
  );

  testWidgets(
    'leer_check: a long shelf (rows under the tab bar): the 16 px fade shows at the top of the list and is gone at its end',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres', 'cuatro', 'cinco']);
      await pumpShelf(tester, rig, size: const Size(390, 600), ratio: 2);
      final fade = find.byType(ListFade);
      expect(tester.getSize(fade).height, 16);
      expect(tester.widget<ListFade>(fade).visible, isTrue);
      // it stands at the tab bar's edge
      expect(tester.getRect(fade).bottom, 600 - 72);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(tester.widget<ListFade>(fade).visible, isFalse);
    },
  );

  testWidgets(
    'leer_check: Biblioteca scrolled to its end: nothing under the tab bar or the Mapa disc',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres', 'cuatro']);
      await pumpShelf(tester, rig, size: const Size(390, 600), ratio: 2);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      final last = tester.getRect(
        find.text('1 more opens as you play the map'),
      );
      // the nav is 72 high and the disc stands 14 above it
      expect(last.bottom, lessThanOrEqualTo(600 - 72 - 14 - 8));
    },
  );

  testWidgets('leer_check: 360 px: shelf has no horizontal scroll', (
    tester,
  ) async {
    final rig = Rig()..played(['uno', 'tres'], read: ['uno']);
    await pumpShelf(tester, rig, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    final scrolls = tester.widgetList<Scrollable>(find.byType(Scrollable));
    expect(scrolls.every((s) => s.axis == Axis.vertical), isTrue);
    // and the cover is the 64 px one
    expect(ShelfEntry.coverWidth(360), 64);
  });

  // ---- behaviours of `biblioteca` the script does not cover

  testWidgets(
    'biblioteca: "Heard N×" shows how many times a story was listened to',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos']);
      rig.store.listened('uno');
      rig.store.listened('uno');
      await pumpShelf(tester, rig);
      expect(entry(tester, 'Uno').subtitle, 'Heard 2× · about 2 min');
      expect(entry(tester, 'Dos').subtitle, 'about 3 min');
    },
  );

  testWidgets('biblioteca: Read ticks, opens the sound, and goes to the book', (
    tester,
  ) async {
    final rig = Rig()..played(['uno']);
    await pumpShelf(tester, rig);
    await tester.tap(buttonOf('Read', 'Uno'));
    expect(rig.nav.routes, [const BookRoute('uno')]);
    expect(rig.haptics.ticks, 1);
    expect(rig.clips.unlocked, isTrue);
  });

  testWidgets(
    'biblioteca: the "todo" setting opens every place\'s picture stories and routines',
    (tester) async {
      final rig = Rig()..played(['cuatro']);
      rig.store.setSetting('todo', 1);
      await pumpShelf(tester, rig);
      // La casa has none of its stories played, but it is open: its picture story and routine show
      expect(rowTitles(tester), ['Dibujo uno', 'Haz uno', 'Cuatro']);
      // what is still closed: the three stories of La casa that are not played, and El parque's other one
      expect(find.text('4 more open as you play the map'), findsOneWidget);
    },
  );

  testWidgets(
    'biblioteca: the books are asked for once, not on every redraw (BOOKS)',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      rig.store.listened('uno');
      await settle(tester);
      rig.store.listened('uno');
      await settle(tester);
      expect(rig.course.bookAsked.where((b) => b == 'uno'), hasLength(1));
    },
  );

  testWidgets(
    'biblioteca: a book that cannot be fetched is a row with Listen only',
    (tester) async {
      final rig = Rig(course: _Failing())..played(['uno']);
      await pumpShelf(tester, rig);
      expect(buttonLabels(tester, 'Uno'), ['Listen']);
      expect(find.byType(ShelfEntry), findsOneWidget);
    },
  );

  testWidgets('biblioteca: a story the catalog does not know is not drawn', (
    tester,
  ) async {
    final course = TestCourse(
      metas: {'uno': StoryMeta(id: 'uno', title: 'Uno', minutes: 2)},
    );
    final rig = Rig(course: course)..played(['uno', 'dos']);
    await pumpShelf(tester, rig);
    expect(rowTitles(tester), ['Uno']);
  });

  testWidgets(
    'biblioteca: a picture that does not load leaves the grey tile (onerror removes the image)',
    (tester) async {
      final rig = Rig()..played(['uno']);
      rig.images.broken.add('libros/img/uno-1.png?v=39');
      await pumpShelf(tester, rig);
      expect(tester.takeException(), isNull);
      expect(buttonLabels(tester, 'Uno'), ['Listen', 'Read']);
      // nothing is drawn in the cover: the grey tile stays
      expect(
        find.descendant(
          of: find.byType(ShelfEntry),
          matching: find.byType(RawImage),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'biblioteca: a played story and an unplayed one are told apart by the progress store',
    (tester) async {
      final rig = Rig()..played(['uno']);
      await pumpShelf(tester, rig);
      expect(rig.progress.played('uno'), isTrue);
      expect(rig.progress.played('dos'), isFalse);
      expect(rowTitles(tester), ['Uno']);
    },
  );

  testWidgets(
    'biblioteca: a late load drops itself (a newer one is under way)',
    (tester) async {
      final slow = _Slow();
      final rig = Rig(course: slow)..played(['uno']);
      await pumpShelf(tester, rig); // its load waits for the first book
      expect(find.byType(ShelfEntry), findsNothing);
      rig.played(['dos']); // a newer load: it gets its books at once
      await settle(tester);
      expect(rowTitles(tester), ['Uno', 'Dos']);
      slow.first.complete(); // the old load arrives late
      await settle(tester);
      expect(rowTitles(tester), ['Uno', 'Dos']);
    },
  );
}

/// A course whose books cannot be fetched.
class _Failing extends TestCourse {
  @override
  Future<Book?> book(String id) async => throw StateError('no network');
}

/// A course whose first request for a book waits until the test lets it go.
class _Slow extends TestCourse {
  final Completer<void> first = Completer<void>();
  bool _asked = false;

  @override
  Future<Book?> book(String id) async {
    if (!_asked) {
      _asked = true;
      await first.future;
    }
    return super.book(id);
  }
}
