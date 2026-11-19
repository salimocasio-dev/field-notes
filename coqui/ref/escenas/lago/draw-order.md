# lago: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (597 W, 10 states); each call's place is the first frame of its stack in a scene file. historia/escenas/lago.js draw(): lines 111-131.

**Drawn in order of y:** the items pushed to a list before lago.js:127 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@lago.js:113` | prop or effect | lago.js:113 | fillRect | `@lago.js:127 · mkJunco` (always) |
| `@lago.js:127` | prop or effect | lago.js:123 | fillRect | `gente @lago.js:127 · KIT.mkPersona` (always); `bote @lago.js:127 · mkBote` (145 of 227) |
| `@lago.js:127 · mkBolsa` | prop or effect | lago.js:122 | mkBolsa | `gente @lago.js:127 · KIT.mkPersona` (always); `pato @lago.js:127 · mkPato` (1 of 111) |
| `@lago.js:127 · mkJunco` | prop or effect | lago.js:116 | mkJunco | `pato @lago.js:127 · mkPato` (91 of 355); `bote @lago.js:127 · mkBote` (124 of 280); `pato @lago.js:127` (7 of 297) |
| `@lago.js:127 · mkPan` | prop or effect | lago.js:121, lago.js:126 | mkPan | `@lago.js:128` (2 of 13) |
| `@lago.js:127 · mkPerro` | character | lago.js:124 | mkPerro | nothing |
| `ave @lago.js:127 · mkPajaro` | character | lago.js:102 | mkPajaro | `ave @lago.js:127 · mkPan` (always) |
| `ave @lago.js:127 · mkPan` | character | lago.js:103 | mkPan | nothing |
| `bote @lago.js:127` | prop or effect | lago.js:105 | fillRect | `bote @lago.js:127 · mkBote` (95 of 163); `gente @lago.js:127 · KIT.mkPersona` (3 of 161); `@lago.js:127 · mkJunco` (1 of 163); `@lago.js:128` (24 of 42) |
| `bote @lago.js:127 · mkBote` | prop or effect | lago.js:105 | mkBote | `bote @lago.js:127` (always); `gente @lago.js:127 · KIT.mkPersona` (213 of 276); `rana @lago.js:127 · mkCoqui` (211 of 276); `@lago.js:127` (211 of 227); `gente @lago.js:127 · mkBote` (49 of 61); `@lago.js:127 · mkJunco` (124 of 280); `@lago.js:128` (26 of 50) |
| `gente @lago.js:127 · KIT.mkPersona` | character | lago.js:91 | KIT.mkPersona | `@lago.js:127 · mkPerro` (always); `rana @lago.js:127 · mkCoqui` (111 of 575); `@lago.js:127 · mkBolsa` (always); `pato @lago.js:127 · mkPato` (47 of 348); `rana @lago.js:127 · mkPan` (35 of 58); `ave @lago.js:127 · mkPajaro` (70 of 301); `ave @lago.js:127 · mkPan` (4 of 10); `@lago.js:127 · mkJunco` (227 of 575); `@lago.js:127` (always); `bote @lago.js:127 · mkBote` (223 of 276); `bote @lago.js:127` (5 of 161); `gente @lago.js:127 · mkBote` (always); `pez @lago.js:127 · mkPez` (25 of 313); `pez @lago.js:127` (25 of 313); `gente @lago.js:127 · mkBolsa` (always); `gente @lago.js:127 · mkPan` (always) |
| `gente @lago.js:127 · mkBolsa` | character | lago.js:92 | mkBolsa | nothing |
| `gente @lago.js:127 · mkBote` | character | lago.js:94 | mkBote | nothing |
| `gente @lago.js:127 · mkPan` | character | lago.js:93 | mkPan | `gente @lago.js:127 · KIT.mkPersona` (always) |
| `pato @lago.js:127` | character | lago.js:98 | fillRect | `pato @lago.js:127 · mkPato` (161 of 297); `@lago.js:128` (3 of 11) |
| `pato @lago.js:127 · mkPato` | character | lago.js:97 | mkPato | `pato @lago.js:127` (164 of 297); `ave @lago.js:127 · mkPajaro` (1 of 301); `@lago.js:128` (3 of 19) |
| `pez @lago.js:127` | character | lago.js:101 | fillRect | `pato @lago.js:127 · mkPato` (15 of 211); `pato @lago.js:127` (20 of 156); `gente @lago.js:127 · KIT.mkPersona` (18 of 313); `gente @lago.js:127 · mkBote` (5 of 35); `@lago.js:127 · mkJunco` (6 of 316); `bote @lago.js:127 · mkBote` (3 of 135); `@lago.js:127 · mkPan` (1 of 71); `@lago.js:128` (29 of 35) |
| `pez @lago.js:127 · mkPez` | character | lago.js:100 | mkPez | `pez @lago.js:127` (always); `pato @lago.js:127 · mkPato` (13 of 211); `pato @lago.js:127` (14 of 156); `gente @lago.js:127 · KIT.mkPersona` (18 of 313); `gente @lago.js:127 · mkBote` (5 of 35); `@lago.js:127 · mkJunco` (6 of 317); `bote @lago.js:127 · mkBote` (3 of 135); `@lago.js:127 · mkPan` (1 of 71); `@lago.js:128` (28 of 35) |
| `rana @lago.js:127 · mkCoqui` | character | lago.js:107 | mkCoqui | `@lago.js:127 · mkBolsa` (91 of 111); `gente @lago.js:127 · KIT.mkPersona` (91 of 575); `rana @lago.js:127 · mkPan` (always); `ave @lago.js:127 · mkPajaro` (69 of 301); `pato @lago.js:127 · mkPato` (68 of 348); `bote @lago.js:127 · mkBote` (219 of 276) |
| `rana @lago.js:127 · mkPan` | character | lago.js:108 | mkPan | `ave @lago.js:127 · mkPajaro` (14 of 46) |
| `@lago.js:128` | prop or effect | lago.js:128 | fillRect | nothing |

## Clip regions

None: this scene never calls clip().

## Background

- lago.js:23 fondo()
- lago.js:112 spr("lago",fondo)

## Notes

- anima() (lago.js:81) runs at the start of every draw and moves ducks, fish and birds: some positions are animated by draw() itself, not by an act.
- The reeds (JUNCOS) are in the sorted list (lago.js:116): they cover what stands behind them.
