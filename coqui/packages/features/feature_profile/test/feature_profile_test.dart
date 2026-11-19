import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_profile'), findsOneWidget);
  });

  test('the module is me', () {
    expect(const ProfileModule().id, 'me');
    expect(fakeServices(), isNotNull);
  });
}
