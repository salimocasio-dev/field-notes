// The tabs under shell-owned keys, place -> story navigation, and system back.
import 'package:app/src/shell.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    '(b) each of the five tabs mounts under ShellKeys.tab, stays alive offstage, and ticks haptics',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      // Map tab at start
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');
      expect(findShellTab('map').hitTestable(), findsOneWidget);
      expect(findMapTopChips().hitTestable(), findsOneWidget);
      expect(findMapUpNextCard().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Library tab
      await app.openTab('library');
      expect(app.selectedTab, 'library');
      expect(findShellTab('library').hitTestable(), findsOneWidget);
      expect(findShellTab('map').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);

      // Words tab
      await app.openTab('words');
      expect(app.selectedTab, 'words');
      expect(findShellTab('words').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('words-due-count')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Speak tab
      await app.openTab('speak');
      expect(app.selectedTab, 'speak');
      expect(findShellTab('speak').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('speak-next-call-card')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Me tab
      await app.openTab('me');
      expect(app.selectedTab, 'me');
      expect(findShellTab('me').hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('me-scroll')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('yo-level-check')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Back on map: all five tabs remain mounted (four offstage, map visible)
      await app.openTab('map');
      expect(app.selectedTab, 'map');
      expect(findShellTab('map').hitTestable(), findsOneWidget);
      for (final id in NocheTabs.order) {
        expect(
          findShellTab(id, skipOffstage: false),
          findsOneWidget,
          reason: 'tab $id stays alive offstage',
        );
      }
      expect(tester.takeException(), isNull);
      // the tab bar ticks on each tab tap (app.html, ver: tick())
      expect(app.haptics.ticks, greaterThanOrEqualTo(5));
    },
  );

  testWidgets(
    '(c) place -> story hides the tab bar and mounts under ShellKeys.route; system back pops story -> place -> map with the bar back',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      await app.go(const PlaceRoute('casa'));
      expect(findShellRoute(const PlaceRoute('casa')), findsOneWidget);
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');

      final storyTile = find.byKey(const Key('story-tile-la-lluvia'));
      expect(storyTile, findsOneWidget);
      await tester.ensureVisible(storyTile);
      await app.tap(storyTile);
      await app.until(
        () => findStoryStartButton().evaluate().isNotEmpty && !app.tabBarShown,
        what: 'story start disc and tab bar sink',
      );

      expect(findShellRoute(const StoryRoute('la-lluvia')), findsOneWidget);
      expect(findShellRoute(const PlaceRoute('casa')), findsNothing);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(findStoryStartButton(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final firstHandled = await tester.binding.handlePopRoute();
      await app.settle(rounds: 10);
      expect(firstHandled, isTrue);
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');
      expect(findShellRoute(const StoryRoute('la-lluvia')), findsNothing);
      expect(findShellRoute(const PlaceRoute('casa')), findsOneWidget);
      expect(find.byKey(const Key('place-back')), findsOneWidget);
      expect(tester.takeException(), isNull);

      final secondHandled = await tester.binding.handlePopRoute();
      await app.settle(rounds: 10);
      expect(secondHandled, isTrue);
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');
      expect(findShellRoute(const PlaceRoute('casa')), findsNothing);
      expect(findShellTab('map').hitTestable(), findsOneWidget);
      expect(findMapUpNextCard().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(j) system back from a lesson returns to the tab that opened it, direct reload returns to map, and switching tabs leaves a lesson',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      await app.openTab('me');
      await app.go(const LevelCheckRoute());
      expect(app.lessonShown, isTrue);
      expect(findShellRoute(const LevelCheckRoute()), findsOneWidget);
      final handled = await tester.binding.handlePopRoute();
      await app.settle(rounds: 5);
      expect(handled, isTrue);
      expect(findShellRoute(const LevelCheckRoute()), findsNothing);
      expect(app.selectedTab, 'me');
      expect(findShellTab('me').hitTestable(), findsOneWidget);

      // from a story opened on Speak, going to another story still returns to Speak on back
      await app.openTab('speak');
      await app.go(const StoryRoute('la-lluvia'));
      expect(app.lessonShown, isTrue);
      expect(findShellRoute(const StoryRoute('la-lluvia')), findsOneWidget);
      await app.go(const StoryRoute('el-bizcocho'));
      expect(app.lessonShown, isTrue);
      expect(findShellRoute(const StoryRoute('el-bizcocho')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await app.settle(rounds: 10);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'speak');
      expect(findShellTab('speak').hitTestable(), findsOneWidget);

      // navigating directly to a TabRoute from a lesson leaves the lesson for that tab
      await app.go(const ReviewRoute());
      expect(app.lessonShown, isTrue);
      expect(findShellRoute(const ReviewRoute()), findsOneWidget);
      await app.go(const TabRoute('words'));
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'words');
      expect(findShellRoute(const ReviewRoute()), findsNothing);
      expect(findShellTab('words').hitTestable(), findsOneWidget);

      // a lesson's address opened directly (a reload): system back returns to the map
      await tester.pumpWidget(const SizedBox());
      final again = TestApp(tester);
      await again.open(stored: seed('curso'), location: '/nivel');
      expect(again.lessonShown, isTrue);
      expect(findShellRoute(const LevelCheckRoute()), findsOneWidget);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await again.settle(rounds: 5);
      expect(findShellRoute(const LevelCheckRoute()), findsNothing);
      expect(again.tabBarShown, isTrue);
      expect(again.selectedTab, 'map');
      expect(findShellTab('map').hitTestable(), findsOneWidget);

      // on a tab, the system back is not the app's: it leaves
      expect(await tester.binding.handlePopRoute(), isFalse);
    },
  );
}
