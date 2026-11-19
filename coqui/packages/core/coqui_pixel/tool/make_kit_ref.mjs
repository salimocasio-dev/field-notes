// Makes the reference for order 12's logic from the OLD code, run in node:
//
//   node tool/make_kit_ref.mjs          (in this package) writes test/support/fixtures/ref_kit_logic.dart
//   node tool/make_kit_ref.mjs --check  says whether that file is the one the old code gives now
//
// Four parts, each the old code run unchanged in node's `vm` with stubs, on a made-up input that test/kit_logic_test.dart
// repeats in Dart (the made-up scene is written twice, here and in test/support/kit_scene.dart: keep them the same):
//
//   scene  historia/escenas/kit.js, KIT.escena(d) on a made-up scene: `hit` at 50 fixed points under four states of W,
//          `box`, `handAt`, `avePos`, and the shared acts `ir`, `burbuja`, `calla`, `pose`, `fin` and the bird's
//          `aveVa` (the calls they make on the game's stubs and W after them). `frogBox` is juego.js's, line for line.
//   sfx    historia/juego.js, the 18 names of `SFX`, on a stub of `tone` and of the audio graph the thunder and the rain
//          use: the calls (as ClipPlayer calls) and, for the thunder and the rain, the raw numbers of the graph.
//   clip   docs/proyecto/pixel/pp-engine.js, `project` of the corners of the faces of made-up boxes.
//   camgo  historia/juego.js, `at`, `camGo` and the step of `draw` that moves the view: how many frames each move takes
//          and, between views of the same size, where the (old, fractional) view is at each of them.
//
// Nothing here depends on the time or on chance, so a second run gives the same file.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../../..');
const outFile = path.resolve(here, '../test/support/fixtures/ref_kit_logic.dart');
const read = f => fs.readFileSync(path.join(repo, f), 'utf8');
const juego = read('historia/juego.js').split('\n');
const lineStarting = (lines, prefix) => {
  const hits = lines.filter(l => l.startsWith(prefix));
  if (hits.length !== 1) throw new Error(`${hits.length} lines start with ${prefix}`);
  return hits[0];
};
const clone = v => JSON.parse(JSON.stringify(v));

