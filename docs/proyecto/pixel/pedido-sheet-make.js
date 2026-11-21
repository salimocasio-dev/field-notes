#!/usr/bin/env node
'use strict';
/* El pedido's sheet (place 8, La fonda, scene 2): writes docs/proyecto/pixel/pedido-sheet.json from pedido-set.html and the design (the orchestrator's p8-spec, general rules and section "pedido"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/pedido-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The wall's hatch, the shelf, the bell, the hook, the stool, the boards and their panels, the tables
   and the chairs' places are read from the set (window.PEDIDO.E: E.SEATS is what FD.setTable returned), never typed again from the design.
   It loads the set in headless Chrome (pedido-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (pedido-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with PEDIDO_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'pedido-sheet.json');
const BASE = process.env.PEDIDO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/pedido-set.html';
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

// the numbers of the design (p8-spec: the rules for every sheet, and "pedido")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, gato: 20 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const CHEST_ROWS = 30;                                   // "from the chest up": the top 30 rows of a grown-up's sprite (the head's 18 rows, then the torso down to its middle row 29: mkPersona tc = 18 + 11)
const SEAT_Z = .44, TABLE_Z = .74;                       // a chair's top; a table's top
const SZ = { plato: [14, 8], platito: [12, 8], bebida: [10, 14], vasito: [8, 18], platanos: [14, 18], cuadro: [14, 12] };
const MOMENTS = [1, 2, 3, 4, 5];
const HOOK_COLOUR = [60, 60, 70];                        // the set's hook (rgb(60, 60, 70) in the wall's paint and in the hook's box)
const SILKEY = { adulto: 'cocinero', adultoS: 'senorS', abuelaS: 'abuelaS', ninoS: 'luisS', coqui: 'coqui', gato: 'gato' };       // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a chair, a shelf, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  mesa_coqui: { to: [-1.1, 5.56, TABLE_Z], why: 'sprites-apart: the frog at the table\'s near edge was 10 px below the family\'s feet (silla1, silla2, 3 and 22 px across) and needs 12: v 5.45 -> 5.56 (+.11; the table\'s own near edge is v 5.6)' },
  borde: { to: [-1.5, 1.97, 0], why: 'panels-clear: the mesera at the hatch\'s edge covered 133 px of the drinks board\'s two lower panels (moment 3): v 1.2 -> 1.97 (+.77: her head clears the panels\' lowest row); u -1.5 -> -.75 would also clear them but puts her in front of the frog on the shelf' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed }
   kind: person (a character stands or sits there), place (the frog's), thing (a small thing: a plate, a drink, the plantains, a picture on a panel)
   sil: which drawing hangs there (adulto = a grown-up standing, adultoS = a grown-up sitting, abuelaS = abuela sitting, ninoS = a child sitting, coqui, gato) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle, centre = its middle
   on: the part of the set it stands on above the floor: pared (the wall: the shelf, the hook, a panel), mesas (a chair's top, a table's top)
   fixed: the set fixes its place (a chair), so it is never moved */
