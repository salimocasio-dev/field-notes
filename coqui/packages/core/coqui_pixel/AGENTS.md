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
- Since order 02 it holds `Thing`, `Scene`, `SceneHost` and `Sfx` (page 12, section 4).
- Since order 10 it holds `PpEngine` and `PpBuild` (the port of pp-engine.js and of the palette and building helpers of mapa.js), and `toInt32` and `imul` (page 12, section 6).
- Since order 11 it holds the sprite library (the port of historia/engine.js) and the software canvas:
  - `Sprite` (`w`, `h`, `px`: `0xAABBGGRR`), `Buf`, `RP`, `OUT`, `BAY`, `bay`, `hs`, `fr`, every `mk*` (`mkCoqui`, `mkAbuela`, `mkDog`, `mkTree`, `mkPalm`, `mkBall`, `mkCup`, `mkBush`, `mkPot`), `sky`, `grass`, `face`, `pointer`, `sparks`, `talk`, `shadow`: top-level, with the old names and parameters.
  - `SpriteLib`: what engine.js keeps in globals that change, as fields (`SP` the sprite cache, `GL` and `GC` the glyph tables that scene files add to, the colour cache) and the functions that use them: `spr`, `rgb`, `coqui`, `glyph`, `bubble`, `bgCasa`, `bgParque`. One per game.
  - A colour is the int `0xFFBBGGRR` (`"#E6863A"` is `0xFF3A86E6`, `"rgba(0,0,0,0)"` is `0`). A flag the old code tests for truth (`open`, `wag`, `ok`, `hz`) is a `bool`; `mkCoqui`'s `blink` is `0` or `1`.
  - `Ctx`: page 12 section 4 (transform stack, 8-bit blending, nearest and bilinear `drawImage`, arc and ellipse fills and strokes by scanline with 4 x 4 samples, a clip stack of whole-pixel rectangles and one path mask, `snapshot`). `smoothing` is off by default (decided Nov 19): an unscaled, unrotated `drawImage` lands on `(x + 0.5).floor()`.

## Run and test it alone

```
cd coqui/packages/core/coqui_pixel
dart test -p vm
dart test -p chrome   # needs CHROME_EXECUTABLE, see the runbook
```

The parity tests compare the Dart engine with pictures the old code made (`coqui/ref/pp/`, and `test/support/fixtures/extra_ref.dart` for what the island and El frente do not reach). On the vm they read the reference files; in chrome they read a Dart fixture made from the same files:

```
dart run tool/make_fixtures.dart [--check]    # test/support/fixtures/ref_pp.dart, from coqui/ref/pp/ (remake it when the reference changes)
node tool/make_extra_ref.mjs [--check]        # test/support/fixtures/extra_ref.dart, from the old pp-engine.js and mapa.js
```

The map's island and El frente's set are built by test-only code under `test/support/`; the real ones are orders 13 and 14's.

Order 11's tests replay the sprites of `coqui/ref/sprites/engine/` (445, every pixel) and the 40 cases of the canvas sheet `coqui/ref/ctx/` (the cases' own calls, on a new `Ctx` each). Same way: the files on the vm, a Dart fixture in chrome.

```
dart run tool/make_sprite_fixtures.dart [--check]   # test/support/fixtures/ref_sprites.dart and ref_ctx.dart, from coqui/ref/sprites/engine/ and coqui/ref/ctx/
```

The Pixel Plays licence text is at the top of `lib/src/pp_engine.dart` and in `LICENSE-pixel-plays.txt`; `test/licence_test.dart` keeps the two the same.

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
