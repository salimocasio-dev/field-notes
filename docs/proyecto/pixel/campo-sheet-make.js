#!/usr/bin/env node
'use strict';
/* El campo's sheet (order 34a): writes docs/proyecto/pixel/campo-sheet.json from campo-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/campo-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.CAMPO_SET), its part map, its depth and every castShadow call from campo-set.html in headless Chrome; measures
   the old sprite layer's bubbles, people, dog, balls, basket and flower (historia/ engine.js, juego.js, kit.js, escenas/campo.js, as they are);
   projects every world point with the engine's own formula; checks the sheet against coqui/ref/escenas/campo/ (positions.json, inventory.json,
   pairs.json) and against every moment of every recorded run of the scene's stories (coqui/tool/ref/trazas/juega.mjs --states, into a temp
   folder); and loads campo-preview.html (over a local http server it starts and stops) to check that the preview puts everyone where the sheet
   does, at every moment. Nothing in the repo is written but the sheet. A second run writes the same bytes. El camino's maker
   (camino-sheet-make.js) is the model: the same rules, the same way of checking. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'campo-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/campo');
// the baked states: one. Every state a story, a review pair or a level picture reaches is this one (checked)
const STATES = ['campo'];
const keyOf = w => 'campo';
const queryOf = k => '';
const SOLID = ['arbol', 'juncos'];   // what stands on the ground

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, kinds: {}, rgb: {}, leaf: {}, shadows: {} };
  for (const key of STATES) {
    await page.goto('file://' + path.join(__dirname, 'campo-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(CAMPO_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      // the leaves' reach: every pixel a swaying leaf can take at any wind step (none here: the tree's and the reeds' are still), by part
      const leaf = {}; for (const [name, [a, b]] of Object.entries(PART_LEAVES)) { const out = new Set();
        for (let j = a; j < b; j++) { const L = leaves[j], reach = Math.min(1, Math.max(.3, (L.z - 2.5) / 3)), mx = Math.round(1.55 * reach * .9), my = Math.round(reach * .45);
          for (let n = 0; n < L.pixels.length; n += 4) for (let dx = -mx; dx <= mx; dx++) for (let dy = -my; dy <= my; dy++) { const x = L.pixels[n] + dx, y = L.pixels[n + 1] + dy; if (x >= 0 && y >= 0 && x < W && y < H) out.add(y * W + x); } }
        leaf[name] = [...out]; }
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      const live = DEPTH.live(), shown0 = {}; TAGS.forEach((t, i) => { if (t && live[i] === bakedZ[i]) (shown0[t] = shown0[t] || []).push(i); });
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; GROUND_CACHE = null; const t0 = performance.now(); buildSet(); const first = performance.now() - t0;
      const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      castShadow = cs0; part = part0;
      // the ground as the set lays it (before shadows and occlusion), and which of its pixels are lit lawn in the baked picture
      const raw = Array.from(GROUND_CACHE.pix), lit = [], shade = Array.from(staticShadow); for (let i = 0; i < W * H; i++) lit.push(kinds[i] === KIND_GRASS && bakedZ[i] === groundZ[i] && !staticShadow[i] ? 1 : 0);
      const onGround = []; for (let i = 0; i < W * H; i++) onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0);
      // over the lake: the ground point (z 0) under each pixel is past the shore
      const wet = [], shoreV = []; for (let i = 0; i < W * H; i++) { const g = unproject(i % W + .5, Math.floor(i / W) + .5), up = Math.floor(i / W) + .5 >= CAMPO_SET.HZ, v = up ? CAMPO_SET.shore(g.x, g.y) : 9; wet.push(v < 0 ? 1 : 0); shoreV.push(Math.round(v * 1e4) / 1e4); }
      // the reed bed's footprint on the ground (where a reed stands), and the earth patch's
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(DEPTH.z), kinds: Array.from(kinds), K: { road: KIND_ROAD, grass: KIND_GRASS, water: KIND_WATER, none: KIND_NONE }, rgb: rgbA, leaf, calls, bake: BAKE_MS,
        first, warm, shown0, shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), raw, lit, onGround, shade, wet, shoreV, glints: LOOK.glints ? LOOK.glints.map(g => g.i) : [],
        PATCH: PATCH.map(c => rgb(...c)), SKYB: SKY.bands };
    });
    G.ms = { first: g.first, warm: g.warm, page: g.bake };
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, K: g.K, PATCH: g.PATCH, SKYB: g.SKYB });
    G.parts[key] = g.parts; G.z[key] = g.z; G.kinds[key] = g.kinds; G.rgb[key] = g.rgb; G.leaf[key] = g.leaf; G.shadows[key] = g.calls;
    for (const k of ['shown0', 'shadowPx', 'raw', 'lit', 'onGround', 'shade', 'wet', 'shoreV', 'glints']) (G[k] = G[k] || {})[key] = g[k];
  }
  if (errs.length) throw new Error(errs.join('; '));
  G.M = await measure(await browser.newPage());
  const sheet = make(G);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  const runs = storyStates();
  G.TICKS = await tickStates(browser, runs);
  G.PV = await previewPlaces(browser, runs);
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 250).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the old sprite layer, measured in the browser: every bubble's rectangle, the people's, the dog's, the balls', the basket's pixels ---------- */
// historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/campo.js loaded as they are into a blank page; campo.js's own ball maker
// (BOLA, mkBola) taken from its text as it is. A bubble is drawn as campo.js bub2 draws it (twice its size, its tail's tip at the origin), on both
// frames of its bob
const CAMPO_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/campo.js'), 'utf8');
const LINES = CAMPO_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('campo.js changed: ' + s); return i + 1; };
const fnText = name => { const a = CAMPO_JS.indexOf('function ' + name + '('); if (a < 0) throw new Error('campo.js changed: ' + name); let d = 0, i = CAMPO_JS.indexOf('{', a);
  for (; i < CAMPO_JS.length; i++) { if (CAMPO_JS[i] === '{') d++; else if (CAMPO_JS[i] === '}' && --d === 0) break; } return CAMPO_JS.slice(a, i + 1); };
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/campo.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  await page.addScriptTag({ content: 'const R=Math.round;' + LINES[lineOf('const BOLA={L:') - 1] + '\n' + fnText('mkBola') + '\nwindow.MK={mkBola,BOLA};' });
  const oldPng = 'data:image/png;base64,' + fs.readFileSync(path.join(REF, 'frames/s000.nochar.png')).toString('base64');
  return page.evaluate(async oldPng => {
    // the old lawn's mean colour (s000 without characters: rows 120 on, its green pixels, the pond and the patch left out)
    const oldLawn = await new Promise(res => { const im = new Image(); im.onload = () => { const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0);
      const d = g.getImageData(0, 0, 240, 216).data; let n = 0, s = [0, 0, 0]; for (let y = 120; y < 216; y++) for (let x = 0; x < 150; x++) { const i = (y * 240 + x) * 4; if (d[i + 1] > d[i] && d[i + 1] > d[i + 2]) { n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } } res(s.map(v => v / n)); }; im.src = oldPng; });
    // the old oval of Canelo's spot (campo.js fondo: ell(SITIO, 15, 5)): its mean colour as the old picture draws it
    const oldOval = await new Promise(res => { const im = new Image(); im.onload = () => { const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0);
      const d = g.getImageData(0, 0, 240, 216).data; let n = 0, s = [0, 0, 0]; for (let y = 160; y < 176; y++) for (let x = 28; x < 66; x++) { const dx = (x + .5 - 46) / 15, dy = (y + .5 - 168) / 5; if (dx * dx + dy * dy > .8) continue; const i = (y * 240 + x) * 4; n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } res(s.map(v => v / n)); }; im.src = oldPng; });
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
    // the opaque rows of a sprite drawn by draw(g, 80, 100): [dy, x from, x to] relative to the anchor
    const rowsOf = draw => { const cv = document.createElement('canvas'); cv.width = 160; cv.height = 140; const g = cv.getContext('2d'); g.imageSmoothingEnabled = false; draw(g, 80, 100);
      const d = g.getImageData(0, 0, cv.width, cv.height).data, out = [];
      for (let y = 0; y < cv.height; y++) { let a = -1, b = -1; for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3] > 40) { if (a < 0) a = x; b = x; } if (a >= 0) out.push([y - 100, a - 80, b - 80]); }
      return out; };
    const QUIEN = { luis: KIT.FAM.hermano, carmen: KIT.FAM.hermana }, masks = {}, heads = {};
    const head = rows => { const top = Math.min(...rows.map(r => r[0])), rs = rows.filter(r => r[0] < top + 10); return { top, head: (Math.min(...rs.map(r => r[1])) + Math.max(...rs.map(r => r[2])) + 1) / 2 }; };
    // a person as campo.js gente draws them: translate(x, y - h + 1), scale(-1, 1) when (pose offer ? -dir : dir) < 0, drawImage(im, -PX, 0)
    for (const [id, fam] of Object.entries(QUIEN)) for (const pose of ['idle', 'wave0', 'wave1', 'offer', 'yo', 'tu']) for (const dir of [1, -1]) {
      const im = KIT.mkPersona(fam, pose, 0, 0), flip = (pose === 'offer' ? -dir : dir) < 0;
      masks[id + '.' + pose + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 1); if (flip) g.scale(-1, 1); g.drawImage(im, -KIT.PX, 0); g.restore(); });
      if (pose === 'idle' && dir === 1) heads[id] = head(masks[id + '.idle.1']);
    }
    // the dog as campo.js perro draws it: translate(x, y - h + 2), scale(-1, 1) when dir < 0, drawImage(im, -13, 0); both frames
    const animals = {};
    for (const pose of ['sit', 'walk', 'run', 'bark', 'lie', 'husmea', 'eat']) for (const f of [0, 1]) for (const dir of [1, -1]) {
      const im = KIT.mkPerro(pose, f); animals['perro.' + pose + '.' + f + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 2); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -13, 0); g.restore(); }); }
    // a ball as unaBola draws it on the ground: drawImage(im, x - (w >> 1), y - z - h + 1); the basket with its four balls (W.cesta, x - 10, y - 11);
    // the flower (W.flor) as draw() line 105
    const balls = {}; for (const k of ['L', 'C', 'q']) balls[k] = rowsOf((g, x, y) => { const im = MK.mkBola(k); g.drawImage(im, x - (im.width >> 1), y - im.height + 1); });
    const cesta = rowsOf((g, x, y) => { const im = MK.mkBola('q'); for (let i = 0; i < 4; i++) g.drawImage(im, x - 10 + i * 5, y - 16 - (i % 2) * 2); g.drawImage(KIT.mkCesta(), x - 10, y - 11); });
    const flor = rowsOf((g, x, y) => { g.fillStyle = '#2E8A34'; g.fillRect(x, y - 9, 1, 9); g.fillRect(x - 3, y - 4, 3, 2); g.fillStyle = '#F06A9A'; [[-3, -13], [1, -13], [-3, -9], [1, -9], [-1, -15], [-1, -8], [-4, -11], [2, -11]].forEach(d => g.fillRect(x + d[0], y + d[1], 3, 3)); g.fillStyle = '#F0C020'; g.fillRect(x - 1, y - 12, 3, 3); });
    // each ball's pixels as unaBola draws it on the ground at (0, 0): [dy, dx, r, g, b]
    const ballPx = {}; for (const k of ['L', 'C', 'q']) { const im = MK.mkBola(k), d = im.getContext('2d').getImageData(0, 0, im.width, im.height).data, out = [];
      for (let y = 0; y < im.height; y++) for (let x = 0; x < im.width; x++) { const i = (y * im.width + x) * 4; if (d[i + 3] > 40) out.push([y - im.height + 1, x - (im.width >> 1), d[i], d[i + 1], d[i + 2]]); } ballPx[k] = out; }
    const meanOf = im => { const g = im.getContext('2d'), d = g.getImageData(0, 0, im.width, im.height).data; let n = 0, s = [0, 0, 0]; for (let i = 0; i < d.length; i += 4) if (d[i + 3] > 40) { n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } return s.map(v => Math.round(v / n)); };
    const mean3 = a => { const n = a.length; return [0, 1, 2].map(k => a.reduce((t, c) => t + c[k], 0) / n); }, hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
    const hairOf = f => mean3([].concat(f.pelo).map(hex));
    const colours = { frog: meanOf(mkCoqui(1, 0, 0)), pelo_luis: hairOf(KIT.FAM.hermano), pelo_carmen: hairOf(KIT.FAM.hermana), L: meanOf(MK.mkBola('L')), C: meanOf(MK.mkBola('C')), q: meanOf(MK.mkBola('q')), perro: meanOf(KIT.mkPerro('sit', 0)), cesta: meanOf(KIT.mkCesta()), flor: [240, 106, 154] };
    return { bubbles, masks, heads, animals, balls, ballPx, cesta, flor, colours, oldLawn, oldOval, PX: KIT.PX, R: { L: MK.BOLA.L.r, C: MK.BOLA.C.r, q: MK.BOLA.q.r } };
  }, oldPng);
}

