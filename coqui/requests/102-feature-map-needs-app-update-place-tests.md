# Request: Update two coqui/app tests for N4.2 PlaceScreen

## What I need

Update two tests in `coqui/app/test/` that still assume tapping a place opens the legacy `CoquiSheet` and that `PlaceRoute('casa')` is unanswered by `MapModule`:

1. `coqui/app/test/tabs_test.dart`, test `(c)` (lines 90–143):
   - Currently expects `CoquiSheet` containing `PlayButton` when tapping a place on the map.
   - Update to expect N4.2's `PlaceScreen` (with `NocheTabBar` still visible on `NocheTabs.map`, `place-play-bar` / `NochePlayBar`, and `story-tile-*` tiles) and verify that tapping a story (or `NochePlayBar`) opens `LessonFrame` with `NocheTabBar` hidden, and closing returns to the map with `NocheTabBar` back.
2. `coqui/app/test/noche_shell_test.dart`, test `'unanswered LanguagesRoute, PlansRoute, ImportRoute, and PlaceRoute do nothing and log a line without crashing'` (lines 259–304):
   - Currently asserts `PlaceRoute('casa')` and `/lugar/casa` are unanswered by any module and emit a log line.
   - Remove `PlaceRoute('casa')` / `/lugar/casa` from the unanswered list (or replace with an unknown place id such as `PlaceRoute('no-existe')` / `/lugar/no-existe`, which `MapModule.screenFor` still returns `null` for once the course is loaded).

## Why

Story N4.2 ("Place screen", issue #102) replaces `PlaceSheetBody` (`CoquiSheet`) with `PlaceScreen` and wires `MapModule.screenFor` to answer `PlaceRoute`. Changing `coqui/app/test/` from `lane/feature_map/102` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All `feature_map` unit, widget, static, and golden tests pass against `PlaceScreen` and `MapModule.screenFor(PlaceRoute(...))` inside `coqui/packages/features/feature_map/`.

## Order and branch

- Order: 102 (N4.2 Place screen)
- Branch: `lane/feature_map/102`
