import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_words/feature_words.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_words'), findsOneWidget);
  });

  test('the module is words', () {
    expect(const WordsModule().id, 'words');
    expect(fakeServices(), isNotNull);
  });
}
