# Request: add `entrada` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/entrada-sprites.{png,txt}`

## What I need

1. Append the six `entrada` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "entrada/ocaso-puesta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=ocaso&cuerda=puesta" },
   { "id": "entrada/ocaso-abierta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=ocaso&cuerda=abierta" },
   { "id": "entrada/noche-puesta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=noche&cuerda=puesta" },
   { "id": "entrada/noche-abierta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=noche&cuerda=abierta" },
   { "id": "entrada/tarde_noche-puesta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=tarde_noche&cuerda=puesta" },
   { "id": "entrada/tarde_noche-abierta", "kind": "set", "page": "docs/proyecto/pixel/entrada-set.html", "query": "?hora=tarde_noche&cuerda=abierta" }
   ```
2. Export `docs/proyecto/pixel/port/entrada-sprites.png` and `docs/proyecto/pixel/port/entrada-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_entrada_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #27 (Order 66, La entrada) lists `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/entrada-sprites.*`, while `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` enforce that `lane/scene.entrada/27` branches may only modify `lane:scene.entrada`'s paths and `coqui/requests/`.

## What I am using meanwhile

- All six `entrada` set reference dumps are committed in `coqui/ref/pp/entrada/` and indexed in `coqui/ref/pp/index.json` (verified against `entrada_set_test.dart`, 0 of 51,840 pixels/zb/kinds differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_entrada_sprites_test.dart` generates `entrada-sprites.png` and `entrada-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 66 (issue #27), branch `lane/scene.entrada/27`.
