#!/usr/bin/env node
'use strict';
/* Reference data for the software canvas (order 05, part A): 40 numbered cases drawn with the browser's 2D canvas.
   Run from the repo root:  node coqui/tool/ref/ctx/make.js
   Writes coqui/ref/ctx/:  cases.json, tiles/NN.bin (64 x 64 RGBA each), sources/<id>.bin, sheet.png, index.json */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { chromium } = require('playwright');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const OUT = path.join(REPO, 'coqui/ref/ctx');
const T = 64;

// Math.random pinned (Mulberry32, seed 1) and counted; the sprites and helpers used here do not call it
const PIN = `(() => { let s = 1; window.__randomCalls = 0; Math.random = () => { window.__randomCalls++; s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; })();`;

async function render(browser) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, reducedMotion: 'no-preference', colorScheme: 'light', locale: 'en-US', timezoneId: 'UTC' });
  const page = await ctx.newPage();
  const problems = [];
  page.on('pageerror', e => problems.push('pageerror: ' + e));
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push('console ' + m.type() + ': ' + m.text()); });
  await page.addInitScript(PIN);
  await page.goto('file://' + path.join(__dirname, 'sheet.html'));
  const result = await page.evaluate(() => window.RESULT);
  const randomCalls = await page.evaluate(() => window.__randomCalls);
  await ctx.close();
  if (problems.length) throw new Error(problems.join('; '));
  assert.strictEqual(randomCalls, 0, 'Math.random was called');
  return result;
}

// the line of the old file that a case's parameters come from, found by its text so that the number cannot go stale
const lines = {};
function ref([file, find, note]) {
  const ls = lines[file] || (lines[file] = fs.readFileSync(path.join(REPO, file), 'utf8').split('\n'));
  const i = ls.findIndex(l => l.includes(find));
  assert(i >= 0, file + ' has no line with ' + find);
  return { file, line: i + 1, text: ls[i].trim().slice(0, 100), note };
}

// ---- the contact sheet: 8 x 5 tiles, case numbers above, drawn over a checkerboard so that transparent pixels show; 3x ----
const DIGITS = { 0: '111101101101111', 1: '010110010010111', 2: '111001111100111', 3: '111001111001111', 4: '101101111001001', 5: '111100111001111', 6: '111100111101111', 7: '111001010010010', 8: '111101111101111', 9: '111101111001111' };
function sheet(tiles) {
  const COLS = 8, ROWS = 5, G = 4, LAB = 8, Z = 3;
  const cw = T + G, ch = T + LAB + G, W = COLS * cw + G, H = ROWS * ch + G;
  const px = Buffer.alloc(W * H * 4);
  const put = (x, y, r, g, b) => { const i = (y * W + x) * 4; px[i] = r; px[i + 1] = g; px[i + 2] = b; px[i + 3] = 255; };
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) put(x, y, 70, 74, 84);
  tiles.forEach((rgba, k) => {
    const ox = G + (k % COLS) * cw, oy = G + Math.floor(k / COLS) * ch + LAB;
    for (let y = 0; y < T; y++) for (let x = 0; x < T; x++) {
      const i = (y * T + x) * 4, a = rgba[i + 3] / 255, c = ((x >> 3) + (y >> 3)) % 2 ? 214 : 255;
      put(ox + x, oy + y, Math.round(rgba[i] * a + c * (1 - a)), Math.round(rgba[i + 1] * a + c * (1 - a)), Math.round(rgba[i + 2] * a + c * (1 - a)));
    }
    [...String(k + 1)].forEach((d, j) => { for (let r = 0; r < 5; r++) for (let q = 0; q < 3; q++) if (DIGITS[d][r * 3 + q] === '1') put(ox + j * 4 + q, oy - LAB + 1 + r, 255, 255, 255); });
  });
  const big = Buffer.alloc(W * Z * H * Z * 4);
  for (let y = 0; y < H * Z; y++) for (let x = 0; x < W * Z; x++) px.copy(big, (y * W * Z + x) * 4, ((y / Z | 0) * W + (x / Z | 0)) * 4, ((y / Z | 0) * W + (x / Z | 0)) * 4 + 4);
  return L.png(W * Z, H * Z, big);
}

