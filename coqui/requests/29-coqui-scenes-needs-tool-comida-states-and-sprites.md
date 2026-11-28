# Request: add `comida` entry to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/comida-sprites.{png,txt}`

## What I need

1. Append the `comida` state entry to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "comida/noche", "kind": "set", "page": "docs/proyecto/pixel/comida-set.html", "query": "?hora=noche" }
   ```
2. Export `docs/proyecto/pixel/port/comida-sprites.png` and `docs/proyecto/pixel/port/comida-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_comida_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #29 (Order 68, La comida) lists `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/comida-sprites.*`, while `tools/lanes.json` restricts `lane/scene.comida/29` to `coqui/packages/core/coqui_scenes/`, `coqui/packages/coqui_story_checks/`, `coqui/ref/pp/comida/`, shared scene manifests, and `coqui/requests/`.

## What I am using meanwhile

- The `comida/noche` set reference dump is committed in `coqui/ref/pp/comida/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ).
- `coqui/packages/core/coqui_scenes/tool/make_comida_sprites_test.dart` generates `comida-sprites.png` and `comida-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 68 (issue #29), branch `lane/scene.comida/29`.
