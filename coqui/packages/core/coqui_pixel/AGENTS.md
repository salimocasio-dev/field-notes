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

- Since order 30b (El balcón), only as far as that scene needs:
  - `Sheet` reads what El balcón's sheet writes that El frente's does not: no `frames` (empty); `front` as `parts`, each drawn again at an old line (`frontParts`, `SheetFrontPart`: name, `line`, `replaces`; `frontHow`, `frontPlane`: the depth test in words; `front` is then the parts' names); top-level `old`/`new` numbers (`numbers`, `numberOf`: `MESA_Y`, `behind`; no longer in `unknown`); a lugar's `q` for `frog` and its `old`; abuela's spots with `ab` (`SheetAnchor.ab`; `abuelaAt` takes them); the remap's `pictures`, `level`, `ab` and `crops`; baked states with no `ref` (`SheetBaked.ref` is null) and a `reached`. El frente's sheet reads as before.
  - `frame.dart`: `SetOverSprites`, a scene whose sprite layer draws parts of the set again over what it has drawn (El balcón's furniture, the sheet's `front.parts`). `drawFrame` calls its `setFramed(engine, baked, W)` after step 3, before `scene.draw`: the engine's `pix` is then the set as the frame shows it, `baked.zb` the set's own depth. Any other scene is drawn as before.
  - `test/balcon_sheet_test.dart`: the reader against El balcón's real sheet (the file on the vm, `test/support/fixtures/balcon_sheet.dart` in chrome).
- Since order 31b (La sala), only as far as that scene needs:
  - `Sheet` reads what La sala's sheet writes that the earlier ones do not: spots and views with no `screen` (their screen is
    the projection of their world point by the sheet's own scale and origin) and a spot's `new` (`SheetAnchor.now`: the place
    the old file writes, today); points given on the screen only (`screenPoints`, `SheetScreenPoint`: a point `xy`, a
    rectangle `rect` or a list `points`, a photo frame's `angle` and `nail`; `points` keeps those with a world point); the
    remap's floor points (`RemapTo.floor`, `SheetRemap.now`); a shadow radius by kind (`SheetShadow.radii`; `radius` throws
    for it); a front part's `sortY` and `boxes`; a set parameter whose values are words (`SetKeyParam.valuesWhat`); and the
    new parts `moves` (`SheetMove`), `smoothing` (`SheetSmoothingPlace`, `smoothingWhat`, `notSmoothing`), `bubbles.rects`
    (`bubbleRects`) and `talk` (`SheetTalk`: places, heads, and `board(name, field)` for the corner cards the sheet gives in
    words). El frente's and El balcón's sheets read as before.
  - `test/sala_sheet_test.dart`: the reader against La sala's real sheet (the file on the vm, the fixture in chrome).
- Since order 32b (El patio), only as far as that scene needs:
  - `Sheet` reads what El patio's sheet writes that the earlier ones do not: `behind` (`SheetBehind`: what the sprite layer draws
    behind the set, in words, and its items; El balcón's `behind` stays a number), `flowerLeaves` (`SheetFlowerLeaves`: the
    palette as colours, the stages `open` and `bud` with their rows and head, the lines that get them and those that do not),
    `hops` and `hopsAll` (`SheetHop`: two places of the frog, the old and today's count and distance; El balcón's and La sala's
    `hops` too, no longer in `unknown`), a point given by its x and its rows (`points.sol`: `SheetScreenPoint.x`, `heights`),
    `moves` with no places, with the values of W they change (`SheetMove.values`), a person's sort row (`z`) and where the
    answer cards stand (`respEn`), a thing's hand point given as a point (`SheetThing.hand`), remap entries that moved
    (`SheetRemap.moved`), that stay a screen point (`RemapTo.screen`), that are no place (`to.none` true) or that name another
    scene's picture (`cropsElsewhere`), and corner cards of two parts with terms `p + q max(m, f)` (`SheetTalk.boardsOf`).
    El frente's, El balcón's and La sala's sheets read as before.
  - `BakedSet` keeps the blades' colours of its bake (`tuftLit`, `tuftDark`) and puts them back: a set whose blades take the
    light of its hour (El patio) sets them in its bake. For the earlier sets they are the engine's own, unchanged.
  - `test/patio_sheet_test.dart`: the reader against El patio's real sheet (the file on the vm, the fixture in chrome).
