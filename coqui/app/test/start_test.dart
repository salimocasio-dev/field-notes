// The start: the welcome on an empty store, the stored progress on every tab, an unknown address, a failed load.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    '(a) an empty store: the map, with the welcome over it; finishing it leaves the map',
    (tester) async {
      final app = TestApp(tester);
      await app.open();
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(find.byType(MapChips), findsOneWidget);
      expect(find.text("I'm new to Spanish"), findsNothing); // step 1 first
      expect(find.text('Next'), findsOneWidget);
      await app.tap(find.text('Next'));
      await app.tap(find.text('Next'));
      await app.settle(rounds: 5);
      await app.tap(find.text("I'm new to Spanish"));
      await app.advance(1000);
      expect(find.text("I'm new to Spanish").hitTestable(), findsNothing);
      expect(app.selectedTab, 'map');
      expect(find.byType(MapChips), findsOneWidget);
      // listo(): the setting is written into the stored progress, under the old key
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
    ]) {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), location: at);
      expect(app.tabBarShown, isTrue, reason: at);
      expect(app.selectedTab, 'map', reason: at);
      expect(find.byType(MapChips), findsOneWidget, reason: at);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    '(l) no network: one line and "Try again"; trying again with the network back starts the app',
    (tester) async {
      final app = TestApp(tester)..offline = true;
      await app.open(stored: seed('curso'));
      expect(
        find.text('Coquí could not load. Check your connection.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CoquiTabBar), findsNothing);
      // the page colour behind it
      final box = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text('Try again'),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(box.color, CoquiColors.bg);
      // still no network: the same
      await app.tap(find.text('Try again'));
      await app.settle(rounds: 5);
      expect(find.text('Try again'), findsOneWidget);
      app.offline = false;
      await app.tap(find.text('Try again'));
      await app.settle(rounds: 10);
      expect(find.text('Try again'), findsNothing);
      expect(app.selectedTab, 'map');
      expect(find.byType(MapChips), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    },
  );
}
