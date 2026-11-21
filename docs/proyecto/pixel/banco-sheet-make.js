#!/usr/bin/env node
'use strict';
/* El banco's sheet (order 36a): writes docs/proyecto/pixel/banco-sheet.json from banco-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/banco-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.BANCO_SET), its part map, its depth, its grounds and every castShadow call from banco-set.html in headless
   Chrome, for every baked state; measures the old sprite layer (historia/engine.js, juego.js, kit.js and escenas/banco.js as they are: every
   person, dog, pigeon, the pushchair and every small thing drawn by banco.js draw() itself, against its own background); projects every world
   point with the engine's own formula; checks the sheet against coqui/ref/escenas/banco/ (positions.json, inventory.json, pairs.json); against
   every moment of every recorded run of the scene's stories (coqui/tool/ref/trazas/juega.mjs --states: the steps' ends); and against every
   tick inside the acts: the old page played by the same machine (page-init.js, page-drive.js: the same seed, think time and clock) with
   banco.js as the port will have it (the sheet's moves applied) and the story files' positions through the sheet's remap. It reads banco.js
   itself for every number that is a place on the picture (the sheet's code). It loads banco-preview.html (over a local http server it starts and
   stops) to check that the preview puts everyone where the sheet does. Nothing in the repo is written but the sheet. A second run writes the
   same bytes. El lago's maker (lago-sheet-make.js) is the model: the same rules, the same way of checking, the same way of naming the ask pictures.
   BANCO_NOCHECK=1: write the sheet only (for designing). BANCO_DUMP=<folder>: also write each run's step ends and ticks, the recorded and the
   port's, there (for the pictures; not in the repo). */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'banco-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/banco');
const BANCO_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/banco.js'), 'utf8');
const LINES = BANCO_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('banco.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const fnText = name => { const a = BANCO_JS.indexOf('function ' + name + '('); if (a < 0) throw new Error('banco.js changed: ' + name); let d = 0, i = BANCO_JS.indexOf('{', a);
  for (; i < BANCO_JS.length; i++) { if (BANCO_JS[i] === '{') d++; else if (BANCO_JS[i] === '}' && --d === 0) break; } return BANCO_JS.slice(a, i + 1); };

// the baked states: luz (dia, tarde, noche), luna (at night), carro (abierto, cerrado, no). setKey(W), as the port has it
const ALL_STATES = [];
for (const luz of ['dia', 'tarde', 'noche']) for (const luna of luz === 'noche' ? [0, 1] : [0]) for (const carro of ['abierto', 'cerrado', 'no']) ALL_STATES.push(luz + '.' + luna + '.' + carro);
const keyOf = w => (w.noche ? 'noche' : w.tarde ? 'tarde' : 'dia') + '.' + (w.noche && w.luna ? 1 : 0) + '.' + (w.carroX != null || w.carro === 0 ? 'no' : w.carro === 'cerrado' ? 'cerrado' : 'abierto');
const queryOf = k => { const [luz, luna, carro] = k.split('.'); return 'luz=' + luz + '&luna=' + luna + '&carro=' + carro; };
const BENCHES = ['banco0', 'banco1', 'banco2'];
const SOLID = ['banco0', 'banco1', 'banco2', 'carro', 'farol', 'poste', 'porton', 'seto', 'arbol0', 'arbol1', 'arbol2', 'cable'];
const FRONT = ['banco0', 'banco1', 'banco2', 'carro', 'farol', 'poste', 'porton', 'seto'];
const THING_OF = p => /^(arbol|seto|porton|cable|poste)/.test(p) ? 'parque' : p;   // the trees, the hedge, its gate, the pole and the wire are the park's

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, kinds: {}, rgb: {}, shadows: {}, ms: {} };
  for (const key of ALL_STATES) {
    await page.goto('file://' + path.join(__dirname, 'banco-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(BANCO_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; for (const k in GROUND_CACHE) delete GROUND_CACHE[k]; const t0 = performance.now(); buildSet(); const first = performance.now() - t0;
      const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      castShadow = cs0; part = part0;
      const onGround = [], surf = []; for (let i = 0; i < W * H; i++) {
        onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0);
        const ix = i % W, iy = Math.floor(i / W), s = BANCO_SET.surfaceAt(ix + .5, iy + .5);
        surf.push(s.on === 'sky' ? 's' : s.on === 'pave' ? 'p' : 'l'); }
      return { foot: FOOTPX(), F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), kinds: Array.from(kinds), rgb: rgbA, calls, bake: BAKE_MS, first, warm,
        shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, surf: surf.join(''), crown: CROWNPX(), pool: POOLPX(), GR: GRASS.map(c => rgb(...c)) };
    });
    G.ms[key] = { first: g.first, warm: g.warm, page: g.bake };
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, GR: g.GR, surf: g.surf });
    G.parts[key] = g.parts; G.z[key] = g.z; G.kinds[key] = g.kinds; G.rgb[key] = g.rgb; G.shadows[key] = g.calls;
    for (const k of ['shadowPx', 'onGround', 'crown', 'pool', 'foot']) (G[k] = G[k] || {})[key] = g[k];
  }
  if (errs.length) throw new Error(errs.join('; '));
  const mpage = await browser.newPage(); mpage.on('pageerror', e => errs.push(String(e)));
  G.M = await measure(mpage);
  const runs = storyStates();
  const sheet = make(G, runs);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.BANCO_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  G.TICKS = await tickStates(browser, runs, sheet);
  G.PV = await previewPlaces(browser, runs);
  if (process.env.BANCO_DUMP) { fs.mkdirSync(process.env.BANCO_DUMP, { recursive: true }); runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.BANCO_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states, ticks: G.TICKS[i].ticks }))); }
  // the sprite layer's shapes for every item seen at any moment (measured in the browser, banco.js draw() itself)
  G.MASK = await masks(mpage, collectKeys(sheet, G, runs));
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 300).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the old sprite layer, measured in the browser ----------
   historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/banco.js loaded as they are into a blank page. Every shape is what
   banco.js draw() itself draws for a world holding only that one thing, against the same world without it (its background, fondo): so a
   person's extras (the hat, the cane, the beard), what they hold, a dog's bone or shawl are all in its shape. A bubble is drawn as banco.js bub2
   draws it (twice its size, its tail's tip at the origin), on both frames of its bob */
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/banco.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  const q0 = lineOf('const QUIEN={'), q1 = lineOf('piraguero:{piel:');
  await page.addScriptTag({ content: '(()=>{const FAM=KIT.FAM,P=KIT.PIEL,H=KIT.PELO;' + LINES.slice(q0 - 1, q1).join('\n') + '\nwindow.QUIEN_=QUIEN;})();' });
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
    // the sprite's height of each person (sitting or standing), for the middle of the face: banco.js extra() draws at (x, top + 11)
    const heights = {}; for (const [id, w] of Object.entries(QUIEN_)) if (id !== 'abuela') for (const sent of [0, 1]) heights[id + '.' + sent] = KIT.mkPersona(w, 'idle', 0, sent).height;
    const frogMask = (() => { const cv = document.createElement('canvas'); cv.width = 60; cv.height = 60; const g = cv.getContext('2d'); g.drawImage(mkCoqui(1, 0, 0), 10, 10); const d = g.getImageData(0, 0, 60, 60).data, out = [];
      for (let y = 0; y < 60; y++) { let a = -1, b = -1; for (let x = 0; x < 60; x++) if (d[(y * 60 + x) * 4 + 3] > 40) { if (a < 0) a = x; b = x; } if (a >= 0) out.push([y - 10, a - 10, b - 10]); } return out; })();
    const HAND = (typeof HANDS !== 'undefined') ? null : null;
    return { bubbles, heights, frogMask, PX: KIT.PX };
  }).then(async m => { m.oldBg = await page.evaluate(async src => { const im = await new Promise(res => { const i = new Image(); i.onload = () => res(i); i.src = src; }); const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0); return Array.from(g.getImageData(0, 0, 240, 216).data); },
    'data:image/png;base64,' + fs.readFileSync(path.join(REF, 'frames/bg.banco.png')).toString('base64')); return m; });
}
// an item's key (what its shape depends on), and the world that draws it alone at (120, 150)
const SHAPE_AT = [120, 150];
function itemKey(kind, o, id) {
  const pick = (ks) => ks.map(k => o[k] == null ? '' : typeof o[k] === 'object' ? JSON.stringify(o[k]) : o[k]).join('|');
  if (kind === 'person') return 'p|' + id + '|' + pick(['pose', 'dir', 'sent', 'animo', 'hace', 'que', 'lleva', 'lleva2', 'lee', 'sin', 'ojos']);
  if (kind === 'dog') return 'd|' + id + '|' + pick(['tipo', 'pose', 'dir', 'lleva', 'chal', 'pena', 'mueve']);
  if (kind === 'pigeon') return 'g|' + pick(['pose', 'dir']);
  if (kind === 'coche') return 'c|' + pick(['capota', 'bebe', 'mano']);
  if (kind === 'thing') return 't|' + pick(['k', 'rot', 'charco']) + '|' + (o.k === 'caja' ? JSON.stringify(o.encaja || []) : '');
  return null;
}
function collectKeys(sheet, G, runs) {
  const keys = new Map();
  const add = w => { for (const it of rawItems(w)) if (it.key && !keys.has(it.key)) keys.set(it.key, it.spec); };
  for (const r of runs) for (const l of r.lines) add(l.W);
  for (const T of G.TICKS) { for (const t of T.ticks) add(t.W); for (const L of T.states) add(L.W); }
  for (const ps of pairSidesOf()) add(pairW(ps, sheet));
  return [...keys.entries()];
}
// the things a world shows, raw: their kind, id, the object, its key and the spec that draws it alone
function rawItems(w) {
  const out = [], shown = o => o && o.vis !== 0 && o.x != null;
  for (const [id, p] of Object.entries(w.gente || {})) if (shown(p) && !(p.al != null && p.al <= .3)) { const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0, paso: 0, bub: null }); out.push({ kind: 'person', id, o: p, key: itemKey('person', p, id), spec: { gente: { [id]: o } } }); }
  for (const [n, d] of Object.entries(w.perros || {})) if (shown(d)) { const o = Object.assign({}, d, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0, ronda: 0, paseo: 0, zzz: 0, correa: null }); out.push({ kind: 'dog', id: n, o: d, key: itemKey('dog', d, n), spec: { perros: { [n]: o } } }); }
  (w.palomas || []).forEach((p, i) => { if (shown(p)) { const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); out.push({ kind: 'pigeon', id: 'paloma ' + (p.i != null ? p.i : i), o: p, key: itemKey('pigeon', p), spec: { palomas: [o] } }); } });
  if (w.coche && w.coche.x != null) { const o = Object.assign({}, w.coche, { x: SHAPE_AT[0], y: SHAPE_AT[1], tiembla: 0, mece: 0 }); out.push({ kind: 'coche', id: 'coche', o: w.coche, key: itemKey('coche', w.coche), spec: { coche: o } }); }
  (w.cosas || []).forEach((c, i) => { if (shown(c)) { const o = Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); out.push({ kind: 'thing', id: 'cosa ' + (c.id || c.k + i), o: c, key: itemKey('thing', Object.assign({}, c, { encaja: w.encaja })), spec: { cosas: [o], encaja: c.k === 'caja' ? (w.encaja || []) : [] } }); } });
  return out;
}
// each key's shape: the rows [dy, x from, x to] relative to SHAPE_AT that banco.js draw() changes, its mean colour, its top row
async function masks(page, list) {
  return page.evaluate(list => {
    const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d');
    const E = ESCENAS.banco, base = () => ({ gente: {}, palomas: [], cosas: [], perros: {}, coche: null, bandeja: null, encima: null, manos: null, encaja: [], noche: 0, tarde: 0, luna: 0, carro: 0, carroX: null, seva: 0, cq: { x: 0, y: 0, s: 1, dy: 0, al: 1, vis: 0, bub: null } });
    const shot = w => { W = w; F = 0; TALK = null; g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.imageSmoothingEnabled = false; E.draw(g, w, 0); return g.getImageData(0, 0, 240, 216).data; };
    const bg = shot(base()), out = {};
    for (const [key, spec] of list) {
      const d = shot(Object.assign(base(), JSON.parse(JSON.stringify(spec)))), rows = []; let n = 0; const s = [0, 0, 0];
      for (let y = 0; y < 216; y++) { let a = -1, b = -1; for (let x = 0; x < 240; x++) { const i = (y * 240 + x) * 4; if (d[i] !== bg[i] || d[i + 1] !== bg[i + 1] || d[i + 2] !== bg[i + 2]) { if (a < 0) a = x; b = x; n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } } if (a >= 0) rows.push([y - 150, a - 120, b - 120]); }
      out[key] = { rows, mean: s.map(v => Math.round(v / Math.max(1, n))) };
    }
    return out;
  }, list);
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

/* ---------- the preview's places: banco-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/banco-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- banco.js as the port will have it: the sheet's moves and helps applied (the same edit as banco-preview.html's, without its drawing) ---------- */
function portSource(sheet) {
  let src = BANCO_JS; const done = new Set();
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); if (!src.includes(m.src)) throw new Error('banco.js does not hold ' + m.src); src = src.split(m.src).join(m.to); }
  for (const [a, b] of sheet.helps.lines) { if (!src.includes(a)) throw new Error('banco.js does not hold ' + a); src = src.split(a).join(b); }
  return src.replace('const B=BANCOS,', 'const GS=' + sheet.helps.shadow.gsSource + ',CARRORUEDA=()=>{},B=BANCOS,');
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

/* ---------- every tick inside the acts (as El lago's maker): the old page played by the same machine as the recorded runs, banco.js and the
   story files as the port will have them, the scene's W kept after every timer the runner fires when it changed ---------- */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = { gente: W.gente, perros: W.perros, palomas: W.palomas, cosas: W.cosas, coche: W.coche, cq: W.cq, manos: W.manos, bandeja: W.bandeja,
      encima: W.encima, encaja: W.encaja, noche: W.noche, tarde: W.tarde, luna: W.luna, carro: W.carro, carroX: W.carroX, seva: W.seva, tarjeta: W.tarjeta, marcas: W.marcas, respEn: W.respEn, resp: W.resp, spot: W.spot, F: typeof F === 'number' ? F : 0 };
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
        await ctx.route(/\/historia\/escenas\/banco\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
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

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'banco') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'banco-sheet-'));
  try {
    const runs = [];
    for (const st of stories) {
      execFileSync(process.execPath, [path.join(REPO, 'coqui/tool/ref/trazas/juega.mjs'), '--only', st.id, '--out', path.join(tmp, 'trazas', st.id), '--states', path.join(tmp, 'states')], { cwd: REPO, stdio: 'pipe' });
      for (const plan of ['right', 'wrong', 'alternate']) {
        const lines = fs.readFileSync(path.join(tmp, 'states', st.id, plan + '.states.jsonl'), 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
        runs.push({ story: st, plan, lines });
      }
    }
    return runs;
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}
const PAIRS = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
const pairSidesOf = () => PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'banco').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
// a pair picture's world, through the sheet's remap (cual.js panelW: the frog at 123, 150 s .86 unless the pair sets him)
function pairW(ps, sheet) {
  const base = { gente: {}, palomas: [], cosas: [], perros: {}, coche: null, carro: 1, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null } }, w = Object.assign(base, JSON.parse(JSON.stringify(ps.spec.set || {})));
  const mv = o => { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === Math.round(o.x) && e.old[1] === Math.round(o.y) && e.uses.some(u => u.startsWith('cual-banco.json'))); if (m) { o.x = m.new[0]; o.y = m.new[1]; } };
  for (const o of Object.values(w.gente || {})) mv(o); for (const o of Object.values(w.perros || {})) mv(o); for (const o of w.palomas || []) mv(o); for (const o of w.cosas || []) mv(o);
  if (w.cq && w.cq.vis) mv(w.cq);
  return w;
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  const surface = (sx, sy) => { const i = Math.floor(sy) * 240 + Math.floor(sx), s = sx < 0 || sx >= 240 || sy < 0 || sy >= 216 ? 'o' : G.surf[i]; return { on: s === 'p' ? 'pave' : s === 'l' ? 'lawn' : s === 's' ? 'sky' : 'out', w: atZ(sx, sy, 0) }; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ, surface };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const R = Math.round;

/* ---------- the old scene's numbers (historia/escenas/banco.js, read as text) ---------- */
const OLD = (() => { const m = BANCO_JS.match(/BANCOS=\[\[(\d+),(\d+)\],\[(\d+),(\d+)\],\[(\d+),(\d+)\]\],CARRO=\[(\d+),(\d+)\],FAROL=\[(\d+),(\d+)\],PORTON=\[(\d+),(\d+)\]/); if (!m) throw new Error('banco.js changed: BANCOS');
  const n = m.slice(1).map(Number), L = BANCO_JS.match(/const LUGAR=\{inicio:\[(\d+),(\d+),(\d+)\],centro:\[(\d+),(\d+),(\d+)\]\}/), P = BANCO_JS.match(/POSA=(\[\[[\d,\[\]]*?\]\])/);
  return { BANCOS: [[n[0], n[1]], [n[2], n[3]], [n[4], n[5]]], CARRO: [n[6], n[7]], FAROL: [n[8], n[9]], PORTON: [n[10], n[11]], LUGAR: { inicio: [+L[1], +L[2], +L[3]], centro: [+L[4], +L[5], +L[6]] }, POSA: JSON.parse(P[1]),
    ASIENTO: +BANCO_JS.match(/ASIENTO=(\d+)/)[1] }; })();
