# Request: Noche lesson frame and game pieces in `coqui_ui`

## What I need

Promote the Noche lesson and review game pieces from `feature_review`'s local copy into `coqui_ui` (beside the legacy `LessonFrame`, `LessonProgressDashes`, `PictureChoice`, `WordTile`, `SpeakerTile`, `TileTray`, `RoundSpeaker`, `StreakChip`, `CheckBadge`, `WrongBadge`, `NumberBadge`, and `TouchSign` so N1.4 can safely delete the old look once every screen is migrated):

1. `NocheLessonFrame`, `NocheLessonCloseButton`, `NocheLessonSoundButton` — full-screen lesson frame on `NocheColors.lessonGround`, directional layout, `NocheIcons.close` / `NocheIcons.speaker`, `NocheType.lessonPrompt` captions with `NocheType.forScript`, bottom zone capped at 480 px.
2. `NocheReviewDashes` — per-item progress dashes (`DashMark`: `none` on `NocheColors.lessonLine`, `right` on `NocheColors.right`, `wrong` on `NocheColors.lessonGround` with `1.5 px NocheColors.text` white outline and never red, `skipped` on `NocheColors.lessonBorder`, `current` white outer ring).
3. `NochePictureChoice`, `NocheWordTile`, `NocheSpeakerTile`, `NocheTileTray`, `NocheCheckBadge`, `NocheWrongBadge`, `NocheNumberBadge`, `NocheTouchSign` (plus `NocheIcons.touchApp` so `NocheTouchSign` does not rely on `CoquiIcons.touchApp`), `NocheStreakChip`, `NocheRoundSpeaker` — all built solely on `NocheColors`, `NocheType`, `NocheSize`, and `NocheIcons`, with white outline (`NocheColors.text`, never red, no shaking) on wrong choices.

## Why

Story N4.8a ("Review and level check in Noche colours", issue #108) migrates `RepasoScreen`, `ReviewScreen`, and `LevelCheckScreen` to Noche tokens and pieces (`lessonGround`, `NocheMic`, white outline on wrong choices, never red) while strictly keeping changes inside `lane:feature_review`. `coqui_ui`'s existing lesson and game widgets (`LessonFrame`, `LessonProgressDashes`, `PictureChoice`, `WordTile`, `SpeakerTile`, `TileTray`, `RoundSpeaker`, `StreakChip`, `WrongBadge`) still hardcode `CoquiColors.lessonBg`, `CoquiColors.lessonBad` (red-orange), `CoquiColors.lessonGreen`, and Roboto `CoquiText.*`.

## What I am using meanwhile

Local Noche implementations in `coqui/packages/features/feature_review/lib/src/ui/noche_lesson_parts.dart`, paired with `NocheMic`, `NocheDashes`, `NochePrimaryButton`, `NocheOutlineButton`, `NochePlayDisc`, `NocheColors`, `NocheType`, `NocheSize`, and `NocheIcons` imported directly from `coqui_ui`.

## Order and branch

- Order: #108 (N4.8a Review and level check in Noche colours)
- Branch: `lane/feature_review/108`
