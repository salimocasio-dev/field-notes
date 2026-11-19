import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_library/feature_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_library'), findsOneWidget);
  });

  test('the module is library', () {
    expect(const LibraryModule().id, 'library');
    expect(fakeServices(), isNotNull);
  });
}
