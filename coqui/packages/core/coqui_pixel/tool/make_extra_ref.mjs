// Makes the reference for the engine's functions El frente's set and the island do not reach, from the OLD code.
//
//   node tool/make_extra_ref.mjs          (in this package) writes test/support/fixtures/extra_ref.dart
//   node tool/make_extra_ref.mjs --check  says whether that file is the one the old code gives now
//
// It loads docs/proyecto/pixel/pp-engine.js and mapa.js unchanged, in node's `vm` with a stub canvas, draws the scene
// below, and writes the buffers after three stages. test/pp_extra_test.dart repeats the same calls in Dart
// (test/support/extra_build.dart) and compares. Keep the two scenes the same.
//
// What it reaches that the island and El frente do not: growTree (and the capture mode of sphere), drawLeaves, box,
// figure (through person and through dynamicAdd), flushShadows with bones, flatRoof, windowOn lit and with its
// defaults, palm's own shadows, drawDots,
// haloDots, drawArrow (and its clipping).
//
// Node's Math.sin differs from Chrome's in the last digits (coqui/tool/ref/pp/README.md, Notes); the tests allow
// 0.5% of the pixels to differ, as for the island.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const oldDir = path.resolve(here, '../../../../../docs/proyecto/pixel');
const outFile = path.resolve(here, '../test/support/fixtures/extra_ref.dart');

// the scene's engine settings: PP_SCENE
const SCENE = { w: 160, h: 140, s: 14, originX: 0, originY: 10, shadowX: 0.9, shadowY: -0.1 };

const canvas = {
  width: 0,
  height: 0,
  getContext: () => ({
    createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }),
    putImageData() {},
  }),
};
const sandbox = {
  window: { PP_SCENE: SCENE },
  document: { getElementById: () => canvas },
  matchMedia: () => ({ matches: false }),
};
const context = vm.createContext(sandbox);
for (const f of ['pp-engine.js', 'mapa.js']) {
  vm.runInContext(fs.readFileSync(path.join(oldDir, f), 'utf8'), context, { filename: f });
}

// The scene. Global names are the old code's (the vm shares the scripts' top-level const and function names).
const driver = `
'use strict';
const out = { stages: {}, meta: {} };
const keep = (name, withKinds) => {
  out.stages[name] = { pix: pix.slice(), zb: zb.slice() };
  if (withKinds) out.stages[name].kinds = kinds.slice();
};
// grass ground, the way El frente's sceneGround makes it, with the grass kind
for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
  const g = unproject(ix + .5, iy + .5), i = iy * W + ix;
  const t = noise(g.x * .45, g.y * .45) * 1.1 + (hash(ix, iy) - .5) * .5;
  kinds[i] = KIND_GRASS;
  pix[i] = rgb(...GRASS[clamp(Math.floor(t * 4.2) + 1, 0, 4)]);
  ground[i] = 1;
  zb[i] = (g.x + g.y) / R2 * COS;
}
growGrass(); groundZ.set(zb);
growTree(-3, -2, .8, 120, 11);
growTree(-1, 5, .5, 80, 300);
box(1, -4, 0, 3.5, -2.5, 1.2, [200, 160, 110], 3);
box(-3, 1, 0, -2, 4, 2, [120, 150, 200]);
block(4, 0, 0, 6.5, 2.5, 2, C.yellow);
flatRoof(4, 0, 6.5, 2.5, 2, C.white);
windowOn('y', 2.5, 5.2, 1.0, .6, .7, C.white, C.glass, true);        // lit
windowOn('x', 6.5, 1.2, 1.0, .5, .7);                                // the default frame and glass
windowOn('x', 6.5, .4, 1.0, .3, .3, C.red, [140, 190, 220], true);
shadowBox(4, 0, 6.5, 2.5, 3, .6);
palm(-5, -4, 3.2, .7, 1);
const P1 = { shirt: [128, 78, 160], stripe: [150, 98, 178], legs: [128, 78, 160], hair: [232, 230, 224], skin: [176, 122, 88] };
const P2 = { shirt: [236, 236, 228], stripe: [60, 66, 90], legs: [60, 66, 90], hair: [40, 30, 26], skin: [200, 146, 104] };
person(0, 3, FACE, P1);
person(-3, 3, FACE + .4, P2, { crouch: .4, lean: .2, armR: .5, armL: -.3, stance: .4, z: .1, scale: .8 });
person(2, 4.5, 1.1, P1, { scale: 0, stance: 0, armL: 0 });   // scale 0 is false in JavaScript: the scale is 1
flushShadows(); pendingShadows.length = 0;
keep('objects', true);
bakeOcclusion(); staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges();
bakedPix.set(pix); bakedZ.set(zb);
keep('baked');
// one frame at time 1.25: the wind, a figure drawn per frame, the signs
pix.set(bakedPix); zb.set(bakedZ);
drawLeaves(1.25);
drawTufts(1.25);
const hand = figure(-1, 1.5, 2.2, { scale: 1.1, armR: .9 }, P2, dynamicAdd);
sphere(hand[0], hand[1], hand[2], .1, [250, 200, 60], 'gloss');
flushShadows(); pendingShadows.length = 0;
applyShadows(groundZ);
drawDots([[-3, 5], [2.7, 3.2], [159.9, 139.9], [160, 10], [10, 140], [0.5, 0.5]], rgb(255, 0, 0));
haloDots([[100, 100], [0, 0], [159, 70]]);
drawArrow(40, 60, .4);
drawArrow(3, 8, .7);
drawArrow(158, 138, 1.1);
drawArrow(80.5, 20.5, 0);
keep('frame');
out.meta = {
  W, H, S, OX, OY, tufts: tufts.length, leaves: leaves.length,
  leafList: leaves.map(l => ({ x: l.x, y: l.y, z: l.z, k: l.k, r: l.r, n: l.pixels.length })),
  hand: Array.from(hand),
};
out;
`;
const out = vm.runInContext(driver, context, { filename: 'driver' });

// ---- write the Dart fixture ----
const piece = 4000;
function b64(typed) {
  return Buffer.from(typed.buffer, typed.byteOffset, typed.byteLength).toString('base64');
}
const files = {};
for (const [stage, bufs] of Object.entries(out.stages)) {
  for (const [name, arr] of Object.entries(bufs)) files[`${stage}/${name}.bin`] = b64(arr);
}
files['meta.json'] = Buffer.from(JSON.stringify(out.meta)).toString('base64');
let text = '// Made by tool/make_extra_ref.mjs from the old pp-engine.js and mapa.js. Do not edit.\n';
text += '// ignore_for_file: lines_longer_than_80_chars\n\n';
text += '/// The reference for test/pp_extra_test.dart: each file as base64 in pieces (buffers little endian).\n';
text += 'const Map<String, List<String>> extraRefFixture = {\n';
for (const [name, data] of Object.entries(files)) {
  text += `  '${name}': [\n`;
  for (let i = 0; i < data.length; i += piece) text += `    '${data.slice(i, i + piece)}',\n`;
  text += '  ],\n';
}
text += '};\n';

if (process.argv.includes('--check')) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'the extra reference is current' : 'the extra reference is NOT current: run tool/make_extra_ref.mjs');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${text.length} characters; tufts ${out.meta.tufts}, leaves ${out.meta.leaves}`);
