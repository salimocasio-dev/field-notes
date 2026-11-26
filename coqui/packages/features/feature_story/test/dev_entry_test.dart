// The dev entry opens on the fakes (tool/dev_main.dart), in portrait and on a phone on its side.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/dev_main.dart';

Future<void> settle(WidgetTester tester) async {
  // the sample course is read, El frente's sheet too, and its first set is baked: real time
  for (
    var i = 0;
    i < 1000 && find.byType(NochePlayDisc).evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets(
    'the dev entry opens on the sample story: the Noche story screen with its start disc',
    (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devApp());
      await settle(tester);
      expect(find.byType(StoryHeader), findsOneWidget);
      expect(find.byType(NocheDashes), findsOneWidget);
      expect(find.byType(NochePlayDisc), findsOneWidget);
      expect(find.byType(PixelView), findsOneWidget);
    },
  );

  testWidgets(
    'a phone on its side (844 by 390): the picture at the start, the rest in a column',
    (tester) async {
      tester.view.physicalSize = const Size(844 * 3, 390 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devApp());
      await settle(tester);
      expect(tester.takeException(), isNull);
      final picture = tester.getRect(find.byType(PixelView));
      final disc = tester.getRect(find.byType(NochePlayDisc));
      expect(picture.left, lessThan(disc.left));
      expect(picture.top, greaterThanOrEqualTo(0));
      expect(picture.bottom, lessThanOrEqualTo(390));
    },
  );
}
