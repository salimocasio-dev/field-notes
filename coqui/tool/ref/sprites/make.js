#!/usr/bin/env node
'use strict';
/* Reference data for the sprites of historia/engine.js and historia/escenas/kit.js (order 05, part A).
   Run from the repo root:  node coqui/tool/ref/sprites/make.js
   Writes coqui/ref/sprites/: engine/<function>.bin + engine/sprites.json, kit/<function>.bin + kit/sprites.json,
   sheet-engine.png, sheet-kit.png, index.json. Sprites that a scene file makes for itself are not here (order 05, part B). */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { chromium } = require('playwright');
const L = require('./lib.js');

const REPO = path.resolve(__dirname, '../../../..');
const OUT = path.join(REPO, 'coqui/ref/sprites');

// Math.random pinned (Mulberry32, seed 1) and counted. No function of engine.js or kit.js calls it; make.js fails if one does.
const PIN = `(() => { let s = 1; window.__randomCalls = 0; Math.random = () => { window.__randomCalls++; s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; })();`;

// ---- what the code base calls: the sizes of every tarjeta written as numbers, and how often each function is called ----
const APP_FILES = [...fs.readdirSync(path.join(REPO, 'historia')).filter(f => /\.(js|html)$/.test(f)).map(f => 'historia/' + f),
  ...fs.readdirSync(path.join(REPO, 'historia/escenas')).filter(f => f.endsWith('.js')).map(f => 'historia/escenas/' + f)].sort();
const SRC = Object.fromEntries(APP_FILES.map(f => [f, fs.readFileSync(path.join(REPO, f), 'utf8').split('\n')]));
function tarjetaSizes() {
  const set = new Map();
  const re = /(?<![\w$])tarjeta\(\s*\w+\s*,\s*[^,()]+,\s*[^,()]+,\s*(\d+)\s*,\s*(\d+)\s*\)/g;
  for (const f of APP_FILES) for (const line of SRC[f]) for (const m of line.matchAll(re)) set.set(m[1] + 'x' + m[2], [+m[1], +m[2]]);
  return [...set.values()].sort((a, b) => a[0] - b[0] || a[1] - b[1]);
}
// where fn is used in historia/: a call fn( (or KIT.fn( ), and for the mk* makers also a reference such as spr("tree", mkTree); not the definition itself
function usage(fn) {
  const re = new RegExp('(?<![\\w$])(?:KIT\\.)?' + fn + (fn.startsWith('mk') ? '(?![\\w$])' : '\\('), 'g'), sites = [];
  for (const f of APP_FILES) SRC[f].forEach((line, i) => {
    const l = line.replace(new RegExp('function\\s+' + fn + '\\('), '');
    if (re.test(l)) sites.push(f.replace('historia/', '') + ':' + (i + 1));
    re.lastIndex = 0;
  });
  return sites;
}

async function render(browser, tarjetas) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, reducedMotion: 'no-preference', colorScheme: 'light', locale: 'en-US', timezoneId: 'UTC' });
  const page = await ctx.newPage();
  const problems = [];
  page.on('pageerror', e => problems.push('pageerror: ' + e));
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push('console ' + m.type() + ': ' + m.text()); });
  await page.addInitScript(PIN);
  await page.goto('file://' + path.join(__dirname, 'sprites.html'));
  const plan = await page.evaluate(t => window.build(t), tarjetas);
  const byKey = {};
  for (const [key] of plan) byKey[key] = await page.evaluate(k => window.RUN(k), key);
  const fam = await page.evaluate(() => window.FAM_JSON());
  const randomCalls = await page.evaluate(() => window.__randomCalls);
  await ctx.close();
  if (problems.length) throw new Error(problems.join('; '));
  assert.strictEqual(randomCalls, 0, 'Math.random was called by a sprite function');
  return { plan, byKey, fam };
}

// the call as it would be written, for a person to read
function callText(group, e) {
  const a = e.args, q = JSON.stringify, pre = group === 'kit' ? 'KIT.' : '';
  if (e.fn === 'mkPersona') {
    const w = a[0], who = 'KIT.FAM.' + w.fam;
    return 'KIT.mkPersona(' + (w.assign ? 'Object.assign({}, ' + who + ', ' + q(w.assign) + ')' : who) + ', ' + a.slice(1).map(q).join(', ') + ')';
  }
  if (e.target) return e.fn + (group === 'kit' ? '' : '') + '(' + (e.target.kind === 'Buf' ? 'b' : 'c') + (a.length ? ', ' : '') + a.map(q).join(', ') + ')  on a transparent ' + (e.target.kind === 'Buf' ? 'Buf(' + e.target.w + ', ' + e.target.h + ')' : 'canvas ' + e.target.w + ' x ' + e.target.h);
  return pre + e.fn + '(' + a.map(q).join(', ') + ')';
}

