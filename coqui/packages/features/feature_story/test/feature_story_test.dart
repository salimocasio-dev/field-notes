import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_story/feature_story.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_main.dart';

void main() {
  testWidgets('the dev entry opens on the fakes', (tester) async {
    await tester.pumpWidget(devApp());
    expect(find.text('feature_story'), findsOneWidget);
  });

  test('the module is story', () {
    expect(const StoryModule().id, 'story');
    expect(fakeServices(), isNotNull);
  });
}
