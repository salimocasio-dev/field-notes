# feature_library

Biblioteca and the book reader (Leer).

- Kind: Flutter package.
- Replaces: the Biblioteca tab and the book reader in app.html (since Nov 23, 2026: stories made for his level and texts he adds, read as text).
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
- It holds one thing: `LibraryModule()` (a `FeatureModule`, boundary rule 4). Id `library`; its tab is Biblioteca (`ReadingHome`); `screenFor(BookRoute)` is the text reader (`TextReader`). Since the Biblioteca rewrite (Nov 23, 2026) the module takes no image address: nothing it shows is a picture.
- What is in `lib/src/`: `reading_home.dart` (the tab: a story for his level or the next one, "Generate a story", "Add text", his shelf), `text_reader.dart` (the reader and `ReaderTexts`, its own English words), `reading.dart` (words and lines of a text, `ReadingStore`, `ReadingVocabulary`, the coverage rule), `story_generator.dart` (stories put together from the plots), `reading_audio.dart` (the recordings a word or a line may play), `reading_assets.dart`.
- The course shelf of order 22 (each story with Listen and Read) and the picture book reader are gone: the map replays the stories. `BookRoute(id)` of a course book still opens, as its lines in text, without pictures. A text that is not there says so in one line; its X goes back.

## How Biblioteca works

- A story is made on the phone, never over the network: `assets/story_plots.json` holds reviewed plots whose beats each have alternatives; every combination is a draft. A draft is offered only when at least 98% of its word tokens are known (ear stage 4, the threshold Yo uses), with at most 3 new words, each said at least twice. Words due for review come first; practice words he asks for must be in it. A story already on his shelf is not offered again. The plots are few (4 plots, 40 drafts): some learners will have no match, and the tab says so.
- He can paste a text with a title. Generated and added texts are kept in the feature's own storage space, `Services.storage('biblioteca')` (`texts`, and `place:<id>` for the page he is on and the words met). The text size is `Services.storage('leer')`, key `tam`, as before.
- The reader shows each word's ear stage by its colour. Tapping a word plays that word's own recording only (never a sentence in its place); a line with a recording has a speaker. A recording heard to its end counts as hearing those words (`progress.heard`); a failed or muted play does not. A text with no recording is read without sound.
- Reading to the end (`progress.markRead`) and the count of words met are kept only with a verified level of A2 or more in `ProgressStore.levelResult['cefr']`. The level check does not write that field yet, so for now nobody's reading is marked finished; the page he is on is kept for everyone.
- `assets/story_plots.json` is content kept in this package until it has a place in the course data (boundary rule 8).

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

The dev entry lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_library`. Its address parameters (`seed`, `screen`, `book`, `speed`, `big`, `tab`, `content=real`) are listed at its head; on `seed=curso` every word of the plots is known, so a story can be made, and `seed=vacio` is a learner with no ear records. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins, except for the shelf and the book: the sections on them below describe Biblioteca before its rewrite of Nov 23, 2026, which he chose; "How Biblioteca works" above is what is built.

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
