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
};
