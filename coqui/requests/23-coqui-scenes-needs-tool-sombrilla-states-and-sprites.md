# Request: add `sombrilla` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/sombrilla-sprites.{png,txt}`

## What I need

1. ~~Append the six `sombrilla` state entries to `coqui/tool/ref/pp/states.json`:~~ **(Fulfilled in `#258` on `lane/tool/258`.)**
   ```json
   { "id": "sombrilla/mediodia-circulo", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=mediodia&dibujo=circulo" },
   { "id": "sombrilla/tarde-circulo", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=tarde&dibujo=circulo" },
   { "id": "sombrilla/sol-circulo", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=sol&dibujo=circulo" },
   { "id": "sombrilla/mediodia-figura", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=mediodia&dibujo=figura" },
   { "id": "sombrilla/tarde-figura", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=tarde&dibujo=figura" },
   { "id": "sombrilla/sol-figura", "kind": "set", "page": "docs/proyecto/pixel/sombrilla-set.html", "query": "?hora=sol&dibujo=figura" }
   ```
2. Export `docs/proyecto/pixel/port/sombrilla-sprites.png` and `docs/proyecto/pixel/port/sombrilla-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_sombrilla_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #23 (Order 63b, La sombrilla) mentions `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/sombrilla-sprites.*`, while `coqui/tool/check_boundaries.dart` (#170) enforces that `story/<n>` branches may only modify `coqui/packages/core/coqui_scenes/`, `coqui/packages/features/feature_story/`, `coqui/packages/coqui_story_checks/`, `coqui/ref/pp/`, and `coqui/requests/`.

## What I am using meanwhile

- All six `sombrilla` set reference dumps are committed in `coqui/ref/pp/sombrilla/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_sombrilla_sprites_test.dart` generates `sombrilla-sprites.png` and `sombrilla-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 63b (issue #23), branch `story/23`.