const opLine = op => '        ' + JSON.stringify(op);
async function main() {
  const browser = await chromium.launch();
  let a, b;
  try { a = await render(browser); b = await render(browser); } finally { await browser.close(); }
  assert.deepStrictEqual(a, b, 'two renders differ');   // tiles, sources, ops: all of it

  fs.rmSync(OUT, { recursive: true, force: true });
  const tiles = [];
  for (const s of Object.values(a.sources)) assert.strictEqual(Buffer.from(s.rgba, 'base64').length, s.w * s.h * 4);
  const srcOut = {};
  for (const [id, s] of Object.entries(a.sources)) {
    const bin = Buffer.from(s.rgba, 'base64');
    L.write(path.join(OUT, 'sources', id + '.bin'), bin);
    srcOut[id] = { call: s.call, w: s.w, h: s.h, file: 'sources/' + id + '.bin', sha256: L.sha256(bin) };
  }
  const caseTxt = a.cases.map(c => {
    const rgba = Buffer.from(c.rgba, 'base64');
    assert.strictEqual(rgba.length, T * T * 4);
    tiles.push(rgba);
    const nn = String(c.n).padStart(2, '0');
    L.write(path.join(OUT, 'tiles', nn + '.bin'), rgba);
    return [
      '    {',
      '      "n": ' + c.n + ',',
      '      "kind": ' + JSON.stringify(c.kind) + ',',
      '      "title": ' + JSON.stringify(c.title) + ',',
      '      "file": ' + JSON.stringify('tiles/' + nn + '.bin') + ',',
      '      "sha256": ' + JSON.stringify(L.sha256(rgba)) + ',',
      '      "refs": ' + JSON.stringify(c.refs.map(ref)) + ',',
      '      "ops": [', c.ops.map(opLine).join(',\n'), '      ]',
      '    }',
    ].join('\n');
  });
  const head = {
    what: 'Canvas reference for the software canvas (Ctx, page 12 section 4): 40 numbered cases drawn with the browser 2D canvas into 64 x 64 tiles.',
    browser: a.browser,
    canvas: { width: T, height: T, contextAttributes: { willReadFrequently: true, colorSpace: 'srgb', alpha: true }, start: 'every tile starts transparent black (0, 0, 0, 0)', defaultsBeforeTheFirstOp: { fillStyle: '#000000', strokeStyle: '#000000', globalAlpha: 1, lineWidth: 1 }, browserDefaultOfImageSmoothingEnabled: a.smoothingDefault },
    tileFormat: 'tiles/NN.bin: 64 * 64 * 4 bytes, RGBA, straight (not premultiplied) alpha as getImageData returns it, row-major, NN = the case number with two digits',
    sheet: 'sheet.png: the 40 tiles, 8 across and 5 down, case numbers above each tile, over a grey checkerboard where transparent, enlarged 3 times. For looking only.',
    replay: {
      about: 'Replay a case on a new Ctx of 64 x 64: run its ops in order. Each op is an array: the name, then the arguments.',
      setters: 'fillStyle and strokeStyle: [name, css, [r, g, b, a8]]: use the resolved bytes (a8 = round(alpha * 255)). globalAlpha, lineWidth: [name, number]. imageSmoothingEnabled: [name, bool] is Ctx.smoothing. Every case begins with imageSmoothingEnabled.',
      calls: 'save, restore, translate(x, y), scale(x, y), rotate(a), fillRect(x, y, w, h), clearRect(x, y, w, h), beginPath, rect(x, y, w, h), arc(x, y, r, a0, a1), ellipse(x, y, rx, ry, rot, a0, a1), moveTo(x, y), lineTo(x, y), fill, stroke, clip.',
      drawImage: '["drawImage", source, dx, dy] and ["drawImage", source, dx, dy, dw, dh] are Ctx.drawImage; ["drawImageRect", source, sx, sy, sw, sh, dx, dy, dw, dh] is Ctx.drawImageRect (the browser\'s nine-argument drawImage). `source` is a key of "sources": a Sprite of that width and height from the RGBA bytes in its file.',
      angles: 'arc and ellipse go clockwise from a0 to a1 in canvas coordinates (y down). A sweep of 2 pi or more (the old code writes 7) is a full circle. arc(x, y, r, Math.PI, 0) is the upper half. There is no anticlockwise argument.',
      clip: 'clip() intersects the clip with the current path under the current transform; save and restore bring the earlier clip back.',
    },
    sources: srcOut,
  };
  const headTxt = JSON.stringify(head, null, 2).replace(/^\{\n/, '').replace(/\n\}$/, '');
  L.write(path.join(OUT, 'cases.json'), '{\n' + headTxt + ',\n  "cases": [\n' + caseTxt.join(',\n') + '\n  ]\n}\n');
  JSON.parse(fs.readFileSync(path.join(OUT, 'cases.json'), 'utf8'));
  L.write(path.join(OUT, 'sheet.png'), sheet(tiles));
  const md = ['# Canvas cases', '', 'Made by `coqui/tool/ref/ctx/make.js`. Each case is a 64 x 64 tile; `cases.json` has its calls. `Source` is where in `historia/` its parameters come from.', '',
    '| # | Kind | What | Source |', '| --- | --- | --- | --- |'];
  a.cases.forEach(c => md.push('| ' + c.n + ' | ' + c.kind + ' | ' + c.title.replace(/\|/g, '/') + ' | ' + (c.refs.length ? c.refs.map(ref).map(r => r.file.replace('historia/', '') + ':' + r.line).join(', ') : 'synthetic (the order\'s list)') + ' |'));
  L.write(path.join(OUT, 'cases.md'), md.join('\n') + '\n');
  const r = L.writeIndex(OUT, 'canvas reference: 40 cases, their source sprites and the contact sheet');
  const kinds = a.cases.reduce((m, c) => (m[c.kind] = (m[c.kind] || 0) + 1, m), {});
  console.log('cases ' + a.cases.length + ' ' + JSON.stringify(kinds));
  console.log('index ' + r.files + ' files, ' + r.totalBytes + ' bytes');
}
main().catch(e => { console.error(e); process.exit(1); });
