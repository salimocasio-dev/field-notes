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
      // Mapa, at the start: the streak of 5 and place 2, El parque; ten words due on the Up next card
      expect(app.selectedTab, 'map');
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);
      expect(find.text('10 words coming back · 6 min'), findsOneWidget);

      // Biblioteca: a story to make for his level; his shelf is empty (the course's stories are
      // replayed on the map, not listed here; "+ Add your own" stays hidden until #115 lands)
      await app.openTab('library');
      expect(app.selectedTab, 'library');
      await app.until(
        () => find.text('Write my story').evaluate().isNotEmpty,
        what: 'Biblioteca',
      );
      expect(byTypeName('ReadingHome').hitTestable(), findsOneWidget);
      if (find.text('+ Add your own').evaluate().isNotEmpty) {
        expect(find.text('+ Add your own').hitTestable(), findsOneWidget);
      }
      expect(
        find.text('Stories you make and books you add appear here.'),
        findsOneWidget,
      );
      expect(find.text('La lluvia'), findsNothing);

      // Palabras / Words: the real tab, with the seed's due words
      await app.openTab('words');
      expect(app.selectedTab, 'words');
      await app.until(
        () => find.text('Start review').evaluate().isNotEmpty,
        what: 'the words',
      );
      expect(byTypeName('WordsTab').hitTestable(), findsOneWidget);
      expect(find.text('Words').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('words-due-count')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('words come\nback today').hitTestable(), findsOneWidget);
      expect(find.text('Start review').hitTestable(), findsOneWidget);

      // Hablar / Speak: La casa is done in the seed, so its call is open and can start; El parque's is not open
      await app.openTab('speak');
      expect(app.selectedTab, 'speak');
      expect(find.text('De visita en la casa').hitTestable(), findsOneWidget);
      expect(find.text('Speak').hitTestable(), findsOneWidget);
      expect(find.text('Call Danny').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('speak-call-disc')).hitTestable(),
        findsOneWidget,
      );
      await app.tap(find.text('El parque'));
      final locked = find.text('Opens when you finish El parque').hitTestable();
      final afterStory = find.textContaining('after story').hitTestable();
      expect(
        locked.evaluate().isNotEmpty || afterStory.evaluate().isNotEmpty,
        isTrue,
      );

      // Yo / Me: the seed's minutes, words heard/good, and where he is
      await app.openTab('me');
      expect(app.selectedTab, 'me');
      expect(find.text('109').hitTestable(), findsOneWidget);
      expect(find.text('Me').hitTestable(), findsOneWidget);
      expect(
        find
            .descendant(
              of: find.byKey(const Key('me-skill-listening')),
              matching: find.text('0 of 78 good'),
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.text('A1 · place 2 of 10').hitTestable(), findsOneWidget);
      expect(find.text('El parque').hitTestable(), findsOneWidget);

      // back on the map: the same map, not made again (each tab is kept)
      await app.openTab('map');
      expect(
        find.text('10 words coming back · 6 min').hitTestable(),
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
      // the map opens scrolled to the frog: tap across the picture until a PlaceScreen opens
      final view = find.byType(PixelView).hitTestable();
      final rect = tester.getRect(view.first);
      final top = tester.getBottomLeft(findMapTopChips()).dy;
      final bottom = tester.getTopLeft(findMapUpNextCard()).dy;
      final placeTiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('story-tile-'),
      );
      var opened = false;
      final seen = <String>[];
      for (var y = bottom - 8; !opened && y > top; y -= 24) {
        for (var x = rect.left + 8; !opened && x < rect.right; x += 24) {
          await tester.tapAt(Offset(x, y));
          await tester.pump();
          await app.advance(400);
          final placeScreen = byTypeName('PlaceScreen').hitTestable();
          if (placeScreen.evaluate().isEmpty) continue;
          expect(app.tabBarShown, isTrue);
          expect(app.selectedTab, 'map');
          seen.add('PlaceScreen');
          opened = placeTiles.hitTestable().evaluate().isNotEmpty;
          if (!opened) {
            // a place with nothing to play (locked): go back to the map and go on
            await app.tap(find.byKey(const Key('place-back')).hitTestable());
            await app.advance(600);
          }
        }
      }
      expect(opened, isTrue, reason: 'no open place found; seen: $seen');
      await app.tap(placeTiles.hitTestable().first);
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(find.byType(NocheTabBar), findsNothing);
      expect(findStoryFrame(), findsOneWidget);
      expect(byTypeName('PlaceScreen').hitTestable(), findsNothing);
      expect(byTypeName('CoquiSheet').hitTestable(), findsNothing);
      await app.tap(findStoryCloseButton());
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(findStoryFrame(), findsNothing);
      expect(
        find.text('10 words coming back · 6 min').hitTestable(),
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
      await again.tap(findReviewCloseButton());
      await again.settle(rounds: 5);
      expect(again.selectedTab, 'map');

      // on a tab, the system back is not the app's: it leaves
      expect(await tester.binding.handlePopRoute(), isFalse);
    },
  );
}