- Since order 33b (El camino), only as far as that scene needs:
  - `Sheet` reads what El camino's sheet writes that the earlier ones do not: a thing's `hintBox` (`SheetThing.hintBox`)
    and its screen box as corners (`screen: [x0, y0, x1, y1]`, `SheetThing.screenRect`); a point with no `old` (the arch:
    `SheetAnchor.old` empty); a screen point's depth `v` and radius (`SheetScreenPoint.v`, `radius`: the cat on the bench,
    the sun); a list of points of three numbers (the clouds, x, y, size); remap entries of kind `numbers` (three counts,
    no place); front parts with no line, placed by their `insert` words (`SheetFrontPart.line` null, `insert`); `sevan`
    (`SheetSevan`: each one's delay in ticks and two points). El frente's, El balcón's, La sala's and El patio's sheets read
    as before.
  - `Thing.hintBox`: where a thing's hint frame and twinkle are drawn when not round its box (a box that runs off the
    picture); `Signs.drawSigns` draws the twinkle round `hintBoxOf(k) ?? bx(k)` and the frame round
    `respBox(k) ?? hintBoxOf(k) ?? bx(k)` (camino-preview.html `hb`). A thing with none, every earlier scene's, is drawn
    as before; touches answer in the box either way.
  - `test/camino_sheet_test.dart`: the reader against El camino's real sheet (the file on the vm, the fixture in chrome).
- Since order 34b (El campo), only as far as that scene needs:
  - `Sheet` reads what El campo's sheet writes that the earlier ones do not: the dropped lines as pieces of source
    (`droppedCode`: line, src, to; `dropped` holds their `why`); a point whose `world` is one number, a line on the ground
    (`points.orilla_linea`: `SheetScreenPoint.line`, its ends in `points`); a screen point's `radii` and `hollow` (the crown,
    the fork); `helps` (`SheetHelps`, `SheetRing`: the ripple ring's inner bound, its colour, a ball's and Canelo's ellipses,
    and the two lines it adds); a shadow's `tree` (`SheetShadow.tree`: where a ball in the crown casts none); `front.waterDepth`
    and `front.tags` (`frontWaterDepth`, `frontTags`); `talk.board` as a rectangle (`SheetTalk.boardRect`, its words in
    `boardWhat`). The earlier sheets read as before.
  - The glints on a set's water, a per-frame step: `Glint`, `drawGlints(e, glints, t, refZ, color)` (set-kit.js's, in
    `pp_engine.dart`), `PpEngine.glints` and `glintColour` (a bake leaves them, as the tufts and the leaves), kept and restored
    by `BakedSet`; `drawFrame` draws them after `drawTufts` at the same wind time when there are any. A set with no water
    leaves none: every earlier scene's frame is as before.
  - `test/campo_sheet_test.dart`: the reader against El campo's real sheet (the file on the vm, the fixture in chrome).
- Since order 35b (El lago), only as far as that scene needs:
  - `Sheet` reads what El lago's sheet writes that the earlier ones do not: a thing whose `world` is null (the water,
    `things.agua`: no box of its own in the world); a point whose `world` is not one point (the dock, a box of six numbers;
    the mooring posts, a list of points) as a screen point, its numbers in `raw`; the ripple rings by kind
    (`SheetRing.kinds`, `kind(name)`: El lago's `pato`, `bote`, `pan`, El campo's `ball` and `dog`, still read by
    `ring.ball` and `ring.dog`) and a patch of paler water (`SheetRing.patches`, `patch(name)`, `SheetPatch`: El lago's fish,
    its centre, radii, soft edge and two colours); a move that takes another thing with it (`SheetMove.shift`: who, while
    which field is set, by how much). The earlier sheets read as before.
  - `test/lago_sheet_test.dart`: the reader against El lago's real sheet (the file on the vm, the fixture in chrome).