const OLDBOX = { carro: [OLD.CARRO[0] - 24, OLD.CARRO[1] - 72, 48, 74], farol: [OLD.FAROL[0] - 7, 34, 14, OLD.FAROL[1] - 28], banco0: [74, 127, 44, 36], banco1: [122, 127, 44, 36], banco2: [170, 127, 44, 36], parque: [0, 60, 240, 156] };

// the places a bubble's tail may go, in order (as El lago's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner card banco.js hud draws, in the 196 x 216 display (tarjeta(3, 3, 66, 24) covers [2, 2, 68, 26])
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];

/* ---------- the design: what moves and why (make() reads it) ---------- */
const SYSRC = 'SY=x=>{const k=x<120?0:x<168?1:2;return Math.round(161+(x-BANCOS[k][0])/2);},AS=x=>SY(x)-12';
const SYf = x => { const k = x < 120 ? 0 : x < 168 ? 1 : 2; return Math.round(161 + (x - OLD.BANCOS[k][0]) / 2); }, ASf = x => SYf(x) - 12;
function designMoves(F, POSA) {
  const B = OLD.BANCOS.map(b => b[0]);
  const sit = (who, x) => [who, [x, 161], [x, SYf(x)]];
  return [
    { act: '*', src: 'PORTON=[188,197];', to: 'PORTON=[188,197],' + SYSRC + ';', def: true,
      why: 'two rules the moves below use. SY(x): where whoever sits on a bench at x has their feet: the benches stand on the world\'s axes (along x), so each seat\'s front edge falls half a row for every px to the right; whoever sits keeps the old x and sits on that edge, their feet over the paving below it; at each bench\'s middle the old 161. AS(x) = SY(x) - 12: a thing put on the seat at x (the old ASIENTO, 149 at each bench\'s middle), two rows behind the edge' },
    { act: '*', src: 'await mueve(id,q[0]+(lado||0)*10,q[1]+11);', to: 'await mueve(id,q[0]+(lado||0)*10,SY(q[0]+(lado||0)*10));', why: 'sienta: whoever sits down sits on the seat\'s edge at their x (SY)' },
    { act: 'inicio21', src: 'hombre:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[2][0],y:161,dir:1,sent:1}', to: 'hombre:{x:B[0][0]-9,y:SY(B[0][0]-9),dir:1,sent:1},mujer:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},luis:{x:B[2][0],y:SY(B[2][0]),dir:1,sent:1}',
      pts: [sit('hombre', B[0] - 9), sit('mujer', B[1] - 9), sit('luis', B[2])], why: 'acts.inicio21: the three on the benches sit on the seats\' edges (SY)' },
    { act: 'inicio22', src: 'senor:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},joven:{x:B[2][0]-9,y:161,dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:161,dir:1,sent:1,lee:1}',
      to: 'senor:{x:B[0][0]-9,y:SY(B[0][0]-9),dir:1,sent:1},mujer:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},joven:{x:B[2][0]-9,y:SY(B[2][0]-9),dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:SY(B[0][0]+11),dir:1,sent:1,lee:1}',
      pts: [sit('senor', B[0] - 9), sit('mujer', B[1] - 9), sit('joven', B[2] - 9), sit('hombre', B[0] + 11)], why: 'acts.inicio22: the four on the benches (SY)' },
    { act: 'sientan', src: 'await mueve(k[0],B[k[1]][0]+k[2],161);', to: 'await mueve(k[0],B[k[1]][0]+k[2],SY(B[k[1]][0]+k[2]));', why: 'acts.sientan: they sit down again on the seats\' edges (SY)' },
    { act: 'inicio23', src: 'senora:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[0][0]-13,y:161,dir:1,sent:1,animo:"cansado"},hombre:{x:B[2][0]+2,y:161,dir:1,sent:1,animo:"triste"}',
      to: 'senora:{x:B[1][0]-9,y:SY(B[1][0]-9),dir:1,sent:1},luis:{x:B[0][0]-13,y:SY(B[0][0]-13),dir:1,sent:1,animo:"cansado"},hombre:{x:B[2][0],y:SY(B[2][0]),dir:1,sent:1,animo:"triste"}',
      pts: [sit('senora', B[1] - 9), sit('luis', B[0] - 13), ['hombre', [B[2] + 2, 161], [B[2], SYf(B[2])]]], why: 'acts.inicio23: the three on the benches (SY); the man on the third bench 2 px left, so that his hint frame stays 2 px inside the view (it did not in the old)' },
    { act: 'abuelallega', src: 'a.x=B[0][0]+5;a.y=161;', to: 'a.x=B[0][0]+7;a.y=SY(B[0][0]+7);', pts: [['abuela', [B[0] + 5, 161], [B[0] + 7, SYf(B[0] + 7)]]], why: 'acts.abuelallega: abuela sits down on the first bench (SY), 2 px further right than the old, apart from Luis (on the slanted seat she sits lower than he)' },
    { act: 'mira23', src: 's.x+=4;await wait(700);s.x-=4;', to: 's.x+=4;s.y+=2;await wait(700);s.x-=4;s.y-=2;', why: 'acts.mira23: the señora leans 4 px to the right along the seat: she keeps to its edge (2 rows lower)' },
    { act: 'dejan', src: '{id:"pir",k:"piragua",x:101,y:ASIENTO-4,rot:Math.PI/2},{id:"bot",k:"agua",x:153,y:ASIENTO}', to: '{id:"pir",k:"piragua",x:97,y:AS(97)-4,rot:Math.PI/2},{id:"bot",k:"agua",x:153,y:AS(153)}',
      pts: [['cosa', [101, OLD.ASIENTO - 4], [97, ASf(97) - 4]], ['cosa', [153, OLD.ASIENTO], [153, ASf(153)]]], why: 'acts.dejan: the piragua and the bottle left on the seats (AS); the piragua 4 px left, so that it lies on the seat\'s top clear of its right end, by the man who leaves it' },
    { act: 'paloma', src: 'await palomaA(pg,119,ASIENTO);', to: 'await palomaA(pg,109,AS(109));', pts: [['paloma', [119, OLD.ASIENTO], [109, ASf(109)]]], why: 'acts.paloma: the pigeon lands on the seat by the piragua: the old point (119) is past the new seat\'s right end; on the seat, 10 px left, its beak at the piragua (moved 4 px left too)' },
    { act: 'paloma', src: 'await palomaA(pg,163,ASIENTO);', to: 'await palomaA(pg,157,AS(157));', pts: [['paloma', [163, OLD.ASIENTO], [157, ASf(157)]]], why: 'acts.paloma: the pigeon lands on the seat by the bottle: on the seat, 6 px left (the old point is past the new seat\'s right end)' },
    { act: 'inicio22', src: '{id:"cartera",k:"cartera",x:157,y:ASIENTO},{id:"mochila",k:"mochila",x:204,y:ASIENTO+1}', to: '{id:"cartera",k:"cartera",x:154,y:AS(154)},{id:"mochila",k:"mochila",x:201,y:AS(201)+1}',
      pts: [['cosa', [157, OLD.ASIENTO], [154, ASf(154)]], ['cosa', [204, OLD.ASIENTO + 1], [201, ASf(201) + 1]]], why: 'acts.inicio22: the handbag and the rucksack on the seats (AS), 3 px left, clear of the seats\' right ends' },
    { act: 'turno22', src: '{id:"periodico",k:"periodico",x:108,y:ASIENTO}', to: '{id:"periodico",k:"periodico",x:105,y:AS(105)}', pts: [['cosa', [108, OLD.ASIENTO], [105, ASf(105)]]], why: 'acts.turno22: the newspaper left on the seat (AS), 3 px left, clear of its right end' },
    { act: 'cojin', src: '{id:"cojin",k:"mochila",x:B[0][0]-21,y:ASIENTO+1,z:150}', to: '{id:"cojin",k:"mochila",x:B[0][0]+12,y:AS(B[0][0]+12)+1,z:150}', pts: [['cosa', [OLD.BANCOS[0][0] - 21, OLD.ASIENTO + 1], [OLD.BANCOS[0][0] + 12, ASf(OLD.BANCOS[0][0] + 12) + 1]]],
      why: 'acts.cojin: Carmen puts the rucksack on the first bench as a cushion: the old point (B - 21) is past the new seat\'s left end, and Luis sits at its left end (B - 13); at its right end' },
    { act: '*', src: 'POSA=[[110,127],[158,127],[176,127],[208,127]]', to: 'POSA=' + JSON.stringify(POSA), pts: OLD.POSA.map((p, i) => ['paloma', p, POSA[i]]),
      why: 'where the pigeons perch on the benches\' backs (posa): on the top of each back at its x, which falls half a row a px to the right; the third (176) was past the third back\'s left end: 12 px right' },
    { act: '*', src: 'CARRO=[47,178]', to: 'CARRO=[34,178]', pts: [['piraguero', [51, 172], [38, 172]], ['carro', [47, 178], [34, 178]]], carroShift: -13,
      why: 'the cart and its man 13 px to the left: the cart lies along y in front of the man (down to the right of him on the screen, where the old one was drawn round him), so its middle is right of him; at the old point its right wheel stood where the frog serves whoever sits at the first bench\'s left (87, 179). W.carroX starts at CARRO[0] (carrova) and every place made from CARRO moves with it (the man: CARRO + (4, -6))' },
    { act: '*', src: 'fresh:()=>({respEn:[120,64],', to: 'fresh:()=>({respEn:[126,31],', respEn: [126, 31],
      why: 'where the answer cards stand (W.respEn, every story of the scene): in the sky under the rounds card, so that the hint drawn round a card (its frame, box + 12, and the hint hand under it, 45 px tall) falls on nobody\'s face: at the old (120, 64) the hand lay on the faces of whoever sits on the benches. Its frames and glow 4 px inside the view, right of the sun; over the wire\'s pigeons and the lamp\'s lantern (no ask with cards names them)' },
    { act: 'inicio22', src: 'W.casa=[124,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;', to: 'W.casa=[138,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;', pts: [['cq', [108, 178], [122, 178]]],
      why: 'acts.inicio22 (senor-senora): the frog\'s home 14 px right, so that his walks to the young dog (moved, below) take their old two hops; every other walk from it keeps its count (hops)' },
    { act: 'inicio22', src: 'W.perros={viejo:{x:90,y:193,pose:"sit",dir:1},joven:{x:38,y:193,pose:"sit",dir:1}}', to: 'W.perros={viejo:{x:104,y:193,pose:"sit",dir:1},joven:{x:52,y:193,pose:"sit",dir:1}}', pts: [['perro', [38, 193], [52, 193]], ['perro', [90, 193], [104, 193]]], why: 'acts.inicio22: the two dogs 14 px right: at 38 the young dog\'s hint frame (box + 12) left the view (as in the old); the old dog with it, and the frog\'s home (above), so that every walk of the frog between them and to them takes its old hops' },
    { act: 'perros22', src: 'L=[38,193],D=[90,193]', to: 'L=[52,193],D=[104,193]', why: 'acts.perros22: the dogs\' two places, as at the start (inicio22)' },
    { act: 'sale22', src: 'perroA("viejo",36,193,"walk"),perroA("joven",64,194,"run")', to: 'perroA("viejo",52,193,"walk"),perroA("joven",78,194,"run")', pts: [['perro', [36, 193], [52, 193]], ['perro', [64, 194], [78, 194]]], why: 'acts.sale22: the dogs move aside to the left: 16 and 14 px less far (their hint frames inside the view)' },
    { act: '*', src: 'if(pi)pi.x=W.carroX+30;', to: 'if(pi){pi.x=W.carroX+30;pi.y=CARRO[1]+2+(CARRO[0]-W.carroX)/2;}', why: 'the cart rolling away (W.seva): it rolls along +y (down to the left on the screen, half a row for every px), the piragua man pushing it from behind' },
    { act: '*', src: 'if(W.carro!==0)L.push({y:CARRO[1],d:()=>c.drawImage(spr("carro"+(W.carro==="cerrado"?1:0),()=>mkCarro(W.carro==="cerrado")),R(W.carroX!=null?W.carroX:CARRO[0])-24,CARRO[1]-72)});',
      to: 'if(W.carro!==0&&W.carroX!=null)L.push({y:CARRO[1]+(CARRO[0]-W.carroX)/2,carro:1,d:()=>CARRORUEDA(c,W)});',
      why: 'the cart: while it stands it is the set\'s (setKey carro abierto or cerrado: banco.js draws nothing); while it rolls (W.carroX) the set has none (carro no) and the sprite layer draws the set\'s own cart, pixel for pixel (sheet carro.rolling), moved by (R(W.carroX) - CARRO[0], R((CARRO[0] - W.carroX) / 2)), in the sorted list at its new row' },
  ];
}
// the story files' own places that move (sitting on a bench, a thing on a seat): the remap
function designStoryMoves() {
  const out = [], sit = x => ({ old: [x, 161], new: [x, SYf(x)], who: 'sitting', why: 'sitting on the bench at x ' + x + ': on its seat\'s edge (SY)' });
  for (const x of [87, 135, 138]) out.push(sit(x));
  out.push({ old: [51, 172], new: [38, 172], who: 'piraguero', why: 'the piragua man behind his cart: CARRO moved (moves)' });
  out.push({ old: [160, 150], new: [156, ASf(156) + 1], who: 'cosa', why: 'h-banco: the rucksack on the second bench\'s seat (AS), 4 px left, clear of its right end' });
  out.push({ old: [152, 149], new: [143, ASf(143)], who: 'cosa', why: 'cual-banco bebe.si: the bottle on the second bench\'s seat (AS), 9 px left: the pigeon by it moved left (the old point is past the seat\'s right end), its beak at the bottle as the old' });
  out.push({ old: [146, 145], new: [146, ASf(146) - 4], who: 'cosa', why: 'cual-banco bebe.no: the piragua lying on the second bench\'s seat (AS - 4, as the old ASIENTO - 4)' });
  out.push({ old: [162, 149], new: [157, ASf(157)], who: 'paloma', why: 'cual-banco bebe.si: the pigeon drinking on the second bench\'s seat, at its right end (AS)' });
  out.push({ old: [164, 149], new: [157, ASf(157)], who: 'paloma', why: 'cual-banco bebe.no: the pigeon eating on the second bench\'s seat, at its right end (AS)' });
  return out;
}

