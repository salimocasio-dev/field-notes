#!/usr/bin/env node
'use strict';
/* A comer's sheet (order 40a): writes docs/proyecto/pixel/comer-sheet.json from comer-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/comer-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.COMER_SET), its part map, depth, surfaces and every castShadow call from comer-set.html in headless Chrome
   (and the set baked without each standing part: what is behind it); measures the old sprite layer as comer.js draw() itself draws it
   (historia/engine.js, juego.js, kit.js and escenas/comer.js as they are, and as the port will have them: each person's body and arms, every
   thing on the table, the dog, the frog, what flies, the thought clouds, each alone); plays every story of the scene on the old page by the
   same machine as the recorded runs (coqui/tool/ref/trazas: juega.mjs --states for the steps' ends, page-init.js and page-drive.js with the
   same seed, think time and clock for every tick inside the acts), with comer.js and the story files as the port will have them (the sheet's
   moves and remap); composes every moment as the game draws it (comer.js draw: the sorted list by its y, then what flies and the clouds; each
   item owns the pixels it drew last; a set part is drawn again by sheet.front only where it is nearer than that owner: the table at the old
   table's place in the list, the chairs before everyone at the table) and checks every rule of the brief on that picture, against the old
   picture of the same moment composed the same way. It reads comer.js itself for every number that is a place on the picture (the sheet's
   code). It loads comer-preview.html (over a local http server it starts and stops) to check that the preview puts everyone where the sheet
   does. Nothing in the repo is written but the sheet (its temporary files live in docs/proyecto/pixel/comer-tmp-*, removed at the end). A
   second run writes the same bytes. The models: La estufa's maker (the kitchen's, on main), El banco's and El lago's.
   COMER_NOCHECK=1: write the sheet only. COMER_DUMP=<folder>: also write each run's steps and ticks, the recorded and the port's, there. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'comer-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/comer');
const COMER_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/comer.js'), 'utf8');
const LINES = COMER_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('comer.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const R = Math.round, r2 = v => Math.round(v * 100) / 100, r4 = v => Math.round(v * 1e4) / 1e4, W4 = p => p.map(r4);
const deacc = s => s.replace(/[¿?]/g, '').replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');

// one baked state: A comer's background never changes (order 06: no background key); what stands on the table is the sprite layer's
const STATES = ['comer'];
const keyOf = () => 'comer';
const queryOf = () => '';
const THING_OF = p => /^mesa/.test(p) ? 'mesa' : p === 'silla3' ? 'silla_papa' : 'cocina';   // the table and papá's chair are touch keys; every other part is the room's
const STANDING = ['mesa', 'mesa.patas', 'silla0', 'silla1', 'silla2', 'silla3', 'sillas.patas', 'fregadero'];   // the parts baked again without them
const FRONT = { sillas: ['silla0', 'silla1', 'silla2', 'silla3', 'sillas.patas'], mesa: ['mesa', 'mesa.patas'] };
const VIEW_X0 = 32, VIEW = [VIEW_X0, 0, 196, 216];
const TZ = 173;

(async () => {
  const browser = await chromium.launch();
  const errs = [];
  const G = await setData(browser, errs);
  G.M = await measure(browser);
  const runs = storyStates();
  let sheet = make(G, runs);
  G.HOPS = await hopTable(browser, runs, sheet);
  sheet = make(G, runs);
  G.WALKS = await hopTable(browser, runs, sheet, G.HOPS.walks);   // every walk again, with the final sheet's port: hop count by hop count
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.COMER_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  G.TICKS = await tickStates(browser, runs, sheet);
  G.PV = await previewPlaces(browser, runs);
  if (process.env.COMER_DUMP) { fs.mkdirSync(process.env.COMER_DUMP, { recursive: true }); runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.COMER_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states, ticks: G.TICKS[i].ticks, alc: G.TICKS[i].alc }))); }
  G.MASK = await masks(browser, sheet, G, runs);
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome, the median of five fresh pages: ' + STATES.map(k => k + ' first ' + R(G.ms[k].first) + ' ms (' + G.ms[k].all.join(', ') + (G.ms[k].tries > 1 ? '; ' + G.ms[k].tries + ' rounds of five' : '') + '), again ' + R(G.ms[k].warm) + ' ms').join('; '));
  if (problems.length) { const g = new Map(); for (const q of problems) { const k = q.replace(/ \((?:[^()]|\([^()]*\))*\)$/, ''); if (!g.has(k)) g.set(k, [q, 0]); g.get(k)[1]++; }
    console.log('CHECK FAILED (' + problems.length + ', ' + g.size + ' kinds):\n  ' + [...g.values()].slice(0, 250).map(([q, n]) => (n > 1 ? n + ' x ' : '') + q).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the set, every baked state, in a fresh page each (the first bake is the one the port must keep under 150 ms) ---------- */
async function setData(browser, errs) {
  const G = { parts: {}, z: {}, rgb: {}, shadows: {}, shadowPx: {}, onGround: {}, surf: {}, ms: {}, sin: {} };
  const url = (key, extra) => 'file://' + path.join(__dirname, 'comer-set.html') + '?tags=1' + (extra || '');
  for (const key of STATES) {
    const page = await browser.newPage(); page.on('pageerror', e => errs.push(String(e)));
    await page.goto(url(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(COMER_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
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
      const onGround = [], surf = []; for (let i = 0; i < W * H; i++) { onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0); const s = COMER_SET.surfaceAt(i % W + .5, Math.floor(i / W) + .5); surf.push(s.on === 'floor' && s.under ? 'under' : s.on); }
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), rgb: rgbA, calls, first: BAKE_MS, warm, shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, surf };
    });
    await page.close();
    // the bake as the port does it (no part tags), in five fresh pages: the median first bake (a page loaded while the machine is busy with
    // other work can take twice as long), and a second bake in the same page; a busy machine: when the median is over the limit, five more
    // pages, up to three times; the lowest median is kept (all are reported)
    for (let attempt = 0; attempt < 3 && !(G.ms[key] && G.ms[key].first < 150); attempt++) { const firsts = [], warms = []; for (let n = 0; n < 5; n++) { const pg = await browser.newPage(); await pg.goto('file://' + path.join(__dirname, 'comer-set.html') + '?' + queryOf(key));
        const t = await pg.evaluate(() => { const t1 = performance.now(); buildSet(); return [BAKE_MS, performance.now() - t1]; }); firsts.push(t[0]); warms.push(t[1]); await pg.close(); }
      const med = a => a.slice().sort((x, y) => x - y)[a.length >> 1], prev = G.ms[key]; if (!prev || med(firsts) < prev.first) G.ms[key] = { first: med(firsts), warm: med(warms), all: firsts.map(R) }; G.ms[key].tries = (prev ? prev.tries : 0) + 1; }
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S });
    G.parts[key] = g.parts; G.z[key] = g.z; G.rgb[key] = g.rgb; G.shadows[key] = g.calls; G.shadowPx[key] = g.shadowPx; G.onGround[key] = g.onGround; G.surf[key] = g.surf;
    // the set without each standing part: what is behind it (thin things' contrast, the lit side of each thing)
    G.sin[key] = {};
    for (const p of STANDING) {
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
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'comer') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(__dirname, 'comer-tmp-'));
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

/* ---------- the preview's places: comer-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/comer-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- comer.js as the port will have it: the sheet's moves applied (the same edit as comer-preview.html's) ---------- */
function portSource(sheet) {
  let src = COMER_JS; const done = new Set();
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); if (!src.includes(m.src)) throw new Error('comer.js does not hold ' + m.src); src = src.split(m.src).join(m.to); }
  for (const [a, b] of sheet.helps.lines) { if (!src.includes(a)) throw new Error('comer.js does not hold ' + a); src = src.split(a).join(b); }
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

/* ---------- every tick inside the acts: the old page played by the same machine as the recorded runs, comer.js and the story files as the
   port will have them, the scene's W kept after every timer the runner fires when it changed ---------- */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const WKEYS = ['gente', 'cq', 'cosas', 'vuelos', 'perro', 'sitio', 'tarjeta', 'marcas', 'respEn', 'resp', 'spot', 'twinkle'];
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = {}; for (const k of ${JSON.stringify(WKEYS)}) o[k] = W[k]; o.F = typeof F === 'number' ? F : 0; o.TALK = typeof TALK === 'undefined' ? null : TALK;
    const s = JSON.stringify(o, (k, x) => typeof x === 'function' || (x && x.nodeType) || x instanceof HTMLCanvasElement || (x && typeof x.then === 'function') ? undefined : x); if (s !== last) { last = s; window.__TICKS.push({ t: H.now, W: JSON.parse(s) }); } } catch (e) {} };
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
        await ctx.route(/\/historia\/escenas\/comer\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
        await ctx.route(/\/historia\/cuentos\/[^/]+\.json(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop()).replace(/\.json$/, '');
          return route.fulfill({ status: 200, contentType: 'application/json', body: portStory(name, sheet) }); });
        const page = await ctx.newPage();
        await page.goto(base + '/historia/index.html?cuento=' + r.story.id + '&fast=1&rec=1&mic=stub:none&abiertas=todas');
        for (let i = 0; ; i++) { if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break; if (i > 600) throw new Error('the page did not load ' + r.story.id); await new Promise(z => setTimeout(z, 50)); }
        await page.evaluate('voiceReady'); await page.evaluate(DRIVE);
        const tr = await page.evaluate(cfg => window.__drive(cfg), { plan: r.plan, think: 700, limitMs: 4 * 3600e3, states: true });
        if (tr.end !== 'finished') throw new Error('ticks: ' + r.story.id + ' ' + r.plan + ' ended: ' + tr.end);
        out.push({ ticks: await page.evaluate(() => window.__TICKS), states: tr.states, sounds: tr.sounds, alc: await page.evaluate(() => (window.__ALC || []).slice()) });
      } finally { await ctx.close(); }
    }
    return out; });
}

/* ---------- the frog's hops: every ranaA call of every run, played on the old page and with the port's comer.js, in order: where he was and
   where he went on the new picture, and on the old. HOPAT (moves) maps each new place to its old one, so the port counts the old hops ---------- */
const JUEGO_JS = fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8');
const HOPTO = 'async function hopTo(x,y,hops,s1){const q=W.cq,x0=q.x,y0=q.y,s0=q.s;';
if (JUEGO_JS.split(HOPTO).length !== 2) throw new Error('walks: hopTo');
// juego.js with every walk of the frog written down: where from, where to, how many hops (hopTo is the only way he hops, acts included)
const JUEGO_LOG = JUEGO_JS.replace(HOPTO, HOPTO + '(window.__WALKS=window.__WALKS||[]).push([x0,y0,x,y,hops]);');
async function hopTable(browser, runs, sheet, oldWalks) {
  const INIT = fs.readFileSync(path.join(TRAZAS, 'page-init.js'), 'utf8').replace('__SEED__', '1'), DRIVE = fs.readFileSync(path.join(TRAZAS, 'page-drive.js'), 'utf8');
  const a = 'async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);';
  const LOG = s => { if (!s.includes(a)) throw new Error('hops: ranaA'); return s.replace(a, a + '(window.__HOPS=window.__HOPS||[]).push([q.x+16,q.y+27,x,y,d<3?0:(h||Math.max(1,Math.min(6,Math.ceil(d/26))))]);'); };
  const SRC = { o: LOG(COMER_JS), n: LOG(portSource(sheet)) };
  return serve(async base => { const table = {}, conflicts = new Set(); let calls = 0;
    const walks = []; let ri = 0;
    for (const r of runs) { const got = {}, wk = {}; if (oldWalks) wk.o = oldWalks[ri].o;
      for (const side of oldWalks ? ['n'] : ['o', 'n']) { const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: 'UTC', locale: 'en-US' });
        try { await ctx.addInitScript(INIT);
          await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop()); return fs.existsSync(path.join(REPO, 'historia/audio', name)) ? route.fulfill({ status: 200, contentType: 'audio/mpeg', body: 'ID3' }) : route.fulfill({ status: 404, body: '' }); });
          await ctx.route(/\/historia\/juego\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: JUEGO_LOG }));
          await ctx.route(/\/historia\/escenas\/comer\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC[side] }));
          if (side === 'n') await ctx.route(/\/historia\/cuentos\/[^/]+\.json(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop()).replace(/\.json$/, ''); return route.fulfill({ status: 200, contentType: 'application/json', body: portStory(name, sheet) }); });
          const page = await ctx.newPage(); await page.goto(base + '/historia/index.html?cuento=' + r.story.id + '&fast=1&rec=1&mic=stub:none&abiertas=todas');
          for (let i = 0; ; i++) { if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break; if (i > 600) throw new Error('the page did not load ' + r.story.id); await new Promise(z => setTimeout(z, 50)); }
          await page.evaluate('voiceReady'); await page.evaluate(DRIVE);
          const tr = await page.evaluate(cfg => window.__drive(cfg), { plan: r.plan, think: 700, limitMs: 4 * 3600e3, states: false }); if (tr.end !== 'finished') throw new Error('hops: ' + r.story.id + ' ' + r.plan + ' ' + side + ' ended: ' + tr.end);
          got[side] = await page.evaluate(() => window.__HOPS || []); wk[side] = await page.evaluate(() => window.__WALKS || []); } finally { await ctx.close(); } }
      walks.push({ story: r.story.id, plan: r.plan, o: wk.o, n: wk.n }); ri++;
      if (oldWalks) continue;
      if (got.o.length !== got.n.length) throw new Error('hops: ' + r.story.id + ' ' + r.plan + ': ' + got.o.length + ' ranaA calls on the old page, ' + got.n.length + ' with the port\'s comer.js');
      got.o.forEach((o, i) => { const w = got.n[i]; calls++;
        for (const [nx, ny, ox, oy] of [[w[2], w[3], o[2], o[3]], [w[0], w[1], o[0], o[1]]]) { if (Math.round(nx) === Math.round(ox) && Math.round(ny) === Math.round(oy)) continue; const k = Math.round(nx) + ',' + Math.round(ny), v = [Math.round(ox), Math.round(oy)];
          if (table[k] && table[k].join() !== v.join()) conflicts.add(k + ': ' + table[k] + ' and ' + v); else table[k] = v; } }); }
    const sorted = {}; for (const k of Object.keys(table).sort((p, q) => { const [a1, b1] = p.split(',').map(Number), [a2, b2] = q.split(',').map(Number); return a1 - a2 || b1 - b2; })) sorted[k] = table[k];
    return { table: sorted, conflicts: [...conflicts], calls, walks }; });
}

/* ---------- the old sprite layer, as comer.js draw() draws it ----------
   Every item a world shows, in the order draw() draws it: the sorted list by its y (pushed in this order, a stable sort: each person's body and
   then their arms and what they hold, at capa(); the table at TZ (the old only: the port's is the set's, drawn again over what is behind it by
   sheet.front); every thing in W.cosas, on the table just after the table (enMesa), elsewhere at its foot; the dog; the frog, over the table
   unless W.cq.sobre is 0), then what flies (W.vuelos) and the thought clouds, a person's and then the frog's. Each item's shape is what draw()
   draws for a world holding only it (comer.js gated item by item for the measure: window.__ONLY), at frame 0 */
const SHAPE_AT = [120, 150], FROG_AT = [104, 123];
const BASE = () => ({ respEn: [130, 22], gente: {}, sitio: {}, cosas: [], vuelos: [], perro: null, tarjeta: null, marcas: null, cq: { x: 108, y: 141, s: 1, dy: 0, al: 1, vis: 0, sobre: 1, bub: null, hace: null, piensa: null, tiene: [] } });
const J = o => JSON.stringify(o == null ? null : o);
const rowsOfPx = list => { const S2 = new Set(list), rows = []; for (const i of [...S2].sort((a, b) => a - b)) { const y = Math.floor(i / 240), x = i % 240, l = rows[rows.length - 1]; if (l && l[0] === y && l[2] === x - 1) l[2] = x; else rows.push([y, x, x]); } return rows; };
const shownP = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
const QUIEN_NINO = { luis: 1, carmen: 1 };
const altoOf = (id, p) => id === 'abuela' ? (p && p.sent ? 48 : 51) : QUIEN_NINO[id] ? (p && p.sent ? 37 : 44) : (p && p.sent ? 49 : 56);
// comer.js capa() and enMesa(): the old ones, and the port's (the sheet's numbers: the table's top and what is behind it, on the new picture)
let GEO = null;   // set by make(): { detras(x, y), entop(x, y) } as the port's comer.js has them
const detrasOld = p => !p.sent && !p.est && p.z == null && p.y < TZ && p.x > 62 && p.x < 190;
const detrasNew = p => !p.sent && !p.est && p.z == null && GEO.detras(p.x, p.y) && p.x < 186 && p.y - (p.x - SYC) / 2 < 118 + 3;   // comer.js detrasMesa (the port's): ATRAS 118
const capaOf = (p, side) => { const uy = side === 'o' || p.x >= 186 ? p.y : p.y - (p.x - SYC) / 2; return p.z != null ? [p.z, p.z + .001] : (p.sent || p.est) ? [side === 'n' && p.x < 186 ? uy + p.x / 10000 : uy, TZ + .9] : (side === 'o' ? detrasOld(p) : detrasNew(p)) ? [40 + uy / 100, 40.5 + uy / 100] : [p.y, p.y < TZ ? TZ + .9 : p.y + .001]; };
const enMesaOf = (o, side) => side === 'o' ? (o.y >= 124 - 1 && o.y <= 170 + 3 && o.x > 66 - 8 && o.x < 66 + 120 + 8) : GEO.entop(o.x, o.y);
const pKey = p => { const o = Object.assign({}, p); delete o.x; delete o.y; delete o.ci; return J(o); };
function rawItems(w, side) {
  const out = [], add = (group, kind, id, key, only, spec, extra) => out.push(Object.assign({ group, kind, id, key: side + '|' + key, only, spec }, extra || {}));
  const talk = w.TALK || null;
  for (const [id, p] of Object.entries(w.gente || {})) if (shownP(p)) {
    const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], vis: 1 }), cp = capaOf(p, side), k = id + '|' + pKey(p) + (talk === id ? '|t' : '');
    add('list', 'person', id, 'c|' + k, 'c', { gente: { [id]: o }, TALK: talk === id ? id : null }, { o: p, y: cp[0], at: [R(p.x), R(p.y)] });
    add('list', 'arms', id + '\'s hands', 'a|' + k, 'a', { gente: { [id]: o }, TALK: talk === id ? id : null }, { o: p, y: cp[1], at: [R(p.x), R(p.y)], of: id });
  }
  if (side === 'o') add('list', 'table', 'the old table', 'mesa', 'mesa', {}, { y: TZ });
  (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0) { const o = Object.assign({}, c, { x: SHAPE_AT[0], y: SHAPE_AT[1], z: null });
    add('list', 'thing', 'cosa ' + (c.id || c.k + i), 't|' + J(o), 't', { cosas: [o] }, { o: c, y: c.z != null ? c.z : enMesaOf(c, side) ? TZ + c.y / 1000 : c.y + 1, at: [R(c.x), R(c.y)], cid: c.id || null }); } });
  if (w.perro && w.perro.vis !== 0) { const o = Object.assign({}, w.perro, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); add('list', 'dog', 'Canelo', 'g|' + J(o), 'g', { perro: o }, { o: w.perro, y: w.perro.y, at: [R(w.perro.x), R(w.perro.y)] }); }
  const q = w.cq; if (q && q.vis && !(q.al <= .3)) { const o = Object.assign({}, q, { x: FROG_AT[0], y: FROG_AT[1], al: 1, bub: null, vis: 1, piensa: null }); add('list', 'frog', 'the frog', 'q|' + J(o) + (talk === 'coqui' ? '|t' : ''), 'q', { cq: o, TALK: talk === 'coqui' ? 'coqui' : null }, { o: q, y: q.sobre === 0 ? q.y + 27 : TZ + (q.y + 27) / 1000, at: [q.x, q.y] }); }
  (w.vuelos || []).forEach((v, i) => { const o = Object.assign({}, v, { x: SHAPE_AT[0], y: SHAPE_AT[1] }); add('post', 'thing', 'vuelo ' + v.k + i, 'u|' + J(o), 'u', { vuelos: [o] }, { o: v, at: [R(v.x), R(v.y)] }); });
  for (const [id, p] of Object.entries(w.gente || {})) if (shownP(p) && p.piensa) { const o = Object.assign({}, p, { x: SHAPE_AT[0], y: SHAPE_AT[1], vis: 1 }); add('post', 'cloud', id + '\'s cloud', 'n|' + id + '|' + J([p.piensa, p.pdx, p.sent]), 'n', { gente: { [id]: o } }, { o: p, at: [R(p.x), R(p.y)] }); }
  if (q && q.vis && q.piensa) { const rel = !q.nube, o = Object.assign({}, q, rel ? { x: FROG_AT[0], y: FROG_AT[1] } : {}); add('post', 'cloud', 'the frog\'s cloud', 'nq|' + J([q.piensa, q.nube, q.nubeAim, q.ndir, rel ? 0 : [q.x, q.y, q.s]]), 'nq', { cq: o }, { o: q, rel }); }
  return out;
}
// each item's offset from where its shape was measured
const shiftOf = it => { if (it.kind === 'person' || it.kind === 'arms') return [R(it.o.x) - SHAPE_AT[0], R(it.o.y) - SHAPE_AT[1]];
  if (it.kind === 'frog') return [it.o.x - FROG_AT[0], it.o.y - FROG_AT[1]];
  if (it.kind === 'cloud') return it.id === 'the frog\'s cloud' ? (it.rel ? [it.o.x - FROG_AT[0], it.o.y - FROG_AT[1]] : [0, 0]) : [R(it.o.x) - SHAPE_AT[0], R(it.o.y) - SHAPE_AT[1]];
  if (it.kind === 'table') return [0, 0];
  if (it.o) return [R(it.o.x) - SHAPE_AT[0], R(it.o.y) - SHAPE_AT[1]];
  return [0, 0]; };
