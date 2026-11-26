# Request: Review & level-check playback checks and stable keys in feature_review

## What I need

In `coqui/packages/features/feature_review/`:

1. Expose stable widget keys on `RepasoScreen` and `LevelCheckScreen` controls and states:
   - Start disc (e.g. `Key('review-start-disc')`)
   - Lesson close button (e.g. `Key('review-close-button')`)
   - Next / end-screen action buttons (e.g. `Key('review-next-button')`, `Key('review-end-action')`, `Key('level-check-end-action')`)
2. Own end-to-end Repaso and Level Check gameplay checks previously in `coqui/app/test/lessons_test.dart` inside `feature_review/test/`:
   - Full Repaso session playback (`HearItem`, `BuildItem`, `MatchItem`), post-#10 no-story-screenshot invariant, ear answer persistence, shared minutes increment, and return to Words tab
   - Full Level Check session playback, `presume` persistence, and return to Map tab.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName`, `stateNamed(...).session`, and quoted feature wording (`'Next'`, `'Back to Palabras'`, `'To the map'`) from `coqui/app/test/`. Shell tests must not reach into `RepasoScreen` or `LevelCheckScreen` state objects or internal widget class names.

## What I am using meanwhile

`coqui/app/test/lessons_test.dart` and `tabs_test.dart` verify that `ReviewRoute()`, `ReviewRoute(practice: true)`, and `LevelCheckRoute()` mount under `ShellKeys.route(...)`, hide `NocheTabBar`, open cleanly from Words (`words-review-button`) and Me (`yo-level-check`), and return cleanly via `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
