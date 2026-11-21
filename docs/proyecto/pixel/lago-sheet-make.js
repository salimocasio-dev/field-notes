#!/usr/bin/env node
'use strict';
/* El lago's sheet (order 35a): writes docs/proyecto/pixel/lago-sheet.json from lago-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/lago-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.LAGO_SET), its part map, its depth, its walkable surfaces and every castShadow call from lago-set.html in
   headless Chrome; measures the old sprite layer's bubbles, people, dog, ducks, birds, boats, fish, bread, bag, sack and flower (historia/
   engine.js, juego.js, kit.js and escenas/lago.js's own sprite makers, as they are); projects every world point with the engine's own formula;
   checks the sheet against coqui/ref/escenas/lago/ (positions.json, inventory.json, pairs.json); against every moment of every recorded run of
   the scene's stories (coqui/tool/ref/trazas/juega.mjs --states, into a temp folder: the steps' ends); and against every tick inside the acts:
   the old page played by the same machine (page-init.js, page-drive.js: the same seed, think time and clock) with lago.js as the port will have
   it (the sheet's moves applied) and the story files' positions through the sheet's remap, the scene's W kept after every timer. It loads
   lago-preview.html (over a local http server it starts and stops) to check that the preview puts everyone where the sheet does, at every
   moment. Nothing in the repo is written but the sheet. A second run writes the same bytes. El campo's maker (campo-sheet-make.js) is the
   model: the same rules, the same way of checking, the same way of naming the ask pictures.
   LAGO_NOCHECK=1: write the sheet only (for designing). LAGO_DUMP=<folder>: also write each run's step ends, the recorded and the port's, there. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'lago-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/lago');
// the baked states: one. Every state a story, a review pair or a level picture reaches is this one (checked)
const STATES = ['lago'];
const keyOf = w => 'lago';
const queryOf = k => '';
const SOLID = ['muelle', 'muelle.postes', 'poste', 'juncos'];   // what stands in the picture (the set's parts)
const THING_OF = p => p.split('.')[0];                          // a part's touch key (the mooring posts are the dock's)

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, kinds: {}, rgb: {}, leaf: {}, shadows: {} };
  for (const key of STATES) {
    await page.goto('file://' + path.join(__dirname, 'lago-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(LAGO_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      const leaf = {};   // no part of this set has swaying leaves
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgbA = []; for (let i = 0; i < W * H; i++) rgbA.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = [], shadowPx = {}; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const saved = shadowMask.slice(); shadowMask.fill(0); cs0(x, y, z, r, strength, dither); let n = 0; const S = shadowPx[cur] = shadowPx[cur] || new Set();
        for (let i = 0; i < W * H; i++) { if (shadowMask[i]) { n++; S.add(i); } if (saved[i] > shadowMask[i]) shadowMask[i] = saved[i]; }
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; GROUND_CACHE = null; const t0 = performance.now(); buildSet(); const first = performance.now() - t0;
      const t1 = performance.now(); buildSet(); const warm = performance.now() - t1;
      castShadow = cs0; part = part0;
      // which of the baked pixels takes a cast shadow (ground and its own depth), and what each pixel's walkable surface is
      const onGround = [], shade = Array.from(staticShadow), surf = [], wet = []; for (let i = 0; i < W * H; i++) {
        onGround.push(ground[i] && bakedZ[i] === groundZ[i] ? 1 : 0);
        const ix = i % W, iy = Math.floor(i / W), s = LAGO_SET.surfaceAt(ix + .5, iy + .5);
        surf.push(iy + .5 < LAGO_SET.HZ ? 's' : s.on === 'dock' ? 'd' : s.on === 'lawn' ? (kinds[i] === KIND_ROAD && bakedZ[i] === groundZ[i] ? 'p' : 'l') : kinds[i] === KIND_WATER ? 'w' : 'b');
        const g = unproject(ix + .5, iy + .5); wet.push(iy + .5 >= LAGO_SET.HZ && LAGO_SET.shore(g.x, g.y) < 0 ? 1 : 0); }
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(bakedZ), kinds: Array.from(kinds), K: { road: KIND_ROAD, grass: KIND_GRASS, water: KIND_WATER, none: KIND_NONE }, rgb: rgbA, leaf, calls,
        bake: BAKE_MS, first, warm, shadowPx: Object.fromEntries(Object.entries(shadowPx).map(([k, v]) => [k, [...v]])), onGround, shade, surf: surf.join(''), wet, shaded: Array.from(SHADED),
        glints: LOOK.glints.map(g => g.i), SKYB: SKY.bands, GR: GRASS.map(c => rgb(...c)), waterline: LAGO_SET.WATERLINE() };
    });
    G.ms = { first: g.first, warm: g.warm, page: g.bake };
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, K: g.K, SKYB: g.SKYB, GR: g.GR });
    G.parts[key] = g.parts; G.z[key] = g.z; G.kinds[key] = g.kinds; G.rgb[key] = g.rgb; G.leaf[key] = g.leaf; G.shadows[key] = g.calls;
    for (const k of ['shadowPx', 'onGround', 'shade', 'surf', 'wet', 'shaded', 'glints', 'waterline']) (G[k] = G[k] || {})[key] = g[k];
  }
  if (errs.length) throw new Error(errs.join('; '));
  G.M = await measure(await browser.newPage());
  const sheet = make(G);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  if (process.env.LAGO_NOCHECK) { await browser.close(); console.log('wrote ' + path.relative(REPO, OUT) + ' (no checks)'); return; }
  const runs = storyStates();
  G.TICKS = await tickStates(browser, runs, sheet);
  G.PV = await previewPlaces(browser, runs);
  if (process.env.LAGO_DUMP) runs.forEach((r, i) => fs.writeFileSync(path.join(process.env.LAGO_DUMP, r.story.id + '.' + r.plan + '.json'), JSON.stringify({ old: r.lines, port: G.TICKS[i].states })));   // for the pictures (not in the repo)
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

/* ---------- the old sprite layer, measured in the browser ---------- */
// historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/lago.js loaded as they are into a blank page; lago.js's own sprite
// makers (COLOR, mkPato, mkPez, mkPajaro, mkBote, mkPan, mkBolsa) taken from its text as they are. A bubble is drawn as lago.js bub2 draws it
// (twice its size, its tail's tip at the origin), on both frames of its bob
const LAGO_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/lago.js'), 'utf8');
const LINES = LAGO_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('lago.js changed: ' + s); return i + 1; };
const linesOf = s => LINES.map((l, i) => l.includes(s) ? i + 1 : 0).filter(Boolean);
const fnText = name => { const a = LAGO_JS.indexOf('function ' + name + '('); if (a < 0) throw new Error('lago.js changed: ' + name); let d = 0, i = LAGO_JS.indexOf('{', a);
  for (; i < LAGO_JS.length; i++) { if (LAGO_JS[i] === '{') d++; else if (LAGO_JS[i] === '}' && --d === 0) break; } return LAGO_JS.slice(a, i + 1); };
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/lago.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  await page.addScriptTag({ content: '(()=>{const R=Math.round;' + LINES[lineOf('const COLOR={rojo:') - 1] + LINES[lineOf('const COLOR={rojo:')] + '\n' + ['mkPato', 'mkPez', 'mkPajaro', 'mkBote', 'mkPan', 'mkBolsa'].map(fnText).join('\n') + '\nwindow.MK={COLOR,mkPato,mkPez,mkPajaro,mkBote,mkPan,mkBolsa};})();' });
  const oldPng = 'data:image/png;base64,' + fs.readFileSync(path.join(REF, 'frames/s000.nochar.png')).toString('base64');
  return page.evaluate(async oldPng => {
    // the old picture without characters: which pixels are its water (rows 119 on, its blue pixels) and its mean water colour
    const old = await new Promise(res => { const im = new Image(); im.onload = () => { const cv = document.createElement('canvas'); cv.width = 240; cv.height = 216; const g = cv.getContext('2d'); g.drawImage(im, 0, 0);
      res(Array.from(g.getImageData(0, 0, 240, 216).data)); }; im.src = oldPng; });
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
    const meanOf = draw => { const cv = document.createElement('canvas'); cv.width = 160; cv.height = 140; const g = cv.getContext('2d'); g.imageSmoothingEnabled = false; draw(g, 80, 100);
      const d = g.getImageData(0, 0, 160, 140).data; let n = 0, s = [0, 0, 0]; for (let i = 0; i < d.length; i += 4) if (d[i + 3] > 40) { n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } return s.map(v => Math.round(v / n)); };
    const QUIEN = { luis: KIT.FAM.hermano, carmen: KIT.FAM.hermana }, masks = {}, heads = {};
    const head = rows => { const top = Math.min(...rows.map(r => r[0])), rs = rows.filter(r => r[0] < top + 10); return { top, head: (Math.min(...rs.map(r => r[1])) + Math.max(...rs.map(r => r[2])) + 1) / 2 }; };
    // a person as lago.js gente draws them: translate(x, y - h + 1), scale(-1, 1) when (pose offer ? -dir : dir) < 0, drawImage(im, -PX, 0)
    for (const [id, fam] of Object.entries(QUIEN)) for (const sent of [0, 1]) for (const pose of ['idle', 'wave0', 'wave1', 'offer', 'yo', 'tu', 'ojos']) for (const dir of [1, -1]) {
      const im = KIT.mkPersona(fam, pose, 0, sent), flip = (pose === 'offer' ? -dir : dir) < 0;
      masks[id + '.' + pose + '.' + dir + (sent ? '.s' : '')] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 1); if (flip) g.scale(-1, 1); g.drawImage(im, -KIT.PX, 0); g.restore(); });
      if (pose === 'idle' && dir === 1) heads[id + (sent ? '.s' : '')] = head(masks[id + '.idle.1' + (sent ? '.s' : '')]);
    }
    // the dog as lago.js draws it: translate(x, y - h + 2), scale(-1, 1) when dir < 0, drawImage(im, -13, 0)
    const animals = {};
    for (const pose of ['sit', 'walk', 'run', 'bark', 'lie']) for (const f of [0, 1]) for (const dir of [1, -1]) {
      const im = KIT.mkPerro(pose, f); animals['perro.' + pose + '.' + f + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 2); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -13, 0); g.restore(); }); }
    // a duck as pato() draws it: translate(x, y - dy), flip, scale(s) (the yellow one .78); nada: the top 18 rows at (-13, -18); else (-13, -21)
    for (const k of ['blanco', 'negro', 'amarillo']) for (const pose of ['nada', 'vuela', 'anda']) for (const f of [0, 1]) for (const dir of [1, -1]) {
      const im = MK.mkPato(k, pose, f), s = k === 'amarillo' ? .78 : 1;
      animals['pato.' + k + '.' + pose + '.' + f + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y); if (dir < 0) g.scale(-1, 1); g.scale(s, s); if (pose === 'nada') g.drawImage(im, 0, 0, 26, 18, -13, -18, 26, 18); else g.drawImage(im, -13, -21); g.restore(); }); }
    // a bird as ave() draws it: translate(x, y - dy), flip, drawImage(im, -7, -12)
    for (const c of ['azul', 'blanco', 'negro']) for (const v of [0, 1]) for (const f of [0, 1]) for (const dir of [1, -1]) {
      const im = MK.mkPajaro(c, f, v); animals['ave.' + c + '.' + v + '.' + f + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -7, -12); g.restore(); }); }
    // a boat as bote() draws it: translate(x, y), drawImage(im, -10, -19) (in the reeds: rotate .3 first)
    for (const c of ['rojo', 'azul', 'verde', 'madera']) for (const r of [0, 1]) { const im = MK.mkBote(c); animals['bote.' + c + '.' + r] = rowsOf((g, x, y) => { g.save(); g.translate(x, y); if (r) g.rotate(.3); g.drawImage(im, -10, -19); g.restore(); }); }
    // a fish as pez() draws it: translate(x, y - dy), flip when dir > 0, rotate -.5 when out of the water, drawImage(im, -9, -6)
    for (const c of ['pardo', 'rojo', 'azul', 'verde']) for (const out of [0, 1]) for (const dir of [1, -1]) { const im = MK.mkPez(c);
      animals['pez.' + c + '.' + out + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y); if (dir > 0) g.scale(-1, 1); if (out) g.rotate(-.5); g.drawImage(im, -9, -6); g.restore(); }); }
    // the bread at (x, y): drawImage(pan, x - 5, y - 7) (where it lies or flies); the bag W.bolsa: (x - 6, y - 12); the sack W.saco (lago.js draw);
    // the flower W.flor (lago.js draw)
    const things = {
      pan: rowsOf((g, x, y) => g.drawImage(MK.mkPan(), x - 5, y - 7)),
      bolsa: rowsOf((g, x, y) => g.drawImage(MK.mkBolsa(), x - 6, y - 12)),
      saco: rowsOf((g, x, y) => { g.fillStyle = '#000'; g.fillRect(x - 8, y - 10, 16, 11); g.fillRect(x - 5, y - 12, 10, 3); }),
      flor: rowsOf((g, x, y) => { g.fillStyle = '#2E8A34'; g.fillRect(x, y - 10, 1, 10); g.fillRect(x - 3, y - 5, 3, 2); g.fillStyle = '#F0B81C'; [[-3, -14], [1, -14], [-3, -10], [1, -10], [-1, -16], [-1, -9], [-4, -12], [2, -12]].forEach(d => g.fillRect(x + d[0], y + d[1], 3, 3)); }),
    };
    const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
    const colours = { frog: meanOf((g, x, y) => g.drawImage(mkCoqui(1, 0, 0), x, y)), pan: meanOf((g, x, y) => g.drawImage(MK.mkPan(), x, y)), perro: meanOf((g, x, y) => g.drawImage(KIT.mkPerro('lie', 0), x, y)), flor: hex(MK.COLOR.amarillo[1]) };
    for (const k of ['blanco', 'negro', 'amarillo']) colours['pato.' + k] = meanOf((g, x, y) => g.drawImage(MK.mkPato(k, 'nada', 0), 0, 0, 26, 18, x, y, 26, 18));
    for (const c of ['azul', 'blanco', 'negro']) colours['ave.' + c] = meanOf((g, x, y) => g.drawImage(MK.mkPajaro(c, 0, 0), x, y));
    for (const c of ['rojo', 'azul', 'verde', 'madera']) colours['bote.' + c] = meanOf((g, x, y) => g.drawImage(MK.mkBote(c), x, y));
    for (const c of ['pardo', 'rojo', 'azul', 'verde']) colours['pez.' + c] = meanOf((g, x, y) => g.drawImage(MK.mkPez(c), x, y));
    for (const c of ['rojo', 'azul', 'verde']) colours['vela.' + c] = meanOf((g, x, y) => g.drawImage(MK.mkBote(c), 10, 3, 9, 11, x, y, 9, 11));   // the sail (right of the mast, rows 3 to 13 of mkBote)
    const frogMask = rowsOf((g, x, y) => g.drawImage(mkCoqui(1, 0, 0), x, y));
    return { bubbles, masks, heads, animals, things, colours, frogMask, old, PX: KIT.PX };
  }, oldPng);
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

