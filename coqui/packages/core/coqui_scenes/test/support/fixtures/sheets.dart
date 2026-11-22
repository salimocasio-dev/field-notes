// Made by tool/make_sheets.dart from docs/proyecto/pixel/<id>-sheet.json. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// The sheets of the converted scenes, by id: the text of each file, for the tests that run in a browser.
const Map<String, String> sheetTexts = {
  'frente': r'''{
 "scene": "frente",
 "made": "node docs/proyecto/pixel/frente-sheet-make.js, from frente-set.html (window.FRENTE) and coqui/ref/escenas/frente/. Order 07.",
 "S": 26,
 "origin": {
  "originX": -2,
  "originY": 12
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "frog": "a spot is the ground under his feet: q.x = round(sx) - 16, q.y = round(sy) - 25; q.s = the spot's scale",
  "abuela": "a spot is the ground under her feet: her sprite is drawn at (round(sx) - 30, round(sy) - 49)",
  "bird": "a point is under its feet: drawAve draws its bottom at y + 2",
  "frame": "a point named with a frame is the old point plus the frame's offset (a whole number of pixels); points drawn relative to it (a rect, a sprite) move by the same offset",
  "sky": "the sky is screen space: what lives in it (clouds, rain, the sun, the bird circling, the stars of marcador) keeps its old screen numbers",
  "view": "a view has a zoom. zoom 1: the 196 x 216 window with x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. zoom 2: the 98 x 108 region [clamp(round(sx - 49), 0, 142), clamp(round(sy - 54), 0, 108)] shown nearest-neighbour at two screen pixels per picture pixel (region is given). Never a fraction",
  "viewChange": "between two views of the same zoom the window slides (camGo, whole pixels); between a zoom 1 and a zoom 2 view it cuts: no in-between sizes",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window [clamp(round(sx - 98), 0, 44), clamp(round(sy - 52), 0, 112)]; zoom 2 = the 98 x 52 region [clamp(round(sx - 49), 0, 142), clamp(round(sy - 26), 0, 164)] shown nearest-neighbour at 2 x 2 in the 196 x 104 picture. crop is given. remap's cam and crop entries say what each old rectangle meant; for the pictures themselves pictures wins"
 },
 "setKey": {
  "params": {
   "door": {
    "values": ["shut", "half", "open"],
    "fromW": "W.door: 0 shut, .5 half, 1 open"
   },
   "win": {
    "values": ["shut", "open"],
    "fromW": "W.win: 0 shut, 1 open"
   },
   "lights": {
    "values": ["0", "1"],
    "fromW": "W.lamp (the lights inside; the old file calls it lamp, there is no porch lamp)"
   },
   "sky": {
    "values": ["day", "storm", "storm2", "rain", "dusk", "sunset"],
    "fromW": "W.dusk 2: sunset; W.dusk 1: dusk; else W.dark >= .33 or W.rain: rain; W.dark >= .27: storm2; W.storm or W.dark > 0: storm; else day"
   },
   "hide": {
    "values": ["0", "1"],
    "fromW": "W.escondite ? 1 : 0 (story 3: the small palm and the birdhouse stand in the garden)"
   },
   "rustle": {
    "values": ["none", "palma", "casa", "todo"],
    "fromW": "W.escondite && W.rustle ? W.rustle : none"
   },
   "side": {
    "values": ["-1", "1"],
    "fromW": "only when rustle is not none: (F >> 1) % 2 ? 1 : -1 (escondite()'s sh(), frente.js:94); the rustling prop sits one pixel left or right"
   }
  },
  "key": "door + win + lights + sky + hide + rustle (+ side), e.g. \"shut-shut-0-day-0-none\"",
  "baked": [
   {
    "ref": "coqui/ref/pp/frente/door-half-win-shut-lights-0-sky-day",
    "query": "?door=half&win=shut&lights=0&sky=day&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-half-win-shut-lights-0-sky-dusk-hide",
    "query": "?door=half&win=shut&lights=0&sky=dusk&hide=1&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-half-win-shut-lights-0-sky-sunset",
    "query": "?door=half&win=shut&lights=0&sky=sunset&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-open-win-open-lights-0-sky-day",
    "query": "?door=open&win=open&lights=0&sky=day&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-open-win-shut-lights-0-sky-day",
    "query": "?door=open&win=shut&lights=0&sky=day&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-open-win-shut-lights-0-sky-dusk-hide",
    "query": "?door=open&win=shut&lights=0&sky=dusk&hide=1&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-open-win-shut-lights-1-sky-storm",
    "query": "?door=open&win=shut&lights=1&sky=storm&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-open-lights-0-sky-day",
    "query": "?door=shut&win=open&lights=0&sky=day&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-open-lights-1-sky-rain",
    "query": "?door=shut&win=open&lights=1&sky=rain&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-open-lights-1-sky-storm",
    "query": "?door=shut&win=open&lights=1&sky=storm&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-open-lights-1-sky-storm2",
    "query": "?door=shut&win=open&lights=1&sky=storm2&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-day",
    "query": "?door=shut&win=shut&lights=0&sky=day&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-day-hide",
    "query": "?door=shut&win=shut&lights=0&sky=day&hide=1&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-storm",
    "query": "?door=shut&win=shut&lights=0&sky=storm&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-sunset-hide",
    "query": "?door=shut&win=shut&lights=0&sky=sunset&hide=1&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-1-sky-rain",
    "query": "?door=shut&win=shut&lights=1&sky=rain&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-1-sky-storm",
    "query": "?door=shut&win=shut&lights=1&sky=storm&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-1-sky-storm2",
    "query": "?door=shut&win=shut&lights=1&sky=storm2&hide=0&rustle=none&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-palma-side--1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=palma&side=-1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-palma-side-1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=palma&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-casa-side--1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=casa&side=-1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-casa-side-1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=casa&side=1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-todo-side--1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=todo&side=-1"
   },
   {
    "ref": "coqui/ref/pp/frente/door-shut-win-shut-lights-0-sky-dusk-hide-rustle-todo-side-1",
    "query": "?door=shut&win=shut&lights=0&sky=dusk&hide=1&rustle=todo&side=1"
   }
  ],
  "bakedWhy": "every state the stories, pairs and level pictures reach (coqui/ref/escenas/frente and a replay of the five stories), plus the rustle palma states a story can reach; each is a reference in coqui/ref/pp/frente/",
  "notRead": "W.abierto (escondite() reads it into a constant it never uses), W.mesa and W.caliente (the cake inside the window: sprite layer), W.nube, W.nube2, W.nube3, W.rain (moving: sprite layer; W.rain only picks the sky)",
  "old": "the old background sprite key was \"fr\" + door + \"_\" + win + \"_\" + lamp; the old W.storm / W.dark / W.dusk overlays (frente.js:163-165) are now the sky parameter"
 },
 "things": {
  "abuela": {
   "sprite": true,
   "why": "a character (today's sprite, drawn 1:1)",
   "box": {
    "puerta": {
     "frame": "abuela.puerta",
     "old": [151, 56, 29, 49],
     "new": [129, 83, 29, 49]
    },
    "paso": {
     "frame": "abuela.paso",
     "old": [110, 58, 36, 50],
     "new": [101, 74, 36, 50]
    },
    "ventana": {
     "clip": "ventana.hueco",
     "old": [97, 61, 30, 20],
     "what": "the window opening: clips[ventana.hueco].box"
    }
   }
  },
  "palma_pequena": {
   "set": true,
   "world": [5.1034, 1.9734, 0, 6.4088, 3.2788, 1.3246],
   "box": [151, 155, 49, 55],
   "hit": {
    "world": [5.1034, 1.9734, 0, 6.4088, 3.2788, 1.3246],
    "box": [151, 155, 49, 55]
   },
   "what": "the small palm (story 3: shown when hide=1)",
   "old": {
    "box": [174, 114, 42, 56],
    "hit": [172, 112, 46, 60]
   }
  },
  "casa_pequena": {
   "set": true,
   "world": [2.3021, 4.9393, 0, 3.1452, 5.7824, 1.6781],
   "box": [54, 148, 32, 55],
   "hit": {
    "world": [2.2221, 4.9393, 0, 3.2252, 5.8624, 1.6781],
    "box": [51, 148, 36, 56]
   },
   "what": "the birdhouse on its post (story 3: shown when hide=1)",
   "old": {
    "box": [60, 110, 26, 58],
    "hit": [58, 108, 30, 62]
   }
  },
  "palma_grande": {
   "set": true,
   "world": [-2.5234, 1.8206, 0, -0.9732, 3.3708, 2.6651],
   "box": [9, 53, 58, 90],
   "hit": {
    "world": [-2.5234, 1.8206, 0, -0.9732, 3.3708, 2.6651],
    "box": [9, 53, 58, 90]
   },
   "what": "the big palm, as a hiding place (story 3). The same world box as palma",
   "old": {
    "box": [34, 34, 48, 72],
    "hit": [34, 34, 48, 74]
   }
  },
  "casa_grande": {
   "set": true,
   "world": [-2.52, -1.62, 0, 2.82, 0.22, 2.9],
   "box": [67, 16, 133, 132],
   "hit": {
    "world": [-2.52, -1.62, 0, 2.82, 0.22, 3.7],
    "box": [67, -2, 133, 150]
   },
   "what": "the house, as a hiding place (story 3). The same world box as casa",
   "old": {
    "box": [60, 17, 166, 90],
    "hit": [57, 16, 171, 95]
   }
  },
  "pajaro": {
   "sprite": true,
   "why": "it flies: the bird is today's sprite; its box stays relative to it (hit: |x - p[0]| < 16, p[1] - 24 < y < p[1] + 5)"
  },
  "bizcocho": {
   "hud": true,
   "why": "the plate in the corner of the display (hud), not in the picture. Its hit (frente.js:190) turns a picture point into display pixels with the old zoom (DW / cam[2]); with no zoom that is x - cam[0], y - cam[1]"
  },
  "coqui": {
   "sprite": true,
   "why": "a character (frogBox around today's sprite)"
  },
  "nube": {
   "sprite": true,
   "sky": true,
   "why": "the storm cloud moves (W.nube.x eases to its tx): today's sprite, in the sky, at the same screen places as before (box [x, 0, 98, 22], hit [x - 2, 0, 102, 24])"
  },
  "puerta": {
   "set": true,
   "world": [0.61, -0.06, 0, 2.34, 0.06, 2.85],
   "box": [128, 60, 35, 83],
   "hit": {
    "world": [0.61, -0.06, 0, 2.34, 0.06, 2.97],
    "box": [128, 58, 35, 85]
   },
   "what": "the door with its frame; hit adds a little slack",
   "old": {
    "box": [151, 51, 30, 54],
    "hit": [145, 46, 42, 62]
   }
  },
  "ventana": {
   "set": true,
   "world": [-1.83, 0, 1.03, 0.11, 0.06, 2.52],
   "box": [83, 46, 38, 53],
   "hit": {
    "world": [-2.29, 0, 0.7, 0.57, 0.42, 2.62],
    "box": [68, 39, 61, 75]
   },
   "what": "the window with its frame, its shutters (open, flat on the wall) and the flower box; hit adds a little slack. The hint frame goes round the window and its frame only",
   "old": {
    "box": [93, 57, 38, 28],
    "hit": [82, 53, 61, 42]
   }
  },
  "casa": {
   "set": true,
   "world": [-2.52, -1.62, 0, 2.82, 0.22, 2.9],
   "box": [67, 16, 133, 132],
   "hit": {
    "world": [-2.52, -1.62, 0, 2.82, 0.22, 3.7],
    "box": [67, -2, 133, 150]
   },
   "what": "the house: walls and roof. Its hit replaces both old tests (the roof trapezoid, frente.js:195, and the wall rectangle, frente.js:196)",
   "old": {
    "box": [60, 17, 166, 90],
    "hit": "roof: 16 <= y < 42, 88 - 30t <= x <= 196 + 30t (t = (y - 16) / 25); walls [57, 41, 171, 70]"
   }
  },
  "sol": {
   "set": true,
   "sky": true,
   "screen": {
    "circle": [215, 17, 12],
    "box": [203, 5, 25, 25]
   },
   "old": {
    "circle": [210, 17, 12]
   },
   "why": "the sun is baked into the sky (pale in a storm, none in the rain); the sky is screen space. It sits 5 px right of the old sun, so its touch circle stays clear of the house's box: hit (x-215)^2 + (y-17)^2 < 144"
  },
  "palma": {
   "set": true,
   "world": [-2.5234, 1.8206, 0, -0.9732, 3.3708, 2.6651],
   "box": [9, 53, 58, 90],
   "hit": {
    "world": [-2.5234, 1.8206, 0, -0.9732, 3.3708, 2.6651],
    "box": [9, 53, 58, 90]
   },
   "what": "the big palm (stories 1 and 2: a free touch)",
   "old": {
    "box": [34, 36, 30, 70],
    "hit": [34, 36, 30, 70]
   }
  }
 },
 "spots": {
  "inicio": {
   "world": [3.9852, 3.9102, 0],
   "screen": [119.38, 192.58],
   "scale": 1,
   "frog": [103, 168],
   "old": [150, 178],
   "what": "where every story starts: on the path, near the bottom (juego.js:16 fresh(), cq x 150 y 178 s 1)"
  },
  "patio": {
   "world": [2.7478, 2.6728, 0],
   "screen": [119.38, 169.83],
   "scale": 0.86,
   "frog": [103, 145],
   "old": [123, 150],
   "what": "LUGAR.patio: on the path in front of the house (also cual.js:21, the frog of every pair picture)"
  },
  "puerta": {
   "world": [1.275, 0.62, 0.16],
   "screen": [130.04, 133.82],
   "scale": 0.72,
   "frog": [114, 109],
   "old": [150, 104],
   "what": "LUGAR.puerta and LUGAR.casa_grande: on the porch, before the door"
  },
  "ventana": {
   "world": [-0.27, 1.47, 0],
   "screen": [86.01, 131.03],
   "scale": 0.72,
   "frog": [70, 106],
   "old": [96, 104],
   "what": "LUGAR.ventana: under the window, on the lawn just before the porch, as the old frog stood (on the porch his bubble covered abuela in the window and the window's hint frame crossed his eyes). Placed so that every hop count acts.ir gives (round(d / 28)) from the places the stories hop from is the old one"
  },
  "palma_grande": {
   "world": [-0.78, 3.46, 0],
   "screen": [40.05, 144.64],
   "scale": 0.74,
   "frog": [24, 120],
   "old": [38, 100],
   "what": "LUGAR.palma_grande: at the foot of the big palm"
  },
  "palma_pequena": {
   "world": [5.6, 3.82, 0],
   "screen": [150.72, 206.59],
   "scale": 0.88,
   "frog": [135, 182],
   "old": [150, 150],
   "what": "LUGAR.palma_pequena: beside the small palm"
  },
  "casa_pequena": {
   "world": [3.55, 5.51, 0],
   "screen": [81.97, 203.28],
   "scale": 0.86,
   "frog": [66, 178],
   "old": [86, 150],
   "what": "LUGAR.casa_pequena: beside the birdhouse"
  },
  "puerta.dentro": {
   "world": [1.475, -0.25, 0.16],
   "screen": [149.71, 127.66],
   "scale": 0.72,
   "frog": [134, 103],
   "old": [150, 80],
   "what": "entra por la puerta: hopTo(150,80,2,.72), just inside the doorway"
  },
  "puerta.escondido": {
   "world": [1.375, -0.45, 0.16],
   "screen": [151.55, 124.9],
   "scale": 0.6,
   "frog": [136, 100],
   "old": [150, 82],
   "what": "esconde casa_grande: hopTo(150,82,1,.6), behind the door"
  },
  "ventana.dentro": {
   "world": [-0.86, -0.05, 1.15],
   "screen": [103.11, 85.74],
   "scale": 0.46,
   "frog": [87, 61],
   "old": [98, 58],
   "what": "entra por la ventana: the jump ends on the sill (q.x 98, q.y 58, s .46)"
  },
  "casa_pequena.dentro": {
   "world": [3.05, 5.91, 1.25],
   "screen": [65.42, 174.22],
   "scale": 0.5,
   "frog": [49, 149],
   "old": [58, 104],
   "what": "esconde casa_pequena: the frog goes half way to (58,104) four times, into the birdhouse"
  },
  "hola": {
   "world": [1.125, 0.78, 0.16],
   "screen": [124.34, 133.91],
   "scale": 0.62,
   "frog": [108, 109],
   "old": [146, 86],
   "what": "pairs hola.si / adiós.no: the frog at the door, waving (cq x 146 y 86 s .62)"
  },
  "adios": {
   "world": [3.1882, 1.3132, 0],
   "screen": [152.47, 161.38],
   "scale": 0.85,
   "frog": [136, 136],
   "old": [176, 116],
   "what": "pairs hola.no / adiós.si: the frog going away from the door (cq x 176 y 116 s .85)"
  },
  "abuela.puerta": {
   "world": [1.475, 0.1, 0.16],
   "screen": [143.28, 130.88],
   "abuela": [113, 82],
   "old": [135, 55],
   "what": "ABAT.puerta: in the doorway (and where she peeks from, behind the half-open door)"
  },
  "abuela.paso": {
   "world": [0.25, 0.4, 0.16],
   "screen": [115.24, 122.37],
   "abuela": [85, 73],
   "old": [94, 57],
   "what": "ABAT.paso: on the porch, left of the door (story 3, with her plate)"
  }
 },
 "lugar": {
  "puerta": {
   "spot": "puerta",
   "frog": [114, 109],
   "scale": 0.72
  },
  "ventana": {
   "spot": "ventana",
   "frog": [70, 106],
   "scale": 0.72
  },
  "patio": {
   "spot": "patio",
   "frog": [103, 145],
   "scale": 0.86
  },
  "casa_grande": {
   "spot": "puerta",
   "frog": [114, 109],
   "scale": 0.72
  },
  "palma_grande": {
   "spot": "palma_grande",
   "frog": [24, 120],
   "scale": 0.74
  },
  "palma_pequena": {
   "spot": "palma_pequena",
   "frog": [135, 182],
   "scale": 0.88
  },
  "casa_pequena": {
   "spot": "casa_pequena",
   "frog": [66, 178],
   "scale": 0.86
  }
 },
 "frames": {
  "ventana": {
   "old": [112, 71],
   "world": [-0.86, 0, 1.775],
   "what": "the window opening, its middle (old opening [97,61,30,20])",
   "screen": [102.19, 72.13],
   "offset": [-10, 1]
  },
  "puerta": {
   "old": [166, 78],
   "world": [1.475, 0, 1.435],
   "what": "the doorway, its middle (old opening [153,53,26,51])",
   "screen": [145.12, 101.25],
   "offset": [-21, 23]
  },
  "abuela.puerta": {
   "old": [135, 55],
   "spot": "abuela.puerta",
   "what": "abuela in the doorway: where her sprite is drawn",
   "screen": [113, 82],
   "offset": [-22, 27]
  },
  "abuela.paso": {
   "old": [94, 57],
   "spot": "abuela.paso",
   "what": "abuela on the porch: where her sprite is drawn",
   "screen": [85, 73],
   "offset": [-9, 16]
  },
  "palma": {
   "old": [56, 52],
   "world": [-1.12, 3.36, 3.6],
   "what": "the big palm's crown",
   "screen": [35.64, 59.53],
   "offset": [-20, 8]
  },
  "palmita": {
   "old": [195, 132],
   "world": [6.325, 3.195, 2.1],
   "what": "the small palm's crown",
   "screen": [175.54, 160.23],
   "offset": [-19, 28]
  },
  "casita": {
   "old": [73, 126],
   "world": [3.05, 5.91, 1.55],
   "what": "the birdhouse's round hole",
   "screen": [65.42, 167.46],
   "offset": [-8, 41]
  },
  "abuela.plato": {
   "old": [94, 57],
   "spot": "abuela.paso",
   "nudge": [18, 2],
   "what": "abuela's plate with the slices left, held in front of her (frente.js:152)",
   "screen": [85, 73],
   "offset": [9, 18]
  },
  "ventana.lado": {
   "old": [112, 71],
   "world": [-0.86, 0, 1.775],
   "nudge": [2, 3],
   "what": "beside abuela in the window: the frog (cq.42), his towel and drops, the cake table and its steam",
   "screen": [102.19, 72.13],
   "offset": [-8, 4]
  }
 },
 "points": {
  "ave.ventana.posa": {
   "world": [-0.86, 0.06, 2.54],
   "old": [112, 57],
   "what": "PERCH.ventana: on top of the window frame",
   "screen": [101.09, 55.45]
  },
  "ave.puerta.posa": {
   "world": [1.575, 0.2, 2.93],
   "old": [166, 49],
   "what": "PERCH.puerta: on the edge of the roof, over the door (the door frame's top is under the eave: the bird would hide in it)",
   "screen": [143.28, 70.34]
  },
  "ave.ventana.hueco": {
   "world": [-0.86, 0, 1.775],
   "old": [112, 71],
   "what": "HOLE.ventana: the middle of the window (it bonks, it flies in, the slice comes out)",
   "screen": [102.19, 72.13]
  },
  "ave.puerta.hueco": {
   "world": [1.475, 0, 1.3075],
   "old": [166, 80],
   "what": "HOLE.puerta and SPOT.casa_grande: the middle of the door",
   "screen": [145.12, 104.12]
  },
  "ave.palma": {
   "world": [-1.12, 3.36, 3.65],
   "old": [56, 52],
   "what": "SPOT.palma_grande: in the big palm's crown",
   "screen": [35.64, 58.41]
  },
  "ave.palmita": {
   "world": [6.325, 3.195, 2.15],
   "old": [195, 132],
   "what": "SPOT.palma_pequena: in the small palm's crown",
   "screen": [175.54, 159.1]
  },
  "ave.casita": {
   "world": [3.235, 5.845, 1.38],
   "old": [73, 129],
   "what": "SPOT.casa_pequena: at the birdhouse's hole, on its perch: centred on the birdhouse as the old bird was (the hole is on its left face; a bird before the hole hung off the house's left side), its feet as low as before",
   "screen": [70.02, 172.39]
  },
  "ave.casita.techo": {
   "world": [3.05, 5.66, 2.1],
   "old": [73, 112],
   "what": "busca_ave casa_pequena: on the birdhouse's roof",
   "screen": [70.02, 152.78]
  },
  "ave.casita.entra": {
   "world": [3.05, 5.91, 1.55],
   "old": [73, 126],
   "what": "avecasa: into the birdhouse's hole",
   "screen": [65.42, 167.46]
  },
  "ave.puerta.lado": {
   "world": [2.5, 0.35, 0.16],
   "old": [176, 100],
   "what": "busca_ave casa_grande: on the porch beside the door",
   "screen": [157.53, 142.6]
  },
  "ave.techo": {
   "world": [2.3, -0.7, 3.7],
   "old": [196, 30],
   "what": "fin2: on the roof's ridge, right end",
   "screen": [173.15, 51.4]
  },
  "ave.cesped": {
   "world": [4.2, 0.9, 0],
   "old": [196, 120],
   "what": "tapate: on the lawn right of the porch, where it sits with a wing over its eyes",
   "screen": [178.67, 166.88]
  },
  "mano.casa": {
   "world": [0.515, -0.49, 3.34],
   "old": [141, 24],
   "what": "handAt.casa and handAt.casa_grande: on the roof (5 px right of the first place: the thumb cleared abuela's hair on the porch, story 3)",
   "screen": [136.48, 45.02]
  },
  "mano.puerta": {
   "world": [1.475, 0, 1.435],
   "old": [166, 76],
   "what": "handAt.puerta, and abuela's hand fallback: the middle of the door",
   "screen": [145.12, 101.25]
  },
  "mano.ventana": {
   "world": [-0.86, 0, 1.775],
   "old": [112, 72],
   "what": "handAt.ventana: the middle of the window",
   "screen": [102.19, 72.13]
  },
  "mano.casa_pequena": {
   "world": [3.05, 5.66, 1.5],
   "old": [73, 128],
   "what": "handAt.casa_pequena: the birdhouse",
   "screen": [70.02, 166.29]
  },
  "mano.palma_grande": {
   "world": [-1.12, 3.36, 3.35],
   "old": [56, 60],
   "what": "handAt.palma_grande: the big palm's crown",
   "screen": [35.64, 65.16]
  },
  "mano.palma_pequena": {
   "world": [6.325, 3.195, 1.85],
   "old": [195, 140],
   "what": "handAt.palma_pequena: the small palm's crown",
   "screen": [175.54, 165.86]
  },
  "corazon": {
   "frame": "ventana",
   "old": [103, 26],
   "world": [-1.3598, 0, 3.5751],
   "what": "heartAt: the heart over the window in the last picture of story 1 (cuadro)",
   "screen": [93, 27]
  },
  "abuela.ventana": {
   "frame": "ventana",
   "old": [82, 61],
   "world": [-2.5021, 0, 1.5544],
   "what": "ABAT.ventana: abuela's sprite behind the window (clipped to the opening)",
   "screen": [72, 62]
  },
  "abuela.ventana.mesa": {
   "frame": "ventana",
   "old": [75, 61],
   "world": [-2.7196, 0, 1.4656],
   "what": "abuela behind the window when W.tab or W.mesa (the frog or the cake beside her): 3 px right of the plain window offset, so her head is wholly inside the opening",
   "nudge": [3, 0],
   "screen": [68, 62]
  },
  "cq.ventana": {
   "frame": "ventana.lado",
   "old": [112, 67],
   "world": [-0.8721, -0.1106, 1.775],
   "what": "the frog beside her in the window (cq.42), 68 when wet: same offset",
   "screen": [104, 71]
  },
  "toalla": {
   "frame": "ventana.lado",
   "old": [114, 62],
   "world": [-1.0896, -0.4369, 1.775],
   "what": "the towel on his head in the window",
   "screen": [106, 66]
  },
  "globo.ventana": {
   "frame": "ventana",
   "old": [112, 60],
   "world": [-0.8703, 0, 2.265],
   "what": "abuela's bubble in the window",
   "screen": [102, 61]
  },
  "dentro.ventana": {
   "frame": "ventana",
   "old": [112, 59],
   "world": [-0.8703, 0, 2.3094],
   "what": "her voice from behind the shut window (bubble quien)",
   "screen": [102, 60]
  },
  "habla.ventana": {
   "frame": "ventana",
   "old": [112, 60],
   "world": [-0.8703, 0, 2.265],
   "what": "talkAt abuela in the window (y 38 with a bubble; x 105 with the cake): same offset",
   "screen": [102, 61]
  },
  "habla.dentro.ventana": {
   "frame": "ventana",
   "old": [112, 37],
   "world": [-0.8703, 0, 3.2865],
   "what": "talkAt abuela behind the shut window",
   "screen": [102, 38]
  },
  "mariposa.1": {
   "frame": "ventana",
   "old": [98, 97],
   "world": [-1.6318, 0, 0.3109],
   "what": "the pink butterfly's middle (ambient: 98 + 34 sin, 97 + 9 sin)",
   "screen": [88, 98]
  },
  "cq.asoma": {
   "old": [150, 84],
   "world": [0.7399, -0.2392, 0.16],
   "what": "the frog peeking from behind the half-open door (cq.6): his left side hidden by the left jamb, the rest whole in the gap (clipped to puerta.hueco)",
   "screen": [126, 106]
  },
  "dentro.puerta": {
   "frame": "puerta",
   "old": [166, 53],
   "world": [1.4686, 0, 2.5537],
   "what": "her voice from behind the shut door (bubble quien)",
   "screen": [145, 76]
  },
  "habla.dentro.puerta": {
   "frame": "puerta",
   "old": [166, 31],
   "world": [1.4686, 0, 3.5307],
   "what": "talkAt abuela behind the shut door",
   "screen": [145, 54]
  },
  "mariposa.2": {
   "frame": "puerta",
   "old": [203, 72],
   "world": [3.4811, 0, 2.5315],
   "what": "the yellow butterfly's middle (ambient: 203 + 13 sin, 72 + 7 sin)",
   "screen": [182, 95]
  },
  "globo.puerta": {
   "frame": "abuela.puerta",
   "old": [147, 69],
   "world": [0.5506, 0.1699, 1.36],
   "what": "abuela's bubble at the door, and on the porch (x 141, y 66 for como): same offset",
   "screen": [125, 96]
  },
  "habla.puerta": {
   "frame": "abuela.puerta",
   "old": [156, 56],
   "world": [0.0883, -0.782, 1.36],
   "what": "talkAt abuela at the door (y 47 with a bubble, x 141 for como): same offset",
   "screen": [134, 83]
  },
  "habla.paso": {
   "frame": "abuela.paso",
   "old": [124, 56],
   "world": [-1.0268, -0.8636, 1.36],
   "what": "talkAt abuela on the porch (y 40 with a bubble): same offset",
   "screen": [115, 72]
  }
 },
 "views": {
  "wide": {
   "world": [0.5, 0, 1.45],
   "screen": [127.19, 91.95],
   "zoom": 1,
   "x0": 29,
   "region": null,
   "old": [44, 0, 196, 216],
   "what": "the house, the path and the sky: every story's usual view"
  },
  "casa": {
   "world": [0.5, 0, 1.45],
   "screen": [127.19, 91.95],
   "zoom": 1,
   "x0": 29,
   "region": null,
   "old": [51.7, 15, 180.6, 199],
   "what": "the house (the same window as wide: the house fits it whole)"
  },
  "puerta": {
   "world": [1.475, 0.3, 1.88],
   "screen": [139.6, 93.99],
   "zoom": 2,
   "x0": 91,
   "region": [91, 40, 98, 108],
   "old": [117, 30, 98, 108],
   "what": "the door, at 2x: the whole door, abuela in it, the frog before it on the porch. The frog on the path (patio) is wholly below it, as in the old view (16 px lower, his head showed at its bottom edge)"
  },
  "ventana": {
   "world": [-0.86, 0.3, 1],
   "screen": [96.67, 92.34],
   "zoom": 2,
   "x0": 48,
   "region": [48, 38, 98, 108],
   "old": [84, 24, 98, 108],
   "what": "the window, at 2x: the window, abuela in it, the frog under it and leaning in"
  },
  "cuadro": {
   "world": [-0.86, 0, 2.55],
   "screen": [102.19, 54.68],
   "zoom": 2,
   "x0": 53,
   "region": [53, 1, 98, 108],
   "old": [63, 18, 98, 108],
   "what": "story 1's last picture, at 2x: abuela and the frog in the window, the heart over it"
  },
  "wide@donde-esta-el-pajaro": {
   "world": [0.755, 1.425, 0],
   "screen": [105.68, 140.04],
   "zoom": 1,
   "x0": 8,
   "region": null,
   "old": [30, 0, 196, 216],
   "what": "story 3's own wide view (cam.wide in donde-esta-el-pajaro.json): the big palm, the house, the birdhouse and the small palm together"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [0, 94, 180, 96],
   "uses": [
    "cual-frente.json grande.no.cam",
    "cual-frente.json pequeña.si.cam"
   ],
   "to": {
    "point": "casa_pequena",
    "world": [3.45, 5.26, 1]
   },
   "screen": [84.72, 177.55],
   "crop": [0, 112, 196, 104],
   "what": "the birdhouse"
  },
  {
   "kind": "cam",
   "old": [30, 0, 196, 216],
   "uses": ["donde-esta-el-pajaro.json cam.wide"],
   "to": {
    "view": "wide@donde-esta-el-pajaro"
   },
   "x0": 8,
   "what": "story 3's wide view"
  },
  {
   "kind": "cam",
   "old": [44, 40, 196, 104],
   "uses": [
    "cual-frente.json hola.si.cam",
    "cual-frente.json hola.no.cam",
    "cual-frente.json adiós.si.cam",
    "cual-frente.json adiós.no.cam"
   ],
   "to": {
    "point": "puerta.cq",
    "world": [1.375, 0.5, 1.06]
   },
   "screen": [134.09, 113.37],
   "crop": [36, 61, 196, 104],
   "what": "the door with the frog before it"
  },
  {
   "kind": "cam",
   "old": [44, 120, 180, 96],
   "uses": ["cual-frente.json casa.no.cam"],
   "to": {
    "point": "patio.abajo",
    "world": [3.5277, 5.8527, 0]
   },
   "screen": [75.26, 206.23],
   "crop": [0, 112, 196, 104],
   "what": "the yard with no house: the bottom of the picture, left (the house's foot still shows: see the report)"
  },
  {
   "kind": "cam",
   "old": [52, 8, 180, 96],
   "uses": [
    "cual-frente.json casa.si.cam",
    "cual-frente.json grande.si.cam",
    "cual-frente.json pequeña.no.cam"
   ],
   "to": {
    "point": "casa.arriba",
    "world": [0.5, -1.4, 2.9]
   },
   "screen": [152.93, 46.43],
   "crop": [44, 0, 196, 104],
   "what": "the house: its roof and walls (the top of the picture)"
  },
  {
   "kind": "cam",
   "old": [55, 46, 94, 50],
   "uses": ["cual-frente.json puerta.no.cam", "cual-frente.json ventana.si.cam", "cual-frente.json abre.si.cam", "cual-frente.json abre.no.cam"],
   "to": {
    "point": "ventana",
    "world": [-0.86, 0, 1.775]
   },
   "screen": [102.19, 72.13],
   "crop": [4, 20, 196, 104],
   "what": "the window"
  },
  {
   "kind": "cam",
   "old": [55, 96, 109, 58],
   "uses": [
    "cual-frente.json sí.si.cam",
    "cual-frente.json no.no.cam"
   ],
   "to": {
    "point": "respuesta",
    "world": [-0.7887, 0.7887, 0]
   },
   "screen": [89, 120],
   "crop": [0, 68, 196, 104],
   "what": "the answer bubble over the frog at patio (respBox with cam = wide); both sí and no pictures show their one bubble whole"
  },
  {
   "kind": "cam",
   "old": [115, 96, 109, 58],
   "uses": [
    "cual-frente.json sí.no.cam",
    "cual-frente.json no.si.cam"
   ],
   "to": {
    "point": "respuesta",
    "world": [-0.7887, 0.7887, 0]
   },
   "screen": [89, 120],
   "crop": [0, 68, 196, 104],
   "what": "the answer bubble over the frog at patio (respBox with cam = wide); both sí and no pictures show their one bubble whole"
  },
  {
   "kind": "cam",
   "old": [135, 46, 94, 50],
   "uses": ["cual-frente.json puerta.si.cam", "cual-frente.json ventana.no.cam", "cual-frente.json abuela.si.cam", "cual-frente.json abuela.no.cam", "cual-frente.json cierra.si.cam", "cual-frente.json cierra.no.cam"],
   "to": {
    "point": "puerta",
    "world": [1.475, 0, 1.435]
   },
   "screen": [145.12, 101.25],
   "crop": [44, 49, 196, 104],
   "what": "the door"
  },
  {
   "kind": "crop",
   "old": [89.36, 46, 45.28, 50],
   "uses": [
    "nivel.js NV puerta.p1",
    "nivel.js NV abre.p0",
    "nivel.js NV abre.p1",
    "nivel.js NV silla.p3"
   ],
   "to": {
    "point": "ventana",
    "world": [-0.86, 0, 1.775]
   },
   "screen": [102.19, 72.13],
   "crop": [4, 20, 196, 104],
   "what": "the window"
  },
  {
   "kind": "crop",
   "old": [112.91, 40, 94.19, 104],
   "uses": [
    "nivel.js NV hola.p0",
    "nivel.js NV hola.p1"
   ],
   "to": {
    "point": "puerta.cq",
    "world": [1.375, 0.5, 1.06]
   },
   "screen": [134.09, 113.37],
   "crop": [36, 61, 196, 104],
   "what": "the door with the frog before it"
  },
  {
   "kind": "crop",
   "old": [143.36, 46, 45.28, 50],
   "uses": [
    "nivel.js NV abuela.p0",
    "nivel.js NV puerta.p0",
    "nivel.js NV abre.p2"
   ],
   "to": {
    "point": "puerta",
    "world": [1.475, 0, 1.435]
   },
   "screen": [145.12, 101.25],
   "crop": [44, 49, 196, 104],
   "what": "the door"
  },
  {
   "kind": "point",
   "old": [0, 0],
   "uses": ["donde-esta-el-pajaro.json beats.1.then.0.set.ave"],
   "to": {
    "none": "set.ave in mode head: x and y are not used (avePos puts the bird on the frog's head)"
   }
  },
  {
   "kind": "point",
   "old": [146, 86],
   "uses": [
    "cual-frente.json hola.si.set.cq",
    "cual-frente.json adiós.no.set.cq"
   ],
   "to": {
    "spot": "hola"
   },
   "screen": [124.34, 133.91],
   "frog": [108, 109],
   "scale": 0.62
  },
  {
   "kind": "point",
   "old": [176, 116],
   "uses": [
    "cual-frente.json hola.no.set.cq",
    "cual-frente.json adiós.si.set.cq"
   ],
   "to": {
    "spot": "adios"
   },
   "screen": [152.47, 161.38],
   "frog": [136, 136],
   "scale": 0.85
  },
  {
   "kind": "x",
   "old": [112],
   "uses": [
    "nivel.js NV puerta.p1",
    "nivel.js NV abre.p0",
    "nivel.js NV abre.p1",
    "nivel.js NV silla.p3"
   ],
   "to": {
    "point": "ventana",
    "world": [-0.86, 0, 1.775]
   },
   "screen": [102.19, 72.13],
   "x": 102,
   "what": "the window: its middle x"
  },
  {
   "kind": "x",
   "old": [160],
   "uses": [
    "nivel.js NV hola.p0",
    "nivel.js NV hola.p1"
   ],
   "to": {
    "point": "puerta.cq",
    "world": [1.375, 0.5, 1.06]
   },
   "screen": [134.09, 113.37],
   "x": 134,
   "what": "the door with the frog: its middle x"
  },
  {
   "kind": "x",
   "old": [166],
   "uses": [
    "nivel.js NV abuela.p0",
    "nivel.js NV puerta.p0",
    "nivel.js NV abre.p2"
   ],
   "to": {
    "point": "puerta",
    "world": [1.475, 0, 1.435]
   },
   "screen": [145.12, 101.25],
   "x": 145,
   "what": "the door: its middle x"
  }
 ],
 "pictures": {
  "casa.si": {
   "world": [0.5, -1.4, 2.9],
   "screen": [152.93, 46.43],
   "zoom": 1,
   "crop": [44, 0, 196, 104],
   "what": "the whole house, its roof at the top"
  },
  "casa.no": {
   "world": [3.8085, 3.7335, 0],
   "screen": [119.38, 189.33],
   "zoom": 2,
   "crop": [70, 163, 98, 52],
   "what": "the yard: the path and the lawn, no part of the house"
  },
  "puerta.si": {
   "world": [2.8828, 0, 2.4475],
   "screen": [171, 91.39],
   "zoom": 2,
   "crop": [122, 65, 98, 52],
   "what": "the door, close: no window in it"
  },
  "puerta.no": {
   "world": [-2.4477, 0, 0.9935],
   "screen": [73, 75.13],
   "zoom": 2,
   "crop": [24, 49, 98, 52],
   "what": "the window, close: no door in it"
  },
  "ventana.si": {
   "world": [-2.4477, 0, 0.9935],
   "screen": [73, 75.13],
   "zoom": 2,
   "crop": [24, 49, 98, 52],
   "what": "the window, close: no door in it"
  },
  "ventana.no": {
   "world": [2.8828, 0, 2.4475],
   "screen": [171, 91.39],
   "zoom": 2,
   "crop": [122, 65, 98, 52],
   "what": "the door, close: no window in it"
  },
  "abuela.si": {
   "world": [1.475, 0, 1.435],
   "screen": [145.12, 101.25],
   "zoom": 1,
   "crop": [44, 49, 196, 104],
   "what": "the door with abuela in it"
  },
  "abuela.no": {
   "world": [1.475, 0, 1.435],
   "screen": [145.12, 101.25],
   "zoom": 1,
   "crop": [44, 49, 196, 104],
   "what": "the shut door, nobody"
  },
  "abre.si": {
   "world": [-2.4477, 0, 0.9935],
   "screen": [73, 75.13],
   "zoom": 2,
   "crop": [24, 49, 98, 52],
   "what": "the window, close: open, abuela in it"
  },
  "abre.no": {
   "world": [-2.4477, 0, 0.9935],
   "screen": [73, 75.13],
   "zoom": 2,
   "crop": [24, 49, 98, 52],
   "what": "the window, close: shut"
  },
  "cierra.si": {
   "world": [1.475, 0, 1.741],
   "screen": [145.12, 94.36],
   "zoom": 2,
   "crop": [96, 68, 98, 52],
   "what": "the door, close: half shut, abuela behind it"
  },
  "cierra.no": {
   "world": [1.475, 0, 1.741],
   "screen": [145.12, 94.36],
   "zoom": 2,
   "crop": [96, 68, 98, 52],
   "what": "the door, close: open, abuela in it"
  },
  "hola.si": {
   "world": [1.375, 0.5, 1.06],
   "screen": [134.09, 113.37],
   "zoom": 1,
   "crop": [36, 61, 196, 104],
   "what": "the door with abuela and the frog: day, waving"
  },
  "hola.no": {
   "world": [1.375, 0.5, 1.06],
   "screen": [134.09, 113.37],
   "zoom": 1,
   "crop": [36, 61, 196, 104],
   "what": "the door at sunset, the frog going"
  },
  "adiós.si": {
   "world": [1.375, 0.5, 1.06],
   "screen": [134.09, 113.37],
   "zoom": 1,
   "crop": [36, 61, 196, 104],
   "what": "the door at sunset, the frog going"
  },
  "adiós.no": {
   "world": [1.375, 0.5, 1.06],
   "screen": [134.09, 113.37],
   "zoom": 1,
   "crop": [36, 61, 196, 104],
   "what": "the door with abuela and the frog: day, waving"
  },
  "sí.si": {
   "world": [-0.7887, 0.7887, 0],
   "screen": [89, 120],
   "zoom": 2,
   "crop": [40, 94, 98, 52],
   "what": "the answer bubble, close: the frog nodding"
  },
  "sí.no": {
   "world": [-0.7887, 0.7887, 0],
   "screen": [89, 120],
   "zoom": 2,
   "crop": [40, 94, 98, 52],
   "what": "the answer bubble, close: the frog shaking his head"
  },
  "no.si": {
   "world": [-0.7887, 0.7887, 0],
   "screen": [89, 120],
   "zoom": 2,
   "crop": [40, 94, 98, 52],
   "what": "the answer bubble, close: the frog shaking his head"
  },
  "no.no": {
   "world": [-0.7887, 0.7887, 0],
   "screen": [89, 120],
   "zoom": 2,
   "crop": [40, 94, 98, 52],
   "what": "the answer bubble, close: the frog nodding"
  },
  "grande.si": {
   "world": [0.5, -1.4, 2.9],
   "screen": [152.93, 46.43],
   "zoom": 1,
   "crop": [44, 0, 196, 104],
   "what": "the whole house"
  },
  "grande.no": {
   "world": [3.05, 5.66, 1.15],
   "screen": [70.02, 174.17],
   "zoom": 2,
   "crop": [21, 148, 98, 52],
   "what": "the birdhouse, close"
  },
  "pequeña.si": {
   "world": [3.05, 5.66, 1.15],
   "screen": [70.02, 174.17],
   "zoom": 2,
   "crop": [21, 148, 98, 52],
   "what": "the birdhouse, close"
  },
  "pequeña.no": {
   "world": [0.5, -1.4, 2.9],
   "screen": [152.93, 46.43],
   "zoom": 1,
   "crop": [44, 0, 196, 104],
   "what": "the whole house"
  }
 },
 "level": [
  {
   "w": "abuela",
   "index": 0,
   "picture": "abuela.si",
   "crop": [44, 49, 196, 104],
   "zoom": 1,
   "old": [143.36, 46, 45.28, 50]
  },
  {
   "w": "puerta",
   "index": 0,
   "picture": "puerta.si",
   "crop": [122, 65, 98, 52],
   "zoom": 2,
   "old": [143.36, 46, 45.28, 50]
  },
  {
   "w": "puerta",
   "index": 1,
   "picture": "ventana.si",
   "crop": [24, 49, 98, 52],
   "zoom": 2,
   "old": [89.36, 46, 45.28, 50]
  },
  {
   "w": "abre",
   "index": 0,
   "picture": "abre.si",
   "crop": [24, 49, 98, 52],
   "zoom": 2,
   "old": [89.36, 46, 45.28, 50]
  },
  {
   "w": "abre",
   "index": 1,
   "picture": "abre.no",
   "crop": [24, 49, 98, 52],
   "zoom": 2,
   "old": [89.36, 46, 45.28, 50]
  },
  {
   "w": "abre",
   "index": 2,
   "picture": "puerta.si",
   "crop": [122, 65, 98, 52],
   "zoom": 2,
   "old": [143.36, 46, 45.28, 50]
  },
  {
   "w": "hola",
   "index": 0,
   "picture": "hola.si",
   "crop": [36, 61, 196, 104],
   "zoom": 1,
   "old": [112.91, 40, 94.19, 104]
  },
  {
   "w": "hola",
   "index": 1,
   "picture": "adiós.si",
   "crop": [36, 61, 196, 104],
   "zoom": 1,
   "old": [112.91, 40, 94.19, 104]
  },
  {
   "w": "silla",
   "index": 3,
   "picture": "ventana.si",
   "crop": [24, 49, 98, 52],
   "zoom": 2,
   "old": [89.36, 46, 45.28, 50]
  }
 ],
 "clips": {
  "ventana.hueco": {
   "thing": "ventana",
   "face": "opening",
   "world": [
    [-1.71, 0, 1.15],
    [-0.01, 0, 1.15],
    [-0.01, 0, 2.4],
    [-1.71, 0, 2.4]
   ],
   "screen": [
    [86.56, 78.39],
    [117.82, 94.01],
    [117.82, 65.87],
    [86.56, 50.24]
   ],
   "box": [86, 50, 32, 45],
   "what": "the window opening on the front wall (old rect [97,61,30,20], frente.js:147): abuela, the cake table, the frog beside her, the towel are drawn inside it"
  },
  "puerta.hueco": {
   "thing": "puerta",
   "face": "gap",
   "world": [
    [0.75, 0, 0.16],
    [1.3766, 0, 0.16],
    [1.3766, 0, 2.71],
    [0.75, 0, 2.71]
   ],
   "screen": [
    [131.79, 123.29],
    [143.31, 129.05],
    [143.31, 71.63],
    [131.79, 65.87]
   ],
   "box": [131, 65, 13, 65],
   "what": "the gap between the left jamb and the half-open leaf (door=half), on the front wall (old rect [153,53,11,51], frente.js:143-144): who peeks from behind the door"
  }
 },
 "front": {
  "things": [],
  "why": "nothing in the set covers a character: abuela inside the window and the frog or abuela behind the half-open door are clipped (clips), the birdhouse and the small palm are drawn before the characters as before, and every spot stands in front of what is near it"
 },
 "shadows": {
  "coqui": {
   "radius": 0.45,
   "at": "his spot (the ground under his feet: unproject his feet, z 0, or the porch's .16 on the porch)",
   "when": "W.cq.vis and he is not in the window (W.tab)",
   "cast": "castShadow(x, y, .3, .45)"
  },
  "abuela": {
   "radius": 0.35,
   "at": "her spot",
   "when": "W.ab with en puerta or paso (none in the window, none while she peeks)",
   "cast": "for (z = .3; z <= 2; z += .35) castShadow(x, y, z + spotZ, .35)"
  },
  "dropped": "juego.js frog()'s shadow() under the frog is not drawn in El frente (the engine casts his)"
 },
 "dropped": [
  "frente.js:140 c.drawImage(bg) -> the set, for setKey(W)",
  "frente.js:97 and :122 c.drawImage(palmita) -> the set (hide=1; its rustle: rustle and side)",
  "frente.js:100 and :125 c.drawImage(casita) -> the set (hide=1; its rustle: rustle and side)",
  "frente.js:163 the pale sun over the sun (W.storm) -> the set (sky storm, storm2: a pale sun; rain: none)",
  "frente.js:164 the W.dark wash over the whole picture -> the set (sky storm, storm2, rain light the set itself)",
  "frente.js:165 the W.dusk washes -> the set (sky dusk, sunset)"
 ],
 "code": [
  {
   "line": 48,
   "old": "250-(F/4)%310, 0 (the small cloud)",
   "to": "sky: unchanged"
  },
  {
   "line": 49,
   "old": "98+34sin, 97+9sin (pink butterfly)",
   "to": {
    "point": "mariposa.1",
    "new": [88, 98]
   },
   "note": "the amplitudes stay"
  },
  {
   "line": 50,
   "old": "203+13sin, 72+7sin (yellow butterfly)",
   "to": {
    "point": "mariposa.2",
    "new": [182, 95]
   },
   "note": "the amplitudes stay"
  },
  {
   "line": 61,
   "old": "ABAT.puerta [135,55]",
   "to": {
    "spot": "abuela.puerta",
    "new": [113, 82]
   }
  },
  {
   "line": 61,
   "old": "ABAT.ventana [82,61]",
   "to": {
    "point": "abuela.ventana",
    "new": [72, 62]
   }
  },
  {
   "line": 61,
   "old": "ABAT.paso [94,57]",
   "to": {
    "spot": "abuela.paso",
    "new": [85, 73]
   }
  },
  {
   "line": 64,
   "old": "mesa fr [108,75,20,2]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [100, 79, 20, 2]
   }
  },
  {
   "line": 64,
   "old": "mesa fr [108,77,20,1]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [100, 81, 20, 1]
   }
  },
  {
   "line": 64,
   "old": "mesa fr [110,78,2,3]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [102, 82, 2, 3]
   }
  },
  {
   "line": 64,
   "old": "mesa fr [124,78,2,3]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [116, 82, 2, 3]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [111,74,14,1]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [103, 78, 14, 1]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [112,68,12,6]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [104, 72, 12, 6]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [112,67,12,2]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [104, 71, 12, 2]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [111,67,1,7]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [103, 71, 1, 7]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [124,67,1,7]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [116, 71, 1, 7]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [112,66,12,1]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [104, 70, 12, 1]
   }
  },
  {
   "line": 65,
   "old": "mesa fr [117,65,2,2]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [109, 69, 2, 2]
   }
  },
  {
   "line": 66,
   "old": "steam 113+k*4, 64-j*3",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [105, 68]
   },
   "note": "the k and j steps stay"
  },
  {
   "line": 77,
   "old": "PERCH.ventana [112,57]",
   "to": {
    "point": "ave.ventana.posa",
    "new": [101.09, 55.45]
   }
  },
  {
   "line": 77,
   "old": "PERCH.puerta [166,49]",
   "to": {
    "point": "ave.puerta.posa",
    "new": [143.28, 70.34]
   }
  },
  {
   "line": 77,
   "old": "HOLE.ventana [112,71]",
   "to": {
    "point": "ave.ventana.hueco",
    "new": [102.19, 72.13]
   }
  },
  {
   "line": 77,
   "old": "HOLE.puerta [166,80]",
   "to": {
    "point": "ave.puerta.hueco",
    "new": [145.12, 104.12]
   }
  },
  {
   "line": 78,
   "old": "avePos head: frogBox + 19 / + 2",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 79,
   "old": "avePos circle 150+56cos, 22+7sin",
   "to": "sky: unchanged"
  },
  {
   "line": 83,
   "old": "drawAve: p[0], p[1]-H+2",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 84,
   "old": "the slice in its beak: p[0]-19 / +11, p[1]-14",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 85,
   "old": "z of sleep: p[0]+12, p[1]-H-4",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 86,
   "old": "little heart: p[0]-2, p[1]-H-5",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 88,
   "old": "SPOT.palma_grande [56,52]",
   "to": {
    "point": "ave.palma",
    "new": [35.64, 58.41]
   }
  },
  {
   "line": 113,
   "old": "SPOT.palma_grande [56,52] (the copy inside hud)",
   "to": {
    "point": "ave.palma",
    "new": [35.64, 58.41]
   }
  },
  {
   "line": 88,
   "old": "SPOT.palma_pequena [195,132]",
   "to": {
    "point": "ave.palmita",
    "new": [175.54, 159.1]
   }
  },
  {
   "line": 113,
   "old": "SPOT.palma_pequena [195,132] (the copy inside hud)",
   "to": {
    "point": "ave.palmita",
    "new": [175.54, 159.1]
   }
  },
  {
   "line": 88,
   "old": "SPOT.casa_pequena [73,129]",
   "to": {
    "point": "ave.casita",
    "new": [70.02, 172.39]
   }
  },
  {
   "line": 113,
   "old": "SPOT.casa_pequena [73,129] (the copy inside hud)",
   "to": {
    "point": "ave.casita",
    "new": [70.02, 172.39]
   }
  },
  {
   "line": 88,
   "old": "SPOT.casa_grande [166,80]",
   "to": {
    "point": "ave.puerta.hueco",
    "new": [145.12, 104.12]
   }
  },
  {
   "line": 113,
   "old": "SPOT.casa_grande [166,80] (the copy inside hud)",
   "to": {
    "point": "ave.puerta.hueco",
    "new": [145.12, 104.12]
   }
  },
  {
   "line": 97,
   "old": "drawImage(palmita, 174+sh, 114)",
   "to": "dropped: the set (hide=1, rustle palma)"
  },
  {
   "line": 122,
   "old": "drawImage(palmita, 174+sh, 114)",
   "to": "dropped: the set (hide=1, rustle palma)"
  },
  {
   "line": 100,
   "old": "drawImage(casita, 60+sh, 110)",
   "to": "dropped: the set (hide=1, rustle casa)"
  },
  {
   "line": 125,
   "old": "drawImage(casita, 60+sh, 110)",
   "to": "dropped: the set (hide=1, rustle casa)"
  },
  {
   "line": 101,
   "old": "legs fr [70,130,2,6]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [62, 171, 2, 6]
   }
  },
  {
   "line": 101,
   "old": "legs fr [75,130,2,6]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [67, 171, 2, 6]
   }
  },
  {
   "line": 101,
   "old": "legs fr [69,135,4,2]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [61, 176, 4, 2]
   }
  },
  {
   "line": 101,
   "old": "legs fr [74,135,4,2]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [66, 176, 4, 2]
   }
  },
  {
   "line": 126,
   "old": "legs fr [70,130,2,6]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [62, 171, 2, 6]
   }
  },
  {
   "line": 126,
   "old": "legs fr [75,130,2,6]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [67, 171, 2, 6]
   }
  },
  {
   "line": 126,
   "old": "legs fr [69,135,4,2]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [61, 176, 4, 2]
   }
  },
  {
   "line": 126,
   "old": "legs fr [74,135,4,2]",
   "to": {
    "frame": "casita",
    "offset": [-8, 41],
    "new": [66, 176, 4, 2]
   }
  },
  {
   "line": 102,
   "old": "rustle leaf fr [44,40,2,2]",
   "to": {
    "frame": "palma",
    "offset": [-20, 8],
    "new": [24, 48, 2, 2]
   }
  },
  {
   "line": 102,
   "old": "rustle leaf fr [80,46,2,2]",
   "to": {
    "frame": "palma",
    "offset": [-20, 8],
    "new": [60, 54, 2, 2]
   }
  },
  {
   "line": 102,
   "old": "rustle leaf fr [180,120,2,2]",
   "to": {
    "frame": "palmita",
    "offset": [-19, 28],
    "new": [161, 148, 2, 2]
   }
  },
  {
   "line": 102,
   "old": "rustle leaf fr [208,126,2,2]",
   "to": {
    "frame": "palmita",
    "offset": [-19, 28],
    "new": [189, 154, 2, 2]
   }
  },
  {
   "line": 127,
   "old": "rustle leaf fr [44,40,2,2]",
   "to": {
    "frame": "palma",
    "offset": [-20, 8],
    "new": [24, 48, 2, 2]
   }
  },
  {
   "line": 127,
   "old": "rustle leaf fr [80,46,2,2]",
   "to": {
    "frame": "palma",
    "offset": [-20, 8],
    "new": [60, 54, 2, 2]
   }
  },
  {
   "line": 127,
   "old": "rustle leaf fr [180,120,2,2]",
   "to": {
    "frame": "palmita",
    "offset": [-19, 28],
    "new": [161, 148, 2, 2]
   }
  },
  {
   "line": 127,
   "old": "rustle leaf fr [208,126,2,2]",
   "to": {
    "frame": "palmita",
    "offset": [-19, 28],
    "new": [189, 154, 2, 2]
   }
  },
  {
   "line": 111,
   "old": "hud plato(g,5,6) and (DW-3*17-26, 6)",
   "to": "display: unchanged (hud draws on the 196 x 216 display)"
  },
  {
   "line": 112,
   "old": "hud x 5, y 5 (the plate at double size)",
   "to": "display: unchanged"
  },
  {
   "line": 136,
   "old": "hud dish x-3, y+19",
   "to": "display: unchanged"
  },
  {
   "line": 140,
   "old": "drawImage(bg, 0, 0)",
   "to": "dropped: the set"
  },
  {
   "line": 143,
   "old": "clip rect [153,53,11,51]",
   "to": {
    "clip": "puerta.hueco"
   }
  },
  {
   "line": 143,
   "old": "drawImage(cq.6, 150, 84)",
   "to": {
    "point": "cq.asoma",
    "new": [126, 106]
   }
  },
  {
   "line": 144,
   "old": "clip rect [153,53,11,51]",
   "to": {
    "clip": "puerta.hueco"
   }
  },
  {
   "line": 144,
   "old": "drawImage(abuela, 135, 55)",
   "to": {
    "spot": "abuela.puerta",
    "new": [113, 82]
   },
   "note": "as in the doorway: the half-open leaf hides about half of her (clip puerta.hueco), as in the old picture"
  },
  {
   "line": 147,
   "old": "clip rect [97,61,30,20]",
   "to": {
    "clip": "ventana.hueco"
   }
  },
  {
   "line": 147,
   "old": "drawImage(abuela, 82, 61)",
   "to": {
    "point": "abuela.ventana",
    "new": [72, 62]
   }
  },
  {
   "line": 147,
   "old": "drawImage(abuela, 75, 61) (W.tab || W.mesa)",
   "to": {
    "point": "abuela.ventana.mesa",
    "new": [68, 62]
   }
  },
  {
   "line": 148,
   "old": "drawImage(cq.42, 112+sh, 67 or 68)",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [104, 71]
   },
   "note": "y 68 when wet: the same offset; +sh stays"
  },
  {
   "line": 149,
   "old": "towel(c, 114, 62)",
   "to": {
    "point": "toalla",
    "new": [106, 66]
   }
  },
  {
   "line": 149,
   "old": "drips 113+k*13, 70+...",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [105, 74]
   },
   "note": "the steps stay"
  },
  {
   "line": 151,
   "old": "drop [110,64]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [102, 68]
   }
  },
  {
   "line": 151,
   "old": "drop [120,62]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [112, 66]
   }
  },
  {
   "line": 151,
   "old": "drop [127,66]",
   "to": {
    "frame": "ventana.lado",
    "offset": [-8, 4],
    "new": [119, 70]
   }
  },
  {
   "line": 152,
   "old": "drawImage(abuela, ABAT.paso)",
   "to": {
    "spot": "abuela.paso",
    "new": [85, 73]
   }
  },
  {
   "line": 152,
   "old": "her plate: ABAT.paso + (5+i*4, 27), (3, 30)",
   "to": {
    "frame": "abuela.plato",
    "offset": [9, 18],
    "new": [108, 102]
   },
   "note": "every slice and the plate line move by the frame's offset"
  },
  {
   "line": 155,
   "old": "dust at frogBox + [-6,0], [-11,-2], [-16,1]; the back of his head at b.x+b.w+1",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 157,
   "old": "drops around the frog (frogBox)",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 158,
   "old": "drops around the frog (frogBox)",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 160,
   "old": "wings: p[0] +- (11+f), p[1]-14",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 161,
   "old": "W.trozo x-4, y-4 ...",
   "to": "relative to W.trozo (set by come from HOLE and the frog): unchanged"
  },
  {
   "line": 162,
   "old": "leaves fly from W.hojas (set by mira from SPOT) by [-1,-1], [1,-1], [-1,0], [1,0], [0,-1]",
   "to": "relative to W.hojas: unchanged"
  },
  {
   "line": 163,
   "old": "arc(210, 17, 10): the pale sun",
   "to": "dropped: the set (sky storm)"
  },
  {
   "line": 164,
   "old": "fillRect(0, 0, SW, SH): W.dark",
   "to": "dropped: the set (sky)"
  },
  {
   "line": 165,
   "old": "fillRect(0, 0, SW, SH) and (0, 0, SW, 40): W.dusk",
   "to": "dropped: the set (sky)"
  },
  {
   "line": 167,
   "old": "drawImage(nube, x, 0)",
   "to": "sky: unchanged"
  },
  {
   "line": 168,
   "old": "rain under the cloud: x+9.., 21+..",
   "to": "sky: unchanged"
  },
  {
   "line": 169,
   "old": "rain(): the whole picture",
   "to": "sky: unchanged"
  },
  {
   "line": 170,
   "old": "flash: fillRect(0,0,SW,SH), the whole picture; bolt at nube.x+44, 21",
   "to": "sky: unchanged"
  },
  {
   "line": 172,
   "old": "bub at [112,60] (window)",
   "to": {
    "point": "globo.ventana",
    "new": [102, 61]
   }
  },
  {
   "line": 172,
   "old": "bub at [147,69] / [141,66] (door, porch)",
   "to": {
    "frame": "abuela.puerta",
    "offset": [-22, 27],
    "new": [125, 96]
   },
   "note": "como: [141,66] + the same offset. The old code uses these for abuela on the porch too: kept"
  },
  {
   "line": 173,
   "old": "bub quien at [112,59]",
   "to": {
    "point": "dentro.ventana",
    "new": [102, 60]
   }
  },
  {
   "line": 173,
   "old": "bub quien at [166,53]",
   "to": {
    "point": "dentro.puerta",
    "new": [145, 76]
   }
  },
  {
   "line": 174,
   "old": "the frog's bubble at frogBox",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 178,
   "old": "talkAt paso [124, 40 or 56]",
   "to": {
    "frame": "abuela.paso",
    "offset": [-9, 16],
    "new": [115, 72]
   },
   "note": "y 40 with a bubble: the same offset"
  },
  {
   "line": 178,
   "old": "talkAt ventana [105 or 112, 38 or 60]",
   "to": {
    "frame": "ventana",
    "offset": [-10, 1],
    "new": [102, 61]
   },
   "note": "x 105 with the cake, y 38 with a bubble: the same offset"
  },
  {
   "line": 178,
   "old": "talkAt puerta [141 or 156, 47 or 56]",
   "to": {
    "frame": "abuela.puerta",
    "offset": [-22, 27],
    "new": [134, 83]
   },
   "note": "x 141 for como, y 47 with a bubble: the same offset"
  },
  {
   "line": 179,
   "old": "talkAt dentro [112,37]",
   "to": {
    "point": "habla.dentro.ventana",
    "new": [102, 38]
   }
  },
  {
   "line": 179,
   "old": "talkAt dentro [166,31]",
   "to": {
    "point": "habla.dentro.puerta",
    "new": [145, 54]
   }
  },
  {
   "line": 181,
   "old": "box abuela ventana [97,61,30,20]",
   "to": {
    "clip": "ventana.hueco",
    "box": [86, 50, 32, 45]
   },
   "note": "the window opening's box"
  },
  {
   "line": 181,
   "old": "box abuela paso [110,58,36,50]",
   "to": {
    "frame": "abuela.paso",
    "offset": [-9, 16],
    "new": [101, 74, 36, 50]
   }
  },
  {
   "line": 181,
   "old": "box abuela puerta [151,56,29,49]",
   "to": {
    "frame": "abuela.puerta",
    "offset": [-22, 27],
    "new": [129, 83, 29, 49]
   }
  },
  {
   "line": 182,
   "old": "box palma_grande [34,34,48,72]",
   "to": {
    "thing": "palma_grande",
    "box": [9, 53, 58, 90]
   }
  },
  {
   "line": 182,
   "old": "box palma_pequena [174,114,42,56]",
   "to": {
    "thing": "palma_pequena",
    "box": [151, 155, 49, 55]
   }
  },
  {
   "line": 182,
   "old": "box casa_pequena [60,110,26,58]",
   "to": {
    "thing": "casa_pequena",
    "box": [54, 148, 32, 55]
   }
  },
  {
   "line": 182,
   "old": "box casa_grande [60,17,166,90]",
   "to": {
    "thing": "casa_grande",
    "box": [67, 16, 133, 132]
   }
  },
  {
   "line": 183,
   "old": "box nube [x, 0, 98, 22]",
   "to": "sky: unchanged"
  },
  {
   "line": 184,
   "old": "box casa [60,17,166,90]",
   "to": {
    "thing": "casa",
    "box": [67, 16, 133, 132]
   }
  },
  {
   "line": 184,
   "old": "box puerta [151,51,30,54]",
   "to": {
    "thing": "puerta",
    "box": [128, 60, 35, 83]
   }
  },
  {
   "line": 184,
   "old": "box ventana [93,57,38,28]",
   "to": {
    "thing": "ventana",
    "box": [83, 46, 38, 53]
   }
  },
  {
   "line": 187,
   "old": "hit palma_pequena [172,112,46,60]",
   "to": {
    "thing": "palma_pequena",
    "hit": [151, 155, 49, 55]
   }
  },
  {
   "line": 187,
   "old": "hit casa_pequena [58,108,30,62]",
   "to": {
    "thing": "casa_pequena",
    "hit": [51, 148, 36, 56]
   }
  },
  {
   "line": 187,
   "old": "hit palma_grande [34,34,48,74]",
   "to": {
    "thing": "palma_grande",
    "hit": [9, 53, 58, 90]
   }
  },
  {
   "line": 188,
   "old": "hit casa_grande [57,16,171,95]",
   "to": {
    "thing": "casa_grande",
    "hit": [67, -2, 133, 150]
   }
  },
  {
   "line": 189,
   "old": "hit pajaro |x - p[0]| < 16, p[1]-24 < y < p[1]+5",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 190,
   "old": "hit bizcocho: display sx < 66, sy < 36 (with the old zoom)",
   "to": "display: x - cam[0] < 66 and y - cam[1] < 36 (no zoom)"
  },
  {
   "line": 192,
   "old": "hit nube [x-2, 0, 102, 24]",
   "to": "sky: unchanged"
  },
  {
   "line": 193,
   "old": "hit puerta [145,46,42,62]",
   "to": {
    "thing": "puerta",
    "hit": [128, 58, 35, 85]
   }
  },
  {
   "line": 194,
   "old": "hit ventana [82,53,61,42]",
   "to": {
    "thing": "ventana",
    "hit": [68, 39, 61, 75]
   }
  },
  {
   "line": 195,
   "old": "hit casa roof: 16 <= y < 42, 88-30t <= x <= 196+30t",
   "to": {
    "thing": "casa",
    "hit": [67, -2, 133, 150]
   },
   "note": "one box replaces both casa tests"
  },
  {
   "line": 196,
   "old": "hit casa [57,41,171,70]",
   "to": {
    "thing": "casa",
    "hit": [67, -2, 133, 150]
   }
  },
  {
   "line": 197,
   "old": "hit sol: (x-210)^2 + (y-17)^2 < 144",
   "to": {
    "thing": "sol",
    "circle": [215, 17, 12]
   }
  },
  {
   "line": 198,
   "old": "hit palma [34,36,30,70]",
   "to": {
    "thing": "palma",
    "hit": [9, 53, 58, 90]
   }
  },
  {
   "line": 205,
   "old": "LUGAR.puerta [150,104,0.72]",
   "to": {
    "spot": "puerta",
    "frog": [114, 109],
    "scale": 0.72
   }
  },
  {
   "line": 205,
   "old": "LUGAR.ventana [96,104,0.72]",
   "to": {
    "spot": "ventana",
    "frog": [70, 106],
    "scale": 0.72
   }
  },
  {
   "line": 205,
   "old": "LUGAR.patio [123,150,0.86]",
   "to": {
    "spot": "patio",
    "frog": [103, 145],
    "scale": 0.86
   }
  },
  {
   "line": 205,
   "old": "LUGAR.casa_grande [150,104,0.72]",
   "to": {
    "spot": "puerta",
    "frog": [114, 109],
    "scale": 0.72
   }
  },
  {
   "line": 205,
   "old": "LUGAR.palma_grande [38,100,0.74]",
   "to": {
    "spot": "palma_grande",
    "frog": [24, 120],
    "scale": 0.74
   }
  },
  {
   "line": 205,
   "old": "LUGAR.palma_pequena [150,150,0.88]",
   "to": {
    "spot": "palma_pequena",
    "frog": [135, 182],
    "scale": 0.88
   }
  },
  {
   "line": 205,
   "old": "LUGAR.casa_pequena [86,150,0.86]",
   "to": {
    "spot": "casa_pequena",
    "frog": [66, 178],
    "scale": 0.86
   }
  },
  {
   "line": 205,
   "old": "NX [22,76,140]",
   "to": "sky: unchanged"
  },
  {
   "line": 207,
   "old": "ir: hops = round(distance / 28)",
   "to": "screen distance: unchanged"
  },
  {
   "line": 209,
   "old": "tocar: the knock at the middle of box(o.en)",
   "to": "from things[o.en].box: unchanged"
  },
  {
   "line": 210,
   "old": "luz stars [92,54],[132,56],[112,50]",
   "to": {
    "frame": "ventana",
    "offset": [-10, 1],
    "new": [82, 55]
   },
   "note": "each of the three + the same offset: [[82,55],[122,57],[102,51]]"
  },
  {
   "line": 210,
   "old": "luz stars [150,47],[182,49],[166,43]",
   "to": {
    "frame": "puerta",
    "offset": [-21, 23],
    "new": [129, 70]
   },
   "note": "each of the three + the same offset: [[129,70],[161,72],[145,66]]"
  },
  {
   "line": 220,
   "old": "hopTo(150, 80, 2, .72)",
   "to": {
    "spot": "puerta.dentro",
    "frog": [134, 103],
    "scale": 0.72
   }
  },
  {
   "line": 220,
   "old": "q.y -= 2 (five times)",
   "to": "relative: unchanged"
  },
  {
   "line": 222,
   "old": "jump to q.x 98, q.y 58, s .72 -> .46, dy -12",
   "to": {
    "spot": "ventana.dentro",
    "frog": [87, 61],
    "scale": 0.46
   },
   "note": "the .72 is where he starts (LUGAR.ventana)"
  },
  {
   "line": 225,
   "old": "nube {x: -100, tx: NX[0]}",
   "to": "sky: unchanged"
  },
  {
   "line": 226,
   "old": "atras: LUGAR.patio",
   "to": {
    "spot": "patio"
   }
  },
  {
   "line": 227,
   "old": "nube2 {x: -100, tx: 44}, nube3 {x: 250, tx: 176}",
   "to": "sky: unchanged"
  },
  {
   "line": 244,
   "old": "pajaro: from (-12, 40) to (150+56, 22)",
   "to": "sky: unchanged"
  },
  {
   "line": 245,
   "old": "bonk: to HOLE",
   "to": "HOLE: see line 77"
  },
  {
   "line": 246,
   "old": "bonk: knock at h[0], h[1]-4; then h[0]-dir*6, h[1]+10; then (150, 26)",
   "to": "relative to HOLE; (150, 26) is sky: unchanged"
  },
  {
   "line": 247,
   "old": "posa: PERCH",
   "to": "PERCH: see line 77"
  },
  {
   "line": 248,
   "old": "come: W.trozo from HOLE",
   "to": "HOLE: see line 77"
  },
  {
   "line": 249,
   "old": "come: to the frog; stars at b.x+b.w/2 -+ 8; the slice shrinks k = 1, 0.7, 0.4 (not a place)",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 250,
   "old": "regala: HOLE",
   "to": "HOLE: see line 77"
  },
  {
   "line": 251,
   "old": "regala: h[1]-6; to the frog",
   "to": "relative: unchanged"
  },
  {
   "line": 253,
   "old": "fin2: aveA(196, 30)",
   "to": {
    "point": "ave.techo",
    "new": [173.15, 51.4]
   }
  },
  {
   "line": 255,
   "old": "fin2: stars at cam + ...",
   "to": "relative to the view (cam): unchanged"
  },
  {
   "line": 258,
   "old": "tapa: from (-10, 60)",
   "to": "off the left edge: unchanged"
  },
  {
   "line": 259,
   "old": "tapa: away to (250, -20)",
   "to": "off the picture: unchanged"
  },
  {
   "line": 263,
   "old": "mira: SPOT[k]",
   "to": "SPOT: see line 88"
  },
  {
   "line": 264,
   "old": "sale: SPOT[k]",
   "to": "SPOT: see line 88"
  },
  {
   "line": 267,
   "old": "tapate: from (250, 60) to (196, 120)",
   "to": {
    "point": "ave.cesped",
    "new": [178.67, 166.88]
   },
   "note": "(250, 60) is off the right edge: unchanged"
  },
  {
   "line": 269,
   "old": "esconde casa_grande: hopTo(150, 82, 1, .6)",
   "to": {
    "spot": "puerta.escondido",
    "frog": [136, 100],
    "scale": 0.6
   }
  },
  {
   "line": 270,
   "old": "esconde casa_pequena: half way to (58, 104), four times",
   "to": {
    "spot": "casa_pequena.dentro",
    "frog": [49, 149]
   }
  },
  {
   "line": 272,
   "old": "busca_ave: SPOT[s]",
   "to": "SPOT: see line 88"
  },
  {
   "line": 273,
   "old": "busca_ave: [176, 100] (casa_grande)",
   "to": {
    "point": "ave.puerta.lado",
    "new": [157.53, 142.6]
   }
  },
  {
   "line": 273,
   "old": "busca_ave: [73, 112] (casa_pequena)",
   "to": {
    "point": "ave.casita.techo",
    "new": [70.02, 152.78]
   }
  },
  {
   "line": 275,
   "old": "busca_ave: knock at pa[0], pa[1]-30; ir patio",
   "to": "relative to the bird; patio: line 205"
  },
  {
   "line": 277,
   "old": "devuelve: from (250, 30); to b.x+b.w+8, b.y+6",
   "to": "sky / relative to the frog: unchanged"
  },
  {
   "line": 279,
   "old": "avecasa: from (200, 40)",
   "to": "sky: unchanged"
  },
  {
   "line": 279,
   "old": "avecasa: to (73, 126)",
   "to": {
    "point": "ave.casita.entra",
    "new": [65.42, 167.46]
   }
  },
  {
   "line": 281,
   "old": "marcador stars [60,20],[180,24],[120,12],[100,30],[150,30]",
   "to": "sky: unchanged"
  },
  {
   "line": 282,
   "old": "vetecq: q.x+38, q.y+4",
   "to": "relative: unchanged"
  },
  {
   "line": 284,
   "old": "fin: stars at cam + ...",
   "to": "relative to the view (cam): unchanged"
  },
  {
   "line": 290,
   "old": "roba: to HOLE",
   "to": "HOLE: see line 77"
  },
  {
   "line": 291,
   "old": "roba: out to (h[0]+30, 24)",
   "to": "x relative to HOLE; y 24 is sky: unchanged"
  },
  {
   "line": 296,
   "old": "stake: NX[...]",
   "to": "sky: unchanged"
  },
  {
   "line": 299,
   "old": "CAM.wide [44,0,196,216]",
   "to": {
    "view": "wide",
    "zoom": 1,
    "x0": 29
   }
  },
  {
   "line": 299,
   "old": "CAM.casa [51.7,15,180.6,199]",
   "to": {
    "view": "casa",
    "zoom": 1,
    "x0": 29
   }
  },
  {
   "line": 299,
   "old": "CAM.puerta [117,30,98,108]",
   "to": {
    "view": "puerta",
    "zoom": 2,
    "x0": 91,
    "region": [91, 40, 98, 108]
   }
  },
  {
   "line": 299,
   "old": "CAM.ventana [84,24,98,108]",
   "to": {
    "view": "ventana",
    "zoom": 2,
    "x0": 48,
    "region": [48, 38, 98, 108]
   }
  },
  {
   "line": 299,
   "old": "CAM.cuadro [63,18,98,108]",
   "to": {
    "view": "cuadro",
    "zoom": 2,
    "x0": 53,
    "region": [53, 1, 98, 108]
   }
  },
  {
   "line": 300,
   "old": "handAt.casa [141,24]",
   "to": {
    "point": "mano.casa",
    "new": [136, 45]
   }
  },
  {
   "line": 300,
   "old": "handAt.puerta [166,76]",
   "to": {
    "point": "mano.puerta",
    "new": [145, 101]
   }
  },
  {
   "line": 300,
   "old": "handAt.ventana [112,72]",
   "to": {
    "point": "mano.ventana",
    "new": [102, 72]
   }
  },
  {
   "line": 300,
   "old": "handAt.casa_grande [141,24]",
   "to": {
    "point": "mano.casa",
    "new": [136, 45]
   }
  },
  {
   "line": 300,
   "old": "handAt.casa_pequena [73,128]",
   "to": {
    "point": "mano.casa_pequena",
    "new": [70, 166]
   }
  },
  {
   "line": 300,
   "old": "handAt.palma_grande [56,60]",
   "to": {
    "point": "mano.palma_grande",
    "new": [36, 65]
   }
  },
  {
   "line": 300,
   "old": "handAt.palma_pequena [195,140]",
   "to": {
    "point": "mano.palma_pequena",
    "new": [176, 166]
   }
  },
  {
   "line": 300,
   "old": "handAt.abuela fallback [166,76]",
   "to": {
    "point": "mano.puerta",
    "new": [145, 101]
   }
  },
  {
   "line": 300,
   "old": "heartAt [103,26]",
   "to": {
    "point": "corazon",
    "new": [93, 27]
   }
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": {
    "spot": "inicio",
    "frog": [103, 168],
    "scale": 1
   },
   "note": "not in frente.js: the host's default frog, for El frente"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": {
    "spot": "patio",
    "frog": [103, 145],
    "scale": 0.86
   },
   "note": "not in frente.js: the frog of a pair picture"
  }
 ]
}
''',
  'balcon': r'''{
 "scene": "balcon",
 "made": "node docs/proyecto/pixel/balcon-sheet-make.js, from balcon-set.html (window.BALCON) and coqui/ref/escenas/balcon/. Order 30a.",
 "S": 26,
 "origin": {
  "originX": 38,
  "originY": 20
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "frog": "a spot is the ground (or seat, or step) under his feet: q.x = round(sx) - 16, q.y = round(sy) - 25; q.s = the spot's scale",
  "abuela": "standing: a spot is the ground under her feet: ab.x = round(sx), ab.y = round(sy) + 1 (balcon.js:123 draws her at ab.x - 30, ab.y - 50). Sitting: points.ABS.screen is the sprite's top left",
  "table": "a glass or jug on the table stands with its bottom on MESA_Y at the x of a mesa.* point (all on one row, a little in front of the table's middle, each base inside the top)",
  "relative": "what the old code draws relative to a character, a glass, ABS or the frog (offsets like ABS[0]+31, v.x+lado*19, b.x+b.w+1) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the red flash (W.rojo), the bird coming in from SW+12, 30, the stars of marcador and fin",
  "view": "a view has a zoom; here all three are zoom 1: the 196 x 216 window with x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction",
  "viewChange": "between two zoom 1 views the window slides (camGo, whole pixels)",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window [clamp(round(sx - 98), 0, 44), clamp(round(sy - 52), 0, 112)]; zoom 2 = the 98 x 52 region [clamp(round(sx - 49), 0, 142), clamp(round(sy - 26), 0, 164)] shown nearest-neighbour at 2 x 2 in the 196 x 104 picture. crop is given. The old rectangles (remap cam and crop) say which pictures they were",
  "walk": "abCamina walks abuela in a straight screen line between her spots, as before, now between the new spots"
 },
 "roof": {
  "what": "the roof is round 2's roof b, chosen by the orchestrator (round 1's roof a and ?roof=a are gone): a short hip roof over the back of the porch, the house 0.4 deep, no posts. Round 3: its eaves are at HF 4.95, so the wall shows to 3.9 over the window's top: a strip of wall over the door and the window (round 4: the bird is on the flower box again; the eaves stay)",
  "HF": 4.95
 },
 "setKey": {
  "params": {
   "door": {
    "values": ["shut", "open"],
    "fromW": "W.door: 0 shut, 1 open"
   },
   "win": {
    "values": ["shut", "open"],
    "fromW": "W.win: 0 shut, 1 open (every story and pair keeps it shut; the old bg() draws both)"
   }
  },
  "key": "door + win, e.g. \"shut-shut\"",
  "baked": [
   {
    "query": "?door=shut&win=shut",
    "reached": "que-calor, the pairs, every story's start"
   },
   {
    "query": "?door=open&win=shut",
    "reached": "el-jugo, d-agua-pajaro, h-balcon"
   },
   {
    "query": "?door=shut&win=open",
    "reached": "no story: the old bg(door, win) can draw it"
   },
   {
    "query": "?door=open&win=open",
    "reached": "no story"
   }
  ],
  "bakedWhy": "the old background sprite key was \"bal\" + door + \"_\" + win; the stories reach bal0_0 and bal1_0 only. The furniture never moves, so it is in the set; what stands on it (glasses, jugs, the fan, the bird) is in the sprite layer",
  "notRead": "every other key of W: the glasses, jugs and fan halves (W.vasos, W.jarras, W.fanMesa, W.enSuelo, W.fanMedio) are drawn by the sprite layer, so they make no new set (order 06 counted 50 states with them)"
 },
 "things": {
  "jugo": {
   "sprite": true,
   "prop": true,
   "why": "the glass (or jug) of juice. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "table": ["mesa.izq", "mesa.der", "mesa.centro"]
   }
  },
  "agua": {
   "sprite": true,
   "prop": true,
   "why": "the glass (or jug) of water. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "table": ["mesa.izq", "mesa.der", "mesa.centro"]
   }
  },
  "vaso_silla": {
   "sprite": true,
   "prop": true,
   "why": "the glass on the small chair. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "seat": "ASIENTO",
    "box": [169, 112, 17, 22]
   }
  },
  "vaso_mesa": {
   "sprite": true,
   "prop": true,
   "why": "the glass on the table. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "table": "mesa.centro",
    "box": [126, 97, 17, 22]
   }
  },
  "vaso_grande": {
   "sprite": true,
   "prop": true,
   "why": "the big glass. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "table": ["mesa.izq", "mesa.der"]
   }
  },
  "vaso_pequeno": {
   "sprite": true,
   "prop": true,
   "why": "the small glass. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged",
   "where": {
    "table": ["mesa.izq", "mesa.der"]
   }
  },
  "abuela": {
   "sprite": true,
   "why": "a character (today's sprite, drawn 1:1). abCaja (balcon.js:102): in her chair ABS + [4, 0, 34, 50]; standing [ab.x - 13, ab.y - 50, 26, 50]: relative, unchanged",
   "box": {
    "silla": {
     "old": [55, 96, 34, 50],
     "new": [60, 51, 34, 50]
    }
   }
  },
  "mesa": {
   "set": true,
   "world": [-1.6758, -0.316, 0, -0.3323, 1.0275, 0.4868],
   "box": [108, 98, 50, 37],
   "hit": {
    "world": [-1.6758, -0.316, 0, -0.3323, 1.0275, 0.4868],
    "box": [108, 98, 50, 37]
   },
   "what": "the round table, foot to top (round: the box is its screen box, as a square world box, as the turned chairs)",
   "old": {
    "box": [94, 124, 52, 25]
   }
  },
  "silla_pequena": {
   "set": true,
   "world": [0.8525, -0.1575, 0, 1.4747, 0.4647, 0.8583],
   "box": [165, 115, 24, 31],
   "hit": {
    "world": [0.8525, -0.1575, 0, 1.4747, 0.4647, 0.8583],
    "box": [165, 115, 24, 31]
   },
   "what": "the small yellow chair (turned to the camera: the box is the screen box of its 8 corners, as a square world box)",
   "turned": {
    "centre": [1.63, 0.62],
    "halfWidth": 0.44,
    "halfDepth": 0.3,
    "height": 1.32,
    "angle": -0.7854
   },
   "old": {
    "box": [148, 120, 24, 30]
   }
  },
  "silla_grande": {
   "set": true,
   "world": [-4.5604, -0.0804, 0, -3.5139, 0.9661, 1.2429],
   "box": [56, 57, 39, 48],
   "hit": {
    "world": [-4.5604, -0.0804, 0, -3.5139, 0.9661, 1.2429],
    "box": [56, 57, 39, 48]
   },
   "what": "abuela's big chair (turned to the camera, as silla_pequena)",
   "turned": {
    "centre": [-3.5, 0.98],
    "halfWidth": 0.74,
    "halfDepth": 0.5,
    "height": 1.82,
    "angle": -0.7854
   },
   "old": {
    "box": [48, 102, 40, 48]
   }
  },
  "puerta": {
   "set": true,
   "world": [2.06, -0.06, 0, 3.64, 0.06, 2.99],
   "box": [194, 79, 33, 84],
   "hit": {
    "world": [2.06, -0.06, 0, 3.64, 0.06, 2.99],
    "box": [194, 79, 33, 84]
   },
   "what": "the door with its frame",
   "old": {
    "box": [162, 54, 32, 68],
    "hand": [178, 84]
   },
   "hand": {
    "point": "mano.puerta",
    "new": [210, 112]
   }
  },
  "ventana": {
   "set": true,
   "world": [-2.21, 0, 1.48, -0.11, 0.3, 2.85],
   "box": [111, 43, 45, 54],
   "hit": {
    "world": [-2.21, 0, 1.48, -0.11, 0.3, 2.85],
    "box": [111, 43, 45, 54]
   },
   "what": "the window with its frame, its shutters (open, flat on the wall) and the flower box",
   "old": {
    "box": [93, 54, 54, 36],
    "hand": [120, 70]
   },
   "hand": {
    "point": "mano.ventana",
    "new": [137, 67]
   }
  },
  "balcon": {
   "set": true,
   "world": [-1.5, 2.1, 0, 3.7, 3, 0.3],
   "box": [75, 126, 113, 64],
   "hit": {
    "world": [-1.5, 2.1, 0, 3.7, 3, 0.3],
    "box": [75, 126, 113, 64]
   },
   "what": "the porch floor: its open front strip, before the furniture, from abuela's chair to the door (the whole floor's box would take in the wall and the roof's posts: with this camera the porch is a slanting band, and a box cannot follow it). Last in the hit order, as before",
   "old": {
    "box": [42, 122, 156, 34]
   }
  }
 },
 "spots": {
  "jardin": {
   "world": [3.2364, 4.5962, 0],
   "screen": [133, 200],
   "scale": 1,
   "frog": [117, 175],
   "old": [104, 185],
   "what": "LUGAR.jardin: on the path, near the bottom: where every story starts (fresh)"
  },
  "sube": {
   "world": [2.2573, 3.6171, 0],
   "screen": [133, 182],
   "scale": 0.9,
   "frog": [117, 157],
   "old": [104, 168],
   "what": "acts.sube: hopTo(LUGAR.jardin[0], 168, 1, .9): on the path, at the foot of the steps"
  },
  "balcon": {
   "world": [1.3193, 2.0264, 0.3],
   "screen": [145, 152],
   "scale": 0.8,
   "frog": [129, 127],
   "old": [106, 130],
   "what": "LUGAR.balcon and LUGAR.ventana: on the porch, before the table (in front of its foot)"
  },
  "mesa": {
   "world": [1.4009, 2.5975, 0.3],
   "screen": [136, 158],
   "scale": 0.86,
   "frog": [120, 133],
   "old": [104, 141],
   "what": "LUGAR.mesa and LUGAR.junto: on the porch, before the table, near the steps but well inside the porch (where he takes a glass)"
  },
  "decir": {
   "world": [2.9783, 2.3256, 0.3],
   "screen": [170, 170],
   "scale": 0.8,
   "frog": [154, 145],
   "old": [134, 130],
   "what": "LUGAR.decir: on the porch, out in front of the small chair, clear of it (where he speaks to abuela)"
  },
  "silla_pequena": {
   "world": [1.63, 0.62, 0.75],
   "screen": [176.57, 131.8],
   "scale": 0.72,
   "frog": [161, 107],
   "old": [144, 109],
   "what": "LUGAR.silla_pequena: on the small chair's seat (rana(): sitting there he has no shadow)"
  },
  "suelo": {
   "world": [3.3318, 1.972, 0.3],
   "screen": [183, 170],
   "scale": 0.8,
   "frog": [167, 145],
   "old": [150, 132],
   "what": "LUGAR.suelo: on the porch floor, out in front of the small chair, towards the door, clear of it"
  },
  "abuela": {
   "world": [0.313, 2.5975, 0.3],
   "screen": [116, 148],
   "scale": 0.8,
   "frog": [100, 123],
   "old": [84, 129],
   "what": "LUGAR.abuela and LUGAR.silla_grande: on the porch, out in front of abuela's chair and the table's left side"
  },
  "puerta": {
   "world": [3.359, 0.6394, 0.3],
   "screen": [208, 158],
   "scale": 0.76,
   "frog": [192, 133],
   "old": [162, 125],
   "what": "LUGAR.puerta: on the porch, before the door"
  },
  "abuela.puerta": {
   "world": [2.85, 0.1, 0.3],
   "screen": [208.56, 148.36],
   "ab": [209, 149],
   "old": [178, 125],
   "what": "AB.puerta: in the doorway (drawn clipped to clips[puerta.hueco])"
  },
  "abuela.mesa": {
   "world": [-0.938, 2.4344, 0.3],
   "screen": [96, 135],
   "ab": [96, 136],
   "old": [98, 143],
   "what": "AB.mesa: on clear floor at the table's left, in front of it and of her chair: nothing of the table or a chair is nearer than her, her box ends left of the drinks; her tray (on her left, as the old one) over the floor before her chair"
  },
  "abuela.lado": {
   "world": [-1.5091, 1.9176, 0.3],
   "screen": [95, 125],
   "ab": [95, 126],
   "old": [94, 147],
   "what": "AB.lado: beside her big chair, on clear floor before its right arm and left of the table: where she stands up from it and sits down in it"
  },
  "abuela.camina": {
   "world": [-1.1556, 2.3256, 0.3],
   "screen": [94, 132],
   "ab": [94, 133],
   "old": [106, 148],
   "what": "pair se sienta.no: abuela standing on clear floor beside her chair (ab en camina at 106, 148)"
  }
 },
 "lugar": {
  "jardin": {
   "spot": "jardin",
   "q": [117, 175],
   "scale": 1,
   "old": [104, 185, 1]
  },
  "balcon": {
   "spot": "balcon",
   "q": [129, 127],
   "scale": 0.8,
   "old": [106, 130, 0.8]
  },
  "mesa": {
   "spot": "mesa",
   "q": [120, 133],
   "scale": 0.86,
   "old": [104, 141, 0.86]
  },
  "junto": {
   "spot": "mesa",
   "q": [120, 133],
   "scale": 0.86,
   "old": [104, 141, 0.86]
  },
  "decir": {
   "spot": "decir",
   "q": [154, 145],
   "scale": 0.8,
   "old": [134, 130, 0.8]
  },
  "silla_pequena": {
   "spot": "silla_pequena",
   "q": [161, 107],
   "scale": 0.72,
   "old": [144, 109, 0.72]
  },
  "suelo": {
   "spot": "suelo",
   "q": [167, 145],
   "scale": 0.8,
   "old": [150, 132, 0.8]
  },
  "abuela": {
   "spot": "abuela",
   "q": [100, 123],
   "scale": 0.8,
   "old": [84, 129, 0.8]
  },
  "silla_grande": {
   "spot": "abuela",
   "q": [100, 123],
   "scale": 0.8,
   "old": [84, 129, 0.8]
  },
  "puerta": {
   "spot": "puerta",
   "q": [192, 133],
   "scale": 0.76,
   "old": [162, 125, 0.76]
  },
  "ventana": {
   "spot": "balcon",
   "q": [129, 127],
   "scale": 0.8,
   "old": [106, 130, 0.8]
  }
 },
 "hops": [
  {
   "a": "jardin",
   "b": "balcon",
   "old": 2,
   "new": 2,
   "dOld": 55.04,
   "dNew": 49.48
  },
  {
   "a": "jardin",
   "b": "mesa",
   "old": 1,
   "new": 1,
   "dOld": 44,
   "dNew": 42.11
  },
  {
   "a": "jardin",
   "b": "junto",
   "old": 1,
   "new": 1,
   "dOld": 44,
   "dNew": 42.11
  },
  {
   "a": "jardin",
   "b": "decir",
   "old": 2,
   "new": 2,
   "dOld": 62.65,
   "dNew": 47.63
  },
  {
   "a": "jardin",
   "b": "silla_pequena",
   "old": 3,
   "new": 3,
   "dOld": 85.88,
   "dNew": 80.99
  },
  {
   "a": "jardin",
   "b": "suelo",
   "old": 2,
   "new": 2,
   "dOld": 70.18,
   "dNew": 58.31
  },
  {
   "a": "jardin",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 59.46,
   "dNew": 54.71
  },
  {
   "a": "jardin",
   "b": "silla_grande",
   "old": 2,
   "new": 2,
   "dOld": 59.46,
   "dNew": 54.71
  },
  {
   "a": "jardin",
   "b": "puerta",
   "old": 3,
   "new": 3,
   "dOld": 83.45,
   "dNew": 85.96
  },
  {
   "a": "jardin",
   "b": "ventana",
   "old": 2,
   "new": 2,
   "dOld": 55.04,
   "dNew": 49.48
  },
  {
   "a": "balcon",
   "b": "mesa",
   "old": 1,
   "new": 1,
   "dOld": 11.18,
   "dNew": 10.82
  },
  {
   "a": "balcon",
   "b": "junto",
   "old": 1,
   "new": 1,
   "dOld": 11.18,
   "dNew": 10.82
  },
  {
   "a": "balcon",
   "b": "decir",
   "old": 1,
   "new": 1,
   "dOld": 28,
   "dNew": 30.81
  },
  {
   "a": "balcon",
   "b": "silla_pequena",
   "old": 1,
   "new": 1,
   "dOld": 43.42,
   "dNew": 37.74
  },
  {
   "a": "balcon",
   "b": "suelo",
   "old": 1,
   "new": 1,
   "dOld": 44.05,
   "dNew": 42.05
  },
  {
   "a": "balcon",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 22.02,
   "dNew": 29.27
  },
  {
   "a": "balcon",
   "b": "silla_grande",
   "old": 1,
   "new": 1,
   "dOld": 22.02,
   "dNew": 29.27
  },
  {
   "a": "balcon",
   "b": "puerta",
   "old": 2,
   "new": 2,
   "dOld": 56.22,
   "dNew": 63.29
  },
  {
   "a": "balcon",
   "b": "ventana",
   "old": 0,
   "new": 0,
   "dOld": 0,
   "dNew": 0
  },
  {
   "a": "mesa",
   "b": "junto",
   "old": 0,
   "new": 0,
   "dOld": 0,
   "dNew": 0
  },
  {
   "a": "mesa",
   "b": "decir",
   "old": 1,
   "new": 1,
   "dOld": 31.95,
   "dNew": 36.06
  },
  {
   "a": "mesa",
   "b": "silla_pequena",
   "old": 2,
   "new": 2,
   "dOld": 51.22,
   "dNew": 48.55
  },
  {
   "a": "mesa",
   "b": "suelo",
   "old": 2,
   "new": 2,
   "dOld": 46.87,
   "dNew": 48.51
  },
  {
   "a": "mesa",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 23.32,
   "dNew": 22.36
  },
  {
   "a": "mesa",
   "b": "silla_grande",
   "old": 1,
   "new": 1,
   "dOld": 23.32,
   "dNew": 22.36
  },
  {
   "a": "mesa",
   "b": "puerta",
   "old": 2,
   "new": 2,
   "dOld": 60.17,
   "dNew": 72
  },
  {
   "a": "mesa",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 11.18,
   "dNew": 10.82
  },
  {
   "a": "junto",
   "b": "decir",
   "old": 1,
   "new": 1,
   "dOld": 31.95,
   "dNew": 36.06
  },
  {
   "a": "junto",
   "b": "silla_pequena",
   "old": 2,
   "new": 2,
   "dOld": 51.22,
   "dNew": 48.55
  },
  {
   "a": "junto",
   "b": "suelo",
   "old": 2,
   "new": 2,
   "dOld": 46.87,
   "dNew": 48.51
  },
  {
   "a": "junto",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 23.32,
   "dNew": 22.36
  },
  {
   "a": "junto",
   "b": "silla_grande",
   "old": 1,
   "new": 1,
   "dOld": 23.32,
   "dNew": 22.36
  },
  {
   "a": "junto",
   "b": "puerta",
   "old": 2,
   "new": 2,
   "dOld": 60.17,
   "dNew": 72
  },
  {
   "a": "junto",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 11.18,
   "dNew": 10.82
  },
  {
   "a": "decir",
   "b": "silla_pequena",
   "old": 1,
   "new": 1,
   "dOld": 23.26,
   "dNew": 38.64
  },
  {
   "a": "decir",
   "b": "suelo",
   "old": 1,
   "new": 1,
   "dOld": 16.12,
   "dNew": 13
  },
  {
   "a": "decir",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 50.01,
   "dNew": 58.31
  },
  {
   "a": "decir",
   "b": "silla_grande",
   "old": 2,
   "new": 2,
   "dOld": 50.01,
   "dNew": 58.31
  },
  {
   "a": "decir",
   "b": "puerta",
   "old": 1,
   "new": 1,
   "dOld": 28.44,
   "dNew": 39.85
  },
  {
   "a": "decir",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 28,
   "dNew": 30.81
  },
  {
   "a": "silla_pequena",
   "b": "suelo",
   "old": 1,
   "new": 1,
   "dOld": 23.77,
   "dNew": 38.47
  },
  {
   "a": "silla_pequena",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 63.25,
   "dNew": 63.06
  },
  {
   "a": "silla_pequena",
   "b": "silla_grande",
   "old": 2,
   "new": 2,
   "dOld": 63.25,
   "dNew": 63.06
  },
  {
   "a": "silla_pequena",
   "b": "puerta",
   "old": 1,
   "new": 1,
   "dOld": 24.08,
   "dNew": 40.46
  },
  {
   "a": "silla_pequena",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 43.42,
   "dNew": 37.74
  },
  {
   "a": "suelo",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 66.07,
   "dNew": 70.52
  },
  {
   "a": "suelo",
   "b": "silla_grande",
   "old": 2,
   "new": 2,
   "dOld": 66.07,
   "dNew": 70.52
  },
  {
   "a": "suelo",
   "b": "puerta",
   "old": 1,
   "new": 1,
   "dOld": 13.89,
   "dNew": 27.73
  },
  {
   "a": "suelo",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 44.05,
   "dNew": 42.05
  },
  {
   "a": "abuela",
   "b": "silla_grande",
   "old": 0,
   "new": 0,
   "dOld": 0,
   "dNew": 0
  },
  {
   "a": "abuela",
   "b": "puerta",
   "old": 3,
   "new": 3,
   "dOld": 78.1,
   "dNew": 92.54
  },
  {
   "a": "abuela",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 22.02,
   "dNew": 29.27
  },
  {
   "a": "silla_grande",
   "b": "puerta",
   "old": 3,
   "new": 3,
   "dOld": 78.1,
   "dNew": 92.54
  },
  {
   "a": "silla_grande",
   "b": "ventana",
   "old": 1,
   "new": 1,
   "dOld": 22.02,
   "dNew": 29.27
  },
  {
   "a": "puerta",
   "b": "ventana",
   "old": 2,
   "new": 2,
   "dOld": 56.22,
   "dNew": 63.29
  }
 ],
 "points": {
  "ABS": {
   "world": [-3.5, 0.98, 0.8],
   "old": [51, 96],
   "screen": [56, 51],
   "what": "ABS: abuela sitting in her big chair (the sprite's top left: her middle, sprite x 17, 3 px left of the chair's middle so her feet stay before it and off the table; her lap, row 36, on its seat). Everything drawn with her (the fan, her glass, the jug over her head, sweat, the splash and its puddle, her bubble) is relative to it: unchanged"
  },
  "talk.lado": {
   "world": [-3.5, 0.98, 0.8],
   "old": [68, 95],
   "screen": [97, 70],
   "what": "TALK_LADO: the tail of her bubble while she sits and the score boards are up (talkAt with W.rondas): beside her head, on its right, under the boards (old: over her head, ABS + (17, -1), as when no boards are up)"
  },
  "mesa.izq": {
   "world": [-0.4232, 1.6983, 1.05],
   "old": [108, 128],
   "what": "X2[0]: the left place on the table top",
   "screen": [119, 116.08]
  },
  "mesa.der": {
   "world": [0.3383, 0.9368, 1.05],
   "old": [132, 128],
   "what": "X2[1]: the right place on the table top (also acts.recibe x 132)",
   "screen": [147, 116.08]
  },
  "mesa.centro": {
   "world": [-0.0152, 1.2904, 1.05],
   "old": [120, 128],
   "what": "the middle of the drinks' row, between the two X2 places (dos(\"sm\") vaso_mesa x 120, acts.aparta x 120: the glass she puts down stands between the two jugs, touching neither; the pairs' glass or jug at 120; acts.aveva's test v.x < 120)",
   "screen": [134, 116.08]
  },
  "mesa.toma": {
   "world": [-0.4232, 1.6983, 1.05],
   "old": [106, 128],
   "what": "pair toma.si: the glass at x 106",
   "screen": [119, 116.08]
  },
  "ave.mesa.toma": {
   "world": [0.1479, 1.1272, 1.05],
   "old": [127, 128],
   "what": "pair toma.si: the bird on the table, drinking from the glass at 106 (x 127)",
   "screen": [140, 116.08]
  },
  "ave.mesa.der": {
   "world": [0.2839, 0.9912, 1.05],
   "old": [132, 128],
   "what": "pair toma.no: the bird asleep on the table at 132",
   "screen": [145, 116.08]
  },
  "mesa.abanico": {
   "world": [0.1437, 1.9931, 1.05],
   "old": [121, 128],
   "what": "W.fanMesa: medio(c, 121, MESA_Y, 1): her half fan left on the table: at its front, its pivot on the rim, between the left jug and the middle, in front of the drinks and clear of them",
   "screen": [124, 124]
  },
  "ASIENTO": {
   "world": [1.63, 0.62, 0.75],
   "old": [160, 135],
   "what": "ASIENTO: the small chair's seat: vaso_silla stands on it (its bottom at y - 1), the bird sits on it (avesilla, marcador)",
   "screen": [176.57, 131.8]
  },
  "PERCH": {
   "world": [-1.16, 0.3, 1.7],
   "old": [120, 86],
   "what": "PERCH: the bird at the window (aveventana; the pairs gracias): on the window's flower box, in the middle: its feet on the box's top front edge (bare soil behind them, the flowers at both ends), its body in front of the shutters, as the old picture; clear of abuela, her glass and every drink",
   "screen": [131.16, 81.82]
  },
  "suelo.abanico.1": {
   "world": [-2.0259, 1.3465, 0.3],
   "old": [98, 157],
   "what": "W.enSuelo: medio(c, 98, 157, -1): one half of her fan on the floor before her chair",
   "screen": [96, 115]
  },
  "suelo.abanico.2": {
   "world": [-1.5907, 1.1289, 0.3],
   "old": [110, 158],
   "what": "W.enSuelo: medio(c, 110, 158, 1): the other half",
   "screen": [108, 117]
  },
  "corazon": {
   "world": [-2.1757, 0, 3.3753],
   "old": [107, 31],
   "what": "heartAt: the heart of a happy ending (its top left, 27 x 24 px): over the bird on the window's flower box, clear of it (PERCH), in the middle of the wide view",
   "screen": [118, 32]
  },
  "mano.puerta": {
   "world": [2.85, 0, 1.881],
   "old": [178, 84],
   "what": "cosas puerta hand: on the door, high (above abuela's face when she stands in it? no: see checks.hands)",
   "screen": [210.4, 111.84]
  },
  "mano.ventana": {
   "world": [-1.16, 0, 2.225],
   "old": [120, 70],
   "what": "cosas ventana hand: the middle of the window",
   "screen": [136.67, 67.24]
  }
 },
 "MESA_Y": {
  "old": 128,
  "new": 116,
  "what": "MESA_Y: the row the glasses and jugs stand on (their bottom): DROW px in front of the table top's middle"
 },
 "behind": {
  "old": 144,
  "new": 126,
  "what": "balcon.js:126 and :141: ab.y < this is drawn at :126 (behind the furniture, which covers her where it is nearer: front), ab.y >= this at :141 (after the furniture and the drinks). Round 3: every place she stands is at or past it (AB.mesa 136, AB.lado 126, camina 133, the door 149): standing, she is on clear floor and drawn over everything but the frog, the bird and the signs; walking between two places she may pass above this row, as the old"
 },
 "views": {
  "wide": {
   "world": [-0.0677, 1.0201, 0.3],
   "screen": [138, 130],
   "zoom": 1,
   "x0": 40,
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the porch from abuela's chair to the door, the path and the frog on it: every story's usual view"
  },
  "mesa": {
   "world": [-0.0677, 1.0201, 0.3],
   "screen": [138, 130],
   "zoom": 1,
   "x0": 40,
   "region": null,
   "old": [45, 36, 127, 140],
   "what": "the table (old: a 1.54x close view of the table): the same window as wide here (order 30b: a zoom 1 window centred on the table slid 5 px for nothing; a zoom 2 one would leave abuela and her bubble out)"
  },
  "porche": {
   "world": [-0.0677, 1.0201, 0.3],
   "screen": [138, 130],
   "zoom": 1,
   "x0": 40,
   "region": null,
   "old": [35, 20, 170, 187.3],
   "what": "the porch (old: a 1.15x view; the same window as wide here)"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [14, 52, 186, 98.7],
   "uses": [
    "cual-balcon.json quiero.si.cam",
    "cual-balcon.json quiero.no.cam",
    "cual-balcon.json gracias.si.cam",
    "cual-balcon.json gracias.no.cam",
    "cual-balcon.json ¿cómo estás?.si.cam",
    "cual-balcon.json ¿cómo estás?.no.cam"
   ],
   "to": {
    "pictures": [
     "quiero.si",
     "quiero.no",
     "gracias.si",
     "gracias.no",
     "¿cómo estás?.si",
     "¿cómo estás?.no"
    ]
   },
   "crops": {
    "quiero.si": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    },
    "quiero.no": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    },
    "gracias.si": {
     "crop": [20, 48, 196, 104],
     "zoom": 1
    },
    "gracias.no": {
     "crop": [20, 48, 196, 104],
     "zoom": 1
    },
    "¿cómo estás?.si": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    },
    "¿cómo estás?.no": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    }
   },
   "what": "abuela in her chair"
  },
  {
   "kind": "cam",
   "old": [18, 84, 124, 65.8],
   "uses": ["cual-balcon.json se sienta.si.cam", "cual-balcon.json se sienta.no.cam"],
   "to": {
    "pictures": ["se sienta.si", "se sienta.no"]
   },
   "crops": {
    "se sienta.si": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    },
    "se sienta.no": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    }
   },
   "what": "abuela and her chair"
  },
  {
   "kind": "cam",
   "old": [82, 94, 124, 65.8],
   "uses": ["cual-balcon.json bien.si.cam", "cual-balcon.json bien.no.cam"],
   "to": {
    "pictures": ["bien.si", "bien.no"]
   },
   "crops": {
    "bien.si": {
     "crop": [44, 88, 196, 104],
     "zoom": 1
    },
    "bien.no": {
     "crop": [44, 88, 196, 104],
     "zoom": 1
    }
   },
   "what": "the frog on the porch"
  },
  {
   "kind": "cam",
   "old": [84, 92, 76, 40.3],
   "uses": ["cual-balcon.json toma.si.cam", "cual-balcon.json toma.no.cam"],
   "to": {
    "pictures": ["toma.si", "toma.no"]
   },
   "crops": {
    "toma.si": {
     "crop": [84, 83, 98, 52],
     "zoom": 2
    },
    "toma.no": {
     "crop": [84, 83, 98, 52],
     "zoom": 2
    }
   },
   "what": "the table and the bird"
  },
  {
   "kind": "cam",
   "old": [86, 98, 68, 36.1],
   "uses": ["cual-balcon.json vaso.si.cam", "cual-balcon.json vaso.no.cam", "cual-balcon.json jugo.si.cam", "cual-balcon.json jugo.no.cam", "cual-balcon.json agua.si.cam", "cual-balcon.json agua.no.cam"],
   "to": {
    "pictures": ["vaso.si", "vaso.no", "jugo.si", "jugo.no", "agua.si", "agua.no"]
   },
   "crops": {
    "vaso.si": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "vaso.no": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "jugo.si": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "jugo.no": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "agua.si": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "agua.no": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    }
   },
   "what": "the table top"
  },
  {
   "kind": "cam",
   "old": [86, 116, 68, 36.1],
   "uses": ["cual-balcon.json silla.no.cam"],
   "to": {
    "pictures": ["silla.no"]
   },
   "crops": {
    "silla.no": {
     "crop": [88, 45, 98, 52],
     "zoom": 2
    }
   },
   "what": "the table, no chair"
  },
  {
   "kind": "cam",
   "old": [126, 116, 68, 36.1],
   "uses": ["cual-balcon.json silla.si.cam"],
   "to": {
    "pictures": ["silla.si"]
   },
   "crops": {
    "silla.si": {
     "crop": [132, 102, 98, 52],
     "zoom": 2
    }
   },
   "what": "the small chair"
  },
  {
   "kind": "crop",
   "old": [49.31, 52, 89.39, 98.7],
   "uses": [
    "nivel.js NV quiero.p0",
    "nivel.js NV quiero.p1",
    "nivel.js NV quiero.p2"
   ],
   "to": {
    "pictures": [
     "quiero.si",
     "quiero.no",
     "¿cómo estás?.si"
    ]
   },
   "crops": {
    "quiero.si": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    },
    "quiero.no": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    },
    "¿cómo estás?.si": {
     "crop": [20, 0, 196, 104],
     "zoom": 1
    }
   },
   "what": "level: abuela in her chair"
  },
  {
   "kind": "crop",
   "old": [50.2, 84, 59.59, 65.8],
   "uses": [
    "nivel.js NV hola.p2",
    "nivel.js NV se sienta.p0"
   ],
   "to": {
    "pictures": ["se sienta.si", "se sienta.no"]
   },
   "crops": {
    "se sienta.si": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    },
    "se sienta.no": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    }
   },
   "what": "level: abuela and her chair"
  },
  {
   "kind": "crop",
   "old": [66.2, 84, 59.59, 65.8],
   "uses": [
    "nivel.js NV se sienta.p1"
   ],
   "to": {
    "pictures": ["se sienta.si", "se sienta.no"]
   },
   "crops": {
    "se sienta.si": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    },
    "se sienta.no": {
     "crop": [20, 40, 196, 104],
     "zoom": 1
    }
   },
   "what": "level: abuela and her chair"
  },
  {
   "kind": "crop",
   "old": [103.65, 98, 32.69, 36.1],
   "uses": [
    "nivel.js NV abre.p3",
    "nivel.js NV silla.p2",
    "nivel.js NV jugo.p0",
    "nivel.js NV jugo.p1",
    "nivel.js NV hasta mañana.p2"
   ],
   "to": {
    "pictures": ["jugo.si", "agua.si"]
   },
   "crops": {
    "jugo.si": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    },
    "agua.si": {
     "crop": [84, 86, 98, 52],
     "zoom": 2
    }
   },
   "what": "level: the table top"
  },
  {
   "kind": "crop",
   "old": [103.65, 116, 32.69, 36.1],
   "uses": [
    "nivel.js NV silla.p1"
   ],
   "to": {
    "pictures": ["silla.no"]
   },
   "crops": {
    "silla.no": {
     "crop": [88, 45, 98, 52],
     "zoom": 2
    }
   },
   "what": "level: the table"
  },
  {
   "kind": "crop",
   "old": [143.65, 116, 32.69, 36.1],
   "uses": [
    "nivel.js NV puerta.p2",
    "nivel.js NV silla.p0",
    "nivel.js NV jugo.p2",
    "nivel.js NV flor.p3"
   ],
   "to": {
    "pictures": ["silla.si"]
   },
   "crops": {
    "silla.si": {
     "crop": [132, 102, 98, 52],
     "zoom": 2
    }
   },
   "what": "level: the small chair"
  },
  {
   "kind": "point",
   "old": [84, 129],
   "uses": ["cual-balcon.json gracias.si.set.cq", "cual-balcon.json gracias.no.set.cq"],
   "to": {
    "spot": "abuela"
   },
   "frog": [100, 123],
   "scale": 0.8
  },
  {
   "kind": "point",
   "old": [94, 147],
   "uses": [
    "que-calor.json beats.0.set.ab",
    "cual-balcon.json silla.si.set.ab",
    "cual-balcon.json silla.no.set.ab",
    "cual-balcon.json vaso.si.set.ab",
    "cual-balcon.json vaso.no.set.ab",
    "cual-balcon.json jugo.si.set.ab",
    "cual-balcon.json jugo.no.set.ab",
    "cual-balcon.json agua.si.set.ab",
    "cual-balcon.json agua.no.set.ab",
    "cual-balcon.json se sienta.si.set.ab",
    "cual-balcon.json toma.si.set.ab",
    "cual-balcon.json toma.no.set.ab",
    "cual-balcon.json quiero.si.set.ab",
    "cual-balcon.json quiero.no.set.ab",
    "cual-balcon.json gracias.si.set.ab",
    "cual-balcon.json gracias.no.set.ab",
    "cual-balcon.json ¿cómo estás?.si.set.ab",
    "cual-balcon.json ¿cómo estás?.no.set.ab",
    "cual-balcon.json bien.si.set.ab",
    "cual-balcon.json bien.no.set.ab"
   ],
   "to": {
    "spot": "abuela.lado"
   },
   "ab": [95, 126],
   "what": "set.ab with en silla: drawn at ABS; x, y are where she stands up to (AB.lado)"
  },
  {
   "kind": "point",
   "old": [106, 130],
   "uses": ["cual-balcon.json bien.si.set.cq", "cual-balcon.json bien.no.set.cq"],
   "to": {
    "spot": "balcon"
   },
   "frog": [129, 127],
   "scale": 0.8
  },
  {
   "kind": "point",
   "old": [106, 148],
   "uses": ["cual-balcon.json se sienta.no.set.ab"],
   "to": {
    "spot": "abuela.camina"
   },
   "ab": [94, 133]
  },
  {
   "kind": "point",
   "old": [120, 86],
   "uses": ["cual-balcon.json gracias.si.set.ave", "cual-balcon.json gracias.no.set.ave"],
   "to": {
    "point": "PERCH"
   },
   "screen": [131, 82]
  },
  {
   "kind": "point",
   "old": [127, 128],
   "uses": ["cual-balcon.json toma.si.set.ave"],
   "to": {
    "point": "ave.mesa.toma"
   },
   "screen": [140, 116]
  },
  {
   "kind": "point",
   "old": [132, 128],
   "uses": ["cual-balcon.json toma.no.set.ave"],
   "to": {
    "point": "ave.mesa.der"
   },
   "screen": [145, 116]
  },
  {
   "kind": "x",
   "old": [80],
   "uses": [
    "nivel.js NV hola.p2",
    "nivel.js NV se sienta.p0"
   ],
   "to": {
    "level": true
   },
   "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
  },
  {
   "kind": "x",
   "old": [94],
   "uses": [
    "nivel.js NV quiero.p0",
    "nivel.js NV quiero.p1",
    "nivel.js NV quiero.p2"
   ],
   "to": {
    "level": true
   },
   "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
  },
  {
   "kind": "x",
   "old": [96],
   "uses": [
    "nivel.js NV se sienta.p1"
   ],
   "to": {
    "level": true
   },
   "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
  },
  {
   "kind": "x",
   "old": [106],
   "uses": ["cual-balcon.json toma.si.set.vasos.0"],
   "to": {
    "point": "mesa.toma"
   },
   "screen": [119, 116],
   "x": 119,
   "what": "x on the table top (y is MESA_Y)"
  },
  {
   "kind": "x",
   "old": [108],
   "uses": ["cual-balcon.json toma.no.set.vasos.0"],
   "to": {
    "point": "mesa.izq"
   },
   "screen": [119, 116],
   "x": 119,
   "what": "x on the table top (y is MESA_Y)"
  },
  {
   "kind": "x",
   "old": [120],
   "uses": ["cual-balcon.json vaso.si.set.vasos.0", "cual-balcon.json vaso.no.set.jarras.0", "cual-balcon.json jugo.si.set.vasos.0", "cual-balcon.json jugo.no.set.vasos.0", "cual-balcon.json agua.si.set.jarras.0", "cual-balcon.json agua.no.set.jarras.0"],
   "to": {
    "point": "mesa.centro"
   },
   "screen": [134, 116],
   "x": 134,
   "what": "x on the table top (y is MESA_Y)"
  }
 ],
 "pictures": {
  "silla.si": {
   "world": [0.9633, -0.2643, 0.3],
   "screen": [180.57, 127.67],
   "zoom": 2,
   "crop": [132, 102, 98, 52],
   "what": "the small yellow chair, close: no table in it"
  },
  "silla.no": {
   "world": [-1.1602, 0, 2.0594],
   "screen": [136.67, 70.97],
   "zoom": 2,
   "crop": [88, 45, 98, 52],
   "what": "the window and its flower box, close: no chair in it (round 2: the whole table cannot be framed at zoom 2 without a chair, so the window, whole, is the picture that is not a chair)"
  },
  "vaso.si": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a glass of water on it"
  },
  "vaso.no": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a jug of water on it"
  },
  "jugo.si": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a glass of juice"
  },
  "jugo.no": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a glass of water"
  },
  "agua.si": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a jug of water"
  },
  "agua.no": {
   "world": [-1.1828, 0.177, 0.3],
   "screen": [133, 112],
   "zoom": 2,
   "crop": [84, 86, 98, 52],
   "what": "the table, close: a jug of juice"
  },
  "se sienta.si": {
   "world": [-2.6786, -0.5029, 0.3],
   "screen": [118, 92],
   "zoom": 1,
   "crop": [20, 40, 196, 104],
   "what": "abuela sitting in her big chair, the table beside her"
  },
  "se sienta.no": {
   "world": [-2.6786, -0.5029, 0.3],
   "screen": [118, 92],
   "zoom": 1,
   "crop": [20, 40, 196, 104],
   "what": "abuela standing beside her big chair"
  },
  "toma.si": {
   "world": [-1.346, 0.0139, 0.3],
   "screen": [133, 109],
   "zoom": 2,
   "crop": [84, 83, 98, 52],
   "what": "the table, close: the bird drinking from a glass"
  },
  "toma.no": {
   "world": [-1.346, 0.0139, 0.3],
   "screen": [133, 109],
   "zoom": 2,
   "crop": [84, 83, 98, 52],
   "what": "the table, close: the bird asleep beside a full glass"
  },
  "quiero.si": {
   "world": [-4.8543, -2.6786, 0.3],
   "screen": [118, 52],
   "zoom": 1,
   "crop": [20, 0, 196, 104],
   "what": "abuela in her chair, a bubble: she wants water"
  },
  "quiero.no": {
   "world": [-4.8543, -2.6786, 0.3],
   "screen": [118, 52],
   "zoom": 1,
   "crop": [20, 0, 196, 104],
   "what": "abuela in her chair, drinking, a heart"
  },
  "gracias.si": {
   "world": [-2.2706, -0.0949, 0.3],
   "screen": [118, 99.5],
   "zoom": 1,
   "crop": [20, 48, 196, 104],
   "what": "abuela gives the frog a glass, the frog's heart"
  },
  "gracias.no": {
   "world": [-2.2706, -0.0949, 0.3],
   "screen": [118, 99.5],
   "zoom": 1,
   "crop": [20, 48, 196, 104],
   "what": "abuela without a glass, the frog sad"
  },
  "¿cómo estás?.si": {
   "world": [-4.8543, -2.6786, 0.3],
   "screen": [118, 52],
   "zoom": 1,
   "crop": [20, 0, 196, 104],
   "what": "abuela in her chair asks how he is (ok, ?, sad)"
  },
  "¿cómo estás?.no": {
   "world": [-4.8543, -2.6786, 0.3],
   "screen": [118, 52],
   "zoom": 1,
   "crop": [20, 0, 196, 104],
   "what": "abuela in her chair asks about water"
  },
  "bien.si": {
   "world": [0.6666, 1.3737, 0.3],
   "screen": [145, 140],
   "zoom": 1,
   "crop": [44, 88, 196, 104],
   "what": "the frog on the porch, ok"
  },
  "bien.no": {
   "world": [0.6666, 1.3737, 0.3],
   "screen": [145, 140],
   "zoom": 1,
   "crop": [44, 88, 196, 104],
   "what": "the frog on the porch, hot and sweating"
  }
 },
 "level": [
  {
   "w": "puerta",
   "index": 2,
   "picture": "silla.si",
   "crop": [132, 102, 98, 52],
   "zoom": 2,
   "old": [143.65, 116, 32.69, 36.1]
  },
  {
   "w": "abre",
   "index": 3,
   "picture": "jugo.si",
   "crop": [84, 86, 98, 52],
   "zoom": 2,
   "old": [103.65, 98, 32.69, 36.1]
  },
  {
   "w": "hola",
   "index": 2,
   "picture": "se sienta.si",
   "crop": [20, 40, 196, 104],
   "zoom": 1,
   "old": [50.2, 84, 59.59, 65.8]
  },
  {
   "w": "silla",
   "index": 0,
   "picture": "silla.si",
   "crop": [132, 102, 98, 52],
   "zoom": 2,
   "old": [143.65, 116, 32.69, 36.1]
  },
  {
   "w": "silla",
   "index": 1,
   "picture": "silla.no",
   "crop": [88, 45, 98, 52],
   "zoom": 2,
   "old": [103.65, 116, 32.69, 36.1]
  },
  {
   "w": "silla",
   "index": 2,
   "picture": "jugo.si",
   "crop": [84, 86, 98, 52],
   "zoom": 2,
   "old": [103.65, 98, 32.69, 36.1]
  },
  {
   "w": "jugo",
   "index": 0,
   "picture": "jugo.si",
   "crop": [84, 86, 98, 52],
   "zoom": 2,
   "old": [103.65, 98, 32.69, 36.1]
  },
  {
   "w": "jugo",
   "index": 1,
   "picture": "agua.si",
   "crop": [84, 86, 98, 52],
   "zoom": 2,
   "old": [103.65, 98, 32.69, 36.1]
  },
  {
   "w": "jugo",
   "index": 2,
   "picture": "silla.si",
   "crop": [132, 102, 98, 52],
   "zoom": 2,
   "old": [143.65, 116, 32.69, 36.1]
  },
  {
   "w": "se sienta",
   "index": 0,
   "picture": "se sienta.si",
   "crop": [20, 40, 196, 104],
   "zoom": 1,
   "old": [50.2, 84, 59.59, 65.8]
  },
  {
   "w": "se sienta",
   "index": 1,
   "picture": "se sienta.no",
   "crop": [20, 40, 196, 104],
   "zoom": 1,
   "old": [66.2, 84, 59.59, 65.8]
  },
  {
   "w": "quiero",
   "index": 0,
   "picture": "quiero.si",
   "crop": [20, 0, 196, 104],
   "zoom": 1,
   "old": [49.31, 52, 89.39, 98.7]
  },
  {
   "w": "quiero",
   "index": 1,
   "picture": "quiero.no",
   "crop": [20, 0, 196, 104],
   "zoom": 1,
   "old": [49.31, 52, 89.39, 98.7]
  },
  {
   "w": "quiero",
   "index": 2,
   "picture": "¿cómo estás?.si",
   "crop": [20, 0, 196, 104],
   "zoom": 1,
   "old": [49.31, 52, 89.39, 98.7]
  },
  {
   "w": "flor",
   "index": 3,
   "picture": "silla.si",
   "crop": [132, 102, 98, 52],
   "zoom": 2,
   "old": [143.65, 116, 32.69, 36.1]
  },
  {
   "w": "hasta mañana",
   "index": 2,
   "picture": "jugo.si",
   "crop": [84, 86, 98, 52],
   "zoom": 2,
   "old": [103.65, 98, 32.69, 36.1]
  }
 ],
 "clips": {
  "puerta.hueco": {
   "thing": "puerta",
   "face": "opening",
   "world": [
    [2.2, 0, -0.15],
    [3.5, 0, -0.15],
    [3.5, 0, 2.85],
    [2.2, 0, 2.85]
   ],
   "screen": [
    [198.45, 151.6],
    [222.35, 163.55],
    [222.35, 96],
    [198.45, 84.05]
   ],
   "box": [198, 84, 25, 80],
   "what": "the doorway on the front wall, carried .45 below the floor so her feet stay whole (old rect [165,57,24,69], balcon.js:124): abuela standing in the door (ab.en puerta) is drawn clipped to it"
  }
 },
 "front": {
  "how": "at the old line, draw again each pixel of the set that balcon-set.html's part(name) drew last (PART_TAGS), over what the sprite layer has drawn so far, but only where that pixel is nearer to the camera than abuela: bakedZ[i] > vAb / COS - (row + .5 - OY) * tan(30 deg) / S (the depth, at that row, of the upright plane through her facing the camera). vAb = (x + y) / R2 of the point under her: standing, the point at height .3 (the porch) that lands on (ab.x, ab.y - 1); sitting, points.ABS.world. Only abuela (standing, balcon.js:126; sitting, :129 to :134, under the small chair and the table) is drawn before these lines. Why the depth: on the old flat picture \"behind the furniture\" was a row (ab.y < 144); with this camera the porch is a slanting band and no row separates behind the table from before her chair",
  "plane": "vAb / COS - (row + .5 - OY) * tan(30 deg) / S",
  "parts": {
   "silla_grande": {
    "line": 127,
    "replaces": "c.drawImage(spr(\"sillaG\",mkSillaG),SILLA[0],SILLA[1])"
   },
   "silla_pequena": {
    "line": 135,
    "replaces": "c.drawImage(spr(\"sillaP\",mkSillaP),SILLITA[0],SILLITA[1])"
   },
   "mesa": {
    "line": 136,
    "replaces": "c.drawImage(spr(\"mesa\",mkMesa),94,125)"
   }
  }
 },
 "shadows": {
  "coqui": {
   "radius": 0.45,
   "at": "the ground point that lands on his feet on screen (g = unproject(b.x + b.w / 2, q.y + 25), on the porch and the steps too, as El frente's porch)",
   "when": "W.cq.vis and al > .5, and not when he sits on the small chair (rana()'s sent: the old drew no shadow there either)",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "abuela": {
   "radius": 0.35,
   "at": "the ground point that lands on her feet on screen (g = unproject(ab.x, ab.y - 1))",
   "when": "W.ab standing (en puerta, camina; not en silla: she sits in the chair's own shadow; not while she fades, al <= .5)",
   "cast": "for (z = .3; z <= 2; z += .35) castShadow(g.x, g.y, z, .35)"
  },
  "dropped": "balcon.js:118 rana()'s dotted shadow under the frog (green on the lawn, tan on the porch) is not drawn: the engine casts his"
 },
 "dropped": [
  "balcon.js:121 c.drawImage(bg) -> the set, for setKey(W)",
  "balcon.js:127, :135, :136 the big chair, the small chair, the table sprites -> the set (and front: their pixels again at those lines)",
  "balcon.js:118 the frog's dotted shadow -> the engine's cast shadow (shadows.coqui)",
  "balcon.js:50 the two hanging plants of bg() are not in the set: from this camera they would hang in front of the window and the door, over their touch boxes (decision 14). The two bushes are; the old posts are not (the short roof stands on none)"
 ],
 "code": [
  {
   "line": 79,
   "old": "VT n [9,13], g [11,17], p [7,9] (glass sizes)",
   "to": "sizes, not places: unchanged"
  },
  {
   "line": 95,
   "old": "X2=[108,132]",
   "to": {
    "points": ["mesa.izq", "mesa.der"],
    "new": [119, 147]
   }
  },
  {
   "line": 95,
   "old": "X4=[101,113,127,139]",
   "to": "never read by the scene: unchanged"
  },
  {
   "line": 95,
   "old": "MESA_Y=128",
   "to": {
    "MESA_Y": 116
   }
  },
  {
   "line": 95,
   "old": "SILLA=[48,102]",
   "to": "the big chair's sprite: dropped (the set); its box is things.silla_grande"
  },
  {
   "line": 95,
   "old": "SILLITA=[148,120]",
   "to": "the small chair's sprite: dropped (the set); its box is things.silla_pequena"
  },
  {
   "line": 95,
   "old": "ABS=[51,96]",
   "to": {
    "point": "ABS",
    "new": [56, 51]
   }
  },
  {
   "line": 95,
   "old": "PERCH=[120,86]",
   "to": {
    "point": "PERCH",
    "new": [131, 82]
   }
  },
  {
   "line": 95,
   "old": "ASIENTO=[160,135]",
   "to": {
    "point": "ASIENTO",
    "new": [177, 132]
   }
  },
  {
   "line": 96,
   "old": "AB.puerta [178,125]",
   "to": {
    "spot": "abuela.puerta",
    "new": [209, 149]
   }
  },
  {
   "line": 96,
   "old": "AB.mesa [98,143]",
   "to": {
    "spot": "abuela.mesa",
    "new": [96, 136]
   }
  },
  {
   "line": 96,
   "old": "AB.lado [94,147]",
   "to": {
    "spot": "abuela.lado",
    "new": [95, 126]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.jardin [104,185,1]",
   "to": {
    "spot": "jardin",
    "new": [117, 175, 1]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.balcon [106,130,0.8]",
   "to": {
    "spot": "balcon",
    "new": [129, 127, 0.8]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.mesa [104,141,0.86]",
   "to": {
    "spot": "mesa",
    "new": [120, 133, 0.86]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.junto [104,141,0.86]",
   "to": {
    "spot": "mesa",
    "new": [120, 133, 0.86]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.decir [134,130,0.8]",
   "to": {
    "spot": "decir",
    "new": [154, 145, 0.8]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.silla_pequena [144,109,0.72]",
   "to": {
    "spot": "silla_pequena",
    "new": [161, 107, 0.72]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.suelo [150,132,0.8]",
   "to": {
    "spot": "suelo",
    "new": [167, 145, 0.8]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.abuela [84,129,0.8]",
   "to": {
    "spot": "abuela",
    "new": [100, 123, 0.8]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.silla_grande [84,129,0.8]",
   "to": {
    "spot": "abuela",
    "new": [100, 123, 0.8]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.puerta [162,125,0.76]",
   "to": {
    "spot": "puerta",
    "new": [192, 133, 0.76]
   }
  },
  {
   "line": 97,
   "old": "LUGAR.ventana [106,130,0.8]",
   "to": {
    "spot": "balcon",
    "new": [129, 127, 0.8]
   }
  },
  {
   "line": 100,
   "old": "cajaDe: [x - w/2 - 4, y - h - 6, w + 8, h + 9]; a jug [v.x - 9, MESA_Y - 24, 26, 27]",
   "to": "relative to the glass or jug: unchanged (MESA_Y is the new one)"
  },
  {
   "line": 102,
   "old": "abCaja silla [55,96,34,50]",
   "to": {
    "new": [60, 51, 34, 50]
   },
   "note": "ABS + [4, 0, 34, 50]; standing: relative, unchanged"
  },
  {
   "line": 105,
   "old": "box mesa [94,124,52,25]",
   "to": {
    "thing": "mesa",
    "box": [108, 98, 50, 37]
   }
  },
  {
   "line": 105,
   "old": "box silla_pequena [SILLITA,24,30] = [148,120,24,30]",
   "to": {
    "thing": "silla_pequena",
    "box": [165, 115, 24, 31]
   }
  },
  {
   "line": 105,
   "old": "box silla_grande [SILLA,40,48] = [48,102,40,48]",
   "to": {
    "thing": "silla_grande",
    "box": [56, 57, 39, 48]
   }
  },
  {
   "line": 106,
   "old": "box puerta [162,54,32,68]",
   "to": {
    "thing": "puerta",
    "box": [194, 79, 33, 84]
   }
  },
  {
   "line": 106,
   "old": "hand puerta [178,84]",
   "to": {
    "point": "mano.puerta",
    "new": [210, 112]
   }
  },
  {
   "line": 106,
   "old": "box ventana [93,54,54,36]",
   "to": {
    "thing": "ventana",
    "box": [111, 43, 45, 54]
   }
  },
  {
   "line": 106,
   "old": "hand ventana [120,70]",
   "to": {
    "point": "mano.ventana",
    "new": [137, 67]
   }
  },
  {
   "line": 106,
   "old": "box balcon [42,122,156,34]",
   "to": {
    "thing": "balcon",
    "box": [75, 126, 113, 64]
   }
  },
  {
   "line": 116,
   "old": "bub2: c.scale(2,2), bub(c,k,0,0,a)",
   "to": "relative: unchanged (the bubbles are drawn at twice their size)"
  },
  {
   "line": 117,
   "old": "rana: sent = |q.x - LUGAR.silla_pequena[0]| < 3 && |q.y - LUGAR.silla_pequena[1]| < 3",
   "to": "reads LUGAR: the new spot"
  },
  {
   "line": 118,
   "old": "rana: the dotted shadow at b.x+2, q.y+25 (green when q.y > 158)",
   "to": "dropped: the engine casts his shadow (shadows.coqui)"
  },
  {
   "line": 121,
   "old": "c.drawImage(bg, 0, 0)",
   "to": "dropped: the set, for setKey(W)"
  },
  {
   "line": 123,
   "old": "dePie: mkAbuela at ab.x - 30, ab.y - 50; the tray at x + 1, y + 26",
   "to": "relative to her: unchanged"
  },
  {
   "line": 124,
   "old": "clip rect(165,57,24,69)",
   "to": {
    "clip": "puerta.hueco"
   }
  },
  {
   "line": 126,
   "old": "ab.y < 144",
   "to": {
    "behind": 126
   }
  },
  {
   "line": 127,
   "old": "drawImage(sillaG, SILLA)",
   "to": {
    "front": "silla_grande"
   }
  },
  {
   "line": 129,
   "old": "mkAbuelaS at ABS",
   "to": {
    "point": "ABS",
    "new": [56, 51]
   }
  },
  {
   "line": 130,
   "old": "fan at ABS + (31 + d, 16)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 131,
   "old": "her glass at ABS + (30 or 36, 17 or 28)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 132,
   "old": "the jug over her head: translate(ABS + (30, -2)), jarra(c, 0, 8)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 133,
   "old": "the water from the jug: ABS + (16, -10 ...)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 134,
   "old": "sweat: ABS + (17 + ..., 6 ...)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 135,
   "old": "drawImage(sillaP, SILLITA)",
   "to": {
    "front": "silla_pequena"
   }
  },
  {
   "line": 136,
   "old": "drawImage(mesa, 94, 125)",
   "to": {
    "front": "mesa"
   }
  },
  {
   "line": 137,
   "old": "vasos at v.x, v.y || MESA_Y",
   "to": "v.x from X2, mesa.centro, ASIENTO or the remap; MESA_Y the new one"
  },
  {
   "line": 138,
   "old": "fanMesa: medio(c, 121, MESA_Y, 1)",
   "to": {
    "point": "mesa.abanico",
    "new": [124, 124]
   },
   "note": "order 30b: x and y both from the point (the old y was MESA_Y)"
  },
  {
   "line": 139,
   "old": "enSuelo: medio(c, 98, 157, -1)",
   "to": {
    "point": "suelo.abanico.1",
    "new": [96, 115]
   }
  },
  {
   "line": 139,
   "old": "enSuelo: medio(c, 110, 158, 1)",
   "to": {
    "point": "suelo.abanico.2",
    "new": [108, 117]
   }
  },
  {
   "line": 140,
   "old": "jarras at v.x, MESA_Y",
   "to": "v.x from X2 or the remap; MESA_Y the new one"
  },
  {
   "line": 141,
   "old": "ab.y >= 144",
   "to": {
    "behind": 126
   }
  },
  {
   "line": 142,
   "old": "the falling fan halves: ABS + (34 - t, 16 + 3t), ABS + (38 + t/2, 16 + 3t)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 143,
   "old": "the frog and what he holds: frogBox",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 149,
   "old": "pouring: ABS + (36, 8 ...)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 150,
   "old": "drawAve(W.ave)",
   "to": "the bird's place comes from PERCH, ASIENTO, the glasses or the remap"
  },
  {
   "line": 151,
   "old": "splash: ABS + (17 ..., 2 ...)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 152,
   "old": "the puddle: ABS + (2, 50), (6, 52)",
   "to": "relative to ABS: unchanged"
  },
  {
   "line": 153,
   "old": "W.rojo: fillRect(0, 0, SW, SH)",
   "to": "the whole picture: unchanged"
  },
  {
   "line": 154,
   "old": "abuela's bubble at talkAt",
   "to": "relative: unchanged"
  },
  {
   "line": 155,
   "old": "the frog's bubble at frogBox",
   "to": "relative: unchanged"
  },
  {
   "line": 158,
   "old": "talkAt: ABS + (17, -39 or -1); standing ab.x, ab.y - 51 (- 38)",
   "to": {
    "point": "talk.lado",
    "new": [97, 70]
   },
   "note": "order 30b: sitting while the score boards are up (W.rondas): [TALK_LADO[0], TALK_LADO[1] - (ab.bub ? 38 : 0)], her bubble beside her head under the boards; otherwise as before, relative to ABS or to her"
  },
  {
   "line": 160,
   "old": "respIcon: a big glass in the answer bubble",
   "to": "relative: unchanged"
  },
  {
   "line": 179,
   "old": "hud: tanteo(g, 5, 5), tanteo(g, DW - 71, 5), termo(g, DW - 51, 7)",
   "to": "display: unchanged (hud draws on the 196 x 216 display)"
  },
  {
   "line": 183,
   "old": "abCamina: from AB.lado when in the chair; steps of 6 px",
   "to": "AB.lado: the new spot; the step length stays"
  },
  {
   "line": 186,
   "old": "dos(): X2[s], X2[1 - s]",
   "to": "X2: line 95"
  },
  {
   "line": 188,
   "old": "dos(\"sm\"): vaso_silla at ASIENTO[0], ASIENTO[1] - 1; vaso_mesa at x 120",
   "to": {
    "point": "mesa.centro",
    "new": [134, 116]
   },
   "note": "ASIENTO: line 95"
  },
  {
   "line": 189,
   "old": "dos(\"fin\"): X2[0], X2[1]",
   "to": "X2: line 95"
  },
  {
   "line": 191,
   "old": "brillo: stars at v.x, (v.y || MESA_Y) - 20",
   "to": "relative to the glasses: unchanged"
  },
  {
   "line": 193,
   "old": "sube: hopTo(LUGAR.jardin[0], 168, 1, .9)",
   "to": {
    "spot": "sube",
    "frog": [117, 157],
    "x": "LUGAR.jardin[0] (the same x: yes)"
   }
  },
  {
   "line": 195,
   "old": "absienta: abCamina(AB.lado)",
   "to": "AB: line 96"
  },
  {
   "line": 197,
   "old": "abentra: abCamina(AB.puerta)",
   "to": "AB: line 96"
  },
  {
   "line": 199,
   "old": "absale: abCamina(AB.mesa)",
   "to": "AB: line 96"
  },
  {
   "line": 210,
   "old": "aveventana: PERCH",
   "to": "PERCH: line 95"
  },
  {
   "line": 212,
   "old": "aveva: lado = v.x < 120 ? 1 : -1; to v.x + lado * 19, v.y || MESA_Y",
   "to": {
    "point": "mesa.centro",
    "x": 134
   },
   "note": "the test x is the table's middle; the 19 stays: the bird lands on the table on the middle's side of the glass"
  },
  {
   "line": 214,
   "old": "avesilla: ASIENTO",
   "to": "ASIENTO: line 95"
  },
  {
   "line": 217,
   "old": "marcador: camGo(\"wide\", 9)",
   "to": {
    "view": "wide"
   }
  },
  {
   "line": 219,
   "old": "marcador stars [60,50],[180,54],[120,42],[96,64],[150,60]",
   "to": "screen effect: unchanged (they are over the roof and the wall, as before)"
  },
  {
   "line": 220,
   "old": "marcador: aveVa(ASIENTO), ir balcon",
   "to": "ASIENTO: line 95; LUGAR: line 97"
  },
  {
   "line": 224,
   "old": "lleva: ir mesa, abuela, decir",
   "to": "LUGAR: line 97"
  },
  {
   "line": 229,
   "old": "aparta: the glass she puts down: x 120",
   "to": {
    "point": "mesa.centro",
    "x": 134
   }
  },
  {
   "line": 242,
   "old": "recibe: his glass: x 132",
   "to": {
    "point": "mesa.der",
    "x": 147
   }
  },
  {
   "line": 244,
   "old": "pone: the jugs at X2",
   "to": "X2: line 95"
  },
  {
   "line": 253,
   "old": "fin stars [60,50],[180,54],[120,42],[96,64],[150,60]",
   "to": "screen effect: unchanged"
  },
  {
   "line": 206,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 209,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 213,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 225,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 227,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 245,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 246,
   "old": "how full: 0.66, 0.33, 0 / 0.4, 0.7, 1",
   "to": "not a place: unchanged"
  },
  {
   "line": 262,
   "old": "CAM.wide [22,0,196,216]",
   "to": {
    "view": "wide",
    "zoom": 1,
    "x0": 40
   }
  },
  {
   "line": 262,
   "old": "CAM.mesa [45,36,127,140]",
   "to": {
    "view": "mesa",
    "zoom": 1,
    "x0": 40
   }
  },
  {
   "line": 262,
   "old": "CAM.porche [35,20,170,187.3]",
   "to": {
    "view": "porche",
    "zoom": 1,
    "x0": 40
   }
  },
  {
   "line": 262,
   "old": "heartAt [107,31]",
   "to": {
    "point": "corazon",
    "new": [118, 32]
   }
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: balcon's fresh() puts him at LUGAR.jardin"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86 (the frog of a pair picture)",
   "to": "the pairs of cual-balcon set cq themselves when they show him (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": []
 }
}
''',
  'sala': r'''{
 "scene": "sala",
 "made": "node docs/proyecto/pixel/sala-sheet-make.js, from sala-set.html (window.SALA) and coqui/ref/escenas/sala/. Order 31a.",
 "S": 26,
 "origin": {
  "originX": 20,
  "originY": -33
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the room is built round the old picture: a place on its floor keeps its screen place. A frog place q: the floor point under (q.x + 16, q.y + 25), new q = old q. A person's place (x, y): the floor point under (x, y - 1), new (x, y) = old. So every floor position of sala.js, its stories and its pairs keeps its numbers, but for the few in moves (where the old picture put someone under the answer cards or a bubble on a face); the sheet names each one (spots, remap, code, moves) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog or a point (p.x + 22, q.x + 16, h[0] - 2, the bubbles, the trays, the cups, the Z of sleep) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the flash (W.flash), the blur (W.borroso), the stars of final6 and final8, the heart (heartAt)",
  "view": "both views are zoom 1: the 196 x 216 window from x0 22, the old wide one. A change of view moves nothing",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were"
 },
 "room": {
  "what": "a doll's house cut: of the room's four walls only the two far ones stand, the left one (facing +x, in shade: the door to the porch and the three frames) and the back one (facing +y, lit: the window). The two near walls are not built. The floor runs past the picture's bottom and sides, so no cut edge of it shows; the standing walls are cut at 3.2 (a strip of wall over the door and the window), their cut tops a white edge. Furniture is turned to face the camera (as El balcón's chairs): the sofa stands across the corner, so the family sits in a row as in the old picture. The frames hang turned to the camera too (round 2): upright pictures on wires from nails, so the photos are upright and whole at the old size: three 20 x 27 frames 2 px apart, their nails at one height on the wall, so they step up towards the corner with it, between the door's casing and the corner with 3 px to spare each side (a crooked one turns two corners 2.9 px out: counterclockwise, over the lower frame on its left and under the higher one on its right). The lamp stands in the corner, its foot on the floor seen over the sofa's back, as tall as the old one (its shade over the frames). Through the door: the porch's tiles (El balcón's), 2.6 out, its stone edge, and the lawn 0.3 lower beyond",
  "why": "the old picture is a wall and a floor that fill the frame, every place in it on that floor; a near wall, even cut low, would stand across the frog's floor and over feet, and a cut edge of the floor would be a line across the room. The two far walls are where the old door (left) and window (right) were; the corner between them is behind the sofa, as the old wall was"
 },
 "top": {
  "liso": "above the cut walls a flat calm dark grey (rgb 38, 36, 44), a little lighter than the lesson screen's #1B1B1F: the picture reads as a room seen from above, nothing outside competes with it",
  "chosen": "liso",
  "decided": "the orchestrator (round 2): top = liso. Round 1's candidate b (the lawn round the house behind the cut walls) is gone, and top is no longer a parameter of the set"
 },
 "smoothing": {
  "what": "sala.js turns smoothing on in three places; the new canvas (Ctx) does not smooth unless told, so each keeps its smoothing on (Ctx.smoothing = true) exactly there, over the new picture",
  "places": [
   {
    "at": "sala.js:120",
    "what": "W.borroso (acts.tropieza: what abuelo sees without his glasses): the whole scene picture, the set and the sprite layer drawn so far, is drawn down to 20 x 18 with smoothing on",
    "keep": "Ctx.snapshot of the 240 x 216 picture, drawImage into a 20 x 18 Sprite with smoothing true. The picture is the new set with the sprites on it: the blur is of the new room"
   },
   {
    "at": "sala.js:121",
    "what": "the 20 x 18 picture drawn back up to 240 x 216 with smoothing on (then off)",
    "keep": "drawImageRect with smoothing true, then false, as the old"
   },
   {
    "at": "sala.js:137",
    "what": "W.visor without nitido (la-foto: the camera's little window, out of focus): the person's sprite (22 x 23 of it) drawn down to 5 x 5 and back up to 46 x 46, smoothing on for both (the hud, on the display picture)",
    "keep": "unchanged: it draws a person's sprite in the hud, not the set"
   }
  ],
  "notSmoothing": "sala.js:190 acts.retrato draws 198 x 124 of the picture into 128 x 80 with smoothing OFF (a nearest-neighbour shrink, as the old): its region is points.retrato"
 },
 "setKey": {
  "params": {
   "luz": {
    "values": ["1", "0"],
    "fromW": "W.luz: the floor lamp lit (1) or not (0); every story keeps it lit (the old mkLampara(W.luz) draws both)"
   },
   "fotos": {
    "values": "three characters, 0 or 1, one a frame, left to right",
    "fromW": "for i in 0..2: W.fotos[i] && !W.fotos[i].ok ? \"1\" (crooked) : \"0\". A photo in a frame (its people, the frog's foot, the slippers) is the sprite layer's: marco()"
   }
  },
  "key": "luz + \"-\" + fotos, e.g. \"1-000\"",
  "baked": [
   {
    "query": "?luz=1&fotos=000",
    "reached": "every story's start, la-familia, d-bizcocho-bebe, quien-eres-tu, h-sala, d-foto-familia (all its photos straight), the pairs"
   },
   {
    "query": "?luz=1&fotos=100",
    "reached": "la-foto wrong (one crooked photo)"
   },
   {
    "query": "?luz=1&fotos=110",
    "reached": "la-foto wrong (two)"
   },
   {
    "query": "?luz=1&fotos=111",
    "reached": "la-foto wrong (three: the slippers)"
   },
   {
    "query": "?luz=1&fotos=010",
    "reached": "la-foto alternate"
   }
  ],
  "bakedWhy": "order 06 found 27 states: what makes them is W.fotos (the frames), W.pastel (the cake), W.camMesa, W.gotas (coffee drops), W.relleno and W.luz. Only the frames' crookedness and the lamp are the set's; the cake, the camera, the drops and the photos in the frames are drawn by the sprite layer, so 5 baked states draw all 27",
  "notRead": "W.borroso is an effect over the whole picture (smoothing: see smoothing); W.golpe (the table jumps 2 px when abuelo trips) is not drawn: the table is in the set"
 },
 "things": {
  "hermano": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "hermana": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "bebe": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "abuela": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "mama": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "papa": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "abuelo": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "bizcocho": {
   "sprite": true,
   "prop": true,
   "why": "the cake on its dish (sprite layer): box [x - 1, y, 30, 16] at points.bizcocho (old [106, 138, 30, 16] at 107, 138)",
   "box": [107, 142, 30, 16]
  },
  "mesita": {
   "set": true,
   "world": [3.182, 4.2154, 0, 4.433, 5.4665, -0.1658],
   "box": [98, 142, 47, 28],
   "what": "the low table, turned to the camera",
   "turned": {
    "centre": [4.1785, 5.2119],
    "halfWidth": 0.8846,
    "halfDepth": 0.36,
    "height": 0.44,
    "angle": -0.7854
   },
   "old": {
    "box": [98, 148, 46, 18]
   }
  },
  "sofa": {
   "set": true,
   "world": [-0.3807, 1.0335, 0, 2.1213, 3.5355, -0.2033],
   "box": [68, 81, 92, 51],
   "what": "the long sofa, turned to the camera",
   "turned": {
    "centre": [1.8031, 3.2173],
    "halfWidth": 1.7692,
    "halfDepth": 0.45,
    "height": 1.32,
    "angle": -0.7854
   },
   "old": {
    "box": [68, 84, 92, 44]
   }
  },
  "butaca": {
   "set": true,
   "world": [2.8012, 0.5711, 0, 3.9435, 1.7134, 0.7954],
   "box": [160, 88, 42, 39],
   "what": "abuelo's armchair, turned to the camera",
   "turned": {
    "centre": [3.6324, 1.4022],
    "halfWidth": 0.8077,
    "halfDepth": 0.44,
    "height": 1.22,
    "angle": -0.7854
   },
   "old": {
    "box": [160, 86, 42, 42]
   }
  },
  "fotos": {
   "set": true,
   "world": [-2.5293, -0.6255, 0, -0.6255, 1.2782, 0.8438],
   "box": [70, 27, 70, 54],
   "what": "the three picture frames on the left wall, crooked or straight, with their nails (the box round them all, as the old one; a square world box whose corners have that screen box)",
   "old": {
    "box": [64, 34, 82, 30]
   }
  },
  "lampara": {
   "set": true,
   "world": [0, -0.12, 0, 0.68, 0.56, 3],
   "box": [129, 6, 26, 81],
   "what": "the floor lamp in the corner, its foot to its shade",
   "old": {
    "box": [146, 62, 20, 64]
   }
  },
  "puerta": {
   "set": true,
   "world": [0.3345, 5.1203, 0, 1.2903, 6.076, 3.3288],
   "box": [34, 50, 36, 93],
   "what": "the doorway with its frame and the open leaf (the box round their real corners, as a square world box: the leaf stands out of the wall)",
   "old": {
    "box": [20, 42, 42, 80]
   }
  },
  "ventana": {
   "set": true,
   "world": [1.24, -0.1, 0.85, 3.98, 0.2, 2.97],
   "box": [159, 18, 57, 77],
   "what": "the window with its curtains and rod",
   "old": {
    "box": [160, 32, 56, 54]
   }
  },
  "sala": {
   "set": true,
   "world": [2.62, 2.62, 0, 8, 10.15, 0],
   "box": [1, 123, 238, 119],
   "what": "the open floor before the furniture (its box is the old floor's, from row 122 down, the whole width). Last in the hit order, as before",
   "old": {
    "box": [0, 122, 240, 94]
   }
  }
 },
 "spots": {
  "frog.puerta": {
   "world": [0.3807, 5.4937, 0],
   "new": [30, 104],
   "scale": 0.7,
   "old": [30, 104],
   "what": "LUGAR.puerta: the frog"
  },
  "frog.centro": {
   "world": [6.6903, 7.7782, 0],
   "new": [104, 183],
   "scale": 1,
   "old": [104, 183],
   "what": "LUGAR.centro: the frog"
  },
  "frog.huele": {
   "world": [3.8075, 6.6359, 0],
   "new": [72, 146],
   "scale": 0.9,
   "old": [72, 146],
   "what": "LUGAR.huele: the frog"
  },
  "frog.abuela": {
   "world": [3.9163, 7.5062, 0],
   "new": [58, 155],
   "scale": 1,
   "old": [58, 155],
   "what": "LUGAR.abuela: the frog"
  },
  "frog.mama": {
   "world": [2.9372, 5.2217, 0],
   "new": [82, 125],
   "scale": 0.9,
   "old": [82, 125],
   "what": "LUGAR.mama: the frog"
  },
  "frog.papa": {
   "world": [3.8619, 4.297, 0],
   "new": [116, 125],
   "scale": 0.9,
   "old": [116, 125],
   "what": "LUGAR.papa: the frog"
  },
  "frog.abuelo": {
   "world": [5.2217, 2.9372, 0],
   "new": [166, 125],
   "scale": 0.9,
   "old": [166, 125],
   "what": "LUGAR.abuelo: the frog"
  },
  "frog.bebe": {
   "world": [5.82, 7.7782, 0],
   "new": [88, 175],
   "scale": 1,
   "old": [88, 175],
   "what": "LUGAR.bebe: the frog"
  },
  "frog.izq": {
   "world": [5.0585, 9.41, 0],
   "new": [44, 183],
   "scale": 1,
   "old": [44, 183],
   "what": "LUGAR.izq: the frog"
  },
  "sitio.mama": {
   "world": [1.6046, 3.9435, 0],
   "new": [97, 127],
   "old": [97, 127],
   "what": "SITIO.mama: mama sitting (sent): the floor at the feet, before the seat"
  },
  "sitio.papa": {
   "world": [2.5293, 3.0188, 0],
   "new": [131, 127],
   "old": [131, 127],
   "what": "SITIO.papa: papa sitting (sent): the floor at the feet, before the seat"
  },
  "sitio.abuelo": {
   "world": [3.8891, 1.659, 0],
   "new": [181, 127],
   "old": [181, 127],
   "what": "SITIO.abuelo: abuelo sitting (sent): the floor at the feet, before the seat"
  },
  "sitio.bebe": {
   "world": [4.4602, 8.2677, 0],
   "new": [70, 193],
   "old": [70, 193],
   "what": "SITIO.bebe: bebe standing (sitting on the blanket)"
  },
  "sitio.abuela": {
   "world": [2.3389, 7.6694, 0],
   "new": [42, 168],
   "old": [42, 168],
   "what": "SITIO.abuela: abuela standing"
  },
  "sitio.hermano": {
   "world": [6.9079, 6.364, 0],
   "new": [150, 198],
   "old": [150, 198],
   "what": "SITIO.hermano: hermano standing"
  },
  "sitio.hermana": {
   "world": [7.7238, 5.5481, 0],
   "new": [180, 198],
   "old": [180, 198],
   "what": "SITIO.hermana: hermana standing"
  },
  "parados.0": {
   "world": [2.1757, 4.3514, 0],
   "new": [100, 136],
   "old": [100, 136],
   "what": "PARADOS[0]: two people standing before the sofa (lados parados; espejuelos)"
  },
  "parados.1": {
   "world": [3.2636, 3.2636, 0],
   "new": [140, 136],
   "old": [140, 136],
   "what": "PARADOS[1]: two people standing before the sofa (lados parados; espejuelos)"
  },
  "aparte.0": {
   "world": [4.7322, 8.5397, 0],
   "new": [70, 198],
   "old": [70, 198],
   "what": "APARTE[0]: two people apart, at the front"
  },
  "aparte.1": {
   "world": [7.4518, 5.82, 0],
   "new": [170, 198],
   "old": [170, 198],
   "what": "APARTE[1]: two people apart, at the front"
  },
  "juntos.0": {
   "world": [4.8954, 8.1589, 0],
   "new": [80, 196],
   "old": [96, 196],
   "what": "JUNTOS[0]: two people together, at the front (moved: see moves)"
  },
  "juntos.1": {
   "world": [7.0711, 5.9832, 0],
   "new": [160, 196],
   "old": [144, 196],
   "what": "JUNTOS[1]: two people together, at the front (moved: see moves)"
  },
  "camara": {
   "world": [7.0167, 3.8619, 0],
   "new": [198, 176],
   "old": [198, 176],
   "what": "CAMARA: abuelo with the camera"
  },
  "puerta.hermano": {
   "world": [0.1, 4.39, 0],
   "new": [61, 117],
   "old": [40, 126],
   "what": "acts.corren: a.x = 40, a.y = 126: the brother appears in the doorway, on its threshold"
  },
  "puerta.hermana": {
   "world": [0.1, 4.936, 0],
   "new": [51, 122],
   "old": [34, 124],
   "what": "acts.corren: b.x = 34, b.y = 124: the sister appears in the doorway, on its threshold, a step behind him"
  }
 },
 "lugar": {
  "puerta": {
   "spot": "frog.puerta",
   "q": [30, 104],
   "scale": 0.7,
   "old": [30, 104]
  },
  "centro": {
   "spot": "frog.centro",
   "q": [104, 183],
   "scale": 1,
   "old": [104, 183]
  },
  "huele": {
   "spot": "frog.huele",
   "q": [72, 146],
   "scale": 0.9,
   "old": [72, 146]
  },
  "abuela": {
   "spot": "frog.abuela",
   "q": [58, 155],
   "scale": 1,
   "old": [58, 155]
  },
  "mama": {
   "spot": "frog.mama",
   "q": [82, 125],
   "scale": 0.9,
   "old": [82, 125]
  },
  "papa": {
   "spot": "frog.papa",
   "q": [116, 125],
   "scale": 0.9,
   "old": [116, 125]
  },
  "abuelo": {
   "spot": "frog.abuelo",
   "q": [166, 125],
   "scale": 0.9,
   "old": [166, 125]
  },
  "bebe": {
   "spot": "frog.bebe",
   "q": [88, 175],
   "scale": 1,
   "old": [88, 175]
  },
  "izq": {
   "spot": "frog.izq",
   "q": [44, 183],
   "scale": 1,
   "old": [44, 183]
  }
 },
 "hops": [
  {
   "a": "puerta",
   "b": "centro",
   "old": 4,
   "new": 4,
   "dOld": 108.25,
   "dNew": 108.25
  },
  {
   "a": "puerta",
   "b": "huele",
   "old": 2,
   "new": 2,
   "dOld": 59.4,
   "dNew": 59.4
  },
  {
   "a": "puerta",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 58.18,
   "dNew": 58.18
  },
  {
   "a": "puerta",
   "b": "mama",
   "old": 2,
   "new": 2,
   "dOld": 56.08,
   "dNew": 56.08
  },
  {
   "a": "puerta",
   "b": "papa",
   "old": 3,
   "new": 3,
   "dOld": 88.53,
   "dNew": 88.53
  },
  {
   "a": "puerta",
   "b": "abuelo",
   "old": 4,
   "new": 4,
   "dOld": 137.61,
   "dNew": 137.61
  },
  {
   "a": "puerta",
   "b": "bebe",
   "old": 3,
   "new": 3,
   "dOld": 91.68,
   "dNew": 91.68
  },
  {
   "a": "puerta",
   "b": "izq",
   "old": 3,
   "new": 3,
   "dOld": 80.23,
   "dNew": 80.23
  },
  {
   "a": "centro",
   "b": "huele",
   "old": 2,
   "new": 2,
   "dOld": 48.92,
   "dNew": 48.92
  },
  {
   "a": "centro",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 53.85,
   "dNew": 53.85
  },
  {
   "a": "centro",
   "b": "mama",
   "old": 2,
   "new": 2,
   "dOld": 62.03,
   "dNew": 62.03
  },
  {
   "a": "centro",
   "b": "papa",
   "old": 2,
   "new": 2,
   "dOld": 59.23,
   "dNew": 59.23
  },
  {
   "a": "centro",
   "b": "abuelo",
   "old": 3,
   "new": 3,
   "dOld": 84.9,
   "dNew": 84.9
  },
  {
   "a": "centro",
   "b": "bebe",
   "old": 1,
   "new": 1,
   "dOld": 17.89,
   "dNew": 17.89
  },
  {
   "a": "centro",
   "b": "izq",
   "old": 2,
   "new": 2,
   "dOld": 60,
   "dNew": 60
  },
  {
   "a": "huele",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 16.64,
   "dNew": 16.64
  },
  {
   "a": "huele",
   "b": "mama",
   "old": 1,
   "new": 1,
   "dOld": 23.26,
   "dNew": 23.26
  },
  {
   "a": "huele",
   "b": "papa",
   "old": 2,
   "new": 2,
   "dOld": 48.75,
   "dNew": 48.75
  },
  {
   "a": "huele",
   "b": "abuelo",
   "old": 3,
   "new": 3,
   "dOld": 96.32,
   "dNew": 96.32
  },
  {
   "a": "huele",
   "b": "bebe",
   "old": 1,
   "new": 1,
   "dOld": 33.12,
   "dNew": 33.12
  },
  {
   "a": "huele",
   "b": "izq",
   "old": 2,
   "new": 2,
   "dOld": 46.4,
   "dNew": 46.4
  },
  {
   "a": "abuela",
   "b": "mama",
   "old": 1,
   "new": 1,
   "dOld": 38.42,
   "dNew": 38.42
  },
  {
   "a": "abuela",
   "b": "papa",
   "old": 2,
   "new": 2,
   "dOld": 65.3,
   "dNew": 65.3
  },
  {
   "a": "abuela",
   "b": "abuelo",
   "old": 4,
   "new": 4,
   "dOld": 112.09,
   "dNew": 112.09
  },
  {
   "a": "abuela",
   "b": "bebe",
   "old": 1,
   "new": 1,
   "dOld": 36.06,
   "dNew": 36.06
  },
  {
   "a": "abuela",
   "b": "izq",
   "old": 1,
   "new": 1,
   "dOld": 31.3,
   "dNew": 31.3
  },
  {
   "a": "mama",
   "b": "papa",
   "old": 1,
   "new": 1,
   "dOld": 34,
   "dNew": 34
  },
  {
   "a": "mama",
   "b": "abuelo",
   "old": 3,
   "new": 3,
   "dOld": 84,
   "dNew": 84
  },
  {
   "a": "mama",
   "b": "bebe",
   "old": 2,
   "new": 2,
   "dOld": 50.36,
   "dNew": 50.36
  },
  {
   "a": "mama",
   "b": "izq",
   "old": 2,
   "new": 2,
   "dOld": 69.34,
   "dNew": 69.34
  },
  {
   "a": "papa",
   "b": "abuelo",
   "old": 2,
   "new": 2,
   "dOld": 50,
   "dNew": 50
  },
  {
   "a": "papa",
   "b": "bebe",
   "old": 2,
   "new": 2,
   "dOld": 57.31,
   "dNew": 57.31
  },
  {
   "a": "papa",
   "b": "izq",
   "old": 3,
   "new": 3,
   "dOld": 92.46,
   "dNew": 92.46
  },
  {
   "a": "abuelo",
   "b": "bebe",
   "old": 3,
   "new": 3,
   "dOld": 92.65,
   "dNew": 92.65
  },
  {
   "a": "abuelo",
   "b": "izq",
   "old": 4,
   "new": 4,
   "dOld": 135.09,
   "dNew": 135.09
  },
  {
   "a": "bebe",
   "b": "izq",
   "old": 1,
   "new": 1,
   "dOld": 44.72,
   "dNew": 44.72
  }
 ],
 "points": {
  "bizcocho": {
   "screen": [108, 142],
   "old": [107, 138],
   "what": "bizcocho(c, x, y, n): the cake on its dish on the low table: the dish (x - 4 .. x + 30, rows y + 9 .. y + 11) on the table top, its bottom a row in front of the top's middle"
  },
  "camMesa": {
   "screen": [113, 143],
   "old": [113, 139],
   "what": "W.camMesa: the camera on the low table (16 x 10 at x, y), its bottom a row in front of the top's middle"
  },
  "foto.0": {
   "screen": [83, 52],
   "angle": 0,
   "nail": [83, 49],
   "old": [86, 40],
   "what": "marco(c, 0, f): translate here (the old translate(x + 10, y + 2)); no rotation; clip to clips.foto.0. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "foto.0.torcida": {
   "screen": [79.791, 52.3869],
   "angle": -0.24,
   "nail": [83, 49],
   "old": [86, 40],
   "what": "marco(c, 0, f): translate here (the old translate(x + 10, y + 2)); rotate(angle): the frame hangs turned counterclockwise about its middle, slid on its wire, the nail where it was (the old .24 + .05 sin(F / 6 + i): baked crooked, so it no longer swings); clip to clips.foto.0.torcida. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "foto.1": {
   "screen": [105, 41],
   "angle": 0,
   "nail": [105, 38],
   "old": [110, 40],
   "what": "marco(c, 1, f): translate here (the old translate(x + 10, y + 2)); no rotation; clip to clips.foto.1. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "foto.1.torcida": {
   "screen": [101.791, 41.3869],
   "angle": -0.24,
   "nail": [105, 38],
   "old": [110, 40],
   "what": "marco(c, 1, f): translate here (the old translate(x + 10, y + 2)); rotate(angle): the frame hangs turned counterclockwise about its middle, slid on its wire, the nail where it was (the old .24 + .05 sin(F / 6 + i): baked crooked, so it no longer swings); clip to clips.foto.1.torcida. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "foto.2": {
   "screen": [127, 30],
   "angle": 0,
   "nail": [127, 27],
   "old": [134, 40],
   "what": "marco(c, 2, f): translate here (the old translate(x + 10, y + 2)); no rotation; clip to clips.foto.2. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "foto.2.torcida": {
   "screen": [123.791, 30.3869],
   "angle": -0.24,
   "nail": [127, 27],
   "old": [134, 40],
   "what": "marco(c, 2, f): translate here (the old translate(x + 10, y + 2)); rotate(angle): the frame hangs turned counterclockwise about its middle, slid on its wire, the nail where it was (the old .24 + .05 sin(F / 6 + i): baked crooked, so it no longer swings); clip to clips.foto.2.torcida. The frame (the set) is marco()'s [-10, 0, 20, 27] there, the nail 3 rows over its top"
  },
  "corazon": {
   "screen": [107, 6],
   "old": [107, 6],
   "what": "heartAt: the heart of a happy ending (its top left): over the corner of the room, the backdrop behind it (unchanged)"
  },
  "hud.plato": {
   "screen": [50, 24],
   "old": [50, 24],
   "what": "vuelaA(..., 50, 24): a slice flies to the plate card in the view's top left (hud tarjeta 3, 3): picture x = wide x0 + 28; the wide window is the old one, so unchanged"
  },
  "destapa.estrellas": {
   "screen": [
    [109, 138],
    [133, 138],
    [121, 132]
   ],
   "old": [
    [108, 134],
    [132, 134],
    [120, 128]
   ],
   "what": "acts.destapa: the stars over the cake (moved with it)"
  },
  "tres.desde": {
   "screen": [121, 144],
   "old": [120, 140],
   "what": "acts.tres: the slices fly from the cake (moved with it)"
  },
  "retrato": {
   "screen": [22, 88, 198, 124],
   "old": [22, 88, 198, 124],
   "what": "acts.retrato: the part of the picture the photo of everyone is taken from (drawImage(sc, 22, 88, 198, 124, 0, 0, 128, 80)): the sofa, the floor before it and the family; the room is built round the old picture, so unchanged"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [3.5355, 4.6234, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the room: the door, the frames, the sofa, the lamp, the armchair and the window, the floor before them"
  },
  "sofa": {
   "zoom": 1,
   "x0": 22,
   "world": [3.5355, 4.6234, 0],
   "region": null,
   "old": [52, 48, 150, 165.3],
   "what": "the sofa (old: a 1.31x view of the sofa; no story turns to it): the same window as wide, so a change to it moves nothing"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [14, 146, 113, 60],
   "uses": [
    "cual-sala.json bebé.si.cam",
    "cual-sala.json bebé.no.cam"
   ],
   "to": {
    "pictures": ["bebe.si", "bebe.no"]
   },
   "crops": {
    "bebe.si": {
     "crop": [23, 152, 98, 52],
     "zoom": 2
    },
    "bebe.no": {
     "crop": [23, 152, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [30, 122, 170, 90.2],
   "uses": [
    "cual-sala.json él.si.cam",
    "cual-sala.json él.no.cam"
   ],
   "to": {
    "pictures": ["el.si", "el.no"]
   },
   "crops": {
    "el.si": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    },
    "el.no": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [35, 60, 170, 90.2],
   "uses": ["cual-sala.json familia.si.cam", "cual-sala.json familia.no.cam"],
   "to": {
    "pictures": ["familia.si", "familia.no"]
   },
   "crops": {
    "familia.si": {
     "crop": [22, 52, 196, 104],
     "zoom": 1
    },
    "familia.no": {
     "crop": [22, 52, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [35, 66, 170, 90.2],
   "uses": ["cual-sala.json ella.si.cam", "cual-sala.json ella.no.cam"],
   "to": {
    "pictures": ["ella.si", "ella.no"]
   },
   "crops": {
    "ella.si": {
     "crop": [22, 52, 196, 104],
     "zoom": 1
    },
    "ella.no": {
     "crop": [22, 52, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [41, 70, 113, 60],
   "uses": [
    "cual-sala.json mamá.si.cam",
    "cual-sala.json mamá.no.cam"
   ],
   "to": {
    "pictures": ["mama.si", "mama.no"]
   },
   "crops": {
    "mama.si": {
     "crop": [48, 77, 98, 52],
     "zoom": 2
    },
    "mama.no": {
     "crop": [48, 77, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [44, 132, 150, 79.6],
   "uses": [
    "cual-sala.json yo.si.cam",
    "cual-sala.json yo.no.cam",
    "cual-sala.json tú.si.cam",
    "cual-sala.json tú.no.cam"
   ],
   "to": {
    "pictures": ["yo.si", "yo.no", "tu.si", "tu.no"]
   },
   "crops": {
    "yo.si": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    },
    "yo.no": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    },
    "tu.si": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    },
    "tu.no": {
     "crop": [20, 112, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [64, 92, 113, 60],
   "uses": ["cual-sala.json hermano.si.cam", "cual-sala.json hermano.no.cam", "cual-sala.json hermana.si.cam", "cual-sala.json hermana.no.cam"],
   "to": {
    "pictures": ["hermano.si", "hermano.no", "hermana.si", "hermana.no"]
   },
   "crops": {
    "hermano.si": {
     "crop": [22, 70, 196, 104],
     "zoom": 1
    },
    "hermano.no": {
     "crop": [22, 70, 196, 104],
     "zoom": 1
    },
    "hermana.si": {
     "crop": [22, 70, 196, 104],
     "zoom": 1
    },
    "hermana.no": {
     "crop": [22, 70, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [75, 70, 113, 60],
   "uses": [
    "cual-sala.json papá.si.cam",
    "cual-sala.json papá.no.cam"
   ],
   "to": {
    "pictures": ["papa.si", "papa.no"]
   },
   "crops": {
    "papa.si": {
     "crop": [82, 77, 98, 52],
     "zoom": 2
    },
    "papa.no": {
     "crop": [82, 77, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [125, 70, 113, 60],
   "uses": ["cual-sala.json abuelo.si.cam", "cual-sala.json abuelo.no.cam"],
   "to": {
    "pictures": ["abuelo.si", "abuelo.no"]
   },
   "crops": {
    "abuelo.si": {
     "crop": [132, 77, 98, 52],
     "zoom": 2
    },
    "abuelo.no": {
     "crop": [132, 77, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [42.83, 146, 54.34, 60],
   "uses": [
    "nivel.js NV hermana.p3"
   ],
   "to": {
    "pictures": ["bebe.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [70.33, 70, 54.34, 60],
   "uses": [
    "nivel.js NV abuela.p1",
    "nivel.js NV quiero.p3",
    "nivel.js NV mamá.p0",
    "nivel.js NV familia.p1",
    "nivel.js NV amigo.p3"
   ],
   "to": {
    "pictures": ["mama.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [79.15, 60, 81.69, 90.2],
   "uses": [
    "nivel.js NV familia.p0"
   ],
   "to": {
    "pictures": ["familia.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [81.95, 132, 72.09, 79.6],
   "uses": [
    "nivel.js NV tú.p0",
    "nivel.js NV tú.p1",
    "nivel.js NV tú.p2"
   ],
   "to": {
    "pictures": ["tu.si", "tu.no", "yo.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [93.33, 92, 54.34, 60],
   "uses": [
    "nivel.js NV abuela.p3",
    "nivel.js NV mamá.p3",
    "nivel.js NV abuelo.p3",
    "nivel.js NV familia.p2",
    "nivel.js NV hermana.p0",
    "nivel.js NV hermana.p1",
    "nivel.js NV hermana.p2",
    "nivel.js NV tú.p3"
   ],
   "to": {
    "pictures": ["hermana.si", "hermano.si", "hermana.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [104.33, 70, 54.34, 60],
   "uses": [
    "nivel.js NV abuela.p2",
    "nivel.js NV jugo.p3",
    "nivel.js NV mamá.p1",
    "nivel.js NV abuelo.p2",
    "nivel.js NV ven.p3"
   ],
   "to": {
    "pictures": ["papa.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [154.33, 70, 54.34, 60],
   "uses": [
    "nivel.js NV se sienta.p3",
    "nivel.js NV mamá.p2",
    "nivel.js NV abuelo.p0",
    "nivel.js NV abuelo.p1",
    "nivel.js NV niña.p3"
   ],
   "to": {
    "pictures": ["abuelo.si", "abuelo.no"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [56, 174],
   "uses": [
    "cual-sala.json él.no.set.cq"
   ],
   "to": {
    "floor": [4.8954, 8.5941, 0]
   },
   "new": [56, 174],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [60, 114],
   "uses": ["cual-sala.json ella.si.set.cq"],
   "to": {
    "floor": [1.7406, 5.2217, 0]
   },
   "new": [60, 114],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [62, 150],
   "uses": ["cual-sala.json familia.si.set.gente.abuela"],
   "to": {
    "floor": [1.9037, 6.1464, 0]
   },
   "new": [62, 150],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [70, 193],
   "uses": [
    "cual-sala.json bebé.si.set.gente.bebe"
   ],
   "to": {
    "floor": [4.4602, 8.2677, 0]
   },
   "new": [70, 193],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [74, 197],
   "uses": [
    "cual-sala.json bebé.no.set.gente.hermano"
   ],
   "to": {
    "floor": [4.7866, 8.3765, 0]
   },
   "new": [74, 197],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [80, 179],
   "uses": [
    "cual-sala.json tú.si.set.cq",
    "cual-sala.json tú.no.set.cq"
   ],
   "to": {
    "floor": [5.82, 8.2133, 0]
   },
   "new": [80, 179],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [84, 200],
   "uses": ["d-foto-familia.json beats.9"],
   "to": {
    "floor": [5.2217, 8.2677, 0]
   },
   "new": [84, 200],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [96, 196],
   "uses": [
    "cual-sala.json él.si.set.gente.hermana",
    "cual-sala.json él.no.set.gente.hermana"
   ],
   "to": {
    "floor": [5.3305, 7.7238, 0]
   },
   "new": [96, 196],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [97, 112],
   "uses": ["cual-sala.json familia.si.set.gente.bebe"],
   "to": {
    "floor": [0.7887, 3.1276, 0]
   },
   "new": [97, 112],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [97, 127],
   "uses": [
    "cual-sala.json mamá.si.set.gente.mama",
    "cual-sala.json familia.si.set.gente.mama",
    "cual-sala.json familia.no.set.gente.mama"
   ],
   "to": {
    "floor": [1.6046, 3.9435, 0]
   },
   "new": [97, 127],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [97, 128],
   "uses": [
    "cual-sala.json mamá.no.set.gente.abuela"
   ],
   "to": {
    "floor": [1.659, 3.9979, 0]
   },
   "new": [97, 128],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [100, 136],
   "uses": ["cual-sala.json ella.si.set.gente.mama", "cual-sala.json ella.no.set.gente.mama"],
   "to": {
    "floor": [2.1757, 4.3514, 0]
   },
   "new": [100, 136],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [100, 196],
   "uses": ["cual-sala.json yo.si.set.gente.hermana", "cual-sala.json yo.no.set.gente.hermana"],
   "to": {
    "floor": [5.4393, 7.615, 0]
   },
   "new": [100, 196],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [114, 150],
   "uses": ["cual-sala.json familia.si.set.gente.hermano"],
   "to": {
    "floor": [3.318, 4.7322, 0]
   },
   "new": [114, 150],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [120, 146],
   "uses": ["d-foto-familia.json beats.6", "d-foto-familia.json beats.12", "d-foto-familia.json beats.18"],
   "to": {
    "floor": [3.2636, 4.3514, 0]
   },
   "new": [120, 146],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [120, 150],
   "uses": ["cual-sala.json hermano.si.set.gente.hermano", "cual-sala.json hermano.no.set.gente.papa", "cual-sala.json hermana.si.set.gente.hermana", "cual-sala.json hermana.no.set.gente.mama"],
   "to": {
    "floor": [3.4811, 4.569, 0]
   },
   "new": [120, 150],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [128, 179],
   "uses": ["cual-sala.json yo.si.set.cq", "cual-sala.json yo.no.set.cq"],
   "to": {
    "floor": [7.1255, 6.9079, 0]
   },
   "new": [128, 179],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [131, 127],
   "uses": [
    "cual-sala.json papá.si.set.gente.papa",
    "cual-sala.json papá.no.set.gente.abuelo",
    "cual-sala.json familia.si.set.gente.papa"
   ],
   "to": {
    "floor": [2.5293, 3.0188, 0]
   },
   "new": [131, 127],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [140, 136],
   "uses": ["cual-sala.json ella.si.set.gente.papa", "cual-sala.json ella.no.set.gente.papa"],
   "to": {
    "floor": [3.2636, 3.2636, 0]
   },
   "new": [140, 136],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [140, 196],
   "uses": [
    "cual-sala.json tú.si.set.gente.hermano",
    "cual-sala.json tú.no.set.gente.hermano"
   ],
   "to": {
    "floor": [6.5271, 6.5271, 0]
   },
   "new": [140, 196],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [144, 196],
   "uses": [
    "cual-sala.json él.si.set.gente.hermano",
    "cual-sala.json él.no.set.gente.hermano"
   ],
   "to": {
    "floor": [6.6359, 6.4184, 0]
   },
   "new": [144, 196],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [148, 114],
   "uses": ["cual-sala.json ella.no.set.cq"],
   "to": {
    "floor": [4.1339, 2.8284, 0]
   },
   "new": [148, 114],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 150],
   "uses": ["cual-sala.json familia.si.set.gente.hermana"],
   "to": {
    "floor": [4.297, 3.7531, 0]
   },
   "new": [150, 150],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [152, 174],
   "uses": [
    "cual-sala.json él.si.set.cq"
   ],
   "to": {
    "floor": [7.5062, 5.9832, 0]
   },
   "new": [152, 174],
   "what": "the frog (cq x, y): the floor under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [156, 200],
   "uses": ["d-foto-familia.json beats.15"],
   "to": {
    "floor": [7.1799, 6.3096, 0]
   },
   "new": [156, 200],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [160, 192],
   "uses": ["d-foto-familia.json beats.26"],
   "to": {
    "floor": [6.8535, 5.7656, 0]
   },
   "new": [160, 192],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [181, 127],
   "uses": ["cual-sala.json abuelo.si.set.gente.abuelo", "cual-sala.json familia.si.set.gente.abuelo"],
   "to": {
    "floor": [3.8891, 1.659, 0]
   },
   "new": [181, 127],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [183, 128],
   "uses": ["cual-sala.json abuelo.no.set.gente.abuela"],
   "to": {
    "floor": [3.9979, 1.659, 0]
   },
   "new": [183, 128],
   "what": "a person's feet (x, y): the floor under them; the same screen place"
  },
  {
   "kind": "x",
   "old": [70],
   "uses": [
    "nivel.js NV hermana.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [118],
   "uses": [
    "nivel.js NV tú.p0",
    "nivel.js NV tú.p1",
    "nivel.js NV tú.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "mama.si": {
   "world": [0.3536, 2.6924, 0],
   "screen": [97, 103],
   "zoom": 2,
   "crop": [48, 77, 98, 52],
   "what": "mamá sitting on the sofa, close"
  },
  "mama.no": {
   "world": [0.3536, 2.6924, 0],
   "screen": [97, 103],
   "zoom": 2,
   "crop": [48, 77, 98, 52],
   "what": "abuela standing where mamá sits, close"
  },
  "papa.si": {
   "world": [1.2782, 1.7678, 0],
   "screen": [131, 103],
   "zoom": 2,
   "crop": [82, 77, 98, 52],
   "what": "papá sitting on the sofa, close"
  },
  "papa.no": {
   "world": [1.2782, 1.7678, 0],
   "screen": [131, 103],
   "zoom": 2,
   "crop": [82, 77, 98, 52],
   "what": "abuelo sitting where papá sits, close"
  },
  "abuelo.si": {
   "world": [2.6381, 0.4079, 0],
   "screen": [181, 103],
   "zoom": 2,
   "crop": [132, 77, 98, 52],
   "what": "abuelo in his armchair, close"
  },
  "abuelo.no": {
   "world": [2.6381, 0.4079, 0],
   "screen": [181, 103],
   "zoom": 2,
   "crop": [132, 77, 98, 52],
   "what": "abuela standing at his armchair, close"
  },
  "bebe.si": {
   "world": [3.7531, 7.4518, 0],
   "screen": [72, 178],
   "zoom": 2,
   "crop": [23, 152, 98, 52],
   "what": "the baby on the blanket, close"
  },
  "bebe.no": {
   "world": [3.7531, 7.4518, 0],
   "screen": [72, 178],
   "zoom": 2,
   "crop": [23, 152, 98, 52],
   "what": "the brother on the blanket, close"
  },
  "familia.si": {
   "world": [1.0335, 2.1213, 0],
   "screen": [120, 104],
   "zoom": 1,
   "crop": [22, 52, 196, 104],
   "what": "everyone"
  },
  "familia.no": {
   "world": [1.0335, 2.1213, 0],
   "screen": [120, 104],
   "zoom": 1,
   "crop": [22, 52, 196, 104],
   "what": "mamá alone on the sofa"
  },
  "hermano.si": {
   "world": [2.0125, 3.1004, 0],
   "screen": [120, 122],
   "zoom": 1,
   "crop": [22, 70, 196, 104],
   "what": "the brother standing before the sofa"
  },
  "hermano.no": {
   "world": [2.0125, 3.1004, 0],
   "screen": [120, 122],
   "zoom": 1,
   "crop": [22, 70, 196, 104],
   "what": "papá standing there"
  },
  "hermana.si": {
   "world": [2.0125, 3.1004, 0],
   "screen": [120, 122],
   "zoom": 1,
   "crop": [22, 70, 196, 104],
   "what": "the sister standing before the sofa"
  },
  "hermana.no": {
   "world": [2.0125, 3.1004, 0],
   "screen": [120, 122],
   "zoom": 1,
   "crop": [22, 70, 196, 104],
   "what": "mamá standing there"
  },
  "el.si": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the frog beside the brother"
  },
  "el.no": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the frog beside the sister"
  },
  "ella.si": {
   "world": [1.0335, 2.1213, 0],
   "screen": [120, 104],
   "zoom": 1,
   "crop": [22, 52, 196, 104],
   "what": "the frog beside mamá"
  },
  "ella.no": {
   "world": [1.0335, 2.1213, 0],
   "screen": [120, 104],
   "zoom": 1,
   "crop": [22, 52, 196, 104],
   "what": "the frog beside papá"
  },
  "yo.si": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the sister points at herself"
  },
  "yo.no": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the sister points at the frog"
  },
  "tu.si": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the brother points at the frog"
  },
  "tu.no": {
   "world": [4.2426, 5.4393, 0],
   "screen": [118, 164],
   "zoom": 1,
   "crop": [20, 112, 196, 104],
   "what": "the brother points at himself"
  }
 },
 "level": [
  {
   "w": "abuela",
   "index": 1,
   "picture": "mama.si",
   "old": [70.33, 70, 54.34, 60],
   "crop": [48, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "abuela",
   "index": 2,
   "picture": "papa.si",
   "old": [104.33, 70, 54.34, 60],
   "crop": [82, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "abuela",
   "index": 3,
   "picture": "hermana.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "jugo",
   "index": 3,
   "picture": "papa.si",
   "old": [104.33, 70, 54.34, 60],
   "crop": [82, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "se sienta",
   "index": 3,
   "picture": "abuelo.si",
   "old": [154.33, 70, 54.34, 60],
   "crop": [132, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "quiero",
   "index": 3,
   "picture": "mama.si",
   "old": [70.33, 70, 54.34, 60],
   "crop": [48, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "mamá",
   "index": 0,
   "picture": "mama.si",
   "old": [70.33, 70, 54.34, 60],
   "crop": [48, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "mamá",
   "index": 1,
   "picture": "papa.si",
   "old": [104.33, 70, 54.34, 60],
   "crop": [82, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "mamá",
   "index": 2,
   "picture": "abuelo.si",
   "old": [154.33, 70, 54.34, 60],
   "crop": [132, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "mamá",
   "index": 3,
   "picture": "hermana.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "abuelo",
   "index": 0,
   "picture": "abuelo.si",
   "old": [154.33, 70, 54.34, 60],
   "crop": [132, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "abuelo",
   "index": 1,
   "picture": "abuelo.no",
   "old": [154.33, 70, 54.34, 60],
   "crop": [132, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "abuelo",
   "index": 2,
   "picture": "papa.si",
   "old": [104.33, 70, 54.34, 60],
   "crop": [82, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "abuelo",
   "index": 3,
   "picture": "hermano.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "familia",
   "index": 0,
   "picture": "familia.si",
   "old": [79.15, 60, 81.69, 90.2],
   "crop": [22, 52, 196, 104],
   "zoom": 1
  },
  {
   "w": "familia",
   "index": 1,
   "picture": "mama.si",
   "old": [70.33, 70, 54.34, 60],
   "crop": [48, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "familia",
   "index": 2,
   "picture": "hermano.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "hermana",
   "index": 0,
   "picture": "hermana.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "hermana",
   "index": 1,
   "picture": "hermano.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "hermana",
   "index": 2,
   "picture": "hermana.no",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "hermana",
   "index": 3,
   "picture": "bebe.si",
   "old": [42.83, 146, 54.34, 60],
   "crop": [23, 152, 98, 52],
   "zoom": 2
  },
  {
   "w": "tú",
   "index": 0,
   "picture": "tu.si",
   "old": [81.95, 132, 72.09, 79.6],
   "crop": [20, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "tú",
   "index": 1,
   "picture": "tu.no",
   "old": [81.95, 132, 72.09, 79.6],
   "crop": [20, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "tú",
   "index": 2,
   "picture": "yo.si",
   "old": [81.95, 132, 72.09, 79.6],
   "crop": [20, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "tú",
   "index": 3,
   "picture": "hermano.si",
   "old": [93.33, 92, 54.34, 60],
   "crop": [22, 70, 196, 104],
   "zoom": 1
  },
  {
   "w": "niña",
   "index": 3,
   "picture": "abuelo.si",
   "old": [154.33, 70, 54.34, 60],
   "crop": [132, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "amigo",
   "index": 3,
   "picture": "mama.si",
   "old": [70.33, 70, 54.34, 60],
   "crop": [48, 77, 98, 52],
   "zoom": 2
  },
  {
   "w": "ven",
   "index": 3,
   "picture": "papa.si",
   "old": [104.33, 70, 54.34, 60],
   "crop": [82, 77, 98, 52],
   "zoom": 2
  }
 ],
 "clips": {
  "foto.0": {
   "thing": "fotos",
   "face": "the opening of frame 0",
   "world": [
    [0.05, 3.5355, 2.376],
    [0.05, 2.6652, 2.0207],
    [0.05, 2.6652, 0.9993],
    [0.05, 3.5355, 1.3546]
   ],
   "screen": [
    [75, 54],
    [91, 54],
    [91, 77],
    [75, 77]
   ],
   "box": [75, 54, 16, 23],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 0 is drawn clipped to this quad (screen), set before the translate"
  },
  "foto.0.torcida": {
   "thing": "fotos",
   "face": "the opening of frame 0, crooked",
   "world": [
    [0.05, 3.6717, 2.3325],
    [0.05, 2.8264, 2.1563],
    [0.05, 2.529, 1.0427],
    [0.05, 3.3744, 1.2189]
   ],
   "screen": [
    [72.4957, 56.2312],
    [88.0371, 52.428],
    [93.5043, 74.7688],
    [77.9629, 78.572]
   ],
   "box": [72, 52, 22, 27],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 0 is drawn clipped to this quad (screen), set before the translate"
  },
  "foto.1": {
   "thing": "fotos",
   "face": "the opening of frame 1",
   "world": [
    [0.05, 2.3389, 2.376],
    [0.05, 1.4686, 2.0207],
    [0.05, 1.4686, 0.9993],
    [0.05, 2.3389, 1.3546]
   ],
   "screen": [
    [97, 43],
    [113, 43],
    [113, 66],
    [97, 66]
   ],
   "box": [97, 43, 16, 23],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 1 is drawn clipped to this quad (screen), set before the translate"
  },
  "foto.1.torcida": {
   "thing": "fotos",
   "face": "the opening of frame 1, crooked",
   "world": [
    [0.05, 2.4751, 2.3325],
    [0.05, 1.6298, 2.1563],
    [0.05, 1.3324, 1.0427],
    [0.05, 2.1777, 1.2189]
   ],
   "screen": [
    [94.4957, 45.2312],
    [110.0371, 41.428],
    [115.5043, 63.7688],
    [99.9629, 67.572]
   ],
   "box": [94, 41, 22, 27],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 1 is drawn clipped to this quad (screen), set before the translate"
  },
  "foto.2": {
   "thing": "fotos",
   "face": "the opening of frame 2",
   "world": [
    [0.05, 1.1422, 2.376],
    [0.05, 0.272, 2.0207],
    [0.05, 0.272, 0.9993],
    [0.05, 1.1422, 1.3546]
   ],
   "screen": [
    [119, 32],
    [135, 32],
    [135, 55],
    [119, 55]
   ],
   "box": [119, 32, 16, 23],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 2 is drawn clipped to this quad (screen), set before the translate"
  },
  "foto.2.torcida": {
   "thing": "fotos",
   "face": "the opening of frame 2, crooked",
   "world": [
    [0.05, 1.2785, 2.3325],
    [0.05, 0.4331, 2.1563],
    [0.05, 0.1357, 1.0427],
    [0.05, 0.9811, 1.2189]
   ],
   "screen": [
    [116.4957, 34.2312],
    [132.0371, 30.428],
    [137.5043, 52.7688],
    [121.9629, 56.572]
   ],
   "box": [116, 30, 22, 27],
   "what": "sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame 2 is drawn clipped to this quad (screen), set before the translate"
  }
 },
 "front": {
  "how": "sala.js:114 drew the low table in the list sorted by y (its y 165): everyone whose y is less is drawn before it and covered by it. The table is in the set now; at its place in the list, for each person (and the frog) drawn before it, the set's own pixels of the table (sala-set.html part \"mesita\", PART_TAGS) are drawn again inside that character's box, only where that pixel is nearer to the camera than the character: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the floor point under the character's feet (people: unproject(x, y - 1); the frog: unproject(q.x + 16, q.y + 25)). The cake and the camera are drawn after it, as before. \"Behind the table\" is that depth test, not the row",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "parts": {
   "mesita": {
    "line": 114,
    "sortY": 165,
    "replaces": "c.drawImage(spr(\"mesita\",mkMesita),98,148+(W.golpe&&F-W.golpe<4?-2:0))",
    "boxes": "people: [x - 24, y - alto - 2, 48, alto + 3]; the frog: frogBox"
   }
  }
 },
 "shadows": {
  "coqui": {
   "radius": 0.45,
   "at": "the floor point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))",
   "when": "W.cq.vis and al > .5",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "grown": 0.35,
    "nino": 0.3,
    "bebe": 0.25
   },
   "at": "the floor point under their feet on screen (unproject(x, y - 1))",
   "when": "visible (vis !== 0, al > .5) and standing (not sent); the baby on the floor too, not on mamá's lap (bebe.z)",
   "cast": "grown and children: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); the baby: castShadow(g.x, g.y, .2, .25)"
  },
  "dropped": "sala.js:101 rana()'s dotted shadow under the frog is not drawn: the engine casts his"
 },
 "dropped": [
  "sala.js:107 c.drawImage(spr(\"sala\", bg)) -> the set, for setKey(W)",
  "sala.js:109 the lamp, :110 the sofa and the armchair, :111 manta() (the baby's blanket) -> the set (nothing covered anyone in the old: they came before everyone)",
  "sala.js:114 the low table sprite -> the set (and front: its pixels again at that place in the list); its jump on W.golpe is not drawn",
  "sala.js:53 and :60 the frames' wood, paper and nail -> the set (marco() draws only the photo in each)",
  "sala.js:32 the potted plant in bg() -> the set, on the floor by the back wall, clear of every touch box",
  "sala.js:101 the frog's dotted shadow -> the engine's cast shadow"
 ],
 "moves": [
  {
   "line": 198,
   "act": "corren",
   "src": "mueve(\"hermano\",94,198,10),mueve(\"hermana\",66,203,10)",
   "to": "mueve(\"hermano\",80,200,10),mueve(\"hermana\",60,204,10)",
   "places": [
    {
     "who": "hermano",
     "old": [94, 198],
     "new": [80, 200],
     "world": [5.1129, 8.3765, 0]
    },
    {
     "who": "hermana",
     "old": [66, 203],
     "new": [60, 204],
     "world": [4.7866, 9.138, 0]
    }
   ],
   "why": "acts.corren: the children stop clear of the frog in the middle (the hint hand, pointing at a child, hung over the frog's face: la-foto beats.8)"
  },
  {
   "line": 214,
   "act": "solo",
   "src": "mueve(o.quien,120,146),mueve(otro,72,206)",
   "to": "mueve(o.quien,120,136),mueve(otro,56,206)",
   "places": [
    {
     "who": "whoever",
     "old": [120, 146],
     "new": [120, 136],
     "world": [2.7196, 3.8075, 0]
    },
    {
     "who": "whoever",
     "old": [72, 206],
     "new": [56, 206],
     "world": [4.7866, 9.3556, 0]
    }
   ],
   "why": "acts.solo: the child alone stands between the sofa and the low table, the other one at the left: the answer cards over the frog covered both (la-foto beats.41)"
  },
  {
   "line": 228,
   "act": "inicio8",
   "src": "a.x=156;a.y=200;a.dir=-1;b.x=84;b.y=200;",
   "to": "a.x=184;a.y=200;a.dir=-1;b.x=56;b.y=200;",
   "places": [
    {
     "who": "hermano",
     "old": [156, 200],
     "new": [184, 200],
     "world": [7.9414, 5.5481, 0]
    },
    {
     "who": "hermana",
     "old": [84, 200],
     "new": [56, 200],
     "world": [4.4602, 9.0292, 0]
    }
   ],
   "why": "acts.inicio8: the children stand either side of the frog, out from under the answer cards (quien-eres-tu beats.10, 13, 22, 28)"
  },
  {
   "line": 236,
   "act": "suelta",
   "src": "mueve(o.quien,o.quien===\"hermano\"?152:86,200)",
   "to": "mueve(o.quien,o.quien===\"hermano\"?184:56,200)",
   "places": [
    {
     "who": "hermano",
     "old": [152, 200],
     "new": [184, 200],
     "world": [7.9414, 5.5481, 0]
    },
    {
     "who": "hermana",
     "old": [86, 200],
     "new": [56, 200],
     "world": [4.4602, 9.0292, 0]
    }
   ],
   "why": "acts.suelta: back to their places either side of the frog (as inicio8)"
  },
  {
   "line": 247,
   "act": "final8",
   "src": "mueve(\"abuelo\",150,170)",
   "to": "mueve(\"abuelo\",172,178)",
   "places": [
    {
     "who": "abuelo",
     "old": [150, 170],
     "new": [172, 178],
     "world": [6.4184, 4.6778, 0]
    }
   ],
   "why": "acts.final8, the cup empty: abuelo asks for more clear of mamá and the baby (his \"q\" bubble was on their faces)"
  },
  {
   "line": 247,
   "act": "final8",
   "src": "mueve(\"abuela\",182,172)",
   "to": "mueve(\"abuela\",200,176)",
   "places": [
    {
     "who": "abuela",
     "old": [182, 172],
     "new": [200, 176],
     "world": [7.0711, 3.8075, 0]
    }
   ],
   "why": "acts.final8: abuela fills his cup from his side (moved with him)"
  },
  {
   "line": 224,
   "act": "final7",
   "src": "mueve(\"abuelo\",172,160)",
   "to": "mueve(\"abuelo\",186,164)",
   "places": [
    {
     "who": "abuelo",
     "old": [172, 160],
     "new": [186, 164],
     "world": [6.0376, 3.5355, 0]
    }
   ],
   "why": "acts.final7: abuelo stands a little further out, so that papá's bubble has a place under the photo of everyone (W.retrato) clear of every face"
  },
  {
   "line": 77,
   "act": "lados",
   "src": "JUNTOS=[[96,196],[144,196]]",
   "to": "JUNTOS=[[80,196],[160,196]]",
   "places": [
    {
     "who": "whoever",
     "old": [96, 196],
     "new": [80, 196],
     "world": [4.8954, 8.1589, 0]
    },
    {
     "who": "whoever",
     "old": [144, 196],
     "new": [160, 196],
     "world": [7.0711, 5.9832, 0]
    }
   ],
   "why": "JUNTOS: two people together at the front, wider apart: the hint hand, pointing at one of them, hung over the frog's face (la-foto beats.18). The frog hops beside them (acts.junto) relative to them, so he moves with them"
  }
 ],
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as sala.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
  "rects": {
   "hola": [-16, -46, 34, 44],
   "amor": [-14, -38, 30, 36],
   "como": [-32, -40, 66, 38],
   "bien": [-14, -40, 30, 38],
   "mal": [-14, -40, 30, 38],
   "quien": [-22, -40, 46, 38],
   "lluvia": [-22, -40, 46, 38],
   "bizcocho": [-16, -40, 34, 38],
   "q": [-12, -40, 26, 38],
   "gafas_q": [-22, -40, 46, 38],
   "feliz": [-14, -40, 30, 38]
  }
 },
 "talk": {
  "what": "where a bubble goes (sala.js talkAt for a person, line 124 for the frog). The old put it over the head; with the room seen from above, people stand in front of the sofa and a bubble over a head lands on the face of whoever sits behind. So: the first of these places whose bubble is wholly inside the view, clear of the corner cards shown (hud: the slices, the coffee, the camera's window, the photo of everyone) and of every face (each visible person's and the frog's, its own too); if none is, the first",
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
  "faces": "a person's face: [x - 6, y - alto + 5 (the baby: + 4), 12, 10] (eyes to chin, not the hair); the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heads": {
   "mama": {
    "top": -54,
    "head": 0
   },
   "mama.sent": {
    "top": -47,
    "head": 0
   },
   "papa": {
    "top": -53,
    "head": 0
   },
   "papa.sent": {
    "top": -46,
    "head": 0
   },
   "abuelo": {
    "top": -51,
    "head": 0
   },
   "abuelo.sent": {
    "top": -44,
    "head": 0
   },
   "hermano": {
    "top": -41,
    "head": 0
   },
   "hermano.sent": {
    "top": -38,
    "head": 0
   },
   "hermana": {
    "top": -41,
    "head": 0
   },
   "hermana.sent": {
    "top": -38,
    "head": 0
   },
   "abuela": {
    "top": -50,
    "head": 0
   },
   "bebe": {
    "top": -28,
    "head": 0
   }
  },
  "headsWhat": "each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the family sprites drawn at -PX)",
  "boards": "in the 196 x 216 display, then + the view's x0: W.plato [2, 2, 80, 31]; W.cafe [2, 2, 46 + 13 * aciertos, 38]; W.visor [2, 2, 52, 52]; W.retrato [29, 5, 138, 90]"
 },
 "code": [
  {
   "line": 17,
   "old": "bg(): the room",
   "to": "dropped: the set"
  },
  {
   "line": 32,
   "old": "bg(): the plant pot at 212, 94",
   "to": "dropped: the set (planta)"
  },
  {
   "line": 49,
   "old": "manta: fr(g,49,177,58,22) fr(g,50,178,56,20) fr(g,50,178,56,1); the white squares 52..104, 180..197",
   "to": "dropped: the set (manta, the same place on the screen)"
  },
  {
   "line": 52,
   "old": "marco: x = 76 + i * 24, y = 38; translate(x + 10, y + 2); rotate(.24 + .05 sin(F / 6 + i)) when !f.ok",
   "to": {
    "points": ["foto.0", "foto.1", "foto.2", "foto.0.torcida", "foto.1.torcida", "foto.2.torcida"],
    "new": [
     [
      [83, 52],
      [79.791, 52.3869],
      -0.24
     ],
     [
      [105, 41],
      [101.791, 41.3869],
      -0.24
     ],
     [
      [127, 30],
      [123.791, 30.3869],
      -0.24
     ]
    ]
   },
   "note": "translate to points.foto.i (or foto.i.torcida, then rotate by its angle: the frame turned about its middle, baked crooked, no swing). Everything marco() draws of a photo keeps its frame coordinates"
  },
  {
   "line": 53,
   "old": "marco: fr(g,-11,-1,22,26,OUT) fr(g,-10,0,20,24,wood) fr(g,-10,0,20,1,wood) fr(g,-8,2,16,20, f ? \"#BFE0F0\" : \"#FBF0D2\")",
   "to": "the frame and the empty paper: dropped (the set: the frame is [-10, 0, 20, 27] in these coordinates, the opening [-8, 2, 16, 23]). With a photo (f): fr(g, -14, -6, 28, 34, \"#BFE0F0\") inside the clip, the photo's ground"
  },
  {
   "line": 54,
   "old": "marco: g.rect(-8,2,16,20); g.clip()",
   "to": {
    "clips": ["foto.0", "foto.1", "foto.2", "foto.0.torcida", "foto.1.torcida", "foto.2.torcida"]
   },
   "note": "the clip is the quad of the set's opening, in picture coordinates: set it before the translate"
  },
  {
   "line": 55,
   "old": "marco: the slippers: fr(g,-8,14,16,8) and the shoes at [-6,10], [1,11]",
   "to": "relative to the frame: unchanged"
  },
  {
   "line": 58,
   "old": "marco: the frog's foot: fr(g,5,17,4,5) fr(g,6,18,3,4)",
   "to": "relative to the frame: unchanged"
  },
  {
   "line": 60,
   "old": "marco: the nail fr(g,0,-3,1,3,OUT)",
   "to": "dropped: the set (each frame hangs on a wire from a nail, the nail 3 rows over the frame's top: points foto.i nail)"
  },
  {
   "line": 75,
   "old": "SITIO.mama [97,127,1]",
   "to": {
    "spot": "sitio.mama",
    "new": [97, 127, 1]
   }
  },
  {
   "line": 75,
   "old": "SITIO.papa [131,127,1]",
   "to": {
    "spot": "sitio.papa",
    "new": [131, 127, 1]
   }
  },
  {
   "line": 75,
   "old": "SITIO.abuelo [181,127,1]",
   "to": {
    "spot": "sitio.abuelo",
    "new": [181, 127, 1]
   }
  },
  {
   "line": 75,
   "old": "SITIO.bebe [70,193]",
   "to": {
    "spot": "sitio.bebe",
    "new": [70, 193]
   }
  },
  {
   "line": 75,
   "old": "SITIO.abuela [42,168]",
   "to": {
    "spot": "sitio.abuela",
    "new": [42, 168]
   }
  },
  {
   "line": 75,
   "old": "SITIO.hermano [150,198]",
   "to": {
    "spot": "sitio.hermano",
    "new": [150, 198]
   }
  },
  {
   "line": 75,
   "old": "SITIO.hermana [180,198]",
   "to": {
    "spot": "sitio.hermana",
    "new": [180, 198]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.puerta [30,104,0.7]",
   "to": {
    "spot": "frog.puerta",
    "new": [30, 104, 0.7]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.centro [104,183,1]",
   "to": {
    "spot": "frog.centro",
    "new": [104, 183, 1]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.huele [72,146,0.9]",
   "to": {
    "spot": "frog.huele",
    "new": [72, 146, 0.9]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.abuela [58,155,1]",
   "to": {
    "spot": "frog.abuela",
    "new": [58, 155, 1]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.mama [82,125,0.9]",
   "to": {
    "spot": "frog.mama",
    "new": [82, 125, 0.9]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.papa [116,125,0.9]",
   "to": {
    "spot": "frog.papa",
    "new": [116, 125, 0.9]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.abuelo [166,125,0.9]",
   "to": {
    "spot": "frog.abuelo",
    "new": [166, 125, 0.9]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.bebe [88,175,1]",
   "to": {
    "spot": "frog.bebe",
    "new": [88, 175, 1]
   }
  },
  {
   "line": 76,
   "old": "LUGAR.izq [44,183,1]",
   "to": {
    "spot": "frog.izq",
    "new": [44, 183, 1]
   }
  },
  {
   "line": 77,
   "old": "PARADOS[0] [100,136]",
   "to": {
    "spot": "parados.0",
    "new": [100, 136]
   }
  },
  {
   "line": 77,
   "old": "PARADOS[1] [140,136]",
   "to": {
    "spot": "parados.1",
    "new": [140, 136]
   }
  },
  {
   "line": 77,
   "old": "APARTE[0] [70,198]",
   "to": {
    "spot": "aparte.0",
    "new": [70, 198]
   }
  },
  {
   "line": 77,
   "old": "APARTE[1] [170,198]",
   "to": {
    "spot": "aparte.1",
    "new": [170, 198]
   }
  },
  {
   "line": 77,
   "old": "JUNTOS[0] [96,196]",
   "to": {
    "spot": "juntos.0",
    "new": [80, 196]
   },
   "note": "moved (see moves, line 77)"
  },
  {
   "line": 77,
   "old": "JUNTOS[1] [144,196]",
   "to": {
    "spot": "juntos.1",
    "new": [160, 196]
   },
   "note": "moved (see moves, line 77)"
  },
  {
   "line": 77,
   "old": "CAMARA [198,176]",
   "to": {
    "spot": "camara",
    "new": [198, 176]
   }
  },
  {
   "line": 79,
   "old": "caja(id): [x - 11, y - alto(id), 22, alto(id)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 82,
   "old": "box bizcocho [106,138,30,16]",
   "to": {
    "thing": "bizcocho",
    "box": [107, 142, 30, 16]
   }
  },
  {
   "line": 82,
   "old": "box mesita [98,148,46,18]",
   "to": {
    "thing": "mesita",
    "box": [98, 142, 47, 28]
   }
  },
  {
   "line": 82,
   "old": "box sofa [68,84,92,44]",
   "to": {
    "thing": "sofa",
    "box": [68, 81, 92, 51]
   }
  },
  {
   "line": 82,
   "old": "box butaca [160,86,42,42]",
   "to": {
    "thing": "butaca",
    "box": [160, 88, 42, 39]
   }
  },
  {
   "line": 83,
   "old": "box fotos [64,34,82,30]",
   "to": {
    "thing": "fotos",
    "box": [70, 27, 70, 54]
   }
  },
  {
   "line": 83,
   "old": "box lampara [146,62,20,64]",
   "to": {
    "thing": "lampara",
    "box": [129, 6, 26, 81]
   }
  },
  {
   "line": 83,
   "old": "box puerta [20,42,42,80]",
   "to": {
    "thing": "puerta",
    "box": [34, 50, 36, 93]
   }
  },
  {
   "line": 83,
   "old": "box ventana [160,32,56,54]",
   "to": {
    "thing": "ventana",
    "box": [159, 18, 57, 77]
   }
  },
  {
   "line": 83,
   "old": "box sala [0,122,240,94]",
   "to": {
    "thing": "sala",
    "box": [1, 123, 238, 119]
   }
  },
  {
   "line": 88,
   "old": "gente abuela: scale(-1,1) when dir < 0; drawImage(im,-30,0) at x, y - 50",
   "to": "relative to her: unchanged"
  },
  {
   "line": 91,
   "old": "gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 92,
   "old": "the Z of sleep: rects [0,0,4,1] [3,1,1,1] [2,2,1,1] [1,3,1,1] [0,4,4,1] at x + 6, y - h - 5",
   "to": "relative to abuelo: unchanged"
  },
  {
   "line": 93,
   "old": "taza at x + 13 d, y - h + 26",
   "to": "relative to abuelo: unchanged"
  },
  {
   "line": 99,
   "old": "taza: the coffee heights [0,2,4,6]",
   "to": "not a place: unchanged"
  },
  {
   "line": 101,
   "old": "rana: the dotted shadow at b.x + 2, q.y + 25",
   "to": "dropped: the engine casts his shadow (shadows.coqui)"
  },
  {
   "line": 105,
   "old": "bub2: c.scale(2,2), bub(c,k,0,0,a)",
   "to": "relative: unchanged (the bubbles are drawn at twice their size)"
  },
  {
   "line": 107,
   "old": "c.drawImage(spr(\"sala\",bg),0,0)",
   "to": "dropped: the set, for setKey(W)"
  },
  {
   "line": 108,
   "old": "marco(c, i, W.fotos[i])",
   "to": "see line 52"
  },
  {
   "line": 109,
   "old": "the lamp at 146, 62",
   "to": "dropped: the set (lampara; luz is a set parameter)"
  },
  {
   "line": 110,
   "old": "the sofa at 68, 84; the armchair at 160, 86",
   "to": "dropped: the set (sofa, butaca)"
  },
  {
   "line": 111,
   "old": "manta(c)",
   "to": "dropped: the set"
  },
  {
   "line": 114,
   "old": "the low table at 98, 148 (sort y 165); bizcocho(c, 107, 138, n); the camera fr(c,113,139,16,10) fr(c,114,140,14,8) fr(c,118,142,5,5)",
   "to": {
    "front": "mesita",
    "sortY": 165,
    "bizcocho": [108, 142],
    "camMesa": [113, 143]
   },
   "note": "the table: front (its own pixels again, depth-tested per character drawn before it); the cake at points.bizcocho; the camera's three rects at points.camMesa + (0, 0), (1, 1), (5, 3)"
  },
  {
   "line": 116,
   "old": "tapaojos: the hands at b.x + b.w * u, b.y + 7 s",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 120,
   "old": "borroso: drawImage(sc, 0, 0, SW, SH, 0, 0, 20, 18), smoothing on",
   "to": "smoothing.places[0]: the whole picture, unchanged"
  },
  {
   "line": 121,
   "old": "borroso: drawImage(t, 0, 0, 20, 18, 0, 0, SW, SH), smoothing on",
   "to": "smoothing.places[1]: unchanged"
  },
  {
   "line": 122,
   "old": "flash: fillRect(0, 0, SW, SH)",
   "to": "the whole picture: unchanged"
  },
  {
   "line": 126,
   "old": "talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 131,
   "old": "hud retrato at ((DW - 136) / 2, 6)",
   "to": "display: unchanged"
  },
  {
   "line": 132,
   "old": "hud plato tarjeta(3,3,78,29) ...",
   "to": "display: unchanged"
  },
  {
   "line": 137,
   "old": "hud visor: smoothing on",
   "to": "smoothing.places[2]: unchanged"
  },
  {
   "line": 162,
   "old": "destapa stars [108,134] [132,134] [120,128]",
   "to": {
    "point": "destapa.estrellas",
    "new": [
     [109, 138],
     [133, 138],
     [121, 132]
    ]
   }
  },
  {
   "line": 163,
   "old": "tres: vuelaA(120,140,50,24)",
   "to": {
    "from": [121, 144],
    "to": [50, 24]
   }
  },
  {
   "line": 174,
   "old": "abda: vuelaA(x.x, x.y - 30, 50, 24, 1)",
   "to": {
    "point": "hud.plato",
    "new": [50, 24]
   }
  },
  {
   "line": 175,
   "old": "abda: to h[0] + (bebe ? 22 : -2), bebe ? h[1] - 4 : 150",
   "to": "relative to SITIO; the row 150 is a floor row: unchanged (the floor rule)"
  },
  {
   "line": 180,
   "old": "suplato: mueve(\"abuela\",158,200)",
   "to": {
    "floor": [7.2342, 6.2552, 0],
    "new": [158, 200]
   }
  },
  {
   "line": 183,
   "old": "final6: vuelaA(b.x, b.y - 14, q.x + 16, q.y + 8, 1, 0.8)",
   "to": "relative: unchanged"
  },
  {
   "line": 184,
   "old": "final6 stars [60,30] [180,34] [120,22] [96,44] [150,40]",
   "to": "screen effect: unchanged (over the walls' tops and the backdrop)"
  },
  {
   "line": 188,
   "old": "mueve / x, y [150,172]",
   "to": {
    "floor": [5.4937, 4.9497, 0],
    "new": [150, 172]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 193,
   "old": "mueve / x, y [150,200]",
   "to": {
    "floor": [7.0167, 6.4727, 0],
    "new": [150, 200]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 193,
   "old": "mueve / x, y [182,200]",
   "to": {
    "floor": [7.887, 5.6025, 0],
    "new": [182, 200]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 198,
   "old": "mueve / x, y [94,198]",
   "to": {
    "floor": [5.1129, 8.3765, 0],
    "new": [80, 200]
   },
   "note": "moved (see moves, line 198)"
  },
  {
   "line": 198,
   "old": "mueve / x, y [66,203]",
   "to": {
    "floor": [4.7866, 9.138, 0],
    "new": [60, 204]
   },
   "note": "moved (see moves, line 198)"
  },
  {
   "line": 214,
   "old": "mueve / x, y [120,146]",
   "to": {
    "floor": [2.7196, 3.8075, 0],
    "new": [120, 136]
   },
   "note": "moved (see moves, line 214)"
  },
  {
   "line": 214,
   "old": "mueve / x, y [72,206]",
   "to": {
    "floor": [4.7866, 9.3556, 0],
    "new": [56, 206]
   },
   "note": "moved (see moves, line 214)"
  },
  {
   "line": 224,
   "old": "mueve / x, y [98,146]",
   "to": {
    "floor": [2.6652, 4.9497, 0],
    "new": [98, 146]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 224,
   "old": "mueve / x, y [142,146]",
   "to": {
    "floor": [3.8619, 3.7531, 0],
    "new": [142, 146]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 224,
   "old": "mueve / x, y [172,160]",
   "to": {
    "floor": [6.0376, 3.5355, 0],
    "new": [186, 164]
   },
   "note": "moved (see moves, line 224)"
  },
  {
   "line": 224,
   "old": "mueve / x, y [66,160]",
   "to": {
    "floor": [2.5565, 6.5815, 0],
    "new": [66, 160]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 224,
   "old": "mueve / x, y [140,190]",
   "to": {
    "floor": [6.2008, 6.2008, 0],
    "new": [140, 190]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 224,
   "old": "mueve / x, y [100,190]",
   "to": {
    "floor": [5.1129, 7.2886, 0],
    "new": [100, 190]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 224,
   "old": "mueve / x, y [106,124]",
   "to": {
    "floor": [1.6862, 3.5355, 0],
    "new": [106, 124]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 228,
   "old": "mueve / x, y [156,200]",
   "to": {
    "floor": [7.9414, 5.5481, 0],
    "new": [184, 200]
   },
   "note": "moved (see moves, line 228)"
  },
  {
   "line": 228,
   "old": "mueve / x, y [84,200]",
   "to": {
    "floor": [4.4602, 9.0292, 0],
    "new": [56, 200]
   },
   "note": "moved (see moves, line 228)"
  },
  {
   "line": 228,
   "old": "mueve / x, y [190,150]",
   "to": {
    "floor": [5.3849, 2.6652, 0],
    "new": [190, 150]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 228,
   "old": "mueve / x, y [97,112]",
   "to": {
    "floor": [0.7887, 3.1276, 0],
    "new": [97, 112]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 230,
   "old": "mueve / x, y [162,176]",
   "to": {
    "floor": [6.0376, 4.841, 0],
    "new": [162, 176]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 231,
   "old": "mueve / x, y [192,180]",
   "to": {
    "floor": [7.0711, 4.2426, 0],
    "new": [192, 180]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 235,
   "old": "mueve / x, y [192,180]",
   "to": {
    "floor": [7.0711, 4.2426, 0],
    "new": [192, 180]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 236,
   "old": "mueve / x, y [152,200]",
   "to": {
    "floor": [7.9414, 5.5481, 0],
    "new": [184, 200]
   },
   "note": "moved (see moves, line 236)"
  },
  {
   "line": 236,
   "old": "mueve / x, y [86,200]",
   "to": {
    "floor": [4.4602, 9.0292, 0],
    "new": [56, 200]
   },
   "note": "moved (see moves, line 236)"
  },
  {
   "line": 247,
   "old": "mueve / x, y [150,170]",
   "to": {
    "floor": [6.4184, 4.6778, 0],
    "new": [172, 178]
   },
   "note": "moved (see moves, line 247)"
  },
  {
   "line": 247,
   "old": "mueve / x, y [182,172]",
   "to": {
    "floor": [7.0711, 3.8075, 0],
    "new": [200, 176]
   },
   "note": "moved (see moves, line 247)"
  },
  {
   "line": 198,
   "old": "corren: a.x=40;a.y=126;b.x=34;b.y=124 (the children appear at the door)",
   "to": {
    "spots": ["puerta.hermano", "puerta.hermana"],
    "new": [
     [61, 117],
     [51, 122]
    ]
   },
   "note": "in the new doorway, on its threshold"
  },
  {
   "line": 199,
   "old": "corren: the baby to mamá's lap: bb.x = 70 + (m.x - 70) i / 6 ..., then m.x, m.y - 15",
   "to": "from SITIO.bebe, relative to mamá: unchanged"
  },
  {
   "line": 205,
   "old": "junto: cx = p.x + (p.x < 120 ? -24 : 24); s = p.y < 150 ? .9 : 1; hopTo(cx - 16, p.y + 5 - 27, 2, s)",
   "to": "the 120 is the room's middle and 150 a floor row: unchanged (the floor rule); relative to the person"
  },
  {
   "line": 207,
   "old": "prueba: a star at p.x, p.y - 50",
   "to": "relative: unchanged"
  },
  {
   "line": 209,
   "old": "dispara: the star at [86 + i * 24, 50]",
   "to": {
    "points": ["foto.0", "foto.1", "foto.2"],
    "new": [
     [83, 66],
     [105, 55],
     [127, 44]
    ]
   },
   "note": "over the middle of frame i (the old 86 + i * 24, 50 was the old frame's)"
  },
  {
   "line": 221,
   "old": "final7 stars at [86 + i * 24, 50]",
   "to": {
    "new": [
     [83, 66],
     [105, 55],
     [127, 44]
    ]
   },
   "note": "over the middle of frame i, as line 209"
  },
  {
   "line": 235,
   "old": "tapa: Math.abs(ab.x - 120) < 60; to q.x + 16, q.y + 22",
   "to": "the room's middle: unchanged; relative to the frog"
  },
  {
   "line": 239,
   "old": "abva: p.x + (p.x < 120 ? -22 : 22), p.y + 10",
   "to": "relative: unchanged"
  },
  {
   "line": 241,
   "old": "espejuelos: m.x + 9, m.y - 26; m.x + 28, m.y + 6; a star at ab.x, ab.y - 58",
   "to": "relative: unchanged"
  },
  {
   "line": 245,
   "old": "final8 stars [60,30] [180,34] [120,22] [96,44] [150,40]",
   "to": "screen effect: unchanged"
  },
  {
   "line": 259,
   "old": "CAM.wide [22,0,196,216]",
   "to": {
    "view": "wide",
    "zoom": 1,
    "x0": 22
   }
  },
  {
   "line": 259,
   "old": "CAM.sofa [52,48,150,165.3]",
   "to": {
    "view": "sofa",
    "zoom": 1,
    "x0": 22
   }
  },
  {
   "line": 259,
   "old": "heartAt [107,6]",
   "to": {
    "point": "corazon",
    "new": [107, 6]
   }
  },
  {
   "line": 260,
   "old": "fresh(): cq at LUGAR.centro",
   "to": "LUGAR: line 76"
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: sala's fresh() puts him at LUGAR.centro"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": "a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 16 things (old 16), 9 frog places (old 9), 2 views (old 2), 46 positions (old 46), 11 review pairs, 28 level pictures (old 28), 94 places of sala.js named in code",
   "hops: 36 pairs of LUGAR places, every count as the old one (round(d / 30), 1 to 4, kit.js acts.ir); the places keep their screen points, so every distance is the old one",
   "decor: no pixel of the plant inside any set thing's touch box (every baked state)",
   "wide view (x0 22): the door, its open leaf and who stands in it from x 34 to 72 (12 px from the left side), from row 50",
   "views: wide zoom 1 x0 22, sofa zoom 1 x0 22: a change of view moves nothing",
   "a strip of wall: 16 px of wall over the door's frame, 10 px over the window's curtain rod, before the wall's cut top",
   "seats: an empty sofa shows 6 rows of its seat, the armchair 6; the curtains hang from a rod on two brackets",
   "frames: in all 5 baked states each of the 3 hangs on the left wall from its own nail, seen, on a wire (9 px of wire at the least), the whole frame seen (nothing of the set over it), its opening its paper; no two frames share a pixel; inside their touch box [70,27,70,54] the set drew only the wall, the frames and 25 px of the lamp's foot in its corner (the frames are hit first there: COSAS order). Straight ones upright (angle 0), a crooked one turned -0.24 rad (counterclockwise, 13.75 degrees) about its middle (its corners 4.02 px from the upright one's); every frame pixel on the left wall, .85 or more over the floor",
   "lamp: it stands in the corner (0.34,0.22); its foot shows (66 px of the lamp in the 13 x 7 round its front edge), 1 row of floor in front of it before the sofa's back",
   "door: through it, from the threshold up, the porch's tiles and edge (827 px) then the lawn beyond (152 px), in each of its 23 columns",
   "table: its top spans x 98..144, rows 147..156; the cake's dish [104,151,34,3] and the camera [113,143,16,10] stand on it, their bottoms 3 and 4 rows from its front edge; plain floor and sofa behind them",
   "table: the cake and the camera are never on it at once (1101 moments)",
   "photos: 89 photos of a person at 44 distinct moments (hermana, hermano, mama, papa): each whole (the 16 x 22 of the sprite, at 1:1, upright or turned with its crooked frame) inside its frame's opening, 0 px from its edge at the least (its sides on the opening's: 16 wide in 16, as the old); no corner card (but the photo of everyone) and no one over any pixel of it",
   "standing over sitting: at 139 distinct moments no standing person's sprite covers more of a sitting person's face (eyes to chin) than the old picture did there (none does, nor in the old); one stands before a sitting one's body, not the face, as abuela before abuelo, abuela before mama, abuela before papa, abuelo before bebe, hermana before papa, hermano before papa, papa before mama, every one as in the old picture",
   "asks: 45 distinct asks: every hint frame (box +- 12) wholly inside the view (0 px from its edge at the least), the hint hand on no face; 16 answer cards inside the view, over no one's body (no opaque pixel of anyone's sprite, in their pose, under a card)",
   "NOT the scene's: the hand juego.js draws at an answer card (the left one) reaches 7 px onto the frog's face, 46 px under it, in every scene (the card's place and the hand are the game's, respBox and hand()): at the asks for yo_coqui, tu_hermana, tu_hermano, $bien_papa",
   "bubbles: 177 bubbles at 1101 moments of 18 runs (d-bizcocho-bebe, d-foto-familia, h-sala, la-familia, la-foto, quien-eres-tu), each its recorded one and the ones an act can show there (anyone's \"amor\" when touched, abuelo's \"q\", the frog's \"amor\"): wholly inside the view (1 px from its edge at the least), clear of the cards shown in the corner (0 px), on no face",
   "floor: 103 distinct places where someone stands (and the frog): inside the room, nothing of the furniture or the walls nearer than them inside their body (the low table only covers who is drawn before it, and only where it is nearer); 11 distinct sittings, each before a seat",
   "pairs, what differs (the same window both sides): mama: mama only in si, abuela only in no; papa: papa only in si, abuelo only in no; abuelo: abuelo only in si, abuela only in no; bebe: bebe only in si, hermano only in no; familia: papa only in si, abuelo only in si, abuela only in si, hermano only in si, hermana only in si, bebe only in si; hermano: hermano only in si, papa only in no; hermana: hermana only in si, mama only in no; el: the frog x; ella: the frog x; yo: hermana pose; tu: hermano pose",
   "pairs: 22 review pictures (and the 28 level pictures, the same pictures): everyone and the frog whole in their crop, on clear floor or a seat"
  ]
 }
}
''',
  'patio': r'''{
 "scene": "patio",
 "made": "node docs/proyecto/pixel/patio-sheet-make.js, from patio-set.html (window.PATIO_SET) and coqui/ref/escenas/patio/. Order 32a.",
 "S": 26,
 "origin": {
  "originX": 0,
  "originY": 4
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the yard is built round the old picture: a place on its lawn keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person's place (x, y): the ground point under (x, y - 1), new (x, y) = old. So every ground position of patio.js, its stories and its pairs keeps its numbers, but for the few in moves; the sheet names each one (spots, remap, code, moves) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog or a point (what they carry, the flower in Carmen's hair, the fireflies \"with\" someone, the bubbles, the ball at p.x + 12) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the stars of the happy endings (final9, final10, final11), the heart (heartAt), the bird's loop (aveloop) and its flights, the fireflies' way out (stake: 226, 58)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were"
 },
 "layout": {
  "what": "the yard built as La sala is: two walls on the world's axes, seen at the engine's 30 degrees (shadows to screen right), coming together in a far corner over the middle of the picture, the lawn running off the picture's sides and bottom. On the LEFT the back of the house: its back wall on x = -1.904392167527876 (it faces +x, in shade, teal siding as El frente's side wall), from its far corner (a white corner board, screen x 76) down off the picture's left edge; in it the back door in its white frame on a stone step (screen x 34 to 69); over it a hip roof of red tiles, the hip over the far corner. On the FAR RIGHT the wooden fence on y = -1.604392167527876 (it faces +y, lit), from the far corner off the picture's right edge, posts with caps along it; in it, near the corner, the cream garden gate between two taller posts (screen x 115 to 163); right of the gate the flamboyán, its trunk a little in front of the fence, its crown where the old one was, the nest on a branch at its left. The lawn before them, the two beds of earth at the old ellipses. The house stops 2 units short of the corner: between its far corner and the fence's first post the yard opens on a field and low hills (the horizon at row 84), where the sun goes down. The gate opens into the yard: its leaf swung on its left post, its face seen; through the empty opening a path of trodden earth goes out over the field and winds up the hill behind. Through the open door a dark room (no story lights it): abuela stands in the doorway, on its threshold. The lawn is the same grass as El frente's and El balcón's (round 4: the engine's GRASS ramp, centred where El frente's lawn is), calm (mostly one tone, Bayer-mixed with its neighbours), no blooms in its grass round the beds, the crate and the ball, right up to the beds; the beds are turned earth in lumps, a hole for each flower, nothing round them (round 6: a flower's leaves are its own, the sprite layer's: flowerLeaves)",
  "lines": {
   "corner": [114.48, 79.75],
   "cornerWhat": "the far corner (where the two lines meet), on the screen",
   "wall": {
    "foot": "row = 136.99 - x / 2",
    "leftEdge": [0, 136.99],
    "viewLeft": [22, 125.99],
    "farEnd": [76, 98.99],
    "what": "the house wall's foot: from the house's far corner down to the left; it leaves the picture at its left edge (and the view at x 22)"
   },
   "fence": {
    "foot": "row = 22.5 + x / 2",
    "rightEdge": [240, 142.5],
    "viewRight": [218, 131.5],
    "what": "the fence's foot: from the far corner down to the right; it leaves the picture at its right edge (and the view at x 218)"
   },
   "gap": "between the house's far corner (x 76) and the fence's first post (x 114): the field and the hills, where the sun goes down"
  },
  "gate": {
   "porton": {
    "at": [126, 86],
    "before": 17.5,
    "oldPicture": 17,
    "round3": {
     "at": [128, 104],
     "before": 34.5
    }
   },
   "sale": {
    "at": [130, 68],
    "before": -2.5,
    "oldPicture": -3,
    "round3": {
     "at": [134, 84],
     "before": 11.5
    }
   },
   "what": "the frog's two places at the gate (LUGAR.porton: he stops at it; LUGAR.sale: he goes out through it and fades), in rows his feet are in front of the fence's line at his column (< 0: past it). The old picture: porton 17 rows before its gate, sale 3 rows past it. Round 4: they follow the gate (moves): porton 17.5 rows before it, his middle at x 142 (the opening x 135 to 157); sale 2.5 rows past it, on the path, his box between the posts. Round 3 had left them where the old hop counts put them: porton 34.5 rows before, sale 11.5 rows before (on the lawn). So some hop counts of pairs with porton or sale are not the old ones: hops lists them"
  },
  "why": "page 11 decision 9 and the owner's three approved sets (El frente, El balcón, La sala): walls run along the world's axes and are seen at the engine's angle. Every place on the lawn keeps its old screen point (rules.floor). Round 3: everyone on the lawn has at least 5 rows of lawn between their feet and the foot of what stands behind them (round 2 put the lines as low as the places allowed, and the frog read as standing on the wall's base, the boy on the fence's): the wall's line went up 1 row, held by the frog at the door (LUGAR.puerta) before the door's step; the fence's 1 row, held by Carmen at the open gate (pair vamos, 168, 120) and the walk to the gate; the trunk stands against the fence, held by the frog at the tree. The old sun sank at x 100, right where the corner rises: a house wall there would hide it at every height, so the house ends short of the corner and the sun goes down in the gap, behind the field and the hills",
  "moved": [
   "the back door: its middle 10 px right of the old one (x 42 to 52), 1.5 units wide (round 3; the old opening 30 px), its threshold on the house wall's foot (row 109, the old 112); box [34,40,35,80] (old [27, 57, 30, 56]). Follow it: abuela in the door (asoma) and whoever goes in (seva), in moves",
   "the gate: its middle 1 px left of the old one (x 147 to 146), its posts at x 133 and 159, its foot on the fence's line, 16 rows further back (row 112 to 96); box [115,42,48,63] (old [127, 70, 40, 43]; it holds the leaf shut and swung open into the yard). Follow it: the walk to the gate (juntos, luiscorre) and (round 4) the frog's two places there, LUGAR.porton and LUGAR.sale (layout.gate), in moves",
   "the flamboyán: its trunk's foot 13 rows lower (row 114 to 127), at the same x (204), against the fence (round 3: 0.12 in front of it, round 2 .35): the trunk is longer; its crown where the old one was (its left lobe 4 px right, clear of the gate's box). Nothing follows: the frog at the tree (LUGAR.arbol) is before the trunk, 5 rows of lawn and more between them",
   "the sixth star: from (112, 58) to [100,44] (moves)",
   "unchanged: the nest (181, 66) and every landing of the bird on it; the bird on the fence (178, 83), on a post's cap; the ball in the tree (196, 64); the sun (SOLX 100), the moon (150, 26)"
  ]
 },
 "behind": {
  "what": "the sky is the set's (baked per hour); what moves or twinkles in it is the sprite layer's, drawn behind the set: the sun (sol(), its rays turning with F, sinking with W.soly), the moon (luna()) and the stars (ESTRELLAS, twinkling). Each is drawn first in the sprite layer, then the set's own pixels are drawn again inside its box wherever the set has drawn anything (bakedZ > -1e8, and the leaves of that frame): the sky objects are farther than everything (depth -1e9, SetOverSprites). The hills are the set's, at depth -10000000 (farther than any of the set's things, nearer than the sky objects). So the sun goes down behind the field and the hills in the gap between the house and the fence, and the house hides the stars at 40, 46 (as the old picture did), 60, 18 and 72, 64",
  "items": [
   {
    "at": "patio.js:131",
    "what": "the stars (W.estrella, W.noche)",
    "boxes": "each star [x - 1, y - 1, 4, 4]"
   },
   {
    "at": "patio.js:132",
    "what": "the moon (W.luna) at 150, 26; the sun at SOLX, soly (W.soly < 110)",
    "boxes": "moon [139, 15, 24, 22]; sun [SOLX - 21, soly - 21, 42, 42] (its rays)"
   }
  ]
 },
 "setKey": {
  "params": {
   "hora": {
    "values": ["dia", "tarde", "tarde2", "ocaso", "crepusculo", "noche"],
    "fromW": "W.noche ? \"noche\" : n = min(3, W.sol || 0): n < 3 ? [\"dia\", \"tarde\", \"tarde2\"][n] : (W.osc >= .25 ? \"crepusculo\" : \"ocaso\"). The sky (the old cielo(n)) and the light of the hour on the set (the old overlays of patio.js:147-148, W.osc) are baked, as El frente's dusk; the characters are not dimmed"
   },
   "door": {
    "values": ["shut", "open"],
    "fromW": "W.pdoor ? \"open\" : \"shut\" (the back door)"
   },
   "gate": {
    "values": ["shut", "open"],
    "fromW": "W.porton ? \"open\" : \"shut\" (the garden gate)"
   }
  },
  "key": "hora + \"-\" + door + \"-\" + gate, e.g. \"dia-shut-shut\"",
  "baked": [
   {
    "key": "dia-shut-shut",
    "query": "?hora=dia&door=shut&gate=shut"
   },
   {
    "key": "dia-open-shut",
    "query": "?hora=dia&door=open&gate=shut"
   },
   {
    "key": "dia-shut-open",
    "query": "?hora=dia&door=shut&gate=open"
   },
   {
    "key": "tarde-shut-shut",
    "query": "?hora=tarde&door=shut&gate=shut"
   },
   {
    "key": "tarde-open-shut",
    "query": "?hora=tarde&door=open&gate=shut"
   },
   {
    "key": "tarde2-shut-shut",
    "query": "?hora=tarde2&door=shut&gate=shut"
   },
   {
    "key": "tarde2-open-shut",
    "query": "?hora=tarde2&door=open&gate=shut"
   },
   {
    "key": "ocaso-shut-shut",
    "query": "?hora=ocaso&door=shut&gate=shut"
   },
   {
    "key": "ocaso-open-shut",
    "query": "?hora=ocaso&door=open&gate=shut"
   },
   {
    "key": "ocaso-open-open",
    "query": "?hora=ocaso&door=open&gate=open"
   },
   {
    "key": "crepusculo-shut-shut",
    "query": "?hora=crepusculo&door=shut&gate=shut"
   },
   {
    "key": "crepusculo-open-shut",
    "query": "?hora=crepusculo&door=open&gate=shut"
   },
   {
    "key": "noche-shut-shut",
    "query": "?hora=noche&door=shut&gate=shut"
   },
   {
    "key": "noche-open-shut",
    "query": "?hora=noche&door=open&gate=shut"
   },
   {
    "key": "noche-open-open",
    "query": "?hora=noche&door=open&gate=open"
   }
  ],
  "bakedWhy": "order 06 found 73 states: what makes them is the sky (W.sol, W.noche, W.osc), the back door, the gate, the crate, the flowers in the beds and the sack. Only the hour, the door and the gate are the set's; the crate, the flowers, the sack, the ball, the sun, the moon and the stars are drawn by the sprite layer, so these 15 baked states draw all 73 (and every review and level picture)"
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "carmen": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "bebe": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "abuela": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "abuelo": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "mama": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "papa": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "bola": {
   "sprite": true,
   "prop": true,
   "why": "the ball (sprite layer): box [x - 7, y - 13, 14, 14] at W.bola, unchanged"
  },
  "saco": {
   "sprite": true,
   "prop": true,
   "why": "the sack (sprite layer): box [x - 13, y - 23, 26, 24] at W.saco, unchanged"
  },
  "caja": {
   "sprite": true,
   "prop": true,
   "why": "the crate of potted flowers (sprite layer, mkCaja at points.caja): box [104, 112, 32, 24], unchanged",
   "box": [104, 112, 32, 24]
  },
  "camaL": {
   "set": true,
   "world": [1.7406, 4.569, 0, 3.2636, 6.092, 0.4441],
   "box": [40, 159, 57, 39],
   "what": "bed L: the earth (the set, painted on the lawn at the old ellipse) and the flowers over it (the sprite layer): the box round both, as the old one",
   "old": {
    "box": [40, 160, 56, 38]
   }
  },
  "camaR": {
   "set": true,
   "world": [4.569, 1.7406, 0, 6.092, 3.2636, 0.4441],
   "box": [144, 159, 56, 39],
   "what": "bed R, as bed L",
   "old": {
    "box": [144, 160, 56, 38]
   }
  },
  "sol": {
   "sprite": true,
   "prop": true,
   "why": "the sun (the sprite layer, drawn behind the set: sheet behind): box [SOLX - 14, soly - 14, 28, 28] while !W.noche and soly < 80, unchanged (SOLY[0] 26: moves)"
  },
  "porton": {
   "set": true,
   "world": [-1.1723, -2.2208, 0, 0.1005, -0.948, 1.6877],
   "box": [115, 42, 48, 63],
   "what": "the garden gate in the fence: its two posts and the leaf, shut and open (open, round 3: the leaf swung into the yard on its left post, 78 degrees, its face seen; the opening empty, the path through it)",
   "old": {
    "box": [127, 70, 40, 43]
   },
   "hand": [133, 46],
   "handWhy": "the hint hand's point (kit.js cosas: hand, as El frente's house has one): the near post's cap, the gate's top left. The hand hangs 54 rows below its point; Luis waits before the gate (hasta-manana beats.32, at 138, 138), right of it (beats.5, 178, 126) and further right (h-patio beats.12, 180, 150): from the cap the hand ends over his head and left of him (lower on the leaf, or at its middle, it is on his face)"
  },
  "nido": {
   "set": true,
   "world": [-0.8975, -4.2154, 0, -0.2992, -3.6171, 0.2221],
   "box": [170, 60, 22, 16],
   "what": "the nest on its branch (the box round it and the bird on it, as the old one)",
   "old": {
    "box": [170, 60, 22, 16]
   }
  },
  "arbol": {
   "set": true,
   "world": [1.2238, -3.2908, 0, 3.2364, -1.2782, 3.9526],
   "box": [166, 3, 74, 127],
   "what": "the flamboyán: its crown (every pixel its leaves take at any wind step) down to the foot of its trunk",
   "old": {
    "box": [168, 8, 60, 106]
   }
  },
  "pajaro": {
   "sprite": true,
   "why": "the bird (kit.js drawAve, sprite layer): box [p.x - 10, p.y - 20, 20, 22] at avePos, unchanged"
  },
  "puerta": {
   "set": true,
   "world": [-2.3769, 1.3368, 0, -1.4619, 2.2518, 2.77],
   "box": [34, 40, 35, 80],
   "what": "the back door in its white frame, on the house wall",
   "old": {
    "box": [27, 57, 30, 56]
   }
  },
  "casa": {
   "set": true,
   "world": [-1.7014, 2.5088, 0, 0.6155, 4.8257, 5.3037],
   "box": [0, -1, 86, 164],
   "what": "the back of the house: its wall (from its far corner down off the picture's left edge), its step and its roof; the box is the part on the picture",
   "old": {
    "box": [0, 14, 61, 100]
   }
  },
  "cerca": {
   "set": true,
   "world": [0.486, -2.5176, 0, 4.0096, 1.006, 2.0717],
   "box": [110, 46, 130, 113],
   "what": "the fence, from the far corner to the picture's right edge (the box is the part on the picture)",
   "old": {
    "box": [60, 80, 180, 33]
   }
  },
  "patio": {
   "set": true,
   "world": [-0.8703, -0.8703, 0, 5.6569, 5.6569, 0.755],
   "box": [0, 79, 240, 137],
   "what": "the lawn, from the far corner (row 79) to the bottom, the whole width: last in the hit order",
   "old": {
    "box": [0, 113, 240, 103]
   }
  }
 },
 "spots": {
  "frog.puerta": {
   "world": [-1.0879, 2.9372, 0],
   "new": [30, 104],
   "scale": 0.8,
   "old": [30, 104],
   "what": "LUGAR.puerta: the frog"
  },
  "frog.inicio": {
   "world": [2.0125, 4.841, 0],
   "new": [52, 150],
   "scale": 1,
   "old": [52, 150],
   "what": "LUGAR.inicio: the frog"
  },
  "frog.centro": {
   "world": [4.9497, 4.9497, 0],
   "new": [104, 178],
   "scale": 1,
   "old": [104, 178],
   "what": "LUGAR.centro: the frog"
  },
  "frog.caja": {
   "world": [3.4267, 3.4267, 0],
   "new": [104, 150],
   "scale": 1,
   "old": [104, 150],
   "what": "LUGAR.caja: the frog"
  },
  "frog.camaL": {
   "world": [3.8075, 4.569, 0],
   "new": [90, 164],
   "scale": 0.9,
   "old": [90, 164],
   "what": "LUGAR.camaL: the frog"
  },
  "frog.camaR": {
   "world": [4.569, 3.8075, 0],
   "new": [118, 164],
   "scale": 0.9,
   "old": [118, 164],
   "what": "LUGAR.camaR: the frog"
  },
  "frog.luis": {
   "world": [3.1004, 2.6652, 0],
   "new": [112, 140],
   "scale": 1,
   "old": [112, 140],
   "what": "LUGAR.luis: the frog"
  },
  "frog.carmen": {
   "world": [1.1966, 3.4811, 0],
   "new": [62, 130],
   "scale": 1,
   "old": [62, 130],
   "what": "LUGAR.carmen: the frog"
  },
  "frog.carmenA": {
   "world": [1.795, 1.3598, 0],
   "new": [112, 116],
   "scale": 0.9,
   "old": [112, 116],
   "what": "LUGAR.carmenA: the frog"
  },
  "frog.abuela": {
   "world": [3.5899, 5.4393, 0],
   "new": [70, 170],
   "scale": 1,
   "old": [70, 170],
   "what": "LUGAR.abuela: the frog"
  },
  "frog.porton": {
   "world": [0.5439, -0.6527, 0],
   "new": [126, 86],
   "scale": 0.85,
   "old": [128, 104],
   "what": "LUGAR.porton: the frog at the gate, on the lawn before its opening (moved: see moves)"
  },
  "frog.arbol": {
   "world": [3.5899, -0.8703, 0],
   "new": [186, 112],
   "scale": 0.8,
   "old": [186, 112],
   "what": "LUGAR.arbol: the frog"
  },
  "frog.luisC": {
   "world": [2.6652, 3.1004, 0],
   "new": [96, 140],
   "scale": 0.95,
   "old": [96, 140],
   "what": "LUGAR.luisC: the frog"
  },
  "frog.sale": {
   "world": [-0.3264, -1.7406, 0],
   "new": [130, 68],
   "scale": 0.5,
   "old": [134, 84],
   "what": "LUGAR.sale: the frog through the gate, on the path just past the fence's line, where he fades (moved: see moves)"
  },
  "detras.L": {
   "world": [2.0125, 4.841, 0],
   "new": [68, 176],
   "old": [68, 176],
   "what": "DETRAS.L: a child behind bed L, planting (acts.dale, final9)"
  },
  "detras.R": {
   "world": [4.841, 2.0125, 0],
   "new": [172, 176],
   "old": [172, 176],
   "what": "DETRAS.R: a child behind bed R, planting (acts.dale, final9)"
  },
  "espera.luis": {
   "world": [1.9037, -0.272, 0],
   "new": [160, 128],
   "old": [160, 128],
   "what": "ESPERA.luis: luis waits (acts.anda a = espera)"
  },
  "espera.carmen": {
   "world": [-0.272, 1.9037, 0],
   "new": [80, 128],
   "old": [80, 128],
   "what": "ESPERA.carmen: carmen waits (acts.anda a = espera)"
  },
  "lados.0": {
   "world": [2.2301, 4.1882, 0],
   "new": [84, 172],
   "old": [84, 172],
   "what": "LADOS[0]: a child either side of the crate, hands out (acts.lados)"
  },
  "lados.1": {
   "world": [4.1882, 2.2301, 0],
   "new": [156, 172],
   "old": [156, 172],
   "what": "LADOS[1]: a child either side of the crate, hands out (acts.lados)"
  },
  "asoma": {
   "world": [-2.1213, 1.5774, 0],
   "new": [52, 108],
   "old": [42, 116],
   "what": "acts.asoma: abuela in the back door, on its threshold, in the doorway (moved: see moves)"
  },
  "seva": {
   "world": [-1.5502, 1.7678, 0],
   "new": [59, 115],
   "old": [44, 118],
   "what": "acts.seva: before the back door's step, where whoever goes in is last seen (moved: see moves)"
  },
  "juntos": {
   "world": [1.387, -1.0607, 0],
   "new": [165, 116],
   "old": [170, 124],
   "what": "acts.juntos, acts.luiscorre: right of the gate, before its right post (moved: see moves)"
  }
 },
 "lugar": {
  "puerta": {
   "spot": "frog.puerta",
   "q": [30, 104],
   "scale": 0.8,
   "old": [30, 104]
  },
  "inicio": {
   "spot": "frog.inicio",
   "q": [52, 150],
   "scale": 1,
   "old": [52, 150]
  },
  "centro": {
   "spot": "frog.centro",
   "q": [104, 178],
   "scale": 1,
   "old": [104, 178]
  },
  "caja": {
   "spot": "frog.caja",
   "q": [104, 150],
   "scale": 1,
   "old": [104, 150]
  },
  "camaL": {
   "spot": "frog.camaL",
   "q": [90, 164],
   "scale": 0.9,
   "old": [90, 164]
  },
  "camaR": {
   "spot": "frog.camaR",
   "q": [118, 164],
   "scale": 0.9,
   "old": [118, 164]
  },
  "luis": {
   "spot": "frog.luis",
   "q": [112, 140],
   "scale": 1,
   "old": [112, 140]
  },
  "carmen": {
   "spot": "frog.carmen",
   "q": [62, 130],
   "scale": 1,
   "old": [62, 130]
  },
  "carmenA": {
   "spot": "frog.carmenA",
   "q": [112, 116],
   "scale": 0.9,
   "old": [112, 116]
  },
  "abuela": {
   "spot": "frog.abuela",
   "q": [70, 170],
   "scale": 1,
   "old": [70, 170]
  },
  "porton": {
   "spot": "frog.porton",
   "q": [126, 86],
   "scale": 0.85,
   "old": [128, 104]
  },
  "arbol": {
   "spot": "frog.arbol",
   "q": [186, 112],
   "scale": 0.8,
   "old": [186, 112]
  },
  "luisC": {
   "spot": "frog.luisC",
   "q": [96, 140],
   "scale": 0.95,
   "old": [96, 140]
  },
  "sale": {
   "spot": "frog.sale",
   "q": [130, 68],
   "scale": 0.5,
   "old": [134, 84]
  }
 },
 "hops": [
  {
   "a": "centro",
   "b": "sale",
   "old": 3,
   "new": 4,
   "dOld": 98.67,
   "dNew": 113.03
  },
  {
   "a": "caja",
   "b": "sale",
   "old": 2,
   "new": 3,
   "dOld": 72.5,
   "dNew": 86.02
  },
  {
   "a": "camaL",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 71.02,
   "dNew": 85.91
  },
  {
   "a": "camaR",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 60.83,
   "dNew": 78.41
  },
  {
   "a": "luis",
   "b": "porton",
   "old": 1,
   "new": 2,
   "dOld": 39.4,
   "dNew": 55.79
  },
  {
   "a": "carmen",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 70.94,
   "dNew": 77.67
  },
  {
   "a": "carmenA",
   "b": "sale",
   "old": 1,
   "new": 2,
   "dOld": 38.83,
   "dNew": 51.26
  },
  {
   "a": "luisC",
   "b": "sale",
   "old": 2,
   "new": 3,
   "dOld": 67.68,
   "dNew": 79.62
  }
 ],
 "hopsWhat": "round 4: each pair of LUGAR places whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one, with the old and the new count and distance; every one has porton or sale (their places followed the gate: moves). Every other pair keeps its count (hopsAll: all 91 pairs). acts.sevan hops 3 times to sale from wherever he is, whatever the distance",
 "hopsAll": [
  {
   "a": "puerta",
   "b": "inicio",
   "old": 2,
   "new": 2,
   "dOld": 50.99,
   "dNew": 50.99
  },
  {
   "a": "puerta",
   "b": "centro",
   "old": 3,
   "new": 3,
   "dOld": 104.65,
   "dNew": 104.65
  },
  {
   "a": "puerta",
   "b": "caja",
   "old": 3,
   "new": 3,
   "dOld": 87.13,
   "dNew": 87.13
  },
  {
   "a": "puerta",
   "b": "camaL",
   "old": 3,
   "new": 3,
   "dOld": 84.85,
   "dNew": 84.85
  },
  {
   "a": "puerta",
   "b": "camaR",
   "old": 4,
   "new": 4,
   "dOld": 106.51,
   "dNew": 106.51
  },
  {
   "a": "puerta",
   "b": "luis",
   "old": 3,
   "new": 3,
   "dOld": 89.55,
   "dNew": 89.55
  },
  {
   "a": "puerta",
   "b": "carmen",
   "old": 1,
   "new": 1,
   "dOld": 41.23,
   "dNew": 41.23
  },
  {
   "a": "puerta",
   "b": "carmenA",
   "old": 3,
   "new": 3,
   "dOld": 82.87,
   "dNew": 82.87
  },
  {
   "a": "puerta",
   "b": "abuela",
   "old": 3,
   "new": 3,
   "dOld": 77.18,
   "dNew": 77.18
  },
  {
   "a": "puerta",
   "b": "porton",
   "old": 3,
   "new": 3,
   "dOld": 98,
   "dNew": 97.67
  },
  {
   "a": "puerta",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 156.2,
   "dNew": 156.2
  },
  {
   "a": "puerta",
   "b": "luisC",
   "old": 3,
   "new": 3,
   "dOld": 75.18,
   "dNew": 75.18
  },
  {
   "a": "puerta",
   "b": "sale",
   "old": 4,
   "new": 4,
   "dOld": 105.91,
   "dNew": 106.28
  },
  {
   "a": "inicio",
   "b": "centro",
   "old": 2,
   "new": 2,
   "dOld": 59.06,
   "dNew": 59.06
  },
  {
   "a": "inicio",
   "b": "caja",
   "old": 2,
   "new": 2,
   "dOld": 52,
   "dNew": 52
  },
  {
   "a": "inicio",
   "b": "camaL",
   "old": 1,
   "new": 1,
   "dOld": 40.5,
   "dNew": 40.5
  },
  {
   "a": "inicio",
   "b": "camaR",
   "old": 2,
   "new": 2,
   "dOld": 67.47,
   "dNew": 67.47
  },
  {
   "a": "inicio",
   "b": "luis",
   "old": 2,
   "new": 2,
   "dOld": 60.83,
   "dNew": 60.83
  },
  {
   "a": "inicio",
   "b": "carmen",
   "old": 1,
   "new": 1,
   "dOld": 22.36,
   "dNew": 22.36
  },
  {
   "a": "inicio",
   "b": "carmenA",
   "old": 2,
   "new": 2,
   "dOld": 68.96,
   "dNew": 68.96
  },
  {
   "a": "inicio",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 26.91,
   "dNew": 26.91
  },
  {
   "a": "inicio",
   "b": "porton",
   "old": 3,
   "new": 3,
   "dOld": 88.84,
   "dNew": 97.84
  },
  {
   "a": "inicio",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 139.28,
   "dNew": 139.28
  },
  {
   "a": "inicio",
   "b": "luisC",
   "old": 2,
   "new": 2,
   "dOld": 45.12,
   "dNew": 45.12
  },
  {
   "a": "inicio",
   "b": "sale",
   "old": 4,
   "new": 4,
   "dOld": 105.26,
   "dNew": 113.17
  },
  {
   "a": "centro",
   "b": "caja",
   "old": 1,
   "new": 1,
   "dOld": 28,
   "dNew": 28
  },
  {
   "a": "centro",
   "b": "camaL",
   "old": 1,
   "new": 1,
   "dOld": 19.8,
   "dNew": 19.8
  },
  {
   "a": "centro",
   "b": "camaR",
   "old": 1,
   "new": 1,
   "dOld": 19.8,
   "dNew": 19.8
  },
  {
   "a": "centro",
   "b": "luis",
   "old": 1,
   "new": 1,
   "dOld": 38.83,
   "dNew": 38.83
  },
  {
   "a": "centro",
   "b": "carmen",
   "old": 2,
   "new": 2,
   "dOld": 63.78,
   "dNew": 63.78
  },
  {
   "a": "centro",
   "b": "carmenA",
   "old": 2,
   "new": 2,
   "dOld": 62.51,
   "dNew": 62.51
  },
  {
   "a": "centro",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 34.93,
   "dNew": 34.93
  },
  {
   "a": "centro",
   "b": "porton",
   "old": 3,
   "new": 3,
   "dOld": 77.79,
   "dNew": 94.59
  },
  {
   "a": "centro",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 105.26,
   "dNew": 105.26
  },
  {
   "a": "centro",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 38.83,
   "dNew": 38.83
  },
  {
   "a": "centro",
   "b": "sale",
   "old": 3,
   "new": 4,
   "dOld": 98.67,
   "dNew": 113.03
  },
  {
   "a": "caja",
   "b": "camaL",
   "old": 1,
   "new": 1,
   "dOld": 19.8,
   "dNew": 19.8
  },
  {
   "a": "caja",
   "b": "camaR",
   "old": 1,
   "new": 1,
   "dOld": 19.8,
   "dNew": 19.8
  },
  {
   "a": "caja",
   "b": "luis",
   "old": 1,
   "new": 1,
   "dOld": 12.81,
   "dNew": 12.81
  },
  {
   "a": "caja",
   "b": "carmen",
   "old": 2,
   "new": 2,
   "dOld": 46.52,
   "dNew": 46.52
  },
  {
   "a": "caja",
   "b": "carmenA",
   "old": 1,
   "new": 1,
   "dOld": 34.93,
   "dNew": 34.93
  },
  {
   "a": "caja",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 39.45,
   "dNew": 39.45
  },
  {
   "a": "caja",
   "b": "porton",
   "old": 2,
   "new": 2,
   "dOld": 51.88,
   "dNew": 67.68
  },
  {
   "a": "caja",
   "b": "arbol",
   "old": 3,
   "new": 3,
   "dOld": 90.38,
   "dNew": 90.38
  },
  {
   "a": "caja",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 12.81,
   "dNew": 12.81
  },
  {
   "a": "caja",
   "b": "sale",
   "old": 2,
   "new": 3,
   "dOld": 72.5,
   "dNew": 86.02
  },
  {
   "a": "camaL",
   "b": "camaR",
   "old": 1,
   "new": 1,
   "dOld": 28,
   "dNew": 28
  },
  {
   "a": "camaL",
   "b": "luis",
   "old": 1,
   "new": 1,
   "dOld": 32.56,
   "dNew": 32.56
  },
  {
   "a": "camaL",
   "b": "carmen",
   "old": 1,
   "new": 1,
   "dOld": 44.05,
   "dNew": 44.05
  },
  {
   "a": "camaL",
   "b": "carmenA",
   "old": 2,
   "new": 2,
   "dOld": 52.8,
   "dNew": 52.8
  },
  {
   "a": "camaL",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 20.88,
   "dNew": 20.88
  },
  {
   "a": "camaL",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 71.02,
   "dNew": 85.91
  },
  {
   "a": "camaL",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 109.18,
   "dNew": 109.18
  },
  {
   "a": "camaL",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 24.74,
   "dNew": 24.74
  },
  {
   "a": "camaL",
   "b": "sale",
   "old": 3,
   "new": 3,
   "dOld": 91.3,
   "dNew": 104
  },
  {
   "a": "camaR",
   "b": "luis",
   "old": 1,
   "new": 1,
   "dOld": 24.74,
   "dNew": 24.74
  },
  {
   "a": "camaR",
   "b": "carmen",
   "old": 2,
   "new": 2,
   "dOld": 65.51,
   "dNew": 65.51
  },
  {
   "a": "camaR",
   "b": "carmenA",
   "old": 2,
   "new": 2,
   "dOld": 48.37,
   "dNew": 48.37
  },
  {
   "a": "camaR",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 48.37,
   "dNew": 48.37
  },
  {
   "a": "camaR",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 60.83,
   "dNew": 78.41
  },
  {
   "a": "camaR",
   "b": "arbol",
   "old": 3,
   "new": 3,
   "dOld": 85.6,
   "dNew": 85.6
  },
  {
   "a": "camaR",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 32.56,
   "dNew": 32.56
  },
  {
   "a": "camaR",
   "b": "sale",
   "old": 3,
   "new": 3,
   "dOld": 81.58,
   "dNew": 96.75
  },
  {
   "a": "luis",
   "b": "carmen",
   "old": 2,
   "new": 2,
   "dOld": 50.99,
   "dNew": 50.99
  },
  {
   "a": "luis",
   "b": "carmenA",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 24
  },
  {
   "a": "luis",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 51.61,
   "dNew": 51.61
  },
  {
   "a": "luis",
   "b": "porton",
   "old": 1,
   "new": 2,
   "dOld": 39.4,
   "dNew": 55.79
  },
  {
   "a": "luis",
   "b": "arbol",
   "old": 3,
   "new": 3,
   "dOld": 79.12,
   "dNew": 79.12
  },
  {
   "a": "luis",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 16,
   "dNew": 16
  },
  {
   "a": "luis",
   "b": "sale",
   "old": 2,
   "new": 2,
   "dOld": 60.17,
   "dNew": 74.22
  },
  {
   "a": "carmen",
   "b": "carmenA",
   "old": 2,
   "new": 2,
   "dOld": 51.92,
   "dNew": 51.92
  },
  {
   "a": "carmen",
   "b": "abuela",
   "old": 1,
   "new": 1,
   "dOld": 40.79,
   "dNew": 40.79
  },
  {
   "a": "carmen",
   "b": "porton",
   "old": 2,
   "new": 3,
   "dOld": 70.94,
   "dNew": 77.67
  },
  {
   "a": "carmen",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 125.3,
   "dNew": 125.3
  },
  {
   "a": "carmen",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 35.44,
   "dNew": 35.44
  },
  {
   "a": "carmen",
   "b": "sale",
   "old": 3,
   "new": 3,
   "dOld": 85.44,
   "dNew": 92.02
  },
  {
   "a": "carmenA",
   "b": "abuela",
   "old": 2,
   "new": 2,
   "dOld": 68.41,
   "dNew": 68.41
  },
  {
   "a": "carmenA",
   "b": "porton",
   "old": 1,
   "new": 1,
   "dOld": 20,
   "dNew": 33.11
  },
  {
   "a": "carmenA",
   "b": "arbol",
   "old": 2,
   "new": 2,
   "dOld": 74.11,
   "dNew": 74.11
  },
  {
   "a": "carmenA",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 28.84,
   "dNew": 28.84
  },
  {
   "a": "carmenA",
   "b": "sale",
   "old": 1,
   "new": 2,
   "dOld": 38.83,
   "dNew": 51.26
  },
  {
   "a": "abuela",
   "b": "porton",
   "old": 3,
   "new": 3,
   "dOld": 87.86,
   "dNew": 100.96
  },
  {
   "a": "abuela",
   "b": "arbol",
   "old": 4,
   "new": 4,
   "dOld": 129.69,
   "dNew": 129.69
  },
  {
   "a": "abuela",
   "b": "luisC",
   "old": 1,
   "new": 1,
   "dOld": 39.7,
   "dNew": 39.7
  },
  {
   "a": "abuela",
   "b": "sale",
   "old": 4,
   "new": 4,
   "dOld": 107.2,
   "dNew": 118.34
  },
  {
   "a": "porton",
   "b": "arbol",
   "old": 2,
   "new": 2,
   "dOld": 58.55,
   "dNew": 65.39
  },
  {
   "a": "porton",
   "b": "luisC",
   "old": 2,
   "new": 2,
   "dOld": 48.17,
   "dNew": 61.77
  },
  {
   "a": "porton",
   "b": "sale",
   "old": 1,
   "new": 1,
   "dOld": 20.88,
   "dNew": 18.44
  },
  {
   "a": "arbol",
   "b": "luisC",
   "old": 3,
   "new": 3,
   "dOld": 94.25,
   "dNew": 94.25
  },
  {
   "a": "arbol",
   "b": "sale",
   "old": 2,
   "new": 2,
   "dOld": 59.06,
   "dNew": 71.22
  },
  {
   "a": "luisC",
   "b": "sale",
   "old": 2,
   "new": 3,
   "dOld": 67.68,
   "dNew": 79.62
  }
 ],
 "points": {
  "nido": {
   "screen": [181, 66],
   "old": [181, 66],
   "world": [2.4025, -0.9155, 2.5612],
   "what": "the bird on its nest (W.ave x, y: its feet): fresh(), aveVa(181, 66) in aveloop, avenido, alnido. The nest (the set) is on a branch of the flamboyán, its rim under the bird's feet, as the old one; its middle on the screen at 181,68"
  },
  "cerca.ave": {
   "screen": [178, 83],
   "old": [178, 83],
   "what": "inicio11: the bird sits on the fence, right of the gate (W.ave x 178, y 83): on the cap of a fence post there, whose top is under its feet (the fence's boards run down to the right, a flat cap takes both feet)"
  },
  "sol": {
   "screen": [100, null],
   "old": [
    100,
    [24, 40, 56, 73]
   ],
   "heights": [26, 40, 56, 73],
   "what": "the sun (sol(c, SOLX, soly, n, brilla)): drawn by the sprite layer behind the set (sheet: behind); SOLX unchanged, SOLY[0] 2 px lower (moves); it goes down where the old one did, now in the gap between the house and the fence, behind the field and the low hills (soly 109: hidden)"
  },
  "luna": {
   "screen": [150, 26],
   "old": [150, 26],
   "what": "luna(c, 150, 26): the moon, behind the set (sheet: behind)"
  },
  "estrellas": {
   "screen": [
    [60, 18],
    [84, 40],
    [124, 12],
    [150, 36],
    [40, 46],
    [100, 44],
    [72, 64],
    [140, 60]
   ],
   "old": [
    [60, 18],
    [84, 40],
    [124, 12],
    [150, 36],
    [40, 46],
    [112, 58],
    [72, 64],
    [140, 60]
   ],
   "what": "ESTRELLAS: the stars, behind the set (sheet: behind): the house hides the ones at 40, 46 (as the old picture did), 60, 18 and 72, 64 (the house now reaches further up and right), the gate's left post the one at 140, 60; the sixth moved from 112, 58 (moves); the other four are in the sky, none touching the set"
  },
  "corazon": {
   "screen": [118, 36],
   "old": [118, 36],
   "what": "heartAt: the heart of a happy ending: in the sky between the house and the tree (unchanged)"
  },
  "caja": {
   "screen": [104, 112],
   "old": [104, 112],
   "what": "mkCaja at (104, 112): the crate of potted flowers on the lawn (the sprite layer, its sort y 136): its bottom row 135 on the lawn, the lawn behind it up to the far corner"
  },
  "hoyos.L": {
   "screen": [
    [48, 186],
    [58, 186],
    [68, 186],
    [78, 186],
    [88, 186]
   ],
   "old": [
    [48, 186],
    [58, 186],
    [68, 186],
    [78, 186],
    [88, 186]
   ],
   "what": "hoyo(L, i): the five holes of bed L (the set draws them at the old points): a flower (florEn) stands in each"
  },
  "hoyos.R": {
   "screen": [
    [192, 186],
    [182, 186],
    [172, 186],
    [162, 186],
    [152, 186]
   ],
   "old": [
    [192, 186],
    [182, 186],
    [172, 186],
    [162, 186],
    [152, 186]
   ],
   "what": "hoyo(R, i): the five holes of bed R (the set draws them at the old points): a flower (florEn) stands in each"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [2.0669, 2.0669, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the yard: the back of the house with its door, the fence with the gate, the flamboyán with the nest, the two beds, the sky"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [16, 146, 113, 60],
   "uses": ["cual-patio.json flor.si.cam", "cual-patio.json flor.no.cam"],
   "to": {
    "pictures": ["flor.si", "flor.no"]
   },
   "crops": {
    "flor.si": {
     "crop": [23, 150, 98, 52],
     "zoom": 2
    },
    "flor.no": {
     "crop": [23, 150, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [22, 30, 196, 104],
   "uses": ["cual-camino.json parque.no.cam"],
   "to": {
    "pictures": ["parque.no"]
   },
   "crops": {
    "parque.no": {
     "crop": [22, 30, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [22, 84, 196, 104],
   "uses": ["cual-camino.json parque.si.cam"],
   "to": {
    "pictures": ["parque.si"]
   },
   "crops": {
    "parque.si": {
     "scene": "camino",
     "what": "drawn by El camino (its sheet's picture): listed here because the pair's other side is this scene's"
    }
   }
  },
  {
   "kind": "cam",
   "old": [24, 40, 180, 95.5],
   "uses": [
    "cual-patio.json hasta mañana.si.cam",
    "cual-patio.json hasta mañana.no.cam"
   ],
   "to": {
    "pictures": [
     "hasta_manana.si",
     "hasta_manana.no"
    ]
   },
   "crops": {
    "hasta_manana.si": {
     "crop": [16, 36, 196, 104],
     "zoom": 1
    },
    "hasta_manana.no": {
     "crop": [16, 36, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [30, 0, 170, 90.2],
   "uses": ["cual-patio.json sol.si.cam", "cual-patio.json sol.no.cam"],
   "to": {
    "pictures": ["sol.si", "sol.no"]
   },
   "crops": {
    "sol.si": {
     "crop": [17, 0, 196, 104],
     "zoom": 1
    },
    "sol.no": {
     "crop": [17, 0, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [30, 124, 150, 79.6],
   "uses": ["cual-patio.json juega.si.cam", "cual-patio.json juega.no.cam"],
   "to": {
    "pictures": ["juega.si", "juega.no"]
   },
   "crops": {
    "juega.si": {
     "crop": [7, 112, 196, 104],
     "zoom": 1
    },
    "juega.no": {
     "crop": [7, 112, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [40, 80, 113, 60],
   "uses": [
    "cual-patio.json niña.si.cam",
    "cual-patio.json niña.no.cam"
   ],
   "to": {
    "pictures": ["nina.si", "nina.no"]
   },
   "crops": {
    "nina.si": {
     "crop": [0, 80, 196, 104],
     "zoom": 1
    },
    "nina.no": {
     "crop": [0, 80, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [40, 100, 170, 90.2],
   "uses": ["cual-patio.json ven.si.cam", "cual-patio.json ven.no.cam", "cual-patio.json mira.si.cam", "cual-patio.json mira.no.cam"],
   "to": {
    "pictures": ["ven.si", "ven.no", "mira.si", "mira.no"]
   },
   "crops": {
    "ven.si": {
     "crop": [27, 93, 196, 104],
     "zoom": 1
    },
    "ven.no": {
     "crop": [27, 93, 196, 104],
     "zoom": 1
    },
    "mira.si": {
     "crop": [27, 93, 196, 104],
     "zoom": 1
    },
    "mira.no": {
     "crop": [27, 93, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [42, 118, 156, 82.8],
   "uses": [
    "cual-patio.json aquí.si.cam",
    "cual-patio.json aquí.no.cam",
    "cual-patio.json allá.si.cam",
    "cual-patio.json allá.no.cam"
   ],
   "to": {
    "pictures": ["aqui.si", "aqui.no", "alla.si", "alla.no"]
   },
   "crops": {
    "aqui.si": {
     "crop": [22, 107, 196, 104],
     "zoom": 1
    },
    "aqui.no": {
     "crop": [22, 107, 196, 104],
     "zoom": 1
    },
    "alla.si": {
     "crop": [22, 107, 196, 104],
     "zoom": 1
    },
    "alla.no": {
     "crop": [22, 107, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [50, 130, 113, 60],
   "uses": ["cual-patio.json amigo.si.cam", "cual-patio.json amigo.no.cam"],
   "to": {
    "pictures": ["amigo.si", "amigo.no"]
   },
   "crops": {
    "amigo.si": {
     "crop": [58, 134, 98, 52],
     "zoom": 2
    },
    "amigo.no": {
     "crop": [58, 134, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [64, 118, 113, 60],
   "uses": [
    "cual-patio.json niño.si.cam",
    "cual-patio.json niño.no.cam"
   ],
   "to": {
    "pictures": ["nino.si", "nino.no"]
   },
   "crops": {
    "nino.si": {
     "crop": [71, 122, 98, 52],
     "zoom": 2
    },
    "nino.no": {
     "crop": [71, 122, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [70, 62, 150, 79.6],
   "uses": ["cual-patio.json vamos.si.cam", "cual-patio.json vamos.no.cam"],
   "to": {
    "pictures": ["vamos.si", "vamos.no"]
   },
   "crops": {
    "vamos.si": {
     "crop": [44, 42, 196, 104],
     "zoom": 1
    },
    "vamos.no": {
     "crop": [44, 42, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "crop",
   "old": [32.83, 146, 54.34, 60],
   "uses": [
    "nivel.js NV flor.p0",
    "nivel.js NV flor.p1"
   ],
   "to": {
    "pictures": ["flor.si", "flor.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [72.83, 80, 54.34, 60],
   "uses": [
    "nivel.js NV familia.p3",
    "nivel.js NV niña.p0",
    "nivel.js NV niña.p2",
    "nivel.js NV juega.p2",
    "nivel.js NV hasta mañana.p3"
   ],
   "to": {
    "pictures": ["nina.si", "nina.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [72.83, 130, 54.34, 60],
   "uses": [
    "nivel.js NV amigo.p0",
    "nivel.js NV amigo.p1"
   ],
   "to": {
    "pictures": ["amigo.si", "amigo.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [74.15, 0, 81.69, 90.2],
   "uses": [
    "nivel.js NV puerta.p3",
    "nivel.js NV juega.p3"
   ],
   "to": {
    "pictures": ["sol.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [76.75, 40, 86.49, 95.5],
   "uses": [
    "nivel.js NV hasta mañana.p0",
    "nivel.js NV hasta mañana.p1"
   ],
   "to": {
    "pictures": [
     "hasta_manana.si",
     "hasta_manana.no"
    ],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [93.33, 118, 54.34, 60],
   "uses": [
    "nivel.js NV se sienta.p2",
    "nivel.js NV niña.p1",
    "nivel.js NV amigo.p2",
    "nivel.js NV ven.p2"
   ],
   "to": {
    "pictures": ["nino.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [93.95, 124, 72.09, 79.6],
   "uses": [
    "nivel.js NV hola.p3",
    "nivel.js NV juega.p0",
    "nivel.js NV juega.p1",
    "nivel.js NV vamos.p3"
   ],
   "to": {
    "pictures": ["juega.si", "juega.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [101.15, 100, 81.69, 90.2],
   "uses": [
    "nivel.js NV ven.p0",
    "nivel.js NV ven.p1",
    "nivel.js NV vamos.p2"
   ],
   "to": {
    "pictures": ["ven.si", "ven.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [109.15, 0, 81.69, 90.2],
   "uses": [
    "nivel.js NV flor.p2"
   ],
   "to": {
    "pictures": ["sol.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [113.95, 62, 72.09, 79.6],
   "uses": [
    "nivel.js NV vamos.p0",
    "nivel.js NV vamos.p1"
   ],
   "to": {
    "pictures": ["vamos.si", "vamos.no"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [-16, -27],
   "uses": [
    "cual-patio.json niño.si.set.cq",
    "cual-patio.json niño.no.set.cq",
    "cual-patio.json niña.si.set.cq",
    "cual-patio.json niña.no.set.cq",
    "cual-patio.json juega.si.set.cq",
    "cual-patio.json juega.no.set.cq",
    "cual-patio.json flor.si.set.cq",
    "cual-patio.json flor.no.set.cq",
    "cual-patio.json sol.si.set.cq",
    "cual-patio.json sol.no.set.cq",
    "cual-patio.json aquí.si.set.cq",
    "cual-patio.json aquí.no.set.cq",
    "cual-patio.json allá.si.set.cq",
    "cual-patio.json allá.no.set.cq",
    "cual-patio.json amigo.no.set.cq",
    "cual-camino.json parque.no.set.cq"
   ],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0): not a place"
  },
  {
   "kind": "point",
   "old": [1, -1],
   "uses": ["d-la-bola.json beats.22", "que-es-esto.json beats.6.after.0"],
   "to": {
    "none": true
   },
   "what": "acts.ojos x, y: where the frog's eyes look (a direction), not a place"
  },
  {
   "kind": "point",
   "old": [1, 0],
   "uses": ["que-es-esto.json beats.10.after.0"],
   "to": {
    "none": true
   },
   "what": "acts.ojos x, y: where the frog's eyes look (a direction), not a place"
  },
  {
   "kind": "point",
   "old": [30, 104],
   "uses": ["d-la-bola.json beats.0.set.cq"],
   "to": {
    "floor": [-1.0879, 2.9372, 0]
   },
   "new": [30, 104],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [34, 136],
   "uses": [
    "cual-patio.json hasta mañana.si.set.gente.abuela",
    "cual-patio.json hasta mañana.no.set.gente.abuela"
   ],
   "to": {
    "floor": [-1.0879, 3.5899, 0]
   },
   "new": [34, 136],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [48, 188],
   "uses": ["cual-patio.json flor.no.set.bola"],
   "to": {
    "floor": [2.1213, 6.0376, 0]
   },
   "new": [48, 188],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [50, 160],
   "uses": ["que-es-esto.json beats.26"],
   "to": {
    "floor": [0.6527, 4.4602, 0]
   },
   "new": [50, 160],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [60, 126],
   "uses": [
    "cual-patio.json hasta mañana.si.set.gente.abuelo",
    "cual-patio.json hasta mañana.no.set.gente.abuelo"
   ],
   "to": {
    "floor": [-0.9247, 2.3389, 0]
   },
   "new": [60, 126],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [62, 128],
   "uses": ["hasta-manana.json beats.25.then.6.right.4", "hasta-manana.json beats.25.else.2.right.4"],
   "to": {
    "floor": [-0.7615, 2.3933, 0]
   },
   "new": [62, 128],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [64, 153],
   "uses": ["cual-patio.json ven.no.set.cq"],
   "to": {
    "floor": [2.5021, 4.6778, 0]
   },
   "new": [64, 153],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [68, 176],
   "uses": [
    "cual-patio.json aquí.si.set.gente.carmen",
    "cual-patio.json aquí.no.set.gente.carmen",
    "cual-patio.json allá.si.set.gente.luis",
    "cual-patio.json allá.no.set.gente.luis"
   ],
   "to": {
    "floor": [2.0125, 4.841, 0]
   },
   "new": [68, 176],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [72, 157],
   "uses": ["cual-patio.json amigo.si.set.cq"],
   "to": {
    "floor": [2.9372, 4.6778, 0]
   },
   "new": [72, 157],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [84, 150],
   "uses": ["d-la-bola.json beats.0.set.gente.carmen", "h-patio.json beats.0.set.gente.carmen", "h-patio.json beats.20"],
   "to": {
    "floor": [0.9247, 3.1004, 0]
   },
   "new": [80, 150],
   "moved": true,
   "why": "Carmen at the start of d-la-bola and h-patio (and h-patio beats.20): 4 px further left (the hint hand pointing at her, h-patio beats.23, reached the frog's face at the crate's place)",
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [86, 136],
   "uses": [
    "las-flores.json beats.29",
    "cual-patio.json niña.si.set.gente.carmen",
    "cual-patio.json hasta mañana.si.set.gente.mama",
    "cual-patio.json hasta mañana.no.set.gente.mama"
   ],
   "to": {
    "floor": [0.3264, 2.1757, 0]
   },
   "new": [86, 136],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [86, 138],
   "uses": [
    "cual-patio.json niña.no.set.gente.mama"
   ],
   "to": {
    "floor": [0.4351, 2.2845, 0]
   },
   "new": [86, 138],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [90, 182],
   "uses": ["cual-patio.json amigo.no.set.bola"],
   "to": {
    "floor": [2.9372, 4.569, 0]
   },
   "new": [90, 182],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [102, 155],
   "uses": ["cual-patio.json mira.si.set.cq"],
   "to": {
    "floor": [3.6443, 3.7531, 0]
   },
   "new": [102, 155],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [106, 178],
   "uses": ["cual-patio.json ven.si.set.polvo"],
   "to": {
    "floor": [3.1548, 3.9163, 0]
   },
   "new": [106, 178],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [106, 180],
   "uses": ["cual-patio.json mira.no.set.polvo"],
   "to": {
    "floor": [3.2636, 4.0251, 0]
   },
   "new": [106, 180],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [112, 126],
   "uses": [
    "cual-patio.json hasta mañana.si.set.gente.papa",
    "cual-patio.json hasta mañana.no.set.gente.papa"
   ],
   "to": {
    "floor": [0.4895, 0.9247, 0]
   },
   "new": [112, 126],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [112, 153],
   "uses": ["cual-patio.json ven.si.set.cq"],
   "to": {
    "floor": [3.8075, 3.3724, 0]
   },
   "new": [112, 153],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [112, 155],
   "uses": ["cual-patio.json mira.no.set.cq"],
   "to": {
    "floor": [3.9163, 3.4811, 0]
   },
   "new": [112, 155],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [118, 105],
   "uses": [
    "cual-patio.json hasta mañana.no.set.cq"
   ],
   "to": {
    "floor": [1.3598, 0.5983, 0]
   },
   "new": [118, 105],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [118, 180],
   "uses": ["cual-patio.json amigo.si.set.gente.luis", "cual-patio.json amigo.no.set.gente.luis"],
   "to": {
    "floor": [3.5899, 3.6987, 0]
   },
   "new": [118, 180],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [120, 170],
   "uses": [
    "cual-patio.json niño.si.set.gente.luis",
    "cual-patio.json niño.no.set.gente.carmen"
   ],
   "to": {
    "floor": [3.1004, 3.1004, 0]
   },
   "new": [120, 170],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [122, 111],
   "uses": ["cual-patio.json vamos.no.set.cq"],
   "to": {
    "floor": [1.795, 0.8159, 0]
   },
   "new": [122, 111],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [124, 124],
   "uses": ["cual-patio.json ven.no.set.rizo", "cual-patio.json mira.si.set.rizo"],
   "to": {
    "screen": [124, 124]
   },
   "what": "in the air (the bird, the loop it flew): a screen point over the yard, unchanged"
  },
  {
   "kind": "point",
   "old": [124, 128],
   "uses": ["cual-patio.json ven.no.set.ave", "cual-patio.json mira.si.set.ave"],
   "to": {
    "screen": [124, 128]
   },
   "what": "in the air (the bird, the loop it flew): a screen point over the yard, unchanged"
  },
  {
   "kind": "point",
   "old": [126, 172],
   "uses": ["cual-patio.json juega.si.set.gente.luis", "cual-patio.json juega.no.set.gente.luis"],
   "to": {
    "floor": [3.3724, 3.046, 0]
   },
   "new": [126, 172],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [128, 99],
   "uses": ["cual-patio.json vamos.si.set.cq"],
   "to": {
    "floor": [1.3054, 0, 0]
   },
   "new": [128, 99],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [130, 101],
   "uses": [
    "cual-patio.json hasta mañana.si.set.cq"
   ],
   "to": {
    "floor": [1.4686, 0.0544, 0]
   },
   "new": [130, 101],
   "what": "the frog (cq x, y): the ground under his feet; the same screen place"
  },
  {
   "kind": "point",
   "old": [134, 132],
   "uses": ["cual-patio.json vamos.si.set.polvo"],
   "to": {
    "floor": [1.4142, 0.6527, 0]
   },
   "new": [134, 132],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [136, 164],
   "uses": ["d-buenas-noches.json beats.4"],
   "to": {
    "floor": [3.2092, 2.3389, 0]
   },
   "new": [136, 164],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [140, 172],
   "uses": ["cual-patio.json juega.si.set.bola"],
   "to": {
    "floor": [3.7531, 2.6652, 0]
   },
   "new": [140, 172],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [146, 174],
   "uses": ["cual-patio.json juega.no.set.bola"],
   "to": {
    "floor": [4.0251, 2.6109, 0]
   },
   "new": [146, 174],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 150],
   "uses": ["d-la-bola.json beats.0.set.gente.luis", "h-patio.json beats.0.set.gente.luis"],
   "to": {
    "floor": [3.6443, 0.3807, 0]
   },
   "new": [180, 150],
   "moved": true,
   "why": "Luis at the start of d-la-bola and h-patio: right of the gate, not before it (the hint hand pointing at the gate, h-patio beats.12, was on his face)",
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [160, 178],
   "uses": ["cual-patio.json mira.si.set.gente.luis"],
   "to": {
    "floor": [4.6234, 2.4477, 0]
   },
   "new": [160, 178],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [162, 150],
   "uses": ["d-la-bola.json beats.0.set.bola", "h-patio.json beats.0.set.bola"],
   "to": {
    "floor": [3.1548, 0.8703, 0]
   },
   "new": [162, 150],
   "what": "on the lawn (the ball, the dust of a hop): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [168, 120],
   "uses": ["cual-patio.json vamos.si.set.gente.carmen"],
   "to": {
    "floor": [1.6862, -0.9247, 0]
   },
   "new": [168, 120],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [170, 138],
   "uses": ["cual-patio.json vamos.no.set.gente.carmen"],
   "to": {
    "floor": [2.7196, 0, 0]
   },
   "new": [170, 138],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [170, 160],
   "uses": ["d-buenas-noches.json beats.5"],
   "to": {
    "floor": [3.9163, 1.1966, 0]
   },
   "new": [170, 160],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [170, 176],
   "uses": ["cual-patio.json ven.si.set.gente.carmen", "cual-patio.json ven.no.set.gente.carmen"],
   "to": {
    "floor": [4.7866, 2.0669, 0]
   },
   "new": [170, 176],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [170, 178],
   "uses": ["cual-patio.json mira.no.set.gente.luis"],
   "to": {
    "floor": [4.8954, 2.1757, 0]
   },
   "new": [170, 178],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [186, 170],
   "uses": ["hasta-manana.json beats.21"],
   "to": {
    "floor": [4.8954, 1.3054, 0]
   },
   "new": [186, 170],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [198, 166],
   "uses": ["hasta-manana.json beats.25.then.2.right.2", "hasta-manana.json beats.25.else.6.right.2"],
   "to": {
    "floor": [5.0041, 0.7615, 0]
   },
   "new": [198, 166],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "x",
   "old": [60],
   "uses": [
    "nivel.js NV flor.p0",
    "nivel.js NV flor.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [100],
   "uses": [
    "nivel.js NV familia.p3",
    "nivel.js NV niña.p0",
    "nivel.js NV niña.p2",
    "nivel.js NV juega.p2",
    "nivel.js NV amigo.p0",
    "nivel.js NV amigo.p1",
    "nivel.js NV hasta mañana.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [120],
   "uses": [
    "nivel.js NV hasta mañana.p0",
    "nivel.js NV hasta mañana.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [130],
   "uses": [
    "nivel.js NV hola.p3",
    "nivel.js NV juega.p0",
    "nivel.js NV juega.p1",
    "nivel.js NV vamos.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [142],
   "uses": [
    "nivel.js NV ven.p0",
    "nivel.js NV ven.p1",
    "nivel.js NV vamos.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [150],
   "uses": [
    "nivel.js NV flor.p2",
    "nivel.js NV vamos.p0",
    "nivel.js NV vamos.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "nino.si": {
   "world": [1.9581, 1.9581, 0],
   "screen": [120, 148],
   "zoom": 2,
   "crop": [71, 122, 98, 52],
   "what": "Luis on the lawn, close"
  },
  "nino.no": {
   "world": [1.9581, 1.9581, 0],
   "screen": [120, 148],
   "zoom": 2,
   "crop": [71, 122, 98, 52],
   "what": "Carmen there, close"
  },
  "nina.si": {
   "world": [0.4351, 1.7406, 0],
   "screen": [96, 132],
   "zoom": 1,
   "crop": [0, 80, 196, 104],
   "what": "Carmen by the crate"
  },
  "nina.no": {
   "world": [0.4351, 1.7406, 0],
   "screen": [96, 132],
   "zoom": 1,
   "crop": [0, 80, 196, 104],
   "what": "mamá there"
  },
  "juega.si": {
   "world": [2.4205, 3.2364, 0],
   "screen": [105, 164],
   "zoom": 1,
   "crop": [7, 112, 196, 104],
   "what": "Luis kicks the ball up"
  },
  "juega.no": {
   "world": [2.4205, 3.2364, 0],
   "screen": [105, 164],
   "zoom": 1,
   "crop": [7, 112, 196, 104],
   "what": "Luis holds a pot, the ball at his feet"
  },
  "flor.si": {
   "world": [2.1757, 4.7866, 0],
   "screen": [72, 176],
   "zoom": 2,
   "crop": [23, 150, 98, 52],
   "what": "one red flower in bed L, close"
  },
  "flor.no": {
   "world": [2.1757, 4.7866, 0],
   "screen": [72, 176],
   "zoom": 2,
   "crop": [23, 150, 98, 52],
   "what": "the ball by bed L, no flower, close"
  },
  "sol.si": {
   "world": [-3.7803, -3.5083, 0],
   "screen": [115, 45],
   "zoom": 1,
   "crop": [17, 0, 196, 104],
   "what": "the sun over the fence, by day"
  },
  "sol.no": {
   "world": [-3.7803, -3.5083, 0],
   "screen": [115, 45],
   "zoom": 1,
   "crop": [17, 0, 196, 104],
   "what": "the moon, at night"
  },
  "aqui.si": {
   "world": [2.5565, 2.5565, 0],
   "screen": [120, 159],
   "zoom": 1,
   "crop": [22, 107, 196, 104],
   "what": "Carmen beside bed L, a flower in it"
  },
  "aqui.no": {
   "world": [2.5565, 2.5565, 0],
   "screen": [120, 159],
   "zoom": 1,
   "crop": [22, 107, 196, 104],
   "what": "Carmen beside bed L, the flower in bed R"
  },
  "alla.si": {
   "world": [2.5565, 2.5565, 0],
   "screen": [120, 159],
   "zoom": 1,
   "crop": [22, 107, 196, 104],
   "what": "Luis beside bed L, the flower in bed R"
  },
  "alla.no": {
   "world": [2.5565, 2.5565, 0],
   "screen": [120, 159],
   "zoom": 1,
   "crop": [22, 107, 196, 104],
   "what": "Luis beside bed L, a flower in it"
  },
  "amigo.si": {
   "world": [2.2573, 2.9644, 0],
   "screen": [107, 160],
   "zoom": 2,
   "crop": [58, 134, 98, 52],
   "what": "Luis, the frog beside him, close"
  },
  "amigo.no": {
   "world": [2.2573, 2.9644, 0],
   "screen": [107, 160],
   "zoom": 2,
   "crop": [58, 134, 98, 52],
   "what": "Luis, the ball beside him, close"
  },
  "ven.si": {
   "world": [1.9309, 1.659, 0],
   "screen": [125, 145],
   "zoom": 1,
   "crop": [27, 93, 196, 104],
   "what": "Carmen calls, the frog hops to her"
  },
  "ven.no": {
   "world": [1.9309, 1.659, 0],
   "screen": [125, 145],
   "zoom": 1,
   "crop": [27, 93, 196, 104],
   "what": "Carmen points up, the frog looks at the bird"
  },
  "mira.si": {
   "world": [1.9309, 1.659, 0],
   "screen": [125, 145],
   "zoom": 1,
   "crop": [27, 93, 196, 104],
   "what": "Luis points up, the frog looks at the bird"
  },
  "mira.no": {
   "world": [1.9309, 1.659, 0],
   "screen": [125, 145],
   "zoom": 1,
   "crop": [27, 93, 196, 104],
   "what": "Luis calls, the frog hops to him"
  },
  "vamos.si": {
   "world": [-0.2992, -1.659, 0],
   "screen": [145, 94],
   "zoom": 1,
   "crop": [44, 42, 196, 104],
   "what": "Carmen at the open gate, the frog hops after her"
  },
  "vamos.no": {
   "world": [-0.2992, -1.659, 0],
   "screen": [145, 94],
   "zoom": 1,
   "crop": [44, 42, 196, 104],
   "what": "Carmen sits with a glass, the frog holds one"
  },
  "hasta_manana.si": {
   "world": [-1.4686, -1.1422, 0],
   "screen": [114, 88],
   "zoom": 1,
   "crop": [16, 36, 196, 104],
   "what": "the family at the back door waves, sunset, the gate open, the frog going"
  },
  "hasta_manana.no": {
   "world": [-1.4686, -1.1422, 0],
   "screen": [114, 88],
   "zoom": 1,
   "crop": [16, 36, 196, 104],
   "what": "the family at the back door waves, by day, the frog stays"
  },
  "parque.no": {
   "world": [-1.6318, -1.6318, 0],
   "screen": [120, 82],
   "zoom": 1,
   "crop": [22, 30, 196, 104],
   "what": "cual-camino's \"parque\" pair, its \"no\" side: the yard, not the park (the old window [22, 30, 196, 104])"
  }
 },
 "level": [
  {
   "w": "puerta",
   "index": 3,
   "picture": "sol.si",
   "old": [74.15, 0, 81.69, 90.2],
   "crop": [17, 0, 196, 104],
   "zoom": 1
  },
  {
   "w": "hola",
   "index": 3,
   "picture": "juega.si",
   "old": [93.95, 124, 72.09, 79.6],
   "crop": [7, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "se sienta",
   "index": 2,
   "picture": "nino.si",
   "old": [93.33, 118, 54.34, 60],
   "crop": [71, 122, 98, 52],
   "zoom": 2
  },
  {
   "w": "familia",
   "index": 3,
   "picture": "nina.si",
   "old": [72.83, 80, 54.34, 60],
   "crop": [0, 80, 196, 104],
   "zoom": 1
  },
  {
   "w": "niña",
   "index": 0,
   "picture": "nina.si",
   "old": [72.83, 80, 54.34, 60],
   "crop": [0, 80, 196, 104],
   "zoom": 1
  },
  {
   "w": "niña",
   "index": 1,
   "picture": "nino.si",
   "old": [93.33, 118, 54.34, 60],
   "crop": [71, 122, 98, 52],
   "zoom": 2
  },
  {
   "w": "niña",
   "index": 2,
   "picture": "nina.no",
   "old": [72.83, 80, 54.34, 60],
   "crop": [0, 80, 196, 104],
   "zoom": 1
  },
  {
   "w": "flor",
   "index": 0,
   "picture": "flor.si",
   "old": [32.83, 146, 54.34, 60],
   "crop": [23, 150, 98, 52],
   "zoom": 2
  },
  {
   "w": "flor",
   "index": 1,
   "picture": "flor.no",
   "old": [32.83, 146, 54.34, 60],
   "crop": [23, 150, 98, 52],
   "zoom": 2
  },
  {
   "w": "flor",
   "index": 2,
   "picture": "sol.no",
   "old": [109.15, 0, 81.69, 90.2],
   "crop": [17, 0, 196, 104],
   "zoom": 1
  },
  {
   "w": "juega",
   "index": 0,
   "picture": "juega.si",
   "old": [93.95, 124, 72.09, 79.6],
   "crop": [7, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "juega",
   "index": 1,
   "picture": "juega.no",
   "old": [93.95, 124, 72.09, 79.6],
   "crop": [7, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "juega",
   "index": 2,
   "picture": "nina.si",
   "old": [72.83, 80, 54.34, 60],
   "crop": [0, 80, 196, 104],
   "zoom": 1
  },
  {
   "w": "juega",
   "index": 3,
   "picture": "sol.si",
   "old": [74.15, 0, 81.69, 90.2],
   "crop": [17, 0, 196, 104],
   "zoom": 1
  },
  {
   "w": "amigo",
   "index": 0,
   "picture": "amigo.si",
   "old": [72.83, 130, 54.34, 60],
   "crop": [58, 134, 98, 52],
   "zoom": 2
  },
  {
   "w": "amigo",
   "index": 1,
   "picture": "amigo.no",
   "old": [72.83, 130, 54.34, 60],
   "crop": [58, 134, 98, 52],
   "zoom": 2
  },
  {
   "w": "amigo",
   "index": 2,
   "picture": "nino.si",
   "old": [93.33, 118, 54.34, 60],
   "crop": [71, 122, 98, 52],
   "zoom": 2
  },
  {
   "w": "ven",
   "index": 0,
   "picture": "ven.si",
   "old": [101.15, 100, 81.69, 90.2],
   "crop": [27, 93, 196, 104],
   "zoom": 1
  },
  {
   "w": "ven",
   "index": 1,
   "picture": "ven.no",
   "old": [101.15, 100, 81.69, 90.2],
   "crop": [27, 93, 196, 104],
   "zoom": 1
  },
  {
   "w": "ven",
   "index": 2,
   "picture": "nino.si",
   "old": [93.33, 118, 54.34, 60],
   "crop": [71, 122, 98, 52],
   "zoom": 2
  },
  {
   "w": "vamos",
   "index": 0,
   "picture": "vamos.si",
   "old": [113.95, 62, 72.09, 79.6],
   "crop": [44, 42, 196, 104],
   "zoom": 1
  },
  {
   "w": "vamos",
   "index": 1,
   "picture": "vamos.no",
   "old": [113.95, 62, 72.09, 79.6],
   "crop": [44, 42, 196, 104],
   "zoom": 1
  },
  {
   "w": "vamos",
   "index": 2,
   "picture": "ven.no",
   "old": [101.15, 100, 81.69, 90.2],
   "crop": [27, 93, 196, 104],
   "zoom": 1
  },
  {
   "w": "vamos",
   "index": 3,
   "picture": "juega.si",
   "old": [93.95, 124, 72.09, 79.6],
   "crop": [7, 112, 196, 104],
   "zoom": 1
  },
  {
   "w": "hasta mañana",
   "index": 0,
   "picture": "hasta_manana.si",
   "old": [76.75, 40, 86.49, 95.5],
   "crop": [16, 36, 196, 104],
   "zoom": 1
  },
  {
   "w": "hasta mañana",
   "index": 1,
   "picture": "hasta_manana.no",
   "old": [76.75, 40, 86.49, 95.5],
   "crop": [16, 36, 196, 104],
   "zoom": 1
  },
  {
   "w": "hasta mañana",
   "index": 3,
   "picture": "nina.si",
   "old": [72.83, 80, 54.34, 60],
   "crop": [0, 80, 196, 104],
   "zoom": 1
  }
 ],
 "clips": {},
 "clipsWhat": "patio.js never calls clip()",
 "front": {
  "how": "nothing of the set covers a character: in the old picture the background (fondo: the house, the fence, the gate, the tree, the nest, the beds) was drawn before everyone, and every place is on the lawn before the house, the fence and the tree (checked: floor). The crate, the flowers, the sack and the ball stay in the sprite layer, in its list sorted by y, as before",
  "parts": {}
 },
 "shadows": {
  "bola": {
   "radius": 0.28,
   "at": "the ground point under it on screen (unproject(x, y - 1)), whether it lies there or is in the air over it (W.bola.h > 0: the shadow stays on the ground under it)",
   "when": "W.bola, and that ground point is on the lawn (x > CX, y > CY: not the ball in the tree, 196, 64, nor its flight there)",
   "cast": "castShadow(g.x, g.y, .05, .28)",
   "why": "round 3: the ball had no shadow and read as hanging in the air in front of the fence"
  },
  "coqui": {
   "radius": 0.45,
   "at": "the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))",
   "when": "W.cq.vis and al > .5",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "grown": 0.35,
    "nino": 0.3,
    "bebe": 0.25
   },
   "at": "the ground point under their feet on screen (unproject(x, y - 1))",
   "when": "visible (vis !== 0, al > .5); the baby only on the ground, not in mamá's arms (bebe.z)",
   "cast": "standing: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); sitting on the grass (sent): castShadow(g.x, g.y, .3, r)"
  },
  "dropped": "patio.js:108 rana()'s dotted shadow under the frog is not drawn: the engine casts his"
 },
 "dropped": [
  "patio.js:129 c.drawImage(spr(\"cielo\" + n)) and patio.js:132 c.drawImage(spr(\"patio\"...), fondo()) -> the set, for setKey(W)",
  "patio.js:147 the light of the hour (orange .10 at sol 2, red .17 at 3) and patio.js:148 W.osc (dark blue over everything) -> baked into the set (setKey hora); the characters, the props and the fireflies are not dimmed (El frente's rule)",
  "patio.js:108 the frog's dotted shadow -> the engine's cast shadow"
 ],
 "flowerLeaves": {
  "what": "round 6: a flower in the ground comes with its own leaves: a clump drawn by the sprite layer immediately before the flower (moves: the line of the beds), at its foot (x, y = hoyo(k, i)), 1:1, not dimmed by the hour (the characters are not; the set bakes the light). Each stage: pixel (x + x0 + col, y + y0 + row) of rows[row][col] is palette[that letter], \".\" none. open: the flower open (f.k), its head x - 4 to x + 4, rows y - 18 to y - 10: the clump 11 wide (x - 5 to x + 5), from y - 1 up to 1 to 4 rows over the head (y - 19 to y - 22), narrower at its foot. bud: the bud (!f.k), x - 2 to x + 2, rows y - 10 to y - 5: 9 wide (x - 4 to x + 4), up to y - 13. A clump stays inside its own hole's 10 px: a neighbour's head is never under it, and neighbours in a full bed join into one row of leaves",
  "palette": {
   "d": [20, 83, 45],
   "l": [28, 108, 54],
   "t": [46, 154, 72]
  },
  "stages": {
   "open": {
    "x0": -5,
    "y0": -22,
    "rows": [".....t.....", "...tddd.d..", "..dltlttd..", ".ttldllllt.", ".dllllltld.", "dltdlllllld", "dllllldltld", "dldtllllldd", "dlllldllltd", "ddlltllldld", "dllldllllld", "dlllltldlld", "dlldlllllld", "dllllltllld", "dtdlllllldd", "dlllldltlld", "ddtlllllddd", "..dldllld..", "..dtllldd..", "..ddlllld..", "..dltldld..", "..ddddddd.."],
    "head": [-4, -18, 9, 9]
   },
   "bud": {
    "x0": -4,
    "y0": -13,
    "rows": ["....t....", "..tdldt..", ".dltttdd.", ".ddlllld.", "tlllltllt", "ddlllllld", "dllldltld", "dtllllldd", "dlldllltd", "ddtlllddd", "..dllld..", "..dtldd..", "..ddddd.."],
    "head": [-2, -10, 5, 6]
   }
  },
  "gets": [
   {
    "line": 135,
    "what": "the flowers in the beds (florEn at hoyo(k, i)): every one, open or bud, in every story, review and level picture (cual-patio flor, aquí, allá: the flower in bed L's or R's first hole)"
   }
  ],
  "not": [
   {
    "line": 60,
    "what": "mkCaja: the tulips in the crate (in pots, not in the ground)"
   },
   {
    "line": 69,
    "what": "mkCosa flor: a flower in a hand, flying (vuelaA), in Carmen's hair (alpelo), in the basket, the nest or a card"
   },
   {
    "line": 144,
    "what": "the butterflies (FLOR colours): not flowers"
   },
   {
    "line": "juego.js",
    "what": "the bubbles and the answer cards (bub, respIcon): drawn by the game"
   }
  ]
 },
 "moves": [
  {
   "line": 16,
   "act": "*",
   "src": "SOLY=[24,40,56,73]",
   "to": "SOLY=[26,40,56,73]",
   "values": [
    {
     "key": "W.soly",
     "old": 24,
     "new": 26
    }
   ],
   "why": "the sun at its highest 2 px lower: its touch box ([SOLX - 14, soly - 14, 28, 28]) and so its hint frame (12 px round it) wholly inside the view (las-flores and h-patio ask for the sun; at soly 24 the frame reached 2 px over the picture's top). W.soly 24 in a recorded run is 26"
  },
  {
   "line": 58,
   "act": "*",
   "src": "ESTRELLAS=[[60,18],[84,40],[124,12],[150,36],[40,46],[112,58],[72,64],[140,60]]",
   "to": "ESTRELLAS=[[60,18],[84,40],[124,12],[150,36],[40,46],[100,44],[72,64],[140,60]]",
   "why": "round 3: the sixth star (112, 58) sat half hidden on the top of the fence's first post (raised with the fence) and read as a lamp on it; it goes up and left into the open sky over the gap between the house and the fence. The others are as before: in the sky, or wholly behind the set (60, 18, 40, 46 and 72, 64 behind the house, 140, 60 behind the gate's left post)"
  },
  {
   "line": 208,
   "act": "asoma",
   "src": "W.gente.abuela={x:42,y:116,pose:\"wave\",dir:1}",
   "to": "W.gente.abuela={x:52,y:108,pose:\"wave\",dir:1}",
   "places": [
    {
     "who": "abuela",
     "old": [42, 116],
     "new": [52, 108],
     "world": [-2.1213, 1.5774, 0]
    }
   ],
   "why": "acts.asoma: abuela in the back door, in the doorway: on its threshold (the house floor, just inside the wall's face), in its middle, the dark room round her head and shoulders, as the old one stood in the old door (round 3: round 2 had her on the step's front edge, and she read as standing in front of the wall). The door stands on the house wall, seen at the angle: its middle is 10 px right of the old one (the whole door, its hint frame and who stands in it inside the wide view with a margin, as El balcón and La sala keep it): 10 px right, -8 rows"
  },
  {
   "line": 240,
   "act": "seva",
   "src": "await mueve(id,44,118)",
   "to": "await mueve(id,59,115)",
   "places": [
    {
     "who": "whoever",
     "old": [44, 118],
     "new": [59, 115],
     "world": [-1.5502, 1.7678, 0]
    }
   ],
   "why": "acts.seva: whoever goes in walks to the back door (the step's front, in the door's middle: moved with it), then is gone"
  },
  {
   "line": 295,
   "act": "juntos",
   "src": "await Promise.all([mueve(id,170,124),acts.ir({a:\"porton\"})])",
   "to": "await Promise.all([mueve(id,165,116),acts.ir({a:\"porton\"})])",
   "places": [
    {
     "who": "whoever",
     "old": [170, 124],
     "new": [165, 116],
     "world": [1.387, -1.0607, 0]
    }
   ],
   "why": "acts.juntos: two go to the gate together: the one who walks ends right of the gate, before its right post. The fence runs up towards the far corner, so the gate stands 16 rows further back than the old one; the walk follows it 8 rows up and 5 px left (as far as the fence behind them allows: 5 rows of lawn between the feet and the fence's foot, round 3). The frog's place at the gate (LUGAR.porton) went up with the gate too (round 4, below): he stands left of the one who walks, before the opening"
  },
  {
   "line": 308,
   "act": "luiscorre",
   "src": "await mueve(\"luis\",170,124,8)",
   "to": "await mueve(\"luis\",165,116,8)",
   "places": [
    {
     "who": "luis",
     "old": [170, 124],
     "new": [165, 116],
     "world": [1.387, -1.0607, 0]
    }
   ],
   "why": "acts.luiscorre: Luis runs to the gate (then opens it, acts.abre): to the same place as acts.juntos"
  },
  {
   "line": 135,
   "act": "*",
   "src": "const h=hoyo(k,i);florEn(c,h[0],h[1],f);",
   "to": "const h=hoyo(k,i);flowerLeaves(c,h[0],h[1],f);florEn(c,h[0],h[1],f);",
   "why": "round 6: draw the clump first: every flower in a bed (the only place patio.js plants one: florEn at hoyo(k, i), the beds' entry in the sprite list at y CAMA[k][1] + 12) gets its own leaves, drawn immediately before it at its foot (flowerLeaves), so at its depth: whoever stands behind the bed is behind the leaves, whoever stands in front is in front, as with the flower. flowerLeaves(g, x, y, f): the stage f.k ? open : bud, each pixel of its rows at (x + x0 + col, y + y0 + row), colours palette"
  },
  {
   "line": 86,
   "act": "*",
   "src": "porton:[128,104,.85]",
   "to": "porton:[126,86,.85]",
   "places": [
    {
     "who": "cq",
     "old": [128, 104],
     "new": [126, 86],
     "world": [0.5439, -0.6527, 0]
    }
   ],
   "why": "round 4: LUGAR.porton, the frog at the gate (acts.ir a porton; acts.juntos), follows the gate: on the lawn before its opening, 17.5 rows before the fence's line (the old picture: 17; round 3 left him 34.5 rows before it, where the old hop counts put him), his middle at x 142 inside the opening's columns. -2 px, -18 rows. W.cq at (128, 104) in a recorded run is here (places: who cq). Some hop counts change: hops"
  },
  {
   "line": 86,
   "act": "*",
   "src": "sale:[134,84,.5]",
   "to": "sale:[130,68,.5]",
   "places": [
    {
     "who": "cq",
     "old": [134, 84],
     "new": [130, 68],
     "world": [-0.3264, -1.7406, 0]
    }
   ],
   "why": "round 4: LUGAR.sale, where the frog fades (acts.sevan: three hops from the gate), is through the opening, on the path 2.5 rows past the fence's line (the old picture: 3; round 3: 11.5 rows before it, on the lawn), his box wholly between the posts: he is seen to go out through the gate before he fades. -4 px, -16 rows. Some hop counts change: hops"
  },
  {
   "line": 195,
   "act": "inicio9",
   "src": "carmen:{x:86,y:136,pose:\"idle\"}}",
   "to": "carmen:{x:94,y:137,pose:\"idle\"}}",
   "places": [
    {
     "who": "carmen",
     "old": [86, 136],
     "new": [94, 137],
     "world": [0.5983, 2.0125, 0]
    }
   ],
   "why": "acts.inicio9: Carmen 8 px further right, in front of the crate's left corner: the hint hand pointing at her (las-flores beats.12) was on the frog's face, at the door's place (LUGAR.inicio)"
  },
  {
   "line": 248,
   "act": "inicio10",
   "src": "carmen:{x:50,y:160,pose:\"idle\",dir:1}",
   "to": "carmen:{x:37,y:178,pose:\"idle\",dir:1}",
   "places": [
    {
     "who": "carmen",
     "old": [50, 160],
     "new": [37, 178],
     "world": [1.2782, 5.7928, 0]
    }
   ],
   "why": "acts.inicio10: Carmen at the left, lower, beside bed L: the answer cards over the frog at the door and by her (que-es-esto beats.3, 10) covered her head, and the hand at the left card her face"
  },
  {
   "line": 290,
   "act": "inicio11",
   "src": "W.gente={abuela:{x:34,y:136,pose:\"idle\",dir:1},abuelo:{x:60,y:126,pose:\"ojos\",lleva:\"bizcocho\",dir:1},mama:{x:86,y:136,pose:\"idle\"},bebe:{x:97,y:109,z:137,est:\"idle\"},papa:{x:112,y:126,pose:\"idle\"},",
   "to": "W.gente={abuela:{x:46,y:136,pose:\"idle\",dir:1},abuelo:{x:70,y:129,pose:\"ojos\",lleva:\"bizcocho\",dir:1},mama:{x:92,y:136,pose:\"idle\"},bebe:{x:103,y:109,z:137,est:\"idle\"},papa:{x:114,y:136,pose:\"idle\"},",
   "places": [
    {
     "who": "abuela",
     "old": [34, 136],
     "new": [46, 136],
     "world": [-0.7615, 3.2636, 0]
    },
    {
     "who": "abuelo",
     "old": [60, 126],
     "new": [70, 129],
     "world": [-0.4895, 2.2301, 0]
    },
    {
     "who": "mama",
     "old": [86, 136],
     "new": [92, 136],
     "world": [0.4895, 2.0125, 0]
    },
    {
     "who": "bebe",
     "old": [97, 109],
     "new": [103, 109],
     "z": 137,
     "world": [-0.6799, 0.2448, 0]
    },
    {
     "who": "papa",
     "old": [112, 126],
     "new": [114, 136],
     "world": [1.0879, 1.4142, 0]
    }
   ],
   "why": "acts.inicio11: the family by the back door, a little further right and closer together, in one row (abuelo 3 px, papá 10 px lower): abuela's hint frame (hasta-manana beats.8) reached 11 px past the view's left side; abuelo's and papá's bubbles (\"amor\", when touched) lay over the fireflies card; the hand at an answer card in the sky (below) was on papá's face. The baby stays in mamá's arms (moved with her)"
  },
  {
   "line": 291,
   "act": "inicio11",
   "src": "luis:{x:150,y:160,pose:\"idle\",dir:-1},carmen:{x:188,y:158,pose:\"alto\",dir:-1}};W.pdoor=1;",
   "to": "luis:{x:178,y:126,pose:\"idle\",dir:-1},carmen:{x:200,y:168,pose:\"alto\",dir:-1}};W.pdoor=1;W.respEn=[164,4];",
   "respEn": [164, 4],
   "places": [
    {
     "who": "luis",
     "old": [150, 160],
     "new": [178, 126],
     "world": [2.2845, -0.8703, 0]
    },
    {
     "who": "carmen",
     "old": [188, 158],
     "new": [200, 168],
     "world": [5.1673, 0.8159, 0]
    }
   ],
   "why": "acts.inicio11: Luis waits right of the gate, by the fence, Carmen in front of the tree: the hint hand pointing at the gate (hasta-manana beats.5) was on Luis's face. And the answer cards stand in the sky at the top right (W.respEn, juego.js: \"a scene that needs its people seen while he chooses puts the bubbles elsewhere\", as banco, mesa, estufa, nevera and comer do): over the frog, at abuela's place and in the middle, they covered the family and Luis (hasta-manana beats.10, 25)"
  }
 ],
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as patio.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
  "rects": {
   "hola": [-16, -46, 34, 44],
   "amor": [-14, -38, 30, 36],
   "como": [-32, -40, 66, 38],
   "bien": [-14, -40, 30, 38],
   "mal": [-14, -40, 30, 38],
   "quien": [-22, -40, 46, 38],
   "lluvia": [-22, -40, 46, 38],
   "q": [-12, -40, 26, 38]
  }
 },
 "talk": {
  "what": "where a bubble goes (patio.js draw: line 150 for a person, 151 for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner cards shown (hud: the sun card, the basket and the nest, the fireflies) and of every face (each visible person's and the frog's, its own too); if none is, the first (the old)",
  "top": "a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2 - (W.lleva ? 18 : 0))",
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
  "faces": "a person's face: [hx - 6, y + top + 5 (the baby: + 4), 12, 10] (eyes to chin, not the hair), hx the head's middle; the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heads": {
   "luis": {
    "top": -41,
    "head": 0
   },
   "luis.sent": {
    "top": -38,
    "head": 0
   },
   "carmen": {
    "top": -41,
    "head": 0
   },
   "carmen.sent": {
    "top": -38,
    "head": 0
   },
   "mama": {
    "top": -54,
    "head": 0
   },
   "mama.sent": {
    "top": -47,
    "head": 0
   },
   "papa": {
    "top": -53,
    "head": 0
   },
   "papa.sent": {
    "top": -46,
    "head": 0
   },
   "abuelo": {
    "top": -51,
    "head": 0
   },
   "abuelo.sent": {
    "top": -44,
    "head": 0
   },
   "abuela": {
    "top": -50,
    "head": 0
   },
   "bebe": {
    "top": -28,
    "head": 0
   }
  },
  "headsWhat": "each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the family sprites drawn at -PX)",
  "boards": "in the 196 x 216 display, then + the view's x0: W.tarjeta sol [2, 2, 36, 54]; W.tarjeta luces [2, 2, 86, 32]; W.tanteo: [2, 2, 26 + 15 max(3, canasta.length), 28] and [119, 2, 75, 28]"
 },
 "code": [
  {
   "line": 16,
   "old": "CAMA L [40,176,56,20], R [144,176,56,20]",
   "to": "the beds (the set paints each at the old ellipse: middle (c[0] + 28, c[1] + 10), radii 28, 10); hoyo() unchanged",
   "note": "points.hoyos.L, hoyos.R"
  },
  {
   "line": 16,
   "old": "SOLX=100, SOLY=[24,40,56,73]",
   "to": {
    "moved": "SOLY=[26,40,56,73]"
   },
   "note": "see moves"
  },
  {
   "line": 58,
   "old": "ESTRELLAS [60,18] [84,40] [124,12] [150,36] [40,46] [112,58] [72,64] [140,60]",
   "to": {
    "moved": "the sixth, [112,58], to [100,44]",
    "point": "estrellas"
   },
   "note": "behind the set (sheet behind); see moves"
  },
  {
   "line": 85,
   "old": "LUGAR.puerta [30,104,0.8]",
   "to": {
    "spot": "frog.puerta",
    "new": [30, 104, 0.8]
   }
  },
  {
   "line": 85,
   "old": "LUGAR.inicio [52,150,1]",
   "to": {
    "spot": "frog.inicio",
    "new": [52, 150, 1]
   }
  },
  {
   "line": 85,
   "old": "LUGAR.centro [104,178,1]",
   "to": {
    "spot": "frog.centro",
    "new": [104, 178, 1]
   }
  },
  {
   "line": 85,
   "old": "LUGAR.caja [104,150,1]",
   "to": {
    "spot": "frog.caja",
    "new": [104, 150, 1]
   }
  },
  {
   "line": 85,
   "old": "LUGAR.camaL [90,164,0.9]",
   "to": {
    "spot": "frog.camaL",
    "new": [90, 164, 0.9]
   }
  },
  {
   "line": 85,
   "old": "LUGAR.camaR [118,164,0.9]",
   "to": {
    "spot": "frog.camaR",
    "new": [118, 164, 0.9]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.luis [112,140,1]",
   "to": {
    "spot": "frog.luis",
    "new": [112, 140, 1]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.carmen [62,130,1]",
   "to": {
    "spot": "frog.carmen",
    "new": [62, 130, 1]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.carmenA [112,116,0.9]",
   "to": {
    "spot": "frog.carmenA",
    "new": [112, 116, 0.9]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.abuela [70,170,1]",
   "to": {
    "spot": "frog.abuela",
    "new": [70, 170, 1]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.porton [128,104,0.85]",
   "to": {
    "spot": "frog.porton",
    "new": [126, 86, 0.85],
    "moved": "round 4: follows the gate (see moves; hop counts: hops)"
   }
  },
  {
   "line": 86,
   "old": "LUGAR.arbol [186,112,0.8]",
   "to": {
    "spot": "frog.arbol",
    "new": [186, 112, 0.8]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.luisC [96,140,0.95]",
   "to": {
    "spot": "frog.luisC",
    "new": [96, 140, 0.95]
   }
  },
  {
   "line": 86,
   "old": "LUGAR.sale [134,84,0.5]",
   "to": {
    "spot": "frog.sale",
    "new": [130, 68, 0.5],
    "moved": "round 4: follows the gate (see moves; hop counts: hops)"
   }
  },
  {
   "line": 87,
   "old": "DETRAS.L [68,176]",
   "to": {
    "spot": "detras.L",
    "new": [68, 176]
   }
  },
  {
   "line": 87,
   "old": "DETRAS.R [172,176]",
   "to": {
    "spot": "detras.R",
    "new": [172, 176]
   }
  },
  {
   "line": 87,
   "old": "ESPERA.luis [160,128]",
   "to": {
    "spot": "espera.luis",
    "new": [160, 128]
   }
  },
  {
   "line": 87,
   "old": "ESPERA.carmen [80,128]",
   "to": {
    "spot": "espera.carmen",
    "new": [80, 128]
   }
  },
  {
   "line": 87,
   "old": "LADOS[0] [84,172]",
   "to": {
    "spot": "lados.0",
    "new": [84, 172]
   }
  },
  {
   "line": 87,
   "old": "LADOS[1] [156,172]",
   "to": {
    "spot": "lados.1",
    "new": [156, 172]
   }
  },
  {
   "line": 89,
   "old": "caja(id): [x - 11, y - alto(id), 22, alto(id)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 93,
   "old": "box caja [104,112,32,24]",
   "to": {
    "thing": "caja",
    "box": [104, 112, 32, 24]
   },
   "note": "the sprite layer's crate: unchanged"
  },
  {
   "line": 93,
   "old": "box camaL [40,160,56,38]",
   "to": {
    "thing": "camaL",
    "box": [40, 159, 57, 39]
   }
  },
  {
   "line": 93,
   "old": "box camaR [144,160,56,38]",
   "to": {
    "thing": "camaR",
    "box": [144, 159, 56, 39]
   }
  },
  {
   "line": 93,
   "old": "box bola [x - 7, y - 13, 14, 14]; saco [x - 13, y - 23, 26, 24]",
   "to": "relative: unchanged"
  },
  {
   "line": 94,
   "old": "box sol [SOLX-14, soly-14, 28, 28]",
   "to": "relative to the sun: unchanged (SOLY: moves)"
  },
  {
   "line": 94,
   "old": "box porton [127,70,40,43]",
   "to": {
    "thing": "porton",
    "box": [115, 42, 48, 63],
    "hand": [133, 46]
   },
   "note": "and hand: the hint hand's point (new: the old had none, so the box's middle)"
  },
  {
   "line": 94,
   "old": "box nido [170,60,22,16]",
   "to": {
    "thing": "nido",
    "box": [170, 60, 22, 16]
   }
  },
  {
   "line": 94,
   "old": "box arbol [168,8,60,106]",
   "to": {
    "thing": "arbol",
    "box": [166, 3, 74, 127]
   }
  },
  {
   "line": 95,
   "old": "box pajaro [p[0]-10, p[1]-20, 20, 22]",
   "to": "relative to the bird: unchanged"
  },
  {
   "line": 95,
   "old": "box puerta [27,57,30,56]",
   "to": {
    "thing": "puerta",
    "box": [34, 40, 35, 80]
   }
  },
  {
   "line": 95,
   "old": "box casa [0,14,61,100]",
   "to": {
    "thing": "casa",
    "box": [0, -1, 86, 164]
   }
  },
  {
   "line": 95,
   "old": "box cerca [60,80,180,33]",
   "to": {
    "thing": "cerca",
    "box": [110, 46, 130, 113]
   }
  },
  {
   "line": 95,
   "old": "box patio [0,113,240,103]",
   "to": {
    "thing": "patio",
    "box": [0, 79, 240, 137]
   }
  },
  {
   "line": 99,
   "old": "gente bebe: drawImage at x - 13, y - 28",
   "to": "relative to the baby: unchanged"
  },
  {
   "line": 100,
   "old": "gente abuela: translate(x, y - 50), scale(-1,1) when dir < 0; drawImage(im,-30,0)",
   "to": "relative to her: unchanged"
  },
  {
   "line": 102,
   "old": "gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 103,
   "old": "the flower in her hair at x + 3, y - h + 2",
   "to": "relative: unchanged"
  },
  {
   "line": 104,
   "old": "what a person holds: cosa at x + d * 14, y - h + 13 (alto, 2 x); x - d * 20, y - h + 30 (offer, 1.4 x); x, y - h + 34 / 38 (1.4 x)",
   "to": "relative: unchanged (the old code's own 1.4 x and 2 x drawings of the small things, kept as they are)"
  },
  {
   "line": 108,
   "old": "rana: the dotted shadow at b.x + 2, q.y + 25",
   "to": "dropped: the engine casts his shadow (shadows.coqui)"
  },
  {
   "line": 110,
   "old": "rana: the eyes at b.x + b.w * .3, .7",
   "to": "relative to the frog: unchanged"
  },
  {
   "line": 113,
   "old": "rana: what he carries at b.x + b.w / 2, b.y + dy + 1; the basket at b.x + b.w - 6, b.y + b.h - 17",
   "to": "relative: unchanged"
  },
  {
   "line": 116,
   "old": "bub2: c.scale(2,2), bub(c,k,0,0,a)",
   "to": "relative: unchanged (the bubbles are drawn at twice their size)"
  },
  {
   "line": 129,
   "old": "c.drawImage(spr(\"cielo\"+n,...),0,0)",
   "to": "dropped: the set's sky, for setKey(W)"
  },
  {
   "line": 130,
   "old": "the stars at ESTRELLAS",
   "to": "behind the set (sheet behind)"
  },
  {
   "line": 131,
   "old": "luna(c,150,26); sol(c, SOLX, soly, n, brilla)",
   "to": {
    "points": ["luna", "sol"]
   },
   "note": "behind the set (sheet behind): unchanged places"
  },
  {
   "line": 132,
   "old": "c.drawImage(spr(\"patio\"+...,()=>fondo(W.porton,W.pdoor)),0,0)",
   "to": "dropped: the set, for setKey(W) (then the sky objects' box redrawn from the set: behind)"
  },
  {
   "line": 136,
   "old": "if(W.caja) c.drawImage(spr(\"caja\",mkCaja),104,112) (sort y 136)",
   "to": {
    "point": "caja",
    "new": [104, 112]
   },
   "note": "the sprite layer: unchanged"
  },
  {
   "line": 135,
   "old": "the flowers in the beds: florEn at hoyo(k, i), sort y CAMA[k][1] + 12",
   "to": {
    "moved": "round 6: each flower's own leaves drawn first (moves; flowerLeaves)"
   },
   "note": "the sprite layer (the set's holes are at hoyo())"
  },
  {
   "line": 142,
   "old": "the loop the bird flew: setLineDash([2,3]) arc at z.x, z.y",
   "to": "screen: unchanged"
  },
  {
   "line": 147,
   "old": "the light of the hour: c.fillRect(0,0,SW,SH)",
   "to": "dropped: baked into the set (setKey hora)"
  },
  {
   "line": 148,
   "old": "W.osc: c.fillRect(0,0,SW,SH)",
   "to": "dropped: baked into the set (setKey hora); the characters are not dimmed"
  },
  {
   "line": 150,
   "old": "a person's bubble at x, y - alto - 1",
   "to": {
    "talk": true
   },
   "note": "sheet talk: the first free place"
  },
  {
   "line": 151,
   "old": "the frog's bubble at b.x + (b.w >> 1), b.y + 2 - (W.lleva ? 18 : 0)",
   "to": {
    "talk": true
   },
   "note": "sheet talk: the first free place"
  },
  {
   "line": 153,
   "old": "talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 156,
   "old": "respIcon ir: [13,27] ...",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 158,
   "old": "respIcon ver: the eyes at x + 13, x + 27",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 159,
   "old": "respIcon ver: the rays [4,6] [20,3] [36,6]",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 164,
   "old": "hud sun card tarjeta(g,3,3,34,52); g.fillRect(5,5,30,40)",
   "to": "display: unchanged"
  },
  {
   "line": 166,
   "old": "hud sun card: the fence g.fillRect(5,42,30,1)",
   "to": "display: unchanged"
  },
  {
   "line": 167,
   "old": "hud tanteo tarjeta(g,3,3,...,26); the basket at 5,7",
   "to": "display: unchanged"
  },
  {
   "line": 169,
   "old": "hud fireflies card tarjeta(g,3,3,84,30); the frog at 5,9",
   "to": "display: unchanged"
  },
  {
   "line": 195,
   "old": "inicio9: luis {x:160,y:128}, carmen {x:86,y:136}, bola {x:174,y:128}",
   "to": {
    "floor": [
     [1.9037, -0.272, 0],
     [0.3264, 2.1757, 0],
     [2.2845, -0.6527, 0]
    ],
    "new": [
     [160, 128],
     [86, 136],
     [174, 128]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 205,
   "old": "ensena: for(const k of [0,1,2,3])",
   "to": "not a place: the sun card's four steps"
  },
  {
   "line": 208,
   "old": "asoma: W.gente.abuela={x:42,y:116,...}",
   "to": {
    "spot": "asoma",
    "new": [52, 108]
   },
   "note": "moved (see moves)"
  },
  {
   "line": 219,
   "old": "final9: the stars [60,150] [180,150] [120,120] [90,170] [150,170]; the butterflies at 48 + i * 24 + (i % 2) 6, 150 + (i % 3) 8",
   "to": "screen effect: unchanged (over the lawn)"
  },
  {
   "line": 220,
   "old": "final9: a firefly at 150, 150",
   "to": "over the lawn: unchanged"
  },
  {
   "line": 223,
   "old": "pelota: mueve(\"luis\",166,150), mueve(\"carmen\",60,150)",
   "to": {
    "floor": [
     [3.2636, 0.7615, 0],
     [0.3807, 3.6443, 0]
    ],
    "new": [
     [166, 150],
     [60, 150]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 231,
   "old": "bolaarbol: the ball to 196, 64 (in the tree, by the nest)",
   "to": "the crown is where it was: unchanged"
  },
  {
   "line": 232,
   "old": "avesale: KIT.aveVa(184,60,5,1)",
   "to": "by the nest, in the air: unchanged"
  },
  {
   "line": 240,
   "old": "seva: mueve(id,44,118)",
   "to": {
    "spot": "seva",
    "new": [59, 115]
   },
   "note": "moved (see moves)"
  },
  {
   "line": 244,
   "old": "luzsale: P [70,160] [150,150] [112,190]",
   "to": {
    "floor": [1.1966, 3.9163, 0],
    "new": [70, 160]
   },
   "note": "over the lawn: the same screen places"
  },
  {
   "line": 248,
   "old": "inicio10: luis {x:190,y:160} (sitting), carmen {x:50,y:160}, saco {x:164,y:165}",
   "to": {
    "floor": [
     [4.4602, 0.6527, 0],
     [0.6527, 4.4602, 0],
     [4.0251, 1.6318, 0]
    ],
    "new": [
     [190, 160],
     [50, 160],
     [164, 165]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 250,
   "old": "aveloop: the loop round 150, 40, r 18; KIT.aveVa(181,66,7,-1)",
   "to": {
    "point": "nido",
    "new": [181, 66]
   },
   "note": "the loop: screen, unchanged; the nest where it was"
  },
  {
   "line": 252,
   "old": "avenido: KIT.aveVa(181,66,8,-1)",
   "to": {
    "point": "nido",
    "new": [181, 66]
   }
  },
  {
   "line": 270,
   "old": "prepA: mueve(\"carmen\",150,140)",
   "to": {
    "floor": [2.2845, 0.6527, 0],
    "new": [150, 140]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 284,
   "old": "alnido: KIT.aveVa(181,66,9,-1)",
   "to": {
    "point": "nido",
    "new": [181, 66]
   }
  },
  {
   "line": 287,
   "old": "final10: the stars [60,40] [150,44] [104,30] [80,60] [130,56]",
   "to": "screen effect: unchanged (in the sky)"
  },
  {
   "line": 290,
   "old": "inicio11: abuela {x:34,y:136}, abuelo {x:60,y:126}, mama {x:86,y:136}, bebe {x:97,y:109,z:137} (in mamá's arms), papa {x:112,y:126}",
   "to": {
    "floor": [
     [-1.0879, 3.5899, 0],
     [-0.9247, 2.3389, 0],
     [0.3264, 2.1757, 0],
     [0.4895, 0.9247, 0]
    ],
    "new": [
     [34, 136],
     [60, 126],
     [86, 136],
     [112, 126]
    ]
   },
   "note": "the floor rule: the same screen places; the baby relative to mamá"
  },
  {
   "line": 291,
   "old": "inicio11: luis {x:150,y:160}, carmen {x:188,y:158}; ave {x:178,y:83} on the fence",
   "to": {
    "floor": [
     [3.3724, 1.7406, 0],
     [4.297, 0.5983, 0]
    ],
    "new": [
     [150, 160],
     [188, 158]
    ],
    "point": "cerca.ave"
   },
   "note": "the floor rule; the bird on the fence, on a post's cap (points cerca.ave)"
  },
  {
   "line": 295,
   "old": "juntos: mueve(id,170,124)",
   "to": {
    "spot": "juntos",
    "new": [165, 116]
   },
   "note": "moved (see moves): right of the gate"
  },
  {
   "line": 296,
   "old": "vuelveluis: mueve(\"luis\",138,138)",
   "to": {
    "floor": [1.8494, 0.8703, 0],
    "new": [138, 138]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 297,
   "old": "alcentro: +o.x || 160, +o.y || 190",
   "to": {
    "floor": [5.2761, 3.1004, 0],
    "new": [160, 190]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 301,
   "old": "viene: mueve(\"carmen\",186,174), mueve(\"abuelo\",52,174)",
   "to": {
    "floor": [
     [5.1129, 1.523, 0],
     [1.4686, 5.1673, 0]
    ],
    "new": [
     [186, 174],
     [52, 174]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 308,
   "old": "luiscorre: mueve(\"luis\",170,124,8)",
   "to": {
    "spot": "juntos",
    "new": [165, 116]
   },
   "note": "moved (see moves): right of the gate"
  },
  {
   "line": 313,
   "old": "final11: the stars [110,70] [170,66] [140,56] [124,96] [160,96]",
   "to": "screen effect: unchanged"
  },
  {
   "line": 316,
   "old": "final11: a firefly comes from 214,120; luzA(l, f[0]+12, f[1]-8, 14, 1)",
   "to": "over the yard: unchanged; relative to the frog"
  },
  {
   "line": 318,
   "old": "sevan: KIT.aveA(150,70,10); hopTo(LUGAR.sale)",
   "to": "the bird in the air: unchanged; the frog out through the gate (LUGAR.sale, moved: see moves), where he fades"
  },
  {
   "line": 323,
   "old": "stake: luzA(l,226,58,14,0)",
   "to": "screen: the firefly leaves to the top right, unchanged"
  },
  {
   "line": 328,
   "old": "CAM.wide [22,0,196,216]",
   "to": {
    "view": "wide",
    "zoom": 1,
    "x0": 22
   }
  },
  {
   "line": 328,
   "old": "heartAt [118,36]",
   "to": {
    "point": "corazon",
    "new": [118, 36]
   }
  },
  {
   "line": 330,
   "old": "fresh(): ave {x:181,y:66}; soly: SOLY[0]",
   "to": {
    "point": "nido",
    "new": [181, 66]
   },
   "note": "the nest where it was; SOLY: moves"
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: patio's fresh() puts him at LUGAR.centro"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": "a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 21 things (old 21), 14 frog places (old 14), 1 view (old 1), 73 positions (old 73), 12 review pairs of cual-patio and cual-camino's parque.no (25 pictures), 27 level pictures (old 27), 120 places of patio.js named in code",
   "hops: 91 pairs of LUGAR places (round(d / 30), 1 to 4, kit.js acts.ir): every count as the old one but these 8, each with porton or sale (round 4: their places followed the gate; the other 12 places keep their points), exactly sheet hops: centro - sale 3 -> 4, caja - sale 2 -> 3, camaL - porton 2 -> 3, camaR - porton 2 -> 3, luis - porton 1 -> 2, carmen - porton 2 -> 3, carmenA - sale 1 -> 2, luisC - sale 2 -> 3",
   "greenery: the crown's lower left lobe reaches 280 px into the bird's box on its nest (behind the bird: the sprite layer draws the bird over it, as the old picture did)",
   "greenery: no pixel the crown's leaves can take (at any wind step) inside the box of the gate, the nest, the door, the house, the beds, the sun at any of its heights or the bird on the fence; the set's parts are arbol, casa, cerca, escalon, nido, porton, puerta (the step is the door's): nothing decorative",
   "wide view (x0 22): the door, its frame and abuela in it from x 33 to 72 (11 px from the left side), from row 40",
   "a strip of wall: 7 px of wall over the door's frame, under the roof's fascia",
   "hint frames, asked or not: the door, the gate, the nest and the sun at each height inside the view (px from its edge: the door 0, the gate 30, the nest 14, the sun at 26 0, the sun at 40 14, the sun at 56 30, the sun at 73 47); the tree's [154,-9,98,151] is not (-34 px on the right, -9 at the top), as the old one: no story or pair asks for the tree",
   "abuela in the door: her feet (52,108) on the threshold (row 108.74 in her column), between the jambs (x 38 to 66); the dark doorway round her head: 7 rows over it, at least 5 px on her left and 5 on her right at every row of her head (idle; waving, over her raised arm)",
   "walks: whoever goes in ends at 59,115, on the door's step in its width (the door 34 to 69, its foot row 120); abuela in the door at 52,108; the walk to the gate ends at 165,116, 6 px right of its right post's foot and 14 rows before it",
   "perch: the bird on its nest has the nest under its feet (6 of 6 columns, its feet row 67); on the fence (inicio11), the boards' tops under its feet (6 of 6)",
   "beds: each of the ten holes is in its bed's earth where the old one was; behind every flower's head (9 x 9 over its hole) only the lawn, in every baked state; the crate's bottom row on the lawn, nothing of the set behind it",
   "lawn (round 4): El frente's grass (GRASS), green at every hour (mean colour of the lawn, El frente's by day hue 76: dia 125,146,63 (hue 75); tarde 131,144,56 (hue 69); tarde2 124,137,52 (hue 69); ocaso 106,129,71 (hue 84); crepusculo 85,114,79 (hue 110); noche 75,100,81 (hue 134))",
   "flowers (round 6): a yellow head at each hole stands out from what is behind it, its leaves (flowerLeaves) and the lawn round them, by 69 at the least (mean CIE76, the 1 px round the head; the old picture's lawn 57); from the lawn 2 to 7 rows over it (flowers.py's measure, every clump drawn) by 46 to 49",
   "sun: the part of its disc in the sky at soly 26: 100%, 40: 100%, 56: 100%, 73: 98%, 109: 0% (the old: the fence hid 2 rows at 73, all at 109; now the field, the hills and the far corner's lawn)",
   "gate (round 3): shut, its leaf fills 99% of the opening (571 px); open, the opening has no pixel of the gate or the fence, and 100 px of the path (day; 100 at night); the open leaf stands in the yard beside it, its face 18.04 px wide on the screen (round 2: edge on)",
   "door (round 3): open, the doorway is a dim room: its pixels' mean / brightest luminance dia 54/72, tarde 58/74, tarde2 59/74, ocaso 52/68, ocaso 52/68, crepusculo 47/61, noche 44/56, noche 44/56 (0 to 255; El frente's dim room is about 60)",
   "stars: 60,18 hidden, 84,40 in the sky, 124,12 in the sky, 150,36 in the sky, 40,46 hidden, 100,44 in the sky, 72,64 hidden, 140,60 hidden (none half hidden, none touching the set, in the night states)",
   "hops in the recorded runs: the frog walks from place to place puerta - centro (6), puerta - arbol (3), centro - arbol (3), centro - caja (3), centro - porton (4), abuela - porton (3), centro - abuela (3), centro - luisC (2), porton - luisC (2), inicio - centro (3), inicio - caja (3), puerta - luis (8), luis - carmen (6), puerta - carmenA (1), luis - carmenA (1); none of these takes a hop more or less (sevan, porton to sale, hops 3 times, as before)",
   "ball: at its 4 places on the lawn the lawn alone behind it, at least 5 rows of lawn between it and the foot of the fence behind it, its ground point on the lawn, where its shadow is cast (shadows.bola) (in the tree, by the nest, as the old: the crown; no shadow)",
   "asks: 69 distinct asks (for abuela, bola, camaL, camaR, carmen, es_flor, es_silla, gracias_abuelo, hm, hm_abuela, ir, luis, pajaro, porton, q_que, sol, ver): every hint frame (box +- 12) wholly inside the view (0 px from its edge at the least), the hint hand on no face; 52 answer cards inside the view, over no one's body (no opaque pixel of anyone's sprite, in their pose, under a card)",
   "NOT the scene's: the hand juego.js draws at an answer card (the left one) reaches onto the frog's face, 46 px under it, in every scene (the card's place and the hand are the game's, respBox and hand()): at the asks for ir, es_flor, q_que, es_silla",
   "bubbles: 84 bubbles at 1128 moments of 18 runs (d-buenas-noches, d-la-bola, h-patio, hasta-manana, las-flores, que-es-esto), each its recorded one and the ones an act can show there (anyone's \"amor\" when touched, at any moment; the \"q\" of duda, encoge and turno at their steps; the frog's \"amor\"): wholly inside the view (0 px from its edge at the least), clear of the cards shown in the corners (0 px), on no face",
   "clear lawn (round 3): at every place where someone stands, at every column of their feet, at least 5 rows of lawn between their feet and the foot of what stands behind them; the least: behind the wall or the step 5 rows, d-la-bola right beats.0: the frog at 30,104; the fence or the gate 6 rows, hasta-manana right beats.5.after.0: luis at 165,116; the trunk 7 rows, d-la-bola right beats.20: the frog at 186,112",
   "ground: 109 distinct places where someone stands (and the frog), 1 where someone sits on the grass: on the lawn of the yard (x > CX, y > CY; abuela in the doorway), none behind the fence or inside the house, nothing of the house, the fence, the gate or the tree nearer than them inside their body",
   "flowerLeaves (round 6): at 189 distinct moments with flowers in the beds no leaf on anyone's face, nor on anyone standing in front of a bed; behind the leaves, as behind the flowers in the old picture: carmen at 200,168, carmen at 68,176, carmen at 186,170, carmen at 186,174, carmen at 198,166, abuelo at 52,174, luis at 172,176, carmen at 84,172, carmen at 37,178",
   "the frog at the gate (round 4): porton 126,86, 17.5 rows before the fence's line (the old picture 17, round 3 34.5), his middle at x 142 (the opening x 137 to 154); sale 130,68, 2.5 rows past it (the old 3; round 3 11.5 rows before it, on the lawn), on the path, his box x 138 to 154 between the posts (their pixels at x 135 and 156). On his way out (15 steps of 3 hops, in 3 open-gate states) no pixel of the leaf, the posts, the fence or the set nearer than him; at sale his bubbles inside the view, on no face (3 runs); nobody where he stands (42 moments at the gate, and his way out): the nearest anyone comes is 0.94 (hasta-manana alternate final.3: luis at 165,116, the frog at 126,86)",
   "standing over sitting: at 158 distinct moments no standing person's sprite covers more of a sitting person's face (the baby in mamá's arms, Luis on the grass) than the old picture did there",
   "pair vamos.si: the gate whole in the picture, 99% of its opening seen (open: the path through it)",
   "pair vamos.no: the gate whole in the picture, 100% of its opening seen (shut: the leaf in it)",
   "pairs (round 6): the single flower with its leaves whole in flor.si, aqui.si, aqui.no, alla.si, alla.no",
   "pairs, what differs (the same window both sides): nino: luis only in si, carmen only in no; nina: carmen only in si, mama only in no; juega: luis pose/lleva, bola; flor: flores, bola; sol: noche, luna, osc; aqui: flores; alla: flores; amigo: bola, the frog x/y/vis; ven: carmen pose/dir, ave, polvo, rizo, the frog x/dy/ojos/ojx/ojy; mira: luis x/pose/dir, ave, rizo, polvo, the frog x/dy/ojos/ojx/ojy; vamos: carmen x/y/pose/dir/sent/lleva, porton, polvo, lleva, the frog x/y/dy; hasta_manana: soly, sol, osc, porton, the frog x/y/s",
   "pairs: 25 review pictures (and the 27 level pictures, the same pictures): everyone, the frog, the ball and the sun or moon whole in their crop, on clear ground",
   "states: 15 baked states reached (crepusculo-open-shut, crepusculo-shut-shut, dia-open-shut, dia-shut-open, dia-shut-shut, noche-open-open, noche-open-shut, noche-shut-shut, ocaso-open-open, ocaso-open-shut, ocaso-shut-shut, tarde-open-shut, tarde-shut-shut, tarde2-open-shut, tarde2-shut-shut)"
  ]
 }
}
''',
  'camino': r'''{
 "scene": "camino",
 "made": "node docs/proyecto/pixel/camino-sheet-make.js, from camino-set.html (window.CAMINO_SET) and coqui/ref/escenas/camino/. Order 33a.",
 "S": 26,
 "origin": {
  "originX": 0,
  "originY": 4
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the park is built round the old picture: a place on its ground keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person's or an animal's place (x, y): the ground point under (x, y - 1), new (x, y) = old. So every ground position of camino.js (LUGAR, ranaEn, ninaEn, perroEn, enT, perroT, the acts' places), its stories and its pairs keeps its numbers, but for the few in moves and in remap (moved); the sheet names each one (spots, remap, code, moves) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog, an animal, a small tree's foot or a mark (the birds at ARBOL + NIDO, the cat in a tree, the lit rings, the shaking leaves, what is carried, the leash, the dust, the snail by the dog, the bush at perroT(.46) + (16, 5), the bubbles) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the stars of the happy endings (final12, final13, final14), the heart (heartAt), the birds flying up (W.vuelan)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were"
 },
 "layout": {
  "what": "a park on the world's axes, seen at the engine's 30 degrees (shadows to screen right): a path of trodden earth comes in from the picture's left edge along +x (down to the right) through the park's arch (two stone posts with caps, an iron arch over them), turns at the first mark and climbs along -y (up to the right) over seven flat stones, bends a little flatter and goes on past the big tree off the picture's right edge. Behind the path, at their old feet, the three small round trees; on its far side, in front of the middle one, the bench along the path, facing it; at its far end, on its far side, the big tree. The lawn is El frente's grass (the engine's GRASS ramp, calm, as El patio's); the horizon at row 100, El frente's far hills and day sky over it, its sun in the upper left of the sky, the old picture's three clouds in it (round 2)",
  "lines": {
   "path": "the path's middle line (world, PATH_PTS): from off the picture's left edge along +x through the arch to mark 0 (66, 182), then over marks 1 to 8 (up to the right, along -y to mark 4, a little flatter after) and on past the big tree off the picture's right edge; 0.6 either side of it (the frog's marks, ranaEn, on its far edge; Carmen's, ninaEn, on the lawn on our side; Canelo's, perroEn, on it)",
   "arch": "the arch over the path's first leg: its opening's middle on the ground at screen (37, 168), its posts at (27, 173) and (47, 162), 2.62 high, the iron arch 0.36 over them; its opening faces +x (into the park down to the right, out of it up to the left)",
   "bench": "the bench: its long side along y (parallel to the path's climb), facing the path (+x), on the path's far side in front of small tree 1, its middle on the ground at screen [91,133]"
  },
  "why": "the brief and page 11 decision 9: the set stands on the world's axes and is seen at the engine's angle; nothing is built square to the camera. The old path already climbed on a slant from the bottom left: its marks 0 to 4 lie on one -y line within 1 px, so the path runs along -y there; its first leg, through the arch, runs along +x, so that whoever leaves goes through the arch and on up the path off the picture's edge (sevan). The arch could not stand across the path's climb: the old picture's lower left holds Carmen, Luis, abuela, the frog and the dog at the end of story 14, and a post there would stand in front of one of them. The three small trees keep their old feet (the birds, the cat in them, Carmen's places by them are all relative to them): free-standing round trees, not a row (a row along -y through the middle one, trees=row in the set's address, puts the first tree's trunk behind the arch and the third's crown into the big tree's: see the report). Every place on the ground keeps its old screen point (rules.floor)",
  "moved": [
   "the big tree (round 2): built like the old one, at the picture's right: its foot 4 px right and 25 rows further back than the old (200, 128 to 204,103), its whole trunk inside the view, lawn between its foot and whoever stands before it (the frog with the basket, Canelo at the last marks, capped at x 188: moves); its broad crown runs off the picture's right and top edges (things.grande.hintBox for its hint frame)",
   "the bench: along y, facing the path; its box [77,117,28,23] (old [97, 126, 32, 18]); the cat on it and the bird on it follow it (remap, moves)",
   "the arch: over the path's first leg, its opening facing +x; its box [23,94,28,80] (old [22, 116, 36, 60]). The frog's place at the first tree (LUGAR.arbol0) moved left clear of its far post (moves)",
   "unchanged: the small trees' feet, the marks, every bird's place, the frog's other places, every person's and animal's place but the cat on the bench"
  ]
 },
 "behind": {
  "what": "nothing: the sun is baked into the set's sky (El frente's); the birds that fly up (W.vuelan) fly up from the crowns they sit on, in front of them and of the sky, as the old",
  "items": []
 },
 "setKey": {
  "params": {
   "gran": {
    "values": ["1", "0"],
    "fromW": "W.sinGran ? \"0\" : \"1\": the big tree (story 13, donde-esta-el-gato, is at the other end of the path: no big tree; the path, its stones and everything else are the same)"
   }
  },
  "key": "gran, e.g. \"1\"",
  "baked": [
   {
    "key": "1",
    "query": "?gran=1"
   },
   {
    "key": "0",
    "query": "?gran=0"
   }
  ],
  "bakedWhy": "order 06 found 9 states: the background (sinGran) and six keys of the sprite layer (arbusto: the bush, arrastra: the frog pulled off his feet, galleta: the biscuit, lit: the counted trees' rings, tumbo: the basket shaken, vuelan: the birds flown up). Only the big tree is the set's; the bush, the rings, the birds and the rest stay in the sprite layer, so these 2 baked states draw all 9 (and every review and level picture)"
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (camino.js:64): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "carmen": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (camino.js:64): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "abuela": {
   "sprite": true,
   "why": "a person (today's sprite, drawn 1:1). caja(id) (camino.js:64): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "ave00": {
   "sprite": true,
   "box": [53, 83, 15, 12],
   "why": "a bird in small tree 0, place 0 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave01": {
   "sprite": true,
   "box": [70, 78, 15, 12],
   "why": "a bird in small tree 0, place 1 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave02": {
   "sprite": true,
   "box": [62, 93, 15, 12],
   "why": "a bird in small tree 0, place 2 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave10": {
   "sprite": true,
   "box": [95, 79, 15, 12],
   "why": "a bird in small tree 1, place 0 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave11": {
   "sprite": true,
   "box": [112, 74, 15, 12],
   "why": "a bird in small tree 1, place 1 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave12": {
   "sprite": true,
   "box": [104, 89, 15, 12],
   "why": "a bird in small tree 1, place 2 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave20": {
   "sprite": true,
   "box": [137, 75, 15, 12],
   "why": "a bird in small tree 2, place 0 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave21": {
   "sprite": true,
   "box": [154, 70, 15, 12],
   "why": "a bird in small tree 2, place 1 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "ave22": {
   "sprite": true,
   "box": [146, 85, 15, 12],
   "why": "a bird in small tree 2, place 2 (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was"
  },
  "perro": {
   "sprite": true,
   "why": "Canelo (KIT.mkPerro): box [x - 14, y - 20, 28, 22] at W.perro, unchanged"
  },
  "gato": {
   "sprite": true,
   "hand": "x + 12, y - 10",
   "why": "the cat (mkGato): box [x - 12, y - 18, 24, 20] at W.gato (on the ground), unchanged; up a tree it is the tree's. Round 2: its hint hand at (x + 12, y - 10) (moves; the old: the box's middle): on the bench (106, 124) the hand from its middle reached Carmen's face (donde-esta-el-gato beats.10)"
  },
  "arbol0": {
   "set": true,
   "world": [-1.8902, 0.8567, 0, -0.8839, 1.863, 1.2657],
   "box": [51, 74, 37, 47],
   "screen": [51, 74, 88, 121],
   "what": "small tree 0: its trunk and crown (still: at its height the wind moves no leaf a pixel)",
   "old": {
    "box": [53, 74, 34, 48]
   },
   "hand": [70, 108],
   "handWhy": "the old hand point (the trunk, 12 rows over the foot). No point in the tree's box keeps the hand off every face at its asks and off the cat's tail, its face and the birds in the tree: the hand hangs 54 rows, and Luis waits under it (donde-esta-el-gato beats.32, 39, 70) as in the old picture (see checks: hand, as the old)"
  },
  "arbol1": {
   "set": true,
   "world": [-0.8839, -0.4759, 0, 0.068, 0.4759, 1.399],
   "box": [95, 68, 35, 49],
   "screen": [95, 68, 130, 117],
   "what": "small tree 1",
   "old": {
    "box": [95, 70, 34, 48]
   },
   "hand": [104, 104],
   "handWhy": "the trunk's left side, 12 rows over the foot (the old point 8 px right): there the hand is on no face at the tree's asks and off the cat's tail and face and the birds in the tree"
  },
  "arbol2": {
   "set": true,
   "world": [-0.0544, -1.9037, 0, 0.9791, -0.8703, 1.2435],
   "box": [135, 66, 38, 47],
   "screen": [135, 66, 173, 113],
   "what": "small tree 2",
   "old": {
    "box": [137, 66, 34, 48]
   },
   "hand": [146, 100],
   "handWhy": "as arbol1's: at the old point the hand lay on Luis's face by the big tree (h-camino beats.13), as in the old picture"
  },
  "banco": {
   "set": true,
   "world": [-0.0272, 1.5502, 0, 0.7343, 2.3117, 0.3997],
   "box": [77, 117, 28, 23],
   "screen": [77, 117, 105, 140],
   "what": "the bench: its seat, backrest and legs",
   "old": {
    "box": [97, 126, 32, 18]
   }
  },
  "grande": {
   "set": true,
   "world": [-0.2176, -4.569, 0, 1.9581, -2.3933, 3.02],
   "box": [160, 0, 80, 108],
   "screen": [160, 0, 240, 108],
   "what": "the big tree: its crown (every pixel its leaves take at any wind step) down to the foot of its trunk (gran 1). As the old, its box has no si: it stays when sinGran hides the tree (story 13 never names it)",
   "old": {
    "box": [160, 16, 58, 116]
   },
   "hintBox": [160, 12, 46, 96],
   "hintWhy": "hintBox: the part of the touch box the hint frame shows (the frame and the twinkle of a thing are drawn round hintBox where it has one; the touch box answers the touches): the crown runs off the picture's right and top edges, as the old one's did",
   "hand": [190, 51],
   "handWhy": "the hint hand's point (new: the old had none, so its box's middle): in its hint box, under the crown's left side, left of the trunk: the hand hangs from it right of Luis's face (he waits at 174, 138)"
  },
  "porton": {
   "set": true,
   "world": [0.3536, 4.8682, 0, 1.1151, 5.6297, 2.9312],
   "box": [23, 94, 28, 80],
   "screen": [23, 94, 51, 174],
   "what": "the arch: its two posts and the iron arch over them",
   "old": {
    "box": [22, 116, 36, 60]
   }
  },
  "camino": {
   "set": true,
   "ground": true,
   "what": "the path (the ground: trodden earth, the stones): the box round it on the picture, as the old one held its path",
   "screen": [0, 115, 240, 190],
   "world": [-2.2845, -2.2845, 0, 4.2426, 4.2426, -1.9985],
   "box": [0, 115, 240, 75],
   "old": {
    "box": [30, 128, 170, 76]
   }
  },
  "parque": {
   "set": true,
   "ground": true,
   "what": "the park: the lawn from the horizon (row 100) to the bottom, the whole width: last in the hit order",
   "old": {
    "box": [0, 100, 240, 116]
   },
   "box": [0, 100, 240, 116],
   "world": [-0.8703, -0.8703, 0, 5.6569, 5.6569, -0.1776]
  }
 },
 "spots": {
  "frog.inicio": {
   "world": [1.6862, 4.9497, 0],
   "new": [44, 148],
   "scale": 0.96,
   "old": [44, 148],
   "what": "LUGAR.inicio: the frog (ranaEn(0))"
  },
  "frog.centro": {
   "world": [4.7322, 4.9497, 0],
   "new": [100, 176],
   "scale": 1,
   "old": [100, 176],
   "what": "LUGAR.centro: the frog"
  },
  "frog.banco": {
   "world": [1.4142, 3.046, 0],
   "new": [74, 128],
   "scale": 0.86,
   "old": [74, 128],
   "what": "LUGAR.banco: the frog"
  },
  "frog.arbol0": {
   "world": [0.3536, 3.3452, 0],
   "new": [49, 121],
   "scale": 0.8,
   "old": [44, 122],
   "what": "LUGAR.arbol0: the frog at the first small tree (moved: see moves)"
  },
  "frog.arbol1": {
   "world": [2.5021, 1.3054, 0],
   "new": [126, 122],
   "scale": 0.8,
   "old": [126, 122],
   "what": "LUGAR.arbol1: the frog"
  },
  "frog.arbol2": {
   "world": [3.3724, 0, 0],
   "new": [166, 118],
   "scale": 0.8,
   "old": [166, 118],
   "what": "LUGAR.arbol2: the frog"
  },
  "frog.gran": {
   "world": [3.8075, 0.4351, 0],
   "new": [166, 126],
   "scale": 0.84,
   "old": [166, 126],
   "what": "LUGAR.gran: the frog"
  },
  "rana.0": {
   "world": [1.6862, 4.9497, 0],
   "new": [44, 148],
   "scale": 0.96,
   "old": [44, 148],
   "what": "ranaEn(0): the frog at mark 0, on the path's far edge"
  },
  "nina.0": {
   "world": [3.7531, 6.1464, 0],
   "new": [76, 204],
   "old": [76, 204],
   "what": "ninaEn(0): Carmen at mark 0, on the lawn on our side of the path"
  },
  "perro.0": {
   "world": [2.7196, 3.8075, 0],
   "new": [100, 173],
   "old": [100, 173],
   "what": "perroEn(0): Canelo a little ahead of the frog, on the path"
  },
  "rana.1": {
   "world": [1.659, 4.2154, 0],
   "new": [57, 141],
   "scale": 0.95,
   "old": [57, 141],
   "what": "ranaEn(1): the frog at mark 1, on the path's far edge"
  },
  "nina.1": {
   "world": [3.7259, 5.4121, 0],
   "new": [89, 197],
   "old": [89, 197],
   "what": "ninaEn(1): Carmen at mark 1, on the lawn on our side of the path"
  },
  "perro.1": {
   "world": [2.6924, 3.0732, 0],
   "new": [113, 166],
   "old": [113, 166],
   "what": "perroEn(1): Canelo a little ahead of the frog, on the path"
  },
  "rana.2": {
   "world": [1.6318, 3.4811, 0],
   "new": [70, 134],
   "scale": 0.93,
   "old": [70, 134],
   "what": "ranaEn(2): the frog at mark 2, on the path's far edge"
  },
  "nina.2": {
   "world": [3.6987, 4.6778, 0],
   "new": [102, 190],
   "old": [102, 190],
   "what": "ninaEn(2): Carmen at mark 2, on the lawn on our side of the path"
  },
  "perro.2": {
   "world": [2.6652, 2.3389, 0],
   "new": [126, 159],
   "old": [126, 159],
   "what": "perroEn(2): Canelo a little ahead of the frog, on the path"
  },
  "rana.3": {
   "world": [1.659, 2.8012, 0],
   "new": [83, 128],
   "scale": 0.91,
   "old": [83, 128],
   "what": "ranaEn(3): the frog at mark 3, on the path's far edge"
  },
  "nina.3": {
   "world": [3.7259, 3.9979, 0],
   "new": [115, 184],
   "old": [115, 184],
   "what": "ninaEn(3): Carmen at mark 3, on the lawn on our side of the path"
  },
  "perro.3": {
   "world": [2.6924, 1.659, 0],
   "new": [139, 153],
   "old": [139, 153],
   "what": "perroEn(3): Canelo a little ahead of the frog, on the path"
  },
  "rana.4": {
   "world": [1.6862, 2.1213, 0],
   "new": [96, 122],
   "scale": 0.9,
   "old": [96, 122],
   "what": "ranaEn(4): the frog at mark 4, on the path's far edge"
  },
  "nina.4": {
   "world": [3.7531, 3.318, 0],
   "new": [128, 178],
   "old": [128, 178],
   "what": "ninaEn(4): Carmen at mark 4, on the lawn on our side of the path"
  },
  "perro.4": {
   "world": [2.7196, 0.9791, 0],
   "new": [152, 147],
   "old": [152, 147],
   "what": "perroEn(4): Canelo a little ahead of the frog, on the path"
  },
  "rana.5": {
   "world": [1.7678, 1.4958, 0],
   "new": [109, 117],
   "scale": 0.89,
   "old": [109, 117],
   "what": "ranaEn(5): the frog at mark 5, on the path's far edge"
  },
  "nina.5": {
   "world": [3.8347, 2.6924, 0],
   "new": [141, 173],
   "old": [141, 173],
   "what": "ninaEn(5): Carmen at mark 5, on the lawn on our side of the path"
  },
  "perro.5": {
   "world": [2.8012, 0.3536, 0],
   "new": [165, 142],
   "old": [165, 142],
   "what": "perroEn(5): Canelo a little ahead of the frog, on the path"
  },
  "rana.6": {
   "world": [1.8494, 0.8703, 0],
   "new": [122, 112],
   "scale": 0.87,
   "old": [122, 112],
   "what": "ranaEn(6): the frog at mark 6, on the path's far edge"
  },
  "nina.6": {
   "world": [3.9163, 2.0669, 0],
   "new": [154, 168],
   "old": [154, 168],
   "what": "ninaEn(6): Carmen at mark 6, on the lawn on our side of the path"
  },
  "perro.6": {
   "world": [2.8828, -0.272, 0],
   "new": [178, 137],
   "old": [178, 137],
   "what": "perroEn(6): Canelo a little ahead of the frog, on the path"
  },
  "rana.7": {
   "world": [1.9853, 0.2992, 0],
   "new": [135, 108],
   "scale": 0.86,
   "old": [135, 108],
   "what": "ranaEn(7): the frog at mark 7, on the path's far edge"
  },
  "nina.7": {
   "world": [4.0523, 1.4958, 0],
   "new": [167, 164],
   "old": [167, 164],
   "what": "ninaEn(7): Carmen at mark 7, on the lawn on our side of the path"
  },
  "perro.7": {
   "world": [2.9372, -0.7615, 0],
   "new": [188, 133],
   "old": [191, 133],
   "what": "perroEn(7): Canelo a little ahead of the frog, on the path (moved: x at most 188, see moves)"
  },
  "rana.8": {
   "world": [2.1757, -0.2176, 0],
   "new": [148, 105],
   "scale": 0.84,
   "old": [148, 105],
   "what": "ranaEn(8): the frog at mark 8, on the path's far edge"
  },
  "nina.8": {
   "world": [4.2426, 0.9791, 0],
   "new": [180, 161],
   "old": [180, 161],
   "what": "ninaEn(8): Carmen at mark 8, on the lawn on our side of the path"
  },
  "perro.8": {
   "world": [2.774, -0.9247, 0],
   "new": [188, 130],
   "old": [204, 130],
   "what": "perroEn(8): Canelo a little ahead of the frog, on the path (moved: x at most 188, see moves)"
  },
  "inicio12.luis": {
   "world": [2.8284, -0.1088, 0],
   "new": [174, 138],
   "old": [174, 138],
   "what": "inicio12: Luis, by the big tree"
  },
  "final12.carmen": {
   "world": [2.8828, 0.7071, 0],
   "new": [160, 146],
   "old": [160, 146],
   "what": "final12: Carmen sits down by the big tree"
  },
  "inicio13.luis": {
   "world": [2.5021, 5.6569, 0],
   "new": [62, 188],
   "old": [62, 188],
   "what": "inicio13: Luis with the leash"
  },
  "inicio13.carmen": {
   "world": [3.8619, 5.3849, 0],
   "new": [92, 198],
   "old": [92, 198],
   "what": "inicio13, carmenvuelve: Carmen with the basket"
  },
  "inicio13.perro": {
   "world": [3.2636, 6.8535, 0],
   "new": [54, 206],
   "old": [54, 206],
   "what": "inicio13, perrocome, agarra, perrocome2: Canelo on the leash, by Luis"
  },
  "escapa.perro": {
   "world": [2.8284, 1.1966, 0],
   "new": [150, 150],
   "old": [150, 150],
   "what": "escapa: Canelo runs loose to here"
  },
  "final13.carmen": {
   "world": [5.4937, 3.5355, 0],
   "new": [156, 196],
   "old": [156, 196],
   "what": "final13: Carmen"
  },
  "inicio14.abuela": {
   "world": [2.2845, 5.2217, 0],
   "new": [66, 182],
   "old": [66, 182],
   "what": "inicio14: abuela waits at the path's turn, inside the arch (mark 0)"
  },
  "inicio14.luis": {
   "world": [3.8619, 5.6025, 0],
   "new": [88, 200],
   "old": [88, 200],
   "what": "inicio14: Luis"
  },
  "inicio14.carmen": {
   "world": [2.8284, 6.8535, 0],
   "new": [46, 202],
   "old": [46, 202],
   "what": "inicio14: Carmen"
  },
  "carmenva.0": {
   "world": [0.1632, 1.9037, 0],
   "new": [88, 132],
   "old": [88, 132],
   "what": "carmenva: Carmen at tree 0 (ARBOL[0] + 18, 12)"
  },
  "carmenva.1": {
   "world": [1.0879, 0.5439, 0],
   "new": [130, 128],
   "old": [130, 128],
   "what": "carmenva: Carmen at tree 1 (ARBOL[1] + 18, 12)"
  },
  "carmenva.2": {
   "world": [2.0125, -0.8159, 0],
   "new": [172, 124],
   "old": [172, 124],
   "what": "carmenva: Carmen at tree 2 (ARBOL[2] + 18, 12)"
  }
 },
 "lugar": {
  "inicio": {
   "spot": "frog.inicio",
   "q": [44, 148],
   "scale": 0.96,
   "old": [44, 148]
  },
  "centro": {
   "spot": "frog.centro",
   "q": [100, 176],
   "scale": 1,
   "old": [100, 176]
  },
  "banco": {
   "spot": "frog.banco",
   "q": [74, 128],
   "scale": 0.86,
   "old": [74, 128]
  },
  "arbol0": {
   "spot": "frog.arbol0",
   "q": [49, 121],
   "scale": 0.8,
   "old": [44, 122]
  },
  "arbol1": {
   "spot": "frog.arbol1",
   "q": [126, 122],
   "scale": 0.8,
   "old": [126, 122]
  },
  "arbol2": {
   "spot": "frog.arbol2",
   "q": [166, 118],
   "scale": 0.8,
   "old": [166, 118]
  },
  "gran": {
   "spot": "frog.gran",
   "q": [166, 126],
   "scale": 0.84,
   "old": [166, 126]
  }
 },
 "hops": [],
 "hopsWhat": "each pair of LUGAR places whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all 21 pairs). ranaEn's marks are walked with the hop counts the acts give (ranaa, va), whatever the distance",
 "hopsAll": [
  {
   "a": "inicio",
   "b": "centro",
   "old": 2,
   "new": 2,
   "dOld": 62.61,
   "dNew": 62.61
  },
  {
   "a": "inicio",
   "b": "banco",
   "old": 1,
   "new": 1,
   "dOld": 36.06,
   "dNew": 36.06
  },
  {
   "a": "inicio",
   "b": "arbol0",
   "old": 1,
   "new": 1,
   "dOld": 26,
   "dNew": 27.46
  },
  {
   "a": "inicio",
   "b": "arbol1",
   "old": 3,
   "new": 3,
   "dOld": 86.02,
   "dNew": 86.02
  },
  {
   "a": "inicio",
   "b": "arbol2",
   "old": 4,
   "new": 4,
   "dOld": 125.63,
   "dNew": 125.63
  },
  {
   "a": "inicio",
   "b": "gran",
   "old": 4,
   "new": 4,
   "dOld": 123.97,
   "dNew": 123.97
  },
  {
   "a": "centro",
   "b": "banco",
   "old": 2,
   "new": 2,
   "dOld": 54.59,
   "dNew": 54.59
  },
  {
   "a": "centro",
   "b": "arbol0",
   "old": 3,
   "new": 3,
   "dOld": 77.79,
   "dNew": 75.01
  },
  {
   "a": "centro",
   "b": "arbol1",
   "old": 2,
   "new": 2,
   "dOld": 59.93,
   "dNew": 59.93
  },
  {
   "a": "centro",
   "b": "arbol2",
   "old": 3,
   "new": 3,
   "dOld": 87.86,
   "dNew": 87.86
  },
  {
   "a": "centro",
   "b": "gran",
   "old": 3,
   "new": 3,
   "dOld": 82.8,
   "dNew": 82.8
  },
  {
   "a": "banco",
   "b": "arbol0",
   "old": 1,
   "new": 1,
   "dOld": 30.59,
   "dNew": 25.96
  },
  {
   "a": "banco",
   "b": "arbol1",
   "old": 2,
   "new": 2,
   "dOld": 52.35,
   "dNew": 52.35
  },
  {
   "a": "banco",
   "b": "arbol2",
   "old": 3,
   "new": 3,
   "dOld": 92.54,
   "dNew": 92.54
  },
  {
   "a": "banco",
   "b": "gran",
   "old": 3,
   "new": 3,
   "dOld": 92.02,
   "dNew": 92.02
  },
  {
   "a": "arbol0",
   "b": "arbol1",
   "old": 3,
   "new": 3,
   "dOld": 82,
   "dNew": 77.01
  },
  {
   "a": "arbol0",
   "b": "arbol2",
   "old": 4,
   "new": 4,
   "dOld": 122.07,
   "dNew": 117.04
  },
  {
   "a": "arbol0",
   "b": "gran",
   "old": 4,
   "new": 4,
   "dOld": 122.07,
   "dNew": 117.11
  },
  {
   "a": "arbol1",
   "b": "arbol2",
   "old": 1,
   "new": 1,
   "dOld": 40.2,
   "dNew": 40.2
  },
  {
   "a": "arbol1",
   "b": "gran",
   "old": 1,
   "new": 1,
   "dOld": 40.2,
   "dNew": 40.2
  },
  {
   "a": "arbol2",
   "b": "gran",
   "old": 1,
   "new": 1,
   "dOld": 8,
   "dNew": 8
  }
 ],
 "points": {
  "arbol.0": {
   "screen": [70, 120],
   "old": [70, 120],
   "world": [-0.9247, 1.795, 0],
   "what": "ARBOL[0]: the foot of small tree 0 (unchanged): the birds (NIDO), the cat in it (cara, cola), the lit ring, the shaking leaves and Carmen's place at it (carmenva) are all relative to it"
  },
  "arbol.1": {
   "screen": [112, 116],
   "old": [112, 116],
   "world": [0, 0.4351, 0],
   "what": "ARBOL[1]: the foot of small tree 1 (unchanged): the birds (NIDO), the cat in it (cara, cola), the lit ring, the shaking leaves and Carmen's place at it (carmenva) are all relative to it"
  },
  "arbol.2": {
   "screen": [154, 112],
   "old": [154, 112],
   "world": [0.9247, -0.9247, 0],
   "what": "ARBOL[2]: the foot of small tree 2 (unchanged): the birds (NIDO), the cat in it (cara, cola), the lit ring, the shaking leaves and Carmen's place at it (carmenva) are all relative to it"
  },
  "nido": {
   "screen": [
    [-9, -31],
    [8, -36],
    [0, -21]
   ],
   "old": [
    [-9, -31],
    [8, -36],
    [0, -21]
   ],
   "what": "NIDO: where up to three birds sit in a small tree, from its foot (unchanged): each bird on the crown's leaves"
  },
  "marca.0": {
   "screen": [66, 182],
   "old": [66, 182],
   "world": [2.3389, 5.2761, 0],
   "what": "MARCA[0]: the path's turn inside the arch"
  },
  "marca.1": {
   "screen": [79, 175],
   "old": [79, 175],
   "world": [2.3117, 4.5418, 0],
   "what": "MARCA[1]: a stone in the path"
  },
  "marca.2": {
   "screen": [92, 168],
   "old": [92, 168],
   "world": [2.2845, 3.8075, 0],
   "what": "MARCA[2]: a stone in the path"
  },
  "marca.3": {
   "screen": [105, 162],
   "old": [105, 162],
   "world": [2.3117, 3.1276, 0],
   "what": "MARCA[3]: a stone in the path"
  },
  "marca.4": {
   "screen": [118, 156],
   "old": [118, 156],
   "world": [2.3389, 2.4477, 0],
   "what": "MARCA[4]: a stone in the path"
  },
  "marca.5": {
   "screen": [131, 151],
   "old": [131, 151],
   "world": [2.4205, 1.8222, 0],
   "what": "MARCA[5]: a stone in the path"
  },
  "marca.6": {
   "screen": [144, 146],
   "old": [144, 146],
   "world": [2.5021, 1.1966, 0],
   "what": "MARCA[6]: a stone in the path"
  },
  "marca.7": {
   "screen": [157, 142],
   "old": [157, 142],
   "world": [2.6381, 0.6255, 0],
   "what": "MARCA[7]: a stone in the path"
  },
  "marca.8": {
   "screen": [170, 139],
   "old": [170, 139],
   "world": [2.8284, 0.1088, 0],
   "what": "MARCA[8]: before the big tree"
  },
  "gran": {
   "screen": [204, 103],
   "old": [200, 128],
   "world": [1.795, -2.774, 0],
   "what": "the big tree's foot (GRAN, used only by the old background and its box): 4 px, -25 rows from the old"
  },
  "arco": {
   "screen": [37, 167.5],
   "world": [0.7615, 5.2761, 0],
   "posts": [
    [26.89, 172.56],
    [47.11, 162.44]
   ],
   "what": "the arch: the middle of its opening on the ground (the cat sits there in d-corre, 46, 172), its two posts' feet (A, down to the left; B, up to the right)"
  },
  "gato_banco": {
   "screen": [92, 123],
   "old": [113, 134],
   "v": 2.1538,
   "what": "the cat on the bench (story files d-corre, h-camino beats.1, cual-camino gato.si: x 113, y 134 -> remap): its lowest pixels on the seat's top; drawn after the bench's entry in the sorted list (front.banco), so no shadow on the lawn (shadows.gato)"
  },
  "ave_banco": {
   "screen": [81, 112],
   "old": [106, 117],
   "what": "the bird on the bench (W.avebanco): drawn at (x, y) 15 x 12, its feet on the seat's back plank (moves)"
  },
  "corazon": {
   "screen": [110, 30],
   "old": [110, 30],
   "what": "heartAt: the heart of a happy ending, in the sky (unchanged)"
  },
  "sol": {
   "screen": [38, 47],
   "radius": 9,
   "what": "the sun: baked into the set's sky (El frente's colours), left of the middle (every shadow falls to the right), round 3 under the corner boards' place and left of every answer card's frame, whole inside the wide view; no story touches it or names its place"
  },
  "nubes": {
   "screen": [
    [128, 6, 0.7],
    [140, 24, 0.8],
    [120, 44, 0.8]
   ],
   "old": [
    [36, 16, 1],
    [112, 9, 0.7],
    [168, 26, 0.8]
   ],
   "what": "the old picture's three clouds (x, y, size: engine.js sky()), baked into the set's sky as El patio's, each moved clear of the sun and of the crowns; no story names them"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [2.0669, 2.0669, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the park: the arch, the path with its stones, the three small trees, the bench, the big tree, the sky"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [22, 30, 196, 104],
   "uses": ["cual-camino.json parque.no.cam"],
   "to": {
    "pictures": ["parque.no"]
   },
   "crops": {
    "parque.no": {
     "scene": "patio",
     "what": "drawn by El patio (its sheet's picture parque.no): listed here because the pair's other side is this scene's"
    }
   }
  },
  {
   "kind": "cam",
   "old": [22, 84, 196, 104],
   "uses": ["cual-camino.json parque.si.cam"],
   "to": {
    "pictures": ["parque.si"]
   },
   "crops": {
    "parque.si": {
     "crop": [22, 84, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [40, 120, 150, 79.6],
   "uses": ["cual-camino.json camina.si.cam", "cual-camino.json camina.no.cam", "cual-camino.json espera.si.cam", "cual-camino.json espera.no.cam"],
   "to": {
    "pictures": ["camina.si", "camina.no", "espera.si", "espera.no"]
   },
   "crops": {
    "camina.si": {
     "crop": [17, 108, 196, 104],
     "zoom": 1
    },
    "camina.no": {
     "crop": [17, 108, 196, 104],
     "zoom": 1
    },
    "espera.si": {
     "crop": [17, 108, 196, 104],
     "zoom": 1
    },
    "espera.no": {
     "crop": [17, 108, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [58, 58, 113, 60],
   "uses": ["cual-camino.json hay.si.cam", "cual-camino.json hay.no.cam"],
   "to": {
    "pictures": ["hay.si", "hay.no"]
   },
   "crops": {
    "hay.si": {
     "crop": [64, 62, 98, 52],
     "zoom": 2
    },
    "hay.no": {
     "crop": [64, 62, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [62, 60, 100, 53.1],
   "uses": ["cual-camino.json uno.si.cam", "cual-camino.json uno.no.cam", "cual-camino.json dos.si.cam", "cual-camino.json dos.no.cam", "cual-camino.json tres.si.cam", "cual-camino.json tres.no.cam"],
   "to": {
    "pictures": ["uno.si", "uno.no", "dos.si", "dos.no", "tres.si", "tres.no"]
   },
   "crops": {
    "uno.si": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    },
    "uno.no": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    },
    "dos.si": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    },
    "dos.no": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    },
    "tres.si": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    },
    "tres.no": {
     "crop": [63, 61, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [62, 96, 100, 53.1],
   "uses": ["cual-camino.json gato.si.cam", "cual-camino.json gato.no.cam"],
   "to": {
    "pictures": ["gato.si", "gato.no"]
   },
   "crops": {
    "gato.si": {
     "crop": [64, 98, 98, 52],
     "zoom": 2
    },
    "gato.no": {
     "crop": [64, 98, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [70, 128, 113, 60],
   "uses": [
    "cual-camino.json perro.si.cam",
    "cual-camino.json perro.no.cam",
    "cual-camino.json corre.si.cam",
    "cual-camino.json corre.no.cam",
    "cual-camino.json rápido.si.cam",
    "cual-camino.json rápido.no.cam",
    "cual-camino.json despacio.si.cam",
    "cual-camino.json despacio.no.cam"
   ],
   "to": {
    "pictures": ["perro.si", "perro.no", "corre.si", "corre.no", "rapido.si", "rapido.no", "despacio.si", "despacio.no"]
   },
   "crops": {
    "perro.si": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "perro.no": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "corre.si": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "corre.no": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "rapido.si": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "rapido.no": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "despacio.si": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    },
    "despacio.no": {
     "crop": [75, 135, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [78, 118, 75, 39.8],
   "uses": [
    "cual-camino.json árbol.no.cam"
   ],
   "to": {
    "pictures": ["arbol.no"]
   },
   "crops": {
    "arbol.no": {
     "crop": [64, 117, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [112, 62, 100, 53.1],
   "uses": [
    "cual-camino.json árbol.si.cam"
   ],
   "to": {
    "pictures": ["arbol.si"]
   },
   "crops": {
    "arbol.si": {
     "crop": [108, 62, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [79.95, 120, 72.09, 79.6],
   "uses": [
    "nivel.js NV corre.p2"
   ],
   "to": {
    "pictures": ["camina.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [87.33, 58, 54.34, 60],
   "uses": [
    "nivel.js NV dos.p3"
   ],
   "to": {
    "pictures": ["hay.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [87.95, 60, 48.09, 53.1],
   "uses": [
    "nivel.js NV dos.p0",
    "nivel.js NV dos.p1",
    "nivel.js NV dos.p2"
   ],
   "to": {
    "pictures": ["dos.si", "uno.si", "tres.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [87.95, 96, 48.09, 53.1],
   "uses": [
    "nivel.js NV perro.p2"
   ],
   "to": {
    "pictures": ["gato.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [99.33, 128, 54.34, 60],
   "uses": [
    "nivel.js NV perro.p0",
    "nivel.js NV perro.p1",
    "nivel.js NV corre.p0",
    "nivel.js NV corre.p1",
    "nivel.js NV corre.p3",
    "nivel.js NV rápido.p0",
    "nivel.js NV rápido.p1",
    "nivel.js NV rápido.p2",
    "nivel.js NV rápido.p3"
   ],
   "to": {
    "pictures": ["perro.si", "perro.no", "corre.si", "corre.no", "despacio.si", "rapido.si", "rapido.no", "despacio.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [137.95, 62, 48.09, 53.1],
   "uses": [
    "nivel.js NV perro.p3"
   ],
   "to": {
    "pictures": ["arbol.si"],
    "level": true
   }
  },
  {
   "kind": "numbers",
   "old": [0, 0, 0],
   "uses": ["cual-camino.json gato.no.set.pajaros"],
   "to": {
    "none": true
   },
   "what": "W.pajaros: how many birds sit in each small tree (counts, not a place)"
  },
  {
   "kind": "numbers",
   "old": [0, 1, 0],
   "uses": ["cual-camino.json uno.si.set.pajaros", "cual-camino.json dos.no.set.pajaros"],
   "to": {
    "none": true
   },
   "what": "W.pajaros: how many birds sit in each small tree (counts, not a place)"
  },
  {
   "kind": "numbers",
   "old": [0, 2, 0],
   "uses": ["cual-camino.json dos.si.set.pajaros", "cual-camino.json tres.no.set.pajaros"],
   "to": {
    "none": true
   },
   "what": "W.pajaros: how many birds sit in each small tree (counts, not a place)"
  },
  {
   "kind": "numbers",
   "old": [0, 3, 0],
   "uses": ["cual-camino.json uno.no.set.pajaros", "cual-camino.json tres.si.set.pajaros"],
   "to": {
    "none": true
   },
   "what": "W.pajaros: how many birds sit in each small tree (counts, not a place)"
  },
  {
   "kind": "point",
   "old": [-16, -27],
   "uses": [
    "cual-camino.json perro.si.set.cq",
    "cual-camino.json perro.no.set.cq",
    "cual-camino.json gato.si.set.cq",
    "cual-camino.json gato.no.set.cq",
    "cual-camino.json árbol.si.set.cq",
    "cual-camino.json árbol.no.set.cq",
    "cual-camino.json parque.si.set.cq",
    "cual-camino.json camina.si.set.cq",
    "cual-camino.json camina.no.set.cq",
    "cual-camino.json corre.si.set.cq",
    "cual-camino.json corre.no.set.cq",
    "cual-camino.json espera.si.set.cq",
    "cual-camino.json espera.no.set.cq",
    "cual-camino.json rápido.si.set.cq",
    "cual-camino.json rápido.no.set.cq",
    "cual-camino.json despacio.si.set.cq",
    "cual-camino.json despacio.no.set.cq",
    "cual-camino.json hay.si.set.cq",
    "cual-camino.json hay.no.set.cq",
    "cual-camino.json uno.si.set.cq",
    "cual-camino.json uno.no.set.cq",
    "cual-camino.json dos.si.set.cq",
    "cual-camino.json dos.no.set.cq",
    "cual-camino.json tres.si.set.cq",
    "cual-camino.json tres.no.set.cq"
   ],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0): not a place"
  },
  {
   "kind": "point",
   "old": [0, 0],
   "uses": ["cual-camino.json hay.si.set.gato"],
   "to": {
    "none": true
   },
   "what": "the cat up small tree 1 (en 1): its x, y are not used (the tree's place is ARBOL[1])"
  },
  {
   "kind": "point",
   "old": [46, 172],
   "uses": ["d-corre.json beats.26"],
   "to": {
    "floor": [1.1966, 5.2217, 0]
   },
   "new": [46, 172],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [70, 186],
   "uses": ["d-corre.json beats.27"],
   "to": {
    "floor": [2.6109, 5.3305, 0]
   },
   "new": [70, 186],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [88, 134],
   "uses": ["d-corre.json beats.49"],
   "to": {
    "floor": [0.8703, 3.046, 0]
   },
   "new": [80, 149],
   "moved": true,
   "why": "round 4: Canelo barking at the cat in the first tree (d-corre beats.49): 8 px left and 15 rows down, before the bench's left end with lawn between (the bench moved along the path and up: at the old point he stood in its foot)",
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [96, 30],
   "uses": [
    "h-camino.json beats.5.set.respEn"
   ],
   "to": {
    "screen": [134, 14]
   },
   "new": [134, 14],
   "moved": true,
   "why": "round 2: the answer cards where acts.inicio12 puts them (moves), their frames inside the view with 2 px to spare",
   "what": "W.respEn: the answer cards in the sky (juego.js respBox: centred at x, their top at y): screen, moved"
  },
  {
   "kind": "point",
   "old": [98, 170],
   "uses": ["cual-camino.json camina.no.set.polvo"],
   "to": {
    "floor": [2.5021, 3.6987, 0]
   },
   "new": [98, 170],
   "what": "on the ground (the dust of a run, the snail): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [100, 174],
   "uses": ["cual-camino.json espera.no.set.polvo"],
   "to": {
    "floor": [2.774, 3.8619, 0]
   },
   "new": [100, 174],
   "what": "on the ground (the dust of a run, the snail): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [102, 185],
   "uses": [
    "cual-camino.json rápido.no.set.caracol",
    "cual-camino.json despacio.si.set.caracol"
   ],
   "to": {
    "floor": [3.4267, 4.4058, 0]
   },
   "new": [102, 185],
   "what": "on the ground (the dust of a run, the snail): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [106, 180],
   "uses": [
    "cual-camino.json rápido.si.set.polvo",
    "cual-camino.json despacio.no.set.polvo"
   ],
   "to": {
    "floor": [3.2636, 4.0251, 0]
   },
   "new": [106, 180],
   "what": "on the ground (the dust of a run, the snail): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [108, 180],
   "uses": ["cual-camino.json corre.si.set.polvo"],
   "to": {
    "floor": [3.318, 3.9707, 0]
   },
   "new": [108, 180],
   "what": "on the ground (the dust of a run, the snail): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [113, 134],
   "uses": ["d-corre.json beats.1.set.gato", "h-camino.json beats.1.set.gato", "cual-camino.json gato.si.set.gato"],
   "to": {
    "floor": [-0.2176, 1.3054, 0]
   },
   "new": [92, 123],
   "moved": true,
   "why": "the cat on the bench (d-corre and h-camino beats.1, cual-camino gato.si): on the new bench's seat, its lowest pixels on the seat's top (points.gato_banco), and drawn after the bench's entry in the sorted list (front.banco: sortY 134.5)",
   "what": "an animal's place (x, y): the ground under it"
  },
  {
   "kind": "point",
   "old": [116, 172],
   "uses": ["cual-camino.json camina.si.set.gente.luis", "cual-camino.json camina.no.set.gente.luis"],
   "to": {
    "floor": [3.1004, 3.318, 0]
   },
   "new": [116, 172],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [118, 176],
   "uses": ["cual-camino.json espera.si.set.gente.carmen", "cual-camino.json espera.no.set.gente.carmen"],
   "to": {
    "floor": [3.3724, 3.4811, 0]
   },
   "new": [118, 176],
   "what": "a person's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [126, 180],
   "uses": [
    "cual-camino.json perro.si.set.perro",
    "cual-camino.json perro.no.set.gato",
    "cual-camino.json corre.si.set.perro",
    "cual-camino.json corre.no.set.perro",
    "cual-camino.json rápido.si.set.perro",
    "cual-camino.json rápido.no.set.perro",
    "cual-camino.json despacio.si.set.gato",
    "cual-camino.json despacio.no.set.gato"
   ],
   "to": {
    "floor": [3.8075, 3.4811, 0]
   },
   "new": [126, 180],
   "what": "an animal's place (x, y): the ground under it; the same screen place"
  },
  {
   "kind": "x",
   "old": [116],
   "uses": [
    "nivel.js NV corre.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "perro.si": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "Canelo sits on the path, close"
  },
  "perro.no": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "the cat sits there, close"
  },
  "corre.si": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "Canelo runs, dust behind him"
  },
  "corre.no": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "Canelo lies down"
  },
  "rapido.si": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "Canelo walks fast, dust behind him"
  },
  "rapido.no": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "Canelo sniffs along, a snail beside him"
  },
  "despacio.si": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "the cat walks, a snail beside it"
  },
  "despacio.no": {
   "world": [2.774, 2.5565, 0],
   "screen": [124, 161],
   "zoom": 2,
   "crop": [75, 135, 98, 52],
   "what": "the cat runs, dust behind it"
  },
  "gato.si": {
   "world": [0.4623, 0.8431, 0],
   "screen": [113, 124],
   "zoom": 2,
   "crop": [64, 98, 98, 52],
   "what": "the cat on the bench, close"
  },
  "gato.no": {
   "world": [0.4623, 0.8431, 0],
   "screen": [113, 124],
   "zoom": 2,
   "crop": [64, 98, 98, 52],
   "what": "a bird on the bench's back, close"
  },
  "arbol.si": {
   "world": [-0.2992, -2.3117, 0],
   "screen": [157, 88],
   "zoom": 2,
   "crop": [108, 62, 98, 52],
   "what": "small tree 2, close"
  },
  "arbol.no": {
   "world": [1.4958, 1.8766, 0],
   "screen": [113, 143],
   "zoom": 2,
   "crop": [64, 117, 98, 52],
   "what": "the bench, no tree, close"
  },
  "parque.si": {
   "world": [1.3054, 1.3054, 0],
   "screen": [120, 136],
   "zoom": 1,
   "crop": [22, 84, 196, 104],
   "what": "the park: the arch, the path, the trees, the bench (the old window [22, 84, 196, 104])"
  },
  "camina.si": {
   "world": [2.4749, 2.7468, 0],
   "screen": [115, 160],
   "zoom": 1,
   "crop": [17, 108, 196, 104],
   "what": "Luis walks on the path"
  },
  "camina.no": {
   "world": [2.4749, 2.7468, 0],
   "screen": [115, 160],
   "zoom": 1,
   "crop": [17, 108, 196, 104],
   "what": "Luis runs, dust behind him"
  },
  "espera.si": {
   "world": [2.4749, 2.7468, 0],
   "screen": [115, 160],
   "zoom": 1,
   "crop": [17, 108, 196, 104],
   "what": "Carmen stands still"
  },
  "espera.no": {
   "world": [2.4749, 2.7468, 0],
   "screen": [115, 160],
   "zoom": 1,
   "crop": [17, 108, 196, 104],
   "what": "Carmen runs, dust behind her"
  },
  "hay.si": {
   "world": [-1.4958, -1.1151, 0],
   "screen": [113, 88],
   "zoom": 2,
   "crop": [64, 62, 98, 52],
   "what": "the cat's face in small tree 1"
  },
  "hay.no": {
   "world": [-1.4958, -1.1151, 0],
   "screen": [113, 88],
   "zoom": 2,
   "crop": [64, 62, 98, 52],
   "what": "small tree 1, nothing in it"
  },
  "uno.si": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "one bird in small tree 1"
  },
  "uno.no": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "three birds there"
  },
  "dos.si": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "two birds in small tree 1"
  },
  "dos.no": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "one bird there"
  },
  "tres.si": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "three birds in small tree 1"
  },
  "tres.no": {
   "world": [-1.5774, -1.1422, 0],
   "screen": [112, 87],
   "zoom": 2,
   "crop": [63, 61, 98, 52],
   "what": "two birds there"
  }
 },
 "level": [
  {
   "w": "perro",
   "index": 0,
   "picture": "perro.si",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "perro",
   "index": 1,
   "picture": "perro.no",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "perro",
   "index": 2,
   "picture": "gato.no",
   "old": [87.95, 96, 48.09, 53.1],
   "crop": [64, 98, 98, 52],
   "zoom": 2
  },
  {
   "w": "perro",
   "index": 3,
   "picture": "arbol.si",
   "old": [137.95, 62, 48.09, 53.1],
   "crop": [108, 62, 98, 52],
   "zoom": 2
  },
  {
   "w": "corre",
   "index": 0,
   "picture": "corre.si",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "corre",
   "index": 1,
   "picture": "corre.no",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "corre",
   "index": 2,
   "picture": "camina.si",
   "old": [79.95, 120, 72.09, 79.6],
   "crop": [17, 108, 196, 104],
   "zoom": 1
  },
  {
   "w": "corre",
   "index": 3,
   "picture": "despacio.si",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "dos",
   "index": 0,
   "picture": "dos.si",
   "old": [87.95, 60, 48.09, 53.1],
   "crop": [63, 61, 98, 52],
   "zoom": 2
  },
  {
   "w": "dos",
   "index": 1,
   "picture": "uno.si",
   "old": [87.95, 60, 48.09, 53.1],
   "crop": [63, 61, 98, 52],
   "zoom": 2
  },
  {
   "w": "dos",
   "index": 2,
   "picture": "tres.si",
   "old": [87.95, 60, 48.09, 53.1],
   "crop": [63, 61, 98, 52],
   "zoom": 2
  },
  {
   "w": "dos",
   "index": 3,
   "picture": "hay.no",
   "old": [87.33, 58, 54.34, 60],
   "crop": [64, 62, 98, 52],
   "zoom": 2
  },
  {
   "w": "rápido",
   "index": 0,
   "picture": "rapido.si",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "rápido",
   "index": 1,
   "picture": "rapido.no",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "rápido",
   "index": 2,
   "picture": "despacio.no",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  },
  {
   "w": "rápido",
   "index": 3,
   "picture": "perro.si",
   "old": [99.33, 128, 54.34, 60],
   "crop": [75, 135, 98, 52],
   "zoom": 2
  }
 ],
 "clips": {},
 "clipsWhat": "camino.js never calls clip()",
 "front": {
  "how": "the old background (fondo: the arch, the trees, the bench, the big tree) was drawn before everyone; the bench and the arch are set things someone can be behind now. At its entry in the list camino.js draw sorts by y (line 107), for each item drawn before it (a person, the frog, Canelo, the cat: each item says who it is), the set's own pixels of that part (camino-set.html part(name), PART_TAGS) are drawn again inside the item's box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under its feet (a person or an animal: unproject(x, y - 1); the frog: unproject(b.x + b.w / 2, q.y + 25)). \"Behind the bench\" or \"behind a post\" is that depth test, not a row",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "boxes": "a person: [x - 24, y - alto - 2, 48, alto + 3]; the frog: frogBox with dy; Canelo or the cat: [x - 16, y - 24, 32, 27]; the cat on the bench (at points.gato_banco): its v is points.gato_banco.v, the seat's front edge (so nothing of the bench goes over it)",
  "parts": {
   "banco": {
    "sortY": 134.5,
    "insert": "before line 107's sort: L.push({y: 134.5, front: \"banco\"})",
    "why": "whoever stands behind the bench (Carmen at small trees 0 and 1, story 13; Canelo barking at tree 0, d-corre, y 134) is drawn before it and the bench over them; the cat on its seat is before it too, its plane the seat's front edge (boxes), so nothing of the bench goes over it"
   },
   "porton": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"porton\"}) (after everyone)",
    "why": "whoever has gone out through the arch (sevan) is behind it: its posts and its iron over them"
   }
  },
  "list": "line 102 (people: id), 103 (animals: k), 104 (the frog: id coqui): each item says who it is"
 },
 "shadows": {
  "coqui": {
   "radius": 0.45,
   "at": "the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))",
   "when": "W.cq.vis and al > .5",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "grown": 0.35,
    "nino": 0.3
   },
   "at": "the ground point under their feet on screen (unproject(x, y - 1))",
   "when": "visible (vis !== 0, al > .5)",
   "cast": "standing: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); sitting on the grass (sent): castShadow(g.x, g.y, .3, r)"
  },
  "perro": {
   "radius": 0.32,
   "at": "the ground point under its feet on screen (unproject(x, y - 1))",
   "when": "W.perro shown (vis !== 0, al > .5)",
   "cast": "castShadow(g.x, g.y, .25, .32)"
  },
  "gato": {
   "radius": 0.25,
   "at": "as Canelo",
   "when": "W.gato on the ground (vis !== 0, en == null), not on the bench (points.gato_banco)",
   "cast": "castShadow(g.x, g.y, .25, .25)"
  },
  "arbusto": {
   "radius": 0.55,
   "at": "the ground point under its foot on screen (unproject(arbusto[0], arbusto[1] - 1))",
   "when": "W.arbusto",
   "cast": "castShadow(g.x, g.y, .3, .55)",
   "why": "the bush is the sprite layer's (a prop of story 14, as the old); its shadow seats it on the lawn"
  },
  "dropped": "camino.js:87 rana()'s dotted shadow under the frog is not drawn: the engine casts his"
 },
 "dropped": [
  "camino.js:95 c.drawImage(spr(\"camino\"...), fondo()) -> the set, for setKey(W)",
  "camino.js:87 the frog's dotted shadow -> the engine's cast shadow"
 ],
 "moves": [
  {
   "line": 160,
   "act": "inicio12",
   "src": "async inicio12(){W.gente={luis:{x:174,y:138,pose:\"wave\",dir:-1}",
   "to": "async inicio12(){W.respEn=[134,14];W.gente={luis:{x:174,y:138,pose:\"wave\",dir:-1}",
   "respEn": [134, 14],
   "why": "acts.inicio12 (uno-dos-tres, d-corre, h-camino): the answer cards stand in the sky (W.respEn 134,14, as h-camino sets for itself at its beats.5: [96, 30], remapped to the same; two or three cards, their lit frames and glow, inside the view with 2 px to spare need 106 <= x <= 134 and y >= 14, and the sun at the top left keeps clear of them at 134): over the frog at the far marks they covered Luis, who waits by the big tree (uno-dos-tres beats.19 to 38), and the hand at a card reached his and Carmen's faces"
  },
  {
   "line": 193,
   "act": "inicio13",
   "src": "async inicio13(){W.sinGran=1;",
   "to": "async inicio13(){W.sinGran=1;W.respEn=[120,34];",
   "respEn": [120, 34],
   "why": "acts.inicio13 (donde-esta-el-gato): the answer cards (con_1, con_2, con_3: which tree the cat is in, by its birds; two at a time) stand in the sky over the trees (W.respEn 120,34): under the biscuits card (rows 2 to 33), above every bird's place, right of the sun with their frames (round 3), their frames inside the view with 2 px to spare: over the frog at the path's middle they covered Luis and Carmen (beats.47, 85) and the hand at a card was on Carmen's face"
  },
  {
   "line": 229,
   "act": "inicio14",
   "src": "async inicio14(){W.gente={abuela:",
   "to": "async inicio14(){W.respEn=[134,34];W.gente={abuela:",
   "respEn": [134, 34],
   "why": "acts.inicio14 (rapido-despacio): the answer cards stand in the sky under the guineos card (W.respEn 134,34): over the frog walking down the path to the arch they ran off the view's left edge (juego.js respBox clamps their middle 76 or 60 px from the edge: the first card's frame is cut)"
  },
  {
   "line": 61,
   "act": "*",
   "src": "Math.min(204,MARCA[i][0]+34)",
   "to": "Math.min(188,MARCA[i][0]+34)",
   "places": [
    {
     "who": "perro",
     "old": [204, 130],
     "new": [188, 130],
     "world": [2.774, -0.9247, 0]
    },
    {
     "who": "perro",
     "old": [191, 133],
     "new": [188, 133],
     "world": [2.9372, -0.7615, 0]
    }
   ],
   "why": "round 2: perroEn(i) caps Canelo's x at 188 (the old 204): at marks 7 and 8 he stands beside the big tree's foot, which is now further right (the old tree's foot was at 200, and he sat in front of it, hiding it): 204, 130 -> 188, 130 and 191, 133 -> 188, 133"
  },
  {
   "line": 258,
   "act": "sevan",
   "src": "async sevan(){const q=W.cq;W.correa=0;const fuera=async id=>{const p=G(id);for(let i=0;i<8;i++){p.x-=4;p.al=1-i/8;await wait(TICK);}p.vis=0;};await Promise.all([fuera(\"abuela\"),fuera(\"luis\"),fuera(\"carmen\"),animalA(\"perro\",-10,W.perro.y,\"walk\"),hopTo(8,q.y,2,q.s)]);q.vis=0;W.perro.vis=0;await wait(500);},",
   "to": "async sevan(){const q=W.cq,pe=W.perro;W.correa=0;pe.pose=\"walk\";const PU={\"abuela\":[45,169,35,164],\"carmen\":[45,169,35,164],\"luis\":[45,169,35,164],\"perro\":[45,169,35,164],\"cq\":[29,144,19,139]},fila=async(o,u,d,f)=>{await wait(d*TICK);const x0=o.x,y0=o.y;for(let i=0;i<8;i++){const a=i<4?[x0,y0,u[0],u[1],(i+1)/4]:[u[0],u[1],u[2],u[3],(i-3)/4];o.x=a[0]+(a[2]-a[0])*a[4];o.y=a[1]+(a[3]-a[1])*a[4];o.al=1-i/8;if(f){o.x=Math.round(o.x);o.y=Math.round(o.y);if(i%4===0)SFX.hop();o.dy=-7*Math.sin(Math.PI*(i%4+1)/4);}await wait(TICK);}if(f)o.dy=0;o.vis=0;};await Promise.all([fila(G(\"abuela\"),PU.abuela,0),fila(G(\"carmen\"),PU.carmen,3),fila(G(\"luis\"),PU.luis,6),fila(pe,PU.perro,9),fila(q,PU.cq,12,1)]);q.vis=0;pe.vis=0;await wait(500);},",
   "why": "acts.sevan (rapido-despacio, the end): everyone leaves the park through the arch, as the old picture had them leave towards its gate (the old act walked them 32 px left on the grass, fading, and the dog off the left edge at its row; the frog hopped to x 8). Round 2: in a file, one after another (abuela, Carmen, Luis, Canelo, the frog, 3 ticks apart): each walks in 4 steps to the same point just inside the opening (PU, screen: a person's or Canelo's feet, the frog's q), then in 4 more through it to just past its line, fading as the old (al 1 - i / 8) and gone; Canelo walks and fades too (moves: animal()), the frog hops twice (one hop to the opening, one through it: the old hop count) and fades. Whoever is under the arch has it drawn over them (front.porton); past its line everyone is faded (al .25 and less), so nobody is seen beyond the left post. What changes: each one's 8 steps as the old, but they start 3 ticks apart (the act takes 20 ticks, the old 8 for the people and about 18 for Canelo's walk), Canelo fades instead of walking off the picture, the frog's two hops take 4 ticks each instead of 5 and a wait"
  },
  {
   "line": 84,
   "act": "*",
   "src": "c.save();c.translate(R(o.x),R(o.y)-im.height+2+(o.dy||0));",
   "to": "c.save();c.globalAlpha=o.al==null?1:o.al;c.translate(R(o.x),R(o.y)-im.height+2+(o.dy||0));",
   "why": "animal(): Canelo and the cat are drawn with their al (1 unless set), so that Canelo fades as he goes out through the arch (acts.sevan); c.restore() puts the alpha back"
  },
  {
   "line": 112,
   "act": "*",
   "src": "c.drawImage(im,BANCO[0]+8,BANCO[1]-11,15,12)",
   "to": "c.drawImage(im,81,112,15,12)",
   "why": "the bird on the bench (W.avebanco, the pair gato.no): on the seat's back plank, its feet on it (points.ave_banco). The new bench stands along y and has no back: the bird -25 px right, -5 rows (the old at 106, 117)"
  },
  {
   "line": 69,
   "act": "*",
   "src": "box:w=>[R(w.gato.x)-12,R(w.gato.y)-18,24,20],m:2}",
   "to": "box:w=>[R(w.gato.x)-12,R(w.gato.y)-18,24,20],hand:w=>[R(w.gato.x)+12,R(w.gato.y)-10],m:2}",
   "why": "round 2: the cat's hint hand at its back (x + 12, y - 10; kit.js handAt takes a thing's hand): on the moved bench the hand from the box's middle hung on Carmen's face (donde-esta-el-gato beats.10)"
  },
  {
   "line": 194,
   "act": "inicio13",
   "src": "W.gato={x:113,y:134,pose:\"lava\"",
   "to": "W.gato={x:92,y:123,pose:\"lava\"",
   "places": [
    {
     "who": "gato",
     "old": [113, 134],
     "new": [92, 123],
     "world": [-0.2176, 1.3054, 0]
    }
   ],
   "why": "acts.inicio13: the cat on the bench, on the new bench's seat (points.gato_banco), as the story files' cat at 113, 134 (remap)"
  },
  {
   "line": 62,
   "act": "*",
   "src": "arbol0:[44,122,.8]",
   "to": "arbol0:[49,121,.8]",
   "places": [
    {
     "who": "cq",
     "old": [44, 122],
     "new": [49, 121],
     "world": [0.3536, 3.3452, 0]
    }
   ],
   "why": "LUGAR.arbol0, the frog at the first small tree: 5 px right and 1 row up, so that the arch's far post (screen x 47, in front of him: its foot 15 rows before his feet) is clear of him (at the old point it stood in front of his right side). Every hop count with the other places is the old one (hops). W.cq at (44, 122) in a recorded run is here (places: who cq)"
  }
 ],
 "sevan": {
  "a": [0.3, -0.22],
  "b": -0.12,
  "delay": {
   "abuela": 0,
   "carmen": 3,
   "luis": 6,
   "perro": 9,
   "cq": 12
  },
  "points": {
   "abuela": [
    [45, 169],
    [35, 164]
   ],
   "carmen": [
    [45, 169],
    [35, 164]
   ],
   "luis": [
    [45, 169],
    [35, 164]
   ],
   "perro": [
    [45, 169],
    [35, 164]
   ],
   "cq": [
    [29, 144],
    [19, 139]
   ]
  },
  "what": "moves (acts.sevan): each one's point just inside the arch's opening and their point past it up the path (screen: a person's feet, the dog's, the frog's q); GATE: the same, as (a, b) from the opening's middle in world units (a into the park, b towards post A)"
 },
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as camino.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
  "rects": {
   "hola": [-16, -46, 34, 44],
   "amor": [-14, -38, 30, 36],
   "como": [-32, -40, 66, 38],
   "bien": [-14, -40, 30, 38],
   "mal": [-14, -40, 30, 38],
   "quien": [-22, -40, 46, 38],
   "lluvia": [-22, -40, 46, 38],
   "q": [-12, -40, 26, 38]
  }
 },
 "talk": {
  "what": "where a bubble goes (camino.js draw: line 113 for a person, 114 for the frog, 85 for Canelo and the cat). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the biscuits, the guineos) and of every face (each visible person's and the frog's, its own too); if none is, the first (the old)",
  "top": "a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2 - (W.guineos != null ? 16 : 0)); Canelo or the cat: (x, y - 22)",
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
  "placesWhat": "[side, dy]: the tail's tip at (top.x + side * (h + 16), top.y + dy), h the head's half width: a person 6, the frog b.w >> 1, Canelo or the cat 8",
  "faces": "a person's face: [hx - 6, y + top + 5, 12, 10] (eyes to chin, not the hair), hx the head's middle; the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heads": {
   "luis": {
    "top": -41,
    "head": 0
   },
   "luis.sent": {
    "top": -38,
    "head": 0
   },
   "carmen": {
    "top": -41,
    "head": 0
   },
   "carmen.sent": {
    "top": -38,
    "head": 0
   },
   "abuela": {
    "top": -50,
    "head": 0
   }
  },
  "headsWhat": "each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the children drawn at -PX)",
  "boards": "in the 196 x 216 display, then + the view's x0: W.tarjeta galletas [2, 2, 90, 32]; W.tarjeta guineos [2, 2, 86, 32]"
 },
 "code": [
  {
   "line": 16,
   "old": "MARCA [66,182] [79,175] [92,168] [105,162] [118,156] [131,151] [144,146] [157,142] [170,139]",
   "to": {
    "points": ["marca.0", "marca.1", "marca.2", "marca.3", "marca.4", "marca.5", "marca.6", "marca.7", "marca.8"],
    "new": [
     [66, 182],
     [79, 175],
     [92, 168],
     [105, 162],
     [118, 156],
     [131, 151],
     [144, 146],
     [157, 142],
     [170, 139]
    ]
   },
   "note": "the floor rule: the same screen places (the set lays the stones at marks 1 to 7)"
  },
  {
   "line": 17,
   "old": "ARBOL [70,120] [112,116] [154,112]",
   "to": {
    "points": ["arbol.0", "arbol.1", "arbol.2"],
    "new": [
     [70, 120],
     [112, 116],
     [154, 112]
    ]
   },
   "note": "unchanged: the small trees stand at their old feet"
  },
  {
   "line": 17,
   "old": "GRAN [200,128]",
   "to": {
    "point": "gran",
    "new": [204, 103]
   },
   "note": "used only by the old background (dropped) and the big tree's box (things.grande)"
  },
  {
   "line": 17,
   "old": "BANCO [98,128,30,16]",
   "to": {
    "thing": "banco",
    "box": [77, 117, 28, 23]
   },
   "note": "used by the old background (dropped), the bench's box (things.banco) and the bird on it (moves)"
  },
  {
   "line": 18,
   "old": "NIDO [-9,-31] [8,-36] [0,-21]",
   "to": {
    "point": "nido"
   },
   "note": "relative to a small tree's foot: unchanged"
  },
  {
   "line": 54,
   "old": "galleta: the biscuit's rectangles [1,0,5,5] [0,1,7,3] [7,0,1,5] [8,-1,1,7] [6,1,1,3] (u(1,0,5,5) u(0,1,7,3) u(6,1,1,3) u(7,0,1,5) u(8,-1,1,7) u(1,1,1,1) u(3,3,2,1))",
   "to": "the biscuit's own drawing: unchanged"
  },
  {
   "line": 55,
   "old": "guineo: [0,2,2,2] [1,3,3,2] [3,4,4,2] [6,3,3,2] [8,1,2,3]",
   "to": "the guineo's own drawing: unchanged"
  },
  {
   "line": 59,
   "old": "ranaEn(i) = MARCA[i] - (22, 34), scale .96 - .015 i",
   "to": {
    "spots": "rana.0 to rana.8"
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 60,
   "old": "ninaEn(i) = MARCA[i] + (10, 22), y at most 206",
   "to": {
    "spots": "nina.0 to nina.8"
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 61,
   "old": "perroEn(i) = MARCA[i] + (34, -9), x at most 204",
   "to": {
    "spots": "perro.0 to perro.8",
    "moved": "x at most 188 (moves): perro.7, perro.8"
   },
   "note": "the floor rule: the same screen places, but marks 7 and 8"
  },
  {
   "line": 62,
   "old": "LUGAR centro [100,176,1], banco [74,128,.86], arbol0 [44,122,.8], arbol1 [126,122,.8], arbol2 [166,118,.8], gran [166,126,.84]",
   "to": {
    "spots": ["frog.inicio", "frog.centro", "frog.banco", "frog.arbol0", "frog.arbol1", "frog.arbol2", "frog.gran"],
    "moved": "arbol0: 49,121 (moves)"
   },
   "note": "the floor rule: the same screen places, but arbol0"
  },
  {
   "line": 64,
   "old": "caja(id): [x - 11, y - alto(id), 22, alto(id)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 66,
   "old": "ave box [ARBOL[i][0] + NIDO[k][0] - 8, ARBOL[i][1] + NIDO[k][1] - 6, 15, 12]",
   "to": "relative to the tree: unchanged"
  },
  {
   "line": 68,
   "old": "perro box [x - 14, y - 20, 28, 22]",
   "to": "relative: unchanged"
  },
  {
   "line": 69,
   "old": "gato box [x - 12, y - 18, 24, 20]",
   "to": "relative: unchanged"
  },
  {
   "line": 70,
   "old": "box arbol0 [ARBOL[0][0]-17,ARBOL[0][1]-46,34,48] = [53,74,34,48]; hand [ARBOL[0][0],ARBOL[0][1]-12]",
   "to": {
    "thing": "arbol0",
    "box": [51, 74, 37, 47],
    "hand": [70, 108]
   },
   "note": "the hand: things.arbol0.handWhy"
  },
  {
   "line": 70,
   "old": "box arbol1 [ARBOL[1][0]-17,ARBOL[1][1]-46,34,48] = [95,70,34,48]; hand [ARBOL[1][0],ARBOL[1][1]-12]",
   "to": {
    "thing": "arbol1",
    "box": [95, 68, 35, 49],
    "hand": [104, 104]
   },
   "note": "the hand: things.arbol1.handWhy"
  },
  {
   "line": 70,
   "old": "box arbol2 [ARBOL[2][0]-17,ARBOL[2][1]-46,34,48] = [137,66,34,48]; hand [ARBOL[2][0],ARBOL[2][1]-12]",
   "to": {
    "thing": "arbol2",
    "box": [135, 66, 38, 47],
    "hand": [146, 100]
   },
   "note": "the hand: things.arbol2.handWhy"
  },
  {
   "line": 71,
   "old": "box banco [BANCO[0]-1,BANCO[1]-2,BANCO[2]+2,18] = [97,126,32,18]",
   "to": {
    "thing": "banco",
    "box": [77, 117, 28, 23]
   }
  },
  {
   "line": 71,
   "old": "box grande [GRAN[0]-40,GRAN[1]-112,58,116] = [160,16,58,116]",
   "to": {
    "thing": "grande",
    "box": [160, 0, 80, 108],
    "hand": [190, 51]
   },
   "note": "and a hand (new: the old had none, so the box's middle)"
  },
  {
   "line": 71,
   "old": "box porton [22,116,36,60]",
   "to": {
    "thing": "porton",
    "box": [23, 94, 28, 80]
   }
  },
  {
   "line": 72,
   "old": "box camino [30,128,170,76]",
   "to": {
    "thing": "camino",
    "box": [0, 115, 240, 75]
   }
  },
  {
   "line": 72,
   "old": "box parque [0,100,240,116]",
   "to": {
    "thing": "parque",
    "box": [0, 100, 240, 116]
   }
  },
  {
   "line": 76,
   "old": "gente abuela: translate(x, y - 50), scale(-1,1) when dir < 0; drawImage(im,-30,0); the basket at x + 2, y - 26",
   "to": "relative to her: unchanged"
  },
  {
   "line": 78,
   "old": "gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 84,
   "old": "animal: translate(x, y - h + 2 + dy), scale(-1,1) when dir < 0, drawImage(im,-13,0)",
   "to": "relative: unchanged"
  },
  {
   "line": 85,
   "old": "animal: its bubble at x, y - 22",
   "to": {
    "talk": true
   },
   "note": "sheet talk: the first free place"
  },
  {
   "line": 87,
   "old": "rana: the dotted shadow at b.x + 2, q.y + 25",
   "to": "dropped: the engine casts his shadow (shadows.coqui)"
  },
  {
   "line": 93,
   "old": "bub2: c.scale(2,2), bub(c,k,0,0,a)",
   "to": "relative: unchanged (the bubbles are drawn at twice their size)"
  },
  {
   "line": 95,
   "old": "c.drawImage(spr(\"camino\"+...,()=>fondo(!W.sinGran)),0,0)",
   "to": "dropped: the set, for setKey(W)"
  },
  {
   "line": 96,
   "old": "the lit ring round a counted tree: ellipse at ARBOL[i] - (0, 30), 19 x 16",
   "to": "relative to the tree: unchanged"
  },
  {
   "line": 98,
   "old": "the shaking leaves at ARBOL + [-18,-36] [16,-40] [-14,-18] [18,-22]",
   "to": "relative to the tree: unchanged"
  },
  {
   "line": 99,
   "old": "the birds at ARBOL[i] + NIDO[k] - (8, 6 + vuelan), 15 x 12",
   "to": "relative: unchanged (on the crown's leaves)"
  },
  {
   "line": 100,
   "old": "the cat in a tree: its face at ARBOL - (12, 34), its tail at ARBOL[0] + lado 9 - 12, ARBOL[1] - 20",
   "to": "relative to the tree: unchanged"
  },
  {
   "line": 105,
   "old": "the snail at x - 9, y - 12 (its sort y)",
   "to": "relative: unchanged"
  },
  {
   "line": 106,
   "old": "the bush at arbusto - (22, 28) (sort y arbusto[1] + 2); the leash's end behind it at arbusto - (25, 9)",
   "to": "the sprite layer's, relative: unchanged (its shadow: shadows.arbusto)"
  },
  {
   "line": 107,
   "old": "the sorted list",
   "to": {
    "front": ["banco", "porton"]
   },
   "note": "two entries added before the sort (front.parts)"
  },
  {
   "line": 109,
   "old": "the leash: from the frog's hand or a person's (x +- 10, y - 18) to the dog's collar (x +- 8, y - 11), or to correaA",
   "to": "relative: unchanged"
  },
  {
   "line": 111,
   "old": "the dust at p.x + dir (4 + 6 i), p.y - 2; the speed lines",
   "to": "relative: unchanged"
  },
  {
   "line": 112,
   "old": "the bird on the bench at BANCO[0] + 8, BANCO[1] - 11",
   "to": {
    "point": "ave_banco",
    "new": [81, 112],
    "moved": "moves"
   }
  },
  {
   "line": 113,
   "old": "a person's bubble at x, y - alto - 1",
   "to": {
    "talk": true
   },
   "note": "sheet talk: the first free place"
  },
  {
   "line": 114,
   "old": "the frog's bubble at b.x + (b.w >> 1), b.y + 2 - (W.guineos != null ? 16 : 0)",
   "to": {
    "talk": true
   },
   "note": "sheet talk: the first free place"
  },
  {
   "line": 116,
   "old": "talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]",
   "to": "relative to the person: unchanged"
  },
  {
   "line": 120,
   "old": "respIcon espera: the frog at x + 6, y + 12; feet [9,30] [18,30]; the hand at x + 27, y + 5",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 121,
   "old": "respIcon corre: the frog at x + 24, y + 21 rotated, drawn at -10,-9; lin(3,9); dust [5,29] [11,27]",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 122,
   "old": "respIcon rapido: the frog at x + 15, y + 12; lin(3,6); steps [18,30] [27,30]",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 123,
   "old": "respIcon despacio: the frog at x + 14, y + 12; the snail at x + 2, y + 23; steps [18,30] [25,30]",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 124,
   "old": "respIcon camina: the frog at x + 12, y + 11; steps [2,29] [7,25]; the leaf [5,-3,2,9] [7,-1,2,5] [9,0,1,3]",
   "to": "the answer card's own drawing: unchanged"
  },
  {
   "line": 129,
   "old": "hud biscuits card tarjeta(g,3,3,88,30); the cat at 5,7",
   "to": "display: unchanged"
  },
  {
   "line": 130,
   "old": "hud biscuits card: the marks at 34 + 18 i, 10; the paw [1,3] [5,1] [9,1] [13,3]",
   "to": "display: unchanged"
  },
  {
   "line": 131,
   "old": "hud guineos card tarjeta(g,3,3,84,30); the basket at 5,13; guineo(g,30+i*17,10,1.5)",
   "to": "display: unchanged"
  },
  {
   "line": 138,
   "old": "enT(t): the frog on the walk back (story 14): (40 + 146 t - 10, 194 - 58 t - 8 sin(pi t) - 14)",
   "to": "the floor rule: the same screen places"
  },
  {
   "line": 139,
   "old": "perroT(t): the dog on the walk back: (40 + 146 tt - 2, 194 - 58 tt - 8 sin(pi tt) + 16)",
   "to": "the floor rule: the same screen places"
  },
  {
   "line": 160,
   "old": "inicio12: luis {x:174,y:138}; carmen at ninaEn(0); the frog at ranaEn(0); the dog at junto()",
   "to": {
    "floor": [
     [2.8284, -0.1088, 0]
    ],
    "new": [
     [174, 138]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 186,
   "old": "final12: mueve(\"carmen\",160,146); the dog to LUGAR.gran - (12, -28)",
   "to": {
    "floor": [2.8828, 0.7071, 0],
    "new": [160, 146]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 187,
   "old": "final12: the stars [150,60] [196,70] [176,50] [160,90] [200,96]",
   "to": "screen effect: unchanged (round the big tree)"
  },
  {
   "line": 193,
   "old": "inicio13: luis {x:62,y:188}, carmen {x:92,y:198}, perro {x:54,y:206}",
   "to": {
    "floor": [
     [2.5021, 5.6569, 0],
     [3.8619, 5.3849, 0],
     [3.2636, 6.8535, 0]
    ],
    "new": [
     [62, 188],
     [92, 198],
     [54, 206]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 194,
   "old": "inicio13: gato {x:113,y:134} (on the bench)",
   "to": {
    "point": "gato_banco",
    "new": [92, 123],
    "moved": "as the story files' (remap): on the new bench's seat"
   }
  },
  {
   "line": 198,
   "old": "gatoarbol: [0,1,2] the trees",
   "to": "not a place: the trees' numbers"
  },
  {
   "line": 203,
   "old": "lit: [0,1,2]",
   "to": "not a place"
  },
  {
   "line": 210,
   "old": "carmenvuelve: mueve(\"carmen\",92,198)",
   "to": {
    "floor": [3.8619, 5.3849, 0],
    "new": [92, 198]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 214,
   "old": "perrocome: animalA(\"perro\",54,206,\"walk\")",
   "to": {
    "floor": [3.2636, 6.8535, 0],
    "new": [54, 206]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 217,
   "old": "escapa: animalA(\"perro\",150,150,\"run\")",
   "to": {
    "floor": [2.8284, 1.1966, 0],
    "new": [150, 150]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 218,
   "old": "agarra: animalA(\"perro\",54,206,\"walk\")",
   "to": {
    "floor": [3.2636, 6.8535, 0],
    "new": [54, 206]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 219,
   "old": "cuentaaves: for [1,2,3]",
   "to": "not a place: the counts"
  },
  {
   "line": 220,
   "old": "carmenva: mueve(\"carmen\",ARBOL[i][0]+18,ARBOL[i][1]+12)",
   "to": {
    "spots": ["carmenva.0", "carmenva.1", "carmenva.2"]
   },
   "note": "relative to the tree: unchanged (whoever is behind the bench: front.banco)"
  },
  {
   "line": 224,
   "old": "perrocome2: animalA(\"perro\",54,206,\"walk\")",
   "to": {
    "floor": [3.2636, 6.8535, 0],
    "new": [54, 206]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 225,
   "old": "final13: mueve(\"carmen\",156,196)",
   "to": {
    "floor": [5.4937, 3.5355, 0],
    "new": [156, 196]
   },
   "note": "the floor rule: the same screen place"
  },
  {
   "line": 226,
   "old": "final13: the stars [90,150] [150,150] [120,130] [100,176] [140,176]",
   "to": "screen effect: unchanged (over the lawn)"
  },
  {
   "line": 229,
   "old": "inicio14: abuela {x:66,y:182}, luis {x:88,y:200}, carmen {x:46,y:202}; the bush at perroT(.46) + (16, 5); the frog at enT(1), the dog at perroT(1)",
   "to": {
    "floor": [
     [2.2845, 5.2217, 0],
     [3.8619, 5.6025, 0],
     [2.8284, 6.8535, 0]
    ],
    "new": [
     [66, 182],
     [88, 200],
     [46, 202]
    ]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 248,
   "old": "cae: the basket shakes [4,-4,3,0]",
   "to": "not a place: offsets"
  },
  {
   "line": 256,
   "old": "final14: the stars [40,120] [90,130] [64,110] [50,150] [90,160]",
   "to": "screen effect: unchanged (by the arch)"
  },
  {
   "line": 258,
   "old": "sevan: p.x -= 4 eight times, fading; the dog to -10, y; the frog to 8, y",
   "to": {
    "moved": "moves: out through the arch and up the path off the picture (sheet sevan)"
   }
  },
  {
   "line": 265,
   "old": "CAM.wide [22,0,196,216]",
   "to": {
    "view": "wide",
    "zoom": 1,
    "x0": 22
   }
  },
  {
   "line": 265,
   "old": "heartAt [110,30]",
   "to": {
    "point": "corazon",
    "new": [110, 30]
   }
  },
  {
   "line": 266,
   "old": "fresh(): pajaros [0,0,0]; cq at LUGAR.inicio",
   "to": "the counts; the frog at mark 0 (the floor rule)"
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: camino's fresh() puts him at LUGAR.inicio"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": "a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 22 things (old 22), 7 frog places (old 7), 1 view (old 1), 35 positions (old 35), 13 review pairs of cual-camino (25 pictures here; parque.no is El patio's), 16 level pictures (old 16), 127 places of camino.js named in code, 2 baked states (the old 9)",
   "hops: all 21 pairs of LUGAR places (round(d / 30), 1 to 4, kit.js acts.ir) keep the old count (arbol0 moved -5 px left: its distances inicio-arbol0 26 -> 27.46, centro-arbol0 77.79 -> 75.01, banco-arbol0 30.59 -> 25.96, arbol0-arbol1 82 -> 77.01, arbol0-arbol2 122.07 -> 117.04, arbol0-gran 122.07 -> 117.11); the frog walks between places in the recorded runs: inicio - centro (3), centro - arbol0 (8), arbol0 - arbol2 (3), centro - arbol2 (3), centro - arbol1 (1), arbol0 - arbol1 (1)",
   "boxes: every pixel of each set thing (the big tree's leaves at every wind step: 1 px either way) inside its touch box: porton [23,94,28,80], arbol0 [51,74,37,47], arbol1 [95,68,35,49], arbol2 [135,66,38,47], banco [77,117,28,23], grande [160,0,80,108]; every path pixel inside the camino box [0,115,240,75]; every pixel of each set thing answers that thing in the hit order (boxes that overlap: arbol0/banco, arbol2/grande, each overlap held by the one drawn there); the set's parts are arbol0, arbol1, arbol2, banco, camino, grande, porton (each a touch key's: nothing decorative)",
   "shadows: every castShadow call of the bake has strength 1 and a radius (none lost), each casting part darkens: porton 12 calls, 244 px set (0 calls wholly over shadow already); arbol0 36 calls, 1970 px set (0 calls wholly over shadow already); arbol1 36 calls, 1976 px set (0 calls wholly over shadow already); arbol2 36 calls, 1970 px set (0 calls wholly over shadow already); banco 12 calls, 896 px set (0 calls wholly over shadow already); grande 45 calls, 3226 px set (15 calls wholly over shadow already)",
   "ground: the lawn and the path only (4390 px of path); the set paints nothing else on the ground but the shadows its things cast and the seven stones in the path",
   "preview: at every moment of the 15 runs (5081 places of people, the frog, Canelo and the cat) camino-preview.html puts everyone exactly where the sheet does (0 differ)",
   "find them: Canelo and the cat have the lawn or the path behind them but gato at 46,172 before porton (60 px), perro at 80,149 before banco (73 px), perro at 46,177 before porton (28 px) (the snail always the path or the lawn)",
   "ground: 80 distinct stands of people, the frog, Canelo and the cat: nothing of the arch, the trees or the bench nearer than them inside their sprites, but where they are behind the bench or the arch and drawn before its entry (front): no one; at least 5 rows of lawn between anyone's feet and the foot of what stands behind them: the least behind a trunk 17 rows, uno-dos-tres right beats.38.right.0: the frog at 148,105; a post 9 rows, d-corre right null: the frog at 44,148; the bench 10 rows, d-corre right beats.49: perro at 80,149",
   "asks: 63 distinct asks (for arbol0, arbol1, arbol2, camina, carmen, con_2, con_3, corre, despacio, di_despacio, di_rapido, espera, gato, grande, luis, perro, rapido): every hint frame (box +- 12) wholly inside the view (0 px from its edge at the least), no frame's rings across a face where the old frame's were not (as the old: donde-esta-el-gato right beats.39 (arbol0) the frog's face; donde-esta-el-gato wrong beats.39 (arbol0) the frog's face; h-camino right beats.8 (perro) carmen's face; h-camino right beats.13 (arbol2) luis's face; h-camino right beats.21 (carmen) the frog's face; rapido-despacio right beats.8 (perro) the frog's face; uno-dos-tres right beats.11 (perro) carmen's face), the hint hand on no face; 103 answer cards, each with its lit frame and glow (+- 12) inside the view (2 px to spare at the least), over no one's body (no opaque pixel of anyone's sprite, in their pose, under a card)",
   "sun (round 3): at 38,47, radius 9: under no corner board (241 boards shown, 4 px to spare at the least) and under no answer card with its frame and glow (103 cards, 5 px to spare at the least), at every moment and ask of every run",
   "NOT solved, as the old picture: the hint hand at the first small tree (its old point; no point in the tree keeps it off every face and off the cat's tail and the birds) lies on a face at donde-esta-el-gato beats.32 (arbol0): over the cat's tail; donde-esta-el-gato beats.32 (arbol0): on luis's face; donde-esta-el-gato beats.39 (arbol0): over the cat's tail; donde-esta-el-gato beats.39 (arbol0): on luis's face; donde-esta-el-gato beats.39 (arbol0): on the frog's face; donde-esta-el-gato beats.70 (arbol0): on luis's face",
   "bubbles: 111 bubbles at 1066 moments of 15 runs (d-corre, donde-esta-el-gato, h-camino, rapido-despacio, uno-dos-tres), each its recorded one and the ones an act can show there (anyone's \"amor\" when touched, at any moment; Carmen's \"q\" at mirarriba; the frog's \"amor\" at lame and acaricia; the cat's at ronronea; Canelo's at final13, final14): wholly inside the view (0 px from its edge at the least), clear of the cards shown in the corner (11 px), on no face",
   "birds: every bird of the nine places perches on its own tree's crown (its leaves under at least 67% of its feet' columns), with nothing but that crown or the sky behind it, none overlapping another of its tree; a bird's blue stands out from the leaves behind it by 53 at the least (mean CIE76)",
   "perch: the bird on the bench (gato.no) has the seat's back plank under 6 of the 6 columns of its feet; the empty bench shows 190 px of its seat's top",
   "stones: the seven stones (marks 1 to 7) in the path, each whole and seen, nothing over them, 1 px apart at the least along the path",
   "sevan (round 2): everyone leaves through the arch in a file, their feet between the posts (x 29.39 to 44.61) as they cross its line (right: abuela at tick 7, carmen at tick 10, luis at tick 13, perro at tick 16, cq at tick 19; wrong: abuela at tick 7, carmen at tick 10, luis at tick 13, perro at tick 16, cq at tick 19; alternate: abuela at tick 7, carmen at tick 10, luis at tick 13, perro at tick 16, cq at tick 19); nobody shows (al > .3) past the line, so nobody is seen beyond the left post; nothing of the set but the arch nearer than them; all gone at the end",
   "arch shadow (round 3): only a contact shadow at each post's foot (57 px, all within 4.51 px of a post's foot; keep 5); the path's first leg, from the view's left edge to mark 0: near edge 251 px, 0% in shadow, lightness 159; far edge 523 px, 0% in shadow, lightness 149 (the lawn 130, the path's middle 180): no dark band along either edge",
   "big tree (round 2): its trunk 18 px wide (a small one 6), its crown 88 px wide (a small one 35, running off the picture's right and top edges), its middle at x 204 over the trunk at 204; no limb seen outside the trunk's columns; its hint box [160,12,46,96] (its touch box [160,0,80,108]), the frame inside the view, its hand 190,51 in it; the foot of its trunk seen at every moment (100% at the least: )",
   "shadows (round 2): each in one piece with its thing, from its foot (grande 339 px, arbol0 242 px, arbol1 465 px, arbol2 464 px, porton 20 px, banco 237 px); the path's edge is the path's own earth, ragged into the lawn (no edge line)",
   "sky (round 2): the sun at 38,47 (radius 9), left of the middle, whole in the view, nothing of the set within 2 px; the old picture's three clouds back, at 128,6; 140,24; 120,44 (the old 36,16; 112,9; 168,26: moved clear of the sun and the crowns), each clear of them by 2 px; no story or pair names the sun or a cloud by a position",
   "bench (round 4): behind whatever sits on it, besides the bench, one backdrop only: the cat (lava) lit lawn, the cat (lava, other frame) lit lawn, the cat (sit) lit lawn, the bird lit lawn, the bird (other frame) lit lawn",
   "pairs, what differs: perro: perro, gato; gato: gato, avebanco; arbol: the window; camina: luis corre, polvo; corre: perro pose, polvo; espera: carmen paso/corre, polvo; rapido: perro pose, polvo, caracol; despacio: gato pose, caracol, polvo; hay: gato; uno: pajaros; dos: pajaros; tres: pajaros",
   "pairs: 25 review pictures (and the 16 level pictures, the same pictures): everyone, the frog, Canelo, the cat, the snail and the birds whole in their crop (no zoom 2 crop cuts what the old window did not), on clear ground",
   "lawn: El frente's grass (GRASS), mean colour 125,146,64 (hue 75); the sprite layer's things on it, by their mean colour against it (CIE76), each with its dark outline: the bush 24, the snail 33, Canelo 34, the cat 51",
   "states: 2 baked states reached (gran 0, 1)"
  ]
 }
}
''',
  'campo': r'''{
 "scene": "campo",
 "made": "node docs/proyecto/pixel/campo-sheet-make.js, from campo-set.html (window.CAMPO_SET) and coqui/ref/escenas/campo/. Order 34a.",
 "S": 26,
 "origin": {
  "originX": 0,
  "originY": 4
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin (El camino's); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the field is built round the old picture: a place on its ground keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person's, Canelo's, a ball's or the basket's place (x, y): the ground point under (x, y - 1), new (x, y) = old (a ball keeps its height z). So every ground position of campo.js (LUGAR, CASA, PIES, CESTA, PILA, FILA, ORILLA, JUNCO, the acts' places), its stories and its pairs keeps its numbers, but for the cards' place in moves; the sheet names each one (spots, remap, code) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog, Canelo, a ball or the old crown (what is carried, the drops, the puddle, the shaking leaves round COPA and round the reeds' 190, 186, the splash, the butterfly, the bubbles) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the stars of the happy endings (final15, final16, final17), the heart (heartAt), the darkness of esconde16 (W.oscuro: the whole picture, then the frog again)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were"
 },
 "layout": {
  "what": "the open field of the park, on the world's axes, seen at the engine's 30 degrees (shadows to screen right): the lawn (El frente's grass, calm, as El camino's) from the horizon (row 100) to the bottom; at the left the tree, its foot and its crown where the old ones were, the trodden earth round its foot reaching Canelo's spot; at the lower right a corner of the lake, its shore a straight bank along y (up to the right on the screen), the water on the near side under a low bank of earth; along the shore the bed of reeds, at the water's edge and in the shallows. El camino's far hills and day sky over it, its sun in the upper left, the old picture's three clouds",
  "lines": {
   "shore": "the lake's shore: x = 5.7656 (screen sx + 2 sy = 582), from the bottom (x 150) to the picture's right edge (row 171); its surface 0.16 under the lawn (a bank 4 rows high)",
   "reeds": "the reeds: a bed along the shore from y 4.3 (down to the left) to -0.7 (up to the right), x 5.6856 to 5.9056 (from the damp lip to the shallows); on the screen from (168, 202) up to (205, 185)"
  },
  "why": "the brief and page 11 decision 9: the set stands on the world's axes and is seen at the engine's angle; nothing is built square to the camera. The old pond's rim ran from the bottom (x 160) up to the right; its four reed clusters stood on one line within 5 px of the screen line sx + 2 sy = 565, which is a line along y: so the shore runs along y, the water on its near side, and the reeds along it. The shore is placed so that every place the stories put someone on the land is on it (Canelo, the frog and the children at most at sx + 2 sy = 565), every ball they float on the lake is beyond it (603 and more), and the balls they hide in the reeds are in the bed (574, 576). The tree keeps its old foot and crown. Every place on the ground keeps its old screen point (rules.floor)",
  "moved": [
   "the tree's crown: its middle 2 px right of the old (62, 100), 27 x 25 px (the old 30 x 26), so its hint frame is inside the view (things.arbol)",
   "the lake: a straight shore along y (the old an ellipse round 232, 228): at the bottom it starts 10 px left of the old rim (x 150; the old 160), at the view's right edge it is 7 rows lower (182; the old 175)",
   "the reeds: a bed of about 21 stalks along the shore (the old four clusters of five); its right end at x 205 (the old 217), so that the hint frame round it is inside the view",
   "the sun: upper left (the old upper right), as El camino's; the clouds moved clear of the corner card and the answer cards",
   "unchanged: every place of a person, the frog, Canelo, a ball and the basket"
  ]
 },
 "behind": {
  "what": "nothing: the sun and the clouds are baked into the set's sky (El camino's); the butterfly of story 17 (W.mariposa) flies in front of everything, as the old",
  "items": []
 },
 "setKey": {
  "params": {},
  "key": "\"campo\" (one baked state)",
  "baked": [
   {
    "key": "campo",
    "query": "?"
   }
  ],
  "bakedWhy": "order 06 found 7 states, made by six keys of the sprite layer: cesta and cestaN (the basket and how many balls are in it: KIT.mkCesta and mkBola, drawn in the sorted list), flor (the flower of the pair bola.no), mojado (the frog's wetness: the puddle he stands in, which rana() draws under him, wider the wetter he is, and the drops on him), cierra (his eyes shut) and oscuro (acts.esconde16: the picture goes dark while he shuts his eyes and somebody hides the ball; draw() line 110 darkens everything and draws him again over it). None of them is the set's: none is the day's light or the ground's (mojado is his puddle, not wet ground; oscuro is his shut eyes, a curtain over the whole picture, people and all, for 10 ticks, not the hour), so they stay in the sprite layer as the old draws them, and this one baked state draws all 7 (and every review and level picture)"
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a child (today's sprite, drawn 1:1). caja(id) (campo.js:52): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "carmen": {
   "sprite": true,
   "why": "a child (today's sprite, drawn 1:1). caja(id) (campo.js:52): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "bola_luis": {
   "sprite": true,
   "why": "the big striped red ball (Luis's, BOLA.L, r 7) (mkBola): cajaBola (campo.js:61): [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4] where it is: unchanged"
  },
  "bola_carmen": {
   "sprite": true,
   "why": "the middle blue ball with white dots (Carmen's, BOLA.C, r 5.5) (mkBola): cajaBola (campo.js:61): [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4] where it is: unchanged"
  },
  "bola_cq": {
   "sprite": true,
   "why": "the small yellow ball with a white line (the frog's, BOLA.q, r 5) (mkBola): cajaBola (campo.js:61): [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4] where it is: unchanged"
  },
  "perro": {
   "sprite": true,
   "why": "Canelo (KIT.mkPerro): box [x - 14, y - 20, 28, 22] at W.perro, unchanged"
  },
  "cesta": {
   "sprite": true,
   "why": "the basket (KIT.mkCesta, with up to four small balls in it): box [x - 11, y - 16, 22, 18] at W.cesta, unchanged. It stays in the sprite layer, as El patio's crate: the stories put it in two places (104, 208; 88, 208) and fill and empty it; on the lawn on clear ground, its shadow cast by the engine (shadows.cesta)"
  },
  "arbol": {
   "set": true,
   "world": [-0.7479, 2.4341, 0, 0.7479, 3.9299, 2.5093],
   "box": [34, 71, 55, 84],
   "screen": [34, 71, 89, 155],
   "what": "the tree: its trunk, its limbs and its crown (still: at its height the wind moves no leaf a pixel)",
   "old": {
    "box": [30, 74, 60, 78]
   },
   "hand": [60, 100],
   "handWhy": "the old hand point: the crown's middle (COPA)",
   "hintBox": [36, 71, 53, 84],
   "hintWhy": "hintBox (round 3): the touch box shrunk on the left so that the hint frame (box + 12) is 2 px inside the view: the crown reaches x 34, 12 px from the view's edge"
  },
  "juncos": {
   "set": true,
   "world": [5.0449, 0.2312, 0, 6.7039, 1.8902, 0.9104],
   "box": [177, 140, 62, 51],
   "screen": [178, 140, 239, 191],
   "what": "the reeds: every stalk, head and blade of the bed along the shore",
   "old": {
    "box": [160, 168, 60, 48]
   },
   "hand": [188, 190],
   "handWhy": "the old hand point (188, 190): in the reeds",
   "hintBox": [177, 164, 27, 27],
   "hintWhy": "hintBox: the part of the touch box the hint frame shows (the frame and the twinkle are drawn round hintBox; the touch box answers the touches): the bed runs off the picture's right edge, as El camino's big tree's crown"
  },
  "campo": {
   "set": true,
   "ground": true,
   "what": "the field: the lawn and the lake from the horizon (row 100) to the bottom, the whole width: last in the hit order",
   "old": {
    "box": [0, 100, 240, 116]
   },
   "box": [0, 100, 240, 116],
   "world": [-0.8703, -0.8703, 0, 5.6569, 5.6569, -0.1776]
  }
 },
 "spots": {
  "frog.centro": {
   "world": [3.8619, 2.9916, 0],
   "new": [120, 150],
   "scale": 1,
   "old": [120, 150],
   "what": "LUGAR.centro: the frog in the middle of the field"
  },
  "frog.inicio": {
   "world": [3.8619, 2.9916, 0],
   "new": [120, 150],
   "scale": 1,
   "old": [120, 150],
   "what": "LUGAR.inicio: the frog in the middle of the field"
  },
  "frog.bajoarbol": {
   "world": [1.3598, 4.1882, 0],
   "new": [52, 138],
   "scale": 1,
   "old": [52, 138],
   "what": "the frog's place in acts.bajoarbol (hopTo, or W.cq)"
  },
  "frog.tumba": {
   "world": [1.4142, 4.3514, 0],
   "new": [50, 140],
   "scale": 1,
   "old": [50, 140],
   "what": "the frog's place in acts.tumba (hopTo, or W.cq)"
  },
  "frog.luisbusca": {
   "world": [1.1422, 4.4058, 0],
   "new": [44, 138],
   "scale": 1,
   "old": [44, 138],
   "what": "the frog's place in acts.luisbusca (hopTo, or W.cq)"
  },
  "frog.listos": {
   "world": [4.297, 2.5565, 0],
   "new": [136, 150],
   "scale": 1,
   "old": [136, 150],
   "what": "the frog's place in acts.listos (hopTo, or W.cq)"
  },
  "frog.inicio16": {
   "world": [3.7531, 2.2301, 0],
   "new": [132, 142],
   "scale": 1,
   "old": [132, 142],
   "what": "the frog's place in acts.inicio16 (hopTo, or W.cq)"
  },
  "frog.turno16a": {
   "world": [3.4811, 0.9791, 0],
   "new": [150, 128],
   "scale": 1,
   "old": [150, 128],
   "what": "the frog's place in acts.turno16a (hopTo, or W.cq)"
  },
  "frog.esconde16": {
   "world": [3.5355, 1.795, 0],
   "new": [136, 136],
   "scale": 1,
   "old": [136, 136],
   "what": "the frog's place in acts.esconde16 (hopTo, or W.cq)"
  },
  "frog.busca_arriba": {
   "world": [1.3054, 4.4602, 0],
   "new": [46, 140],
   "scale": 1,
   "old": [46, 140],
   "what": "the frog's place in acts.busca (hopTo, or W.cq)"
  },
  "frog.busca_baja": {
   "world": [3.046, 4.8954, 0],
   "new": [70, 160],
   "scale": 1,
   "old": [70, 160],
   "what": "the frog's place in acts.busca (hopTo, or W.cq)"
  },
  "frog.busca_abajo": {
   "world": [4.7594, 2.4205, 0],
   "new": [147, 153],
   "scale": 1,
   "old": [160, 166],
   "what": "the frog's place in acts.busca (hopTo, or W.cq)"
  },
  "frog.final16_no": {
   "world": [4.4058, 2.0125, 0],
   "new": [148, 146],
   "scale": 1,
   "old": [148, 146],
   "what": "the frog's place in acts.final16 (hopTo, or W.cq)"
  },
  "frog.final16_si": {
   "world": [3.3724, 2.6109, 0],
   "new": [118, 142],
   "scale": 1,
   "old": [118, 142],
   "what": "the frog's place in acts.final16 (hopTo, or W.cq)"
  },
  "frog.inicio17": {
   "world": [3.1004, 2.6652, 0],
   "new": [112, 140],
   "scale": 1,
   "old": [112, 140],
   "what": "the frog's place in acts.inicio17 (hopTo, or W.cq)"
  },
  "luis.casa": {
   "world": [2.6652, 4.4058, 0],
   "new": [88, 178],
   "old": [88, 178],
   "what": "CASA.luis: where Luis stands (acasa)"
  },
  "carmen.casa": {
   "world": [4.0251, 0.4351, 0],
   "new": [186, 154],
   "old": [186, 154],
   "what": "CASA.carmen: where Carmen stands (acasa), up the field near the lake"
  },
  "bola.pies": {
   "world": [4.9497, 4.0795, 0],
   "new": [136, 196],
   "old": [136, 196],
   "what": "PIES: where the frog's ball lies at his feet"
  },
  "cesta": {
   "world": [4.7322, 5.6025, 0],
   "new": [104, 208],
   "old": [104, 208],
   "what": "CESTA: the basket (story 15; story 16 puts it at 88, 208: spot cesta.16)"
  },
  "cesta.16": {
   "world": [4.297, 6.0376, 0],
   "new": [88, 208],
   "old": [88, 208],
   "what": "acts.inicio16: the basket"
  },
  "pila.0": {
   "world": [1.0879, 5.4393, 0],
   "new": [40, 173],
   "old": [40, 173],
   "what": "PILA[0]: Canelo's pile of balls, on the trodden earth by his spot"
  },
  "pila.1": {
   "world": [1.4686, 5.1673, 0],
   "new": [52, 174],
   "old": [52, 174],
   "what": "PILA[1]: Canelo's pile of balls, on the trodden earth by his spot"
  },
  "pila.2": {
   "world": [1.0335, 5.0585, 0],
   "new": [46, 169],
   "old": [46, 169],
   "what": "PILA[2]: Canelo's pile of balls, on the trodden earth by his spot"
  },
  "pila.3": {
   "world": [1.4686, 5.4937, 0],
   "new": [46, 177],
   "old": [46, 177],
   "what": "PILA[3]: Canelo's pile of balls, on the trodden earth by his spot"
  },
  "fila.0": {
   "world": [4.1882, 4.6234, 0],
   "new": [112, 194],
   "old": [112, 194],
   "what": "FILA[0]: story 17's row of balls on the grass"
  },
  "fila.1": {
   "world": [4.6778, 4.2426, 0],
   "new": [128, 195],
   "old": [128, 195],
   "what": "FILA[1]: story 17's row of balls on the grass"
  },
  "fila.2": {
   "world": [5.0585, 3.7531, 0],
   "new": [144, 194],
   "old": [144, 194],
   "what": "FILA[2]: story 17's row of balls on the grass"
  },
  "orilla": {
   "world": [6.5271, 2.7196, 0],
   "new": [190, 198],
   "old": [190, 198],
   "what": "ORILLA: the water's edge, where a ball rolls before it goes in (acts.alagua) and where Canelo wades for one (tira17)"
  },
  "junco": {
   "world": [6.2008, 2.9372, 0],
   "new": [180, 197],
   "old": [180, 197],
   "what": "JUNCO: where a ball hides in the reeds (ruedabajo, esconde16 abajo, sol abajo)"
  },
  "perro.sitio": {
   "world": [1.251, 5.0585, 0],
   "new": [50, 171],
   "old": [50, 171],
   "what": "SITIO + (4, 3): Canelo's spot under the tree, on the trodden earth"
  },
  "flota.0": {
   "world": [7.0711, 2.9372, 0],
   "new": [196, 205],
   "old": [196, 205],
   "what": "acts.alagua: the first ball that floats on the lake"
  },
  "flota.1": {
   "world": [6.9895, 2.2573, 0],
   "new": [207, 198],
   "old": [207, 198],
   "what": "acts.alagua: the second ball that floats on the lake"
  },
  "flota.2": {
   "world": [7.5606, 3.2092, 0],
   "new": [200, 212],
   "old": [200, 212],
   "what": "acts.alagua: the third ball that floats on the lake"
  },
  "flota.3": {
   "world": [7.6694, 2.6652, 0],
   "new": [212, 208],
   "old": [212, 208],
   "what": "acts.alagua: the fourth ball that floats on the lake"
  }
 },
 "lugar": {
  "centro": {
   "spot": "frog.centro",
   "q": [120, 150],
   "scale": 1,
   "old": [120, 150]
  },
  "inicio": {
   "spot": "frog.inicio",
   "q": [120, 150],
   "scale": 1,
   "old": [120, 150]
  }
 },
 "hops": [
  {
   "a": "bajoarbol",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 111.57,
   "dNew": 96.18
  },
  {
   "a": "tumba",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 113.03,
   "dNew": 97.87
  },
  {
   "a": "luisbusca",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 119.33,
   "dNew": 104.09
  },
  {
   "a": "busca_arriba",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 116.93,
   "dNew": 101.83
  },
  {
   "a": "busca_abajo",
   "b": "final16_si",
   "old": 2,
   "new": 1,
   "dOld": 48.37,
   "dNew": 31.02
  },
  {
   "a": "busca_abajo",
   "b": "inicio17",
   "old": 2,
   "new": 1,
   "dOld": 54.59,
   "dNew": 37.34
  }
 ],
 "hopsWhat": "each pair of the frog's places (LUGAR and every place an act hops him to) whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all 91 pairs). The acts' hopTo give their own counts, whatever the distance",
 "hopsAll": [
  {
   "a": "centro",
   "b": "bajoarbol",
   "old": 2,
   "new": 2,
   "dOld": 69.05,
   "dNew": 69.05
  },
  {
   "a": "centro",
   "b": "tumba",
   "old": 2,
   "new": 2,
   "dOld": 70.71,
   "dNew": 70.71
  },
  {
   "a": "centro",
   "b": "luisbusca",
   "old": 3,
   "new": 3,
   "dOld": 76.94,
   "dNew": 76.94
  },
  {
   "a": "centro",
   "b": "listos",
   "old": 1,
   "new": 1,
   "dOld": 16,
   "dNew": 16
  },
  {
   "a": "centro",
   "b": "inicio16",
   "old": 1,
   "new": 1,
   "dOld": 14.42,
   "dNew": 14.42
  },
  {
   "a": "centro",
   "b": "turno16a",
   "old": 1,
   "new": 1,
   "dOld": 37.2,
   "dNew": 37.2
  },
  {
   "a": "centro",
   "b": "esconde16",
   "old": 1,
   "new": 1,
   "dOld": 21.26,
   "dNew": 21.26
  },
  {
   "a": "centro",
   "b": "busca_arriba",
   "old": 2,
   "new": 2,
   "dOld": 74.67,
   "dNew": 74.67
  },
  {
   "a": "centro",
   "b": "busca_baja",
   "old": 2,
   "new": 2,
   "dOld": 50.99,
   "dNew": 50.99
  },
  {
   "a": "centro",
   "b": "busca_abajo",
   "old": 1,
   "new": 1,
   "dOld": 43.08,
   "dNew": 27.17
  },
  {
   "a": "centro",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 28.28,
   "dNew": 28.28
  },
  {
   "a": "centro",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 8.25,
   "dNew": 8.25
  },
  {
   "a": "centro",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 12.81,
   "dNew": 12.81
  },
  {
   "a": "bajoarbol",
   "b": "tumba",
   "old": 0,
   "new": 0,
   "dOld": 2.83,
   "dNew": 2.83
  },
  {
   "a": "bajoarbol",
   "b": "luisbusca",
   "old": 1,
   "new": 1,
   "dOld": 8,
   "dNew": 8
  },
  {
   "a": "bajoarbol",
   "b": "listos",
   "old": 3,
   "new": 3,
   "dOld": 84.85,
   "dNew": 84.85
  },
  {
   "a": "bajoarbol",
   "b": "inicio16",
   "old": 3,
   "new": 3,
   "dOld": 80.1,
   "dNew": 80.1
  },
  {
   "a": "bajoarbol",
   "b": "turno16a",
   "old": 3,
   "new": 3,
   "dOld": 98.51,
   "dNew": 98.51
  },
  {
   "a": "bajoarbol",
   "b": "esconde16",
   "old": 3,
   "new": 3,
   "dOld": 84.02,
   "dNew": 84.02
  },
  {
   "a": "bajoarbol",
   "b": "busca_arriba",
   "old": 1,
   "new": 1,
   "dOld": 6.32,
   "dNew": 6.32
  },
  {
   "a": "bajoarbol",
   "b": "busca_baja",
   "old": 1,
   "new": 1,
   "dOld": 28.43,
   "dNew": 28.43
  },
  {
   "a": "bajoarbol",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 111.57,
   "dNew": 96.18
  },
  {
   "a": "bajoarbol",
   "b": "final16_no",
   "old": 3,
   "new": 3,
   "dOld": 96.33,
   "dNew": 96.33
  },
  {
   "a": "bajoarbol",
   "b": "final16_si",
   "old": 2,
   "new": 2,
   "dOld": 66.12,
   "dNew": 66.12
  },
  {
   "a": "bajoarbol",
   "b": "inicio17",
   "old": 2,
   "new": 2,
   "dOld": 60.03,
   "dNew": 60.03
  },
  {
   "a": "tumba",
   "b": "luisbusca",
   "old": 1,
   "new": 1,
   "dOld": 6.32,
   "dNew": 6.32
  },
  {
   "a": "tumba",
   "b": "listos",
   "old": 3,
   "new": 3,
   "dOld": 86.58,
   "dNew": 86.58
  },
  {
   "a": "tumba",
   "b": "inicio16",
   "old": 3,
   "new": 3,
   "dOld": 82.02,
   "dNew": 82.02
  },
  {
   "a": "tumba",
   "b": "turno16a",
   "old": 3,
   "new": 3,
   "dOld": 100.72,
   "dNew": 100.72
  },
  {
   "a": "tumba",
   "b": "esconde16",
   "old": 3,
   "new": 3,
   "dOld": 86.09,
   "dNew": 86.09
  },
  {
   "a": "tumba",
   "b": "busca_arriba",
   "old": 1,
   "new": 1,
   "dOld": 4,
   "dNew": 4
  },
  {
   "a": "tumba",
   "b": "busca_baja",
   "old": 1,
   "new": 1,
   "dOld": 28.28,
   "dNew": 28.28
  },
  {
   "a": "tumba",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 113.03,
   "dNew": 97.87
  },
  {
   "a": "tumba",
   "b": "final16_no",
   "old": 3,
   "new": 3,
   "dOld": 98.18,
   "dNew": 98.18
  },
  {
   "a": "tumba",
   "b": "final16_si",
   "old": 2,
   "new": 2,
   "dOld": 68.03,
   "dNew": 68.03
  },
  {
   "a": "tumba",
   "b": "inicio17",
   "old": 2,
   "new": 2,
   "dOld": 62,
   "dNew": 62
  },
  {
   "a": "luisbusca",
   "b": "listos",
   "old": 3,
   "new": 3,
   "dOld": 92.78,
   "dNew": 92.78
  },
  {
   "a": "luisbusca",
   "b": "inicio16",
   "old": 3,
   "new": 3,
   "dOld": 88.09,
   "dNew": 88.09
  },
  {
   "a": "luisbusca",
   "b": "turno16a",
   "old": 4,
   "new": 4,
   "dOld": 106.47,
   "dNew": 106.47
  },
  {
   "a": "luisbusca",
   "b": "esconde16",
   "old": 3,
   "new": 3,
   "dOld": 92.02,
   "dNew": 92.02
  },
  {
   "a": "luisbusca",
   "b": "busca_arriba",
   "old": 0,
   "new": 0,
   "dOld": 2.83,
   "dNew": 2.83
  },
  {
   "a": "luisbusca",
   "b": "busca_baja",
   "old": 1,
   "new": 1,
   "dOld": 34.06,
   "dNew": 34.06
  },
  {
   "a": "luisbusca",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 119.33,
   "dNew": 104.09
  },
  {
   "a": "luisbusca",
   "b": "final16_no",
   "old": 3,
   "new": 3,
   "dOld": 104.31,
   "dNew": 104.31
  },
  {
   "a": "luisbusca",
   "b": "final16_si",
   "old": 2,
   "new": 2,
   "dOld": 74.11,
   "dNew": 74.11
  },
  {
   "a": "luisbusca",
   "b": "inicio17",
   "old": 2,
   "new": 2,
   "dOld": 68.03,
   "dNew": 68.03
  },
  {
   "a": "listos",
   "b": "inicio16",
   "old": 1,
   "new": 1,
   "dOld": 8.94,
   "dNew": 8.94
  },
  {
   "a": "listos",
   "b": "turno16a",
   "old": 1,
   "new": 1,
   "dOld": 26.08,
   "dNew": 26.08
  },
  {
   "a": "listos",
   "b": "esconde16",
   "old": 1,
   "new": 1,
   "dOld": 14,
   "dNew": 14
  },
  {
   "a": "listos",
   "b": "busca_arriba",
   "old": 3,
   "new": 3,
   "dOld": 90.55,
   "dNew": 90.55
  },
  {
   "a": "listos",
   "b": "busca_baja",
   "old": 2,
   "new": 2,
   "dOld": 66.75,
   "dNew": 66.75
  },
  {
   "a": "listos",
   "b": "busca_abajo",
   "old": 1,
   "new": 1,
   "dOld": 28.84,
   "dNew": 11.4
  },
  {
   "a": "listos",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 12.65,
   "dNew": 12.65
  },
  {
   "a": "listos",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 19.7,
   "dNew": 19.7
  },
  {
   "a": "listos",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 26,
   "dNew": 26
  },
  {
   "a": "inicio16",
   "b": "turno16a",
   "old": 1,
   "new": 1,
   "dOld": 22.8,
   "dNew": 22.8
  },
  {
   "a": "inicio16",
   "b": "esconde16",
   "old": 1,
   "new": 1,
   "dOld": 7.21,
   "dNew": 7.21
  },
  {
   "a": "inicio16",
   "b": "busca_arriba",
   "old": 3,
   "new": 3,
   "dOld": 86.02,
   "dNew": 86.02
  },
  {
   "a": "inicio16",
   "b": "busca_baja",
   "old": 2,
   "new": 2,
   "dOld": 64.56,
   "dNew": 64.56
  },
  {
   "a": "inicio16",
   "b": "busca_abajo",
   "old": 1,
   "new": 1,
   "dOld": 36.88,
   "dNew": 18.6
  },
  {
   "a": "inicio16",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 16.49,
   "dNew": 16.49
  },
  {
   "a": "inicio16",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 14,
   "dNew": 14
  },
  {
   "a": "inicio16",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 20.1,
   "dNew": 20.1
  },
  {
   "a": "turno16a",
   "b": "esconde16",
   "old": 1,
   "new": 1,
   "dOld": 16.12,
   "dNew": 16.12
  },
  {
   "a": "turno16a",
   "b": "busca_arriba",
   "old": 3,
   "new": 3,
   "dOld": 104.69,
   "dNew": 104.69
  },
  {
   "a": "turno16a",
   "b": "busca_baja",
   "old": 3,
   "new": 3,
   "dOld": 86.16,
   "dNew": 86.16
  },
  {
   "a": "turno16a",
   "b": "busca_abajo",
   "old": 1,
   "new": 1,
   "dOld": 39.29,
   "dNew": 25.18
  },
  {
   "a": "turno16a",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 18.11,
   "dNew": 18.11
  },
  {
   "a": "turno16a",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 34.93,
   "dNew": 34.93
  },
  {
   "a": "turno16a",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 39.85,
   "dNew": 39.85
  },
  {
   "a": "esconde16",
   "b": "busca_arriba",
   "old": 3,
   "new": 3,
   "dOld": 90.09,
   "dNew": 90.09
  },
  {
   "a": "esconde16",
   "b": "busca_baja",
   "old": 2,
   "new": 2,
   "dOld": 70.23,
   "dNew": 70.23
  },
  {
   "a": "esconde16",
   "b": "busca_abajo",
   "old": 1,
   "new": 1,
   "dOld": 38.42,
   "dNew": 20.25
  },
  {
   "a": "esconde16",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 15.62,
   "dNew": 15.62
  },
  {
   "a": "esconde16",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 18.97,
   "dNew": 18.97
  },
  {
   "a": "esconde16",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 24.33,
   "dNew": 24.33
  },
  {
   "a": "busca_arriba",
   "b": "busca_baja",
   "old": 1,
   "new": 1,
   "dOld": 31.24,
   "dNew": 31.24
  },
  {
   "a": "busca_arriba",
   "b": "busca_abajo",
   "old": 4,
   "new": 3,
   "dOld": 116.93,
   "dNew": 101.83
  },
  {
   "a": "busca_arriba",
   "b": "final16_no",
   "old": 3,
   "new": 3,
   "dOld": 102.18,
   "dNew": 102.18
  },
  {
   "a": "busca_arriba",
   "b": "final16_si",
   "old": 2,
   "new": 2,
   "dOld": 72.03,
   "dNew": 72.03
  },
  {
   "a": "busca_arriba",
   "b": "inicio17",
   "old": 2,
   "new": 2,
   "dOld": 66,
   "dNew": 66
  },
  {
   "a": "busca_baja",
   "b": "busca_abajo",
   "old": 3,
   "new": 3,
   "dOld": 90.2,
   "dNew": 77.32
  },
  {
   "a": "busca_baja",
   "b": "final16_no",
   "old": 3,
   "new": 3,
   "dOld": 79.25,
   "dNew": 79.25
  },
  {
   "a": "busca_baja",
   "b": "final16_si",
   "old": 2,
   "new": 2,
   "dOld": 51.26,
   "dNew": 51.26
  },
  {
   "a": "busca_baja",
   "b": "inicio17",
   "old": 2,
   "new": 2,
   "dOld": 46.52,
   "dNew": 46.52
  },
  {
   "a": "busca_abajo",
   "b": "final16_no",
   "old": 1,
   "new": 1,
   "dOld": 23.32,
   "dNew": 7.07
  },
  {
   "a": "busca_abajo",
   "b": "final16_si",
   "old": 2,
   "new": 1,
   "dOld": 48.37,
   "dNew": 31.02
  },
  {
   "a": "busca_abajo",
   "b": "inicio17",
   "old": 2,
   "new": 1,
   "dOld": 54.59,
   "dNew": 37.34
  },
  {
   "a": "final16_no",
   "b": "final16_si",
   "old": 1,
   "new": 1,
   "dOld": 30.27,
   "dNew": 30.27
  },
  {
   "a": "final16_no",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 36.5,
   "dNew": 36.5
  },
  {
   "a": "final16_si",
   "b": "inicio17",
   "old": 1,
   "new": 1,
   "dOld": 6.32,
   "dNew": 6.32
  }
 ],
 "points": {
  "arbol": {
   "screen": [60, 152],
   "old": [60, 152],
   "world": [0.5439, 3.8075, 0],
   "what": "ARBOL: the tree's foot (unchanged): the ball in the tree (HORQ, ARBOL[1]), the shaking leaves (COPA), the frog's and the people's places under it are all as the old"
  },
  "copa": {
   "screen": [63, 99],
   "radii": [25, 25],
   "old": [60, 100, 30, 26],
   "what": "the crown: its middle and radii on the screen (the old COPA 60, 100, 30, 26: the shaking leaves of W.tiembla stay round the old middle)"
  },
  "horq": {
   "screen": [64, 116],
   "old": [64, 116],
   "hollow": [64, 111, 10, 9],
   "what": "HORQ: the fork where a ball sticks (64, 116): the hollow in the crown's front over it, through which the limbs show (hollow: its middle and radii on the screen)"
  },
  "sitio": {
   "screen": [46, 168],
   "old": [46, 168],
   "what": "SITIO: Canelo's spot, on the trodden earth that runs from the tree's foot"
  },
  "orilla": {
   "screen": [190, 198],
   "old": [190, 198],
   "what": "ORILLA: the water's edge (unchanged)"
  },
  "junco": {
   "screen": [180, 197],
   "old": [180, 197],
   "what": "JUNCO: in the reeds (unchanged)"
  },
  "corazon": {
   "screen": [110, 30],
   "old": [110, 30],
   "what": "heartAt: the heart of a happy ending, in the sky (unchanged)"
  },
  "sol": {
   "screen": [38, 47],
   "radius": 9,
   "what": "the sun: baked into the set's sky (El camino's, in the same place: left of the middle, every shadow falls to the right), under the corner card's place and left of the answer cards' frames, whole inside the wide view; no story touches it or names its place (the old sun was at the upper right)"
  },
  "nubes": {
   "screen": [
    [188, 12, 0.7],
    [204, 34, 0.8],
    [108, 10, 0.6]
   ],
   "old": [
    [36, 16, 1],
    [112, 9, 0.7],
    [168, 26, 0.8]
   ],
   "what": "the old picture's three clouds (x, y, size: engine.js sky()), baked into the set's sky as El camino's, moved clear of the corner card, the sun, the crown and the answer cards' place; no story names them"
  },
  "orilla_linea": {
   "screen": [
    [149, 204],
    [220, 168]
   ],
   "world": 5.7656,
   "what": "the lake's shore: the line x = 5.7656 (on the screen sx + 2 sy = 582), wavering a little; the water on its near side, its surface 0.16 under the lawn"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [2.0669, 2.0669, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the field: the tree, the lawn, the reeds, the corner of the lake, the sky"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [4, 84, 113, 60],
   "uses": ["cual-campo.json arriba.si.cam"],
   "to": {
    "pictures": ["arriba.si"]
   },
   "crops": {
    "arriba.si": {
     "crop": [13, 88, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [14, 78, 150, 79.6],
   "uses": ["cual-campo.json abajo.si.cam", "cual-campo.json abajo.no.cam"],
   "to": {
    "pictures": ["abajo.si", "abajo.no"]
   },
   "crops": {
    "abajo.si": {
     "crop": [0, 66, 196, 104],
     "zoom": 1
    },
    "abajo.no": {
     "crop": [0, 66, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [74, 126, 113, 60],
   "uses": ["cual-campo.json tiene.si.cam", "cual-campo.json tiene.no.cam", "cual-campo.json dame.si.cam", "cual-campo.json dame.no.cam", "cual-campo.json mi.si.cam", "cual-campo.json mi.no.cam", "cual-campo.json tu.si.cam", "cual-campo.json tu.no.cam"],
   "to": {
    "pictures": ["tiene.si", "tiene.no", "dame.si", "dame.no", "mi.si", "mi.no", "tu.si", "tu.no"]
   },
   "crops": {
    "tiene.si": {
     "crop": [33, 104, 196, 104],
     "zoom": 1
    },
    "tiene.no": {
     "crop": [33, 104, 196, 104],
     "zoom": 1
    },
    "dame.si": {
     "crop": [90, 98, 98, 52],
     "zoom": 2
    },
    "dame.no": {
     "crop": [90, 98, 98, 52],
     "zoom": 2
    },
    "mi.si": {
     "crop": [89, 98, 98, 52],
     "zoom": 2
    },
    "mi.no": {
     "crop": [89, 98, 98, 52],
     "zoom": 2
    },
    "tu.si": {
     "crop": [90, 98, 98, 52],
     "zoom": 2
    },
    "tu.no": {
     "crop": [90, 98, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 112, 134, 71.1],
   "uses": ["cual-campo.json tira.si.cam", "cual-campo.json tira.no.cam", "cual-campo.json coge.si.cam", "cual-campo.json coge.no.cam"],
   "to": {
    "pictures": ["tira.si", "tira.no", "coge.si", "coge.no"]
   },
   "crops": {
    "tira.si": {
     "crop": [44, 96, 196, 104],
     "zoom": 1
    },
    "tira.no": {
     "crop": [44, 96, 196, 104],
     "zoom": 1
    },
    "coge.si": {
     "crop": [44, 96, 196, 104],
     "zoom": 1
    },
    "coge.no": {
     "crop": [44, 96, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [100, 150, 75, 39.8],
   "uses": ["cual-campo.json bola.si.cam", "cual-campo.json bola.no.cam", "cual-campo.json salta.si.cam", "cual-campo.json salta.no.cam"],
   "to": {
    "pictures": ["bola.si", "bola.no", "salta.si", "salta.no"]
   },
   "crops": {
    "bola.si": {
     "crop": [99, 101, 98, 52],
     "zoom": 2
    },
    "bola.no": {
     "crop": [99, 101, 98, 52],
     "zoom": 2
    },
    "salta.si": {
     "crop": [90, 100, 98, 52],
     "zoom": 2
    },
    "salta.no": {
     "crop": [90, 100, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [108, 150, 113, 60],
   "uses": [
    "cual-campo.json más.si.cam",
    "cual-campo.json más.no.cam"
   ],
   "to": {
    "pictures": ["mas.si", "mas.no"]
   },
   "crops": {
    "mas.si": {
     "crop": [44, 112, 196, 104],
     "zoom": 1
    },
    "mas.no": {
     "crop": [44, 112, 196, 104],
     "zoom": 1
    }
   }
  },
  {
   "kind": "cam",
   "old": [120, 150, 113, 60],
   "uses": ["cual-campo.json arriba.no.cam"],
   "to": {
    "pictures": ["arriba.no"]
   },
   "crops": {
    "arriba.no": {
     "crop": [131, 156, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [36.83, 84, 54.34, 60],
   "uses": [
    "nivel.js NV arriba.p0"
   ],
   "to": {
    "pictures": ["arriba.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [53.95, 78, 72.09, 79.6],
   "uses": [
    "nivel.js NV arriba.p2"
   ],
   "to": {
    "pictures": ["abajo.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [86.83, 126, 54.34, 60],
   "uses": [
    "nivel.js NV mi.p0"
   ],
   "to": {
    "pictures": ["mi.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [98.83, 126, 54.34, 60],
   "uses": [
    "nivel.js NV mi.p1"
   ],
   "to": {
    "pictures": ["mi.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [99.8, 112, 64.39, 71.1],
   "uses": [
    "nivel.js NV tira.p1"
   ],
   "to": {
    "pictures": ["tira.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [100.83, 126, 54.34, 60],
   "uses": [
    "nivel.js NV tira.p2",
    "nivel.js NV coge.p2"
   ],
   "to": {
    "pictures": ["dame.si", "dame.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [101.8, 112, 64.39, 71.1],
   "uses": [
    "nivel.js NV tira.p0",
    "nivel.js NV coge.p1",
    "nivel.js NV mi.p2"
   ],
   "to": {
    "pictures": ["tira.si", "coge.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [102.83, 126, 54.34, 60],
   "uses": [
    "nivel.js NV tira.p3",
    "nivel.js NV mi.p3"
   ],
   "to": {
    "pictures": ["tiene.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [105.8, 112, 64.39, 71.1],
   "uses": [
    "nivel.js NV coge.p0"
   ],
   "to": {
    "pictures": ["coge.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [119.48, 150, 36.05, 39.8],
   "uses": [
    "nivel.js NV coge.p3",
    "nivel.js NV arriba.p3"
   ],
   "to": {
    "pictures": ["salta.si", "salta.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [148.83, 150, 54.34, 60],
   "uses": [
    "nivel.js NV arriba.p1"
   ],
   "to": {
    "pictures": ["arriba.no"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [-16, -27],
   "uses": ["cual-campo.json bola.si.set.cq", "cual-campo.json bola.no.set.cq", "cual-campo.json tiene.si.set.cq", "cual-campo.json tiene.no.set.cq", "cual-campo.json tira.si.set.cq", "cual-campo.json tira.no.set.cq", "cual-campo.json coge.si.set.cq", "cual-campo.json coge.no.set.cq", "cual-campo.json salta.si.set.cq", "cual-campo.json salta.no.set.cq", "cual-campo.json tu.si.set.cq", "cual-campo.json tu.no.set.cq", "cual-campo.json arriba.si.set.cq", "cual-campo.json arriba.no.set.cq"],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0): not a place"
  },
  {
   "kind": "point",
   "old": [0, 1],
   "uses": ["cual-campo.json tira.no.set.bolas.a.vuela", "cual-campo.json coge.si.set.bolas.a.vuela"],
   "to": {
    "none": true
   },
   "what": "a ball's flight lines (vuela: a direction, not a place)"
  },
  {
   "kind": "point",
   "old": [1, 0],
   "uses": ["cual-campo.json tira.si.set.bolas.a.vuela", "cual-campo.json coge.no.set.bolas.a.vuela"],
   "to": {
    "none": true
   },
   "what": "a ball's flight lines (vuela: a direction, not a place)"
  },
  {
   "kind": "point",
   "old": [46, 87],
   "uses": ["cual-campo.json abajo.no.set.cq"],
   "to": {
    "floor": [-3.4267, 0.5983, 0]
   },
   "new": [46, 87],
   "what": "the frog's place q (x, y): the ground under (x + 16, y + 25); the same screen place (in the tree's crown: abajo.no)"
  },
  {
   "kind": "point",
   "old": [64, 152],
   "uses": ["cual-campo.json arriba.si.set.bolas.a"],
   "to": {
    "floor": [0.5983, 3.6443, 0]
   },
   "new": [64, 152],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [80, 127],
   "uses": ["cual-campo.json abajo.si.set.cq"],
   "to": {
    "floor": [-0.3264, 1.8494, 0]
   },
   "new": [80, 127],
   "what": "the frog's place q (x, y): the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [88, 155],
   "uses": ["cual-campo.json dame.si.set.cq", "cual-campo.json dame.no.set.cq"],
   "to": {
    "floor": [-0.4351, 0.8703, 0]
   },
   "new": [96, 117],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "the frog's place q (x, y): the ground under (x + 16, y + 25); moved (why)"
  },
  {
   "kind": "point",
   "old": [92, 184],
   "uses": ["cual-campo.json mi.no.set.bolas.a"],
   "to": {
    "floor": [1.251, 2.3389, 0]
   },
   "new": [100, 146],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [94, 184],
   "uses": ["cual-campo.json tu.si.set.bolas.b"],
   "to": {
    "floor": [1.3054, 2.2845, 0]
   },
   "new": [102, 146],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [108, 159],
   "uses": [
    "cual-campo.json más.si.set.cq",
    "cual-campo.json más.no.set.cq"
   ],
   "to": {
    "floor": [2.1757, 2.8284, 0]
   },
   "new": [108, 159],
   "what": "the frog's place q (x, y): the ground under (x + 16, y + 25); the same screen place"
  },
  {
   "kind": "point",
   "old": [110, 182],
   "uses": ["cual-campo.json mi.si.set.gente.luis", "cual-campo.json mi.no.set.gente.luis"],
   "to": {
    "floor": [1.6318, 1.7406, 0]
   },
   "new": [118, 144],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a child's feet (x, y): the ground under them; moved (why)"
  },
  {
   "kind": "point",
   "old": [112, 40],
   "uses": [
    "h-campo.json beats.1.set.respEn"
   ],
   "to": {
    "screen": [132, 32]
   },
   "new": [132, 32],
   "moved": true,
   "why": "the answer cards where the scene's inicio acts put them (moves), clear of the sun and the rounds card, their frames inside the view with 2 px to spare",
   "what": "W.respEn: the answer cards in the sky (juego.js respBox: centred at x, their top at y): screen, moved"
  },
  {
   "kind": "point",
   "old": [112, 182],
   "uses": ["cual-campo.json tu.si.set.gente.carmen", "cual-campo.json tu.no.set.gente.carmen"],
   "to": {
    "floor": [1.6862, 1.6862, 0]
   },
   "new": [120, 144],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a child's feet (x, y): the ground under them; moved (why)"
  },
  {
   "kind": "point",
   "old": [122, 178],
   "uses": ["cual-campo.json tira.si.set.gente.luis"],
   "to": {
    "floor": [3.5899, 3.4811, 0]
   },
   "new": [122, 178],
   "what": "a child's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [124, 178],
   "uses": ["cual-campo.json coge.no.set.gente.carmen"],
   "to": {
    "floor": [3.6443, 3.4267, 0]
   },
   "new": [124, 178],
   "what": "a child's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [124, 182],
   "uses": ["cual-campo.json tiene.si.set.perro", "cual-campo.json tiene.no.set.perro"],
   "to": {
    "floor": [3.8619, 3.6443, 0]
   },
   "new": [124, 182],
   "what": "Canelo's place (x, y): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [128, 184],
   "uses": ["cual-campo.json salta.no.set.perro"],
   "to": {
    "floor": [1.8494, 1.4142, 0]
   },
   "new": [128, 143],
   "moved": true,
   "why": "round 2, the pair salta (zoom 2): moved 0 px, -41 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "Canelo's place (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [137, 178],
   "uses": ["cual-campo.json bola.si.set.bolas.a", "cual-campo.json bola.no.set.flor"],
   "to": {
    "floor": [2.0397, 1.1151, 0]
   },
   "new": [137, 142],
   "moved": true,
   "why": "round 2, the pair bola (zoom 2): moved 0 px, -36 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [137, 186],
   "uses": ["cual-campo.json salta.si.set.perro"],
   "to": {
    "floor": [2.2029, 1.2782, 0]
   },
   "new": [137, 145],
   "moved": true,
   "why": "round 2, the pair salta (zoom 2): moved 0 px, -41 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "Canelo's place (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [138, 183],
   "uses": ["cual-campo.json tiene.si.set.bolas.a"],
   "to": {
    "floor": [4.297, 3.318, 0]
   },
   "new": [138, 183],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [138, 187],
   "uses": ["cual-campo.json salta.si.set.bolas.a"],
   "to": {
    "floor": [2.2845, 1.3054, 0]
   },
   "new": [138, 146],
   "moved": true,
   "why": "round 2, the pair salta (zoom 2): moved 0 px, -41 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [140, 184],
   "uses": ["cual-campo.json mi.no.set.bolas.b"],
   "to": {
    "floor": [2.5565, 1.0335, 0]
   },
   "new": [148, 146],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [142, 183],
   "uses": ["cual-campo.json tiene.no.set.bolas.a"],
   "to": {
    "floor": [4.4058, 3.2092, 0]
   },
   "new": [142, 183],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [143, 189],
   "uses": [
    "cual-campo.json más.si.set.bolas.a",
    "cual-campo.json más.no.set.bolas.a"
   ],
   "to": {
    "floor": [4.7594, 3.5083, 0]
   },
   "new": [143, 189],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [144, 153],
   "uses": ["cual-campo.json mi.si.set.cq", "cual-campo.json mi.no.set.cq"],
   "to": {
    "floor": [0.9791, -0.7615, 0]
   },
   "new": [152, 115],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "the frog's place q (x, y): the ground under (x + 16, y + 25); moved (why)"
  },
  {
   "kind": "point",
   "old": [146, 178],
   "uses": ["cual-campo.json tira.no.set.gente.luis"],
   "to": {
    "floor": [4.2426, 2.8284, 0]
   },
   "new": [146, 178],
   "what": "a child's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 178],
   "uses": ["cual-campo.json coge.si.set.gente.carmen"],
   "to": {
    "floor": [4.3514, 2.7196, 0]
   },
   "new": [150, 178],
   "what": "a child's feet (x, y): the ground under them; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 182],
   "uses": ["cual-campo.json dame.si.set.gente.carmen", "cual-campo.json dame.no.set.gente.carmen", "cual-campo.json tu.si.set.gente.luis", "cual-campo.json tu.no.set.gente.luis"],
   "to": {
    "floor": [2.7196, 0.6527, 0]
   },
   "new": [158, 144],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a child's feet (x, y): the ground under them; moved (why)"
  },
  {
   "kind": "point",
   "old": [152, 179],
   "uses": ["cual-campo.json tira.no.set.bolas.a"],
   "to": {
    "floor": [4.4602, 2.7196, 0]
   },
   "new": [152, 179],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [152, 184],
   "uses": ["cual-campo.json mi.si.set.bolas.b"],
   "to": {
    "floor": [2.8828, 0.7071, 0]
   },
   "new": [160, 146],
   "moved": true,
   "why": "round 2, the pair dame, mi or tu (zoom 2): moved 8 px, -38 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [155, 179],
   "uses": ["cual-campo.json coge.si.set.bolas.a"],
   "to": {
    "floor": [4.5418, 2.6381, 0]
   },
   "new": [155, 179],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [160, 187],
   "uses": ["cual-campo.json salta.no.set.bolas.a"],
   "to": {
    "floor": [2.8828, 0.7071, 0]
   },
   "new": [160, 146],
   "moved": true,
   "why": "round 2, the pair salta (zoom 2): moved 0 px, -41 rows up the lawn with the whole picture, so that it shows none of the tree's shadow (it lies on rows 154 to 182, left of x 131) and none of the tree",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [160, 188],
   "uses": [
    "cual-campo.json más.si.set.perro"
   ],
   "to": {
    "floor": [4.7594, 2.8556, 0]
   },
   "new": [155, 183],
   "moved": true,
   "why": "round 3: the pair más.si, Canelo sniffs at the ball: 8 px of lawn round his feet, no reed over him; 5 px, 5 rows",
   "what": "Canelo's place (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [168, 192],
   "uses": ["d-bola-canelo.json beats.27"],
   "to": {
    "floor": [4.5962, 2.5837, 0]
   },
   "new": [157, 179],
   "moved": true,
   "why": "round 2 and 3: d-bola-canelo beats.27, Canelo barking by the water: 8 px of lawn round his feet; 11 px, 11 rows, on the lawn",
   "what": "Canelo's place in a perro step of the picture story (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [172, 178],
   "uses": ["cual-campo.json tira.si.set.bolas.a", "cual-campo.json coge.no.set.bolas.a"],
   "to": {
    "floor": [4.9497, 2.1213, 0]
   },
   "new": [172, 178],
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place"
  },
  {
   "kind": "point",
   "old": [176, 176],
   "uses": ["d-bola-canelo.json beats.37"],
   "to": {
    "floor": [4.6234, 1.795, 0]
   },
   "new": [172, 172],
   "moved": true,
   "why": "round 3: d-bola-canelo beats.37, Canelo barking by Carmen: 8 px of lawn round his feet; 4 px, 4 rows",
   "what": "Canelo's place in a perro step of the picture story (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [176, 196],
   "uses": ["cual-campo.json arriba.no.set.bolas.a"],
   "to": {
    "floor": [6.5543, 3.1276, 0]
   },
   "new": [183, 202],
   "moved": true,
   "why": "round 2: the pair arriba.no, the big ball down in the reeds: it lay across the lip of the bank; 7 px, 6 rows into the water among the reeds (water all round it, its ring)",
   "what": "a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; moved (why)"
  },
  {
   "kind": "point",
   "old": [178, 197],
   "uses": [
    "cual-campo.json más.no.set.perro"
   ],
   "to": {
    "floor": [6.5815, 3.318, 0]
   },
   "new": [180, 204],
   "moved": true,
   "why": "the pair más.no: Canelo drinks at the water: at the old point (178, 197) the reeds stand in front of his head (the subject hidden); in the shallows down the shore from the reeds, wading as he drinks (his ring), as acts.aguanta (moves)",
   "what": "Canelo's place (x, y): the ground under it; moved (why)"
  },
  {
   "kind": "x",
   "old": [64],
   "uses": [
    "nivel.js NV arriba.p0"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [90],
   "uses": [
    "nivel.js NV arriba.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [114],
   "uses": [
    "nivel.js NV mi.p0"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [126],
   "uses": [
    "nivel.js NV mi.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [128],
   "uses": [
    "nivel.js NV tira.p2",
    "nivel.js NV coge.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [130],
   "uses": [
    "nivel.js NV tira.p3",
    "nivel.js NV mi.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [132],
   "uses": [
    "nivel.js NV tira.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [134],
   "uses": [
    "nivel.js NV tira.p0",
    "nivel.js NV coge.p1",
    "nivel.js NV mi.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [138],
   "uses": [
    "nivel.js NV coge.p0"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [176],
   "uses": [
    "nivel.js NV arriba.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "bola.si": {
   "world": [1.5774, 0.0544, 0],
   "screen": [148, 127],
   "zoom": 2,
   "crop": [99, 101, 98, 52],
   "what": "a ball on the grass, close"
  },
  "bola.no": {
   "world": [1.5774, 0.0544, 0],
   "screen": [148, 127],
   "zoom": 2,
   "crop": [99, 101, 98, 52],
   "what": "a flower there, close"
  },
  "tiene.si": {
   "world": [2.6924, 2.0941, 0],
   "screen": [131, 156],
   "zoom": 1,
   "crop": [33, 104, 196, 104],
   "what": "Canelo lies with the ball by him"
  },
  "tiene.no": {
   "world": [2.6924, 2.0941, 0],
   "screen": [131, 156],
   "zoom": 1,
   "crop": [33, 104, 196, 104],
   "what": "Canelo jumps, the ball in the air before him"
  },
  "tira.si": {
   "world": [2.8012, 1.1151, 0],
   "screen": [151, 148],
   "zoom": 1,
   "crop": [44, 96, 196, 104],
   "what": "Luis throws the ball: it flies away from him"
  },
  "tira.no": {
   "world": [2.8012, 1.1151, 0],
   "screen": [151, 148],
   "zoom": 1,
   "crop": [44, 96, 196, 104],
   "what": "Luis holds his hands up, the ball drops to him"
  },
  "coge.si": {
   "world": [2.8012, 1.1151, 0],
   "screen": [151, 148],
   "zoom": 1,
   "crop": [44, 96, 196, 104],
   "what": "Carmen catches the ball over her head"
  },
  "coge.no": {
   "world": [2.8012, 1.1151, 0],
   "screen": [151, 148],
   "zoom": 1,
   "crop": [44, 96, 196, 104],
   "what": "Carmen throws the ball away"
  },
  "salta.si": {
   "world": [1.2782, 0.2448, 0],
   "screen": [139, 126],
   "zoom": 2,
   "crop": [90, 100, 98, 52],
   "what": "Canelo jumps over the ball"
  },
  "salta.no": {
   "world": [1.2782, 0.2448, 0],
   "screen": [139, 126],
   "zoom": 2,
   "crop": [90, 100, 98, 52],
   "what": "Canelo runs, the ball before him"
  },
  "dame.si": {
   "world": [1.1694, 0.136, 0],
   "screen": [139, 124],
   "zoom": 2,
   "crop": [90, 98, 98, 52],
   "what": "Carmen holds out her hand, the frog has the ball"
  },
  "dame.no": {
   "world": [1.1694, 0.136, 0],
   "screen": [139, 124],
   "zoom": 2,
   "crop": [90, 98, 98, 52],
   "what": "Carmen has the ball"
  },
  "mi.si": {
   "world": [1.1422, 0.1632, 0],
   "screen": [138, 124],
   "zoom": 2,
   "crop": [89, 98, 98, 52],
   "what": "Luis points at himself, his ball in his hands"
  },
  "mi.no": {
   "world": [1.1422, 0.1632, 0],
   "screen": [138, 124],
   "zoom": 2,
   "crop": [89, 98, 98, 52],
   "what": "Luis points at the frog, his ball on the grass"
  },
  "tu.si": {
   "world": [1.1694, 0.136, 0],
   "screen": [139, 124],
   "zoom": 2,
   "crop": [90, 98, 98, 52],
   "what": "Carmen points at Luis"
  },
  "tu.no": {
   "world": [1.1694, 0.136, 0],
   "screen": [139, 124],
   "zoom": 2,
   "crop": [90, 98, 98, 52],
   "what": "Carmen points at herself"
  },
  "arriba.si": {
   "world": [-1.4686, 1.6862, 0],
   "screen": [62, 114],
   "zoom": 2,
   "crop": [13, 88, 98, 52],
   "what": "the big ball up in the tree, in its fork"
  },
  "arriba.no": {
   "world": [5.4393, 2.1757, 0],
   "screen": [180, 182],
   "zoom": 2,
   "crop": [131, 156, 98, 52],
   "what": "the big ball down in the reeds"
  },
  "abajo.si": {
   "world": [-0.5167, 1.1694, 0],
   "screen": [89, 118],
   "zoom": 1,
   "crop": [0, 66, 196, 104],
   "what": "the frog on the grass under the tree"
  },
  "abajo.no": {
   "world": [-0.5167, 1.1694, 0],
   "screen": [89, 118],
   "zoom": 1,
   "crop": [0, 66, 196, 104],
   "what": "the frog up in the tree's crown"
  },
  "mas.si": {
   "world": [3.4267, 2.2301, 0],
   "screen": [142, 164],
   "zoom": 1,
   "crop": [44, 112, 196, 104],
   "what": "Canelo sniffs at the ball, wet (zoom 1 with the trunk: round 2)"
  },
  "mas.no": {
   "world": [3.4267, 2.2301, 0],
   "screen": [142, 164],
   "zoom": 1,
   "crop": [44, 112, 196, 104],
   "what": "Canelo drinks at the water"
  }
 },
 "level": [
  {
   "w": "tira",
   "index": 0,
   "picture": "tira.si",
   "old": [101.8, 112, 64.39, 71.1],
   "crop": [44, 96, 196, 104],
   "zoom": 1
  },
  {
   "w": "tira",
   "index": 1,
   "picture": "tira.no",
   "old": [99.8, 112, 64.39, 71.1],
   "crop": [44, 96, 196, 104],
   "zoom": 1
  },
  {
   "w": "tira",
   "index": 2,
   "picture": "dame.si",
   "old": [100.83, 126, 54.34, 60],
   "crop": [90, 98, 98, 52],
   "zoom": 2
  },
  {
   "w": "tira",
   "index": 3,
   "picture": "tiene.si",
   "old": [102.83, 126, 54.34, 60],
   "crop": [33, 104, 196, 104],
   "zoom": 1
  },
  {
   "w": "coge",
   "index": 0,
   "picture": "coge.si",
   "old": [105.8, 112, 64.39, 71.1],
   "crop": [44, 96, 196, 104],
   "zoom": 1
  },
  {
   "w": "coge",
   "index": 1,
   "picture": "coge.no",
   "old": [101.8, 112, 64.39, 71.1],
   "crop": [44, 96, 196, 104],
   "zoom": 1
  },
  {
   "w": "coge",
   "index": 2,
   "picture": "dame.no",
   "old": [100.83, 126, 54.34, 60],
   "crop": [90, 98, 98, 52],
   "zoom": 2
  },
  {
   "w": "coge",
   "index": 3,
   "picture": "salta.si",
   "old": [119.48, 150, 36.05, 39.8],
   "crop": [90, 100, 98, 52],
   "zoom": 2
  },
  {
   "w": "arriba",
   "index": 0,
   "picture": "arriba.si",
   "old": [36.83, 84, 54.34, 60],
   "crop": [13, 88, 98, 52],
   "zoom": 2
  },
  {
   "w": "arriba",
   "index": 1,
   "picture": "arriba.no",
   "old": [148.83, 150, 54.34, 60],
   "crop": [131, 156, 98, 52],
   "zoom": 2
  },
  {
   "w": "arriba",
   "index": 2,
   "picture": "abajo.si",
   "old": [53.95, 78, 72.09, 79.6],
   "crop": [0, 66, 196, 104],
   "zoom": 1
  },
  {
   "w": "arriba",
   "index": 3,
   "picture": "salta.no",
   "old": [119.48, 150, 36.05, 39.8],
   "crop": [90, 100, 98, 52],
   "zoom": 2
  },
  {
   "w": "mi",
   "index": 0,
   "picture": "mi.si",
   "old": [86.83, 126, 54.34, 60],
   "crop": [89, 98, 98, 52],
   "zoom": 2
  },
  {
   "w": "mi",
   "index": 1,
   "picture": "mi.no",
   "old": [98.83, 126, 54.34, 60],
   "crop": [89, 98, 98, 52],
   "zoom": 2
  },
  {
   "w": "mi",
   "index": 2,
   "picture": "tira.si",
   "old": [101.8, 112, 64.39, 71.1],
   "crop": [44, 96, 196, 104],
   "zoom": 1
  },
  {
   "w": "mi",
   "index": 3,
   "picture": "tiene.si",
   "old": [102.83, 126, 54.34, 60],
   "crop": [33, 104, 196, 104],
   "zoom": 1
  }
 ],
 "clips": {},
 "clipsWhat": "campo.js never calls clip()",
 "front": {
  "how": "the old background (fondo: the tree, the reeds) was drawn before everyone; the reeds are a set thing someone (Canelo nosing in them, wading by them; a ball hidden in them) can be behind now. At its entry in the list campo.js draw sorts by y (line 107), after everyone, for each item drawn before it (a child, the frog, Canelo, a ball, the basket: each item says what it is), the set's own pixels of the reeds (campo-set.html part(\"juncos\"), PART_TAGS) are drawn again inside the item's box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under it (a child, Canelo, a ball, the basket: unproject(x, y - 1); the frog: unproject(b.x + b.w / 2, q.y + 25)); where that ground point is over the lake, v of the water's surface under it (v - waterDepth * sqrt(3)). \"Behind the reeds\" is that depth test, not a row. Nobody stands behind the tree (every place under it is in front of its trunk), so the tree is no front part",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "waterDepth": 0.16,
  "boxes": "a child: [x - 24, y - 46 - dy, 48, 49 + dy]; the frog: frogBox with dy; Canelo: [x - 16, y - 24 - dy, 32, 27 + dy]; a ball: [x - ceil(r) - 3, y - z - 2 ceil(r) - 4, 2 ceil(r) + 6, 2 ceil(r) + 6] (x, y, z: bolaXY), its ground point under (x, y - 1) with y its entry's sort y - .5; the basket: [x - 12, y - 20, 24, 21]",
  "parts": {
   "juncos": {
    "sortY": 9999,
    "insert": "before line 107's sort: L.push({y: 9999, front: \"juncos\"}) (after everyone)",
    "why": "whoever is behind reeds (Canelo nosing in them at 166, 198 and wading at 196, 204; a ball hidden in them at JUNCO) has the reeds nearer than them drawn over them: partly hidden, as being in the reeds is"
   }
  },
  "tags": [
   [
    "L.push({y:p.y,d:()=>gente(c,id,a)})",
    "L.push({y:p.y,id,d:()=>gente(c,id,a)})"
   ],
   [
    "L.push({y:W.perro.y,d:()=>perro(c,a)})",
    "L.push({y:W.perro.y,k:\"perro\",d:()=>perro(c,a)})"
   ],
   [
    "L.push({y:q.y+27,d:()=>rana(c,q,a)})",
    "L.push({y:q.y+27,id:\"coqui\",d:()=>rana(c,q,a)})"
   ],
   [
    "if(W.cesta)L.push({y:W.cesta[1],d:",
    "if(W.cesta)L.push({y:W.cesta[1],cesta:1,d:"
   ],
   [
    "L.push({y,d:()=>unaBola(c,o)})",
    "L.push({y,b:k,d:()=>unaBola(c,o)})"
   ],
   [
    "KIT.escena({id:\"campo\"",
    "window.CAMPO_BOLA={bolaXY,radio};KIT.escena({id:\"campo\""
   ]
  ],
  "tagsWhat": "each item of the sorted list says what it is (lines 100, 101, 102, 103, 104); the last pair only lets the preview read where a ball is (the port has bolaXY)"
 },
 "shadows": {
  "coqui": {
   "radius": 0.45,
   "at": "the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))",
   "when": "W.cq.vis and al > .5",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "nino": 0.3
   },
   "at": "the ground point under their feet on screen (unproject(x, y - 1))",
   "when": "visible (vis !== 0, al > .5)",
   "cast": "for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .3)"
  },
  "perro": {
   "radius": 0.32,
   "at": "the ground point under his feet on screen (unproject(x, y - 1))",
   "when": "W.perro shown (vis !== 0)",
   "cast": "castShadow(g.x, g.y, .25, .32): in the air too (a jump, dy > 0) his shadow stays on the ground under him (round 3: checked inside every picture)"
  },
  "cesta": {
   "radius": 0.36,
   "at": "the ground point under it (unproject(x, y - 1))",
   "when": "W.cesta",
   "cast": "castShadow(g.x, g.y, .2, .36)",
   "why": "the basket is the sprite layer's; its shadow seats it on the lawn"
  },
  "bola": {
   "radius": {
    "L": 0.27,
    "C": 0.21,
    "q": 0.19
   },
   "at": "the ground point under it on screen (unproject(x, y - 1)), x, y, z = bolaXY",
   "when": "a ball shown (vis !== 0), not carried (con), not floating (flota), not in the tree (z >= tree.z, |x - tree.x| <= tree.dx, y <= tree.y: in the crown), and not lying on the water (its point over the water and z <= 1: it has its ring, helps.ring)",
   "tree": {
    "x": 64,
    "dx": 14,
    "y": 152,
    "z": 24
   },
   "cast": "castShadow(g.x, g.y, radius[k], radius[k]): from the ball's middle as it lies there, so that it falls offset like every other shadow in the picture (round 3: round 2's z .05 lay right under it); a ball in the air keeps it on the ground under it",
   "why": "the brief: a ball in the air has its shadow on the ground; the old dark bar under a ball in the air is dropped (dropped)"
  },
  "dropped": "campo.js:96 the background: the set, for setKey(W); campo.js:85 rana(): the frog's dotted shadow; the engine casts his (shadows.coqui); campo.js:92 unaBola(): the dark bar under a ball in the air; the engine casts every ball's shadow on the ground under it, in the air or not (shadows.bola, as El patio's); campo.js:78 perro(): the dark bar under Canelo in the air; the engine casts his shadow on the ground under him (shadows.perro)"
 },
 "dropped": [
  {
   "line": 96,
   "src": "c.drawImage(spr(\"campo\",fondo),0,0);",
   "to": "",
   "why": "the background: the set, for setKey(W)"
  },
  {
   "line": 85,
   "src": "for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,\"#2E8A34\");",
   "to": "",
   "why": "rana(): the frog's dotted shadow; the engine casts his (shadows.coqui)"
  },
  {
   "line": 92,
   "src": "if(p[2]>3&&!o.con){c.globalAlpha=.3;fr(c,p[0]-R(r)+1,p[1]-1,R(r*2)-2,2,\"#103010\");c.globalAlpha=1;}",
   "to": "",
   "why": "unaBola(): the dark bar under a ball in the air; the engine casts every ball's shadow on the ground under it, in the air or not (shadows.bola, as El patio's)"
  },
  {
   "line": 78,
   "src": "if((o.dy||0)>3){c.globalAlpha=.3;fr(c,R(o.x)-9,R(o.y),18,2,\"#103010\");c.globalAlpha=1;}",
   "to": "",
   "why": "perro(): the dark bar under Canelo in the air; the engine casts his shadow on the ground under him (shadows.perro)"
  }
 ],
 "moves": [
  {
   "line": 187,
   "act": "inicio15",
   "src": "async inicio15(){W.gente=",
   "to": "async inicio15(){W.respEn=[132,32];W.gente=",
   "respEn": [132, 32],
   "why": "acts.inicio15 (la-bola, d-bola-canelo): the answer cards stand in the sky (W.respEn 132,32): over the frog at the field's middle they covered Luis (88, 178), the hand at a card reached his face; under the rounds card, right of the sun with their lit frames and glow, inside the view with 2 px to spare"
  },
  {
   "line": 228,
   "act": "inicio16",
   "src": "async inicio16(){W.gente=",
   "to": "async inicio16(){W.respEn=[132,32];W.gente=",
   "respEn": [132, 32],
   "why": "acts.inicio16 (arriba-abajo): the answer cards stand in the sky (W.respEn 132,32), as inicio15"
  },
  {
   "line": 292,
   "act": "inicio17",
   "src": "async inicio17(){W.gente=",
   "to": "async inicio17(){W.respEn=[132,32];W.gente=",
   "respEn": [132, 32],
   "why": "acts.inicio17 (otra-vez): the answer cards (three: tira, aguanta, da) stand in the sky (W.respEn 132,32): over the frog they ran over Luis's head and the tree's crown"
  },
  {
   "line": 317,
   "act": "*",
   "src": "await vuela(n,[168,206],22,8);",
   "to": "await vuela(n,[166,207],22,8);",
   "places": [
    {
     "who": "bola",
     "old": [168, 206],
     "new": [166, 207],
     "world": [6.364, 3.8619, 0]
    }
   ],
   "why": "acts.malA17 (otra-vez, wrong): the ball he throws lands at the water's edge, a little way off, and Canelo does not go after it. The old point (168, 206) was on the old pond's rim; here it lay across the lip of the bank: -2 px, 1 rows into the water at the edge, round 2 (water all round it, its ring: on the land every point near enough lay on Canelo or on the row of balls); Canelo then noses it back (vuelvefila) (the ball then rolls back to the row, vuelvefila, from where it lies)"
  },
  {
   "line": 326,
   "act": "*",
   "src": "await perroA(ORILLA[0]-10,ORILLA[1]+2,\"walk\");pe.dir=1;pe.pose=\"eat\";",
   "to": "await perroA(180,204,\"walk\");pe.dir=1;pe.pose=\"eat\";",
   "places": [
    {
     "who": "perro",
     "old": [180, 200],
     "new": [180, 204],
     "world": [6.5815, 3.318, 0]
    }
   ],
   "why": "acts.aguanta (otra-vez): Canelo goes down and drinks at the water's edge: at the old point (180, 200: ORILLA - 10, + 2) the reeds stand in front of his head; 0 px, 4 rows to the open bank down the shore from the reeds (the same place as the pair más.no's, remap)"
  },
  {
   "line": 156,
   "act": "*",
   "src": "d=[[196,205],[207,198],[200,212],[212,208]]",
   "to": "d=[[203,206],[202,191],[201,207],[170,207]]",
   "places": [
    {
     "who": "bola",
     "old": [196, 205],
     "new": [203, 206],
     "world": [7.3158, 2.8012, 0]
    },
    {
     "who": "bola",
     "old": [207, 198],
     "new": [202, 191],
     "world": [6.4727, 2.0125, 0]
    },
    {
     "who": "bola",
     "old": [200, 212],
     "new": [201, 207],
     "world": [7.3158, 2.91, 0]
    },
    {
     "who": "bola",
     "old": [212, 208],
     "new": [170, 207],
     "world": [6.4727, 3.7531, 0]
    }
   ],
   "why": "round 3: acts.alagua, the four places where a ball floats on the lake: 8 px and more inside the water, its ring on it, 6 px and more from the view's right and bottom edges (the old ones lay against them), apart where the old picture had them apart (the first and the fourth, the second and the third) and apart from the ball in the reeds (JUNCO)"
  },
  {
   "line": 298,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [
    {
     "who": "perro",
     "old": [164, 188],
     "new": [157, 177],
     "world": [4.4874, 2.4749, 0]
    }
   ],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 310,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 318,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 326,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 328,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 332,
   "act": "*",
   "src": "perroA(164,188,\"walk\"",
   "to": "perroA(157,177,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 164,188: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -7 px, -11 rows, on the lawn"
  },
  {
   "line": 296,
   "act": "*",
   "src": "perroA(160,190,\"walk\"",
   "to": "perroA(155,178,\"walk\"",
   "places": [
    {
     "who": "perro",
     "old": [160, 190],
     "new": [155, 178],
     "world": [4.4874, 2.5837, 0]
    }
   ],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 160,190: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -5 px, -12 rows, on the lawn"
  },
  {
   "line": 300,
   "act": "*",
   "src": "perroA(160,190,\"walk\"",
   "to": "perroA(155,178,\"walk\"",
   "places": [],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 160,190: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -5 px, -12 rows, on the lawn"
  },
  {
   "line": 319,
   "act": "*",
   "src": "perroA(150,192,\"walk\"",
   "to": "perroA(146,188,\"walk\"",
   "places": [
    {
     "who": "perro",
     "old": [150, 192],
     "new": [146, 188],
     "world": [4.7866, 3.3724, 0]
    }
   ],
   "why": "round 3: Canelo sits (or comes back to sit) by the water at 150,192: with the shore moved up the lawn his feet lay within 8 px of the lip of the bank; -4 px, -4 rows, on the lawn"
  },
  {
   "line": 298,
   "act": "*",
   "src": "perroA(FILA[i][0]+16,FILA[i][1]-4,\"walk\")",
   "to": "perroA(...(i===2?[155,178]:[FILA[i][0]+16,FILA[i][1]-4]),\"walk\")",
   "places": [],
   "why": "round 3: acts.alafila, Canelo by the small ball's place in the row (FILA[2] + 16, - 4 = 160, 190): as perroA(160, 190) (above); the other two places stay"
  },
  {
   "line": 310,
   "act": "*",
   "src": "perroA(FILA[i][0]+16,FILA[i][1]-4,\"run\")",
   "to": "perroA(...(i===2?[155,178]:[FILA[i][0]+16,FILA[i][1]-4]),\"run\")",
   "places": [],
   "why": "round 3: acts.tira17, as acts.alafila"
  },
  {
   "line": 324,
   "act": "*",
   "src": "perroA(FILA[2][0]+14,FILA[2][1]-4,\"walk\")",
   "to": "perroA(153,183,\"walk\")",
   "places": [
    {
     "who": "perro",
     "old": [158, 190],
     "new": [153, 183],
     "world": [4.705, 2.91, 0]
    }
   ],
   "why": "round 3: acts.empuja, Canelo noses the small ball in the row (FILA[2] + 14, - 4 = 158, 190): 8 px of lawn round his feet, the same place as perrotumba's"
  },
  {
   "line": 300,
   "act": "*",
   "src": "perroA(p[0]+16,p[1]-3,\"walk\")",
   "to": "perroA(...(p[0]+16>155?[155,178]:[p[0]+16,p[1]-3]),\"walk\")",
   "places": [
    {
     "who": "perro",
     "old": [160, 191],
     "new": [155, 178],
     "world": [4.4874, 2.5837, 0]
    }
   ],
   "why": "round 3: acts.perrocoge, Canelo picks a ball out of the row (16 px right of it, 3 rows up): for the small ball (144, 194) that is 160, 191, within 8 px of the lip of the bank: there he goes to his place by the water instead (as perroA(160, 190), above); the other two balls unchanged"
  },
  {
   "line": 269,
   "act": "*",
   "src": "await hopTo(160,166,3,1)",
   "to": "await hopTo(147,153,3,1)",
   "places": [
    {
     "who": "cq",
     "old": [160, 166],
     "new": [147, 153],
     "world": [4.7594, 2.4205, 0]
    }
   ],
   "why": "round 3: acts.busca (abajo), the frog hops down to look in the reeds: his feet (176, 191) lay over the water past the moved shore; -13 px, -13 rows, on the lawn above the reeds (8 px of lawn round his feet). The hop counts this changes are in hops (none of those pairs is walked in a recorded run)"
  },
  {
   "line": 284,
   "act": "*",
   "src": "mueve(\"luis\",150,194),mueve(\"carmen\",128,202)",
   "to": "mueve(\"luis\",147,191),mueve(\"carmen\",127,201)",
   "places": [
    {
     "who": "luis",
     "old": [150, 194],
     "new": [147, 191],
     "world": [4.9769, 3.5083, 0]
    },
    {
     "who": "carmen",
     "old": [128, 202],
     "new": [127, 201],
     "world": [4.9769, 4.5962, 0]
    }
   ],
   "why": "round 3: acts.final16 (none right): Luis and Carmen by the water: 8 px of lawn round their feet; Luis 3 px, 3 rows, Carmen 1 px, 1 row"
  },
  {
   "line": 50,
   "act": "*",
   "src": "JUNCO=[180,197]",
   "to": "JUNCO=[185,205]",
   "places": [
    {
     "who": "bola",
     "old": [180, 197],
     "new": [185, 205],
     "world": [6.7719, 3.2364, 0]
    },
    {
     "who": "bola",
     "old": [178, 199],
     "new": [183, 207],
     "world": [6.8263, 3.3996, 0]
    }
   ],
   "why": "round 2: JUNCO, where a ball hides in the reeds (ruedabajo, esconde16, sol: and sol's JUNCO - 2, + 2): the old point lay across the lip of the bank; 5 px, 8 rows out into the water among the reeds (water all round it, its ring; the reeds in front of it)"
  },
  {
   "line": 238,
   "act": "*",
   "src": "await mueve(\"luis\",ar?82:166,ar?166:194,null,1)",
   "to": "await mueve(\"luis\",ar?82:158,ar?166:186,null,1)",
   "places": [
    {
     "who": "luis",
     "old": [166, 194],
     "new": [158, 186],
     "world": [5.0041, 2.9372, 0]
    }
   ],
   "why": "round 2: acts.luisbusca, Luis looks in the reeds: his feet were 2 px from the lip of the bank; 1 px up and left, on the lawn"
  },
  {
   "line": 274,
   "act": "*",
   "src": "await perroA(166,198,\"run\");pe.pose=\"husmea\"",
   "to": "await perroA(153,183,\"run\");pe.pose=\"husmea\"",
   "places": [
    {
     "who": "perro",
     "old": [166, 198],
     "new": [153, 183],
     "world": [4.705, 2.91, 0]
    }
   ],
   "why": "round 2: acts.perrotumba, Canelo noses at the reeds: he stood across the lip of the bank; -13 px, -15 rows, on the lawn by the water"
  },
  {
   "line": 307,
   "act": "*",
   "src": "await perroA(ORILLA[0]-12,ORILLA[1]+2,\"run\")",
   "to": "await perroA(183,201,\"run\")",
   "places": [
    {
     "who": "perro",
     "old": [178, 200],
     "new": [183, 201],
     "world": [6.4999, 3.0732, 0]
    }
   ],
   "why": "round 2: acts.tira17, Canelo fetches the ball from the water: he stood across the lip of the bank (178, 200); 5 px, 1 rows into the water, wading (his ring)"
  },
  {
   "line": 333,
   "act": "*",
   "src": "await perroA(160,196,\"walk\");if(b){await vuela(\"cq\",[170,197],0,4,0);}",
   "to": "await perroA(149,182,\"walk\");if(b){await vuela(\"cq\",[159,183],0,4,0);}",
   "places": [
    {
     "who": "perro",
     "old": [160, 196],
     "new": [149, 182],
     "world": [4.5418, 2.9644, 0]
    },
    {
     "who": "bola",
     "old": [170, 197],
     "new": [159, 183],
     "world": [4.8682, 2.7468, 0]
    }
   ],
   "why": "round 2: acts.final17, Canelo lies down by the water with the small ball: both lay across the lip of the bank; Canelo -11 px, -14 rows, the ball -11 px, -14 rows, on the lawn"
  },
  {
   "line": 59,
   "act": "*",
   "src": "R(p.x)+d*(p.pose===\"offer\"?11:p.pose===\"arriba\"?4:6),R(p.y)+1,(p.pose===\"arriba\"?h+2:",
   "to": "R(p.x)+d*(p.pose===\"offer\"?11:p.pose===\"arriba\"?8:6),R(p.y)+1,(p.pose===\"arriba\"?h-3:",
   "why": "round 2 (point 4): manos(), a ball a child holds up over the head (pose arriba): in the raised hand (the sprite's raised fist, 6 to 9 px to the side the child faces, its top 39 rows over the feet: the ball 8 px to that side, its lowest row on the fist) instead of 4 px from the middle and 2 rows over the head, where it hung loose in the air (readers: \"the blue ball is in the air next to the trunk\", otra-vez 09 to 12, Carmen at 58, 198 in front of the trunk). A flight that ends in a child's raised hands (pasa, alta, acarmen) ends there too"
  }
 ],
 "helps": {
  "what": "drawn by the sprite layer just before the thing they help, 1:1, in the same sorted list (two lines added to campo.js, below): a ripple ring on the water round whatever floats or wades (a ball in the water, Canelo wading), so that a learner sees \"in the water\" (round 3: round 2's dark rim round the yellow ball is withdrawn)",
  "margin": 8,
  "edge": 6,
  "marginWhat": "round 3: whatever rests at the shore is on one side: on the land with at least this many px of lawn (not the bank's lip, its face or the water) round its foot (the lowest 2 rows of its sprite), or in the water with this many px of water all round its foot and its ring, the ring and the thing at least `edge` px from the view's right and bottom edges",
  "shore": "over the water: the ground point (z 0) under the screen point (x, y - 1) is past the shore: x > 5.7656 + .035 sin(2.3 y + 1) + .025 sin(5.1 y) (world x, y: pp-engine.js unproject)",
  "ring": {
   "inner": 0.45,
   "colour": [212, 236, 246],
   "ball": {
    "rx": 4,
    "ry": 2.5
   },
   "dog": {
    "rx": 15,
    "ry": 3.5,
    "dy": 1
   },
   "when": "a ball (not carried) that floats (o.flota) or lies over the water (bolaXY height <= 1 and its point over the water); Canelo, not in the air (dy <= 3), with his point over the water",
   "how": "every pixel (x, y) with .45 < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1 takes the colour: a ball's ring at cx = bolaXY x, cy = bolaXY y (a floating ball: + its bob, (F >> 3) % 2, as unaBola), rx = radio(k) + 4, ry = 2.5; Canelo's at cx = x, cy = y + 1, rx = 15, ry = 3.5"
  },
  "lines": [
   [
    "function unaBola(c,o){const p=bolaXY(o),r=radio(o.k),im=spr(\"bola\"+o.k,()=>mkBola(o.k));",
    "function unaBola(c,o){const p=bolaXY(o),r=radio(o.k),im=spr(\"bola\"+o.k,()=>mkBola(o.k));PREVIEW.under(c,o,p,r,im);"
   ],
   [
    "function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;",
    "function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;PREVIEW.wade(c,o);"
   ]
  ],
  "linesWhat": "the two lines campo.js gains (unaBola, perro): the help is drawn first, then the thing; the port draws them the same way"
 },
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as campo.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
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
  "what": "where a bubble goes (campo.js draw: line 108 for a child, 109 for the frog, 83 for Canelo). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible child's and the frog's, its own too); if none is, the first (the old)",
  "top": "a child: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2); Canelo: (x, y - 22)",
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
  "placesWhat": "[side, dy]: the tail's tip at (top.x + side * (h + 16), top.y + dy), h the head's half width: a child 6, the frog b.w >> 1, Canelo 8",
  "faces": "a child's face: [hx - 6, y - dy + top + 5, 12, 10] (eyes to chin, not the hair), hx the head's middle; the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heads": {
   "luis": {
    "top": -41,
    "head": 0
   },
   "carmen": {
    "top": -41,
    "head": 0
   }
  },
  "headsWhat": "each sprite (idle): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head + 1)",
  "board": [2, 2, 68, 26],
  "boardWhat": "in the 196 x 216 display, then + the view's x0: W.tarjeta (the rounds card) [2, 2, 68, 26]"
 },
 "code": [
  {
   "line": 15,
   "old": "ARBOL [60,152]; COPA [60,100,30,26]; HORQ [64,116]; SITIO [46,168]",
   "to": {
    "points": ["arbol", "copa", "horq", "sitio"]
   },
   "note": "the tree (points.arbol, copa, horq, sitio): its foot, the fork and Canelo's spot at their old screen points; the crown 2 px right, 3 px narrower"
  },
  {
   "line": 16,
   "old": "AGUA [232,228,74,54]; JUNCOS[] [170,201]; JUNCOS[] [184,190]; JUNCOS[] [198,182]; JUNCOS[] [211,177]",
   "to": {
    "dropped": "fondo"
   },
   "note": "dropped with the old background (fondo, and enAgua, which nothing calls): the lake's shore and the reed bed are the set's (layout.lines)"
  },
  {
   "line": 48,
   "old": "LUGAR.centro [120,150,1]; LUGAR.inicio [120,150,1]",
   "to": {
    "spots": ["frog.centro", "frog.inicio"]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 49,
   "old": "CASA.luis [88,178]; CASA.carmen [186,154]; PIES [136,196]; CESTA [104,208]; PILA[] [40,173]; PILA[] [52,174]; PILA[] [46,169]; PILA[] [46,177]",
   "to": {
    "spots": ["luis.casa", "carmen.casa", "bola.pies", "cesta", "pila.0", "pila.1", "pila.2", "pila.3"]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 50,
   "old": "FILA[] [112,194]; FILA[] [128,195]; FILA[] [144,194]; ORILLA [190,198]; JUNCO [180,197]",
   "to": {
    "spots": ["fila.0", "fila.1", "fila.2", "orilla", "junco"]
   },
   "note": "the floor rule: the same screen places"
  },
  {
   "line": 67,
   "old": "box [160,168,60,48]; hand [188,190]",
   "to": {
    "thing": "juncos"
   },
   "note": "the reeds' box and hand (things.juncos)"
  },
  {
   "line": 68,
   "old": "box [0,100,240,116]",
   "to": {
    "thing": "campo"
   },
   "note": "the field's box (things.campo)"
  },
  {
   "line": 74,
   "old": "c.scale(-1,1) args 0,1 [-1,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 79,
   "old": "c.scale(-1,1) args 0,1 [-1,1]; c.drawImage(im,-13,0) args 1,2 [-13,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 81,
   "old": "gotas(c,R(o.x)-11,R(o.y)-12,22,12,4) args 3,4 [22,12]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 86,
   "old": "ry [0,2.5,4,6]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 89,
   "old": "c.scale(2,2) args 0,1 [2,2]; bub(c,k,0,0,a) args 2,3 [0,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 91,
   "old": "c.drawImage(im,0,0,im.width,im.height-R(r*.7),p[0]-(im.width>>1),…,im.width,im.height-R(r*.7)) args 1,2 [0,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 96,
   "old": "c.drawImage(spr(\"_\",fondo),0,0) [sprite \"campo\"] args 1,2 [0,0]",
   "to": {
    "dropped": true
   },
   "note": "dropped: the set (dropped)"
  },
  {
   "line": 97,
   "old": "[] [-26,-10]; [] [24,-14]; [] [-18,14]; [] [22,10]; [] [0,-28]; [] [-14,-8]; [] [10,-14]; [] [20,-4]; [] [-4,-18]; point [190,186]",
   "to": "unchanged",
   "note": "relative to the old crown's middle (COPA) and to the reeds' 190, 186: unchanged (both in the new crown and bed)"
  },
  {
   "line": 105,
   "old": "[] [-3,-13]; [] [1,-13]; [] [-3,-9]; [] [1,-9]; [] [-1,-15]; [] [-1,-8]; [] [-4,-11]; [] [2,-11]",
   "to": "unchanged",
   "note": "the flower's own drawing, relative to W.flor: unchanged"
  },
  {
   "line": 110,
   "old": "c.fillRect(0,0,SW,SH) args 0,1 [0,0]",
   "to": "unchanged",
   "note": "the darkness of esconde16 over the whole picture, then the frog again: unchanged (setKey.bakedWhy)"
  },
  {
   "line": 115,
   "old": "[] [0,3,7,1]; [] [1,2,5,1]; [] [2,1,3,1]; [] [3,0,1,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 119,
   "old": "[] [0,0]; [] [-1,-1]; [] [-1,1]; [] [-2,-2]; [] [-2,2]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 120,
   "old": "flechita(x+37,y+10,1,0) args 2,3 [1,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 121,
   "old": "[] [9,10]; [] [27,10]; flechita(x+34,y+12,0,1) args 2,3 [0,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 122,
   "old": "g.scale(1,1.3) args 0,1 [1,1.3]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 123,
   "old": "g.scale(1.15,.65) args 0,1 [1.15,0.65]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 124,
   "old": "[] [13,0]; [] [25,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 125,
   "old": "g.drawImage(im,-10,-9) args 1,2 [-10,-9]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 126,
   "old": "[] [0,0]; [] [2,0]; [] [4,0]; [] [3,-1]; [] [3,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 130,
   "old": "tarjeta(g,3,3,66,24) args 1,2 [3,3]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 133,
   "old": "[] [1,3]; [] [5,1]; [] [9,1]; [] [13,3]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 134,
   "old": "[] [6,0,2,3]; [] [5,3,4,3]; [] [4,6,6,3]; [] [3,9,8,4]; [] [4,13,6,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 156,
   "old": "d[] [196,205]; d[] [207,198]; d[] [200,212]; d[] [212,208]; vuela(n,…,0,7,0) args 2,3 [0,7]; vuela(n,d,4,5,0) args 2,3 [4,5]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 159,
   "old": "vuela(\"_\",a,10,6,0) args 2,3 [10,6]; vuela(\"_\",PIES,10,6,0) args 2,3 [10,6]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 181,
   "old": "vuela(o.b||\"_\",PIES,4,4,0) args 2,3 [4,4]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 202,
   "old": "vuela(\"_\",…,3,4,0) args 2,3 [3,4]; vuela(\"_\",…,3,4,0) args 2,3 [3,4]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 206,
   "old": "vuela(\"_\",[lu.x-13,lu.y+5],3,4,0) args 2,3 [3,4]; vuela(\"_\",PIES,0,8,0) args 2,3 [0,8]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 207,
   "old": "vuela(\"_\",PIES,3,4,0) args 2,3 [3,4]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 210,
   "old": "vuela(\"_\",…,16,8) args 2,3 [16,8]; vuela(\"_\",\"_\",8,7,0) args 2,3 [8,7]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 211,
   "old": "vuela(\"_\",PIES,3,4,0) args 2,3 [3,4]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 213,
   "old": "vuela(\"_\",…,3,4,0) args 2,3 [3,4]; vuela(\"_\",…,3,4,0) args 2,3 [3,4]; vuela(\"_\",PIES,4,4,0) args 2,3 [4,4]; mueve(\"_\",166,160) args 1,2 [166,160]; mueve(\"_\",190,156) args 1,2 [190,156]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 217,
   "old": "vuela(\"_\",PIES,0,8,0) args 2,3 [0,8]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 225,
   "old": "pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]",
   "to": "unchanged",
   "note": "screen effect: the stars, unchanged"
  },
  {
   "line": 228,
   "old": "W.cesta [88,208]; x:,y: [92,170]; x:,y: [112,190]; x:,y: [46,178]; x:,y: [132,142]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 232,
   "old": "hopTo(52,138,2) args 0,1 [52,138]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 235,
   "old": "vuela(…) [104,190]; hopTo(50,140,2) args 0,1 [50,140]; vuela(\"_\",[104,190],8,7,0) args 2,3 [8,7]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 236,
   "old": "vuela(…) [150,196]; vuela(\"_\",[150,196],10,6,0) args 2,3 [10,6]; vuela(\"_\",…,0,7,0) args 2,3 [0,7]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 239,
   "old": "hopTo(44,138,2,1) args 0,1 [44,138]; vuela(\"_\",\"_\",4,7,0) args 2,3 [4,7]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 243,
   "old": "mueve(\"_\",74,204) args 1,2 [74,204]; hopTo(136,150,2,1) args 0,1 [136,150]; perroA(46,178,\"_\") args 0,1 [46,178]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 244,
   "old": "vuela(\"_\",\"_\",8,6,0) args 2,3 [8,6]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 245,
   "old": "hopTo(136,150,2,1) args 0,1 [136,150]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 246,
   "old": "vuela(\"_\",\"_\",8,6,0) args 2,3 [8,6]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 249,
   "old": "vuela(…) [178,186,30]; ranaSalta(16,8) args 0,1 [16,8]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 250,
   "old": "vuela(…) [176,190,0]; vuela(\"_\",…,0,10,0) args 2,3 [0,10]; ranaSalta(16,8) args 0,1 [16,8]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 252,
   "old": "vuela(\"_\",…,14,7,0) args 2,3 [14,7]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 254,
   "old": "vuela(\"_\",\"_\",8,6,0) args 2,3 [8,6]; hopTo(150,128,2) args 0,1 [150,128]; perroA(140,180,\"_\") args 0,1 [140,180]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 255,
   "old": "vuela(…) [176,190,0]; vuela(\"_\",[176,190,0],0,11,0) args 2,3 [0,11]; brinco(pe,14,8) args 1,2 [14,8]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 258,
   "old": "vuela(\"_\",\"_\",8,6,0) args 2,3 [8,6]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 259,
   "old": "vuela(\"_\",\"_\",30,9) args 2,3 [30,9]; brinco(ca,8,7) args 1,2 [8,7]; vuela(\"_\",\"_\",22,8) args 2,3 [22,8]; mueve(\"_\",74,204) args 1,2 [74,204]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 260,
   "old": "perroA(46,178,\"_\") args 0,1 [46,178]; hopTo(136,150,2) args 0,1 [136,150]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 263,
   "old": "x:,y: [136,136]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 268,
   "old": "vuela(…) [84,188]; hopTo(46,140,3,1) args 0,1 [46,140]; vuela(\"_\",[84,188],6,6,0) args 2,3 [6,6]; hopTo(70,160,1) args 0,1 [70,160]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 269,
   "old": "hopTo(160,166,3,1) args 0,1 [160,166]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 273,
   "old": "vuela(…) [98,188]; vuela(…) [150,196]; perroA(80,166,\"_\") args 0,1 [80,166]; brinco(pe,9,6) args 1,2 [9,6]; vuela(\"_\",[98,188],6,7,0) args 2,3 [6,7]; perroA(112,190,\"_\") args 0,1 [112,190]; vuela(\"_\",[150,196],10,7,0) args 2,3 [10,7]; perroA(160,196,\"_\") args 0,1 [160,196]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 274,
   "old": "vuela(…) [176,203]; perroA(166,198,\"_\") args 0,1 [166,198]; vuela(\"_\",[176,203],3,4,0) args 2,3 [3,4]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 277,
   "old": "vuela(\"_\",\"_\",12,7,0) args 2,3 [12,7]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 278,
   "old": "hopTo(136,136,3,1) args 0,1 [136,136]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 280,
   "old": "mueve(\"_\",104,180) args 1,2 [104,180]; mueve(\"_\",76,202) args 1,2 [76,202]; hopTo(136,136,2,1) args 0,1 [136,136]; perroA(50,196,\"_\") args 0,1 [50,196]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 281,
   "old": "vuela(\"_\",\"_\",8,6,0) args 2,3 [8,6]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 282,
   "old": "vuela(…) [156,186]; vuela(\"_\",…,50,12) args 2,3 [50,12]; vuela(\"_\",[156,186],56,12) args 2,3 [56,12]; vuela(\"_\",…,5,6,0) args 2,3 [5,6]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 284,
   "old": "mueve(\"_\",150,194) args 1,2 [150,194]; mueve(\"_\",128,202) args 1,2 [128,202]; hopTo(148,146,2,1) args 0,1 [148,146]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 285,
   "old": "mueve(\"_\",96,180) args 1,2 [96,180]; mueve(\"_\",168,176) args 1,2 [168,176]; hopTo(118,142,2,1) args 0,1 [118,142]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 287,
   "old": "pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]; ranaSalta(24,12) args 0,1 [24,12]",
   "to": "unchanged",
   "note": "screen effect: the stars, unchanged; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 289,
   "old": "brinco(lu,9,8) args 1,2 [9,8]; brinco(ca,9,8) args 1,2 [9,8]; ranaSalta(40,14) args 0,1 [40,14]; ranaSalta(40,14) args 0,1 [40,14]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 292,
   "old": "x:,y: [84,174]; x:,y: [58,198]; x:,y: [196,204]; x:,y: [112,140]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 294,
   "old": "mueve(\"_\",58,198) args 1,2 [58,198]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 296,
   "old": "perroA(160,190,\"_\") args 0,1 [160,190]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 298,
   "old": "perroA(164,188,\"_\") args 0,1 [164,188]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 300,
   "old": "perroA(160,190,\"_\") args 0,1 [160,190]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 302,
   "old": "vuela(n,FILA[i],4,5,0) args 2,3 [4,5]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 306,
   "old": "vuela(…) [176,186,22]; vuela(n,[176,186,22],26,9) args 2,3 [26,9]; perroA(168,188,\"_\") args 0,1 [168,188]; brinco(pe,16,5) args 1,2 [16,5]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 307,
   "old": "vuela(n,…,30,10) args 2,3 [30,10]",
   "to": "unchanged",
   "note": "not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 310,
   "old": "perroA(164,188,\"_\") args 0,1 [164,188]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 312,
   "old": "hopTo(112,140,2) args 0,1 [112,140]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 313,
   "old": "mueve(\"_\",84,174) args 1,2 [84,174]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 317,
   "old": "vuela(…) [168,206]; vuela(n,[168,206],22,8) args 2,3 [22,8]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 318,
   "old": "perroA(180,204,\"_\") args 0,1 [180,204]; vuela(n,FILA[i],0,10,0) args 2,3 [0,10]; perroA(164,188,\"_\") args 0,1 [164,188]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 319,
   "old": "perroA(150,192,\"_\",8) args 0,1 [150,192]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 322,
   "old": "hopTo(112,140,2) args 0,1 [112,140]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 323,
   "old": "mueve(\"_\",84,174) args 1,2 [84,174]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 326,
   "old": "perroA(164,188,\"_\") args 0,1 [164,188]; vuela(\"_\",FILA[2],4,4,0) args 2,3 [4,4]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 328,
   "old": "perroA(164,188,\"_\") args 0,1 [164,188]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 331,
   "old": "x:,y: [40,150]; mueve(\"_\",58,198) args 1,2 [58,198]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place"
  },
  {
   "line": 332,
   "old": "vuela(\"_\",FILA[2],0,9,0) args 2,3 [0,9]; perroA(164,188,\"_\") args 0,1 [164,188]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 333,
   "old": "vuela(…) [170,197]; perroA(160,196,\"_\") args 0,1 [160,196]; vuela(\"_\",[170,197],0,4,0) args 2,3 [0,4]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every place here (a child's feet, the frog's q, Canelo's, a ball's, the basket's) keeps its screen place; not a place: a flight's or a jump's height and steps"
  },
  {
   "line": 334,
   "old": "pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]",
   "to": "unchanged",
   "note": "screen effect: the stars, unchanged"
  },
  {
   "line": 342,
   "old": "CAM.wide [22,0,196,216]; heartAt [110,30]",
   "to": {
    "view": "wide",
    "point": "corazon"
   },
   "note": "the view (views.wide) and the heart (points.corazon): unchanged"
  },
  {
   "line": 66,
   "old": "box arbol [COPA[0]-COPA[2],COPA[1]-COPA[3],COPA[2]*2,COPA[3]*2+26] = [30,74,60,78]; hand [COPA[0],COPA[1]] = [60,100]",
   "to": {
    "thing": "arbol",
    "box": [34, 71, 55, 84],
    "hand": [60, 100]
   }
  },
  {
   "line": 67,
   "old": "box juncos [160,168,60,48]; hand [188,190]",
   "to": {
    "thing": "juncos",
    "box": [177, 140, 62, 51],
    "hand": [188, 190]
   }
  },
  {
   "line": 68,
   "old": "box campo [0,100,240,116]",
   "to": {
    "thing": "campo",
    "box": [0, 100, 240, 116]
   }
  },
  {
   "line": 52,
   "old": "caja(id): [x - 11, y - alto(id), 22, alto(id)]",
   "to": "relative to the child: unchanged"
  },
  {
   "line": 61,
   "old": "cajaBola: [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4]",
   "to": "relative to the ball: unchanged"
  },
  {
   "line": 64,
   "old": "perro box [x - 14, y - 20, 28, 22]; cesta box [x - 11, y - 16, 22, 18]",
   "to": "relative: unchanged"
  },
  {
   "line": 107,
   "old": "the sorted list",
   "to": {
    "front": ["juncos"]
   },
   "note": "one entry added before the sort (front.parts), each item tagged (front.tags)"
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: campo's fresh() puts him at LUGAR.inicio"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": "a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 10 things (old 10), 2 frog places of LUGAR (old 2) and 15 frog places in all, 1 view (old 1), 66 positions (old 66), 11 review pairs of cual-campo (22 pictures here; none is another scene's), 16 level pictures (old 16), 241 places of campo.js named in code, 1 baked state (the old 7)",
   "hops (round 3): the pairs whose count changed (the frog's place in acts.busca, abajo, moved: moves): bajoarbol-busca_abajo 4 -> 3, tumba-busca_abajo 4 -> 3, luisbusca-busca_abajo 4 -> 3, busca_arriba-busca_abajo 4 -> 3, busca_abajo-final16_si 2 -> 1, busca_abajo-inicio17 2 -> 1; none of them walked in a recorded run (the frog's walks between his places in the runs: busca_abajo-esconde16, busca_abajo-listos, busca_arriba-busca_baja, busca_arriba-esconde16, busca_baja-esconde16, busca_baja-final16_si, centro-inicio16, centro-inicio17, esconde16-final16_no, esconde16-final16_si, esconde16-listos, esconde16-tumba, inicio16-tumba, listos-turno16a)",
   "hops: all 91 pairs of the frog's 14 places (LUGAR and every place an act hops him to; round(d / 30), 1 to 4, kit.js acts.ir) keep the old count, but those listed in hops (below)",
   "boxes: every pixel of each set thing inside its touch box: arbol [34,71,55,84] (2545 px), juncos [177,140,62,51] (411 px) (still: no leaf or reed moves at any wind step); every pixel of each answers that thing in the hit order; the set's parts are arbol, juncos (each a touch key's: nothing decorative); the lake is the field's ground",
   "shadows: every castShadow call of the bake has strength 1 and a radius, each casting part darkens: arbol 48 calls, 2328 px set (0 calls wholly over shadow already); juncos 10 calls, 94 px set (0 calls wholly over shadow already); the reeds (thin) cast only contact shadows, every pixel within 2.24 px of a reed's foot",
   "ground: the lawn (the crown's shade one tone down on it), the bank's lip (105 px), the bank's face (344 px) and the water (2964 px); nothing else but the shadows the tree and the reeds cast (no patch of earth: round 3)",
   "water: 1894 px in the view, mean colour 64,132,161 (28 from the nearest sky band, CIE76), 10.8% of it ripples (baked) and 20 glints that come and go each frame (drawGlints, 8 steps a second, still when the OS asks); the bank's face (or the reeds standing on it) over the water at 85 of the 85 columns it reaches",
   "preview: at every moment of the 15 runs (8241 places of the children, the frog, Canelo, the balls and the cards) campo-preview.html puts everyone exactly where the sheet does (0 differ)",
   "asks: 44 distinct asks (for abajo, aguanta, arbol, arriba, bola_carmen, bola_cq, bola_luis, carmen, coge, da, di_abajo, di_coge, di_dame, di_mi, di_tu, juncos, luis, perro, salta, tira): every hint frame (box +- 12) inside the view with 2 px to spare (round 3; 2 px from its edge at the least), no frame's rings across a face where the old frame's were not (as the old: arriba-abajo right beats.23 (arbol) luis's face; la-bola right beats.22 (carmen) luis's face; la-bola right beats.25 (luis) carmen's face; la-bola right beats.25 (luis) the frog's face; la-bola right beats.50 (carmen) luis's face; la-bola wrong beats.50 (carmen) luis's face), the hint hand on no face; 64 answer cards, each with its lit frame and glow (+- 12) inside the view with 4 px to spare (round 3; 4 px at the least), over no one's body, no ball and not the tree",
   "sun: at 38,47, radius 9: under no corner card (437 shown, 10 px to spare at the least) and under no answer card with its frame and glow (64 cards, 3 px to spare at the least), at every moment and ask of every run",
   "bubbles: 64 bubbles at 1193 moments of 15 runs (arriba-abajo, d-bola-canelo, h-campo, la-bola, otra-vez), each its recorded one and anyone's \"amor\" when touched: wholly inside the view (12 px from its edge at the least), clear of the rounds card (55 px), on no face",
   "tree: its crown on the screen [34,71,88,154] (the old [30,74,90,126]), its trunk's foot at row 154 (the old 152), the hollow over the fork darker than the crown round it (lightness 30 against 48); at least 11 rows of lawn between anyone's feet and the trunk's foot behind them (arriba-abajo right beats.15.after.0: the frog at 50,140)",
   "shadows: each in one piece with its thing (arbol 258 px, juncos 29 px)",
   "sky: the sun at 38,47 (radius 9), left of the middle, whole in the view, nothing of the set within 2 px; the old picture's three clouds at 188,12; 204,34; 108,10 (the old 36,16; 112,9; 168,26), each clear of the sun, the crown and the corner card by 2 px",
   "ground: 54 distinct stands of the children, the frog, Canelo and the basket: nothing of the tree nearer than them inside their sprites; behind reeds (front.juncos draws them over): no one; in the water or the reeds, each where the old picture had them by the pond: perro at 196,204 in the water",
   "balls: 51 distinct balls at every moment and in every pair: on the ground with lawn (or the trodden earth) round them (100% of the ring at the least), at the water's edge on the land where the old picture had them on its pond's rim (cq at 159,183 (100% lawn round it)), in the air (3: their shadows, checked in the shore block), floating with water all round (100% at the least) and no reed over them, in the reeds partly hidden and at least half seen (-), in the tree with the crown behind them (100% at the least) and standing out from it (47 at the least, CIE76); no two loose balls overlap (Canelo's pile and the balls floating on the lake, as the old, not counted: the stories never ask for them)",
   "shore (round 3): 7020 ticks inside the acts of the 15 runs (every timer of the old page, played as the recorded runs), every step's end and every pair picture: 6020 rests near the shore (300 ms or more in one place, or a step's end), each clearly on one side (on the land with 8 px of lawn at least round its foot: luis at 158,186, perro at 153,183, carmen at 127,201, luis at 147,191, bola cq at 136,196, carmen at 168,180, bola cq at 144,194, perro at 146,188, bola cq at 159,183; in the water with water all round and its ring: bola juego at 185,205, bola flota0 at 203,206, bola juego at 183,207, bola flota1 at 202,191, bola flota2 at 201,207, bola flota3 at 170,207, perro at 183,201, perro at 180,204, perro at 196,204, bola luis at 166,207, bola a at 183,202); 3581 moments of something floating or wading, each with its ring (resting ones 100% on the water at the least); 2135 ticks of a ball or Canelo in the air, each with its shadow on the ground under it (cast as when it lies there), inside the picture (the view, or the pair's crop) and on ground that shows (40% of it at the least: no trunk or reed over it); whatever floats away from the view's right and bottom edges by 6 px at the least, and no two floating balls touching where the old picture had them apart (together, as the old: bola flota0/bola flota2)",
   "shade (round 3, point 2): the crown's shadow is one even shade, the lawn one tone down its own ramp (916 px, no pattern, no dither edge), joined to the trunk's shadow (11 px edge between them); the lit lawn 125,146,63, the shaded lawn 93,124,57; each thing against the lit / the shaded lawn (CIE76; keep 0.8): Luis's ball 51 / 51, Carmen's ball 69 / 62, the frog's ball 25 / 34, the flower 87 / 87, Canelo 34 / 35, the frog 31 / 33, Luis's dark hair 64 / 55, Carmen's dark hair 54 / 47",
   "balls on the lawn (round 3, point 5): each with only its ordinary cast shadow; at 23 places where a ball rests on the land, the ball against the 3 px band round it as drawn (CIE76), the least: C lit 64 (at 128,195), L lit 47 (at 160,146), q lit 26 (at 52,174); accepted (the frog's yellow ball against the old lawn: 50)",
   "water (round 3, point 1): the lake shows 2210 px in the view (1875 of them open water), the old pond 1675 (132%); its bank, one straight line along y, meets the view's right edge at row 169 and the bottom edge at x 124",
   "water (round 2 and 3, point 1): lighter and bluer than round 1 (CIE L*a*b* 52,-13,-22, round 1 41,-10,-19); against it (CIE76): the bank's lip 53, the frog's ball 75, Luis's 56, Canelo 60",
   "pairs, what differs: bola: bolas a, flor; tiene: bolas a, perro pose/dy; tira: luis x/pose, bolas a; coge: carmen x/pose, bolas a; salta: bolas a, perro x/y/dy/polvo; dame: bolas a; mi: luis pose, bolas a/b; tu: carmen pose, bolas b; arriba: bolas a, the window; abajo: cq x/y/s; mas: perro x/y/pose/dir",
   "pairs (round 2): the zoom 2 pictures show none of the tree's shadow without its trunk: bola.si, bola.no, salta.si, salta.no, dame.si, dame.no, mi.si, mi.no, tu.si, tu.no, arriba.si, arriba.no; in each picture Canelo whole with 2 px to spare and every ball's shadow inside it",
   "pairs: 22 review pictures (and the 16 level pictures, the same pictures): everyone, the frog, Canelo, the balls and the flower whole in their crop (no zoom 2 crop cuts what the old window did not), on clear ground",
   "lawn: El frente's grass (GRASS), mean colour 120,141,61 (hue 75; the old lawn 64,163,63); the sprite layer's things on it, by their mean colour against it (CIE76; keep 25), each with its dark outline and its cast shadow: Luis's ball 50 (the old 77), Carmen's ball 67 (the old 83), the frog's ball 25 (the old 50), Canelo 33 (the old 62), the basket 42 (the old 71), the flower's petals 86 (the old 113). The frog's small yellow ball is the nearest to the olive lawn by its mean colour (round 3: no help drawn for it, its weaker figure accepted; balls on the lawn, below)",
   "states: 1 baked state reached (every moment, pair and level picture)"
  ]
 }
}
''',
  'lago': r'''{
 "scene": "lago",
 "made": "node docs/proyecto/pixel/lago-sheet-make.js, from lago-set.html (window.LAGO_SET) and coqui/ref/escenas/lago/. Order 35a.",
 "S": 26,
 "origin": {
  "originX": 0,
  "originY": 4
 },
 "picture": [240, 216],
 "view": [196, 216],
 "pairPicture": [196, 104],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin (El camino's and El campo's); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]",
  "floor": "the lake and its dock are built round the old picture: a place keeps its screen place, and its world point is the walkable surface under it (lago-set.html surfaceAt): the dock's planks (z 0.28) where the deck or its landing is under the screen point at that height, else the lawn (z 0) on the land side of the shore, else the water's surface (z -0.16). A frog place q: under (q.x + 16, q.y + 25); a person's, Canelo's, a duck's, a bird's, a boat's, the bread's, the bag's, the sack's or the flower's place (x, y): under (x, y - 1). So every position of lago.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each one (spots, remap, code) with its world point",
  "relative": "what the old code draws or moves relative to a person, the frog, a duck, a bird, a boat or the fish (what is carried, the brush, the bread in a beak, a splash, a wake, the bubbles) keeps its offsets",
  "sky": "screen-space effects keep their old numbers: the stars of the happy endings (final18, final19, final20), the heart (heartAt), the birds' and the duck's circle in the sky (anima: 150 + 46 cos, 58 + 16 sin)",
  "view": "one view, zoom 1: the 196 x 216 window from x0 22, the old wide one",
  "pair": "a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2 (every old picture of cual-lago is a 113 x 60 or 100 x 53 window: about 2 x). The old rectangles (remap cam and crop) say which pictures they were"
 },
 "layout": {
  "what": "the park's lake seen nearer, on the world's axes at the engine's 30 degrees (shadows to screen right): the lawn (El frente's grass, calm, as El camino's and El campo's) up to the left of one straight shore along y; the lake (El campo's water: the same helper, colours, bank and glints) on its near side, filling the picture down and to the right; the dock running out from the shore along x over the water, its planks across it, on pilings, its landing on the lawn at its root; the post standing alone in the water past the dock's end; the reed bed in the shallows at the right, higher up the water than the old; El camino's hills and day sky over it, the sun upper left, the old picture's three clouds",
  "lines": {
   "shore": "x = 0.272 (screen sx + 2 sy = 354)",
   "deck": "x 0.212 to 3.25, y 1.32 to 5.22, z 0.28 (its underside 0.13); the landing x -0.45 to 0.222, y 3.82 to 5.22"
  },
  "why": "the brief and page 11 decision 9: the set stands on the world's axes; nothing is built square to the camera. The old picture had a horizontal far bank and a horizontal dock: neither can lie on a world axis. One straight shore along y keeps the old strip of lawn at the back on the left (Luis and Carmen sitting, Canelo) and the old left bank under the dock's root, and gives the lake more of the view than the old water had (water); the old far bank at the right becomes water, and what stood there moves onto the lawn up the shore (moves: Carmen of los-botes, the flower, the duck that climbs out, the bird of pájaro.si). The dock runs out from the shore along x; as every place on the old dock keeps its screen point (the frog, the children, the bag, the sack, the ducks that waddle onto it: on the screen a level row 100 px long), its deck is as wide as that row needs, on a world axis a row level on the screen runs across both axes. The post moved past the dock's end and the reeds higher up the water at the right: below them, before the dock's end, is where the ducks, the boats and the fish of the stories swim"
 },
 "behind": {
  "what": "nothing: the sun and the clouds are baked into the set's sky (El camino's and El campo's); every bird, flying or perched, is drawn in front of everything as the old (its sort y + 200)",
  "items": []
 },
 "setKey": {
  "params": {},
  "key": "\"lago\" (one baked state)",
  "baked": [
   {
    "key": "lago",
    "query": "?"
   }
  ],
  "bakedWhy": "order 06 found 10 states, made by five keys: bolsa (the bag of bread on the dock, mkBolsa), fila (how many pieces of bread lie in the row on the dock, mkPan), flor (the yellow flower), pincel (the brush the frog holds: drawn by rana()) and saco (the sack on the dock). Each is a thing drawn by the sprite layer (lago.js draw and rana()), none the day's light or the ground's, so they stay in the sprite layer as the old draws them (their places moved where moves says), and this one baked state draws all 10 (and every review and level picture)"
 },
 "things": {
  "luis": {
   "sprite": true,
   "why": "a child (today's sprite, drawn 1:1). caja(id) (lago.js:65): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged"
  },
  "carmen": {
   "sprite": true,
   "why": "as luis"
  },
  "pato_blanco": {
   "sprite": true,
   "why": "a duck (mkPato): [x - 12, y - 17 - dy, 24, 18] where it is (lago.js:68): unchanged"
  },
  "pato_negro": {
   "sprite": true,
   "why": "as pato_blanco"
  },
  "pato_amarillo": {
   "sprite": true,
   "why": "as pato_blanco (drawn at .78)"
  },
  "ave_blanco": {
   "sprite": true,
   "why": "a bird (mkPajaro): [x - 10, y - 15, 20, 18] (lago.js:69): unchanged"
  },
  "ave_negro": {
   "sprite": true,
   "why": "as ave_blanco"
  },
  "bote_rojo": {
   "sprite": true,
   "why": "a toy boat in the row on the dock (mkBote): [x - 10, y - 20, 20, 22] (lago.js:70): unchanged; the row's places moved (moves: FX, FYB)"
  },
  "bote_azul": {
   "sprite": true,
   "why": "as bote_rojo"
  },
  "bote_verde": {
   "sprite": true,
   "why": "as bote_rojo"
  },
  "pez": {
   "sprite": true,
   "why": "the fish (mkPez): [x - 11, y - 10 - dy, 22, 18]: unchanged"
  },
  "pajaro": {
   "sprite": true,
   "why": "the blue bird (mkPajaro): [x - 10, y - 15, 20, 18]: unchanged"
  },
  "perro": {
   "sprite": true,
   "why": "Canelo (KIT.mkPerro): [x - 14, y - 14, 28, 16]: unchanged"
  },
  "flor": {
   "sprite": true,
   "why": "the yellow flower (W.flor, drawn by lago.js draw): [x - 5, y - 16, 10, 17]: unchanged; its place moved onto the lawn (moves)"
  },
  "juncos": {
   "set": true,
   "world": [4.9497, 0.1632, 0, 5.7112, 0.9247, 0.7994],
   "box": [193, 140, 29, 33],
   "screen": [194, 141, 222, 173],
   "what": "the reeds: every stalk, head and blade of the bed in the shallows",
   "old": {
    "box": [178, 120, 40, 46]
   },
   "hintBox": [193, 140, 11, 33],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [199, 157],
   "handWhy": "the middle of its hint box"
  },
  "poste": {
   "set": true,
   "world": [3.9707, 1.4686, 0, 4.1882, 1.6862, 1.4212],
   "box": [162, 129, 8, 37],
   "screen": [162, 130, 170, 166],
   "what": "the post standing in the water",
   "old": {
    "box": [147, 120, 10, 36]
   },
   "hand": [166, 152],
   "handWhy": "on the post (the old: the middle of its box)"
  },
  "muelle": {
   "set": true,
   "world": [-0.3128, 1.5638, 0, 3.4675, 5.3441, 0.1554],
   "box": [16, 120, 139, 73],
   "screen": [16, 120, 155, 193],
   "what": "the dock: its deck, its edge, its pilings, its landing on the lawn and its two mooring posts",
   "old": {
    "box": [26, 150, 112, 17]
   },
   "hintBox": [36, 120, 119, 73],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [96, 160],
   "handWhy": "on the planks before the people's feet (the old: the middle of the old dock's box, 82, 158)"
  },
  "agua": {
   "set": true,
   "ground": true,
   "what": "the water: the lake from the shore to the picture's edges, under the horizon",
   "old": {
    "box": [0, 118, 240, 98]
   },
   "box": [0, 100, 240, 116],
   "world": null,
   "hintBox": [36, 100, 168, 102],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [176, 196],
   "handWhy": "on open water past the dock (the old: the middle of the old water, 120, 167, now on the dock)"
  },
  "lago": {
   "set": true,
   "ground": true,
   "what": "the lake and its lawn: everything under the horizon; last in the hit order",
   "old": {
    "box": [0, 94, 240, 122]
   },
   "box": [0, 100, 240, 116],
   "hintBox": [36, 100, 168, 102],
   "hintWhy": "hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches",
   "hand": [176, 196],
   "handWhy": "on open water past the dock"
  }
 },
 "spots": {
  "frog.inicio": {
   "world": [2.3011, 2.5186, 0.28],
   "on": "dock",
   "new": [100, 125],
   "scale": 1,
   "old": [100, 125],
   "what": "LUGAR.inicio: the frog on the dock"
  },
  "frog.muelle": {
   "world": [2.3011, 2.5186, 0.28],
   "on": "dock",
   "new": [100, 125],
   "scale": 1,
   "old": [100, 125],
   "what": "LUGAR.muelle: the frog on the dock"
  },
  "frog.inicio19": {
   "world": [1.2132, 3.6065, 0.28],
   "on": "dock",
   "new": [60, 125],
   "scale": 1,
   "old": [60, 125],
   "what": "the frog's place in acts.inicio19"
  },
  "frog.inicio20": {
   "world": [1.2676, 3.5521, 0.28],
   "on": "dock",
   "new": [62, 125],
   "scale": 1,
   "old": [62, 125],
   "what": "the frog's place in acts.inicio20"
  },
  "frog.ranapinta": {
   "world": [1.8659, 2.9538, 0.28],
   "on": "dock",
   "new": [84, 125],
   "scale": 1,
   "old": [84, 125],
   "what": "the frog's place in acts.ranapinta (Luis's x - 44)"
  },
  "frog.pequeno": {
   "world": [1.9203, 2.8994, 0.28],
   "on": "dock",
   "new": [86, 125],
   "scale": 1,
   "old": [86, 125],
   "what": "the frog's place in d-pato-pequeno beats.1"
  },
  "frog.ranaa": {
   "world": [2.4099, 2.4099, 0.28],
   "on": "dock",
   "new": [104, 125],
   "scale": 1,
   "old": [104, 125],
   "what": "the frog's place in acts.ranaa (d-pato-pequeno beats.37)"
  },
  "frog.hlago": {
   "world": [2.5186, 2.3011, 0.28],
   "on": "dock",
   "new": [108, 125],
   "scale": 1,
   "old": [108, 125],
   "what": "the frog's place in h-lago beats.1"
  },
  "luis.inicio18": {
   "world": [0.5061, 4.64, 0.28],
   "on": "dock",
   "new": [44, 154],
   "old": [44, 154],
   "what": "acts.inicio18: Luis sits on the dock (its landing), at its root"
  },
  "carmen.inicio18": {
   "world": [1.2676, 3.8785, 0.28],
   "on": "dock",
   "new": [72, 154],
   "old": [72, 154],
   "what": "acts.inicio18: Carmen on the dock, the bag in her hand"
  },
  "luis.inicio19": {
   "world": [2.7906, 2.3555, 0.28],
   "on": "dock",
   "new": [128, 154],
   "old": [128, 154],
   "what": "acts.inicio19: Luis at the dock's end"
  },
  "carmen.inicio19": {
   "world": [2.1757, -2.5021, 0],
   "on": "lawn",
   "new": [206, 110],
   "old": [196, 117],
   "moved": true,
   "what": "acts.inicio19: Carmen across the water (ORILLA + (18, 1))"
  },
  "luis.inicio20": {
   "world": [-0.9791, 1.523, 0],
   "on": "lawn",
   "new": [74, 118],
   "old": [74, 118],
   "what": "acts.inicio20: Luis sits on the lawn up the shore"
  },
  "carmen.inicio20": {
   "world": [2.3555, 2.7906, 0.28],
   "on": "dock",
   "new": [112, 154],
   "old": [112, 154],
   "what": "acts.inicio20: Carmen on the dock"
  },
  "perro": {
   "world": [-1.6862, 2.3389, 0],
   "on": "lawn",
   "new": [46, 119],
   "old": [46, 119],
   "what": "acts.inicio20: Canelo lies on the lawn"
  },
  "bolsa": {
   "world": [1.8659, 3.1714, 0.28],
   "on": "dock",
   "new": [96, 153],
   "old": [96, 153],
   "what": "acts.inicio20: the bag on the dock (W.bolsa)"
  },
  "saco": {
   "world": [2.2467, 2.7906, 0.28],
   "on": "dock",
   "new": [110, 153],
   "old": [110, 153],
   "what": "acts.inicio19: the sack on the dock (W.saco)"
  },
  "flor": {
   "world": [2.2301, -2.3389, 0],
   "on": "lawn",
   "new": [204, 112],
   "old": [196, 119],
   "moved": true,
   "what": "acts.inicio20: the yellow flower (W.flor)"
  },
  "pato.casa": {
   "world": [4.2643, 3.0676, -0.16],
   "on": "water",
   "new": [142, 184],
   "old": [142, 184],
   "what": "acts.inicio18, baja, alagua: the white duck's place on the water"
  },
  "pez.inicio18": {
   "world": [4.6994, 3.7203, -0.16],
   "on": "water",
   "new": [138, 194],
   "old": [92, 192],
   "moved": true,
   "what": "acts.inicio18: the fish, swimming to and fro"
  },
  "ave.poste": {
   "world": [2.0885, -0.4135, -0.16],
   "on": "water",
   "new": [166, 132],
   "old": [152, 122],
   "moved": true,
   "what": "POSTE[1] - 24: the bird on the post"
  },
  "ave.pm0": {
   "world": [-0.3642, 3.9872, 0.28],
   "on": "dock",
   "new": [40, 140],
   "old": [40, 140],
   "what": "PM[0] - 1: a bird on the left mooring post"
  },
  "ave.pm1": {
   "world": [2.1651, 1.458, 0.28],
   "on": "dock",
   "new": [133, 140],
   "old": [133, 140],
   "what": "PM[1] - 1: a bird on the right mooring post"
  },
  "bote.fila0": {
   "world": [0.5605, 4.5856, 0.28],
   "on": "dock",
   "new": [46, 154],
   "old": [46, 165],
   "moved": true,
   "what": "FX[0], FY: the first boat of the row on the dock"
  },
  "bote.fila1": {
   "world": [1.6484, 4.5856, 0.28],
   "on": "dock",
   "new": [66, 164],
   "old": [68, 165],
   "moved": true,
   "what": "FX[1], FY"
  },
  "bote.fila2": {
   "world": [2.709, 4.6128, 0.28],
   "on": "dock",
   "new": [85, 174],
   "old": [90, 165],
   "moved": true,
   "what": "FX[2], FY"
  },
  "sale.0": {
   "world": [3.8291, 2.1973, -0.16],
   "on": "water",
   "new": [150, 172],
   "old": [150, 172],
   "what": "SALE[0]: where a boat is set on the water"
  },
  "sale.1": {
   "world": [4.7538, 2.1429, -0.16],
   "on": "water",
   "new": [168, 180],
   "old": [168, 180],
   "what": "SALE[1]"
  },
  "sale.2": {
   "world": [4.8626, 3.122, -0.16],
   "on": "water",
   "new": [152, 190],
   "old": [152, 190],
   "what": "SALE[2]"
  },
  "pega.0": {
   "world": [4.3186, 0.4024, -0.16],
   "on": "water",
   "new": [192, 160],
   "old": [182, 166],
   "moved": true,
   "what": "PEGA[0]: where a drifting boat sticks in the reeds"
  },
  "pega.1": {
   "world": [3.9651, 0.3208, -0.16],
   "on": "water",
   "new": [187, 156],
   "old": [196, 172],
   "moved": true,
   "what": "PEGA[1]"
  },
  "pega.2": {
   "world": [4.6994, 0.5655, -0.16],
   "on": "water",
   "new": [196, 165],
   "old": [210, 168],
   "moved": true,
   "what": "PEGA[2]"
  },
  "pega.3": {
   "world": [4.2099, 0.7287, -0.16],
   "on": "water",
   "new": [184, 162],
   "old": [190, 178],
   "moved": true,
   "what": "PEGA[3]"
  },
  "pato.orilla.agua": {
   "world": [0.7287, 0.076, -0.16],
   "on": "water",
   "new": [132, 124],
   "old": [124, 126],
   "moved": true,
   "what": "acts.orilla: the duck at the shore"
  },
  "pato.orilla": {
   "world": [-0.6527, 0.3264, 0],
   "on": "lawn",
   "new": [102, 110],
   "old": [120, 118],
   "moved": true,
   "what": "acts.orilla: the duck out on the lawn"
  }
 },
 "lugar": {
  "inicio": {
   "spot": "frog.inicio",
   "q": [100, 125],
   "scale": 1,
   "old": [100, 125]
  },
  "muelle": {
   "spot": "frog.muelle",
   "q": [100, 125],
   "scale": 1,
   "old": [100, 125]
  }
 },
 "hops": [],
 "hopsWhat": "each pair of the frog's places (LUGAR and every place an act or a story puts him) whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all 21 pairs)",
 "hopsAll": [
  {
   "a": "inicio",
   "b": "inicio19",
   "old": 1,
   "new": 1,
   "dOld": 40,
   "dNew": 40
  },
  {
   "a": "inicio",
   "b": "inicio20",
   "old": 1,
   "new": 1,
   "dOld": 38,
   "dNew": 38
  },
  {
   "a": "inicio",
   "b": "ranapinta",
   "old": 1,
   "new": 1,
   "dOld": 16,
   "dNew": 16
  },
  {
   "a": "inicio",
   "b": "pequeno",
   "old": 1,
   "new": 1,
   "dOld": 14,
   "dNew": 14
  },
  {
   "a": "inicio",
   "b": "ranaa",
   "old": 1,
   "new": 1,
   "dOld": 4,
   "dNew": 4
  },
  {
   "a": "inicio",
   "b": "hlago",
   "old": 1,
   "new": 1,
   "dOld": 8,
   "dNew": 8
  },
  {
   "a": "inicio19",
   "b": "inicio20",
   "old": 0,
   "new": 0,
   "dOld": 2,
   "dNew": 2
  },
  {
   "a": "inicio19",
   "b": "ranapinta",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 24
  },
  {
   "a": "inicio19",
   "b": "pequeno",
   "old": 1,
   "new": 1,
   "dOld": 26,
   "dNew": 26
  },
  {
   "a": "inicio19",
   "b": "ranaa",
   "old": 1,
   "new": 1,
   "dOld": 44,
   "dNew": 44
  },
  {
   "a": "inicio19",
   "b": "hlago",
   "old": 2,
   "new": 2,
   "dOld": 48,
   "dNew": 48
  },
  {
   "a": "inicio20",
   "b": "ranapinta",
   "old": 1,
   "new": 1,
   "dOld": 22,
   "dNew": 22
  },
  {
   "a": "inicio20",
   "b": "pequeno",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 24
  },
  {
   "a": "inicio20",
   "b": "ranaa",
   "old": 1,
   "new": 1,
   "dOld": 42,
   "dNew": 42
  },
  {
   "a": "inicio20",
   "b": "hlago",
   "old": 2,
   "new": 2,
   "dOld": 46,
   "dNew": 46
  },
  {
   "a": "ranapinta",
   "b": "pequeno",
   "old": 0,
   "new": 0,
   "dOld": 2,
   "dNew": 2
  },
  {
   "a": "ranapinta",
   "b": "ranaa",
   "old": 1,
   "new": 1,
   "dOld": 20,
   "dNew": 20
  },
  {
   "a": "ranapinta",
   "b": "hlago",
   "old": 1,
   "new": 1,
   "dOld": 24,
   "dNew": 24
  },
  {
   "a": "pequeno",
   "b": "ranaa",
   "old": 1,
   "new": 1,
   "dOld": 18,
   "dNew": 18
  },
  {
   "a": "pequeno",
   "b": "hlago",
   "old": 1,
   "new": 1,
   "dOld": 22,
   "dNew": 22
  },
  {
   "a": "ranaa",
   "b": "hlago",
   "old": 1,
   "new": 1,
   "dOld": 4,
   "dNew": 4
  }
 ],
 "points": {
  "shore": {
   "screen": [
    [125, 115],
    [15, 170]
   ],
   "world": 0.272,
   "what": "the lake's shore: the line x = 0.272 (on the screen sx + 2 sy = 354), wavering a little as El campo's; the lawn on its far side (up to the left), the water on its near side, its surface 0.16 under the lawn"
  },
  "dock": {
   "world": [0.212, 1.32, 0.28, 3.25, 5.22, 0.28],
   "landing": [-0.45, 3.82, 0.222, 5.22],
   "screen": [
    [99.63, 119.78],
    [155.48, 147.7],
    [83.78, 183.55],
    [15.76, 149.54]
   ],
   "what": "the dock's deck: the planks at z 0.28 over x 0.212 to 3.25, y 1.32 to 5.22, and its landing on the lawn (landing: x0, y0, x1, y1); screen: its far corner, its right corner, its near corner, the landing's left corner"
  },
  "postes": {
   "screen": [
    [40, 141],
    [133, 141]
   ],
   "world": [
    [0.063, 4.4145, 0.54],
    [2.5923, 1.8852, 0.54]
   ],
   "old": [
    [40, 141],
    [133, 141]
   ],
   "what": "the two mooring posts on the deck (the old PM, where the birds perch): their tops at the old screen points, 0.26 over the planks"
  },
  "poste": {
   "screen": [166, 132],
   "foot": [166, 164],
   "world": [3.8835, 1.3814, 1.2612],
   "old": [152, 122],
   "what": "the post in the water: its top (where the bird perches: POSTE[1] - 24) and its foot at the water (POSTE[1] + 8): moved (moves)"
  },
  "corazon": {
   "screen": [110, 30],
   "old": [110, 30],
   "what": "heartAt: the heart of a happy ending, in the sky (unchanged)"
  },
  "sol": {
   "screen": [31, 47],
   "radius": 8,
   "what": "the sun: baked into the set's sky (El camino's and El campo's, in the same place: upper left, every shadow falls to the right), whole inside the view; no story touches it or names its place (the old sun was at the upper right)"
  },
  "nubes": {
   "screen": [
    [188, 12, 0.7],
    [204, 34, 0.8],
    [108, 10, 0.6]
   ],
   "old": [
    [36, 16, 1],
    [112, 9, 0.7],
    [168, 26, 0.8]
   ],
   "what": "the old picture's three clouds (engine.js sky()), baked into the set's sky as El campo's, clear of the corner card, the sun and the answer cards' place; no story names them"
  }
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 22,
   "world": [2.0669, 2.0669, 0],
   "region": null,
   "old": [22, 0, 196, 216],
   "what": "the lake: the lawn and the shore at the back and left, the dock from the shore, the water, the post, the reeds, the sky"
  }
 },
 "remap": [
  {
   "kind": "cam",
   "old": [44, 112, 113, 60],
   "uses": ["cual-lago.json pato.si.cam", "cual-lago.json pato.no.cam", "cual-lago.json vuela.no.cam", "cual-lago.json verde.si.cam", "cual-lago.json verde.no.cam"],
   "to": {
    "pictures": ["pato.si", "pato.no", "vuela.no", "verde.si", "verde.no"]
   },
   "crops": {
    "pato.si": {
     "crop": [51, 114, 98, 52],
     "zoom": 2
    },
    "pato.no": {
     "crop": [51, 114, 98, 52],
     "zoom": 2
    },
    "vuela.no": {
     "crop": [49, 114, 98, 52],
     "zoom": 2
    },
    "verde.si": {
     "crop": [49, 114, 98, 52],
     "zoom": 2
    },
    "verde.no": {
     "crop": [49, 114, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 84, 113, 60],
   "uses": [
    "cual-lago.json pájaro.si.cam"
   ],
   "to": {
    "pictures": ["pajaro.si"]
   },
   "crops": {
    "pajaro.si": {
     "crop": [142, 76, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [84, 116, 100, 53.1],
   "uses": ["cual-lago.json blanco.si.cam", "cual-lago.json blanco.no.cam"],
   "to": {
    "pictures": ["blanco.si", "blanco.no"]
   },
   "crops": {
    "blanco.si": {
     "crop": [84, 104, 98, 52],
     "zoom": 2
    },
    "blanco.no": {
     "crop": [84, 104, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [96, 30, 113, 60],
   "uses": ["cual-lago.json nada.no.cam", "cual-lago.json vuela.si.cam"],
   "to": {
    "pictures": ["nada.no", "vuela.si"]
   },
   "crops": {
    "nada.no": {
     "crop": [101, 30, 98, 52],
     "zoom": 2
    },
    "vuela.si": {
     "crop": [103, 30, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "cam",
   "old": [100, 156, 113, 60],
   "uses": [
    "cual-lago.json pez.si.cam",
    "cual-lago.json pez.no.cam",
    "cual-lago.json pájaro.no.cam",
    "cual-lago.json nada.si.cam",
    "cual-lago.json rojo.si.cam",
    "cual-lago.json rojo.no.cam",
    "cual-lago.json azul.si.cam",
    "cual-lago.json azul.no.cam",
    "cual-lago.json amarillo.si.cam",
    "cual-lago.json amarillo.no.cam",
    "cual-lago.json negro.si.cam",
    "cual-lago.json negro.no.cam"
   ],
   "to": {
    "pictures": ["pez.si", "pez.no", "pajaro.no", "nada.si", "rojo.si", "rojo.no", "azul.si", "azul.no", "amarillo.si", "amarillo.no", "negro.si", "negro.no"]
   },
   "crops": {
    "pez.si": {
     "crop": [107, 158, 98, 52],
     "zoom": 2
    },
    "pez.no": {
     "crop": [107, 158, 98, 52],
     "zoom": 2
    },
    "pajaro.no": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "nada.si": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "rojo.si": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "rojo.no": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "azul.si": {
     "crop": [101, 158, 98, 52],
     "zoom": 2
    },
    "azul.no": {
     "crop": [101, 158, 98, 52],
     "zoom": 2
    },
    "amarillo.si": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "amarillo.no": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "negro.si": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    },
    "negro.no": {
     "crop": [101, 154, 98, 52],
     "zoom": 2
    }
   }
  },
  {
   "kind": "crop",
   "old": [68.83, 112, 54.34, 60],
   "uses": [
    "nivel.js NV vuela.p1",
    "nivel.js NV rojo.p2"
   ],
   "to": {
    "pictures": ["vuela.no", "verde.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [72.83, 112, 54.34, 60],
   "uses": [
    "nivel.js NV pato.p0",
    "nivel.js NV pato.p1"
   ],
   "to": {
    "pictures": ["pato.si", "pato.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [108.95, 116, 48.09, 53.1],
   "uses": [
    "nivel.js NV negro.p3"
   ],
   "to": {
    "pictures": ["blanco.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [122.83, 156, 54.34, 60],
   "uses": [
    "nivel.js NV vuela.p2",
    "nivel.js NV rojo.p0",
    "nivel.js NV rojo.p1",
    "nivel.js NV rojo.p3",
    "nivel.js NV negro.p0",
    "nivel.js NV negro.p1",
    "nivel.js NV negro.p2"
   ],
   "to": {
    "pictures": ["nada.si", "rojo.si", "rojo.no", "azul.si", "negro.si", "negro.no", "amarillo.no"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [124.83, 30, 54.34, 60],
   "uses": [
    "nivel.js NV vuela.p0"
   ],
   "to": {
    "pictures": ["vuela.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [128.83, 156, 54.34, 60],
   "uses": [
    "nivel.js NV pato.p2",
    "nivel.js NV vuela.p3"
   ],
   "to": {
    "pictures": ["pez.si"],
    "level": true
   }
  },
  {
   "kind": "crop",
   "old": [148.83, 156, 54.34, 60],
   "uses": [
    "nivel.js NV pato.p3"
   ],
   "to": {
    "pictures": ["pajaro.no"],
    "level": true
   }
  },
  {
   "kind": "point",
   "old": [0, 0],
   "uses": [
    "cual-lago.json pato.si.set.cq",
    "cual-lago.json pato.no.set.cq",
    "cual-lago.json pez.si.set.cq",
    "cual-lago.json pez.no.set.cq",
    "cual-lago.json pájaro.si.set.cq",
    "cual-lago.json pájaro.no.set.cq",
    "cual-lago.json nada.si.set.cq",
    "cual-lago.json nada.no.set.cq",
    "cual-lago.json vuela.si.set.cq",
    "cual-lago.json vuela.no.set.cq",
    "cual-lago.json rojo.si.set.cq",
    "cual-lago.json rojo.no.set.cq",
    "cual-lago.json azul.si.set.cq",
    "cual-lago.json azul.no.set.cq",
    "cual-lago.json verde.si.set.cq",
    "cual-lago.json verde.no.set.cq",
    "cual-lago.json amarillo.si.set.cq",
    "cual-lago.json amarillo.no.set.cq",
    "cual-lago.json blanco.si.set.cq",
    "cual-lago.json blanco.no.set.cq",
    "cual-lago.json negro.si.set.cq",
    "cual-lago.json negro.no.set.cq"
   ],
   "to": {
    "none": true
   },
   "what": "the frog out of the picture (vis 0) in a review picture: not a place"
  },
  {
   "kind": "point",
   "old": [42, 154],
   "uses": ["d-pato-pequeno.json beats.1.set.gente.carmen"],
   "to": {
    "dock": [0.4517, 4.6944, 0.28]
   },
   "new": [42, 154],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [58, 153],
   "uses": ["d-pato-pequeno.json beats.1.set.bolsa"],
   "to": {
    "dock": [0.8325, 4.2048, 0.28]
   },
   "new": [58, 153],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [64, 118],
   "uses": ["h-lago.json beats.1.set.gente.carmen"],
   "to": {
    "lawn": [-1.251, 1.795, 0]
   },
   "new": [64, 118],
   "what": "a place (x, y): the surface under (x, y - 1): lawn; the same screen place"
  },
  {
   "kind": "point",
   "old": [86, 125],
   "uses": ["d-pato-pequeno.json beats.1.set.cq"],
   "to": {
    "dock": [1.9203, 2.8994, 0.28]
   },
   "new": [86, 125],
   "what": "the frog's place q (x, y): the surface under (x + 16, y + 25): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [96, 118],
   "uses": ["d-pato-pequeno.json beats.1.set.gente.luis", "h-lago.json beats.1.set.gente.luis"],
   "to": {
    "lawn": [-0.9247, 0.9247, 0]
   },
   "new": [86, 113],
   "moved": true,
   "why": "d-pato-pequeno and h-lago beats.1: Luis sits on the lawn up the shore: 8 px of lawn round him, clear of the dock's far corner (the bank is nearer here than the old far bank was); 10 px left, 5 rows up",
   "what": "a place (x, y): the surface under (x, y - 1): lawn; moved (why)"
  },
  {
   "kind": "point",
   "old": [96, 153],
   "uses": ["cual-lago.json verde.si.set.botes.a", "cual-lago.json verde.no.set.botes.a"],
   "to": {
    "dock": [1.8659, 3.1714, 0.28]
   },
   "new": [96, 153],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [96, 154],
   "uses": ["cual-lago.json vuela.no.set.aves.a"],
   "to": {
    "dock": [1.9203, 3.2257, 0.28]
   },
   "new": [96, 154],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [100, 154],
   "uses": ["cual-lago.json pato.si.set.patos.a", "cual-lago.json pato.no.set.aves.a"],
   "to": {
    "dock": [2.0291, 3.117, 0.28]
   },
   "new": [100, 154],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [104, 125],
   "uses": ["d-pato-pequeno.json beats.37"],
   "to": {
    "dock": [2.4099, 2.4099, 0.28]
   },
   "new": [104, 125],
   "what": "the frog's place q (x, y): the surface under (x + 16, y + 25): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [104, 172],
   "uses": ["d-pato-pequeno.json beats.33"],
   "to": {
    "water": [4.2099, 4.2099, -0.16]
   },
   "new": [120, 194],
   "moved": true,
   "why": "d-pato-pequeno beats.33 (patoa): the old point is under the new deck; in front of the dock's near corner, water all round",
   "what": "a place (x, y): the surface under (x, y - 1): water; moved (why)"
  },
  {
   "kind": "point",
   "old": [108, 125],
   "uses": ["h-lago.json beats.1.set.cq"],
   "to": {
    "dock": [2.5186, 2.3011, 0.28]
   },
   "new": [108, 125],
   "what": "the frog's place q (x, y): the surface under (x + 16, y + 25): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [124, 176],
   "uses": ["d-pato-pequeno.json beats.34"],
   "to": {
    "water": [4.373, 3.394, -0.16]
   },
   "new": [138, 188],
   "moved": true,
   "why": "d-pato-pequeno beats.34 (patoa): the old point is at the new deck's end; past it, water all round",
   "what": "a place (x, y): the surface under (x, y - 1): water; moved (why)"
  },
  {
   "kind": "point",
   "old": [133, 140],
   "uses": ["cual-lago.json blanco.si.set.aves.a", "cual-lago.json blanco.no.set.aves.a"],
   "to": {
    "dock": [2.1651, 1.458, 0.28]
   },
   "new": [133, 140],
   "what": "a place (x, y): the surface under (x, y - 1): dock; the same screen place"
  },
  {
   "kind": "point",
   "old": [140, 119],
   "uses": [
    "cual-lago.json pájaro.si.set.aves.a"
   ],
   "to": {
    "lawn": [2.2301, -2.5565, 0]
   },
   "new": [208, 110],
   "moved": true,
   "why": "the pair pájaro.si: the bird with the crust stood on the old far bank (140, 119), open water here: on the right bank (round 3)",
   "what": "a place (x, y): the surface under (x, y - 1): lawn; moved (why)"
  },
  {
   "kind": "point",
   "old": [143, 184],
   "uses": [
    "cual-lago.json pájaro.no.set.pan"
   ],
   "to": {
    "water": [4.2914, 3.0404, -0.16]
   },
   "new": [143, 184],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 62],
   "uses": ["cual-lago.json nada.no.set.patos.a"],
   "to": {
    "lawn": [-1.9581, -3.5899, 0]
   },
   "new": [150, 62],
   "what": "a place (x, y): the surface under (x, y - 1): lawn; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 188],
   "uses": ["cual-lago.json nada.si.set.patos.a"],
   "to": {
    "water": [4.6994, 3.0676, -0.16]
   },
   "new": [150, 188],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 190],
   "uses": ["cual-lago.json rojo.si.set.botes.a", "cual-lago.json rojo.no.set.botes.a", "cual-lago.json amarillo.si.set.patos.a", "cual-lago.json amarillo.no.set.patos.a", "cual-lago.json negro.si.set.patos.a", "cual-lago.json negro.no.set.patos.a"],
   "to": {
    "water": [4.8082, 3.1764, -0.16]
   },
   "new": [150, 190],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [150, 192],
   "uses": ["cual-lago.json azul.si.set.peces.a", "cual-lago.json azul.no.set.peces.a"],
   "to": {
    "water": [4.917, 3.2852, -0.16]
   },
   "new": [150, 192],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [152, 60],
   "uses": ["cual-lago.json vuela.si.set.aves.a"],
   "to": {
    "lawn": [-2.0125, -3.7531, 0]
   },
   "new": [152, 60],
   "what": "a place (x, y): the surface under (x, y - 1): lawn; the same screen place"
  },
  {
   "kind": "point",
   "old": [152, 122],
   "uses": ["h-lago.json beats.14.set.aves.a"],
   "to": {
    "water": [2.0885, -0.4135, -0.16]
   },
   "new": [166, 132],
   "moved": true,
   "why": "h-lago beats.14: the bird on the post (POSTE[1] - 24): the post moved (moves)",
   "what": "a place (x, y): the surface under (x, y - 1): water; moved (why)"
  },
  {
   "kind": "point",
   "old": [152, 178],
   "uses": ["d-pato-pequeno.json beats.39"],
   "to": {
    "water": [4.2099, 2.4693, -0.16]
   },
   "new": [152, 178],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [156, 186],
   "uses": [
    "cual-lago.json pájaro.no.set.peces.a"
   ],
   "to": {
    "water": [4.7538, 2.7956, -0.16]
   },
   "new": [156, 186],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [156, 190],
   "uses": ["cual-lago.json pez.no.set.patos.a"],
   "to": {
    "water": [4.9714, 3.0132, -0.16]
   },
   "new": [156, 190],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [156, 196],
   "uses": ["cual-lago.json pez.si.set.peces.a"],
   "to": {
    "water": [5.2977, 3.3396, -0.16]
   },
   "new": [156, 196],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [164, 200],
   "uses": ["d-pato-pequeno.json beats.23"],
   "to": {
    "water": [5.7329, 3.3396, -0.16]
   },
   "new": [164, 200],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [178, 184],
   "uses": ["d-pato-pequeno.json beats.19"],
   "to": {
    "water": [5.2433, 2.0885, -0.16]
   },
   "new": [178, 184],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "point",
   "old": [192, 192],
   "uses": ["h-lago.json beats.14.set.peces.a"],
   "to": {
    "water": [6.0592, 2.1429, -0.16]
   },
   "new": [192, 192],
   "what": "a place (x, y): the surface under (x, y - 1): water; the same screen place"
  },
  {
   "kind": "x",
   "old": [96],
   "uses": [
    "nivel.js NV vuela.p1",
    "nivel.js NV rojo.p2"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [100],
   "uses": [
    "nivel.js NV pato.p0",
    "nivel.js NV pato.p1"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [133],
   "uses": [
    "nivel.js NV negro.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [150],
   "uses": [
    "nivel.js NV vuela.p2",
    "nivel.js NV rojo.p0",
    "nivel.js NV rojo.p1",
    "nivel.js NV rojo.p3",
    "nivel.js NV negro.p0",
    "nivel.js NV negro.p1",
    "nivel.js NV negro.p2"
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
    "nivel.js NV vuela.p0"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [156],
   "uses": [
    "nivel.js NV pato.p2",
    "nivel.js NV vuela.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  },
  {
   "kind": "x",
   "old": [176],
   "uses": [
    "nivel.js NV pato.p3"
   ],
   "to": {
    "level": true,
    "what": "a level crop's centre x: the level pictures take pictures[...] whole (level[])"
   }
  }
 ],
 "pictures": {
  "pato.si": {
   "world": [1.322, 2.4099, 0.28],
   "screen": [100, 140],
   "zoom": 2,
   "crop": [51, 114, 98, 52],
   "what": "a duck walking on the dock"
  },
  "pato.no": {
   "world": [1.322, 2.4099, 0.28],
   "screen": [100, 140],
   "zoom": 2,
   "crop": [51, 114, 98, 52],
   "what": "a bird on the dock"
  },
  "pez.si": {
   "world": [4.6994, 2.7413, -0.16],
   "screen": [156, 184],
   "zoom": 2,
   "crop": [107, 158, 98, 52],
   "what": "a fish leaping from the water"
  },
  "pez.no": {
   "world": [4.6994, 2.7413, -0.16],
   "screen": [156, 184],
   "zoom": 2,
   "crop": [107, 158, 98, 52],
   "what": "a duck on the water, eating"
  },
  "pajaro.si": {
   "world": [1.6318, -2.7196, 0],
   "screen": [200, 102],
   "zoom": 2,
   "crop": [142, 76, 98, 52],
   "what": "a bird with a crust, on the lawn by the water"
  },
  "pajaro.no": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "a fish under the water by a crust"
  },
  "nada.si": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "a duck swimming"
  },
  "nada.no": {
   "world": [-2.2301, -3.8619, 0],
   "screen": [150, 56],
   "zoom": 2,
   "crop": [101, 30, 98, 52],
   "what": "a duck flying"
  },
  "vuela.si": {
   "world": [-2.1757, -3.9163, 0],
   "screen": [152, 56],
   "zoom": 2,
   "crop": [103, 30, 98, 52],
   "what": "a bird flying"
  },
  "vuela.no": {
   "world": [1.2676, 2.4642, 0.28],
   "screen": [98, 140],
   "zoom": 2,
   "crop": [49, 114, 98, 52],
   "what": "a bird on the dock with a crust"
  },
  "rojo.si": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "a red boat on the water"
  },
  "rojo.no": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "a blue boat on the water"
  },
  "azul.si": {
   "world": [4.5362, 2.9044, -0.16],
   "screen": [150, 184],
   "zoom": 2,
   "crop": [101, 158, 98, 52],
   "what": "a blue fish"
  },
  "azul.no": {
   "world": [4.5362, 2.9044, -0.16],
   "screen": [150, 184],
   "zoom": 2,
   "crop": [101, 158, 98, 52],
   "what": "a green fish"
  },
  "verde.si": {
   "world": [1.2676, 2.4642, 0.28],
   "screen": [98, 140],
   "zoom": 2,
   "crop": [49, 114, 98, 52],
   "what": "a green boat on the dock"
  },
  "verde.no": {
   "world": [1.2676, 2.4642, 0.28],
   "screen": [98, 140],
   "zoom": 2,
   "crop": [49, 114, 98, 52],
   "what": "a red boat on the dock"
  },
  "amarillo.si": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "the yellow duck"
  },
  "amarillo.no": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "the white duck"
  },
  "blanco.si": {
   "world": [1.1367, 0.4296, -0.16],
   "screen": [133, 130],
   "zoom": 2,
   "crop": [84, 104, 98, 52],
   "what": "a white bird on the post"
  },
  "blanco.no": {
   "world": [1.1367, 0.4296, -0.16],
   "screen": [133, 130],
   "zoom": 2,
   "crop": [84, 104, 98, 52],
   "what": "a black bird on the post"
  },
  "negro.si": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "the black duck"
  },
  "negro.no": {
   "world": [4.3186, 2.6869, -0.16],
   "screen": [150, 180],
   "zoom": 2,
   "crop": [101, 154, 98, 52],
   "what": "the yellow duck"
  }
 },
 "level": [
  {
   "w": "pato",
   "index": 0,
   "picture": "pato.si",
   "old": [72.83, 112, 54.34, 60],
   "crop": [51, 114, 98, 52],
   "zoom": 2
  },
  {
   "w": "pato",
   "index": 1,
   "picture": "pato.no",
   "old": [72.83, 112, 54.34, 60],
   "crop": [51, 114, 98, 52],
   "zoom": 2
  },
  {
   "w": "pato",
   "index": 2,
   "picture": "pez.si",
   "old": [128.83, 156, 54.34, 60],
   "crop": [107, 158, 98, 52],
   "zoom": 2
  },
  {
   "w": "pato",
   "index": 3,
   "picture": "pajaro.no",
   "old": [148.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "vuela",
   "index": 0,
   "picture": "vuela.si",
   "old": [124.83, 30, 54.34, 60],
   "crop": [103, 30, 98, 52],
   "zoom": 2
  },
  {
   "w": "vuela",
   "index": 1,
   "picture": "vuela.no",
   "old": [68.83, 112, 54.34, 60],
   "crop": [49, 114, 98, 52],
   "zoom": 2
  },
  {
   "w": "vuela",
   "index": 2,
   "picture": "nada.si",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "vuela",
   "index": 3,
   "picture": "pez.si",
   "old": [128.83, 156, 54.34, 60],
   "crop": [107, 158, 98, 52],
   "zoom": 2
  },
  {
   "w": "rojo",
   "index": 0,
   "picture": "rojo.si",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "rojo",
   "index": 1,
   "picture": "rojo.no",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "rojo",
   "index": 2,
   "picture": "verde.si",
   "old": [68.83, 112, 54.34, 60],
   "crop": [49, 114, 98, 52],
   "zoom": 2
  },
  {
   "w": "rojo",
   "index": 3,
   "picture": "azul.si",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 158, 98, 52],
   "zoom": 2
  },
  {
   "w": "negro",
   "index": 0,
   "picture": "negro.si",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "negro",
   "index": 1,
   "picture": "negro.no",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "negro",
   "index": 2,
   "picture": "amarillo.no",
   "old": [122.83, 156, 54.34, 60],
   "crop": [101, 154, 98, 52],
   "zoom": 2
  },
  {
   "w": "negro",
   "index": 3,
   "picture": "blanco.si",
   "old": [108.95, 116, 48.09, 53.1],
   "crop": [84, 104, 98, 52],
   "zoom": 2
  }
 ],
 "clips": {},
 "clipsWhat": "lago.js never calls clip()",
 "front": {
  "how": "the old background (fondo: the dock, its posts, the post) was drawn before everyone, and its reeds were in the sorted list; now the reeds, the post and the dock's mooring posts are set things someone can be behind. At its entry in the list lago.js draw sorts by y (sortY 9999: after everyone), for each item drawn before it (a child, the frog, Canelo, a duck, a bird, a boat, the fish, the bread, the bag, the sack: each item says what it is), the set's own pixels of the part (lago-set.html part(), PART_TAGS) are drawn again inside the item's box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the surface point under it (rules.floor: the deck's, the lawn's or the water's). \"Behind the post\" is that depth test, not a row",
  "plane": "v / COS - (row + .5 - OY) * tan(30 deg) / S",
  "boxes": "a child: [x - 24, y - 46 - dy, 48, 49 + dy]; the frog: frogBox with dy; Canelo: [x - 16, y - 24 - dy, 32, 27 + dy]; a duck: [x - 14, y - 23 - dy, 28, 26]; a bird: [x - 9, y - 14 - dy, 18, 16]; a boat: [x - 12, y - 22, 24, 26]; the fish: [x - 11, y - 9 - dy, 22, 16]; the bread: [x - 6, y - z - 8, 13, 12]; the bag: [x - 7, y - 13, 14, 15]; the sack: [x - 9, y - 13, 18, 15]; its ground point under (x, y - 1)",
  "parts": {
   "juncos": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"juncos\"})",
    "why": "a boat stuck in the reeds, a duck or the fish among them: the reeds nearer than it drawn over it"
   },
   "poste": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"poste\"})",
    "why": "a duck paddling round the post (acts.rema), behind it: the post drawn over it"
   },
   "muelle.postes": {
    "sortY": 9999,
    "insert": "before the sort: L.push({y: 9999, front: \"muelle.postes\"})",
    "why": "whoever stands on the dock behind a mooring post: the post drawn over them"
   }
  },
  "tags": [
   [
    "L.push({y:p.y,d:()=>gente(c,id,a)})",
    "L.push({y:p.y,id,d:()=>gente(c,id,a)})"
   ],
   [
    "L.push({y:o.pose===\"vuela\"?o.y+200:o.y,d:()=>pato(c,o,a)})",
    "L.push({y:o.pose===\"vuela\"?o.y+200:o.y,pato:k,d:()=>pato(c,o,a)})"
   ],
   [
    "L.push({y:o.y+200,d:()=>ave(c,o,a)})",
    "L.push({y:o.y+200,ave:k,d:()=>ave(c,o,a)})"
   ],
   [
    "L.push({y:o.y+(o.en===\"juncos\"?14:1),d:()=>bote(c,o)})",
    "L.push({y:o.y+(o.en===\"juncos\"?14:1),bote:k,d:()=>bote(c,o)})"
   ],
   [
    "L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,d:()=>pez(c,o)})",
    "L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,pez:k,d:()=>pez(c,o)})"
   ],
   [
    "if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)})",
    "if(q.vis)L.push({y:q.y+27,id:\"coqui\",d:()=>rana(c,q,a)})"
   ],
   [
    "if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:",
    "if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,k:\"perro\",d:"
   ]
  ],
  "tagsWhat": "each item of the sorted list says what it is (the front masks read it); nothing else changes"
 },
 "shadows": {
  "rule": "every shadow is cast from the ground point (z 0) under the screen point of the thing's feet (unproject), as El campo's, and darkens only pixels that take a cast shadow: the lawn and the dock's planks (ground, at its own depth). The water takes none (lago-set.html LOOK.noShade): what floats or swims has its ring instead (helps.ring); the dock's own shade on the water is baked into the set, joined to it",
  "coqui": {
   "radius": 0.45,
   "at": "unproject(b.x + b.w / 2, q.y + 25)",
   "when": "W.cq.vis and al > .5, on the lawn or the dock",
   "cast": "castShadow(g.x, g.y, .3, .45)"
  },
  "people": {
   "radius": {
    "nino": 0.3
   },
   "at": "unproject(x, y - 1)",
   "when": "visible (vis !== 0, al > .5)",
   "cast": "for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .3) (sitting: z to 1.35)"
  },
  "perro": {
   "radius": 0.32,
   "at": "unproject(x, y - 1)",
   "when": "W.perro shown",
   "cast": "castShadow(g.x, g.y, .25, .32)"
  },
  "pato": {
   "radius": 0.26,
   "at": "unproject(x, y - 1)",
   "when": "a duck that walks (pose anda) on the lawn or the dock",
   "cast": "castShadow(g.x, g.y, .2, .26)"
  },
  "ave": {
   "radius": 0.16,
   "at": "unproject(x, y - 1)",
   "when": "a bird standing (not flying, not on a post top) on the lawn or the dock",
   "cast": "castShadow(g.x, g.y, .1, .16)"
  },
  "bote": {
   "radius": 0.3,
   "at": "unproject(x, y - 1)",
   "when": "a boat on the dock (en muelle)",
   "cast": "castShadow(g.x, g.y, .15, .3)"
  },
  "pan": {
   "radius": 0.18,
   "at": "unproject(x, y - 1) of each piece: the row (W.fila, at its places in moves) and a piece lying on the dock",
   "cast": "castShadow(g.x, g.y, .1, .18)"
  },
  "bolsa": {
   "radius": 0.22,
   "at": "unproject(x, y - 1)",
   "when": "W.bolsa",
   "cast": "castShadow(g.x, g.y, .15, .22)"
  },
  "saco": {
   "radius": 0.3,
   "at": "unproject(x, y - 1)",
   "when": "W.saco",
   "cast": "castShadow(g.x, g.y, .15, .3)"
  },
  "dropped": "none of the old code's own: lago.js draws no shadow"
 },
 "dropped": [
  {
   "line": 112,
   "src": "c.drawImage(spr(\"lago\",fondo),0,0);",
   "to": "",
   "why": "the background: the set, for setKey(W)"
  },
  {
   "line": 116,
   "src": "JUNCOS.forEach((p,i)=>L.push({y:p[1],d:()=>c.drawImage(spr(\"jn\"+i,()=>mkJunco(i)),p[0]-11,p[1]-33)}));",
   "to": "",
   "why": "the reeds (mkJunco, in the sorted list): the set's bed of reeds (things.juncos); whoever is behind them has them drawn again over them (front.juncos)"
  }
 ],
 "moves": [
  {
   "line": 17,
   "act": "*",
   "src": "POSTE=[152,146]",
   "to": "POSTE=[166,156]",
   "places": [
    {
     "who": "ave",
     "old": [152, 122],
     "new": [166, 132],
     "world": [2.0885, -0.4135, -0.16]
    }
   ],
   "shift": {
    "who": "pato",
    "when": "rema",
    "by": [14, 10]
   },
   "why": "the post in the water: its old foot (152, 154) lies at the dock's right corner (the deck is as wide as its row of places needs: layout); 14 px right and 10 rows down, past the dock's end, so that the post, the bird on it (POSTE[1] - 24) and the duck paddling round it (acts.rema) have water all round, clear of the dock, of the boats' row at Carmen's feet and of the reeds (round 3)"
  },
  {
   "line": 17,
   "act": "inicio19",
   "src": "ORILLA=[178,116]",
   "to": "ORILLA=[188,109]",
   "places": [
    {
     "who": "carmen",
     "old": [196, 117],
     "new": [206, 110],
     "world": [2.1757, -2.5021, 0]
    }
   ],
   "why": "acts.inicio19 (los-botes): Carmen on the far bank (ORILLA + (18, 1)). The shore is one straight line on a world axis: the lawn is up to the left, and the old far bank at the right (196, 117) is open water. Round 3: the lake has its right bank again (layout): she stands on it near her old point, 8 px of lawn round her feet, facing the water, and the boats Luis sends arrive at her feet (slotC), as the old row ended at hers; as low on the bank as she can (the answer cards in the sky 2 px over her head, the hand at the right card off her face)"
  },
  {
   "line": 61,
   "act": "*",
   "src": "FX=[46,68,90],FY=165",
   "to": "FX=[46,66,85],FY=165,FYB=[154,164,174]",
   "places": [
    {
     "who": "bote",
     "old": [46, 165],
     "new": [46, 154],
     "world": [0.5605, 4.5856, 0.28]
    },
    {
     "who": "bote",
     "old": [68, 165],
     "new": [66, 164],
     "world": [1.6484, 4.5856, 0.28]
    },
    {
     "who": "bote",
     "old": [90, 165],
     "new": [85, 174],
     "world": [2.709, 4.6128, 0.28]
    }
   ],
   "why": "the row of three boats on the dock (repone): the old row lay along the old dock's face (row 165); here the boats stand on the planks in a row along the dock's near edge (each with planks under its whole keel and 3 px of plank to the edge), in front of the frog as the old"
  },
  {
   "line": 205,
   "act": "*",
   "src": "x:FX[i],y:FY,en:\"muelle\"",
   "to": "x:FX[i],y:FYB[i],en:\"muelle\"",
   "why": "repone: each boat of the row at its own row (FYB)"
  },
  {
   "line": 205,
   "act": "*",
   "src": "{W.botes[id].x=FX[i];}",
   "to": "{W.botes[id].x=FX[i];W.botes[id].y=FYB[i];}",
   "why": "repone: a boat put back in the row takes its row too (the old row had one row for all three)"
  },
  {
   "line": 207,
   "act": "*",
   "src": "await boteA(id,134,FY,7)",
   "to": "await boteA(id,112,160,7)",
   "places": [
    {
     "who": "bote",
     "old": [134, 165],
     "new": [112, 160],
     "world": [2.6818, 3.117, 0.28]
    }
   ],
   "why": "acts.empuja: the frog pushes the boat along the dock to Luis: the old point (134, 165) is off the new dock's end; on the planks before Luis's feet"
  },
  {
   "line": 208,
   "act": "*",
   "src": "await boteA(id,134,FY-6,8)",
   "to": "await boteA(id,120,156,8)",
   "places": [
    {
     "who": "bote",
     "old": [134, 159],
     "new": [120, 156],
     "world": [2.6818, 2.6818, 0.28]
    }
   ],
   "why": "acts.luiscoge: Luis carries the boat back to his place at the dock's end: before his feet, on the planks"
  },
  {
   "line": 272,
   "act": "*",
   "src": "await patoA(k,136,172,\"nada\",6)",
   "to": "await patoA(k,150,184,\"nada\",6)",
   "places": [
    {
     "who": "pato",
     "old": [136, 172],
     "new": [150, 184],
     "world": [4.4818, 2.85, -0.16]
    }
   ],
   "why": "acts.final20: the ducks gather before the dock's end before they waddle onto it: the old point is under the new deck's end; 8 px of water past it"
  },
  {
   "line": 121,
   "act": "*",
   "src": "L.push({y:FY+1,d:()=>c.drawImage(spr(\"pan\",mkPan),36+i*12-5,FY-8)})",
   "to": "L.push({y:158,d:()=>c.drawImage(spr(\"pan\",mkPan),54+i*12-5,149)})",
   "why": "the row of bread on the dock (W.fila): the old row lay on the old dock's face; here on the planks, in front of the people"
  },
  {
   "line": 62,
   "act": "*",
   "src": "const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];",
   "to": "const SLOTC=[[160,122],[166,125],[166,116],[171,128],[172,119],[177,130],[183,133],[189,136],[178,122],[184,125],[190,128],[196,131]],slotC=i=>SLOTC[Math.min(i,11)];",
   "why": "round 3: the boats that reach Carmen (sopla, conpez; 12 at the most in a run): the old row lay along the far bank and ended at her feet, filled from its far end towards her; here two rows on the water along the right bank, running from her feet up the bank, the last slot 8 to 12 px of water straight in front of her, filled from the farthest towards her as the old, neighbours 6 px apart at the least (the old spacing), each slot no further from her than the old slot was from the old Carmen (+ 10 px), none behind the post or in the reeds"
  },
  {
   "line": 61,
   "act": "*",
   "src": "PEGA=[[182,166],[196,172],[210,168],[190,178]]",
   "to": "PEGA=[[192,160],[187,156],[196,165],[184,162]]",
   "places": [
    {
     "who": "bote",
     "old": [182, 166],
     "new": [192, 160],
     "world": [4.3186, 0.4024, -0.16]
    },
    {
     "who": "bote",
     "old": [196, 172],
     "new": [187, 156],
     "world": [3.9651, 0.3208, -0.16]
    },
    {
     "who": "bote",
     "old": [210, 168],
     "new": [196, 165],
     "world": [4.6994, 0.5655, -0.16]
    },
    {
     "who": "bote",
     "old": [190, 178],
     "new": [184, 162],
     "world": [4.2099, 0.7287, -0.16]
    }
   ],
   "why": "acts.deriva: where a drifting boat sticks in the reeds: at the front of the reed bed in the shallows of the right bank (round 3; round 4: the bed further into the view), 6 px and more from the view's edge, 60% and more of each boat seen"
  },
  {
   "line": 185,
   "act": "*",
   "src": "await patoA(\"blanco\",124,126,\"nada\");d.pose=\"anda\";await patoA(\"blanco\",120,118,\"anda\",4)",
   "to": "await patoA(\"blanco\",132,124,\"nada\");d.pose=\"anda\";await patoA(\"blanco\",102,110,\"anda\",4)",
   "places": [
    {
     "who": "pato",
     "old": [124, 126],
     "new": [132, 124],
     "world": [0.7287, 0.076, -0.16]
    },
    {
     "who": "pato",
     "old": [120, 118],
     "new": [102, 110],
     "world": [-0.6527, 0.3264, 0]
    }
   ],
   "why": "acts.orilla (pan-para-el-pato): the duck climbs out onto the far bank: the old bank at row 118 is water here; it swims to the shore up the lake (8 px of water round it) and walks out onto the lawn (8 px of lawn round its feet)"
  },
  {
   "line": 186,
   "act": "*",
   "src": "await patoA(\"blanco\",124,126,\"anda\",4);d.pose=\"nada\";salpica(124,128);",
   "to": "await patoA(\"blanco\",132,124,\"anda\",4);d.pose=\"nada\";salpica(132,126);",
   "why": "acts.alagua: back into the water where it came out (orilla)"
  },
  {
   "line": 176,
   "act": "inicio18",
   "src": "async inicio18(){W.gente=",
   "to": "async inicio18(){W.respEn=[121,75];W.gente=",
   "respEn": [121, 75],
   "why": "acts.inicio18 (pan-para-el-pato): the answer cards (vuela, nada) stand over the frog as the old, a little higher and to the right: clear of Carmen's head, under the circle the duck and the bird fly round (its lowest row 74), the hand at the first card off her face"
  },
  {
   "line": 202,
   "act": "inicio19",
   "src": "async inicio19(){W.gente=",
   "to": "async inicio19(){W.respEn=[127,31];W.gente=",
   "respEn": [127, 31],
   "why": "acts.inicio19 (los-botes): the answer cards stand in the sky (W.respEn): over the frog on the dock they covered Carmen across the water, Luis and the boats. Round 3: under the rounds card by 2 px, over Carmen's head on the right bank by 2 px, their frames and glow off the sun and 4 px inside the view; the hand at each card off her face"
  },
  {
   "line": 241,
   "act": "inicio20",
   "src": "async inicio20(){W.gente=",
   "to": "async inicio20(){W.respEn=[132,32];W.gente=",
   "respEn": [132, 32],
   "why": "acts.inicio20 (cual, d-pato-pequeno, h-lago): the answer cards stand in the sky (W.respEn): over the frog they covered Luis and Canelo on the lawn and Carmen"
  },
  {
   "line": 63,
   "act": "*",
   "src": "const P7=i=>[134+(i-1)*9.5,177+(i-1)*2]",
   "to": "const P7=i=>[156+(i-1)*4.5,186+(i-1)*1]",
   "places": [
    {
     "who": "pato",
     "old": [120, 168],
     "new": [142, 177],
     "world": [3.8835, 2.6869, -0.16]
    },
    {
     "who": "pato",
     "old": [148, 170],
     "new": [170, 179],
     "world": [4.7538, 2.0341, -0.16]
    },
    {
     "who": "pato",
     "old": [134, 189],
     "new": [156, 198],
     "world": [5.4065, 3.4484, -0.16]
    },
    {
     "who": "pato",
     "old": [130, 170],
     "new": [147, 178],
     "world": [4.0739, 2.6053, -0.16]
    },
    {
     "who": "pato",
     "old": [158, 172],
     "new": [175, 180],
     "world": [4.9442, 1.9526, -0.16]
    },
    {
     "who": "pato",
     "old": [144, 191],
     "new": [161, 199],
     "world": [5.5969, 3.3668, -0.16]
    },
    {
     "who": "pato",
     "old": [139, 172],
     "new": [151, 179],
     "world": [4.2371, 2.5509, -0.16]
    },
    {
     "who": "pato",
     "old": [167, 174],
     "new": [179, 181],
     "world": [5.1073, 1.8982, -0.16]
    },
    {
     "who": "pato",
     "old": [153, 193],
     "new": [165, 200],
     "world": [5.7601, 3.3124, -0.16]
    },
    {
     "who": "pato",
     "old": [149, 174],
     "new": [156, 180],
     "world": [4.4274, 2.4693, -0.16]
    },
    {
     "who": "pato",
     "old": [177, 176],
     "new": [184, 182],
     "world": [5.2977, 1.8166, -0.16]
    },
    {
     "who": "pato",
     "old": [163, 195],
     "new": [170, 201],
     "world": [5.9504, 3.2308, -0.16]
    },
    {
     "who": "pato",
     "old": [158, 176],
     "new": [160, 181],
     "world": [4.5906, 2.4149, -0.16]
    },
    {
     "who": "pato",
     "old": [186, 178],
     "new": [188, 183],
     "world": [5.4609, 1.7622, -0.16]
    },
    {
     "who": "pato",
     "old": [172, 197],
     "new": [174, 202],
     "world": [6.1136, 3.1764, -0.16]
    },
    {
     "who": "pato",
     "old": [168, 178],
     "new": [165, 182],
     "world": [4.781, 2.3333, -0.16]
    },
    {
     "who": "pato",
     "old": [196, 180],
     "new": [193, 184],
     "world": [5.6513, 1.6806, -0.16]
    },
    {
     "who": "pato",
     "old": [182, 199],
     "new": [179, 203],
     "world": [6.304, 3.0948, -0.16]
    },
    {
     "who": "pato",
     "old": [177, 180],
     "new": [169, 183],
     "world": [4.9442, 2.2789, -0.16]
    },
    {
     "who": "pato",
     "old": [205, 182],
     "new": [197, 185],
     "world": [5.8144, 1.6262, -0.16]
    },
    {
     "who": "pato",
     "old": [191, 201],
     "new": [183, 204],
     "world": [6.4672, 3.0404, -0.16]
    }
   ],
   "why": "story 20: the seven places of the three ducks, from the dock outward: the old first places lay under the new dock's end (as wide as its row of places needs); they start 8 px of water past its end and end 6 px from the view's right edge (the ducks closer together, their order and offsets OFF unchanged)"
  },
  {
   "line": 177,
   "act": "*",
   "src": "W.peces={a:{c:\"pardo\",x:92,y:192,x0:92,dir:1,vaiven:1}}",
   "to": "W.peces={a:{c:\"pardo\",x:138,y:194,x0:138,dir:1,vaiven:1}}",
   "places": [
    {
     "who": "pez",
     "old": [92, 192],
     "new": [138, 194],
     "world": [4.6994, 3.7203, -0.16]
    }
   ],
   "why": "acts.inicio18: the fish swimming to and fro (x0 +- 12): the old place passed under the new dock's near corner; on open water in front of its end, out of its shade (round 3)"
  },
  {
   "line": 86,
   "act": "*",
   "src": "o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t)",
   "to": "o.x=132+8*Math.cos(t);o.y=190+4*Math.sin(t)",
   "why": "anima: the fish circling before the dock (pezviene, h-lago): its hint frame (box + 12) 2 px inside the view at the bottom of its circle, its patch out of the dock's shade, its circle narrower (13 to 8 px) so that it keeps clear of the ducks (round 3)"
  },
  {
   "line": 222,
   "act": "*",
   "src": "await pezA(\"a\",134,192,16)",
   "to": "await pezA(\"a\",140,190,16)",
   "places": [
    {
     "who": "pez",
     "old": [134, 192],
     "new": [140, 190],
     "world": [4.5362, 3.4484, -0.16]
    }
   ],
   "why": "acts.pezviene: the fish swims up to its circle (anima, moved)"
  },
  {
   "line": 87,
   "act": "*",
   "src": "const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;",
   "to": "const b=W.botes[o.sigue];o.x=b.x+10;o.y=b.y+12;",
   "why": "anima: the fish swimming with a boat to Carmen (conpez): below the boat's right instead of its left, so that its path keeps out of the dock's shade at the dock's end (round 3)"
  },
  {
   "line": 230,
   "act": "*",
   "src": "await pezA(\"a\",SALE[0][0]-4,SALE[0][1]+9,6)",
   "to": "await pezA(\"a\",SALE[0][0]+10,SALE[0][1]+12,6)",
   "why": "acts.conpez: the fish comes to the boat's right (anima, round 3)"
  },
  {
   "line": 241,
   "act": "inicio20",
   "src": "W.flor=[196,119]",
   "to": "W.flor=[204,112]",
   "places": [
    {
     "who": "flor",
     "old": [196, 119],
     "new": [204, 112],
     "world": [2.2301, -2.3389, 0]
    }
   ],
   "why": "acts.inicio20: the yellow flower on the right bank (round 3), as the old: round 4, 8 px right and 7 rows up of its old point, whole inside the view 4 px and more from its right edge with the stars of its twinkle inside it, 8 px of lawn round its foot, lawn and the hills behind its head"
  }
 ],
 "helps": {
  "what": "drawn by the sprite layer just before the thing they help, 1:1 (lines: each drawing function of a thing on the water gains one call): El campo's ripple ring on the water round whatever floats or swims at the surface: a duck swimming, a boat on the water or in the reeds, the bread lying on the water",
  "margin": 8,
  "edge": 6,
  "deckMargin": 3,
  "marginWhat": "whatever rests near the shore or the dock's edge is on one side: on the lawn with at least `margin` px of lawn round its foot (the lowest 2 rows of its sprite); on the dock with planks under its whole foot and at least `deckMargin` px of plank to the dock's edge; in the water with `margin` px of water all round its foot, the ring and the thing `edge` px and more from the picture's edges",
  "ring": {
   "inner": 0.45,
   "colour": [212, 236, 246],
   "pato": {
    "rx": 13,
    "ry": 3,
    "dy": 0
   },
   "bote": {
    "rx": 11,
    "ry": 3,
    "dy": 0
   },
   "pan": {
    "rx": 7,
    "ry": 2.5,
    "dy": 0
   },
   "pez": {
    "centre": [0, -0.5],
    "rx": 13,
    "ry": 8.5,
    "soft": 3,
    "patch": [166, 210, 224],
    "dash": [149, 196, 211],
    "why": "round 5: the fish at the surface swims in a patch of lighter water of its own: an ellipse centred on the fish (its sprite, 18 x 11, either way it faces), its axes the fish's length + 8 and height + 6 (26 x 17: rx 13, ry 8.5); the old water's pale tone (#A6D2E0) in it; no rim, no ring line: its edge breaks into the lake by dither over its outer soft (3) px (t, the px inside its edge: a pixel is drawn where the Bayer threshold at it is under t / soft, so the outer pixels are sparse); inside it the lake's own ripple dashes go on (set-kit.js waterPixel's rows and runs) in the lake's lightest ripple tone (dash: its shallow water + .55 of the sky's colour), the same surface stirred pale; only where the water shows. Every fish colour 45 and more from the 2 px band of water just outside its outline"
   },
   "when": "a duck swimming (pose nada, not in the air: dy <= 3); a boat on the water or in the reeds (en agua, juncos, carmen, or on its way: meta); the bread lying on the water (W.pan, not carried, z <= 1, its point over the water); round 3: the fish swimming at the surface (dy <= 4) has its pale patch instead (pez; leaping, it has its splash as the old)",
   "how": "every pixel (x, y) with .45 < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1 that shows the water (the set's surface) takes the colour: a duck's at (x, y) (rx scaled .78 for the yellow one), a boat's at (x, y + bob), the bread's at (x, y)"
  },
  "lines": [
   [
    "function pato(c,o,a){if(!o||o.vis===0)return;",
    "function pato(c,o,a){if(!o||o.vis===0)return;PREVIEW.ring(c,\"pato\",o);"
   ],
   [
    "function bote(c,o){if(!o||o.vis===0)return;",
    "function bote(c,o){if(!o||o.vis===0)return;PREVIEW.ring(c,\"bote\",o);"
   ],
   [
    "function pez(c,o){if(!o||o.vis===0)return;",
    "function pez(c,o){if(!o||o.vis===0)return;PREVIEW.patch(c,o);"
   ],
   [
    "L.push({y:999,d:()=>c.drawImage(spr(\"pan\",mkPan),R(W.pan.x)-5,R(W.pan.y)-R(W.pan.z||0)-7)});",
    "L.push({y:999,d:()=>{PREVIEW.ring(c,\"pan\",W.pan);c.drawImage(spr(\"pan\",mkPan),R(W.pan.x)-5,R(W.pan.y)-R(W.pan.z||0)-7);}});"
   ]
  ],
  "linesWhat": "the lines lago.js gains: the help is drawn first, then the thing; the port draws them the same way"
 },
 "bubbles": {
  "what": "each bubble's rectangle relative to its tail's tip, as lago.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]",
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
  "what": "where a bubble goes (lago.js draw: line 129 for a child, 130 for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible child's and the frog's, its own too); if none is, the first (the old)",
  "top": "a child: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)",
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
  "placesWhat": "[side, dy]: the tail's tip at (top.x + side * (h + 16), top.y + dy), h the head's half width: a child 6, the frog b.w >> 1",
  "faces": "a child's face: [hx - 6, y - dy + top + 5, 12, 10] (eyes to chin, not the hair), hx the head's middle; the frog's: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]",
  "heads": {
   "luis": {
    "top": -41,
    "head": 0
   },
   "luis.s": {
    "top": -38,
    "head": 0
   },
   "carmen": {
    "top": -41,
    "head": 0
   },
   "carmen.s": {
    "top": -38,
    "head": 0
   }
  },
  "headsWhat": "each sprite (idle; .s sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head + 1)",
  "board": [2, 2, 68, 26],
  "boardWhat": "in the 196 x 216 display, then + the view's x0: W.tarjeta (the rounds card) [2, 2, 68, 26]"
 },
 "code": [
  {
   "line": 17,
   "old": "MUELLE [26,152,112,13]; POSTE [152,146]; PM[] [40,141]; PM[] [133,141]; JUNCOS[] [190,150]; JUNCOS[] [200,144]; JUNCOS[] [210,152]; JUNCOS[] [196,158]; JUNCOS[] [206,162]; ORILLA [178,116]",
   "to": {
    "points": ["shore", "dock", "postes", "poste"],
    "moves": [
     "POSTE",
     "ORILLA"
    ]
   },
   "note": "the set's things: the shore and the water (points.shore), the dock (points.dock), the mooring posts at the old PM tops (points.postes), the post (moved: moves), the reeds (dropped: the set's bed), Carmen's far bank (ORILLA: moved)"
  },
  {
   "line": 60,
   "old": "LUGAR.inicio [100,125,1]; LUGAR.muelle [100,125,1]",
   "to": {
    "spots": ["frog.inicio", "frog.muelle"]
   },
   "note": "the floor rule: the same screen places, on the dock"
  },
  {
   "line": 61,
   "old": "FX [46,68,90]; SALE[] [150,172]; SALE[] [168,180]; SALE[] [152,190]; PEGA[] [182,166]; PEGA[] [196,172]; PEGA[] [210,168]; PEGA[] [190,178]",
   "to": {
    "moves": [
     "FX",
     "PEGA"
    ],
    "spots": ["sale.0", "sale.1", "sale.2"]
   },
   "note": "the row of boats on the dock (moves), SALE unchanged (on the water), PEGA in the reeds (moves)"
  },
  {
   "line": 63,
   "old": "OFF[] [-14,-9]; OFF[] [14,-7]; OFF[] [0,12]",
   "to": "unchanged",
   "note": "the ducks' seven places on the water (story 20): the floor rule, unchanged"
  },
  {
   "line": 76,
   "old": "box [178,120,40,46]",
   "to": {
    "things": ["juncos", "poste", "muelle", "agua", "lago"]
   },
   "note": "the set things' boxes (things)"
  },
  {
   "line": 77,
   "old": "box [0,94,240,122]",
   "to": {
    "things": ["agua", "lago"]
   },
   "note": "the water's and the lake's boxes (things.agua, things.lago)"
  },
  {
   "line": 91,
   "old": "c.scale(-1,1) args 0,1 [-1,1]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 97,
   "old": "c.scale(-1,1) args 0,1 [-1,1]; c.drawImage(im,0,0,26,18,-13,…,26,18) args 1,2 [0,0]; c.drawImage(im,-13,-21) args 1,2 [-13,-21]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 100,
   "old": "c.scale(-1,1) args 0,1 [-1,1]; c.drawImage(im,-9,-6) args 1,2 [-9,-6]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 102,
   "old": "c.scale(-1,1) args 0,1 [-1,1]; c.drawImage(im,-7,-12) args 1,2 [-7,-12]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 105,
   "old": "c.drawImage(im,-10,-19) args 1,2 [-10,-19]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 110,
   "old": "c.scale(2,2) args 0,1 [2,2]; bub(c,k,0,0,a) args 2,3 [0,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 112,
   "old": "c.drawImage(spr(\"_\",fondo),0,0) [sprite \"lago\"] args 1,2 [0,0]",
   "to": {
    "dropped": true
   },
   "note": "dropped: the set (dropped)"
  },
  {
   "line": 113,
   "old": "[] [-3,-14]; [] [1,-14]; [] [-3,-10]; [] [1,-10]; [] [-1,-16]; [] [-1,-9]; [] [-4,-12]; [] [2,-12]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 124,
   "old": "c.scale(-1,1) args 0,1 [-1,1]; c.drawImage(im,-13,0) args 1,2 [-13,0]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 137,
   "old": "tarjeta(g,3,3,66,24) args 1,2 [3,3]",
   "to": "unchanged",
   "note": "a sprite's, a card's or an effect's own drawing, relative to where it is drawn: unchanged"
  },
  {
   "line": 176,
   "old": "x:,y: [44,154]; x:,y: [72,154]; x:,y: [100,125]",
   "to": {
    "moves": [
     "async inicio18(){W.gente="
    ]
   },
   "note": "moved: async inicio18(){W.gente= (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 177,
   "old": "x:,y: [142,184]; x:,y: [92,192]",
   "to": {
    "moves": [
     "W.peces={a:{c:\"pardo\",x:92,y:192,x0:92,dir:1,vaiven:1}}"
    ]
   },
   "note": "moved: W.peces={a:{c:\"pardo\",x:92,y:192,x0:92,dir:1,vaiven:1}} (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 180,
   "old": "patoA(\"_\",142,184,…) args 1,2 [142,184]; salpica(142,184) args 0,1 [142,184]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 185,
   "old": "patoA(\"_\",124,126,\"_\") args 1,2 [124,126]; patoA(\"_\",120,118,\"_\",4) args 1,2 [120,118]",
   "to": {
    "moves": [
     "await patoA(\"blanco\",124,126,\"nada\");d.pose=\"anda\";await patoA(\"blanco\",120,118,\"anda\",4)"
    ]
   },
   "note": "moved: await patoA(\"blanco\",124,126,\"nada\");d.pose=\"anda\";await patoA(\"blanco\",120,118,\"anda\",4) (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 186,
   "old": "patoA(\"_\",124,126,\"_\",4) args 1,2 [124,126]; salpica(124,128) args 0,1 [124,128]; patoA(\"_\",142,184,\"_\") args 1,2 [142,184]",
   "to": {
    "moves": [
     "await patoA(\"blanco\",124,126,\"anda\",4);d.pose=\"nada\";salpica(124,128);"
    ]
   },
   "note": "moved: await patoA(\"blanco\",124,126,\"anda\",4);d.pose=\"nada\";salpica(124,128); (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 197,
   "old": "pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]",
   "to": "unchanged",
   "note": "screen effect: the stars, unchanged"
  },
  {
   "line": 202,
   "old": "W.saco [110,153]; x:,y: [128,154]; x:,y: [60,125]",
   "to": {
    "moves": [
     "async inicio19(){W.gente="
    ]
   },
   "note": "moved: async inicio19(){W.gente= (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 208,
   "old": "mueve(\"_\",128,154) args 1,2 [128,154]",
   "to": {
    "moves": [
     "await boteA(id,134,FY-6,8)"
    ]
   },
   "note": "moved: await boteA(id,134,FY-6,8) (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 222,
   "old": "x:,y: [232,192]; pezA(\"_\",134,192,16) args 1,2 [134,192]",
   "to": {
    "moves": [
     "await pezA(\"a\",134,192,16)"
    ]
   },
   "note": "moved: await pezA(\"a\",134,192,16) (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 238,
   "old": "pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]",
   "to": "unchanged",
   "note": "screen effect: the stars, unchanged"
  },
  {
   "line": 241,
   "old": "W.bolsa [96,153]; W.flor [196,119]; x:,y: [74,118]; x:,y: [112,154]; x:,y: [62,125]; x:,y: [46,119]",
   "to": {
    "moves": [
     "async inicio20(){W.gente=",
     "W.flor=[196,119]"
    ]
   },
   "note": "moved: async inicio20(){W.gente=; W.flor=[196,119] (moves); the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 242,
   "old": "W.orden [0,1,2]; x:,y: [0,0]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every other place here keeps its screen place; offsets and orders, not places: unchanged"
  },
  {
   "line": 254,
   "old": "x:,y: [-10,60]; x:,y: [250,50]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 259,
   "old": "panA(…,4,6) args 1,2 [4,6]; panA([p[0],p[1]-6],0,22) args 1,2 [0,22]",
   "to": {
    "floor": true
   },
   "note": "the floor rule: every other place here keeps its screen place"
  },
  {
   "line": 272,
   "old": "xs [104,118,131]; pts[] [70,60]; pts[] [196,70]; pts[] [136,50]; pts[] [110,90]; pts[] [170,96]; patoA(k,136,172,\"_\",6) args 1,2 [136,172]",
   "to": {
    "moves": [
     "await patoA(k,136,172,\"nada\",6)"
    ]
   },
   "note": "moved: await patoA(k,136,172,\"nada\",6) (moves); the floor rule: every other place here keeps its screen place; screen effect: the stars, unchanged"
  },
  {
   "line": 279,
   "old": "for(…) [-2,1,-1,0]",
   "to": "unchanged",
   "note": "offsets and orders, not places: unchanged"
  },
  {
   "line": 294,
   "old": "CAM.wide [22,0,196,216]; heartAt [110,30]",
   "to": {
    "view": "wide",
    "point": "corazon"
   },
   "note": "the view (views.wide) and the heart (points.corazon): unchanged"
  },
  {
   "line": 76,
   "old": "box juncos [178,120,40,46]",
   "to": {
    "thing": "juncos",
    "box": [193, 140, 29, 33],
    "hand": [199, 157]
   }
  },
  {
   "line": 76,
   "old": "box poste [147,120,10,36]",
   "to": {
    "thing": "poste",
    "box": [162, 129, 8, 37],
    "hand": [166, 152]
   }
  },
  {
   "line": 76,
   "old": "box muelle [26,150,112,17]",
   "to": {
    "thing": "muelle",
    "box": [16, 120, 139, 73],
    "hand": [96, 160]
   }
  },
  {
   "line": 77,
   "old": "box agua [0,118,240,98]",
   "to": {
    "thing": "agua",
    "box": [0, 100, 240, 116],
    "hand": [176, 196]
   }
  },
  {
   "line": 77,
   "old": "box lago [0,94,240,122]",
   "to": {
    "thing": "lago",
    "box": [0, 100, 240, 116],
    "hand": [176, 196]
   }
  },
  {
   "line": 205,
   "old": "x:FX[i],y:FY,en:\"muelle\"",
   "to": {
    "moves": [
     "x:FX[i],y:FY,en:\"muelle\""
    ]
   },
   "note": "moved (moves): repone"
  },
  {
   "line": 207,
   "old": "await boteA(id,134,FY,7)",
   "to": {
    "moves": [
     "await boteA(id,134,FY,7)"
    ]
   },
   "note": "moved (moves): acts.empuja"
  },
  {
   "line": 121,
   "old": "L.push({y:FY+1,d:()=>c.drawImage(spr(\"pan\",mkPan),36+i*12-5,FY-8)})",
   "to": {
    "moves": [
     "L.push({y:FY+1,d:()=>c.drawImage(spr(\"pan\",mkPan),36+i*12-5,FY-8)})"
    ]
   },
   "note": "moved (moves): the row of bread on the dock (W.fila)"
  },
  {
   "line": 62,
   "old": "const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];",
   "to": {
    "moves": [
     "const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];"
    ]
   },
   "note": "moved (moves): round 3"
  },
  {
   "line": 86,
   "old": "o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t)",
   "to": {
    "moves": [
     "o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t)"
    ]
   },
   "note": "moved (moves): anima"
  },
  {
   "line": 87,
   "old": "const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;",
   "to": {
    "moves": [
     "const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;"
    ]
   },
   "note": "moved (moves): anima"
  },
  {
   "line": 230,
   "old": "await pezA(\"a\",SALE[0][0]-4,SALE[0][1]+9,6)",
   "to": {
    "moves": [
     "await pezA(\"a\",SALE[0][0]-4,SALE[0][1]+9,6)"
    ]
   },
   "note": "moved (moves): acts.conpez"
  },
  {
   "line": 65,
   "old": "caja(id): [x - 11, y - alto(id), 22, alto(id)]",
   "to": "relative to the child: unchanged"
  },
  {
   "line": 127,
   "old": "the sorted list",
   "to": {
    "front": ["juncos", "poste", "muelle.postes"]
   },
   "note": "entries added before the sort (front.parts), each item tagged (front.tags)"
  },
  {
   "line": "juego.js:16",
   "old": "fresh(): cq x 150 y 178 s 1",
   "to": "not used here: lago's fresh() puts him at LUGAR.inicio"
  },
  {
   "line": "cual.js:21",
   "old": "panelW(): cq x 123 y 150 s .86",
   "to": "a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)"
  }
 ],
 "checks": {
  "notes": [
   "inventory: 19 things (old 19), 2 frog places of LUGAR (old 2) and 8 frog places in all, 1 view (old 1), 48 positions (old 48), 11 review pairs of cual-lago (22 pictures here; none is another scene's), 16 level pictures (old 16), 98 places of lago.js and every moved line named in code, 1 baked state (the old 10)",
   "hops: all 21 pairs of the frog's 7 places keep the old count; his walks in the runs: hlago-inicio20, inicio-inicio19, inicio-inicio20, inicio-pequeno, inicio-ranaa, inicio19-ranapinta, inicio20-pequeno, pequeno-ranaa",
   "boxes: every pixel of each set thing inside its touch box (nothing sways: no leaf, no reed moves at any wind step): muelle [16,120,139,73] (5092 px), poste [162,129,8,37] (278 px), juncos [193,140,29,33] (495 px); every pixel answers its own thing in the hit order; the set's parts are juncos, muelle, muelle.postes, poste (each a touch key's: nothing decorative); the water and the lawn are the ground of agua and lago",
   "shadows of the set: every castShadow call has strength 1 and a radius; each casting part darkens pixels, its shadow in one piece with it and short (a contact shadow at the foot of the thin mooring posts): muelle.postes 4 calls, 16 px darkened",
   "water: none of its 14780 px takes a cast shadow (people, animals and things cast theirs on the lawn and the planks only); the dock's shade, 860 px on the water beside and under it, every one within 9 px of the dock",
   "water: El campo's (mean 61,128,163, 27 from the nearest sky band; 12.5% ripples; 82 glints, none in the dock's shade); the lake in the view (every pixel whose ground is past the shore, the dock over it counted, as the old dock over the old water) 17540 px against the old 17435 (101%); open water shown 12214 px against the old 13298 (92%): the deck covers more of it than the old strip of a dock did",
   "sides: 17793 ticks inside the acts of the port's play of the 15 runs, every step's end and every pair picture: 164934 rests (300 ms or more in one place), each clearly on one side: on the lawn with 8 px of lawn round its foot (ave a, carmen, flor, luis, pato blanco, perro), on the dock with planks under its whole foot and 3 px of plank to the edge (ave a, bolsa, bote a, bote f_azul, bote f_rojo, bote f_verde, carmen, luis, pan fila.0, pan fila.1, pan fila.2, pan fila.3, pan fila.4, pan fila.5, pato a, pato amarillo, pato blanco, pato negro, saco, the frog), in the water with 8 px of water round it (bote a, bote b0, bote b1, bote b10, bote b11, bote b12, bote b13, bote b14, bote b15, bote b16, bote b2, bote b3, bote b4, bote b5, bote b6, bote b7, bote b8, bote b9, pan, pato a, pato amarillo, pato blanco, pato negro), whatever floats 8 px at least from the view's edges",
   "rings: 83833 moments of a duck swimming, a boat on the water or the bread on it, each with its ring (resting ones 92% on the water at the least); the fish under the surface over open water (7952 moments) or leaping with its splash (450)",
   "perches: 10284 moments of a bird on a post's top (the mooring posts' or the post's), each with the post under its feet; behind a front part, drawn over them by front: bote b1 at 167,165 behind poste (117 px), bote b1 at 167,163 behind poste (123 px), bote b0 at 154,153 behind poste (3 px), bote b1 at 167,161 behind poste (123 px), bote b0 at 154,152 behind poste (3 px), bote b1 at 167,159 behind poste (123 px), bote b0 at 154,150 behind poste (3 px), bote b1 at 167,157 behind poste (123 px), bote b0 at 155,148 behind poste (9 px), bote b1 at 167,155 behind poste (123 px), bote b2 at 157,166 behind poste (16 px), bote b0 at 155,146 behind poste (9 px), bote b1 at 167,153 behind poste (123 px), bote b2 at 157,164 behind poste (27 px), bote b0 at 156,144 behind poste (17 px), bote b1 at 167,152 behind poste (123 px), bote b2 at 157,162 behind poste (28 px), bote b0 at 156,142 behind poste (17 px), bote b1 at 167,150 behind poste (123 px), bote b2 at 158,160 behind poste (40 px), bote b0 at 156,140 behind poste (17 px), bote b1 at 167,148 behind poste (123 px), bote b2 at 158,158 behind poste (40 px), bote b0 at 157,138 behind poste (24 px), bote b1 at 167,146 behind poste (118 px), bote b2 at 158,156 behind poste (40 px), bote b0 at 157,137 behind poste (22 px), bote b1 at 167,144 behind poste (109 px), bote b2 at 159,155 behind poste (54 px), bote b0 at 157,135 behind poste (15 px), bote b1 at 167,142 behind poste (98 px), bote b2 at 159,153 behind poste (54 px), bote b0 at 158,133 behind poste (12 px), bote b1 at 167,140 behind poste (84 px), bote b2 at 159,151 behind poste (54 px), bote b0 at 158,131 behind poste (3 px), bote b1 at 166,138 behind poste (68 px), bote b2 at 160,149 behind poste (69 px), bote b1 at 166,136 behind poste (52 px), bote b2 at 160,147 behind poste (69 px), bote b1 at 166,134 behind poste (36 px), bote b2 at 160,145 behind poste (69 px), bote b1 at 166,133 behind poste (28 px), bote b2 at 161,143 behind poste (80 px), bote b1 at 166,131 behind poste (12 px), bote b2 at 161,141 behind poste (74 px), bote b2 at 162,140 behind poste (78 px), bote b2 at 162,138 behind poste (65 px), bote b2 at 162,136 behind poste (49 px), bote b2 at 163,134 behind poste (35 px), bote b2 at 163,132 behind poste (19 px), bote b2 at 163,130 behind poste (4 px), bote b3 at 140,140 behind muelle.postes (3 px), bote b3 at 142,147 behind muelle.postes (11 px), bote b3 at 154,163 behind poste (3 px), bote b3 at 155,162 behind poste (9 px), bote b3 at 156,160 behind poste (17 px), bote b3 at 156,159 behind poste (17 px), bote b3 at 157,158 behind poste (28 px), bote b3 at 158,156 behind poste (40 px), bote b3 at 158,155 behind poste (40 px), bote b3 at 159,153 behind poste (54 px), bote b3 at 160,152 behind poste (69 px), bote b3 at 160,150 behind poste (69 px), bote b3 at 161,149 behind poste (86 px), bote b3 at 162,147 behind poste (100 px), bote b3 at 162,146 behind poste (98 px), bote b3 at 163,145 behind poste (106 px), bote b3 at 164,143 behind poste (105 px), bote b3 at 164,142 behind poste (99 px), bote b3 at 165,140 behind poste (84 px), bote b3 at 166,139 behind poste (76 px), bote b3 at 167,137 behind poste (60 px), bote b3 at 167,136 behind poste (52 px), bote b3 at 168,134 behind poste (36 px), bote b3 at 169,133 behind poste (27 px), bote b3 at 169,132 behind poste (19 px), bote b3 at 170,130 behind poste (4 px), bote b4 at 140,140 behind muelle.postes (3 px), bote b4 at 142,147 behind muelle.postes (11 px), bote b4 at 154,163 behind poste (3 px), bote b4 at 154,162 behind poste (3 px), bote b4 at 155,160 behind poste (9 px), bote b4 at 156,159 behind poste (17 px), bote b4 at 156,157 behind poste (17 px), bote b4 at 157,156 behind poste (28 px), bote b4 at 157,154 behind poste (28 px), bote b4 at 158,153 behind poste (40 px), bote b4 at 159,151 behind poste (54 px), bote b4 at 159,150 behind poste (54 px), bote b4 at 160,148 behind poste (69 px), bote b4 at 160,147 behind poste (69 px), bote b4 at 161,145 behind poste (84 px), bote b4 at 162,144 behind poste (94 px), bote b4 at 162,142 behind poste (87 px), bote b4 at 163,141 behind poste (89 px), bote b4 at 163,139 behind poste (75 px), bote b4 at 164,138 behind poste (68 px), bote b4 at 165,137 behind poste (60 px), bote b4 at 165,135 behind poste (44 px), bote b4 at 166,134 behind poste (36 px), bote b4 at 167,132 behind poste (20 px), bote b4 at 167,131 behind poste (12 px), bote b5 at 140,140 behind muelle.postes (3 px), bote b5 at 142,147 behind muelle.postes (11 px), bote b6 at 143,142 behind muelle.postes (1 px), bote b6 at 158,165 behind poste (37 px), bote b7 at 140,143 behind muelle.postes (16 px), bote b5 at 155,164 behind poste (9 px), bote b5 at 156,162 behind poste (17 px), bote b5 at 157,161 behind poste (28 px), bote b5 at 158,159 behind poste (40 px), bote b6 at 173,166 behind poste (26 px), bote b5 at 159,158 behind poste (54 px), bote b6 at 173,164 behind poste (40 px), bote b5 at 160,156 behind poste (69 px), bote b6 at 174,162 behind poste (29 px), bote b5 at 161,154 behind poste (86 px), bote b6 at 174,160 behind poste (29 px), bote b5 at 162,153 behind poste (101 px), bote b6 at 175,158 behind poste (19 px), bote b5 at 163,151 behind poste (114 px), bote b6 at 176,156 behind poste (11 px), bote b5 at 164,150 behind poste (124 px), bote b6 at 176,155 behind poste (11 px), bote b5 at 165,148 behind poste (127 px), bote b6 at 177,153 behind poste (6 px), bote b7 at 168,166 behind poste (83 px), bote b5 at 166,146 behind poste (123 px), bote b6 at 177,151 behind poste (6 px), bote b7 at 169,165 behind poste (99 px), bote b5 at 167,145 behind poste (114 px), bote b6 at 178,149 behind poste (2 px), bote b7 at 170,163 behind poste (90 px), bote b5 at 168,143 behind poste (98 px), bote b6 at 178,147 behind poste (2 px), bote b7 at 171,162 behind poste (73 px), bote b5 at 170,142 behind poste (76 px), bote b7 at 172,160 behind poste (55 px), bote b5 at 171,140 behind poste (60 px), bote b7 at 173,159 behind poste (41 px), bote b5 at 172,138 behind poste (44 px), bote b7 at 175,157 behind poste (19 px), bote b5 at 173,137 behind poste (33 px), bote b7 at 176,156 behind poste (11 px), bote b5 at 174,135 behind poste (21 px), bote b7 at 177,154 behind poste (6 px), bote b5 at 175,134 behind poste (12 px), bote b7 at 178,152 behind poste (2 px), bote b5 at 176,132 behind poste (1 px), bote b8 at 140,140 behind muelle.postes (3 px), bote b8 at 142,147 behind muelle.postes (11 px), bote b8 at 170,166 behind poste (60 px), bote b8 at 171,166 behind poste (48 px), bote b8 at 172,166 behind poste (37 px), bote b8 at 173,165 behind poste (38 px), bote b8 at 175,165 behind poste (17 px), bote b8 at 176,165 behind poste (10 px), bote b8 at 177,164 behind poste (6 px), bote b8 at 178,164 behind poste (2 px), bote b8 at 187,161 behind juncos (3 px), bote b8 at 188,161 behind juncos (6 px), bote b8 at 190,161 behind juncos (18 px), bote b8 at 191,160 behind juncos (24 px), bote b8 at 192,160 behind juncos (57 px), bote b9 at 154,165 behind poste (3 px), bote b9 at 155,164 behind poste (9 px), bote b9 at 156,162 behind poste (17 px), bote b9 at 156,160 behind poste (17 px), bote b9 at 157,159 behind poste (28 px), bote b9 at 158,157 behind poste (40 px), bote b9 at 159,155 behind poste (54 px), bote b9 at 160,154 behind poste (69 px), bote b9 at 161,152 behind poste (86 px), bote b9 at 162,150 behind poste (101 px), bote b9 at 163,149 behind poste (114 px), bote b9 at 164,147 behind poste (121 px), bote b9 at 165,145 behind poste (118 px), bote b9 at 166,144 behind poste (114 px), bote b9 at 167,142 behind poste (98 px), bote b9 at 168,141 behind poste (88 px), bote b9 at 169,139 behind poste (71 px), bote b9 at 169,137 behind poste (58 px), bote b9 at 170,136 behind poste (49 px), bote b9 at 171,134 behind poste (30 px), bote b9 at 172,132 behind poste (13 px), bote b9 at 173,131 behind poste (5 px), bote b10 at 140,140 behind muelle.postes (3 px), bote b10 at 142,147 behind muelle.postes (11 px), bote b10 at 155,166 behind poste (3 px), bote b10 at 156,164 behind poste (17 px), bote b10 at 157,163 behind poste (28 px), bote b10 at 158,162 behind poste (40 px), bote b10 at 158,160 behind poste (40 px), bote b10 at 159,159 behind poste (54 px), bote b10 at 160,158 behind poste (69 px), bote b10 at 161,156 behind poste (86 px), bote b10 at 162,155 behind poste (101 px), bote b10 at 163,154 behind poste (114 px), bote b10 at 164,153 behind poste (124 px), bote b10 at 165,151 behind poste (127 px), bote b10 at 166,150 behind poste (127 px), bote b10 at 167,149 behind poste (123 px), bote b10 at 168,147 behind poste (114 px), bote b10 at 169,146 behind poste (98 px), bote b10 at 170,145 behind poste (83 px), bote b10 at 171,143 behind poste (67 px), bote b10 at 172,142 behind poste (53 px), bote b10 at 173,141 behind poste (40 px), bote b10 at 173,140 behind poste (39 px), bote b10 at 174,138 behind poste (27 px), bote b10 at 175,137 behind poste (18 px), bote b10 at 176,136 behind poste (11 px), bote b10 at 177,134 behind poste (3 px), bote b11 at 140,140 behind muelle.postes (3 px), bote b11 at 142,147 behind muelle.postes (11 px), bote b12 at 143,142 behind muelle.postes (1 px), bote b12 at 158,165 behind poste (37 px), bote b11 at 155,166 behind poste (3 px), bote b11 at 156,165 behind poste (16 px), bote b11 at 158,164 behind poste (39 px), bote b11 at 159,162 behind poste (54 px), bote b11 at 160,161 behind poste (69 px), bote b11 at 162,159 behind poste (101 px), bote b12 at 176,165 behind poste (10 px), bote b11 at 163,158 behind poste (114 px), bote b12 at 177,164 behind poste (6 px), bote b11 at 164,157 behind poste (124 px), bote b12 at 178,162 behind poste (2 px), bote b11 at 165,155 behind poste (127 px), bote b11 at 167,154 behind poste (123 px), bote b11 at 168,152 behind poste (116 px), bote b11 at 169,151 behind poste (104 px), bote b11 at 170,150 behind poste (90 px), bote b11 at 172,148 behind poste (55 px), bote b11 at 173,147 behind poste (41 px), bote b11 at 174,145 behind poste (29 px), bote b12 at 186,149 behind juncos (2 px), bote b11 at 176,144 behind poste (11 px), bote b12 at 187,147 behind juncos (2 px), bote b11 at 177,142 behind poste (6 px), bote b11 at 178,141 behind poste (2 px), bote b9 at 163,166 behind poste (79 px), bote b9 at 164,166 behind poste (87 px), bote b9 at 165,165 behind poste (121 px), bote b9 at 166,165 behind poste (121 px), bote b9 at 167,164 behind poste (121 px), bote b9 at 169,164 behind poste (103 px), bote b9 at 170,164 behind poste (89 px), bote b9 at 171,163 behind poste (73 px), bote b9 at 172,163 behind poste (55 px), bote b9 at 173,162 behind poste (41 px), bote b9 at 174,162 behind poste (29 px), bote b9 at 175,161 behind poste (19 px), bote b9 at 176,161 behind poste (11 px), bote b9 at 177,160 behind poste (6 px), bote b9 at 178,160 behind poste (2 px), bote b9 at 187,156 behind juncos (9 px), bote b10 at 154,165 behind poste (3 px), bote b10 at 155,164 behind poste (9 px), bote b10 at 156,162 behind poste (17 px), bote b10 at 156,160 behind poste (17 px), bote b10 at 157,159 behind poste (28 px), bote b10 at 158,157 behind poste (40 px), bote b10 at 159,155 behind poste (54 px), bote b10 at 160,154 behind poste (69 px), bote b10 at 161,152 behind poste (86 px), bote b10 at 162,150 behind poste (101 px), bote b10 at 163,149 behind poste (114 px), bote b10 at 164,147 behind poste (121 px), bote b10 at 165,145 behind poste (118 px), bote b10 at 166,144 behind poste (114 px), bote b10 at 167,142 behind poste (98 px), bote b10 at 168,141 behind poste (88 px), bote b10 at 169,139 behind poste (71 px), bote b10 at 169,137 behind poste (58 px), bote b10 at 170,136 behind poste (49 px), bote b10 at 171,134 behind poste (30 px), bote b10 at 172,132 behind poste (13 px), bote b10 at 173,131 behind poste (5 px), bote b11 at 187,166 behind juncos (3 px), bote b11 at 188,166 behind juncos (6 px), bote b11 at 189,166 behind juncos (8 px), bote b11 at 191,166 behind juncos (12 px), bote b11 at 192,166 behind juncos (17 px), bote b11 at 193,165 behind juncos (22 px), bote b11 at 195,165 behind juncos (41 px), bote b11 at 196,165 behind juncos (73 px), bote b12 at 140,140 behind muelle.postes (3 px), bote b12 at 142,147 behind muelle.postes (11 px), bote b12 at 155,166 behind poste (3 px), bote b12 at 156,164 behind poste (17 px), bote b12 at 157,163 behind poste (28 px), bote b12 at 158,162 behind poste (40 px), bote b12 at 158,160 behind poste (40 px), bote b12 at 159,159 behind poste (54 px), bote b12 at 160,158 behind poste (69 px), bote b12 at 161,156 behind poste (86 px), bote b12 at 162,155 behind poste (101 px), bote b12 at 163,154 behind poste (114 px), bote b12 at 164,153 behind poste (124 px), bote b12 at 165,151 behind poste (127 px), bote b12 at 166,150 behind poste (127 px), bote b12 at 167,149 behind poste (123 px), bote b12 at 168,147 behind poste (114 px), bote b12 at 169,146 behind poste (98 px), bote b12 at 170,145 behind poste (83 px), bote b12 at 171,143 behind poste (67 px), bote b12 at 172,142 behind poste (53 px), bote b12 at 173,141 behind poste (40 px), bote b12 at 173,140 behind poste (39 px), bote b12 at 174,138 behind poste (27 px), bote b12 at 175,137 behind poste (18 px), bote b12 at 176,136 behind poste (11 px), bote b12 at 177,134 behind poste (3 px), bote b13 at 140,143 behind muelle.postes (16 px), bote b14 at 140,143 behind muelle.postes (16 px), bote b15 at 140,140 behind muelle.postes (3 px), bote b15 at 142,147 behind muelle.postes (11 px), bote b16 at 143,142 behind muelle.postes (1 px), bote b16 at 158,165 behind poste (37 px), bote b15 at 155,166 behind poste (3 px), bote b15 at 156,165 behind poste (16 px), bote b15 at 158,164 behind poste (39 px), bote b15 at 159,162 behind poste (54 px), bote b15 at 160,161 behind poste (69 px), bote b15 at 162,159 behind poste (101 px), bote b16 at 176,165 behind poste (10 px), bote b15 at 163,158 behind poste (114 px), bote b16 at 177,164 behind poste (6 px), bote b15 at 164,157 behind poste (124 px), bote b16 at 178,162 behind poste (2 px), bote b15 at 165,155 behind poste (127 px), bote b15 at 167,154 behind poste (123 px), bote b15 at 168,152 behind poste (116 px), bote b15 at 169,151 behind poste (104 px), bote b15 at 170,150 behind poste (90 px), bote b15 at 172,148 behind poste (55 px), bote b15 at 173,147 behind poste (41 px), bote b15 at 174,145 behind poste (29 px), bote b16 at 186,149 behind juncos (2 px), bote b15 at 176,144 behind poste (11 px), bote b16 at 187,147 behind juncos (2 px), bote b15 at 177,142 behind poste (6 px), bote b15 at 178,141 behind poste (2 px), bote b10 at 163,166 behind poste (79 px), bote b10 at 164,166 behind poste (87 px), bote b10 at 165,165 behind poste (121 px), bote b10 at 166,165 behind poste (121 px), bote b10 at 167,164 behind poste (121 px), bote b10 at 169,164 behind poste (103 px), bote b10 at 170,164 behind poste (89 px), bote b10 at 171,163 behind poste (73 px), bote b10 at 172,163 behind poste (55 px), bote b10 at 173,162 behind poste (41 px), bote b10 at 174,162 behind poste (29 px), bote b10 at 175,161 behind poste (19 px), bote b10 at 176,161 behind poste (11 px), bote b10 at 177,160 behind poste (6 px), bote b10 at 178,160 behind poste (2 px), bote b10 at 187,156 behind juncos (9 px), bote b11 at 156,164 behind poste (17 px), bote b11 at 157,163 behind poste (28 px), bote b11 at 158,162 behind poste (40 px), bote b11 at 158,160 behind poste (40 px), bote b11 at 159,159 behind poste (54 px), bote b11 at 160,158 behind poste (69 px), bote b11 at 161,156 behind poste (86 px), bote b11 at 162,155 behind poste (101 px), bote b11 at 163,154 behind poste (114 px), bote b11 at 164,153 behind poste (124 px), bote b11 at 165,151 behind poste (127 px), bote b11 at 166,150 behind poste (127 px), bote b11 at 167,149 behind poste (123 px), bote b11 at 168,147 behind poste (114 px), bote b11 at 169,146 behind poste (98 px), bote b11 at 170,145 behind poste (83 px), bote b11 at 171,143 behind poste (67 px), bote b11 at 172,142 behind poste (53 px), bote b11 at 173,141 behind poste (40 px), bote b11 at 173,140 behind poste (39 px), bote b11 at 174,138 behind poste (27 px), bote b11 at 175,137 behind poste (18 px), bote b11 at 176,136 behind poste (11 px), bote b11 at 177,134 behind poste (3 px), bote b12 at 140,143 behind muelle.postes (16 px), bote b12 at 191,168 behind juncos (10 px), bote b12 at 192,167 behind juncos (16 px), bote b12 at 193,166 behind juncos (23 px), bote b12 at 195,166 behind juncos (42 px), bote b12 at 196,165 behind juncos (73 px), bote b13 at 140,140 behind muelle.postes (3 px), bote b13 at 142,147 behind muelle.postes (11 px), bote b14 at 143,142 behind muelle.postes (1 px), bote b14 at 158,165 behind poste (37 px), bote b13 at 155,166 behind poste (3 px), bote b13 at 156,165 behind poste (16 px), bote b13 at 158,164 behind poste (39 px), bote b13 at 159,162 behind poste (54 px), bote b13 at 160,161 behind poste (69 px), bote b13 at 162,159 behind poste (101 px), bote b14 at 176,165 behind poste (10 px), bote b13 at 163,158 behind poste (114 px), bote b14 at 177,164 behind poste (6 px), bote b13 at 164,157 behind poste (124 px), bote b14 at 178,162 behind poste (2 px), bote b13 at 165,155 behind poste (127 px), bote b13 at 167,154 behind poste (123 px), bote b13 at 168,152 behind poste (116 px), bote b13 at 169,151 behind poste (104 px), bote b13 at 170,150 behind poste (90 px), bote b13 at 172,148 behind poste (55 px), bote b13 at 173,147 behind poste (41 px), bote b13 at 174,145 behind poste (29 px), bote b14 at 186,149 behind juncos (2 px), bote b13 at 176,144 behind poste (11 px), bote b14 at 187,147 behind juncos (2 px), bote b13 at 177,142 behind poste (6 px), bote b13 at 178,141 behind poste (2 px), pato blanco at 136,148 behind muelle.postes (40 px), pato blanco at 136,145 behind muelle.postes (32 px), pato blanco at 135,142 behind muelle.postes (14 px), pato blanco at 178,134 behind poste (4 px), pato blanco at 178,137 behind poste (15 px), pato blanco at 179,140 behind poste (21 px), pato blanco at 180,143 behind poste (22 px), pato blanco at 180,145 behind poste (24 px), pato blanco at 181,148 behind poste (14 px), pato blanco at 182,151 behind poste (6 px), pato blanco at 182,154 behind poste (6 px), pato blanco at 183,157 behind juncos (1 px), pato blanco at 184,163 behind juncos (1 px), pato blanco at 185,166 behind juncos (4 px), pato blanco at 187,148 behind juncos (11 px), pato blanco at 187,151 behind juncos (23 px), pato blanco at 187,154 behind juncos (35 px), pato blanco at 187,157 behind juncos (42 px), pato blanco at 187,160 behind juncos (28 px), pato blanco at 186,163 behind juncos (19 px), pato blanco at 186,166 behind juncos (11 px), pato blanco at 154,166 behind poste (10 px), pato blanco at 155,166 behind poste (14 px), pato blanco at 156,166 behind poste (19 px), pato blanco at 157,166 behind poste (30 px), pato blanco at 158,166 behind poste (41 px), pato blanco at 159,165 behind poste (69 px), pato blanco at 160,165 behind poste (80 px), pato blanco at 161,165 behind poste (90 px), pato blanco at 162,165 behind poste (99 px), pato blanco at 163,165 behind poste (107 px), pato blanco at 164,165 behind poste (109 px), pato blanco at 165,165 behind poste (109 px), pato blanco at 166,165 behind poste (107 px), pato blanco at 167,165 behind poste (105 px), pato blanco at 168,165 behind poste (103 px), pato blanco at 169,165 behind poste (102 px), pato blanco at 170,165 behind poste (102 px), pato blanco at 171,165 behind poste (102 px), pato blanco at 172,165 behind poste (100 px), pato blanco at 173,165 behind poste (97 px), pato blanco at 174,166 behind poste (71 px), pato blanco at 175,166 behind poste (66 px), pato blanco at 176,166 behind poste (59 px), pato blanco at 177,166 behind poste (47 px), pato blanco at 178,166 behind poste (35 px); nobody has the deck or its pilings nearer than them",
   "bubbles: 209 bubbles at 19035 moments (each child's recorded one and \"amor\" when touched, the frog's): wholly inside the view (6 px from its edge at the least), clear of the rounds card, on no face",
   "asks: 75 distinct asks (for bote_azul, bote_rojo, bote_verde, di_azul, di_blanco, di_cual, di_nada, di_negro, di_rojo, di_verde, di_vuela, pajaro, pato_amarillo, pato_blanco, pato_negro, pez, pote_azul, pote_rojo, pote_verde): every hint frame (box +- 12) inside the view with 2 px to spare (2 at the least; the things that run off the picture by their hintBox), no frame's rings across a face where the old frame's were not (as the old: los-botes beats.11 (bote_rojo) the frog's face), the hint hand on no face; 81 answer cards, each with its lit frame and glow 4 px and more inside the view (5 at the least), 2 px clear of the rounds card and of everyone's head and body, over no duck, bird, boat, fish, bread, the post or the dock, the sun under none; 210 times a duck, a bird, a boat or the fish a learner must tell apart: whole in the view, on plain water, lawn, planks or sky, apart where the old had them apart; a boat's colour against the water 30 at the least (CIE76)",
   "NOT the scene's: the hand juego.js draws at an answer card reaches onto the frog's face where the cards are over him (respBox and hand() are the game's): at the asks for di_vuela",
   "boats to Carmen (round 3): 40163 moments of a boat arrived (slots 0 to 11), the nearest boat's hull 16.12 px from her feet at the most (keep 20), each no further from Carmen's feet than the old slot from hers + 10 px (the most: -8.8 px over the old); neighbours 6.71 px apart at the least (the old 6); the nearest 8.06 px of water from the lip; none behind the post or the reeds",
   "waterlines (round 3): piling 9 of 9 feet that show, 16 px at the least; poste 1 of 1 feet that show, 16 px at the least; junco 7 of 7 feet that show, 1 px at the least; at the reeds 7 separate dashes, the frontmost reed of each clump, each within its half width + 4 px of its foot and 2 rows (smaller than any ring); no dark patch inside a plank (each plank one tone, its edge shaded the same on every plank)",
   "mooring posts (round 3): each (tops at 40,141; 133,141) on the planks with 5 px of plank round its foot and planks over its top, its contact shadow on the planks (16 px)",
   "fish's patch (round 5): an ellipse 26 x 17 (the fish + 8 and + 6), no rim, its edge dithered into the lake over 3 px, the lake's ripple dashes inside it; the longest straight run of its edge 3 px at any Bayer phase (keep 4)",
   "fish (round 5, CIE76): at 7712 moments at the surface, the fish against the 2 px band of water just outside its outline as drawn (its patch of lighter water, 166,210,224 at its middle), the least: pardo 55 (at 126,194; against the open water 52), rojo 73 (at 126,187; against the open water 75), verde 61 (at 205,131; against the open water 61), azul 51 (at 125,189; against the open water 32); the sails against the water 61,128,163: rojo 85, azul 39, verde 67; the fish at the surface swims in its patch at every moment, out of the dock's shade; leaping, its splash (the old salpica)",
   "planks (round 3): 15 planks, their lightness 50 47 51 48 46 50 47 52 49 46 51 45 49 46 52 (CIE L*; mean 49): no two light ones side by side",
   "reeds (round 4): 24 px of the bed inside the view, its nearest feet at x 195, its tops at row 141, below the boats' row at Carmen's feet (row 140); 5 things resting in it, each 64% seen at the least, 6 px and more from the view's edge (sides)",
   "deck (round 4): 4 colours on the planks out of every shadow, none of them stray (fewer than 20 px); each plank even along its length (its lightest tone's share, quarter by quarter, within 5%); no glint on the deck, the post or a reed",
   "flower (round 4): on the right bank, whole inside the view (9 px from its right edge; the stars of its twinkle 1 px inside it), 8.49 px of lawn round its foot, lawn or the hills behind it, nobody in front of it at any of 4391 moments",
   "sky: the sun at 31,47 (radius 8), upper left, whole in the view, under no card and no board at any moment; the old picture's three clouds at 188,12; 204,34; 108,10, clear of the sun and of the corner card",
   "preview: at every step's end of the 15 recorded runs (12450 places of the children, the frog, Canelo, the ducks, the birds, the boats, the fish and the things) lago-preview.html puts everyone exactly where the sheet's rule does (0 differ); and the rule puts each of the 6850 places at rest where the port's play has them (0 differ)",
   "pairs: 22 review pictures (and the 16 level pictures, the same pictures), all zoom 2: everything in each whole with 2 px to spare, on its side of the shore and the dock (sides); what differs: pato: patos, aves; pez: patos, peces; pajaro: aves, peces, pan, the window; nada: patos, the window; vuela: aves, the window; rojo: botes; azul: peces; verde: botes; amarillo: patos; blanco: aves; negro: patos; no picture shows the dock's shade without the dock",
   "states: 1 baked state reached (every moment, pair and level picture)"
  ]
 }
}
''',
  'banco': r'''{
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
''',
  'mostrador': r'''{
 "scene": "mostrador",
 "made": "node docs/proyecto/pixel/mostrador-sheet-make.js, from mostrador-set.html (window.MOSTRADOR.CD, CF) and the design of El mostrador (version 2, with the calle state, and the orchestrator's pass 3). A new scene: no old scene, no remap.",
 "S": 26,
 "origin": {
  "originX": -7,
  "originY": -32
 },
 "picture": [240, 216],
 "view": [196, 216],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels",
  "spot": "a spot is a world point of the feet (z 0: the floor; z 1: the counter top; z .45: the seat) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite's bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog's: 1 everywhere",
  "anchor": "the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), 46 sitting (a 49-row canvas); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a small thing: its bottom middle on the point",
  "view": "a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction",
  "person": "for the check \"seen from the thighs up\": a person is 53 rows tall (the standing figure's drawn rows), at least 28 of them above the counter's top back edge at his column",
  "depth": "a spot's depth is the engine's d of its world point; front.plane turns it into the depth of each row of a character",
  "clear": "a spot keeps 4 px from the pixels the set draws for the register (part caja), the freezer (part nevera, nevera = 1) and the chair (part silla): the distance from the spot's feet pixel (column sx, row sy - 1) to the nearest such pixel. A spot of the design that was nearer moved along x by the least step of .01 that clears it: spots[name].moved says from where"
 },
 "setKey": {
  "params": {
   "donde": {
    "values": ["dentro", "calle"]
   },
   "hora": {
    "values": ["manana", "tarde"]
   },
   "atras": {
    "values": ["shut", "open"],
    "only": "dentro"
   },
   "nevera": {
    "values": [0, 1],
    "only": "dentro"
   },
   "puerta": {
    "values": ["shut", "open"],
    "only": "calle",
    "note": "the shop door seen from the street"
   },
   "props": {
    "values": [0, 1],
    "note": "props=1 draws stand-in goods on the shelves for readers' renders; the game uses 0 and draws the goods as sprites"
   }
  },
  "key": "dentro: hora + atras + nevera, e.g. \"manana-shut-0\"; calle: hora + puerta, e.g. \"manana-shut\"",
  "baked": ["?donde=dentro&hora=manana&atras=shut&nevera=0", "?donde=dentro&hora=manana&atras=shut&nevera=1", "?donde=dentro&hora=manana&atras=open&nevera=0", "?donde=dentro&hora=manana&atras=open&nevera=1", "?donde=dentro&hora=tarde&atras=shut&nevera=0", "?donde=dentro&hora=tarde&atras=shut&nevera=1", "?donde=dentro&hora=tarde&atras=open&nevera=0", "?donde=dentro&hora=tarde&atras=open&nevera=1"]
 },
 "things": {
  "nevera": {
   "set": true,
   "world": [5.1, 2.15, 1, 6, 2.7, 1.54],
   "box": [157, 107, 27, 27],
   "what": "the little freezer on the counter, only when nevera = 1: CD.NEVERA, the box colmado-dentro.js draws",
   "when": "nevera = 1"
  },
  "mostrador": {
   "set": true,
   "world": [1.3, 2, 0, 6.2, 2.85, 1],
   "box": [84, 83, 107, 77],
   "what": "the counter, a poke"
  },
  "puerta": {
   "set": true,
   "world": [0, 3.6, 0, 0.02, 5, 2.55],
   "box": [21, 51, 27, 72],
   "what": "the street door, a poke"
  },
  "silla": {
   "set": true,
   "world": [6.5, 4.1, 0, 7.3, 4.9, 1.05],
   "box": [142, 149, 30, 40],
   "what": "the waiting chair: a box round CD.SILLA, .8 wide and 1.05 high"
  },
  "leche": "sprite",
  "pan": "sprite",
  "mantequilla": "sprite",
  "queso": "sprite",
  "cafe": "sprite",
  "arroz": "sprite",
  "azucar": "sprite",
  "jugo": "sprite",
  "habichuelas": "sprite",
  "bolsa": "sprite",
  "limber_a": "sprite",
  "limber_b": "sprite",
  "quesitos": "sprite",
  "pepe": "sprite",
  "abuela": "sprite",
  "luis": "sprite",
  "carmen": "sprite",
  "senora": "sprite",
  "senor": "sprite",
  "ninos": "sprite",
  "coqui": "sprite",
  "si": "sprite",
  "no": "sprite"
 },
 "spots": {
  "pepe.mostrador": {
   "world": [3.6, 1.15, 0],
   "screen": [158, 120],
   "depth": 2.9088,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe's usual place, behind the counter"
  },
  "pepe.estante.leche": {
   "world": [1.95, 0.95, 0],
   "screen": [131, 103],
   "depth": 1.7759,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to leche"
  },
  "pepe.estante.pan": {
   "world": [2.75, 0.95, 0],
   "screen": [146, 110],
   "depth": 2.2658,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to pan"
  },
  "pepe.estante.mantequilla": {
   "world": [3.55, 0.95, 0],
   "screen": [161, 117],
   "depth": 2.7557,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to mantequilla"
  },
  "pepe.estante.queso": {
   "world": [4.35, 0.95, 0],
   "screen": [176, 125],
   "depth": 3.2456,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to queso"
  },
  "pepe.estante.cafe": {
   "world": [5.1, 0.95, 0],
   "screen": [189, 132],
   "depth": 3.7049,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to cafe"
  },
  "pepe.estante.arroz": {
   "world": [2.2, 0.95, 0],
   "screen": [136, 105],
   "depth": 1.929,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to arroz"
  },
  "pepe.estante.azucar": {
   "world": [3.1, 0.95, 0],
   "screen": [153, 113],
   "depth": 2.4801,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to azucar"
  },
  "pepe.estante.jugo": {
   "world": [4, 0.95, 0],
   "screen": [169, 122],
   "depth": 3.0312,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to jugo"
  },
  "pepe.estante.habichuelas": {
   "world": [4.9, 0.95, 0],
   "screen": [186, 130],
   "depth": 3.5824,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe in front of the shelves, reaching up to habichuelas"
  },
  "pepe.atras": {
   "world": [0.7, 0.6, 0],
   "screen": [115, 88],
   "depth": 0.7961,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe at the back door"
  },
  "pepe.fuera": {
   "drawn": false,
   "kind": "person",
   "what": "don Pepe gone through the back door: not drawn"
  },
  "pepe.silla": {
   "world": [5.2, 1.15, 0],
   "screen": [187, 134],
   "depth": 3.8886,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe sitting behind the counter with his fan (story 38)"
  },
  "coqui.frente": {
   "world": [4.4, 3.5, 0],
   "screen": [130, 149],
   "depth": 4.8377,
   "scale": 1,
   "kind": "person",
   "what": "the frog on the floor, in front of the counter, in story 36 (with abuela at abuela.frente)"
  },
  "coqui.frente2": {
   "world": [3.4, 3.7, 0],
   "screen": [107, 141],
   "depth": 4.3478,
   "scale": 1,
   "kind": "person",
   "what": "the frog's place on the floor whenever a child stands at nino.frente (story 37); an alternative of coqui.frente"
  },
  "coqui.mostrador": {
   "world": [3.45, 2.38, 1],
   "screen": [133, 107],
   "depth": 4.0701,
   "scale": 1,
   "kind": "person",
   "what": "the frog's one place on the counter top, right of the register (it casts no shadow); it may overlap the register's side shelf, not its body"
  },
  "abuela.frente": {
   "world": [3, 4.1, 0],
   "screen": [93, 141],
   "depth": 4.3478,
   "scale": 1,
   "kind": "person",
   "what": "abuela standing in front of the counter"
  },
  "abuela.silla": {
   "world": [6.9, 4.5, 0.45],
   "screen": [157, 171],
   "depth": 7.206,
   "scale": 1,
   "kind": "person",
   "what": "abuela sitting in the waiting chair (CD.SILLA); z .45 is the chair's seat top (colmado-dentro.js chairs()); the sitting sprite is anchored by her lap, rules.anchor"
  },
  "nino.frente": {
   "world": [5.2, 3.6, 0],
   "screen": [142, 157],
   "depth": 5.3889,
   "scale": 1,
   "kind": "person",
   "what": "Luis or Carmen at the counter"
  },
  "nino.puerta_dentro": {
   "world": [0.7, 5.4, 0],
   "screen": [27, 132],
   "depth": 3.7355,
   "scale": 1,
   "kind": "person",
   "what": "Carmen looking out of the street door, inside"
  },
  "cliente": {
   "world": [3.15, 3.75, 0],
   "screen": [102, 139],
   "depth": 4.2254,
   "scale": 1,
   "kind": "person",
   "what": "the customer being served (v3b: (3.15, 3.75, 0))"
  },
  "cola1": {
   "world": [2.3, 4.2, 0],
   "screen": [78, 136],
   "depth": 3.9804,
   "scale": 1,
   "kind": "person",
   "what": "waiting, first"
  },
  "cola2": {
   "world": [1.6, 4.7, 0],
   "screen": [56, 134],
   "depth": 3.8579,
   "scale": 1,
   "kind": "person",
   "what": "waiting, second"
  },
  "puerta": {
   "world": [0.45, 4.3, 0],
   "screen": [42, 120],
   "depth": 2.9088,
   "scale": 1,
   "kind": "person",
   "what": "just inside the street door"
  },
  "fuera": {
   "world": [-0.35, 4.3, 0],
   "screen": [28, 112],
   "depth": 2.4189,
   "scale": 1,
   "kind": "person",
   "what": "on the pavement, seen through the street door (no shadow)"
  },
  "ninos_puerta.1": {
   "world": [0.6, 4, 0],
   "screen": [50, 118],
   "depth": 2.8169,
   "scale": 1,
   "kind": "person",
   "what": "child 1 of the three just inside the street door, the one behind (story 38: they wait there, each with a coin); group ninos_puerta: all three heads must show (the head is the top 14 rows)"
  },
  "ninos_puerta.2": {
   "world": [1, 5.05, 0],
   "screen": [39, 132],
   "depth": 3.7049,
   "scale": 1,
   "kind": "person",
   "what": "child 2 of the three just inside the street door, in front, left (story 38: they wait there, each with a coin); group ninos_puerta: all three heads must show (the head is the top 14 rows)"
  },
  "ninos_puerta.3": {
   "world": [1.8, 4.5, 0],
   "screen": [63, 134],
   "depth": 3.8579,
   "scale": 1,
   "kind": "person",
   "what": "child 3 of the three just inside the street door, in front, right (story 38: they wait there, each with a coin); group ninos_puerta: all three heads must show (the head is the top 14 rows)"
  },
  "bandeja": {
   "world": [5.6, 2.38, 1],
   "screen": [172, 127],
   "depth": 5.3867,
   "scale": 1,
   "kind": "counter",
   "what": "the tray of quesitos"
  },
  "platillo": {
   "world": [5, 2.15, 1],
   "screen": [165, 119],
   "depth": 4.8785,
   "scale": 1,
   "kind": "counter",
   "what": "the coin dish"
  },
  "cosa_a": {
   "world": [3.6, 2.5, 1],
   "screen": [133, 110],
   "depth": 4.2355,
   "scale": 1,
   "kind": "counter",
   "what": "the first of the two things in front of the frog"
  },
  "cosa_b": {
   "world": [4.25, 2.5, 1],
   "screen": [145, 116],
   "depth": 4.6335,
   "scale": 1,
   "kind": "counter",
   "what": "the second of the two things in front of the frog"
  },
  "compra": {
   "world": [4.4, 2.5, 1],
   "screen": [148, 117],
   "depth": 4.7254,
   "scale": 1,
   "kind": "counter",
   "what": "where a thing taken down from a shelf is set"
  },
  "monedas": {
   "world": [4.6, 2.62, 1],
   "screen": [149, 120],
   "depth": 4.9213,
   "scale": 1,
   "kind": "counter",
   "what": "the first of Carmen's coins; the row runs towards +x (dir), .22 apart (step)",
   "dir": [1, 0, 0],
   "step": 0.22
  },
  "maltas": {
   "world": [5.95, 2.15, 1],
   "screen": [183, 128],
   "depth": 5.4602,
   "scale": 1,
   "kind": "counter",
   "what": "the malts"
  },
  "limber_pepe": {
   "world": [4.65, 2.45, 1],
   "screen": [153, 119],
   "depth": 4.8478,
   "scale": 1,
   "kind": "counter",
   "what": "a límber at don Pepe's end",
   "moved": {
    "from": [4.75, 2.45, 1],
    "dx": -0.1,
    "why": "it was 2 px from the caja + nevera's pixels; now 4 px (needs 4)"
   }
  },
  "limber_lejos": {
   "world": [3.95, 2.6, 1],
   "screen": [138, 114],
   "depth": 4.511,
   "scale": 1,
   "kind": "counter",
   "what": "a límber at the frog's end"
  },
  "bolsa": {
   "world": [4.45, 2.55, 1],
   "screen": [148, 118],
   "depth": 4.7866,
   "scale": 1,
   "kind": "counter",
   "what": "the bag being packed"
  },
  "estante.leche": {
   "world": [1.95, 0.19, 1.36],
   "screen": [145, 65],
   "depth": 1.9905,
   "scale": 1,
   "kind": "shelf",
   "what": "where leche stands on its shelf (the plank's top)"
  },
  "estante.pan": {
   "world": [2.75, 0.19, 1.36],
   "screen": [160, 72],
   "depth": 2.4804,
   "scale": 1,
   "kind": "shelf",
   "what": "where pan stands on its shelf (the plank's top)"
  },
  "estante.mantequilla": {
   "world": [3.55, 0.19, 1.36],
   "screen": [175, 80],
   "depth": 2.9703,
   "scale": 1,
   "kind": "shelf",
   "what": "where mantequilla stands on its shelf (the plank's top)"
  },
  "estante.queso": {
   "world": [4.35, 0.19, 1.36],
   "screen": [189, 87],
   "depth": 3.4602,
   "scale": 1,
   "kind": "shelf",
   "what": "where queso stands on its shelf (the plank's top)"
  },
  "estante.cafe": {
   "world": [5.1, 0.19, 1.36],
   "screen": [203, 94],
   "depth": 3.9195,
   "scale": 1,
   "kind": "shelf",
   "what": "where cafe stands on its shelf (the plank's top)"
  },
  "estante.arroz": {
   "world": [2.2, 0.19, 2.01],
   "screen": [150, 53],
   "depth": 2.4686,
   "scale": 1,
   "kind": "shelf",
   "what": "where arroz stands on its shelf (the plank's top)"
  },
  "estante.azucar": {
   "world": [3.1, 0.19, 2.01],
   "screen": [166, 61],
   "depth": 3.0197,
   "scale": 1,
   "kind": "shelf",
   "what": "where azucar stands on its shelf (the plank's top)"
  },
  "estante.jugo": {
   "world": [4, 0.19, 2.01],
   "screen": [183, 69],
   "depth": 3.5708,
   "scale": 1,
   "kind": "shelf",
   "what": "where jugo stands on its shelf (the plank's top)"
  },
  "estante.habichuelas": {
   "world": [4.9, 0.19, 2.01],
   "screen": [200, 78],
   "depth": 4.122,
   "scale": 1,
   "kind": "shelf",
   "what": "where habichuelas stands on its shelf (the plank's top)"
  }
 },
 "groups": {
  "ninos_puerta": ["ninos_puerta.1", "ninos_puerta.2", "ninos_puerta.3"]
 },
 "alternatives": {
  "groups": [
   ["pepe.mostrador", "pepe.silla"],
   ["coqui.mostrador", "coqui.frente", "coqui.frente2"],
   ["abuela.frente", "abuela.silla"],
   ["cliente", "abuela.frente"],
   ["coqui.frente2", "cliente"],
   ["nino.frente", "nino.puerta_dentro"]
  ],
  "vsGroup": {
   "ninos_puerta": ["nino.puerta_dentro", "cola1", "cola2"]
  },
  "what": "spots that are never in the same picture, so the people-apart and sprites-apart checks do not compare them: each list of groups is alternatives of each other (one body has one place at a time; cliente and abuela.frente: abuela is the customer of story 36, the señora of story 38 stands at cliente; coqui.frente2 and cliente never stand together: the frog of story 37 has no customer); vsGroup: the spots listed are alternatives of the whole group (ninos_puerta is together: its three children are compared with each other, never with these)"
 },
 "notes": [
  "bandeja, platillo and maltas stay where the design has them: they belong to stories without the freezer (nevera = 0), which is why they may lie under the freezer's footprint when nevera = 1 (see the info line of counter-spots-on-top)",
  "v3: the spots whose numbers the orchestrator gave (nino.frente, coqui.frente, coqui.frente2, coqui.mostrador, limber_lejos, cliente, ninos_puerta.1 to .3, the calle spots) are final and are not moved by the old clearance rule; spots-clear reports one that is nearer than 4 px and the nearest x that would pass",
  "the calle view's x0 22 is accepted by the orchestrator and final (views.calle.final)"
 ],
 "views": {
  "dentro": {
   "world": [3.2, 2.9, 0],
   "screen": [118.52, 132.07],
   "zoom": 1,
   "x0": 21,
   "region": [21, 0, 196, 216],
   "what": "inside the shop: the 196 x 216 window over the 240 x 216 picture, centred on this point (x0 = clamp(round(sx - 98), 0, 44)); donde=calle has its own picture and view (calle.views.calle)"
  }
 },
 "moved": [
  {
   "spot": "limber_pepe",
   "from": [4.75, 2.45, 1],
   "to": [4.65, 2.45, 1],
   "dx": -0.1,
   "clearBefore": 2,
   "clearAfter": 4,
   "against": "caja + nevera",
   "otherSide": null
  }
 ],
 "front": {
  "list": null,
  "how": "no list. A character is hidden by every set pixel that is nearer the camera than the character's feet (depth test against the baked depth, with the feet's depth plus 0.3), so the counter hides don Pepe's legs and nothing behind him hides him.",
  "bias": 0.3,
  "plane": "for the character's pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot's depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón's front; the same test for people, things on the counter and goods on the shelves",
  "sprites": "between two sprites the nearer pixel wins: the same depth(r), no bias"
 },
 "shadows": {
  "radius": {
   "coqui": 0.45,
   "adultos": 0.35,
   "ninos": 0.28
  },
  "byCharacter": {
   "coqui": 0.45,
   "pepe": 0.35,
   "abuela": 0.35,
   "senora": 0.35,
   "senor": 0.35,
   "luis": 0.28,
   "carmen": 0.28,
   "ninos": 0.28
  },
  "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)",
  "none": ["pepe.fuera", "fuera", "gallo"],
  "onCounter": "the frog on the counter top (z 1) casts none: the counter top is not ground in colmado-dentro.js (no slab), so a shadow has nothing to land on, and one cast at the floor under him would show in front of the counter"
 },
 "calle": {
  "what": "the state donde=calle: the shop front from the street (colmado-fuera.js, drawn by mostrador-set.html?donde=calle); its own origin, picture and view. The depth rule, the anchors and the shadows are the same as inside (the top level of this sheet)",
  "origin": {
   "originX": -46,
   "originY": -6
  },
  "picture": [240, 216],
  "view": [196, 216],
  "setKey": {
   "params": {
    "hora": {
     "values": ["manana", "tarde"]
    },
    "puerta": {
     "values": ["shut", "open"]
    }
   },
   "key": "hora + puerta, e.g. \"manana-shut\"",
   "baked": ["?donde=calle&hora=manana&puerta=shut", "?donde=calle&hora=manana&puerta=open", "?donde=calle&hora=tarde&puerta=shut", "?donde=calle&hora=tarde&puerta=open"]
  },
  "spots": {
   "abuela.acera": {
    "world": [1.2, 2.7, 0],
    "screen": [46, 138],
    "depth": 2.3883,
    "scale": 1,
    "kind": "person",
    "what": "abuela on the pavement in front of the door (v3: (1.2, 2.7, 0))"
   },
   "coqui.acera": {
    "world": [3, 2.9, 0],
    "screen": [76, 156],
    "depth": 3.613,
    "scale": 1,
    "kind": "person",
    "what": "the frog on the pavement, right of abuela (v3: (3.0, 2.9, 0))"
   },
   "puerta_calle": {
    "world": [1.65, 0.4, 0],
    "screen": [97, 121],
    "depth": 1.2554,
    "scale": 1,
    "kind": "door",
    "what": "where they go in: the middle of the shop door (x = the middle of CF.D0 .. CF.D1), on the pavement at the wall"
   },
   "gallo": {
    "world": [6.2, 1, 2.78],
    "screen": [170, 106],
    "depth": 5.7991,
    "scale": 1,
    "kind": "small",
    "what": "the rooster on the awning's front edge, at its middle (x = the middle of CF.AX0 .. CF.AX1, y = CF.AY, z = CF.AZ0); a small sprite, no shadow"
   }
  },
  "things": {
   "colmado": {
    "set": true,
    "world": [0.5, 0, 0, 2.8, 0, 3.4],
    "box": [83, 30, 43, 98],
    "what": "the shop front's door together with the sign over it: the screen box of the wall rectangle x CF.D0 - .5 .. CF.D1 + .5, z 0 .. CF.DH + .85 (the sign's top)"
   }
  },
  "views": {
   "calle": {
    "final": true,
    "zoom": 1,
    "x0": 22,
    "region": [22, 0, 196, 216],
    "what": "FINAL (accepted by the orchestrator): the 196 x 216 window over the 240 x 216 calle picture at x0 22; the check calle-in-view holds every calle spot and the colmado box inside it"
   }
  },
  "shadows": {
   "byCharacter": {
    "abuela": 0.35,
    "coqui": 0.45
   },
   "none": ["gallo", "puerta_calle"],
   "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for abuela and the frog on the pavement"
  },
  "constants": {
   "CF.D0": 1,
   "CF.D1": 2.3,
   "CF.DH": 2.55,
   "CF.AX0": 3.7,
   "CF.AX1": 8.7,
   "CF.AY": 1,
   "CF.AZ0": 2.78,
   "CF.PAVE": 4.3
  }
 },
 "checks": {
  "person": {
   "rows": 53,
   "minAbove": 28
  },
  "results": [
   {
    "name": "spots-in-view",
    "ok": true,
    "lines": [
     "spots-in-view: 46 spot points (every spot but pepe.fuera) inside the 240 x 216 picture and the dentro window [21, 217) x [0, 216)"
    ]
   },
   {
    "name": "people-apart",
    "ok": true,
    "lines": [
     "people-apart: 88 pairs of the 15 people spots that are on screen together are at least 10 px apart (closest: coqui.frente2 ~ abuela.frente 14 px, coqui.frente ~ nino.frente 14.42 px, cola1 ~ abuela.frente 15.81 px; alternatives of one body, pepe.atras and pepe.estante.* are not compared)",
     "       closest pairs: coqui.frente2 107,141 ~ abuela.frente 93,141 14 px; coqui.frente 130,149 ~ nino.frente 142,157 14.42 px; cola1 78,136 ~ abuela.frente 93,141 15.81 px; ninos_puerta.1 50,118 ~ ninos_puerta.2 39,132 17.8 px; abuela.silla 157,171 ~ nino.frente 142,157 20.52 px"
    ]
   },
   {
    "name": "things-in-view",
    "ok": true,
    "lines": [
     "things-in-view: 4 things with a box (nevera 157,107,27,27, mostrador 84,83,107,77, puerta 21,51,27,72, silla 142,149,30,40) inside the dentro window"
    ]
   },
   {
    "name": "pepe-thighs-up",
    "ok": true,
    "lines": [
     "pepe-thighs-up: 10 places: of the 53-row standing figure at least 45.75 rows above the counter's top back edge (minimum, needs 28), and 44 rows clear from the top by the depth rule",
     "       pepe.mostrador 45.75 (7.25 rows hidden under the edge at row 112.75; the set draws it at row 111; depth rule: 44 rows clear from the top, 9 hidden)",
     "       pepe.estante.leche 49.25 (3.75 rows hidden under the edge at row 99.25; the set draws it at row 98; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.pan 49.75 (3.25 rows hidden under the edge at row 106.75; the set draws it at row 105; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.mantequilla 50.25 (2.75 rows hidden under the edge at row 114.25; the set draws it at row 113; depth rule: 49 rows clear from the top, 4 hidden)",
     "       pepe.estante.queso 49.75 (3.25 rows hidden under the edge at row 121.75; the set draws it at row 120; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.cafe 49.25 (3.75 rows hidden under the edge at row 128.25; the set draws it at row 127; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.arroz 49.75 (3.25 rows hidden under the edge at row 101.75; the set draws it at row 100; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.azucar 50.25 (2.75 rows hidden under the edge at row 110.25; the set draws it at row 109; depth rule: 49 rows clear from the top, 4 hidden)",
     "       pepe.estante.jugo 49.25 (3.75 rows hidden under the edge at row 118.25; the set draws it at row 117; depth rule: 48 rows clear from the top, 5 hidden)",
     "       pepe.estante.habichuelas 49.75 (3.25 rows hidden under the edge at row 126.75; the set draws it at row 125; depth rule: 48 rows clear from the top, 5 hidden)"
    ],
    "pepe": [
     {
      "k": "pepe.mostrador",
      "above": 45.75,
      "hidden": 7.25,
      "edgeRow": 112.75,
      "drawnEdgeRow": 111,
      "byDepth": 44,
      "hiddenByDepth": 9
     },
     {
      "k": "pepe.estante.leche",
      "above": 49.25,
      "hidden": 3.75,
      "edgeRow": 99.25,
      "drawnEdgeRow": 98,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.pan",
      "above": 49.75,
      "hidden": 3.25,
      "edgeRow": 106.75,
      "drawnEdgeRow": 105,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.mantequilla",
      "above": 50.25,
      "hidden": 2.75,
      "edgeRow": 114.25,
      "drawnEdgeRow": 113,
      "byDepth": 49,
      "hiddenByDepth": 4
     },
     {
      "k": "pepe.estante.queso",
      "above": 49.75,
      "hidden": 3.25,
      "edgeRow": 121.75,
      "drawnEdgeRow": 120,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.cafe",
      "above": 49.25,
      "hidden": 3.75,
      "edgeRow": 128.25,
      "drawnEdgeRow": 127,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.arroz",
      "above": 49.75,
      "hidden": 3.25,
      "edgeRow": 101.75,
      "drawnEdgeRow": 100,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.azucar",
      "above": 50.25,
      "hidden": 2.75,
      "edgeRow": 110.25,
      "drawnEdgeRow": 109,
      "byDepth": 49,
      "hiddenByDepth": 4
     },
     {
      "k": "pepe.estante.jugo",
      "above": 49.25,
      "hidden": 3.75,
      "edgeRow": 118.25,
      "drawnEdgeRow": 117,
      "byDepth": 48,
      "hiddenByDepth": 5
     },
     {
      "k": "pepe.estante.habichuelas",
      "above": 49.75,
      "hidden": 3.25,
      "edgeRow": 126.75,
      "drawnEdgeRow": 125,
      "byDepth": 48,
      "hiddenByDepth": 5
     }
    ]
   },
   {
    "name": "goods-not-hidden",
    "ok": true,
    "lines": [
     "goods-not-hidden: 9 shelf places x 8 states of the set (hora x atras x nevera): the pixel at each point, exact and rounded, is drawn by part 'generos' (props=1 tags=1)"
    ]
   },
   {
    "name": "boxes-cover-set",
    "ok": true,
    "lines": [
     "boxes-cover-set: nevera pixels [156,107,184,132] in box [157,107,27,27]; silla pixels [146,154,167,184] in box [142,149,30,40] (1 px tolerance)"
    ]
   },
   {
    "name": "counter-spots-on-top",
    "ok": true,
    "lines": [
     "counter-spots-on-top: 11 spots at z = CH (the counter things and the frog's one) are inside the counter top x 1.3..6.2, y 2..2.85",
     "       info, not a check: under the freezer's footprint (CD.NEVERA x 5.1..6, y 2.15..2.7), so not usable while nevera = 1 (these are spots of stories without the freezer, left where the design has them): bandeja, maltas"
    ],
    "under": ["bandeja", "maltas"]
   },
   {
    "name": "spots-clear",
    "ok": true,
    "lines": [
     "spots-clear: 24 spots (counter-top ones from the register; coqui.mostrador, limber_pepe, limber_lejos also from the freezer; floor spots in front of the counter from the chair) keep at least 4 px from those pixels; nearest: nino.frente 4 px (silla), limber_pepe 4 px (caja+nevera), coqui.mostrador 15.62 px (caja+nevera)",
     "       moved from the design to clear it: limber_pepe x 4.75 -> 4.65 (-0.1, caja + nevera: 2 -> 4 px; the nearest clear place on the other side: none on the counter)",
     "       info, not a check: counter-top spots of the stories WITHOUT the freezer (nevera = 0) that lie under or within 4 px of its pixels, left where the design has them: bandeja 0 px, platillo 0 px, maltas 0 px"
    ],
    "leftNearFreezer": [
     "bandeja 0 px",
     "platillo 0 px",
     "maltas 0 px"
    ]
   },
   {
    "name": "sprites-apart",
    "ok": true,
    "lines": [
     "sprites-apart: 31 pairs in the 6 moments of the preview (m1 (pepe.mostrador, abuela.frente, coqui.frente); m2 (pepe.estante.leche, abuela.frente, coqui.frente); m3 (abuela.silla, coqui.mostrador, cliente, cola1); m4 (pepe.mostrador, nino.frente, coqui.frente2); m5 (pepe.silla, coqui.mostrador, cliente, ninos_puerta.1, ninos_puerta.2, ninos_puerta.3); m6 (abuela.acera, coqui.acera)): no two sprite boxes overlap sideways unless their feet are 12 px or more apart up-down (the frog 32 wide, grown-up 24, child 24); the pairs that do overlap sideways: m2 pepe.estante.leche ~ coqui.frente (1 px across, 46 down), m3 abuela.silla ~ coqui.mostrador (24 px across, 64 down), m4 pepe.mostrador ~ nino.frente (16 px across, 37 down), m5 ninos_puerta.1 ~ ninos_puerta.2 (11 px across, 14 down), m5 ninos_puerta.1 ~ ninos_puerta.3 (13 px across, 16 down)",
     "       closest in each moment (px across / px down): m1 pepe.mostrador ~ coqui.frente 28/29 (needs 28 across or 12 down); m2 pepe.estante.leche ~ coqui.frente 1/46 (needs 28 across or 12 down); m3 abuela.silla ~ coqui.mostrador 24/64 (needs 28 across or 12 down); m4 pepe.mostrador ~ nino.frente 16/37 (needs 24 across or 12 down); m5 ninos_puerta.1 ~ ninos_puerta.2 11/14 (needs 24 across or 12 down); m6 abuela.acera ~ coqui.acera 30/18 (needs 28 across or 12 down)"
    ],
    "pairs": [
     {
      "moment": 1,
      "a": "pepe.mostrador",
      "b": "abuela.frente",
      "across": 65,
      "down": 21,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 1,
      "a": "pepe.mostrador",
      "b": "coqui.frente",
      "across": 28,
      "down": 29,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 1,
      "a": "abuela.frente",
      "b": "coqui.frente",
      "across": 37,
      "down": 8,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 2,
      "a": "pepe.estante.leche",
      "b": "abuela.frente",
      "across": 38,
      "down": 38,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 2,
      "a": "pepe.estante.leche",
      "b": "coqui.frente",
      "across": 1,
      "down": 46,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 2,
      "a": "abuela.frente",
      "b": "coqui.frente",
      "across": 37,
      "down": 8,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "abuela.silla",
      "b": "coqui.mostrador",
      "across": 24,
      "down": 64,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "abuela.silla",
      "b": "cliente",
      "across": 55,
      "down": 32,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "abuela.silla",
      "b": "cola1",
      "across": 79,
      "down": 35,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "coqui.mostrador",
      "b": "cliente",
      "across": 31,
      "down": 32,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "coqui.mostrador",
      "b": "cola1",
      "across": 55,
      "down": 29,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "cliente",
      "b": "cola1",
      "across": 24,
      "down": 3,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.mostrador",
      "b": "nino.frente",
      "across": 16,
      "down": 37,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.mostrador",
      "b": "coqui.frente2",
      "across": 51,
      "down": 21,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "nino.frente",
      "b": "coqui.frente2",
      "across": 35,
      "down": 16,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "pepe.silla",
      "b": "coqui.mostrador",
      "across": 54,
      "down": 27,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "pepe.silla",
      "b": "cliente",
      "across": 85,
      "down": 5,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "pepe.silla",
      "b": "ninos_puerta.1",
      "across": 137,
      "down": 16,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "pepe.silla",
      "b": "ninos_puerta.2",
      "across": 148,
      "down": 2,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "pepe.silla",
      "b": "ninos_puerta.3",
      "across": 124,
      "down": 0,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "coqui.mostrador",
      "b": "cliente",
      "across": 31,
      "down": 32,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "coqui.mostrador",
      "b": "ninos_puerta.1",
      "across": 83,
      "down": 11,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "coqui.mostrador",
      "b": "ninos_puerta.2",
      "across": 94,
      "down": 25,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "coqui.mostrador",
      "b": "ninos_puerta.3",
      "across": 70,
      "down": 27,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "cliente",
      "b": "ninos_puerta.1",
      "across": 52,
      "down": 21,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "cliente",
      "b": "ninos_puerta.2",
      "across": 63,
      "down": 7,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "cliente",
      "b": "ninos_puerta.3",
      "across": 39,
      "down": 5,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "ninos_puerta.1",
      "b": "ninos_puerta.2",
      "across": 11,
      "down": 14,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "ninos_puerta.1",
      "b": "ninos_puerta.3",
      "across": 13,
      "down": 16,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "ninos_puerta.2",
      "b": "ninos_puerta.3",
      "across": 24,
      "down": 2,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 6,
      "a": "abuela.acera",
      "b": "coqui.acera",
      "across": 30,
      "down": 18,
      "needAcross": 28,
      "ok": true
     }
    ]
   },
   {
    "name": "ninos-puerta-heads",
    "ok": true,
    "lines": [
     "ninos-puerta-heads: the three heads (top 14 rows of each child) show in moment 5: ninos_puerta.1 50,118: head rows 77 to 90 (182 px, 182 shown by the set); no row covered; ninos_puerta.2 39,132: head rows 91 to 104 (244 px, 244 shown by the set); no row covered; ninos_puerta.3 63,134: head rows 93 to 106 (182 px, 182 shown by the set); no row covered"
    ],
    "heads": [
     "ninos_puerta.1 50,118: head rows 77 to 90 (182 px, 182 shown by the set); no row covered",
     "ninos_puerta.2 39,132: head rows 91 to 104 (244 px, 244 shown by the set); no row covered",
     "ninos_puerta.3 63,134: head rows 93 to 106 (182 px, 182 shown by the set); no row covered"
    ]
   },
   {
    "name": "frog-register-body",
    "ok": true,
    "lines": [
     "frog-register-body: the frog on the counter at coqui.mostrador 133,107 overlaps the register's body by 0 px (it may overlap the side shelf): moment 3 the frog at coqui.mostrador [133,107] (536 px shown, box [118,83,147,106]): 0 px on the register's body (810 px, box [87,64,120,100]; the boxes overlap 3 across, 18 down), 10 px on the side shelf (69 px); moment 5 the frog at coqui.mostrador [133,107] (536 px shown, box [118,83,147,106]): 0 px on the register's body (810 px, box [87,64,120,100]; the boxes overlap 3 across, 18 down), 10 px on the side shelf (69 px)"
    ],
    "overlap": [
     {
      "moment": 3,
      "bodyPx": 0,
      "shelfPx": 10,
      "boxOverlap": [3, 18]
     },
     {
      "moment": 5,
      "bodyPx": 0,
      "shelfPx": 10,
      "boxOverlap": [3, 18]
     }
    ]
   },
   {
    "name": "calle-in-view",
    "ok": true,
    "lines": [
     "calle-in-view: 4 spots (abuela.acera 46,138, coqui.acera 76,156, puerta_calle 97,121, gallo 170,106) and the colmado box [83,30,43,98] inside the calle picture and the calle window [22, 218) x [0, 216)"
    ]
   },
   {
    "name": "calle-people-apart",
    "ok": true,
    "lines": [
     "calle-people-apart: abuela.acera 46,138 ~ coqui.acera 76,156: 30 px sideways (needs 28); 18 px up-down"
    ]
   },
   {
    "name": "calle-abuela-clear-of-scale",
    "ok": true,
    "lines": [
     "calle-abuela-clear-of-scale: abuela.acera 46,138: her box [34,88,24,50] holds none of the 329 scale pixels (dial, chains, plate; their box columns 78..92, rows 101..135); the box is 21 px clear of them (her drawn silhouette in moment 6 is 20.62 px from the nearest)"
    ]
   },
   {
    "name": "calle-places",
    "ok": true,
    "lines": [
     "calle-places: abuela.acera and coqui.acera on the pavement (y 2.7, 2.9 <= CF.PAVE 4.3); puerta_calle x 1.65 in the door (CF.D0 .. CF.D1 = 1 .. 2.3) and inside the colmado box; gallo at x 6.2, y 1, z 2.78 (the awning's front edge, its middle) and the pixel there is the awning in all 4 calle states"
    ]
   }
  ]
 }
}
''',
  'estantes': r'''{
 "scene": "estantes",
 "made": "node docs/proyecto/pixel/estantes-sheet-make.js, from estantes-set.html (window.ESTANTES.CD) and the design of Los estantes. A new scene: no old scene, no remap.",
 "S": 26,
 "origin": {
  "originX": -222,
  "originY": -95
 },
 "picture": [240, 216],
 "view": [196, 216],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels",
  "spot": "a spot is a world point of the feet (z 0: the floor; z .3: the top of the frog's crate; z 1.46: a rung) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite's bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog's: 1 everywhere",
  "anchor": "the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); Canelo mkPerro (30 x 22): column 13 (the scenes draw it at -13), its lowest drawn row on sy - 1; a small thing standing (can, bottle, box, crate, net): its bottom middle on the point; a thing lying on the floor (a bottle box seen from above) and the drawing on the wall: its middle on the point",
  "view": "a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction",
  "depth": "a spot's depth is the engine's d of its world point; front.plane turns it into the depth of each row of a character",
  "rungs": "the ladder has seven rungs at z = LTOP * r / 8 (colmado-dentro.js), LTOP = ESCALERA_ALTO z / .75 = 2.92: 0.365, 0.73, 1.095, 1.46, 1.825, 2.19, 2.555. pepe.escalera is on the fourth, the one nearest z 1.3"
 },
 "setKey": {
  "params": {
   "anillos": {
    "values": [0, 1],
    "note": "six rings of dust on the middle shelf (story 39)"
   },
   "mesa": {
    "values": [0, 1],
    "note": "the low display table (story 40)"
   },
   "tags": {
    "values": [0, 1],
    "note": "dev only: tags each pixel by the part that drew it (the checks read it); the game does not use it"
   }
  },
  "fixed": "hora manana, atras shut, the ladder always there, no goods drawn (the goods, the cans and the bottles are sprites)",
  "key": "anillos + mesa, e.g. \"1-0\"",
  "baked": ["?anillos=0&mesa=0", "?anillos=1&mesa=0", "?anillos=0&mesa=1", "?anillos=1&mesa=1"]
 },
 "things": {
  "estante": {
   "set": true,
   "world": [10.95, 0.02, 0, 15.05, 0.4, 3.05],
   "box": [91, 45, 84, 111],
   "what": "the second run of shelves, a poke: from the uprights' outer faces, from the wall to the low cupboard's front, up to the uprights' tops (what colmado-dentro.js draws as part estantes2)"
  },
  "mesa": {
   "set": true,
   "world": [11.45, 3.2, 0, 13.15, 4.2, 0.55],
   "box": [31, 135, 50, 38],
   "what": "the low display table, a poke: the cloth's top and its hanging edges, down to the floor",
   "when": "mesa = 1"
  },
  "lata": "sprite",
  "botella": "sprite",
  "caja": "sprite",
  "red_a": "sprite",
  "red_b": "sprite",
  "di_siete": "sprite",
  "di_ocho": "sprite",
  "di_nueve": "sprite",
  "di_diez": "sprite",
  "caja_senora": "sprite",
  "caja_senor": "sprite",
  "pepe": "sprite",
  "luis": "sprite",
  "senora": "sprite",
  "senor": "sprite",
  "coqui": "sprite",
  "perro": "sprite"
 },
 "spots": {
  "pepe.pie": {
   "world": [12.3, 1.5, 0],
   "screen": [97, 140],
   "depth": 8.4507,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe at the foot of the ladder, left of it"
  },
  "pepe.escalera": {
   "world": [13, 0.8292, 1.46],
   "screen": [122, 107],
   "depth": 9.1986,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe on the ladder, his feet on the rung nearest z 1.3 (z 1.46, the fourth of seven); x and y from the ladder's line between ESCALERA_PIE and ESCALERA_ALTO"
  },
  "pepe.mesa": {
   "world": [12.9, 2.9, 0],
   "screen": [82, 158],
   "depth": 9.6755,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe behind the display table, at its right end, clear of the pyramid"
  },
  "pepe.entra": {
   "world": [10.6, 3, 0],
   "screen": [38, 138],
   "depth": 8.3283,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe coming in from the left with the big box"
  },
  "coqui.cajon": {
   "world": [15, 3.2, 0.3],
   "screen": [115, 174],
   "depth": 11.2952,
   "scale": 1,
   "kind": "person",
   "what": "the frog on his crate; the crate is a sprite .3 high under him (its bottom middle on ground)",
   "ground": {
    "world": [15, 3.2, 0],
    "screen": [115, 180],
    "depth": 11.1452
   }
  },
  "coqui.piso": {
   "world": [13.5, 4.3, 0],
   "screen": [67, 177],
   "depth": 10.9002,
   "scale": 1,
   "kind": "person",
   "what": "the frog on the floor"
  },
  "luis.piso": {
   "world": [15.4, 4.6, 0],
   "screen": [97, 197],
   "depth": 12.2474,
   "scale": 1,
   "kind": "person",
   "what": "Luis on the floor"
  },
  "luis.cajas": {
   "world": [15.4, 3.6, 0],
   "screen": [115, 188],
   "depth": 11.6351,
   "scale": 1,
   "kind": "person",
   "what": "Luis where he counts and holds a box up"
  },
  "caja_grande": {
   "world": [12.9, 2.4, 0],
   "screen": [91, 154],
   "depth": 9.3693,
   "scale": 1,
   "kind": "object",
   "what": "the big cardboard box of the delivery"
  },
  "cajon_latas": {
   "world": [13.9, 3.2, 0],
   "screen": [95, 170],
   "depth": 10.4716,
   "scale": 1,
   "kind": "object",
   "what": "the crate of cans (story 40)"
  },
  "red_a": {
   "world": [13.3, 3.4, 0.35],
   "screen": [80, 159],
   "depth": 10.4016,
   "scale": 1,
   "kind": "object",
   "what": "the first net of cans, on the crate"
  },
  "red_b": {
   "world": [14.6, 3, 0.35],
   "screen": [111, 167],
   "depth": 10.9528,
   "scale": 1,
   "kind": "object",
   "what": "the second net of cans, on the crate"
  },
  "estante.medio.0": {
   "world": [11.42, 0.19, 2.01],
   "screen": [104, 74],
   "depth": 8.1146,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 0 on the middle shelf, at the ring the set draws (x = E2X0 + 0.42); the shelf top"
  },
  "estante.medio.1": {
   "world": [11.98, 0.19, 2.01],
   "screen": [115, 80],
   "depth": 8.4576,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 1 on the middle shelf, at the ring the set draws (x = E2X0 + 0.98); the shelf top"
  },
  "estante.medio.2": {
   "world": [12.58, 0.19, 2.01],
   "screen": [126, 85],
   "depth": 8.825,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 2 on the middle shelf, at the ring the set draws (x = E2X0 + 1.58); the shelf top"
  },
  "estante.medio.3": {
   "world": [13.4, 0.19, 2.01],
   "screen": [141, 93],
   "depth": 9.3271,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 3 on the middle shelf, at the ring the set draws (x = E2X0 + 2.4); the shelf top"
  },
  "estante.medio.4": {
   "world": [14, 0.19, 2.01],
   "screen": [152, 98],
   "depth": 9.6946,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 4 on the middle shelf, at the ring the set draws (x = E2X0 + 3); the shelf top"
  },
  "estante.medio.5": {
   "world": [14.6, 0.19, 2.01],
   "screen": [163, 104],
   "depth": 10.062,
   "scale": 1,
   "kind": "shelf",
   "what": "ring place 5 on the middle shelf, at the ring the set draws (x = E2X0 + 3.6); the shelf top"
  },
  "estante.alto.0": {
   "world": [11.5, 0.19, 2.66],
   "screen": [106, 61],
   "depth": 8.4886,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 0 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.1": {
   "world": [12, 0.19, 2.66],
   "screen": [115, 65],
   "depth": 8.7948,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 1 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.2": {
   "world": [12.5, 0.19, 2.66],
   "screen": [124, 70],
   "depth": 9.101,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 2 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.3": {
   "world": [13, 0.19, 2.66],
   "screen": [134, 74],
   "depth": 9.4072,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 3 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.4": {
   "world": [13.5, 0.19, 2.66],
   "screen": [143, 79],
   "depth": 9.7134,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 4 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.5": {
   "world": [14, 0.19, 2.66],
   "screen": [152, 84],
   "depth": 10.0196,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 5 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "estante.alto.6": {
   "world": [14.5, 0.19, 2.66],
   "screen": [161, 88],
   "depth": 10.3258,
   "scale": 1,
   "kind": "shelf",
   "what": "bottle place 6 on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top"
  },
  "mesa.fila.0": {
   "world": [12.3, 3.7, 0.55],
   "screen": [56, 148],
   "depth": 10.073,
   "scale": 1,
   "kind": "table",
   "what": "the middle of row 0 of the pyramid on the table top (row 0 on the cloth, each row .3 higher)"
  },
  "mesa.fila.1": {
   "world": [12.3, 3.7, 0.85],
   "screen": [56, 141],
   "depth": 10.223,
   "scale": 1,
   "kind": "table",
   "what": "the middle of row 1 of the pyramid on the table top (row 0 on the cloth, each row .3 higher)"
  },
  "mesa.fila.2": {
   "world": [12.3, 3.7, 1.15],
   "screen": [56, 134],
   "depth": 10.373,
   "scale": 1,
   "kind": "table",
   "what": "the middle of row 2 of the pyramid on the table top (row 0 on the cloth, each row .3 higher)"
  },
  "mesa.fila.3": {
   "world": [12.3, 3.7, 1.45],
   "screen": [56, 127],
   "depth": 10.523,
   "scale": 1,
   "kind": "table",
   "what": "the middle of row 3 of the pyramid on the table top (row 0 on the cloth, each row .3 higher)"
  },
  "dibujo": {
   "world": [9.6, 0, 1.75],
   "screen": [74, 62],
   "depth": 6.7538,
   "scale": 1,
   "kind": "wall",
   "what": "the drawing pinned on the back wall, between the two runs; its middle on the point"
  },
  "cola1": {
   "world": [11, 3.4, 0],
   "screen": [38, 145],
   "depth": 8.8182,
   "scale": 1,
   "kind": "person",
   "what": "the señora waiting at the left edge"
  },
  "cola2": {
   "world": [10.5, 4.3, 0],
   "screen": [12, 149],
   "depth": 9.0631,
   "scale": 1,
   "kind": "person",
   "what": "the señor waiting at the left edge"
  },
  "entra": {
   "world": [10.4, 3.7, 0],
   "screen": [21, 143],
   "depth": 8.6345,
   "scale": 1,
   "kind": "person",
   "what": "where somebody appears coming in"
  },
  "caja_abuela": {
   "world": [14.4, 4, 0],
   "screen": [89, 182],
   "depth": 11.2677,
   "scale": 1,
   "kind": "box",
   "what": "the first bottle box of story 41, on the floor, seen from above (its middle; about 1.0 x .5, the long side along x)",
   "footprint": [1, 0.5]
  },
  "caja_senora": {
   "world": [11.3, 4.8, 0],
   "screen": [18, 161],
   "depth": 9.8592,
   "scale": 1,
   "kind": "box",
   "what": "the señora's bottle box (its middle; about 1.0 x .5, the long side along x)",
   "footprint": [1, 0.5]
  },
  "caja_senor": {
   "world": [13, 5, 0],
   "screen": [45, 178],
   "depth": 11.0227,
   "scale": 1,
   "kind": "box",
   "what": "the señor's bottle box (its middle; about 1.0 x .5, the long side along x)",
   "footprint": [1, 0.5]
  },
  "senora.caja": {
   "world": [11, 4.4, 0],
   "screen": [19, 155],
   "depth": 9.4305,
   "scale": 1,
   "kind": "person",
   "what": "the señora standing by her box"
  },
  "senor.caja": {
   "world": [12.8, 4.8, 0],
   "screen": [45, 175],
   "depth": 10.7778,
   "scale": 1,
   "kind": "person",
   "what": "the señor standing behind his box, clear of the frog: the frog is never behind a grown-up (the orchestrator's number, Nov 20)"
  },
  "perro.entra": {
   "world": [10.5, 4.2, 0],
   "screen": [14, 148],
   "depth": 9.0019,
   "scale": 1,
   "kind": "animal",
   "what": "Canelo coming in"
  },
  "perro.mesa": {
   "world": [11.7, 4.2, 0],
   "screen": [36, 159],
   "depth": 9.7367,
   "scale": 1,
   "kind": "animal",
   "what": "Canelo bumping the table"
  },
  "perro.rana": {
   "world": [15.4, 4.3, 0],
   "screen": [102, 194],
   "depth": 12.0637,
   "scale": 1,
   "kind": "animal",
   "what": "Canelo sitting beside the frog (v3b: the frog's y, x 15.4: the frog's x stepped up by .05 until his box is 4 px clear of the frog's box on the screen's right)",
   "stepped": {
    "from": 13.5,
    "step": 0.05,
    "needGap": 4,
    "gapAt": [
     {
      "x": 13.5,
      "gap": -31
     },
     {
      "x": 13.7,
      "gap": -27
     },
     {
      "x": 13.9,
      "gap": -24
     },
     {
      "x": 14.1,
      "gap": -20
     },
     {
      "x": 14.3,
      "gap": -16
     },
     {
      "x": 14.5,
      "gap": -12
     },
     {
      "x": 14.7,
      "gap": -9
     },
     {
      "x": 14.9,
      "gap": -5
     },
     {
      "x": 15.1,
      "gap": -1
     },
     {
      "x": 15.3,
      "gap": 2
     },
     {
      "x": 15.4,
      "gap": 4
     }
    ],
    "result": 15.4
   }
  },
  "puerta_lata": {
   "world": [9.8744, 4, 0],
   "screen": [6, 141],
   "depth": 8.4963,
   "scale": 1,
   "kind": "edge",
   "what": "where a can rolls out of the picture: the left edge of the window (the first column, x0) at floor level, y 4.0"
  }
 },
 "groups": {
  "estante.medio": ["estante.medio.0", "estante.medio.1", "estante.medio.2", "estante.medio.3", "estante.medio.4", "estante.medio.5"],
  "estante.alto": ["estante.alto.0", "estante.alto.1", "estante.alto.2", "estante.alto.3", "estante.alto.4", "estante.alto.5", "estante.alto.6"],
  "mesa.fila": ["mesa.fila.0", "mesa.fila.1", "mesa.fila.2", "mesa.fila.3"]
 },
 "views": {
  "wide": {
   "world": [14.1049, 2.9, 0],
   "screen": [104, 169.32],
   "zoom": 1,
   "x0": 6,
   "region": [6, 0, 196, 216],
   "what": "the one view: the 196 x 216 window over the 240 x 216 picture, x0 = clamp(round(sx - 98), 0, 44) for sx the projection of this world point (the floor point on the window's middle column, on y = 2.9). x0 = 6: the middle of the x0 values (0..11) that keep the whole run of shelves (columns 92..174), the ladder (104..138) and the table (31..80) in the window with 20 px of floor left of the table"
  }
 },
 "front": {
  "list": null,
  "how": "no list. A character is hidden by every set pixel that is nearer the camera than the character's feet (depth test against the baked depth, with the feet's depth plus 0.3), so the table hides the legs of don Pepe behind it and nothing behind a character hides him.",
  "bias": 0.3,
  "plane": "for the character's pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot's depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón's front and El mostrador's; the same test for people, the dog, the goods on the shelves and the things on the table",
  "sprites": "between two sprites the nearer pixel wins: the same depth(r), no bias",
  "after": {
   "pepe.escalera": "don Pepe on the ladder is drawn after the ladder: the pixels of the set's part escalera (the ladder) do not hide him (the depth test is skipped on them); every other set pixel still does"
  }
 },
 "shadows": {
  "radius": {
   "coqui": 0.45,
   "adultos": 0.35,
   "ninos": 0.28,
   "perro": 0.3
  },
  "byCharacter": {
   "coqui": 0.45,
   "pepe": 0.35,
   "senora": 0.35,
   "senor": 0.35,
   "luis": 0.28,
   "perro": 0.3
  },
  "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)",
  "none": ["pepe.escalera", "coqui.cajon"],
  "off_floor": "a character off the floor (don Pepe on the ladder, the frog on his crate) casts none: the spot's z is not 0 (as the frog on El mostrador's counter)"
 },
 "checks": {
  "results": [
   {
    "name": "spots-in-view",
    "ok": true,
    "lines": [
     "spots-in-view: 42 spot points inside the 240 x 216 picture and the wide window [6, 202) x [0, 216)"
    ]
   },
   {
    "name": "things-in-view",
    "ok": true,
    "lines": [
     "things-in-view: 2 things with a box (estante 91,45,84,111, mesa 31,135,50,38) inside the wide window"
    ]
   },
   {
    "name": "people-apart",
    "ok": true,
    "lines": [
     "people-apart: every pair in each group at least 12 px apart: group 1 (pepe.pie, coqui.cajon, luis.piso, cola1, cola2) least 26.31 px; group 2 (pepe.mesa, coqui.piso, luis.cajas, perro.mesa) least 24.21 px; group 3 (senora.caja, senor.caja, luis.cajas, coqui.piso) least 22.09 px",
     "       info, not a check: senor.caja 45,175 against coqui.piso 67,177: 22 px sideways, 2 rows behind the frog"
    ]
   },
   {
    "name": "frog-crate-apart-big-box",
    "ok": true,
    "lines": [
     "frog-crate-apart-big-box: coqui.cajon 115,174 is 31.24 px from caja_grande 91,154 (at least 14)"
    ]
   },
   {
    "name": "frog-floor-apart-crate-of-cans",
    "ok": true,
    "lines": [
     "frog-floor-apart-crate-of-cans: coqui.piso 67,177 is 28.86 px from cajon_latas 95,170 (at least 14)"
    ]
   },
   {
    "name": "frog-floor-apart-abuela-box",
    "ok": true,
    "lines": [
     "frog-floor-apart-abuela-box: coqui.piso 67,177 is 22.56 px from caja_abuela 89,182 (at least 14)"
    ]
   },
   {
    "name": "pepe-mesa-column-apart-pyramid",
    "ok": true,
    "lines": [
     "pepe-mesa-column-apart-pyramid: pepe.mesa's column 82 is 26 px from the pyramid's axis (mesa.fila.0, column 56) (at least 22)"
    ]
   },
   {
    "name": "perro-clear-of-frog",
    "ok": true,
    "lines": [
     "perro-clear-of-frog: perro.rana 102,194 (Canelo's box [86,172,115,193]) is 4 px clear of the frog at coqui.piso 67,177 (box [52,153,81,176]) on the screen's right (needs 4); the boxes share 5 rows; x 15.4 is the first of the frog's x 13.5 + .05 k that gives it"
    ]
   },
   {
    "name": "shelf-places",
    "ok": true,
    "lines": [
     "shelf-places: 13 places x 4 states of the set (anillos x mesa): each point, exact and rounded, is on a shelf top (part estantes2; with the rings drawn a ring pixel counts, it lies on the top; ladder off); clear of the ladder: 6 of 6 middle, 6 of 7 top; behind the ladder: estante.alto.2"
    ]
   },
   {
    "name": "pepe-escalera-in-picture",
    "ok": true,
    "lines": [
     "pepe-escalera-in-picture: rows 54..106 of his 53 (feet on row 106, top on row 54) inside rows 0..215; his 48-px canvas spans columns 98,145 of 0..239"
    ]
   },
   {
    "name": "pepe-on-rung",
    "ok": true,
    "lines": [
     "pepe-on-rung: his feet point (13,0.8292,1.46) is on a ladder pixel (part escalera) or one row above or below it, in all 4 states"
    ]
   },
   {
    "name": "bottle-boxes-apart",
    "ok": true,
    "lines": [
     "bottle-boxes-apart: the three boxes' footprints (1.0 x .5, long side along x) do not overlap each other or the table's box on screen: caja_abuela / caja_senora apart 34.53 px; caja_abuela / caja_senor apart 8.22 px; caja_abuela / mesa apart 12.33 px; caja_senora / caja_senor apart 11.51 px; caja_senora / mesa apart 5.76 px; caja_senor / mesa apart 9.04 px"
    ]
   },
   {
    "name": "view-holds-set",
    "ok": true,
    "lines": [
     "view-holds-set: x0 6: the run (columns 92,174), the ladder (104,138) and the table (31,80) are in the window 6,201, with 25 px of floor left of the table"
    ]
   },
   {
    "name": "dibujo-clear",
    "ok": true,
    "lines": [
     "dibujo-clear: the drawing's point 74,62 is inside the window, on the wall, 15.8 px from the nearest plantain pixel (needs 8)"
    ]
   },
   {
    "name": "rings-match",
    "ok": true,
    "lines": [
     "rings-match: each of the six ring places is within 1.5 px of the centre of the pixels of one of the set's six rings (distances 0: 0.47, 1: 0.66, 2: 0.66, 3: 0.22, 4: 0.69, 5: 0.95)"
    ]
   },
   {
    "name": "boxes-cover-set",
    "ok": true,
    "lines": [
     "boxes-cover-set: estante pixels [92,45,174,154] in box [91,45,84,111]; mesa pixels [31,135,80,169] in box [31,135,50,38] (1 px tolerance)"
    ]
   },
   {
    "name": "mesa-fila-on-cloth",
    "ok": true,
    "lines": [
     "mesa-fila-on-cloth: the pixel at mesa.fila.0 56,148 is drawn by part mesa (the cloth), in both states with the table"
    ]
   }
  ]
 }
}
''',
  'frutas': r'''{
 "scene": "frutas",
 "made": "node docs/proyecto/pixel/frutas-sheet-make.js, from frutas-set.html (window.FRUTAS.CF, colmado-fuera.js) and the design of Las frutas. A new scene: no old scene, no remap.",
 "S": 26,
 "origin": {
  "originX": -68,
  "originY": -10
 },
 "picture": [240, 216],
 "view": [196, 216],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels. The front wall of the shop is y = 0 (it faces +y); the pavement runs from it to y = 4.3",
  "spot": "a spot is a world point of the feet (z 0: the pavement; z 0.7: the ledge's top; z 0.34: the low crate's top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite's bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog's: 1 everywhere",
  "anchor": "the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy); the goat (a new sprite, about 30 x 24 px): its middle column on sx, its bottom edge on sy; in the pose with its neck stretched down its head is at cabra.cajon (the goat's feet stay on cabra.poste); a small thing: its bottom middle on the point; things of a row (monedas4, monedas2): the first one's bottom middle on the point, the next ones on the points .2 on along dir",
  "view": "a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction",
  "person": "for the check \"shows enough above the stand's back board\": don Pepe is 53 rows tall (mkPersona standing), at least 24 of them above the board's top edge at his column",
  "depth": "a spot's depth is the engine's d of its world point; front.plane turns it into the depth of each row of a character. Except plato and aguja, which have drawn_depth too: the set draws the scale (dial, pan, chains) at the dial's depth + .3, nearer than their world points, so a sprite on them (the needle, what lies on the pan) must use drawn_depth in front.plane or the scale's own pixels hide it",
  "footprints": "what the check \"frog-places\" takes the small things on the ledge to cover (their stand-ins in frutas-preview.html; the final art may differ): a coin 7 x 7 px; a crate 0.7 x 0.3 x 0.34 (world x, y, z: .7 wide as the design says, a ledge's depth less a hair, as high as the low crate); the basket 0.9 x 0.3 x 0.3; each box is the screen box of the thing's projected corners standing on the ledge's top at its point, the frog's is his drawn box (30 x 24)"
 },
 "setKey": {
  "params": {
   "hora": {
    "values": ["manana", "tarde"]
   },
   "puerta": {
    "values": ["shut", "open"],
    "note": "the shop door; the set's default is open"
   },
   "carro": {
    "values": [0, 1],
    "note": "don Pepe's hand cart on the pavement, left of the scale (story 44)"
   },
   "surtido": {
    "values": ["verduras", "frutas"],
    "note": "what the stand's bins hold: four bins of verduras (tomates, cebollas, papas, platanos) or three of frutas (aguacates, pinas, limones)"
   },
   "aguja": {
    "values": [
     "",
     "0",
     "medio",
     "libra"
    ],
    "note": "a red needle on the scale's dial for the readers' renders only; in the game the needle is a sprite and the baked sets have none"
   }
  },
  "key": "hora + puerta + carro + surtido, e.g. \"manana-open-0-verduras\"",
  "baked": ["?hora=manana&puerta=shut&carro=0&surtido=verduras", "?hora=manana&puerta=shut&carro=0&surtido=frutas", "?hora=manana&puerta=shut&carro=1&surtido=verduras", "?hora=manana&puerta=shut&carro=1&surtido=frutas", "?hora=manana&puerta=open&carro=0&surtido=verduras", "?hora=manana&puerta=open&carro=0&surtido=frutas", "?hora=manana&puerta=open&carro=1&surtido=verduras", "?hora=manana&puerta=open&carro=1&surtido=frutas", "?hora=tarde&puerta=shut&carro=0&surtido=verduras", "?hora=tarde&puerta=shut&carro=0&surtido=frutas", "?hora=tarde&puerta=shut&carro=1&surtido=verduras", "?hora=tarde&puerta=shut&carro=1&surtido=frutas", "?hora=tarde&puerta=open&carro=0&surtido=verduras", "?hora=tarde&puerta=open&carro=0&surtido=frutas", "?hora=tarde&puerta=open&carro=1&surtido=verduras", "?hora=tarde&puerta=open&carro=1&surtido=frutas"]
 },
 "surtidos": {
  "verduras": ["tomates", "cebollas", "papas", "platanos"],
  "frutas": ["aguacates", "pinas", "limones"]
 },
 "things": {
  "tomates": {
   "set": true,
   "world": [4, 0.95, 0.78, 5.1, 2, 1.45],
   "box": [88, 110, 41, 36],
   "what": "the bin of tomatoes (assortment verduras): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "verduras"
  },
  "cebollas": {
   "set": true,
   "world": [5.1, 0.95, 0.78, 6.2, 2, 1.45],
   "box": [108, 120, 41, 36],
   "what": "the bin of onions (assortment verduras): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "verduras"
  },
  "papas": {
   "set": true,
   "world": [6.2, 0.95, 0.78, 7.3, 2, 1.45],
   "box": [129, 131, 40, 35],
   "what": "the bin of potatoes (assortment verduras): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "verduras"
  },
  "platanos": {
   "set": true,
   "world": [7.3, 0.95, 0.78, 8.4, 2, 1.45],
   "box": [149, 141, 40, 36],
   "what": "the bin of plantains (assortment verduras): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "verduras"
  },
  "aguacates": {
   "set": true,
   "world": [4, 0.95, 0.78, 5.4667, 2, 1.45],
   "box": [88, 110, 48, 40],
   "what": "the bin of avocados (assortment frutas): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "frutas"
  },
  "pinas": {
   "set": true,
   "world": [5.4667, 0.95, 0.78, 6.9333, 2, 1.45],
   "box": [115, 124, 48, 39],
   "what": "the bin of pineapples (assortment frutas): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "frutas"
  },
  "limones": {
   "set": true,
   "world": [6.9333, 0.95, 0.78, 8.4, 2, 1.45],
   "box": [142, 137, 47, 40],
   "what": "the bin of limes (assortment frutas): the bin's space from the table's low edge to .3 above its back (CF.binBox)",
   "surtido": "frutas"
  },
  "pesa": {
   "set": true,
   "box": [56, 97, 15, 35],
   "what": "the scale, the dial and the pan together (the pole and the arm left out): the screen box of the pixels the set draws for part pesa (tags=1) from the dial's top row down and no further right than its right edge"
  },
  "guineos": {
   "set": true,
   "box": [141, 106, 10, 13],
   "what": "the hand of guineos, a poke: the screen box of the pixels the set draws for part guineos (tags=1)"
  },
  "cajon": {
   "set": true,
   "world": [8.95, 1.25, 0, 9.7, 1.95, 0.34],
   "box": [180, 184, 28, 22],
   "what": "the low crate, a poke"
  },
  "puerta": {
   "set": true,
   "world": [1, 0, 0, 2.3, 0.02, 2.55],
   "box": [70, 49, 25, 71],
   "what": "the shop door, a poke (the doorway, in either state of the door)"
  },
  "fruta_a": "sprite",
  "fruta_b": "sprite",
  "cajon_a": "sprite",
  "cajon_b": "sprite",
  "canasta": "sprite",
  "cabra": "sprite",
  "pepe": "sprite",
  "abuela": "sprite",
  "senora": "sprite",
  "coqui": "sprite"
 },
 "spots": {
  "pepe.detras": {
   "world": [6.3, 0.5, 0],
   "screen": [159, 161],
   "depth": 4.1641,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe behind the stand, between it and the wall (the stand hides him up to his waist)"
  },
  "pepe.puerta": {
   "world": [1.65, 0.35, 0],
   "screen": [76, 116],
   "depth": 1.2247,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe at the shop door"
  },
  "pepe.carro": {
   "world": [1.9, 3.35, 0],
   "screen": [25, 146],
   "depth": 3.215,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe at the hand cart's handles: (2.35, 3.35, 0) so that he is whole inside the window, or (1.9, 3.35, 0) if at 2.35 he covers more than 10 pixels of the cart's handle; `stepped` lists what each covered",
   "stepped": {
    "try": 2.35,
    "keep": 1.9,
    "maxHandlePx": 10,
    "handle": "the pixels of part carro whose world x (read back from the baked depth) is left of the bed's left end CF.CART x - .95 by more than .05: the two rails and the cross-grip",
    "tries": [
     {
      "x": 2.35,
      "coveredPx": 14,
      "handlePx": 35
     },
     {
      "x": 1.9,
      "coveredPx": 0,
      "handlePx": 35
     }
    ],
    "chosen": 1.9
   }
  },
  "pepe.pesa": {
   "world": [1.9, 2.7, 0],
   "screen": [37, 140],
   "depth": 2.8169,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe beside the scale"
  },
  "abuela.delante": {
   "world": [7.4, 4, 0],
   "screen": [115, 203],
   "depth": 6.981,
   "scale": 1,
   "kind": "person",
   "what": "abuela in front of the stand"
  },
  "abuela.junto_cabra": {
   "world": [8.7, 3, 0],
   "screen": [157, 206],
   "depth": 7.1648,
   "scale": 1,
   "kind": "person",
   "what": "abuela beside the low crate"
  },
  "repisa.izq": {
   "world": [4.6, 2.16, 0.7],
   "screen": [97, 144],
   "depth": 4.4896,
   "scale": 1,
   "kind": "frog",
   "what": "the frog on the ledge, left place (x 4.6, in the middle of the ledge's depth, z CF.LZ); the frog of stories 42, 43 and 44 (v3: two places on the ledge, not three)"
  },
  "repisa.der": {
   "world": [7.7, 2.16, 0.7],
   "screen": [154, 173],
   "depth": 6.388,
   "scale": 1,
   "kind": "frog",
   "what": "the frog on the ledge, right place (x 7.7, in the middle of the ledge's depth, z CF.LZ)"
  },
  "cabra.poste": {
   "world": [9.9, 2.35, 0],
   "screen": [191, 211],
   "depth": 7.5016,
   "scale": 1,
   "kind": "goat",
   "what": "the goat by its post, standing"
  },
  "cabra.cajon": {
   "world": [9.325, 1.6, 0.34],
   "screen": [194, 191],
   "depth": 6.8602,
   "scale": 1,
   "kind": "head",
   "what": "where the goat's head is when it eats from the low crate: the crate's top middle (the goat's feet stay on cabra.poste)"
  },
  "senora.puerta": {
   "world": [1.65, 0.25, 0],
   "screen": [78, 115],
   "depth": 1.1635,
   "scale": 1,
   "kind": "person",
   "what": "la señora leaning out of the shop door"
  },
  "monedas4": {
   "world": [5.6, 2.16, 0.7],
   "screen": [115, 154],
   "depth": 5.102,
   "scale": 1,
   "kind": "ledge",
   "what": "abuela's four coins in a row on the ledge, .2 apart (story 42); the first coin here, the row runs towards +x",
   "dir": [1, 0, 0],
   "row": {
    "n": 4,
    "step": 0.2
   }
  },
  "monedas2": {
   "world": [6.7, 2.16, 0.7],
   "screen": [135, 164],
   "depth": 5.7756,
   "scale": 1,
   "kind": "ledge",
   "what": "her two other coins, .2 apart, under the guineos (story 42)",
   "dir": [1, 0, 0],
   "row": {
    "n": 2,
    "step": 0.2
   }
  },
  "canasta": {
   "world": [7.5, 2.16, 0.7],
   "screen": [150, 171],
   "depth": 6.2655,
   "scale": 1,
   "kind": "ledge",
   "what": "abuela's basket on the ledge, lined with a cloth with three hollows (story 43)"
  },
  "cajon_a": {
   "world": [5.9, 2.16, 0.7],
   "screen": [121, 156],
   "depth": 5.2857,
   "scale": 1,
   "kind": "ledge",
   "what": "the first crate of story 44, .7 wide",
   "width": 0.7
  },
  "cajon_b": {
   "world": [6.95, 2.16, 0.7],
   "screen": [140, 166],
   "depth": 5.9287,
   "scale": 1,
   "kind": "ledge",
   "what": "the second crate of story 44, .7 wide",
   "width": 0.7
  },
  "bolsa": {
   "world": [7.9, 2.16, 0.7],
   "screen": [158, 175],
   "depth": 6.5105,
   "scale": 1,
   "kind": "ledge",
   "what": "a paper bag on the ledge"
  },
  "bajo": {
   "world": [9.325, 1.6, 0.34],
   "screen": [194, 191],
   "depth": 6.8602,
   "scale": 1,
   "kind": "point",
   "what": "where a thing lands on the low crate: its top middle"
  },
  "vuelo": {
   "world": [7.2, 2.7, 1.6],
   "screen": [135, 153],
   "depth": 6.8625,
   "scale": 1,
   "kind": "point",
   "what": "the top of the arc of a tossed thing, between the ledge and abuela's basket"
  },
  "lista": {
   "drawn": false,
   "kind": "card",
   "what": "abuela's list is a card of the game's own, not in the picture"
  },
  "plato": {
   "world": [2.75, 2.1, 0.72],
   "screen": [64, 126],
   "depth": 3.33,
   "scale": 1,
   "kind": "part",
   "what": "the scale's pan: what is weighed lies on it (CF.PESA_PLATO, the centre of the pan's top)",
   "drawn_depth": 4.12
  },
  "aguja": {
   "world": [2.75, 2.1, 1.7],
   "screen": [64, 104],
   "depth": 3.82,
   "scale": 1,
   "kind": "part",
   "what": "the scale's dial: the needle is drawn here, pointing to 12 (rest), 3 (medio) or 6 o'clock (libra) (CF.PESA_DIAL; the dial faces the camera)",
   "drawn_depth": 4.12
  },
  "guineos": {
   "screen": [146, 112],
   "box": [141, 106, 10, 13],
   "kind": "part",
   "what": "the hand of guineos hanging from the awning: the middle of the screen box of the pixels the set draws for part guineos (tags=1); no world point: the part is drawn pixel by pixel"
  }
 },
 "views": {
  "wide": {
   "world": [5.7771, 2.16, 0],
   "screen": [118.5, 170.96],
   "zoom": 1,
   "x0": 21,
   "region": [21, 0, 196, 216],
   "extent": [26, 210],
   "what": "the one view: the 196 x 216 window over the 240 x 216 picture. Its point is the ground point (at the ledge's depth) under the middle column of what the window must hold: the shop door, the scale, the whole stand, the low crate, the post and the goat at it, and the hand cart when carro = 1 (their pixels span columns 26 to 210); x0 = clamp(round(sx - 98), 0, 44), as the sheet's other views"
  }
 },
 "front": {
  "list": null,
  "how": "no list. A character is hidden by every set pixel that is nearer the camera than the character's feet (depth test against the baked depth, with the feet's depth plus 0.3), so the stand hides don Pepe behind it up to his waist, the bins and the ledge hide nothing that stands in front of them, and the goat is drawn in front of its post (the post is a hair nearer than the goat's feet, less than the .3).",
  "bias": 0.3,
  "plane": "for the character's pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot's depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador's sheet: the upright plane through the feet; the same test for people, the goat and the things on the ledge",
  "sprites": "between two sprites the nearer pixel wins: the same depth(r), no bias"
 },
 "shadows": {
  "radius": {
   "adultos": 0.35,
   "cabra": 0.4
  },
  "byCharacter": {
   "pepe": 0.35,
   "abuela": 0.35,
   "senora": 0.35,
   "cabra": 0.4
  },
  "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the pavement (z 0)",
  "none": ["repisa.izq", "repisa.der"],
  "onLedge": "the frog on the ledge casts none: the ledge is not ground (a shadow cast at the pavement under him would show in front of the stand)"
 },
 "checks": {
  "person": {
   "rows": 53,
   "minAbove": 24
  },
  "results": [
   {
    "name": "in-view",
    "ok": true,
    "lines": [
     "in-view: 22 spot points (every spot but lista) and 11 thing boxes inside the 240 x 216 picture and the wide window [21, 217) x [0, 216); in all 10 states of the set (surtido verduras and frutas, carro 0 and 1, the door shut and open, both hours) the drawn pixels of the door, the scale, the stand, its bins, the low crate and the post, and with carro = 1 the cart, are inside it (hand cart (carro = 1) pixels [26,135,91,168], pepe.carro 25,146); the goat's 30-px box at its post is inside"
    ]
   },
   {
    "name": "pepe-over-stand",
    "ok": true,
    "lines": [
     "pepe-over-stand: don Pepe at pepe.detras 159,161: of his 53 rows (top row 108) 31 are above the stand's back board at his column (the board's top edge is at row 139.72, the set draws it at row 140) and 26 of those are shown by the depth rule (needs 24; the awning hides 5 rows of his head in verduras carro 0 puerta open manana); his lowest shown row is 139, above the board; none of his shown pixels is over produce (worst of 10 states, both assortments)",
     "       info, not a check: of his 834 drawn pixels 461 show with the verduras bins (hidden: 63 by toldo, 134 by puesto, 109 by papas, 67 by platanos), 455 with the frutas bins (hidden: 63 by toldo, 29 by pinas, 161 by puesto, 126 by limones)",
     "       info, not a check: 7 of his shown pixels lie under the board's top edge (his left hand, over 7 of part puesto): the .3 of the depth rule lets a hand at the board's top edge show over it"
    ],
    "pepe": {
     "above": 31,
     "shown": 26
    }
   },
   {
    "name": "abuela-clear-of-bins",
    "ok": true,
    "lines": [
     "abuela-clear-of-bins: abuela at abuela.delante 115,203 covers no bin in either assortment",
     "       verduras: her head's top is at row 153, the ledge's front edge at her column 115 is at row 156.64 (3.64 rows above); her drawn box columns 102 to 127, rows 153 to 202; she covers no bin; she also shows over: puesto 126, ground 769",
     "       frutas: her head's top is at row 153, the ledge's front edge at her column 115 is at row 156.64 (3.64 rows above); her drawn box columns 102 to 127, rows 153 to 202; she covers no bin; she also shows over: puesto 126, ground 769"
    ]
   },
   {
    "name": "frog-places",
    "ok": true,
    "lines": [
     "frog-places: the two places are 63.95 px apart (needs 30) and in each story the frog's box clears the small things on the ledge: story 42 repisa.izq: monedas4 clear, monedas2 clear; story 43 repisa.izq: canasta clear; story 44 repisa.izq: cajon_a clear, cajon_b clear",
     "       info: the frog's boxes repisa.izq [82,120,111,143], repisa.der [139,149,168,172]; the things' boxes monedas4 [112,147,129,158], monedas2 [132,157,142,165], canasta [139,158,161,176], cajon_a [111,144,129,160], cajon_b [130,153,149,170]",
     "       info: each place against every thing, whatever the story: repisa.izq against every thing: monedas4 clear, monedas2 clear, canasta clear, cajon_a clear, cajon_b clear; repisa.der against every thing: monedas4 clear, monedas2 overlaps 4 x 9, canasta overlaps 23 x 15, cajon_a clear, cajon_b overlaps 11 x 18"
    ],
    "frog": {
     "sep": [
      ["repisa.izq", "repisa.der", 63.95]
     ],
     "story": [
      [42, "repisa.izq"],
      [43, "repisa.izq"],
      [44, "repisa.izq"]
     ],
     "hits": [
      [
       "repisa.der",
       "monedas2",
       42,
       [4, 9]
      ],
      [
       "repisa.der",
       "canasta",
       43,
       [23, 15]
      ],
      [
       "repisa.der",
       "cajon_b",
       44,
       [11, 18]
      ]
     ]
    }
   },
   {
    "name": "cajones-apart",
    "ok": true,
    "lines": [
     "cajones-apart: story 44's two crates do not overlap each other: cajon_a (x 5.9) box [111,144,129,160] and cajon_b (x 6.95) box [130,153,149,170]"
    ]
   },
   {
    "name": "goat-reach",
    "ok": true,
    "lines": [
     "goat-reach: abuela.junto_cabra 157,206 and cabra.poste 191,211 are 34.37 px apart (needs 14); the goat's head at cabra.cajon 194,191 is 3 across and 20 rows above its feet, inside its 30 x 24 box, on the low crate's top middle (z 0.34); its neck stretched down must put the head tip there",
     "       info, not a check: the goat drawn in front of the post: 0 post pixels under its box, 0 of them nearer than its plane + 0.3 (hide it)",
     "       info, not a check: cabra.poste 9.9,2.35,0 is outside the low crate's footprint (x 8.95 to 9.7, y 1.25 to 1.95)"
    ]
   },
   {
    "name": "cart-clear",
    "ok": true,
    "lines": [
     "cart-clear: carro = 1: pepe.carro 25,146 is inside the window; the cart (pixels [26,135,91,168]) is 13 px clear of abuela at abuela.delante (her pixels columns 102 to 127, rows 153 to 202; the boxes are 10 px apart; needs 10)",
     "       info, not a check: pepe.carro: tried x 2.35 (kept only if he covers at most 10 handle pixels, else 1.9): x 2.35 covers 14 of the 35 handle pixels; x 1.9 covers 0 of the 35 handle pixels -> x 1.9 (the fallback: he covers more than 10 at 2.35)",
     "       info, not a check: his drawn box at pepe.carro is columns 13 to 36, rows 93 to 145 and the window starts at column 21: 8 of his 24 columns are left of the window",
     "       info, not a check: don Pepe at pepe.carro: 834 of his 834 drawn pixels show ()"
    ]
   },
   {
    "name": "info-people",
    "ok": true,
    "lines": [
     "info-people: not a check; the share of each person's drawn pixels the set hides, by the depth rule (only the spots where something is hidden)",
     "       pepe.detras 159,161 in verduras carro 0 puerta open manana: 461 of 834 drawn pixels show (63 hidden by toldo, 134 hidden by puesto, 109 hidden by papas, 67 hidden by platanos)",
     "       pepe.puerta 76,116 in verduras carro 0 puerta open manana: 716 of 834 drawn pixels show (118 hidden by pesa)",
     "       senora.puerta 78,115 in verduras carro 0 puerta open manana: 766 of 878 drawn pixels show (112 hidden by pesa)",
     "       pepe.detras 159,161 in verduras carro 1 puerta open manana: 461 of 834 drawn pixels show (63 hidden by toldo, 134 hidden by puesto, 109 hidden by papas, 67 hidden by platanos)",
     "       pepe.puerta 76,116 in verduras carro 1 puerta open manana: 716 of 834 drawn pixels show (118 hidden by pesa)",
     "       senora.puerta 78,115 in verduras carro 1 puerta open manana: 766 of 878 drawn pixels show (112 hidden by pesa)",
     "       pepe.pesa stands -27 px right of the dial's column and 36 rows below its centre: his box columns 25 to 48, rows 87 to 139 against the dial and pan box 56, 97, 15, 35 (x, y, w, h); his shown pixels lie over 0 of the 329 pixels the set draws in the dial and pan box (carro 0), and with carro = 1 0 (the cart hides 0 of his pixels)"
    ]
   }
  ]
 }
}
''',
  'caja': r'''{
 "scene": "caja",
 "made": "node docs/proyecto/pixel/caja-sheet-make.js, from caja-set.html (window.CAJA.CD) and the design of La caja. A new scene: no old scene, no remap.",
 "S": 26,
 "origin": {
  "originX": 11,
  "originY": -30
 },
 "picture": [240, 216],
 "view": [196, 216],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels",
  "spot": "a spot is a world point of the feet (z 0: the floor; z 1: the counter top; z .96: the sill) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite's bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog's: 1 everywhere",
  "anchor": "the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), a child 41 rows (a 44-row canvas); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); a small thing: its bottom middle on the point",
  "view": "a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0, kept inside 0 .. 44. Never a fraction",
  "person": "for the check \"seen from the thighs up\": a person is 53 rows tall (the standing figure's drawn rows), at least 28 of them above the counter's top back edge at his column",
  "depth": "a spot's depth is the engine's d of its world point; front.plane turns it into the depth of each row of a character",
  "cards": "tecla_a and tecla_b have a screen box (x, y, w, h) in picture pixels and no world point: the game draws them over the picture"
 },
 "setKey": {
  "params": {
   "hora": {
    "values": ["manana", "tarde"]
   }
  },
  "key": "hora, e.g. \"tarde\" (the back door is always shut; no props, no freezer)",
  "baked": ["?hora=manana", "?hora=tarde"]
 },
 "things": {
  "caja": {
   "set": true,
   "world": [1.4, 2.05, 1, 2.75, 2.8, 2.18],
   "box": [105, 60, 39, 47],
   "what": "the register with its side shelf: the box of the set's part 'caja'"
  },
  "tecla_a": "sprite",
  "tecla_b": "sprite",
  "cosa_a": "sprite",
  "cosa_b": "sprite",
  "frasco": "sprite",
  "papel": "sprite",
  "bola": "sprite",
  "pepe": "sprite",
  "luis": "sprite",
  "carmen": "sprite",
  "senora": "sprite",
  "senor": "sprite",
  "ninos": "sprite",
  "coqui": "sprite",
  "importe": {
   "sprite": true,
   "at": "ventana_caja",
   "size": [13, 9],
   "box": [117, 75, 13, 9],
   "digits": {
    "count": 2,
    "size": [5, 7],
    "gap": 1
   },
   "what": "the amount the register shows: a sprite, a pale plate 13 x 9 with two numerals of 5 x 7 (11 wide with a 1 px gap), its middle on the screen point of spots.ventana_caja; drawn in front of the register (hidden only by a sprite nearer than the window)"
  }
 },
 "spots": {
  "pepe.caja": {
   "world": [1.925, 1, 0],
   "screen": [148, 105],
   "depth": 1.7912,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe behind the register (v3: (1.925, 1.0, 0); x is the register's middle, CD.CAJA_VENTANA[0])"
  },
  "pepe.empaca": {
   "world": [3.6, 1.2, 0],
   "screen": [175, 122],
   "depth": 2.9394,
   "scale": 1,
   "kind": "person",
   "what": "don Pepe packing bags beside the register"
  },
  "coqui.frente": {
   "world": [4.3, 3.6, 0],
   "screen": [144, 151],
   "depth": 4.8377,
   "scale": 1,
   "kind": "person",
   "what": "the frog on the floor in front of the counter, as in El mostrador (v3: not on the register's shelf and not on the counter)"
  },
  "cliente": {
   "world": [2.7, 4, 0],
   "screen": [107, 140],
   "depth": 4.1029,
   "scale": 1,
   "kind": "person",
   "what": "the customer at the register"
  },
  "cola1": {
   "world": [3.5, 4.5, 0],
   "screen": [113, 152],
   "depth": 4.899,
   "scale": 1,
   "kind": "person",
   "what": "the line, first: running away from the door"
  },
  "cola2": {
   "world": [4.3, 5, 0],
   "screen": [118, 163],
   "depth": 5.6951,
   "scale": 1,
   "kind": "person",
   "what": "the line, second"
  },
  "cola3": {
   "world": [5.1, 5.5, 0],
   "screen": [124, 175],
   "depth": 6.4911,
   "scale": 1,
   "kind": "person",
   "what": "the line, third"
  },
  "cosa_cliente": {
   "world": [2.95, 2.6, 1],
   "screen": [137, 107],
   "depth": 3.8987,
   "scale": 1,
   "kind": "counter",
   "what": "what the customer sets down; its price tag stands in front of it",
   "etiqueta": {
    "dw": [-0.05, 0.3, 0],
    "box": [11, 10]
   }
  },
  "cosa_a": {
   "world": [3.6, 2.55, 1],
   "screen": [150, 112],
   "depth": 4.2661,
   "scale": 1,
   "kind": "counter",
   "what": "the first of the two things of story 46; its price tag in front",
   "etiqueta": {
    "dw": [-0.05, 0.3, 0],
    "box": [11, 10]
   }
  },
  "cosa_b": {
   "world": [4.3, 2.55, 1],
   "screen": [163, 118],
   "depth": 4.6948,
   "scale": 1,
   "kind": "counter",
   "what": "the second of the two things of story 46; its price tag in front",
   "etiqueta": {
    "dw": [-0.05, 0.3, 0],
    "box": [11, 10]
   }
  },
  "papel": {
   "world": [5.2, 2.3, 1],
   "screen": [184, 124],
   "depth": 5.0928,
   "scale": 1,
   "kind": "counter",
   "what": "the holder of gift paper"
  },
  "taza_abuela": {
   "world": [4.85, 2.25, 1],
   "screen": [179, 121],
   "depth": 4.8478,
   "scale": 1,
   "kind": "counter",
   "what": "the cup set aside"
  },
  "frasco": {
   "world": [3.35, 2.2, 1],
   "screen": [152, 107],
   "depth": 3.8987,
   "scale": 1,
   "kind": "counter",
   "what": "the children's jar"
  },
  "clip": {
   "world": [2.275, 2.8, 1.46],
   "screen": [121, 92],
   "depth": 3.8378,
   "scale": 1,
   "kind": "face",
   "what": "the frog's bills, clipped on the register's front face at its right top corner (CD.CAJA_GAVETA: .35 to the right, .3 up)"
  },
  "ventana_caja": {
   "world": [1.925, 2.35, 1.72],
   "screen": [123, 79],
   "depth": 3.4779,
   "scale": 1,
   "kind": "window",
   "what": "the register's amount window (CD.CAJA_VENTANA): the numerals of the amount are drawn here, two digits, about 5 x 7 px each",
   "pane": [118, 75, 9, 8],
   "digits": {
    "count": 2,
    "size": [5, 7],
    "gap": 1
   }
  },
  "bola": {
   "world": [0.16, 2.3, 0.96],
   "screen": [92, 79],
   "depth": 1.9864,
   "scale": 1,
   "kind": "sill",
   "what": "the ball on the sill inside the shop window (x .16, the window's middle y, the sill's top)"
  },
  "ninos_fuera.1": {
   "world": [-0.5, 1.355, 0],
   "screen": [97, 86],
   "depth": 0.5236,
   "scale": 1,
   "kind": "person",
   "what": "child 1 of the three outside, at the shop window, seen through its panes only (no shadow); group ninos_fuera. v3: its head in the middle of the pane on the VW0 side; x -0.5, the first x of -0.4 to -1.2 (steps of 0.1) that shows zero pixels outside the panes and 20 rows or more of the child; no clip"
  },
  "ninos_fuera.2": {
   "world": [-0.3, 4.3, 0],
   "screen": [46, 115],
   "depth": 2.4495,
   "scale": 1,
   "kind": "person",
   "what": "child 2 of the three outside, in the open street doorway, looking in (no shadow); group ninos_fuera. v3b: (x, 4.3, 0), the first x of -0.3 to -0.8 (steps of 0.1) that shows 20 rows or more of him in the door opening and no pixel over the wall or the door frame: x -0.3"
  },
  "ninos_fuera.3": {
   "world": [-0.5, 2.245, 0],
   "screen": [81, 94],
   "depth": 1.0686,
   "scale": 1,
   "kind": "person",
   "what": "child 3 of the three outside, at the shop window, seen through its panes only (no shadow); group ninos_fuera. v3: its head in the middle of the pane on the VW1 side; x -0.5, the first x of -0.4 to -1.2 (steps of 0.1) that shows zero pixels outside the panes and 20 rows or more of the child; no clip"
  },
  "ninos_dentro.1": {
   "world": [1.1, 4.4, 0],
   "screen": [70, 129],
   "depth": 3.368,
   "scale": 1,
   "kind": "person",
   "what": "child 1 of the three inside; group ninos_dentro"
  },
  "ninos_dentro.2": {
   "world": [1.7, 4.9, 0],
   "screen": [72, 139],
   "depth": 4.0417,
   "scale": 1,
   "kind": "person",
   "what": "child 2 of the three inside; group ninos_dentro"
  },
  "ninos_dentro.3": {
   "world": [2.4, 5.4, 0],
   "screen": [76, 150],
   "depth": 4.7765,
   "scale": 1,
   "kind": "person",
   "what": "child 3 of the three inside; group ninos_dentro"
  },
  "puerta": {
   "world": [0.5, 4.3, 0],
   "screen": [61, 122],
   "depth": 2.9394,
   "scale": 1,
   "kind": "person",
   "what": "just inside the street door"
  },
  "tecla_a": {
   "kind": "card",
   "box": [87, 34, 30, 26],
   "what": "the first answer key, a card over the picture (the game draws it): 30 x 26 px, centred above the register with tecla_b, 10 px gap; its bottom edge is 6 px above the register's topmost pixel"
  },
  "tecla_b": {
   "kind": "card",
   "box": [127, 34, 30, 26],
   "what": "the second answer key, to the right of tecla_a"
  }
 },
 "groups": {
  "ninos_fuera": ["ninos_fuera.1", "ninos_fuera.2", "ninos_fuera.3"],
  "ninos_dentro": ["ninos_dentro.1", "ninos_dentro.2", "ninos_dentro.3"],
  "cola": ["cola1", "cola2", "cola3"]
 },
 "views": {
  "wide": {
   "zoom": 1,
   "x0": 17,
   "region": [17, 0, 196, 216],
   "needs": {
    "from": 19,
    "to": 211,
    "parts": {
     "register": [105, 143],
     "shop window": [71, 109],
     "street door (with its open leaf)": [19, 68],
     "counter": [99, 211]
    }
   },
   "what": "the 196 x 216 window over the 240 x 216 picture. x0 = clamp(round(the middle of what must be inside - 98), 0, 44): what must be inside is the register, the shop window, the street door with its open leaf and the counter (the columns of the pixels the set draws for those parts) and the floor in front of the counter (the spots pepe.empaca, coqui.frente, cliente, cola1 to cola3, ninos_dentro.1 to .3 and puerta, 12 px to each side); `needs` gives that span [from, to)"
  }
 },
 "cards": {
  "final": true,
  "centre": 122,
  "registerTop": 66,
  "bottomAbove": 6
 },
 "front": {
  "list": null,
  "how": "no list. A character is hidden by every set pixel that is nearer the camera than the character's feet (depth test against the baked depth, with the feet's depth plus 0.3), so the counter hides don Pepe's legs, nothing behind him hides him, and the wall hides the three children outside the shop window below the sill.",
  "bias": 0.3,
  "plane": "for the character's pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot's depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón's front; the same test for people and for things on the counter",
  "sprites": "between two sprites the nearer pixel wins: the same depth(r), no bias"
 },
 "shadows": {
  "radius": {
   "coqui": 0.45,
   "adultos": 0.35,
   "ninos": 0.28
  },
  "byCharacter": {
   "coqui": 0.45,
   "pepe": 0.35,
   "senora": 0.35,
   "senor": 0.35,
   "luis": 0.28,
   "carmen": 0.28,
   "ninos": 0.28
  },
  "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)",
  "none": ["ninos_fuera.1", "ninos_fuera.2", "ninos_fuera.3"]
 },
 "checks": {
  "person": {
   "rows": 53,
   "minAbove": 28
  },
  "results": [
   {
    "name": "in-view",
    "ok": true,
    "lines": [
     "in-view: 23 spot points and 4 boxes (caja 105,60,39,47, importe 117,75,13,9, tecla_a 87,34,30,26, tecla_b 127,34,30,26) inside the 240 x 216 picture and the window [17, 213) x [0, 216)",
     "       the window x0 = 17 holds what must be inside, which spans columns 19 to 211 (register 105..143, shop window 71..109, street door (with its open leaf) 19..68, counter 99..211)"
    ]
   },
   {
    "name": "people-apart",
    "ok": true,
    "lines": [
     "people-apart: 18 pairs (pepe.caja, coqui.frente, cliente, cola1, cola2, cola3; and ninos_dentro.1 to .3 with cliente) at least 12 px apart on screen (closest: cola1 ~ cola2 12.08 px, cliente ~ cola1 13.42 px, cola2 ~ cola3 13.42 px)",
     "       info, not a check: pepe.empaca (the same body as pepe.caja) is coqui.frente 42.45 px, cola1 68.88 px, cola2 70.21 px, cliente 70.34 px, cola3 73.55 px from the others"
    ]
   },
   {
    "name": "frog-sideways-apart",
    "ok": true,
    "lines": [
     "frog-sideways-apart: coqui.frente 144,151 is at least 28 px sideways from cliente and from cola1: cliente 107,140 37 px, cola1 113,152 31 px"
    ]
   },
   {
    "name": "pepe-thighs-up",
    "ok": true,
    "lines": [
     "pepe-thighs-up: pepe.caja 148,105: 48.75 of 53 rows above the counter's back edge (4.25 rows hidden under it, edge at row 100.75; needs 28); the register hides 2 of his 24 columns (8.33 %, at most 33.3 %; worst single row 8.33 %), 8 of his 834 pixels (0.96 %); by the depth rule 27 rows are clear from the top, 84 pixels hidden in all (counter and register)"
    ],
    "pepe": {
     "above": 48.75,
     "hiddenRows": 4.25,
     "edgeRow": 100.75,
     "columns": 24,
     "columnsHiddenByRegister": 2,
     "fraction": 0.0833,
     "worstRowFraction": 0.0833,
     "pixels": 834,
     "pixelsHiddenByRegister": 8,
     "rowsClearFromTop": 27
    }
   },
   {
    "name": "ninos-fuera-through-window",
    "ok": true,
    "lines": [
     "ninos-fuera-through-window: the way chosen: PLACEMENT, x -0.5, no clip. Zero pixels of the two children at the window show outside the panes (over the wall, the sill or the frame) in both hours, and each shows at least 20 rows through the glass: ninos_fuera.1 30 rows (30 from the top of the head; 331 of 600 pixels); ninos_fuera.3 30 rows (30 from the top of the head; 354 of 600 pixels) (ninos_fuera.1 -0.5,1.355,0 -> 97,86; ninos_fuera.3 -0.5,2.245,0 -> 81,94)",
     "       the x's tried, in order (outside the panes / rows through the glass of child 1, 3, in the afternoon): x -0.4 2/29 0/28 no; x -0.5 0/30 0/30 PASSES; x -0.6 0/30 0/30 PASSES; x -0.7 0/30 0/30 PASSES; x -0.8 0/26 0/29 PASSES; x -0.9 0/0 0/1 no; x -1 0/0 0/0 no; x -1.1 0/0 0/0 no; x -1.2 0/0 0/0 no",
     "       pane middles on the wall (y): 1.86, 2.75 (VW0-side pane y 1.45,2.26, mullion 2.26,2.34, VW1-side pane y 2.34,3.15); a pixel of part vitrina is glass when its world x (from the baked depth) is left of -0.25",
     "       manana ninos_fuera.1 0 px outside the panes; manana ninos_fuera.3 0 px outside the panes; tarde ninos_fuera.1 0 px outside the panes; tarde ninos_fuera.3 0 px outside the panes"
    ],
    "way": "placement",
    "ninos": {
     "x": -0.5,
     "clip": null,
     "tried": [
      {
       "x": -0.4,
       "ok": false,
       "kids": [
        {
         "outside": 2,
         "over": {
          "vitrina": 2
         },
         "rows": 29
        },
        {
         "outside": 0,
         "over": {},
         "rows": 28
        }
       ]
      },
      {
       "x": -0.5,
       "ok": true,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 30
        },
        {
         "outside": 0,
         "over": {},
         "rows": 30
        }
       ]
      },
      {
       "x": -0.6,
       "ok": true,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 30
        },
        {
         "outside": 0,
         "over": {},
         "rows": 30
        }
       ]
      },
      {
       "x": -0.7,
       "ok": true,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 30
        },
        {
         "outside": 0,
         "over": {},
         "rows": 30
        }
       ]
      },
      {
       "x": -0.8,
       "ok": true,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 26
        },
        {
         "outside": 0,
         "over": {},
         "rows": 29
        }
       ]
      },
      {
       "x": -0.9,
       "ok": false,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 0
        },
        {
         "outside": 0,
         "over": {},
         "rows": 1
        }
       ]
      },
      {
       "x": -1,
       "ok": false,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 0
        },
        {
         "outside": 0,
         "over": {},
         "rows": 0
        }
       ]
      },
      {
       "x": -1.1,
       "ok": false,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 0
        },
        {
         "outside": 0,
         "over": {},
         "rows": 0
        }
       ]
      },
      {
       "x": -1.2,
       "ok": false,
       "kids": [
        {
         "outside": 0,
         "over": {},
         "rows": 0
        },
        {
         "outside": 0,
         "over": {},
         "rows": 0
        }
       ]
      }
     ]
    }
   },
   {
    "name": "nino-fuera-in-doorway",
    "ok": true,
    "lines": [
     "nino-fuera-in-doorway: ninos_fuera.2 -0.3,4.3,0 -> 46,115 (x -0.3, the first of -0.3, -0.4, -0.5, -0.6, -0.7, -0.8 that passes): manana: 41 rows in the door opening (603 of 724 pixels), 0 px over the wall or the door frame; tarde: 41 rows in the door opening (603 of 724 pixels), 0 px over the wall or the door frame",
     "       the x's tried (rows in the opening / px over the wall or the frame, afternoon): x -0.3 41/0 PASSES; x -0.4 41/0 PASSES; x -0.5 41/0 PASSES; x -0.6 41/0 PASSES; x -0.7 41/0 PASSES; x -0.8 38/0 PASSES; a pixel of part puerta is the street when its world x (from the baked depth) is left of -0.04 (the backdrop at x -.5 and the pavement; the frame is at x .03)",
     "       info, not a check: in moment 4's finished picture what is left of each child outside: ninos_fuera.1 313 px in 27 rows (columns 91..103); ninos_fuera.2 603 px in 41 rows (columns 40..56); ninos_fuera.3 354 px in 30 rows (columns 74..87)"
    ],
    "door": {
     "x": -0.3,
     "ok": true,
     "tried": [
      {
       "x": -0.3,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 41,
       "visible": 603
      },
      {
       "x": -0.4,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 41,
       "visible": 565
      },
      {
       "x": -0.5,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 41,
       "visible": 484
      },
      {
       "x": -0.6,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 41,
       "visible": 402
      },
      {
       "x": -0.7,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 41,
       "visible": 322
      },
      {
       "x": -0.8,
       "ok": true,
       "outside": 0,
       "over": {},
       "rows": 38,
       "visible": 159
      }
     ]
    }
   },
   {
    "name": "key-cards",
    "ok": true,
    "lines": [
     "key-cards: tecla_a [87,34,30,26] and tecla_b [127,34,30,26] (30 x 26, gap 10) inside the window; clear of the frog's head box [128,126,32,25] by 66 px and of the customer's box [95,87,24,53] by 27 px; the register's topmost pixel is row 66, the cards' bottom edge row 60 (6 px above it); their middle column 122 is the middle of the register's body (its side shelf not counted)"
    ]
   },
   {
    "name": "box-covers-set",
    "ok": true,
    "lines": [
     "box-covers-set: caja pixels [105,66,142,102] in box [105,60,39,47] (1 px tolerance)"
    ]
   },
   {
    "name": "counter-spots-on-top",
    "ok": true,
    "lines": [
     "counter-spots-on-top: 6 counter-top spots (cosa_cliente, cosa_a, cosa_b, papel, taza_abuela, frasco) inside the counter top x 1.3..6.2, y 2..2.85; the clip is on the register",
     "       info, not a check: the amount window's pale pane is 9 x 8 px (at 118,75); the numerals of the design (2 digits of 5 x 7, 1 px gap) are 11 x 7 px: they do NOT fit in it (2 px too wide)"
    ],
    "window": {
     "pane": [118, 75, 9, 8],
     "digits": "11 x 7",
     "fits": false,
     "plate": [117, 75, 13, 9]
    }
   },
   {
    "name": "frog-clear-of-counter",
    "ok": true,
    "lines": [
     "frog-clear-of-counter: the frog's box [128,126,32,25] at coqui.frente 144,151 covers no pixel of cosa_cliente (176 px, 20 px clear), cosa_cliente tag (96 px, 18 px clear), cosa_a (108 px, 15 px clear), cosa_a tag (96 px, 13 px clear), cosa_b (108 px, 9 px clear), cosa_b tag (96 px, 6 px clear), papel (211 px, 16 px clear), taza_abuela (108 px, 15 px clear), frasco (144 px, 20 px clear), importe (117 px, 43 px clear)"
    ]
   },
   {
    "name": "importe-clear",
    "ok": true,
    "lines": [
     "importe-clear: in the 4 moments no pixel of any sprite that stands there covers importe's plate [117,75,13,9] (13 x 9, middle on ventana_caja 123,79, depth 3.4779): m1 6 sprites, 0 px, m2 6 sprites, 0 px, m3 7 sprites, 0 px, m4 7 sprites, 0 px"
    ]
   }
  ]
 }
}
''',
  'esquina': r'''{
 "scene": "esquina",
 "made": "node docs/proyecto/pixel/esquina-sheet-make.js, from esquina-set.html (window.ESQUINA.E, calle-base.js) and the design of La esquina (the orchestrator's p5-spec). A new scene: no old scene, no remap.",
 "S": 26,
 "origin": {
  "originX": 30,
  "originY": -8
 },
 "picture": [240, 216],
 "view": [196, 216],
 "rules": {
  "project": "pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY (here OX 150, OY 100). That is sx = OX + (x - y) * 18.38, sy = OY + (x + y) * 9.19 - z * 22.5. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)] (clipped to the picture where the thing says so). screen is the projection rounded to whole pixels. The colmado's front wall is y = 0 (it faces +y); its pavement runs y 0 to 1.6, the street A from y 1.8 to 5.8 (lanes at y 2.8 far, 4.8 near), the near pavement from y 6 to 8.6",
  "spot": "a spot is a world point of the feet (z 0: the pavement or the street; z .3: the top of the obrero's bucket) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite's bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog's: 1 everywhere. A thing that drives: its spot is the middle of its floor",
  "anchor": "the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy); the obrero sitting on his bucket (obrero.cubo): the sitting persona (mkPersona with sent = 1), column 24 and the row of his hips, 38, on (sx, sy), the spot being the bucket's top (as abuela sitting in El mostrador: lap row on the spot); the bebé on an arm is a part of the carrier's sprite; a cone, the bucket, a bicycle: its bottom middle on the point; a car, a guagua: the pixels the set draws for it (its autos= parameter), the spot being the middle of its floor (spots[name].drawn is their screen box)",
  "view": "a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction",
  "depth": "a spot's depth is the engine's d of its world point; front.plane turns it into the depth of each row of a character. The cars and the guagua are baked into the set (autos=), so the same rule puts them in front of a person standing behind them",
  "nearest": "the make's lines \"nearest passing\": where a number of the spec fails a check, the least move of one spot along x or y (steps of .01, up to 3, either way, staying on its own strip: the colmado's pavement y .1 to 1.6, the street y 1.8 to 5.8, the near pavement y 5.8 to 8.6) that passes it. The spec's numbers are kept in the sheet",
  "widths": "the sprite boxes the checks use: the frog 32 wide, a grown-up 24, a child 24 (the spec; the dog's 28 is not used here), the feet's spot in the middle of the bottom edge; a car or a guagua is the pixels the set draws; a cone, a bicycle, a lamp, the button: the point only (the spec gives no size)"
 },
 "setKey": {
  "params": {
   "hora": {
    "values": ["manana", "tarde"]
   },
   "obra": {
    "values": [0, 1],
    "note": "the dug-up far lane with its cones, no stripes, and the two squares of cement in the near pavement (story 50)"
   },
   "puerta": {
    "values": ["shut", "open"],
    "note": "the colmado's door; the set's default is shut"
   },
   "autos": {
    "note": "for the readers' renders and the preview only: \"kind@x,y,heading\" joined by \";\" (carro, azul, guagua; i = to -x, d = to +x). In the game things that drive are sprites and the baked sets have none"
   },
   "t": {
    "note": "wind time, 0 for the reference"
   }
  },
  "key": "hora + obra + puerta, e.g. \"manana-0-shut\"",
  "baked": ["?hora=manana&obra=0&puerta=shut", "?hora=manana&obra=0&puerta=open", "?hora=manana&obra=1&puerta=shut", "?hora=manana&obra=1&puerta=open", "?hora=tarde&obra=0&puerta=shut", "?hora=tarde&obra=0&puerta=open", "?hora=tarde&obra=1&puerta=shut", "?hora=tarde&obra=1&puerta=open"]
 },
 "things": {
  "colmado": {
   "set": true,
   "world": [-10, -9, 0, 0, 0, 3.5],
   "box": [0, 0, 240, 100],
   "what": "the building: the screen box of the pixels the set draws for the parts colmado, puerta and vitrina (its front wall, its top, the side wall, the door, the shop window and its awning); its world box is the block x -10 to 0, y -9 to 0, up to E.WH. It runs off the picture at the left and at the top: a touch on the door (puerta) wins over it"
  },
  "puerta": {
   "set": true,
   "world": [-2.5, 0, 0, -1.2, 0.02, 2.55],
   "box": [103, 19, 25, 71],
   "what": "the colmado's door, a poke (the doorway, in either state of the door)"
  },
  "boton": {
   "set": true,
   "world": [1.54, 1.52, 0.62, 1.78, 1.66, 0.98],
   "box": [147, 106, 8, 12],
   "what": "the button box on the pole (the yellow box with the red button, the pole's box(x - .12, y + .02, .62, x + .12, y + .16, .98) of calle-base.js trafficLight): where he touches to press"
  },
  "calle": {
   "set": true,
   "world": [-9, 1.8, 0, 9, 5.8, 0],
   "box": [0, 33, 240, 183],
   "what": "the street's asphalt, the whole of street A from the colmado's kerb to the near kerb, as far as the set builds it (x -9 to 9); with obra = 1 the hole is part of it"
  },
  "esquina": {
   "set": true,
   "world": [0, 0, 0, 1.6, 1.6, 0],
   "box": [120, 100, 60, 30],
   "what": "the corner: the colmado's pavement from x 0 to 1.6 (y 0 to 1.6), where the pole stands"
  },
  "cemento": {
   "set": true,
   "world": [1.2, 6.15, 0, 2.2, 7.05, 0],
   "box": [42, 167, 36, 19],
   "what": "the wet square of cement (obra = 1), the one with three cones round it",
   "when": "obra = 1"
  },
  "gente": "sprite",
  "carro": "sprite",
  "azul": "sprite",
  "guagua": "sprite",
  "bicicleta": "sprite",
  "abuela": "sprite",
  "bebe": "sprite",
  "mama": "sprite",
  "papa": "sprite",
  "luis": "sprite",
  "carmen": "sprite",
  "senora": "sprite",
  "senor": "sprite",
  "pepe": "sprite",
  "obrero": "sprite",
  "coqui": "sprite"
 },
 "spots": {
  "puerta": {
   "world": [-1.85, 0.35, 0],
   "screen": [110, 86],
   "depth": -0.9186,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "at the colmado's door, in front of it: abuela coming out (story 49 opening, before the group is there: an alternative of pepe.puerta)"
  },
  "pepe.puerta": {
   "world": [-1.85, 0.3, 0],
   "screen": [110, 86],
   "depth": -0.9492,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "don Pepe at the colmado's door with his broom (story 49; an alternative of puerta)"
  },
  "esquina": {
   "world": [0.5, 1.25, 0],
   "screen": [136, 116],
   "depth": 1.0717,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "the frog at the corner, always (story 49; there is no esquina2)"
  },
  "boton_coqui": {
   "world": [1.1, 1.2, 0],
   "screen": [148, 121],
   "depth": 1.4085,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "the frog while he presses the button on the pole (the pole may hide him: he is pressing its button)"
  },
  "boton": {
   "world": [1.66, 1.665, 0.8],
   "screen": [150, 113],
   "depth": 2.4361,
   "scale": 1,
   "kind": "point",
   "what": "the button on the pole: E.LUZ.button (the red disc on the yellow box, at frog height)"
  },
  "bordillo1": {
   "world": [-1.1, 1.35, 0],
   "screen": [105, 102],
   "depth": 0.1531,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "at the kerb, the first of the two (story 49: in the opening la señora; in the game one of la señora, el señor, Luis, Carmen)"
  },
  "bordillo2": {
   "world": [-2.7, 1.35, 0],
   "screen": [76, 88],
   "depth": -0.8267,
   "scale": 1,
   "kind": "person",
   "who": "nino",
   "what": "at the kerb, the second (story 49: in the opening Luis, the child in front)"
  },
  "fondo1": {
   "world": [-0.3, 0.45, 0],
   "screen": [136, 101],
   "depth": 0.0919,
   "scale": 1,
   "kind": "person",
   "who": "nino",
   "what": "behind the kerb row, right: Carmen in the opening of story 49"
  },
  "fondo2": {
   "world": [-3.4, 0.5, 0],
   "screen": [78, 73],
   "depth": -1.7759,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "behind the kerb row, left: el señor in the opening of story 49 (the grown-up behind)"
  },
  "vuelta": {
   "world": [0.8, -2.2, 0],
   "screen": [205, 87],
   "depth": -0.8573,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "where somebody who goes round the corner leaves the picture (an exit: only its point has to be in the window); he walks along the pavement to (0.8, 0.2, 0), then up the side wall to here",
   "exit": true,
   "path": [
    {
     "world": [0.8, 0.2, 0],
     "screen": [161, 109]
    },
    {
     "world": [0.8, -2.2, 0],
     "screen": [205, 87]
    }
   ]
  },
  "acera1": {
   "world": [0.5, 6.5, 0],
   "screen": [40, 164],
   "depth": 4.2866,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "back row 1: papá or mamá (stories 48 and 49: mamá with the bebé on her arm: enfrente)"
  },
  "acera2": {
   "world": [2.1, 6.5, 0],
   "screen": [69, 179],
   "depth": 5.2664,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "back row 2: abuela with the bebé on her arm (story 48), the one who crossed (story 49: cruce_fin), abuela (the ending of story 49)"
  },
  "acera3": {
   "world": [3.7, 6.5, 0],
   "screen": [99, 194],
   "depth": 6.2462,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "back row 3: mamá or papá (the end of story 48)"
  },
  "acera4": {
   "world": [5.3, 6.5, 0],
   "screen": [128, 208],
   "depth": 7.226,
   "scale": 1,
   "kind": "person",
   "who": "nino",
   "what": "back row 4: Luis with his bicycle (story 48)"
  },
  "acera5": {
   "world": [2.4, 7.9, 0],
   "screen": [49, 195],
   "depth": 6.3074,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "front row 5: the frog (the start of story 48, the ending of story 49)"
  },
  "acera6": {
   "world": [4, 7.9, 0],
   "screen": [78, 209],
   "depth": 7.2872,
   "scale": 1,
   "kind": "person",
   "who": "nino",
   "what": "front row 6: Luis (story 50)"
  },
  "enfrente": {
   "world": [0.5, 6.5, 0],
   "screen": [40, 164],
   "depth": 4.2866,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "mamá, with the bebé on her arm, on the near pavement (story 49): the same place as acera1",
   "alias": "acera1"
  },
  "cruce_fin": {
   "world": [2.1, 6.5, 0],
   "screen": [69, 179],
   "depth": 5.2664,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "where somebody who crossed ends and waves (story 49): the same place as acera2",
   "alias": "acera2"
  },
  "para48_carro": {
   "world": [0.7, 4.8, 0],
   "screen": [75, 151],
   "depth": 3.368,
   "scale": 1,
   "kind": "vehicle",
   "what": "story 48: where the car stops, the middle of its floor, in the near lane, heading to -x",
   "sprite": "carro",
   "heading": "i",
   "drawn": [44, 113, 104, 161],
   "drawn_px": 1941
  },
  "para48_guagua": {
   "world": [4.5, 4.8, 0],
   "screen": [144, 185],
   "depth": 5.6951,
   "scale": 1,
   "kind": "vehicle",
   "what": "story 48: where the guagua stops, the middle of its floor, in the near lane behind the car, heading to -x",
   "sprite": "guagua",
   "heading": "i",
   "drawn": [92, 110, 196, 204],
   "drawn_px": 6541
  },
  "sale_carro": {
   "world": [0.7, 5.9, 0],
   "screen": [54, 161],
   "depth": 4.0417,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "where somebody gets out of the car (mamá, papá), on the kerb stone beside it; he walks to acera3 (mamá) or acera1 (papá)"
  },
  "sale_guagua": {
   "world": [3.05, 5.9, 0],
   "screen": [98, 182],
   "depth": 5.4807,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "where somebody gets out of the guagua (its front door), on the kerb stone beside it; he walks to acera3 (mamá) or acera1 (papá)"
  },
  "toca_carro": {
   "world": [1.3, 6.05, 0],
   "screen": [63, 168],
   "depth": 4.5009,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "the frog knocks at the car, on the near pavement beside the kerb"
  },
  "toca_guagua": {
   "world": [3.6, 6.05, 0],
   "screen": [105, 189],
   "depth": 5.9094,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "the frog knocks at the guagua, on the near pavement beside the kerb"
  },
  "alto_carro": {
   "world": [3.5, 4.8, 0],
   "screen": [126, 176],
   "depth": 5.0827,
   "scale": 1,
   "kind": "vehicle",
   "what": "story 49: where the car stops at the stop line, the middle of its floor, in the near lane, heading to -x (its front at x 2.4, the stop line at x 2.2); the guagua stops behind it",
   "sprite": "carro",
   "heading": "i",
   "drawn": [95, 139, 156, 187],
   "drawn_px": 1971
  },
  "alto_guagua": {
   "world": [7, 4.8, 0],
   "screen": [190, 208],
   "depth": 7.226,
   "scale": 1,
   "kind": "vehicle",
   "what": "story 49: where the guagua stops, the middle of its floor, in the near lane behind the car, heading to -x (its front at x 4.5)",
   "sprite": "guagua",
   "heading": "i",
   "drawn": [138, 133, 242, 227],
   "drawn_px": 6549
  },
  "carril_a.carro": {
   "world": [-0.9, 4.8, 0],
   "screen": [45, 136],
   "depth": 2.3883,
   "scale": 1,
   "kind": "vehicle",
   "what": "carril_a, the left end of the one lane (the near lane): a car's middle, heading to +x; the guagua never waits here",
   "sprite": "azul",
   "heading": "d",
   "drawn": [14, 97, 75, 146],
   "drawn_px": 1978
  },
  "carril_a.bici": {
   "world": [-0.5, 4.8, 0],
   "screen": [53, 140],
   "depth": 2.6332,
   "scale": 1,
   "kind": "vehicle",
   "what": "carril_a: a bicycle's middle, heading to +x (an alternative of the car; the set has no bicycle: a sprite)",
   "sprite": "bici",
   "heading": "d"
  },
  "carril_b.carro": {
   "world": [5.1, 4.8, 0],
   "screen": [156, 191],
   "depth": 6.0625,
   "scale": 1,
   "kind": "vehicle",
   "what": "carril_b, the right end of the one lane: a car's middle, heading to -x",
   "sprite": "carro",
   "heading": "i",
   "drawn": [125, 154, 185, 202],
   "drawn_px": 1950
  },
  "carril_b.guagua": {
   "world": [6.3, 4.8, 0],
   "screen": [178, 202],
   "depth": 6.7973,
   "scale": 1,
   "kind": "vehicle",
   "what": "carril_b: the guagua's middle, heading to -x",
   "sprite": "guagua",
   "heading": "i",
   "drawn": [125, 127, 229, 221],
   "drawn_px": 6536
  },
  "carril_b.bici": {
   "world": [4.5, 4.8, 0],
   "screen": [144, 185],
   "depth": 5.6951,
   "scale": 1,
   "kind": "vehicle",
   "what": "carril_b: a bicycle's middle, heading to -x (the set has no bicycle: a sprite)",
   "sprite": "bici",
   "heading": "i"
  },
  "obrero.paleta": {
   "world": [3.2, 3.6, 0],
   "screen": [143, 163],
   "depth": 4.1641,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "the obrero at the lane with his paddle, on the street at the hole's right end",
   "street": true
  },
  "obrero.cubo": {
   "world": [5.3, 6.5, 0.3],
   "screen": [128, 202],
   "depth": 7.376,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "the obrero sitting on his bucket (a sprite; its top is z .3); the sitting sprite is anchored by his lap row on the spot's row (rules.anchor)",
   "seated": true
  },
  "coqui.cerca": {
   "world": [3.1, 6.1, 0],
   "screen": [95, 185],
   "depth": 5.6338,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "story 50: the frog near the cement, on the pavement right of the wet square"
  },
  "coqui.cemento": {
   "world": [1.7, 6.6, 0],
   "screen": [60, 176],
   "depth": 5.0827,
   "scale": 1,
   "kind": "frog",
   "who": "coqui",
   "what": "the frog on the wet square (the ending of story 50)"
  },
  "luis.cemento": {
   "world": [0.5, 6.5, 0],
   "screen": [40, 164],
   "depth": 4.2866,
   "scale": 1,
   "kind": "person",
   "who": "nino",
   "what": "Luis kneeling behind and left of the frog, on the old dry square (the ending of story 50; the preview's stand-in is the sitting persona)"
  },
  "obrero.fin": {
   "world": [3.9, 6.5, 0],
   "screen": [102, 196],
   "depth": 6.3687,
   "scale": 1,
   "kind": "person",
   "who": "adulto",
   "what": "the obrero standing in the ending of story 50"
  },
  "cono1": {
   "world": [1.1, 6.05, 0],
   "screen": [59, 166],
   "depth": 4.3785,
   "scale": 1,
   "kind": "small",
   "what": "a cone round the wet square (a sprite)"
  },
  "cono2": {
   "world": [2.3, 6.05, 0],
   "screen": [81, 177],
   "depth": 5.1133,
   "scale": 1,
   "kind": "small",
   "what": "a cone round the wet square (a sprite); the one that is knocked over (in a wrong move, and in the ending of story 50)"
  },
  "cono3": {
   "world": [2.35, 7.15, 0],
   "screen": [62, 187],
   "depth": 5.8175,
   "scale": 1,
   "kind": "small",
   "what": "a cone round the wet square (a sprite)"
  },
  "lamps.1": {
   "world": [1.66, 1.625, 3.27],
   "screen": [151, 57],
   "depth": 3.6466,
   "scale": 1,
   "kind": "point",
   "what": "a lamp of the traffic light, from E.LUZ.lamps, top to bottom: red; the lit lamp is a sprite",
   "lamp": "red"
  },
  "lamps.2": {
   "world": [1.66, 1.625, 2.88],
   "screen": [151, 65],
   "depth": 3.4516,
   "scale": 1,
   "kind": "point",
   "what": "a lamp of the traffic light, from E.LUZ.lamps, top to bottom: amber; the lit lamp is a sprite",
   "lamp": "amber"
  },
  "lamps.3": {
   "world": [1.66, 1.625, 2.49],
   "screen": [151, 74],
   "depth": 3.2566,
   "scale": 1,
   "kind": "point",
   "what": "a lamp of the traffic light, from E.LUZ.lamps, top to bottom: green; the lit lamp is a sprite",
   "lamp": "green"
  }
 },
 "groups": {
  "grupo": ["bordillo1", "bordillo2", "fondo1", "fondo2"],
  "bordillo": ["bordillo1", "bordillo2"],
  "fila_atras": ["acera1", "acera2", "acera3", "acera4"],
  "fila_delante": ["acera5", "acera6"],
  "lamps": ["lamps.1", "lamps.2", "lamps.3"],
  "conos": ["cono1", "cono2", "cono3"]
 },
 "alternatives": {
  "groups": [
   ["puerta", "pepe.puerta"],
   ["esquina", "boton_coqui"],
   ["sale_carro", "sale_guagua"],
   ["toca_carro", "toca_guagua"],
   ["para48_carro", "alto_carro"],
   ["para48_guagua", "alto_guagua"],
   ["carril_a.carro", "carril_a.bici"],
   ["carril_b.carro", "carril_b.guagua", "carril_b.bici"]
  ],
  "vsGroup": {},
  "aliases": {
   "enfrente": "acera1",
   "cruce_fin": "acera2"
  },
  "what": "spots that are never in the same picture: each list is alternatives of each other (puerta and pepe.puerta: abuela comes out before the group is there; esquina and boton_coqui: the frog stands at one or the other; the cars of story 48 and of story 49; the car, the guagua and the bicycle of one end of the lane). aliases: enfrente is the place acera1, cruce_fin the place acera2 (the spec's own names for them)"
 },
 "routes": {
  "trafico": {
   "what": "traffic passing along street A: it enters at the right and leaves at the left, in its lane; in story 49 it stops at the stop line at alto_carro and alto_guagua. These points are outside the picture on purpose: they are exits, where a sprite enters and leaves, not spots",
   "lanes": {
    "lejos": {
     "entra": {
      "world": [9.5, 2.8, 0],
      "screen": [273, 213]
     },
     "sale": {
      "world": [-6, 2.8, 0],
      "screen": [-12, 71]
     }
    },
    "cerca": {
     "entra": {
      "world": [9.5, 4.8, 0],
      "screen": [236, 231]
     },
     "sale": {
      "world": [-6, 4.8, 0],
      "screen": [-49, 89]
     }
    }
   }
  }
 },
 "notes": [
  "second pass: the spots are the orchestrator's new ones (the near pavement now runs to y 8.6, the park's wall); cola1 to cola4, esquina2, abuela.acera, coqui.acera, luis.bici, junto, papa.acera, abuela.enfrente, coqui.enfrente, para_carro, para_guagua and luis.obra are gone",
  "things.gente is a sprite key (the spec gives no box): the people at the kerb, who are the members of the group grupo (bordillo1, bordillo2, fondo1, fondo2) in the opening of story 49 and of the group bordillo in its game",
  "the section of the spec for La esquina has no \"step until\" rule: every number in it is kept as given, and where it fails a check the make says so and gives the nearest value that passes (rules.nearest)",
  "the preview gives moments 1 to 6 the afternoon and 7 and 8 the morning (the scripts' hours), the door shut in all; obra = 1 in 7 and 8; the middle cone is knocked over in moment 8"
 ],
 "views": {
  "wide": {
   "world": [1.6243, 3.8, 0],
   "screen": [110, 149.86],
   "zoom": 1,
   "x0": 12,
   "region": [12, 0, 196, 216],
   "what": "the one view: the 196 x 216 window over the 240 x 216 picture, centred on this point (on the street's middle line y 3.8), x0 = clamp(round(sx - 98), 0, 44). x0 12 is the one that keeps every spot's point inside the window (x0 10 to 40 do) with the fewest sprites cut (x0 10 to 14 tie; this is their middle): 0 cut, 0 px in all; see the check spots-in-view for which and by how much",
   "choice": {
    "feasible": [10, 40],
    "rule": "every spot's point inside the window (vuelta and the traffic's entries and exits are exits: the point only); then the fewest spots whose sprite box is cut (a car's or a guagua's at the right or the bottom does not count); then the fewest px cut; then the middle of the x0 that still tie (10 to 14: the most room at both sides)",
    "table": [
     [10, 0, 0],
     [11, 0, 0],
     [12, 0, 0],
     [13, 0, 0],
     [14, 0, 0],
     [15, 1, 1],
     [16, 1, 2],
     [17, 1, 3],
     [18, 1, 4],
     [19, 1, 5],
     [20, 1, 6],
     [21, 1, 7],
     [22, 1, 8],
     [23, 1, 9],
     [24, 1, 10],
     [25, 1, 11],
     [26, 1, 12],
     [27, 1, 13],
     [28, 1, 14],
     [29, 4, 18],
     [30, 4, 22],
     [31, 4, 26],
     [32, 4, 30],
     [33, 4, 34],
     [34, 5, 39],
     [35, 5, 44],
     [36, 5, 49],
     [37, 5, 54],
     [38, 5, 59],
     [39, 5, 64],
     [40, 5, 69]
    ]
   }
  }
 },
 "front": {
  "list": null,
  "how": "no list. A character is hidden by every set pixel that is nearer the camera than the character's feet (depth test against the baked depth, with the feet's depth plus 0.3), so the colmado's wall hides nobody who stands in front of it, and a car or a guagua baked into the set (autos=) hides whoever stands behind it.",
  "bias": 0.3,
  "plane": "for the character's pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot's depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El mostrador's front; the same test for people and small things",
  "sprites": "between two sprites the nearer pixel wins: the same depth(r), no bias"
 },
 "shadows": {
  "radius": {
   "coqui": 0.45,
   "adulto": 0.35,
   "nino": 0.28,
   "cono": 0.16
  },
  "byCharacter": {
   "coqui": 0.45,
   "pepe": 0.35,
   "abuela": 0.35,
   "mama": 0.35,
   "papa": 0.35,
   "senora": 0.35,
   "senor": 0.35,
   "obrero": 0.35,
   "luis": 0.28,
   "carmen": 0.28,
   "cono": 0.16
  },
  "at": "castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0); the cones .16 as the set's own cones (calle-base.js cone)",
  "none": ["obrero.cubo"],
  "onBucket": "the obrero sitting on his bucket (z .3) casts none: the rule casts only for z 0, and the bucket is a sprite"
 },
 "checks": {
  "results": [
   {
    "name": "spots-in-view",
    "ok": true,
    "lines": [
     "spots-in-view: 43 spots: every point inside the 240 x 216 picture and the window [12, 208) x [0, 216) and every sprite whole (a vehicle may be cut at the right and the bottom of the picture, vuelta is an exit: 5 such cut(s), below)",
     "       not a failure: vuelta 205,87 is an exit, only its point has to be inside; the stand-in sprite would be cut by 9 px at the right",
     "       not a failure: alto_guagua (vehicle) 190,208: cut by the window 35 px at the right (its drawn pixels reach column 242, the window ends at 207)",
     "       not a failure: alto_guagua (vehicle) 190,208: cut by the picture 12 rows at the bottom (its drawn pixels reach row 227, the picture ends at 215)",
     "       not a failure: carril_b.guagua (vehicle) 178,202: cut by the window 22 px at the right (its drawn pixels reach column 229, the window ends at 207)",
     "       not a failure: carril_b.guagua (vehicle) 178,202: cut by the picture 6 rows at the bottom (its drawn pixels reach row 221, the picture ends at 215)",
     "       info, not a check: the x0 that keep every spot point inside, with the sprites each cuts that count (columns only: the spec's widths and the car's and the guagua's drawn pixels): x0 10: 0 sprite(s), 0 px; x0 11: 0 sprite(s), 0 px; x0 12: 0 sprite(s), 0 px; x0 13: 0 sprite(s), 0 px; x0 14: 0 sprite(s), 0 px; x0 15: 1 sprite(s), 1 px; x0 16: 1 sprite(s), 2 px; x0 17: 1 sprite(s), 3 px; x0 18: 1 sprite(s), 4 px; x0 19: 1 sprite(s), 5 px; x0 20: 1 sprite(s), 6 px; x0 21: 1 sprite(s), 7 px; x0 22: 1 sprite(s), 8 px; x0 23: 1 sprite(s), 9 px; x0 24: 1 sprite(s), 10 px; x0 25: 1 sprite(s), 11 px; x0 26: 1 sprite(s), 12 px; x0 27: 1 sprite(s), 13 px; x0 28: 1 sprite(s), 14 px; x0 29: 4 sprite(s), 18 px; x0 30: 4 sprite(s), 22 px; x0 31: 4 sprite(s), 26 px; x0 32: 4 sprite(s), 30 px; x0 33: 4 sprite(s), 34 px; x0 34: 5 sprite(s), 39 px; x0 35: 5 sprite(s), 44 px; x0 36: 5 sprite(s), 49 px; x0 37: 5 sprite(s), 54 px; x0 38: 5 sprite(s), 59 px; x0 39: 5 sprite(s), 64 px; x0 40: 5 sprite(s), 69 px",
     "       info, not a check: the pixels the stand-in people actually draw that the window cuts (the check above uses the spec's widths): none",
     "       info, not a check: the people sprites (the frog and the grown-ups and children, not vuelta nor the vehicles) span columns 28 (acera1) to 163 (boton_coqui): 136 px, the window is 196 wide"
    ],
    "x0": 12
   },
   {
    "name": "sprites-apart",
    "ok": true,
    "lines": [
     "sprites-apart: 48 pairs in the 8 moments of the preview (m1 (acera2, acera5); m2 (acera2, toca_guagua); m3 (acera1, acera2, acera3, acera4, acera5); m4 (pepe.puerta, fondo1, fondo2, bordillo1, bordillo2, esquina, acera1); m5 (esquina, bordillo1, bordillo2, acera1); m6 (acera1, acera2, acera5); m7 (obrero.cubo, coqui.cerca, acera6); m8 (obrero.fin, coqui.cemento, luis.cemento)): no two sprite boxes overlap sideways unless their feet are 12 px or more apart up-down (the frog 32 wide, grown-up 24, child 24); the pairs that do overlap sideways: m1 acera2 ~ acera5 (20 px across, 16 down), m3 acera1 ~ acera5 (9 px across, 31 down), m3 acera2 ~ acera5 (20 px across, 16 down), m4 pepe.puerta ~ bordillo1 (5 px across, 16 down), m4 pepe.puerta ~ esquina (26 px across, 30 down), m4 fondo1 ~ esquina (0 px across, 15 down), m4 fondo2 ~ bordillo2 (2 px across, 15 down), m6 acera1 ~ acera5 (9 px across, 31 down), m6 acera2 ~ acera5 (20 px across, 16 down), m7 coqui.cerca ~ acera6 (17 px across, 24 down), m8 coqui.cemento ~ luis.cemento (20 px across, 12 down)",
     "       closest in each moment (px across / px down): m1 acera2 ~ acera5 20/16 (needs 28 across or 12 down); m2 acera2 ~ toca_guagua 36/10 (needs 28 across or 12 down); m3 acera1 ~ acera5 9/31 (needs 28 across or 12 down); m4 fondo1 ~ esquina 0/15 (needs 28 across or 12 down); m5 esquina ~ bordillo1 31/14 (needs 28 across or 12 down); m6 acera1 ~ acera5 9/31 (needs 28 across or 12 down); m7 coqui.cerca ~ acera6 17/24 (needs 28 across or 12 down); m8 coqui.cemento ~ luis.cemento 20/12 (needs 28 across or 12 down)",
     "       info, not a check: pairs of spots the scripts put together but no moment shows (px across / px down; the boxes need 28 across for a grown-up and the frog, 24 for two grown-ups, or 12 down): sale_carro ~ toca_carro 9/7; sale_guagua ~ toca_guagua 7/7"
    ],
    "pairs": [
     {
      "moment": 1,
      "a": "acera2",
      "b": "acera5",
      "across": 20,
      "down": 16,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 2,
      "a": "acera2",
      "b": "toca_guagua",
      "across": 36,
      "down": 10,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera1",
      "b": "acera2",
      "across": 29,
      "down": 15,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera1",
      "b": "acera3",
      "across": 59,
      "down": 30,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera1",
      "b": "acera4",
      "across": 88,
      "down": 44,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera1",
      "b": "acera5",
      "across": 9,
      "down": 31,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera2",
      "b": "acera3",
      "across": 30,
      "down": 15,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera2",
      "b": "acera4",
      "across": 59,
      "down": 29,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera2",
      "b": "acera5",
      "across": 20,
      "down": 16,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera3",
      "b": "acera4",
      "across": 29,
      "down": 14,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera3",
      "b": "acera5",
      "across": 50,
      "down": 1,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 3,
      "a": "acera4",
      "b": "acera5",
      "across": 79,
      "down": 13,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "fondo1",
      "across": 26,
      "down": 15,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "fondo2",
      "across": 32,
      "down": 13,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "bordillo1",
      "across": 5,
      "down": 16,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "bordillo2",
      "across": 34,
      "down": 2,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "esquina",
      "across": 26,
      "down": 30,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "pepe.puerta",
      "b": "acera1",
      "across": 70,
      "down": 78,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo1",
      "b": "fondo2",
      "across": 58,
      "down": 28,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo1",
      "b": "bordillo1",
      "across": 31,
      "down": 1,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo1",
      "b": "bordillo2",
      "across": 60,
      "down": 13,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo1",
      "b": "esquina",
      "across": 0,
      "down": 15,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo1",
      "b": "acera1",
      "across": 96,
      "down": 63,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo2",
      "b": "bordillo1",
      "across": 27,
      "down": 29,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo2",
      "b": "bordillo2",
      "across": 2,
      "down": 15,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo2",
      "b": "esquina",
      "across": 58,
      "down": 43,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "fondo2",
      "b": "acera1",
      "across": 38,
      "down": 91,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "bordillo1",
      "b": "bordillo2",
      "across": 29,
      "down": 14,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "bordillo1",
      "b": "esquina",
      "across": 31,
      "down": 14,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "bordillo1",
      "b": "acera1",
      "across": 65,
      "down": 62,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "bordillo2",
      "b": "esquina",
      "across": 60,
      "down": 28,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 4,
      "a": "bordillo2",
      "b": "acera1",
      "across": 36,
      "down": 76,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 4,
      "a": "esquina",
      "b": "acera1",
      "across": 96,
      "down": 48,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "esquina",
      "b": "bordillo1",
      "across": 31,
      "down": 14,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "esquina",
      "b": "bordillo2",
      "across": 60,
      "down": 28,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "esquina",
      "b": "acera1",
      "across": 96,
      "down": 48,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 5,
      "a": "bordillo1",
      "b": "bordillo2",
      "across": 29,
      "down": 14,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "bordillo1",
      "b": "acera1",
      "across": 65,
      "down": 62,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 5,
      "a": "bordillo2",
      "b": "acera1",
      "across": 36,
      "down": 76,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 6,
      "a": "acera1",
      "b": "acera2",
      "across": 29,
      "down": 15,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 6,
      "a": "acera1",
      "b": "acera5",
      "across": 9,
      "down": 31,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 6,
      "a": "acera2",
      "b": "acera5",
      "across": 20,
      "down": 16,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 7,
      "a": "obrero.cubo",
      "b": "coqui.cerca",
      "across": 33,
      "down": 17,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 7,
      "a": "obrero.cubo",
      "b": "acera6",
      "across": 50,
      "down": 7,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 7,
      "a": "coqui.cerca",
      "b": "acera6",
      "across": 17,
      "down": 24,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 8,
      "a": "obrero.fin",
      "b": "coqui.cemento",
      "across": 42,
      "down": 20,
      "needAcross": 28,
      "ok": true
     },
     {
      "moment": 8,
      "a": "obrero.fin",
      "b": "luis.cemento",
      "across": 62,
      "down": 32,
      "needAcross": 24,
      "ok": true
     },
     {
      "moment": 8,
      "a": "coqui.cemento",
      "b": "luis.cemento",
      "across": 20,
      "down": 12,
      "needAcross": 28,
      "ok": true
     }
    ]
   },
   {
    "name": "frog-seen",
    "ok": true,
    "lines": [
     "frog-seen: in all 8 moments of the preview no car, guagua or grown-up hides any pixel of the frog, and the pole and the children together hide at most 40 of them: m1 acera5 536 px, 0 by cars, 0 by grown-ups, 32 by pole/child/other; m2 toca_guagua 536 px, 0 by cars, 0 by grown-ups, 0 by pole/child/other; m3 acera5 536 px, 0 by cars, 0 by grown-ups, 32 by pole/child/other; m4 esquina 536 px, 0 by cars, 0 by grown-ups, 22 by pole/child/other; m5 esquina 536 px, 0 by cars, 0 by grown-ups, 22 by pole/child/other; m6 acera5 536 px, 0 by cars, 0 by grown-ups, 32 by pole/child/other; m7 coqui.cerca 536 px, 0 by cars, 0 by grown-ups, 33 by pole/child/other; m8 coqui.cemento 536 px, 0 by cars, 0 by grown-ups, 15 by pole/child/other",
     "       all moments (px hidden: by cars and guaguas / by grown-ups / by the pole, children and other things, of the 40 allowed): m1 acera5 0 / 0 / 32 (32 by set part muro); m2 toca_guagua 0 / 0 / 0; m3 acera5 0 / 0 / 32 (32 by set part muro); m4 esquina 0 / 0 / 22 (22 by the pole); m5 esquina 0 / 0 / 22 (22 by the pole); m6 acera5 0 / 0 / 32 (32 by set part muro); m7 coqui.cerca 0 / 0 / 33 (33 by child at acera6); m8 coqui.cemento 0 / 0 / 15 (2 by thing at cono2, 13 by thing at cono3)"
    ],
    "frog": [
     {
      "moment": 1,
      "at": "acera5",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 32,
      "by": {
       "set part muro": 32
      },
      "ok": true
     },
     {
      "moment": 2,
      "at": "toca_guagua",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 0,
      "by": {},
      "ok": true
     },
     {
      "moment": 3,
      "at": "acera5",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 32,
      "by": {
       "set part muro": 32
      },
      "ok": true
     },
     {
      "moment": 4,
      "at": "esquina",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 22,
      "by": {
       "the pole": 22
      },
      "ok": true
     },
     {
      "moment": 5,
      "at": "esquina",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 22,
      "by": {
       "the pole": 22
      },
      "ok": true
     },
     {
      "moment": 6,
      "at": "acera5",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 32,
      "by": {
       "set part muro": 32
      },
      "ok": true
     },
     {
      "moment": 7,
      "at": "coqui.cerca",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 33,
      "by": {
       "child at acera6": 33
      },
      "ok": true
     },
     {
      "moment": 8,
      "at": "coqui.cemento",
      "drawn": 536,
      "car": 0,
      "grownUp": 0,
      "poleChildOther": 15,
      "by": {
       "thing at cono2": 2,
       "thing at cono3": 13
      },
      "ok": true
     }
    ]
   },
   {
    "name": "door-people",
    "ok": true,
    "lines": [
     "door-people: puerta and pepe.puerta stand in front of the colmado's door and none of their pixels is hidden by the wall or the door in any of the 8 states of the set: puerta 110,86 (y 0.35 in front of the wall y 0; x -1.85 in the door x -2.5 to -1.2, 0.65 from its left jamb and 0.65 from its right): 0 of the 895 pixels of abuela hidden by the set in the worst of the 8 states; pepe.puerta 110,86 (y 0.3 in front of the wall y 0; x -1.85 in the door x -2.5 to -1.2, 0.65 from its left jamb and 0.65 from its right): 0 of the 834 pixels of pepe hidden by the set in the worst of the 8 states",
     "       info, not a check: with the door open its leaf is drawn over pixels [127,34,144,103] (columns, rows) that the shut door leaves to the wall; don Pepe at pepe.puerta draws columns 98 to 121, rows 33 to 85"
    ]
   },
   {
    "name": "street-people",
    "ok": true,
    "lines": [
     "street-people: every person and the frog (27 spots) stands off the street (y 1.8 to 5.8) and the hole, except the ones the spec puts on the street: obrero.paleta y 3.6; sale_carro y 5.9 is 0.1 past the street's edge y 5.8, on the kerb stone (the kerb is y 5.8 to 6); sale_guagua y 5.9 is 0.1 past the street's edge y 5.8, on the kerb stone (the kerb is y 5.8 to 6); the spots of the moments with obra = 1 (obrero.cubo, coqui.cerca, acera6, cono1, cono2, cono3, obrero.fin, coqui.cemento, luis.cemento) are off the two squares of cement but the frog on the wet one at coqui.cemento and Luis, kneeling, on the old dry one at luis.cemento",
     "       info, not a check: spots of the stories without the dug-up street that lie on the footprint of a cement square (the squares are there only with obra = 1): acera1 0.5,6.5,0 (dry), acera2 2.1,6.5,0 (wet), enfrente 0.5,6.5,0 (dry), cruce_fin 2.1,6.5,0 (wet)"
    ]
   },
   {
    "name": "seat-top",
    "ok": true,
    "lines": [
     "seat-top: the set has no seat; the only person off the ground is the obrero at obrero.cubo (z 0.3, the top of his bucket): the preview draws the bucket on the ground under him (its base on row 208, 6 rows below the spot's row 202, which is z .3 = 6.75 px up) and his lap row 38 on the spot's row"
    ]
   },
   {
    "name": "frog-clear-of-vehicles",
    "ok": true,
    "lines": [
     "frog-clear-of-vehicles: the frog at esquina and at boton_coqui is not covered by the car at alto_carro or the guagua at alto_guagua: esquina 136,116 (536 px drawn): 0 covered by the car at alto_carro, 0 by the guagua at alto_guagua, 0 by both (apart from these, 22 hidden by the pole); boton_coqui 148,121 (536 px drawn): 0 covered by the car at alto_carro, 0 by the guagua at alto_guagua, 0 by both (apart from these, 136 hidden by the pole: allowed there, he is pressing its button)",
     "       info, not a check: story 48: toca_carro 63,168: 0 px covered by the car at para48_carro or the guagua at para48_guagua; toca_guagua 105,189: 0 px covered by the car at para48_carro or the guagua at para48_guagua; acera5 49,195: 0 px covered by the car at para48_carro or the guagua at para48_guagua",
     "       info, not a check: things that drive standing together: moment 2 carro@0.7,4.8 ~ guagua@4.5,4.8: floors apart (0.5 in x, same lane); moment 5 carro@3.5,4.8 ~ guagua@6.7,4.8: the floors overlap by 0.1 in x (and 1.1 in y); moment 7 azul@-0.9,4.8 ~ guagua@6.3,4.8: floors apart (3.9 in x, same lane)"
    ],
    "covered": {
     "esquina": {
      "drawn": 536,
      "car": 0,
      "guagua": 0,
      "both": 0,
      "hiddenByThePole": 22
     },
     "boton_coqui": {
      "drawn": 536,
      "car": 0,
      "guagua": 0,
      "both": 0,
      "hiddenByThePole": 136
     }
    }
   },
   {
    "name": "enfrente-in-window",
    "ok": true,
    "lines": [
     "enfrente-in-window: mamá at enfrente 40,164 is whole inside the window [12, 208): moment 4: columns 28 to 51, rows 110 to 163 (954 of 954 px in the picture; 16 px from the window's left edge, 156 from its right); moment 5: columns 28 to 51, rows 110 to 163 (954 of 954 px in the picture; 16 px from the window's left edge, 156 from its right); moment 6: columns 28 to 51, rows 110 to 163 (954 of 954 px in the picture; 16 px from the window's left edge, 156 from its right)"
    ]
   },
   {
    "name": "hole-shows",
    "ok": true,
    "lines": [
     "hole-shows: moment 7: the hole shows 434 of its 901 pixels (48.17%, needs 45%); covered: 467 by the vehicles (0 by azul at -0.9,4.8 alone, 467 by guagua at 6.3,4.8 alone), 0 by sprites",
     "       info, not a check: counting the whole image of the hole's rectangle (1628 pixels, with its barrier, cones, heaps and spade) the vehicles and people cover 755 and 873 show: 53.62%"
    ],
    "hole": {
     "pixels": 901,
     "shown": 434,
     "byVehicles": 467,
     "bySprites": 0,
     "share": 0.4817,
     "wholeImage": {
      "pixels": 1628,
      "shown": 873,
      "share": 0.5362
     }
    }
   },
   {
    "name": "things-in-view",
    "ok": true,
    "lines": [
     "things-in-view: 6 things with a box (colmado [0,0,240,100], puerta [103,19,25,71], boton [147,106,8,12], calle [0,33,240,183], esquina [120,100,60,30], cemento [42,167,36,19]) inside the picture; puerta, boton, esquina and cemento whole inside the window; what draws each world box (the middle pixel, or 9 pixels for a flat one): puerta 1 puerta, boton 1 semaforo, calle 9 ground, esquina 8 ground + 1 semaforo, cemento 9 ground; colmado [0,0,240,100] is cut by the window: 12 px at the left, 32 at the right; calle [0,33,240,183] is cut by the window: 12 px at the left, 32 at the right"
    ]
   }
  ]
 }
}
''',
};
