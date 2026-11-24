# Request: Language-aware ProgressStore extensions and ProgressStoreCollection contract

## What I need

1. In `coqui_contracts` (`lib/src/progress.dart`, exported from `coqui_contracts.dart`), following the same optional-interface + extension pattern as `LanguageCatalog` / `CourseLanguage` in `lib/src/language.dart`:
   - Add an optional `abstract interface class LanguageProgressStore` exposing:
     - `Language get language;`
     - `double minutesOn(DateTime day);`
     - `int get stageMax;`
     - `int? get streakFreezes;`
   - Add an `extension LanguageProgress on ProgressStore` that delegates to `LanguageProgressStore` when implemented and provides backward-compatible defaults otherwise:
     - `Language get language` -> defaults to `Language.spanish`
     - `double minutesOn(DateTime day)` -> defaults to `0`
     - `int get stageMax` -> defaults to `4`
     - `int? get streakFreezes` -> defaults to `null`
2. Optionally, in `coqui_contracts` (`lib/src/progress.dart`), add an `abstract interface class ProgressStoreCollection` (matching `ProgressStores` in `coqui_progress`) exposing:
   - `ProgressStore forLanguage(Language language);`
   - `List<String> get languagesWithProgress;`
   - `bool hasProgress(String languageCode);`
   - `String get currentLanguageCode;`
   - `set currentLanguageCode(String code);`
   - `int get streak;`
   - `double get minutes;`
   - `double minutesOn(DateTime day);`
   - `Stream<void> get changes;`

## Why

Issue #87 (N2.4) adds per-language progress storage (`coqui.<lang>.palabras.v1`), shared streak/minutes (`coqui.shared.v1`), rolling 35-day `minutesOn(DateTime day)`, `stageMax`, `streakFreezes`, and `ProgressStores` in `coqui_progress`. Downstream feature lanes (#101 Map `minutesOn(today)`, #104 Words `stageMax`, #107 Me 7-day `minutesOn` chart and `streakFreezes`, #93 Your languages sheet) and the shell (#94) only depend on `coqui_contracts` and need to read these members through `ProgressStore` and a multi-language store collection without breaking existing `ProgressStore` fakes in feature tests.

## What I am using meanwhile

- `PalabrasStore` directly exposes `language`, `minutesOn(DateTime day)`, `stageMax` (`4`), `streakFreezes` (`null`), and `hasProgress` as public members without changing `coqui_contracts`.
- `ProgressStores` is exported directly from `coqui_progress` (`lib/coqui_progress.dart`). Once `LanguageProgressStore` and `ProgressStoreCollection` land in `coqui_contracts`, `PalabrasStore` and `ProgressStores` can add `implements` clauses without changing their method signatures.

## Order and branch

- Order: 87
- Branch: `lane/coqui_progress/87`