/* ---------- the preview's places: lago-preview.html maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  return serve(async base => {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto(base + '/docs/proyecto/pixel/lago-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => PREVIEW.places(PREVIEW.remapW(w))); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    await page.close();
    return out;
  });
}

/* ---------- lago.js as the port will have it: the sheet's moves applied (the same edit as lago-preview.html's, without its drawing) ---------- */
function portSource(sheet) {
  let src = LAGO_JS; const done = new Set();
  for (const m of sheet.moves) { if (done.has(m.src)) continue; done.add(m.src); if (!src.includes(m.src)) throw new Error('lago.js does not hold ' + m.src); src = src.split(m.src).join(m.to); }
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

/* ---------- every tick inside the acts: the old page played by the same machine as the recorded runs (coqui/tool/ref/trazas: page-init.js and
   page-drive.js, as they are, the same seed, think time and clock), lago.js and the story files as the port will have them (portSource,
   portStory), with one more script, read only: after each timer the runner fires, the scene's W is kept when it changed. So a duck's paddle, a
   boat's drift, a bird's flight and the bread's throw are seen tick by tick, at their new places */
const TRAZAS = path.join(REPO, 'coqui/tool/ref/trazas');
const TICK_HOOK = `(() => { const H = window.__H, d = H.drain; window.__TICKS = []; let last = '';
  const keep = () => { try { if (typeof W === 'undefined' || !W || !W.cq) return; const o = { gente: W.gente, perro: W.perro, patos: W.patos, aves: W.aves, peces: W.peces, botes: W.botes, pan: W.pan, cq: W.cq,
      bolsa: W.bolsa, saco: W.saco, flor: W.flor, fila: W.fila, tarjeta: W.tarjeta, marcas: W.marcas, respEn: W.respEn, resp: W.resp, spot: W.spot, salpica: W.salpica, F: typeof F === 'number' ? F : 0 };
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
        await ctx.route(/\/historia\/escenas\/lago\.js(\?.*)?$/, route => route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: SRC }));
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

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  // the walkable surface under a screen point (lago-set.html surfaceAt): the deck's planks, the lawn or the water's surface
  const F = G.F, onDeck = (x, y) => (x >= F.DECK.x0 && x <= F.DECK.x1 && y >= F.DECK.y0 && y <= F.DECK.y1) || (x >= F.LANDING.x0 && x <= F.LANDING.x1 && y >= F.LANDING.y0 && y <= F.LANDING.y1);
  const shore = (x, y) => Math.max(F.BANK + .035 * Math.sin(y * 2.3 + 1) + .025 * Math.sin(y * 5.1) - x, F.BANK2 + .03 * Math.sin(x * 2.1 + .5) + .02 * Math.sin(x * 4.7) - y);
  const surface = (sx, sy) => { const d = atZ(sx, sy, F.ZD); if (onDeck(d[0], d[1])) return { on: 'dock', w: d };
    const g = atZ(sx, sy, 0); if (shore(g[0], g[1]) >= 0 || sy < F.HZ) return { on: 'lawn', w: g }; return { on: 'water', w: atZ(sx, sy, -F.WDEPTH) }; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ, surface, onDeck, shore };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const hop = d => d < 3 ? 0 : Math.max(1, Math.min(4, Math.round(d / 30)));   // kit.js acts.ir
const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');

/* ---------- the old scene's numbers (historia/escenas/lago.js, read as text: they must be what the file says) ---------- */
function fixJson(s) { return s.replace(/\s+/g, '').replace(/([{,])(\w+):/g, '$1"$2":').replace(/:\./g, ':0.').replace(/,\./g, ',0.').replace(/\[\./g, '[0.'); }
const OLD = (() => { const g = (re, w) => { const m = LAGO_JS.match(re); if (!m) throw new Error('lago.js changed: ' + w); return JSON.parse(fixJson(m[1])); };
  return { AGUA: g(/const AGUA=(\d+)/, 'AGUA'), MUELLE: g(/MUELLE=(\[[\d,]+\])/, 'MUELLE'), POSTE: g(/POSTE=(\[\d+,\d+\])/, 'POSTE'), PM: g(/PM=(\[\[[^;]*?\]\]),JUNCOS/, 'PM'),
    JUNCOS: g(/JUNCOS=(\[\[[^;]*?\]\]),ORILLA/, 'JUNCOS'), ORILLA: g(/ORILLA=(\[\d+,\d+\])/, 'ORILLA'), FX: g(/FX=(\[[\d,]+\])/, 'FX'), FY: g(/FY=(\d+)/, 'FY'),
    SALE: g(/SALE=(\[\[[^;]*?\]\]),PEGA/, 'SALE'), PEGA: g(/PEGA=(\[\[[^;]*?\]\]);/, 'PEGA') }; })();
{ const m = LAGO_JS.match(/const LUGAR=\{inicio:\[(\d+),(\d+),(\d+)\],muelle:\[(\d+),(\d+),(\d+)\]\}/); if (!m) throw new Error('lago.js changed: LUGAR'); OLD.LUGAR = { inicio: [+m[1], +m[2], +m[3]], muelle: [+m[4], +m[5], +m[6]] }; }
// the old boxes of the set things (lago.js COSAS)
const OLDBOX = { juncos: [178, 120, 40, 46], poste: [OLD.POSTE[0] - 5, OLD.POSTE[1] - 26, 10, 36], muelle: [OLD.MUELLE[0], OLD.MUELLE[1] - 2, OLD.MUELLE[2], OLD.MUELLE[3] + 4], agua: [0, OLD.AGUA, 240, 98], lago: [0, 94, 240, 122] };
// every frog place: LUGAR, the frog's places in inicio19 and inicio20, the place acts.ranapinta hops him to (Luis's x - 44: Luis is at 128, so
// 84), and the stories' own (d-pato-pequeno: 86, 125 and acts.ranaa 104, 125; h-lago: 108, 125). Screen q (old = new: the floor rule)
const FROG_PLACES = { inicio: [100, 125], inicio19: [60, 125], inicio20: [62, 125], ranapinta: [84, 125], pequeno: [86, 125], ranaa: [104, 125], hlago: [108, 125] };

// the places a bubble's tail may go, in order (as El campo's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner card lago.js hud draws, in the 196 x 216 display (tarjeta(3, 3, 66, 24) covers [2, 2, 68, 26])
const BOARD = [2, 2, 68, 26];
const boardsOf = (w, x0) => w.tarjeta ? [['the rounds card', [BOARD[0] + x0, BOARD[1], BOARD[2], BOARD[3]]]] : [];

/* ---------- the design: what moves and why, the pictures, the rules (make() reads it) ---------- */
const DESIGN = (() => {
  const POSTE = [166, 156], ORILLA = [188, 109], SLOTS = [[160,122],[166,125],[166,116],[171,128],[172,119],[177,130],[183,133],[189,136],[178,122],[184,125],[190,128],[196,131]], FX = [46, 66, 85], FYB = [154, 164, 174], EN = [132, 32];
  const moves = [
    { act: '*', src: 'POSTE=[152,146]', to: 'POSTE=[' + POSTE + ']', pts: [['ave', [152, 122], [POSTE[0], POSTE[1] - 24]]], shift: { who: 'pato', when: 'rema', by: [POSTE[0] - 152, POSTE[1] - 146] },
      why: 'the post in the water: its old foot (152, 154) lies at the dock\'s right corner (the deck is as wide as its row of places needs: layout); ' + (POSTE[0] - 152) + ' px right and ' + (POSTE[1] - 146) + ' rows down, past the dock\'s end, so that the post, the bird on it (POSTE[1] - 24) and the duck paddling round it (acts.rema) have water all round, clear of the dock, of the boats\' row at Carmen\'s feet and of the reeds (round 3)' },
    { act: 'inicio19', src: 'ORILLA=[178,116]', to: 'ORILLA=[' + ORILLA + ']', pts: [['carmen', [196, 117], [ORILLA[0] + 18, ORILLA[1] + 1]]],
      why: 'acts.inicio19 (los-botes): Carmen on the far bank (ORILLA + (18, 1)). The shore is one straight line on a world axis: the lawn is up to the left, and the old far bank at the right (196, 117) is open water. Round 3: the lake has its right bank again (layout): she stands on it near her old point, 8 px of lawn round her feet, facing the water, and the boats Luis sends arrive at her feet (slotC), as the old row ended at hers; as low on the bank as she can (the answer cards in the sky 2 px over her head, the hand at the right card off her face)' },
    { act: '*', src: 'FX=[46,68,90],FY=165', to: 'FX=[' + FX + '],FY=165,FYB=[' + FYB + ']', pts: [['bote', [46, 165], [FX[0], FYB[0]]], ['bote', [68, 165], [FX[1], FYB[1]]], ['bote', [90, 165], [FX[2], FYB[2]]]],
      why: 'the row of three boats on the dock (repone): the old row lay along the old dock\'s face (row 165); here the boats stand on the planks in a row along the dock\'s near edge (each with planks under its whole keel and 3 px of plank to the edge), in front of the frog as the old' },
    { act: '*', src: 'x:FX[i],y:FY,en:"muelle"', to: 'x:FX[i],y:FYB[i],en:"muelle"', why: 'repone: each boat of the row at its own row (FYB)' },
    { act: '*', src: '{W.botes[id].x=FX[i];}', to: '{W.botes[id].x=FX[i];W.botes[id].y=FYB[i];}', why: 'repone: a boat put back in the row takes its row too (the old row had one row for all three)' },
    { act: '*', src: 'await boteA(id,134,FY,7)', to: 'await boteA(id,112,160,7)', pts: [['bote', [134, 165], [112, 160]]], why: 'acts.empuja: the frog pushes the boat along the dock to Luis: the old point (134, 165) is off the new dock\'s end; on the planks before Luis\'s feet' },
    { act: '*', src: 'await boteA(id,134,FY-6,8)', to: 'await boteA(id,120,156,8)', pts: [['bote', [134, 159], [120, 156]]], why: 'acts.luiscoge: Luis carries the boat back to his place at the dock\'s end: before his feet, on the planks' },
    { act: '*', src: 'await patoA(k,136,172,"nada",6)', to: 'await patoA(k,150,184,"nada",6)', pts: [['pato', [136, 172], [150, 184]]], why: 'acts.final20: the ducks gather before the dock\'s end before they waddle onto it: the old point is under the new deck\'s end; 8 px of water past it' },
    { act: '*', src: 'L.push({y:FY+1,d:()=>c.drawImage(spr("pan",mkPan),36+i*12-5,FY-8)})', to: 'L.push({y:158,d:()=>c.drawImage(spr("pan",mkPan),54+i*12-5,149)})', why: 'the row of bread on the dock (W.fila): the old row lay on the old dock\'s face; here on the planks, in front of the people' },
    { act: '*', src: 'const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];', to: 'const SLOTC=' + JSON.stringify(SLOTS) + ',slotC=i=>SLOTC[Math.min(i,11)];', slot: true,
      why: 'round 3: the boats that reach Carmen (sopla, conpez; 12 at the most in a run): the old row lay along the far bank and ended at her feet, filled from its far end towards her; here two rows on the water along the right bank, running from her feet up the bank, the last slot 8 to 12 px of water straight in front of her, filled from the farthest towards her as the old, neighbours 6 px apart at the least (the old spacing), each slot no further from her than the old slot was from the old Carmen (+ 10 px), none behind the post or in the reeds' },
    { act: '*', src: 'PEGA=[[182,166],[196,172],[210,168],[190,178]]', to: 'PEGA=[[192,160],[187,156],[196,165],[184,162]]', pts: [['bote', [182, 166], [192, 160]], ['bote', [196, 172], [187, 156]], ['bote', [210, 168], [196, 165]], ['bote', [190, 178], [184, 162]]],
      why: 'acts.deriva: where a drifting boat sticks in the reeds: at the front of the reed bed in the shallows of the right bank (round 3; round 4: the bed further into the view), 6 px and more from the view\'s edge, 60% and more of each boat seen' },
    { act: '*', src: 'await patoA("blanco",124,126,"nada");d.pose="anda";await patoA("blanco",120,118,"anda",4)', to: 'await patoA("blanco",132,124,"nada");d.pose="anda";await patoA("blanco",102,110,"anda",4)', pts: [['pato', [124, 126], [132, 124]], ['pato', [120, 118], [102, 110]]],
      why: 'acts.orilla (pan-para-el-pato): the duck climbs out onto the far bank: the old bank at row 118 is water here; it swims to the shore up the lake (8 px of water round it) and walks out onto the lawn (8 px of lawn round its feet)' },
    { act: '*', src: 'await patoA("blanco",124,126,"anda",4);d.pose="nada";salpica(124,128);', to: 'await patoA("blanco",132,124,"anda",4);d.pose="nada";salpica(132,126);', why: 'acts.alagua: back into the water where it came out (orilla)' },
    { act: 'inicio18', src: 'async inicio18(){W.gente=', to: 'async inicio18(){W.respEn=[121,75];W.gente=', respEn: [121, 75], why: 'acts.inicio18 (pan-para-el-pato): the answer cards (vuela, nada) stand over the frog as the old, a little higher and to the right: clear of Carmen\'s head, under the circle the duck and the bird fly round (its lowest row 74), the hand at the first card off her face' },
    { act: 'inicio19', src: 'async inicio19(){W.gente=', to: 'async inicio19(){W.respEn=[127,31];W.gente=', respEn: [127, 31], why: 'acts.inicio19 (los-botes): the answer cards stand in the sky (W.respEn): over the frog on the dock they covered Carmen across the water, Luis and the boats. Round 3: under the rounds card by 2 px, over Carmen\'s head on the right bank by 2 px, their frames and glow off the sun and 4 px inside the view; the hand at each card off her face' },
    { act: 'inicio20', src: 'async inicio20(){W.gente=', to: 'async inicio20(){W.respEn=['+EN+'];W.gente=', respEn: [132, 32], why: 'acts.inicio20 (cual, d-pato-pequeno, h-lago): the answer cards stand in the sky (W.respEn): over the frog they covered Luis and Canelo on the lawn and Carmen' },
    { act: '*', src: 'const P7=i=>[134+(i-1)*9.5,177+(i-1)*2]', to: 'const P7=i=>[156+(i-1)*4.5,186+(i-1)*1]', pts: (() => { const OFF = [[-14, -9], [14, -7], [0, 12]], out = []; for (let i = 1; i <= 7; i++) for (const o of OFF) out.push(['pato', [Math.round(134 + (i - 1) * 9.5 + o[0]), Math.round(177 + (i - 1) * 2 + o[1])], [Math.round(156 + (i - 1) * 4.5 + o[0]), 186 + (i - 1) * 1 + o[1]]]); return out; })(), why: 'story 20: the seven places of the three ducks, from the dock outward: the old first places lay under the new dock\'s end (as wide as its row of places needs); they start 8 px of water past its end and end 6 px from the view\'s right edge (the ducks closer together, their order and offsets OFF unchanged)' },
    { act: '*', src: 'W.peces={a:{c:"pardo",x:92,y:192,x0:92,dir:1,vaiven:1}}', to: 'W.peces={a:{c:"pardo",x:138,y:194,x0:138,dir:1,vaiven:1}}', pts: [['pez', [92, 192], [138, 194]]], why: 'acts.inicio18: the fish swimming to and fro (x0 +- 12): the old place passed under the new dock\'s near corner; on open water in front of its end, out of its shade (round 3)' },
    { act: '*', src: 'o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t)', to: 'o.x=132+8*Math.cos(t);o.y=190+4*Math.sin(t)', why: 'anima: the fish circling before the dock (pezviene, h-lago): its hint frame (box + 12) 2 px inside the view at the bottom of its circle, its patch out of the dock\'s shade, its circle narrower (13 to 8 px) so that it keeps clear of the ducks (round 3)' },
    { act: '*', src: 'await pezA("a",134,192,16)', to: 'await pezA("a",140,190,16)', pts: [['pez', [134, 192], [140, 190]]], why: 'acts.pezviene: the fish swims up to its circle (anima, moved)' },
    { act: '*', src: 'const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;', to: 'const b=W.botes[o.sigue];o.x=b.x+10;o.y=b.y+12;', why: 'anima: the fish swimming with a boat to Carmen (conpez): below the boat\'s right instead of its left, so that its path keeps out of the dock\'s shade at the dock\'s end (round 3)' },
    { act: '*', src: 'await pezA("a",SALE[0][0]-4,SALE[0][1]+9,6)', to: 'await pezA("a",SALE[0][0]+10,SALE[0][1]+12,6)', why: 'acts.conpez: the fish comes to the boat\'s right (anima, round 3)' },
    { act: 'inicio20', src: 'W.flor=[196,119]', to: 'W.flor=[204,112]', pts: [['flor', [196, 119], [204, 112]]], why: 'acts.inicio20: the yellow flower on the right bank (round 3), as the old: round 4, 8 px right and 7 rows up of its old point, whole inside the view 4 px and more from its right edge with the stars of its twinkle inside it, 8 px of lawn round its foot, lawn and the hills behind its head' },
  ];
  const storyMoves = [
    { old: [152, 122], new: [POSTE[0], POSTE[1] - 24], who: 'ave', why: 'h-lago beats.14: the bird on the post (POSTE[1] - 24): the post moved (moves)' },
    { old: [96, 118], new: [86, 113], who: 'luis', why: 'd-pato-pequeno and h-lago beats.1: Luis sits on the lawn up the shore: 8 px of lawn round him, clear of the dock\'s far corner (the bank is nearer here than the old far bank was); 10 px left, 5 rows up' },
    { old: [140, 119], new: [208, 110], who: 'ave', why: 'the pair pájaro.si: the bird with the crust stood on the old far bank (140, 119), open water here: on the right bank (round 3)' },
    { old: [104, 172], new: [120, 194], who: 'pato', why: 'd-pato-pequeno beats.33 (patoa): the old point is under the new deck; in front of the dock\'s near corner, water all round' },
    { old: [124, 176], new: [138, 188], who: 'pato', why: 'd-pato-pequeno beats.34 (patoa): the old point is at the new deck\'s end; past it, water all round' },
  ];
  const all = () => moves.flatMap(m => (m.pts || []).map(q => ({ old: q[1], new: q[2] }))).concat(storyMoves);
  return {
    POSTE, ORILLA, FX, FYB, moves, storyMoves,
    newPlace: o => { const m = all().find(q => q.old[0] === o[0] && q.old[1] === o[1]); return m ? m.new.slice() : null; },
    places: [
      ['luis.inicio18', { old: [44, 154] }, 'acts.inicio18: Luis sits on the dock (its landing), at its root'],
      ['carmen.inicio18', { old: [72, 154] }, 'acts.inicio18: Carmen on the dock, the bag in her hand'],
      ['luis.inicio19', { old: [128, 154] }, 'acts.inicio19: Luis at the dock\'s end'],
      ['carmen.inicio19', { old: [196, 117] }, 'acts.inicio19: Carmen across the water (ORILLA + (18, 1))'],
      ['luis.inicio20', { old: [74, 118] }, 'acts.inicio20: Luis sits on the lawn up the shore'],
      ['carmen.inicio20', { old: [112, 154] }, 'acts.inicio20: Carmen on the dock'],
      ['perro', { old: [46, 119] }, 'acts.inicio20: Canelo lies on the lawn'],
      ['bolsa', { old: [96, 153] }, 'acts.inicio20: the bag on the dock (W.bolsa)'],
      ['saco', { old: [110, 153] }, 'acts.inicio19: the sack on the dock (W.saco)'],
      ['flor', { old: [196, 119] }, 'acts.inicio20: the yellow flower (W.flor)'],
      ['pato.casa', { old: [142, 184] }, 'acts.inicio18, baja, alagua: the white duck\'s place on the water'],
      ['pez.inicio18', { old: [92, 192] }, 'acts.inicio18: the fish, swimming to and fro'],
      ['ave.poste', { old: [152, 122] }, 'POSTE[1] - 24: the bird on the post'],
      ['ave.pm0', { old: [40, 140] }, 'PM[0] - 1: a bird on the left mooring post'],
      ['ave.pm1', { old: [133, 140] }, 'PM[1] - 1: a bird on the right mooring post'],
      ['bote.fila0', { old: [46, 165] }, 'FX[0], FY: the first boat of the row on the dock'],
      ['bote.fila1', { old: [68, 165] }, 'FX[1], FY'], ['bote.fila2', { old: [90, 165] }, 'FX[2], FY'],
      ['sale.0', { old: [150, 172] }, 'SALE[0]: where a boat is set on the water'], ['sale.1', { old: [168, 180] }, 'SALE[1]'], ['sale.2', { old: [152, 190] }, 'SALE[2]'],
      ['pega.0', { old: [182, 166] }, 'PEGA[0]: where a drifting boat sticks in the reeds'], ['pega.1', { old: [196, 172] }, 'PEGA[1]'], ['pega.2', { old: [210, 168] }, 'PEGA[2]'], ['pega.3', { old: [190, 178] }, 'PEGA[3]'],
      ['pato.orilla.agua', { old: [124, 126] }, 'acts.orilla: the duck at the shore'], ['pato.orilla', { old: [120, 118] }, 'acts.orilla: the duck out on the lawn'],
    ],
    pictures: pic => ({
      'pato.si': pic(100, 140, 2, 'a duck walking on the dock'), 'pato.no': pic(100, 140, 2, 'a bird on the dock'),
      'pez.si': pic(156, 184, 2, 'a fish leaping from the water'), 'pez.no': pic(156, 184, 2, 'a duck on the water, eating'),
      'pajaro.si': pic(200, 102, 2, 'a bird with a crust, on the lawn by the water'), 'pajaro.no': pic(150, 180, 2, 'a fish under the water by a crust'),
      'nada.si': pic(150, 180, 2, 'a duck swimming'), 'nada.no': pic(150, 56, 2, 'a duck flying'),
      'vuela.si': pic(152, 56, 2, 'a bird flying'), 'vuela.no': pic(98, 140, 2, 'a bird on the dock with a crust'),
      'rojo.si': pic(150, 180, 2, 'a red boat on the water'), 'rojo.no': pic(150, 180, 2, 'a blue boat on the water'),
      'azul.si': pic(150, 184, 2, 'a blue fish'), 'azul.no': pic(150, 184, 2, 'a green fish'),
      'verde.si': pic(98, 140, 2, 'a green boat on the dock'), 'verde.no': pic(98, 140, 2, 'a red boat on the dock'),
      'amarillo.si': pic(150, 180, 2, 'the yellow duck'), 'amarillo.no': pic(150, 180, 2, 'the white duck'),
      'blanco.si': pic(133, 130, 2, 'a white bird on the post'), 'blanco.no': pic(133, 130, 2, 'a black bird on the post'),
      'negro.si': pic(150, 180, 2, 'the black duck'), 'negro.no': pic(150, 180, 2, 'the yellow duck'),
    }),
  };
})();
Object.assign(DESIGN, {
  // the set things' hands and hint boxes: a thing that runs off the picture (the lake, the water, the reeds) gets a hint box, the part of its
  // touch box the hint frame shows (its frame, box + 12, 2 px inside the view); touches still answer in its box
  thingsExtra(things, { E, F, G }) {
    const inView = b => { const x0 = Math.max(b[0], 22 + 14), y0 = Math.max(b[1], 14), x1 = Math.min(b[0] + b[2], 22 + 196 - 14), y1 = Math.min(b[1] + b[3], 216 - 14); return [x0, y0, x1 - x0, y1 - y0]; };
    const wetRows = (() => { let top = 216; for (let i = 0; i < 240 * 216; i++) if (G.wet.lago[i]) { top = Math.min(top, Math.floor(i / 240)); } return top; })();
    things.agua.box = [0, wetRows, 240, 216 - wetRows]; things.agua.world = null;
    things.lago.box = [0, F.HZ, 240, 216 - F.HZ];
    for (const k of ['juncos', 'agua', 'lago', 'muelle', 'poste']) { const b = things[k].box, h = inView(b); if (JSON.stringify(h) !== JSON.stringify(b)) { things[k].hintBox = h; things[k].hintWhy = 'hintBox: the part of its touch box the hint frame shows (the frame, box + 12, 2 px inside the view); the touch box answers the touches'; } }
    things.muelle.hand = [96, 160]; things.muelle.handWhy = 'on the planks before the people\'s feet (the old: the middle of the old dock\'s box, 82, 158)';
    things.poste.hand = [this.POSTE[0], this.POSTE[1] - 4]; things.poste.handWhy = 'on the post (the old: the middle of its box)';
    things.juncos.hand = [things.juncos.hintBox ? Math.round(things.juncos.hintBox[0] + things.juncos.hintBox[2] / 2) : 0, things.juncos.hintBox ? Math.round(things.juncos.hintBox[1] + things.juncos.hintBox[3] / 2) : 0]; things.juncos.handWhy = 'the middle of its hint box';
    things.agua.hand = [176, 196]; things.agua.handWhy = 'on open water past the dock (the old: the middle of the old water, 120, 167, now on the dock)';
    things.lago.hand = [176, 196]; things.lago.handWhy = 'on open water past the dock';
  },
  rules: F => ({
    project: 'pp-engine.js project(x, y, z) with S 26 and this origin (El camino\'s and El campo\'s); a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
    floor: 'the lake and its dock are built round the old picture: a place keeps its screen place, and its world point is the walkable surface under it (lago-set.html surfaceAt): the dock\'s planks (z ' + F.ZD + ') where the deck or its landing is under the screen point at that height, else the lawn (z 0) on the land side of the shore, else the water\'s surface (z -' + F.WDEPTH + '). A frog place q: under (q.x + 16, q.y + 25); a person\'s, Canelo\'s, a duck\'s, a bird\'s, a boat\'s, the bread\'s, the bag\'s, the sack\'s or the flower\'s place (x, y): under (x, y - 1). So every position of lago.js, its stories and its pairs keeps its numbers, but those in moves and the story positions remap moves; the sheet names each one (spots, remap, code) with its world point',
    relative: 'what the old code draws or moves relative to a person, the frog, a duck, a bird, a boat or the fish (what is carried, the brush, the bread in a beak, a splash, a wake, the bubbles) keeps its offsets',
    sky: 'screen-space effects keep their old numbers: the stars of the happy endings (final18, final19, final20), the heart (heartAt), the birds\' and the duck\'s circle in the sky (anima: 150 + 46 cos, 58 + 16 sin)',
    view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
    pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2 (every old picture of cual-lago is a 113 x 60 or 100 x 53 window: about 2 x). The old rectangles (remap cam and crop) say which pictures they were',
  }),
  layout: (F, E) => ({
    what: 'the park\'s lake seen nearer, on the world\'s axes at the engine\'s 30 degrees (shadows to screen right): the lawn (El frente\'s grass, calm, as El camino\'s and El campo\'s) up to the left of one straight shore along y; the lake (El campo\'s water: the same helper, colours, bank and glints) on its near side, filling the picture down and to the right; the dock running out from the shore along x over the water, its planks across it, on pilings, its landing on the lawn at its root; the post standing alone in the water past the dock\'s end; the reed bed in the shallows at the right, higher up the water than the old; El camino\'s hills and day sky over it, the sun upper left, the old picture\'s three clouds',
    lines: { shore: 'x = ' + r4(F.BANK) + ' (screen sx + 2 sy = ' + F.SHORE_K + ')', deck: 'x ' + r4(F.DECK.x0) + ' to ' + r4(F.DECK.x1) + ', y ' + r4(F.DECK.y0) + ' to ' + r4(F.DECK.y1) + ', z ' + F.ZD + ' (its underside ' + r4(F.ZD - F.TH) + '); the landing x ' + r4(F.LANDING.x0) + ' to ' + r4(F.LANDING.x1) + ', y ' + r4(F.LANDING.y0) + ' to ' + r4(F.LANDING.y1) },
    why: 'the brief and page 11 decision 9: the set stands on the world\'s axes; nothing is built square to the camera. The old picture had a horizontal far bank and a horizontal dock: neither can lie on a world axis. One straight shore along y keeps the old strip of lawn at the back on the left (Luis and Carmen sitting, Canelo) and the old left bank under the dock\'s root, and gives the lake more of the view than the old water had (water); the old far bank at the right becomes water, and what stood there moves onto the lawn up the shore (moves: Carmen of los-botes, the flower, the duck that climbs out, the bird of pájaro.si). The dock runs out from the shore along x; as every place on the old dock keeps its screen point (the frog, the children, the bag, the sack, the ducks that waddle onto it: on the screen a level row 100 px long), its deck is as wide as that row needs, on a world axis a row level on the screen runs across both axes. The post moved past the dock\'s end and the reeds higher up the water at the right: below them, before the dock\'s end, is where the ducks, the boats and the fish of the stories swim',
  }),
  front: F => ({
    how: 'the old background (fondo: the dock, its posts, the post) was drawn before everyone, and its reeds were in the sorted list; now the reeds, the post and the dock\'s mooring posts are set things someone can be behind. At its entry in the list lago.js draw sorts by y (sortY 9999: after everyone), for each item drawn before it (a child, the frog, Canelo, a duck, a bird, a boat, the fish, the bread, the bag, the sack: each item says what it is), the set\'s own pixels of the part (lago-set.html part(), PART_TAGS) are drawn again inside the item\'s box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the surface point under it (rules.floor: the deck\'s, the lawn\'s or the water\'s). "Behind the post" is that depth test, not a row',
    plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
    boxes: 'a child: [x - 24, y - 46 - dy, 48, 49 + dy]; the frog: frogBox with dy; Canelo: [x - 16, y - 24 - dy, 32, 27 + dy]; a duck: [x - 14, y - 23 - dy, 28, 26]; a bird: [x - 9, y - 14 - dy, 18, 16]; a boat: [x - 12, y - 22, 24, 26]; the fish: [x - 11, y - 9 - dy, 22, 16]; the bread: [x - 6, y - z - 8, 13, 12]; the bag: [x - 7, y - 13, 14, 15]; the sack: [x - 9, y - 13, 18, 15]; its ground point under (x, y - 1)',
    parts: Object.fromEntries(['juncos', 'poste', 'muelle.postes'].map(p => [p, { sortY: 9999, insert: 'before the sort: L.push({y: 9999, front: "' + p + '"})', why: { juncos: 'a boat stuck in the reeds, a duck or the fish among them: the reeds nearer than it drawn over it', poste: 'a duck paddling round the post (acts.rema), behind it: the post drawn over it', 'muelle.postes': 'whoever stands on the dock behind a mooring post: the post drawn over them' }[p] }])),
    tags: [
      ['L.push({y:p.y,d:()=>gente(c,id,a)})', 'L.push({y:p.y,id,d:()=>gente(c,id,a)})'],
      ['L.push({y:o.pose==="vuela"?o.y+200:o.y,d:()=>pato(c,o,a)})', 'L.push({y:o.pose==="vuela"?o.y+200:o.y,pato:k,d:()=>pato(c,o,a)})'],
      ['L.push({y:o.y+200,d:()=>ave(c,o,a)})', 'L.push({y:o.y+200,ave:k,d:()=>ave(c,o,a)})'],
      ['L.push({y:o.y+(o.en==="juncos"?14:1),d:()=>bote(c,o)})', 'L.push({y:o.y+(o.en==="juncos"?14:1),bote:k,d:()=>bote(c,o)})'],
      ['L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,d:()=>pez(c,o)})', 'L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,pez:k,d:()=>pez(c,o)})'],
      ['if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)})', 'if(q.vis)L.push({y:q.y+27,id:"coqui",d:()=>rana(c,q,a)})'],
      ['if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:', 'if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,k:"perro",d:'],
    ],
    tagsWhat: 'each item of the sorted list says what it is (the front masks read it); nothing else changes',
  }),
  shadows: (F, DROPPED) => ({
    rule: 'every shadow is cast from the ground point (z 0) under the screen point of the thing\'s feet (unproject), as El campo\'s, and darkens only pixels that take a cast shadow: the lawn and the dock\'s planks (ground, at its own depth). The water takes none (lago-set.html LOOK.noShade): what floats or swims has its ring instead (helps.ring); the dock\'s own shade on the water is baked into the set, joined to it',
    coqui: { radius: .45, at: 'unproject(b.x + b.w / 2, q.y + 25)', when: 'W.cq.vis and al > .5, on the lawn or the dock', cast: 'castShadow(g.x, g.y, .3, .45)' },
    people: { radius: { nino: .3 }, at: 'unproject(x, y - 1)', when: 'visible (vis !== 0, al > .5)', cast: 'for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, .3) (sitting: z to 1.35)' },
    perro: { radius: .32, at: 'unproject(x, y - 1)', when: 'W.perro shown', cast: 'castShadow(g.x, g.y, .25, .32)' },
    pato: { radius: .26, at: 'unproject(x, y - 1)', when: 'a duck that walks (pose anda) on the lawn or the dock', cast: 'castShadow(g.x, g.y, .2, .26)' },
    ave: { radius: .16, at: 'unproject(x, y - 1)', when: 'a bird standing (not flying, not on a post top) on the lawn or the dock', cast: 'castShadow(g.x, g.y, .1, .16)' },
    bote: { radius: .3, at: 'unproject(x, y - 1)', when: 'a boat on the dock (en muelle)', cast: 'castShadow(g.x, g.y, .15, .3)' },
    pan: { radius: .18, at: 'unproject(x, y - 1) of each piece: the row (W.fila, at its places in moves) and a piece lying on the dock', cast: 'castShadow(g.x, g.y, .1, .18)' },
    bolsa: { radius: .22, at: 'unproject(x, y - 1)', when: 'W.bolsa', cast: 'castShadow(g.x, g.y, .15, .22)' },
    saco: { radius: .3, at: 'unproject(x, y - 1)', when: 'W.saco', cast: 'castShadow(g.x, g.y, .15, .3)' },
    dropped: 'none of the old code\'s own: lago.js draws no shadow',
  }),
  helps: F => ({
    what: 'drawn by the sprite layer just before the thing they help, 1:1 (lines: each drawing function of a thing on the water gains one call): El campo\'s ripple ring on the water round whatever floats or swims at the surface: a duck swimming, a boat on the water or in the reeds, the bread lying on the water',
    margin: 8, edge: 6, deckMargin: 3,
    marginWhat: 'whatever rests near the shore or the dock\'s edge is on one side: on the lawn with at least `margin` px of lawn round its foot (the lowest 2 rows of its sprite); on the dock with planks under its whole foot and at least `deckMargin` px of plank to the dock\'s edge; in the water with `margin` px of water all round its foot, the ring and the thing `edge` px and more from the picture\'s edges',
    ring: { inner: .45, colour: [212, 236, 246], pato: { rx: 13, ry: 3, dy: 0 }, bote: { rx: 11, ry: 3, dy: 0 }, pan: { rx: 7, ry: 2.5, dy: 0 }, pez: { box: [-9.5, -6, 19, 11], round: 3, pad: 3, soft: 1, rim: 1, patch: [166, 210, 224], rimColour: [212, 236, 246], why: 'round 4: the fish at the surface swims in a patch of pale stirred water of its own, the old water\'s pale tone (#A6D2E0), larger than the fish on every side: e, the distance (px) from the fish\'s box [x - 9.5, y - 6, 19, 11] (its sprite either way it faces), its corners rounded (radius round), so that the patch is an oval more than a card, pale where e <= pad (3), dithered over the next soft px, the ring\'s light line on the last rim px (e 4 to 5); only where the water shows. Its whole outline, tail and fin, on pale water; every fish colour 45 and more from the 2 px band just outside its outline' },
      when: 'a duck swimming (pose nada, not in the air: dy <= 3); a boat on the water or in the reeds (en agua, juncos, carmen, or on its way: meta); the bread lying on the water (W.pan, not carried, z <= 1, its point over the water); round 3: the fish swimming at the surface (dy <= 4) has its pale patch instead (pez; leaping, it has its splash as the old)',
      how: 'every pixel (x, y) with .45 < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1 that shows the water (the set\'s surface) takes the colour: a duck\'s at (x, y) (rx scaled .78 for the yellow one), a boat\'s at (x, y + bob), the bread\'s at (x, y)' },
    lines: [
      ['function pato(c,o,a){if(!o||o.vis===0)return;', 'function pato(c,o,a){if(!o||o.vis===0)return;PREVIEW.ring(c,"pato",o);'],
      ['function bote(c,o){if(!o||o.vis===0)return;', 'function bote(c,o){if(!o||o.vis===0)return;PREVIEW.ring(c,"bote",o);'],
      ['function pez(c,o){if(!o||o.vis===0)return;', 'function pez(c,o){if(!o||o.vis===0)return;PREVIEW.patch(c,o);'],
      ['L.push({y:999,d:()=>c.drawImage(spr("pan",mkPan),R(W.pan.x)-5,R(W.pan.y)-R(W.pan.z||0)-7)});', 'L.push({y:999,d:()=>{PREVIEW.ring(c,"pan",W.pan);c.drawImage(spr("pan",mkPan),R(W.pan.x)-5,R(W.pan.y)-R(W.pan.z||0)-7);}});'],
    ],
    linesWhat: 'the lines lago.js gains: the help is drawn first, then the thing; the port draws them the same way',
  }),
  code({ lineOf, things, OLDBOX, POS }) {
    const C = [], c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const byLine = new Map(); for (const p of POS.inSceneFile) { const L = +p.at.split(':')[1]; if (!byLine.has(L)) byLine.set(L, []); byLine.get(L).push(p); }
    const NOTE = {
      [lineOf('const AGUA=118,MUELLE=')]: ['the set\'s things: the shore and the water (points.shore), the dock (points.dock), the mooring posts at the old PM tops (points.postes), the post (moved: moves), the reeds (dropped: the set\'s bed), Carmen\'s far bank (ORILLA: moved)', { points: ['shore', 'dock', 'postes', 'poste'], moves: ['POSTE', 'ORILLA'] }],
      [lineOf('const LUGAR=')]: ['the floor rule: the same screen places, on the dock', { spots: ['frog.inicio', 'frog.muelle'] }],
      [lineOf('const FX=[46,68,90]')]: ['the row of boats on the dock (moves), SALE unchanged (on the water), PEGA in the reeds (moves)', { moves: ['FX', 'PEGA'], spots: ['sale.0', 'sale.1', 'sale.2'] }],
      [lineOf('const P7=i=>')]: ['the ducks\' seven places on the water (story 20): the floor rule, unchanged', 'unchanged'],
      [lineOf('{id:"juncos",box:')]: ['the set things\' boxes (things)', { things: ['juncos', 'poste', 'muelle', 'agua', 'lago'] }],
      [lineOf('{id:"agua",box:')]: ['the water\'s and the lake\'s boxes (things.agua, things.lago)', { things: ['agua', 'lago'] }],
      [lineOf('c.drawImage(spr("lago",fondo),0,0);')]: ['dropped: the set (dropped)', { dropped: true }],
      [lineOf('KIT.escena({id:"lago"')]: ['the view (views.wide) and the heart (points.corazon): unchanged', { view: 'wide', point: 'corazon' }],
    };
    for (const [L, ps] of [...byLine.entries()].sort((a, b) => a[0] - b[0])) {
      const old = ps.map(p => (p.what || 'point').replace(/_+/g, '_') + ' ' + JSON.stringify(p.nums)).join('; ');
      if (NOTE[L]) { c(L, old, NOTE[L][1], NOTE[L][0]); continue; }
      const mv = this.moves.filter(m => LAGO_JS.split('\n')[L - 1].includes(m.src));
      const kinds = new Set(ps.map(p => /^(hopTo|mueve|patoA|aveA|pezA|boteA|panA|salpica)\(|^x:,y:|^W\.(saco|bolsa|flor)|^xs/.test(p.what || '') ? 'floor' : /^pts\[\]/.test(p.what) ? 'stars' : /^OFF|^W\.orden|^for/.test(p.what || '') ? 'offset' : 'drawing'));
      const notes = [];
      if (mv.length) notes.push('moved: ' + mv.map(m => m.src).join('; ') + ' (moves)');
      if (kinds.has('floor')) notes.push('the floor rule: every other place here keeps its screen place');
      if (kinds.has('stars')) notes.push('screen effect: the stars, unchanged');
      if (kinds.has('offset')) notes.push('offsets and orders, not places: unchanged');
      if (kinds.has('drawing')) notes.push('a sprite\'s, a card\'s or an effect\'s own drawing, relative to where it is drawn: unchanged');
      c(L, old, mv.length ? { moves: mv.map(m => m.src) } : kinds.has('floor') ? { floor: true } : 'unchanged', notes.join('; '));
    }
    for (const k of ['juncos', 'poste', 'muelle', 'agua', 'lago']) { const L = lineOf('{id:"' + k + '",box:'); if (!C.some(e => e.line === L && e.to && e.to.thing === k)) c(L, 'box ' + k + ' ' + JSON.stringify(OLDBOX[k]), { thing: k, box: things[k].box, hand: things[k].hand || null }); }
    for (const m of this.moves) for (const L of linesOf(m.src)) if (!C.some(e => e.line === L)) c(L, m.src, { moves: [m.src] }, 'moved (moves): ' + m.why.split(':')[0]);
    c(lineOf('const caja=id=>'), 'caja(id): [x - 11, y - alto(id), 22, alto(id)]', 'relative to the child: unchanged');
    c(lineOf('L.sort((m,n)=>m.y-n.y)'), 'the sorted list', { front: ['juncos', 'poste', 'muelle.postes'] }, 'entries added before the sort (front.parts), each item tagged (front.tags)');
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: lago\'s fresh() puts him at LUGAR.inicio');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', 'a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)');
    return C;
  },
});

function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2] || 0); return [r2(q.sx), r2(q.sy)]; };
  const floorW = (sx, sy) => { const s = E.surface(sx, sy); return { on: s.on, world: W4(s.w) }; };
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };

  /* ---- the floor rule: the lake and its dock are built round the old picture, so every place keeps its screen place; its world point is the
     walkable surface under it: the dock's planks (z ZD), the lawn (z 0) or the water's surface (z -WDEPTH) ---- */
  // a frog place q (juego.js frogBox: his middle q.x + 16, his feet row q.y + 25); a person's place (x, y) (their feet, lago.js gente), the dog's,
  // a duck's (its waterline or feet), a bird's (its feet), a boat's (its keel), the bag's and the sack's (their bottom row): under (x, y - 1)
  const frogW = q => floorW(q[0] + 16, q[1] + 25), personW = p => floorW(p[0], p[1] - 1);

  /* ---- the set's own things, from its pixels ---- */
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1, y1 + 1]; };
  const partsOf = name => Object.keys(G.parts[STATES[0]]).filter(p => THING_OF(p) === name);
  const partScreen = name => { const all = []; for (const p of partsOf(name)) all.push(...G.parts[STATES[0]][p]); return pxBox(all); };

  /* ---- the places that move (the floor rule keeps every other one). Each is an exact piece of lago.js source and its replacement ---- */
  const D = DESIGN;
  const MOVES = D.moves.map(m => Object.assign({ line: lineOf(m.src) }, m, { lines: linesOf(m.src) }));
  for (const m of MOVES) for (const q of m.pts || []) q.push(q[0] === 'cq' ? frogW(q[2]).world : personW(q[2]).world);
  // the old code's own drawing the engine replaces (the background; the reeds, now the set's)
  const DROPPED = [
    { src: 'c.drawImage(spr("lago",fondo),0,0);', to: '', why: 'the background: the set, for setKey(W)' },
    { src: 'JUNCOS.forEach((p,i)=>L.push({y:p[1],d:()=>c.drawImage(spr("jn"+i,()=>mkJunco(i)),p[0]-11,p[1]-33)}));', to: '', why: 'the reeds (mkJunco, in the sorted list): the set\'s bed of reeds (things.juncos); whoever is behind them has them drawn again over them (front.juncos)' },
  ].map(d => Object.assign({ line: lineOf(d.src) }, d));

  /* ---- spots ---- */
  const SPOTS = {};
  const spot = (k, at, what, kind = 'person', moved) => { const w = kind === 'cq' ? frogW(at) : personW(at); SPOTS[k] = Object.assign({ world: w.world, on: w.on, old: at.slice(0, 2), what }, kind === 'cq' ? { scale: 1 } : {}, moved ? { moved } : {}); };
  for (const [k, v] of Object.entries(OLD.LUGAR)) spot('frog.' + k, v, 'LUGAR.' + k + ': the frog on the dock', 'cq');
  for (const [k, v] of Object.entries(FROG_PLACES)) if (k !== 'inicio') spot('frog.' + k, v, 'the frog\'s place in ' + { inicio19: 'acts.inicio19', inicio20: 'acts.inicio20', ranapinta: 'acts.ranapinta (Luis\'s x - 44)', pequeno: 'd-pato-pequeno beats.1', ranaa: 'acts.ranaa (d-pato-pequeno beats.37)', hlago: 'h-lago beats.1' }[k], 'cq');
  for (const [k, v, what] of D.places) spot(k, v.old, what, 'person', v.new ? undefined : undefined);
  for (const s of Object.values(SPOTS)) { const mv = D.newPlace(s.old); s.new = mv || s.old.slice(); if (mv) { s.moved = true; const w = s.scale != null ? frogW(mv) : personW(mv); s.world = w.world; s.on = w.on; } }

  /* ---- the named points of the set ---- */
  const PTS = {
    shore: { screen: [[Math.round(E.project(F.BANK, 0, 0).sx), Math.round(E.project(F.BANK, 0, 0).sy)], [Math.round(E.project(F.BANK, 6, 0).sx), Math.round(E.project(F.BANK, 6, 0).sy)]], world: r4(F.BANK), what: 'the lake\'s shore: the line x = ' + r4(F.BANK) + ' (on the screen sx + 2 sy = ' + F.SHORE_K + '), wavering a little as El campo\'s; the lawn on its far side (up to the left), the water on its near side, its surface ' + F.WDEPTH + ' under the lawn' },
    dock: { world: [F.DECK.x0, F.DECK.y0, F.ZD, F.DECK.x1, F.DECK.y1, F.ZD].map(r4), landing: [F.LANDING.x0, F.LANDING.y0, F.LANDING.x1, F.LANDING.y1].map(r4), screen: [P([F.DECK.x0, F.DECK.y0, F.ZD]), P([F.DECK.x1, F.DECK.y0, F.ZD]), P([F.DECK.x1, F.DECK.y1, F.ZD]), P([F.LANDING.x0, F.LANDING.y1, F.ZD])], what: 'the dock\'s deck: the planks at z ' + F.ZD + ' over x ' + r4(F.DECK.x0) + ' to ' + r4(F.DECK.x1) + ', y ' + r4(F.DECK.y0) + ' to ' + r4(F.DECK.y1) + ', and its landing on the lawn (landing: x0, y0, x1, y1); screen: its far corner, its right corner, its near corner, the landing\'s left corner' },
    postes: { screen: F.PM.map(p => p.top), world: F.PM.map(p => W4([p.x, p.y, F.ZD + F.PM_H])), old: OLD.PM, what: 'the two mooring posts on the deck (the old PM, where the birds perch): their tops at the old screen points, ' + F.PM_H + ' over the planks' },
    poste: { screen: [D.POSTE[0], D.POSTE[1] - 24], foot: [D.POSTE[0], D.POSTE[1] + 8], world: W4([F.POST.x, F.POST.y, F.POST.top]), old: [OLD.POSTE[0], OLD.POSTE[1] - 24], what: 'the post in the water: its top (where the bird perches: POSTE[1] - 24) and its foot at the water (POSTE[1] + 8): moved (moves)' },
    corazon: { screen: [110, 30], old: [110, 30], what: 'heartAt: the heart of a happy ending, in the sky (unchanged)' },
    sol: { screen: F.SUN.slice(0, 2), radius: F.SUN[2], what: 'the sun: baked into the set\'s sky (El camino\'s and El campo\'s, in the same place: upper left, every shadow falls to the right), whole inside the view; no story touches it or names its place (the old sun was at the upper right)' },
    nubes: { screen: F.CLOUDS, old: [[36, 16, 1], [112, 9, .7], [168, 26, .8]], what: 'the old picture\'s three clouds (engine.js sky()), baked into the set\'s sky as El campo\'s, clear of the corner card, the sun and the answer cards\' place; no story names them' },
  };

  /* ---- things: the 19 touch keys ---- */
  const T = (name, what, extra = {}) => { const s = partScreen(name), w = boxAround(s[0], s[1], s[2], s[3]); return Object.assign({ set: true, world: W4(w), box: box(w), screen: s, what, old: { box: OLDBOX[name] } }, extra); };
  const sprite = why => ({ sprite: true, why });
  const things = {
    luis: sprite('a child (today\'s sprite, drawn 1:1). caja(id) (lago.js:' + lineOf('const caja=id=>') + '): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged'),
    carmen: sprite('as luis'),
    pato_blanco: sprite('a duck (mkPato): [x - 12, y - 17 - dy, 24, 18] where it is (lago.js:' + lineOf('const patoCosa=n=>') + '): unchanged'), pato_negro: sprite('as pato_blanco'), pato_amarillo: sprite('as pato_blanco (drawn at .78)'),
    ave_blanco: sprite('a bird (mkPajaro): [x - 10, y - 15, 20, 18] (lago.js:' + lineOf('const aveCosa=n=>') + '): unchanged'), ave_negro: sprite('as ave_blanco'),
    bote_rojo: sprite('a toy boat in the row on the dock (mkBote): [x - 10, y - 20, 20, 22] (lago.js:' + lineOf('const boteCosa=c=>') + '): unchanged; the row\'s places moved (moves: FX, FYB)'), bote_azul: sprite('as bote_rojo'), bote_verde: sprite('as bote_rojo'),
    pez: sprite('the fish (mkPez): [x - 11, y - 10 - dy, 22, 18]: unchanged'), pajaro: sprite('the blue bird (mkPajaro): [x - 10, y - 15, 20, 18]: unchanged'),
    perro: sprite('Canelo (KIT.mkPerro): [x - 14, y - 14, 28, 16]: unchanged'),
    flor: sprite('the yellow flower (W.flor, drawn by lago.js draw): [x - 5, y - 16, 10, 17]: unchanged; its place moved onto the lawn (moves)'),
    juncos: T('juncos', 'the reeds: every stalk, head and blade of the bed in the shallows'),
    poste: T('poste', 'the post standing in the water'),
    muelle: T('muelle', 'the dock: its deck, its edge, its pilings, its landing on the lawn and its two mooring posts'),
    agua: { set: true, ground: true, what: 'the water: the lake from the shore to the picture\'s edges, under the horizon', old: { box: OLDBOX.agua } },
    lago: { set: true, ground: true, what: 'the lake and its lawn: everything under the horizon; last in the hit order', old: { box: OLDBOX.lago } },
  };
  D.thingsExtra(things, { E, F, G, box, boxAround, partScreen, W4 });

  /* ---- views: one, zoom 1, the old wide window ---- */
  const views = { wide: { zoom: 1, x0: 22, world: W4(E.atZ(120, 150, 0)), region: null, old: [22, 0, 196, 216], what: 'the lake: the lawn and the shore at the back and left, the dock from the shore, the water, the post, the reeds, the sky' } };

  /* ---- the review and level pictures ---- */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(cx - 98))), Math.max(0, Math.min(112, Math.round(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(cx - 49))), Math.max(0, Math.min(164, Math.round(cy - 26))), 98, 52];
    const w = floorW(cx, cy); return { world: w.world, screen: [cx, cy], zoom, crop, what }; };
  const PICS = D.pictures(pic);
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'lago' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      const ats = p.uses.map(u => u.at);
      if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0) in a review picture: not a place'; return e; }
      const mv = D.storyMoves.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y], isFrog = ats.every(a => /\.cq$/.test(a) || /^beats\.37$/.test(a) && p.x === 104), w = isFrog ? frogW(at) : personW(at);
      e.to = { [w.on]: w.world }; e.new = at.slice(); if (mv) { e.moved = true; e.why = mv.why; }
      e.what = (isFrog ? 'the frog\'s place q (x, y): the surface under (x + 16, y + 25)' : 'a place (x, y): the surface under (x, y - 1)') + ': ' + w.on + (mv ? '; moved (why)' : '; the same screen place');
    }
    return e;
  });

  // hop counts: every pair of the frog's places, old against new
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
    key: '"lago" (one baked state)',
    baked: STATES.map(k => ({ key: k, query: '?' + queryOf(k) })),
    bakedWhy: 'order 06 found 10 states, made by five keys: bolsa (the bag of bread on the dock, mkBolsa), fila (how many pieces of bread lie in the row on the dock, mkPan), flor (the yellow flower), pincel (the brush the frog holds: drawn by rana()) and saco (the sack on the dock). Each is a thing drawn by the sprite layer (lago.js draw and rana()), none the day\'s light or the ground\'s, so they stay in the sprite layer as the old draws them (their places moved where moves says), and this one baked state draws all 10 (and every review and level picture)',
  };

  return {
    scene: 'lago',
    made: 'node docs/proyecto/pixel/lago-sheet-make.js, from lago-set.html (window.LAGO_SET) and coqui/ref/escenas/lago/. Order 35a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: D.rules(F),
    layout: D.layout(F, E),
    behind: { what: 'nothing: the sun and the clouds are baked into the set\'s sky (El camino\'s and El campo\'s); every bird, flying or perched, is drawn in front of everything as the old (its sort y + 200)', items: [] },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, on: s.on, new: s.new }, s.scale != null ? { scale: s.scale } : {}, { old: s.old }, s.moved ? { moved: true } : {}, { what: s.what })])),
    lugar,
    hops,
    hopsWhat: 'each pair of the frog\'s places (LUGAR and every place an act or a story puts him) whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all ' + hopsAll.length + ' pairs)',
    hopsAll,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'lago.js never calls clip()',
    front: D.front(F),
    shadows: D.shadows(F, DROPPED),
    dropped: DROPPED,
    moves: MOVES.map(m => Object.assign({ line: m.line }, m.lines.length > 1 ? { lines: m.lines } : {}, { act: m.act, src: m.src, to: m.to }, m.respEn ? { respEn: m.respEn } : {}, m.pts && m.pts.length ? { places: m.pts.map(q => ({ who: q[0] || 'whoever', old: q[1], new: q[2], world: q[3] })) } : {}, m.shift ? { shift: m.shift } : {}, { why: m.why })),
    helps: D.helps(F),
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as lago.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (lago.js draw: line ' + lineOf('Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a child, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the rounds) and of every face (each visible child\'s and the frog\'s, its own too); if none is, the first (the old)',
      top: 'a child: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a child 6, the frog b.w >> 1',
      faces: 'a child\'s face: [hx - 6, y - dy + top + 5, 12, 10] (eyes to chin, not the hair), hx the head\'s middle; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heads: G.M.heads,
      headsWhat: 'each sprite (idle; .s sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head + 1)',
      board: BOARD, boardWhat: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta (the rounds card) [2, 2, 68, 26]',
    },
    code: D.code({ lineOf, things, OLDBOX, POS }),
    checks: { notes: [] },
  };
}

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'lago') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'lago-sheet-'));
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

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([Math.round(hp[0]) - 12 + i * 3, Math.round(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };
const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));
const R = Math.round;

function check(sh, G, runs) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M, KEY = STATES[0];
  const NEW = G.TICKS;   // per run: { ticks, states } of the port's play
  /* the inventory */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')), cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-lago.json'), 'utf8'));
  const pairSides = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'lago').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
  const otherScene = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene !== 'lago').map(s => p.w + '.' + s + ' (' + p[s].scene + ')'));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'lago') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  // every place of lago.js has its entry in code (each line, and each line's numbers); every place an act or a move uses too
  const codeLines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!codeLines.has(L)) P.push('lago.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n.replace(/^0\./, '.')) || e.old.replace(/\s/g, '').includes(n)))) P.push('lago.js:' + L + ' ' + JSON.stringify(p.nums) + ': no code entry names these numbers'); }
  for (const m of sh.moves) { for (const L of m.lines || [m.line]) if (!LINES[L - 1].includes(m.src)) P.push('moves: line ' + L + ' does not hold ' + m.src.slice(0, 60)); for (const L of m.lines || [m.line]) if (!codeLines.has(String(L))) P.push('moves: lago.js line ' + L + ' (' + m.src.slice(0, 40) + ') has no entry in code'); }
  for (const d of sh.dropped) if (!LINES[d.line - 1].includes(d.src)) P.push('dropped: line ' + d.line + ' does not hold ' + d.src.slice(0, 60));
  for (const [a] of sh.front.tags.concat(sh.helps.lines)) if (!LAGO_JS.includes(a)) P.push('lago.js does not hold ' + a);
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places of LUGAR (old ' + Object.keys(inv.given.lugar).length + ') and ' + Object.keys(sh.spots).filter(k => k.startsWith('frog.')).length + ' frog places in all, ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-lago (' + pairSides.length + ' pictures here' + (otherScene.length ? '; ' + otherScene.join(', ') + ' another scene\'s' : '; none is another scene\'s') + '), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + pos.inSceneFile.length + ' places of lago.js and every moved line named in code, ' + STATES.length + ' baked state (the old ' + inv.states.count + ')');

  /* hops: every pair whose count changed is walked in no run (the recorded ones, and the port's play) */
  { const at = {}; for (const [k, v] of Object.entries(FROG_PLACES)) at[v.join(',')] = k; const walked = new Set();
    const walk = Ws => { let prev = null; for (const w of Ws) { const q = w.cq; if (!q || !q.vis) continue; const k = at[q.x + ',' + q.y]; if (!k) continue; if (prev && prev !== k) walked.add([prev, k].sort().join('-')); prev = k; } };
    runs.forEach((r, ri) => { walk(r.lines.map(l => l.W)); walk(NEW[ri].ticks.map(t => t.W)); });
    for (const c of sh.hops) if (walked.has([c.a, c.b].sort().join('-'))) P.push('hops: ' + c.a + '-' + c.b + ' ' + c.old + ' -> ' + c.new + ' is walked in a run');
    notes.push('hops: all ' + sh.hopsAll.length + ' pairs of the frog\'s ' + Object.keys(FROG_PLACES).length + ' places keep the old count' + (sh.hops.length ? ' but ' + sh.hops.map(c => c.a + '-' + c.b + ' ' + c.old + ' -> ' + c.new).join(', ') + ' (walked in no run)' : '') + '; his walks in the runs: ' + [...walked].sort().join(', ')); }

  /* the set's pixels */
  const TAG = (() => { const m = new Array(240 * 216).fill(null); for (const [k, list] of Object.entries(G.parts[KEY])) for (const i of list) m[i] = k; return m; })();
  const Z = G.z[KEY], K = G.kinds[KEY], RGB = G.rgb[KEY], SURF = G.surf[KEY], OG = G.onGround[KEY], WET = G.wet[KEY], SHD = G.shaded[KEY];
  const rgbAt = i => [RGB[i * 3], RGB[i * 3 + 1], RGB[i * 3 + 2]];
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];
  // each pixel's zone: d the deck's planks, e the dock's edge and pilings, x a post or a reed, l the lawn, p the bank's lip, b the bank's face,
  // w the water's surface (in the dock's shade too), s the sky
  const ZONE = []; for (let i = 0; i < 240 * 216; i++) { const t = TAG[i], s = SURF[i];
    ZONE.push(t === 'muelle' ? (s === 'd' ? 'd' : 'e') : t === 'muelle.postes' ? 'd' : t ? 'x' : s === 'p' ? 'p' : s); }
  const zoneAt = (x, y) => x < 0 || x >= 240 || y < 0 || y >= 216 ? 'out' : ZONE[y * 240 + x];

  /* every set thing's pixels inside its touch box; nothing decorative; the hit order */
  { const res = [];
    for (const name of ['muelle', 'poste', 'juncos']) { const b = sh.things[name].box; let out = 0, n = 0;
      for (const p of Object.keys(G.parts[KEY]).filter(p => THING_OF(p) === name)) for (const i of G.parts[KEY][p]) { n++; const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + name + ' are outside its touch box ' + JSON.stringify(b));
      res.push(name + ' ' + JSON.stringify(b) + ' (' + n + ' px)'); }
    for (const p of Object.keys(G.parts[KEY])) if (!sh.things[THING_OF(p)] || !sh.things[THING_OF(p)].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s');
    const ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const hitAt = (x, y) => { for (const [id, m] of ORDER) { const b = sh.things[id].box; if (x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) return id; } return null; };
    const wrong = {};
    for (const p of Object.keys(G.parts[KEY])) for (const i of G.parts[KEY][p]) { const h = hitAt(i % 240, Math.floor(i / 240)); if (h !== THING_OF(p)) { const k = p + ' -> ' + h; wrong[k] = (wrong[k] || 0) + 1; } }
    for (const [k, n] of Object.entries(wrong)) P.push('hit: ' + n + ' px of ' + k + ' (a touch there answers the other thing)');
    for (const a of ['muelle', 'poste', 'juncos']) for (const b of ['muelle', 'poste', 'juncos']) if (a < b && meets(sh.things[a].box, sh.things[b].box)) P.push('boxes: ' + a + '\'s and ' + b + '\'s overlap');
    notes.push('boxes: every pixel of each set thing inside its touch box (nothing sways: no leaf, no reed moves at any wind step): ' + res.join(', ') + '; every pixel answers its own thing in the hit order; the set\'s parts are ' + Object.keys(G.parts[KEY]).sort().join(', ') + ' (each a touch key\'s: nothing decorative); the water and the lawn are the ground of agua and lago'); }

  /* every castShadow call of the bake darkens; a thin thing casts only a short contact shadow; each shadow in one piece with its thing */
  { const byPart = {};
    for (const c of G.shadows[KEY]) { const [x, y, z, r, s] = c.args, k = c.part || '(none)';
      if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + k + ' castShadow(' + c.args.map(r2).join(', ') + '): nothing is cast');
      const b = byPart[k] = byPart[k] || { calls: 0, set: 0, dark: 0 }; b.calls++; b.set += c.set; }
    const pieces = [];
    for (const [k, b] of Object.entries(byPart)) { const sp = (G.shadowPx[KEY][k] || []).filter(i => OG[i]); b.dark = sp.length; if (!b.dark) P.push('shadow: the part ' + k + ' casts ' + b.calls + ' times and darkens nothing');
      // in one piece with its thing, and short: every shadow pixel within 4 px of the part's own pixels
      const own = new Set(G.parts[KEY][k] || []); let far = 0; for (const i of sp) { const x = i % 240, y = Math.floor(i / 240); let near = false; for (let dy = -4; dy <= 4 && !near; dy++) for (let dx = -4; dx <= 4; dx++) if (own.has((y + dy) * 240 + x + dx)) { near = true; break; } if (!near) far++; }
      if (far) P.push('shadow: ' + far + ' px of ' + k + '\'s shadow are further than 4 px from it (not one piece, or not a short contact shadow)');
      pieces.push(k + ' ' + b.calls + ' calls, ' + b.dark + ' px darkened'); }
    notes.push('shadows of the set: every castShadow call has strength 1 and a radius; each casting part darkens pixels, its shadow in one piece with it and short (a contact shadow at the foot of the thin mooring posts): ' + pieces.join('; ')); }

  /* no cast shadow on the water: the water's surface takes none (it is not ground); the dock's own shade is baked, joined to the dock */
  { let wetG = 0, nW = 0, sh0 = 0, apart = 0; for (let i = 0; i < 240 * 216; i++) { if (ZONE[i] === 'w') { nW++; if (OG[i]) wetG++; }
      if (SHD[i] && ZONE[i] === 'w') { sh0++; const x = i % 240, y = Math.floor(i / 240); let near = false; for (let dy = -9; dy <= 9 && !near; dy++) for (let dx = -9; dx <= 9; dx++) { const z = zoneAt(x + dx, y + dy); if (z === 'd' || z === 'e') { near = true; break; } } if (!near) apart++; } }
    if (wetG) P.push('water: ' + wetG + ' px of the water\'s surface take a cast shadow');
    if (apart) P.push('shade: ' + apart + ' px of the dock\'s shade on the water lie further than 9 px from the dock');
    notes.push('water: none of its ' + nW + ' px takes a cast shadow (people, animals and things cast theirs on the lawn and the planks only); the dock\'s shade, ' + sh0 + ' px on the water beside and under it, every one within 9 px of the dock'); }

  /* the water reads as water and shows as much of the lake as the old picture */
  { const sky = G.SKYB, wc = [0, 0, 0]; let n = 0, light = 0; const ws = [];
    for (let i = 0; i < 240 * 216; i++) if (ZONE[i] === 'w' && !SHD[i] && i % 240 >= x0 && i % 240 < x0 + 196) { n++; const c = rgbAt(i); for (let k = 0; k < 3; k++) wc[k] += c[k]; ws.push(c); }
    const m = wc.map(v => v / n); for (const c of ws) if (c[0] + c[1] + c[2] > (m[0] + m[1] + m[2]) * 1.35) light++;
    const dSky = Math.min(...sky.map(s => dE(m, s)));
    if (dSky < 25) P.push('water: its mean colour is within ' + Math.round(dSky) + ' of a sky band (keep 25)');
    // the old lake: lago.js fondo's water, rows AGUA + 1 on, right of the left bank (its formula), in the view, the dock over it counted (it stands
    // on the water); open: the old picture's water pixels (s000 without characters: what shows of it, the dock, its posts and the reeds left out)
    let oldLake = 0, oldOpen = 0, now = 0, open = 0;
    for (let y = OLD.AGUA + 1; y < 216; y++) { const bw = 44 - R((y - OLD.AGUA) * .12) + R(Math.sin(y / 9) * 3); for (let x = Math.max(x0, bw); x < x0 + 196; x++) { oldLake++; const j = (y * 240 + x) * 4, c = [M.old[j], M.old[j + 1], M.old[j + 2]]; if (c[2] > c[0] + 20 && c[2] >= c[1]) oldOpen++; } }
    for (let y = 0; y < 216; y++) for (let x = x0; x < x0 + 196; x++) { const i = y * 240 + x; if (WET[i]) now++; if (ZONE[i] === 'w') open++; }
    if (now < oldLake) P.push('water: the lake shows ' + now + ' px in the view, the old ' + oldLake + ' (keep 100%)');
    notes.push('water: El campo\'s (mean ' + m.map(Math.round) + ', ' + Math.round(dSky) + ' from the nearest sky band; ' + Math.round(light / n * 1000) / 10 + '% ripples; ' + G.glints[KEY].length + ' glints, none in the dock\'s shade); the lake in the view (every pixel whose ground is past the shore, the dock over it counted, as the old dock over the old water) ' + now + ' px against the old ' + oldLake + ' (' + Math.round(now / oldLake * 100) + '%); open water shown ' + open + ' px against the old ' + oldOpen + ' (' + Math.round(open / oldOpen * 100) + '%): the deck covers more of it than the old strip of a dock did'); }

  /* the old sprite layer's shapes, at a moment */
  const alto = (id, p) => p && p.sent ? 40 : 44;
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const people = w => Object.entries(w.gente || {}).filter(([id, p]) => shown(p));
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const poseOf = p => p.pose === 'wave' ? 'wave0' : p.pose === 'arriba' ? 'wave0' : ['offer', 'yo', 'tu', 'wave0', 'wave1', 'ojos'].includes(p.pose) ? p.pose : 'idle';
  const personRows = (id, p) => rowsAt(M.masks[id + '.' + poseOf(p) + '.' + (p.dir < 0 ? -1 : 1) + (p.sent ? '.s' : '')], R(p.x), R(p.y) - R(p.dy || 0));
  const dogRows = o => rowsAt(M.animals['perro.' + (M.animals['perro.' + o.pose + '.0.1'] ? o.pose : 'sit') + '.0.' + (o.dir < 0 ? -1 : 1)], R(o.x), R(o.y) - R(o.dy || 0));
  const duckPose = o => o.aletea ? 'vuela' : (o.pose || 'nada');
  const duckRows = o => rowsAt(M.animals['pato.' + o.k + '.' + duckPose(o) + '.0.' + (o.dir < 0 ? -1 : 1)], R(o.x), R(o.y) - (o.dy || 0));
  const birdRows = o => rowsAt(M.animals['ave.' + o.c + '.' + (o.vuela || o.aletea ? 1 : 0) + '.0.' + (o.dir < 0 ? -1 : 1)], R(o.x), R(o.y) - (o.dy || 0));
  const boatRows = o => rowsAt(M.animals['bote.' + o.c + '.' + (o.en === 'juncos' ? 1 : 0)], R(o.x), R(o.y));
  const fishRows = o => rowsAt(M.animals['pez.' + o.c + '.' + ((o.dy || 0) > 4 ? 1 : 0) + '.' + (o.dir < 0 ? -1 : 1)], R(o.x), R(o.y) - R(o.dy || 0));
  const breadRows = (x, y) => rowsAt(M.things.pan, x, y);
  const frogRows = q => { const b = frogBox(q), rs = []; for (let y = b.y + R(q.dy || 0); y < b.y + R(q.dy || 0) + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]); return rs; };
  const faceOf = (id, p) => { const hd = sh.talk.heads[id + (p.sent ? '.s' : '')], x = R(p.x), y = R(p.y) - R(p.dy || 0), hx = p.dir < 0 ? x - hd.head + 1 : x + hd.head; return [R(hx - 6), y + hd.top + 5, 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + R(q.dy || 0), b.w - 4, R(b.h * .6)]; };
  const facesOf = w => { const f = people(w).filter(([id, p]) => !(p.al != null && p.al < .5)).map(([id, p]) => [id + '\'s face', faceOf(id, p)]); if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };
  const rowsOverlap = (A, B) => { const S = new Set(); for (const [y, a, b] of A) for (let x = a; x <= b; x++) S.add(y * 240 + x); let n = 0; for (const [y, a, b] of B) for (let x = a; x <= b; x++) if (S.has(y * 240 + x)) n++; return n; };
  const vSurf = (sx, sy) => { const w = E.surface(sx, sy).w; return (w[0] + w[1]) / E.R2; };
  const nearerRows = (rs, v, names) => { const out = {};
    for (const [y, a, b] of rs) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (names.includes(TAG[i]) && !(TAG[i] === 'muelle' && ZONE[i] === 'd') && Z[i] > v / COS - (y + .5 - E.OY) * T30 / E.S) out[TAG[i]] = (out[TAG[i]] || 0) + 1; } }
    return out; };
  const breadPlace = (() => { const m = sh.moves.find(m => m.src.includes('36+i*12-5')).to.match(/mkPan\),(.*),([^,]*)\)\}\)$/), f = new Function('i', 'FY', 'return [(' + m[1] + ')+5,(' + m[2] + ')+10];'); return i => f(i, 165); })();
  const perchAt = o => { const P2 = sh.points; return P2.postes.screen.map(t => [t[0], t[1] - 1]).concat([P2.poste.screen]).find(t => Math.abs(R(o.x) - t[0]) <= 2 && Math.abs(R(o.y) - t[1]) <= 2); };

  // everything shown at a moment, as items: who, kind, rows, foot point, state
  const itemsOf = w => { const it = [];
    for (const [id, p] of people(w)) it.push({ id, kind: 'person', rows: personRows(id, p), at: [R(p.x), R(p.y)], air: R(p.dy || 0) > 3 });
    if (w.cq && w.cq.vis && !(w.cq.al <= .3)) { const b = frogBox(w.cq); it.push({ id: 'the frog', kind: 'frog', rows: frogRows(w.cq), at: [b.x + b.w / 2, w.cq.y + 26], air: R(-(w.cq.dy || 0)) > 3 || w.cq.y < 100 }); }
    if (w.perro && w.perro.vis !== 0 && w.perro.x != null) it.push({ id: 'perro', kind: 'dog', rows: dogRows(w.perro), at: [R(w.perro.x), R(w.perro.y)], air: R(w.perro.dy || 0) > 3 });
    for (const [k, o] of Object.entries(w.patos || {})) if (o && o.vis !== 0 && o.x != null) it.push({ id: 'pato ' + k, kind: 'duck', o, rows: duckRows(o), at: [R(o.x), R(o.y)], air: o.pose === 'vuela' || (o.dy || 0) > 3 || o.ronda });
    for (const [k, o] of Object.entries(w.aves || {})) if (o && o.vis !== 0 && o.x != null) it.push({ id: 'ave ' + k, kind: 'bird', o, rows: birdRows(o), at: [R(o.x), R(o.y)], air: !!(o.vuela || o.ronda || o.sale) || R(o.y) < F.HZ, perch: perchAt(o) });
    for (const [k, o] of Object.entries(w.botes || {})) if (o && o.vis !== 0 && o.x != null) it.push({ id: 'bote ' + k, kind: 'boat', o, rows: boatRows(o), at: [R(o.x), R(o.y)] });
    for (const [k, o] of Object.entries(w.peces || {})) if (o && o.vis !== 0 && o.x != null) it.push({ id: 'pez ' + k, kind: 'fish', o, rows: fishRows(o), at: [R(o.x), R(o.y)], air: (o.dy || 0) > 4 });
    for (let i = 0; i < (w.fila || 0); i++) { const p = breadPlace(i); it.push({ id: 'pan fila.' + i, kind: 'bread', rows: breadRows(p[0], p[1] - 3), at: p }); }
    if (w.pan && w.pan.con == null && w.pan.vis !== 0 && w.pan.x != null) it.push({ id: 'pan', kind: 'bread', o: w.pan, rows: breadRows(R(w.pan.x), R(w.pan.y) - R(w.pan.z || 0)), at: [R(w.pan.x), R(w.pan.y) + 2], air: (w.pan.z || 0) > 1 });
    if (w.bolsa) it.push({ id: 'bolsa', kind: 'bag', rows: rowsAt(M.things.bolsa, w.bolsa[0], w.bolsa[1]), at: [w.bolsa[0], w.bolsa[1] + 1] });
    if (w.saco) it.push({ id: 'saco', kind: 'sack', rows: rowsAt(M.things.saco, w.saco[0], w.saco[1]), at: [w.saco[0], w.saco[1] + 1] });
    if (w.flor) it.push({ id: 'flor', kind: 'flower', rows: rowsAt(M.things.flor, w.flor[0], w.flor[1]), at: [w.flor[0], w.flor[1] + 1] });
    return it; };
  const footOf = rs => { const last = Math.max(...rs.map(r => r[0])); return rs.filter(r => r[0] >= last - 1); };
  const ringOf = it => { const RG = sh.helps.ring, o = it.o;
    if (it.kind === 'duck') { if (it.air || duckPose(o) !== 'nada' && !o.aletea) return null; const s = o.k === 'amarillo' ? .78 : 1; return [R(o.x), R(o.y), RG.pato.rx * s, RG.pato.ry]; }
    if (it.kind === 'boat') return o.en === 'muelle' ? null : [R(o.x), R(o.y), RG.bote.rx, RG.bote.ry];
    if (it.kind === 'fish') return it.air ? null : [R(o.x), R(o.y), RG.pez.rx, RG.pez.ry];
    if (it.kind === 'bread' && o && !it.air && E.surface(R(o.x), R(o.y) - 1).on === 'water') return [R(o.x), R(o.y), RG.pan.rx, RG.pan.ry];
    return null; };
  // round 4: the fish's patch (lago-preview.html PREVIEW.patchAt): its colour at a pixel, or null; its pixels; the 2 px band just outside the fish's
  // outline as drawn (the patch where it paints and the water shows, else the set), against the fish (CIE76)
  const patchAt = (o, x, y) => { const H = sh.helps.ring.pez, b = H.box, q = H.round, X0 = R(o.x) + b[0] + q, Y0 = R(o.y) + b[1] + q, dx = Math.max(0, X0 - (x + .5), (x + .5) - (X0 + b[2] - 2 * q)), dy = Math.max(0, Y0 - (y + .5), (y + .5) - (Y0 + b[3] - 2 * q)), e = Math.hypot(dx, dy) - q;   // its box with rounded corners (radius round + its distance)
    if (e <= H.pad) return H.patch; if (e <= H.pad + H.soft) { const B = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5][(y & 3) * 4 + (x & 3)] / 16; return B < 1 - (e - H.pad) / H.soft ? H.patch : null; }
    if (e <= H.pad + H.soft + H.rim) return H.rimColour; return null; };
  const patchPx = o => { const H = sh.helps.ring.pez, b = H.box, out = []; for (let y = Math.floor(R(o.y) + b[1] - 6); y <= Math.ceil(R(o.y) + b[1] + b[3] + 6); y++) for (let x = Math.floor(R(o.x) + b[0] - 6); x <= Math.ceil(R(o.x) + b[0] + b[2] + 6); x++) if (patchAt(o, x, y)) out.push([x, y]); return out; };
  const fishWorst = {}; let fishN = 0;
  const fishBand = it => { if (it.at[0] < x0 + 10 || it.at[0] > x0 + 186) return;   // a fish entering or leaving the view: its band is not in the picture
    const o = it.o, own = new Set(); for (const [y, a, b] of it.rows) for (let x = a; x <= b; x++) own.add(y * 240 + x); const sum = [0, 0, 0]; let n = 0;
    for (const [y, a, b] of it.rows) for (let x = a - 2; x <= b + 2; x++) for (let dy = -2; dy <= 2; dy++) { const yy = y + dy, i = yy * 240 + x; if (own.has(i) || x < 0 || x >= 240 || yy < 0 || yy >= 216) continue; own.add(i);
      if (zoneAt(x, yy) !== 'w') continue;   // the water round it (a post or the dock beside it is not)
      const c = patchAt(o, x, yy) || rgbAt(i); for (let k = 0; k < 3; k++) sum[k] += c[k]; n++; }
    const d = dE(M.colours['pez.' + o.c], sum.map(v => v / n)); fishN++; if (!(o.c in fishWorst) || d < fishWorst[o.c][0]) fishWorst[o.c] = [d, it.at.join(',')]; };
  const ringPx = (cx, cy, rx, ry) => { const out = []; for (let y = Math.floor(cy - ry - 1); y <= Math.ceil(cy + ry + 1); y++) for (let x = Math.floor(cx - rx - 1); x <= Math.ceil(cx + rx + 1); x++) { const d = ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2; if (d > sh.helps.ring.inner && d <= 1) out.push([x, y]); } return out; };
  const OLD_DOCK = [OLD.MUELLE[0] - 12, OLD.MUELLE[1] - 12, OLD.MUELLE[2] + 24, OLD.MUELLE[3] + 40];   // the old dock, its face and its posts, with a margin
  // on which side a foot is: the lawn (lawn within m px), the dock (planks under it and within mD px), the water (water within m px of its
  // middle and within 2 px of the whole foot; the dock's edge and pilings allowed further than 2 px where the old picture had it by the dock)
  const sideOf = (foot, at, reeds) => { const m = sh.helps.margin, mD = sh.helps.deckMargin; let land = true, dock = true, water = true;
    for (const [y, a, b] of foot) for (let x = a - m; x <= b + m; x++) for (let dy = -m; dy <= m; dy++) { const dx = x < a ? a - x : x > b ? x - b : 0; if (dx * dx + dy * dy > m * m) continue; const z = zoneAt(x, y + dy); if (z !== 'out' && z !== 'l') land = false; }
    for (const [y, a, b] of foot) for (let x = a - mD; x <= b + mD; x++) for (let dy = -mD; dy <= mD; dy++) { const dx = x < a ? a - x : x > b ? x - b : 0; if (dx * dx + dy * dy > mD * mD) continue; const z = zoneAt(x, y + dy); if (z !== 'd') dock = false; }
    const byDock = within([at[0], at[1], 1, 1], OLD_DOCK), ok = z => z === 'w' || z === 'out' || (byDock && z === 'e') || (reeds && z === 'x');
    { const last = foot[foot.length - 1], cx = R((last[1] + last[2]) / 2), cy = last[0];
      for (let x = cx - m; x <= cx + m; x++) for (let dy = -m; dy <= m; dy++) { if ((x - cx) ** 2 + dy * dy > m * m) continue; if (!ok(zoneAt(x, cy + dy))) water = false; } }
    for (const [y, a, b] of foot) for (let x = a - 2; x <= b + 2; x++) for (let dy = -2; dy <= 2; dy++) { const z = zoneAt(x, y + dy); if (z !== 'w' && z !== 'out' && !(reeds && z === 'x')) water = false; }
    return land ? 'land' : dock ? 'dock' : water ? 'water' : 'across'; };
  const WANT = { person: ['land', 'dock'], frog: ['land', 'dock'], dog: ['land', 'dock'], bag: ['dock', 'land'], sack: ['dock', 'land'], flower: ['land'], bread: ['dock', 'land', 'water'], bird: ['land', 'dock'], duck: null, boat: null, fish: ['water'] };
  const want = it => it.kind === 'duck' ? (ringOf(it) ? ['water'] : ['land', 'dock']) : it.kind === 'boat' ? ['dock', 'water'] : WANT[it.kind];

  /* the port's play: at every tick inside the acts and every step's end, and in every pair picture */
  const reedSeen = new Map();
  const REST_MS = 300, sides = new Map(), across = new Map(), ringBad = new Map(), perchBad = new Map(), hidden = new Map(), behind = new Map(), fishBad = new Map(), stats = { ticks: 0, rest: 0, rings: 0, worstRing: 1, edge: 99, perched: 0, fishUnder: 0, fishUp: 0 };
  const look = (where, w, dwell, crop) => {
    for (const it of itemsOf(w)) {
      const resting = !dwell || dwell[it.id + '@' + it.at.join(',')] >= REST_MS;
      // a bird on a post's top: the post under its feet
      if (it.kind === 'bird' && it.perch) { stats.perched++; const fx = R(it.o.x), fy = R(it.o.y); let n = 0; for (let x = fx - 2; x <= fx + 2; x++) for (let y = fy; y <= fy + 2; y++) { const t = TAG[y * 240 + x]; if (t === 'muelle.postes' || t === 'poste') n++; } if (n < 4) perchBad.set(it.id + ' at ' + it.at, where + ': only ' + n + ' px of post under its feet'); continue; }
      // the fish: under the surface, every pixel of it over open water; or leaping
      if (it.kind === 'fish') { if (it.air) { stats.fishUp++; continue; } stats.fishUnder++;
        { let n = 0, on = 0, shd = 0; stats.rings++;   // its pale patch: on the water, out of the dock's shade
          for (const [x, y] of patchPx(it.o)) { n++; const z = zoneAt(x, y); if (z === 'w' || z === 'out') on++; if (z === 'w' && SHD[y * 240 + x]) shd++; }
          fishBand(it); 
          if (resting) { stats.worstRing = Math.min(stats.worstRing, on / n); if (on < .9 * n) ringBad.set(it.id + ' at ' + it.at, Math.round(on / n * 100) + '% of its patch on the water, ' + where); }
          let own = 0; for (const [y, a, b] of it.rows) for (let x = a; x <= b; x++) if (zoneAt(x, y) === 'w' && SHD[y * 240 + x]) own++;
          if (resting && shd) fishBad.set(it.id + ' at ' + it.at + ' (shade)', where + ': ' + shd + ' px of its patch in the dock\'s shade'); if (own) fishBad.set(it.id + ' at ' + it.at + ' (path)', where + ': ' + own + ' px of it in the dock\'s shade'); } let bad = 0; for (const [y, a, b] of it.rows) for (let x = a; x <= b; x++) { const z = zoneAt(x, y); if (z !== 'w' && z !== 'out') bad++; } if (bad && resting) fishBad.set(it.id + ' at ' + it.at, where + ': ' + bad + ' px of it over something but the water'); continue; }
      if (it.air) continue;
      // a set thing nearer than it inside its sprite: the dock never (nobody under or behind the deck); the reeds, the post, the mooring posts are front parts
      { const v = vSurf(it.at[0], it.at[1] - 1), near = nearerRows(it.rows, v, SOLID);
        for (const [part, n] of Object.entries(near)) { if (sh.front.parts[part]) { const k = it.id + ' at ' + it.at + ' behind ' + part; behind.set(k, Math.max(behind.get(k) || 0, n)); if (part === 'juncos' && resting) { const tot = it.rows.reduce((a, q) => a + q[2] - q[1] + 1, 0), seenF = 1 - n / tot, kk = it.id + ' at ' + it.at; reedSeen.set(kk, Math.min(reedSeen.has(kk) ? reedSeen.get(kk) : 1, seenF)); } continue; } if (resting) hidden.set(it.id + ' at ' + it.at, where + ': ' + n + ' px of ' + part + ' nearer than it inside its sprite'); } }
      const ring = ringOf(it);
      if (ring) { stats.rings++; const rp = ringPx(...ring), on = rp.filter(([x, y]) => zoneAt(x, y) === 'w' || (it.kind === 'boat' && zoneAt(x, y) === 'x' && TAG[y * 240 + x] === 'juncos')).length / rp.length;
        if (resting) { stats.worstRing = Math.min(stats.worstRing, on); if (on < .9) ringBad.set(it.id + ' at ' + it.at, Math.round(on * 100) + '% of its ring on the water, ' + where); } }
      if (!resting) continue;
      stats.rest++;
      const side = sideOf(footOf(it.rows), it.at, it.kind === 'boat'), wantS = want(it); sides.set(it.id + ' at ' + it.at, side);
      if (side === 'across' || !wantS.includes(side)) across.set(it.id + ' at ' + it.at + ' (' + side + ')', where);
      if (side === 'water') { const rb = rowsBox(it.rows), E6 = sh.helps.edge, bx = crop || VIEW, r = ring ? [ring[0] - ring[2], ring[1] - ring[3], 2 * ring[2], 2 * ring[3]] : rb, L2 = Math.min(rb[0], r[0]), T2 = Math.min(rb[1], r[1]), R2_ = Math.max(rb[0] + rb[2], r[0] + r[2]), B2 = Math.max(rb[1] + rb[3], r[1] + r[3]);
        if (!crop) { const e = Math.min(L2 - bx[0], bx[0] + bx[2] - R2_, B2 > 0 ? 216 - B2 : 99); stats.edge = Math.min(stats.edge, e); if (e < E6) across.set(it.id + ' at ' + it.at + ' (within ' + E6 + ' px of the view\'s edge)', where); } }
    } };
  const posOf = w => { const o = {}; for (const it of itemsOf(w)) o[it.id] = it.at; return o; };
  runs.forEach((r, ri) => { const T = NEW[ri].ticks, P0 = T.map(t => posOf(t.W)), dwell = P0.map(() => ({}));
    for (let i = 0; i < T.length; i++) for (const [id, p] of Object.entries(P0[i])) { const key = id + '@' + p.join(','); if (i > 0 && P0[i - 1][id] && P0[i - 1][id].join(',') === p.join(',')) { dwell[i][key] = dwell[i - 1][key]; continue; }
      let j = i; while (j + 1 < T.length && P0[j + 1][id] && P0[j + 1][id].join(',') === p.join(',')) j++; dwell[i][key] = (j + 1 < T.length ? T[j + 1].t : T[j].t + REST_MS) - T[i].t; }
    for (let i = 0; i < T.length; i++) { stats.ticks++; look(r.story.id + ' ' + r.plan + ' t ' + T[i].t, T[i].W, dwell[i]); }
    for (const L of NEW[ri].states) look(r.story.id + ' ' + r.plan + ' ' + L.path, L.W, {}); });
  if (process.env.LAGO_ZONE) for (const q of process.env.LAGO_ZONE.split(';')) { const [x, y] = q.split(',').map(Number); for (let yy = y - 6; yy <= y + 6; yy++) { let l = ''; for (let xx = x - 20; xx <= x + 20; xx++) l += zoneAt(xx, yy); console.log(yy + ' ' + l); } console.log(''); }
  // the pair pictures, through the sheet's remap
  const pairW = ps => { const base = { gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, patos: {}, aves: {}, botes: {}, peces: {} }, w = Object.assign(base, JSON.parse(JSON.stringify(ps.spec.set || {})));
    const mv = o => { const m = sh.remap.find(e => e.moved && e.kind === 'point' && e.old[0] === R(o.x) && e.old[1] === R(o.y) && e.uses.some(u => u.startsWith('cual-lago.json'))); if (m) { o.x = m.new[0]; o.y = m.new[1]; } };
    for (const k of ['patos', 'aves', 'botes', 'peces']) for (const o of Object.values(w[k] || {})) mv(o); if (w.pan) mv(w.pan); return w; };
  for (const ps of pairSides) look('pair ' + deacc(ps.w) + '.' + ps.side, pairW(ps), null, sh.pictures[deacc(ps.w) + '.' + ps.side].crop);
  for (const [k, where] of across) P.push('side: ' + k + ' (' + where + ')');
  for (const [k, why] of ringBad) P.push('ring: ' + k + ': ' + why);
  for (const [k, why] of perchBad) P.push('perch: ' + k + ' ' + why);
  for (const [k, why] of hidden) P.push('hidden: ' + k + ' ' + why);
  for (const [k, why] of fishBad) P.push('fish: ' + k + ' ' + why);
  const bySide = s => [...new Set([...sides].filter(e => e[1] === s).map(e => e[0].replace(/ at .*/, '')))].sort().join(', ');
  notes.push('sides: ' + stats.ticks + ' ticks inside the acts of the port\'s play of the ' + runs.length + ' runs, every step\'s end and every pair picture: ' + stats.rest + ' rests (' + REST_MS + ' ms or more in one place), each clearly on one side: on the lawn with ' + sh.helps.margin + ' px of lawn round its foot (' + bySide('land') + '), on the dock with planks under its whole foot and ' + sh.helps.deckMargin + ' px of plank to the edge (' + bySide('dock') + '), in the water with ' + sh.helps.margin + ' px of water round it (' + bySide('water') + '), whatever floats ' + stats.edge + ' px at least from the view\'s edges');
  notes.push('rings: ' + stats.rings + ' moments of a duck swimming, a boat on the water or the bread on it, each with its ring (resting ones ' + Math.round(stats.worstRing * 100) + '% on the water at the least); the fish under the surface over open water (' + stats.fishUnder + ' moments) or leaping with its splash (' + stats.fishUp + ')');
  notes.push('perches: ' + stats.perched + ' moments of a bird on a post\'s top (the mooring posts\' or the post\'s), each with the post under its feet; behind a front part, drawn over them by front: ' + ([...behind.entries()].map(([k, n]) => k + ' (' + n + ' px)').join(', ') || 'no one') + '; nobody has the deck or its pilings nearer than them');

  /* bubbles, boards, the sun */
  let nM = 0, nB = 0, worstView = 99; const seen = new Set();
  const SUNR = [F.SUN[0] - F.SUN[2] - 2, F.SUN[1] - F.SUN[2] - 2, 2 * F.SUN[2] + 4, 2 * F.SUN[2] + 4];
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } return bubRect(k, top[0], top[1]); };
  const bubblesOf = (w, view = VIEW) => { const out = [], boards = boardsOf(w, view[0]), faces = facesOf(w);
    for (const [id, p] of people(w)) { if (p.al != null && p.al < .5) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor');
      for (const k of ks) out.push([id + ' "' + k + '"', talk(k, [R(p.x), R(p.y) - alto(id, p) - 1], view, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5) && q.bub) { const b = frogBox(q); out.push(['the frog "' + q.bub + '"', talk(q.bub, [b.x + (b.w >> 1), b.y + 2], view, boards, faces, b.w >> 1)]); }
    return out; };
  const allW = []; runs.forEach((r, ri) => { for (const t of NEW[ri].ticks) allW.push([r.story.id + ' ' + r.plan + ' t ' + t.t, t.W]); for (const L of NEW[ri].states) allW.push([r.story.id + ' ' + r.plan + ' ' + L.path, L.W]); });
  for (const [where, w] of allW) { nM++; const boards = boardsOf(w, x0), faces = facesOf(w);
    for (const [bn, b] of boards) if (meets(SUNR, b)) P.push('sun: ' + where + ': ' + bn + ' covers the sun');
    for (const [who, rect] of bubblesOf(w)) { const key = JSON.stringify([who, rect, boards, faces]); if (seen.has(key)) continue; seen.add(key); nB++;
      if (!within(rect, VIEW)) { P.push('bubble: ' + where + ' ' + who + ' ' + JSON.stringify(rect) + ' is not wholly inside the view'); continue; }
      worstView = Math.min(worstView, rect[0] - x0, x0 + 196 - rect[0] - rect[2], rect[1], 216 - rect[1] - rect[3]);
      for (const [bn, b] of boards) if (meets(rect, b)) P.push('bubble: ' + where + ' ' + who + ' is over ' + bn);
      for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + who + ' is on ' + fn); } }
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments (each child\'s recorded one and "amor" when touched, the frog\'s): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the rounds card, on no face');

  /* the asks: hint frames, the hand, the answer cards; the things a learner must tell apart */
  const cajaBox = (id, p) => [R(p.x) - 11, R(p.y) - alto(id, p), 22, alto(id, p)];
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) return old ? t.old.box : (t.hintBox || t.box);
    let m;
    if ((m = k.match(/^pato_(.+)$/))) { const o = (w.patos || {})[m[1]]; return o && o.vis !== 0 ? [R(o.x) - 12, R(o.y) - 17 - (o.dy || 0), 24, 18] : null; }
    if ((m = k.match(/^ave_(.+)$/))) { const o = (w.aves || {})[m[1]]; return o && o.vis !== 0 ? [R(o.x) - 10, R(o.y) - 15, 20, 18] : null; }
    if ((m = k.match(/^bote_(.+)$/))) { const o = (w.botes || {})['f_' + m[1]]; return o ? [R(o.x) - 10, R(o.y) - 20, 20, 22] : null; }
    if (k === 'pez') { const o = (w.peces || {}).a; return o && o.vis !== 0 ? [R(o.x) - 11, R(o.y) - 10 - (o.dy || 0), 22, 18] : null; }
    if (k === 'pajaro') { const o = (w.aves || {}).a; return o && o.vis !== 0 ? [R(o.x) - 10, R(o.y) - 15, 20, 18] : null; }
    if (k === 'perro') return w.perro ? [R(w.perro.x) - 14, R(w.perro.y) - 14, 28, 16] : null;
    if (k === 'flor') return w.flor ? [w.flor[0] - 5, w.flor[1] - 16, 10, 17] : null;
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? cajaBox(k, p) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !old) return t.hand; const b = boxOf(w, k, old); return b ? [R(b[0] + b[2] / 2), R(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [R(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [R(cx - 50), y, 40, 36] : [R(cx + 10), y, 40, 36]; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const TELL = /^(pato_|ave_|bote_|pajaro$|pez$)/;
  let nF = 0, nC = 0, worstF = 99, cardSpare = 99, nTell = 0, boatWater = 99; const askSeen = new Set(), askedFor = new Set(), cardHand = new Set(), crossedOld = new Set(), handOld = new Set();
  const waterMean = (() => { let n = 0, s = [0, 0, 0]; for (let i = 0; i < 240 * 216; i++) if (ZONE[i] === 'w' && !SHD[i]) { n++; for (let c = 0; c < 3; c++) s[c] += RGB[i * 3 + c]; } return s.map(v => v / n); })();
  for (const c of ['rojo', 'azul', 'verde']) boatWater = Math.min(boatWater, dE(M.colours['bote.' + c], waterMean));
  if (boatWater < 25) P.push('boats: a boat\'s colour stands out from the water by only ' + Math.round(boatWater));
  runs.forEach((r, ri) => { const Ls = NEW[ri].states, Lo = r.lines;
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = JSON.parse(JSON.stringify(Ls[j - 1].W)), jo = Lo.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')), wo = jo > 0 ? Lo[jo - 1].W : w;
      const st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      let spot = null, opts = [];
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); opts = [spot]; }
      else if (st.decide) { opts = st.options.map(sb); const bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || opts[0]; if (st.decide === 'say') w.resp = opts; else if (bur.length) w.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', key = JSON.stringify([spot, opts, w.gente, w.cq, w.resp, w.patos, w.aves, w.botes, w.peces, w.tarjeta, w.respEn]);
      if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), facesOld = facesOf(wo), items = itemsOf(w);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        { const fr2 = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; if (meets(SUNR, fr2)) P.push('sun: ' + where + ' the card ' + k + ', its frame or its glow covers the sun'); }   // round 3: the glow too
        { const f = [c[0] - 16, c[1] - 16, c[2] + 32, c[3] + 32]; cardSpare = Math.min(cardSpare, f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3]); if (!within([f[0] - 4, f[1] - 4, f[2] + 8, f[3] + 8], VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ': its lit frame and glow are not 4 px inside the view'); }
        const c2 = [c[0] - 2, c[1] - 2, c[2] + 4, c[3] + 4];
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c2, bb)) P.push('cards: ' + where + ' the card ' + k + ' is not 2 px clear of ' + bn);
        for (const it of items) { if (it.kind === 'frog') { const f = frogBox(w.cq); if (meets(c, [f.x + 2, f.y + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' covers the frog'); continue; }
          const n = rowsMeet(it.rows, it.kind === 'person' ? c2 : c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + it.id + (it.kind === 'person' ? ' (2 px round the card)' : '')); }
        for (const name of ['poste', 'muelle']) for (const p of Object.keys(G.parts[KEY]).filter(p => THING_OF(p) === name)) { const n = G.parts[KEY][p].filter(i => meets([i % 240, Math.floor(i / 240), 1, 1], c)).length; if (n > 3) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + p); } }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, [x0 + 2, 2, 192, 212])) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view with 2 px to spare'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' (the old frame did not)'); else crossedOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      if (!hp) { P.push('hand: ' + where + ' no place for the hand at ' + spot); return; }
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb && fn === 'the frog\'s face') { cardHand.add(spot); continue; }
        const ho = rb ? null : handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1])) { handOld.add(where.replace(/ (right|wrong|alternate) /, ' ') + ': on ' + fn); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
      // the things a learner must find, tell apart or count, at this ask: each whole in the view, apart from the others where the old had
      // them apart, on a plain backdrop (water, lawn, planks or sky, or the post it perches on round it)
      const tell = items.filter(it => opts.some(o => TELL.test(o)) && ['duck', 'bird', 'boat', 'fish'].includes(it.kind) && !(it.kind === 'boat' && !/^f_/.test(it.id.split(' ')[1])));
      const itemsO = itemsOf(wo);
      for (const a of tell) { nTell++; const bxA = rowsBox(a.rows);
        if (!within(bxA, VIEW)) P.push('tell: ' + where + ' ' + a.id + ' ' + JSON.stringify(bxA) + ' is not whole in the view');
        let n = 0, ok = 0; const own = new Set(); for (const [y, x1, x2] of a.rows) for (let x = x1; x <= x2; x++) own.add(y * 240 + x);
        for (const [y, x1, x2] of a.rows) for (let x = x1 - 2; x <= x2 + 2; x++) for (const dy of [-2, 0, 2]) { const i = (y + dy) * 240 + x; if (own.has(i)) continue; const z = zoneAt(x, y + dy); if (z === 'out') continue; n++; if ('wlds'.includes(z) || (a.perch && z === 'x')) ok++; }
        if (n && ok < n * .85) P.push('tell: ' + where + ' ' + a.id + ' at ' + a.at + ': only ' + Math.round(ok / n * 100) + '% of what is round it is plain water, lawn, planks or sky');
        for (const b2 of tell) if (a.id < b2.id) { const nn = rowsOverlap(a.rows, b2.rows); if (!nn) continue; const ao = itemsO.find(x => x.id === a.id), bo2 = itemsO.find(x => x.id === b2.id); if (ao && bo2 && rowsOverlap(ao.rows, bo2.rows)) continue; P.push('tell: ' + where + ' ' + a.id + ' and ' + b2.id + ' overlap by ' + nn + ' px (apart in the old picture)'); } }
    }); });
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- 12) inside the view with 2 px to spare (' + worstF + ' at the least; the things that run off the picture by their hintBox), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.size ? ' (as the old: ' + [...crossedOld].join('; ') + ')' : '') + ', the hint hand on no face' + (handOld.size ? ' (but as the old: ' + [...handOld].join('; ') + ')' : '') + '; ' + nC + ' answer cards, each with its lit frame and glow 4 px and more inside the view (' + (cardSpare) + ' at the least), 2 px clear of the rounds card and of everyone\'s head and body, over no duck, bird, boat, fish, bread, the post or the dock, the sun under none; ' + nTell + ' times a duck, a bird, a boat or the fish a learner must tell apart: whole in the view, on plain water, lawn, planks or sky, apart where the old had them apart; a boat\'s colour against the water ' + Math.round(boatWater) + ' at the least (CIE76)');
  if (cardHand.size) notes.push('NOT the scene\'s: the hand juego.js draws at an answer card reaches onto the frog\'s face where the cards are over him (respBox and hand() are the game\'s): at the asks for ' + [...cardHand].join(', '));

  /* round 2, point 1: the boats Luis sends reach Carmen: at every moment a boat has arrived (en carmen), its distance to Carmen's feet is no
     more than the old picture's for the same slot (the old slotC(i) to the old Carmen, ORILLA + (18, 1)) + 10 px; the row's neighbours 6 px apart
     at the least (the old spacing); the nearest 8 to 12 px of water from the lip in front of her; none behind the post or the reeds */
  { const SL = JSON.parse(sh.moves.find(m => m.src.startsWith('const slotC=')).to.match(/SLOTC=(\[\[.*?\]\])/)[1]), CAR = [196, 117];
    const oldD = i => Math.hypot(98 + (i % 13) * 6 - CAR[0], 119 + (i >= 13 ? 4 : 0) - CAR[1]);
    for (let i = 1; i < SL.length; i++) { const d = Math.hypot(SL[i][0] - SL[i - 1][0], SL[i][1] - SL[i - 1][1]); if (d < 6) P.push('boats: slots ' + (i - 1) + ' and ' + i + ' are ' + r2(d) + ' px apart (the old 6)'); }
    let n = 0, worst = -99, maxI = -1, hullMin = 99; const behindB = new Set();
    runs.forEach((r, ri) => { if (r.story.id !== 'los-botes') return; for (const t of NEW[ri].ticks.map(t => t.W).concat(NEW[ri].states.map(L => L.W))) { const ca = (t.gente || {}).carmen; if (!ca) continue;
      for (const [k, o] of Object.entries(t.botes || {})) { if (!o || o.en !== 'carmen') continue; const i = SL.findIndex(q => q[0] === R(o.x) && q[1] === R(o.y)); if (i < 0) { P.push('boats: ' + k + ' reached Carmen at ' + R(o.x) + ',' + R(o.y) + ', no slot'); continue; } n++; maxI = Math.max(maxI, i);
        const d = Math.hypot(R(o.x) - R(ca.x), R(o.y) - R(ca.y)); worst = Math.max(worst, d - oldD(i));
        { let h = 99; for (const [yy, a, b] of boatRows(o).filter(q => q[0] >= R(o.y) - 4)) for (let xx = a; xx <= b; xx++) h = Math.min(h, Math.hypot(xx - R(ca.x), yy - R(ca.y))); hullMin = Math.min(hullMin, h); } if (d > oldD(i) + 10) P.push('boats: slot ' + i + ' is ' + r2(d) + ' px from Carmen\'s feet, the old ' + r2(oldD(i)));
        const near = nearerRows(boatRows(o), vSurf(R(o.x), R(o.y) - 1), ['poste', 'juncos']); if (Object.keys(near).length) behindB.add(k + ' slot ' + i); } } });
    for (const b of behindB) P.push('boats: ' + b + ' is behind the post or the reeds');
    if (hullMin > 20) P.push('boats: the nearest boat\'s hull is ' + r2(hullMin) + ' px from Carmen\'s feet (keep 20)');
    // the nearest slot's water to the lip: from its waterline to the nearest pixel that is not water (the bank's face, its lip, the lawn)
    const near = SL[SL.length - 1]; let lip = 99; for (let y = near[1] - 20; y <= near[1] + 20; y++) for (let x = near[0] - 20; x <= near[0] + 20; x++) { const z = zoneAt(x, y); if (z === 'b' || z === 'p' || z === 'l') lip = Math.min(lip, Math.hypot(x - near[0], y - (near[1] - 1))); }
    if (lip < 8 || lip > 12) P.push('boats: the nearest slot ' + near + ' has ' + r2(lip) + ' px of water to the lip (keep 8 to 12)');
    notes.push('boats to Carmen (round 3): ' + n + ' moments of a boat arrived (slots 0 to ' + maxI + '), the nearest boat\'s hull ' + r2(hullMin) + ' px from her feet at the most (keep 20), each no further from Carmen\'s feet than the old slot from hers + 10 px (the most: ' + r2(worst) + ' px over the old); neighbours ' + r2(Math.min(...SL.slice(1).map((q, i) => Math.hypot(q[0] - SL[i][0], q[1] - SL[i][1])))) + ' px apart at the least (the old 6); the nearest ' + r2(lip) + ' px of water from the lip; none behind the post or the reeds'); }

  /* round 2, point 2: where the post, each piling that shows and each reed meet the water, a short waterline of the water's ripple light round the
     foot (baked: lago-set.html waterlines), small: within its half width + 4 px of the foot and 2 rows */
  { const WL = G.waterline[KEY], by = {}; let small = true;
    for (const w of WL) { const shows = (() => { for (let dy = -1; dy <= 2; dy++) for (let dx = -Math.ceil(w.hw) - 3; dx <= Math.ceil(w.hw) + 3; dx++) { const x = w.foot[0] + dx, y = w.foot[1] + dy; if (zoneAt(x, y) === 'w' && !w.px.includes(y * 240 + x)) return true; } return false; })();
      const b = by[w.what] = by[w.what] || { n: 0, shown: 0, px: 0, min: 99 }; b.n++; if (!shows && !w.px.length) continue; b.shown++; b.px += w.px.length; b.min = Math.min(b.min, w.px.length);
      if (w.px.length < (w.what === 'junco' ? 1 : 2)) P.push('waterline: the ' + w.what + ' at ' + w.foot + ' meets the water with ' + w.px.length + ' px of waterline');
      for (const i of w.px) { const x = i % 240, y = Math.floor(i / 240); if (Math.abs(x + .5 - w.foot[0]) > w.hw + 4 || Math.abs(y - w.foot[1]) > 2) small = false; } }
    if (!small) P.push('waterline: a waterline reaches further than its foot\'s half width + 4 px or 2 rows');
    // round 3: at the reeds, separate short dashes only: no two reeds' waterline pixels touch, each dash 8 px at the most
    { const reedPx = WL.filter(w => w.what === 'junco').map(w => w.px); let touch = 0, big = 0; const own = new Map(); reedPx.forEach((l, k) => l.forEach(i => own.set(i, k)));
      reedPx.forEach((l, k) => { if (l.length > 8) big++; for (const i of l) for (const d of [-1, 1, -240, 240, -241, -239, 239, 241]) { const o = own.get(i + d); if (o != null && o !== k) touch++; } });
      if (touch || big) P.push('waterline: at the reeds ' + touch + ' px of two dashes touch, ' + big + ' dashes longer than 8 px'); by.dashes = reedPx.filter(l => l.length).length; }
    notes.push('waterlines (round 3): ' + Object.entries(by).filter(e => typeof e[1] === 'object').map(([k, b]) => k + ' ' + b.shown + ' of ' + b.n + ' feet that show, ' + b.min + ' px at the least').join('; ') + '; at the reeds ' + by.dashes + ' separate dashes, the frontmost reed of each clump' + ', each within its half width + 4 px of its foot and 2 rows (smaller than any ring); no dark patch inside a plank (each plank one tone, its edge shaded the same on every plank)'); }

  /* round 2, point 3: each mooring post stands on the planks, 2 px and more inside the deck's edge all round its foot, its contact shadow on the planks */
  { const res = [];
    for (const p of F.PM) { let bad = 0; for (let a = 0; a < 16; a++) { const q = E.project(p.x + F.PM_R * Math.cos(a / 16 * 6.283), p.y + F.PM_R * Math.sin(a / 16 * 6.283), F.ZD), qx = R(q.sx), qy = R(q.sy);
        for (let dy = -5; dy <= 5; dy++) for (let dx = -5; dx <= 5; dx++) if (dx * dx + dy * dy <= 25 && zoneAt(qx + dx, qy + dy) !== 'd') bad++; }
      for (let dx = -2; dx <= 2; dx++) for (const dy of [1, 2]) if (zoneAt(p.top[0] + dx, p.top[1] - 1 - dy) !== 'd') bad++;   // planks seen over its top too
      if (bad) P.push('posts: the mooring post at ' + p.top + ' has ' + bad + ' px within 5 px of its foot (or over its top) off the planks'); res.push(p.top.join(',')); }
    const sp = G.shadowPx[KEY]['muelle.postes'] || [], off = sp.filter(i => OG[i] && ZONE[i] !== 'd').length, on = sp.filter(i => OG[i] && ZONE[i] === 'd').length;
    if (off || !on) P.push('posts: their contact shadows darken ' + on + ' px of planks and ' + off + ' px off them');
    notes.push('mooring posts (round 3): each (tops at ' + res.join('; ') + ') on the planks with 5 px of plank round its foot and planks over its top, its contact shadow on the planks (' + on + ' px)'); }

  /* round 2, point 4: the fish against the water round it (CIE76, mean against mean): 30 at the least, or the help (its ring a tone lighter);
     the blue boat's sail, measured the same way (reported) */
  { const W0 = waterMean, PT = sh.helps.ring.pez.patch, res = [];
    for (const [c, [d, at]] of Object.entries(fishWorst)) { res.push(c + ' ' + Math.round(d) + ' (at ' + at + '; against the open water ' + Math.round(dE(M.colours['pez.' + c], W0)) + ')'); if (d < 45) P.push('fish: the ' + c + ' fish at ' + at + ' stands out from the 2 px band round its outline by ' + Math.round(d) + ' (keep 45)'); }
    for (const c of ['pardo', 'rojo', 'azul', 'verde']) if (!(c in fishWorst)) res.push(c + ' (not at the surface in any run or pair)');
    notes.push('fish (round 4, CIE76): at ' + fishN + ' moments at the surface, the fish against the 2 px band of water just outside its outline as drawn (its pale patch ' + PT + ' larger than it by 3 px and more on every side), the least: ' + res.join(', ') + '; the sails against the water ' + W0.map(Math.round) + ': ' + ['rojo', 'azul', 'verde'].map(c => c + ' ' + Math.round(dE(M.colours['vela.' + c], W0))).join(', ') + '; the fish at the surface swims in its patch at every moment, out of the dock\'s shade; leaping, its splash (the old salpica)'); }

  /* round 3, point 5: the planks' tones vary plank by plank, no run of light ones: the mean lightness of each plank's pixels on the deck,
     no two side by side both lighter than the deck's mean by 3 (CIE L*) */
  { const byK = new Map(); for (let i = 0; i < 240 * 216; i++) { if (ZONE[i] !== 'd' || TAG[i] !== 'muelle') continue; const w = E.atZ(i % 240 + .5, Math.floor(i / 240) + .5, F.ZD), f = (w[0] - F.DECK.x0 + 40 * F.PW) / F.PW, k = Math.floor(f); if (f - k < .14 || f - k > .86) continue;
      const L = lab(rgbAt(i))[0], b = byK.get(k) || [0, 0]; b[0] += L; b[1]++; byK.set(k, b); }
    const ks = [...byK.keys()].sort((a, b) => a - b).filter(k => byK.get(k)[1] > 20), Ls = ks.map(k => byK.get(k)[0] / byK.get(k)[1]), mean = Ls.reduce((a, b) => a + b, 0) / Ls.length; let run = 0;
    for (let j = 1; j < Ls.length; j++) if (Ls[j] > mean + 3 && Ls[j - 1] > mean + 3) run++;
    if (run) P.push('planks: ' + run + ' pairs of light planks side by side (a band)');
    notes.push('planks (round 3): ' + ks.length + ' planks, their lightness ' + Ls.map(Math.round).join(' ') + ' (CIE L*; mean ' + Math.round(mean) + '): no two light ones side by side'); }

  /* round 4: the reed bed shows 22 px and more of its width inside the view, its nearest feet at x 196 or less, its tops below the boats' row at
     Carmen's feet; whatever sticks or rests in it 6 px and more from the view's right edge (sides) and 60% and more of it seen */
  { const rp = G.parts[KEY].juncos || [], xs = rp.map(i => i % 240).filter(x => x < x0 + 196), minX = Math.min(...xs), top = Math.min(...rp.map(i => Math.floor(i / 240))), feet = Math.min(...F.REED_FEET.map(f => f[0]));
    const SL = JSON.parse(sh.moves.find(m => m.src.startsWith('const slotC=')).to.match(/SLOTC=(\[\[.*?\]\])/)[1]); let slotBottom = 0;
    for (const q of SL) { const o = { c: 'rojo', x: q[0], y: q[1], en: 'carmen' }, b = rowsBox(boatRows(o)); if (b[0] + b[2] >= minX) slotBottom = Math.max(slotBottom, q[1] + sh.helps.ring.bote.ry + 1); }
    if (x0 + 196 - minX < 22) P.push('reeds: only ' + (x0 + 196 - minX) + ' px of the bed inside the view');
    if (feet > 196) P.push('reeds: the nearest feet at x ' + feet);
    if (top <= slotBottom) P.push('reeds: their tops (row ' + top + ') reach the boats\' row at Carmen\'s feet (row ' + slotBottom + ')');
    let worstSeen = 1, nIn = 0; for (const [k, f] of reedSeen) { nIn++; worstSeen = Math.min(worstSeen, f); if (f < .6) P.push('reeds: ' + k + ' is only ' + Math.round(f * 100) + '% seen'); }
    notes.push('reeds (round 4): ' + (x0 + 196 - minX) + ' px of the bed inside the view, its nearest feet at x ' + feet + ', its tops at row ' + top + ', below the boats\' row at Carmen\'s feet (row ' + slotBottom + '); ' + nIn + ' things resting in it, each ' + Math.round(worstSeen * 100) + '% seen at the least, 6 px and more from the view\'s edge (sides)'); }

  /* round 4: no stray light pixel on the deck, each plank's tone even along its length (its light pixels, quarter by quarter, within 20%) */
  { const cnt = new Map(), byK = new Map(); for (let i = 0; i < 240 * 216; i++) { if (TAG[i] !== 'muelle' || ZONE[i] !== 'd' || G.shade[KEY][i]) continue; const c = RGB[i * 3] + ',' + RGB[i * 3 + 1] + ',' + RGB[i * 3 + 2]; cnt.set(c, (cnt.get(c) || 0) + 1); }
    const stray = [...cnt].filter(e => e[1] < 20); for (const [c, n] of stray) P.push('deck: ' + n + ' px of ' + c + ' on the planks (a stray colour)');
    const light = [...cnt].sort((a, b) => b[1] - a[1]).slice(0, 4).map(e => e[0].split(',').map(Number)).sort((a, b) => lab(b)[0] - lab(a)[0])[0].join(',');
    for (let i = 0; i < 240 * 216; i++) { if (TAG[i] !== 'muelle' || ZONE[i] !== 'd' || G.shade[KEY][i]) continue; const w = E.atZ(i % 240 + .5, Math.floor(i / 240) + .5, F.ZD), f = (w[0] - F.DECK.x0 + 40 * F.PW) / F.PW, k = Math.floor(f); if (f - k < .14 || f - k > .86) continue;
      const q = Math.min(3, Math.max(0, Math.floor((w[1] - F.DECK.y0) / (F.DECK.y1 - F.DECK.y0) * 4))), b = byK.get(k) || [[0, 0], [0, 0], [0, 0], [0, 0]]; b[q][1]++; if (RGB[i * 3] + ',' + RGB[i * 3 + 1] + ',' + RGB[i * 3 + 2] === light) b[q][0]++; byK.set(k, b); }
    let uneven = 0, worst = 0; for (const [k, b] of byK) { const fr = b.filter(q => q[1] > 15).map(q => q[0] / q[1]); if (fr.length < 2) continue; const d = Math.max(...fr) - Math.min(...fr); worst = Math.max(worst, d); if (d > .2) uneven++; }
    if (uneven) P.push('deck: ' + uneven + ' planks uneven along their length');
    notes.push('deck (round 4): ' + cnt.size + ' colours on the planks out of every shadow, none of them stray (fewer than 20 px); each plank even along its length (its lightest tone\'s share, quarter by quarter, within ' + Math.round(worst * 100) + '%); no glint on the deck, the post or a reed'); }

  /* round 3: the flower on the right bank: plain lawn round it (2 px), nobody in front of it at any moment */
  { let bad = 0, n = 0, flowerSpare = 99, flowerLawn = 99; const over = new Set();
    for (const [where, w] of allW) { if (!w.flor) continue; n++; const fr = rowsAt(M.things.flor, w.flor[0], w.flor[1]);
      if (n === 1) { for (const [y, a, b] of fr) for (let x = a - 2; x <= b + 2; x++) { const z = zoneAt(x, y); if (z !== 'l' && z !== 's') bad++; }   // behind it and 2 px each side, on its own rows: lawn, or the hills behind its head
        const fb = rowsBox(fr); if (fb[0] + fb[2] > x0 + 196 - 4 || fb[0] < x0 + 4) P.push('flower: ' + JSON.stringify(fb) + ' is not whole inside the view 4 px from its edges');
        { const b2 = [w.flor[0] - 5, w.flor[1] - 16, 10, 17], cx = b2[0] + b2[2] / 2, cy = b2[1] + b2[3] / 2, rx = b2[2] / 2 + 5, ry = b2[3] / 2 + 5; if (cx - rx - 3 < x0 || cx + rx + 3 > x0 + 196 || cy - ry - 3 < 0) P.push('flower: the stars of its twinkle (juego.js twinkle: box + 5, 3 px) leave the view'); flowerSpare = [x0 + 196 - fb[0] - fb[2], R(x0 + 196 - (cx + rx + 3))]; }
        { const f = footOf(fr); let m = 99; for (let y = f[0][0] - 12; y <= f[0][0] + 12; y++) for (let x = fb[0] - 12; x <= fb[0] + fb[2] + 12; x++) { const z = zoneAt(x, y); if (z !== 'l' && z !== 's' && z !== 'out') for (const [fy, a, b] of f) m = Math.min(m, Math.hypot(x < a ? a - x : x > b ? x - b : 0, y - fy)); } flowerLawn = m; } }
      for (const it of itemsOf(w)) if (it.kind !== 'flower' && rowsOverlap(it.rows, fr)) over.add(it.id + ' (' + where + ')'); }
    if (bad) P.push('flower: ' + bad + ' px round it are not lawn'); for (const o of [...over].slice(0, 10)) P.push('flower: ' + o + ' is in front of it');
    notes.push('flower (round 4): on the right bank, whole inside the view (' + flowerSpare[0] + ' px from its right edge; the stars of its twinkle ' + flowerSpare[1] + ' px inside it), ' + r2(flowerLawn) + ' px of lawn round its foot, lawn or the hills behind it, nobody in front of it at any of ' + n + ' moments'); }

  /* the sky */
  { const [sx, sy, sr] = F.SUN;
    if (sx - sr - 1 < x0 || sx + sr + 1 > x0 + 196 || sy - sr - 1 < 0) P.push('sun: its disc is not whole inside the view');
    if (sx > 120) P.push('sun: not in the upper left');
    let n = 0; for (let y = Math.max(0, sy - sr - 2); y <= sy + sr + 2; y++) for (let x = sx - sr - 2; x <= sx + sr + 2; x++) if (Z[y * 240 + x] > -1e8) n++; if (n) P.push('sun: ' + n + ' px of the set within 2 px of its disc');
    for (const [cx, cy, s2] of F.CLOUDS) { const b = [Math.floor(cx - 17 * s2 - 2), Math.floor(cy - 5 * s2 - 2), Math.ceil(cx + 19 * s2 + 2), Math.ceil(cy + 6 * s2 + 2)];
      if (b[2] >= sx - sr && b[0] <= sx + sr && b[3] >= sy - sr && b[1] <= sy + sr) P.push('cloud at ' + cx + ',' + cy + ': on the sun');
      if (b[2] >= x0 + BOARD[0] && b[0] <= x0 + BOARD[0] + BOARD[2] && b[1] <= BOARD[1] + BOARD[3]) P.push('cloud at ' + cx + ',' + cy + ': under the rounds card'); }
    notes.push('sky: the sun at ' + F.SUN.slice(0, 2) + ' (radius ' + sr + '), upper left, whole in the view, under no card and no board at any moment; the old picture\'s three clouds at ' + F.CLOUDS.map(c => c.slice(0, 2).join(',')).join('; ') + ', clear of the sun and of the corner card'); }

  /* the preview puts everyone where the sheet does, at every moment of the recorded runs (PREVIEW.remapW, the sheet's rule), and the sheet's rule
     puts every one at rest where the port's play has them (the recorded step's end against the same step's end of the port's play) */
  { let nP = 0, bad = 0, nR = 0, badR = 0; const off = new Map();
    const MV = sh.moves.flatMap(m => (m.places || []).map(q => q)), RMall = sh.remap.filter(e => e.moved && e.kind === 'point');
    const shift = (sh.moves.find(m => m.shift) || {}).shift, slotSL = JSON.parse(sh.moves.find(m => m.src.startsWith('const slotC=')).to.match(/SLOTC=(\[\[.*?\]\])/)[1]), slotF = i => slotSL[Math.min(i, 11)];
    const remapW = (w0, story) => { const w = JSON.parse(JSON.stringify(w0)), RM = RMall.filter(e => e.uses.some(u => u.startsWith(story + '.json')));
      const find = (who, p) => MV.find(q => (q.who === 'whoever' || q.who === who) && q.old[0] === R(p.x) && q.old[1] === R(p.y)) || RM.find(e => e.old[0] === R(p.x) && e.old[1] === R(p.y));
      const mv = (who, p) => { const m = find(who, p); if (m) { p.x = m.new[0]; p.y = m.new[1]; } };
      for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) mv(id, p);
      if (w.perro && w.perro.x != null) mv('perro', w.perro);
      for (const o of Object.values(w.patos || {})) if (o && o.x != null) { if (shift && o[shift.when]) { o.x += shift.by[0]; o.y += shift.by[1]; } else mv('pato', o); }
      for (const o of Object.values(w.aves || {})) if (o && o.x != null) { mv('ave', o); if (o.casa) { const m = find('ave', { x: o.casa[0], y: o.casa[1] }); if (m) o.casa = m.new.slice(); } }
      for (const o of Object.values(w.botes || {})) if (o && o.x != null) { if (o.en === 'carmen') { const i = R((o.x - 98) / 6) + (o.y > 121 ? 13 : 0); const s = slotF(i); o.x = s[0]; o.y = s[1]; } else mv('bote', o); }
      for (const o of Object.values(w.peces || {})) if (o && o.x != null) mv('pez', o);
      if (w.cq) { const m = MV.find(q => q.who === 'cq' && q.old[0] === w.cq.x && q.old[1] === w.cq.y) || RM.find(q => q.old[0] === w.cq.x && q.old[1] === w.cq.y); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }
      if (w.pan && w.pan.con == null && w.pan.x != null) mv('pan', w.pan);
      for (const k of ['flor', 'bolsa', 'saco']) if (w[k]) { const m = find(k, { x: w[k][0], y: w[k][1] }); if (m) w[k] = m.new.slice(); }
      return w; };
    const places = w => { const o = {}; for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null && p.vis !== 0) o[id] = [R(p.x), R(p.y)];
      if (w.cq && w.cq.vis) o.cq = [w.cq.x, w.cq.y]; if (w.perro && w.perro.x != null) o.perro = [R(w.perro.x), R(w.perro.y)];
      for (const [kk, nm] of [['patos', 'pato'], ['aves', 'ave'], ['botes', 'bote'], ['peces', 'pez']]) for (const [k, p] of Object.entries(w[kk] || {})) if (p && p.vis !== 0) o[nm + '.' + k] = [R(p.x), R(p.y)];
      for (const k of ['flor', 'bolsa', 'saco']) if (w[k]) o[k] = w[k].slice(); return o; };
    runs.forEach((r, ri) => { const Ls = NEW[ri].states;
      r.lines.forEach((ln, li) => { const mine = places(remapW(ln.W, r.story.id)), pv = G.PV[ri][li];
        for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } }
        // against the port's play: what was at rest in the recorded step (the same place at the step before and after) and the step's twin
        const tw = Ls.find(L => L.path === ln.path && L.kind === ln.kind); if (!tw || li === 0) return; const prev = places(remapW(r.lines[li - 1].W, r.story.id)), port = places(tw.W);
        for (const [k, p] of Object.entries(mine)) { if (!prev[k] || prev[k].join() !== p.join() || !port[k] || /^(pez|pato)\./.test(k) || (/^bote\./.test(k) && !/^bote\.f_/.test(k)) || (/^ave\./.test(k) && !perchAt({ x: p[0], y: p[1] }))) continue; nR++; if (port[k].join() !== p.join()) { badR++; off.set(k + ' ' + JSON.stringify(p) + ' -> ' + JSON.stringify(port[k]), r.story.id + ' ' + ln.path); } } }); });
    if (badR) for (const [k, w] of [...off].slice(0, 30)) P.push('rule: ' + k + ' in the port\'s play (' + w + ')');
    notes.push('preview: at every step\'s end of the ' + runs.length + ' recorded runs (' + nP + ' places of the children, the frog, Canelo, the ducks, the birds, the boats, the fish and the things) lago-preview.html puts everyone exactly where the sheet\'s rule does (' + bad + ' differ); and the rule puts each of the ' + nR + ' places at rest where the port\'s play has them (' + badR + ' differ)'); }

  /* the review pictures */
  { let nPic = 0; const pairDiff = [], zoom2 = [];
    const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
    for (const [word, sides2] of Object.entries(byWord)) { const ws = {};
      for (const side of Object.keys(sides2)) { const ps = sides2[side], nm = deacc(word) + '.' + side, pc = sh.pictures[nm], w = pairW(ps); ws[side] = w; nPic++;
        const crop = pc.crop, oc = ps.spec.cam, ocr = [Math.floor(oc[0]), Math.floor(oc[1]), Math.ceil(oc[2]), Math.ceil(oc[3])];
        for (const it of itemsOf(w)) { const b = rowsBox(it.rows), wo = JSON.parse(JSON.stringify(ps.spec.set || {})); if (!within([b[0] - 2, b[1] - 2, b[2] + 4, b[3] + 4], crop)) P.push('pair ' + nm + ': ' + it.id + ' ' + JSON.stringify(b) + ' is not whole with 2 px to spare in ' + JSON.stringify(crop)); }
        // a zoom 2 picture shows no shadow without its caster: the dock's shade only with the dock in it
        if (pc.zoom === 2) { let shade = 0, dock = 0; for (let y = crop[1]; y < crop[1] + crop[3]; y++) for (let x = crop[0]; x < crop[0] + crop[2]; x++) { const i = y * 240 + x; if (SHD[i] && ZONE[i] === 'w') shade++; if (TAG[i] === 'muelle') dock++; }
          if (shade && dock < 20) P.push('pair ' + nm + ': shows ' + shade + ' px of the dock\'s shade and not the dock'); zoom2.push(nm + (shade ? ' (the dock\'s shade with the dock)' : '')); } }
      if (!ws.si || !ws.no) continue;
      const diff = []; for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k);
      if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
      if (!diff.length) P.push('pair ' + word + ': the two pictures are the same');
      pairDiff.push(deacc(word) + ': ' + diff.join(', ')); }
    notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures), all zoom 2: everything in each whole with 2 px to spare, on its side of the shore and the dock (sides); what differs: ' + pairDiff.join('; ') + '; no picture shows the dock\'s shade without the dock'); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSides) reached.add(keyOf(ps.spec.set || {}));
    for (const k of STATES) if (!reached.has(k)) P.push('state ' + k + ' is baked but nothing reaches it');
    notes.push('states: ' + reached.size + ' baked state reached (every moment, pair and level picture)');
    console.log('  (not in the sheet, it changes from run to run) bake in headless Chrome: the first ' + Math.round(G.ms.first || 0) + ' ms, again ' + Math.round(G.ms.warm || 0) + ' ms (the ground cached)'); }
  return P;
}
