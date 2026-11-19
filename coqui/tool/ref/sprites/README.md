# ref/sprites: sprites of engine.js and kit.js

Every sprite that `historia/engine.js` and `historia/escenas/kit.js` can make, as RGBA pixels, with the call that made it. Written to `coqui/ref/sprites/`. Order 11 (sprites and the software canvas) and order 12 (the kit) are tested against it. Sprites that a scene file makes for itself are not here (order 05, part B).

## Regenerate

From the repo root:

```
node coqui/tool/ref/sprites/make.js     # writes coqui/ref/sprites/ (about 3 seconds)
node coqui/tool/ref/sprites/check.js    # reads it back: every file, every sprite slice, the sizes, the coverage
```

A second run gives byte-identical files. `make.js` runs everything twice in two fresh pages and stops if any pixel differs. Needs Node 22 and the pre-installed Node Playwright.

## What it makes

| File | What |
| --- | --- |
| `engine/<function>.bin`, `kit/<function>.bin` | the RGBA bytes of every sprite of that function, one after another (straight alpha, row-major, `w * h * 4` bytes each) |
| `engine/sprites.json`, `kit/sprites.json` | for every sprite: `id`, `fn`, `call` (the call, written out), `args` (as JSON), `w`, `h`, `file`, `offset`, `bytes`, `sha256`, and for a drawer its `target`. Also `functions` (per function: file, count, SHA-256, where `historia/` uses it). `kit/sprites.json` also has `FAM` (the people of the kit, as data; a function as its source text) |
| `sheet-engine.png`, `sheet-kit.png` | every sprite of the group at 1:1 in index order over grey, a gap between functions (for looking at) |
| `index.json` | every file with its size and SHA-256 |

A sprite is the `bytes` bytes at `offset` in `<file>`.

Two kinds of entry:

- **maker**: the function returns the picture (`mkCoqui`, `mkAbuela`, `mkPersona`, `bgCasa`, ...). `args` are its arguments.
- **drawer** (has `target`): the function draws on a canvas or a `Buf` it is given (`sky`, `grass`, `glyph`, `face`, `bubble`, `shadow`, `pointer`, `sparks`, `talk`, `KIT.tarjeta`, `KIT.mano`). A transparent canvas (`target.kind` `canvas`) or `Buf` (`Buf`) of `target.w` x `target.h` is made, the function is called on it with `args` (the canvas or `Buf` is the first argument and is left out of `args`), and the target is the sprite.

For `KIT.mkPersona` the first argument is `{ "fam": name }` or `{ "fam": name, "assign": {...} }`: `Object.assign({}, KIT.FAM[name], assign)`.

## Which argument values

Read from the scenes, juego.js, cual.js, nivel.js and app.html; where an argument is small and enumerable, every value.

| Function | Values |
| --- | --- |
| `mkCoqui(s, blink, open)` | `s` is every hundredth from .40 to 1 (juego.js `hopTo` rounds the frog's size to hundredths; the smallest the scenes use are .42 in frente.js and .5), plus the sizes that are not hundredths: camino.js `enT` gives `1 - .14 t` (t in twentieths) and frente.js `max(.5, s - .08)` (four steps from each size frente's `LUGAR` uses). `blink` 0, 1. `open` 0, 1. 364 sprites |
| `mkAbuela(pose, open)` | the seven poses it draws (idle, wave0, wave1, dedo0, dedo1, offer, bless), both mouths |
| `mkDog(wag)`, `bgCasa(open)` | 0 and 1 |
| `mkTree`, `mkPalm`, `mkBall`, `mkCup`, `mkBush`, `mkPot`, `bgParque` | no arguments |
| `sky(b, 240, hz)` | `hz` 84, 96, 100, 150 (parque, banco and frente, camino, campo and lago, balcon), on `Buf(240, hz)` |
| `grass(b, y0, 240, H)` | (y0, H) = (150, 216), (92, 133), (100, 216), (96, 216), (94, 120), (110, 216) from the scenes (balcon, banco, camino and campo, frente, lago, patio), and (96, 150), (86, 150) from `bgCasa`, `bgParque`; on `Buf(240, H)` |
| `glyph(c, k, x, y)` | every key of `GL` in engine.js, at (2, 2) |
| `face(c, cx, cy, ok)` | true, false |
| `bubble(c, list, tx, ty, f)` | the four lists of `BUBL` in juego.js that use engine.js's icons (como, bien, mal, quien), `f` 0 and 1 |
| `shadow(c, x, y, w)` | `w` 10 to 27: juego.js draws `shadow(g, b.x + 2, q.y + 25, b.w - 5)` and `b.w = round(30 s) + 2` |
| `pointer`, `sparks`, `talk` | one sample each (`f` 0, 1; `talk` also `dir` 1, -1): engine.js defines them, `historia/` never calls them (`usedInHistoria` is 0) |
| `KIT.mkAve(st, fl)` | st n, sleep, feliz, round; fl 0, 1 |
| `KIT.mkAbuelaS(pose, open, pies)` | idle, fan0, fan1, vaso, bebe, zzz; open 0, 1; pies 0, 1 |
| `KIT.mkPersona(w, pose, open, sent)` | w: each of `FAM` (mama, papa, abuelo, hermano, hermana); each with `{ dormido: 1 }` (estufa.js, nevera.js, sala.js); abuelo with `{ gafas: "arriba" }` (sala.js). Poses idle, wave0, wave1, offer, yo, tu, foto, taza, ojos; open 0, 1; sent 0, 1. 396 sprites |
| `KIT.mkBebe(est, f)` | idle, clap, llora, come (the four it draws) and duerme, rie, cal, carmen (values the scenes pass; they draw as idle); f 0, 1 |
| `KIT.mkPerro(pose, f)` | lie, panza, sit, eat, bark, husmea, run, walk; f 0, 1 |
| `KIT.mkCesta` | no arguments |
| `KIT.tarjeta(g, x, y, w, h)` | every (w, h) written as numbers in `historia/` (found by `make.js`: 34x52, 50x50, 50x62, 66x24, 78x29, 84x30, 88x30), at (3, 3) |
| `KIT.mano(g, x, y)` | (3, 2) |

## Not here

- `coqui(s, f, open)` in engine.js only caches `mkCoqui(s, (f % 19) === 0 ? 1 : 0, open)`. `fr`, `rgb`, `hs`, `bay` are helpers the sprites use.
- `drawAve`, `avePos`, `aveVa` and the other bird functions of kit.js draw from scene state (the frame counter, the scene's `W`); their sprites are `mkAve`.
- A pose, `st` or `est` the function does not handle draws as its default (idle, n, idle): such values are not repeated.
- Glyphs that other files add to `GL` (`GL.gota` in juego.js; `sol`, `jugo`, `agua`, `equis` in balcon.js; `biz`, `gaf` in sala.js) are not engine.js's. So `BUBL.lluvia` (needs `gota`) is not here.
- No function of engine.js or kit.js calls `Math.random`: `make.js` pins it (Mulberry32, seed 1) and fails if it is called. Nothing in the data depends on it.

## Size

About 7.9 MB: `kit/mkPersona.bin` 3.7 MB, `engine/grass.bin` 1.4 MB, the rest under 1 MB each.
`lib.js` (PNG writer, SHA-256, index) is the same file in `ref/pp/` and `ref/ctx/`.
