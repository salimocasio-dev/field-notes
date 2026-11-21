#!/usr/bin/env node
'use strict';
/* La estufa's sheet (order 38a): writes docs/proyecto/pixel/estufa-sheet.json from estufa-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/estufa-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.ESTUFA_SET), its part map, depth, surfaces and every castShadow call from estufa-set.html in headless Chrome,
   for every baked state, and the set baked without each standing part (what is behind it); measures the old sprite layer as estufa.js draw()
   itself draws it (historia/engine.js, juego.js, kit.js and escenas/estufa.js as they are, and as the port will have them: every person, the
   frog, every pot, pan, cup, plate, tray, sack, jug, bucket and cloud, each against the same world without it); plays every story of the scene
   on the old page by the same machine as the recorded runs (coqui/tool/ref/trazas: juega.mjs --states for the steps' ends, page-init.js and
   page-drive.js with the same seed, think time and clock for every tick inside the acts), with estufa.js and the story files as the port will
   have them (the sheet's moves and remap); composes every moment as the game draws it (estufa.js draw: what comes before the sorted list, the
   list by its y, what comes after; each item owns the pixels it drew last; a set part is drawn again by sheet.front only where it is nearer than
   that owner) and checks every rule of the brief on that picture, against the old picture of the same moment composed the same way. It reads
   estufa.js itself for every number that is a place on the picture (the sheet's code). It loads estufa-preview.html (over a local http server it
   starts and stops) to check that the preview puts everyone where the sheet does. Nothing in the repo is written but the sheet (its temporary
   files live in docs/proyecto/pixel/estufa-tmp-*, removed at the end). A second run writes the same bytes. The models: El banco's maker (the way
   of composing and of reading the scene file) and El lago's (the play at every tick, the ask pictures).
   ESTUFA_NOCHECK=1: write the sheet only. ESTUFA_DUMP=<folder>: also write each run's steps and ticks, the recorded and the port's, there. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'estufa-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/estufa');
const ESTUFA_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/estufa.js'), 'utf8');
const LINES = ESTUFA_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('estufa.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const R = Math.round, r2 = v => Math.round(v * 100) / 100, r4 = v => Math.round(v * 1e4) / 1e4, W4 = p => p.map(r4);
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');

// the baked states: the stool there or not (W.banco). setKey(W), as the port has it
const STATES = ['banco1', 'banco0'];
const keyOf = w => w.banco === 0 || w.banco === false ? 'banco0' : 'banco1';
const queryOf = k => 'banco=' + (k === 'banco1' ? 1 : 0);
const THING_OF = p => p === 'estufa' ? 'estufa' : 'cocina';     // the stove is its own touch key; every other part is the room's
const STANDING = ['izq', 'estufa', 'der', 'salpicadero', 'campana', 'estante', 'banco', 'banco.patas'];   // the parts baked again without them
const FRONT = { banco: ['banco', 'banco.patas'], ventana: ['pared', 'ventana', 'izq', 'der', 'estufa', 'salpicadero', 'campana', 'estante'] };
const VIEW_X0 = 22, VIEW = [VIEW_X0, 0, 196, 216];

(async () => {
  const browser = await chromium.launch();
  const errs = [];
  const G = await setData(browser, errs);
  G.M = await measure(browser);
  const runs = storyStates();
  let sheet = make(G, runs);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.ESTUFA_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  G.TICKS = await tickStates(browser, runs, sheet);
  G.PV = await previewPlaces(browser, runs);
  if (process.env.ESTUFA_DUMP) { fs.mkdirSync(process.env.ESTUFA_DUMP, { recursive: true }); runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.ESTUFA_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states, ticks: G.TICKS[i].ticks }))); }
  G.MASK = await masks(browser, sheet, G, runs);
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome, the median of five fresh pages: ' + STATES.map(k => k + ' first ' + R(G.ms[k].first) + ' ms (' + G.ms[k].all.join(', ') + '), again ' + R(G.ms[k].warm) + ' ms').join('; '));
  if (problems.length) { const g = new Map(); for (const q of problems) { const k = q.replace(/ \((?:[^()]|\([^()]*\))*\)$/, ''); if (!g.has(k)) g.set(k, [q, 0]); g.get(k)[1]++; }
    console.log('CHECK FAILED (' + problems.length + ', ' + g.size + ' kinds):\n  ' + [...g.values()].slice(0, 200).map(([q, n]) => (n > 1 ? n + ' x ' : '') + q).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the set, every baked state, in a fresh page each (the first bake is the one the port must keep under 150 ms) ---------- */
async function setData(browser, errs) {
  const G = { parts: {}, z: {}, rgb: {}, shadows: {}, shadowPx: {}, onGround: {}, surf: {}, ms: {}, sin: {} };
  const url = (key, extra) => 'file://' + path.join(__dirname, 'estufa-set.html') + '?tags=1&' + queryOf(key) + (extra || '');
  for (const key of STATES) {
    const page = await browser.newPage(); page.on('pageerror', e => errs.push(String(e)));
    await page.goto(url(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(ESTUFA_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      // every castShadow call of a bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S2 = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S2.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      buildSet(); castShadow = cs0; part = part0;
      const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      const onGround = [], surf = []; for (let i = 0; i < W * H; i++) { onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0); surf.push(ESTUFA_SET.surfaceAt(i % W + .5, Math.floor(i / W) + .5).on); }
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), rgb: rgbA, calls, first: BAKE_MS, warm, shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, surf };
    });
    await page.close();
    // the bake as the port does it (no part tags), in five fresh pages: the median first bake (a page loaded while the machine is busy with
    // other work can take twice as long), and a second bake in the same page
    { const firsts = [], warms = []; for (let n = 0; n < 5; n++) { const pg = await browser.newPage(); await pg.goto('file://' + path.join(__dirname, 'estufa-set.html') + '?' + queryOf(key));
        const t = await pg.evaluate(() => { const t1 = performance.now(); buildSet(); return [BAKE_MS, performance.now() - t1]; }); firsts.push(t[0]); warms.push(t[1]); await pg.close(); }
      const med = a => a.slice().sort((x, y) => x - y)[a.length >> 1]; G.ms[key] = { first: med(firsts), warm: med(warms), all: firsts.map(R) }; }
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S });
    G.parts[key] = g.parts; G.z[key] = g.z; G.rgb[key] = g.rgb; G.shadows[key] = g.calls; G.shadowPx[key] = g.shadowPx; G.onGround[key] = g.onGround; G.surf[key] = g.surf;
    // the set without each standing part: what is behind it (thin things' contrast, the lit side of each thing)
    G.sin[key] = {};
    for (const p of STANDING) { if (key === 'banco0' && /^banco/.test(p)) continue;
      const pg = await browser.newPage(); pg.on('pageerror', e => errs.push(String(e))); await pg.goto(url(key, '&sin=' + p));
      G.sin[key][p] = await pg.evaluate(() => { const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, a = []; for (let i = 0; i < W * H; i++) a.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]); return a; });
      await pg.close(); }
  }
  return G;
}

/* ---------- the stories, played on the old page by the recorded runs' machine (juega.mjs --states: each step's end) ---------- */
function storyStates() {
  const { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'estufa') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(__dirname, 'estufa-tmp-'));
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

/* ---------- a local http server over the repo (the preview, the old page) ---------- */
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.woff2': 'font/woff2', '.css': 'text/css', '.mp3': 'audio/mpeg' };
async function serve(fn) {
  const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(REPO, u);
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); fs.createReadStream(f).pipe(res); });
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  try { return await fn('http://127.0.0.1:' + srv.address().port); } finally { await new Promise(r => srv.close(r)); }
}

/* ---------- the preview's places: estufa-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/estufa-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- estufa.js as the port will have it: the sheet's moves applied (the same edit as estufa-preview.html's) ---------- */
function portSource(sheet) {
  let src = ESTUFA_JS; const done = new Set();
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); if (!src.includes(m.src)) throw new Error('estufa.js does not hold ' + m.src); src = src.split(m.src).join(m.to); }
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

/* ---------- every tick inside the acts: the old page played by the same machine as the recorded runs, estufa.js and the story files as the
   port will have them, the scene's W kept after every timer the runner fires when it changed ---------- */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const WKEYS = ['gente', 'cq', 'fuegos', 'izq', 'der', 'basura', 'ventana', 'ventanacome', 'cosas', 'vuelos', 'banco', 'encima', 'estante', 'repisa', 'olor', 'mat', 'plata', 'cubo', 'salero', 'tarjeta', 'marcas', 'respEn', 'resp', 'spot', 'twinkle'];
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = {}; for (const k of ${JSON.stringify(WKEYS)}) o[k] = W[k]; o.F = typeof F === 'number' ? F : 0;
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
        await ctx.route(/\/historia\/escenas\/estufa\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
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

/* ---------- the old sprite layer, as estufa.js draw() draws it ----------
   Every item a world shows, in the order draw() draws it: before the sorted list (the window's people, the shelf's sack and jar, the two
   burners with what stands on them, the smell, the counters' things), the sorted list by its y (the bucket, the stool, the people, the
   things, the frog: pushed in that order, a stable sort), then after it (abuela's big plate, the frog's plate, the shaker, what flies, the
   thought clouds). Each item's shape is what draw() changes for a world holding only that item, against the same world without it (a person
   with what they hold and the baby, a pot with its flames and steam at frame 0, the frog with what is on his head) */
const PEOPLE_H = { abuela: 51, luis: 44, carmen: 44 };   // estufa.js alto(): abuela 51, a child 44, else 56
const SHAPE_AT = [120, 150], FROG_AT = [104, 123];
const BASE = () => ({ respEn: [125, 46], estante: 0, repisa: 0, olor: null, mat: null, plata: null, cubo: 0, salero: 0, gente: {}, fuegos: [{}, {}], izq: {}, der: {}, basura: [], ventana: [], ventanacome: 0, cola: [], cosas: [], vuelos: [], banco: 0, encima: null, tarjeta: null, marcas: null, cq: { x: 0, y: 0, s: 1, dy: 0, al: 1, vis: 0, bub: null, hace: null } });
const J = o => JSON.stringify(o == null ? null : o);
const rowsOfPx = list => { const S2 = new Set(list), rows = []; for (const i of [...S2].sort((a, b) => a - b)) { const y = Math.floor(i / 240), x = i % 240, l = rows[rows.length - 1]; if (l && l[0] === y && l[2] === x - 1) l[2] = x; else rows.push([y, x, x]); } return rows; };
const shownP = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
function rawItems(w, side) {
  const out = [], I = w.izq || {}, Dr = w.der || {}, add = (group, kind, id, key, spec, extra) => out.push(Object.assign({ group, kind, id, key: side + '|' + key, spec }, extra || {}));
  if (w.ventana && w.ventana.length) add('pre', 'ventana', 'the window\'s people', 'v|' + J(w.ventana) + J(w.ventanacome), { ventana: w.ventana, ventanacome: w.ventanacome });
  if (w.estante) add('pre', 'thing', 'estante', 'e|' + w.estante, { estante: w.estante });
  (w.fuegos || []).forEach((f, i) => { if (f && f.k) add('pre', 'pot', 'fuego' + i, 'f' + i + '|' + J(f), { fuegos: i ? [{}, f] : [f, {}] }); });
  if (w.olor) add('pre', 'smell', 'olor', 'o|' + J(w.olor), { olor: w.olor });
  if (I.llenando) add('pre', 'thing', 'llenando', 'll', { izq: { llenando: 1 } });
  for (const k of ['saco', 'tazon']) if (I[k]) add('pre', 'thing', k, k + '|' + I[k], { izq: { [k]: I[k] } });
  if (I.bandeja) add('pre', 'thing', 'bandeja', 'bj|' + J(I.bandeja), { izq: { bandeja: I.bandeja } });
  if (w.repisa) add('pre', 'thing', 'repisa', 'rp', { repisa: 1 });
  if (Dr.servidos && Dr.servidos.length) add('pre', 'thing', 'servidos', 'sv|' + J(Dr.servidos.map(q => q.items)), { der: { servidos: Dr.servidos } });
  if (I.jarra) add('pre', 'thing', 'jarra', 'jr', { izq: { jarra: 1 } });
  if (I.tazas) add('pre', 'thing', 'tazas', 'tz|' + I.tazas, { izq: { tazas: I.tazas } });
  if (Dr.platos && Dr.platos.length) add('pre', 'thing', 'platos', 'pl|' + J(Dr.platos), { der: { platos: Dr.platos } });
  if (Dr.pila) add('pre', 'thing', 'pila', 'pi|' + Dr.pila, { der: { pila: Dr.pila } });
  if (Dr.platito) add('pre', 'thing', 'platito', 'pt', { der: { platito: 1 } });
  if (Dr.masa != null) add('pre', 'thing', 'masa', 'ma|' + Dr.masa, { der: { masa: Dr.masa } });
  if (Dr.fuente) add('pre', 'thing', 'fuente', 'fu|' + J(Dr.frituras), { der: { fuente: 1, frituras: Dr.frituras } });
  // the sorted list, in push order
  if (w.cubo) add('list', 'thing', 'cubo', 'cu|' + J(w.basura), { cubo: 1, basura: w.basura || [] }, { y: 209 });
  if (w.banco && side === 'o') add('list', 'stool', 'the old stool', 'bn', { banco: 1 }, { y: 185 });
  for (const [id, p] of Object.entries(w.gente || {})) if (p && p.vis !== 0 && !(p.al != null && p.al <= .3)) {
    const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], dy: 0, paso: 0, bub: null, piensa: null, vis: 1 });
    add('list', 'person', id, 'p|' + id + '|' + J([p.pose, p.dir < 0 ? -1 : 1, p.lleva, p.alza, p.bebe, p.come, p.cierra]), { gente: { [id]: o } }, { o: p, y: p.y, at: [R(p.x), R(p.y) + (id === 'abuela' ? 0 : R(p.dy || 0))] });
    if (p.piensa) add('post', 'cloud', id + '\'s cloud', 'n|' + id + '|' + J([p.pose, p.dir < 0 ? -1 : 1, p.lleva, p.alza, p.bebe, p.come, p.cierra]) + '|' + J([p.piensa, p.pdx]), { gente: { [id]: Object.assign({}, o, { piensa: p.piensa, pdx: p.pdx }) } }, { o: p, at: [R(p.x), R(p.y)] });
  }
  (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0) { const o = Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1], z: null }); add('list', 'thing', 'cosa ' + (c.id || c.k + i), 't|' + J([c.k, c.v, c.rot, c.vapor]), { cosas: [o] }, { o: c, y: c.z != null ? c.z : c.y + 1, at: [R(c.x), R(c.y)] }); } });
  const q = w.cq; if (q && q.vis && !(q.al <= .3)) add('list', 'frog', 'the frog', 'q|' + J([q.s, w.encima]), { cq: Object.assign({}, q, { x: FROG_AT[0], y: FROG_AT[1], dy: 0, al: 1, bub: null, vis: 1 }), encima: w.encima }, { o: q, y: q.y + 27, at: [q.x, q.y + R(q.dy || 0)] });
  // after the list
  if (w.plata) add('post', 'thing', 'plata', 'pa|' + J(w.plata), { plata: w.plata });
  if (w.mat) add('post', 'thing', 'mat', 'mt|' + J(w.mat), { mat: w.mat });
  if (w.salero) add('post', 'thing', 'salero', 'sl', { salero: 1 });
  (w.vuelos || []).forEach((v, i) => add('post', 'thing', 'vuelo ' + v.k + i, 'u|' + J([v.k, v.v, v.rot]), { vuelos: [Object.assign({}, v, { x: SHAPE_AT[0], y: SHAPE_AT[1] })] }, { o: v, at: [R(v.x), R(v.y)] }));
  return out;
}
// each item's offset from where its shape was measured
const shiftOf = it => { if (it.kind === 'person' || it.kind === 'cloud') return [R(it.o.x) - SHAPE_AT[0], R(it.o.y) - SHAPE_AT[1] + (it.kind === 'person' && it.id !== 'abuela' ? R(it.o.dy || 0) : 0)];
  if (it.kind === 'frog') return [it.o.x - FROG_AT[0], it.o.y - FROG_AT[1] + R(it.o.dy || 0)];
  if (it.o && (it.key.split('|')[1] === 't' || it.key.split('|')[1] === 'u')) return [R(it.o.x) - SHAPE_AT[0], R(it.o.y) - SHAPE_AT[1]];
  return [0, 0]; };
