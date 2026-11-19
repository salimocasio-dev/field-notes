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
- It exports one thing: its module, `WordsModule` (boundary rule 4). Its id is `words`; `tab(s)` is the Palabras tab; `screenFor` answers `TabRoute('words')` with the same screen and every other route with null.
- Since order 21 the screen is the Palabras tab of v=39 (`lib/src/`): `words_view.dart` (app.html `palabras`: what is shown, worked out from `Services.progress` and `Services.course`), `words_tab.dart` (the tab), `word_sheet.dart` (`palabra` and `oyeLinea`: the word sheet's content, opened with coqui_ui's `showCoquiSheet` so that its scrim dims the tab bar), `add_box.dart` (`extra`), `balanced_key_line.dart` (the key line, see "Stand-ins"), `text_rules.dart` (`occs`, `vuelve`). The tab reads the store again after every save of it. "Palabras" and "Repaso" come from `CoquiLabels`.
- The dev entry is `tool/dev_main.dart` (below); `web/` is there for it.

## Stand-ins

What this package carries because the shared packages do not have it. The requests for them are answered (the files in `coqui/requests/` are gone); these stay in the package.

- `AddBox` (`lib/src/add_box.dart`): the text field of "Add a word or a goal", a Material `TextField` set to the look of v=39's `input` (48 px, white, a `--line2` ring through `CoquiLayout.border`, 12 px corners, the browser's grey placeholder). coqui_ui has no text field; `coquiTheme()` gives the standard density.
- `BalancedKeyLine` and `BalancedText` (`lib/src/balanced_key_line.dart`): the grey key line under the first place title, with `text-wrap: balance` (`KeyLine` of coqui_ui does not balance its lines).
- The full sample course (`tool/make_dev_data.mjs`, `tool/dev_data/`): the whole of `historia/` behind `FakeCourseCatalog(fetch:)` and the seeds of `coqui/ref/pantallas/seeds/`, so that the dev entry shows every reference state. coqui_testing's sample course holds three stories.
- `DevPictures` and `DevClips` (`tool/dev_services.dart`): grey pictures with the real source's geometry and a clip player whose clips play for their own length, for the dev entry and the screenshots. `GateClips` (`test/support.dart`) is the player of the tests: its clips end when the test says.

The word sheet is not one of them: it opens with `showCoquiSheet`. `showCoquiSheet` calls its builder once and `CoquiSheet.titleVisible` is a plain value, so `WordSheet` (`word_sheet.dart`) marks the builder's element to build again when the title shows or hides (the title shows once the big word has scrolled away).

## The dev entry and the screenshots

```
cd coqui/packages/features/feature_words
flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?state=curso"   # vacio, uno, curso, todo, nivel
flutter build web -t tool/dev_main.dart --no-web-resources-cdn
node tool/shots.mjs [--out <dir>] [--no-build] [--device android|iphone] [--only 030,038]
node tool/make_dev_data.mjs && dart format tool    # after a change in coqui/ref/pantallas/seeds/ or historia/
```

- `?state=` is the stored progress it starts in: a seed of `coqui/ref/pantallas/seeds/`, loaded through the fake store's `import`. The clock stands at 19 Nov 2026, 12:00 in Puerto Rico, as in the old pictures.
- The fakes are set up in `tool/dev_services.dart`: the whole course of `historia/` behind `FakeCourseCatalog(fetch:)`, a clip that plays for its length, grey pictures with the real source's geometry (see "Stand-ins").
- `tool/shots.mjs` takes each picture of `coqui/ref/pantallas/` that order 21 uses on both phones, drives the page through its accessibility tree, and writes the pictures, a side by side with each reference, and `pairs.json`.

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

The dev entry lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`). Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

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
