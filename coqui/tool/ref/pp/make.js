#!/usr/bin/env node
'use strict';
/* Reference data for the engine (order 05, part A): renders of docs/proyecto/pixel/ in headless Chrome.
   Run from the repo root:  node coqui/tool/ref/pp/make.js
   Options:  --states <file>   the list of page states to dump (default: states.json beside this script)
             --only <id,id>    make only these ids (a state id, "island" or "unit"); the index is rebuilt from the folder
             --out <dir>       where to write (default: coqui/ref/pp)
             --index-only      skip rendering; rebuild per-folder <folder>/index.json and assemble top-level index.json
   Order 07 adds the states of El frente's set by adding lines to states.json. */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const TOP_WHAT = 'engine reference: renders of docs/proyecto/pixel/ in headless Chrome, the island, and unit values';
const arg = (name, def) => { const i = process.argv.indexOf(name); return i < 0 ? def : process.argv[i + 1]; };
const hasFlag = name => process.argv.includes(name);
const OUT = path.resolve(arg('--out', path.join(REPO, 'coqui/ref/pp')));
const STATES = JSON.parse(fs.readFileSync(path.resolve(arg('--states', path.join(__dirname, 'states.json'))), 'utf8'));
const ONLY = arg('--only', null) && arg('--only').split(',');
const INDEX_ONLY = hasFlag('--index-only');
const want = id => !ONLY || ONLY.includes(id);

// The clock and the dice the pages see. The old page files are not edited: this runs before them.
//  - requestAnimationFrame only queues; __flush() runs the queue once, at time 0, so the first frame is time 0
//  - performance.now() is 0 and Date.now() is a fixed instant, so a frame's dt is 0
//  - Math.random is Mulberry32 seed 1 and counts its calls (the pixel files use none: the count is saved in state.json)
const CLOCK = `(() => {
  const q = [];
  window.requestAnimationFrame = cb => { q.push(cb); return q.length; };
  window.cancelAnimationFrame = () => {};
  window.__flush = () => { const c = q.splice(0); c.forEach(f => f(0)); return c.length; };
  performance.now = () => 0;
  const T0 = 1700000000000, RD = Date;
  class FixedDate extends RD { constructor(...a) { if (a.length === 0) super(T0); else super(...a); } static now() { return T0; } }
  window.Date = FixedDate;
  let s = 1; window.__randomCalls = 0;
  Math.random = () => { window.__randomCalls++; s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
})();`;

// read back from the page: the three buffers (base64 of the raw bytes) and the engine's settings
const GRAB = () => {
  const b64 = a => { const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength); let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
  return {
    littleEndian: new Uint8Array(new Uint32Array([1]).buffer)[0] === 1,
    pix: b64(pix), zb: b64(zb), kinds: b64(kinds),
    engine: { W, H, S, originX: SCENE.originX || 0, originY: SCENE.originY || 0, OX, OY, SHADOW_X, SHADOW_Y, STILL, SIN, COS, R2, WIND_FPS, GRADIENT_Y, EDGE, PP_SCENE: SCENE },
    counts: { tufts: tufts.length, leaves: leaves.length, waterPix: waterPix.length / 4 },
    randomCalls: window.__randomCalls,
  };
};
const MAP_STATE = () => ({
  places: CURSO.lugares.map(l => l.id),
  hecho: hecho.slice(), abierto: abierto.slice(), aqui: MAPA.STATE.aqui,
  N, time, frog: Object.assign({}, MAPA.FROG, { onArrive: null }),
});
const SET_STATE = () => ({ spots: typeof SPOTS !== 'undefined' ? SPOTS : null, screen: typeof SCREEN !== 'undefined' ? SCREEN : null });

async function newPage(browser) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, reducedMotion: 'no-preference', colorScheme: 'light', locale: 'en-US', timezoneId: 'UTC' });
  const page = await ctx.newPage();
  const problems = [];
  page.on('pageerror', e => problems.push('pageerror: ' + e));
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push('console ' + m.type() + ': ' + m.text()); });
  await page.addInitScript(CLOCK);
  return { ctx, page, problems };
}

