# Request: add `cuenta` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/cuenta-sprites.{png,txt}`

## What I need

1. Append the eight `cuenta` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "cuenta/no-abajo", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=no&sillas=abajo" },
   { "id": "cuenta/no-arriba", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=no&sillas=arriba" },
   { "id": "cuenta/lejos-abajo", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=lejos&sillas=abajo" },
   { "id": "cuenta/lejos-arriba", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=lejos&sillas=arriba" },
   { "id": "cuenta/medio-abajo", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=medio&sillas=abajo" },
   { "id": "cuenta/medio-arriba", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=medio&sillas=arriba" },
   { "id": "cuenta/cerca-abajo", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=cerca&sillas=abajo" },
   { "id": "cuenta/cerca-arriba", "kind": "set", "page": "docs/proyecto/pixel/cuenta-set.html", "query": "?guagua=cerca&sillas=arriba" }
   ```
2. Export `docs/proyecto/pixel/port/cuenta-sprites.png` and `docs/proyecto/pixel/port/cuenta-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_cuenta_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #30 (Order 69, La cuenta) is scoped to `lane:scene.cuenta` (`lane/scene.cuenta/30`), while `coqui/tool/ref/pp/states.json` belongs to `lane:tool` and `docs/proyecto/pixel/port/` belongs to `lane:docs`.

## What I am using meanwhile

- All eight `cuenta` set reference dumps are committed in `coqui/ref/pp/cuenta/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_cuenta_sprites_test.dart` generates `cuenta-sprites.png` and `cuenta-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 69 (issue #30), branch `lane/scene.cuenta/30`.
