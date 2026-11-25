// The tabs with a stored progress, a lesson opened from the map and closed, the system back.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    '(b) the mid-course progress: each of the five tabs opens and shows it',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      // Mapa, at the start: the streak of 5 and place 2, El parque; ten words due on the Today card
      expect(app.selectedTab, 'map');
      expect(find.text('5 days'), findsOneWidget);
      expect(
        find.text(isNocheMap() ? 'You are here' : '2 · El parque'),
        findsOneWidget,
      );
      expect(find.text('10 words coming back · 6 min'), findsOneWidget);

      // Biblioteca: a story to make for his level; his shelf is empty (the course's stories are
      // replayed on the map, not listed here; "+ Add your own" stays hidden until N5.4)
      await app.openTab('library');
      expect(app.selectedTab, 'library');
      await app.until(
        () => find.text('Write my story').evaluate().isNotEmpty,
        what: 'Biblioteca',
      );
      expect(byTypeName('ReadingHome').hitTestable(), findsOneWidget);
      expect(find.text('+ Add your own'), findsNothing);
      expect(
        find.text('Stories you make and books you add appear here.'),
        findsOneWidget,
      );
      expect(find.text('La lluvia'), findsNothing);

      // Palabras / Words: the real tab, with the seed's due words (N4.4 Noche WordsTab or pre-N4.4 Repaso card)
      await app.openTab('words');
      expect(app.selectedTab, 'words');
      await app.until(
        () =>
            find.text('Start review').evaluate().isNotEmpty ||
            find.text('Repaso').evaluate().isNotEmpty,
        what: 'the words',
      );
      expect(byTypeName('WordsTab').hitTestable(), findsOneWidget);
      if (find.text('Start review').evaluate().isNotEmpty) {
        expect(find.text('Words').hitTestable(), findsOneWidget);
        expect(
          find.byKey(const Key('words-due-count')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.text('words come\nback today').hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Start review').hitTestable(), findsOneWidget);
      } else {
        expect(
          find.text('10 words today · about 2 min').hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Start').hitTestable(), findsOneWidget);
        expect(find.text('casa').hitTestable(), findsOneWidget);
      }

      // Hablar: La casa is done in the seed, so its call is Up next and can start; El parque's is not open
      await app.openTab('speak');
      expect(app.selectedTab, 'speak');
      expect(find.text('De visita en la casa').hitTestable(), findsOneWidget);
      expect(find.text('Start call').hitTestable(), findsOneWidget);
      await app.tap(find.text('El parque'));
      expect(
        find.text('Opens when you finish El parque').hitTestable(),
        findsOneWidget,
      );

      // Yo: the seed's streak, minutes and words heard, and where he is
      await app.openTab('me');
      expect(app.selectedTab, 'me');
      expect(find.text('109').hitTestable(), findsOneWidget);
      expect(find.text('78').hitTestable(), findsOneWidget);
      expect(
        find.text('A1 · place 2 of 10 · El parque').hitTestable(),
        findsOneWidget,
      );

      // back on the map: the same map, not made again (each tab is kept)
      await app.openTab('map');
      expect(
        (isNocheMap()
                ? find.text('10 words coming back · 6 min')
                : find.text('2 · El parque'))
            .hitTestable(),
        findsOneWidget,
      );
      // the tab bar ticks on each tab tap (app.html, ver: tick())
      expect(app.haptics.ticks, greaterThanOrEqualTo(5));
    },
  );

  testWidgets(
    '(c) tap a place, tap a story row: the story, the tab bar hidden; its X returns to the map with the bar back',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      // the map opens scrolled to the frog: tap across the picture until a place opens
      // (either N4.2 PlaceScreen or legacy CoquiSheet)
      final view = find.byType(PixelView).hitTestable();
      final rect = tester.getRect(view.first);
      final top = tester.getBottomLeft(findMapTopChips()).dy;
      final bottom = tester.getTopLeft(findMapUpNextCard()).dy;
      final sheetRows = find.descendant(
        of: find.byType(CoquiSheet),
        matching: find.byType(PlayButton),
      );
      final placeTiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('story-tile-'),
      );
      var opened = false;
      var openedAsPlaceScreen = false;
      final seen = <String>[];
      for (var y = bottom - 8; !opened && y > top; y -= 24) {
        for (var x = rect.left + 8; !opened && x < rect.right; x += 24) {
          await tester.tapAt(Offset(x, y));
          await tester.pump();
          await app.advance(400);
          final placeScreen = byTypeName('PlaceScreen').hitTestable();
          if (placeScreen.evaluate().isNotEmpty) {
            expect(app.tabBarShown, isTrue);
            expect(app.selectedTab, 'map');
            seen.add('PlaceScreen');
            opened = placeTiles.hitTestable().evaluate().isNotEmpty;
            if (opened) {
              openedAsPlaceScreen = true;
            } else {
              // a place with nothing to play (locked): go back to the map and go on
              await app.tap(find.byKey(const Key('place-back')).hitTestable());
              await app.advance(600);
            }
            continue;
          }
          // legacy CoquiSheet fallback (pre-N4.2 main): the welcome's own sheet is always there, closed
          final sheet = find.byType(CoquiSheet).hitTestable();
          if (sheet.evaluate().isEmpty) continue;
          seen.add('${tester.widget<CoquiSheet>(sheet.first).title}');
          opened = sheetRows.evaluate().isNotEmpty;
          if (!opened) {
            // a place with nothing to play (locked): close it and go on
            await app.tap(find.byType(CoquiCloseButton).hitTestable().first);
            await app.advance(600);
          }
        }
      }
      expect(opened, isTrue, reason: 'no open place found; seen: $seen');
      await app.tap(
        openedAsPlaceScreen ? placeTiles.hitTestable().first : sheetRows.first,
      );
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(find.byType(NocheTabBar), findsNothing);
      expect(find.byType(LessonFrame), findsOneWidget);
      expect(byTypeName('PlaceScreen').hitTestable(), findsNothing);
      expect(find.byType(CoquiSheet).hitTestable(), findsNothing);
      await app.tap(find.byType(LessonCloseButton));
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(find.byType(LessonFrame), findsNothing);
      expect(
        (isNocheMap()
                ? find.text('10 words coming back · 6 min')
                : find.text('2 · El parque'))
            .hitTestable(),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '(j) the system back from a lesson returns to the tab that opened it; on a tab it leaves the app',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      await app.openTab('me');
      await app.go(const LevelCheckRoute());
      expect(app.lessonShown, isTrue);
      expect(byTypeName('LevelCheckScreen'), findsOneWidget);
      final handled = await tester.binding.handlePopRoute();
      await app.settle(rounds: 5);
      expect(handled, isTrue);
      expect(byTypeName('LevelCheckScreen'), findsNothing);
      expect(app.selectedTab, 'me');

      // from a story opened on Hablar, Next goes on and the system back still returns to Hablar
      await app.openTab('speak');
      await app.go(const StoryRoute('la-lluvia'));
      expect(app.lessonShown, isTrue);
      await app.go(const StoryRoute('el-bizcocho'));
      expect(app.lessonShown, isTrue);
      await tester.binding.handlePopRoute();
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'speak');

      // a lesson's address opened as it is (a reload): its X returns to the map
      await tester.pumpWidget(const SizedBox());
      final again = TestApp(tester);
      await again.open(stored: seed('curso'), location: '/nivel');
      expect(again.lessonShown, isTrue);
      expect(byTypeName('LevelCheckScreen'), findsOneWidget);
      await again.tap(find.byType(LessonCloseButton));
      await again.settle(rounds: 5);
      expect(again.selectedTab, 'map');

      // on a tab, the system back is not the app's: it leaves
      expect(await tester.binding.handlePopRoute(), isFalse);
    },
  );
}
