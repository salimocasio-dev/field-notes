# Request: Reader body font styles (Atkinson & Lexend) in `coqui_ui`

## What I need

Expose `NocheType` reader body styles (or a script-aware helper) for the three reader font choices in `coqui/packages/core/coqui_ui/lib/src/noche_tokens.dart`:

- `NocheType.bookBody` (`nocheFontLiterata`, weight 400, 19 / 31) — already exists.
- `NocheType.bookBodyAtkinson` (`nocheFontAtkinson`, weight 400, 19 / 31) — or `NocheType.bookBodyFor(String family)` accepting `nocheFontLiterata`, `nocheFontAtkinson`, or `nocheFontLexend`.
- `NocheType.bookBodyLexend` (`nocheFontLexend`, weight 400, 19 / 31).

`coqui_ui` already bundles `Lexend-400.ttf` and `Lexend-500.ttf`, declares `Lexend` and `packages/coqui_ui/Lexend` in `pubspec.yaml`, and exports `const String nocheFontLexend = 'Lexend'`, but `NocheType` currently defines no `TextStyle` using `nocheFontLexend`.

## Why

Story N5.2 ("Text and page settings", issue #113, board `docs/proyecto/noche/Noche-Lector-Aa.dc.html`) offers Literata, Atkinson, and Lexend for both the 80-high `"Ag"` font tiles and the reader page body text. Under `22-noche-epics.md` Part 1.4, `.github/workflows/coqui-guardrails.yml` (`grep -nE 'Color\(0x|fontFamily\s*:'`), and `noche_static_test.dart`, feature packages may not write `fontFamily:` outside `coqui_ui`, and `lane/feature_library/113` may not edit `coqui_ui`.

## What I am using meanwhile

In `coqui/packages/features/feature_library/lib/src/reader_model.dart`, `ReaderFont.literata` uses `NocheType.bookBody` (Literata w400, preview w500), `ReaderFont.atkinson` uses `NocheType.body` (Atkinson Hyperlegible Next w500), and `ReaderFont.lexend` uses `NocheType.body` with `FontWeight.w400` (distinct weight from Atkinson, persisted as `'lexend'`) until `NocheType.bookBodyLexend` lands in `coqui_ui`.

## Order and branch

- Order: #113 (N5.2 Text and page settings)
- Branch: `lane/feature_library/113`