// comer.js gated for the measure: each item of draw() drawn only when window.__ONLY names it (or nothing is named); no background
const GATES = [
  ['c.drawImage(spr("comer",fondo),0,0);', ''],
  ['L.push({y:cp[0],d:()=>cuerpo(c,id,a)});L.push({y:cp[1],d:()=>objetos(c,id,a)});', 'if(__G("c"))L.push({y:cp[0],d:()=>cuerpo(c,id,a)});if(__G("a"))L.push({y:cp[1],d:()=>objetos(c,id,a)});'],
  ['L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});', 'if(__G("mesa"))L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});'],
  ['(W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push(', '(__G("t")?(W.cosas||[]):[]).forEach(o=>{if(o.vis!==0)L.push('],
  ['if(W.perro&&W.perro.vis!==0)L.push(', 'if(__G("g")&&W.perro&&W.perro.vis!==0)L.push('],
  ['if(q.vis)L.push({y:q.sobre===0', 'if(__G("q")&&q.vis)L.push({y:q.sobre===0'],
  ['(W.vuelos||[]).forEach(o=>{if(o.k==="chorro")', '(__G("u")?(W.vuelos||[]):[]).forEach(o=>{if(o.k==="chorro")'],
  ['Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(', 'if(__G("n"))Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube('],
  ['if(q.vis&&q.piensa){', 'if(__G("nq")&&q.vis&&q.piensa){'],
];
const gated = src => { for (const [a, b] of GATES) { if (!a.startsWith('L.push({y:TZ') && !src.includes(a)) throw new Error('masks: comer.js does not hold ' + a); src = src.split(a).join(b); } return 'window.__G=k=>!window.__ONLY||window.__ONLY===k;\n' + src; };
// the shapes: the old scene file and the port's, each in its own page; every key seen at any moment of either
async function masks(browser, sheet, G, runs) {
  const keys = { o: new Map(), n: new Map() };
  const add = (w, side) => { for (const it of rawItems(w, side)) if (!keys[side].has(it.key)) keys[side].set(it.key, [it.only, it.spec]); };
  for (const r of runs) for (const l of r.lines) add(l.W, 'o');
  for (const T of G.TICKS) { for (const t of T.ticks) add(t.W, 'n'); for (const L of T.states) add(L.W, 'n'); }
  for (const ps of pairSidesOf()) { add(pairW(ps, null), 'o'); add(pairW(ps, sheet), 'n'); }
  const out = {};
  for (const side of ['o', 'n']) {
    const page = await browser.newPage(); const errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
    for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
    await page.addScriptTag({ content: gated(side === 'o' ? COMER_JS : portSource(sheet)) });
    if (errs.length) throw new Error('masks: ' + errs.join('; '));
    const list = [...keys[side].entries()];
    for (let s = 0; s < list.length; s += 400) Object.assign(out, await page.evaluate(([list, base]) => {
      const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'), E = ESCENAS.comer, res = {};
      for (const [key, [only, spec]] of list) {
        const w = Object.assign(JSON.parse(base), JSON.parse(JSON.stringify(spec))); delete w.TALK; window.__ONLY = only; W = w; F = 0; TALK = spec.TALK || null;
        g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.imageSmoothingEnabled = false; g.clearRect(0, 0, 240, 216); E.draw(g, w, 0); window.__ONLY = null;
        const d = g.getImageData(0, 0, 240, 216).data, rows = [], px = []; let n = 0; const s3 = [0, 0, 0];
        for (let y = 0; y < 216; y++) { let a = -1; for (let x = 0; x <= 240; x++) { const i = (y * 240 + x) * 4, ch = x < 240 && d[i + 3] > 0;
          if (ch) { n++; s3[0] += d[i]; s3[1] += d[i + 1]; s3[2] += d[i + 2]; px.push(y * 240 + x, d[i], d[i + 1], d[i + 2]); if (a < 0) a = x; } else if (a >= 0) { rows.push([y, a, x - 1]); a = -1; } } }
        res[key] = { rows, mean: s3.map(v => Math.round(v / Math.max(1, n))), px };
      }
      TALK = null; return res;
    }, [list.slice(s, s + 400), JSON.stringify(BASE())]));
    await page.close();
  }
  return out;
}

// the bubbles (bub: the tail's tip at the origin, both frames of the bob), each person's sprite heights standing and sitting
async function measure(browser) {
  const page = await browser.newPage(); const errs = []; page.on('pageerror', e => errs.push(String(e)));
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  await page.addScriptTag({ content: COMER_JS });
  const M = await page.evaluate(() => {
    const keys = Object.keys(BUB).concat(Object.keys(BUBL)), bubbles = {};
    for (const k of keys) { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const a of [0, 1]) { const cv = document.createElement('canvas'); cv.width = 400; cv.height = 300; const g = cv.getContext('2d'); g.translate(200, 250); bub(g, k, 0, 0, a);
        const d = g.getImageData(0, 0, 400, 300).data; for (let i = 0; i < 400 * 300; i++) if (d[i * 4 + 3]) { const x = i % 400 - 200, y = (i / 400 | 0) - 250; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } }
      bubbles[k] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1]; }
    return { bubbles, sinTxt: typeof SINTXT === 'undefined' ? null : SINTXT };
  });
  await page.close(); if (errs.length) throw new Error('measure: ' + errs.join('; '));
  return M;
}

/* ---------- the review pictures ---------- */
const PAIRS = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
const pairSidesOf = () => PAIRS.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'comer').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
// a pair picture's world (cual.js panelW: the frog at 123, 150 s .86, seen only if the pair shows cards), through the sheet's remap when given
function pairW(ps, sheet) {
  const w = Object.assign(BASE(), { cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: ps.spec.set && ps.spec.set.resp ? 1 : 0, bub: null, sobre: 1, tiene: [] } }, JSON.parse(JSON.stringify(ps.spec.set || {})));
  if (!sheet) return w;
  const mv = o => { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === R(o.x) && e.old[1] === R(o.y) && e.uses.some(u => u.startsWith('cual-comer.json'))); if (m) { o.x = m.new[0]; o.y = m.new[1]; } };
  for (const o of Object.values(w.gente || {})) mv(o); for (const o of w.cosas || []) mv(o); for (const o of w.vuelos || []) mv(o); if (w.perro) mv(w.perro);
  if (w.cq && w.cq.vis) { const m = sheet.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === w.cq.x && e.old[1] === w.cq.y); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }
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
// what is under a screen point: the table's top, a counter's or the stove's top, the floor (comer-set.html surfaceAt), with the world point
function surfaceW(E, F, sx, sy) {
  const inR = (x, y, r, m = 0) => x >= r[0] - m && x <= r[2] + m && y >= r[1] - m && y <= r[3] + m;
  for (const [on, r, z] of [['mesa', F.FOOT.mesa, F.ZT], ['mostrador', F.FOOT.mostrador, F.K.CZ], ['mostrador2', F.FOOT.mostrador2, F.K.CZ], ['estufa', F.FOOT.estufa, F.K.CZ]]) { const g = E.atZ(sx, sy, z); if (inR(g[0], g[1], r)) return { on, w: g }; }
  const g = E.atZ(sx, sy, 0), under = Object.entries(F.FOOT).find(([k, r]) => inR(g[0], g[1], r)) || F.CHAIRS.map((c, k) => ['silla' + k, [c.x - F.CH.hw, c.y - F.CH.hd, c.x + F.CH.hw, c.y + F.CH.hd]]).find(([k, r]) => inR(g[0], g[1], r));
  return { on: g[0] < 0 || g[1] < 0 ? 'wall' : 'floor', w: g, under: under ? under[0] : null };
}

/* ---------- the design: what moves and why (make() reads it). Every move is an exact piece of comer.js and its replacement ----------
   THE RULE (layout). The table is long along world x: a row level on the old screen cannot lie on it. So every place AT the table (the four
   seats and whoever sits there, the plates and cups in front of them, the lane behind the chairs, the children at the table's back corners,
   the frog's places beside a seated one's plate) steps down half a row a pixel to the right, round column 118 (SY(x, y) = y + (x - 118) / 2:
   La mesa's own four chairs, set .218 nearer on both world axes, i.e. 4 rows lower: comer-set.html DS, land there). Every other place keeps its old screen point if what stands there stands on what it stood on (a
   thing or the frog on the cloth; a person on clear floor), else it moves the least distance that does (moves, each named with its reason).
   Paths: whoever goes behind the table walks round its right end (the left end runs off the picture at the front); whoever comes in to sit,
   or leaves from behind, comes and goes by the doorway in the left wall (La mesa's) */
