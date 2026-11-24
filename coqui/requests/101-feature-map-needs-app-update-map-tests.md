# Request: Update app/test map assertions for N4.1 Noche UI

## What I need

In `coqui/app/test/` (`start_test.dart`, `lessons_test.dart`, `tabs_test.dart`, `story_test.dart`, `previa_test.dart`), update the assertions that inspect the old `v=39` map widgets and copy:
- `find.byType(MapChips)` -> N4.1's top chips (`Spanish`, `A1`, streak chip)
- `find.byType(TodayCard)` -> N4.1's Up next card (`NochePlayDisc` / `NocheCard`)
- `find.text('1 · La casa')`, `find.text('2 · El parque')`, `find.text('4 · El colmado')` -> `'You are here'` / `'UP NEXT · LA CASA'` / `'UP NEXT · EL PARQUE'` / `'UP NEXT · EL COLMADO'`
- `find.text('TODAY · 1 OF 3')`, `find.text('New story · play it twice · 4 min')`, `find.text('10 words coming back · 6 min')` -> N4.1's Up next labels (`'UP NEXT · ...'`, `'New story · 4 min'`, `'10 words coming back · 6 min'`)

## Why

Story N4.1 ("Map (home)", issue #101) replaces `MapScreen`'s old `MapChips` and `TodayCard` with the Noche UI (`Noche-Mapa.dc.html`). `lane/feature_map/101` cannot edit files under `coqui/app/`.

## What I am using meanwhile

All unit, widget, and golden tests inside `feature_map` pass on `feature_map`'s own test harness; `coqui/app/test/` updates belong to `lane:app` (N4.9, #110).

## Order and branch

- Order: 101 (N4.1 Map home)
- Branch: `lane/feature_map/101`
