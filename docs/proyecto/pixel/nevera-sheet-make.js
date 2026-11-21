#!/usr/bin/env node
'use strict';
/* La nevera's sheet (order 39a): writes docs/proyecto/pixel/nevera-sheet.json from nevera-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/nevera-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.NEVERA_SET), its part map, its depth, its surfaces and every castShadow call from nevera-set.html in headless
   Chrome, for every state the set can bake; measures the old sprite layer (historia/engine.js, juego.js, kit.js and escenas/nevera.js as they
   are: every shape is what nevera.js draw() itself draws for a world holding only that one thing, against the same world without it); projects
   every world point with the engine's own formula; checks the sheet against coqui/ref/escenas/nevera/ (positions.json, inventory.json,
   pairs.json); against every moment of every recorded run of the scene's stories and of the routine h-nevera, which has no recorded run in
   coqui/ref/trazas/ and is played here with the same tool (coqui/tool/ref/trazas/juega.mjs --states: the steps' ends); and against every tick
   inside the acts: the old page played by the same machine (page-init.js, page-drive.js: the same seed, think time and clock) with nevera.js
   as the port will have it (the sheet's moves applied) and the story files' positions through the sheet's remap. It reads nevera.js itself for
   every number that is a place on the picture (the sheet's code). It loads nevera-preview.html (over a local http server it starts and stops)
   to check that the preview puts everyone where the sheet does. Every check measures the picture as it is drawn: the sorted list composed as
   nevera.js draws it (each item owns the pixels it drew last; a set part drawn again only where it is nearer than that owner). Nothing in the
   repo is written but the sheet. A second run writes the same bytes. El banco's maker (orden/36a) and El lago's are the models.
   NEVERA_NOCHECK=1: write the sheet only (for designing). NEVERA_DUMP=<folder>: also write each run's step ends and ticks, the recorded and the
   port's, there (for the pictures; not in the repo). Temporary files go where os.tmpdir() says (TMPDIR). */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'nevera-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/nevera');
const NEV_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/nevera.js'), 'utf8');
const LINES = NEV_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('nevera.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const R = Math.round;
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

// the baked states: nev (shut, open, half open), cajon (open only: none, shut, pulled out), pila (empty, dishwater, juice), banco (the stool)
const ALL_STATES = [];
for (const nev of [0, 1, 2]) for (const cajon of nev === 1 ? [0, 1, 2] : [0]) for (const pila of ['0', 'a', 'j']) for (const banco of [1, 0]) ALL_STATES.push([nev, cajon, pila, banco].join('.'));
const keyOf = w => { const n = w.nev || {}, nev = n.abierta === 1 ? 1 : n.abierta === 2 ? 2 : 0; return [nev, nev === 1 ? (n.cajonver ? 2 : n.cajon ? 1 : 0) : 0, w.pila === 'a' || w.pila === 'j' ? w.pila : '0', w.banco ? 1 : 0].join('.'); };
const queryOf = k => { const [nev, cajon, pila, banco] = k.split('.'); return 'nev=' + nev + '&cajon=' + cajon + '&pila=' + pila + '&banco=' + banco; };
// the set's parts and whose touch key each is
const THING_OF = p => /^nevera/.test(p) ? 'nevera' : p === 'pared' || p === 'ventana' || p === 'mostrador' || p === 'pila' || p === 'banco' ? 'cocina' : p;
const FRONT = ['nevera', 'nevera.dentro', 'nevera.puerta', 'mostrador', 'pila', 'banco', 'ventana'];   // what can be nearer than someone

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, rgb: {}, shadows: {}, ms: {}, shadowPx: {}, onGround: {}, zone: {}, outside: {} };
  for (const key of ALL_STATES) {
    await page.goto('file://' + path.join(__dirname, 'nevera-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(NEVERA_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      const zone = NEVERA_SET.zones(), rowsT = NEVERA_SET.rows();
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; COCINA_FLOOR = null; const t0 = performance.now(); buildSet(); const first = performance.now() - t0;
      const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      castShadow = cs0; part = part0;
      const onGround = []; for (let i = 0; i < W * H; i++) onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0);
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), rgb: rgbA, calls, bake: BAKE_MS, first, warm,
        shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, zone: zone.zone, outside: zone.outside, rows: rowsT };
    });
    G.ms[key] = { first: g.first, warm: g.warm, page: g.bake };
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, ROWS: g.rows });
    G.parts[key] = g.parts; G.z[key] = g.z; G.rgb[key] = g.rgb; G.shadows[key] = g.calls;
    for (const k of ['shadowPx', 'onGround', 'zone', 'outside']) (G[k] = G[k] || {})[key] = g[k];
  }
  // the first bake of every state in a fresh page (the floor built too)
  G.fresh = {};
  for (const key of ALL_STATES) for (let n = 0; n < 3; n++) { const p2 = await browser.newPage(); await p2.goto('file://' + path.join(__dirname, 'nevera-set.html') + '?' + queryOf(key)); const ms = await p2.evaluate(() => BAKE_MS); G.fresh[key] = Math.min(G.fresh[key] || 1e9, ms); await p2.close(); }   // the least of three fresh pages (the machine is shared)
  if (errs.length) throw new Error(errs.join('; '));
  const mpage = await browser.newPage(); mpage.on('pageerror', e => errs.push(String(e)));
  G.M = await measure(mpage);
  const CACHE = process.env.NEVERA_CACHE;   // design only: a file outside the repo holding the runs, the port's ticks and the shapes, reused while the moves are the same
  const cached = CACHE && fs.existsSync(CACHE) ? JSON.parse(fs.readFileSync(CACHE, 'utf8')) : null;
  const runs = cached ? cached.runs : storyStates();
  const sheet = make(G, runs);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.NEVERA_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  const movesSig = JSON.stringify([sheet.moves, sheet.remap, sheet.dropped]);
  if (cached && cached.sig === movesSig) { G.TICKS = cached.TICKS; } else G.TICKS = await tickStates(browser, runs, sheet);
  G.PV = await previewPlaces(browser, runs);
  if (process.env.NEVERA_DUMP) { fs.mkdirSync(process.env.NEVERA_DUMP, { recursive: true }); runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.NEVERA_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states, ticks: G.TICKS[i].ticks }))); }
  // the sprite layer's shapes for every item seen at any moment (measured in the browser, nevera.js draw() itself)
  G.MASK = await masks(mpage, collectKeys(sheet, G, runs));
  if (CACHE) fs.writeFileSync(CACHE, JSON.stringify({ runs, TICKS: G.TICKS, sig: movesSig }));
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 400).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the old sprite layer, measured in the browser ----------
   historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/nevera.js loaded as they are into a blank page. Every shape is what
   nevera.js draw() itself draws for a world holding only that one thing, against the same world without it: so a person's held thing, a
   cup's colour, the smell lines of an old roll are in its shape. A bubble is drawn as nevera.js bub2 draws it (twice its size, its tail's tip
   at the origin), on both frames of its bob; a thought cloud as nube() draws it */
const HTML0 = '<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>';
async function measure(page) {
  await page.setContent(HTML0);
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/nevera.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  const m = await page.evaluate(() => {
    const keys = Object.keys(BUB).concat(Object.keys(BUBL)), bubbles = {};
    for (const k of keys) {
      let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const a of [0, 1]) {
        const cv = document.createElement('canvas'); cv.width = 400; cv.height = 300; const g = cv.getContext('2d');
        g.translate(200, 250); g.scale(2, 2); bub(g, k, 0, 0, a);
        const d = g.getImageData(0, 0, 400, 300).data;
        for (let i = 0; i < 400 * 300; i++) if (d[i * 4 + 3]) { const x = i % 400 - 200, y = (i / 400 | 0) - 250; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
      }
      bubbles[k] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    }
    return { bubbles, PX: KIT.PX };
  });
  const png = f => 'data:image/png;base64,' + fs.readFileSync(path.join(REF, 'frames', f)).toString('base64');
  m.oldBg = await page.evaluate(async src => { const im = await new Promise(res => { const i = new Image(); i.onload = () => res(i); i.src = src; }); const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0); return Array.from(g.getImageData(0, 0, 240, 216).data); }, png('bg.nevera.png'));
  return m;
}
// an item's key (what its shape depends on) and the world that draws it alone (where it is drawn: SHAPE_AT, or the scene's own place)
const SHAPE_AT = [120, 150];
const pick = (o, ks) => ks.map(k => o[k] == null ? '' : typeof o[k] === 'object' ? JSON.stringify(o[k]) : o[k]).join('|');
// the things a world shows, raw: their kind, id, the object, the mask's key, the spec that draws it alone and the anchor its rows are relative to
function rawItems(w) {
  const out = [], shown = o => o && o.vis !== 0;
  for (const [id, p] of Object.entries(w.gente || {})) if (shown(p) && p.x != null) {
    const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0, paso: 0, bub: null, piensa: null, fuera: 0, gorro: 0 });
    out.push({ kind: p.fuera ? 'outside' : 'person', id, o: p, key: 'p|' + id + '|' + pick(p, ['pose', 'dir', 'lleva', 'alza', 'bebe', 'come', 'bebecosa', 'cierra']), spec: { gente: { [id]: o } }, at: SHAPE_AT });
    const b = Object.assign({}, o, { lleva: null, alza: null, bebe: null, come: null, bebecosa: null });
    out.push({ kind: 'bare', id, o: p, key: 'pb|' + id + '|' + pick(p, ['pose', 'dir', 'cierra']), spec: { gente: { [id]: b } }, at: SHAPE_AT });
    if (p.fuera && p.gorro) out.push({ kind: 'hat', id: id + ' hat', o: p, key: 't|sombrero||0|0', spec: { cosas: [{ k: 'sombrero', x: SHAPE_AT[0], y: SHAPE_AT[1] }] }, at: SHAPE_AT });
  }
  (w.cosas || []).forEach((c, i) => { if (shown(c) && c.x != null) out.push({ kind: 'thing', id: 'cosa ' + (c.id || c.k + i), o: c, key: 't|' + pick(c, ['k', 'v', 'rot', 'e']), spec: { cosas: [Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1] })] }, at: SHAPE_AT }); });
  (w.vuelos || []).forEach((c, i) => { if (c && c.x != null) out.push({ kind: 'flying', id: 'vuelo ' + c.k + i, o: c, key: 'v|' + pick(c, ['k', 'v', 'rot']), spec: { vuelos: [Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1] })] }, at: SHAPE_AT }); });
  (w.repisa || []).forEach((c, i) => { if (shown(c) && c.x != null) out.push({ kind: 'sill', id: 'repisa ' + (c.id || c.k + i), o: c, key: 'r|' + pick(c, ['k', 'v', 'rot', 'e']), spec: { repisa: [Object.assign({}, c, { x: 120, dy: 0 })] }, at: [120, 98] }); });
  const P = w.patio || {};
  if (P.carrito) out.push({ kind: 'yard', id: 'carrito', o: { x: P.carrito === 1 ? 196 : P.carrito }, key: 'c|', spec: { patio: { carrito: 196 } }, at: [196, 76] });
  (P.cosas || []).forEach((c, i) => out.push({ kind: 'yard', id: 'muro ' + c.k + i, o: c, key: 'w|' + pick(c, ['k', 'v']), spec: { patio: { cosas: [Object.assign({}, c, { x: 182 })] } }, at: [182, 71] }));
  (P.aves || []).forEach((c, i) => out.push({ kind: 'bird', id: 'ave ' + i, o: c, key: 'a|' + (c.come ? 1 : 0), spec: { patio: { aves: [{ x: 182, come: c.come }] } }, at: [182, 71] }));
  const N = w.nev || {};
  if (N.abierta === 1) {
    (N.h || []).forEach((c, i) => { if (c) out.push({ kind: 'fridge', id: 'nevera ' + i + ' ' + c.k, slot: i, o: c, key: 'n|' + pick(c, ['k', 'v']), spec: { nev: { abierta: 1, h: [{ k: c.k, v: c.v }] } }, at: [55, 79] }); });
    if (N.soporte) { out.push({ kind: 'fridge', id: 'soporte', slot: 0, o: {}, key: 'n|soporte|', spec: { nev: { abierta: 1, h: [{ k: 'soporte' }] } }, at: [55, 79] }); out.push({ kind: 'fridge', id: 'platoazul', slot: 1, dy: 1, o: {}, key: 'n|platoazul|', spec: { nev: { abierta: 1, h: [{ k: 'platoazul' }] } }, at: [55, 79] }); }
    if (N.cajonver) { const C = N.cajon || {}; for (let i = 0; i < (C.guineo || 0); i++) out.push({ kind: 'drawer', id: 'cajon guineo ' + i, fruit: 'guineo', i, o: {}, key: 'n|guineo|', spec: { nev: { abierta: 1, h: [{ k: 'guineo' }] } }, at: [55, 79] });
      for (let i = 0; i < (C.manzana || 0); i++) out.push({ kind: 'drawer', id: 'cajon manzana ' + i, fruit: 'manzana', i, o: {}, key: 'n|manzana|', spec: { nev: { abierta: 1, h: [{ k: 'manzana' }] } }, at: [55, 79] }); }
  }
  if (w.cesta) out.push({ kind: 'top', id: 'cesta', o: w.cesta, key: 'e|' + w.cesta.n, spec: { cesta: { n: w.cesta.n } }, at: [68, 40] });
  if (w.canasta) out.push({ kind: 'canasta', id: 'canasta', o: w.canasta, key: 'k|' + JSON.stringify(w.canasta.items || []), spec: { canasta: { x: 156, items: w.canasta.items || [] } }, at: [156, 123] });
  if (w.encima && w.cq && w.cq.vis) out.push({ kind: 'carried', id: 'encima', o: w.encima, key: 't|' + pick(w.encima, ['k', 'v']) + '||0', spec: { cosas: [{ k: w.encima.k, v: w.encima.v, x: SHAPE_AT[0], y: SHAPE_AT[1] }] }, at: SHAPE_AT });
  return out;
}
const BASE_W = () => ({ respEn: [142, 10], olfato: null, canasta: null, pila: null, vista: null, nev: { abierta: 0, h: [] }, mos: {}, patio: {}, repisa: [], cesta: null, gente: {}, cosas: [], vuelos: [], banco: 0, encima: null, tarjeta: null, marcas: null, cq: { x: 0, y: 0, s: 1, dy: 0, al: 1, vis: 0, bub: null, hace: null, piensa: null } });
function collectKeys(sheet, G, runs) {
  const keys = new Map();
  const add = w => { for (const it of rawItems(w)) if (it.key && !keys.has(it.key)) keys.set(it.key, { spec: it.spec, at: it.at, fridge: it.kind === 'fridge' || it.kind === 'drawer' }); };
  for (const r of runs) for (const l of r.lines) add(l.W);
  for (const T of G.TICKS) { for (const t of T.ticks) add(t.W); for (const L of T.states) add(L.W); }
  for (const ps of pairSidesOf()) add(pairW(ps, sheet));
  return [...keys.entries()];
}
// each key's shape: the rows [dy, x from, x to] relative to its anchor that nevera.js draw() changes, its mean colour
async function masks(page, list) {
  return page.evaluate(([list, base]) => {
    const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d');
    const E = ESCENAS.nevera;
    const shot = w => { W = w; F = 0; TALK = null; g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.imageSmoothingEnabled = false; E.draw(g, w, 0); return g.getImageData(0, 0, 240, 216).data; };
    const bgs = {}, out = {};
    for (const [key, { spec, at, fridge }] of list) {
      const b0 = Object.assign(JSON.parse(JSON.stringify(base)), fridge ? { nev: { abierta: 1, h: [] } } : {}), bk = fridge ? 'f' : 'n';
      if (!bgs[bk]) bgs[bk] = shot(b0);
      const bg = bgs[bk], d = shot(Object.assign(JSON.parse(JSON.stringify(b0)), JSON.parse(JSON.stringify(spec)))), rows = []; let n = 0; const s = [0, 0, 0];
      for (let y = 0; y < 216; y++) { let a = -1, b = -1; for (let x = 0; x < 240; x++) { const i = (y * 240 + x) * 4; if (d[i] !== bg[i] || d[i + 1] !== bg[i + 1] || d[i + 2] !== bg[i + 2]) { if (a < 0) a = x; b = x; n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } } if (a >= 0) rows.push([y - at[1], a - at[0], b - at[0]]); }
      out[key] = { rows, mean: s.map(v => Math.round(v / Math.max(1, n))) };
    }
    return out;
  }, [list, BASE_W()]);
}

/* ---------- a local http server over the repo (the preview, the old page) ---------- */
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.woff2': 'font/woff2', '.css': 'text/css', '.mp3': 'audio/mpeg' };
async function serve(fn) {
  const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(REPO, u);
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); fs.createReadStream(f).pipe(res); });
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  try { return await fn('http://127.0.0.1:' + srv.address().port); } finally { await new Promise(r => srv.close(r)); }
}

/* ---------- the preview's places: nevera-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/nevera-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- nevera.js as the port will have it: the sheet's moves, drops and helps applied (the same edit as nevera-preview.html's, without its drawing) ---------- */
function portSource(sheet) {
  let src = NEV_JS; const done = new Set();
  const X = (a, b) => { if (!src.includes(a)) throw new Error('nevera.js does not hold ' + a.slice(0, 80)); src = src.split(a).join(b); };
  for (const d of sheet.dropped) X(d.src, d.to);
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); X(m.src, m.to); }
  for (const [a, b] of sheet.helps.lines) X(a, b);
  return src;
}
// a story file with its positions through the sheet's remap (the host does it: page 12 section 5); returns the text
function portStory(file, sheet) {
  const j = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos', file + '.json'), 'utf8'));
  for (const e of sheet.remap) { if (!e.moved || e.kind !== 'point') continue;
    for (const u of e.uses) { const [f, at] = u.split(' '); if (f !== file + '.json') continue;
      const keys = at.split('.'), last = keys.pop(), o = keys.reduce((a, k) => a[/^\d+$/.test(k) ? +k : k], j), t = o[last];
      if (Array.isArray(t)) { t[0] = e.new[0]; t[1] = e.new[1]; } else if (t && typeof t === 'object') { t.x = e.new[0]; t.y = e.new[1]; } else throw new Error('remap: ' + u + ' is not a place'); } }
  return JSON.stringify(j);
}

