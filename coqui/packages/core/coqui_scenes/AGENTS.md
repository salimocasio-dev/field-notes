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
- It exports `loadScene` (a scene made from its sheet, read from this package's assets), `convertedScenes`,
  `sceneRegistry`, `SetScene` (a converted scene: its sheet, its engine, its set built from a key, its characters'
  shadows), `SetBakes` (a scene's baked states, cached by set key), `StillFrame` and `StillHost` (one frame of a scene on
  a host whose waits return at once and whose sound is silent), and `ScenePictures`, the `PictureSource` of page 12,
  section 3.
- `lib/src/registry.dart` holds `sceneRegistry`: the eleven scene ids in order. El frente's factory makes the real
  scene (its sheet read first: `loadScene`); the other ten are stubs that throw `UnimplementedError('not converted yet')`.

## How a converted scene is laid out (order 14, El frente; the pattern for orders 30b to 39b)

- `lib/src/set_kit.dart`: the port of `docs/proyecto/pixel/set-kit.js`, shared by every set. A helper a new set
  reference adds to set-kit.js is ported here, same name and parameters.
- `lib/src/<id>/<id>_set.dart`: the port of `<id>-set.html`, call for call: `<id>Engine()` (the page's `PP_SCENE`), the
  state class (`fromQuery`, `fromKey`, `key` as the sheet's `setKey` table writes it) and the builder (`buildSet`).
- `lib/src/<id>/<id>_places.dart`: every screen place the scene uses, read from the sheet once (spots, points, frame
  offsets, boxes, clips, views), projected by the engine. No number of the sheet is typed in Dart.
- `lib/src/<id>/<id>.dart`: the old scene file line for line, a `SetScene`: minus its background function and the
  sheet's `dropped` lines; each old screen number replaced as the sheet's `code` says for its line; `setKey` from the
  sheet's table; `shadows` from the sheet's `shadows`; `remap` through `Sheet.remap*`.
- `assets/sheets/<id>-sheet.json`: a copy of the sheet, made by `dart run tool/make_sheets.dart` (`--check` fails when
  stale); add the id to `converted` there and to `convertedScenes`, and point the registry at the real factory.
- Tests: `set_test` (every state against `coqui/ref/pp/<id>/`), `sprites_test` (the scene's own sprites against
  `coqui/ref/sprites/escenas/<id>/`), `preview_test` (the frame against `<id>-preview.html`), `boxes_test`, `acts_test`,
  `pictures_test`. A browser test reads fixtures under `test/support/fixtures/`, each made by a tool with `--check`.

## Tools

```
dart run tool/make_sheets.dart [--check]          the sheets as assets (and their fixture for browser tests)
dart run tool/make_set_fixture.dart [--check]     the hashes of coqui/ref/pp/frente/ for the browser set test
dart run tool/make_sprite_fixture.dart [--check]  the hashes of coqui/ref/sprites/escenas/frente/
node tool/preview_shots.mjs --states DIR --out DIR [--fixture]   frente-preview.html's pictures (DIR from
                                                  node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR)
COQUI_OUT=DIR COQUI_CASES=FILE flutter test tool/make_pictures_test.dart   the pictures for fresh readers
flutter build web --release --no-web-resources-cdn -t tool/dev_main.dart; node tool/bake_time.mjs   bake times
```

Numbers for a report: `COQUI_REPORT_DIR=DIR flutter test` writes them on the vm; `--dart-define=COQUI_SHOW=true`
makes each comparison test end by failing on purpose with its numbers (vm and chrome).

## Run and test it alone

```
cd coqui/packages/core/coqui_scenes
flutter test
CHROME_EXECUTABLE=/opt/sdk/chrome-nosandbox.sh flutter test --platform chrome
flutter run -d chrome -t tool/dev_main.dart       # ?w=<W JSON>&view=<name>, ?page=pairs, ?page=bake
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
