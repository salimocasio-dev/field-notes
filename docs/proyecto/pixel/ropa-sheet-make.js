#!/usr/bin/env node
'use strict';
/* La ropa's sheet: writes docs/proyecto/pixel/ropa-sheet.json from ropa-set.html and the design (the orchestrator's p7-spec, section "ropa"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/ropa-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene (place 7, La playa; stories 78, 79, 80): no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z),
   u across the picture, v down it (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S, rounded half up. The set's numbers (the beach, the palms, the line's height, the pegs, the cabin, the bench, the road,
   the guagua) are read from the set (window.ROPA.E), never typed again from the design.
   The set has two palms whose fronds sway: frame(t) draws them over the baked set (DEPTH.live() is the depth with the fronds in). The sheet takes the depth and the pixels after
   frame(0): a frond in front of a spot counts as covering it. Over the wind (60 s in the set's own 1/8 s steps) the fronds reach further: reported as information.
   It loads the set in headless Chrome (ropa-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from today's makers (historia/engine.js, historia/escenas/kit.js) loaded in a second, empty page. The checks that say "covers" or "shows"
   read the PREVIEW's moments (ropa-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is
   written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with ROPA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'ropa-sheet.json');
const BASE = process.env.ROPA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/ropa-set.html';
const BLANK = BASE + '/__blank__.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

// every request to BASE is answered from the files of this tree
const serve = route => {
  const u = new URL(route.request().url());
  if (u.pathname === '/__blank__.html') return route.fulfill({ status: 200, contentType: 'text/html', body: '<!doctype html><html><head><meta charset="utf-8"><title>blank</title></head><body></body></html>' });
  const f = path.join(REPO, decodeURIComponent(u.pathname));
  if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
  route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
};
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100, sgn = v => (v > 0 ? '+' : '') + r2(v);
const W4 = p => p.map(r4);
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, T30 = Math.tan(Math.PI / 6);
const hu = v => Math.floor(v + .5 + 1e-9);               // rounded half up: v -.5 (the things afloat) and u -.75 are exactly on a half pixel

// the numbers of the design (p7-spec: the rules for every sheet, and "ropa")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const PIECE = { w: 16, h: 16 };                          // a piece on the line: 16 wide, 16 high, hung below it (its top on the line's row)
const AFLOAT = { w: 14, h: 9 };                          // a thing afloat
const PLATO = { w: 16, h: 10, lift: 8 };                 // the plate: its foot 8 px above the sand
const ZAPATOS = { w: 24, h: 8, pair: 12 };               // two pairs side by side, 12 x 8 each
const BOLSA = { w: 14, h: 10 };                          // the open bag
const CHOFER = { w: 14, h: 14 };                         // the driver's head and arm at his window
const SEAT_Z = .46;                                      // the bench's seat top
const FEET_ROWS = 8;                                     // "their feet": the bottom 8 rows of a child
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STATES = [{ hora: 'tarde', guagua: 0 }, { hora: 'ocaso', guagua: 1 }];
const BASE_STATE = STATES[0], BUS_STATE = STATES[1];

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, lift }
   kind: person (a character stands there), place (the frog's, or a bare point), thing (a small thing: a piece on the line, a thing afloat, the plate, the shoes, the bag, the driver)
   sil: which drawing hangs there (abuela = standing, abuelaS = abuela sitting, nino, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle (lift px above the point), centre = its middle */