const SYC = 118, SY = (x, y) => y + (x - SYC) / 2;
function geometry(E, F) {
  const P = (x, y, z = 0) => { const p = E.project(x, y, z); return [p.sx, p.sy]; }, T = F.TBL;
  const top = [P(T.x0, T.y0, T.z), P(T.x1, T.y0, T.z), P(T.x1, T.y1, T.z), P(T.x0, T.y1, T.z)];   // far-left, far-right, near-right, near-left
  const line = (a, b) => { const k = (b[1] - a[1]) / (b[0] - a[0]); return x => a[1] + k * (x - a[0]); };
  const far = line(top[0], top[1]), near = line(top[3], top[2]), left = line(top[0], top[3]), right = line(top[1], top[2]);
  const dz = T.z * E.COS * E.S;   // the floor under an edge of the top lies this many rows lower
  // a thing's foot row at (x, y), hw its half width: both ends of its foot on the cloth with m px to spare
  const onTop = (x, y, hw, m = 2) => [x - hw, x + hw].every(xx => y >= far(xx) + m && y <= near(xx) - m && y >= left(xx) + m && y <= right(xx) - m);
  // a person's feet at (x, y): on clear floor (not under the table, a counter, the stove or a chair) with .12 to spare
  const clear = (x, y, m = .12) => { const g = E.atZ(x, y - 1, 0), inR = (r, mm) => g[0] >= r[0] - mm && g[0] <= r[2] + mm && g[1] >= r[1] - mm && g[1] <= r[3] + mm;
    if (g[0] < 0 || g[1] < 0) return false; if (Object.values(F.FOOT).some(r => inR(r, m))) return false; return !F.CHAIRS.some(c => inR([c.x - F.CH.hw, c.y - F.CH.hd, c.x + F.CH.hw, c.y + F.CH.hd], .05)); };
  const least = (x, y, ok) => { if (ok(x, y)) return [x, y]; for (let r = 1; r < 90; r++) { let best = null; for (let k = 0; k < 360; k += 3) { const a = k * Math.PI / 180, p = [R(x + r * Math.cos(a)), R(y + r * Math.sin(a))]; if (ok(p[0], p[1]) && (!best || Math.hypot(p[0] - x, p[1] - y) < Math.hypot(best[0] - x, best[1] - y))) best = p; } if (best) return best; } throw new Error('least: none near ' + [x, y]); };
  // the run's tops (the stove and the counter beside it, on the back wall; the counter along the left wall): a thing's foot row there
  const runTop = (x, hw, face) => { const fr = face === 'x' ? xx => P(.9, .9 + (E.OX - xx) / (E.S / E.R2) - .9 + .9, F.K.CZ)[1] : null; return fr; };
  return { P, top, far, near, left, right, dz, onTop, clear, least, T };
}
function designMoves(E, F) {
  const Gm = geometry(E, F), P = Gm.P;
  const leastTop = (x, y, hw) => Gm.least(x, y, (a, b) => Gm.onTop(a, b, hw));
  const leastFloor = (x, y) => Gm.least(x, y, (a, b) => Gm.clear(a, b));
  // the numbers the port's comer.js gains (line 21): the table's top and what is behind it on the new screen
  const L = { far: Gm.far(0), near: Gm.near(0), left: Gm.left(0), right: Gm.right(0) };   // y at x = 0 of each edge's line (far and near rise .5 a pixel, the ends fall .5)
  const ENT = [Math.floor(L.far) - 3, Math.ceil(L.near) + 3, Math.floor(L.left) - 3, Math.ceil(L.right) + 3];
  const FARF = Math.floor(L.far + Gm.dz) - 2, LEFTF = Math.ceil(L.left + Gm.dz) + 5;
  const XP = 202, DOOR = P(.15, 2.1, 0).map(R), PB = P(1.25, 3.1, 0).map(R);
  const NUM = { SYC, XP, DOOR, PB, ENTOP: ENT, DETRAS: { far: FARF, left: 100, passage: LEFTF, right: 215 } };
  GEO = { detras: (x, y) => (y < FARF + x / 2 || (x < 80 && y < LEFTF - x / 2)) && y > 100 - x / 2 && x < 215, entop: (x, y) => y >= ENT[0] + x / 2 && y <= ENT[1] + x / 2 && y >= ENT[2] - x / 2 && y <= ENT[3] - x / 2 };
  // the new places (old screen point -> new), each with its reason
  const NP = {}, place = (k, old, nw, why) => { NP[k] = { old, new: nw.map(R), why }; return NP[k].new; };
  const tp = (k, old, hw, why) => place(k, old, leastTop(old[0], old[1], hw), why || 'on the cloth: the least move that stands it wholly on the table\'s top');
  const fl = (k, old, why) => place(k, old, leastFloor(old[0], old[1]), why || 'on clear floor: the least move off the table\'s foot');
  // the stove's and the counters' tops (the old stood things on the old stove's front and the old counter)
  const runRow = (x, hw) => { const yf = xx => P(F.STX + (xx - P(F.STX, F.K.SD, F.K.CZ)[0]) / (E.S / E.R2) + 0, F.K.SD, F.K.CZ)[1]; return R(Math.min(yf(x - hw), yf(x + hw)) - 2); };
  // story 33
  const CE33 = place('CE33', [84, 146], [90, 147], 'the basket of rolls: at the near edge of the cloth, within the arm of the one who asks (on the world\'s axes the cloth\'s near edge at the left is 20 rows higher than the old front)');
  const BU33 = place('BU33', [112, 164], [150, 166], 'the butter dish at the cloth\'s near edge, the frog\'s place to its left (x - 20) on it too, clear of the basket and of where the frog waits');
  const CH33 = place('CH33', [160, 164], [162, 150], 'the chocolate dish on the cloth, the frog\'s place to its left on it too, behind the butter (the cloth\'s near edge at the right falls away)');
  const HOME33 = place('HOME33', [82, 174], [118, 165], 'the frog\'s place at the cloth\'s near edge, to the right of the one who asks as the old (the old place is in front of the table here)');
  const FETCH33 = place('FETCH33', [112, 152], [118, 148], 'where the frog takes a roll from the basket, to its right: on the cloth, within his arm');
  const HO33 = place('HO33', [66, 158], [97, 155], 'where a roll passes from the asker\'s hand to the frog\'s: between them, within both arms');
  const PA33S = place('PA33S', [146, 150], [102, 157], 'abuela\'s plate at the start, at the near edge of the cloth: she reaches it from the floor in front of the table');
  const PA33 = place('PA33', [136, 150], [92, 152], 'where abuela slides her plate to: 10 px left as the old, along the near edge');
  const LEPN = place('LEP.nino', [58, 170], [78, 181], 'a child who asks: on clear floor in front of the table\'s near edge, near enough to reach the basket');
  const LEPA = place('LEP.adulto', [52, 184], [72, 184], 'a grown-up who asks: as a child');
  const EST_L = place('EST33.luis', [72, 126], [71, 108], 'Luis at the table\'s back left corner: in the passage between the counter and the table\'s left end (the sheared point is inside the counter)');
  const EST_LP = place('EST33.luis.pl', [74, 124], [74, R(SY(74, 124))], 'his plate at the cloth\'s far left corner (the rule)');
  const EST_C = place('EST33.carmen', [180, 126], [190, R(SY(190, 126))], 'Carmen behind the table by its far right corner (the rule), 10 px right: clear of papá\'s shoulder, beside him rather than behind him (sorted by her own row, as the old)');
  const EST_CP = place('EST33.carmen.pl', [180, 124], [180, R(SY(180, 124))], 'her plate at the cloth\'s far right (the rule)');
  const TRAY = place('bandeja', [213, 121], [200, 91], 'the tray of rolls on the stove\'s top (the kit\'s stove, on the back wall behind the table\'s right end)');
  const ASIDE = place('aparte33', [150, 160], [124, 162], 'the frog steps aside to the right of the basket (turno33), left of the butter and the chocolate: the chocolate dish stands behind his place here (it is drawn before him), so he waits to its left, clear of it');
  const TIP = place('tip33', [52, 176], [CE33[0] - 34, CE33[1] + 31], 'where abuela tips the tray into the basket: as the old, relative to the basket');
  const ABLP = place('final33.lp', [54, 170], [66, 176], 'where abuela takes the last roll from the basket (final33): on clear floor within her arm of it');
  const ABPL = fl('final33.plato', [PA33[0] - 2, 183]);
  const ABPLS = fl('plato33', [PA33S[0] - 2, 184]);
  // story 34
  const OLLA = tp('OLLA', [134, 158], 12, 'the pot of rice on the cloth');
  const FU34 = tp('FU34', [96, 160], 14, 'the platter\'s place on the cloth');
  const PLUIS = place('PLUIS', [100, 172], [126, 177], 'Luis\'s plate on the cloth\'s near edge, 11 px to the right of where he stands (the old: 18 px left): there the near edge is low enough that his fork goes to it and to his mouth beside his face, not across it (the cloth\'s near edge falls to the right)');
  const PRANA = place('PRANA', [150, 174], [146, 176], 'the frog\'s small plate on the cloth\'s near edge, right of Luis\'s, his fork beside it on the cloth too');
  const CASA34 = place('CASA34', [172, 168], [160, 175], 'the frog\'s place in story 34: on the cloth by its near right corner, beside his plate: clear of abuela\'s serving spoon at the right end and of papá\'s fork at his plate (the old point is at the right end\'s edge, under papá\'s fork)');
  const EAT34 = place('EAT34', [162, 176], [154, 174], 'where the frog eats at his plate, on the cloth, beside it (behind its right half)');
  const LUIS34 = place('LUIS34', [118, 190], [108, 196], 'Luis stands on clear floor in front of the cloth\'s near edge, 18 px left of his plate as the old has him 18 px right of it (his fork goes up to it and to his mouth beside his face; the floor under the near edge falls to the right)');
  const PLAT34 = place('PLAT34', [213, 118], [204, 94], 'the platter waits on the stove\'s top (the kit\'s stove and the counter beside it)');
  const CONT34 = place('CONT34', [58, 117], [214, 98], 'where a plate is set on a counter\'s top: the counter beside the stove (the counter along the left wall is behind the table\'s left end: whoever stands at it is hidden from the waist down)');
  const CONTP = place('CONT34.pie', [49, 152], [190, 124], 'where Carmen stands to set it there: in front of that counter, behind the table');
  const ENC34 = fl('ENC34', [196, 184], 'where Luis meets abuela for the big spoon: at the right of the table\'s right end, on clear floor');
  const TIPR = tp('tipa34.rana', [144, 172], 10, 'where the frog hands the spoon back to Luis: on the cloth');
  // story 35
  const K1 = tp('K1', [76, 170], 8, 'Luis\'s cup of milk on the cloth');
  const K2 = tp('K2', [100, 170], 8, 'Carmen\'s cup of milk on the cloth');
  const AZU = place('AZU', [138, 170], [128, 178], 'the sugar bowl (with its lid beside it) on the cloth\'s near edge, 8 rows nearer as the seats\' row steps there (SY), 10 px left so that its lid stays on the cloth and abuela can stand in front of it: under the frog where he sugars papá\'s cup, not over him');
  const TRANA = tp('TRANA', [172, 170], 8, 'the frog\'s cup on the cloth');
  const GRECA35 = place('GRECA35', [152, 162], (() => { const g = leastTop(152, 166, 7); return [g[0], g[1] - 4]; })(), 'the little coffee pot at the right of the table (its foot GRECA35[1] + 4), on the cloth');
  const GRECA35B = tp('GRECA35B', [158, 178], 7, 'where abuela sets the little coffee pot down for the frog, on the cloth');
  const TABU = tp('TABU', [186, 154], 8, 'abuela\'s cup at the right end of the cloth');
  const CASA35 = tp('CASA35', [110, 166], 10, 'the frog\'s place in story 35, on the cloth');
  const CAFE35 = place('CAFE35', [199, 118], [194, 93], 'the big coffee pot on the stove\'s top, at its front left between the burners (round 2: its whole foot on the top face, its lid under the hood)');
  const CAZO35 = place('CAZO35', [218, 118], [212, 91], 'the milk pan on the stove\'s top beside the coffee pot, at its right corner (round 2: on the stove as the old, its whole foot on the top face)');
  const AFOGON = place('AFOGON', [208, 153], [174, 114], 'where abuela stands to take something off the stove\'s top: on the floor at the stove\'s front left corner (in front of it her face would be under the hint hand of the second answer card on the wall above)');
  place('STOOL', [210, 178], [206, 184], 'abuela\'s stool, 4 px left and 6 rows nearer: she sits on it wholly inside the view with 3 px to spare, clear of the table\'s right end');
  place('SIDE34', [194, 166], [204, 166], 'abuela\'s way from the stove to the front: right of the table\'s right end (straight down from there she passes clear of its corner)');
  return { NP, NUM, XP, DOOR, PB, leastTop, leastFloor, Gm };
}
// the edits of comer.js: one move a line (several replacements in it), the line's own text up to its comment
function designEdits(E, F, D) {
  const N = k => D.NP[k].new, A = k => '[' + N(k).join(',') + ']', byLine = new Map();
  const srcOf = L => LINES[L - 1].replace(/\s{2,}\/\/ .*$/, '').trim();
  const ed = (key, pairs, why, pts, act = '*') => {
    const L = typeof key === 'number' ? key : lineOf(key); let e = byLine.get(L);
    if (!e) { const src = srcOf(L), same = LINES.map((l, i) => srcOf(i + 1) === src ? i + 1 : 0).filter(Boolean); if (COMER_JS.split(src).length !== same.length + 1) throw new Error('design: line ' + L + ' is not unique'); e = Object.assign({ line: L, act, src, to: src, why: [], pts: [] }, same.length > 1 ? { lines: same } : {}); byLine.set(L, e); }
    for (const [a, b] of pairs) { if (!e.to.includes(a)) throw new Error('design: line ' + L + ' does not hold ' + a); e.to = e.to.split(a).join(b); }
    e.why.push(why); if (pts) e.pts.push(...pts); };
  const fn = (first, n, to, why) => { const L = lineOf(first), src = LINES.slice(L - 1, L - 1 + n).join('\n').replace(/\s{2,}\/\/ [^\n]*$/gm, ''); if (COMER_JS.split(src).length !== 2) throw new Error('design: ' + first); byLine.set(L, { line: L, lines: Array.from({ length: n }, (_, i) => L + i), act: '*', src, to, why: [why], pts: [] }); };
  const NU = D.NUM, EN = NU.ENTOP, DT = NU.DETRAS, Gm = D.Gm;
  const NF = Math.ceil(Gm.near(0) + Gm.dz) + 3, RF = Math.ceil(Gm.right(0) + Gm.dz) + 3, FF = Math.floor(Gm.far(0) + Gm.dz) - 3, LF = Math.floor(Gm.left(0) + Gm.dz) - 3;
  ed('const FILA=124,MED=148,FREN=170,TZ=173,ASIENTO=132,ATRAS=122,FR=212,FLO=154;', [['ATRAS=122', 'ATRAS=118'], ['FLO=154;', 'FLO=154,SY=(x,y)=>y+(x-' + SYC + ')/2,XP=' + NU.XP + ',DOOR=[' + NU.DOOR + '],PB=[' + NU.PB + ']' +
    ',DETRAS=(x,y)=>(y<' + DT.far + '+x/2||(x<80&&y<' + DT.passage + '-x/2))&&y>' + DT.left + '-x/2&&x<' + DT.right +
    ',ENTOP=(x,y)=>y>=' + EN[0] + '+x/2&&y<=' + EN[1] + '+x/2&&y>=' + EN[2] + '-x/2&&y<=' + EN[3] + '-x/2' +
    ',MESAPIE=(x,y)=>y>' + FF + '+x/2&&y<' + NF + '+x/2&&y>' + LF + '-x/2&&y<' + RF + '-x/2' +
    ',FRONTROW=(x,y)=>{while(MESAPIE(x,y)&&y<212)y++;return y;}' +
    ',LIBRE=(who,tx,ty,h)=>{const Fc=[];for(const k in W.gente){const p=W.gente[k];if(k!==who&&p&&p.vis!==0)Fc.push([R(p.x)-6,R(p.y)-alto(k)+7-(k==="abuela"&&p.sent?1:0)+R(p.dy||0),12,10]);}if(who!=="coqui"&&W.cq&&W.cq.vis){const b=frogBox(W.cq);Fc.push([b.x+2,b.y+R(W.cq.dy),b.w-4,R(b.h*.6)]);}for(const[s,dy]of ' + JSON.stringify(TALK) + '){const x=tx+s*(h+16),y=ty+dy,r=[x-9,y-16,19,13];if(r[0]>=cam[0]&&r[1]>=0&&r[0]+r[2]<=cam[0]+cam[2]&&!Fc.some(f=>f[0]<r[0]+r[2]&&r[0]<f[0]+f[2]&&f[1]<r[1]+r[3]&&r[1]<f[1]+f[3]))return [x,y];}return [tx,ty];}' +
    ',CARTAS=W=>{const n=W.resp.length,Fc=[],on=(a,b)=>a[0]<b[0]+b[2]&&b[0]<a[0]+a[2]&&a[1]<b[1]+b[3]&&b[1]<a[1]+a[3];for(const k in W.gente){const p=W.gente[k];if(p&&p.vis!==0)Fc.push([R(p.x)-6,R(p.y)-alto(k)+7-(k==="abuela"&&p.sent?1:0)+R(p.dy||0),12,10]);}' +
    'for(const cx of ' + JSON.stringify(CARDS.cx) + '){let ok=1;for(let i=0;i<n&&ok;i++){const c=n>2?[R(cx-70+i*50),' + CARDS.y + ',40,36]:i===0?[R(cx-50),' + CARDS.y + ',40,36]:[R(cx+10),' + CARDS.y + ',40,36],fr=[c[0]-12,c[1]-12,64,60],hx=c[0]+8,hy=c[1]+30;if(W.tarjeta&&on([c[0]-2,c[1]-2,44,40],[cam[0]+' + (BOARD[0] + 1) + ',' + (BOARD[1] + 1) + ',' + BOARD[2] + ',' + BOARD[3] + ']))ok=0;' +
    'for(const f of Fc){if(on(fr,[f[0]-2,f[1]-6,16,16]))ok=0;for(const o of [0,9])HAND.forEach((rw,j)=>{for(let x=0;x<12;x++)if(rw[x]!=="."&&on([hx+x*3,hy+j*3+o,3,3],f))ok=0;});if(!ok)break;}}if(ok)return [cx,' + CARDS.y + '];}return [' + CARDS.cx[0] + ',' + CARDS.y + '];}' +
    ',atras=async(id,x,y)=>{const p=G(id),ln=SY(p.x,ATRAS);if(p.y>ln+3&&p.x>80&&!(x>XP-8&&p.x>XP-8)){if(SILLA.some(s=>Math.abs(s-p.x)<6))await mueve(id,p.x+12,SY(p.x+12,ASIENTO-3));await mueve(id,G(id).x,SY(G(id).x,ATRAS));}const q=G(id),a=q.x<80&&q.y>PB[1]-1,b=x<80&&y>PB[1]-1;if(b&&!a&&q.x>86)await mueve(id,86,SY(86,ATRAS));if(a!==b)await mueve(id,PB[0],PB[1]);await mueve(id,x,y);};']],
    'the new geometry, for the lines below: SY(x, y), a row at the table stepping down half a row a pixel to the right (round x ' + SYC + '); XP, the column of the way round the table\'s right end; DOOR, the doorway in the left wall (whoever comes in to sit or leaves from behind); PB, the passage between the counter and the table\'s left end; DETRAS, a place behind the table (or in that passage); ENTOP, a foot on the cloth; MESAPIE, a floor point under the table; atras, a walk behind the table (by the lane behind the chairs and the passage)');
  ed('const LE=[66,190],CAR=[46,194],FOGON=[208,168],AFOGON=[208,153],DER=[208,176],PUERTA=[0,190];', [['AFOGON=[208,153]', 'AFOGON=' + A('AFOGON')]], D.NP.AFOGON.why, [['abuela', [208, 153], N('AFOGON')]]);
  ed('const caja=id=>{', [['MESA[1]+26-(R(p.y)-h)', 'SY(R(p.x),MESA[1]+14)-(R(p.y)-h)']], 'caja: a seated one\'s box reaches down to 6 rows over his feet, at his column (SY): his chest in its middle as the old (the table\'s far edge is 14 rows over a sitter\'s feet here, 20 in the old), and its hint frame clear of the frog on the cloth in front');
  ed('const enMesa=o=>', [['o.y>=FILA-1&&o.y<=FREN+3&&o.x>MESA[0]-8&&o.x<MESA[0]+MESA[2]+8', 'ENTOP(o.x,o.y)']], 'enMesa: a thing on the table is one whose foot is on the cloth (the new table\'s top)');
  ed('const detrasMesa=p=>', [['p.y<TZ&&p.x>62&&p.x<190', 'DETRAS(p.x,p.y)&&p.x<186&&p.y-(p.x-' + SYC + ')/2<ATRAS+3']], 'detrasMesa: behind the table is behind the chairs (the lane, the passage at its left end), short of the stove (whoever stands at the stove is drawn after what stands on its top, as the old); whoever stands at a chair, getting up or sitting down, is sorted by his row (capa) and drawn after the chairs');
  ed('const capa=p=>', [['(p.sent||p.est)?[p.y,TZ+.9]:detrasMesa(p)?[40+p.y/100,40.5+p.y/100]', '(p.sent||p.est)?[p.x<186?p.y-(p.x-' + SYC + ')/2+p.x/10000:p.y,TZ+.9]:detrasMesa(p)?[40+(p.y-(p.x-' + SYC + ')/2)/100,40.5+(p.y-(p.x-' + SYC + ')/2)/100]']], 'capa: whoever sits, stands at a corner or walks behind the table (left of x 186: abuela on her stool keeps her own row, as the old) is sorted by his row at the table without its step, and of two in one row the one to the right (nearer on the world\'s x) is drawn over the other (y - (x - ' + SYC + ') / 2): who is behind whom along the table is as the old');
  ed('const HIJA=[213,204],OLLA=', [['OLLA=[134,158]', 'OLLA=' + A('OLLA')], ['PLUIS=[100,172]', 'PLUIS=' + A('PLUIS')], ['PRANA=[150,174]', 'PRANA=' + A('PRANA')], ['CASA34=[172,168]', 'CASA34=' + A('CASA34')], ['EAT34=[162,176]', 'EAT34=' + A('EAT34')], ['LUIS34=[118,190]', 'LUIS34=' + A('LUIS34')], ['FU34=[96,160]', 'FU34=' + A('FU34')], ['PLAT34=[213,118]', 'PLAT34=' + A('PLAT34')], ['CONT34=[58,117]', 'CONT34=' + A('CONT34')], ['SIDE34=[194,166]', 'SIDE34=' + A('SIDE34')]],
    'story 34\'s places: ' + ['OLLA', 'PLUIS', 'PRANA', 'CASA34', 'EAT34', 'LUIS34', 'FU34', 'PLAT34', 'CONT34', 'SIDE34'].map(k => k + ' ' + D.NP[k].why).join('; '), ['OLLA', 'PLUIS', 'PRANA', 'CASA34', 'EAT34', 'LUIS34', 'FU34', 'PLAT34', 'CONT34', 'SIDE34'].map(k => [k === 'LUIS34' ? 'luis' : k === 'CASA34' || k === 'EAT34' ? 'cq.feet' : 'cosa', D.NP[k].old, N(k)]));
  ed('async function aEncuentro34(){', [['[[l.x,FR],[184,FR],[ENC34[0],ENC34[1]]]', '[[l.x,FR],[ENC34[0],FR],[ENC34[0],ENC34[1]]]']], 'aEncuentro34: Luis walks along the front to the right of the table\'s right end');
  ed('async function deEncuentro34(){', [['[[184,FR],[LUIS34[0],FR]', '[[ENC34[0],FR],[LUIS34[0],FR]']], 'deEncuentro34: and back');
  ed('const ENC34=[192,182];', [['[192,182]', A('ENC34')]], D.NP.ENC34.why, [['luis', [192, 182], N('ENC34')]]);
  { const c = N('CASA34');
    ed('const NUBE34={barriga:', [['[146,84]', '[165,55]'], ['[160,100]', '[173,67]'], ['AIM34=[172,141]', 'AIM34=[' + c[0] + ',' + (c[1] - 27) + ']']], 'the frog\'s thought (story 34): over the stove\'s side, right of the seated (over the table it would cover their faces: their row steps up to the left), under the answer cards (2 rows clear of them); its trail to his head (AIM34, as the old relative to his place)'); }
  ed('    if(TALK==="coqui"&&q.vis){const b=frogBox(q),fx=b.x+(b.w>>1),fy=b.y+R(q.dy);hab(fx,fy-3,fx);}', [['hab(fx,fy-3,fx);', '{const u=LIBRE("coqui",fx,fy-3,b.w>>1);hab(u[0],u[1],u[0]);}']], 'with the words hidden, the frog\'s empty bubble goes to the first place of talk.places clear of every other face (LIBRE)');
  ed('    else if(TALK&&Gt[TALK]&&Gt[TALK].vis!==0){const t=talkAt(TALK,W),p=Gt[TALK];', [['else hab(t[0],t[1]-1,t[0]);', 'else{const u=LIBRE(TALK,t[0],t[1]-1,6);hab(u[0],u[1],u[0]);}']], 'with the words hidden, a speaker\'s empty bubble goes to the first place of talk.places clear of every other face (LIBRE)');
  ed('function draw(c,W,a){const q=W.cq,Gt=W.gente||{};c.imageSmoothingEnabled=false;', [['c.imageSmoothingEnabled=false;', 'c.imageSmoothingEnabled=false;if(W.resp)W.respEn=CARTAS(W);']], 'the answer cards (W.respEn) are placed at every frame while the frog chooses: on the wall above the heads, right of the rounds card, at the first centre of cards.cx whose hint hands fall on no face (CARTAS); the old place [130, 22] is left of the rounds card\'s right end and its hands would be on the seated faces here (their row steps up to the left)');
  ed('const lado34=px=>', [['{fx:px-17,fy:138,izq:0}', '{fx:px-17,fy:SY(px-17,138),izq:0}'], ['{fx:px+17,fy:138,izq:1}', '{fx:px+17,fy:SY(px+17,138),izq:1}']], 'lado34: the frog beside a seated one\'s plate stands at the table\'s row there (SY)');
  ed('const origen=()=>{', [['fu.x<200', 'fu.y>PLAT34[1]+20']], 'origen: the platter is on the table (not on the stove\'s top) when it stands lower than the stove\'s top');
  ed('const K1=[76,170],K2=', ['K1', 'K2', 'AZU', 'TRANA', 'GRECA35', 'GRECA35B', 'TABU', 'CASA35', 'CAFE35', 'CAZO35', 'STOOL'].map(k => [k + '=[' + D.NP[k].old.join(',') + ']', k + '=' + A(k)]).concat([['NUBE35=[102,104]', 'NUBE35=[' + (N('CASA35')[0] - 8) + ',' + (N('CASA35')[1] - 62) + ']'], ['AIM35=[110,139]', 'AIM35=[' + N('CASA35')[0] + ',' + (N('CASA35')[1] - 27) + ']']]),
    'story 35\'s places: ' + ['K1', 'K2', 'AZU', 'TRANA', 'GRECA35', 'GRECA35B', 'TABU', 'CASA35', 'CAFE35', 'CAZO35', 'STOOL'].map(k => k + ' ' + D.NP[k].why).join('; ') + '; NUBE35 and AIM35 (the frog\'s thought) as the old relative to CASA35', ['K1', 'K2', 'AZU', 'TRANA', 'GRECA35B', 'TABU', 'CAFE35', 'CAZO35', 'STOOL'].map(k => ['cosa', D.NP[k].old, N(k)]).concat([['cq.feet', [110, 166], N('CASA35')]]));
  ed('for(let x=Math.round(tx-44);x<=tx+48;x+=2){if(Math.abs(x-tx)<14)continue;', [['if(Math.abs(x-tx)<14)continue;', 'if(Math.abs(x-tx)<14||MESAPIE(x,y))continue;']], 'puestoVierte: whoever pours stands on clear floor (not under the table)');
  ed('const FRENTE=[176,180,184,188,192];', [['[176,180,184,188,192]', '[176,180,184,188,192,196,200,204,208]']], 'FRENTE: the rows where abuela can stand round the table go down to 208 (in front of the table\'s right part the clear floor begins lower: its near edge falls to the right)');
  ed('const detrasOK=p=>', [['p.y<148&&p.x>66&&p.x<190', 'DETRAS(p.x,p.y)']], 'detrasOK: behind the table (DETRAS)');
  fn('async function detras(id,x,y){', 4, 'async function detras(id,x,y){const p=G(id);y=y==null?SY(x,ATRAS):y;\n  if(detrasOK(p)){await atras(id,x,y);return;}\n  const pts=[];if(p.x<XP-6&&p.y<FR-2)pts.push([p.x,FR]);if(p.x<XP-6)pts.push([XP,FR]);pts.push([Math.max(XP,p.x),SY(Math.max(XP,p.x),ATRAS)]);await ruta(id,pts);await atras(id,x,y);}',
    'detras: to a place behind the table along the floor in front of it, round its right end (its left end runs off the picture at the front) and along the lane behind the chairs (atras)');
  fn('async function delante(id,x,y){', 4, 'async function delante(id,x,y){const p=G(id);\n  if(!detrasOK(p)){await mueve(id,x,y);return;}\n  if(p.x<XP-6)await atras(id,XP,SY(XP,ATRAS));const pts=[[Math.max(XP,G(id).x),FR]];if(x<XP-8)pts.push([x,FR]);pts.push([x,y]);await ruta(id,pts);}',
    'delante: from behind the table to the floor in front of it: along the lane, round its right end, along the front');
  fn('async function sale(id){', 4, 'async function sale(id){const p=G(id);if(p.vis===0)return;p.sent=0;p.est=0;p.come=null;p.cara=null;p.pose="idle";p.abre=0;\n  if(detrasOK(p)){await atras(id,DOOR[0]+6,DOOR[1]+8);await mueve(id,DOOR[0],DOOR[1]);p.vis=0;p.x=PUERTA[0];p.y=190;return;}\n  else if(p.x>84&&p.y<FR-2)await mueve(id,p.x,FR);\n  await mueve(id,PUERTA[0],Math.max(190,Math.min(p.y,FR)));p.vis=0;}',
    'sale: whoever is behind the table leaves by the doorway in the left wall (La mesa\'s); whoever is in front walks out at the left, as the old');
  ed('async function sienta(id,i){', [['p.x=PUERTA[0];p.y=190;', 'p.x=DOOR[0];p.y=DOOR[1];']], 'sienta: whoever comes in to sit comes in by the doorway (behind the table)');
  ed('  await detras(id,SILLA[i]-3,ATRAS);await mueve(id,SILLA[i],ASIENTO,3);', [['detras(id,SILLA[i]-3,ATRAS)', 'detras(id,SILLA[i]+12,SY(SILLA[i]+12,ATRAS))'], ['mueve(id,SILLA[i],ASIENTO,3)', 'mueve(id,SILLA[i]+12,SY(SILLA[i]+12,ASIENTO-3),2);await mueve(id,SILLA[i],SY(SILLA[i],ASIENTO),2)']], 'sienta: along the lane behind the chairs to the gap beside his chair, down it, and sideways onto the seat (behind the seat is the chair\'s back), at the table\'s row (SY)');
  ed('  p.sent=1;p.y=ASIENTO;p.dy=-4;', [['p.y=ASIENTO;', 'p.y=SY(SILLA[i],ASIENTO);']], 'sienta: as above');
  ed('  p.sent=0;p.y=ASIENTO;p.dy=0;await wait(TICK*4);', [['p.y=ASIENTO;', 'p.y=SY(p.x,ASIENTO);']], 'levanta: the seat at the table\'s row (SY)');
  ed('  await mueve(id,p.x,ASIENTO-3,1);await wait(TICK*2);await mueve(id,p.x,ATRAS,2);await delante(id,x,y);}', [['mueve(id,p.x,ASIENTO-3,1)', 'mueve(id,p.x+12,SY(p.x+12,ASIENTO-3),1)'], ['mueve(id,p.x,ATRAS,2)', 'mueve(id,p.x,SY(p.x,ATRAS),2)']], 'levanta: he steps out of his chair sideways, into the gap beside it (behind him is the chair\'s back), then back to the lane behind the chairs, at the table\'s row (SY)');
  ed('const LEP=id=>', [['[58,170]:[52,184]', A('LEP.nino') + ':' + A('LEP.adulto')]], 'LEP: ' + D.NP['LEP.nino'].why, [['nino', [58, 170], N('LEP.nino')], ['adulto', [52, 184], N('LEP.adulto')]]);
  ed('const CE33=[84,146],BU33=', ['CE33', 'BU33', 'CH33', 'HOME33', 'FETCH33', 'HO33', 'PA33S', 'PA33'].map(k => [k + '=[' + D.NP[k].old.join(',') + ']', k + '=' + A(k)]).concat([['PA0=[SILLA[1],FILA]', 'PA0=[SILLA[1],SY(SILLA[1],FILA)]']]),
    'story 33\'s places: ' + ['CE33', 'BU33', 'CH33', 'HOME33', 'FETCH33', 'HO33', 'PA33S', 'PA33'].map(k => k + ' ' + D.NP[k].why).join('; ') + '; PA0, abuela\'s place at the table, at the table\'s row (SY)', ['CE33', 'BU33', 'CH33', 'PA33S', 'PA33'].map(k => ['cosa', D.NP[k].old, N(k)]).concat([['cq.feet', [82, 174], N('HOME33')], ['cq.feet', [112, 152], N('FETCH33')]]));
  ed('const EST33={luis:', [['luis:{x:72,y:126,pl:[74,124]', 'luis:{x:' + N('EST33.luis').join(',y:') + ',pl:' + A('EST33.luis.pl')], ['carmen:{x:180,y:126,pl:[180,124]', 'carmen:{x:' + N('EST33.carmen').join(',y:') + ',pl:' + A('EST33.carmen.pl')]], 'EST33: ' + D.NP['EST33.luis'].why + '; ' + D.NP['EST33.carmen'].why, [['luis', [72, 126], N('EST33.luis')], ['carmen', [180, 126], N('EST33.carmen')], ['cosa', [74, 124], N('EST33.luis.pl')], ['cosa', [180, 124], N('EST33.carmen.pl')]]);
  ed('async function vaEstacion(id){', [['p.x=PUERTA[0];p.y=190;', 'p.x=DOOR[0];p.y=DOOR[1];']], 'vaEstacion: a child who comes in to his corner comes in by the doorway (behind the table)');
  ed('  await mueveTiene(id,f,(dx-p.x)*d,p.y-(pl.y-1),3);W.cosas.push(', [['p.y-(pl.y-1),3)', 'p.y-(pl.y-1+(dx-pl.x)/2),3)'], ['y:pl.y-1})', 'y:pl.y-1+(dx-pl.x)/2})']], 'dejaTenedor: a fork laid by a plate lies along the table, at the table\'s row there (half a row a pixel)');
  ed('    const pl=(id,x)=>({id,k:"plato",x,y:FILA,rollos:[]});', [['y:FILA', 'y:SY(x,FILA)']], 'inicio33: each plate in front of its seat at the table\'s row (SY)');
  ed('{id:"bandeja",k:"bandeja",v:4,x:213,y:121,', [['x:213,y:121', 'x:' + N('bandeja').join(',y:')]], D.NP.bandeja.why, [['cosa', [213, 121], N('bandeja')]]);
  ed('await ruta("abuela",[[FOGON[0],FR],[PA33S[0]-2,FR],[PA33S[0]-2,184]]);', [['[PA33S[0]-2,184]', '[PA33S[0]-2,' + N('plato33')[1] + ']']], 'plato33: abuela stands on clear floor in front of her plate', [['abuela', [144, 184], [N('PA33S')[0] - 2, N('plato33')[1]]]]);
  // the frog's hops: counted on the old picture (HOPAT: each of his places on the new picture and the old place it stands for), so every walk takes
  // the old number of hops, whatever the new distance (the hop count is the old one between every pair of his places)
  if (D.HOPAT) ed('async function ranaA(x,y,h){', [['async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(6,Math.ceil(d/26))));}',
    'async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;const k=a=>HOPAT[R(a[0])+","+R(a[1])]||a,o=k([x,y]),f=k([q.x+16,q.y+27]),dd=Math.hypot(o[0]-f[0],o[1]-f[1]);await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(6,Math.ceil(dd/26))));}const HOPAT=' + JSON.stringify(D.HOPAT) + ';']],
    'ranaA: the frog takes the old number of hops: they are counted on the old picture (HOPAT: each of his places on the new picture, by its feet, and the old place it stands for, from the recorded runs played both ways), not on the new distance (his places stand where the table\'s top is, so the distances between them changed)');
  ed('    const lp=[54,170];await entra("abuela",lp[0],lp[1],1);', [['const lp=[54,170]', 'const lp=' + A('final33.lp')]], D.NP['final33.lp'].why, [['abuela', [54, 170], N('final33.lp')]]);
  ed('const aparte=ranaA(150,160);', [['ranaA(150,160)', 'ranaA(' + N('aparte33').join(',') + ')']], D.NP.aparte33.why, [['cq.feet', [150, 160], N('aparte33')]]);
  ed('await ruta("abuela",[[46,FR],[196,FR],[200,170],[AFOGON[0],AFOGON[1]]]);', [['[196,FR],[200,170]', '[XP,FR],[XP,SY(XP,ATRAS)]']], 'turno33: abuela walks along the front and round the table\'s right end to the stove (behind it)');
  ed('await ruta("abuela",[[200,170],[196,FR],[54,FR],[52,176]]);', [['[[200,170],[196,FR],[54,FR],[52,176]]', '[[XP,SY(XP,ATRAS)],[XP,FR],[54,FR],' + A('tip33') + ']']], 'turno33: and back with the tray to the basket', [['abuela', [52, 176], N('tip33')]]);
  ed('await ruta("abuela",[[54,FR],[PA33[0]-2,FR],[PA33[0]-2,183]]);', [['[PA33[0]-2,183]', '[PA33[0]-2,' + N('final33.plato')[1] + ']']], 'final33: abuela on clear floor in front of her plate', [['abuela', [134, 183], [N('PA33')[0] - 2, N('final33.plato')[1]]]]);
  ed('await detras("abuela",SILLA[SEAT33.abuela]-11,ASIENTO);', [['SILLA[SEAT33.abuela]-11,ASIENTO', 'SILLA[SEAT33.abuela]-11,SY(SILLA[SEAT33.abuela]-11,ASIENTO)']], 'final33: behind her seat at the table\'s row (SY)');
  ed('    W.gente={mama:{x:SILLA[0],y:ASIENTO,', [0, 1, 2].map(i => ['{x:SILLA[' + i + '],y:ASIENTO', '{x:SILLA[' + i + '],y:SY(SILLA[' + i + '],ASIENTO)']), 'inicio34: the seated at the table\'s row (SY)');
  ed('    const pl=(id,x,v)=>({id,k:"plato",x,y:FILA,', [['y:FILA', 'y:SY(x,FILA)']], 'inicio34: the plates at the table\'s row (SY)');
  { const t = N('tipa34.rana'); ed('await ranaA(144,172);await cucharaAR(sp,127,172,true,4);', [['ranaA(144,172)', 'ranaA(' + t.join(',') + ')'], ['cucharaAR(sp,127,172,', 'cucharaAR(sp,' + (t[0] - 17) + ',' + t[1] + ',']], D.NP['tipa34.rana'].why, [['cq.feet', [144, 172], t]]); }
  // the floor in front of what abuela works at: the first clear row at the old x (each from the old row down)
  const row = (x, y0) => { for (let y = y0; y <= 212; y++) if (Gm.clear(x, y)) return y; throw new Error('no clear floor at ' + x); };
  const NA = k => N(k), O = N('OLLA'), FU = N('FU34'), TR = N('TRANA'), GR = N('GRECA35'), GB = N('GRECA35B'), AZ = N('AZU'), TB = N('TABU'), CZ = N('CAZO35'), CP = N('CONT34.pie');
  ed('if(id==="mama"){await delante(id,188,206);p.dir=1;const bc=', [], 'levanta34: mamá at the baby\'s high chair: unchanged (clear floor right of the table)');
  ed('else if(llevaPlato){const it=await toma(id,pl,null,null,{n:3});', [['await delante(id,CONT34[0]-9,152)', 'await atras(id,' + CP.join(',') + ')']], 'levanta34: whoever takes a plate to the counter walks behind the table to the passage in front of the counter (' + D.NP['CONT34.pie'].why + ')', [['carmen', [49, 152], CP]]);
  ed('if(+o.plato){await delante(id,CONT34[0]-9,152);p.dir=-1;', [['await delante(id,CONT34[0]-9,152)', 'await atras(id,' + CP.join(',') + ')']], 'vuelve34: as levanta34');
  ed('      await detras(id,SILLA[seat]-8,ASIENTO);p.dir=1;await pon(', [['detras(id,SILLA[seat]-8,ASIENTO)', 'detras(id,SILLA[seat]-8,SY(SILLA[seat]-8,ASIENTO))'], ['SILLA[seat],FILA,4', 'SILLA[seat],SY(SILLA[seat],FILA),4']], 'vuelve34: her seat and her place at the table\'s row (SY)');
  ed('    const lw=ruta("luis",[[184,FR],[58,FR],[58,190]])', [['[[184,FR],', '[[ENC34[0],FR],']], 'turno34: Luis goes back along the front from the right of the table');
  { const y = row(FU[0], 184); ed('await ruta("abuela",[[SIDE34[0],SIDE34[1]],[192,FR],[FU34[0],FR],[FU34[0],184]]);', [['[192,FR]', '[SIDE34[0],FR]'], ['[FU34[0],184]', '[FU34[0],' + y + ']']], 'turno34: abuela with the platter, straight down the right of the table and along the front to its place, on clear floor in front of it', [['abuela', [96, 184], [FU[0], y]]]); }
  { const y = row(O[0] + 22, 182); ed('await mueve("abuela",OLLA[0]+22,182);', [['OLLA[0]+22,182', 'OLLA[0]+22,' + y]], 'turno34: abuela at the pot\'s right, on clear floor', [['abuela', [156, 182], [O[0] + 22, y]]]); }
  ed('const sirve=async id=>{const pl=ob("pl_"+id);await detras("abuela",pl.x+13,130);', [['pl.x+13,130', 'pl.x+13,SY(pl.x+13,130)']], 'turno34: abuela behind each seated one, at the table\'s row (SY)');
  { const y = row(O[0] - 14, 184); ed('ab.est=0;await delante("abuela",OLLA[0]-14,184);', [['OLLA[0]-14,184', 'OLLA[0]-14,' + y]], 'turno34: in front of the pot, on clear floor', [['abuela', [120, 184], [O[0] - 14, y]]]); }
  { const y = row(O[0] - 16, 186); ed('await mueve("abuela",OLLA[0]-16,186);', [['OLLA[0]-16,186', 'OLLA[0]-16,' + y]], 'turno34: between the pot and the platter, on clear floor', [['abuela', [118, 186], [O[0] - 16, y]]]); }
  { const y = row(O[0] - 22, 182); ed('await mueve("abuela",OLLA[0]-22,182);ab.dir=1;const pot2=', [['OLLA[0]-22,182', 'OLLA[0]-22,' + y]], 'turno34: at the pot\'s left, on clear floor', [['abuela', [112, 182], [O[0] - 22, y]]]); }
  ed('await ruta("abuela",[[OLLA[0]-22,FR],[186,FR],[FOGON[0]-2,176]]);', [['[186,FR]', '[FOGON[0]-2,FR]']], 'turno34: to the stove along the front and up the right of the table');
  { const y = row(FU[0] - 18, 184); ed('ab.dir=1;await mueve("abuela",FU34[0]-18,184);', [['FU34[0]-18,184', 'FU34[0]-18,' + y]], 'final34: abuela left of the platter, on clear floor', [['abuela', [78, 184], [FU[0] - 18, y]]]); }
  { const y = row(FU[0], 184); ed('await mueve("abuela",FU34[0],184);ab.dir=-1;const pf=', [['FU34[0],184', 'FU34[0],' + y]], 'final34: in front of the platter, on clear floor', [['abuela', [96, 184], [FU[0], y]]]); }
  ed('await mueveTiene("abuela",pf,-11,22,3);await detras("abuela",pl.x+16,130);', [['pl.x+16,130', 'pl.x+16,SY(pl.x+16,130)']], 'final34: behind papá, at the table\'s row (SY)');
  ed('ab.est=0;await delante("abuela",196,FR);await ruta("abuela",[[186,FR],[FOGON[0]-2,176]]);', [['delante("abuela",196,FR)', 'delante("abuela",XP,FR)'], ['[[186,FR],[FOGON[0]-2,176]]', '[[FOGON[0]-2,FR],[FOGON[0]-2,176]]']], 'final34: back round the table\'s right end to the stove');
  for (const k of ['  async trae35(o){', '  async turnoA35(o){']) { const L = lineOf(k) + (k.includes('trae35') ? 1 : 2); ed(L, [['detras("abuela",150,ATRAS)', 'detras("abuela",150,SY(150,ATRAS))'], ['mueve("abuela",126,ASIENTO-2)', 'mueve("abuela",126,SY(126,ASIENTO-2))']], (k.includes('trae35') ? 'trae35' : 'turnoA35') + ': abuela behind the table between the two men, at the table\'s row (SY)'); }
  ed('  async vuelve35(o){', [['await delante("abuela",AFOGON[0],AFOGON[1])', 'await atras("abuela",AFOGON[0],AFOGON[1])']], 'vuelve35: from behind the table to the stove, behind it too');
  { const y = row(GR[0] + 4, 190); ed('    await ruta("abuela",[[FOGON[0],FR],[GRECA35[0]+4,FR],[GRECA35[0]+4,190]]);ab.dir=-1;const it=await toma("abuela",jt,6,22', [['[GRECA35[0]+4,190]', '[GRECA35[0]+4,' + y + ']']], 'pote35: abuela in front of the little pot, on clear floor', [['abuela', [156, 190], [GR[0] + 4, y]]]); }
  { const y = row(GB[0] - 10, 190); ed('    await ruta("abuela",[[GRECA35B[0]-10,190]]);', [['[GRECA35B[0]-10,190]', '[GRECA35B[0]-10,' + y + ']']], 'pote35: in front of the frog, on clear floor', [['abuela', [148, 190], [GB[0] - 10, y]]]); }
  ed('const fx=izq?98:92,fy=148;await ranaA(fx,fy);', [['const fx=izq?98:92,fy=148;', 'const fx=t.x+(izq?22:-8),fy=t.y-22;']], 'vierte35: the frog pours into a child\'s cup from beside it, as the old relative to the cup (K1, K2 moved)');
  ed('  const fx=cxw<150?cxw-16:cxw+16,fy=146,iz=fx>cxw;', [['fx=cxw<150?cxw-16:cxw+16,fy=146', 'fx=cxw<=150?cxw-22:cxw+16,fy=SY(G(who).x,146)+(G(who).x<' + SYC + '?6:-6)']], 'azucarEn: the frog sugars the cup a seated man holds from its left (22 px, the old 16; at papá\'s raised cup too, which the old did from its right: there he would stand on papá\'s lap), on the cloth at the man\'s row stepped as his seat (SY), 6 rows nearer at abuelo\'s (clear of his chest) and 6 farther at papá\'s (clear of the cups and the sugar bowl at the cloth\'s near right)');
  ed('    W.gente={abuelo:{x:SILLA[0],y:ASIENTO,', [['{x:SILLA[0],y:ASIENTO', '{x:SILLA[0],y:SY(SILLA[0],ASIENTO)'], ['{x:SILLA[3],y:ASIENTO', '{x:SILLA[3],y:SY(SILLA[3],ASIENTO)']], 'inicio35: the two men at the table\'s row (SY)');
  ed('    W.cosas=[{id:"taburete",k:"taburete",x:STOOL[0],y:STOOL[1]},{id:"t_abuelo"', [['x:SILLA[0],y:FILA,', 'x:SILLA[0],y:SY(SILLA[0],FILA),'], ['x:SILLA[3],y:FILA,', 'x:SILLA[3],y:SY(SILLA[3],FILA),'], ['x:SILLA[0]-12,y:FILA-1', 'x:SILLA[0]-12,y:SY(SILLA[0]-12,FILA)-1'], ['x:SILLA[3]+12,y:FILA-1', 'x:SILLA[3]+12,y:SY(SILLA[3]+12,FILA)-1']], 'inicio35: the men\'s cups and their teaspoons at the table\'s row (SY)');
  const cz = N('CAZO35'), czRow = (() => { const a = 1.2 + (cz[0] - 4 - E.OX) / (E.S / E.R2); return R(E.project(a, 1.2, 0).sy); })();
  const reps = [['[TRANA[0]+26,190]', '[TRANA[0]+26,' + row(TR[0] + 26, 190) + ']'], ['[GRECA35[0]+4,190]', '[GRECA35[0]+4,' + row(GR[0] + 4, 190) + ']'], ['[AZU[0]+4,188]', '[AZU[0]+4,' + row(AZ[0] + 4, 188) + ']'], ['AZU[0]+4,188)', 'AZU[0]+4,' + row(AZ[0] + 4, 188) + ')'],
    ['[TABU[0]+12,178]', '[TABU[0]+12,' + row(TB[0] + 12, 178) + ']'], ['[CAZO35[0]-4,150]', '[CAZO35[0]-4,' + czRow + ']'], ['mueve("abuela",CAZO35[0]-4,150)', 'mueve("abuela",CAZO35[0]-4,' + czRow + ')'], ['delante("abuela",198,176)', 'delante("abuela",' + (TB[0] + 18) + ',' + row(TB[0] + 18, 176) + ')'], ['mostrar(jt,jt.x+4,190)', 'mostrar(jt,jt.x+4,FRONTROW(jt.x,190))']];
  for (let L = lineOf('/* ----- story 35: Café con azúcar ----- */'); L <= lineOf('async prueba(o){'); L++) { if (byLine.has(L)) { const e = byLine.get(L), prs = reps.filter(([a]) => e.to.includes(a)); if (prs.length) ed(L, prs, 'story 35: abuela on clear floor in front of the table (the first clear row at the old x)'); continue; } const prs = reps.filter(([a]) => LINES[L - 1].includes(a)); if (prs.length) ed(L, prs, 'story 35: where abuela stands in front of the table to pour, to take a pot or to set one down: on clear floor at the old x (the first clear row from the old one down); in front of the milk pan\'s counter, just in front of it'); }
  return { byLine, NF, RF, FF, LF };
}

