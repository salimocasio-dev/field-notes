# Request: add `cuarto` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/cuarto-sprites.{png,txt}`

## What I need

1. Append the 4 `cuarto` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "cuarto/alba-0-0-0", "kind": "set", "page": "docs/proyecto/pixel/cuarto-set.html", "query": "?hora=alba&luz=0&cuna=0&butaca=0" },
   { "id": "cuarto/alba-1-0-0", "kind": "set", "page": "docs/proyecto/pixel/cuarto-set.html", "query": "?hora=alba&luz=1&cuna=0&butaca=0" },
   { "id": "cuarto/manana-0-0-0", "kind": "set", "page": "docs/proyecto/pixel/cuarto-set.html", "query": "?hora=manana&luz=0&cuna=0&butaca=0" },
   { "id": "cuarto/manana-0-1-1", "kind": "set", "page": "docs/proyecto/pixel/cuarto-set.html", "query": "?hora=manana&luz=0&cuna=1&butaca=1" }
   ```
2. Export `docs/proyecto/pixel/port/cuarto-sprites.png` and `docs/proyecto/pixel/port/cuarto-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_cuarto_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #32 (Order 70, El cuarto) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/cuarto-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.cuarto/32` branches may only modify `lane:scene.cuarto` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- The 4 `cuarto` set reference dumps are committed in `coqui/ref/pp/cuarto/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_cuarto_sprites_test.dart` generates `cuarto-sprites.png` and `cuarto-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 70 (issue #32), branch `lane/scene.cuarto/32`.