async function renderState(browser, job) {
  const { ctx, page, problems } = await newPage(browser);
  try {
    await page.goto('file://' + path.join(REPO, job.page) + job.query);
    await page.evaluate(() => window.__flush());
    const got = await page.evaluate(GRAB);
    const extra = job.kind === 'mapa' ? await page.evaluate(MAP_STATE) : job.kind === 'set' ? await page.evaluate(SET_STATE) : {};
    if (problems.length) throw new Error(job.id + ': ' + problems.join('; '));
    return { got, extra };
  } finally { await ctx.close(); }
}

function writeBuffer(dir, name, bytes, w, h, type, note) {
  L.write(path.join(dir, name + '.bin'), bytes);
  L.write(path.join(dir, name + '.json'), L.json({ file: name + '.bin', width: w, height: h, type, endian: 'little', layout: 'row-major, index = y * width + x', note, bytes: bytes.length, sha256: L.sha256(bytes) }));
}
function dumpBuffers(dir, got) {
  const { W, H } = got.engine, pix = Buffer.from(got.pix, 'base64'), zb = Buffer.from(got.zb, 'base64'), kinds = Buffer.from(got.kinds, 'base64');
  assert(got.littleEndian, 'this machine is not little-endian');
  assert.strictEqual(pix.length, W * H * 4); assert.strictEqual(zb.length, W * H * 4); assert.strictEqual(kinds.length, W * H);
  writeBuffer(dir, 'pix', pix, W, H, 'uint32', 'pixels 0xAABBGGRR; the four bytes of one pixel are R, G, B, A in memory order; alpha 0 where nothing was drawn');
  writeBuffer(dir, 'zb', zb, W, H, 'float32', 'the depth buffer after the frame; -1e9 where nothing was drawn');
  writeBuffer(dir, 'kinds', kinds, W, H, 'uint8', 'KIND_NONE 0, SAND 1, WATER 2, GRASS 3, ROAD 4');
  L.write(path.join(dir, 'pix.png'), L.png(W, H, pix));
}
let BROWSER = '';
const hashes = got => [got.pix, got.zb, got.kinds].map(b => L.sha256(Buffer.from(b, 'base64'))).join(' ');

async function doState(browser, job) {
  const dir = path.join(OUT, job.id);
  const a = await renderState(browser, job), b = await renderState(browser, job);   // twice, in two pages: the clock pin must give the same bytes
  assert.strictEqual(hashes(a.got), hashes(b.got), job.id + ': two renders in one run differ');
  assert.strictEqual(a.got.randomCalls, 0, job.id + ': the page called Math.random');
  fs.rmSync(dir, { recursive: true, force: true });
  dumpBuffers(dir, a.got);
  L.write(path.join(dir, 'state.json'), L.json(Object.assign({
    id: job.id, kind: job.kind, source: job.page + job.query, browser: BROWSER,
    clock: 'requestAnimationFrame queued and run once with timestamp 0; performance.now() = 0; Date.now() = 1700000000000; so the frame is time 0',
    mathRandomCalls: a.got.randomCalls,
    engine: a.got.engine, counts: a.got.counts,
  }, a.extra)));
  console.log('state  ' + job.id + '  ' + a.got.engine.W + 'x' + a.got.engine.H);
}