/* ---------- the sheet ---------- */
const OLDBOX = { mesa: [60, 112, 132, 66], cocina: [32, 24, 196, 190], silla_papa: [152, 86, 20, 36] };
// the answer cards (W.respEn, read by juego.js respBox): on the wall above the heads, right of the rounds card, the first centre of cx whose
// cards stand 2 px clear of the rounds card (when it is up), whose hint hands (juego.js HAND, 3 px a dot, from the card's foot - 6) are on no
// face and whose hint frames cross no head (comer.js CARTAS)
const CARDS = { cx: Array.from({ length: 63 }, (_, i) => 162 - i), y: 16 };
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0 + 1, BOARD[1] + 1, BOARD[2], BOARD[3]]]] : [];
const FROG_OLD = { HOME33: [82, 174], FETCH33: [112, 152], CASA34: [172, 168], EAT34: [162, 176], CASA35: [110, 166], aparte33: [150, 160], 'tipa34.rana': [144, 172], inicio: [124, 168] };
function make(G, runs) {
  const E = engine(G), F = G.F, D = designMoves(E, F); if (G.HOPS) D.HOPAT = G.HOPS.table; const ED = designEdits(E, F, D), Gm = D.Gm;
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };
  const placeW = p => { const s = surfaceW(E, F, p[0], p[1] - 1); return { on: s.on, world: W4(s.w) }; }, frogW = feet => placeW([feet[0], feet[1] + 0]);
  const MOVES = [...ED.byLine.values()].sort((a, b) => a.line - b.line).map(m => Object.assign({}, m, { why: m.why.join('; ') }));
  for (const m of MOVES) for (const q of m.pts) q.push(placeW(q[2]).world);
  const DROPPED = [{ src: 'c.drawImage(spr("comer",fondo),0,0);', to: '', why: 'the background (fondo): the set' },
    { src: 'L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});', to: 'L.push({y:TZ,front:"mesa"});', why: 'the table (mkMesa): the set\'s; at its place in the sorted list (TZ) the set\'s table is drawn again over whoever is behind it (front.parts.mesa)' }].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* spots: the frog's places and the named places */
  const SPOTS = {};
  for (const [k, e] of Object.entries(D.NP)) { const fr = k in FROG_OLD, w = placeW(e.new); SPOTS[k] = Object.assign({ world: w.world, on: w.on, old: e.old, new: e.new }, fr ? { scale: 1, what: 'the frog\'s feet (W.cq.x + 16, W.cq.y + 27)' } : {}, e.old[0] !== e.new[0] || e.old[1] !== e.new[1] ? { moved: true } : {}, { why: e.why }); }
  SPOTS['frog.inicio'] = { world: placeW([124, R(SY(124, 168))]).world, on: 'mesa', old: [124, 168], new: [124, 168], what: 'LUGAR.inicio, .centro (124, 141): the frog\'s feet at (124 + 16 - 16, 141 + 27): on the cloth, unchanged (x 124 is the rule\'s own column: no step)', scale: 1 };
  SPOTS.puerta = { world: W4(E.atZ(D.DOOR[0], D.DOOR[1] - 1, 0)), on: 'floor', old: [0, 190], new: D.DOOR, moved: true, why: 'whoever comes in to sit (sienta, vaEstacion) or leaves from behind the table (sale) comes and goes by the doorway in the left wall (La mesa\'s); whoever comes in to the front still walks in at the left (PUERTA, unchanged)' };
  SPOTS.XP = { world: W4(E.atZ(D.XP, 212 - 1, 0)), on: 'floor', new: [D.XP, 212], why: 'the way round the table\'s right end: up from the front lane (FR) at x ' + D.XP + ' to the lane behind the chairs' };
  SPOTS.PB = { world: W4(E.atZ(D.PB[0], D.PB[1] - 1, 0)), on: 'floor', new: D.PB, why: 'the passage between the counter and the table\'s left end, at its back' };
  const seats = [0, 1, 2, 3].map(i => { const x = [90, 114, 138, 162][i], y = R(SY(x, 132)); return { seat: i, feet: [x, y], old: [x, 132], lap: [x, y - 8], world: W4(F.LAPS[i].concat([F.ZS])) }; });

  /* things: the 23 touch keys */
  const sprite = why => ({ sprite: true, why });
  const things = { luis: sprite('a person (today\'s sprite, drawn 1:1). caja(id) (comer.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)] standing; seated, down to SY(x, MESA[1] + 26) (moves)') };
  for (const id of ['carmen', 'abuelo', 'mama', 'papa', 'abuela']) things[id] = sprite('as luis');
  for (const id of ['di_buen', 'di_tambien', 'di_lleno', 'di_poco', 'di_mucho']) things[id] = sprite('the frog\'s speaking turn (tu_turno): one 16 x 10 box over his head, [b.x + (b.w >> 1) - 8, b.y - 27, 16, 10] of frogBox(W.cq), the same for all five (comer.js:' + lineOf('["di_buen","di_tambien","di_lleno","di_poco","di_mucho"]') + '); relative to the frog: unchanged (faults)');
  for (const [id, w, h] of [['mant', 26, 18], ['choc', 26, 18], ['cesta', 48, 24], ['cafetera', 24, 28], ['azucarera', 24, 18], ['olla', 30, 26], ['fuente', 56, 22], ['pl_papa', 24, 10], ['pl_rana', 18, 9]]) things[id] = sprite('a thing in W.cosas (the sprite layer): porId box [x - ' + (w >> 1) + ', y - ' + h + ', ' + w + ', ' + h + '] at where it stands (moves)');
  const partBox = list => { const pxs = list.map(i => [i % 240, Math.floor(i / 240)]); const x0 = Math.min(...pxs.map(p => p[0])), y0 = Math.min(...pxs.map(p => p[1])); return [x0, y0, Math.max(...pxs.map(p => p[0])) + 1 - x0, Math.max(...pxs.map(p => p[1])) + 1 - y0]; };
  const T = F.TBL, wt = [T.x0 - .03, T.y0 - .03, 0, T.x1 + .03, T.y1 + .03, T.z + .012];
  things.mesa = { set: true, world: W4(wt), box: box(wt), what: 'the table with its checked cloth (its top, the cloth hanging over its near side and its ends, its four legs)', old: { box: OLDBOX.mesa } };
  { const b = things.mesa.box, hx0 = Math.max(b[0], VIEW_X0 + 14), hy0 = Math.max(b[1], 14), hx1 = Math.min(b[0] + b[2], VIEW_X0 + 196 - 14), hy1 = Math.min(b[1] + b[3], 216 - 14);
    things.mesa.hintBox = [hx0, hy0, hx1 - hx0, hy1 - hy0]; things.mesa.hintWhy = 'hintBox: its touch box runs off the view at the left (the table\'s left end runs off the picture): the hint frame shows this part of it, 2 px inside the view; the touch box answers the touches'; }
  const chairW = c => W4([c.x - F.CH.hw, c.y - F.CH.hd, 0, c.x + F.CH.hw, c.y + F.CH.hd, F.CH.ZB]);
  things.silla_papa = { set: true, world: chairW(F.CHAIRS[3]), box: box(chairW(F.CHAIRS[3])), byChair: F.CHAIRS.map(c => box(chairW(c))), what: 'papá\'s chair: the chair at W.sitio.papa (3 when not set: every story has it at 3); boxes: byChair[W.sitio.papa]', old: { box: OLDBOX.silla_papa } };
  things.cocina = { set: true, ground: true, box: [0, 0, 240, 216], what: 'the kitchen: the floor, the walls, the counter with the sink and the cupboard, the doorway, the window, the stove and its hood, the counter beside it, the chairs (but papá\'s); last in the hit order', old: { box: OLDBOX.cocina } };
  { const b = things.cocina.box, hx0 = Math.max(b[0], VIEW_X0 + 14), hy0 = Math.max(b[1], 14), hx1 = Math.min(b[0] + b[2], VIEW_X0 + 196 - 14), hy1 = Math.min(b[1] + b[3], 216 - 14);
    things.cocina.hintBox = [hx0, hy0, hx1 - hx0, hy1 - hy0]; things.cocina.hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view)'; }

  const views = { wide: { zoom: 1, x0: VIEW_X0, world: W4(E.atZ(130, 150, 0)), region: null, old: [32, 0, 196, 216], what: 'the table laid for the meal in the middle, the four chairs and whoever sits there behind it, the counter with the sink and the cupboard at the left, the stove with its hood and the window at the right, the floor in front' } };

  /* the review and level pictures: each centred on its subject where the sheet puts it (first pass: the old rectangles' centres through the rule) */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1 ? [Math.max(0, Math.min(44, R(cx - 98))), Math.max(0, Math.min(112, R(cy - 52))), 196, 104] : [Math.max(0, Math.min(142, R(cx - 49))), Math.max(0, Math.min(164, R(cy - 26))), 98, 52];
    const w = placeW([cx, cy]); return { world: w.world, screen: [cx, cy], zoom, crop, what }; };
  const PICS = designPictures(pic, D);
  const LEVEL = PAIRS.level.flatMap(Lv => Lv.pictures.map((p, i) => p.scene === 'comer' ? { w: Lv.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* remap: every distinct position of positions.json */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const STORY = designStoryMoves(E, F, D);
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); return e; }
    if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; return e; }
    if (p.kind === 'x') { e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' }; return e; }
    if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
    const mv = STORY.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y], w = placeW(at);
    e.to = { [w.on]: w.world }; e.new = at.slice(); if (mv) { e.moved = true; e.why = mv.why; }
    e.what = 'a place (x, y): the surface under (x, y - 1) (' + w.on + ')' + (mv ? '; moved (why)' : '; the same screen place');
    return e; });

  // hop counts: every pair of the frog's named places, old against new (comer.js ranaA: ceil(d / 26), 1 to 6)
  const fpn = Object.keys(FROG_OLD).filter(k => k === 'inicio' || D.NP[k]), hopsAll = [], hop = d => d < 3 ? 0 : Math.max(1, Math.min(6, Math.ceil(d / 26)));
  const fnew = k => k === 'inicio' ? [124, 168] : D.NP[k].new;
  for (let i = 0; i < fpn.length; i++) for (let j = i + 1; j < fpn.length; j++) { const a = fpn[i], b = fpn[j], dO = Math.hypot(FROG_OLD[a][0] - FROG_OLD[b][0], FROG_OLD[a][1] - FROG_OLD[b][1]), dN = Math.hypot(fnew(a)[0] - fnew(b)[0], fnew(a)[1] - fnew(b)[1]); hopsAll.push({ a, b, old: hop(dO), new: hop(dN) }); }

  return {
    scene: 'comer',
    made: 'node docs/proyecto/pixel/comer-sheet-make.js, from comer-set.html (window.COMER_SET) and coqui/ref/escenas/comer/. Order 40a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      layout: 'every place AT the table steps down half a row a pixel to the right round column ' + SYC + ': SY(x, y) = y + (x - ' + SYC + ') / 2 (the four seats, the plates and cups in front of them, the lane behind the chairs, the children\'s corners, the frog beside a seated one\'s plate); every other place keeps its screen point if what stands there stands on what it stood on, else it moves the least distance that does (moves, remap). The world point of a place is the surface under it (comer-set.html surfaceAt): the table\'s top (z ' + F.ZT + '), a counter\'s or the stove\'s top (z ' + F.K.CZ + '), or the floor (z 0). A frog place q: his feet (q.x + 16, q.y + 27); a person\'s or a thing\'s place (x, y): under (x, y - 1)',
      relative: 'what the old code draws or moves relative to a person, the frog or a thing (what is held, the arms, the steam, the streams, the spoons, the bubbles, the clouds, the speaking box) keeps its offsets',
      paths: 'whoever goes behind the table walks round its right end (XP) and along the lane behind the chairs; whoever comes in to sit or leaves from behind comes and goes by the doorway (DOOR); the passage between the counter and the table\'s left end (PB) leads to the counter and to the back left corner',
      view: 'one view, zoom 1: the 196 x 216 window from x0 ' + VIEW_X0 + ', the old wide one',
      pair: 'a review or level picture is pictures[word.side]: zoom 2 = the 98 x 52 crop shown at 2 x 2, zoom 1 = the 196 x 104 window. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: { what: 'La mesa\'s room (cocina-kit.js; mesa-set.html at orden/37a 4033fc0) seen closer: the table in the middle with the four chairs behind it, the counter with the sink and the cupboard at the left, the stove with its hood and the window behind the table at the right, the doorway in the left wall',
      table: { world: [T.x0, T.y0, T.x1, T.y1, T.z], screen: Gm.top.map(p => p.map(r2)), why: 'La mesa\'s table (its far edge at y ' + T.y0 + ' and its four chairs where La mesa has them) made larger: drawn out to ' + T.x1 + ' at the right and ' + T.y1 + ' towards us, and to ' + T.x0 + ' at the left, leaving the passage to the counter' },
      seats, numbers: D.NUM },
    behind: { what: 'nothing: the outside (sky, bush, the patio) is baked into the window and the doorway', items: [] },
    setKey: { params: {}, key: '"comer"', baked: [{ key: 'comer', query: '?' }], notReached: [],
      bakedWhy: 'order 06 found 158 states and no key of the background (one fondo for every state); everything the stories change is the sprite layer\'s (the people, what stands on the table, the stool and the high chair, the stove\'s pots, the dog, the frog): one baked state' },
    things, spots: SPOTS,
    lugar: { inicio: { spot: 'frog.inicio', q: [124, 141], scale: 1, old: [124, 141] }, centro: { spot: 'frog.inicio', q: [124, 141], scale: 1, old: [124, 141] } },
    hops: [], hopsAll, hopsWhat: 'each pair of the frog\'s named places: the old count (ranaA: ceil(d / 26) hops, 1 to 6, on the old distance) and the count the new distance would give; the port counts on the old distance (HOPAT, moves): every pair keeps the old count',
    hopTable: G.HOPS ? { calls: G.HOPS.calls, places: Object.keys(G.HOPS.table).length, conflicts: G.HOPS.conflicts, what: 'every ranaA call of the 9 recorded runs played both ways: each new place of the frog (his feet) and the old place it stands for (moves: HOPAT)' } : null,
    views, remap, pictures: PICS, level: LEVEL,
    clips: { none: 'comer.js never calls clip()' },
    smoothing: 'comer.js turns smoothing off (tenidaC, tenida, rana) and never on',
    front: {
      how: 'two set things stand where people are drawn: the chairs and the table. Each item of the sorted list owns the pixels it drew last; at the chairs\' entry (sortY ' + 60 + ': after whoever is behind the table, drawn at 40 + y / 100, and before anyone else) and at the table\'s (the old table\'s own place, TZ ' + TZ + ', comer.js:' + lineOf('L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa)') + ') their pixels are drawn again over each item drawn before that owns them, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the floor point under the item\'s feet. "Behind the table" is that depth test, not a row: a seated one\'s lap under the table\'s far edge, whoever walks behind the chairs, the children at its back corners',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      parts: { sillas: { parts: FRONT.sillas, sortY: 60, insert: 'before the sort: L.push({y: 60, front: "sillas"})' }, mesa: { parts: FRONT.mesa, sortY: TZ, insert: 'the old table\'s line (dropped)' } },
      tags: [['L.push({y:cp[0],d:()=>cuerpo(c,id,a)});L.push({y:cp[1],d:()=>objetos(c,id,a)});', 'L.push({y:cp[0],id,d:()=>cuerpo(c,id,a)});L.push({y:cp[1],id,d:()=>objetos(c,id,a)});'], ['if(q.vis)L.push({y:q.sobre===0?q.y+27:TZ+(q.y+27)/1000,d:()=>rana(c,q,a)});', 'if(q.vis)L.push({y:q.sobre===0?q.y+27:TZ+(q.y+27)/1000,id:"coqui",d:()=>rana(c,q,a)});'], ['if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{', 'if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,id:"perro",d:()=>{']],
      tagsWhat: 'each person\'s, the frog\'s and the dog\'s items of the sorted list say whose they are (the front masks read it); nothing else changes',
    },
    shadows: {
      rule: 'the kitchen\'s one light (cocina-kit.js): from the upper left, shadows to screen right, low and joined to the thing. Whoever stands on the floor casts a small shadow from the floor point under their feet; whoever sits, the frog and what stands on the table cast none (a shadow falls on the floor only)',
      people: { radius: { abuela: .35, nino: .3, other: .35 }, at: 'the floor under (x, y - 1)', when: 'visible (vis !== 0, al > .5), standing (not sent), on the floor', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r)' },
      perro: { radius: .3, at: 'the floor under (x, y - 1)', cast: 'castShadow(g.x, g.y, .2, .3)' },
      coqui: { none: 'he stands on the table\'s top (the cloth): no shadow is cast on it' },
      dropped: 'none: comer.js draws no shadow of its own (COSA.sombra is never drawn)',
    },
    dropped: DROPPED,
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.pts.length ? { places: m.pts.map(q => ({ who: q[0], old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    helps: { what: 'the steam (comer.js vapor) is drawn with a darker blue-grey edge on both sides of each wisp, #6E80A6 for the old one-sided #B8C4D4: white steam over the white cloth, the cream wall and the people at the table stands out by its edge (contrast 2.0 and more), as it did not in the old picture',
      lines: [['fr(c,x+dx+sw-1,y-k,3,1,"#B8C4D4");fr(c,x+dx+sw,y-k,2,1,"#FFFFFF");', 'fr(c,x+dx+sw-1,y-k,4,1,"#5C6C92");fr(c,x+dx+sw,y-k,2,1,"#FFFFFF");']] },
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as juego.js bub draws it, both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    cards: { what: 'the answer cards (W.respEn, juego.js respBox: two cards at cx - 50 and cx + 10, three at cx - 70 + 50 i; y the top; 40 x 36): set by comer.js CARTAS at every frame while the frog chooses, the first cx of this list whose cards are 2 px clear of the rounds card (when it is up), whose hint hands (juego.js HAND from the card\'s foot - 6) are on no face and whose hint frames (card +- 12) cross no head; at every cx the cards\' lit frame and glow (card +- 12) are 4 px inside the view; the rounds card is checked by CARTAS itself', cx: CARDS.cx, y: CARDS.y, old: [130, 22] },
    talk: { what: 'where a bubble goes: the first of these places whose bubble is wholly inside the view, clear of the corner card and of every face; if none is, the first (the old)', top: 'a person: talkAt(k) = (x, y - alto - 1); the frog: (b.x + b.w / 2, b.y + dy - 1)', places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1', faces: 'a person\'s face: [x - 6, top + 6, 12, 10], top = y - height + 1 + dy (abuela: y - 50 standing, y - 48 sitting); the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]', board: BOARD },
    faults: [
      { what: 'the five speaking boxes di_buen, di_tambien, di_lleno, di_poco, di_mucho are one and the same 16 x 10 box over the frog\'s head (comer.js:' + lineOf('["di_buen","di_tambien","di_lleno","di_poco","di_mucho"]') + ': [b.x + (b.w >> 1) - 8, b.y - 27, 16, 10] of frogBox(W.cq)); the kit\'s hit() answers the first thing whose box holds the touch, so only di_buen is ever answered', kept: 'as the old: the box stays where the old one is relative to the frog; the port is told, not asked to change it' },
      { what: 'on the old review and level pages A comer\'s pictures show El balcón\'s round wooden table: the sprite cache key "mesa" is the same in both scenes (comer.js:' + lineOf('L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa)') + ', balcon.js) and El balcón draws first', kept: 'not copied: the set\'s review and level pictures show A comer\'s own table (coqui/ref/escenas/comer/pairs/*.png show the round one)' },
      { what: 'comer.js draws the table as an item of the sorted list (mkMesa at TZ ' + TZ + '), not in its background; the four chairs are in the background', kept: 'the set has both; the port drops the old table\'s line and draws the set\'s table again at TZ where it is nearer than what was drawn before it, and the chairs at sortY 60 (front)' },
    ],
    code: codeEntries(MOVES, DROPPED, things),
    checks: { notes: [] },
  };
}
// the story files' own places that move: the remap (cual-comer's pictures). A seated one and what stands in front of a seat take the rule's
// step (SY); a thing elsewhere on the table its least move onto the cloth; a person or the dog on the floor the least move onto clear floor
function designStoryMoves(E, F, D) {
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-comer.json'), 'utf8')), out = [], seen = new Set();
  // buen provecho: the seated three (yes) and the standing three (no) share one 196 x 104 window; on the world's axes the seats' row climbs to the
  // left and the cloth's near edge falls to the right, so by the rule the seated tops and the standing feet are 130 rows apart. Here the three sit
  // one seat to the right (seats 1 to 3: their plates with them) and the three who stand stand on clear floor at the table's left end and right
  // of its right end: everyone whole in the window
  const PAIR_WHY = 'buen provecho: one seat to the right (the seated) or at the table\'s ends on clear floor (the standing), so that both pictures are whole in one 196 x 104 window', S = (x, y) => [x, R(SY(x, y))];
  const PAIR_OWN = { '90,132': () => S(114, 132), '114,132': () => S(138, 132), '138,132': () => S(162, 132), '90,127': () => S(114, 127), '114,127': () => S(138, 127), '138,127': () => S(162, 127),
    '164,182': () => [170, 199], '70,186': () => [52, 176], '112,186': () => [74, 178], '160,186': () => [208, 178] };
  const hwOf = k => ({ cesta: 18, azucarera: 19, olla: 12, fuente: 14, bizcocho: 11, cuenco: 15, platoma: 13, platoH: 13, muslo: 12 })[k] || 8;
  for (const it of cual.items) for (const side of ['si', 'no']) { const st = (it[side] || {}).set || {};
    const add = (who, p, kind, k) => { const key = p.x + ',' + p.y; if (seen.has(key)) return; seen.add(key);
      let nw, why;
      if (PAIR_OWN[key]) { nw = PAIR_OWN[key](); why = key === '164,182' ? 'un poco: Carmen off the table\'s foot, 1 px left and 1 down of the least move (171, 198): with abuela\'s head 2 px inside its left edge, her head is then 2 px inside the right edge of the close window (98 px), which no window holds otherwise (round 2)' : PAIR_WHY; }
      else if (kind === 'gente' && p.sent) { nw = [p.x, R(SY(p.x, p.y))]; why = 'a seated one: the rule\'s step (SY)'; }
      else if (kind === 'cosa' && p.y <= 136) { nw = [p.x, R(SY(p.x, p.y))]; why = 'what stands in front of a seat: the rule\'s step (SY)'; }
      else if (kind === 'cosa' && p.z == null) { nw = D.leastTop(p.x, p.y, hwOf(k)); why = 'on the cloth: the least move that stands it wholly on the table\'s top'; }
      else if (kind === 'cosa') { nw = [p.x, p.y]; why = 'a thing shown in the air (z): unchanged'; }
      else { nw = D.leastFloor(p.x, p.y); why = 'on clear floor: the least move off the table\'s foot'; }
      if (nw[0] !== p.x || nw[1] !== p.y) out.push({ old: [p.x, p.y], new: nw, who, why: it.w + '.' + side + ': ' + why }); };
    for (const [id, p] of Object.entries(st.gente || {})) if (p && p.x != null) add(id, p, 'gente');
    for (const c of st.cosas || []) if (c && c.x != null) add('cosa', c, 'cosa', c.k);
    if (st.perro) add('perro', st.perro, 'perro'); }
  return out;
}
// the review pictures: a zoom 1 picture is the 196 x 104 window over the rows of its subject; a zoom 2 one the 98 x 52 region round it
function designPictures(pic, D) {
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-comer.json'), 'utf8')), out = {};
  for (const it of cual.items) for (const side of ['si', 'no']) { const sp = it[side]; if (!sp) continue; const c = sp.cam, nm = deacc(it.w) + '.' + side;
    const zoom = c[2] <= 120 ? 2 : 1; out[nm] = pic(c[0] + c[2] / 2, c[1] + c[3] / 2, zoom, 'first pass: the old rectangle\'s middle'); }
  return out;
}

/* ---------- code: every line of comer.js that holds a number, and what each number is (El banco's way) ----------
   The maker reads comer.js itself (not order 06's inventory): it finds every numeric literal outside comments and strings, sorts each by what it
   is from where it stands (a place on the picture; an offset from someone; a time, a sound, a count; a draw order; a sprite's or a sign's own
   drawing), and the sheet names, line by line, what becomes of its places (moved, the rule, a set thing, dropped). check() fails if a line
   with a place has no entry */
const REGIONS = (() => {
  const at = s => lineOf(s), out = [];
  const r = (a, b, kind, why) => out.push({ a, b, kind, why });
  r(at('function fondo(){'), at('function mkSillaBebe(v){') - 1, 'dropped', 'the background (fondo) and the table (mkMesa): the set\'s, dropped');
  r(at('function mkSillaBebe(v){'), at('function tenida(c,k,x,y,ang,esc,v)'), 'drawing', 'a sprite\'s own drawing (the high chair, the plates, the rolls, the basket, the dishes, the cups, the pots, the platter, the jugs, the bowls, the cake...) and tenidaC, tenida: relative to where it is drawn, unchanged');
  r(at('const hex=(r,g,b)'), at('function cucharon(c,x0,y0,x1,y1,load,o){') + 10, 'drawing', 'recolor, steam, streams, a thick line, a hand, a long spoon: relative to the point they are drawn at, unchanged');
  r(at('const alto=id=>'), at('const alto=id=>'), 'drawing', 'alto: the sprites\' heights, not places');
  r(at('const hombroY=(id,p)'), at('function nube(g,x,y,o,dir,aim){') + 5, 'drawing', 'the shoulders, the mouths, the bodies, the arms, the hands, the frog, the thought clouds: drawn relative to them, unchanged');
  r(at('function hud(g,W,a){'), at('const marca=m=>'), 'drawing', 'the rounds card in the corner (hud): screen space, unchanged (talk.board)');
  r(at('function talkAt(k,W){'), at('function respIcon(g,k,x,y,w,h,a){}'), 'drawing', 'talkAt: over the head, relative; respIcon draws nothing');
  r(at('function rolloD(c,x,yb,r,a){'), at('function cosaDibuja(c,o,a){') + 6, 'drawing', 'a thing on the table and what lies on it: drawn relative to its place, unchanged');
  r(at('async function stake('), at('const estado=W=>') + 3, 'other', 'stake, poke and estado: no place');
  return out;
})();
const regionOf = L => REGIONS.find(r => L >= r.a && L <= r.b);
const stripLine = l => l.replace(/\/\/.*$/, '').replace(/"(?:[^"\\]|\\.)*"/g, '""');
const numsOf = l => { const out = []; const re = /(?<![\w#.$])(\d+\.\d+|\d+|\.\d+)(?![\w])/g; let m; while ((m = re.exec(l))) out.push({ n: m[1], at: m.index }); return out; };
// what a number is, from the text before and after it
function numKind(l, at, n) {
  const before = l.slice(Math.max(0, at - 40), at), after = l.slice(at + n.length, at + n.length + 6);
  if (/(wait|setTimeout)\($/.test(before) || /TICK\s*\*\s*$/.test(before) || /tone\([^()]*$/.test(before) || /SFX\.\w+\($/.test(before) || /bounce\($/.test(before) || /\bms\s*\|\|\s*$/.test(before) || /\(F>>$|F>>$|F%$/.test(before)) return 'time';
  if (/[<>]=?\s*$|===?\s*$|!==?\s*$|%\s*$|Math\.(min|max)\(\s*$|\|\|\s*$|\?\s*$|>>\s*$|<<\s*$|\.length\s*[<>]=?\s*$|\bi<=?\s*$|\bn\s*=\s*$|\bn\|\|\s*$/.test(before)) return 'count';
  if (/\bz:\s*-?$|\.z\s*=\s*$/.test(before) || /TZ\s*\+\s*$|\b40\s*[+.]/.test(before + n)) return 'order';
  if (/\b(dy|al|s|h|vis|paso|dir|n|i|e|dx|vapor|vn|vh|vdx|vdy|sent|est|pie|boca|abre|hinch|caida|espalda|lleno|mal|sobre|tomada|spoons|ang|L|_m|sh|gx|gy|ax|ay|bx|by|rx|ry|una|dos|plata|load|pdx|marcas|turno|nO|lista35)\s*[:=]\s*-?$/.test(before) || /\.(dy|ang|dx)\s*[+-]?=\s*-?$/.test(before)) return 'state';
  if (/Math\.PI\s*[*\/]\s*$|\*\s*$|Math\.sin\([^()]*$|Math\.cos\([^()]*$|Math\.hypot\([^()]*$|\/\s*$/.test(before) || /^\s*\*/.test(after)) return 'scale';
  if (/\b[xy]\s*:\s*-?$|\b[xy]\s*:\s*\w[\w.\[\]]*\s*[+-]\s*$|\.[xy]\s*=\s*-?$|\.[xy]\s*[+-]=\s*$/.test(before)) return /[+-]\s*$/.test(before) && !/:\s*-$|=\s*-$/.test(before) ? 'offset' : 'place';
  if (/(mueve|ranaA|vuela|hopTo|tenida|tenidaC|entra|detras|delante|ruta|cucharaA|cucharaAR|ranaPon|pon|granosCaen|vierteA)\([^()]*$/.test(before)) return /[+-]\s*$/.test(before) && !/[(,]\s*-$/.test(before) ? 'offset' : 'place';
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
    if (dr.length && !mv.length) { e.to = { dropped: true }; e.note = dr.map(d => d.why).join('; '); }
    else if (mv.length) { e.to = { moves: mv.map(m => m.src.slice(0, 60)) }; e.note = 'moved (moves): ' + mv.map(m => m.why.split(':')[0]).join('; ') + (kinds.place ? '; every other place here keeps its screen point (the rule)' : ''); }
    else if (reg) { e.to = reg.kind === 'dropped' ? { dropped: true } : 'unchanged'; e.note = reg.why; }
    else if (kinds.place) { e.to = { rule: true }; e.note = 'places on the picture: each keeps its screen point, its world point the surface under it (rules.layout): checked at every moment (a thing on the cloth, a person on clear floor)'; }
    else { e.to = 'unchanged'; e.note = 'no place: ' + Object.keys(kinds).join(', '); }
    C.push(e);
  }
  const set = (L, to, note) => { const e = C.find(q => q.line === L); if (!e) throw new Error('code: no numbers on line ' + L); if (e.to && e.to.moves) { e.note += '; ' + note; return; } e.to = to; e.note = note; };
  set(lineOf('const PISO=142,MESA=[66,112,120,60]'), { things: ['mesa', 'silla_papa'], points: ['layout.table', 'layout.seats'] }, 'PISO, MOSTR, ESTUFA, ESTANTE: the old background (dropped: the set); MESA: the old table (the set\'s table, layout.table; its box things.mesa); SILLA: the seats\' x, unchanged (their rows by SY: layout.seats)');
  set(lineOf('const FILA=124,MED=148,FREN=170,TZ=173,'), { moves: ['SY'] }, 'FILA, ASIENTO, ATRAS: rows at the table, each at x through SY (moves); TZ: the table\'s place in the sorted list (a draw order, kept: front.parts.mesa); FR, the front lane: unchanged; MED, FREN, FLO: no longer read');
  set(lineOf('const SUBE=[80,182];'), 'unchanged', 'SUBE: no longer read (detras and delante go round the table\'s right end: moves)');
  set(lineOf('{id:"silla_papa",si:w=>true,'), { things: ['silla_papa', 'mesa', 'cocina'] }, 'the boxes of papá\'s chair, the table and the room: the set things (things.*.box; papá\'s chair byChair[W.sitio.papa])');
  set(lineOf('KIT.escena({id:"comer"'), { view: 'wide', spots: ['frog.inicio'] }, 'the view (views.wide), heartAt [130, 22] (unchanged: on the wall over the table) and LUGAR (the frog on the cloth): unchanged');
  set(lineOf('fresh:()=>({respEn:'), 'unchanged', 'respEn [130, 22]: where the answer cards stand, unchanged (on the wall over the heads); the frog\'s first place (108, 141): unchanged');
  for (let L = lineOf('async prueba(o){'); L <= lineOf('async prueba(o){'); L++) { const e = C.find(q => q.line === L); if (e) { e.to = 'unchanged'; e.note = 'acts.prueba (a test act no story calls): unchanged'; } }
  C.push({ line: 'juego.js:16', to: 'unchanged', note: 'fresh(): comer\'s fresh() puts the frog at (108, 141)' });
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
const labOf = c => { const f = u => { u /= 255; return u <= .04045 ? u / 12.92 : ((u + .055) / 1.055) ** 2.4; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .95047, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.08883, F3 = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * F3(Y) - 16, 500 * (F3(X) - F3(Y)), 200 * (F3(Y) - F3(Z))]; };
const dE76 = (a, b) => { const A = labOf(a), B = labOf(b); return Math.hypot(A[0] - B[0], A[1] - B[1], A[2] - B[2]); };
const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); };
// (round 2) whoever is in a close picture is there with his arms and what he holds: a sleeve or a held thing in it is that person in it
const withArms = its => its.filter(it => it.kind !== 'arms').map(it => it.kind === 'person' ? Object.assign({}, it, { all: it.rows.concat(...its.filter(a => a.kind === 'arms' && a.of === it.id).map(a => a.rows)) }) : it);
const rowsAt = (rows, dx, dy) => rows.map(r => [r[0] + dy, r[1] + dx, r[2] + dx]);
const rowsBox = rs => { if (!rs.length) return null; const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
const PERSON_H = (id, p) => id === 'abuela' ? (p.sent ? 48 : 50) : null;

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), MASK = G.MASK, NEW = G.TICKS, x0 = VIEW_X0, key0 = 'comer';
  const TAGS = {}; for (const k of STATES) { const m = new Array(240 * 216).fill(null); for (const [p, list] of Object.entries(G.parts[k])) for (const i of list) m[i] = p; TAGS[k] = m; }
  const rgbAt = (k, i) => [G.rgb[k][i * 3], G.rgb[k][i * 3 + 1], G.rgb[k][i * 3 + 2]];
  const pairSides = pairSidesOf();
  // (round 2) the cloth's top (pixels of the part mesa over the table's top at its height) and the stove's top face; each thing's outline
  const TOPCL = new Uint8Array(240 * 216), STTOP = new Uint8Array(240 * 216), TB = F.TBL, ST0 = F.STOVE;
  for (const i of G.parts[key0].mesa || []) { const g = E.atZ(i % 240 + .5, Math.floor(i / 240) + .5, TB.z); if (g[0] >= TB.x0 - .04 && g[0] <= TB.x1 + .04 && g[1] >= TB.y0 - .04 && g[1] <= TB.y1 + .04) TOPCL[i] = 1; }
  for (let i = 0; i < 240 * 216; i++) { const s0 = surfaceW(E, F, i % 240 + .5, Math.floor(i / 240) + .5); if (s0.on === 'estufa') STTOP[i] = 1; }
  const EDGES = new Map(), edgesOf = key => { if (EDGES.has(key)) return EDGES.get(key); const px = MASK[key].px, S = new Map(); for (let q = 0; q < px.length; q += 4) S.set(px[q], [px[q + 1], px[q + 2], px[q + 3]]); const out = [];
    for (const [i, c] of S) { const x = i % 240, y = Math.floor(i / 240); for (const [ex, ey] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) if (!S.has((y + ey) * 240 + x + ex)) out.push([x, y, ex, ey, c]); } EDGES.set(key, out); return out; };
  const CLM = new Map(), clothContrast = it => { const mk = it.key + '|' + it.dx + ',' + it.dy; if (CLM.has(mk)) return CLM.get(mk); let s0 = 0, c0 = 0;
    for (const [x, y, ex, ey, c] of edgesOf(it.key)) { const nx = x + it.dx + ex, ny = y + it.dy + ey; if (nx < 0 || ny < 0 || nx >= 240 || ny >= 216) continue; const j = ny * 240 + nx; if (!TOPCL[j]) continue; s0 += ratio(c, rgbAt(key0, j)); c0++; }
    const v = c0 >= 4 ? [s0 / c0, c0] : null; CLM.set(mk, v); return v; };
  const BODY_H = { cafetera: 20, cazo: 11, fuente: 16, bandeja: 18 };   // each one's body (its steam, drawn with it, rises over the hood: not counted)
  const STM = new Map(), stoveOf = it => { const mk = it.key + '|' + it.dx + ',' + it.dy; if (STM.has(mk)) return STM.get(mk); const T0 = TAGS[key0], last = Math.max(...it.rows.map(q => q[0])), bh = BODY_H[it.o.k] || 99; let n = 0, off = 0, hood = 0, any = false;
    for (const [y, a, b] of it.rows) for (let x = a; x <= b; x++) { if (x < 0 || y < 0 || x >= 240 || y >= 216) continue; if (y > last - bh && T0[y * 240 + x] === 'campana') hood++; if (y === last) { n++; const on = [0, 1, 2].some(d => y + d < 216 && STTOP[(y + d) * 240 + x]); if (on) any = true; else off++; } }
    const v = any || hood ? { n, off, hood } : null; STM.set(mk, v); return v; };
  let nCl = 0, nSt = 0, clWorst = [99, '']; const clothBad = new Map(), stoveBad = new Map();

  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-comer.json'), 'utf8'));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of PAIRS.level) for (const p of L.pictures) if (p.scene === 'comer') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  /* code: comer.js read here, line by line: every line with a number has an entry; a line with a place has a fate; every move's line too */
  { const byL = new Map(sh.code.map(e => [String(e.line), e])); let nPlace = 0;
    for (let L = 1; L <= LINES.length; L++) { const ns = numsOf(stripLine(LINES[L - 1])); if (!ns.length) continue; const e = byL.get(String(L)); if (!e) { P.push('code: comer.js line ' + L + ' has numbers and no entry'); continue; }
      if (e.numbers.place) { nPlace++; if (!e.to || (typeof e.to === 'object' && !Object.keys(e.to).length)) P.push('code: line ' + L + ' has places and no fate'); } }
    for (const m of sh.moves) for (const L of m.lines || [m.line]) { if (!m.src.split('\n').some(s => LINES[L - 1].includes(s.trim().slice(0, 40)))) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); const e = byL.get(String(L)); if (e && e.numbers && Object.keys(e.numbers).length && (!e.to || !e.to.moves)) P.push('moves: line ' + L + ' is not named as moved in code'); }
    for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
    for (const [a] of sh.front.tags.concat(sh.helps.lines)) if (!COMER_JS.includes(a)) P.push('comer.js does not hold ' + a);
    notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-comer (' + pairSides.length + ' pictures), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + sh.code.length + ' lines of comer.js with numbers named in code (' + nPlace + ' of them with places, each with its fate), ' + sh.moves.length + ' moves, ' + sh.setKey.baked.length + ' baked state (the old ' + inv.states.count + ' states)'); }

  /* hops: the frog's walks take the old number of hops: every run's sounds, the port's against the recorded run's, the same hops in the same order */
  { let nH = 0, bad = 0; runs.forEach((r, ri) => { const rec = JSON.parse(fs.readFileSync(path.join(REPO, 'coqui/ref/trazas', r.story.id, r.plan + '.json'), 'utf8')), a = rec.sounds.map(x => Array.isArray(x) ? x[0] : x), b = (NEW[ri].sounds || []).map(x => Array.isArray(x) ? x[0] : x);
      const hops = q => q.filter(x => x === 'hop').length, seq = q => q.filter(x => x !== 'blip').join(' ');
      nH += hops(a); if (hops(a) !== hops(b) || seq(a) !== seq(b)) { bad++; P.push('hops: ' + r.story.id + ' ' + r.plan + ': ' + hops(b) + ' hops, the recorded run ' + hops(a) + (seq(a) !== seq(b) ? ' (the sounds but the blips differ in order)' : '')); } });
    notes.push('hops: every run of the port\'s play makes the recorded run\'s sounds, the blips aside, in the same order: ' + nH + ' hops in all (' + bad + ' runs differ)'); }

  /* walks: every call of juego.js hopTo (the frog's every walk, acts included) of every run, on the old page and with the port, walk by walk:
     as many walks, each with the old hop count */
  { let n = 0, bad = 0; const per = [];
    for (const w of G.WALKS.walks) { const o = w.o || [], q = w.n || [];
      if (o.length !== q.length) { bad++; P.push('walks: ' + w.story + ' ' + w.plan + ': ' + q.length + ' walks, the old page ' + o.length); continue; }
      let d = 0; o.forEach((a, i) => { n++; if (a[4] !== q[i][4]) { d++; bad++; P.push('walks: ' + w.story + ' ' + w.plan + ' walk ' + (i + 1) + ' from (' + q[i][0] + ', ' + q[i][1] + ') to (' + q[i][2] + ', ' + q[i][3] + '): ' + q[i][4] + ' hops, the old ' + a[4] + ' (from (' + a[0] + ', ' + a[1] + ') to (' + a[2] + ', ' + a[3] + '))'); } });
      per.push(w.story + ' ' + w.plan + ' ' + o.length); }
    sh.checks.walks = { count: n, differ: bad, runs: per, what: 'every call of juego.js hopTo (where from, where to, how many hops: his top-left corner) in every run of the three stories, acts included, on the old page and with the port, compared walk by walk' };
    notes.push('walks: every walk of the frog (every hopTo call) of the ' + G.WALKS.walks.length + ' runs, on the old page and with the port, walk by walk: ' + n + ' walks, ' + bad + ' with another hop count or missing'); }
  if (sh.hopTable && sh.hopTable.conflicts.length) P.push('hops: a new place of the frog stands for two old ones: ' + sh.hopTable.conflicts.join('; '));
  /* the set's pixels: every set thing's pixels inside its touch box; the hit order; the set things whole in the view or clearly off it */
  { const res = []; const k = key0, parts = G.parts[k];
    for (const p of Object.keys(parts)) { if (!sh.things[THING_OF(p)] || !sh.things[THING_OF(p)].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s'); }
    for (const [t, ps] of [['mesa', FRONT.mesa], ['silla_papa', ['silla3']]]) { const b = sh.things[t].box; let out = 0; for (const p of ps) for (const i of parts[p] || []) { const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + t + ' are outside its touch box ' + JSON.stringify(b)); }
    { const b = sh.things.silla_papa.box; let n = 0; for (const p of FRONT.mesa) for (const i of parts[p] || []) { const x = i % 240, y = Math.floor(i / 240); if (x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3]) n++; } res.push('the table\'s pixels in papá\'s chair\'s box (they answer the chair: it is before the table in the hit order, as the old): ' + n); }
    for (const [p, list] of Object.entries(parts)) { if (p === 'pared') continue; let a = 1e9, c = -1e9, t = 1e9, d = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); a = Math.min(a, x); c = Math.max(c, x); t = Math.min(t, y); d = Math.max(d, y); }
      const inL = a >= x0 + 3, inR = c <= x0 + 196 - 4, inT = t >= 3, inB = d <= 216 - 4, offL = a <= x0 - 12, offR = c >= x0 + 196 + 11, offT = t <= -12 || t === 0, offB = d >= 216 + 11 || d === 215;
      if (!((inL || offL) && (inR || offR) && (inT || offT) && (inB || offB))) P.push('edge: the part ' + p + ' spans x ' + a + ' to ' + c + ', y ' + t + ' to ' + d + ': it neither stays 3 px inside the view nor clearly runs off it');
      res.push(p + ' x ' + a + '-' + c + ' y ' + t + '-' + d); }
    notes.push('set things: the table\'s pixels all inside its touch box ' + JSON.stringify(sh.things.mesa.box) + ' (its hint box ' + JSON.stringify(sh.things.mesa.hintBox) + '), papá\'s chair\'s inside its box ' + JSON.stringify(sh.things.silla_papa.box) + '; every other part the room\'s (cocina, its box the whole picture, its hint box ' + JSON.stringify(sh.things.cocina.hintBox) + '); each part whole inside the view with 3 px to spare or clearly running off it: ' + res.join('; ')); }

  /* the light: every castShadow call darkens; each shadow in one piece with its thing; a thin thing (a leg) only a short contact shadow on its shadow
     side; no pixel of the floor within 3 px of a thing on its lit side (left and above) differs from the floor without the thing */
  { const pieces = [], k = key0, OG = G.onGround[k], byPart = {};
    for (const c of G.shadows[k]) { const [x, y, z, r, s] = c.args, p = c.part || '(none)'; if (!(s > 0) || !(r > 0)) P.push('shadow: ' + p + ' castShadow(' + c.args.map(r2) + '): nothing is cast'); const b = byPart[p] = byPart[p] || { calls: 0 }; b.calls++; }
    for (const [p, b] of Object.entries(byPart)) { const sp = (G.shadowPx[k][p] || []).filter(i => OG[i]); if (!sp.length) P.push('shadow: the part ' + p + ' casts ' + b.calls + ' times and darkens nothing');
      const own = new Set(); for (const [q, list] of Object.entries(G.parts[k])) if (q === p || q.startsWith(p.split('.')[0])) for (const i of list) own.add(i);
      const lim = 4; let far = 0; for (const i of sp) { const x = i % 240, y = Math.floor(i / 240); let near = false; for (let dy = -lim; dy <= lim && !near; dy++) for (let dx = -lim; dx <= lim; dx++) if (own.has((y + dy) * 240 + x + dx)) { near = true; break; } if (!near) far++; }
      if (far) P.push('shadow: ' + far + ' px of ' + p + '\'s shadow are further than ' + lim + ' px from it');
      pieces.push(p + ' ' + b.calls + ' calls, ' + sp.length + ' px'); }
    for (const [p, rgbSin] of Object.entries(G.sin[k])) { if (!/patas$/.test(p)) continue; const own = new Set(G.parts[k][p] || []); let bad = 0;
      for (const i of own) { const x = i % 240, y = Math.floor(i / 240); for (const [dx, dy] of [[-1, 0], [-2, 0], [-3, 0], [0, -1], [0, -2], [0, -3], [-1, -1], [-2, -2]]) { const j = (y + dy) * 240 + x + dx; if (x + dx < 0 || y + dy < 0 || own.has(j) || !OG[j]) continue;
        if (G.rgb[k][j * 3] !== rgbSin[j * 3] || G.rgb[k][j * 3 + 1] !== rgbSin[j * 3 + 1] || G.rgb[k][j * 3 + 2] !== rgbSin[j * 3 + 2]) bad++; } }
      if (bad) P.push('lit side: ' + bad + ' floor pixels within 3 px of ' + p + ' on its lit side differ from the floor without it'); }
    notes.push('light: the kit\'s one rule; every castShadow call of the set darkens the floor, each shadow within 4 px of its own thing (' + pieces.join('; ') + ': the table\'s and the chairs\' legs, thin, each a short contact shadow at its foot on its shadow side); no floor pixel within 3 px of a leg on its lit side differs from the floor without the leg (the kit\'s floor dimming on the shadow side only)'); }

  /* the window and the doorway: what shows through them is outside (the sky, the bush, the patio), with the reveal and the frame */
  { const k = key0, T = TAGS[k]; const cnt = p => { let n = 0, sky = 0, green = 0; for (const i of G.parts[k][p] || []) { n++; const c = rgbAt(k, i); if (c[2] > c[0] + 40 && c[2] > 180) sky++; else if (c[1] > c[0] + 30 && c[1] > c[2]) green++; } return { n, sky, green }; };
    const wv = cnt('ventana'), pt = cnt('puerta'); if (wv.sky < 20 || wv.green < 10) P.push('window: it shows ' + wv.sky + ' px of sky and ' + wv.green + ' of green'); if (pt.sky < 20 || pt.green < 10) P.push('doorway: it shows ' + pt.sky + ' px of sky and ' + pt.green + ' of green');
    notes.push('window and doorway: the kit\'s (La mesa\'s): what shows through them is outside, the window ' + wv.sky + ' px of sky and ' + wv.green + ' of the bush, the doorway ' + pt.sky + ' px of sky and ' + pt.green + ' of the patio\'s hedge, each with its frame standing out of the wall and its reveal (the window a sill)'); }

  /* (round 2) the table reads as a laid table. Round 1 measured only the cloth's thin legs (contrast) and where things stood on it: nothing
     about the cloth against the floor, so a pale pink-and-white cloth of the floor's own diamond size passed. Now: the mean colour of the
     cloth's top against the floor's (CIE76 dE 25 and more), its pattern's period against the floor's (at most half), the cloth's drop on the
     near side and the right end (6 rows and more in every column of the table's seen length), the top's near edge over the floor under it
     (10 rows and more) */
  { const k = key0, T = TAGS[k], OG = G.onGround[k], top = [], drop = [], floor = []; const inV = x => x >= x0 && x < x0 + 196, mean = a => [0, 1, 2].map(c => a.reduce((s0, i) => s0 + G.rgb[k][i * 3 + c], 0) / Math.max(1, a.length));
    for (const i of G.parts[k].mesa || []) { if (!inV(i % 240)) continue; (TOPCL[i] ? top : drop).push(i); }
    for (let i = 0; i < 240 * 216; i++) { if (!inV(i % 240) || T[i] || !OG[i]) continue; const g = E.atZ(i % 240 + .5, Math.floor(i / 240) + .5, 0); if (g[0] >= 0 && g[1] >= 0) floor.push(i); }
    const mt = mean(top), mf = mean(floor), d = dE76(mt, mf), perC = 2 * F.CHECK, perF = 2 * F.K.TILE;
    if (d < 25) P.push('table: the cloth\'s top (mean ' + mt.map(R) + ') against the floor (mean ' + mf.map(R) + '): dE ' + r2(d) + ' (keep 25)');
    if (perC > perF / 2) P.push('table: the cloth\'s pattern repeats every ' + perC + ', the floor\'s every ' + perF + ' (keep half)');
    const cols = new Map(); for (const i of top) { const x = i % 240, y = Math.floor(i / 240); cols.set(x, Math.max(cols.get(x) == null ? -1 : cols.get(x), y)); }
    const dropOf = new Map(); for (const i of drop) { const x = i % 240, y = Math.floor(i / 240); if (cols.has(x) && y > cols.get(x)) dropOf.set(x, (dropOf.get(x) || 0) + 1); }
    let minDrop = 99, minAt = 0, thin = 0; for (const x of cols.keys()) { const n = dropOf.get(x) || 0; if (n < minDrop) { minDrop = n; minAt = x; } if (n < 6) thin++; }
    if (thin) P.push('table: in ' + thin + ' of the ' + cols.size + ' columns of the table\'s seen length the cloth\'s drop has fewer than 6 rows (' + minDrop + ' at x ' + minAt + ')');
    let hMin = 99; for (let t = 0; t <= 1; t += .02) { for (const [wx, wy] of [[F.TBL.x0 + t * (F.TBL.x1 - F.TBL.x0), F.TBL.y1], [F.TBL.x1, F.TBL.y0 + t * (F.TBL.y1 - F.TBL.y0)]]) { const a = E.project(wx, wy, F.TBL.z).sy, b = E.project(wx, wy, 0).sy; if (inV(E.project(wx, wy, 0).sx)) hMin = Math.min(hMin, b - a); } }
    if (hMin < 10) P.push('table: its top\'s near edge stands ' + r2(hMin) + ' rows over the floor under it (keep 10)');
    notes.push('table (round 2): the cloth\'s top, blue-and-white gingham (mean ' + mt.map(R) + '), against the floor (mean ' + mf.map(R) + '): dE ' + r2(d) + ' (keep 25); its pattern repeats every ' + perC + ', the floor\'s every ' + perF + ' (keep half); the drop over the near side and the right end ' + minDrop + ' rows at the least over the ' + cols.size + ' columns of its seen length (keep 6); the top\'s near edge ' + r2(hMin) + ' rows over the floor at the least (keep 10)'); }

  /* (round 2) the door: La mesa's final one (main 64aa5f1). Round 1 measured only the sky and green seen through the doorway: a doorway with no
     leaf, its lower part behind the counter's end, passed. Now as La mesa's: its leaf, the wall's thickness in the opening and the threshold 30
     px and more each in the view, the brass handle seen, the lowest outside pixel of every column of the opening the patio's ground; and the way
     in clear: no pixel of the opening (the wall's plane from the threshold to the lintel) is the counter's, its sink's or the cupboard's */
  { const K0 = key0, T0 = TAGS[K0], RGB = G.rgb[K0], inV = i => { const x = i % 240; return x >= x0 && x < x0 + 196; }, n = p => (G.parts[K0][p] || []).filter(inV).length;
    const nLeaf = n('puerta.hoja'), nRev = n('puerta.jamba'), nThr = n('puerta.umbral');
    for (const [nm, v] of [['leaf', nLeaf], ['reveal', nRev], ['threshold', nThr]]) if (v < 30) P.push('door: its ' + nm + ' has ' + v + ' px in the wide view (30 kept)');
    let knob = 0; for (const i of G.parts[K0]['puerta.hoja'] || []) { const c = [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]; if (dE76(c, F.KC.knob) < 20 || dE76(c, F.KC.knob.map(v => v * .86)) < 20) knob++; }
    if (knob < 2) P.push('door: its leaf shows ' + knob + ' px of its brass handle');
    const isGround = c => dE76(c, F.STONE) < 12 || dE76(c, F.STONE.map(v => v * .84)) < 12 || dE76(c, F.STONE.map(v => v * .7)) < 14 || dE76(c, [124, 146, 62]) < 10;
    let cols = 0, okc = 0; const badc = [], KC = F.KC, BACK = [...KC.sky, KC.yard, KC.yardTop, KC.yardLine, ...KC.hedge, [255, 255, 255]];
    const outside = (i, x, y) => { if (!T0[i]) return G.onGround[K0][i] && E.atZ(x + .5, y + .5, 0)[0] < 0 ? 'ground' : null; if (T0[i] !== 'puerta') return null; const c = [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]; return BACK.some(b => dE76(c, b) < 3) ? 'back' : null; };
    for (let x = 0; x < 240; x++) { let low = -1, kind = null; for (let y = 215; y >= 0; y--) { const i = y * 240 + x, o = outside(i, x, y); if (o) { low = i; kind = o; break; } }
      if (low < 0) continue; cols++; const c = [RGB[low * 3], RGB[low * 3 + 1], RGB[low * 3 + 2]]; if (kind === 'ground' && isGround(c)) okc++; else badc.push(x + ',' + Math.floor(low / 240) + ' ' + kind + ' ' + c.join('/')); }
    if (!cols || badc.length) P.push('door: the lowest outside pixel of ' + badc.length + ' of the opening\'s ' + cols + ' columns is not the patio\'s ground: ' + badc.slice(0, 8).join('; '));
    let nOp = 0, blocked = 0; const seenPx = new Set(); for (let y = F.DOOR.a0; y <= F.DOOR.a1; y += .02) for (let z = F.DOOR.z0; z <= F.DOOR.z1; z += .02) { const q = E.project(0, y, z), i = Math.floor(q.sy) * 240 + Math.floor(q.sx); if (seenPx.has(i)) continue; seenPx.add(i); nOp++; if (/^(mostrador|fregadero|alacena)/.test(T0[i] || '')) blocked++; }
    if (blocked) P.push('door: ' + blocked + ' of the opening\'s ' + nOp + ' px are the counter\'s (its end stands in front of the way in)');
    notes.push('door (round 2, La mesa\'s final one): in the wide view its leaf ' + nLeaf + ' px (open into the room against the wall towards the corner, its brass handle ' + knob + ' px), the wall\'s thickness in the opening ' + nRev + ' px, the threshold ' + nThr + ' px (30 kept each); the lowest outside pixel of each of the opening\'s ' + cols + ' columns is the patio\'s ground (' + okc + ': El patio\'s step, the lawn); of the opening\'s ' + nOp + ' px none is the counter\'s (' + blocked + '): the counter starts 1 past the jamb (La mesa\'s .24), its end no longer in front of the way in; whoever comes in stands in the doorway at its threshold (DOOR) on clear floor (the floor check)'); }

  /* thin things are seen: each thin part of the set against what is behind it (the set baked without it), WCAG's contrast ratio */
  { const res = [], k = key0;
    for (const p of ['mesa.patas', 'sillas.patas', 'fregadero']) { if (!G.sin[k][p]) continue; const own = G.parts[k][p] || []; if (!own.length) continue; let ok = 0, sl = 0, sb = 0;
      for (const i of own) { const a = rgbAt(k, i), b = [G.sin[k][p][i * 3], G.sin[k][p][i * 3 + 1], G.sin[k][p][i * 3 + 2]], r = ratio(a, b); if (r >= 2) ok++; sl += lum(a); sb += lum(b); }
      const mr = (Math.max(sl, sb) / own.length + .05) / (Math.min(sl, sb) / own.length + .05);
      if (mr < 2) P.push('thin: ' + p + ' stands out from what is behind it by ' + r2(mr) + ' (its pixels ' + Math.round(ok / own.length * 100) + '% at 2.0 or more)');
      res.push(p + ' ' + r2(mr) + ' (' + Math.round(ok / own.length * 100) + '% of its pixels at 2.0 or more)'); }
    notes.push('thin things of the set against what is behind them (WCAG contrast ratio of the mean luminances; each part\'s pixels): ' + res.join('; ') + ' (the sink and its tap: fregadero)'); }

  /* the moments: compose each as comer.js draw() draws it */
  const STAMP = new Int32Array(240 * 216), OWN = new Int32Array(240 * 216); let stampN = 0;
  const itemsOf = (w, side) => rawItems(w, side).filter(it => MASK[it.key]).map((it, n) => { const [dx, dy] = shiftOf(it); return Object.assign(it, { n, rows: rowsAt(MASK[it.key].rows, dx, dy), px: MASK[it.key].px, dx, dy }); });
  const orderOf = its => { const list = its.filter(i => i.group === 'list'), post = its.filter(i => i.group === 'post'); list.sort((a, b) => a.y - b.y || a.n - b.n); return list.concat(post); };
  const heightOf = (id, p) => id === 'abuela' ? (p.sent ? 48 : 50) : QUIEN_NINO[id] ? (p.sent ? 41 : 44) : (p.sent ? 49 : 56);
  const faceOf = it => { const p = it.o; if (it.kind === 'frog') { const b = frogBox(p); return [b.x + 2, b.y + R(p.dy || 0), b.w - 4, R(b.h * .6)]; }
    if (it.kind !== 'person') return null; const x = R(p.x), top = it.id === 'abuela' ? R(p.y) - (p.sent ? 48 : 50) + R(p.dy || 0) : R(p.y) - heightOf(it.id, p) + 1 + R(p.dy || 0);
    return [x - 6, top + 6, 12, 10]; };
  const planeOf = it => { if (it.kind === 'person' || it.kind === 'arms' || it.kind === 'dog') { const g = E.atZ(R(it.o.x), R(it.o.y) - 1, 0); return (g[0] + g[1]) / E.R2; } return null; };
  // compose: each item owns the pixels it drew last; new: the chairs (sortY 60) and the table (TZ) drawn again over list items behind them
  const compose = (w, side) => { const its = orderOf(itemsOf(w, side)); stampN++; const cov = new Map();
    const fronts = side === 'n' ? [[60, FRONT.sillas], [TZ, FRONT.mesa]] : [];
    let fi = 0; const Z = G.z[key0], TG = TAGS[key0];
    const applyFront = (parts, upto) => { for (const part of parts) for (const i of G.parts[key0][part] || []) { if (STAMP[i] !== stampN) continue; const j = OWN[i]; if (j >= upto) continue; const pl = PLS[j]; if (pl == null) continue; const y = Math.floor(i / 240); if (Z[i] > pl / COS - (y + .5 - E.OY) * T30 / E.S) cov.set(i, part); } };
    const PLS = its.map(it => it.group === 'list' ? planeOf(it) : null);
    its.forEach((it, j) => { it.j = j;
      while (fi < fronts.length && it.group === 'list' && it.y >= fronts[fi][0]) { applyFront(fronts[fi][1], j); fi++; }
      if (it.group === 'post') while (fi < fronts.length) { applyFront(fronts[fi][1], j); fi++; }
      for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; STAMP[i] = stampN; OWN[i] = j; cov.delete(i); } } });
    while (fi < fronts.length) { applyFront(fronts[fi][1], its.length); fi++; }
    LASTCOV = cov;
    return its.map(it => { let tot = 0, vis = 0, fTot = 0, fVis = 0; const by = {}, hid = {}, face = faceOf(it);
      for (const [y, a, b] of it.rows) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; tot++; const inF = face && x >= face[0] && x < face[0] + face[2] && y >= face[1] && y < face[1] + face[3]; if (inF) fTot++;
        const mine = STAMP[i] === stampN && OWN[i] === it.j, c = cov.get(i); if (!mine) { const h = its[OWN[i]].id; hid[h] = (hid[h] || 0) + 1; } else if (c) { hid[c] = (hid[c] || 0) + 1; by[c] = (by[c] || 0) + (inF ? 1000 : 1); } else { vis++; if (inF) fVis++; } } }
      return { it, tot, vis, fTot, fVis, by, hid, face }; }); };
  let LASTCOV = new Map();

  // the moments: every tick inside the acts of the port's play and every step's end, every pair picture
  const allW = []; runs.forEach((r, ri) => { for (const t of NEW[ri].ticks) allW.push([r.story.id + ' ' + r.plan + ' t ' + t.t, t.W, 'tick']); for (const L of NEW[ri].states) allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W, 'step']); });
  for (const ps of pairSides) allW.push(['pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps, sh), 'pair']);
  const TOPS = { mesa: ['mesa'], run: ['estufa', 'mostrador2', 'mostrador'] };
  { const bad = new Map(), sitBad = new Map(), restBad = new Map(), floorBad = new Map(); let nM = 0, nSit = 0, nRest = 0, nFloor = 0; const restSeen = new Set(), sitSeen = new Map();
    // the old picture's table over each sitter: the old composition of the same moment (step ends: the recorded run)
    // (people only: the frog and the things on the cloth are taken away on both sides, so that what they cover is not counted for neither)
    const bare = w => Object.assign(JSON.parse(JSON.stringify(w)), { cosas: [], vuelos: [], perro: null, cq: Object.assign({}, w.cq, { vis: 0 }) });
    const oldSit = new Map(); runs.forEach((r, ri) => r.lines.forEach(ln => { for (const q of compose(bare(ln.W), 'o')) if (q.it.kind === 'person' && q.it.o.sent) { const k2 = q.it.id + J([R(q.it.o.x), R(q.it.o.y), q.it.o.dy || 0]); oldSit.set(r.story.id + ' ' + r.plan + ' ' + ln.path + ' ' + q.it.id, q.hid['the old table'] || 0); } }));
    for (const [where, w, kind] of allW) { nM++; const C = compose(w, 'n');
      for (const r of C) { const it = r.it; if (it.kind !== 'thing' || !it.rows.length) continue;
        // (round 2) a thing on the cloth: its outline against the cloth directly behind it, WCAG, the mean over its outline 2.0 and more
        if (enMesaOf(it.o, 'n') && it.o.k !== 'sombra') { const v = clothContrast(it); if (v) { nCl++; if (v[0] < clWorst[0]) clWorst = [v[0], it.id + ' (' + where + ')']; if (v[0] < 2) clothBad.set(it.id + ' ' + J(it.at), where + ': ' + r2(v[0]) + ' over ' + v[1] + ' px of its outline'); } }
        // (round 2) a thing on the stove: its whole foot on the stove's top face, no pixel of it over the hood
        const sv = stoveOf(it); if (sv) { nSt++; if (sv.off || sv.hood) stoveBad.set(it.id + ' at ' + J(it.at), where + ': ' + sv.off + ' of ' + sv.n + ' px of its foot off the stove\'s top' + (sv.hood ? ', ' + sv.hood + ' px over the hood' : '')); } }
      for (const r of C) { const it = r.it;
        for (const [part, n] of Object.entries(r.by)) { const faceN = Math.floor(n / 1000); if (faceN && it.kind === 'person') bad.set(part + ' over ' + it.id + '\'s face', where + ': ' + faceN + ' px'); }
        if (it.kind === 'person' && it.o.sent && kind === 'step') { nSit++; const rb = compose(bare(w), 'n').find(x => x.it.kind === 'person' && x.it.id === it.id) || r; const setN = Object.entries(rb.by).reduce((s, [p, n]) => s + (n % 1000) + Math.floor(n / 1000), 0), oldN = oldSit.get(where + ' ' + it.id);
          if (oldN != null && setN > oldN + 8) sitBad.set(it.id + ' at ' + [R(it.o.x), R(it.o.y)], where + ': ' + setN + ' px of the set over them, the old table ' + oldN); }
        // what stands on the table rests on it: its lowest rows over the cloth, nothing of the set over it; on the stove's or a counter's top likewise
        if (it.kind === 'thing' && it.group === 'list' && it.o && it.o.vis !== 0 && it.o.z == null) { const on = GEO.entop(it.o.x, it.o.y) ? 'mesa' : null, run = !on && it.o.y < 110 ? 'run' : null; if (!on && !run) continue; const k2 = it.key + J(it.at); if (restSeen.has(k2)) continue; restSeen.add(k2); nRest++;
          const rs = it.rows.filter(q => q[0] >= 0 && q[0] < 216); if (!rs.length) continue; const last = Math.max(...rs.map(q => q[0])); let n = 0, ok = 0;
          for (const [y, a, b] of rs) if (y >= last - 1) for (let x = a; x <= b; x++) { n++; const s = surfaceW(E, F, x + .5, y + 1.5); if ((on ? TOPS.mesa : TOPS.run).includes(s.on)) ok++; }
          if (n && ok < n * .9) restBad.set(it.id + ' (' + it.key.slice(2, 50) + ')', where + ': ' + ok + ' of ' + n + ' px of its foot over the ' + (on ? 'cloth' : 'top') + ' at ' + J(it.at));
          if (Object.keys(r.by).length) restBad.set(it.id + ' covered by the set', where + ': ' + JSON.stringify(r.by)); }
        if (it.kind === 'person' && kind === 'step' && !it.o.sent && !it.o.est) { const x = R(it.o.x), y = R(it.o.y); if (x - 11 >= x0 + 196 || x + 11 <= x0) continue; nFloor++; const s = surfaceW(E, F, x, y - 1);
          const g = E.atZ(x, y - 1, 0), inR = r => g[0] >= r[0] - .05 && g[0] <= r[2] + .05 && g[1] >= r[1] - .05 && g[1] <= r[3] + .05, under = Object.entries(F.FOOT).find(([k2, r2]) => inR(r2));
          if (g[0] < 0 || g[1] < 0 || under) floorBad.set(it.id + ' at ' + [x, y], where + ': ' + (under ? 'under ' + under[0] : 'in the wall')); } } }
    for (const [k, v] of [...bad].slice(0, 30)) P.push('drawn: ' + k + ' (' + v + ')');
    for (const [k, v] of [...sitBad].slice(0, 30)) P.push('seat: ' + k + ' (' + v + ')');
    for (const [k, v] of [...restBad].slice(0, 30)) P.push('on a top: ' + k + ' (' + v + ')');
    for (const [k, v] of [...floorBad].slice(0, 30)) P.push('floor: ' + k + ' (' + v + ')');
    for (const [k, v] of [...clothBad].slice(0, 40)) P.push('on the cloth: ' + k + ' (' + v + ')');
    for (const [k, v] of [...stoveBad].slice(0, 40)) P.push('on the stove: ' + k + ' (' + v + ')');
    notes.push('on the cloth (round 2; round 1 had no such check: a thing\'s colour against the cloth was not measured): at ' + nCl + ' thing-moments (every tick, step\'s end and pair picture) each thing standing on the cloth (not the drawn shadows, sombra, of the review pictures: they are a thing\'s shadow, not a thing) stands out from the cloth directly behind its outline, WCAG mean ' + r2(clWorst[0]) + ' at the least (' + clWorst[1] + '; keep 2.0)');
    notes.push('on the stove (round 2; round 1 asked only 90% of a foot over any top, the stove\'s or a counter\'s, and nothing of the hood): at ' + nSt + ' thing-moments each thing on the stove has its whole foot (its lowest row, each pixel within 2 rows over the stove\'s top face) on the stove\'s top, no pixel of its body over the hood (the steam of what steams rises over it)');
    notes.push('drawn: at ' + nM + ' moments (every tick inside the acts of the port\'s play of the ' + runs.length + ' runs, every step\'s end, every pair picture) composed as comer.js draws them (each item owns what it drew last; the chairs drawn again over whoever is behind them at sortY 60, the table at the old table\'s place TZ): no part of the set over any face; ' + nSit + ' sittings at step ends, each with no more of the set over the one who sits than the old table had (8 px to spare; both pictures with the people alone, so that what the frog or a thing covers counts for neither); ' + nRest + ' things standing on the cloth or on the stove\'s or a counter\'s top, each with 90% and more of its foot over it and nothing of the set over it; ' + nFloor + ' step ends of someone standing in the view, each on clear floor'); }

  /* at every step's end each person's, the dog's and the frog's share seen no less than in the old picture of that moment less 10%, their face no
     less at all; whoever was wholly inside the view in the old picture is wholly inside with 3 px to spare */
  { const lows = [], edges = []; let n = 0;
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach((ln, li) => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return;
      const o = new Map(compose(ln.W, 'o').map(q => [q.it.kind + q.it.id, q])), nw = compose(tw.W, 'n');
      for (const q of nw) { const p = o.get(q.it.kind + q.it.id); if (!p || !p.tot || !q.tot) continue;
        if (q.it.kind !== 'arms') { const bo = rowsBox(p.it.rows), bn = rowsBox(q.it.rows); if (bo && bn && within(bo, VIEW) && !within([bn[0] - 3, bn[1] - 3, bn[2] + 6, bn[3] + 6], VIEW)) edges.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' ' + JSON.stringify(bn)); }
        if (!['person', 'frog', 'dog'].includes(q.it.kind)) continue; n++;
        const sN = q.vis / q.tot, sO = p.vis / p.tot, fN = q.fTot ? q.fVis / q.fTot : 1, fO = p.fTot ? p.fVis / p.fTot : 1;
        if (process.env.COMER_DBG && (r.story.id + ' ' + r.plan + ' ' + ln.path) === process.env.COMER_DBG && fN < 1) console.log('DBG', q.it.id, JSON.stringify(q.face), JSON.stringify(q.hid), JSON.stringify(nw.filter(x => x.it.kind === 'person' || x.it.kind === 'frog').map(x => [x.it.id, x.it.j, x.it.y, rowsBox(x.it.rows)])));
        if (fN < fO - 1e-9 || sN < sO - .1) lows.push(r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + q.it.id + ' seen ' + R(sN * 100) + '% (face ' + R(fN * 100) + '%), the old ' + R(sO * 100) + '% (' + R(fO * 100) + '%), by ' + JSON.stringify(q.hid)); } }); });
    for (const l of lows) P.push('seen: ' + l);
    for (const l of [...new Set(edges)].slice(0, 30)) P.push('edge: ' + l + ' (wholly inside the view in the old picture)');
    notes.push('seen: at ' + n + ' person-, dog- and frog-moments (every step\'s end of the ' + runs.length + ' runs) each seen no less than in the old picture less 10%, the face no less (' + lows.length + ' less); everyone and everything wholly inside the view in the old picture of a moment wholly inside with 3 px to spare (' + new Set(edges).size + ' not)'); }
  const picture = (w, skip) => { const C2 = compose(w, 'n'), out = G.rgb[key0].slice(); const cov = LASTCOV;
    for (const r of C2) { const it = r.it; if (!it.px || (skip && skip(it))) continue; for (let q = 0; q < it.px.length; q += 4) { const i0 = it.px[q], x = i0 % 240 + it.dx, y = Math.floor(i0 / 240) + it.dy; if (x < 0 || y < 0 || x >= 240 || y >= 216) continue; const i = y * 240 + x;
      if (STAMP[i] === stampN && OWN[i] === it.j && !cov.has(i)) { out[i * 3] = it.px[q + 1]; out[i * 3 + 1] = it.px[q + 2]; out[i * 3 + 2] = it.px[q + 3]; } } }
    return out; };
  return P.concat(checkAsks(sh, G, runs, { E, F, x0, TAGS, rgbAt, compose, itemsOf, allW, faceOf, notes, picture, heightOf }));
}

// the review and level pictures: a pair's two pictures share one window. Zoom 1: the 196 x 104 window holding every person, thing and the frog
// of both pictures with 2 px to spare (as near the old window as that allows); when the two pictures differ in less than 1.5% of it (the pair
// is about a small thing), zoom 2: the 98 x 52 region round what differs, holding whole whatever it meets
let DBG_PIC = false; const DBG_WHY = [];
function placePictures(sh, C) {
  const byWord = {}; for (const ps of pairSidesOf()) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
  for (const [word, sides] of Object.entries(byWord)) { const ws = {}, boxes = [];
    for (const side of Object.keys(sides)) { ws[side] = pairW(sides[side], sh); for (const it of C.itemsOf(ws[side], 'n')) { if (it.kind === 'arms') continue; const b = rowsBox(it.rows.filter(q => q[0] >= 0 && q[0] < 216)); if (b) boxes.push(b); } }
    const u = boxes.reduce((a, b) => a ? [Math.min(a[0], b[0]), Math.min(a[1], b[1]), Math.max(a[0] + a[2], b[0] + b[2]) - Math.min(a[0], b[0]), Math.max(a[1] + a[3], b[1] + b[3]) - Math.min(a[1], b[1])] : b, null);
    const old = sides.si.spec.cam, clampX = (v, w) => Math.max(0, Math.min(240 - w, v)), clampY = (v, h) => Math.max(0, Math.min(216 - h, v));
    const fit = (w, h) => { const cx = u[0] + u[2] / 2, cy = u[1] + u[3] / 2; let x = clampX(R(cx - w / 2), w), y = clampY(R(cy - h / 2), h); if (u[2] + 4 <= w) x = clampX(Math.min(Math.max(x, u[0] + u[2] + 2 - w), u[0] - 2), w); if (u[3] + 4 <= h) y = clampY(Math.min(Math.max(y, u[1] + u[3] + 2 - h), u[1] - 2), h); return [x, y, w, h]; };
    let crop = fit(196, 104), zoom = 1; if (crop[0] < 0 || crop[0] > 44) crop[0] = Math.max(0, Math.min(44, crop[0]));
    if (ws.si && ws.no) { const A = C.picture(ws.si), B = C.picture(ws.no); let n = 0, m = 0, d = null; for (let y = crop[1]; y < crop[1] + 104; y++) for (let x = crop[0]; x < crop[0] + 196; x++) { m++; const i = (y * 240 + x) * 3; if (A[i] !== B[i] || A[i + 1] !== B[i + 1] || A[i + 2] !== B[i + 2]) { n++; d = d ? [Math.min(d[0], x), Math.min(d[1], y), Math.max(d[2], x), Math.max(d[3], y)] : [x, y, x, y]; } }
      if (d && n < m * .015) { zoom = 2; const cx = (d[0] + d[2]) / 2, cy = (d[1] + d[3]) / 2; crop = [clampX(R(cx - 49), 98), clampY(R(cy - 26), 52), 98, 52];
        // the nearest region (to the one centred on what differs) that holds what differs, in which every thing it meets is whole, every person it
        // meets has the whole head, and no set part shows less than 12 px (the check's own tests)
        const its = [ws.si, ws.no].flatMap(w2 => withArms(C.itemsOf(w2, 'n')).filter(it => it.rows.length)), T = C.TAGS.comer, c0 = crop.slice();
        const why = t => { if (DBG_PIC) DBG_WHY.push(t); }, bad = cr => { let v = 0; if (!within([d[0], d[1], d[2] - d[0] + 1, d[3] - d[1] + 1], cr)) { v += 5; why('what differs ' + J(d)); }
          for (const it of its) { const bx = rowsBox(it.rows); if (it.kind === 'person') { const top = Math.min(...it.rows.map(q => q[0])), hd = rowsBox(it.rows.filter(q => q[0] < top + 16)), inPic = it.all.some(q => q[0] >= cr[1] && q[0] < cr[1] + cr[3] && q[2] >= cr[0] && q[1] < cr[0] + cr[2]); if (inPic && !within([hd[0] - 2, hd[1] - 2, hd[2] + 4, hd[3] + 4], cr)) { v++; why(it.id + ' head ' + J(hd)); } }
            else if (meets(bx, cr) && !within([bx[0] - 2, bx[1] - 2, bx[2] + 4, bx[3] + 4], cr)) { v++; why(it.id + ' ' + J(bx)); } }
          const cnt = {}; for (let y = cr[1]; y < cr[1] + cr[3]; y++) for (let x = cr[0]; x < cr[0] + cr[2]; x++) { const t = (T[y * 240 + x] || '').split('.')[0]; if (t) cnt[t] = (cnt[t] || 0) + 1; }
          for (const [t, c] of Object.entries(cnt)) if (c < 12 && t !== 'pared') { v++; why(t + ' ' + c + ' px'); } return v; };
        let best = null; for (let dy = -34; dy <= 34; dy++) for (let dx = -44; dx <= 44; dx++) { const cr = [clampX(c0[0] + dx, 98), clampY(c0[1] + dy, 52), 98, 52], sc = bad(cr) * 1e4 + Math.abs(cr[0] - c0[0]) + Math.abs(cr[1] - c0[1]); if (!best || sc < best[0]) best = [sc, cr]; }
        crop = best[1]; if (best[0] >= 1e4) { DBG_PIC = true; bad(crop); DBG_PIC = false; console.log('pictures: ' + word + ' fits nowhere whole; at ' + J(crop) + ': ' + DBG_WHY.splice(0).join('; ')); } } }
    for (const side of ['si', 'no']) { const nm = deacc(word) + '.' + side; if (!sh.pictures[nm]) continue; Object.assign(sh.pictures[nm], { zoom, crop: crop.slice(), what: (zoom === 1 ? 'the 196 x 104 window over every person and thing of the pair, with 2 px to spare' : 'zoom 2: the 98 x 52 region round what differs between the two pictures (in the whole window they differ in less than 1.5%)') + '; the old: ' + JSON.stringify(old) }); } }
  for (const l of sh.level) { const pc = sh.pictures[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }
  for (const e of sh.remap) if (e.kind === 'cam' && e.crops) for (const n of Object.keys(e.crops)) e.crops[n] = { crop: sh.pictures[n].crop, zoom: sh.pictures[n].zoom };
}

function checkAsks(sh, G, runs, C) {
  const P = [], { E, F, x0, TAGS, rgbAt, compose, itemsOf, allW, faceOf, notes, heightOf } = C, NEW = G.TICKS, key0 = 'comer';
  placePictures(sh, C);
  const facesOf = (w, side = 'n') => { const out = []; for (const it of itemsOf(w, side)) { if ((it.kind === 'person' && !(it.o.al != null && it.o.al < .5)) || (it.kind === 'frog' && !(it.o.al < .5))) out.push([it.kind === 'frog' ? 'the frog\'s face' : it.id + '\'s face', faceOf(it)]); } return out; };
  const VIEWR = [x0, 0, 196, 216];

  /* bubbles: the thought clouds (a person's, the frog's) wholly inside the view, clear of the rounds card, on no face but their thinker's;
     the speech bubble's tail (juego.js donde: talkAt over a head, the frog's beside him) inside the view; with the words hidden (?txt=no) the
     empty bubble comer.js draws over the speaker (hab) wholly inside the view, on no face */
  { let nB = 0, nT = 0; const seen = new Set();
    for (const [where, w] of allW) { const boards = boardsOf(w, x0), faces = facesOf(w), its = itemsOf(w, 'n');
      for (const it of its) { if (it.kind !== 'cloud') continue; const b = rowsBox(it.rows); if (!b) continue; const k = J([it.key, it.dx, it.dy, boards, faces]); if (seen.has(k)) continue; seen.add(k); nB++;
        if (!within(b, VIEWR)) P.push('cloud: ' + where + ' ' + it.id + ' ' + JSON.stringify(b) + ' is not wholly inside the view');
        for (const [bn, bb] of boards) if (meets(b, bb)) P.push('cloud: ' + where + ' ' + it.id + ' is over ' + bn);
        const own = it.id === 'the frog\'s cloud' ? 'the frog\'s face' : it.id.replace('\'s cloud', '\'s face');
        for (const [fn, f] of faces) if (fn !== own && rowsMeet(it.rows, f)) P.push('cloud: ' + where + ' ' + it.id + ' is on ' + fn); }
      const talk = w.TALK; if (!talk) continue; nT++;
      let a = null, u = null, hh = 6; if (talk === 'coqui') { const q = w.cq; if (q && q.vis) { const b = frogBox(q); a = [b.x + b.w / 2, b.y + R(q.dy || 0) - 1]; u = [b.x + (b.w >> 1), b.y + R(q.dy || 0) - 3]; hh = b.w >> 1; } } else { const p = (w.gente || {})[talk]; if (shownP(p)) { a = [R(p.x), R(p.y) - altoOf(talk, p) - 1]; u = [a[0], a[1] - 1]; } }
      if (!a) continue; if (a[0] < x0 + 3 || a[0] > x0 + 193 || a[1] < 3) P.push('talk: ' + where + ' ' + talk + '\'s bubble\'s tail ' + JSON.stringify(a) + ' is not inside the view');
      // where comer.js puts the empty bubble with the words hidden (LIBRE): the first of talk.places clear of every other face, wholly in the view across
      { const own = talk === 'coqui' ? 'the frog\'s face' : talk + '\'s face', Fc = faces.filter(f => f[0] !== own).map(f => f[1]);
        for (const [sd, dy] of TALK) { const x = u[0] + sd * (hh + 16), y = u[1] + dy, r = [x - 9, y - 16, 19, 13]; if (r[0] >= x0 && r[1] >= 0 && r[0] + r[2] <= x0 + 196 && !Fc.some(f => meets(f, r))) { u = [x, y]; break; } } }
      const hab = talk === 'abuela' && w.gente.abuela.x > 190 && w.gente.abuela.y < 170 ? [a[0] - 28, a[1] - 7, 19, 13] : [u[0] - 9, u[1] - 16, 19, 13]; if (!within(hab, VIEWR)) P.push('talk: ' + where + ' the empty bubble over ' + talk + ' ' + JSON.stringify(hab) + ' is not wholly inside the view');
      for (const [fn, f] of faces) if (fn !== (talk === 'coqui' ? 'the frog\'s face' : talk + '\'s face') && meets(hab, f)) P.push('talk: ' + where + ' the empty bubble over ' + talk + ' is on ' + fn); }
    notes.push('bubbles: ' + nB + ' thought clouds (a person\'s, the frog\'s) at every moment wholly inside the view, clear of the rounds card, on no face but their thinker\'s; at ' + nT + ' moments someone speaks: the tail of the speech bubble (juego.js donde) inside the view, and the empty bubble comer.js draws over the speaker with the words hidden (hab, 19 x 13 over the head) wholly inside the view and on no other face'); }

  /* the asks: hint frames, the hand, the answer cards and the hint drawn round each card; the asked thing seen whole, uncovered, on a plain surface */
  const COS2 = { mant: [26, 18], choc: [26, 18], cesta: [48, 24], cafetera: [24, 28], azucarera: [24, 18], olla: [30, 26], fuente: [56, 22], pl_papa: [24, 10], pl_rana: [18, 9] };
  const cajaBox = (id, p, old) => { const h = altoOf(id, p); if (!p.sent) return [R(p.x) - 11, R(p.y) - h, 22, h]; const lim = old ? 138 : R(SY(R(p.x), 126)); /* comer.js caja: MESA[1] + 26 in the old, SY(x, MESA[1] + 14) in the port */ return [R(p.x) - 11, R(p.y) - h, 22, Math.max(40, lim - (R(p.y) - h))]; };
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) { if (k === 'silla_papa') { const i = w.sitio && w.sitio.papa != null ? w.sitio.papa : 3; return old ? [[90, 114, 138, 162][i] - 10, 86, 20, 36] : t.byChair[i]; } return old ? t.old.box : (t.hintBox || t.box); }
    if (/^di_/.test(k)) { const b = frogBox(w.cq); return [b.x + (b.w >> 1) - 8, b.y - 27, 16, 10]; }
    if (COS2[k]) { const o = (w.cosas || []).find(c => c.id === k && c.vis !== 0); if (!o) return null; const [ww, hh] = COS2[k]; return [R(o.x) - (ww >> 1), R(o.y) - hh, ww, hh]; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shownP(p) ? cajaBox(k, p, old) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !old) return t.hand; const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  // comer.js CARTAS (the port's): where the cards stand at this moment, by the faces round them
  const cartas = w => { const n = w.resp.length, Fc = []; for (const k in w.gente || {}) { const p = w.gente[k]; if (p && p.vis !== 0) Fc.push([R(p.x) - 6, R(p.y) - altoOf(k, p) + 7 - (k === 'abuela' && p.sent ? 1 : 0) + R(p.dy || 0), 12, 10]); }
    for (const cx of CARDS.cx) { let ok = 1; for (let i = 0; i < n && ok; i++) { const c = n > 2 ? [R(cx - 70 + i * 50), CARDS.y, 40, 36] : i === 0 ? [R(cx - 50), CARDS.y, 40, 36] : [R(cx + 10), CARDS.y, 40, 36], fr = [c[0] - 12, c[1] - 12, 64, 60];
      if (boardsOf(w, x0).some(([bn, bb]) => meets([c[0] - 2, c[1] - 2, 44, 40], bb))) { ok = 0; break; }
      for (const f of Fc) { if (meets(fr, [f[0] - 2, f[1] - 6, 16, 16]) || handOn([c[0] + 20, c[1] + 30], f)) { ok = 0; break; } } } if (ok) return [cx, CARDS.y]; } return [CARDS.cx[0], CARDS.y]; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.resp ? cartas(w) : w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
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
      const key = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.cosas, w.tarjeta, w.respEn]); if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), fOld = facesOf(wo, 'o'), its = itemsOf(w, 'n');
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within(f, VIEWR)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow (+- 12) are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn);
        for (const it of its) { if (it.kind === 'frog') { const f = frogBox(w.cq); if (meets(c, [f.x + 2, f.y + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' covers the frog'); continue; }
          if (!['person', 'arms', 'thing', 'cloud', 'dog'].includes(it.kind)) continue; const n = rowsMeet(it.rows, it.kind === 'person' ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id); }
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
      // the thing asked for (and every thing among the choices): whole in the view, nothing drawn over it more than the old, a plain surface round it
      for (const o of new Set([spot, ...opts])) { if (!COS2[o]) continue; const cn = compose(w, 'n'), co = compose(wo, 'o'), q = cn.find(x => x.it.kind === 'thing' && x.it.cid === o), qo = co.find(x => x.it.kind === 'thing' && x.it.cid === o); if (!q) continue; nTell++;
        const bxA = rowsBox(q.it.rows); if (!within(bxA, VIEWR)) P.push('tell: ' + where + ' ' + o + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        const hidN = q.tot - q.vis, hidO = qo ? qo.tot - qo.vis : 0; if (hidN > hidO + 2) { P.push('tell: ' + where + ' ' + o + ': ' + hidN + ' px of it covered (the old ' + hidO + ') by ' + JSON.stringify(q.hid)); } else if (hidN > 2) coverOld.add(o + ' (' + where.split(' (')[0] + ', as the old: ' + Object.keys(q.hid).join(', ') + ')');
        let n = 0, ok = 0; const own = new Set(); for (const [y, a, bb] of q.it.rows) for (let x = a; x <= bb; x++) own.add(y * 240 + x); const T = TAGS[key0];
        for (const [y, a, bb] of q.it.rows) for (let x = a - 2; x <= bb + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i) || x < 0 || x >= 240 || y + dy < 0 || y + dy >= 216) continue; n++; const t = T[i], s = G.surf[key0][i]; if (['mesa', 'mostrador', 'mostrador2', 'estufa', 'campana', 'pared'].includes(t) || s === 'floor') ok++; }
        if (n && ok < n * .75) P.push('tell: ' + where + ' ' + o + ': only ' + Math.round(ok / n * 100) + '% of what is round it is a plain surface'); } }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least; the table and the room by their hint boxes), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face and not cut by the view\'s edge where the old was not' + (handOld.size ? ' (as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow (card +- 12) 4 px inside the view (' + cardSpare + ' px more at the least), 2 px clear of the rounds card and of everyone\'s head and body, over no thing; the hint round each card 2 px inside the view and across no head, its hand on no face; ' + nTell + ' times a thing asked for or among the choices: whole in the view, covered no more than in the old picture' + (coverOld.size ? ' (' + [...coverOld].slice(0, 6).join('; ') + ')' : '') + ', a plain surface round it');
  sh.checks.asks = asks.filter((a, i) => asks.findIndex(b => b.story === a.story && b.plan === a.plan && b.path === a.path) === i).map(a => ({ story: a.story, plan: a.plan, path: a.path, before: a.before, spot: a.spot }));

  /* heads: nobody's head against the window's bars, the cupboard's edge or the hood where the old picture kept it clear */
  { const OLDR = { ventana: [188, 22, 38, 38], alacena: [26, 33, 44, 42], campana: [193, 95, 30, 6] }; let n = 0; const bad = new Map(), T = TAGS[key0];
    runs.forEach((r, ri) => { const Ls = NEW[ri].states; r.lines.forEach(ln => { const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw) return;
      const fo = facesOf(ln.W, 'o'); for (const [fn, f] of facesOf(tw.W)) { n++; const hr = [f[0] - 4, f[1] - 8, f[2] + 8, f[3] + 10], o = fo.find(e => e[0] === fn), ho = o ? [o[1][0] - 4, o[1][1] - 8, o[1][2] + 8, o[1][3] + 10] : null;
        for (const part of ['ventana', 'alacena', 'campana']) { let m = 0; for (let y = hr[1]; y < hr[1] + hr[3]; y++) for (let x = hr[0]; x < hr[0] + hr[2]; x++) if (x >= 0 && y >= 0 && x < 240 && y < 216 && T[y * 240 + x] === part) m++; if (m > 3 && !(ho && meets(ho, OLDR[part]))) bad.set(fn + ' against ' + part, r.story.id + ' ' + r.plan + ' ' + ln.path + ' (' + m + ' px)'); } } }); });
    for (const [k, v] of [...bad].slice(0, 20)) P.push('head: ' + k + ' (' + v + ')');
    notes.push('heads: at ' + n + ' face-moments (step ends) nobody\'s head against the window, the wall cupboard or the hood where the old picture kept it clear'); }

  /* steam is seen: each puff (comer.js vapor: two wisps, 9 rows, swaying) against what is directly behind it, WCAG's contrast ratio, at every moment */
  { const puffs = (x, y, n, h) => { const out = [], H = Math.min(h || 9, 9); for (let t = 0; t < 12; t++) for (let i = 0; i < (n || 2); i++) { const dx = i * 7 - 3; for (let k = 0; k < H; k++) { const sw = Math.round(Math.sin((k + t * 1.2 + i * 4) / 2.4) * 2.4), al = Math.max(.12, .85 - k * 14 / H * .065); out.push({ t, x: x + dx + sw, y: y - k, al }); } } return out; };
    const seenK = new Set(); let n = 0, worst = 99, worstAt = '';
    for (const [where, w] of allW) { const its = itemsOf(w, 'n'), list = [];
      for (const o of w.cosas || []) { if (!o || o.vis === 0 || !o.vapor) continue; const k = o.k;
        if (k === 'plato' || k === 'platoc') list.push(['steam over a plate', o.x, o.y - 12, 1, 9]);
        else if (k === 'olla') { if (o.v !== 'vacio') list.push(['steam over the pot', o.x, o.y - 22, 2, 9]); }
        else if (k === 'cesta') { list.push(['steam over the basket', o.x + (o.vdx || 0), o.y - (o.vdy == null ? 18 : o.vdy), o.vn || 2, o.vh]); }
        else list.push(['steam over ' + (o.id || k), o.x + (o.vdx || 0), o.y - (o.vdy == null ? (k === 'taza' ? 15 : 12) : o.vdy), o.vn || 2, o.vh]); }
      for (const [what, x, y, nn, h] of list) { const k2 = what + R(x) + ',' + R(y) + its.map(i => i.key + J(i.at)).join(); if (seenK.has(k2)) continue; seenK.add(k2); n++;
        const pic = C.picture(w, it => it.o && it.o.vapor); let sl = 0, sb = 0, m = 0;
        // each row of a wisp (where it is drawn at alpha .4 and more: its fading top is meant to melt away) is seen by its edge or by its core: the
        // contrast of the better of the two, its colour laid over what is behind it at the row's alpha; the puff's is the mean of its rows
        for (const pf of puffs(R(x), R(y), nn, h)) { if (pf.al < .4) continue; const part = cols => { let a = 0, b2 = 0, k = 0; for (const [dx, col] of cols) { const xx = pf.x + dx - 1, yy = pf.y; if (xx < 0 || yy < 0 || xx >= 240 || yy >= 216) continue; const i = yy * 240 + xx, behind = [pic[i * 3], pic[i * 3 + 1], pic[i * 3 + 2]], c = behind.map((v, q) => v + (col[q] - v) * pf.al); a += lum(c); b2 += lum(behind); k++; } return k ? (Math.max(a, b2) / k + .05) / (Math.min(a, b2) / k + .05) : 1; };
          sl += Math.max(part([[0, [92, 108, 146]], [3, [92, 108, 146]]]), part([[1, [255, 255, 255]], [2, [255, 255, 255]]])); m++; }
        const rr = m ? sl / m : 99; if (rr < worst) { worst = rr; worstAt = what + ' (' + where + ')'; }
        if (rr < 2) P.push('steam: ' + what + ' stands out from what is behind it by ' + r2(rr) + ' (' + where + ')'); } }
    notes.push('steam: ' + n + ' distinct puffs (every frame of their rise, as comer.js draws them with the help\'s darker edge) against what is directly behind them (the picture without what steams): each row of a wisp drawn at alpha .4 and more seen by its edge or its core (WCAG contrast of that colour over what is behind it), the mean over its rows ' + r2(worst) + ' at the least (' + worstAt + ')'); }

  /* the preview puts everyone where the sheet's rule does, at every recorded moment; the rule puts everyone at rest where the port's play has them */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    const MV = sh.moves.flatMap(m => (m.places || [])), RMall = sh.remap.filter(e => e.moved && e.kind === 'point');
    const remapW = (w0, story) => { const w = JSON.parse(JSON.stringify(w0)), RM = RMall.filter(e => e.uses.some(u => u.startsWith(story + '.json')));
      const find = (who, p) => MV.find(q => q.who === who && q.old[0] === R(p.x) && q.old[1] === R(p.y)) || RM.find(e => e.old[0] === R(p.x) && e.old[1] === R(p.y));
      for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) { const m = find(id, p); if (m) { p.x = m.new[0] + (p.x - R(p.x)); p.y = m.new[1] + (p.y - R(p.y)); } }
      for (const p of (w.cosas || []).concat(w.vuelos || [])) if (p && p.x != null) { const m = find('cosa', p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
      if (w.perro) { const m = find('perro', w.perro); if (m) { w.perro.x = m.new[0]; w.perro.y = m.new[1]; } }
      if (w.cq) { const mq = MV.find(m2 => m2.who === 'cq.feet' && m2.old[0] === w.cq.x + 16 && m2.old[1] === w.cq.y + 27) || RM.find(e => e.old[0] === w.cq.x && e.old[1] === w.cq.y && e.uses.every(u => /\.cq$/.test(u))); if (mq) { if (mq.who === 'cq.feet') { w.cq.x = mq.new[0] - 16; w.cq.y = mq.new[1] - 27; } else { w.cq.x = mq.new[0]; w.cq.y = mq.new[1]; } } }
      return w; };
    const places = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)]; if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y];
      (w.cosas || []).forEach((c, i) => { if (c && c.vis !== 0) o['cosa.' + (c.id || c.k + i)] = [R(c.x), R(c.y)]; }); if (w.perro && w.perro.vis !== 0) o.perro = [R(w.perro.x), R(w.perro.y)]; return o; };
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = places(remapW(ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw || li === 0) return; const prev = places(remapW(r.lines[li - 1].W, r.story.id)), port = places(tw.W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k]) continue; nR++; if (port[k].join() !== p.join()) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    sh.checks.rule = { places: nR, differ: badR, what: 'places at rest the rule (moves.places, remap) does not name and the port\'s play has elsewhere: the code moves them (constants and lines of moves), the port reads them from there', examples: [...off.keys()].slice(0, 12) };
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places) comer-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); of the ' + nR + ' places at rest, ' + (nR - badR) + ' are where the port\'s play has them by the rule alone, the other ' + badR + ' are placed by the moved code itself (checks.rule)'); }

  /* the review pictures: the two of a pair differ; everything in each whole with 2 px to spare; no zoom 2 picture shows a set part's cut-off piece */
  { const byWord = {}; for (const ps of pairSidesOf()) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps; const diffs = [], pairPct = []; let nHead = 0;
    for (const [word, sides] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides)) { const ps = sides[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps, sh); ws[side] = w;
        for (const it of withArms(itemsOf(w, 'n'))) { const b = rowsBox(it.rows); if (!b) continue;
          if (it.kind === 'person' && pc.zoom === 2) { const top = Math.min(...it.rows.map(q => q[0])); nHead++; const hd = rowsBox(it.rows.filter(q => q[0] < top + 16)), inPic = it.all.some(q => q[0] >= pc.crop[1] && q[0] < pc.crop[1] + pc.crop[3] && q[2] >= pc.crop[0] && q[1] < pc.crop[0] + pc.crop[2]); if (inPic && !within([hd[0] - 2, hd[1] - 2, hd[2] + 4, hd[3] + 4], pc.crop)) P.push('pair ' + nm + ': ' + it.id + '\'s head ' + JSON.stringify(hd) + ' is not whole with 2 px to spare in ' + JSON.stringify(pc.crop)); continue; }
          if (!within([b[0] - 2, b[1] - 2, b[2] + 4, b[3] + 4], pc.crop) && meets(b, pc.crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with 2 px to spare in ' + JSON.stringify(pc.crop)); }
        if (pc.zoom === 2) { const T = TAGS[key0], cnt = {}; for (let y = pc.crop[1]; y < pc.crop[1] + pc.crop[3]; y++) for (let x = pc.crop[0]; x < pc.crop[0] + pc.crop[2]; x++) { const t = (T[y * 240 + x] || '').split('.')[0]; if (t) cnt[t] = (cnt[t] || 0) + 1; }
          for (const [t, c] of Object.entries(cnt)) if (c < 12 && t !== 'pared') P.push('pair ' + nm + ': shows only ' + c + ' px of ' + t + ' (a cut-off piece)'); } }
      if (!ws.si || !ws.no) continue; const d = [];
      { const pcs = sh.pictures[deacc(word) + '.si'], crop = pcs.crop, A = C.picture(ws.si), B = C.picture(ws.no); let n = 0, m = 0; for (let y = crop[1]; y < crop[1] + crop[3]; y++) for (let x = crop[0]; x < crop[0] + crop[2]; x++) { m++; const i = (y * 240 + x) * 3; if (A[i] !== B[i] || A[i + 1] !== B[i + 1] || A[i + 2] !== B[i + 2]) n++; }
        pairPct.push(deacc(word) + ' ' + r2(n / m * 100) + '%'); if (n < m * .015) P.push('pair ' + word + ': the two pictures differ in ' + n + ' px of ' + m + ' (keep 1.5%)'); } for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) d.push(k);
      if (!d.length) P.push('pair ' + word + ': the two pictures are the same'); diffs.push(deacc(word) + ': ' + d.join(', ')); }
    notes.push('pairs: ' + pairSidesOf().length + ' review pictures (the ' + sh.level.length + ' level pictures are among them): everything in each whole with 2 px to spare (a person in a zoom 2 picture whole but for the feet), no zoom 2 picture with a cut-off piece of the set; what differs: ' + diffs.join('; ') + '; the pixels that differ between yes and no (keep 1.5%): ' + pairPct.join(', ') + '; ' + nHead + ' people in zoom 2 pictures, each that has any part in it (the body, a sleeve, a hand, what they hold: round 2; round 1 left out the arms and what they hold, so a cut sleeve passed) with the whole head inside with 2 px to spare'); }

  /* states, bakes, reach */
  { if (G.ms.comer.first >= 150) P.push('bake: the first bake took ' + R(G.ms.comer.first) + ' ms in a fresh page (keep under 150)');
    const alc = new Set(); for (const T of NEW) for (const a of T.alc || []) alc.add(a.replace(/ at .*/, ''));
    sh.checks.reach = { what: 'comer.js\'s own measure (window.__ALC): a hand drawn farther than its arm reaches, in the port\'s play (the old page\'s is empty); the arm is drawn stretched there', hands: [...alc].sort() };
    notes.push('states: one baked state, reached by every moment, pair and level picture; its first bake in a fresh page under 150 ms (the median of five); hands beyond their arm in the port\'s play: ' + alc.size + ' kinds (checks.reach)'); }
  return P;
}
