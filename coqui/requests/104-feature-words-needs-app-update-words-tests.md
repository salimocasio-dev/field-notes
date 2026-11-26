# Request: Update two coqui/app tests for N4.4 Noche WordsTab

## What I need

Update two tests in `coqui/app/test/` that still expect the legacy v=39 Palabras card strings (`Repaso`, `10 words today · about 2 min`, `Start`) on the Words tab:

1. `coqui/app/test/tabs_test.dart`, test `(b)` (lines 40–54):
   - Currently waits for `find.text('Repaso')` and asserts `find.text('10 words today · about 2 min')` and `find.text('Start')`.
   - Update to accept N4.4's Noche `WordsTab` (`find.text('Words')`, `find.text('Start review')`, due card text `'words come\nback today'`, and `'casa'` in the soonest-first list) alongside or replacing the legacy strings.
2. `coqui/app/test/lessons_test.dart`, test `(m)` (lines 297–315):
   - Currently waits for and taps `find.text('Start')` on the Words tab.
   - Update to wait for and tap `find.text('Start review')` (or `Start` on pre-N4.4 `main`).

## Why

Story N4.4 ("Words", issue #104) replaces the legacy v=39 Palabras Repaso card (`Repaso`, `10 words today · about 2 min`, `Start`) with the Noche Words screen (`Words`, due card, 5-column `NocheBarChart`, `NocheSegmented` skill switch, soonest-first word list, and `"Start review"` / `"Practice"` button without minutes estimate). Changing `coqui/app/test/` from `lane/feature_words/104` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All `feature_words` unit, widget, static, Arabic/RTL, bucket, and screenshot tests pass inside `coqui/packages/features/feature_words/`.

## Order and branch

- Order: 104 (N4.4 Words)
- Branch: `lane/feature_words/104`
