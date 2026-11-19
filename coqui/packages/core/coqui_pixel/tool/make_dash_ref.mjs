// Makes the reference for Ctx.setLineDash from the browser: a few 64 x 64 tiles drawn by headless Chrome's canvas.
//
//   node tool/make_dash_ref.mjs          (in this package) writes test/support/fixtures/ref_dash.dart
//   node tool/make_dash_ref.mjs --check  says whether that file is the one Chrome gives now
//
// Each case is a list of canvas calls (below). Chrome runs them on a 64 x 64 canvas; test/ctx_dash_test.dart replays
// the same calls on Ctx (test/support/dash_replay.dart) and compares. The first case is the call patio.js makes
// (line 142: the loop the bird has just flown). Needs Node 22 and the pre-installed Node Playwright. Nothing in the
// drawing depends on the time or on chance, so a second run gives the same file.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const outFile = path.resolve(here, '../test/support/fixtures/ref_dash.dart');

const BG = '#2E6CD0';
const stroke = (colour, width, dash, ...path) => [
  ['strokeStyle', colour], ['lineWidth', width], ['setLineDash', dash], ['beginPath'], ...path, ['stroke'],
];
const CASES = [
  { title: "patio.js line 142: a white loop, line width 1, dash [2, 3], arc(x, y, 12, 0, 7), then setLineDash([])",
    ops: [...stroke('#FFFFFF', 1, [2, 3], ['arc', 32, 32, 12, 0, 7]), ['setLineDash', []]] },
  { title: 'the same loop at a smaller radius and a centre off the grid', ops: stroke('#FFFFFF', 1, [2, 3], ['arc', 30.5, 33.25, 9, 0, 7]) },
  { title: 'a straight line, width 2, dash [4, 2]', ops: stroke('#FFE040', 2, [4, 2], ['moveTo', 4, 20.5], ['lineTo', 60, 20.5]) },
  { title: 'a diagonal line, width 1, dash [3, 3]', ops: stroke('#FFFFFF', 1, [3, 3], ['moveTo', 4, 4], ['lineTo', 58, 50]) },
  { title: 'an odd list [3] is [3, 3]; width 2', ops: stroke('#FFFFFF', 2, [3], ['moveTo', 4, 12.5], ['lineTo', 60, 12.5]) },
  { title: 'an odd list [2, 3, 1] is [2, 3, 1, 2, 3, 1]; width 1', ops: stroke('#FFFFFF', 1, [2, 3, 1], ['moveTo', 4, 30.5], ['lineTo', 60, 30.5]) },
  { title: 'a rectangle (a closed sub-path), width 1, dash [5, 3]', ops: stroke('#FFFFFF', 1, [5, 3], ['rect', 8.5, 10.5, 40, 30]) },
  { title: 'a path with two corners, width 2, dash [6, 3]', ops: stroke('#FFE040', 2, [6, 3], ['moveTo', 6, 50], ['lineTo', 30, 50], ['lineTo', 30, 12], ['lineTo', 56, 12]) },
  { title: 'a negative length is ignored: [2, 3] stays', ops: [['setLineDash', [2, 3]], ['setLineDash', [-1, 2]], ...stroke('#FFFFFF', 1, null, ['moveTo', 4, 20.5], ['lineTo', 60, 20.5])] },
  { title: 'an empty list is a solid line', ops: [['setLineDash', [2, 3]], ...stroke('#FFFFFF', 1, [], ['moveTo', 4, 20.5], ['lineTo', 60, 20.5])] },
  { title: 'save and restore keep the dash list: [2, 2] inside, solid after', ops: [
    ['save'], ['setLineDash', [2, 2]], ['restore'], ...stroke('#FFFFFF', 1, null, ['moveTo', 4, 20.5], ['lineTo', 60, 20.5])] },
  { title: 'a dash list is kept by save: [4, 4] set before save and used after restore', ops: [
    ['setLineDash', [4, 4]], ['save'], ['setLineDash', [1, 1]], ['restore'], ...stroke('#FFFFFF', 1, null, ['moveTo', 4, 20.5], ['lineTo', 60, 20.5])] },
];

const page_fn = `(cases) => {
  const hex = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
  return cases.map(c => {
    const cv = document.createElement('canvas'); cv.width = 64; cv.height = 64;
    const g = cv.getContext('2d', { willReadFrequently: true, colorSpace: 'srgb' });
    g.fillStyle = '${BG}'; g.fillRect(0, 0, 64, 64);
    for (const op of c.ops) {
      const [name, ...a] = op;
      if (name === 'strokeStyle' || name === 'fillStyle') g[name] = a[0];
      else if (name === 'lineWidth') g.lineWidth = a[0];
      else if (name === 'setLineDash') { if (a[0] !== null) g.setLineDash(a[0]); }
      else g[name](...a);
    }
    const d = g.getImageData(0, 0, 64, 64).data;
    let s = ''; for (let i = 0; i < d.length; i += 0x8000) s += String.fromCharCode.apply(null, d.subarray(i, i + 0x8000));
    return btoa(s);
  });
}`;

const browser = await chromium.launch();
const page = await (await browser.newContext({ deviceScaleFactor: 1 })).newPage();
const tiles = await page.evaluate(`(${page_fn})(${JSON.stringify(CASES)})`);
const again = await page.evaluate(`(${page_fn})(${JSON.stringify(CASES)})`);
await browser.close();
if (JSON.stringify(tiles) !== JSON.stringify(again)) throw new Error('Chrome drew a case two ways');

const piece = 4000;
const files = { 'cases.json': Buffer.from(JSON.stringify({ background: BG, cases: CASES })).toString('base64') };
tiles.forEach((t, i) => { files[`tiles/${String(i + 1).padStart(2, '0')}.bin`] = t; });
let text = '// Made by tool/make_dash_ref.mjs from headless Chrome\'s canvas. Do not edit.\n';
text += '// ignore_for_file: lines_longer_than_80_chars\n\n';
text += '/// The reference for test/ctx_dash_test.dart: each file as base64 in pieces. Tiles are 64 x 64 RGBA, straight alpha.\n';
text += 'const Map<String, List<String>> refDashFixture = {\n';
for (const [name, data] of Object.entries(files)) {
  text += `  '${name}': [\n`;
  for (let i = 0; i < data.length; i += piece) text += `    '${data.slice(i, i + piece)}',\n`;
  text += '  ],\n';
}
text += '};\n';

if (process.argv.includes('--check')) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'the dash reference is current' : 'the dash reference is NOT current: run tool/make_dash_ref.mjs');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${text.length} characters, ${CASES.length} cases`);
