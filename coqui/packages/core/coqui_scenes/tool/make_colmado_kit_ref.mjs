#!/usr/bin/env node
// El colmado's two kits (docs/proyecto/pixel/colmado-dentro.js and colmado-fuera.js) drawn piece by piece in headless
// Chrome, for the test that lib/src/colmado/colmado_dentro.dart and colmado_fuera.dart draw the same pixels
// (test/colmado_kit_test.dart). The kits keep their pieces inside a closure and export only a few; this tool reads each
// file as it is and, in the page only (the file on disk is not changed), adds the inner pieces to what it returns, so a
// piece can be drawn alone. Each case starts from empty buffers on an engine with the origin of one of the place's sets
// (240 x 216, S 26, shadows (.9, -.1)): El mostrador inside (-7, -32) and in the street (-46, -6), Los estantes
// (-222, -95), La caja (11, -30), Las frutas (-68, -10); then the hashes (test/support/hash.dart's) of pix, zb, kinds,
// ground and shadowMask, and the numbers the pieces give back. The cases run in this order, one page per engine, as the
// test runs them.
//
//   node tool/make_colmado_kit_ref.mjs            (in this package) writes test/support/fixtures/colmado_kit_refs.dart
//   node tool/make_colmado_kit_ref.mjs --check    says whether that file is what the kits draw now
//   node tool/make_colmado_kit_ref.mjs --dump DIR also writes each case's buffers (<engine>.<case>.pix.bin, .zb.bin)
//
// A piece another builder adds to a kit gets a case here and in the test, added at the end of its engine's list.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/colmado_kit_refs.dart');
const arg = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i + 1]; };
const CHECK = process.argv.includes('--check'), DUMP = arg('--dump');

// the kits as the page runs them, with their inner pieces added to what they give back
function opened(file, find, add) {
  const src = fs.readFileSync(path.join(PIX, file), 'utf8');
  if (!src.includes(find)) throw new Error(file + ': no "' + find + '" to open the kit at (the file changed: update this tool)');
  return src.replace(find, add + find);
}
const DENTRO = opened('colmado-dentro.js', '  return { RX1, RY1, WH,', '  const __inner = { walls, counter, shelves, chairs, storeRoom, pixelsX, stampY, paneX };\n')
  .replace('ESCALERA_PIE, ESCALERA_ALTO, CAJA_VENTANA, CAJA_GAVETA, CAJA_REPISA, NEVERA, floorAt, build, light, standIn };', 'ESCALERA_PIE, ESCALERA_ALTO, CAJA_VENTANA, CAJA_GAVETA, CAJA_REPISA, NEVERA, floorAt, build, light, standIn, __inner };');
if (!DENTRO.includes('standIn, __inner };')) throw new Error('colmado-dentro.js: its return line changed: update this tool');
const FUERA = opened('colmado-fuera.js', '  return api;\n})();', '  api.__inner = { building, stand, extras, cart, scale, bin, setSurtido: s => { BINS = SURTIDOS[s] || SURTIDOS.verduras; BW = (TX1 - TX0) / BINS.length; } };\n');

const ENGINES = [
  { name: 'dentro', origin: [-7, -32] },
  { name: 'estantes', origin: [-222, -95] },
  { name: 'caja', origin: [11, -30] },
  { name: 'calle', origin: [-46, -6] },
  { name: 'frutas', origin: [-68, -10] },
];

