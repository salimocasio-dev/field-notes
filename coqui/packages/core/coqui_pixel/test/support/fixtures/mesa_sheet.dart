// Made by tool/make_sheet_fixture.dart from docs/proyecto/pixel/mesa-sheet.json. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// La mesa's sheet (order 37a), the text of the file, for the tests that run in a browser.
const String mesaSheetJson = r'''{
 "scene": "mesa",
 "made": "node docs/proyecto/pixel/mesa-sheet-make.js, from mesa-set.html (window.MESA_SET), cocina-kit.js and coqui/ref/escenas/mesa/. Order 37a.",
 "S": 26,
 "origin": {
  "originX": 4,
  "originY": -22
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its pixels or of the 8 projected corners of its world box",
  "floor": "the kitchen is built round the old picture: a place keeps its screen place and its world point is the surface under it: the floor (z 0), the table's top (z 1), the counter's or the stove's top (z 1.3): a frog place q under (q.x + 16, q.y + 25); a person's, the dog's or a thing's place (x, y) under (x, y - 1). Whoever sits (sent) is on a chair: their world point the seat under their lap (x, y - 8, z 0.6), their feet row 150 + SD[i] (moves). So every position of mesa.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each one (spots, remap, storyPlaces, code) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog or the dog (what is carried, raised, held out, poured; a frog place by whoever he serves; the bubbles and the thoughts) keeps its offsets: a sitter's moved feet move what is relative to them (caja, the thing in the hand, the cloth's pulled corner)",
  "sky": "screen-space effects keep their old numbers: the stars of the endings, the heart (heartAt)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were",
  "kit": "the room is cocina-kit.js's (written with this set, shared with La estufa and La nevera): its floor, walls, tile band, counters, wall cupboard, window, stove, hood, the panel behind the stove, its light and its cut-open build (cocinaBuild)"
 },
 "layout": {
  "what": "abuela's kitchen cut open as La sala: two walls stand (the left wall along y, the back wall along x), the floor (the old red and cream checker, laid on the axes) runs off the picture; along the left wall the counter (cupboards with the white top, the tile band behind it) and the wall cupboard over it, then the doorway to the yard; on the back wall the small window (the patio's bush outside), the stove with its hood and the dark panel behind it, the counter beside it running off the right edge, the tile band behind both; the table in the middle along x, its long side to the camera, the four chairs along its far side",
  "why": "the brief and page 11 decision 9: the set stands on the world's axes, nothing square to the camera. The old picture was flat: its table, chairs, counter and stove stood in level rows. The table runs along x, so its far side falls half a row a px to the right: the four seats step down by SD (moves), the least that keeps them in their old order and every place in front of the table on clear floor; whoever comes to sit comes in at the doorway and walks behind the chairs (the old walked behind the table along row 152). The counter runs along the left wall, so its top falls half a row a px to the left: each stack on it moved onto the top by the least distance (EN). The stove stands at the right edge as the old, its things on its top (moves)",
  "walls": {
   "cut": 3.2,
   "thick": 0.22,
   "back": "y = 0, x from 0 to 9",
   "left": "x = 0, y from 0 to 9"
  }
 },
 "behind": {
  "what": "nothing: the set has no sky",
  "items": []
 },
 "setKey": {
  "params": {
   "mantel": "W.mantel ? 1 : 0",
   "horno": "W.estufa && W.estufa.horno ? 1 : 0"
  },
  "key": "\"m\" + mantel + \"h\" + horno",
  "baked": [
   {
    "key": "m0h0",
    "query": "?mantel=0&horno=0"
   },
   {
    "key": "m1h0",
    "query": "?mantel=1&horno=0"
   },
   {
    "key": "m0h1",
    "query": "?mantel=0&horno=1"
   }
  ],
  "notReached": ["m1h1"],
  "bakedWhy": "order 06 found 141 states made by eleven set keys. Two are the set's: mantel (the white cloth on the table) and estufa.horno (the oven lit: its window glows; one review picture). afuera (the stall, one review picture) swaps the whole background: that picture is El colmado's stall (pictures cocina.no), not a state of this set. The other eight are what the sprite layer draws, as the old: bandeja (what lies in the tray), encima (what the frog carries on his head), estufa's olla, tapa, vapor, bizcocho, jarra and pastel (on the stove's top), mostrador (the stacks on the counter), puestos (what stands at each place and what is spilt), reb (the slices on abuela's board), sitio (who sits where: their places), suelo (what lies on the floor), vierte (the jug that pours)",
  "spriteKeys": {
   "bandeja": "draw(): the tray's spoon, fork and knife",
   "encima": "rana(): what he carries on his head",
   "estufa": "draw(): what stands on the stove (olla, tapa, vapor, bizcocho, jarra, pastel; horno is the set's)",
   "mostrador": "draw(): the stacks on the counter (EN, moved)",
   "puestos": "draw(): at the table's entry in the sorted list, each place's plate and cup and what is spilt in front (FILA + SD, FRENTE + SD)",
   "reb": "gente(): the slices on abuela's board",
   "sitio": "which chair each sitter has (SILLA, SD)",
   "suelo": "draw(): what lies on the floor",
   "vierte": "draw(): the jug pouring"
  }
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (mesa.js:121): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand; whoever sits: down to their feet row + 1 (moves)"
  },
  "carmen": {
   "sprite": true,
   "why": "as luis"
  },
  "abuelo": {
   "sprite": true,
   "why": "as luis"
  },
  "mama": {
   "sprite": true,
   "why": "as luis"
  },
  "papa": {
   "sprite": true,
   "why": "as luis"
  },
  "abuela": {
   "sprite": true,
   "why": "as luis"
  },
  "platos": {
   "sprite": true,
   "why": "the plates on the counter (enMostr): [EN.platos - (12, 18), 24, 22]: EN moved onto the counter's top (moves)"
  },
  "tazas": {
   "sprite": true,
   "why": "as platos (EN.tazas)"
  },
  "bandeja": {
   "sprite": true,
   "why": "as platos (EN.bandeja)"
  },
  "comidas": {
   "sprite": true,
   "why": "the plates of food on the counter: [EN.comidas - (15, 16), 30, 18] (EN moved)"
  },
  "vasos": {
   "sprite": true,
   "why": "the glasses on the counter: [EN.vasos - (9, 18), 19, 20] (EN moved)"
  },
  "muestra": {
   "sprite": true,
   "why": "the thing lifted off the counter to be looked at: relative to EN (moved with it)"
  },
  "ofrece": {
   "sprite": true,
   "why": "what abuela holds out: relative to her"
  },
  "bebe": {
   "sprite": true,
   "why": "mamá's baby: relative to her"
  },
  "perro": {
   "sprite": true,
   "why": "Canelo (KIT.mkPerro): [x - 14, y - 20, 28, 22] where he is"
  },
  "olla": {
   "sprite": true,
   "why": "the pot on the stove: [ESTUFA[0] + 1, ESTUFA[1] - 16, 26, 20] moved with the pot (moves: line 130)",
   "box": [194, 90, 26, 20]
  },
  "mesa": {
   "set": true,
   "box": [64, 102, 124, 91],
   "screen": [64, 102, 124, 91],
   "what": "the table, its cloth and its four chairs",
   "old": {
    "box": [88, 130, 104, 38]
   },
   "hand": [140, 159],
   "handWhy": "on the table's top between the second and third places"
  },
  "estufa": {
   "set": true,
   "box": [195, 61, 37, 87],
   "screen": [195, 61, 37, 87],
   "what": "the stove: its hob, front, oven door, its hood and the panel behind it",
   "old": {
    "box": [190, 100, 28, 46]
   },
   "hintBox": [195, 61, 9, 87],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (2 px inside the view)",
   "hand": [208, 122],
   "handWhy": "on the stove's front, at its oven door"
  },
  "cocina": {
   "set": true,
   "ground": true,
   "box": [22, 0, 196, 216],
   "what": "the kitchen: the floor, the walls, the door, the window, the counters and the wall cupboard; last in the hit order",
   "old": {
    "box": [22, 24, 196, 190]
   },
   "hintBox": [36, 14, 168, 188],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [60, 150],
   "handWhy": "on the floor in front of the counter"
  }
 },
 "spots": {
  "frog.inicio": {
   "world": [5.3305, 5.5481, 0],
   "on": "floor",
   "old": [104, 161],
   "new": [104, 161],
   "scale": 1,
   "what": "LUGAR.inicio: the frog's place q (his feet at q.x + 16, q.y + 25), in front of the table"
  },
  "frog.centro": {
   "world": [5.3305, 5.5481, 0],
   "on": "floor",
   "old": [104, 161],
   "new": [104, 161],
   "scale": 1,
   "what": "LUGAR.centro: the frog's place q (his feet at q.x + 16, q.y + 25), in front of the table"
  },
  "silla.0": {
   "world": [2.421, 3.5089, 0.6],
   "on": "seat",
   "old": [104, 150],
   "new": [104, 135],
   "moved": true,
   "what": "SILLA[0]: whoever sits at place 0 (their feet row 150 + SD[0]; their lap on the seat)"
  },
  "silla.1": {
   "world": [3.7265, 3.5089, 0.6],
   "on": "seat",
   "old": [128, 150],
   "new": [128, 147],
   "moved": true,
   "what": "SILLA[1]: whoever sits at place 1 (their feet row 150 + SD[1]; their lap on the seat)"
  },
  "silla.2": {
   "world": [5.0319, 3.5089, 0.6],
   "on": "seat",
   "old": [152, 150],
   "new": [152, 159],
   "moved": true,
   "what": "SILLA[2]: whoever sits at place 2 (their feet row 150 + SD[2]; their lap on the seat)"
  },
  "silla.3": {
   "world": [6.3373, 3.5089, 0.6],
   "on": "seat",
   "old": [176, 150],
   "new": [176, 171],
   "moved": true,
   "what": "SILLA[3]: whoever sits at place 3 (their feet row 150 + SD[3]; their lap on the seat)"
  },
  "puesto.0": {
   "world": [3.1829, 4.2707, 1],
   "on": "mesa",
   "old": [104, 148],
   "new": [104, 133],
   "moved": true,
   "what": "FILA: what stands at place 0 (its plate, its cup), on the table's top (FILA + SD[0])"
  },
  "puesto.1": {
   "world": [4.4883, 4.2707, 1],
   "on": "mesa",
   "old": [128, 148],
   "new": [128, 145],
   "moved": true,
   "what": "FILA: what stands at place 1 (its plate, its cup), on the table's top (FILA + SD[1])"
  },
  "puesto.2": {
   "world": [5.7937, 4.2707, 1],
   "on": "mesa",
   "old": [152, 148],
   "new": [152, 157],
   "moved": true,
   "what": "FILA: what stands at place 2 (its plate, its cup), on the table's top (FILA + SD[2])"
  },
  "puesto.3": {
   "world": [5.8744, 3.046, 0],
   "on": "floor",
   "old": [176, 148],
   "new": [176, 169],
   "moved": true,
   "what": "FILA: what stands at place 3 (its plate, its cup), on the table's top (FILA + SD[3])"
  },
  "frente.0": {
   "world": [3.5636, 4.8691, 1],
   "on": "mesa",
   "old": [100, 157],
   "new": [100, 142],
   "moved": true,
   "what": "FRENTE: what is spilt or set aside in front of place 0, on the table's top (FRENTE + SD[0])"
  },
  "frente.1": {
   "world": [4.8691, 4.8691, 1],
   "on": "mesa",
   "old": [124, 157],
   "new": [124, 154],
   "moved": true,
   "what": "FRENTE: what is spilt or set aside in front of place 1, on the table's top (FRENTE + SD[1])"
  },
  "frente.2": {
   "world": [6.1745, 4.8691, 1],
   "on": "mesa",
   "old": [148, 157],
   "new": [148, 166],
   "moved": true,
   "what": "FRENTE: what is spilt or set aside in front of place 2, on the table's top (FRENTE + SD[2])"
  },
  "frente.3": {
   "world": [6.2552, 3.6443, 0],
   "on": "floor",
   "old": [172, 157],
   "new": [172, 178],
   "moved": true,
   "what": "FRENTE: what is spilt or set aside in front of place 3, on the table's top (FRENTE + SD[3])"
  },
  "rana.0": {
   "world": [4.6234, 6.4727, 0],
   "on": "floor",
   "old": [74, 163],
   "new": [74, 163],
   "scale": 1,
   "what": "ranaAl(0): the frog serving place 0 (q; his feet at SILLA - 14 + FRX, 188 + FR), in front of the table"
  },
  "rana.1": {
   "world": [5.2761, 5.82, 0],
   "on": "floor",
   "old": [98, 163],
   "new": [98, 163],
   "scale": 1,
   "what": "ranaAl(1): the frog serving place 1 (q; his feet at SILLA - 14 + FRX, 188 + FR), in front of the table"
  },
  "rana.2": {
   "world": [6.1464, 5.6025, 0],
   "on": "floor",
   "old": [122, 163],
   "new": [118, 169],
   "scale": 1,
   "moved": true,
   "what": "ranaAl(2): the frog serving place 2 (q; his feet at SILLA - 14 + FRX, 188 + FR), in front of the table"
  },
  "rana.3": {
   "world": [7.1799, 5.0041, 0],
   "on": "floor",
   "old": [146, 163],
   "new": [148, 173],
   "scale": 1,
   "moved": true,
   "what": "ranaAl(3): the frog serving place 3 (q; his feet at SILLA - 14 + FRX, 188 + FR), in front of the table"
  },
  "luis.0": {
   "world": [5.3033, 7.207, 0],
   "on": "floor",
   "old": [89, 202],
   "new": [89, 202],
   "what": "luisEn(0): Luis serving place 0, in front of the table"
  },
  "luis.1": {
   "world": [5.956, 6.5543, 0],
   "on": "floor",
   "old": [113, 202],
   "new": [113, 202],
   "what": "luisEn(1): Luis serving place 1, in front of the table"
  },
  "luis.2": {
   "world": [6.6087, 5.9016, 0],
   "on": "floor",
   "old": [137, 202],
   "new": [137, 202],
   "what": "luisEn(2): Luis serving place 2, in front of the table"
  },
  "luis.3": {
   "world": [7.2614, 5.2489, 0],
   "on": "floor",
   "old": [161, 202],
   "new": [161, 202],
   "what": "luisEn(3): Luis serving place 3, in front of the table"
  },
  "abuela.0": {
   "world": [6.4727, 6.2552, 0],
   "on": "floor",
   "old": [126, 204],
   "new": [128, 204],
   "moved": true,
   "what": "abuelaEn(0): abuela serving place 0, in front of the table"
  },
  "abuela.1": {
   "world": [7.1255, 5.6025, 0],
   "on": "floor",
   "old": [150, 204],
   "new": [152, 204],
   "moved": true,
   "what": "abuelaEn(1): abuela serving place 1, in front of the table"
  },
  "abuela.2": {
   "world": [7.7782, 4.9497, 0],
   "on": "floor",
   "old": [174, 204],
   "new": [176, 204],
   "moved": true,
   "what": "abuelaEn(2): abuela serving place 2, in front of the table"
  },
  "abuela.3": {
   "world": [8.4853, 4.2426, 0],
   "on": "floor",
   "old": [198, 204],
   "new": [202, 204],
   "moved": true,
   "what": "abuelaEn(3): abuela serving place 3, in front of the table"
  },
  "puerta": {
   "world": [-0.3264, 1.8494, 0],
   "on": "floor",
   "old": [6, 152],
   "new": [84, 101],
   "moved": true,
   "what": "PUERTA: on the patio's step just outside the doorway (round 2: seen in the opening before they step onto the kitchen floor), where whoever comes in to sit appears and whoever leaves goes (the old came in at the left edge, x 6)"
  },
  "luis": {
   "world": [2.6381, 5.3033, 0],
   "on": "floor",
   "old": [75, 160],
   "new": [75, 160],
   "what": "LUIS: where Luis waits at the counter"
  },
  "fogon": {
   "world": [7.9414, 3.6987, 0],
   "on": "floor",
   "old": [205, 170],
   "new": [202, 194],
   "moved": true,
   "what": "FOGON: where abuela stands at the stove"
  },
  "canelo": {
   "world": [8.3221, 4.4058, 0],
   "on": "floor",
   "old": [196, 204],
   "new": [196, 204],
   "what": "CAN: where Canelo lies, beside the table's right end"
  },
  "mostrador.platos": {
   "world": [0.6131, 5.3997, 1.3],
   "on": "mostrador",
   "old": [36, 113],
   "new": [36, 113],
   "what": "EN.platos: where the platos stand on the counter (the bottom row of the stack)"
  },
  "mostrador.tazas": {
   "world": [0.5859, 4.6654, 1.3],
   "on": "mostrador",
   "old": [54, 112],
   "new": [49, 106],
   "moved": true,
   "what": "EN.tazas: where the tazas stand on the counter (the bottom row of the stack)"
  },
  "mostrador.bandeja": {
   "world": [0.4771, 5.1005, 1.3],
   "on": "mostrador",
   "old": [44, 114],
   "new": [39, 109],
   "moved": true,
   "what": "EN.bandeja: where the bandeja stand on the counter (the bottom row of the stack)"
  },
  "mostrador.comidas": {
   "world": [0.4771, 5.3181, 1.3],
   "on": "mostrador",
   "old": [38, 114],
   "new": [35, 111],
   "moved": true,
   "what": "EN.comidas: where the comidas stand on the counter (the bottom row of the stack)"
  },
  "mostrador.vasos": {
   "world": [0.6131, 4.5294, 1.3],
   "on": "mostrador",
   "old": [61, 114],
   "new": [52, 105],
   "moved": true,
   "what": "EN.vasos: where the vasos stand on the counter (the bottom row of the stack)"
  },
  "mostrador.jarron": {
   "world": [0.5859, 3.7951, 1.3],
   "on": "mostrador",
   "old": [78, 112],
   "new": [65, 98],
   "moved": true,
   "what": "EN.jarron: where the jarron stand on the counter (the bottom row of the stack)"
  },
  "estufa.olla": {
   "world": [5.0189, 0.5587, 1.3],
   "on": "estufa",
   "old": [203, 107],
   "new": [206, 109],
   "moved": true,
   "what": "the olla on the stove's top (draw)"
  },
  "estufa.entero": {
   "world": [5.0461, 0.5315, 1.3],
   "on": "estufa",
   "old": [207, 108],
   "new": [207, 109],
   "moved": true,
   "what": "the entero on the stove's top (draw)"
  },
  "estufa.jarra": {
   "world": [4.9645, 0.0692, 1.3],
   "on": "estufa",
   "old": [215, 103],
   "new": [214, 104],
   "moved": true,
   "what": "the jarra on the stove's top (draw)"
  },
  "estufa.pastel": {
   "world": [4.9373, 0.7491, 1.3],
   "on": "estufa",
   "old": [195, 110],
   "new": [201, 110],
   "moved": true,
   "what": "the pastel on the stove's top (draw)"
  },
  "frog.ranaa": {
   "world": [2.3389, 6.9079, 0],
   "on": "floor",
   "old": [24, 146],
   "new": [24, 146],
   "scale": 1,
   "what": "acts.rana (la-mesa beats.53: 40, 173): the frog by the counter"
  },
  "frog.hm": {
   "world": [4.1339, 8.0501, 0],
   "on": "floor",
   "old": [36, 173],
   "new": [36, 173],
   "scale": 1,
   "what": "acts.inicio24, inicio25: the frog at the counter (36, 173)"
  },
  "frog.th": {
   "world": [4.1882, 7.1255, 0],
   "on": "floor",
   "old": [54, 165],
   "new": [54, 165],
   "scale": 1,
   "what": "acts.inicio26: the frog at the counter (54, 165)"
  }
 },
 "lugar": {
  "inicio": {
   "spot": "frog.inicio",
   "q": [104, 161],
   "scale": 1,
   "old": [104, 161]
  },
  "centro": {
   "spot": "frog.centro",
   "q": [104, 161],
   "scale": 1,
   "old": [104, 161]
  }
 },
 "hops": [],
 "hopsWhat": "each pair of the frog's places (LUGAR, the places at each seat and those the acts and the stories give him) whose hop count (mesa.js ranaA: round(d / 40), 1 to 3, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all 36 pairs)",
 "hopsAll": [
  {
   "a": "frog.centro",
   "b": "frog.hm",
   "old": 2,
   "new": 2,
   "dOld": 69.05,
   "dNew": 69.05
  },
  {
   "a": "frog.centro",
   "b": "frog.inicio",
   "old": 0,
   "new": 0,
   "dOld": 0,
   "dNew": 0
  },
  {
   "a": "frog.centro",
   "b": "frog.ranaa",
   "old": 2,
   "new": 2,
   "dOld": 81.39,
   "dNew": 81.39
  },
  {
   "a": "frog.centro",
   "b": "frog.th",
   "old": 1,
   "new": 1,
   "dOld": 50.16,
   "dNew": 50.16
  },
  {
   "a": "frog.centro",
   "b": "rana.0",
   "old": 1,
   "new": 1,
   "dOld": 30.07,
   "dNew": 30.07
  },
  {
   "a": "frog.centro",
   "b": "rana.1",
   "old": 1,
   "new": 1,
   "dOld": 6.32,
   "dNew": 6.32
  },
  {
   "a": "frog.centro",
   "b": "rana.2",
   "old": 1,
   "new": 1,
   "dOld": 18.11,
   "dNew": 16.12
  },
  {
   "a": "frog.centro",
   "b": "rana.3",
   "old": 1,
   "new": 1,
   "dOld": 42.05,
   "dNew": 45.61
  },
  {
   "a": "frog.hm",
   "b": "frog.inicio",
   "old": 2,
   "new": 2,
   "dOld": 69.05,
   "dNew": 69.05
  },
  {
   "a": "frog.hm",
   "b": "frog.ranaa",
   "old": 1,
   "new": 1,
   "dOld": 29.55,
   "dNew": 29.55
  },
  {
   "a": "frog.hm",
   "b": "frog.th",
   "old": 1,
   "new": 1,
   "dOld": 19.7,
   "dNew": 19.7
  },
  {
   "a": "frog.hm",
   "b": "rana.0",
   "old": 1,
   "new": 1,
   "dOld": 39.29,
   "dNew": 39.29
  },
  {
   "a": "frog.hm",
   "b": "rana.1",
   "old": 2,
   "new": 2,
   "dOld": 62.8,
   "dNew": 62.8
  },
  {
   "a": "frog.hm",
   "b": "rana.2",
   "old": 2,
   "new": 2,
   "dOld": 86.58,
   "dNew": 82.1
  },
  {
   "a": "frog.hm",
   "b": "rana.3",
   "old": 3,
   "new": 3,
   "dOld": 110.45,
   "dNew": 112
  },
  {
   "a": "frog.inicio",
   "b": "frog.ranaa",
   "old": 2,
   "new": 2,
   "dOld": 81.39,
   "dNew": 81.39
  },
  {
   "a": "frog.inicio",
   "b": "frog.th",
   "old": 1,
   "new": 1,
   "dOld": 50.16,
   "dNew": 50.16
  },
  {
   "a": "frog.inicio",
   "b": "rana.0",
   "old": 1,
   "new": 1,
   "dOld": 30.07,
   "dNew": 30.07
  },
  {
   "a": "frog.inicio",
   "b": "rana.1",
   "old": 1,
   "new": 1,
   "dOld": 6.32,
   "dNew": 6.32
  },
  {
   "a": "frog.inicio",
   "b": "rana.2",
   "old": 1,
   "new": 1,
   "dOld": 18.11,
   "dNew": 16.12
  },
  {
   "a": "frog.inicio",
   "b": "rana.3",
   "old": 1,
   "new": 1,
   "dOld": 42.05,
   "dNew": 45.61
  },
  {
   "a": "frog.ranaa",
   "b": "frog.th",
   "old": 1,
   "new": 1,
   "dOld": 35.51,
   "dNew": 35.51
  },
  {
   "a": "frog.ranaa",
   "b": "rana.0",
   "old": 1,
   "new": 1,
   "dOld": 52.81,
   "dNew": 52.81
  },
  {
   "a": "frog.ranaa",
   "b": "rana.1",
   "old": 2,
   "new": 2,
   "dOld": 75.93,
   "dNew": 75.93
  },
  {
   "a": "frog.ranaa",
   "b": "rana.2",
   "old": 2,
   "new": 2,
   "dOld": 99.46,
   "dNew": 96.77
  },
  {
   "a": "frog.ranaa",
   "b": "rana.3",
   "old": 3,
   "new": 3,
   "dOld": 123.18,
   "dNew": 126.91
  },
  {
   "a": "frog.th",
   "b": "rana.0",
   "old": 1,
   "new": 1,
   "dOld": 20.1,
   "dNew": 20.1
  },
  {
   "a": "frog.th",
   "b": "rana.1",
   "old": 1,
   "new": 1,
   "dOld": 44.05,
   "dNew": 44.05
  },
  {
   "a": "frog.th",
   "b": "rana.2",
   "old": 2,
   "new": 2,
   "dOld": 68.03,
   "dNew": 64.12
  },
  {
   "a": "frog.th",
   "b": "rana.3",
   "old": 2,
   "new": 2,
   "dOld": 92.02,
   "dNew": 94.34
  },
  {
   "a": "rana.0",
   "b": "rana.1",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 24
  },
  {
   "a": "rana.0",
   "b": "rana.2",
   "old": 1,
   "new": 1,
   "dOld": 48,
   "dNew": 44.41
  },
  {
   "a": "rana.0",
   "b": "rana.3",
   "old": 2,
   "new": 2,
   "dOld": 72,
   "dNew": 74.67
  },
  {
   "a": "rana.1",
   "b": "rana.2",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 20.88
  },
  {
   "a": "rana.1",
   "b": "rana.3",
   "old": 1,
   "new": 1,
   "dOld": 48,
   "dNew": 50.99
  },
  {
   "a": "rana.2",
   "b": "rana.3",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 30.27
  }
 ],
 "points": {
  "mesa": {
   "world": [1.821, 3.672, 0, 6.837, 5.032, 1],
   "top": [
    [89.97, 113.98],
    [182.19, 160.09],
    [157.18, 172.59],
    [64.97, 126.48]
   ],
   "what": "the table along x: its top at z 1 over x 1.821 to 6.837, y 3.672 to 5.032 (the far edge 14 rows over each sitter's feet, the near edge 11 rows under them); top: its corners on the screen, far left, far right, near right, near left"
  },
  "sillas": {
   "world": [
    [2.171, 3.089, 0, 2.671, 3.529, 1.45],
    [3.476, 3.089, 0, 3.976, 3.529, 1.45],
    [4.782, 3.089, 0, 5.282, 3.529, 1.45],
    [6.087, 3.089, 0, 6.587, 3.529, 1.45]
   ],
   "seat": 0.6,
   "what": "the four chairs along the table's far side: each seat at z 0.6, its middle .14 behind the sitter's lap; the back along its far edge up to z 1.45"
  },
  "laps": {
   "world": [
    [2.421, 3.509, 0.6],
    [3.726, 3.509, 0.6],
    [5.032, 3.509, 0.6],
    [6.337, 3.509, 0.6]
   ],
   "screen": [
    [104, 127],
    [128, 139],
    [152, 151],
    [176, 163]
   ],
   "what": "each sitter's lap (x, y - 8 of their feet row) on their seat"
  },
  "mostrador": {
   "world": [0, 2.858, 0, 0.9, 9, 1.3],
   "what": "the counter along the left wall (cocina-kit cocinaBase): from y 2.858 (its right end, at the old counter's right end on the screen) off the picture; its top at z 1.3"
  },
  "estufa": {
   "world": [4.776, 0, 0, 5.836, 0.9, 1.3],
   "what": "the stove on the back wall (cocina-kit cocinaStove: hob with two burners, knobs, oven door), its hood and the dark panel behind it; the counter beside it off the picture's right edge"
  },
  "puerta": {
   "world": [0, 1.6, 0, 0, 2.62, 2.75],
   "what": "the doorway to the yard in the left wall (the old door at the picture's left edge), the patio seen through it"
  },
  "ventana": {
   "world": [2.7, 0, 1.95, 3.85, 0, 2.85],
   "what": "the small window in the back wall, the patio's bush outside (the old window over the stove: here left of the stove's hood)"
  },
  "paso": {
   "world": 2.2,
   "row": "PASO(x) = round(64.45 + x / 2)",
   "what": "the walkway behind the chairs: the world line y = 2.2, from the doorway (PUERTA) along x"
  },
  "corazon": {
   "screen": [124, 22],
   "what": "heartAt: unchanged"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [3.3724, 3.5899, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the kitchen: the counter and the wall cupboard at the left, the doorway, the table with its four chairs in the middle, the window, the stove at the right"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [54, 150, 113, 60],
   "uses": ["cual-mesa.json plato.si.cam", "cual-mesa.json plato.no.cam", "cual-mesa.json taza.si.cam", "cual-mesa.json taza.no.cam", "cual-mesa.json cuchara.si.cam", "cual-mesa.json cuchara.no.cam", "cual-mesa.json tenedor.si.cam", "cual-mesa.json tenedor.no.cam"],
   "to": {
    "pictures": ["plato.si", "plato.no", "taza.si", "taza.no", "cuchara.si", "cuchara.no", "tenedor.si", "tenedor.no"]
   },
   "crops": {
    "plato.si": {
     "crop": [108, 72, 98, 52],
     "zoom": 2
    },
    "plato.no": {
     "crop": [108, 72, 98, 52],
     "zoom": 2
    },
    "taza.si": {
     "crop": [110, 68, 98, 52],
     "zoom": 2
    },
    "taza.no": {
     "crop": [110, 68, 98, 52],
     "zoom": 2
    },
    "cuchara.si": {
     "crop": [108, 55, 98, 52],
     "zoom": 2
    },
    "cuchara.no": {
     "crop": [108, 55, 98, 52],
     "zoom": 2
    },
    "tenedor.si": {
     "crop": [108, 55, 98, 52],
     "zoom": 2
    },
    "tenedor.no": {
     "crop": [108, 55, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [70, 86, 169.5, 90],
   "uses": ["cual-mesa.json cocina.si.cam"],
   "to": {
    "pictures": ["cocina.si"]
   },
   "crops": {
    "cocina.si": {
     "crop": [44, 82, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [70, 90, 169.5, 90],
   "uses": ["cual-mesa.json cocina.no.cam"],
   "to": {
    "pictures": ["cocina.no"]
   },
   "crops": {
    "cocina.no": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 84, 113, 60],
   "uses": ["cual-mesa.json tengo hambre.si.cam", "cual-mesa.json tengo hambre.no.cam"],
   "to": {
    "pictures": [
     "tengo_hambre.si",
     "tengo_hambre.no"
    ]
   },
   "crops": {
    "tengo_hambre.si": {
     "crop": [93, 75, 98, 52],
     "zoom": 2
    },
    "tengo_hambre.no": {
     "crop": [93, 75, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 100, 113, 60],
   "uses": ["cual-mesa.json mesa.si.cam", "cual-mesa.json tengo sed.si.cam", "cual-mesa.json tengo sed.no.cam", "cual-mesa.json listo.si.cam"],
   "to": {
    "pictures": [
     "mesa.si",
     "tengo_sed.si",
     "tengo_sed.no",
     "listo.si"
    ]
   },
   "crops": {
    "mesa.si": {
     "crop": [91, 115, 98, 52],
     "zoom": 2
    },
    "tengo_sed.si": {
     "crop": [85, 102, 98, 52],
     "zoom": 2
    },
    "tengo_sed.no": {
     "crop": [85, 102, 98, 52],
     "zoom": 2
    },
    "listo.si": {
     "crop": [114, 110, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [100, 126, 56.5, 30],
   "uses": ["cual-mesa.json comida.si.cam", "cual-mesa.json comida.no.cam"],
   "to": {
    "pictures": ["comida.si", "comida.no"]
   },
   "crops": {
    "comida.si": {
     "crop": [79, 113, 98, 52],
     "zoom": 2
    },
    "comida.no": {
     "crop": [79, 113, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [122, 66, 113, 60],
   "uses": ["cual-mesa.json mesa.no.cam"],
   "to": {
    "pictures": ["mesa.no"]
   },
   "crops": {
    "mesa.no": {
     "crop": [142, 70, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [127, 104, 113, 60],
   "uses": ["cual-mesa.json pone.si.cam", "cual-mesa.json pone.no.cam"],
   "to": {
    "pictures": ["pone.si", "pone.no"]
   },
   "crops": {
    "pone.si": {
     "crop": [123, 122, 98, 52],
     "zoom": 2
    },
    "pone.no": {
     "crop": [123, 122, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [127, 116, 113, 60],
   "uses": ["cual-mesa.json cuchillo.si.cam", "cual-mesa.json cuchillo.no.cam", "cual-mesa.json listo.no.cam"],
   "to": {
    "pictures": ["cuchillo.si", "cuchillo.no", "listo.no"]
   },
   "crops": {
    "cuchillo.si": {
     "crop": [134, 91, 98, 52],
     "zoom": 2
    },
    "cuchillo.no": {
     "crop": [134, 91, 98, 52],
     "zoom": 2
    },
    "listo.no": {
     "crop": [114, 110, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [83.33, 150, 54.34, 60],
   "uses": [
    "nivel.js NV plato.p0",
    "nivel.js NV plato.p1",
    "nivel.js NV plato.p2",
    "nivel.js NV plato.p3",
    "nivel.js NV taza.p0",
    "nivel.js NV taza.p1",
    "nivel.js NV taza.p2",
    "nivel.js NV taza.p3",
    "nivel.js NV cuchara.p0",
    "nivel.js NV cuchara.p1",
    "nivel.js NV cuchara.p2",
    "nivel.js NV cuchara.p3"
   ],
   "to": {
    "pictures": ["plato.si", "plato.no", "cuchara.si", "taza.no", "taza.si", "cuchara.no", "tenedor.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [113.33, 84, 54.34, 60],
   "uses": [
    "nivel.js NV tengo hambre.p0",
    "nivel.js NV tengo hambre.p1"
   ],
   "to": {
    "pictures": [
     "tengo_hambre.si",
     "tengo_hambre.no"
    ],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [113.33, 100, 54.34, 60],
   "uses": [
    "nivel.js NV tengo hambre.p2"
   ],
   "to": {
    "pictures": [
     "tengo_sed.si"
    ],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [114.67, 126, 27.17, 30],
   "uses": [
    "nivel.js NV tengo hambre.p3"
   ],
   "to": {
    "pictures": ["comida.no"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [0, 0],
   "uses": ["cual-mesa.json mesa.si.set.cq", "cual-mesa.json mesa.no.set.cq", "cual-mesa.json plato.si.set.cq", "cual-mesa.json plato.no.set.cq", "cual-mesa.json taza.si.set.cq", "cual-mesa.json taza.no.set.cq", "cual-mesa.json cuchara.si.set.cq", "cual-mesa.json cuchara.no.set.cq", "cual-mesa.json tenedor.si.set.cq", "cual-mesa.json tenedor.no.set.cq", "cual-mesa.json cuchillo.si.set.cq", "cual-mesa.json cuchillo.no.set.cq", "cual-mesa.json comida.si.set.cq", "cual-mesa.json comida.no.set.cq", "cual-mesa.json cocina.si.set.cq", "cual-mesa.json cocina.no.set.cq", "cual-mesa.json pone.si.set.cq", "cual-mesa.json pone.no.set.cq", "cual-mesa.json tengo hambre.si.set.cq", "cual-mesa.json tengo hambre.no.set.cq", "cual-mesa.json tengo sed.si.set.cq", "cual-mesa.json tengo sed.no.set.cq", "cual-mesa.json listo.si.set.cq", "cual-mesa.json listo.no.set.cq"],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0) in a review picture: not a place"
  },
  {
   "kind": "point",
   "old": [40, 173],
   "uses": ["la-mesa.json beats.53"],
   "to": {
    "floor": [4.2426, 7.9414, 0]
   },
   "new": [40, 173],
   "what": "the frog's place q: the floor under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [48, 168],
   "uses": ["h-mesa.json beats.5"],
   "to": {
    "floor": [2.3389, 6.4727, 0]
   },
   "new": [48, 168],
   "what": "a place (x, y): the floor under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [104, 150],
   "uses": ["h-mesa.json beats.2"],
   "to": {
    "seat": [2.421, 3.5089, 0.6]
   },
   "new": [104, 135],
   "moved": true,
   "why": "sitting at place 0 (x 104): on its chair (150 + SD[0])",
   "what": "sitting at the table: the seat under the lap (x, y - 8); moved (why)"
  },
  {
   "kind": "point",
   "old": [110, 206],
   "uses": ["cual-mesa.json plato.si.set.gente.luis", "cual-mesa.json plato.no.set.gente.luis", "cual-mesa.json taza.si.set.gente.carmen", "cual-mesa.json taza.no.set.gente.carmen", "cual-mesa.json cuchara.si.set.gente.abuelo", "cual-mesa.json cuchara.no.set.gente.abuelo", "cual-mesa.json tenedor.si.set.gente.papa", "cual-mesa.json tenedor.no.set.gente.papa"],
   "to": {
    "floor": [2.3389, 1.251, 0]
   },
   "new": [144, 120],
   "moved": true,
   "why": "cual-mesa plato, taza, cuchara, tenedor (round 2): whoever holds up a thing stands on the floor before the back wall, left of the window, so the thing is seen against the plaster (at the old point, in front of the table, it was seen against the checker floor: 18 to 61% plain round it); the nearest such place to the old one (86 px), all eight pictures 58% plain and more",
   "what": "a place (x, y): the floor under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [128, 150],
   "uses": ["h-mesa.json beats.3", "cual-mesa.json tengo hambre.si.set.gente.luis", "cual-mesa.json tengo hambre.no.set.gente.luis", "cual-mesa.json tengo sed.si.set.gente.carmen", "cual-mesa.json tengo sed.no.set.gente.carmen"],
   "to": {
    "seat": [3.7265, 3.5089, 0.6]
   },
   "new": [128, 147],
   "moved": true,
   "why": "sitting at place 1 (x 128): on its chair (150 + SD[1])",
   "what": "sitting at the table: the seat under the lap (x, y - 8); moved (why)"
  },
  {
   "kind": "point",
   "old": [140, 152],
   "uses": ["cual-mesa.json mesa.si.set.cosas.0"],
   "to": {
    "mesa": [5.1954, 4.3251, 1]
   },
   "new": [140, 152],
   "what": "a thing on the table's top: the top under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [140, 153],
   "uses": ["cual-mesa.json listo.si.set.cosas.0"],
   "to": {
    "mesa": [5.2498, 4.3795, 1]
   },
   "new": [140, 153],
   "what": "a thing on the table's top: the top under (x, y - 1); the same screen place"
  },
  {
   "kind": "point",
   "old": [176, 150],
   "uses": ["h-mesa.json beats.4"],
   "to": {
    "seat": [6.3373, 3.5089, 0.6]
   },
   "new": [176, 171],
   "moved": true,
   "why": "sitting at place 3 (x 176): on its chair (150 + SD[3])",
   "what": "sitting at the table: the seat under the lap (x, y - 8); moved (why)"
  },
  {
   "kind": "point",
   "old": [176, 172],
   "uses": ["cual-mesa.json cocina.si.set.gente.abuela"],
   "to": {
    "floor": [5.9288, 3.1004, 0]
   },
   "new": [176, 170],
   "moved": true,
   "why": "cual-mesa cocina.si: abuela in the kitchen, by the stove: the old point is not clear floor; moved by the least distance to clear floor",
   "what": "a place (x, y): the floor under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [176, 176],
   "uses": ["cual-mesa.json cocina.no.set.gente.abuela"],
   "to": {
    "scene": "frutas",
    "spot": "abuela.delante"
   },
   "new": [115, 203],
   "moved": true,
   "why": "cual-mesa cocina.no (W.afuera: abuela outside, at a stall): the picture is El colmado's fruit stall (frutas, its spot abuela.delante: in front of the stand)",
   "what": "a place in another scene's picture (pictures cocina.no)"
  },
  {
   "kind": "point",
   "old": [178, 150],
   "uses": ["cual-mesa.json pone.no.set.cosas.0"],
   "to": {
    "mesa": [6.2561, 3.9172, 1]
   },
   "new": [167, 158],
   "moved": true,
   "why": "cual-mesa: the plate on the table's top (round 1: 171, 158, the least move onto the top); round 2, pone.no: the plate beside the cloth, moved with it: the least move from there that puts the cloth's plain top round half its outline",
   "what": "a thing on the table's top: the top under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [187, 150],
   "uses": ["cual-mesa.json pone.si.set.cosas.0"],
   "to": {
    "mesa": [6.4737, 3.8084, 1]
   },
   "new": [173, 159],
   "moved": true,
   "why": "cual-mesa: the plate set down on the table's top (round 1: 175, 160, the least move onto the top); round 2, pone.si: the plate set down (by the cloth's edge: 44% plain round it): the least move from there that puts the cloth's plain top round half its outline",
   "what": "a thing on the table's top: the top under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [187, 151],
   "uses": ["cual-mesa.json pone.no.set.cosas.1"],
   "to": {
    "mesa": [6.5008, 3.89, 1]
   },
   "new": [172, 160],
   "moved": true,
   "why": "cual-mesa: the cloth on the table's top (round 1: 176, 160, the least move onto the top); round 2, pone.no: the little cloth (by the cloth's edge: 30% plain round it): the least move from there that puts the cloth's plain top round half its outline",
   "what": "a thing on the table's top: the top under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [205, 170],
   "uses": ["cual-mesa.json cuchillo.si.set.gente.abuela", "cual-mesa.json cuchillo.no.set.gente.abuela"],
   "to": {
    "floor": [5.7656, 1.523, 0]
   },
   "new": [202, 154],
   "moved": true,
   "why": "cual-mesa cuchillo (round 2): abuela with the knife or the spoon stands before the stove, the thing seen against its white front (at FOGON, 202, 194, it was against the floor and the table: 6 to 20% plain round it); the nearest such place to FOGON (40 px)",
   "what": "a place (x, y): the floor under (x, y - 1); moved (why)"
  },
  {
   "kind": "point",
   "old": [206, 165],
   "uses": ["cual-mesa.json pone.si.set.gente.carmen", "cual-mesa.json pone.no.set.gente.carmen"],
   "to": {
    "floor": [6.4727, 2.0125, 0]
   },
   "new": [206, 165],
   "what": "a place (x, y): the floor under (x, y - 1); the same screen place"
  }
 ],
 "storyPlaces": [],
 "pictures": {
  "mesa.si": {
   "world": [4.6515, 3.7812, 1],
   "screen": [140, 141],
   "zoom": 2,
   "crop": [91, 115, 98, 52],
   "what": "the table with its cloth and a vase of flowers on it",
   "thing": ["cosas.0"]
  },
  "mesa.no": {
   "world": [2.3661, -1.2782, 0],
   "screen": [191, 96],
   "zoom": 2,
   "crop": [142, 70, 98, 52],
   "what": "the stove with a steaming pot",
   "thing": ["estufa.olla", "estufa.vapor"]
  },
  "plato.si": {
   "world": [1.5502, -0.2448, 0],
   "screen": [157, 98],
   "zoom": 2,
   "crop": [108, 72, 98, 52],
   "what": "Luis holding up a plate",
   "thing": ["gente.luis.alza"]
  },
  "plato.no": {
   "world": [1.5502, -0.2448, 0],
   "screen": [157, 98],
   "zoom": 2,
   "crop": [108, 72, 98, 52],
   "what": "Luis holding up a cup",
   "thing": ["gente.luis.alza"]
  },
  "taza.si": {
   "world": [1.387, -0.5167, 0],
   "screen": [159, 94],
   "zoom": 2,
   "crop": [110, 68, 98, 52],
   "what": "Carmen holding up a cup of chocolate",
   "thing": ["gente.carmen.alza"]
  },
  "taza.no": {
   "world": [1.387, -0.5167, 0],
   "screen": [159, 94],
   "zoom": 2,
   "crop": [110, 68, 98, 52],
   "what": "Carmen holding up a pot",
   "thing": ["gente.carmen.alza"]
  },
  "cuchara.si": {
   "world": [0.6255, -1.1694, 0],
   "screen": [157, 81],
   "zoom": 2,
   "crop": [108, 55, 98, 52],
   "what": "abuelo holding up a spoon",
   "thing": ["gente.abuelo.alza"]
  },
  "cuchara.no": {
   "world": [0.6255, -1.1694, 0],
   "screen": [157, 81],
   "zoom": 2,
   "crop": [108, 55, 98, 52],
   "what": "abuelo holding up a fork",
   "thing": ["gente.abuelo.alza"]
  },
  "tenedor.si": {
   "world": [0.6255, -1.1694, 0],
   "screen": [157, 81],
   "zoom": 2,
   "crop": [108, 55, 98, 52],
   "what": "papá holding up a fork",
   "thing": ["gente.papa.alza"]
  },
  "tenedor.no": {
   "world": [0.6255, -1.1694, 0],
   "screen": [157, 81],
   "zoom": 2,
   "crop": [108, 55, 98, 52],
   "what": "papá holding up a knife",
   "thing": ["gente.papa.alza"]
  },
  "cuchillo.si": {
   "world": [3.2908, 0.0816, 0],
   "screen": [183, 117],
   "zoom": 2,
   "crop": [134, 91, 98, 52],
   "what": "abuela by the stove holding up a knife",
   "thing": ["gente.abuela.alza"]
  },
  "cuchillo.no": {
   "world": [3.2908, 0.0816, 0],
   "screen": [183, 117],
   "zoom": 2,
   "crop": [134, 91, 98, 52],
   "what": "abuela by the stove holding up a spoon",
   "thing": ["gente.abuela.alza"]
  },
  "comida.si": {
   "world": [4.2164, 3.9988, 1],
   "screen": [128, 139],
   "zoom": 2,
   "crop": [79, 113, 98, 52],
   "what": "a plate of hot food at a place on the table",
   "thing": ["puestos.1.plato"]
  },
  "comida.no": {
   "world": [4.2164, 3.9988, 1],
   "screen": [128, 139],
   "zoom": 2,
   "crop": [79, 113, 98, 52],
   "what": "two empty plates at that place",
   "thing": ["puestos.1.plato"]
  },
  "cocina.si": {
   "world": [3.8619, 1.3598, 0],
   "screen": [170, 134],
   "zoom": 1,
   "crop": [44, 82, 196, 104],
   "what": "abuela in the kitchen by the stove, a pot steaming",
   "thing": ["estufa.olla"],
   "zoom1": "zoom 2 cannot hold it: the pot with its steam (25 rows) and abuela's whole head by the stove need 55 rows of a 52-row window; and its other picture, cocina.no, is El colmado's stall at zoom 1"
  },
  "cocina.no": {
   "world": [4.297, 4.6234, 0],
   "screen": [118, 168],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "abuela outside at a fruit stall (El colmado's stall: frutas-set.html?surtido=frutas)",
   "scene": "frutas",
   "query": "?surtido=frutas",
   "zoom1": "another scene's picture, El colmado's stall, drawn whole as its page draws it",
   "port": "El colmado is ported later: until then the port draws this picture from the web page itself. File docs/proyecto/pixel/frutas-set.html with the query ?surtido=frutas (its canvas, 240 x 216, as the page draws it: no state of mesa-set.html, no mesa sprite but abuela); the window: crop [20, 112, 196, 104] at zoom 1 (the 196 x 104 picture, as the picture's crop here and mesa-preview.html draw it); abuela: the sprite layer of mesa.js (W.afuera 1, gente.abuela with dir -1 as cual-mesa.json gives) at frutas's spot abuela.delante, screen (115, 203) (storyMoves: old 176, 176), her feet there; nothing else of mesa.js is drawn (its old stall, mkPuesto, is dropped). When El colmado is in Dart, its set at that state and that spot replace the page"
  },
  "pone.si": {
   "world": [4.6778, 2.0669, 0],
   "screen": [172, 148],
   "zoom": 2,
   "crop": [123, 122, 98, 52],
   "what": "Carmen at the table's end, a plate set on it",
   "thing": ["cosas.0"]
  },
  "pone.no": {
   "world": [4.6778, 2.0669, 0],
   "screen": [172, 148],
   "zoom": 2,
   "crop": [123, 122, 98, 52],
   "what": "Carmen at the table's end, a plate and a cloth on it",
   "thing": ["cosas.1"]
  },
  "tengo_hambre.si": {
   "world": [1.3054, 0.3264, 0],
   "screen": [142, 101],
   "zoom": 2,
   "crop": [93, 75, 98, 52],
   "what": "Luis at the table thinking of food",
   "thing": ["gente.luis.piensa"]
  },
  "tengo_hambre.no": {
   "world": [1.3054, 0.3264, 0],
   "screen": [142, 101],
   "zoom": 2,
   "crop": [93, 75, 98, 52],
   "what": "Luis at the table thinking of water",
   "thing": ["gente.luis.piensa"]
  },
  "tengo_sed.si": {
   "world": [2.5565, 2.0125, 0],
   "screen": [134, 128],
   "zoom": 2,
   "crop": [85, 102, 98, 52],
   "what": "Carmen at the table drinking",
   "thing": ["gente.carmen.hace"],
   "plainKnown": "the glass is at her mouth: round it her face and hair, which are hers (left out), and the chair's back behind her, as the old"
  },
  "tengo_sed.no": {
   "world": [2.5565, 2.0125, 0],
   "screen": [134, 128],
   "zoom": 2,
   "crop": [85, 102, 98, 52],
   "what": "Carmen at the table eating",
   "thing": ["gente.carmen.hace"],
   "plainKnown": "the fork is at her mouth: round it her face, which is hers (left out), and the chair's back behind her, as the old"
  },
  "listo.si": {
   "world": [3.7803, 1.659, 0],
   "screen": [163, 136],
   "zoom": 2,
   "crop": [114, 110, 98, 52],
   "what": "a whole cake on the table",
   "thing": ["cosas.0"]
  },
  "listo.no": {
   "world": [3.7803, 1.659, 0],
   "screen": [163, 136],
   "zoom": 2,
   "crop": [114, 110, 98, 52],
   "what": "the oven lit, something baking",
   "thing": ["estufa.horno"]
  }
 },
 "level": [
  {
   "w": "plato",
   "index": 0,
   "picture": "plato.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 72, 98, 52],
   "zoom": 2
  },
  {
   "w": "plato",
   "index": 1,
   "picture": "plato.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 72, 98, 52],
   "zoom": 2
  },
  {
   "w": "plato",
   "index": 2,
   "picture": "cuchara.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 55, 98, 52],
   "zoom": 2
  },
  {
   "w": "plato",
   "index": 3,
   "picture": "taza.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [110, 68, 98, 52],
   "zoom": 2
  },
  {
   "w": "taza",
   "index": 0,
   "picture": "taza.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [110, 68, 98, 52],
   "zoom": 2
  },
  {
   "w": "taza",
   "index": 1,
   "picture": "taza.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [110, 68, 98, 52],
   "zoom": 2
  },
  {
   "w": "taza",
   "index": 2,
   "picture": "plato.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 72, 98, 52],
   "zoom": 2
  },
  {
   "w": "taza",
   "index": 3,
   "picture": "cuchara.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 55, 98, 52],
   "zoom": 2
  },
  {
   "w": "cuchara",
   "index": 0,
   "picture": "cuchara.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 55, 98, 52],
   "zoom": 2
  },
  {
   "w": "cuchara",
   "index": 1,
   "picture": "cuchara.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 55, 98, 52],
   "zoom": 2
  },
  {
   "w": "cuchara",
   "index": 2,
   "picture": "tenedor.no",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 55, 98, 52],
   "zoom": 2
  },
  {
   "w": "cuchara",
   "index": 3,
   "picture": "plato.si",
   "old": [83.33, 150, 54.34, 60],
   "crop": [108, 72, 98, 52],
   "zoom": 2
  },
  {
   "w": "tengo hambre",
   "index": 0,
   "picture": "tengo_hambre.si",
   "old": [113.33, 84, 54.34, 60],
   "crop": [93, 75, 98, 52],
   "zoom": 2
  },
  {
   "w": "tengo hambre",
   "index": 1,
   "picture": "tengo_hambre.no",
   "old": [113.33, 84, 54.34, 60],
   "crop": [93, 75, 98, 52],
   "zoom": 2
  },
  {
   "w": "tengo hambre",
   "index": 2,
   "picture": "tengo_sed.si",
   "old": [113.33, 100, 54.34, 60],
   "crop": [85, 102, 98, 52],
   "zoom": 2
  },
  {
   "w": "tengo hambre",
   "index": 3,
   "picture": "comida.no",
   "old": [114.67, 126, 27.17, 30],
   "crop": [79, 113, 98, 52],
   "zoom": 2
  }
 ],
 "clips": {},
 "clipsWhat": "mesa.js never calls clip()",
 "front": {
  "how": "the old table (mkMesa) was drawn in the sorted list at y MESA[1] + MESA[3] + 6 (166), over whoever sat behind it; its chairs, counter and stove were the background. Now the table, its chairs, the counters and the stove are set things someone can be behind. Every item of the sorted list owns the pixels it drew last; at each front entry (sortY 9999: after everyone) the set's own pixels of that part (mesa-set.html part(), PART_TAGS) are drawn again where their owner stands behind them: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the owner's plane: whoever sits, their lap on the seat (x, y - 8, z 0.6) + .03; anyone else, the floor under their foot (x, y - 1); the frog, the floor under (b.x + b.w / 2, q.y + 25); what stands on a top is never drawn over (the places at the table: their entry; the stacks on the counter and the stove are drawn before the list). \"Behind the table\" is that depth test, not a row",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "chairs": "a chair is never drawn over whoever sits (they sit on it, its back behind them)",
  "parts": {
   "mesa": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"mesa\"})",
    "why": "whoever sits behind the table, or walks behind it: the table's top drawn over their lower part"
   },
   "mesa.patas": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"mesa.patas\"})",
    "why": "its legs"
   },
   "sillas": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"sillas\"})",
    "why": "whoever walks behind the chairs: their backs drawn over their legs"
   },
   "sillas.patas": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"sillas.patas\"})",
    "why": "their legs"
   },
   "mostrador": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"mostrador\"})",
    "why": "whoever stands behind the counter's end: none in the stories"
   },
   "mostrador2": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"mostrador2\"})",
    "why": "as mostrador"
   },
   "estufa": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"estufa\"})",
    "why": "whoever stands behind the stove: none in the stories"
   },
   "pared": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"pared\"})",
    "why": "whoever stands outside on the step (PUERTA, round 2): the left wall drawn over what of them is behind it, so they are seen in the opening"
   },
   "puerta": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"puerta\"})",
    "why": "as pared: the door's frame and reveal over whoever stands outside (the patio and the backdrop are behind them: the depth test keeps them under)"
   },
   "puerta.umbral": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"puerta.umbral\"})",
    "why": "the threshold over the feet of whoever stands outside on the step"
   },
   "puerta.jamba": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"puerta.jamba\"})",
    "why": "the wall's thickness in the opening, where it stands before whoever is outside"
   }
  },
  "tags": [
   [
    "L.push({y:p.z!=null?p.z:p.y,d:()=>gente(c,id,a)});",
    "L.push({y:p.z!=null?p.z:p.y,id,d:()=>gente(c,id,a)});"
   ],
   [
    "if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:",
    "if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,k:\"perro\",d:"
   ],
   [
    "if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});",
    "if(q.vis)L.push({y:q.y+27,id:\"coqui\",d:()=>rana(c,q,a)});"
   ],
   [
    "if(!W.afuera)L.push({y:MESA[1]+MESA[3]+6+SD[3],d:()=>{",
    "if(!W.afuera)L.push({y:MESA[1]+MESA[3]+6+SD[3],mesa:1,d:()=>{"
   ],
   [
    "(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>",
    "(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,cosa:o,d:()=>"
   ],
   [
    "(W.suelo||[]).forEach(o=>L.push({y:o.y-4,d:()=>",
    "(W.suelo||[]).forEach(o=>L.push({y:o.y-4,cosa:o,d:()=>"
   ]
  ],
  "tagsWhat": "each item of the sorted list says what it is (the front masks read it), in mesa.js with the moves applied; nothing else changes"
 },
 "shadows": {
  "rule": "the kitchen's one light (cocina-kit): from the upper left, every shadow cast to screen right from the ground point under the thing's feet (unproject), low and joined to it; on the floor only",
  "coqui": {
   "radius": 0.45,
   "at": "unproject(b.x + b.w / 2, q.y + 25)",
   "when": "W.cq.vis and al > .5",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "adulto": 0.34,
    "nino": 0.3
   },
   "at": "unproject(x, y - 1)",
   "when": "standing on the floor (not sitting: whoever sits is under the table's top), visible (vis !== 0, al > .5)",
   "cast": "for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r)"
  },
  "perro": {
   "radius": 0.32,
   "at": "unproject(x, y - 1)",
   "when": "W.perro shown",
   "cast": "castShadow(g.x, g.y, .25, .32)"
  },
  "cosas": {
   "radius": 0.18,
   "at": "unproject(x, y - 1)",
   "when": "a thing lying on the floor (W.cosas with no z, W.suelo)",
   "cast": "castShadow(g.x, g.y, .05, .18)"
  },
  "dropped": "none of the old code's own: mesa.js draws no shadow"
 },
 "dropped": [
  {
   "line": 156,
   "src": "c.drawImage(W.afuera?spr(\"puesto\",mkPuesto):spr(\"cocina\",fondo),0,0);",
   "to": "",
   "why": "the background (fondo, mkPuesto): the set, for setKey(W); W.afuera (the stall, one review picture) is El colmado's stall (pictures cocina.no)"
  },
  {
   "line": 157,
   "src": "if(E.horno){fr(c,ESTUFA[0]+6,ESTUFA[1]+18,ESTUFA[2]-12,16,\"#B84818\");fr(c,ESTUFA[0]+8,ESTUFA[1]+27,14,6,\"#F4E4C0\");fr(c,ESTUFA[0]+8,ESTUFA[1]+26,14,2,\"#FFF8E8\");}",
   "to": "",
   "why": "the oven lit (W.estufa.horno): the set's (setKey horno: the stove's oven window glows)"
  },
  {
   "line": 171,
   "src": "c.drawImage(spr(\"mesa\"+(W.mantel?1:0),()=>mkMesa(W.mantel)),MESA[0]-6,MESA[1]);",
   "to": "",
   "why": "the table (mkMesa, in the sorted list): the set's table and its cloth (setKey mantel); what stands on it is still drawn there, at its entry; the set's table and chairs are drawn again over whoever is behind them (front)"
  }
 ],
 "moves": [
  {
   "line": 21,
   "act": "*",
   "src": "FILA=148,FRENTE=157;",
   "to": "FILA=148,FRENTE=157,SD=[-15,-3,9,21],PUERTA=[84,101],PASO=x=>Math.round(64.45+x/2);",
   "why": "the table stands on the world's axes (along x), so its far side, where the four chairs stand, falls half a row for every px to the right: SD[i], the rows each seat steps down from the old row 150 (whoever sits at seat i has their feet at 150 + SD[i]: -24, -12, 0, +12, the least that keeps the four in the old order, apart, and the right end of the table clear of the frog's, Luis's and abuela's places in front of it); PUERTA, on the patio's step outside the doorway in the left wall (round 2: seen in the opening, the wall and the door's frame drawn over what of them is behind it), where whoever comes in to sit appears and where whoever leaves goes; from it they step in straight onto the walkway's end in the doorway (the old door at the picture's left edge, x 6); PASO(x), the row of the walkway behind the chairs at x (the world line y = 2.2)"
  },
  {
   "line": 24,
   "act": "*",
   "src": "const LUIS=[75,160],FOGON=[205,170],CAN=[196,204];",
   "to": "const LUIS=[75,160],FOGON=[202,194],CAN=[196,204],FRX=[0,0,-4,2],FAX=[24,24,24,26],FR=[0,0,6,10],FT=[0,0,10,10],FL=[0,0,0,0],FA=[0,0,0,0],FP=[0,4,3,3],FC=[0,0,0,0],FI=[0,0,0,0];",
   "places": [
    {
     "who": "abuela",
     "old": [205, 170],
     "new": [202, 194],
     "world": [7.9414, 3.6987, 0]
    }
   ],
   "why": "LUIS, where Luis waits at the counter: unchanged (what he holds up at his right reaches over the table's near left corner: checks, asks); FOGON, where abuela stands at the stove: 3 px left, so that she is whole in the view with 3 px to spare (her sprite reached the view's last column), and 24 rows down, in front of the table's right end beside the stove: the table's right end and whoever sits there (150 + SD[3]) are where she stood, and what she holds out covered their face; from here her walks keep in front of the table; CAN, where Canelo lies: 0 rows down (clear floor beside the table's right end). FR, FL, FA, FP, FC, FI: for each seat, the rows the places in front of it step down from the old ones (the frog serving, the frog fetching from the sitter, Luis, abuela, Canelo begging, what falls from the table, the bundle of the cloth), the least that puts each on clear floor in front of the table (the table along x comes nearer the camera to the right)"
  },
  {
   "line": 221,
   "act": "*",
   "src": "const ranaAl=i=>ranaA(SILLA[i]-14,190);",
   "to": "const ranaAl=i=>ranaA(SILLA[i]-14+FRX[i],190+FR[i]);",
   "places": [
    {
     "who": "cq",
     "old": [122, 163],
     "new": [118, 169],
     "world": [4.297, 4.6234, 0]
    },
    {
     "who": "cq",
     "old": [146, 163],
     "new": [148, 173],
     "world": [5.3305, 4.0251, 0]
    }
   ],
   "why": "ranaAl: the frog serving place i stands in front of the table (FR), at the two right places 3 px apart from where abuela waits in the middle (centro: FRX), so that she covers no more of his face than the old"
  },
  {
   "line": 219,
   "act": "*",
   "src": "await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190:p.y+8);",
   "to": "await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190+FT[j]:p.y+8);",
   "places": [
    {
     "who": "cq",
     "old": [126, 163],
     "new": [126, 173],
     "world": [4.7322, 4.6234, 0]
    },
    {
     "who": "cq",
     "old": [150, 163],
     "new": [150, 173],
     "world": [5.3849, 3.9707, 0]
    }
   ],
   "why": "ranaTrae: the frog fetching from whoever sits at place j stands in front of the table (FT: the least rows down, as FR)"
  },
  {
   "line": 212,
   "act": "*",
   "src": "x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202;",
   "to": "x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202+FL[i];",
   "why": "luisEn: Luis serving place i stands in front of the table (FL)"
  },
  {
   "line": 210,
   "act": "*",
   "src": "if(Math.hypot(ab.x-x,ab.y-y)>3)await mueve(\"abuela\",x,y);ab.dir=-1;}",
   "to": "if(Math.hypot(ab.x-x,ab.y-y)>3){const vy=Math.max(ab.y,y),vx=ab.y<y?ab.x:x;if(Math.hypot(ab.x-vx,ab.y-vy)>3)await mueve(\"abuela\",vx,vy);await mueve(\"abuela\",x,y);}ab.dir=-1;}",
   "why": "abuelaEn: abuela walks between the stove and a place at the table round the front of the table: down (or across) to the lower row first, then along it, so that she passes below the faces of whoever sits at the right of the table (the table along x brings the right seats nearer the camera: across the straight way her head went over their faces)"
  },
  {
   "line": 210,
   "act": "*",
   "src": "x=i==null?FOGON[0]:SILLA[i]+22,y=i==null?FOGON[1]:204;",
   "to": "x=i==null?FOGON[0]:SILLA[i]+FAX[i],y=i==null?FOGON[1]:204+FA[i];",
   "places": [
    {
     "who": "abuela",
     "old": [126, 204],
     "new": [128, 204],
     "world": [6.4727, 6.2552, 0]
    },
    {
     "who": "abuela",
     "old": [150, 204],
     "new": [152, 204],
     "world": [7.1255, 5.6025, 0]
    },
    {
     "who": "abuela",
     "old": [174, 204],
     "new": [176, 204],
     "world": [7.7782, 4.9497, 0]
    },
    {
     "who": "abuela",
     "old": [198, 204],
     "new": [202, 204],
     "world": [8.4853, 4.2426, 0]
    }
   ],
   "why": "abuelaEn: abuela serving place i stands in front of the table (FA), 2 px further right than the old (4 at the last place: FAX), so that what she carries is off the face of the frog when he serves the place too"
  },
  {
   "line": 238,
   "act": "abuelaa",
   "src": "await mueve(\"abuela\",142,207)",
   "to": "await mueve(\"abuela\",138,213)",
   "places": [
    {
     "who": "abuela",
     "old": [142, 207],
     "new": [138, 213],
     "world": [7.2342, 6.4727, 0]
    }
   ],
   "why": "acts.abuelaa (centro): where abuela waits in the middle while the frog serves, 6 rows nearer and 4 px left: the frog serving the right places stands lower than the old (FR), and her skirt covered more of his face than the old"
  },
  {
   "line": 336,
   "act": "*",
   "src": "await perroA(SILLA[i]+16,194);",
   "to": "await perroA(SILLA[i]+16,194+FP[i]);",
   "places": [
    {
     "who": "perro",
     "old": [144, 194],
     "new": [144, 198],
     "world": [6.5815, 5.4937, 0]
    },
    {
     "who": "perro",
     "old": [168, 194],
     "new": [168, 197],
     "world": [7.1799, 4.7866, 0]
    },
    {
     "who": "perro",
     "old": [192, 194],
     "new": [192, 197],
     "world": [7.8326, 4.1339, 0]
    }
   ],
   "why": "canelo: Canelo begging at place i sits in front of the table (FP)"
  },
  {
   "line": 262,
   "act": "*",
   "src": "await mueve(\"luis\",SILLA[sitio(\"mama\")]-26,204);",
   "to": "await mueve(\"luis\",SILLA[sitio(\"mama\")]-26,204+FL[sitio(\"mama\")]);",
   "why": "recoge24: Luis picks the bundle up in front of mamá's place (FL)"
  },
  {
   "line": 261,
   "act": "*",
   "src": "W.cosas.push({id:\"lio\",k:\"lio\",x:SILLA[im]-6,y:200});",
   "to": "W.cosas.push({id:\"lio\",k:\"lio\",x:SILLA[im]-6,y:200+FI[im]});",
   "why": "tira24: the bundle of the cloth lies on the floor in front of mamá's place (FI)"
  },
  {
   "line": 353,
   "act": "final26",
   "src": "await mueve(\"abuela\",CAN[0]-34,CAN[1]-8);",
   "to": "await mueve(\"abuela\",CAN[0]-34,CAN[1]-8+3);",
   "places": [
    {
     "who": "abuela",
     "old": [162, 196],
     "new": [162, 199],
     "world": [7.1255, 5.0585, 0]
    }
   ],
   "why": "acts.final26: abuela gives Canelo his bone standing in front of the table's right end (3 rows down: the old point is under it)"
  },
  {
   "line": 241,
   "act": "inicio24",
   "src": "async inicio24(){W.mantel=1;",
   "to": "async inicio24(){W.respEn=[98,20];W.mantel=1;",
   "why": "acts.inicio24 (la-mesa, h-mesa): the two answer cards (di_plato, di_taza) stand on the wall above the heads, so that the hint hand under each falls on nobody's face: the first card's hand left of abuelo's (seat 0), the second's right of it, both over the heads of seats 1 to 3 (their faces under the hands' reach); as high as their glow allows (4 px inside the view)"
  },
  {
   "line": 273,
   "act": "inicio25",
   "src": "async inicio25(){W.mantel=1;",
   "to": "async inicio25(){W.respEn=[123,20];W.mantel=1;",
   "why": "acts.inicio25 (la-cuchara): the three answer cards on the wall above the heads, the hand under each between the sitters' faces or over them (the first card's left of abuelo's face, the second's right of it)"
  },
  {
   "line": 311,
   "act": "inicio26",
   "src": "async inicio26(){W.mantel=0;",
   "to": "async inicio26(){W.respEn=[98,20];W.mantel=0;",
   "why": "acts.inicio26 (tengo-hambre): the two answer cards as la-mesa's"
  },
  {
   "line": 208,
   "act": "*",
   "src": "if(p.vis===0){p.vis=1;p.x=6;p.y=152;p.sent=0;}await mueve(id,p.x,152,2);await mueve(id,SILLA[i],152);p.sent=1;p.y=150;p.dir=1;",
   "to": "if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=PUERTA[1];p.sent=0;}await mueve(id,p.x,PASO(p.x),2);await mueve(id,SILLA[i],PASO(SILLA[i]));p.sent=1;p.y=150+SD[i];p.dir=1;",
   "places": [
    {
     "who": "whoever",
     "old": [6, 152],
     "new": [84, 101],
     "world": [-0.3264, 1.8494, 0]
    }
   ],
   "why": "sienta: whoever comes in to sit appears in the doorway (PUERTA), walks along the walkway behind the chairs (PASO: the old row 152, behind the table) to their chair and sits on it (150 + SD[i])"
  },
  {
   "line": 209,
   "act": "*",
   "src": "p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,152,2);await mueve(id,4,152);p.vis=0;",
   "to": "p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,PASO(p.x),2);await mueve(id,PUERTA[0],PUERTA[1]);p.vis=0;",
   "places": [
    {
     "who": "whoever",
     "old": [4, 152],
     "new": [84, 101],
     "world": [-0.3264, 1.8494, 0]
    }
   ],
   "why": "sale: whoever leaves gets up onto the walkway behind the chairs and goes out by the doorway (the old went out at the picture's left edge, x 4)"
  },
  {
   "line": 273,
   "act": "inicio25",
   "src": "abuelo:{x:SILLA[0],y:150,sent:1,dir:1},mama:{x:SILLA[1],y:150,sent:1,dir:1},papa:{x:SILLA[2],y:150,sent:1,dir:1},carmen:{x:SILLA[3],y:150,sent:1,dir:1}",
   "to": "abuelo:{x:SILLA[0],y:150+SD[0],sent:1,dir:1},mama:{x:SILLA[1],y:150+SD[1],sent:1,dir:1},papa:{x:SILLA[2],y:150+SD[2],sent:1,dir:1},carmen:{x:SILLA[3],y:150+SD[3],sent:1,dir:1}",
   "places": [
    {
     "who": "abuelo",
     "old": [104, 150],
     "new": [104, 135],
     "world": [2.421, 3.5089, 0.6]
    },
    {
     "who": "mama",
     "old": [128, 150],
     "new": [128, 147],
     "world": [3.7265, 3.5089, 0.6]
    },
    {
     "who": "papa",
     "old": [152, 150],
     "new": [152, 159],
     "world": [5.0319, 3.5089, 0.6]
    },
    {
     "who": "carmen",
     "old": [176, 150],
     "new": [176, 171],
     "world": [6.3373, 3.5089, 0.6]
    }
   ],
   "why": "acts.inicio25: the four at the table sit on their chairs (150 + SD)"
  },
  {
   "line": 358,
   "act": "prueba",
   "src": "abuelo:{x:SILLA[0],y:150,dir:1,sent:1",
   "to": "abuelo:{x:SILLA[0],y:150+SD[0],dir:1,sent:1",
   "why": "acts.prueba (a test of the drawing, no story): abuelo on his chair"
  },
  {
   "line": 358,
   "act": "prueba",
   "src": "papa:{x:SILLA[1],y:150,dir:1,sent:1",
   "to": "papa:{x:SILLA[1],y:150+SD[1],dir:1,sent:1",
   "why": "acts.prueba: papá on his chair"
  },
  {
   "line": 358,
   "act": "prueba",
   "src": "mama:{x:SILLA[2],y:150,dir:1,sent:1",
   "to": "mama:{x:SILLA[2],y:150+SD[2],dir:1,sent:1",
   "why": "acts.prueba: mamá on her chair"
  },
  {
   "line": 358,
   "act": "prueba",
   "src": "carmen:{x:SILLA[3],y:150,dir:1,sent:1",
   "to": "carmen:{x:SILLA[3],y:150+SD[3],dir:1,sent:1",
   "why": "acts.prueba: Carmen on her chair"
  },
  {
   "line": 171,
   "act": "*",
   "src": "L.push({y:MESA[1]+MESA[3]+6,d:",
   "to": "L.push({y:MESA[1]+MESA[3]+6+SD[3],d:",
   "why": "draw: what stands at the places (the table's entry in the sorted list) is drawn after whoever sits, at every seat: the seats step down to 150 + SD[3] at the right, past the old row 166"
  },
  {
   "line": 174,
   "act": "*",
   "src": "L.push({y:MESA[1]+MESA[3]+7,d:",
   "to": "L.push({y:MESA[1]+MESA[3]+7+SD[3],d:",
   "why": "draw (W.tiron): the pulled cloth after the places, as the old"
  },
  {
   "line": 172,
   "act": "*",
   "src": "fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+dy+e.dy));",
   "to": "fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+SD[i]+Math.round(dx/2)+dy+e.dy));",
   "why": "draw: what stands at place i (its plate, its cup) on the table's top at its seat (FILA + SD[i]); when the cloth is pulled (tira24: dx) it slides along the table, half a row for every px"
  },
  {
   "line": 173,
   "act": "*",
   "src": "const x=SILLA[i]-4+j*7,y=FRENTE+(j%2)*2;",
   "to": "const x=SILLA[i]-4+j*7,y=FRENTE+SD[i]+(j%2)*2;",
   "why": "draw: what is spilt or set aside in front of place i (FRENTE + SD[i]), on the table's top"
  },
  {
   "line": 121,
   "act": "*",
   "src": "return p.sent?[R(p.x)-11,R(p.y)-h,22,FILA+3-(R(p.y)-h)]:[R(p.x)-11,R(p.y)-h,22,h];",
   "to": "return p.sent?[R(p.x)-11,R(p.y)-h,22,h+1]:[R(p.x)-11,R(p.y)-h,22,h];",
   "why": "caja: whoever sits is touched above the table's edge, down to the old FILA + 3 (their feet row + 1): relative to them (the same box at the old row 150)"
  },
  {
   "line": 147,
   "act": "*",
   "src": "else if(p.mano)tenida(c,p.mano,x+8,p.sent?MESA[1]+7:hy+18);",
   "to": "else if(p.mano)tenida(c,p.mano,x+8,p.sent?y-13:hy+18);",
   "why": "gente: what a sitter holds lies at the table's edge in front of them (the old MESA[1] + 7, 13 rows over their feet): relative to them"
  },
  {
   "line": 174,
   "act": "*",
   "src": "for(let j=0;j<12;j++)fr(c,x+2-(j>>2),MESA[1]-10+j,4,1,j%3?\"#FFFFFF\":\"#E4E4EE\");fr(c,x,MESA[1]+1,6,2,\"#D0302A\");",
   "to": "for(let j=0;j<12;j++)fr(c,x+2-(j>>2),R(m.y)-30+j,4,1,j%3?\"#FFFFFF\":\"#E4E4EE\");fr(c,x,R(m.y)-19,6,2,\"#D0302A\");",
   "why": "draw (W.tiron): the corner of the cloth the baby pulls, at mamá's place: relative to her (the old MESA[1] = her feet row - 20)"
  },
  {
   "line": 248,
   "act": "*",
   "src": "if(k===\"plato\"){await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,xDe(i,\"plato\"),FILA-2-(ps.plato.n-1)*3,5);ps.plato.con=\"bizcocho\";}",
   "to": "if(k===\"plato\"){await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,xDe(i,\"plato\"),FILA+SD[i]-2-(ps.plato.n-1)*3,5);ps.plato.con=\"bizcocho\";}",
   "why": "sirve: the slice flies onto the plate at place i (FILA + SD[i])"
  },
  {
   "line": 249,
   "act": "*",
   "src": "W.vierte={x:xDe(i,\"taza\")-2,y:FILA-8+dyDe(i,\"taza\")};",
   "to": "W.vierte={x:xDe(i,\"taza\")-2,y:FILA+SD[i]-8+dyDe(i,\"taza\")};",
   "why": "sirve: the jug pours into the cup at place i"
  },
  {
   "line": 252,
   "act": "*",
   "src": "await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,x-1,FILA-8,5);const v={k:\"bizcocho\",x:x-1,y:FILA-8};",
   "to": "await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,x-1,FILA+SD[i]-8,5);const v={k:\"bizcocho\",x:x-1,y:FILA+SD[i]-8};",
   "why": "sirvemal: the slice lands on the cup at place i"
  },
  {
   "line": 253,
   "act": "*",
   "src": "W.vierte={x:x-2,y:FILA-6,h:8};",
   "to": "W.vierte={x:x-2,y:FILA+SD[i]-6,h:8};",
   "why": "sirvemal: the jug pours onto the plate at place i"
  },
  {
   "line": 350,
   "act": "*",
   "src": "y1=id===\"coqui\"?pies()+3:FILA;",
   "to": "y1=id===\"coqui\"?pies()+3:FILA+SD[sitio(id)];",
   "why": "reparte26: what goes round lands at each place (FILA + SD)"
  },
  {
   "line": 336,
   "act": "*",
   "src": "c=Object.assign({x:SILLA[i]-2,y:FRENTE},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+(202-FRENTE)*s/4;",
   "to": "c=Object.assign({x:SILLA[i]-2,y:FRENTE+SD[i]},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+SD[i]+(202+FC[i]-FRENTE-SD[i])*s/4;",
   "why": "canelo: what was set aside in front of place i (FRENTE + SD[i]) falls from the table to the floor in front of it (202 + FC[i])"
  },
  {
   "line": 23,
   "act": "*",
   "src": "const EN={platos:[36,MOSTR[1]+7],tazas:[54,MOSTR[1]+6],bandeja:[44,MOSTR[1]+8],comidas:[38,MOSTR[1]+8],vasos:[61,MOSTR[1]+8],jarron:[78,MOSTR[1]+6]};",
   "to": "const EN={platos:[36,113],tazas:[49,106],bandeja:[39,109],comidas:[35,111],vasos:[52,105],jarron:[65,98]},ENQ={platos:[38,MOSTR[1]+7],tazas:[54,MOSTR[1]+6],bandeja:[44,MOSTR[1]+8],comidas:[38,MOSTR[1]+8],vasos:[61,MOSTR[1]+8],jarron:[78,MOSTR[1]+6]};",
   "places": [
    {
     "who": "mostrador.tazas",
     "old": [54, 112],
     "new": [49, 106],
     "world": [0.5859, 4.6654, 1.3]
    },
    {
     "who": "mostrador.bandeja",
     "old": [44, 114],
     "new": [39, 109],
     "world": [0.4771, 5.1005, 1.3]
    },
    {
     "who": "mostrador.comidas",
     "old": [38, 114],
     "new": [35, 111],
     "world": [0.4771, 5.3181, 1.3]
    },
    {
     "who": "mostrador.vasos",
     "old": [61, 114],
     "new": [52, 105],
     "world": [0.6131, 4.5294, 1.3]
    },
    {
     "who": "mostrador.jarron",
     "old": [78, 112],
     "new": [65, 98],
     "world": [0.5859, 3.7951, 1.3]
    },
    {
     "who": "muestra",
     "old": [54, 92],
     "new": [49, 86],
     "world": [-2.0941, 1.9853, 0]
    },
    {
     "who": "muestra",
     "old": [35, 108],
     "new": [30, 103],
     "world": [-1.6862, 3.4267, 0]
    },
    {
     "who": "muestra",
     "old": [44, 108],
     "new": [39, 103],
     "world": [-1.4414, 3.182, 0]
    },
    {
     "who": "muestra",
     "old": [53, 108],
     "new": [48, 103],
     "world": [-1.1966, 2.9372, 0]
    },
    {
     "who": "cq",
     "old": [22, 144],
     "new": [24, 144],
     "world": [0.3807, 5.82, 0]
    }
   ],
   "why": "where each kind of thing stands on the counter (EN): the counter runs along the left wall, so its top falls half a row for every px to the left; each stack's bottom row moved by the least distance that puts it on the top, 2 rows inside its back edge and 1 inside its front; the thing lifted off a stack to be shown (W.muestra) moves with its stack. ENQ, the old EN: the places on the floor in front of the counter made from it (the frog fetching, abuela at the counter, Canelo begging) keep their old screen points (they did not need to move), but the frog fetching plates (ENQ.platos 2 px right of the old EN.platos), so that he is whole in the view with 3 px to spare"
  },
  {
   "line": 220,
   "act": "pon",
   "src": "const key=k+\"s\",e=EN[M[key]!=null?key:\"bandeja\"];await ranaA(e[0]+2,171);",
   "to": "const key=k+\"s\",e=ENQ[M[key]!=null?key:\"bandeja\"];await ranaA(e[0]+2,171);",
   "why": "ranaTrae: the frog fetches at the counter where he did (ENQ: the old EN)"
  },
  {
   "line": 326,
   "act": "lleva26",
   "src": "await ranaA(EN[key][0]+4,173);",
   "to": "await ranaA(ENQ[key][0]+4,173);",
   "why": "acts.lleva26: the frog fetches at the counter where he did (ENQ)"
  },
  {
   "line": 314,
   "lines": [314, 318, 323, 328, 348],
   "act": "*",
   "src": "mueve(\"abuela\",EN.jarron[0]+26,182)",
   "to": "mueve(\"abuela\",ENQ.jarron[0]+26,182)",
   "why": "llena26, abuelada, ofrece26, abuelalleva, reparte26: abuela at the counter where she stood (ENQ)"
  },
  {
   "line": 345,
   "act": "canelo26",
   "src": "await perroA(EN.comidas[0]+52,198);",
   "to": "await perroA(ENQ.comidas[0]+52,198);",
   "why": "acts.canelo26: Canelo sits begging in front of the counter where he did (ENQ)"
  },
  {
   "line": 159,
   "act": "*",
   "src": "if(E.olla===2)tenida(c,\"ollavacia\",ESTUFA[0]+13,ESTUFA[1]+3);else if(E.olla){tenida(c,\"olla\",ESTUFA[0]+13,ESTUFA[1]+3);if(E.tapa)tenida(c,\"tapa\",ESTUFA[0]+13,ESTUFA[1]-9);",
   "to": "if(E.olla===2)tenida(c,\"ollavacia\",ESTUFA[0]+16,ESTUFA[1]+5);else if(E.olla){tenida(c,\"olla\",ESTUFA[0]+16,ESTUFA[1]+5);if(E.tapa)tenida(c,\"tapa\",ESTUFA[0]+16,ESTUFA[1]-7);",
   "places": [
    {
     "who": "estufa.olla",
     "old": [203, 107],
     "new": [206, 109],
     "world": [5.0189, 0.5587, 1.3]
    }
   ],
   "why": "draw: the pot (and its lid) on the stove's top, over its left burner"
  },
  {
   "line": 159,
   "act": "*",
   "src": "[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+p[0]+((t+i)%3)-1,ESTUFA[1]+p[1]-((t+i*2)%6),2,3,\"#FFFFFF\"));",
   "to": "[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+3+p[0]+((t+i)%3)-1,ESTUFA[1]+2+p[1]-((t+i*2)%6),2,3,\"#FFFFFF\"));",
   "why": "draw: the steam rises from the pot (moved with it), against the dark panel behind the stove"
  },
  {
   "line": 160,
   "act": "*",
   "src": "if(E.bizcocho)tenida(c,\"entero\",ESTUFA[0]+17,ESTUFA[1]+4);if(E.jarra)tenida(c,\"jarra\",ESTUFA[0]+25,ESTUFA[1]-1);if(E.pastel)tenida(c,\"pastel\",ESTUFA[0]+5,ESTUFA[1]+6);",
   "to": "if(E.bizcocho)tenida(c,\"entero\",ESTUFA[0]+17,ESTUFA[1]+5);if(E.jarra)tenida(c,\"jarra\",ESTUFA[0]+24,ESTUFA[1]+0);if(E.pastel)tenida(c,\"pastel\",ESTUFA[0]+11,ESTUFA[1]+6);",
   "places": [
    {
     "who": "estufa.entero",
     "old": [207, 108],
     "new": [207, 109],
     "world": [5.0461, 0.5315, 1.3]
    },
    {
     "who": "estufa.jarra",
     "old": [215, 103],
     "new": [214, 104],
     "world": [4.9645, 0.0692, 1.3]
    },
    {
     "who": "estufa.pastel",
     "old": [195, 110],
     "new": [201, 110],
     "world": [4.9373, 0.7491, 1.3]
    }
   ],
   "why": "draw: the cake, the jug and the pink cake on the stove's top, each moved by the least distance that puts it on the top"
  }
 ],
 "storyMoves": [
  {
   "old": [104, 150],
   "new": [104, 135],
   "who": "sitting",
   "why": "sitting at place 0 (x 104): on its chair (150 + SD[0])"
  },
  {
   "old": [128, 150],
   "new": [128, 147],
   "who": "sitting",
   "why": "sitting at place 1 (x 128): on its chair (150 + SD[1])"
  },
  {
   "old": [152, 150],
   "new": [152, 159],
   "who": "sitting",
   "why": "sitting at place 2 (x 152): on its chair (150 + SD[2])"
  },
  {
   "old": [176, 150],
   "new": [176, 171],
   "who": "sitting",
   "why": "sitting at place 3 (x 176): on its chair (150 + SD[3])"
  },
  {
   "old": [187, 150],
   "new": [173, 159],
   "who": "cosa",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa: the plate set down on the table's top (round 1: 175, 160, the least move onto the top); round 2, pone.si: the plate set down (by the cloth's edge: 44% plain round it): the least move from there that puts the cloth's plain top round half its outline"
  },
  {
   "old": [178, 150],
   "new": [167, 158],
   "who": "cosa",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa: the plate on the table's top (round 1: 171, 158, the least move onto the top); round 2, pone.no: the plate beside the cloth, moved with it: the least move from there that puts the cloth's plain top round half its outline"
  },
  {
   "old": [187, 151],
   "new": [172, 160],
   "who": "cosa",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa: the cloth on the table's top (round 1: 176, 160, the least move onto the top); round 2, pone.no: the little cloth (by the cloth's edge: 30% plain round it): the least move from there that puts the cloth's plain top round half its outline"
  },
  {
   "old": [176, 172],
   "new": [176, 170],
   "who": "standing",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa cocina.si: abuela in the kitchen, by the stove: the old point is not clear floor; moved by the least distance to clear floor"
  },
  {
   "old": [110, 206],
   "new": [144, 120],
   "who": "standing",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa plato, taza, cuchara, tenedor (round 2): whoever holds up a thing stands on the floor before the back wall, left of the window, so the thing is seen against the plaster (at the old point, in front of the table, it was seen against the checker floor: 18 to 61% plain round it); the nearest such place to the old one (86 px), all eight pictures 58% plain and more"
  },
  {
   "old": [205, 170],
   "new": [202, 154],
   "who": "standing",
   "uses": ["cual-mesa.json"],
   "why": "cual-mesa cuchillo (round 2): abuela with the knife or the spoon stands before the stove, the thing seen against its white front (at FOGON, 202, 194, it was against the floor and the table: 6 to 20% plain round it); the nearest such place to FOGON (40 px)"
  },
  {
   "old": [176, 176],
   "new": [115, 203],
   "who": "abuela",
   "uses": ["cual-mesa.json cocina.no"],
   "scene": "frutas",
   "spot": "abuela.delante",
   "why": "cual-mesa cocina.no (W.afuera: abuela outside, at a stall): the picture is El colmado's fruit stall (frutas, its spot abuela.delante: in front of the stand)"
  }
 ],
 "helps": {
  "what": "none: nothing is painted round an empty place; the set needs no help for a sprite-layer thing",
  "lines": []
 },
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as mesa.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
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
  "what": "where a bubble goes (mesa.js draw: line 187 for a person, 188 for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible person's and the frog's, its own too); if none is, the first (the old)",
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
  "faces": "a face: [hx - 6, top + 6, 12, 10] (eyes to chin), top the sprite's first opaque row, hx the middle of its top 10 rows; the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "board": [2, 2, 68, 26],
  "boardWhat": "in the 196 x 216 display, then + the view's x0: W.tarjeta (the rounds card) [2, 2, 68, 26], hidden while three picture bubbles stand at the top (hud)"
 },
 "code": [
  {
   "line": 3,
   "numbers": {
    "other": ["3"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 12,
   "numbers": {
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 21,
   "numbers": {
    "other": ["142", "148", "157"],
    "place": ["92", "130", "96", "30", "104", "128", "152", "176", "24", "106", "62", "12", "190", "104", "30", "42"]
   },
   "to": {
    "moves": [
     "FILA=148,FRENTE=157;"
    ],
    "points": ["mesa", "sillas", "mostrador", "estufa"],
    "spots": ["silla.0", "silla.1", "silla.2", "silla.3", "puesto.0", "frente.0"]
   },
   "note": "PISO (the old floor's first row): the set's floor; MESA: the table (the set's, points.mesa: its box things.mesa; its far edge for a sitter's hand and the cloth's pulled corner: relative to the sitter, moves); SILLA: the seats' x, unchanged, their rows 150 + SD (moves); MOSTR: the counter (the set's, points.mostrador; EN moved onto its top); ESTUFA: the stove (the set's, points.estufa; its things moved onto its top, moves); FILA, FRENTE: the rows at each place, + SD (moves)"
  },
  {
   "line": 23,
   "numbers": {
    "place": ["36", "1", "54", "1", "44", "1", "38", "1", "61", "1", "78", "1"],
    "offset": ["7", "6", "8", "8", "8", "6"]
   },
   "to": {
    "moves": [
     "const EN={platos:[36,MOSTR[1]+7],tazas:[54,MOSTR[1]+6],bandeja:[44,MOSTR[1]+8],comidas:[38,MOSTR[1]+8],vasos:[61,MOSTR[1]+8],jarron:[78,MOSTR[1]+6]};"
    ],
    "spots": ["mostrador.platos", "mostrador.tazas", "mostrador.bandeja", "mostrador.comidas", "mostrador.vasos", "mostrador.jarron"]
   },
   "note": "EN: where each kind of thing stands on the counter: moved onto its top (moves)"
  },
  {
   "line": 24,
   "numbers": {
    "place": ["75", "160", "205", "170", "196", "204"]
   },
   "to": {
    "spots": ["luis", "fogon", "canelo"]
   },
   "note": "LUIS, FOGON, CAN: the floor rule, the same screen places (spots)"
  },
  {
   "line": 31,
   "numbers": {
    "dropped": ["0", "0", "5", "2", "2", "6"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 32,
   "numbers": {
    "dropped": ["84", "1", "22", "90", "8", "0", "8", "4"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 33,
   "numbers": {
    "dropped": ["80", "1", "186", "8", "2", "8", "0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 35,
   "numbers": {
    "dropped": ["0", "12", "6", "16", "12", "0", "6", "16", "0", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 36,
   "numbers": {
    "dropped": ["0", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 38,
   "numbers": {
    "dropped": ["0", "58", "20", "58", "0", "112", "20", "112", "2", "20", "56", "3", "56", "1", "0", "56", "22", "3", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 40,
   "numbers": {
    "dropped": ["182", "28", "34", "36", "208", "54", "10", "9", "180", "26", "38", "40", "1", "181", "27", "36", "38", "3", "198", "28", "2", "36", "2", "182", "45", "34", "2", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 42,
   "numbers": {
    "dropped": ["27", "34", "42", "40", "2", "27", "34", "42", "2", "4", "27", "72", "42", "2", "0", "26", "33", "44", "42", "47", "36", "2", "36", "0", "43", "51", "52", "2", "6", "30", "38", "16", "32", "1", "50", "38", "16", "32", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 44,
   "numbers": {
    "dropped": ["0", "1", "3", "2", "4", "1", "3", "2", "0", "1", "3", "2", "2", "0", "0", "1", "1", "3", "1", "2", "2", "6", "1", "3"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 45,
   "numbers": {
    "dropped": ["54", "1", "3", "3", "2", "20", "0", "48", "60", "1", "3", "9", "2", "5"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 46,
   "numbers": {
    "dropped": ["0", "2", "1", "2", "4", "3", "0", "2", "1", "2", "4", "2", "0", "2", "1", "3", "2", "2", "4", "2", "0", "3", "1", "1", "2", "6", "3", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 48,
   "numbers": {
    "dropped": ["0", "1", "2", "3", "0", "1", "2", "5", "0", "1", "5", "2", "2", "0", "1", "1", "1", "2", "2", "3", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 49,
   "numbers": {
    "dropped": ["0", "3", "1", "16", "2", "6", "22", "0", "7", "1", "19", "2", "14", "2", "0", "6", "0", "14", "0", "22", "1", "8", "3", "3"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 51,
   "numbers": {
    "dropped": ["9", "1", "26", "2", "44", "0", "7", "1", "26", "2", "44", "0", "1", "26", "1", "18", "9", "18", "4", "2", "9", "18", "1", "4", "10", "1", "27", "20", "10"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo): the set, dropped"
  },
  {
   "line": 54,
   "numbers": {
    "dropped": ["0", "0", "150", "1", "1", "40"]
   },
   "to": {
    "dropped": true
   },
   "note": "the stall (mkPuesto, W.afuera): El colmado's stall (pictures cocina.no), dropped"
  },
  {
   "line": 55,
   "numbers": {
    "dropped": ["96", "200", "96", "112", "96", "3", "2", "95", "95", "106", "18", "98", "112", "3", "60", "1", "195", "112", "3", "60", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the stall (mkPuesto, W.afuera): El colmado's stall (pictures cocina.no), dropped"
  },
  {
   "line": 56,
   "numbers": {
    "dropped": ["100", "150", "96", "22", "2", "100", "150", "96", "2", "4", "99", "149", "98", "24", "110", "120", "115", "136", "146", "141", "164", "174", "184", "179", "0", "146", "3", "2", "5", "0", "4.4", "4", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the stall (mkPuesto, W.afuera): El colmado's stall (pictures cocina.no), dropped"
  },
  {
   "line": 58,
   "numbers": {
    "dropped": ["2", "12", "66", "2", "3"]
   },
   "to": {
    "dropped": true
   },
   "note": "the old table's sprite (mkMesa): the set's table and cloth, dropped"
  },
  {
   "line": 59,
   "numbers": {
    "dropped": ["0", "6", "6", "12", "1", "3", "50", "2", "3", "7", "3", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the old table's sprite (mkMesa): the set's table and cloth, dropped"
  },
  {
   "line": 60,
   "numbers": {
    "dropped": ["0", "12", "5", "1", "0", "3", "12", "2", "2", "10", "6", "5", "3", "2"]
   },
   "to": {
    "dropped": true
   },
   "note": "the old table's sprite (mkMesa): the set's table and cloth, dropped"
  },
  {
   "line": 61,
   "numbers": {
    "dropped": ["3", "5", "6", "5", "0", "1", "4", "26", "0", "0", "1", "1", "26", "1"]
   },
   "to": {
    "dropped": true
   },
   "note": "the old table's sprite (mkMesa): the set's table and cloth, dropped"
  },
  {
   "line": 65,
   "numbers": {
    "drawing": ["13", "7", "6.5", "3.5", "5.6", "2.8", "6.5", "3.2", "3.2", "1.4"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 66,
   "numbers": {
    "drawing": ["13", "9", "6.5", "5.5", "4.4", "3", "6.5", "3.6", "5.6", "3", "6.5", "3.4", "4", "1.9"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 67,
   "numbers": {
    "drawing": ["10", "10", "1", "2", "6", "7", "1", "2", "2", "7", "1", "8", "6", "1", "7", "3", "1", "1", "8", "4", "1", "3", "7", "7", "1", "1", "2", "2", "4", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 68,
   "numbers": {
    "drawing": ["10", "10", "1", "2", "6", "7", "1", "2", "2", "7", "1", "8", "6", "1", "7", "3", "1", "1", "8", "4", "1", "3", "7", "7", "1", "1", "2", "2", "4", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 69,
   "numbers": {
    "drawing": ["10", "14", "1", "1", "8", "12", "1", "5", "8", "8", "1", "5", "8", "1", "1", "1", "2", "12"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 70,
   "numbers": {
    "drawing": ["10", "14", "1", "1", "8", "12", "1", "1", "2", "12"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 71,
   "numbers": {
    "drawing": ["16", "9", "1", "2", "12", "6", "1", "2", "12", "2", "12", "1", "2", "8", "1", "7", "12", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 72,
   "numbers": {
    "drawing": ["9", "18", "4.5", "5", "3", "4", "4", "9", "1", "8"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 73,
   "numbers": {
    "drawing": ["9", "18", "1", "4", "7", "1", "1", "6", "1", "7", "7", "2", "4", "9", "1", "8"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 74,
   "numbers": {
    "drawing": ["9", "18", "4.5", "3.5", "2.2", "2.6", "2", "3", "5", "7", "2", "3", "1", "7", "6", "3", "1", "7", "3", "10", "3", "1", "3", "11", "3", "6", "3", "11", "1", "6"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 75,
   "numbers": {
    "drawing": ["10", "9", "1", "4", "8", "4", "1", "4", "8", "1", "1", "2", "8", "2", "4", "1", "5", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 76,
   "numbers": {
    "drawing": ["20", "11", "0", "8", "20", "2", "1", "3", "7", "3", "13", "3", "0", "3", "0", "1", "2", "6", "3", "0", "1", "6", "2", "0", "2", "1", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 77,
   "numbers": {
    "drawing": ["11", "11", "2", "6", "7", "4", "3", "6", "1", "4", "6", "6", "1", "4", "5.5", "5", "4.4", "2.6", "5", "1", "2", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 78,
   "numbers": {
    "drawing": ["12", "9", "2", "2", "8", "6", "2", "2", "8", "2", "1", "3", "2", "4", "4", "0", "3", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 79,
   "numbers": {
    "drawing": ["22", "13", "2", "6", "18", "6", "2", "20", "3", "6", "1", "6", "1", "5", "20", "2", "6", "4", "11", "3", "16", "4", "0", "1", "3", "2.4"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 80,
   "numbers": {
    "drawing": ["9", "7", "4.5", "3.5", "3.6", "2.6", "4", "2", "1", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 81,
   "numbers": {
    "drawing": ["24", "18", "12", "9", "9", "8", "12", "9", "7", "6", "1", "8", "2", "3", "21", "8", "2", "3"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 82,
   "numbers": {
    "drawing": ["14", "17", "2", "2", "8", "14", "2", "2", "2", "14", "10", "5", "2", "1", "12", "6", "1", "5", "10", "11", "2", "1", "0", "2", "2", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 83,
   "numbers": {
    "drawing": ["24", "13", "12", "8", "10.6", "4", "12", "5.5", "10.6", "3.6", "6", "12", "18", "4"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 84,
   "numbers": {
    "drawing": ["17", "9", "1", "4", "5", "4", "1", "3", "5", "2", "4", "5", "2", "3", "9", "5", "4", "3", "9", "4", "4", "1", "9", "6", "1", "2", "7", "1", "2", "2", "7", "7", "14", "7", "15", "4", "6", "2", "0", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 85,
   "numbers": {
    "drawing": ["19", "8", "8", "4", "5.4", "1.8", "12", "3", "3", "1.4", "4", "5", "2.4", "1.2", "13", "5", "3", "1", "6", "3", "3", "1", "17", "6", "1", "1", "17", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 86,
   "numbers": {
    "drawing": ["21", "8", "9", "4", "7", "2.4", "15", "3", "3.4", "1.6", "3", "6", "4", "1", "6", "3", "4", "1", "19", "6", "1", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 87,
   "numbers": {
    "drawing": ["34", "7", "1", "1", "32", "5", "1", "33", "4", "1", "2", "5", "1", "3", "32", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 88,
   "numbers": {
    "drawing": ["24", "16", "3", "5", "18", "10", "3", "5", "4", "10", "3", "13", "18", "2", "1", "6", "2", "3", "21", "6", "2", "3", "3", "4", "18", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 89,
   "numbers": {
    "drawing": ["22", "7", "11", "7", "9.6", "5", "9", "0", "4", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 90,
   "numbers": {
    "drawing": ["15", "14", "3", "3", "8", "10", "3", "3", "3", "10", "2", "2", "10", "2", "11", "5", "2", "1", "13", "6", "1", "4", "11", "10", "2", "1", "0", "3", "3", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 91,
   "numbers": {
    "drawing": ["14", "17", "2", "2", "8", "14", "2", "6", "8", "10", "2", "2", "2", "14", "10", "5", "2", "1", "12", "6", "1", "5", "10", "11", "2", "1", "0", "2", "2", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 92,
   "numbers": {
    "drawing": ["13", "8", "6.5", "4.6", "5", "2.6", "2", "5", "4", "3", "6", "5", "8", "3", "10", "5", "0", "1", "0", "1", "1", "1", "4.5", "2.6", "1.6", "1.5", "8.5", "2.8", "1.6", "1.5"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 93,
   "numbers": {
    "drawing": ["14", "8", "4.5", "4.5", "3.6", "3", "4", "3", "1", "2", "9", "3", "4", "4", "9", "3", "4", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 94,
   "numbers": {
    "drawing": ["13", "7", "4.5", "4", "3.6", "2.4", "9", "4", "3", "2.2", "8", "3"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 95,
   "numbers": {
    "drawing": ["15", "8", "4", "3", "7", "2", "3", "2", "3", "5", "11", "2", "11", "5", "0", "1", "1.7", "1.7"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 96,
   "numbers": {
    "drawing": ["32", "18", "16", "12", "14", "5.4", "4", "14", "24", "2", "8", "9", "2", "4", "21", "9", "2", "4", "8", "5", "5", "2", "2", "2", "13", "6", "19", "2", "6", "6", "18", "1", "8", "8", "26", "3", "2", "1", "28", "4", "1", "3", "26", "7", "2", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 97,
   "numbers": {
    "drawing": ["30", "8", "1", "2", "28", "5", "1", "2", "28", "1", "2", "3", "26", "3"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 98,
   "numbers": {
    "drawing": ["13", "20", "4", "11", "5", "8", "4", "11", "2", "8", "3", "5", "9", "4", "6", "2", "0", "1", "2", "1", "9", "1", "2", "1", "0", ".5", "1", "2.2", "2.2", "2"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 99,
   "numbers": {
    "drawing": ["12", "10", "1", "1", "10", "8", "1", "4", "10", "1", "1", "7", "10", "1"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 100,
   "numbers": {
    "drawing": ["15", "8", "7", "4", "5.4", "2.6", "11", "2.5", "2", "1.3", "2", "6", "13", "6"]
   },
   "to": "unchanged",
   "note": "a thing's own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged"
  },
  {
   "line": 102,
   "numbers": {
    "drawing": ["1", "1"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 105,
   "numbers": {
    "drawing": ["1", "0", "1", "6", "4", "12", "2", "5", "4", "10", "1", "1", "3"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 106,
   "numbers": {
    "drawing": ["1", "3", "2", "1", "2", "3", "2", "3", "10", "1", "3", "1", "12", "1", "3", "4", "9", "1", "2"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 107,
   "numbers": {
    "drawing": ["3", "4", "1", "1", "2", "5", "1", "1", "3", "1", "1"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 108,
   "numbers": {
    "drawing": ["1", "1", "1", "1", "4", "3", "2", "3", "13", "1", "2", "15", "1", "2"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 111,
   "numbers": {
    "drawing": ["9", "0", "9"]
   },
   "to": "unchanged",
   "note": "a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged"
  },
  {
   "line": 114,
   "numbers": {
    "count": ["6"],
    "other": ["0", "0"],
    "offset": ["3"]
   },
   "to": "unchanged",
   "note": "no place: count, other, offset"
  },
  {
   "line": 115,
   "numbers": {
    "count": ["4"],
    "other": ["0"],
    "state": ["0"]
   },
   "to": "unchanged",
   "note": "no place: count, other, state"
  },
  {
   "line": 117,
   "numbers": {
    "state": ["0"]
   },
   "to": "unchanged",
   "note": "no place: state"
  },
  {
   "line": 119,
   "numbers": {
    "place": ["104", "161", "1", "104", "161", "1"]
   },
   "to": {
    "spots": ["frog.inicio", "frog.centro"]
   },
   "note": "the floor rule: the same screen places, in front of the table"
  },
  {
   "line": 120,
   "numbers": {
    "count": ["51", "37", "49"],
    "other": ["44", "56"]
   },
   "to": "unchanged",
   "note": "heights of the sprites (alto), not places"
  },
  {
   "line": 121,
   "numbers": {
    "count": ["0"],
    "offset": ["11", "3", "11"],
    "place": ["22", "22"]
   },
   "to": {
    "moves": [
     "return p.sent?[R(p.x)-11,R(p.y)-h,22,FILA+3-(R(p.y)-h)]:[R(p.x)-11,R(p.y)-h,22,h];"
    ]
   },
   "note": "moved (moves): caja; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 122,
   "numbers": {
    "other": ["1"],
    "count": ["0"]
   },
   "to": "unchanged",
   "note": "no place: other, count"
  },
  {
   "line": 123,
   "numbers": {
    "other": ["2"],
    "order": ["1"],
    "place": ["0", "1", "30", "18", "0", "1", "19", "20", "0", "1", "24", "22"],
    "offset": ["15", "16", "9", "18", "12", "18"]
   },
   "to": "unchanged",
   "note": "a counter stack's box relative to EN: unchanged (EN moved)"
  },
  {
   "line": 126,
   "numbers": {
    "offset": ["9"],
    "count": ["38", "40"],
    "other": ["14", "16", "0"],
    "place": ["18"]
   },
   "to": "unchanged",
   "note": "the shown thing's, abuela's offer's, the baby's and the dog's boxes: relative, unchanged"
  },
  {
   "line": 127,
   "numbers": {
    "offset": ["29", "42"],
    "place": ["20", "18"],
    "other": ["0"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 128,
   "numbers": {
    "count": ["0"],
    "offset": ["3", "38"],
    "place": ["18", "18"],
    "other": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 129,
   "numbers": {
    "count": ["0"],
    "offset": ["14", "20"],
    "place": ["28", "22"],
    "other": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 130,
   "numbers": {
    "place": ["0", "1", "26", "20"],
    "offset": ["1", "16"],
    "other": ["1"]
   },
   "to": {
    "things": ["olla", "mesa", "estufa"]
   },
   "note": "the pot's box (moved with the pot: things.olla), the table's and the stove's (the set's: things.mesa, things.estufa)"
  },
  {
   "line": 131,
   "numbers": {
    "place": ["0", "1", "2", "3", "0", "1", "28", "46"],
    "offset": ["4", "8", "8", "4"],
    "other": ["0", "0"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 132,
   "numbers": {
    "place": ["22", "24", "196", "190"],
    "other": ["0"]
   },
   "to": {
    "things": ["cocina"]
   },
   "note": "the kitchen's box: unchanged, its hint box (things.cocina.hintBox)"
  },
  {
   "line": 135,
   "numbers": {
    "drawing": ["1", "1", "24", "20", "22", "18", "4", "17", "4", "4", "3", "18", "2", "2", "8", "22", "3", "3", "11", "16"]
   },
   "to": "unchanged",
   "note": "a thought bubble: relative to the head, unchanged"
  },
  {
   "line": 136,
   "numbers": {
    "count": ["0", "2", "1", "0"],
    "other": ["0", "1"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, other, offset"
  },
  {
   "line": 137,
   "numbers": {
    "count": ["2", "2", "0"],
    "offset": ["50", "1", "1"],
    "other": ["0", "1", "0"],
    "place": ["30"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 138,
   "numbers": {
    "offset": ["14", "17", "13", "15"],
    "place": ["0", "0"],
    "count": ["0", "3"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 139,
   "numbers": {
    "offset": ["19", "18"],
    "place": ["0", "2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 140,
   "numbers": {
    "offset": ["16", "27", "15", "26", "19", "26"],
    "place": ["7", "3", "6", "2", "2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 141,
   "numbers": {
    "count": ["2", "1", "2", "0"],
    "other": ["0", "0"],
    "offset": ["1", "1"]
   },
   "to": "unchanged",
   "note": "no place: count, other, offset"
  },
  {
   "line": 142,
   "numbers": {
    "count": ["0"],
    "offset": ["1"],
    "other": ["1", "0"]
   },
   "to": "unchanged",
   "note": "no place: count, offset, other"
  },
  {
   "line": 143,
   "numbers": {
    "count": ["1", "2", "2", "39"],
    "offset": ["1"],
    "other": ["40"]
   },
   "to": "unchanged",
   "note": "no place: count, offset, other"
  },
  {
   "line": 144,
   "numbers": {
    "count": ["22"],
    "other": ["26"]
   },
   "to": "unchanged",
   "note": "no place: count, other"
  },
  {
   "line": 145,
   "numbers": {
    "offset": ["5", "4", "6", "12"],
    "count": ["2", "2"],
    "scale": ["2", "2"]
   },
   "to": "unchanged",
   "note": "no place: offset, count, scale"
  },
  {
   "line": 146,
   "numbers": {
    "offset": ["6", "6"],
    "count": ["2"]
   },
   "to": "unchanged",
   "note": "no place: offset, count"
  },
  {
   "line": 147,
   "numbers": {
    "offset": ["8", "7", "18"],
    "place": ["1"]
   },
   "to": {
    "moves": [
     "else if(p.mano)tenida(c,p.mano,x+8,p.sent?MESA[1]+7:hy+18);"
    ]
   },
   "note": "moved (moves): gente; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 148,
   "numbers": {
    "count": ["10", "13"],
    "offset": ["25", "8", "3", "4", "2", "3"],
    "place": ["0", "2", "6", "5", "4", "3", "2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 149,
   "numbers": {
    "scale": ["10", "10"],
    "count": ["34", "34"],
    "other": ["38", "38"],
    "offset": ["2"]
   },
   "to": "unchanged",
   "note": "no place: scale, count, other, offset"
  },
  {
   "line": 150,
   "numbers": {
    "scale": ["10"],
    "count": ["34"],
    "other": ["38"]
   },
   "to": "unchanged",
   "note": "no place: scale, count, other"
  },
  {
   "line": 151,
   "numbers": {
    "drawing": ["47", "2", "1", "0", "2", "1", "0", "1"]
   },
   "to": "unchanged",
   "note": "the frog and what he carries on his head; the bubble drawn twice its size: relative, unchanged"
  },
  {
   "line": 152,
   "numbers": {
    "drawing": ["1"]
   },
   "to": "unchanged",
   "note": "the frog and what he carries on his head; the bubble drawn twice its size: relative, unchanged"
  },
  {
   "line": 153,
   "numbers": {
    "drawing": ["3"]
   },
   "to": "unchanged",
   "note": "the frog and what he carries on his head; the bubble drawn twice its size: relative, unchanged"
  },
  {
   "line": 154,
   "numbers": {
    "drawing": ["2", "2", "0", "0"]
   },
   "to": "unchanged",
   "note": "the frog and what he carries on his head; the bubble drawn twice its size: relative, unchanged"
  },
  {
   "line": 156,
   "numbers": {
    "place": ["0"],
    "other": ["0"]
   },
   "to": {
    "dropped": true
   },
   "note": "the background (fondo, mkPuesto): the set, for setKey(W); W.afuera (the stall, one review picture) is El colmado's stall (pictures cocina.no)"
  },
  {
   "line": 157,
   "numbers": {
    "place": ["0", "1", "2", "16", "0", "1", "14", "6", "0", "1", "14", "2"],
    "offset": ["6", "18", "12", "8", "27", "8", "26"]
   },
   "to": {
    "dropped": true
   },
   "note": "the oven lit (W.estufa.horno): the set's (setKey horno: the stove's oven window glows)"
  },
  {
   "line": 159,
   "numbers": {
    "count": ["2", "6", "3", "6"],
    "place": ["0", "1", "0", "1", "0", "1", "9", "14", "14", "18", "18", "13", "0", "0", "1", "1", "2", "3"],
    "offset": ["13", "3", "13", "3", "13", "9", "1"],
    "time": ["2"],
    "scale": ["2"]
   },
   "to": {
    "moves": [
     "if(E.olla===2)tenida(c,\"ollavacia\",ESTUFA[0]+13,ESTUFA[1]+3);else if(E.olla){tenida(c,\"olla\",ESTUFA[0]+13,ESTUFA[1]+3);if(E.tapa)tenida(c,\"tapa\",ESTUFA[0]+13,ESTUFA[1]-9);",
     "[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+p[0]+((t+i)%3)-1,ESTUFA[1]+p[1]-((t+i*2)%6),2,3,\"#FFFFFF\"));"
    ]
   },
   "note": "moved (moves): draw; draw; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 160,
   "numbers": {
    "place": ["0", "1", "0", "1", "0", "1"],
    "offset": ["17", "4", "25", "1", "5", "6"]
   },
   "to": {
    "moves": [
     "if(E.bizcocho)tenida(c,\"entero\",ESTUFA[0]+17,ESTUFA[1]+4);if(E.jarra)tenida(c,\"jarra\",ESTUFA[0]+25,ESTUFA[1]-1);if(E.pastel)tenida(c,\"pastel\",ESTUFA[0]+5,ESTUFA[1]+6);"
    ]
   },
   "note": "moved (moves): draw; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 162,
   "numbers": {
    "state": ["0"],
    "count": ["0"],
    "place": ["0", "1"],
    "scale": ["2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 163,
   "numbers": {
    "state": ["0"],
    "count": ["0", "2", "1"],
    "place": ["0", "1"],
    "offset": ["5"],
    "scale": ["11", "5"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 164,
   "numbers": {
    "place": ["0", "1", "0", "1"],
    "offset": ["2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 165,
   "numbers": {
    "state": ["0"],
    "count": ["0", "2", "1"],
    "place": ["0", "1"],
    "offset": ["7"],
    "scale": ["15", "6"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 166,
   "numbers": {
    "state": ["0"],
    "count": ["0", "2", "1"],
    "place": ["0", "1"],
    "offset": ["4"],
    "scale": ["9", "3"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 167,
   "numbers": {
    "count": ["2"],
    "place": ["0", "1"],
    "offset": ["4"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 169,
   "numbers": {
    "count": ["0"]
   },
   "to": "unchanged",
   "note": "no place: count"
  },
  {
   "line": 171,
   "numbers": {
    "place": ["1", "3", "0", "1"],
    "offset": ["6", "6"],
    "count": ["1"],
    "other": ["0"]
   },
   "to": {
    "dropped": true,
    "moves": [
     "L.push({y:MESA[1]+MESA[3]+6,d:"
    ]
   },
   "note": "the table (mkMesa, in the sorted list): the set's table and its cloth (setKey mantel); what stands on it is still drawn there, at its entry; the set's table and chairs are drawn again over whoever is behind them (front); moved (moves): draw"
  },
  {
   "line": 172,
   "numbers": {
    "offset": ["12"],
    "other": ["0"],
    "count": ["0"]
   },
   "to": {
    "moves": [
     "fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+dy+e.dy));"
    ]
   },
   "note": "moved (moves): draw"
  },
  {
   "line": 173,
   "numbers": {
    "offset": ["4", "5", "7", "2"],
    "scale": ["7", "2"],
    "count": ["2"]
   },
   "to": {
    "moves": [
     "const x=SILLA[i]-4+j*7,y=FRENTE+(j%2)*2;"
    ]
   },
   "note": "moved (moves): draw"
  },
  {
   "line": 174,
   "numbers": {
    "place": ["1", "3", "1", "4", "1", "1", "6", "2"],
    "offset": ["7", "8", "2", "10", "1"],
    "other": ["0"],
    "count": ["12", "2", "3"]
   },
   "to": {
    "moves": [
     "L.push({y:MESA[1]+MESA[3]+7,d:",
     "for(let j=0;j<12;j++)fr(c,x+2-(j>>2),MESA[1]-10+j,4,1,j%3?\"#FFFFFF\":\"#E4E4EE\");fr(c,x,MESA[1]+1,6,2,\"#D0302A\");"
    ]
   },
   "note": "moved (moves): draw (W.tiron); draw (W.tiron); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 175,
   "numbers": {
    "count": ["0", "1", "2", "0", "0"],
    "other": ["0", "1", "0"],
    "offset": ["2", "1"],
    "place": ["13"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 176,
   "numbers": {
    "scale": ["16"]
   },
   "to": "unchanged",
   "note": "no place: scale"
  },
  {
   "line": 177,
   "numbers": {
    "count": ["0"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 178,
   "numbers": {
    "offset": ["4"]
   },
   "to": "unchanged",
   "note": "no place: offset"
  },
  {
   "line": 179,
   "numbers": {
    "offset": ["27"]
   },
   "to": "unchanged",
   "note": "no place: offset"
  },
  {
   "line": 183,
   "numbers": {
    "offset": ["9", "6", "1", "10"],
    "place": ["0.6", "2"],
    "count": ["10"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 184,
   "numbers": {
    "place": ["0", "2"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 185,
   "numbers": {
    "count": ["0"],
    "offset": ["7", "21"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 186,
   "numbers": {
    "count": ["1"],
    "offset": ["12", "24"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 187,
   "numbers": {
    "count": ["0"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 188,
   "numbers": {
    "count": ["1"],
    "offset": ["2"]
   },
   "to": "unchanged",
   "note": "no place: count, offset"
  },
  {
   "line": 190,
   "numbers": {
    "count": ["0", "12"],
    "offset": ["1"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: count, offset, other"
  },
  {
   "line": 192,
   "numbers": {
    "drawing": ["1", "2", "0", "2"]
   },
   "to": "unchanged",
   "note": "a picture bubble's icon (twice its size): relative, unchanged"
  },
  {
   "line": 193,
   "numbers": {
    "drawing": ["0", "3", "3", "66", "24"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 194,
   "numbers": {
    "drawing": ["10", "20", "6"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 195,
   "numbers": {
    "drawing": ["0", "1", "1", "3", "3", "0", "2", "1", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 196,
   "numbers": {
    "drawing": ["0", "11", "1", "4", "3", "10", "1", "4", "3", "0", "11", "1", "2", "2", "1", "11", "2", "2", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 197,
   "numbers": {
    "drawing": ["1", "13", "12", "1", "1", "1", "1", "12", "12", "1", "1", "12", "1", "1", "12", "1"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 198,
   "numbers": {
    "drawing": ["0"]
   },
   "to": "unchanged",
   "note": "the rounds card in the corner (hud): screen space, unchanged (talk.board)"
  },
  {
   "line": 201,
   "numbers": {
    "count": ["3", "3", "1"],
    "scale": ["6"],
    "state": ["0", "1", "1", "0"],
    "offset": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, scale, state, offset"
  },
  {
   "line": 202,
   "numbers": {
    "count": ["5"],
    "state": ["1"],
    "scale": ["8"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, state, scale, other"
  },
  {
   "line": 203,
   "numbers": {
    "offset": ["16", "27"]
   },
   "to": "unchanged",
   "note": "the frog's middle and feet relative to q: unchanged"
  },
  {
   "line": 204,
   "numbers": {
    "scale": ["16", "27", "40"],
    "count": ["3", "1", "3"],
    "offset": ["16", "27"]
   },
   "to": "unchanged",
   "note": "ranaA: q relative to the point; the hop count by the distance (40 px a hop): unchanged"
  },
  {
   "line": 205,
   "numbers": {
    "place": ["0", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 208,
   "numbers": {
    "count": ["0"],
    "state": ["1", "0", "1", "1"],
    "place": ["6", "152", "152", "2", "152", "150"]
   },
   "to": {
    "moves": [
     "if(p.vis===0){p.vis=1;p.x=6;p.y=152;p.sent=0;}await mueve(id,p.x,152,2);await mueve(id,SILLA[i],152);p.sent=1;p.y=150;p.dir=1;"
    ]
   },
   "note": "moved (moves): sienta; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 209,
   "numbers": {
    "state": ["0", "0"],
    "place": ["152", "2", "4", "152"]
   },
   "to": {
    "moves": [
     "p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,152,2);await mueve(id,4,152);p.vis=0;"
    ]
   },
   "note": "moved (moves): sale; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 210,
   "numbers": {
    "place": ["0", "1"],
    "offset": ["22"],
    "other": ["204"],
    "count": ["3"],
    "state": ["1"]
   },
   "to": {
    "moves": [
     "if(Math.hypot(ab.x-x,ab.y-y)>3)await mueve(\"abuela\",x,y);ab.dir=-1;}",
     "x=i==null?FOGON[0]:SILLA[i]+22,y=i==null?FOGON[1]:204;"
    ]
   },
   "note": "moved (moves): abuelaEn; abuelaEn; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 211,
   "numbers": {
    "other": ["1"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: other, state"
  },
  {
   "line": 212,
   "numbers": {
    "place": ["0", "1"],
    "offset": ["15"],
    "other": ["202"],
    "count": ["3"],
    "state": ["1"]
   },
   "to": {
    "moves": [
     "x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202;"
    ]
   },
   "note": "moved (moves): luisEn; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 213,
   "numbers": {
    "count": ["3"],
    "scale": ["7"],
    "offset": ["1"],
    "other": ["1"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count, scale, offset, other, state"
  },
  {
   "line": 215,
   "numbers": {
    "state": ["2", "0"],
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 216,
   "numbers": {
    "state": ["1"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: state, other"
  },
  {
   "line": 217,
   "numbers": {
    "state": ["2", "2"],
    "other": ["1", "0"]
   },
   "to": "unchanged",
   "note": "no place: state, other"
  },
  {
   "line": 219,
   "numbers": {
    "offset": ["10", "16", "8"],
    "count": ["190"]
   },
   "to": {
    "moves": [
     "await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190:p.y+8);"
    ]
   },
   "note": "moved (moves): ranaTrae"
  },
  {
   "line": 220,
   "numbers": {
    "place": ["0", "171"],
    "offset": ["2"]
   },
   "to": {
    "moves": [
     "const key=k+\"s\",e=EN[M[key]!=null?key:\"bandeja\"];await ranaA(e[0]+2,171);"
    ]
   },
   "note": "moved (moves): ranaTrae; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 221,
   "numbers": {
    "offset": ["14"],
    "place": ["190"]
   },
   "to": {
    "moves": [
     "const ranaAl=i=>ranaA(SILLA[i]-14,190);"
    ]
   },
   "note": "moved (moves): ranaAl; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 222,
   "numbers": {
    "count": ["0"]
   },
   "to": "unchanged",
   "note": "no place: count"
  },
  {
   "line": 223,
   "numbers": {
    "state": ["1", "1"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: state, other"
  },
  {
   "line": 228,
   "numbers": {
    "time": ["250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 236,
   "numbers": {
    "place": ["0", "1"],
    "offset": ["9"],
    "other": ["0", "9", "0", "20"],
    "count": ["6"],
    "time": ["200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 238,
   "numbers": {
    "state": ["1", "1", "0"],
    "place": ["142", "207"]
   },
   "to": {
    "moves": [
     "await mueve(\"abuela\",142,207)"
    ]
   },
   "note": "moved (moves): acts.abuelaa (centro); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 240,
   "numbers": {
    "other": ["24"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 241,
   "numbers": {
    "state": ["1", "6", "6", "1", "1", "1", "3", "9", "0", "1", "1", "0", "0", "0", "1", "0", "1"],
    "place": ["0", "1", "0", "1", "52", "200", "36", "173"]
   },
   "to": {
    "moves": [
     "async inicio24(){W.mantel=1;"
    ]
   },
   "note": "moved (moves): acts.inicio24 (la-mesa, h-mesa); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 242,
   "numbers": {
    "other": ["0", "1", "3"],
    "time": ["6", "6"]
   },
   "to": "unchanged",
   "note": "no place: other, time"
  },
  {
   "line": 244,
   "numbers": {
    "time": ["120", "250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 245,
   "numbers": {
    "time": ["120", "250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 247,
   "numbers": {
    "state": ["0"],
    "count": ["0"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: state, count, other"
  },
  {
   "line": 248,
   "numbers": {
    "offset": ["14", "24", "2", "1"],
    "scale": ["3"],
    "other": ["5"]
   },
   "to": {
    "moves": [
     "if(k===\"plato\"){await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,xDe(i,\"plato\"),FILA-2-(ps.plato.n-1)*3,5);ps.plato.con=\"bizcocho\";}"
    ]
   },
   "note": "moved (moves): sirve"
  },
  {
   "line": 249,
   "numbers": {
    "offset": ["2", "8"],
    "time": ["6", "250"],
    "other": ["0"]
   },
   "to": {
    "moves": [
     "W.vierte={x:xDe(i,\"taza\")-2,y:FILA-8+dyDe(i,\"taza\")};"
    ]
   },
   "note": "moved (moves): sirve"
  },
  {
   "line": 251,
   "numbers": {
    "state": ["0"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: state, other"
  },
  {
   "line": 252,
   "numbers": {
    "offset": ["14", "24", "1", "8", "1", "8", "0.6"],
    "place": ["5"],
    "time": ["5", "3"],
    "state": ["3", "3"],
    "other": ["1"]
   },
   "to": {
    "moves": [
     "await vuela({k:\"bizcocho\"},ab.x-14,ab.y-24,x-1,FILA-8,5);const v={k:\"bizcocho\",x:x-1,y:FILA-8};"
    ]
   },
   "note": "moved (moves): sirvemal; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 253,
   "numbers": {
    "offset": ["2", "6"],
    "other": ["8"],
    "time": ["4", "5", "3"]
   },
   "to": {
    "moves": [
     "W.vierte={x:x-2,y:FILA-6,h:8};"
    ]
   },
   "note": "moved (moves): sirvemal"
  },
  {
   "line": 254,
   "numbers": {
    "time": ["500"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "no place: time, other"
  },
  {
   "line": 257,
   "numbers": {
    "place": ["0", "2", "0", "1"],
    "time": ["120", "200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 259,
   "numbers": {
    "state": ["1", "1"],
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 260,
   "numbers": {
    "state": ["1"],
    "count": ["5"],
    "scale": ["5"]
   },
   "to": "unchanged",
   "note": "no place: state, count, scale"
  },
  {
   "line": 261,
   "numbers": {
    "other": ["0"],
    "state": ["0", "0", "1"],
    "offset": ["6"],
    "place": ["200"],
    "time": ["500"]
   },
   "to": {
    "moves": [
     "W.cosas.push({id:\"lio\",k:\"lio\",x:SILLA[im]-6,y:200});"
    ]
   },
   "note": "moved (moves): tira24; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 262,
   "numbers": {
    "offset": ["26"],
    "other": ["204"],
    "time": ["150", "300"],
    "place": ["4", "190"],
    "state": ["0", "0"]
   },
   "to": {
    "moves": [
     "await mueve(\"luis\",SILLA[sitio(\"mama\")]-26,204);"
    ]
   },
   "note": "moved (moves): recoge24; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 263,
   "numbers": {
    "state": ["1", "3", "3"],
    "place": ["6", "170"],
    "time": ["200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 265,
   "numbers": {
    "state": ["3", "3", "1", "0", "0"],
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 267,
   "numbers": {
    "count": ["2", "0"],
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: count, time"
  },
  {
   "line": 268,
   "numbers": {
    "state": ["0", "1"],
    "offset": ["40", "8", "15", "3"],
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: state, offset, time"
  },
  {
   "line": 269,
   "numbers": {
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 271,
   "numbers": {
    "other": ["25"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 273,
   "numbers": {
    "state": ["1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1"],
    "place": ["0", "1", "0", "1", "0", "150", "1", "150", "2", "150", "3", "150", "52", "200", "36", "173"],
    "other": ["0", "1", "2", "3"]
   },
   "to": {
    "moves": [
     "async inicio25(){W.mantel=1;",
     "abuelo:{x:SILLA[0],y:150,sent:1,dir:1},mama:{x:SILLA[1],y:150,sent:1,dir:1},papa:{x:SILLA[2],y:150,sent:1,dir:1},carmen:{x:SILLA[3],y:150,sent:1,dir:1}"
    ]
   },
   "note": "moved (moves): acts.inicio25 (la-cuchara); acts.inicio25; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 275,
   "numbers": {
    "time": ["120", "200"],
    "state": ["1"]
   },
   "to": "unchanged",
   "note": "no place: time, state"
  },
  {
   "line": 279,
   "numbers": {
    "time": ["120"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 280,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 281,
   "numbers": {
    "offset": ["8", "24", "4"],
    "other": ["6"]
   },
   "to": "unchanged",
   "note": "no place: offset, other"
  },
  {
   "line": 283,
   "numbers": {
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 286,
   "numbers": {
    "state": ["3", "0"],
    "time": ["250", "200"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 288,
   "numbers": {
    "offset": ["4", "8", "22", "4", "4"],
    "other": ["6", "6"]
   },
   "to": "unchanged",
   "note": "no place: offset, other"
  },
  {
   "line": 289,
   "numbers": {
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 292,
   "numbers": {
    "time": ["500"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 293,
   "numbers": {
    "time": ["800", "500"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 295,
   "numbers": {
    "time": ["150"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 299,
   "numbers": {
    "state": ["0", "0", "0"],
    "count": ["4"],
    "time": ["150"],
    "place": ["4", "196"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 300,
   "numbers": {
    "state": ["0", "1", "1"],
    "place": ["6", "196", "0", "0", "0", "1", "0", "1", "1"],
    "time": ["200"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 304,
   "numbers": {
    "state": ["0", "0", "1"],
    "count": ["4"],
    "time": ["120"]
   },
   "to": "unchanged",
   "note": "no place: state, count, time"
  },
  {
   "line": 305,
   "numbers": {
    "state": ["3"],
    "count": ["0"],
    "time": ["120"]
   },
   "to": "unchanged",
   "note": "no place: state, count, time"
  },
  {
   "line": 306,
   "numbers": {
    "offset": ["40", "8", "15", "3"],
    "state": ["1"],
    "time": ["200"]
   },
   "to": "unchanged",
   "note": "no place: offset, state, time"
  },
  {
   "line": 307,
   "numbers": {
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 309,
   "numbers": {
    "other": ["26"]
   },
   "to": "unchanged",
   "note": "no place: other"
  },
  {
   "line": 311,
   "numbers": {
    "state": ["0", "1", "1", "1", "1", "0", "0", "0", "0", "0", "1"],
    "place": ["0", "1", "70", "192", "54", "165"]
   },
   "to": {
    "moves": [
     "async inicio26(){W.mantel=0;"
    ]
   },
   "note": "moved (moves): acts.inicio26 (tengo-hambre); every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 312,
   "numbers": {
    "state": ["0", "1"],
    "time": ["400"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 314,
   "numbers": {
    "count": ["2", "0", "0"],
    "place": ["0", "182"],
    "offset": ["26", "1"],
    "state": ["1", "0", "2", "2"],
    "time": ["200", "500"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",EN.jarron[0]+26,182)"
    ]
   },
   "note": "moved (moves): llena26, abuelada, ofrece26, abuelalleva, reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 316,
   "numbers": {
    "time": ["250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 318,
   "numbers": {
    "place": ["0", "182"],
    "offset": ["26", "54", "10", "23", "5", "3"],
    "state": ["1", "1"],
    "time": ["150", "250"],
    "order": ["0"],
    "count": ["16"],
    "other": ["29"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",EN.jarron[0]+26,182)"
    ]
   },
   "note": "moved (moves): llena26, abuelada, ofrece26, abuelalleva, reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 320,
   "numbers": {
    "other": ["1"],
    "time": ["1100", "200"]
   },
   "to": "unchanged",
   "note": "no place: other, time"
  },
  {
   "line": 323,
   "numbers": {
    "place": ["0", "182"],
    "offset": ["26"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",EN.jarron[0]+26,182)"
    ]
   },
   "note": "moved (moves): llena26, abuelada, ofrece26, abuelalleva, reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 326,
   "numbers": {
    "offset": ["30", "10", "4"],
    "time": ["120"],
    "place": ["0", "173"]
   },
   "to": {
    "moves": [
     "await ranaA(EN[key][0]+4,173);"
    ]
   },
   "note": "moved (moves): acts.lleva26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 327,
   "numbers": {
    "time": ["120", "250"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 328,
   "numbers": {
    "place": ["0", "182"],
    "offset": ["26"],
    "state": ["1"],
    "time": ["120", "200"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",EN.jarron[0]+26,182)"
    ]
   },
   "note": "moved (moves): llena26, abuelada, ofrece26, abuelalleva, reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 330,
   "numbers": {
    "time": ["600"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 331,
   "numbers": {
    "time": ["300"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 334,
   "numbers": {
    "time": ["500"],
    "offset": ["18", "2"],
    "other": ["1"]
   },
   "to": "unchanged",
   "note": "no place: time, offset, other"
  },
  {
   "line": 335,
   "numbers": {
    "place": ["1", "1", "1", "1"],
    "time": ["180", "500"],
    "other": ["1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 336,
   "numbers": {
    "offset": ["16", "2"],
    "place": ["194"],
    "state": ["1", "5", "1", "0"],
    "time": ["300"],
    "count": ["4"],
    "other": ["202"],
    "scale": ["4"]
   },
   "to": {
    "moves": [
     "await perroA(SILLA[i]+16,194);",
     "c=Object.assign({x:SILLA[i]-2,y:FRENTE},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+(202-FRENTE)*s/4;"
    ]
   },
   "note": "moved (moves): canelo; canelo; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 338,
   "numbers": {
    "place": ["0", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 339,
   "numbers": {
    "state": ["1"],
    "place": ["0"],
    "offset": ["24"],
    "scale": ["17"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 340,
   "numbers": {
    "place": ["1"],
    "offset": ["6"],
    "time": ["900"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 341,
   "numbers": {
    "offset": ["3", "9", "2", "5"],
    "place": ["1", "1"],
    "order": ["0"],
    "time": ["900"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 342,
   "numbers": {
    "state": ["1", "0"],
    "time": ["400"]
   },
   "to": "unchanged",
   "note": "no place: state, time"
  },
  {
   "line": 343,
   "numbers": {
    "time": ["4"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 345,
   "numbers": {
    "place": ["4", "200", "0", "198"],
    "state": ["1", "1"],
    "offset": ["52"],
    "time": ["300", "600"]
   },
   "to": {
    "moves": [
     "await perroA(EN.comidas[0]+52,198);"
    ]
   },
   "note": "moved (moves): acts.canelo26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 346,
   "numbers": {
    "place": ["0", "1"],
    "state": ["1"],
    "time": ["300"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 348,
   "numbers": {
    "place": ["0", "182"],
    "offset": ["26"],
    "state": ["1"]
   },
   "to": {
    "moves": [
     "mueve(\"abuela\",EN.jarron[0]+26,182)"
    ]
   },
   "note": "moved (moves): llena26, abuelada, ofrece26, abuelalleva, reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 350,
   "numbers": {
    "count": ["16"],
    "other": ["29", "6", "1"],
    "offset": ["3", "23", "5"],
    "place": ["0", "1"],
    "order": ["0"],
    "time": ["120"]
   },
   "to": {
    "moves": [
     "y1=id===\"coqui\"?pies()+3:FILA;"
    ]
   },
   "note": "moved (moves): reparte26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 352,
   "numbers": {
    "time": ["700"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 353,
   "numbers": {
    "place": ["0", "1", "0", "1"],
    "offset": ["34", "8", "14", "6"],
    "state": ["1", "1", "1"],
    "time": ["200"]
   },
   "to": {
    "moves": [
     "await mueve(\"abuela\",CAN[0]-34,CAN[1]-8);"
    ]
   },
   "note": "moved (moves): acts.final26; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 354,
   "numbers": {
    "time": ["900"]
   },
   "to": "unchanged",
   "note": "no place: time"
  },
  {
   "line": 357,
   "numbers": {
    "count": ["1"]
   },
   "to": "unchanged",
   "note": "no place: count"
  },
  {
   "line": 358,
   "numbers": {
    "place": ["0", "1", "0", "1", "0", "150", "1", "150", "2", "150", "3", "150"],
    "state": ["1", "1", "1", "1", "1", "1", "1", "1", "1", "1"],
    "count": ["1", "1", "3", "2", "2", "3", "2", "1", "1", "2", "2", "3"],
    "other": ["0", "0", "1", "2", "3"]
   },
   "to": {
    "moves": [
     "abuelo:{x:SILLA[0],y:150,dir:1,sent:1",
     "papa:{x:SILLA[1],y:150,dir:1,sent:1",
     "mama:{x:SILLA[2],y:150,dir:1,sent:1",
     "carmen:{x:SILLA[3],y:150,dir:1,sent:1"
    ]
   },
   "note": "moved (moves): acts.prueba (a test of the drawing, no story); acts.prueba; acts.prueba; acts.prueba; every other place here keeps its screen place (the floor rule)"
  },
  {
   "line": 359,
   "numbers": {
    "count": ["3", "2", "1", "3", "2", "2", "1", "2", "1", "3"],
    "state": ["4", "4", "2", "1", "5", "4", "2", "1", "1", "1"],
    "other": ["1", "0", "0"],
    "place": ["0", "1"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 361,
   "numbers": {
    "count": ["1"],
    "state": ["1", "1", "2", "1", "1", "1", "1", "1"]
   },
   "to": "unchanged",
   "note": "no place: count, state"
  },
  {
   "line": 362,
   "numbers": {
    "count": ["2"],
    "state": ["1", "1", "1", "1"]
   },
   "to": "unchanged",
   "note": "no place: count, state"
  },
  {
   "line": 363,
   "numbers": {
    "state": ["1", "1"]
   },
   "to": "unchanged",
   "note": "no place: state"
  },
  {
   "line": 364,
   "numbers": {
    "count": ["3", "1"],
    "place": ["0", "1", "0", "1", "0", "1", "146", "200"],
    "offset": ["24", "3", "42", "5", "41", "2"],
    "order": ["0"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 365,
   "numbers": {
    "count": ["2"],
    "place": ["110", "196", "140", "204", "166", "192"],
    "other": ["1", "2.2", "0.6"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 366,
   "numbers": {
    "place": ["104", "163", "0", "1"],
    "state": ["1", "1"],
    "count": ["1", "2", "3", "2"],
    "offset": ["6"]
   },
   "to": {
    "floor": true
   },
   "note": "places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)"
  },
  {
   "line": 368,
   "numbers": {
    "other": ["200"]
   },
   "to": "unchanged",
   "note": "stake, poke and estado: no place"
  },
  {
   "line": 370,
   "numbers": {
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "stake, poke and estado: no place"
  },
  {
   "line": 373,
   "numbers": {
    "place": ["22", "0", "196", "216", "124", "22"]
   },
   "to": {
    "view": "wide",
    "point": "corazon"
   },
   "note": "the view (views.wide) and the heart (points.corazon): unchanged"
  },
  {
   "line": 374,
   "numbers": {
    "place": ["125", "28", "0", "1", "2", "3", "120", "188", "104", "161"],
    "state": ["0", "3", "9", "0", "1", "0", "1", "1"],
    "other": ["0"]
   },
   "to": "unchanged",
   "note": "respEn (where the answer cards stand), the frog's home and first place: unchanged"
  },
  {
   "line": "juego.js:16",
   "to": "unchanged",
   "note": "fresh(): not used here: mesa's fresh() puts the frog at (104, 161)"
  },
  {
   "line": "cual.js:21",
   "to": "unchanged",
   "note": "panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 19 things (old 19), 2 frog places of LUGAR (old 2), 1 view (old 1), 29 positions (old 29) (h-mesa's among them), 12 review pairs of cual-mesa (24 pictures), 16 level pictures (old 16), 3 baked states for the old 144",
   "code: every one of the 377 lines of mesa.js read here; 242 hold numbers, each with an entry (101 other, 320 place, 204 offset, 364 dropped, 916 drawing, 132 count, 178 state, 5 order, 26 scale, 78 time); every one of order 06's 288 places named by its line's entry; 43 moves, each line holding its source",
   "walks: every walk of the frog (every call of hopTo, acts included) in the 12 runs, the old page against the port's play, walk by walk: 181 walks, each with the old hop count (0 differ)",
   "runs: the 12 runs (h-mesa, la-cuchara, la-mesa, tengo-hambre, three plans each) are played by juega.mjs on the old page, each trace byte for byte its recorded run in coqui/ref/trazas/ (12 of 12)",
   "hops: all 36 pairs of the frog's places keep the old count; his walks between them in the runs: frog.centro-frog.hm, frog.centro-frog.th, frog.hm-frog.ranaa, frog.hm-rana.0, frog.hm-rana.1, frog.hm-rana.2, frog.hm-rana.3, frog.ranaa-rana.3, frog.th-rana.0, frog.th-rana.1, frog.th-rana.2, rana.0-rana.1, rana.1-rana.2, rana.1-rana.3",
   "boxes: every pixel of each set thing inside its touch box in every baked state: mesa [64,102,124,91], estufa [195,61,37,87]; every pixel answers its own thing in the hit order; every part of the set is a touch key's (nothing decorative): the room's pieces (the counters, the wall cupboard, the door, the window, the walls) are la cocina's, the whole room; where the table's or the stove's box (a rectangle) reaches over them a touch answers the table or the stove, as the old boxes did over the old background (45 px of ventana under estufa, 448 px of mostrador under mesa, 20 px of puerta.umbral under mesa, 542 px of mostrador2 under estufa)",
   "shadows of the set: every castShadow call has strength 1 and a radius; each casting part darkens pixels, its shadow within 4 px of it (a contact shadow at the foot of each thin leg): mesa.patas 4 calls, 36 px darkened; sillas.patas 8 calls, 7 px darkened",
   "light: the kitchen's one rule (cocina-kit: shadows to screen right, low, joined); on the lit side (left) of every leg, chair, counter and the stove, 231 floor px within 3 px checked: none differs from the floor without the thing (no ring, no fringe; cocinaOcclusion dims the shadow side only)",
   "thin things (WCAG contrast against what is behind them, 2 kept; one light, so every light): legs against the floor 2.31 at the least (217 px), knob on the stove 4.55, oven handle 3.05, burner on the hob 2.63, cupboard handle (front, lit) 3.12, cupboard handle (front, shade) 2.83, window bar against the sky 3.36, steam against the panel behind the stove 9.63, chair rail against the wall 7.19",
   "window: through it 59 px of sky and 67 px of the patio's bush, seen on a backdrop 1.92 behind the wall's face (it shifts as a view does, not as a picture on the wall); its frame and bars (634 px) stand 0.06 out of the wall, a sill under it",
   "door (round 2): in the wide view its leaf 1615 px (open into the room against the wall towards the corner, its brass handle 7 px), the wall's thickness in the opening 234 px, the threshold 48 px (30 kept each); through it the patio's ground at the floor's level, El patio's stone step then the lawn, out to the yard's wall and hedge: the lowest outside pixel of each of the opening's 13 columns is ground (13); whoever comes in appears on the step (PUERTA), seen in the opening (the wall, its frame, its thickness and the threshold drawn over what of them is behind: front), and steps in onto the walkway's end",
   "specks (round 2): in every baked state, every group of floor pixels of one colour (4-connected) of fewer than 6 px has a pixel of its own colour next to it, on the floor or of the set (no lone speck: mesa-set.html noSpecks): m0h0 0, m1h0 0, m0h1 0, m1h1 0",
   "edges: every set thing whole inside the view by 3 px or running off it by 12 (px to each edge, negative off the view): the table and chairs left 42 right 30 top 102 bottom 39; the stove, hood and panel left 173 right -14 top 61 bottom 68; the left counter left -22 right 130 top 83 bottom 54; the right counter left 193 right -22 top 111 bottom 58; the wall cupboard left 3 right 146 top 48 bottom 129; the door left 52 right 120 top 36 bottom 115; the window left 146 right 20 top 44 bottom 132",
   "drawn: at 21890 moments (every tick inside the acts of the port's play of the 12 runs, every step's end, every pair picture) the sorted list composed as it is drawn (each item owns what it drew last; a front part drawn again only over an owner behind it): no part of the set over any face; at 65328 sitter-moments the table over no part of a sitter the old table did not cover (0 px more at the worst); nothing on the table's top under any part of the set",
   "rests: 52161 moments of someone standing still on the floor, each on clear floor (nothing of the set under or within .08 of the foot); 65327 of someone sitting, the seat under the lap; every stack on the counter and every thing on the stove on its top",
   "seen: at 7663 person-, dog- and frog-moments (every step's end of the 12 runs) each seen no less than in the old picture of that moment less 10%, and their face no less (0 less; 18 person-moments where the port's play has them elsewhere than the rule puts the old moment's place, mid-walk, are not compared); whoever was wholly inside the old view is wholly inside it with 3 px to spare",
   "bubbles: 0 distinct bubbles at every moment: wholly inside the view (99 px from its edge at the least), clear of the rounds card, on no face (talk)",
   "asks: 41 distinct asks (for abuelo, bebe, carmen, comidas, cuchara, di_cuchara, di_cuchillo, di_hambre, di_plato, di_sed, di_taza, di_tenedor, luis, mama, papa, platos, tazas, tenedor, vasos): every hint frame (box +- 12) inside the view with 2 px to spare (3 at the least), no frame's rings across a face where the old frame's were not (as the old: h-mesa beats.8 (platos): its frame past the view as the old; h-mesa beats.8 (platos) abuela's face; h-mesa beats.11 (platos): its frame past the view as the old; h-mesa beats.11 (platos) abuela's face; h-mesa beats.13 (platos): its frame past the view as the old; h-mesa beats.13 (platos) abuela's face; h-mesa beats.17 (bebe) mama's face; h-mesa beats.19 (papa) abuelo's face; la-cuchara beats.72 (abuelo) mama's face; la-mesa beats.23 (platos): its frame past the view as the old; la-mesa beats.33 (papa) abuelo's face; la-mesa beats.78 (papa) abuelo's face; la-mesa beats.78 (papa) carmen's face; tengo-hambre beats.16 (comidas): its frame past the view as the old; tengo-hambre beats.32 (carmen) luis's face; tengo-hambre beats.70 (papa) mama's face), the hint hand on no face and not cut by the view's edge where the old was not (but as the old: h-mesa beats.8 (platos): on abuela's face; h-mesa beats.9 (tazas): on luis's face; h-mesa beats.9 (tazas): on abuela's face; h-mesa beats.11 (platos): on abuela's face; h-mesa beats.12 (tazas): on luis's face; h-mesa beats.12 (tazas): on abuela's face; h-mesa beats.13 (platos): on abuela's face; la-cuchara beats.34 (luis): on the frog's face; la-mesa beats.33 (papa): on abuela's face; la-mesa beats.40 (tazas): on luis's face; la-mesa beats.66 (tazas): on luis's face; la-mesa beats.66 (tazas): on the frog's face; la-mesa beats.78 (papa): on abuela's face); nothing of the set over the thing asked for (but where Luis holds a thing up at the counter, LUIS: it reaches over the table's near left corner, under its top's edge by the depth test: la-cuchara beats.34 (luis) luis; a row or two nearer, his hint frame would cross the frog's face at his home by the counter); 40 answer cards, each with its lit frame and glow 4 px and more inside the view (4 at the least), 2 px clear of everyone's head and body, over no thing, and of the rounds card but where the old card met it too (la-cuchara beats.81 (di_tenedor) di_cuchara; la-mesa beats.85 (di_taza) di_plato; tengo-hambre beats.48 (di_sed) di_hambre: there the rounds card covers the top rows of the first card, as the old touched it; lower, the hint hand under the cards would fall on the sitters' faces); at each of the 40 cards the hint drawn round it: its frame 2 px inside the view, across no head, its hand on no face; 38 times someone or something a learner must find or tell apart: whole in the view, apart where the old had them apart (plain surface round them under 80%: abuelo 79%, luis 50%, abuelo 70%)",
   "heads: at 54137 face-moments (everyone at rest) no face has the window, the door's frame, the wall cupboard or the hood behind it; the door's open leaf (round 2: a plain wooden panel, its lower edge at the face's top rows) behind the face of whoever sits at the first seat: abuelo h-mesa, abuelo la-cuchara, abuelo la-mesa, abuelo tengo-hambre",
   "preview: at every step's end of the 12 recorded runs (8511 places of the people, the frog, the dog and the things) mesa-preview.html puts everyone exactly where the sheet's rule does (0 differ); and the rule puts each of the 8075 places at rest where the port's play has them (0 differ)",
   "pairs: 24 review pictures (and the 16 level pictures, the same pictures), 22 at zoom 2, at zoom 1: cocina.si (zoom 2 cannot hold it: the pot with its steam (25 rows) and abuela's whole head by the stove need 55 rows of a 52-row window; and its other picture, cocina.no, is El colmado's stall at zoom 1) (cocina.no is El colmado's stall); in each, everyone who is in it has their whole head inside with 2 px to spare (17 heads; a person may be cut by the window's edges, as the old close pictures), every other sprite whole with 1 px to spare (2 at zoom 1) or out of it, the thing the pair is about whole with 1 px to spare, a plain surface round half its outline at least (mesa.si 59%, mesa.no 63%, plato.si 82%, plato.no 83%, taza.si 82%, taza.no 80%, cuchara.si 85%, cuchara.no 78%, tenedor.si 78%, tenedor.no 83%, cuchillo.si 61%, cuchillo.no 72%, comida.si 80%, comida.no 79%, cocina.si 63%, pone.si 56%, pone.no 53%, tengo_hambre.si 75%, tengo_hambre.no 75%, tengo_sed.si 13%, tengo_sed.no 18%, listo.si 77%, listo.no 77%; under half, as written in the picture: tengo_sed.si 13% (the glass is at her mouth: round it her face and hair, which are hers (left out), and the chair's back behind her, as the old); tengo_sed.no 18% (the fork is at her mouth: round it her face, which is hers (left out), and the chair's back behind her, as the old)); the two pictures of each pair differ in 1.5% of their pixels at least (mesa 94.0%, plato 5.6%, taza 21.4%, cuchara 5.8%, tenedor 8.3%, cuchillo 6.6%, comida 1.6%, pone 2.9%, tengo_hambre 2.7%, tengo_sed 4.0%, listo 29.4%); no zoom 2 picture shows a shadow without its caster; what differs: mesa: cosas, estufa, mantel, the window; plato: gente; taza: gente; cuchara: gente; tenedor: gente; cuchillo: gente; comida: puestos; cocina: gente, estufa, afuera, the window; pone: cosas; tengo_hambre: gente; tengo_sed: gente, puestos; listo: cosas, estufa, mantel",
   "states: 3 baked states reached (m0h0, m1h0, m0h1; every moment, pair and level picture), of the 4 the set can bake"
  ]
 }
}
''';
