# Request: add `noche` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/noche-sprites.{png,txt}`

## What I need

1. Append the four `noche` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "noche/0-1-0-0-0-0", "kind": "set", "page": "docs/proyecto/pixel/noche-set.html", "query": "?luz1=0&luz2=1&luz3=0&tele=0&mesa=0&oscuro=0" },
   { "id": "noche/0-1-0-1-0-0", "kind": "set", "page": "docs/proyecto/pixel/noche-set.html", "query": "?luz1=0&luz2=1&luz3=0&tele=1&mesa=0&oscuro=0" },
   { "id": "noche/1-1-1-0-1-0", "kind": "set", "page": "docs/proyecto/pixel/noche-set.html", "query": "?luz1=1&luz2=1&luz3=1&tele=0&mesa=1&oscuro=0" },
   { "id": "noche/0-0-0-0-0-1", "kind": "set", "page": "docs/proyecto/pixel/noche-set.html", "query": "?luz1=0&luz2=0&luz3=0&tele=0&mesa=0&oscuro=1" }
   ```
2. Export `docs/proyecto/pixel/port/noche-sprites.png` and `docs/proyecto/pixel/port/noche-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_noche_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #35 (Order 73, La noche) is scoped to `lane:scene.noche` (`lane/scene.noche/35`), while `coqui/tool/ref/pp/states.json` belongs to `lane:tool` and `docs/proyecto/pixel/port/` belongs to `lane:docs`.

## What I am using meanwhile

- All four `noche` set reference dumps are committed in `coqui/ref/pp/noche/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_noche_sprites_test.dart` generates `noche-sprites.png` and `noche-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 73 (issue #35), branch `lane/scene.noche/35`.
