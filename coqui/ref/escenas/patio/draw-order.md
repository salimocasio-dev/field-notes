# patio: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (397 W, 73 states); each call's place is the first frame of its stack in a scene file. historia/escenas/patio.js draw(): lines 128-152.

**Drawn in order of y:** the items pushed to a list before patio.js:140 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@patio.js:130` | prop or effect | patio.js:130 | fillRect | `luna @patio.js:131` (always); `@patio.js:132 · fondo` (always); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (30 of 92) |
| `luna @patio.js:131` | prop or effect | patio.js:57 | fill | `@patio.js:132 · fondo` (always); `@patio.js:148` (always) |
| `sol @patio.js:131` | prop or effect | patio.js:55, patio.js:56 | fillRect | `@patio.js:132 · fondo` (always); `gente @patio.js:140 · KIT.mkPersona` (104 of 383); `gente @patio.js:140 · KIT.mkBebe` (always); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (66 of 96) |
| `@patio.js:140 · mkCaja` | prop or effect | patio.js:136 | mkCaja | `gente @patio.js:140 · KIT.mkPersona` (60 of 139); `rana > cosa @patio.js:140 · mkCosa` (always); `@patio.js:147` (always) |
| `@patio.js:140 · mkSaco` | prop or effect | patio.js:137 | mkSaco | `rana @patio.js:140 · mkCanasta` (62 of 89); `drawAve @patio.js:143 · mkAve` (2 of 89) |
| `cosa @patio.js:140 · mkCosa` | prop or effect | patio.js:76 | mkCosa | `drawAve @patio.js:143 · mkAve` (8 of 174); `@patio.js:144` (1 of 39); `@patio.js:147` (always); `luciernaga @patio.js:149` (1 of 2) |
| `florEn @patio.js:140` | prop or effect | patio.js:79, patio.js:80, patio.js:81 | fillRect | `rana @patio.js:140 · mkCoqui` (110 of 337); `gente @patio.js:140 · KIT.mkPersona` (3 of 337); `rana > cosa @patio.js:140 · mkCosa` (7 of 22); `@patio.js:144` (12 of 42); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (17 of 96) |
| `gente @patio.js:140` | character | patio.js:103 | fillRect | nothing |
| `gente @patio.js:140 · KIT.mkBebe` | character | patio.js:99 | KIT.mkBebe | `gente @patio.js:140 · KIT.mkPersona` (15 of 98); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (56 of 88) |
| `gente @patio.js:140 · KIT.mkPersona` | character | patio.js:102 | KIT.mkPersona | `gente > cosa @patio.js:140 · mkCosa` (always); `gente @patio.js:140 · mkAbuela` (103 of 111); `gente @patio.js:140 · KIT.mkBebe` (always); `cosa @patio.js:140 · mkCosa` (145 of 173); `rana @patio.js:140 · mkCoqui` (189 of 368); `rana @patio.js:140` (86 of 368); `florEn @patio.js:140` (106 of 337); `rana > cosa @patio.js:140 · mkCosa` (always); `@patio.js:140 · mkCaja` (82 of 139); `@patio.js:140 · mkSaco` (always); `rana @patio.js:140 · mkCanasta` (66 of 89); `gente @patio.js:140` (always); `drawAve @patio.js:143 · mkAve` (100 of 379); `drawAve @patio.js:143` (always); `@patio.js:144` (38 of 42); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (87 of 91) |
| `gente @patio.js:140 · mkAbuela` | character | patio.js:100 | mkAbuela | `gente @patio.js:140 · KIT.mkPersona` (15 of 111); `gente > cosa @patio.js:140 · mkCosa` (5 of 55); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (6 of 88) |
| `gente > cosa @patio.js:140 · mkCosa` | character | patio.js:76 | mkCosa | `gente @patio.js:140 · mkAbuela` (50 of 55); `gente @patio.js:140 · KIT.mkPersona` (50 of 83); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (52 of 53) |
| `rana @patio.js:140` | character | patio.js:108, patio.js:110, patio.js:111 | fillRect | `rana @patio.js:140 · mkCoqui` (375 of 378); `gente @patio.js:140 · KIT.mkPersona` (29 of 368); `florEn @patio.js:140` (100 of 337); `rana @patio.js:140 · mkCanasta` (always); `@patio.js:141` (1 of 3); `drawAve @patio.js:143 · mkAve` (2 of 377); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (5 of 93) |
| `rana @patio.js:140 · mkCanasta` | character | patio.js:114 | mkCanasta | `gente @patio.js:140 · KIT.mkPersona` (16 of 89); `gente @patio.js:140` (2 of 58); `@patio.js:140 · mkSaco` (5 of 89) |
| `rana @patio.js:140 · mkCoqui` | character | patio.js:109 | mkCoqui | `gente @patio.js:140 · KIT.mkPersona` (36 of 368); `rana @patio.js:140` (15 of 378); `florEn @patio.js:140` (100 of 337); `rana > cosa @patio.js:140 · mkCosa` (always); `rana @patio.js:140 · mkCanasta` (always); `gente @patio.js:140` (2 of 58); `@patio.js:141` (1 of 3); `drawAve @patio.js:143 · mkAve` (7 of 377); `@patio.js:144` (12 of 42); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (34 of 93) |
| `rana > cosa @patio.js:140 · mkCosa` | character | patio.js:76 | mkCosa | `@patio.js:144` (1 of 3); `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (7 of 8) |
| `@patio.js:141` | character | patio.js:141 | fillRect | nothing |
| `@patio.js:142` | prop or effect | patio.js:142 | stroke | `drawAve @patio.js:143 · mkAve` (always) |
| `drawAve @patio.js:143` | character | kit.js:30 | fillRect | nothing |
| `drawAve @patio.js:143 · mkAve` | character | kit.js:28 | mkAve | `@patio.js:147` (always); `@patio.js:148` (always); `luciernaga @patio.js:149` (64 of 93); `bub2 @patio.js:150` (1 of 5) |
| `drawAve > Z @patio.js:143` | character | kit.js:29 | fillRect | `@patio.js:148` (always) |
| `@patio.js:144` | character | patio.js:144 | fillRect | `@patio.js:147` (always); `luciernaga @patio.js:149` (1 of 3) |
| `@patio.js:147` | prop or effect | patio.js:147 | fillRect | `@patio.js:148` (always); `luciernaga @patio.js:149` (always) |
| `@patio.js:148` | prop or effect | patio.js:148 | fillRect | `luciernaga @patio.js:149` (always) |
| `luciernaga @patio.js:149` | character | patio.js:125, patio.js:126 | fillRect | nothing |
| `bub2 @patio.js:150` | character | patio.js:116 | fillRect | nothing |

## Clip regions

None: this scene never calls clip().

## Background

- patio.js:23 fondo(pt,pd)
- patio.js:129 spr("cielo"+n, ()=>cielo(n)) with n = W.noche?4:Math.min(3,W.sol||0) (patio.js:128)
- patio.js:132 spr("patio"+(W.porton?1:0)+(W.pdoor?1:0), ()=>fondo(W.porton,W.pdoor))

## Notes

- The sky (cielo) is a separate background sprite, then the sun or moon, then fondo (the yard) over it (patio.js:129-132): the sun sets behind the wall.
- The light of the hour and W.osc lay a colour over everything (patio.js:147-148); the fireflies are drawn after that, so they glow (patio.js:149).
