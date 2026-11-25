## What I need

> **Status:** All 47/47 `coqui/app` tests already pass with this PR because prerequisite PR #144 (`lane/app/10`, commit `b0dd834`) already merged to `main` with dual-mode support. This request is **post-#10 dead-branch cleanup only**.

Clean up `coqui/app/test/lessons_test.dart` test `(f, g)` (`Repaso from the Today card`, lines 162–291) after `#10` merges:
- PR #144 (`lane/app/10`, already merged on `main`) added temporary dual-mode compatibility so `(f, g)` passes on both pre-`#10` `main` and `#10`.
- Once `#10` (`lane/feature_review/10`) merges, remove the legacy pre-`#10` `if (kinds.contains('CualItem'))` branch, the `ScenePictures` / `oldPicture` pixel comparison loop, and the `hombre` / `testSceneId` setup that existed only to test story-scene crops on flashcards.
- Keep the post-`#10` assertions verifying `kinds` contains `['HearItem', 'BuildItem', 'MatchItem']`, `kinds` does not contain `'CualItem'` or `'WhereItem'`, zero `PictureChoice` / zero `BookImage` story screenshots render on flashcards, ear answers are written (`moved.length >= 5`), minutes increment, and the session ends on Palabras.

## Why

Issue #10 forbids story screenshots and story-scene crops (`ScenePictures`) on flashcards (`¿Cuál?` is gated on dedicated `word_assets/...` single-word pictures, and `¿Dónde?` is removed from `playKinds`). Because `coqui/app/` is outside `lane/feature_review/10`, final test cleanup in `app/test/lessons_test.dart` must happen on `lane:app` after `#10` merges.

## What I am using meanwhile

PR #144 (`lane/app/10`, merged to `main`) keeps `coqui/app/test/lessons_test.dart` passing across both pre-`#10` and `#10`, while `feature_review/test/repaso_pictures_policy_test.dart` directly enforces zero story screenshots, zero `ScenePictures` calls, and dedicated single-word asset gating.

## Order and branch

- Issue #10 (`lane/feature_review/10`)
