# campo: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (385 W, 7 states); each call's place is the first frame of its stack in a scene file. historia/escenas/campo.js draw(): lines 95-111.

**Drawn in order of y:** the items pushed to a list before campo.js:107 are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `@campo.js:97` | prop or effect | campo.js:97 | fillRect | `unaBola @campo.js:107 · mkBola` (9 of 16); `rana @campo.js:107 · mkCoqui` (7 of 16) |
| `@campo.js:98` | prop or effect | campo.js:98 | fillRect | `unaBola @campo.js:107 · mkBola` (always); `unaBola @campo.js:107` (always) |
| `@campo.js:107` | character | campo.js:105, campo.js:106 | fillRect | nothing |
| `@campo.js:107 · mkBola` | prop or effect | campo.js:103 | mkBola | `@campo.js:107 · mkCesta` (always) |
| `@campo.js:107 · mkCesta` | prop or effect | campo.js:103 | mkCesta | nothing |
| `gente @campo.js:107` | character | campo.js:75 | fillRect | nothing |
| `gente @campo.js:107 · KIT.mkPersona` | character | campo.js:74 | KIT.mkPersona | `@campo.js:107 · mkBola` (74 of 255); `rana @campo.js:107` (103 of 366); `rana @campo.js:107 · mkCoqui` (136 of 366); `perro @campo.js:107 · mkPerro` (194 of 362); `unaBola @campo.js:107 · mkBola` (249 of 366); `@campo.js:107 · mkCesta` (60 of 255); `gente @campo.js:107` (always); `gente > gotas @campo.js:107` (always); `perro > gotas @campo.js:107` (6 of 107); `unaBola @campo.js:107` (2 of 83) |
| `gente > gotas @campo.js:107` | character | campo.js:71 | fillRect | `unaBola @campo.js:107 · mkBola` (6 of 63); `perro @campo.js:107 · mkPerro` (6 of 63) |
| `perro @campo.js:107` | character | campo.js:78, campo.js:80 | fillRect | `unaBola @campo.js:107 · mkBola` (1 of 3) |
| `perro @campo.js:107 · mkPerro` | character | campo.js:79 | mkPerro | `@campo.js:107 · mkBola` (35 of 255); `@campo.js:107 · mkCesta` (35 of 255); `gente @campo.js:107 · KIT.mkPersona` (145 of 362); `unaBola @campo.js:107 · mkBola` (162 of 362); `perro > gotas @campo.js:107` (always) |
| `perro > gotas @campo.js:107` | character | campo.js:71 | fillRect | `unaBola @campo.js:107 · mkBola` (47 of 109) |
| `rana @campo.js:107` | character | campo.js:85, campo.js:86 | fillRect | `rana @campo.js:107 · mkCoqui` (358 of 371); `gente @campo.js:107 · KIT.mkPersona` (72 of 366); `perro @campo.js:107 · mkPerro` (30 of 364); `unaBola @campo.js:107 · mkBola` (120 of 362); `rana > gotas @campo.js:107` (29 of 37) |
| `rana @campo.js:107 · mkCoqui` | character | campo.js:87 | mkCoqui | `gente @campo.js:107 · KIT.mkPersona` (52 of 366); `perro @campo.js:107 · mkPerro` (13 of 364); `unaBola @campo.js:107 · mkBola` (119 of 362); `rana > gotas @campo.js:107` (always) |
| `rana > gotas @campo.js:107` | character | campo.js:71 | fillRect | `unaBola @campo.js:107 · mkBola` (7 of 37) |
| `unaBola @campo.js:107` | prop or effect | campo.js:91, campo.js:92, campo.js:94 | fillRect | `gente @campo.js:107 · KIT.mkPersona` (8 of 83); `unaBola @campo.js:107 · mkBola` (41 of 85); `@campo.js:107 · mkBola` (3 of 79) |
| `unaBola @campo.js:107 · mkBola` | prop or effect | campo.js:91, campo.js:93 | mkBola | `@campo.js:107 · mkBola` (64 of 249); `gente @campo.js:107 · KIT.mkPersona` (148 of 366); `@campo.js:107 · mkCesta` (18 of 249); `unaBola @campo.js:107` (37 of 85); `rana @campo.js:107` (114 of 362); `rana @campo.js:107 · mkCoqui` (122 of 362); `perro @campo.js:107 · mkPerro` (73 of 362); `perro > gotas @campo.js:107` (11 of 109); `gente > gotas @campo.js:107` (6 of 63) |

## Clip regions

None: this scene never calls clip().

## Background

- campo.js:20 fondo()
- campo.js:96 spr("campo",fondo)

## Notes

- W.oscuro darkens everything, then draws the frog again on top (campo.js:110): his eyes are shut, all is dark but him.
