// ref/escenas: what make.mjs cannot read from the running page, set by hand from the scene files (each line cited).
// Every judgment here is also written into the scene's inventory.json ("judgments") and draw-order.md.

export const SCENES = ["frente", "balcon", "sala", "patio", "camino", "campo", "lago", "banco", "mesa", "estufa", "nevera", "comer"];

// The background functions: what the scene draws first, once per state, cached by spr(). Their W keys are the set's states.
// file:line of the call in draw(), and the W keys the call passes or the key reads (checked by make.mjs: two states with the same
// values of these keys never get a different background sprite).
export const BG = {
  frente: { fns: ["bg"], at: ["frente.js:12 bg(door,win,lamp)", "frente.js:140 spr(\"fr\"+W.door+\"_\"+W.win+\"_\"+W.lamp, ()=>bg(W.door,W.win,W.lamp))"], keys: ["door", "win", "lamp"] },
  balcon: { fns: ["bg"], at: ["balcon.js:15 bg(door,win)", "balcon.js:121 spr(\"bal\"+W.door+\"_\"+W.win, ()=>bg(W.door,W.win))"], keys: ["door", "win"] },
  sala: { fns: ["bg"], at: ["sala.js:17 bg()", "sala.js:107 spr(\"sala\",bg)"], keys: [] },
  patio: { fns: ["cielo", "fondo"], at: ["patio.js:23 fondo(pt,pd)", "patio.js:129 spr(\"cielo\"+n, ()=>cielo(n)) with n = W.noche?4:Math.min(3,W.sol||0) (patio.js:128)", "patio.js:132 spr(\"patio\"+(W.porton?1:0)+(W.pdoor?1:0), ()=>fondo(W.porton,W.pdoor))"], keys: ["noche", "sol", "porton", "pdoor"] },
  camino: { fns: ["fondo"], at: ["camino.js:21 fondo(gran)", "camino.js:95 spr(\"camino\"+(W.sinGran?0:1), ()=>fondo(!W.sinGran))"], keys: ["sinGran"] },
  campo: { fns: ["fondo"], at: ["campo.js:20 fondo()", "campo.js:96 spr(\"campo\",fondo)"], keys: [] },
  lago: { fns: ["fondo"], at: ["lago.js:23 fondo()", "lago.js:112 spr(\"lago\",fondo)"], keys: [] },
  banco: { fns: ["fondo"], at: ["banco.js:33 fondo()", "banco.js:192 spr(\"banco\",fondo)", "banco.js:194 the same sprite again, a 46x38 patch of it (84,6) copied to (196,6) when W.noche"], keys: [] },
  mesa: { fns: ["fondo", "mkPuesto"], at: ["mesa.js:30 fondo()", "mesa.js:54 mkPuesto()", "mesa.js:156 W.afuera ? spr(\"puesto\",mkPuesto) : spr(\"cocina\",fondo)"], keys: ["afuera"] },
  estufa: { fns: ["fondo"], at: ["estufa.js:26 fondo()", "estufa.js:133 spr(\"estufa\",fondo)"], keys: [] },
  nevera: { fns: ["fondo"], at: ["nevera.js:22 fondo()", "nevera.js:156 spr(\"nevera\",fondo)"], keys: [] },
  comer: { fns: ["fondo"], at: ["comer.js:31 fondo()", "comer.js:549 spr(\"comer\",fondo)"], keys: [] },
};

