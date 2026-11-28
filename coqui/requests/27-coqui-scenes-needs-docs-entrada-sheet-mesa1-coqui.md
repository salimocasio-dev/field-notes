# Request: nudge `mesa1_coqui` in `entrada-sheet.json` to match `mesa2_coqui` and `mesa3_coqui` (`sprites-apart`)

## What I need

Update `spots.mesa1_coqui` in `docs/proyecto/pixel/entrada-sheet-make.js` and regenerate `docs/proyecto/pixel/entrada-sheet.json` (and copy it to `coqui/packages/core/coqui_scenes/assets/sheets/entrada-sheet.json`) so `mesa1_coqui` moves from `[1.3, 3.35, 0.74]` (screen `[154, 93]`) to `[1.33, 3.50, 0.74]` (screen `[155, 95]`), still strictly inside table 1's top (`u 0.65..2.85`, `v 2.3..3.5`, `z 0.74`).

## Why

In `docs/proyecto/pixel/entrada-sheet.json`, `mesa2_coqui` and `mesa3_coqui` were nudged in `moves` so they pass `sprites-apart` against their tables' seated family spots (at least 12 px down from `mesa*_a`/`mesa*_b` and 28 px across from `mesa*_c`). Because table 1 did not appear in the 7 preview moments (`entrada-preview.html`), `mesa1_coqui` stayed at its un-nudged spec point `[1.3, 3.35, 0.74]` -> `[154, 93]`, which is only 10 px below `mesa1_a`/`mesa1_b` (`[151, 83]` / `[180, 83]`) and 27 px right of `mesa1_c` (`[127, 94]`). Story 84's 1-star ending (`final84(n=1)`) seats the family at `mesa1_a..d` with Coquí at `mesa1_coqui`.

`lane:scene.entrada` may not edit `docs/proyecto/pixel/*` and `entrada.dart` must read named sheet spots directly from `entrada-sheet.json` with no hardcoded coordinate overrides.

## What I am using meanwhile

- `entrada.dart` reads `mesa1_coqui` directly from `entrada-sheet.json` via `_p.at('mesa1_coqui')` with zero hardcoded overrides.
- `coqui/packages/coqui_story_checks/test/support/entrada_rules.dart` keeps `frog-seen` and `heads-clear` 100% strict on `mesa1_coqui` and carries a narrow, self-expiring guard in `sprites-apart` ONLY for `coqui@mesa1_coqui` vs `mesa1_a`/`mesa1_b`/`mesa1_c` that activates only while the loaded sheet still has `|sy(mesa1_coqui) - sy(mesa1_a)| < 12` or `|sx(mesa1_coqui) - sx(mesa1_c)| < 28`. Once `entrada-sheet.json` is updated, the guard automatically stops triggering and full strictness applies.

## Order and branch

Order 66 (issue #27), branch `lane/scene.entrada/27`.
