# Request: add `bano` entry to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/bano-sprites.{png,txt}`

## What I need

1. Append the `bano` state entry to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "bano/dia", "kind": "set", "page": "docs/proyecto/pixel/bano-set.html", "query": "?hora=dia" }
   ```
2. Export `docs/proyecto/pixel/port/bano-sprites.png` and `docs/proyecto/pixel/port/bano-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_bano_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #33 (Order 71, El baño) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/bano-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.bano/33` branches may only modify `lane:scene.bano` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- The `bano/dia` set reference dump is committed in `coqui/ref/pp/bano/dia/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_bano_sprites_test.dart` generates `bano-sprites.png` and `bano-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 71 (issue #33), branch `lane/scene.bano/33`.
