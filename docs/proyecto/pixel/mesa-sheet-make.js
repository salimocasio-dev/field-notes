#!/usr/bin/env node
'use strict';
/* La mesa's sheet (order 37a): writes docs/proyecto/pixel/mesa-sheet.json from mesa-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/mesa-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.MESA_SET), its part map, its depth and every castShadow call from mesa-set.html in headless Chrome, for every
   baked state, each on a fresh page (the first bake, which also lays the floor, is timed there); measures the old sprite layer (historia/engine.js,
   juego.js, kit.js and escenas/mesa.js as they are: every person, the dog, the frog and every thing drawn by mesa.js draw() itself, alone, against
   the same world without it); projects every world point with the engine's own formula; checks the sheet against coqui/ref/escenas/mesa/
   (positions.json, inventory.json, pairs.json); against every moment of every recorded run of the scene's stories (coqui/tool/ref/trazas/
   juega.mjs --states: the steps' ends; each play the same as its recorded run in coqui/ref/trazas/, h-mesa's too); and against every tick
   inside the acts: the old page played by the same machine (page-init.js, page-drive.js: the same seed, think time and clock) with mesa.js as
   the port will have it (the sheet's moves applied) and the story files' positions through the sheet's remap. It reads mesa.js itself for every
   number that is a place on the picture (the sheet's code). It loads mesa-preview.html (over a local http server it starts and stops) to check
   that the preview puts everyone where the sheet does. Nothing in the repo is written but the sheet. A second run writes the same bytes.
   El banco's maker (orden/36a) and El lago's are the models: the same rules, the same way of checking, the same way of naming the ask pictures.
   MESA_NOCHECK=1: write the sheet only (for designing). MESA_DUMP=<folder>: also write each run's step ends and ticks, the recorded and the
   port's, there (for the pictures; not in the repo). */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'mesa-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/mesa');
const MESA_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/mesa.js'), 'utf8');
const LINES = MESA_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('mesa.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const fnText = name => { const a = MESA_JS.indexOf('function ' + name + '('); if (a < 0) throw new Error('mesa.js changed: ' + name); let d = 0, i = MESA_JS.indexOf('{', a);
  for (; i < MESA_JS.length; i++) { if (MESA_JS[i] === '{') d++; else if (MESA_JS[i] === '}' && --d === 0) break; } return MESA_JS.slice(a, i + 1); };

// the baked states: mantel (the cloth on the table) and horno (the oven lit). setKey(W), as the port has it
const ALL_STATES = ['m0h0', 'm1h0', 'm0h1', 'm1h1'];
const keyOf = w => 'm' + (w.mantel ? 1 : 0) + 'h' + (w.estufa && w.estufa.horno ? 1 : 0);
const queryOf = k => 'mantel=' + k[1] + '&horno=' + k[3];
// the set's parts and the touch key each answers: the table and its chairs are la mesa's; the stove (with its hood and the panel behind it)
// la estufa's; the walls, the door, the window, the counters and the wall cupboard the kitchen's (la cocina: the whole room)
const THING_OF = p => /^(mesa|sillas)/.test(p) ? 'mesa' : /^(estufa|campana)/.test(p) ? 'estufa' : 'cocina';
// the parts that stand in the room (someone can be behind them): drawn again over whoever stands behind them (front)
const FRONT = ['mesa', 'mesa.patas', 'sillas', 'sillas.patas', 'mostrador', 'mostrador2', 'estufa', 'pared', 'puerta', 'puerta.umbral', 'puerta.jamba'];
const SOLID = ['mesa', 'mesa.patas', 'sillas', 'sillas.patas', 'mostrador', 'mostrador2', 'estufa', 'campana', 'alacena', 'pared', 'puerta', 'ventana'];
const R = Math.round, r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100, W4 = p => p.map(r4);
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
const STATES_ARG = process.env.MESA_STATES ? process.env.MESA_STATES.split(',') : ALL_STATES;

(async () => {
  const browser = await chromium.launch();
  const errs = [];
  const G = { parts: {}, z: {}, rgb: {}, shadows: {}, ms: {}, shadowPx: {}, onGround: {}, sub: {} };
  for (const key of STATES_ARG) {
    const page = await browser.newPage();   // a fresh page for each state: its first bake also lays the floor (as the port's very first bake)
    page.on('pageerror', e => errs.push(String(e)));
    await page.goto('file://' + path.join(__dirname, 'mesa-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(MESA_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      const first = BAKE_MS;
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      castShadow = cs0; part = part0;
      // the set without its shadows and dimming: the colour of each pixel before applyShadows (for the lit side check: what the surface is without the thing)
      const onGround = []; for (let i = 0; i < W * H; i++) onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0);
      const surf = []; for (let i = 0; i < W * H; i++) { const s = surfaceAt((i % W) + .5, Math.floor(i / W) + .5); surf.push(s.on === 'floor' ? (s.under ? 'u' : 'f') : s.on === 'wall' ? 'w' : s.on === 'mesa' ? 't' : s.on === 'estufa' ? 'e' : 'c'); }
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), rgb: rgbA, calls, first, warm, shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, surf: surf.join(''), OXY: [OX, OY] };
    });
    // the set without the table, the chairs and the counter's front: what lies behind each piece (for the thin pieces' contrast and the lit side)
    // the first bake on a fresh page, five times (the machine's load varies): the middle one
    const firsts = [g.first]; for (let k = 0; k < 4; k++) { const p2 = await browser.newPage(); await p2.goto('file://' + path.join(__dirname, 'mesa-set.html') + '?' + queryOf(key)); firsts.push(await p2.evaluate(() => BAKE_MS)); await p2.close(); }
    firsts.sort((a, b) => a - b);
    G.ms[key] = { first: firsts[2], firsts, warm: g.warm };
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, surf: g.surf, OXY: g.OXY });
    G.parts[key] = g.parts; G.z[key] = g.z; G.rgb[key] = g.rgb; G.shadows[key] = g.calls; G.shadowPx[key] = g.shadowPx; G.onGround[key] = g.onGround;
    await page.close();
  }
  { const page = await browser.newPage(); page.on('pageerror', e => errs.push(String(e)));   // the set with no shadow cast and no floor dimming: the lit side
    await page.goto('file://' + path.join(__dirname, 'mesa-set.html') + '?noshade=1&' + queryOf('m0h0'));
    G.bare = await page.evaluate(() => { const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, o = []; for (let i = 0; i < W * H; i++) o.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]); return o; });
    await page.goto('file://' + path.join(__dirname, 'mesa-set.html') + '?empty=1&' + queryOf('m0h0'));
    G.empty = await page.evaluate(() => { const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, o = []; for (let i = 0; i < W * H; i++) o.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]); return o; });
    await page.close(); }
  if (errs.length) throw new Error(errs.join('; '));
  const mpage = await browser.newPage(); mpage.on('pageerror', e => errs.push(String(e)));
  await loadOld(mpage);
  G.M = await measure(mpage);
  const runs = storyStates();
  const sheet = make(G, runs);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.MESA_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  G.TICKS = await tickStates(browser, runs, sheet);
  G.OLDHOPS = (await tickStates(browser, runs, sheet, true)).map(r => r.hops);   // the old page played as it is (old mesa.js, old story files): its frog's walks
  G.PV = await previewPlaces(browser, runs);
  G.PAIRPX = await pairPixels(browser, sheet);
  if (process.env.MESA_DUMP) { fs.mkdirSync(process.env.MESA_DUMP, { recursive: true }); runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.MESA_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states, ticks: G.TICKS[i].ticks }))); }
  // the sprite layer's shapes for every item seen at any moment (measured in the browser, mesa.js draw() itself: the old one and the port's)
  const ppage = await browser.newPage(); ppage.on('pageerror', e => errs.push(String(e)));
  await loadOld(ppage, portSource(sheet));
  G.MASK = await masks(mpage, ppage, collectKeys(sheet, G, runs));
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
   historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/mesa.js (the old one, or the port's: the sheet's moves applied) loaded as
   they are into a blank page. Every shape is what mesa.js draw() itself draws for a world holding only that one thing, against the same world
   without it: a person's extras (what they hold, carry, raise or offer, the baby), the dog's load, every thing. A bubble is drawn as mesa.js bub2
   draws it (twice its size, its tail's tip at the origin), on both frames of its bob */
async function loadOld(page, src) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  if (src) await page.addScriptTag({ content: src }); else await page.addScriptTag({ path: path.join(REPO, 'historia/escenas/mesa.js') });
  // the old table's own sprite (mkMesa, drawn at MESA[0] - 6, MESA[1] in the sorted list): for the old picture's composite
  await page.addScriptTag({ content: '(()=>{const R=Math.round,MESA=[92,130,96,30];' + fnText('mkMesa') + '\nwindow.MKMESA=mkMesa;})();' });
}
async function measure(page) {
  return page.evaluate(() => {
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
    // the old table (mkMesa) at its place: its rows, with and without the cloth
    const tableRows = {}; for (const m of [0, 1]) { const im = MKMESA(m), cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 92 - 6, 130);
      const d = g.getImageData(0, 0, 240, 216).data, rows = []; for (let y = 0; y < 216; y++) { let a = -1, b = -1; for (let x = 0; x < 240; x++) if (d[(y * 240 + x) * 4 + 3] > 40) { if (a < 0) a = x; b = x; } if (a >= 0) rows.push([y, a, b]); } tableRows[m] = rows; }
    return { bubbles, tableRows, PX: KIT.PX };
  }).then(async m => { m.oldBg = await page.evaluate(async src => { const im = await new Promise(res => { const i = new Image(); i.onload = () => res(i); i.src = src; }); const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0); return Array.from(g.getImageData(0, 0, 240, 216).data); },
    'data:image/png;base64,' + fs.readFileSync(path.join(REF, 'frames/bg.cocina.png')).toString('base64')); return m; });
}
// an item's key (what its shape depends on), and the world that draws it alone. People, the dog and a thing at SHAPE_AT (their shape does not
// depend on where they are); the things on the table (puestos), on the counter (mostrador) and on the stove (estufa) where they are (their places
// are the scene's own): their key holds all that draws them
const SHAPE_AT = [120, 150];
const pickO = (o, ks) => ks.map(k => o[k] == null ? '' : typeof o[k] === 'object' ? JSON.stringify(o[k]) : o[k]).join('|');
function rawItems(w) {
  const out = [], shown = o => o && o.vis !== 0 && o.x != null;
  for (const [id, p] of Object.entries(w.gente || {})) if (shown(p) && !(p.al != null && p.al <= .3)) {
    const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0, paso: 0, bub: null, piensa: null });
    out.push({ kind: 'person', id, o: p, key: 'p|' + id + '|' + pickO(p, ['pose', 'dir', 'sent', 'hace', 'que', 'lleva', 'lleva2', 'alza', 'alzax', 'mano', 'ofrece', 'bebe']) + '|' + (p.lleva === 'bandeja' || (p.lleva && p.lleva.k === 'bandeja') ? JSON.stringify(w.bandeja || []) : '') + '|' + (id === 'abuela' && p.lleva === 'tabla' ? Math.max(0, Math.min(3, w.reb)) : ''),
      spec: { gente: { [id]: o }, bandeja: w.bandeja || [], reb: w.reb } }); }
  if (w.perro && shown(w.perro)) { const o = Object.assign({}, w.perro, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0 }); out.push({ kind: 'dog', id: 'perro', o: w.perro, key: 'd|' + pickO(w.perro, ['pose', 'dir', 'lleva', 'cola']), spec: { perro: o } }); }
  (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0 && c.x != null) { const o = Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); delete o.z; out.push({ kind: 'thing', id: 'cosa ' + (c.id || c.k + i), o: c, key: 't|' + pickO(c, ['k', 'con', 'n', 'rot', 'vapor', 'plano']), spec: { cosas: [o] } }); } });
  (w.suelo || []).forEach((c, i) => { const o = Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); out.push({ kind: 'thing', id: 'suelo ' + c.k, o: Object.assign({ suelo: 1 }, c), key: 's|' + pickO(c, ['k', 'rot']), spec: { suelo: [o] } }); });
  return out;
}
// the fixed-place items: what stands at the places at the table, on the counter, on the stove; drawn where they are
function placeItems(w) {
  const out = [], P = w.puestos || [], any = P.some(p => p && (p.plato || p.taza || (p.frente || []).length));
  if (any) out.push({ kind: 'table', id: 'the places at the table', key: 'T|' + JSON.stringify(P) + '|' + JSON.stringify(w.sitio || {}) + '|' + Object.entries(w.gente || {}).filter(([k, p]) => p && p.hace === 'bebe').map(e => e[0]).join(','),
    spec: { puestos: P, sitio: w.sitio || {}, gente: Object.fromEntries(Object.entries(w.gente || {}).filter(([k, p]) => p && p.hace === 'bebe').map(([k, p]) => [k, { x: -100, y: -100, hace: 'bebe', vis: 1 }])) } });
  const M = w.mostrador || {}; if (Object.values(M).some(v => v)) out.push({ kind: 'counter', id: 'the counter\'s things', key: 'M|' + JSON.stringify(M) + '|' + JSON.stringify(w.bandeja || []), spec: { mostrador: M, bandeja: w.bandeja || [] } });
  const E = Object.assign({}, w.estufa || {}); delete E.horno; if (Object.values(E).some(v => v)) out.push({ kind: 'stove', id: 'the stove\'s things', key: 'E|' + JSON.stringify(E), spec: { estufa: E } });
  return out;
}
function collectKeys(sheet, G, runs) {
  const keys = new Map();
  const add = w => { for (const it of rawItems(w).concat(placeItems(w))) { if (it.key && !keys.has(it.key)) keys.set(it.key, it.spec);
    if (it.kind === 'person') { const p = it.o, fk = 'f|' + it.id + '|' + (p.pose || '') + '|' + (p.dir < 0 ? -1 : 1) + '|' + (p.sent ? 1 : 0); if (!keys.has(fk)) keys.set(fk, { gente: { [it.id]: { x: SHAPE_AT[0], y: SHAPE_AT[1], dir: p.dir, sent: p.sent, pose: p.pose } } }); } } };
  for (const r of runs) for (const l of r.lines) add(l.W);
  for (const T of G.TICKS) { for (const t of T.ticks) add(t.W); for (const L of T.states) add(L.W); }
  for (const ps of pairSidesOf()) add(pairW(ps, sheet, true)), add(pairW(ps, sheet, false));
  return [...keys.entries()];
}
// each key's shape: the rows [dy, x from, x to] that mesa.js draw() changes (relative to SHAPE_AT for a person, the dog and a thing; where they are
// for the fixed-place items), its mean colour; measured with the old mesa.js (old) and the port's (new: the places moved)
async function masks(oldPage, newPage, list) {
  const run = page => page.evaluate(list => {
    const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d');
    const E = ESCENAS.mesa, base = () => Object.assign(E.fresh(), { afuera: 1, gente: {}, cosas: [], suelo: [], puestos: [0, 1, 2, 3].map(() => ({ plato: null, taza: null, uts: [], frente: [] })), mostrador: {}, estufa: {}, perro: null, vuelos: [], cq: { x: 0, y: 0, s: 1, dy: 0, al: 1, vis: 0, bub: null } });
    const shot = w => { W = w; F = 0; TALK = null; g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.imageSmoothingEnabled = false; g.clearRect(0, 0, 240, 216); E.draw(g, w, 0); return g.getImageData(0, 0, 240, 216).data; };
    const out = {}, bgs = {};
    for (const [key, spec] of list) {
      const fixed = /^[TME]\|/.test(key), b0 = Object.assign(base(), fixed ? { afuera: key[0] === 'T' ? 0 : 1 } : {}), bk = fixed ? key[0] : 'x';
      if (!bgs[bk]) bgs[bk] = shot(JSON.parse(JSON.stringify(b0)));
      const bg = bgs[bk], d = shot(Object.assign(JSON.parse(JSON.stringify(b0)), JSON.parse(JSON.stringify(spec)))), rows = []; let n = 0; const s = [0, 0, 0];
      const ox = fixed ? 0 : 120, oy = fixed ? 0 : 150;
      for (let y = 0; y < 216; y++) { let a = -1, b = -1; for (let x = 0; x < 240; x++) { const i = (y * 240 + x) * 4; if (d[i] !== bg[i] || d[i + 1] !== bg[i + 1] || d[i + 2] !== bg[i + 2]) { if (a < 0) a = x; b = x; n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } } if (a >= 0) rows.push([y - oy, a - ox, b - ox]); }
      out[key] = { rows, mean: s.map(v => Math.round(v / Math.max(1, n))) };
    }
    return out;
  }, list);
  return { old: await run(oldPage), new: await run(newPage) };
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

/* ---------- the preview's places: mesa-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/mesa-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [{ id: r.story.id }, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- (round 2) the review pictures as the preview draws them: each whole picture before its crop, without the thing the pair is about
   (sheet pictures[...].thing), and without each person in it: the thing's pixels and each person's, for the pairs' checks ---------- */
async function pairPixels(browser, sheet) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/mesa-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    const raw = async (w, s, d) => Buffer.from(await page.evaluate(([w, s, d]) => PREVIEW.pairRaw(w, s, d), [w, s, d]), 'base64');
    const diff = (a, b) => { const m = []; for (let i = 0; i < 240 * 216; i++) if (a[i * 3] !== b[i * 3] || a[i * 3 + 1] !== b[i * 3 + 1] || a[i * 3 + 2] !== b[i * 3 + 2]) m.push(i); return m; };
    const out = {};
    for (const ps of pairSidesOf()) { const nm = deacc(ps.w) + '.' + ps.side, pc = sheet.pictures[nm]; if (pc.scene) continue; const w = deacc(ps.w);
      const full = await raw(w, ps.side, []), noT = await raw(w, ps.side, pc.thing), people = {};
      for (const id of Object.keys((ps.spec.set || {}).gente || {})) people[id] = diff(full, await raw(w, ps.side, ['gente.' + id]));
      out[nm] = { full, noT, thing: diff(full, noT), people }; }
    await page.close();
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    return out;
  });
}

/* ---------- mesa.js as the port will have it: the sheet's moves applied (the same edit as mesa-preview.html's, without its drawing) ---------- */
function portSource(sheet) {
  let src = MESA_JS; const done = new Set();
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); if (!src.includes(m.src)) throw new Error('mesa.js does not hold ' + m.src); src = src.split(m.src).join(m.to); }
  return src;
}
// a story file with its positions through the sheet's remap (the host does it: page 12 section 5); returns the text
function portStory(file, sheet) {
  const j = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos', file + '.json'), 'utf8'));
  for (const e of sheet.remap.concat(sheet.storyPlaces || [])) { if (!e.moved || e.kind !== 'point') continue;
    for (const u of e.uses) { const [f, at] = u.split(' '); if (f !== file + '.json') continue;
      const keys = at.split('.'), last = keys.pop(), o = keys.reduce((a, k) => a[/^\d+$/.test(k) ? +k : k], j), t = o[last];
      if (Array.isArray(t)) { t[0] = e.new[0]; t[1] = e.new[1]; } else if (t && typeof t === 'object') { t.x = e.new[0]; t.y = e.new[1]; } else throw new Error('remap: ' + u + ' is not a place'); } }
  return JSON.stringify(j);
}

