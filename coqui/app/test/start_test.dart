// The start: loading surface, welcome gate on an empty store, unknown
// addresses, and LoadFailed + retry.
import 'dart:async';

import 'package:app/src/app.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    'boot loading surface stays on Noche ground with no tab bar until course load completes',
    (tester) async {
      final courseCompleter = Completer<CourseCatalog>();
      final app = TestApp(tester)..loadCourse = (_) => courseCompleter.future;

      await app.open(stored: seed('curso'));
      expect(find.byKey(shellLoadingKey), findsOneWidget);
      final loadingBox = tester.widget<ColoredBox>(find.byKey(shellLoadingKey));
      expect(loadingBox.color, NocheColors.ground);
      expect(find.byType(NocheTabBar), findsNothing);
      expect(findShellTab('map'), findsNothing);

      courseCompleter.complete(FakeCourseCatalog());
      await app.settle(rounds: 10);

      expect(find.byKey(shellLoadingKey), findsNothing);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(findShellTab('map'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(a) an empty store: the map, with the welcome over it; finishing it leaves the map',
    (tester) async {
      final app = TestApp(tester);
      await app.open();
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(findShellTab('map'), findsOneWidget);
      expect(findMapTopChips(), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-step-0')), findsOneWidget);
      expect(find.byKey(const Key('welcome-new-button')), findsNothing);
      expect(find.byKey(const Key('welcome-next-button')), findsOneWidget);

      await app.tap(find.byKey(const Key('welcome-next-button')));
      await app.tap(find.byKey(const Key('welcome-next-button')));
      await app.settle(rounds: 5);
      expect(find.byKey(const ValueKey('welcome-step-2')), findsOneWidget);
      expect(find.byKey(const Key('welcome-new-button')), findsOneWidget);
      await app.tap(find.byKey(const Key('welcome-new-button')));
      await app.advance(1000);

      expect(
        find.byKey(const ValueKey('welcome-step-2')).hitTestable(),
        findsNothing,
      );
      expect(
        find.byKey(const Key('welcome-new-button')).hitTestable(),
        findsNothing,
      );
      expect(app.selectedTab, 'map');
      expect(findShellTab('map'), findsOneWidget);
      expect(findMapTopChips(), findsOneWidget);
      // listo(): the setting is written into the active language's progress store
      expect(app.stored, contains('"bienvenida":1'));
      // the course was read from the site's files before the first screen, with the voice test's lines
      expect(app.fetched.take(1), ['datos/curso.json']);
      expect(app.fetched, contains('audio/ready.json'));
      expect(app.fetched, contains('datos/prueba-voz.json'));
    },
  );

  testWidgets('(k) an unknown address opens the map', (tester) async {
    for (final at in [
      '/nada',
      '/tab/nada',
      '/cuento/NO',
      '/cuento/no-es-un-cuento',
      '/cuento/palabras-solas', // a file of historia/cuentos/ the course does not name (the word list, not a story)
      '/llamada/luna',
      '/llamada/casa?call=',
      '/llamada/casa?call=INVALID',
    ]) {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), location: at);
      expect(app.tabBarShown, isTrue, reason: at);
      expect(app.selectedTab, 'map', reason: at);
      expect(findShellTab('map'), findsOneWidget, reason: at);
      expect(findMapTopChips(), findsOneWidget, reason: at);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    '(l) no network: LoadFailed surface and retry recover into the app once network returns',
    (tester) async {
      final app = TestApp(tester)..offline = true;
      await app.open(stored: seed('curso'));
      expect(find.byKey(LoadFailed.screenKey), findsOneWidget);
      expect(find.text(loadFailedLine), findsOneWidget);
      expect(find.byKey(LoadFailed.retryKey), findsOneWidget);
      expect(find.text(tryAgainLabel), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);
      // the page colour behind it
      final box = tester.widget<ColoredBox>(find.byKey(LoadFailed.screenKey));
      expect(box.color, NocheColors.ground);
      // still no network: the same
      await app.tap(find.byKey(LoadFailed.retryKey));
      await app.settle(rounds: 5);
      expect(find.byKey(LoadFailed.screenKey), findsOneWidget);
      expect(find.byKey(LoadFailed.retryKey), findsOneWidget);

      app.offline = false;
      await app.tap(find.byKey(LoadFailed.retryKey));
      await app.settle(rounds: 10);
      expect(find.byKey(LoadFailed.screenKey), findsNothing);
      expect(find.byKey(LoadFailed.retryKey), findsNothing);
      expect(app.selectedTab, 'map');
      expect(findShellTab('map'), findsOneWidget);
      expect(findMapTopChips(), findsOneWidget);
      expect(app.services.progress.streak, 5);
    },
  );
}
