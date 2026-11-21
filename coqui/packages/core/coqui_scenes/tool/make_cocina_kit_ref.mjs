#!/usr/bin/env node
// The kitchen's kit (docs/proyecto/pixel/cocina-kit.js) drawn piece by piece in headless Chrome, for the test that
// lib/src/cocina_kit.dart draws the same pixels (test/cocina_kit_test.dart). Each case starts from empty buffers on one
// engine (240 x 216, S 26, origin (-102, -40), shadows (.9, -.1): La estufa's) and calls the kit as the test does; then
// the hashes (test/support/hash.dart's) of pix, zb, kinds and ground, and the numbers the pieces give back. The cases
// run in this order on one page, as the test runs them on one engine (cocinaBuild lays the floor once per page).
//
//   node tool/make_cocina_kit_ref.mjs            (in this package) writes test/support/fixtures/cocina_kit_refs.dart
//   node tool/make_cocina_kit_ref.mjs --check    says whether that file is what the kit draws now
//   node tool/make_cocina_kit_ref.mjs --dump DIR also writes each case's buffers (<case>.pix.bin, .zb.bin) into DIR
//
// A function La mesa's designer adds to cocina-kit.js gets a case here and in the test, added at the end.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/cocina_kit_refs.dart');
const arg = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i + 1]; };
const CHECK = process.argv.includes('--check'), DUMP = arg('--dump');

// the cases, run in the page (the same calls as test/cocina_kit_test.dart)
const CASES = () => {
  const reset = () => { zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9); };
  const paint = (f, p, q, sh) => rgb(f === 'top' ? 200 : f === 'front' ? 100 : 50, p * 40, q * 90 + (sh ? 30 : 0));
  const plan = occlusion => ({
    XR: 9, YL: 6, occlusion,
    windows: [
      { face: 'y', a0: 4, a1: 5.5, z0: 1.6, z1: 2.7, view: 'arbusto' },
      { face: 'x', a0: 2, a1: 3.4, z0: 1.5, z1: 2.8, view: 'patio', bars: 'medio' },
      { name: 'puerta', face: 'y', a0: 6.5, a1: 7.6, z0: 0, z1: 2.5, door: true, view: 'patio', horizon: 1.2 },
      { face: 'x', a0: 4.2, a1: 5.2, z0: 1.7, z1: 2.6, bushA: .1, bushZ: 2.1, bushR: .4 },
    ],
    band: { y: [[0, 4], [5.6, 6.4]], x: [[0, 2]] },
    floor: (x, y) => x > 6.5 && x < 7.6 && y < .3 ? rgb(90, 90, 90) : 0,
    furnish() {
      cocinaBase('y', 0, 2.4, { noEnd: true });
      cocinaStove('y', 2.4, { noEnd: true });
      cocinaBase('y', 2.4 + K.STW, 4.2);
      cocinaHood('y', 2.4);
      cocinaBackguard('y', 2.4);
      cocinaWallCupboard('y', .2, 2.2);
      cocinaShelf('x', .5, 1.8, 2.4);
      kSolid('y', 1, 1.6, 2.5, 3.1, 0, .7, KC.woodL);
    },
    shadows() { cocinaShadowBlock(1, 2.5, 1.6, 3.1); cocinaShadowFoot(5, 4); cocinaShadowFoot(5.5, 4.2, .12); },
  });
  const cases = [
    ['cocinaFloor', () => { for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), c = cocinaFloor(g.x, g.y); if (c) pix[iy * W + ix] = c; } }],
    ['cocinaWallColour', () => { planeFace('y', 0, 0, 8, 0, K.WH, (a, z) => cocinaWallColour(false, a, z, a > 2 && a < 6)); planeFace('x', 0, 0, 6, 0, K.WH, (a, z) => cocinaWallColour(true, a, z, a < 3)); }],
    ['kBox', () => { kBox('y', 1, 3, .2, 1.1, .3, 1.5, paint); kBox('x', 1, 2.5, .3, 1, .2, 1.8, paint); kBox('y', 4, 5, 1.5, 2.3, 0, .9, paint, 'tf'); kBox('x', 3, 4, 2, 2.5, 0, 1, paint, 'e'); }],
    ['kSolid', () => { kSolid('y', 1, 2.5, .2, 1, 0, 1.2, KC.wood); kSolid('x', 1, 3, .2, .8, .5, 1.6, KC.steel, 'fe'); }],
    ['cocinaBase', () => [cocinaBase('y', .5, 3.2), cocinaBase('y', 3.2, 5, { noEnd: true, doors: 1 }), cocinaBase('x', .5, 2.5, { doors: 3 })]],
    ['cocinaWallCupboard', () => [cocinaWallCupboard('y', .5, 2.2), cocinaWallCupboard('x', 1, 2.6, { z0: 2.1, z1: 2.9, depth: .4, doors: 3 })]],
    ['cocinaShelf', () => [cocinaShelf('y', 1, 3.5, 2.5), cocinaShelf('x', 1, 3, 2.3, { depth: .5 })]],
    ['cocinaStove', () => [cocinaStove('y', 2), cocinaStove('x', 1.5, { knobs: 3, horno: true, noEnd: true })]],
    ['cocinaHood', () => { cocinaHood('y', 2); cocinaHood('x', 1.5, { top: 3 }); }],
    ['cocinaBackguard', () => { cocinaBackguard('y', 2); cocinaBackguard('x', 1.5, { top: 2.2 }); }],
    ['cocinaWindow', () => { cocinaWindow({ face: 'y', a0: 3, a1: 4.6, z0: 1.4, z1: 2.6, view: 'patio' }); cocinaWindow({ face: 'x', a0: 2, a1: 3, z0: 1.2, z1: 2.4, door: true }); }],
    ['cocinaBuild', () => cocinaBuild(plan('shade'))],
    ['cocinaBuild.bakeOcclusion', () => cocinaBuild(plan(undefined))],
    ['cocinaBuild.none', () => cocinaBuild(plan('none'))],
    ['cocinaOcclusion', () => { cocinaBuild(plan('none')); cocinaOcclusion(); }],
  ];
  const b64 = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
  const hash = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let x = 0x811C9DC5, y = 0x01234567; for (let i = 0; i < u.length; i++) { x = Math.imul(x ^ u[i], 0x01000193) >>> 0; y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0; } return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0'); };
  cocinaCheckScene();
  const out = [];
  for (const [name, fn] of cases) {
    reset();
    const r = fn();
    out.push({ name, pix: hash(pix), zb: hash(zb), kinds: hash(kinds), ground: hash(ground), result: r === undefined ? null : r, bufs: { pix: b64(pix), zb: b64(zb) } });
  }
  // the numbers of the wall's frame and the outside
  const win = { face: 'y', a0: 4, a1: 5.5, z0: 1.6, z1: 2.7 };
  out.push({ name: 'numbers', result: {
    kpt: [kpt('y', 1.5, .4, 1.3), kpt('x', 1.5, .4, 1.3)],
    kWallPixel: [kWallPixel('y', 0, 120, 60), kWallPixel('x', 0, 30, 90), kWallPixel('y', -1.92, 140, 50), kWallPixel('x', -1.92, 10, 70)],
    kLit: [kLit(KC.wood, false), kLit(KC.wood, true)],
    KDROP,
    kView: [
      kView('arbusto', .3, 2.0, 5, 7, win), kView('arbusto', -.6, 2.6, 6, 7, win), kView('arbusto', 1.5, 1.7, 1, 2, win),
      kView('patio', .4, 3.4, 3, 3, win), kView('patio', .1, 2.03, 3, 4, win), kView('patio', .15, 1.9, 5, 5, win), kView('patio', .7, 1.2, 9, 9, win),
    ],
  } });
  return out;
};

