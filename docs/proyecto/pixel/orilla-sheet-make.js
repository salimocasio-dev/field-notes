#!/usr/bin/env node
'use strict';
/* La orilla's sheet: writes docs/proyecto/pixel/orilla-sheet.json from orilla-set.html and the design (the orchestrator's p7-spec, section "orilla"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/orilla-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene (place 7, La playa, scene 1): no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the
   picture, v down it (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S. The beach's numbers (the water's edge, the palms, the rope, the castle's towers, the patch, the blanket, the boat)
   are read from the set (window.ORILLA.E), never typed again from the design.
   It loads the set in headless Chrome (orilla-set.html, tags=1: which part drew each pixel; the baked depth; the depth with the palms' fronds in at frame(0): DEPTH.live()), and writes
   the spots, things, the view (wide), shadows and the depth rule. The sprites' silhouettes come from the preview's own stand-ins (orilla-preview.html, PREVIEW.sil). The checks that say
   "covers" or "shows" read the PREVIEW's moments (PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written
   again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with ORILLA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'orilla-sheet.json');
const BASE = process.env.ORILLA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/orilla-set.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

// every request to BASE is answered from the files of this tree
const serve = route => {
  const u = new URL(route.request().url());
  const f = path.join(REPO, decodeURIComponent(u.pathname));
  if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
  route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
};
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100, sgn = v => (v > 0 ? '+' : '') + r2(v);
const W4 = p => p.map(r4);
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2;

// the numbers of the design (p7-spec: the rules for every sheet, and "orilla")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28, any: 32 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down. any: a spot whose person the spec does not name (llegada, orilla): the widest, the frog's
const SHELL = { w: 6, h: 6 }, SHELL_PITCH = 8;           // a pink shell: 6 px (the spec gives no height: 6 used); three in a row: the spec gives no spacing: 8 px from middle to middle used (open point)
const ROW = { w: 2 * SHELL_PITCH + SHELL.w, h: SHELL.h };                         // the row of three: 22 x 6
const BOAT = { w: 34, h: 20 }, TOY = { w: 14, h: 10 }, TOWEL = { w: 14, h: 16 }, PILE = { w: 14, h: 10 }, CESTA = { w: 12, h: 10 };
const FROGBOAT = { w: 36, h: 8 };                        // the boat the frog rides at navega: the spec gives no size: a plain hull wider than he is (open point)
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STATES = [{ hora: 'manana', castillo: 1, manta: 0 }, { hora: 'mediodia', castillo: 0, manta: 0 }, { hora: 'tarde', castillo: 0, manta: 1 }, { hora: 'ocaso', castillo: 0, manta: 1 }];
// the set state each spot is probed in (the set page is built with that state's parts only): the castle's spots with the castle, the blanket's with the blanket, the rest on the bare beach
const CASTLE_SPOTS = ['castillo_l', 'castillo_r', 'torre1', 'torre2', 'torre3', 'coqui.castillo', 'parche', 'mar_busca', 'abuela.foto', 'perro', 'conchas'];
const MANTA_SPOTS = ['manta_abuela', 'manta_coqui', 'toallas', 'canasta', 'pie1', 'pie2', 'cuerda1', 'cuerda2', 'sale'];
const stateOf = k => CASTLE_SPOTS.includes(k) ? 'castillo' : MANTA_SPOTS.includes(k) ? 'manta' : 'plain';

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor }
   kind: person (a character stands there), place (the frog's, or whoever walks in), thing (a small thing: a shell, a toy boat, a towel, the pile, the basket)
   sil: which drawing hangs there (nino = a child standing, ninoS = a child sitting or kneeling on the sand, abuelaS = abuela sitting on the sand, coqui, perro = Canelo sitting) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle on the point */