// the shapes: the old scene file and the port's, each in its own page; every key seen at any moment of either
async function masks(browser, sheet, G, runs) {
  const keys = { o: new Map(), n: new Map() };
  const add = (w, side) => { for (const it of rawItems(w, side)) if (!keys[side].has(it.key)) keys[side].set(it.key, it.spec); };
  for (const r of runs) for (const l of r.lines) add(l.W, 'o');
  for (const T of G.TICKS) { for (const t of T.ticks) add(t.W, 'n'); for (const L of T.states) add(L.W, 'n'); }
  for (const ps of pairSidesOf()) { add(pairW(ps, null), 'o'); add(pairW(ps, sheet), 'n'); }
  // a cloud's "minus" (the person under it) is found among the person keys
  const out = {};
  for (const side of ['o', 'n']) {
    const page = await browser.newPage(); const errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
    for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
    await page.addScriptTag({ content: side === 'o' ? ESTUFA_JS : portSource(sheet) });
    if (errs.length) throw new Error('masks: ' + errs.join('; '));
    const list = [...keys[side].entries()].filter(e => e[1]);
    Object.assign(out, await page.evaluate(([list, base]) => {
      const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'), E = ESCENAS.estufa;
      const shot = w => { W = w; F = 0; TALK = null; g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.imageSmoothingEnabled = false; g.clearRect(0, 0, 240, 216); E.draw(g, w, 0); return g.getImageData(0, 0, 240, 216).data; };
      const bg = shot(JSON.parse(base)), res = {}, img = {};
      for (const [key, spec] of list) {
        const d = shot(Object.assign(JSON.parse(base), JSON.parse(JSON.stringify(spec)))); img[key] = d;
        const rows = []; let n = 0; const s = [0, 0, 0], px = [];
        for (let y = 0; y < 216; y++) { let a = -1; for (let x = 0; x <= 240; x++) { const i = (y * 240 + x) * 4, ch = x < 240 && (d[i] !== bg[i] || d[i + 1] !== bg[i + 1] || d[i + 2] !== bg[i + 2]);
          if (ch) { n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; px.push(y * 240 + x, d[i], d[i + 1], d[i + 2]); if (a < 0) a = x; } else if (a >= 0) { rows.push([y, a, x - 1]); a = -1; } } }
        res[key] = { rows, mean: s.map(v => Math.round(v / Math.max(1, n))), px };
      }
      return res;
    }, [list, JSON.stringify(BASE())]));
    await page.close();
  }
  // a cloud: its own pixels, where the drawing with it differs from its person's alone
  for (const key of Object.keys(out)) { if (key.split('|')[1] !== 'n') continue; const parts = key.split('|'), mk = parts[0] + '|p|' + parts[2] + '|' + parts[3]; if (!out[mk]) throw new Error('no shape for the person under ' + key);
    const own = new Map(); for (let i = 0; i < out[mk].px.length; i += 4) own.set(out[mk].px[i], out[mk].px.slice(i + 1, i + 4).join());
    const keep = []; for (let i = 0; i < out[key].px.length; i += 4) { const j = out[key].px[i]; if (own.get(j) !== out[key].px.slice(i + 1, i + 4).join()) keep.push(j); }
    out[key].rows = rowsOfPx(keep); }
  return out;
}

// the bubbles (as estufa.js bub2 draws them: twice their size, the tail's tip at the origin, both frames of the bob), each person's sprite height
// (estufa.js gente: top = y - im.height + 1), abuela's head off her x (the middle of her top 10 rows, facing right)
async function measure(browser) {
  const page = await browser.newPage(); const errs = []; page.on('pageerror', e => errs.push(String(e)));
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  const M = await page.evaluate(() => {
    const keys = Object.keys(BUB).concat(Object.keys(BUBL)), bubbles = {};
    for (const k of keys) { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const a of [0, 1]) { const cv = document.createElement('canvas'); cv.width = 400; cv.height = 300; const g = cv.getContext('2d'); g.translate(200, 250); g.scale(2, 2); bub(g, k, 0, 0, a);
        const d = g.getImageData(0, 0, 400, 300).data; for (let i = 0; i < 400 * 300; i++) if (d[i * 4 + 3]) { const x = i % 400 - 200, y = (i / 400 | 0) - 250; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } }
      bubbles[k] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1]; }
    const FAM = KIT.FAM, Q = { luis: FAM.hermano, carmen: FAM.hermana, abuelo: FAM.abuelo, mama: FAM.mama, papa: FAM.papa }, heights = {};
    for (const [id, w] of Object.entries(Q)) heights[id] = KIT.mkPersona(w, 'idle', 0, 0).height;
    const im = mkAbuela('idle', 0), cv = document.createElement('canvas'); cv.width = 60; cv.height = 60; const g = cv.getContext('2d'); g.drawImage(im, 0, 0); const d = g.getImageData(0, 0, 60, 60).data;
    let top = -1, a = 1e9, b = -1e9; for (let y = 0; y < 60 && (top < 0 || y < top + 10); y++) for (let x = 0; x < 60; x++) if (d[(y * 60 + x) * 4 + 3] > 40) { if (top < 0) top = y; a = Math.min(a, x); b = Math.max(b, x); }
    return { bubbles, heights, abuelaHead: Math.round((a + b + 1) / 2) - 30 };
  });
  await page.close(); if (errs.length) throw new Error('measure: ' + errs.join('; '));
  return M;
}

/* ---------- the review pictures ---------- */
const PAIRS = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
const pairSidesOf = () => PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'estufa').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
// a pair picture's world (cual.js panelW: the frog at 123, 150 s .86, seen only if the pair shows cards), through the sheet's remap when given
function pairW(ps, sheet) {
  const w = Object.assign(BASE(), { cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: ps.spec.set && ps.spec.set.resp ? 1 : 0, bub: null } }, JSON.parse(JSON.stringify(ps.spec.set || {})));
  if (!sheet) return w;
  const mv = o => { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === R(o.x) && e.old[1] === R(o.y) && e.uses.some(u => u.startsWith('cual-estufa.json'))); if (m) { o.x = m.new[0]; o.y = m.new[1]; } };
  for (const o of Object.values(w.gente || {})) mv(o); for (const o of w.cosas || []) mv(o); for (const o of w.vuelos || []) mv(o);
  if (w.mat) mv(w.mat); if (w.plata) mv(w.plata); if (w.cq && w.cq.vis) { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === w.cq.x && e.old[1] === w.cq.y); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }
  if (w.olor) { const m = sheet.remap.find(e => e.moved && e.kind === 'rect' && e.old.join() === w.olor.join()); if (m) w.olor = m.new.slice(); }
  return w;
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  const surf = (key, sx, sy) => { const x = Math.floor(sx), y = Math.floor(sy); return x < 0 || x >= 240 || y < 0 || y >= 216 ? 'out' : G.surf[key][y * 240 + x]; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ, surf };
}
// the walkable surface under a screen point and its world point: the stool's top, a top of the run, the shelf, the floor (estufa-set.html surfaceAt)
function surfaceW(E, F, sx, sy) {
  const st = E.atZ(sx, sy, F.STOOL.h); if (Math.abs(st[0] - F.STOOL_C[0]) <= F.STOOL.hw && Math.abs(st[1] - F.STOOL_C[1]) <= F.STOOL.hw) return { on: 'banco', w: st };
  const t = E.atZ(sx, sy, F.CZ); if (t[1] >= 0 && t[1] <= F.D && t[0] >= F.AL0 && t[0] <= F.AR1) return { on: t[0] < F.AS0 ? 'izq' : t[0] <= F.AS1 ? 'estufa' : 'der', w: t };
  const sl = E.atZ(sx, sy, F.SHELF.z); if (sl[1] >= 0 && sl[1] <= F.SHELF.d && sl[0] >= F.SHELF.a0 && sl[0] <= F.SHELF.a1) return { on: 'estante', w: sl };
  const g = E.atZ(sx, sy, 0); return { on: g[0] >= 0 && g[1] > F.D ? 'suelo' : 'mueble', w: g };
}

