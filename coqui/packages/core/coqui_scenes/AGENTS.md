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
- `lib/src/registry.dart` holds `sceneRegistry`: the eleven scene ids in order, then the new scenes as they are converted (order 50b: `mostrador`; order 54b: `esquina`). El frente's, El balcón's, La sala's, El
  patio's, El camino's, El campo's, El lago's and El banco's factories make the real scenes (their sheets read first:
  `loadScene`); the other three are stubs that throw `UnimplementedError('not converted yet')`.

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
  ..., order 32b), El camino's two (`camino/gran-1`, `camino/gran-0`, order 33b), El campo's one with two more frames of it at
  other wind times (`campo/campo`, `campo/campo-t-1.5`, `campo/campo-t-3.25`: the page's `?t=`, its glints, order 34b), El
  lago's the same way (`lago/lago`, `lago/lago-t-1.5`, `lago/lago-t-3.25`, order 35b) and El banco's seven reached states
  (`banco/luz-dia-luna-0-carro-abierto` ..., order 36b).
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

## A park with a gate, a bench and a big tree (order 33b, El camino)

camino.js is on the kit too (`class Camino extends Escena implements SetScene, SetOverSprites`). What El camino's sheet has
that the earlier ones did not, and how the port uses it, as camino-preview.html does:

- **A hint box** (`things.grande.hintBox`). The big tree's touch box runs off the picture; its `Thing` carries the sheet's
  `hintBox` (`Thing.hintBox`, coqui_pixel), and the signs draw its hint frame and twinkle round that (`Signs.hintBoxOf`); a
  touch still answers in its box. Any thing of any scene can carry one; no other does.
- **`sevan`** (the sheet's `moves` at line 258, `Sheet.sevan`). At the end of story 14 everyone leaves through the arch in a
  file: abuela, Carmen, Luis, Canelo and the frog, 3 ticks apart (`sevan.delay`), each in 4 steps to a point just inside
  the opening and 4 more past its line (`sevan.points`), fading (al 1 - i / 8); the frog's two hops are the act's own (two
  hop sounds, no hopTo). Canelo is drawn with his `al` (`moves` at line 84). 20 ticks; the recorded runs of
  rapido-despacio were made with the old act: there and after they are 140 ms later, nothing else differs.
- **`moves`** at their lines: W.respEn at the start of stories 12, 13 and 14 (the answer cards in the sky:
  `CaminoPlaces.respEn(line)`), perroEn's x at most 188 (spots perro.7, perro.8), the cat on the bench (inicio13:
  `points.gato_banco`), the bird on the bench (`points.ave_banco`), the cat's hint hand at its back, the frog's place at
  the first tree (LUGAR.arbol0). The other places of the old file keep their numbers (the floor rule:
  `CaminoPlaces.floor(line, x, y)` finds each in the sheet's `code`, a place it does not name throws). `hops` is empty: all
  21 counts are the old ones (`camino_acts_test` checks each against the kit).
- **`front`**: the bench (`front.parts.banco`, `sortY` 134.5) and the arch (`porton`, `sortY` 9999: after everyone) are set
  things someone can be behind: at their entries in the list sorted by y their own pixels are drawn again inside each
  item drawn before them, only where nearer (`Camino.front`, `frontBox`: a person, the frog, Canelo or the cat; the cat on
  the bench takes `points.gato_banco.v`, the seat's front edge). The pixels of each part are recorded at the first bake of
  each state, as La sala's.
- **`talk`** as El patio's (its corner cards `tarjeta galletas` and `tarjeta guineos`); **`shadows`**: the frog's, the
  people's, Canelo's, the cat's (on the ground, not on the bench) and the bush's (the sprite layer's prop).
- **Remap**: a story position the sheet moved (the cat on the bench, Canelo at the first tree in d-corre), where the answer
  cards stand in h-camino (`respEn`: the runner sends it through remap since order 33b), three counts that are no place
  (`numbers`: W.pajaros, given back). cual-camino's `parque.no` is El patio's picture; `parque.si` is El camino's.
- **Random draws** (`gatoarbol`: two) from the game's `Rng`, as El patio's.
- Files: `lib/src/camino/camino_set.dart`, `camino_places.dart`, `camino.dart`. Tests: `camino_set_test`,
  `camino_sprites_test`, `camino_preview_test`, `camino_boxes_test`, `camino_pictures_test`, `camino_acts_test`; the
  preview's rule for moving a recorded W is `test/support/camino_preview_remap.dart`.

## A field by a lake (order 34b, El campo)

campo.js is on the kit too (`class Campo extends Escena implements SetScene, SetOverSprites, PairPlaces`). What El campo's sheet
has that the earlier ones did not, and how the port uses it, as campo-preview.html does:

- **The park's water** (`set_kit.dart`: `waterPixel`, `WSTEP`, `KIND_WATER`, `WaterLook`, `drawGlints`, set-kit.js's, for El lago
  too). The set's ground pass hands a pixel over the water to `waterPixel`, which draws the bank's face or the surface with their
  depth and collects the glints (`look.glints`) on the first bake (`campo_set.dart`'s ground cache keeps them, as the page's).
  `campoShore` (the set's `shore`) is what the scene asks too: over the water or not.
- **The glints, a per-frame step.** The bake leaves them in the engine (`PpEngine.glints`, `glintColour`), `BakedSet` keeps and
  restores them, and `drawFrame` draws them after `drawTufts` at the same wind time (coqui_pixel's `drawGlints`): deterministic
  from the frame's time, still when the OS asks for reduced motion. A set with no water has none: its frames are as before.
  `CampoSet.frame(t)` is the page's own frame (the reference states at t 0, 1.5 and 3.25).
- **`helps.ring`**: before a ball that floats or lies on the water (`Campo.under`, in unaBola) and under Canelo wading
  (`Campo.wade`, in perro), a ripple ring, `helps.ring`'s colour, every pixel between `inner` and 1 of its ellipse: the sheet's
  two lines added to campo.js.
- **`moves`** at their lines (`CampoPlaces.floor(line, x, y)`: a moved place gives its `new`; a move named on several lines
  gives its places on the first; a `moves` entry whose new source keeps the numbers (line 238's `ar?82:`), the same; a `code`
  entry of that line that names `[x,y]` or keeps every place on its line (`floor: true`), the same; else SheetError). Lines 233
  and 286 have no `code` entry: their places are kept by the sheet's `rules.floor` only (`CampoPlaces.floorRule`, those two lines
  only; reported by order 34b). `respEn` at inicio15, 16, 17 (`CampoPlaces.respEn`), JUNCO, the floating balls, Canelo's places
  by the water, the frog's at the reeds, the ball in a raised hand (manos, line 59).
- **`hops`**: LUGAR is the sheet's (centro, inicio); the acts' hopTo give their own counts; the 6 pairs one hop fewer are
  walked in no recorded run (`campo_acts_test` checks all 91 against the kit's count).
- **`shadows`**: the frog's, the children's, Canelo's (on the ground under him in the air too), the basket's and each ball's not
  carried, afloat, in the tree (`shadows.bola.tree`) or on the water, from its middle, on the ground under it in the air too.
- **`front`**: the reeds (`front.parts.juncos`, sortY 9999: after everyone) drawn again over each item before them, only where
  nearer (`Campo.front`, `frontBox`: a child, the frog, Canelo, a ball, the basket, each tagged as `front.tags`); over the water
  the test takes the surface (`front.waterDepth`).
- **`talk`** with one corner card as a rectangle (`SheetTalk.boardRect`, W.tarjeta); the faces lifted by `dy`.
- **Hint boxes** for the tree and the reeds (`things.<id>.hintBox`).
- **Remap**: a story position the sheet moved (d-bola-canelo's Canelo by the water), where the answer cards stand (h-campo
  beats.1, `respEn`), a ball's flight direction (`to.none`). A pair's own W holds places deeper than its top level
  (`gente.<id>`, `bolas.<k>`, `flor: [x, y]`): `ScenePictures.pictureW` gives them to a `PairPlaces` scene (`Campo.placePair`),
  which sends each through remap (the pairs dame, mi, tu, salta and bola moved up the lawn with their pictures).
- No random draw: the registry's factory takes no source.
- Files: `lib/src/campo/campo_set.dart`, `campo_places.dart`, `campo.dart`. Tests: `campo_set_test`, `campo_sprites_test`,
  `campo_preview_test`, `campo_boxes_test`, `campo_pictures_test`, `campo_acts_test`; the preview's rule for moving a recorded W
  is `test/support/campo_preview_remap.dart`.

## A lake with its dock (order 35b, El lago)

lago.js is on the kit too (`class Lago extends Escena implements SetScene, SetOverSprites, PairPlaces`). What El lago's sheet
has that the earlier ones did not, or uses differently, and how the port uses it, as lago-preview.html does:

- **The water takes no cast shadow** (`set_kit.dart`: `WaterLook.noShade`, set-kit.js's `look.noShade`: the surface is not
  ground). El campo leaves it out: its pictures are unchanged. The dock's own shade on the water is baked into the set
  (`lago_set.dart`: `SHADED`, kept with the ground cache, as the glints the shade and the dock drop).
- **The set** (`lago_set.dart`): two shores on the world's two axes, the deck with its planks, pilings, landing and mooring
  posts, the post in the water, the reeds, the waterlines, the dock's shade, the glints; one baked state. `lagoSurfaceAt` (the
  page's `surfaceAt`: the planks, the lawn or the water under a screen point) is what the scene asks for the rings, the
  shadows and the front test.
- **`helps`**: El campo's ripple ring before whatever floats or swims, a size per kind (`helps.ring.<kind>`: a duck swimming,
  the yellow one's .78 as wide; a boat on the water or in the reeds, bobbing; the bread lying on the water: `Lago.ring`,
  `ringWhere`); and the fish's patch (`helps.ring.pez`: `Lago.patch`, `patchAt`, the preview's function pixel for pixel: an
  ellipse 26 x 17 of the patch's colour, the lake's ripple dashes going on inside it in the dash colour, its outer 3 px
  dithered into the lake by a 4 x 4 Bayer; none when the fish leaps). Both only where the set's water shows
  (`Lago.waterShown`: the baked state's water with nothing standing over it, recorded at its bake; a scene that has not baked
  bakes once on an engine of its own).
- **`moves`** (23): read from the moved source itself (`LagoPlaces.to(line, src, [pattern])`: the numbers of the sheet's new
  source for that old source) for the post (POSTE), Carmen's right bank (ORILLA), the boats' row on the planks (FX, FYB),
  where boats stick (PEGA), the row at Carmen's feet (SLOTC, 12 slots), the ducks' seven places (P7), the bread row, the
  fish's circle and its place beside a boat, and the moved patoA, pezA and boteA calls; a moved place by its old numbers
  (`LagoPlaces.floor(line, x, y)`: a move's `places`, else the line's `code` entry that keeps every other place on it; else
  SheetError); `respEn` at inicio18, 19, 20. Three lines have numbers the sheet's code names nowhere (263: the birds rise to
  row 70; 276: the bread falls to `o.y || 178`; 278: the ducks swim out to x 252): kept by `LagoPlaces.floorRule`, those three
  lines only (reported by order 35b).
- **`hops`** is empty: all 21 counts are the old ones (`lago_acts_test` checks each).
- **`front`**: the reeds, the post and the mooring posts (`front.parts`, each sortY 9999: after everyone) drawn again over
  each item before them, only where nearer, the item's depth that of the surface under it (the planks', the lawn's or the
  water's: `Lago.vOf`); the items say what they are (`LagoItem`: a child, the frog, Canelo, a duck not flying, a boat, the
  fish; a bird, the bread, the bag and the sack are not drawn over, as the preview's `frontBox`). Nobody has the deck or its
  pilings drawn over them.
- **`shadows`**: on the lawn and the planks only: the frog, the children (sitting: to 1.35), Canelo, a duck walking, a bird
  standing (not on a post's top: `Lago.perched`), a boat on the dock, the row of bread, the bread lying, the bag, the sack.
- **`talk`** as El campo's; a sitting child's head is `heads.<id>.s`.
- **Remap**: the story positions the sheet moved (d-pato-pequeno's ducks, Luis in h-lago and d-pato-pequeno, the bird on
  the post); a pair's own W (`Lago.placePair`, the preview's `remapW` for cual-lago: the ducks, with the post's `shift`; the
  birds and their post; the boats, one at Carmen's to its slot; the fish; the flower, the bag, the sack).
- **Random draws** (mueven's `baraja`, rina's) from the game's `Rng` (the registry's factory takes it), as El camino's.
- lago.js's own `aveA` is `Lago.pajaroA` (the kit gives every scene its own bird's `aveA`). lago.js:237 ends in a comment that
  holds the rest of its line: that code never ran, and the port keeps it so.
- Files: `lib/src/lago/lago_set.dart`, `lago_places.dart`, `lago.dart`. Tests: `lago_set_test`, `lago_sprites_test`,
  `lago_preview_test`, `lago_boxes_test`, `lago_pictures_test`, `lago_acts_test`; the preview's rule for moving a recorded W
  is `test/support/lago_preview_remap.dart`.

## A paved corner with benches, a cart and a gate (order 36b, El banco)

banco.js is on the kit too (`class Banco extends Escena implements SetScene, SetOverSprites, PairPlaces`). What El banco's sheet
has that the earlier ones did not, or uses differently, and how the port uses it, as banco-preview.html does:

- **The set by its light** (`banco_set.dart`): `setKey` is `luz.luna.carro` (`dia`, `tarde`, `noche`; the moon only at night;
  the cart `abierto`, `cerrado` or `no`: gone, or rolling); 7 states are reached. Evening and night are the set under another
  light (`lightPass`), the lamp's glass lit (`plotGlow`) with its pool of light round its foot, the wire's colour by the
  light, the sun by day and in the evening, the moon (`luna`) and no sun at night: the old page's copied patch over its sun
  (banco.js:194) is kept so (the sheet's `patch`). The sprites are not darkened: the old overlays (banco.js:192 to :195) are
  dropped. No shadow at night (the set casts none; `Banco.shadows` gives none).
- **The draw order as it is drawn** (`front`): every item of the sorted list owns the pixels it drew last (`Banco.item`:
  their colour changed, as the preview's PV.item compares the canvas before and after); at each front part's entry (the
  three benches, the cart, the lamp post, the pole, the gate's posts, the hedge: sortY 9999, after everyone) the set's own
  pixels of the part are drawn again where their owner stands behind them (`Banco.front`, `frontBox`: a person, the frog, a
  dog, a pigeon not in the air or on the wire, the pushchair, a thing), never over whoever sits on that bench (their plane
  the seat's front under their lap) or what lies on its seat (`onSeat`, `perch`: the back, the seat).
- **The cart** (`carro`): standing it is the set's; rolling (`W.carroX`, the cart going home at night) the set has none and
  `Banco.cart` draws the set's own cart (the pixels tagged `carro` in the state with the same light and moon and the cart
  closed, that state's frame at time 0), moved by `cartAt` (dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2),
  CARRO banco.js's own as moved: 36), at its row in the sorted list (moves line 198); its touch box moves with it.
  banco-preview.html's PV.cartAt takes the same CARRO (spots.carro.new, the sheet's round 4).
- **`helps`**: a pigeon in the air has its shadow: palomaA keeps `o.gs` (`Banco.GS`, the sheet's `helps.shadow.gsSource`, its
  numbers read from the source).
- **`moves`** (42), read from the moved sources (`BancoPlaces.to(line, src, [pattern])`; a move named on several lines, the
  sheet's `lines`): PORTON and every way out through the gate (PORTON[1] + 12), SY and AS (the seats' edges), CARRO, POSA,
  JUGEN, respEn (in `fresh`), the sitters, the things on the seats, the dogs, the frog's home, Carmen, the queue, the
  señora leaning; every other place by `BancoPlaces.floor(line, x, y)` (a move's place, else the line's `code` entry: the
  sheet's maker read banco.js for every line) and `keep(line, v)`.
- **Two acts named twice** in banco.js's object of acts (`manos`: lines 280 and 407; `sale`: 291 and 399): the later wins,
  as it did in the old game.
- **`talk`** with each sprite's height (`talk.heights`), abuela's face from her sprite; **`shadows`**: the frog, the people
  (sitting: from the ground under their feet), the dogs, the pushchair, the pigeons (on the ground, or in the air), the
  things on the ground; **hint box**: the park.
- **Remap**: the story positions the sheet moved (d-vamos-a-casa's ways out, h-banco's sitters and the rucksack on the seat,
  the piragua man with his cart); a pair's own W (`Banco.placePair`: the preview's `remapW` for cual-banco, the sitters at SY).
- No random draw: the registry's factory takes no source.
- Files: `lib/src/banco/banco_set.dart`, `banco_places.dart`, `banco_sprites.dart` (banco.js's own sprites), `banco.dart`.
  Tests: `banco_set_test`, `banco_sprites_test`, `banco_preview_test`, `banco_boxes_test`, `banco_pictures_test`,
  `banco_acts_test`; the preview's rule for moving a recorded W is `test/support/banco_preview_remap.dart` (the scene's own
  `remapW`, the frog's part included).

## A new scene of places 4 to 10 (order 50b, El mostrador; El colmado's first)

There is no old scene file: the scene is written new from its script's "Needs" list (`historia/notas/guiones/<id>.md`), its
set ported call for call from `<id>-set.html`, every place from the content lane's sheet, read by coqui_pixel's `SceneSheet`
(not `Sheet`: another shape). How El mostrador does it, as the pattern for the 27 after it:

- **The place's kits and cast** (`lib/src/colmado/`, one first writer, the others add only): `colmado_dentro.dart` and
  `colmado_fuera.dart` (colmado-dentro.js and colmado-fuera.js whole; `test/colmado_kit_test.dart` against the JavaScript,
  `tool/make_colmado_kit_ref.mjs`), `colmado_cast.dart` (don Pepe, the three children, the goat, coins, bags, the goods:
  mkPersona and Buf as the family is drawn; `Anchored`, `inkBottom`, `overSprite`). `tool/make_colmado_sprites_test.dart`
  writes the sprite sheets for the content lane (`docs/proyecto/pixel/port/colmado-sprites.png`, `mostrador-sprites.png`).
- **The sheet.** `sheet_cache.dart` reads a sheet with no `pairPicture` as a `SceneSheet` (`sceneSheetOf(id)`); `sheetOf(id)`
  then gives its `legacy()` Sheet, which is the scene's `sheet` for the shared code (no places, no pictures; the start frog
  the runner's own, the scene's `fresh` places him).
- **The set** (`mostrador_set.dart`): `setKey` is the sheet's (`hora-atras-nevera` inside, `hora-puerta` in the street). A
  state on another origin (the street, `calle`, the sheet's part) is built on an engine of its own and handed to the
  scene's engine (every buffer a bake leaves), so one engine serves both; its shadows are cast at the scene engine's world
  point under the same screen point. 12 states in `coqui/ref/pp/mostrador/` (0 of 51,840 differ).
- **The scene** (`mostrador.dart`, `class Mostrador extends Escena implements SetScene, SetOverSprites`): people and things
  are kept in W by world point and picture (`gente`, `cosas`); `items` places every sprite by rules.anchor, `placed` adds the
  frog (drawn by the host's `frog` into a small picture); `draw` composes them by the sheet's `front` (a set pixel nearer
  than the upright plane through the feet plus `bias` hides a sprite pixel; between sprites the nearer wins) and draws the
  covered box. Touch boxes of sprite things are their drawn pixels' box; the set's things the sheet's boxes. The scene's
  state at the start follows the story's acts (`fresh` reads them: who is there, what is on the shelf, the list). Each act
  does what the Needs line says; where the sheet names no place or the script settles no picture, an `OPEN:` comment.
- **Tests**: `mostrador_set_test` (12 states), `mostrador_acts_test` (every act of the three stories on a StillHost, both
  branches; boxes and touches after each), `colmado_kit_test`, `colmado_cast_test`; in feature_story `mostrador_stories_test`
  and `tool/mostrador_paths_test.dart` (every path, the sheet's rules at every act's end: `test/support/mostrador_rules.dart`).
- Bake: `?page=bake&scene=mostrador`, `node tool/bake_time.mjs --scene mostrador`.

## La calle's shared pieces and La esquina (order 54b, place 5's first scene)

- **The place's kit, vehicles and cast** (`lib/src/calle/`, one first writer, the other three add only): `calle_base.dart`
  (calle-base.js whole; `test/calle_kit_test.dart`, 77 cases on the four sets' origins equal to the JavaScript,
  `tool/make_calle_kit_ref.mjs`), `calle_vehicles.dart` (the red car, the blue car and the guagua baked ONCE each from
  `vehicle(kind, x, y, heading, board)`: an engine at origin (0, 0), a flat ground, the vehicle at (3, 3), shadeEdges, the
  pixels and their depths cropped; both headings, the guagua with each roof picture; `litVehicle` (a set's lightPass),
  `vehicleShadows` (the casts vehicle() makes), `placeVehicle` (by the floor's middle), `putVehicle` / `personOver` (per-pixel
  depth: a person is hidden by a vehicle's pixel as by the set's, with front.bias), `drive` (along a lane, easing to a
  stop); new looks: a door open, a window down with a face; `test/calle_vehicles_test.dart`, every bake equal to
  `tool/make_calle_vehicles_ref.mjs`'s), `calle_cast.dart` (the obrero, his paddle, flags, bottle and bucket, the cones, the
  bicycle alone, ridden and pushed, the bebé on an arm, `callePerson` for everybody of the place). The sheets for the content
  lane: `tool/make_calle_sprites_test.dart` writes `docs/proyecto/pixel/port/calle-sprites.png` and `esquina-sprites.png`.
- **La esquina** (`lib/src/esquina/`): `esquina_set.dart` (esquina-set.html; 8 states in `coqui/ref/pp/esquina/`, 0 pixels
  differ), `esquina_places.dart` (the sheet's places, and its `routes.trafico.lanes` read as plain data),
  `esquina_sprites.dart`, `esquina.dart` (`class Esquina extends Escena implements SetScene, SetOverSprites`, written new from
  esquina.md's Needs list as El mostrador is: people and things by world point; the vehicles composed first with their own
  depths, then every sprite by front.plane; the frog's pixels are never hidden by a grown-up's or a vehicle's, the sheet's
  rule; acts started with `suelto: 1` waited for by `ya`; `OPEN:` comments where the sheet names no place).
- **Tests**: `esquina_set_test`, `esquina_acts_test` (every act of the three stories on a StillHost, both branches and the
  leads; boxes and touches after each); in feature_story `esquina_stories_test` and `tool/esquina_paths_test.dart` (every
  path; the rules: `test/support/esquina_rules.dart`). Frames for looking: `COQUI_OUT=DIR flutter test
  tool/esquina_frames_test.dart`. Bake: `?page=bake&scene=esquina`, `node tool/bake_time.mjs --scene esquina`.

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
- **The tests of the old pictures' path** do not depend on which real scenes are converted (order 36b): they use a test-only
  scene (`prueba`, test/support/fixtures/test_scene.dart: three of order 06's pictures of El banco), never converted, read
  through `TestSceneBundle` (test/support/sheet_bundle.dart). An id the registry does not hold is a scene for ScenePictures
  only when the bundle holds its old pictures; once every real scene is converted the path is still tested so.
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
dart run tool/make_set_fixture.dart [--check]     the hashes of coqui/ref/pp/frente/, .../balcon/, .../sala/, .../patio/, .../camino/, .../campo/, .../lago/ and .../banco/ for the browser set tests
dart run tool/make_sprite_fixture.dart [--check]  the hashes of coqui/ref/sprites/escenas/frente/, .../balcon/, .../sala/, .../patio/, .../camino/, .../campo/, .../lago/ and .../banco/
node tool/preview_shots.mjs [--scene balcon|sala|patio|camino|campo|lago|banco] --states DIR --out DIR [--fixture]   <scene>-preview.html's pictures (DIR from
                                                  node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR, for each of
                                                  the scene's stories)
COQUI_PREVIEW_DIR=DIR COQUI_REPORT_DIR=DIR [COQUI_SCENE=balcon|sala|patio|camino|campo|lago|banco] flutter test tool/compare_all_test.dart   every picture of
                                                  preview_shots.mjs against the Dart frame
COQUI_OUT=DIR COQUI_CASES=FILE flutter test tool/make_pictures_test.dart   the pictures for fresh readers
COQUI_OUT=DIR flutter test tool/make_cells_test.dart   the 24 review pictures and the 9 level cells of El frente, 4x, and a contact sheet of the cells
flutter build web --release --no-web-resources-cdn -t tool/dev_main.dart; node tool/bake_time.mjs [--scene balcon|sala|patio|camino|campo|lago|banco]   bake times
                                                  (each state's first bake, then again on the same engine; for a set with glints on its
                                                  water, what drawing them costs a frame)
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
