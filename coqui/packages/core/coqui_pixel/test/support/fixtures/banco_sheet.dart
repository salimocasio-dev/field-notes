// Made by tool/make_sheet_fixture.dart from docs/proyecto/pixel/banco-sheet.json. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// El banco's sheet (order 36a), the text of the file, for the tests that run in a browser.
const String bancoSheetJson = r'''{
 "scene": "banco",
 "made": "node docs/proyecto/pixel/banco-sheet-make.js, from banco-set.html (window.BANCO_SET) and coqui/ref/escenas/banco/. Order 36a.",
 "S": 26,
 "origin": {
  "originX": 0,
  "originY": 4
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin (El camino's, El campo's and El lago's); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the corner is built round the old picture: a place keeps its screen place and its world point is the ground under it (the paving or the lawn, z 0): a frog place q under (q.x + 16, q.y + 25); a person's, a dog's, a pigeon's on the ground, the pushchair's or a thing's place (x, y) under (x, y - 1). Whoever sits (sent) is on a seat: their world point the seat under their lap (x, y - 11, z 0.42), their feet at SY(x) (moves). A thing on a seat, under (x, y - 1) at the seat's height; a pigeon on a bench's back, on its top; on the wire, on the wire (points.cable). So every position of banco.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each (spots, remap, code)",
  "relative": "what the old code draws or moves relative to a person, the frog, a dog, a pigeon or the pushchair (what is carried, a frog place by whoever he serves, a toy thrown from the pushchair, the bubbles) keeps its offsets: a sitter's moved feet move what is relative to them",
  "sky": "screen-space effects keep their old numbers: the stars of the endings, the heart (heartAt)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were"
 },
 "layout": {
  "what": "the paved corner of the park on the world's axes at the engine's 30 degrees: the paving (flags along x and y) from the benches to the picture's lower edge, its far edge stepped along the axes behind the benches; the lawn beyond it with El camino's three trees and the pole; the three benches each along x, stepped so that each one's seat edge passes its old point; the cart along y at the left; the lamp post behind the benches; the wire from the pole to the lamp post and on; the hedge along y across the lower right corner with the gate in it, the paving running out through it; El camino's hills and day sky, by the hour",
  "why": "the brief and page 11 decision 9: the set stands on the world's axes, nothing square to the camera. The old benches stood in one level row facing us, the old paving began on one level row and the old hedge ran down the right edge: none of these lies on a world axis. Each bench lies along x (its seat and back facing +y, the lit side, towards the camera), its middle at the old BANCOS; a seat along x falls half a row a px, so whoever sits keeps the old x and sits on its edge (moves: SY), with the back behind them. The paving's far edge runs behind each bench along x (hidden by it) and steps along y between them, so that behind every head on a bench is the lawn as in the old picture (the old paving began behind the backs), and the trees stand on the lawn. Left of the first bench the edge turns along y, so the cart and its way out (it rolls along +y) are on the paving. The hedge lies along y across the lower right corner, the gate in it where the old gate was, so that whoever leaves (to x 246 on the old gate's rows) walks out through its opening",
  "edge": "a look candidate (banco-set.html ?edge=straight): the paving's far edge one straight line along y, from the left edge up to the right: it reaches the horizon right of the middle, so the paving runs to the hills behind the third bench and the lamp post; kept recoverable, not built on"
 },
 "behind": {
  "what": "nothing: the sun, the moon and the clouds are baked into the set's sky",
  "items": []
 },
 "setKey": {
  "params": {
   "luz": "W.noche ? \"noche\" : W.tarde ? \"tarde\" : \"dia\"",
   "luna": "W.noche && W.luna ? 1 : 0",
   "carro": "W.carroX != null || W.carro === 0 ? \"no\" : W.carro === \"cerrado\" ? \"cerrado\" : \"abierto\""
  },
  "key": "luz + \".\" + luna + \".\" + carro",
  "baked": [
   {
    "key": "dia.0.abierto",
    "query": "?luz=dia&luna=0&carro=abierto"
   },
   {
    "key": "dia.0.no",
    "query": "?luz=dia&luna=0&carro=no"
   },
   {
    "key": "tarde.0.abierto",
    "query": "?luz=tarde&luna=0&carro=abierto"
   },
   {
    "key": "noche.0.abierto",
    "query": "?luz=noche&luna=0&carro=abierto"
   },
   {
    "key": "noche.0.cerrado",
    "query": "?luz=noche&luna=0&carro=cerrado"
   },
   {
    "key": "noche.0.no",
    "query": "?luz=noche&luna=0&carro=no"
   },
   {
    "key": "noche.1.abierto",
    "query": "?luz=noche&luna=1&carro=abierto"
   }
  ],
  "notReached": ["dia.0.cerrado", "tarde.0.cerrado", "tarde.0.no", "noche.1.cerrado", "noche.1.no"],
  "bakedWhy": "order 06 found 49 states made by eleven keys. Three are the set's: tarde and noche (the light of the hour: the evening's warm light and sky, the night's light, sky and lit lamp; noche always comes with tarde), luna (the moon in the night sky) and carro with carroX (the cart open, closed or gone; rolling, it is the sprite layer's and the set has none). The other seven are things the sprite layer draws, as the old: bandeja (the tray over the frog), coche (the pushchair, which moves), encaja (what is in the box), encima (what the frog carries on his head), manos (what he holds), seva (the cart and the dogs going home: it moves them in draw()). So setKey reads luz, luna and carro; every other key is the sprite layer's",
  "spriteKeys": {
   "bandeja": "rana(): the tray over the frog",
   "coche": "coche(): the pushchair (a moving thing: W.coche.x, y)",
   "encaja": "draw(): what lies in the box (W.cosas caja)",
   "encima": "rana(): what he carries on his head",
   "manos": "rana(): what he holds",
   "seva": "draw(): moves the cart, the piragua man and the dogs (the rolling cart: carro.rolling)",
   "carroX": "the rolling cart's place (carro.rolling); a set key only as \"rolling or not\" (carro no)"
  }
 },
 "light": {
  "tarde": "the evening (W.tarde): the set under a warm light (set-kit.js lightPass m .9 .9 .9, a 25.5 15 6: the old page's own evening tint, rgba(255, 150, 60, .10), the blades keep their lit colours, El frente's dusk), the evening sky, the sun where it is by day (the old evening kept its sun), the lantern lit with a faint pool of light; the sun still casts the shadows",
  "noche": "the night (W.noche): the set under El patio's night light (m .56 .62 .82, a 6 10 30; every blade in its shade colour), El patio's night sky, no sun, the moon when W.luna, the lantern lit (its glass keeps its colour) and its pool of light on the ground round the lamp post's foot; nothing casts a shadow (the one rule: the sun casts every shadow, and at night there is none; the set bakes none and the engine casts none for anyone)",
  "sprites": "not darkened, as the old page: banco.js draw() laid the night's colour (rgba(30, 24, 90, .32)) and the evening's (rgba(255, 150, 60, .10)) over its background only, before the sorted list; every person, animal and thing was drawn after it in its own colours. The port draws the sprite layer as by day at every hour (dropped)",
  "shadows": "day and evening: the sun's (upper left), cast to screen right, for the set and for everyone (shadows); night: none"
 },
 "patch": {
  "old": "banco.js:194: at night the old page copied a 46 x 38 patch of its own background from (84, 6) to (196, 6), before the night colour",
  "what": "it hid the sun: the old sun was baked into the background at (210, 17) (engine.js sky(): W - 30, radius 8), and the patch laid a piece of the sky (with the cloud at 112, 9) over it, so that the night sky had no sun",
  "kept": "by the set: the night sky (setKey luz noche) is drawn without a sun (and with the moon when W.luna). The port copies nothing: there is no snapshot of the picture in El banco (Ctx.snapshot is not called)"
 },
 "carro": {
  "standing": "the set's: setKey carro abierto (its umbrella open) or cerrado (furled); banco.js draws nothing for it; its box things.carro.box; whoever stands behind it (the piragua man) has its pixels drawn over them (front)",
  "rolling": "while W.carroX is set the set is baked with no cart (setKey carro no) and the sprite layer draws the cart: the pixels the set's part \"carro\" has in the baked state with the same luz and luna and carro cerrado (each pixel's colour and depth: the same cart, pixel for pixel), moved by dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2) (along +y: the cart rolls on its wheels' line), drawn in the sorted list at y CARRO[1] + (CARRO[0] - W.carroX) / 2 (moves). It rolls only at night: no shadow. Its touch box moves with it (things.carro.rolling)",
  "sprite": {
   "from": "state <luz>.<luna>.cerrado, part carro",
   "at": "dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2)"
  }
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (banco.js:126): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "carmen": {
   "sprite": true,
   "why": "as luis"
  },
  "abuela": {
   "sprite": true,
   "why": "as luis"
  },
  "hombre": {
   "sprite": true,
   "why": "as luis"
  },
  "mujer": {
   "sprite": true,
   "why": "as luis"
  },
  "senor": {
   "sprite": true,
   "why": "as luis"
  },
  "joven": {
   "sprite": true,
   "why": "as luis"
  },
  "senora": {
   "sprite": true,
   "why": "as luis"
  },
  "piraguero": {
   "sprite": true,
   "why": "as luis"
  },
  "perro_viejo": {
   "sprite": true,
   "why": "a dog (mkCan): [x - 15, y - 22, 30, 24] (banco.js:128): unchanged"
  },
  "perro_joven": {
   "sprite": true,
   "why": "as perro_viejo"
  },
  "perro": {
   "sprite": true,
   "why": "as perro_viejo (Canelo)"
  },
  "coche": {
   "sprite": true,
   "why": "the pushchair (mkCoche): [x - 19, y - 42, 38, 44]: unchanged"
  },
  "pajaro": {
   "sprite": true,
   "why": "the pigeons (mkPaloma): the box round every one shown: unchanged"
  },
  "carro": {
   "set": true,
   "world": [0.8159, 4.7322, 0, 1.9581, 5.8744, 3.1088],
   "box": [27, 93, 43, 91],
   "screen": [27, 93, 69, 184],
   "what": "the cart: its box, wheels, umbrella (open or closed), the bottles and the glass case",
   "old": {
    "box": [23, 106, 48, 74]
   },
   "rolling": "while it rolls (W.carroX) its box moves with it: [box x + R(W.carroX) - CARRO[0], box y + R((CARRO[0] - W.carroX) / 2), w, h]",
   "hand": [49, 139]
  },
  "farol": {
   "set": true,
   "world": [2.774, -0.1632, 0, 3.1004, 0.1632, 4.6188],
   "box": [168, 31, 12, 111],
   "screen": [168, 32, 180, 142],
   "what": "the lamp post: its foot, its post, its lantern",
   "old": {
    "box": [161, 34, 14, 126]
   },
   "hand": [174, 100],
   "handWhy": "on the post, under the wire"
  },
  "banco0": {
   "set": true,
   "world": [1.4006, 2.4613, 0, 2.5157, 3.5763, 0.9993],
   "box": [80, 125, 41, 43],
   "screen": [80, 125, 121, 168],
   "what": "the first bench: seat, back, legs",
   "old": {
    "box": [74, 127, 44, 36]
   },
   "hand": [101, 147]
  },
  "banco1": {
   "set": true,
   "world": [2.706, 1.1558, 0, 3.8211, 2.2709, 0.9993],
   "box": [128, 124, 41, 44],
   "screen": [128, 125, 169, 168],
   "what": "the second bench",
   "old": {
    "box": [122, 127, 44, 36]
   },
   "hand": [149, 146]
  },
  "banco2": {
   "set": true,
   "world": [3.8891, 0.0272, 0, 4.705, 0.8431, 1.0215],
   "box": [176, 124, 30, 39],
   "screen": [176, 125, 206, 163],
   "what": "the third bench",
   "old": {
    "box": [170, 127, 44, 36]
   },
   "hand": [191, 144]
  },
  "parque": {
   "set": true,
   "ground": true,
   "box": [0, 40, 240, 176],
   "what": "the park: the paving, the lawn, the trees, the hedge and its gate, the pole and the wire; last in the hit order",
   "old": {
    "box": [0, 60, 240, 156]
   },
   "hintBox": [36, 40, 168, 162],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [120, 186],
   "handWhy": "on the open paving before the benches"
  }
 },
 "spots": {
  "frog.inicio": {
   "world": [1.0879, 5.7656, 0],
   "on": "pave",
   "old": [18, 150],
   "new": [18, 150],
   "scale": 1,
   "what": "LUGAR.inicio: the frog's place q (his feet at q.x + 16, q.y + 25)"
  },
  "frog.centro": {
   "world": [5.0585, 5.0585, 0],
   "on": "pave",
   "old": [104, 180],
   "new": [104, 180],
   "scale": 1,
   "what": "LUGAR.centro: the frog's place q (his feet at q.x + 16, q.y + 25)"
  },
  "sitio.0": {
   "world": [1.9286, 3.234, 0.42],
   "on": "seat",
   "old": [96, 161],
   "new": [96, 161],
   "moved": true,
   "what": "BANCOS[0]: whoever sits at the middle of bench 0 (their feet; SY gives every other x)"
  },
  "sitio.1": {
   "world": [3.234, 1.9286, 0.42],
   "on": "seat",
   "old": [144, 161],
   "new": [144, 161],
   "moved": true,
   "what": "BANCOS[1]: whoever sits at the middle of bench 1 (their feet; SY gives every other x)"
  },
  "sitio.2": {
   "world": [4.5395, 0.6232, 0.42],
   "on": "seat",
   "old": [192, 161],
   "new": [192, 161],
   "moved": true,
   "what": "BANCOS[2]: whoever sits at the middle of bench 2 (their feet; SY gives every other x)"
  },
  "carro": {
   "world": [1.251, 5.82, 0],
   "on": "pave",
   "old": [47, 178],
   "new": [36, 178],
   "moved": true,
   "what": "CARRO: the cart standing (its place in the sorted list; the set's cart is built round it, points.carro); the rolling cart starts here (W.carroX = CARRO[0])"
  },
  "piraguero": {
   "world": [1.0335, 5.3849, 0],
   "on": "pave",
   "old": [51, 172],
   "new": [40, 172],
   "moved": true,
   "what": "CARRO + (4, -6): the piragua man, behind his cart"
  },
  "porton": {
   "world": [7.0439, 2.7468, 0],
   "on": "pave",
   "old": [188, 197],
   "new": [199, 203],
   "moved": true,
   "what": "PORTON: where one stands at the gate, in its opening (moves)"
  },
  "porton.fuera": {
   "world": [8.9748, 2.1213, 0],
   "on": "out",
   "old": [246, 197],
   "new": [246, 215],
   "moved": true,
   "what": "where whoever leaves goes, out through the gate along the path and off the picture (moves)"
  },
  "cable.0": {
   "world": [-0.0239, 2.9133, 3.711],
   "on": "wire",
   "old": [66, 55],
   "new": [66, 55],
   "what": "CABLE(0): a pigeon on the wire (its feet on it): the wire hangs where the old one was"
  },
  "cable.1": {
   "world": [0.4507, 2.4633, 3.6767],
   "on": "wire",
   "old": [83, 56],
   "new": [83, 56],
   "what": "CABLE(1): a pigeon on the wire (its feet on it): the wire hangs where the old one was"
  },
  "cable.2": {
   "world": [0.9254, 2.0133, 3.6423],
   "on": "wire",
   "old": [100, 57],
   "new": [100, 57],
   "what": "CABLE(2): a pigeon on the wire (its feet on it): the wire hangs where the old one was"
  },
  "cable.3": {
   "world": [1.4001, 1.5632, 3.6524],
   "on": "wire",
   "old": [117, 57],
   "new": [117, 57],
   "what": "CABLE(3): a pigeon on the wire (its feet on it): the wire hangs where the old one was"
  },
  "cable.4": {
   "world": [1.8747, 1.1132, 3.6625],
   "on": "wire",
   "old": [134, 57],
   "new": [134, 57],
   "what": "CABLE(4): a pigeon on the wire (its feet on it): the wire hangs where the old one was"
  },
  "respaldo.0": {
   "world": [2.2827, 2.8266, 1.02],
   "on": "back",
   "old": [110, 127],
   "new": [110, 137],
   "moved": true,
   "what": "POSA[0]: a pigeon on a bench's back (moves)"
  },
  "respaldo.1": {
   "world": [3.5881, 1.5212, 1.02],
   "on": "back",
   "old": [158, 127],
   "new": [158, 137],
   "moved": true,
   "what": "POSA[1]: a pigeon on a bench's back (moves)"
  },
  "respaldo.2": {
   "world": [3.9145, 0.2158, 1.02],
   "on": "back",
   "old": [176, 127],
   "new": [188, 128],
   "moved": true,
   "what": "POSA[2]: a pigeon on a bench's back (moves)"
  },
  "respaldo.3": {
   "world": [4.4312, 0.243, 1.02],
   "on": "back",
   "old": [208, 127],
   "new": [197, 133],
   "moved": true,
   "what": "POSA[3]: a pigeon on a bench's back (moves)"
  }
 },
 "lugar": {
  "inicio": {
   "spot": "frog.inicio",
   "q": [18, 150],
   "scale": 1,
   "old": [18, 150]
  },
  "centro": {
   "spot": "frog.centro",
   "q": [104, 180],
   "scale": 1,
   "old": [104, 180]
  }
 },
 "hops": [],
 "hopsAll": [
  {
   "a": [104, 180],
   "b": [88, 181],
   "a2": [104, 180],
   "b2": [88, 181],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 16.03,
   "dNew": 16.03
  },
  {
   "a": [88, 181],
   "b": [62, 173],
   "a2": [88, 181],
   "b2": [62, 173],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 27.2,
   "dNew": 27.2
  },
  {
   "a": [62, 173],
   "b": [88, 181],
   "a2": [62, 173],
   "b2": [88, 181],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 27.2,
   "dNew": 27.2
  },
  {
   "a": [104, 180],
   "b": [28, 183],
   "a2": [104, 180],
   "b2": [28, 183],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 2,
   "new": 2,
   "dOld": 76.06,
   "dNew": 76.06
  },
  {
   "a": [104, 180],
   "b": [140, 180],
   "a2": [104, 180],
   "b2": [140, 180],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 36,
   "dNew": 36
  },
  {
   "a": [140, 180],
   "b": [216, 177],
   "a2": [140, 180],
   "b2": [216, 177],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 2,
   "new": 2,
   "dOld": 76.06,
   "dNew": 76.06
  },
  {
   "a": [104, 180],
   "b": [118, 179],
   "a2": [104, 180],
   "b2": [118, 179],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 14.04,
   "dNew": 14.04
  },
  {
   "a": [104, 180],
   "b": [108, 179],
   "a2": [104, 180],
   "b2": [108, 179],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 4.12,
   "dNew": 4.12
  },
  {
   "a": [108, 179],
   "b": [71, 156],
   "a2": [108, 179],
   "b2": [71, 152],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 43.57,
   "dNew": 45.8
  },
  {
   "a": [71, 156],
   "b": [108, 179],
   "a2": [71, 152],
   "b2": [108, 179],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 43.57,
   "dNew": 45.8
  },
  {
   "a": [108, 179],
   "b": [119, 156],
   "a2": [108, 179],
   "b2": [119, 152],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 25.5,
   "dNew": 29.15
  },
  {
   "a": [119, 156],
   "b": [108, 179],
   "a2": [119, 152],
   "b2": [108, 179],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 25.5,
   "dNew": 29.15
  },
  {
   "a": [104, 180],
   "b": [108, 178],
   "a2": [104, 180],
   "b2": [118, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 4.47,
   "dNew": 14.14
  },
  {
   "a": [108, 178],
   "b": [119, 156],
   "a2": [118, 178],
   "b2": [119, 152],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 24.6,
   "dNew": 26.02
  },
  {
   "a": [119, 156],
   "b": [108, 178],
   "a2": [119, 152],
   "b2": [118, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 24.6,
   "dNew": 26.02
  },
  {
   "a": [108, 178],
   "b": [52, 170],
   "a2": [118, 178],
   "b2": [66, 170],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 2,
   "new": 2,
   "dOld": 56.57,
   "dNew": 52.61
  },
  {
   "a": [52, 170],
   "b": [108, 178],
   "a2": [66, 170],
   "b2": [118, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 2,
   "new": 2,
   "dOld": 56.57,
   "dNew": 52.61
  },
  {
   "a": [108, 178],
   "b": [104, 170],
   "a2": [118, 178],
   "b2": [118, 170],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 8.94,
   "dNew": 8
  },
  {
   "a": [104, 170],
   "b": [108, 178],
   "a2": [118, 170],
   "b2": [118, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 8.94,
   "dNew": 8
  },
  {
   "a": [108, 178],
   "b": [84, 178],
   "a2": [118, 178],
   "b2": [98, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 20
  },
  {
   "a": [84, 178],
   "b": [112, 178],
   "a2": [98, 178],
   "b2": [112, 178],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 28,
   "dNew": 14
  },
  {
   "a": [112, 178],
   "b": [68, 184],
   "a2": [112, 178],
   "b2": [68, 184],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 44.41,
   "dNew": 44.41
  },
  {
   "a": [68, 184],
   "b": [108, 163],
   "a2": [68, 184],
   "b2": [108, 163],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 45.18,
   "dNew": 45.18
  },
  {
   "a": [104, 170],
   "b": [52, 170],
   "a2": [118, 170],
   "b2": [66, 170],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 2,
   "new": 2,
   "dOld": 52,
   "dNew": 52
  },
  {
   "a": [112, 178],
   "b": [90, 184],
   "a2": [112, 178],
   "b2": [90, 184],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 22.8,
   "dNew": 22.8
  },
  {
   "a": [90, 184],
   "b": [108, 163],
   "a2": [90, 184],
   "b2": [108, 163],
   "by": "banco.js ranaA (34 px a hop)",
   "old": 1,
   "new": 1,
   "dOld": 27.66,
   "dNew": 27.66
  }
 ],
 "points": {
  "bancos": [
   {
    "middle": [96, 151],
    "seat": [1.133, 2.7884, 0.42, 2.833, 3.2884, 0.42],
    "back": 1.02,
    "corners": [
     [80.37, 143.19],
     [111.63, 158.81],
     [120.82, 154.22],
     [89.57, 138.59]
    ]
   },
   {
    "middle": [144, 151],
    "seat": [2.4384, 1.483, 0.42, 4.1384, 1.983, 0.42],
    "back": 1.02,
    "corners": [
     [128.37, 143.19],
     [159.63, 158.81],
     [168.82, 154.22],
     [137.57, 138.59]
    ]
   },
   {
    "middle": [192, 151],
    "seat": [3.7439, 0.1776, 0.42, 4.8639, 0.6776, 0.42],
    "back": 1.02,
    "corners": [
     [176.37, 143.19],
     [196.96, 153.48],
     [206.16, 148.89],
     [185.57, 138.59]
    ]
   }
  ],
  "bancosWhat": "each bench along x: its seat (x0, y0, z, x1, y1, z) at z 0.42, its back up to z 1.02 along its far side (y0); middle: the screen point of its seat's front edge at its middle (the old BANCOS x, row 151); corners: its seat's front left, front right, back right, back left on the screen",
  "borde": {
   "what": "the paving's far edge, on the axes: behind each bench a stretch along x 6.5 rows behind its back legs' feet (hidden by the bench), a step along y between two benches (from column 110 and 158), and left of the first bench a stretch along y from column 80 down to the picture's left edge; the lawn beyond it",
   "rows": [
    [0, 176.76],
    [40, 156.76],
    [80, 136.76],
    [96, 144.76],
    [110, 151.76],
    [120, 146.76],
    [134, 139.76],
    [144, 144.76],
    [158, 151.76],
    [170, 145.76],
    [192, 144.76],
    [240, 168.76]
   ]
  },
  "seto": {
   "line": "sx + 2 sy = 604",
   "x": 7.2311,
   "thick": 0.32,
   "high": 0.7,
   "what": "the hedge along y across the lower right corner (its +x face on the line x = 7.2311, on the screen sx + 2 sy = 604), 0.7 high"
  },
  "porton": {
   "posts": [
    [180, 212],
    [212, 196]
   ],
   "world": [
    [7.0711, 3.8075, 0],
    [7.0711, 2.0669, 0]
   ],
   "high": 1.55,
   "what": "the gate: the opening in the hedge between two stone posts (El camino's, without the arch) at the old gate's rows; the paving runs out through it along +x, between the lines through the two posts (sy - sx / 2 from 90 to 122)"
  },
  "poste": {
   "foot": [24, 138],
   "top": [24, 48],
   "world": [-1.1966, 4.0251, 0],
   "what": "the pole at the left (the old one, rows 48 to 138), on the lawn"
  },
  "farol": {
   "foot": [174, 140],
   "lantern": [174, 34, 48],
   "world": [2.9916, 0.0544, 0],
   "what": "the lamp post: its foot on the paving behind the gap between the second and third bench, its lantern at the old lantern's rows (34 to 48)"
  },
  "cable": {
   "what": "the wire: it hangs from the pole's top to the lamp post and on off the picture; its plan the line on the ground from the pole's foot through the lamp post's; at every column it lies on the old wire's row (cableY), so every pigeon on it keeps its old point",
   "plan": [
    [24, 138],
    [174, 140]
   ],
   "groundRow": "the ground under the wire at column c: row 138 + (c - 24) * 0.0133"
  },
  "luz": {
   "pool": [2.9916, 0.0544, 2.4],
   "what": "the lamp's light (evening and night): a pool on the ground round its foot, radius 2.4 (world), lighter towards the post; at night stronger"
  },
  "arboles": [
   {
    "foot": [86, 102],
    "world": [-1.4686, 0.3807, 0]
   },
   {
    "foot": [121, 114],
    "world": [0.136, 0.0816, 0]
   },
   {
    "foot": [220, 124],
    "world": [3.3724, -2.0669, 0]
   }
  ],
  "arbolesWhat": "El camino's small trees on the lawn beyond the paving (the old three, behind the benches): their feet; a lone tree's crown shade, lighter and solid (El campo's rule), on the lawn",
  "carro": {
   "world": [1.1935, 4.7149, 0.34, 1.8535, 6.1549, 0.9],
   "wheels": 0.3,
   "what": "the cart: a box along y on two wheels (at its two ends, on its +x side), its back face just in front of the piragua man (CARRO + (4, -6)); its umbrella's pole from its middle; open, a cone of eight panels red and white; closed, furled"
  },
  "sol": {
   "screen": [34, 40],
   "radius": 4,
   "what": "the sun (day and evening): upper left (every shadow falls to the right), right of the corner card's place, over the wire"
  },
  "luna": {
   "screen": [34, 40],
   "radius": 4,
   "old": [64, 26, 9],
   "what": "the moon (W.luna, at night): in the night sky, under the corner card's place (the old one, at 64, 26, lay under it)"
  },
  "nubes": {
   "screen": [
    [150, 12, 0.7],
    [196, 30, 0.8],
    [160, 40, 0.6]
   ],
   "old": [
    [36, 16, 1],
    [112, 9, 0.7],
    [168, 26, 0.8]
   ],
   "what": "the old picture's three clouds (engine.js sky()), clear of the sun, the moon and the corner card"
  },
  "corazon": {
   "screen": [110, 30],
   "what": "heartAt: unchanged"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [2.0669, 2.0669, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the corner: the benches in the middle, the cart at the left, the lamp post, the gate at the right, the lawn and trees behind, the sky"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [64, 154, 113, 60],
   "uses": ["cual-banco.json viejo.si.cam", "cual-banco.json viejo.no.cam", "cual-banco.json duerme.si.cam", "cual-banco.json duerme.no.cam", "cual-banco.json triste.si.cam", "cual-banco.json triste.no.cam"],
   "to": {
    "pictures": ["viejo.si", "viejo.no", "duerme.si", "duerme.no", "triste.si", "triste.no"]
   },
   "crops": {
    "viejo.si": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    },
    "viejo.no": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    },
    "duerme.si": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    },
    "duerme.no": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    },
    "triste.si": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    },
    "triste.no": {
     "crop": [49, 164, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 136, 124.3, 66],
   "uses": [
    "cual-banco.json mujer.si.cam",
    "cual-banco.json mujer.no.cam",
    "cual-banco.json señora.si.cam",
    "cual-banco.json señora.no.cam",
    "cual-banco.json joven.si.cam",
    "cual-banco.json joven.no.cam"
   ],
   "to": {
    "pictures": ["mujer.si", "mujer.no", "senora.si", "senora.no", "joven.si", "joven.no"]
   },
   "crops": {
    "mujer.si": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    },
    "mujer.no": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    },
    "senora.si": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    },
    "senora.no": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    },
    "joven.si": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    },
    "joven.no": {
     "crop": [44, 108, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [88, 106, 113, 60],
   "uses": [
    "cual-banco.json hombre.si.cam",
    "cual-banco.json hombre.no.cam",
    "cual-banco.json señor.si.cam",
    "cual-banco.json señor.no.cam",
    "cual-banco.json come.si.cam",
    "cual-banco.json come.no.cam",
    "cual-banco.json cansado.si.cam",
    "cual-banco.json cansado.no.cam",
    "cual-banco.json contento.si.cam",
    "cual-banco.json contento.no.cam"
   ],
   "to": {
    "pictures": ["hombre.si", "hombre.no", "senor.si", "senor.no", "come.si", "come.no", "cansado.si", "cansado.no", "contento.si", "contento.no"]
   },
   "crops": {
    "hombre.si": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    },
    "hombre.no": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    },
    "senor.si": {
     "crop": [113, 110, 98, 52],
     "zoom": 2
    },
    "senor.no": {
     "crop": [113, 110, 98, 52],
     "zoom": 2
    },
    "come.si": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    },
    "come.no": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    },
    "cansado.si": {
     "crop": [113, 112, 98, 52],
     "zoom": 2
    },
    "cansado.no": {
     "crop": [113, 112, 98, 52],
     "zoom": 2
    },
    "contento.si": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    },
    "contento.no": {
     "crop": [113, 111, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [112, 116, 90, 47.8],
   "uses": ["cual-banco.json bebe.si.cam", "cual-banco.json bebe.no.cam"],
   "to": {
    "pictures": ["bebe.si", "bebe.no"]
   },
   "crops": {
    "bebe.si": {
     "crop": [103, 114, 98, 52],
     "zoom": 2
    },
    "bebe.no": {
     "crop": [103, 114, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [93.33, 154, 54.34, 60],
   "uses": [
    "nivel.js NV viejo.p0",
    "nivel.js NV viejo.p1",
    "nivel.js NV viejo.p2",
    "nivel.js NV viejo.p3",
    "nivel.js NV triste.p0",
    "nivel.js NV triste.p1"
   ],
   "to": {
    "pictures": ["viejo.si", "viejo.no", "duerme.no", "triste.si", "triste.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [116.11, 136, 59.77, 66],
   "uses": [
    "nivel.js NV señora.p0",
    "nivel.js NV señora.p1",
    "nivel.js NV señora.p3"
   ],
   "to": {
    "pictures": ["senora.si", "senora.no", "mujer.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [117.33, 106, 54.34, 60],
   "uses": [
    "nivel.js NV come.p0",
    "nivel.js NV come.p1",
    "nivel.js NV come.p3",
    "nivel.js NV señora.p2",
    "nivel.js NV triste.p2",
    "nivel.js NV triste.p3"
   ],
   "to": {
    "pictures": ["come.si", "come.no", "cansado.si", "senor.si", "contento.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [130.35, 116, 43.29, 47.8],
   "uses": [
    "nivel.js NV come.p2"
   ],
   "to": {
    "pictures": ["bebe.si"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [0, 0],
   "uses": [
    "cual-banco.json hombre.si.set.cq",
    "cual-banco.json hombre.no.set.cq",
    "cual-banco.json mujer.si.set.cq",
    "cual-banco.json mujer.no.set.cq",
    "cual-banco.json señor.si.set.cq",
    "cual-banco.json señor.no.set.cq",
    "cual-banco.json joven.si.set.cq",
    "cual-banco.json joven.no.set.cq",
    "cual-banco.json viejo.si.set.cq",
    "cual-banco.json viejo.no.set.cq",
    "cual-banco.json come.si.set.cq",
    "cual-banco.json come.no.set.cq",
    "cual-banco.json bebe.si.set.cq",
    "cual-banco.json bebe.no.set.cq",
    "cual-banco.json duerme.si.set.cq",
    "cual-banco.json duerme.no.set.cq",
    "cual-banco.json cansado.si.set.cq",
    "cual-banco.json cansado.no.set.cq",
    "cual-banco.json contento.si.set.cq",
    "cual-banco.json contento.no.set.cq",
    "cual-banco.json triste.si.set.cq",
    "cual-banco.json triste.no.set.cq"
   ],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0) in a review picture: not a place"
  },
  {
   "kind": "point",
   "old": [28, 183],
   "uses": ["d-vamos-a-casa.json beats.0.set.cq"],
   "to": {
    "pave": [3.1548, 7.2886, 0]
   },
   "new": [28, 183],
   "what": "the frog's place q: the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [44, 210],
   "uses": ["d-vamos-a-casa.json beats.0.set.casa"],
   "to": {
    "pave": [3.2092, 7.343, 0]
   },
   "new": [44, 210],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [51, 172],
   "uses": ["d-piragua-luis.json beats.0.set.gente.piraguero", "d-vamos-a-casa.json beats.0.set.gente.piraguero", "h-banco.json beats.0.set.gente.piraguero"],
   "to": {
    "pave": [1.0335, 5.3849, 0]
   },
   "new": [40, 172],
   "moved": true,
   "why": "the piragua man behind his cart: CARRO moved (moves)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [54, 194],
   "uses": ["h-banco.json beats.0.set.perros.viejo"],
   "to": {
    "pave": [2.6109, 6.2008, 0]
   },
   "new": [54, 194],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [62, 206],
   "uses": ["d-piragua-luis.json beats.0.set.gente.carmen"],
   "to": {
    "pave": [3.4811, 6.6359, 0]
   },
   "new": [62, 206],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [66, 55],
   "uses": ["h-banco.json beats.0.set.palomas.0"],
   "to": {
    "sky": [-4.6234, -1.6862, 0]
   },
   "new": [66, 55],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [76, 200],
   "uses": ["d-vamos-a-casa.json beats.0.set.gente.abuela"],
   "to": {
    "pave": [3.5355, 5.9288, 0]
   },
   "new": [76, 200],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [78, 200],
   "uses": ["d-piragua-luis.json beats.24"],
   "to": {
    "pave": [3.5899, 5.8744, 0]
   },
   "new": [78, 200],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [83, 56],
   "uses": ["h-banco.json beats.0.set.palomas.1"],
   "to": {
    "sky": [-4.1067, -2.0941, 0]
   },
   "new": [83, 56],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [86, 190],
   "uses": ["d-piragua-luis.json beats.0.set.gente.luis"],
   "to": {
    "pave": [3.2636, 5.1129, 0]
   },
   "new": [86, 190],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [87, 161],
   "uses": ["d-vamos-a-casa.json beats.0.set.gente.senor"],
   "to": {
    "seat": [1.4663, 3.2612, 0.42]
   },
   "new": [87, 157],
   "moved": true,
   "why": "sitting on the bench at x 87: on its seat's edge (SY)",
   "what": "sitting on a bench: the seat under the lap (x, y - 11); moved (why)"
  },
  {
   "kind": "point",
   "old": [88, 181],
   "uses": ["d-piragua-luis.json beats.0.set.cq"],
   "to": {
    "pave": [4.6778, 5.5481, 0]
   },
   "new": [88, 181],
   "what": "the frog's place q: the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [90, 194],
   "uses": ["h-banco.json beats.0.set.perros.joven"],
   "to": {
    "pave": [3.5899, 5.2217, 0]
   },
   "new": [90, 194],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [92, 210],
   "uses": ["d-vamos-a-casa.json beats.0.set.perros.canelo"],
   "to": {
    "pave": [4.5146, 6.0376, 0]
   },
   "new": [92, 210],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [96, 161],
   "uses": ["h-banco.json beats.0.set.gente.mujer"],
   "to": {
    "seat": [1.9286, 3.234, 0.42]
   },
   "new": [96, 161],
   "what": "sitting on a bench: the seat under the lap (x, y - 11); the same screen place"
  },
  {
   "kind": "point",
   "old": [100, 57],
   "uses": ["d-piragua-luis.json beats.0.set.palomas.0", "d-vamos-a-casa.json beats.0.set.palomas.0", "h-banco.json beats.0.set.palomas.2"],
   "to": {
    "sky": [-3.5899, -2.5021, 0]
   },
   "new": [100, 57],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [104, 204],
   "uses": ["d-vamos-a-casa.json beats.0.set.gente.luis"],
   "to": {
    "pave": [4.5146, 5.3849, 0]
   },
   "new": [104, 204],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [104, 208],
   "uses": ["d-piragua-luis.json beats.0.set.casa", "d-piragua-luis.json beats.29"],
   "to": {
    "pave": [4.7322, 5.6025, 0]
   },
   "new": [104, 208],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [106, 172],
   "uses": [
    "cual-banco.json señora.si.set.cq",
    "cual-banco.json señora.no.set.cq"
   ],
   "to": {
    "pave": [4.6778, 4.569, 0]
   },
   "new": [106, 172],
   "what": "the frog's place q: the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [117, 57],
   "uses": ["h-banco.json beats.0.set.palomas.3"],
   "to": {
    "sky": [-3.1276, -2.9644, 0]
   },
   "new": [117, 57],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [118, 179],
   "uses": ["h-banco.json beats.0.set.cq"],
   "to": {
    "pave": [5.3849, 4.6234, 0]
   },
   "new": [118, 179],
   "what": "the frog's place q: the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [118, 208],
   "uses": ["d-vamos-a-casa.json beats.35"],
   "to": {
    "pave": [5.1129, 5.2217, 0]
   },
   "new": [118, 208],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [120, 204],
   "uses": ["cual-banco.json viejo.si.set.perros.viejo", "cual-banco.json viejo.no.set.perros.joven", "cual-banco.json duerme.si.set.perros.canelo", "cual-banco.json duerme.no.set.perros.canelo", "cual-banco.json triste.si.set.perros.canelo", "cual-banco.json triste.no.set.perros.canelo"],
   "to": {
    "pave": [4.9497, 4.9497, 0]
   },
   "new": [120, 204],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [124, 188],
   "uses": ["d-piragua-luis.json beats.17"],
   "to": {
    "pave": [4.1882, 3.9707, 0]
   },
   "new": [124, 188],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [126, 208],
   "uses": ["d-vamos-a-casa.json beats.0.set.gente.carmen"],
   "to": {
    "pave": [5.3305, 5.0041, 0]
   },
   "new": [126, 208],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [134, 57],
   "uses": ["h-banco.json beats.0.set.palomas.4"],
   "to": {
    "sky": [-2.6652, -3.4267, 0]
   },
   "new": [134, 57],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [134, 206],
   "uses": ["h-banco.json beats.0.set.casa"],
   "to": {
    "pave": [5.4393, 4.6778, 0]
   },
   "new": [134, 206],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [135, 161],
   "uses": ["d-vamos-a-casa.json beats.0.set.gente.mujer"],
   "to": {
    "seat": [2.7717, 1.9558, 0.42]
   },
   "new": [135, 157],
   "moved": true,
   "why": "sitting on the bench at x 135: on its seat's edge (SY)",
   "what": "sitting on a bench: the seat under the lap (x, y - 11); moved (why)"
  },
  {
   "kind": "point",
   "old": [138, 161],
   "uses": ["h-banco.json beats.0.set.gente.joven"],
   "to": {
    "seat": [2.9077, 1.9286, 0.42]
   },
   "new": [138, 158],
   "moved": true,
   "why": "sitting on the bench at x 138: on its seat's edge (SY)",
   "what": "sitting on a bench: the seat under the lap (x, y - 11); moved (why)"
  },
  {
   "kind": "point",
   "old": [144, 161],
   "uses": [
    "cual-banco.json hombre.si.set.gente.hombre",
    "cual-banco.json hombre.no.set.gente.mujer",
    "cual-banco.json señor.si.set.gente.senor",
    "cual-banco.json señor.no.set.gente.luis",
    "cual-banco.json come.si.set.gente.hombre",
    "cual-banco.json come.no.set.gente.hombre",
    "cual-banco.json cansado.si.set.gente.luis",
    "cual-banco.json cansado.no.set.gente.luis",
    "cual-banco.json contento.si.set.gente.hombre",
    "cual-banco.json contento.no.set.gente.hombre"
   ],
   "to": {
    "seat": [3.234, 1.9286, 0.42]
   },
   "new": [144, 161],
   "what": "sitting on a bench: the seat under the lap (x, y - 11); the same screen place"
  },
  {
   "kind": "point",
   "old": [146, 145],
   "uses": ["cual-banco.json bebe.no.set.cosas.0"],
   "to": {
    "seat": [3.0165, 1.6022, 0.42]
   },
   "new": [146, 146],
   "moved": true,
   "why": "cual-banco bebe.no: the piragua lying on the second bench's seat (AS - 4, as the old ASIENTO - 4)",
   "what": "on a bench's seat: the seat under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [146, 198],
   "uses": ["cual-banco.json mujer.si.set.gente.mujer", "cual-banco.json mujer.no.set.gente.carmen", "cual-banco.json joven.si.set.gente.joven", "cual-banco.json joven.no.set.gente.senor"],
   "to": {
    "pave": [5.3305, 3.9163, 0]
   },
   "new": [146, 198],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 186],
   "uses": ["d-piragua-luis.json beats.8"],
   "to": {
    "pave": [4.7866, 3.1548, 0]
   },
   "new": [150, 186],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [152, 149],
   "uses": ["cual-banco.json bebe.si.set.cosas.0"],
   "to": {
    "seat": [3.0981, 1.847, 0.42]
   },
   "new": [143, 149],
   "moved": true,
   "why": "cual-banco bebe.si: the bottle on the second bench's seat (AS), 9 px left: the pigeon by it moved left (the old point is past the seat's right end), its beak at the bottle as the old",
   "what": "on a bench's seat: the seat under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [158, 190],
   "uses": ["d-piragua-luis.json beats.11"],
   "to": {
    "pave": [5.2217, 3.1548, 0]
   },
   "new": [158, 190],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [160, 150],
   "uses": ["h-banco.json beats.0.set.cosas.0"],
   "to": {
    "seat": [3.8324, 1.8742, 0.42]
   },
   "new": [156, 156],
   "moved": true,
   "why": "h-banco: the rucksack on the second bench's seat (AS), 4 px left, clear of its right end",
   "what": "on a bench's seat: the seat under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [160, 198],
   "uses": [
    "cual-banco.json señora.si.set.gente.mujer",
    "cual-banco.json señora.no.set.gente.joven"
   ],
   "to": {
    "pave": [5.7112, 3.5355, 0]
   },
   "new": [160, 198],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [162, 149],
   "uses": ["cual-banco.json bebe.si.set.palomas.0"],
   "to": {
    "seat": [3.8596, 1.847, 0.42]
   },
   "new": [157, 156],
   "moved": true,
   "why": "cual-banco bebe.si: the pigeon drinking on the second bench's seat, at its right end (AS)",
   "what": "on a bench's seat: the seat under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [164, 149],
   "uses": ["cual-banco.json bebe.no.set.palomas.0"],
   "to": {
    "seat": [3.8596, 1.847, 0.42]
   },
   "new": [157, 156],
   "moved": true,
   "why": "cual-banco bebe.no: the pigeon eating on the second bench's seat, at its right end (AS)",
   "what": "on a bench's seat: the seat under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [168, 196],
   "uses": ["d-vamos-a-casa.json beats.20"],
   "to": {
    "pave": [5.82, 3.2092, 0]
   },
   "new": [168, 196],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [170, 191],
   "uses": ["d-piragua-luis.json beats.38"],
   "to": {
    "pave": [5.6025, 2.8828, 0]
   },
   "new": [170, 191],
   "what": "a place (x, y): the ground under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [186, 204],
   "uses": ["d-vamos-a-casa.json beats.21"],
   "to": {
    "pave": [6.7447, 2.8284, 0]
   },
   "new": [192, 201],
   "moved": true,
   "why": "d-vamos-a-casa: Carmen by the gate, in front of its opening (at the old point she stood behind its left post)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [188, 197],
   "uses": ["d-vamos-a-casa.json beats.7", "d-vamos-a-casa.json beats.12"],
   "to": {
    "pave": [7.0439, 2.7468, 0]
   },
   "new": [199, 203],
   "moved": true,
   "why": "PORTON moved into the gate's opening (moves)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [188, 200],
   "uses": ["d-vamos-a-casa.json beats.47"],
   "to": {
    "pave": [7.207, 2.91, 0]
   },
   "new": [199, 206],
   "moved": true,
   "why": "by PORTON, as PORTON (moves)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [192, 161],
   "uses": ["h-banco.json beats.0.set.gente.senor"],
   "to": {
    "seat": [4.5395, 0.6232, 0.42]
   },
   "new": [192, 161],
   "what": "sitting on a bench: the seat under the lap (x, y - 11); the same screen place"
  },
  {
   "kind": "point",
   "old": [240, 202],
   "uses": ["d-vamos-a-casa.json beats.41"],
   "to": {
    "out": [8.5397, 2.0125, 0]
   },
   "new": [240, 210],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [246, 197],
   "uses": ["d-vamos-a-casa.json beats.11", "d-vamos-a-casa.json beats.15"],
   "to": {
    "out": [8.7572, 1.9037, 0]
   },
   "new": [246, 211],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [246, 198],
   "uses": ["d-vamos-a-casa.json beats.44"],
   "to": {
    "out": [8.8116, 1.9581, 0]
   },
   "new": [246, 212],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [246, 204],
   "uses": ["d-vamos-a-casa.json beats.45"],
   "to": {
    "out": [8.9204, 2.0669, 0]
   },
   "new": [246, 214],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [250, 200],
   "uses": ["d-vamos-a-casa.json beats.49"],
   "to": {
    "out": [8.9204, 1.8494, 0]
   },
   "new": [250, 212],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [250, 208],
   "uses": ["d-vamos-a-casa.json beats.42"],
   "to": {
    "out": [8.5941, 1.523, 0]
   },
   "new": [250, 206],
   "moved": true,
   "why": "d-vamos-a-casa: out through the middle of the gate's opening along the path (round 2)",
   "what": "a place (x, y): the ground under (x, y - 1); moved (why)"
  },
  {
   "kind": "x",
   "old": [146],
   "uses": [
    "nivel.js NV señora.p0",
    "nivel.js NV señora.p1",
    "nivel.js NV señora.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [152],
   "uses": [
    "nivel.js NV come.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "hombre.si": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the man sitting on the second bench, reading"
  },
  "hombre.no": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the woman sitting there, reading"
  },
  "senor.si": {
   "world": [2.4477, 0.1632, 0],
   "screen": [162, 136],
   "zoom": 2,
   "crop": [113, 110, 98, 52],
   "what": "the old man sitting on the bench"
  },
  "senor.no": {
   "world": [2.4477, 0.1632, 0],
   "screen": [162, 136],
   "zoom": 2,
   "crop": [113, 110, 98, 52],
   "what": "Luis sitting there"
  },
  "come.si": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the man on the bench eating a piragua"
  },
  "come.no": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the man drinking water"
  },
  "cansado.si": {
   "world": [2.5565, 0.272, 0],
   "screen": [162, 138],
   "zoom": 2,
   "crop": [113, 112, 98, 52],
   "what": "Luis on the bench, tired"
  },
  "cansado.no": {
   "world": [2.5565, 0.272, 0],
   "screen": [162, 138],
   "zoom": 2,
   "crop": [113, 112, 98, 52],
   "what": "Luis on the bench, happy, waving"
  },
  "contento.si": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the man on the bench, happy"
  },
  "contento.no": {
   "world": [2.5021, 0.2176, 0],
   "screen": [162, 137],
   "zoom": 2,
   "crop": [113, 111, 98, 52],
   "what": "the man on the bench, crying"
  },
  "mujer.si": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "the woman walking on the paving"
  },
  "mujer.no": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "Carmen walking there"
  },
  "senora.si": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "the woman with a bag, the frog"
  },
  "senora.no": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "the young man with a bag, the frog"
  },
  "joven.si": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "the young man walking"
  },
  "joven.no": {
   "world": [3.318, 1.9037, 0],
   "screen": [146, 160],
   "zoom": 1,
   "crop": [44, 108, 196, 104],
   "what": "the old man walking"
  },
  "viejo.si": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "the old dog walking"
  },
  "viejo.no": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "the young dog walking"
  },
  "duerme.si": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "Canelo asleep"
  },
  "duerme.no": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "Canelo lying with a bone"
  },
  "triste.si": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "Canelo sad"
  },
  "triste.no": {
   "world": [3.6443, 4.841, 0],
   "screen": [98, 190],
   "zoom": 2,
   "crop": [49, 164, 98, 52],
   "what": "Canelo tired"
  },
  "bebe.si": {
   "world": [2.3933, 0.6527, 0],
   "screen": [152, 140],
   "zoom": 2,
   "crop": [103, 114, 98, 52],
   "what": "a pigeon drinking from a bottle on the bench"
  },
  "bebe.no": {
   "world": [2.3933, 0.6527, 0],
   "screen": [152, 140],
   "zoom": 2,
   "crop": [103, 114, 98, 52],
   "what": "a pigeon eating a piragua on the bench"
  }
 },
 "level": [
  {
   "w": "come",
   "index": 0,
   "picture": "come.si",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 111, 98, 52],
   "zoom": 2
  },
  {
   "w": "come",
   "index": 1,
   "picture": "come.no",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 111, 98, 52],
   "zoom": 2
  },
  {
   "w": "come",
   "index": 2,
   "picture": "bebe.si",
   "old": [130.35, 116, 43.29, 47.8],
   "crop": [103, 114, 98, 52],
   "zoom": 2
  },
  {
   "w": "come",
   "index": 3,
   "picture": "cansado.si",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 112, 98, 52],
   "zoom": 2
  },
  {
   "w": "señora",
   "index": 0,
   "picture": "senora.si",
   "old": [116.11, 136, 59.77, 66],
   "crop": [44, 108, 196, 104],
   "zoom": 1
  },
  {
   "w": "señora",
   "index": 1,
   "picture": "senora.no",
   "old": [116.11, 136, 59.77, 66],
   "crop": [44, 108, 196, 104],
   "zoom": 1
  },
  {
   "w": "señora",
   "index": 2,
   "picture": "senor.si",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 110, 98, 52],
   "zoom": 2
  },
  {
   "w": "señora",
   "index": 3,
   "picture": "mujer.no",
   "old": [116.11, 136, 59.77, 66],
   "crop": [44, 108, 196, 104],
   "zoom": 1
  },
  {
   "w": "viejo",
   "index": 0,
   "picture": "viejo.si",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "viejo",
   "index": 1,
   "picture": "viejo.no",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "viejo",
   "index": 2,
   "picture": "duerme.no",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "viejo",
   "index": 3,
   "picture": "triste.si",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "triste",
   "index": 0,
   "picture": "triste.si",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "triste",
   "index": 1,
   "picture": "triste.no",
   "old": [93.33, 154, 54.34, 60],
   "crop": [49, 164, 98, 52],
   "zoom": 2
  },
  {
   "w": "triste",
   "index": 2,
   "picture": "contento.si",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 111, 98, 52],
   "zoom": 2
  },
  {
   "w": "triste",
   "index": 3,
   "picture": "cansado.si",
   "old": [117.33, 106, 54.34, 60],
   "crop": [113, 112, 98, 52],
   "zoom": 2
  }
 ],
 "clips": {},
 "clipsWhat": "banco.js never calls clip()",
 "smoothing": "banco.js never turns smoothing on (respIcon turns it off)",
 "front": {
  "how": "the old background (fondo: the benches, the lamp post, the pole, the hedge and its posts) was drawn before everyone, and the cart was in the sorted list; now each is a set thing someone can be behind. At its entry in the list banco.js draw sorts by y (sortY 9999: after everyone), for each item drawn before it (a person, the frog, a dog, a pigeon, the pushchair, a thing: each item says what it is), the set's own pixels of the part (banco-set.html part(), PART_TAGS) are drawn again inside the item's box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under it (rules.floor). Whoever sits on a bench (sent) stands in the plane of that bench's seat front (its y1) + .03: so nothing of their bench is drawn over them, and its back stays behind them. A thing or a pigeon on a seat stands in the plane of the seat's point under its lowest row + 1 (at the seat's height) + .02: under (x, y), and under (x, y + 5) for a thing lying on its side (rot: the piragua, whose width reaches forward), a pigeon on a bench's back in that of the back's top; a pigeon on the wire is drawn over everything. \"Behind the bench\" is that depth test, not a row",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "boxes": "a person: [x - 24, y - 60 - dy, 48, 63 + dy]; the frog: frogBox with dy; a dog: [x - 16, y - 24 - dy, 32, 27 + dy]; a pigeon: [x - 10, y - 14, 20, 16]; the pushchair: [x - 21, y - 42, 42, 45]; a thing: [x - 15, y - 34, 30, 36]; its ground point under (x, y - 1)",
  "parts": {
   "banco0": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"banco0\"})"
   },
   "banco1": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"banco1\"})"
   },
   "banco2": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"banco2\"})"
   },
   "carro": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"carro\"})"
   },
   "farol": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"farol\"})"
   },
   "poste": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"poste\"})"
   },
   "porton": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"porton\"})"
   },
   "seto": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"seto\"})"
   }
  },
  "tags": [
   [
    "L.push({y:p.sent?p.y-8:p.y,d:()=>gente(c,id,a)})",
    "L.push({y:p.sent?p.y-8:p.y,id,d:()=>gente(c,id,a)})"
   ],
   [
    "(W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,d:()=>{",
    "(W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,pal:o,d:()=>{"
   ],
   [
    "(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{",
    "(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,cosa:o,d:()=>{"
   ],
   [
    "if(o&&o.vis!==0)L.push({y:o.y,d:()=>perro(c,n,a)})",
    "if(o&&o.vis!==0)L.push({y:o.y,perro:n,d:()=>perro(c,n,a)})"
   ],
   [
    "if(W.coche)L.push({y:W.coche.y,d:()=>coche(c,a)});",
    "if(W.coche)L.push({y:W.coche.y,coche:1,d:()=>coche(c,a)});"
   ],
   [
    "if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});",
    "if(q.vis)L.push({y:q.y+27,id:\"coqui\",d:()=>rana(c,q,a)});"
   ]
  ],
  "tagsWhat": "each item of the sorted list says what it is (the front masks read it); nothing else changes"
 },
 "shadows": {
  "rule": "every shadow is the sun's (day and evening; at night none: light.noche), cast from the ground point (z 0) under the screen point of the thing's feet (unproject), and darkens only pixels that take a cast shadow (the paving and the lawn, at their own depth)",
  "coqui": {
   "radius": 0.45,
   "at": "unproject(b.x + b.w / 2, q.y + 25)",
   "when": "W.cq.vis and al > .5, not W.noche",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": 0.32,
   "at": "unproject(x, y - 1); sitting: the ground under their feet, unproject(x, y)",
   "when": "visible (vis !== 0, al > .5), not W.noche",
   "cast": "for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .32) (sitting: z .3 and .65)"
  },
  "perros": {
   "radius": 0.32,
   "at": "unproject(x, y - 1)",
   "when": "every dog shown (not in the air: dy <= 3), not W.noche",
   "cast": "castShadow(g.x, g.y, .25, .32)"
  },
  "coche": {
   "radius": 0.45,
   "at": "unproject(x, y - 1)",
   "when": "W.coche, not W.noche",
   "cast": "castShadow(g.x, g.y, .3, .45), castShadow(g.x, g.y, .9, .4)"
  },
  "paloma": {
   "radius": 0.16,
   "at": "on the ground: unproject(x, y - 1); in the air (palomaA, pose vuela): unproject(o.gs) (helps.shadow)",
   "when": "on the ground or in the air, not on the wire, a bench's back or seat, the pushchair, not W.noche",
   "cast": "castShadow(g.x, g.y, .1, .16)"
  },
  "cosas": {
   "radius": 0.18,
   "at": "unproject(x, y - 1)",
   "when": "a thing lying on the ground (not on a seat, not in the air: z unset or <= its y), not W.noche",
   "cast": "castShadow(g.x, g.y, .1, .18) (the box: .4)"
  },
  "dropped": "none of the old code's own: banco.js draws no shadow"
 },
 "helps": {
  "what": "a pigeon in the air has its shadow on the ground under it: palomaA keeps, at every step of its flight, the screen point on the ground under it (o.gs): between the ground under where it took off and the ground under where it lands, as far along as it has flown (GS); landed, none",
  "lines": [
   [
    "o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-Math.sin(Math.PI*t)*8;await wait(TICK);}o.x=x;o.y=y;o.pose=\"\";",
    "o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-Math.sin(Math.PI*t)*8;o.gs=GS(x0,y0,x,y,t);await wait(TICK);}o.x=x;o.y=y;o.pose=\"\";o.gs=null;"
   ]
  ],
  "linesWhat": "the lines banco.js gains; GS (shadow.gsSource) is defined in the line of B and ASIENTO (const GS=..., B=BANCOS, ...); the port draws the rolling cart where the edited line calls CARRORUEDA (carro.rolling)",
  "shadow": {
   "gs": "GS(x0, y0, x1, y1, t): the ground under a perch (x, y): on the wire (|y - cableY(x)| <= 2, y < 80): [x, 138 + (x - 24) * 0.0133] (points.cable); on a bench's back (a POSA): [x, y - 1 + (ZS + BACK_H) * COS * S]; on a seat (a bench's seat at that row): [x, y - 1 + ZS * COS * S]; else [x, y - 1]. The shadow: lerp of the two by t",
   "gsSource": "(x0,y0,x1,y1,t)=>{const g=(x,y)=>Math.abs(y-cableY(x))<=2&&y<80?[x,138+(x-24)*0.0133]:POSA.some(p=>Math.abs(p[0]-x)<=1&&Math.abs(p[1]-y)<=1)?[x,y-1+22.967]:(y>=140&&y<=170&&Math.abs(y-AS(x))<=2&&x>75&&x<215)?[x,y-1+9.457]:[x,y-1],a=g(x0,y0),b=g(x1,y1);return [a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];}"
  },
  "margin": 6,
  "marginWhat": "whatever rests near the paving's edge, the hedge, a bench, the lamp post or the gate is on one side: on the paving with at least `margin` px of paving round its foot (the lowest 2 rows of its sprite), or on the lawn with `margin` px of lawn, and `margin` px from the footprint of every set thing (where it meets the ground: a bench's leg, the lamp post's foot, the cart's wheels, a trunk; banco-set.html FOOTS), 3 px from a gate's post (the opening is just wide enough to walk through) and from the hedge (round 2: it may hide feet, never a face); what stands behind a thing is drawn behind it (front), what stands in front of it before it"
 },
 "moves": [
  {
   "line": 19,
   "act": "*",
   "src": "PORTON=[188,197];",
   "to": "PORTON=[199,203],SY=x=>{const k=x<120?0:x<168?1:2;return Math.round(161+(x-BANCOS[k][0])/2);},AS=x=>SY(x)-12;",
   "places": [
    {
     "who": "porton",
     "old": [188, 197],
     "new": [199, 203],
     "world": [7.0439, 2.7468, 0]
    },
    {
     "who": "porton",
     "old": [184, 199],
     "new": [195, 205],
     "world": [7.0439, 2.9644, 0]
    },
    {
     "who": "porton",
     "old": [184, 197],
     "new": [195, 203],
     "world": [6.9351, 2.8556, 0]
    },
    {
     "who": "cq",
     "old": [176, 172],
     "new": [187, 178],
     "world": [7.207, 2.6924, 0]
    }
   ],
   "why": "round 2: PORTON, where one stands at the gate, 11 px right and 6 rows down: inside the gate's opening (the hedge along y across the lower right corner, its two posts at 180, 212 and 212, 196); every place made from it moves with it (luisve, pasa, sale, turno22, adios, sevade, alza, final22, sevan22: the way out at PORTON[1]). And two rules the moves below use. SY(x): where whoever sits on a bench at x has their feet: the benches stand on the world's axes (along x), so each seat's front edge falls half a row for every px to the right; whoever sits keeps the old x and sits on that edge, their feet over the paving below it; at each bench's middle the old 161. AS(x) = SY(x) - 12: a thing put on the seat at x (the old ASIENTO, 149 at each bench's middle), two rows behind the edge"
  },
  {
   "line": 231,
   "act": "*",
   "src": "await mueve(id,q[0]+(lado||0)*10,q[1]+11);",
   "to": "await mueve(id,q[0]+(lado||0)*10,SY(q[0]+(lado||0)*10));",
   "why": "sienta: whoever sits down sits on the seat's edge at their x (SY)"
  },
  {
   "line": 267,
   "act": "inicio21",
   "src": "hombre:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[2][0],y:161,dir:1,sent:1}",
   "to": "hombre:{x:B[0][0]-9,y:SY(B[0][0]-9),dir:1,sent:1},mujer:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},luis:{x:B[2][0],y:SY(B[2][0]),dir:1,sent:1}",
   "places": [
    {
     "who": "hombre",
     "old": [87, 161],
     "new": [87, 157],
     "world": [1.4663, 3.2612, 0.42]
    },
    {
     "who": "mujer",
     "old": [135, 161],
     "new": [135, 157],
     "world": [2.7717, 1.9558, 0.42]
    },
    {
     "who": "luis",
     "old": [192, 161],
     "new": [192, 161],
     "world": [4.5395, 0.6232, 0.42]
    }
   ],
   "why": "acts.inicio21: the three on the benches sit on the seats' edges (SY)"
  },
  {
   "line": 302,
   "act": "inicio22",
   "src": "senor:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},joven:{x:B[2][0]-9,y:161,dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:161,dir:1,sent:1,lee:1}",
   "to": "senor:{x:B[0][0]-9,y:SY(B[0][0]-9),dir:1,sent:1},mujer:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},joven:{x:B[2][0]-9,y:SY(B[2][0]-9),dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:SY(B[0][0]+11),dir:1,sent:1,lee:1}",
   "places": [
    {
     "who": "senor",
     "old": [87, 161],
     "new": [87, 157],
     "world": [1.4663, 3.2612, 0.42]
    },
    {
     "who": "mujer",
     "old": [135, 161],
     "new": [135, 157],
     "world": [2.7717, 1.9558, 0.42]
    },
    {
     "who": "joven",
     "old": [183, 161],
     "new": [183, 157],
     "world": [4.0771, 0.6504, 0.42]
    },
    {
     "who": "hombre",
     "old": [107, 161],
     "new": [107, 167],
     "world": [2.5541, 3.2612, 0.42]
    }
   ],
   "why": "acts.inicio22: the four on the benches (SY)"
  },
  {
   "line": 308,
   "act": "sientan",
   "src": "await mueve(k[0],B[k[1]][0]+k[2],161);",
   "to": "await mueve(k[0],B[k[1]][0]+k[2],SY(B[k[1]][0]+k[2]));",
   "why": "acts.sientan: they sit down again on the seats' edges (SY)"
  },
  {
   "line": 339,
   "act": "inicio23",
   "src": "senora:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[0][0]-13,y:161,dir:1,sent:1,animo:\"cansado\"},hombre:{x:B[2][0]+2,y:161,dir:1,sent:1,animo:\"triste\"}",
   "to": "senora:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},luis:{x:B[0][0]-13,y:SY(B[0][0]-13),dir:1,sent:1,animo:\"cansado\"},hombre:{x:B[2][0]+1,y:SY(B[2][0]+1),dir:1,sent:1,animo:\"triste\"}",
   "places": [
    {
     "who": "senora",
     "old": [135, 161],
     "new": [135, 157],
     "world": [2.7717, 1.9558, 0.42]
    },
    {
     "who": "luis",
     "old": [83, 161],
     "new": [83, 155],
     "world": [1.2487, 3.2612, 0.42]
    },
    {
     "who": "hombre",
     "old": [194, 161],
     "new": [193, 162],
     "world": [4.6211, 0.6504, 0.42]
    }
   ],
   "why": "acts.inicio23: the three on the benches (SY); the man on the third bench 1 px left, so that his hint frame stays inside the view (it did not in the old), and the frog's walk to him (alegra) still takes its old 4 hops (round 4: 2 px left made it 3)"
  },
  {
   "line": 344,
   "act": "abuelallega",
   "src": "a.x=B[0][0]+5;a.y=161;",
   "to": "a.x=B[0][0]+7;a.y=SY(B[0][0]+7);",
   "places": [
    {
     "who": "abuela",
     "old": [101, 161],
     "new": [103, 165],
     "world": [2.3366, 3.2612, 0.42]
    }
   ],
   "why": "acts.abuelallega: abuela sits down on the first bench (SY), 2 px further right than the old, apart from Luis (on the slanted seat she sits lower than he)"
  },
  {
   "line": 361,
   "act": "mira23",
   "src": "s.x+=4;await wait(700);s.x-=4;",
   "to": "s.x+=4;s.y+=2;await wait(700);s.x-=4;s.y-=2;",
   "why": "acts.mira23: the señora leans 4 px to the right along the seat: she keeps to its edge (2 rows lower)"
  },
  {
   "line": 272,
   "act": "dejan",
   "src": "{id:\"pir\",k:\"piragua\",x:101,y:ASIENTO-4,rot:Math.PI/2},{id:\"bot\",k:\"agua\",x:153,y:ASIENTO}",
   "to": "{id:\"pir\",k:\"piragua\",x:97,y:AS(97)-4,rot:Math.PI/2},{id:\"bot\",k:\"agua\",x:153,y:AS(153)}",
   "places": [
    {
     "who": "cosa",
     "old": [101, 145],
     "new": [97, 146],
     "world": [1.6838, 2.9349, 0.42]
    },
    {
     "who": "cosa",
     "old": [153, 149],
     "new": [153, 154],
     "world": [3.642, 1.847, 0.42]
    }
   ],
   "why": "acts.dejan: the piragua and the bottle left on the seats (AS); the piragua 4 px left, so that it lies on the seat's top clear of its right end, by the man who leaves it"
  },
  {
   "line": 274,
   "act": "paloma",
   "src": "await palomaA(pg,119,ASIENTO);",
   "to": "await palomaA(pg,109,AS(109));",
   "places": [
    {
     "who": "paloma",
     "old": [119, 149],
     "new": [109, 156],
     "world": [2.5541, 3.1524, 0.42]
    }
   ],
   "why": "acts.paloma: the pigeon lands on the seat by the piragua: the old point (119) is past the new seat's right end; on the seat, 10 px left, its beak at the piragua (moved 4 px left too)"
  },
  {
   "line": 274,
   "act": "paloma",
   "src": "await palomaA(pg,163,ASIENTO);",
   "to": "await palomaA(pg,157,AS(157));",
   "places": [
    {
     "who": "paloma",
     "old": [163, 149],
     "new": [157, 156],
     "world": [3.8596, 1.847, 0.42]
    }
   ],
   "why": "acts.paloma: the pigeon lands on the seat by the bottle: on the seat, 6 px left (the old point is past the new seat's right end)"
  },
  {
   "line": 303,
   "act": "inicio22",
   "src": "{id:\"cartera\",k:\"cartera\",x:157,y:ASIENTO},{id:\"mochila\",k:\"mochila\",x:204,y:ASIENTO+1}",
   "to": "{id:\"cartera\",k:\"cartera\",x:154,y:AS(154)},{id:\"mochila\",k:\"mochila\",x:197,y:AS(197)+1}",
   "places": [
    {
     "who": "cosa",
     "old": [157, 149],
     "new": [154, 154],
     "world": [3.6692, 1.8198, 0.42]
    },
    {
     "who": "cosa",
     "old": [204, 150],
     "new": [197, 153],
     "world": [4.7842, 0.596, 0.42]
    }
   ],
   "why": "acts.inicio22: the handbag and the rucksack on the seats (AS), clear of the seats' right ends (the third bench ends 5 px right of its middle, round 2)"
  },
  {
   "line": 315,
   "act": "turno22",
   "src": "{id:\"periodico\",k:\"periodico\",x:108,y:ASIENTO}",
   "to": "{id:\"periodico\",k:\"periodico\",x:105,y:AS(105)}",
   "places": [
    {
     "who": "cosa",
     "old": [108, 149],
     "new": [105, 154],
     "world": [2.3366, 3.1524, 0.42]
    }
   ],
   "why": "acts.turno22: the newspaper left on the seat (AS), 3 px left, clear of its right end"
  },
  {
   "line": 343,
   "act": "cojin",
   "src": "{id:\"cojin\",k:\"mochila\",x:B[0][0]-21,y:ASIENTO+1,z:150}",
   "to": "{id:\"cojin\",k:\"mochila\",x:B[0][0]+12,y:AS(B[0][0]+12)+1,z:150}",
   "places": [
    {
     "who": "cosa",
     "old": [75, 150],
     "new": [108, 156],
     "world": [2.5269, 3.1796, 0.42]
    }
   ],
   "why": "acts.cojin: Carmen puts the rucksack on the first bench as a cushion: the old point (B - 21) is past the new seat's left end, and Luis sits at its left end (B - 13); at its right end"
  },
  {
   "line": 238,
   "act": "*",
   "src": "POSA=[[110,127],[158,127],[176,127],[208,127]]",
   "to": "POSA=[[110,137],[158,137],[188,128],[197,133]]",
   "places": [
    {
     "who": "paloma",
     "old": [110, 127],
     "new": [110, 137],
     "world": [2.2827, 2.8266, 1.02]
    },
    {
     "who": "paloma",
     "old": [158, 127],
     "new": [158, 137],
     "world": [3.5881, 1.5212, 1.02]
    },
    {
     "who": "paloma",
     "old": [176, 127],
     "new": [188, 128],
     "world": [3.9145, 0.2158, 1.02]
    },
    {
     "who": "paloma",
     "old": [208, 127],
     "new": [197, 133],
     "world": [4.4312, 0.243, 1.02]
    }
   ],
   "why": "where the pigeons perch on the benches' backs (posa): on the top of each back at its x, which falls half a row a px to the right; the third (176) was past the third back's left end: 12 px right; the fourth 11 px left (the third bench is shorter, round 2)"
  },
  {
   "line": 19,
   "act": "*",
   "src": "CARRO=[47,178]",
   "to": "CARRO=[36,178]",
   "places": [
    {
     "who": "piraguero",
     "old": [51, 172],
     "new": [40, 172],
     "world": [1.0335, 5.3849, 0]
    },
    {
     "who": "carro",
     "old": [47, 178],
     "new": [36, 178],
     "world": [1.251, 5.82, 0]
    }
   ],
   "why": "the cart and its man 11 px to the left: the cart lies along y in front of the man (down to the right of him on the screen, where the old one was drawn round him), so its middle is right of him; at the old point its right wheel stood where the frog serves whoever sits at the first bench's left (87, 179). W.carroX starts at CARRO[0] (carrova) and every place made from CARRO moves with it (the man: CARRO + (4, -6))"
  },
  {
   "line": 426,
   "act": "*",
   "src": "fresh:()=>({respEn:[120,64],",
   "to": "fresh:()=>({respEn:[128,31],",
   "why": "where the answer cards stand (W.respEn, every story of the scene): in the sky under the rounds card, so that the hint drawn round a card (its frame, box + 12, and the hint hand under it, 45 px tall) falls on nobody's face: at the old (120, 64) the hand lay on the faces of whoever sits on the benches. Its frames and glow 4 px inside the view, right of the sun; over the wire's pigeons and the lamp's lantern (no ask with cards names them)"
  },
  {
   "line": 305,
   "act": "inicio22",
   "src": "W.casa=[124,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;",
   "to": "W.casa=[134,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;",
   "places": [
    {
     "who": "cq",
     "old": [108, 178],
     "new": [118, 178],
     "world": [5.3305, 4.569, 0]
    }
   ],
   "why": "acts.inicio22 (senor-senora): the frog's home 10 px right, so that his walks to the young dog (moved, below) take their old two hops; every other walk from it keeps its count (hops)"
  },
  {
   "line": 304,
   "act": "inicio22",
   "src": "W.perros={viejo:{x:90,y:193,pose:\"sit\",dir:1},joven:{x:38,y:193,pose:\"sit\",dir:1}}",
   "to": "W.perros={viejo:{x:104,y:193,pose:\"sit\",dir:1},joven:{x:52,y:193,pose:\"sit\",dir:1}}",
   "places": [
    {
     "who": "perro",
     "old": [38, 193],
     "new": [52, 193],
     "world": [2.4725, 6.1712, 0.42]
    },
    {
     "who": "perro",
     "old": [90, 193],
     "new": [104, 193],
     "world": [3.8867, 4.757, 0.42]
    }
   ],
   "why": "acts.inicio22: the two dogs 14 px right: at 38 the young dog's hint frame (box + 12) left the view (as in the old); the old dog with it, and the frog's home (above), so that every walk of the frog between them and to them takes its old hops"
  },
  {
   "line": 318,
   "act": "sale22",
   "src": "W.casa=[100,205];",
   "to": "W.casa=[114,205];",
   "places": [
    {
     "who": "cq",
     "old": [84, 178],
     "new": [98, 178],
     "world": [4.7866, 5.1129, 0]
    }
   ],
   "why": "acts.sale22: the frog's home when the dogs have moved aside, 14 px right with them (moved, below), so that he stands where he stood beside the young dog and his walks take their old hops"
  },
  {
   "line": 309,
   "lines": [309, 311],
   "act": "*",
   "src": "mueve(\"carmen\",158,210)",
   "to": "mueve(\"carmen\",160,215)",
   "places": [
    {
     "who": "carmen",
     "old": [158, 210],
     "new": [160, 215],
     "world": [6.6064, 4.4307, 0.42]
    }
   ],
   "why": "bolsa, hueso: where Carmen hands the bag and the bone, 2 px right and 5 rows nearer (round 3: 1 px from the picture's lower edge, not 3: no place holds, see checks.notFixed) (round 3: 3 px and more inside the picture's lower edge, as the old): Luis and the frog's home moved 14 px right (round 2), and 14 px would put her behind the gate's left post; here she is clear of the frog, of the post, and of Luis but his feet"
  },
  {
   "line": 335,
   "act": "carrova",
   "src": "v.y=196;j.y=204;",
   "to": "v.y=206;j.y=210;",
   "why": "acts.carrova: when the cart goes home the two dogs walk 10 and 6 rows nearer: the cart now rolls toward the viewer (+y) with its man pushing it, and at the old rows he walked over the old dog; here both dogs stay in front of him while they are in the view (the young one still in front of the old)"
  },
  {
   "line": 327,
   "act": "perros22",
   "src": "L=[38,193],D=[90,193]",
   "to": "L=[52,193],D=[104,193]",
   "why": "acts.perros22: the dogs' two places, as at the start (inicio22)"
  },
  {
   "line": 318,
   "act": "sale22",
   "src": "perroA(\"viejo\",36,193,\"walk\"),perroA(\"joven\",64,194,\"run\")",
   "to": "perroA(\"viejo\",52,193,\"walk\"),perroA(\"joven\",54,210,\"run\")",
   "places": [
    {
     "who": "perro",
     "old": [36, 193],
     "new": [52, 193],
     "world": [2.4725, 6.1712, 0.42]
    },
    {
     "who": "perro",
     "old": [64, 194],
     "new": [54, 210],
     "world": [3.4516, 7.0415, 0.42]
    }
   ],
   "why": "acts.sale22: the dogs move aside to the left: the old one 16 px less far (his hint frame inside the view), the young one 10 px farther and 16 rows nearer (round 3: 3 px and more inside the picture's lower edge), in front of the old one (moved) and of the frog when he serves whoever queues first at the cart (cola22: at the old row he stood over the dog)"
  },
  {
   "line": 302,
   "act": "inicio22",
   "src": "carmen:{x:176,y:208,dir:-1}",
   "to": "carmen:{x:198,y:211,dir:-1}",
   "places": [
    {
     "who": "carmen",
     "old": [176, 208],
     "new": [198, 211],
     "world": [7.4223, 3.1796, 0.42]
    }
   ],
   "why": "acts.inicio22: Carmen 18 px right and 4 rows down, on the path just beyond the gate: at the old point she stood on the gate's left post; the frog's home, Luis and the box moved 14 px right (round 2), and she keeps her distance from them"
  },
  {
   "line": 302,
   "act": "inicio22",
   "src": "luis:{x:148,y:186,dir:1}",
   "to": "luis:{x:162,y:186,dir:1}",
   "places": [
    {
     "who": "luis",
     "old": [148, 186],
     "new": [162, 186],
     "world": [5.0834, 2.7989, 0.42]
    }
   ],
   "why": "acts.inicio22: Luis by the box, 14 px right with the frog's home (moved), so that the frog does not stand on his feet (round 2)"
  },
  {
   "line": 317,
   "lines": [317, 326],
   "act": "*",
   "src": "mueve(\"luis\",148,186)",
   "to": "mueve(\"luis\",162,186)",
   "why": "luiscaja, luisguarda: Luis back to his place by the box (moved, inicio22)"
  },
  {
   "line": 303,
   "act": "inicio22",
   "src": "{id:\"caja\",k:\"caja\",x:167,y:187}",
   "to": "{id:\"caja\",k:\"caja\",x:185,y:187}",
   "places": [
    {
     "who": "cosa",
     "old": [167, 187],
     "new": [185, 187],
     "world": [6.3072, 2.7717, 0.42]
    }
   ],
   "why": "acts.inicio22: the box beside Luis, 18 px right (he moved 14), so that it hides no more of his legs than the old (round 2)"
  },
  {
   "line": 306,
   "act": "alcarro",
   "src": "const en={senor:[80,184],mujer:[96,188],joven:[112,184]}",
   "to": "const en={senor:[80,190],mujer:[96,192],joven:[120,186]}",
   "places": [
    {
     "who": "senor",
     "old": [80, 184],
     "new": [80, 190],
     "world": [3.0709, 5.2466, 0.42]
    },
    {
     "who": "mujer",
     "old": [96, 188],
     "new": [96, 192],
     "world": [3.6148, 4.9202, 0.42]
    },
    {
     "who": "joven",
     "old": [112, 184],
     "new": [120, 186],
     "world": [3.9411, 3.9411, 0.42]
    }
   ],
   "why": "acts.alcarro: the three queue at the cart 6, 4 and 2 rows nearer, the young man 8 px right, behind the old dog (moved) as before it: the man reading on the first bench sits up to 6 rows lower than the old (SY), and their heads stood in front of his face (round 2)"
  },
  {
   "line": 238,
   "act": "*",
   "src": "JUGEN=[[182,188],[195,196],[183,209],[196,211]]",
   "to": "JUGEN=[[182,188],[195,196],[190,208],[196,211]]",
   "places": [
    {
     "who": "cosa",
     "old": [183, 209],
     "new": [190, 208],
     "world": [7.5855, 3.778, 0.42]
    }
   ],
   "why": "where the third toy lands (despierta): 7 px right, in the gate's opening: the old point is on its left post"
  },
  {
   "line": 323,
   "act": "pasa",
   "src": "await mueve(o.a,PORTON[0]+8,PORTON[1]);",
   "to": "await mueve(o.a,PORTON[0]-2,PORTON[1]+5);",
   "places": [
    {
     "who": "porton",
     "old": [196, 197],
     "new": [197, 208],
     "world": [7.2614, 3.0732, 0]
    }
   ],
   "why": "acts.pasa: who walks through the gate stops just beyond it on the path, clear of the right post and the hedge (round 2), and 3 px and more inside the picture's right edge with what they carry, as the old (round 3)"
  },
  {
   "line": 325,
   "act": "sevade",
   "src": "p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;},",
   "to": "p.dir=1;await mueve(o.a,PORTON[0],PORTON[1]);await mueve(o.a,246,PORTON[1]+12);p.vis=0;},",
   "why": "acts.sevade: who says goodbye walks out through the gate's opening (PORTON) and along the path: from the benches straight to the old exit point the way crossed the hedge (round 2)"
  },
  {
   "line": 333,
   "act": "alza",
   "src": "p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;W.cq.dy=0;",
   "to": "p.dir=1;await mueve(o.a,PORTON[0],PORTON[1]);await mueve(o.a,246,PORTON[1]+12);p.vis=0;W.cq.dy=0;",
   "why": "acts.alza: as sevade"
  },
  {
   "line": 344,
   "act": "abuelallega",
   "src": "W.gente.abuela={x:250,y:204,dir:-1,paso:1}",
   "to": "W.gente.abuela={x:250,y:212,dir:-1,paso:1}",
   "places": [
    {
     "who": "abuela",
     "old": [250, 204],
     "new": [250, 212],
     "world": [8.8909, 1.8198, 0.42]
    }
   ],
   "why": "acts.abuelallega: abuela comes in along the path and through the gate's opening (from 8 rows lower, off the picture)"
  },
  {
   "line": 334,
   "act": "final22",
   "src": "mueve(\"carmen\",190,204)",
   "to": "mueve(\"carmen\",192,200)",
   "places": [
    {
     "who": "carmen",
     "old": [190, 204],
     "new": [192, 200],
     "world": [6.6608, 2.7445, 0.42]
    }
   ],
   "why": "acts.final22: Carmen waits at the gate in front of its opening, clear of the left post (round 2)"
  },
  {
   "line": 334,
   "act": "final22",
   "src": "h.pose=\"idle\";await mueve(\"hombre\",246,PORTON[1]);h.vis=0;}else",
   "to": "h.pose=\"idle\";await mueve(\"hombre\",PORTON[0],PORTON[1]);await mueve(\"hombre\",246,PORTON[1]+12);h.vis=0;}else",
   "why": "acts.final22: the man who came for his paper leaves through the gate's opening (PORTON) and along the path: from beside Luis straight to the exit the way crossed the line of the gate at its right post (round 2)"
  },
  {
   "line": 322,
   "lines": [322, 325, 332, 333, 334],
   "act": "*",
   "src": "246,PORTON[1])",
   "to": "246,PORTON[1]+12)",
   "why": "whoever leaves walks to (246, PORTON[1] + 12): through the middle of the gate's opening and out along the path (round 2; the old went to PORTON[1], past the right post)"
  },
  {
   "line": 315,
   "act": "*",
   "src": "244,PORTON[1])",
   "to": "244,PORTON[1]+12)",
   "why": "as 246, PORTON[1] (turno22)"
  },
  {
   "line": 296,
   "act": "final21",
   "src": "cx()+46,pies()+2",
   "to": "cx()+36,pies()+2",
   "places": [
    {
     "who": "carmen",
     "old": [170, 208],
     "new": [160, 208],
     "world": [6.2256, 4.0499, 0.42]
    }
   ],
   "why": "acts.final21: Carmen comes to the frog's right 10 px nearer: at the old offset from his home she stood on the gate's left post (round 2)"
  },
  {
   "line": 391,
   "act": "sevan23",
   "src": "mueve(\"abuela\",250,200),mueve(\"carmen\",250,206),mueve(\"luis\",250,196),perroA(\"canelo\",250,210",
   "to": "mueve(\"abuela\",250,210),mueve(\"carmen\",250,206),mueve(\"luis\",250,206),perroA(\"canelo\",250,214",
   "places": [
    {
     "who": "abuela",
     "old": [250, 200],
     "new": [250, 210],
     "world": [8.7821, 1.711, 0.42]
    },
    {
     "who": "luis",
     "old": [250, 196],
     "new": [250, 206],
     "world": [8.5645, 1.4935, 0.42]
    },
    {
     "who": "perro",
     "old": [250, 210],
     "new": [250, 214],
     "world": [8.9997, 1.9286, 0.42]
    }
   ],
   "why": "acts.sevan23: everyone leaves through the gate's opening and out along the path (the old walked out over the hedge's line)"
  },
  {
   "line": 196,
   "act": "*",
   "src": "if(pi)pi.x=W.carroX+30;",
   "to": "if(pi){pi.x=W.carroX+30;pi.y=CARRO[1]+2+(CARRO[0]-W.carroX)/2;}",
   "why": "the cart rolling away (W.seva): it rolls along +y (down to the left on the screen, half a row for every px), the piragua man pushing it from behind"
  },
  {
   "line": 198,
   "act": "*",
   "src": "if(W.carro!==0)L.push({y:CARRO[1],d:()=>c.drawImage(spr(\"carro\"+(W.carro===\"cerrado\"?1:0),()=>mkCarro(W.carro===\"cerrado\")),R(W.carroX!=null?W.carroX:CARRO[0])-24,CARRO[1]-72)});",
   "to": "if(W.carro!==0&&W.carroX!=null)L.push({y:CARRO[1]+(CARRO[0]-W.carroX)/2,carro:1,d:()=>CARRORUEDA(c,W)});",
   "why": "the cart: while it stands it is the set's (setKey carro abierto or cerrado: banco.js draws nothing); while it rolls (W.carroX) the set has none (carro no) and the sprite layer draws the set's own cart, pixel for pixel (sheet carro.rolling), moved by (R(W.carroX) - CARRO[0], R((CARRO[0] - W.carroX) / 2)), in the sorted list at its new row"
  }
 ],
 "dropped": [
  {
   "line": 192,
   "src": "c.drawImage(spr(\"banco\",fondo),0,0);",
   "to": "",
   "why": "the background (fondo): the set, for setKey(W)"
  },
  {
   "line": 193,
   "src": "if(W.luna){c.fillStyle=OUT;c.beginPath();c.arc(64,26,9,0,7);c.fill();c.fillStyle=\"#FFF8D8\";c.beginPath();c.arc(64,26,8,0,7);c.fill();c.fillStyle=\"#E8DCA8\";c.fillRect(60,22,3,3);c.fillRect(66,28,2,2);}   // the moon",
   "to": "",
   "why": "the moon: baked into the night sky (setKey luna; points.luna)"
  },
  {
   "line": 194,
   "src": "if(W.noche){c.drawImage(spr(\"banco\",fondo),84,6,46,38,196,6,46,38);c.fillStyle=\"rgba(30,24,90,.32)\";c.fillRect(0,0,SW,SH);fr(c,FAROL[0]-5,36,11,11,\"#FFF8C8\");c.fillStyle=\"rgba(255,240,160,.16)\";c.beginPath();c.ellipse(FAROL[0],FAROL[1]+18,46,22,0,0,7);c.fill();}",
   "to": "",
   "why": "the night (setKey luz noche): its colour laid over the background is the set's night light (set-kit.js lightPass), its lit lantern and pool of light the set's; the patch of sky it copies over the sun (patch) is the night sky's, which has no sun"
  },
  {
   "line": 195,
   "src": "if(W.tarde&&!W.noche){c.fillStyle=\"rgba(255,150,60,.10)\";c.fillRect(0,0,SW,SH);}",
   "to": "",
   "why": "the evening (setKey luz tarde): the set's warm light and evening sky"
  }
 ],
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as banco.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
  "rects": {
   "hola": [-16, -46, 34, 44],
   "amor": [-14, -38, 30, 36],
   "como": [-32, -40, 66, 38],
   "bien": [-14, -40, 30, 38],
   "mal": [-14, -40, 30, 38],
   "quien": [-22, -40, 46, 38],
   "lluvia": [-22, -40, 46, 38]
  }
 },
 "talk": {
  "what": "where a bubble goes (banco.js draw: line 207 for a person, 208 for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud) and of every face; if none is, the first (the old)",
  "top": "a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)",
  "places": [
   [0, 0],
   [1, 7],
   [-1, 7],
   [1, 30],
   [-1, 30],
   [1, 44],
   [-1, 44],
   [2, 7],
   [-2, 7],
   [2, 30],
   [-2, 30],
   [2, 44],
   [-2, 44],
   [1, 58],
   [-1, 58],
   [2, 58],
   [-2, 58]
  ],
  "placesWhat": "[side, dy]: the tail's tip at (top.x + side * (h + 16), top.y + dy), h the head's half width: a person 6, the frog b.w >> 1",
  "faces": "a person's face: [x - 6, top + 6, 12, 10] (eyes to chin), top the sprite's first row (y - height + 1 - dy, + 3 tired, + 1 sad: banco.js gente; heights); abuela's: from her sprite (the middle of its top 10 rows); the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heights": {
   "luis.0": 44,
   "luis.1": 41,
   "carmen.0": 44,
   "carmen.1": 41,
   "hombre.0": 56,
   "hombre.1": 49,
   "mujer.0": 56,
   "mujer.1": 49,
   "senor.0": 56,
   "senor.1": 49,
   "joven.0": 56,
   "joven.1": 49,
   "senora.0": 56,
   "senora.1": 49,
   "piraguero.0": 56,
   "piraguero.1": 49
  },
  "board": [2, 2, 68, 26],
  "boardWhat": "in the 196 x 216 display, then + the view's x0: W.tarjeta (the rounds card) [2, 2, 68, 26]"
 },
 "code": [
  {
   "line": 3,
   "numbers": {
    "other": ["2"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 19,
   "numbers": {
    "other": ["132"],
    "place": ["96", "150", "144", "150", "192", "150", "47", "178", "168", "154", "188", "197"]
   },
   "to": {
    "moves": [
     "PORTON=[188,197];"
    ],
    "points": ["bancos", "carro", "farol", "porton"],
    "spots": ["sitio.0", "sitio.1", "sitio.2", "carro", "porton"]
   },
   "note": "SUELO (the old paving's first row): the set's paving (points.borde); BANCOS: the benches, each along x, the middle of its seat's edge at the old point (points.bancos; whoever sits: SY, moves); CARRO: the cart (the set's, built round it: points.carro; its place in the list unchanged); FAROL: the lamp post (the set's: points.farol, things.farol); PORTON: unchanged (spots.porton)"
  },
  {
   "line": 20,
   "numbers": {
    "other": ["50", "1", "2"],
    "scale": ["7", "98"],
    "offset": ["120"]
   },
   "to": {
    "points": ["cable"]
   },
   "note": "the wire's rows: the set's wire lies on them (points.cable): every pigeon on it keeps its point"
  },
  {
   "line": 21,
   "numbers": {
    "other": ["66", "66"],
    "scale": ["17", "17"]
   },
   "to": {
    "spots": ["cable.0", "cable.1", "cable.2", "cable.3", "cable.4"]
   },
   "note": "where the pigeons sit on the wire: unchanged (the wire is under them)"
  },
  {
   "line": 22,
   "numbers": {
    "place": ["0", "1"],
    "offset": ["23"]
   },
   "to": "unchanged",
   "note": "RESP (the top of a bench's back, B - 23): used by no act or draw (the pigeons perch at POSA)"
  },
  {
   "line": 26,
   "numbers": {
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 27,
   "numbers": {
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 28,
   "numbers": {
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 29,
   "numbers": {
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 30,
   "numbers": {
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 34,
   "numbers": {
    "dropped": ["96", "92", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 36,
   "numbers": {
    "dropped": ["40", "98", "122", "94", "218", "98", "0", "3", "1", "6", "34", "1", "0", "3", "1", "2", "34", "3", "0", "1", "10", "24", "17", "0", "1", "10", "23", "16", "0", "8", "1", "15", "9", "5", "3", "4"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 38,
   "numbers": {
    "dropped": ["0", "14", "2", "12", "24", "14", "0", "2", "12", "24", "0", "7", "3", "5", "1", "60", "1", "1", "6"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 39,
   "numbers": {
    "dropped": ["0", "1", "0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 41,
   "numbers": {
    "dropped": ["0", "1", "48", "3", "1", "44", "0", "4", "1", "3", "9", "3", "0", "5", "36", "11", "11", "0", "6", "35", "13", "13", "0", "4", "33", "9", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 42,
   "numbers": {
    "dropped": ["21", "48", "3", "90"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 43,
   "numbers": {
    "dropped": ["22"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 45,
   "numbers": {
    "dropped": ["0", "21", "1", "2", "22", "2", "34", "0", "38", "22", "2", "34", "0", "22", "16", "10", "42", "4", "2", "42", "1", "4", "3", "42", "1", "1", "1", "3", "44", "5", "3", "1", "3", "44", "1", "4", "1", "1", "44", "1", "1", "2", "4", "46", "7", "1", "23", "44", "17", "3", "3", "3", "9", "0", "36", "3", "3", "9", "0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 47,
   "numbers": {
    "dropped": ["160", "203", "180", "200", "203", "160", "20", "4", "3", "34", "0", "5", "50", "1", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 48,
   "numbers": {
    "dropped": ["160", "20", "198", "16", "197", "0", "8", "1", "197", "0", "2", "1", "203", "0", "2", "1", "196", "0", "1", "10", "1", "2", "195", "0", "3", "12", "3", "194", "0", "4", "14", "5", "201", "0", "7", "3.4", "3.4", "201", "0", "7", "2.6", "2.6"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 49,
   "numbers": {
    "dropped": ["181", "200", "206", "1", "1", "8"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 52,
   "numbers": {
    "drawing": ["48", "74", "23", "14", "2", "34"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 53,
   "numbers": {
    "drawing": ["21", "2", "6", "26", "23", "2", "2", "26", "20", "1", "8", "28"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 54,
   "numbers": {
    "drawing": ["0", "5", "2", "4", "8", "6", "2", "2", "8", "7", "2", "3", "12", "42", "2", "24", "5", "4", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 55,
   "numbers": {
    "drawing": ["5", "46", "38", "18", "5", "46", "38", "3", "5", "61", "38", "3", "4", "45", "40", "20", "10", "51", "28", "7", "13", "52", "19", "52", "25", "52", "31", "52", "0", "1", "3", "5", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 56,
   "numbers": {
    "drawing": ["8", "36", "13", "10", "8", "36", "13", "2", "7", "35", "15", "12", "26", "38", "31", "38", "36", "38", "0", "1", "4", "8", "2", "0", "1", "1", "3", "2", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 57,
   "numbers": {
    "drawing": ["12", "36", "68", "6", "6", "68", "5", "5", "68", "1.5", "1.5"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 60,
   "numbers": {
    "drawing": ["9", "13", "4.5", "4", "3.6", "3.4", "2", "2", "2", "2", "0", "6", "2", ".42", "7", "5", ".84", "1", "4", "12"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 61,
   "numbers": {
    "drawing": ["13", "18", "6.5", "6", "5.6", "5.2", "1", "5", "4", "4", "5", "1", "4", "7", "9", "5", "3", "4", "3", "2", "2", "3", "9", "2", "2", "3", "0", "8", "3", ".45", "10", "7", ".9", "1", "6", "17"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 62,
   "numbers": {
    "drawing": ["7", "8", "0", "6", "1", ".42", "1", "5", ".84", "1", "3", "7"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 63,
   "numbers": {
    "drawing": ["7", "13", "1", "4", "5", "8", "1", "4", "2", "8", "2", "1", "3", "3", "1", "6", "5", "1", "2", "0", "3", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 64,
   "numbers": {
    "drawing": ["7", "13", "1", "4", "5", "8", "2", "1", "3", "3", "1", "11", "5", "1", "2", "0", "3", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 65,
   "numbers": {
    "drawing": ["16", "8", "4", "1", "8", "5", "4", "1", "8", "1", "4", "4", "8", "1", "1", "6", "14", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 66,
   "numbers": {
    "drawing": ["11", "32", "5", "6", "1", "24", "8", "28", "12", "1", "8", "1", "23", "3", "24", "1", "3", "5", "2", "1", "1", "2", "2", "5", "0", "5", "1", "1", "6", "6", "0", "3", "1", "9", "1", "1", "3", "5", "30", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 67,
   "numbers": {
    "drawing": ["15", "11", "1", "1", "13", "9", "1", "1", "13", "2", "1", "5", "13", "1", "6", "4", "3", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 68,
   "numbers": {
    "drawing": ["15", "17", "1", "3", "13", "13", "1", "3", "13", "2", "3", "8", "9", "6", "3", "8", "9", "1", "5", "0", "5", "3", "7", "11"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 69,
   "numbers": {
    "drawing": ["8", "30", "3", "3", "2", "26", "3", "1", "5", "2", "7", "2", "1", "3", "3", "28", "2", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 70,
   "numbers": {
    "drawing": ["13", "13", "1", "5", "11", "7", "1", "5", "11", "2", "6", "8", "3", "1", "1", "4", "9", "1", "1", "4", "3", "0", "7", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 71,
   "numbers": {
    "drawing": ["14", "7", "1", "1", "9", "5", "1", "1", "9", "1", "9", "4", "5", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 72,
   "numbers": {
    "drawing": ["15", "8", "1", "1", "13", "6", "2", "4", "2", "11", "1", "7", "1", "1", "6"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 73,
   "numbers": {
    "drawing": ["10", "13", "1", "3", "8", "9", "1", "3", "3", "9", "1", "1", "8", "2", "2", "0", "6", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 74,
   "numbers": {
    "drawing": ["13", "7", "3", "2", "7", "3", "2", "1", "2", "5", "10", "1", "10", "5", "0", "1", "1.6", "1.6"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 75,
   "numbers": {
    "drawing": ["28", "16", "1", "5", "26", "10", "1", "5", "26", "2", "1", "13", "26", "2", "3", "2", "22", "3", "12", "8", "4", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 76,
   "numbers": {
    "drawing": ["8", "12", "4", "4", "3", "3", "3", "3", "3", "7", "2", "4"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 77,
   "numbers": {
    "drawing": ["15", "10", "1", "4", "13", "3", "4", "1", "7", "3", "5", "2", "2", "2", "8", "2", "2", "2", "1", "4", "13", "1", "4", "11", "7.5", "1.8", "1.8", "7"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 78,
   "numbers": {
    "drawing": ["9", "9", "1", "1", "7", "7", "1", "1", "7", "2", "3", "3", "3", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 79,
   "numbers": {
    "drawing": ["11", "9", "5", "5.5", "4", "2.6", "8", "2.5", "2", "2", "9", "2", "10", "3", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 80,
   "numbers": {
    "drawing": ["20", "10", "10", "5", "9", "4", "2", "18", "3", "9"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 81,
   "numbers": {
    "drawing": ["9", "9", "4.5", "4.5", "3.6", "3.6", "2", "4", "5", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 82,
   "numbers": {
    "drawing": ["22", "6", "1", "2", "20", "3", "1", "2", "20", "1", "0", "1", "2", "2", "20", "1", "2", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 85,
   "numbers": {
    "drawing": ["18", "13"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 86,
   "numbers": {
    "drawing": ["7", "7", "4.4", "2.6", "6", "6", "4", "1", "11", "1.6", "2", "8", "6", "10", "1", "11", "1.6", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 87,
   "numbers": {
    "drawing": ["6", "7", "4.6", "3.2", "2", "7", "0", "5", "1.2", "0", "5", "10", "1", "2", "8", "10", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 88,
   "numbers": {
    "drawing": ["11", "12", "9", "10", "8", "2", "3", "6", "4", "9", "6", "1", "1.4", "1", "2.4", "2.4", "1", "2", "1", "1", "1", "2", "1", "0", "2", "1", "8", "5", "2", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 89,
   "numbers": {
    "drawing": ["14", "11", "16", "10", "15", "6", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 91,
   "numbers": {
    "drawing": ["32", "24", "13", "13"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 92,
   "numbers": {
    "drawing": ["1", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 93,
   "numbers": {
    "drawing": ["12", "5", "10", "3", "1", "1", "12", "6", "1", "1", "9", "1", "0", "1", "1.4", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 94,
   "numbers": {
    "drawing": ["6", "10", "4", "6", "8", "6", "2", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 95,
   "numbers": {
    "drawing": ["1", "4", "7", "6", "1", "0", "3", "5", "2", "6", "1", "6", "5", "2", "6", "2", "4", "9", "4", "2", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 96,
   "numbers": {
    "drawing": ["2", "10", "6", "5"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 97,
   "numbers": {
    "drawing": ["6", "5", "11", "2", "9", "1.3", "1", "3", "5", "7", "2", "10", "1.3", "0", "5", "5", "10", "2", "9", "1.3", "1", "7", "5", "12", "2", "10", "1.3", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 98,
   "numbers": {
    "drawing": ["0", "7", "6", "2", "5", "1", "4", "6", "2", "5", "0", "4", "6", "2", "5", "1", "7", "6", "2", "5", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 99,
   "numbers": {
    "drawing": ["3", "5", "3", "1", "3", "2.4", "4", "7", "6", "3", "2", "1.6"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 101,
   "numbers": {
    "drawing": ["10", "1", "0", "4", "1", "2", "3", "2", "0", "4", "4", "5", "2", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 102,
   "numbers": {
    "drawing": ["5", ".6", "0", "4.6", ".4", "0", "4", "1.5", "3", "2.2", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 104,
   "numbers": {
    "drawing": ["3", "3", "4", "3", "1.6", "0", "3", "3", "5", "2", "1.5", "0", "1", "4", "2", "7", "1.3", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 105,
   "numbers": {
    "drawing": ["2", "3", "6", "2", "3", "5", "4", "1", "3", "1", "5", "2", "3", "4", "1", "6", "2", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 106,
   "numbers": {
    "drawing": ["1", "2", "2", "1", "2", "3", "4", "3", "2", "4", "5", "2", "4", "3", "1", "6", "1", "0", "2", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 107,
   "numbers": {
    "drawing": ["1", "3", "1", "1", "1", "3", "3", "4", "2", "3", "3", "3", "2", "3", "4", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 108,
   "numbers": {
    "drawing": ["6", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 109,
   "numbers": {
    "drawing": ["2", "1", "1", "2", "1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 112,
   "numbers": {
    "drawing": ["38", "42"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 113,
   "numbers": {
    "drawing": ["10", "28", "37", "4", "4", "37", "3", "3", "37"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 114,
   "numbers": {
    "drawing": ["9", "31", "20", "2", "33", "9", "29", "30", "1", "31", "7", "6", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 115,
   "numbers": {
    "drawing": ["4", "19", "26", "12", "1", "4", "19", "26", "2", "2", "4", "29", "26", "2", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 116,
   "numbers": {
    "drawing": ["15", "15", "12", "10", "3", "17", "26", "3", "0", "6", "26", "5", "8", "1", "9", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 117,
   "numbers": {
    "drawing": ["8", "14", "6", "9", "0", "1", "12", "16", "16", "4"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 118,
   "numbers": {
    "drawing": ["19", "12", "5.4", "5.2", "1", "2", "3", "16", "6", "6", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 119,
   "numbers": {
    "drawing": ["16", "11", "2", "1", "21", "11", "2", "1", "17", "13", "5", "3", "15", "12", "1", "3", "1", "0", "23", "12", "1", "3", "0", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 120,
   "numbers": {
    "drawing": ["17", "11", "21", "11", "17", "13", "5", "2", "18", "13", "3", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 121,
   "numbers": {
    "drawing": ["16", "11", "2", "1", "21", "11", "2", "1", "19", "14"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 124,
   "numbers": {
    "drawing": ["18", "150", "1", "104", "180", "1"]
   },
   "to": {
    "spots": ["frog.inicio", "frog.centro"]
   },
   "note": "the floor rule: the same screen places, on the paving"
  },
  {
   "line": 125,
   "numbers": {
    "drawing": ["48", "51", "40", "44", "49", "56"]
   },
   "to": "unchanged",
   "note": "heights of the sprites (alto), not places"
  },
  {
   "line": 126,
   "numbers": {
    "drawing": ["0", "11", "22"]
   },
   "to": "unchanged",
   "note": "a person's box relative to them: unchanged"
  },
  {
   "line": 127,
   "numbers": {
    "drawing": ["1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 128,
   "numbers": {
    "drawing": ["2", "0", "15", "22", "30", "24"]
   },
   "to": "unchanged",
   "note": "a dog's box relative to it: unchanged"
  },
  {
   "line": 131,
   "numbers": {
    "drawing": ["19", "42", "38", "44", "1"]
   },
   "to": "unchanged",
   "note": "the pushchair's box relative to it: unchanged"
  },
  {
   "line": 132,
   "numbers": {
    "drawing": ["0", "0", "9", "14", "18", "18", "0"]
   },
   "to": "unchanged",
   "note": "the pigeons' box relative to them: unchanged"
  },
  {
   "line": 133,
   "numbers": {
    "drawing": ["0", "24", "1", "72", "48", "74", "0", "0", "7", "34", "14", "1", "28", "0"]
   },
   "to": {
    "things": ["carro", "farol"]
   },
   "note": "the set things' boxes (things.carro, things.farol; the cart's moves with it while it rolls)"
  },
  {
   "line": 134,
   "numbers": {
    "drawing": ["0", "0", "22", "0", "1", "23", "44", "36", "0", "1", "0", "22", "1", "1", "23", "44", "36", "0", "2", "0", "22", "2", "1", "23", "44", "36", "0"]
   },
   "to": {
    "things": ["banco0", "banco1", "banco2"]
   },
   "note": "the benches' boxes (things)"
  },
  {
   "line": 135,
   "numbers": {
    "drawing": ["0", "60", "240", "156", "0"]
   },
   "to": {
    "things": ["parque"]
   },
   "note": "the park's box: unchanged, its hint box (things.parque.hintBox)"
  },
  {
   "line": 140,
   "numbers": {
    "drawing": ["5", "2", "10", "4", "2", "3", "4", "1", "6", "1", "1", "4", "5", "1", "1", "4"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 141,
   "numbers": {
    "drawing": ["7", "8", "14", "5", "6", "7", "12", "3", "5", "0", "5", "0", "4", "6", "2", "5", "0", "4", "0", "4", "5", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 142,
   "numbers": {
    "drawing": ["11", "0", "1", "5", "8", "6", "16", "11", "0", "0", "4", "9", "4", "14", "6", "10", "1", "12", "5", "10", "1", "12"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 143,
   "numbers": {
    "drawing": ["6", "13", "12", "7", "5", "12", "10", "5", "5", "8", "10", "1", "9", "7", "18", "3", "8", "6", "16", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 144,
   "numbers": {
    "drawing": ["8", "0", "0", "3", "5", "4", "11", "8", "0", "1", "2", "4", "2", "9", "6", "0", "0", "2", "6", "3", "3"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 145,
   "numbers": {
    "drawing": ["12", "1", "12", "3", "24", "13", "1", "26", "3", "11", "6", "3", "2", "12", "4", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 146,
   "numbers": {
    "drawing": ["6", "12", "12", "14", "6", "12", "12", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 148,
   "numbers": {
    "drawing": ["3", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 149,
   "numbers": {
    "drawing": ["3", "3", "6", "2", "2", "4", "4", "1", "3", "5", "1", "1", "2", "5", "1", "1", "5", "3", "2", "1", "3", "4", "1", "1", "3", "3", "2", "1", "2", "4", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 150,
   "numbers": {
    "drawing": ["5", "1", "2", "4", "3", "1", "2", "3", "1", "5", "8", "2", "2", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 151,
   "numbers": {
    "drawing": ["4", "1", "3", "1", "1", "1", "3", "1", "4", "3", "1", "1", "3", "1", "3", "3", "6", "2", "2", "4", "4", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 152,
   "numbers": {
    "drawing": ["6", "7", "2", "3", "8", "5", "2", "3", "8", "2", "11", "1", "14", "4", "2", "4", "0", "1", "1", "1", "5", "4", "0", "1", "3", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 153,
   "numbers": {
    "drawing": ["3", "3", "6", "2", "2", "3", "4", "1", "4", "2", "1", "1", "3", "2", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 154,
   "numbers": {
    "drawing": ["1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 155,
   "numbers": {
    "drawing": ["0", "2", "1", "0", "0", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 156,
   "numbers": {
    "drawing": ["48", "0", "17", "4", "12", "3", "1", "1", "12", "3", "1", "14", "16"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 157,
   "numbers": {
    "drawing": ["2", "50", "2", "1", "0", "0", "1", "1", "30", "0", "12", "14"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 158,
   "numbers": {
    "drawing": ["2", "1", "0", "1", "2", "1", "0", "0", "3", "1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 159,
   "numbers": {
    "drawing": ["0", "1", "1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 160,
   "numbers": {
    "drawing": ["11", "11"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 161,
   "numbers": {
    "drawing": ["5", "24", "2", "11", "7", "2", "2.3", "2.45"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 162,
   "numbers": {
    "drawing": ["10", "34", "38"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 163,
   "numbers": {
    "drawing": ["11", "40", "46"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 164,
   "numbers": {
    "drawing": ["8", "24", "16", "9", "7", "25", "14", "7", "25", "1", "7", "27", "29", "6", "5", "1", "2", "4", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 165,
   "numbers": {
    "drawing": ["47", "2", "1", "0", "2", "1", "0", "2", "0", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 166,
   "numbers": {
    "drawing": ["1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 167,
   "numbers": {
    "drawing": ["11", "4", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 169,
   "numbers": {
    "drawing": ["1", "1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 170,
   "numbers": {
    "drawing": ["1", "3", "10", "1", "2", "2.2", "1.9", "1", "2", "21", "2", "1", "17", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 171,
   "numbers": {
    "drawing": ["2", "4", "15", "8"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 172,
   "numbers": {
    "drawing": ["18", "6", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 173,
   "numbers": {
    "drawing": ["3", "2", "13", "3", "1", "2", "14", "5", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 174,
   "numbers": {
    "drawing": ["2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 175,
   "numbers": {
    "drawing": ["0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 176,
   "numbers": {
    "drawing": ["44", "22", "22", "44", "22", "34", "22", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 177,
   "numbers": {
    "drawing": ["130", "65", "65", "130", "65", "16", "65", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 178,
   "numbers": {
    "drawing": ["0", "1", "2", "0", "1", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 179,
   "numbers": {
    "drawing": ["2", "0", "0", "1", "1", "13", "0"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 180,
   "numbers": {
    "drawing": ["16", "1", "17", "12"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 181,
   "numbers": {
    "drawing": ["14", "10"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 182,
   "numbers": {
    "drawing": ["3", "3", "14", "20", "21", "27", "1", "0", "5", "0", "1", "1", "1", "3", "3", "0", "5", "0", "1", "1", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 183,
   "numbers": {
    "drawing": ["1", "0", "5", "5", ".5", "10.5", ".5", ".5"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 184,
   "numbers": {
    "drawing": ["1", "2", "1", "0", "2", "1", "1", "5", "2", "0", "19", "40"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 186,
   "numbers": {
    "drawing": ["3", "3", "27", "2", "3", "3", "1", "28", "3", "3", "1", "1", "27", "4", "3", "3", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 187,
   "numbers": {
    "drawing": ["1", "6", "4", "1", "2", "3", "9", "2", "15", "1", "10", "0", "2", "6", "1", "2", "3", "9", "1", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 188,
   "numbers": {
    "drawing": ["2", "2", "13", "2", "1", "5", "6", "14", "2", "2", "3", "4", "2"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 189,
   "numbers": {
    "drawing": ["2", "3", "12", "2", "2", "1", "18", "4", "2", "1"]
   },
   "to": "unchanged",
   "note": "a sprite's own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged"
  },
  {
   "line": 190,
   "numbers": {
    "drawing": ["2", "2", "0", "0"]
   },
   "to": "unchanged",
   "note": "the bubble drawn twice its size: unchanged"
  },
  {
   "line": 192,
   "numbers": {
    "place": ["0"],
    "other": ["0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, for setKey(W)"
  },
  {
   "line": 193,
   "numbers": {
    "other": ["64", "7", "64", "7", "60", "3", "66", "2"],
    "place": ["26", "9", "0", "26", "8", "0", "22", "3", "28", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the moon: baked into the night sky (setKey luna; points.luna)"
  },
  {
   "line": 194,
   "numbers": {
    "place": ["84", "6", "46", "38", "196", "6", "46", "0", "0", "36", "11", "11", "0", "1", "46", "22", "0", "0"],
    "other": ["38", "0", "7"],
    "offset": ["5", "18"]
   },
   "to": {
    "dropped": true
   },
   "note": "the night (setKey luz noche): its colour laid over the background is the set's night light (set-kit.js lightPass), its lit lantern and pool of light the set's; the patch of sky it copies over the sun (patch) is the night sky's, which has no sun"
  },
  {
   "line": 195,
   "numbers": {
    "other": ["0"],
    "place": ["0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the evening (setKey luz tarde): the set's warm light and evening sky"
  },
  {
   "line": 196,
   "numbers": {
    "count": ["1", "3"],
    "other": ["1.1", "1"],
    "offset": ["30", "1"],
    "place": [".35"],
    "scale": [".5", "34", "7"]
   },
   "to": {
    "moves": [
     "if(pi)pi.x=W.carroX+30;"
    ]
   },
   "note": "moved (moves): the cart rolling away (W.seva); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 198,
   "numbers": {
    "count": ["0", "1"],
    "place": ["1", "0", "1"],
    "other": ["0"],
    "offset": ["24", "72"]
   },
   "to": {
    "moves": [
     "if(W.carro!==0)L.push({y:CARRO[1],d:()=>c.drawImage(spr(\"carro\"+(W.carro===\"cerrado\"?1:0),()=>mkCarro(W.carro===\"cerrado\")),R(W.carroX!=null?W.carroX:CARRO[0])-24,CARRO[1]-72)});"
    ]
   },
   "note": "moved (moves): the cart; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 199,
   "numbers": {
    "count": ["0"],
    "offset": ["8"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 200,
   "numbers": {
    "count": ["0", "0", "2", "0"],
    "other": ["1", "1"],
    "offset": ["1", "12"],
    "place": ["7"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 201,
   "numbers": {
    "count": ["0", "2"],
    "offset": ["1", "13", "9"],
    "scale": ["9", "2"]
   },
   "to": "unchanged",
   "note": "no place: count, offset, scale"
  },
  {
   "line": 202,
   "numbers": {
    "offset": ["9", "1", "6", "1"],
    "place": ["16", "2", "10", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 203,
   "numbers": {
    "count": ["0"]
   },
   "to": "unchanged",
   "note": "no place: count"
  },
  {
   "line": 205,
   "numbers": {
    "offset": ["27"]
   },
   "to": "unchanged",
   "note": "no place: offset"
  },
  {
   "line": 207,
   "numbers": {
    "count": ["0"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 208,
   "numbers": {
    "count": ["1"],
    "offset": ["2"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 210,
   "numbers": {
    "drawing": ["0", "1", "38", "0"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 212,
   "numbers": {
    "drawing": ["1", "0", "1", "2", "2", "0", "3", "0", "1", "10", "11", "0", "1", "9", "3", "0", "9", "2", "0", "8", "4", "3", "8", "7", "4", "3"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 213,
   "numbers": {
    "drawing": ["0", "15", "2", "2", "3", "2", "12", "2", "3", "2"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 215,
   "numbers": {
    "drawing": ["2", "2", "1", "0", ".6", "0", "2", "3"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 217,
   "numbers": {
    "drawing": ["28", "32", "2", "2", "0", "0"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 218,
   "numbers": {
    "drawing": ["31", "31", "2", "2", "0", "0", ".75", ".15"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 219,
   "numbers": {
    "drawing": ["24", "5", "2", "22", "24", "26", "27", "31", "23", "0", "1", "2", "2"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 220,
   "numbers": {
    "drawing": ["24", "10", "1"]
   },
   "to": "unchanged",
   "note": "the frog's doing bubbles, the music note, talkAt's offset over the head: relative, unchanged"
  },
  {
   "line": 222,
   "numbers": {
    "drawing": ["3", "3", "66", "24"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 223,
   "numbers": {
    "drawing": ["10", "20", "6"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 224,
   "numbers": {
    "drawing": ["0", "1", "1", "3", "3", "0", "2", "1", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 225,
   "numbers": {
    "drawing": ["0", "11", "1", "4", "3", "10", "1", "4", "3", "0", "11", "1", "2", "2", "1", "11", "2", "2", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 226,
   "numbers": {
    "drawing": ["1", "13", "12", "1", "1", "1", "1", "12", "12", "1", "1", "12", "1", "1", "12", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 227,
   "numbers": {
    "drawing": ["0"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 230,
   "numbers": {
    "count": ["3", "3", "1"],
    "scale": ["5"],
    "state": ["0", "1", "1", "0"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, scale, state, offset"
  },
  {
   "line": 231,
   "numbers": {
    "place": ["0", "1"],
    "count": ["0"],
    "scale": ["10"],
    "offset": ["11"],
    "state": ["1", "1"]
   },
   "to": {
    "moves": [
     "await mueve(id,q[0]+(lado||0)*10,q[1]+11);"
    ]
   },
   "note": "moved (moves): sienta; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 232,
   "numbers": {
    "count": ["5", "3", "1"],
    "scale": ["9", "8"],
    "order": ["400"],
    "offset": ["1"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, scale, order, offset, state"
  },
  {
   "line": 233,
   "numbers": {
    "count": ["4", "8", "2", "3", "1"],
    "other": ["4"],
    "offset": ["1"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, other, offset, state"
  },
  {
   "line": 234,
   "numbers": {
    "time": ["1500", "0", ".05", ".04", "1900", "1300", ".07", ".05", ".04", "1700"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 235,
   "numbers": {
    "sound": ["0", "1", "520", ".26", ".07", ".05", "300", "400", ".26", ".07", ".1", ".05", "240"]
   },
   "to": "unchanged",
   "note": "a sound"
  },
  {
   "line": 238,
   "numbers": {
    "other": ["149"],
    "place": ["110", "127", "158", "127", "176", "127", "208", "127", "182", "188", "195", "196", "183", "209", "196", "211"]
   },
   "to": {
    "moves": [
     "POSA=[[110,127],[158,127],[176,127],[208,127]]"
    ],
    "spots": ["respaldo.0", "respaldo.1", "respaldo.2", "respaldo.3"]
   },
   "note": "ASIENTO: a thing put on a seat (AS, moves); POSA: the pigeons on the backs (moved); JUGEN: where the toys land from the pushchair: the floor rule (on the paving, the last two on the path out through the gate)"
  },
  {
   "line": 239,
   "numbers": {
    "offset": ["16", "27"]
   },
   "to": "unchanged",
   "note": "the frog's middle and feet relative to q: unchanged"
  },
  {
   "line": 240,
   "numbers": {
    "scale": ["16", "27", "34"],
    "count": ["3", "1", "4"],
    "offset": ["16", "27"]
   },
   "to": "unchanged",
   "note": "ranaA: q relative to the point; the hop count by the distance (34 px a hop): unchanged"
  },
  {
   "line": 241,
   "numbers": {
    "place": ["0", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 242,
   "numbers": {
    "offset": ["30", "1"],
    "state": ["1", "1"],
    "time": ["250", "300"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time"
  },
  {
   "line": 246,
   "numbers": {
    "place": ["0", "1"],
    "count": ["2", "1"],
    "offset": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 247,
   "numbers": {
    "count": ["3", "0", "0"],
    "offset": ["1"],
    "place": ["0", "1"],
    "order": ["140"],
    "state": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 248,
   "numbers": {
    "other": ["0"],
    "count": ["4"],
    "time": ["150"]
   },
   "to": "unchanged",
   "note": "no place: other, count, time"
  },
  {
   "line": 250,
   "numbers": {
    "sound": ["0", ".24", ".48", "760", ".2", ".07", "520"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 251,
   "numbers": {
    "sound": ["0", ".12", ".24", ".36", "420", "2", "90", ".09", ".05", "380"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 252,
   "numbers": {
    "sound": ["0", ".3", "330", ".24", ".08", "240"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 253,
   "numbers": {
    "sound": ["620", "0", ".45", ".07", "860"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 254,
   "numbers": {
    "sound": ["120", "0", ".45", ".05", "90"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 255,
   "numbers": {
    "sound": ["0", ".5", "1400", ".09", ".025", "1500", "2100", ".12", ".14", ".025", "2500"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 256,
   "numbers": {
    "sound": ["0", ".14", "900", ".04", ".06", "500"]
   },
   "to": "unchanged",
   "note": "sounds"
  },
  {
   "line": 257,
   "numbers": {
    "count": ["0", "3", "3"],
    "state": ["1", "0"],
    "time": ["350"]
   },
   "to": "unchanged",
   "note": "no place: count, state, time"
  },
  {
   "line": 258,
   "numbers": {
    "offset": ["30", "1", "30", "30"],
    "order": ["400"],
    "state": ["1"],
    "count": ["8"],
    "scale": ["8", "16"],
    "place": ["0", "1", "0", "1"],
    "time": ["450"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 259,
   "numbers": {
    "state": ["0", "1", "0"],
    "time": ["1500", "300"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 263,
   "numbers": {
    "time": ["250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 266,
   "numbers": {
    "other": ["21"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 267,
   "numbers": {
    "place": ["0", "1", "62", "206", "0", "0", "161", "1", "0", "161", "2", "0", "161"],
    "offset": ["4", "6", "9", "9"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1"]
   },
   "to": {
    "moves": [
     "hombre:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[2][0],y:161,dir:1,sent:1}"
    ]
   },
   "note": "moved (moves): acts.inicio21; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 268,
   "numbers": {
    "place": ["0", "1", "2", "3", "4", "0", "1", "124", "206", "0", "1"],
    "count": ["2", "1"],
    "offset": ["1", "16", "27"],
    "state": ["1", "1", "0"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 269,
   "numbers": {
    "time": ["250", "300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 270,
   "numbers": {
    "offset": ["26", "22"],
    "state": ["1"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time"
  },
  {
   "line": 271,
   "numbers": {
    "offset": ["26", "22", "30"],
    "state": ["1", "4", "1", "0"],
    "time": ["300", "900"],
    "order": ["400"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time, order"
  },
  {
   "line": 272,
   "numbers": {
    "state": ["1", "1"],
    "place": ["101", "153"],
    "offset": ["4"],
    "scale": ["2"],
    "time": ["500"]
   },
   "to": {
    "moves": [
     "{id:\"pir\",k:\"piragua\",x:101,y:ASIENTO-4,rot:Math.PI/2},{id:\"bot\",k:\"agua\",x:153,y:ASIENTO}"
    ]
   },
   "note": "moved (moves): acts.dejan; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 273,
   "numbers": {
    "place": ["104", "182", "150", "182", "62", "206"],
    "time": ["250", "250", "500"],
    "state": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 274,
   "numbers": {
    "place": ["119", "163"],
    "state": ["1", "1"],
    "order": ["152"],
    "time": ["700"]
   },
   "to": {
    "moves": [
     "await palomaA(pg,119,ASIENTO);",
     "await palomaA(pg,163,ASIENTO);"
    ]
   },
   "note": "moved (moves): acts.paloma; acts.paloma; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 275,
   "numbers": {
    "state": ["0", "1", "3", "0"],
    "time": ["150", "250"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 276,
   "numbers": {
    "state": ["0", "1"],
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 277,
   "numbers": {
    "state": ["0", "1"],
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 278,
   "numbers": {
    "place": ["104", "182", "150", "182", "62", "206"],
    "state": ["1"],
    "other": ["1"],
    "time": ["200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 279,
   "numbers": {
    "time": ["150"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 282,
   "numbers": {
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 283,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 284,
   "numbers": {
    "place": ["0", ".2", ".4", "0", ".25", ".5"],
    "time": ["300", ".05", ".03", "240", "500", ".08", ".04", "380", "650"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 285,
   "numbers": {
    "time": ["350", "250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 288,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 289,
   "numbers": {
    "offset": ["1", "9"],
    "other": ["1"],
    "state": ["5", "0"],
    "time": ["500", "1100", "400", "300"],
    "scale": ["17"],
    "order": ["400"],
    "count": ["0"]
   },
   "to": "unchanged",
   "note": "no place: offset, other, state, time, scale, order, count"
  },
  {
   "line": 290,
   "numbers": {
    "offset": ["3", "9", "10"],
    "state": ["1"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time"
  },
  {
   "line": 291,
   "numbers": {
    "offset": ["1"],
    "other": ["1"],
    "order": ["400"]
   },
   "to": "unchanged",
   "note": "no place: offset, other, order"
  },
  {
   "line": 292,
   "numbers": {
    "scale": ["22"],
    "other": ["4"],
    "time": ["450", "350"]
   },
   "to": "unchanged",
   "note": "no place: scale, other, time"
  },
  {
   "line": 293,
   "numbers": {
    "scale": ["17"],
    "offset": ["9"],
    "other": ["4"],
    "time": ["1000", "300"]
   },
   "to": "unchanged",
   "note": "no place: scale, offset, other, time"
  },
  {
   "line": 294,
   "numbers": {
    "scale": ["17", "26", "2", "36"],
    "offset": ["9", "3"],
    "other": ["4", "1", "3"],
    "time": ["1000"]
   },
   "to": "unchanged",
   "note": "no place: scale, offset, other, time"
  },
  {
   "line": 296,
   "numbers": {
    "count": ["0", "1"],
    "offset": ["46", "2"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "cx()+46,pies()+2"
    ]
   },
   "note": "moved (moves): acts.final21"
  },
  {
   "line": 297,
   "numbers": {
    "count": ["4", "4", "4", "4", "0", "1"],
    "place": ["34", "2", "22", "12", "26", "14", "44", "6", "0", "1", "0"],
    "offset": ["1"],
    "time": ["400"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 298,
   "numbers": {
    "state": ["2"],
    "time": ["200", "300"],
    "scale": ["3"]
   },
   "to": "unchanged",
   "note": "no place: state, time, scale"
  },
  {
   "line": 299,
   "numbers": {
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 301,
   "numbers": {
    "other": ["22"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 302,
   "numbers": {
    "place": ["0", "1", "0", "0", "161", "1", "0", "161", "2", "0", "161", "0", "0", "161", "176", "208", "148", "186"],
    "offset": ["4", "6", "9", "9", "9", "11"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1"],
    "other": ["1"]
   },
   "to": {
    "moves": [
     "senor:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},joven:{x:B[2][0]-9,y:161,dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:161,dir:1,sent:1,lee:1}",
     "carmen:{x:176,y:208,dir:-1}",
     "luis:{x:148,y:186,dir:1}"
    ]
   },
   "note": "moved (moves): acts.inicio22; acts.inicio22; acts.inicio22; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 303,
   "numbers": {
    "place": ["72", "163", "157", "204", "167", "187"],
    "offset": ["1"]
   },
   "to": {
    "moves": [
     "{id:\"cartera\",k:\"cartera\",x:157,y:ASIENTO},{id:\"mochila\",k:\"mochila\",x:204,y:ASIENTO+1}",
     "{id:\"caja\",k:\"caja\",x:167,y:187}"
    ]
   },
   "note": "moved (moves): acts.inicio22; acts.inicio22; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 304,
   "numbers": {
    "place": ["90", "193", "38", "193", "0", "1", "2", "3", "4", "0", "1"],
    "state": ["1", "1"],
    "count": ["2", "1"],
    "offset": ["1"]
   },
   "to": {
    "moves": [
     "W.perros={viejo:{x:90,y:193,pose:\"sit\",dir:1},joven:{x:38,y:193,pose:\"sit\",dir:1}}"
    ]
   },
   "note": "moved (moves): acts.inicio22; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 305,
   "numbers": {
    "place": ["124", "205", "0", "1"],
    "offset": ["16", "27"],
    "state": ["1", "1"]
   },
   "to": {
    "moves": [
     "W.casa=[124,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;"
    ]
   },
   "note": "moved (moves): acts.inicio22 (senor-senora); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 306,
   "numbers": {
    "place": ["80", "184", "96", "188", "112", "184", "0", "1"],
    "state": ["1"],
    "time": ["400"]
   },
   "to": {
    "moves": [
     "const en={senor:[80,184],mujer:[96,188],joven:[112,184]}"
    ]
   },
   "note": "moved (moves): acts.alcarro; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 307,
   "numbers": {
    "other": ["0", "1", "2"],
    "state": ["1", "3", "0"],
    "time": ["350", "160", "250"],
    "place": ["0", "172"],
    "offset": ["9"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 308,
   "numbers": {
    "place": ["0", "9", "1", "9", "2", "9", "0", "0", "1", "0", "2", "161", "3"],
    "state": ["1", "1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "await mueve(k[0],B[k[1]][0]+k[2],161);"
    ]
   },
   "note": "moved (moves): acts.sientan; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 309,
   "numbers": {
    "place": ["122", "174", "158", "210"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "mueve(\"carmen\",158,210)"
    ]
   },
   "note": "moved (moves): bolsa, hueso; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 310,
   "numbers": {
    "offset": ["2", "22", "25", "1"],
    "count": ["1"],
    "time": ["400"]
   },
   "to": "unchanged",
   "note": "no place: offset, count, time"
  },
  {
   "line": 311,
   "numbers": {
    "place": ["146", "176", "158", "210"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "mueve(\"carmen\",158,210)"
    ]
   },
   "note": "moved (moves): bolsa, hueso; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 312,
   "numbers": {
    "offset": ["30", "4"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: offset, time"
  },
  {
   "line": 313,
   "numbers": {
    "count": ["0"],
    "other": ["1"],
    "state": ["1"],
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: count, other, state, time"
  },
  {
   "line": 314,
   "numbers": {
    "count": ["0"],
    "other": ["1"],
    "state": ["1"],
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: count, other, state, time"
  },
  {
   "line": 315,
   "numbers": {
    "state": ["0", "0"],
    "place": ["108", "0", "1", "244", "1"],
    "time": ["400", "300"]
   },
   "to": {
    "moves": [
     "{id:\"periodico\",k:\"periodico\",x:108,y:ASIENTO}",
     "244,PORTON[1])"
    ]
   },
   "note": "moved (moves): acts.turno22; as 246, PORTON[1] (turno22); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 316,
   "numbers": {
    "state": ["1", "1"],
    "time": ["300", "200"],
    "place": ["112", "178", "0", "1"],
    "offset": ["4", "2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 317,
   "numbers": {
    "other": ["0"],
    "count": ["3"],
    "time": ["160", "300"],
    "place": ["148", "186"],
    "state": ["1"]
   },
   "to": {
    "moves": [
     "mueve(\"luis\",148,186)"
    ]
   },
   "note": "moved (moves): luiscaja, luisguarda; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 318,
   "numbers": {
    "place": ["36", "193", "64", "194", "100", "205"],
    "state": ["1", "1"]
   },
   "to": {
    "moves": [
     "W.casa=[100,205];",
     "perroA(\"viejo\",36,193,\"walk\"),perroA(\"joven\",64,194,\"run\")"
    ]
   },
   "note": "moved (moves): acts.sale22; acts.sale22; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 319,
   "numbers": {
    "state": ["0", "1"],
    "offset": ["4", "8", "22", "22", "4"],
    "place": ["176", "3", "3"],
    "order": ["400"],
    "count": ["6"],
    "scale": ["26", "6"],
    "time": ["90", "350"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 320,
   "numbers": {
    "place": ["0", "1"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 321,
   "numbers": {
    "state": ["1", "3", "0"],
    "time": ["300", "160", "200"],
    "offset": ["10", "2"]
   },
   "to": "unchanged",
   "note": "no place: state, time, offset"
  },
  {
   "line": 322,
   "numbers": {
    "state": ["1", "0"],
    "time": ["600"],
    "place": ["0", "1", "246", "1"]
   },
   "to": {
    "moves": [
     "246,PORTON[1])"
    ]
   },
   "note": "moved (moves): whoever leaves walks to (246, PORTON[1] + 12); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 323,
   "numbers": {
    "place": ["0", "1", "0", "1"],
    "offset": ["8"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "await mueve(o.a,PORTON[0]+8,PORTON[1]);"
    ]
   },
   "note": "moved (moves): acts.pasa; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 324,
   "numbers": {
    "count": ["0", "1"],
    "state": ["3", "0"],
    "time": ["200"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, state, time, offset"
  },
  {
   "line": 325,
   "numbers": {
    "state": ["1", "1", "0"],
    "time": ["700"],
    "place": ["246", "1"]
   },
   "to": {
    "moves": [
     "p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;},",
     "246,PORTON[1])"
    ]
   },
   "note": "moved (moves): acts.sevade; whoever leaves walks to (246, PORTON[1] + 12); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 326,
   "numbers": {
    "offset": ["10", "6", "22"],
    "state": ["0", "1"],
    "place": ["148", "186"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "mueve(\"luis\",148,186)"
    ]
   },
   "note": "moved (moves): luiscaja, luisguarda; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 327,
   "numbers": {
    "place": ["38", "193", "90", "193", "0", "1", "0", "1"],
    "state": ["0", "0", "1", "1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "L=[38,193],D=[90,193]"
    ]
   },
   "note": "moved (moves): acts.perros22; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 328,
   "numbers": {
    "state": ["1"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 329,
   "numbers": {
    "offset": ["30", "4"],
    "time": ["4", "500"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: offset, time, state"
  },
  {
   "line": 330,
   "numbers": {
    "count": ["0", "1"],
    "other": ["1", "0"],
    "place": ["82", "186", "104", "186"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 331,
   "numbers": {
    "place": ["0", "1", "128", "205", "0", "1"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 332,
   "numbers": {
    "count": ["0"],
    "scale": ["350"],
    "place": ["0", "1", "246", "1"],
    "state": ["0"]
   },
   "to": {
    "moves": [
     "246,PORTON[1])"
    ]
   },
   "note": "moved (moves): whoever leaves walks to (246, PORTON[1] + 12); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 333,
   "numbers": {
    "state": ["7", "1", "0", "0"],
    "time": ["500", "700"],
    "place": ["246", "1"]
   },
   "to": {
    "moves": [
     "p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;W.cq.dy=0;",
     "246,PORTON[1])"
    ]
   },
   "note": "moved (moves): acts.alza; whoever leaves walks to (246, PORTON[1] + 12); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 334,
   "numbers": {
    "state": ["1", "1", "1", "1", "1", "0", "1", "1"],
    "place": ["124", "190", "190", "204", "244", "1", "0", "1", "246", "1"],
    "time": ["500", "200", "400", "700", "300"],
    "offset": ["4", "20"],
    "other": ["0"],
    "count": ["3"]
   },
   "to": {
    "moves": [
     "mueve(\"carmen\",190,204)",
     "h.pose=\"idle\";await mueve(\"hombre\",246,PORTON[1]);h.vis=0;}else",
     "246,PORTON[1])"
    ]
   },
   "note": "moved (moves): acts.final22; acts.final22; whoever leaves walks to (246, PORTON[1] + 12); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 335,
   "numbers": {
    "time": ["400", "300"],
    "place": ["0", "1", "0", "196", "204"],
    "offset": ["30", "2"],
    "state": ["1", "1", "0", "0", "1", "1"],
    "other": ["70", "0", "0"],
    "count": ["1", "1"]
   },
   "to": {
    "moves": [
     "v.y=196;j.y=204;"
    ]
   },
   "note": "moved (moves): acts.carrova; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 336,
   "numbers": {
    "state": ["2", "0", "1", "1", "1", "3"],
    "time": ["900", "1400"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 338,
   "numbers": {
    "other": ["23"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 339,
   "numbers": {
    "place": ["0", "1", "1", "0", "161", "0", "0", "161", "2", "0", "161", "38", "210"],
    "offset": ["4", "6", "9", "13", "2"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1"]
   },
   "to": {
    "moves": [
     "senora:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[0][0]-13,y:161,dir:1,sent:1,animo:\"cansado\"},hombre:{x:B[2][0]+2,y:161,dir:1,sent:1,animo:\"triste\"}"
    ]
   },
   "note": "moved (moves): acts.inicio23; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 340,
   "numbers": {
    "place": ["164", "176", "112", "208", "184", "178"],
    "state": ["0", "1", "0", "0"],
    "other": ["1"],
    "scale": ["2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 341,
   "numbers": {
    "place": ["0", "1", "2", "3", "4", "0", "1", "156", "207", "0", "1"],
    "count": ["2", "1"],
    "offset": ["1", "16", "27"],
    "state": ["1", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 342,
   "numbers": {
    "place": ["70", "190"],
    "offset": ["4", "26", "22", "2"],
    "time": ["700"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 343,
   "numbers": {
    "place": ["0", "0", "180", "0", "0", "38", "210"],
    "offset": ["4", "21", "1"],
    "order": ["150"],
    "time": ["400"],
    "state": ["1"]
   },
   "to": {
    "moves": [
     "{id:\"cojin\",k:\"mochila\",x:B[0][0]-21,y:ASIENTO+1,z:150}"
    ]
   },
   "note": "moved (moves): acts.cojin; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 344,
   "numbers": {
    "place": ["250", "204", "0", "0", "176", "0", "0", "161", "124", "180"],
    "state": ["1", "1", "1", "1", "1", "1"],
    "offset": ["6", "5"],
    "time": ["400", "300"],
    "other": ["1"]
   },
   "to": {
    "moves": [
     "a.x=B[0][0]+5;a.y=161;",
     "W.gente.abuela={x:250,y:204,dir:-1,paso:1}"
    ]
   },
   "note": "moved (moves): acts.abuelallega; acts.abuelallega; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 345,
   "numbers": {
    "time": ["350", "250"],
    "state": ["0"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: time, state, other"
  },
  {
   "line": 346,
   "numbers": {
    "other": ["1"],
    "time": ["600"]
   },
   "to": "unchanged",
   "note": "no place: other, time"
  },
  {
   "line": 347,
   "numbers": {
    "other": ["0"],
    "count": ["2"],
    "place": ["196", "208", "124", "180"],
    "state": ["1"],
    "time": ["500"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 348,
   "numbers": {
    "time": ["350", "500"],
    "place": ["0", "0", "160"],
    "offset": ["19"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 349,
   "numbers": {
    "count": ["1", "7", "6", "2"],
    "other": ["0", "0", "30", "0", "1"],
    "offset": ["16", "16", "14", "2"],
    "place": ["178", "178", "124", "180"],
    "state": ["1", "1"],
    "scale": ["7", "7"],
    "time": ["200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 350,
   "numbers": {
    "other": ["0"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: other, time"
  },
  {
   "line": 351,
   "numbers": {
    "time": ["300", "400"],
    "state": ["1"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: time, state, other"
  },
  {
   "line": 352,
   "numbers": {
    "time": ["600", "400"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: time, other"
  },
  {
   "line": 354,
   "numbers": {
    "other": ["1", "1"],
    "state": ["3", "0"],
    "time": ["400"]
   },
   "to": "unchanged",
   "note": "no place: other, state, time"
  },
  {
   "line": 355,
   "numbers": {
    "offset": ["16"],
    "place": ["178", "8", "2.5", "3"],
    "state": ["1", "0"],
    "count": ["7", "4"],
    "time": ["600"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 356,
   "numbers": {
    "other": ["1", "1"],
    "state": ["0", "0"],
    "count": ["8", "2", "3"],
    "offset": ["3"],
    "time": ["90", "700"]
   },
   "to": "unchanged",
   "note": "no place: other, state, count, offset, time"
  },
  {
   "line": 357,
   "numbers": {
    "other": ["1", "0", "1"],
    "time": ["700", "220", "160"],
    "count": ["2"],
    "state": ["7", "0"]
   },
   "to": "unchanged",
   "note": "no place: other, time, count, state"
  },
  {
   "line": 358,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 359,
   "numbers": {
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: state"
  },
  {
   "line": 360,
   "numbers": {
    "state": ["1", "1"],
    "time": ["300", "350"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 361,
   "numbers": {
    "place": ["4", "4"],
    "time": ["700", "250"]
   },
   "to": {
    "moves": [
     "s.x+=4;await wait(700);s.x-=4;"
    ]
   },
   "note": "moved (moves): acts.mira23; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 362,
   "numbers": {
    "time": ["400"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 363,
   "numbers": {
    "time": ["1300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 364,
   "numbers": {
    "time": ["1300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 365,
   "numbers": {
    "state": ["0", "0"],
    "place": ["0", ".12", ".24"],
    "time": ["900", "120", ".07", ".03", "1100", "800"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 366,
   "numbers": {
    "state": ["0", "0"],
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 369,
   "numbers": {
    "state": ["0", "1", "1"],
    "time": ["500", "300", "400"],
    "place": ["92", "192"],
    "offset": ["14", "33"],
    "order": ["400"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 370,
   "numbers": {
    "time": ["8", "200", "500"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 371,
   "numbers": {
    "time": ["300"],
    "state": ["0"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: time, state, other"
  },
  {
   "line": 372,
   "numbers": {
    "place": ["190", "204", "150", "150", "196", "204", "124", "199"],
    "time": ["200", "250"],
    "state": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 373,
   "numbers": {
    "time": ["500", "300", "900", "500"],
    "place": ["70", "196"],
    "scale": ["2"],
    "state": ["1", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 374,
   "numbers": {
    "place": ["0", "0", "184"],
    "offset": ["8", "46", "2", "13", "1", "1"],
    "state": ["1"],
    "time": ["400"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 376,
   "numbers": {
    "offset": ["2", "24"],
    "state": ["2", "0", "3", "0"],
    "time": ["200", "140", "140"],
    "other": ["0"],
    "count": ["3"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time, other, count"
  },
  {
   "line": 378,
   "numbers": {
    "offset": ["4", "24", "36", "22", "2"]
   },
   "to": "unchanged",
   "note": "no place: offset"
  },
  {
   "line": 379,
   "numbers": {
    "place": ["0", "0", "184", "0", "0", "184"],
    "offset": ["8", "8"],
    "state": ["0", "3", "0", "2", "0", "1"],
    "time": ["700", "700"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 380,
   "numbers": {
    "place": ["70", "190"],
    "time": ["500", "400", "300"],
    "state": ["4", "0"],
    "other": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 381,
   "numbers": {
    "other": ["0"],
    "count": ["2"],
    "state": ["5", "0", "2", "0", "3", "0"],
    "time": ["150", "150", "700", "700"]
   },
   "to": "unchanged",
   "note": "no place: other, count, state, time"
  },
  {
   "line": 383,
   "numbers": {
    "place": ["0", "0", "180"],
    "offset": ["6", "30", "2", "13", "1", "1"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 384,
   "numbers": {
    "place": ["70", "196"],
    "offset": ["18", "4"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 385,
   "numbers": {
    "place": ["38", "210"],
    "state": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 386,
   "numbers": {
    "count": ["0"],
    "state": ["0", "0", "0", "0"],
    "time": ["400", "300"],
    "place": ["0", "0", "180"],
    "offset": ["10"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 387,
   "numbers": {
    "count": ["1"],
    "place": ["0"],
    "offset": ["14", "6", "28", "10"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 388,
   "numbers": {
    "place": ["0"],
    "offset": ["12", "2"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 390,
   "numbers": {
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 391,
   "numbers": {
    "place": ["250", "200", "250", "206", "250", "196", "250", "210", "232", "204", "4"],
    "time": ["500"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",250,200),mueve(\"carmen\",250,206),mueve(\"luis\",250,196),perroA(\"canelo\",250,210"
    ]
   },
   "note": "moved (moves): acts.sevan23; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 395,
   "numbers": {
    "count": ["4"],
    "scale": ["2"],
    "state": ["1", "1", "0"]
   },
   "to": "unchanged",
   "note": "no place: count, scale, state"
  },
  {
   "line": 396,
   "numbers": {
    "time": ["750"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 397,
   "numbers": {
    "other": ["0"],
    "count": ["2", "4"],
    "time": ["130", "130"],
    "state": ["0"]
   },
   "to": "unchanged",
   "note": "no place: other, count, time, state"
  },
  {
   "line": 399,
   "numbers": {
    "place": ["0", "1", "236", "1", "2"],
    "offset": ["4", "2", "2"],
    "state": ["0"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 400,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 402,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 403,
   "numbers": {
    "count": ["0"],
    "time": ["150"]
   },
   "to": "unchanged",
   "note": "no place: count, time"
  },
  {
   "line": 404,
   "numbers": {
    "count": ["10"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, state"
  },
  {
   "line": 405,
   "numbers": {
    "state": ["1"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 406,
   "numbers": {
    "other": ["0"],
    "count": ["3"],
    "place": ["6", "10", "6", "0"],
    "time": ["60"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)"
  },
  {
   "line": 407,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 408,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 409,
   "numbers": {
    "count": ["1", "1"],
    "other": ["0"],
    "state": ["3", "0"],
    "time": ["140", "140"]
   },
   "to": "unchanged",
   "note": "no place: count, other, state, time"
  },
  {
   "line": 410,
   "numbers": {
    "state": ["1", "0", "1"],
    "time": ["1500"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 413,
   "numbers": {
    "count": ["1"]
   },
   "to": "unchanged",
   "note": "acts.prueba: a test act no story of this scene calls (only la-foto, another scene, names \"prueba\"): its places unchanged; whoever sits there sits at the old 161"
  },
  {
   "line": 414,
   "numbers": {
    "place": ["0", "1", "0", "1", "2", "3", "4", "0", "1"],
    "offset": ["4", "6", "1"],
    "state": ["1"],
    "count": ["2", "1"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 415,
   "numbers": {
    "count": ["5", "4", "2", "0"],
    "state": ["0", "1", "0"],
    "place": ["50", "160"],
    "scale": ["46", "26"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 416,
   "numbers": {
    "count": ["2"],
    "place": ["0", "0", "0", "1", "1", "0", "1", "1", "2", "0", "2", "1", "2", "0", "2", "1", "186", "200", "150", "204"],
    "offset": ["8", "11", "8", "11", "10", "11", "11", "11"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 417,
   "numbers": {
    "place": ["112", "180", "40", "204", "68", "206", "0", "206", "1", "0", "1", "1"],
    "state": ["1", "1", "1"],
    "offset": ["14", "5"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 418,
   "numbers": {
    "place": ["0", "0", "0", "1", "0", "0", "161", "1", "0", "1", "1", "2", "0", "2", "1", "52", "208"],
    "offset": ["13", "11", "5", "9", "11", "2", "11"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1", "1", "1"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 419,
   "numbers": {
    "place": ["130", "175", "164", "176", "124", "180", "0", "0", "160"],
    "state": ["1", "1"],
    "count": ["0", "0", "0"],
    "offset": ["19"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 420,
   "numbers": {
    "place": ["0", "1"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "acts.prueba (a test act no story calls): unchanged"
  },
  {
   "line": 422,
   "numbers": {
    "other": ["300"]
   },
   "to": "unchanged",
   "note": "stake, poke and estado: sounds and the state line, no place"
  },
  {
   "line": 424,
   "numbers": {
    "other": ["0", "0", "0", "0"]
   },
   "to": "unchanged",
   "note": "stake, poke and estado: sounds and the state line, no place"
  },
  {
   "line": 425,
   "numbers": {
    "place": ["22", "0", "196", "216", "110", "30"]
   },
   "to": {
    "view": "wide",
    "point": "corazon"
   },
   "note": "the view (views.wide) and the heart (points.corazon): unchanged"
  },
  {
   "line": 426,
   "numbers": {
    "place": ["120", "64", "0", "1"],
    "state": ["0", "0", "1", "0", "0", "0", "1", "0", "1", "1"]
   },
   "to": "unchanged",
   "note": "respEn (where the answer cards stand: the sky over the frog's place) and the frog's first place: unchanged"
  },
  {
   "line": "juego.js:16",
   "to": "unchanged",
   "note": "fresh(): not used here: banco's fresh() puts the frog at LUGAR.centro"
  },
  {
   "line": "cual.js:21",
   "to": "unchanged",
   "note": "panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "code: banco.js read here: 331 lines hold numbers, every one with its entry; 486 numbers are places on the picture, each named in its line's entry with what becomes of it (moved, the floor rule, a set thing, dropped); 2847 are not places (other 89, scale 37, offset 179, dropped 215, drawing 1701, count 101, state 260, order 10, time 192, sound 63: each line's entry lists them by kind)",
   "inventory: 20 things (old 20), 2 frog places of LUGAR (old 2), 1 view (old 1), 62 positions (old 62), 12 review pairs of cual-banco (24 pictures here; none is another scene's), 16 level pictures (old 16), 7 baked states reached (the old 49)",
   "hops (round 4): every walk of the frog in the 18 runs, at any moment (107 calls of hopTo, the old page's run and the port's walk by walk): each the old number of hops (0 differ)",
   "hops: the frog's 86 walks between steps in the 18 runs, recorded and the port's, each the old number of hops (26 distinct walks; 0 changed)",
   "boxes, two touch things side by side (as the old, whose lamp post's box also reached over the second bench's end): banco1 -> farol 24 px, banco2 -> farol 24 px",
   "boxes: every pixel of each set thing inside its touch box in every baked state (nothing sways): carro [27,93,43,91], farol [168,31,12,111], banco0 [80,125,41,43], banco1 [128,124,41,44], banco2 [176,124,30,39]; every pixel answers its own thing in the hit order (the wire answers the lamp only where it hangs from it, 8 px); no two boxes overlap; the trees, the hedge, the gate, the pole and the wire are the park's",
   "shadows of the set: 1580 castShadow calls over the 12 states, each with strength 1 and a radius, none at night; each casting part darkens pixels, its shadow joined to it; the thin pole, lamp post and gate posts only a contact shadow at their foot: arbol0 960 px, arbol1 960 px, arbol2 690 px, poste 78 px, farol 84 px, carro 1100 px, banco0 1554 px, banco1 1554 px, banco2 834 px, seto 888 px, porton 222 px",
   "the lamp's pool (evening and night): 3628 and 3628 px round its foot, joined to it, none by day; the trees' crown shades (day and evening), lighter and solid, on the lawn only",
   "sides: 20565 ticks inside the acts of the port's play of the 18 runs, every step's end and every pair picture: 117257 rests (300 ms or more in one place) on the ground, each clearly on one side with 6 px of that ground round its foot: on the paving (abuela, carmen, coche, cosa billetera, cosa bola, cosa caida, cosa caja, cosa cojin, cosa hielo, cosa jug0, cosa jug1, cosa jug2, cosa jug3, cosa sombrilla, hombre, joven, luis, mujer, paloma 1, paloma 2, paloma 3, perro canelo, perro joven, perro viejo, piraguero, senor, senora, the frog), on the lawn (none); 3907 moments of someone beyond the hedge's line (on the pavement outside), 205 crossings of it, each in the gate's opening",
   "sitting: 50312 moments of someone on a bench: the seat under the lap, the feet over the paving, nothing of the bench nearer than them (its back behind them); 10621 moments of a thing or a pigeon on a seat, on it",
   "pigeons: 87478 wire, 1434 air, 1086 ground, 49 coche, 602 seat, 243 frog, 4698 back (moments): on the wire with the wire under their feet, on a back with its top under them; 1434 moments in the air, each with its shadow on the ground (helps)",
   "behind a front part, drawn over them by front: piraguero behind carro, paloma 2 behind porton, senor behind banco0, senor behind porton, senor behind seto, mujer behind banco1, mujer behind porton, luis behind porton, luis behind seto, carmen behind porton, carmen behind seto, cosa bola behind seto, cosa bola behind porton, perro canelo behind seto, perro canelo behind porton, abuela behind porton, abuela behind seto, the frog behind porton, the frog behind seto, coche behind porton, cosa caida behind porton, luis behind banco0, cosa jug0 behind porton, paloma 0 behind porton, senora behind banco1, senora behind porton, cosa sombrilla behind carro, cosa caja behind porton, mujer behind banco0, joven behind banco1, joven behind porton, joven behind banco2, hombre behind banco0, hombre behind porton, hombre behind seto, mujer behind seto, joven behind seto; nobody has another part of the set nearer than them",
   "bubbles: 7486 bubbles at 21886 moments (each person's recorded one and \"amor\" when touched, the frog's): wholly inside the view (0 px from its edge at the least), clear of the rounds card, on no face; but where no place is free the \"amor\" of a touch keeps the old place, as the old (abuela \"amor\" (el-bebe-duerme wrong), luis \"amor\" (el-bebe-duerme wrong), hombre \"amor\" (senor-senora right), mujer \"amor\" (senor-senora right), mujer \"amor\" (senor-senora wrong))",
   "drawn (round 2): at 21910 moments the sorted list composed as it is drawn (each item owns what it drew last; a front part drawn again only over an owner behind it): no bench drawn over whoever sits on it or what lies on its seat (50312 sittings), the lamp post drawn over nobody and nothing, no part of the set (a bench, the cart, the lamp post, the pole, the hedge, a gate post) over any face (so every sitter's face and the vendor's are hidden by nothing of the set; by another sprite only as in the old picture: seen)",
   "edge (round 3): at 9101 person-, dog-, frog- and pushchair-moments (every step's end of the 18 runs) whoever was wholly inside the view in the old picture is wholly inside now with 3 px to spare (or the old's, when it had less): 0 not; not fixed: Carmen where she hands the bag and the bone (160, 215), 1 px from the lower edge, at 202 step ends",
   "seen (round 2): at 9024 person-, dog- and frog-moments (every step's end of the 18 runs) each seen no less than in the old picture of that moment less 10%, and their face too (0 less)",
   "seen, not fixed (round 2): 3 step ends: senor-senora right final.5 (95): piraguero seen 85% (face 100%), the old 100% (100%), by perro viejo; senor-senora wrong final.5 (108): piraguero seen 86% (face 100%), the old 100% (100%), by perro viejo; senor-senora alternate final.5 (98): piraguero seen 85% (face 100%), the old 100% (100%), by perro viejo: the cart going home (carrova, W.seva): it rolls along +y, toward the viewer, its man pushing it from behind, and he passes the old dog, who walks slower in front of him; in the old picture the man walked along the back row, behind the dog. Only his legs, never his face, for a moment as both leave the view",
   "gate (round 2): two stone posts 43 rows high with their balls, whole in the view ([174,154,217,212]; round 3 asked 3 px inside the right edge: the right post has 0, not done), no fringe beside them (pixels within 3 px of a post's left side differing from the set without the posts: dia 0 of 209, tarde 0 of 209, noche 0 of 209), 32 px apart, PORTON 199,203 in the opening, the hedge 16 rows high joined to both (73 and 63 px of it beside the left and the right post; 46 px of it right of the right post), the paving running out through the opening as a path, lawn beyond the hedge; the lamp's foot behind the benches' line (40 px of it seen in the gap), its pool round its foot reaching the paving in front of the benches (round 3: tarde: centre 0.57 px from the foot, inner half 67% brighter; noche: centre 0.57 px from the foot, inner half 306% brighter); the wire against the sky dia 5.39 (against the first tree's crown top, not done: 1.35), tarde 6.22 (against the first tree's crown top, not done: 1.8), noche 4.72 (against the first tree's crown top, not done: 1.1) (round 3: the least luminance contrast with the sky just above and below it, WCAG, 2 kept; round 2: CIE76); the pole whole, 3 px wide; the sun and moon (radius 4; round 3 asked El camino's 9 with 10 px from the wire and 14 from the pole: not done, no place holds it) from the wire and the pole by sun-wire 7.42, sun-pole 8.1, moon-wire 7.42, moon-pole 8.1 px (6 kept), in the left half, clear of the rounds board; every bench whole in the view with 2 px",
   "umbrella (round 2): at 1288 step ends with the cart open and its man at it, the rim of the umbrella 7 px and more above his hair (3 kept); the cart over no face (drawn)",
   "asks: 46 distinct asks (for bebe, canta, come, di_bebe, di_cansado, di_come, di_contento, di_joven, di_senor, di_senora, di_triste, hombre, joven, luis, mujer, perro_joven, perro_viejo, quieto, senor): every hint frame (box +- 12) inside the view with 2 px to spare (2 at the least; the park by its hintBox), no frame's rings across a face where the old frame's were not (as the old: el-bebe-duerme beats.57 (luis) abuela's face; senor-senora beats.20 (mujer) hombre's face; senor-senora beats.20 (mujer) luis's face; senor-senora beats.25 (perro_viejo) the frog's face; senor-senora beats.52 (senor) joven's face), the hint hand on no face (but as the old: el-bebe-duerme beats.57 (luis): on luis's face; h-banco beats.4 (joven): on the frog's face; h-banco beats.7 (joven): on the frog's face; la-piragua beats.11 (mujer): on the frog's face; la-piragua beats.44 (mujer): on the frog's face; senor-senora beats.20 (mujer): on carmen's face; senor-senora beats.20 (mujer): on luis's face; senor-senora beats.20 (mujer): on the frog's face); 52 answer cards, each with its lit frame and glow 4 px and more inside the view (4 at the least), 2 px clear of the rounds card and of everyone's head and body, over no dog, the pushchair or a thing, nor what the ask names (over the wire's pigeons at no ask that names them: el-bebe-duerme, la-piragua, senor-senora; over farol of the set, named by no ask with cards), the sun and the moon under none; (new) at each of the 52 cards the hint drawn round it: its frame 2 px inside the view, across no head, its hand on no face; 69 times someone a learner must find or tell apart: whole in the view, on plain paving, lawn, sky or their own bench, apart where the old had them apart, 42 at the least from their backdrop in the evening and at night (CIE76, their fill or their dark outline against the 2 px round them; 15 kept, or no less than the old picture: none lower)",
   "heads: at 65023 face-moments (everyone at rest) no face has a tree, the lamp post, the pole or the wire behind it where the old picture did not",
   "sky: the sun at 34,40 (radius 4), upper left, whole in the view, under no card and no board at any moment; the moon at 34,40 (at night, W.luna) the same; the old picture's three clouds at 150,12; 196,30; 160,40, clear of both and of the corner card; by night no sun (patch)",
   "preview: at every step's end of the 18 recorded runs (16127 places of the people, the frog, the dogs, the pigeons, the things and the pushchair) banco-preview.html puts everyone exactly where the sheet's rule does (0 differ); and the rule puts each of the 9920 places at rest where the port's play has them (0 differ)",
   "pairs: 24 review pictures (and the 16 level pictures, the same pictures), 18 at zoom 2, the others at zoom 1 (a standing person is taller than 52 rows): everything in each whole with 1 px to spare at zoom 2 (2 at zoom 1); no zoom 2 picture shows a shadow without its caster; what differs: hombre: gente; mujer: gente; senor: gente; senora: gente; joven: gente; viejo: perros; come: gente; bebe: palomas, cosas; duerme: perros; cansado: gente; contento: gente; triste: perros",
   "states: 7 baked states reached (dia.0.abierto, dia.0.no, tarde.0.abierto, noche.0.abierto, noche.0.cerrado, noche.0.no, noche.1.abierto; every moment, pair and level picture), of the 12 the set can bake"
  ],
  "notFixed": [
   {
    "what": "senor-senora right final.5 (95): piraguero seen 85% (face 100%), the old 100% (100%), by perro viejo",
    "why": "the cart going home (carrova, W.seva): it rolls along +y, toward the viewer, its man pushing it from behind, and he passes the old dog, who walks slower in front of him; in the old picture the man walked along the back row, behind the dog. Only his legs, never his face, for a moment as both leave the view"
   },
   {
    "what": "senor-senora wrong final.5 (108): piraguero seen 86% (face 100%), the old 100% (100%), by perro viejo",
    "why": "the cart going home (carrova, W.seva): it rolls along +y, toward the viewer, its man pushing it from behind, and he passes the old dog, who walks slower in front of him; in the old picture the man walked along the back row, behind the dog. Only his legs, never his face, for a moment as both leave the view"
   },
   {
    "what": "senor-senora alternate final.5 (98): piraguero seen 85% (face 100%), the old 100% (100%), by perro viejo",
    "why": "the cart going home (carrova, W.seva): it rolls along +y, toward the viewer, its man pushing it from behind, and he passes the old dog, who walks slower in front of him; in the old picture the man walked along the back row, behind the dog. Only his legs, never his face, for a moment as both leave the view"
   },
   {
    "what": "senor-senora, every plan: Carmen at (160, 215) (bolsa, hueso) at 202 step ends, 1 px from the picture's lower edge (3 asked; the old had her 6 px from it)",
    "why": "round 3: no place holds her: right of it the gate's left post goes over her face, the hedge's line is within 6 px of her feet; higher up she stands over Luis (seen); left of it she stands over the frog"
   }
  ]
 }
}
''';