/* ---------- the sheet ---------- */
function make(G, runs) {
  const E = engine(G), F = G.F, KEY0 = 'dia.0.abierto';
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1, y1 + 1]; };
  // a part's pixels in every baked state (the cart's in the states that have it)
  const partPx = name => { const all = []; for (const k of ALL_STATES) all.push(...(G.parts[k][name] || [])); return all; };
  const floorW = (sx, sy) => { const s = E.surface(sx, sy); return { on: s.on, world: W4(s.w) }; };
  const seatW = (sx, sy) => { const w = E.atZ(sx, sy - 11, F.ZS); return { on: 'seat', world: W4(w) }; };   // whoever sits: the seat under their lap (y - 11)
  const frogW = q => floorW(q[0] + 16, q[1] + 25), placeW = p => floorW(p[0], p[1] - 1);
  const onSeatW = p => { const w = E.atZ(p[0], p[1] - 1, F.ZS); return { on: 'seat', world: W4(w) }; };

  /* the back's top (where a pigeon perches on a bench's back), at column c of bench k: the old POSA moved onto it */
  const backTop = (k, c) => { const b = F.BENCH[k], y = b.y0 + .065, z = F.ZS + F.BACK_H - .02, x = (c - E.OX) / E.S * E.R2 + y; return E.project(x, y, z).sy; };
  const POSA = [[110, 0], [158, 1], [188, 2], [208, 2]].map(([c, k]) => [c, Math.floor(backTop(k, c)) + 1]);
  const MOVES = designMoves(F, POSA).map(m => Object.assign({ line: lineOf(m.src) }, m, { lines: linesOf(m.src) }));
  for (const m of MOVES) for (const q of m.pts || []) q.push(q[0] === 'paloma' && m.src.startsWith('POSA') ? W4(E.atZ(q[2][0], q[2][1] - 1, F.ZS + F.BACK_H)) : q[0] === 'cosa' || q[0] === 'paloma' ? onSeatW(q[2]).world : q[0] === 'cq' ? frogW(q[2]).world : ['porton', 'piraguero', 'carro'].includes(q[0]) ? placeW(q[2]).world : seatW(q[2][0], q[2][1]).world);
  const STORY = designStoryMoves();

  // the old code's own drawing the engine replaces: the background, the moon, the night's colour, its patch, the lamp's glass and light, the evening's colour
  const DROPPED = [
    { src: 'c.drawImage(spr("banco",fondo),0,0);', to: '', why: 'the background (fondo): the set, for setKey(W)' },
    { src: LINES[lineOf('if(W.luna){c.fillStyle=OUT;') - 1].trim(), to: '', why: 'the moon: baked into the night sky (setKey luna; points.luna)' },
    { src: LINES[lineOf('if(W.noche){c.drawImage(spr("banco",fondo),84,6,46,38,196,6,46,38);') - 1].trim(), to: '', why: 'the night (setKey luz noche): its colour laid over the background is the set\'s night light (set-kit.js lightPass), its lit lantern and pool of light the set\'s; the patch of sky it copies over the sun (patch) is the night sky\'s, which has no sun' },
    { src: LINES[lineOf('if(W.tarde&&!W.noche){c.fillStyle=') - 1].trim(), to: '', why: 'the evening (setKey luz tarde): the set\'s warm light and evening sky' },
  ].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* spots: the frog's places of LUGAR and the named places of the old code; each keeps its screen place (the floor rule) but those moves name */
  const SPOTS = {};
  const spot = (k, at, what, kind = 'place', nw) => { const n = nw || at, w = kind === 'cq' ? frogW(n) : kind === 'sit' ? seatW(n[0], n[1]) : kind === 'seat' ? onSeatW(n) : placeW(n);
    SPOTS[k] = Object.assign({ world: w.world, on: w.on, old: at.slice(0, 2), new: n.slice(0, 2) }, kind === 'cq' ? { scale: 1 } : {}, nw ? { moved: true } : {}, { what }); };
  for (const [k, v] of Object.entries(OLD.LUGAR)) spot('frog.' + k, v, 'LUGAR.' + k + ': the frog\'s place q (his feet at q.x + 16, q.y + 25)', 'cq');
  OLD.BANCOS.forEach((b, i) => spot('sitio.' + i, [b[0], 161], 'BANCOS[' + i + ']: whoever sits at the middle of bench ' + i + ' (their feet; SY gives every other x)', 'sit', [b[0], SYf(b[0])]));
  spot('carro', OLD.CARRO, 'CARRO: the cart standing (its place in the sorted list; the set\'s cart is built round it, points.carro)');
  spot('piraguero', [OLD.CARRO[0] + 4, OLD.CARRO[1] - 6], 'CARRO + (4, -6): the piragua man, behind his cart');
  spot('porton', OLD.PORTON, 'PORTON: where one stands at the gate, before its opening');
  spot('porton.fuera', [246, OLD.PORTON[1]], 'where whoever leaves goes, out through the gate and off the picture');
  for (let i = 0; i < 5; i++) { const x = 66 + i * 17, y = R(50 + 7 * (1 - Math.pow((x - 120) / 98, 2))); SPOTS['cable.' + i] = { world: W4(cableWorld(F, x, y)), on: 'wire', old: [x, y], new: [x, y], what: 'CABLE(' + i + '): a pigeon on the wire (its feet on it): the wire hangs where the old one was' }; }
  OLD.POSA.forEach((p, i) => { SPOTS['respaldo.' + i] = { world: W4(E.atZ(POSA[i][0], POSA[i][1] - 1, F.ZS + F.BACK_H)), on: 'back', old: p, new: POSA[i], moved: true, what: 'POSA[' + i + ']: a pigeon on a bench\'s back (moves)' }; });

  /* the named points of the set */
  const P = (x, y, z = 0) => { const p = E.project(x, y, z); return [r2(p.sx), r2(p.sy)]; };
  const PTS = {
    bancos: F.BENCH.map((b, k) => ({ middle: [F.BANCOS[k], 151], seat: W4([b.x0, b.y0, F.ZS, b.x1, b.y1, F.ZS]), back: r4(F.ZS + F.BACK_H), corners: [P(b.x0, b.y1, F.ZS), P(b.x1, b.y1, F.ZS), P(b.x1, b.y0, F.ZS), P(b.x0, b.y0, F.ZS)] })),
    bancosWhat: 'each bench along x: its seat (x0, y0, z, x1, y1, z) at z ' + F.ZS + ', its back up to z ' + r4(F.ZS + F.BACK_H) + ' along its far side (y0); middle: the screen point of its seat\'s front edge at its middle (the old BANCOS x, row 151); corners: its seat\'s front left, front right, back right, back left on the screen',
    borde: { what: 'the paving\'s far edge, on the axes: behind each bench a stretch along x ' + F.EDGE_BACK + ' rows behind its back legs\' feet (hidden by the bench), a step along y between two benches (from column ' + F.STEP_AT.join(' and ') + '), and left of the first bench a stretch along y from column ' + F.TURN_AT + ' down to the picture\'s left edge; the lawn beyond it', rows: [0, 40, 80, 96, 110, 120, 134, 144, 158, 170, 192, 240].map(c => [c, r2(edgeRow(F, c))]) },
    seto: { line: 'sx + 2 sy = ' + F.HEDGE_K, x: r4(F.HEDGE_X), thick: F.HEDGE_T, high: F.HEDGE_H, what: 'the hedge along y across the lower right corner (its +x face on the line x = ' + r4(F.HEDGE_X) + ', on the screen sx + 2 sy = ' + F.HEDGE_K + '), ' + F.HEDGE_H + ' high' },
    porton: { posts: F.GATE, world: F.GATE_W.map(p => W4([F.HEDGE_X - F.HEDGE_T / 2, p[1], 0])), high: F.POST_H, what: 'the gate: the opening in the hedge between two stone posts (El camino\'s, without the arch) at the old gate\'s rows; the paving runs out through it along +x, between the lines through the two posts (sy - sx / 2 from ' + r2(F.GATE[1][1] - F.GATE[1][0] / 2) + ' to ' + r2(F.GATE[0][1] - F.GATE[0][0] / 2) + ')' },
    poste: { foot: F.POLE.at, top: [F.POLE.at[0], F.POLE.top], world: W4(E.atZ(...F.POLE.at, 0)), what: 'the pole at the left (the old one, rows 48 to 138), on the lawn' },
    farol: { foot: F.FAROL.at, lantern: F.FAROL.lamp, world: W4(E.atZ(...F.FAROL.at, 0)), what: 'the lamp post: its foot on the paving behind the gap between the second and third bench, its lantern at the old lantern\'s rows (' + F.FAROL.lamp[1] + ' to ' + F.FAROL.lamp[2] + ')' },
    cable: { what: 'the wire: it hangs from the pole\'s top to the lamp post and on off the picture; its plan the line on the ground from the pole\'s foot through the lamp post\'s; at every column it lies on the old wire\'s row (cableY), so every pigeon on it keeps its old point', plan: [F.POLE.at, F.FAROL.at], groundRow: 'the ground under the wire at column c: row ' + F.POLE.at[1] + ' + (c - ' + F.POLE.at[0] + ') * ' + r4((F.FAROL.at[1] - F.POLE.at[1]) / (F.FAROL.at[0] - F.POLE.at[0])) },
    luz: { pool: W4([...E.atZ(...F.FAROL.at, 0).slice(0, 2), F.POOL.rx]), what: 'the lamp\'s light (evening and night): a pool on the ground round its foot, radius ' + F.POOL.rx + ' (world), lighter towards the post; at night stronger' },
    arboles: F.TREES.map(t => ({ foot: t, world: W4(E.atZ(...t, 0)) })),
    arbolesWhat: 'El camino\'s small trees on the lawn beyond the paving (the old three, behind the benches): their feet; a lone tree\'s crown shade, lighter and solid (El campo\'s rule), on the lawn',
    carro: { world: W4([F.CART.x0, F.CART.y0, F.CART.z0, F.CART.x1, F.CART.y1, F.CART.z1]), wheels: F.WHEEL_R, what: 'the cart: a box along y on two wheels (at its two ends, on its +x side), its back face just in front of the piragua man (CARRO + (4, -6)); its umbrella\'s pole from its middle; open, a cone of eight panels red and white; closed, furled' },
    sol: { screen: F.SUN.slice(0, 2), radius: F.SUN[2], what: 'the sun (day and evening): upper left (every shadow falls to the right), right of the corner card\'s place, over the wire' },
    luna: { screen: F.MOON.slice(0, 2), radius: F.MOON[2], old: [64, 26, 9], what: 'the moon (W.luna, at night): in the night sky, under the corner card\'s place (the old one, at 64, 26, lay under it)' },
    nubes: { screen: F.CLOUDS, old: [[36, 16, 1], [112, 9, .7], [168, 26, .8]], what: 'the old picture\'s three clouds (engine.js sky()), clear of the sun, the moon and the corner card' },
    corazon: { screen: [110, 30], what: 'heartAt: unchanged' },
  };

  /* things: the 20 touch keys */
  const T = (name, what, pxs) => { const s = pxBox(pxs || partPx(name)), w = boxAround(s[0], s[1], s[2], s[3]); return { set: true, world: W4(w), box: box(w), screen: s, what, old: { box: OLDBOX[name] } }; };
  const sprite = why => ({ sprite: true, why });
  const things = {
    luis: sprite('a person (today\'s sprite, drawn 1:1). caja(id) (banco.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged'),
    carmen: sprite('as luis'), abuela: sprite('as luis'), hombre: sprite('as luis'), mujer: sprite('as luis'), senor: sprite('as luis'), joven: sprite('as luis'), senora: sprite('as luis'), piraguero: sprite('as luis'),
    perro_viejo: sprite('a dog (mkCan): [x - 15, y - 22, 30, 24] (banco.js:' + lineOf('const perroC=n=>') + '): unchanged'), perro_joven: sprite('as perro_viejo'), perro: sprite('as perro_viejo (Canelo)'),
    coche: sprite('the pushchair (mkCoche): [x - 19, y - 42, 38, 44]: unchanged'),
    pajaro: sprite('the pigeons (mkPaloma): the box round every one shown: unchanged'),
    carro: Object.assign(T('carro', 'the cart: its box, wheels, umbrella (open or closed), the bottles and the glass case'), { rolling: 'while it rolls (W.carroX) its box moves with it: [box x + R(W.carroX) - CARRO[0], box y + R((CARRO[0] - W.carroX) / 2), w, h]' }),
    farol: T('farol', 'the lamp post: its foot, its post, its lantern'),
    banco0: T('banco0', 'the first bench: seat, back, legs'), banco1: T('banco1', 'the second bench'), banco2: T('banco2', 'the third bench'),
    parque: { set: true, ground: true, box: [0, 40, 240, 176], what: 'the park: the paving, the lawn, the trees, the hedge and its gate, the pole and the wire; last in the hit order', old: { box: OLDBOX.parque } },
  };
  { const b = things.parque.box, x0 = Math.max(b[0], 22 + 14), y0 = Math.max(b[1], 14), x1 = Math.min(b[0] + b[2], 22 + 196 - 14), y1 = Math.min(b[1] + b[3], 216 - 14); things.parque.hintBox = [x0, y0, x1 - x0, y1 - y0]; things.parque.hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches'; things.parque.hand = [120, 186]; things.parque.handWhy = 'on the open paving before the benches'; }
  for (const k of ['farol', 'carro', ...BENCHES]) { const b = things[k].box; things[k].hand = [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)]; }
  things.farol.hand = [F.FAROL.at[0], 100]; things.farol.handWhy = 'on the post, under the wire';

  const views = { wide: { zoom: 1, x0: 22, world: W4(E.atZ(120, 150, 0)), region: null, old: [22, 0, 196, 216], what: 'the corner: the benches in the middle, the cart at the left, the lamp post, the gate at the right, the lawn and trees behind, the sky' } };

  /* the review and level pictures */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, R(cx - 98))), Math.max(0, Math.min(112, R(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, R(cx - 49))), Math.max(0, Math.min(164, R(cy - 26))), 98, 52];
    const w = floorW(cx, cy); return { world: w.world, screen: [cx, cy], zoom, crop, what }; };
  const PICS = {
    'hombre.si': pic(144, 137, 2, 'the man sitting on the second bench, reading'), 'hombre.no': pic(144, 137, 2, 'the woman sitting there, reading'),
    'senor.si': pic(144, 136, 2, 'the old man sitting on the bench'), 'senor.no': pic(144, 136, 2, 'Luis sitting there'),
    'come.si': pic(144, 137, 2, 'the man on the bench eating a piragua'), 'come.no': pic(144, 137, 2, 'the man drinking water'),
    'cansado.si': pic(144, 138, 2, 'Luis on the bench, tired'), 'cansado.no': pic(144, 138, 2, 'Luis on the bench, happy, waving'),
    'contento.si': pic(144, 137, 2, 'the man on the bench, happy'), 'contento.no': pic(144, 137, 2, 'the man on the bench, crying'),
    'mujer.si': pic(146, 160, 1, 'the woman walking on the paving'), 'mujer.no': pic(146, 160, 1, 'Carmen walking there'),
    'senora.si': pic(146, 160, 1, 'the woman with a bag, the frog'), 'senora.no': pic(146, 160, 1, 'the young man with a bag, the frog'),
    'joven.si': pic(146, 160, 1, 'the young man walking'), 'joven.no': pic(146, 160, 1, 'the old man walking'),
    'viejo.si': pic(98, 190, 2, 'the old dog walking'), 'viejo.no': pic(98, 190, 2, 'the young dog walking'),
    'duerme.si': pic(98, 190, 2, 'Canelo asleep'), 'duerme.no': pic(98, 190, 2, 'Canelo lying with a bone'),
    'triste.si': pic(98, 190, 2, 'Canelo sad'), 'triste.no': pic(98, 190, 2, 'Canelo tired'),
    'bebe.si': pic(152, 140, 2, 'a pigeon drinking from a bottle on the bench'), 'bebe.no': pic(152, 140, 2, 'a pigeon eating a piragua on the bench'),
  };
  const LEVEL = PAIRS.level.flatMap(L => L.pictures.map((p, i) => p.scene === 'banco' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* remap: every distinct position of positions.json */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
      const ats = p.uses.map(u => u.at), mv = STORY.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y];
      const isFrog = ats.every(a => /\.cq$/.test(a)), isSit = ats.some(a => /gente\.\w+$/.test(a)) && p.y === 161, isSeat = mv && (mv.who === 'cosa' || mv.who === 'paloma') || (p.y >= 145 && p.y <= 150 && p.x > 70 && p.x < 220);
      const w = isFrog ? frogW(at) : isSit ? seatW(at[0], at[1]) : isSeat ? onSeatW(at) : placeW(at);
      e.to = { [w.on]: w.world }; e.new = at.slice(); if (mv) { e.moved = true; e.why = mv.why; }
      e.what = (isFrog ? 'the frog\'s place q: the ground under (x + 16, y + 25)' : isSit ? 'sitting on a bench: the seat under the lap (x, y - 11)' : isSeat ? 'on a bench\'s seat: the seat under (x, y - 1)' : 'a place (x, y): the ground under (x, y - 1)') + (mv ? '; moved (why)' : '; the same screen place');
    }
    return e;
  });

  const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSidesOf()) reached.add(keyOf(Object.assign({ carro: 1 }, ps.spec.set || {})));
  const setKey = {
    params: { luz: 'W.noche ? "noche" : W.tarde ? "tarde" : "dia"', luna: 'W.noche && W.luna ? 1 : 0', carro: 'W.carroX != null || W.carro === 0 ? "no" : W.carro === "cerrado" ? "cerrado" : "abierto"' },
    key: 'luz + "." + luna + "." + carro',
    baked: ALL_STATES.filter(k => reached.has(k)).map(k => ({ key: k, query: '?' + queryOf(k) })),
    notReached: ALL_STATES.filter(k => !reached.has(k)),
    bakedWhy: 'order 06 found 49 states made by eleven keys. Three are the set\'s: tarde and noche (the light of the hour: the evening\'s warm light and sky, the night\'s light, sky and lit lamp; noche always comes with tarde), luna (the moon in the night sky) and carro with carroX (the cart open, closed or gone; rolling, it is the sprite layer\'s and the set has none). The other seven are things the sprite layer draws, as the old: bandeja (the tray over the frog), coche (the pushchair, which moves), encaja (what is in the box), encima (what the frog carries on his head), manos (what he holds), seva (the cart and the dogs going home: it moves them in draw()). So setKey reads luz, luna and carro; every other key is the sprite layer\'s',
    spriteKeys: { bandeja: 'rana(): the tray over the frog', coche: 'coche(): the pushchair (a moving thing: W.coche.x, y)', encaja: 'draw(): what lies in the box (W.cosas caja)', encima: 'rana(): what he carries on his head', manos: 'rana(): what he holds', seva: 'draw(): moves the cart, the piragua man and the dogs (the rolling cart: carro.rolling)', carroX: 'the rolling cart\'s place (carro.rolling); a set key only as "rolling or not" (carro no)' },
  };

  const SCR_ROW = c => edgeRow(F, c);
  return {
    scene: 'banco',
    made: 'node docs/proyecto/pixel/banco-sheet-make.js, from banco-set.html (window.BANCO_SET) and coqui/ref/escenas/banco/. Order 36a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin (El camino\'s, El campo\'s and El lago\'s); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the corner is built round the old picture: a place keeps its screen place and its world point is the ground under it (the paving or the lawn, z 0): a frog place q under (q.x + 16, q.y + 25); a person\'s, a dog\'s, a pigeon\'s on the ground, the pushchair\'s or a thing\'s place (x, y) under (x, y - 1). Whoever sits (sent) is on a seat: their world point the seat under their lap (x, y - 11, z ' + F.ZS + '), their feet at SY(x) (moves). A thing on a seat, under (x, y - 1) at the seat\'s height; a pigeon on a bench\'s back, on its top; on the wire, on the wire (points.cable). So every position of banco.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each (spots, remap, code)',
      relative: 'what the old code draws or moves relative to a person, the frog, a dog, a pigeon or the pushchair (what is carried, a frog place by whoever he serves, a toy thrown from the pushchair, the bubbles) keeps its offsets: a sitter\'s moved feet move what is relative to them',
      sky: 'screen-space effects keep their old numbers: the stars of the endings, the heart (heartAt)',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: {
      what: 'the paved corner of the park on the world\'s axes at the engine\'s 30 degrees: the paving (flags along x and y) from the benches to the picture\'s lower edge, its far edge stepped along the axes behind the benches; the lawn beyond it with El camino\'s three trees and the pole; the three benches each along x, stepped so that each one\'s seat edge passes its old point; the cart along y at the left; the lamp post behind the benches; the wire from the pole to the lamp post and on; the hedge along y across the lower right corner with the gate in it, the paving running out through it; El camino\'s hills and day sky, by the hour',
      why: 'the brief and page 11 decision 9: the set stands on the world\'s axes, nothing square to the camera. The old benches stood in one level row facing us, the old paving began on one level row and the old hedge ran down the right edge: none of these lies on a world axis. Each bench lies along x (its seat and back facing +y, the lit side, towards the camera), its middle at the old BANCOS; a seat along x falls half a row a px, so whoever sits keeps the old x and sits on its edge (moves: SY), with the back behind them. The paving\'s far edge runs behind each bench along x (hidden by it) and steps along y between them, so that behind every head on a bench is the lawn as in the old picture (the old paving began behind the backs), and the trees stand on the lawn. Left of the first bench the edge turns along y, so the cart and its way out (it rolls along +y) are on the paving. The hedge lies along y across the lower right corner, the gate in it where the old gate was, so that whoever leaves (to x 246 on the old gate\'s rows) walks out through its opening',
      edge: SET_EDGE_NOTE,
    },
    behind: { what: 'nothing: the sun, the moon and the clouds are baked into the set\'s sky', items: [] },
    setKey,
    light: {
      tarde: 'the evening (W.tarde): the set under a warm light (set-kit.js lightPass m .9 .8 .72, a 34 16 4, the blades keep their lit colours, El frente\'s dusk), the evening sky, the sun where it is by day (the old evening kept its sun), the lantern lit with a faint pool of light; the sun still casts the shadows',
      noche: 'the night (W.noche): the set under El patio\'s night light (m .56 .62 .82, a 6 10 30; every blade in its shade colour), El patio\'s night sky, no sun, the moon when W.luna, the lantern lit (its glass keeps its colour) and its pool of light on the ground round the lamp post\'s foot; nothing casts a shadow (the one rule: the sun casts every shadow, and at night there is none; the set bakes none and the engine casts none for anyone)',
      sprites: 'not darkened, as the old page: banco.js draw() laid the night\'s colour (rgba(30, 24, 90, .32)) and the evening\'s (rgba(255, 150, 60, .10)) over its background only, before the sorted list; every person, animal and thing was drawn after it in its own colours. The port draws the sprite layer as by day at every hour (dropped)',
      shadows: 'day and evening: the sun\'s (upper left), cast to screen right, for the set and for everyone (shadows); night: none',
    },
    patch: {
      old: 'banco.js:' + lineOf('if(W.noche){c.drawImage(spr("banco",fondo),84,6,46,38,196,6,46,38);') + ': at night the old page copied a 46 x 38 patch of its own background from (84, 6) to (196, 6), before the night colour',
      what: 'it hid the sun: the old sun was baked into the background at (210, 17) (engine.js sky(): W - 30, radius 8), and the patch laid a piece of the sky (with the cloud at 112, 9) over it, so that the night sky had no sun',
      kept: 'by the set: the night sky (setKey luz noche) is drawn without a sun (and with the moon when W.luna). The port copies nothing: there is no snapshot of the picture in El banco (Ctx.snapshot is not called)',
    },
    carro: {
      standing: 'the set\'s: setKey carro abierto (its umbrella open) or cerrado (furled); banco.js draws nothing for it; its box things.carro.box; whoever stands behind it (the piragua man) has its pixels drawn over them (front)',
      rolling: 'while W.carroX is set the set is baked with no cart (setKey carro no) and the sprite layer draws the cart: the pixels the set\'s part "carro" has in the baked state with the same luz and luna and carro cerrado (each pixel\'s colour and depth: the same cart, pixel for pixel), moved by dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2) (along +y: the cart rolls on its wheels\' line), drawn in the sorted list at y CARRO[1] + (CARRO[0] - W.carroX) / 2 (moves). It rolls only at night: no shadow. Its touch box moves with it (things.carro.rolling)',
      sprite: { from: 'state <luz>.<luna>.cerrado, part carro', at: 'dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2)' },
    },
    things,
    spots: SPOTS,
    lugar: Object.fromEntries(Object.entries(OLD.LUGAR).map(([k, v]) => [k, { spot: 'frog.' + k, q: v.slice(0, 2), scale: v[2], old: v.slice(0, 2) }])),
    hops: [], hopsAll: [],
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'banco.js never calls clip()',
    smoothing: 'banco.js never turns smoothing on (respIcon turns it off)',
    front: {
      how: 'the old background (fondo: the benches, the lamp post, the pole, the hedge and its posts) was drawn before everyone, and the cart was in the sorted list; now each is a set thing someone can be behind. At its entry in the list banco.js draw sorts by y (sortY 9999: after everyone), for each item drawn before it (a person, the frog, a dog, a pigeon, the pushchair, a thing: each item says what it is), the set\'s own pixels of the part (banco-set.html part(), PART_TAGS) are drawn again inside the item\'s box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under it (rules.floor). Whoever sits on a bench (sent) stands in the plane of that bench\'s seat front (its y1) + .03: so nothing of their bench is drawn over them, and its back stays behind them. A thing or a pigeon on a seat stands in the plane of the seat\'s point under its lowest row + 1 (at the seat\'s height) + .02: under (x, y), and under (x, y + 5) for a thing lying on its side (rot: the piragua, whose width reaches forward), a pigeon on a bench\'s back in that of the back\'s top; a pigeon on the wire is drawn over everything. "Behind the bench" is that depth test, not a row',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      boxes: 'a person: [x - 24, y - 60 - dy, 48, 63 + dy]; the frog: frogBox with dy; a dog: [x - 16, y - 24 - dy, 32, 27 + dy]; a pigeon: [x - 10, y - 14, 20, 16]; the pushchair: [x - 21, y - 42, 42, 45]; a thing: [x - 15, y - 34, 30, 36]; its ground point under (x, y - 1)',
      parts: Object.fromEntries(FRONT.map(p => [p, { sortY: 9999, insert: 'before the sort: L.push({y: 9999, front: "' + p + '"})' }])),
      tags: [
        ['L.push({y:p.sent?p.y-8:p.y,d:()=>gente(c,id,a)})', 'L.push({y:p.sent?p.y-8:p.y,id,d:()=>gente(c,id,a)})'],
        ['(W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,d:()=>{', '(W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,pal:o,d:()=>{'],
        ['(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{', '(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,cosa:o,d:()=>{'],
        ['if(o&&o.vis!==0)L.push({y:o.y,d:()=>perro(c,n,a)})', 'if(o&&o.vis!==0)L.push({y:o.y,perro:n,d:()=>perro(c,n,a)})'],
        ['if(W.coche)L.push({y:W.coche.y,d:()=>coche(c,a)});', 'if(W.coche)L.push({y:W.coche.y,coche:1,d:()=>coche(c,a)});'],
        ['if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});', 'if(q.vis)L.push({y:q.y+27,id:"coqui",d:()=>rana(c,q,a)});'],
      ],
      tagsWhat: 'each item of the sorted list says what it is (the front masks read it); nothing else changes',
    },
    shadows: {
      rule: 'every shadow is the sun\'s (day and evening; at night none: light.noche), cast from the ground point (z 0) under the screen point of the thing\'s feet (unproject), and darkens only pixels that take a cast shadow (the paving and the lawn, at their own depth)',
      coqui: { radius: .45, at: 'unproject(b.x + b.w / 2, q.y + 25)', when: 'W.cq.vis and al > .5, not W.noche', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: .32, at: 'unproject(x, y - 1); sitting: the ground under their feet, unproject(x, y)', when: 'visible (vis !== 0, al > .5), not W.noche', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .32) (sitting: z .3 and .65)' },
      perros: { radius: .32, at: 'unproject(x, y - 1)', when: 'every dog shown (not in the air: dy <= 3), not W.noche', cast: 'castShadow(g.x, g.y, .25, .32)' },
      coche: { radius: .45, at: 'unproject(x, y - 1)', when: 'W.coche, not W.noche', cast: 'castShadow(g.x, g.y, .3, .45), castShadow(g.x, g.y, .9, .4)' },
      paloma: { radius: .16, at: 'on the ground: unproject(x, y - 1); in the air (palomaA, pose vuela): unproject(o.gs) (helps.shadow)', when: 'on the ground or in the air, not on the wire, a bench\'s back or seat, the pushchair, not W.noche', cast: 'castShadow(g.x, g.y, .1, .16)' },
      cosas: { radius: .18, at: 'unproject(x, y - 1)', when: 'a thing lying on the ground (not on a seat, not in the air: z unset or <= its y), not W.noche', cast: 'castShadow(g.x, g.y, .1, .18) (the box: .4)' },
      dropped: 'none of the old code\'s own: banco.js draws no shadow',
    },
    helps: {
      what: 'a pigeon in the air has its shadow on the ground under it: palomaA keeps, at every step of its flight, the screen point on the ground under it (o.gs): between the ground under where it took off and the ground under where it lands, as far along as it has flown (GS); landed, none',
      lines: [
        ['o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-Math.sin(Math.PI*t)*8;await wait(TICK);}o.x=x;o.y=y;o.pose="";', 'o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-Math.sin(Math.PI*t)*8;o.gs=GS(x0,y0,x,y,t);await wait(TICK);}o.x=x;o.y=y;o.pose="";o.gs=null;'],
      ],
      linesWhat: 'the lines banco.js gains; GS (shadow.gsSource) is defined in the line of B and ASIENTO (const GS=..., B=BANCOS, ...); the port draws the rolling cart where the edited line calls CARRORUEDA (carro.rolling)',
      shadow: {
        gs: 'GS(x0, y0, x1, y1, t): the ground under a perch (x, y): on the wire (|y - cableY(x)| <= 2, y < 80): [x, ' + F.POLE.at[1] + ' + (x - ' + F.POLE.at[0] + ') * ' + r4((F.FAROL.at[1] - F.POLE.at[1]) / (F.FAROL.at[0] - F.POLE.at[0])) + '] (points.cable); on a bench\'s back (a POSA): [x, y - 1 + (ZS + BACK_H) * COS * S]; on a seat (a bench\'s seat at that row): [x, y - 1 + ZS * COS * S]; else [x, y - 1]. The shadow: lerp of the two by t',
        gsSource: gsSource(F, POSA),
      },
      margin: 6, marginWhat: 'whatever rests near the paving\'s edge, the hedge, a bench, the lamp post or the gate is on one side: on the paving with at least `margin` px of paving round its foot (the lowest 2 rows of its sprite), or on the lawn with `margin` px of lawn, and `margin` px from the footprint of every set thing (where it meets the ground: a bench\'s leg, a post, the hedge, the lamp post\'s foot, the cart, a trunk; banco-set.html FOOTS); what stands behind a thing is drawn behind it (front), what stands in front of it before it',
    },
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines.length > 1 ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.pts && m.pts.length ? { places: m.pts.map(q => ({ who: q[0], old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    dropped: DROPPED,
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as banco.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (banco.js draw: line ' + lineOf('Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a person, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud) and of every face; if none is, the first (the old)',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1',
      faces: 'a person\'s face: [x - 6, top + 6, 12, 10] (eyes to chin), top the sprite\'s first row (y - height + 1 - dy, + 3 tired, + 1 sad: banco.js gente; heights); abuela\'s: from her sprite (the middle of its top 10 rows); the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heights: G.M.heights,
      board: BOARD, boardWhat: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta (the rounds card) [2, 2, 68, 26]',
    },
    code: codeEntries(MOVES, DROPPED, things),
    checks: { notes: [] },
  };
}
const SET_EDGE_NOTE = 'a look candidate (banco-set.html ?edge=straight): the paving\'s far edge one straight line along y, from the left edge up to the right: it reaches the horizon right of the middle, so the paving runs to the hills behind the third bench and the lamp post; kept recoverable, not built on';
function edgeRow(F, c) {
  const back = (k, cc) => 151 + (cc - F.BANCOS[k]) / 2 - F.BD * 26 / Math.SQRT2 + F.ZS * Math.sqrt(3) / 2 * 26, seg = (k, cc) => back(k, cc) - F.EDGE_BACK;
  if (c <= F.TURN_AT) return seg(0, F.TURN_AT) + (F.TURN_AT - c) / 2;
  for (let k = 0; k < 3; k++) { if (k === 2 || c <= F.STEP_AT[k]) return seg(k, c); const r = seg(k, F.STEP_AT[k]) - (c - F.STEP_AT[k]) / 2; if (r >= seg(k + 1, c)) return r; }
  return seg(2, c);
}
// the world point on the wire at a screen column (points.cable): its plan the ground line from the pole's foot through the lamp post's
function cableWorld(F, sx, sy) {
  const OX = 120 + (0), OY = 108 + 4, S = 26, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const atZ = (a, b, z) => { const u = (a - OX) / S, v = (b - OY + z * COS * S) / (S * .5); return [(u + v) / R2, (v - u) / R2, z]; };
  const gr = F.POLE.at[1] + (sx - F.POLE.at[0]) * (F.FAROL.at[1] - F.POLE.at[1]) / (F.FAROL.at[0] - F.POLE.at[0]), z = (gr - sy) / (COS * S);
  return atZ(sx, sy, z);
}
function gsSource(F, POSA) {
  const k = r4((F.FAROL.at[1] - F.POLE.at[1]) / (F.FAROL.at[0] - F.POLE.at[0])), hb = r4((F.ZS + F.BACK_H) * Math.sqrt(3) / 2 * 26), hs = r4(F.ZS * Math.sqrt(3) / 2 * 26);
  return '(x0,y0,x1,y1,t)=>{const g=(x,y)=>Math.abs(y-cableY(x))<=2&&y<80?[x,' + F.POLE.at[1] + '+(x-' + F.POLE.at[0] + ')*' + k + ']:POSA.some(p=>Math.abs(p[0]-x)<=1&&Math.abs(p[1]-y)<=1)?[x,y-1+' + hb + ']:(y>=140&&y<=170&&Math.abs(y-AS(x))<=2&&x>75&&x<215)?[x,y-1+' + hs + ']:[x,y-1],a=g(x0,y0),b=g(x1,y1);return [a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];}';
}

/* ---------- code: every line of banco.js that holds a number, and what each number is ----------
   The maker reads banco.js itself (not order 06's inventory): it finds every numeric literal outside comments and strings, sorts each by what it is
   from where it stands (a place on the picture; an offset from someone; a time, a sound, a count; a draw order; a sprite's or a sign's own
   drawing), and the sheet names, line by line, what becomes of its places (moved, the floor rule, a set thing, dropped). check() fails if a line
   with a place has no entry, or an entry misses one of its place numbers */
const REGIONS = (() => {
  const at = s => lineOf(s), out = [];
  const r = (a, b, kind, why) => out.push({ a, b, kind, why });
  r(at('function fondo(){'), at('return b.done();}') , 'dropped', 'the background (fondo): the set, dropped');
  r(at('function mkCarro('), at('function bub2(') - 1, 'drawing', 'a sprite\'s own drawing (the old cart, the small things, the pigeon, the dogs, the pushchair) or what is drawn relative to someone (extra, animo, tenida, gente, rana, perro, coche): relative to where it is drawn, unchanged');
  r(at('function bub2('), at('function bub2('), 'drawing', 'the bubble drawn twice its size: unchanged');
  r(at('function talkAt('), at('function respIcon(') + 5, 'drawing', 'the frog\'s doing bubbles, the music note, talkAt\'s offset over the head: relative, unchanged');
  r(at('function hud(g,W,a){'), at('const marca=m=>'), 'drawing', 'the rounds card in the corner (hud): screen space, unchanged (talk.board)');
  r(at('const ladra=n=>'), at('const ladra=n=>'), 'sound', 'a sound');
  r(at('const llanto=()=>'), at('const palmas=()=>'), 'sound', 'sounds');
  r(at('async function stake('), at('const estado=W=>'), 'other', 'stake, poke and estado: sounds and the state line, no place');
  return out;
})();
const regionOf = L => REGIONS.find(r => L >= r.a && L <= r.b);
const stripLine = l => l.replace(/\/\/.*$/, '').replace(/"(?:[^"\\]|\\.)*"/g, '""');
const numsOf = l => { const out = []; const re = /(?<![\w#.$])(\d+\.\d+|\d+|\.\d+)(?![\w])/g; let m; while ((m = re.exec(l))) out.push({ n: m[1], at: m.index }); return out; };
// what a number is, from the text before and after it
function numKind(l, at, n) {
  const before = l.slice(Math.max(0, at - 40), at), after = l.slice(at + n.length, at + n.length + 6);
  if (/(wait|setTimeout)\($/.test(before) || /tone\([^()]*$/.test(before) || /SFX\.\w+\($/.test(before) || /bounce\($/.test(before) || /\bms\s*\|\|\s*$/.test(before) || /F\s*[-%\/]\s*[\w.]*\)?\s*[%\/]\s*$/.test(before) || /\(F>>$|F>>$/.test(before) || /\/$/.test(before) && /Math\.sin\(t$|F\/$/.test(before)) return 'time';
  if (/[<>]=?\s*$|===?\s*$|!==?\s*$|%\s*$|Math\.(min|max)\(\s*$|\|\|\s*$|\bn2\b|\?\s*$|>>\s*$|<<\s*$|\.length\s*[<>]=?\s*$|\bk<\s*$|\bi<=?\s*$/.test(before)) return 'count';
  if (/\bz:\s*-?$|\.z\s*=\s*$|pg\.z=\s*$|\bo\.z=\s*$/.test(before)) return 'order';
  if (/\b(dy|al|s|h|fase|mano|capota|vis|sent|paso|tiembla|mece|ojos|pena|chal|lee|dir|posadas|juguetes|concojin|n|i|bandeja|carro|tarde|noche|luna|seva|marcas|ronda|paseo)\s*[:=]\s*-?$/.test(before) || /\.dy\s*=\s*-?$|\.dy\s*[+-]=\s*$/.test(before)) return 'state';
  if (/Math\.PI\s*[*\/]\s*$|\*\s*$|Math\.sin\([^()]*$|Math\.cos\([^()]*$|Math\.hypot\([^()]*$|\/\s*$/.test(before) || /^\s*\*/.test(after)) return 'scale';
  if (/\b[xy]\s*:\s*-?$|\b[xy]\s*:\s*\w[\w.\[\]]*\s*[+-]\s*$|\.[xy]\s*=\s*-?$|\.[xy]\s*[+-]=\s*$/.test(before)) return /[+-]\s*$/.test(before) && !/:\s*-$|=\s*-$/.test(before) ? 'offset' : 'place';
  if (/(mueve|palomaA|ranaA|perroA|hopTo|alcable|boteA)\([^()]*$/.test(before)) return /[+-]\s*$/.test(before) && !/[(,]\s*-$/.test(before) ? 'offset' : 'place';
  if (/\[\s*-?$|\[\s*\d+\s*,\s*-?$|\],\s*\[\s*-?$|,\s*-?$/.test(before) && /^\s*[,\]]/.test(after)) return 'place';
  if (/[+-]\s*$/.test(before)) return 'offset';
  return 'other';
}
function codeEntries(MOVES, DROPPED, things) {
  const C = [];
  for (let L = 1; L <= LINES.length; L++) {
    const raw = LINES[L - 1], l = stripLine(raw), ns = numsOf(l); if (!ns.length) continue;
    const reg = regionOf(L), kinds = {}; for (const { n, at } of ns) { const k = reg ? reg.kind : numKind(l, at, n); (kinds[k] = kinds[k] || []).push(n); }
    const mv = MOVES.filter(m => (m.lines || [m.line]).includes(L)), dr = DROPPED.filter(d => d.line === L);
    const e = { line: L, numbers: kinds };
    if (dr.length) { e.to = { dropped: true }; e.note = dr.map(d => d.why).join('; '); }
    else if (mv.length) { e.to = { moves: mv.map(m => m.src) }; e.note = 'moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; ') + (kinds.place ? '; every other place here keeps its screen place (the floor rule)' : ''); }
    else if (reg) { e.to = reg.kind === 'dropped' ? { dropped: true } : 'unchanged'; e.note = reg.why; }
    else if (kinds.place) { e.to = { floor: true }; e.note = 'places on the picture: each keeps its screen place, its world point the ground under it (rules.floor)'; }
    else { e.to = 'unchanged'; e.note = 'no place: ' + Object.keys(kinds).join(', '); }
    C.push(e);
  }
  // the named lines: the constants, the boxes, the view
  const set = (L, to, note) => { const e = C.find(q => q.line === L); if (!e) throw new Error('code: no numbers on line ' + L); e.to = to; e.note = note; };
  set(lineOf('const SUELO=132,BANCOS='), { moves: ['PORTON=[188,197];'], points: ['bancos', 'carro', 'farol', 'porton'], spots: ['sitio.0', 'sitio.1', 'sitio.2', 'carro', 'porton'] }, 'SUELO (the old paving\'s first row): the set\'s paving (points.borde); BANCOS: the benches, each along x, the middle of its seat\'s edge at the old point (points.bancos; whoever sits: SY, moves); CARRO: the cart (the set\'s, built round it: points.carro; its place in the list unchanged); FAROL: the lamp post (the set\'s: points.farol, things.farol); PORTON: unchanged (spots.porton)');
  set(lineOf('const cableY=x=>'), { points: ['cable'] }, 'the wire\'s rows: the set\'s wire lies on them (points.cable): every pigeon on it keeps its point');
  set(lineOf('const CABLE=i=>'), { spots: ['cable.0', 'cable.1', 'cable.2', 'cable.3', 'cable.4'] }, 'where the pigeons sit on the wire: unchanged (the wire is under them)');
  set(lineOf('const RESP=i=>'), 'unchanged', 'RESP (the top of a bench\'s back, B - 23): used by no act or draw (the pigeons perch at POSA)');
  set(lineOf('const LUGAR={inicio:'), { spots: ['frog.inicio', 'frog.centro'] }, 'the floor rule: the same screen places, on the paving');
  set(lineOf('const alto=id=>'), 'unchanged', 'heights of the sprites (alto), not places');
  set(lineOf('const caja=id=>'), 'unchanged', 'a person\'s box relative to them: unchanged');
  set(lineOf('const perroC=n=>'), 'unchanged', 'a dog\'s box relative to it: unchanged');
  set(lineOf('{id:"coche",si:'), 'unchanged', 'the pushchair\'s box relative to it: unchanged');
  set(lineOf('{id:"pajaro",si:'), 'unchanged', 'the pigeons\' box relative to them: unchanged');
  set(lineOf('{id:"carro",box:'), { things: ['carro', 'farol'] }, 'the set things\' boxes (things.carro, things.farol; the cart\'s moves with it while it rolls)');
  set(lineOf('{id:"banco0",box:'), { things: ['banco0', 'banco1', 'banco2'] }, 'the benches\' boxes (things)');
  set(lineOf('{id:"parque",box:'), { things: ['parque'] }, 'the park\'s box: unchanged, its hint box (things.parque.hintBox)');
  set(lineOf('const B=BANCOS,ASIENTO=149'), { moves: ['POSA=[[110,127],[158,127],[176,127],[208,127]]'], spots: ['respaldo.0', 'respaldo.1', 'respaldo.2', 'respaldo.3'] }, 'ASIENTO: a thing put on a seat (AS, moves); POSA: the pigeons on the backs (moved); JUGEN: where the toys land from the pushchair: the floor rule (on the paving, the last two on the path out through the gate)');
  set(lineOf('const cx=()=>W.cq.x+16'), 'unchanged', 'the frog\'s middle and feet relative to q: unchanged');
  set(lineOf('async function ranaA('), 'unchanged', 'ranaA: q relative to the point; the hop count by the distance (34 px a hop): unchanged');
  set(lineOf('KIT.escena({id:"banco"'), { view: 'wide', point: 'corazon' }, 'the view (views.wide) and the heart (points.corazon): unchanged');
  set(lineOf('fresh:()=>({respEn:'), 'unchanged', 'respEn (where the answer cards stand: the sky over the frog\'s place) and the frog\'s first place: unchanged');
  set(lineOf('async prueba(o){'), 'unchanged', 'acts.prueba: a test act no story of this scene calls (only la-foto, another scene, names "prueba"): its places unchanged; whoever sits there sits at the old 161');
  for (const L of [lineOf('async prueba(o){') + 1, lineOf('async prueba(o){') + 2, lineOf('async prueba(o){') + 3, lineOf('async prueba(o){') + 4, lineOf('async prueba(o){') + 5, lineOf('async prueba(o){') + 6, lineOf('async prueba(o){') + 7]) { const e = C.find(q => q.line === L); if (e) { e.to = 'unchanged'; e.note = 'acts.prueba (a test act no story calls): unchanged'; } }
  const dl = DROPPED.map(d => d.line); for (const e of C) if (dl.includes(e.line)) e.to = { dropped: true };
  C.push({ line: 'juego.js:16', to: 'unchanged', note: 'fresh(): not used here: banco\'s fresh() puts the frog at LUGAR.centro' });
  C.push({ line: 'cual.js:21', to: 'unchanged', note: 'panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)' });
  return C;
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([R(hp[0]) - 12 + i * 3, R(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const frogBox = q => { const w = R(30 * q.s) + 2, h = R(25 * q.s) + 2; return { x: R(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const OUTC = (() => { const h = fs.readFileSync(path.join(REPO, 'historia/engine.js'), 'utf8').match(/OUT\s*=\s*"(#[0-9A-Fa-f]{6})"/); if (!h) throw new Error('engine.js: OUT'); return [1, 3, 5].map(i => parseInt(h[1].slice(i, i + 2), 16)); })();   // every old sprite's outline (engine.js OUT)
const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));
const cableYf = x => R(50 + 7 * (1 - Math.pow((x - 120) / 98, 2)));
const hopsOf = d => [d < 3 ? 0 : Math.max(1, Math.min(4, R(d / 34))), d < 3 ? 0 : Math.max(1, Math.min(4, R(d / 30)))];   // banco.js ranaA (34 px a hop) and kit.js ir (30)

// the sheet's rule for a world written in old positions (what banco-preview.html PREVIEW.remapW does, and the port by its moves and remap)
function remapW(sh, w0, story) {
  const w = JSON.parse(JSON.stringify(w0)), MV = sh.moves.flatMap(m => (m.places || [])), RM = sh.remap.filter(e => e.moved && e.kind === 'point' && (!story || e.uses.some(u => u.startsWith(story + '.json'))));
  const find = (who, p) => MV.find(q => (q.who === who || (who === 'cosa' && q.who === 'cosa')) && q.old[0] === R(p.x) && q.old[1] === R(p.y)) || RM.find(e => e.old[0] === R(p.x) && e.old[1] === R(p.y));
  for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.sent && R(p.y) === 161) { const m = MV.find(q => q.who === id && q.old[0] === R(p.x) && q.old[1] === 161); if (m) p.x = m.new[0] + (p.x - R(p.x)); p.y = SYf(R(p.x)) + (p.y - R(p.y)); }
  for (const p of w.palomas || []) if (p && p.x != null) { const m = find('paloma', p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
  for (const p of w.cosas || []) if (p && p.x != null) { const m = find('cosa', p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
  for (const p of Object.values(w.perros || {})) if (p && p.x != null) { const m = find('perro', p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
  const sitters = Object.values(w0.gente || {}).filter(p => p && p.sent && R(p.y) === 161 && p.vis !== 0);
  for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null || p.sent) continue; const m = MV.find(q => (q.who === id || q.who === 'porton') && q.old[0] === R(p.x) && q.old[1] === R(p.y)) || RM.find(e => e.old[0] === R(p.x) && e.old[1] === R(p.y) && e.uses.some(u => / (beats|.*gente)/.test(u))); if (m) { p.x = m.new[0] + (p.x - R(p.x)); p.y = m.new[1] + (p.y - R(p.y)); } }
  // the frog serving whoever sits (ranaA(p.x - 0, 2 or 4, p.y + 22 or 24)) moves with them; the frog at the gate (PORTON + 4) with it
  if (w.cq) { const mq = MV.find(m2 => m2.who === 'cq' && m2.old[0] === w.cq.x && m2.old[1] === w.cq.y); if (mq) { w.cq.x = mq.new[0]; w.cq.y = mq.new[1]; } }
  if (w.cq) for (const d of Object.values(w0.perros || {})) { if (!d || d.x == null || w.cq.x !== R(d.x) + 14 || w.cq.y !== R(d.y) - 23) continue; const m = MV.find(m2 => m2.who === 'perro' && m2.old[0] === R(d.x) && m2.old[1] === R(d.y)); if (m) { w.cq.x += m.new[0] - m.old[0]; w.cq.y += m.new[1] - m.old[1]; } break; }
  if (w.cq) { const q = w.cq, s = sitters.find(p => [0, -2, -4].includes(q.x + 16 - R(p.x)) && [156, 158].includes(q.y)); if (s) { const m = MV.find(m2 => m2.old[0] === R(s.x) && m2.old[1] === 161 && m2.who !== 'sitting'), nx = m ? m.new[0] : R(s.x); q.x += nx - R(s.x); q.y += SYf(nx) - 161; }
  }
  if (w.carroX != null) { w.carroX += -13; if (w.gente && w.gente.piraguero && w.seva) { const pi = w.gente.piraguero; pi.x += -13; pi.y = 178 + 2 + (34 - w.carroX) / 2; } }
  return w;
}
const placesOf = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)];
  if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y]; for (const [n, d] of Object.entries(w.perros || {})) if (d && d.vis !== 0 && d.x != null) o['perro.' + n] = [R(d.x), R(d.y)];
  (w.palomas || []).forEach((p, i) => { if (p && p.vis !== 0) o['paloma.' + (p.i != null ? p.i : i)] = [R(p.x), R(p.y)]; }); (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0) o['cosa.' + (c.id || c.k + i)] = [R(c.x), R(c.y)]; });
  if (w.coche) o.coche = [R(w.coche.x), R(w.coche.y)]; return o; };

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M, MASK = G.MASK, NEW = G.TICKS;
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];
  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const T of NEW) { for (const t of T.ticks) reached.add(keyOf(t.W)); for (const L of T.states) reached.add(keyOf(L.W)); } for (const ps of pairSidesOf()) reached.add(keyOf(pairW(ps, sh)));
    sh.setKey.baked = ALL_STATES.filter(k => reached.has(k)).map(k => ({ key: k, query: '?' + queryOf(k) })); sh.setKey.notReached = ALL_STATES.filter(k => !reached.has(k)); }
  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-banco.json'), 'utf8')), pairSides = pairSidesOf();
  const otherScene = PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene !== 'banco').map(s => p.w + '.' + s + ' (' + p[s].scene + ')'));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of PAIRS.level) for (const p of L.pictures) if (p.scene === 'banco') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  /* code: banco.js read here, line by line: every line with a number has an entry; a line with a place has a fate (moved, the floor rule, a set thing, dropped) */
  { const byLine = new Map(sh.code.map(e => [String(e.line), e])); let nPlace = 0, nLines = 0, nNot = 0; const notPlaces = {};
    for (let L = 1; L <= LINES.length; L++) { const l = stripLine(LINES[L - 1]), ns = numsOf(l); if (!ns.length) continue; nLines++; const e = byLine.get(String(L));
      if (!e) { P.push('code: banco.js line ' + L + ' holds numbers (' + ns.map(n => n.n).join(', ') + ') and has no entry'); continue; }
      const reg = regionOf(L);
      for (const { n, at } of ns) { const k = reg ? reg.kind : numKind(l, at, n); if (k === 'place') { nPlace++; if (!(e.numbers.place || []).includes(n)) P.push('code: banco.js:' + L + ' the place number ' + n + ' is not named in its entry'); if (e.to === 'unchanged' && !/prueba|RESP|respEn/.test(e.note)) P.push('code: banco.js:' + L + ' has places but its entry says only "unchanged"'); } else { nNot++; notPlaces[k] = (notPlaces[k] || 0) + 1; } } }
    for (const m of sh.moves) { for (const L of m.lines || [m.line]) if (!LINES[L - 1].includes(m.src)) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); }
    for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
    for (const [a] of sh.front.tags.concat(sh.helps.lines)) if (!BANCO_JS.includes(a)) P.push('banco.js does not hold ' + a);
    notes.push('code: banco.js read here: ' + nLines + ' lines hold numbers, every one with its entry; ' + nPlace + ' numbers are places on the picture, each named in its line\'s entry with what becomes of it (moved, the floor rule, a set thing, dropped); ' + nNot + ' are not places (' + Object.entries(notPlaces).map(([k, n]) => k + ' ' + n).join(', ') + ': each line\'s entry lists them by kind)'); }
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-banco (' + pairSides.length + ' pictures here' + (otherScene.length ? '; ' + otherScene.join(', ') + ' another scene\'s' : '; none is another scene\'s') + '), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + sh.setKey.baked.length + ' baked states reached (the old ' + inv.states.count + ')');

  /* hops: the frog's walks, recorded and the port's, step by step: each walk takes the old number of hops (banco.js ranaA, kit.js ir) */
  { const restQ = Ws => { const out = []; for (const w of Ws) { const q = w.cq; if (!q || !q.vis) continue; const k = q.x + ',' + q.y; if (!out.length || out[out.length - 1] !== k) out.push(k); } return out; };
    const all = new Map(); let nW = 0; const changed = new Set();
    runs.forEach((r, ri) => { const o = r.lines, n = NEW[ri].states; for (let i = 1; i < o.length; i++) { const a = o[i - 1].W.cq, b = o[i].W.cq; if (!a || !b || !a.vis || !b.vis) continue;
        const twin = n.findIndex(L => L.path === o[i].path && L.kind === o[i].kind); if (twin < 1) continue; const a2 = n[twin - 1].W.cq, b2 = n[twin].W.cq; if (!a2 || !b2) continue;
        const dO = Math.hypot(a.x - b.x, a.y - b.y), dN = Math.hypot(a2.x - b2.x, a2.y - b2.y); if (dO < 3 && dN < 3) continue; nW++;
        const stp = (() => { try { return o[i].path.split('.').reduce((q, k) => q == null ? q : q[/^\d+$/.test(k) ? +k : k], r.story); } catch (e) { return null; } })(), byIr = !!(stp && stp.act === 'ir'), K = byIr ? 1 : 0;
        const ho = hopsOf(dO), hn = hopsOf(dN), key = [a.x + ',' + a.y, b.x + ',' + b.y].join(' -> '); all.set(key + ' => ' + [a2.x + ',' + a2.y, b2.x + ',' + b2.y].join(' -> '), { a: [a.x, a.y], b: [b.x, b.y], a2: [a2.x, a2.y], b2: [b2.x, b2.y], by: byIr ? 'kit.js ir (30 px a hop)' : 'banco.js ranaA (34 px a hop)', old: ho[K], new: hn[K], dOld: r2(dO), dNew: r2(dN) });
        if (ho[K] !== hn[K]) { changed.add(key); P.push('hops: ' + r.story.id + ' ' + r.plan + ' ' + o[i].path + ': the frog\'s walk ' + key + ' took ' + ho[K] + ' hops, the port\'s ' + hn[K]); } } });
    sh.hopsAll = [...all.values()]; sh.hops = sh.hopsAll.filter(h => h.old !== h.new);
    notes.push('hops: the frog\'s ' + nW + ' walks between steps in the ' + runs.length + ' runs, recorded and the port\'s, each the old number of hops (' + all.size + ' distinct walks; ' + sh.hops.length + ' changed)'); }

  /* the set's pixels, every baked state */
  const TAGS = {}, ZONES = {};
  const zoneOfTag = t => !t ? null : /^banco/.test(t) ? 'b' + t.slice(-1) : { carro: 'c', farol: 'f', poste: 'q', porton: 'g', seto: 'h', cable: 'w' }[t] || (/^arbol/.test(t) ? 't' : 'x');
  for (const k of ALL_STATES) { const m = new Array(240 * 216).fill(null); for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) m[i] = p; TAGS[k] = m;
    const Z = []; for (let i = 0; i < 240 * 216; i++) Z.push(zoneOfTag(m[i]) || G.surf[i]); ZONES[k] = Z; }
  const zoneAt = (k, x, y) => x < 0 || x >= 240 || y < 0 || y >= 216 ? 'out' : ZONES[k][y * 240 + x];
  /* every set thing's pixels inside its touch box (in every state; the cart's standing); nothing decorative over a touch box; the hit order */
  { const res = [], ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const hitAt = (x, y) => { for (const [id, m] of ORDER) { const b = sh.things[id].box; if (x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) return id; } return null; };
    for (const name of ['carro', 'farol', ...BENCHES]) { const b = sh.things[name].box; let out = 0, n = 0;
      for (const k of ALL_STATES) for (const i of G.parts[k][name] || []) { n++; const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + name + ' are outside its touch box ' + JSON.stringify(b)); res.push(name + ' ' + JSON.stringify(b)); }
    const wrong = {}, K0 = sh.setKey.baked[0].key;
    for (const k of ALL_STATES) for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) { const x = i % 240, y = Math.floor(i / 240), h = hitAt(x, y), own = THING_OF(p);
      if (h === own) continue; if (p === 'cable' && h === 'farol' && Math.abs(x - F.FAROL.at[0]) <= 8) continue;   // the wire where it hangs from the lamp post
      const kk = p + ' -> ' + h; wrong[kk] = (wrong[kk] || 0) + 1; }
    const both = []; for (const [kk, n] of Object.entries(wrong)) { const p = kk.split(' -> ')[0]; if (THING_OF(p) === 'parque') P.push('hit: ' + n + ' px of ' + kk + ' (decor over a touch box)'); else both.push(kk + ' ' + n + ' px'); }
    if (both.length) notes.push('boxes, two touch things side by side (as the old, whose lamp post\'s box also reached over the second bench\'s end): ' + both.join(', '));
    
    notes.push('boxes: every pixel of each set thing inside its touch box in every baked state (nothing sways): ' + res.join(', ') + '; every pixel answers its own thing in the hit order (the wire answers the lamp only where it hangs from it, 8 px); no two boxes overlap; the trees, the hedge, the gate, the pole and the wire are the park\'s'); }

  /* every castShadow call darkens; each shadow in one piece with its thing; a thin thing casts only a short contact shadow */
  { const pieces = {}; let nCalls = 0;
    for (const k of ALL_STATES) { const OG = G.onGround[k], byPart = {};
      for (const c of G.shadows[k]) { const [x, y, z, r, s] = c.args, p = c.part || '(none)'; nCalls++;
        if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + k + ' ' + p + ' castShadow(' + c.args.map(r2).join(', ') + '): nothing is cast');
        (byPart[p] = byPart[p] || { calls: 0 }).calls++; }
      if (k.startsWith('noche') && G.shadows[k].length) P.push('shadow: ' + k + ': ' + G.shadows[k].length + ' castShadow calls at night (none: light.noche)');
      for (const [p, b] of Object.entries(byPart)) { const sp = (G.shadowPx[k][p] || []).filter(i => OG[i]); if (!sp.length) P.push('shadow: ' + k + ' the part ' + p + ' casts ' + b.calls + ' times and darkens nothing');
        // one piece: the shadow's pixels and the part's own, joined (8 neighbours, gaps of 2 px allowed)
        const own = new Set(G.parts[k][p] || []), seen = new Set(own), stack = [...own]; if (!stack.length) continue;
        const all = new Set([...own, ...(G.shadowPx[k][p] || [])]);
        while (stack.length) { const i = stack.pop(), x = i % 240, y = Math.floor(i / 240); for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) { const j = (y + dy) * 240 + x + dx; if (x + dx < 0 || x + dx >= 240 || y + dy < 0 || y + dy >= 216 || seen.has(j) || !all.has(j)) continue; seen.add(j); stack.push(j); } }
        const apart = sp.filter(i => !seen.has(i)).length; if (apart) P.push('shadow: ' + k + ' ' + apart + ' px of ' + p + '\'s shadow are not joined to it');
        if (['poste', 'farol', 'porton'].includes(p)) { const foot = p === 'poste' ? F.POLE.at : p === 'farol' ? F.FAROL.at : null; const far = sp.filter(i => { const x = i % 240, y = Math.floor(i / 240); return foot ? Math.hypot(x - foot[0], (y - foot[1]) * 2) > 14 : !F.GATE.some(g => Math.hypot(x - g[0] + 5, (y - g[1] + 2) * 2) < 16); }).length;
          if (far) P.push('shadow: ' + k + ' the thin ' + p + ' casts ' + far + ' px further than its foot'); }
        pieces[p] = (pieces[p] || 0) + sp.length; } }
    notes.push('shadows of the set: ' + nCalls + ' castShadow calls over the ' + ALL_STATES.length + ' states, each with strength 1 and a radius, none at night; each casting part darkens pixels, its shadow joined to it; the thin pole, lamp post and gate posts only a contact shadow at their foot: ' + Object.entries(pieces).map(([p, n]) => p + ' ' + n + ' px').join(', ')); }
  /* the lamp's pool of light and the trees' crown shades: on the ground, joined to their thing (nothing painted round an empty place) */
  { let pool = 0, poolFar = 0, crown = 0, crownOff = 0;
    for (const k of ALL_STATES) { for (const i of G.pool[k]) { pool++; const x = i % 240, y = Math.floor(i / 240); if (Math.hypot(x - F.FAROL.at[0], (y - F.FAROL.at[1]) * 2) > 2 * F.POOL.rx * 26) poolFar++; }
      for (const i of G.crown[k]) { crown++; if (G.surf[i] !== 'l') crownOff++; } }
    if (poolFar) P.push('light: ' + poolFar + ' px of the lamp\'s pool lie far from its foot');
    if (crownOff) P.push('trees: ' + crownOff + ' px of a crown\'s shade are off the lawn');
    if (G.pool['dia.0.abierto'].length) P.push('light: a pool of light by day');
    notes.push('the lamp\'s pool (evening and night): ' + G.pool['tarde.0.abierto'].length + ' and ' + G.pool['noche.0.abierto'].length + ' px round its foot, joined to it, none by day; the trees\' crown shades (day and evening), lighter and solid, on the lawn only'); }
  return checkMoments(sh, G, runs, P, { E, F, COS, T30, M, MASK, NEW, x0, VIEW, TAGS, ZONES, zoneAt, pairSides, notes });
}

function checkMoments(sh, G, runs, P, C) {
  const { E, F, COS, T30, M, MASK, NEW, x0, VIEW, TAGS, ZONES, zoneAt, pairSides, notes } = C;
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
  const rowsOverlap = (A, B) => { const S = new Set(); for (const [y, a, b] of A) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0; for (const [y, a, b] of B) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++; return n; };
  const alto = (id, p) => id === 'abuela' ? (p && p.sent ? 48 : 51) : (p && p.sent ? 49 : 56);
  const frogRows = q => { const b = frogBox(q), rs = []; for (let y = b.y + R(q.dy || 0); y < b.y + R(q.dy || 0) + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]); return rs; };
  const benchOf = x => x < 120 ? 0 : x < 168 ? 1 : 2;
  const vSeat = (k, x) => { const b = F.BENCH[k]; return (x + b.y1) / E.R2; };   // whoever sits: the plane of their bench's seat front (front.how)
  const seatAt = (sx, sy, z = F.ZS) => { const w = E.atZ(sx, sy, z); for (let k = 0; k < 3; k++) { const b = F.BENCH[k]; if (w[0] >= b.x0 - .02 && w[0] <= b.x1 + .02 && w[1] >= b.y0 - .02 && w[1] <= b.y1 + .02) return k; } return -1; };
  // the top of a bench's back at a column (where a pigeon perches on it): its top plank's top, along its length
  const backTopAt = x => { for (let k = 0; k < 3; k++) { const b = F.BENCH[k], yy = b.y0 + .065, z = F.ZS + F.BACK_H - .02, wx = (x - E.OX) / E.S * E.R2 + yy; if (wx >= b.x0 + .02 && wx <= b.x1 - .02) return E.project(wx, yy, z).sy; } return null; };
  const perchOf = (o, w) => { const x = R(o.x), y = R(o.y);
    if (o.pose === 'vuela') return 'air';
    if (Math.abs(y - cableYf(x)) <= 1 && y < 80) return 'wire';
    const bt = backTopAt(x); if (bt != null && Math.abs(y - 1 - bt) <= 1.5) return 'back';
    if (w && w.cq && w.cq.vis) { const b = frogBox(w.cq); if (Math.abs(x - (b.x + b.w / 2)) <= 24 && y >= b.y - 16 && y <= b.y + b.h - 4) return 'frog'; }
    if (w && w.coche && Math.abs(x - R(w.coche.x) - 14) <= 3 && Math.abs(y - R(w.coche.y) + 33) <= 3) return 'coche';
    if (seatAt(x, y - 1) >= 0 && y < 172) return 'seat';
    return 'ground'; };
  const itemsOf = (w, sitPlane = true) => { const it = [];
    for (const r of rawItems(w)) { const o = r.o, m = MASK[r.key]; if (!m || !m.rows.length) continue; const dy = R(o.dy || 0);
      const rows = rowsAt(m.rows, R(o.x), R(o.y) - dy); const item = { id: r.kind === 'person' ? r.id : r.kind === 'dog' ? 'perro ' + r.id : r.id, kind: r.kind, o, rows, at: [R(o.x), R(o.y)], mean: m.mean, air: dy > 3 };
      if (r.kind === 'person') { item.sent = !!o.sent; if (o.sent) item.bench = benchOf(R(o.x)); }
      if (r.kind === 'pigeon') { item.perch = perchOf(o, w); item.air = item.perch === 'air'; }
      if (r.kind === 'thing') { item.air = o.z === 400 || (o.z != null && o.z > o.y + 30); item.onSeat = seatAt(R(o.x), R(o.y) - 1) >= 0 && R(o.y) < 172; }
      it.push(item); }
    if (w.cq && w.cq.vis && !(w.cq.al <= .3)) { const b = frogBox(w.cq); it.push({ id: 'the frog', kind: 'frog', o: w.cq, rows: frogRows(w.cq), at: [b.x + b.w / 2, w.cq.y + 26], air: R(-(w.cq.dy || 0)) > 3 }); }
    return it; };
  const faceOf = (id, p, rows) => { const dy = R(p.dy || 0); if (id === 'abuela') { const top = Math.min(...rows.map(r => r[0])), rs = rows.filter(r => r[0] < top + 10), hx = (Math.min(...rs.map(r => r[1])) + Math.max(...rs.map(r => r[2])) + 1) / 2; return [R(hx - 6), top + 6, 12, 10]; }
    const h = M.heights[id + '.' + (p.sent ? 1 : 0)], top = R(p.y) - h + 1 - dy + (p.animo === 'cansado' ? 3 : p.animo === 'triste' ? 1 : 0); return [R(p.x) - 6, top + 6, 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + R(q.dy || 0), b.w - 4, R(b.h * .6)]; };
  const facesOf = w => { const f = []; for (const it of itemsOf(w)) { if (it.kind === 'person' && !(it.o.al != null && it.o.al < .5)) f.push([it.id + '\'s face', faceOf(it.id, it.o, it.rows)]); }
    if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  const headOf = f => [f[0] - 2, f[1] - 6, f[2] + 4, f[3] + 6];   // a face and the hair over it
  const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const vAt = (sx, sy, z) => { const w = E.atZ(sx, sy, z); return (w[0] + w[1]) / E.R2 + .02; };
  const vGround = (sx, sy) => { const w = E.atZ(sx, sy, 0); return (w[0] + w[1]) / E.R2; };
  const nearerRows = (key, rs, v, names) => { const out = {}, TG = TAGS[key], Z = G.z[key];
    for (const [y, a, b] of rs) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (names.includes(TG[i]) && Z[i] > v / COS - (y + .5 - E.OY) * T30 / E.S) out[TG[i]] = (out[TG[i]] || 0) + 1; } }
    return out; };
  const footOf = rs => { const last = Math.max(...rs.map(r => r[0])); return rs.filter(r => r[0] >= last - 1); };
  const FOOTS = {}; for (const k of ALL_STATES) FOOTS[k] = new Set(G.foot[k]);
  const sideOf = (key, foot) => { const m = sh.helps.margin; let pave = true, lawn = true;
    for (const [y, a, b] of foot) for (let x = a - m; x <= b + m; x++) for (let dy = -m; dy <= m; dy++) { const dx = x < a ? a - x : x > b ? x - b : 0, d2 = dx * dx + dy * dy; if (d2 > m * m) continue; const yy = y + dy, z = x < 0 || x >= 240 || yy < 0 || yy >= 216 ? 'out' : FOOTS[key].has(yy * 240 + x) ? 'F' : G.surf[yy * 240 + x]; if (z !== 'out' && z !== 'p') pave = false; if (z !== 'out' && z !== 'l') lawn = false; }
    return pave ? 'pave' : lawn ? 'lawn' : 'across'; };

  /* every moment: the port's play at every tick inside the acts and every step's end, and every pair picture */
  const REST_MS = 300, across = new Map(), sides = new Map(), hidden = new Map(), behind = new Map(), sitBad = new Map(), perchBad = new Map(), seatBad = new Map(), hedgeBad = new Map(), flyBad = new Map(), stats = { ticks: 0, rest: 0, sit: 0, perched: {}, fly: 0, onSeat: 0, gate: 0, cross: 0 };
  const HK = F.HEDGE_K;
  const look = (where, w, dwell) => { const key = keyOf(w);
    for (const it of itemsOf(w)) {
      const resting = !dwell || dwell[it.id + '@' + it.at.join(',')] >= REST_MS;
      if (['person', 'dog', 'frog', 'coche'].includes(it.kind) && it.at[0] < 240 && it.at[0] + 2 * it.at[1] >= HK) stats.gate++;
      if (it.kind === 'pigeon') { stats.perched[it.perch] = (stats.perched[it.perch] || 0) + 1;
        if (it.perch === 'air') { stats.fly++; if (dwell && !it.o.gs) flyBad.set(it.id, where + ': in the air with no shadow point (o.gs)'); else if (it.o.gs) { const s = E.surface(it.o.gs[0], it.o.gs[1]); if (s.on !== 'pave' && s.on !== 'lawn' && it.o.gs[0] < 240 && it.o.gs[0] >= 0) flyBad.set(it.id + ' shadow', where + ': its shadow at ' + it.o.gs.map(R) + ' is not on the ground'); } continue; }
        if (it.perch === 'wire') { let n = 0; for (let x = it.at[0] - 3; x <= it.at[0] + 3; x++) for (let y = it.at[1] - 1; y <= it.at[1] + 1; y++) if (TAGS[key][y * 240 + x] === 'cable') n++; if (n < 3) perchBad.set(it.id + ' at ' + it.at, where + ': only ' + n + ' px of wire under its feet'); continue; }
        if (it.perch === 'back') { let n = 0; for (let x = it.at[0] - 2; x <= it.at[0] + 2; x++) for (let y = it.at[1] - 1; y <= it.at[1] + 1; y++) if (/^banco/.test(TAGS[key][y * 240 + x] || '')) n++; if (n < 4) perchBad.set(it.id + ' at ' + it.at, where + ': only ' + n + ' px of the bench\'s back under its feet'); continue; }
        if (it.perch === 'seat' || it.perch === 'back') { stats.onSeat++; const near = nearerRows(key, it.rows, vAt(it.at[0], Math.max(...it.rows.map(q => q[0])) + 1, it.perch === 'seat' ? F.ZS : F.ZS + F.BACK_H), BENCHES); if (Object.keys(near).length) seatBad.set(it.id + ' at ' + it.at, where + ': ' + JSON.stringify(near) + ' of its bench in front of it'); continue; }
        if (it.perch === 'frog' || it.perch === 'coche') continue; }
      if (it.kind === 'thing' && it.onSeat && !it.air) { stats.onSeat++; const near = nearerRows(key, it.rows, vAt(it.at[0], Math.max(...it.rows.map(q => q[0])) + 1, F.ZS), BENCHES); if (Object.keys(near).length) seatBad.set(it.id + ' at ' + it.at, where + ': ' + JSON.stringify(near) + ' of its bench in front of it'); continue; }
      if (it.kind === 'person' && it.sent) { stats.sit++;
        // on the seat: the seat under the lap, the bench's back behind the body, the feet over the paving; nothing of the set nearer than them
        const lap = [it.at[0], it.at[1] - 11], k = seatAt(lap[0], lap[1]), k2 = seatAt(lap[0], lap[1] + 1);
        if (k < 0 && k2 < 0) sitBad.set(it.id + ' at ' + it.at, where + ': no seat under the lap (' + lap + ')');
        const kb = k >= 0 ? k : k2; let back = 0; for (const [y, a, b] of it.rows) if (y >= it.at[1] - 34 && y <= it.at[1] - 16) for (let x = a; x <= b; x++) if (TAGS[key][y * 240 + x] === 'banco' + kb) back++;
        const feet = E.surface(it.at[0], it.at[1] + 1).on; if (feet !== 'pave') sitBad.set(it.id + ' at ' + it.at + ' (feet)', where + ': the feet over ' + feet);
        const near = nearerRows(key, it.rows, vSeat(kb < 0 ? benchOf(it.at[0]) : kb, it.at[0]) + .03, ['banco0', 'banco1', 'banco2']); if (Object.keys(near).length) sitBad.set(it.id + ' at ' + it.at + ' (front)', where + ': ' + JSON.stringify(near) + ' nearer than them');
        if (resting) { const nr = nearerRows(key, it.rows, vSeat(kb < 0 ? benchOf(it.at[0]) : kb, it.at[0]) + .03, SOLID.filter(p => !/^banco/.test(p))); for (const [part, n] of Object.entries(nr)) { if (FRONT.includes(part)) behind.set(it.id + ' at ' + it.at + ' behind ' + part, n); else hidden.set(it.id + ' at ' + it.at, where + ': ' + n + ' px of ' + part + ' nearer than them'); } }
        continue; }
      if (it.air) continue;
      // a set thing nearer than it inside its sprite: the front parts are drawn over it (front); any other part never
      { const v = vGround(it.at[0], it.at[1] - 1), near = nearerRows(key, it.rows, v, SOLID);
        for (const [part, n] of Object.entries(near)) { if (FRONT.includes(part)) { const kk = it.id + ' at ' + it.at + ' behind ' + part; behind.set(kk, Math.max(behind.get(kk) || 0, n)); continue; } if (resting && n > 2) hidden.set(it.id + ' at ' + it.at, where + ': ' + n + ' px of ' + part + ' nearer than it inside its sprite'); } }
      if (!resting) continue;
      if (it.at[0] < x0 || it.at[0] >= x0 + 196) continue;   // out of the view (leaving, or not yet come)
      if (it.kind === 'person' && Math.abs(it.at[1] - SYf(it.at[0])) <= 1 && seatAt(it.at[0], it.at[1] - 11) >= 0) continue;   // sitting down or getting up, at the seat's edge
      stats.rest++;
      const side = sideOf(key, footOf(it.rows)); sides.set(it.id + ' at ' + it.at, side);
      if (side === 'across') across.set(it.id + ' at ' + it.at, where);
    } };
  if (process.env.BANCO_ZONE) for (const q of process.env.BANCO_ZONE.split(';')) { const [x, y] = q.split(',').map(Number); for (let yy = y - 8; yy <= y + 4; yy++) { let l = ''; for (let xx = x - 20; xx <= x + 20; xx++) l += String(zoneAt('dia.0.abierto', xx, yy)).slice(0, 1); console.log(yy + ' ' + l); } console.log(''); }
  if (process.env.BANCO_ITEM) { const w = { gente: { mujer: { x: 146, y: 198, dir: 1 } }, cq: { vis: 0 } }; for (const it of itemsOf(w)) { const f = footOf(it.rows); console.log(it.id, JSON.stringify(f), sideOf('dia.0.no', f), sideOf('dia.0.abierto', f)); const m = 6, bad = []; for (const [y, a, b] of f) for (let x = a - m; x <= b + m; x++) for (let dy = -m; dy <= m; dy++) { const dx = x < a ? a - x : x > b ? x - b : 0; if (dx * dx + dy * dy > m * m) continue; const z = zoneAt('dia.0.no', x, y + dy); if (z !== 'p') bad.push(x + ',' + (y + dy) + ':' + z); } console.log(bad.slice(0, 20).join(' ')); } }
  const posOf = w => { const o = {}; for (const it of itemsOf(w)) o[it.id] = it.at; return o; };
  const allW = [];
  runs.forEach((r, ri) => { const T = NEW[ri].ticks, P0 = T.map(t => posOf(t.W)), dwell = P0.map(() => ({}));
    for (let i = 0; i < T.length; i++) for (const [id, p] of Object.entries(P0[i])) { const key = id + '@' + p.join(','); if (i > 0 && P0[i - 1][id] && P0[i - 1][id].join(',') === p.join(',')) { dwell[i][key] = dwell[i - 1][key]; continue; }
      let j = i; while (j + 1 < T.length && P0[j + 1][id] && P0[j + 1][id].join(',') === p.join(',')) j++; dwell[i][key] = (j + 1 < T.length ? T[j + 1].t : T[j].t + REST_MS) - T[i].t; }
    for (let i = 0; i < T.length; i++) { stats.ticks++; look(r.story.id + ' ' + r.plan + ' t ' + T[i].t, T[i].W, dwell[i]); allW.push([r.story.id + ' ' + r.plan + ' t ' + T[i].t, T[i].W, Object.values(dwell[i]).every(v => v >= REST_MS)]); }
    // whoever crosses the hedge's line crosses it in the gate's opening, between the posts (nobody walks through the hedge)
    for (let i = 1; i < T.length; i++) for (const [id, p] of Object.entries(P0[i])) { const q = P0[i - 1][id]; if (!q || /^paloma|^cosa/.test(id)) continue;
      const k0 = q[0] + 2 * (q[1] - 1) - HK, k1 = p[0] + 2 * (p[1] - 1) - HK; if ((k0 < 0) === (k1 < 0)) continue; const t = k0 / (k0 - k1), cx = q[0] + (p[0] - q[0]) * t; if (cx >= 240) continue; stats.cross++;
      if (cx < F.GATE[0][0] + 4 || cx > F.GATE[1][0] - 4) hedgeBad.set(id + ' ' + r.story.id + ' ' + r.plan, 'at t ' + T[i].t + ' crosses the hedge\'s line at x ' + R(cx) + ', not in the gate\'s opening (' + (F.GATE[0][0] + 4) + ' to ' + (F.GATE[1][0] - 4) + ')'); }
    for (const L of NEW[ri].states) { let j = -1; for (let k = 0; k < T.length && T[k].t <= L.t; k++) j = k; const dw = {}; const P1 = posOf(L.W);
        for (const [id, p] of Object.entries(P1)) { const key = id + '@' + p.join(','); dw[key] = j >= 0 && dwell[j][key] != null ? dwell[j][key] : (j < 0 ? 999 : 0); }
        look(r.story.id + ' ' + r.plan + ' ' + L.path, L.W, dw); allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W]); } });
  for (const ps of pairSides) look('pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps, sh), null);
  for (const [k, where] of across) P.push('side: ' + k + ' is not clearly on the paving or the lawn (' + sh.helps.margin + ' px round its foot) (' + where + ')');
  for (const [k, why] of hedgeBad) P.push('gate: ' + k + ' ' + why);
  for (const [k, why] of sitBad) P.push('sitting: ' + k + ' ' + why);
  for (const [k, why] of perchBad) P.push('perch: ' + k + ' ' + why);
  for (const [k, why] of seatBad) P.push('on a seat: ' + k + ' ' + why);
  for (const [k, why] of flyBad) P.push('flying: ' + k + ' ' + why);
  for (const [k, why] of hidden) P.push('hidden: ' + k + ' ' + why);
  const bySide = s => [...new Set([...sides].filter(e => e[1] === s).map(e => e[0].replace(/ at .*/, '')))].sort().join(', ');
  notes.push('sides: ' + stats.ticks + ' ticks inside the acts of the port\'s play of the ' + runs.length + ' runs, every step\'s end and every pair picture: ' + stats.rest + ' rests (' + REST_MS + ' ms or more in one place) on the ground, each clearly on one side with ' + sh.helps.margin + ' px of that ground round its foot: on the paving (' + bySide('pave') + '), on the lawn (' + (bySide('lawn') || 'none') + '); ' + stats.gate + ' moments of someone beyond the hedge\'s line (on the pavement outside), ' + stats.cross + ' crossings of it, each in the gate\'s opening');
  notes.push('sitting: ' + stats.sit + ' moments of someone on a bench: the seat under the lap, the feet over the paving, nothing of the bench nearer than them (its back behind them); ' + stats.onSeat + ' moments of a thing or a pigeon on a seat, on it');
  notes.push('pigeons: ' + Object.entries(stats.perched).map(([k, n]) => n + ' ' + k).join(', ') + ' (moments): on the wire with the wire under their feet, on a back with its top under them; ' + stats.fly + ' moments in the air, each with its shadow on the ground (helps)');
  notes.push('behind a front part, drawn over them by front: ' + ([...new Set([...behind.keys()].map(k => k.replace(/ at [^ ]+/, '')))].join(', ') || 'no one') + '; nobody has another part of the set nearer than them');

  /* bubbles, boards, the sun and the moon */
  let nM = 0, nB = 0, worstView = 99; const seen = new Set(), asOldB = new Set();
  const SUNR = [F.SUN[0] - F.SUN[2] - 2, F.SUN[1] - F.SUN[2] - 2, 2 * F.SUN[2] + 4, 2 * F.SUN[2] + 4], MOONR = [F.MOON[0] - F.MOON[2] - 2, F.MOON[1] - F.MOON[2] - 2, 2 * F.MOON[2] + 4, 2 * F.MOON[2] + 4];
  const discOf = w => w.noche ? (w.luna ? ['the moon', MOONR] : null) : ['the sun', SUNR];
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } const r = bubRect(k, top[0], top[1]); r.old = true; return r; };
  const bubblesOf = w => { const out = [], boards = boardsOf(w, x0), faces = facesOf(w);
    for (const [id, p] of Object.entries(w.gente || {})) { if (!shown(p) || (p.al != null && p.al < .5) || R(p.x) < x0 || R(p.x) >= x0 + 196) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor');
      for (const k of ks) out.push([id + ' "' + k + '"', talk(k, [R(p.x), R(p.y) - alto(id, p) - 1], VIEW, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5) && q.bub) { const b = frogBox(q); out.push(['the frog "' + q.bub + '"', talk(q.bub, [b.x + (b.w >> 1), b.y + 2], VIEW, boards, faces, b.w >> 1)]); }
    return out; };
  for (const [where, w] of allW) { nM++; const boards = boardsOf(w, x0), faces = facesOf(w), disc = discOf(w);
    for (const [bn, b] of boards) if (disc && meets(disc[1], b)) P.push('sky: ' + where + ': ' + bn + ' covers ' + disc[0]);
    for (const [who, rect] of bubblesOf(w)) { const key = JSON.stringify([who, rect, boards, faces]); if (seen.has(key)) continue; seen.add(key); nB++;
      if (rect.old && / "amor"$/.test(who)) { asOldB.add(who.replace(/ ".*/, '') + ' "amor" (' + where.split(' t ')[0] + ')'); continue; }
      if (!within(rect, VIEW)) { P.push('bubble: ' + where + ' ' + who + ' ' + JSON.stringify(rect) + ' is not wholly inside the view'); continue; }
      worstView = Math.min(worstView, rect[0] - x0, x0 + 196 - rect[0] - rect[2], rect[1], 216 - rect[1] - rect[3]);
      for (const [bn, b] of boards) if (meets(rect, b)) P.push('bubble: ' + where + ' ' + who + ' is over ' + bn);
      for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + who + ' is on ' + fn); } }
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments (each person\'s recorded one and "amor" when touched, the frog\'s): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the rounds card, on no face; but where no place is free the "amor" of a touch keeps the old place, as the old (' + ([...asOldB].join(', ') || 'none') + ')');
  return checkAsks(sh, G, runs, P, Object.assign(C, { itemsOf, facesOf, headOf, rowsBox, rowsMeet, rowsOverlap, shown, alto, SUNR, MOONR, discOf, allW, faceOf }));
}

function checkAsks(sh, G, runs, P, C) {
  const { E, F, M, NEW, x0, VIEW, TAGS, ZONES, zoneAt, pairSides, notes, itemsOf, facesOf, headOf, rowsBox, rowsMeet, rowsOverlap, shown, alto, SUNR, discOf, allW, faceOf } = C;
  /* the asks: hint frames, the hand, the answer cards and the hint drawn round a card; the things a learner must find or tell apart */
  const cajaBox = (id, p) => [R(p.x) - 11, R(p.y) - alto(id, p), 22, alto(id, p)];
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) { if (old) return t.old.box; const b = (t.hintBox || t.box).slice(); if (k === 'carro' && w.carroX != null) { b[0] += R(w.carroX) - OLD.CARRO[0]; b[1] += R((OLD.CARRO[0] - w.carroX) / 2); } return b; }
    let m;
    if ((m = k.match(/^perro(?:_(.+))?$/))) { const o = (w.perros || {})[m[1] || 'canelo']; return o && o.vis !== 0 ? [R(o.x) - 15, R(o.y) - 22, 30, 24] : null; }
    if (k === 'coche') return w.coche ? [R(w.coche.x) - 19, R(w.coche.y) - 42, 38, 44] : null;
    if (k === 'pajaro') { const o = (w.palomas || []).filter(o => o.vis !== 0); if (!o.length) return null; const xs = o.map(q => q.x), ys = o.map(q => q.y); return [Math.min(...xs) - 9, Math.min(...ys) - 14, Math.max(...xs) - Math.min(...xs) + 18, Math.max(...ys) - Math.min(...ys) + 18]; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? cajaBox(k, p) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !old) { const h = t.hand.slice(); if (k === 'carro' && w.carroX != null) { h[0] += R(w.carroX) - OLD.CARRO[0]; h[1] += R((OLD.CARRO[0] - w.carroX) / 2); } return h; } const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const PEOPLE = ['luis', 'carmen', 'abuela', 'hombre', 'mujer', 'senor', 'joven', 'senora', 'piraguero'], TELLK = new Set(['person', 'dog', 'pigeon', 'coche']);
  const plainZ = (z, it) => 'pls'.includes(z) || z === 'out' || (it.kind === 'person' && it.sent && z === 'b' + it.bench) || (it.kind === 'pigeon' && ((it.perch === 'wire' && z === 'w') || (it.perch === 'back' && /^b/.test(z)) || (it.perch === 'seat' && /^b/.test(z))));
  // the old picture's backdrop round a thing at its old place: the share of it that is plain (its paving, lawn and sky colours, banco.js fondo)
  const OLDPLAIN = [[216, 208, 186], [226, 218, 198], [206, 198, 176], [184, 174, 152], [138, 130, 112]].concat([[94, 186, 98], [70, 160, 80], [116, 206, 112], [58, 134, 230], [120, 186, 250], [162, 211, 255]]);
  const plainOld = it => { let n = 0, ok = 0; const own = new Set(); for (const [y, x1, x2] of it.rows) for (let x = x1; x <= x2; x++) own.add(y * 240 + x);
    for (const [y, x1, x2] of it.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const yy = y + dy, i = yy * 240 + x; if (own.has(i) || x < 0 || x >= 240 || yy < 0 || yy >= 216) continue; n++; const c = [M.oldBg[i * 4], M.oldBg[i * 4 + 1], M.oldBg[i * 4 + 2]]; if (yy >= 132 ? c[0] > 180 && Math.abs(c[0] - c[2]) < 50 : OLDPLAIN.some(q => dE(q, c) < 22)) ok++; }
    return n ? ok / n : 1; };
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99, nTell = 0, nightWorst = 99, cardHint = 0; const lowAsOld = new Set(), cardsOverPigeons = new Set(), cardsOverSet = new Set(), askSeen = new Set(), askedFor = new Set(), crossedOld = new Set(), handOld = new Set();
  runs.forEach((r, ri) => { const Ls = NEW[ri].states, Lo = r.lines;
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = JSON.parse(JSON.stringify(Ls[j - 1].W)), jo = Lo.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')), wo = jo > 0 ? Lo[jo - 1].W : w;
      const st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      let spot = null, opts = [];
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); opts = [spot]; }
      else if (st.decide) { opts = st.options.map(sb); const bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || opts[0]; if (st.decide === 'say') w.resp = opts; else if (bur.length) w.resp = bur; }
      const key = keyOf(w), where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', sig = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.perros, w.palomas, w.coche, w.tarjeta, w.respEn, key]);
      if (askSeen.has(sig)) return; askSeen.add(sig); askedFor.add(spot);
      const faces = facesOf(w), facesOld = facesOf(wo), items = itemsOf(w), disc = discOf(w);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const fr2 = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; if (disc && meets(disc[1], fr2)) P.push('sky: ' + where + ' the card ' + k + ', its frame or its glow covers ' + disc[0]); }
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within([f[0] - 4, f[1] - 4, f[2] + 8, f[3] + 8], VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn);
        // over nobody (a person, the frog, a dog, the pushchair, a thing lying about), and over none of what the ask names (a pigeon when it names the pigeons; the cart, the lamp post, a bench)
        for (const it of items) { if (it.kind === 'frog') { const f = frogBox(w.cq); if (meets(c, [f.x + 2, f.y + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' covers the frog'); continue; }
          if (it.kind === 'pigeon' && !opts.includes('pajaro')) { if (rowsMeet(it.rows, c)) cardsOverPigeons.add(r.story.id); continue; }
          const n = rowsMeet(it.rows, it.kind === 'person' ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id); }
        for (const name of ['carro', 'farol', ...BENCHES]) { const n = (G.parts[key][name] || []).filter(i => meets([i % 240, Math.floor(i / 240), 1, 1], c)).length; if (n > 3) { if (opts.includes(name)) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + name); else cardsOverSet.add(name); } }
        // (new from El lago's port) the hint drawn round a card: its frame (box + 12) 2 px inside the view and across no head; its hand on no face
        cardHint++; const fr = [c[0] - FRAME_OUT, c[1] - FRAME_OUT, c[2] + 2 * FRAME_OUT, c[3] + 2 * FRAME_OUT];
        if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('card hint: ' + where + ' the frame round the card ' + k + ' is not 2 px inside the view');
        for (const [fn, f] of faces) if (ringMeets(c, headOf(f))) P.push('card hint: ' + where + ' the frame round the card ' + k + ' crosses ' + fn.replace('face', 'head'));
        const hp = [c[0] + c[2] / 2, c[1] + c[3] - 6]; for (const [fn, f] of faces) if (handOn(hp, f)) P.push('card hint: ' + where + ' the hand at the card ' + k + ' is on ' + fn); }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view with 2 px to spare'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' (the old frame did not)'); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      if (!hp) { P.push('hand: ' + where + ' no place for the hand at ' + spot); return; }
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb) continue;   // the card's own hand: checked above (card hint)
        const ho = handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1])) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      // the things a learner must find, tell apart or count at this ask: whole in the view, on a plain backdrop, apart where the old had them
      // apart; at night (and in the evening) told from their backdrop at a glance
      const named = new Set(opts.map(o => o === 'pajaro' ? 'pigeon' : o)); if (opts.some(o => /^perro/.test(o))) named.add('dogs'); if (opts.some(o => PEOPLE.includes(o))) named.add('people');
      // the people a learner must tell apart: those the ask names, and the grown-ups of the corner (the señor, the señora, the man, the woman, the young man) when it names one
      const ADULTS = ['hombre', 'mujer', 'senor', 'senora', 'joven'], adultAsk = opts.some(o => ADULTS.includes(o));
      const tell = items.filter(it => TELLK.has(it.kind) && ((it.kind === 'person' && !it.air && (opts.includes(it.id) || (adultAsk && ADULTS.includes(it.id)))) || (it.kind === 'dog' && named.has('dogs')) || (it.kind === 'pigeon' && named.has('pigeon')) || (it.kind === 'coche' && named.has('coche'))));
      const itemsO = itemsOf(wo);
      for (const a of tell) { nTell++; const bxA = rowsBox(a.rows);
        if (!within(bxA, VIEW) && !(a.at[0] > x0 + 196 || a.at[0] < x0)) P.push('tell: ' + where + ' ' + a.id + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        let n = 0, ok = 0; const own = new Set(), ring = [0, 0, 0]; let nr = 0; for (const [y, x1, x2] of a.rows) for (let x = x1; x <= x2; x++) own.add(y * 240 + x);
        for (const [y, x1, x2] of a.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i)) continue; const z = zoneAt(key, x, y + dy); if (z === 'out') continue; n++; if (plainZ(z, a)) ok++; const c = G.rgb[key]; ring[0] += c[i * 3]; ring[1] += c[i * 3 + 1]; ring[2] += c[i * 3 + 2]; nr++; }
        const ao0 = itemsO.find(x => x.id === a.id), oldPlain = ao0 ? plainOld(ao0) : 0;
        if (n && ok < n * .8 && ok / n < oldPlain - .03 && a.at[0] >= x0 && a.at[0] < x0 + 196) P.push('tell: ' + where + ' ' + a.id + ' at ' + a.at + ': only ' + R(ok / n * 100) + '% of what is round it is plain paving, lawn or sky (or its own bench, wire or back)');
        if (nr) { const d = Math.max(dE(a.mean, ring.map(v => v / nr)), dE(OUTC, ring.map(v => v / nr))); if (!key.startsWith('dia')) nightWorst = Math.min(nightWorst, d);
          // the old picture's backdrop round the same thing at its old place (its background, banco.js fondo)
          const ao = itemsO.find(x => x.id === a.id); let dOld = 99; if (ao) { const s2 = [0, 0, 0]; let n2 = 0; const own2 = new Set(); for (const [y, x1, x2] of ao.rows) for (let x = x1; x <= x2; x++) own2.add(y * 240 + x);
            for (const [y, x1, x2] of ao.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const yy = y + dy, i = yy * 240 + x; if (own2.has(i) || x < 0 || x >= 240 || yy < 0 || yy >= 216) continue; for (let c = 0; c < 3; c++) s2[c] += M.oldBg[i * 4 + c]; n2++; } if (n2) dOld = Math.max(dE(ao.mean, s2.map(v => v / n2)), dE(OUTC, s2.map(v => v / n2))); }
          if (d < 15 && d < dOld - 3 && !key.startsWith('dia')) P.push('tell: ' + where + ' ' + a.id + ' stands out from what is round it by only ' + R(d) + ' (' + key + '; the old picture ' + R(dOld) + ')'); else if (d < 15) lowAsOld.add(a.id + ' ' + R(d) + ' (old ' + R(dOld) + ')'); }
        for (const b2 of tell) if (a.id < b2.id) { const nn = rowsOverlap(a.rows, b2.rows); if (!nn) continue; const ao = itemsO.find(x => x.id === a.id), bo2 = itemsO.find(x => x.id === b2.id); if (ao && bo2 && rowsOverlap(ao.rows, bo2.rows)) continue; P.push('tell: ' + where + ' ' + a.id + ' and ' + b2.id + ' overlap by ' + nn + ' px (apart in the old picture)'); } }
    }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least; the park by its hintBox), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face' + (handOld.size ? ' (but as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow 4 px and more inside the view (' + cardSpare + ' at the least), 2 px clear of the rounds card and of everyone\'s head and body, over no dog, the pushchair or a thing, nor what the ask names (over the wire\'s pigeons at no ask that names them: ' + ([...cardsOverPigeons].join(', ') || 'none') + '; over ' + ([...cardsOverSet].join(', ') || 'nothing') + ' of the set, named by no ask with cards), the sun and the moon under none; (new) at each of the ' + cardHint + ' cards the hint drawn round it: its frame 2 px inside the view, across no head, its hand on no face; ' + nTell + ' times someone a learner must find or tell apart: whole in the view, on plain paving, lawn, sky or their own bench, apart where the old had them apart, ' + R(nightWorst) + ' at the least from their backdrop in the evening and at night (CIE76, their fill or their dark outline against the 2 px round them; 15 kept, or no less than the old picture: ' + ([...lowAsOld].join(', ') || 'none lower') + ')');

  /* heads: nobody's face against a tree, the lamp post, the pole or the wire (where the old picture kept it clear) */
  { const OLDPARTS = [['arbol', (x, y) => [[40, 98], [122, 94], [218, 98]].some(([tx, ty]) => ((x - tx) / 24) ** 2 + ((y - ty + 10) / 17) ** 2 <= 1 || (x >= tx - 3 && x < tx + 3 && y >= ty && y < ty + 34))],
      ['farol', (x, y) => (x >= 163 && x <= 177 && y >= 48 && y < 158) || (x >= 160 && x < 179 && y >= 32 && y < 48)], ['poste', (x, y) => x >= 21 && x <= 23 && y >= 48 && y < 138], ['cable', (x, y) => x >= 22 && Math.abs(y - cableYf(x)) < 1]];
    const bad = new Map(); let n = 0;
    for (const [where, w, rest] of allW) { if (rest === false) continue; const key = keyOf(w); for (const [fn, f] of facesOf(w)) { if (fn === 'the frog\'s face') continue; n++;
      for (let y = f[1]; y < f[1] + f[3]; y++) for (let x = f[0]; x < f[0] + f[2]; x++) { const t = TAGS[key][y * 240 + x]; if (!t || !/^(arbol|farol|poste|cable)/.test(t)) continue; const tk = t.replace(/\d$/, ''), old = OLDPARTS.find(o => o[0] === tk);
        if (old && old[1](x, y)) continue; bad.set(fn + ' / ' + t, where + ' (face ' + JSON.stringify(f) + ', its pixel ' + x + ',' + y + ')'); } } }
    for (const [k, w] of [...bad].slice(0, 20)) P.push('heads: ' + k + ' (behind the face, where the old picture had none) at ' + w);
    notes.push('heads: at ' + n + ' face-moments (everyone at rest) no face has a tree, the lamp post, the pole or the wire behind it where the old picture did not'); }

  /* the sky */
  { const [sx, sy, sr] = F.SUN, [mx, my, mr] = F.MOON;
    for (const [nm, cx, cy, r] of [['sun', sx, sy, sr], ['moon', mx, my, mr]]) { if (cx - r - 1 < x0 || cx + r + 1 > x0 + 196 || cy - r - 1 < 0) P.push('sky: the ' + nm + '\'s disc is not whole inside the view');
      for (const k of ALL_STATES) { let n = 0; for (let y = Math.max(0, cy - r - 2); y <= cy + r + 2; y++) for (let x = cx - r - 2; x <= cx + r + 2; x++) if (G.z[k][y * 240 + x] > -1e8) n++; if (n) P.push('sky: ' + n + ' px of the set within 2 px of the ' + nm + ' (' + k + ')'); } }
    if (sx > 120) P.push('sky: the sun is not in the upper left');
    for (const [cx, cy, s2] of F.CLOUDS) { const b = [Math.floor(cx - 17 * s2 - 2), Math.floor(cy - 5 * s2 - 2), Math.ceil(cx + 19 * s2 + 2), Math.ceil(cy + 6 * s2 + 2)];
      for (const [nm, d] of [['sun', [sx, sy, sr]], ['moon', [mx, my, mr]]]) if (b[2] >= d[0] - d[2] && b[0] <= d[0] + d[2] && b[3] >= d[1] - d[2] && b[1] <= d[1] + d[2]) P.push('sky: the cloud at ' + cx + ',' + cy + ' is on the ' + nm);
      if (b[2] >= x0 + BOARD[0] && b[0] <= x0 + BOARD[0] + BOARD[2] && b[1] <= BOARD[1] + BOARD[3]) P.push('sky: the cloud at ' + cx + ',' + cy + ' is under the rounds card'); }
    notes.push('sky: the sun at ' + F.SUN.slice(0, 2) + ' (radius ' + sr + '), upper left, whole in the view, under no card and no board at any moment; the moon at ' + F.MOON.slice(0, 2) + ' (at night, W.luna) the same; the old picture\'s three clouds at ' + F.CLOUDS.map(c => c.slice(0, 2).join(',')).join('; ') + ', clear of both and of the corner card; by night no sun (patch)'); }

  /* the preview puts everyone where the sheet's rule does, at every recorded moment; the rule puts everyone at rest where the port's play has them */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = placesOf(remapW(sh, ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw || li === 0) return; const prev = placesOf(remapW(sh, r.lines[li - 1].W, r.story.id)), port = placesOf(tw.W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k] || /^perro\.joven|^paloma/.test(k)) continue; nR++; if (port[k].join() !== p.join()) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    if (badR) for (const [k, w] of [...off].slice(0, 30)) P.push('rule: ' + k + ' in the port\'s play (' + w + ')');
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places of the people, the frog, the dogs, the pigeons, the things and the pushchair) banco-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); and the rule puts each of the ' + nR + ' places at rest where the port\'s play has them (' + badR + ' differ)'); }

  /* the review pictures */
  { let nPic = 0; const pairDiff = [], zoom2 = [];
    const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
    for (const [word, sides2] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides2)) { const ps = sides2[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps, sh), key = keyOf(w); ws[side] = w; nPic++;
        const crop = pc.crop;
        const mrg = pc.zoom === 2 ? 1 : 2; for (const it of itemsOf(w)) { const b = rowsBox(it.rows); if (!within([b[0] - mrg, b[1] - mrg, b[2] + 2 * mrg, b[3] + 2 * mrg], crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with ' + mrg + ' px to spare in ' + JSON.stringify(crop)); }
        // a zoom 2 picture shows no shadow without its caster
        if (pc.zoom === 2) { for (const [part, list] of Object.entries(G.shadowPx[key])) { const inC = i => { const x = i % 240, y = Math.floor(i / 240); return x >= crop[0] && x < crop[0] + crop[2] && y >= crop[1] && y < crop[1] + crop[3]; };
            const sh2 = list.filter(i => G.onGround[key][i] && inC(i)).length, own = (G.parts[key][part] || []).filter(inC).length; if (sh2 > 4 && own < 6) P.push('pair ' + nm + ': shows ' + sh2 + ' px of ' + part + '\'s shadow and not ' + part); }
          const inC2 = i => { const x = i % 240, y = Math.floor(i / 240); return x >= crop[0] && x < crop[0] + crop[2] && y >= crop[1] && y < crop[1] + crop[3]; };
          const cr = G.crown[key].filter(inC2).length, tr = Object.keys(G.parts[key]).filter(p => /^arbol/.test(p)).reduce((n, p) => n + G.parts[key][p].filter(inC2).length, 0); if (cr > 4 && tr < 6) P.push('pair ' + nm + ': shows a tree\'s crown shade and not the tree');
          zoom2.push(nm); } }
      if (!ws.si || !ws.no) continue;
      const diff = []; for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k);
      if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
      if (!diff.length) P.push('pair ' + word + ': the two pictures are the same');
      pairDiff.push(deacc(word) + ': ' + diff.join(', ')); }
    notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures), ' + zoom2.length + ' at zoom 2, the others at zoom 1 (a standing person is taller than 52 rows): everything in each whole with 1 px to spare at zoom 2 (2 at zoom 1); no zoom 2 picture shows a shadow without its caster; what differs: ' + pairDiff.join('; ')); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const T of NEW) for (const t of T.ticks) reached.add(keyOf(t.W)); for (const ps of pairSides) reached.add(keyOf(pairW(ps, sh)));
    for (const b of sh.setKey.baked) if (!reached.has(b.key)) P.push('state ' + b.key + ' is baked but nothing reaches it');
    for (const k of reached) if (!sh.setKey.baked.some(b => b.key === k)) P.push('state ' + k + ' is reached but not baked');
    notes.push('states: ' + sh.setKey.baked.length + ' baked states reached (' + sh.setKey.baked.map(b => b.key).join(', ') + '; every moment, pair and level picture), of the ' + ALL_STATES.length + ' the set can bake');
    const ms = Object.entries(G.ms).filter(([k]) => reached.has(k));
    console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome, each reached state: the first ' + ms.map(([k, v]) => k + ' ' + R(v.first)).join(', ') + ' ms; again ' + ms.map(([k, v]) => R(v.warm)).join(', ') + ' ms (the ground cached)'); }
  return P;
}