/* ---------- the design: what moves and why (make() reads it). Every move is an exact piece of estufa.js and its replacement ---------- */
// the run's top at column sx, depth d from the wall (its row); where an item of width w (px) centred at x stands on it: its bottom row
// between the back edge under its right end and the front edge under its left end (the run falls half a row a pixel to the right)
function geometry(E, F) {
  const topY = (sx, d, z = F.CZ) => E.project(d + (sx - E.OX) / E.S * E.R2, d, z).sy;
  const rowOn = (x, w, m = .14) => { const lo = topY(x + w / 2, m), hi = topY(x - w / 2, F.D - m); return { y: R((lo + hi) / 2), lo, hi }; };
  const shelfRow = x => R(topY(x, F.SHELF.d * .5, F.SHELF.z));
  const sillRow = x => R(topY(x, .08, F.WIN.z0 - .1));
  const holeTop = x => R(topY(x, 0, F.WIN.z1));
  const burnerRow = i => F.burners[i].screen[1];
  // the floor in front of the run: the first row at column x where the floor is clear (world y >= D + .2) for whoever stands there
  const clearY = x => { for (let y = 120; y < 216; y++) { const g = E.atZ(x, y - 1, 0); if (g[1] >= F.D + .2) return y; } return 216; };
  return { topY, rowOn, shelfRow, sillRow, holeTop, burnerRow, clearY };
}
function designMoves(E, F) {
  const Gm = geometry(E, F), FYS = [107, 145].map(x => Gm.rowOn(x, 30).y), FDY = FYS.map(v => v - 121);
  const EN = { saco: [49, 26], tazon: [67, 24], platos: [189, 42], basura: [207, 24], jarra: [188, 20], tazas: [201, 30], masa: [38, 24], fuente: [64, 24], apartes: [222, 15] };
  const ENY = Object.fromEntries(Object.entries(EN).map(([k, [x, w]]) => [k, Gm.rowOn(x, w).y + 1]));
  ENY.jarra = Math.ceil(Gm.topY(EN.jarra[0] + 10, .16)) + 1;
  ENY.tazas = Math.floor(Gm.rowOn(EN.tazas[0], EN.tazas[1]).hi);   // the clean cups at the front of the right counter, before the jug   // the jug at the back of the right counter: its hint hand ends above the faces of whoever stands before it
  const BJ = Gm.rowOn(50, 46).y + 1, REPY = R(Gm.topY(190, .3)) + 1, SALY = R(Gm.topY(126, F.D - .2)) + 1;
  const SVY = [0, 1, 2].map(i => Gm.rowOn(180 + i * 19, 30).y + 1);
  const ES = [Gm.shelfRow(38) + 1, Gm.shelfRow(50) + 1], WY = [0, 1, 2].map(j => Gm.holeTop(178 + j * 12) + 1), SILL = [0, 1, 2].map(j => Gm.sillRow(178 + j * 12) + 1);
  const STEAM = { pot: -27, potSmoke: -31, pan: -20 };
  const NUM = { FYS, FDY, ENX: Object.fromEntries(Object.entries(EN).map(([k, v]) => [k, v[0]])), ENY, BJ, REPY, SALY, SVY, ES, WY, SILL, STEAM };
  const M = [];
  const mv = (act, src, to, why, pts) => M.push(Object.assign({ act, src, to, why }, pts ? { pts } : {}));
  // the new constants: one line of estufa.js gains them
  mv('*', 'const REP=[190,ENC+1],SVX=i=>180+i*19,ESX=EST[0]+26,CUBO=[34,208],SALX=EST[0]+40;', 'const REP=[190,' + REPY + '],SVX=i=>180+i*19,SVY=i=>' + JSON.stringify(SVY) + '[i],ESX=EST[0]+26,CUBO=[37,208],SALX=EST[0]+40,SALY=' + SALY + ',FYS=' + JSON.stringify(FYS) + ',FYi=i=>FYS[i],BJ=' + BJ + ';',
    'the places on the run\'s tops (layout: the run falls half a row a pixel to the right, so a place on its top keeps its x and takes the top\'s row there): REP, the two plates put by on the right counter (at its back); SVY(i), the row of the plate served to each child on the right counter (SVX keeps its x); SALY, the shaker on the stove\'s top at its front edge between the burners (SALX keeps its x; the old stood it on the stove\'s front at row ' + 127 + '); FYS, the row each burner\'s pot stands at (FX keeps its x: the old FY was one row for both; on the world\'s axes the two burners, side by side along the stove, are ' + (FYS[1] - FYS[0]) + ' rows apart, ' + FDY.map(v => (v > 0 ? '+' : '') + v).join(' and ') + ' rows from the old); BJ, the tray\'s row on the left counter; CUBO, the waste bucket on the floor, 3 px right (what is thrown in it whole inside the view with 3 px to spare)',
    [['cubo', [34, 208], [37, 208]], ['plato', [190, 113], [190, REPY]], ['salero', [126, 127], [126, SALY]], ...[0, 1, 2].map(i => ['plato', [180 + i * 19, 122], [180 + i * 19, SVY[i]]])]);
  mv('*', 'const EN={saco:[45,ENC+10],tazon:[67,ENC+10],platos:[184,ENC+9],basura:[207,ENC+10],jarra:[181,ENC+9],tazas:[195,ENC+9],masa:[38,ENC+9],fuente:[64,ENC+9],apartes:[222,ENC+9]};',
    'const EN={saco:[49,' + ENY.saco + '],tazon:[67,' + ENY.tazon + '],platos:[184,' + ENY.platos + '],basura:[207,' + ENY.basura + '],jarra:[188,' + ENY.jarra + '],tazas:[195,' + ENY.tazas + '],masa:[38,' + ENY.masa + '],fuente:[64,' + ENY.fuente + '],apartes:[222,' + ENY.apartes + ']};',
    'EN: where each thing stands on a counter takes the row of the top there, its whole bottom row on the top (the cups of rice and beans, the plates, the jug and the cups, the board of batter, the fritter plate): the left counter\'s ' + (ENY.saco - 122) + ' to ' + (ENY.masa - 121) + ' rows, the right counter\'s ' + (ENY.jarra - 121) + ' to ' + (ENY.tazas - 121) + ' rows from the old; each keeps its x but the cups of rice, 4 px right so that their hint frame (box + 12) is 2 px inside the view (the old was not); where the frog and Carmen stand before them does not move (echa, carmenecha). The jug of cold chocolate 7 px right, at the back of the counter (cuidado): its hint hand off the face of whoever came in for a cup; the frog\'s place before the jug moves with it (ranallena: EN.jarra[0] - 4; his hops there are the old ones)',
    [['saco', [45, 122], [49, ENY.saco]], ['tazon', [67, 122], [67, ENY.tazon]], ['platos', [184, 121], [184, ENY.platos]], ['jarra', [181, 121], [188, ENY.jarra]], ['tazas', [195, 121], [195, ENY.tazas]], ['masa', [38, 121], [38, ENY.masa]], ['fuente', [64, 121], [64, ENY.fuente]]]);
  // every line that draws or moves something at a burner: FY becomes that burner's row
  const byBurner = (L, idx) => { const src = LINES[L - 1]; let to = src.replace(/SALX,FY\+6/g, 'SALX,SALY'); to = to.replace(/\bFY\b/g, 'FYi(' + idx + ')'); return [src.trim(), to.trim()]; };
  const burnerLines = [
    [lineOf('function llama(c,x,a){'), '+(x!==FX[0])', 'llama: a burner\'s flames at its own row'],
    [lineOf('if(f.k==="olla"){tenida(c,"olla",x,FY+1'), 'i', 'fuego: the pot, its contents, foam, smoke and steam at its burner\'s row'],
    [lineOf('if(f.mal)tenida(c,"monton",x,FY-13'), 'i', 'fuego: as above'],
    [lineOf('else{tenida(c,"sarten",x+6,FY+1)'), 'i', 'fuego: the pan and what fries in it at its burner\'s row'],
    [lineOf('{id:"olla0",si:'), null, 'the pots\' boxes at their burners'],
    [lineOf('{id:"sarten",si:'), '0', 'the pan\'s box at burner 0; the tray\'s box at the tray (BJ)'],
    [lineOf('if(W.salero)tenida(c,"salero",SALX,FY+6)'), '0', 'the shaker on the stove\'s top (SALY)'],
    [lineOf('async echa(o){'), 'i', 'echa: the cup flies into its pot; the frog still stands where he stood before the cups of rice (EN.saco moved 4 px right)'], [lineOf('async carmenecha(o){'), 'i', 'carmenecha: as echa; Carmen too'], [lineOf('async ultimas27(){'), 'i', 'ultimas27: as echa'],
    [lineOf('async saca(o){'), 'i', 'saca: what is lifted out of a pot starts at it'], [lineOf('const arroz=f.con==="arroz";for(const j of'), 'i', 'sirve27: each helping starts at its pot'],
    [lineOf('async toma28(o){'), '0', 'toma28: the shaker from its place (SALY)'], [lineOf('async sala(o){'), '0', 'sala: salt over the pan at burner 0'],
    [lineOf('async par(o){'), '0', 'par: the pair from the tray (BJ) into the pan'], [lineOf('W.salero=0;await vuela({k:"salero"},SALX,FY+6,FX[0]'), '0', 'par: abuela salts the pan'],
    [lineOf('async sirve28(o){'), '0', 'sirve28: from the pan to the plate (SVY)'], [lineOf('async salplato(o){'), '0', 'salplato: the shaker from its place to the plate (SVY)'],
    [lineOf('const cu={k:"cucharon",x:FX[1]+9'), '1', 'ranallena: the ladle in the pot at burner 1'], [lineOf('async frie(){'), '0', 'frie: the batter into the pan'],
    [lineOf('async saca29(o){'), '0', 'saca29: the fritter from the pan'], [lineOf('await vuela({k:"fritura",v:"dorada"},FX[0],FY-10'), '0', 'saca29: as above'],
  ];
  for (const [L, idx, why] of burnerLines) { let [src, to] = byBurner(L, idx);
    // the steam and the smoke rise from 5 rows (a pot) or 6 rows (the pan) higher: over the pot's rim and the pan's oil they did not show (2.0)
    to = to.replace('vapor(c,x,FYi(i)-26,1)', 'vapor(c,x,FYi(i)' + STEAM.potSmoke + ',1)').replace('vapor(c,x,FYi(i)-22,0)', 'vapor(c,x,FYi(i)' + STEAM.pot + ',0)').replace(/vapor\(c,(px|x),FYi\(i\)-14,([01])\)/g, 'vapor(c,$1,FYi(i)' + STEAM.pan + ',$2)');
    if (idx === null) { to = src.replace('[FX[0]-17,FY-24,34,28]', '[FX[0]-17,FYi(0)-24,34,28]').replace('[FX[1]-17,FY-24,34,28]', '[FX[1]-17,FYi(1)-24,34,28]'); }
    to = to.replace('ranaA(e[0]+6,186)', 'ranaA(e[0]+(key==="saco"?2:6),186)').replace('mueve("carmen",e[0]+4,AYUDA[1])', 'mueve("carmen",e[0]+(key==="saco"?0:4),AYUDA[1])').replace('box:[28,ENC-4,46,16]', 'box:[28,BJ-15,46,16]').replace(/,40,ENC\+4,/, ',40,BJ-7,').replace(/,60,ENC\+4,/, ',60,BJ-7,').replace('SVX(i),ENC+6', 'SVX(i),SVY(i)-4').replace(/px\+4,ENC-6/g, 'px+4,SVY(i)-16').replace(/cae28\(px,ENC\+2\)/g, 'cae28(px,SVY(i)-8)');
    if (src !== to) mv('*', src, to, why); }
  // the counters' own lines
  const sv = LINES[lineOf('(D.servidos||[]).forEach((pl,i)=>{const x=SVX(i),y=ENC+10;') - 1].trim();
  mv('*', sv, sv.replace('const x=SVX(i),y=ENC+10;', 'const x=SVX(i),y=SVY(i);'), 'the plates served to the children: each on the right counter\'s top at its own row (SVY)');
  const bj = LINES[lineOf('if(I.bandeja){const t=I.bandeja;tenida(c,"bandeja",50,ENC+11)') - 1].trim();
  mv('*', bj, bj.replace('tenida(c,"bandeja",50,ENC+11)', 'tenida(c,"bandeja",50,BJ)').replace(/ENC\+8-\(i%2\)/g, 'BJ-3-(i%2)'), 'the tray of drumsticks and eggs on the left counter (BJ), what lies on it with it', [['bandeja', [50, 123], [50, BJ]]]);
  const es = LINES[lineOf('if(W.estante){const v=W.estante===2') - 1].trim();
  mv('*', es, es.replace('tenida(c,"saco",38,50,0,0,v)', 'tenida(c,"saco",38,' + ES[0] + ',0,0,v)').replace('tenida(c,"frasco",50,50,0,0,v)', 'tenida(c,"frasco",50,' + ES[1] + ',0,0,v)'),
    'the sack of rice and the jar of beans on the shelf (W.estante): on its board at their x (the shelf on the wall over the left counter, ' + (ES[0] - 50) + ' rows from the old)', [['saco', [38, 50], [38, ES[0]]], ['frasco', [50, 50], [50, ES[1]]]]);
  const vn = LINES[lineOf('if(W.ventana&&W.ventana.length){c.save();') - 1].trim();
  mv('*', vn, vn.replace('c.save();c.beginPath();c.rect(176,22,38,36);c.clip();', 'c.save();').replace('176+j*12-KIT.PX+7', '171+j*12-KIT.PX+7').replace('30+(j%2)*3', JSON.stringify(WY) + '[j]+(j%2)*3').replace('tenida(c,"plato",183+j*12,57)', 'tenida(c,"plato",178+j*12,' + JSON.stringify(SILL) + '[j])'),
    'the family at the window (familia27): each one stands outside, close to the glass, the head in the opening, 5 px left of their old x (the third one whole inside the view with 3 px to spare), ' + (WY[0] - 30) + ' to ' + (WY[2] - 30) + ' rows from the old (the window is on the wall over the right counter); the plates on the sill under each one. The clip to the old window rectangle goes: the wall, the window\'s frame and the room are nearer than they are and are drawn again over them (front.ventana), so they are seen only through the opening, in front of its bars as the old',
    [0, 1, 2].map(j => ['ventana', [183 + j * 12, 30 + (j % 2) * 3], [178 + j * 12, WY[j] + (j % 2) * 3]]));
  // people who stand at the right counter: on clear floor in front of it
  const pl = LINES[lineOf('await Promise.all([mueve("abuela",EN.platos[0]+4,LADO[1][1]+4)') - 1].trim(), ya = Gm.clearY(188), yc = Gm.clearY(206);
  mv('platos27', pl, pl.replace('mueve("abuela",EN.platos[0]+4,LADO[1][1]+4)', 'mueve("abuela",EN.platos[0]+4,LADO[1][1]+' + Math.max(4, ya - 176) + ')').replace('mueve("carmen",EN.platos[0]+22,LADO[1][1]+12)', 'mueve("carmen",EN.platos[0]+20,LADO[1][1]+' + Math.max(12, yc - 176) + ')'),
    'platos27: abuela and Carmen set the plates out standing on clear floor in front of the right counter (its front, D from the wall, falls to the right): ' + Math.max(0, ya - 180) + ' and ' + Math.max(0, yc - 188) + ' rows nearer (Carmen 2 px left: her whole sprite 3 px inside the view\'s right edge)', [['abuela', [188, 180], [188, Math.max(180, ya)]], ['carmen', [206, 188], [204, Math.max(188, yc)]]]);
  const tz = LINES[lineOf('for(let i=(I.tazas||0)-1;i>=0;i--)tenida(c,"taza",EN.tazas[0]-3+(i%3)*9,EN.tazas[1]-Math.floor(i/3)*6)') - 1].trim();
  mv('*', tz, tz.replace('EN.tazas[1]-Math.floor(i/3)*6', 'EN.tazas[1]-Math.floor(i/3)*3'), 'the nine clean cups (cuidado): their three rows 3 rows apart (the old 6): on the counter\'s top they stand before the jug, not over it');
  // the left counter's sack and jar while Carmen fills the cups (llenando), the pile of plates and the small plate on the right counter: on the tops
  const ll = LINES[lineOf('if(I.llenando){tenida(c,"saco",EN.saco[0]-9,EN.saco[1]-9)') - 1].trim(), LLS = Gm.rowOn(40, 20).y + 1, LLF = Gm.rowOn(76, 14).y + 1;
  mv('*', ll, ll.replace('tenida(c,"saco",EN.saco[0]-9,EN.saco[1]-9)', 'tenida(c,"saco",EN.saco[0]-9,' + LLS + ')').replace('tenida(c,"frasco",EN.tazon[0]+9,EN.tazon[1]-9)', 'tenida(c,"frasco",EN.tazon[0]+9,' + LLF + ')'),
    'llenando: the sack and the jar Carmen fills the cups from, on the left counter\'s top beside the cups (the old stood them 9 rows behind the cups, here behind the top\'s back edge)');
  const pi = LINES[lineOf('for(let i=0;i<(D.pila||0);i++)tenida(c,"plato",EN.platos[0]+12,EN.platos[1]-9-i*2)') - 1].trim(), PIY = Gm.rowOn(196, 15).y + 1 - 4, PTY = Gm.rowOn(174, 11).y + 1 - 6;
  mv('*', pi, pi.replace('EN.platos[0]+12,EN.platos[1]-9-i*2', 'EN.platos[0]+12,' + PIY + '-i*2').replace('tenida(c,"platito",EN.platos[0]-10,EN.platos[1]-10)', 'tenida(c,"platito",EN.platos[0]-10,' + PTY + ')'),
    'the pile of clean plates and the small plate on the right counter, on its top behind the row of plates (the old stood them 9 and 10 rows behind it, here behind the top\'s back edge)');
  // whoever comes in for a cup stands where their hint frame (box + 12) is 2 px inside the view: the second one beside the first, not in front
  const vi = 'const p=G(o.quien),x=o.lugar==2?207:184,y=o.lugar==2?212:204;';
  mv('viene', vi, 'const p=G(o.quien),x=o.lugar==2?192:169,y=o.lugar==2?202:202;', 'viene (cuidado): whoever comes in for a cup stands 15 px left and 2 rows further back, a second one beside the first (23 px right) rather than in front of it: at the old places their hint frames (box + 12) left the view at the bottom and the right (the old\'s too), and the jug\'s hint hand lay on the face of the one who stood under it. What is relative to them moves with them: where Luis hands them the cup (luisda: x - 20, y + 2) and where the frog serves the first one (ranallena: x - 22, y + 8; his hops there and back are the old ones)', [...['papa', 'mama', 'abuelo', 'carmen'].flatMap(id => [[id, [184, 204], [169, 202]], [id, [207, 212], [192, 202]]]), ['luis', [164, 206], [149, 204]], ['luis', [187, 214], [172, 204]], ['cq', [146, 185], [131, 183]], ['cq', [161, 165], [168, 165]]]);
  const fi = 'mueve("carmen",204,202)';
  mv('final27', fi, 'mueve("carmen",202,202)', 'final27: Carmen with her plate held up 2 px left: wholly inside the view with 3 px to spare (the old was 1 px inside)', [['carmen', [204, 202], [202, 202]]]);
  for (const L of linesOf('LADO[1][0]-11')) { const src = LINES[L - 1].trim(); mv('*', src, src.split('LADO[1][0]-11,LADO[1][1]').join('LADO[1][0]-21,LADO[1][1]-6').split('x:LADO[1][0]-11,y:LADO[1][1]').join('x:LADO[1][0]-21,y:LADO[1][1]-6'), 'cuidado: Luis\'s place at the right (inicio29, and where he goes back to: luisda, luisbebe, luiscome) 10 px left and 6 rows back, clear of whoever comes in for a cup and of the jug\'s hint frame', [['luis', [160, 176], [150, 170]]]); }
  mv('*', 'fresh:()=>({respEn:[125,46],', 'fresh:()=>({respEn:[146,20],', 'where the answer cards stand (W.respEn, every story of the scene): 21 px right and 26 rows up, over the hood and the cut top of the wall, clear of the pots, the pan and the steam and smoke over them, the tray and the rounds card');
  return { moves: M, NUM };
}
// the story files' own places that move: the remap (cual-estufa's pictures)
function designStoryMoves(E, F, NUM) {
  const Gm = geometry(E, F), out = [];
  const mama = Gm.clearY(176), ab = Gm.clearY(156);
  out.push({ old: [176, 152], new: [176, Math.max(152, mama)], who: 'mama', why: 'hace (both pictures): mamá stood at the old counter\'s foot; here on clear floor in front of the right counter, at her x' });
  out.push({ old: [156, 164], new: [156, Math.max(164, ab)], who: 'abuela', why: 'cuidado.si: abuela on clear floor in front of the stove and the right counter, at her x' });
  out.push({ old: [126, 127], new: [126, Gm.rowOn(126, 12).y + 1], who: 'cosa', why: 'caliente, frío: the cup on the stove\'s top between the burners, at its x (the old stood it on the stove\'s front)' });
  out.push({ old: [150, 113], new: [150, 113 + NUM.FDY[1]], who: 'cosa', why: 'hace.si: the ladle in the pot at burner 1 moves with that pot (FYS)' });
  out.push({ old: [195, 123], new: [195, Gm.rowOn(195, 45).y + 1], who: 'plata', why: 'pollo (both pictures): the plate on the right counter\'s top, at its x' });
  out.push({ kind: 'rect', old: [106, 104, 90, 117], new: [106, 104 + NUM.FDY[0], 90, 117], who: 'olor', why: 'huele.si: the smell rises from the pan at burner 0 (moved with it, FYS) to papá\'s nose (unchanged)' });
  return out;
}

