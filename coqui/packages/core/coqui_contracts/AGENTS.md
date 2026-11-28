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
- Issue `#5`: `CallBrief` fields `id`, `title`, `jobEn`, `isMain`, and nullable `photo`; `CallsCatalog` + `CourseCalls`
  extension (`course.callsFor(placeId)`, separate interface falling back to `[callFor(placeId)]`); `CallRoute(placeId,
  {callId})`; and `CallProgressStore` + `CallProgress` extension (`progress.callDone(callId)`, separate interface
  defaulting to `false`).
- Issue `#61`: `StoryMeta.minApp` (optional `int?`, omitted from JSON when null); `MinAppCatalog` + `CourseMinApp`
  extension (`course.minApp` defaulting to `null`, `course.minAppFor(storyId)` returning the higher of course/story
  `minApp` or `null`); and `AppNumberInfo` + `AppInfoNumber` extension (`info.appNumber` parsing the leading numeric
  prefix of `build` or `0` for unnumbered/`'dev'` builds, and `info.supportsMinApp(minApp)`).
- Issue `#171`: `CallProgressStore.markCallDone(callId)` + `CallProgress.markCallDone(callId)` (no-op fallback);
  `LanguageProgressStore` + `LanguageProgress` extension (`language`, `minutesOn(day)`, `stageMax`, `streakFreezes`)
  and `ProgressStoreCollection`; optional `Language? language` parameter on `repasoTokens` and `RepasoServing`
  (with `repasoServing` forwarding `course.language`); `VariableSpeedClipPlayer` + `ClipPlayerSpeed.playAtRate`;
  and `DeletableKeyValueStore` + `KeyValueStoreDelete.delete`.

## How contracts change

- **New capability = new interface; existing interfaces never gain members.** Adding an abstract member to an existing interface breaks implementers and fakes in other packages. Declare a new small `abstract interface class` for the capability and, when callers need a helper on the base interface, expose it via an `extension` that checks `this is NewCapability`.
- **No `abstract mixin class` defaults for contracts.** Most implementers use `implements`, which inherits no default implementation and would still break if a member were added.
- **Explicit fallback rule (never quiet success on sensitive capabilities).** When a store or platform lacks a capability, the caller must be told. For **delete, grant, pay, sign-in, and call tokens**, the fallback refuses or throws (for example `UnsupportedError`) and never reports quiet success. Safe read-only queries may return a documented default only when that default cannot mask a failed write, deletion, grant, payment, sign-in, or token request.
- **Conformance branches (`contracts/<n>`).** A `contracts/<n>` branch may pair changes in `coqui/packages/core/coqui_contracts/lib/` with small in-place conformance edits in existing `.dart` files of implementing packages (capped at 6 added+deleted lines per file to accommodate `dart format` wrapping of one-line `implements`/`@override` updates). Both `coqui/tool/check_boundaries.dart` and `.github/scripts/check_lanes.py` (via `tools/lanes.json`) enforce `^contracts/[0-9]+$`, require a change under `coqui/packages/core/coqui_contracts/lib/`, and deny locked paths (Danny/ElevenLabs call code, mobile build configs, and `historia/cuentos/`).

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
