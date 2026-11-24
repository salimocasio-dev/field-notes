#!/usr/bin/env node
// La plaza's kit (docs/proyecto/pixel/plaza-base.js, `PZ`, with the three pieces of calle-base.js it uses: CL.grass,
// CL.tree, CL.sky) drawn piece by piece in headless Chrome, for the test that lib/src/plaza/plaza_base.dart draws the same
// pixels (test/plaza_kit_test.dart). The kit gives back every piece it has; the files are read as they are. Each case
// starts from empty buffers on an engine with the origin of one of the sets that load the kit (240 x 216, S 26, shadows
// (.9, -.1)): La plaza's four (plaza (0, 10), reloj (0, 44), quiosco (0, 14), calendario (0, 12)) and two of the places
// whose kits stand on it (orilla (0, -30), entrada (0, -42)); then the hashes (test/support/hash.dart's) of pix, zb,
// kinds, ground, shadowMask and staticShadow, and the numbers the pieces give back. The cases run in this order, one page
// per engine, as the test runs them.
//
//   node tool/make_plaza_kit_ref.mjs            (in this package) writes test/support/fixtures/plaza_kit_refs.dart
//   node tool/make_plaza_kit_ref.mjs --check    says whether that file is what the kit draws now
//   node tool/make_plaza_kit_ref.mjs --dump DIR also writes each case's buffers (<engine>.<case>.pix.bin, .zb.bin)
//
// A piece another builder adds to the kit gets a case here and in the test, added at the end of its engine's list.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/plaza_kit_refs.dart');
const arg = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i + 1]; };
const CHECK = process.argv.includes('--check'), DUMP = arg('--dump');

const ENGINES = [
  { name: 'plaza', origin: [0, 10] },
  { name: 'reloj', origin: [0, 44] },
  { name: 'quiosco', origin: [0, 14] },
  { name: 'calendario', origin: [0, 12] },
  { name: 'orilla', origin: [0, -30] },
  { name: 'entrada', origin: [0, -42] },
];

