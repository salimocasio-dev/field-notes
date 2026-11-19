# coqui_ui

Colours, type, shared widgets, the lesson frame, the widget that shows a pixel picture.

- Kind: Flutter package.
- Replaces: the CSS in app.html, notas/ui-decisiones-1 to 3, page 09.
- One package is one lane. Branch: `lane/coqui_ui/<order number>`.
- Work orders: 20.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, Flutter.
  The plan's table says "Flutter only". The orchestrator changed it on Nov 19, 2026: page 12, section 3 needs the contracts, and contracts depends on nothing.
- Coquí packages: `coqui_contracts`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_ui.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the public file holds a library comment and nothing else. `fonts/` holds Pixelify Sans, weights 400 and 700, as `.ttf` (converted from `historia/fuentes/`), with its licence `LICENSE-pixelify-sans.txt` beside them. The pubspec declares the family `Pixelify Sans`. Use it only where page 09 allows: signs on the map, never learning content.
- Since order 02 it holds `PictureRef`, `PictureSource`, `Services`, `FeatureTab`, `FeatureModule` (page 12, section 3). Later it holds `PixelView` and the shared look (tokens, buttons, bottom sheet, tab bar, lesson frame, meters, word card).

## Run and test it alone

```
cd coqui/packages/core/coqui_ui
flutter test
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

From 09-ui-plan, "What the doc says, in short":

- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.
- Thumb zone: primary actions and the mic in the bottom third. Targets 48 px or more, 16 to 24 px apart. 8-point grid. Type: H1 24 semibold, H2 16 to 18, body 14 to 16, labels 12.
- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Each tab keeps its state (scroll, place in a deck).
- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- One system: green #17803F for anything that starts or continues learning, blue #3B5BDB for other primary actions; one green 48 px play disc; one outline secondary button; 48 px targets 16 px apart; 8-point grid; H1 24, H2 18, body 16, labels 12.
- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.

From 10-leer-y-repaso, "Rules that bind this (his)":

- Only the map is game-styled. Reading and review are calm screens (UI plan).

From 03-requirements, "Lessons":

- English only so a stuck learner can navigate; never a mostly-English lesson.

From 03-requirements, "His instructions to the build chat (Nov 13)":

- "Why are the captions English. Everything should be in spanish." (The code was all Spanish; most likely his phone translated the page. Pages are now marked do-not-translate.) Then: "It's good. Continue". So: nothing on screen in a lesson may turn into English, by any route.
