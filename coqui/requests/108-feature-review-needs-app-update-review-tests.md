# Request: Update `coqui/app/test/` for N4.8a Noche Repaso & Level Check widgets

## What I need

Update 4 tests across two files in `coqui/app/test/` that still look up legacy v=39 `coqui_ui` lesson/game widget types (`LessonStartButton`, `LessonCloseButton`, `LessonButton`, `WordTile`, `SpeakerTile`, `TileTray`, `PictureChoice`) inside `RepasoScreen` and `LevelCheckScreen`, so they work with both N4.8a Noche widgets and pre-N4.8a `main` (matching PRs #133, #144, #150, #152, #165, and #182):

1. `coqui/app/test/lessons_test.dart`:
   - `playRepaso` (lines 111–159):
     - Line 112: tap `find.widgetWithText(NochePrimaryButton, 'Next')` if present, else `find.widgetWithText(LessonButton, 'Next')` (or `find.text('Next')`).
     - Lines 131–133, 140–141, 151, 155: match `byTypeName('NocheTileTray')` / `find.byType(TileTray)`, `byTypeName('NocheWordTile')` / `find.byType(WordTile)`, `byTypeName('NocheSpeakerTile')` / `find.byType(SpeakerTile)`, and `byTypeName('NochePictureChoice')` / `find.byType(PictureChoice)`.
   - Test `(f, g)` (line 206): tap `find.byType(NochePlayDisc)` if present, else `find.byType(LessonStartButton)`.
   - Test `(m)` (line 316): tap `byTypeName('NocheLessonCloseButton')` if present, else `find.byType(LessonCloseButton)`.
   - Test `(h)` (line 457): tap `find.byType(NochePlayDisc)` if present, else `find.byType(LessonStartButton)`.
2. `coqui/app/test/tabs_test.dart`:
   - Test `(j)` (line 217, closing `LevelCheckScreen` via X): tap `byTypeName('NocheLessonCloseButton')` if present, else `find.byType(LessonCloseButton)`.

## Why

Story N4.8a ("Review and level check in Noche colours", issue #108) migrates `RepasoScreen`, `ReviewScreen`, and `LevelCheckScreen` from legacy v=39 `coqui_ui` widgets (`LessonFrame` on `CoquiColors.lessonBg`, green `LessonStartButton`, `LessonButton`, red-ring `PictureChoice`/`WordTile`/`SpeakerTile`/`TileTray`) to Noche tokens and pieces (`NocheColors.lessonGround`, `NochePlayDisc`, `NochePrimaryButton`, `NocheOutlineButton`, `NocheMic`, `NocheDashes`, and local Noche lesson/game pieces in `noche_lesson_parts.dart` with white outline on wrong choices and zero red). Editing `coqui/app/test/` from `lane/feature_review/108` is disallowed by `check_boundaries.dart`, and `lane:app` is currently held by #94.

## What I am using meanwhile

All 311 unit, differential, widget, RTL/Arabic, and Noche static tests inside `coqui/packages/features/feature_review/` pass (`flutter test` = 311/311), along with all screenshot tools (`noche_shots_test.dart`, `say_shots_test.dart`, `picture_shots_test.dart`).

## Order and branch

- Order: #108 (N4.8a Review and level check in Noche colours)
- Branch: `lane/feature_review/108`
