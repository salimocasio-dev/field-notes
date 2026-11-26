// The end of a story: the title sits under the 400-high scene at the start
// margin, clear of the Noche action buttons, in portrait and landscape.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

/// Plays the story by answering each question rightly, until its end screen.
Future<void> _toTheEnd(Screen s) => s.answerUntil(
  () => s.runner.view.screen == StoryScreenState.end,
  what: 'the end screen',
);

void main() {
  for (final (w, h, ratio) in const [
    (390.0, 844.0, 3.0),
    (412.0, 915.0, 2.625),
    (390.0, 844.0, 2.0),
  ]) {
    testWidgets(
      'the title sits 16 px under the 400-high scene, at the 24 px start margin, clear of every button (${w.toInt()} x ${h.toInt()}, ratio $ratio)',
      (tester) async {
        final s = await openScreen(tester, size: Size(w, h), ratio: ratio);
        await tester.tap(find.byType(NochePlayDisc));
        await _toTheEnd(s);
        await s.advance(300);

        final title = tester.getRect(find.text('La lluvia'));
        // 64 px header + 400 px scene + 16 px top padding = 480
        expect(
          title.top,
          closeTo(StoryHeader.height + StoryScreen.sceneHeight + 16, 0.5),
        );
        expect(title.left, closeTo(24, 0.5));

        final outlines = find.byType(NocheOutlineButton);
        final primary = find.byType(NochePrimaryButton);
        expect(outlines, findsNWidgets(2)); // Play again, Map
        expect(primary, findsOneWidget); // Next story
        for (final finder in [outlines, primary]) {
          for (final b in finder.evaluate()) {
            final r = tester.getRect(find.byWidget(b.widget));
            expect(
              title.bottom,
              lessThanOrEqualTo(r.top),
              reason: 'the title sits above the button at $r',
            );
          }
        }
      },
    );
  }

  testWidgets(
    'a phone on its side (844 x 390): the title is at the top of the column beside the picture, clear of every button',
    (tester) async {
      final s = await openScreen(tester, size: const Size(844, 390), ratio: 3);
      await tester.tap(find.byType(NochePlayDisc));
      await _toTheEnd(s);
      await s.advance(300);
      final title = tester.getRect(find.text('La lluvia'));
      expect(title.top, closeTo(StoryHeader.height + 16, 0.5));
      for (final finder in [
        find.byType(NocheOutlineButton),
        find.byType(NochePrimaryButton),
      ]) {
        for (final b in finder.evaluate()) {
          expect(
            title.bottom,
            lessThanOrEqualTo(tester.getRect(find.byWidget(b.widget)).top),
          );
        }
      }
    },
  );
}