function defs(E) {
  const T = E.TABLE, N = E.NEXT, SH = E.SHELF.z, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const tv = r4(T.v + .45);
  // the family's chairs
  const SIT = [['abuelaS', 'adulto', 'abuela (87, 88), abuelo (89)'], ['adultoS', 'adulto', 'abuelo (87, 88), abuela (89)'], ['ninoS', 'nino', 'Luis'], ['ninoS', 'nino', 'Carmen (87, 88; nobody in 89)']];
  E.SEATS.forEach((p, i) => add('silla' + (i + 1), [r4(p[0]), r4(p[1]), SEAT_Z], 'person', SIT[i][0], SIT[i][1], 'chair ' + (i + 1) + ' of the family\'s long table, left to right (E.SEATS[' + i + ']: FD.setTable\'s place): on its top, z ' + SEAT_Z + '; ' + SIT[i][2] + '; whoever sits is hung by the lap', { on: 'mesas', fixed: true }));
  add('mesa_coqui', [-1.1, tv, TABLE_Z], 'place', 'coqui', 'coqui', 'the frog on the table\'s near edge (v ' + tv + ', the table\'s own near edge is v ' + r4(T.v + T.hd) + '): the table\'s top, z ' + TABLE_Z, { on: 'mesas' });
  // the shelf: z SHELF.z, v .25
  add('repisa_coqui', [-.2, .25, SH], 'place', 'coqui', 'coqui', 'the frog on the hatch\'s shelf, left of the bell (BELL u ' + E.BELL[0] + '): the shelf\'s top, z ' + SH, { on: 'pared' });
  [1.15, 1.75, 2.35].forEach((u, i) => add('repisa' + (i + 1), [u, .25, SH], 'thing', null, null, 'plate ' + (i + 1) + ' on the shelf (a ' + SZ.plato.join(' x ') + ' px stand-in): its bottom middle on the shelf\'s top, z ' + SH, { size: SZ.plato, anchor: 'bottom', on: 'pared' }));
  add('repisa_fin', [2.88, .25, SH], 'thing', null, null, 'the small plate (three golden rounds) or the frog\'s own plate, at the shelf\'s end (a ' + SZ.platito.join(' x ') + ' px stand-in): its bottom middle on the shelf\'s top, z ' + SH, { size: SZ.platito, anchor: 'bottom', on: 'pared' });
  // the people on the floor
  add('hueco', [1.0, -.4, 0], 'person', 'adulto', 'adulto', 'the cocinero in the kitchen, behind the wall (v -.4; the kitchen\'s back wall is v ' + E.KITCHEN + '): seen in the hatch from the chest up (the wall and the shelf hide the rest)');
  add('borde', [-1.5, 1.2, 0], 'person', 'adulto', 'adulto', 'the mesera at the hatch\'s left edge, in front of the wall (the hatch\'s left edge is u ' + E.HATCH[0] + ')');
  add('junto_mesa', [-2.4, r4(T.v + .4), 0], 'person', 'adulto', 'adulto', 'the mesera or the mesero at the family\'s table, left of its left end (the table runs from u ' + r4(T.u - T.hw) + ' to ' + r4(T.u + T.hw) + ')');
  add('lejos', [-1.6, 9.9, 0], 'person', 'adulto', 'adulto', 'the mesera across the room (a sprite is drawn from the front: it cannot show her back to the hatch)');
  // the tray on the table (89)
  [-.2, .35, .9].forEach((u, i) => add('bebida' + (i + 1), [u, tv, TABLE_Z], 'thing', null, null, 'drink ' + (i + 1) + ' of the tray (a ' + SZ.bebida.join(' x ') + ' px stand-in): its bottom middle on the table\'s top, z ' + TABLE_Z, { size: SZ.bebida, anchor: 'bottom', on: 'mesas' }));
  add('vasito', [1.5, tv, TABLE_Z], 'thing', null, null, 'the tall glass of juice (a ' + SZ.vasito.join(' x ') + ' px stand-in): its bottom middle on the table\'s top, z ' + TABLE_Z, { size: SZ.vasito, anchor: 'bottom', on: 'mesas' });
  // the next table
  E.NEXTSEATS.forEach((p, i) => add('otra_mesa' + (i + 1), [r4(p[0]), r4(p[1]), SEAT_Z], 'person', 'adultoS', 'adulto', 'guest ' + (i + 1) + ' of the next table (NEXT u ' + N.u + ', v ' + N.v + '): its chair (what FD.setTable returned for it: u NEXT.u ' + (i ? '+' : '-') + ' .45, v NEXT.v - .45 - .26, z ' + SEAT_Z + '): seen from the chest up (the table hides the rest)', { on: 'mesas', fixed: true }));
  // the hook and the cat
  add('platanos', [E.HOOK[0], .1, E.HOOK[1]], 'thing', null, null, 'the plantains hanging from the hook (a ' + SZ.platanos.join(' x ') + ' px stand-in): their top middle on the hook\'s point (u ' + E.HOOK[0] + ', z ' + E.HOOK[1] + ')', { size: SZ.platanos, anchor: 'top', on: 'pared', hook: 1 });
  add('banquito', [3.1, 1.6, 0], 'person', 'gato', 'gato', 'the cat on the floor by the stool (the stool is at u ' + E.STOOL[0] + ', v ' + E.STOOL[1] + ')');
  // the pictures on the boards' panels (the spec gives the panels, not spots for the pictures: cuadro1 to cuadro4 are the food board's, bcuadro1 to bcuadro4 the drinks board's)
  [['cuadro', 0, 'food'], ['bcuadro', 1, 'drinks']].forEach(([n, k, b]) => E.PANELS[k].forEach((p, i) => add(n + (i + 1), [r4((p[0] + p[1]) / 2), 0, r4((p[2] + p[3]) / 2)], 'thing', null, null, 'panel ' + (i + 1) + ' of the ' + b + ' board (top left, top right, bottom left, bottom right): a ' + SZ.cuadro.join(' x ') + ' px picture centred on the panel, on the wall (v 0)', { size: SZ.cuadro, anchor: 'centre', on: 'pared', panel: [k, i] })));
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on a chair, the table, the shelf, the hook,
   the panels are on what the set draws), things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (the head of
   everyone at a table covered by nobody and by nothing), cocinero-head, plates-clear, frog-shelf, panels-clear, drinks-clear, guests-chest.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(PEDIDO.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // a second copy of the set: the tables are drawn again with FD.setTable wrapped to keep what it returns (the chairs' places of every table: the set's own numbers, E.SEATS is the first),
  // then a lone chair is drawn at (0, 8) to read the depth of its seat's top (in the picture the table is in front of the chairs' seats: the set's pixel under a sitter's spot is the table's)
  const pp = await browser.newPage();
  pp.on('pageerror', e => errs.push(String(e)));
  await pp.route(BASE + '/**', serve);
  await pp.goto(PAGE + '?tags=1');
  G.tables = await pp.evaluate(() => {
    const calls = [], orig = FD.setTable; FD.setTable = (...a) => { const r = orig(...a); calls.push({ u: a[0], v: a[1], hw: a[2], opt: a[3], seats: r }); return r; };
    zb.fill(-1e9); pix.fill(0); part('mesas', tables); FD.setTable = orig;
    zb.fill(-1e9); pix.fill(0); part('probe', () => FD.chair(0, 8));
    const sx = Math.round(OX), sy = Math.round(OY + 8 * .5 * S - .44 * Math.sqrt(3) / 2 * S), d = 8 * Math.sqrt(3) / 2 + .44 * .5;
    const up = []; for (let dy = -2; dy <= 2; dy++) up.push([dy, zb[(sy + dy) * W + sx]]);
    return { calls, chair: { sx, sy, d, z: zb[sy * W + sx], around: up } };
  });
  G.E.NEXTSEATS = G.tables.calls[1].seats;
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs);
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

