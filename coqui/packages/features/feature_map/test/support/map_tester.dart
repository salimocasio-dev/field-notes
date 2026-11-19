import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A widget test that ends by taking the screen down and letting the engine's last timers run: in a browser the
/// pictures `PixelView` uploads are decoded by the engine, which leaves a timer behind that the test would
/// otherwise report as pending.
void mapTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
