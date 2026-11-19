import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_map/feature_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_map'), findsOneWidget);
  });

  test('the module is map', () {
    expect(const MapModule().id, 'map');
    expect(fakeServices(), isNotNull);
  });
}