/* ---------- the sheet ---------- */
const OLDBOX = { estufa: [86, 104, 80, 54], cocina: [22, 16, 196, 198] };
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];
// the old picture's places (estufa.js, read as text)
const OLDC = (() => { const m = ESTUFA_JS.match(/const PISO=(\d+),ENC=(\d+),EST=\[(\d+),(\d+),(\d+),(\d+)\],FX=\[(\d+),(\d+)\],FY=(\d+),IZQ=\[(\d+),(\d+)\],DER=\[(\d+),(\d+)\],BANCO=\[(\d+),(\d+)\]/); if (!m) throw new Error('estufa.js changed: PISO');
  const n = m.slice(1).map(Number), L = ESTUFA_JS.match(/const LADO=\[\[(\d+),(\d+)\],\[(\d+),(\d+)\]\],AYUDA=\[(\d+),(\d+)\],PUERTA=\[(\d+),(\d+)\]/);
  return { PISO: n[0], ENC: n[1], EST: n.slice(2, 6), FX: n.slice(6, 8), FY: n[8], BANCO: [n[13], n[14]], LADO: [[+L[1], +L[2]], [+L[3], +L[4]]], AYUDA: [+L[5], +L[6]], PUERTA: [+L[7], +L[8]], LUGAR: { inicio: [n[13] - 16, n[14] - 27, 1], centro: [n[13] - 16, n[14] - 27, 1] } }; })();
// every place the frog stands at (the old code's): q = (x - 16, y - 27) of ranaA(x, y)
const FROG_NEW = { servir: [131, 183], jarra: [168, 165] };   // the frog's places that move: where he serves whoever came in for a cup (viene, moved)
const FROG_PLACES = { banco: [OLDC.BANCO[0] - 16, OLDC.BANCO[1] - 27], saco: [45 + 6 - 16, 186 - 27], tazon: [67 + 6 - 16, 186 - 27], fuego0: [107 - 16, 190 - 27], fuego1: [145 - 16, 190 - 27], olla1: [145 - 16, 192 - 27], jarra: [181 - 4 - 16, 192 - 27], servir: [184 - 22 - 16, 204 + 8 - 27] };

