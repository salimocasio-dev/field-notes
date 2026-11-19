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
- Today the file holds a library comment and nothing else.
- Later it holds one thing: its module, a `FeatureModule` (boundary rule 4).

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