/* ---------- every tick inside the acts (as El lago's and El banco's makers): the old page played by the same machine as the recorded runs,
   mesa.js and the story files as the port will have them, the scene's W kept after every timer the runner fires when it changed ---------- */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = { gente: W.gente, sitio: W.sitio, puestos: W.puestos, mostrador: W.mostrador, estufa: W.estufa, mantel: W.mantel, cosas: W.cosas, suelo: W.suelo, vuelos: W.vuelos,
      vierte: W.vierte, muestra: W.muestra, encima: W.encima, perro: W.perro, bandeja: W.bandeja, tiron: W.tiron, reb: W.reb, cq: W.cq, tarjeta: W.tarjeta, marcas: W.marcas, respEn: W.respEn, resp: W.resp, spot: W.spot, F: typeof F === 'number' ? F : 0 };
    const s = JSON.stringify(o, (k, x) => typeof x === 'function' || (x && x.nodeType) || x instanceof HTMLCanvasElement ? undefined : x); if (s !== last) { last = s; window.__TICKS.push({ t: H.now, W: JSON.parse(s) }); } } catch (e) {} };
  H.drain = () => d().then(() => { keep(); }); })();`;
// (fix after the port) every walk of the frog: each call of juego.js hopTo (mesa.js ranaA and every act that hops him), where he is, where to, how
// many hops; installed at the first drain after juego.js has defined hopTo (mesa.js calls it by its global name)
const HOP_HOOK = `(() => { const H = window.__H, d = H.drain; window.__HOPS = [];
  const put = () => { try { if (typeof hopTo !== 'function' || hopTo.__hop) return; const f = hopTo; const g = function (x, y, hops, s1) { const q = W.cq; window.__HOPS.push({ t: H.now, from: [q.x, q.y], to: [x, y], hops }); return f.apply(this, arguments); }; g.__hop = 1; window.hopTo = g; } catch (e) {} };
  H.drain = () => { put(); return d().then(() => { put(); }); }; })();`;
async function tickStates(browser, runs, sheet, old = false) {
  const INIT = fs.readFileSync(path.join(TRAZAS, 'page-init.js'), 'utf8').replace('__SEED__', '1'), DRIVE = fs.readFileSync(path.join(TRAZAS, 'page-drive.js'), 'utf8');
  const SRC = portSource(sheet);
  return serve(async base => { const out = [];
    for (const r of runs) {
      const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: 'UTC', locale: 'en-US' });
      try {
        await ctx.addInitScript(INIT); if (!old) await ctx.addInitScript(TICK_HOOK); await ctx.addInitScript(HOP_HOOK);
        await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop());
          return fs.existsSync(path.join(REPO, 'historia/audio', name)) ? route.fulfill({ status: 200, contentType: 'audio/mpeg', body: 'ID3' }) : route.fulfill({ status: 404, body: '' }); });
        if (!old) await ctx.route(/\/historia\/escenas\/mesa\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
        if (!old) await ctx.route(/\/historia\/cuentos\/[^/]+\.json(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop()).replace(/\.json$/, '');
          return route.fulfill({ status: 200, contentType: 'application/json', body: portStory(name, sheet) }); });
        const page = await ctx.newPage();
        await page.goto(base + '/historia/index.html?cuento=' + r.story.id + '&fast=1&rec=1&mic=stub:none&abiertas=todas');
        for (let i = 0; ; i++) { if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break; if (i > 600) throw new Error('the page did not load ' + r.story.id); await new Promise(z => setTimeout(z, 50)); }
        await page.evaluate('voiceReady'); await page.evaluate(DRIVE);
        const tr = await page.evaluate(cfg => window.__drive(cfg), { plan: r.plan, think: 700, limitMs: 4 * 3600e3, states: true });
        if (tr.end !== 'finished') throw new Error('ticks: ' + r.story.id + ' ' + r.plan + ' ended: ' + tr.end);
        const hops = await page.evaluate(() => window.__HOPS); if (old) { out.push({ hops }); continue; }
        out.push({ ticks: await page.evaluate(() => window.__TICKS), states: tr.states, hops });
      } finally { await ctx.close(); }
    }
    return out; });
}

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'mesa') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'mesa-sheet-'));
  try {
    const runs = [];
    for (const st of stories) {
      execFileSync(process.execPath, [path.join(REPO, 'coqui/tool/ref/trazas/juega.mjs'), '--only', st.id, '--out', path.join(tmp, 'trazas', st.id), '--states', path.join(tmp, 'states')], { cwd: REPO, stdio: 'pipe' });
      for (const plan of ['right', 'wrong', 'alternate']) {
        const lines = fs.readFileSync(path.join(tmp, 'states', st.id, plan + '.states.jsonl'), 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
        // the play is the recorded run: its trace, byte for byte, is coqui/ref/trazas/<story>/<plan>.json (h-mesa's too, recorded on the kitchen's base)
        const played = path.join(tmp, 'trazas', st.id, st.id, plan + '.json'), rec = path.join(REPO, 'coqui/ref/trazas', st.id, plan + '.json');
        const recorded = fs.existsSync(rec) ? fs.readFileSync(played).equals(fs.readFileSync(rec)) : null;
        runs.push({ story: st, plan, lines, recorded });
      }
    }
    return runs;
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}
const PAIRS = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
const pairSidesOf = () => PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'mesa').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
const CUAL = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-mesa.json'), 'utf8'));
// a pair picture's world (cual.js panelW: the frog at 123, 150 s .86 unless the pair sets him), through the sheet's remap (old: as it is)
function pairW(ps, sheet, old) {
  const it = CUAL.items.find(i => i.w === ps.w), set = JSON.parse(JSON.stringify(it[ps.side].set || {}));
  const w = Object.assign({ gente: {}, cosas: [], suelo: [], puestos: [0, 1, 2, 3].map(() => ({ plato: null, taza: null, uts: [], frente: [] })), mostrador: {}, estufa: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null } }, set);
  if (old) return w;
  const mv = o => { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === R(o.x) && e.old[1] === R(o.y) && e.uses.some(u => u.startsWith('cual-mesa.json'))); if (m) { o.x = m.new[0]; o.y = m.new[1]; } };
  for (const o of Object.values(w.gente || {})) mv(o); for (const o of w.cosas || []) mv(o); if (w.perro) mv(w.perro);
  if (w.cq && w.cq.vis) mv(w.cq);
  return w;
}

/* ---------- the engine's projection, as pp-engine.js has it; the room's surfaces (mesa-set.html surfaceAt) ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2, F = G.F;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  const inR = (x, y, r, m = 0) => x >= r[0] - m && x <= r[2] + m && y >= r[1] - m && y <= r[3] + m;
  const TOPS = [['mesa', F.FOOT.mesa, F.ZT], ['mostrador', F.FOOT.mostrador, F.K.CZ], ['mostrador2', F.FOOT.mostrador2, F.K.CZ], ['estufa', F.FOOT.estufa, F.K.CZ]];
  const CHR = F.CHAIRS.map((c, k) => ['silla' + k, [c.x - F.CH.hw, c.y - F.CH.hd, c.x + F.CH.hw, c.y + F.CH.hd]]);
  // what is under a screen point: a top (the table's, a counter's, the stove's) or the floor; on the floor whether it is under something
  const surface = (sx, sy, m = 0) => { for (const [on, r, z] of TOPS) { const g = atZ(sx, sy, z); if (inR(g[0], g[1], r, m)) return { on, z, w: g }; }
    const g = atZ(sx, sy, 0), u = Object.entries(F.FOOT).find(([k, r]) => inR(g[0], g[1], r)) || CHR.find(([k, r]) => inR(g[0], g[1], r));
    return { on: g[0] < 0 || g[1] < 0 ? 'wall' : 'floor', z: 0, w: g, under: u ? u[0] : null }; };
  // is the screen point on the top `on`, at least m (world) inside its edges
  const onTop = (sx, sy, on, m = .04) => { const t = TOPS.find(q => q[0] === on), g = atZ(sx, sy, t[2]); return inR(g[0], g[1], t[1], -m); };
  // is the floor under the screen point clear (in the room, under nothing), with a margin m (world) to everything standing
  const clearFloor = (sx, sy, m = .1) => { const g = atZ(sx, sy, 0); if (g[0] < m || g[1] < m) return false; for (const r of Object.values(F.FOOT)) if (inR(g[0], g[1], r, m)) return false; for (const [, r] of CHR) if (inR(g[0], g[1], r, m)) return false; return true; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ, surface, onTop, clearFloor, inR };
}

/* ---------- the old scene's numbers (historia/escenas/mesa.js, read as text) ---------- */
const OLD = (() => { const g = (re, w) => { const m = MESA_JS.match(re); if (!m) throw new Error('mesa.js changed: ' + w); return m; };
  const L21 = g(/const PISO=(\d+),MESA=\[(\d+),(\d+),(\d+),(\d+)\],SILLA=\[(\d+),(\d+),(\d+),(\d+)\],MOSTR=\[(\d+),(\d+),(\d+),(\d+)\],ESTUFA=\[(\d+),(\d+),(\d+),(\d+)\],FILA=(\d+),FRENTE=(\d+);/, 'line 21').slice(1).map(Number);
  const EN = JSON.parse('{' + g(/const EN=\{(.*?)\};/, 'EN')[1].replace(/(\w+):/g, '"$1":').replace(/MOSTR\[1\]\+(\d+)/g, (m, d) => String(L21[10] + +d)) + '}');
  const L24 = g(/const LUIS=\[(\d+),(\d+)\],FOGON=\[(\d+),(\d+)\],CAN=\[(\d+),(\d+)\];/, 'line 24').slice(1).map(Number);
  const LU = g(/const LUGAR=\{inicio:\[(\d+),(\d+),(\d+)\],centro:\[(\d+),(\d+),(\d+)\]\};/, 'LUGAR').slice(1).map(Number);
  return { PISO: L21[0], MESA: L21.slice(1, 5), SILLA: L21.slice(5, 9), MOSTR: L21.slice(9, 13), ESTUFA: L21.slice(13, 17), FILA: L21[17], FRENTE: L21[18], EN,
    LUIS: L24.slice(0, 2), FOGON: L24.slice(2, 4), CAN: L24.slice(4, 6), LUGAR: { inicio: LU.slice(0, 3), centro: LU.slice(3, 6) } }; })();
const OLDBOX = { mesa: [OLD.MESA[0] - 4, OLD.MESA[1], OLD.MESA[2] + 8, OLD.MESA[3] + 8], estufa: [OLD.ESTUFA[0], OLD.ESTUFA[1] - 4, 28, 46], cocina: [22, 24, 196, 190] };
// the places a bubble's tail may go, in order (as El lago's and El banco's): over the head (the old), beside the head on the right, on the left ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner card mesa.js hud draws, in the 196 x 216 display (tarjeta(3, 3, 66, 24) covers [2, 2, 68, 26])
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta && !(w.resp && w.resp.some(k => ['cuchara', 'tenedor', 'cuchillo'].includes(k))) ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];
// the frog's places that the acts and the stories use (q, his top left), and the old ones they are
const FROG_PLACES = { inicio: [104, 161], ranaa: [24, 146], hm: [36, 173], th: [54, 165] }, FROG_NEW = {};

/* ---------- the design: what moves and why (make() reads it) ----------
   Each move is an exact piece of mesa.js and its replacement (the port does the same edit). Numbers come from the set's plan (MESA_SET) and the
   rules below, so a second run writes the same bytes. */
function design(E, F) {
  const SD = F.SD, SY = OLD.SILLA.map((x, k) => 150 + SD[k]);
  const pd = F.WALK.out, PU = E.project(pd[0], pd[1], 0), PUERTA = [R(PU.sx), R(PU.sy)];
  const PK = r2(E.OY - E.OX / 2 + F.WALK.y * E.S / E.R2), PASO = x => R(PK + x / 2);
  // the least move (whole px) that puts every foot of a thing (its bottom row's middle, and its two ends) on a top, 2 rows inside its back edge and
  // 1 inside its front: feet [[dx, dy, half width]] relative to the anchor; returns [mx, my] (0, 0 when it is already on it)
  const onTopAll = (ax, ay, feet, on) => feet.every(([dx, dy, hw]) => { const x = ax + dx, y = ay + dy - .5; return E.onTop(x, y - 2, on, .02) && E.onTop(x, y + 1, on, .02) && E.onTop(x - hw, y, on, 0) && E.onTop(x + hw, y, on, 0); });
  const least = (ax, ay, feet, on, keepX) => { let best = null;
    for (let r = 0; r <= 40 && !best; r++) for (let mx = keepX ? 0 : -r; mx <= (keepX ? 0 : r); mx++) for (let my = -r; my <= r; my++) { if (Math.max(Math.abs(mx), Math.abs(my)) !== r) continue;
      if (onTopAll(ax + mx, ay + my, feet, on) && (!best || Math.hypot(mx, my) < Math.hypot(best[0], best[1]))) best = [mx, my]; }
    if (!best) throw new Error('no place on ' + on + ' for ' + ax + ',' + ay); return best; };
  // the counter's things (EN, mesa.js line 23): each stack's bottom row on the counter's top
  const ENFEET = { platos: [[0, 0, 6]], tazas: [[-5, 0, 4], [6, 0, 4]], bandeja: [[0, 0, 14]], comidas: [[-7, 0, 6], [8, 0, 6]], vasos: [[-4, 0, 4], [5, 0, 4]], jarron: [[4, 0, 6]] };
  const EN = {}; for (const [k, p] of Object.entries(OLD.EN)) { const m = least(p[0], p[1], ENFEET[k], 'mostrador'); EN[k] = [p[0] + m[0], p[1] + m[1]]; }
  // the stove's things (draw: the pot on the burner, the cake, the jug, the pink cake; ESTUFA + offsets)
  const ES = OLD.ESTUFA, STF = { olla: [13, 3, [[0, 0, 9]]], entero: [17, 4, [[0, 0, 10]]], jarra: [25, -1, [[-2, 0, 4]]], pastel: [5, 6, [[0, 0, 4]]] };
  const ST = {}; for (const [k, [dx, dy, feet]] of Object.entries(STF)) { const m = least(ES[0] + dx, ES[1] + dy, feet, 'estufa'); ST[k] = [dx + m[0], dy + m[1]]; }
  // the places in front of each seat (the old rows: the frog serving 190, Luis 202, abuela 204, Canelo begging 194, what falls 202, the bundle 200):
  // the least rows down that put each on clear floor in front of the table (margin .1), whole in the picture with 3 px to spare
  // in front of the table across a sprite's width: the plane of its foot (v = (x + y) / R2) nearer than the table's near face at every column of
  // the sprite (the near edge runs along x, so its right part is nearer than its left: the depth test the front redraw makes)
  const T0 = F.TBL, vFoot = (sx, sy) => { const g = E.atZ(sx, sy - 1, 0); return (g[0] + g[1]) / E.R2; };
  const vNear = sx => { const xw = Math.min(T0.x1, Math.max(T0.x0, (sx - E.OX) / (E.S / E.R2) + T0.y1)); return (xw + T0.y1) / E.R2; };
  const clearP = (x, y, hw, mv = .03) => [-hw, 0, hw].every(dx => E.clearFloor(x + dx, y - 1, .1)) && E.clearFloor(x, y - 4, .1) && (y - 1 < E.project(T0.x0, T0.y0, T0.z).sy || vFoot(x, y) >= Math.max(vNear(x - hw), vNear(x + hw)) + mv);
  const down = (x, y, hw, maxY, mv) => { for (let d = 0; y + d <= maxY; d++) if (clearP(x, y + d, hw, mv)) return d; throw new Error('no clear floor in front of ' + x + ',' + y); };
  const S = OLD.SILLA, FRX = [0, 0, -4, 2], FAX = [24, 24, 24, 26], FR = S.map((x, i) => down(x - 14 + FRX[i], 188, 15, 211, .1)), FT = S.map(x => down(x - 10, 188, 15, 211, .1)), FL = S.map(x => down(x - 15, 202, 11, 213)), FA = S.map((x, i) => down(x + FAX[i], 204, 12, 213)), FP = S.map(x => down(x + 16, 194, 13, 213)), FC = S.map(x => down(x - 2, 202, 6, 213)), FI = S.map(x => down(x - 6, 200, 12, 213));
  // where abuela stands at the stove (FOGON) and where Canelo lies (CAN): 3 px inside the view's right edge (her sprite reaches 13 px right of her x)
  // (FOGON 24 rows down: in front of the table's right end, beside the stove, so that what she holds out passes under the face of whoever sits at
  // the right end of the table (it steps down to 171), and her walks to the places and the counter keep in front of the table)
  const FOGON = [Math.min(OLD.FOGON[0], 22 + 196 - 3 - 13), OLD.FOGON[1] + 24], CAN = [OLD.CAN[0], OLD.CAN[1] + down(OLD.CAN[0], OLD.CAN[1], 12, 213)];
  const AB = down(CAN[0] - 34, CAN[1] - 8, 12, 213), LUIS = OLD.LUIS.slice();   // (unchanged: see check KNOWN, what Luis holds up over the table's near left corner)
  return { SD, SY, PUERTA, PK, PASO, EN, ST, ENFEET, FRX, FAX, FR, FT, FL, FA, FP, FC, FI, FOGON, CAN, AB, LUIS };
}
function designMoves(E, F, D) {
  const S = OLD.SILLA, SDs = '[' + D.SD.join(',') + ']', ENs = Object.entries(D.EN).map(([k, p]) => k + ':[' + p.join(',') + ']').join(',');
  const sit = (who, k) => [who, [S[k], 150], [S[k], D.SY[k]], 'sit'];
  const st = (k, o) => 'ESTUFA[0]' + (o[0] >= 0 ? '+' : '') + o[0] + ',ESTUFA[1]' + (o[1] >= 0 ? '+' : '') + o[1];
  return [
    { act: '*', src: 'FILA=148,FRENTE=157;', to: 'FILA=148,FRENTE=157,SD=' + SDs + ',PUERTA=[' + D.PUERTA.join(',') + '],PASO=x=>Math.round(' + D.PK + '+x/2);', def: true,
      why: 'the table stands on the world\'s axes (along x), so its far side, where the four chairs stand, falls half a row for every px to the right: SD[i], the rows each seat steps down from the old row 150 (whoever sits at seat i has their feet at 150 + SD[i]: -24, -12, 0, +12, the least that keeps the four in the old order, apart, and the right end of the table clear of the frog\'s, Luis\'s and abuela\'s places in front of it); PUERTA, on the patio\'s step outside the doorway in the left wall (round 2: seen in the opening, the wall and the door\'s frame drawn over what of them is behind it), where whoever comes in to sit appears and where whoever leaves goes; from it they step in straight onto the walkway\'s end in the doorway (the old door at the picture\'s left edge, x 6); PASO(x), the row of the walkway behind the chairs at x (the world line y = ' + F.WALK.y + ')' },
    { act: '*', src: 'const LUIS=[75,160],FOGON=[205,170],CAN=[196,204];', to: 'const LUIS=[' + D.LUIS + '],FOGON=[' + D.FOGON + '],CAN=[' + D.CAN + '],FRX=[' + D.FRX + '],FAX=[' + D.FAX + '],FR=[' + D.FR + '],FT=[' + D.FT + '],FL=[' + D.FL + '],FA=[' + D.FA + '],FP=[' + D.FP + '],FC=[' + D.FC + '],FI=[' + D.FI + '];',
      pts: [['abuela', OLD.FOGON, D.FOGON], ['perro', OLD.CAN, D.CAN], ['luis', OLD.LUIS, D.LUIS]].filter(q => q[1].join() !== q[2].join()),
      why: 'LUIS, where Luis waits at the counter: unchanged (what he holds up at his right reaches over the table\'s near left corner: checks, asks); FOGON, where abuela stands at the stove: ' + (OLD.FOGON[0] - D.FOGON[0]) + ' px left, so that she is whole in the view with 3 px to spare (her sprite reached the view\'s last column), and 24 rows down, in front of the table\'s right end beside the stove: the table\'s right end and whoever sits there (150 + SD[3]) are where she stood, and what she holds out covered their face; from here her walks keep in front of the table; CAN, where Canelo lies: ' + (D.CAN[1] - OLD.CAN[1]) + ' rows down (clear floor beside the table\'s right end). FR, FL, FA, FP, FC, FI: for each seat, the rows the places in front of it step down from the old ones (the frog serving, the frog fetching from the sitter, Luis, abuela, Canelo begging, what falls from the table, the bundle of the cloth), the least that puts each on clear floor in front of the table (the table along x comes nearer the camera to the right)' },
    { act: '*', src: 'const ranaAl=i=>ranaA(SILLA[i]-14,190);', to: 'const ranaAl=i=>ranaA(SILLA[i]-14+FRX[i],190+FR[i]);', pts: S.map((x, i) => ['cq', [x - 30, 163], [x - 30 + D.FRX[i], 163 + D.FR[i]]]).filter(q => q[1].join() !== q[2].join()), why: 'ranaAl: the frog serving place i stands in front of the table (FR), at the two right places 3 px apart from where abuela waits in the middle (centro: FRX), so that she covers no more of his face than the old' },
    { act: '*', src: 'await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190:p.y+8);', to: 'await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190+FT[j]:p.y+8);', pts: S.map((x, i) => ['cq', [x - 26, 163], [x - 26, 163 + D.FT[i]]]).filter(q => q[1][1] !== q[2][1]), why: 'ranaTrae: the frog fetching from whoever sits at place j stands in front of the table (FT: the least rows down, as FR)' },
    { act: '*', src: 'x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202;', to: 'x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202+FL[i];', pts: S.map((x, i) => ['luis', [x - 15, 202], [x - 15, 202 + D.FL[i]]]).filter(q => q[1][1] !== q[2][1]), why: 'luisEn: Luis serving place i stands in front of the table (FL)' },
    { act: '*', src: 'if(Math.hypot(ab.x-x,ab.y-y)>3)await mueve("abuela",x,y);ab.dir=-1;}', to: 'if(Math.hypot(ab.x-x,ab.y-y)>3){const vy=Math.max(ab.y,y),vx=ab.y<y?ab.x:x;if(Math.hypot(ab.x-vx,ab.y-vy)>3)await mueve("abuela",vx,vy);await mueve("abuela",x,y);}ab.dir=-1;}',
      why: 'abuelaEn: abuela walks between the stove and a place at the table round the front of the table: down (or across) to the lower row first, then along it, so that she passes below the faces of whoever sits at the right of the table (the table along x brings the right seats nearer the camera: across the straight way her head went over their faces)' },
    { act: '*', src: 'x=i==null?FOGON[0]:SILLA[i]+22,y=i==null?FOGON[1]:204;', to: 'x=i==null?FOGON[0]:SILLA[i]+FAX[i],y=i==null?FOGON[1]:204+FA[i];', pts: S.map((x, i) => ['abuela', [x + 22, 204], [x + D.FAX[i], 204 + D.FA[i]]]), why: 'abuelaEn: abuela serving place i stands in front of the table (FA), 2 px further right than the old (4 at the last place: FAX), so that what she carries is off the face of the frog when he serves the place too' },
    { act: 'abuelaa', src: 'await mueve("abuela",142,207)', to: 'await mueve("abuela",138,213)', pts: [['abuela', [142, 207], [138, 213]]], why: 'acts.abuelaa (centro): where abuela waits in the middle while the frog serves, 6 rows nearer and 4 px left: the frog serving the right places stands lower than the old (FR), and her skirt covered more of his face than the old' },
    { act: '*', src: 'await perroA(SILLA[i]+16,194);', to: 'await perroA(SILLA[i]+16,194+FP[i]);', pts: S.map((x, i) => ['perro', [x + 16, 194], [x + 16, 194 + D.FP[i]]]).filter(q => q[1][1] !== q[2][1]), why: 'canelo: Canelo begging at place i sits in front of the table (FP)' },
    { act: '*', src: 'await mueve("luis",SILLA[sitio("mama")]-26,204);', to: 'await mueve("luis",SILLA[sitio("mama")]-26,204+FL[sitio("mama")]);', why: 'recoge24: Luis picks the bundle up in front of mamá\'s place (FL)' },
    { act: '*', src: 'W.cosas.push({id:"lio",k:"lio",x:SILLA[im]-6,y:200});', to: 'W.cosas.push({id:"lio",k:"lio",x:SILLA[im]-6,y:200+FI[im]});', pts: S.map((x, i) => ['cosa', [x - 6, 200], [x - 6, 200 + D.FI[i]]]).filter(q => q[1][1] !== q[2][1]), why: 'tira24: the bundle of the cloth lies on the floor in front of mamá\'s place (FI)' },
    { act: 'final26', src: 'await mueve("abuela",CAN[0]-34,CAN[1]-8);', to: 'await mueve("abuela",CAN[0]-34,CAN[1]-8+' + D.AB + ');', pts: [['abuela', [OLD.CAN[0] - 34, OLD.CAN[1] - 8], [D.CAN[0] - 34, D.CAN[1] - 8 + D.AB]]], why: 'acts.final26: abuela gives Canelo his bone standing in front of the table\'s right end (' + D.AB + ' rows down: the old point is under it)' },
    { act: 'inicio24', src: 'async inicio24(){W.mantel=1;', to: 'async inicio24(){W.respEn=[98,20];W.mantel=1;', respEn: [98, 20], why: 'acts.inicio24 (la-mesa, h-mesa): the two answer cards (di_plato, di_taza) stand on the wall above the heads, so that the hint hand under each falls on nobody\'s face: the first card\'s hand left of abuelo\'s (seat 0), the second\'s right of it, both over the heads of seats 1 to 3 (their faces under the hands\' reach); as high as their glow allows (4 px inside the view)' },
    { act: 'inicio25', src: 'async inicio25(){W.mantel=1;', to: 'async inicio25(){W.respEn=[123,20];W.mantel=1;', respEn: [123, 20], why: 'acts.inicio25 (la-cuchara): the three answer cards on the wall above the heads, the hand under each between the sitters\' faces or over them (the first card\'s left of abuelo\'s face, the second\'s right of it)' },
    { act: 'inicio26', src: 'async inicio26(){W.mantel=0;', to: 'async inicio26(){W.respEn=[98,20];W.mantel=0;', respEn: [98, 20], why: 'acts.inicio26 (tengo-hambre): the two answer cards as la-mesa\'s' },
    { act: '*', src: 'if(p.vis===0){p.vis=1;p.x=6;p.y=152;p.sent=0;}await mueve(id,p.x,152,2);await mueve(id,SILLA[i],152);p.sent=1;p.y=150;p.dir=1;',
      to: 'if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=PUERTA[1];p.sent=0;}await mueve(id,p.x,PASO(p.x),2);await mueve(id,SILLA[i],PASO(SILLA[i]));p.sent=1;p.y=150+SD[i];p.dir=1;',
      pts: [['whoever', [6, 152], D.PUERTA]], why: 'sienta: whoever comes in to sit appears in the doorway (PUERTA), walks along the walkway behind the chairs (PASO: the old row 152, behind the table) to their chair and sits on it (150 + SD[i])' },
    { act: '*', src: 'p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,152,2);await mueve(id,4,152);p.vis=0;', to: 'p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,PASO(p.x),2);await mueve(id,PUERTA[0],PUERTA[1]);p.vis=0;',
      pts: [['whoever', [4, 152], D.PUERTA]], why: 'sale: whoever leaves gets up onto the walkway behind the chairs and goes out by the doorway (the old went out at the picture\'s left edge, x 4)' },
    { act: 'inicio25', src: 'abuelo:{x:SILLA[0],y:150,sent:1,dir:1},mama:{x:SILLA[1],y:150,sent:1,dir:1},papa:{x:SILLA[2],y:150,sent:1,dir:1},carmen:{x:SILLA[3],y:150,sent:1,dir:1}',
      to: 'abuelo:{x:SILLA[0],y:150+SD[0],sent:1,dir:1},mama:{x:SILLA[1],y:150+SD[1],sent:1,dir:1},papa:{x:SILLA[2],y:150+SD[2],sent:1,dir:1},carmen:{x:SILLA[3],y:150+SD[3],sent:1,dir:1}',
      pts: [sit('abuelo', 0), sit('mama', 1), sit('papa', 2), sit('carmen', 3)], why: 'acts.inicio25: the four at the table sit on their chairs (150 + SD)' },
    { act: 'prueba', src: 'abuelo:{x:SILLA[0],y:150,dir:1,sent:1', to: 'abuelo:{x:SILLA[0],y:150+SD[0],dir:1,sent:1', why: 'acts.prueba (a test of the drawing, no story): abuelo on his chair' },
    { act: 'prueba', src: 'papa:{x:SILLA[1],y:150,dir:1,sent:1', to: 'papa:{x:SILLA[1],y:150+SD[1],dir:1,sent:1', why: 'acts.prueba: papá on his chair' },
    { act: 'prueba', src: 'mama:{x:SILLA[2],y:150,dir:1,sent:1', to: 'mama:{x:SILLA[2],y:150+SD[2],dir:1,sent:1', why: 'acts.prueba: mamá on her chair' },
    { act: 'prueba', src: 'carmen:{x:SILLA[3],y:150,dir:1,sent:1', to: 'carmen:{x:SILLA[3],y:150+SD[3],dir:1,sent:1', why: 'acts.prueba: Carmen on her chair' },
    { act: '*', src: 'L.push({y:MESA[1]+MESA[3]+6,d:', to: 'L.push({y:MESA[1]+MESA[3]+6+SD[3],d:', why: 'draw: what stands at the places (the table\'s entry in the sorted list) is drawn after whoever sits, at every seat: the seats step down to 150 + SD[3] at the right, past the old row 166' },
    { act: '*', src: 'L.push({y:MESA[1]+MESA[3]+7,d:', to: 'L.push({y:MESA[1]+MESA[3]+7+SD[3],d:', why: 'draw (W.tiron): the pulled cloth after the places, as the old' },
    { act: '*', src: 'fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+dy+e.dy));', to: 'fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+SD[i]+Math.round(dx/2)+dy+e.dy));',
      why: 'draw: what stands at place i (its plate, its cup) on the table\'s top at its seat (FILA + SD[i]); when the cloth is pulled (tira24: dx) it slides along the table, half a row for every px' },
    { act: '*', src: 'const x=SILLA[i]-4+j*7,y=FRENTE+(j%2)*2;', to: 'const x=SILLA[i]-4+j*7,y=FRENTE+SD[i]+(j%2)*2;', why: 'draw: what is spilt or set aside in front of place i (FRENTE + SD[i]), on the table\'s top' },
    { act: '*', src: 'return p.sent?[R(p.x)-11,R(p.y)-h,22,FILA+3-(R(p.y)-h)]:[R(p.x)-11,R(p.y)-h,22,h];', to: 'return p.sent?[R(p.x)-11,R(p.y)-h,22,h+1]:[R(p.x)-11,R(p.y)-h,22,h];',
      why: 'caja: whoever sits is touched above the table\'s edge, down to the old FILA + 3 (their feet row + 1): relative to them (the same box at the old row 150)' },
    { act: '*', src: 'else if(p.mano)tenida(c,p.mano,x+8,p.sent?MESA[1]+7:hy+18);', to: 'else if(p.mano)tenida(c,p.mano,x+8,p.sent?y-13:hy+18);', why: 'gente: what a sitter holds lies at the table\'s edge in front of them (the old MESA[1] + 7, 13 rows over their feet): relative to them' },
    { act: '*', src: 'for(let j=0;j<12;j++)fr(c,x+2-(j>>2),MESA[1]-10+j,4,1,j%3?"#FFFFFF":"#E4E4EE");fr(c,x,MESA[1]+1,6,2,"#D0302A");', to: 'for(let j=0;j<12;j++)fr(c,x+2-(j>>2),R(m.y)-30+j,4,1,j%3?"#FFFFFF":"#E4E4EE");fr(c,x,R(m.y)-19,6,2,"#D0302A");',
      why: 'draw (W.tiron): the corner of the cloth the baby pulls, at mamá\'s place: relative to her (the old MESA[1] = her feet row - 20)' },
    { act: '*', src: 'if(k==="plato"){await vuela({k:"bizcocho"},ab.x-14,ab.y-24,xDe(i,"plato"),FILA-2-(ps.plato.n-1)*3,5);ps.plato.con="bizcocho";}', to: 'if(k==="plato"){await vuela({k:"bizcocho"},ab.x-14,ab.y-24,xDe(i,"plato"),FILA+SD[i]-2-(ps.plato.n-1)*3,5);ps.plato.con="bizcocho";}',
      why: 'sirve: the slice flies onto the plate at place i (FILA + SD[i])' },
    { act: '*', src: 'W.vierte={x:xDe(i,"taza")-2,y:FILA-8+dyDe(i,"taza")};', to: 'W.vierte={x:xDe(i,"taza")-2,y:FILA+SD[i]-8+dyDe(i,"taza")};', why: 'sirve: the jug pours into the cup at place i' },
    { act: '*', src: 'await vuela({k:"bizcocho"},ab.x-14,ab.y-24,x-1,FILA-8,5);const v={k:"bizcocho",x:x-1,y:FILA-8};', to: 'await vuela({k:"bizcocho"},ab.x-14,ab.y-24,x-1,FILA+SD[i]-8,5);const v={k:"bizcocho",x:x-1,y:FILA+SD[i]-8};', why: 'sirvemal: the slice lands on the cup at place i' },
    { act: '*', src: 'W.vierte={x:x-2,y:FILA-6,h:8};', to: 'W.vierte={x:x-2,y:FILA+SD[i]-6,h:8};', why: 'sirvemal: the jug pours onto the plate at place i' },
    { act: '*', src: 'y1=id==="coqui"?pies()+3:FILA;', to: 'y1=id==="coqui"?pies()+3:FILA+SD[sitio(id)];', why: 'reparte26: what goes round lands at each place (FILA + SD)' },
    { act: '*', src: 'c=Object.assign({x:SILLA[i]-2,y:FRENTE},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+(202-FRENTE)*s/4;', to: 'c=Object.assign({x:SILLA[i]-2,y:FRENTE+SD[i]},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+SD[i]+(202+FC[i]-FRENTE-SD[i])*s/4;',
      pts: S.map((x, i) => ['cosa', [x - 2, 202], [x - 2, 202 + D.FC[i]]]).filter(q => q[1][1] !== q[2][1]), why: 'canelo: what was set aside in front of place i (FRENTE + SD[i]) falls from the table to the floor in front of it (202 + FC[i])' },
    { act: '*', src: 'const EN={' + LINES[lineOf('const EN={platos:') - 1].match(/const EN=\{(.*?)\};/)[1] + '};', to: 'const EN={' + ENs + '},ENQ={' + LINES[lineOf('const EN={platos:') - 1].match(/const EN=\{(.*?)\};/)[1].replace('platos:[36,', 'platos:[38,') + '};',
      pts: Object.entries(OLD.EN).filter(([k, p]) => D.EN[k][0] !== p[0] || D.EN[k][1] !== p[1]).map(([k, p]) => ['mostrador.' + k, p, D.EN[k]])
        .concat(['platos', 'tazas'].filter(k => D.EN[k][0] !== OLD.EN[k][0] || D.EN[k][1] !== OLD.EN[k][1]).map(k => ['muestra', [OLD.EN[k][0], OLD.EN[k][1] - 20], [D.EN[k][0], D.EN[k][1] - 20]]))
        .concat(Object.entries({ cuchara: -9, tenedor: 0, cuchillo: 9 }).map(([k, bx]) => ['muestra', [OLD.EN.bandeja[0] + bx, OLD.EN.bandeja[1] - 6], [D.EN.bandeja[0] + bx, D.EN.bandeja[1] - 6]]))
        .concat([['cq', [OLD.EN.platos[0] + 2 - 16, 144], [OLD.EN.platos[0] + 4 - 16, 144]]]),
      why: 'where each kind of thing stands on the counter (EN): the counter runs along the left wall, so its top falls half a row for every px to the left; each stack\'s bottom row moved by the least distance that puts it on the top, 2 rows inside its back edge and 1 inside its front; the thing lifted off a stack to be shown (W.muestra) moves with its stack. ENQ, the old EN: the places on the floor in front of the counter made from it (the frog fetching, abuela at the counter, Canelo begging) keep their old screen points (they did not need to move), but the frog fetching plates (ENQ.platos 2 px right of the old EN.platos), so that he is whole in the view with 3 px to spare' },
    { act: 'pon', src: 'const key=k+"s",e=EN[M[key]!=null?key:"bandeja"];await ranaA(e[0]+2,171);', to: 'const key=k+"s",e=ENQ[M[key]!=null?key:"bandeja"];await ranaA(e[0]+2,171);', why: 'ranaTrae: the frog fetches at the counter where he did (ENQ: the old EN)' },
    { act: 'lleva26', src: 'await ranaA(EN[key][0]+4,173);', to: 'await ranaA(ENQ[key][0]+4,173);', why: 'acts.lleva26: the frog fetches at the counter where he did (ENQ)' },
    { act: '*', src: 'mueve("abuela",EN.jarron[0]+26,182)', to: 'mueve("abuela",ENQ.jarron[0]+26,182)', why: 'llena26, abuelada, ofrece26, abuelalleva, reparte26: abuela at the counter where she stood (ENQ)' },
    { act: 'canelo26', src: 'await perroA(EN.comidas[0]+52,198);', to: 'await perroA(ENQ.comidas[0]+52,198);', why: 'acts.canelo26: Canelo sits begging in front of the counter where he did (ENQ)' },
    { act: '*', src: 'if(E.olla===2)tenida(c,"ollavacia",ESTUFA[0]+13,ESTUFA[1]+3);else if(E.olla){tenida(c,"olla",ESTUFA[0]+13,ESTUFA[1]+3);if(E.tapa)tenida(c,"tapa",ESTUFA[0]+13,ESTUFA[1]-9);',
      to: 'if(E.olla===2)tenida(c,"ollavacia",' + st('olla', D.ST.olla) + ');else if(E.olla){tenida(c,"olla",' + st('olla', D.ST.olla) + ');if(E.tapa)tenida(c,"tapa",' + st('olla', [D.ST.olla[0], D.ST.olla[1] - 12]) + ');',
      pts: [['estufa.olla', [OLD.ESTUFA[0] + 13, OLD.ESTUFA[1] + 3], [OLD.ESTUFA[0] + D.ST.olla[0], OLD.ESTUFA[1] + D.ST.olla[1]]]], why: 'draw: the pot (and its lid) on the stove\'s top, over its left burner' },
    { act: '*', src: '[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+p[0]+((t+i)%3)-1,ESTUFA[1]+p[1]-((t+i*2)%6),2,3,"#FFFFFF"));', to: '[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+' + (D.ST.olla[0] - 13) + '+p[0]+((t+i)%3)-1,ESTUFA[1]+' + (D.ST.olla[1] - 3) + '+p[1]-((t+i*2)%6),2,3,"#FFFFFF"));', why: 'draw: the steam rises from the pot (moved with it), against the dark panel behind the stove' },
    { act: '*', src: 'if(E.bizcocho)tenida(c,"entero",ESTUFA[0]+17,ESTUFA[1]+4);if(E.jarra)tenida(c,"jarra",ESTUFA[0]+25,ESTUFA[1]-1);if(E.pastel)tenida(c,"pastel",ESTUFA[0]+5,ESTUFA[1]+6);',
      to: 'if(E.bizcocho)tenida(c,"entero",' + st('entero', D.ST.entero) + ');if(E.jarra)tenida(c,"jarra",' + st('jarra', D.ST.jarra) + ');if(E.pastel)tenida(c,"pastel",' + st('pastel', D.ST.pastel) + ');',
      pts: ['entero', 'jarra', 'pastel'].map(k => ['estufa.' + k, [OLD.ESTUFA[0] + { entero: 17, jarra: 25, pastel: 5 }[k], OLD.ESTUFA[1] + { entero: 4, jarra: -1, pastel: 6 }[k]], [OLD.ESTUFA[0] + D.ST[k][0], OLD.ESTUFA[1] + D.ST[k][1]]]),
      why: 'draw: the cake, the jug and the pink cake on the stove\'s top, each moved by the least distance that puts it on the top' },
  ];
}

/* ---------- the sheet ---------- */
function make(G, runs) {
  const E = engine(G), F = G.F, KEY0 = 'm0h0';
  const P2 = (x, y, z = 0) => { const p = E.project(x, y, z); return [r2(p.sx), r2(p.sy)]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1 - x0, y1 + 1 - y0]; };
  const partPx = names => { const all = []; for (const k of Object.keys(G.parts)) for (const n of names) all.push(...(G.parts[k][n] || [])); return all; };
  // a person, the dog, the frog: the floor under the point (a top may be in front of it: they stand behind the table); a thing: the surface under it
  const floorW = (sx, sy) => ({ on: 'floor', world: W4(E.atZ(sx, sy, 0)) }), topW = (sx, sy) => { const s = E.surface(sx, sy); return { on: s.on === 'wall' ? 'floor' : s.on, world: W4(s.w) }; };
  const frogW = q => floorW(q[0] + 16, q[1] + 25), placeW = p => floorW(p[0], p[1] - 1);
  const seatW = (sx, sy) => ({ on: 'seat', world: W4(E.atZ(sx, sy - 8, F.ZS)) });   // whoever sits: the seat under their lap (x, y - 8)
  const D = design(E, F);
  const MOVES = designMoves(E, F, D).map(m => Object.assign({ line: lineOf(m.src) }, m, { lines: linesOf(m.src) }));
  for (const m of MOVES) for (const q of m.pts || []) q[3] = /^(mostrador|estufa)\./.test(q[0]) ? W4(E.surface(q[2][0], q[2][1] - 1).w) : q[3] === 'sit' ? seatW(q[2][0], q[2][1]).world : placeW(q[2]).world;
  const STORY = designStoryMoves(E, F, D);

  // the old code's own drawing the engine replaces
  const DROPPED = [
    { src: 'c.drawImage(W.afuera?spr("puesto",mkPuesto):spr("cocina",fondo),0,0);', to: '', why: 'the background (fondo, mkPuesto): the set, for setKey(W); W.afuera (the stall, one review picture) is El colmado\'s stall (pictures cocina.no)' },
    { src: 'if(E.horno){fr(c,ESTUFA[0]+6,ESTUFA[1]+18,ESTUFA[2]-12,16,"#B84818");fr(c,ESTUFA[0]+8,ESTUFA[1]+27,14,6,"#F4E4C0");fr(c,ESTUFA[0]+8,ESTUFA[1]+26,14,2,"#FFF8E8");}', to: '', why: 'the oven lit (W.estufa.horno): the set\'s (setKey horno: the stove\'s oven window glows)' },
    { src: 'c.drawImage(spr("mesa"+(W.mantel?1:0),()=>mkMesa(W.mantel)),MESA[0]-6,MESA[1]);', to: '', why: 'the table (mkMesa, in the sorted list): the set\'s table and its cloth (setKey mantel); what stands on it is still drawn there, at its entry; the set\'s table and chairs are drawn again over whoever is behind them (front)' },
  ].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* spots: the frog's places of LUGAR and the named places of the old code; each keeps its screen place (the floor rule) but those moves name */
  const SPOTS = {};
  const spot = (k, at, what, kind = 'place', nw) => { const n = nw || at, w = kind === 'cq' ? frogW(n) : kind === 'sit' ? seatW(n[0], n[1]) : kind === 'top' ? topW(n[0], n[1] - 1) : placeW(n);
    SPOTS[k] = Object.assign({ world: w.world, on: w.on, old: at.slice(0, 2), new: n.slice(0, 2) }, kind === 'cq' ? { scale: 1 } : {}, nw && (nw[0] !== at[0] || nw[1] !== at[1]) ? { moved: true } : {}, { what }); };
  for (const [k, v] of Object.entries(OLD.LUGAR)) spot('frog.' + k, v, 'LUGAR.' + k + ': the frog\'s place q (his feet at q.x + 16, q.y + 25), in front of the table', 'cq');
  OLD.SILLA.forEach((x, i) => spot('silla.' + i, [x, 150], 'SILLA[' + i + ']: whoever sits at place ' + i + ' (their feet row 150 + SD[' + i + ']; their lap on the seat)', 'sit', [x, D.SY[i]]));
  OLD.SILLA.forEach((x, i) => spot('puesto.' + i, [x, OLD.FILA], 'FILA: what stands at place ' + i + ' (its plate, its cup), on the table\'s top (FILA + SD[' + i + '])', 'top', [x, OLD.FILA + D.SD[i]]));
  OLD.SILLA.forEach((x, i) => spot('frente.' + i, [x - 4, OLD.FRENTE], 'FRENTE: what is spilt or set aside in front of place ' + i + ', on the table\'s top (FRENTE + SD[' + i + '])', 'top', [x - 4, OLD.FRENTE + D.SD[i]]));
  OLD.SILLA.forEach((x, i) => spot('rana.' + i, [x - 30, 163], 'ranaAl(' + i + '): the frog serving place ' + i + ' (q; his feet at SILLA - 14 + FRX, 188 + FR), in front of the table', 'cq', [x - 30 + D.FRX[i], 163 + D.FR[i]]));
  OLD.SILLA.forEach((x, i) => spot('luis.' + i, [x - 15, 202], 'luisEn(' + i + '): Luis serving place ' + i + ', in front of the table', 'place', [x - 15, 202 + D.FL[i]]));
  OLD.SILLA.forEach((x, i) => spot('abuela.' + i, [x + 22, 204], 'abuelaEn(' + i + '): abuela serving place ' + i + ', in front of the table', 'place', [x + D.FAX[i], 204 + D.FA[i]]));
  spot('puerta', [6, 152], 'PUERTA: on the patio\'s step just outside the doorway (round 2: seen in the opening before they step onto the kitchen floor), where whoever comes in to sit appears and whoever leaves goes (the old came in at the left edge, x 6)', 'place', D.PUERTA);
  spot('luis', OLD.LUIS, 'LUIS: where Luis waits at the counter', 'place', D.LUIS);
  spot('fogon', OLD.FOGON, 'FOGON: where abuela stands at the stove', 'place', D.FOGON);
  spot('canelo', OLD.CAN, 'CAN: where Canelo lies, beside the table\'s right end', 'place', D.CAN);
  for (const [k, p] of Object.entries(OLD.EN)) spot('mostrador.' + k, p, 'EN.' + k + ': where the ' + k + ' stand on the counter (the bottom row of the stack)', 'top', D.EN[k]);
  for (const [k, o] of Object.entries({ olla: [13, 3], entero: [17, 4], jarra: [25, -1], pastel: [5, 6] })) spot('estufa.' + k, [OLD.ESTUFA[0] + o[0], OLD.ESTUFA[1] + o[1]], 'the ' + k + ' on the stove\'s top (draw)', 'top', [OLD.ESTUFA[0] + D.ST[k][0], OLD.ESTUFA[1] + D.ST[k][1]]);
  for (const [k, q] of Object.entries(FROG_PLACES)) if (k !== 'inicio') spot('frog.' + k, q, { ranaa: 'acts.rana (la-mesa beats.53: 40, 173): the frog by the counter', hm: 'acts.inicio24, inicio25: the frog at the counter (36, 173)', th: 'acts.inicio26: the frog at the counter (54, 165)' }[k], 'cq', FROG_NEW[k]);

  /* the named points of the set */
  const T0 = F.TBL;
  const PTS = {
    mesa: { world: W4([T0.x0, T0.y0, 0, T0.x1, T0.y1, T0.z]), top: [P2(T0.x0, T0.y0, T0.z), P2(T0.x1, T0.y0, T0.z), P2(T0.x1, T0.y1, T0.z), P2(T0.x0, T0.y1, T0.z)], what: 'the table along x: its top at z ' + T0.z + ' over x ' + T0.x0 + ' to ' + T0.x1 + ', y ' + T0.y0 + ' to ' + T0.y1 + ' (the far edge 14 rows over each sitter\'s feet, the near edge 11 rows under them); top: its corners on the screen, far left, far right, near right, near left' },
    sillas: { world: F.CHAIRS.map(c => W4([c.x - F.CH.hw, c.y - F.CH.hd, 0, c.x + F.CH.hw, c.y + F.CH.hd, F.CH.ZB])), seat: F.ZS, what: 'the four chairs along the table\'s far side: each seat at z ' + F.ZS + ', its middle .14 behind the sitter\'s lap; the back along its far edge up to z ' + F.CH.ZB },
    laps: { world: F.LAPS.map(l => W4([l[0], l[1], F.ZS])), screen: OLD.SILLA.map((x, i) => [x, D.SY[i] - 8]), what: 'each sitter\'s lap (x, y - 8 of their feet row) on their seat' },
    mostrador: { world: W4([0, F.A0, 0, F.K.CD, F.A1, F.K.CZ]), what: 'the counter along the left wall (cocina-kit cocinaBase): from y ' + F.A0 + ' (its right end, at the old counter\'s right end on the screen) off the picture; its top at z ' + F.K.CZ },
    estufa: { world: W4([F.STX, 0, 0, F.STX + F.K.STW, F.K.SD, F.K.CZ]), what: 'the stove on the back wall (cocina-kit cocinaStove: hob with two burners, knobs, oven door), its hood and the dark panel behind it; the counter beside it off the picture\'s right edge' },
    puerta: { world: W4([0, F.DOOR.a0, 0, 0, F.DOOR.a1, F.DOOR.z1]), what: 'the doorway to the yard in the left wall (the old door at the picture\'s left edge), the patio seen through it' },
    ventana: { world: W4([F.WIN.a0, 0, F.WIN.z0, F.WIN.a1, 0, F.WIN.z1]), what: 'the small window in the back wall, the patio\'s bush outside (the old window over the stove: here left of the stove\'s hood)' },
    paso: { world: F.WALK.y, row: 'PASO(x) = round(' + D.PK + ' + x / 2)', what: 'the walkway behind the chairs: the world line y = ' + F.WALK.y + ', from the doorway (PUERTA) along x' },
    corazon: { screen: [124, 22], what: 'heartAt: unchanged' },
  };

  /* things: the 19 touch keys */
  const T = (name, what, parts) => { const s = pxBox(partPx(parts)), b = [s[0], s[1], s[2], s[3]]; return { set: true, box: b, screen: b, what, old: { box: OLDBOX[name] } }; };
  const sprite = why => ({ sprite: true, why });
  const things = {
    luis: sprite('a person (today\'s sprite, drawn 1:1). caja(id) (mesa.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand; whoever sits: down to their feet row + 1 (moves)'),
    carmen: sprite('as luis'), abuelo: sprite('as luis'), mama: sprite('as luis'), papa: sprite('as luis'), abuela: sprite('as luis'),
    platos: sprite('the plates on the counter (enMostr): [EN.platos - (12, 18), 24, 22]: EN moved onto the counter\'s top (moves)'), tazas: sprite('as platos (EN.tazas)'), bandeja: sprite('as platos (EN.bandeja)'),
    comidas: sprite('the plates of food on the counter: [EN.comidas - (15, 16), 30, 18] (EN moved)'), vasos: sprite('the glasses on the counter: [EN.vasos - (9, 18), 19, 20] (EN moved)'),
    muestra: sprite('the thing lifted off the counter to be looked at: relative to EN (moved with it)'), ofrece: sprite('what abuela holds out: relative to her'), bebe: sprite('mamá\'s baby: relative to her'),
    perro: sprite('Canelo (KIT.mkPerro): [x - 14, y - 20, 28, 22] where he is'),
    olla: sprite('the pot on the stove: [ESTUFA[0] + 1, ESTUFA[1] - 16, 26, 20] moved with the pot (moves: line ' + lineOf('{id:"olla",si:') + ')'),
    mesa: T('mesa', 'the table, its cloth and its four chairs', ['mesa', 'mesa.patas', 'sillas', 'sillas.patas']),
    estufa: T('estufa', 'the stove: its hob, front, oven door, its hood and the panel behind it', ['estufa', 'campana']),
    cocina: { set: true, ground: true, box: [22, 0, 196, 216], what: 'the kitchen: the floor, the walls, the door, the window, the counters and the wall cupboard; last in the hit order', old: { box: OLDBOX.cocina } },
  };
  // the pot's touch box follows the pot (the old one is relative to ESTUFA)
  const OB = [OLD.ESTUFA[0] + D.ST.olla[0] - 12, OLD.ESTUFA[1] + D.ST.olla[1] - 19, 26, 20];
  things.olla.box = OB;
  { const b = things.cocina.box, x0 = Math.max(b[0], 22 + 14), y0 = Math.max(b[1], 14), x1 = Math.min(b[0] + b[2], 22 + 196 - 14), y1 = Math.min(b[1] + b[3], 216 - 14); things.cocina.hintBox = [x0, y0, x1 - x0, y1 - y0]; things.cocina.hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches'; }
  things.cocina.hand = [60, 150]; things.cocina.handWhy = 'on the floor in front of the counter';
  for (const k of ['mesa', 'estufa']) { const b = things[k].box, inV = [Math.max(b[0], 22 + 14), Math.max(b[1], 14), Math.min(b[0] + b[2], 22 + 196 - 14), Math.min(b[1] + b[3], 216 - 14)];
    if (inV[0] !== b[0] || inV[1] !== b[1] || inV[2] !== b[0] + b[2] || inV[3] !== b[1] + b[3]) { things[k].hintBox = [inV[0], inV[1], inV[2] - inV[0], inV[3] - inV[1]]; things[k].hintWhy = 'hintBox: the part of its touch box the hint frame shows (2 px inside the view)'; } }
  things.mesa.hand = [R(D.SY[1] ? (OLD.SILLA[1] + OLD.SILLA[2]) / 2 : 140), R((D.SY[1] + D.SY[2]) / 2 + 6)]; things.mesa.handWhy = 'on the table\'s top between the second and third places';
  { const b = things.estufa.box; things.estufa.hand = [R(b[0] + b[2] * .35), R(b[1] + b[3] * .7)]; things.estufa.handWhy = 'on the stove\'s front, at its oven door'; }

  const views = { wide: { zoom: 1, x0: 22, world: W4(E.atZ(120, 150, 0)), region: null, old: [22, 0, 196, 216], what: 'the kitchen: the counter and the wall cupboard at the left, the doorway, the table with its four chairs in the middle, the window, the stove at the right' } };

  /* the review and level pictures */
  const pic = (cx, cy, zoom, what, extra) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, R(cx - 98))), Math.max(0, Math.min(112, R(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, R(cx - 49))), Math.max(0, Math.min(164, R(cy - 26))), 98, 52];
    const w = topW(cx, cy); return Object.assign({ world: w.world, screen: [cx, cy], zoom, crop, what }, extra || {}); };   // (extra.crop: the window found for it)
  const PICS = designPictures(pic, D);
  const LEVEL = PAIRS.level.flatMap(L => L.pictures.map((p, i) => p.scene === 'mesa' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* remap: every distinct position of positions.json, and the story positions order 06 did not list (h-mesa) */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const placeOf = (p, ats) => { const mv = STORY.find(m => m.old[0] === p[0] && m.old[1] === p[1] && (!m.uses || ats.some(a => m.uses.some(u => a.includes(u))))), at = mv ? mv.new : p;
    const isFrog = ats.every(a => /\.cq$/.test(a) || /beats\.53$/.test(a)), isSit = !isFrog && ats.some(a => /gente\.\w+$|beats\.\d+$/.test(a)) && p[1] === 150, isTop = ats.some(a => /cosas\.\d+$/.test(a));
    const w = isFrog ? frogW(at) : isSit ? seatW(at[0], at[1]) : isTop ? topW(at[0], at[1] - 1) : placeW(at);
    return { mv, at, w, what: (isFrog ? 'the frog\'s place q: the floor under (x + 16, y + 25)' : isSit ? 'sitting at the table: the seat under the lap (x, y - 8)' : isTop ? 'a thing on the table\'s top: the top under (x, y - 1)' : 'a place (x, y): the floor under (x, y - 1)') + (mv ? '; moved (why)' : '; the same screen place') }; };
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
      const q = placeOf([p.x, p.y], p.uses.map(u => u.file + ' ' + u.at));
      if (q.mv && q.mv.scene) { e.to = { scene: q.mv.scene, spot: q.mv.spot }; e.new = q.at.slice(); e.moved = true; e.why = q.mv.why; e.what = 'a place in another scene\'s picture (pictures cocina.no)'; return e; }
      e.to = { [q.w.on]: q.w.world }; e.new = q.at.slice(); if (q.mv) { e.moved = true; e.why = q.mv.why; } e.what = q.what;
    }
    return e;
  });
  // h-mesa (newer than order 06's inventory): its own places, read from its file
  const storyPlaces = [];
  for (const r of runs.filter((r, i, a) => a.findIndex(q => q.story.id === r.story.id) === i)) { if (POS.positions.some(p => p.uses.some(u => u.file === 'cuentos/' + r.story.id + '.json'))) continue;
    const found = new Map(); const walk = (o, pth) => { if (Array.isArray(o)) o.forEach((v, i) => walk(v, pth + '.' + i)); else if (o && typeof o === 'object') { if (typeof o.x === 'number' && typeof o.y === 'number') { const k = o.x + ',' + o.y; if (!found.has(k)) found.set(k, []); found.get(k).push(pth.slice(1)); } for (const [k, v] of Object.entries(o)) walk(v, pth + '.' + k); } };
    walk(r.story, '');
    for (const [k, ats] of found) { const [x, y] = k.split(',').map(Number), q = placeOf([x, y], ats.map(a => r.story.id + '.json ' + a)); storyPlaces.push(Object.assign({ kind: 'point', old: [x, y], uses: ats.map(a => r.story.id + '.json ' + a), to: { [q.w.on]: q.w.world }, new: q.at.slice() }, q.mv ? { moved: true, why: q.mv.why } : {}, { what: q.what + ' (' + r.story.id + ', not in positions.json: read from the story file)' })); } }

  // hop counts: every pair of the frog's places, old against new
  const hop = d => d < 3 ? 0 : Math.max(1, Math.min(3, R(d / 40)));   // mesa.js ranaA: round(d / 40), 1 to 3
  const FP = {}; for (const [k, v] of Object.entries(SPOTS)) if (v.scale != null || /^rana\./.test(k)) FP[k] = { old: v.old, q: v.new };
  const hopsAll = [], names = Object.keys(FP).sort();
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) { const a = FP[names[i]], b = FP[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hopsAll.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) }); }
  const hops = hopsAll.filter(h => h.old !== h.new);
  const lugar = {}; for (const [k, v] of Object.entries(OLD.LUGAR)) lugar[k] = { spot: 'frog.' + k, q: SPOTS['frog.' + k].new, scale: v[2], old: v.slice(0, 2) };

  const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSidesOf()) if (!(ps.w === 'cocina' && ps.side === 'no')) reached.add(keyOf(pairW(ps, { remap: [] }, true)));
  const setKey = {
    params: { mantel: 'W.mantel ? 1 : 0', horno: 'W.estufa && W.estufa.horno ? 1 : 0' },
    key: '"m" + mantel + "h" + horno',
    baked: ALL_STATES.filter(k => reached.has(k)).map(k => ({ key: k, query: '?' + queryOf(k) })),
    notReached: ALL_STATES.filter(k => !reached.has(k)),
    bakedWhy: 'order 06 found 141 states made by eleven set keys. Two are the set\'s: mantel (the white cloth on the table) and estufa.horno (the oven lit: its window glows; one review picture). afuera (the stall, one review picture) swaps the whole background: that picture is El colmado\'s stall (pictures cocina.no), not a state of this set. The other eight are what the sprite layer draws, as the old: bandeja (what lies in the tray), encima (what the frog carries on his head), estufa\'s olla, tapa, vapor, bizcocho, jarra and pastel (on the stove\'s top), mostrador (the stacks on the counter), puestos (what stands at each place and what is spilt), reb (the slices on abuela\'s board), sitio (who sits where: their places), suelo (what lies on the floor), vierte (the jug that pours)',
    spriteKeys: { bandeja: 'draw(): the tray\'s spoon, fork and knife', encima: 'rana(): what he carries on his head', estufa: 'draw(): what stands on the stove (olla, tapa, vapor, bizcocho, jarra, pastel; horno is the set\'s)', mostrador: 'draw(): the stacks on the counter (EN, moved)', puestos: 'draw(): at the table\'s entry in the sorted list, each place\'s plate and cup and what is spilt in front (FILA + SD, FRENTE + SD)', reb: 'gente(): the slices on abuela\'s board', sitio: 'which chair each sitter has (SILLA, SD)', suelo: 'draw(): what lies on the floor', vierte: 'draw(): the jug pouring' },
  };

  return {
    scene: 'mesa',
    made: 'node docs/proyecto/pixel/mesa-sheet-make.js, from mesa-set.html (window.MESA_SET), cocina-kit.js and coqui/ref/escenas/mesa/. Order 37a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its pixels or of the 8 projected corners of its world box',
      floor: 'the kitchen is built round the old picture: a place keeps its screen place and its world point is the surface under it: the floor (z 0), the table\'s top (z ' + F.ZT + '), the counter\'s or the stove\'s top (z ' + F.K.CZ + '): a frog place q under (q.x + 16, q.y + 25); a person\'s, the dog\'s or a thing\'s place (x, y) under (x, y - 1). Whoever sits (sent) is on a chair: their world point the seat under their lap (x, y - 8, z ' + F.ZS + '), their feet row 150 + SD[i] (moves). So every position of mesa.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each one (spots, remap, storyPlaces, code) with its world point',
      relative: 'what the old code draws or moves relative to a person, the frog or the dog (what is carried, raised, held out, poured; a frog place by whoever he serves; the bubbles and the thoughts) keeps its offsets: a sitter\'s moved feet move what is relative to them (caja, the thing in the hand, the cloth\'s pulled corner)',
      sky: 'screen-space effects keep their old numbers: the stars of the endings, the heart (heartAt)',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were',
      kit: 'the room is cocina-kit.js\'s (written with this set, shared with La estufa and La nevera): its floor, walls, tile band, counters, wall cupboard, window, stove, hood, the panel behind the stove, its light and its cut-open build (cocinaBuild)',
    },
    layout: {
      what: 'abuela\'s kitchen cut open as La sala: two walls stand (the left wall along y, the back wall along x), the floor (the old red and cream checker, laid on the axes) runs off the picture; along the left wall the counter (cupboards with the white top, the tile band behind it) and the wall cupboard over it, then the doorway to the yard; on the back wall the small window (the patio\'s bush outside), the stove with its hood and the dark panel behind it, the counter beside it running off the right edge, the tile band behind both; the table in the middle along x, its long side to the camera, the four chairs along its far side',
      why: 'the brief and page 11 decision 9: the set stands on the world\'s axes, nothing square to the camera. The old picture was flat: its table, chairs, counter and stove stood in level rows. The table runs along x, so its far side falls half a row a px to the right: the four seats step down by SD (moves), the least that keeps them in their old order and every place in front of the table on clear floor; whoever comes to sit comes in at the doorway and walks behind the chairs (the old walked behind the table along row 152). The counter runs along the left wall, so its top falls half a row a px to the left: each stack on it moved onto the top by the least distance (EN). The stove stands at the right edge as the old, its things on its top (moves)',
      walls: { cut: F.K.WH, thick: F.K.T, back: 'y = 0, x from 0 to ' + F.XR, left: 'x = 0, y from 0 to ' + F.YL },
    },
    behind: { what: 'nothing: the set has no sky', items: [] },
    setKey,
    things,
    spots: SPOTS,
    lugar,
    hops,
    hopsWhat: 'each pair of the frog\'s places (LUGAR, the places at each seat and those the acts and the stories give him) whose hop count (mesa.js ranaA: round(d / 40), 1 to 3, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all ' + hopsAll.length + ' pairs)',
    hopsAll,
    points: PTS,
    views,
    remap,
    storyPlaces,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'mesa.js never calls clip()',
    front: {
      how: 'the old table (mkMesa) was drawn in the sorted list at y MESA[1] + MESA[3] + 6 (166), over whoever sat behind it; its chairs, counter and stove were the background. Now the table, its chairs, the counters and the stove are set things someone can be behind. Every item of the sorted list owns the pixels it drew last; at each front entry (sortY 9999: after everyone) the set\'s own pixels of that part (mesa-set.html part(), PART_TAGS) are drawn again where their owner stands behind them: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the owner\'s plane: whoever sits, their lap on the seat (x, y - 8, z ' + F.ZS + ') + .03; anyone else, the floor under their foot (x, y - 1); the frog, the floor under (b.x + b.w / 2, q.y + 25); what stands on a top is never drawn over (the places at the table: their entry; the stacks on the counter and the stove are drawn before the list). "Behind the table" is that depth test, not a row',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      chairs: 'a chair is never drawn over whoever sits (they sit on it, its back behind them)',
      parts: Object.fromEntries(FRONT.map(p => [p, { sortY: 9999, insert: 'before the sort: L.push({y: 9999, front: "' + p + '"})', why: { mesa: 'whoever sits behind the table, or walks behind it: the table\'s top drawn over their lower part', 'mesa.patas': 'its legs', sillas: 'whoever walks behind the chairs: their backs drawn over their legs', 'sillas.patas': 'their legs', mostrador: 'whoever stands behind the counter\'s end: none in the stories', mostrador2: 'as mostrador', estufa: 'whoever stands behind the stove: none in the stories', pared: 'whoever stands outside on the step (PUERTA, round 2): the left wall drawn over what of them is behind it, so they are seen in the opening', puerta: 'as pared: the door\'s frame and reveal over whoever stands outside (the patio and the backdrop are behind them: the depth test keeps them under)', 'puerta.umbral': 'the threshold over the feet of whoever stands outside on the step', 'puerta.jamba': 'the wall\'s thickness in the opening, where it stands before whoever is outside' }[p] }])),
      tags: [
        ['L.push({y:p.z!=null?p.z:p.y,d:()=>gente(c,id,a)});', 'L.push({y:p.z!=null?p.z:p.y,id,d:()=>gente(c,id,a)});'],
        ['if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:', 'if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,k:"perro",d:'],
        ['if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});', 'if(q.vis)L.push({y:q.y+27,id:"coqui",d:()=>rana(c,q,a)});'],
        ['if(!W.afuera)L.push({y:MESA[1]+MESA[3]+6+SD[3],d:()=>{', 'if(!W.afuera)L.push({y:MESA[1]+MESA[3]+6+SD[3],mesa:1,d:()=>{'],
        ['(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>', '(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,cosa:o,d:()=>'],
        ['(W.suelo||[]).forEach(o=>L.push({y:o.y-4,d:()=>', '(W.suelo||[]).forEach(o=>L.push({y:o.y-4,cosa:o,d:()=>'],
      ],
      tagsWhat: 'each item of the sorted list says what it is (the front masks read it), in mesa.js with the moves applied; nothing else changes',
    },
    shadows: {
      rule: 'the kitchen\'s one light (cocina-kit): from the upper left, every shadow cast to screen right from the ground point under the thing\'s feet (unproject), low and joined to it; on the floor only',
      coqui: { radius: .45, at: 'unproject(b.x + b.w / 2, q.y + 25)', when: 'W.cq.vis and al > .5', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { adulto: .34, nino: .3 }, at: 'unproject(x, y - 1)', when: 'standing on the floor (not sitting: whoever sits is under the table\'s top), visible (vis !== 0, al > .5)', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r)' },
      perro: { radius: .32, at: 'unproject(x, y - 1)', when: 'W.perro shown', cast: 'castShadow(g.x, g.y, .25, .32)' },
      cosas: { radius: .18, at: 'unproject(x, y - 1)', when: 'a thing lying on the floor (W.cosas with no z, W.suelo)', cast: 'castShadow(g.x, g.y, .05, .18)' },
      dropped: 'none of the old code\'s own: mesa.js draws no shadow',
    },
    dropped: DROPPED,
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines.length > 1 ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.pts && m.pts.length ? { places: m.pts.map(q => ({ who: q[0] || 'whoever', old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    storyMoves: STORY,
    helps: { what: 'none: nothing is painted round an empty place; the set needs no help for a sprite-layer thing', lines: [] },
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as mesa.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (mesa.js draw: line ' + lineOf('Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a person, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible person\'s and the frog\'s, its own too); if none is, the first (the old)',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1',
      faces: 'a face: [hx - 6, top + 6, 12, 10] (eyes to chin), top the sprite\'s first opaque row, hx the middle of its top 10 rows; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      board: BOARD, boardWhat: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta (the rounds card) [2, 2, 68, 26], hidden while three picture bubbles stand at the top (hud)',
    },
    code: codeEntries(MOVES, DROPPED, things, D),
    checks: { notes: [] },
  };
}

// the story files' own places that move: whoever sits (the seats step: SD), a thing on the table's top, someone standing where the table now is
function designStoryMoves(E, F, D) {
  const out = [];
  OLD.SILLA.forEach((x, k) => out.push({ old: [x, 150], new: [x, D.SY[k]], who: 'sitting', why: 'sitting at place ' + k + ' (x ' + x + '): on its chair (150 + SD[' + k + '])' }));
  // a thing put on the table in a review picture (cosas, z 300): the least move that puts its foot on the table's top
  const onT = (x, y, hw) => E.onTop(x, y - 2.5, 'mesa', .02) && E.onTop(x, y + .5, 'mesa', .02) && E.onTop(x - hw, y - .5, 'mesa', 0) && E.onTop(x + hw, y - .5, 'mesa', 0);
  const leastT = (x, y, hw) => { for (let r = 0; r <= 40; r++) { let best = null; for (let mx = -r; mx <= r; mx++) for (let my = -r; my <= r; my++) { if (Math.max(Math.abs(mx), Math.abs(my)) !== r) continue; if (onT(x + mx, y + my, hw) && (!best || Math.hypot(mx, my) < Math.hypot(best[0], best[1]))) best = [mx, my]; } if (best) return [x + best[0], y + best[1]]; } throw new Error('no place on the table for ' + x + ',' + y); };
  // (round 2) pone: the plate set down and the little cloth, from there the least further move that puts a plain surface (the cloth's top) round
  // half the thing's outline at least (a search over every point within 16 px); the plate beside the cloth moves with it
  const R2N = { '187,150': [[173, 159], 'pone.si: the plate set down (by the cloth\'s edge: 44% plain round it)'], '178,150': [[167, 158], 'pone.no: the plate beside the cloth, moved with it'], '187,151': [[172, 160], 'pone.no: the little cloth (by the cloth\'s edge: 30% plain round it)'] };
  for (const [p, hw, what] of [[[140, 152], 6, 'the vase'], [[140, 153], 11, 'the whole cake'], [[187, 150], 6, 'the plate set down'], [[178, 150], 6, 'the plate'], [[187, 151], 5, 'the cloth']]) {
    const n = leastT(p[0], p[1], hw), r2n = R2N[p.join()];
    if (r2n) { out.push({ old: p, new: r2n[0], who: 'cosa', uses: ['cual-mesa.json'], why: 'cual-mesa: ' + what + ' on the table\'s top (round 1: ' + n.join(', ') + ', the least move onto the top); round 2, ' + r2n[1] + ': the least move from there that puts the cloth\'s plain top round half its outline' }); continue; }
    if (n[0] !== p[0] || n[1] !== p[1]) out.push({ old: p, new: n, who: 'cosa', uses: ['cual-mesa.json'], why: 'cual-mesa: ' + what + ' on the table\'s top: moved by the least distance that puts it on the top (the table along x falls half a row a px to the right)' }); }
  // someone standing (a review picture) where the floor is not clear: the least move to clear floor in front of it
  const clearFoot = (x, y) => [-6, 0, 6].every(dx => E.clearFloor(x + dx, y - 1, .12)) && E.clearFloor(x, y - 4, .12);
  const leastF = (x, y) => { for (let r = 0; r <= 40; r++) { let best = null; for (let mx = -r; mx <= r; mx++) for (let my = -r; my <= r; my++) { if (Math.max(Math.abs(mx), Math.abs(my)) !== r) continue; if (clearFoot(x + mx, y + my) && (!best || Math.hypot(mx, my) < Math.hypot(best[0], best[1]))) best = [mx, my]; } if (best) return [x + best[0], y + best[1]]; } throw new Error('no clear floor near ' + x + ',' + y); };
  for (const [p, what] of [[[176, 172], 'cual-mesa cocina.si: abuela in the kitchen, by the stove'], [[206, 165], 'cual-mesa pone: Carmen setting a plate on the table'], [[110, 206], 'cual-mesa: whoever holds up a thing']]) {
    const n = leastF(p[0], p[1]); if (n[0] !== p[0] || n[1] !== p[1]) out.push({ old: p, new: n, who: 'standing', uses: ['cual-mesa.json'], why: what + ': the old point is ' + (E.surface(p[0], p[1] - 1).under ? 'under the ' + E.surface(p[0], p[1] - 1).under : 'not clear floor') + '; moved by the least distance to clear floor' }); }
  // (round 2) whoever holds up a thing in a review picture: the least move (a search over the floor, every 4 px) that puts a plain surface round
  // half the held thing's outline at least, for all four (plato, taza, cuchara, tenedor: the same place, as the old): on the floor before the
  // back wall, the thing seen against its plaster; abuela with the knife or the spoon: before the stove, the thing against its white front
  out.push({ old: [110, 206], new: [144, 120], who: 'standing', uses: ['cual-mesa.json'], why: 'cual-mesa plato, taza, cuchara, tenedor (round 2): whoever holds up a thing stands on the floor before the back wall, left of the window, so the thing is seen against the plaster (at the old point, in front of the table, it was seen against the checker floor: 18 to 61% plain round it); the nearest such place to the old one (86 px), all eight pictures 58% plain and more' });
  out.push({ old: OLD.FOGON.slice(), new: [202, 154], who: 'standing', uses: ['cual-mesa.json'], why: 'cual-mesa cuchillo (round 2): abuela with the knife or the spoon stands before the stove, the thing seen against its white front (at FOGON, ' + D.FOGON.join(', ') + ', it was against the floor and the table: 6 to 20% plain round it); the nearest such place to FOGON (40 px)' });
  out.push({ old: [176, 176], new: [115, 203], who: 'abuela', uses: ['cual-mesa.json cocina.no'], scene: 'frutas', spot: 'abuela.delante', why: 'cual-mesa cocina.no (W.afuera: abuela outside, at a stall): the picture is El colmado\'s fruit stall (frutas, its spot abuela.delante: in front of the stand)' });
  return out;
}
// the review pictures (round 2: every one at zoom 2, as the old close pictures): each a 98 x 52 window (shown at 2 x 2: the 196 x 104 picture) on
// what the pair is about (thing: the W paths that draw it), the whole head of whoever holds it or stands by it inside (they may be cut by the
// window's lower or side edges); the windows found by a search over every place (the thing whole, the heads whole, the most plain round the thing)
// (the search: the window's top left corner; the two pictures of a pair share their window, but mesa's, whose two are of different things, as the old)
const PAIR_WIN = {'mesa.si': [91, 115], 'mesa.no': [142, 70], 'plato.si': [108, 72], 'plato.no': [108, 72], 'taza.si': [110, 68], 'taza.no': [110, 68], 'cuchara.si': [108, 55], 'cuchara.no': [108, 55], 'tenedor.si': [108, 55], 'tenedor.no': [108, 55], 'cuchillo.si': [134, 91], 'cuchillo.no': [134, 91], 'comida.si': [79, 113], 'comida.no': [79, 113], 'pone.si': [123, 122], 'pone.no': [123, 122], 'tengo_hambre.si': [93, 75], 'tengo_hambre.no': [93, 75], 'tengo_sed.si': [85, 102], 'tengo_sed.no': [85, 102], 'listo.si': [114, 110], 'listo.no': [114, 110]};
function designPictures(pic, D) {
  const PORTCROP = pic(118, 168, 1, '').crop.join(', ');   // (cocina.no: its window, the same pic() as below)
  const P = (nm, what, thing, extra) => { const w = PAIR_WIN[nm]; return pic(w[0] + 49, w[1] + 26, 2, what, Object.assign({ thing, crop: [w[0], w[1], 98, 52] }, extra || {})); };
  return {
    'mesa.si': P('mesa.si', 'the table with its cloth and a vase of flowers on it', ['cosas.0']), 'mesa.no': P('mesa.no', 'the stove with a steaming pot', ['estufa.olla', 'estufa.vapor']),
    'plato.si': P('plato.si', 'Luis holding up a plate', ['gente.luis.alza']), 'plato.no': P('plato.no', 'Luis holding up a cup', ['gente.luis.alza']),
    'taza.si': P('taza.si', 'Carmen holding up a cup of chocolate', ['gente.carmen.alza']), 'taza.no': P('taza.no', 'Carmen holding up a pot', ['gente.carmen.alza']),
    'cuchara.si': P('cuchara.si', 'abuelo holding up a spoon', ['gente.abuelo.alza']), 'cuchara.no': P('cuchara.no', 'abuelo holding up a fork', ['gente.abuelo.alza']),
    'tenedor.si': P('tenedor.si', 'papá holding up a fork', ['gente.papa.alza']), 'tenedor.no': P('tenedor.no', 'papá holding up a knife', ['gente.papa.alza']),
    'cuchillo.si': P('cuchillo.si', 'abuela by the stove holding up a knife', ['gente.abuela.alza']), 'cuchillo.no': P('cuchillo.no', 'abuela by the stove holding up a spoon', ['gente.abuela.alza']),
    'comida.si': P('comida.si', 'a plate of hot food at a place on the table', ['puestos.1.plato']), 'comida.no': P('comida.no', 'two empty plates at that place', ['puestos.1.plato']),
    'cocina.si': pic(170, 134, 1, 'abuela in the kitchen by the stove, a pot steaming', { thing: ['estufa.olla'], zoom1: 'zoom 2 cannot hold it: the pot with its steam (25 rows) and abuela\'s whole head by the stove need 55 rows of a 52-row window; and its other picture, cocina.no, is El colmado\'s stall at zoom 1' }),
    'cocina.no': pic(118, 168, 1, 'abuela outside at a fruit stall (El colmado\'s stall: frutas-set.html?surtido=frutas)', { scene: 'frutas', query: '?surtido=frutas', zoom1: 'another scene\'s picture, El colmado\'s stall, drawn whole as its page draws it',
      port: 'El colmado is ported later: until then the port draws this picture from the web page itself. File docs/proyecto/pixel/frutas-set.html with the query ?surtido=frutas (its canvas, 240 x 216, as the page draws it: no state of mesa-set.html, no mesa sprite but abuela); the window: crop [' + PORTCROP + '] at zoom 1 (the 196 x 104 picture, as the picture\'s crop here and mesa-preview.html draw it); abuela: the sprite layer of mesa.js (W.afuera 1, gente.abuela with dir -1 as cual-mesa.json gives) at frutas\'s spot abuela.delante, screen (115, 203) (storyMoves: old 176, 176), her feet there; nothing else of mesa.js is drawn (its old stall, mkPuesto, is dropped). When El colmado is in Dart, its set at that state and that spot replace the page' }),
    'pone.si': P('pone.si', 'Carmen at the table\'s end, a plate set on it', ['cosas.0']), 'pone.no': P('pone.no', 'Carmen at the table\'s end, a plate and a cloth on it', ['cosas.1']),
    'tengo_hambre.si': P('tengo_hambre.si', 'Luis at the table thinking of food', ['gente.luis.piensa']), 'tengo_hambre.no': P('tengo_hambre.no', 'Luis at the table thinking of water', ['gente.luis.piensa']),
    'tengo_sed.si': P('tengo_sed.si', 'Carmen at the table drinking', ['gente.carmen.hace'], { plainKnown: 'the glass is at her mouth: round it her face and hair, which are hers (left out), and the chair\'s back behind her, as the old' }),
    'tengo_sed.no': P('tengo_sed.no', 'Carmen at the table eating', ['gente.carmen.hace'], { plainKnown: 'the fork is at her mouth: round it her face, which is hers (left out), and the chair\'s back behind her, as the old' }),
    'listo.si': P('listo.si', 'a whole cake on the table', ['cosas.0']), 'listo.no': P('listo.no', 'the oven lit, something baking', ['estufa.horno']),
  };
}

/* ---------- code: every line of mesa.js that holds a number, and what each number is ----------
   The maker reads mesa.js itself (not order 06's inventory): it finds every numeric literal outside comments and strings, sorts each by what it is
   from where it stands (a place on the picture; an offset from someone; a time, a sound, a count; a draw order; a sprite's or a sign's own
   drawing), and the sheet names, line by line, what becomes of its places (moved, the floor rule, a set thing, dropped). check() fails if a line
   with a place has no entry, or an entry misses one of its place numbers */
const REGIONS = (() => {
  const at = s => lineOf(s), out = [];
  const r = (a, b, kind, why) => out.push({ a, b, kind, why });
  r(at('function fondo(){'), at('return b.done();}'), 'dropped', 'the background (fondo): the set, dropped');
  r(at('function mkPuesto(){'), at('function mkPuesto(){') + 3, 'dropped', 'the stall (mkPuesto, W.afuera): El colmado\'s stall (pictures cocina.no), dropped');
  r(at('function mkMesa(mantel){'), at('function mkMesa(mantel){') + 4, 'dropped', 'the old table\'s sprite (mkMesa): the set\'s table and cloth, dropped');
  r(at('const COSA={'), at('const cosa=(k,c)=>'), 'drawing', 'a thing\'s own sprite (plates, cups, glasses, spoons, cakes, the jug, the tray, the messes): its own drawing, unchanged');
  r(at('function tenida('), at('const BX={'), 'drawing', 'a thing drawn at its foot, a plate or cup with what is in it, steam over it: relative to where it is drawn, unchanged');
  r(at('function nube(g,x,y,o)'), at('function nube(g,x,y,o)'), 'drawing', 'a thought bubble: relative to the head, unchanged');
  r(at('function rana(g,q,a)'), at('function bub2(c,k,tx,ty,a)'), 'drawing', 'the frog and what he carries on his head; the bubble drawn twice its size: relative, unchanged');
  r(at('function respIcon('), at('function respIcon('), 'drawing', 'a picture bubble\'s icon (twice its size): relative, unchanged');
  r(at('function hud(g,W,a){'), at('const marca=m=>'), 'drawing', 'the rounds card in the corner (hud): screen space, unchanged (talk.board)');
  r(at('async function stake('), at('const estado=W=>') + 2, 'other', 'stake, poke and estado: no place');
  return out;
})();
const regionOf = L => REGIONS.find(r => L >= r.a && L <= r.b);
const stripLine = l => l.replace(/\/\/.*$/, '').replace(/"(?:[^"\\]|\\.)*"/g, '""');
const numsOf = l => { const out = []; const re = /(?<![\w#.$])(\d+\.\d+|\d+|\.\d+)(?![\w])/g; let m; while ((m = re.exec(l))) out.push({ n: m[1], at: m.index }); return out; };
function numKind(l, at, n) {
  const before = l.slice(Math.max(0, at - 40), at), after = l.slice(at + n.length, at + n.length + 6);
  if (/(wait|setTimeout)\($/.test(before) || /TICK\*$/.test(before) || /SFX\.\w+\($/.test(before) || /\(F>>$|F>>$|F%$/.test(before)) return 'time';
  if (/[<>]=?\s*$|===?\s*$|!==?\s*$|%\s*$|Math\.(min|max)\(\s*$|\|\|\s*$|\?\s*$|>>\s*$|<<\s*$|\.length\s*[<>]=?\s*$|\bs<=?\s*$|\bi<=?\s*$|\bj<\s*$|\bk<\s*$/.test(before)) return 'count';
  if (/\bz:\s*-?$/.test(before)) return 'order';
  if (/\b(dy|al|s|vis|sent|paso|dir|n|i|reb|choc|contado|mantel|bebe|cola|olla|tapa|vapor|bizcocho|jarra|pastel|platos|tazas|jarron|bandeja|alza|tiron|lio|plano|g|horno|comidas|vasos)\s*[:=]\s*-?$/.test(before) || /\.dy\s*=\s*-?$|[+-]=\s*$/.test(before)) return 'state';
  if (/\*\s*$|Math\.sin\([^()]*$|Math\.cos\([^()]*$|Math\.hypot\([^()]*$|\/\s*$/.test(before) || /^\s*\*/.test(after)) return 'scale';
  if (/\b[xy]\s*:\s*-?$|\b[xy]\s*:\s*\w[\w.\[\]()]*\s*[+-]\s*$|\.[xy]\s*=\s*-?$/.test(before)) return /[+-]\s*$/.test(before) && !/:\s*-$|=\s*-$/.test(before) ? 'offset' : 'place';
  if (/(mueve|ranaA|perroA|hopTo|vuela|tenida|conTodo|fr|bub2|nube)\([^()]*$/.test(before)) return /[+-]\s*$/.test(before) && !/[(,]\s*-$/.test(before) ? 'offset' : 'place';
  if (/\[\s*-?$|\[\s*\d+\s*,\s*-?$|\],\s*\[\s*-?$|,\s*-?$/.test(before) && /^\s*[,\]]/.test(after)) return 'place';
  if (/[+-]\s*$/.test(before)) return 'offset';
  return 'other';
}
function codeEntries(MOVES, DROPPED, things, D) {
  const C = [];
  for (let L = 1; L <= LINES.length; L++) {
    const raw = LINES[L - 1], l = stripLine(raw), ns = numsOf(l); if (!ns.length) continue;
    const reg = regionOf(L), kinds = {}; for (const { n, at } of ns) { const k = reg ? reg.kind : numKind(l, at, n); (kinds[k] = kinds[k] || []).push(n); }
    const mv = MOVES.filter(m => (m.lines || [m.line]).includes(L)), dr = DROPPED.filter(d => d.line === L);
    const e = { line: L, numbers: kinds };
    if (dr.length) { e.to = { dropped: true }; e.note = dr.map(d => d.why).join('; ') + (mv.length ? '; moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; ') : ''); if (mv.length) e.to.moves = mv.map(m => m.src); }
    else if (mv.length) { e.to = { moves: mv.map(m => m.src) }; e.note = 'moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; ') + (kinds.place ? '; every other place here keeps its screen place (the floor rule)' : ''); }
    else if (reg) { e.to = reg.kind === 'dropped' ? { dropped: true } : 'unchanged'; e.note = reg.why; }
    else if (kinds.place) { e.to = { floor: true }; e.note = 'places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)'; }
    else { e.to = 'unchanged'; e.note = 'no place: ' + Object.keys(kinds).join(', '); }
    C.push(e);
  }
  const set = (L, to, note) => { const e = C.find(q => q.line === L); if (!e) throw new Error('code: no numbers on line ' + L); e.to = to; e.note = note; };
  set(lineOf('const PISO=142,MESA='), { moves: ['FILA=148,FRENTE=157;'], points: ['mesa', 'sillas', 'mostrador', 'estufa'], spots: ['silla.0', 'silla.1', 'silla.2', 'silla.3', 'puesto.0', 'frente.0'] }, 'PISO (the old floor\'s first row): the set\'s floor; MESA: the table (the set\'s, points.mesa: its box things.mesa; its far edge for a sitter\'s hand and the cloth\'s pulled corner: relative to the sitter, moves); SILLA: the seats\' x, unchanged, their rows 150 + SD (moves); MOSTR: the counter (the set\'s, points.mostrador; EN moved onto its top); ESTUFA: the stove (the set\'s, points.estufa; its things moved onto its top, moves); FILA, FRENTE: the rows at each place, + SD (moves)');
  set(lineOf('const EN={platos:'), { moves: [MOVES.find(m => m.src.startsWith('const EN={')).src], spots: Object.keys(OLD.EN).map(k => 'mostrador.' + k) }, 'EN: where each kind of thing stands on the counter: moved onto its top (moves)');
  set(lineOf('const LUIS=[75,160],FOGON='), { spots: ['luis', 'fogon', 'canelo'] }, 'LUIS, FOGON, CAN: the floor rule, the same screen places (spots)');
  set(lineOf('const LUGAR={inicio:'), { spots: ['frog.inicio', 'frog.centro'] }, 'the floor rule: the same screen places, in front of the table');
  set(lineOf('const alto=id=>'), 'unchanged', 'heights of the sprites (alto), not places');
  set(lineOf('const enMostr=k=>'), 'unchanged', 'a counter stack\'s box relative to EN: unchanged (EN moved)');
  set(lineOf('{id:"muestra",si:'), 'unchanged', 'the shown thing\'s, abuela\'s offer\'s, the baby\'s and the dog\'s boxes: relative, unchanged');
  set(lineOf('{id:"olla",si:'), { things: ['olla', 'mesa', 'estufa'] }, 'the pot\'s box (moved with the pot: things.olla), the table\'s and the stove\'s (the set\'s: things.mesa, things.estufa)');
  set(lineOf('{id:"cocina",box:'), { things: ['cocina'] }, 'the kitchen\'s box: unchanged, its hint box (things.cocina.hintBox)');
  set(lineOf('const cx=()=>W.cq.x+16'), 'unchanged', 'the frog\'s middle and feet relative to q: unchanged');
  set(lineOf('async function ranaA('), 'unchanged', 'ranaA: q relative to the point; the hop count by the distance (40 px a hop): unchanged');
  set(lineOf('KIT.escena({id:"mesa"'), { view: 'wide', point: 'corazon' }, 'the view (views.wide) and the heart (points.corazon): unchanged');
  set(lineOf('fresh:()=>({respEn:'), 'unchanged', 'respEn (where the answer cards stand), the frog\'s home and first place: unchanged');
  const dl = DROPPED.map(d => d.line); for (const e of C) if (dl.includes(e.line) && !(e.to && e.to.dropped)) e.to = Object.assign({ dropped: true }, typeof e.to === 'object' ? e.to : {});
  C.push({ line: 'juego.js:16', to: 'unchanged', note: 'fresh(): not used here: mesa\'s fresh() puts the frog at (104, 161)' });
  C.push({ line: 'cual.js:21', to: 'unchanged', note: 'panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)' });
  return C;
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([Math.round(hp[0]) - 12 + i * 3, Math.round(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };
const handBox = hp => [R(hp[0]) - 12, R(hp[1]), 36, 45 + 9];
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));
// WCAG's relative luminance and contrast ratio
const lum = c => { const f = u => { u /= 255; return u <= .03928 ? u / 12.92 : ((u + .055) / 1.055) ** 2.4; }; return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2]); };
const contrast = (a, b) => { const la = lum(a), lb = lum(b); return (Math.max(la, lb) + .05) / (Math.min(la, lb) + .05); };
const OUTC = (() => { const h = fs.readFileSync(path.join(REPO, 'historia/engine.js'), 'utf8').match(/OUT\s*=\s*"(#[0-9A-Fa-f]{6})"/); return [1, 3, 5].map(i => parseInt(h[1].slice(i, i + 2), 16)); })();
const SILLA = [104, 128, 152, 176];
// the sheet's rule for a W in old positions (the same as mesa-preview.html remapRule)
function remapW(sh, w0, story) {
  const w = JSON.parse(JSON.stringify(w0)), SD = JSON.parse(sh.moves[0].to.match(/SD=(\[[-\d,]+\])/)[1]);
  const MV = sh.moves.flatMap(m => m.places || []), RM = (sh.storyMoves || []).filter(e => !e.scene && (!e.uses || !story || e.uses.some(u => u.startsWith(story))));
  const find = (who, x, y) => RM.find(e => e.who !== 'sitting' && e.uses && e.old[0] === x && e.old[1] === y) || MV.find(q => (q.who === 'whoever' || q.who === who) && q.old[0] === x && q.old[1] === y) || RM.find(e => e.who !== 'sitting' && e.old[0] === x && e.old[1] === y);   // (round 2) a story file's own move first
  const mv = (who, p) => { const m = find(who, R(p.x), R(p.y)); if (m) { p.x = m.new[0]; p.y = m.new[1]; } };
  for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null) continue; if (p.sent) { const k = SILLA.indexOf(R(p.x)); if (k >= 0 && R(p.y) === 150) p.y = 150 + SD[k]; } else mv(id, p); }
  if (w.perro && w.perro.x != null) mv('perro', w.perro);
  for (const o of w.cosas || []) if (o && o.x != null) mv('cosa', o);
  if (w.muestra) mv('muestra', w.muestra);
  if (w.vierte) { let k = 0; for (let i = 1; i < 4; i++) if (Math.abs(w.vierte.x - SILLA[i]) < Math.abs(w.vierte.x - SILLA[k])) k = i; w.vierte.y += SD[k]; }
  if (w.cq) { const m = MV.find(q => q.who === 'cq' && q.old[0] === w.cq.x && q.old[1] === w.cq.y); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }
  return w;
}
const placesOf = w => { const o = {};
  for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)];
  if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y];
  if (w.perro && w.perro.x != null) o.perro = [R(w.perro.x), R(w.perro.y)];
  (w.cosas || []).forEach((c, i) => { if (c && c.x != null) o['cosa.' + (c.id || c.k + i)] = [R(c.x), R(c.y)]; });
  if (w.muestra) o.muestra = [R(w.muestra.x), R(w.muestra.y)];
  if (w.vierte) o.vierte = [R(w.vierte.x), R(w.vierte.y)];
  return o; };

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M, NEW = G.TICKS;
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];
  const STATES = Object.keys(G.parts);
  const TAGS = {}; for (const k of STATES) { const m = new Array(240 * 216).fill(null); for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) m[i] = p; TAGS[k] = m; }
  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairSides = pairSidesOf();
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of PAIRS.level) for (const p of L.pictures) if (p.scene === 'mesa') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + ')' + (sh.storyPlaces.length ? ' and ' + sh.storyPlaces.length + ' story places not in positions.json' : ' (h-mesa\'s among them)') + ', ' + CUAL.items.length + ' review pairs of cual-mesa (' + pairSides.length + ' pictures), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + sh.setKey.baked.length + ' baked states for the old ' + inv.states.count);

  /* code: mesa.js read here, line by line: every line with a number has an entry; every place of order 06's list is named by its entry */
  { const codeLines = new Set(sh.code.map(e => String(e.line)));
    for (let L = 1; L <= LINES.length; L++) if (numsOf(stripLine(LINES[L - 1])).length && !codeLines.has(String(L))) P.push('code: mesa.js line ' + L + ' holds numbers and has no entry');
    for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], e = sh.code.find(q => String(q.line) === L); if (!e) { P.push('code: mesa.js:' + L + ' (' + p.what + ') has no entry'); continue; }
      const all = Object.values(e.numbers || {}).flat().map(String); for (const n of p.nums.map(v => String(Math.abs(v)))) if (!all.includes(n) && !all.includes(n.replace(/^0\./, '.'))) P.push('code: mesa.js:' + L + ' ' + JSON.stringify(p.nums) + ': ' + n + ' not among its numbers'); }
    for (const e of sh.code) if (typeof e.line === 'number' && (e.numbers || {}).place && e.to === 'unchanged' && !regionOf(e.line) && !/no place|unchanged/.test(e.note)) P.push('code: mesa.js line ' + e.line + ' has places but no fate');
    for (const m of sh.moves) { for (const L of m.lines || [m.line]) if (!LINES[L - 1].includes(m.src)) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); }
    for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
    { const PS = portSource(sh); for (const [a] of sh.front.tags) if (!PS.includes(a)) P.push('mesa.js with the moves does not hold ' + a); }
    const counts = {}; for (const e of sh.code) for (const [k, v] of Object.entries(e.numbers || {})) counts[k] = (counts[k] || 0) + v.length;
    notes.push('code: every one of the ' + LINES.length + ' lines of mesa.js read here; ' + sh.code.filter(e => typeof e.line === 'number').length + ' hold numbers, each with an entry (' + Object.entries(counts).map(([k, v]) => v + ' ' + k).join(', ') + '); every one of order 06\'s ' + pos.inSceneFile.length + ' places named by its line\'s entry; ' + sh.moves.length + ' moves, each line holding its source'); }

  /* (fix after the port) every walk of the frog, old against the port's: the old page (old mesa.js, old story files) and the port's play
     (mesa.js with the sheet's moves, the story files through its remap) each record every call of hopTo, acts included; walk by walk, in every
     run, the port's walk has the old one's hop count (the sound of each hop is heard: their number is the old one) */
  { let n = 0, bad = 0; const fails = [];
    runs.forEach((r, ri) => { const A = G.OLDHOPS[ri] || [], B = G.TICKS[ri].hops || [];
      if (A.length !== B.length) { P.push('walks: ' + r.story.id + ' ' + r.plan + ': the old page walks the frog ' + A.length + ' times, the port ' + B.length); return; }
      A.forEach((a, k) => { n++; const b = B[k]; if (a.hops !== b.hops) { bad++; fails.push(r.story.id + ' ' + r.plan + ' walk ' + k + ' (' + a.from + ' -> ' + a.to + ': ' + a.hops + '; port ' + b.from + ' -> ' + b.to + ': ' + b.hops + ')'); } }); });
    for (const f of fails.slice(0, 30)) P.push('walks: the hop count changed at ' + f);
    notes.push('walks: every walk of the frog (every call of hopTo, acts included) in the ' + runs.length + ' runs, the old page against the port\'s play, walk by walk: ' + n + ' walks, each with the old hop count (' + bad + ' differ)'); }

  { const off = runs.filter(r => r.recorded !== true); for (const r of off) P.push('runs: ' + r.story.id + ' ' + r.plan + ': ' + (r.recorded === null ? 'no recorded run in coqui/ref/trazas' : 'the play is not its recorded run (coqui/ref/trazas)'));
    notes.push('runs: the ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + ', three plans each) are played by juega.mjs on the old page, each trace byte for byte its recorded run in coqui/ref/trazas/ (' + runs.filter(r => r.recorded).length + ' of ' + runs.length + ')'); }

  /* hops: every pair whose count changed is walked in no run */
  { const at = {}; for (const [k, v] of Object.entries(sh.spots)) if (v.scale != null || /^rana\./.test(k)) at[v.new.join(',')] = k; const walked = new Set();
    const walk = Ws => { let prev = null; for (const w of Ws) { const q = w.cq; if (!q || !q.vis) continue; const k = at[q.x + ',' + q.y]; if (!k) continue; if (prev && prev !== k) walked.add([prev, k].sort().join('-')); prev = k; } };
    runs.forEach((r, ri) => { walk(r.lines.map(l => remapW(sh, l.W, r.story.id).cq ? remapW(sh, l.W, r.story.id) : l.W)); walk(NEW[ri].ticks.map(t => t.W)); });
    for (const c of sh.hops) if (walked.has([c.a, c.b].sort().join('-'))) P.push('hops: ' + c.a + '-' + c.b + ' ' + c.old + ' -> ' + c.new + ' is walked in a run');
    notes.push('hops: all ' + sh.hopsAll.length + ' pairs of the frog\'s places keep the old count' + (sh.hops.length ? ' but ' + sh.hops.map(c => c.a + '-' + c.b + ' ' + c.old + ' -> ' + c.new).join(', ') + ' (walked in no run)' : '') + '; his walks between them in the runs: ' + [...walked].sort().join(', ')); }

  /* the set's pixels: every set thing's pixels inside its touch box; nothing decorative over a touch box; the hit order */
  { const res = [];
    for (const name of ['mesa', 'estufa']) { const b = sh.things[name].box; let out = 0, n = 0;
      for (const k of STATES) for (const [p, list] of Object.entries(G.parts[k])) if (THING_OF(p) === name) for (const i of list) { n++; const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + name + ' are outside its touch box ' + JSON.stringify(b));
      res.push(name + ' ' + JSON.stringify(b)); }
    const ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const hitAt = (x, y) => { for (const [id, m] of ORDER) { const b = sh.things[id].box; if (x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) return id; } return null; };
    const wrong = {};
    for (const k of STATES) for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) { const x = i % 240, y = Math.floor(i / 240); if (x < x0 || x >= x0 + 196) continue; const h = hitAt(x, y), want = THING_OF(p); if (h !== want && !(want === 'cocina')) { const kk = p + ' -> ' + h; wrong[kk] = (wrong[kk] || 0) + 1; } }
    // the room's pieces (counter, wall cupboard, walls, door, window) are la cocina's: decorative over no other thing's box but where the old picture had them behind (the table's box over the wall behind it)
    const decor = {}; for (const k of [STATES[0]]) for (const [p, list] of Object.entries(G.parts[k])) if (THING_OF(p) === 'cocina' && !['pared'].includes(p)) for (const i of list) { const x = i % 240, y = Math.floor(i / 240); const h = hitAt(x, y); if (h && h !== 'cocina') { const kk = p + ' under ' + h; decor[kk] = (decor[kk] || 0) + 1; } }
    for (const [k, n] of Object.entries(wrong)) P.push('hit: ' + n + ' px of ' + k + ' (a touch there answers the other thing)');
    for (const p of Object.keys(G.parts[STATES[0]])) if (!sh.things[THING_OF(p)] || !sh.things[THING_OF(p)].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s');
    notes.push('boxes: every pixel of each set thing inside its touch box in every baked state: ' + res.join(', ') + '; every pixel answers its own thing in the hit order; every part of the set is a touch key\'s (nothing decorative): the room\'s pieces (the counters, the wall cupboard, the door, the window, the walls) are la cocina\'s, the whole room; where the table\'s or the stove\'s box (a rectangle) reaches over them a touch answers the table or the stove, as the old boxes did over the old background (' + Object.entries(decor).map(([k, n]) => n + ' px of ' + k).join(', ') + ')'); }

  /* every castShadow call darkens; each shadow in one piece with its thing; a thin thing casts only a short contact shadow; no fringe on the lit side */
  { const byPart = {}, K0 = STATES[0];
    for (const c of G.shadows[K0]) { const [x, y, z, r, s] = c.args, k = c.part || '(none)'; if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + k + ' castShadow(' + c.args.map(r2).join(', ') + '): nothing is cast');
      const b = byPart[k] = byPart[k] || { calls: 0, set: 0, dark: 0 }; b.calls++; b.set += c.set; }
    const pieces = [];
    for (const [k, b] of Object.entries(byPart)) { const sp = (G.shadowPx[K0][k] || []).filter(i => G.onGround[K0][i]); b.dark = sp.length; if (!b.dark) P.push('shadow: the part ' + k + ' casts ' + b.calls + ' times and darkens nothing');
      const own = new Set(G.parts[K0][k] || []); let far = 0; for (const i of sp) { const x = i % 240, y = Math.floor(i / 240); let near = false; for (let dy = -4; dy <= 4 && !near; dy++) for (let dx = -4; dx <= 4; dx++) if (own.has((y + dy) * 240 + x + dx)) { near = true; break; } if (!near) far++; }
      if (far) P.push('shadow: ' + far + ' px of ' + k + '\'s shadow are further than 4 px from it (not one piece, or not a short contact shadow)');
      pieces.push(k + ' ' + b.calls + ' calls, ' + b.dark + ' px darkened'); }
    notes.push('shadows of the set: every castShadow call has strength 1 and a radius; each casting part darkens pixels, its shadow within 4 px of it (a contact shadow at the foot of each thin leg): ' + pieces.join('; '));
    // the lit side: within 3 px to the left of any standing piece's pixels on the floor, the floor is as it is with nothing there (G.bare: no shadow, no dimming)
    let bad = 0, n = 0; const RGB = G.rgb[K0], BARE = G.bare, Z = G.z[K0], SURF = G.surf;
    const solid = new Set(); for (const p of ['mesa', 'sillas', 'mostrador', 'mostrador2', 'estufa']) for (const i of G.parts[K0][p] || []) solid.add(i);
    const lit = new Set(); for (const i of solid) { const x = i % 240; for (let d = 1; d <= 3; d++) { const j = i - d; if (x - d < 0 || solid.has(j) || !G.onGround[K0][j]) continue; let shade = false; for (let e = 1; e <= 5 && !shade; e++) for (const dy of [-2, -1, 0, 1, 2]) { const q = j - e + dy * 240; if (Z[q] > -1e8 && !G.onGround[K0][q]) { shade = true; break; } } if (!shade) lit.add(j); } }
    for (const j of lit) { n++; if (RGB[j * 3] !== BARE[j * 3] || RGB[j * 3 + 1] !== BARE[j * 3 + 1] || RGB[j * 3 + 2] !== BARE[j * 3 + 2]) bad++; }
    if (bad) P.push('light: ' + bad + ' floor px within 3 px left of a standing thing (its lit side) differ from the floor with nothing there');
    notes.push('light: the kitchen\'s one rule (cocina-kit: shadows to screen right, low, joined); on the lit side (left) of every leg, chair, counter and the stove, ' + n + ' floor px within 3 px checked: none differs from the floor without the thing (no ring, no fringe; cocinaOcclusion dims the shadow side only)'); }

  /* thin things seen: each small piece the picture needs stands out from what is directly behind it by WCAG contrast 2 */
  { const K0 = STATES[0], RGB = G.rgb[K0], EMP = G.empty, at = i => [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]], emp = i => [EMP[i * 3], EMP[i * 3 + 1], EMP[i * 3 + 2]];
    const res = [];
    // the legs of the table and of the chairs against the floor behind them (the room without them); a knob, a handle, a burner against the face round it
    const legs = []; for (const p of ['mesa.patas', 'sillas.patas']) for (const i of G.parts[K0][p] || []) legs.push(i);
    let worst = 99, worstAt = null, nL = 0; const legCol = {}; for (const i of legs) { const behind = emp(i); if (!(G.surf[i] === 'f' || G.surf[i] === 'u')) continue; const c = contrast(at(i), behind); nL++; if (c < worst) { worst = c; worstAt = i; } }
    res.push('legs against the floor ' + r2(worst) + ' at the least (' + nL + ' px)'); if (worst < 2) P.push('thin: a leg pixel at ' + (worstAt % 240) + ',' + Math.floor(worstAt / 240) + ' stands out from the floor behind it by ' + r2(worst));
    // the stove's knobs, the oven's handle, the cupboards' handles: their colour against the face they are on (the set's own colours)
    const KC = F.KC, face = (c, sh) => sh ? [c[0] * .86 + 4, c[1] * .86 + 5, c[2] * .86 + 12] : c;
    for (const [nm, a, b] of [['knob on the stove', KC.red, KC.steel], ['oven handle', KC.handle, KC.steel], ['burner on the hob', KC.burner, KC.hob], ['cupboard handle (front, lit)', KC.knob, rampOf3(KC.wood)], ['cupboard handle (front, shade)', face(KC.knob, 1), face(rampOf3(KC.wood), 1)], ['window bar against the sky', rampOf2(KC.frame), KC.sky[1]], ['steam against the panel behind the stove', [255, 255, 255], KC.guard], ['chair rail against the wall', F.CHW || [110, 66, 32], KC.plaster]]) {
      const c = contrast(a, b); res.push(nm + ' ' + r2(c)); if (c < 2) P.push('thin: ' + nm + ' stands out by ' + r2(c) + ' (WCAG; 2 kept)'); }
    notes.push('thin things (WCAG contrast against what is behind them, 2 kept; one light, so every light): ' + res.join(', ')); }

  /* the window and the door show the outside with depth: the patio's colours through them, a frame standing out of the wall, a sill */
  { const K0 = STATES[0], T0 = TAGS[K0], RGB = G.rgb[K0]; let sky = 0, green = 0, frame = 0;
    for (let i = 0; i < 240 * 216; i++) { if (T0[i] !== 'ventana') continue; const c = [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]; if (c[2] > c[0] + 40 && c[2] > 180) sky++; else if (c[1] > c[0] + 30 && c[1] > c[2]) green++; else frame++; }
    if (sky < 20 || green < 6) P.push('window: the outside shows ' + sky + ' px of sky and ' + green + ' of green (20 and 6 kept)');
    notes.push('window: through it ' + sky + ' px of sky and ' + green + ' px of the patio\'s bush, seen on a backdrop ' + (F.K.OUTD + F.K.T) + ' behind the wall\'s face (it shifts as a view does, not as a picture on the wall); its frame and bars (' + frame + ' px) stand ' + .06 + ' out of the wall, a sill under it'); }

  /* the door (round 2): a leaf open against the wall with its handle, the wall's thickness seen, a threshold, the patio's ground through it */
  { const K0 = STATES[0], T0 = TAGS[K0], RGB = G.rgb[K0], inV = i => { const x = i % 240; return x >= x0 && x < x0 + 196; }, n = p => (G.parts[K0][p] || []).filter(inV).length;
    const nLeaf = n('puerta.hoja'), nRev = n('puerta.jamba'), nThr = n('puerta.umbral');
    for (const [nm, v] of [['leaf', nLeaf], ['reveal', nRev], ['threshold', nThr]]) if (v < 30) P.push('door: its ' + nm + ' has ' + v + ' px in the wide view (30 kept)');
    let knob = 0; for (const i of G.parts[K0]['puerta.hoja'] || []) { const c = [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]; if (dE(c, F.KC.knob) < 20 || dE(c, F.KC.knob.map(v => v * .86)) < 20) knob++; }
    if (knob < 2) P.push('door: its leaf shows ' + knob + ' px of its brass handle');
    // the opening's lowest outside pixels: in each column of the opening, the lowest pixel that is neither the room's (the wall, the frame, the
    // reveal, the threshold, the leaf, the kitchen's floor) is the patio's ground (El patio's step or lawn), not the backdrop (sky, yard wall, hedge)
    const isGround = c => dE(c, F.STONE) < 12 || dE(c, F.STONE.map(v => v * .84)) < 12 || dE(c, F.STONE.map(v => v * .7)) < 14 || dE(c, [124, 146, 62]) < 10;
    let cols = 0, okc = 0; const badc = [], KC = F.KC, BACK = [...KC.sky, KC.yard, KC.yardTop, KC.yardLine, ...KC.hedge, [255, 255, 255]];
    const outside = (i, x, y) => { if (!T0[i]) return G.onGround[K0][i] && E.atZ(x + .5, y + .5, 0)[0] < 0 ? 'ground' : null; if (T0[i] !== 'puerta') return null; const c = [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]; return BACK.some(b => dE(c, b) < 3) ? 'back' : null; };
    for (let x = 0; x < 240; x++) { let low = -1, kind = null; for (let y = 215; y >= 0; y--) { const i = y * 240 + x, o = outside(i, x, y); if (o) { low = i; kind = o; break; } }
      if (low < 0) continue; cols++; const c = [RGB[low * 3], RGB[low * 3 + 1], RGB[low * 3 + 2]]; if (kind === 'ground' && isGround(c)) okc++; else badc.push(x + ',' + Math.floor(low / 240) + ' ' + kind + ' ' + c.join('/')); }
    if (!cols || badc.length) P.push('door: the lowest outside pixel of ' + badc.length + ' of the opening\'s ' + cols + ' columns is not the patio\'s ground: ' + badc.slice(0, 8).join('; '));
    notes.push('door (round 2): in the wide view its leaf ' + nLeaf + ' px (open into the room against the wall towards the corner, its brass handle ' + knob + ' px), the wall\'s thickness in the opening ' + nRev + ' px, the threshold ' + nThr + ' px (30 kept each); through it the patio\'s ground at the floor\'s level, El patio\'s stone step then the lawn, out to the yard\'s wall and hedge: the lowest outside pixel of each of the opening\'s ' + cols + ' columns is ground (' + okc + '); whoever comes in appears on the step (PUERTA), seen in the opening (the wall, its frame, its thickness and the threshold drawn over what of them is behind: front), and steps in onto the walkway\'s end'); }

  /* specks (round 2): the empty set (every baked state) has no group of fewer than 6 floor pixels of one colour that differs from all the floor round it */
  { const res = []; for (const k of STATES) { const T0 = TAGS[k], RGB = G.rgb[k], col = i => RGB[i * 3] * 65536 + RGB[i * 3 + 1] * 256 + RGB[i * 3 + 2], seen = new Uint8Array(240 * 216); let nG = 0; const bad = [];
      for (let y = 0; y < 216; y++) for (let x = x0; x < x0 + 196; x++) { const i = y * 240 + x; if (seen[i] || T0[i] || G.z[k][i] < -1e8) continue;
        const c = col(i), grp = [i], q = [i]; seen[i] = 1; while (q.length && grp.length < 6) { const j = q.pop(), jx = j % 240, jy = Math.floor(j / 240);
          for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const nx = jx + dx, ny = jy + dy, m = ny * 240 + nx; if (nx < 0 || nx >= 240 || ny < 0 || ny >= 216 || seen[m] || T0[m] || col(m) !== c) continue; seen[m] = 1; grp.push(m); q.push(m); } }
        nG++; if (grp.length >= 6) continue;
        // the floor round the group (8 neighbours, untagged, not in it): a speck when none of it is the group's colour
        const S = new Set(grp); let same = false; for (const j of grp) { const jx = j % 240, jy = Math.floor(j / 240); for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const m = (jy + dy) * 240 + jx + dx; if (S.has(m) || jx + dx < 0 || jx + dx >= 240 || jy + dy < 0 || jy + dy >= 216) continue; if (col(m) === c) same = true; } }
        if (!same) bad.push((grp[0] % 240 - x0) + ',' + Math.floor(grp[0] / 240) + ' (' + grp.length + ' px)'); }
      if (bad.length) P.push('speck: ' + k + ' has ' + bad.length + ' groups of under 6 floor px unlike every pixel round them (view x, y): ' + bad.slice(0, 12).join('; '));
      res.push(k + ' ' + bad.length); }
    notes.push('specks (round 2): in every baked state, every group of floor pixels of one colour (4-connected) of fewer than 6 px has a pixel of its own colour next to it, on the floor or of the set (no lone speck: mesa-set.html noSpecks): ' + res.join(', ')); }

  /* a set thing is either whole inside the view by 3 px or clearly runs off it (by 12 px or more) */
  { const res = []; for (const [name, parts] of [['the table and chairs', ['mesa', 'sillas']], ['the stove, hood and panel', ['estufa', 'campana']], ['the left counter', ['mostrador']], ['the right counter', ['mostrador2']], ['the wall cupboard', ['alacena']], ['the door', ['puerta']], ['the window', ['ventana']]]) {
      let a = 1e9, b = -1e9, t = 1e9, bt = -1e9; for (const k of STATES) for (const p of parts) for (const i of G.parts[k][p] || []) { const x = i % 240, y = Math.floor(i / 240); a = Math.min(a, x); b = Math.max(b, x); t = Math.min(t, y); bt = Math.max(bt, y); }
      const sides = [['left', a - x0], ['right', x0 + 195 - b], ['top', t], ['bottom', 215 - bt]], bad = sides.filter(([s, d]) => d < 3 && d > -12);
      if (bad.length) P.push('edge: ' + name + ' ends ' + bad.map(([s, d]) => d + ' px from the view\'s ' + s).join(', ') + ' (3 inside or 12 off)');
      res.push(name + ' ' + sides.map(([s, d]) => s + ' ' + d).join(' ')); }
    notes.push('edges: every set thing whole inside the view by 3 px or running off it by 12 (px to each edge, negative off the view): ' + res.join('; ')); }

  /* bake */
  { const ms = Object.entries(G.ms); for (const [k, v] of ms) if (v.first >= 150) P.push('bake: the first bake of ' + k + ' took ' + R(v.first) + ' ms on a fresh page (the middle of five; 150 kept)');
    console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome, each state on a fresh page: the first ' + ms.map(([k, v]) => k + ' ' + R(v.first) + ' (' + v.firsts.map(R).join(', ') + ')').join(', ') + ' ms (the floor laid too; the middle of five fresh pages); again ' + ms.map(([k, v]) => R(v.warm)).join(', ') + ' ms (the floor cached)'); }

  checkMoments(sh, G, runs, P, { E, F, COS, T30, M, NEW, x0, VIEW, TAGS, pairSides, notes });
  return P;
}
const rampOf3 = c => c, rampOf2 = c => c.map(v => v * .84);   // the cupboard door's lit panel (the kit's ramp step 3: the colour itself); the window frame's front (step 2: .84)

/* ---------- every moment: the port's play at every tick inside the acts and every step's end, and every pair picture ---------- */
function checkMoments(sh, G, runs, P, C) {
  const { E, F, COS, T30, M, NEW, x0, VIEW, TAGS, pairSides, notes } = C;
  const MN = G.MASK.new, MO = G.MASK.old;
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
  const rowsOverlap = (A, B) => { const S = new Set(); for (const [y, a, b] of A) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0; for (const [y, a, b] of B) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++; return n; };
  const frogRows = q => { const b = frogBox(q), rs = []; for (let y = b.y + R(q.dy || 0); y < b.y + R(q.dy || 0) + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]); return rs; };
  const alto = (id, p) => id === 'abuela' ? 51 : ['luis', 'carmen'].includes(id) ? (p && p.sent ? 37 : 44) : (p && p.sent ? 49 : 56);
  // a face: from the sprite's own shape (its first opaque row and the middle of its top 10 rows), 6 rows under its top
  const faceOf = (id, p, rows) => { const top = Math.min(...rows.map(r => r[0])), rs = rows.filter(r => r[0] < top + 10), hx = (Math.min(...rs.map(r => r[1])) + Math.max(...rs.map(r => r[2])) + 1) / 2; return [R(hx - 6), top + 6, 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + R(q.dy || 0), b.w - 4, R(b.h * .6)]; };
  // everything a world shows, as items in the order mesa.js draw() draws them: before the list (the counter's and the stove's things), the
  // sorted list (people, the places at the table, the dog, things, the frog), after it (nothing measured: what flies, the jug, the shown thing)
  const SDS = JSON.parse(sh.moves[0].to.match(/SD=(\[[-\d,]+\])/)[1]);
  const itemsOf = (w, MK, old) => { const pre = [], list = [];
    for (const it of placeItems(w)) { const m = MK[it.key]; if (!m || !m.rows.length) continue; const item = { id: it.id, kind: it.kind, rows: m.rows.map(r => r.slice()), mean: m.mean };
      if (it.kind === 'table') list.push(Object.assign(item, { sk: old ? 166 : 166 + SDS[3], n: list.length })); else pre.push(item); }
    for (const r of rawItems(w)) { const o = r.o, m = MK[r.key]; if (!m || !m.rows.length) continue; const dy = R(o.dy || 0);
      const item = { id: r.kind === 'dog' ? 'perro' : r.id, kind: r.kind, o, rows: rowsAt(m.rows, R(o.x), R(o.y) + (r.kind === 'person' ? dy : -dy)), at: [R(o.x), R(o.y)], mean: m.mean, air: r.kind === 'person' ? dy < -3 : dy > 3, n: list.length };
      if (r.kind === 'person') { item.sent = !!o.sent; const fk = MK['f|' + r.id + '|' + (o.pose || '') + '|' + (o.dir < 0 ? -1 : 1) + '|' + (o.sent ? 1 : 0)]; item.face = faceOf(r.id, o, fk ? rowsAt(fk.rows, R(o.x), R(o.y) + dy) : item.rows); item.sk = o.z != null ? o.z : o.y; }
      else if (r.kind === 'dog') item.sk = o.y;
      else { item.sk = o.suelo ? o.y - 4 : o.z != null ? o.z : o.y + 1; item.onTop = o.z != null && o.z >= 300; item.air = o.z === 400; }
      list.push(item); }
    if (w.cq && w.cq.vis && !(w.cq.al <= .3)) { const b = frogBox(w.cq); list.push({ id: 'the frog', kind: 'frog', o: w.cq, rows: frogRows(w.cq), at: [b.x + b.w / 2, w.cq.y + 26], air: R(-(w.cq.dy || 0)) > 3, face: frogFace(w.cq), sk: w.cq.y + 27, n: list.length }); }
    if (old && !w.afuera) list.push({ id: 'the old table', kind: 'oldtable', rows: M.tableRows[w.mantel ? 1 : 0], sk: 166, n: -1 });
    list.sort((a, b) => a.sk - b.sk || (a.kind === 'oldtable' ? -1 : b.kind === 'oldtable' ? 1 : 0) || a.n - b.n);
    return { pre, list }; };
  const vAt = (sx, sy, z) => { const g = E.atZ(sx, sy, z); return (g[0] + g[1]) / E.R2; };
  // an item's plane for the front test (sheet front.how): null = never drawn over
  const plane = it => { if (it.air || ['table', 'oldtable', 'counter', 'stove'].includes(it.kind)) return null;
    if (it.kind === 'person' && it.o.sent) return vAt(it.at[0], it.at[1] - 8, F.ZS) + .03;
    if (it.kind === 'frog') { const b = frogBox(it.o); return vAt(b.x + b.w / 2, it.o.y + 25, 0); }
    if (it.kind === 'thing') { const s = E.surface(it.at[0], it.at[1] - 1); return s.on === 'floor' || s.on === 'wall' ? vAt(it.at[0], it.at[1] - 1, 0) : null; }
    return vAt(it.at[0], it.at[1] - 1, 0); };
  // the picture as it is drawn: each item owns the pixels it drew last; then each front part is drawn again where its owner stands behind it
  const STAMP = new Int32Array(240 * 216), OWN = new Int16Array(240 * 216); let stampN = 0;
  const compose = (w, old) => { const key = keyOf(w), { pre, list } = itemsOf(w, old ? MO : MN, old); stampN++;
    const key0 = key, all = pre.concat(list); all.forEach((it, j) => { it.j = j; for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; STAMP[i] = stampN; OWN[i] = j; } } });
    const cov = new Map();
    if (!old) { const Z = G.z[key], TG = TAGS[key], PL = all.map(plane);
      for (const part of FRONT) for (const i of G.parts[key][part] || []) { if (STAMP[i] !== stampN) continue; const j = OWN[i], pl = PL[j]; if (pl == null) continue; if (/^sillas/.test(part) && all[j].kind === 'person' && all[j].o.sent) continue; const y = Math.floor(i / 240);
        if (Z[i] > pl / COS - (y + .5 - E.OY) * T30 / E.S) cov.set(i, part); } }
    return all.map(it => { let tot = 0, vis = 0, fTot = 0, fVis = 0; const by = {}, rel = new Set(), face = it.face;
      for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (x < x0 || x >= x0 + 196) continue; tot++; const inF = face && x >= face[0] && x < face[0] + face[2] && y >= face[1] && y < face[1] + face[3]; if (inF) fTot++;
        const mine = STAMP[i] === stampN && OWN[i] === it.j, c = cov.get(i);
        if (mine && c) { by[c] = (by[c] || 0) + (inF ? 1000 : 1); if (it.at) rel.add((y - it.at[1]) + ',' + (x - it.at[0])); if (process.env.MESA_DEBUG) (it.cpx = it.cpx || []).push(x + ',' + y + ':' + G.z[key][i].toFixed(2)); }
        if (!mine && old && all[OWN[i]] && all[OWN[i]].kind === 'oldtable' && it.at) rel.add((y - it.at[1]) + ',' + (x - it.at[0]));
        if (mine && !c) { vis++; if (inF) fVis++; } } }
      return { it, tot, vis, fTot, fVis, by, rel }; }); };

  // every moment: the port's ticks and step ends (as they are: the port's own play), every pair picture (through the remap)
  const allW = [];
  const REST_MS = 300;
  const posOf = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (shown(p) && p.x != null) o[id] = [R(p.x), R(p.y)]; if (w.perro && w.perro.x != null) o.perro = [R(w.perro.x), R(w.perro.y)]; if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y]; return o; };
  runs.forEach((r, ri) => { const T = NEW[ri].ticks, P0 = T.map(t => posOf(t.W)), dwell = P0.map(() => ({}));
    for (let i = 0; i < T.length; i++) for (const [id, p] of Object.entries(P0[i])) { const key = id + '@' + p.join(','); if (i > 0 && P0[i - 1][id] && P0[i - 1][id].join(',') === p.join(',')) { dwell[i][key] = dwell[i - 1][key]; continue; }
      let j = i; while (j + 1 < T.length && P0[j + 1][id] && P0[j + 1][id].join(',') === p.join(',')) j++; dwell[i][key] = (j + 1 < T.length ? T[j + 1].t : T[j].t + REST_MS) - T[i].t; }
    for (let i = 0; i < T.length; i++) allW.push([r.story.id + ' ' + r.plan + ' t ' + T[i].t, T[i].W, dwell[i]]);
    for (const L of NEW[ri].states) { let j = -1; for (let k = 0; k < T.length && T[k].t <= L.t; k++) j = k; const dw = {}, P1 = posOf(L.W);
      for (const [id, p] of Object.entries(P1)) { const key = id + '@' + p.join(','); dw[key] = j >= 0 && dwell[j][key] != null ? dwell[j][key] : (j < 0 ? 999 : 0); }
      allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W, dw]); } });
  for (const ps of pairSides) if (!(ps.w === 'cocina' && ps.side === 'no')) allW.push(['pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps, sh, false), null]);

  /* drawn as it is drawn: no set part over any face; nobody who sits has the table or a chair over a part of them the old table did not cover;
     what stands on a top rests on it, covered by nothing of the set */
  { const bad = new Map(); let nMom = 0, nSit = 0, worstSit = 0; const sitOld = new Map();
    // the old table over each sitter, relative to their feet (the old picture: the same list with the old table in it)
    const oldCover = (id, w) => { const wo = JSON.parse(JSON.stringify(w)); const SD = JSON.parse(sh.moves[0].to.match(/SD=(\[[-\d,]+\])/)[1]);
      for (const p of Object.values(wo.gente || {})) if (p && p.sent) { const k = SILLA.indexOf(R(p.x)); if (k >= 0) p.y = R(p.y) - SD[k]; }
      const r = compose(wo, true).find(q => q.it.id === id); return r ? r.rel : new Set(); };
    for (const [where, w] of allW) { nMom++; for (const r of compose(w, false)) { const it = r.it;
      for (const [part, n] of Object.entries(r.by)) { const faceN = Math.floor(n / 1000), bodyN = n % 1000;
        if (faceN) bad.set(part + ' over ' + it.id + '\'s face', where + ': ' + faceN + ' px');
        if (it.kind === 'thing' && it.onTop) bad.set(part + ' over ' + it.id + ' (on the table)', where + ': ' + (faceN + bodyN) + ' px'); }
      if (it.kind === 'person' && it.sent && Object.keys(r.by).length) { nSit++; const k0 = SILLA.indexOf(it.at[0]), oy = it.at[1] - (k0 >= 0 ? SDS[k0] : 0); let extra = 0;
        for (const q of r.rel) { const [dy, dx] = q.split(',').map(Number), oyy = oy + dy, oxx = it.at[0] + dx; if (oyy < OLD.MESA[1] || oxx < OLD.MESA[0] - 6 || oxx > OLD.MESA[0] + OLD.MESA[2] + 6) extra++; }
        for (const [part, n] of Object.entries(r.by)) if (/^sillas/.test(part)) extra += n % 1000 + Math.floor(n / 1000);
        worstSit = Math.max(worstSit, extra);
        if (extra > 0) bad.set('the table or a chair over ' + it.id + ' sitting at ' + it.at + ' where the old table was not', where + ': ' + extra + ' px' + (it.cpx ? ' ' + it.cpx.slice(0, 8).join(' ') : '')); } } }
    for (const [k, w] of [...bad].slice(0, 40)) P.push('drawn: ' + k + ' (' + w + ')');
    notes.push('drawn: at ' + nMom + ' moments (every tick inside the acts of the port\'s play of the ' + runs.length + ' runs, every step\'s end, every pair picture) the sorted list composed as it is drawn (each item owns what it drew last; a front part drawn again only over an owner behind it): no part of the set over any face; at ' + nSit + ' sitter-moments the table over no part of a sitter the old table did not cover (' + worstSit + ' px more at the worst); nothing on the table\'s top under any part of the set'); }

  /* rests: whoever stands still (300 ms and more) on the floor stands on clear floor (nothing of the set under or round their foot); whoever sits
     has the seat under their lap and the chair's back behind them; what stands on a top rests on it */
  { const bad = new Map(); let nRest = 0, nSit = 0, D0 = { PUERTA: JSON.parse(sh.moves[0].to.match(/PUERTA=(\[\d+,\d+\])/)[1]) };
    const footClear = (x, y) => [-5, 0, 5].every(dx => E.clearFloor(x + dx, y - 1, .08));
    for (const [where, w, dwell] of allW) { const { pre, list } = itemsOf(w, MN, false);
      for (const it of list) { if (it.air || !it.at) continue; const resting = !dwell || dwell[(it.kind === 'dog' ? 'perro' : it.id) + '@' + it.at.join(',')] >= REST_MS || (it.kind === 'frog' && dwell['cq@' + [it.o.x, it.o.y].join(',')] >= REST_MS);
        if (!resting) continue; if (it.at[0] < x0 - 6 || it.at[0] > x0 + 202) continue;
        if (it.kind === 'person' && it.sent) { nSit++; const lap = E.atZ(it.at[0], it.at[1] - 8, F.ZS), k = F.CHAIRS.findIndex(c => Math.abs(lap[0] - c.x) <= F.CH.hw && Math.abs(lap[1] - c.y) <= F.CH.hd + .2); if (k < 0) bad.set(it.id + ' sitting at ' + it.at, where + ': no seat under the lap');
          continue; }
        if (it.kind === 'thing' && it.onTop) { const s = E.surface(it.at[0], it.at[1] - 1); if (s.on !== 'mesa') bad.set(it.id + ' at ' + it.at, where + ': not on the table\'s top (' + s.on + ')'); continue; }
        if (it.kind === 'thing') continue;
        if (it.at[0] === D0.PUERTA[0] && it.at[1] === D0.PUERTA[1]) continue;   // in the doorway (where they appear and go)
        nRest++; const fx = it.kind === 'frog' ? it.at[0] : it.at[0], fy = it.kind === 'frog' ? it.o.y + 26 : it.at[1];
        if (!footClear(fx, fy)) { const s = E.surface(fx, fy - 1); bad.set(it.id + ' at ' + it.at, where + ': not on clear floor (' + (s.under || s.on) + ' under or round the foot)'); } } }
    // the things on the counter and the stove: each stack's bottom row on its top (moves)
    for (const [k, p] of Object.entries(sh.spots)) if (/^(mostrador|estufa)\./.test(k)) { const on = k.startsWith('mostrador') ? 'mostrador' : 'estufa'; if (!E.onTop(p.new[0], p.new[1] - 1, on, 0)) P.push('top: ' + k + ' at ' + p.new + ' is not on the ' + on + '\'s top'); }
    for (const [k, why] of [...bad].slice(0, 40)) P.push('rest: ' + k + ' (' + why + ')');
    notes.push('rests: ' + nRest + ' moments of someone standing still on the floor, each on clear floor (nothing of the set under or within .08 of the foot); ' + nSit + ' of someone sitting, the seat under the lap; every stack on the counter and every thing on the stove on its top'); }

  /* seen: at every step's end each person, the dog and the frog seen no less than in the old picture of that moment less 10%, their face no less;
     whoever was wholly inside the view is wholly inside it with 3 px to spare */
  { const lows = [], edge = []; let n = 0, skipped = 0;
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach((ln, li) => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return;
      const o = new Map(compose(ln.W, true).map(q => [q.it.id, q])), nw = compose(tw.W, false);
      for (const q of nw) { if (!['person', 'dog', 'frog'].includes(q.it.kind) || q.it.air) continue; const p = o.get(q.it.id); if (!p || !p.tot || !q.tot) continue; if (q.it.kind === 'person' && (!!q.it.o.sent !== !!p.it.o.sent)) continue; { const rm = remapW(sh, ln.W, r.story.id), po = q.it.kind === 'frog' ? rm.cq && [rm.cq.x, rm.cq.y] : q.it.kind === 'dog' ? rm.perro && [R(rm.perro.x), R(rm.perro.y)] : rm.gente[q.it.id] && [R(rm.gente[q.it.id].x), R(rm.gente[q.it.id].y)], pn = q.it.kind === 'frog' ? [q.it.o.x, q.it.o.y] : q.it.at; if (!po || po[0] !== pn[0] || po[1] !== pn[1]) { skipped++; continue; } } n++;
        const sN = q.vis / q.tot, sO = p.vis / p.tot, fN = q.fTot ? q.fVis / q.fTot : 1, fO = p.fTot ? p.fVis / p.fTot : 1;
        if (fN < fO - .001 || sN < sO - .1) lows.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' seen ' + R(sN * 100) + '% (face ' + R(fN * 100) + '%), the old ' + R(sO * 100) + '% (' + R(fO * 100) + '%)');
        const bo = rowsBox(p.it.rows), bn = rowsBox(q.it.rows); if (within(bo, VIEW) && !within([bn[0] - 3, bn[1] - 3, bn[2] + 6, bn[3] + 6], VIEW)) edge.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' ' + JSON.stringify(bn)); } }); });
    for (const l of lows.slice(0, 40)) P.push('seen: ' + l);
    for (const l of [...new Set(edge)].slice(0, 20)) P.push('edge: ' + l + ' was wholly inside the old view and is not 3 px inside now');
    notes.push('seen: at ' + n + ' person-, dog- and frog-moments (every step\'s end of the ' + runs.length + ' runs) each seen no less than in the old picture of that moment less 10%, and their face no less (' + lows.length + ' less; ' + skipped + ' person-moments where the port\'s play has them elsewhere than the rule puts the old moment\'s place, mid-walk, are not compared); whoever was wholly inside the old view is wholly inside it with 3 px to spare'); }

  /* bubbles */
  { let nB = 0, worstView = 99; const seen = new Set();
    const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const rr = sh.bubbles.rects[k], r = [top[0] + side * (h + 16) + rr[0], top[1] + dy + rr[1], rr[2], rr[3]];
        if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } const rr = sh.bubbles.rects[k], r = [top[0] + rr[0], top[1] + rr[1], rr[2], rr[3]]; r.old = true; return r; };
    for (const [where, w] of allW) { const { list } = itemsOf(w, MN, false), faces = list.filter(it => it.face && !(it.o && it.o.al != null && it.o.al < .5)).map(it => [it.id + '\'s face', it.face]), boards = boardsOf(w, x0);
      const bubs = []; for (const [id, p] of Object.entries(w.gente || {})) if (shown(p) && p.bub && p.x != null) bubs.push([id + ' "' + p.bub + '"', p.bub, [R(p.x), R(p.y) - alto(id, p) - 1], 6]);
      if (w.cq && w.cq.vis && w.cq.bub) { const b = frogBox(w.cq); bubs.push(['the frog "' + w.cq.bub + '"', w.cq.bub, [b.x + (b.w >> 1), b.y + 2], b.w >> 1]); }
      for (const [who, k, top, h] of bubs) { if (!sh.bubbles.rects[k]) continue; const rect = talk(k, top, VIEW, boards, faces, h), sig = JSON.stringify([who, rect, boards, faces]); if (seen.has(sig)) continue; seen.add(sig); nB++;
        if (!within(rect, VIEW)) { P.push('bubble: ' + where + ' ' + who + ' ' + JSON.stringify(rect) + ' is not wholly inside the view'); continue; }
        worstView = Math.min(worstView, rect[0] - x0, x0 + 196 - rect[0] - rect[2], rect[1], 216 - rect[1] - rect[3]);
        for (const [bn, b] of boards) if (meets(rect, b)) P.push('bubble: ' + where + ' ' + who + ' is over ' + bn);
        for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + who + ' is on ' + fn); } }
    notes.push('bubbles: ' + nB + ' distinct bubbles at every moment: wholly inside the view (' + worstView + ' px from its edge at the least), clear of the rounds card, on no face (talk)'); }

  checkAsks(sh, G, runs, P, Object.assign(C, { itemsOf, compose, rowsBox, rowsMeet, rowsOverlap, shown, alto, allW, MN, MO }));
}

function checkAsks(sh, G, runs, P, C) {
  const { E, F, NEW, x0, VIEW, TAGS, pairSides, notes, itemsOf, compose, rowsBox, rowsMeet, rowsOverlap, shown, alto, allW, MN, MO } = C;
  /* the asks: hint frames, the hand, the answer cards and the hint drawn round a card; the things a learner must find or tell apart */
  const cajaBox = (id, p) => { const h = alto(id, p); return p.sent ? [R(p.x) - 11, R(p.y) - h, 22, h + 1] : [R(p.x) - 11, R(p.y) - h, 22, h]; };
  const cajaBoxOld = (id, p) => { const h = alto(id, p); return p.sent ? [R(p.x) - 11, R(p.y) - h, 22, OLD.FILA + 3 - (R(p.y) - h)] : [R(p.x) - 11, R(p.y) - h, 22, h]; };
  const EN = JSON.parse('{' + sh.moves.find(m => m.src.startsWith('const EN={')).to.match(/const EN=\{(.*?)\},ENQ=/)[1].replace(/(\w+):/g, '"$1":') + '}');
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) return old ? t.old.box : (t.hintBox || t.box).slice();
    if (k === 'olla') return w.estufa && w.estufa.olla ? (old ? [OLD.ESTUFA[0] + 1, OLD.ESTUFA[1] - 16, 26, 20] : t.box) : null;
    const en = old ? OLD.EN : EN;
    if (['platos', 'tazas', 'bandeja', 'comidas', 'vasos'].includes(k)) { const e = en[k]; return k === 'comidas' ? [e[0] - 15, e[1] - 16, 30, 18] : k === 'vasos' ? [e[0] - 9, e[1] - 18, 19, 20] : [e[0] - 12, e[1] - 18, 24, 22]; }
    if (k === 'perro') return w.perro ? [R(w.perro.x) - 14, R(w.perro.y) - 20, 28, 22] : null;
    if (k === 'bebe') { const p = w.gente && w.gente.mama; return p && p.bebe ? [R(p.x) + 3, R(p.y) - 38, 18, 18] : null; }
    if (k === 'ofrece') { const p = w.gente && w.gente.abuela; return p && p.ofrece ? [R(p.x) - 29, R(p.y) - 42, 20, 18] : null; }
    if (k === 'muestra') { const m = w.muestra; return m ? [m.x - 9, m.y - (m.g ? 38 : 14), 18, m.g ? 40 : 16] : null; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? (old ? cajaBoxOld(k, p) : cajaBox(k, p)) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !old) return t.hand.slice(); const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const headOf = f => [f[0] - 2, f[1] - 6, f[2] + 4, f[3] + 6];
  const PEOPLE = ['luis', 'carmen', 'abuelo', 'mama', 'papa', 'abuela'], STACKS = ['platos', 'tazas', 'comidas', 'vasos', 'bandeja'];
  // plain round a thing: the table's top, a counter's top, the stove's top, the wall, the tile band, the floor (one surface, no edge of another piece)
  const K0 = 'm0h0';
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99, nTell = 0, cardHint = 0; const boardOld = new Set(), knownTouch = new Set(), askSeen = new Set(), askedFor = new Set(), crossedOld = new Set(), handOld = new Set(), plainLow = new Set();
  runs.forEach((r, ri) => { const Ls = NEW[ri].states, Lo = r.lines;
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = JSON.parse(JSON.stringify(Ls[j - 1].W)), jo = Lo.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')), wo = jo > 0 ? Lo[jo - 1].W : w;
      const st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      let spot = null, opts = [];
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); opts = [spot]; }
      else if (st.decide) { opts = st.options.map(sb); const bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || opts[0]; if (st.decide === 'say') w.resp = opts; else if (bur.length) w.resp = bur; }
      if (!spot) return;
      const key = keyOf(w), where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', sig = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.perro, w.mostrador, w.tarjeta, w.respEn, key]);
      if (askSeen.has(sig)) return; askSeen.add(sig); askedFor.add(spot);
      const { pre, list } = itemsOf(w, MN, false), items = pre.concat(list), faces = list.filter(it => it.face).map(it => [it.id + '\'s face', it.face]);
      const io = itemsOf(wo, MO, true), facesOld = io.list.filter(it => it.face).map(it => [it.id + '\'s face', it.face]);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within([f[0] - 4, f[1] - 4, f[2] + 8, f[3] + 8], VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) { const co = respBox(Object.assign({}, wo, { resp: w.resp, respEn: [125, 28] }), k); if (meets([co[0] - 2, co[1] - 2, co[2] + 4, co[3] + 4], bb)) boardOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + k); else P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn); }
        for (const it of items) { const n = rowsMeet(it.rows, it.kind === 'person' ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id); }
        for (const name of ['mesa', 'sillas', 'estufa']) { const n = (G.parts[key][name] || []).filter(i => meets([i % 240, Math.floor(i / 240), 1, 1], c)).length; if (n > 3 && opts.includes(THING_OF(name))) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + name); }
        cardHint++; const fr = [c[0] - FRAME_OUT, c[1] - FRAME_OUT, c[2] + 2 * FRAME_OUT, c[3] + 2 * FRAME_OUT];
        if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('card hint: ' + where + ' the frame round the card ' + k + ' is not 2 px inside the view');
        for (const [fn, f] of faces) if (ringMeets(c, headOf(f))) P.push('card hint: ' + where + ' the frame round the card ' + k + ' crosses ' + fn.replace('face', 'head'));
        const hp = [c[0] + c[2] / 2, c[1] + c[3] - 6]; for (const [fn, f] of faces) if (handOn(hp, f)) P.push('card hint: ' + where + ' the hand at the card ' + k + ' is on ' + fn); }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { const bo = boxOf(wo, spot, true) || b, fro = [bo[0] - FRAME_OUT, bo[1] - FRAME_OUT, bo[2] + 2 * FRAME_OUT, bo[3] + 2 * FRAME_OUT];
        if (!within(fr, [x0 + 2, 2, 192, 212])) { if (within(fro, [x0 + 2, 2, 192, 212])) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view with 2 px to spare'); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': its frame past the view as the old'); }
        else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' (the old frame did not)' + (process.env.MESA_DEBUG ? ' ' + JSON.stringify([b, f, bo, fo && fo[1]]) : '')); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      if (!hp) { P.push('hand: ' + where + ' no place for the hand at ' + spot); return; }
      { const hb = handBox(hp); if (!rb && !within(hb, VIEW)) { const ho = handOf(wo, spot, true); if (!ho || within(handBox(ho), VIEW)) P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is cut by the view\'s edge'); } }
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb) continue;
        const ho = handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1])) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      // nothing covers the thing asked for at this moment (the set, or a sprite drawn after it)
      { const comp = compose(w, false), me = comp.find(q => (STACKS.includes(spot) && q.it.kind === 'counter') || q.it.id === spot); if (me && me.tot && me.it.kind === 'person' && me.it.o.alza && !me.it.o.sent && me.it.at.join() === OLD.LUIS.join()) { knownTouch.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + spot); } else if (me && me.tot && !(me.it.kind === 'person' && me.it.sent)) { const coveredSet = Object.values(me.by).reduce((a, n) => a + n % 1000 + Math.floor(n / 1000), 0); if (coveredSet) P.push('touch: ' + where + ' ' + coveredSet + ' px of ' + spot + ' under the set ' + JSON.stringify(me.by) + ' at ' + me.it.at + (me.it.cpx ? ' ' + me.it.cpx.slice(0, 12).join(' ') : '')); } }
      // the things a learner must find, tell apart or count: whole in the view, apart where the old had them apart, on a plain surface
      const tell = items.filter(it => (it.kind === 'person' && !it.air && opts.includes(it.id)) || (it.kind === 'counter' && opts.some(o => STACKS.includes(o))) || (it.kind === 'dog' && opts.includes('perro')));
      const itemsO = io.pre.concat(io.list);
      for (const a of tell) { nTell++; const bxA = rowsBox(a.rows);
        if (!within(bxA, VIEW)) P.push('tell: ' + where + ' ' + a.id + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        // plain: the 2 px round it are one surface of the set (the zones: table top t, counter or stove top c / e, floor f, wall w), not another piece's edge
        let n = 0, ok = 0; const own = new Set(); for (const [y, x1, x2] of a.rows) for (let x = x1; x <= x2; x++) own.add(y * 240 + x);
        for (const [y, x1, x2] of a.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i) || x < 0 || x >= 240 || y + dy < 0 || y + dy >= 216) continue; n++; const t = TAGS[key][i]; if (!t || t === 'pared' || (a.kind === 'person' && a.sent && /^(mesa|sillas)$/.test(t)) || (a.kind === 'counter' && /^mostrador/.test(t))) ok++; }
        if (n && ok < n * .8) plainLow.add(a.id + ' ' + R(ok / n * 100) + '%');
        for (const b2 of tell) if (a.id < b2.id) { const nn = rowsOverlap(a.rows, b2.rows); if (!nn) continue; const ao = itemsO.find(x => x.id === a.id), bo2 = itemsO.find(x => x.id === b2.id); if (ao && bo2 && rowsOverlap(ao.rows, bo2.rows)) continue; P.push('tell: ' + where + ' ' + a.id + ' and ' + b2.id + ' overlap by ' + nn + ' px (apart in the old picture)'); } }
    }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least)' + ', no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face and not cut by the view\'s edge where the old was not' + (handOld.size ? ' (but as the old: ' + [...handOld].join('; ') + ')' : '') + '; nothing of the set over the thing asked for (but where Luis holds a thing up at the counter, LUIS: it reaches over the table\'s near left corner, under its top\'s edge by the depth test: ' + ([...knownTouch].join('; ') || 'none') + '; a row or two nearer, his hint frame would cross the frog\'s face at his home by the counter); ' + nC + ' answer cards, each with its lit frame and glow 4 px and more inside the view (' + cardSpare + ' at the least), 2 px clear of everyone\'s head and body, over no thing, and of the rounds card but where the old card met it too (' + ([...boardOld].join('; ') || 'none') + ': there the rounds card covers the top rows of the first card, as the old touched it; lower, the hint hand under the cards would fall on the sitters\' faces); at each of the ' + cardHint + ' cards the hint drawn round it: its frame 2 px inside the view, across no head, its hand on no face; ' + nTell + ' times someone or something a learner must find or tell apart: whole in the view, apart where the old had them apart (plain surface round them under 80%: ' + ([...plainLow].join(', ') || 'none') + ')');

  /* heads: nobody's face against the window's bars, a cupboard's edge or the hood (where the old picture kept it clear) */
  const isWood = c => [.4, .62, .84, 1, 1.1].some(k => dE(c, F.KC.frame.map(v => v * k)) < 18) || dE(c, F.KC.frameL) < 18 || dE(c, F.KC.sill) < 18;
  { const bad = new Map(), leafBehind = new Set(); let n = 0;
    for (const [where, w, dwell] of allW) { if (dwell && !Object.values(dwell).every(v => v >= 300)) continue; const key = keyOf(w), { list } = itemsOf(w, MN, false);
      for (const it of list) { if (!it.face || it.kind === 'frog') continue; n++; const f = it.face;
        for (let y = f[1]; y < f[1] + f[3]; y++) for (let x = f[0]; x < f[0] + f[2]; x++) { const i = y * 240 + x, t = TAGS[key][i]; if (!t || !/^(ventana|alacena|campana|puerta)/.test(t)) continue; if (t === 'puerta.hoja') { leafBehind.add(it.id + ' ' + where.replace(/ (right|wrong|alternate) .*/, '')); continue; } const c = [G.rgb[key][i * 3], G.rgb[key][i * 3 + 1], G.rgb[key][i * 3 + 2]]; if (/^(ventana|puerta)/.test(t) && !isWood(c)) continue; bad.set(it.id + ' / ' + t, where + ' (face ' + JSON.stringify(f) + ', its pixel ' + x + ',' + y + ')'); } } }
    for (const [k, w] of [...bad].slice(0, 20)) P.push('heads: ' + k + ' behind the face at ' + w);
    notes.push('heads: at ' + n + ' face-moments (everyone at rest) no face has the window, the door\'s frame, the wall cupboard or the hood behind it' + (leafBehind.size ? '; the door\'s open leaf (round 2: a plain wooden panel, its lower edge at the face\'s top rows) behind the face of whoever sits at the first seat: ' + [...leafBehind].join(', ') : '')); }

  /* the preview puts everyone where the sheet's rule does, at every recorded moment; the rule puts everyone at rest where the port's play has them */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = placesOf(remapW(sh, ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        const twI = Ls.findIndex(L => L.path === ln.path && L.kind === ln.kind), tw = Ls[twI]; if (!tw || li === 0 || twI < 1) return; const prev = placesOf(remapW(sh, r.lines[li - 1].W, r.story.id)), port = placesOf(tw.W), portPrev = placesOf(Ls[twI - 1].W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k] || !portPrev[k] || portPrev[k].join() !== port[k].join() || p[0] >= x0 + 196) continue; nR++; if (Math.abs(port[k][0] - p[0]) + Math.abs(port[k][1] - p[1]) > 0) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    if (badR) for (const [k, w] of [...off].slice(0, 30)) P.push('rule: ' + k + ' in the port\'s play (' + w + ')');
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places of the people, the frog, the dog and the things) mesa-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); and the rule puts each of the ' + nR + ' places at rest where the port\'s play has them (' + badR + ' differ)'); }

  /* the review pictures */
  { let nPic = 0; const pairDiff = [], zoom2 = [], heads = [], plainAt = [], plainKnown = [], diffPct = [];
    const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
    for (const [word, sides2] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides2)) { const ps = sides2[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps, sh, false); ws[side] = w; nPic++;
        if (pc.scene) continue;
        const key = keyOf(w), crop = pc.crop, mrg = pc.zoom === 2 ? 1 : 2, { pre, list } = itemsOf(w, MN, false), PX = G.PAIRPX[nm];
        const inCrop = i => { const x = i % 240, y = Math.floor(i / 240); return x >= crop[0] && x < crop[0] + crop[2] && y >= crop[1] && y < crop[1] + crop[3]; };
        // (round 2) a person may be cut by the window's edges (as the old close pictures): their whole head inside with 2 px to spare, or none of
        // them in it; every other thing whole with 1 px to spare (2 at zoom 1), or none of it in it
        for (const it of pre.concat(list)) { if (it.kind === 'table' || it.kind === 'counter' || it.kind === 'stove' || it.kind === 'person') continue; const b = rowsBox(it.rows); if (!within([b[0] - mrg, b[1] - mrg, b[2] + 2 * mrg, b[3] + 2 * mrg], crop) && rowsMeet(it.rows, crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with ' + mrg + ' px to spare in ' + JSON.stringify(crop)); }
        const T = new Set(PX.thing);
        for (const [id, m] of Object.entries(PX.people)) { const body = m.filter(i => !T.has(i)); if (!body.length) continue; const top = Math.min(...body.map(i => Math.floor(i / 240))), hd = body.filter(i => Math.floor(i / 240) < top + 16);
          const hb = [Math.min(...hd.map(i => i % 240)), top, Math.max(...hd.map(i => i % 240)) - Math.min(...hd.map(i => i % 240)) + 1, Math.max(...hd.map(i => Math.floor(i / 240))) - top + 1];
          if (within([hb[0] - 2, hb[1] - 2, hb[2] + 4, hb[3] + 4], crop)) { heads.push(nm + ' ' + id); continue; }
          if (m.some(inCrop)) P.push('pair ' + nm + ': ' + id + '\'s head ' + JSON.stringify(hb) + ' is not whole with 2 px to spare in ' + JSON.stringify(crop) + ' and part of ' + id + ' is in it'); }
        // the thing the pair is about: whole in the window with 1 px to spare; a plain surface round half of its outline at least (the ring of
        // pixels next to it, those of whoever holds it left out: each one plain when the 3 x 3 round it, the thing left out, in the picture
        // without the thing, is one colour within dE 12)
        { if (!PX.thing.length) P.push('pair ' + nm + ': the thing (' + pc.thing.join(', ') + ') draws nothing');
          else { const tb = rowsBox(PX.thing.map(i => [Math.floor(i / 240), i % 240, i % 240])); if (!within([tb[0] - 1, tb[1] - 1, tb[2] + 2, tb[3] + 2], crop)) P.push('pair ' + nm + ': the thing ' + JSON.stringify(tb) + ' is not whole with 1 px to spare in ' + JSON.stringify(crop)); }
          const HOLD = new Set(); for (const m of Object.values(PX.people)) for (const i of m) if (!T.has(i)) HOLD.add(i);
          const ring = new Set(); for (const i of PX.thing) { const x = i % 240, y = Math.floor(i / 240); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const j = (y + dy) * 240 + x + dx; if (!T.has(j) && !HOLD.has(j) && inCrop(j)) ring.add(j); } }
          const cAt = (A, i) => [A[i * 3], A[i * 3 + 1], A[i * 3 + 2]]; let ok = 0;
          for (const i of ring) { const x = i % 240, y = Math.floor(i / 240), c = cAt(PX.noT, i); let good = true; for (let dy = -1; dy <= 1 && good; dy++) for (let dx = -1; dx <= 1; dx++) { const j = (y + dy) * 240 + x + dx; if (T.has(j)) continue; if (dE(cAt(PX.noT, j), c) > 12) { good = false; break; } } if (good) ok++; }
          const fr = ring.size ? ok / ring.size : 0; plainAt.push(nm + ' ' + R(fr * 100) + '%');
          if (fr < .5) { if (pc.plainKnown) plainKnown.push(nm + ' ' + R(fr * 100) + '% (' + pc.plainKnown + ')'); else P.push('pair ' + nm + ': a plain surface round ' + R(fr * 100) + '% of the thing\'s outline (half kept)'); } }
        if (pc.zoom === 2) { for (const [part, lst] of Object.entries(G.shadowPx[key])) { const inC = i => { const x = i % 240, y = Math.floor(i / 240); return x >= crop[0] && x < crop[0] + crop[2] && y >= crop[1] && y < crop[1] + crop[3]; };
            const sh2 = lst.filter(i => G.onGround[key][i] && inC(i)).length, own = (G.parts[key][part] || []).filter(inC).length; if (sh2 > 4 && own < 6) P.push('pair ' + nm + ': shows ' + sh2 + ' px of ' + part + '\'s shadow and not ' + part); }
          zoom2.push(nm); } }
      if (!ws.si || !ws.no) continue;
      // (round 2) the pixels that differ between the two pictures (as shown: 196 x 104, the crop at its zoom): 1.5% of the picture at least
      { const pic = side => { const pc = sh.pictures[deacc(word) + '.' + side], A = G.PAIRPX[deacc(word) + '.' + side]; if (!A) return null; const o = [];
          for (let y = 0; y < 104; y++) for (let x = 0; x < 196; x++) { const i = (pc.crop[1] + Math.floor(y / pc.zoom)) * 240 + pc.crop[0] + Math.floor(x / pc.zoom); o.push(A.full[i * 3] * 65536 + A.full[i * 3 + 1] * 256 + A.full[i * 3 + 2]); } return o; };
        const a2 = pic('si'), b2 = pic('no'); if (a2 && b2) { let n = 0; for (let k = 0; k < a2.length; k++) if (a2[k] !== b2[k]) n++; const pct = n / a2.length * 100; diffPct.push(deacc(word) + ' ' + pct.toFixed(1) + '%'); if (pct < 1.5) P.push('pair ' + word + ': the two pictures differ in ' + pct.toFixed(2) + '% of their pixels (1.5% kept)'); } }
      const diff = []; for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k);
      if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
      if (!diff.length) P.push('pair ' + word + ': the two pictures are the same');
      pairDiff.push(deacc(word) + ': ' + diff.join(', ')); }
    const z1 = Object.entries(sh.pictures).filter(([k, v]) => v.zoom === 1 && !v.scene).map(([k, v]) => k + ' (' + v.zoom1 + ')');
    notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures), ' + zoom2.length + ' at zoom 2' + (z1.length ? ', at zoom 1: ' + z1.join(', ') : ', none at zoom 1') + ' (cocina.no is El colmado\'s stall); in each, everyone who is in it has their whole head inside with 2 px to spare (' + heads.length + ' heads; a person may be cut by the window\'s edges, as the old close pictures), every other sprite whole with 1 px to spare (2 at zoom 1) or out of it, the thing the pair is about whole with 1 px to spare, a plain surface round half its outline at least (' + plainAt.join(', ') + (plainKnown.length ? '; under half, as written in the picture: ' + plainKnown.join('; ') : '') + '); the two pictures of each pair differ in 1.5% of their pixels at least (' + diffPct.join(', ') + '); no zoom 2 picture shows a shadow without its caster; what differs: ' + pairDiff.join('; ')); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const T of NEW) for (const t of T.ticks) reached.add(keyOf(t.W)); for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side].scene) reached.add(keyOf(pairW(ps, sh, false)));
    for (const b of sh.setKey.baked) if (!reached.has(b.key)) P.push('state ' + b.key + ' is baked but nothing reaches it');
    for (const k of reached) if (!sh.setKey.baked.some(b => b.key === k)) P.push('state ' + k + ' is reached but not baked');
    notes.push('states: ' + sh.setKey.baked.length + ' baked states reached (' + sh.setKey.baked.map(b => b.key).join(', ') + '; every moment, pair and level picture), of the ' + ALL_STATES.length + ' the set can bake'); }
}
