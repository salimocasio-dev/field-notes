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
};
