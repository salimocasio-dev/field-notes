#!/usr/bin/env node
'use strict';
/* El camino's sheet (order 33a): writes docs/proyecto/pixel/camino-sheet.json from camino-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/camino-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.CAMINO_SET), its part map, its depth and every castShadow call from camino-set.html in headless Chrome, for
   both baked states; measures the old sprite layer's bubbles, people, dog, cat and birds (historia/ engine.js, juego.js, kit.js, escenas/camino.js,
   as they are); projects every world point with the engine's own formula; checks the sheet against coqui/ref/escenas/camino/ (positions.json,
   inventory.json, pairs.json) and against every moment of every recorded run of the scene's stories (coqui/tool/ref/trazas/juega.mjs --states,
   into a temp folder); and loads camino-preview.html (over a local http server it starts and stops) to check that the preview puts everyone
   where the sheet does, at every moment. Nothing in the repo is written but the sheet. A second run writes the same bytes. El patio's maker
   (patio-sheet-make.js) is the model: the same rules, the same way of checking. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'camino-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/camino');
// the baked states: gran (the big tree). Every state a story, a review pair or a level picture reaches is one of these (checked)
const STATES = ['1', '0'];
const keyOf = w => w.sinGran ? '0' : '1';
const queryOf = k => 'gran=' + k;
const SOLID = ['porton', 'arbol0', 'arbol1', 'arbol2', 'banco', 'grande'];   // what stands on the ground (the stones lie on the path)

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, kinds: {}, rgb: {}, leaf: {}, shadows: {}, ms: {} };
  for (const key of STATES) {
    await page.goto('file://' + path.join(__dirname, 'camino-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(CAMINO_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      // the leaves' reach: every pixel a swaying leaf can take at any wind step (drawLeaves: dx = round(swayX .9), |swayX| <= 1.55 reach,
      // dy = round(sin .45 reach)), by part
      const leaf = {}; for (const [name, [a, b]] of Object.entries(PART_LEAVES)) { const out = new Set();
        for (let j = a; j < b; j++) { const L = leaves[j], reach = Math.min(1, Math.max(.3, (L.z - 2.5) / 3)), mx = Math.round(1.55 * reach * .9), my = Math.round(reach * .45);
          for (let n = 0; n < L.pixels.length; n += 4) for (let dx = -mx; dx <= mx; dx++) for (let dy = -my; dy <= my; dy++) { const x = L.pixels[n] + dx, y = L.pixels[n + 1] + dy; if (x >= 0 && y >= 0 && x < W && y < H) out.add(y * W + x); } }
        leaf[name] = [...out]; }
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgb = []; for (let i = 0; i < W * H; i++) rgb.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      // every castShadow call of the bake, with the part that made it and what it did: bake again with castShadow and part() watched
      const calls = []; let cur = null; const cs0 = castShadow, part0 = part;
      castShadow = function (x, y, z, r, strength = 1, dither = .4) { const before = shadowMask.slice(); cs0(x, y, z, r, strength, dither); let n = 0; for (let i = 0; i < W * H; i++) if (shadowMask[i] !== before[i]) n++;
        calls.push({ part: cur, args: [x, y, z, r, strength], set: n }); };
      part = function (name, fn) { const c0 = cur; cur = name; const r = part0(name, fn); cur = c0; return r; };
      PART_TAGS = null; const t0 = performance.now(); buildSet(); const warm = performance.now() - t0;
      castShadow = cs0; part = part0;
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(DEPTH.z), kinds: Array.from(kinds), K: { road: KIND_ROAD, grass: KIND_GRASS }, rgb, leaf, calls, bake: BAKE_MS };
    });
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, K: g.K });
    G.parts[key] = g.parts; G.z[key] = g.z; G.kinds[key] = g.kinds; G.rgb[key] = g.rgb; G.leaf[key] = g.leaf; G.shadows[key] = g.calls;
  }
  if (errs.length) throw new Error(errs.join('; '));
  G.M = await measure(await browser.newPage());
  const sheet = make(G);
  fs.writeFileSync(OUT, text(sheet));   // the preview reads the sheet: written first, then checked (and written again with the checks' notes)
  const runs = storyStates();
  G.PV = await previewPlaces(browser, runs);
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const problems = check(sheet, G, runs);
  const t = text(sheet);
  fs.writeFileSync(OUT, t);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + t.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 200).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });
const text = sheet => JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';

/* ---------- the old sprite layer, measured in the browser: every bubble's rectangle, the people's, the dog's, the cat's and the birds' pixels ---------- */
// historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/camino.js loaded as they are into a blank page; camino.js's own sprite
// makers (mkGato, mkPajarito, mkCaracol, mkArbusto) taken from its text as they are. A bubble is drawn as camino.js bub2 draws it (twice its
// size, its tail's tip at the origin), on both frames of its bob
const CAMINO_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/camino.js'), 'utf8');
const LINES = CAMINO_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('camino.js changed: ' + s); return i + 1; };
const fnText = name => { const a = CAMINO_JS.indexOf('function ' + name + '('); if (a < 0) throw new Error('camino.js changed: ' + name); let d = 0, i = CAMINO_JS.indexOf('{', a);
  for (; i < CAMINO_JS.length; i++) { if (CAMINO_JS[i] === '{') d++; else if (CAMINO_JS[i] === '}' && --d === 0) break; } return CAMINO_JS.slice(a, i + 1); };
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/camino.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  await page.addScriptTag({ content: ['mkGato', 'mkPajarito', 'mkCaracol', 'mkArbusto'].map(fnText).join('\n') + '\nwindow.MK={mkGato,mkPajarito,mkCaracol,mkArbusto};' });
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
    // the opaque rows of a sprite drawn at (ox, oy) on a big canvas: [dy, x from, x to] relative to the anchor
    const rowsOf = (draw, ox, oy) => { const cv = document.createElement('canvas'); cv.width = 160; cv.height = 140; const g = cv.getContext('2d'); g.imageSmoothingEnabled = false; draw(g, 80, 100);
      const d = g.getImageData(0, 0, cv.width, cv.height).data, out = [];
      for (let y = 0; y < cv.height; y++) { let a = -1, b = -1; for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3] > 40) { if (a < 0) a = x; b = x; } if (a >= 0) out.push([y - 100, a - 80, b - 80]); }
      return out; };
    const QUIEN = { luis: KIT.FAM.hermano, carmen: KIT.FAM.hermana }, masks = {}, heads = {};
    const head = rows => { const top = Math.min(...rows.map(r => r[0])), rs = rows.filter(r => r[0] < top + 10); return { top, head: (Math.min(...rs.map(r => r[1])) + Math.max(...rs.map(r => r[2])) + 1) / 2 }; };
    // a person as camino.js gente draws them: translate(x, y - h + 1), scale(-1, 1) when dir < 0, drawImage(im, -PX, 0); abuela translate(x, y - 50), drawImage(im, -30, 0)
    for (const [id, fam] of Object.entries(QUIEN)) for (const sent of [0, 1]) for (const pose of ['idle', 'wave0', 'wave1', 'offer']) for (const dir of [1, -1]) {
      const im = KIT.mkPersona(fam, pose, 0, sent);
      masks[id + '.' + pose + (sent ? '.sent' : '') + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 1); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -KIT.PX, 0); g.restore(); });
      if (pose === 'idle' && dir === 1) heads[id + (sent ? '.sent' : '')] = head(masks[id + '.idle' + (sent ? '.sent' : '') + '.1']);
    }
    for (const pose of ['idle', 'wave0', 'wave1', 'offer']) for (const dir of [1, -1]) { const im = mkAbuela(pose, 0);
      masks['abuela.' + pose + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - 50); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -30, 0); g.restore(); }); }
    heads.abuela = head(masks['abuela.idle.1']);
    // the dog and the cat as camino.js animal draws them: translate(x, y - h + 2), scale(-1, 1) when dir < 0, drawImage(im, -13, 0); both frames
    const animals = {};
    for (const [k, mk] of [['perro', KIT.mkPerro], ['gato', MK.mkGato]]) for (const pose of k === 'perro' ? ['sit', 'walk', 'run', 'bark', 'lie', 'husmea', 'eat'] : ['sit', 'lava', 'walk', 'run']) for (const f of [0, 1]) for (const dir of [1, -1]) {
      const im = mk(pose, f); animals[k + '.' + pose + '.' + f + '.' + dir] = rowsOf((g, x, y) => { g.save(); g.translate(x, y - im.height + 2); if (dir < 0) g.scale(-1, 1); g.drawImage(im, -13, 0); g.restore(); }); }
    // a bird in a tree: mkPajarito(f) drawn at (x, y) 15 x 12 (both frames); the cat's face and tail in a tree; the snail; the bush
    const ave = {}; for (const f of [0, 1]) ave[f] = rowsOf((g, x, y) => g.drawImage(MK.mkPajarito(f), x, y, 15, 12));
    const cara = rowsOf((g, x, y) => g.drawImage(MK.mkGato('cara', 0), x, y)), cola = rowsOf((g, x, y) => g.drawImage(MK.mkGato('cola', 0), x, y));
    const caracol = rowsOf((g, x, y) => g.drawImage(MK.mkCaracol(0), x - 9, y - 12)), arbusto = rowsOf((g, x, y) => g.drawImage(MK.mkArbusto(), x - 22, y - 28));
    // the mean colour of the bush, the snail, the dog and the cat (sitting): do they stand out from the lawn
    const meanOf = im => { const g = im.getContext('2d'), d = g.getImageData(0, 0, im.width, im.height).data; let n = 0, s = [0, 0, 0]; for (let i = 0; i < d.length; i += 4) if (d[i + 3] > 40) { n++; s[0] += d[i]; s[1] += d[i + 1]; s[2] += d[i + 2]; } return s.map(v => Math.round(v / n)); };
    const colours = { arbusto: meanOf(MK.mkArbusto()), caracol: meanOf(MK.mkCaracol(0)), perro: meanOf(KIT.mkPerro('sit', 0)), gato: meanOf(MK.mkGato('sit', 0)), pajaro: meanOf(MK.mkPajarito(0)) };
    return { bubbles, masks, heads, animals, ave, cara, cola, caracol, arbusto, colours, PX: KIT.PX };
  });
}

/* ---------- the preview's places: camino-preview.html, served over http, maps every recorded moment as the app will ---------- */
async function previewPlaces(browser, runs) {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.woff2': 'font/woff2', '.css': 'text/css' };
  const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(REPO, u);
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); fs.createReadStream(f).pipe(res); });
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  try {
    const page = await browser.newPage(), errs = []; page.on('pageerror', e => errs.push(String(e)));
    await page.goto('http://127.0.0.1:' + srv.address().port + '/docs/proyecto/pixel/camino-preview.html');
    await page.evaluate(() => PREVIEW.ready);
    if (errs.length) throw new Error('preview: ' + errs.join('; '));
    const out = [];
    for (const r of runs) out.push(await page.evaluate(([story, Ws]) => { PREVIEW.story = story; const res = Ws.map(w => { const n = PREVIEW.remapW(w), o = {};
        for (const [id, p] of Object.entries(n.gente || {})) if (p && p.x != null) o[id] = [Math.round(p.x), Math.round(p.y)];
        if (n.cq) o.cq = [n.cq.x, n.cq.y]; for (const k of ['perro', 'gato']) if (n[k] && n[k].x != null) o[k] = [Math.round(n[k].x), Math.round(n[k].y)];
        return o; }); PREVIEW.story = null; return res; }, [r.story, r.lines.map(l => l.W)]));
    // the bubbles' places the preview gives (PREVIEW.talk), for a sample of every moment's speaking people (checked against the sheet's talk)
    await page.close();
    return out;
  } finally { await new Promise(r => srv.close(r)); }
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

/* ---------- the old scene's numbers (historia/escenas/camino.js, read as text: they must be what the file says) ---------- */
function fixJson(s) { return s.replace(/\s+/g, '').replace(/([{,])(\w+):/g, '$1"$2":').replace(/:\./g, ':0.').replace(/,\./g, ',0.').replace(/\[\./g, '[0.'); }
const OLD = (() => { const g = (re, w, wrap) => { const m = CAMINO_JS.match(re); if (!m) throw new Error('camino.js changed: ' + w); return JSON.parse(fixJson(wrap ? '{' + m[1] + '}' : m[1])); };
  return { MARCA: g(/const MARCA=(\[\[[^;]*\]\]);/, 'MARCA'), ARBOL: g(/const ARBOL=(\[\[[^\]]*\],\[[^\]]*\],\[[^\]]*\]\])/, 'ARBOL'), GRAN: g(/GRAN=(\[\d+,\d+\])/, 'GRAN'), BANCO: g(/BANCO=(\[[\d,]+\])/, 'BANCO'),
    NIDO: g(/const NIDO=(\[\[[^;]*\]\]);/, 'NIDO'), LUGARc: g(/LUGAR=\{inicio:ranaEn\(0\),(centro:[^}]*)\}/, 'LUGAR', 1) }; })();
OLD.ranaEn = i => [OLD.MARCA[i][0] - 22, OLD.MARCA[i][1] - 34, Math.round((.96 - .015 * i) * 100) / 100];
OLD.ninaEn = i => [OLD.MARCA[i][0] + 10, Math.min(206, OLD.MARCA[i][1] + 22)];
OLD.perroEn = i => [Math.min(204, OLD.MARCA[i][0] + 34), OLD.MARCA[i][1] - 9];
OLD.LUGAR = Object.assign({ inicio: OLD.ranaEn(0) }, OLD.LUGARc);
OLD.enT = t => { const x = 40 + 146 * t, y = 194 - 58 * t - 8 * Math.sin(Math.PI * t); return [Math.round(x - 10), Math.round(y - 14), 1 - .14 * t]; };
OLD.perroT = t => { const tt = Math.max(0, t - .12), x = 40 + 146 * tt, y = 194 - 58 * tt - 8 * Math.sin(Math.PI * tt); return [Math.round(x) - 2, Math.round(y) + 16]; };
// the old boxes of the set things (camino.js COSAS)
const OLDBOX = { arbol0: [53, 74, 34, 48], arbol1: [95, 70, 34, 48], arbol2: [137, 66, 34, 48], banco: [97, 126, 32, 18], grande: [160, 16, 58, 116], porton: [22, 116, 36, 60], camino: [30, 128, 170, 76], parque: [0, 100, 240, 116] };

