# Canvas cases

Made by `coqui/tool/ref/ctx/make.js`. Each case is a 64 x 64 tile; `cases.json` has its calls. `Source` is where in `historia/` its parameters come from.

| # | Kind | What | Source |
| --- | --- | --- | --- |
| 1 | fillRect-whole | a card: dark frame, then the cream fill (KIT.tarjeta(g,6,6,50,30)) | escenas/kit.js:160, escenas/sala.js:132 |
| 2 | fillRect-whole | pixel icons: eight glyphs and two faces, every pixel a 1 x 1 fillRect | engine.js:137, engine.js:138 |
| 3 | fillRect-whole | an answer bubble with three icons and its tail (bubble(c,["ok","heart","up"],32,46,0)) | engine.js:141, juego.js:54 |
| 4 | fillRect-half | three rectangles: half origin, half size, half both | escenas/campo.js:86 |
| 5 | fillRect-half | quarter positions, and one rectangle half outside the tile | synthetic (the order's list) |
| 6 | drawImage-plain | the frog drawn plain on a transparent tile | juego.js:48 |
| 7 | drawImage-plain | abuela, then the frog in front of her, on grass | escenas/balcon.js:124 |
| 8 | drawImage-plain | a card with the frog and a 16 x 22 crop of abuela (nine-argument drawImage, 1:1) | escenas/sala.js:132, escenas/sala.js:57 |
| 9 | drawImage-scale-1.6 | scale(1.6, 1.6) then drawImage, as the bird is drawn | escenas/kit.js:28 |
| 10 | drawImage-scale-1.6 | five-argument drawImage to 1.6 times the size, rounded (22 x 30 to 35 x 48) | escenas/sala.js:65, escenas/patio.js:76 |
| 11 | drawImage-scale-1.6 | a held thing at 1.6: translate, scale, drawImage from its bottom middle | escenas/estufa.js:94 |
| 12 | drawImage-scale-0.86 | scale(.86, .86) then drawImage | escenas/kit.js:28 |
| 13 | drawImage-scale-0.86 | five-argument drawImage to .86 of the size, rounded (32 x 27 to 28 x 23) | escenas/patio.js:76 |
| 14 | drawImage-scale-0.86 | a tree at .86 from its foot, over a second plain tree | escenas/estufa.js:94 |
| 15 | drawImage-scale-stretch | the frog stretched tall (1, 1.3) and crouched flat (1.15, .65) | escenas/campo.js:122, escenas/campo.js:123 |
| 16 | drawImage-flip | abuela facing left: translate, scale(-1, 1), drawImage at -30 | escenas/estufa.js:118 |
| 17 | drawImage-flip | a bush flipped, over the plain one | escenas/camino.js:84 |
| 18 | drawImage-flip | flipped and scaled 1.6: scale(-1.6, 1.6) | escenas/kit.js:28 |
| 19 | drawImage-rotate-0.5 | the bird tipping: translate to the foot, rotate(.5) about the bottom, scale 1.6 | escenas/kit.js:28 |
| 20 | drawImage-rotate-0.5 | the frog pulled off his feet: rotate(-.5) about his middle, drawn from -w/2, -h/2 | escenas/camino.js:89 |
| 21 | drawImage-rotate-0.5 | flipped and rotated: scale(-1, 1), rotate(-.5) | escenas/lago.js:100 |
| 22 | drawImage-smoothing | the frog mid-hop: y = 24 - 7 sin(pi/5) = 19.886, smoothing on (the scene canvas default) | juego.js:156, escenas/banco.js:166 |
| 23 | drawImage-smoothing | half-pixel position, both axes, smoothing on | synthetic (the order's list) |
| 24 | drawImage-smoothing | smoothing on: abuela down to 20 x 18, the frog up by 1.5 (the blur of "borroso") | escenas/sala.js:120, escenas/sala.js:137 |
| 25 | drawImage-smoothing | the frog pulled off his feet, rotate(-.5), smoothing on (same call as the rotate case, other setting) | escenas/camino.js:89 |
| 26 | globalAlpha-0.5 | the frog at globalAlpha .5 over abuela | escenas/banco.js:166 |
| 27 | globalAlpha-0.5 | two overlapping rectangles at globalAlpha .5 | escenas/campo.js:78 |
| 28 | alpha-rgba | the night over the bench: rgba(30,24,90,.32) over everything, a lamp, a rgba(255,240,160,.16) glow ellipse | escenas/banco.js:194 |
| 29 | arc-fill | filled circles of five radii: 2, 4, 6, 9, 12 (arc(x,y,r,0,7)) | escenas/patio.js:158, escenas/patio.js:158, app.html:270, escenas/banco.js:193, escenas/patio.js:142 |
| 30 | arc-fill | the frog's eyes wide open: dark ring r+1, white r, pupil r/2, centres fractional | escenas/patio.js:110, escenas/sala.js:116 |
| 31 | arc-fill | half discs: arc(x, y, r, Math.PI, 0), the beach umbrella of the map icons | app.html:271 |
| 32 | ellipse-fill | filled ellipses of five sizes: 3 x 2, 6 x 3, 11 x 5, 15 x 10, 22 x 4 (radii) | app.html:272, escenas/camino.js:96, escenas/campo.js:86 |
| 33 | ellipse-fill | a round white plate: dark rim, white, grey well (three layers) | escenas/frente.js:104 |
| 34 | ellipse-fill | half ellipses from Math.PI to 0: a lid over the pot | escenas/sala.js:68 |
| 35 | clip-rect | abuela behind a doorway: clip to a rectangle, then drawImage | escenas/balcon.js:124 |
| 36 | clip-rect | the frog peeks from behind a door: clip to a narrow strip, the frog 3 pixels left of it | escenas/frente.js:143 |
| 37 | clip-rotated | a tilted photo frame: rotate(.27), rectangles, then clip to the picture area and draw inside | escenas/sala.js:54, escenas/sala.js:52 |
| 38 | stroke-1 | width 1 on half pixels: a diagonal leash, a horizontal and a vertical line (crisp) | escenas/banco.js:183 |
| 39 | stroke-1 | width 1 on whole pixels: the line straddles two pixel columns (half coverage each) | escenas/banco.js:183 |
| 40 | stroke-2 | width 2: the lit ring round a tree (ellipse stroke) and a whole-pixel line | escenas/camino.js:96 |
