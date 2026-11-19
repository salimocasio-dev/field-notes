# ref/escenas: the eleven old scenes, what each holds and where, and frames of every state

Order 06 (docs/proyecto/13-flutter-orders.md). For each scene of `historia/escenas/` a folder `<id>/`, read from the old site as it is
(nothing under `historia/` changes): the next step (each scene's set and sheet, orders 07 and 30 to 39; then the port, orders 14 and 30b to 39b)
works only from these folders.

## Run

```
node coqui/tool/ref/escenas/make.mjs               # about 4 minutes: plays every story (order 05's juega.mjs --states, into a temp folder), then writes this folder
node coqui/tool/ref/escenas/make.mjs --work DIR    # reuse DIR/trazas and DIR/states (juega.mjs --out DIR/trazas --states DIR/states)
node coqui/tool/ref/escenas/make.mjs --only lago   # one scene; --out DIR writes elsewhere
node coqui/tool/ref/escenas/check.mjs              # the checks below
node coqui/tool/ref/escenas/sheets.mjs DIR [scene] # contact sheets of the frames into DIR (never into the repo)
```

Node 22 and the pre-installed Playwright Chromium. A second run gives the same bytes. The tool: `coqui/tool/ref/escenas/`:
`make.mjs` (the run), `page-escena.js` (run inside the old pages), `static.mjs` (reads a scene file as text), `config.mjs` (the judgments set
by hand, each with its line), `png.mjs`, `check.mjs`, `sheets.mjs`, `readme.mjs`.

## How it is read

- **The states.** Every story of the scene (curso.js lists 51 files to play) is played by order 05's player with its three plans; after every step it
  writes W, V and the camera (`juega.mjs --states`). Each review picture (`cuentos/cual-*.json`) is one more W: `panelW(spec)` of cual.js on
  cual.html. A level-check picture uses a review picture's W (nivel.js:75), so it adds no state.
- **The page.** Each scene is loaded on `historia/index.html?cuento=<one of its stories>` with order 05's `page-init.js` (virtual clock, seeded
  Math.random, and the catch of what the scene passes to `KIT.escena`). Then `page-escena.js` sets juego.js's `W`, `cam` and `F` to a recorded
  state and calls the scene's own `draw`, `box`, `hit`, `handAt`, `fresh`, `hud`. The scene canvas's methods are wrapped on the instance to record
  every call with its stack (file:line); `W` is read through a Proxy to know which keys each function reads.
- **A state** (frames/index.json) is a group of snapshots with the same background sprite(s), the same *set* things shown with the same boxes,
  and the same values of the *set keys* (the W keys the sprite layer reads, less the character, moving-prop and sign keys of config.mjs).
  Characters and moving props (people, animals, the frog, a ball in the air) do not separate states; their box in every snapshot is in the
  inventory (`things[id].bySnapshot`, `spriteLayer`). Every recorded step and every review picture is in exactly one state (check.mjs).
- **Frames** are drawn at the frame counter the page had then (`floor(t/70)`, moved past a blink); review and level pictures at F=8.
  Only the scene's `draw()`: juego.js's signs (the big hand, the frame round a thing, stars, the heart, answer bubbles) are not in the state frames;
  the views add the scene's `hud()` as the play screen does. The pair pictures are drawn as cual.js draws them (answer bubbles included).

## Files of a scene folder

### inventory.json