/* ============================== scene: kit.js ============================== */
function sceneRef() {
  const ctx = vm.createContext({});
  vm.runInContext(`
    var RP = new Proxy({}, { get: () => ['#000001', '#000002', '#000003', '#000004', '#000005'] });
    var OUT = '#10182A', ESCENAS = {}, TICK = 70, F = 0;
    var W = {}, S = { stake: { steps: 3 } }, cam = [22, 0, 196, 216];
    var LOG = [];
    function wait(ms) { LOG.push(['wait', ms]); return Promise.resolve(); }
    function hopTo(x, y, hops, s1) { LOG.push(['hopTo', x, y, hops, s1 == null ? null : s1]); return Promise.resolve(); }
    function bounce(h) { LOG.push(['bounce', h == null ? null : h]); }
    function fx(e) { LOG.push(['fx', JSON.parse(JSON.stringify(e))]); }
    var SFX = new Proxy({}, { get: (_, k) => () => { LOG.push(['SFX', k]); } });
  `, ctx);
  vm.runInContext(lineStarting(juego, 'function frogBox('), ctx, { filename: 'juego.js:frogBox' });
  vm.runInContext(read('historia/escenas/kit.js'), ctx, { filename: 'kit.js' });

  // the made-up scene (the same is in test/support/kit_scene.dart)
  vm.runInContext(`
    var OWN_IR = async o => { LOG.push(['own ir', o.a === undefined ? null : o.a]); };
    var COSAS = [
      { id: 'cartel', box: [10, 20, 40, 30], z: 1 },
      { id: 'arbol', box: w => [100.5, 40 + (w.dy || 0), 30, 70], m: 0 },
      { id: 'puerta', box: [150, 60, 30, 56], si: w => w.door !== 2, hand: [165, 100] },
      { id: 'perilla', box: [160, 90, 8, 8], si: w => w.door === 1, z: 1, m: 6, hand: w => [164, w.door * 10 + 80] },
      { id: 'banco', box: [40, 120, 60, 20], m: 5 },
      { id: 'suelo', box: [0, 150, 240, 66] },
      { id: 'fuera', box: w => [300, 300, 10, 10] },
    ];
    var LUGAR = { puerta: [165, 150, .9], banco: [70, 150, 1], origen: [150, 178, 1] };
    var SCENE = KIT.escena({ id: 'maqueta', CAM: { wide: [22, 0, 196, 216] }, heartAt: [110, 30], lugar: LUGAR, cosas: COSAS,
      acts: { ir: OWN_IR, abre: async o => { LOG.push(['abre']); } } });
    var PLAIN = KIT.escena({ id: 'plana', CAM: { wide: [22, 0, 196, 216] }, lugar: LUGAR, cosas: COSAS });
  `, ctx);

  const ids = ['cartel', 'arbol', 'puerta', 'perilla', 'banco', 'suelo', 'fuera', 'nope'];

  const points = [];
  for (let i = 0; i < 30; i++) points.push([(i * 53 + 17) % 240, (i * 97 + 31) % 216]);
  points.push(...[[10, 20], [9, 19], [50, 50], [49, 49], [7, 17], [6, 16], [52, 52], [53, 53],
    [100, 50], [101, 50], [130, 50], [131, 50], [110, 39], [110, 40], [110, 109], [110, 110],
    [165, 100], [164, 85], [150, 178], [182, 204]]);
  if (points.length !== 50) throw new Error('50 points');

  const variants = [
    { name: 'v1: the frog stands, a bird sits', W: { cq: { x: 150, y: 178, s: 1, dy: 0, vis: 1, bub: null }, ave: { mode: 'sit', x: 60, y: 100, dir: 1, st: 'n' }, door: 0, ab: { bub: null, pose: 'idle' }, lost: 0, fx: [] } },
    { name: 'v2: the frog is gone, no bird, the door is half open, the tree is lower', W: { cq: { x: 150, y: 178, s: 1, dy: 0, vis: 0 }, ave: { mode: 'none' }, door: 1, dy: 5 } },
    { name: 'v3: a small frog, the bird on his head, the door is open', W: { cq: { x: 60, y: 100, s: .72, dy: -3, vis: 1 }, ave: { mode: 'head', x: 0, y: 0, dir: 1, st: 'n' }, door: 2 } },
    { name: 'v4: a bird in flight, dipping', W: { cq: { x: 200, y: 60, s: 1, dy: 0, vis: 1 }, ave: { mode: 'fly', x: 200, y: 60.5, dip: 3, dir: -1, st: 'feliz' }, door: 1 } },
  ];
  const orNull = v => (v === undefined ? null : v);
  const out = { points, ids, variants: [], acts: [],
    actNames: { own: vm.runInContext('Object.keys(SCENE.acts)', ctx), plain: vm.runInContext('Object.keys(PLAIN.acts)', ctx),
      ownIrIsKept: vm.runInContext('SCENE.acts.ir === OWN_IR', ctx), heartAt: vm.runInContext('[SCENE.heartAt, PLAIN.heartAt]', ctx) } };
  for (const v of variants) {
    ctx.W = clone(v.W);
    const hit = points.map(([x, y]) => orNull(ctx.SCENE.hit(x, y, ctx.W)));
    const box = {}, handAt = {};
    for (const id of ids) { box[id] = orNull(ctx.SCENE.box(id, ctx.W)); handAt[id] = orNull(ctx.SCENE.handAt[id]); }
    const avePos = ctx.W.ave && ctx.W.ave.mode !== 'none' ? vm.runInContext('KIT.avePos(W.ave)', ctx) : null;   // a bird that is gone has no place (NaN)
    out.variants.push({ name: v.name, W: v.W, hit, box, handAt, avePos });
  }

  // the acts: each from a state, with the calls it makes and W after it
  const runs = [
    ['the scene\'s own ir is the one that runs', 'ir', { a: 'puerta' }, 'v1', { scene: 'SCENE' }],
    ['ir to the door from his place', 'ir', { a: 'puerta' }, 'v1'],
    ['ir to a far place by "en"', 'ir', { en: 'banco' }, 'v4'],
    ['ir where he already is: only his size changes', 'ir', { a: 'origen' }, 'v1'],
    ['ir to a place the scene does not know', 'ir', { a: 'nope' }, 'v1'],
    ['ir with neither a nor en', 'ir', {}, 'v1'],
    ['burbuja: the frog speaks', 'burbuja', { quien: 'cq', que: 'hola' }, 'v1'],
    ['burbuja: abuela speaks', 'burbuja', { quien: 'ab', que: 'amor' }, 'v1'],
    ['burbuja: abuela speaks but there is no abuela', 'burbuja', { quien: 'ab', que: 'amor' }, 'v2'],
    ['calla with abuela', 'calla', {}, 'v1', { cqBub: 'hola', abBub: 'x' }],
    ['calla without abuela', 'calla', {}, 'v2', { cqBub: 'hola' }],
    ['pose with abuela', 'pose', { que: 'wave0' }, 'v1'],
    ['pose without abuela', 'pose', { que: 'wave0' }, 'v2'],
    ['fin: nothing lost', 'fin', {}, 'v1'],
    ['fin: one step lost of three', 'fin', {}, 'v1', { lost: 1 }],
    ['fin: all lost', 'fin', {}, 'v1', { lost: 3 }],
    ['fin: nothing lost, a view at a fractional place', 'fin', {}, 'v1', { cam: [45.5, 36.25, 98, 108] }],
  ];
  const driver = vm.runInContext(`(async (scene, name, o) => { await scene.acts[name](o); })`, ctx);
  const doRun = async (title, name, o, vname, tweak = {}) => {
    const v = variants.find(x => x.name.startsWith(vname));
    const W0 = clone(v.W);
    if (tweak.cqBub) W0.cq.bub = tweak.cqBub;
    if (tweak.abBub && W0.ab) W0.ab.bub = tweak.abBub;
    if (tweak.lost != null) W0.lost = tweak.lost;
    ctx.W = clone(W0);
    ctx.cam = tweak.cam || [22, 0, 196, 216];
    ctx.LOG.length = 0;
    await driver(ctx[tweak.scene || 'PLAIN'], name, o);
    out.acts.push({ title, scene: tweak.scene === 'SCENE' ? 'own' : 'plain', act: name, o, W0, cam: clone(ctx.cam), log: clone(ctx.LOG), W1: clone(ctx.W) });
  };
  const bird = async (title, W0, call) => {
    ctx.W = clone(W0); ctx.cam = [22, 0, 196, 216]; ctx.LOG.length = 0;
    await vm.runInContext(`(async () => { ${call} })()`, ctx);
    out.acts.push({ title, scene: 'plain', act: call, o: null, W0, cam: [22, 0, 196, 216], log: clone(ctx.LOG), W1: clone(ctx.W) });
  };
  return { ctx, out, runs, doRun, bird, variants };
}
const S = sceneRef();
for (const r of S.runs) await S.doRun(...r);
await S.bird('aveVa with no bird: it comes in from the right', { cq: { x: 150, y: 178, s: 1, dy: 0, vis: 1 } }, 'await KIT.aveVa(100, 80, 4, 1)');
await S.bird('aveVa from where it sits, nine steps by default, no direction', { cq: { x: 150, y: 178, s: 1, dy: 0, vis: 1 }, ave: { mode: 'sit', x: 60, y: 100, dir: 1, st: 'n' } }, 'await KIT.aveVa(20, 120)');
await S.bird('aveVa from the frog\'s head', { cq: { x: 60, y: 100, s: .72, dy: -3, vis: 1 }, ave: { mode: 'head', x: 0, y: 0, dir: 1, st: 'n' } }, 'await KIT.aveVa(200, 40, 3, -1)');
await S.bird('aveA alone', { cq: { x: 150, y: 178, s: 1, dy: 0, vis: 1 }, ave: { mode: 'fly', x: 10, y: 10, dir: 1, st: 'n' } }, 'await KIT.aveA(70, 50, 5)');

