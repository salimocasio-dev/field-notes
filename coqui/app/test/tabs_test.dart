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
      expect(find.text('2 · El parque'), findsOneWidget);
      expect(find.text('10 words coming back · 6 min'), findsOneWidget);

      // Biblioteca: the real shelf, with what the seed has played (La casa's stories, each with its Listen) and what it
      // has heard (El jugo, once)
      await app.openTab('library');
      expect(app.selectedTab, 'library');
      await app.until(
        () => find.text('La lluvia').evaluate().isNotEmpty,
        what: 'the shelf',
      );
      expect(byTypeName('LibraryShelf').hitTestable(), findsOneWidget);
      expect(find.text('La casa').hitTestable(), findsOneWidget);
      expect(find.text('La lluvia').hitTestable(), findsOneWidget);
      expect(find.text('El jugo').hitTestable(), findsOneWidget);
      expect(find.text('Heard 1× · about 4 min').hitTestable(), findsOneWidget);
      expect(find.text('Listen').hitTestable(), findsWidgets);

      // Palabras: the real tab, with the seed's ten words due on its Repaso card and the words he has met, by place
      await app.openTab('words');
      expect(app.selectedTab, 'words');
      await app.until(
        () => find.text('Repaso').evaluate().isNotEmpty,
        what: 'the words',
      );
      expect(byTypeName('WordsTab').hitTestable(), findsOneWidget);
      expect(
        find.text('10 words today · about 2 min').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Start').hitTestable(), findsOneWidget);
      expect(find.text('casa').hitTestable(), findsOneWidget);

      // Hablar: La casa is done in the seed, so its call card is open; El parque's is not
      await app.openTab('speak');
      expect(app.selectedTab, 'speak');
      expect(find.text('La casa · about 5 min').hitTestable(), findsOneWidget);
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
      expect(find.text('2 · El parque').hitTestable(), findsOneWidget);
      // the tab bar ticks on each tab tap (app.html, ver: tick())
      expect(app.haptics.ticks, greaterThanOrEqualTo(5));
    },
  );

  testWidgets(
    '(c) tap a place, tap a story row: the story, the tab bar hidden; its X returns to the map with the bar back',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      // the map opens scrolled to the frog: tap across the picture until a place's sheet opens
      final view = find.byType(PixelView).hitTestable();
      final rect = tester.getRect(view.first);
      final top = tester.getBottomLeft(find.byType(MapChips)).dy;
      final bottom = tester.getTopLeft(find.byType(TodayCard)).dy;
      final rows = find.descendant(
        of: find.byType(CoquiSheet),
        matching: find.byType(PlayButton),
      );
      var opened = false;
      final seen = <String>[];
      for (var y = bottom - 8; !opened && y > top; y -= 24) {
        for (var x = rect.left + 8; !opened && x < rect.right; x += 24) {
          await tester.tapAt(Offset(x, y));
          await tester.pump();
          await app.advance(400);
          // the welcome's own sheet is always there, closed: a place's sheet is one that can be touched
          final sheet = find.byType(CoquiSheet).hitTestable();
          if (sheet.evaluate().isEmpty) continue;
          seen.add('${tester.widget<CoquiSheet>(sheet.first).title}');
          opened = rows.evaluate().isNotEmpty;
          if (!opened) {
            // a place with nothing to play (locked): close it and go on
            await app.tap(find.byType(CoquiCloseButton).hitTestable().first);
            await app.advance(600);
          }
        }
      }
      expect(opened, isTrue, reason: 'no open place found; sheets: $seen');
      await app.tap(rows.first);
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(find.byType(CoquiTabBar), findsNothing);
      expect(find.byType(LessonFrame), findsOneWidget);
      expect(find.byType(CoquiSheet).hitTestable(), findsNothing);
      await app.tap(find.byType(LessonCloseButton));
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(find.byType(LessonFrame), findsNothing);
      expect(find.text('2 · El parque').hitTestable(), findsOneWidget);
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