// the places a bubble's tail may go, in order (as El patio's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner cards camino.js hud draws, in the 196 x 216 display (tarjeta(x, y, w, h) covers [x - 1, y - 1, w + 2, h + 2])
const boardsOf = (w, x0) => { const b = [];
  if (w.tarjeta === 'galletas') b.push(['the biscuits card', [2, 2, 90, 32]]);
  if (w.tarjeta === 'guineos') b.push(['the guineos card', [2, 2, 86, 32]]);
  return b.map(([n, r]) => [n, [r[0] + x0, r[1], r[2], r[3]]]); };

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

  /* ---- the floor rule: the park is built round the old picture, so a place on its ground stays where it was on the screen ---- */
  // a frog place q (juego.js frogBox: his middle q.x + 16, his feet row q.y + 25): the ground point under (q.x + 16, q.y + 25); new q = old q.
  // a person's place (x, y) (their feet, camino.js gente): the ground point under (x, y - 1); an animal's (x, y) (camino.js animal: its sprite's
  // bottom row y + 1): the ground point under (x, y - 1), as a person's; new = old
  const frogW = q => floor(q[0] + 16, q[1] + 25), personW = p => floor(p[0], p[1] - 1);
  const frogQ = w => { const s = P(w); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const personQ = w => { const s = P(w); return [Math.round(s[0]), Math.round(s[1]) + 1]; };

  /* ---- the set's own things, from its pixels: each part's screen box (its leaves at every wind step too) ---- */
  const tagsOf = key => G.parts[key];
  const pxBox = list => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of list) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1, y1 + 1]; };
  const partScreen = name => { const all = []; for (const key of STATES) { const l = (tagsOf(key)[name] || []).concat(G.leaf[key][name] || []); all.push(...l); } return pxBox(all); };
  // the arch's middle and its posts, on the screen
  const ac = E.project(F.AC[0], F.AC[1], 0), pA = E.project(F.AC[0], F.AC[1] + F.AH, 0), pB = E.project(F.AC[0], F.AC[1] - F.AH, 0);

  /* ---- the places that move (the floor rule keeps every other one). Each is an exact piece of camino.js source and its replacement ---- */
  // the arch's opening: a point in it, b along y from its middle (+ towards post A, down to the left on the screen), a along x (+ into the park)
  const inArch = (a, b) => { const q = E.project(F.AC[0] + a, F.AC[1] + b, 0); return [Math.round(q.sx), Math.round(q.sy)]; };
  // acts.sevan: everyone leaves the park through the arch and goes on up the path off the picture's left edge (the old: walked left, fading,
  // on the grass). Each person: 4 steps to their own point just inside the opening (a .3), 4 steps through it and on (a -2.7), fading as before;
  // the dog walks through it and off; the frog hops through it in his two hops
  const GATE = { abuela: [.3, 0], luis: [.3, -.2], carmen: [.3, .2], perro: [.3, 0], cq: [.3, -.1] };
  const pu = id => { const g = GATE[id]; return [inArch(g[0], g[1]), inArch(-2.7, g[1])]; };
  const fq = p => [p[0] - 16, p[1] - 25];                                   // the frog's q from the point under his feet
  const SEVAN_SRC = 'async sevan(){const q=W.cq;W.correa=0;const fuera=async id=>{const p=G(id);for(let i=0;i<8;i++){p.x-=4;p.al=1-i/8;await wait(TICK);}p.vis=0;};await Promise.all([fuera("abuela"),fuera("luis"),fuera("carmen"),animalA("perro",-10,W.perro.y,"walk"),hopTo(8,q.y,2,q.s)]);q.vis=0;W.perro.vis=0;await wait(500);},';
  const SEVAN_PU = { abuela: pu('abuela'), luis: pu('luis'), carmen: pu('carmen') }, SEVAN_DOG = pu('perro'), SEVAN_FROG = pu('cq').map(fq);
  const SEVAN_TO = 'async sevan(){const q=W.cq;W.correa=0;const PU={abuela:' + JSON.stringify(SEVAN_PU.abuela.flat()) + ',luis:' + JSON.stringify(SEVAN_PU.luis.flat()) + ',carmen:' + JSON.stringify(SEVAN_PU.carmen.flat()) +
    '},fuera=async id=>{const p=G(id),x0=p.x,y0=p.y,u=PU[id];for(let i=0;i<8;i++){const a=i<4?[x0,y0,u[0],u[1],(i+1)/4]:[u[0],u[1],u[2],u[3],(i-3)/4];p.x=a[0]+(a[2]-a[0])*a[4];p.y=a[1]+(a[3]-a[1])*a[4];p.al=1-i/8;await wait(TICK);}p.vis=0;};' +
    'await Promise.all([fuera("abuela"),fuera("luis"),fuera("carmen"),(async()=>{await animalA("perro",' + SEVAN_DOG[0] + ',"walk");await animalA("perro",' + SEVAN_DOG[1] + ',"walk");})(),(async()=>{await hopTo(' + SEVAN_FROG[0] + ',1,q.s);await hopTo(' + SEVAN_FROG[1] + ',1,q.s);})()]);q.vis=0;W.perro.vis=0;await wait(500);},';
  // the bird on the bench (the pair gato.no): on the backrest's top rail, its feet on it (points.ave_banco)
  const AVEB = F.AVEB || [104, 103];
  const ARBOL0 = F.ARBOL0_Q || [36, 122];
  // the answer cards in the sky (W.respEn, juego.js respBox: "a scene that needs its people seen while he chooses puts the bubbles elsewhere", as
  // El patio's inicio11 and h-camino's own beats.5): over the frog they covered Luis by the big tree (uno-dos-tres) and Luis and Carmen (the
  // asks con_n of donde-esta-el-gato), and their hand reached Carmen's and Luis's faces
  const EN12 = [92, 30], EN13 = [166, 24];
  const MOVES = [
    { line: lineOf('async inicio12()'), act: 'inicio12', src: 'async inicio12(){W.gente={luis:{x:174,y:138,pose:"wave",dir:-1}', to: 'async inicio12(){W.respEn=[' + EN12 + '];W.gente={luis:{x:174,y:138,pose:"wave",dir:-1}', respEn: EN12,
      why: 'acts.inicio12 (uno-dos-tres, d-corre, h-camino): the answer cards stand in the sky at the top left (W.respEn ' + EN12 + ', as h-camino sets for itself at its beats.5: [96, 30]; three cards need x >= 92 to stay in the view): over the frog at the far marks they covered Luis, who waits by the big tree (uno-dos-tres beats.19 to 38), and the hand at a card reached his and Carmen\'s faces' },
    { line: lineOf('async inicio13()'), act: 'inicio13', src: 'async inicio13(){W.sinGran=1;', to: 'async inicio13(){W.sinGran=1;W.respEn=[' + EN13 + '];', respEn: EN13,
      why: 'acts.inicio13 (donde-esta-el-gato): the answer cards (con_1, con_2, con_3: which tree the cat is in, by its birds) stand in the sky over the trees (W.respEn ' + EN13 + '): over the frog at the path\'s middle they covered Luis and Carmen (beats.47, 85) and the hand at a card was on Carmen\'s face' },
    { line: lineOf('async sevan()'), act: 'sevan', src: SEVAN_SRC, to: SEVAN_TO,
      why: 'acts.sevan (rapido-despacio, the end): everyone leaves the park through the arch and goes on up the path off the picture\'s left edge, as the old picture had them leave towards its gate (the old act walked them 32 px left on the grass, fading, and the dog off the left edge at its row; the frog hopped to x 8). Each person walks in 4 steps to their own point just inside the opening (abuela in its middle, Luis to her right, Carmen to her left: PU, screen), then in 4 more through it and on up the path (a 2.7 past the arch), fading as before (al 1 - i / 8) and gone; the dog walks through it and on off the picture (animalA, twice); the frog hops through it in his two hops (one to the opening, one on). The same number of steps, of hops and of waits as the old: the act takes the time it took. Whoever is past the arch is behind it: the arch is drawn again over them (front.porton)' },
    { line: lineOf('if(W.avebanco){'), act: '*', src: 'c.drawImage(im,BANCO[0]+8,BANCO[1]-11,15,12)', to: 'c.drawImage(im,' + AVEB[0] + ',' + AVEB[1] + ',15,12)',
      why: 'the bird on the bench (W.avebanco, the pair gato.no): on the seat\'s back plank, its feet on it (points.ave_banco). The new bench stands along y and has no back: the bird ' + (AVEB[0] - 106) + ' px right, ' + (AVEB[1] - 117) + ' rows (the old at 106, 117)' },
    { line: lineOf('W.gato={x:113,y:134,pose:"lava"'), act: 'inicio13', src: 'W.gato={x:113,y:134,pose:"lava"', to: 'W.gato={x:' + F.CAT_BENCH[0] + ',y:' + F.CAT_BENCH[1] + ',pose:"lava"', pts: [['gato', [113, 134], F.CAT_BENCH]],
      why: 'acts.inicio13: the cat on the bench, on the new bench\'s seat (points.gato_banco), as the story files\' cat at 113, 134 (remap)' },
    { line: lineOf('arbol0:[44,122,.8]'), act: '*', src: 'arbol0:[44,122,.8]', to: 'arbol0:[' + ARBOL0 + ',.8]', pts: [['cq', [44, 122], ARBOL0]],
      why: 'LUGAR.arbol0, the frog at the first small tree: ' + (44 - ARBOL0[0]) + ' px further left, so that the arch\'s far post (screen x ' + Math.round(pB.sx) + ', in front of him: its foot ' + Math.round(pB.sy - 122 - 25) + ' rows before his feet) is clear of him (at the old point it stood in front of his right side). Every hop count with the other places is the old one (hops). W.cq at (44, 122) in a recorded run is here (places: who cq)' },
  ];
  for (const m of MOVES) for (const q of m.pts || []) q.push(q[0] === 'cq' ? frogW(q[2]) : W4(personW(q[2])));

  /* ---- spots: the frog's places (LUGAR, ranaEn), Carmen's (ninaEn), the dog's (perroEn), the acts' named places ---- */
  const SPOTS = {};
  for (const [k, v] of Object.entries(OLD.LUGAR)) SPOTS['frog.' + k] = { world: frogW(v), scale: v[2], old: v.slice(0, 2), what: 'LUGAR.' + k + ': the frog' + (k === 'inicio' ? ' (ranaEn(0))' : '') };
  for (let i = 0; i <= 8; i++) {
    SPOTS['rana.' + i] = { world: frogW(OLD.ranaEn(i)), scale: OLD.ranaEn(i)[2], old: OLD.ranaEn(i).slice(0, 2), what: 'ranaEn(' + i + '): the frog at mark ' + i + ', on the path\'s far edge' };
    SPOTS['nina.' + i] = { world: personW(OLD.ninaEn(i)), old: OLD.ninaEn(i), what: 'ninaEn(' + i + '): Carmen at mark ' + i + ', on the lawn on our side of the path' };
    SPOTS['perro.' + i] = { world: personW(OLD.perroEn(i)), old: OLD.perroEn(i), what: 'perroEn(' + i + '): Canelo a little ahead of the frog, on the path' };
  }
  const named = [['inicio12.luis', [174, 138], 'inicio12: Luis, by the big tree'], ['final12.carmen', [160, 146], 'final12: Carmen sits down by the big tree'],
    ['inicio13.luis', [62, 188], 'inicio13: Luis with the leash'], ['inicio13.carmen', [92, 198], 'inicio13, carmenvuelve: Carmen with the basket'], ['inicio13.perro', [54, 206], 'inicio13, perrocome, agarra, perrocome2: Canelo on the leash, by Luis'],
    ['escapa.perro', [150, 150], 'escapa: Canelo runs loose to here'], ['final13.carmen', [156, 196], 'final13: Carmen'],
    ['inicio14.abuela', [66, 182], 'inicio14: abuela waits at the path\'s turn, inside the arch (mark 0)'], ['inicio14.luis', [88, 200], 'inicio14: Luis'], ['inicio14.carmen', [46, 202], 'inicio14: Carmen']];
  for (const [k, p, w] of named) SPOTS[k] = { world: personW(p), old: p, what: w };
  OLD.ARBOL.forEach((a, i) => { SPOTS['carmenva.' + i] = { world: personW([a[0] + 18, a[1] + 12]), old: [a[0] + 18, a[1] + 12], what: 'carmenva: Carmen at tree ' + i + ' (ARBOL[' + i + '] + 18, 12)' }; });
  for (const s of Object.values(SPOTS)) s.new = s.scale != null ? frogQ(s.world) : personQ(s.world);
  Object.assign(SPOTS['frog.arbol0'], { world: frogW(ARBOL0), new: ARBOL0, what: 'LUGAR.arbol0: the frog at the first small tree (moved: see moves)' });

  /* ---- the named points of the set ---- */
  const PTS = {}, pt = (k, o) => { PTS[k] = o; };
  OLD.ARBOL.forEach((a, i) => pt('arbol.' + i, { screen: a, old: a, world: floor(a[0], a[1]), what: 'ARBOL[' + i + ']: the foot of small tree ' + i + ' (unchanged): the birds (NIDO), the cat in it (cara, cola), the lit ring, the shaking leaves and Carmen\'s place at it (carmenva) are all relative to it' }));
  pt('nido', { screen: OLD.NIDO, old: OLD.NIDO, what: 'NIDO: where up to three birds sit in a small tree, from its foot (unchanged): each bird on the crown\'s leaves' });
  OLD.MARCA.forEach((m, i) => pt('marca.' + i, { screen: m, old: m, world: floor(m[0], m[1]), what: 'MARCA[' + i + ']: ' + (i === 0 ? 'the path\'s turn inside the arch' : i === 8 ? 'before the big tree' : 'a stone in the path') }));
  pt('gran', { screen: F.GRAN, old: OLD.GRAN, world: floor(F.GRAN[0], F.GRAN[1]), what: 'the big tree\'s foot (GRAN, used only by the old background and its box): ' + (F.GRAN[0] - OLD.GRAN[0]) + ' px, ' + (F.GRAN[1] - OLD.GRAN[1]) + ' rows from the old' });
  pt('arco', { screen: [r2(ac.sx), r2(ac.sy)], world: W4(F.AC), posts: [[r2(pA.sx), r2(pA.sy)], [r2(pB.sx), r2(pB.sy)]], what: 'the arch: the middle of its opening on the ground (the cat sits there in d-corre, 46, 172), its two posts\' feet (A, down to the left; B, up to the right)' });
  pt('gato_banco', { screen: F.CAT_BENCH, old: [113, 134], v: r4(F.CAT_BENCH_V), what: 'the cat on the bench (story files d-corre, h-camino beats.1, cual-camino gato.si: x 113, y 134 -> remap): its lowest pixels on the seat\'s top; drawn after the bench\'s entry in the sorted list (front.banco), so no shadow on the lawn (shadows.gato)' });
  pt('ave_banco', { screen: AVEB, old: [106, 117], what: 'the bird on the bench (W.avebanco): drawn at (x, y) 15 x 12, its feet on the seat\'s back plank (moves)' });
  pt('corazon', { screen: [110, 30], old: [110, 30], what: 'heartAt: the heart of a happy ending, in the sky (unchanged)' });
  pt('sol', { screen: F.SUN.slice(0, 2), radius: F.SUN[2], what: 'the sun: baked into the set\'s sky (El frente\'s), behind the big tree\'s crown; no story touches it' });

  /* ---- things: the 22 touch keys ---- */
  const T = (name, what, extra = {}) => { const s = partScreen(name), w = boxAround(s[0], s[1], s[2], s[3]); return Object.assign({ set: true, world: W4(w), box: box(w), screen: s, what, old: { box: OLDBOX[name] } }, extra); };
  const person = id => ({ sprite: true, why: 'a person (today\'s sprite, drawn 1:1). caja(id) (camino.js:64): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged' });
  const aves = {}; for (let i = 0; i < 3; i++) for (let k = 0; k < 3; k++) aves['ave' + i + k] = { sprite: true, box: [OLD.ARBOL[i][0] + OLD.NIDO[k][0] - 8, OLD.ARBOL[i][1] + OLD.NIDO[k][1] - 6, 15, 12], why: 'a bird in small tree ' + i + ', place ' + k + ' (mkPajarito, drawn 15 x 12 at ARBOL + NIDO - (8, 6)): unchanged; the tree is where it was' };
  const lawnTop = F.HZ;
  const things = Object.assign({ luis: person('luis'), carmen: person('carmen'), abuela: person('abuela') }, aves, {
    perro: { sprite: true, why: 'Canelo (KIT.mkPerro): box [x - 14, y - 20, 28, 22] at W.perro, unchanged' },
    gato: { sprite: true, why: 'the cat (mkGato): box [x - 12, y - 18, 24, 20] at W.gato (on the ground), unchanged; up a tree it is the tree\'s' },
    arbol0: T('arbol0', 'small tree 0: its trunk and crown (still: at its height the wind moves no leaf a pixel)', { hand: [OLD.ARBOL[0][0], OLD.ARBOL[0][1] - 12], handWhy: 'the old hand point (the trunk, 12 rows over the foot)' }),
    arbol1: T('arbol1', 'small tree 1', { hand: [OLD.ARBOL[1][0], OLD.ARBOL[1][1] - 12] }),
    arbol2: T('arbol2', 'small tree 2', { hand: [OLD.ARBOL[2][0], OLD.ARBOL[2][1] - 12] }),
    banco: T('banco', 'the bench: its seat, backrest and legs'),
    grande: T('grande', 'the big tree: its crown (every pixel its leaves take at any wind step) down to the foot of its trunk (gran 1). As the old, its box has no si: it stays when sinGran hides the tree (story 13 never names it)'),
    porton: T('porton', 'the arch: its two posts and the iron arch over them'),
    camino: { set: true, ground: true, what: 'the path (the ground: trodden earth, the stones): the box round it on the picture, as the old one held its path' },
    parque: { set: true, ground: true, what: 'the park: the lawn from the horizon (row ' + lawnTop + ') to the bottom, the whole width: last in the hit order', old: { box: OLDBOX.parque } },
  });
  // the hand of the big tree: its trunk, 30 rows over its foot (the old had none: the box's middle, on the crown's lower edge)
  things.grande.hand = [F.GRAN[0] + 4, F.GRAN[1] - 40]; things.grande.handWhy = 'the hint hand\'s point (new: the old had none, so its box\'s middle): the trunk\'s right side, 40 rows over its foot, under the crown (the hand hangs from it to the right of Luis, who waits by the big tree at 174, 138: at the box\'s middle it was on his face)';
  { const roads = []; for (let i = 0; i < 240 * 216; i++) if (G.kinds['1'][i] === G.K.road) roads.push(i); const s = pxBox(roads.concat(tagsOf('1').camino || []));
    things.camino.screen = s; things.camino.world = W4(boxAround(s[0], s[1], s[2], s[3])); things.camino.box = [s[0], s[1], s[2] - s[0], s[3] - s[1]]; things.camino.old = { box: OLDBOX.camino }; }
  // (the path is flat on the ground: its box is its own screen rectangle, as El patio's lawn; a square world box can only reach it so)
  things.parque.box = [0, lawnTop, 240, 216 - lawnTop]; things.parque.world = W4(boxAround(0, lawnTop, 240, 216));

  /* ---- views: one, zoom 1, the old wide window ---- */
  const views = { wide: { zoom: 1, x0: 22, world: floor(120, 150), region: null, old: [22, 0, 196, 216], what: 'the park: the arch, the path with its stones, the three small trees, the bench, the big tree, the sky' } };

  /* ---- the review and level pictures ---- */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(cx - 98))), Math.max(0, Math.min(112, Math.round(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(cx - 49))), Math.max(0, Math.min(164, Math.round(cy - 26))), 98, 52];
    return { world: floor(cx, cy), screen: [cx, cy], zoom, crop, what }; };
  const PICS = PICTURES(pic);
  const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'camino' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  // story-file positions that move (the files are not edited: the host passes the point through remap, which gives the new one)
  const STORY_MOVES = [
    { old: [113, 134], new: F.CAT_BENCH, who: 'gato', why: 'the cat on the bench (d-corre and h-camino beats.1, cual-camino gato.si): on the new bench\'s seat, its lowest pixels on the seat\'s top (points.gato_banco), and drawn after the bench\'s entry in the sorted list (front.banco: sortY ' + F.BENCH_SORT + ')' },
  ];
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : p.kind === 'numbers' ? [p.x, p.y, p.w] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, PICS[n] ? { crop: PICS[n].crop, zoom: PICS[n].zoom } : { scene: 'patio', what: 'drawn by El patio (its sheet\'s picture parque.no): listed here because the pair\'s other side is this scene\'s' }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else if (p.kind === 'numbers') { e.to = { none: true }; e.what = 'W.pajaros: how many birds sit in each small tree (counts, not a place)'; }
    else {
      const ats = p.uses.map(u => u.at);
      if (p.x === -16 && p.y === -27) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0): not a place'; }
      else if (p.x === 0 && p.y === 0) { e.to = { none: true }; e.what = 'the cat up small tree 1 (en 1): its x, y are not used (the tree\'s place is ARBOL[1])'; }
      else if (ats.every(a => /respEn$/.test(a))) { e.to = { screen: [p.x, p.y] }; e.what = 'W.respEn: the answer cards in the sky (juego.js respBox: centred at x, their top at y): screen, unchanged'; }
      else { const mv = STORY_MOVES.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y], w = personW(at);
        e.to = { floor: w }; e.new = personQ(w); if (mv) { e.moved = true; e.why = mv.why; }
        e.what = ats.every(a => /\.(polvo|caracol)$/.test(a)) ? 'on the ground (the dust of a run, the snail): the ground under it; the same screen place' : ats.every(a => /\.(perro|gato)$/.test(a)) ? 'an animal\'s place (x, y): the ground under it' + (mv ? '' : '; the same screen place') : 'a person\'s feet (x, y): the ground under them; the same screen place'; }
    }
    return e;
  });

  // hop counts: every pair of LUGAR places, old against new
  const lugar = {}; for (const [k, v] of Object.entries(OLD.LUGAR)) lugar[k] = { spot: 'frog.' + k, q: SPOTS['frog.' + k].new, scale: v[2], old: v.slice(0, 2) };
  const hopsAll = [], names = Object.keys(lugar);
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const a = lugar[names[i]], b = lugar[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hopsAll.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) });
  }
  const hops = hopsAll.filter(h => h.old !== h.new);

  const setKey = {
    params: { gran: { values: ['1', '0'], fromW: 'W.sinGran ? "0" : "1": the big tree (story 13, donde-esta-el-gato, is at the other end of the path: no big tree; the path, its stones and everything else are the same)' } },
    key: 'gran, e.g. "1"',
    baked: STATES.map(k => ({ key: k, query: '?' + queryOf(k) })),
    bakedWhy: 'order 06 found 9 states: the background (sinGran) and six keys of the sprite layer (arbusto: the bush, arrastra: the frog pulled off his feet, galleta: the biscuit, lit: the counted trees\' rings, tumbo: the basket shaken, vuelan: the birds flown up). Only the big tree is the set\'s; the bush, the rings, the birds and the rest stay in the sprite layer, so these 2 baked states draw all 9 (and every review and level picture)',
  };

  const LINES_WHAT = {
    path: 'the path\'s middle line (world, PATH_PTS): from off the picture\'s left edge along +x through the arch to mark 0 (66, 182), then over marks 1 to 8 (up to the right, along -y to mark 4, a little flatter after) and on past the big tree off the picture\'s right edge; ' + F.PATH_HALF + ' either side of it (the frog\'s marks, ranaEn, on its far edge; Carmen\'s, ninaEn, on the lawn on our side; Canelo\'s, perroEn, on it)',
    arch: 'the arch over the path\'s first leg: its opening\'s middle on the ground at screen (' + Math.round(ac.sx) + ', ' + Math.round(ac.sy) + '), its posts at (' + Math.round(pA.sx) + ', ' + Math.round(pA.sy) + ') and (' + Math.round(pB.sx) + ', ' + Math.round(pB.sy) + '), ' + F.APH + ' high, the iron arch ' + F.ARISE + ' over them; its opening faces +x (into the park down to the right, out of it up to the left)',
    bench: 'the bench: its long side along y (parallel to the path\'s climb), facing the path (+x), on the path\'s far side in front of small tree 1, its middle on the ground at screen ' + JSON.stringify(F.BENCH_SCREEN),
  };

  return {
    scene: 'camino',
    made: 'node docs/proyecto/pixel/camino-sheet-make.js, from camino-set.html (window.CAMINO_SET) and coqui/ref/escenas/camino/. Order 33a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the park is built round the old picture: a place on its ground keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person\'s or an animal\'s place (x, y): the ground point under (x, y - 1), new (x, y) = old. So every ground position of camino.js (LUGAR, ranaEn, ninaEn, perroEn, enT, perroT, the acts\' places), its stories and its pairs keeps its numbers, but for the few in moves and in remap (moved); the sheet names each one (spots, remap, code, moves) with its world point',
      relative: 'what the old code draws or moves relative to a person, the frog, an animal, a small tree\'s foot or a mark (the birds at ARBOL + NIDO, the cat in a tree, the lit rings, the shaking leaves, what is carried, the leash, the dust, the snail by the dog, the bush at perroT(.46) + (16, 5), the bubbles) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the stars of the happy endings (final12, final13, final14), the heart (heartAt), the birds flying up (W.vuelan)',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: {
      what: 'a park on the world\'s axes, seen at the engine\'s 30 degrees (shadows to screen right): a path of trodden earth comes in from the picture\'s left edge along +x (down to the right) through the park\'s arch (two stone posts with caps, an iron arch over them), turns at the first mark and climbs along -y (up to the right) over seven flat stones, bends a little flatter and goes on past the big tree off the picture\'s right edge. Behind the path, at their old feet, the three small round trees; on its far side, in front of the middle one, the bench along the path, facing it; at its far end, on its far side, the big tree. The lawn is El frente\'s grass (the engine\'s GRASS ramp, calm, as El patio\'s); the horizon at row ' + F.HZ + ', El frente\'s far hills and day sky over it, its sun behind the big tree\'s crown',
      lines: LINES_WHAT,
      why: 'the brief and page 11 decision 9: the set stands on the world\'s axes and is seen at the engine\'s angle; nothing is built square to the camera. The old path already climbed on a slant from the bottom left: its marks 0 to 4 lie on one -y line within 1 px, so the path runs along -y there; its first leg, through the arch, runs along +x, so that whoever leaves goes through the arch and on up the path off the picture\'s edge (sevan). The arch could not stand across the path\'s climb: the old picture\'s lower left holds Carmen, Luis, abuela, the frog and the dog at the end of story 14, and a post there would stand in front of one of them. The three small trees keep their old feet (the birds, the cat in them, Carmen\'s places by them are all relative to them): free-standing round trees, not a row (a row along -y through the middle one, trees=row in the set\'s address, puts the first tree\'s trunk behind the arch and the third\'s crown into the big tree\'s: see the report). Every place on the ground keeps its old screen point (rules.floor)',
      moved: [
        'the big tree: its foot 8 px left and 10 rows further back than the old (200, 128 to ' + F.GRAN + '), its crown smaller and kept inside x 152 to 203, rows 13 to 62: its hint frame (h-camino asks for it) inside the view, its leaves clear of small tree 2\'s box, the dog at mark 8 (204, 130) with 5 rows of lawn and more before its trunk',
        'the bench: along y, facing the path; its box ' + JSON.stringify(things.banco.box) + ' (old [97, 126, 32, 18]); the cat on it and the bird on it follow it (remap, moves)',
        'the arch: over the path\'s first leg, its opening facing +x; its box ' + JSON.stringify(things.porton.box) + ' (old [22, 116, 36, 60]). The frog\'s place at the first tree (LUGAR.arbol0) moved left clear of its far post (moves)',
        'unchanged: the small trees\' feet, the marks, every bird\'s place, the frog\'s other places, every person\'s and animal\'s place but the cat on the bench',
      ],
    },
    behind: { what: 'nothing: the sun is baked into the set\'s sky (El frente\'s); the birds that fly up (W.vuelan) fly up from the crowns they sit on, in front of them and of the sky, as the old', items: [] },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, new: s.new }, s.scale != null ? { scale: s.scale } : {}, { old: s.old, what: s.what })])),
    lugar,
    hops,
    hopsWhat: 'each pair of LUGAR places whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one; every other pair keeps its count (hopsAll: all ' + hopsAll.length + ' pairs). ranaEn\'s marks are walked with the hop counts the acts give (ranaa, va), whatever the distance',
    hopsAll,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'camino.js never calls clip()',
    front: {
      how: 'the old background (fondo: the arch, the trees, the bench, the big tree) was drawn before everyone; the bench and the arch are set things someone can be behind now. At its entry in the list camino.js draw sorts by y (line ' + lineOf('L.sort((m,n)=>m.y-n.y)') + '), for each item drawn before it (a person, the frog, Canelo, the cat: each item says who it is), the set\'s own pixels of that part (camino-set.html part(name), PART_TAGS) are drawn again inside the item\'s box, only where that pixel is nearer to the camera than the item: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the ground point under its feet (a person or an animal: unproject(x, y - 1); the frog: unproject(b.x + b.w / 2, q.y + 25)). "Behind the bench" or "behind a post" is that depth test, not a row',
      plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
      boxes: 'a person: [x - 24, y - alto - 2, 48, alto + 3]; the frog: frogBox with dy; Canelo or the cat: [x - 16, y - 24, 32, 27]; the cat on the bench (at points.gato_banco): its v is points.gato_banco.v, the seat\'s front edge (so nothing of the bench goes over it)',
      parts: {
        banco: { sortY: F.BENCH_SORT, insert: 'before line ' + lineOf('L.sort((m,n)=>m.y-n.y)') + '\'s sort: L.push({y: ' + F.BENCH_SORT + ', front: "banco"})', why: 'whoever stands behind the bench (Carmen at small trees 0 and 1, story 13; Canelo barking at tree 0, d-corre, y 134) is drawn before it and the bench over them; the cat on its seat is before it too, its plane the seat\'s front edge (boxes), so nothing of the bench goes over it' },
        porton: { sortY: 9999, insert: 'before the sort: L.push({y: 9999, front: "porton"}) (after everyone)', why: 'whoever has gone out through the arch (sevan) is behind it: its posts and its iron over them' },
      },
      list: 'line ' + lineOf('Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.vis!==0)L.push(') + ' (people: id), ' + lineOf('["perro","gato"].forEach(k=>') + ' (animals: k), ' + lineOf('if(q.vis)L.push({y:q.y+27') + ' (the frog: id coqui): each item says who it is',
    },
    shadows: {
      coqui: { radius: .45, at: 'the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))', when: 'W.cq.vis and al > .5', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { grown: .35, nino: .3 }, at: 'the ground point under their feet on screen (unproject(x, y - 1))', when: 'visible (vis !== 0, al > .5)', cast: 'standing: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); sitting on the grass (sent): castShadow(g.x, g.y, .3, r)' },
      perro: { radius: .32, at: 'the ground point under its feet on screen (unproject(x, y - 1))', when: 'W.perro shown (vis !== 0)', cast: 'castShadow(g.x, g.y, .25, .32)' },
      gato: { radius: .25, at: 'as Canelo', when: 'W.gato on the ground (vis !== 0, en == null), not on the bench (points.gato_banco)', cast: 'castShadow(g.x, g.y, .25, .25)' },
      arbusto: { radius: .55, at: 'the ground point under its foot on screen (unproject(arbusto[0], arbusto[1] - 1))', when: 'W.arbusto', cast: 'castShadow(g.x, g.y, .3, .55)', why: 'the bush is the sprite layer\'s (a prop of story 14, as the old); its shadow seats it on the lawn' },
      dropped: 'camino.js:' + lineOf('for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5') + ' rana()\'s dotted shadow under the frog is not drawn: the engine casts his',
    },
    dropped: [
      'camino.js:' + lineOf('c.drawImage(spr("camino"+(W.sinGran?0:1)') + ' c.drawImage(spr("camino"...), fondo()) -> the set, for setKey(W)',
      'camino.js:' + lineOf('for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5') + ' the frog\'s dotted shadow -> the engine\'s cast shadow',
    ],
    moves: MOVES.map(m => Object.assign({ line: m.line, act: m.act, src: m.src, to: m.to }, m.respEn ? { respEn: m.respEn } : {}, m.pts ? { places: m.pts.map(q => ({ who: q[0] || 'whoever', old: q[1], new: q[2], world: q[3] })) } : {}, { why: m.why })),
    sevan: { gate: GATE, people: SEVAN_PU, dog: SEVAN_DOG, frog: SEVAN_FROG, what: 'moves (acts.sevan): each one\'s point just inside the arch\'s opening and their point past it up the path (screen: a person\'s feet, the dog\'s, the frog\'s q); GATE: the same, as (a, b) from the opening\'s middle in world units (a into the park, b towards post A)' },
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as camino.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (camino.js draw: line ' + lineOf('Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub&&p.vis!==0)bub2') + ' for a person, ' + lineOf('if(q.vis&&q.bub){const b=frogBox(q);bub2') + ' for the frog, ' + lineOf('if(o.bub)bub2(c,o.bub') + ' for Canelo and the cat). The first of these places whose bubble is wholly inside the view, clear of the corner card shown (hud: the biscuits, the guineos) and of every face (each visible person\'s and the frog\'s, its own too); if none is, the first (the old)',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2 - (W.guineos != null ? 16 : 0)); Canelo or the cat: (x, y - 22)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1, Canelo or the cat 8',
      faces: 'a person\'s face: [hx - 6, y + top + 5, 12, 10] (eyes to chin, not the hair), hx the head\'s middle; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heads: G.M.heads,
      headsWhat: 'each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the children drawn at -PX)',
      boards: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta galletas [2, 2, 90, 32]; W.tarjeta guineos [2, 2, 86, 32]',
    },
    code: CODE(),
    checks: { notes: [] },
  };

  function PICTURES(pic) {
    // each picture's centre is a screen point; both sides of a pair the same window, but árbol (its two sides were two windows in the old, and
    // they show two different things: a tree, the bench). An old 113 x 60 or 100 x 53 view (1.73 to 1.96 x) is zoom 2 when its subject is whole
    // in 98 x 52; camina and espera (1.31 x) are zoom 1, as parque
    return {
      'perro.si': pic(124, 161, 2, 'Canelo sits on the path, close'), 'perro.no': pic(124, 161, 2, 'the cat sits there, close'),
      'corre.si': pic(124, 161, 2, 'Canelo runs, dust behind him'), 'corre.no': pic(124, 161, 2, 'Canelo lies down'),
      'rapido.si': pic(124, 161, 2, 'Canelo walks fast, dust behind him'), 'rapido.no': pic(124, 161, 2, 'Canelo sniffs along, a snail beside him'),
      'despacio.si': pic(124, 161, 2, 'the cat walks, a snail beside it'), 'despacio.no': pic(124, 161, 2, 'the cat runs, dust behind it'),
      'gato.si': pic(113, 124, 2, 'the cat on the bench, close'), 'gato.no': pic(113, 124, 2, 'a bird on the bench\'s back, close'),
      'arbol.si': pic(157, 88, 2, 'small tree 2, close'), 'arbol.no': pic(113, 143, 2, 'the bench, no tree, close'),
      'parque.si': pic(120, 136, 1, 'the park: the arch, the path, the trees, the bench (the old window [22, 84, 196, 104])'),
      'camina.si': pic(115, 160, 1, 'Luis walks on the path'), 'camina.no': pic(115, 160, 1, 'Luis runs, dust behind him'),
      'espera.si': pic(115, 160, 1, 'Carmen stands still'), 'espera.no': pic(115, 160, 1, 'Carmen runs, dust behind her'),
      'hay.si': pic(113, 88, 2, 'the cat\'s face in small tree 1'), 'hay.no': pic(113, 88, 2, 'small tree 1, nothing in it'),
      'uno.si': pic(112, 87, 2, 'one bird in small tree 1'), 'uno.no': pic(112, 87, 2, 'three birds there'),
      'dos.si': pic(112, 87, 2, 'two birds in small tree 1'), 'dos.no': pic(112, 87, 2, 'one bird there'),
      'tres.si': pic(112, 87, 2, 'three birds in small tree 1'), 'tres.no': pic(112, 87, 2, 'two birds there'),
    };
  }

  function CODE() {
    const C = [], c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const L = s => lineOf(s), fl = p => ({ floor: personW(p), new: personQ(personW(p)) });
    c(L('const MARCA='), 'MARCA ' + OLD.MARCA.map(m => JSON.stringify(m)).join(' '), { points: OLD.MARCA.map((m, i) => 'marca.' + i), new: OLD.MARCA }, 'the floor rule: the same screen places (the set lays the stones at marks 1 to 7)');
    c(L('const ARBOL='), 'ARBOL ' + OLD.ARBOL.map(m => JSON.stringify(m)).join(' '), { points: ['arbol.0', 'arbol.1', 'arbol.2'], new: OLD.ARBOL }, 'unchanged: the small trees stand at their old feet');
    c(L('const ARBOL='), 'GRAN [200,128]', { point: 'gran', new: F.GRAN }, 'used only by the old background (dropped) and the big tree\'s box (things.grande)');
    c(L('const ARBOL='), 'BANCO [98,128,30,16]', { thing: 'banco', box: things.banco.box }, 'used by the old background (dropped), the bench\'s box (things.banco) and the bird on it (moves)');
    c(L('const NIDO='), 'NIDO [-9,-31] [8,-36] [0,-21]', { point: 'nido' }, 'relative to a small tree\'s foot: unchanged');
    c(L('[[1,0,5,5],[0,1,7,3],[7,0,1,5]'), 'galleta: the biscuit\'s rectangles [1,0,5,5] [0,1,7,3] [7,0,1,5] [8,-1,1,7] [6,1,1,3] (u(1,0,5,5) u(0,1,7,3) u(6,1,1,3) u(7,0,1,5) u(8,-1,1,7) u(1,1,1,1) u(3,3,2,1))', 'the biscuit\'s own drawing: unchanged');
    c(L('function guineo('), 'guineo: [0,2,2,2] [1,3,3,2] [3,4,4,2] [6,3,3,2] [8,1,2,3]', 'the guineo\'s own drawing: unchanged');
    c(L('const ranaEn='), 'ranaEn(i) = MARCA[i] - (22, 34), scale .96 - .015 i', { spots: 'rana.0 to rana.8' }, 'the floor rule: the same screen places');
    c(L('const ninaEn='), 'ninaEn(i) = MARCA[i] + (10, 22), y at most 206', { spots: 'nina.0 to nina.8' }, 'the floor rule: the same screen places');
    c(L('const perroEn='), 'perroEn(i) = MARCA[i] + (34, -9), x at most 204', { spots: 'perro.0 to perro.8' }, 'the floor rule: the same screen places');
    c(L('const LUGAR='), 'LUGAR centro [100,176,1], banco [74,128,.86], arbol0 [44,122,.8], arbol1 [126,122,.8], arbol2 [166,118,.8], gran [166,126,.84]', { spots: Object.keys(OLD.LUGAR).map(k => 'frog.' + k), moved: 'arbol0: ' + ARBOL0 + ' (moves)' }, 'the floor rule: the same screen places, but arbol0');
    c(L('const caja=id=>'), 'caja(id): [x - 11, y - alto(id), 22, alto(id)]', 'relative to the person: unchanged');
    c(L('const AVES=[];'), 'ave box [ARBOL[i][0] + NIDO[k][0] - 8, ARBOL[i][1] + NIDO[k][1] - 6, 15, 12]', 'relative to the tree: unchanged');
    c(L('{id:"perro",si:'), 'perro box [x - 14, y - 20, 28, 22]', 'relative: unchanged');
    c(L('{id:"gato",si:'), 'gato box [x - 12, y - 18, 24, 20]', 'relative: unchanged');
    for (const i of [0, 1, 2]) c(L('{id:"arbol0",box:'), 'box arbol' + i + ' [ARBOL[' + i + '][0]-17,ARBOL[' + i + '][1]-46,34,48] = ' + JSON.stringify(OLDBOX['arbol' + i]) + '; hand [ARBOL[' + i + '][0],ARBOL[' + i + '][1]-12]', { thing: 'arbol' + i, box: things['arbol' + i].box, hand: things['arbol' + i].hand });
    c(L('{id:"banco",box:'), 'box banco [BANCO[0]-1,BANCO[1]-2,BANCO[2]+2,18] = [97,126,32,18]', { thing: 'banco', box: things.banco.box });
    c(L('{id:"banco",box:'), 'box grande [GRAN[0]-40,GRAN[1]-112,58,116] = [160,16,58,116]', { thing: 'grande', box: things.grande.box, hand: things.grande.hand }, 'and a hand (new: the old had none, so the box\'s middle)');
    c(L('{id:"banco",box:'), 'box porton [22,116,36,60]', { thing: 'porton', box: things.porton.box });
    c(L('{id:"camino",box:'), 'box camino [30,128,170,76]', { thing: 'camino', box: things.camino.box });
    c(L('{id:"camino",box:'), 'box parque [0,100,240,116]', { thing: 'parque', box: things.parque.box });
    c(L('if(id==="abuela"){const ps='), 'gente abuela: translate(x, y - 50), scale(-1,1) when dir < 0; drawImage(im,-30,0); the basket at x + 2, y - 26', 'relative to her: unchanged');
    c(L('c.translate(x,y-im.height+1'), 'gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1', 'relative to the person: unchanged');
    c(L('c.save();c.translate(R(o.x),R(o.y)-im.height+2'), 'animal: translate(x, y - h + 2 + dy), scale(-1,1) when dir < 0, drawImage(im,-13,0)', 'relative: unchanged');
    c(L('if(o.bub)bub2(c,o.bub'), 'animal: its bubble at x, y - 22', { talk: true }, 'sheet talk: the first free place');
    c(L('for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5'), 'rana: the dotted shadow at b.x + 2, q.y + 25', 'dropped: the engine casts his shadow (shadows.coqui)');
    c(L('function bub2('), 'bub2: c.scale(2,2), bub(c,k,0,0,a)', 'relative: unchanged (the bubbles are drawn at twice their size)');
    c(L('c.drawImage(spr("camino"+(W.sinGran'), 'c.drawImage(spr("camino"+...,()=>fondo(!W.sinGran)),0,0)', 'dropped: the set, for setKey(W)');
    c(L('(W.lit||[]).forEach('), 'the lit ring round a counted tree: ellipse at ARBOL[i] - (0, 30), 19 x 16', 'relative to the tree: unchanged');
    c(L('if(W.tiembla&&F-W.tiembla<10)'), 'the shaking leaves at ARBOL + [-18,-36] [16,-40] [-14,-18] [18,-22]', 'relative to the tree: unchanged');
    c(L('(W.pajaros||[]).forEach((n,i)=>'), 'the birds at ARBOL[i] + NIDO[k] - (8, 6 + vuelan), 15 x 12', 'relative: unchanged (on the crown\'s leaves)');
    c(L('if(W.gato&&W.gato.en!=null&&typeof'), 'the cat in a tree: its face at ARBOL - (12, 34), its tail at ARBOL[0] + lado 9 - 12, ARBOL[1] - 20', 'relative to the tree: unchanged');
    c(L('if(W.caracol)L.push('), 'the snail at x - 9, y - 12 (its sort y)', 'relative: unchanged');
    c(L('if(W.arbusto)L.push('), 'the bush at arbusto - (22, 28) (sort y arbusto[1] + 2); the leash\'s end behind it at arbusto - (25, 9)', 'the sprite layer\'s, relative: unchanged (its shadow: shadows.arbusto)');
    c(L('L.sort((m,n)=>m.y-n.y)'), 'the sorted list', { front: ['banco', 'porton'] }, 'two entries added before the sort (front.parts)');
    c(L('if(W.correa&&W.perro&&'), 'the leash: from the frog\'s hand or a person\'s (x +- 10, y - 18) to the dog\'s collar (x +- 8, y - 11), or to correaA', 'relative: unchanged');
    c(L('if(W.polvo){const p=W.polvo;'), 'the dust at p.x + dir (4 + 6 i), p.y - 2; the speed lines', 'relative: unchanged');
    c(L('if(W.avebanco){'), 'the bird on the bench at BANCO[0] + 8, BANCO[1] - 11', { point: 'ave_banco', new: AVEB, moved: 'moves' });
    c(L('Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub&&p.vis!==0)bub2'), 'a person\'s bubble at x, y - alto - 1', { talk: true }, 'sheet talk: the first free place');
    c(L('if(q.vis&&q.bub){const b=frogBox(q);bub2'), 'the frog\'s bubble at b.x + (b.w >> 1), b.y + 2 - (W.guineos != null ? 16 : 0)', { talk: true }, 'sheet talk: the first free place');
    c(L('function talkAt('), 'talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]', 'relative to the person: unchanged');
    c(L('if(k==="espera"){'), 'respIcon espera: the frog at x + 6, y + 12; feet [9,30] [18,30]; the hand at x + 27, y + 5', 'the answer card\'s own drawing: unchanged');
    c(L('else if(k==="corre"){'), 'respIcon corre: the frog at x + 24, y + 21 rotated, drawn at -10,-9; lin(3,9); dust [5,29] [11,27]', 'the answer card\'s own drawing: unchanged');
    c(L('else if(k==="rapido"){'), 'respIcon rapido: the frog at x + 15, y + 12; lin(3,6); steps [18,30] [27,30]', 'the answer card\'s own drawing: unchanged');
    c(L('else if(k==="despacio"){'), 'respIcon despacio: the frog at x + 14, y + 12; the snail at x + 2, y + 23; steps [18,30] [25,30]', 'the answer card\'s own drawing: unchanged');
    c(L('else{const up=(F>>2)%2?3:0;g.drawImage(im,x+12'), 'respIcon camina: the frog at x + 12, y + 11; steps [2,29] [7,25]; the leaf [5,-3,2,9] [7,-1,2,5] [9,0,1,3]', 'the answer card\'s own drawing: unchanged');
    c(L('if(W.tarjeta==="galletas"){tarjeta(g,3,3,88,30)'), 'hud biscuits card tarjeta(g,3,3,88,30); the cat at 5,7', 'display: unchanged');
    c(L('(W.marcas||[]).forEach((m,i)=>{const x=34+i*18'), 'hud biscuits card: the marks at 34 + 18 i, 10; the paw [1,3] [5,1] [9,1] [13,3]', 'display: unchanged');
    c(L('if(W.tarjeta==="guineos"){tarjeta(g,3,3,84,30)'), 'hud guineos card tarjeta(g,3,3,84,30); the basket at 5,13; guineo(g,30+i*17,10,1.5)', 'display: unchanged');
    c(L('const enT=t=>'), 'enT(t): the frog on the walk back (story 14): (40 + 146 t - 10, 194 - 58 t - 8 sin(pi t) - 14)', 'the floor rule: the same screen places');
    c(L('const perroT=t=>'), 'perroT(t): the dog on the walk back: (40 + 146 tt - 2, 194 - 58 tt - 8 sin(pi tt) + 16)', 'the floor rule: the same screen places');
    c(L('async inicio12()'), 'inicio12: luis {x:174,y:138}; carmen at ninaEn(0); the frog at ranaEn(0); the dog at junto()', { floor: [personW([174, 138])], new: [[174, 138]] }, 'the floor rule: the same screen places');
    c(L('async final12()'), 'final12: mueve("carmen",160,146); the dog to LUGAR.gran - (12, -28)', fl([160, 146]), 'the floor rule: the same screen place');
    c(L('if(!n){await Promise.all([car(),yo()]);bounce(8)'), 'final12: the stars [150,60] [196,70] [176,50] [160,90] [200,96]', 'screen effect: unchanged (round the big tree)');
    c(L('async inicio13()'), 'inicio13: luis {x:62,y:188}, carmen {x:92,y:198}, perro {x:54,y:206}', { floor: [personW([62, 188]), personW([92, 198]), personW([54, 206])], new: [[62, 188], [92, 198], [54, 206]] }, 'the floor rule: the same screen places');
    c(L('W.gato={x:113,y:134,pose:"lava"'), 'inicio13: gato {x:113,y:134} (on the bench)', { point: 'gato_banco', new: F.CAT_BENCH, moved: 'as the story files\' (remap): on the new bench\'s seat' });
    c(L('async gatoarbol(o)'), 'gatoarbol: [0,1,2] the trees', 'not a place: the trees\' numbers');
    c(L('async lit(o)'), 'lit: [0,1,2]', 'not a place');
    c(L('async carmenvuelve()'), 'carmenvuelve: mueve("carmen",92,198)', fl([92, 198]), 'the floor rule: the same screen place');
    c(L('async perrocome(){'), 'perrocome: animalA("perro",54,206,"walk")', fl([54, 206]), 'the floor rule: the same screen place');
    c(L('async escapa(){'), 'escapa: animalA("perro",150,150,"run")', fl([150, 150]), 'the floor rule: the same screen place');
    c(L('async agarra(){'), 'agarra: animalA("perro",54,206,"walk")', fl([54, 206]), 'the floor rule: the same screen place');
    c(L('async cuentaaves(){'), 'cuentaaves: for [1,2,3]', 'not a place: the counts');
    c(L('async carmenva(o)'), 'carmenva: mueve("carmen",ARBOL[i][0]+18,ARBOL[i][1]+12)', { spots: ['carmenva.0', 'carmenva.1', 'carmenva.2'] }, 'relative to the tree: unchanged (whoever is behind the bench: front.banco)');
    c(L('async perrocome2(){'), 'perrocome2: animalA("perro",54,206,"walk")', fl([54, 206]), 'the floor rule: the same screen place');
    c(L('async final13(){'), 'final13: mueve("carmen",156,196)', fl([156, 196]), 'the floor rule: the same screen place');
    c(L('if(n>=3){W.heart=1;SFX.win();fx({t:"star",n:30,pts:[[90,150]'), 'final13: the stars [90,150] [150,150] [120,130] [100,176] [140,176]', 'screen effect: unchanged (over the lawn)');
    c(L('async inicio14(){'), 'inicio14: abuela {x:66,y:182}, luis {x:88,y:200}, carmen {x:46,y:202}; the bush at perroT(.46) + (16, 5); the frog at enT(1), the dog at perroT(1)', { floor: [personW([66, 182]), personW([88, 200]), personW([46, 202])], new: [[66, 182], [88, 200], [46, 202]] }, 'the floor rule: the same screen places');
    c(L('async cae(){'), 'cae: the basket shakes [4,-4,3,0]', 'not a place: offsets');
    c(L('if(n>=3){W.heart=1;SFX.win();fx({t:"star",n:30,pts:[[40,120]'), 'final14: the stars [40,120] [90,130] [64,110] [50,150] [90,160]', 'screen effect: unchanged (by the arch)');
    c(L('async sevan()'), 'sevan: p.x -= 4 eight times, fading; the dog to -10, y; the frog to 8, y', { moved: 'moves: out through the arch and up the path off the picture (sheet sevan)' });
    c(L('KIT.escena({id:"camino"'), 'CAM.wide [22,0,196,216]', { view: 'wide', zoom: 1, x0: views.wide.x0 });
    c(L('KIT.escena({id:"camino"'), 'heartAt [110,30]', { point: 'corazon', new: PTS.corazon.screen });
    c(L('fresh:()=>({gente:{},perro:null'), 'fresh(): pajaros [0,0,0]; cq at LUGAR.inicio', 'the counts; the frog at mark 0 (the floor rule)');
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: camino\'s fresh() puts him at LUGAR.inicio');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', 'a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)');
    return C;
  }
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HANDR = [-12, 0, 36, 54];        // juego.js hand(): 12 x 15 cells of 3 px, drawn from (p.x - 12, p.y), 9 px lower on the down beat
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);   // its rows of cells: o ink, w white
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([Math.round(hp[0]) - 12 + i * 3, Math.round(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };   // its drawn cells, both beats
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };
// the frame's rings (juego.js spot): between 5 and 12 px outside the box; a face crossed by them (not wholly inside the inner edge, not wholly outside)
const ringMeets = (b, f) => { const outer = [b[0] - 12, b[1] - 12, b[2] + 24, b[3] + 24], inner = [b[0] - 5, b[1] - 5, b[2] + 10, b[3] + 10]; return meets(f, outer) && !within(f, inner); };

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'camino') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'camino-sheet-'));
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
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), M = G.M;
  const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
  /* the inventory: every thing, place, view, position, pair and level picture */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-camino.json'), 'utf8'));
  const pairSides = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'camino').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'camino') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('camino.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n.replace(/^0\./, '.')) || e.old.replace(/\s/g, '').includes(n)))) P.push('camino.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  for (const m of sh.moves) if (!LINES[m.line - 1].includes(m.src)) P.push('moves: line ' + m.line + ' does not hold ' + m.src.slice(0, 60));
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-camino (' + pairSides.length + ' pictures here; parque.no is El patio\'s), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + pos.inSceneFile.length + ' places of camino.js named in code, ' + STATES.length + ' baked states (the old 9)');

  /* hops */
  { const L = sh.lugar, ks = Object.keys(L), changed = [];
    for (let i = 0; i < ks.length; i++) for (let j = i + 1; j < ks.length; j++) { const a = L[ks[i]], b = L[ks[j]];
      const o = hop(Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1])), n = hop(Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]));
      if (o !== n) changed.push(ks[i] + '-' + ks[j] + ' ' + o + ' ' + n); }
    const listed = sh.hops.map(h => h.a + '-' + h.b + ' ' + h.old + ' ' + h.new);
    for (const c of changed) if (!listed.includes(c)) P.push('hops: ' + c + ' changed and is not in sheet hops');
    for (const c of listed) if (!changed.includes(c)) P.push('hops: sheet hops lists ' + c + ', which is not what the places give');
    for (const c of changed) P.push('hops: ' + c + ' is not the old count (no place here is at an opening: every count must be the old one)');
    if (sh.hopsAll.length !== ks.length * (ks.length - 1) / 2) P.push('hopsAll: ' + sh.hopsAll.length + ' pairs');
    // the walks in the recorded runs between LUGAR places (old points)
    const at = {}; for (const k of ks) at[L[k].old.join(',')] = k; const walks = new Map();
    for (const r of runs) { let prev = null; for (const ln of r.lines) { const q = ln.W.cq; if (!q || !q.vis) continue; const k = at[q.x + ',' + q.y]; if (!k) { prev = null; continue; }
      if (prev && prev !== k) { const pr = [prev, k].sort((x, y) => ks.indexOf(x) - ks.indexOf(y)).join(' - '); walks.set(pr, (walks.get(pr) || 0) + 1); } prev = k; } }
    notes.push('hops: all ' + sh.hopsAll.length + ' pairs of LUGAR places (round(d / 30), 1 to 4, kit.js acts.ir) keep the old count (arbol0 moved ' + (L.arbol0.old[0] - L.arbol0.q[0]) + ' px left: its distances ' + sh.hopsAll.filter(h => h.a === 'arbol0' || h.b === 'arbol0').map(h => h.a + '-' + h.b + ' ' + h.dOld + ' -> ' + h.dNew).join(', ') + '); the frog walks between places in the recorded runs: ' + [...walks.entries()].map(([k, n]) => k + ' (' + n + ')').join(', ')); }

  /* the set's pixels: which part drew each, its depth */
  const tagMap = key => { const m = new Array(240 * 216).fill(null); for (const [k, list] of Object.entries(G.parts[key])) for (const i of list) m[i] = k; return m; };
  const TAGS = Object.fromEntries(STATES.map(k => [k, tagMap(k)]));
  const countIn = (tag, r, names) => { let n = 0; for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) if (names.includes(tag[y * 240 + x])) n++; return n; };
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];

  /* every set thing's pixels inside its touch box, its leaves at every wind step; the box's 8 corners give it; nothing decorative; greenery off the
     other things' boxes */
  { const res = [];
    for (const name of ['porton', 'arbol0', 'arbol1', 'arbol2', 'banco', 'grande', 'camino']) { const b = sh.things[name].box; let out = 0, n = 0;
      for (const key of STATES) for (const i of (G.parts[key][name] || []).concat(G.leaf[key][name] || [])) { n++; const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; }
      if (out) P.push('box: ' + out + ' px of ' + name + ' (its leaves at every wind step) are outside its touch box ' + JSON.stringify(b));
      if (n && name !== 'camino') res.push(name + ' ' + JSON.stringify(b)); }
    // the path's: every path pixel (the ground kind) inside the camino box
    { const b = sh.things.camino.box; let out = 0; for (let i = 0; i < 240 * 216; i++) if (G.kinds['1'][i] === G.K.road) { const x = i % 240, y = Math.floor(i / 240); if (!(x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) out++; } if (out) P.push('box: ' + out + ' px of the path outside the camino box'); }
    const parts = new Set(Object.values(G.parts).flatMap(p => Object.keys(p)));
    for (const p of parts) if (!sh.things[p] || !sh.things[p].set) P.push('decor: the set has a part ' + p + ' that is no touch key\'s');
    // the hit order (kit.js hit: cosas in order, each box widened by its slack m): every pixel of each set thing answers that thing; and no crown's
    // leaf answers another thing (greenery off touch targets)
    const ORDER = inv.given.cosas.filter(t => sh.things[t.id] && sh.things[t.id].set).map(t => [t.id, t.m == null ? 3 : t.m]);
    const hitAt = (x, y) => { for (const [id, m] of ORDER) { const b = sh.things[id].box; if (x >= b[0] - m && x < b[0] + b[2] + m && y >= b[1] - m && y < b[1] + b[3] + m) return id; } return null; };
    const wrong = {};
    for (const key of STATES) for (const name of ['porton', 'arbol0', 'arbol1', 'arbol2', 'banco', 'grande']) for (const i of (G.parts[key][name] || []).concat(G.leaf[key][name] || [])) { const h = hitAt(i % 240, Math.floor(i / 240)); if (h !== name) { const k = name + ' -> ' + h; wrong[k] = (wrong[k] || 0) + 1; } }
    for (const [k, n] of Object.entries(wrong)) P.push('hit: ' + n + ' px of ' + k + ' (a touch there answers the other thing)');
    const ov = []; const ks = ['arbol0', 'arbol1', 'arbol2', 'banco', 'grande', 'porton']; for (let i = 0; i < ks.length; i++) for (let j = i + 1; j < ks.length; j++) if (meets(sh.things[ks[i]].box, sh.things[ks[j]].box)) ov.push(ks[i] + '/' + ks[j]);
    notes.push('boxes: every pixel of each set thing (the big tree\'s leaves at every wind step: 1 px either way) inside its touch box: ' + res.join(', ') + '; every path pixel inside the camino box ' + JSON.stringify(sh.things.camino.box) + '; every pixel of each set thing answers that thing in the hit order (boxes that overlap: ' + (ov.join(', ') || 'none') + ', each overlap held by the one drawn there); the set\'s parts are ' + [...parts].sort().join(', ') + ' (each a touch key\'s: nothing decorative)'); }

  /* every castShadow call of the bake darkens: its strength is 1 or 2 (a fraction is lost in the Uint8 mask: El patio's trunk and nest), its radius
     positive, and it sets shadow on the picture; every part that casts has shadow on its ground */
  { const byPart = {};
    for (const key of STATES) for (const c of G.shadows[key]) { const [x, y, z, r, s] = c.args, k = c.part || '(none)';
      if (!(s >= 1) || !(r > 0) || !(z >= 0)) P.push('shadow: ' + key + ' ' + k + ' castShadow(' + c.args.map(r2).join(', ') + '): strength ' + s + ', radius ' + r + ' (nothing is cast)');
      const b = byPart[k] = byPart[k] || { calls: 0, set: 0, zero: 0 }; b.calls++; b.set += c.set; if (!c.set) b.zero++; }
    for (const [k, b] of Object.entries(byPart)) if (!b.set) P.push('shadow: the part ' + k + ' casts ' + b.calls + ' times and darkens nothing');
    notes.push('shadows: every castShadow call of the bake has strength 1 and a radius (none lost), each casting part darkens: ' + Object.entries(byPart).map(([k, b]) => k + ' ' + b.calls + ' calls, ' + b.set + ' px set (' + b.zero + ' calls wholly over shadow already)').join('; ')); }

  /* the ground: only lawn and path; the path is the path (within PATH_HALF of its line); nothing painted round an empty place */
  { const K = G.kinds['1']; let other = 0, n = 0; for (let i = 0; i < 240 * 216; i++) { const y = Math.floor(i / 240); if (y < F.HZ) continue; if (K[i] !== G.K.grass && K[i] !== G.K.road) other++; if (K[i] === G.K.road) n++; }
    if (other) P.push('ground: ' + other + ' px of the ground are neither lawn nor path');
    notes.push('ground: the lawn and the path only (' + n + ' px of path); the set paints nothing else on the ground but the shadows its things cast and the seven stones in the path'); }

  /* the old sprite layer's shapes */
  const alto = (id, p) => id === 'abuela' ? 51 : (p && p.sent ? 40 : 44);
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const people = w => Object.entries(w.gente || {}).filter(([id, p]) => shown(p));
  const poseKey = (id, p) => { const ps = p.pose === 'wave' ? 'wave0' : p.pose === 'alto' || p.pose === 'dedos' ? 'wave0' : p.pose === 'offer' ? 'offer' : 'idle'; return id + '.' + ps + (p.sent && id !== 'abuela' ? '.sent' : '') + '.' + (p.dir < 0 ? -1 : 1); };
  const maskOf = (id, p) => M.masks[poseKey(id, p)] || M.masks[id + '.idle' + (p.sent && id !== 'abuela' ? '.sent' : '') + '.' + (p.dir < 0 ? -1 : 1)];
  const rowsAt = (rows, x, y) => rows.map(r => [y + r[0], x + r[1], x + r[2]]);
  const rowsBox = rs => { const ys = rs.map(r => r[0]); return [Math.min(...rs.map(r => r[1])), Math.min(...ys), Math.max(...rs.map(r => r[2])) - Math.min(...rs.map(r => r[1])) + 1, Math.max(...ys) - Math.min(...ys) + 1]; };
  const personRows = (id, p) => rowsAt(maskOf(id, p), Math.round(p.x), Math.round(p.y));
  const animalPose = (k, o) => { const ps = M.animals[k + '.' + o.pose + '.0.1'] ? o.pose : k === 'perro' ? 'sit' : 'sit'; return ps; };
  const animalRows = (k, o) => { const rs = M.animals[k + '.' + animalPose(k, o) + '.0.' + (o.dir < 0 ? -1 : 1)]; return rowsAt(rs, Math.round(o.x), Math.round(o.y) + Math.round(o.dy || 0)); };
  const onGround = (w, k) => w[k] && w[k].vis !== 0 && w[k].en == null && w[k].x != null;
  const faceOf = (id, p) => { const hd = sh.talk.heads[id + (p.sent && id !== 'abuela' ? '.sent' : '')], x = Math.round(p.x), y = Math.round(p.y), hx = p.dir < 0 ? x - hd.head + (id === 'abuela' ? 0 : 1) : x + hd.head; return [Math.round(hx - 6), y + hd.top + 5, 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + Math.round(q.dy || 0), b.w - 4, Math.round(b.h * .6)]; };
  const facesOf = w => { const f = people(w).filter(([id, p]) => !(p.al != null && p.al < .5)).map(([id, p]) => [id + '\'s face', faceOf(id, p)]); if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  const BUBR = sh.bubbles.rects, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const rowsMeet = (rs, r) => { let n = 0; for (const [y, a, b] of rs) if (y >= r[1] && y < r[1] + r[3]) n += Math.max(0, Math.min(b + 1, r[0] + r[2]) - Math.max(a, r[0])); return n; };

  /* the old runs' W in the new places: moves (for the acts the story uses; the frog's place at tree 0), remap moved (the story's own positions) */
  const MVall = sh.moves.flatMap(m => (m.places || []).map(q => Object.assign({ act: m.act }, q)));
  const RMall = sh.remap.filter(e => e.moved).map(e => ({ old: e.old, new: e.new, files: e.uses.map(u => u.split(' ')[0].replace(/\.json$/, '')) }));
  let MV = MVall, RM = RMall, EN = null;
  const remapW = w0 => { const w = JSON.parse(JSON.stringify(w0));
    if (EN && w.respEn == null && (w.gente && Object.keys(w.gente).length)) w.respEn = EN;   // the answer cards in the sky (moves: inicio12, inicio13), once the act has run
    for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null) continue; const m = MV.find(q => (q.who === 'whoever' || q.who === id) && q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y));
      if (m) { p.x = m.new[0]; p.y = m.new[1]; continue; } const r = RM.find(q => q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y)); if (r) { p.x = r.new[0]; p.y = r.new[1]; } }
    for (const k of ['perro', 'gato']) { const p = w[k]; if (!p || p.x == null) continue; const m = MV.find(q => q.who === k && q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y));
      if (m) { p.x = m.new[0]; p.y = m.new[1]; continue; } const r = RM.find(q => q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y)); if (r) { p.x = r.new[0]; p.y = r.new[1]; } }
    if (w.cq) { const m = MV.find(q => q.who === 'cq' && q.old[0] === Math.round(w.cq.x) && q.old[1] === Math.round(w.cq.y)); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }
    return w; };
  const actsOf = st => new Set((JSON.stringify(st).match(/"act":\s*"[a-z0-9]+"/g) || []).map(a => a.split('"')[3]));
  const forRun = r => { const a = actsOf(r.story); MV = MVall.filter(q => a.has(q.act) || q.act === '*'); RM = RMall.filter(q => q.files.includes(r.story.id)); EN = (sh.moves.find(m => m.respEn && a.has(m.act)) || {}).respEn || null; };
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;

  /* the preview puts everyone where the sheet does: at every moment, each person, the frog, Canelo and the cat (PREVIEW.remapW against this
     maker's remapW) */
  { let nP = 0, bad = 0;
    runs.forEach((r, ri) => { forRun(r); r.lines.forEach((ln, li) => { const w = remapW(ln.W), pv = G.PV[ri][li], mine = {};
      for (const [id, p] of Object.entries(w.gente || {})) if (p && p.x != null) mine[id] = [Math.round(p.x), Math.round(p.y)];
      if (w.cq) mine.cq = [w.cq.x, w.cq.y]; for (const k of ['perro', 'gato']) if (w[k] && w[k].x != null) mine[k] = [Math.round(w[k].x), Math.round(w[k].y)];
      for (const k of new Set([...Object.keys(mine), ...Object.keys(pv)])) { nP++; if (JSON.stringify(mine[k]) !== JSON.stringify(pv[k])) { bad++; if (bad < 20) P.push('preview: ' + r.story.id + ' ' + r.plan + ' ' + ln.path + ': ' + k + ' at ' + JSON.stringify(pv[k]) + ' in the preview, ' + JSON.stringify(mine[k]) + ' in the sheet'); } } }); });
    notes.push('preview: at every moment of the ' + runs.length + ' runs (' + nP + ' places of people, the frog, Canelo and the cat) camino-preview.html puts everyone exactly where the sheet does (' + bad + ' differ)'); }

  /* the ground under everyone: standing on clear ground. At every moment: for each person, the frog, Canelo and the cat on the ground, no pixel of
     the set's standing things (the arch, the trees, the bench) nearer than them inside their sprite's pixels, unless that thing is a front part and
     they are drawn before its entry (then the set's pixels go over them: they are behind it); and at least 5 rows of lawn between their feet and
     the foot of whatever stands behind them (a trunk, a post, the bench), at every column of their feet. The cat on the bench sits on its seat */
  const vAt = (sx, sy) => { const g = E.atZ(sx, sy, 0); return (g[0] + g[1]) / E.R2; };
  const nearerRows = (key, rs, v, names) => { const Z = G.z[key], tag = TAGS[key], out = {};
    for (const [y, a, b] of rs) { if (y < 0 || y >= 216) continue; for (let x = Math.max(0, a); x <= Math.min(239, b); x++) { const i = y * 240 + x; if (names.includes(tag[i]) && Z[i] > v / COS - (y + .5 - E.OY) * T30 / E.S) out[tag[i]] = (out[tag[i]] || 0) + 1; } }
    return out; };
  const CLEAR = 5, footOf = {};
  const footRows = key => footOf[key] || (footOf[key] = (() => { const tag = TAGS[key], out = new Array(240).fill(null).map(() => []);
    for (let x = 0; x < 240; x++) { let prev = null; for (let y = 215; y >= 0; y--) { const t = tag[y * 240 + x]; if (SOLID.includes(t) && t !== prev) { if (!out[x].some(e => e[1] === t)) out[x].push([y, t]); } prev = t; } }
    return out; })());   // per column, each standing part's lowest pixel
  const clearLeast = {}; let nStand = 0;
  const clearCheck = (where, who, key, cols, feet) => { const fr = footRows(key);
    for (let x = Math.max(0, cols[0]); x <= Math.min(239, cols[1]); x++) for (const [fy, t] of fr[x]) { if (fy >= feet) continue;   // in front of them: the depth test (nearer) speaks for it
      const g = feet - fy - 1, kind = t === 'porton' ? 'post' : t === 'banco' ? 'bench' : 'trunk';
      if (g < 60 && (!clearLeast[kind] || g < clearLeast[kind][0])) clearLeast[kind] = [g, where + ' ' + who];
      if (g < CLEAR) P.push('clear ground: ' + where + ' ' + who + ': ' + g + ' rows of lawn between the feet (row ' + feet + ') and the foot of ' + t + ' (row ' + fy + ') at x ' + x + ' (keep ' + CLEAR + ')'); } };
  const benchFront = sh.front.parts.banco.sortY;
  const catOnBench = o => Math.round(o.x) === F.CAT_BENCH[0] && Math.round(o.y) === F.CAT_BENCH[1];
  const behind = new Map(), seenG = new Set(), animalBehind = new Map();
  const groundCheck = (where, w) => {
    const key = keyOf(w); if (!STATES.includes(key)) P.push('state: ' + where + ' reaches ' + key + ', which is not baked');
    const items = [];
    for (const [id, p] of people(w)) items.push({ who: id, sortY: p.y, rows: personRows(id, p), v: vAt(Math.round(p.x), Math.round(p.y) - 1), feet: Math.round(p.y) + Math.max(...maskOf(id, p).map(r => r[0])), cols: null, at: Math.round(p.x) + ',' + Math.round(p.y) });
    for (const k of ['perro', 'gato']) if (onGround(w, k)) { const o = w[k], rs = animalRows(k, o); items.push({ who: k, sortY: o.y, rows: rs, v: vAt(Math.round(o.x), Math.round(o.y) - 1), feet: Math.max(...rs.map(r => r[0])), at: Math.round(o.x) + ',' + Math.round(o.y), bench: k === 'gato' && catOnBench(o) }); }
    const q = w.cq; if (q && q.vis && !(q.al <= .3)) { const b = frogBox(q), dy = Math.round(q.dy || 0), rs = []; for (let y = b.y + dy; y < b.y + dy + b.h; y++) rs.push([y, b.x + 2, b.x + b.w - 3]);
      items.push({ who: 'the frog', sortY: q.y + 27, rows: rs, v: vAt(b.x + b.w / 2, q.y + 25), feet: q.y + 25, cols: [b.x + 2, b.x + b.w - 3], at: q.x + ',' + q.y, frog: true }); }
    for (const it of items) {
      const k = JSON.stringify([it.who, it.at, key, it.rows.length, it.sortY]); if (seenG.has(k)) continue; seenG.add(k); nStand++;
      if (it.bench) { // the cat on the bench: its lowest pixels on the seat's top (the bench part, its top face, right under them); nothing nearer than the seat's front edge over it
        const nb = nearerRows(key, it.rows, F.CAT_BENCH_V, SOLID); for (const [part, n] of Object.entries(nb)) P.push('the cat on the bench: ' + where + ' ' + n + ' px of ' + part + ' nearer than the seat\'s front edge over it');
        const last = Math.max(...it.rows.map(r => r[0])), low = it.rows.filter(r => r[0] === last), tag = TAGS[key]; let on = 0, n = 0;
        for (const [y, a, b] of low) for (let x = a; x <= b; x++) { n++; if (tag[(y + 1) * 240 + x] === 'banco' || tag[(y + 2) * 240 + x] === 'banco') on++; }
        if (on < n) P.push('the cat on the bench: ' + where + ' ' + (n - on) + ' of the ' + n + ' columns of its lowest row have no bench under them');
        continue; }
      if (it.who === 'perro' || it.who === 'gato') { const tag = TAGS[key]; for (const [y, a, b] of it.rows) for (let x = a; x <= b; x++) { const t = tag[y * 240 + x]; if (SOLID.includes(t)) { const kk = it.who + ' at ' + it.at + ' before ' + t; animalBehind.set(kk, (animalBehind.get(kk) || 0) + 1); } } }
      const near = nearerRows(key, it.rows, it.v, SOLID);
      for (const [part, n] of Object.entries(near)) {
        const fp = sh.front.parts[part];
        if (fp && it.sortY < fp.sortY) { const b = it.who + ' behind ' + part; behind.set(b, (behind.get(b) || 0) + 1); continue; }
        P.push('ground: ' + where + ' ' + it.who + ' at ' + it.at + ': ' + n + ' px of ' + part + ' nearer than them inside their sprite' + (fp ? ' (drawn after its front entry, y ' + fp.sortY + ')' : ''));
      }
      const cols = it.cols || (() => { const last = Math.max(...it.rows.map(r => r[0])), rs = it.rows.filter(r => r[0] >= last - 1); return [Math.min(...rs.map(r => r[1])), Math.max(...rs.map(r => r[2]))]; })();
      clearCheck(where, it.who + ' at ' + it.at, key, cols, it.feet);
      // nobody stands on a trunk's or a post's foot: their ground point not inside a standing thing's footprint (its pixels at their feet row)
    }
  };
  for (const r of runs) { forRun(r); for (const L of r.lines) groundCheck(r.story.id + ' ' + r.plan + ' ' + L.path + ':', remapW(L.W)); }
  notes.push('find them: Canelo and the cat have the lawn or the path behind them but ' + (animalBehind.size ? [...animalBehind.entries()].map(([k, n]) => k + ' (' + n + ' px)').join(', ') : 'nowhere') + ' (the snail always the path or the lawn)');
  notes.push('ground: ' + nStand + ' distinct stands of people, the frog, Canelo and the cat: nothing of the arch, the trees or the bench nearer than them inside their sprites, but where they are behind the bench or the arch and drawn before its entry (front): ' + (behind.size ? [...behind.entries()].map(([k, n]) => k + ' (' + n + ')').join(', ') : 'no one') + '; at least ' + CLEAR + ' rows of lawn between anyone\'s feet and the foot of what stands behind them: the least behind a trunk ' + (clearLeast.trunk || ['-']).join(' rows, ') + '; a post ' + (clearLeast.post || ['-']).join(' rows, ') + '; the bench ' + (clearLeast.bench || ['-']).join(' rows, '));

  /* the bubbles: every bubble wholly inside the view, clear of the corner cards, on no face */
  let nM = 0, nB = 0, worstView = 99, worstBoard = 99; const seen = new Set();
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } return bubRect(k, top[0], top[1]); };
  // each person's recorded bubble and "amor" (poke: anyone touched, at any moment), Carmen's "q" (mirarriba); the frog's recorded one, his "amor"
  // (lame, acaricia); Canelo's and the cat's recorded ones and "amor" where an act shows it (ronronea, final13, final14)
  const bubblesOf = (w, extra = {}, view = VIEW) => {
    const out = [], boards = boardsOf(w, view[0]), faces = facesOf(w);
    for (const [id, p] of people(w)) { if (p.al != null && p.al < .5) continue; const ks = new Set(p.bub ? [p.bub] : []); ks.add('amor'); if (extra[id]) ks.add(extra[id]);
      for (const k of ks) out.push([id + ' (' + Math.round(p.x) + ',' + Math.round(p.y) + ') "' + k + '"', talk(k, [Math.round(p.x), Math.round(p.y) - alto(id, p) - 1], view, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5)) { const b = frogBox(q); for (const k of new Set([q.bub, extra.cq].filter(Boolean))) out.push(['the frog (' + q.x + ',' + q.y + ') "' + k + '"', talk(k, [b.x + (b.w >> 1), b.y + 2 - (w.guineos != null ? 16 : 0)], view, boards, faces, b.w >> 1)]); }
    for (const k of ['perro', 'gato']) if (onGround(w, k)) { const o = w[k]; for (const kk of new Set([o.bub, extra[k]].filter(Boolean))) out.push([k + ' (' + Math.round(o.x) + ',' + Math.round(o.y) + ') "' + kk + '"', talk(kk, [Math.round(o.x), Math.round(o.y) - 22], view, boards, faces, 8)]); }
    return out; };
  const judge = (where, rect, box, boards, faces) => {
    if (!within(rect, box)) { P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is not wholly inside ' + JSON.stringify(box)); return; }
    worstView = Math.min(worstView, rect[0] - box[0], box[0] + box[2] - rect[0] - rect[2], rect[1] - box[1], box[1] + box[3] - rect[1] - rect[3]);
    for (const [bn, b] of boards) { if (meets(rect, b)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is over ' + bn + ' ' + JSON.stringify(b)); else worstBoard = Math.min(worstBoard, gapTo(rect, b)); }
    for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is on ' + fn + ' ' + JSON.stringify(f));
  };
  const EXTRA = { mirarriba: { carmen: 'q' }, lame: { cq: 'amor' }, acaricia: { cq: 'amor' }, ronronea: { gato: 'amor' }, final13: { perro: 'amor' }, final14: { perro: 'amor' } };
  for (const r of runs) { forRun(r); for (const L of r.lines) {
    if (JSON.stringify(L.cam) !== '[22,0,196,216]') P.push(r.story.id + ' ' + r.plan + ' ' + L.path + ': a view the sheet does not have ' + JSON.stringify(L.cam));
    const w = remapW(L.W), boards = boardsOf(w, x0), faces = facesOf(w); nM++;
    const st = L.path && at(r.story, L.path), extra = st && typeof st === 'object' && EXTRA[st.act] || {};
    for (const [who, rect] of bubblesOf(w, extra)) { const key = JSON.stringify([who, rect, boards, faces]); if (seen.has(key)) continue; seen.add(key); nB++; judge(r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + who, rect, VIEW, boards, faces); }
  } }

  /* the asks: hint frames inside the view, no frame's rings across a face where the old ones had none, the hand on no face, the answer cards over no one */
  const cajaBox = (id, p) => [Math.round(p.x) - 11, Math.round(p.y) - alto(id, p), 22, alto(id, p)];
  const boxOf = (w, k, old) => { const t = sh.things[k];
    if (t && t.set) return old ? (t.old && t.old.box) : t.box;
    if (/^ave\d\d$/.test(k)) { const i = +k[3], j = +k[4]; return (w.pajaros || [])[i] > j ? t.box : null; }
    if (k === 'perro') return onGround(w, 'perro') ? [Math.round(w.perro.x) - 14, Math.round(w.perro.y) - 20, 28, 22] : null;
    if (k === 'gato') return onGround(w, 'gato') ? [Math.round(w.gato.x) - 12, Math.round(w.gato.y) - 18, 24, 20] : null;
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? cajaBox(k, p) : null; };
  const handOf = (w, k, old) => { const t = sh.things[k]; if (t && t.hand && !(old && k === 'grande')) return t.hand; const b = boxOf(w, k, old); return b ? [Math.round(b[0] + b[2] / 2), Math.round(b[1] + b[3] / 2)] : null; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [Math.round(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [Math.round(cx - 50), y, 40, 36] : [Math.round(cx + 10), y, 40, 36]; };
  let nF = 0, nC = 0, worstF = 99; const askSeen = new Set(), askedFor = new Set(), cardHand = new Set(), crossedOld = [];
  for (const r of runs) { const Ls = r.lines; forRun(r);
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(Mm => Mm.path === L.path || (Mm.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const wo = Ls[j - 1].W, w = remapW(wo), st = at(r.story, L.path), V = Ls[j - 1].V, sb = x => sub(x, V);
      w.resp = null; let spot = null;
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); }
      else if (st.decide) { const ops = st.options.map(sb), bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || ops[0]; if (st.decide === 'say') w.resp = ops; else if (bur.length) w.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', key = JSON.stringify([spot, w.gente, w.cq, w.resp, w.perro, w.gato, w.pajaros, w.sinGran]);
      if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), facesOld = facesOf(wo);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        if (!within(c, VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' is not inside the view');
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c, bb)) P.push('cards: ' + where + ' the card ' + k + ' is over ' + bn);
        for (const [id, p] of people(w)) { const n = rowsMeet(personRows(id, p), c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + id); }
        for (const kk of ['perro', 'gato']) if (onGround(w, kk)) { const n = rowsMeet(animalRows(kk, w[kk]), c); if (n) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of ' + kk); }
        { const f = frogBox(w.cq); if (w.cq.vis && meets(c, [f.x + 2, f.y + Math.round(w.cq.dy || 0) + 2, f.w - 4, f.h - 3])) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers the frog'); }
        (w.pajaros || []).forEach((n, i) => { for (let j = 0; j < n; j++) { const A = sh.points['arbol.' + i].screen, N = sh.points.nido.screen[j], m = rowsMeet(rowsAt(M.ave[0], A[0] + N[0] - 8, A[1] + N[1] - 6), c); if (m) P.push('cards: ' + where + ' the card ' + k + ' covers ' + m + ' px of bird ' + i + j); } });
        if (w.gato && typeof w.gato.en === 'number' && w.gato.pose === 'cara') { const A = sh.points['arbol.' + w.gato.en].screen, m = rowsMeet(rowsAt(M.cara, A[0] - 12, A[1] - 34), c); if (m) P.push('cards: ' + where + ' the card ' + k + ' covers the cat\'s face'); } }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, VIEW)) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not wholly inside the view'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]);
        // the frame's rings across a face: only where the old frame's crossed that face too
        const bo = boxOf(wo, spot, true) || b;
        for (const [fn, f] of faces) if (ringMeets(b, f)) { const fo = facesOld.find(e => e[0] === fn); if (!fo || !ringMeets(bo, fo[1])) P.push('hint frame: ' + where + ' its rings cross ' + fn + ' ' + JSON.stringify(f) + ' (the old frame ' + JSON.stringify(bo) + ' did not)'); else crossedOld.push(where + ' ' + fn); } }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : handOf(w, spot);
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb && fn === 'the frog\'s face') { cardHand.add(spot); continue; }
        const ho = rb ? null : handOf(wo, spot, true), fo = facesOld.find(e => e[0] === fn);
        if (ho && fo && handOn(ho, fo[1]) && JSON.stringify(ho) === JSON.stringify(hp)) { crossedOld.push(where + ' hand on ' + fn + ' (as the old)'); continue; }
        P.push('hand: ' + where + ' the hand at ' + JSON.stringify(hp) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
    }); }
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- ' + FRAME_OUT + ') wholly inside the view (' + worstF + ' px from its edge at the least), no frame\'s rings across a face where the old frame\'s were not' + (crossedOld.length ? ' (as the old: ' + [...new Set(crossedOld)].join('; ') + ')' : '') + ', the hint hand on no face; ' + nC + ' answer cards inside the view, over no one\'s body (no opaque pixel of anyone\'s sprite, in their pose, under a card)');
  if (cardHand.size) notes.push('NOT the scene\'s: the hand juego.js draws at an answer card reaches onto the frog\'s face, 46 px under it, in every scene (the card\'s place and the hand are the game\'s, respBox and hand()): at the asks for ' + [...cardHand].join(', '));
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments of ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + '), each its recorded one and the ones an act can show there (anyone\'s "amor" when touched, at any moment; Carmen\'s "q" at mirarriba; the frog\'s "amor" at lame and acaricia; the cat\'s at ronronea; Canelo\'s at final13, final14): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the cards shown in the corner (' + (worstBoard === 99 ? 'no card shown with a bubble near' : worstBoard + ' px') + '), on no face');

  /* the birds in the trees: each perches on its tree's crown (the crown's pixels under its feet), behind it only that crown or the sky (no other part
     of the set: plain); the three of a tree do not overlap each other; a bird stands out from the leaves behind it. The cat in a tree: its face and
     tail on its tree's crown (behind them only it, the sky or the lawn) */
  { const tag = TAGS['1'], rgb = G.rgb['1'], lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
    const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k]));
    let least = 99, leastC = 999;
    for (let i = 0; i < 3; i++) { const A = sh.points['arbol.' + i].screen, birds = [];
      for (let k = 0; k < 3; k++) { const x = A[0] + sh.points.nido.screen[k][0] - 8, y = A[1] + sh.points.nido.screen[k][1] - 6;
        for (const f of [0, 1]) { const rs = rowsAt(M.ave[f], x, y); if (f === 0) birds.push(rs);
          // behind it: its own tree or the sky (nothing else of the set)
          let other = 0; for (const [yy, a, b] of rs) for (let xx = a; xx <= b; xx++) { const t = tag[yy * 240 + xx]; if (t && t !== 'arbol' + i) other++; }
          if (other) P.push('birds: the bird ' + i + k + ' (frame ' + f + ') has ' + other + ' px of another thing of the set behind it');
          // under its feet (the lowest row of its body, its middle half): its tree's crown, within 2 rows
          const last = Math.max(...rs.map(r => r[0])), low = rs.filter(r => r[0] === last); let on = 0, n = 0;
          for (const [yy, a, b] of low) for (let xx = a; xx <= b; xx++) { n++; if ([1, 2].some(d => tag[(yy + d) * 240 + xx] === 'arbol' + i)) on++; }
          least = Math.min(least, n ? on / n : 0); if (on < n * .5) P.push('birds: the bird ' + i + k + ' has its tree under ' + on + ' of the ' + n + ' columns of its feet');
          // it stands out: the bird's mean colour against the leaves behind it
          let s = [0, 0, 0], m = 0; for (const [yy, a, b] of rs) for (let xx = a; xx <= b; xx++) { const j = yy * 240 + xx; if (tag[j] === 'arbol' + i) { m++; for (let c = 0; c < 3; c++) s[c] += rgb[j * 3 + c]; } }
          if (m) { const d = dE(M.colours.pajaro, s.map(v => v / m)); leastC = Math.min(leastC, d); } } }
      for (let a = 0; a < 3; a++) for (let b = a + 1; b < 3; b++) { const S = new Set(); for (const [y, x0r, x1r] of birds[a]) for (let x = x0r; x <= x1r; x++) S.add(y * 240 + x); let n = 0; for (const [y, x0r, x1r] of birds[b]) for (let x = x0r; x <= x1r; x++) if (S.has(y * 240 + x)) n++;
        if (n) P.push('birds: in tree ' + i + ' the birds at places ' + a + ' and ' + b + ' overlap by ' + n + ' px (the count unclear)'); } }
    notes.push('birds: every bird of the nine places perches on its own tree\'s crown (its leaves under at least ' + Math.round(least * 100) + '% of its feet\' columns), with nothing but that crown or the sky behind it, none overlapping another of its tree; a bird\'s blue stands out from the leaves behind it by ' + Math.round(leastC) + ' at the least (mean CIE76)'); }

  /* the bird on the bench: its feet on the backrest's top rail; the bench's seat seen when empty */
  { const tag = TAGS['1'], p = sh.points.ave_banco.screen, rs = rowsAt(M.ave[0], p[0], p[1]), last = Math.max(...rs.map(r => r[0])), low = rs.filter(r => r[0] === last); let on = 0, n = 0;
    for (const [y, a, b] of low) for (let x = a; x <= b; x++) { n++; if ([1, 2].some(d => tag[(y + d) * 240 + x] === 'banco')) on++; }
    if (on < n * .5) P.push('perch: the bird on the bench has the bench under ' + on + ' of the ' + n + ' columns of its feet');
    let other = 0; for (const [y, a, b] of rs) for (let x = a; x <= b; x++) { const t = tag[y * 240 + x]; if (t && t !== 'banco' && t !== 'arbol1') other++; }
    // the seat seen: the top faces of the seat's slats (the lightest wood), at least 40 px
    const seat = F.SEAT_PX || 0; if (seat < 40) P.push('bench: its seat shows ' + seat + ' px');
    notes.push('perch: the bird on the bench (gato.no) has the seat\'s back plank under ' + on + ' of the ' + n + ' columns of its feet; the empty bench shows ' + seat + ' px of its seat\'s top'); }

  /* the marks on the path: the seven stones in the path, apart, nothing of the set over them */
  { const tag = TAGS['1'], K = G.kinds['1']; let apart = 99;
    for (let i = 1; i <= 7; i++) { const m = sh.points['marca.' + i].screen; if (K[m[1] * 240 + m[0]] !== G.K.road) P.push('stones: mark ' + i + ' at ' + m + ' is not on the path');
      let n = 0, other = 0; for (let y = m[1] - 3; y <= m[1] + 3; y++) for (let x = m[0] - 6; x <= m[0] + 6; x++) { if (tag[y * 240 + x] === 'camino') n++; else if (tag[y * 240 + x]) other++; }
      if (n < 30) P.push('stones: the stone at mark ' + i + ' shows ' + n + ' px'); if (other) P.push('stones: ' + other + ' px of another thing over the stone at mark ' + i);
      if (i > 1) { const p = sh.points['marca.' + (i - 1)].screen; apart = Math.min(apart, Math.hypot(m[0] - p[0], m[1] - p[1]) - 13); } }
    notes.push('stones: the seven stones (marks 1 to 7) in the path, each whole and seen, nothing over them, ' + Math.round(apart) + ' px apart at the least along the path'); }

  /* the front parts' order: everyone drawn before the bench's entry is behind it or clear of it; the cat on its seat is after it */

  /* acts.sevan: each one goes out through the opening (their way crosses the arch's line between its posts, clear of them by their half width),
     and is beyond the view or faded (al <= .3) at the end; at every step with al > .3, no set pixel nearer than them inside their sprite but the
     arch's (drawn over them after everyone: front.porton) */
  { const sv = sh.sevan, inner = F.AH - F.APW, out = [];
    const crossB = (p0, p1) => { const g0 = E.atZ(p0[0], p0[1] - 1, 0), g1 = E.atZ(p1[0], p1[1] - 1, 0), t = (F.AC[0] - g0[0]) / (g1[0] - g0[0]); return t >= 0 && t <= 1 ? g0[1] + (g1[1] - g0[1]) * t - F.AC[1] : null; };
    const halfB = { abuela: .15, luis: .15, carmen: .15, perro: .15, cq: .15 };   // their ground point well inside the opening (their sprites are wider than it: past the arch's line the posts are drawn over them, front.porton)
    for (const id of ['abuela', 'luis', 'carmen']) { const [g, f] = sv.people[id], b = crossB(g, f);
      if (b == null || Math.abs(b) + halfB[id] > inner) P.push('sevan: ' + id + ' crosses the arch\'s line at ' + (b == null ? 'no point' : r2(b)) + ' (keep within ' + r2(inner - halfB[id]) + ')'); else out.push(id + ' ' + r2(b));
      if (f[0] + 20 > x0 + 8) P.push('sevan: ' + id + ' ends at ' + f + ', in the view'); }
    { const b = crossB(sv.dog[0], sv.dog[1]); if (b == null || Math.abs(b) + halfB.perro > inner) P.push('sevan: the dog crosses the arch\'s line at ' + b); else out.push('Canelo ' + r2(b)); if (sv.dog[1][0] + 16 > x0) P.push('sevan: the dog ends in the view'); }
    { const b = crossB([sv.frog[0][0] + 16, sv.frog[0][1] + 26], [sv.frog[1][0] + 16, sv.frog[1][1] + 26]); if (b == null || Math.abs(b) + halfB.cq > inner + .3) P.push('sevan: the frog crosses the arch\'s line at ' + b); else out.push('the frog ' + r2(b)); }
    notes.push('sevan: everyone leaves through the arch\'s opening (where their way crosses its line, from its middle, in world units; its posts\' inner faces at +-' + r2(inner) + '): ' + out.join(', ') + '; each ends past the view\'s left edge (the dog walks on off it, the people fade there, the frog hops there); behind the arch, it is drawn over them (front.porton)'); }

  /* the review pictures (and the level pictures, the same pictures): everyone whole in their crop (a zoom 2 crop cuts no one the old one did not),
     every bubble inside, on the ground; what differs between the two sides */
  let nPic = 0; const pairDiff = [];
  const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
  for (const [word, sides] of Object.entries(byWord)) {
    const ws = {};
    for (const side of Object.keys(sides)) {
      const spec = sides[side].spec, base = { gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, pajaros: [0, 0, 0] };
      MV = MVall.filter(q => q.act === '*'); RM = RMall.filter(q => q.files.includes('cual-camino')); EN = null;
      const w = remapW(Object.assign(base, JSON.parse(JSON.stringify(spec.set || {})))), nm = deacc(word) + '.' + side, pc = sh.pictures[nm]; ws[side] = w; nPic++;
      const crop = pc.crop, oc = spec.cam, ocr = [Math.floor(oc[0]), Math.floor(oc[1]), Math.ceil(oc[2]), Math.ceil(oc[3])], who = people(w).map(([id, p]) => [id, rowsBox(personRows(id, p))]);
      if (w.cq.vis) { const b = frogBox(w.cq); who.push(['the frog', [b.x, b.y, b.w, b.h]]); }
      for (const k of ['perro', 'gato']) if (onGround(w, k)) who.push([k, rowsBox(animalRows(k, w[k]))]);
      if (w.caracol) who.push(['the snail', rowsBox(rowsAt(M.caracol, Math.round(w.caracol.x), Math.round(w.caracol.y)))]);
      if (w.gato && w.gato.en != null && w.gato.pose === 'cara') { const A = sh.points['arbol.' + w.gato.en].screen; who.push(['the cat\'s face', rowsBox(rowsAt(M.cara, A[0] - 12, A[1] - 34))]); }
      (w.pajaros || []).forEach((n, i) => { for (let k = 0; k < n; k++) { const A = sh.points['arbol.' + i].screen, N = sh.points.nido.screen[k]; who.push(['bird ' + i + k, rowsBox(rowsAt(M.ave[0], A[0] + N[0] - 8, A[1] + N[1] - 6))]); } });
      if (w.avebanco) who.push(['the bird on the bench', rowsBox(rowsAt(M.ave[0], sh.points.ave_banco.screen[0], sh.points.ave_banco.screen[1]))]);
      for (const [id, b] of who) { const cut = !within(b, crop), oldCut = !within(b, ocr);
        if (cut && !oldCut) P.push('pair ' + nm + ': ' + id + ' ' + JSON.stringify(b) + ' is cut by the picture ' + JSON.stringify(crop)); }
      for (const [who2, rect] of bubblesOf(w, {}, crop).filter(e => !/"amor"/.test(e[0]))) if (!within(rect, crop)) P.push('pair ' + nm + ': ' + who2 + ' bubble is cut');
      groundCheck('pair ' + nm + ':', w);
    }
    if (!ws.si || !ws.no) continue;
    if (JSON.stringify(ws.si) === JSON.stringify(ws.no) && JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) === JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) P.push('pair ' + word + ': the two pictures are the same');
    const diff = []; const ids = new Set([...Object.keys(ws.si.gente || {}), ...Object.keys(ws.no.gente || {})]);
    for (const id of ids) { const x = (ws.si.gente || {})[id], y = (ws.no.gente || {})[id]; if (JSON.stringify(x) !== JSON.stringify(y)) diff.push(id + (!x ? ' only in no' : !y ? ' only in si' : ' ' + Object.keys(Object.assign({}, x, y)).filter(k => JSON.stringify(x[k]) !== JSON.stringify(y[k])).join('/'))); }
    for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (k !== 'gente' && k !== 'cq' && JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k + (ws.si[k] && ws.no[k] && typeof ws.si[k] === 'object' && !Array.isArray(ws.si[k]) ? ' ' + Object.keys(Object.assign({}, ws.si[k], ws.no[k])).filter(q => JSON.stringify(ws.si[k][q]) !== JSON.stringify(ws.no[k][q])).join('/') : ''));
    if (JSON.stringify(sh.pictures[deacc(word) + '.si'].crop) !== JSON.stringify(sh.pictures[deacc(word) + '.no'].crop)) diff.push('the window');
    pairDiff.push(deacc(word) + ': ' + diff.join(', '));
  }
  notes.push('pairs, what differs: ' + pairDiff.join('; '));
  notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures): everyone, the frog, Canelo, the cat, the snail and the birds whole in their crop (no zoom 2 crop cuts what the old window did not), on clear ground');

  /* sprite-layer things on the lawn stand out from it (the bush, the snail, Canelo, the cat: their mean colour against the lawn's) */
  { const C = G.rgb['1'], K = G.kinds['1']; let n = 0, m = [0, 0, 0]; for (let y = 140; y < 216; y++) for (let x = 0; x < 240; x++) { const i = y * 240 + x; if (K[i] !== G.K.grass) continue; n++; for (let k = 0; k < 3; k++) m[k] += C[i * 3 + k]; }
    m = m.map(v => v / n); const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
    const dE = c => Math.round(Math.hypot(...lab(c).map((v, k) => v - lab(m)[k])));
    const hue = Math.round(60 * (2 + (m[2] - m[0]) / (m[1] - Math.min(m[0], m[2]))));
    if (!(m[1] > m[0] && m[1] > m[2] && hue >= 65)) P.push('lawn: its mean colour ' + m.map(Math.round) + ' (hue ' + hue + ') is not green');
    notes.push('lawn: El frente\'s grass (GRASS), mean colour ' + m.map(Math.round) + ' (hue ' + hue + '); the sprite layer\'s things on it, by their mean colour against it (CIE76), each with its dark outline: the bush ' + dE(M.colours.arbusto) + ', the snail ' + dE(M.colours.caracol) + ', Canelo ' + dE(M.colours.perro) + ', the cat ' + dE(M.colours.gato)); }

  { const reached = new Set(); for (const r of runs) for (const L of r.lines) reached.add(keyOf(L.W)); for (const ps of pairSides) reached.add(keyOf(ps.spec.set || {}));
    for (const k of STATES) if (!reached.has(k)) P.push('state ' + k + ' is baked but nothing reaches it');
    notes.push('states: ' + reached.size + ' baked states reached (gran ' + [...reached].sort().join(', ') + ')'); }
  return P;
}
