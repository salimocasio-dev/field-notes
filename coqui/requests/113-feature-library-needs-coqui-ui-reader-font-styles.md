# Request: Reader body font styles (Atkinson & Lexend) and group a11y keys in `coqui_ui`

## What I need

1. Expose `NocheType` reader body styles (or a script-aware helper) for the three reader font choices in `coqui/packages/core/coqui_ui/lib/src/noche_tokens.dart`:
   - `NocheType.bookBody` (`nocheFontLiterata`, weight 400, 19 / 31) — already exists.
   - `NocheType.bookBodyAtkinson` (`nocheFontAtkinson`, weight 400, 19 / 31).
   - `NocheType.bookBodyLexend` (`nocheFontLexend`, weight 400, 19 / 31) — `coqui_ui` already bundles `Lexend-400.ttf`/`500.ttf` and exports `const String nocheFontLexend = 'Lexend'`, but `NocheType` currently exposes no `TextStyle` using `nocheFontLexend`.
2. Add `NocheA11y` role keys in `coqui/packages/core/coqui_ui/lib/src/noche_a11y.dart` for the settings radio groups (`font`, `lineSpacing`, `pageColour`).

## Why

Story N5.2 ("Text and page settings", issue #113, board `docs/proyecto/noche/Noche-Lector-Aa.dc.html`) offers Literata, Atkinson, and Lexend for both the 80-high `"Ag"` font tiles and the reader page body text. Under `22-noche-epics.md` Part 1.4, `.github/workflows/coqui-guardrails.yml` (`grep -nE 'Color\(0x|fontFamily\s*:'`), and `noche_static_test.dart`, feature packages may not write `fontFamily:` outside `coqui_ui`, and `lane/feature_library/113` may not edit `coqui_ui`.

## What I am using meanwhile

- In `coqui/packages/features/feature_library/lib/src/reader_model.dart`, `ReaderFont.literata` uses `NocheType.bookBody` (`Literata`) and `ReaderFont.atkinson` uses `NocheType.body` (`Atkinson Hyperlegible Next`).
- The Lexend tile in `lib/src/reader_settings_sheet.dart` is intentionally disabled (`ReaderSettings.lexendAvailable = false`) so the UI never mislabels Atkinson as Lexend; once `NocheType.bookBodyLexend` lands in `coqui_ui`, flipping `ReaderSettings.lexendAvailable` and wiring `NocheType.bookBodyLexend` enables it in one place.
- Radio-group semantic labels in `lib/src/reader_settings_sheet.dart` check `NocheA11y.lessonLabelsInCourseLanguage` and `course.language.a11yWords` for `'font'`, `'lineSpacing'`, and `'pageColour'` with English fallbacks until `NocheA11y` exports those constants.

## Order and branch

- Order: #113 (N5.2 Text and page settings)
- Branch: `lane/feature_library/113`