async function doIsland(browser) {
  const url = 'file://' + path.join(__dirname, 'island.html');
  const one = async logged => {
    const { ctx, page, problems } = await newPage(browser);
    try {
      await page.goto(url);
      const log = await page.evaluate(logged ? () => buildIslandLogged() : () => { buildIsland(); return null; });
      const got = await page.evaluate(GRAB);
      if (problems.length) throw new Error('island: ' + problems.join('; '));
      return { got, log };
    } finally { await ctx.close(); }
  };
  const a = await one(false), b = await one(false), c = await one(true);
  assert.strictEqual(hashes(a.got), hashes(b.got), 'island: two renders differ');
  assert.strictEqual(hashes(a.got), hashes(c.got), 'island: the logging build differs from the plain build');
  assert.strictEqual(a.got.randomCalls, 0);
  const dir = path.join(OUT, 'island');
  fs.rmSync(dir, { recursive: true, force: true });
  dumpBuffers(dir, a.got);
  const steps = [
    'zb.fill(-1e9); pix.fill(0); kinds.fill(0); waterPix.length = 0;   // the first four statements of bake()',
    'for iy in 0..H-1, ix in 0..W-1:  g = unproject(ix + .5, iy + .5); i = iy*W + ix; c = groundColor(g.x, g.y, ix, iy, i);  if c == 0 continue;  pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS',
    'slabSides()', 'growGrass()', 'groundZ.set(zb)', 'decorate()',
  ];
  L.write(path.join(dir, 'state.json'), L.json({
    id: 'island', kind: 'island', browser: BROWSER, source: 'coqui/tool/ref/pp/island.html (loads docs/proyecto/pixel/pp-engine.js and mapa.js)',
    note: 'The map island with no places. Same engine settings as mapa.html. Nothing after decorate(): no flushShadows, bakeOcclusion, applyShadows or shadeEdges, no places, no frog, no flags, no plates.',
    steps, engine: a.got.engine, counts: a.got.counts, decorateCalls: c.log.length, mathRandomCalls: a.got.randomCalls,
  }));
  L.write(path.join(dir, 'decorate-calls.json'), '[\n' + c.log.map(e => '  ' + JSON.stringify(e)).join(',\n') + '\n]\n');
  const tally = c.log.reduce((m, e) => (m[e.fn] = (m[e.fn] || 0) + 1, m), {});
  const fmt = v => (Array.isArray(v) ? '[' + v.map(fmt).join(', ') + ']' : typeof v === 'string' ? "'" + v + "'" : String(v));
  L.write(path.join(dir, 'calls.md'), [
    '# The island with no places: the calls that made it',
    '',
    'Made by `coqui/tool/ref/pp/make.js` from `island.html`, which loads `docs/proyecto/pixel/pp-engine.js` and `mapa.js` unchanged.',
    'Engine settings: `PP_SCENE = { w: 256, h: 480, s: 8, originY: 36, shadowX: .9, shadowY: -.1 }` (the ones in mapa.html).',
    'Buffers: `pix`, `zb`, `kinds`, as they are after the last call below, and nothing else is called. The same as `bake()` in mapa.js (lines 411 to 430)',
    'with the place passes removed: no place is built, so `patches` stays empty, and the ground loop sees no patch.',
    '',
    '## The calls, in order',
    '',
    '1. `zb.fill(-1e9)`, `pix.fill(0)`, `kinds.fill(0)`, `waterPix.length = 0` (the first statements of `bake()`).',
    '2. The ground loop of `bake()`, unchanged, row by row (`iy` 0 to 479, `ix` 0 to 255):',
    '   ```js',
    '   const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = groundColor(g.x, g.y, ix, iy, i);',
    '   if (!c) continue;',
    '   pix[i] = c; ground[i] = 1;',
    '   zb[i] = (g.x + g.y) / R2 * COS;',
    '   ```',
    '   `groundColor` is mapa.js\'s own (island shape `islandSd`, sea band, sand, then grass; it sets `kinds[i]` and fills `waterPix`). `zb` holds a float32 per pixel.',
    '3. `slabSides()` (mapa.js line 456).',
    '4. `growGrass()` (pp-engine.js).',
    '5. `groundZ.set(zb)`.',
    '6. `decorate()` (mapa.js line 396). Nothing is called after it.',
    '',
    '## What `decorate()` asks the engine to draw',
    '',
    'The calls to `palm`, `bush` and `sphere` that `decorate()` itself makes, in order (calls those functions make inside themselves are not listed).',
    'Totals: ' + Object.entries(tally).map(([k, v]) => v + ' `' + k + '`').join(', ') + '. The same list, as data, is in `decorate-calls.json`.',
    '',
    '| # | call |',
    '| --- | --- |',
    ...c.log.map((e, i) => '| ' + (i + 1) + ' | `' + e.fn + '(' + e.args.map(fmt).join(', ') + ')` |'),
    '',
    '`bush(x, y, r, c)` and `sphere(x, y, z, r, c, mode)` take the colour as an [r, g, b] array; the mode of every `sphere` here is `\'solid\'`.',
    '',
  ].join('\n'));
  console.log('island  ' + c.log.length + ' decorate calls ' + JSON.stringify(tally));
}

