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
  a host whose waits return at once and whose sound is silent), `PictureError`, and `ScenePictures`, the `PictureSource` of
  page 12, section 3: `of(ref, {width = 196, height = 104, animated = false})`, sizes in PICTURE pixels, no scale.
- `lib/src/registry.dart` holds `sceneRegistry`: the eleven scene ids in order. El frente's, El balcón's, La sala's and El
  patio's factories make the real scenes (their sheets read first: `loadScene`); the other seven are stubs that throw
  `UnimplementedError('not converted yet')`.

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
  stale). To convert a scene: add the id to `convertedScenes` (`lib/src/converted_scenes.dart`, the one list the app and the
  tools read), point the registry at the real factory, and run `dart run tool/make_old_pictures.dart` (below): the scene's
  old pictures go.
- `coqui/ref/pp/<id>/`: the set's baked states, made by `node coqui/tool/ref/pp/make.js --states <file>` with one line per
  state of the sheet's `setKey.baked` (`{"id": "<id>/door-shut-win-shut", "kind": "set", "page": "docs/proyecto/pixel/<id>-set.html",
  "query": "?door=shut&win=shut"}`), listed in `coqui/tool/ref/pp/states.json` and made by `make.js --only <ids>`: El balcón's four
  (order 30b), La sala's five (`sala/luz-1-fotos-000` ..., order 31b) and El patio's fifteen (`patio/hora-dia-door-shut-gate-shut`
  ..., order 32b).
- Tests: `set_test` (every state against `coqui/ref/pp/<id>/`), `sprites_test` (the scene's own sprites against
  `coqui/ref/sprites/escenas/<id>/`), `preview_test` (the frame against `<id>-preview.html`), `boxes_test`, `acts_test`,
  `pictures_test`, `picture_cut_test` (the size rule), `plate_test` (a thing drawn on the display, hit at both zooms),
  `shadows_test`. A browser test reads fixtures under `test/support/fixtures/`, each made by a tool with `--check`.

## A scene written on the kit (order 30b, El balcón; the pattern for the scenes after it)

El frente was written before the kit; balcon.js and the scenes after it call `KIT.escena`. Their port is an `Escena` (coqui_pixel)
that `implements SetScene` (`class Balcon extends Escena implements SetScene, SetOverSprites`): the kit gives `box`, `hit`,
`handAt`, the shared acts and the bird; the scene's own acts are `ownActs`; `buildSet` and `frogShadow` are written in the scene
(an `implements` inherits nothing). What El balcón needed that El frente did not, and how it is done:

- **Its glyphs and bubbles** (`GL.sol`, ..., `Object.assign(BUBL, ...)` at load): put into the game's tables when the scene is
  given its host (the `host` setter).
- **Its random draws** (`azar`: `Math.random() < .5`, which side each glass and jug is on): from the game's one `Rng`, given to the
  constructor (`Balcon(sheet, rng:)`, as the tests do), or else the host's (`(host as dynamic).rng`: the story runner holds the
  game's `Rng` as `rng`; the registry's factories take none). The trace's random draws are then the old run's.
- **The furniture in front** (the sheet's `front.parts`): the old picture drew the big chair, the small chair and the table as
  sprites after abuela when she stood behind them. They are in the set now; at each old line the scene draws the set's own
  pixels of that part again (balcon-preview.html `PREVIEW.front`), only where the pixel is nearer than abuela (the sheet's
  `front.plane`). The pixels of each part are the set reference's `part()` tags, recorded at the first bake of each state
  (`SetKit.PART_TAGS`); the set as the frame shows it comes from `drawFrame` (`SetOverSprites.setFramed`). A frame drawn with no set
  (the player with no screen, `HeadlessRenderer`) draws nothing again.
- **Places the stories and pairs write**: `remap` also gives abuela's spot (`ab`), a point's rounded screen place, a level crop's
  x as it is, and a pair rectangle's crop when the sheet names its pictures. `ScenePictures.pictureW` also remaps a list of things
  placed by `x` alone (the glasses and jugs of a pair: the remap's `x` kind). `frogOfCode` reads the old numbers of a `code` entry
  whose place is not used (`"cq x 150 y 178 s 1"`: El balcón's `juego.js:16` and `cual.js:21`).
- Files: `lib/src/balcon/balcon_set.dart`, `balcon_places.dart` (the sheet's places, `ptRound` as the preview's `ptR`),
  `balcon.dart`. Tests: `balcon_set_test`, `balcon_sprites_test`, `balcon_preview_test`, `balcon_boxes_test`,
  `balcon_pictures_test`, `balcon_acts_test` (with the shadows and the furniture in front). The preview's rule for moving a
  recorded W is `test/support/balcon_preview_remap.dart` (a dev tool's, per scene).

## A room seen from inside (order 31b, La sala)

sala.js is on the kit too (`class Sala extends Escena implements SetScene, SetOverSprites`). What La sala's sheet has that the
two earlier ones did not, and how the port uses it, as sala-preview.html does:

- **The floor rule.** The room is built round the old picture: every place on its floor keeps its old screen numbers, so the
  sheet gives each place's number as its `new` (`spots.<name>.new`; the `code` entry of each old `mueve(...)` place with its
  `new`; `SITIO` from the code entries of line 75). `sala_places.dart` reads them: `floor(line, x, y)` is the `code` entry of
  that line whose old place is `x, y` (a place the sheet does not name throws: stop). The few the sheet moves (`moves`: seven
  pieces of sala.js and their replacements, eight entries) come out of the same entries; a comment at each line says so.
- **`talk`.** Where a bubble goes (`Sala.talkPlace`, preview `PREVIEW.talk`): the first of the sheet's places beside the head
  whose bubble (`bubbles.rects`) is wholly in the view (`host.cam[0]`), clear of the corner cards shown (`talk.boards`,
  `SheetTalk.board`) and of every face (`talk.heads`); else over the head. `talkAt` and the frog's bubble use it.
- **The photos.** marco() draws only a photo: at `points.foto.<i>` (or `foto.<i>.torcida`, rotated by its `angle`), clipped to
  the frame's opening, the quad `clips.foto.<i>[.torcida].screen` (a screen quad: its world points are on the wall, not exact).
- **`smoothing`.** sala.js:120 and :121 (W.borroso) snapshot the picture drawn so far (`Ctx.snapshot`) into a 20 x 18 sprite
  and back up, with `Ctx.smoothing` on, then off; :137 (the camera's window out of focus) the same with a 5 x 5 sprite. The
  canvas's bilinear gives the browser's pixels here: the 5 x 5 window is exact (`sala_sprites_test`, `vis`), the blur
  identical to the preview (`blur.*` cases). acts.retrato shrinks the last frame drawn (the scene keeps its canvas) with
  smoothing off, from `points.retrato`.
- **The low table in front** (`front.parts.mesita`, `sortY`): at its place in the list sorted by y, its own pixels are drawn
  again inside each character drawn before it, only where nearer (as El balcón's furniture).
- **Review pictures** are named with the word's accents folded (`mama.si` for `mamá.si`): `sheetPictureName` finds them.
- **Random draws** (`azar`, in `lados`) from the game's `Rng`, as El balcón's.
- Files: `lib/src/sala/sala_set.dart`, `sala_places.dart`, `sala.dart`. Tests: `sala_set_test`, `sala_sprites_test`,
  `sala_preview_test`, `sala_boxes_test`, `sala_pictures_test`, `sala_acts_test`; the preview's rule for moving a recorded W
  is `test/support/sala_preview_remap.dart` (the moves of the acts its story names: the case's `acts`).

## A yard with its sky, by the hour (order 32b, El patio)

patio.js is on the kit too (`class Patio extends Escena implements SetScene, SetOverSprites`). What El patio's sheet has that
the earlier ones did not, and how the port uses it, as patio-preview.html does:

- **The hour is the set's.** `setKey` is `hora-door-gate` (`dia`, `tarde`, `tarde2`, `ocaso`, `crepusculo`, `noche`; W.noche,
  W.sol, W.osc as the sheet's `setKey.params.hora.fromW`): the sky, the hills and the light of the hour are baked; the old
  overlays of patio.js:147 and :148 are dropped and nobody is dimmed. The blades of the lawn take the light of the hour
  (patio-set.html sets the engine's `tuftLit` and `tuftDark` when its page loads): `PatioSet.buildSet` sets them first and
  `BakedSet` keeps them with the state, so one engine serves every hour. The ground (the field and the path beyond the yard
  take their colours from the hour) is cached per engine and per day, dusk and night (patio-set.html: one per page).
- **`behind`.** The sun, the moon and the stars are drawn first by `draw` (patio.js:130, :131), then `Patio.behind` draws the
  set's own pixels again wherever this frame's depth is over -1e8 (the hills included, and the leaves of this frame): the
  `SetOverSprites` turn the other way round. It reads the set as framed (`setFramed`: `engine.pix` after the shadows and its
  `zb` after the leaves, patio-preview.html `DEPTH.live()`). A frame with no set draws nothing again.
- **`flowerLeaves`.** At patio.js:135 (the sheet's `moves`) each flower in a bed's hole is drawn with its clump of leaves
  first (`Patio.flowerLeaves`: the stage `open` or `bud` by `f.k`, the sheet's rows and palette, 1:1, not dimmed).
- **The frog's places at the gate** (`moves`, line 86: LUGAR.porton and LUGAR.sale follow the gate): `LUGAR` is the sheet's
  `lugar`, so the kit's `ir` counts 8 pairs one hop more (the sheet's `hops`; `hopsAll` holds all 91, `patio_acts_test` checks
  each against the kit). No recorded run walks one of them.
- **`moves`** at their lines: SOLY (26 for the old 24), the sixth star, abuela in the door (spot `asoma`), the walk to the door
  (`seva`) and to the gate (`juntos`), the people of inicio9, inicio10 and inicio11 (`PatioPlaces.floor(line, x, y)`: a moved
  place gives its `new`, a place the code entry of that line names its own numbers), and `W.respEn` after inicio11.
- **A position an act reads from the story file** (`anda`, `pon`, `alcentro`: `+o.x`, `+o.y`) goes through `remap`, as the
  runner sends a set step's (h-patio beats.20 is moved). `remap` also gives back a point in the air (`to.screen`) and one that is
  no place (`to.none`, the eyes' direction).
- **`talk`** as La sala's, its corner cards read by `SheetTalk.boardsOf` (the sun card, the fireflies card, the two scores).
  **`shadows`**: the ball's on the lawn (not in the tree), the frog's and the people's (the baby in mamá's arms casts none).
- **Review pictures** fold `ñ` and write a space as `_` (`hasta mañana.si` is `hasta_manana.si`); cual-camino's `parque.no` is a
  picture of the yard (its `esc`), drawn by El patio.
- **Random draws** (`azar`, in `lados`) from the game's `Rng`, as La sala's.
- Files: `lib/src/patio/patio_set.dart`, `patio_places.dart`, `patio.dart`. Tests: `patio_set_test`, `patio_sprites_test`,
  `patio_preview_test`, `patio_boxes_test`, `patio_pictures_test`, `patio_acts_test`; the preview's rule for moving a recorded W
  is `test/support/patio_preview_remap.dart` (the moves of the acts its story names, the story's own positions the sheet
  moved: the case's `story` and `acts`).

## Pictures: by name, the size rule, old pictures until converted

`ScenePictures` (`lib/src/pictures.dart`) is the `PictureSource`. A `PictureRef` carries its scene, its state (`set`), and its
`name`: `<word>.si` / `<word>.no` (`PictureRef.of`) or `nivel.<word>.<index>` (`PictureRef.ofLevel`).

- **Converted scene (`convertedScenes`).** The picture of that name is the sheet's: `pictures.<word>.<side>`, or, for
  `nivel.<word>.<index>`, the sheet's `level` entry for that word and index (it names the pair picture it uses and gives its
  own `crop` and `zoom`). The state drawn is the ref's `set`. A ref with no name falls back to the old lookup by scene, state
  and view through the review pairs given to the constructor, and fails clearly when two pictures match. A name the sheet
  does not have fails clearly. A new scene's sheet must name every picture the content asks of it:
  `test/pictures_test.dart` ("the names the content makes") checks every pair side and level picture of every course item.
- **The size rule** (`lib/src/picture_cut.dart`, `pictureRegion` and `cutPicture`, tested in `test/picture_cut_test.dart`): the
  picture is `width` x `height` picture pixels. A REVIEW picture shows the region of `width / zoom` x `height / zoom` of the 240 x
  216 scene picture (zoom 1 or 2, from the sheet's entry), centred on the centre of the sheet's `crop` for the picture, kept
  inside the scene picture, each region pixel drawn as a zoom x zoom block; at 196 x 104 it is the sheet's `crop` exactly. A
  LEVEL-CHECK cell (`nivel.<word>.<index>`) is ALWAYS zoom 1, whatever the zoom of the pair picture it uses (decided: a zoom-2
  cell would be 48 x 53 picture pixels, smaller than a door or a window): a `width` x `height` region (96 x 106) centred on the
  centre of the level entry's `crop`, kept inside the picture, one picture pixel per pixel. A review size that is not whole
  zoom blocks fails with a `PictureError`; nothing is ever stretched by a fraction.
- **A scene that is not converted** shows its OLD picture (order 06's, `coqui/ref/escenas/<id>/pairs/`), found by the ref's
  name in `assets/old_pictures/<id>/index.json`, decoded and shown through `PixelView`. It comes only in the size it was drawn
  in (196 x 104 review, 96 x 106 level cell); any other size, a name with no picture, and a ref with no name fail clearly.
  `animated` does nothing for it; `warm` decodes it ahead. `dart run tool/make_old_pictures.dart` writes the folders (and the
  asset list in `pubspec.yaml`, and the test fixtures `old_sample.dart`, `old_hashes.dart`) for every scene NOT in
  `convertedScenes`, and removes the folder of any other; `--check` fails when something is stale or when a folder exists for a
  converted scene; it also fails for every picture a course item names that has no file.
- **A picture handed another picture in place** (the same widget with another ref, name, size or `animated`) starts over and
  shows the new one: its state mixes in `TickerProviderStateMixin`, because it disposes its ticker and starts another, which
  a single-ticker state refuses (Flutter threw and the picture showed the red error box). `test/pictures_test.dart` ("handed
  another picture in place") pumps one picture, then others in its place, animated and not.
- The next scene's order: add it to `convertedScenes`, make its sheet (`level` and `pictures` entries for every picture the
  content asks of it), run `make_sheets.dart` and `make_old_pictures.dart`, and add its tests to `pictures_test` as El frente's.
- Shadows: a character casts his engine shadow only while more than half faded in (`al > .5`), as the preview does it.
- A thing drawn on the display (hud: El frente's cake plate) is hit-tested in DISPLAY coordinates: `pictureToDisplay` /
  `displayToPicture` of coqui_pixel, so its touch area is the same at zoom 1 and zoom 2.

## Tools

```
dart run tool/make_sheets.dart [--check]          the sheets as assets (and their fixture for browser tests)
dart run tool/make_old_pictures.dart [--check]    the old pictures of the scenes not converted yet, as assets (and their fixtures)
dart run tool/make_set_fixture.dart [--check]     the hashes of coqui/ref/pp/frente/, .../balcon/, .../sala/ and .../patio/ for the browser set tests
dart run tool/make_sprite_fixture.dart [--check]  the hashes of coqui/ref/sprites/escenas/frente/, .../balcon/, .../sala/ and .../patio/
node tool/preview_shots.mjs [--scene balcon|sala|patio] --states DIR --out DIR [--fixture]   <scene>-preview.html's pictures (DIR from
                                                  node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR, for each of
                                                  the scene's stories)
COQUI_PREVIEW_DIR=DIR COQUI_REPORT_DIR=DIR [COQUI_SCENE=balcon|sala|patio] flutter test tool/compare_all_test.dart   every picture of
                                                  preview_shots.mjs against the Dart frame
COQUI_OUT=DIR COQUI_CASES=FILE flutter test tool/make_pictures_test.dart   the pictures for fresh readers
COQUI_OUT=DIR flutter test tool/make_cells_test.dart   the 24 review pictures and the 9 level cells of El frente, 4x, and a contact sheet of the cells
flutter build web --release --no-web-resources-cdn -t tool/dev_main.dart; node tool/bake_time.mjs [--scene balcon|sala|patio]   bake times
                                                  (each state's first bake, then again on the same engine)
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
