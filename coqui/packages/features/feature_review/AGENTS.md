# feature_review

Repaso (¿Cuál?) and the level check.

- Kind: Flutter package.
- Replaces: cual.js, cual.html, nivel.js, nivel.html.
- One package is one lane. Branch: `lane/feature_review/<order number>`.
- Work orders: 23.
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

- `lib/feature_review.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- It holds one thing: its module, `ReviewModule`, a `FeatureModule` (boundary rule 4). Since order 23 it answers `ReviewRoute` (Repaso) and `LevelCheckRoute` (the level check), full-screen lessons, and has no tab. `ReviewRoute.practice` is not read: like cual.js, the screen decides from the store whether anything is due.
- The dev entry is `tool/dev_main.dart`: `flutter run -d chrome -t tool/dev_main.dart`; `web/` is there for it.

## What is where (order 23)

- `lib/src/logic/`: the lessons as plain Dart taking `Rng`, `Clock`, the catalog, the store, a clip player and the host's `wait`: `review_session.dart` (cual.js), `level_check.dart` (nivel.js), `lesson_base.dart` (the voice, captions and sounds of juego.js), `js_sort.dart` (V8's `Array.prototype.sort`, so that `list.sort(() => Math.random() - .5)` draws as the old page does).
- `lib/src/ui/`: the screens from coqui_ui (`review_screen.dart`, `level_check_screen.dart`), the page's layout arithmetic (`block_layout.dart`), local stand-ins that stay local (`lesson_parts.dart`: the lesson's text screen, the choice that takes the touch when the finger goes down; the Repaso end list): the answer to order 23's requests. The level check's cells are `PictureRef.ofLevel` pictures, asked for 96 x 106 (`test/level_picture_ref_test.dart` checks that ref against the crop this package made itself, over every item of `historia/datos/nivel.json`).
- `test/`: the differential tests (`*_differential_test.dart`, `js_sort_test.dart`, `layout_test.dart`) against the old code run in Node, and the widget tests (`review_screen_test.dart`, `review_end_test.dart`, `level_screen_test.dart`, `strings_test.dart`), one for each check of `repaso_check.py`, `cual_check.py` and `nivel_check.py`.
- `tool/diff/`: the Node scripts that run cual.js and nivel.js (`old_harness.mjs`, `runs.mjs`) and write `test/fixtures/` (`make_fixture.mjs`, `sort_probe.mjs`). Re-run: `node tool/diff/make_fixture.mjs`; the files come out byte for byte the same.
- `tool/dev_main.dart`, `dev_states.dart`, `dev_data.g.dart` (made by `node tool/embed_dev_data.mjs` from `historia/` and `ref/pantallas/seeds/`), `support/`: the dev entry. Its address parameters are in the file's header (`?screen=review|level&seed=curso&state=tu-turno`).
- `tool/shots.mjs` (screenshots of every reference state on both phones, side by side with the old pictures, `pairs.json`) and `tool/compare.mjs` (the same numbers measured from both pictures).

## Repaso as games (order 27)

Page 15 (docs/proyecto/15-repaso-juegos.md) is the design; where it and page 10 differ about Repaso, page 15 wins.

- `ReviewModule({imageUrl, imageProvider})` answers `ReviewRoute` with `RepasoScreen` (the games) when the course is a
  `RepasoCatalog` whose `repaso` is not null (`datos/repaso.json` was read); otherwise with today's `ReviewScreen`
  (cual.js), unchanged. `imageUrl` / `imageProvider` turn a book page's `img` into its picture, as `LibraryModule`'s do;
  the shell passes the site's address.
- `lib/src/logic/repaso_plan.dart`: the words, the scored item of each word (¿Cuál? / ¿Qué oyes? in turn by the Ear
  count `n`; ¿Cuál? after a miss), the sentence in turn by that count, the wrong tiles, the play items (Arma la frase,
  Parejas, ¿Dónde?, Dilo in turn after every third scored item). Only sentences of stories he has finished (played to the
  end; a story the level check only presumed does not count; a picture story heard to its end does).
- `lib/src/logic/repaso_session.dart`: the session on the host's wait (silence for the scored games, the answer shown,
  a miss back once three items later, at most five), what is written (Ear as today's Repaso, Mouth for Dilo heard right,
  the minutes), the end. `repaso_words.dart`: folding and finding a word in a sentence.
- The feature's own storage space `review` keeps two things: the last sentence each word was asked in (`repaso.last`, so
  two reviews running never repeat one) and where the play kinds' turn stands (`repaso.kind`).
- `lib/src/ui/repaso_screen.dart` (the start, each game, the end, Dilo's mic), `book_image.dart` (a book picture at a
  whole scale; a local copy of Biblioteca's).
- The readers' fixes (page 15's lines for them are in the page; the tests of each are named for its letter): the one rule
  for which words Repaso can serve is `RepasoServing` in coqui_contracts (the plan delegates to it; Palabras and the map
  count by it). The screen has one fixed layout from the moment an item is asked: (1) the instruction line, and the
  streak chip's place (reserved); (2) the round speaker (`RoundSpeaker`, not in Parejas, whose sounds are its tiles),
  the same size and place in every game that plays a sentence; (3) the game's own area; (4) the reveal, a place of its
  own (key `reveal`) that holds the sentence and its story picture after the answer; (5) Next's place (key `next-slot`),
  empty until Next shows (Dilo's "Can't speak now" stands in it until then). Every item ends with Next (it shows at once
  after a right answer, and after a wrong one when the right thing has been touched; the praise plays meanwhile and Next
  cuts it short); no text of the sentence shows before the answer (the session's captions are off). A wrong touch has
  the red-orange ring and the X badge; the right one then has the pointing hand over its middle and no ring until it is
  touched. A missed item returns as the same sentence and game with its pictures or tiles in another order
  (`CualItem.rearranged`, `HearItem.rearranged`). The bar has one dash for each planned item (a missed one red-orange
  until its return is answered, `barMissed`). Speakers on ¿Qué oyes? tiles only when every tile has a clip of its word
  alone (`HearItem.speakers`). ¿Dónde? stacks its pictures at the largest whole scale that fits and has two when three
  could not be 150 px wide each (`ui/repaso_layout.dart`, `WhereItem.picturesFor`, `RepasoSession.wherePictures`).
  Arma la frase: a row of empty slots, a placed tile goes back to the bank when touched (`RepasoSession.slots`); Parejas:
  a wrong pair flashes about a second, a matched pair has its number; Dilo: "Listening…", "Heard: …", "Try again".
- Tests: `repaso_plan_test.dart` (on the real data file: tiles over every sentence, rotation, which game, the seeded
  learner's session), `repaso_session_test.dart` (each game's rules with no screen, and the session's side of each fix),
  `repaso_screen_test.dart` (both phones, text size, reduced motion), `repaso_fixes_test.dart` (the fixes on screen: the
  pictures of consecutive ¿Cuál? items, the layout that does not move, the hand, Arma la frase, Parejas, Dilo, ¿Dónde?,
  the end screen), `repaso_layout_test.dart`; `test/support/repaso_screen_rig.dart` is the screen rig.
  `tool/repaso_counts_test.dart` prints how many words get each game at stories 3, 11, 22, 32. The pictures for readers:
  `coqui/app/tool/repaso_shots_test.dart`; it fails the run on an `ErrorWidget` or a picture that failed to draw at any
  picture, on a game whose layout moved after it was asked, and on an end screen that does not list every scored word once.
- Pictures that change place: the pictures of a ¿Cuál? item are keyed to their item. `coqui_scenes`' `ScenePicture` is a
  `SingleTickerProviderStateMixin` that starts a second ticker when it is handed another picture in place, which Flutter
  refuses; until that is changed in `coqui_scenes` (not this package's to change), never hand a scene picture another ref in place.

## Run and test it alone

```
cd coqui/packages/features/feature_review
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A dev entry that starts the feature on the fakes comes with order 02. It lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_review`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 10-leer-y-repaso, "Rules that bind this (his)":

- No English in learning content: no translation, no gloss. English only in menus, labels, the welcome, the stuck line.
- No self-report: no swipe-to-rate, no "I knew it". The app finds out by asking.
- Reading from day 1, not tracked until A2: reading writes no word record.
- Original pixel art; pictures must read with zero words known.
- Only the map is game-styled. Reading and review are calm screens (UI plan).
- Spanish text is shown exactly as recorded.

From 10-leer-y-repaso, "Repaso (¿Cuál?): the session":

- Up to 10 words a session (due first, most overdue first). If more are due, the rest wait for the next session; no backlog count is shown beyond "N words today".
- Each item as today: the sentence plays, two pictures, only one fits; a touch before the sentence ends does not count.
- No touch 6 s after the sentence ends: the sentence plays again; 6 s more: the right picture gets the green ring and the sign and he touches it (counts as a miss).
- A miss comes back once in the same session, three items later (or at the end if fewer are left), with the pictures in a new random order; that second ask is not scored (intro), as the plan says ("the word comes back later in the session").
- End screen: the words of the session with a picture each, grouped "Moving up" (right) and "Coming back soon" (missed), and Back to Palabras. No score number.
- The scheduler (palabras.js) is unchanged except: the due check uses the palabras clock, not Date.now().

From 10-leer-y-repaso, "Repaso after the fresh read (Nov 19)":

- Start screen: one English line under the title: "Listen, then touch the picture that fits."
- While the sentence plays, both pictures are dimmed (not touchable look); when it ends they come to full brightness: that is "your turn".
- Right: the green ring plus a small check badge on the picture, and the other picture dims. Wrong: as today.
- The progress bar has one segment per word of the session; a second ask adds no segment.
- End screen: one summary line ("8 moving up · 2 coming back soon"; practice: "6 right · 2 missed"); a grey line under each group heading ("You'll see these less often" / "You'll see these again soon"; practice: none); no sound button and no X on it (the green button is the way out); grid centred, a long word wraps inside its cell, a fade at both ends of the scrolling list.
- Not taken: English glosses (his rule), a reward animation (the reports: extrinsic rewards undermine; the summary line is enough).

From 09-ui-plan, "Where the build differs from the doc, and why (told to him in one line each)":

- No swipe-to-rate flashcards: that is the learner telling the app he knows a word. Review stays the picture check (¿Cuál?), where the app finds out. His rule against self-report buttons.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.

From 09-ui-plan, "Reading and review (Nov 19, v=39)":

- Repaso (¿Cuál?): up to 10 words a session. Both pictures are dim while the sentence plays. No touch for 6 s: the sentence plays again; 6 s more: the right picture is shown and it counts as a miss. A miss comes back once, three items later, unscored. The end screen: a summary line, the words with their pictures under "Moving up" and "Coming back soon" ("Right" and "Missed" after a practice), and a green "Back to Palabras". No score number.

From 03-requirements, "What the app is":

- "For a true beginner experience every word is new. So it goes into the system that way, you can ask more questions as the person learns more words… Once the word is consistently used, its goes into good and comes less frequently." "And you can just test someone and understand what level they are anyway."
