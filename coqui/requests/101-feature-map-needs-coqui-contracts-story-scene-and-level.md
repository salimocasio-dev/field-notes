# Request: Story scene thumbnails and course CEFR level

## What I need

1. In `coqui_contracts` (`StoryMeta` or `CourseCatalog`) and `coqui_ui` / `coqui_scenes` (`PictureSource` / `ScenePictures`):
   - Expose each story's `scene` id synchronously on `StoryMeta` (or a thumbnail `PictureRef` helper on `CourseCatalog`), and allow `PictureSource.of(..., width: 72, height: 72)` to render a scene/story thumbnail even when a story's scene has no matching `ReviewPair` or is not yet converted (`ScenePictures._oldOf` currently throws for sizes other than `196 x 104` and `96 x 106`).
2. In `coqui_contracts` (`Language`, `CourseCatalog`, or `ProgressStore`):
   - Expose the learner's current CEFR level label (such as `'A1'`) so the map's language chip does not hardcode `'A1'`.

## Why

Story N4.1 ("Map (home)", issue #101) shows:
- A `72 x 72` picture of the next story's scene inside the Up next card.
- The learner's level (`A1`) next to the English language name inside the top-start language chip.

## What I am using meanwhile

- Picking a `ReviewPair` from `course.pairs` via `PictureRef.of(pair, pair.yes)` (matching the story's normalized `scene` when available via `course.story(id)` or normalized place scene, and returning `null` to render the `NocheColors.chip` placeholder icon when no `ReviewPair` matches cleanly).
- Omitting the level badge from the language chip until `coqui_contracts` exposes the learner's real level (no hardcoded `'A1'`).

## Order and branch

- Order: 101 (N4.1 Map home)
- Branch: `lane/feature_map/101`
