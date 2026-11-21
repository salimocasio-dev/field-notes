#!/usr/bin/env node
'use strict';
/* La noche's sheet (place 9, La casa, un día entero, scene 4): writes docs/proyecto/pixel/noche-sheet.json from noche-set.html and the design (the orchestrator's p9-spec, general rules and section "noche"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/noche-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The arch, the bed, the lamps, the window, the clock, the sideboard, the sofa, the armchair, the television, the table and
   the chairs' places are read from the set (window.NOCHE.E: E.SEATS is what FD.setTable returned), never typed again from the design.
   It loads the set in headless Chrome (noche-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (noche-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with NOCHE_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'noche-sheet.json');
const BASE = process.env.NOCHE_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/noche-set.html';
const SETQ = 'mesa=1&luz1=1&luz2=1&luz3=1';              // the set the make reads its numbers from: the table laid (E.SEATS), the lamps lit
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

// the numbers of the design (p9-spec: the rules for every sheet, and "noche")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = .44, TABLE_Z = .74, ARM_Z = .72, BED_Z = .6;     // a chair's, an armchair's and a sofa's seat; the dinner table's top; the sofa's right arm's top; the head's place on the pillow
const SZ = { jugo: [10, 10], flan: [10, 10], queso: [10, 10], frutas: [10, 10], vela: [6, 14] };
const MOMENTS = [1, 2, 3, 4, 5, 6, 7];
const SILKEY = { adulto: 'abuelo', adultoS: 'abueloS', abuelaS: 'abuelaS', ninoS: 'luisS', nino: 'luis', coqui: 'coqui', perro: 'perro', lying: 'lying:luis' };       // which preview sprite draws each silhouette name (a standing child is the tallest child the rug holds)
const BED_COLOUR = [236, 190, 110];                      // the colour noche-set.html passes to CS.bed (its backWall): the blanket's colour (the set keeps it inline, E does not hold it)

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a shelf, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  ensalada: { to: [.3, 1.03, 0], why: 'sprites-apart: in moment 4 abuela at the sideboard\'s end was 8 px above the children on the sofa\'s seats (sofa2 and sofa3, 17 and 8 px across) and needs 12: v 1.3 -> 1.03 (-.27; the seats are fixed by the set)' },
  mesa_coqui: { to: [1.0, 6.25, TABLE_Z], why: 'sprites-apart: in moment 5 the frog at the table\'s near edge was 10 px below the family\'s feet (silla1, silla2: 10 and 12 px across) and needs 12: v 6.15 -> 6.25 (+.10; the table\'s own near edge is v 6.3)' },
  cama1: { to: [-3.32, -2.5, BED_Z], why: 'sprites-apart: in moment 7 the two children in the bed were 13 px apart sideways on the same row: both go to the pillow\'s ends, 24 px apart (u -3.11 -> -3.32)' },
  cama2: { to: [-2.40, -2.5, BED_Z], why: 'sprites-apart: as cama1 (u -2.61 -> -2.40)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed, lying }
   kind: person (a character stands, sits or lies there), place (the frog's), thing (a small thing: the juice, the flan, the cheese, the fruit, the candle)
   sil: which drawing hangs there (adulto = a grown-up standing, adultoS = a grown-up sitting, abuelaS = abuela sitting, ninoS = a child sitting, nino = a child standing or sitting on the floor, perro = Canelo,
        lying = whoever lies in the bed: the standing sprite hung from the head with a blanket over it, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle on the point, centre = its middle
   on: the part of the set it stands on above the floor: sala (a seat, the sofa's arm, the sideboard's top, the table's top), pared (the wall: the window's sill, the bed)
   fixed: the set fixes its place (a chair), so it is never moved */
