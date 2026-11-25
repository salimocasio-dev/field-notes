# Request: Promote the 31 reviewed calls to live course data

## What I need

1. Promote `coqui/packages/core/coqui_content/data/llamadas.json` (the 10 main calls and 21 smaller calls across all 10 places, with their Puerto Rican Spanish titles and one-line English jobs) into the live course data (`historia/datos/llamadas.json` or the `content/` layout, without touching `historia/cuentos/`), and update any downstream fixtures/generators (`coqui/tool/export_datos.mjs`, `coqui_testing` sample data) if needed.
2. Coordinate that promotion with `feature_speaking` (`hablar_model.dart` / `call_catalog.dart`): `feature_speaking` currently uses `course.callFor(place.id) != null` to decide whether a place's call is live vs "Coming soon". Once `feature_speaking` reads `course.callsFor(place.id)` directly and checks live readiness (e.g. `brief.opening.isNotEmpty`), the 31-call `llamadas.json` can be served live without falsely unlocking places whose Spanish `opening` prompts are not yet written.

## Why

Issue `#6` (`lane:coqui_content`) requires `coqui_content` to serve the 31 reviewed calls from course data with zero Spanish text in Dart code, while `lane/coqui_content/6` is prohibited by `coqui/tool/check_boundaries.dart` from editing `historia/`, `feature_speaking/`, `coqui_testing/`, or `coqui/tool/`. Additionally, `historia/datos/llamadas.json` currently serves only `"casa"` on the legacy site and `real_tree_test.dart` checks parity against it.

## What I am using meanwhile

- `ContentCatalog` implements `CallsCatalog` (`callsFor(placeId)`) and parses both the legacy single-object-per-place format and the multi-call JSON array format from `datos/llamadas.json`.
- All 31 reviewed calls live as course JSON data in `coqui/packages/core/coqui_content/data/llamadas.json` and are verified end-to-end through `ContentCatalog` in `coqui/packages/core/coqui_content/test/calls_data_test.dart`.

## Order and branch

- Order: Issue `#6` (`lane:coqui_content`)
- Branch: `lane/coqui_content/6`
