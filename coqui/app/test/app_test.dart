import 'package:app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the empty app shows its name', (tester) async {
    await tester.pumpWidget(const CoquiApp());
    expect(find.text('Coquí'), findsOneWidget);
  });
}
