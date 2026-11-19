# coqui_pixel

The Pixel Plays engine, the set-building helpers, the sprite library, the software canvas, the scene kit. Pure Dart.

- Kind: pure Dart (no Flutter SDK).
- Replaces: docs/proyecto/pixel/pp-engine.js, the building helpers in mapa.js, historia/engine.js, escenas/kit.js, the signs and marks in juego.js.
- One package is one lane. Branch: `lane/coqui_pixel/<order number>`.
- Work orders: 10, 11 and 12, one after another.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts.
- Coquí packages: `coqui_contracts`.
- Third party: `collection` ^1.19.1.
- Dev only: `lints`, `test`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_pixel.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Since order 02 it holds `Thing`, `Scene`, `SceneHost` and `Sfx` (page 12, section 4), and `PpEngine`, `PpBuild`, `Sprite`, `Ctx` as shells that throw until orders 10 and 11 fill them in.

## Run and test it alone

```
cd coqui/packages/core/coqui_pixel
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

From 03-requirements, "The app structure":

- Art bar: instagram.com/science_in_8bit. Pictures must be clear enough that someone who understands zero words understands from the picture.

From 09-ui-plan, "What the doc says, in short":

- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.

From 10-leer-y-repaso, "Rules that bind this (his)":

- Original pixel art; pictures must read with zero words known.
