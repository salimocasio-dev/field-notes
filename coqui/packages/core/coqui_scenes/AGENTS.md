# coqui_scenes

One folder per scene (its set, its scene), and the pictures other features ask for.

- Kind: Flutter package.
- Replaces: historia/escenas/*.js, pixel/frente-set.html, `miniatura` and `panelW`.
- One package is one lane. Branch: `lane/coqui_scenes/<order number>`.
- Work orders: 14, then 30b to 39b, one scene at a time.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: pixel, contracts, ui.
- Coquí packages: `coqui_contracts`, `coqui_pixel`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_scenes.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the public file holds a library comment and nothing else. `lib/src/registry.dart` holds `sceneRegistry`: the eleven scene ids in order, each mapped to a stub that throws `UnimplementedError('not converted yet')`. There is one stub file per scene under `lib/src/<id>/`. The public file does not export the registry yet.
- Later it holds the `PictureSource` of page 12, section 3, built on the scenes.

## Run and test it alone

```
cd coqui/packages/core/coqui_scenes
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

From 03-requirements, "The app structure":

- Art bar: instagram.com/science_in_8bit. Pictures must be clear enough that someone who understands zero words understands from the picture.

From 09-ui-plan, "What the doc says, in short":

- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.

From 10-leer-y-repaso, "Rules that bind this (his)":

- Original pixel art; pictures must read with zero words known.

From 03-requirements, "How a story must sound and play (Nov 13, his verdict on the first version of story 1)":

- So: the voice talks TO the learner in whole, natural sentences and asks real questions. Not labels. Praise is short ("¡Muy bien!"), then on. The sign for what to touch is BIG. A right touch never reads as wrong. The story moves; no repeating an ask to pad it.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.