function make(G, runs) {
  const E = engine(G), F = G.F, Gm = geometry(E, F);
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };
  const placeW = p => { const s = surfaceW(E, F, p[0], p[1] - 1); return { on: s.on, world: W4(s.w) }; }, frogW = q => placeW([q[0] + 16, q[1] + 26]);
  const { moves, NUM } = designMoves(E, F);
  const MOVES = moves.map(m => Object.assign({ line: lineOf(m.src) }, m, { lines: linesOf(m.src) }));
  for (const m of MOVES) for (const q of m.pts || []) q.push(placeW(q[2]).world);
  const STORY = designStoryMoves(E, F, NUM);
  const DROPPED = [{ src: 'c.drawImage(spr("estufa",fondo),0,0);', to: '', why: 'the background (fondo): the set, for setKey(W)' }, { src: 'if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});', to: '', why: 'the stool (W.banco): the set\'s (setKey banco); whoever stands behind it has it drawn again over them (front.banco)' }].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* spots: the frog's places and the named places of the old code; each keeps its screen place (the floor rule) but those moves name */
  const SPOTS = {};
  const spot = (k, at, what, kind = 'place', nw) => { const n = nw || at, w = kind === 'cq' ? frogW(n) : placeW(n);
    SPOTS[k] = Object.assign({ world: w.world, on: w.on, old: at.slice(0, 2), new: n.slice(0, 2) }, kind === 'cq' ? { scale: 1 } : {}, nw ? { moved: true } : {}, { what }); };
  for (const [k, v] of Object.entries(OLDC.LUGAR)) spot('frog.' + k, v, 'LUGAR.' + k + ': the frog on the stool (his feet on its top)', 'cq');
  for (const [k, v] of Object.entries(FROG_PLACES)) if (k !== 'banco') spot('frog.' + k, v, 'ranaA: the frog on the floor ' + { saco: 'before the cups of rice (echa)', tazon: 'before the cups of beans (echa)', fuego0: 'before burner 0 (echa)', fuego1: 'before burner 1 (echa)', olla1: 'before the chocolate pot (ranallena)', jarra: 'before the jug (ranallena: EN.jarra[0] - 4, moved with it)', servir: 'before whoever came in for a cup (ranallena: x - 22, y + 8; moved with them)' }[k], 'cq', FROG_NEW[k]);
  spot('lado.0', OLDC.LADO[0], 'LADO[0]: the cook at the left of the stove'); spot('lado.1', OLDC.LADO[1], 'LADO[1]: the cook at the right of the stove');
  spot('ayuda', OLDC.AYUDA, 'AYUDA: the helper at the left counter'); spot('puerta', OLDC.PUERTA, 'PUERTA: whoever comes in (acts.prueba only)');
  spot('banco', [OLDC.BANCO[0], OLDC.BANCO[1]], 'BANCO: the stool\'s top under the frog\'s feet (the set\'s stool, points.banco)');
  spot('cubo', [34, 208], 'CUBO: the waste bucket on the floor');
  OLDC.FX.forEach((x, i) => spot('fuego.' + i, [x, OLDC.FY + 1], 'FX[' + i + '], FY: where burner ' + i + '\'s pot stands (moved: FYS)', 'place', [x, NUM.FYS[i] + 1]));
  for (const m of MOVES) for (const q of m.pts || []) { const k = q[0] + '.' + q[1].join('_'); if (!SPOTS[k]) SPOTS[k] = { world: q[3], on: placeW(q[2]).on, old: q[1], new: q[2], moved: true, what: m.why.split(':')[0] }; }

  /* the named points of the set */
  const P = (x, y, z = 0) => { const p = E.project(x, y, z); return [r2(p.sx), r2(p.sy)]; };
  const PTS = {
    run: { world: [F.AL0, 0, 0, F.AR1, F.D, F.CZ], left: [F.AL0, F.AS0], stove: [F.AS0, F.AS1], right: [F.AS1, F.AR1], what: 'the run along the back wall (x from ' + F.AL0 + ' to ' + F.AR1 + ', y from 0 to ' + F.D + ', its tops at z ' + F.CZ + '): the left counter (izq), the stove, the right counter (der); its front edge at column sx on the screen falls half a row a pixel to the right', frontRow: [22, 80, 126, 180, 218].map(x => [x, r2(Gm.topY(x, F.D))]), backRow: [22, 80, 126, 180, 218].map(x => [x, r2(Gm.topY(x, 0))]) },
    burners: F.burners.map((b, i) => ({ world: W4(b.world), screen: b.screen.map(r2), pot: [OLDC.FX[i], NUM.FYS[i] + 1], old: [OLDC.FX[i], OLDC.FY + 1] })), burnersWhat: 'each burner\'s middle on the stove\'s top; pot: where its pot\'s sprite stands (FX, FYS + 1: the bottom of its sprite), old: the old (FX, FY + 1)',
    banco: { world: W4([F.STOOL_C[0], F.STOOL_C[1], F.STOOL.h]), top: [F.STOOL.sx, F.STOOL.sy], half: F.STOOL.hw, what: 'the stool: its square top (half width ' + F.STOOL.hw + ') at z ' + F.STOOL.h + ', its middle under the frog\'s feet (the old BANCO); four legs, a rail' },
    ventana: { world: [F.WIN.a0, 0, F.WIN.z0, F.WIN.a1, 0, F.WIN.z1], hole: F.holePoly, what: 'the window on the back wall over the right counter (the kit\'s: frame with depth, the cross bars, the sill), the bush and the sky outside; hole: its opening on the screen (four corners)' },
    estante: { world: [F.SHELF.a0, 0, F.SHELF.z, F.SHELF.a1, F.SHELF.d, F.SHELF.z], jars: F.JARS.map(j => j[0]), what: 'the shelf on the wall over the left counter (the kit\'s), its two jars (green, blue; the old background\'s)' },
    campana: { world: [F.AS0, 0, F.K.HZ0, F.AS1, F.K.HD, F.K.HZ1], what: 'the kit\'s hood over the stove, as wide as it' },
    salpicadero: { world: [F.AS0, 0, F.CZ, F.AS1, .03, F.K.HZ0], colour: F.SPLASH, what: 'the steel splashback behind the stove, from its top to the hood (estufa-set.html): what the steam and smoke rise against' },
    corazon: { screen: [124, 24], what: 'heartAt: unchanged' },
  };

  /* things: the 17 touch keys */
  const sprite = why => ({ sprite: true, why });
  const things = {
    luis: sprite('a person (today\'s sprite, drawn 1:1). caja(id) (estufa.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged'),
    carmen: sprite('as luis'), abuelo: sprite('as luis'), mama: sprite('as luis'), papa: sprite('as luis'), abuela: sprite('as luis'),
    olla0: sprite('the pot at burner 0 (fuegos[0], drawn by the sprite layer): [FX[0] - 17, FYi(0) - 24, 34, 28] (moves: FYS)'), olla1: sprite('the pot at burner 1: [FX[1] - 17, FYi(1) - 24, 34, 28] (moves)'),
    saco: sprite('the cups of rice on the left counter (W.izq.saco): [EN.saco x - 12, y - 16, 24, 18] (moves: EN)'), tazon: sprite('the cups of beans (W.izq.tazon): [EN.tazon x - 12, y - 16, 24, 18] (moves: EN)'),
    pzpollo: sprite('the drumstick on abuela\'s plate (W.plata): [plata.x - 24, plata.y - 22, 24, 24]: unchanged'), pzhuevo: sprite('the egg on her plate: [plata.x, plata.y - 22, 24, 24]: unchanged'),
    sarten: sprite('the pan at burner 0: [FX[0] - 17, FYi(0) - 14, 36, 16] (moves)'), bandeja: sprite('the tray on the left counter: [28, BJ - 15, 46, 16] (moves)'), jarra: sprite('the jug on the right counter: [EN.jarra x - 11, y - 22, 20, 24] (moves: EN)'),
  };
  { const sp = (G.parts.banco1.estufa || []), pxs = sp.map(i => [i % 240, Math.floor(i / 240)]), x0 = Math.min(...pxs.map(p => p[0])), y0 = Math.min(...pxs.map(p => p[1])), x1 = Math.max(...pxs.map(p => p[0])) + 1, y1 = Math.max(...pxs.map(p => p[1])) + 1;
    const wb = [F.AS0, 0, 0, F.AS1, F.D, F.CZ];
    things.estufa = { set: true, world: W4(wb), box: box(wb), screen: [x0, y0, x1, y1], what: 'the stove: its top with the two burners, its front with the knobs and the oven door', old: { box: OLDBOX.estufa } };
    things.estufa.hand = [R((F.burners[0].screen[0] + F.burners[1].screen[0]) / 2), R(Gm.topY((F.burners[0].screen[0] + F.burners[1].screen[0]) / 2, F.D)) + 14]; things.estufa.handWhy = 'on the stove\'s front, under its top between the burners';
    things.cocina = { set: true, ground: true, box: [0, 0, 240, 216], what: 'the kitchen: the floor, the walls, the counters, the shelf, the hood, the splashback, the window, the stool; last in the hit order', old: { box: OLDBOX.cocina } };
    const b = things.cocina.box, hx0 = Math.max(b[0], VIEW_X0 + 14), hy0 = Math.max(b[1], 14), hx1 = Math.min(b[0] + b[2], VIEW_X0 + 196 - 14), hy1 = Math.min(b[1] + b[3], 216 - 14);
    things.cocina.hintBox = [hx0, hy0, hx1 - hx0, hy1 - hy0]; things.cocina.hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches';
    things.cocina.hand = [60, 180]; things.cocina.handWhy = 'on the open floor at the left'; }

  const views = { wide: { zoom: 1, x0: VIEW_X0, world: W4(E.atZ(120, 150, 0)), region: null, old: [22, 0, 196, 216], what: 'the kitchen\'s run: the left counter, the stove under its hood, the right counter under the window, the stool in front, the floor' } };

  /* the review and level pictures: each centred on its subject where the sheet puts it */
  const shiftOf2 = (cx, cy, dy) => [cx, cy + dy];
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1 ? [Math.max(0, Math.min(44, R(cx - 98))), Math.max(0, Math.min(112, R(cy - 52))), 196, 104] : [Math.max(0, Math.min(142, R(cx - 49))), Math.max(0, Math.min(164, R(cy - 26))), 98, 52];
    const w = placeW([cx, cy]); return { world: w.world, screen: [cx, cy], zoom, crop, what }; };
  const pot0 = [107, NUM.FYS[0] - 12], pot1 = [145, NUM.FYS[1] - 12], cup = STORY.find(s => s.old.join() === '126,127').new, plat = STORY.find(s => s.old.join() === '195,123').new, mama = STORY.find(s => s.old.join() === '176,152').new;
  const PICS = {
    'arroz.si': pic(pot0[0], pot0[1] + 2, 2, 'the pot at burner 0 full of rice'), 'arroz.no': pic(pot0[0], pot0[1] + 2, 2, 'the pot full of beans'),
    'habichuelas.si': pic(97, 172, 2, 'Luis holding up a bowl of beans'), 'habichuelas.no': pic(97, 172, 2, 'Luis holding up a bowl of rice'),
    'olla.si': pic(130, 172, 2, 'abuela holding up a pot'), 'olla.no': pic(130, 172, 2, 'abuela holding up a pan'),
    'hace.si': pic(160, mama[1] - 47, 1, 'mamá at the stove, the ladle in the pot'), 'hace.no': pic(160, mama[1] - 47, 1, 'mamá eating from a plate'),
    'pollo.si': pic(plat[0] - 2, plat[1] - 12, 2, 'a drumstick on a plate'), 'pollo.no': pic(plat[0] - 2, plat[1] - 12, 2, 'a fried egg on a plate'),
    'huevo.si': pic(pot0[0] - 6, pot0[1] + 8, 2, 'an egg frying in the pan'), 'huevo.no': pic(97, 172, 2, 'Luis holding up the shaker'),
    'sal.si': pic(146, 172, 2, 'salt falling from the shaker over the frog\'s plate'), 'sal.no': pic(146, 172, 2, 'pepper from the mill'),
    'huele.si': pic(104, 118, 1, 'papá smelling the pan'), 'huele.no': pic(104, 118, 1, 'papá eating'),
    'caliente.si': pic(cup[0], cup[1] - 8, 2, 'a hot cup of chocolate, steaming'), 'caliente.no': pic(cup[0], cup[1] - 8, 2, 'a cold glass of chocolate'),
    'frio.si': pic(cup[0], cup[1] - 8, 2, 'a glass of cold water'), 'frio.no': pic(pot1[0], pot1[1] + 2, 2, 'the pot of water on the fire'),
    'cuidado.si': pic(124, 122, 1, 'Luis and abuela, both warning'), 'cuidado.no': pic(124, 130, 1, 'Luis and abuela offering a plate'),
    'ya.si': pic(136, 172, 2, 'abuela holding up the plate of fritters'), 'ya.no': pic(136, 172, 2, 'abuela holding up a bowl'),
  };
  const LEVEL = PAIRS.level.flatMap(L => L.pictures.map((p, i) => p.scene === 'estufa' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* remap: every distinct position of positions.json */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); return e; }
    if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; return e; }
    if (p.kind === 'x') { e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' }; return e; }
    if (p.kind === 'rect') { const mv = STORY.find(m => m.kind === 'rect' && m.old.join() === e.old.join()); e.to = { olor: true }; if (mv) { e.new = mv.new; e.moved = true; e.why = mv.why; } e.what = 'the smell\'s curve (W.olor: from x0, y0 to x1, y1)'; return e; }
    if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
    const ats = p.uses.map(u => u.at), mv = STORY.find(m => !m.kind && m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y], isFrog = ats.every(a => /\.cq$/.test(a)), w = isFrog ? frogW(at) : placeW(at);
    e.to = { [w.on]: w.world }; e.new = at.slice(); if (mv) { e.moved = true; e.why = mv.why; }
    e.what = (isFrog ? 'the frog\'s place q: the surface under (x + 16, y + 26)' : 'a place (x, y): the surface under (x, y - 1)') + ' (' + w.on + ')' + (mv ? '; moved (why)' : '; the same screen place');
    return e; });

  // hop counts: every pair of the frog's places, old against new (kit.js ir: round(d / 30); estufa.js ranaA: round(d / 40), 1 to 3)
  const fp = Object.fromEntries(Object.entries(FROG_PLACES).map(([k, v]) => [k, { q: FROG_NEW[k] || v, old: v }])), names = Object.keys(fp), hopsAll = [];
  const hop = d => d < 3 ? 0 : Math.max(1, Math.min(3, R(d / 40)));
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) { const a = fp[names[i]], b = fp[names[j]], dO = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dN = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]); hopsAll.push({ a: names[i], b: names[j], old: hop(dO), new: hop(dN) }); }

  const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSidesOf()) reached.add(keyOf(pairW(ps, null)));
  return {
    scene: 'estufa',
    made: 'node docs/proyecto/pixel/estufa-sheet-make.js, from estufa-set.html (window.ESTUFA_SET) and coqui/ref/escenas/estufa/. Order 38a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the kitchen is built round the old picture: a place keeps its screen place, its world point the surface under it (estufa-set.html surfaceAt): the stool\'s top, a top of the run (z ' + F.CZ + '), the shelf, or the floor (z 0). A frog place q: under (q.x + 16, q.y + 26); a person\'s or a thing\'s place (x, y): under (x, y - 1). So every position of estufa.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each (spots, remap, code)',
      relative: 'what the old code draws or moves relative to a person, the frog, a pot, a plate or a counter\'s place (what is carried, the steam, the flames, the helpings, the pieces on a plate, the bubbles, the clouds) keeps its offsets',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side]: zoom 2 = the 98 x 52 crop shown at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: {
      what: 'La cocina\'s room (cocina-kit.js) cut open as La sala\'s, on the world\'s axes at the engine\'s 30 degrees: one run along the back wall, the left counter from the corner, the stove, the right counter running off the picture at the right; the shelf with its jars over the left counter, the hood and a steel splashback over the stove, the window with its bush over the right counter; the stool on the floor in front of the stove; the checker floor; dark above the cut walls',
      why: 'the brief: the stove and the two counters in one run along one axis against a far wall. A run along x falls half a row a pixel to the right; it is placed as low as the right cook (LADO[1], 171, 176) lets it (whoever stands at the run is on clear floor in front of it, its front ' + F.D + ' from the wall), so the stove\'s pots and the right counter\'s things move least and the left counter\'s most (moves). Its tops are ' + F.D + ' deep (the kit\'s counters are ' + .9 + ') so that the tray, 46 px wide, and the plates stand wholly on them. The stove is as wide as two 34 px pots side by side need, in the kit\'s look',
      numbers: NUM,
    },
    behind: { what: 'nothing: the outside (sky, bush) is baked into the window', items: [] },
    setKey: { params: { banco: 'W.banco ? 1 : 0 (the stool)' }, key: '"banco" + (W.banco ? 1 : 0)', baked: STATES.filter(k => reached.has(k)).map(k => ({ key: k, query: '?' + queryOf(k) })), notReached: STATES.filter(k => !reached.has(k)),
      bakedWhy: 'order 06 found 164 states made by fourteen keys. One is the set\'s: banco (the stool; the review pictures leave it out). The other thirteen are things the sprite layer draws, as the old: basura and cubo (the waste bucket and what lies in it), der and izq (what stands on the counters), encima (on the frog\'s head), estante (the sack and the jar on the shelf), fuegos (the pots and the pan, their contents, flames, steam and smoke), mat (the frog\'s plate), olor (the smell), plata (abuela\'s plate), repisa (the plates put by), salero (the shaker), ventanacome (the plates on the sill). So setKey reads banco only',
      spriteKeys: { basura: 'draw(): what lies in the bucket', cubo: 'draw(): the bucket (sorted list)', der: 'draw(): the right counter\'s things (and the left counter\'s board and fritter plate)', izq: 'draw(): the left counter\'s things', encima: 'rana()', estante: 'draw(): on the shelf (moves)', fuegos: 'fuego()', mat: 'draw()', olor: 'draw()', plata: 'draw()', repisa: 'draw() (moves: REP)', salero: 'draw() (moves: SALY)', ventanacome: 'draw(): on the sill (moves)' } },
    things,
    spots: SPOTS,
    lugar: Object.fromEntries(Object.entries(OLDC.LUGAR).map(([k, v]) => [k, { spot: 'frog.' + k, q: v.slice(0, 2), scale: v[2], old: v.slice(0, 2) }])),
    hops: hopsAll.filter(h => h.old !== h.new), hopsAll, hopsWhat: 'each pair of the frog\'s places (FROG_PLACES: the stool and the floor places of ranaA), old against new (where he serves whoever came in for a cup moved with them): every count is the old',
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: { ventana: { old: 'estufa.js:' + lineOf('c.rect(176,22,38,36);c.clip();') + ' clip rect [176, 22, 38, 36]', thing: 'cocina', face: 'the window\'s opening in the back wall (points.ventana.hole)', how: 'not clipped: the family stands outside, close to the glass (their plane y = -0.05, inside the wall\'s thickness, in front of the bars), and the set\'s own pixels nearer than them (the wall, the frame, the sill, the counter, the room) are drawn again over them (front.parts.ventana); so they are seen only through the opening, over its bars as the old' } },
    smoothing: 'estufa.js turns smoothing off (respIcon) and never on',
    front: {
      how: 'the stool is now a set thing someone can stand behind; the window\'s people stand outside. At its entry in the sorted list (sortY 9999: after everyone) the stool\'s pixels (part banco, banco.patas) are drawn again over each item drawn before it that owns them (each item says what it is), only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the surface point under the item (rules.floor). After the window\'s people (drawn first of all), the set\'s pixels of front.parts.ventana nearer than their plane are drawn again over them. "Behind the stool" is that depth test, not a row',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      parts: { banco: { parts: FRONT.banco, sortY: 9999, insert: 'before the sort: L.push({y: 9999, front: "banco"})' }, ventana: { parts: FRONT.ventana, after: 'the window\'s people (draw: the line of W.ventana)', plane: 'world y = -0.05 under each one\'s column' } },
      tags: [['L.push({y:p.y,d:()=>gente(c,id,a)})', 'L.push({y:p.y,id,d:()=>gente(c,id,a)})'], ['if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)})', 'if(q.vis)L.push({y:q.y+27,id:"coqui",d:()=>rana(c,q,a)})']],
      tagsWhat: 'each item of the sorted list says what it is (the front masks read it); nothing else changes',
    },
    shadows: {
      rule: 'the kitchen\'s one light (cocina-kit.js): from the upper left, shadows to screen right, low and joined to the thing. Whoever stands on the floor casts a small shadow from the floor point under their feet; what stands on a top, the frog on the stool and the window\'s people cast none (a shadow falls on the floor only)',
      coqui: { radius: .45, at: 'the floor under (b.x + b.w / 2, q.y + 26)', when: 'W.cq.vis and al > .5 and his place is on the floor (not on the stool)', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { abuela: .35, nino: .3, other: .35 }, at: 'the floor under (x, y - 1)', when: 'visible (vis !== 0, al > .5), on the floor', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r)' },
      dropped: 'none of the old code\'s own: estufa.js draws no shadow',
    },
    dropped: DROPPED,
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines.length > 1 ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.pts && m.pts.length ? { places: m.pts.map(q => ({ who: q[0], old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    helps: { what: 'none yet', lines: [] },
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as estufa.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: { what: 'where a bubble goes (estufa.js draw: bub2 over the head for a person, over the frog): the first of these places whose bubble is wholly inside the view, clear of the corner card and of every face; if none is, the first (the old)', top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)', places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1', faces: 'a person\'s face: [x - 6, top + 6, 12, 10], top = y - height + 1 + dy; abuela\'s: [x + f * abuelaHead - 6, y - 50 + 6, 12, 10], f = 1 facing right (her pose offer or bless turns her), -1 left; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]', heights: G.M.heights, abuelaHead: G.M.abuelaHead, board: BOARD },
    code: codeEntries(MOVES, DROPPED),
    checks: { notes: [] },
  };
}

/* ---------- code: every line of estufa.js that holds a number, and what each number is (El banco's way) ----------
   The maker reads estufa.js itself (not order 06's inventory): it finds every numeric literal outside comments and strings, sorts each by what it
   is from where it stands (a place on the picture; an offset from someone; a time, a sound, a count; a draw order; a sprite's or a sign's own
   drawing), and the sheet names, line by line, what becomes of its places (moved, the floor rule, a set thing, dropped). check() fails if a line
   with a place has no entry, or an entry misses one of its place numbers */
const REGIONS = (() => {
  const at = s => lineOf(s), out = [];
  const r = (a, b, kind, why) => out.push({ a, b, kind, why });
  r(at('function fondo(){'), at('const COSA={') - 1, 'dropped', 'the background (fondo): the set, dropped');
  r(at('const COSA={'), at('function tenida(c,k,x,y,ang,esc,v)'), 'drawing', 'a sprite\'s own drawing (the pots, the pan, the cups, the plates, the food, the stool, the bucket...) and tenida: relative to where it is drawn, unchanged');
  r(at('function vapor(c,x,y,negro)'), at('function vapor(c,x,y,negro)'), 'drawing', 'the steam and smoke: relative to the point it is drawn at, unchanged');
  r(at('function pieza(c,o,x,y,esc)'), at('const persona=id=>'), 'drawing', 'pieza, alto and caja: sizes and offsets relative to a piece or a person, unchanged');
  r(at('function gente(c,id,a){'), at('function bub2(c,k,tx,ty,a)'), 'drawing', 'a person, the thought clouds, the frog, what each holds: drawn relative to them, unchanged');
  r(at('function talkAt(k,W)'), at('const marca=m=>'), 'drawing', 'talkAt\'s offset over the head, the answer icons, the rounds card in the corner (hud): relative or screen space, unchanged (talk.board)');
  r(at('async function stake('), at('const estado=W=>'), 'other', 'stake, poke and estado: no place');
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
  if (/\b(dy|al|s|h|fase|mano|vis|paso|dir|n|i|e|dx|llama|vapor|humo|sal|pollo|huevo|masa|pila|tazas|saco|tazon|cubo|banco|estante|repisa|ventanacome|platito|fuente|marcas|bebe|al|s)\s*[:=]\s*-?$/.test(before) || /\.dy\s*=\s*-?$|\.dy\s*[+-]=\s*$/.test(before)) return 'state';
  if (/Math\.PI\s*[*\/]\s*$|\*\s*$|Math\.sin\([^()]*$|Math\.cos\([^()]*$|Math\.hypot\([^()]*$|\/\s*$/.test(before) || /^\s*\*/.test(after)) return 'scale';
  if (/\b[xy]\s*:\s*-?$|\b[xy]\s*:\s*\w[\w.\[\]]*\s*[+-]\s*$|\.[xy]\s*=\s*-?$|\.[xy]\s*[+-]=\s*$/.test(before)) return /[+-]\s*$/.test(before) && !/:\s*-$|=\s*-$/.test(before) ? 'offset' : 'place';
  if (/(mueve|ranaA|vuela|hopTo|tenida|cae28|nube2|nube)\([^()]*$/.test(before)) return /[+-]\s*$/.test(before) && !/[(,]\s*-$/.test(before) ? 'offset' : 'place';
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
    const e = { line: L, numbers: kinds };
    if (dr.length && !mv.length) { e.to = { dropped: true }; e.note = dr.map(d => d.why).join('; '); }
    else if (mv.length) { e.to = { moves: mv.map(m => m.src.slice(0, 60)) }; e.note = 'moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; ') + (kinds.place ? '; every other place here keeps its screen place (the floor rule)' : ''); }
    else if (reg) { e.to = reg.kind === 'dropped' ? { dropped: true } : 'unchanged'; e.note = reg.why; }
    else if (kinds.place) { e.to = { floor: true }; e.note = 'places on the picture: each keeps its screen place, its world point the surface under it (rules.floor)'; }
    else { e.to = 'unchanged'; e.note = 'no place: ' + Object.keys(kinds).join(', '); }
    C.push(e);
  }
  const set = (L, to, note) => { const e = C.find(q => q.line === L); if (!e) throw new Error('code: no numbers on line ' + L); e.to = to; e.note = note; };
  set(lineOf('const PISO=150,ENC=112,EST='), { points: ['run', 'burners', 'banco'], spots: ['fuego.0', 'fuego.1', 'banco'], moves: ['FYS (on line ' + lineOf('const REP=[190,ENC+1]') + ')'] }, 'PISO and ENC (the old floor\'s and counters\' first rows), EST, IZQ, DER (the old stove and counters): the set\'s run (points.run); FX: unchanged (the pots keep their x); FY: each burner\'s own row (FYS, moves); BANCO: the stool\'s top (points.banco, spots.banco)');
  set(lineOf('const LADO=[[82,174]'), { spots: ['lado.0', 'lado.1', 'ayuda', 'puerta'] }, 'where the cooks and the helper stand: the floor rule, unchanged (on clear floor in front of the run)');
  set(lineOf('const alto=id=>'), 'unchanged', 'the sprites\' heights (alto), not places');
  set(lineOf('{id:"saco",si:'), { things: ['saco', 'tazon'] }, 'the cups\' boxes relative to EN (moved: EN)');
  set(lineOf('{id:"pzpollo",si:'), { things: ['pzpollo', 'pzhuevo'] }, 'the pieces\' boxes relative to abuela\'s plate: unchanged');
  set(lineOf('{id:"jarra",si:'), { things: ['jarra'] }, 'the jug\'s box relative to EN.jarra (moved: EN)');
  set(lineOf('{id:"estufa",box:'), { things: ['estufa', 'cocina'] }, 'the stove\'s box and the room\'s: the set things (things.estufa, things.cocina, its hint box)');
  set(lineOf('const cx=()=>W.cq.x+16'), 'unchanged', 'the frog\'s middle and feet relative to q: unchanged');
  set(lineOf('async function ranaA('), 'unchanged', 'ranaA: q relative to the point; the hop count by the distance (40 px a hop): unchanged');
  set(lineOf('KIT.escena({id:"estufa"'), { view: 'wide', point: 'corazon', spots: ['frog.inicio', 'frog.centro'] }, 'the view (views.wide), the heart (points.corazon) and LUGAR (the frog on the stool): unchanged');
  set(lineOf('fresh:()=>({respEn:'), { moves: ['fresh:()=>({respEn:[125,46],'] }, 'respEn: where the answer cards stand, moved (moves); the frog\'s first place (the stool): unchanged');
  for (let L = lineOf('async prueba(o){'); L <= lineOf('async prueba(o){') + 4; L++) { const e = C.find(q => q.line === L); if (e) { e.to = 'unchanged'; e.note = 'acts.prueba (a test act no story calls): unchanged'; } }
  C.push({ line: 'juego.js:16', to: 'unchanged', note: 'fresh(): not used here: estufa\'s fresh() puts the frog at LUGAR.inicio' });
  C.push({ line: 'cual.js:21', to: 'unchanged', note: 'panelW(): cq x 123 y 150 s .86: a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)' });
  return C;
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([R(hp[0]) - 12 + i * 3, R(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };
const handBox = hp => [R(hp[0]) - 12, R(hp[1]), 36, HAND.length * 3 + 9];
const frogBox = q => { const w = R(30 * q.s) + 2, h = R(25 * q.s) + 2; return { x: R(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const lum = c => { const f = u => { u /= 255; return u <= .03928 ? u / 12.92 : ((u + .055) / 1.055) ** 2.4; }; return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2]); };
const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); };
const rowsAt = (rows, dx, dy) => rows.map(r => [r[0] + dy, r[1] + dx, r[2] + dx]);
const rowsBox = rs => { if (!rs.length) return null; const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
const HEX = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), MASK = G.MASK, NEW = G.TICKS, x0 = VIEW_X0;
  const TAGS = {}; for (const k of STATES) { const m = new Array(240 * 216).fill(null); for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) m[i] = p; TAGS[k] = m; }
  const rgbAt = (k, i) => [G.rgb[k][i * 3], G.rgb[k][i * 3 + 1], G.rgb[k][i * 3 + 2]];
  const pairSides = pairSidesOf();

  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-estufa.json'), 'utf8'));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of PAIRS.level) for (const p of L.pictures) if (p.scene === 'estufa') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  /* code: estufa.js read here, line by line: every line with a number has an entry; a line with a place has a fate; every move's line too */
  { const byL = new Map(sh.code.map(e => [String(e.line), e])); let nPlace = 0;
    for (let L = 1; L <= LINES.length; L++) { const ns = numsOf(stripLine(LINES[L - 1])); if (!ns.length) continue; const e = byL.get(String(L)); if (!e) { P.push('code: estufa.js line ' + L + ' has numbers and no entry'); continue; }
      if (e.numbers.place) { nPlace++; if (!e.to || (typeof e.to === 'object' && !Object.keys(e.to).length)) P.push('code: line ' + L + ' has places and no fate'); } }
    for (const m of sh.moves) for (const L of m.lines || [m.line]) { if (!LINES[L - 1].includes(m.src)) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); const e = byL.get(String(L)); if (!e || !e.to || !e.to.moves) P.push('moves: line ' + L + ' is not named as moved in code'); }
    for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
    for (const [a] of sh.front.tags.concat(sh.helps.lines)) if (!ESTUFA_JS.includes(a)) P.push('estufa.js does not hold ' + a);
    notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + ') and ' + Object.keys(sh.spots).filter(k => k.startsWith('frog.')).length + ' frog places in all, ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-estufa (' + pairSides.length + ' pictures), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + sh.code.length + ' lines of estufa.js with numbers named in code (' + nPlace + ' of them with places, each with its fate), ' + sh.moves.length + ' moves, ' + sh.setKey.baked.length + ' baked states (the old ' + inv.states.count + ')'); }

  /* hops: the frog's walks. No frog place moves, so at every step's end of the port's play he is where the recorded run had him, walking the old walks */
  { let n = 0, bad = 0; runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach(ln => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw || !ln.W.cq || !tw.W.cq) return; n++;
      if (!Object.values(FROG_PLACES).some(v => v[0] === ln.W.cq.x && v[1] === ln.W.cq.y) && !sh.moves.flatMap(m => m.places || []).some(q => q.who === 'cq' && q.old[0] === ln.W.cq.x && q.old[1] === ln.W.cq.y)) return;
      const mq = sh.moves.flatMap(m => m.places || []).find(q => q.who === 'cq' && q.old[0] === ln.W.cq.x && q.old[1] === ln.W.cq.y), ox = mq ? mq.new[0] : ln.W.cq.x, oy = mq ? mq.new[1] : ln.W.cq.y;
      if (ox !== tw.W.cq.x || oy !== tw.W.cq.y) { bad++; if (bad < 10) P.push('hops: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': the frog at ' + [tw.W.cq.x, tw.W.cq.y] + ', the recorded run ' + [ln.W.cq.x, ln.W.cq.y]); } }); });
    { const at = {}; for (const [k, v] of Object.entries(FROG_PLACES)) at[v.join(',')] = k; const walked = new Set(); for (const r of runs) { let prev = null; for (const L of r.lines) { const q = L.W.cq; if (!q || !q.vis) continue; const k = at[q.x + ',' + q.y]; if (!k) continue; if (prev && prev !== k) walked.add([prev, k].sort().join('-')); prev = k; } }
      for (const h of sh.hops) if (walked.has([h.a, h.b].sort().join('-'))) P.push('hops: ' + h.a + '-' + h.b + ' ' + h.old + ' -> ' + h.new + ' is walked in a recorded run'); sh.checks.walked = [...walked].sort(); }
    notes.push('hops: all ' + sh.hopsAll.length + ' pairs of the frog\'s ' + Object.keys(FROG_PLACES).length + ' places keep the old count; at ' + n + ' step ends of the port\'s play he stands where the recorded run had him, or where moves puts that place (' + bad + ' differ)'); }

  /* the set's pixels: every set thing's pixels inside its touch box; nothing decorative; the hit order; the set things whole in the view or clearly off it */
  { const res = [];
    for (const k of STATES) { const parts = G.parts[k];
      for (const p of Object.keys(parts)) { if (!sh.things[THING_OF(p)] || !sh.things[THING_OF(p)].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s'); }
      const b = sh.things.estufa.box; let out = 0; for (const i of parts.estufa || []) { const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of the stove are outside its touch box ' + JSON.stringify(b) + ' (' + k + ')');
      // the hit order (set things only; the sprite things that stand there answer first, as the old): every stove pixel answers the stove
      let wrong = 0; for (const i of parts.estufa || []) { const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) wrong++; } if (wrong) P.push('hit: ' + wrong + ' stove pixels answer the room');
      // a set part either whole inside the view with 3 px to spare, or clearly off it (12 px or more past its edge)
      for (const [p, list] of Object.entries(parts)) { if (p === 'pared') continue; let a = 1e9, c = -1e9, t = 1e9, d = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); a = Math.min(a, x); c = Math.max(c, x); t = Math.min(t, y); d = Math.max(d, y); }
        const inL = a >= x0 + 3, inR = c <= x0 + 196 - 4, inT = t >= 3, inB = d <= 216 - 4, offL = a <= x0 - 12, offR = c >= x0 + 196 + 11, offB = d >= 216 + 11;
        if (!((inL || offL) && (inR || offR) && (inT) && (inB || offB))) P.push('edge: the part ' + p + ' spans x ' + a + ' to ' + c + ', y ' + t + ' to ' + d + ': it neither stays 3 px inside the view nor clearly runs off it (' + k + ')');
        if (k === 'banco1') res.push(p + ' x ' + a + '-' + c + ' y ' + t + '-' + d); } }
    notes.push('set things: the stove\'s pixels all inside its touch box ' + JSON.stringify(sh.things.estufa.box) + ' and answering it; every other part the room\'s (cocina, its box the whole picture, its hint box ' + JSON.stringify(sh.things.cocina.hintBox) + '); each part whole inside the view with 3 px to spare or clearly running off it: ' + res.join('; ')); }

  /* the light: every castShadow call darkens; each shadow in one piece with its thing; a thin thing (the stool's legs) only a short contact shadow; no
     pixel of the floor within 3 px of a thing on its lit side (left and above) differs from the floor without the thing */
  { const pieces = [];
    for (const k of STATES) { const OG = G.onGround[k], byPart = {};
      for (const c of G.shadows[k]) { const [x, y, z, r, s] = c.args, p = c.part || '(none)'; if (!(s > 0) || !(r > 0)) P.push('shadow: ' + p + ' castShadow(' + c.args.map(r2) + '): nothing is cast'); const b = byPart[p] = byPart[p] || { calls: 0 }; b.calls++; }
      for (const [p, b] of Object.entries(byPart)) { const sp = (G.shadowPx[k][p] || []).filter(i => OG[i]); if (!sp.length) P.push('shadow: the part ' + p + ' casts ' + b.calls + ' times and darkens nothing (' + k + ')');
        const own = new Set(); for (const [q, list] of Object.entries(G.parts[k])) if (q === p || q.startsWith(p + '.') || p.startsWith(q + '.') || (p === 'banco.patas' && q === 'banco')) for (const i of list) own.add(i);
        const lim = p === 'banco.patas' ? 3 : 4; let far = 0; for (const i of sp) { const x = i % 240, y = Math.floor(i / 240); let near = false; for (let dy = -lim; dy <= lim && !near; dy++) for (let dx = -lim; dx <= lim; dx++) if (own.has((y + dy) * 240 + x + dx)) { near = true; break; } if (!near) far++; }
        if (far) P.push('shadow: ' + far + ' px of ' + p + '\'s shadow are further than ' + lim + ' px from it (' + k + ')');
        if (k === 'banco1') pieces.push(p + ' ' + b.calls + ' calls, ' + sp.length + ' px'); }
      for (const [p, rgbSin] of Object.entries(G.sin[k])) { if (!/^banco/.test(p)) continue; const own = new Set(G.parts[k][p] || []); let bad = 0;
        for (const i of own) { const x = i % 240, y = Math.floor(i / 240); for (const [dx, dy] of [[-1, 0], [-2, 0], [-3, 0], [0, -1], [0, -2], [0, -3], [-1, -1], [-2, -2]]) { const j = (y + dy) * 240 + x + dx; if (x + dx < 0 || y + dy < 0 || own.has(j) || !OG[j]) continue;
          if (G.rgb[k][j * 3] !== rgbSin[j * 3] || G.rgb[k][j * 3 + 1] !== rgbSin[j * 3 + 1] || G.rgb[k][j * 3 + 2] !== rgbSin[j * 3 + 2]) bad++; } }
        if (bad) P.push('lit side: ' + bad + ' floor pixels within 3 px of ' + p + ' on its lit side differ from the floor without it (' + k + ')'); } }
    notes.push('light: the kit\'s one rule; every castShadow call of the set darkens the floor, each shadow within 4 px of its own thing (' + (pieces.join('; ') || 'the set casts none: the run stands against the wall with its lit front to the room, the stool casts none') + '); no floor pixel within 3 px of the stool (the thin thing on the floor) on its lit side differs from the floor without it (the stool is drawn after the room is baked: no ring of the engine\'s ambient occlusion round its legs); the run against the wall casts none (its lit front faces the room)'); }

  /* the window: what shows through it is outside (sky, the bush, the hedge), with the reveal, the frame and the sill */
  { const k = 'banco1', poly = F.holePoly, inside = (x, y) => { let c = false; for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) { const [xa, ya] = poly[a], [xb, yb] = poly[b]; if ((ya > y) !== (yb > y) && x < (xb - xa) * (y - ya) / (yb - ya) + xa) c = !c; } return c; };
    let n = 0, sky = 0, green = 0, frame = 0; const T = TAGS[k];
    for (let y = 0; y < 216; y++) for (let x = 0; x < 240; x++) { if (!inside(x + .5, y + .5)) continue; const i = y * 240 + x; n++; const c = rgbAt(k, i); if (T[i] !== 'ventana') continue; if (c[2] > c[0] + 40 && c[2] > 180) sky++; else if (c[1] > c[0] + 30 && c[1] > c[2]) green++; else frame++; }
    if (sky < n * .2 || green < 10) P.push('window: its opening shows ' + sky + ' px of sky and ' + green + ' of green of ' + n);
    notes.push('window: its opening (' + n + ' px) shows the outside: ' + sky + ' px of sky, ' + green + ' of the bush and the hedge, ' + frame + ' of its bars, the reveal and the frame (the kit\'s, with depth and a sill)'); }

  /* thin things are seen: each thin part of the set against what is behind it (the set baked without it), WCAG's contrast ratio */
  { const res = [];
    for (const p of F.THIN) for (const k of STATES) { if (!G.sin[k][p]) continue; const own = G.parts[k][p] || []; if (!own.length) continue; let ok = 0, sl = 0, sb = 0;
      for (const i of own) { const a = rgbAt(k, i), b = [G.sin[k][p][i * 3], G.sin[k][p][i * 3 + 1], G.sin[k][p][i * 3 + 2]], r = ratio(a, b); if (r >= 2) ok++; sl += lum(a); sb += lum(b); }
      const mr = (Math.max(sl, sb) / own.length + .05) / (Math.min(sl, sb) / own.length + .05);
      if (ok < own.length * .85 || mr < 2) P.push('thin: ' + p + ' stands out from what is behind it by ' + r2(mr) + ' (its pixels ' + Math.round(ok / own.length * 100) + '% at 2.0 or more) (' + k + ')');
      if (k === 'banco1') res.push(p + ' ' + r2(mr) + ' (' + Math.round(ok / own.length * 100) + '% of its pixels at 2.0 or more)'); }
    notes.push('thin things of the set against what is behind them (WCAG contrast ratio of the mean luminances; each part\'s pixels): ' + res.join('; ')); }

  /* the moments: compose each as estufa.js draw() draws it */
  const STAMP = new Int32Array(240 * 216), OWN = new Int32Array(240 * 216); let stampN = 0;
  const itemsOf = (w, side) => { const its = rawItems(w, side).filter(it => MASK[it.key]).map((it, n) => { const [dx, dy] = shiftOf(it); return Object.assign(it, { n, rows: rowsAt(MASK[it.key].rows, dx, dy), px: MASK[it.key].px, dx, dy }); }); return its; };
  const orderOf = its => { const pre = its.filter(i => i.group === 'pre'), list = its.filter(i => i.group === 'list'), post = its.filter(i => i.group === 'post'); list.sort((a, b) => a.y - b.y || a.n - b.n); return pre.concat(list, post); };
  const faceOf = it => { const p = it.o; if (it.kind === 'frog') { const b = frogBox(p); return [b.x + 2, b.y + R(p.dy || 0), b.w - 4, R(b.h * .6)]; }
    if (it.kind !== 'person') return null; const x = R(p.x);
    if (it.id === 'abuela') { const ps = p.pose || 'idle', f = ((ps === 'offer' || ps === 'bless') ? -1 : 1) * (p.dir < 0 ? -1 : 1); return [x + f * sh.talk.abuelaHead - 6, R(p.y) - 50 + 6, 12, 10]; }
    return [x - 6, R(p.y) - sh.talk.heights[it.id] + 1 + R(p.dy || 0) + 6, 12, 10]; };
  const planeOf = (it, w) => { if (it.kind === 'person') { const s = surfaceW(E, F, R(it.o.x), R(it.o.y) - 1); return (s.w[0] + s.w[1]) / E.R2; }
    if (it.kind === 'frog') { const b = frogBox(it.o), s = surfaceW(E, F, b.x + b.w / 2, it.o.y + 26); return s.on === 'banco' ? null : (s.w[0] + s.w[1]) / E.R2; }
    if (it.group === 'list' && it.o) { const s = surfaceW(E, F, R(it.o.x), R(it.o.y) - 1); return s.on === 'suelo' ? (s.w[0] + s.w[1]) / E.R2 : null; }
    return null; };
  // compose: each item owns the pixels it drew last; new: the stool drawn again over list items behind it, the room over the window's people
  const compose = (w, side) => { const key = keyOf(w), its = orderOf(itemsOf(w, side)); stampN++;
    its.forEach((it, j) => { it.j = j; for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; STAMP[i] = stampN; OWN[i] = j; } } });
    const cov = new Map();
    if (side === 'n') { const Z = G.z[key], TG = TAGS[key], PL = its.map(it => it.group === 'list' ? planeOf(it, w) : null);
      if (key === 'banco1') for (const part of FRONT.banco) for (const i of G.parts[key][part] || []) { if (STAMP[i] !== stampN) continue; const j = OWN[i], pl = PL[j]; if (pl == null) continue; const y = Math.floor(i / 240); if (Z[i] > pl / COS - (y + .5 - E.OY) * T30 / E.S) cov.set(i, part); }
      const wi = its.findIndex(it => it.kind === 'ventana'); if (wi >= 0) for (const it of [its[wi]]) for (const [y, a, b] of it.rows) for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (STAMP[i] !== stampN || OWN[i] !== wi || !FRONT.ventana.includes(TG[i])) continue; const v = (x + .5 - E.OX) / E.S - .05 * E.R2; if (Z[i] > v / COS - (y + .5 - E.OY) * T30 / E.S) cov.set(i, TG[i]); } }
    LASTCOV = cov;
    return its.map(it => { let tot = 0, vis = 0, fTot = 0, fVis = 0; const by = {}, hid = {}, face = faceOf(it);
      for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; tot++; const inF = face && x >= face[0] && x < face[0] + face[2] && y >= face[1] && y < face[1] + face[3]; if (inF) fTot++;
        const mine = STAMP[i] === stampN && OWN[i] === it.j, c = cov.get(i); if (!mine) { const h = its[OWN[i]].id; hid[h] = (hid[h] || 0) + 1; } else if (c) { hid[c] = (hid[c] || 0) + 1; by[c] = (by[c] || 0) + (inF ? 1000 : 1); } else { vis++; if (inF) fVis++; } } }
      return { it, tot, vis, fTot, fVis, by, hid, face }; }); };
  const STAMPv = (x, y, it) => { if (x < 0 || y < 0 || x >= 240 || y >= 216) return false; const i = y * 240 + x; return STAMP[i] === stampN && OWN[i] === it.j && !LASTCOV.has(i); };
  let LASTCOV = new Map();

  // the moments: every tick inside the acts of the port's play and every step's end, every pair picture
  const allW = []; runs.forEach((r, ri) => { for (const t of NEW[ri].ticks) allW.push([r.story.id + ' ' + r.plan + ' t ' + t.t, t.W, 'tick']); for (const L of NEW[ri].states) allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W, 'step']); });
  for (const ps of pairSides) allW.push(['pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps, sh), 'pair']);
  const TOPS = ['izq', 'estufa', 'der'];
  { const bad = new Map(), restBad = new Map(), stoolBad = new Map(), floorBad = new Map(), winBad = new Map(); let nM = 0, nRest = 0, nStool = 0, nFloor = 0, nWin = 0; const restSeen = new Set();
    for (const [where, w, kind] of allW) { nM++; const C = compose(w, 'n'), key = keyOf(w);
      for (const r of C) { const it = r.it;
        for (const [part, n] of Object.entries(r.by)) { const faceN = Math.floor(n / 1000); if (faceN) bad.set(part + ' over ' + it.id + '\'s face', where + ': ' + faceN + ' px'); }
        if (it.kind === 'ventana') { const NUMv = sh.layout.numbers; (w.ventana || []).forEach((id, j) => { const f = [178 + j * 12 - 6, NUMv.WY[j] + (j % 2) * 3 + 6, 12, 10]; let n = 0, v = 0;
            for (let y = f[1]; y < f[1] + f[3]; y++) for (let x = f[0]; x < f[0] + f[2]; x++) { n++; if (STAMPv(x, y, it)) v++; } nWin++; if (v < n * .75) winBad.set(id + ' at the window', where + ': ' + v + ' of ' + n + ' px of the face seen'); }); }
        // what stands on a top rests on it: its lowest row over the top (or the shelf), and nothing of the set over it
        if (it.group === 'pre' && ['pot', 'thing'].includes(it.kind) && !restSeen.has(it.key + key)) { restSeen.add(it.key + key); nRest++; const rs = it.rows.filter(q => q[0] >= 0 && q[0] < 216); if (!rs.length) continue; const last = Math.max(...rs.map(q => q[0])), on = it.id === 'estante' ? ['estante'] : TOPS; let n = 0, ok = 0;
          for (const [y, a, b] of rs) if (y >= last - 1) for (let x = a; x <= b; x++) { if (x < x0 || x >= x0 + 196) continue; n++; if (on.includes(E.surf(key, x + .5, y + 1.5))) ok++; }
          if (n && ok < n * .9) restBad.set(it.id + ' (' + it.key.slice(2, 40) + ')', where + ': ' + ok + ' of ' + n + ' px of its foot over ' + on.join(' or '));
          if (Object.keys(r.by).length) restBad.set(it.id + ' covered', where + ': ' + JSON.stringify(r.by)); }
        // the frog on the stool stands on its top; whoever stands on the floor stands on clear floor in front of the run
        if (it.kind === 'frog' && key === 'banco1') { const b = frogBox(it.o), s = surfaceW(E, F, b.x + b.w / 2, it.o.y + 26); if (Math.abs(b.x + b.w / 2 - F.STOOL.sx) <= 4 && Math.abs(it.o.y + 27 - F.STOOL.sy) <= 3 && !(it.o.dy < -1)) { nStool++; if (s.on !== 'banco') stoolBad.set('at ' + [it.o.x, it.o.y], where + ': his feet over ' + s.on); } }
        if (it.kind === 'person' && kind !== 'tick') { const x = R(it.o.x), y = R(it.o.y); if (x - 11 >= x0 + 196 || x + 11 <= x0) continue; nFloor++; const s = surfaceW(E, F, x, y - 1); if (s.on !== 'suelo' || s.w[1] < F.D + .15) floorBad.set(it.id + ' at ' + [x, y], where + ': on ' + s.on + ' (' + r2(s.w[1] - F.D) + ' in front of the run)'); } } }
    for (const [k, v] of [...bad].slice(0, 30)) P.push('drawn: ' + k + ' (' + v + ')');
    for (const [k, v] of [...restBad].slice(0, 30)) P.push('on a top: ' + k + ' (' + v + ')');
    for (const [k, v] of [...stoolBad].slice(0, 10)) P.push('stool: the frog ' + k + ' (' + v + ')');
    for (const [k, v] of [...floorBad].slice(0, 30)) P.push('floor: ' + k + ' (' + v + ')');
    for (const [k, v] of [...winBad].slice(0, 10)) P.push('window: ' + k + ' (' + v + ')');
    notes.push('drawn: at ' + nM + ' moments (every tick inside the acts of the port\'s play of the ' + runs.length + ' runs, every step\'s end, every pair picture) composed as estufa.js draws them (each item owns what it drew last; the stool drawn again over whoever stands behind it, the room over the window\'s people): no part of the set over any face; ' + nRest + ' things standing on a top (the pots and the pan, the cups, the tray, the plates, the jug, the board, the sack and the jar on the shelf), each with 90% and more of its foot over it and nothing of the set over it; ' + nStool + ' moments of the frog on the stool, his feet on its top; ' + nFloor + ' step ends of someone standing in the view, each on clear floor at least .15 in front of the run; ' + nWin + ' faces at the window, each 75% and more seen through its opening'); }

  /* at every step's end each person's and the frog's share seen no less than in the old picture of that moment less 10%, their face no less at all;
     whoever was wholly inside the view in the old picture is wholly inside with 3 px to spare */
  { const lows = [], edges = []; let n = 0;
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach((ln, li) => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return;
      const o = new Map(compose(ln.W, 'o').map(q => [q.it.id, q])), nw = compose(tw.W, 'n');
      const MVp = sh.moves.flatMap(m => m.places || []);
      for (const q of nw) { const p = o.get(q.it.id); if (!p || !p.tot || !q.tot) continue;
        if (['person', 'frog'].includes(q.it.kind)) { const a = p.it.kind === 'frog' ? [p.it.o.x, p.it.o.y] : [R(p.it.o.x), R(p.it.o.y)], b = q.it.kind === 'frog' ? [q.it.o.x, q.it.o.y] : [R(q.it.o.x), R(q.it.o.y)], m = MVp.find(z => (z.who === q.it.id || (z.who === 'cq' && q.it.kind === 'frog')) && z.old[0] === a[0] && z.old[1] === a[1]) || sh.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === a[0] && e.old[1] === a[1]), want = m ? m.new : a; if (want[0] !== b[0] || want[1] !== b[1]) continue; }
        if (['person', 'frog', 'ventana'].includes(q.it.kind) || q.it.group !== 'pre') { const bo = rowsBox(p.it.rows), bn = rowsBox(q.it.rows); if (bo && bn && within(bo, VIEW) && !within([bn[0] - 3, bn[1] - 3, bn[2] + 6, bn[3] + 6], VIEW)) edges.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' ' + JSON.stringify(bn)); }
        if (!['person', 'frog'].includes(q.it.kind)) continue; n++;
        const sN = q.vis / q.tot, sO = p.vis / p.tot, fN = q.fTot ? q.fVis / q.fTot : 1, fO = p.fTot ? p.fVis / p.fTot : 1;
        if (fN < fO - 1e-9 || sN < sO - .1) lows.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' seen ' + R(sN * 100) + '% (face ' + R(fN * 100) + '%), the old ' + R(sO * 100) + '% (' + R(fO * 100) + '%), by ' + JSON.stringify(q.hid)); } }); });
    for (const l of lows.slice(0, 40)) P.push('seen: ' + l);
    for (const l of [...new Set(edges)].slice(0, 30)) P.push('edge: ' + l + ' (wholly inside the view in the old picture)');
    notes.push('seen: at ' + n + ' person- and frog-moments (every step\'s end of the ' + runs.length + ' runs) each seen no less than in the old picture less 10%, the face no less (' + lows.length + ' less); everyone and everything wholly inside the view in the old picture of a moment wholly inside with 3 px to spare (' + edges.length + ' not)'); }
  return P.concat(checkAsks(sh, G, runs, { E, F, x0, TAGS, rgbAt, compose, itemsOf, allW, faceOf, notes }));
}