/* ---------- the preview's moments: pedido-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/pedido-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(k => window.PREVIEW.silhouette(k), v);
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  PV.nearestFree = (st, specs, idx, boxes) => p.evaluate(x => window.PREVIEW.nearestFree(x.st, x.specs, x.idx, x.boxes), { st, specs, idx, boxes });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle; a small thing: its box) takes: [first, last]
const colsOf = s => s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
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
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.hook) o.hook = 1;
    if (d.fixed) o.fixed = 1;
    if (d.panel) o.panel = d.panel;
    if (d.moved) { o.spec = W4(d.spec); o.moved = d.moved; }
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [87, 88, 89], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 87, 88 and 89: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
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
  for (const [n, k, b] of [['cuadro', 0, 'food'], ['bcuadro', 1, 'drinks']]) for (let i = 0; i < 4; i++) { const p = E.PANELS[k][i]; things[n + (i + 1)] = await setThing(r4(p[0]), 0, r4(p[2]), r4(p[1]), 0, r4(p[3]), 'panel ' + (i + 1) + ' of the ' + b + ' board (top left, top right, bottom left, bottom right; PANELS[' + k + '][' + i + ']): u ' + r4(p[0]) + ' to ' + r4(p[1]) + ', z ' + r4(p[2]) + ' to ' + r4(p[3]) + ', on the wall (v 0); a poke' + (k ? ' (not named in the spec: the spec names only the food board\'s four as cuadro1 to cuadro4)' : '')); }
  const B2 = E.BOARDS[1];
  things.bebidas = await setThing(B2[0], 0, B2[2], B2[1], 0, B2[3], 'the drinks board: its whole face, u ' + B2[0] + ' to ' + B2[1] + ', z ' + B2[2] + ' to ' + B2[3] + ', on the wall (v 0); a poke');
  things.campana = await setThing(r4(E.BELL[0] - .1), r4(E.BELL[1] - .1), E.SHELF.z, r4(E.BELL[0] + .1), r4(E.BELL[1] + .1), r4(E.SHELF.z + .2), 'the bell on the shelf (BELL u ' + E.BELL[0] + ', v ' + E.BELL[1] + ': a sphere of radius .1 on a drum, z ' + E.SHELF.z + ' to ' + r4(E.SHELF.z + .2) + '); not in the spec\'s things: made for the check that the frog on the shelf does not cover it');
  const touch = { plato1: 'repisa1', plato2: 'repisa2', plato3: 'repisa3', bebida1: 'bebida1', bebida2: 'bebida2', bebida3: 'bebida3', platito: 'repisa_fin', vasito: 'vasito', platanos: 'platanos', gato: 'banquito' };
  for (const k of Object.keys(touch)) things[k] = 'sprite';
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'mesera', 'mesero', 'cocinero', 'coqui']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'pedido',
    made: 'node docs/proyecto/pixel/pedido-sheet-make.js, from pedido-set.html (window.PEDIDO.E, E.SEATS and E.PANELS) and the design of El pedido (the orchestrator\'s p8-spec, general rules and section pedido). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. The family\'s chairs are E.SEATS (FD.setTable\'s places): ' + E.SEATS.map((p, i) => 'silla' + (i + 1) + ' (' + r4(p[0]) + ', ' + r4(p[1]) + ')').join(', '),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + SEAT_Z + ': a chair\'s top; z ' + TABLE_Z + ': the table\'s top; z ' + E.SHELF.z + ': the hatch\'s shelf) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): a plate, a drink, the tall glass and the small plate have their bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]); the plantains hang with their top middle on the hook\'s point (the box [sx - 7, sy, 14, 18]); a picture on a panel is centred on the panel\'s middle (the box [sx - 7, sy - 6, 14, 12]; a panel is about 13 x 10 px, so a picture overlaps its frame by a pixel or two). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the chair; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy); the cat (El camino\'s mkGato sitting, 26 x 20): column 12 and its bottom edge; a small thing: see spot. Nobody is drawn turned: whoever sits at the table or stands behind the wall faces us',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      cocinero: 'the cocinero\'s spot hueco is behind the wall (v -.4, the kitchen\'s back wall is v ' + E.KITCHEN + '): the wall, the shelf and the table hide him below the hatch\'s sill, and the hatch\'s hole (u ' + E.HATCH[0] + ' to ' + E.HATCH[1] + ', z ' + E.HATCH[2] + ' to ' + E.HATCH[3] + ') shows him from the chest up',
    },
    setKey: {
      params: { hora: { values: ['noche'], note: 'the one state: the lamps are lit; no other state is used by stories 87 to 89' } },
      key: 'hora, e.g. "noche"',
      baked: ['?hora=noche'],
    },
    things,
    spots,
    groups: {
      sillas: ['silla1', 'silla2', 'silla3', 'silla4'], repisa: ['repisa1', 'repisa2', 'repisa3', 'repisa_fin'], bebidas: ['bebida1', 'bebida2', 'bebida3', 'vasito'], otra_mesa: ['otra_mesa1', 'otra_mesa2'],
      cuadros: ['cuadro1', 'cuadro2', 'cuadro3', 'cuadro4'], bcuadros: ['bcuadro1', 'bcuadro2', 'bcuadro3', 'bcuadro4'],
      touch: Object.assign({}, touch, { abuela: 'silla1', abuelo: 'silla2', luis: 'silla3', carmen: 'silla4', coqui: 'mesa_coqui', cocinero: 'hueco' }),
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p8-spec, "pedido"), given in (u, v, z); the chairs, the shelf, the bell, the hook, the stool, the panels and the next table are read from the set',
      'things: cuadro1 to cuadro4 are the food board\'s four panels (PANELS[0]); bebidas is the drinks board\'s box; plato1 to plato3, bebida1 to bebida3, platito, vasito, platanos and gato are sprites at the spots groups.touch names; the people are sprites. NOT IN THE SPEC, made for the checks and the preview: bcuadro1 to bcuadro4 (the drinks board\'s four panels, as set things and as the spots of the pictures moment 5 puts on them), cuadro1 to cuadro4 as the spots of the food board\'s pictures, and campana (the bell\'s box)',
      'whoever sits (silla1 to silla4, otra_mesa1, otra_mesa2) is hung by the lap on the chair\'s top; silla1 and silla2 are abuela and abuelo in stories 87 and 88, abuelo and abuela in 89 (silla4 is empty in 89); a spot\'s sprite is the one of the first of those',
      'the spec gives no radius for the cat\'s shadow: ' + 0.2 + ' used (open point); the others are El cruce\'s (frog .45, grown-ups .35, children .28)',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the table hides the lap and legs of whoever sits behind it, the wall and the shelf hide the cocinero below the hatch\'s sill, the next table hides its guests from the waist down.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El cruce\'s sheet: the upright plane through the feet (a picture on a panel is the plane through its middle, on the wall)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, gato: .2 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, mesera: .35, mesero: .35, cocinero: .35, luis: .28, carmen: .28, gato: .2 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) and .2 for the cat (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name).concat(['hueco']),
      onSeat: 'whoever sits on a chair, stands on the table or on the shelf (z above 0) casts none: none of those is floor (a shadow cast at the floor under them would show in front of them); the cocinero (hueco) casts none: the kitchen\'s floor is behind the wall',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part)
  const spotsPx = await page.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
        const X = s.screen[0] + dx, Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, c = bakedPix[i];
        rows.push({ dx, dy, tag: TAGS[i], z: DEPTH.z[i], rgb: [c & 255, c >> 8 & 255, c >> 16 & 255] });
      }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
  return { spotsPx };
}

function checks(sheet, G, probes, PV) { return checksAsync(sheet, G, probes, PV); }
async function checksAsync(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, SIL = PV.sil;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, cov = 0; const who = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2]) { hid++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].at; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  // the shown pixels of layer i inside a box
  const shownIn = (L, i, box) => L[i].px.filter(p => !p[2] && inside(box, p[0], p[1])).length;
  const idxAt = (L, at) => L.findIndex(l => l.at === at);
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, the cat 20; and his rows from the drawn silhouette; a small thing's box)
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
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + s.box + ']') + ' is cut ' + (cut.concat([picL && 'by the picture\'s left edge ' + picL, picR && 'by the picture\'s right edge ' + picR].filter(Boolean))).join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k];
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = Object.assign({}, s, { screen: [sx, s.screen[1]] }); if (s.box) t.box = [s.box[0] + sx - s.screen[0], s.box[1], s.box[2], s.box[3]]; if (!cutAt(t, x0) && colsOf(t)[0] >= 0 && colsOf(t)[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const left = Object.entries(S).sort((p, q) => colsOf(p[1])[0] - colsOf(q[1])[0])[0], right = Object.entries(S).sort((p, q) => colsOf(q[1])[1] - colsOf(p[1])[1])[0];
    add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + colsOf(left[1])[0] + ' (' + left[0] + '), the rightmost ' + colsOf(right[1])[1] + ' (' + right[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
  }

  // 3. the spots above the floor are on what the set draws: a chair's top and the table's top (part mesas), the shelf's top (part pared), the panels (part pared, inside the panel's box),
  //    the plantains' hook (a dark pixel of the hook's colour within 1 px of the spot)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx, near = (k, f) => (px[k] || []).filter(f);
    // the chairs: the spot is the chair's own place (E.SEATS, and what FD.setTable returned for the next table) and the chair drawn alone has its seat's top at the spot's depth; in the picture the table is in front of every
    // chair's seat (the set's pixel under a sitter's spot is the table's), so the pixel under the spot cannot be asked
    const ch = G.tables.chair, chairOk = Math.abs(ch.z - ch.d) < .1, seatsOk = E.SEATS.every((p, i) => S['silla' + (i + 1)].uv[0] === r4(p[0]) && S['silla' + (i + 1)].uv[1] === r4(p[1])) && G.tables.calls[0].seats.every((p, i) => p[0] === E.SEATS[i][0] && p[1] === E.SEATS[i][1]);
    const chairs = Object.entries(S).filter(([, s]) => s.fixed && s.on === 'mesas');
    if (!chairOk) bad.push('a chair drawn alone at (0, 8): its seat\'s top at row ' + ch.sy + ' has depth ' + r2(ch.z) + ', not ' + r2(ch.d) + ' (z ' + SEAT_Z + ')');
    if (!seatsOk) bad.push('silla1 to silla4 are not E.SEATS (the first table FD.setTable drew)');
    for (const [k, s] of chairs) { const best = (px[k] || []).find(r => r.dx === 0 && r.dy === 0); lines.push(k + ' z ' + s.uv[2] + ': the chair\'s own place (' + (k.startsWith('silla') ? 'E.SEATS' : 'FD.setTable\'s return for the next table') + '); drawn alone its seat\'s top is at depth ' + r2(ch.z) + ' against the ' + r2(ch.d) + ' of a spot at z ' + SEAT_Z + '; in the picture the table hides it (the pixel under the spot is part ' + (best ? best.tag + ' at depth ' + r2(best.z) : 'none') + ', the table\'s)'); surf.push(k); }
    for (const [k, s] of Object.entries(S)) {
      if (s.hook || s.panel || s.fixed || !s.on || s.on === 'ground') continue;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const panelsOk = [];
    for (const [k, s] of Object.entries(S)) {
      if (!s.panel) continue;
      const th = T[k], r = (px[k] || []).find(r => r.dx === 0 && r.dy === 0), inBox = inside(th.box, s.screen[0], s.screen[1]), ok = r && r.tag === 'pared' && Math.abs(r.z - s.depth) < .1 && inBox;
      panelsOk.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ': the pixel under the picture\'s middle is ' + (r ? 'part ' + r.tag + ' at depth ' + r2(r.z) + ' (the spot\'s ' + r2(s.depth) + ')' : 'none') + ', and the panel\'s box is [' + th.box + ']' + (inBox ? '' : ': the spot is outside it'));
    }
    const hooks = Object.entries(S).filter(([, s]) => s.hook), missed = []; let farthest = 0;
    for (const [k, s] of hooks) {
      const d = near(k, r => Math.abs(r.rgb[0] - HOOK_COLOUR[0]) <= 14 && Math.abs(r.rgb[1] - HOOK_COLOUR[1]) <= 14 && Math.abs(r.rgb[2] - HOOK_COLOUR[2]) <= 14).map(r => Math.max(Math.abs(r.dx), Math.abs(r.dy))).sort((a, b) => a - b)[0];
      if (d === undefined || d > 1) missed.push(k + ' ' + s.screen + (d === undefined ? ': no pixel of the hook\'s colour within 2 px' : ': the hook\'s pixel is ' + d + ' px away')); else farthest = Math.max(farthest, d);
    }
    for (const m of missed) bad.push('hook ' + m);
    const o = add('spots-on-surface', bad, surf.length + ' spots on a chair, the table or the shelf (' + surf.join(', ') + ') are on a surface the set draws (the chairs\' tops z ' + SEAT_Z + ': the chairs\' own places, the chair drawn alone has its seat\'s top at the spot\'s depth; the table\'s top z ' + TABLE_Z + ' part mesas, the shelf\'s top z ' + E.SHELF.z + ' part pared: depth within .1 of the spot\'s); the ' + panelsOk.length + ' picture spots are on their panel (part pared, inside its box); the plantains\' spot has a pixel of the set\'s hook within ' + farthest + ' px', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
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
    add('things-in-view', bad, 'the boxes of cuadro1 to cuadro4, bcuadro1 to bcuadro4, bebidas and campana are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the cat 20; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
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
      const s = S[name]; if (s.fixed) return 'fixed by the set (a chair): not moved';
      const res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 5 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 5 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    // two chairs of the set that are too close: the spots are never moved; say what gap the set would need (the chairs' middle kept)
    const seenPair = new Set();
    for (const h of hints) {
      const a = S[h.a.at], b = S[h.b.at]; if (!(a.fixed && b.fixed) || seenPair.has(h.a.at + h.b.at)) continue; seenPair.add(h.a.at + h.b.at);
      const mid = (a.uv[0] + b.uv[0]) / 2, gap = Math.abs(a.uv[0] - b.uv[0]); let need = null;
      for (let g = gap; g <= gap + 1 && need === null; g = r4(g + .001)) if (Math.abs(scrUV(G, mid + g / 2, a.uv[1], a.uv[2])[0] - scrUV(G, mid - g / 2, a.uv[1], a.uv[2])[0]) >= h.half) need = g;
      o.lines.push('       OPEN POINT (a set number, not a spot of the spec): ' + h.a.at + ' and ' + h.b.at + ' are the next table\'s two chairs, ' + r2(gap * G.S) + ' px apart in u (' + r4(gap) + ' u, FD.setTable span in pedido-set.html\'s tables()), ' + Math.abs(a.screen[0] - b.screen[0]) + ' px after rounding; they would be ' + h.half + ' px apart or more with the chairs ' + need + ' u apart (span ' + need + ') about the same middle (u ' + r4(mid) + ')');
    }
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 5 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. heads-clear: everyone who sits at a table (the family at the long table, the guests at the next one) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'mesa' && l.group !== 'otra') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'every person at a table (' + MOMENTS.map(m => 'm' + m + ': ' + PV.inspect[m].layers.filter(l => l.group === 'mesa' || l.group === 'otra').map(l => l.at).join(', ')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people at the tables:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. cocinero-head: the cocinero at hueco: his head (the top 14 rows) is inside the hatch's hole on the picture (every px shown, none hidden by the wall, the frame or the shelf), and no plate and not the frog covers it
  {
    const bad = [], lines = [], H = E.HATCH, hx0 = G.OX + H[0] * G.S, hx1 = G.OX + H[1] * G.S, hy0 = G.OY - H[3] * 22.5, hy1 = G.OY - H[2] * 22.5;     // the hole's screen rectangle: the wall at v 0
    const hole = [hx0, hy0, hx1, hy1].map(r2);
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, i = idxAt(L, 'hueco'); if (i < 0) continue;
      const M = planes(L), l = L[i], top = Math.min(...l.px.map(p => p[1])), head = l.px.filter(p => p[1] < top + HEAD_ROWS);
      const outside = head.filter(p => !(p[0] + .5 > hx0 && p[0] + .5 < hx1 && p[1] + .5 > hy0 && p[1] + .5 < hy1)), hid = head.filter(p => p[2]);
      const c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
      const rows = []; for (let y = top; y <= Math.max(...l.px.map(p => p[1])); y++) if (!l.px.some(p => p[1] === y && !p[2]) && l.px.some(p => p[1] === y)) { rows.push(y - top); break; }
      lines.push('m' + m + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ' (columns ' + Math.min(...head.map(p => p[0])) + ' to ' + Math.max(...head.map(p => p[0])) + '): ' + outside.length + ' px outside the hole, ' + hid.length + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + '; he is seen down to sprite row ' + (rows.length ? rows[0] - 1 : 'the last') + ' (the sill hides the rest)');
      if (outside.length || hid.length || c.cov) bad.push('moment ' + m + ': the cocinero\'s head: ' + outside.length + ' px outside the hatch\'s hole [x ' + hole[0] + ' to ' + hole[2] + ', y ' + hole[1] + ' to ' + hole[3] + '], ' + hid.length + ' hidden by the set, ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
    }
    add('cocinero-head', bad, 'the cocinero at hueco ' + S.hueco.screen + ': in every moment he is in (m1 to m4) his head (the top ' + HEAD_ROWS + ' rows) is inside the hatch\'s hole (x ' + hole[0] + ' to ' + hole[2] + ', y ' + hole[1] + ' to ' + hole[3] + '), none of it hidden by the set, no plate and not the frog covers it: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 9. plates-clear: the plates at repisa1 to repisa3 and the small plate (or the frog's plate) at repisa_fin are covered by nobody (not the frog, not the cat, not the set) and stand on the shelf's top (spots-on-surface: part pared at the shelf's depth)
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'plato') continue;
        const c = coverOf(L, M, i, null), shelf = S[l.at].uv[2] === E.SHELF.z && S[l.at].on === 'pared' && surf.includes(l.at);
        lines.push('m' + m + ' ' + l.at + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; on the shelf\'s top ' + (shelf ? 'yes' : 'NO'));
        if (c.cov || c.hid || c.out || !shelf) bad.push('moment ' + m + ' ' + l.at + ' ' + S[l.at].screen + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture' + (shelf ? '' : '; not on the shelf\'s top'));
      }
    }
    add('plates-clear', bad, 'the plates at repisa1 to repisa3 (m2, m3) and the small plate or the frog\'s plate at repisa_fin (m1 to m4) are covered by nobody and stand on the shelf\'s top: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 10. frog-shelf: the frog at repisa_coqui stands on the shelf's top (spots-on-surface) and covers neither the bell (its box) nor a plate (no plate pixel under a nearer frog pixel)
  {
    const bad = [], lines = [], hints = [], bell = T.campana.box;
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, i = idxAt(L, 'repisa_coqui'); if (i < 0) continue;
      const M = planes(L), f = L[i], shown = f.px.filter(p => !p[2]), n = shownIn(L, i, bell), right = Math.max(...shown.map(p => p[0]));
      const plates = L.map((l, j) => [l, j]).filter(([l]) => l.group === 'plato').map(([l, j]) => ({ at: l.at, c: coverOf(L, M, j, [i]), left: Math.min(...l.px.map(p => p[0])) }));
      lines.push('m' + m + ': the frog\'s rightmost column ' + right + ', the bell\'s box [' + bell + '] (left column ' + bell[0] + '): ' + n + ' px of his on it; plates covered by him: ' + (plates.map(p => p.at + ' ' + p.c.cov).join(', ') || 'no plates') + (plates.length ? ' (the nearest plate\'s left column ' + Math.min(...plates.map(p => p.left)) + ')' : '') + '; on the shelf\'s top ' + (surf.includes('repisa_coqui') ? 'yes' : 'NO'));
      if (n) { bad.push('moment ' + m + ': the frog at repisa_coqui ' + [f.sx, f.sy] + ' covers ' + n + ' px of the bell\'s box [' + bell + ']'); }
      for (const p of plates) if (p.c.cov) { bad.push('moment ' + m + ': the frog covers ' + p.c.cov + ' px of the plate at ' + p.at); }
      if (n) hints.push([m, i]);
    }
    if (!surf.includes('repisa_coqui')) bad.push('the frog at repisa_coqui is not on the shelf\'s top');
    const o = add('frog-shelf', bad, 'the frog at repisa_coqui ' + S.repisa_coqui.screen + ' stands on the shelf\'s top and covers neither the bell nor a plate: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of hints) { const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, [bell]); o.lines.push('       nearest passing, moment ' + m + ' repisa_coqui ' + S.repisa_coqui.uv + ': ' + axisTxt(r, 'repisa_coqui')); }
  }

  // 11. panels-clear: the eight panels (the food board's cuadro1 to cuadro4, the drinks board's) are covered by nobody in any moment: no shown pixel of a person or a thing (the pictures on them excepted) lies in a panel's box
  {
    const bad = [], lines = [], hints = [], boxes = []; for (const n of ['cuadro', 'bcuadro']) for (let i = 1; i <= 4; i++) boxes.push([n + i, T[n + i].box]);
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, hits = [];
      for (const [i, l] of L.entries()) { if (l.group === 'cuadro') continue; for (const [n, b] of boxes) { const c = shownIn(L, i, b); if (c) hits.push([n, l.at, c, i]); } }
      const pics = L.filter(l => l.group === 'cuadro').length;
      lines.push('m' + m + ': ' + pics + ' picture(s) on the panels; ' + (hits.length ? hits.map(h => h[1] + ' covers ' + h[0] + ' ' + h[2] + ' px').join(', ') : '0 px of the eight panels covered by anyone'));
      for (const h of hits) { bad.push('moment ' + m + ': ' + h[1] + ' ' + S[h[1]].screen + ' covers ' + h[2] + ' px of panel ' + h[0] + ' [' + T[h[0]].box + ']'); hints.push([m, h[3], h[1]]); }
    }
    const seen = new Set(), o = add('panels-clear', bad, 'the eight panels are covered by nobody in any of the 5 moments (the pictures on them excepted): ' + lines.join('; '), [bad.length + ' covering(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { if (seen.has(m + at)) continue; seen.add(m + at); const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, boxes.map(b => b[1])); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + axisTxt(r, at)); }
  }

  // 12. drinks-clear (moment 5): the three drinks and the tall glass are covered by nobody and cover no head (the top 14 rows of anyone who sits)
  {
    const bad = [], lines = [], m = 5, L = PV.inspect[m].layers, M = planes(L), dr = L.map((l, i) => [l, i]).filter(([l]) => l.group === 'bebida').map(([, i]) => i);
    for (const i of dr) { const c = coverOf(L, M, i, null); lines.push(L[i].at + ' ' + L[i].sx + ',' + L[i].sy + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); if (c.cov || c.hid || c.out) bad.push('moment 5 ' + L[i].at + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); }
    for (const [j, l] of L.entries()) {
      if (l.group !== 'mesa') continue;
      const c = coverOf(L, M, j, dr, [0, HEAD_ROWS]);
      lines.push(l.at + '\'s head: ' + c.cov + ' px covered by a drink'); if (c.cov) bad.push('moment 5: the drinks cover ' + c.cov + ' px of the head of ' + l.at + ' (' + whoTxt(c) + ')');
    }
    add('drinks-clear', bad, 'in moment 5 the three drinks and the tall glass (bebida1 to bebida3, vasito) are covered by nobody and cover no head: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 13. guests-chest: the guests at otra_mesa1, otra_mesa2 are whole from the chest up (the top 30 rows of the sprite shown: the table hides the rest) and inside the window
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'otra') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, CHEST_ROWS]), top = c.top;
        const seenRows = (() => { let n = 0; for (let y = top; ; y++) { if (!l.px.some(p => p[1] === y)) break; if (l.px.some(p => p[1] === y && !p[2] && !(M.get(key(p[0], p[1])) || []).some(q => q.i !== i && q.plane > p[3] + EPS))) n++; else break; } return n; })();
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): chest rows ' + top + ' to ' + (top + CHEST_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px; he is seen whole down to sprite row ' + (seenRows - 1) + ' (the table hides the rest)');
        if (c.cov || c.hid || cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': from the chest up (the top ' + CHEST_ROWS + ' rows) ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' outside the picture');
      }
    }
    add('guests-chest', bad, 'the guests at otra_mesa1, otra_mesa2 (m2, m3, m4) are whole from the chest up (the top ' + CHEST_ROWS + ' rows of the sprite) and inside the window: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // info: the things he can touch that the spec lists no check for (the plantains, the cat, the drinks board), and the standing people and the plates over the cocinero: not checks of the spec
  {
    const lines = [], bb = T.bebidas.box;
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const at of ['platanos', 'banquito']) { const i = idxAt(L, at); if (i >= 0) { const c = coverOf(L, M, i, null); parts.push(at + ' ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); } }
      let drinks = 0; for (const [i] of L.entries()) if (L[i].group !== 'cuadro') drinks += shownIn(L, i, bb);
      parts.push('bebidas [' + bb + '] ' + drinks + ' px under anyone');
      lines.push('m' + m + ': ' + parts.join(', '));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