// ---- the sheet: every sprite of a group, 1:1, in index order, grey ground, a gap between functions ----
function sheet(items) {
  const WIDTH = 1500, PAD = 4;
  const place = [];
  let x = PAD, y = PAD, rowH = 0, lastFn = null;
  for (const it of items) {
    if (lastFn !== null && it.fn !== lastFn) { x = PAD; y += rowH + PAD * 3; rowH = 0; }
    if (x + it.w + PAD > WIDTH) { x = PAD; y += rowH + PAD; rowH = 0; }
    place.push([x, y]); x += it.w + PAD; rowH = Math.max(rowH, it.h); lastFn = it.fn;
  }
  const H = y + rowH + PAD;
  const px = Buffer.alloc(WIDTH * H * 4);
  for (let i = 0; i < WIDTH * H; i++) { px[i * 4] = 128; px[i * 4 + 1] = 136; px[i * 4 + 2] = 148; px[i * 4 + 3] = 255; }
  items.forEach((it, k) => {
    const [ox, oy] = place[k];
    for (let j = 0; j < it.h; j++) for (let i = 0; i < it.w; i++) {
      const s = (j * it.w + i) * 4, d = ((oy + j) * WIDTH + ox + i) * 4, a = it.rgba[s + 3] / 255;
      for (let c = 0; c < 3; c++) px[d + c] = Math.round(it.rgba[s + c] * a + px[d + c] * (1 - a));
    }
  });
  return { png: L.png(WIDTH, H, px), w: WIDTH, h: H };
}

async function main() {
  const tarjetas = tarjetaSizes();
  const browser = await chromium.launch();
  let a, b;
  try { a = await render(browser, tarjetas); b = await render(browser, tarjetas); } finally { await browser.close(); }
  assert.deepStrictEqual(a, b, 'two renders differ');

  fs.rmSync(OUT, { recursive: true, force: true });
  const summary = [];
  for (const group of ['engine', 'kit']) {
    const keys = a.plan.filter(([k]) => k.startsWith(group + ':')).map(([k]) => k);
    const sprites = [], functions = {}, sheetItems = [];
    for (const key of keys) {
      const fn = key.split(':')[1];
      const list = a.byKey[key];
      const bufs = list.map(e => Buffer.from(e.rgba, 'base64'));
      list.forEach((e, i) => assert.strictEqual(bufs[i].length, e.w * e.h * 4, e.id));
      const all = Buffer.concat(bufs);
      L.write(path.join(OUT, group, fn + '.bin'), all);
      let off = 0;
      list.forEach((e, i) => {
        const opaque = bufs[i].some((v, p) => p % 4 === 3 && v !== 0);
        assert(opaque, e.id + ' is empty');
        sprites.push({ id: e.id, fn, call: callText(group, e), args: e.args, w: e.w, h: e.h, file: fn + '.bin', offset: off, bytes: bufs[i].length, sha256: L.sha256(bufs[i]), target: e.target || undefined, note: e.note || undefined });
        sheetItems.push({ fn, w: e.w, h: e.h, rgba: bufs[i] });
        off += bufs[i].length;
      });
      const sites = usage(fn);
      functions[fn] = { file: fn + '.bin', sprites: list.length, bytes: all.length, sha256: L.sha256(all), usedInHistoria: sites.length, firstUses: sites.slice(0, 6) };
    }
    const head = { group, what: 'every sprite the functions of ' + (group === 'engine' ? 'historia/engine.js' : 'historia/escenas/kit.js') + ' make, over the argument values the code base uses',
      format: 'Each function has one <function>.bin: the RGBA bytes (straight alpha, row-major, w * h * 4) of its sprites one after another, in the order of this list. A sprite is the `bytes` bytes at `offset`. A "maker" (no `target`) is the picture the function returns. A "drawer" has a `target`: a transparent canvas (or Buf) of that size is made first, then the function is called on it with `args` (the canvas or Buf is the first argument, left out of `args`), and the target is the sprite.',
      sheet: 'sheet-' + group + '.png: all of them at 1:1 in this order, over grey, a gap between functions. For looking at.' };
    if (group === 'kit') head.FAM = a.fam;
    const txt = JSON.stringify(head, null, 2).replace(/\n\}$/, '') + ',\n  "functions": {\n' + Object.entries(functions).map(([k, v]) => '    ' + JSON.stringify(k) + ': ' + JSON.stringify(v)).join(',\n') + '\n  },\n  "sprites": [\n' + sprites.map(s => '    ' + JSON.stringify(s)).join(',\n') + '\n  ]\n}\n';
    JSON.parse(txt);
    L.write(path.join(OUT, group, 'sprites.json'), txt);
    const sh = sheet(sheetItems);
    L.write(path.join(OUT, 'sheet-' + group + '.png'), sh.png);
    summary.push(group + ': ' + sprites.length + ' sprites, ' + keys.length + ' functions, sheet ' + sh.w + 'x' + sh.h);
    for (const k of Object.keys(functions)) summary.push('  ' + k + ' ' + functions[k].sprites + (functions[k].usedInHistoria ? '' : '  (not used in historia/)'));
  }
  const r = L.writeIndex(OUT, 'sprites of engine.js and kit.js, as RGBA, with the call that made each');
  console.log(summary.join('\n'));
  console.log('tarjeta sizes found: ' + tarjetas.map(t => t.join('x')).join(' '));
  console.log('index ' + r.files + ' files, ' + r.totalBytes + ' bytes');
}
main().catch(e => { console.error(e); process.exit(1); });
