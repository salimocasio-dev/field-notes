import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('coquiTheme has the standard visual density on every platform', () {
    expect(coquiTheme().visualDensity, VisualDensity.standard);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        expect(
          coquiTheme().visualDensity,
          VisualDensity.standard,
          reason: '$platform',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });

  // A dense outlined text field is 48 px high at the standard density and 40 px at the compact one,
  // which a browser on a desktop machine asks for by itself.
  const field = TextField(
    decoration: InputDecoration(border: OutlineInputBorder(), isDense: true),
  );

  Future<double> heightUnder(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: field),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(TextField)).height;
  }

  testWidgets(
    'a text field keeps its 48 px under coquiTheme, whatever the density asked for',
    (tester) async {
      expect(await heightUnder(tester, coquiTheme()), 48);
      // The control the theme guards against: the same field under the compact density.
      expect(
        await heightUnder(
          tester,
          coquiTheme().copyWith(visualDensity: VisualDensity.compact),
        ),
        40,
      );
    },
  );

  testWidgets('on a desktop platform the field is still 48 px', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(await heightUnder(tester, coquiTheme()), 48);
    // The control: Flutter's own theme, on the same platform, gives the compact density and 40 px.
    expect(await heightUnder(tester, ThemeData(useMaterial3: true)), 40);
  });
}
