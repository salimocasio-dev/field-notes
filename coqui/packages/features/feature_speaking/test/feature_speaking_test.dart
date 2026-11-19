import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_speaking'), findsOneWidget);
  });

  test('the module is speak', () {
    expect(const SpeakingModule().id, 'speak');
    expect(fakeServices(), isNotNull);
  });
}