const browser = await chromium.launch();
const page = await browser.newPage();
const problems = [];
page.on('pageerror', e => problems.push('pageerror: ' + e));
await page.setContent('<!doctype html><canvas id="c"></canvas>');
await page.addScriptTag({ content: 'window.PP_SCENE = { w: 240, h: 216, s: 26, originX: -102, originY: -40, shadowX: .9, shadowY: -.1 };' });
for (const f of ['pp-engine.js', 'mapa.js', 'set-kit.js', 'cocina-kit.js']) await page.addScriptTag({ content: fs.readFileSync(path.join(PIX, f), 'utf8') });
const got = await page.evaluate(CASES);
await browser.close();
if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
if (DUMP) {
  fs.mkdirSync(DUMP, { recursive: true });
  for (const c of got) if (c.bufs) for (const k of ['pix', 'zb']) fs.writeFileSync(path.join(DUMP, c.name + '.' + k + '.bin'), Buffer.from(c.bufs[k], 'base64'));
}
const rows = got.map(c => { const o = Object.assign({}, c); delete o.bufs; return o; });
const json = JSON.stringify(rows, null, 1);
const made = [
  '// Made by tool/make_cocina_kit_ref.mjs from docs/proyecto/pixel/cocina-kit.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// The kitchen's kit drawn piece by piece by the JavaScript (headless Chrome): each case's hashes of pix, zb, kinds and",
  '/// ground (test/support/hash.dart), and the numbers the pieces give back.',
  "const String cocinaKitRefs = r'''" + json + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'cocina_kit_refs.dart: up to date' : 'cocina_kit_refs.dart: STALE (run node tool/make_cocina_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
