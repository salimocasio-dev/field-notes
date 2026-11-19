# ref/sprites/escenas: the sprites each scene file makes for itself

Every sprite a scene file (`historia/escenas/<scene>.js`) asks engine.js's sprite cache for, read from the old page after the story runs of
`ref/trazas/`, as raw pixels with the key and the code that made it. One folder per scene, `coqui/ref/sprites/escenas/<scene>/`, and an index.
Sprites that engine.js, kit.js or juego.js make themselves are the other agent's (`ref/sprites/engine`, `ref/sprites/kit`); they are listed here, not dumped.

## Run

The sprites are made by the story runs, so the command is the stories' one:

```
node coqui/tool/ref/trazas/juega.mjs        # replaces coqui/ref/trazas/ and coqui/ref/sprites/escenas/
```

`sprites.mjs` in this folder is the part of it that merges and writes the sprites (imported by `../trazas/juega.mjs`; not run alone).
A second run gives byte-identical files.

## How they are read

- engine.js has one cache for everything: `const SP={}; function spr(k, fn){return SP[k]||(SP[k]=fn());}`. Every sprite of the scenes goes through it
  (the scene files have no cache of their own; 144 `spr(` call sites in the 11 files).
- Before any page script runs, `document.createElement` is wrapped to keep, for each canvas, the stack that made it (`../trazas/page-init.js`).
- After each run, every entry of `SP` is read: its key, its canvas, and from the canvas's stack the frame that called `spr` (the **caller**) and
  the frame just inside it (the **maker**, the function passed to `spr`). An entry belongs to a scene when its caller is in that scene's file.
  When two files ask for the same key, the first in that run made it (the cache is shared): `cq.7_0` is made by frente.js in some runs and by juego.js in others.
- Pixels: `getImageData` of the whole canvas, so RGBA, 8 bits a channel, not premultiplied, rows top to bottom. Each distinct picture is
  hashed (SHA-256 of those bytes) in the page and checked again when written.
- Canvases made by a scene file outside the cache (at load, or later) are watched too: there are none in any run (`outsideCache` is empty), so no
  scene builds a module-level sprite. (sala.js's `retrato` act would make one; no story calls it.)
- Runs are merged in a fixed order (stories in curso.js order, plans right, wrong, alternate), whatever order the pages finish in.

## Files

`<scene>/<key>.rgba`: the raw bytes, `w * h * 4`. Characters other than letters, digits, `_`, `.`, `-` in a key are written `~` and two hex digits.
When one key came out different in two runs, every version is kept as `<key>.0.rgba`, `<key>.1.rgba`, ... in the order first seen.

`<scene>/index.json`:

| Field | What |
| --- | --- |
| `scene`, `file`, `fileSha256` | the scene and the SHA-256 of its file |
| `sprites` | one per picture: `key` (the cache key exactly; it is JavaScript's own string of the numbers in it, `cq0.5400000000000001_00`, `cq1_00`), `file`, `w`, `h`, `sha256`, `caller` and `maker` (`file:line:col function`, 1-based, as V8 reports them), `firstRun` (`story/plan`), `runs` (in how many runs it was in the cache), `variants`, and `scratch` for a working canvas (below) |
| `outsideCache` | canvases the scene made outside the cache (none) |
| `notDumped` | keys found in this scene's runs whose caller is not the scene file (juego.js's frog and answer-bubble frogs, kit.js's bird), with that caller |
| `sites` | every `spr(` call in the scene file (`line`, `col`, the key expression as written), with `made`: the keys first made there; `madeElsewhere` for a literal key first made at another call site |

`index.json` (top): per scene `files`, `keys`, `differsBetweenRuns`, `outsideCache`, `notDumped`, `sites`, `sitesNeverReached`, and `bytes`.

## Is the cache complete?

It holds every sprite the 51 story files reach under the three plans (153 runs). To see what is missing, every `spr(` call site of each scene
file (144 in the 11 files) is listed in `sites` with the keys first made there. The cache is by key, so a site that only drew keys already made
at another site shows nothing; such a site is marked `madeElsewhere` when its key, or its key expression written the same way, was made elsewhere.
Of the 144, one never made its sprite and has no twin (`sitesNeverReached`):

- mesa.js 156: `spr("puesto", mkPuesto)`, the background when `W.afuera` (outside the kitchen). No story sets `afuera`; only the review set cual-mesa does.

Two sites have a twin but may never have run: balcon.js 124 col 172 (abuela standing away from the door, same keys as col 91) and camino.js 123
(the snail in the "despacio" doing bubble, same keys as line 105). Their keys are in the dump either way.

Other states that only review pairs and the level check use (¿Cuál?, `cual-*.json`, nivel.js) are not played here; where they need a key no
story makes, that key is missing. Keys made from state (`"fr"+door+"_"+win+"_"+lamp`, `"ab"+pose+habla`, ...) have only the combinations the runs reached.

## Things to know

- `sala/bor` is not a sprite: sala.js line 120 keeps a 20 x 18 canvas in the cache and draws the whole picture into it, smoothed, every frame
  `W.borroso` is set (the blur). Its pixels are the last such frame of a run, so it differs between runs (2 versions kept, `scratch` says so). Do not compare it.
- Frog sprites drawn by a kit scene's own `draw` (`"cq"+q.s+"_"+bl+op`) are the scene's here; El frente's frog is drawn by juego.js, so its frog keys are under `notDumped`.
- Pixels come from this machine's Chromium. Sprites drawn with `drawImage` scaling (frente's `palmita`) or smoothing could differ by a level on another Chromium.
