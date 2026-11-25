# coqui_progress

Word records and the scheduler. Pure Dart.

- Kind: pure Dart (no Flutter SDK).
- Replaces: historia/palabras.js.
- One package is one lane. Branch: `lane/coqui_progress/<order number>`.
- Work orders: 16.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts.
- Coquí packages: `coqui_contracts`.
- Third party: `collection` ^1.19.1.
- Dev only: `lints`, `test`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_progress.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- It exports `PalabrasStore`: the `ProgressStore` of page 12, section 2, on a `KeyValueStore` and a `Clock` (order 16, a port of historia/palabras.js). `lib/src/palabras_store.dart` is the port, function by function with the old names in comments; `lib/src/js.dart` holds the JavaScript behaviours it leans on (truthiness, `JSON.stringify` with numbers written as JavaScript writes them, `Object.assign`).
- `PalabrasStore` also implements `CallProgressStore` (`callDone` / `markCallDone`, persisted under per-language `db.llamadas`).
- The store is the JSON object of palabras.js kept as a map, so unknown keys and half-empty records stay as they are; `WordRecord` and the other typed records are copies made from it.

## Run and test it alone

```
cd coqui/packages/core/coqui_progress
dart test -p vm
dart test -p chrome   # needs CHROME_EXECUTABLE, see the runbook
bash tool/test_zones.sh   # the suite four times: TZ=UTC and TZ=America/New_York, each on the VM and in Chrome
node tool/make_fixture.mjs   # makes test/fixtures/progress_fixture.dart again: after node coqui/tool/ref/progress/make.mjs, or when historia/app.html or palabras.js changes
```

- `test/replay_test.dart` replays the recordings of `coqui/ref/progress/` (as the Dart fixture) in the zone the test process runs in: UTC or America/New_York, and fails in any other. Plain `dart test` replays the zone the machine has; `tool/test_zones.sh` covers both.
- `test/fixture_files_test.dart` (VM only) checks that the fixture equals the files, and that `historia/app.html` still contains the pieces below.
- The members palabras.js does not have (`markRead`, `hasRead`, `add`, `added`, `played`, `setting`, `setSetting`, `levelResult`, `minutes`) are ported from `historia/app.html`. `tool/app_sequences.mjs` cuts each piece out of the page (`marcaLeido`, `extra`, `hecho`, the `onclick` handlers that write `ajustes`, ...), runs it against the real palabras.js once per zone, and `make_fixture.mjs` writes what the store was after every call into the fixture (`fixtureAppSequences`). `replay_test.dart` replays them like the recorded sequences.

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "What the app is":

- Each language skill keeps its own retention value per word (missing a word while speaking counts against speaking only).

From 03-requirements, "What the app is":

- "For a true beginner experience every word is new. So it goes into the system that way, you can ask more questions as the person learns more words… Once the word is consistently used, its goes into good and comes less frequently." "And you can just test someone and understand what level they are anyway."

From 03-requirements, "Speaking inside the stories (Nov 16)":

- Asked when the research says to add speaking: per word, 2 to 3 days after he first hears it. His conclusion: "So basically the design is fine. You speak to Danny after finishing a story. Except right now we should probably put some speaking prompts in the next stories that use the previously learned vocabulary".

From 10-leer-y-repaso, "Rules that bind this (his)":

- Reading from day 1, not tracked until A2: reading writes no word record.

From 10-leer-y-repaso, "Repaso (¿Cuál?): the session":

- The scheduler (palabras.js) is unchanged except: the due check uses the palabras clock, not Date.now().
