// The end of a story (N8.8): the picture window closes from 400 to 296 at top 0
// in portrait; the title sits under the 296 window and story-counter label at the
// 16 px start margin, clear of every Noche action button, in portrait and landscape.
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
      'the title sits under the 296-high end window at the 16 px start margin, clear of every button (${w.toInt()} x ${h.toInt()}, ratio $ratio)',
      (tester) async {
        final s = await openScreen(tester, size: Size(w, h), ratio: ratio);
        await tester.tap(find.byType(NochePlayDisc));
        await _toTheEnd(s);
        await s.advance(1200);

        final title = tester.getRect(find.text('La lluvia'));
        // 296 px end window + 24 px top padding + 12 px counter label + 8 px gap = 340
        expect(
          title.top,
          greaterThanOrEqualTo(StoryScreen.endSceneHeight + 24),
        );
        expect(title.top, closeTo(StoryScreen.endSceneHeight + 44, 2.0));
        expect(title.left, closeTo(16, 0.5));

        final outlines = find.byType(NocheOutlineButton);
        final primary = find.byType(NochePrimaryButton);
        expect(outlines, findsNWidgets(2)); // Play again, Map
        expect(primary, findsOneWidget); // Next: El bizcocho
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
      await s.advance(1200);
      final title = tester.getRect(find.text('La lluvia'));
      expect(title.top, greaterThanOrEqualTo(StoryHeader.height + 24));
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
