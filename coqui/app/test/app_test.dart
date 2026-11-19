import 'package:app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the empty app shows its name', (tester) async {
    await tester.pumpWidget(const CoquiApp());
    expect(find.text('Coquí'), findsOneWidget);
  });

  testWidgets('the empty app shows its build number, small, under the name', (
    tester,
  ) async {
    await tester.pumpWidget(const CoquiApp());
    // `flutter test` passes no COQUI_BUILD, so the number is `dev`.
    expect(coquiBuild, 'dev');
    expect(find.text('build dev'), findsOneWidget);
    final name = tester.getTopLeft(find.text('Coquí'));
    final build = tester.getTopLeft(find.text('build dev'));
    expect(build.dy, greaterThan(name.dy));
    expect(tester.widget<Text>(find.text('build dev')).style?.fontSize, 12);
  });
}