/* ============================== sfx: juego.js ============================== */
function sfxRef() {
  // lines `const SFX={` to the end of `Object.assign(SFX,{...})`
  const a = juego.findIndex(l => l.startsWith('const SFX={'));
  const b = juego.findIndex((l, i) => i > a && l.startsWith('Object.assign(SFX,'));
  let e = b;
  while (!juego[e].includes('swoop(){')) e++;
  const text = juego.slice(a, e + 1).join('\n');
  const raw = [], calls = [], thunder = { v: null };
  const ctx = vm.createContext({
    // tone: the call is the ClipPlayer's tone(hz, at, dur, wave, vol, toHz)
    tone: (f0, at, dur, type, vol, f1) => calls.push(['tone', f0, at, dur, type, vol, f1 === undefined ? null : f1]),
    noise: () => ({ noiseBuffer: true }),
    out: () => ({ master: true }),
    ac: () => ({
      currentTime: 0,
      createBufferSource: () => { const s = { set loop(v) { raw.push(['source.loop', v]); this._l = v; }, get loop() { return this._l; },
        connect: () => ({ connect: () => ({ connect: () => 0 }) }),
        start: (...x) => { raw.push(['source.start', ...x]); if (s._l) calls.push(['loop', 'rain', true]); },
        stop: (...x) => { raw.push(['source.stop', ...x]); if (s._l) calls.push(['loop', 'rain', false]); } }; return s; },
      createBiquadFilter: () => { const f = { set type(v) { raw.push(['filter.type', v]); }, frequency: { value: 0, setValueAtTime: (...x) => raw.push(['filter.freq.set', ...x]), exponentialRampToValueAtTime: (...x) => raw.push(['filter.freq.ramp', ...x]) },
        connect: () => ({ connect: () => 0 }) }; return f; },
      createGain: () => ({ gain: { set value(v) { raw.push(['gain.value', v]); }, setValueAtTime: (v, t) => { raw.push(['gain.set', v, t]); thunder.v = v; },
        exponentialRampToValueAtTime: (...x) => raw.push(['gain.ramp', ...x]) }, connect: () => ({ connect: () => 0 }) }),
    }),
  });
  vm.runInContext(text.replace('const SFX=', 'var SFX=').replace(/^let NOISE=null,RAIN=null;/m, ''), ctx, { filename: 'juego.js:SFX' });
  vm.runInContext('var RAIN = null, NOISE = null;', ctx);
  const names = vm.runInContext('Object.keys(SFX)', ctx);
  const run = (name, ...args) => {
    calls.length = 0; raw.length = 0; thunder.v = null;
    vm.runInContext(`SFX.${name}(${args.map(a => JSON.stringify(a)).join(',')})`, ctx);
    const c = calls.map(x => x.slice());
    // trueno has no tone: the graph is the thunder, `noiseBurst(vol)` where the graph's first gain is `vol * .5`
    if (name === 'trueno') c.push(['noise', thunder.v / .5]);
    return { name, args, calls: c, raw: raw.map(x => x.slice()) };
  };
  const list = [];
  for (const n of names) list.push(run(n));
  list.push(run('trueno', .6), run('trueno', 0), run('trueno', 2));
  // the rain keeps state in the old code: a second lluvia starts nothing, a calla with no rain stops nothing
  const seq = [];
  vm.runInContext('RAIN = null', ctx);
  for (const n of ['calla', 'lluvia', 'lluvia', 'calla', 'calla']) seq.push({ name: n, calls: run(n).calls });
  return { names, list, rainSequence: seq };
}

