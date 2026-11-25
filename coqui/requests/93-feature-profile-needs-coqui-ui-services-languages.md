# Request: Multi-language stores and available courses on Services

## What I need

1. Fulfill `coqui/requests/87-coqui-progress-needs-coqui-contracts-progress-extensions.md` (`ProgressStoreCollection` in `coqui_contracts`, with `forLanguage(Language)`, `languagesWithProgress`, `hasProgress(String)`, `currentLanguageCode`, `set currentLanguageCode`, and `changes`).
2. In `coqui_ui` (`Services` in `lib/src/contracts.dart`):
   - Expose an optional `ProgressStoreCollection? progressStores` (or equivalent multi-language store accessor) and the list of available catalog courses (`List<CourseCatalog>` / course summaries) so `ProfileModule.screenFor(const LanguagesRoute(), Services s)` can list every started language's store/course and every unstarted catalog language without depending on `coqui_progress` or `coqui_content`.
3. Related: `coqui/requests/101-feature-map-needs-coqui-contracts-story-scene-and-level.md` (exposing the learner's CEFR level on `CourseCatalog` or `ProgressStore` so the sheet's `"<level> · place <N> of <M> · <K> words"` line does not default to `'A1'`).
4. Optional `coqui_ui` typography polish: expose a `14 / 16` w500 meta text style token on `NocheType` (matching `Noche-Idiomas.dc.html:33` and `Noche-Mapa.dc.html:38`) so feature screens do not override `NocheType.bodySmall` inline.

## Why

Story N2.10 ("Your languages (the sheet) and the language chip", issue #93) opens on `LanguagesRoute` and needs:
- Per-language progress (`ProgressStores`) to render `"Your languages"` radio cards (current first, word count, current place, level) and update the active language in the shared store (`coqui.shared.v1` `'idioma'`).
- The catalog's available courses to render `"Add a language"` rows for languages with no progress yet (and hide the section when empty).

## What I am using meanwhile

- Local adapter `LanguagesSource` in `coqui/packages/features/feature_profile/lib/src/languages_data.dart`:
  - `ServicesLanguagesSource` adapts the active `Services.course` + `Services.progress` and stores/reads the active language code under the `'idioma'` setting key.
  - `CatalogLanguagesSource` accepts any list of `CourseCatalog`s, a `storeFor(Language)` lookup, and a shared `ProgressStore` (exercised with Spanish-only and Spanish + Arabic fake courses in `test/languages_sheet_test.dart`, and ready for N2.11 shell wiring once `Services` carries multi-language stores and courses).

## Order and branch

- Order: 93 (N2.10 Your languages sheet)
- Branch: `lane/feature_profile/93`
