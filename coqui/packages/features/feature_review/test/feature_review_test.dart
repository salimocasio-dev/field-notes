import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/feature_review.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_review'), findsOneWidget);
  });

  test('the module is review', () {
    expect(const ReviewModule().id, 'review');
    expect(fakeServices(), isNotNull);
  });
}