- Since order 36b (El banco), only as far as that scene needs:
  - `Sheet` reads what El banco's sheet writes that the earlier ones do not: `setKey.params` given in words (each its
    `fromW`), each baked state's `key` (`SheetBaked.key`) and the states not reached (`SheetSetKey.notReached`); `code`
    entries that list their numbers by kind (`SheetCode.numbers`, no `old` words: `old` is empty); `points` that are neither
    an anchor nor a screen point (the benches as a list, the paving's edge, the hedge, the gate's posts, the pole, the lamp
    post, the wire, the pool, the trees, the cart: `otherPoints`, kept as written); `smoothing` as words
    (`smoothingWhat`); `talk.heights` (each sprite's height; `heads` empty); `hopsAll` between screen points
    (`SheetHop.aAt`, `bAt`, `aNow`, `bNow`, `by`: `a` and `b` are then `"x,y"`); `helps` with no ring and a pigeon's shadow
    in the air (`SheetHelps.shadowGs`, `shadowGsSource`, `linesWhat`; `ring` throws for a sheet that has none); a move on
    several lines (`SheetMove.lines`); the remap's surfaces (`RemapTo.on`: `pave`, `seat`, `sky`, `out`, and `onWorld`); a
    spot's surface (`SheetAnchor.on`); a thing's `rolling` (the cart); the new parts `light` and `patch` (words by name) and
    `carro` (`SheetCarro`: standing, rolling, the sprite's `from` and `at`); and `checks` (`SheetChecks`: notes, and
    `notFixed`, what and why), read from `raw` while `checks` stays in `unknown` as for the earlier sheets. The earlier
    sheets read as before.
  - `test/banco_sheet_test.dart`: the reader against El banco's real sheet (the file on the vm, the fixture in chrome).
- Since order 38b (La estufa), only as far as that scene needs (on El banco's reader):
  - `Sheet` reads what La estufa's sheet writes that El banco's does not: a remap of kind `rect` (four numbers, its `new`
    four too: W.olor, the smell's curve); a clip the old code made that the sheet no longer makes (`clips.ventana`, `how`
    and no `world`: in `raw` only); a front part with no line, drawn `after` something at a world `y` (`front.parts.ventana`,
    in its `raw`); `code` lines of other files with no `old` (`juego.js:16`, `cual.js:21`); `talk.abuelaHead` (abuela's
    head off her x; `talk.heights` by `<who>` alone) and `talk.board` with no `boardWhat`; hops with counts only (`dOld`,
    `dNow` NaN); `helps` with no ring, no shadow and no line (null); `faults` (`Sheet.faults`: the old file's faults the port keeps: line, the line it goes with, in words).
    The earlier sheets read as before.
  - `test/estufa_sheet_test.dart`: the reader against La estufa's real sheet (the file on the vm, the fixture in chrome).
- Since order 39b (La nevera), only as far as that scene needs (on La estufa's reader):
  - `Sheet` reads what La nevera's sheet writes that La estufa's does not: review pictures given by their `screen` and `crop`
    only (`SheetPicture.world` null: `pictureRegion` and `pictureCrop` throw for them; ScenePictures cuts by the crop);
    whoever stands outside the window as a spot and as a move's place with `world` null (an empty world; the spot's screen
    place is its `new`); a remap of kind `x` whose `new` is one number (an x alone on the sill); `talk` with neither `heads`
    nor `heights` (each face measured from its sprite: the same reading as La mesa's, order 37b). The fridge's boxes, hands
    and hint boxes by state and the surfaces' rows (`layout.numbers`) are read from `raw`. The earlier sheets read as before.
  - `test/nevera_sheet_test.dart`: the reader against La nevera's real sheet (the file on the vm, the fixture in chrome).
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
dart run tool/make_sheet_fixture.dart [--check]   # test/support/fixtures/frente_sheet.dart, balcon_sheet.dart, sala_sheet.dart, patio_sheet.dart, camino_sheet.dart, campo_sheet.dart, lago_sheet.dart, banco_sheet.dart, estufa_sheet.dart and nevera_sheet.dart: docs/proyecto/pixel/<id>-sheet.json as a string, for chrome
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
