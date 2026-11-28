# Request: add `sala_dia` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/sala_dia-sprites.{png,txt}`

## What I need

1. Append the two `sala_dia` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "sala_dia/0", "kind": "set", "page": "docs/proyecto/pixel/sala_dia-set.html", "query": "?pantalla=0" },
   { "id": "sala_dia/1", "kind": "set", "page": "docs/proyecto/pixel/sala_dia-set.html", "query": "?pantalla=1" }
   ```
2. Export `docs/proyecto/pixel/port/sala_dia-sprites.png` and `docs/proyecto/pixel/port/sala_dia-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_sala_dia_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #34 (Order 72, La sala, de día) needs `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/sala_dia-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.sala_dia/34` branches may only modify `lane:scene.sala_dia` paths, `generated_path_groups.scene_manifests`, and `coqui/requests/`.

## What I am using meanwhile

- Both `sala_dia/0` and `sala_dia/1` set reference dumps are committed in `coqui/ref/pp/sala_dia/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_sala_dia_sprites_test.dart` generates `sala_dia-sprites.png` and `sala_dia-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 72 (issue #34), branch `lane/scene.sala_dia/34`.