// the cases, run in the page (the same calls as test/plaza_kit_test.dart)
const CASES = (engine) => {
  const reset = () => { zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9); tufts.length = 0; leaves.length = 0; pendingShadows.length = 0; slabTops.length = 0; glowReset(); PZ.NIGHT = false; CL.NIGHT = false; };
  // a ground pass: every pixel takes fn(u, v, ix, iy) of its ground point (as plaza-set.html's groundAt)
  const ground1 = fn => { for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix, [u, v] = PZ.uv(g.x, g.y), c = fn(u, v, ix, iy); if (!c) continue; pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = v < -3.4 ? KIND_GRASS : KIND_ROAD; } groundZ.set(zb); };
  const bake = () => { flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs(); staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges(); };
  const pattern = (u, z) => (Math.floor(u * 7) + Math.floor(z * 5)) % 3 === 0 ? 0 : (Math.floor(u * 7) + Math.floor(z * 5)) % 3 === 1 ? rgb(200, 40, 40) : rgb(40, 40, 200);
  const all = [
    ['paving', () => ground1(PZ.paving)],
    ['grass', () => ground1(PZ.grass)],
    ['box', () => PZ.box(.5, .2, 0, .8, 1.1, .4, PZ.STONE)],
    ['box.fn', () => PZ.box(-1.3, 1.1, .2, 1.4, .6, .3, PZ.TILE, (s, t, z, face) => face === 'top' ? rgb(10, 200, 10) : face === 'front' && z > .8 ? rgb(200, 200, 10) : 0)],
    ['wall', () => PZ.wall(-2, 1.5, -.6, .2, 2.4, pattern)],
    ['flat', () => PZ.flat(-1.5, -1, 2, 1.5, .5, (u, v) => (Math.floor(u * 4) + Math.floor(v * 4)) % 2 ? rgb(230, 120, 30) : 0)],
    ['slope', () => PZ.slope(-2, 2, .8, 1.6, -.6, 2.4, (u, b) => shade(PZ.TILE, b > .5 ? 3.0 : 2.4, u, b))],
    ['post', () => { PZ.post(.3, .5, 0, 2.2, .06, PZ.IRON); PZ.post(-2.2, 1.4, .5, 1.8, .12, PZ.WOOD_D); }],
    ['ball', () => { PZ.ball(-.5, .4, .6, .4, PZ.OCHRE); PZ.ball(1.4, .6, .3, .2, PZ.CREAM, 'smooth'); PZ.ball(2.2, -.2, 1.2, .25, PZ.WHITE, 'gloss'); }],
    ['shadow', () => { ground1(PZ.paving); PZ.shadow(.4, .8, .5, .5); PZ.shadow(-2, -.4, 1.6, .3); bake(); }],
    ['tree', () => { ground1(PZ.paving); PZ.tree(.6, -2.3, 1.9, 1.45); bake(); }],
    ['tree.colours', () => PZ.tree(-2.4, .2, 1.2, .8, CL.LEAF, CL.LEAF_L)],
    ['tree.other', () => PZ.tree(2.5, .4, 1.6, 1.0, [180, 90, 140], [230, 150, 190])],
    ['seat', () => { ground1(PZ.paving); PZ.seat(.6, 0, 2.0); bake(); }],
    ['seat.short.noback', () => PZ.seat(-1.5, 1.2, 1.0, false, [120, 140, 200])],
    ['seat.long', () => PZ.seat(.2, -1, 3.1, true)],
    ['seatSide', () => PZ.seatSide(1.2, -1, 1.4)],
    ['seatSide.colour', () => PZ.seatSide(-2, .2, 1.1, [120, 80, 60])],
    ['bed', () => PZ.bed(-1.2, -2.95, -.1, -2.3)],
    ['bed.cols', () => PZ.bed(2.4, -2.95, 4.6, -2.3, [[250, 250, 250], [236, 120, 170], [250, 206, 70]])],
    ['hedge', () => PZ.hedge(-5, -4.75, 5, -4.75)],
    ['hedge.short', () => PZ.hedge(-1, 1, -.9, 1.1)],
    ['lamp', () => { ground1(PZ.paving); PZ.lamp(-3.95, -2.6); bake(); }],
    ['lamp.night', () => { ground1(PZ.paving); PZ.NIGHT = CL.NIGHT = true; PZ.lamp(-.5, .4); PZ.lamp(2, 1, 2.4); bake(); PZ.light('noche'); }],
    ['flags', () => PZ.flags(-3, 2.6, 3, 2.2, .2)],
    ['flags.cols', () => PZ.flags(-1.1, 1.8, 3.6, 2.2, .14, .25, [[10, 200, 10], [200, 10, 200]])],
    ['sky.manana.tower', () => skyFill(PZ.sky('manana', PZ.farTower(206, 55)))],
    ['sky.mediodia.tower', () => skyFill(PZ.sky('mediodia', PZ.farTower(120, 80, 50)))],
    ['sky.tarde', () => skyFill(PZ.sky('tarde', PZ.farTower(40, 60, 30)))],
    ['sky.ocaso', () => skyFill(PZ.sky('ocaso'))],
    ['sky.noche', () => skyFill(PZ.sky('noche'))],
    ['sky.otra', () => skyFill(PZ.sky('lluvia', null, PZ.farTower(100, 50)))],
    ['light.tarde', () => { ground1(PZ.paving); PZ.seat(.6, 0, 2.0); bake(); PZ.light('tarde'); skyFill(PZ.sky('tarde')); }],
    ['light.ocaso', () => { ground1(PZ.grass); PZ.tree(0, -1, 1.5, 1); bake(); PZ.light('ocaso'); }],
    ['light.manana', () => { ground1(PZ.paving); PZ.box(0, 0, 0, 1, 1, 1, PZ.STONE); PZ.light('manana'); PZ.light('mediodia'); }],
    ['lit.dim.up', () => { for (let i = 0; i < 40; i++) { const u = -4 + i * .2; PZ.wall(u, u + .2, 0, 0, 1, (a, z) => z < .33 ? PZ.lit(PZ.STONE, a, z) : z < .66 ? PZ.dim(PZ.WOOD, a, z) : PZ.up(PZ.TILE, a, z)); } }],
  ];
  const b64 = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
  const hash = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let x = 0x811C9DC5, y = 0x01234567; for (let i = 0; i < u.length; i++) { x = Math.imul(x ^ u[i], 0x01000193) >>> 0; y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0; } return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0'); };
  // every engine runs every case: the origins differ, the kit is the same
  const out = [];
  for (const [name, fn] of all) {
    reset();
    const r = fn();
    out.push({ engine, name, pix: hash(pix), zb: hash(zb), kinds: hash(kinds), ground: hash(ground), shadow: hash(shadowMask), still: hash(staticShadow), result: r === undefined ? null : r, bufs: { pix: b64(pix), zb: b64(zb) } });
  }
  const pts = [[0, 0], [1, 0], [0, 1], [-2.5, 3.7], [3.05, 3.5], [-3.72, -1.3]];
  out.push({ engine, name: 'numbers', result: {
    A: PZ.A,
    xy: pts.map(p => PZ.xy(p[0], p[1])), uv: pts.map(p => PZ.uv(p[0], p[1])), P: pts.map(p => PZ.P(p[0], p[1], .5)),
    lit: [PZ.lit(PZ.STONE), PZ.lit(PZ.WOOD, 1.3, .2), PZ.dim(PZ.IRON, .4, .9), PZ.up(PZ.TILE, 2, 3)],
    paving: pts.map((p, i) => PZ.paving(p[0] + .3, p[1] + .2, i * 17, i * 31)),
    grass: pts.map((p, i) => PZ.grass(p[0], p[1], i * 5, i * 9)),
    tower: [[200, 20], [206, 33], [206, 40], [203, 40], [212, 15], [206, 52], [190, 30]].map(([ix, iy]) => PZ.farTower(206, 55)(ix, iy)),
  } });
  return out;
};

