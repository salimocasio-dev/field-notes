# coqui_contracts

Models, interfaces, routes. Pure Dart.

- Kind: pure Dart (no Flutter SDK).
- Replaces: the shapes in palabras.js, curso.js, the story file; `norm`.
- One package is one lane. Branch: `lane/coqui_contracts/<order number>`.
- Work orders: 02, by the orchestrator. After order 02 only the orchestrator changes a contract, through a request.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: nothing.
- Coquí packages: none.
- Third party: `collection` ^1.19.1.
- Dev only: `lints`, `test`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_contracts.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Since order 02 it holds page 12, section 2: the models, the interfaces, the routes, `normalize` (PAL.norm, through `lib/src/normalize_table.dart`) and `Mulberry32`. `coqui/tool/contracts/make_fixtures.mjs` makes the table and the test fixtures from the old code.

- Order 27: `RepasoData` and its parts (`lib/src/repaso.dart`), the typed `historia/datos/repaso.json` that
  `coqui/tool/make_repaso.py --app` writes, and `RepasoCatalog` (`RepasoData? get repaso`). It is an interface of its own,
  not a member of `CourseCatalog`: a new member there would break the catalogs other packages' tests implement.
- The readers' fixes to Repaso: `RepasoServing` and `repasoServing(course, progress)` (same file): the one rule for which
  words Repaso can serve now (a word with a picture pair and a sentence of his, or a sentence of a story he has finished
  that scores it with two fair wrong tiles among the words he has met). The session's plan, the Palabras tab's Repaso
  card ("N words today") and the map's Today card all ask it; it gives null when the course has not read the games'
  data, and the caller then keeps today's rule (a word with a picture pair). `repasoStoryFinished`, `repasoTokens`.
- N2.1: `Language`, `LanguageDirection`, `WordToken`, `LanguageCatalog` + `CourseLanguage` extension (`course.language`,
  default `Language.spanish`, separate interface like `RepasoCatalog` so existing catalogs keep compiling), `Plan`,
  `Feature`, `Entitlements`, `AllowAllEntitlements`, four new routes (`LanguagesRoute`, `PlansRoute`, `ImportRoute`,
  `PlaceRoute`), and `CallBrief.agentId` (default `spanishCallAgentId`). Global `normalize()` stays, delegating to
  `Language.spanish.normalize`, documented as deprecated until N2.11 removes it.

## Run and test it alone

```
cd coqui/packages/core/coqui_contracts
dart test -p vm
dart test -p chrome   # needs CHROME_EXECUTABLE, see the runbook
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

None apply directly.