/* ============================== clip: pp-engine.js ============================== */
function clipRef() {
  const SCENE = { w: 240, h: 216, s: 26, originX: -30, originY: 40 };
  const canvas = { width: 0, height: 0, getContext: () => ({ createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }), putImageData() {} }) };
  const ctx = vm.createContext({ window: { PP_SCENE: SCENE }, document: { getElementById: () => canvas }, matchMedia: () => ({ matches: false }) });
  vm.runInContext(read('docs/proyecto/pixel/pp-engine.js'), ctx, { filename: 'pp-engine.js' });
  const boxes = [[-1.5, -2, 0, 3, 2.5, 3.2], [0, 0, 0, 1, 1, 1], [-4.25, 1.5, .5, -2.75, 4, 2.55], [2, -3, 1.2, 5.5, -.5, 2.8]];
  const project = (x, y, z) => vm.runInContext(`(() => { const p = project(${x}, ${y}, ${z}); return [p.sx, p.sy]; })()`, ctx);
  const out = [];
  for (const w of boxes) {
    const [x0, y0, z0, x1, y1, z1] = w;
    out.push({ world: w, faces: {
      y: [[x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1]].map(p => project(...p)),
      x: [[x1, y0, z0], [x1, y1, z0], [x1, y1, z1], [x1, y0, z1]].map(p => project(...p)),
    } });
  }
  return { scene: SCENE, boxes: out };
}

