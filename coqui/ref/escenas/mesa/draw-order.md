# mesa: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (437 W, 144 states); each call's place is the first frame of its stack in a scene file. historia/escenas/mesa.js draw(): lines 155-189.

**Drawn in order of y:** the items pushed to a list before mesa.js:180 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@mesa.js:157` | prop or effect | mesa.js:157 | fillRect | nothing |
| `@mesa.js:159` | prop or effect | mesa.js:159 | fillRect | nothing |
| `tenida @mesa.js:159 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `@mesa.js:159` (122 of 155); `gente @mesa.js:180 · KIT.mkPersona` (40 of 215); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (54 of 182) |
| `tenida @mesa.js:160 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (159 of 170) |
| `tenida @mesa.js:162 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (2 of 165) |
| `tenida @mesa.js:163 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (86 of 172) |
| `tenida @mesa.js:164 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (32 of 108); `tenida @mesa.js:184 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `conTodo > tenida @mesa.js:165 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `tenida @mesa.js:166 · ()=>(COSA[k]||COSA.plato)(c)` (72 of 90); `gente @mesa.js:180 · KIT.mkPersona` (5 of 85) |
| `tenida @mesa.js:166 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (1 of 81) |
| `tenida @mesa.js:167 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (66 of 105) |
| `@mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:173 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `@mesa.js:180 · mkMesa` | prop or effect | mesa.js:171 | mkMesa | `rana @mesa.js:180 · mkCoqui` (119 of 413); `gente @mesa.js:180 · mkAbuela` (373 of 415); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (336 of 351); `gente @mesa.js:180` (21 of 91); `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (19 of 25); `@mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (always); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (116 of 304); `gente @mesa.js:180 · KIT.mkPersona` (14 of 401); `conTodo @mesa.js:180` (97 of 98); `tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (always); `@mesa.js:180 · mkPerro` (always); `conTodo > tenida @mesa.js:182 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @mesa.js:183 · ()=>(COSA[k]||COSA.plato)(c)` (always); `@mesa.js:183` (always); `nube @mesa.js:186` (always); `nube > conTodo > tenida @mesa.js:186 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `@mesa.js:180 · mkPerro` | character | mesa.js:175 | mkPerro | `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (2 of 83) |
| `conTodo @mesa.js:180` | prop or effect | mesa.js:106, mesa.js:107, mesa.js:108 | fillRect | `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (10 of 98) |
| `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `rana @mesa.js:180 · mkCoqui` (105 of 344); `gente @mesa.js:180 · mkAbuela` (54 of 344); `gente @mesa.js:180 · KIT.mkPersona` (47 of 328); `conTodo @mesa.js:180` (20 of 98); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (31 of 270); `@mesa.js:180 · mkMesa` (108 of 351); `gente @mesa.js:180` (3 of 64); `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (3 of 23); `@mesa.js:180 · mkPerro` (3 of 83); `@mesa.js:183` (always); `nube @mesa.js:186` (10 of 25); `nube > conTodo > tenida @mesa.js:186 · ()=>(COSA[k]||COSA.plato)(c)` (10 of 25) |
| `gente @mesa.js:180` | character | mesa.js:140, mesa.js:148 | fillRect | `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (always); `@mesa.js:180 · mkMesa` (56 of 91); `gente @mesa.js:180 · KIT.mkPersona` (68 of 91); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (59 of 87); `gente @mesa.js:180 · mkAbuela` (54 of 83) |
| `gente @mesa.js:180 · KIT.mkBebe` | character | mesa.js:143 | KIT.mkBebe | `@mesa.js:180 · mkMesa` (always); `gente @mesa.js:180 · mkAbuela` (16 of 161); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (108 of 136); `gente @mesa.js:180 · KIT.mkPersona` (89 of 161); `conTodo @mesa.js:180` (34 of 96); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (4 of 110) |
| `gente @mesa.js:180 · KIT.mkPersona` | character | mesa.js:142 | KIT.mkPersona | `@mesa.js:180 · mkMesa` (391 of 401); `gente @mesa.js:180 · KIT.mkBebe` (always); `gente @mesa.js:180 · mkAbuela` (313 of 387); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (283 of 328); `gente @mesa.js:180` (79 of 91); `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (20 of 25); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (207 of 302); `@mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (always); `rana @mesa.js:180 · mkCoqui` (13 of 387); `conTodo @mesa.js:180` (96 of 97); `tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (always); `conTodo > tenida @mesa.js:182 · ()=>(COSA[k]||COSA.plato)(c)` (always); `tenida @mesa.js:183 · ()=>(COSA[k]||COSA.plato)(c)` (always); `@mesa.js:183` (always); `tenida @mesa.js:184 · ()=>(COSA[k]||COSA.plato)(c)` (3 of 5); `nube @mesa.js:185` (always); `nube @mesa.js:186` (always) |
| `gente @mesa.js:180 · mkAbuela` | character | mesa.js:137 | mkAbuela | `rana @mesa.js:180 · mkCoqui` (24 of 412); `gente @mesa.js:180` (13 of 83); `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (13 of 25); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (108 of 294); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (23 of 344); `@mesa.js:180 · mkPerro` (2 of 83); `conTodo > tenida @mesa.js:182 · ()=>(COSA[k]||COSA.plato)(c)` (always); `nube @mesa.js:186` (8 of 25); `nube > conTodo > tenida @mesa.js:186 · ()=>(COSA[k]||COSA.plato)(c)` (8 of 25) |
| `gente > conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` | character | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `@mesa.js:180 · mkMesa` (6 of 25); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (1 of 23); `nube @mesa.js:186` (always) |
| `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` | character | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · KIT.mkPersona` (172 of 302); `@mesa.js:180 · mkMesa` (188 of 304); `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (98 of 270); `gente @mesa.js:180` (78 of 87); `gente @mesa.js:180 · mkAbuela` (89 of 294); `gente @mesa.js:180 · KIT.mkBebe` (4 of 110); `conTodo @mesa.js:180` (4 of 91) |
| `rana @mesa.js:180 · mkCoqui` | character | mesa.js:152 | mkCoqui | `conTodo > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (33 of 344); `gente > tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` (29 of 292); `gente @mesa.js:180 · mkAbuela` (14 of 412); `conTodo @mesa.js:180` (1 of 97); `conTodo > tenida @mesa.js:182 · ()=>(COSA[k]||COSA.plato)(c)` (always); `nube @mesa.js:186` (always) |
| `tenida @mesa.js:180 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `gente @mesa.js:180 · mkAbuela` (20 of 38) |
| `conTodo > tenida @mesa.js:182 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `@mesa.js:183` | prop or effect | mesa.js:183 | fillRect | nothing |
| `tenida @mesa.js:183 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | `@mesa.js:183` (always) |
| `conTodo > tenida @mesa.js:184 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `tenida @mesa.js:184 · ()=>(COSA[k]||COSA.plato)(c)` | prop or effect | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `nube @mesa.js:185` | character | mesa.js:135 | fillRect | `nube > conTodo > tenida @mesa.js:185 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube > conTodo > tenida @mesa.js:185 · ()=>(COSA[k]||COSA.plato)(c)` | character | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | nothing |
| `nube @mesa.js:186` | character | mesa.js:135 | fillRect | `nube > conTodo > tenida @mesa.js:186 · ()=>(COSA[k]||COSA.plato)(c)` (always) |
| `nube > conTodo > tenida @mesa.js:186 · ()=>(COSA[k]||COSA.plato)(c)` | character | mesa.js:102 | ()=>(COSA[k]||COSA.plato)(c) | nothing |

## Clip regions

None: this scene never calls clip().

## Background

- mesa.js:30 fondo()
- mesa.js:54 mkPuesto()
- mesa.js:156 W.afuera ? spr("puesto",mkPuesto) : spr("cocina",fondo)

## Notes

- W.afuera swaps the whole background for mkPuesto (mesa.js:156) and drops the table (mesa.js:171); set only by cual-mesa (order 05: no story reaches it).
- Things in the air, the pouring jug and what is held up (mesa.js:182-184) are drawn after the sorted list: over everyone.
