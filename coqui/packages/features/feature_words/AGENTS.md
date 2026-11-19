# feature_words

Palabras.

- Kind: Flutter package.
- Replaces: the Palabras tab in app.html.
- One package is one lane. Branch: `lane/feature_words/<order number>`.
- Work orders: 21.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui.
- Coquí packages: `coqui_contracts`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_words.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the file holds a library comment and nothing else.
- Later it holds one thing: its module, a `FeatureModule` (boundary rule 4).

## Run and test it alone

```
cd coqui/packages/features/feature_words
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A dev entry that starts the feature on the fakes comes with order 02. It lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_words`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 10-leer-y-repaso, "Rules that bind this (his)":

- No English in learning content: no translation, no gloss. English only in menus, labels, the welcome, the stuck line.
- No self-report: no swipe-to-rate, no "I knew it". The app finds out by asking.
- Reading from day 1, not tracked until A2: reading writes no word record.
- Original pixel art; pictures must read with zero words known.
- Only the map is game-styled. Reading and review are calm screens (UI plan).
- Spanish text is shown exactly as recorded.

From 10-leer-y-repaso, "The tab":

- Top: the review card (as today, renamed "Repaso"): "N words today · about M min" and Start; when nothing is due: "Nothing due today" and "Practice" (asks his weakest heard words, schedule untouched, as now).
- Then words grouped by place, in story order. Each word is a card: its picture (pair words) or a plain tile (words with no picture), the word, and two small four-dot meters with labels "Ear" and "Mouth" (dots = stage 1 to 4). The word is always spelled (decided Nov 19 after the fresh read: the "?" before stage 2 read as a bug, and the books show every word written from day 1 anyway, so hiding it protected nothing).
- Tap a card: a word sheet opens: the big picture, the word, Ear and Mouth meters with the next return in English ("Comes back in 2 days"), and "Heard in" — up to five lines from stories he has played that contain the word, each with a play button (the story's own recording). No translation.
- "Add a word or a goal" stays (his vision) with honest text: "Saved. Material for it comes later." and the saved list.

From 10-leer-y-repaso, "After the first fresh read (Nov 19)":

- Nothing is ever covered by the tab bar or the Mapa disc: lists, grid and sheets end clear of it.
- Palabras: one key line under the grid title: "Ear: you know it when you hear it. Mouth: you can say it."; a word with no picture is a plain tile with the word large (no empty picture box); the word sheet keeps the word in its header when scrolled; the word is bold inside its "Heard in" lines.

From 10-leer-y-repaso, "Not now (said so it is not invented)":

- Word-level karaoke or word audio (no word timing exists).
- Themes (dark/sepia), reading tracking, new recordings, new review item types beyond ¿Cuál?, pictures for the 28 words without a pair.

From 09-ui-plan, "Reading and review (Nov 19, v=39)":

- Palabras: the Repaso card, then every word he has met, by place, with its picture or a plain tile, and the Ear and Mouth meters (four dots each). A tap opens the word sheet: big picture, meters, when it comes back, "Heard in" with a play button on each line. "Add a word or a goal" saves the text and says material comes later.

From 03-requirements, "What the app is":

- Each language skill keeps its own retention value per word (missing a word while speaking counts against speaking only).