function defs(E) {
  const K = E.CASTLE, P = E.PATCH, PV = E.PALMS[0][1], D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  [[-3.0, 2.9], [-1.85, 3.1], [-.7, 2.9], [.45, 3.1]].forEach(([u, v], i) => add('llegada' + (i + 1), [u, v, 0], 'place', null, 'any', 'where one of them walks in (abuela, Luis, Carmen, the frog: the spec does not say which goes where): checked with the widest box, the frog\'s'));
  [.2, 1.2, 2.2, 3.2].forEach((u, i) => add('orilla' + (i + 1), [u, .45, 0], 'place', null, 'any', 'a place of the row on the wet sand (anyone: checked with the widest box, the frog\'s)'));
  add('agua1', [1.0, -.5, 0], 'person', 'nino', 'nino', 'a child wading in the shallow water: to the ankles');
  add('agua2', [1.2, -1.3, 0], 'person', 'nino', 'nino', 'a child wading in the shallow water: to the knees');
  // story 72
  add('castillo_l', [-.35, 3.5, 0], 'person', 'ninoS', 'nino', 'Carmen kneeling at the castle (left); the stand-in is a child sitting (no maker draws a person kneeling)');
  add('castillo_r', [2.75, 3.5, 0], 'person', 'ninoS', 'nino', 'Luis kneeling at the castle (right)');
  K.towers.forEach((tu, i) => add('torre' + (i + 1), [tu, K.v, r4(.12 + K.th)], 'place', 'coqui', 'coqui', 'the top of tower ' + (i + 1) + ' (z 0.12 + th = ' + r4(.12 + K.th) + '): the frog stands there, or a shell', { on: 'castillo' }));
  add('coqui.castillo', [1.2, 7.7, 0], 'place', 'coqui', 'coqui', 'the frog, below the patch of smooth sand');
  add('parche', [P.u, P.v, 0], 'place', 'coqui', 'coqui', 'the middle of the patch of smooth sand: where the frog digs');
  add('mar_busca', [1.2, -.4, 0], 'place', 'coqui', 'coqui', 'in the sea at the water\'s edge: where the frog ducks');
  add('abuela.foto', [-1.9, 4.6, 0], 'person', 'abuelaS', 'adulto', 'abuela sitting on the sand, with her camera');
  add('perro', [3.3, 4.6, 0], 'person', 'perro', 'perro', 'Canelo (sitting up)');
  add('conchas', [2.9, 5.5, 0], 'thing', null, null, 'three pink shells in a row (' + SHELL.w + ' px each, ' + SHELL_PITCH + ' px from middle to middle: the spec gives no spacing), the row\'s bottom middle on the spot', { size: [ROW.w, ROW.h], anchor: 'bottom', parts: 3 });
  // story 73
  add('luis.botes', [.3, .65, 0], 'person', 'ninoS', 'nino', 'Luis sitting on the wet sand with his two boats');
  add('bote_a', [1.15, .55, 0], 'thing', null, null, 'a toy boat on the wet sand (' + TOY.w + ' x ' + TOY.h + ')', { size: [TOY.w, TOY.h], anchor: 'bottom' });
  add('bote_b', [1.9, .55, 0], 'thing', null, null, 'a toy boat on the wet sand (' + TOY.w + ' x ' + TOY.h + ')', { size: [TOY.w, TOY.h], anchor: 'bottom' });
  add('coqui.orilla', [2.9, 1.6, 0], 'place', 'coqui', 'coqui', 'the frog on the sand near the water');
  add('conchas73', [1.6, 1.75, 0], 'thing', null, null, 'three pink shells in a row, on the sand (' + SHELL.w + ' px each, ' + SHELL_PITCH + ' px apart)', { size: [ROW.w, ROW.h], anchor: 'bottom', parts: 3 });
  add('abuela.arena', [-2.9, 3.4, 0], 'person', 'abuelaS', 'adulto', 'abuela sitting on the sand');
  add('navega', [2.4, -.7, 0], 'place', 'coqui', 'coqui', 'the frog in a boat on the water, half way to Carmen (the boat: a plain hull ' + FROGBOAT.w + ' x ' + FROGBOAT.h + ', the spec gives no size)', { boat: [FROGBOAT.w, FROGBOAT.h] });
  // story 74
  add('manta_abuela', [-3.1, 4.15, 0], 'person', 'abuelaS', 'adulto', 'abuela on her blanket (sitting)', { on: 'manta' });
  add('manta_coqui', [-1.4, 4.5, 0], 'place', 'coqui', 'coqui', 'the frog on abuela\'s blanket', { on: 'manta' });
  add('toallas', [-2.35, 3.5, 0], 'thing', null, null, 'the pile of three folded towels (' + PILE.w + ' x ' + PILE.h + ') on the blanket', { size: [PILE.w, PILE.h], anchor: 'bottom', on: 'manta' });
  add('canasta', [-2.35, 4.6, 0], 'thing', null, null, 'the basket (' + CESTA.w + ' x ' + CESTA.h + ') on the blanket', { size: [CESTA.w, CESTA.h], anchor: 'bottom', on: 'manta' });
  add('pie1', [-.2, 4.3, 0], 'person', 'nino', 'nino', 'a child standing in front of the blanket');
  add('pie2', [.95, 4.3, 0], 'person', 'nino', 'nino', 'a child standing in front of the blanket');
  add('cuerda1', [-3.1, PV, E.ROPE], 'thing', null, null, 'the first towel\'s place on the rope (z ROPE ' + E.ROPE + '): the towel hangs below it (' + TOWEL.w + ' x ' + TOWEL.h + '), its top middle on the point', { size: [TOWEL.w, TOWEL.h], anchor: 'top', on: 'cuerda' });
  add('cuerda2', [-2.45, PV, E.ROPE], 'thing', null, null, 'the second towel\'s place on the rope: the towel hangs below it (' + TOWEL.w + ' x ' + TOWEL.h + ')', { size: [TOWEL.w, TOWEL.h], anchor: 'top', on: 'cuerda' });
  add('sale', [2.2, .5, 0], 'person', 'nino', 'nino', 'a child coming out of the water');
  add('bote', [E.BOAT[0], E.BOAT[1], 0], 'thing', null, null, 'the fishing boat at anchor (a sprite, ' + BOAT.w + ' x ' + BOAT.h + '): its bottom middle on BOAT; the set draws it only for bote=1', { size: [BOAT.w, BOAT.h], anchor: 'bottom' });
  return D;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots above the ground are on what the set draws:
   the towers' tops, the rope; the ground ones on the ground the spec says), things-in-view, things-hold-pixels (the sea, the patch and the castle hold every pixel the set draws for them), sprites-apart (the people of a moment),
   frog-seen (the frog whole in every moment), castle-towers (Carmen and Luis kneeling cover at most a tenth of a tower), patch-clear, towels-clear, boats-clear, frog-torre2, blanket.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const errs = [];
  const open = async url => { const p = await browser.newPage(); p.on('pageerror', e => errs.push(String(e))); await p.route(BASE + '/**', serve); await p.goto(url); return p; };

  // the main set page: every part on (the castle, the blanket, the boat), tagged
  const page = await open(PAGE + '?tags=1&castillo=1&manta=1&bote=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(ORILLA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  G.sea = await seaProbe(page);
  {                                                                                  // the stand-ins' drawn silhouettes (the preview's own makers; they do not need the sheet)
    const sp = await open(BASE + '/docs/proyecto/pixel/orilla-preview.html?nodraw=1');
    const sil = k => sp.evaluate(k => window.PREVIEW.sil(k), k);
    SILS = { nino: await sil('luis'), ninoS: await sil('luisS'), abuelaS: await sil('abuelaS'), coqui: await sil('coqui'), perro: await sil('perro') };
    await sp.close();
  }
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(open, page, sheet, G);
  probes.towers = await towerPixels(open, G);
  const PV = await previewData(open);
  const results = await checks(sheet, G, probes, PV);
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

/* ---------- the preview's moments: orilla-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden (1 by the baked set, 2 by a frond only), plane]) ---------- */
async function previewData(open) {
  const p = await open(BASE + '/docs/proyecto/pixel/orilla-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.SIL = SILS;
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  PV.nearestAvoid = (st, specs, idx, keys, allow) => p.evaluate(x => window.PREVIEW.nearestAvoid(x.st, x.specs, x.idx, x.keys, x.allow), { st, specs, idx, keys, allow: allow || 0 });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
// the columns a spot's sprite takes: [first, last]. A person: the spec's box (the feet's spot in the middle) and the stand-in's drawn ink, whichever is wider ("its sprite whole"); a small thing: its box;
// the frog at navega: his boat too
let SILS = null;                                         // the stand-ins' silhouettes (PREVIEW.sil), read before the sheet is made
const colsOf = s => {
  let [a, b] = s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
  const sil = s.sprite ? SILS[s.sprite] : s.who === 'any' ? SILS.coqui : null;
  if (sil) { a = Math.min(a, s.screen[0] + sil.box[0]); b = Math.max(b, s.screen[0] + sil.box[2]); }
  if (s.boat) { a = Math.min(a, s.screen[0] - Math.floor(s.boat[0] / 2)); b = Math.max(b, s.screen[0] - Math.floor(s.boat[0] / 2) + s.boat[0] - 1); }
  return [a, b];
};
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj) {
  const E = G.E, sc = G.scene, DEF = defs(E);
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.parts) o.parts = [0, 1, 2].map(k => [sx - Math.floor(ROW.w / 2) + k * SHELL_PITCH, sy - SHELL.h, SHELL.w, SHELL.h]);
    if (d.boat) o.boat = d.boat;
    if (d.uvz[2] > 0) o.on = d.on || 'ground';                                  // what it stands on above the ground: the tower's top, the rope
    else if (d.on) o.on = d.on;                                                 // the blanket
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [72, 73, 74], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 72, 73 and 74: the 196 x 216 window over the 240 x 216 picture. The spec: every spot is inside it with its sprite whole, x0 22 unless a spot is cut. ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all' + (ok0.includes(centred) ? '' : ' (x0 ' + centred + ' cuts ' + held.filter(([, s]) => cutAt(s, centred)).map(([k, s]) => k + ' by ' + cutAt(s, centred) + ' px').join(', ') + ')') + '; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async (corners) => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what, more) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    return Object.assign({ set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what }, more || {});
  };
  const B = E.B, K = E.CASTLE, P = E.PATCH, things = {};
  const uL = Math.ceil((x0 - G.OX) / G.S * 1e4) / 1e4, uR = Math.floor((x0 + 196 - G.OX) / G.S * 1e4) / 1e4;   // the window's two edges in u, rounded in
  const seaV1 = Math.ceil(G.sea.vmax * 100) / 100;
  things.mar = await setThing(uL, B.deep, 0, uR, seaV1, 0, 'the shallow sea: from the water\'s edge out to where it turns dark (v ' + B.deep + ' to ' + B.edge + '), across the view (u ' + uL + ' to ' + uR + '). The edge wanders (the set\'s wob, up to ' + r4(seaV1 - B.edge) + ' down the beach), so the box runs to v ' + seaV1 + ' to hold every pixel of the sea; a poke (the dark sea beyond v ' + B.deep + ' is not in it)', { state: 'always' });
  things.arena = await setThing(r4(P.u - P.ru), r4(P.v - P.rv), 0, r4(P.u + P.ru), r4(P.v + P.rv), 0, 'the patch of smooth sand in front of the castle: its oval\'s box (u ' + r4(P.u - P.ru) + ' to ' + r4(P.u + P.ru) + ', v ' + r4(P.v - P.rv) + ' to ' + r4(P.v + P.rv) + '); a poke. Only where castillo = 1', { state: 'castillo = 1' });
  things.bote = 'sprite'; things.bote_a = 'sprite'; things.bote_b = 'sprite'; things.toalla_a = 'sprite'; things.toalla_b = 'sprite'; things.toallas = 'sprite';
  things.castillo = await setThing(r4(K.u - K.r), r4(K.v - K.r), 0, r4(K.u + K.r), r4(K.v + K.r), r4(.12 + K.th + .11), 'the sand castle: its round base (r ' + K.r + ') with its three towers up to the top of their battlements (z 0 to ' + r4(.12 + K.th + .11) + '); a poke. Only where castillo = 1', { state: 'castillo = 1' });
  things.conchas = 'sprite';
  for (const k of ['abuela', 'luis', 'carmen', 'coqui', 'perro']) things[k] = 'sprite';

  return {
    scene: 'orilla',
    made: 'node docs/proyecto/pixel/orilla-sheet-make.js, from orilla-set.html (window.ORILLA.E) and the design of La orilla (the orchestrator\'s p7-spec, section orilla). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the water\'s edge at v ' + B.edge + '; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '; v from ' + r2((0 - G.OY) / 13) + ' (above the horizon, v ' + B.hor + ') to ' + r2((G.H - G.OY) / 13),
      spot: 'a spot is a world point of the feet (z 0: the sand or the shallow water; z ' + r4(.12 + K.th) + ': a tower\'s top; z ' + E.ROPE + ': the rope) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the shells, the toy boats, the pile, the basket, the fishing boat have their bottom middle on the spot; a towel on the rope hangs with its top middle on it. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up, 41 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); Canelo sitting mkPerro(\'sit\') (30 x 22): column 15 and its bottom edge. Whoever sits or kneels on the sand (abuela.foto, abuela.arena, manta_abuela, luis.botes, castillo_l, castillo_r): no maker draws a person on the sand (today\'s sitting sprites are drawn for a seat, their legs hang below the lap and the ground would hide them), so the stand-in is today\'s sitting drawing cut off just below the hips and given an outline row, its bottom edge on sy (open point: the real art). A small thing: see spot. Nobody is turned: the makers draw everyone from the front',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character. The set is taken at frame(0): the depth of window.DEPTH.live() (the palms\' fronds drawn in), not the baked one, so a frond in front of a spot covers it',
      boat: 'the fishing boat: a sprite ' + BOAT.w + ' x ' + BOAT.h + ' with its bottom middle on spot bote (BOAT u ' + E.BOAT[0] + ', v ' + E.BOAT[1] + '). The set draws a boat there only with bote = 1 (for the readers\' renders: preview moments 3 and 4 use it); in the game it is the sprite',
      shells: 'a pink shell: ' + SHELL.w + ' x ' + SHELL.h + ' (the spec gives the width; the height is a stand-in); the three of a row (conchas, conchas73) are ' + SHELL_PITCH + ' px from middle to middle: the row is ' + ROW.w + ' x ' + ROW.h + ', its bottom middle on the spot; spots.*.parts lists the three boxes. A shell on a tower has its bottom middle on torre1 / torre3',
      towels: 'a towel on the rope (cuerda1, cuerda2): ' + TOWEL.w + ' wide, ' + TOWEL.h + ' high, hanging below the point: the box [sx - 7, sy, ' + TOWEL.w + ', ' + TOWEL.h + ']; toalla_a hangs at cuerda1 and toalla_b at cuerda2',
    },
    setKey: {
      params: { hora: { values: ['manana', 'mediodia', 'tarde', 'ocaso'], note: '72 manana, 73 mediodia, 74 tarde for its opening and ocaso for its game and ending (the sun low)' }, castillo: { values: [0, 1], note: 'the sand castle with its patch of smooth sand (story 72)' }, manta: { values: [0, 1], note: 'abuela\'s blanket in the palms\' shade (story 74)' }, bote: { values: [0, 1], note: 'the fishing boat drawn by the set: for the readers\' renders only (the preview\'s moments 3 and 4); in the game it is the sprite bote' } },
      key: 'hora + castillo + manta, e.g. "manana-1-0"',
      baked: STATES.map(s => '?hora=' + s.hora + '&castillo=' + s.castillo + '&manta=' + s.manta),
    },
    things,
    spots,
    groups: {
      llegada: ['llegada1', 'llegada2', 'llegada3', 'llegada4'], orilla: ['orilla1', 'orilla2', 'orilla3', 'orilla4'], agua: ['agua1', 'agua2'], torres: ['torre1', 'torre2', 'torre3'], conchas: ['conchas', 'conchas73'], cuerda: ['cuerda1', 'cuerda2'],
      spriteAt: { bote: 'bote', bote_a: 'bote_a', bote_b: 'bote_b', toalla_a: 'cuerda1', toalla_b: 'cuerda2', toallas: 'toallas', conchas: ['conchas', 'conchas73'] },
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p7-spec, "orilla"), given in (u, v, z); the castle, the patch, the palms, the rope and the boat\'s places are read from the set (window.ORILLA.E)',
      'torre1 to torre3 are the towers\' tops (u E.CASTLE.towers, v E.CASTLE.v, z 0.12 + th); cuerda1 and cuerda2 are on the rope at v E.PALMS v (the rope sags up to .09 between the palms: the rope is a few px under the point, see spots-on-surface)',
      'llegada1 to llegada4 and orilla1 to orilla4 name no person in the spec: their sprite is checked with the widest box, the frog\'s (32)',
      'the spec gives no size for the frog\'s boat at navega (' + FROGBOAT.w + ' x ' + FROGBOAT.h + ' used), no spacing for the three shells of a row (' + SHELL_PITCH + ' px used) and no height for a shell (' + SHELL.h + ' used): open points',
      'mar is the whole shallow sea across the view and runs to the lowest pixel the edge wanders to; arena and castillo exist only with castillo = 1',
      'the view\'s x0: the x0 that holds every spot, the one nearest the window centred on the picture (views.wide.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the set\'s depth at frame(0), the palms\' fronds in, with the feet\'s depth plus 0.3): the palms\' trunks and fronds, the castle\'s towers hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where live[r * 240 + x] > depth(r) + bias (live: window.DEPTH.live() of the set page after frame(0)). The same rule as El calendario\'s sheet: the upright plane through the feet (a towel on the rope: the plane through its top, on the rope)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn (the frog is the last layer of every moment)',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0), through frame(t, casts). The spec gives no radius: these are El calendario\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onTop: 'whoever stands above the ground (the frog on a tower: z above 0) casts none: a shadow cast at the sand under him would show in front of the castle',
    },
  };
}

