#!/usr/bin/env node
// La calle's kit (docs/proyecto/pixel/calle-base.js) drawn piece by piece in headless Chrome, for the test that
// lib/src/calle/calle_base.dart draws the same pixels (test/calle_kit_test.dart). Every piece of the kit is exported
// by the file (`CL`), so nothing is opened. Each case starts from empty buffers on an engine with the origin of one of
// the place's sets (240 x 216, S 26, shadows (.9, -.1)): La esquina (30, -8), La parada (70, -16), Las tiendas (0, 24)
// and El cruce (-24, 10); then the hashes (test/support/hash.dart's) of pix, zb, kinds, ground and shadowMask, and the
// numbers the pieces give back. The cases run in this order, one page per engine, as the test runs them.
//
//   node tool/make_calle_kit_ref.mjs            (in this package) writes test/support/fixtures/calle_kit_refs.dart
//   node tool/make_calle_kit_ref.mjs --check    says whether that file is what the kit draws now
//   node tool/make_calle_kit_ref.mjs --dump DIR also writes each case's buffers (<engine>.<case>.pix.bin, .zb.bin)
//
// A piece another builder adds to the kit gets a case here and in the test, added at the end of its engine's list.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/calle_kit_refs.dart');
const arg = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i + 1]; };
const CHECK = process.argv.includes('--check'), DUMP = arg('--dump');

const ENGINES = [
  { name: 'esquina', origin: [30, -8] },
  { name: 'parada', origin: [70, -16] },
  { name: 'tiendas', origin: [0, 24] },
  { name: 'cruce', origin: [-24, 10] },
];

