// Order 27: the Biblioteca redesign. The "Hear next" card, the grey line under each place, a cover on every book,
// compact rows, the way to the map when nothing is played, and the shelf at both phone sizes, with the text-size
// setting and with reduce motion.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/shelf_row.dart';
import 'package:feature_library/src/strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

ShelfEntry entry(WidgetTester tester, String title) => tester
    .widgetList<ShelfEntry>(find.byType(ShelfEntry))
    .firstWhere((e) => e.title == title);

ShelfNextCard card(WidgetTester tester) =>
    tester.widget<ShelfNextCard>(find.byType(ShelfNextCard));

Finder rowNamed(String title) =>
    find.byWidgetPredicate((w) => w is ShelfEntry && w.title == title);

void main() {
  setUpAll(makeTestPicture);

  group('Hear next', () {
    testWidgets('no card when nothing is on the shelf', (tester) async {
      await pumpShelf(tester, Rig());
      expect(find.byType(ShelfNextCard), findsNothing);
    });

    testWidgets(
      'names the story heard least; of those, the one played last; a listen here counts too',
      (tester) async {
        final clock = FakeClock();
        final rig = Rig(progress: FakeProgressStore(clock: clock));
        rig.played(['uno']);
        clock.advance(const Duration(days: 1));
        rig.played(['cuatro']);
        clock.advance(const Duration(days: 1));
        rig.played(['dos', 'dos']); // heard twice
        // La casa is not finished (tres is not played): nothing on the shelf is new
        await pumpShelf(tester, rig);
        // uno and cuatro are heard once each; cuatro was played last
        expect(card(tester).title, 'Cuatro');
        expect(
          card(tester).subtitle,
          '${LibraryStrings.heardLeast} · about 5 min',
        );
        rig.store.listened('cuatro');
        await settle(tester);
        expect(card(tester).title, 'Uno');
      },
    );

    testWidgets(
      'a story never heard (a picture story of a finished place) comes first, and says it is new',
      (tester) async {
        final rig = Rig()..played(['uno', 'dos', 'tres']);
        await pumpShelf(tester, rig, size: const Size(390, 844), ratio: 2);
        expect(card(tester).title, 'Dibujo uno');
        expect(
          card(tester).subtitle,
          '${LibraryStrings.newOnShelf} · about 3 min',
        );
        expect(
          find.descendant(
            of: find.byType(ShelfNextCard),
            matching: find.text(LibraryStrings.hearNext.toUpperCase()),
          ),
          findsOneWidget,
        );
        // the card is above the first place
        expect(
          tester.getRect(find.byType(ShelfNextCard)).bottom,
          lessThan(tester.getRect(find.text('La casa')).top),
        );
      },
    );

    testWidgets(
      'its Listen is the only green button on the shelf, and goes where the row\'s Listen goes',
      (tester) async {
        final rig = Rig()..played(['uno', 'dos', 'tres']);
        await pumpShelf(tester, rig, size: const Size(412, 1800));
        final green = [
          ...tester
              .widgetList<ShelfButton>(find.byType(ShelfButton))
              .where((b) => b.kind == ShelfButtonKind.go),
          ...tester
              .widgetList<PlayButton>(find.byType(PlayButton))
              .where((b) => !b.quiet),
        ];
        expect(green, hasLength(1));
        await tester.tap(nextButtonOf('Listen', 'Dibujo uno'));
        expect(rig.nav.last, const StoryRoute('d-uno'));
        await tester.tap(buttonOf('Listen', 'Dibujo uno'));
        expect(rig.nav.last, const StoryRoute('d-uno'));
        expect(rig.haptics.ticks, 2);
      },
    );

    testWidgets('Read on the card only for a book that reads well', (
      tester,
    ) async {
      final rig = Rig()..played(['dos']); // lee:false
      await pumpShelf(tester, rig);
      expect(card(tester).read, isNull);
      final rig2 = Rig()..played(['uno'], read: ['uno']);
      await pumpShelf(tester, rig2);
      expect((card(tester).read! as ShelfButton).check, isTrue);
      await tester.tap(nextButtonOf('Read again', 'Uno'));
      expect(rig2.nav.last, const BookRoute('uno'));
      expect(rig2.clips.unlocked, isTrue);
    });

    testWidgets('a routine on the card has the plain tile and no Read', (
      tester,
    ) async {
      final rig = Rig()..played(['uno', 'dos', 'tres']);
      rig.store.listened('d-uno');
      await pumpShelf(tester, rig);
      expect(card(tester).title, 'Haz uno');
      expect(card(tester).cover, isNull);
      expect(card(tester).read, isNull);
    });
  });

  group('the place line', () {
    testWidgets(
      'under each place: stories played of its stories, books read of its books on the shelf that read well',
      (tester) async {
        final rig = Rig()
          ..played(['uno', 'dos', 'tres', 'cuatro'], read: ['uno']);
        await pumpShelf(tester, rig, size: const Size(412, 1800));
        // La casa: uno, tres and d-uno read well (dos does not; a routine has no book)
        const casaLine = '3 of 3 stories played · 1 of 3 books read';
        expect(find.text(casaLine), findsOneWidget);
        // El parque: cuatro reads well; cinco is not played
        expect(
          find.text('1 of 2 stories played · 0 of 1 book read'),
          findsOneWidget,
        );
        // the line is under the place's name and above its first row
        final casa = tester.getRect(find.text('La casa'));
        final line = tester.getRect(find.text(casaLine));
        final uno = tester.getRect(rowNamed('Uno'));
        expect(line.top, greaterThan(casa.bottom));
        expect(line.bottom, lessThan(uno.top));
      },
    );

    testWidgets('no book on the shelf that reads well: no second half', (
      tester,
    ) async {
      final rig = Rig()..played(['dos']);
      await pumpShelf(tester, rig);
      expect(find.text('1 of 3 stories played'), findsOneWidget);
    });

    test('one story, one book', () {
      expect(
        LibraryStrings.placeLine(played: 1, stories: 1, read: 1, books: 1),
        '1 of 1 story played · 1 of 1 book read',
      );
    });
  });

  testWidgets(
    'every row with a book has its first page as cover; a routine has the plain tile with a speaker',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos', 'tres']);
      await pumpShelf(tester, rig, size: const Size(412, 1800));
      for (final t in ['Uno', 'Dos', 'Tres', 'Dibujo uno']) {
        expect(entry(tester, t).cover, isNotNull, reason: t);
      }
      expect(rig.images.asked, contains('libros/img/dos-1.png?v=39'));
      expect(entry(tester, 'Haz uno').cover, isNull);
      final tile = find.descendant(
        of: rowNamed('Haz uno'),
        matching: find.byType(ShelfCover),
      );
      expect(
        find.descendant(of: tile, matching: find.byType(CoquiIcon)),
        findsOneWidget,
      );
    },
  );

  testWidgets('nothing played: the plain line and a button to the map', (
    tester,
  ) async {
    final rig = Rig();
    await pumpShelf(tester, rig);
    expect(find.text(LibraryStrings.emptyShelf), findsOneWidget);
    await tester.tap(find.text(LibraryStrings.openMap));
    expect(rig.nav.last, const TabRoute(CoquiTabs.mapId));
    expect(rig.haptics.ticks, 1);
  });

  testWidgets(
    'rows are compact: a Listen-only row is at most 88 px, a row with Read at most 128',
    (tester) async {
      final rig = Rig()..played(['uno', 'dos']);
      await pumpShelf(tester, rig, size: const Size(390, 844), ratio: 2);
      expect(tester.getSize(rowNamed('Dos')).height, lessThanOrEqualTo(88));
      expect(tester.getSize(rowNamed('Uno')).height, lessThanOrEqualTo(128));
    },
  );

  testWidgets('the grey line wraps only between its parts', (tester) async {
    expect(
      keepTogether('Cuento con dibujos · about 2 min'),
      'Cuento con dibujos · about 2 min',
    );
    final rig = Rig()..played(['uno', 'dos', 'tres']);
    // a line that fits is written as it is
    await pumpShelf(tester, rig, size: const Size(412, 1800));
    expect(find.text('about 2 min'), findsOneWidget);
    // at twice the text size the picture story's line cannot fit: its parts stay whole
    await pumpShelf(tester, rig, size: const Size(390, 3000), textScale: 2);
    expect(
      find.text(keepTogether('${CoquiLabels.pictureStory} · about 3 min')),
      findsOneWidget,
    );
  });

  testWidgets(
    'both phones and 360 px, the text-size setting at 1.3 and 2, reduce motion: nothing overflows or leaves the screen',
    (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(412, 915),
        Size(360, 640),
      ]) {
        for (final scale in const [1.0, 1.3, 2.0]) {
          final rig = Rig()
            ..played(['uno', 'dos', 'tres', 'cuatro'], read: ['uno']);
          final services = fakeServices(
            progress: rig.progress,
            course: rig.course,
            clips: rig.clips,
            nav: rig.nav,
            haptics: rig.haptics,
            pictures: rig.pictures,
            reduceMotion: true,
          );
          await pumpShelf(
            tester,
            rig,
            size: size,
            ratio: 2,
            textScale: scale,
            services: services,
          );
          expect(tester.takeException(), isNull, reason: '$size x$scale');
          final scrolls = tester.widgetList<Scrollable>(
            find.byType(Scrollable),
          );
          expect(scrolls.every((s) => s.axis == Axis.vertical), isTrue);
          for (final e in [
            ...find.byType(ShelfNextCard).evaluate(),
            ...find.byType(ShelfEntry).evaluate(),
          ]) {
            final r = tester.getRect(find.byWidget(e.widget));
            expect(r.left, greaterThanOrEqualTo(0), reason: '$size x$scale');
            expect(
              r.right,
              lessThanOrEqualTo(size.width),
              reason: '$size x$scale',
            );
          }
        }
      }
    },
  );
}
