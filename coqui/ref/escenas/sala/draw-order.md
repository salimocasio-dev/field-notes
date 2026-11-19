# sala: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (338 W, 27 states); each call's place is the first frame of its stack in a scene file. historia/escenas/sala.js draw(): lines 106-125.

**Drawn in order of y:** the items pushed to a list before sala.js:117 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `marco @sala.js:108` | prop or effect | sala.js:53, sala.js:55, sala.js:58, sala.js:60 | fillRect | `marco @sala.js:108 · KIT.mkPersona` (always); `marco @sala.js:108 · mkCoqui` (always) |
| `marco @sala.js:108 · KIT.mkPersona` | prop or effect | sala.js:57 | KIT.mkPersona | `marco @sala.js:108` (always); `marco @sala.js:108 · mkCoqui` (8 of 24) |
| `marco @sala.js:108 · mkCoqui` | prop or effect | sala.js:56 | mkCoqui | `marco @sala.js:108 · KIT.mkPersona` (always); `marco @sala.js:108` (always) |
| `@sala.js:109 · mkLampara` | prop or effect | sala.js:109 | mkLampara | `@sala.js:110 · mkSofa` (always); `@sala.js:110 · mkButaca` (always); `gente @sala.js:117 · KIT.mkPersona` (323 of 335); `gente @sala.js:117 · mkAbuela` (13 of 320); `gente @sala.js:117 · KIT.mkBebe` (26 of 319); `rana @sala.js:117 · mkCoqui` (3 of 325); `gente > taza @sala.js:117` (7 of 54); `bub2 @sala.js:123` (3 of 4) |
| `@sala.js:110 · mkButaca` | prop or effect | sala.js:110 | mkButaca | `gente @sala.js:117 · KIT.mkPersona` (321 of 335); `rana @sala.js:117 · mkCoqui` (10 of 325); `gente > trozo @sala.js:117 · mkTrozo` (22 of 80); `gente > plato @sala.js:117` (always); `gente @sala.js:117 · mkAbuela` (8 of 320); `gente @sala.js:117 · KIT.mkBebe` (26 of 319); `gente > taza @sala.js:117` (14 of 54); `bub2 @sala.js:123` (always) |
| `@sala.js:110 · mkSofa` | prop or effect | sala.js:110 | mkSofa | `gente @sala.js:117 · KIT.mkPersona` (328 of 335); `gente @sala.js:117 · mkAbuela` (295 of 320); `bizcocho @sala.js:117` (41 of 146); `gente > trozo @sala.js:117 · mkTrozo` (71 of 80); `rana @sala.js:117 · mkCoqui` (26 of 325); `gente > plato @sala.js:117` (always); `gente @sala.js:117 · KIT.mkBebe` (171 of 319); `gente > taza @sala.js:117` (12 of 54); `bub2 @sala.js:123` (3 of 4); `bub2 @sala.js:124` (always) |
| `manta @sala.js:111` | prop or effect | sala.js:49 | fillRect | `gente @sala.js:117 · KIT.mkBebe` (148 of 319); `rana @sala.js:117 · mkCoqui` (277 of 325); `gente > trozo @sala.js:117 · mkTrozo` (67 of 80); `gente @sala.js:117 · KIT.mkPersona` (169 of 335); `gente @sala.js:117 · mkAbuela` (3 of 320) |
| `@sala.js:117` | prop or effect | sala.js:114, sala.js:116 | fillRect | `gente @sala.js:117 · KIT.mkPersona` (3 of 7) |
| `@sala.js:117 · mkMesita` | prop or effect | sala.js:114 | mkMesita | `bizcocho @sala.js:117` (always); `gente @sala.js:117 · mkAbuela` (14 of 320); `gente @sala.js:117 · KIT.mkPersona` (211 of 335); `@sala.js:117` (3 of 7); `rana @sala.js:117 · mkCoqui` (1 of 325) |
| `bizcocho @sala.js:117` | prop or effect | sala.js:67, sala.js:68, sala.js:69, sala.js:70, sala.js:71 | fillRect | `gente @sala.js:117 · KIT.mkPersona` (18 of 146); `gente @sala.js:117 · mkAbuela` (3 of 146); `bub2 @sala.js:124` (always) |
| `gente @sala.js:117` | character | sala.js:89 | fillRect | nothing |
| `gente @sala.js:117 · KIT.mkBebe` | character | sala.js:87 | KIT.mkBebe | `gente > trozo @sala.js:117 · mkTrozo` (67 of 80); `gente @sala.js:117 · KIT.mkPersona` (27 of 318); `gente @sala.js:117 · mkAbuela` (9 of 318); `rana @sala.js:117` (2 of 317); `rana @sala.js:117 · mkCoqui` (2 of 317); `gente > taza @sala.js:117` (7 of 54) |
| `gente @sala.js:117 · KIT.mkPersona` | character | sala.js:91 | KIT.mkPersona | `bizcocho @sala.js:117` (58 of 146); `gente > Z @sala.js:117` (always); `gente > trozo @sala.js:117 · mkTrozo` (71 of 80); `rana @sala.js:117 · mkCoqui` (229 of 325); `gente > plato @sala.js:117` (always); `gente @sala.js:117 · KIT.mkBebe` (206 of 318); `@sala.js:117 · mkMesita` (210 of 335); `gente @sala.js:117 · mkAbuela` (153 of 318); `@sala.js:117` (always); `trozo @sala.js:117 · mkTrozo` (2 of 14); `rana @sala.js:117` (12 of 325); `gente > taza @sala.js:117` (always); `bub2 @sala.js:123` (always); `bub2 @sala.js:124` (always) |
| `gente @sala.js:117 · mkAbuela` | character | sala.js:88 | mkAbuela | `gente @sala.js:117 · KIT.mkBebe` (122 of 318); `gente @sala.js:117` (always); `gente > trozo @sala.js:117 · mkTrozo` (7 of 80); `rana @sala.js:117 · mkCoqui` (15 of 317); `gente @sala.js:117 · KIT.mkPersona` (139 of 318); `@sala.js:117 · mkMesita` (8 of 320); `bizcocho @sala.js:117` (8 of 146) |
| `gente > plato @sala.js:117` | character | sala.js:72 | fillRect | `gente @sala.js:117 · KIT.mkPersona` (always) |
| `gente > taza @sala.js:117` | character | sala.js:98, sala.js:99 | fillRect | `gente @sala.js:117 · mkAbuela` (1 of 54) |
| `gente > trozo @sala.js:117 · mkTrozo` | character | sala.js:65 | mkTrozo | `gente @sala.js:117 · KIT.mkPersona` (48 of 80); `@sala.js:117 · mkMesita` (58 of 80); `bizcocho @sala.js:117` (58 of 80); `gente @sala.js:117 · mkAbuela` (57 of 80); `gente @sala.js:117 · KIT.mkBebe` (58 of 80); `rana @sala.js:117 · mkCoqui` (54 of 80); `trozo @sala.js:117 · mkTrozo` (4 of 10); `rana @sala.js:117` (10 of 80); `gente @sala.js:117` (always) |
| `gente > Z @sala.js:117` | character | sala.js:92 | fillRect | nothing |
| `rana @sala.js:117` | character | sala.js:101 | fillRect | `rana @sala.js:117 · mkCoqui` (always); `@sala.js:117 · mkMesita` (14 of 325); `gente @sala.js:117 · KIT.mkBebe` (1 of 317); `gente @sala.js:117 · mkAbuela` (10 of 317); `gente @sala.js:117 · KIT.mkPersona` (10 of 325) |
| `rana @sala.js:117 · mkCoqui` | character | sala.js:102 | mkCoqui | `@sala.js:117 · mkMesita` (14 of 325); `bizcocho @sala.js:117` (14 of 146); `gente @sala.js:117 · KIT.mkBebe` (1 of 317); `gente @sala.js:117 · mkAbuela` (10 of 317); `gente @sala.js:117 · KIT.mkPersona` (10 of 325); `@sala.js:117` (4 of 7) |
| `trozo @sala.js:117 · mkTrozo` | character | sala.js:65 | mkTrozo | nothing |
| `bub2 @sala.js:123` | character | sala.js:105 | fillRect | nothing |
| `bub2 @sala.js:124` | character | sala.js:105 | fillRect | nothing |

## Clip regions

| at | region (scene picture) | what is drawn inside it | seen in |
|---|---|---|---|
| sala.js:54 `if(f){g.save();g.beginPath();g.rect(-8,2,16,20);g.clip();` | rect [-8,2,16,20] (screen [78,42,16,20]) | `marco @sala.js:108 · KIT.mkPersona`; `marco @sala.js:108 · mkCoqui` | 122 W |

## Background

- sala.js:17 bg()
- sala.js:107 spr("sala",bg)

## Notes

- Everyone, the low table and the frog are sorted by y (sala.js:113-117); the photos, the lamp, the sofa, the armchair and the blanket come before (sala.js:108-111) and so never cover anyone.
- W.borroso blurs the whole picture with smoothing on (sala.js:120-121), reading back the scene canvas (sc) itself; W.flash whitens it (sala.js:122).
