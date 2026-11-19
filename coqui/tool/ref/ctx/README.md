# ref/ctx: canvas reference data

Forty numbered cases drawn with the browser's 2D canvas into 64 x 64 tiles. Written to `coqui/ref/ctx/`. Order 11 tests the software canvas (`Ctx`, page 12 section 4) against it.

## Regenerate

From the repo root:

```
node coqui/tool/ref/ctx/make.js       # writes coqui/ref/ctx/ (about 3 seconds)
node coqui/tool/ref/ctx/check.js      # reads it back: every file against index.json, every tile and op, every source line in historia/
```

A second run gives byte-identical files. `make.js` renders the sheet twice in two fresh pages and stops if tiles, sources or call lists differ. Needs Node 22 and the pre-installed Node Playwright.

## What it makes

| File | What |
| --- | --- |
| `cases.json` | for each case: `n`, `kind`, `title`, `file` and `sha256` of its tile, `refs` (where in `historia/` its parameters come from: file, line, the line's text), and `ops`, every canvas call it made, in order, with its arguments. Also `sources` and how to replay (`replay`) |
| `tiles/NN.bin` | the case's tile: 64 * 64 * 4 bytes, RGBA, straight alpha as `getImageData` gives it, row-major |
| `sources/<id>.bin` | the sprites that `drawImage` draws, as RGBA: real sprites from `historia/engine.js` (`mkCoqui` at 1, .7, .6 and .5, `mkAbuela("idle",0)`, `mkTree`, `mkBush`, `mkPot`, `mkBall`, `mkCup`) |
| `sheet.png` | the 40 tiles on one picture, 8 across, numbered, enlarged 3 times (for looking at) |
| `cases.md` | one line per case: number, kind, what it draws, the old-code lines it follows |
| `index.json` | every file with its size and SHA-256 |

## How a case is made

- `sheet.html` loads `historia/engine.js` and `historia/escenas/kit.js` as they are. The drawing helpers a case uses (`fr`, `glyph`, `face`, `bubble`, `KIT.tarjeta`) are the real ones.
- A case draws on its own 64 x 64 canvas made with `getContext('2d', { willReadFrequently: true, colorSpace: 'srgb' })`. The tile starts transparent. The first thing every case does is set `imageSmoothingEnabled`: `false` unless the case is a smoothing case.
- The context is wrapped in a recorder. Every method call and every property set is logged as it is made, then done. So `ops` is what the browser ran, not what someone meant it to run. A call or property that `Ctx` does not have (for example `setLineDash`, `getImageData`) stops the run.
- Colours are written as the code wrote them (`"#2A1810"`, `"rgba(30,24,90,.32)"`) with the bytes the canvas turns them into: `[r, g, b, a8]`, `a8 = round(alpha * 255)` (checked in Chrome: `.32` gives 82, `.16` gives 41, `.5` gives 128).
- `drawImage` with three or five arguments is the op `drawImage`; with nine, `drawImageRect`. The image is a key of `sources`.
- Parameters are taken from real calls in `historia/` where there is one (`refs` names the line, found by its text; `check.js` fails if the old file's line has changed). Cases 4 (half positions, partly), 5 and 23 follow the order's list and have no matching call.

## The kinds

| Kind | Cases |
| --- | --- |
| fillRect-whole | 1 to 3 |
| fillRect-half | 4, 5 |
| drawImage-plain | 6 to 8 |
| drawImage-scale-1.6 | 9 to 11 |
| drawImage-scale-0.86 | 12 to 14 |
| drawImage-scale-stretch | 15 |
| drawImage-flip | 16 to 18 |
| drawImage-rotate-0.5 | 19 to 21 |
| drawImage-smoothing (smoothing on) | 22 to 25 |
| globalAlpha-0.5 | 26, 27 |
| alpha-rgba (a translucent `fillStyle`) | 28 |
| arc-fill | 29 to 31 (29: five radii) |
| ellipse-fill | 32 to 34 (32: five sizes) |
| clip-rect | 35, 36 |
| clip-rotated (a clip under a rotation) | 37 |
| stroke-1 | 38, 39 |
| stroke-2 | 40 |

## Things a Dart test needs to know

- The browser's default for `imageSmoothingEnabled` is `true`, and the old scene context `c` (juego.js line 12) is never set to `false` for the whole frame: only `dc` is (juego.js line 74), and a few scene functions set `c` to `false` and leave it. So a sprite drawn at a fractional position in the old game is bilinear. Cases 22 to 25 are drawn with smoothing on for that reason. Every other case has smoothing off, as the order says.
- An `arc` or `ellipse` with a sweep of 2 pi or more (the old code writes `7`) is a full circle. `arc(x, y, r, Math.PI, 0)` goes clockwise from pi to 0: the upper half.
- A tile is straight (not premultiplied) alpha; the canvas stores premultiplied, so a translucent pixel over a transparent tile can come back a step off in its colour channels (cases 6 and 26 to 28 show it where it matters).
- `cases.json` names the Chrome that drew it (`browser`). Another Chrome can differ at the edge of antialiased shapes.
- `lib.js` (PNG writer, SHA-256, index) is the same file in `ref/pp/` and `ref/sprites/`.
