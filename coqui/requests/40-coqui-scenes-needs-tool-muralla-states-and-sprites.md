# Request: add `muralla` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/muralla-sprites.{png,txt}`

## What I need

1. Append the 2 `muralla` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "muralla/noche", "kind": "set", "page": "docs/proyecto/pixel/muralla-set.html", "query": "?hora=noche" },
   { "id": "muralla/tarde_noche", "kind": "set", "page": "docs/proyecto/pixel/muralla-set.html", "query": "?hora=tarde_noche" }
   ```
2. Export `docs/proyecto/pixel/port/muralla-sprites.png` and `docs/proyecto/pixel/port/muralla-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_muralla_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #40 (Order 77, La muralla) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/muralla-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.muralla/40` branches may only modify `lane:scene.muralla` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- Both `muralla` set reference dumps (`noche`, `tarde_noche`) are committed in `coqui/ref/pp/muralla/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_muralla_sprites_test.dart` generates `muralla-sprites.png` and `muralla-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 77 (issue #40), branch `lane/scene.muralla/40`.
