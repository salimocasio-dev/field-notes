# Request: Noche PageRoute transitions and HeroController for map -> place -> story in app

## What I need

In `coqui/app/` (story N8.3, `#221`):

- Push and pop `PlaceRoute` (and `StoryRoute` from the map card play disc or from `PlaceScreen`) through Flutter `PageRoute`s backed by a `HeroController` using `NocheMotion.pageIn` (320 ms) forward and `NocheMotion.pageOut` (200 ms) reverse durations (`NocheMotion.quick` under reduced motion), with pass-through `transitionsBuilder` so `MapScreen` and `PlaceScreen` run their own fade/rise choreography while keeping the floating `NocheTabBar` above Map <-> Place and sinking it on `StoryRoute`.
- Preserve `MapScreen` and `PlaceScreen` on their own `ModalRoute`s during push/pop so:
  1. `NocheWindow` `Hero` endpoints with tag `storyId` (`MapMotion.storyWindowTag(storyId)`) fly cleanly across `MapScreen` (`72x72`, radius `16`) <-> `PlaceScreen` (`296 + top inset`, radius `0`) <-> `feature_story` (`400`, radius `0`).
  2. `ModalRoute.of(context)?.secondaryAnimation` drives `MapScreen`'s outgoing `quick` fade and back-return `quick` fade after `40 ms` (with zero rise), and drives `PlaceScreen`'s Story push fade and Story back-return fade after `40 ms` (with zero rise) without recreating `PlaceScreen`.
- If the shell ever recreates `PlaceScreen` when returning from a lesson instead of popping a `PageRoute`, pass `enteringFromBack: true` so rows fade in after `40 ms` without replaying the forward rise.

## Why

Story `#222` (N8.4 Map: opening a place, and a story from the card) builds `NocheWindow` hero tagging and `ModalRoute`-driven `pageIn` / `pageOut` motion inside `feature_map`. Today `coqui/app/lib/src/app.dart` renders routes inside a single `NoTransitionPage` and `coqui/app/lib/src/shell.dart` swaps `PlaceScreen` / `StoryScreen` inside a `Stack` rather than pushing/popping `PageRoute`s, so cross-screen `NocheWindow` flights and `secondaryAnimation` back fades do not run in the production shell until N8.3 (`lane:app`) wires them. `feature_map` cannot edit `coqui/app/` on a lane branch.

## What I am using meanwhile

- `MapScreen` gates its `NocheWindow` `Hero` tag on `TickerMode.valuesOf(context).enabled` so the existing `AppShell` `Stack` (`Offstage` + `TickerMode(enabled: false)`) never hits duplicate Hero tags.
- `MapDevApp` (`coqui/packages/features/feature_map/test/support/map_dev_app.dart`) and `coqui/packages/features/feature_map/test/noche_motion_test.dart` use `buildNocheMapRoute` (`lib/src/motion.dart`) inside a `Navigator` with a `HeroController` to exercise and verify the full `pageIn` / `pageOut` transitions.

## Order and branch

- Order: 222 (`lane:feature_map`)
- Branch: `lane/feature_map/222`