/* ============================== camgo: juego.js ============================== */
function camgoRef() {
  const ctx = vm.createContext({});
  vm.runInContext(`
    var E = { CAM: {} }, cam = [22, 0, 196, 216], camA = null, F = 0;
    ${lineStarting(juego, 'const at=')}
    ${lineStarting(juego, 'function camGo(')}
    function step() {
    ${lineStarting(juego, '  if(camA){const t=Math.min(1')}
    }
  `, ctx, { filename: 'juego.js:camGo' });
  const moves = [
    ['a slide, nine frames by default', [22, 0, 196, 216], [44, 0, 196, 216], undefined],
    ['a slide, 5 frames', [44, 0, 196, 216], [0, 0, 196, 216], 5],
    ['a slide of 2x views, 12 frames', [10, 20, 98, 108], [140, 100, 98, 108], 12],
    ['a slide of 1 frame', [0, 0, 196, 216], [44, 0, 196, 216], 1],
    ['n = 0 is nine', [0, 0, 196, 216], [44, 0, 196, 216], 0],
    ['1x to 2x (different zoom), nine frames', [22, 0, 196, 216], [60, 50, 98, 108], undefined],
    ['2x to 1x (different zoom), 7 frames', [60, 50, 98, 108], [22, 0, 196, 216], 7],
    ['1x to 2x, 20 frames', [0, 0, 196, 216], [142, 108, 98, 108], 20],
    ['already there: nothing to wait for', [22, 0, 196, 216], [22, 0, 196, 216], 6],
  ];
  const out = [];
  for (const [title, from, to, n] of moves) {
    ctx.E.CAM.k = to; ctx.cam = from.slice(); ctx.camA = null; ctx.F = 40;
    let resolved = false;
    const p = vm.runInContext(`camGo('k', ${n === undefined ? 'undefined' : n})`, ctx);
    p.then(() => { resolved = true; });
    const positions = [];
    let steps = 0;
    if (vm.runInContext('camA', ctx) !== null) {
      while (vm.runInContext('camA', ctx) !== null) {
        vm.runInContext('F++; step()', ctx);
        steps++;
        positions.push(Array.from(ctx.cam));
        if (steps > 100) throw new Error('camGo does not end');
      }
    }
    out.push({ title, from, to, n: n === undefined ? null : n, steps, positions, end: Array.from(ctx.cam) });
  }
  return out;
}

const ref = { scene: S.out, sfx: sfxRef(), clip: clipRef(), camgo: camgoRef() };
const json = JSON.stringify(ref);
if (json.includes("'''")) throw new Error('the JSON holds three quotes');
const text = `// Made by tool/make_kit_ref.mjs from the old kit.js, juego.js and pp-engine.js. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// The reference for test/kit_logic_test.dart: JSON, \`{scene, sfx, clip, camgo}\`.
const String kitLogicRef =
    r'''${json}''';
`;
if (process.argv.includes('--check')) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'the kit logic reference is current' : 'the kit logic reference is NOT current: run tool/make_kit_ref.mjs');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${text.length} characters; ${ref.scene.variants.length} states, ${ref.scene.acts.length} act runs, ${ref.sfx.list.length} sfx runs, ${ref.clip.boxes.length} boxes, ${ref.camgo.length} moves`);
