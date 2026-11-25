# Request: Update two coqui/app tests for N4.3 Noche StoryScreen

## What I need

Update two tests in `coqui/app/test/` that still look for the legacy v=39 `LessonFrame`, `LessonCloseButton`, and `LessonStartButton` when opening `StoryScreen`:

1. `coqui/app/test/story_test.dart` (lines 20, 25, 124, 127, 175):
   - Currently waits for and taps `find.byType(LessonStartButton)` when a story opens.
   - Update to accept N4.3's `find.byKey(const Key('story-start-disc'))` (or `NochePlayDisc`) alongside `LessonStartButton`.
2. `coqui/app/test/tabs_test.dart`, test `(c)` (lines 167–174):
   - Currently asserts `expect(find.byType(LessonFrame), findsOneWidget)`, taps `find.byType(LessonCloseButton)`, and asserts `expect(find.byType(LessonFrame), findsNothing)` when opening and closing a story from a place.
   - Update to accept N4.3's `StoryScreen` (`find.byType(NocheDashes)` / `byTypeName('StoryCloseButton')` / `find.bySemanticsLabel('Close story')`) alongside legacy `LessonFrame` / `LessonCloseButton`.

## Why

Story N4.3 ("Story lesson", issue #103) replaces the legacy v=39 `LessonFrame`, `LessonCloseButton`, `LessonSoundButton`, `LessonProgressDashes`, `LessonStartButton`, and `LessonButton` in `StoryScreen` with the Noche full-screen `lessonGround` layout (`StoryHeader`, `NocheDashes`, `StoryTxtToggle`, `NochePlayDisc`, `NocheMic`, `NochePrimaryButton`, `NocheOutlineButton`). Changing `coqui/app/test/` from `lane/feature_story/103` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All `feature_story` unit, runner, differential (all 171 recorded runs), Arabic/RTL, Noche static, widget, and screenshot tests pass inside `coqui/packages/features/feature_story/`.

## Order and branch

- Order: 103 (N4.3 Story lesson)
- Branch: `lane/feature_story/103`
