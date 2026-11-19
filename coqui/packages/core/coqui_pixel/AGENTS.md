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

- Since order 12 it holds the scene kit, the signs, the camera and the frame recipe:
  - `kit.dart` (kit.js): `mkAve`, `mkAbuelaS`, `mkPersona`, `mkBebe`, `mkPerro`, `mkCesta`, `mano`, `tarjeta`, `FAM`, `PIEL`, `PELO`, `PX`, `Who` (the `who` object of `mkPersona`, a class; `copyWith` is `Object.assign`), and `Escena`, the base class of a scene (`box`, `hit`, `handAt`, the shared acts `ir`, `burbuja`, `calla`, `pose`, `fin`, the bird: `avePos`, `drawAve`, `aveA`, `aveVa`, `aveHit`). A scene's own acts are `ownActs` (kit.js's `d.acts`); `acts` is that map with the shared acts added where the scene has none of the name. A flag the old code tests for truth is a `bool`.
  - `signs.dart` (juego.js, "signs and marks"): `hand`, `heart`, `star`, `spot`, `bang`, `frogBox`, `HAND`, `HEART`, `BUB`, `newBUBL()`, and `Signs`, which reads the game's state through a `SceneHost` and a `Scene` (`twinkle`, `bub`, `frog`, `respBox`, `bx`, `respDraw`, `drawSigns`: everything juego.js's `draw` puts over the scene, in its order; `handPoint`). `glow` (a field of `W` in juego.js) is never drawn in the old code, so it is not here. `Signs.frog(g, q, a, {shadow = true})`: with `shadow: false` the frog is drawn exactly as before except the old flat shadow (juego.js line 48, the call `shadow(g,b.x+2,q.y+25,b.w-5)`), for a scene whose engine casts the frog's shadow; it draws the same pixels as the shadowless copy in `coqui_scenes`' still host. The default is the old picture, byte for byte.
  - `camera.dart` (juego.js: `cam`, `camGo`, `at`; page 12 section 5 as corrected Nov 19): a view is a centre and a zoom of 1 or 2 (`viewAt`): `cam` stays `[x, y, w, h]`, 196 × 216 at zoom 1 and 98 × 108 at zoom 2, so `zoomOf(cam)` is the old `DW / cam[2]`. `pictureToDisplay` and `displayToPicture` map a point through the view. `CamSlide` is `camGo`: a slide in whole pixels between views of one zoom, a cut between two zooms, the same number of frames as the old one. `reviewRegion` and `reviewCrop` are the review and level-check picture (196 × 104, zoom 1 or 2).
  - `frame.dart`: `drawFrame`, the frame recipe of section 5 as one function that holds no state; `clipToWorld` (the projection of a list of world points as the clip: the sheet's `clips` are world polygons), and on top of it `facePoints`, `faceCorners`, `clipTo` (a face `'x'` or `'y'` of a thing's world box, as the building helpers name them).
  - `baked_set.dart`: `BakedSet`, one baked state of a set with everything a bake leaves behind (the baked picture and depth, `ground`, `groundZ`, `kinds`, `staticShadow`, the tufts and leaves). `BakedSet.capture(engine)` right after a bake; `drawFrame` restores it first, so one engine can serve every state.
  - `sheet.dart`: `Sheet`, a scene's `<id>-sheet.json` parsed from its text (the caller reads the file) into typed parts: `things`, `spots`, `lugar`, `frames`, `points`, `views`, the `remap` table, `pictures`, `level`, `clips`, `front`, `shadows`, `setKey` (the table, not the function from W), `code`. A field it does not know is kept (`raw`, `unknown`) and ignored. What needs the engine takes it: `boxOf`, `hitBoxOf`, `screenOf`, `frogAt`, `abuelaAt`, `lugarOf`, `viewOf`, `pictureRegion`, `pictureCrop`, `clipPolygon`. `remap(kind, old)` (and `remapPoint`, `remapCam`, `remapCrop`, `remapX`) throws `SheetError` naming a position the table does not have.
  - `js.dart`: `jsNum` (a number as JavaScript joins it to a string, for sprite-cache keys) and `jsTruthy`.
  - `Ctx.setLineDash`, and `SceneHost.lib` (the game's one `SpriteLib`, which the old code reached as the global `spr`).

- Since order 12b it also holds `hexColour` (`colour.dart`): `"#RRGGBB"` as the int `0xFFBBGGRR`, for a colour that is made once. `hexColours` (a list of them) stays under `src/`.

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

Order 12's tests replay the 469 sprites of `coqui/ref/sprites/kit/` (the files on the vm, a fixture in chrome), and compare the rest with the OLD code, run by scripts under `tool/`:

```
dart run tool/make_sprite_fixtures.dart [--check]   # (also) test/support/fixtures/ref_kit.dart, from coqui/ref/sprites/kit/
node tool/make_kit_ref.mjs [--check]     # test/support/fixtures/ref_kit_logic.dart: kit.js's hit, box, handAt and acts on a made-up scene, juego.js's 18 SFX and camGo, pp-engine.js's project (clipTo), all run in node
node tool/make_signs_ref.mjs [--check]   # test/support/fixtures/ref_signs.dart: the signs of juego.js and the bird of kit.js drawn by headless Chrome (132 cases)
node tool/make_dash_ref.mjs [--check]    # test/support/fixtures/ref_dash.dart: setLineDash, 12 cases drawn by headless Chrome
```

```
dart run tool/make_sheet_fixture.dart [--check]   # test/support/fixtures/frente_sheet.dart: docs/proyecto/pixel/frente-sheet.json as a string, for chrome
```

`test/pp_frente_test.dart` rebuilds the Nov 14 one-state El frente (an old frente-set.html) as a test of `PpBuild`'s helpers at S = 26. That picture is no longer in `coqui/ref/pp/` (order 07 replaced it with El frente's 25 states): its bytes are `test/support/fixtures/frente_nov14.dart`, read on every platform, and nothing makes that file again. The 25 states are order 14's.

The made-up scene of `make_kit_ref.mjs` is written again in `test/support/kit_scene.dart`: keep the two the same. The Node scripts need Node 22 and the pre-installed Node Playwright (`require('playwright')`). A fixture is formatted the way `dart format` leaves it, so the format check passes.

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