function checkAsks(sh, G, runs, C) {
  const P = [], { E, F, x0, TAGS, rgbAt, compose, itemsOf, allW, faceOf, notes } = C, NEW = G.TICKS;
  const facesOf = w => { const out = []; for (const it of itemsOf(w, 'n')) { if ((it.kind === 'person' && !(it.o.al != null && it.o.al < .5)) || (it.kind === 'frog' && !(it.o.al < .5))) out.push([it.kind === 'frog' ? 'the frog\'s face' : it.id + '\'s face', faceOf(it)]); } return out; };
  const facesOld = w => { const out = []; for (const it of itemsOf(w, 'o')) { if ((it.kind === 'person' && !(it.o.al != null && it.o.al < .5)) || (it.kind === 'frog' && !(it.o.al < .5))) out.push([it.kind === 'frog' ? 'the frog\'s face' : it.id + '\'s face', faceOf(it)]); } return out; };
  const alto = id => id === 'abuela' ? 51 : PEOPLE_H[id] || 56;
  const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const VIEWR = [x0, 0, 196, 216];

  /* bubbles: every one wholly inside the view, clear of the rounds card, on no face (talk) */
  { let nB = 0, worst = 99; const seen = new Set(), asOld = new Set();
    const talk = (k, top, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy); if (within(r, VIEWR) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } const r = bubRect(k, top[0], top[1]); r.old = true; return r; };
    for (const [where, w] of allW) { const boards = boardsOf(w, x0), faces = facesOf(w);
      const out = []; for (const [id, p] of Object.entries(w.gente || {})) { if (!shownP(p) || (p.al != null && p.al < .5) || R(p.x) < x0 || R(p.x) >= x0 + 196) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor'); for (const k of ks) out.push([id + ' "' + k + '"', talk(k, [R(p.x), R(p.y) - alto(id) - 1], boards, faces)]); }
      const q = w.cq; if (q && q.vis && !(q.al < .5) && q.bub) { const b = frogBox(q); out.push(['the frog "' + q.bub + '"', talk(q.bub, [b.x + (b.w >> 1), b.y + 2], boards, faces, b.w >> 1)]); }
      for (const [who, rect] of out) { const key = JSON.stringify([who, rect, boards, faces]); if (seen.has(key)) continue; seen.add(key); nB++;
        if (rect.old && / "amor"$/.test(who)) { asOld.add(who); continue; }
        if (!within(rect, VIEWR)) { P.push('bubble: ' + where + ' ' + who + ' ' + JSON.stringify(rect) + ' is not wholly inside the view'); continue; }
        worst = Math.min(worst, rect[0] - x0, x0 + 196 - rect[0] - rect[2], rect[1], 216 - rect[1] - rect[3]);
        for (const [bn, b] of boards) if (meets(rect, b)) P.push('bubble: ' + where + ' ' + who + ' is over ' + bn);
        for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + who + ' is on ' + fn); } }
    notes.push('bubbles: ' + nB + ' bubbles (each person\'s recorded one and "amor" when touched, the frog\'s) at every moment: wholly inside the view (' + worst + ' px from its edge at the least), clear of the rounds card, on no face' + (asOld.size ? '; where no place is free the "amor" of a touch keeps the old place: ' + [...asOld].join(', ') : '')); }

  /* the asks: hint frames, the hand, the answer cards and the hint drawn round each card; the asked thing seen whole, uncovered, on a plain surface */
  const cajaBox = (id, p) => [R(p.x) - 11, R(p.y) - alto(id), 22, alto(id)];
  const PL = { olla0: (w, Fy) => w.fuegos[0] && w.fuegos[0].k === 'olla' ? [107 - 17, Fy[0] - 24, 34, 28] : null, olla1: (w, Fy) => w.fuegos[1] && w.fuegos[1].k === 'olla' ? [145 - 17, Fy[1] - 24, 34, 28] : null, sarten: (w, Fy) => w.fuegos[0] && w.fuegos[0].k === 'sarten' ? [107 - 17, Fy[0] - 14, 36, 16] : null };
  const FYn = sh.layout.numbers.FYS, FYo = [OLDC.FY, OLDC.FY], ENn = sh.layout.numbers.ENY, BJn = sh.layout.numbers.BJ;
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) return old ? t.old.box : (t.hintBox || t.box);
    if (PL[k]) return PL[k](w, old ? FYo : FYn);
    if (k === 'saco' || k === 'tazon') { if (!(w.izq || {})[k]) return null; const x = old ? (k === 'saco' ? 45 : 67) : sh.layout.numbers.ENX[k], y = old ? 122 : ENn[k]; return [x - 12, y - 16, 24, 18]; }
    if (k === 'jarra') { if (!(w.izq || {}).jarra) return null; const y = old ? 121 : ENn.jarra, x = old ? 181 : sh.layout.numbers.ENX.jarra; return [x - 11, y - 22, 20, 24]; }
    if (k === 'bandeja') { if (!(w.izq || {}).bandeja) return null; return [28, (old ? 123 : BJn) - 15, 46, 16]; }
    if (k === 'pzpollo' || k === 'pzhuevo') { if (!w.plata) return null; return k === 'pzpollo' ? [w.plata.x - 24, w.plata.y - 22, 24, 24] : [w.plata.x, w.plata.y - 22, 24, 24]; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shownP(p) ? cajaBox(k, p) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !old) return t.hand; const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const itemOfThing = k => k === 'olla0' || k === 'sarten' ? 'fuego0' : k === 'olla1' ? 'fuego1' : ['saco', 'tazon', 'jarra', 'bandeja'].includes(k) ? k : k === 'pzpollo' || k === 'pzhuevo' ? 'plata' : null;
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99, nTell = 0; const askSeen = new Set(), askedFor = new Set(), crossedOld = new Set(), handOld = new Set(), coverOld = new Set(), asks = [];
  runs.forEach((r, ri) => { const Ls = NEW[ri].states, Lo = r.lines;
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = JSON.parse(JSON.stringify(Ls[j - 1].W)), jo = Lo.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')), wo = jo > 0 ? JSON.parse(JSON.stringify(Lo[jo - 1].W)) : w;
      const st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      let spot = null, opts = [];
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = wo.resp = st.resp.map(sb); opts = [spot]; }
      else if (st.decide) { opts = st.options.map(sb); const bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || opts[0]; if (st.decide === 'say') w.resp = wo.resp = opts; else if (bur.length) w.resp = wo.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')';
      asks.push({ story: r.story.id, plan: r.plan, path: L.path, before: Ls[j - 1].path, spot, opts, resp: w.resp || null });
      const key = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.fuegos, w.izq, w.der, w.plata, w.tarjeta, w.respEn]); if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), fOld = facesOld(wo), its = itemsOf(w, 'n');
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within([f[0] - 4, f[1] - 4, f[2] + 8, f[3] + 8], VIEWR)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn);
        for (const it of its) { if (it.kind === 'frog') { const f = frogBox(w.cq); if (meets(c, [f.x + 2, f.y + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' covers the frog'); continue; }
          if (!['person', 'pot', 'thing', 'ventana'].includes(it.kind)) continue; const n = rowsMeet(it.rows, it.kind === 'person' ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id); }
        // the hint the game draws round a card: its frame (box + 12) 2 px inside the view and over no head; its hand on no face
        const fr = [c[0] - FRAME_OUT, c[1] - FRAME_OUT, c[2] + 2 * FRAME_OUT, c[3] + 2 * FRAME_OUT]; if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('cards: ' + where + ' the hint frame round the card ' + k + ' is not 2 px inside the view');
        for (const [fn, f] of faces) { const head = [f[0] - 2, f[1] - 6, f[2] + 4, f[3] + 6]; if (meets(fr, head)) P.push('cards: ' + where + ' the hint frame round the card ' + k + ' crosses ' + fn.replace('face', 'head'));
          if (fn !== 'the frog\'s face' && handOn([c[0] + c[2] / 2, c[1] + c[3] - 6], f)) P.push('cards: ' + where + ' the hand at the card ' + k + ' is on ' + fn); } }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view with 2 px to spare'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = fOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' (the old frame did not)'); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      if (!hp) { P.push('hand: ' + where + ' no place for the hand at ' + spot); return; }
      { const hb = handBox(hp), ho = rb ? null : handOf(wo, spot, true), hbo = ho ? handBox(ho) : null; if (!rb && !within(hb, VIEWR) && hbo && within(hbo, VIEWR)) P.push('hand: ' + where + ' the hand ' + JSON.stringify(hb) + ' is cut by the view\'s edge (the old was not)'); }
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb && fn === 'the frog\'s face') continue; const ho = rb ? null : handOf(wo, spot, true), fo = fOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1])) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      // the thing asked for (and every thing among the choices): whole in the view, nothing drawn over it (as the old), a plain surface round it
      for (const o of new Set([spot, ...opts])) { const iname = itemOfThing(o); if (!iname) continue; const cn = compose(w, 'n'), co = compose(wo, 'o'), q = cn.find(x => x.it.id === iname), qo = co.find(x => x.it.id === iname); if (!q) continue; nTell++;
        const bxA = rowsBox(q.it.rows); if (!within(bxA, VIEWR)) P.push('tell: ' + where + ' ' + o + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        const hidN = q.tot - q.vis, hidO = qo ? qo.tot - qo.vis : 0; if (hidN > hidO + 2) { P.push('tell: ' + where + ' ' + o + ': ' + hidN + ' px of it covered (the old ' + hidO + ') by ' + JSON.stringify(q.hid)); } else if (hidN > 2) coverOld.add(o + ' (' + where.split(' (')[0] + ', as the old: ' + Object.keys(q.hid).join(', ') + ')');
        let n = 0, ok = 0; const own = new Set(); for (const [y, a, bb] of q.it.rows) for (let x = a; x <= bb; x++) own.add(y * 240 + x); const key = keyOf(w), T = TAGS[key];
        for (const [y, a, bb] of q.it.rows) for (let x = a - 2; x <= bb + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i) || x < 0 || x >= 240 || y + dy < 0 || y + dy >= 216) continue; n++; const t = T[i], s = G.surf[key][i]; if (['izq', 'der', 'estufa', 'salpicadero', 'pared'].includes(t) || s === 'suelo') ok++; }
        if (n && ok < n * .75) P.push('tell: ' + where + ' ' + o + ': only ' + Math.round(ok / n * 100) + '% of what is round it is a plain surface (a top, the stove, the splashback, the wall, the floor)'); } }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least; the room by its hint box), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face and not cut by the view\'s edge where the old was not' + (handOld.size ? ' (as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow 4 px and more inside the view (' + cardSpare + ' at the least), 2 px clear of the rounds card and of everyone\'s head and body, over no pot, pan or thing; the hint round each card 2 px inside the view and across no head, its hand on no face; ' + nTell + ' times a thing asked for or among the choices: whole in the view, covered no more than in the old picture' + (coverOld.size ? ' (' + [...coverOld].slice(0, 6).join('; ') + ')' : '') + ', a plain surface round it');
  sh.checks.asks = asks.filter((a, i) => asks.findIndex(b => b.story === a.story && b.plan === a.plan && b.path === a.path) === i).map(a => ({ story: a.story, plan: a.plan, path: a.path, before: a.before, spot: a.spot }));

  /* heads: nobody's head against the window's bars, the hood or the shelf where the old picture kept it clear */
  { const OLDR = { ventana: [174, 20, 42, 40], campana: [89, 17, 74, 26], estante: [25, 36, 52, 18] }; let n = 0; const bad = new Map();
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach(ln => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return; const key = keyOf(tw.W), T = TAGS[key];
      const fo = facesOld(ln.W); for (const [fn, f] of facesOf(tw.W)) { n++; const hr = [f[0] - 4, f[1] - 8, f[2] + 8, f[3] + 10], o = fo.find(e => e[0] === fn), ho = o ? [o[1][0] - 4, o[1][1] - 8, o[1][2] + 8, o[1][3] + 10] : null;
        for (const part of ['ventana', 'campana', 'estante']) { let m = 0; for (let y = hr[1]; y < hr[1] + hr[3]; y++) for (let x = hr[0]; x < hr[0] + hr[2]; x++) if (x >= 0 && y >= 0 && x < 240 && y < 216 && T[y * 240 + x] === part) m++; if (m > 3 && !(ho && meets(ho, OLDR[part]))) bad.set(fn + ' against ' + part, r.story.id + ' ' + r.plan + ' ' + ln.path + ' (' + m + ' px)'); } } }); });
    for (const [k, v] of [...bad].slice(0, 20)) P.push('head: ' + k + ' (' + v + ')');
    notes.push('heads: at ' + n + ' face-moments (step ends) nobody\'s head against the window, the hood or the shelf where the old picture kept it clear'); }

  /* steam and smoke are seen: each puff against what is directly behind it (the set, or the pot under it), WCAG's contrast ratio, at every moment */
  { const puffs = (x, y, negro) => { const out = []; for (let t = 0; t < 6; t++) { if (negro) [[-6, 2, 5], [1, -4, 6], [6, 1, 4], [-2, -10, 5]].forEach((p, i) => { const yy = y + p[1] - ((t + i * 2) % 6) * 2, xx = x + p[0] + ((t + i) % 3) - 1, r = p[2]; out.push({ t, rect: [xx - 1, yy - 1, r + 2, r + 2], smoke: [xx, yy, r] }); });
        else [[-7, 0], [0, -4], [6, -1]].forEach((p, i) => { const yy = y + p[1] - ((t + i * 2) % 6); out.push({ t, rect: [x + p[0] + ((t + i) % 3) - 1, yy, 2, 3], c: [255, 255, 255] }); }); } return out; };
    const seenK = new Set(); let n = 0, worst = 99, worstAt = '';
    for (const [where, w] of allW) { const key = keyOf(w), its = itemsOf(w, 'n'), list = [];
      (w.fuegos || []).forEach((f, i) => { if (!f || !f.k) return; const x = [107, 145][i], Fy = sh.layout.numbers.FYS[i];
        const ST = sh.layout.numbers.STEAM;
        if (f.k === 'olla') { if (f.humo) list.push(['smoke over pot ' + i, x, Fy + ST.potSmoke, 1]); else if (f.vapor && f.llama) list.push(['steam over pot ' + i, x, Fy + ST.pot, 0]); }
        else { (f.cosas || []).forEach((o, j) => { if (o.humo) list.push(['smoke over the pan', x + j * 12 - ((f.cosas.length - 1) * 6), Fy + ST.pan, 1]); }); if (f.humo) list.push(['smoke over the pan', x, Fy + ST.pan, 1]); else if (f.vapor) list.push(['steam over the pan', x, Fy + ST.pan, 0]); } });
      for (const c of w.cosas || []) if (c && c.vapor && c.vis !== 0) list.push(['steam over a cup', R(c.x) - 1, R(c.y) - 15, 0]);
      for (const [what, x, y, negro] of list) { const k2 = key + what + x + ',' + y + its.map(i => i.key).join(); if (seenK.has(k2)) continue; seenK.add(k2); n++;
        let sl = 0, sb = 0, m = 0; for (const pf of puffs(x, y, negro)) for (let yy = pf.rect[1]; yy < pf.rect[1] + pf.rect[3]; yy++) for (let xx = pf.rect[0]; xx < pf.rect[0] + pf.rect[2]; xx++) { if (xx < 0 || yy < 0 || xx >= 240 || yy >= 216) continue; const i = yy * 240 + xx;
          let behind = rgbAt(key, i); for (const it of its) if (it.group === 'pre' && it.px) { for (let q = 0; q < it.px.length; q += 4) if (it.px[q] === i) { const c = [it.px[q + 1], it.px[q + 2], it.px[q + 3]], cs = c.join(); if (!['42,42,54', '106,106,122', '148,148,166', '255,255,255'].includes(cs)) behind = c; break; } }   // (not the steam or smoke itself, drawn in the pot's shape at frame 0)
          const c = pf.smoke ? (xx >= pf.smoke[0] + 1 && yy >= pf.smoke[1] + 1 && xx < pf.smoke[0] + pf.smoke[2] - 2 && yy < pf.smoke[1] + pf.smoke[2] - 2 ? [148, 148, 166] : xx >= pf.smoke[0] && yy >= pf.smoke[1] && xx < pf.smoke[0] + pf.smoke[2] && yy < pf.smoke[1] + pf.smoke[2] ? [106, 106, 122] : [42, 42, 54]) : pf.c;
          sl += lum(c); sb += lum(behind); m++; }
        const rr = (Math.max(sl, sb) / m + .05) / (Math.min(sl, sb) / m + .05); if (rr < worst) { worst = rr; worstAt = what + ' (' + where + ')'; }
        if (rr < 2) P.push('steam: ' + what + ' stands out from what is behind it by ' + r2(rr) + ' (' + where + ')'); } }
    notes.push('steam and smoke: ' + n + ' distinct puffs (every frame of their rise) against what is directly behind them, the contrast ratio of the mean luminances ' + r2(worst) + ' at the least (' + worstAt + ')'); }

  /* the preview puts everyone where the sheet's rule does, at every recorded moment; the rule puts everyone at rest where the port's play has them */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    const MV = sh.moves.flatMap(m => (m.places || [])), RMall = sh.remap.filter(e => e.moved && e.kind === 'point');
    const remapW = (w0, story) => { const w = JSON.parse(JSON.stringify(w0)), RM = RMall.filter(e => e.uses.some(u => u.startsWith(story + '.json')));
      const find = (who, p) => MV.find(q => q.who === who && q.old[0] === R(p.x) && q.old[1] === R(p.y)) || RM.find(e => e.old[0] === R(p.x) && e.old[1] === R(p.y));
      for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) { const m = find(id, p); if (m) { p.x = m.new[0] + (p.x - R(p.x)); p.y = m.new[1] + (p.y - R(p.y)); } }
      for (const p of (w.cosas || []).concat(w.vuelos || [])) if (p && p.x != null) { const m = find('cosa', p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
      if (w.plata) { const m = find('plata', w.plata); if (m) { w.plata.x = m.new[0]; w.plata.y = m.new[1]; } }
      return w; };
    const places = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)]; if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y];
      (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0) o['cosa.' + (c.id || c.k + i)] = [R(c.x), R(c.y)]; }); if (w.plata) o.plata = [R(w.plata.x), R(w.plata.y)]; if (w.mat) o.mat = [R(w.mat.x), R(w.mat.y)]; return o; };
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = places(remapW(ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw || li === 0) return; const prev = places(remapW(r.lines[li - 1].W, r.story.id)), port = places(tw.W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k]) continue; nR++; if (port[k].join() !== p.join()) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    for (const [k, w] of [...off].slice(0, 30)) P.push('rule: ' + k + ' in the port\'s play (' + w + ')');
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places) estufa-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); the rule puts each of the ' + nR + ' places at rest where the port\'s play has them (' + badR + ' differ)'); }

  /* the review pictures: the two of a pair differ; everything in each whole with 2 px to spare; no zoom 2 picture shows a set part's cut-off piece */
  { const byWord = {}; for (const ps of pairSidesOf()) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps; const diffs = [];
    for (const [word, sides] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides)) { const ps = sides[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps, sh); ws[side] = w;
        const subj = pc.subject || [];
        for (const it of itemsOf(w, 'n')) { const b = rowsBox(it.rows); if (!b) continue; if (it.group === 'pre' && !subj.includes(it.id) && pc.zoom === 1) continue;
          if (it.kind === 'person' && pc.zoom === 2) { const f = faceOf(it), top = Math.min(...it.rows.map(q => q[0])); if (!within([f[0] - 2, top - 2, f[2] + 4, f[1] + f[3] - top + 4], pc.crop)) P.push('pair ' + nm + ': ' + it.id + '\'s head is not whole in ' + JSON.stringify(pc.crop)); const hb = rowsBox(it.rows.filter(q => q[0] <= pc.crop[1] + pc.crop[3] - 3)); if (hb && !within([hb[0] - 2, hb[1] - 2, hb[2] + 4, hb[3] + 2], pc.crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(hb) + ' is cut at the side or top of ' + JSON.stringify(pc.crop)); continue; } if (!within([b[0] - 2, b[1] - 2, b[2] + 4, b[3] + 4], pc.crop) && meets(b, pc.crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with 2 px to spare in ' + JSON.stringify(pc.crop)); }
        if (pc.zoom === 2) { const key = keyOf(w), T = TAGS[key], cnt = {}; for (let y = pc.crop[1]; y < pc.crop[1] + pc.crop[3]; y++) for (let x = pc.crop[0]; x < pc.crop[0] + pc.crop[2]; x++) { const t = T[y * 240 + x]; if (t) cnt[t] = (cnt[t] || 0) + 1; }
          for (const [t, c] of Object.entries(cnt)) if (c < 12 && t !== 'pared') P.push('pair ' + nm + ': shows only ' + c + ' px of ' + t + ' (a cut-off piece)'); } }
      if (!ws.si || !ws.no) continue; const d = []; for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) d.push(k);
      if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) d.push('the window'); if (!d.length) P.push('pair ' + word + ': the two pictures are the same'); diffs.push(deacc(word) + ': ' + d.join(', ')); }
    notes.push('pairs: ' + pairSidesOf().length + ' review pictures (the ' + sh.level.length + ' level pictures are among them): everything in each whole with 2 px to spare (a person in a zoom 2 picture whole but for the feet, as the old close pictures; in a zoom 1 picture of people, a pot or the pan behind them may be cut by its edge), no zoom 2 picture with a cut-off piece of the set; what differs: ' + diffs.join('; ')); }

  /* states and bakes */
  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSidesOf()) reached.add(keyOf(pairW(ps, null)));
    for (const k of STATES) if (!reached.has(k)) P.push('state ' + k + ' is baked but nothing reaches it');
    for (const k of STATES) if (G.ms[k].first >= 150) P.push('bake: the first bake of ' + k + ' took ' + R(G.ms[k].first) + ' ms in a fresh page (keep under 150)');
    notes.push('states: ' + reached.size + ' baked states reached (every moment, pair and level picture); each first bake in a fresh page under 150 ms (the median of five)'); }
  return P;
}
