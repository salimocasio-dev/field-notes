import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dev_app.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    await tester.pumpAndSettle();
    expect(find.text('Hablar'), findsOneWidget);
    expect(find.text('Call Danny'), findsWidgets);
  });

  test('the module is speak', () {
    expect(const SpeakingModule().id, 'speak');
    expect(fakeServices(), isNotNull);
  });
}
