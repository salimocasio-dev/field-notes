# Request: add `orilla` entries to `coqui/tool/ref/pp/states.json` and export `docs/proyecto/pixel/port/orilla-sprites.{png,txt}`

## What I need

1. Append the five `orilla` state entries to `coqui/tool/ref/pp/states.json`:
   ```json
   { "id": "orilla/manana-0-0", "kind": "set", "page": "docs/proyecto/pixel/orilla-set.html", "query": "?hora=manana&castillo=0&manta=0" },
   { "id": "orilla/manana-1-0", "kind": "set", "page": "docs/proyecto/pixel/orilla-set.html", "query": "?hora=manana&castillo=1&manta=0" },
   { "id": "orilla/mediodia-0-0", "kind": "set", "page": "docs/proyecto/pixel/orilla-set.html", "query": "?hora=mediodia&castillo=0&manta=0" },
   { "id": "orilla/tarde-0-1", "kind": "set", "page": "docs/proyecto/pixel/orilla-set.html", "query": "?hora=tarde&castillo=0&manta=1" },
   { "id": "orilla/ocaso-0-1", "kind": "set", "page": "docs/proyecto/pixel/orilla-set.html", "query": "?hora=ocaso&castillo=0&manta=1" }
   ```
2. Export `docs/proyecto/pixel/port/orilla-sprites.png` and `docs/proyecto/pixel/port/orilla-sprites.txt` for the content lane by running:
   `COQUI_OUT=../../../../docs/proyecto/pixel/port flutter test tool/make_orilla_sprites_test.dart` (in `coqui/packages/core/coqui_scenes`).

## Why

Issue #22 (Order 62b, La orilla) mentions `coqui/tool/ref/pp/states.json` and `docs/proyecto/pixel/port/orilla-sprites.*`, while `coqui/tool/check_boundaries.dart` (#170) enforces that `story/<n>` branches may only modify `coqui/packages/core/coqui_scenes/`, `coqui/packages/features/feature_story/`, `coqui/packages/coqui_story_checks/`, `coqui/ref/pp/`, and `coqui/requests/`.

## What I am using meanwhile

- All five `orilla` set reference dumps are committed in `coqui/ref/pp/orilla/` and indexed in `coqui/ref/pp/index.json` (verified with `node coqui/tool/ref/pp/check.js`, 0 of 51,840 pixels differ on every state).
- `coqui/packages/core/coqui_scenes/tool/make_orilla_sprites_test.dart` generates `orilla-sprites.png` and `orilla-sprites.txt` into `COQUI_OUT` on demand.

## Order and branch

Order 62b (issue #22), branch `story/22`.