function defs(E) {
  const B = E.BENCH, K = E.CABIN, BUS = E.BUS, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz: uvz.map(r4), kind, sil, who, what }, more || {}));
  add('banco1', [B.u - .45, B.v, SEAT_Z], 'person', 'abuelaS', 'adulto', 'abuela on the bench (the left place): on the seat\'s top (z ' + SEAT_Z + '); the sitting sprite hangs by the lap', { on: 'banco' });
  add('banco2', [B.u + .62, B.v, SEAT_Z], 'place', 'coqui', 'coqui', 'the frog on the bench beside her: on the seat\'s top (z ' + SEAT_Z + ')', { on: 'banco' });
  add('plato', [B.u - .95 - .25, B.v + .1, 0], 'thing', null, null, 'the plate of sandwiches, on a small box on the sand at the bench\'s left end (a ' + PLATO.w + ' x ' + PLATO.h + ' px stand-in, its foot ' + PLATO.lift + ' px above the spot\'s row)', { size: [PLATO.w, PLATO.h], anchor: 'bottom', lift: PLATO.lift });
  add('abuela.cuerda', [-2.45, 3.5, 0], 'person', 'abuela', 'adulto', 'abuela standing at the line');
  add('coqui.cuerda', [-.04, 3.7, 0], 'place', 'coqui', 'coqui', 'the frog on the sand under the line');
  add('zapatos', [1.1, 3.2, 0], 'thing', null, null, 'two pairs of shoes side by side on the sand (white at the left, black at the right): ' + ZAPATOS.pair + ' x ' + ZAPATOS.h + ' px each, ' + ZAPATOS.w + ' x ' + ZAPATOS.h + ' together, their bottom middle on the point', { size: [ZAPATOS.w, ZAPATOS.h], anchor: 'bottom', pairs: 2 });
  add('caseta', [K.u, K.v + K.hd + .15, 0], 'person', 'nino', 'nino', 'in front of the cabin\'s curtain (Carmen, story 80)');
  E.PEGS.forEach((u, i) => add('cuerda' + (i + 1), [u, E.PALMS[0][1], E.LINE], 'thing', null, null, 'peg ' + (i + 1) + ' of the line (u ' + u + ', the line\'s v ' + E.PALMS[0][1] + ', z ' + E.LINE + ', the line\'s height): a piece hangs below it, ' + PIECE.w + ' x ' + PIECE.h + ', its top on the point' + (i >= 1 && i <= 3 ? ' (story 78: ' + ['', 'camisa', 'pantalon', 'vestido'][i] + (i === 2 ? '; story 79: toalla' : '') + ')' : ''), { size: [PIECE.w, PIECE.h], anchor: 'top', on: 'cuerda', peg: i + 1 }));
  add('pie1', [-2.25, 4.8, 0], 'person', 'nino', 'nino', 'Luis, story 78 (the game)');
  add('pie2', [-1.2, 4.8, 0], 'person', 'nino', 'nino', 'Carmen, story 78 (the game)');
  add('orilla1', [-2.5, .5, 0], 'person', 'abuela', 'adulto', 'abuela at the water\'s edge, story 79');
  add('orilla2', [2.7, .5, 0], 'person', 'nino', 'nino', 'Luis at the water\'s edge, story 79');
  add('orilla3', [3.3, 1.55, 0], 'person', 'nino', 'nino', 'Carmen at the water\'s edge, story 79');
  add('coqui.orilla', [.1, 1.6, 0], 'place', 'coqui', 'coqui', 'the frog on the wet sand, story 79');
  [-1.6, -.75, .1, .95, 1.8].forEach((u, i) => add('agua' + (i + 1), [u, -.5, 0], 'thing', null, null, 'thing afloat ' + (i + 1) + ' of 5 in the shallow water (a ' + AFLOAT.w + ' x ' + AFLOAT.h + ' px stand-in, its bottom middle on the point)', { size: [AFLOAT.w, AFLOAT.h], anchor: 'bottom', water: 1 }));
  add('bolsa', [-2.5, 1.3, 0], 'thing', null, null, 'the open bag on the sand (a ' + BOLSA.w + ' x ' + BOLSA.h + ' px stand-in, its bottom middle on the point)', { size: [BOLSA.w, BOLSA.h], anchor: 'bottom' });
  add('luis.viste', [-2.0, 3.7, 0], 'person', 'nino', 'nino', 'Luis putting his clothes on, story 80');
  [[-2.9, 'a boy'], [-1.9, 'the other boy'], [-.6, 'a girl'], [.4, 'the other girl']].forEach(([u, w], i) => add('ninos' + (i + 1), [u, 6.6, 0], 'person', 'nino', 'nino', w + ' of the four children at the water\'s edge of story 80 (the picture\'s two boys at ninos1, ninos2, the two girls at ninos3, ninos4)'));
  add('coqui.busca', [-1.25, 8.0, 0], 'place', 'coqui', 'coqui', 'the frog looking for them, story 80');
  add('parada', [r4(BUS.u0 + .75), r4(BUS.v + .2), 0], 'place', null, null, 'the stop: on the road, at the middle of the guagua\'s open door (the door is ' + .35 + ' to ' + 1.15 + ' from its front end u ' + BUS.u0 + '); a point: the spec puts nobody there');
  add('chofer', [r4(BUS.u0 + .14), BUS.v, 1.5], 'thing', null, null, 'the driver\'s head and arm at his window (a ' + CHOFER.w + ' x ' + CHOFER.h + ' px stand-in centred on the point: the window is the dark pane at the guagua\'s front end)', { size: [CHOFER.w, CHOFER.h], anchor: 'centre', on: 'guagua' });
  return D;
}

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  const pageBus = await browser.newPage();
  pageBus.on('pageerror', e => errs.push(String(e)));
  await pageBus.route(BASE + '/**', serve);
  const sp = await browser.newPage();
  sp.on('pageerror', e => errs.push(String(e)));
  await sp.route(BASE + '/**', serve);
  const SIL = await silhouettes(sp);

  await page.goto(PAGE + '?tags=1&hora=' + BASE_STATE.hora + '&guagua=' + BASE_STATE.guagua);
  await pageBus.goto(PAGE + '?tags=1&hora=' + BUS_STATE.hora + '&guagua=' + BUS_STATE.guagua);
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(ROPA.E)) if (typeof v !== 'function') o[k] = v;
    // the fronds: the pixels a frond takes at wind time 0, and over the wind (0 to 60 s in 1/8 s steps)
    const ZB = Float32Array.from(DEPTH.z), bb = Z => { let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1, n = 0; for (let i = 0; i < Z.length; i++) if (Z[i] !== ZB[i]) { n++; const x = i % W, y = (i / W) | 0; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return { box: n ? [x0, y0, x1, y1] : null, px: n }; };
    frame(0); const z0 = Float32Array.from(DEPTH.live()), mx = Float32Array.from(ZB);
    for (let t = 0; t < 60; t += .125) { frame(t); const z = DEPTH.live(); for (let i = 0; i < mx.length; i++) if (z[i] > mx[i]) mx[i] = z[i]; }
    frame(0);
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY, KIND: { sand: KIND_SAND, water: KIND_WATER, road: KIND_ROAD }, fronds: { frame0: bb(z0), wind: bb(mx) } };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj, SIL);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = { base: await probeSets(page, sheet), bus: await probeSets(pageBus, sheet) };
  const PV = await previewData(browser, errs);
  const results = await checks(sheet, G, SIL, probes, PV);
  sheet.checks = { results };
  const out = compact(JSON.stringify(sheet, null, 1)) + '\n';
  fs.writeFileSync(OUT, out);
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + out.length + ' bytes)');
  for (const r of results) for (const [i, line] of r.lines.entries()) console.log((i === 0 ? (r.ok ? 'ok   ' : 'FAIL ') : '     ') + line);
  const bad = results.filter(r => !r.ok);
  if (bad.length) { console.log('CHECK FAILED: ' + bad.map(r => r.name).join(', ')); process.exit(1); }
  console.log('check: all ' + results.length + ' checks ok');
})().catch(e => { console.error(e); process.exit(1); });

// an array of numbers or plain words goes on one line
const ITEM = '(?:-?[\\d.]+|"[\\w.=+&?-]+")';
const compact = t => t.replace(new RegExp('\\[\\n\\s+(' + ITEM + '(?:,\\n\\s+' + ITEM + ')*)\\n\\s+\\]', 'g'), (m, a) => '[' + a.replace(/,\n\s+/g, ', ') + ']');

/* ---------- the sprites' silhouettes: [dx, dy] of each drawn pixel from the anchor column and the anchor row (dy -1 is the feet's row) ---------- */
async function silhouettes(sp) {
  await sp.goto(BLANK);
  for (const f of ['historia/engine.js', 'historia/escenas/kit.js']) await sp.addScriptTag({ url: BASE + '/' + f });
  return sp.evaluate(() => {
    const sil = (cv, ax, ay) => {
      const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, ink = [];
      let bottom = 0;
      for (let y = 0; y < cv.height; y++) for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { ink.push([x, y]); bottom = Math.max(bottom, y + 1); }
      const row = ay == null ? bottom : ay;
      let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const [x, y] of ink) { x0 = Math.min(x0, x - ax); x1 = Math.max(x1, x - ax); y0 = Math.min(y0, y - row); y1 = Math.max(y1, y - row); }
      return { w: cv.width, h: cv.height, ax, ay: row, box: [x0, y0, x1, y1] };
    };
    const FAM = KIT.FAM;
    return {
      abuela: sil(mkAbuela('idle', 0), 30), abuelaS: sil(KIT.mkAbuelaS('idle', 0, 0), 17, 36),
      nino: sil(KIT.mkPersona(FAM.hermano, 'idle', 0, 0), KIT.PX), coqui: sil(mkCoqui(1, 0, 0), 16),
    };
  });
}

