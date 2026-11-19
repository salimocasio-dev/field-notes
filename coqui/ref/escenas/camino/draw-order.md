# camino: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (352 W, 9 states); each call's place is the first frame of its stack in a scene file. historia/escenas/camino.js draw(): lines 94-115.

**Drawn in order of y:** the items pushed to a list before camino.js:107 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@camino.js:96` | prop or effect | camino.js:96 | stroke | `@camino.js:99 · mkPajarito` (always); `@camino.js:100 · mkGato` (always) |
| `@camino.js:99 · mkPajarito` | character | camino.js:99 | mkPajarito | `@camino.js:100 · mkGato` (always); `gente @camino.js:107 · KIT.mkPersona` (64 of 198); `gente @camino.js:107 · mkGato` (5 of 8) |
| `@camino.js:100 · mkGato` | character | camino.js:100 | mkGato | `gente @camino.js:107 · KIT.mkPersona` (9 of 71); `gente @camino.js:107` (3 of 64); `gente @camino.js:107 · mkCesta` (3 of 64); `bub2 @camino.js:113` (always) |
| `@camino.js:107` | prop or effect | camino.js:106 | fillRect | `gente @camino.js:107 · KIT.mkPersona` (always) |
| `@camino.js:107 · mkArbusto` | prop or effect | camino.js:106 | mkArbusto | `gente @camino.js:107 · KIT.mkPersona` (always); `@camino.js:107` (always); `animal @camino.js:107 · mkPerro` (4 of 54); `@camino.js:109` (24 of 63) |
| `@camino.js:107 · mkCaracol` | character | camino.js:105 | mkCaracol | `@camino.js:107 · mkArbusto` (4 of 6); `gente @camino.js:107 · KIT.mkPersona` (2 of 6) |
| `animal @camino.js:107 · mkGato` | character | camino.js:84 | mkGato | `animal @camino.js:107 · mkPerro` (7 of 67) |
| `animal @camino.js:107 · mkPerro` | character | camino.js:84 | mkPerro | `gente @camino.js:107 · KIT.mkPersona` (97 of 320); `rana @camino.js:107` (3 of 320); `rana @camino.js:107 · mkCoqui` (7 of 320); `@camino.js:107 · mkCaracol` (6 of 7); `@camino.js:107 · mkArbusto` (38 of 54); `@camino.js:109` (always) |
| `gente @camino.js:107` | character | camino.js:79, camino.js:80 | fillRect | `gente @camino.js:107 · mkCesta` (always); `gente @camino.js:107 · mkGato` (always) |
| `gente @camino.js:107 · KIT.mkPersona` | character | camino.js:78 | KIT.mkPersona | `animal @camino.js:107 · mkPerro` (240 of 320); `rana @camino.js:107` (93 of 329); `rana @camino.js:107 · mkCoqui` (193 of 329); `gente @camino.js:107` (153 of 154); `gente @camino.js:107 · mkCesta` (153 of 157); `gente @camino.js:107 · mkGato` (always); `@camino.js:109` (166 of 210); `@camino.js:111` (always) |
| `gente @camino.js:107 · mkAbuela` | character | camino.js:76 | mkAbuela | `@camino.js:107 · mkArbusto` (always); `gente @camino.js:107 · KIT.mkPersona` (always); `@camino.js:107` (always); `animal @camino.js:107 · mkPerro` (7 of 54); `gente @camino.js:107 · mkCesta` (always); `gente > guineo @camino.js:107` (always); `rana @camino.js:107 · mkCoqui` (4 of 63); `@camino.js:109` (7 of 63) |
| `gente @camino.js:107 · mkCesta` | character | camino.js:76, camino.js:79 | mkCesta | `rana @camino.js:107 · mkCoqui` (67 of 157); `gente @camino.js:107 · mkGato` (always); `animal @camino.js:107 · mkPerro` (3 of 157); `gente > guineo @camino.js:107` (always); `@camino.js:107 · mkArbusto` (always); `gente @camino.js:107 · KIT.mkPersona` (4 of 157); `@camino.js:109` (4 of 151) |
| `gente @camino.js:107 · mkGato` | character | camino.js:79 | mkGato | `animal @camino.js:107 · mkPerro` (3 of 8) |
| `gente > guineo @camino.js:107` | character | camino.js:55 | fillRect | nothing |
| `rana @camino.js:107` | character | camino.js:87 | fillRect | `rana @camino.js:107 · mkCoqui` (322 of 330); `gente @camino.js:107 · KIT.mkPersona` (149 of 329); `@camino.js:107 · mkArbusto` (3 of 63); `animal @camino.js:107 · mkPerro` (8 of 320); `@camino.js:109` (57 of 210) |
| `rana @camino.js:107 · mkCesta` | character | camino.js:90 | mkCesta | `rana > guineo @camino.js:107` (always) |
| `rana @camino.js:107 · mkCoqui` | character | camino.js:89 | mkCoqui | `gente @camino.js:107 · KIT.mkPersona` (138 of 329); `rana @camino.js:107 · mkCesta` (always); `animal @camino.js:107 · mkPerro` (49 of 320); `rana > guineo @camino.js:107` (2 of 56); `@camino.js:107 · mkArbusto` (15 of 63); `@camino.js:109` (59 of 210); `bub2 @camino.js:113` (always) |
| `rana > galleta @camino.js:107` | character | camino.js:53, camino.js:54 | fillRect | nothing |
| `rana > guineo @camino.js:107` | character | camino.js:55 | fillRect | nothing |
| `@camino.js:109` | character | camino.js:109 | fillRect | nothing |
| `@camino.js:111` | character | camino.js:111 | fillRect | nothing |
| `@camino.js:112 · mkPajarito` | character | camino.js:112 | mkPajarito | nothing |
| `bub2 @camino.js:113` | character | camino.js:93 | fillRect | nothing |

## Clip regions

None: this scene never calls clip().

## Background

- camino.js:21 fondo(gran)
- camino.js:95 spr("camino"+(W.sinGran?0:1), ()=>fondo(!W.sinGran))

## Notes

- Birds in the trees and the cat up a tree are drawn before everyone (camino.js:99-100), so people and the frog cover them.
- The leash is drawn after the sorted list (camino.js:109): over the dog, the frog and whoever holds it.
