# Request: Update app Biblioteca tests for Noche ReadingHome (#105)

## What I need

Update the three pre-Noche Biblioteca widget test assertions in `coqui/app/test/` to match the Noche N4.5 `ReadingHome` UI:

1. `coqui/app/test/lessons_test.dart` (lines 303–336):
   - Currently taps `'Add text'` -> fills dialog -> taps `'Add and read'` -> asserts `'Added text'`.
   - Under N4.5 (#105), `+ Add your own` is hidden until N5.4 (#115) merges, the shelf labels personal books as `'Book'` and stories as `'Story'`, and story generation uses `'Write my story'`. Update the test to seed a personal book in `biblioteca` storage (or open via `'Continue reading'` / shelf `'Book'` tile) and assert `'Book'` instead of `'Added text'`.
2. `coqui/app/test/previa_test.dart` (line 351):
   - Currently waits for `find.text('Generate a story')`.
   - Update to `find.text('Write my story')`.
3. `coqui/app/test/tabs_test.dart` (lines 26–34):
   - Currently asserts `find.text('Generate a story')`, `find.text('Add text')`, and `find.text('Stories you generate and texts you add appear here.')`.
   - Update to assert `find.text('Write my story')`, `find.text('Stories you make and books you add appear here.')`, and that `'+ Add your own'` is not shown yet (until N5.4).

## Why

Issue #105 (N4.5 Library home) redesigns `ReadingHome` in `feature_library` to match `docs/proyecto/noche/Noche-Biblioteca.dc.html` (Noche tokens/widgets, `Write my story`, `All` / `Stories` / `Books` shelf with `Book` and `Story` tiles, `Keep reading` card, and `+ Add your own` hidden by default behind `showAddYourOwn` until N5.4 #115 lands). `lane:feature_library` cannot modify `coqui/app/`.

## What I am using meanwhile

`feature_library` has updated its own package tests (`test/module_test.dart`, `test/reading_home_test.dart`, `test/noche_static_test.dart`) and dev harness (`tool/dev_main.dart`) to test the Noche `ReadingHome` and `TextReader` flows in isolation.

## Order and branch

- Order: 105 (N4.5 Library home)
- Branch: `lane/feature_library/105`