// the sea: the lowest v of any water pixel (the edge wanders); the water pixels of the shallow part below the nominal edge
async function seaProbe(page) {
  return page.evaluate(() => {
    const B = ORILLA.E.B; let vmax = -1e9, vmin = 1e9, out = 0, n = 0;
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const i = iy * W + ix; if (!ground[i] || kinds[i] !== KIND_WATER) continue; const g = unproject(ix + .5, iy + .5), v = PZ.uv(g.x, g.y)[1]; vmax = Math.max(vmax, v); vmin = Math.min(vmin, v); if (v >= B.deep) { n++; if (v > B.edge) out++; } }
    return { vmax, vmin, shallow: n, belowEdge: out };
  });
}

/* ---------- the checks that read the set's own pixels ---------- */
// what the set drew at each spot's feet (the baked depth and the part), the ground there (PL.ground) and the patch: run in the page of the spot's state
function spotProbe(arg) {
  const o = {}, P = ORILLA.E.PATCH;
  for (const [k, s] of Object.entries(arg)) {
    const rows = [];
    for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) {
      const X = s.screen[0] + dx, Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
      const i = Y * W + X, c = bakedPix[i];
      rows.push({ dx, dy, tag: TAGS[i], z: DEPTH.z[i], gz: groundZ[i], rgb: [c & 255, c >> 8 & 255, c >> 16 & 255] });
    }
    const [ix, iy] = s.screen, g = PL.ground(s.uv[0], s.uv[1], ix, iy, ORILLA.E.B), i = iy * W + ix, d = Math.hypot((s.uv[0] - P.u) / P.ru, (s.uv[1] - P.v) / P.rv);
    o[k] = { rows, ground: g ? g[1] : null, gz: groundZ[i], z: DEPTH.z[i], patch: d < 1 };
  }
  return o;
}
async function probeSets(open, page, sheet, G) {
  const sea = G.sea, spotsPx = {};
  for (const [state, q] of [['plain', '?tags=1'], ['castillo', '?tags=1&castillo=1'], ['manta', '?tags=1&manta=1']]) {
    const p = await open(PAGE + q);
    spotsPx[state] = await p.evaluate(spotProbe, Object.fromEntries(Object.entries(sheet.spots).filter(([k]) => stateOf(k) === state).map(([k, s]) => [k, { screen: s.screen, uv: s.uv }])));
    await p.close();
  }
  const px = Object.assign({}, spotsPx.plain, spotsPx.castillo, spotsPx.manta);
  // the patch's pixels (castillo = 1): the ground points inside its oval; and what the set does over them; the castle's pixels
  const pc = await open(PAGE + '?tags=1&castillo=1');
  const patch = await pc.evaluate(() => {
    const P = ORILLA.E.PATCH, live = DEPTH.live(), keys = []; let covered = 0, shadow = 0;
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const i = iy * W + ix; if (!ground[i]) continue;
      const g = unproject(ix + .5, iy + .5), [u, v] = PZ.uv(g.x, g.y);
      if (Math.hypot((u - P.u) / P.ru, (v - P.v) / P.rv) < 1) { keys.push(i); if (live[i] !== groundZ[i]) covered++; if (staticShadow[i]) shadow++; }
    }
    const castle = []; for (let i = 0; i < W * H; i++) if (TAGS[i] === 'castillo') castle.push(i);
    return { keys, setCover: covered, shadow, castle };
  });
  await pc.close();
  // the set's own fishing boat (bote = 1): the box of the pixels it drew
  const boat = await page.evaluate(() => { let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1, n = 0; for (let i = 0; i < W * H; i++) if (TAGS[i] === 'bote') { n++; const x = i % W, y = (i / W) | 0; x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); } return { n, box: [x0, y0, x1 - x0 + 1, y1 - y0 + 1] }; });
  // the shallow sea's pixels (for the box of mar)
  const seaPx = await page.evaluate(() => { const B = ORILLA.E.B, o = []; for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) { const i = iy * W + ix; if (!ground[i] || kinds[i] !== KIND_WATER) continue; const g = unproject(ix + .5, iy + .5), v = PZ.uv(g.x, g.y)[1]; if (v >= B.deep) o.push(i); } return o; });
  return { spotsPx: px, sea, patch, boat, castlePx: patch.castle, seaPx };
}