/* ---------- every tick inside the acts (as El banco's maker): the old page played by the same machine as the recorded runs, nevera.js and the
   story files as the port will have them, the scene's W kept after every timer the runner fires when it changed ---------- */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = { gente: W.gente, cosas: W.cosas, vuelos: W.vuelos, cq: W.cq, nev: W.nev, mos: W.mos, patio: W.patio, repisa: W.repisa, cesta: W.cesta, canasta: W.canasta,
      pila: W.pila, vista: W.vista, olfato: W.olfato, banco: W.banco, encima: W.encima, tarjeta: W.tarjeta, marcas: W.marcas, respEn: W.respEn, resp: W.resp, spot: W.spot, twinkle: W.twinkle, F: typeof F === 'number' ? F : 0 };
    const s = JSON.stringify(o, (k, x) => typeof x === 'function' || (x && x.nodeType) || x instanceof HTMLCanvasElement ? undefined : x); if (s !== last) { last = s; window.__TICKS.push({ t: H.now, W: JSON.parse(s) }); } } catch (e) {} };
  H.drain = () => d().then(() => { keep(); }); })();`;
async function tickStates(browser, runs, sheet) {
  const INIT = fs.readFileSync(path.join(TRAZAS, 'page-init.js'), 'utf8').replace('__SEED__', '1'), DRIVE = fs.readFileSync(path.join(TRAZAS, 'page-drive.js'), 'utf8');
  const SRC = portSource(sheet);
  return serve(async base => { const out = [];
    for (const r of runs) {
      const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: 'UTC', locale: 'en-US' });
      try {
        await ctx.addInitScript(INIT); await ctx.addInitScript(TICK_HOOK);
        await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop());
          return fs.existsSync(path.join(REPO, 'historia/audio', name)) ? route.fulfill({ status: 200, contentType: 'audio/mpeg', body: 'ID3' }) : route.fulfill({ status: 404, body: '' }); });
        await ctx.route(/\/historia\/escenas\/nevera\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
        await ctx.route(/\/historia\/cuentos\/[^/]+\.json(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop()).replace(/\.json$/, '');
          return route.fulfill({ status: 200, contentType: 'application/json', body: portStory(name, sheet) }); });
        const page = await ctx.newPage();
        await page.goto(base + '/historia/index.html?cuento=' + r.story.id + '&fast=1&rec=1&mic=stub:none&abiertas=todas');
        for (let i = 0; ; i++) { if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break; if (i > 600) throw new Error('the page did not load ' + r.story.id); await new Promise(z => setTimeout(z, 50)); }
        await page.evaluate('voiceReady'); await page.evaluate(DRIVE);
        const tr = await page.evaluate(cfg => window.__drive(cfg), { plan: r.plan, think: 700, limitMs: 4 * 3600e3, states: true });
        if (tr.end !== 'finished') throw new Error('ticks: ' + r.story.id + ' ' + r.plan + ' ended: ' + tr.end);
        out.push({ ticks: await page.evaluate(() => window.__TICKS), states: tr.states });
      } finally { await ctx.close(); }
    }
    return out; });
}

// the scene's stories and its routine (scene "nevera"; not the review set), each played with juega.mjs --states (three plans)
function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'nevera') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nevera-sheet-'));
  try {
    const runs = [];
    for (const st of stories) {
      execFileSync(process.execPath, [path.join(REPO, 'coqui/tool/ref/trazas/juega.mjs'), '--only', st.id, '--out', path.join(tmp, 'trazas', st.id), '--states', path.join(tmp, 'states')], { cwd: REPO, stdio: 'pipe' });
      for (const plan of ['right', 'wrong', 'alternate']) {
        const lines = fs.readFileSync(path.join(tmp, 'states', st.id, plan + '.states.jsonl'), 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
        runs.push({ story: st, plan, lines, recorded: fs.existsSync(path.join(REPO, 'coqui/ref/trazas', st.id, plan + '.json')) });
      }
    }
    return runs;
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}
const PAIRS = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
const pairSidesOf = () => PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'nevera').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
// a pair picture's world, through the sheet's remap (cual.js panelW: the frog at 123, 150 s .86 unless the pair sets him)
function pairW(ps, sheet) {
  const w = Object.assign(BASE_W(), { banco: 0 }, JSON.parse(JSON.stringify(ps.spec.set || {})));
  return remapW(sheet, w, 'cual-nevera');
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ };
}

/* ---------- the old scene's numbers (historia/escenas/nevera.js, read as text) ---------- */
const OLD = (() => { const m = NEV_JS.match(/const PISO=(\d+),ENC=(\d+),NEV=\[(\d+),(\d+),(\d+),(\d+)\],MOS=\[(\d+),(\d+)\],BANCO=\[(\d+),(\d+)\],VEN=\[(\d+),(\d+),(\d+),(\d+)\],SILL=(\d+),PATIO=(\d+),MURO=(\d+);/);
  if (!m) throw new Error('nevera.js changed: the constants'); const n = m.slice(1).map(Number);
  const H = NEV_JS.match(/const HUECO=(\[\[[\d,\[\]]*?\]\]);/), L = NEV_JS.match(/lugar:\{inicio:\[BANCO\[0\]-16,BANCO\[1\]-27,1\],centro:\[BANCO\[0\]-16,BANCO\[1\]-27,1\]\}/);
  if (!H || !L) throw new Error('nevera.js changed: HUECO or lugar');
  return { PISO: n[0], ENC: n[1], NEV: n.slice(2, 6), MOS: n.slice(6, 8), BANCO: n.slice(8, 10), VEN: n.slice(10, 14), SILL: n[14], PATIO: n[15], MURO: n[16], HUECO: JSON.parse(H[1]),
    LUGAR: { inicio: [n[8] - 16, n[9] - 27, 1], centro: [n[8] - 16, n[9] - 27, 1] }, CESTA: [68, n[3]] }; })();
const OLDBOX = { nevera: [OLD.NEV[0], OLD.NEV[1], OLD.NEV[2], OLD.NEV[3]], frutas: [OLD.NEV[0] + 4, OLD.NEV[1] + 20, OLD.NEV[2] - 8, 48], cocina: [22, 16, 196, 198] };
// the places a bubble's tail may go, in order (as El banco's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner card nevera.js hud draws, in the 196 x 216 display (tarjeta(3, 3, 66, 24) covers [2, 2, 68, 26])
const BOARD = [2, 2, 68, 26];
const VX0 = 28;   // the view's x0 (the old 22: views.wide.why)
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];

/* ---------- the design: the surfaces' rows, and every place that moves (make() reads it) ----------
   The counter runs along the back wall (a world axis): its top falls half a row a pixel to the right, so whatever stands on it, on the sill or
   on the yard's wall, and whoever stands outside the window, stands on that slope: each row is a line sy = c + sx / 2 (CT, SL, MU, PA, CB, VT,
   added to nevera.js's constants), and every place that stood on the old level rows stands on it at its old x. The fridge's places (HUECO, the
   drawer, its top) are the nearest that show whole through its opening (searched below, on the set's own pixels) */
function fitRow(arr, xs) { let s = 0; for (const x of xs) s += arr[x] - x / 2; return Math.round(s / xs.length * 2) / 2; }
function design(G, E) {
  const F = G.F, RW = G.ROWS, xs = []; for (let x = 100; x <= 230; x++) xs.push(x);
  const yx = Object.keys(RW.yard).map(Number);
  const gx = Object.keys(RW.glassTop).map(Number).filter(x => x >= 160 && x <= 205);
  const C = { ct: fitRow(RW.counter, xs), sl: fitRow(RW.sill, xs), vt: Math.ceil(fitRow(Object.assign([], RW.glassTop), gx)), vb: fitRow(RW.winBottom, xs), cb: fitRow(RW.front, xs) + 6, mu: fitRow(Object.assign([], RW.yard), yx) };
  C.pa = C.vt + 50;   // whoever stands outside: a grown-up's face 2 rows under the top of what shows of the outside through the window (VT: the top of their hair under the frame), so their face and shoulders show and stay clear of the hint frames of what stands on the counter
  const f = c => x => Math.round(c + x / 2);
  C.CT = f(C.ct); C.SL = f(C.sl); C.MU = f(C.mu); C.PA = f(C.pa); C.CB = f(C.cb); C.VT = f(C.vt);
  // the fridge's places: each HUECO thing whole over the inside of the open fridge (zones d, e: nothing of the fridge, its door or its rim in front
  // of it) and its feet on its shelf (HUECO 0 and 1 the upper shelf, 2 and 3 the lower), well inside the shelf; the two on a shelf as far apart
  // as the old (26 px); the nearest to the old points (the sum of the two distances). What stands in a slot in any story (nevera.js tenida draws
  // a thing w x h with its foot's middle at the point): 0 leche 12 x 19, platofruta 22 x 12, soporte 16 x 7; 1 queso 18 x 13, platofruta,
  // platoazul 20 x 6 (one row lower); 2 and 3 platofruta
  const SIZES = [[[12, 19], [22, 12], [16, 7]], [[18, 13], [22, 12], [20, 7]], [[22, 12]], [[22, 12]]];
  const Z = G.zone['1.0.0.1'], inside = (x, y) => x >= 0 && y >= 0 && x < 240 && y < 216 && 'de'.includes(Z[y * 240 + x]);
  // and nothing of the set nearer than it (a shelf's glass in front of a thing deep on the shelf below): the front test's plane (front.plane)
  const ZB = G.z['1.0.0.1'], T30 = Math.tan(Math.PI / 6);
  const fits = (slot, x, y, z) => { const pl = { face: 'x', at: E.atZ(x, y, z)[0] };
    for (const [w, h] of SIZES[slot]) for (let yy = y - h; yy < y; yy++) for (let xx = x - (w >> 1); xx < x - (w >> 1) + w; xx++) { if (!inside(xx, yy)) return false; if (ZB[yy * 240 + xx] > planeDepth(E, pl, xx, yy) + 1e-3) return false; } return true; };
  const onShelf = (x, y, z) => { const w = E.atZ(x, y - 1, z); return w[0] >= .14 && w[0] <= F.FR.d - .08 && w[1] >= F.FR.a0 + .2 && w[1] <= F.FR.a1 - .2; };
  const cands = (slot, z) => { const o = OLD.HUECO[slot], out = []; for (let y = o[1] - 60; y <= o[1] + 60; y++) for (let x = o[0] - 30; x <= o[0] + 30; x++) if (onShelf(x, y, z) && fits(slot, x, y, z)) out.push([x, y, Math.hypot(x - o[0], y - o[1])]); return out; };
  const H = OLD.HUECO.map(p => p.slice());
  for (const [i, j, z] of [[0, 1, F.FR.shelves[0]], [2, 3, F.FR.shelves[1]]]) {
    const A = cands(i, z), B = cands(j, z); let best = null;
    const clear = q => i < 2 || [0, 1].every(u => { const o = H[u]; return Math.abs(q[0] - o[0]) >= 22 || q[1] - 12 >= o[1] + 2 || q[1] <= o[1] - 21; });
    for (const a of A) for (const b of B) { if (b[0] - a[0] < 26 || !clear(a) || !clear(b)) continue; const s = a[2] + b[2]; if (!best || s < best[0] || (s === best[0] && a[1] + b[1] < best[1][1] + best[2][1])) best = [s, a, b]; }
    if (!best) throw new Error('design: no place in the fridge for HUECO ' + i + ' and ' + j);
    H[i] = best[1].slice(0, 2); H[j] = best[2].slice(0, 2);
  }
  C.HUECO = H;
  return C;
}
// the drawer pulled out (state 1.2): its floor's pixels (zone r); the two piles of fruit stand on it, the guineos at its left third, the manzanas
// at its right third, each on the row two above the floor's lowest at that column
function drawerPlaces(G, E) {
  // each pile on the drawer's floor (zone r under its foot), nothing of the set nearer than any of its three fruit (the front test's plane),
  // the two piles 14 px apart and more, the nearest to the old (55, 148) and (78, 148)
  const K = '1.2.0.1', Z = G.zone[K], ZB = G.z[K], T30 = Math.tan(Math.PI / 6), F = G.F, zf = F.FR.bin[0] + .06;
  const clear = (x, y, w, h, step) => { const pl = { face: 'x', at: E.atZ(x, y, zf)[0] }; for (let k = 0; k < 3; k++) for (let yy = y - k * step - h; yy < y - k * step; yy++) for (let xx = x - (w >> 1); xx < x - (w >> 1) + w; xx++) { const i = yy * 240 + xx; if (xx < 0 || xx >= 240 || yy < 0 || (Z[i] !== 'r' && ZB[i] > planeDepth(E, pl, xx, yy) + 1e-3)) return false; } return true; };
  const cands = (o, w, h, step) => { const out = []; for (let y = o[1] - 50; y <= o[1] + 40; y++) for (let x = o[0] - 30; x <= o[0] + 40; x++) if (Z[(y - 1) * 240 + x] === 'r' && Z[(y - 1) * 240 + x - (w >> 1)] === 'r' && Z[(y - 1) * 240 + x + (w >> 1)] === 'r' && E.atZ(x, y - 1, zf)[0] >= F.FR.d + .1 && clear(x, y, w, h, step)) out.push([x, y, Math.hypot(x - o[0], y - o[1])]); return out; };
  const A = cands([55, 148], 16, 10, 11), B = cands([78, 148], 11, 11, 12); let best = null;
  for (const a of A) for (const b of B) { if (Math.abs(b[0] - a[0]) < 14) continue; const s = a[2] + b[2]; if (!best || s < best[0]) best = [s, a, b]; }
  if (!best) throw new Error('design: no place in the drawer for its fruit');
  return { guineo: best[1].slice(0, 2), manzana: best[2].slice(0, 2) };
}
function designMoves(C, G, E) {
  const F = G.F, CT = C.CT, SL = C.SL, PA = C.PA, MU = C.MU, H = C.HUECO, DR = drawerPlaces(G, E);
  const ctS = x => 'CT(' + x + ')', fn = (n, c) => n + '=x=>Math.round(' + c + '+x/2)';
  // the fridge's top: where the bread basket and the two glasses stand (the old row 40 is over its top): the middle of its top at their columns
  const topRow = x => Math.round(G.ROWS.fridgeTop[x]);
  const CES = [68, topRow(68) + 6], C1 = [76, topRow(76) + 3], C2 = [88, topRow(88) + 3];
  C.CES = CES; C.C1 = C1; C.C2 = C2; C.DR = DR;
  const M = [];
  const mv = (act, src, to, why, pts) => M.push(Object.assign({ act, src, to, why }, pts ? { pts } : {}));
  mv('*', 'SILL=98,PATIO=120,MURO=70;', 'SILL=98,PATIO=120,MURO=70,' + [fn('CT', C.ct), fn('SL', C.sl), fn('MU', C.mu), fn('PA', C.pa), fn('CB', C.cb), fn('VT', C.vt)].join(',') + ';',
    'the rows of the new set\'s surfaces, each a line falling half a row a pixel (the counter along the back wall, a world axis): CT where a thing stands on the counter (the old ENC + 10), SL on the window\'s sill (the old SILL), MU the yard wall\'s top seen through the window (the old MURO), PA where whoever stands outside has their feet (the old PATIO), CB the floor just before the counter\'s foot, VT the top row of the outside seen through the window; each place that stood on an old level row keeps its x and stands on the new row there');
  mv('*', 'const HUECO=[[55,79],[81,79],[55,105],[81,105]];', 'const HUECO=' + JSON.stringify(H) + ';',
    'the four places on the fridge\'s two shelves: the old fridge was 116 px high (twice abuela) and its shelves at rows 79 and 105; the new one stands to the wall\'s cut (3.15, 71 px), so each thing stands where it shows whole through the open door\'s opening on its shelf, the nearest to its old point (searched on the set\'s pixels), the two of a shelf side by side 26 px apart as the old',
    OLD.HUECO.map((o, i) => ['nevera', o, H[i]]));
  mv('*', 'const EN={pan:[160,ENC+10],frutero:[170,ENC+10],vasos:[202,ENC+9],pila:[124,ENC+10],cesta:[68,NEV[1]]};', 'const EN={pan:[160,CT(160)],frutero:[170,CT(170)],vasos:[202,CT(202)-1],pila:[124,CT(124)],cesta:[' + CES + ']};',
    'the counter\'s places (CT) and the bread basket on the fridge\'s top: the old fridge\'s top was at row 40; the new top\'s middle at that column', [['cesta', OLD.CESTA, CES]]);
  // patio(): the yard seen through the window (clipped to the window's glass: clips), what stands on the yard wall, the sill
  mv('*', 'tenida(c,"carrito",P.carrito===1?VEN[0]+46:P.carrito,MURO+6);', 'tenida(c,"carrito",P.carrito===1?VEN[0]+46:P.carrito,MU(P.carrito===1?VEN[0]+46:P.carrito)+6);', 'the piragua cart in the yard: on the ground before the yard wall (MU + 6), at its old x');
  mv('*', '(P.cosas||[]).forEach(o=>tenida(c,o.k,o.x,MURO+1,0,0,o.v));', '(P.cosas||[]).forEach(o=>tenida(c,o.k,o.x,MU(o.x)+1,0,0,o.v));', 'what lies on the yard wall: on its top (MU + 1) at its old x');
  mv('*', 'tenida(c,"ave",o.x,MURO+1-', 'tenida(c,"ave",o.x,MU(o.x)+1-', 'a bird on the yard wall: on its top (MU + 1) at its old x');
  mv('*', 'tenida(c,o.k,o.x,SILL+(o.dy||0),o.rot||0,o.e||0,o.v);if(o.v==="manchas")hedor(c,o.x,SILL-24);', 'tenida(c,o.k,o.x,SL(o.x)+(o.dy||0),o.rot||0,o.e||0,o.v);if(o.v==="manchas")hedor(c,o.x,SL(o.x)-24);', 'a thing on the sill (W.repisa): on the sill\'s top (SL) at its old x');
  // nevera(): the drawer's fruit
  mv('*', 'tenida(c,"guineo",x+15,148-i*11);', 'tenida(c,"guineo",' + DR.guineo[0] + ',' + DR.guineo[1] + '-i*11);', 'the guineos in the drawer pulled out: on the drawer\'s floor, piled as the old (11 rows apart)', [['cajon', [55, 148], DR.guineo]]);
  mv('*', 'tenida(c,"manzana",x+38,148-i*12);', 'tenida(c,"manzana",' + DR.manzana[0] + ',' + DR.manzana[1] + '-i*12);', 'the manzanas in the drawer pulled out: on the drawer\'s floor, piled as the old (12 rows apart)', [['cajon', [78, 148], DR.manzana]]);
  mv('*', 'if(p.fuera)return [R(p.x)-12,VEN[1]+6,24,SILL-VEN[1]-6];', 'if(p.fuera)return [R(p.x)-12,VT(p.x)+2,24,' + Math.round(C.vb - C.vt - 2) + '];', 'whoever stands outside: the part of the window that shows them (its glass, VT down to the sill), at their x');
  mv('*', '{id:"frutas",si:w=>!!(w.nev&&w.nev.abierta===1),box:[NEV[0]+4,NEV[1]+20,NEV[2]-8,48],m:0}', '{id:"frutas",si:w=>!!(w.nev&&w.nev.abierta===1),box:w=>FRUTAS[w.nev&&w.nev.cajonver?1:0],m:0}', 'the fridge\'s inside: the set\'s (things.frutas), with the drawer pulled out or not');
  mv('*', '{id:"nevera",box:[NEV[0],NEV[1],NEV[2],NEV[3]],m:0}', '{id:"nevera",box:w=>NEVERA[(w.nev&&w.nev.abierta)||0],m:0}', 'the fridge: the set\'s (things.nevera), shut, open or half open');
  mv('*', 'box:w=>{const o=w.cosas.find(o=>o.id===id);return [R(o.x)-9,R(o.y)-19,18,23];},m:1,z:3', 'box:w=>{const o=w.cosas.find(o=>o.id===id);return [R(o.x)-9,R(o.y)-19,18,23];},hand:w=>{const o=w.cosas.find(o=>o.id===id);return o?[R(o.x),R(o.y)-17]:null;},m:1,z:3', 'a thing of W.cosas with a name (the cups, the tray\'s roll and plate): the hint hand points at its top (y - 17), not at its middle: on the counter\'s right end the things stand lower than the old row, and the hand at their middle reached the faces of whoever stands before the counter');
  mv('*', 'ab.lleva={k:"platopan",v:2};await mueve("abuela",216,196);', 'ab.lleva={k:"platopan",v:2};await mueve("abuela",216,210);', 'acts.abuelamira (sale): abuela with the bread going to the door: 14 rows nearer, clear of the cups\' hint frames on the counter\'s right end', [['abuela', [216, 196], [216, 210]]]);
  mv('*', 'await mueve("abuela",200,184);', 'await mueve("abuela",200,199);', 'acts.abuelamira: abuela looks into the children\'s cups at the counter\'s right end: the cups stand lower there than the old row, and their hint frames reached her face; 15 rows nearer, still at the counter', [['abuela', [200, 184], [200, 199]]]);
  mv('inicio30', '{id:"carta_leche",k:"carta",v:"leche",x:114,y:86,z:50},{id:"carta_queso",k:"carta",v:"queso",x:132,y:86,z:50}', '{id:"carta_leche",k:"carta",v:"leche",x:119,y:78,z:50},{id:"carta_queso",k:"carta",v:"queso",x:133,y:78,z:50}', 'acts.inicio30: the frog\'s two cards hang on the tile band over the counter, 8 rows higher and a little right of the old: over the tap at the wall, clear of the fridge\'s half open door', [['carta_leche', [114, 86], [119, 78]], ['carta_queso', [132, 86], [133, 78]]]);
  mv('*', 'await mueve("abuela",t.x,176);', 'await mueve("abuela",t.x,Math.max(176,CB(t.x)+2));', 'acts.huele31: abuela bends over a thing on the tray: on the floor before the counter\'s foot (CB + 2) where the counter comes further forward than row 176');
  mv('*', 'fresh:()=>({respEn:[142,10],', 'fresh:()=>({respEn:[154,20],', 'the answer cards: in the dark over the back wall, 2 px clear of the rounds card, their lit frame and glow 4 px inside the view (the old [142, 10] put them 6 px over the top edge)', [['respEn', [142, 10], [154, 20]]]);
  mv('*', '(M.vasos||[]).forEach((v,i)=>tenida(c,"vaso",v.x!=null?v.x:EN.vasos[0]-i*11,EN.vasos[1],0,0,v.de));', '(M.vasos||[]).forEach((v,i)=>tenida(c,"vaso",v.x!=null?v.x:EN.vasos[0]-i*11,CT(v.x!=null?v.x:EN.vasos[0]-i*11)-1,0,0,v.de));', 'the counter\'s cups (W.mos, used by no story): on the counter (CT) at their x');
  mv('*', 'const x=p.x!=null?p.x:150+i*20,y=ENC+10;', 'const x=p.x!=null?p.x:150+i*20,y=CT(x);', 'the counter\'s plates (W.mos, used by no story): on the counter (CT)');
  mv('*', 'ky=K.y||ENC+11;', 'ky=K.y||CT(K.x)+1;', 'the picnic basket on the counter: on its top (CT + 1) at its x');
  mv('*', 'W.olfato={x:t.x,y:ENC+13};', 'W.olfato={x:t.x,y:CT(t.x)+3};', 'acts.huele31: the smell over a thing on the tray: relative to the counter (CT + 3)');
  mv('*', 'x=169+n*9;await vuela(o,x0,y0,x,MURO+2,8);', 'x=169+n*9;await vuela(o,x0,y0,x,MU(x)+2,8);', 'alMuro: a thing thrown out lands on the yard wall\'s top (MU + 2) at its old x');
  // the frog on the counter: his feet on its top (CT - 1, the old ENC + 9) at the old x
  for (const [src, x] of [['ranaA(150,ENC+9)', '150'], ['ranaA(186,ENC+9)', '186'], ['ranaA(j.x-16,ENC+9)', 'j.x-16'], ['ranaA(v.x-26,ENC+9)', 'v.x-26'], ['ranaA(v.x-20,ENC+9)', 'v.x-20'], ['ranaA(EN.pila[0]+22,ENC+9)', 'EN.pila[0]+22']])
    mv('*', src, 'ranaA(' + x + ',CT(' + x + ')-1)', 'the frog on the counter: his feet on its top (CT - 1, the old ENC + 9) at the old x', /^\d+$/.test(x) ? [['cq', [+x - 16, OLD.ENC + 9 - 27], [+x - 16, CT(+x) - 1 - 27]]] : null);
  // the sill and the coins: from the sill or the jar to papá's hand outside
  mv('*', 'vuela({k:"moneda"},mon.x,SILL-4,pa.x,SILL-22,6)', 'vuela({k:"moneda"},mon.x,SL(mon.x)-4,pa.x,SL(pa.x)-22,6)', 'a coin tossed from the sill to papá outside: from the sill (SL) to his hand over it');
  mv('*', 'vuela({k:"moneda"},tar.x,SILL-10,pa.x,SILL-22,9)', 'vuela({k:"moneda"},tar.x,SL(tar.x)-10,pa.x,SL(pa.x)-22,9)', 'a coin from the jar on the sill to papá');
  mv('*', 'vuela({k:"moneda"},t.x,SILL-10,178,SILL-2,5)', 'vuela({k:"moneda"},t.x,SL(t.x)-10,178,SL(178)-2,5)', 'acts.sacamoneda: a coin from the jar onto the sill');
  mv('*', 'vuela({k:"moneda"},t.x,SILL-10,pa.x,SILL-22,5)', 'vuela({k:"moneda"},t.x,SL(t.x)-10,pa.x,SL(pa.x)-22,5)', 'acts.final30: the coins from the jar to papá');
  mv('*', 'vuela({k:"piragua",v:n},pa.x-8,SILL-12,160,ENC+2,6)', 'vuela({k:"piragua",v:n},pa.x-8,SL(pa.x-8)-12,160,CT(160)-8,6)', 'acts.final30: the piragua handed in over the sill onto the counter');
  // whoever stands outside: feet at PA (the old PATIO), at their old x
  const pa = (x, d) => 'PA(' + x + ')' + (d ? (d > 0 ? '+' : '') + d : '');
  const outs = [['papa:{x:158,y:PATIO,', 'papa:{x:154,y:' + pa(154, 4) + ',', 'papa', 154, 4], ['luis:{x:173,y:PATIO-4,', 'luis:{x:166,y:' + pa(166, -4) + ',', 'luis', 166, -4], ['abuelo:{x:207,y:PATIO,', 'abuelo:{x:214,y:' + pa(214, -1) + ',', 'abuelo', 214, -1],
    ['papa:{x:160,y:PATIO,', 'papa:{x:160,y:' + pa(160, 4) + ',', 'papa', 160, 4], ['abuelo:{x:176,y:PATIO,', 'abuelo:{x:176,y:' + pa(176) + ',', 'abuelo', 176, 0], ['mama:{x:200,y:PATIO,', 'mama:{x:200,y:' + pa(200) + ',', 'mama', 200, 0],
    ['mueve("papa",136,PATIO)', 'mueve("papa",136,' + pa(136, 4) + ')', 'papa', 136, 4], ['mueve("papa",158,PATIO)', 'mueve("papa",154,' + pa(154, 4) + ')', 'papa', 154, 4], ['mueve("luis",230,PATIO-4)', 'mueve("luis",230,' + pa(230, -4) + ')', 'luis', 230, -4],
    ['l.y=PATIO-4;', 'l.y=' + pa(230, -4) + ';', 'luis', 230, -4], ['mueve("luis",173,PATIO-4)', 'mueve("luis",166,' + pa(166, -4) + ')', 'luis', 166, -4], ['mueve("papa",186,PATIO)', 'mueve("papa",186,' + pa(186, 4) + ')', 'papa', 186, 4],
    ['mueve("papa",160,PATIO)', 'mueve("papa",160,' + pa(160, 4) + ')', 'papa', 160, 4], ['mueve("mama",198,PATIO)', 'mueve("mama",198,' + pa(198) + ')', 'mama', 198, 0], ['mueve("mama",170,PATIO)', 'mueve("mama",170,' + pa(170) + ')', 'mama', 170, 0],
    ['p.x=158;p.y=PATIO+8;', 'p.x=158;p.y=' + pa(158, 8) + ';', 'luis', 158, 8]];
  mv('*', 'ao.x=207', 'ao.x=214', 'acts.abuelo31: abuelo at the window 7 px right of the old, so that the hint hand at the right answer card stays off his face', [['abuelo', [207, OLD.PATIO], [214, PA(214) - 1]]]);
  const OLDX = { 154: 158, 166: 173, 214: 207 };
  for (const [src, to, who, x, d] of outs) { const od = who === 'papa' || who === 'abuelo' ? 0 : d, ox = (who === 'papa' && x === 154) || (who === 'luis' && x === 166) || (who === 'abuelo' && x === 214) ? OLDX[x] : x; mv('*', src, to, 'whoever stands outside the window: feet at PA (the old PATIO' + (od ? (od > 0 ? ' + ' : ' - ') + Math.abs(od) : '') + ') at the old x, so that their head and shoulders show through the window as in the old picture' + (ox !== x ? '; ' + (who === 'papa' ? 'papá 4 px left of the old (154 for 158)' : who === 'abuelo' ? 'abuelo 7 px right of the old (214 for 207)' : 'Luis 7 px left of the old (166 for 173)') + ', so that the hint hand at the right answer card (over the window, its glow inside the view) stays off their faces' : '') + (who === 'papa' ? '; papá 4 rows lower (PA + 4), so that the hint frames of the answer cards stay off his head' : who === 'abuelo' ? '; abuelo 1 row higher (PA - 1), so that the hint frames of the tray\'s things stay off his face' : ''), [[who, [ox, OLD.PATIO + od], [x, PA(x) + d]]]); }
  // things on the counter: on its top (CT) at the old x
  const ctThings = [['{id:"red",k:"red",v:4,x:142,y:ENC+10,', 142, 'red'], ['{id:"jarra",k:"jarra",v:3,x:156,y:ENC+10,', 156, 'jarra'], ['{id:"v_rojo",k:"vaso",v:"rojo",x:170,y:ENC+10,', 170, 'v_rojo'], ['{id:"v_azul",k:"vaso",v:"azul",x:180,y:ENC+10,', 180, 'v_azul'],
    ['{id:"v_verde",k:"vaso",v:"verde",x:191,y:ENC+10,', 191, 'v_verde'], ['{id:"v_amarillo",k:"vaso",v:"amarillo",x:201,y:ENC+10,', 201, 'v_amarillo']];
  for (const [src, x, who] of ctThings) mv('inicio32', src, src.replace('y:ENC+10,', 'y:' + ctS(x) + ','), 'acts.inicio32: on the counter (CT) at the old x', [[who, [x, OLD.ENC + 10], [x, CT(x)]]]);
  mv('inicio30', 'W.cosas.push({id:"sobra",k,v,x:176+W.sobras*14,y:ENC+10,z:300});', 'W.cosas.push({id:"sobra",k,v,x:176+W.sobras*14,y:CT(176+W.sobras*14),z:120});', 'acts.mandado: what is left on the counter (CT), in the sorted list before whoever stands before the counter (z 120: the old 300 drew it over their heads, the new counter stands behind them)');
  mv('inicio31', '{k:"bandeja",x:196,y:ENC+11,z:99}', '{k:"bandeja",x:196,y:' + ctS(196) + '+1,z:99}', 'acts.inicio31: the tray on the counter (CT + 1)', [['bandeja', [196, OLD.ENC + 11], [196, CT(196) + 1]]]);
  mv('*', 'W.cosas.push({id:"t_pan",k:"panecillo",x:xs.pan,y:ENC+9,z:300,', 'W.cosas.push({id:"t_pan",k:"panecillo",x:xs.pan,y:CT(xs.pan)-1,z:120,', 'acts.lote: the roll on the tray (CT - 1), in the sorted list before whoever stands before the counter (z 120: the old 300 drew it over their heads)');
  mv('*', 'W.cosas.push({id:"t_fruta",k:"platofruta",x:xs.fruta,y:ENC+10,z:300,', 'W.cosas.push({id:"t_fruta",k:"platofruta",x:xs.fruta,y:CT(xs.fruta),z:120,', 'acts.lote: the plate of fruit on the tray (CT), before whoever stands before the counter (z 120)');
  mv('inicio32', '{id:"pan32",k:"platopan",v:2,x:160,y:SILL,', '{id:"pan32",k:"platopan",v:2,x:160,y:SL(160),', 'acts.inicio32: the plate of bread on the sill (SL)', [['pan32', [160, OLD.SILL], [160, SL(160)]]]);
  mv('inicio32', '{id:"mant",k:"mantequilla",v:3,x:178,y:SILL,', '{id:"mant",k:"mantequilla",v:3,x:178,y:SL(178),', 'acts.inicio32: the butter on the sill (SL)', [['mant', [178, OLD.SILL], [178, SL(178)]]]);
  mv('inicio32', '{id:"c1",k:"claro",v:0,x:76,y:NEV[1],z:90},{id:"c2",k:"claro",v:0,x:88,y:NEV[1],z:90}', '{id:"c1",k:"claro",v:0,x:' + C1[0] + ',y:' + C1[1] + ',z:90},{id:"c2",k:"claro",v:0,x:' + C2[0] + ',y:' + C2[1] + ',z:90}', 'acts.inicio32: the two clear glasses on the fridge\'s top (the old top at row 40): the middle of the new top at their columns', [['c1', [76, 40], C1], ['c2', [88, 40], C2]]);
  mv('*', 'if(v.vis===0||v.y<ENC)await vuela({k:"vaso",v:v.v},EN.pila[0],ENC+2,X0[id],ENC+6,5);v.vis=1;v.x=X0[id];v.y=ENC+10;', 'if(v.vis===0||v.y<CT(v.x)-6)await vuela({k:"vaso",v:v.v},EN.pila[0],CT(EN.pila[0])-8,X0[id],CT(X0[id])-4,5);v.vis=1;v.x=X0[id];v.y=CT(v.x);', 'acts.exprime: a cup not on the counter (on the sill: SL, over CT - 6) comes from the sink to its place on the counter (CT)');
  mv('*', '[0.35,0.7].forEach(t=>W.cosas.push({k:"gotaj",x:v.x+14,y:R(v.y+5+(y2-v.y-10)*t),z:500}));', '[0.35,0.7].forEach(t=>W.cosas.push({k:"gotaj",x:v.x+14,y:R(v.y+5+(y2-v.y-10)*t),z:150}));', 'acts.vierte: the drops of juice running down the counter\'s front are drawn before whoever stands at the counter (z 150: the old 500 drew them over everyone; the new counter\'s right end is lower, and a drop fell on Carmen\'s face)');
  mv('*', 'alta=v.y<ENC;', 'alta=v.y<CT(v.x)-6;', 'acts.vierte: a cup on the sill stands higher than the counter (SL, over CT - 6)');
  mv('*', 'const y2=alta?ENC+11:PISO+16;', 'const y2=alta?CT(v.x+8)+1:CB(v.x+8);', 'acts.vierte: the juice runs down onto the counter (CT + 1) from the sill, or onto the floor just before the counter\'s foot (CB) from the counter');
  mv('*', 'vv.x=191;va.x=201;vv.y=va.y=ENC+10;', 'vv.x=191;va.x=201;vv.y=CT(191);va.y=CT(201);', 'acts.ninos32: the children set their cups down on the counter (CT)');
  mv('*', 'const x1=v===vr?190:203;if(v.y>SILL)await vuela({k:"vaso",v:v.v},v.x,v.y-4,x1,SILL-2,6);v.x=x1;v.y=SILL;', 'const x1=v===vr?187:199;if(v.y>SL(v.x)+6)await vuela({k:"vaso",v:v.v},v.x,v.y-4,x1,SL(x1)-2,6);v.x=x1;v.y=SL(x1);', 'acts.mama32: mamá sets the two cups on the sill (SL); the red one at 187 and the blue one at 199 (the old 190 and 203), so that the blue one\'s hint frame is inside the view and the two stand apart', [['v_rojo', [190, 98], [187, SL(187)]], ['v_azul', [203, 98], [199, SL(199)]]]);
  mv('*', 'if(vr.y>SILL){for(const v of [vr,vz])await vuela({k:"vaso",v:v.v},v.x,v.y-4,m.x-8,SILL-6,5);}', 'if(vr.y>SL(vr.x)+6){for(const v of [vr,vz])await vuela({k:"vaso",v:v.v},v.x,v.y-4,m.x-8,SL(m.x-8)-6,5);}', 'acts.mama32: mamá takes the cups from the counter over the sill');
  mv('*', 'const vv={k:"vaso",v:v.v,x:EN.pila[0]+8,y:ENC+2,rot:-1.9};', 'const vv={k:"vaso",v:v.v,x:EN.pila[0]+8,y:CT(EN.pila[0]+8)-8,rot:-1.9};', 'acts.lleva32: the cup tipped over the sink (CT - 8)');
  mv('*', 'const g={k:"gotaj",x:EN.pila[0]+1,y:ENC+2+i};', 'const g={k:"gotaj",x:EN.pila[0]+1,y:CT(EN.pila[0]+1)-8+i};', 'acts.lleva32: the drops into the sink');
  mv('*', 'c1.x=132;c2.x=143;c1.y=c2.y=ENC+10;', 'c1.x=132;c2.x=143;c1.y=CT(132);c2.y=CT(143);', 'acts.final32: the two clear glasses on the counter (CT)');
  mv('*', 'v.x=W.perdio==="v_verde"?191:201;v.y=ENC+10;', 'v.x=W.perdio==="v_verde"?191:201;v.y=CT(v.x);', 'acts.final32: the cup back on the counter (CT)');
  mv('*', 'alMuro({k:it.k,v:it.viejo?"manchas":null},it.x,SILL-8,!it.viejo)', 'alMuro({k:it.k,v:it.viejo?"manchas":null},it.x,SL(it.x)-8,!it.viejo)', 'acts.abuelo31 tira: from the sill (SL)');
  return M;
}

/* ---------- the sheet ---------- */
const DROPS = () => [
  ['c.drawImage(spr("nevera",fondo),0,0);', 'the background (fondo): the set, for setKey(W)'],
  ['fr(c,VEN[0]-2,VEN[1]-2,VEN[2]+4,2,Wd[1]);fr(c,VEN[0]-2,VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]+VEN[2],VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]-3,VEN[1]-3,VEN[2]+6,1,OUT);fr(c,VEN[0]-3,VEN[1]-2,1,VEN[3]+2,OUT);fr(c,VEN[0]+VEN[2]+2,VEN[1]-2,1,VEN[3]+2,OUT);', 'the window\'s frame: the set\'s (the kit\'s window, with depth)'],
  ['fr(c,VEN[0]-6,SILL-1,VEN[2]+12,1,OUT);fr(c,VEN[0]-5,SILL,VEN[2]+10,4,"#F2F2F8");fr(c,VEN[0]-5,SILL+3,VEN[2]+10,1,"#B8B8C8");fr(c,VEN[0]-6,SILL+4,VEN[2]+12,1,OUT);fr(c,VEN[0]-6,SILL,1,4,OUT);fr(c,VEN[0]+VEN[2]+5,SILL,1,4,OUT);', 'the sill: the set\'s'],
  ['fr(c,x+3,y+18,w-6,h-22,"#EAF6FA");fr(c,x+3,y+18,w-6,2,"#B8D8E4");[80,106].forEach(sy=>{fr(c,x+3,sy,w-6,2,"#8AB4C8");});fr(c,x+5,112,w-10,38,"#D6ECF2");fr(c,x+5,112,w-10,1,"#8AB4C8");fr(c,x+5,149,w-10,1,"#8AB4C8");', 'the open fridge\'s inside, shelves and bin: the set\'s (setKey nev 1)'],
  ['fr(c,x-14,y+15,14,h-15,OUT);fr(c,x-13,y+16,12,h-17,"#C8CCDA");fr(c,x-13,y+16,2,h-17,"#E8EAF2");[72,104,136].forEach(sy=>{fr(c,x-11,sy,9,2,"#8A8EA0");});', 'the open door: the set\'s'],
  ['fr(c,x+3,110,w-6,42,OUT);fr(c,x+4,111,w-8,40,"#EAF6FA");', 'the drawer pulled out: the set\'s (setKey cajon 2)'],
  ['else if(N.cajon){fr(c,x+5,112,w-10,38,"#F2F4FA");fr(c,x+5,112,w-10,1,"#8A8EA0");fr(c,x+5,149,w-10,1,"#8A8EA0");fr(c,x+20,118,16,3,"#8A8EA0");}', 'the drawer shut: the set\'s (setKey cajon 1)'],
  ['else{const ww=N.abierta===2?w-16:w-4;if(N.abierta===2){fr(c,x+w-14,y+17,12,h-19,"#3A4A5A");fr(c,x+w-14,y+17,3,h-19,"#EAF6FA");}fr(c,x+2,y+17,ww,h-19,"#F2F4FA");fr(c,x+2,y+17,ww,1,"#8A8EA0");fr(c,x+2,y+17,2,h-19,"#FFFFFF");fr(c,x+ww+1,y+17,1,h-19,"#8A8EA0");fr(c,x+ww-7,y+46,3,30,"#8A8EA0");fr(c,x+ww-6,y+46,1,30,"#C8CCDA");}', 'the shut and the half shut door: the set\'s (setKey nev 0, 2)'],
  ['if(W.pila){fr(c,EN.pila[0]-10,ENC+3,20,6,W.pila==="j"?"#F0A040":"#DCEEF8");fr(c,EN.pila[0]-10,ENC+3,20,1,W.pila==="j"?"#C06008":"#9CC0D8");[[-7,5],[-2,4],[4,5],[7,4]].forEach(q=>fr(c,EN.pila[0]+q[0],ENC+q[1],2,2,"#FFFFFF"));}', 'the water in the sink: the set\'s (setKey pila a, j)'],
  ['if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});', 'the stool: the set\'s (setKey banco), whose top the frog stands on'],
].map(([src, why]) => ({ line: lineOf(src), src, to: '', why }));

function make(G, runs) {
  const E = engine(G), F = G.F;
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 - x0 + 1, y1 - y0 + 1]; };
  const C = design(G, E);
  /* things: the 26 touch keys. Set things: the fridge (every pixel of it in every state: body, door, inside, drawer), its inside (frutas: open)
     and the room (cocina); the others are the sprite layer's, their boxes relative to them as the old */
  const fridgePx = [], insidePx = [];
  for (const k of ALL_STATES) for (const [p, list] of Object.entries(G.parts[k])) { if (/^nevera/.test(p)) for (const i of list) fridgePx.push(i); if (p === 'nevera.dentro') for (const i of list) insidePx.push(i); }
  const NEVERA = pxBox(fridgePx), FRUTAS = pxBox(insidePx);
  // the boxes by state: the fridge shut (0), open (1), half open (2); its inside with the drawer pulled out (1) or not (0)
  const byState = (f, parts) => { const px = []; for (const k of ALL_STATES) if (f(k)) for (const [p, list] of Object.entries(G.parts[k])) if (parts(p)) px.push(...list); return pxBox(px); };
  const NEVERA_BY = [0, 1, 2].map(n => byState(k => k.startsWith(n + '.'), p => /^nevera/.test(p)));
  const FRUTAS_BY = [0, 1].map(c => byState(k => k.startsWith('1.') && (c ? k.startsWith('1.2') : !k.startsWith('1.2')), p => p === 'nevera.dentro'));
  C.NEVERA = NEVERA; C.FRUTAS = FRUTAS;
  const MOVES = designMoves(C, G, E);
  MOVES[0].to = MOVES[0].to.replace(/;$/, ',NEVERA=' + JSON.stringify(NEVERA_BY) + ',FRUTAS=' + JSON.stringify(FRUTAS_BY) + ';');
  for (const m of MOVES) { m.line = lineOf(m.src); m.lines = linesOf(m.src); }
  const DROPPED = DROPS();
  const inView = b => { const x0 = Math.max(b[0], VX0 + 14), y0 = Math.max(b[1], 14), x1 = Math.min(b[0] + b[2], VX0 + 196 - 14), y1 = Math.min(b[1] + b[3], 216 - 14); return [x0, y0, x1 - x0, y1 - y0]; };
  const sprite = why => ({ sprite: true, why });
  const things = {
    luis: sprite('a person (today\'s sprite, drawn 1:1). caja(id) (nevera.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)] relative to where they stand; outside the window: the window\'s glass at their x (moves)'),
    carmen: sprite('as luis'), abuelo: sprite('as luis'), mama: sprite('as luis'), papa: sprite('as luis'), abuela: sprite('as luis'),
    leche: sprite('a thing in the open fridge (enNevera): [HUECO[i] - (13, 23), 26, 26] relative to its place on its shelf (HUECO: moves)'), queso: sprite('as leche'), mantequilla: sprite('as leche'),
    red: sprite('a thing in W.cosas with no name of its own (sinNombre): [x - 9, y - 19, 18, 23] relative to it'), mant: sprite('as red'), jarra: sprite('as red'),
    v_verde: sprite('a cup in W.cosas (porId): [x - 9, y - 19, 18, 23] relative to it'), v_amarillo: sprite('as v_verde'), v_rojo: sprite('as v_verde'), v_azul: sprite('as v_verde'), t_pan: sprite('as v_verde'), t_fruta: sprite('as v_verde'),
    cesta: sprite('the basket of rolls on the fridge\'s top (W.cesta): [EN.cesta - (18, 16), 36, 18] relative to it (EN.cesta: moves)'),
    pan: sprite('the loaf on the counter (W.mos, used by no story): relative to EN.pan (on CT)'), guineo: sprite('the fruit bowl\'s (W.mos, used by no story): relative to EN.frutero'), manzana: sprite('as guineo'), china: sprite('as guineo'),
    frutas: { set: true, box: FRUTAS, boxes: FRUTAS_BY, boxesWhat: 'its box by W.nev.cajonver: [0] the drawer in, [1] the drawer pulled out (the box the port uses: FRUTAS[cajonver ? 1 : 0])', what: 'the inside of the open fridge: its back, sides, shelves and bin (every state with nev 1)', old: { box: OLDBOX.frutas } },
    nevera: { set: true, box: NEVERA, boxes: NEVERA_BY, boxesWhat: 'its box by W.nev.abierta: [0] shut, [1] open, [2] half open (the box the port uses: NEVERA[abierta]); box: all three together', what: 'the fridge: its body, its door shut, half open or open, its inside and the drawer pulled out (every state)', old: { box: OLDBOX.nevera } },
    cocina: { set: true, ground: true, box: OLDBOX.cocina.slice(), what: 'the kitchen: the floor, the walls, the counter, the window; last in the hit order', old: { box: OLDBOX.cocina } },
  };
  for (const k of ['nevera', 'frutas', 'cocina']) { const b = things[k].box, h = inView(b); things[k].hand = [R(h[0] + h[2] / 2), R(h[1] + h[3] / 2)]; if (JSON.stringify(h) !== JSON.stringify(b)) { things[k].hintBox = h; things[k].hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches'; }
    if (things[k].boxes) { things[k].hintBoxes = things[k].boxes.map(inView); things[k].hands = things[k].hintBoxes.map(h => [R(h[0] + h[2] / 2), R(h[1] + h[3] / 2)]); } }

  /* spots */
  const SPOTS = {};
  const floorW = (sx, sy) => W4(E.atZ(sx, sy, 0)), onZ = (sx, sy, z) => W4(E.atZ(sx, sy, z));
  for (const [k, v] of Object.entries(OLD.LUGAR)) SPOTS['frog.' + k] = { world: null, on: 'stool', old: v.slice(0, 2), new: v.slice(0, 2), scale: 1, what: 'LUGAR.' + k + ': the frog on the stool (BANCO), his feet on its top' };
  SPOTS['frog.inicio'].world = onZ(OLD.LUGAR.inicio[0] + 16, OLD.LUGAR.inicio[1] + 25, F.STOOL.h); SPOTS['frog.centro'].world = SPOTS['frog.inicio'].world.slice();
  for (const m of MOVES) for (const q of m.pts || []) { const [who, o, n] = q, k = who + '.' + o.join(','), z = who === 'nevera' ? (o[1] === 79 ? F.FR.shelves[0] : F.FR.shelves[1]) : who === 'cq' ? F.CZ : /^(cesta|c1|c2)$/.test(who) ? F.FR.h : /^(pan32|mant)$/.test(who) ? F.WIN.z0 - .1 : /^(red|jarra|v_|bandeja)/.test(who) ? F.CZ : who === 'cajon' ? F.FR.bin[0] + .06 : 0;
    const out = ['papa', 'luis', 'abuelo', 'mama'].includes(who); q.push(out ? null : onZ(n[0] + (who === 'cq' ? 16 : 0), n[1] - 1 + (who === 'cq' ? 27 : 0), z));
    SPOTS[k] = { world: out ? null : q[3], on: out ? 'outside' : who === 'nevera' ? 'shelf' : who === 'cq' || /^(red|jarra|v_|bandeja)/.test(who) ? 'counter' : /^(cesta|c1|c2)$/.test(who) ? 'fridge top' : /^(pan32|mant)$/.test(who) ? 'sill' : who === 'cajon' ? 'drawer' : 'floor', old: o, new: n, moved: true, what: m.why.split(':')[0] }; }
  SPOTS['nevera.abuela'] = { world: floorW(94, 173), on: 'floor', old: [94, 174], new: [94, 174], what: 'abuela at the fridge (mira30, cajon31, lote, sostienen, lotes31, final32): the floor rule, before its open door; her head under the lower shelf\'s things' };
  SPOTS['nevera.luis'] = { world: floorW(98, 169), on: 'floor', old: [98, 170], new: [98, 170], what: 'Luis at the fridge (mandado): the floor rule' };

  /* the named points of the set */
  const P = (x, y, z = 0) => { const p = E.project(x, y, z); return [r2(p.sx), r2(p.sy)]; };
  const PTS = {
    rincon: { world: [0, 0, 0], screen: P(0, 0, 0), what: 'the corner of the two standing walls (the kit\'s plan): the back wall runs right on y = 0, the left wall left on x = 0' },
    mostrador: { world: [0, 0, 0, F.CA1, F.CD, F.CZ], rows: { CT: C.ct, CB: C.cb }, what: 'the counter along the back wall from the corner, its top at z ' + F.CZ + ' (the kit\'s): a thing on it stands at row CT(x) = ' + C.ct + ' + x / 2 (its top\'s middle, d .45)' },
    pila: { world: W4([F.SINK.a0, F.SINK.d0, F.CZ, F.SINK.a1, F.SINK.d1, F.CZ]), screen: P((F.SINK.a0 + F.SINK.a1) / 2, (F.SINK.d0 + F.SINK.d1) / 2, F.CZ), what: 'the sink set into the counter near the corner (the old EN.pila 124), its tap at the wall behind it' },
    ventana: { world: W4([F.WIN.a0, 0, F.WIN.z0, F.WIN.a1, 0, F.WIN.z1]), rows: { SL: C.sl, VT: C.vt, VB: C.vb, MU: C.mu, PA: C.pa }, what: 'the big window on the back wall over the counter (the kit\'s, view "patio"), from x ' + F.WIN.a0 + ' to ' + F.WIN.a1 + ' (the old 150 to 214), z ' + F.WIN.z0 + ' to ' + F.WIN.z1 + '; its sill (the kit\'s ledge) at z ' + r4(F.WIN.z0 - .1) + ': SL(x) = ' + C.sl + ' + x / 2; the yard wall\'s top seen through it MU(x) = ' + C.mu + ' + x / 2; whoever stands outside has their feet at PA(x) = ' + C.pa + ' + x / 2' },
    nevera: { world: W4([0, F.FR.a0, 0, F.FR.d, F.FR.a1, F.FR.h]), shelves: F.FR.shelves, bin: F.FR.bin, huecos: C.HUECO, drawer: C.DR, top: { cesta: C.CES, c1: C.C1, c2: C.C2 }, what: 'the fridge against the left wall from y ' + F.FR.a0 + ' to ' + F.FR.a1 + ', ' + F.FR.d + ' deep, ' + F.FR.h + ' high, its front looking +x; its door hinged on its far edge (y ' + F.FR.a1 + ': the left on the screen); two glass shelves at z ' + F.FR.shelves.join(' and ') + ', the bin under them (z ' + F.FR.bin.join(' to ') + ')' },
    banco: { foot: P(F.STOOL_AT[0], F.STOOL_AT[1], 0), top: [F.STOOL.sx, F.STOOL.sy], height: F.STOOL.h, what: 'the stool where the frog stands (BANCO, unchanged): its top\'s middle at (' + F.STOOL.sx + ', ' + F.STOOL.sy + '), the frog\'s feet' },
    corazon: { screen: [124, 24], what: 'heartAt: unchanged (in the dark over the walls)' },
  };

  /* views */
  const views = { wide: { zoom: 1, x0: VX0, world: floorW(VX0 + 98, 150), region: null, old: [22, 0, 196, 216], why: 'the old window moved 6 px right (x0 28 for 22): so that the hint frame of every thing on the counter\'s right end (the cups at 201) is inside the view, and the fridge\'s side runs off the left edge', what: 'the kitchen\'s corner: the fridge at the left, the counter with the sink and the window at the right, the stool in front' } };

  /* the review and level pictures */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1 ? [Math.max(0, Math.min(44, R(cx - 98))), Math.max(0, Math.min(112, R(cy - 52))), 196, 104] : [Math.max(0, Math.min(142, R(cx - 49))), Math.max(0, Math.min(164, R(cy - 26))), 98, 52]; return { screen: [cx, cy], zoom, crop, what }; };
  const PICS = DESIGN_PICS(pic, C);
  const LEVEL = PAIRS.level.flatMap(L => L.pictures.map((p, i) => p.scene === 'nevera' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* remap: every distinct position of positions.json, and of h-nevera (newer than the reference folder: its set steps' positions) */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const extra = hNeveraPositions();
  const remap = POS.positions.concat(extra).map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.extra) e.from = 'h-nevera (not in positions.json: newer than the reference folder)';
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
      const ats = p.uses.map(u => u.at), isCosa = ats.every(a => /cosas\.\d+$/.test(a)), isOut = ats.every(a => /gente\.\w+$/.test(a)) && p.y < 140;
      let at = [p.x, p.y], on = 'floor', z = 0;
      if (isCosa && p.y >= 110 && p.y <= 130) { const nx = p.extra ? ({ 182: 180, 194: 190, 206: 201 }[p.x] || p.x) : p.x; at = [nx, C.CT(nx) + p.y - (OLD.ENC + 10)]; on = 'counter'; z = F.CZ; }
      else if (isCosa && p.y >= 94 && p.y <= 102) { at = [p.x, C.SL(p.x) + p.y - OLD.SILL]; on = 'sill'; z = F.WIN.z0 - .1; }
      else if (isOut) { at = [p.x, C.PA(p.x) + p.y - OLD.PATIO]; on = 'outside'; }
      e.to = { [on]: on === 'outside' ? null : W4(E.atZ(at[0], at[1] - 1, z)) }; e.new = at; if (at[1] !== p.y || at[0] !== p.x) { e.moved = true; e.why = on === 'counter' ? 'on the counter: its row CT(x) + (y - ' + (OLD.ENC + 10) + ')' + (at[0] !== p.x ? '; three of the row of cups 2 to 5 px left (180, 190, 201 for 182, 194, 206; 170 stays), so that the last one\'s hint frame is inside the view and each stands apart' : '') : on === 'sill' ? 'on the sill: SL(x) + (y - ' + OLD.SILL + ')' : 'outside the window: PA(x) + (y - ' + OLD.PATIO + ')'; }
      e.what = on === 'floor' ? 'a place (x, y): the floor under (x, y - 1); the same screen place' : 'a place ' + on + (e.moved ? ' (moved: why)' : '');
    }
    return e;
  });

  const setKey = {
    params: { nev: 'W.nev.abierta: 0 shut, 1 open, 2 half open', cajon: 'open only: W.nev.cajonver ? 2 : W.nev.cajon ? 1 : 0 (the drawer pulled out, shut, none)', pila: 'W.pila: "0", "a" (dishwater), "j" (juice)', banco: 'W.banco ? 1 : 0 (the stool)' },
    key: 'nev + "." + cajon + "." + pila + "." + banco',
    baked: [], notReached: [],
    bakedWhy: 'order 06 found 87 states made by ten set keys (banco, canasta, cesta, encima, mos, nev, patio, pila, repisa, vista). Four are the set\'s: nev (the fridge shut, open or half open; open, its drawer shut or pulled out: nev.cajon, nev.cajonver), pila (the water in the sink) and banco (the stool: the review pictures have none). The others are things the sprite layer draws, as the old: canasta (the picnic basket and what is in it), cesta (the basket of rolls on the fridge), encima (what the frog carries over his head), mos (the counter\'s bread, fruit bowl, cups and plates: used by no story), nev.h and nev.soporte (what stands in the fridge), patio (the cart, the birds and what lies on the yard wall, seen through the window), repisa (what stands on the sill), vista (the round picture over a cup)',
    spriteKeys: { canasta: 'draw(): the picnic basket on the counter, at CT', cesta: 'nevera(): the basket of rolls on the fridge\'s top (EN.cesta)', encima: 'rana(): what the frog carries', mos: 'draw(): the counter\'s things (no story)', 'nev.h': 'nevera(): the things on the shelves (HUECO)', 'nev.cajon': 'nevera(): the fruit in the drawer pulled out (the drawer itself: setKey cajon)', patio: 'patio(): the cart, the birds, what lies on the yard wall (clips)', repisa: 'patio(): what stands on the sill (SL)', vista: 'draw(): the round picture over a cup' },
  };

  return {
    scene: 'nevera',
    made: 'node docs/proyecto/pixel/nevera-sheet-make.js, from nevera-set.html (window.NEVERA_SET), cocina-kit.js and coqui/ref/escenas/nevera/. Order 39a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its pixels',
      floor: 'the kitchen is built round the old picture: a place on the floor keeps its screen place, its world point the floor under it (z 0): a person\'s (x, y) under (x, y - 1), the frog\'s q under (q.x + 16, q.y + 25). A place on the old level rows of the counter (ENC + k), the sill (SILL), the yard wall (MURO) or outside (PATIO) keeps its x and stands on the new sloping row there (CT, SL, MU, PA: moves); the fridge\'s places (HUECO, the drawer, its top) are the nearest that show whole (moves). The sheet names each (spots, remap, code)',
      relative: 'what the old code draws or moves relative to a person, the frog, a cup or a thing (what is carried, a puddle beside a cup, a drop, a bubble, a cloud) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the stars of the endings, the heart (heartAt), the answer cards (respEn), all in the dark over the walls',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: LAYOUT(F, C),
    behind: { what: 'nothing: the outside seen through the window is the set\'s (the kit\'s backdrop)', items: [] },
    setKey,
    things,
    spots: SPOTS,
    lugar: Object.fromEntries(Object.entries(OLD.LUGAR).map(([k, v]) => [k, { spot: 'frog.' + k, q: v.slice(0, 2), scale: v[2], old: v.slice(0, 2) }])),
    hops: [], hopsAll: [],
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: { patio: { at: 'nevera.js:' + lineOf('function patio(c,a){'), old: [OLD.VEN[0], OLD.VEN[1], OLD.VEN[2], OLD.VEN[3]], thing: 'cocina', face: 'the window on the back wall (part "ventana")', how: 'what patio() draws between its save/clip and restore (the cart, what lies on the yard wall, the birds, whoever stands outside and the hat) is drawn only on the set\'s pixels that show the outside through the window (zone o: the kit\'s backdrop seen through the glass); the window\'s frame and sill (the set\'s) stay over it' } },
    smoothing: 'nevera.js never turns smoothing on (respIcon turns it off)',
    front: FRONTSPEC(),
    shadows: SHADOWSPEC(F),
    helps: { what: 'none: nothing the sprite layer draws needs a help on this set', lines: [] },
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines.length > 1 ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.pts && m.pts.length ? { places: m.pts.map(q => ({ who: q[0], old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    dropped: DROPPED,
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as nevera.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (nevera.js draw: line ' + lineOf('Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a person, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud) and of every face; if none is, the first (the old)',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1',
      faces: 'a person\'s face: [hx - 6, top + 6, 12, 10] (eyes to chin), top the bare sprite\'s first row, hx the middle of its top 10 rows; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      board: BOARD, boardWhat: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta (the rounds card) [2, 2, 68, 26]',
    },
    code: codeEntries(MOVES, DROPPED),
    checks: { notes: [] },
  };
}

// h-nevera (a routine newer than the reference folder): the positions its set steps write (positions.json does not hold them)
function hNeveraPositions() {
  const j = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/h-nevera.json'), 'utf8')), out = new Map();
  const walk = (o, at) => { if (Array.isArray(o)) o.forEach((v, i) => walk(v, at + '.' + i)); else if (o && typeof o === 'object') { if (typeof o.x === 'number' && typeof o.y === 'number' && /\.set\./.test(at)) { const k = o.x + ',' + o.y; if (!out.has(k)) out.set(k, { kind: 'point', x: o.x, y: o.y, uses: [], extra: true }); out.get(k).uses.push({ file: 'cuentos/h-nevera.json', at: at.slice(1) }); } for (const [k, v] of Object.entries(o)) walk(v, at + '.' + k); } };
  walk(j.beats, '.beats');
  return [...out.values()];
}
function DESIGN_PICS(pic, C) {
  return {
    'leche.si': pic(150, 178, 2, 'Carmen drinking a glass of milk'), 'leche.no': pic(150, 178, 2, 'Carmen drinking a glass of juice'),
    'queso.si': pic(168, C.CT(160) - 12, 2, 'a wedge of cheese on a blue dish on the counter'), 'queso.no': pic(168, C.CT(160) - 12, 2, 'butter on its dish on the counter'),
    'no_hay.si': pic(R((C.HUECO[0][0] + C.HUECO[1][0]) / 2), R((C.HUECO[0][1] + C.HUECO[1][1]) / 2) - 8, 2, 'the open fridge: the holder empty, the cheese beside it'), 'no_hay.no': pic(R((C.HUECO[0][0] + C.HUECO[1][0]) / 2), R((C.HUECO[0][1] + C.HUECO[1][1]) / 2) - 8, 2, 'the open fridge: the milk in its holder, no cheese'),
    'busca.si': pic(184, C.PA(184) - 52, 2, 'papá outside the window with a bag, thinking of bread'), 'busca.no': pic(184, C.PA(184) - 52, 2, 'papá outside the window eating a slice'),
    'fruta.si': pic(150, 172, 1, 'abuelo holding up a plate of fruit'), 'fruta.no': pic(150, 172, 1, 'abuelo holding up a plate of rolls'),
    'guineo.si': pic(150, 172, 1, 'mamá with the baby eating a banana'), 'guineo.no': pic(150, 172, 1, 'mamá with the baby eating an apple'),
    'manzana.si': pic(152, 176, 2, 'Luis holding an apple'), 'manzana.no': pic(152, 176, 2, 'Luis holding an orange'),
    'china.si': pic(162, 172, 1, 'abuelo giving Carmen an orange'), 'china.no': pic(162, 172, 1, 'abuelo giving Carmen a banana'),
    'pan.si': pic(166, C.CT(166) - 12, 2, 'a basket of rolls on the counter'), 'pan.no': pic(166, C.CT(166) - 12, 2, 'a pot of rice on the counter'),
    'mantequilla.si': pic(172, 131, 1, 'abuela offering bread being buttered'), 'mantequilla.no': pic(172, 131, 1, 'abuela offering bread with cheese'),
    'lleno.si': pic(152, 176, 2, 'Luis holding a full plate'), 'lleno.no': pic(152, 176, 2, 'Luis holding an empty plate'),
    'vacio.si': pic(150, 172, 1, 'papá holding an empty glass upside down'), 'vacio.no': pic(150, 172, 1, 'papá drinking a full glass of juice'),
  };
}
function LAYOUT(F, C) {
  return {
    what: 'La cocina\'s room (cocina-kit.js), cut open as La sala: of its four walls the two far ones stand (the left one on x = 0, the back one on y = 0), cut at ' + 3.2 + ' with the plain dark backdrop above; the checker floor runs off the picture. Along the back wall from the corner, the counter (the kit\'s cupboards and white top) to past the right edge, the sink set into it near the corner, its tap at the wall; over it the big window (the kit\'s, view "patio": sky and a cloud, the yard\'s cream wall, the hedge), its sill a ledge. Against the left wall, a little way from the corner, the big fridge, its front looking +x, its door hinged on its far edge; the stool on the floor in front, where the frog stands',
    why: 'the brief and page 11 decision 9: the set stands on the world\'s axes, nothing square to the camera; the kit fixes the room\'s plan (the corner at (0, 0), the walls on its axes). The old picture had the fridge, the counter and the window side by side on one flat wall: on a world axis a wall falls half a row a pixel, so the fridge (left of the counter, standing as low as the counter\'s foot) cannot share the counter\'s wall. The fridge stands on the left wall, the counter and the window on the back wall: both feet stay near their old rows where people stand at them, and the counter\'s top passes its old row (122) at x 170, the middle of what stands on it; to either side it falls half a row a pixel (CT: whatever stands on it moves to that row at its old x, as El banco\'s sitters to SY). The fridge is as high as the wall (3.15, a little under its cut at 3.2: 1.4 times abuela, the old one was 2.3 times her); its two shelves hold the four old places side by side as the old, moved down to where they show whole through its opening (HUECO), above the heads of whoever stands before it. The window is as wide as the old one, from the sill just over the counter to just under the wall\'s cut: what happens outside shows through it, the yard wall\'s top on its slope (MU), whoever stands outside with their feet on PA',
    numbers: { CT: C.ct, SL: C.sl, MU: C.mu, PA: C.pa, CB: C.cb, VT: C.vt, VB: C.vb },
  };
}
function FRONTSPEC() {
  return {
    how: 'the old background (fondo: the fridge, the counter, the window) was drawn before everyone, and the stool was in the sorted list; now each is a set thing. Every item the sprite layer draws owns the pixels it drew last; at the entry of each front part (after everyone in the sorted list, and after what nevera() draws in the fridge) the set\'s own pixels of the part are drawn again where they are nearer to the camera than the item that owns the pixel: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the point the item stands on (the floor under (x, y - 1); a thing on the counter, the sill, a shelf or the fridge\'s top: that surface under (x, y - 1) at its height; the frog on the stool: its top). Whoever stands outside the window is clipped to the outside (clips) and nothing is drawn again over them. "Behind a thing" is that depth test, not a row',
    plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
    parts: Object.fromEntries(FRONT.map(p => [p, { sortY: 9999, insert: 'after the sorted list: drawn again where nearer than the owner of the pixel' }])),
    tags: [],
    tagsWhat: 'the port knows each item of the sorted list by its object (gente id, a cosa, the frog); nothing in nevera.js changes for it',
  };
}
function SHADOWSPEC(F) {
  return {
    rule: 'the kitchen\'s one light (cocina-kit.js): from the upper left, shadows to screen right; every shadow cast from the floor point under the screen point of the feet (unproject), darkening only the floor at its own depth. Whoever stands on the stool or the counter, outside the window, or in the fridge casts none (the engine casts only on the floor, and a shadow on the floor under a raised thing would lie apart from it)',
    coqui: { radius: .45, at: 'unproject(b.x + b.w / 2, q.y + 25)', when: 'W.cq.vis and al > .5 and on the floor (not on the stool, not on the counter)', cast: 'castShadow(g.x, g.y, .3, .45)' },
    people: { radius: .32, at: 'unproject(x, y - 1)', when: 'visible (vis !== 0, al > .5), on the floor (not fuera)', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .32) (a child: z to 1.35)' },
    cosas: { radius: .18, at: 'unproject(x, y - 1)', when: 'a thing lying on the floor (its y over the counter\'s foot CB, z 1 or unset), not in the air', cast: 'castShadow(g.x, g.y, .1, .18)' },
    dropped: 'none of the old code\'s own: nevera.js draws no shadow',
  };
}

/* ---------- code: every line of nevera.js that holds a number, and what each number is ----------
   The maker reads nevera.js itself (not order 06's inventory): it finds every numeric literal outside comments and strings, sorts each by what it
   is from where it stands (a place on the picture; an offset from someone; a time, a sound, a count; a draw order; a sprite's or a sign's own
   drawing), and the sheet names, line by line, what becomes of its places (moved, the floor rule, a set thing, dropped). check() fails if a line
   with a place has no entry, or an entry misses one of its place numbers */
const REGIONS = (() => {
  const at = s => lineOf(s), out = [];
  const r = (a, b, kind, why) => out.push({ a, b, kind, why });
  r(at('function fondo(){'), at('function fondo(){') + 17, 'dropped', 'the background (fondo): the set, dropped');
  r(at('const COSA={'), at('const cosa=(k,c)=>') - 1, 'drawing', 'a sprite\'s own drawing (COSA: every thing the scene draws): relative to where it is drawn, unchanged');
  r(at('const cosa=(k,c)=>'), at('function hedor(c,x,y)'), 'drawing', 'tenida and hedor: a thing drawn by its foot, its smell over it: relative, unchanged');
  r(at('function gente(c,id,a){'), at('function bub2(c,k,tx,ty,a)'), 'drawing', 'gente, nube, rana, bub2: a person, what they hold, a thought cloud, the frog, a bubble: relative to them, unchanged');
  r(at('function talkAt(k,W){'), at('const marca=m=>'), 'drawing', 'talkAt, respIcon and the rounds card (hud): relative, or screen space (talk.board): unchanged');
  r(at('async function mueve(id,x,y,n){'), at('async function vuela(o,x0,y0,x1,y1,n){'), 'drawing', 'mueve and vuela: a walk or a throw between two places (the steps, the arc): relative, unchanged');
  r(at('async function stake('), at('const estado=W=>'), 'other', 'stake, poke and estado: no place');
  return out;
})();
const regionOf = L => REGIONS.find(r => L >= r.a && L <= r.b);
const stripLine = l => l.replace(/\/\/.*$/, '').replace(/"(?:[^"\\]|\\.)*"/g, '""');
const numsOf = l => { const out = []; const re = /(?<![\w#.$])(\d+\.\d+|\d+|\.\d+)(?![\w])/g; let m; while ((m = re.exec(l))) out.push({ n: m[1], at: m.index }); return out; };
// what a number is, from the text before and after it (El banco's rule, with nevera.js's names)
function numKind(l, at, n) {
  const before = l.slice(Math.max(0, at - 40), at), after = l.slice(at + n.length, at + n.length + 6);
  if (/(wait|setTimeout)\($/.test(before) || /wait\(\+?\(?[^()]*$/.test(before) && /\)\s*;?$|^\)/.test(after) && /wait\(/.test(before.slice(-12)) || /tone\([^()]*$/.test(before) || /SFX\.\w+\($/.test(before) || /\bms\s*\|\|\s*$/.test(before) || /\(F>>$|F>>$/.test(before) || /\bms:\s*$/.test(before)) return 'time';
  if (/[<>]=?\s*$|===?\s*$|!==?\s*$|%\s*$|Math\.(min|max)\(\s*$|\|\|\s*$|\?\s*$|>>\s*$|<<\s*$|\.length\s*[<>]=?\s*$|\bi<\s*$|\bn\s*$/.test(before)) return 'count';
  if (/\bz:\s*-?$|\.z\s*=\s*$|\bc[12]\.z=c[12]\.z=\s*$/.test(before)) return 'order';
  if (/\b(dy|al|s|v|n|vis|paso|dir|fuera|abierta|soporte|come|bebe|e|rot|cierra|gorro|fijo|bueno|cajonver|guineo|manzana|sobras|pila|carrito|marcas|banco|e)\s*[:=]\s*-?$/.test(before) || /\.dy\s*=\s*-?$|\.v\s*[-+]=\s*$|\.n\s*=\s*$|\.v\s*=\s*$/.test(before)) return 'state';
  if (/Math\.PI\s*[*\/]\s*$|\*\s*$|Math\.sin\([^()]*$|Math\.cos\([^()]*$|Math\.hypot\([^()]*$|\/\s*$/.test(before) || /^\s*\*/.test(after)) return 'scale';
  if (/\b(dx|dy)\s*:\s*-?$/.test(before)) return 'offset';
  if (/\b[xy]\s*:\s*-?$|\b[xy]\s*:\s*\w[\w.\[\]]*\s*[+-]\s*$|\.[xy]\s*=\s*-?$|\.[xy]\s*[+-]=\s*$|\b(fruta|pan|v_rojo|v_azul|v_verde|v_amarillo)\s*:\s*$/.test(before)) return /[+-]\s*$/.test(before) && !/:\s*-$|=\s*-$/.test(before) ? 'offset' : 'place';
  if (/(mueve|ranaA|hopTo|vuela|alMuro)\([^()]*$/.test(before)) return /[+-]\s*$/.test(before) && !/[(,]\s*-$/.test(before) ? 'offset' : 'place';
  if (/\?\s*$|:\s*$/.test(before) && /^\s*[:;,]/.test(after)) return 'place';
  if (/\[\s*-?$|\[\s*\d+\s*,\s*-?$|\],\s*\[\s*-?$|,\s*-?$/.test(before) && /^\s*[,\]]/.test(after)) return 'place';
  if (/[+-]\s*$/.test(before)) return 'offset';
  return 'other';
}
function codeEntries(MOVES, DROPPED) {
  const C = [];
  for (let L = 1; L <= LINES.length; L++) {
    const raw = LINES[L - 1], l = stripLine(raw), ns = numsOf(l); if (!ns.length) continue;
    const reg = regionOf(L), kinds = {}; for (const { n, at } of ns) { const k = reg ? reg.kind : numKind(l, at, n); (kinds[k] = kinds[k] || []).push(n); }
    const mv = MOVES.filter(m => (m.lines || [m.line]).includes(L)), dr = DROPPED.filter(d => d.line === L);
    const e = { line: L, numbers: kinds }, notes = [];
    if (dr.length) notes.push('dropped (the set\'s): ' + dr.map(d => d.why.split(':')[0]).join('; '));
    if (mv.length) notes.push('moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; '));
    if (reg) { e.to = reg.kind === 'dropped' ? { dropped: true } : 'unchanged'; notes.push(reg.why); }
    else if (mv.length) e.to = { moves: [...new Set(mv.map(m => m.src))] };
    else if (dr.length) e.to = { dropped: true };
    else if (kinds.place) e.to = { floor: true };
    else e.to = 'unchanged';
    if (!reg && kinds.place) notes.push('every other place here keeps its screen place: on the floor (rules.floor), or its x on its row (CT, SL, MU, PA)');
    if (!reg && !kinds.place && !mv.length && !dr.length) notes.push('no place: ' + Object.keys(kinds).join(', '));
    e.note = notes.join('; ');
    C.push(e);
  }
  const set = (L, to, note) => { const e = C.find(q => q.line === L); if (!e) throw new Error('code: no numbers on line ' + L); e.to = to; e.note = note; };
  set(lineOf('const PISO=150,ENC=112,'), { moves: [MOVES[0].src], points: ['mostrador', 'ventana', 'nevera', 'banco'] }, 'PISO, ENC, NEV, MOS, VEN, SILL, PATIO, MURO: the old flat picture\'s rows and boxes (the floor\'s top, the counter\'s top, the fridge, the counter, the window, its sill, the yard, its wall): the set\'s (points), and the rows CT, SL, MU, PA, CB, VT added here (moves); BANCO: the stool, unchanged (the set\'s stool stands under it: points.banco)');
  set(lineOf('const HUECO=[[55,79]'), { moves: [MOVES[1].src] }, 'the four places on the fridge\'s shelves: moved (moves)');
  set(lineOf('const EN={pan:'), { moves: [MOVES[2].src] }, 'the counter\'s places on CT, the basket on the fridge\'s top: moved (moves)');
  set(lineOf('const caja=id=>'), { moves: [MOVES.find(m => m.src.startsWith('if(p.fuera)return')).src] }, 'a person\'s box relative to them; outside, the window\'s glass at their x (moves)');
  set(lineOf('const COSAS=Object.keys(QUIEN)'), { moves: MOVES.filter(m => /^\{id:"(frutas|nevera)"/.test(m.src)).map(m => m.src), things: ['cesta', 'frutas'] }, 'the basket\'s box relative to EN.cesta (moved); the fridge\'s inside: the set\'s (things.frutas)');
  set(lineOf('{id:"nevera",box:[NEV[0]'), { things: ['nevera', 'cocina'] }, 'the fridge: the set\'s (things.nevera); the kitchen\'s box: unchanged, its hint box (things.cocina)');
  set(lineOf('const alBanco=()=>'), { spots: ['frog.inicio'] }, 'the frog to the stool: BANCO, unchanged');
  set(lineOf('KIT.escena({id:"nevera"'), { view: 'wide', point: 'corazon', spots: ['frog.inicio', 'frog.centro'] }, 'the view (views.wide), the heart (points.corazon) and the frog\'s places on the stool: unchanged');
  set(lineOf('fresh:()=>({respEn:'), 'unchanged', 'respEn (the answer cards: in the dark over the walls) and the frog\'s first place on the stool: unchanged');
  const p0 = lineOf('async prueba(o){');
  for (let L = p0; L <= p0 + 6; L++) { const e = C.find(q => q.line === L); if (e) { e.to = 'unchanged'; e.note = 'acts.prueba: a test act no story of this scene calls (only la-foto, another scene, names "prueba"): its places unchanged'; } }
  const dl = DROPPED.map(d => d.line); for (const e of C) if (dl.includes(e.line) && e.to === 'unchanged') e.to = { dropped: true };
  C.push({ line: 'juego.js:16', to: 'unchanged', note: 'fresh(): not used here: nevera\'s fresh() puts the frog on the stool' });
  C.push({ line: 'cual.js:21', to: 'unchanged', note: 'panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)' });
  return C;
}

/* ---------- the sheet's rule for a world written in old positions (what nevera-preview.html PREVIEW.remapW does; the port has its moves and
   the story files' remap) ---------- */
function remapW(sh, w0, story) {
  const w = JSON.parse(JSON.stringify(w0)), N = sh.layout.numbers, f = c => x => Math.round(c + x / 2), CT = f(N.CT), SL = f(N.SL), PA = f(N.PA), CB = f(N.CB);
  const ENC = OLD.ENC, top = sh.points.nevera.top, done = new Set();
  // the story file's own positions first (the host passes them through the sheet's remap)
  if (story) for (const e of sh.remap) if (e.moved && e.kind === 'point' && e.uses.some(u => u.startsWith(story + '.json'))) for (const o of (w.cosas || [])) if (o && !done.has(o) && Math.round(o.x) === e.old[0] && Math.round(o.y) === e.old[1]) { o.x = e.new[0]; o.y = e.new[1]; done.add(o); }
  for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.fuera) { p.y = PA(Math.round(p.x)) + (p.y - OLD.PATIO) + 0; const HX = { abuelo: [207, 214, -1], papa: [158, 154, 4], luis: [173, 166, 0] }[id]; if (HX && Math.round(p.x) === HX[0]) { p.x = HX[1]; p.y = PA(HX[1]) + (w0.gente[id].y - OLD.PATIO); } if (HX) p.y += HX[2]; }
  const named = {}; for (const m of sh.moves) for (const q of m.places || []) if (/^(carta_|v_)/.test(q.who)) named[q.who + '@' + q.old.join(',')] = q.new;
  for (const m of sh.moves) for (const q of m.places || []) if (q.who === 'abuela') { const p = (w.gente || {}).abuela; if (p && Math.round(p.x) === q.old[0] && Math.round(p.y) === q.old[1]) { p.x = q.new[0]; p.y = q.new[1]; } }
  for (const o of w.cosas || []) { if (!o || o.x == null || done.has(o)) continue; const x = Math.round(o.x), nm = named[o.id + '@' + Math.round(o.x) + ',' + Math.round(o.y)]; if (nm) { o.x = nm[0]; o.y = nm[1]; continue; }
    if (o.id === 'c1' && o.y === 40) { o.x = top.c1[0]; o.y = top.c1[1]; continue; }
    if (o.id === 'c2' && o.y === 40) { o.x = top.c2[0]; o.y = top.c2[1]; continue; }
    if (o.z === 50 || o.z === 399 || o.z === 400) continue;                                    // the cards on the wall; what lies by the frog
    if (o.z === 1 && o.y === OLD.PISO + 16) { o.y = CB(x); continue; }                         // a puddle on the floor at the counter's foot
    if (o.y >= OLD.SILL - 4 && o.y <= OLD.SILL + 4 && (o.z === 90 || o.z === 100)) { o.y = SL(x) + (o.y - OLD.SILL); continue; }
    if (o.y >= ENC + 2 && o.y <= ENC + 20 && o.z != null && o.z >= 90 && o.z <= 500) { o.y = CT(x) + (o.y - (ENC + 10)); continue; } }
  if (w.olfato && w.olfato.y === ENC + 13) w.olfato.y = CT(Math.round(w.olfato.x)) + 3;
  if (w.cq && w.cq.vis && w.cq.y === ENC + 9 - 27) w.cq.y = CT(w.cq.x + 16) - 1 - 27;
  if (w.respEn && w.respEn[0] === 142 && w.respEn[1] === 10) w.respEn = sh.moves.find(m => m.src.startsWith('fresh:()=>({respEn:')).places[0].new.slice();
  return w;
}
const placesOf = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)];
  if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y]; (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0 && c.x != null) o['cosa.' + (c.id || c.k + i)] = [R(c.x), R(c.y)]; }); return o; };

/* ---------- the plane a thing stands in (front.how) ----------
   On the floor and on the stool, a free thing: the vertical plane facing the camera through its foot (v = (x + y) / R2: depth v / COS - (row + .5
   - OY) tan 30 / S). On the counter, the sill or the tile band: the plane parallel to the back wall through its foot (y = d); in the fridge, on its
   top or in its drawer: parallel to the left wall (x = d): a thing along a wall is drawn as wide as its sprite along that wall */
function planeDepth(E, pl, ix, iy) {
  if (pl.v != null) return pl.v / E.COS - (iy + .5 - E.OY) * Math.tan(Math.PI / 6) / E.S;
  const u = (ix + .5 - E.OX) / E.S, k = (iy + .5 - E.OY) / E.S, x = pl.face === 'y' ? pl.at + u * E.R2 : pl.at, y = pl.face === 'y' ? pl.at : pl.at - u * E.R2, v = (x + y) / E.R2, z = (v * E.SIN - k) / E.COS;
  return v * E.COS + z * E.SIN;
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([R(hp[0]) - 12 + i * 3, R(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };
const handRects = hp => { const out = []; for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.') out.push([R(hp[0]) - 12 + i * 3, R(hp[1]) + j * 3 + o, 3, 3]); return out; };
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const frogBox = q => { const w = R(30 * q.s) + 2, h = R(25 * q.s) + 2; return { x: R(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));
const lum = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }; return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2]); };
const wcag = (a, b) => { const la = lum(a), lb = lum(b); return (Math.max(la, lb) + .05) / (Math.min(la, lb) + .05); };
const hopsOf = d => [d < 3 ? 0 : Math.max(1, Math.min(3, R(d / 40))), d < 3 ? 0 : Math.max(1, Math.min(4, R(d / 30)))];   // nevera.js ranaA (40 px a hop) and kit.js ir (30)
const QUIEN_NINO = { luis: 1, carmen: 1 };
const altoOf = id => id === 'abuela' ? 51 : QUIEN_NINO[id] ? 44 : 56;

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M, MASK = G.MASK, NEW = G.TICKS;
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];
  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const T of NEW) { for (const t of T.ticks) reached.add(keyOf(t.W)); for (const L of T.states) reached.add(keyOf(L.W)); } for (const ps of pairSidesOf()) reached.add(keyOf(pairW(ps, sh)));
    sh.setKey.baked = ALL_STATES.filter(k => reached.has(k)).map(k => ({ key: k, query: '?' + queryOf(k) })); sh.setKey.notReached = ALL_STATES.filter(k => !reached.has(k)); }
  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  const nExtra = sh.remap.filter(e => e.from).length;
  if (sh.remap.length - nExtra !== pos.positions.length) P.push('remap has ' + (sh.remap.length - nExtra) + ' entries of positions.json, it holds ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-nevera.json'), 'utf8')), pairSides = pairSidesOf();
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of PAIRS.level) for (const p of L.pictures) if (p.scene === 'nevera') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  /* code: nevera.js read here, line by line */
  { const byLine = new Map(sh.code.map(e => [String(e.line), e])); let nPlace = 0, nLines = 0, nNot = 0; const notPlaces = {};
    for (let L = 1; L <= LINES.length; L++) { const l = stripLine(LINES[L - 1]), ns = numsOf(l); if (!ns.length) continue; nLines++; const e = byLine.get(String(L));
      if (!e) { P.push('code: nevera.js line ' + L + ' holds numbers (' + ns.map(n => n.n).join(', ') + ') and has no entry'); continue; }
      const reg = regionOf(L);
      for (const { n, at } of ns) { const k = reg ? reg.kind : numKind(l, at, n); if (k === 'place') { nPlace++; if (!(e.numbers.place || []).includes(n)) P.push('code: nevera.js:' + L + ' the place number ' + n + ' is not named in its entry'); if (e.to === 'unchanged' && !/prueba|respEn/.test(e.note)) P.push('code: nevera.js:' + L + ' has places but its entry says only "unchanged"'); } else { nNot++; notPlaces[k] = (notPlaces[k] || 0) + 1; } } }
    for (const m of sh.moves) { for (const L of m.lines || [m.line]) if (!LINES[L - 1].includes(m.src)) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); }
    for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
    notes.push('code: nevera.js read here: ' + nLines + ' lines hold numbers, every one with its entry; ' + nPlace + ' numbers are places on the picture, each named in its line\'s entry with what becomes of it (moved, the floor rule, a set thing, dropped); ' + nNot + ' are not places (' + Object.entries(notPlaces).map(([k, n]) => k + ' ' + n).join(', ') + ')'); }
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + (sh.remap.length - nExtra) + ' positions (old ' + pos.positions.length + ') and ' + nExtra + ' of h-nevera (newer than the reference folder), ' + cual.items.length + ' review pairs of cual-nevera (' + pairSides.length + ' pictures), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + sh.setKey.baked.length + ' baked states reached (the old ' + inv.states.count + ')');

  /* hops: the frog's walks, recorded and the port's, step by step: each walk takes the old number of hops (nevera.js ranaA, kit.js ir) */
  { const all = new Map(); let nW = 0;
    runs.forEach((r, ri) => { const o = r.lines, n = NEW[ri].states; for (let i = 1; i < o.length; i++) { const a = o[i - 1].W.cq, b = o[i].W.cq; if (!a || !b || !a.vis || !b.vis) continue;
        const twin = n.findIndex(L => L.path === o[i].path && L.kind === o[i].kind); if (twin < 1) continue; const a2 = n[twin - 1].W.cq, b2 = n[twin].W.cq; if (!a2 || !b2) continue;
        const dO = Math.hypot(a.x - b.x, a.y - b.y), dN = Math.hypot(a2.x - b2.x, a2.y - b2.y); if (dO < 3 && dN < 3) continue; nW++;
        const stp = (() => { try { return o[i].path.split('.').reduce((q, k) => q == null ? q : q[/^\d+$/.test(k) ? +k : k], r.story); } catch (e) { return null; } })(), K = stp && stp.act === 'ir' ? 1 : 0;
        const ho = hopsOf(dO), hn = hopsOf(dN), key = [a.x + ',' + a.y, b.x + ',' + b.y].join(' -> ');
        all.set(key + ' => ' + [a2.x + ',' + a2.y, b2.x + ',' + b2.y].join(' -> '), { a: [a.x, a.y], b: [b.x, b.y], a2: [a2.x, a2.y], b2: [b2.x, b2.y], by: K ? 'kit.js ir (30 px a hop)' : 'nevera.js ranaA (40 px a hop)', old: ho[K], new: hn[K], dOld: r2(dO), dNew: r2(dN) });
        if (ho[K] !== hn[K]) P.push('hops: ' + r.story.id + ' ' + r.plan + ' ' + o[i].path + ': the frog\'s walk ' + key + ' took ' + ho[K] + ' hops, the port\'s ' + hn[K]); } });
    sh.hopsAll = [...all.values()]; sh.hops = sh.hopsAll.filter(h => h.old !== h.new);
    notes.push('hops: the frog\'s ' + nW + ' walks between steps in the ' + runs.length + ' runs, recorded and the port\'s, each the old number of hops (' + all.size + ' distinct walks; ' + sh.hops.length + ' changed)'); }

  /* the set's pixels, every baked state */
  const TAGS = {}; for (const k of ALL_STATES) { const m = new Array(240 * 216).fill(null); for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) m[i] = p; TAGS[k] = m; }
  const zoneAt = (k, x, y) => x < 0 || x >= 240 || y < 0 || y >= 216 ? '-' : G.zone[k][y * 240 + x];
  const boxOfThing = (k, w) => { const b = sh.things[k].box; return typeof b === 'function' ? b(w) : b; };
  /* every set thing's pixels inside its touch box, in every state; the hit order; nothing decorative over a touch box */
  { const res = [], roomIn = {}, ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const boxFor = (id, key) => { if (id === 'frutas' && !key.startsWith('1.')) return null; const t = sh.things[id]; if (id === 'nevera') return t.boxes[+key[0]]; if (id === 'frutas') return t.boxes[key.startsWith('1.2') ? 1 : 0]; return t.box; };
    for (const k of ALL_STATES) { const wrong = {};
      for (const [p, list] of Object.entries(G.parts[k])) { const own = THING_OF(p);
        if (own !== 'cocina') { const b = boxFor(own === 'nevera' && p === 'nevera.dentro' ? 'frutas' : own, k) || sh.things[own].box; let out = 0; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; } if (out) P.push('box: ' + k + ' ' + out + ' px of ' + p + ' outside its touch box ' + JSON.stringify(b)); }
        for (const i of list) { const x = i % 240, y = Math.floor(i / 240); if (x < x0 || x >= x0 + 196) continue; let h = null; for (const [id, m] of ORDER) { const b = boxFor(id, k); if (b && x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) { h = id; break; } }
          if (own === 'cocina' && h !== 'cocina' && h != null) { roomIn[h] = (roomIn[h] || 0) + 1; continue; }
          const ok = own === 'nevera' ? (h === 'nevera' || h === 'frutas') : own === 'cocina' ? true : h === own; if (!ok) { const kk = p + ' -> ' + h; wrong[kk] = (wrong[kk] || 0) + 1; } } }
      for (const [kk, n] of Object.entries(wrong)) P.push('hit: ' + k + ' ' + n + ' px of ' + kk + ' (a touch there answers another thing)'); }
    for (const k of ['nevera', 'frutas']) res.push(k + ' ' + JSON.stringify(sh.things[k].box));
    notes.push('boxes: every pixel of the fridge (body, door, inside, drawer) inside its touch box in every state, its inside in frutas\'s: ' + res.join(', ') + '; in the view every pixel of the fridge answers the fridge (or its inside, open); the room (walls, counter, window, sink, stool: cocina, whose box holds every box as the old) shows inside the fridge\'s boxes, a rectangle round a slanting front, at ' + Object.entries(roomIn).map(([k, n]) => k + ' ' + n).join(', ') + ' pixel-states (no decoration: every set part is the fridge\'s or the kitchen\'s)'); }

  /* every castShadow call darkens; each shadow in one piece with its thing; the stool's thin legs cast only a short contact shadow at their foot,
     on their shadow side: no pixel of the floor on a leg's lit side within 3 px differs from the floor without the stool */
  { const pieces = {}; let nCalls = 0, litBad = 0, litN = 0;
    for (const k of ALL_STATES) { const OG = G.onGround[k], byPart = {};
      for (const c of G.shadows[k]) { const [x, y, z, r, s] = c.args, p = c.part || '(none)'; nCalls++;
        if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + k + ' ' + p + ' castShadow(' + c.args.map(r2).join(', ') + '): nothing is cast');
        (byPart[p] = byPart[p] || { calls: 0 }).calls++; }
      for (const [p, b] of Object.entries(byPart)) { const sp = (G.shadowPx[k][p] || []).filter(i => OG[i] || G.zone[k][i] === 'f'); if (!sp.length) P.push('shadow: ' + k + ' the part ' + p + ' casts ' + b.calls + ' times and darkens nothing');
        const own = new Set(), all = new Set(sp); for (const [pp, list] of Object.entries(G.parts[k])) if (THING_OF(pp) === THING_OF(p) || pp === p) for (const i of list) own.add(i);
        const seen = new Set([...own]), stack = [...own]; while (stack.length) { const i = stack.pop(), x = i % 240, y = Math.floor(i / 240); for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) { const j = (y + dy) * 240 + x + dx; if (x + dx < 0 || x + dx >= 240 || y + dy < 0 || y + dy >= 216 || seen.has(j) || !all.has(j)) continue; seen.add(j); stack.push(j); } }
        const apart = sp.filter(i => !seen.has(i)).length; if (apart) P.push('shadow: ' + k + ' ' + apart + ' px of ' + p + '\'s shadow are not joined to it');
        pieces[p] = (pieces[p] || 0) + sp.length; }
      // the stool's legs: compare with the same state without the stool
      if (k.endsWith('.1')) { const k0 = k.slice(0, -1) + '0', A = G.rgb[k], B = G.rgb[k0], legs = (G.parts[k].banco || []).filter(i => G.zone[k][i] === 'b');
        const legSet = new Set(legs);
        for (const i of legs) { const x = i % 240, y = Math.floor(i / 240); for (let dx = -3; dx <= 0; dx++) for (let dy = -3; dy <= 0; dy++) { const j = (y + dy) * 240 + x + dx; if (legSet.has(j) || G.zone[k][j] !== 'f') continue; litN++; if (A[j * 3] !== B[j * 3] || A[j * 3 + 1] !== B[j * 3 + 1] || A[j * 3 + 2] !== B[j * 3 + 2]) litBad++; } } } }
    if (litBad) P.push('shadow: ' + litBad + ' floor pixels on the stool legs\' lit side (up and left, within 3 px) differ from the floor without the stool');
    notes.push('shadows of the set: ' + nCalls + ' castShadow calls over the ' + ALL_STATES.length + ' states, each with strength 1 and a radius; each casting part darkens pixels, its shadow joined to it: ' + Object.entries(pieces).map(([p, n]) => p + ' ' + n + ' px').join(', ') + '; the stool\'s legs: a contact shadow at the foot on the shadow side only (' + litN + ' floor pixels on their lit side within 3 px, every one as the floor without the stool)'); }

  return checkMoments(sh, G, runs, P, { E, F, COS, T30, M, MASK, NEW, x0, VIEW, TAGS, zoneAt, pairSides, notes });
}

function checkMoments(sh, G, runs, P, C) {
  const { E, F, COS, T30, M, MASK, NEW, x0, VIEW, TAGS, zoneAt, pairSides, notes } = C;
  const N = sh.layout.numbers, f = c => x => Math.round(c + x / 2), CT = f(N.CT), SL = f(N.SL), MU = f(N.MU), PA = f(N.PA);
  const HN = sh.points.nevera.huecos, DR = sh.points.nevera.drawer, CES = sh.points.nevera.top.cesta, OUTSIDE = {}; for (const k of ALL_STATES) OUTSIDE[k] = new Set(G.outside[k]);
  const OLDWIN = [OLD.VEN[0], OLD.VEN[1], OLD.VEN[2], OLD.VEN[3]];
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
  const rowsOverlap = (A, B) => { const S = new Set(); for (const [y, a, b] of A) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0; for (const [y, a, b] of B) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++; return n; };
  const frogRows = q => { const b = frogBox(q), rs = []; for (let y = b.y + R(q.dy || 0); y < b.y + R(q.dy || 0) + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]); return rs; };
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  // the plane of the point a thing stands on (front.how): the zone under its foot says which surface
  const vOn = (sx, sy, z) => { const g = E.atZ(sx, sy, z); return (g[0] + g[1]) / E.R2; };
  const planeAt = (key, x, y) => { const z0 = zoneAt(key, x, y - 1), g = z => E.atZ(x, y, z);
    if (z0 === 'c' || z0 === 'p') return [{ face: 'y', at: g(F.CZ)[1] }, 'counter']; if (z0 === 'v') return [{ face: 'y', at: g(F.WIN.z0 - .1)[1] }, 'sill'];
    if (z0 === 'q') return [{ face: 'x', at: g(F.FR.h)[0] }, 'fridge top']; if (z0 === 'b') return [{ v: vOn(x, y, F.STOOL.h) }, 'stool'];
    if (z0 === 'r') return [{ face: 'x', at: g(F.FR.bin[0] + .06)[0] }, 'drawer'];
    if (z0 === 'e') { let best = null; for (const z of F.FR.shelves.concat([F.FR.bin[1]])) { const q = g(z); if (q[0] >= 0 && q[0] <= F.FR.d && q[1] >= F.FR.a0 && q[1] <= F.FR.a1 && (best == null || z > best)) best = z; } return [{ face: 'x', at: g(best == null ? 0 : best)[0] }, 'shelf']; }
    if (z0 === 't' || z0 === 'w') return [x + .5 < E.OX ? { face: 'x', at: .05 } : { face: 'y', at: .05 }, 'wall'];
    if (z0 === 'f') return [{ v: vOn(x, y - 1, 0) }, 'floor'];
    return [{ v: vOn(x, y - 1, 0) }, z0]; };
  // everything a world shows, placed as nevera.js draws it (new: the port's W and the sheet's numbers; old: the old numbers), in draw order
  const itemsOf = (w, isOld) => { const it = [], raw = rawItems(w), key = keyOf(w);
    const add = (r, rows, at, layer, extra) => { if (!rows) return; it.push(Object.assign({ id: r.id, kind: r.kind, o: r.o, rows, at, layer, key: r.key, mean: (MASK[r.key] || {}).mean }, extra || {})); };
    const m = r => (MASK[r.key] || { rows: [] }).rows;
    for (const r of raw) { const o = r.o;
      if (r.kind === 'yard') { if (r.id === 'carrito') add(r, rowsAt(m(r), o.x, isOld ? 76 : MU(o.x) + 6), [o.x, isOld ? 76 : MU(o.x) + 6], 0, { clip: true }); else add(r, rowsAt(m(r), R(o.x), isOld ? 71 : MU(R(o.x)) + 1), [R(o.x), isOld ? 71 : MU(R(o.x)) + 1], 0, { clip: true }); }
      if (r.kind === 'bird') add(r, rowsAt(m(r), R(o.x), isOld ? 71 : MU(R(o.x)) + 1), [R(o.x), isOld ? 71 : MU(R(o.x)) + 1], 0, { clip: true }); }
    const outs = raw.filter(r => r.kind === 'outside').sort((a, b) => a.o.x - b.o.x);
    for (const r of outs) { const y = R(r.o.y) + R(r.o.dy || 0); add(r, rowsAt(m(r), R(r.o.x), y), [R(r.o.x), R(r.o.y)], 0, { clip: true, person: true });
      const hat = raw.find(q => q.kind === 'hat' && q.id === r.id + ' hat'); if (hat) add(hat, rowsAt(m(hat), R(r.o.x), R(r.o.y) - altoOf(r.id) + 6), [R(r.o.x), R(r.o.y)], 0, { clip: true }); }
    for (const r of raw.filter(r => r.kind === 'sill')) add(r, rowsAt(m(r), R(r.o.x), (isOld ? OLD.SILL : SL(R(r.o.x))) + (r.o.dy || 0)), [R(r.o.x), (isOld ? OLD.SILL : SL(R(r.o.x))) + (r.o.dy || 0)], 1, { base: [R(r.o.x), isOld ? OLD.SILL : SL(R(r.o.x))] });
    for (const r of raw.filter(r => r.kind === 'top')) { const p = isOld ? OLD.CESTA : CES; add(r, rowsAt(m(r), p[0], p[1]), p, 2, { sup: [{ face: 'x', at: E.atZ(p[0], p[1], F.FR.h)[0] }, 'fridge top'] }); }
    for (const r of raw.filter(r => r.kind === 'fridge')) { const h = (isOld ? OLD.HUECO : HN)[r.slot]; add(r, rowsAt(m(r), h[0], h[1] + (r.dy || 0)), [h[0], h[1] + (r.dy || 0)], 2, { sup: [{ face: 'x', at: E.atZ(h[0], h[1], F.FR.shelves[r.slot < 2 ? 0 : 1])[0] }, 'shelf'] }); }
    for (const r of raw.filter(r => r.kind === 'drawer')) { const p = isOld ? (r.fruit === 'guineo' ? [55, 148] : [78, 148]) : DR[r.fruit], y = p[1] - r.i * (r.fruit === 'guineo' ? 11 : 12); add(r, rowsAt(m(r), p[0], y), [p[0], y], 2, { sup: [{ face: 'x', at: E.atZ(p[0], p[1], F.FR.bin[0] + .06)[0] }, 'drawer'] }); }
    for (const r of raw.filter(r => r.kind === 'canasta')) { const K = r.o, y = K.y || (isOld ? OLD.ENC + 11 : CT(K.x) + 1); add(r, rowsAt(m(r), K.x - 156 + 156, y), [K.x, y], 3); }
    // the sorted list: people (y), things (z or y + 1), the frog (q.y + 27); then what flies
    const L = [];
    for (const r of raw.filter(r => r.kind === 'person')) L.push([r.o.y, () => add(r, rowsAt(m(r), R(r.o.x), R(r.o.y) + R(r.o.dy || 0)), [R(r.o.x), R(r.o.y)], 4, { person: true, list: true })]);
    for (const r of raw.filter(r => r.kind === 'thing')) L.push([r.o.z != null ? r.o.z : r.o.y + 1, () => add(r, rowsAt(m(r), R(r.o.x), R(r.o.y)), [R(r.o.x), R(r.o.y)], 4, { list: true, air: r.o.k === 'gotaj' || r.o.z === 500 })]);
    const q = w.cq; if (q && q.vis && !(q.al <= .3)) L.push([q.y + 27, () => { const b = frogBox(q); it.push({ id: 'the frog', kind: 'frog', o: q, rows: frogRows(q), at: [b.x + (b.w >> 1), q.y + 26], layer: 4, list: true, air: R(-(q.dy || 0)) > 3 });
      const en = raw.find(r => r.kind === 'carried'); if (en) add(en, rowsAt(m(en), b.x + (b.w >> 1), b.y + R(q.dy || 0) + 3), [b.x + (b.w >> 1), b.y + 3], 4, { list: true, air: true }); }]);
    L.map((e, i) => [e[0], i, e[1]]).sort((a, b) => a[0] - b[0] || a[1] - b[1]).forEach(e => e[2]());
    for (const r of raw.filter(r => r.kind === 'flying')) add(r, rowsAt(m(r), R(r.o.x), R(r.o.y)), [R(r.o.x), R(r.o.y)], 5, { air: true });
    for (const r of raw.filter(r => r.kind === 'bare')) { const p = it.find(q => q.id === r.id && q.person); if (p) p.bare = rowsAt(m(r), R(r.o.x), R(r.o.y) + R(r.o.dy || 0)); }
    return it; };
  const faceOf = it => { if (it.kind === 'frog') { const b = frogBox(it.o); return [b.x + 2, b.y + R(it.o.dy || 0), b.w - 4, R(b.h * .6)]; }
    const rs = it.bare || it.rows; if (!rs.length) return null; const top = Math.min(...rs.map(r => r[0])), tr = rs.filter(r => r[0] < top + 10), hx = R((Math.min(...tr.map(r => r[1])) + Math.max(...tr.map(r => r[2])) + 1) / 2); return [hx - 6, top + 6, 12, 10]; };
  const facesOf = (w, isOld) => { const f = []; for (const it of itemsOf(w, isOld)) { if (!(it.person || it.kind === 'frog')) continue; if (it.o.al != null && it.o.al < .5) continue; const fc = faceOf(it); if (fc) f.push([it.id + '\'s face', fc, it]); } return f; };
  // the picture as it is drawn: each item owns the pixels it drew last (clipped to the window's outside); after the sorted list the set's own
  // pixels again where nearer than their owner (front); the old picture: the same, with the old window's rectangle as the clip and no front
  const STAMP = new Int32Array(240 * 216), OWN = new Int16Array(240 * 216); let stampN = 0;
  const FRONTP = Object.keys(sh.front.parts);
  const compose = (w, isOld) => { const key = keyOf(w), its = itemsOf(w, isOld); stampN++;
    const inClip = (x, y) => isOld ? x >= OLDWIN[0] && x < OLDWIN[0] + OLDWIN[2] && y >= OLDWIN[1] && y < OLDWIN[1] + OLDWIN[3] : OUTSIDE[key].has(y * 240 + x);
    its.forEach((it, j) => { it.j = j; for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { if (it.clip && !inClip(x, y)) continue; const i = y * 240 + x; STAMP[i] = stampN; OWN[i] = j; } } });
    const cov = new Map(), near = new Map();
    if (!isOld) { const Z = G.z[key], TG = TAGS[key], PL = its.map(it => it.clip || it.air ? null : it.sup || planeAt(key, (it.base || it.at)[0], (it.base || it.at)[1]));
      const SUP = { counter: 'cp', sill: 'vc', 'fridge top': 'q', shelf: 'e', drawer: 'r', stool: 'b' }, ZK = G.zone[key];
      for (let i = 0; i < 240 * 216; i++) { if (STAMP[i] !== stampN || !FRONTP.includes(TG[i])) continue; const j = OWN[i], pl = PL[j]; if (!pl) continue; const y = Math.floor(i / 240); if (SUP[pl[1]] && SUP[pl[1]].includes(ZK[i])) continue; if (pl[1] !== 'floor' && y >= its[j].at[1] - 3 && !(its[j].person || its[j].kind === 'frog')) continue;
        if (Z[i] > planeDepth(E, pl[0], i % 240, y) + 1e-3) { if (its[j].list) cov.set(i, TG[i]); else near.set(i, TG[i]); if (process.env.NEAR_DBG && TG[i] === 'ventana' && !its[j].dbg) { its[j].dbg = 1; console.log('NEAR', its[j].id, JSON.stringify(its[j].base || its[j].at), pl[1], i % 240, y, key); } } } }
    return its.map(it => { let tot = 0, vis = 0, fTot = 0, fVis = 0; const by = {}, hid = {}, nearBy = {}, face = (it.person || it.kind === 'frog') ? faceOf(it) : null;
      for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; tot++; const inF = face && x >= face[0] && x < face[0] + face[2] && y >= face[1] && y < face[1] + face[3]; if (inF) fTot++;
        const mine = STAMP[i] === stampN && OWN[i] === it.j, c = cov.get(i);
        if (process.env.FACE_DBG && inF && !mine) { const h = STAMP[i] === stampN ? its[OWN[i]].id + JSON.stringify(rowsBox(its[OWN[i]].rows)) + its[OWN[i]].kind : 'unstamped'; (it.fdbg = it.fdbg || {})[h] = (it.fdbg[h] || 0) + 1; }
        if (!mine && STAMP[i] === stampN && OWN[i] !== it.j) { const h = its[OWN[i]].id; hid[h] = (hid[h] || 0) + 1; }
        if (mine && c) by[c] = (by[c] || 0) + (inF ? 1000 : 1); if (mine && near.has(i)) nearBy[near.get(i)] = (nearBy[near.get(i)] || 0) + 1;
        if (mine && !c) { vis++; if (inF) fVis++; } } }
      return { it, tot, vis, fTot, fVis, by, hid, nearBy, face, fdbg: it.fdbg }; }); };

  /* every moment: the port's play at every tick inside the acts and every step's end, and every pair picture */
  const allW = [];
  runs.forEach((r, ri) => { for (const t of NEW[ri].ticks) allW.push([r.story.id + ' ' + r.plan + ' t ' + t.t, t.W, 'tick']); for (const L of NEW[ri].states) allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W, 'end']); });
  for (const ps of pairSides) allW.push(['pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps, sh), 'pair']);
  { const bad = new Map(); let nMom = 0, nOn = 0, nTouch = 0; const onSurf = {};
    for (const [where, w, kind] of allW) { nMom++; const key = keyOf(w);
      for (const r of compose(w, false)) { const it = r.it;
        for (const [part, n] of Object.entries(r.by)) { const faceN = Math.floor(n / 1000), bodyN = n % 1000;
          if (faceN) bad.set(part + ' over ' + it.id + '\'s face', where + ': ' + faceN + ' px');
          if (it.kind === 'thing' && bodyN + faceN) { const pl = planeAt(key, it.at[0], it.at[1])[1]; if (pl !== 'floor') bad.set(part + ' over ' + it.id + ' on the ' + pl, where + ': ' + (bodyN + faceN) + ' px'); } }
        // what stands on a top or in the fridge, or anything the sprite layer draws before the sorted list: nothing of the set nearer than it
        for (const [part, n] of Object.entries(r.nearBy)) if (n > 0) bad.set(part + ' nearer than ' + it.id + ' (drawn over it by the sprite layer, but in front of it)', where + ': ' + n + ' px');
        if (it.kind === 'thing' && !it.air) { const pl = planeAt(key, it.at[0], it.at[1])[1]; onSurf[pl] = (onSurf[pl] || 0) + 1; nOn++; } } }
    for (const [k, w] of [...bad].slice(0, 40)) P.push('drawn: ' + k + ' (' + w + ')');
    notes.push('drawn: at ' + nMom + ' moments (every tick inside the acts and every step\'s end of the ' + runs.length + ' runs, every pair picture) the sprite layer composed as it is drawn (each item owns what it drew last; the yard clipped to the window\'s outside; a set part drawn again only over an owner behind it): no set part over any face; nothing of the set over a thing standing on the counter, the sill, the fridge\'s top or a shelf, nor nearer than anything the sprite layer draws before the sorted list (the fridge\'s things, the sill\'s, the basket, the yard\'s); ' + nOn + ' thing-moments by their surface: ' + Object.entries(onSurf).map(([k, n]) => k + ' ' + n).join(', ')); }

  /* at every step's end each person's, and the frog's share seen, and their face's, no smaller than in the old picture of that moment (less 10%;
     the face no less at all); whoever was wholly inside the old view is wholly inside the new one with 3 px to spare */
  { const lows = [], edges = [], worstBy = {}, known = []; let n = 0, nE = 0;
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach((ln, li) => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return;
      const o = new Map(compose(ln.W, true).map(q => [q.it.id, q])), nw = compose(tw.W, false);
      for (const q of nw) { const p = o.get(q.it.id); if (!p) continue;
        if (['person', 'outside', 'frog'].includes(q.it.kind) && !q.it.air && p.tot && q.tot) { n++;
          const sN = q.vis / q.tot, sO = p.vis / p.tot, fN = q.fTot ? q.fVis / q.fTot : 1, fO = p.fTot ? p.fVis / p.fTot : 1;
          { const wk = q.it.id + (q.it.clip ? ' (outside)' : ''), d = Math.min(sN - sO, (fN - fO) * 10); if (!worstBy[wk] || d < worstBy[wk][0]) worstBy[wk] = [d, R(sN * 100) + '/' + R(sO * 100) + ' face ' + R(fN * 100) + '/' + R(fO * 100) + ' ' + r.story.id + ' ' + ln.path + ' new ' + JSON.stringify([q.hid, q.by, q.face, q.fTot, q.tot, q.fdbg]) + ' old ' + JSON.stringify([p.hid, p.face, p.fTot, p.tot])]; }
          // known, not fixed (sheet checks.notFixed): whoever stands outside the window shows less of their body than through the old window,
          // which was 62 rows high; the kit's wall is cut at 3.2, so the new window is 40 rows high at the most, and the counter's things
          // stand right under it; their face is seen as much as in the old picture. And a face covered by another person as in the old picture (a stack kept)
          const byPerson = h => Object.keys(h).filter(k => !/^(cosa|repisa|vuelo|nevera|cesta|canasta|encima|muro|carrito|ave)/.test(k));
          const stackOld = fN < fO && byPerson(q.hid).some(k => byPerson(p.hid).includes(k)) && fN >= fO - .05;
          if (q.it.clip && q.hid['the frog'] && (fN < fO - 1e-9 || sN < sO - .1)) { known.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' (outside) behind the frog: face ' + R(fN * 100) + '%, the old ' + R(fO * 100) + '%'); continue; }
          if (q.it.clip && fN >= fO - 1e-9 && sN < sO - .1 && sN >= sO * .5) { known.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' (outside) seen ' + R(sN * 100) + '%, the old ' + R(sO * 100) + '%, face ' + R(fN * 100) + '%'); continue; }
          if (stackOld && sN >= sO - .1) { known.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + '\'s face ' + R(fN * 100) + '%, the old ' + R(fO * 100) + '%, behind ' + byPerson(q.hid).join(', ') + ' as in the old picture'); continue; }
          if (fN < fO - 1e-9 || sN < sO - .1) lows.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' seen ' + R(sN * 100) + '% (face ' + R(fN * 100) + '%), the old ' + R(sO * 100) + '% (' + R(fO * 100) + '%)' + (process.env.SEEN_BY ? ' new by ' + JSON.stringify(Object.assign({}, q.hid, q.by)) + ' old by ' + JSON.stringify(p.hid) : '')); }
        // nobody new at the edge
        if (q.it.clip) continue; const bO = rowsBox(p.it.rows), bN = rowsBox(q.it.rows); if (!within(bO, VIEW)) continue; nE++;
        if (!within([bN[0] - 3, bN[1] - 3, bN[2] + 6, bN[3] + 6], VIEW)) edges.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' ' + JSON.stringify(bN) + ' (wholly inside the old view at ' + JSON.stringify(bO) + ')'); } }); });
    { const by = {}; for (const l of lows) { const m = l.match(/: (.+?) seen/); by[m[1]] = (by[m[1]] || 0) + 1; } if (lows.length) console.log('  seen less, by who: ' + JSON.stringify(by) + ' worst: ' + JSON.stringify(worstBy)); }
    for (const l of [...new Set(lows)].slice(0, 40)) P.push('seen: ' + l);
    for (const l of [...new Set(edges)].slice(0, 40)) P.push('edge: ' + l + ' is not inside the view with 3 px to spare');
    { const kinds = {}; for (const k of known) { const m = k.match(/: (.+?)( \(outside\)|'s face)/); const kk = m[1] + (m[2] === ' (outside)' ? (/behind the frog/.test(k) ? ' outside, behind the frog hopping along the counter' : ' outside') : ' behind someone'); kinds[kk] = (kinds[kk] || 0) + 1; }
      sh.checks.notFixed = Object.entries(kinds).map(([k, n]) => ({ what: k, moments: n, why: /behind the frog/.test(k) ? 'the frog hops along the counter in front of the window (sacamoneda, mandado); the window is lower over the counter than the old one (the kit\'s wall), so for the moment he passes he covers the face of whoever stands outside behind him (between his hops: no rest place)' : /outside/.test(k) ? 'the window is as high as the kit\'s wall allows (cut at 3.2: 40 rows of it, the old 62), and the counter\'s things (the jug, the plates) stand right under it, so less of the body of whoever stands outside shows; their face shows as much as in the old picture, and never less than half of what showed' : 'the old picture stacked these two people the same way (a stack kept, page 13: as the old)' }));
      if (known.length) notes.push('seen, as the old or not fixed: ' + sh.checks.notFixed.map(k => k.what + ' (' + k.moments + ' step ends)').join(', ')); }
    notes.push('seen: at ' + n + ' person-, outside- and frog-moments (every step\'s end of the ' + runs.length + ' runs) each seen no less than in the old picture of that moment less 10%, and their face no less at all (' + lows.length + ' less); edge: ' + nE + ' item-moments wholly inside the old view, each wholly inside the new one with 3 px to spare'); }
  /* a set thing is whole inside the view by 3 px or clearly runs off it (by 12 px or more) */
  { const res = [];
    for (const k of ALL_STATES) { const byThing = {}; for (const [p, list] of Object.entries(G.parts[k])) { const th = p === 'pared' || p === 'mostrador' ? null : p.split('.')[0]; if (!th) continue; for (const i of list) { const x = i % 240, y = Math.floor(i / 240), b = byThing[th] = byThing[th] || [1e9, 1e9, -1e9, -1e9]; b[0] = Math.min(b[0], x); b[1] = Math.min(b[1], y); b[2] = Math.max(b[2], x); b[3] = Math.max(b[3], y); } }
      for (const [th, b] of Object.entries(byThing)) { const L = b[0] - x0, Rt = x0 + 195 - b[2], B = 215 - b[3];
        for (const [side, d, off] of [['left', L, x0 - b[0]], ['right', Rt, b[2] - (x0 + 195)], ['bottom', B, 0]]) if (d < 3 && !(off >= 12)) P.push('edge: ' + k + ' the ' + th + ' ends ' + d + ' px from the view\'s ' + side + ' edge (whole inside by 3 px, or off it by 12)');
        if (k === '1.0.0.1' || k === '0.0.0.1') res.push(th + ' ' + JSON.stringify(b)); } }
    notes.push('edge: every set thing in every state whole inside the view by 3 px or off it by 12 px and more (the walls, the floor and the counter run off): ' + res.join(', ')); }

  /* whoever stands on the floor stands on clear floor: the lowest two rows of their sprite over the floor (zone f), 2 px round; the frog on the
     stool stands on its top; a thing on the counter, the sill, the fridge's top or a shelf stands on it */
  { const REST_MS = 300, bad = new Map(); let nR = 0;
    const footOf = rs => { const last = Math.max(...rs.map(r => r[0])); return rs.filter(r => r[0] >= last - 1); };
    runs.forEach((r, ri) => { const T = NEW[ri].ticks;
      const posOf = w => { const o = {}; for (const it of itemsOf(w, false)) o[it.id] = it.at.join(','); return o; }, P0 = T.map(t => posOf(t.W));
      for (let i = 0; i < T.length; i++) { const w = T[i].W, key = keyOf(w);
        for (const it of itemsOf(w, false)) { if (it.clip || it.air) continue; let j = i; while (j + 1 < T.length && P0[j + 1][it.id] === P0[i][it.id]) j++; if ((j + 1 < T.length ? T[j + 1].t : T[j].t + REST_MS) - T[i].t < REST_MS) continue; nR++;
          if (it.person) { let off = 0; const pv = planeAt(key, it.at[0], it.at[1])[0], Zk = G.z[key]; for (const [y, a, b] of footOf(it.rows)) for (let x = a - 2; x <= b + 2; x++) for (let dy = 0; dy <= 2; dy++) { const z = zoneAt(key, x, y + dy); if (z === 'f' || z === '-' || z === 's') continue; const i = (y + dy) * 240 + x; if (Zk[i] > planeDepth(E, pv, x, y + dy)) continue; off++; } if (off) bad.set(it.id + ' at ' + it.at, r.story.id + ' ' + r.plan + ' t ' + T[i].t + ': ' + off + ' px round their feet are not floor'); }
          if (it.kind === 'frog') { const fx = it.at[0], fy = it.at[1], z = zoneAt(key, fx, fy), z2 = zoneAt(key, fx, fy + 1); if (!['f', 'b', 'c'].includes(z) && !['f', 'b', 'c'].includes(z2)) bad.set('the frog at ' + it.at, r.story.id + ' ' + r.plan + ' t ' + T[i].t + ': his feet over ' + z + z2); }
          if (it.kind === 'thing' && it.o.z !== 50 && it.o.k !== 'gotaj') { const z = zoneAt(key, it.at[0], it.at[1] - 1); if (!['f', 'c', 'v', 'q', 'e', 'p'].includes(z)) bad.set(it.id + ' at ' + it.at, r.story.id + ' ' + r.plan + ' t ' + T[i].t + ': it stands over ' + z); } } } });
    for (const [k, w] of [...bad].slice(0, 30)) P.push('stands: ' + k + ' (' + w + ')');
    notes.push('stands: ' + nR + ' item-moments at rest (300 ms or more in one place): every person on clear floor (2 px of floor round their feet), the frog on the floor, the stool or the counter, every thing on the floor, the counter, the sill, the fridge\'s top or a shelf'); }

  return checkAsks(sh, G, runs, P, Object.assign(C, { itemsOf, facesOf, faceOf, compose, rowsBox, rowsMeet, rowsOverlap, shown, allW, planeAt, CT, SL, MU, PA }));
}

function checkAsks(sh, G, runs, P, C) {
  const { E, F, M, NEW, x0, VIEW, TAGS, zoneAt, pairSides, notes, itemsOf, facesOf, compose, rowsBox, rowsMeet, rowsOverlap, shown, allW, CT } = C;
  const N = sh.layout.numbers, VT = x => Math.round(N.VT + x / 2);
  /* bubbles, boards */
  { let nM = 0, nB = 0, worstView = 99; const seen = new Set(), asOld = new Set();
    const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
    const talk = (k, top, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy); if (within(r, VIEW) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } const r = bubRect(k, top[0], top[1]); r.old = true; return r; };
    for (const [where, w] of allW) { nM++; const boards = boardsOf(w, x0), faces = facesOf(w, false);
      for (const [id, p] of Object.entries(w.gente || {})) { if (!shown(p) || p.x == null || (p.al != null && p.al < .5) || R(p.x) < x0 || R(p.x) >= x0 + 196) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor');
        for (const k of ks) { const rect = talk(k, [R(p.x), R(p.y) - altoOf(id) - 1], boards, faces), key = JSON.stringify([id, k, rect, boards, faces.map(f => f[1])]); if (seen.has(key)) continue; seen.add(key); nB++;
          if (rect.old && k === 'amor') { asOld.add(id + ' "amor" (' + where.split(' t ')[0] + ')'); continue; }
          if (!within(rect, VIEW)) { P.push('bubble: ' + where + ' ' + id + ' "' + k + '" ' + JSON.stringify(rect) + ' is not wholly inside the view'); continue; }
          worstView = Math.min(worstView, rect[0] - x0, x0 + 196 - rect[0] - rect[2], rect[1], 216 - rect[1] - rect[3]);
          for (const [bn, b] of boards) if (meets(rect, b)) P.push('bubble: ' + where + ' ' + id + ' "' + k + '" is over ' + bn);
          for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + id + ' "' + k + '" is on ' + fn); } }
      const q = w.cq; if (q && q.vis && !(q.al < .5) && q.bub) { const b = frogBox(q), rect = talk(q.bub, [b.x + (b.w >> 1), b.y + 2], boards, faces, b.w >> 1); nB++;
        if (!within(rect, VIEW)) P.push('bubble: ' + where + ' the frog "' + q.bub + '" is not wholly inside the view'); else for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' the frog "' + q.bub + '" is on ' + fn); } }
    notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments (each person\'s recorded one and "amor" when touched, the frog\'s): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the rounds card, on no face' + (asOld.size ? '; where no place is free the "amor" of a touch keeps the old place, as the old (' + [...asOld].join(', ') + ')' : '')); }

  /* the asks: hint frames, the hand, the answer cards and the hint drawn round a card; the things a learner must find or tell apart */
  const caja = (id, p) => p.fuera ? [R(p.x) - 12, VT(R(p.x)) + 2, 24, Math.round(N.VB - N.VT - 2)] : [R(p.x) - 11, R(p.y) - altoOf(id), 22, altoOf(id)];
  const cajaOld = (id, p) => p.fuera ? [R(p.x) - 12, OLD.VEN[1] + 6, 24, OLD.SILL - OLD.VEN[1] - 6] : [R(p.x) - 11, R(p.y) - altoOf(id), 22, altoOf(id)];
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) { if (old) return t.old.box; const st = keyOf(w); if (t.hintBoxes) return t.hintBoxes[k === 'nevera' ? +st[0] : st.startsWith('1.2') ? 1 : 0].slice(); return (t.hintBox || t.box).slice(); }
    const N2 = w.nev || {}, H = old ? OLD.HUECO : sh.points.nevera.huecos;
    if (['leche', 'queso', 'mantequilla'].includes(k)) { const i = (N2.h || []).findIndex(o => o && o.k === k); return N2.abierta && i >= 0 ? [H[i][0] - 13, H[i][1] - 23, 26, 26] : null; }
    if (k === 'cesta') { const c = old ? OLD.CESTA : sh.points.nevera.top.cesta; return w.cesta ? [c[0] - 18, c[1] - 16, 36, 18] : null; }
    const o = (w.cosas || []).find(o => o.id === k && o.vis !== 0); if (o) return [R(o.x) - 9, R(o.y) - 19, 18, 23];
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? (old ? cajaOld(k, p) : caja(k, p)) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hands && !old) { const st = keyOf(w); return t.hands[k === 'nevera' ? +st[0] : st.startsWith('1.2') ? 1 : 0]; } if (t && t.hand && !old) return t.hand;
    const o = !old && (w.cosas || []).find(o => o.id === k && o.vis !== 0); if (o) return [R(o.x), R(o.y) - 17]; const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const headOf = f => [f[0] - 2, f[1] - 6, f[2] + 4, f[3] + 6];
  const PLAIN = 'ctwdeqfvosk';
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99, nTell = 0, cardHint = 0; const askSeen = new Set(), askedFor = new Set(), crossedOld = new Set(), handOld = new Set(), lowAsOld = new Set();
  runs.forEach((r, ri) => { const Ls = NEW[ri].states, Lo = r.lines;
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = JSON.parse(JSON.stringify(Ls[j - 1].W)), jo = Lo.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')), wo = jo > 0 ? Lo[jo - 1].W : w;
      const st = at(r.story, L.path), V = Ls[j - 1].V; let spot = null, opts = [];
      if (st.ask) { spot = sub(st.ask, V); if (st.resp) w.resp = st.resp.map(x => sub(x, V)); opts = [spot]; }
      else if (st.decide) { opts = st.options.map(x => sub(x, V)); const bur = (st.burbujas || []).map(x => sub(x, V)); spot = sub(st.pick, V) || opts[0]; if (st.decide === 'say') w.resp = opts; else if (bur.length) w.resp = bur; }
      const key = keyOf(w), where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', sig = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.cosas, w.nev, w.tarjeta, w.respEn, key]);
      if (askSeen.has(sig)) return; askSeen.add(sig); askedFor.add(spot);
      const faces = facesOf(w, false), facesOld = facesOf(wo, true), items = itemsOf(w, false);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within([f[0] - 4, f[1] - 4, f[2] + 8, f[3] + 8], VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn);
        for (const it of items) { if (it.clip) { const n = rowsMeet(it.rows, c2); if (n && it.person) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + it.id + ' (outside)'); continue; }
          if (it.kind === 'frog') { const f = frogBox(w.cq); if (meets(c, [f.x + 2, f.y + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' covers the frog'); continue; }
          const n = rowsMeet(it.rows, it.person ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id); }
        for (const name of ['nevera.dentro', 'nevera.puerta', 'ventana', 'pila']) { const n = (G.parts[key][name] || []).filter(i => meets([i % 240, Math.floor(i / 240), 1, 1], c)).length; if (n > 3) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + name); }
        // the hint drawn round a card: its frame (box + 12) 2 px inside the view and across no head; its hand on no face
        cardHint++; const fr = [c[0] - FRAME_OUT, c[1] - FRAME_OUT, c[2] + 2 * FRAME_OUT, c[3] + 2 * FRAME_OUT];
        if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('card hint: ' + where + ' the frame round the card ' + k + ' is not 2 px inside the view');
        for (const [fn, f] of faces) if (ringMeets(c, headOf(f))) P.push('card hint: ' + where + ' the frame round the card ' + k + ' crosses ' + fn.replace('face', 'head'));
        const hp = [c[0] + c[2] / 2, c[1] + c[3] - 6]; for (const [fn, f] of faces) if (handOn(hp, f)) P.push('card hint: ' + where + ' the hand at the card ' + k + ' ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view with 2 px to spare'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' (the old frame did not)'); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      if (!hp) { P.push('hand: ' + where + ' no place for the hand at ' + spot); return; }
      if (!rb) { const hr = handRects(hp); if (hr.some(q => !within(q, VIEW))) { const ho = handOf(wo, spot, true); if (!ho || handRects(ho).every(q => within(q, VIEW))) P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is cut by the view\'s edge (the old was not)'); } }
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb) continue;
        const ho = handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1])) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      // the things a learner must find, tell apart or count at this ask: whole in the view, on a plain backdrop, apart where the old had them apart,
      // and covered by nothing (not by the set, not by anyone drawn after them) more than in the old picture
      const named = new Set(opts.filter(Boolean)), tell = items.filter(it => named.has(it.id.replace(/^(cosa|nevera \d) /, '')) || (it.kind === 'fridge' && named.has(it.o.k)) || (it.person && named.has(it.id)));
      const comp = compose(w, false), compO = compose(wo, true), itemsO = itemsOf(wo, true);
      for (const a of tell) { nTell++; const bxA = rowsBox(a.rows);
        if (!within(bxA, VIEW)) P.push('tell: ' + where + ' ' + a.id + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        const ca = comp.find(q => q.it === a), co = compO.find(q => q.it.id === a.id);
        if (ca && co && ca.tot && co.tot && ca.vis / ca.tot < co.vis / co.tot - .1) P.push('tell: ' + where + ' ' + a.id + ' is seen ' + R(ca.vis / ca.tot * 100) + '%, the old ' + R(co.vis / co.tot * 100) + '% (covered by ' + JSON.stringify(Object.assign({}, ca.hid, ca.by)) + ')');
        if (ca && Object.keys(ca.by).length) P.push('tell: ' + where + ' ' + a.id + ' has the set drawn over it: ' + JSON.stringify(ca.by));
        let n = 0, ok = 0; const own = new Set(); for (const [y, x1, x2] of a.rows) for (let x = x1; x <= x2; x++) own.add(y * 240 + x);
        for (const [y, x1, x2] of a.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i)) continue; const z = zoneAt(key, x, y + dy); if (z === '-') continue; n++; if (PLAIN.includes(z)) ok++; }
        if (n && ok < n * .8) P.push('tell: ' + where + ' ' + a.id + ' at ' + a.at + ': only ' + R(ok / n * 100) + '% of what is round it is plain counter, tile, wall, fridge, floor or sky');
        for (const b2 of tell) if (a.id < b2.id) { const nn = rowsOverlap(a.rows, b2.rows); if (!nn) continue; const ao = itemsO.find(x => x.id === a.id), bo2 = itemsO.find(x => x.id === b2.id); if (ao && bo2 && rowsOverlap(ao.rows, bo2.rows)) continue; P.push('tell: ' + where + ' ' + a.id + ' and ' + b2.id + ' overlap by ' + nn + ' px (apart in the old picture)'); } }
    }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least; the fridge and the kitchen by their hint box), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face and cut by no edge where the old was not' + (handOld.size ? ' (but as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow 4 px and more inside the view (' + cardSpare + ' at the least), 2 px clear of the rounds card and of everyone\'s head and body, over no thing, the fridge\'s inside or door, the window or the sink (over the fridge\'s top in no-hay-leche, where nothing stands); at each of the ' + cardHint + ' cards the hint drawn round it: its frame 2 px inside the view, across no head, its hand on no face; ' + nTell + ' times a thing or a person a learner must find or tell apart: whole in the view, seen as much as in the old picture, the set over none, on a plain backdrop, apart where the old had them apart');

  /* heads: nobody's face against the window's frame or bars, the fridge's edge or a cupboard's edge where the old picture kept it clear */
  { const bad = new Map(); let n = 0;
    for (const [where, w, kind] of allW) { if (kind === 'tick') continue; const key = keyOf(w); for (const [fn, f, it] of facesOf(w, false)) { if (it.kind === 'frog' || it.clip) continue; n++;
      for (let y = f[1]; y < f[1] + f[3]; y++) for (let x = f[0]; x < f[0] + f[2]; x++) { const z = zoneAt(key, x, y); if (z === 'v') bad.set(fn + ' / ' + z, where + ' (face ' + JSON.stringify(f) + ')'); } } }
    for (const [k, w] of [...bad].slice(0, 20)) P.push('heads: ' + k + ' (the window\'s frame or the fridge\'s door behind a face) at ' + w);
    notes.push('heads: at ' + n + ' face-moments no face has the window\'s frame, its sill or the fridge\'s door behind it'); }

  /* thin or small things are seen: each pixel of the tap, the fridge's handle, the shelves' edges, the stool's legs and the window's frame
     against the pixel just beside it that is not the thing (left, right, above, below), WCAG contrast: 2.0 and more on average for each thing */
  { const res = [];
    const K = '1.0.0.1', K0 = '0.0.0.1', zone = k => G.zone[k], rgbAt = (k, i) => [G.rgb[k][i * 3], G.rgb[k][i * 3 + 1], G.rgb[k][i * 3 + 2]];
    const thin = [['the tap', K0, i => zone(K0)[i] === 'p' && Math.floor(i / 240) < G.ROWS.counter[i % 240] - 8], ['the shelves\' edges', K, i => zone(K)[i] === 'e' && zone(K)[i + 240] !== 'e'], ['the stool\'s legs', K0, i => zone(K0)[i] === 'b' && Math.floor(i / 240) > F.STOOL.sy + 3], ['the window\'s frame', K0, i => zone(K0)[i] === 'v'], ['the fridge\'s handle', K0, i => (G.parts[K0].nevera || []).includes(i) && G.rgb[K0][i * 3] < 160 && zone(K0)[i] === 'n']];
    for (const [name, k, isIt] of thin) { const Zs = zone(k); let s = 0, n = 0, worst = 99;
      for (let i = 241; i < 240 * 215; i++) { if (!isIt(i)) continue; for (const d of [-1, 1, -240, 240]) { const j = i + d; if (isIt(j) || Zs[j] === Zs[i] && name !== 'the shelves\' edges') continue; const cr = wcag(rgbAt(k, i), rgbAt(k, j)); s += cr; n++; worst = Math.min(worst, cr); break; } }
      const m = n ? s / n : 0; res.push(name + ' ' + r2(m) + ' (' + n + ' px)'); if (n && m < 2) P.push('contrast: ' + name + ' stands out from what is beside it by ' + r2(m) + ' (WCAG; keep 2.0)'); if (!n) P.push('contrast: ' + name + ' has no pixel'); }
    notes.push('contrast (WCAG, each pixel against the one beside it that is not the thing, the mean): ' + res.join(', ')); }

  /* the window: the outside seen through it (sky, the yard's wall, the hedge: the kit's backdrop behind the wall), its frame standing out of the
     wall with its depth, its sill a ledge */
  { const K0 = '0.0.0.1', Z = G.zone[K0], nO = G.outside[K0].length, nV = [...Z].filter(z => z === 'v').length; let sill = 0;
    for (let x = 0; x < 240; x++) for (let y = 0; y < 216; y++) if (Z[y * 240 + x] === 'v' && y > G.ROWS.winBottom[x] + 1) sill++;
    if (nO < 1000) P.push('window: only ' + nO + ' px of the outside show through it'); if (sill < 60) P.push('window: its sill shows ' + sill + ' px');
    notes.push('window: ' + nO + ' px of the outside through it (the kit\'s patio: sky and a cloud, the yard\'s wall, the hedge, ' + (3.2 - 1.92).toFixed(2) + ' behind the wall), its frame and bars ' + nV + ' px standing out of the wall, its sill a ledge (' + sill + ' px)'); }

  /* the preview puts everyone where the sheet's rule does, at every recorded moment; the rule puts everyone at rest where the port's play has them */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = placesOf(remapW(sh, ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        const twI = Ls.findIndex(L => L.path === ln.path && L.kind === ln.kind), tw = Ls[twI]; if (!tw || li === 0 || twI < 1) return; const prev = placesOf(remapW(sh, r.lines[li - 1].W, r.story.id)), port = placesOf(tw.W), portPrev = placesOf(Ls[twI - 1].W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k] || !portPrev[k] || portPrev[k].join() !== port[k].join() || /^cosa\.(charcoj|gotaj)/.test(k)) continue; nR++; if (Math.abs(port[k][0] - p[0]) + Math.abs(port[k][1] - p[1]) > 1) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    if (badR) for (const [k, w] of [...off].slice(0, 30)) P.push('rule: ' + k + ' in the port\'s play (' + w + ')');
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places of the people, the frog and the things) nevera-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); and the rule puts each of the ' + nR + ' places at rest where the port\'s play has them (' + badR + ' differ by more than 1 px)'); }

  /* the review pictures */
  { let nPic = 0; const pairDiff = [], zoom2 = [];
    const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
    for (const [word, sides2] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides2)) { const ps = sides2[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps, sh), key = keyOf(w); ws[side] = w; nPic++;
        const crop = pc.crop, mrg = pc.zoom === 2 ? 1 : 2;
        for (const it of itemsOf(w, false)) { if (it.clip) continue; const b = rowsBox(it.rows); if (!within([b[0] - mrg, b[1] - mrg, b[2] + 2 * mrg, b[3] + 2 * mrg], crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with ' + mrg + ' px to spare in ' + JSON.stringify(crop)); }
        if (pc.zoom === 2) { const inC = i => { const x = i % 240, y = Math.floor(i / 240); return x >= crop[0] && x < crop[0] + crop[2] && y >= crop[1] && y < crop[1] + crop[3]; };
          for (const [part, list] of Object.entries(G.shadowPx[key])) { const s2 = list.filter(i => G.onGround[key][i] && inC(i)).length, own = Object.entries(G.parts[key]).filter(([p]) => THING_OF(p) === THING_OF(part) || p === part).reduce((n, [, l]) => n + l.filter(inC).length, 0); if (s2 > 4 && own < 6) P.push('pair ' + nm + ': shows ' + s2 + ' px of ' + part + '\'s shadow and not ' + part); }
          zoom2.push(nm); } }
      if (!ws.si || !ws.no) continue;
      const diff = []; for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k);
      if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
      if (!diff.length) P.push('pair ' + word + ': the two pictures are the same');
      pairDiff.push(deacc(word) + ': ' + diff.join(', ')); }
    notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures), ' + zoom2.length + ' at zoom 2, the others at zoom 1: everything in each whole with 1 px to spare at zoom 2 (2 at zoom 1); no zoom 2 picture shows a shadow without its caster; what differs: ' + pairDiff.join('; ')); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const T of NEW) for (const t of T.ticks) reached.add(keyOf(t.W)); for (const ps of pairSides) reached.add(keyOf(pairW(ps, sh)));
    for (const b of sh.setKey.baked) if (!reached.has(b.key)) P.push('state ' + b.key + ' is baked but nothing reaches it');
    for (const k of reached) if (!sh.setKey.baked.some(b => b.key === k)) P.push('state ' + k + ' is reached but not baked');
    notes.push('states: ' + sh.setKey.baked.length + ' baked states reached (' + sh.setKey.baked.map(b => b.key).join(', ') + '; every moment, pair and level picture), of the ' + ALL_STATES.length + ' the set can bake');
    const slow = [...reached].filter(k => G.fresh[k] >= 150); for (const k of slow) P.push('bake: the first bake of ' + k + ' in a fresh page took ' + R(G.fresh[k]) + ' ms (keep under 150)');
    console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome, each reached state: the first in a fresh page ' + [...reached].sort().map(k => k + ' ' + R(G.fresh[k])).join(', ') + ' ms; again in the same page ' + [...reached].sort().map(k => R(G.ms[k].warm)).join(', ') + ' ms'); }
  return P;
}