const browser = await chromium.launch();
const problems = [];
const got = [];
for (const en of ENGINES) {
  const page = await browser.newPage();
  page.on('pageerror', e => problems.push(en.name + ': pageerror: ' + e));
  await page.setContent('<!doctype html><canvas id="c"></canvas>');
  await page.addScriptTag({ content: `window.PP_SCENE = { w: 240, h: 216, s: 26, originX: ${en.origin[0]}, originY: ${en.origin[1]}, shadowX: .9, shadowY: -.1 };` });
  for (const f of ['pp-engine.js', 'mapa.js', 'set-kit.js', 'calle-base.js', 'plaza-base.js']) await page.addScriptTag({ content: fs.readFileSync(path.join(PIX, f), 'utf8') });
  got.push(...await page.evaluate(CASES, en.name));
  await page.close();
}
await browser.close();
if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
if (DUMP) {
  fs.mkdirSync(DUMP, { recursive: true });
  for (const c of got) if (c.bufs) for (const k of ['pix', 'zb']) fs.writeFileSync(path.join(DUMP, c.engine + '.' + c.name + '.' + k + '.bin'), Buffer.from(c.bufs[k], 'base64'));
}
const rows = got.map(c => { const o = Object.assign({}, c); delete o.bufs; return o; });
const json = JSON.stringify(rows, null, 1);
const made = [
  '// Made by tool/make_plaza_kit_ref.mjs from docs/proyecto/pixel/plaza-base.js (and calle-base.js). Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// La plaza's kit drawn piece by piece by the JavaScript (headless Chrome): each case's engine, the hashes of pix, zb,",
  '/// kinds, ground, shadowMask and staticShadow (test/support/hash.dart), and the numbers the pieces give back.',
  "const String plazaKitRefs = r'''" + json + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'plaza_kit_refs.dart: up to date' : 'plaza_kit_refs.dart: STALE (run node tool/make_plaza_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
