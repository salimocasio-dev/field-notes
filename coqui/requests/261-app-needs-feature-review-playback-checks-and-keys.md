# Request: Review & level-check playback checks and stable keys in feature_review

## What I need

In `coqui/packages/features/feature_review/`:

### Already present on `main` (document as standing rule in `feature_review/AGENTS.md`)

- None currently relied on by `coqui/app/test/` (`coqui/app/test/` uses shell-owned `ShellKeys.route(const ReviewRoute())`, `ShellKeys.route(const ReviewRoute(practice: true))`, and `ShellKeys.route(const LevelCheckRoute())`).

### New keys requested

- Start disc (`Key('review-start-disc')`)
- Lesson close button (`Key('review-close-button')`)
- Next / end-screen action buttons (`Key('review-next-button')`, `Key('review-end-action')`, `Key('level-check-end-action')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

The review and level-check playback assertions removed from `coqui/app/test/lessons_test.dart` are already covered inside `feature_review/test/`:

- `coqui/packages/features/feature_review/test/repaso_pictures_policy_test.dart:184` — post-#10 no story screenshots (`CualItem` / `WhereItem` / `BookImage` / `NochePictureChoice` absent)
- `coqui/packages/features/feature_review/test/repaso_session_test.dart:529-540,805` — Repaso game progression and `ear` answer persistence
- `coqui/packages/features/feature_review/test/repaso_screen_test.dart:112` & `coqui/packages/features/feature_review/test/review_end_test.dart:257-330` — end screen and `Back to Palabras` return
- `coqui/packages/features/feature_review/test/level_screen_test.dart:168-234` & `coqui/packages/features/feature_review/test/level_differential_test.dart:97` — Level Check playback, `presume`, and `To the map`.

Small gap to add in `feature_review/test/`: assert that completing a Repaso session calls `progress.addMinutes(...)` with a positive duration (shell-level `coqui.shared.v1` `minutos` persistence across language switches is now directly tested in `coqui/app/test/language_shell_test.dart`).

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName`, `stateNamed(...).session`, and quoted feature wording (`'Next'`, `'Back to Palabras'`, `'To the map'`) from `coqui/app/test/`. Shell tests must not reach into `RepasoScreen` or `LevelCheckScreen` state objects or internal widget class names.

## What I am using meanwhile

`coqui/app/test/lessons_test.dart` and `tabs_test.dart` verify that `ReviewRoute()`, `ReviewRoute(practice: true)`, and `LevelCheckRoute()` mount under `ShellKeys.route(...)`, hide `NocheTabBar`, render zero `Image` widgets on `ReviewRoute` (defense-in-depth for product rule 4), open cleanly from Words (`words-review-button`) and Me (`yo-level-check`), and return cleanly via `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
