#!/usr/bin/env node
// La calle's vehicles baked by the JavaScript (docs/proyecto/pixel/calle-base.js `CL.vehicle`) the way
// lib/src/calle/calle_vehicles.dart bakes its sprites, for the test that every sprite is the JavaScript's picture pixel
// for pixel (test/calle_vehicles_test.dart). The bake: an engine of 240 x 216, S 26, origin (0, 0), shadows (.9, -.1),
// empty; a flat ground under every pixel; vehicle(kind, 3, 3, heading, board); shadeEdges(); the pixels whose depth is not
// the ground's, cropped to their box, each with its depth less the depth of the point (3, 3, 0). Then the same under
// La esquina's afternoon light (esquina-set.html: lightPass([1.0, .93, .84], [10, 2, -8])). For each: the box, the
// floor middle's column and row in it, and the hashes (test/support/hash.dart's) of the cropped picture and depths.
//
//   node tool/make_calle_vehicles_ref.mjs           writes test/support/fixtures/calle_vehicles_refs.dart
//   node tool/make_calle_vehicles_ref.mjs --check   says whether that file is what the JavaScript bakes now
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/calle_vehicles_refs.dart');
const CHECK = process.argv.includes('--check');

const LOOKS = [];
for (const k of ['carro', 'azul', 'guagua']) for (const h of ['i', 'd']) LOOKS.push([k, h, null]);
for (const b of ['arbol', 'toldo', 'casa']) for (const h of ['i', 'd']) LOOKS.push(['guagua', h, b]);

const run = (looks) => {
  const hash = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let x = 0x811C9DC5, y = 0x01234567; for (let i = 0; i < u.length; i++) { x = Math.imul(x ^ u[i], 0x01000193) >>> 0; y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0; } return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0'); };
  const out = [];
  for (const [kind, heading, board] of looks) for (const light of [null, 'tarde']) {
    zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9); pendingShadows.length = 0; glowReset();
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const g = unproject(ix + .5, iy + .5), i = iy * W + ix; pix[i] = rgb(128, 128, 128); ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; }
    groundZ.set(zb);
    CL.vehicle(kind, 3, 3, heading, board);
    shadeEdges();
    if (light === 'tarde') lightPass([1.0, .93, .84], [10, 2, -8], false);
    let x0 = W, y0 = H, x1 = -1, y1 = -1;
    for (let i = 0; i < W * H; i++) { if (zb[i] === groundZ[i]) continue; const x = i % W, y = Math.floor(i / W); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    const w = x1 - x0 + 1, h = y1 - y0 + 1, px = new Uint32Array(w * h), z = new Float32Array(w * h), d0 = project(3, 3, 0).d;
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) { const i = (y0 + y) * W + x0 + x, j = y * w + x; if (zb[i] === groundZ[i]) continue; px[j] = pix[i]; z[j] = zb[i] - d0; }
    const p = project(3, 3, 0);
    out.push({ kind, heading, board, light, box: [x0, y0, w, h], ax: Math.round(p.sx) - x0, ay: Math.round(p.sy) - y0, pix: hash(px), z: hash(z), n: px.filter(c => c).length });
  }
  return out;
};

const browser = await chromium.launch();
const page = await browser.newPage();
const problems = [];
page.on('pageerror', e => problems.push('pageerror: ' + e));
await page.setContent('<!doctype html><canvas id="c"></canvas>');
await page.addScriptTag({ content: 'window.PP_SCENE = { w: 240, h: 216, s: 26, originX: 0, originY: 0, shadowX: .9, shadowY: -.1 };' });
for (const f of ['pp-engine.js', 'mapa.js', 'set-kit.js', 'calle-base.js']) await page.addScriptTag({ content: fs.readFileSync(path.join(PIX, f), 'utf8') });
const rows = await page.evaluate(run, LOOKS);
await browser.close();
if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
const made = [
  '// Made by tool/make_calle_vehicles_ref.mjs from docs/proyecto/pixel/calle-base.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// La calle's vehicles baked by the JavaScript as calle_vehicles.dart bakes them: each look (kind, heading, board),",
  "/// plain and under La esquina's afternoon light: its box, its floor middle's place in it, the hashes of its pixels and",
  '/// depths (test/support/hash.dart), and how many pixels it has.',
  "const String calleVehiclesRefs = r'''" + JSON.stringify(rows, null, 1) + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'calle_vehicles_refs.dart: up to date' : 'calle_vehicles_refs.dart: STALE (run node tool/make_calle_vehicles_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' looks');
