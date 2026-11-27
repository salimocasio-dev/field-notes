# Request: add `cielo` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/cielo-sprites.{png,txt}`

## What I need

1. Append the ten `cielo` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "cielo/azul-arriba", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=azul&toldo=arriba" },
   { "id": "cielo/azul-abajo", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=azul&toldo=abajo" },
   { "id": "cielo/nublado-arriba", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=nublado&toldo=arriba" },
   { "id": "cielo/nublado-abajo", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=nublado&toldo=abajo" },
   { "id": "cielo/gris-arriba", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=gris&toldo=arriba" },
   { "id": "cielo/gris-abajo", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=gris&toldo=abajo" },
   { "id": "cielo/rosa-arriba", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=rosa&toldo=arriba" },
   { "id": "cielo/rosa-abajo", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=rosa&toldo=abajo" },
   { "id": "cielo/noche-arriba", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=noche&toldo=arriba" },
   { "id": "cielo/noche-abajo", "kind": "set", "page": "docs/proyecto/pixel/cielo-set.html", "query": "?cielo=noche&toldo=abajo" }
   ```
2. Export `docs/proyecto/pixel/port/cielo-sprites.png` and `docs/proyecto/pixel/port/cielo-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_cielo_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #25 (Order 65, El cielo) lists `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/cielo-sprites.*`, while `coqui/tool/check_boundaries.dart` enforces that `story/<n>` branches may only modify `coqui/packages/core/coqui_scenes/`, `coqui/packages/features/feature_story/`, `coqui/packages/coqui_story_checks/`, `coqui/ref/pp/`, and `coqui/requests/`.

## What I am using meanwhile

- All ten `cielo` set reference dumps are committed in `coqui/ref/pp/cielo/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_cielo_sprites_test.dart` generates `cielo-sprites.png` and `cielo-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 65 (issue #25), branch `story/25`.
