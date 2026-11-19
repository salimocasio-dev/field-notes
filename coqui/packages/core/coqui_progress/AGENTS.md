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
- Today the file holds a library comment and nothing else.
- Later it holds the `ProgressStore` of page 12, section 2, on a `KeyValueStore` and a `Clock`.

## Run and test it alone

```
cd coqui/packages/core/coqui_progress
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