/* ---------- the preview's places: campo-preview.html, served over http, maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.woff2': 'font/woff2', '.css': 'text/css' };
  const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(REPO, u);
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); fs.createReadStream(f).pipe(res); });
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  try {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto('http://127.0.0.1:' + srv.address().port + '/docs/proyecto/pixel/campo-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => { const n = PREVIEW.remapW(w), o = {};
        for (const [id, p] of Object.entries(n.gente || {})) if (p && p.x != null) o[id] = [Math.round(p.x), Math.round(p.y)];
        if (n.cq) o.cq = [n.cq.x, n.cq.y]; if (n.perro && n.perro.x != null) o.perro = [Math.round(n.perro.x), Math.round(n.perro.y)];
        for (const [k, b] of Object.entries(n.bolas || {})) if (b && !b.con && b.x != null) o['bola.' + k] = [Math.round(b.x), Math.round(b.y)];
        if (n.respEn) o.respEn = n.respEn.slice();
        return o; }); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  } finally { await new Promise(r => srv.close(r)); }
}

/* ---------- every tick inside the acts: the old page played by the same machine as the recorded runs (coqui/tool/ref/trazas: page-init.js and
   page-drive.js, as they are, the same seed, think time and clock), with one more script, read only: after each timer the runner fires, the
   scene's W (the children, the frog, Canelo, the balls, the basket) is kept when it changed. So a throw, a roll or a wade is seen tick by tick */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = { gente: W.gente, perro: W.perro, bolas: W.bolas, cq: W.cq, cesta: W.cesta, tarjeta: W.tarjeta, mojado: W.mojado };
    const s = JSON.stringify(o, (k, x) => typeof x === 'function' || (x && x.nodeType) || x instanceof HTMLCanvasElement ? undefined : x); if (s !== last) { last = s; window.__TICKS.push({ t: H.now, W: JSON.parse(s) }); } } catch (e) {} };
  H.drain = () => d().then(() => { keep(); }); })();`;
async function serve(fn) {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.woff2': 'font/woff2', '.css': 'text/css', '.mp3': 'audio/mpeg' };
  const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(REPO, u);
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); fs.createReadStream(f).pipe(res); });
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  try { return await fn('http://127.0.0.1:' + srv.address().port); } finally { await new Promise(r => srv.close(r)); }
}
async function tickStates(browser, runs) {
  const INIT = fs.readFileSync(path.join(TRAZAS, 'page-init.js'), 'utf8').replace('__SEED__', '1'), DRIVE = fs.readFileSync(path.join(TRAZAS, 'page-drive.js'), 'utf8');
  return serve(async base => { const out = [];
    for (const r of runs) {
      const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: 'UTC', locale: 'en-US' });
      try {
        await ctx.addInitScript(INIT); await ctx.addInitScript(TICK_HOOK);
        await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => { const name = decodeURIComponent(new URL(route.request().url()).pathname.split('/').pop());
          return fs.existsSync(path.join(REPO, 'historia/audio', name)) ? route.fulfill({ status: 200, contentType: 'audio/mpeg', body: 'ID3' }) : route.fulfill({ status: 404, body: '' }); });
        const page = await ctx.newPage();
        await page.goto(base + '/historia/index.html?cuento=' + r.story.id + '&fast=1&rec=1&mic=stub:none&abiertas=todas');
        for (let i = 0; ; i++) { if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break; if (i > 600) throw new Error('the page did not load ' + r.story.id); await new Promise(z => setTimeout(z, 50)); }
        await page.evaluate('voiceReady'); await page.evaluate(DRIVE);
        const tr = await page.evaluate(cfg => window.__drive(cfg), { plan: r.plan, think: 700, limitMs: 4 * 3600e3, states: false });
        if (tr.end !== 'finished') throw new Error('ticks: ' + r.story.id + ' ' + r.plan + ' ended: ' + tr.end);
        out.push(await page.evaluate(() => window.__TICKS));
      } finally { await ctx.close(); }
    }
    return out; });
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const hop = d => d < 3 ? 0 : Math.max(1, Math.min(4, Math.round(d / 30)));   // kit.js acts.ir
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');

/* ---------- the old scene's numbers (historia/escenas/campo.js, read as text: they must be what the file says) ---------- */
function fixJson(s) { return s.replace(/\s+/g, '').replace(/([{,])(\w+):/g, '$1"$2":').replace(/:\./g, ':0.').replace(/,\./g, ',0.').replace(/\[\./g, '[0.'); }
const OLD = (() => { const g = (re, w) => { const m = CAMPO_JS.match(re); if (!m) throw new Error('campo.js changed: ' + w); return JSON.parse(fixJson(m[1])); };
  return { ARBOL: g(/const ARBOL=(\[\d+,\d+\])/, 'ARBOL'), COPA: g(/COPA=(\[[\d,]+\])/, 'COPA'), HORQ: g(/HORQ=(\[\d+,\d+\])/, 'HORQ'), SITIO: g(/SITIO=(\[\d+,\d+\])/, 'SITIO'),
    AGUA: g(/const AGUA=(\[[\d,]+\])/, 'AGUA'), JUNCOS: g(/JUNCOS=(\[\[[^;]*\]\]);/, 'JUNCOS'), LUGAR: { centro: [120, 150, 1], inicio: [120, 150, 1] },
    CASA: g(/const CASA=(\{[^}]*\})/, 'CASA'), PIES: g(/PIES=(\[\d+,\d+\])/, 'PIES'), CESTA: g(/CESTA=(\[\d+,\d+\])/, 'CESTA'), PILA: g(/PILA=(\[\[[^;]*\]\]);/, 'PILA'),
    FILA: g(/const FILA=(\[\[[^=]*\]\]),ORILLA/, 'FILA'), ORILLA: g(/ORILLA=(\[\d+,\d+\])/, 'ORILLA'), JUNCO: g(/JUNCO=(\[\d+,\d+\])/, 'JUNCO') }; })();
{ const m = CAMPO_JS.match(/const LUGAR=\{centro:\[(\d+),(\d+),(\d+)\],inicio:\[(\d+),(\d+),(\d+)\]\}/); if (!m) throw new Error('campo.js changed: LUGAR'); OLD.LUGAR = { centro: [+m[1], +m[2], +m[3]], inicio: [+m[4], +m[5], +m[6]] }; }
const enAguaOld = (x, y) => { const A = OLD.AGUA, dx = (x - A[0]) / A[2], dy = (y - A[1]) / A[3]; return Math.sqrt(dx * dx + dy * dy); };   // the old pond: < 1 water, < 1.07 its rim
// the old boxes of the set things (campo.js COSAS)
const OLDBOX = { arbol: [OLD.COPA[0] - OLD.COPA[2], OLD.COPA[1] - OLD.COPA[3], OLD.COPA[2] * 2, OLD.COPA[3] * 2 + 26], juncos: [160, 168, 60, 48], campo: [0, 100, 240, 116] };
// every frog place the acts hop to (hopTo, and the frog's places in inicio and esconde16), screen q (old = new: the floor rule)
const FROG_PLACES = { centro: [120, 150], bajoarbol: [52, 138], tumba: [50, 140], luisbusca: [44, 138], listos: [136, 150], inicio16: [132, 142], turno16a: [150, 128], esconde16: [136, 136],
  busca_arriba: [46, 140], busca_baja: [70, 160], busca_abajo: [160, 166], final16_no: [148, 146], final16_si: [118, 142], inicio17: [112, 140] };

// the places a bubble's tail may go, in order (as El camino's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner card campo.js hud draws, in the 196 x 216 display (tarjeta(3, 3, 66, 24) covers [2, 2, 68, 26])
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];

function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2] || 0); return [r2(q.sx), r2(q.sy)]; };
  const floor = (sx, sy) => W4(E.atZ(sx, sy, 0));
  // the box (square on the ground) whose 8 projected corners have the screen box [sx0, sy0] - [sx1, sy1] (set-kit.js boxAround)
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };

  /* ---- the floor rule: the field is built round the old picture, so a place on its ground stays where it was on the screen ---- */
  // a frog place q (juego.js frogBox: his middle q.x + 16, his feet row q.y + 25): the ground point under (q.x + 16, q.y + 25); new q = old q.
  // a person's place (x, y) (their feet, campo.js gente), the dog's (perro: its sprite's bottom row y + 1), a ball's (unaBola: its lowest row at
  // y - z), the basket's (its bottom row y): the ground point under (x, y - 1); new = old
  const frogW = q => floor(q[0] + 16, q[1] + 25), personW = p => floor(p[0], p[1] - 1);
  const frogQ = w => { const s = P(w); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const personQ = w => { const s = P(w); return [Math.round(s[0]), Math.round(s[1]) + 1]; };

  /* ---- the set's own things, from its pixels: each part's screen box (its leaves at every wind step too) ---- */
  const tagsOf = key => G.parts[key];
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1, y1 + 1]; };
  const partScreen = name => { const all = []; for (const key of STATES) { const l = (tagsOf(key)[name] || []).concat(G.leaf[key][name] || []); all.push(...l); } return pxBox(all); };

  /* ---- the places that move (the floor rule keeps every other one). Each is an exact piece of campo.js source and its replacement ---- */
  // the answer cards in the sky (W.respEn, juego.js respBox: "a scene that needs its people seen while he chooses puts the bubbles elsewhere", as
  // El camino's): over the frog they covered Luis and Carmen; under the rounds card (rows 2 to 28), right of the sun with their frames
  const EN = [134, 32], MALA17 = [165, 210], BEBE = [167, 211], CONTACT_BALLS = ['q'], JUNCO = [188, 201], LUISJ = [165, 193], HUSMEA = [158, 190], NADA = [184, 206], ECHA = [158, 191], BOLA17 = [169, 193];
  const MOVES = [
    { line: lineOf('async inicio15()'), act: 'inicio15', src: 'async inicio15(){W.gente=', to: 'async inicio15(){W.respEn=[' + EN + '];W.gente=', respEn: EN,
      why: 'acts.inicio15 (la-bola, d-bola-canelo): the answer cards stand in the sky (W.respEn ' + EN + '): over the frog at the field\'s middle they covered Luis (88, 178), the hand at a card reached his face; under the rounds card, right of the sun with their lit frames and glow, inside the view with 2 px to spare' },
    { line: lineOf('async inicio16()'), act: 'inicio16', src: 'async inicio16(){W.gente=', to: 'async inicio16(){W.respEn=[' + EN + '];W.gente=', respEn: EN,
      why: 'acts.inicio16 (arriba-abajo): the answer cards stand in the sky (W.respEn ' + EN + '), as inicio15' },
    { line: lineOf('async inicio17()'), act: 'inicio17', src: 'async inicio17(){W.gente=', to: 'async inicio17(){W.respEn=[' + EN + '];W.gente=', respEn: EN,
      why: 'acts.inicio17 (otra-vez): the answer cards (three: tira, aguanta, da) stand in the sky (W.respEn ' + EN + '): over the frog they ran over Luis\'s head and the tree\'s crown' },
    { line: lineOf('async malA17('), act: 'malA17', src: 'await vuela(n,[168,206],22,8);', to: 'await vuela(n,[' + MALA17 + '],22,8);', pts: [['bola', [168, 206], MALA17]],
      why: 'acts.malA17 (otra-vez, wrong): the ball he throws lands at the water\'s edge, a little way off, and Canelo does not go after it. The old point (168, 206) was on the old pond\'s rim; here it lay across the lip of the bank: ' + (MALA17[0] - 168) + ' px, ' + (MALA17[1] - 206) + ' rows into the water at the edge, round 2 (water all round it, its ring: on the land every point near enough lay on Canelo or on the row of balls); Canelo then noses it back (vuelvefila) (the ball then rolls back to the row, vuelvefila, from where it lies)' },
    { line: lineOf('async aguanta('), act: 'aguanta', src: 'await perroA(ORILLA[0]-10,ORILLA[1]+2,"walk");pe.dir=1;pe.pose="eat";', to: 'await perroA(' + BEBE + ',"walk");pe.dir=1;pe.pose="eat";',
      pts: [['perro', [180, 200], BEBE]],
      why: 'acts.aguanta (otra-vez): Canelo goes down and drinks at the water\'s edge: at the old point (180, 200: ORILLA - 10, + 2) the reeds stand in front of his head; ' + (BEBE[0] - 180) + ' px, ' + (BEBE[1] - 200) + ' rows to the open bank down the shore from the reeds (the same place as the pair más.no\'s, remap)' },
    // round 2, the shore: whatever rests at the shore is clearly on one side (helps.margin); each old point that lay across the lip of the bank,
    // moved the least (the nearest point on that side: on the land with 3 px of lawn round its foot, or in the water with water round it)
    { line: lineOf('const FILA='), act: '*', src: 'JUNCO=[180,197]', to: 'JUNCO=[' + JUNCO + ']', pts: [['bola', [180, 197], JUNCO], ['bola', [178, 199], [JUNCO[0] - 2, JUNCO[1] + 2]]],
      why: 'round 2: JUNCO, where a ball hides in the reeds (ruedabajo, esconde16, sol: and sol\'s JUNCO - 2, + 2): the old point lay across the lip of the bank; ' + (JUNCO[0] - 180) + ' px, ' + (JUNCO[1] - 197) + ' rows out into the water among the reeds (water all round it, its ring; the reeds in front of it)' },
    { line: lineOf('await mueve("luis",ar?82:166,ar?166:194,null,1)'), act: 'luisbusca', src: 'await mueve("luis",ar?82:166,ar?166:194,null,1)', to: 'await mueve("luis",ar?82:' + LUISJ[0] + ',ar?166:' + LUISJ[1] + ',null,1)', pts: [['luis', [166, 194], LUISJ]],
      why: 'round 2: acts.luisbusca, Luis looks in the reeds: his feet were 2 px from the lip of the bank; 1 px up and left, on the lawn' },
    { line: lineOf('await perroA(166,198,"run");pe.pose="husmea"'), act: 'perrotumba', src: 'await perroA(166,198,"run");pe.pose="husmea"', to: 'await perroA(' + HUSMEA + ',"run");pe.pose="husmea"', pts: [['perro', [166, 198], HUSMEA]],
      why: 'round 2: acts.perrotumba, Canelo noses at the reeds: he stood across the lip of the bank; ' + (HUSMEA[0] - 166) + ' px, ' + (HUSMEA[1] - 198) + ' rows, on the lawn by the water' },
    { line: lineOf('await perroA(ORILLA[0]-12,ORILLA[1]+2,"run")'), act: 'tira17', src: 'await perroA(ORILLA[0]-12,ORILLA[1]+2,"run")', to: 'await perroA(' + NADA + ',"run")', pts: [['perro', [178, 200], NADA]],
      why: 'round 2: acts.tira17, Canelo fetches the ball from the water: he stood across the lip of the bank (178, 200); ' + (NADA[0] - 178) + ' px, ' + (NADA[1] - 200) + ' rows into the water, wading (his ring)' },
    { line: lineOf('await perroA(160,196,"walk");if(b){await vuela("cq",[170,197],0,4,0);}'), act: 'final17', src: 'await perroA(160,196,"walk");if(b){await vuela("cq",[170,197],0,4,0);}', to: 'await perroA(' + ECHA + ',"walk");if(b){await vuela("cq",[' + BOLA17 + '],0,4,0);}', pts: [['perro', [160, 196], ECHA], ['bola', [170, 197], BOLA17]],
      why: 'round 2: acts.final17, Canelo lies down by the water with the small ball: both lay across the lip of the bank; Canelo ' + (ECHA[0] - 160) + ' px, ' + (ECHA[1] - 196) + ' rows, the ball ' + (BOLA17[0] - 170) + ' px, ' + (BOLA17[1] - 197) + ' rows, on the lawn' },
    { line: lineOf('p.pose==="arriba"?4:6'), act: '*', src: 'R(p.x)+d*(p.pose==="offer"?11:p.pose==="arriba"?4:6),R(p.y)+1,(p.pose==="arriba"?h+2:', to: 'R(p.x)+d*(p.pose==="offer"?11:p.pose==="arriba"?8:6),R(p.y)+1,(p.pose==="arriba"?h-3:',
      why: 'round 2 (point 4): manos(), a ball a child holds up over the head (pose arriba): in the raised hand (the sprite\'s raised fist, 6 to 9 px to the side the child faces, its top 39 rows over the feet: the ball 8 px to that side, its lowest row on the fist) instead of 4 px from the middle and 2 rows over the head, where it hung loose in the air (readers: "the blue ball is in the air next to the trunk", otra-vez 09 to 12, Carmen at 58, 198 in front of the trunk). A flight that ends in a child\'s raised hands (pasa, alta, acarmen) ends there too' },
  ];
  for (const m of MOVES) for (const q of m.pts || []) q.push(q[0] === 'cq' ? frogW(q[2]) : W4(personW(q[2])));
  // the old code's own drawing the engine replaces (the background, the shadows it now casts); the preview and the port take each out
  const DROPPED = [
    { src: 'c.drawImage(spr("campo",fondo),0,0);', to: '', why: 'the background: the set, for setKey(W)' },
    { src: 'for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#2E8A34");', to: '', why: 'rana(): the frog\'s dotted shadow; the engine casts his (shadows.coqui)' },
    { src: 'if(p[2]>3&&!o.con){c.globalAlpha=.3;fr(c,p[0]-R(r)+1,p[1]-1,R(r*2)-2,2,"#103010");c.globalAlpha=1;}', to: '', why: 'unaBola(): the dark bar under a ball in the air; the engine casts every ball\'s shadow on the ground under it, in the air or not (shadows.bola, as El patio\'s)' },
    { src: 'if((o.dy||0)>3){c.globalAlpha=.3;fr(c,R(o.x)-9,R(o.y),18,2,"#103010");c.globalAlpha=1;}', to: '', why: 'perro(): the dark bar under Canelo in the air; the engine casts his shadow on the ground under him (shadows.perro)' },
  ].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* ---- spots: the frog's places, the people's, the dog's, the balls' and the basket's named places ---- */
  const SPOTS = {};
  for (const [k, v] of Object.entries(OLD.LUGAR)) SPOTS['frog.' + k] = { world: frogW(v), scale: v[2], old: v.slice(0, 2), what: 'LUGAR.' + k + ': the frog in the middle of the field' };
  for (const [k, v] of Object.entries(FROG_PLACES)) if (k !== 'centro') SPOTS['frog.' + k] = { world: frogW(v), scale: 1, old: v, what: 'the frog\'s place in acts.' + k.replace(/_.*/, '') + ' (hopTo, or W.cq)' };
  SPOTS['luis.casa'] = { world: personW(OLD.CASA.luis), old: OLD.CASA.luis, what: 'CASA.luis: where Luis stands (acasa)' };
  SPOTS['carmen.casa'] = { world: personW(OLD.CASA.carmen), old: OLD.CASA.carmen, what: 'CASA.carmen: where Carmen stands (acasa), up the field near the lake' };
  SPOTS['bola.pies'] = { world: personW(OLD.PIES), old: OLD.PIES, what: 'PIES: where the frog\'s ball lies at his feet' };
  SPOTS['cesta'] = { world: personW(OLD.CESTA), old: OLD.CESTA, what: 'CESTA: the basket (story 15; story 16 puts it at 88, 208: spot cesta.16)' };
  SPOTS['cesta.16'] = { world: personW([88, 208]), old: [88, 208], what: 'acts.inicio16: the basket' };
  OLD.PILA.forEach((p, i) => { SPOTS['pila.' + i] = { world: personW(p), old: p, what: 'PILA[' + i + ']: Canelo\'s pile of balls, on the trodden earth by his spot' }; });
  OLD.FILA.forEach((p, i) => { SPOTS['fila.' + i] = { world: personW(p), old: p, what: 'FILA[' + i + ']: story 17\'s row of balls on the grass' }; });
  SPOTS['orilla'] = { world: personW(OLD.ORILLA), old: OLD.ORILLA, what: 'ORILLA: the water\'s edge, where a ball rolls before it goes in (acts.alagua) and where Canelo wades for one (tira17)' };
  SPOTS['junco'] = { world: personW(OLD.JUNCO), old: OLD.JUNCO, what: 'JUNCO: where a ball hides in the reeds (ruedabajo, esconde16 abajo, sol abajo)' };
  SPOTS['perro.sitio'] = { world: personW([OLD.SITIO[0] + 4, OLD.SITIO[1] + 3]), old: [OLD.SITIO[0] + 4, OLD.SITIO[1] + 3], what: 'SITIO + (4, 3): Canelo\'s spot under the tree, on the trodden earth' };
  [[196, 205], [207, 198], [200, 212], [212, 208]].forEach((p, i) => { SPOTS['flota.' + i] = { world: personW(p), old: p, what: 'acts.alagua: the ' + ['first', 'second', 'third', 'fourth'][i] + ' ball that floats on the lake' }; });
  for (const s of Object.values(SPOTS)) s.new = s.scale != null ? frogQ(s.world) : personQ(s.world);

  /* ---- the named points of the set ---- */
  const PTS = {}, pt = (k, o) => { PTS[k] = o; };
  pt('arbol', { screen: OLD.ARBOL, old: OLD.ARBOL, world: floor(OLD.ARBOL[0], OLD.ARBOL[1]), what: 'ARBOL: the tree\'s foot (unchanged): the ball in the tree (HORQ, ARBOL[1]), the shaking leaves (COPA), the frog\'s and the people\'s places under it are all as the old' });
  pt('copa', { screen: [F.TCROWN.cx, F.TCROWN.cy], radii: [F.TCROWN.rx, F.TCROWN.ry], old: OLD.COPA, what: 'the crown: its middle and radii on the screen (the old COPA 60, 100, 30, 26: the shaking leaves of W.tiembla stay round the old middle)' });
  pt('horq', { screen: OLD.HORQ, old: OLD.HORQ, hollow: [F.HOLLOW.cx, F.HOLLOW.cy, F.HOLLOW.rx, F.HOLLOW.ry], what: 'HORQ: the fork where a ball sticks (64, 116): the hollow in the crown\'s front over it, through which the limbs show (hollow: its middle and radii on the screen)' });
  pt('sitio', { screen: OLD.SITIO, old: OLD.SITIO, what: 'SITIO: Canelo\'s spot, on the trodden earth that runs from the tree\'s foot' });
  pt('orilla', { screen: OLD.ORILLA, old: OLD.ORILLA, what: 'ORILLA: the water\'s edge (unchanged)' });
  pt('junco', { screen: OLD.JUNCO, old: OLD.JUNCO, what: 'JUNCO: in the reeds (unchanged)' });
  pt('corazon', { screen: [110, 30], old: [110, 30], what: 'heartAt: the heart of a happy ending, in the sky (unchanged)' });
  pt('sol', { screen: F.SUN.slice(0, 2), radius: F.SUN[2], what: 'the sun: baked into the set\'s sky (El camino\'s, in the same place: left of the middle, every shadow falls to the right), under the corner card\'s place and left of the answer cards\' frames, whole inside the wide view; no story touches it or names its place (the old sun was at the upper right)' });
  pt('nubes', { screen: F.CLOUDS, old: [[36, 16, 1], [112, 9, .7], [168, 26, .8]], what: 'the old picture\'s three clouds (x, y, size: engine.js sky()), baked into the set\'s sky as El camino\'s, moved clear of the corner card, the sun, the crown and the answer cards\' place; no story names them' });
  pt('orilla_linea', { screen: [[Math.round(E.project(F.BANK, 4.2, 0).sx), Math.round(E.project(F.BANK, 4.2, 0).sy)], [Math.round(E.project(F.BANK, .3, 0).sx), Math.round(E.project(F.BANK, .3, 0).sy)]], world: r4(F.BANK), what: 'the lake\'s shore: the line x = ' + r4(F.BANK) + ' (on the screen sx + 2 sy = 582), wavering a little; the water on its near side, its surface ' + F.WDEPTH + ' under the lawn' });

  /* ---- things: the 10 touch keys ---- */
  const T = (name, what, extra = {}) => { const s = partScreen(name), w = boxAround(s[0], s[1], s[2], s[3]); return Object.assign({ set: true, world: W4(w), box: box(w), screen: s, what, old: { box: OLDBOX[name] } }, extra); };
  const person = id => ({ sprite: true, why: 'a child (today\'s sprite, drawn 1:1). caja(id) (campo.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged' });
  const bola = n => ({ sprite: true, why: 'the ' + { luis: 'big striped red ball (Luis\'s, BOLA.L, r 7)', carmen: 'middle blue ball with white dots (Carmen\'s, BOLA.C, r 5.5)', cq: 'small yellow ball with a white line (the frog\'s, BOLA.q, r 5)' }[n] + ' (mkBola): cajaBola (campo.js:' + lineOf('const cajaBola=n=>') + '): [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4] where it is: unchanged' });
  const lawnTop = F.HZ;
  const things = {
    luis: person('luis'), carmen: person('carmen'), bola_luis: bola('luis'), bola_carmen: bola('carmen'), bola_cq: bola('cq'),
    perro: { sprite: true, why: 'Canelo (KIT.mkPerro): box [x - 14, y - 20, 28, 22] at W.perro, unchanged' },
    cesta: { sprite: true, why: 'the basket (KIT.mkCesta, with up to four small balls in it): box [x - 11, y - 16, 22, 18] at W.cesta, unchanged. It stays in the sprite layer, as El patio\'s crate: the stories put it in two places (104, 208; 88, 208) and fill and empty it; on the lawn on clear ground, its shadow cast by the engine (shadows.cesta)' },
    arbol: T('arbol', 'the tree: its trunk, its limbs and its crown (still: at its height the wind moves no leaf a pixel)'),
    juncos: T('juncos', 'the reeds: every stalk, head and blade of the bed along the shore'),
    campo: { set: true, ground: true, what: 'the field: the lawn and the lake from the horizon (row ' + lawnTop + ') to the bottom, the whole width: last in the hit order', old: { box: OLDBOX.campo } },
  };
  things.campo.box = [0, lawnTop, 240, 216 - lawnTop]; things.campo.world = W4(boxAround(0, lawnTop, 240, 216));
  things.arbol.hand = [OLD.COPA[0], OLD.COPA[1]]; things.arbol.handWhy = 'the old hand point: the crown\'s middle (COPA)';
  things.juncos.hand = [188, 190]; things.juncos.handWhy = 'the old hand point (188, 190): in the reeds';
  // the reeds run along the shore off the picture's right edge, as the old row ran to the view's: the hint frame and its twinkle go round its hint
  // box, the part of its touch box inside the view shrunk so that the frame (box + 12) is inside it (as El camino's big tree's)
  { const b = things.juncos.box, hx0 = Math.max(b[0], 22 + 12), hy0 = Math.max(b[1], 12), hx1 = Math.min(b[0] + b[2], 22 + 196 - 12), hy1 = Math.min(b[1] + b[3], 216 - 12);
    things.juncos.hintBox = [hx0, hy0, hx1 - hx0, hy1 - hy0];
    things.juncos.hintWhy = 'hintBox: the part of the touch box the hint frame shows (the frame and the twinkle are drawn round hintBox; the touch box answers the touches): the bed runs off the picture\'s right edge, as El camino\'s big tree\'s crown'; }

  /* ---- views: one, zoom 1, the old wide window ---- */
  const views = { wide: { zoom: 1, x0: 22, world: floor(120, 150), region: null, old: [22, 0, 196, 216], what: 'the field: the tree, the lawn, the reeds, the corner of the lake, the sky' } };

  /* ---- the review and level pictures ---- */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(cx - 98))), Math.max(0, Math.min(112, Math.round(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(cx - 49))), Math.max(0, Math.min(164, Math.round(cy - 26))), 98, 52];
    return { world: floor(cx, cy), screen: [cx, cy], zoom, crop, what }; };
  const PICS = PICTURES(pic);
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'campo' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  // round 2: the zoom 2 pairs dame, mi, tu (they share 150, 182) shift up the lawn by PAIR_A, bola and salta by PAIR_B: their pictures then hold
  // none of the tree's shadow (it falls on rows 154 to 182 left of x 131) and none of the tree; d-bola-canelo's Canelo barking by the water
  // off the lip of the bank
  const PAIR_A = [8, -38], PAIR_B = [0, -38], sh_ = (p, v) => [p[0] + v[0], p[1] + v[1]];
  const pairMove = (o, v, what) => ({ old: o, new: sh_(o, v), who: 'pair', why: 'round 2, the pair ' + what + ' (zoom 2): moved ' + v[0] + ' px, ' + v[1] + ' rows up the lawn with the whole picture, so that it shows none of the tree\'s shadow (it lies on rows 154 to 182, left of x 131) and none of the tree' });
  const STORY_MOVES = [
    ...[[150, 182], [88, 155], [110, 182], [144, 153], [92, 184], [94, 184], [152, 184], [140, 184], [112, 182]].map(o => pairMove(o, PAIR_A, 'dame, mi or tu')),
    ...[[137, 178], [137, 186], [138, 187], [128, 184], [160, 187]].map(o => pairMove(o, o[0] === 137 && o[1] === 178 ? [0, -36] : PAIR_B, o[0] === 137 && o[1] === 178 ? 'bola' : 'salta')),
    { old: [176, 196], new: [183, 202], who: 'bola', why: 'round 2: the pair arriba.no, the big ball down in the reeds: it lay across the lip of the bank; 7 px, 6 rows into the water among the reeds (water all round it, its ring)' },
    { old: [168, 192], new: [163, 187], who: 'perro', why: 'round 2: d-bola-canelo beats.27, Canelo barking by the water: he stood across the lip of the bank; 5 px, 5 rows, on the lawn' },
    { old: [178, 197], new: BEBE, who: 'perro', why: 'the pair más.no: Canelo drinks at the water: at the old point (178, 197) the reeds stand in front of his head (the subject hidden); in the shallows down the shore from the reeds, wading as he drinks (his ring), as acts.aguanta (moves)' }];
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : p.kind === 'numbers' ? [p.x, p.y, p.w] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      const ats = p.uses.map(u => u.at);
      if (p.x === -16 && p.y === -27) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0): not a place'; }
      else if (ats.every(a => /\.vuela$/.test(a))) { e.to = { none: true }; e.what = 'a ball\'s flight lines (vuela: a direction, not a place)'; }
      else if (ats.every(a => /respEn$/.test(a))) { e.to = { screen: EN }; e.new = EN; e.moved = true; e.why = 'the answer cards where the scene\'s inicio acts put them (moves), clear of the sun and the rounds card, their frames inside the view with 2 px to spare'; e.what = 'W.respEn: the answer cards in the sky (juego.js respBox: centred at x, their top at y): screen, moved'; }
      else { const mv = STORY_MOVES.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y], w = personW(at);
        e.to = { floor: w }; e.new = personQ(w); if (mv) { e.moved = true; e.why = mv.why; }
        e.what = ats.every(a => /\.cq$/.test(a)) ? 'the frog\'s place q (x, y): the ground under (x + 16, y + 25); the same screen place' + (p.y < 120 ? ' (in the tree\'s crown: abajo.no)' : '') : ats.every(a => /bolas\./.test(a) || /flor$/.test(a)) ? 'a ball (or the flower) where it lies (x, y; its height z is kept): the ground under it; the same screen place' : ats.every(a => /\.perro$/.test(a) || /^beats/.test(a)) ? 'Canelo\'s place (x, y): the ground under it; the same screen place' : 'a child\'s feet (x, y): the ground under them; the same screen place';
        if (ats.every(a => /^beats/.test(a))) e.what = 'Canelo\'s place in a perro step of the picture story (x, y): the ground under it; the same screen place';
        if (mv) e.what = e.what.replace('; the same screen place', '; moved (why)'); }
    }
    return e;
  });

  // hop counts: every pair of the frog's places, old against new (all keep their points: the same counts)
  const lugar = {}; for (const [k, v] of Object.entries(OLD.LUGAR)) lugar[k] = { spot: 'frog.' + k, q: SPOTS['frog.' + k].new, scale: v[2], old: v.slice(0, 2) };
  const fp = {}; for (const [k, v] of Object.entries(FROG_PLACES)) fp[k] = { q: SPOTS['frog.' + k].new, old: v };
  const hopsAll = [], names = Object.keys(fp);
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const a = fp[names[i]], b = fp[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hopsAll.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) });
  }
  const hops = hopsAll.filter(h => h.old !== h.new);

  const setKey = {
    params: {},
    key: '"campo" (one baked state)',
    baked: STATES.map(k => ({ key: k, query: '?' + queryOf(k) })),
    bakedWhy: 'order 06 found 7 states, made by six keys of the sprite layer: cesta and cestaN (the basket and how many balls are in it: KIT.mkCesta and mkBola, drawn in the sorted list), flor (the flower of the pair bola.no), mojado (the frog\'s wetness: the puddle he stands in, which rana() draws under him, wider the wetter he is, and the drops on him), cierra (his eyes shut) and oscuro (acts.esconde16: the picture goes dark while he shuts his eyes and somebody hides the ball; draw() line ' + lineOf('if(W.oscuro){') + ' darkens everything and draws him again over it). None of them is the set\'s: none is the day\'s light or the ground\'s (mojado is his puddle, not wet ground; oscuro is his shut eyes, a curtain over the whole picture, people and all, for 10 ticks, not the hour), so they stay in the sprite layer as the old draws them, and this one baked state draws all 7 (and every review and level picture)',
  };

  /* ---- round 2: the helps the sprite layer draws for things (as El patio's flowerLeaves: the help belongs to the thing) ---- */
  const HELPS = {
    what: 'drawn by the sprite layer just before the thing they help, 1:1, in the same sorted list (two lines added to campo.js, below): a ripple ring on the water round whatever floats or wades (a ball in the water, Canelo wading), so that a learner sees "in the water"; a darker rim round a ball that lies on the lawn, where its colour alone does not stand out from the lawn (the frog\'s yellow ball: notes, balls on the lawn)',
    margin: 3, marginWhat: 'whatever rests at the shore is on one side: on the land with at least this many px of lawn (not the bank\'s lip, its face or the water) round its foot (the lowest 2 rows of its sprite), or in the water with water all round its foot (2 px) and its ring',
    shore: 'over the water: the ground point (z 0) under the screen point (x, y - 1) is past the shore: x > ' + r4(F.BANK) + ' + .035 sin(2.3 y + 1) + .025 sin(5.1 y) (world x, y: pp-engine.js unproject)',
    ring: { inner: .45, colour: [212, 236, 246], ball: { rx: 4, ry: 2.5 }, dog: { rx: 15, ry: 3.5, dy: 1 },
      when: 'a ball (not carried) that floats (o.flota) or lies over the water (bolaXY height <= 1 and its point over the water); Canelo, not in the air (dy <= 3), with his point over the water',
      how: 'every pixel (x, y) with .45 < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1 takes the colour: a ball\'s ring at cx = bolaXY x, cy = bolaXY y (a floating ball: + its bob, (F >> 3) % 2, as unaBola), rx = radio(k) + 4, ry = 2.5; Canelo\'s at cx = x, cy = y + 1, rx = 15, ry = 3.5' },
    contact: { balls: CONTACT_BALLS, colour: [42, 60, 30], halo: 2,
      when: 'a ball of these kinds (the frog\'s small yellow one: the other two stand out from the lawn without it, balls), not carried, not floating, on the land (its point not over the water), its height <= 3, not in the tree',
      how: 'a darker rim round the ball: every pixel within 2 px (either way, the square round each) of an opaque pixel of the ball\'s sprite, as unaBola places it, and not one of them, takes the colour (a deep shade of the lawn); then the ball is drawn over it' },
    lines: [
      ['function unaBola(c,o){const p=bolaXY(o),r=radio(o.k),im=spr("bola"+o.k,()=>mkBola(o.k));', 'function unaBola(c,o){const p=bolaXY(o),r=radio(o.k),im=spr("bola"+o.k,()=>mkBola(o.k));PREVIEW.under(c,o,p,r,im);'],
      ['function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;', 'function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;PREVIEW.wade(c,o);'],
    ],
    linesWhat: 'the two lines campo.js gains (unaBola, perro): the help is drawn first, then the thing; the port draws them the same way',
  };

  const LAYOUT = {
    what: 'the open field of the park, on the world\'s axes, seen at the engine\'s 30 degrees (shadows to screen right): the lawn (El frente\'s grass, calm, as El camino\'s) from the horizon (row ' + F.HZ + ') to the bottom; at the left the tree, its foot and its crown where the old ones were, the trodden earth round its foot reaching Canelo\'s spot; at the lower right a corner of the lake, its shore a straight bank along y (up to the right on the screen), the water on the near side under a low bank of earth; along the shore the bed of reeds, at the water\'s edge and in the shallows. El camino\'s far hills and day sky over it, its sun in the upper left, the old picture\'s three clouds',
    lines: { shore: 'the lake\'s shore: x = ' + r4(F.BANK) + ' (screen sx + 2 sy = 582), from the bottom (x 150) to the picture\'s right edge (row 171); its surface ' + F.WDEPTH + ' under the lawn (a bank 4 rows high)', reeds: 'the reeds: a bed along the shore from y ' + F.REED_Y0 + ' (down to the left) to ' + F.REED_Y1 + ' (up to the right), x ' + r4(F.REED_X0) + ' to ' + r4(F.REED_X1) + ' (from the damp lip to the shallows); on the screen from (168, 202) up to (205, 185)' },
    why: 'the brief and page 11 decision 9: the set stands on the world\'s axes and is seen at the engine\'s angle; nothing is built square to the camera. The old pond\'s rim ran from the bottom (x 160) up to the right; its four reed clusters stood on one line within 5 px of the screen line sx + 2 sy = 565, which is a line along y: so the shore runs along y, the water on its near side, and the reeds along it. The shore is placed so that every place the stories put someone on the land is on it (Canelo, the frog and the children at most at sx + 2 sy = 565), every ball they float on the lake is beyond it (603 and more), and the balls they hide in the reeds are in the bed (574, 576). The tree keeps its old foot and crown. Every place on the ground keeps its old screen point (rules.floor)',
    moved: [
      'the tree\'s crown: its middle 2 px right of the old (62, 100), 27 x 25 px (the old 30 x 26), so its hint frame is inside the view (things.arbol)',
      'the lake: a straight shore along y (the old an ellipse round 232, 228): at the bottom it starts 10 px left of the old rim (x 150; the old 160), at the view\'s right edge it is 7 rows lower (182; the old 175)',
      'the reeds: a bed of about ' + F.REEDS.length + ' stalks along the shore (the old four clusters of five); its right end at x 205 (the old 217), so that the hint frame round it is inside the view',
      'the sun: upper left (the old upper right), as El camino\'s; the clouds moved clear of the corner card and the answer cards',
      'unchanged: every place of a person, the frog, Canelo, a ball and the basket',
    ],
  };

  return {
    scene: 'campo',
    made: 'node docs/proyecto/pixel/campo-sheet-make.js, from campo-set.html (window.CAMPO_SET) and coqui/ref/escenas/campo/. Order 34a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin (El camino\'s); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the field is built round the old picture: a place on its ground keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person\'s, Canelo\'s, a ball\'s or the basket\'s place (x, y): the ground point under (x, y - 1), new (x, y) = old (a ball keeps its height z). So every ground position of campo.js (LUGAR, CASA, PIES, CESTA, PILA, FILA, ORILLA, JUNCO, the acts\' places), its stories and its pairs keeps its numbers, but for the cards\' place in moves; the sheet names each one (spots, remap, code) with its world point',
      relative: 'what the old code draws or moves relative to a person, the frog, Canelo, a ball or the old crown (what is carried, the drops, the puddle, the shaking leaves round COPA and round the reeds\' 190, 186, the splash, the butterfly, the bubbles) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the stars of the happy endings (final15, final16, final17), the heart (heartAt), the darkness of esconde16 (W.oscuro: the whole picture, then the frog again)',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: LAYOUT,
    behind: { what: 'nothing: the sun and the clouds are baked into the set\'s sky (El camino\'s); the butterfly of story 17 (W.mariposa) flies in front of everything, as the old', items: [] },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, new: s.new }, s.scale != null ? { scale: s.scale } : {}, { old: s.old, what: s.what })])),
    lugar,
    hops,
    hopsWhat: 'each pair of the frog\'s places (LUGAR and every place an act hops him to) whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all ' + hopsAll.length + ' pairs). The acts\' hopTo give their own counts, whatever the distance',
    hopsAll,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'campo.js never calls clip()',
    front: {
      how: 'the old background (fondo: the tree, the reeds) was drawn before everyone; the reeds are a set thing someone (Canelo nosing in them, wading by them; a ball hidden in them) can be behind now. At its entry in the list campo.js draw sorts by y (line ' + lineOf('L.sort((m,n)=>m.y-n.y)') + '), after everyone, for each item drawn before it (a child, the frog, Canelo, a ball, the basket: each item says what it is), the set\'s own pixels of the reeds (campo-set.html part("juncos"), PART_TAGS) are drawn again inside the item\'s box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under it (a child, Canelo, a ball, the basket: unproject(x, y - 1); the frog: unproject(b.x + b.w / 2, q.y + 25)); where that ground point is over the lake, v of the water\'s surface under it (v - waterDepth * sqrt(3)). "Behind the reeds" is that depth test, not a row. Nobody stands behind the tree (every place under it is in front of its trunk), so the tree is no front part',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      waterDepth: F.WDEPTH,
      boxes: 'a child: [x - 24, y - 46 - dy, 48, 49 + dy]; the frog: frogBox with dy; Canelo: [x - 16, y - 24 - dy, 32, 27 + dy]; a ball: [x - ceil(r) - 3, y - z - 2 ceil(r) - 4, 2 ceil(r) + 6, 2 ceil(r) + 6] (x, y, z: bolaXY), its ground point under (x, y - 1) with y its entry\'s sort y - .5; the basket: [x - 12, y - 20, 24, 21]',
      parts: { juncos: { sortY: 9999, insert: 'before line ' + lineOf('L.sort((m,n)=>m.y-n.y)') + '\'s sort: L.push({y: 9999, front: "juncos"}) (after everyone)', why: 'whoever is behind reeds (Canelo nosing in them at 166, 198 and wading at 196, 204; a ball hidden in them at JUNCO) has the reeds nearer than them drawn over them: partly hidden, as being in the reeds is' } },
      tags: [
        ['L.push({y:p.y,d:()=>gente(c,id,a)})', 'L.push({y:p.y,id,d:()=>gente(c,id,a)})'],
        ['L.push({y:W.perro.y,d:()=>perro(c,a)})', 'L.push({y:W.perro.y,k:"perro",d:()=>perro(c,a)})'],
        ['L.push({y:q.y+27,d:()=>rana(c,q,a)})', 'L.push({y:q.y+27,id:"coqui",d:()=>rana(c,q,a)})'],
        ['if(W.cesta)L.push({y:W.cesta[1],d:', 'if(W.cesta)L.push({y:W.cesta[1],cesta:1,d:'],
        ['L.push({y,d:()=>unaBola(c,o)})', 'L.push({y,b:k,d:()=>unaBola(c,o)})'],
        ['KIT.escena({id:"campo"', 'window.CAMPO_BOLA={bolaXY,radio};KIT.escena({id:"campo"'],
      ],
      tagsWhat: 'each item of the sorted list says what it is (lines ' + [lineOf('L.push({y:p.y,d:()=>gente(c,id,a)})'), lineOf('L.push({y:W.perro.y,d:()=>perro(c,a)})'), lineOf('L.push({y:q.y+27,d:()=>rana(c,q,a)})'), lineOf('if(W.cesta)L.push({y:W.cesta[1],d:'), lineOf('L.push({y,d:()=>unaBola(c,o)})')].join(', ') + '); the last pair only lets the preview read where a ball is (the port has bolaXY)',
    },
    shadows: {
      coqui: { radius: .45, at: 'the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))', when: 'W.cq.vis and al > .5', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { nino: .3 }, at: 'the ground point under their feet on screen (unproject(x, y - 1))', when: 'visible (vis !== 0, al > .5)', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .3)' },
      perro: { radius: .32, at: 'the ground point under its feet on screen (unproject(x, y - 1)), in the air too (dy: the shadow stays on the ground)', when: 'W.perro shown (vis !== 0)', cast: 'castShadow(g.x, g.y, .25, .32)' },
      cesta: { radius: .36, at: 'the ground point under it (unproject(x, y - 1))', when: 'W.cesta', cast: 'castShadow(g.x, g.y, .2, .36)', why: 'the basket is the sprite layer\'s; its shadow seats it on the lawn' },
      bola: { radius: { L: r2(7 / 26), C: r2(5.5 / 26), q: r2(5 / 26) }, at: 'the ground point under it on screen (unproject(x, y - 1)), whether it lies there or is in the air over it (z > 0: the shadow stays on the ground under it), as El patio\'s', when: 'a ball shown (vis !== 0), not carried (con), not floating (flota), not in the tree (z >= tree.z, |x - tree.x| <= tree.dx, y <= tree.y: in the crown), and its ground point on the land (not over the lake)', tree: { x: OLD.HORQ[0], dx: 14, y: OLD.ARBOL[1], z: 24 }, cast: 'castShadow(g.x, g.y, .05, radius[k])', why: 'the brief: a ball in the air has its shadow on the ground under it; the old dark bar under a ball in the air is dropped (dropped)' },
      dropped: DROPPED.map(d => 'campo.js:' + d.line + ' ' + d.why).join('; '),
    },
    dropped: DROPPED,
    moves: MOVES.map(m => Object.assign({ line: m.line, act: m.act, src: m.src, to: m.to }, m.respEn ? { respEn: m.respEn } : {}, m.pts ? { places: m.pts.map(q => ({ who: q[0] || 'whoever', old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    helps: HELPS,
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as campo.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (campo.js draw: line ' + lineOf('Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a child, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog, ' + lineOf('if(o.bub)bub2(c,o.bub') + ' for Canelo). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible child\'s and the frog\'s, its own too); if none is, the first (the old)',
      top: 'a child: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2); Canelo: (x, y - 22)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a child 6, the frog b.w >> 1, Canelo 8',
      faces: 'a child\'s face: [hx - 6, y - dy + top + 5, 12, 10] (eyes to chin, not the hair), hx the head\'s middle; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heads: G.M.heads,
      headsWhat: 'each sprite (idle): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head + 1)',
      board: BOARD, boardWhat: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta (the rounds card) [2, 2, 68, 26]',
    },
    code: CODE(),
    checks: { notes: [] },
  };

  function PICTURES(pic) {
    // each picture's centre is a screen point; both sides of a pair the same window, but arriba (its two sides were two windows in the old, and
    // they show two places: the ball in the tree, the ball in the reeds). An old 75 x 40 or 113 x 60 view (1.73 to 2.6 x) is zoom 2 when its
    // subject is whole in 98 x 52; tira, coge (1.46 x) and abajo (1.31 x) are zoom 1
    return {
      'bola.si': pic(148, 127, 2, 'a ball on the grass, close'), 'bola.no': pic(148, 127, 2, 'a flower there, close'),
      'tiene.si': pic(131, 156, 1, 'Canelo lies with the ball by him'), 'tiene.no': pic(131, 156, 1, 'Canelo jumps, the ball in the air before him'),
      'tira.si': pic(151, 148, 1, 'Luis throws the ball: it flies away from him'), 'tira.no': pic(151, 148, 1, 'Luis holds his hands up, the ball drops to him'),
      'coge.si': pic(151, 148, 1, 'Carmen catches the ball over her head'), 'coge.no': pic(151, 148, 1, 'Carmen throws the ball away'),
      'salta.si': pic(139, 126, 2, 'Canelo jumps over the ball'), 'salta.no': pic(139, 126, 2, 'Canelo runs, the ball before him'),
      'dame.si': pic(139, 124, 2, 'Carmen holds out her hand, the frog has the ball'), 'dame.no': pic(139, 124, 2, 'Carmen has the ball'),
      'mi.si': pic(138, 124, 2, 'Luis points at himself, his ball in his hands'), 'mi.no': pic(138, 124, 2, 'Luis points at the frog, his ball on the grass'),
      'tu.si': pic(139, 124, 2, 'Carmen points at Luis'), 'tu.no': pic(139, 124, 2, 'Carmen points at herself'),
      'arriba.si': pic(62, 114, 2, 'the big ball up in the tree, in its fork'), 'arriba.no': pic(180, 182, 2, 'the big ball down in the reeds'),
      'abajo.si': pic(89, 118, 1, 'the frog on the grass under the tree'), 'abajo.no': pic(89, 118, 1, 'the frog up in the tree\'s crown'),
      'mas.si': pic(142, 164, 1, 'Canelo sniffs at the ball, wet (zoom 1 with the trunk: round 2)'), 'mas.no': pic(142, 164, 1, 'Canelo drinks at the water'),
    };
  }

  function CODE() {
    const C = [], c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const pos = POS.inSceneFile, byLine = new Map();
    for (const p of pos) { const L = +p.at.split(':')[1]; if (!byLine.has(L)) byLine.set(L, []); byLine.get(L).push(p); }
    const NOTE = {
      [lineOf('const ARBOL=')]: ['the tree (points.arbol, copa, horq, sitio): its foot, the fork and Canelo\'s spot at their old screen points; the crown 2 px right, 3 px narrower', { points: ['arbol', 'copa', 'horq', 'sitio'] }],
      [lineOf('const AGUA=')]: ['dropped with the old background (fondo, and enAgua, which nothing calls): the lake\'s shore and the reed bed are the set\'s (layout.lines)', { dropped: 'fondo' }],
      [lineOf('const LUGAR=')]: ['the floor rule: the same screen places', { spots: ['frog.centro', 'frog.inicio'] }],
      [lineOf('const CASA=')]: ['the floor rule: the same screen places', { spots: ['luis.casa', 'carmen.casa', 'bola.pies', 'cesta', 'pila.0', 'pila.1', 'pila.2', 'pila.3'] }],
      [lineOf('const FILA=')]: ['the floor rule: the same screen places', { spots: ['fila.0', 'fila.1', 'fila.2', 'orilla', 'junco'] }],
      [lineOf('{id:"juncos",box:')]: ['the reeds\' box and hand (things.juncos)', { thing: 'juncos' }],
      [lineOf('{id:"campo",box:')]: ['the field\'s box (things.campo)', { thing: 'campo' }],
      [lineOf('c.drawImage(spr("campo",fondo),0,0);')]: ['dropped: the set (dropped)', { dropped: true }],
      [lineOf('if(W.tiembla){')]: ['relative to the old crown\'s middle (COPA) and to the reeds\' 190, 186: unchanged (both in the new crown and bed)', 'unchanged'],
      [lineOf('if(W.flor){')]: ['the flower\'s own drawing, relative to W.flor: unchanged', 'unchanged'],
      [lineOf('if(W.oscuro){')]: ['the darkness of esconde16 over the whole picture, then the frog again: unchanged (setKey.bakedWhy)', 'unchanged'],
      [lineOf('async alagua(')]: ['the floor rule: the four floating balls at the same screen places, on the lake beyond the reeds (spots flota.0 to flota.3); the rest: a flight\'s height and steps', { spots: ['flota.0', 'flota.1', 'flota.2', 'flota.3'] }],
      [lineOf('KIT.escena({id:"campo"')]: ['the view (views.wide) and the heart (points.corazon): unchanged', { view: 'wide', point: 'corazon' }],
    };
    for (const [L, ps] of [...byLine.entries()].sort((a, b) => a[0] - b[0])) {
      const old = ps.map(p => (p.what || 'point').replace(/_+/g, '_') + ' ' + JSON.stringify(p.nums)).join('; ');
      if (NOTE[L]) { c(L, old, NOTE[L][1], NOTE[L][0]); continue; }
      const kinds = new Set(ps.map(p => /^(hopTo|mueve|perroA)\(|^x:,y:|^W\.cesta|^vuela\(…\)|^d\[\]/.test(p.what || '') ? 'floor' : /^pts\[\]/.test(p.what) ? 'stars' : /^(vuela\(|ranaSalta|brinco)/.test(p.what) ? 'motion' : 'drawing'));
      const notes = [];
      if (kinds.has('floor')) notes.push('the floor rule: every place here (a child\'s feet, the frog\'s q, Canelo\'s, a ball\'s, the basket\'s) keeps its screen place');
      if (kinds.has('stars')) notes.push('screen effect: the stars, unchanged');
      if (kinds.has('motion')) notes.push('not a place: a flight\'s or a jump\'s height and steps');
      if (kinds.has('drawing')) notes.push('a sprite\'s, a card\'s or an effect\'s own drawing, relative to where it is drawn: unchanged');
      c(L, old, kinds.has('floor') ? { floor: true } : 'unchanged', notes.join('; '));
    }
    // the cosas lines with their old boxes and hands
    c(lineOf('{id:"arbol",box:'), 'box arbol [COPA[0]-COPA[2],COPA[1]-COPA[3],COPA[2]*2,COPA[3]*2+26] = ' + JSON.stringify(OLDBOX.arbol) + '; hand [COPA[0],COPA[1]] = [60,100]', { thing: 'arbol', box: things.arbol.box, hand: things.arbol.hand });
    c(lineOf('{id:"juncos",box:'), 'box juncos [160,168,60,48]; hand [188,190]', { thing: 'juncos', box: things.juncos.box, hand: things.juncos.hand });
    c(lineOf('{id:"campo",box:'), 'box campo [0,100,240,116]', { thing: 'campo', box: things.campo.box });
    c(lineOf('const caja=id=>'), 'caja(id): [x - 11, y - alto(id), 22, alto(id)]', 'relative to the child: unchanged');
    c(lineOf('const cajaBola=n=>'), 'cajaBola: [x - r - 2, y - z - 2r - 2, 2r + 4, 2r + 4]', 'relative to the ball: unchanged');
    c(lineOf('{id:"perro",si:'), 'perro box [x - 14, y - 20, 28, 22]; cesta box [x - 11, y - 16, 22, 18]', 'relative: unchanged');
    c(lineOf('L.sort((m,n)=>m.y-n.y)'), 'the sorted list', { front: ['juncos'] }, 'one entry added before the sort (front.parts), each item tagged (front.tags)');
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: campo\'s fresh() puts him at LUGAR.inicio');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', 'a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)');
    return C;
  }
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);   // its rows of cells: o ink, w white
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([Math.round(hp[0]) - 12 + i * 3, Math.round(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };   // its drawn cells, both beats
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
// the frame's rings (juego.js spot): between 5 and 12 px outside the box; a face crossed by them (not wholly inside the inner edge, not wholly outside)
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'campo') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'campo-sheet-'));
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

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M, KEY = STATES[0];
  /* the inventory: every thing, place, view, position, pair and level picture */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-campo.json'), 'utf8'));
  const pairSides = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'campo').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
  const otherScene = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene !== 'campo').map(s => p.w + '.' + s + ' (' + p[s].scene + ')'));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'campo') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('campo.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n.replace(/^0\./, '.')) || e.old.replace(/\s/g, '').includes(n)))) P.push('campo.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  for (const m of sh.moves) if (!LINES[m.line - 1].includes(m.src)) P.push('moves: line ' + m.line + ' does not hold ' + m.src.slice(0, 60));
  for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
  for (const [a] of sh.front.tags) if (!CAMPO_JS.includes(a)) P.push('front.tags: campo.js does not hold ' + a);
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + ') and ' + Object.keys(sh.spots).filter(k => k.startsWith('frog.')).length + ' frog places in all, ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-campo (' + pairSides.length + ' pictures here' + (otherScene.length ? '; ' + otherScene.join(', ') + ' another scene\'s' : '; none is another scene\'s') + '), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + pos.inSceneFile.length + ' places of campo.js named in code, ' + STATES.length + ' baked state (the old ' + inv.states.count + ')');

  /* hops */
  { const ks = sh.hopsAll; const changed = ks.filter(h => h.old !== h.new);
    for (const c of changed) P.push('hops: ' + c.a + '-' + c.b + ' ' + c.old + ' -> ' + c.new + ' is not the old count');
    if (sh.hops.length !== changed.length) P.push('hops: the sheet lists ' + sh.hops.length + ', the places give ' + changed.length);
    notes.push('hops: all ' + ks.length + ' pairs of the frog\'s ' + Object.keys(FROG_PLACES).length + ' places (LUGAR and every place an act hops him to; round(d / 30), 1 to 4, kit.js acts.ir) keep the old count'); }

  /* the set's pixels: which part drew each, its depth */
  const TAG = (() => { const m = new Array(240 * 216).fill(null); for (const [k, list] of Object.entries(G.parts[KEY])) for (const i of list) m[i] = k; return m; })();
  const Z = G.z[KEY], K = G.kinds[KEY], RGB = G.rgb[KEY], WET = G.wet[KEY], OG = G.onGround[KEY], SH = G.shade[KEY];
  const rgbAt = i => [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]];
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];

  /* every set thing's pixels inside its touch box (its leaves at every wind step); nothing decorative; the hit order */
  { const res = [];
    for (const name of SOLID) { const b = sh.things[name].box; let out = 0, n = 0;
      for (const i of (G.parts[KEY][name] || []).concat(G.leaf[KEY][name] || [])) { n++; const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + name + ' are outside its touch box ' + JSON.stringify(b));
      res.push(name + ' ' + JSON.stringify(b) + ' (' + n + ' px)'); }
    const parts = new Set(Object.keys(G.parts[KEY]));
    for (const p of parts) if (!sh.things[p] || !sh.things[p].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s');
    const ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const hitAt = (x, y) => { for (const [id, m] of ORDER) { const b = sh.things[id].box; if (x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) return id; } return null; };
    const wrong = {};
    for (const name of SOLID) for (const i of G.parts[KEY][name] || []) { const h = hitAt(i % 240, Math.floor(i / 240)); if (h !== name) { const k = name + ' -> ' + h; wrong[k] = (wrong[k] || 0) + 1; } }
    for (const [k, n] of Object.entries(wrong)) P.push('hit: ' + n + ' px of ' + k + ' (a touch there answers the other thing)');
    if (meets(sh.things.arbol.box, sh.things.juncos.box)) P.push('boxes: the tree\'s and the reeds\' overlap');
    // nothing decorative over a touch box: the only set parts are the touch keys'; the lake is the field's ground (inside the campo box)
    notes.push('boxes: every pixel of each set thing inside its touch box: ' + res.join(', ') + ' (still: no leaf or reed moves at any wind step); every pixel of each answers that thing in the hit order; the set\'s parts are ' + [...parts].sort().join(', ') + ' (each a touch key\'s: nothing decorative); the lake is the field\'s ground'); }

  /* every castShadow call of the bake darkens; a thin thing (a reed) casts only a short contact shadow at its foot */
  { const byPart = {};
    for (const c of G.shadows[KEY]) { const [x, y, z, r, s] = c.args, k = c.part || '(none)';
      if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + k + ' castShadow(' + c.args.map(r2).join(', ') + '): strength ' + s + ', radius ' + r + ' (nothing is cast)');
      const b = byPart[k] = byPart[k] || { calls: 0, set: 0, zero: 0 }; b.calls++; b.set += c.set; if (!c.set) b.zero++; }
    for (const [k, b] of Object.entries(byPart)) if (!b.set) P.push('shadow: the part ' + k + ' casts ' + b.calls + ' times and darkens nothing');
    // the reeds: every shadow pixel within 4 px of a reed's foot (the lowest pixel of a stalk's column)
    const feet = F.REED_FEET;
    let far = 0, worst = 0; for (const i of G.shadowPx[KEY].juncos || []) { const x = i % 240, y = Math.floor(i / 240), d = Math.min(...feet.map(f => Math.hypot(x - f[0], y - f[1]))); worst = Math.max(worst, d); if (d > 4) far++; }
    if (far) P.push('reeds\' shadow: ' + far + ' px further than 4 px from a reed\'s foot');
    notes.push('shadows: every castShadow call of the bake has strength 1 and a radius, each casting part darkens: ' + Object.entries(byPart).map(([k, b]) => k + ' ' + b.calls + ' calls, ' + b.set + ' px set (' + b.zero + ' calls wholly over shadow already)').join('; ') + '; the reeds (thin) cast only contact shadows, every pixel within ' + r2(worst) + ' px of a reed\'s foot'); }

  /* the ground: lawn, Canelo's patch of dug earth, the bank's lip, the bank's face and the water; nothing else. Round 2: the patch is a small one
     of its own where the old oval was (SITIO), apart from the trunk (lawn between them); his coat and the balls stand out from it at least as
     well as from the old oval */
  { let other = 0, nW = 0, nF = 0; const patch = []; for (let i = 0; i < 240 * 216; i++) { const y = Math.floor(i / 240); if (y < F.HZ) continue; const k = K[i];
      if (k === G.K.water) nW++; else if (k === G.K.road) { if (G.shoreV[KEY][i] > .2) patch.push(i); } else if (k === G.K.none && Z[i] > -1e8 && !TAG[i]) nF++; else if (k !== G.K.grass && !TAG[i]) other++; }
    if (other) P.push('ground: ' + other + ' px of the ground are none of lawn, the patch, the bank or the water');
    const trunkFootRow0 = Math.max(...G.parts[KEY].arbol.map(i => Math.floor(i / 240))), top = Math.min(...patch.map(i => Math.floor(i / 240))), xs = patch.map(i => i % 240), ys = patch.map(i => Math.floor(i / 240));
    const gap = top - trunkFootRow0 - 1, pb = [Math.min(...xs), top, Math.max(...xs), Math.max(...ys)];
    if (gap < 3) P.push('patch: only ' + gap + ' rows of lawn between the trunk\'s foot and Canelo\'s patch');
    if (Math.abs((pb[0] + pb[2]) / 2 - OLD.SITIO[0]) > 4 || Math.abs((pb[1] + pb[3]) / 2 - OLD.SITIO[1]) > 4) P.push('patch: not where the old oval was ' + JSON.stringify(pb));
    const pm = [0, 1, 2].map(c => patch.reduce((t, i) => t + RGB[i * 3 + c], 0) / patch.length), res = [];
    for (const [k, nm] of [['perro', 'Canelo\'s coat'], ['L', 'the red-and-white ball'], ['q', 'the yellow ball']]) { const dn = dE(M.colours[k], pm), dO = dE(M.colours[k], M.oldOval); res.push(nm + ' ' + Math.round(dn) + ' (the old oval ' + Math.round(dO) + ')');
      if (dn < dO) P.push('patch: ' + nm + ' stands out from the patch by ' + Math.round(dn) + ', from the old oval by ' + Math.round(dO)); }
    notes.push('ground: the lawn, Canelo\'s patch of dug earth (' + patch.length + ' px, on the screen ' + JSON.stringify(pb) + ', ' + gap + ' rows of lawn under the trunk\'s foot: apart from it), the bank\'s face (' + nF + ' px) and the water (' + nW + ' px); nothing else but the shadows the tree and the reeds cast');
    notes.push('patch (round 2): its mean colour ' + pm.map(Math.round) + ' (the old oval ' + M.oldOval.map(Math.round) + '); against it (CIE76): ' + res.join(', ')); }
  function OLDY(y) { return y; }

  /* the water reads as water: its colour apart from the sky's, its ripples, its bank */
  { const sky = G.SKYB.map(c => c), wc = [0, 0, 0]; let n = 0, light = 0; const ws = [];
    for (let i = 0; i < 240 * 216; i++) if (K[i] === G.K.water && i % 240 >= x0 && i % 240 < x0 + 196) { n++; const c = rgbAt(i); for (let k = 0; k < 3; k++) wc[k] += c[k]; ws.push(c); }
    const m = wc.map(v => v / n); for (const c of ws) if (c[0] + c[1] + c[2] > (m[0] + m[1] + m[2]) * 1.35) light++;
    const dSky = Math.min(...sky.map(s => dE(m, s)));
    if (dSky < 25) P.push('water: its mean colour ' + m.map(Math.round) + ' is within ' + Math.round(dSky) + ' of a sky band (keep 25)');
    if (light / n < .03) P.push('water: only ' + Math.round(light / n * 1000) / 10 + '% of it shows ripples');
    // the bank: along the shore's whole length in the view, the face of earth between the lawn and the water (at every column the water reaches)
    let cols = 0, faced = 0; for (let x = x0; x < x0 + 196; x++) { let top = -1; for (let y = F.HZ; y < 216; y++) if (K[y * 240 + x] === G.K.water) { top = y; break; } if (top < 0) continue; cols++;
      if ([1, 2, 3, 4].some(d => (K[(top - d) * 240 + x] === G.K.none && Z[(top - d) * 240 + x] > -1e8 && !TAG[(top - d) * 240 + x]) || TAG[(top - d) * 240 + x] === 'juncos')) faced++; }
    if (faced < cols * .7) P.push('water: the bank\'s face shows over the water at ' + faced + ' of the ' + cols + ' columns');
    notes.push('water: ' + n + ' px in the view, mean colour ' + m.map(Math.round) + ' (' + Math.round(dSky) + ' from the nearest sky band, CIE76), ' + Math.round(light / n * 1000) / 10 + '% of it ripples (baked) and ' + G.glints[KEY].length + ' glints that come and go each frame (drawGlints, 8 steps a second, still when the OS asks); the bank\'s face (or the reeds standing on it) over the water at ' + faced + ' of the ' + cols + ' columns it reaches'); }

  /* the old sprite layer's shapes */
  const alto = id => 44;
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const people = w => Object.entries(w.gente || {}).filter(([id, p]) => shown(p));
  const poseKey = (id, p) => { const ps = p.pose === 'wave' ? 'wave0' : p.pose === 'arriba' ? 'wave0' : p.pose === 'atras' ? 'idle' : ['offer', 'yo', 'tu', 'wave0', 'wave1'].includes(p.pose) ? p.pose : 'idle'; return id + '.' + ps + '.' + (p.dir < 0 ? -1 : 1); };
  const maskOf = (id, p) => M.masks[poseKey(id, p)] || M.masks[id + '.idle.' + (p.dir < 0 ? -1 : 1)];
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const personRows = (id, p) => rowsAt(maskOf(id, p), Math.round(p.x), Math.round(p.y) - Math.round(p.dy || 0));
  const dogRows = o => { const ps = M.animals['perro.' + o.pose + '.0.1'] ? o.pose : 'sit'; return rowsAt(M.animals['perro.' + ps + '.0.' + (o.dir < 0 ? -1 : 1)], Math.round(o.x), Math.round(o.y) - Math.round(o.dy || 0)); };
  const dogShown = w => w.perro && w.perro.vis !== 0 && w.perro.x != null;
  const faceOf = (id, p) => { const hd = sh.talk.heads[id], x = Math.round(p.x), y = Math.round(p.y) - Math.round(p.dy || 0), hx = p.dir < 0 ? x - hd.head + 1 : x + hd.head; return [Math.round(hx - 6), y + hd.top + 5, 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + Math.round(q.dy || 0), b.w - 4, Math.round(b.h * .6)]; };
  const facesOf = w => { const f = people(w).filter(([id, p]) => !(p.al != null && p.al < .5)).map(([id, p]) => [id + '\'s face', faceOf(id, p)]); if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
  // where a ball is: campo.js bolaXY (in somebody's hands, in the dog's mouth, or where it lies): [x, ground row, height]
  const frogHands = q => { const b = frogBox(q); return [b.x + (b.w >> 1), q.y + 28, 3 - Math.round(q.dy || 0)]; };
  const ballXY = (w, o) => { if (o.con === 'cq') return frogHands(w.cq); if (o.con === 'perro') { const p = w.perro; return [Math.round(p.x) + (p.dir < 0 ? -13 : 13), Math.round(p.y) + 1, 5 + (p.dy || 0)]; }
    if (o.con) { const p = w.gente[o.con]; if (!p) return null; const h = alto(o.con), d = p.dir < 0 ? -1 : 1; return [Math.round(p.x) + d * (p.pose === 'offer' ? 11 : p.pose === 'arriba' ? 8 : 6), Math.round(p.y) + 1, (p.pose === 'arriba' ? h - 3 : p.pose === 'offer' ? h - 27 : h - 24) + (p.dy || 0)]; }
    return [Math.round(o.x), Math.round(o.y), Math.round(o.z || 0)]; };
  const ballRows = (w, o) => { const p = ballXY(w, o); if (!p) return null; if (o.flota) { const r = M.R[o.k], rs = M.balls[o.k], cut = Math.round(r * .7), last = Math.max(...rs.map(q => q[0])); return rowsAt(rs.filter(q => q[0] <= last - cut), p[0], p[1] + cut); } return rowsAt(M.balls[o.k], p[0], p[1] - p[2]); };
  const inTree = (o, p) => { const T = sh.shadows.bola.tree; return p[2] >= T.z && Math.abs(p[0] - T.x) <= T.dx && p[1] <= T.y; };
  const vAt = (sx, sy) => { const g = E.atZ(sx, sy, 0); return (g[0] + g[1]) / E.R2; };
  const wetAt = (sx, sy) => { const x = Math.round(sx), y = Math.round(sy); return x >= 0 && x < 240 && y >= 0 && y < 216 && WET[y * 240 + x] === 1; };
  const vItem = (sx, sy) => vAt(sx, sy) - (wetAt(sx, sy) ? F.WDEPTH * Math.sqrt(3) : 0);   // over the lake: the water's surface under it
  const nearerRows = (rs, v, names) => { const out = {};
    for (const [y, a, b] of rs) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (names.includes(TAG[i]) && Z[i] > v / COS - (y + .5 - E.OY) * T30 / E.S) out[TAG[i]] = (out[TAG[i]] || 0) + 1; } }
    return out; };
  const inReedBed = (sx, sy) => { const g = E.atZ(sx, sy, 0); return g[0] >= F.REED_X0 - .12 && g[0] <= F.REED_X1 + .12 && g[1] >= F.REED_Y1 - .15 && g[1] <= F.REED_Y0 + .15; };

  /* the old runs' W in the new places: moves (for the acts the story uses), remap moved (the story's own positions) */
  const MVall = sh.moves.flatMap(m => (m.places || []).map(q => Object.assign({ act: m.act }, q)));
  const RMall = sh.remap.filter(e => e.moved).map(e => ({ old: e.old, new: e.new, files: e.uses.map(u => u.split(' ')[0].replace(/\.json$/, '')) }));
  let MV = MVall, RM = RMall, EN = null;
  const remapW = w0 => { const w = JSON.parse(JSON.stringify(w0));
    if (EN && w.respEn == null && (w.gente && Object.keys(w.gente).length)) w.respEn = EN;
    const mv = (who, p) => { const m = MV.find(q => (q.who === 'whoever' || q.who === who) && q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y)); if (m) { p.x = m.new[0]; p.y = m.new[1]; return; }
      const r = RM.find(q => q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y)); if (r) { p.x = r.new[0]; p.y = r.new[1]; } };
    for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) mv(id, p);
    if (w.perro && w.perro.x != null) mv('perro', w.perro);
    for (const [k, o] of Object.entries(w.bolas || {})) if (o && !o.con && o.x != null) mv('bola', o);
    if (w.cq) { const m = MV.find(q => q.who === 'cq' && q.old[0] === Math.round(w.cq.x) && q.old[1] === Math.round(w.cq.y)); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } else { const r = RM.find(q => q.old[0] === w.cq.x && q.old[1] === w.cq.y); if (r) { w.cq.x = r.new[0]; w.cq.y = r.new[1]; } } }
    if (w.flor) { const r = RM.find(q => q.old[0] === w.flor[0] && q.old[1] === w.flor[1]); if (r) w.flor = r.new.slice(); }
    if (w.respEn) { const r = RM.find(q => q.old[0] === w.respEn[0] && q.old[1] === w.respEn[1]); if (r) w.respEn = r.new.slice(); }
    return w; };
  const actsOf = st => new Set((JSON.stringify(st).match(/"act":\s*"[A-Za-z0-9]+"/g) || []).map(a => a.split('"')[3]));
  const forRun = r => { const a = actsOf(r.story); MV = MVall.filter(q => a.has(q.act) || q.act === '*'); RM = RMall.filter(q => q.files.includes(r.story.id)); EN = (sh.moves.find(m => m.respEn && a.has(m.act)) || {}).respEn || null; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;

  /* the preview puts everyone where the sheet does: at every moment, each child, the frog, Canelo and every ball not carried (PREVIEW.remapW
     against this maker's remapW) */
  { let nP = 0, bad = 0;
    runs.forEach((r, ri) => { forRun(r); r.lines.forEach((ln, li) => { const w = remapW(ln.W), pv = G.PV[ri][li], mine = {};
      for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) mine[id] = [Math.round(p.x), Math.round(p.y)];
      if (w.cq) mine.cq = [w.cq.x, w.cq.y]; if (w.perro && w.perro.x != null) mine.perro = [Math.round(w.perro.x), Math.round(w.perro.y)];
      for (const [k, b] of Object.entries(w.bolas || {})) if (b && !b.con && b.x != null) mine['bola.' + k] = [Math.round(b.x), Math.round(b.y)];
      if (w.respEn) mine.respEn = w.respEn.slice();
      for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } } }); });
    notes.push('preview: at every moment of the ' + runs.length + ' runs (' + nP + ' places of the children, the frog, Canelo, the balls and the cards) campo-preview.html puts everyone exactly where the sheet does (' + bad + ' differ)'); }

  /* the ground under everyone, and the balls, at every moment and in every pair picture */
  const CLEAR = 5;
  const trunkFootRow = Math.max(...G.parts[KEY].arbol.map(i => Math.floor(i / 240))), trunkCols = (() => { const xs = G.parts[KEY].arbol.filter(i => Math.floor(i / 240) >= trunkFootRow - 1).map(i => i % 240); return [Math.min(...xs), Math.max(...xs)]; })();
  const edge = new Set(), seenG = new Set(), behind = new Map(), wade = new Map(), ballSeen = new Map(), stats = { stand: 0, balls: 0, least: 99, leastAt: '', inReeds: [1, ''], float: 99, tree: [99, 99], air: 0, grassRing: 1 };
  const lawnRing = (x, y, r) => { let n = 0, ok = 0; for (let a = 0; a < 16; a++) { const px = Math.round(x + Math.cos(a / 16 * 6.283) * (r + 2)), py = Math.round(y - 1 + Math.sin(a / 16 * 6.283) * (r + 2) * .5); if (py < y - 1 - r * .3) continue; if (px < 0 || px >= 240 || py < 0 || py >= 216) continue; n++; const i = py * 240 + px; if ((K[i] === G.K.grass || K[i] === G.K.road) && !WET[i]) ok++; } return n ? ok / n : 1; };
  const groundCheck = (where, w, oldW) => {
    const key = keyOf(w); if (!STATES.includes(key)) P.push('state: ' + where + ' reaches ' + key + ', which is not baked');
    const items = [];
    for (const [id, p] of people(w)) items.push({ who: id, rows: personRows(id, p), feet: [Math.round(p.x), Math.round(p.y) - 1], at: Math.round(p.x) + ',' + Math.round(p.y), old: oldW && oldW.gente && oldW.gente[id] ? [Math.round(oldW.gente[id].x), Math.round(oldW.gente[id].y) - 1] : null });
    if (dogShown(w)) { const o = w.perro; items.push({ who: 'perro', rows: dogRows(o), feet: [Math.round(o.x), Math.round(o.y) - 1], at: Math.round(o.x) + ',' + Math.round(o.y), old: oldW && oldW.perro ? [Math.round(oldW.perro.x), Math.round(oldW.perro.y) - 1] : null }); }
    const q = w.cq; if (q && q.vis && !(q.al <= .3)) { const b = frogBox(q), dy = Math.round(q.dy || 0), rs = []; for (let y = b.y + dy; y < b.y + dy + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]);
      items.push({ who: 'the frog', rows: rs, feet: [b.x + b.w / 2, q.y + 25], at: q.x + ',' + q.y, frog: true, up: q.y < 120, old: oldW && oldW.cq ? [frogBox(oldW.cq).x + frogBox(oldW.cq).w / 2, oldW.cq.y + 25] : null }); }
    if (w.cesta) items.push({ who: 'the basket', rows: rowsAt(M.cesta, w.cesta[0], w.cesta[1]), feet: [w.cesta[0], w.cesta[1] - 1], at: w.cesta.join(','), basket: true });
    for (const it of items) {
      const k = JSON.stringify([it.who, it.at, it.rows.length, it.rows[0]]); if (seenG.has(k)) continue; seenG.add(k); stats.stand++;
      if (it.up) continue;   // the frog up in the crown (abajo.no): over the tree, as the old
      const v = vItem(it.feet[0], it.feet[1]), near = nearerRows(it.rows, v, SOLID);
      for (const [part, n] of Object.entries(near)) { const fp = sh.front.parts[part];
        if (fp) { const b = it.who + ' at ' + it.at + ' behind ' + part; behind.set(b, (behind.get(b) || 0) + n);
          if (/^pair /.test(where)) P.push('pair: ' + where + ' ' + it.who + ' at ' + it.at + ' has ' + n + ' px of reeds over them (the subject not hidden)');
          const o = it.old || it.feet, dOld = enAguaOld(o[0], o[1] + 1), oldReed = within([o[0], o[1], 1, 1], OLDBOX.juncos);
          if (!(dOld < 1.1 || oldReed)) P.push('reeds: ' + where + ' ' + it.who + ' at ' + it.at + ' has ' + n + ' px of reeds over them, where the old picture had them away from the reeds (old pond ' + r2(dOld) + ')');
          continue; }
        P.push('ground: ' + where + ' ' + it.who + ' at ' + it.at + ': ' + n + ' px of ' + part + ' nearer than them inside their sprite'); }
      // in the water or in the reeds only where the old picture had them there (the old pond and its rim; the old reeds' box)
      const wet = wetAt(it.feet[0], it.feet[1]), reed = inReedBed(it.feet[0], it.feet[1]);
      if (wet || reed) { const o = it.old || it.feet, dOld = enAguaOld(o[0], o[1] + 1), oldReed = within([o[0], o[1], 1, 1], OLDBOX.juncos);
        const k2 = it.who + ' at ' + it.at + (wet ? ' in the water' : ' in the reeds'); wade.set(k2, (wade.get(k2) || 0) + 1);
        if (!(dOld < 1.07 || oldReed)) P.push('water: ' + where + ' ' + it.who + ' at ' + it.at + (wet ? ' stands in the water' : ' stands in the reeds') + ', where the old picture had them on the grass (old pond ' + r2(dOld) + ')'); }
      // at least 5 rows of lawn between the feet and the foot of the trunk behind them
      const cols = [Math.min(...it.rows.filter(r => r[0] >= Math.max(...it.rows.map(q => q[0])) - 1).map(r => r[1])), Math.max(...it.rows.filter(r => r[0] >= Math.max(...it.rows.map(q => q[0])) - 1).map(r => r[2]))];
      const feetRow = Math.max(...it.rows.map(r => r[0]));
      if (cols[1] >= trunkCols[0] && cols[0] <= trunkCols[1] && feetRow > trunkFootRow) { const g = feetRow - trunkFootRow - 1; if (g < stats.least) { stats.least = g; stats.leastAt = where + ' ' + it.who + ' at ' + it.at; } if (g < CLEAR) P.push('clear ground: ' + where + ' ' + it.who + ' at ' + it.at + ': ' + g + ' rows of lawn between the feet and the trunk\'s foot'); }
      // the basket: on the lawn, clear ground under it (no water, no reed, not the bank)
      if (it.basket) { if (lawnRing(w.cesta[0], w.cesta[1], 10) < 1) P.push('basket: ' + where + ' at ' + it.at + ' has something but lawn round its foot'); if (near.juncos) P.push('basket: ' + where + ' among the reeds'); }
    }
    // the balls
    for (const [k, o] of Object.entries(w.bolas || {})) { if (!o || o.vis === 0) continue; const p = ballXY(w, o); if (!p) continue;
      const kk = JSON.stringify([k, o.k, p, !!o.flota, o.con || null]); if (seenG.has(kk)) continue; seenG.add(kk); stats.balls++;
      const rs = ballRows(w, o), r = M.R[o.k];
      if (o.con) continue;   // in somebody's hands or mouth: drawn with them, as the old
      if (o.flota) { // floating: on the water, a ring of water round it, no reed over it
        const n = Object.values(nearerRows(rs, vItem(p[0], p[1] - 1), SOLID)).reduce((a, b) => a + b, 0); if (n) P.push('ball: ' + where + ' the ball ' + k + ' floating at ' + p.slice(0, 2) + ' has ' + n + ' px of reeds over it');
        let wn = 0, wt = 0; for (const dx of [-r - 3, -r - 2, r + 2, r + 3]) { const i = (p[1]) * 240 + Math.round(p[0] + dx); wt++; if (K[i] === G.K.water) wn++; } for (const dy of [2, 3]) { const i = (p[1] + dy) * 240 + p[0]; wt++; if (K[i] === G.K.water) wn++; }
        stats.float = Math.min(stats.float, wn / wt); if (wn < wt) P.push('ball: ' + where + ' the ball ' + k + ' floating at ' + p.slice(0, 2) + ' has ' + (wt - wn) + ' of ' + wt + ' points round it not water');
        continue; }
      if (inTree(o, p)) { // in the tree: in the crown where the old was, the crown (or its hollow) behind it, told from the leaves
        let on = 0, n = 0, s = [0, 0, 0], m = 0; for (const [y, a, b] of rs) for (let x = a; x <= b; x++) { n++; const i = y * 240 + x; if (TAG[i] === 'arbol') { on++; m++; const c = rgbAt(i); for (let j = 0; j < 3; j++) s[j] += c[j]; } }
        const d = m ? dE(M.colours[o.k], s.map(v => v / m)) : 99; stats.tree = [Math.min(stats.tree[0], on / n), Math.min(stats.tree[1], d)];
        if (on < n * .8) P.push('ball: ' + where + ' the ball ' + k + ' in the tree at ' + p + ' has the tree behind only ' + on + ' of its ' + n + ' px');
        if (d < 40) P.push('ball: ' + where + ' the ball ' + k + ' in the tree stands out from what is behind it by only ' + Math.round(d));
        continue; }
      const gp = [p[0], p[1] - 1], wetB = wetAt(gp[0], gp[1]), reedB = inReedBed(gp[0], gp[1]), near = nearerRows(rs, vItem(gp[0], gp[1]), SOLID), hid = Object.values(near).reduce((a, b) => a + b, 0), tot = rs.reduce((a, q) => a + q[2] - q[1] + 1, 0);
      if (p[2] > 3) { stats.air++; if (wetB) P.push('ball: ' + where + ' the ball ' + k + ' in the air at ' + p + ' has its shadow point over the water'); }
      if (reedB || hid) { // in the reeds: partly hidden by reeds, and seen (at least half of it), where the old picture had a ball in the reeds
        const oldIn = within([p[0], p[1], 1, 1], OLDBOX.juncos); ballSeen.set(k + ' at ' + p.slice(0, 2), Math.round((1 - hid / tot) * 100));
        if (!oldIn) P.push('ball: ' + where + ' the ball ' + k + ' at ' + p + ' is in the reeds (' + hid + ' px hidden), where the old picture had it on the grass');
        if (hid > tot * .5) P.push('ball: ' + where + ' the ball ' + k + ' at ' + p + ': ' + hid + ' of its ' + tot + ' px behind reeds (keep half seen)');
        stats.inReeds = hid / tot < stats.inReeds[0] ? [hid / tot, k + ' ' + p] : stats.inReeds; continue; }
      if (wetB && p[2] <= 3) { stats.wetRing = (stats.wetRing || 0) + 1; continue; }   // round 2: in the water with its ring (the shore check)
      if (p[2] <= 3) { const ob = oldW && oldW.bolas && oldW.bolas[k] && !oldW.bolas[k].con ? [Math.round(oldW.bolas[k].x), Math.round(oldW.bolas[k].y)] : p, g = lawnRing(p[0], p[1], r), oldEdge = enAguaOld(ob[0], ob[1]) < 1.07;   // the old picture had it on the old pond's rim: at the water's edge
        if (oldEdge) { edge.add(k + ' at ' + p.slice(0, 2) + ' (' + Math.round(g * 100) + '% lawn round it)'); if (wetB) P.push('ball: ' + where + ' the ball ' + k + ' at the water\'s edge at ' + p + ' is on the water'); }
        else { stats.grassRing = Math.min(stats.grassRing, g); if (g < .75) P.push('ball: ' + where + ' the ball ' + k + ' on the ground at ' + p + ' has lawn on only ' + Math.round(g * 100) + '% of the ring round it'); } }
    }
    // the balls a learner must tell apart do not overlap (but the pile of balls Canelo makes, and what is in somebody's hands, as the old)
    const free = Object.entries(w.bolas || {}).filter(([k, o]) => o && o.vis !== 0 && !o.con && !o.flota && !/^pila/.test(k)).map(([k, o]) => [k, ballRows(w, o)]).filter(e => e[1]);
    for (let i = 0; i < free.length; i++) for (let j = i + 1; j < free.length; j++) { const S = new Set(); for (const [y, a, b] of free[i][1]) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0; for (const [y, a, b] of free[j][1]) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++;
      if (n) P.push('balls: ' + where + ' ' + free[i][0] + ' and ' + free[j][0] + ' overlap by ' + n + ' px'); }
  };
  for (const r of runs) { forRun(r); r.lines.forEach((L, li) => groundCheck(r.story.id + ' ' + r.plan + ' ' + L.path + ':', remapW(L.W), L.W)); }

  /* the bubbles: every bubble wholly inside the view, clear of the corner card, on no face */
  let nM = 0, nB = 0, worstView = 99, worstBoard = 99; const seen = new Set();
  const SUNR = [F.SUN[0] - F.SUN[2] - 2, F.SUN[1] - F.SUN[2] - 2, 2 * F.SUN[2] + 4, 2 * F.SUN[2] + 4]; let sunBoard = 99, sunCard = 99, nSunB = 0, nSunC = 0;
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } return bubRect(k, top[0], top[1]); };
  // each child's recorded bubble and "amor" (poke: anyone touched, at any moment); the frog's recorded one; Canelo's recorded one
  const bubblesOf = (w, view = VIEW) => {
    const out = [], boards = boardsOf(w, view[0]), faces = facesOf(w);
    for (const [id, p] of people(w)) { if (p.al != null && p.al < .5) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor');
      for (const k of ks) out.push([id + ' (' + Math.round(p.x) + ',' + Math.round(p.y) + ') "' + k + '"', talk(k, [Math.round(p.x), Math.round(p.y) - alto(id) - 1], view, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5)) { const b = frogBox(q); for (const k of new Set([q.bub].filter(Boolean))) out.push(['the frog (' + q.x + ',' + q.y + ') "' + k + '"', talk(k, [b.x + (b.w >> 1), b.y + 2], view, boards, faces, b.w >> 1)]); }
    if (dogShown(w) && w.perro.bub) { const o = w.perro; out.push(['perro (' + Math.round(o.x) + ',' + Math.round(o.y) + ') "' + o.bub + '"', talk(o.bub, [Math.round(o.x), Math.round(o.y) - 22], view, boards, faces, 8)]); }
    return out; };
  const judge = (where, rect, box, boards, faces) => {
    if (!within(rect, box)) { P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is not wholly inside ' + JSON.stringify(box)); return; }
    worstView = Math.min(worstView, rect[0] - box[0], box[0] + box[2] - rect[0] - rect[2], rect[1] - box[1], box[1] + box[3] - rect[1] - rect[3]);
    for (const [bn, b] of boards) { if (meets(rect, b)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is over ' + bn + ' ' + JSON.stringify(b)); else worstBoard = Math.min(worstBoard, gapTo(rect, b)); }
    for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is on ' + fn + ' ' + JSON.stringify(f));
  };
  for (const r of runs) { forRun(r); for (const L of r.lines) {
    if (JSON.stringify(L.cam) !== '[22,0,196,216]') P.push(r.story.id + ' ' + r.plan + ' ' + L.path + ': a view the sheet does not have ' + JSON.stringify(L.cam));
    const w = remapW(L.W), boards = boardsOf(w, x0), faces = facesOf(w); nM++;
    for (const [bn, b] of boards) if (meets(SUNR, b)) P.push('sun: ' + r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + bn + ' ' + JSON.stringify(b) + ' covers the sun (2 px to spare)'); else { sunBoard = Math.min(sunBoard, gapTo(SUNR, b) + 2); nSunB++; }
    for (const [who, rect] of bubblesOf(w)) { const key = JSON.stringify([who, rect, boards, faces]); if (seen.has(key)) continue; seen.add(key); nB++; judge(r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + who, rect, VIEW, boards, faces); }
  } }

  /* the asks: hint frames inside the view, no frame's rings across a face where the old ones had none, the hand on no face, the answer cards over no one */
  const cajaBox = (id, p) => [Math.round(p.x) - 11, Math.round(p.y) - alto(id), 22, alto(id)];
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) return old ? (t.old && t.old.box) : (t.hintBox || t.box);
    if (k === 'perro') return dogShown(w) ? [Math.round(w.perro.x) - 14, Math.round(w.perro.y) - 20, 28, 22] : null;
    if (k === 'cesta') return w.cesta ? [w.cesta[0] - 11, w.cesta[1] - 16, 22, 18] : null;
    if (/^bola_/.test(k)) { const o = (w.bolas || {})[k.slice(5)]; if (!o || o.vis === 0) return null; const p = ballXY(w, o), r = M.R[o.k]; return p ? [p[0] - r - 2, p[1] - p[2] - 2 * r - 2, 2 * r + 4, 2 * r + 4] : null; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? cajaBox(k, p) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand) return old && t.old && t.old.hand ? t.old.hand : t.hand; const b = boxOf(w, k, old); return b ? [Math.round(b[0] + b[2] / 2), Math.round(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [Math.round(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [Math.round(cx - 50), y, 40, 36] : [Math.round(cx + 10), y, 40, 36]; };
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99; const askSeen = new Set(), askedFor = new Set(), cardHand = new Set(), crossedOld = [], handOld = new Set();
  for (const r of runs) { const Ls = r.lines; forRun(r);
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const wo = Ls[j - 1].W, w = remapW(wo), st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      w.resp = null; let spot = null;
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); }
      else if (st.decide) { const ops = st.options.map(sb), bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || ops[0]; if (st.decide === 'say') w.resp = ops; else if (bur.length) w.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', key = JSON.stringify([spot, w.gente, w.cq, w.resp, w.perro, w.bolas, w.tarjeta]);
      if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), facesOld = facesOf(wo);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const fr2 = [c[0] - 12, c[1] - 12, c[2] + 24, c[3] + 24 + (w.respEn ? 0 : 4)]; if (meets(SUNR, fr2)) P.push('sun: ' + where + ' the card ' + k + ' with its frame ' + JSON.stringify(fr2) + ' covers the sun (2 px to spare)'); else { sunCard = Math.min(sunCard, gapTo(SUNR, fr2) + 2); nSunC++; } }
        { const f = [c[0] - 12 - 2, c[1] - 12 - 2, c[2] + 28, c[3] + 28 + (w.respEn ? 0 : 4)]; if (!within(f, VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow (+- 12) are not inside the view with 2 px to spare'); else cardSpare = Math.min(cardSpare, f[0] + 2 - x0, x0 + 196 - f[0] - f[2] + 2, f[1] + 2, 216 - f[1] - f[3] + 2); }
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c, bb)) P.push('cards: ' + where + ' the card ' + k + ' is over ' + bn);
        for (const [id, p] of people(w)) { const n = rowsMeet(personRows(id, p), c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + id); }
        if (dogShown(w)) { const n = rowsMeet(dogRows(w.perro), c); if (n) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of Canelo'); }
        { const f = frogBox(w.cq); if (w.cq.vis && meets(c, [f.x + 2, f.y + Math.round(w.cq.dy || 0) + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers the frog'); }
        for (const [bk, o] of Object.entries(w.bolas || {})) { if (!o || o.vis === 0) continue; const rs = ballRows(w, o); if (rs && rowsMeet(rs, c)) P.push('cards: ' + where + ' the card ' + k + ' covers the ball ' + bk); }
        { const n = (G.parts[KEY].arbol || []).filter(i => meets([i % 240, Math.floor(i / 240), 1, 1], c)).length; if (n) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of the tree'); } }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, VIEW)) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not wholly inside the view'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' ' + JSON.stringify(f) + ' (the old frame ' + JSON.stringify(bo) + ' did not)'); else crossedOld.push(where + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb && fn === 'the frog\'s face') { cardHand.add(spot); continue; }
        const ho = rb ? null : handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1]) && JSON.stringify(ho) === JSON.stringify(hp)) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
    }); }
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- ' + FRAME_OUT + ') wholly inside the view (' + worstF + ' px from its edge at the least), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.length ? ' (as the old: ' + [...new Set(crossedOld)].join('; ') + ')' : '') + ', the hint hand on no face' + (handOld.size ? ' (but as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow (+- 12) inside the view (' + cardSpare + ' px to spare at the least), over no one\'s body, no ball and not the tree');
  notes.push('sun: at ' + F.SUN.slice(0, 2) + ', radius ' + F.SUN[2] + ': under no corner card (' + nSunB + ' shown, ' + sunBoard + ' px to spare at the least) and under no answer card with its frame and glow (' + nSunC + ' cards, ' + sunCard + ' px to spare at the least), at every moment and ask of every run');
  if (cardHand.size) notes.push('NOT the scene\'s: the hand juego.js draws at an answer card reaches onto the frog\'s face in every scene where the cards are over him (respBox and hand() are the game\'s): at the asks for ' + [...cardHand].join(', '));
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments of ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + '), each its recorded one and anyone\'s "amor" when touched: wholly inside the view (' + worstView + ' px from its edge at the least), clear of the rounds card (' + (worstBoard === 99 ? 'no card shown with a bubble near' : worstBoard + ' px') + '), on no face');

  /* the tree: its crown where the old one was (the old 60, 100, 30 x 26), its fork's hollow dark, the trodden earth at its foot */
  { const leaves = G.parts[KEY].arbol, xs = leaves.map(i => i % 240), ys = leaves.map(i => Math.floor(i / 240)), bx = [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
    const c = OLD.COPA; if (Math.abs((bx[0] + bx[2]) / 2 - c[0]) > 4 || Math.abs(bx[1] - (c[1] - c[3])) > 4) P.push('tree: its crown ' + JSON.stringify(bx) + ' is not where the old one was');
    // the hollow: behind the ball in the fork (64, 152, z 33: rows 103 to 119) the set is darker than the rest of the crown (the old: a dark
    // ellipse in the green), so the ball reads as sitting in the tree
    const H = F.HOLLOW; let dark = 0, n = 0, crown = 0, nc = 0; for (const i of G.parts[KEY].arbol) { const x = i % 240, y = Math.floor(i / 240); if (y > OLD.COPA[1] + OLD.COPA[3]) continue; const L = lab(rgbAt(i))[0], dx = (x - H.cx) / H.rx, dy = (y - H.cy) / H.ry, q = dx * dx + dy * dy; if (q < 1) { dark += L; n++; } else if (q > 2) { crown += L; nc++; } }
    if (n && nc && dark / n > crown / nc - 4) P.push('tree: the hollow over the fork is not darker than the crown round it (' + Math.round(dark / n) + ' against ' + Math.round(crown / nc) + ')');
    notes.push('tree: its crown on the screen ' + JSON.stringify(bx) + ' (the old ' + JSON.stringify([c[0] - c[2], c[1] - c[3], c[0] + c[2], c[1] + c[3]]) + '), its trunk\'s foot at row ' + trunkFootRow + ' (the old ' + OLD.ARBOL[1] + '), the hollow over the fork darker than the crown round it (lightness ' + (n ? Math.round(dark / n) : '-') + ' against ' + (nc ? Math.round(crown / nc) : '-') + '); at least ' + stats.least + ' rows of lawn between anyone\'s feet and the trunk\'s foot behind them (' + stats.leastAt + ')'); }

  /* shadows in one piece with their things */
  { const pieces = [];
    for (const part of SOLID) { const own = new Set(G.parts[KEY][part]), sp = (G.shadowPx[KEY][part] || []).filter(i => OG[i] && !own.has(i)), all = new Set([...own, ...sp]), seenS = new Set(), stack = [];
      for (const i of own) { seenS.add(i); stack.push(i); }
      while (stack.length) { const i = stack.pop(), x = i % 240, y = Math.floor(i / 240); for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) { const j = (y + dy) * 240 + x + dx; if (x + dx < 0 || x + dx >= 240 || y + dy < 0 || y + dy >= 216 || seenS.has(j) || !all.has(j)) continue; seenS.add(j); stack.push(j); } }
      const lost = sp.filter(i => !seenS.has(i)).length; if (lost > 2) P.push('shadow: ' + lost + ' of the ' + sp.length + ' shadow px of ' + part + ' are not joined to it (a piece apart)');
      pieces.push(part + ' ' + sp.length + ' px'); }
    notes.push('shadows: each in one piece with its thing (' + pieces.join(', ') + ')'); }

  /* the sky: the sun in the upper left, whole inside the wide view, nothing of the set within 2 px of its disc; the clouds clear of it and the crown */
  { const reach = new Set(Object.values(G.leaf[KEY]).flat()), [sx, sy, sr] = F.SUN;
    const clear = (x0r, y0r, x1r, y1r) => { let n = 0; for (let y = Math.max(0, y0r); y <= Math.min(215, y1r); y++) for (let x = Math.max(0, x0r); x <= Math.min(239, x1r); x++) { const i = y * 240 + x; if (Z[i] > -1e8 || reach.has(i)) n++; } return n; };
    if (sx - sr - 1 < x0 || sx + sr + 1 > x0 + 196 || sy - sr - 1 < 0) P.push('sun: its disc is not whole inside the view');
    if (sx > 120) P.push('sun: not in the upper left');
    { const n = clear(Math.floor(sx - sr - 2), Math.floor(sy - sr - 2), Math.ceil(sx + sr + 2), Math.ceil(sy + sr + 2)); if (n) P.push('sun: ' + n + ' px of the set within 2 px of its disc'); }
    for (const [cx, cy, s2] of F.CLOUDS) { const b = [Math.floor(cx - 17 * s2 - 2), Math.floor(cy - 5 * s2 - 2), Math.ceil(cx + 19 * s2 + 2), Math.ceil(cy + 6 * s2 + 2)];
      const n = clear(...b); if (n) P.push('cloud at ' + cx + ',' + cy + ': ' + n + ' px of the set within 2 px');
      if (b[2] >= sx - sr && b[0] <= sx + sr && b[3] >= sy - sr && b[1] <= sy + sr) P.push('cloud at ' + cx + ',' + cy + ': on the sun');
      if (b[2] >= x0 + BOARD[0] && b[0] <= x0 + BOARD[0] + BOARD[2] && b[1] <= BOARD[1] + BOARD[3]) P.push('cloud at ' + cx + ',' + cy + ': under the rounds card'); }
    notes.push('sky: the sun at ' + F.SUN.slice(0, 2) + ' (radius ' + sr + '), left of the middle, whole in the view, nothing of the set within 2 px; the old picture\'s three clouds at ' + F.CLOUDS.map(c => c.slice(0, 2).join(',')).join('; ') + ' (the old 36,16; 112,9; 168,26), each clear of the sun, the crown and the corner card by 2 px'); }

  notes.push('ground: ' + stats.stand + ' distinct stands of the children, the frog, Canelo and the basket: nothing of the tree nearer than them inside their sprites; behind reeds (front.juncos draws them over): ' + (behind.size ? [...behind.entries()].map(([k, n]) => k + ' (' + n + ' px)').join(', ') : 'no one') + '; in the water or the reeds, each where the old picture had them by the pond: ' + (wade.size ? [...wade.keys()].join(', ') : 'no one'));
  notes.push('balls: ' + stats.balls + ' distinct balls at every moment and in every pair: on the ground with lawn (or the trodden earth) round them (' + Math.round(stats.grassRing * 100) + '% of the ring at the least), at the water\'s edge on the land where the old picture had them on its pond\'s rim (' + ([...edge].join(', ') || '-') + '), in the air with their shadow point on the land (' + stats.air + '), floating with water all round (' + Math.round(stats.float * 100) + '% at the least) and no reed over them, in the reeds partly hidden and at least half seen (' + ([...ballSeen.entries()].map(([k, v]) => k + ' ' + v + '% seen').join(', ') || '-') + '), in the tree with the crown behind them (' + Math.round(stats.tree[0] * 100) + '% at the least) and standing out from it (' + Math.round(stats.tree[1]) + ' at the least, CIE76); no two loose balls overlap (Canelo\'s pile and the balls floating on the lake, as the old, not counted: the stories never ask for them)');

  /* round 2, the shore: at every tick inside every act (G.TICKS) and at every step's end. Whatever rests at the shore (a ball, Canelo, the frog,
     a child, the basket) is clearly on one side: on the land with at least SHORE_M px of lawn between its foot and the lip of the bank, or in the
     water with water all round its foot (and its ripple ring: helps.ring). Whatever floats or wades has its ring on the water. Every ball in
     flight has its shadow on the ground under it (a ground pixel of the set, no trunk or reed over it) */
  const SV = G.shoreV[KEY], LIP = .07, SHORE_M = sh.helps.margin;
  const zoneAt = (x, y) => { if (x < 0 || x >= 240 || y < 0 || y >= 216) return 'out'; const i = y * 240 + x, v = SV[i]; return v > LIP ? 'lawn' : v >= 0 ? 'lip' : K[i] === G.K.water ? 'water' : 'bank'; };
  const nearShore = (x, y) => { for (let dy = -10; dy <= 10; dy += 2) for (let dx = -10; dx <= 10; dx += 2) { const z = zoneAt(x + dx, y + dy); if (z !== 'lawn' && z !== 'out') return true; } return false; };
  const footOf = rs => { const last = Math.max(...rs.map(r => r[0])); return rs.filter(r => r[0] >= last - 1); };
  const sideOf = (foot, m) => { let land = true, water = true;
    for (const [y, a, b] of foot) for (let x = a - m; x <= b + m; x++) for (let dy = -m; dy <= m; dy++) { const z = zoneAt(x, y + dy); if (z === 'out') continue; if (z !== 'lawn') land = false; }
    for (const [y, a, b] of foot) for (let x = a - 2; x <= b + 2; x++) for (let dy = -2; dy <= 2; dy++) { const z = zoneAt(x, y + dy); if (z === 'out') continue; if (z !== 'water') water = false; }
    return land ? 'land' : water ? 'water' : 'across'; };
  const ringPx = (cx, cy, rx, ry) => { const out = []; for (let y = Math.floor(cy - ry - 1); y <= Math.ceil(cy + ry + 1); y++) for (let x = Math.floor(cx - rx - 1); x <= Math.ceil(cx + rx + 1); x++) { const d = ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2; if (d > sh.helps.ring.inner && d <= 1) out.push([x, y]); } return out; };
  const RG = sh.helps.ring, REST_MS = 300, restBalls = new Set();
  const overWater = (x, y) => { const z = zoneAt(Math.round(x), Math.round(y)); return z === 'water' || z === 'bank'; };
  { let nT = 0, nRest = 0, nFly = 0, nRing = 0, worstRing = 1; const ballOver = new Map(), poses = new Map(), across = new Map(), sides = new Map(), flyBad = new Map(), ringBad = new Map();
    const overlapAt = (w, o) => { const rs = ballRows(w, o); if (!rs) return 0; const S = new Set(); for (const [y, a, b] of rs) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0;
      const cnt = r2s => { for (const [y, a, b] of r2s) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++; }; if (dogShown(w) && o.con !== 'perro') cnt(dogRows(w.perro)); for (const [id, pp] of people(w)) if (o.con !== id) cnt(personRows(id, pp)); return n; };
    const look = (where, w, prev, w0) => {
      const items = [];
      for (const [k, o] of Object.entries(w.bolas || {})) { if (!o || o.vis === 0 || o.con) continue; const p = ballXY(w, o); if (!p) continue; items.push({ id: 'bola ' + k, kind: 'ball', o, p, rs: ballRows(w, o) }); }
      if (dogShown(w)) items.push({ id: 'perro', kind: 'dog', pose: w.perro.pose, dir: w.perro.dir, p: [Math.round(w.perro.x), Math.round(w.perro.y), Math.round(w.perro.dy || 0)], rs: dogRows(w.perro) });
      for (const [id, pp] of people(w)) items.push({ id, kind: 'person', p: [Math.round(pp.x), Math.round(pp.y), Math.round(pp.dy || 0)], rs: personRows(id, pp) });
      if (w.cq && w.cq.vis) { const b = frogBox(w.cq), rs = []; for (let y = b.y; y < b.y + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]); items.push({ id: 'the frog', kind: 'frog', p: [w.cq.x, w.cq.y, Math.round(-(w.cq.dy || 0))], rs }); }
      if (w.cesta) items.push({ id: 'the basket', kind: 'basket', p: [w.cesta[0], w.cesta[1], 0], rs: rowsAt(M.cesta, w.cesta[0], w.cesta[1]) });
      for (const it of items) {
        const resting = prev === null || (prev && prev[it.id + '@' + it.p.join(',')] >= REST_MS);
        if (it.kind === 'ball' && it.p[2] > 3 && !inTree(it.o, it.p) && !it.o.flota) { nFly++;   // in flight: its shadow on the ground under it
          const x = it.p[0], y = it.p[1] - 1, i = y * 240 + x; if (!(x >= 0 && x < 240 && y >= 0 && y < 216)) continue;
          { let n = 0, ok = 0; for (let dy = -2; dy <= 2; dy++) for (let dx = -4; dx <= 4; dx++) { const j = (y + dy) * 240 + x + dx; if (y + dy < 0 || y + dy >= 216 || x + dx < 0 || x + dx >= 240) continue; n++; if (OG[j] && !TAG[j]) ok++; }
            if (ok < n * .3) { const kk = it.id + ' at ' + it.p; flyBad.set(kk, where); } }
          continue; }
        if (it.kind === 'ball' && inTree(it.o, it.p)) continue;
        if (it.p[2] > 3) continue;   // a jump: in the air over the ground
        const wet = it.kind === 'ball' ? (it.o.flota || overWater(it.p[0], it.p[1] - 1)) : it.kind === 'dog' ? overWater(it.p[0], it.p[1] - 1) : false;
        if (wet) { nRing++; const r = it.kind === 'ball' ? M.R[it.o.k] : 0, cy = it.p[1] + (it.kind === 'dog' ? RG.dog.dy : 0), rp = ringPx(it.p[0], cy, it.kind === 'dog' ? RG.dog.rx : r + RG.ball.rx, it.kind === 'dog' ? RG.dog.ry : RG.ball.ry), on = rp.filter(([x, y]) => zoneAt(x, y) === 'water').length / rp.length;
          if (resting) { worstRing = Math.min(worstRing, on); if (on < .9) ringBad.set(it.id + ' at ' + it.p.slice(0, 2), Math.round(on * 100) + '% of its ring on the water, ' + where); } }
        if (resting && it.kind === 'ball' && !wet && it.p[2] <= 3) restBalls.add(it.o.k + ',' + it.p[0] + ',' + it.p[1]);
        if (resting && it.kind === 'ball' && w0) { const k0 = it.id.slice(5), o0 = (w0.bolas || {})[k0], n = overlapAt(w, it.o), n0 = o0 ? overlapAt(w0, o0) : 0; if (n > n0) ballOver.set(it.id + ' at ' + it.p.slice(0, 2), n + ' px over Canelo or a child (the old: ' + n0 + '), ' + where); }
        if (!resting || !nearShore(it.p[0], it.p[1])) continue;
        nRest++; const side = sideOf(footOf(it.rs), SHORE_M), kk = it.id + ' at ' + it.p.slice(0, 2);
        sides.set(kk, side);
        if (side === 'across') { across.set(kk, where); poses.set(kk, [it.pose, it.dir]); }
        if (side === 'land' && wet) across.set(kk + ' (drawn as in the water)', where);
        if (side === 'water' && !wet) across.set(kk + ' (in the water, drawn with no ring)', where);
      } };
    // a thing rests where it stays REST_MS or more (from the first tick it is there to the first tick it is not); every step's end is a rest
    const posOf = w => { const o = {};
      for (const [k, b] of Object.entries(w.bolas || {})) if (b && !b.con && b.vis !== 0) { const p = ballXY(w, b); if (p) o['bola ' + k] = p; }
      if (dogShown(w)) o.perro = [Math.round(w.perro.x), Math.round(w.perro.y), Math.round(w.perro.dy || 0)];
      for (const [id, pp] of people(w)) o[id] = [Math.round(pp.x), Math.round(pp.y), Math.round(pp.dy || 0)];
      if (w.cq && w.cq.vis) o['the frog'] = [w.cq.x, w.cq.y, Math.round(-(w.cq.dy || 0))];
      if (w.cesta) o['the basket'] = [w.cesta[0], w.cesta[1], 0];
      return o; };
    runs.forEach((r, ri) => { forRun(r); const T = G.TICKS[ri], Ws = T.map(tk => remapW(tk.W)), P0 = Ws.map(posOf), dwell = P0.map(() => ({}));
      for (let i = 0; i < T.length; i++) for (const [id, p] of Object.entries(P0[i])) { const key = id + '@' + p.join(','); if (i > 0 && P0[i - 1][id] && P0[i - 1][id].join(',') === p.join(',')) { dwell[i][key] = dwell[i - 1][key]; continue; }
        let j = i; while (j + 1 < T.length && P0[j + 1][id] && P0[j + 1][id].join(',') === p.join(',')) j++; dwell[i][key] = (j + 1 < T.length ? T[j + 1].t : T[j].t + REST_MS) - T[i].t; }
      for (let i = 0; i < T.length; i++) { nT++; look(r.story.id + ' ' + r.plan + ' t ' + T[i].t, Ws[i], dwell[i], T[i].W); }
      for (const L of r.lines) look(r.story.id + ' ' + r.plan + ' ' + L.path, remapW(L.W), null, L.W); });
    MV = MVall.filter(q => q.act === '*'); RM = RMall.filter(q => q.files.includes('cual-campo')); EN = null;
    for (const ps of pairSides) look('pair ' + deacc(ps.w) + '.' + ps.side, remapW(Object.assign({ gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, bolas: {} }, JSON.parse(JSON.stringify(ps.spec.set || {})))), null);
    for (const [k, where] of across) P.push('shore: ' + k + ' rests across the lip of the bank (' + where + ')');
    if (process.env.CAMPO_SUGGEST) for (const k of across.keys()) { const m = k.match(/^(.*) at (-?\d+),(-?\d+)/); if (!m) continue; const id = m[1], x = +m[2], y = +m[3], best = {};
      for (let d = 1; d <= 24; d++) for (let dy = -d; dy <= d; dy++) for (let dx = -d; dx <= d; dx++) { if (Math.max(Math.abs(dx), Math.abs(dy)) !== d) continue;
        let rs; if (/^bola/.test(id)) { const kk = id.split(' ')[1], o = { k: /luis/.test(kk) ? 'L' : /carmen/.test(kk) ? 'C' : 'q', x: x + dx, y: y + dy, z: 0 }; rs = ballRows({}, o); }
        else if (id === 'perro') rs = dogRows({ x: x + dx, y: y + dy, pose: (poses.get(k) || [])[0] || 'sit', dir: (poses.get(k) || [])[1] || 1 }); else if (id === 'the frog') { const b = frogBox({ x: x + dx, y: y + dy, s: 1 }); rs = []; for (let yy = b.y; yy < b.y + b.h; yy++) rs.push([yy, b.x + 2, b.x + b.w - 3]); } else rs = personRows(id, { x: x + dx, y: y + dy, pose: 'idle', dir: 1 });
        const sd = sideOf(footOf(rs), SHORE_M); if (sd !== 'across' && !best[sd]) best[sd] = [x + dx, y + dy, d]; }
      console.log('SUGGEST ' + k + ' ' + JSON.stringify(poses.get(k)) + ' -> ' + JSON.stringify(best)); }
    for (const [k, why] of ballOver) P.push('ball: ' + k + ' rests ' + why);
    for (const [k, where] of flyBad) P.push('flight: the ball ' + k + ' has no ground under it for its shadow (' + where + ')');
    for (const [k, why] of ringBad) P.push('ring: ' + k + ': ' + why);
    const land = [...sides].filter(e => e[1] === 'land').map(e => e[0]), water = [...sides].filter(e => e[1] === 'water').map(e => e[0]);
    notes.push('shore (round 2): ' + nT + ' ticks inside the acts of the ' + runs.length + ' runs (every timer of the old page, played as the recorded runs), every step\'s end and every pair picture: ' + nRest + ' rests near the shore (' + REST_MS + ' ms or more in one place, or a step\'s end), each clearly on one side (on the land with ' + SHORE_M + ' px of lawn at least round its foot: ' + land.join(', ') + '; in the water with water all round and its ring: ' + water.join(', ') + '); ' + nRing + ' moments of something floating or wading, each with its ring (resting ones ' + Math.round(worstRing * 100) + '% on the water at the least); ' + nFly + ' ticks of a ball in flight, each with its shadow on the ground under it (at least 30% of the 9 x 5 px round its point is ground that shows: no trunk or reed over it)'); }

  /* round 2, the tree's shadow (point 2): the crown's shadow is cast at a reduced strength (castShadowCover: only the share CROWN_SHADE of its
     pixels, by the Bayer threshold, takes the engine's shadow tint), so that the things the stories are about stand out from the shaded lawn
     about as well as from the lit lawn (CIE76 between each thing's mean colour and the lawn's mean colour, in the shade and in the light: at
     least SHADE_K of it); the trunk's own shadow stays whole */
  const SHADE_K = .8;
  const crownCall = G.shadows[KEY].filter(c => c.part === 'arbol').sort((a, b) => b.args[3] - a.args[3])[0];
  const crownRegion = (() => { const [x, y, z, r] = crownCall.args, p = E.project(x + .9 * z, y - .1 * z, 0), rx = r * E.S * 1.05, ry = rx * .5 + 1, out = [];
    for (let iy = Math.floor(p.sy - ry); iy <= Math.ceil(p.sy + ry); iy++) for (let ix = Math.floor(p.sx - rx); ix <= Math.ceil(p.sx + rx); ix++) { const dx = (ix + .5 - p.sx) / rx, dy = (iy + .5 - p.sy) / ry; if (dx * dx + dy * dy <= .8) out.push(iy * 240 + ix); } return out; })();
  { const inR = new Set(crownRegion), meanOfPx = l => [0, 1, 2].map(c => l.reduce((t, i) => t + RGB[i * 3 + c], 0) / l.length);
    const shaded = crownRegion.filter(i => K[i] === G.K.grass && !TAG[i]), litL = []; for (let i = 120 * 240; i < 240 * 216; i++) if (K[i] === G.K.grass && !SH[i] && !inR.has(i) && !TAG[i]) litL.push(i);
    const ms = meanOfPx(shaded), ml = meanOfPx(litL), res = [];
    const NM = { L: 'Luis\'s ball', C: 'Carmen\'s ball', q: 'the frog\'s ball', flor: 'the flower', perro: 'Canelo', frog: 'the frog', pelo_luis: 'Luis\'s dark hair', pelo_carmen: 'Carmen\'s dark hair' };
    for (const [k, nm] of Object.entries(NM)) { const a = dE(M.colours[k], ml), b = dE(M.colours[k], ms); res.push(nm + ' ' + Math.round(a) + ' / ' + Math.round(b));
      if (b < SHADE_K * a) P.push('shade: ' + nm + ' stands out from the shaded lawn by ' + Math.round(b) + ', from the lit lawn by ' + Math.round(a) + ' (keep ' + SHADE_K + ' of it)'); }
    notes.push('shade (round 2, point 2): the crown\'s shadow at a reduced strength: the engine\'s shadow tint on ' + Math.round(F.CROWN_SHADE * 100) + '% of its pixels (Bayer, castShadowCover), the trunk\'s shadow whole; the lit lawn ' + ml.map(Math.round) + ', the shaded lawn (mean over the crown\'s shadow) ' + ms.map(Math.round) + '; each thing against the lit / the shaded lawn (CIE76; keep ' + SHADE_K + '): ' + res.join(', ')); }

  /* round 2, point 5: a ball on the lawn stands out from the lawn where it lies, by 38 at least: the ball's mean colour against the mean of the
     3 px band round it as the picture shows it (the lawn, lit or shaded, the shadow the engine casts under the ball, its contact rim: helps.contact),
     at every place a ball rests on the land in every run and pair (G.TICKS, the steps' ends, the pictures) */
  const BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map(v => (v + .5) / 16), bay = (x, y) => BAYER[(y & 3) * 4 + (x & 3)];
  const bandOf = (k, x, y, help) => { const px = new Map(), get = (ix, iy) => { const i = iy * 240 + ix; if (!px.has(i)) px.set(i, [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]]); return px.get(i); };
    const g = E.atZ(x, y - 1, 0), R = sh.shadows.bola.radius[k], p = E.project(g[0] + .045, g[1] - .005, 0), rx = R * E.S * 1.05, ry = rx * .5 + 1;
    for (let iy = Math.floor(p.sy - ry); iy <= Math.ceil(p.sy + ry); iy++) for (let ix = Math.floor(p.sx - rx); ix <= Math.ceil(p.sx + rx); ix++) { const dx = (ix + .5 - p.sx) / rx, dy = (iy + .5 - p.sy) / ry;
      if (dx * dx + dy * dy + (bay(ix, iy) - .5) * .4 > 1 || !OG[iy * 240 + ix]) continue; const c = get(ix, iy); px.set(iy * 240 + ix, [c[0] * .54, c[1] * .52, c[2] * .72]); }
    const r = M.R[k], C = sh.helps.contact;
    const ball = new Set(M.ballPx[k].map(([dy, dx]) => (y + dy) * 240 + x + dx)), band = [];
    if (help) for (const i of ball) { const bx = i % 240, by = Math.floor(i / 240); for (let dy = -C.halo; dy <= C.halo; dy++) for (let dx = -C.halo; dx <= C.halo; dx++) { const j = (by + dy) * 240 + bx + dx; if (!ball.has(j)) px.set(j, C.colour.slice()); } }
    for (const i of ball) { const bx = i % 240, by = Math.floor(i / 240); for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) { const j = (by + dy) * 240 + bx + dx; if (!ball.has(j) && !band.includes(j)) band.push(j); } }
    const bm = [0, 1, 2].map(c => band.reduce((t, j) => t + get(j % 240, Math.floor(j / 240))[c], 0) / band.length), bmean = [0, 1, 2].map(c => M.ballPx[k].reduce((t, q) => t + q[2 + c], 0) / M.ballPx[k].length);
    return dE(bmean, bm); };
  { const inR = new Set(crownRegion), worst = {}, worstNo = {}; let n = 0;
    MV = MVall.filter(q => q.act === '*'); RM = RMall.filter(q => q.files.includes('cual-campo')); EN = null;
    for (const ps of pairSides) { const w = remapW(Object.assign({ gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, bolas: {} }, JSON.parse(JSON.stringify(ps.spec.set || {}))));
      for (const o of Object.values(w.bolas || {})) { if (o.con || o.flota) continue; const p = ballXY(w, o); if (p && p[2] <= 3 && !overWater(p[0], p[1] - 1)) restBalls.add(o.k + ',' + p[0] + ',' + p[1]); } }
    for (const e of restBalls) { const [k, xs, ys] = e.split(','), x = +xs, y = +ys; n++; const shd = inR.has((y - 1) * 240 + x) ? 'shaded' : 'lit';
      const d = bandOf(k, x, y, sh.helps.contact.balls.includes(k)), d0 = bandOf(k, x, y, false), key = k + ' ' + shd;
      if (!worst[key] || d < worst[key][0]) worst[key] = [Math.round(d), x + ',' + y]; if (!worstNo[key] || d0 < worstNo[key][0]) worstNo[key] = [Math.round(d0), x + ',' + y];
      if (d < 38) P.push('ball: ' + k + ' at ' + x + ',' + y + ' (' + shd + ' lawn) stands out from the lawn round it by ' + Math.round(d) + ' (keep 38)'); }
    for (const k of sh.helps.contact.balls) { const need = ['lit', 'shaded'].some(s2 => worstNo[k + ' ' + s2] && worstNo[k + ' ' + s2][0] < 38); if (!need) P.push('ball: ' + k + ' has the contact rim but needs none (' + JSON.stringify([worstNo[k + ' lit'], worstNo[k + ' shaded']]) + ')'); }
    notes.push('balls on the lawn (round 2, point 5): at ' + n + ' places where a ball rests on the land, the ball against the 3 px band round it as drawn (lawn, the engine\'s shadow under it, its rim; CIE76, keep 38), the least, with the help / without: ' + Object.keys(worst).sort().map(key => key + ' ' + worst[key][0] + ' / ' + worstNo[key][0] + ' (at ' + worst[key][1] + ')').join(', ') + '; the contact rim drawn for ' + sh.helps.contact.balls.join(', ') + ' (the old: the frog\'s ball against the old lawn ' + Math.round(dE(M.colours.q, M.oldLawn)) + ')'); }

  /* round 2: the water lighter and bluer than round 1's, a measured distance from every sky tone (above: water) */
  { const r1 = lab([50, 103, 127]); let n = 0, s3 = [0, 0, 0]; for (let i = 0; i < 240 * 216; i++) if (K[i] === G.K.water && i % 240 >= x0 && i % 240 < x0 + 196) { n++; for (let c = 0; c < 3; c++) s3[c] += RGB[i * 3 + c]; }
    const m = s3.map(v => v / n), L = lab(m); if (!(L[0] > r1[0] + 5 && L[2] < r1[2] - 3)) P.push('water: not lighter and bluer than round 1 (' + L.map(Math.round) + ' against ' + r1.map(Math.round) + ')');
    notes.push('water (round 2, point 1): lighter and bluer than round 1 (CIE L*a*b* ' + L.map(Math.round) + ', round 1 ' + r1.map(Math.round) + '); against it (CIE76): the bank\'s lip ' + Math.round(dE(m, [150, 118, 76])) + ', the frog\'s ball ' + Math.round(dE(m, M.colours.q)) + ', Luis\'s ' + Math.round(dE(m, M.colours.L)) + ', Canelo ' + Math.round(dE(m, M.colours.perro))); }

  /* the review pictures (and the level pictures, the same pictures): everyone whole in their crop, every bubble inside, on the ground; what differs */
  let nPic = 0; const pairDiff = [], zoom2 = [];
  const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
  for (const [word, sides] of Object.entries(byWord)) {
    const ws = {};
    for (const side of Object.keys(sides)) {
      const spec = sides[side].spec, base = { gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, bolas: {} };
      MV = MVall.filter(q => q.act === '*'); RM = RMall.filter(q => q.files.includes('cual-campo')); EN = null;
      const w = remapW(Object.assign(base, JSON.parse(JSON.stringify(spec.set || {})))), nm = deacc(word) + '.' + side, pc = sh.pictures[nm]; ws[side] = w; nPic++;
      const crop = pc.crop, oc = spec.cam, ocr = [Math.floor(oc[0]), Math.floor(oc[1]), Math.ceil(oc[2]), Math.ceil(oc[3])], who = people(w).map(([id, p]) => [id, rowsBox(personRows(id, p))]);
      if (w.cq.vis) { const b = frogBox(w.cq); who.push(['the frog', [b.x, b.y, b.w, b.h]]); }
      if (dogShown(w)) who.push(['perro', rowsBox(dogRows(w.perro))]);
      for (const [k, o] of Object.entries(w.bolas || {})) { const rs = ballRows(w, o); if (rs) who.push(['the ball ' + k, rowsBox(rs)]); }
      if (w.flor) who.push(['the flower', rowsBox(rowsAt(M.flor, w.flor[0], w.flor[1]))]);
      for (const [id, b] of who) { const cut = !within(b, crop), oldCut = !within(b, ocr);
        if (cut && !oldCut) P.push('pair ' + nm + ': ' + id + ' ' + JSON.stringify(b) + ' is cut by the picture ' + JSON.stringify(crop)); }
      for (const [who2, rect] of bubblesOf(w, crop).filter(e => !/"amor"/.test(e[0]))) if (!within(rect, crop)) P.push('pair ' + nm + ': ' + who2 + ' bubble is cut');
      // round 2: Canelo whole with 2 px to spare; every ball's shadow (or contact rim) inside the picture
      if (dogShown(w)) { const b = rowsBox(dogRows(w.perro)); if (!within([b[0] - 2, b[1] - 2, b[2] + 4, b[3] + 4], crop)) P.push('pair ' + nm + ': Canelo ' + JSON.stringify(b) + ' not whole with 2 px to spare in ' + JSON.stringify(crop)); }
      for (const [k, o] of Object.entries(w.bolas || {})) { if (o.con) continue; const p = ballXY(w, o); if (p && !inTree(o, p) && !within([p[0] - 4, p[1] - 3, 8, 6], crop)) P.push('pair ' + nm + ': the ball ' + k + '\'s shadow at ' + p.slice(0, 2) + ' is not inside the picture'); }
      // round 2: a zoom 2 picture shows none of the tree's shadow, unless the trunk is in it
      if (pc.zoom === 2) { const trunk = G.parts[KEY].arbol.some(i => Math.floor(i / 240) > OLD.COPA[1] + OLD.COPA[3] && within([i % 240, Math.floor(i / 240), 1, 1], crop)), shd = (G.shadowPx[KEY].arbol || []).filter(i => OG[i] && within([i % 240, Math.floor(i / 240), 1, 1], crop)).length;
        if (shd && !trunk) P.push('pair ' + nm + ': shows ' + shd + ' px of the tree\'s shadow and not its trunk'); zoom2.push(nm + (shd ? ' (' + shd + ' px of shadow, with the trunk)' : '')); }
      groundCheck('pair ' + nm + ':', w, null);
    }
    if (!ws.si || !ws.no) continue;
    if (JSON.stringify(ws.si) === JSON.stringify(ws.no) && JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) === JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) P.push('pair ' + word + ': the two pictures are the same');
    const diff = []; const ids = new Set([...Object.keys(ws.si.gente || {}), ...Object.keys(ws.no.gente || {})]);
    for (const id of ids) { const x = (ws.si.gente || {})[id], y = (ws.no.gente || {})[id]; if (JSON.stringify(x) !== JSON.stringify(y)) diff.push(id + (!x ? ' only in no' : !y ? ' only in si' : ' ' + Object.keys(Object.assign({}, x, y)).filter(k => JSON.stringify(x[k]) !== JSON.stringify(y[k])).join('/'))); }
    for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (k !== 'gente' && JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k + (ws.si[k] && ws.no[k] && typeof ws.si[k] === 'object' && !Array.isArray(ws.si[k]) ? ' ' + Object.keys(Object.assign({}, ws.si[k], ws.no[k])).filter(q => JSON.stringify(ws.si[k][q]) !== JSON.stringify(ws.no[k][q])).join('/') : ''));
    if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
    pairDiff.push(deacc(word) + ': ' + diff.join(', '));
  }
  notes.push('pairs, what differs: ' + pairDiff.join('; '));
  notes.push('pairs (round 2): the zoom 2 pictures show none of the tree\'s shadow without its trunk: ' + zoom2.join(', ') + '; in each picture Canelo whole with 2 px to spare and every ball\'s shadow inside it');
  notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures): everyone, the frog, Canelo, the balls and the flower whole in their crop (no zoom 2 crop cuts what the old window did not), on clear ground');

  /* the lawn is green; the sprite layer's things stand out from it */
  { let n = 0, m = [0, 0, 0]; for (let y = 120; y < 216; y++) for (let x = 0; x < 240; x++) { const i = y * 240 + x; if (K[i] !== G.K.grass) continue; n++; const c = rgbAt(i); for (let k = 0; k < 3; k++) m[k] += c[k]; }
    m = m.map(v => v / n);
    const hue = Math.round(60 * (2 + (m[2] - m[0]) / (m[1] - Math.min(m[0], m[2]))));
    if (!(m[1] > m[0] && m[1] > m[2] && hue >= 65)) P.push('lawn: its mean colour ' + m.map(Math.round) + ' (hue ' + hue + ') is not green');
    const d = k => Math.round(dE(M.colours[k], m)), dOld = k => Math.round(dE(M.colours[k], M.oldLawn)), ks = ['L', 'C', 'q', 'perro', 'cesta', 'flor'], NM = { L: 'Luis\'s ball', C: 'Carmen\'s ball', q: 'the frog\'s ball', perro: 'Canelo', cesta: 'the basket', flor: 'the flower\'s petals' };
    // a thing of the sprite layer stands out from the lawn by its colour (CIE76 between its mean colour and the lawn's) by 25 at the least, each
    // also with its dark outline and the shadow the engine casts under it (the old lawn was a brighter green: the old numbers are given)
    for (const k of ks) if (d(k) < 25) P.push('lawn: ' + NM[k] + ' stands out from it by only ' + d(k) + ' (the old: ' + dOld(k) + ')');
    notes.push('lawn: El frente\'s grass (GRASS), mean colour ' + m.map(Math.round) + ' (hue ' + hue + '; the old lawn ' + M.oldLawn.map(Math.round) + '); the sprite layer\'s things on it, by their mean colour against it (CIE76; keep 25), each with its dark outline and its cast shadow: ' + ks.map(k => NM[k] + ' ' + d(k) + ' (the old ' + dOld(k) + ')').join(', ') + '. The frog\'s small yellow ball is the nearest to the olive lawn: it keeps its dark outline and its shadow (no help needed: El patio\'s flowerLeaves rule; a reader to judge)'); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSides) reached.add(keyOf(ps.spec.set || {}));
    for (const k of STATES) if (!reached.has(k)) P.push('state ' + k + ' is baked but nothing reaches it');
    notes.push('states: ' + reached.size + ' baked state reached (every moment, pair and level picture)');
    console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome: the first ' + Math.round(G.ms.first || 0) + ' ms, again ' + Math.round(G.ms.warm || 0) + ' ms (the ground cached)'); }
  return P;
}
