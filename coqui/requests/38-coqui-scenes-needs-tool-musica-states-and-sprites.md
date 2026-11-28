# Request: add `musica` entry to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/musica-sprites.{png,txt}`

## What I need

1. Append the `musica` state entry to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "musica/noche", "kind": "set", "page": "docs/proyecto/pixel/musica-set.html", "query": "?hora=noche" }
   ```
2. Export `docs/proyecto/pixel/port/musica-sprites.png` and `docs/proyecto/pixel/port/musica-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_musica_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #38 (Order 75, La música) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/musica-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.musica/38` branches may only modify `lane:scene.musica` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- The `musica/noche` set reference dump is committed in `coqui/ref/pp/musica/noche/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`).
- `coqui/packages/core/coqui_scenes/tool/make_musica_sprites_test.dart` generates `musica-sprites.png` and `musica-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 75 (issue #38), branch `lane/scene.musica/38`.
