// The end of a story: the title hangs 16 px under the last picture, at the left of the 16 px margin, and never touches a
// button (index.html `#fin`, juego.js `finFit`: `y = stage.bottom - main.top + 16`; coqui/ref/pantallas/ 136, 137).
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

/// Plays the story by answering each question rightly, until its end screen.
Future<void> _toTheEnd(Screen s) => s.answerUntil(
  () => s.runner.view.screen == StoryScreenState.end,
  what: 'the end screen',
);

void main() {
  // the two phones of coqui/ref/pantallas/, and the size the frames tool plays at (390 x 844 at ratio 2)
  for (final (w, h, ratio) in const [
    (390.0, 844.0, 3.0),
    (412.0, 915.0, 2.625),
    (390.0, 844.0, 2.0),
  ]) {
    testWidgets(
      'the title is 16 px under the picture, at the left margin, clear of every button (${w.toInt()} x ${h.toInt()}, ratio $ratio)',
      (tester) async {
        final s = await openScreen(tester, size: Size(w, h), ratio: ratio);
        await tester.tap(find.byType(LessonStartButton));
        await _toTheEnd(s);
        await s.advance(300);

        final picture = tester.getRect(find.byType(PixelView));
        final title = tester.getRect(find.text('La lluvia'));
        // 16 px under the picture (the Text's own box is its 32 px line: `h1{font:600 24px/32px}`)
        expect(title.top - picture.bottom, closeTo(16, 0.01));
        expect(title.height, closeTo(32, 0.01));
        // at the left of the 16 px margin, as `#fin h1{text-align:left}`
        expect(title.left, closeTo(16, 0.01));
        // clear of every button, with room between
        final buttons = find.byType(LessonButton);
        expect(buttons, findsNWidgets(3)); // Play again, Map, Next story
        for (final b in buttons.evaluate()) {
          final r = tester.getRect(find.byWidget(b.widget));
          expect(
            title.bottom,
            lessThanOrEqualTo(r.top),
            reason: 'the title sits above the button at $r',
          );
        }
      },
    );
  }

  testWidgets(
    'a phone on its side (844 x 390): the title is at the top of the column beside the picture, not in the middle of it',
    (tester) async {
      final s = await openScreen(tester, size: const Size(844, 390), ratio: 3);
      await tester.tap(find.byType(LessonStartButton));
      await _toTheEnd(s);
      await s.advance(300);
      final title = tester.getRect(find.text('La lluvia'));
      // the column's top bar is 56 px, `#fin{padding:8px 0 152px}`
      expect(title.top, closeTo(CoquiMetrics.lessonTopBar + 8, 0.01));
      expect(title.height, closeTo(32, 0.01));
      for (final b in find.byType(LessonButton).evaluate()) {
        expect(
          title.bottom,
          lessThanOrEqualTo(tester.getRect(find.byWidget(b.widget)).top),
        );
      }
    },
  );
}
