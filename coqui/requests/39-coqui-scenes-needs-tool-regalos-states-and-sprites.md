# Request: add `regalos` entry to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/regalos-sprites.{png,txt}`

## What I need

1. Append the `regalos` state entry to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "regalos/noche", "kind": "set", "page": "docs/proyecto/pixel/regalos-set.html", "query": "?" }
   ```
2. Export `docs/proyecto/pixel/port/regalos-sprites.png` and `docs/proyecto/pixel/port/regalos-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_regalos_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #39 (Order 76, Los regalos) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/regalos-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.regalos/39` branches may only modify `lane:scene.regalos` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- The `regalos/noche` set reference dump is committed in `coqui/ref/pp/regalos/noche/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_regalos_sprites_test.dart` generates `regalos-sprites.png` and `regalos-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 76 (issue #39), branch `lane/scene.regalos/39`.