| field | what |
|---|---|
| `scene`, `file`, `sha256` | the scene file and the SHA-256 of the text read |
| `stories`, `reviewFile`, `hostPage` | the story files set in this scene (`scene` field), its review file, the page the scene was loaded on |
| `background` | `functions` (bg, fondo, mkPuesto, cielo), `at` (file:line of the function and of its call in draw), `keys` (the W keys that decide it: the set's states), `keysCheck` (checked over every W), `sprites`: each background sprite made (`key` of the sprite cache, the maker's source, the W keys the maker read, where it was asked for) |
| `given` | kit scenes: what the scene passed to `KIT.escena`: `call` (file:line), `keys`, `CAM`, `heartAt`, `lugar` (frog spots: x, y, scale), `cosas` (every field of every thing; a function as `{fn: source, line}`), `fresh`, `acts` (`own` and `shared`: the kit's ir, burbuja, calla, pose, fin when the scene has none of its own), `other`, `functions` (draw, hud, poke, stake, talkAt, respIcon, estado with lines), `hitOrder` (kit.js:120-125: the z things, the bird, the frog, the rest; slack m). El frente: `ESCENAS.frente` read from the page (`CAM`, `heartAt`, `handAt`, the getter of abuela's hand, `acts`), `box` (source and line), `hit` (`order`: every id in hit()'s order with its condition and test, file:line; `rects`), `consts` (ABAT, PERCH, HOLE, SPOT, LUGAR, NX evaluated from their lines in the file) |
| `thingIds` | the ids, in the scene's order (kit: `cosas`; El frente: hit()'s order) |
| `things.<id>` | `moves` (its box and visibility read only character or moving-prop keys), `fresh` (si, box, hand in the fresh state), `boxReads` / `siReads` / `handReads` (W paths each reads), and either `byState` (each distinct {si, box} with the state ids) or, for a thing that moves, `bySnapshot` (each distinct {si, box} with the runs and step numbers, or review pictures, that gave it). A box is `[x, y, w, h]` on the 240 x 216 picture; si `true` = shown |
| `hitTest` | the scene's own `hit()` on every 3rd pixel of every distinct W: `idsAnswered`, `answers` (count, states, a point), `onlyInList` (ids never answered), `notInList` |
| `namedInFiles` | every id the story files name (ask, decide options, pick, vale, alias, gratis, names, set spot) and the runs offered or touched, with where; `$var` true when filled at run time |
| `views`, `storyViews` | the scene's `CAM` rectangles; a story's own `cam` (juego.js:413) |
| `fresh.<story>` | `scene`: the scene's `fresh(S)` for that story; `page`: juego.js's `fresh()` (its defaults and the scene's) with the camera |
| `states` | `count`, `distinctW`, `snapshots`, the grouping rule, `setKeys`, `setThings`, `movingThings`, `propKeys`; the states themselves are in frames/index.json |
| `wKeys.<key>` | every W key seen: `fresh` (set by fresh()), `writtenBy` (`actsInCode`: acts whose source assigns it; `otherCode`: other functions of the scene object, draw included; `seenAfter`: step kinds and acts after which it had changed in the runs, with counts; `setIn`: set steps and review pictures that set it), `readBy` (background, spriteLayer, hitTest, hud), `role`, `distinctValues`, `values` (the 25 most frequent, with counts) |
| `spriteLayer` | every item the sprite layer draws: `key` (functions between draw() and the canvas @ the line of draw() · the sprite maker), `class` (background, character, prop or effect), `maker`, `method`, `functions`, `drawCall`, `code`, `sites` (file:line of the canvas calls), `chain`, `clipped` (clip sites active), `states`, `boxes` (screen boxes and the states each was seen in) |
| `positionsInFile` | numbers in the scene file that look like places (arrays of 2 to 4 numbers, `{x:, y:}`, place arguments of drawing and moving calls), outside the background function and the sprite makers: `at` (file:line), `fn`, `kind`, `nums`, `what` (the name or call), `comment` |
| `judgments` | the choices made for this scene |

### positions.json

Every distinct place on screen in the scene's story files, review pairs and level-check items. `positions[]`: `kind` (point: x, y;
x: an x alone; cam: a camera rectangle; rect; crop: a level-check crop; numbers: a list that is not a place), `x`, `y`, `w`, `h`, and
`uses[]`: `file`, `at` (path in the file: a step, or a pair's word and side), `owner` (`set.cq`, `set.gente.luis`, `act:anda quien=luis`, ...),
`meaning` (what the scene's code makes of it, with lines), `lugar` (the frog spots it equals), `insideThings` (the things whose box holds it in
the state after that step), `note`. `inSceneFile`: the same list as the inventory's `positionsInFile`.

### frames/

`index.json`: `views`, and `states[]`: `id`, `files`, `background` (sprite keys), `keys` (the background and set keys' values),
`things` (box of each set thing, null = hidden), `characters` (box of the frog, the bird, each moving thing, in the drawn snapshot),
`drawnFrom` (the snapshot drawn), `cam`, `F`, `distinctW`, `reachedBy` (`steps`: run -> step numbers, "start" = the fresh state; `pairs`).
`files`: `full` (240 x 216, the scene's draw), `nochar` (the same without characters), `full.<view>` and `nochar.<view>` (196 x 216, the view as
the player sees it, with the hud), `bg` (the background sprite alone). A file is written once: a state whose picture is the same as an earlier
one points to the earlier file. Indexed PNG when the picture has at most 256 colours.

### pairs.json and pairs/

`pairs[]`: every review pair of the scene's file and every pair picture this scene draws (`esc`): `file`, `w`, `say`, `sayText`, and
`si` / `no`: `scene`, `cam`, `set`, `esc`, `png` (196 x 104, as cual.html shows it), `samePixelsAsOther`. `level[]`: every level-check
item with a picture of this scene: `w`, `s`, `pictures[]` (`first` = the right one, `pair`, `side`, `x`, `crop`, `scene`, `png` 96 x 106).

### draw-order.md

For each character and prop, what draw() draws after it that overlaps it (what can cover it), always or in how many states; every clip region
with what is drawn inside it; the background calls; notes read from the code.

## The scenes

| scene | things | states | distinct W | positions | pairs | level items | views | frames |
|---|---|---|---|---|---|---|---|---|
| frente | 14 | 43 | 291 | 18 | 12 | 5 | 5 | 471 |
| balcon | 13 | 50 | 288 | 26 | 10 | 9 | 3 | 335 |
| sala | 16 | 27 | 338 | 46 | 11 | 12 | 2 | 156 |
| patio | 21 | 73 | 397 | 73 | 13 | 11 | 1 | 278 |
| camino | 22 | 9 | 352 | 35 | 13 | 4 | 1 | 31 |
| campo | 10 | 7 | 385 | 66 | 11 | 4 | 1 | 26 |
| lago | 19 | 10 | 597 | 48 | 11 | 4 | 1 | 41 |
| banco | 20 | 49 | 419 | 62 | 12 | 4 | 1 | 171 |
| mesa | 19 | 141 | 391 | 26 | 12 | 4 | 1 | 536 |
| estufa | 17 | 164 | 387 | 35 | 12 | 4 | 1 | 625 |
| nevera | 26 | 87 | 360 | 29 | 12 | 4 | 1 | 321 |

`datos/nivel.json` is the same as nivel.js's NV.

## check.mjs

1. Thing ids: the inventory's equal the list the running scene was given (kit: `KIT.escena`'s `cosas`, read again on a fresh page; El frente: hit()'s
   order); hit() answers no id outside the list; the ids the story files name (as written, or as filled and touched in the runs) are all in the
   scene (answer-bubble ids and names filled at run time are listed apart).
2. States: every step of every recorded run (coqui/ref/trazas) and every review picture of the scene is in exactly one state; every frame exists
   with its size.
3. Positions: the story, review and level files are walked again; every place found is looked up in positions.json.
4. The size of this folder.
