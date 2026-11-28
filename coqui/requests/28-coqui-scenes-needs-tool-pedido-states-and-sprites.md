# Request: add `pedido` entry to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/pedido-sprites.{png,txt}`

## What I need

1. Append the `pedido` state entry to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "pedido/noche", "kind": "set", "page": "docs/proyecto/pixel/pedido-set.html", "query": "?hora=noche" }
   ```
2. Export `docs/proyecto/pixel/port/pedido-sprites.png` and `docs/proyecto/pixel/port/pedido-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_pedido_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #28 (Order 67, El pedido) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/pedido-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.pedido/28` branches may only modify `lane:scene.pedido` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- The `pedido/noche` set reference dump is committed in `coqui/ref/pp/pedido/noche/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_pedido_sprites_test.dart` generates `pedido-sprites.png` and `pedido-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 67 (issue #28), branch `lane/scene.pedido/28`.