// the pixels of each tower (the pixels whose depth changes when that tower is built, over the base alone) and what the frame(0) shows of them
async function towerPixels(open, G) {
  const p = await open(PAGE + '?castillo=1');
  const res = await p.evaluate(() => {
    const E = ORILLA.E, K = E.CASTLE, save = K.towers.slice(), bakeZ = ts => { K.towers = ts; ORILLA.buildSet(); frame(0); return [Float32Array.from(bakedZ), Float32Array.from(DEPTH.live())]; };
    const base = bakeZ([]), towers = save.map(tu => { const [z, live] = bakeZ([tu]), keys = []; for (let i = 0; i < W * H; i++) if (z[i] !== base[0][i]) keys.push(i); return { u: tu, keys, shown: keys.filter(i => live[i] === z[i]).length }; });
    K.towers = save; ORILLA.buildSet(); frame(0);
    return towers;
  });
  await p.close();
  return res;
}

function checks(sheet, G, probes, PV) { return checksAsync(sheet, G, probes, PV); }
async function checksAsync(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, SIL = PV.SIL;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  const vars = ['u', 'v', 'z'];
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them
  const coverOf = (L, M, t, by) => {
    const l = L[t]; let tot = 0, hid = 0, frond = 0, cov = 0; const who = {};
    for (const p of l.px) {
      tot++; if (p[2]) { hid++; if (p[2] === 2) frond++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].at + (L[nearest.i].s ? ' (' + L[nearest.i].s + ')' : ''); who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, frond, cov, who, out: l.out };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const idxS = (L, s, at) => L.findIndex(l => l.s === s && (!at || l.at === at));
  const idxAt = (L, at) => L.findIndex(l => l.at === at);

  // 1. the view: x0 holds every spot
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const cut22 = v.holds.map(k => [k, cutAt(S[k], 22)]).filter(o => o[1]);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)' + (cut22.length ? '; x0 22 would cut ' + cut22.map(c => c[0] + ' by ' + c[1] + ' px').join(', ') : '; x0 22 holds them all'), [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole
  {
    const bad = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sil = s.sprite ? SIL[s.sprite] : s.who === 'any' ? SIL.nino : null;
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else if (sil) { top = sy + sil.box[1]; bottom = sy + sil.box[3]; } else { top = sy; bottom = sy; }
      if (s.boat) { top = Math.min(top, sy - s.boat[1]); }
      const aa = a, bb = b;
      const cutL = Math.max(0, x0 - aa), cutR = Math.max(0, bb - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -aa), picR = Math.max(0, bb - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + s.box + ']') + ' is cut ' + cut.concat([picL && 'by the picture\'s left edge ' + picL, picR && 'by the picture\'s right edge ' + picR].filter(Boolean)).join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k];
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = Object.assign({}, s, { screen: [sx, s.screen[1]] }); if (s.box) t.box = [s.box[0] + sx - s.screen[0], s.box[1], s.box[2], s.box[3]]; if (!cutAt(t, x0) && colsOf(t)[0] >= 0 && colsOf(t)[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the fishing boat bote is box [' + S.bote.box + '], the rope\'s towels cuerda1 [' + S.cuerda1.box + '] and cuerda2 [' + S.cuerda2.box + ']; the lowest feet row is ' + Math.max(...Object.values(S).map(s => s.screen[1])) + ' of ' + (G.H - 1) + ', the highest sprite top row ' + Math.min(...Object.entries(S).map(([k, s]) => s.box ? s.box[1] : s.sprite ? s.screen[1] + SIL[s.sprite].box[1] : s.screen[1])), [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    o.cut = bad;
    // info: the drawn ink of each stand-in against the spec's width (the check above holds whichever is wider: "its sprite whole")
    const spec = { nino: 'nino', ninoS: 'nino', abuelaS: 'adulto', coqui: 'coqui', perro: 'perro' };
    o.lines.push('       info, not a check: the check takes the wider of the spec\'s box (frog 32, grown-up 24, child 24, dog 28) and the stand-in\'s drawn ink; the ink of each: ' + Object.entries(SIL).map(([k, v]) => k + ' ' + (v.box[2] - v.box[0] + 1) + ' wide (spec ' + WIDTH[spec[k]] + '), columns ' + v.box[0] + ' to ' + v.box[2] + ' from its anchor, rows ' + v.box[1] + ' to ' + v.box[3] + ' from its feet row').join('; '));
  }

  // 3. the spots on what the set draws: the towers' tops (part castillo, depth the spot's), the rope's points (a rope pixel under the point), the ground ones on the ground the spec says; nothing of the set at the feet
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const k of ['torre1', 'torre2', 'torre3']) {
      const s = S[k], best = px[k].rows.filter(r => Math.abs(r.dx) <= 1 && Math.abs(r.dy) <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === 'castillo' && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on the tower\'s top: ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel'));
    }
    for (const k of ['cuerda1', 'cuerda2']) {
      const s = S[k], near = px[k].rows.filter(r => r.tag === 'palmas' && Math.abs(r.z - s.depth) < .1 && r.dx === 0).sort((a, b) => Math.abs(a.dy) - Math.abs(b.dy))[0];
      lines.push(k + ' z ' + s.uv[2] + ' (ROPE): the set\'s rope pixel (part palmas, depth within .1 of the spot\'s) in its column is ' + (near ? near.dy + ' px ' + (near.dy > 0 ? 'under' : near.dy < 0 ? 'over' : 'on') + ' the point (the rope sags, the point is at ROPE)' : 'not within 3 px'));
      if (!near || Math.abs(near.dy) > 3) bad.push(k + ' ' + s.screen + ': no pixel of the rope within 3 px of the point in its column');
    }
    if (!px.parche.patch) bad.push('parche ' + S.parche.screen + ' is not on the patch of smooth sand');
    lines.push('parche (the patch\'s middle) is on the patch of smooth sand: ' + px.parche.patch);
    // the ground ones: the ground the spec names (the row on the wet sand, the shallow water), and nothing of the set at the feet
    const want = { orilla1: 'mojada', orilla2: 'mojada', orilla3: 'mojada', orilla4: 'mojada', agua1: 'mar', agua2: 'mar', mar_busca: 'mar', navega: 'mar' };
    const kinds = {};
    for (const [k, s] of Object.entries(S)) {
      if (s.uv[2] > 0) continue;
      const g = px[k], kind = g.patch ? 'patch of smooth sand' : g.ground === 'mojada' ? 'wet sand' : g.ground === 'mar' ? 'sea' : g.ground === 'arena' ? 'dry sand' : String(g.ground);
      (kinds[kind] = kinds[kind] || []).push(k);
      if (want[k] && g.ground !== want[k]) bad.push(k + ' ' + s.screen + ' is on ' + kind + ', the spec puts it ' + (want[k] === 'mojada' ? 'on the wet sand' : 'in the water'));
      if (want[k] === 'mar') { const t = (-s.uv[1]) / (E.B.edge - E.B.deep); lines.push(k + ' in the sea ' + r2(-s.uv[1]) + ' out (' + Math.round(t * 100) + '% of the way to where it turns dark at v ' + E.B.deep + ')'); }
      const over = g.z - g.gz;
      if (over > .05 && !s.on) bad.push(k + ' ' + s.screen + ': something of the set is at its feet (depth ' + r2(g.z) + ' against the ground\'s ' + r2(g.gz) + ')');
    }
    const o = add('spots-on-surface', bad, 'the 3 tower spots are on a tower\'s top (part castillo, depth within .1 of the spot\'s), the 2 rope spots have the rope within 3 px under the point; orilla1 to orilla4 are on the wet sand and agua1, agua2, mar_busca, navega in the sea; nothing of the set stands at the feet of the ' + Object.values(kinds).reduce((a, b) => a + b.length, 0) + ' ground spots (on the blanket, z .03, excepted); ground by spot: ' + Object.entries(kinds).map(([k, v]) => k + ': ' + v.join(', ')).join('; '), ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       the spec\'s rule "a person on a seat sits on its top": this scene has no seat (everybody stands, kneels or sits on the sand, z 0); the nearest thing is the frog on a tower: z ' + S.torre2.uv[2] + ' = 0.12 + th, the tower\'s top');
    // info: which spots lie on the castle's base (when castillo = 1) or the blanket (when manta = 1) without being the castle's or the blanket's own
    const Kc = E.CASTLE, Bk = E.BLANKET, onC = [], onM = [];
    for (const [k, s] of Object.entries(S)) {
      if (s.uv[2] > 0 || CASTLE_SPOTS.includes(k) || k === 'bote') continue;
      const d = Math.hypot(s.uv[0] - Kc.u, s.uv[1] - Kc.v); if (d < Kc.r) onC.push(k + ' (' + r2(d) + ' from its middle, base r ' + Kc.r + ')');
      if (!MANTA_SPOTS.includes(k) && s.uv[0] >= Bk[0] && s.uv[0] <= Bk[2] && s.uv[1] >= Bk[1] && s.uv[1] <= Bk[3]) onM.push(k);
    }
    o.lines.push('       info, not a check: with castillo = 1 the castle\'s base is under ' + (onC.join(', ') || 'no other spot') + '; with manta = 1 the blanket is under ' + (onM.join(', ') || 'no other spot') + ' (the spots of the stories that have neither are probed on the bare beach)');
  }

  // 4. the set things' boxes are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    const o = add('things-in-view', bad, 'the boxes of mar, arena and castillo are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    const Bk = E.BLANKET, bl = scrUV(G, Bk[0], Bk[1], 0)[0], br = scrUV(G, Bk[2], Bk[3], 0)[0];
    o.lines.push('       info, not a check: the blanket (a set part, manta = 1, not a thing) spans columns ' + bl + ' to ' + br + ': ' + (bl < x0 ? (x0 - bl) + ' px of its left edge are left of the window' : 'inside the window'));
  }

  // 5. the set things hold their pixels: every shallow-sea pixel in the box of mar (and, with the nominal edge v 0, how many are below it), every pixel of the castle in the box of castillo, every patch pixel in arena
  {
    const bad = [], inB = (b, i) => inside(b, i % G.W, (i / G.W) | 0);
    const sea = probes.seaPx, seaOut = sea.filter(i => !inB(T.mar.box, i)).filter(i => (i % G.W) >= x0 && (i % G.W) < x0 + 196), castle = probes.castlePx.filter(i => !inB(T.castillo.box, i)), patch = probes.patch.keys.filter(i => !inB(T.arena.box, i));
    if (seaOut.length) bad.push('mar: ' + seaOut.length + ' px of the shallow sea (inside the window) are outside its box [' + T.mar.box + ']');
    if (castle.length) bad.push('castillo: ' + castle.length + ' px of the castle are outside its box [' + T.castillo.box + ']');
    if (patch.length) bad.push('arena: ' + patch.length + ' px of the patch are outside its box [' + T.arena.box + ']');
    add('things-hold-pixels', bad, 'the shallow sea (' + sea.length + ' px, v ' + E.B.deep + ' to the lowest the edge wanders to, v ' + r2(probes.sea.vmax) + ': ' + probes.sea.belowEdge + ' of them lie below v ' + E.B.edge + ', the nominal edge) is inside mar [' + T.mar.box + ']; the castle (' + probes.castlePx.length + ' px) is inside castillo [' + T.castillo.box + ']; the patch (' + probes.patch.keys.length + ' px) is inside arena [' + T.arena.box + ']', ['pixels outside their thing\'s box:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 6. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
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

  // 7. frog-seen: in every moment his whole drawing is seen (no pixel hidden by the set or a frond, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + (c.hid - c.frond) + ' hidden by the set, ' + c.frond + ' by a frond, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + (c.hid - c.frond) + ' hidden by the set, ' + c.frond + ' by a frond, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[specs[fi].at].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '));
    }
  }

  // 8. castle-towers: Carmen and Luis kneeling cover no more than a tenth of any tower (the pixels the set shows of it at frame(0)), in the moments they kneel
  {
    const bad = [], lines = [], hints = [];
    for (const m of [1, 2]) {
      const L = PV.inspect[m].layers, kn = ['castillo_l', 'castillo_r'].map(a => idxAt(L, a)), shown = new Map();
      for (const i of kn) for (const p of L[i].px) if (!p[2]) shown.set(key(p[0], p[1]), L[i].at);
      probes.towers.forEach((t, ti) => {
        const hit = t.keys.filter(k => shown.has(k)), pct = t.shown ? hit.length / t.shown : 0, who = {}; hit.forEach(k => { who[shown.get(k)] = (who[shown.get(k)] || 0) + 1; });
        lines.push('m' + m + ' tower ' + (ti + 1) + ' (u ' + t.u + '): ' + hit.length + ' of its ' + t.shown + ' shown px covered (' + (Math.round(pct * 1000) / 10) + '%)' + (hit.length ? ' by ' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', ') : ''));
        if (pct > .1) { bad.push('moment ' + m + ': tower ' + (ti + 1) + ' has ' + hit.length + ' of its ' + t.shown + ' px (' + (Math.round(pct * 1000) / 10) + '%) covered by Carmen and Luis, more than a tenth'); hints.push([m, ti, kn]); }
      });
    }
    const o = add('castle-towers', bad, 'Carmen at castillo_l and Luis at castillo_r (kneeling) cover at most a tenth of any tower in moments 1 and 2: ' + lines.join('; '), [bad.length + ' tower(s) covered by more than a tenth:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ti] of hints) { const M = PV.moment[m]; for (const k of ['castillo_l', 'castillo_r']) { const ci = M.layers.findIndex(l => l.at === k), r = await PV.nearestAvoid(M.set, M.layers, ci, probes.towers[ti].keys, .1 * probes.towers[ti].shown / Math.max(1, probes.towers[ti].keys.length)); o.lines.push('       nearest passing, moment ' + m + ' ' + k + ' ' + S[k].uv + ' (tower ' + (ti + 1) + '): ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[k].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')); } }
  }

  // 9. patch-clear: nobody and nothing covers the patch in moment 1 (no shown sprite pixel on it, nothing of the set nearer than the ground over it)
  {
    const L = PV.inspect[1].layers, keys = new Set(probes.patch.keys), who = {}, bad = [];
    L.forEach(l => { for (const p of l.px) if (!p[2] && keys.has(key(p[0], p[1]))) who[l.at + ' (' + l.s + ')'] = (who[l.at + ' (' + l.s + ')'] || 0) + 1; });
    const n = Object.values(who).reduce((a, b) => a + b, 0);
    if (n) bad.push('moment 1: ' + n + ' of the patch\'s ' + keys.size + ' px are under a sprite: ' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', '));
    if (probes.patch.setCover) bad.push('the set covers ' + probes.patch.setCover + ' of the patch\'s ' + keys.size + ' px (something nearer than the sand)');
    const o = add('patch-clear', bad, 'in moment 1 nobody and nothing covers the patch of smooth sand (' + keys.size + ' px, box [' + T.arena.box + ']): no sprite pixel on it, nothing of the set nearer than the sand; the castle\'s shadow darkens ' + probes.patch.shadow + ' of its px (a shadow is not a cover)', [bad.length + ' covering of the patch:'].concat(bad.map(b => '  ' + b)));
    if (n) for (const l of L) { const i = L.indexOf(l); if (!who[l.at + ' (' + l.s + ')'] || !l.who) continue; const M = PV.moment[1], r = await PV.nearestAvoid(M.set, M.layers, i, [...keys], 0); o.lines.push('       nearest passing, moment 1 ' + l.at + ' ' + S[l.at].uv + ': ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[l.at].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')); }
    const fi = L.findIndex(l => l.who === 'coqui'), fp = L[fi].px.filter(p => !p[2]);
    o.lines.push('       info, not a check: the frog at ' + L[fi].at + ' ' + [L[fi].sx, L[fi].sy] + ' draws rows ' + Math.min(...fp.map(p => p[1])) + ' to ' + Math.max(...fp.map(p => p[1])) + '; the patch is rows ' + Math.min(...[...keys].map(k => (k / G.W) | 0)) + ' to ' + Math.max(...[...keys].map(k => (k / G.W) | 0)));
  }

  // 10. towels-clear: the two towels on the rope are covered by nobody and by no frond (report), moments 5 and 6
  {
    const bad = [], lines = [], hints = [];
    for (const m of [5, 6]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const s of ['toallar', 'toallaa']) {
        const i = idxS(L, s), c = coverOf(L, M, i, null);
        lines.push('m' + m + ' ' + L[i].at + ' (' + (s === 'toallar' ? 'red' : 'blue') + ', box [' + S[L[i].at].box + ']): ' + c.tot + ' px, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + c.frond + ' under a frond, ' + (c.hid - c.frond) + ' behind the baked set (trunk)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ': the towel at ' + L[i].at + ' has ' + c.cov + ' px under a sprite, ' + c.frond + ' under a frond, ' + (c.hid - c.frond) + ' behind the baked set'); hints.push([m, i]); }
      }
    }
    const o = add('towels-clear', bad, 'the two towels on the rope are covered by nobody and by no frond in moments 5 and 6: ' + lines.join('; '), [bad.length + ' covered towel(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of hints) { const M = PV.moment[m], at = M.layers[i].at, r = await PV.nearest(M.set, M.layers, i); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[at].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 11. boats-clear: the two toy boats are covered by nobody (moments 3 and 4)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const s of ['botev', 'botew']) {
        const i = idxS(L, s), c = coverOf(L, M, i, null);
        lines.push('m' + m + ' ' + L[i].at + ': ' + c.tot + ' px, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + c.hid + ' hidden by the set');
        if (c.cov) { bad.push('moment ' + m + ': the toy boat at ' + L[i].at + ' has ' + c.cov + ' of its ' + c.tot + ' px under ' + whoTxt(c)); hints.push([m, i]); }
      }
    }
    const o = add('boats-clear', bad, 'the two toy boats on the wet sand are covered by nobody in moments 3 and 4: ' + lines.join('; '), [bad.length + ' covered boat(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of hints) { const M = PV.moment[m], at = M.layers[i].at, r = await PV.nearest(M.set, M.layers, i); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[at].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')); }
  }

  // 12. frog-torre2: the frog on torre2 is inside the picture (and the window) in moment 2
  {
    const L = PV.inspect[2].layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], xs = f.px.map(p => p[0]), ys = f.px.map(p => p[1]), bad = [];
    if (f.at !== 'torre2') bad.push('the frog of moment 2 is at ' + f.at + ', not torre2');
    if (f.out) bad.push('moment 2: ' + f.out + ' px of the frog on torre2 are outside the picture');
    if (Math.min(...xs) < x0 || Math.max(...xs) > x0 + 195) bad.push('moment 2: the frog on torre2 is outside the window: columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ', window ' + x0 + ' to ' + (x0 + 195));
    add('frog-torre2', bad, 'the frog on torre2 ' + [f.sx, f.sy] + ' is inside the picture and the window (drawn rows ' + Math.min(...ys) + ' to ' + Math.max(...ys) + ' of 0 to ' + (G.H - 1) + ', columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ' of the window ' + x0 + ' to ' + (x0 + 195) + ')', ['the frog on torre2:'].concat(bad.map(b => '  ' + b)));
  }

  // 13. blanket: abuela at manta_abuela and the frog at manta_coqui stand inside the blanket's box (their feet's spot; info: their sprite's feet row against its edges)
  {
    const B = E.BLANKET, bad = [], lines = [], inB = (u, v) => u >= B[0] && u <= B[2] && v >= B[1] && v <= B[3];
    for (const k of ['manta_abuela', 'manta_coqui']) {
      const s = S[k], [u, v] = s.uv, ok = inB(u, v), sc = scrUV(G, B[0], B[1], 0), ec = scrUV(G, B[2], B[3], 0), half = WIDTH[s.who] / 2;
      lines.push(k + ' (u ' + u + ', v ' + v + '): ' + (ok ? 'inside' : 'OUTSIDE') + ' the blanket u ' + B[0] + ' to ' + B[2] + ', v ' + B[1] + ' to ' + B[3] + ' (' + r2(u - B[0]) + ' from its left edge, ' + r2(B[2] - u) + ' from its right edge, ' + r2(v - B[1]) + ' from its back edge, ' + r2(B[3] - v) + ' from its front edge); its box (' + half * 2 + ' wide) is columns ' + (s.screen[0] - half) + ' to ' + (s.screen[0] + half - 1) + ' against the blanket\'s ' + sc[0] + ' to ' + ec[0]);
      if (!ok) bad.push(k + ' (u ' + u + ', v ' + v + ') is outside the blanket\'s box u ' + B[0] + ' to ' + B[2] + ', v ' + B[1] + ' to ' + B[3]);
    }
    add('blanket', bad, 'abuela at manta_abuela and the frog at manta_coqui stand inside the blanket\'s box [' + B + ']: ' + lines.join('; '), ['outside the blanket:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // info: the set's own fishing boat (bote = 1) against the sprite's box; the sprites that the set hides, by moment
  {
    const b = probes.boat, sb = S.bote.box, inb = b.box[0] >= sb[0] && b.box[1] >= sb[1] && b.box[0] + b.box[2] <= sb[0] + sb[2] && b.box[1] + b.box[3] <= sb[1] + sb[3];
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      lines.push('m' + m + ': ' + L.map((l, i) => { const c = coverOf(L, M, i, null); return l.at + (l.s ? ' (' + l.s + ')' : '') + ' ' + c.tot + ' px' + (c.hid ? ', ' + (c.hid - c.frond) + ' behind the set + ' + c.frond + ' under fronds' : '') + (c.cov ? ', ' + c.cov + ' under ' + Object.keys(c.who).join(', ') : '') + (c.out ? ', ' + c.out + ' outside' : ''); }).join('; '));
    }
    // the people the set hides (the spec does not ask for them whole, but a person behind a trunk is a finding): more than a tenth hidden by the set or a frond
    const hid = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers;
      for (const [i, l] of L.entries()) {
        if (!l.who || l.who === 'coqui') continue;
        const c = coverOf(L, planes(L), i, null);
        if (c.hid > c.tot / 10) {
          const M = PV.moment[m], r = await PV.nearest(M.set, M.layers, i, .1), at = l.at;
          hid.push('m' + m + ' ' + at + ' ' + S[at].uv + ': ' + c.hid + ' of its ' + c.tot + ' px hidden by the set (' + (c.hid - c.frond) + ' behind the baked set: the palm\'s trunk; ' + c.frond + ' under fronds at frame(0)); nearest with at most a tenth hidden: ' + vars.map((a, ai) => r.axis[a] ? a + ' ' + S[at].uv[ai] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '));
        }
      }
    }
    OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check. The set\'s own boat (bote = 1) is ' + b.n + ' px in the box [' + b.box + '], the sprite\'s box at BOAT [' + sb + '] (' + (inb ? 'the set\'s boat is inside it' : 'the set\'s boat is NOT inside it: its mast stands above the hull') + ')', ...(hid.length ? ['       people hidden by the set (more than a tenth of their sprite):', ...hid.map(h => '         ' + h)] : ['       no person has more than a tenth of his sprite hidden by the set']), ...lines.map(l => '       ' + l)] });
  }
  return OUTS;
}