// the cases, run in the page (the same calls as test/colmado_kit_test.dart)
const CASES = (engine) => {
  const reset = () => { zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9); tufts.length = 0; leaves.length = 0; pendingShadows.length = 0; slabTops.length = 0; };
  const CDi = CD.__inner, CFi = CF.__inner;
  const floor = () => { for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = CD.floorAt(g.x, g.y, ix, iy, i); if (!c) continue; pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; } groundZ.set(zb); };
  // mostrador-set.html's buildSet, inside and in the street (estantes-set.html and caja-set.html do the same inside)
  const DARK = [46, 38, 40];
  const inside = o => { floor(); CD.build(o); flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs(); staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges(); CD.light(o); skyFill(() => rgb(...DARK)); };
  const street = o => { const HZ = CF.skyPlan(o).HZ; for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = CF.groundAt(g.x, g.y, ix, iy, i, HZ); if (!c) continue; pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; } groundZ.set(zb); CF.build(o); flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs(); staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges(); skyFill(CF.sky(o, HZ)); return HZ; };
  const SPOT = { leche: [1.95, .19, 1.36], pan: [2.75, .19, 1.36], mantequilla: [3.55, .19, 1.36], queso: [4.35, .19, 1.36], cafe: [5.1, .19, 1.36], arroz: [2.2, .19, 2.01], azucar: [3.1, .19, 2.01], jugo: [4, .19, 2.01], habichuelas: [4.9, .19, 2.01] };
  const byEngine = {
    dentro: [
      ['floorAt', () => floor()],
      ['walls', () => CDi.walls({})],
      ['walls.tarde.open', () => CDi.walls({ hora: 'tarde', atras: 'open' })],
      ['walls.novitrina.reloj', () => CDi.walls({ vitrina: false, reloj: true })],
      ['storeRoom', () => CDi.storeRoom()],
      ['counter', () => CDi.counter({})],
      ['counter.nevera', () => CDi.counter({ nevera: true })],
      ['counter.nocaja', () => CDi.counter({ caja: false, nevera: true })],
      ['shelves', () => CDi.shelves({})],
      ['shelves.all', () => CDi.shelves({ props: true, anillos: true, escalera: true, mesa: true })],
      ['standIn', () => { for (const k in SPOT) CD.standIn(k, ...SPOT[k]); CD.standIn('nada', 3, 1, 1); }],
      ['chairs', () => CDi.chairs()],
      ['stampY', () => CDi.stampY(2, 3, 1.5, ['#.#', '.#.', '#.#', '##'], { '#': rgb(200, 20, 20) })],
      ['pixelsX', () => CDi.pixelsX(.08, 3, 3.8, 1.5, 2.4, (b, z) => (Math.floor(b * 10) + Math.floor(z * 10)) % 2 ? rgb(10, 200, 10) : 0)],
      ['light', () => { floor(); CDi.walls({}); CD.light({}); }],
      ['light.tarde', () => { floor(); CDi.walls({ hora: 'tarde' }); CD.light({ hora: 'tarde' }); }],
      ['build', () => inside({})],
      ['build.tarde.open.nevera', () => inside({ hora: 'tarde', atras: 'open', nevera: true })],
      ['build.props', () => inside({ props: true })],
    ],
    estantes: [
      ['build', () => inside({ escalera: true, anillos: true, mesa: true })],
      ['shelves.all', () => CDi.shelves({ props: true, anillos: true, escalera: true, mesa: true })],
    ],
    caja: [
      ['build', () => inside({})],
      ['build.tarde', () => inside({ hora: 'tarde', reloj: true })],
    ],
    calle: [
      ['groundAt', () => { const o = { hora: 'manana', solX: 206 }, HZ = CF.skyPlan(o).HZ; for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = CF.groundAt(g.x, g.y, ix, iy, i, HZ); if (c) pix[i] = c; } return HZ; }],
      ['building', () => CFi.building({})],
      ['building.open', () => CFi.building({ puerta: 'open' })],
      ['stand.verduras', () => { CFi.setSurtido('verduras'); CFi.stand({}); }],
      ['stand.frutas', () => { CFi.setSurtido('frutas'); CFi.stand({ aguja: 'medio' }); }],
      ['scale.libra', () => CFi.scale({ aguja: 'libra' })],
      ['scale.0', () => CFi.scale({ aguja: '0' })],
      ['cart', () => CFi.cart()],
      ['extras', () => CFi.extras({ carro: true })],
      ['sky', () => skyFill(CF.sky({ hora: 'manana', solX: 206 }, CF.skyPlan({ hora: 'manana', solX: 206 }).HZ))],
      ['sky.tarde', () => skyFill(CF.sky({ hora: 'tarde' }, CF.skyPlan({ hora: 'tarde' }).HZ))],
      ['build', () => street({ hora: 'manana', puerta: 'shut', puesto: true, surtido: 'verduras', solX: 206 })],
      ['build.tarde.open', () => street({ hora: 'tarde', puerta: 'open', puesto: true, surtido: 'verduras', solX: 206 })],
      ['build.sinpuesto', () => street({ hora: 'manana', puesto: false, carro: true })],
    ],
    frutas: [
      ['build', () => street({ hora: 'manana', puerta: 'shut', carro: true, surtido: 'frutas', aguja: 'libra' })],
      ['build.verduras', () => street({ hora: 'tarde', puerta: 'open', surtido: 'verduras' })],
      ['build.otro', () => street({ surtido: 'otro', aguja: 'nada' })],
    ],
  };
  const b64 = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
  const hash = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let x = 0x811C9DC5, y = 0x01234567; for (let i = 0; i < u.length; i++) { x = Math.imul(x ^ u[i], 0x01000193) >>> 0; y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0; } return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0'); };
  const out = [];
  for (const [name, fn] of byEngine[engine]) {
    reset();
    const r = fn();
    out.push({ engine, name, pix: hash(pix), zb: hash(zb), kinds: hash(kinds), ground: hash(ground), shadow: hash(shadowMask), result: r === undefined ? null : r, bufs: { pix: b64(pix), zb: b64(zb) } });
  }
  if (engine === 'calle') {
    CF.__inner.setSurtido('verduras');
    const v = ['tomates', 'cebollas', 'papas', 'platanos'].map(k => [CF.binX(k), CF.binBox(k)]);
    CF.__inner.setSurtido('frutas');
    const f = ['aguacates', 'pinas', 'limones'].map(k => [CF.binX(k), CF.binBox(k)]);
    out.push({ engine, name: 'numbers', result: {
      skyPlan: [CF.skyPlan({}), CF.skyPlan({ hora: 'tarde' }), CF.skyPlan({ solX: 206 }), CF.skyPlan({ hora: 'tarde', solX: 120 })],
      bins: { verduras: v, frutas: f },
      tableZ: [-1, .95, 1.2, 1.5, 2, 3].map(y => CF.tableZ(y)),
      dial: CF.PESA_DIAL, plato: CF.PESA_PLATO,
      dentro: { ESCALERA_PIE: CD.ESCALERA_PIE, ESCALERA_ALTO: CD.ESCALERA_ALTO, CAJA_VENTANA: CD.CAJA_VENTANA, CAJA_GAVETA: CD.CAJA_GAVETA, CAJA_REPISA: CD.CAJA_REPISA, NEVERA: CD.NEVERA, MESA: CD.MESA, SILLA: CD.SILLA },
    } });
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
  for (const f of ['pp-engine.js', 'mapa.js', 'set-kit.js']) await page.addScriptTag({ content: fs.readFileSync(path.join(PIX, f), 'utf8') });
  await page.addScriptTag({ content: DENTRO });
  await page.addScriptTag({ content: FUERA });
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
  '// Made by tool/make_colmado_kit_ref.mjs from docs/proyecto/pixel/colmado-dentro.js and colmado-fuera.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// El colmado's two kits drawn piece by piece by the JavaScript (headless Chrome): each case's engine, the hashes of",
  '/// pix, zb, kinds, ground and shadowMask (test/support/hash.dart), and the numbers the pieces give back.',
  "const String colmadoKitRefs = r'''" + json + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'colmado_kit_refs.dart: up to date' : 'colmado_kit_refs.dart: STALE (run node tool/make_colmado_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
