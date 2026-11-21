# nevera: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (412 W, 90 states); each call's place is the first frame of its stack in a scene file. historia/escenas/nevera.js draw(): lines 155-178.

**Drawn in order of y:** the items pushed to a list before nevera.js:169 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `nevera @nevera.js:156` | prop or effect | nevera.js:118, nevera.js:119, nevera.js:122, nevera.js:123, nevera.js:124 | fillRect | `nevera > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` (125 of 171); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (123 of 394); `gente @nevera.js:169 · mkAbuela` (16 of 265); `tenida @nevera.js:170 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 2) |
| `nevera > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `nevera @nevera.js:156` (50 of 171); `gente @nevera.js:169 · mkAbuela` (1 of 120); `tenida @nevera.js:170 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 2) |
| `patio @nevera.js:156` | prop or effect | nevera.js:112, nevera.js:113 | fillRect | `patio > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` (184 of 237); `patio > hedor @nevera.js:156` (always); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (175 of 394); `rana @nevera.js:169 · mkCoqui` (16 of 388); `tenida @nevera.js:172 · ()=>(COSA[k]||COSA.plato)(c)` (always); `nube @nevera.js:174` (always); `nube > tenida @nevera.js:174 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `patio > gente @nevera.js:156 · KIT.mkPersona` | character | nevera.js:145 | KIT.mkPersona | `patio @nevera.js:156` (always); `patio > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` (92 of 213); `patio > gente > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` (always); `patio > hedor @nevera.js:156` (1 of 37); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (always); `rana @nevera.js:169 · mkCoqui` (16 of 339); `hedor @nevera.js:169` (always); `tenida @nevera.js:170 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 2); `@nevera.js:171` (always); `tenida @nevera.js:172 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `patio > gente > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` | character | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `patio @nevera.js:156` (always) |
| `patio > hedor @nevera.js:156` | prop or effect | nevera.js:104 | fillRect | nothing |
| `patio > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `patio > gente @nevera.js:156 · KIT.mkPersona` (133 of 213); `patio @nevera.js:156` (179 of 237); `patio > hedor @nevera.js:156` (always); `rana @nevera.js:169 · mkCoqui` (12 of 237) |
| `@nevera.js:162` | prop or effect | nevera.js:162 | fillRect | `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `tenida @nevera.js:163 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `gente @nevera.js:169 · KIT.mkBebe` | character | nevera.js:146 | KIT.mkBebe | `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 117); `gente > tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 10) |
| `gente @nevera.js:169 · KIT.mkPersona` | character | nevera.js:145 | KIT.mkPersona | `gente > tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (104 of 118); `gente @nevera.js:169 · mkAbuela` (6 of 200); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (8 of 287); `gente @nevera.js:169 · KIT.mkBebe` (always) |
| `gente @nevera.js:169 · mkAbuela` | character | nevera.js:142 | mkAbuela | `gente @nevera.js:169 · KIT.mkPersona` (186 of 200); `rana @nevera.js:169 · mkCoqui` (219 of 263); `gente > tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (91 of 97); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (12 of 265); `tenida @nevera.js:170 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 2); `@nevera.js:171` (1 of 2); `nube @nevera.js:175` (always); `nube > tenida @nevera.js:175 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `gente > tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` | character | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `gente @nevera.js:169 · KIT.mkPersona` (100 of 118); `gente @nevera.js:169 · mkAbuela` (6 of 97); `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 112); `rana @nevera.js:169 · mkCoqui` (20 of 112) |
| `hedor @nevera.js:169` | prop or effect | nevera.js:104 | fillRect | nothing |
| `rana @nevera.js:169 · mkCoqui` | character | nevera.js:152 | mkCoqui | `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (343 of 388); `gente @nevera.js:169 · KIT.mkPersona` (94 of 287); `gente @nevera.js:169 · mkAbuela` (1 of 263) |
| `tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | `gente @nevera.js:169 · mkAbuela` (263 of 265); `gente @nevera.js:169 · KIT.mkPersona` (226 of 287); `rana @nevera.js:169 · mkCoqui` (387 of 388); `gente > tenida @nevera.js:169 · ()=>(COSA[k]||COSA.plato)(c)` (93 of 112); `gente @nevera.js:169 · KIT.mkBebe` (43 of 117); `@nevera.js:171` (always); `tenida @nevera.js:172 · ()=>(COSA[k]||COSA.plato)(c)` (always); `hedor @nevera.js:173` (always); `nube @nevera.js:175` (always); `nube > tenida @nevera.js:175 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `tenida @nevera.js:170 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `@nevera.js:171` | character | nevera.js:171 | fillRect | nothing |
| `tenida @nevera.js:172 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `hedor @nevera.js:173` | character | nevera.js:104 | fillRect | nothing |
| `nube @nevera.js:174` | character | nevera.js:150 | fillRect | `nube > tenida @nevera.js:174 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube > tenida @nevera.js:174 · ()=>(COSA[k]||COSA.plato)(c)` | character | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `nube @nevera.js:175` | character | nevera.js:150 | fillRect | `nube > tenida @nevera.js:175 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube > tenida @nevera.js:175 · ()=>(COSA[k]||COSA.plato)(c)` | character | nevera.js:103 | ()=>(COSA[k]||COSA.plato)(c) | nothing |

## Clip regions

| at | region (scene picture) | what is drawn inside it | seen in |
|---|---|---|---|
| nevera.js:106 `function patio(c,a){const P=W.patio||{},Gt=W.gente||{},Wd=RP.wood;c.save();c.beginPath();c` | rect [150,36,64,62] | `patio > gente @nevera.js:156 · KIT.mkPersona`; `patio > gente > tenida @nevera.js:156 · ()=>(COSA[k]||COSA.plato)(c)` | 412 W |

## Background

- nevera.js:22 fondo()
- nevera.js:156 spr("nevera",fondo)

## Notes

- The yard in the window (patio(), nevera.js:105) is clipped to the window: the cart, the birds on the wall and people outside.
- The fridge is drawn by nevera() (nevera.js:115) every frame, after the background: open, half shut or shut (W.nev.abierta).