// Characters, for the frames "without characters" (variant nochar): a canvas call is left out when its stack holds one of these
// functions, or one of these lines (anywhere in the stack); keep wins over both. Characters are the frog, abuela, people, the baby and
// animals, with what is drawn on them or held by them (speech and thought bubbles, sweat, a glass in a hand, dust behind a hop).
// Props that stand on their own (glasses on a table, a ball in the air, the storm cloud, rain) stay.
export const CHARS = {
  frente: { fns: ["frog", "drawAve", "bub", "fly", "towel"], keep: ["mesa"],
    lines: ["frente.js:143", "frente.js:144", "frente.js:146", "frente.js:147", "frente.js:148", "frente.js:149", "frente.js:151", "frente.js:152", "frente.js:153", "frente.js:155", "frente.js:156", "frente.js:157", "frente.js:158", "frente.js:160", "frente.js:172", "frente.js:173", "frente.js:174"],
    note: "frente.js:47-50 ambient(): two butterflies (fly, left out) and a small white cloud that drifts with the frame counter (kept: it is sky)." },
  balcon: { fns: ["rana", "dePie", "drawAve", "bub2", "gota"], keep: [],
    lines: ["balcon.js:129", "balcon.js:130", "balcon.js:131", "balcon.js:132", "balcon.js:133", "balcon.js:134", "balcon.js:143", "balcon.js:144", "balcon.js:145", "balcon.js:146", "balcon.js:147", "balcon.js:148", "balcon.js:149", "balcon.js:151", "balcon.js:152", "balcon.js:154", "balcon.js:155"] },
  sala: { fns: ["gente", "rana", "bub2"], keep: [], lines: ["sala.js:115", "sala.js:116", "sala.js:123", "sala.js:124"] },
  patio: { fns: ["gente", "rana", "drawAve", "bub2", "luciernaga"], keep: [], lines: ["patio.js:139", "patio.js:141", "patio.js:143", "patio.js:144", "patio.js:150", "patio.js:151"] },
  camino: { fns: ["gente", "animal", "rana", "bub2"], keep: [], lines: ["camino.js:99", "camino.js:100", "camino.js:105", "camino.js:109", "camino.js:111", "camino.js:112", "camino.js:113", "camino.js:114"] },
  campo: { fns: ["gente", "perro", "rana", "bub2"], keep: [], lines: ["campo.js:106", "campo.js:108", "campo.js:109", "campo.js:110"] },
  lago: { fns: ["gente", "pato", "pez", "ave", "rana", "bub2"], keep: [], lines: ["lago.js:124", "lago.js:129", "lago.js:130"] },
  banco: { fns: ["gente", "perro", "rana", "bub2"], keep: [], lines: ["banco.js:200", "banco.js:207", "banco.js:208"] },
  mesa: { fns: ["gente", "rana", "nube", "bub2"], keep: [], lines: ["mesa.js:174", "mesa.js:175", "mesa.js:176", "mesa.js:185", "mesa.js:186", "mesa.js:187", "mesa.js:188"] },
  estufa: { fns: ["gente", "rana", "nube", "nube2", "bub2"], keep: [], lines: ["estufa.js:134", "estufa.js:163", "estufa.js:164", "estufa.js:165"] },
  nevera: { fns: ["gente", "rana", "nube", "bub2"], keep: [], lines: ["nevera.js:109", "nevera.js:171", "nevera.js:173", "nevera.js:174", "nevera.js:175", "nevera.js:176", "nevera.js:177"] },
  comer: { fns: ["cuerpo", "objetos", "rana", "nube", "hab"], keep: [], lines: ["comer.js:554", "comer.js:555", "comer.js:556"],
    note: "comer.js:455 cuerpo() draws a person without the arms that hold, objetos() (comer.js:481) the arms, hands and what they hold; comer.js:554-556 the dog; nube() the thought clouds; hab() the empty speech bubbles drawn only with ?txt=no (comer.js:561-566)." },
};

