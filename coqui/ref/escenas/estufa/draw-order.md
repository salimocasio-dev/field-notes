# estufa: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (387 W, 164 states); each call's place is the first frame of its stack in a scene file. historia/escenas/estufa.js draw(): lines 132-166.

**Drawn in order of y:** the items pushed to a list before estufa.js:158 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@estufa.js:134 · KIT.mkPersona` | character | estufa.js:134 | KIT.mkPersona | `tenida @estufa.js:134 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `tenida @estufa.js:134 · ()=>(COSA[k]||COSA.plato)(c)` | character | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `@estufa.js:134 · KIT.mkPersona` (always) |
| `tenida @estufa.js:135 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `fuego > llama @estufa.js:136` | prop or effect | estufa.js:96 | fillRect | `fuego > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` (197 of 342); `@estufa.js:138` (always); `gente @estufa.js:158 · mkAbuela` (242 of 334); `gente @estufa.js:158 · KIT.mkPersona` (5 of 320); `gente > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 60) |
| `fuego > pieza > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `fuego > vapor @estufa.js:136` (5 of 20); `@estufa.js:138` (always); `gente @estufa.js:158 · KIT.mkPersona` (3 of 44); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (5 of 11) |
| `fuego > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `fuego > vapor @estufa.js:136` (203 of 238); `fuego > llama @estufa.js:136` (always); `fuego > pieza > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` (always); `@estufa.js:138` (always); `gente @estufa.js:158 · KIT.mkPersona` (5 of 348); `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 361); `gente > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 67); `tenida @estufa.js:161 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (6 of 15) |
| `fuego > vapor @estufa.js:136` | prop or effect | estufa.js:97 | fillRect | `fuego > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` (53 of 238); `fuego > pieza > tenida @estufa.js:136 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 20); `@estufa.js:138` (always); `gente @estufa.js:158 · KIT.mkPersona` (5 of 235); `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 230) |
| `@estufa.js:138` | prop or effect | estufa.js:138 | fillRect | `gente @estufa.js:158 · KIT.mkPersona` (always) |
| `tenida @estufa.js:141 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:142 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `nube2 @estufa.js:163` (3 of 11) |
| `tenida @estufa.js:143 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` (always); `pieza > tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` (33 of 36) |
| `pieza > tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` (23 of 49) |
| `tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `pieza > tenida @estufa.js:144 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `tenida @estufa.js:145 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:147 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:148 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:150 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `gente @estufa.js:158 · KIT.mkBebe` | character | estufa.js:122 | KIT.mkBebe | `gente @estufa.js:158 · KIT.mkPersona` (4 of 94) |
| `gente @estufa.js:158 · KIT.mkPersona` | character | estufa.js:121 | KIT.mkPersona | `rana @estufa.js:158 · mkCoqui` (136 of 344); `gente > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (67 of 70); `gente @estufa.js:158 · mkAbuela` (1 of 346); `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (101 of 345); `rana > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 10); `gente @estufa.js:158 · KIT.mkBebe` (always); `tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (19 of 22); `pieza > tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (14 of 16); `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (78 of 92); `pieza > tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (5 of 8); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (always); `nube @estufa.js:163` (always); `nube > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` (55 of 59); `nube2 @estufa.js:163` (8 of 11); `nube2 > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` (8 of 11) |
| `gente @estufa.js:158 · mkAbuela` | character | estufa.js:118 | mkAbuela | `gente > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (19 of 69); `gente @estufa.js:158 · KIT.mkPersona` (130 of 346); `rana @estufa.js:158 · mkCoqui` (68 of 362); `gente @estufa.js:158 · KIT.mkBebe` (61 of 94); `tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (always); `pieza > tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 15); `nube2 @estufa.js:163` (3 of 11) |
| `gente > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` | character | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `gente @estufa.js:158 · mkAbuela` (1 of 69); `rana @estufa.js:158 · mkCoqui` (5 of 64); `gente @estufa.js:158 · KIT.mkPersona` (36 of 70); `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (4 of 64); `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (always); `pieza > tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `rana @estufa.js:158 · mkCoqui` | character | estufa.js:129 | mkCoqui | `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (345 of 365); `gente @estufa.js:158 · KIT.mkPersona` (94 of 344); `rana > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (always); `pieza > tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (6 of 16); `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (3 of 112); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 17) |
| `rana > tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` | character | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:158 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `rana @estufa.js:158 · mkCoqui` (4 of 365); `gente @estufa.js:158 · KIT.mkPersona` (85 of 345); `gente @estufa.js:158 · KIT.mkBebe` (7 of 94); `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (3 of 112); `pieza > tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (3 of 10) |
| `vapor @estufa.js:158` | prop or effect | estufa.js:97 | fillRect | nothing |
| `pieza > tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `pieza > tenida @estufa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 4) |
| `pieza > tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 10); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `pieza > tenida @estufa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` (4 of 17) |
| `tenida @estufa.js:161 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @estufa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `nube @estufa.js:163` | character | estufa.js:127 | fillRect | `nube > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` | character | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | `nube @estufa.js:163` (43 of 59) |
| `nube2 @estufa.js:163` | character | estufa.js:126 | fillRect | `nube2 > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube2 > tenida @estufa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` | character | estufa.js:94 | ()=>(COSA[k]||COSA.plato)(c) | nothing |

## Clip regions

| at | region (scene picture) | what is drawn inside it | seen in |
|---|---|---|---|
| estufa.js:134 `if(W.ventana&&W.ventana.length){c.save();c.beginPath();c.rect(176,22,38,36);c.clip();W.ven` | rect [176,22,38,36] | `@estufa.js:134 · KIT.mkPersona`; `tenida @estufa.js:134 · ()=>(COSA[k]||COSA.plato)(c)` | 5 W |

## Background

- estufa.js:26 fondo()
- estufa.js:133 spr("estufa",fondo)

## Notes

- People seen through the window are clipped to it (estufa.js:134) and drawn before the counters.