/* ---------- the preview's moments: ropa-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane, what hides it]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/ropa-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow, apart) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow, x.apart), { st, specs, idx, allow: allow || 0, apart: apart || null });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  PV.boxCover = (st, box, d, sy, wind) => p.evaluate(x => window.PREVIEW.boxCover(x.st, x.box, x.d, x.sy, x.wind), { st, box, d, sy, wind: !!wind });
  PV.fronds = st => p.evaluate(s => window.PREVIEW.fronds(s), st);
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded half up to a pixel
const scrUV = (G, u, v, z) => [hu(G.OX + u * G.S), hu(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor, lift = 0) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h - lift : sy - Math.floor(h / 2), w, h];
};
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle; a small thing: its box) takes: [first, last]
const colsOf = s => s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}
const clip = (b, w) => { const x0 = Math.max(b[0], w[0]), y0 = Math.max(b[1], w[1]), x1 = Math.min(b[0] + b[2], w[0] + w[2]), y1 = Math.min(b[1] + b[3], w[1] + w[3]); return x1 > x0 && y1 > y0 ? [x0, y0, x1 - x0, y1 - y0] : null; };

/* ---------- the sheet ---------- */
async function make(G, proj, SIL) {
  const E = G.E, sc = G.scene, BUS = E.BUS, DEF = defs(E);
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], [sx, sy] = scrUV(G, d.uvz[0], d.uvz[1], d.uvz[2]);
    if (Math.abs(q[0] - (G.OX + d.uvz[0] * G.S)) > 1e-6 || Math.abs(q[1] - (G.OY + (d.uvz[1] * .5 - d.uvz[2] * COS) * G.S)) > 1e-6) throw new Error('the engine\'s projection of ' + d.name + ' is not sx = OX + u S, sy = OY + (v / 2 - z cos 30) S');
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor, d.lift || 0); o.anchor = d.anchor; }
    if (d.lift) o.lift = d.lift;
    if (d.pairs) o.pairs = [[o.box[0], o.box[1], ZAPATOS.pair, ZAPATOS.h], [o.box[0] + ZAPATOS.pair, o.box[1], ZAPATOS.pair, ZAPATOS.h]];
    if (d.uvz[2] > 0) o.on = d.on || 'ground';                                  // what it stands on above the ground: a part of the set (the bench, the line, the guagua) or nothing (held in the air)
    if (d.peg) o.peg = d.peg;
    if (d.water) o.water = 1;
    spots[d.name] = o;
  });

  /* ---- the view: x0 so that every spot is inside the picture and the window ---- */
  const held = Object.entries(spots);
  const ext = held.map(([, s]) => colsOf(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0))) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [78, 79, 80], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 78, 79 and 80: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment is inside it (a person with his sprite whole, a small thing with its box whole). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    const t = { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
    if (v0 === v1) t.quad = [0, 1, 5, 4].map(i => W4([q[i][3], q[i][4], corners[i][2]]));          // a plane facing the camera: its four corners
    return t;
  };
  const things = {};
  things.guagua = await setThing(BUS.u0, BUS.v, 0, BUS.u1, BUS.v, r4(BUS.h + .3), 'the guagua\'s side: the wall the set draws (u ' + BUS.u0 + ' to ' + BUS.u1 + ', z .3 to ' + r4(BUS.h + .3) + ') with its wheels (z 0 to .54), on the plane v ' + BUS.v + '; its front end (the driver, the door) is at the left, u ' + BUS.u0 + '; it runs off the picture\'s right edge on purpose (u ' + BUS.u1 + ' is column ' + hu(G.OX + BUS.u1 * G.S) + ' of ' + G.W + '); a poke (the roof\'s top, the sign are not in it)');
  things.guagua.visible = clip(things.guagua.box, [x0, 0, 196, G.H]);
  things.guagua.door = (await setThing(r4(BUS.u0 + .35), BUS.v, .3, r4(BUS.u0 + 1.15), BUS.v, r4(.3 + BUS.h - .2), 'the front door, open: ' + .35 + ' to ' + 1.15 + ' from the front end')).box;
  things.guagua.window = (await setThing(BUS.u0, BUS.v, r4(.3 + .85), r4(BUS.u0 + .28), BUS.v, r4(.3 + 1.55), 'the driver\'s window: the first .28 of the wall, z ' + r4(.3 + .85) + ' to ' + r4(.3 + 1.55))).box;
  for (const k of ['camisa', 'pantalon', 'vestido', 'zapatos', 'sombrero', 'toalla', 'chancletas', 'gafas', 'traje', 'plato', 'bolsa', 'ninos1', 'ninos2', 'ninos3', 'ninos4', 'abuela', 'luis', 'carmen', 'coqui', 'perro']) things[k] = 'sprite';

  return {
    scene: 'ropa',
    made: 'node docs/proyecto/pixel/ropa-sheet-make.js, from ropa-set.html (window.ROPA.E) and the design of La ropa (the orchestrator\'s p7-spec, section ropa). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded half up to whole pixels (the things afloat at v -.5 and agua2 at u -.75 are exactly on a half pixel)',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera); plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The beach: the water\'s edge at v ' + E.B.edge + ', the wet strip to v ' + E.B.wet + ', the horizon at v ' + E.B.hor + '; the road from v ' + E.ROAD + '; the line between the palms at v ' + E.PALMS[0][1] + ', z ' + E.LINE + ' (it sags up to .07 below that at its middle); the pegs at u ' + E.PEGS.join(', ') + '; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the sand, the sea\'s shallows, the road; z ' + SEAT_Z + ': the bench\'s seat top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): a piece on the line (cuerda1 to cuerda5, ' + PIECE.w + ' x ' + PIECE.h + ') hangs with its top row on sy and its middle on sx; the things afloat (' + AFLOAT.w + ' x ' + AFLOAT.h + '), the bag (' + BOLSA.w + ' x ' + BOLSA.h + ') and the shoes (' + ZAPATOS.w + ' x ' + ZAPATOS.h + ': two pairs of ' + ZAPATOS.pair + ' x ' + ZAPATOS.h + ') have their bottom middle on the spot; the plate (' + PLATO.w + ' x ' + PLATO.h + ') has its bottom middle ' + PLATO.lift + ' px above it (on a small box); the driver (' + CHOFER.w + ' x ' + CHOFER.h + ') is centred on chofer. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 41 rows drawn standing for a child; abuela standing mkAbuela (48 x 51): column 30, 51 rows drawn (engine.js); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a small thing: see spot. Whoever sits on the bench faces us: no sprite is turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character. A piece on the line, a thing afloat, the plate, the shoes, the bag and the driver are upright planes like a character (the plate\'s plane is the plane through its spot: the same plane as the sand under it)',
    },
    setKey: {
      params: { hora: { values: ['tarde', 'ocaso'], note: '78 and 79 tarde (late afternoon, afternoon), 80 ocaso (the sun low)' }, guagua: { values: [0, 1], note: 'the guagua standing at the stop on the road, its door open (story 80: 1); its driver is a sprite' }, t: { values: ['wind time'], note: 'the palms\' fronds sway: frame(t); 0 for the reference (the sheet\'s depth is the depth after frame(0))' } },
      key: 'hora + guagua, e.g. "tarde-0"',
      baked: STATES.map(s => '?hora=' + s.hora + '&guagua=' + s.guagua),
    },
    fronds: {
      note: 'the palms\' fronds are drawn every frame over the baked set (frame(t)); the sheet\'s depth and pixels are those after frame(0). frame0: the bounding box [x0, y0, x1, y1] and the count of the picture\'s pixels a frond takes at wind time 0; wind: the same over the wind (60 s in 1/8 s steps: the largest reach a frond has). The palms are the same in both hours',
      frame0: G.fronds.frame0, wind: G.fronds.wind, palms: E.PALMS,
    },
    things,
    spots,
    groups: {
      cuerda: ['cuerda1', 'cuerda2', 'cuerda3', 'cuerda4', 'cuerda5'], agua: ['agua1', 'agua2', 'agua3', 'agua4', 'agua5'], ninos: ['ninos1', 'ninos2', 'ninos3', 'ninos4'], banco: ['banco1', 'banco2'],
      moment1: ['abuela.cuerda', 'coqui.cuerda', 'cuerda2', 'cuerda3', 'cuerda4', 'zapatos'], moment2: ['banco1', 'plato', 'coqui.cuerda', 'pie1', 'pie2', 'cuerda2', 'cuerda3', 'cuerda4', 'zapatos'],
      moment3: ['agua1', 'agua2', 'agua3', 'agua4', 'agua5', 'orilla1', 'orilla2', 'orilla3', 'coqui.orilla', 'bolsa', 'cuerda3'], moment4: ['agua1', 'agua2', 'agua4', 'agua5', 'orilla1', 'orilla2', 'orilla3', 'coqui.orilla', 'bolsa', 'cuerda3'],
      moment5: ['banco1', 'banco2', 'luis.viste', 'caseta', 'chofer'], moment6: ['banco1', 'ninos1', 'ninos2', 'ninos3', 'ninos4', 'coqui.busca', 'chofer'],
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p7-spec, "ropa"), given in (u, v, z); the set\'s numbers (the beach, the palms, LINE, PEGS, CABIN, BENCH, ROAD, BUS) are read from the set',
      'cuerda1 to cuerda5 are the spec\'s five pegs (PEGS, at the line\'s v ' + E.PALMS[0][1] + ' and z LINE); a piece hangs with its top on the peg\'s point. The line sags up to .07 (1.6 px) below LINE at its middle (the set draws it so): the spec says LINE, so the points are at LINE (open point: check spots-on-surface says how far the drawn line is below each peg)',
      'the things afloat (14 x 9), the bag (14 x 10), the shoes (24 x 8), the driver (14 x 14) and the pieces (16 x 16) are the spec\'s sizes; the spec gives no anchor but the plate\'s (foot 8 px above the sand) and the driver\'s window: the bottom middle on the spot is used for the afloat things, the bag and the shoes, the top middle for the pieces, the middle for the driver (open point)',
      'which thing floats at which agua is not in the spec: the preview puts the hat at agua1, the sandals at agua2, the towel at agua3 (the one that is fished out first, so story 79\'s game has agua1, 2, 4, 5), the glasses at agua4, the swimming suit at agua5',
      'the small box the plate stands on is not a thing of its own in the spec: the preview draws a 12 x 8 stand-in box on the sand under it; the sheet gives the plate\'s box only',
      'parada is a point on the road at the guagua\'s open door (the spec puts nobody there); no spot has been given to Canelo (perro is in the spec\'s things, with no place)',
      'caseta, pie1, pie2, luis.viste, orilla2, orilla3, ninos1 to ninos4 are children (24 wide); abuela at abuela.cuerda and orilla1 stands (24 wide); at banco1 she sits',
      'the spec gives no hour for moments 2 to 4 and 6: the preview uses tarde for 78 and 79 and ocaso with the guagua (guagua 1) for 80',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the set\'s depth, with the feet\'s depth plus 0.3): the guagua and its sign, the bench, the cabin, the palms\' trunks and fronds hide whoever is behind them. The set\'s depth is the live depth after frame(0): the baked set with the palms\' fronds at wind time 0 (window.DEPTH.live(); the fronds are not in window.DEPTH.z)',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where live[r * 240 + x] > depth(r) + bias (live: window.DEPTH.live() of the set page after frame(0)). The same rule as El calendario\'s sheet: the upright plane through the feet (a piece on the line is the plane through its top on the line\'s v)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, luis: .28, carmen: .28, ninos: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are the other places\' (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on the bench casts none (it is not ground: a shadow cast at the sand under them would show in front of them); the pieces on the line and the driver are in the air',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(pg, sheet) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth, the live depth, the part, the kind of ground), the 5 x 5 round it
  return pg.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 4; dy++) for (let dx = -2; dx <= 2; dx++) {
        const X = s.screen[0] + dx, Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, c = bakedPix[i];
        rows.push({ dx, dy, tag: TAGS[i], z: DEPTH.z[i], live: DEPTH.live()[i], kind: kinds[i], gz: groundZ[i], rgb: [c & 255, c >> 8 & 255, c >> 16 & 255] });
      }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  const planeAt = (l, Y) => l.d + (l.sy - (Y + .5)) * T30 / G.S;
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them; and the hidden ones by what hides them
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, cov = 0; const who = {}, hidBy = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2]) { hid++; hidBy[p[4]] = (hidBy[p[4]] || 0) + 1; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].at; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, hidBy, out: l.out, top };
  };
  // the pixels of layer t's whole BOX (the spec's thing, not the stand-in's drawing) that a nearer shown pixel of another layer covers
  const boxCovered = (L, M, t) => {
    const l = L[t], b = l.box, who = {}; let n = 0;
    for (let y = b[1]; y < b[1] + b[3]; y++) for (let x = b[0]; x < b[0] + b[2]; x++) {
      const pl = planeAt(l, y); let nearest = null;
      for (const q of M.get(key(x, y)) || []) if (q.i !== t && q.plane > pl + EPS && (!nearest || q.plane > nearest.plane)) nearest = q;
      if (nearest) { n++; const a = L[nearest.i].at; who[a] = (who[a] || 0) + 1; }
    }
    return { n, who };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const hidTxt = h => Object.entries(h).map(([k, v]) => k + ' ' + v).join(', ');
  const sum = h => Object.values(h).reduce((a, b) => a + b, 0);
  const idxAt = (L, at) => L.findIndex(l => l.at === at);
  // the people layer i must stand clear of (sprites-apart): [sx, sy, the half-widths' sum] of every other person of the moment
  const apartOf = (L, i) => L.filter((l, j) => j !== i && l.who).map(l => [l.sx, l.sy, (WIDTH[L[i].who] + WIDTH[l.who]) / 2]);
  const busLeft = hu(G.OX + E.BUS.u0 * G.S);                                  // the guagua's front end: set pixels of the guagua part left of it are the stop's sign and its post

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24; and his rows from the drawn silhouette; a small thing's box)
  {
    const bad = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sil = s.sprite ? SIL[s.sprite] : null;
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else if (sil) { top = sy + sil.box[1]; bottom = sy + sil.box[3]; } else { top = sy; bottom = sy; }
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : s.box ? 'box [' + s.box + ']' : 'point') + ' is cut ' + (cut.concat([picL && 'by the picture\'s left edge ' + picL, picR && 'by the picture\'s right edge ' + picR].filter(Boolean))).join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k];
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = Object.assign({}, s, { screen: [sx, s.screen[1]] }); if (s.box) t.box = [s.box[0] + sx - s.screen[0], s.box[1], s.box[2], s.box[3]]; if (!cutAt(t, x0) && colsOf(t)[0] >= 0 && colsOf(t)[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost columns: ' + names.map(k => [colsOf(S[k])[0], k]).sort((p, q) => p[0] - q[0]).slice(0, 2).map(p => p[1] + ' from column ' + p[0]).join(', ') + '; the rightmost: ' + names.map(k => [colsOf(S[k])[1], k]).sort((p, q) => q[0] - p[0]).slice(0, 2).map(p => p[1] + ' to column ' + p[0]).join(', '), [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    o.cut = bad;
  }

  // 3. the spots are on what the set draws: the bench's seat top (part banco), the line (part palmas, a pixel of the line within 2 rows below the peg), the things afloat on water,
  //    the people and the sand things on sand, the stop on the road, the driver at the window of the guagua
  {
    const bad = [], lines = [], pxOf = k => (S[k].on === 'guagua' || k === 'parada' ? probes.bus : probes.base)[k] || [];
    const seats = [];
    for (const k of ['banco1', 'banco2']) {
      const s = S[k], best = pxOf(k).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === 'banco' && best.dz < .1;
      seats.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on the bench\'s seat top: ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const pegs = [];
    for (let k = 1; k <= 5; k++) {
      const s = S['cuerda' + k], below = pxOf('cuerda' + k).filter(r => r.dx === 0 && r.dy >= -1 && r.tag === 'palmas' && Math.abs(r.z - s.depth) < .08).map(r => r.dy).sort((a, b) => a - b)[0];
      pegs.push(k + ': ' + (below === undefined ? 'none' : below + ' row' + (below === 1 ? '' : 's') + ' below'));
      if (below === undefined || below > 2) bad.push('cuerda' + k + ' ' + s.screen + ': ' + (below === undefined ? 'no pixel of the line (part palmas at the line\'s depth) in its column' : 'the line is drawn ' + below + ' rows below the peg\'s point (the line sags: the point is at LINE), a piece hung there would float above it'));
    }
    const wet = [], gnd = [];
    for (const [k, s] of Object.entries(S)) {
      if (s.on) continue;
      const r = pxOf(k).find(r => r.dx === 0 && r.dy === 0), want = s.water ? G.KIND.water : k === 'parada' ? G.KIND.road : G.KIND.sand;
      (s.water ? wet : gnd).push(k);
      if (!r || r.kind !== want) bad.push(k + ' ' + s.screen + ': the ground under its point is ' + (r ? 'kind ' + r.kind : 'not there') + ', not ' + (s.water ? 'water' : k === 'parada' ? 'the road' : 'sand') + ' (kind ' + want + ')');
    }
    const ch = pxOf('chofer').filter(r => r.dx === 0 && r.dy === 0)[0];
    if (!ch || ch.tag !== 'guagua') bad.push('chofer ' + S.chofer.screen + ': the pixel under his point is not the guagua\'s wall (part ' + (ch ? ch.tag : 'none') + ')');
    const o = add('spots-on-surface', bad, 'banco1 and banco2 are on the seat top (part banco, depth within .1 of the spot\'s z ' + SEAT_Z + '); the 5 pegs have a pixel of the line within 2 rows below their point (peg ' + pegs.join('; peg ') + '); the ' + wet.length + ' things afloat are on water and the other ' + gnd.length + ' ground spots on sand (parada on the road); the driver\'s point is on the guagua\'s wall (part ' + (ch ? ch.tag : 'none') + ')', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of seats) o.lines.push('       ' + l);
  }

  // 4. the set things' boxes: the guagua's front end, its door and its driver's window are inside the window and the picture; the rest of the side runs off the picture's right edge on purpose
  {
    const t = T.guagua, bad = [], w = [x0, 0, 196, G.H];
    for (const [n, b] of [['door', t.door], ['window', t.window]]) if (!clip(b, w) || clip(b, w).join() !== b.join()) bad.push('guagua ' + n + ' [' + b + '] is not inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture');
    if (t.box[0] < x0) bad.push('guagua box [' + t.box + '] begins left of the window (' + x0 + ')');
    if (t.box[1] < 0 || t.box[1] + t.box[3] > G.H) bad.push('guagua box [' + t.box + '] is outside the picture\'s rows');
    add('things-in-view', bad, 'the guagua\'s box [' + t.box + '] begins at column ' + t.box[0] + ' (inside the window [' + x0 + ', ' + (x0 + 196) + ')) and runs off the picture\'s right edge by ' + (t.box[0] + t.box[2] - G.W) + ' px (on purpose: ' + (t.visible ? t.visible[2] : 0) + ' px of it show in the window); its door [' + t.door + '] and its driver\'s window [' + t.window + '] are inside the window and the picture', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person, a thing or the set (the fronds too): in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set' + (c.hid ? ' (' + hidTxt(c.hidBy) + ')' : '') + ', ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set' + (c.hid ? ': ' + hidTxt(c.hidBy) : '') + ', ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi, 0, apartOf(PV.inspect[m].layers, fi));
      o.lines.push('       nearest passing (shown whole and clear of the others by the sprites-apart rule), moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[specs[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // the nearest place of a small thing's box, along u or along v (steps of .01, up to 3), where the set and the fronds (frame 0) hide none of it
  const nearestBox = async (k, st) => {
    const s = S[k], res = [];
    for (const [ax, lab] of [[0, 'u'], [1, 'v']]) for (let n = 1; n <= 300; n++) {
      let hit = null;
      for (const sg of [1, -1]) {
        const uv = s.uv.slice(); uv[ax] = r4(uv[ax] + sg * n * .01); const [sx, sy] = scrUV(G, uv[0], uv[1], uv[2]), box = [s.box[0] + sx - s.screen[0], s.box[1] + sy - s.screen[1], s.box[2], s.box[3]];
        const c = await PV.boxCover(st, box, r4(s.depth + (uv[1] - s.uv[1]) * COS), sy);
        if (!sum(c.hid) && !c.out) { hit = lab + ' ' + s.uv[ax] + ' -> ' + uv[ax] + ' (' + sgn(sg * n * .01) + ')'; break; }
      }
      if (hit) { res.push(hit); break; }
    }
    return res.join('; or ') || 'none within 3';
  };

  // the nearest LINE height (z) at which the pieces of the pegs `ks` (boxes hung below the line) clear every frond and the set, in steps of .01 (their u and v do not move)
  const nearestLine = async ks => {
    const res = {};
    for (let n = 0; n <= 150; n++) for (const sg of n ? [-1, 1] : [1]) {
      const z = r4(E.LINE + sg * n * .01); if (res[sg] !== undefined) continue;
      let hit = true;
      for (const k of ks) { const s = S['cuerda' + k], sy = scrUV(G, s.uv[0], s.uv[1], z)[1], c = await PV.boxCover(BASE_STATE, [s.box[0], sy, PIECE.w, PIECE.h], r4(s.depth + (z - E.LINE) * .5), sy); if (sum(c.hid) || c.out) { hit = false; break; } }
      if (hit) res[sg] = z;
    }
    return res;
  };
  const lineTxt = r => ['-1', '1'].filter(s => r[s] !== undefined).map(s => 'LINE ' + E.LINE + ' -> ' + r[s] + ' (' + sgn(r[s] - E.LINE) + ')').join(' or ') || 'no height within 1.5';

  // 7. pieces-on-line: the pieces hung on the line (the box of each: pegs 2, 3, 4 hold the shirt, the trousers, the dress; peg 3 the towel) are covered by nobody and by no frond (nor any set part); pegs 1 and 5 are reported
  {
    const bad = [], lines = [], infos = [], hitPegs = [];
    for (let k = 1; k <= 5; k++) {
      const s = S['cuerda' + k], c = await PV.boxCover(BASE_STATE, s.box, s.depth, s.screen[1]), w = await PV.boxCover(BASE_STATE, s.box, s.depth, s.screen[1], true);
      let spr = 0; const who = {}, inM = [];
      for (const m of [1, 2, 3, 4]) { const L = PV.inspect[m].layers, i = idxAt(L, 'cuerda' + k); if (i < 0) continue; inM.push(m); const q = boxCovered(L, planes(L), i); spr += q.n; for (const a in q.who) who[a] = (who[a] || 0) + q.who[a]; }
      const txt = 'cuerda' + k + ' box [' + s.box + ']: ' + sum(c.hid) + ' of its ' + (c.total + c.out) + ' px hidden by the set (' + (hidTxt(c.hid) || 'none') + '), ' + spr + ' covered by a nearer sprite' + (spr ? ' (' + hidTxt(who) + ')' : '') + ' in moments ' + (inM.join(', ') || 'none (no moment hangs a piece there)') + '; ' + c.out + ' outside the picture';
      const wtxt = 'cuerda' + k + ': over the wind (60 s) a frond can reach ' + sum(w.hid) + ' px of it (' + (hidTxt(w.hid) || 'none') + ')';
      if (k >= 2 && k <= 4) { lines.push(txt); if (sum(c.hid) || spr || c.out) { bad.push(txt); if (c.hid.frond) hitPegs.push(k); } } else infos.push('info, not a check (no piece on the pegs 1 and 5 in the moments): ' + txt);
      infos.push(wtxt);
    }
    const o = add('pieces-on-line', bad, 'the pieces on pegs 2, 3 and 4 (the shirt, the trousers, the dress; the towel on peg 3) are covered by nobody and by no frond (frame 0): ' + lines.join('; '), [bad.length + ' peg(s) with a piece covered:'].concat(bad.map(b => '  ' + b)));
    if (hitPegs.length) o.lines.push('       nearest passing LINE height (every frond clear of the pieces on pegs 2, 3, 4; the pieces hang from it): ' + lineTxt(await nearestLine([2, 3, 4])));
    for (const l of infos) o.lines.push('       ' + l);
    const f5 = await PV.boxCover(BASE_STATE, S.cuerda5.box, S.cuerda5.depth, S.cuerda5.screen[1]), f1 = await PV.boxCover(BASE_STATE, S.cuerda1.box, S.cuerda1.depth, S.cuerda1.screen[1]);
    if (f1.hid.frond || f5.hid.frond) o.lines.push('       nearest passing LINE height for all five pegs (frame 0): ' + lineTxt(await nearestLine([1, 2, 3, 4, 5])));
  }

  // 8. things-afloat: the things at agua1 to agua5 (boxes 14 x 9) are covered by nobody and by no frond (moments 3 and 4)
  {
    const bad = [], lines = [];
    for (let k = 1; k <= 5; k++) {
      const s = S['agua' + k], c = await PV.boxCover(BASE_STATE, s.box, s.depth, s.screen[1]), w = await PV.boxCover(BASE_STATE, s.box, s.depth, s.screen[1], true);
      let spr = 0; const who = {}, inM = [];
      for (const m of [3, 4]) { const L = PV.inspect[m].layers, i = idxAt(L, 'agua' + k); if (i < 0) continue; inM.push(m); const q = boxCovered(L, planes(L), i); spr += q.n; for (const a in q.who) who[a] = (who[a] || 0) + q.who[a]; }
      const txt = 'agua' + k + ' [' + s.box + ']: ' + sum(c.hid) + ' of its ' + (c.total + c.out) + ' px hidden by the set (' + (hidTxt(c.hid) || 'none') + '), ' + spr + ' under a nearer sprite' + (spr ? ' (' + hidTxt(who) + ')' : '') + ' (moments ' + inM.join(', ') + '); over the wind a frond can reach ' + sum(w.hid) + ' px';
      lines.push(txt); if (sum(c.hid) || spr || c.out) bad.push(txt);
    }
    const o = add('things-afloat', bad, 'the five things afloat are covered by nobody and by no frond (frame 0): ' + lines.join('; '), [bad.length + ' thing(s) afloat covered:'].concat(bad.map(b => '  ' + b)));
    for (let k = 1; k <= 5; k++) if (bad.some(b => b.startsWith('agua' + k + ' '))) o.lines.push('       nearest passing, agua' + k + ' ' + S['agua' + k].uv + ' (its box clear of the set and the fronds at frame 0): ' + await nearestBox('agua' + k, BASE_STATE));
  }

  // 9. children: moment 6: the four children are whole in the window, covered by neither the guagua, its sign nor a frond, and the frog at coqui.busca covers no more than their feet (the bottom 8 rows)
  {
    const L = PV.inspect[6].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), bad = [], lines = [];
    for (let k = 1; k <= 4; k++) {
      const i = idxAt(L, 'ninos' + k), l = L[i], sx = S['ninos' + k], cut = cutAt(sx, x0), hidBy = { guagua: 0, sign: 0, frond: 0, other: 0 };
      for (const p of l.px) if (p[2]) { const h = p[4] === 'guagua' ? (p[0] < busLeft ? 'sign' : 'guagua') : p[4] === 'frond' ? 'frond' : 'other'; hidBy[h]++; }
      const bottom = Math.max(...l.px.map(p => p[1])), feet = bottom - FEET_ROWS + 1, byFrog = { feet: 0, above: 0 }, others = {};
      for (const p of l.px) {
        if (p[2]) continue;
        let nearest = null; for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== i && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
        if (!nearest) continue;
        if (nearest.i === fi) byFrog[p[1] >= feet ? 'feet' : 'above']++; else others[L[nearest.i].at] = (others[L[nearest.i].at] || 0) + 1;
      }
      lines.push('ninos' + k + ' ' + [l.sx, l.sy] + ': window cut ' + cut + ' px, ' + l.out + ' px outside the picture; hidden by the guagua ' + hidBy.guagua + ', its sign ' + hidBy.sign + ', a frond ' + hidBy.frond + ', any other set part ' + hidBy.other + '; under the frog ' + byFrog.feet + ' px in the feet (rows ' + feet + ' to ' + bottom + ') and ' + byFrog.above + ' above them' + (Object.keys(others).length ? '; under other sprites ' + hidTxt(others) : ''));
      if (cut || l.out) bad.push('ninos' + k + ' ' + [l.sx, l.sy] + ' is not whole in the window (' + cut + ' px cut, ' + l.out + ' outside the picture)');
      for (const [n, v] of Object.entries(hidBy)) if (v) bad.push('ninos' + k + ' ' + [l.sx, l.sy] + ': ' + v + ' of its ' + l.px.length + ' px are hidden by ' + { guagua: 'the guagua', sign: 'its sign (and the post)', frond: 'a frond', other: 'another part of the set' }[n]);
      if (byFrog.above) bad.push('ninos' + k + ' ' + [l.sx, l.sy] + ': the frog at coqui.busca covers ' + byFrog.above + ' px above their feet (the bottom ' + FEET_ROWS + ' rows are ' + feet + ' to ' + bottom + ')');
      if (Object.keys(others).length) bad.push('ninos' + k + ': covered by ' + hidTxt(others));
    }
    const o = add('children', bad, 'the four children of moment 6 are whole in the window, hidden by neither the guagua, its sign nor a frond, and the frog at coqui.busca covers only their feet: ' + lines.join('; '), [bad.length + ' problem(s) with the four children:'].concat(bad.map(b => '  ' + b)));
    // the nearest passing place of a child hidden by the sign / the guagua
    const hint = [];
    for (let k = 1; k <= 4; k++) {
      const i = idxAt(L, 'ninos' + k);
      if (!L[i].px.some(p => p[2])) continue;
      const Mm = PV.moment[6], r = await PV.nearest(Mm.set, Mm.layers, i, 0, apartOf(L, i));
      hint.push('       nearest passing, ninos' + k + ' ' + S['ninos' + k].uv + ' (shown whole, under no nearer sprite, clear of the others by the sprites-apart rule): ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S['ninos' + k].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    for (const h of hint) o.lines.push(h);
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 10. bench-pair: abuela on the bench and the frog beside her are 28 px apart
  {
    const a = S.banco1, b = S.banco2, dx = b.screen[0] - a.screen[0], bad = [];
    if (dx !== 28) bad.push('banco1 ' + a.screen + ' and banco2 ' + b.screen + ' are ' + dx + ' px apart across (' + r2((b.uv[0] - a.uv[0]) * G.S) + ' unrounded), not 28 (their boxes, 24 + 32 wide, need 28)');
    const o = add('bench-pair', bad, 'abuela at banco1 ' + a.screen + ' and the frog at banco2 ' + b.screen + ' are ' + dx + ' px apart across (u ' + a.uv[0] + ' and ' + b.uv[0] + ': ' + r2((b.uv[0] - a.uv[0]) * G.S) + ' unrounded); their boxes (24 and 32 wide) just touch', ['the pair on the bench is not 28 px apart:'].concat(bad.map(x => '  ' + x)));
    if (bad.length) {
      const f = (name, sgOK) => { const s = S[name]; for (let n = 1; n <= 50; n++) for (const sg of [1, -1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], d = name === 'banco2' ? sx - a.screen[0] : b.screen[0] - sx; if (d === 28) return name + ' u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; } return name + ': none within .5'; };
      o.lines.push('       nearest passing: ' + f('banco2') + '; or ' + f('banco1'));
    }
  }

  // 11. plate-clear: the plate (its box, 16 x 10) is covered by nobody (moment 2), and by nothing of the set
  {
    const L = PV.inspect[2].layers, i = L.findIndex(l => l.at === 'plato' && l.box), M = planes(L), s = S.plato, bad = [];
    const q = boxCovered(L, M, i), c = await PV.boxCover(BASE_STATE, s.box, s.depth, s.screen[1]);
    const crate = L.findIndex(l => l.at === 'plato' && !l.box), sh = idxAt(L, 'zapatos'), shoes = coverOf(L, M, sh, [i]);
    if (q.n) bad.push('the plate [' + s.box + '] has ' + q.n + ' px covered by ' + hidTxt(q.who));
    if (sum(c.hid)) bad.push('the plate [' + s.box + '] has ' + sum(c.hid) + ' px hidden by the set (' + hidTxt(c.hid) + ')');
    const o = add('plate-clear', bad, 'the plate [' + s.box + '] (16 x 10, its foot ' + PLATO.lift + ' px above the sand, on a ' + (crate >= 0 ? 'stand-in box' : '') + ') is covered by nobody in moment 2 and hidden by nothing of the set', ['the plate is covered:'].concat(bad.map(x => '  ' + x)));
    const M2 = PV.moment[2], rs = await PV.nearest(M2.set, M2.layers, sh);
    o.lines.push('       info, not a check: the plate (nearer) covers ' + shoes.cov + ' of the shoes\' ' + L[sh].px.length + ' drawn px in moment 2 (zapatos box [' + S.zapatos.box + '], plate box [' + s.box + ']); nearest passing for the shoes to be shown whole: ' + (['u', 'v', 'z'].map(a => rs.axis[a] ? a + ' ' + S.zapatos.uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + rs.axis[a].to + ' (' + sgn(rs.axis[a].d) + ')' : a + ': none within 3').join('; ')));
  }

  // 12. driver: the driver's box (14 x 14) is inside the window and the picture, and drawn whole at his window in moments 5 and 6
  {
    const s = S.chofer, b = s.box, bad = [];
    if (b[0] < x0 || b[0] + b[2] > x0 + 196 || b[0] < 0 || b[0] + b[2] > G.W || b[1] < 0 || b[1] + b[3] > G.H) bad.push('chofer ' + s.screen + ': its box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture');
    const lines = [];
    for (const m of [5, 6]) { const L = PV.inspect[m].layers, i = idxAt(L, 'chofer'), c = coverOf(L, planes(L), i, null); lines.push('m' + m + ': ' + (L[i].px.length + L[i].out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a sprite, ' + L[i].out + ' outside'); if (c.hid || c.cov || L[i].out) bad.push('moment ' + m + ': the driver is not whole (' + c.hid + ' hidden by the set (' + hidTxt(c.hidBy) + '), ' + c.cov + ' under a sprite, ' + L[i].out + ' outside the picture)'); }
    add('driver', bad, 'the driver\'s box [' + b + '] (14 x 14, centred on chofer ' + s.screen + ') is inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture; drawn whole at his window: ' + lines.join('; '), ['the driver:'].concat(bad.map(x => '  ' + x)));
  }

  // info: what the set and the fronds hide of the people and things in each moment (not checks of the spec), and the fronds' reach
  {
    const lines = [], severe = new Map();
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), part = [];
      L.forEach((l, i) => { const c = coverOf(L, M, i, null), n = l.px.length + l.out; if (c.hid || c.cov) part.push(l.at + (l.s ? ' (' + l.s + ')' : '') + ' ' + (c.hid ? c.hid + ' hidden by ' + hidTxt(c.hidBy) : '') + (c.hid && c.cov ? ', ' : '') + (c.cov ? c.cov + ' under ' + whoTxt(c) : '') + ' of ' + n); if (l.at && (c.hid + c.cov) / n >= .2 && l.s !== 'caja' && l.s !== 'zapatos' && !severe.has(l.at)) severe.set(l.at, [m, i, c.hid + c.cov, n]); });
      lines.push('m' + m + ': ' + (part.join('; ') || 'nothing is hidden or covered'));
    }
    const fr = G.fronds, o = { name: 'info-seen', ok: true, lines: ['info-seen: not a check. The palms\' fronds at wind time 0 take ' + fr.frame0.px + ' px in the box [' + fr.frame0.box + ']; over the wind (60 s) ' + fr.wind.px + ' px in [' + fr.wind.box + ']. What the set and the fronds hide of what is drawn in each moment (px of the sprite\'s drawing; a sprite is hidden where the live depth is nearer than its plane + ' + BIAS + '):'].concat(lines.map(l => '       ' + l)) };
    // the places the spec gives that leave a third or more of a drawing hidden (a fifth: listed): the nearest place that shows it whole
    for (const [at, [m, i, n, tot]] of severe) {
      const Mm = PV.moment[m], l = PV.inspect[m].layers[i], sp = S[at];
      if (sp.box && !sp.who) o.lines.push('       nearest passing, ' + at + ' ' + sp.uv + ' (' + n + ' of ' + tot + ' px hidden or covered in moment ' + m + '; its box clear of the set and the fronds): ' + await nearestBox(at, PV.inspect[m].set));
      else { const r = await PV.nearest(Mm.set, Mm.layers, i, 0, apartOf(PV.inspect[m].layers, i)); o.lines.push('       nearest passing, ' + at + ' ' + sp.uv + ' (' + n + ' of ' + tot + ' px hidden or covered in moment ' + m + '; shown whole, clear of the others): ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + sp.uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
    }
    OUTS.push(o);
  }
  return OUTS;
}