// the cases, run in the page (the same calls as test/calle_kit_test.dart)
const CASES = (engine) => {
  const reset = () => { zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9); tufts.length = 0; leaves.length = 0; pendingShadows.length = 0; slabTops.length = 0; CL.NIGHT = false; };
  // a ground of each painter over the whole picture (esquina-set.html's ground pass, one painter at a time)
  const ground_ = fn => { for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = fn(g.x, g.y, ix, iy); if (!c) continue; pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = KIND_ROAD; } groundZ.set(zb); };
  const baked = () => { flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs(); staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges(); };
  const pic = (u, v) => (Math.hypot(u - .5, v - .5) < .3) ? rgb(200, 40, 40) : 0;
  const common = [
    ['slab', () => ground_(CL.slab)],
    ['asphalt', () => ground_((x, y, ix, iy) => CL.asphalt(ix, iy))],
    ['kerb.paint', () => ground_((x, y) => ((x + 40) % 2) < 1 ? CL.kerb() : CL.paint(CL.LINE))],
    ['grass', () => ground_(CL.grass)],
    ['faceY', () => CL.faceY(1, -2, 2, 0, 2, (a, z) => (Math.floor(a * 4) + Math.floor(z * 4)) % 2 ? rgb(10, 200, 10) : 0)],
    ['faceX.step', () => CL.faceX(1, -2, 2, 0, 2, (b, z) => rgb(100 + b * 20, 50, 200 - z * 30), CL.PP)],
    ['top', () => CL.top(-1, -1, 2, 1.5, .5, (a, b) => a > 0 && b > 0 ? 0 : rgb(220, 120, 40))],
    ['box', () => CL.box(-1, -1, 0, 1, 1, 1.5, [150, 104, 62])],
    ['box.topFn', () => CL.box(-1, -1, 0, 1, 1, 1.5, [70, 120, 206], (a, b) => a > .3 ? rgb(250, 250, 250) : 0)],
    ['wallAlongX', () => CL.wallAlongX(0, -10, 0, 3.5, CL.SALMON, CL.TEAL, [[-2.62, -1.08, 0, 2.67], [-6.4, -4.2, .85, 2.3]])],
    ['wallAlongY', () => CL.wallAlongY(0, -9, 0, 3.5, CL.SALMON, CL.TEAL, [[-4, -2, 1, 2]])],
    ['doorX.shut', () => CL.doorX(0, -2.5, -1.2, 2.55, false)],
    ['doorX.open', () => CL.doorX(0, -2.5, -1.2, 2.55, true)],
    ['doorX.plain', () => CL.doorX(0, 1, 2.1, 2.4, false, [60, 90, 170], false)],
    ['signX', () => CL.signX(0, -2.95, -.75, 2.75, 3.42, pic)],
    ['signY', () => CL.signY(0, -4, -2, 2, 2.8, pic)],
    ['windowY', () => CL.windowY(0, -4, -2.5, 1, 2.2)],
    ['awningY', () => CL.awningY(0, -5, -1, 2.9, 2.6, .8)],
    ['tree', () => CL.tree(2, 3, 1.3, .9)],
    ['tree.colours', () => CL.tree(-1, 4, 1.9, 1.35, [96, 150, 70], [140, 190, 90])],
    ['trafficLight', () => CL.trafficLight(1.66, 1.5)],
    ['cone', () => { CL.cone(1, 4.25); CL.cone(-.3, 2.3); }],
    ['windowX', () => CL.windowX(0, -6.3, -4.3, .95, 2.2)],
    ['windowX.night', () => { CL.NIGHT = true; CL.windowX(0, -6.3, -4.3, .95, 2.2); }],
    ['awningX', () => CL.awningX(0, -6.6, -4.0, 2.9, 2.6, .8)],
    ['seat', () => CL.seat(-1, 6, 1)],
    ['seat.bench', () => CL.seat(2, 6.5, 4, false, [196, 186, 168])],
    ['signPole', () => CL.signPole(2, 1.2, 2.3, .62, .62, [40, 110, 200], pic)],
    ['houseX', () => CL.houseX(0, -4.2, .2, 3.2, [244, 170, 150], [200, 110, 96], -1.6, -3.4)],
    ['houseX.none', () => CL.houseX(0, .2, 4.6, 3.4, [196, 220, 150], [120, 160, 90], null, 2.6, [96, 70, 110], 2.0)],
    ['sky.manana', () => skyFill(CL.sky('manana', [60, 30, 12]))],
    ['sky.tarde', () => skyFill(CL.sky('tarde', [200, 20, 14]))],
    ['sky.noche', () => skyFill(CL.sky('noche', null))],
    ['sky.temprano', () => skyFill(CL.sky('temprano', [30, 40, 10]))],
    ['sky.gris', () => skyFill(CL.sky('gris', null))],
    ['sky.otra', () => skyFill(CL.sky('nada', null))],
    ['vehicle.carro.i', () => CL.vehicle('carro', .7, 4.8, 'i')],
    ['vehicle.carro.d', () => CL.vehicle('carro', -.9, 4.8, 'd')],
    ['vehicle.azul.i', () => CL.vehicle('azul', 5.1, 4.8, 'i')],
    ['vehicle.azul.d', () => CL.vehicle('azul', -.9, 4.8, 'd')],
    ['vehicle.guagua.i', () => CL.vehicle('guagua', 4.5, 4.8, 'i')],
    ['vehicle.guagua.d', () => CL.vehicle('guagua', -1.5, 4.8, 'd')],
    ['vehicle.guagua.i.arbol', () => CL.vehicle('guagua', 4.5, 4.8, 'i', 'arbol')],
    ['vehicle.guagua.d.toldo', () => CL.vehicle('guagua', -1.5, 4.8, 'd', 'toldo')],
    ['vehicle.guagua.i.casa', () => CL.vehicle('guagua', 4.5, 2.8, 'i', 'casa')],
    ['vehicle.guagua.i.otro', () => CL.vehicle('guagua', 4.5, 2.8, 'i', 'otro')],
    ['baked.street', () => { ground_((x, y, ix, iy) => y > 1.8 && y < 5.8 ? CL.asphalt(ix, iy) : CL.slab(x, y, ix, iy)); CL.vehicle('carro', .7, 4.8, 'i'); CL.vehicle('guagua', 4.5, 2.8, 'd', 'arbol'); CL.trafficLight(1.66, 1.5); CL.tree(-3, 7.5, 1.3, .9); CL.cone(3, 6.2); baked(); }],
  ];
  const b64 = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
  const hash = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let x = 0x811C9DC5, y = 0x01234567; for (let i = 0; i < u.length; i++) { x = Math.imul(x ^ u[i], 0x01000193) >>> 0; y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0; } return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0'); };
  const cases = engine === 'esquina' ? common : common.filter(c => ['slab', 'box', 'houseX', 'tree', 'seat', 'signPole', 'vehicle.guagua.i.arbol', 'baked.street', 'sky.tarde'].includes(c[0]));
  const out = [];
  for (const [name, fn] of cases) {
    reset();
    const r = fn();
    out.push({ engine, name, pix: hash(pix), zb: hash(zb), kinds: hash(kinds), ground: hash(ground), shadow: hash(shadowMask), result: r === undefined ? null : r, bufs: { pix: b64(pix), zb: b64(zb) } });
  }
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
  for (const f of ['pp-engine.js', 'mapa.js', 'set-kit.js', 'calle-base.js']) await page.addScriptTag({ content: fs.readFileSync(path.join(PIX, f), 'utf8') });
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
  '// Made by tool/make_calle_kit_ref.mjs from docs/proyecto/pixel/calle-base.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// La calle's kit drawn piece by piece by the JavaScript (headless Chrome): each case's engine, the hashes of pix, zb,",
  '/// kinds, ground and shadowMask (test/support/hash.dart), and the numbers the pieces give back.',
  "const String calleKitRefs = r'''" + json + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'calle_kit_refs.dart: up to date' : 'calle_kit_refs.dart: STALE (run node tool/make_calle_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