// W keys that hold characters (who stands where, how): left out when states are grouped (a character's own box, when it is a thing,
// still separates states). And keys that are the game's signs or a frame stamp, the same for every scene.
export const CHARKEYS = {
  frente: ["cq", "ab", "ave", "tab", "shake", "wet", "gotas", "polvo", "piernas", "asoma", "peek", "tapado", "dentro", "trozo", "hojas"],
  balcon: ["cq", "ab", "ave", "calor", "sudor", "abvaso", "sobre", "splash", "vierte", "bebiendo", "cqfan", "fuente"],
  sala: ["cq", "gente", "ave", "lleva", "tapaojos"],
  patio: ["cq", "gente", "ave", "mari", "luces", "polvo", "lleva"],
  camino: ["cq", "gente", "perro", "gato", "pajaros", "caracol", "correa", "correaDe", "correaA", "polvo", "avebanco", "guineos"],
  campo: ["cq", "gente", "perro", "mariposa"],
  lago: ["cq", "gente", "patos", "peces", "aves", "perro"],
  banco: ["cq", "gente", "perros", "palomas", "ladrona"],
  mesa: ["cq", "gente", "perro", "tiron"],
  estufa: ["cq", "gente", "ventana"],
  nevera: ["cq", "gente", "olfato"],
  comer: ["cq", "gente", "perro", "sitio"],
};
// W keys of props that move about (carried, thrown, put down here and there): like characters, they do not separate states; where each
// one was is in inventory.json (spriteLayer, things) for every snapshot.
export const PROPKEYS = { frente: [], balcon: [], sala: ["vuela"], patio: ["bola", "vuela"], camino: ["vuela"], campo: ["bolas"], lago: ["botes", "pan"], banco: ["cosas"], mesa: ["cosas", "vuelos", "muestra"], estufa: ["cosas", "vuelos"], nevera: ["cosas", "vuelos"], comer: ["vuelos"] };
export const SIGNKEYS = ["fx", "spot", "twinkle", "glow", "heart", "resp", "respVoz", "respOn", "respEn", "marcas", "apodo", "flash", "rojo", "azul", "trozos", "golpe", "brilla", "tiembla", "salpica", "lost", "mios", "plato", "rondas", "termo", "tarjeta", "cafe", "aciertos", "visor", "retrato"];

// What a position in a story or pair file means, where the scene's code makes it clear: the owner of an x, y (the path under set,
// or an act's name), with the line that reads it.
export const MEANING = {
  "*": {
    "set.cq": "the frog: frogBox(cq) (juego.js:46) is x+(32-w)/2, y+27-h, w = round(30s)+2, h = round(25s)+2; his feet are at y+27, his middle at x+16",
    "act:rana": "the frog hops to x, y (the scene's act rana)",
  },
  frente: { "set.ave": "the bird: frente.js:78-79 avePos; mode head puts it on the frog's head, x and y unused" },
  balcon: { "set.ab": "abuela standing: her feet at x, y (balcon.js:123 draws mkAbuela at x-30, y-50); en: silla puts her in the big chair at ABS (balcon.js:95) whatever x, y say",
    "set.ave": "the bird's feet (kit.js:25 avePos)", "set.vasos": "a glass: its middle x, its foot at y or MESA_Y 128 (balcon.js:80, 137)", "set.jarras": "a jug: its middle x, its foot at MESA_Y 128 (balcon.js:87, 140)" },
  sala: { "set.gente": "a person's feet: x middle, y the bottom (sala.js:86-92 gente)" },
  patio: { "set.gente": "a person's feet: x middle, y the bottom (patio.js:98-103 gente)", "set.bola": "the ball's foot (patio.js:138, cosa at x-7, y-14-h)", "set.polvo": "dust behind a hop (patio.js:141)", "set.rizo": "the dotted loop the bird flew: centre x, y, radius r (patio.js:142)" },
  camino: { "set.gente": "a person's feet (camino.js:75-80 gente)", "set.perro": "the dog's feet (camino.js:82 animal)", "set.gato": "the cat's feet; en: a tree index puts it up that tree instead (camino.js:100)", "set.polvo": "dust behind a run (camino.js:111)", "set.caracol": "the snail's foot (camino.js:105)", "set.respEn": "where the answer bubbles stand instead of above the frog (juego.js:51 respBox)" },
  campo: { "set.gente": "a person's feet (campo.js:72-75 gente)", "set.perro": "the dog's feet (campo.js:77 perro)", "set.bolas": "a ball (campo.js:90 unaBola, bolaXY)", "set.flor": "a flower's foot (campo.js:105)" },
  lago: { "set.gente": "a person's feet (lago.js:89 gente)", "set.patos": "a duck (lago.js:96 pato)", "set.peces": "a fish (lago.js:99 pez)", "set.aves": "a bird (lago.js:102 ave)", "set.pan": "the bread (lago.js:126)", "set.bolsa": "the bag of bread's foot (lago.js:122)" },
  banco: { "set.gente": "a person's feet; sent: sitting on the bench (banco.js:155-163 gente)", "set.perros": "a dog's feet (banco.js:175 perro)", "set.palomas": "a dove's feet (banco.js:200)", "set.cosas": "a thing's foot (banco.js:201 tenida)", "set.casa": "where the walk home ends (banco.js acts)" },
  mesa: { "set.gente": "a person's feet (mesa.js:136-149 gente)", "set.cosas": "a thing's foot (mesa.js:177 conTodo / tenida)" },
  estufa: { "set.gente": "a person's feet (estufa.js:117-127 gente)", "set.cosas": "a thing's foot (estufa.js:156 tenida)", "set.vuelos": "a thing in the air (estufa.js:162)", "set.mat": "the small plate (estufa.js:160)", "set.plata": "the big plate (estufa.js:159)", "set.olor": "the smell line from x0, y0 to x1, y1 (estufa.js:138)" },
  nevera: { "set.gente": "a person's feet; fuera: outside, seen in the window (nevera.js:109, 141)", "set.cosas": "a thing's foot (nevera.js:167 tenida)" },
  comer: { "set.gente": "a person's feet: x middle, y the bottom (comer.js:455 cuerpo; sent: sitting, at a chair SILLA, comer.js:20)", "set.cosas": "a thing's foot: x middle, y the bottom (comer.js:538 cosaDibuja, comer.js:294 tenida)",
    "set.vuelos": "a thing in the air: its middle (comer.js:560 tenidaC)", "set.perro": "the dog's feet (comer.js:554)" },
};