// ---- unit values ----
const UNITS = [
  { file: 'unit/unit.json', q: 'w=256&h=480&s=8&oy=36&shx=.9&shy=-.1', what: 'the map settings (mapa.html)', only: null },
  { file: 'unit/unit-s26.json', q: 'w=240&h=216&s=26&ox=-30&oy=40&shx=.9&shy=-.1', what: 'the scene settings of El frente (S = 26, originX -30, originY 40)', only: ['project', 'unproject'] },
];
function unitText(d, keys) {
  const row = o => '    ' + JSON.stringify(o);
  const parts = ['  "settings": ' + JSON.stringify(d.settings)];
  for (const k of keys) parts.push('  "' + k + '": [\n' + d[k].map(row).join(',\n') + '\n  ]');
  return '{\n' + parts.join(',\n') + '\n}\n';
}
async function doUnit(browser) {
  for (const u of UNITS) {
    const { ctx, page, problems } = await newPage(browser);
    try {
      await page.goto('file://' + path.join(__dirname, 'unit.html') + '?' + u.q);
      const d = await page.evaluate(() => window.UNIT);
      if (problems.length) throw new Error('unit: ' + problems.join('; '));
      d.settings.browser = BROWSER;
      const keys = u.only || ['hash', 'noise', 'project', 'unproject', 'rampOf'];
      keys.forEach(k => assert.strictEqual(d[k].length, 200));
      const text = unitText(d, keys);
      const back = JSON.parse(text);   // the numbers must come back exactly (SameValue, so -0 would fail too)
      for (const k of keys) assert.deepStrictEqual(back[k], d[k], u.file + ' ' + k + ' does not round-trip');
      assert.deepStrictEqual(back.settings, d.settings);
      L.write(path.join(OUT, u.file), text);
      console.log('unit   ' + u.file + '  ' + keys.map(k => k + ' ' + d[k].length).join(', '));
    } finally { await ctx.close(); }
  }
}

function listSubdirs(root) {
  return fs.readdirSync(root, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name)
    .sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

function assembleIndex(root) {
  const entries = [];
  let totalBytes = 0;
  for (const folder of listSubdirs(root)) {
    const idx = JSON.parse(fs.readFileSync(path.join(root, folder, 'index.json'), 'utf8'));
    for (const e of idx.entries) {
      entries.push({ path: folder + '/' + e.path, bytes: e.bytes, sha256: e.sha256 });
      totalBytes += e.bytes;
    }
  }
  entries.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
  L.write(path.join(root, 'index.json'), L.json({ what: TOP_WHAT, files: entries.length, totalBytes, entries }));
  return { files: entries.length, totalBytes };
}

(async () => {
  const touchedFolders = new Set();
  if (!INDEX_ONLY) {
    const { chromium } = require('playwright');
    const browser = await chromium.launch();
    BROWSER = 'Chromium ' + browser.version();
    try {
      if (want('island')) { await doIsland(browser); touchedFolders.add('island'); }
      for (const job of STATES) if (want(job.id)) { await doState(browser, job); touchedFolders.add(job.id.split('/')[0]); }
      if (want('unit')) { await doUnit(browser); touchedFolders.add('unit'); }
    } finally { await browser.close(); }
  }
  for (const folder of listSubdirs(OUT)) {
    if (INDEX_ONLY || !ONLY || touchedFolders.has(folder) || !fs.existsSync(path.join(OUT, folder, 'index.json'))) {
      L.writeIndex(path.join(OUT, folder), 'engine reference: ' + folder);
    }
  }
  const r = assembleIndex(OUT);
  console.log('index  ' + r.files + ' files, ' + r.totalBytes + ' bytes');
})().catch(e => { console.error(e); process.exit(1); });
