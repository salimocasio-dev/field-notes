# feature_library

Biblioteca and the book reader (Leer).

- Kind: Flutter package.
- Replaces: the Biblioteca tab and the book reader in app.html.
- One package is one lane. Branch: `lane/feature_library/<order number>`.
- Work orders: 22.
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

- `lib/feature_library.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- It holds one thing: `LibraryModule` (a `FeatureModule`, boundary rule 4). Id `library`; its tab is the Biblioteca shelf; `screenFor(BookRoute)` is the book reader. A book page's picture is a file served by the old site: `LibraryModule({imageUrl, imageProvider})` takes the address resolver (default `libros/<img>?v=39`, the old page's own) until `Services` carries a base (request `22-feature-library-needs-coqui-contracts-book-image-url`).
- What is in `lib/src/`: `shelf.dart` (app.html `biblioteca`), `shelf_row.dart` (`.bk` and `.btn` of the shelf), `reader.dart` (`leer` to `initLibro`), `book_line.dart` (`lineaEl`, `.lbl`, the underlines), `book_picture.dart` (`ajustaPic`), `word_marks.dart` (`pares`, `occs`), `word_popup.dart` (`tarjetaPal`), `strings.dart` (the words app.html writes itself), `images.dart`, `press.dart`.
- The reader keeps its text size in its own storage space: `Services.storage('leer')`, key `tam` (the old page's `coqui.leer.tam`). It writes no word record; `progress.markRead` at the last page.
- The shelf reads `course.places` when it is built and after each progress save: the shell loads the catalog first. It carries its own `#fadeTab` fade (16 px at the tab bar's edge, while there is more to scroll) and expects the shell to lay the tab out full screen with the tab bar over it, as `TabPage`'s foot padding does.

## The dev entry

`tool/dev_main.dart` runs the feature alone on the fakes, on the shelf with a tab bar under it; Read opens the reader. The address starts it in a reference state (`coqui/ref/pantallas/`):

```
flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?seed=curso&screen=book&book=la-lluvia&page=5&hold=2"
```

`seed` (vacio, curso, casi, todo: the progress of the reference states, embedded by `dart run tool/embed_seeds.dart` into `tool/dev_seeds.dart`), `screen` (shelf or book), `book`, `page` (from 1), `hold` (the n-th line of the page hangs, lit), `speed` (clips play this many times faster), `big=1`, `card=1`, `scroll=end`, `tab=0`, `content=real` (the real files of `historia/`, served by the screenshot script). The sample course has one book, La lluvia, whose own verdict is "does not read well"; the dev entry turns it on so the shelf shows Read.

```
node tool/shots.mjs --out <dir>      # builds it, serves it with the books' files, captures every reference state of order 22 on both phones
```

It writes `<dir>/<device>/<mode>/<state>.png`, `<dir>/pairs.json` (each picture with its reference picture) and `<dir>/side/` (each pair, the reference at the left). `--mode sample` is the sample course alone, `--mode real` the real files of `historia/` (read from the repository, nothing copied).

## Run and test it alone

```
cd coqui/packages/features/feature_library
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

The dev entry lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_library`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 10-leer-y-repaso, "Rules that bind this (his)":

- No English in learning content: no translation, no gloss. English only in menus, labels, the welcome, the stuck line.
- No self-report: no swipe-to-rate, no "I knew it". The app finds out by asking.
- Reading from day 1, not tracked until A2: reading writes no word record.
- Original pixel art; pictures must read with zero words known.
- Only the map is game-styled. Reading and review are calm screens (UI plan).
- Spanish text is shown exactly as recorded.

From 10-leer-y-repaso, "The shelf (Biblioteca tab)":

- Per place (h2 = place name), one row per story he has played: a small cover picture (its first page), the title, and two buttons: Listen (the story straight through, as "Otra vez" today) and Read (opens the book). A small check after a book has been read to its last page (completion only; no word record).
- The Escuchar picture stories and routines of a finished place appear the same way.
- Nothing he cannot open yet is listed; one grey line counts them (as today).

From 10-leer-y-repaso, "The book":

- Full screen, calm (the lesson frame: close X top left, a thin page-progress bar, text size button top right, tab bar hidden). Close returns to the shelf.
- One page at a time: the picture on top (whole-number scaled, the scene as it was at that moment of the story), up to three lines of text below, large type (20 px, 30 px line height; a text-size button toggles 20 / 24 px and is remembered).
- The speaker shows as it is in the text (the recording says "Abuela dice: …"); the coquí's lines carry a small "Coquí" label as today.
- Opening a page plays its lines in order; the line playing is lit (line level, not word level: Puerto Rican speech drops sounds the spelling keeps). Then it waits. He can tap any line to hear it again. Next / back: big arrow buttons at the bottom and a swipe; no auto-advance. The last page ends with "Otra vez" (read again) and "Biblioteca".
- Tapping a word that has a picture (the 128 words with a ¿Cuál? pair, matched on the normalised word, multi-word words as phrases): a small card pops over the page with that word's picture (its "sí" picture) and the word; every place the word occurs on the page is underlined for a moment; the card closes on any tap. Other words: the tap plays the line. No translation, ever.
- Audio loads per page (the page's clips and the next page's), not the whole story.

From 10-leer-y-repaso, "After the first fresh read (Nov 19)":

- Nothing is ever covered by the tab bar or the Mapa disc: lists, grid and sheets end clear of it.
- Book: the line playing is lit on every page; each line has a small speaker icon (tap to hear it again); words with a picture carry a faint dotted underline; a page count "3 / 9" beside the progress bar; the last page says "Fin" above its buttons, both buttons in the app's green style (no blue), "Otra vez" with a replay icon.
- Shelf: the Read button has a book icon; a read book shows "Read ✓" in place of a bare check.

From 10-leer-y-repaso, "After the beginner review of the books (Nov 19)":

- Then the same kind of fresh beginner review again, on all books. A book whose verdict is not "reads well" gets no Read button (Listen only) until its own overrides fix it; the shelf shows only books that read well. Overrides are listed in the tool, per story, never by hand in the JSON.

From 10-leer-y-repaso, "What goes in a book (the text)":

- Routines (Haz esto) get no book: all their lines are commands. On the shelf they have Listen only.

From 10-leer-y-repaso, "Not now (said so it is not invented)":

- Word-level karaoke or word audio (no word timing exists).
- Themes (dark/sepia), reading tracking, new recordings, new review item types beyond ¿Cuál?, pictures for the 28 words without a pair.

From 09-ui-plan, "Where the build differs from the doc, and why (told to him in one line each)":

- No English translation tooltip in reading: his rule that English is only for menus, the welcome and the stuck line.

From 09-ui-plan, "Reading and review (Nov 19, v=39)":

- Biblioteca: per place, one row for each story he has played: a cover (the book's first page), the title, Listen and Read. "Read ✓" once the book was read to its last page. Read shows only for a book that read well (22 of 43 now); the other 21 show Listen only until their own fixes. Routines (Haz esto) show Listen only.
- The book: full screen on calm dark grey, the tab bar hidden. One page at a time: the picture (whole-number scaled), up to three lines, 20 px type (24 px on the text-size button). The line playing is lit; each line has a speaker icon and plays again on a tap. Words with a picture have a dotted underline; a tap shows the word's picture. Page count "3 / 9". Next and back by arrows or swipe, no auto-advance. The last page says "Fin" with "Otra vez" and "Biblioteca", both green.

From 03-requirements, "The app structure":

- Reading on day 1: "Yes it includes everything. What changes its what's tracked. Reading gets no tracking until A2."