function defs(E) {
  const S = E.SOFA, A = E.ARMCHAIR, T = E.TABLE, SB = E.SIDEBOARD, B = E.BED, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  // the sofa's three seats, the armchair, the arm
  [[-1.3, 'abuelo (105, 107)'], [-.35, 'Luis (106)'], [.6, 'Carmen (106)']].forEach(([u, who], i) => add('sofa' + (i + 1), [u, S.v, SEAT_Z], 'person', i ? 'ninoS' : 'adultoS', i ? 'nino' : 'adulto', 'the sofa\'s seat ' + (i + 1) + ' of 3 (SOFA u ' + S.u + ', v ' + S.v + ': seats at u -1.3, -.35, .6): on its top, z ' + SEAT_Z + '; ' + who + '; whoever sits is hung by the lap', { on: 'sala', fixed: true }));
  add('butaca', [A[0], A[1], SEAT_Z], 'person', 'abuelaS', 'adulto', 'the armchair\'s seat (ARMCHAIR u ' + A[0] + ', v ' + A[1] + '): on its top, z ' + SEAT_Z + '; abuela (105, 107); she is hung by the lap', { on: 'sala', fixed: true });
  add('brazo_coqui', [r4(S.u + S.hw + .1), r4(S.v - .02), ARM_Z], 'place', 'coqui', 'coqui', 'the frog on the sofa\'s right arm (u SOFA.u + SOFA.hw + .1 = ' + r4(S.u + S.hw + .1) + ', v SOFA.v - .02 = ' + r4(S.v - .02) + '): the arm\'s top, z ' + ARM_Z, { on: 'sala' });
  // the rug, the window
  add('alfombra1', [-1.4, 4.1, 0], 'person', 'nino', 'nino', 'a child on the rug, on the left (Luis): sitting on the floor (105) or standing (107): the feet on the spot', {});
  add('alfombra2', [-.3, 4.1, 0], 'person', 'nino', 'nino', 'a child on the rug, on the right (Carmen): sitting on the floor (105) or standing (107): the feet on the spot', {});
  add('ventana_abuelo', [-.65, 1.0, 0], 'person', 'adulto', 'adulto', 'abuelo by the window (107, the start): standing, in front of the wall (the window is u ' + E.WINDOW[0] + ' to ' + E.WINDOW[1] + ')', {});
  add('ventana_coqui', [-.65, .06, E.WINDOW[2]], 'place', 'coqui', 'coqui', 'the frog on the window\'s sill (the window\'s bottom edge, z ' + E.WINDOW[2] + ', v .06, just in front of the wall)', { on: 'pared' });
  // story 106: the dinner table (mesa 1), the sideboard
  E.SEATS.forEach((p, i) => add('silla' + (i + 1), [r4(p[0]), r4(p[1]), SEAT_Z], 'person', ['abuelaS', 'ninoS', 'ninoS', 'adultoS'][i], ['adulto', 'nino', 'nino', 'adulto'][i], 'chair ' + (i + 1) + ' of the table\'s four along its far side, left to right (E.SEATS[' + i + ']: FD.setTable\'s place): on its top, z ' + SEAT_Z + '; ' + ['abuela', 'Luis', 'Carmen', 'abuelo (silla4 also in 106 opening and game)'][i] + ' (106 ending); whoever sits is hung by the lap', { on: 'sala', fixed: true, chair: true }));
  add('junto_mesa', [-.35, r4(T.v + .3), 0], 'person', 'adulto', 'adulto', 'abuela beside the table, at its left end (v TABLE.v + .3 = ' + r4(T.v + .3) + '; the table runs from u ' + r4(T.u - T.hw) + ' to ' + r4(T.u + T.hw) + ')', {});
  add('ensalada', [.3, 1.3, 0], 'person', 'adulto', 'adulto', 'abuela at the sideboard\'s end, her bowl of salad (the sideboard runs from u ' + r4(SB.u - SB.hw) + ' to ' + r4(SB.u + SB.hw) + ')', {});
  add('aparador_coqui', [1.55, SB.v, SB.h], 'place', 'coqui', 'coqui', 'the frog on the sideboard (v SIDEBOARD.v = ' + SB.v + '): its top, z ' + SB.h, { on: 'sala' });
  [['jugo', 2.35, 'the jug of juice'], ['flan', 2.7, 'the flan'], ['queso', 3.0, 'the plate of cheese'], ['frutas', 3.3, 'the bowl of fruit']].forEach(([n, u, w]) => add(n, [u, SB.v, SB.h], 'thing', null, null, w + ' on the sideboard\'s top (v SIDEBOARD.v = ' + SB.v + ': the spec gives u only; a ' + SZ[n].join(' x ') + ' px stand-in): its bottom middle on the top, z ' + SB.h, { size: SZ[n], anchor: 'bottom', on: 'sala' }));
  add('vela', [T.u, r4(T.v - .1), TABLE_Z], 'thing', null, null, 'the tall candle on the table (TABLE.u, TABLE.v - .1; a ' + SZ.vela.join(' x ') + ' px stand-in): its bottom middle on the table\'s top, z ' + TABLE_Z, { size: SZ.vela, anchor: 'bottom', on: 'sala' });
  add('mesa_coqui', [1.0, r4(T.v + .45), TABLE_Z], 'place', 'coqui', 'coqui', 'the frog on the table\'s near edge (v TABLE.v + .45 = ' + r4(T.v + .45) + ', the table\'s own near edge is v ' + r4(T.v + T.hd) + '): the table\'s top, z ' + TABLE_Z, { on: 'sala' });
  add('perro', [2.75, 2.1, 0], 'person', 'perro', 'perro', 'Canelo at his bowl (the bowl is u ' + E.BOWL[0] + ', v ' + E.BOWL[1] + ')', {});
  // story 107: the bed seen through the arch
  add('cama1', [r4(B.u - .25), r4(B.v0 + .3), BED_Z], 'person', 'lying', 'nino', 'the head\'s place of a child lying in the bed seen through the arch (BED.u - .25, BED.v0 + .3; the pillow\'s top is z ' + BED_Z + '): the standing sprite hangs DOWN the bed from it (its top middle on the spot), a blanket over it from the chest to the bed\'s foot; Luis', { on: 'pared', lying: true, anchor: 'top' });
  add('cama2', [r4(B.u + .25), r4(B.v0 + .3), BED_Z], 'person', 'lying', 'nino', 'the head\'s place of the other child in the bed (BED.u + .25, BED.v0 + .3): as cama1; Carmen', { on: 'pared', lying: true, anchor: 'top' });
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on a seat, the arm, the sideboard, the table, the sill, the bed are on what the set draws),
   things-in-view (the set things' boxes), sprites-apart (the people of a moment), seats-apart (the set's own chairs), frog-seen (the frog whole in every moment), heads-clear (the head of everyone who sits or lies covered by nobody and by nothing),
   lamps-tv-clear, sideboard-clear, bed-heads, frog-arm, frog-sideboard, frog-sill.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1&' + SETQ);
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(NOCHE.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // a second copy of the set: a lone chair is drawn at (0, 8) to read the depth of its seat's top (in the picture the table is in front of the chairs' seats: the set's pixel under a sitter's spot is the table's)
  const pp = await browser.newPage();
  pp.on('pageerror', e => errs.push(String(e)));
  await pp.route(BASE + '/**', serve);
  await pp.goto(PAGE + '?tags=1&' + SETQ);
  G.tables = await pp.evaluate(() => {
    zb.fill(-1e9); pix.fill(0); part('probe', () => FD.chair(0, 8));
    const sx = Math.round(OX), sy = Math.round(OY + 8 * .5 * S - .44 * Math.sqrt(3) / 2 * S), d = 8 * Math.sqrt(3) / 2 + .44 * .5;
    const up = []; for (let dy = -2; dy <= 2; dy++) up.push([dy, zb[(sy + dy) * W + sx]]);
    return { chair: { sx, sy, d, z: zb[sy * W + sx], around: up } };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs, sheet);
  const results = await checks(sheet, G, probes, PV);
  sheet.setKey.baked = [...new Set(MOMENTS.map(m => '?' + ['luz1', 'luz2', 'luz3', 'tele', 'mesa', 'oscuro'].map(k => k + '=' + PV.moment[m].set[k]).join('&')))];
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
const ITEM = '(?:-?[\\d.]+|"[\\w.=+&?:-]+")';
const compact = t => t.replace(new RegExp('\\[\\n\\s+(' + ITEM + '(?:,\\n\\s+' + ITEM + ')*)\\n\\s+\\]', 'g'), (m, a) => '[' + a.replace(/,\n\s+/g, ', ') + ']');

/* ---------- the preview's moments: noche-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/noche-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  const lyingCtx = sheet.spots.cama1.screen;
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(a => window.PREVIEW.silhouette(a.k, a.ctx), { k: v, ctx: { sx: lyingCtx[0], sy: lyingCtx[1] } });
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
    if (d.lying) { o.anchor = d.anchor; o.plane = 'lying'; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.fixed) o.fixed = 1;
    if (d.chair) o.chair = 1;
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [105, 106, 107], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 105, 106 and 107: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
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
  const T = E.TV, SB = E.SIDEBOARD, TB = E.TABLE, BD = E.BED, SF = E.SOFA, L1 = E.LAMP1, L2 = E.LAMP2, L3 = E.LAMP3;
  const tvV = r4(T.v - .02 + .08);                                                   // the screen's face: the set draws the screen box at v - .02 with half-depth .08
  things.television = await setThing(r4(T.u - (T.hw - .06)), tvV, r4(T.z0 + .06), r4(T.u + (T.hw - .06)), tvV, r4(T.z1 - .06), 'the television\'s screen (TV u ' + T.u + ', v ' + T.v + ', hw ' + T.hw + ', z ' + T.z0 + ' to ' + T.z1 + '): the lit or dark face, a .06 border in from the frame, on the face at v ' + tvV + '; a poke');
  things.luz1 = await setThing(r4(L1[0] - .3), L1[1], 1.6, r4(L1[0] + .3), L1[1], 2.05, 'the standing lamp\'s shade (LAMP1 u ' + L1[0] + ', v ' + L1[1] + '; z 1.6 to 2.05, half-width .3 at its foot): a poke');
  things.luz2 = await setThing(r4(L2.u - .2), .12, r4(L2.z + .2), r4(L2.u + .2), .12, r4(L2.z + .52), 'the lamp on the wall shelf\'s shade (LAMP2 u ' + L2.u + ', the shelf\'s top z ' + L2.z + ': the shade is z ' + r4(L2.z + .2) + ' to ' + r4(L2.z + .52) + ', v .12, half-width .2): a poke');
  things.luz3 = await setThing(r4(L3[0] - .16), .13, L3[1], r4(L3[0] + .16), .13, r4(L3[1] + .3), 'the wall lamp\'s shade (LAMP3 u ' + L3[0] + ', z ' + L3[1] + ': the shade is z ' + L3[1] + ' to ' + r4(L3[1] + .3) + ', v .13, half-width .16): a poke');
  const CK = E.CLOCK, ckU = 7.5 / G.S, ckZ = 7.5 / 22.5;
  things.reloj = await setThing(r4(CK[0] - ckU), 0, r4(CK[1] - ckZ), r4(CK[0] + ckU), 0, r4(CK[1] + ckZ), 'the wall clock (u ' + CK[0] + ', z ' + CK[1] + ': a disc of radius 7.5 px, hands are sprites), on the wall (v 0); a poke');
  things.mesa = await setThing(r4(TB.u - TB.hw), r4(TB.v - TB.hd), TABLE_Z, r4(TB.u + TB.hw), r4(TB.v + TB.hd), TABLE_Z, 'the dinner table\'s top (mesa = 1: u ' + r4(TB.u - TB.hw) + ' to ' + r4(TB.u + TB.hw) + ', v ' + r4(TB.v - TB.hd) + ' to ' + r4(TB.v + TB.hd) + ', z ' + TABLE_Z + '); a poke');
  things.aparador = await setThing(r4(SB.u - SB.hw), r4(SB.v - SB.hd), SB.h, r4(SB.u + SB.hw), r4(SB.v + SB.hd), SB.h, 'the sideboard\'s top (u ' + r4(SB.u - SB.hw) + ' to ' + r4(SB.u + SB.hw) + ', v ' + r4(SB.v - SB.hd) + ' to ' + r4(SB.v + SB.hd) + ', z ' + SB.h + '); a poke');
  const bmid = (BD.v0 + BD.v1) / 2, bhd = (BD.v1 - BD.v0) / 2, bhw = BD.hw - .04, bv0 = r4(bmid + .06 - (bhd - .08)), bv1 = r4(bmid + .06 + (bhd - .08));      // CS.bed's mattress: box (u, mid + .06, .34, .5, hw - .04, hd - .08)
  things.cama = await setThing(r4(BD.u - bhw), bv0, .34, r4(BD.u + bhw), bv1, .5, 'the bed\'s mattress seen through the arch (BED u ' + BD.u + ', v ' + bv0 + ' to ' + bv1 + ', z .34 to .5: its top is z .5); a poke');
  const fq = (await proj([[BD.u, bv1, .5]]))[0];
  things.cama.foot = [Math.round(fq[0]), Math.round(fq[1])];                         // the mattress's top edge at the foot: where the blanket ends
  things.cama.blanket = [Math.round(2 * bhw * G.S), Math.round(fq[0])];             // the blanket: the mattress's width in px, and its middle column
  things.cama.colour = BED_COLOUR;
  things.sofa = await setThing(r4(SF.u - SF.hw), r4(SF.v - .32), 0, r4(SF.u + SF.hw), r4(SF.v + .32), SEAT_Z, 'the sofa\'s seat (box u ' + r4(SF.u - SF.hw) + ' to ' + r4(SF.u + SF.hw) + ', v ' + r4(SF.v - .32) + ' to ' + r4(SF.v + .32) + ', z 0 to ' + SEAT_Z + '); a poke');
  // the things abuela holds, at the armchair: sprites at a pixel offset from the spot butaca (not spots of the spec: the spec gives their sizes and "in abuela's hands / in her lap")
  const bs = spots.butaca.screen;
  const HOLD = { bufanda: { px: [4, -2], size: [12, 8], what: 'the scarf, three stripes (a 12 x 8 px stand-in) across her hands at the armchair: its bottom middle 4 px right of and 2 px above butaca\'s point (105, moments 1 and 2)' },
    lana: { px: [-8, -1], size: [8, 8], what: 'the ball of wool (an 8 x 8 px stand-in) in her lap: its bottom middle 8 px left of and 1 px above butaca\'s point (105, the turn); in no moment of the spec, so it is not drawn' },
    libro: { px: [4, -2], size: [12, 8], what: 'her storybook, open (a 12 x 8 px stand-in) in her lap: its bottom middle 4 px right of and 2 px above butaca\'s point (107, moment 6)' } };
  for (const [k, h] of Object.entries(HOLD)) things[k] = { sprite: true, on: 'butaca', px: h.px, anchor: 'bottom', size: h.size, box: boxOn(bs[0] + h.px[0], bs[1] + h.px[1], h.size, 'bottom'), what: h.what };
  const touch = { jugo: 'jugo', flan: 'flan', queso: 'queso', frutas: 'frutas', vela: 'vela', perro: 'perro' };
  for (const k of Object.keys(touch)) things[k] = 'sprite';
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'coqui']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'noche',
    made: 'node docs/proyecto/pixel/noche-sheet-make.js, from noche-set.html (window.NOCHE.E and E.SEATS) and the design of La noche (the orchestrator\'s p9-spec, general rules and section noche). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. The table\'s chairs are E.SEATS (FD.setTable\'s places, with mesa 1): ' + E.SEATS.map((p, i) => 'silla' + (i + 1) + ' (' + r4(p[0]) + ', ' + r4(p[1]) + ')').join(', '),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + SEAT_Z + ': a seat\'s top; z ' + ARM_Z + ': the sofa\'s right arm\'s top; z ' + SB.h + ': the sideboard\'s top; z ' + TABLE_Z + ': the table\'s top; z ' + E.WINDOW[2] + ': the window\'s sill) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the juice, the flan, the cheese, the fruit and the candle have their bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; abuela standing mkAbuela (48 x 51): column 30; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy); a child sitting on the floor (alfombra1, alfombra2 in 105): the sitting drawing with its feet (its lowest row) on the spot; Canelo mkPerro (30 x 22): column 15 and its bottom edge; a small thing: see spot. Whoever lies in the bed (cama1, cama2): the standing sprite hangs DOWN the bed from the spot (the top of his sprite on row sy, his middle on column sx), clipped at the bed\'s foot (things.cama.foot), and over it a blanket in the bed\'s colour (things.cama.colour) and the mattress\'s width (things.cama.blanket) from his chest (sprite row 24 of a child) to the bed\'s foot. Nobody is drawn turned: whoever sits faces us',
      lying: 'the depth of whoever lies in the bed (spots with plane "lying"): the sprite is not an upright plane through the feet but lies on the bed: its pixel at picture row r has the depth of the horizontal plane at the head\'s height z (the spot\'s z, .6): depth(r) = ((r + .5 - OY + z * 22.5) / 13) * COS + z / 2, the same for everybody in the bed (two of them tie: the later layer wins). The wall\'s rim and the floor in front of the arch hide what is outside the hole by the ordinary rule (hidden where bakedZ > depth(r) + bias)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: {
      params: { luz1: { values: [0, 1], default: 0, note: 'the standing lamp' }, luz2: { values: [0, 1], default: 1, note: 'the lamp on the wall shelf (lit when the address says nothing)' }, luz3: { values: [0, 1], default: 0, note: 'the wall lamp over the sideboard' },
        tele: { values: [0, 1], default: 0, note: 'the television\'s screen' }, mesa: { values: [0, 1], default: 0, note: 'the dinner table with its four chairs (story 106)' }, oscuro: { values: [0, 1], default: 0, note: 'every lamp out: only the moon (the last picture of 107)' } },
      key: 'luz1, luz2, luz3, tele, mesa, oscuro, e.g. "luz1=0&luz2=1&luz3=0&tele=0&mesa=0&oscuro=0"',
      baked: [],                                                                       // filled from the preview's moments (the states they draw), below
      note: 'the geometry (and so the depth) is the same in every state but mesa: the table and its chairs are in the depth of mesa = 1 only. The sheet\'s numbers are read from the set with mesa = 1 and the three lamps lit',
    },
    things,
    spots,
    groups: {
      sofa: ['sofa1', 'sofa2', 'sofa3'], sillas: ['silla1', 'silla2', 'silla3', 'silla4'], alfombra: ['alfombra1', 'alfombra2'], cama: ['cama1', 'cama2'], aparador: ['jugo', 'flan', 'queso', 'frutas'],
      touch: Object.assign({}, touch, { abuela: 'butaca', abuelo: 'sofa1', luis: 'alfombra1', carmen: 'alfombra2', coqui: 'brazo_coqui', bufanda: 'butaca', lana: 'butaca', libro: 'butaca' }),
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p9-spec, "noche"), given in (u, v, z); the seats, the arm, the sideboard, the table, the arch, the bed, the lamps, the window, the clock and the television are read from the set',
      'things: television, luz1, luz2, luz3, reloj, mesa, aparador, cama and sofa are set things with a box (the screen, the shades, the clock\'s disc, the table\'s top, the sideboard\'s top, the mattress, the sofa\'s seat); jugo, flan, queso, frutas and vela are sprites at the spots of the same name; bufanda, lana and libro are sprites held at butaca (things.*.on, .px: a pixel offset from the spot: NOT IN THE SPEC as spots, made for the preview); the people are sprites',
      'whoever sits (sofa1 to sofa3, butaca, silla1 to silla4) is hung by the lap on the seat\'s top; abuelo is sofa1 in 105 and 107 and silla4 in 106, Luis sofa2 then silla2, Carmen sofa3 then silla3, abuela butaca then junto_mesa, ensalada, silla1; a spot\'s sprite is the one of the first of those (the sheet\'s spots.*.what names them all)',
      'the spec gives the four things on the sideboard (jugo, flan, queso, frutas) a u only: v SIDEBOARD.v (' + SB.v + ') is used, the same as aparador_coqui',
      'the spec gives no radius for Canelo\'s shadow: ' + .3 + ' used (open point); the others are El cruce\'s (frog .45, grown-ups .35, children .28)',
      'abuelo is kit\'s FAM.abuelo (a grown-up man, as in the other scenes); mamá does not appear; the lana is in no moment of the spec, so no preview moment draws it (its box is in things.lana)',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the table hides the lap and legs of whoever sits behind it, the sofa\'s seat hides the legs of whoever sits on it, the wall\'s rim hides what is outside the arch\'s hole. Whoever lies in the bed: rules.lying.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page for the moment\'s state). The same rule as El pedido\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing or sitting on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on a seat, stands on the sofa\'s arm, the sideboard, the table or the sill, or lies in the bed (z above 0) casts none: none of those is floor (a shadow cast at the floor under them would show in front of them); the things on the sideboard\'s and the table\'s tops cast none',
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
  const layerName = l => l.at + (l.thing ? ' (' + l.thing + ')' : '');

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, the dog 28; and his rows from the drawn silhouette; a small thing's box)
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

  // 3. the spots above the floor are on what the set draws: a seat's top, the sofa's arm, the sideboard's top, the table's top, the window's sill (part sala or pared, depth within .1 of the spot's),
  //    the chairs' own places (E.SEATS) and the bed (the head rests on the pillow or the mattress: part pared, depth within .15)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    // the chairs: the spot is the chair's own place (E.SEATS) and the chair drawn alone has its seat's top at the spot's depth; in the picture the table is in front of every
    // chair's seat (the set's pixel under a sitter's spot is the table's), so the pixel under the spot cannot be asked
    const ch = G.tables.chair, chairOk = Math.abs(ch.z - ch.d) < .1, seatsOk = E.SEATS.every((p, i) => S['silla' + (i + 1)].uv[0] === r4(p[0]) && S['silla' + (i + 1)].uv[1] === r4(p[1]));
    const chairs = Object.entries(S).filter(([, s]) => s.chair);
    if (!chairOk) bad.push('a chair drawn alone at (0, 8): its seat\'s top at row ' + ch.sy + ' has depth ' + r2(ch.z) + ', not ' + r2(ch.d) + ' (z ' + SEAT_Z + ')');
    if (!seatsOk) bad.push('silla1 to silla4 are not E.SEATS (what FD.setTable drew)');
    for (const [k, s] of chairs) { const best = (px[k] || []).find(r => r.dx === 0 && r.dy === 0); lines.push(k + ' z ' + s.uv[2] + ': the chair\'s own place (E.SEATS); drawn alone its seat\'s top is at depth ' + r2(ch.z) + ' against the ' + r2(ch.d) + ' of a spot at z ' + SEAT_Z + '; in the picture the table hides it (the pixel under the spot is part ' + (best ? best.tag + ' at depth ' + r2(best.z) : 'none') + ', the table\'s)'); surf.push(k); }
    for (const [k, s] of Object.entries(S)) {
      if (s.chair || !s.on || s.on === 'ground') continue;
      const tol = s.plane === 'lying' ? .15 : .1;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < tol;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface the set draws (the seats\' tops z ' + SEAT_Z + ', the sofa\'s arm z ' + ARM_Z + ', the sideboard\'s top z ' + E.SIDEBOARD.h + ', the table\'s top z ' + TABLE_Z + ' part sala; the window\'s sill z ' + E.WINDOW[2] + ' and the bed (the pillow z ' + BED_Z + ') part pared: depth within .1 of the spot\'s, .15 for the bed; the chairs\' own places: the chair drawn alone has its seat\'s top at the spot\'s depth)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
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
    add('things-in-view', bad, 'the boxes of ' + lines.map(l => l.split(' ')[0]).join(', ') + ' are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down.
  //    The pairs of two of the set's own chairs (the spec never moves a seat) are checked apart (seats-apart)
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN, seats = S[a.at].chair && S[b.at].chair;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok, seats });
        if (!ok && !seats) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name]; if (s.fixed) return 'fixed by the set (a seat): not moved';
      const res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 7 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down (the pairs of two of the set\'s own chairs: seats-apart); the pairs that do overlap sideways: ' + (all.filter(q => q.over && !q.seats).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 7 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m && !x.seats).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok, seats: q.seats || undefined }));
  }

  // 5b. seats-apart: the pairs of two of the set's own chairs (silla1 to silla4, E.SEATS: the spec never moves a seat): the same rule. A failing pair is an open point for the set (FD.setTable's span), not a spot to move
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who && S[l.at].chair);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy);
        lines.push('m' + m + ' ' + a.at + ' ~ ' + b.at + ' ' + dx + '/' + dy);
        if (dx < half && dy < UPDOWN) bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways');
      }
    }
    const o = add('seats-apart', bad, 'the people at silla1 to silla4 (' + lines.join(', ') + ') keep their boxes apart sideways or 12 px apart up-down', [bad.length + ' pair(s) of the set\'s own chairs closer than their sprite boxes need (the seats are fixed by the set: not moved):'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {
      const sp = E.SEATS.length > 1 ? Math.abs(E.SEATS[1][0] - E.SEATS[0][0]) : 0, need = Math.ceil(24 / G.S * 1e3) / 1e3;
      o.lines.push('       OPEN POINT (a set number, not a spot of the spec): the table\'s four chairs are ' + r2(sp * G.S) + ' px apart (' + r4(sp) + ' u: FD.setTable span ' + r4(sp * (E.SEATS.length - 1)) + ' in noche-set.html\'s room()); two people at neighbouring chairs need 24 px (' + r4(need) + ' u each: span ' + r4(need * (E.SEATS.length - 1)) + ' u or more, about the same middle u ' + r4(E.TABLE.u) + ')');
    }
  }

  // 6. frog-seen: the frog is never behind a person or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 7 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. heads-clear: everyone who sits or lies (on the sofa, in the armchair, at the table, on the rug in 105, in the bed) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'head') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'every person who sits or lies (' + MOMENTS.map(m => 'm' + m + ': ' + PV.inspect[m].layers.filter(l => l.group === 'head').map(l => l.at).join(', ')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people who sit or lie:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. lamps-tv-clear (moments 1, 2, 6): the three lamps' shades and the television's screen are covered by nobody (no shown pixel of any sprite lies in their boxes)
  {
    const bad = [], lines = [], hints = [], boxes = ['luz1', 'luz2', 'luz3', 'television'].map(n => [n, T[n].box]);
    for (const m of [1, 2, 6]) {
      const L = PV.inspect[m].layers, hits = [];
      for (const [i, l] of L.entries()) for (const [n, b] of boxes) { const c = shownIn(L, i, b); if (c) hits.push([n, layerName(l), c, i, l.at]); }
      lines.push('m' + m + ': ' + (hits.length ? hits.map(h => h[1] + ' covers ' + h[0] + ' ' + h[2] + ' px').join(', ') : '0 px of the three shades and the screen under anyone'));
      for (const h of hits) { bad.push('moment ' + m + ': ' + h[1] + ' covers ' + h[2] + ' px of ' + h[0] + ' [' + T[h[0]].box + ']'); hints.push([m, h[3], h[4]]); }
    }
    const seen = new Set(), o = add('lamps-tv-clear', bad, 'in moments 1, 2 and 6 the three lamps\' shades (luz1 [' + T.luz1.box + '], luz2 [' + T.luz2.box + '], luz3 [' + T.luz3.box + ']) and the television\'s screen [' + T.television.box + '] are covered by nobody: ' + lines.join('; '), [bad.length + ' covering(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { if (seen.has(m + at)) continue; seen.add(m + at); const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, boxes.map(b => b[1])); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + axisTxt(r, at)); }
  }

  // 9. sideboard-clear (moments 3, 4, 5): the things on the sideboard (jugo, flan, queso, frutas) and the candle are covered by nobody, and the candle covers no head (the top 14 rows of anyone who sits or lies)
  {
    const bad = [], lines = [];
    for (const m of [3, 4, 5]) {
      const L = PV.inspect[m].layers, M = planes(L);
      const th = L.map((l, i) => [l, i]).filter(([l]) => l.group === 'cosa' || l.group === 'vela');
      const parts = [];
      for (const [l, i] of th) { const c = coverOf(L, M, i, null); parts.push(l.at + ' ' + l.sx + ',' + l.sy + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); if (c.cov || c.hid || c.out) bad.push('moment ' + m + ' ' + l.at + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture'); }
      const vi = L.findIndex(l => l.group === 'vela');
      if (vi >= 0) for (const [j, l] of L.entries()) { if (l.group !== 'head') continue; const c = coverOf(L, M, j, [vi], [0, HEAD_ROWS]); parts.push('the candle on ' + l.at + '\'s head: ' + c.cov + ' px'); if (c.cov) bad.push('moment ' + m + ': the candle covers ' + c.cov + ' px of the head of ' + l.at); }
      lines.push('m' + m + ': ' + parts.join('; '));
    }
    add('sideboard-clear', bad, 'in moments 3, 4 and 5 the things on the sideboard (m3: jugo, flan, queso, frutas; m4: queso, frutas) and the candle (vela) are covered by nobody and the candle covers no head: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 10. bed-heads (moment 7): the heads of the two children in the bed (the top 14 rows of the sprite) are inside the arch's hole on the picture (every px shown, none hidden by the wall's rim) and covered by nobody
  {
    const bad = [], lines = [], A = E.ARCH, am = (A[0] + A[1]) / 2, ah = (A[1] - A[0]) / 2;
    const inHole = (X, Y) => { const u = (X + .5 - G.OX) / G.S, z = (G.OY - (Y + .5)) / 22.5; return u > A[0] && u < A[1] && (z < A[3] - ah * .5 || Math.hypot((u - am) / ah, (z - (A[3] - ah * .5)) / (ah * .5)) < 1); };
    const hole = [G.OX + A[0] * G.S, G.OX + A[1] * G.S, G.OY - A[3] * 22.5, G.OY].map(r2);
    const m = 7, L = PV.inspect[m].layers, M = planes(L);
    for (const [i, l] of L.entries()) {
      if (l.group !== 'head' || S[l.at].plane !== 'lying') continue;
      const top = Math.min(...l.px.map(p => p[1])), head = l.px.filter(p => p[1] < top + HEAD_ROWS), outside = head.filter(p => !inHole(p[0], p[1])), hid = head.filter(p => p[2]), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
      lines.push(l.at + ' ' + [l.sx, l.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ' (columns ' + Math.min(...head.map(p => p[0])) + ' to ' + Math.max(...head.map(p => p[0])) + '): ' + outside.length + ' px outside the hole, ' + hid.length + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : ''));
      if (outside.length || hid.length || c.cov) bad.push('moment 7 ' + l.at + ': the head: ' + outside.length + ' px outside the arch\'s hole [x ' + hole[0] + ' to ' + hole[1] + ', y ' + hole[2] + ' to ' + hole[3] + '], ' + hid.length + ' hidden by the set, ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
    }
    add('bed-heads', bad, 'in moment 7 the heads of the two children in the bed (cama1, cama2: the top ' + HEAD_ROWS + ' rows of their sprites) are inside the arch\'s hole (x ' + hole[0] + ' to ' + hole[1] + ', y ' + hole[2] + ' to ' + hole[3] + '), none hidden by the wall\'s rim, covered by nobody: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 11. frog-arm (moments 1, 2, 6): the frog on the sofa's arm stands on the arm's top (spots-on-surface: part sala at the spot's depth) and is seen whole
  {
    const bad = [], lines = [];
    if (!surf.includes('brazo_coqui')) bad.push('brazo_coqui is not on the sofa\'s arm\'s top');
    for (const m of [1, 2, 6]) {
      const L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'brazo_coqui'), c = coverOf(L, M, i, null), best = (probes.spotsPx.brazo_coqui || []).find(r => r.dx === 0 && r.dy === 0);
      lines.push('m' + m + ': ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture; the arm\'s own pixel under his feet: part ' + (best ? best.tag + ' at depth ' + r2(best.z) + ' (the spot\'s ' + r2(S.brazo_coqui.depth) + ')' : 'none'));
      if (c.cov || c.hid || c.out) bad.push('moment ' + m + ': the frog on the arm: ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture');
    }
    add('frog-arm', bad, 'the frog at brazo_coqui ' + S.brazo_coqui.screen + ' (u ' + S.brazo_coqui.uv[0] + ', v ' + S.brazo_coqui.uv[1] + ', z ' + ARM_Z + ') stands on the sofa\'s right arm\'s top and is seen whole in moments 1, 2 and 6: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 12. frog-sideboard (moments 3, 4): the frog on the sideboard stands on its top (spots-on-surface) and covers none of the things on it (no pixel of his on a thing's drawn pixels or its box)
  {
    const bad = [], lines = [], hints = [];
    if (!surf.includes('aparador_coqui')) bad.push('aparador_coqui is not on the sideboard\'s top');
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'aparador_coqui'), f = L[i], right = Math.max(...f.px.filter(p => !p[2]).map(p => p[0])), left = Math.min(...f.px.filter(p => !p[2]).map(p => p[0]));
      const parts = [];
      for (const [j, l] of L.entries()) {
        if (l.group !== 'cosa') continue;
        const c = coverOf(L, M, j, [i]), n = shownIn(L, i, S[l.at].box);
        parts.push(l.at + ' (box column ' + S[l.at].box[0] + '): ' + c.cov + ' px under him, ' + n + ' px of his in its box');
        if (c.cov || n) { bad.push('moment ' + m + ': the frog covers ' + c.cov + ' px of ' + l.at + ' (' + n + ' px of his lie in its box [' + S[l.at].box + '])'); hints.push([m, i]); }
      }
      lines.push('m' + m + ': the frog\'s columns ' + left + ' to ' + right + '; ' + parts.join('; '));
    }
    const o = add('frog-sideboard', bad, 'the frog at aparador_coqui ' + S.aparador_coqui.screen + ' (u ' + S.aparador_coqui.uv[0] + ', z ' + E.SIDEBOARD.h + ') stands on the sideboard\'s top and covers none of the things on it: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    const seen = new Set();
    for (const [m, i] of hints) { if (seen.has(m)) continue; seen.add(m); const M = PV.moment[m], boxes = ['jugo', 'flan', 'queso', 'frutas'].filter(k => M.layers.some(l => l.at === k)).map(k => S[k].box), r = await PV.nearestFree(M.set, M.layers, i, boxes); o.lines.push('       nearest passing, moment ' + m + ' aparador_coqui ' + S.aparador_coqui.uv + ': ' + axisTxt(r, 'aparador_coqui')); }
  }

  // 13. frog-sill (moment 7): the frog on the window's sill is whole and inside the picture (and inside the window)
  {
    const bad = [], m = 7, L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'ventana_coqui'), f = L[i], c = coverOf(L, M, i, null), [a, b] = colsOf(S.ventana_coqui);
    const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195));
    if (c.cov || c.hid || c.out || cutL || cutR) bad.push('moment 7: the frog on the sill ' + [f.sx, f.sy] + ': ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + (cutL + cutR) + ' px cut by the window');
    if (!surf.includes('ventana_coqui')) bad.push('ventana_coqui is not on the window\'s sill');
    add('frog-sill', bad, 'the frog at ventana_coqui ' + S.ventana_coqui.screen + ' (z ' + E.WINDOW[2] + ') on the window\'s sill: ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + (cutL + cutR) + ' px cut by the window (columns ' + a + ' to ' + b + ' of the window\'s ' + x0 + ' to ' + (x0 + 195) + ')', [bad.length + ' problem(s):'].concat(bad.map(b2 => '  ' + b2)));
  }

  // info: the things he can touch that the spec lists no check for (the scarf and the book, the clock, the sofa, the bed, the table, the sideboard), the people over them: not checks of the spec
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, parts = [];
      for (const n of ['bufanda', 'libro']) { const i = L.findIndex(l => l.thing === n); if (i >= 0) { const M = planes(L), c = coverOf(L, M, i, null); parts.push(n + ' ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); } }
      for (const n of ['reloj', 'cama', 'television']) { let k = 0; for (const [i, l] of L.entries()) if (!l.thing) k += shownIn(L, i, T[n].box); parts.push(n + ' [' + T[n].box + '] ' + k + ' px under anyone'); }
      lines.push('m' + m + ': ' + parts.join(', '));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
