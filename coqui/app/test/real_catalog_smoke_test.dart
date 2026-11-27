// Real-catalog end-to-end smoke test: boots the real CoquiApp against historia/,
// exercises all five tabs, launches the first story from the Up next card, plays
// through it using scattered grid taps, confirms progress persistence, and
// returns to the map via system back. Driven strictly by keys (zero feature
// wording, zero type-name probes).
//
// Pass --dart-define=COQUI_SKIP_SMOKE=true to skip on fast feature-lane runs
// while keeping it active on main and release checks.
import 'dart:convert';

import 'package:app/src/shell.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const bool _skipSmoke = bool.fromEnvironment('COQUI_SKIP_SMOKE');

void main() {
  testWidgets(
    'real-catalog smoke: boots against historia/, visits all five tabs, plays la-lluvia to completion, and returns to map',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('vacio'), speechAvailable: false);

      expect(findShellTab('map').hitTestable(), findsOneWidget);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(findMapTopChips().hitTestable(), findsOneWidget);
      expect(findMapUpNextCard().hitTestable(), findsOneWidget);
      expect(findMapUpNextAction().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final id in const ['library', 'words', 'speak', 'me', 'map']) {
        await app.openTab(id);
        expect(app.selectedTab, id);
        expect(findShellTab(id).hitTestable(), findsOneWidget, reason: id);
        expect(tester.takeException(), isNull, reason: id);
      }

      await playUpNextStoryToEnd(app, 'la-lluvia');

      expect(app.clips!.played.first, 'esta_casa');
      final db = jsonDecode(app.stored!) as Map<String, dynamic>;
      expect(((db['cuentos'] as Map)['la-lluvia'] as Map)['n'], 1);
      expect(app.services.progress.played('la-lluvia'), isTrue);
      expect(tester.takeException(), isNull);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await app.settle(rounds: 5);
      // Drain any clip playback timer still active when leaving the story end screen.
      await app.advance(5000);
      expect(app.tabBarShown, isTrue);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(app.selectedTab, 'map');
      expect(findShellTab('map').hitTestable(), findsOneWidget);
      expect(findMapUpNextCard().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: _skipSmoke,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
