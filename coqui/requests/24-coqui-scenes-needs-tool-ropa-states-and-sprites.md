# Request: add `ropa` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/ropa-sprites.{png,txt}`

## What I need

1. Append the two `ropa` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "ropa/tarde-0", "kind": "set", "page": "docs/proyecto/pixel/ropa-set.html", "query": "?hora=tarde&guagua=0" },
   { "id": "ropa/ocaso-1", "kind": "set", "page": "docs/proyecto/pixel/ropa-set.html", "query": "?hora=ocaso&guagua=1" }
   ```
2. Export `docs/proyecto/pixel/port/ropa-sprites.png` and `docs/proyecto/pixel/port/ropa-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_ropa_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #24 (Order 64, La ropa) mentions `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/ropa-sprites.*`, while `coqui/tool/check_boundaries.dart` (#170) enforces that `story/<n>` branches may only modify `coqui/packages/core/coqui_scenes/`, `coqui/packages/coqui_story_checks/`, `coqui/ref/pp/`, and `coqui/requests/`.

## What I am using meanwhile

- Both `ropa` set reference dumps are committed in `coqui/ref/pp/ropa/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_ropa_sprites_test.dart` generates `ropa-sprites.png` and `ropa-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 64 (issue #24), branch `story/24`.
