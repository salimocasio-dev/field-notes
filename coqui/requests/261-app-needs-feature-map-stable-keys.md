# Request: Stable widget keys and map-progression checks in feature_map

## What I need

In `coqui/packages/features/feature_map/`:

1. Expose stable keys for map/place UI elements that shell smoke tests or `feature_map` integration tests interact with, including a root key on the map screen (e.g. `Key('map-screen')`) and place screen (e.g. `Key('place-screen')`), and document the existing keys (`language-chip`, `streak-chip`, `up-next-card`, `up-next-play`, `place-back`, `place-plan-card`, `place-see-plans`, `place-play-bar`, `story-tile-<id>`) as stable test keys.
2. Keep map progression and Up Next card copy/state assertions (e.g. streak display, "You are here", Up Next card transitions after first/second play and after level check) inside `feature_map/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes feature-internal wording and type-name probes (`byTypeName('PlaceScreen')`, `'5 days'`, `'You are here'`, `'New story · 4 min'`, `'Second play · 2 min'`, `'10 words coming back · 6 min'`) from `coqui/app/test/` so changing map copy or internal widget names never breaks shell tests.

## What I am using meanwhile

`coqui/app/test/` asserts shell routing via `ShellKeys.tab('map')`, `ShellKeys.route(PlaceRoute(...))`, and `feature_map`'s existing stable keys (`language-chip`, `streak-chip`, `up-next-card`, `up-next-play`, `place-back`, `place-plan-card`, `place-see-plans`, `place-play-bar`, `story-tile-la-lluvia`).

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