// El frente has no KIT.escena: its hit() order, each with its condition and the rectangle (or shape) it tests, frente.js:185-199.
export const FRENTE_HIT = [
  { id: "abuela", line: 186, if: "W.ab", test: "inside box('abuela',W): ventana [97,61,30,20], paso [110,58,36,50], else [151,56,29,49] (frente.js:181)" },
  { id: "palma_pequena", line: 187, if: "W.escondite", test: "inside [172,112,46,60]" },
  { id: "casa_pequena", line: 187, if: "W.escondite", test: "inside [58,108,30,62]" },
  { id: "palma_grande", line: 187, if: "W.escondite", test: "inside [34,34,48,74]" },
  { id: "casa_grande", line: 188, if: "W.escondite", test: "inside [57,16,171,95] and not inside abuela's box when W.ab" },
  { id: "pajaro", line: 189, if: "W.ave && W.ave.mode!=='none'", test: "|x-p[0]|<16 and p[1]-24<y<p[1]+5, p = avePos(W.ave) (frente.js:78)" },
  { id: "bizcocho", line: 190, if: "W.plato!=null", test: "in the view: (x-cam[0])*DW/cam[2] < 66 and (y-cam[1])*DH/cam[3] < 36 (the plate in the corner, drawn by hud)" },
  { id: "coqui", line: 191, if: "W.cq.vis", test: "inside frogBox(W.cq) (juego.js:46)" },
  { id: "nube", line: 192, if: "W.storm && W.nube", test: "inside [W.nube.x-2,0,102,24]" },
  { id: "puerta", line: 193, if: "always", test: "inside [145,46,42,62] (box() says [151,51,30,54])" },
  { id: "ventana", line: 194, if: "always", test: "inside [82,53,61,42] (box() says [93,57,38,28])" },
  { id: "casa", line: 195, if: "always", test: "the roof: 16<=y<42 and 88-30t<=x<=196+30t, t=(y-16)/25 (frente.js:195); or inside [57,41,171,70] (frente.js:196)" },
  { id: "sol", line: 197, if: "!W.storm", test: "(x-210)^2+(y-17)^2<144" },
  { id: "palma", line: 198, if: "always", test: "inside [34,36,30,70]: the big palm bg() draws at 30,34 (frente.js:42, mkPalm)" },
];
export const FRENTE_HIT_RECT = { abuela: null, palma_pequena: [172, 112, 46, 60], casa_pequena: [58, 108, 30, 62], palma_grande: [34, 34, 48, 74], casa_grande: [57, 16, 171, 95], puerta: [145, 46, 42, 62], ventana: [82, 53, 61, 42], casa: [57, 16, 171, 95], sol: [198, 5, 25, 25], palma: [34, 36, 30, 70] };
// El frente's constants inside its closure (not readable from the page): make.mjs evaluates these declarations from the file text
export const FRENTE_CONSTS = ["ABAT", "PERCH", "SPOT", "LUGAR", "NX"];
