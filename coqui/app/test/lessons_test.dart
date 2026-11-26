// Shell route-reaches-screen checks: every lesson and feature route mounts
// under ShellKeys.route, toggles NocheTabBar as expected, throws no exceptions,
// and returns cleanly on system back.
// Feature-level playback & copy checks live in their owning packages on main:
// - feature_review: repaso_pictures_policy_test.dart, repaso_session_test.dart,
//   repaso_screen_test.dart, review_end_test.dart, level_screen_test.dart
// - feature_library: module_test.dart, reading_home_test.dart, reader_test.dart
// - feature_speaking: llamada_expected_test.dart, call_screen_test.dart,
//   arabic_language_test.dart, voice_test_test.dart
// - feature_story: screen_test.dart, lines_test.dart, not_converted_test.dart
import 'package:app/src/shell.dart';
import 'package:app/src/switches.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show NochePlayDisc;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    'StoryRoute (play and listen) reaches its screen under ShellKeys.route and returns on back',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), speechAvailable: false);

      for (final route in const [
        StoryRoute('la-lluvia'),
        StoryRoute('la-lluvia', listen: true),
      ]) {
        await app.go(route);
        await app.until(
          () => findStoryStartButton().evaluate().isNotEmpty,
          what: 'story start disc for $route',
        );
        expect(findShellRoute(route), findsOneWidget, reason: '$route');
        expect(app.lessonShown, isTrue, reason: '$route');
        expect(find.byKey(ShellKeys.tabBar), findsNothing, reason: '$route');
        expect(findStoryStartButton(), findsOneWidget, reason: '$route');
        expect(tester.takeException(), isNull, reason: '$route');

        expect(await tester.binding.handlePopRoute(), isTrue, reason: '$route');
        await app.settle(rounds: 5);
        expect(findShellRoute(route), findsNothing, reason: '$route');
        expect(app.tabBarShown, isTrue, reason: '$route');
        expect(app.selectedTab, 'map', reason: '$route');
        expect(findShellTab('map').hitTestable(), findsOneWidget);
      }

      await app.advance(5000);
    },
  );

  testWidgets(
    'ReviewRoute (direct, practice, and from Words tab) reaches its screen under ShellKeys.route and returns cleanly',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), speechAvailable: false);

      // Direct navigation via ReviewRoute() and ReviewRoute(practice: true).
      for (final route in const [ReviewRoute(), ReviewRoute(practice: true)]) {
        await app.go(route);
        expect(findShellRoute(route), findsOneWidget, reason: '$route');
        expect(app.lessonShown, isTrue, reason: '$route');
        expect(find.byKey(ShellKeys.tabBar), findsNothing, reason: '$route');
        // Shell-level defense-in-depth for product rule 4 (no story screenshots
        // as UI/flashcard pictures); full item policy lives in
        // feature_review/test/repaso_pictures_policy_test.dart
        // ('default Repaso session (curso.json and everythingJson) has zero
        // CualItem, zero WhereItem, zero BookImage, zero NochePictureChoice,
        // and never calls PictureSource').
        expect(find.byType(Image), findsNothing, reason: '$route');
        expect(tester.takeException(), isNull, reason: '$route');

        expect(await tester.binding.handlePopRoute(), isTrue, reason: '$route');
        await app.settle(rounds: 5);
        expect(findShellRoute(route), findsNothing, reason: '$route');
        expect(app.tabBarShown, isTrue, reason: '$route');
        expect(app.selectedTab, 'map', reason: '$route');
      }

      // From Words tab via Key('words-review-button'), starting the first item
      // so the rule-4 Image-free assertion runs against a live Repaso item.
      await app.openTab('words');
      final reviewButton = find.byKey(const Key('words-review-button'));
      await app.until(
        () => reviewButton.evaluate().isNotEmpty,
        what: 'words-review-button',
      );
      await tester.ensureVisible(reviewButton);
      await app.tap(reviewButton);
      await app.settle(rounds: 10);
      expect(findShellRoute(const ReviewRoute()), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      final playDisc = find.byType(NochePlayDisc);
      expect(playDisc, findsOneWidget);
      await app.tap(playDisc);
      await app.advance(400);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      await app.advance(5000);
      expect(findShellRoute(const ReviewRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'words');
      expect(findShellTab('words').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'LevelCheckRoute (direct and from Me tab) reaches its screen under ShellKeys.route and returns cleanly',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      // Direct navigation.
      await app.go(const LevelCheckRoute());
      expect(findShellRoute(const LevelCheckRoute()), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const LevelCheckRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');

      // From Me tab via Key('yo-level-check').
      await app.openTab('me');
      final levelCheck = find.byKey(const Key('yo-level-check'));
      expect(levelCheck, findsOneWidget);
      await tester.ensureVisible(levelCheck);
      await app.tap(levelCheck);
      await app.settle(rounds: 10);
      expect(findShellRoute(const LevelCheckRoute()), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const LevelCheckRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'me');
      expect(findShellTab('me').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'BookRoute (via go and direct /libro/la-familia) reaches TextReader under ShellKeys.route and returns cleanly',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      await app.go(const BookRoute('la-familia'));
      expect(findShellRoute(const BookRoute('la-familia')), findsOneWidget);
      expect(find.byKey(const ValueKey('book:la-familia')), findsOneWidget);
      // Shell-level defense-in-depth for product rule 4 (no story screenshots
      // as book pictures); feature guard lives in
      // feature_library/test/module_test.dart
      // ('BookRoute opens TextReader without pictures').
      expect(find.byType(Image), findsNothing);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.advance(10000);
      expect(findShellRoute(const BookRoute('la-familia')), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');

      // Direct location open (reload).
      await tester.pumpWidget(const SizedBox());
      final direct = TestApp(tester);
      await direct.open(stored: seed('curso'), location: '/libro/la-familia');
      expect(findShellRoute(const BookRoute('la-familia')), findsOneWidget);
      expect(find.byKey(const ValueKey('book:la-familia')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(direct.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await direct.advance(10000);
      expect(findShellRoute(const BookRoute('la-familia')), findsNothing);
      expect(direct.tabBarShown, isTrue);
      expect(direct.selectedTab, 'map');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'CallRoute (from Speak tab with ?callstub=1 and direct /llamada/casa) reaches CallScreen under ShellKeys.route',
    (tester) async {
      final app = TestApp(tester);
      await app.open(
        stored: seed('curso'),
        switches: AppSwitches.fromQuery(const {'callstub': '1'}),
      );

      await app.openTab('speak');
      final callDisc = find.byKey(const Key('speak-call-disc'));
      expect(callDisc, findsOneWidget);
      await app.tap(callDisc);
      await app.settle(rounds: 10);
      expect(findShellRoute(const CallRoute('casa')), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const CallRoute('casa')), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'speak');

      // Direct location open (reload).
      await tester.pumpWidget(const SizedBox());
      final direct = TestApp(tester);
      await direct.open(
        stored: seed('curso'),
        location: '/llamada/casa',
        switches: AppSwitches.fromQuery(const {'callstub': '1'}),
      );
      expect(findShellRoute(const CallRoute('casa')), findsOneWidget);
      expect(direct.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await direct.settle(rounds: 5);
      expect(findShellRoute(const CallRoute('casa')), findsNothing);
      expect(direct.tabBarShown, isTrue);
      expect(direct.selectedTab, 'map');
    },
  );

  testWidgets(
    'VoiceTestRoute (/prueba-voz) reaches its screen under ShellKeys.route and returns to map on back',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), location: '/prueba-voz');

      expect(findShellRoute(const VoiceTestRoute()), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const VoiceTestRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
    },
  );

  testWidgets(
    'PlaceRoute, LanguagesRoute, and PlansRoute reach their screens under ShellKeys.route with expected tab-bar visibility',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      // PlaceRoute('casa'): keeps tab bar visible with map selected.
      await app.go(const PlaceRoute('casa'));
      expect(findShellRoute(const PlaceRoute('casa')), findsOneWidget);
      expect(find.byKey(const Key('place-back')), findsOneWidget);
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const PlaceRoute('casa')), findsNothing);
      expect(app.selectedTab, 'map');

      // LanguagesRoute(): hides tab bar, exposes language-card-es.
      await app.go(const LanguagesRoute());
      expect(findShellRoute(const LanguagesRoute()), findsOneWidget);
      expect(find.byKey(const ValueKey('language-card-es')), findsOneWidget);
      expect(app.tabBarShown, isFalse);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const LanguagesRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');

      // PlansRoute(): hides tab bar, exposes plans-scroll.
      await app.go(const PlansRoute());
      expect(findShellRoute(const PlansRoute()), findsOneWidget);
      expect(find.byKey(const Key('plans-scroll')), findsOneWidget);
      expect(app.tabBarShown, isFalse);
      expect(find.byKey(ShellKeys.tabBar), findsNothing);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      expect(findShellRoute(const PlansRoute()), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
    },
  );
}
