# ref/pp: engine reference data

Renders of the old engine in headless Chrome. Written to `coqui/ref/pp/`. Order 10 (the engine in Dart), order 13 (the map) and order 14 (El frente) test against it.

## Regenerate

From the repo root:

```
node coqui/tool/ref/pp/make.js        # writes coqui/ref/pp/ (about 7 seconds)
node coqui/tool/ref/pp/check.js       # reads it back: sizes and SHA-256 of every file, shapes of the buffers and unit files
```

A second run gives byte-identical files (`git status` stays clean). Needs Node 22 and the pre-installed Node Playwright (`require('playwright')`). Nothing is installed.
`make.js` also renders every state twice in two fresh pages and stops if the three buffers differ.
Options: `--only <id,id>` (a state id, `island` or `unit`), `--states <file>`, `--out <dir>`. The index is always rebuilt from the whole folder.

## What it makes

| Folder | What |
| --- | --- |
| `map/hecho-0`, `map/hecho-3`, `map/hecho-10` | `docs/proyecto/pixel/mapa.html?hecho=N`, the first frame, time 0 |
| `island/` | the map's island with no places (ground, `slabSides`, `growGrass`, `decorate`), built by `island.html`; `calls.md` and `decorate-calls.json` say what was called |
| `frente/<state>/` | `docs/proyecto/pixel/frente-set.html?door=…&win=…&lights=…&sky=…&hide=…&rustle=…&side=…`: the 25 baked states of El frente's set (order 07), one folder each, named after the query (`door-shut-win-shut-lights-0-sky-day`, … `-hide`, … `-rustle-casa-side--1`). The set's origin is its default (originX -2, originY 12); the frame is the bake plus `drawLeaves(0)` and `drawTufts(0)`, no characters |
| `unit/unit.json` | `hash`, `noise`, `project`, `unproject`, `rampOf` on 200 fixed inputs each, with the map's settings |
| `unit/unit-s26.json` | `project` and `unproject` on 200 fixed inputs, with S = 26, originX -30, originY 40 (El frente's origin before order 07; order 07 moved it to -2, 12. The file is kept as it was: it still tests the projection at S = 26) |
| `index.json` | every file with its size and SHA-256 |

Each dump folder holds:

- `pix.bin` (`Uint32Array`, little endian, pixels `0xAABBGGRR`: bytes R, G, B, A in memory order), `zb.bin` (`Float32Array`), `kinds.bin` (`Uint8Array`), each `width * height` long, row-major (`index = y * width + x`).
- `pix.json`, `zb.json`, `kinds.json`: width, height, element type, endianness, byte count, SHA-256 of the `.bin` beside it.
- `pix.png`: the picture (alpha 0 where nothing was drawn).
- `state.json`: the page and query, every engine setting (`W`, `H`, `S`, origin, `OX`, `OY`, shadow, `STILL`, wind and edge constants, the `PP_SCENE` given), counts (`tufts`, `leaves`, `waterPix`), and for a map state the `hecho`, `abierto` and `aqui` that mapa.html built, `N`, `time` and the frog.

The buffers are the ones the engine holds after the frame: `pix` and `zb` after `draw()` (not the baked ones), `kinds` as `bake()` left it.

## How the first frame is time 0

The old page files are not edited. `make.js` injects, before the page's scripts run:

- `requestAnimationFrame` only queues the callbacks. After load, `__flush()` runs the queue once with timestamp 0. mapa.html's `frame(now)` then has `dt = min(.05, (0 - last) / 1000) = 0` (`last` is `performance.now()`, which is 0), so `time` is 0 and the wind step, sea, flags and arrow bob are the time-0 ones.
- `performance.now()` returns 0. `Date.now()` and `new Date()` return 1700000000000.
- `Math.random` is Mulberry32 seed 1 and counts its calls. The pixel files do not call it; `state.json` says `mathRandomCalls: 0`, and `make.js` fails if that is not so.
- The browser context is fixed: viewport 390 x 844, device scale factor 1, `prefers-reduced-motion: no-preference` (so `STILL` is `false`), light colour scheme, `en-US`, `UTC`.

## Adding a state

Add a line to `states.json`:

```json
{ "id": "frente/door-shut-win-shut-lights-0-sky-day", "kind": "set", "page": "docs/proyecto/pixel/frente-set.html", "query": "?door=shut&win=shut&lights=0&sky=day&hide=0&rustle=none&side=1" }
```

`id` is the folder under `coqui/ref/pp/`; `kind` is `mapa` (adds the map state to `state.json`) or `set` (adds the page's `SPOTS` and `SCREEN` when it has them); `page` is a path from the repo root; `query` is the address query. The page must draw its one frame while it loads (or in a `requestAnimationFrame` callback, which `make.js` runs once at time 0). Then run `make.js` (all states, or `--only <id>`) and `check.js`. A folder whose id is no longer in `states.json` is not removed by `make.js`: delete it by hand (order 07 removed the old `frente/door-open-shutters-open-lamp-on`).
El frente's states: every state its stories, review pairs and level pictures reach (see `docs/proyecto/pixel/frente-sheet.json`, `setKey`).

## Notes

- `hash` and `noise` use `Math.sin`, and `Math.sin` is not the same function in every JavaScript engine. In Chrome 157 it gives exactly what glibc's `sin` gives (checked against Python's `math.sin` on 3 inputs); the same 200 inputs in Node 22 (V8 12.4) give a different last few digits for 5 of the 200 `hash` values and 9 of the 200 `noise` values, by up to 7.3e-12. `project`, `unproject` and `rampOf` are exact in both. The order's 1e-9 for `hash` and `noise` is right; the data names the Chrome that made it (`browser` in `state.json` and in the unit files' `settings`). The island's three buffers, run in plain Node (the old files in a `vm` with a stub canvas), match the Chrome ones byte for byte.
- Sizes: about 17 MB for the folder (El frente's 25 states are about 12 MB of it), most of it the raw buffers.
- The PNGs are made with Node's zlib (level 9). They are byte-identical between runs on one machine; another Node version can compress differently, so the `.bin` files and their hashes, not the PNGs, are what a test should rely on.
- `lib.js` (PNG writer, SHA-256, index) is the same file in `ref/ctx/` and `ref/sprites/`; each part stands alone.
