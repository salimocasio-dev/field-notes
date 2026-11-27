# Request: Stable widget keys and map-progression checks in feature_map

## What I need

In `coqui/packages/features/feature_map/`:

### Already present on `main` (document as standing rule in `feature_map/AGENTS.md`)

Keep these existing keys stable as shell/integration test contracts:

- `Key('language-chip')` — `coqui/packages/features/feature_map/lib/src/map_screen.dart:596`
- `Key('streak-chip')` — `coqui/packages/features/feature_map/lib/src/map_screen.dart:637`
- `Key('up-next-card')` — `coqui/packages/features/feature_map/lib/src/map_screen.dart:834`
- `Key('up-next-play')` — `coqui/packages/features/feature_map/lib/src/map_screen.dart:846`
- `Key('story-tile-$storyId')` — `coqui/packages/features/feature_map/lib/src/place_screen.dart:601`
- `Key('place-plan-card')` — `coqui/packages/features/feature_map/lib/src/place_screen.dart:687`
- `Key('place-see-plans')` — `coqui/packages/features/feature_map/lib/src/place_screen.dart:705`
- `Key('place-play-bar')` — `coqui/packages/features/feature_map/lib/src/place_screen.dart:727,746,758`
- `Key('place-back')` — `coqui/packages/features/feature_map/lib/src/place_screen.dart:779`

### New keys requested

- Root screen keys for `MapScreen` (`Key('map-screen')`) and `PlaceScreen` (`Key('place-screen')`) if needed by future shell diagnostics.

### Already-merged feature test coverage on `main` (zero coverage loss)

Map progression, Up Next card transitions, streak chip copy, "You are here" pill, and locked/unlocked place gating are owned and verified inside `coqui/packages/features/feature_map/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes feature-internal wording and type-name probes (`byTypeName('PlaceScreen')`, `'5 days'`, `'You are here'`, `'New story · 4 min'`, `'Second play · 2 min'`, `'10 words coming back · 6 min'`) from `coqui/app/test/` so changing map copy or internal widget names never breaks shell tests.

## What I am using meanwhile

`coqui/app/test/` asserts shell routing via `ShellKeys.tab('map')`, `ShellKeys.route(PlaceRoute(...))`, and `feature_map`'s existing keys listed above (`language-chip`, `streak-chip`, `up-next-card`, `up-next-play`, `place-back`, `place-plan-card`, `place-see-plans`, `place-play-bar`, `story-tile-la-lluvia`).

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
