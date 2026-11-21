#!/usr/bin/env node
'use strict';
/* La entrada's sheet (place 8, La fonda, scene 1): writes docs/proyecto/pixel/entrada-sheet.json from entrada-set.html and the design (the orchestrator's p8-spec: the rules for every sheet, and "entrada"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/entrada-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The door, the rug, the bench, the stand, the rope, the tables and their chairs, the vellonera and the
   window are read from the set (window.ENTRADA.E, E.SEATS), never typed again from the design. Nothing sways here: window.DEPTH.z is the baked depth.
   It loads the set in headless Chrome (entrada-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (entrada-preview.html: PREVIEW.boxes(): today's makers from historia/engine.js and historia/escenas/kit.js). The checks that
   say "covers" or "shows" read the PREVIEW's moments (entrada-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then
   the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   Where one of the spec's numbers failed a check, the spot was moved the least distance that passes (v first, then u; never z, never a seat or a top): MOVES below lists every move with its old
   number and why; the sheet's `moves` and the moved spots' `spec` carry them.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with ENTRADA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'entrada-sheet.json');
const BASE = process.env.ENTRADA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/entrada-set.html';
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

// the numbers of the design (p8-spec: the rules for every sheet, and "entrada")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, gato: 20, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const HEAD_GAP = 16;                                     // moments 1 and 3: the heads of the pair at cola1, cola2 are this many px or more above the heads of the grown-ups in front of them
const WAIST = 35, WAIST_MID = 38;                        // "from the waist up": the top 35 rows of a grown-up, the rows above the hips (kit.js mkPersona: the hips are an ellipse round row hc = 18 + 2 t - 2 = 38, 3.4 high either side: they start at row 35); the spec gives no row: open point. WAIST_MID is the middle of the hips, reported beside it
const SEAT_Z = .44, BENCH_Z = .46, TOP_Z = .74, CLOTH_Z = .36, STOOL_Z = .6;   // a chair's seat top, the bench's, a table's top (the spec), the cloth's hem (the set's FD.table: the box from z .36), the stool's seat
const PX_Z = 22.5;                                       // px per unit of z: S cos 30
const SZ = {                                             // the small things' sizes: the spec's, except the three marked (stand-in: the spec gives no size)
  flores: [10, 12], tarjeta: [8, 10], vela: [6, 10], velaStep: 7, cosa: [10, 12], menu: [14, 12], dulces: [12, 8],
  platos: [16, 18], taburete: [14, 14], bandeja: [30, 3],
};
const MOMENTS = [1, 2, 3, 4, 5, 6, 7];
const STATES = [];
for (const hora of ['ocaso', 'noche', 'tarde_noche']) for (const cuerda of ['puesta', 'abierta']) STATES.push({ hora, cuerda });
const USED = ['ocaso-puesta', 'ocaso-abierta', 'noche-puesta', 'tarde_noche-puesta'];   // the sets the seven moments use

/* Every move of a spec number that a check made necessary: { spot: { to: [u, v, z], why } } (never z, never a seat or a top). The spec's number stays in the sheet as `spec`. */
const MOVES = {
  paso2: { to: [-3.36, 7.6, 0], why: 'cut by the window (spots-in-view, views-x0): the spec\'s u -3.6 puts the mesero\'s left edge at column 14; no x0 holds it and mesa1_d to mesa3_d (the set\'s chairs: their right edge is column 216, so x0 is 21 or more); x0 21 is the only x0 that holds every other spot (puerta1 and atril1: abuela\'s drawn pixels reach one column left of her 24 px box); moved +.24 in u (v moves nothing sideways) to the least u that passes at x0 21: column 33, left edge 21'},
  mesa2_coqui: { to: [1.3, 6.56, TOP_Z], why: 'moment 7: the frog\'s feet are 10 px above abuela\'s and abuelo\'s (mesa2_a, mesa2_b: row 123, the frog row 133) with the boxes overlapping sideways (sprites-apart needs 12 px up-down); moved +.11 in v (the least that passes: row 135; still on the table\'s top, v 5.4 to 6.6)'},
  mesa3_coqui: { to: [1.33, 9.63, TOP_Z], why: 'moment 4: the frog\'s feet are 10 px below abuela\'s and abuelo\'s (mesa3_a, mesa3_b: row 163, the frog row 173) with the boxes overlapping sideways, and 27 px across from Luis at mesa3_c with his feet on the same row (sprites-apart needs 12 px up-down or 28 across); no move along one axis passes both: moved +.08 in v (row 175, 12 below abuela and abuelo) and +.03 in u (28 across from Luis); still on the table\'s top, v 8.5 to 9.7'},
  mesera_fin: { to: [.15, 7.42, 0], why: 'moment 4: her feet are 5 px above Luis\'s at mesa3_c (row 169, Luis row 174) with the boxes overlapping sideways (3 px across: sprites-apart needs 12 px up-down); moved -.48 in v (the least that passes: row 162, 12 above Luis; u would need -.79)'},
};

/* the spots: { name, spec uvz, uvz, kind, sprite, who, on, what, size, anchor, alias, parts }
   kind: person (a character stands or sits there), place (the frog's), thing (a small thing)
   sprite: the preview's sprite name hanging there by default (abuela, abuelo, luis, carmen, senor, ..., coqui; .S = sitting): its silhouette gives the rows the sprite takes
   on: what it stands on above the ground: banco (the bench's seat), silla (a chair's seat), mesa (a table's top), taburete (a stool: a sprite, the set draws none), mano (held in the air) or ground
   size (small things): [w, h]; anchor: bottom = its bottom middle on the point */
function defs(E) {
  const T = E.TABLES, S = E.SEATS.map(t => t.map(p => W4(p))), B = E.BENCH, ST = E.STAND, D = [], names = ['a', 'b', 'c', 'd'];
  const add = (name, uvz, kind, sprite, who, on, what, more) => {
    const mv = MOVES[name];
    D.push(Object.assign({ name, spec: uvz.slice(), uvz: (mv ? mv.to : uvz).slice(), kind, sprite, who, on, what, why: mv ? mv.why : null }, more || {}));
  };
  const alias = (name, of, what, sprite, who, kind) => D.push({ name, alias: of, spec: null, uvz: null, kind, sprite, who, on: 'ground', what });
  // the way in
  add('cola1', [-3.31, .5, 0], 'person', 'senor', 'adulto', 'ground', 'the first of the pair behind the family, in the doorway (the señor in 84 start, the hombre in round B)');
  add('cola2', [-2.38, .5, 0], 'person', 'senora', 'adulto', 'ground', 'the second of the pair behind the family, in the doorway (the señora in 84 start, the mujer in round B)');
  add('puerta1', [-3.31, 2.3, 0], 'person', 'abuela', 'adulto', 'ground', 'abuela, in the open door, behind the frog');
  add('puerta2', [-2.38, 2.3, 0], 'person', 'abuelo', 'adulto', 'ground', 'abuelo, beside abuela');
  add('puerta3', [-3.31, 3.3, 0], 'person', 'luis', 'nino', 'ground', 'Luis, behind abuela');
  add('puerta4', [-2.38, 3.3, 0], 'person', 'carmen', 'nino', 'ground', 'Carmen, behind abuelo');
  add('felpudo', [-2.85, 4.8, 0], 'place', 'coqui', 'coqui', 'ground', 'the frog on the doormat, at the rug\'s near end');
  // the bench
  add('banco_coqui', [B.u, B.v, BENCH_Z], 'place', 'coqui', 'coqui', 'banco', 'the frog sitting on the bench: its middle (BENCH.u, BENCH.v), on the seat\'s top z ' + BENCH_Z);
  add('banco1', [-1.67, B.v, BENCH_Z], 'person', 'hombre.S', 'adulto', 'banco', 'a grown-up waiting on the bench, at its left (on the seat\'s top; he sits, hung by the lap)');
  add('banco2', [-.74, B.v, BENCH_Z], 'person', 'mujer.S', 'adulto', 'banco', 'a grown-up waiting on the bench, at its right');
  // the stand
  add('atril', [ST.u, r4(ST.v - .45), 0], 'person', 'mesera', 'adulto', 'ground', 'the mesera behind her stand');
  add('taburete', [ST.u, r4(ST.v - .45), STOOL_Z], 'person', 'mesero.S', 'adulto', 'taburete', 'the mesero sitting on a stool at the stand (85): the stool\'s seat z ' + STOOL_Z + '; the set draws no stool: a stand-in is drawn in the preview');
  add('ante_atril', [-1.9, 6.0, 0], 'place', 'coqui', 'coqui', 'ground', 'the frog in front of the stand');
  alias('taburete_coqui', 'ante_atril', 'the frog beside the mesero\'s stool: the same place as ante_atril', 'coqui', 'coqui', 'place');
  add('atril1', [-3.31, 3.8, 0], 'person', 'abuela', 'adulto', 'ground', 'abuela, waiting at the stand (84 round B)');
  add('atril2', [-2.38, 3.8, 0], 'person', 'abuelo', 'adulto', 'ground', 'abuelo, beside abuela');
  add('atril3', [-3.31, 4.8, 0], 'person', 'luis', 'nino', 'ground', 'Luis, behind abuela');
  add('atril4', [-2.38, 4.8, 0], 'person', 'carmen', 'nino', 'ground', 'Carmen, behind abuelo');
  alias('ante_cuerda1', 'atril1', 'a couple waiting at the rope (85): the first, the same place as atril1', 'senor', 'adulto', 'person');
  alias('ante_cuerda2', 'atril2', 'a couple waiting at the rope (85): the second, the same place as atril2', 'senora', 'adulto', 'person');
  // beyond the rope
  add('tras_cuerda', [.15, 4.4, 0], 'person', 'mesera', 'adulto', 'ground', 'the mesera beyond the rope');
  // the mesero crossing
  add('paso1', [0, 7.6, 0], 'person', 'mesero', 'adulto', 'ground', 'where the mesero starts his crossing in front of the stand (84)');
  add('paso2', [-3.6, 7.6, 0], 'person', 'mesero', 'adulto', 'ground', 'where his crossing ends, at the left');
  add('choque', [-1.9, 7.2, 0], 'person', 'mesero', 'adulto', 'ground', 'where he is met (84 step 2: the frog\'s way): with his pile of plates');
  // the tables
  for (let n = 1; n <= 3; n++) {
    names.forEach((k, i) => add('mesa' + n + '_' + k, [S[n - 1][i][0], S[n - 1][i][1], SEAT_Z], 'person', 'senor.S', 'adulto', 'silla', 'table ' + n + ': ' + ['the far chair at the left', 'the far chair at the right', 'the chair at the left end', 'the chair at the right end'][i] + ' (E.SEATS[' + (n - 1) + '][' + i + ']), on its seat\'s top z ' + SEAT_Z + '; whoever sits is hung by the lap'));
    add('mesa' + n + '_coqui', [1.3, r4(T[n - 1][1] + .45), TOP_Z], 'place', 'coqui', 'coqui', 'mesa', 'the frog on the near edge of table ' + n + ', on its top z ' + TOP_Z);
  }
  // the vellonera
  add('vellonera1', [1.3, .9, 0], 'person', 'vecino', 'adulto', 'ground', 'a grown-up at the vellonera, his back to the room (drawn from the front: the makers have no back view)');
  add('vellonera2', [2.25, .9, 0], 'person', 'vecina', 'adulto', 'ground', 'a second grown-up at the vellonera');
  // story 86
  add('velas', [2.5, r4(T[1][1] + .3), TOP_Z], 'thing', null, null, 'mesa', 'the three candles in glass cups on the middle table (86): the middle one on the point, the others ' + SZ.velaStep + ' px either side (centre to centre), each ' + SZ.vela.join(' x ') + ' px, bottom edge on the point', { size: [2 * SZ.velaStep + SZ.vela[0], SZ.vela[1]], anchor: 'bottom' });
  add('junto_mesa', [-1.6, 7.2, 0], 'person', 'mesera', 'adulto', 'ground', 'the mesera at the family\'s table (86)');
  add('bandeja', [-.6, 7.6, 0], 'person', 'mesero', 'adulto', 'ground', 'the mesero with his tray (86)');
  add('cosa_a', [-.85, 7.6, 1.0], 'thing', null, null, 'mano', 'the first of the two things on his tray (z 1.0, held: the tray is a sprite)', { size: SZ.cosa, anchor: 'bottom' });
  add('cosa_b', [-.35, 7.6, 1.0], 'thing', null, null, 'mano', 'the second of the two things on his tray', { size: SZ.cosa, anchor: 'bottom' });
  // the things the spec's list names with a place in words
  const m2a = S[1][0];
  add('menu', [m2a[0], m2a[1], r4(SEAT_Z + 10 / PX_Z)], 'thing', null, null, 'mano', 'the menu card in abuela\'s hands at mesa2_a: its bottom middle 10 px above her lap (z ' + r4(SEAT_Z + 10 / PX_Z) + ' = ' + SEAT_Z + ' + 10 / ' + PX_Z + '; open point: the spec says "10 px above her lap", not which edge)', { size: SZ.menu, anchor: 'bottom' });
  add('dulces', [ST.u, r4(ST.v - .45), .95], 'thing', null, null, 'mano', 'the saucer of sweets on the mesero\'s knee at taburete (z .95)', { size: SZ.dulces, anchor: 'bottom' });
  // names of mine for places the spec gives in numbers only
  add('mesera_fin', [.15, 7.9, 0], 'person', 'mesera', 'adulto', 'ground', 'the mesera at the ending of 84 (the spec gives the place, (.15, 7.9, 0), not a name: the name is the make\'s)');
  add('flores', [2.2, r4(T[2][1] + .15), TOP_Z], 'thing', null, null, 'mesa', 'the flowers on the near table (84), near its right end, on its top (the spec says "near its right end": the place is the make\'s: open point)', { size: SZ.flores, anchor: 'bottom' });
  add('tarjeta', [2.6, r4(T[2][1] + .15), TOP_Z], 'thing', null, null, 'mesa', 'the star card on the near table (84), beside the flowers, on its top (the place is the make\'s: open point)', { size: SZ.tarjeta, anchor: 'bottom' });
  for (const d of D) if (d.alias) { const t = D.find(x => x.name === d.alias); d.uvz = t.uvz.slice(); d.spec = t.spec.slice(); d.why = t.why; }
  return D;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   spec-projection, views-x0, spots-in-view, moments-in-view, spots-on-surface, things-in-view, sprites-apart, frog-seen, heads-clear, cola-heads, bench-seat, mesera-waist, cloths-clear, m7-things.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => ({ E: JSON.parse(JSON.stringify(ENTRADA.E)), scene: PP_SCENE, W, H, S, OX, OY, pzxy: PZ.xy(.7, 1.3) }));
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet0 = await make(G, proj, null);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet0, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const PV = await previewData(browser, errs);
  const sheet = await make(G, proj, PV.boxes);
  const probes = await probeSets(browser, page, sheet, G);
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

/* ---------- the preview's moments: entrada-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its id, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/entrada-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  PV.boxes = await p.evaluate(() => window.PREVIEW.boxes());
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow, head, guard, selfOff) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow, x.head, x.guard, x.selfOff), { st, specs, idx, allow: allow || 0, head: head || 0, guard: guard || [], selfOff: !!selfOff });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point (bottom middle on the point)
const boxOn = (sx, sy, size) => [sx - Math.floor(size[0] / 2), sy - size[1], size[0], size[1]];
// what a spot takes of the picture: columns [first, last] (a person: his sprite box, the feet's spot in the middle, joined with the drawn silhouette; a small thing: its box) and rows [top, bottom]
function extentOf(s, BOX) {
  const [sx, sy] = s.screen;
  if (s.who) {
    const hw = WIDTH[s.who] / 2, k = BOX && BOX[s.sprite];
    let a = sx - hw, b = sx + hw - 1, t = sy, bt = sy;
    if (k) { a = Math.min(a, sx + k.box[0]); b = Math.max(b, sx + k.box[2]); t = sy + k.box[1]; bt = sy + k.box[3]; }
    return { cols: [a, b], rows: [t, bt] };
  }
  if (s.box) return { cols: [s.box[0], s.box[0] + s.box[2] - 1], rows: [s.box[1], s.box[1] + s.box[3] - 1] };
  return { cols: [sx, sx], rows: [sy, sy] };
}
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0, BOX) {
  const [a, b] = extentOf(s, BOX).cols;
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, BOX) {
  const E = G.E, sc = G.scene, DEF = defs(E), T = E.TABLES, SE = E.SEATS;
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sprite) o.sprite = d.sprite;
    if (d.who) o.who = d.who;
    if (d.alias) o.alias = d.alias;
    if (d.size) { o.box = boxOn(sx, sy, d.size); o.anchor = d.anchor; }
    if (d.name === 'velas') o.parts = [-1, 0, 1].map(k => [sx - Math.floor(SZ.vela[0] / 2) + k * SZ.velaStep, sy - SZ.vela[1], SZ.vela[0], SZ.vela[1]]);
    if (d.uvz[2] > 0) o.on = d.on;
    if (d.why) { o.spec = W4(d.spec); o.moved = d.why; }
    spots[d.name] = o;
  });

  /* ---- the view: x0 22 (the window centred on the picture) unless a spot is cut, then the x0 that holds them all ---- */
  const held = Object.keys(spots);
  const ext = held.map(k => extentOf(spots[k], BOX).cols), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const okAll = []; for (let x = 0; x <= G.W - 196; x++) if (held.every(k => !cutAt(spots[k], x, BOX))) okAll.push(x);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (okAll.length) { for (const x of okAll) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, k) => a + cutAt(spots[k], x, BOX), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [84, 85, 86], holds: held, extent: [lo, hi], x0Range: okAll.length ? [okAll[0], okAll[okAll.length - 1]] : null,
      what: 'the one view of stories 84, 85 and 86: the 196 x 216 window over the 240 x 216 picture. The spec: x0 ' + centred + ' (the window centred on the picture) unless a spot is cut. ' + (okAll.length ? 'x0 ' + okAll[0] + ' to ' + okAll[okAll.length - 1] + ' hold every spot (a person with his sprite whole, a small thing with its box); x0 ' + x0 + ' is the one nearest ' + centred : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    const t = { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
    if (v0 === v1) t.quad = [0, 1, 5, 4].map(i => W4([q[i][3], q[i][4], corners[i][2]]));          // a plane facing the camera: its four corners
    return t;
  };
  // the table's half-depth and the chairs' span come from the chairs' places (E.SEATS): the far chairs stand .26 beyond the table's far edge, .55 either side of its middle
  const HD = T.map((t, k) => r4(t[1] - SE[k][0][1] - .26)), SPAN = T.map((t, k) => r4((SE[k][1][0] - SE[k][0][0]) / 2));
  const things = {}, B = E.BENCH, D0 = E.DOOR, V = E.VELLONERA;
  things.banco = await setThing(r4(B.u - B.hw), r4(B.v - .3), 0, r4(B.u + B.hw), r4(B.v + .26), 1.17, 'the bench against the back wall: its seat (u ' + r4(B.u - B.hw) + ' to ' + r4(B.u + B.hw) + ', the top z ' + BENCH_Z + '), its back to z 1.17 and its arms; plaza-base.js PZ.seat: v ' + r4(B.v - .3) + ' (its back\'s uprights) to ' + r4(B.v + .26) + ' (the arms\' front). A poke');
  for (let k = 0; k < 3; k++) things['mesa' + (k + 1)] = await setThing(r4(T[k][0] - E.THW), r4(T[k][1] - HD[k]), TOP_Z, r4(T[k][0] + E.THW), r4(T[k][1] + HD[k]), TOP_Z, 'table ' + (k + 1) + '\'s top (z ' + TOP_Z + '): u ' + r4(T[k][0] - E.THW) + ' to ' + r4(T[k][0] + E.THW) + ' (THW ' + E.THW + ' either side of its middle), v ' + r4(T[k][1] - HD[k]) + ' to ' + r4(T[k][1] + HD[k]) + '. A poke');
  things.puerta = await setThing(D0[0], 0, D0[2], D0[1], 0, D0[3], 'the open door: its hole in the back wall (E.DOOR: u ' + D0[0] + ' to ' + D0[1] + ', z ' + D0[2] + ' to ' + D0[3] + '), on the plane v 0 (its frame is not in it). A poke');
  things.vellonera = await setThing(r4(V.u - V.hw), r4(V.v - V.hd), 0, r4(V.u + V.hw), r4(V.v + V.hd), V.h, 'the vellonera: its box (u ' + r4(V.u - V.hw) + ' to ' + r4(V.u + V.hw) + ', v ' + r4(V.v - V.hd) + ' to ' + r4(V.v + V.hd) + ', z 0 to ' + V.h + '). A poke');
  for (const k of ['mesera', 'menu', 'cosa_a', 'cosa_b', 'velas', 'dulces', 'mesero', 'abuela', 'abuelo', 'luis', 'carmen', 'senor', 'senora', 'hombre', 'mujer', 'joven', 'coqui']) things[k] = 'sprite';

  /* ---- the cloths (85: a red one on mesa2, a blue one on mesa3): sprites that cover a table's top and front, hung from its near bottom edge ---- */
  const cloths = {};
  for (const k of [1, 2]) {
    const tu = T[k][0], tv = T[k][1], hd = HD[k], hw = E.THW, ytop = G.OY + G.S * (tv - hd) * .5 - TOP_Z * COS * G.S, yfront = G.OY + G.S * (tv + hd) * .5 - TOP_Z * COS * G.S, yhem = G.OY + G.S * (tv + hd) * .5 - CLOTH_Z * COS * G.S;
    const x0c = Math.ceil(G.OX + G.S * (tu - hw) - .5 - 1e-9), x1c = Math.floor(G.OX + G.S * (tu + hw) - .5 + 1e-9), y0c = Math.ceil(ytop - .5 - 1e-9), ysp = Math.ceil(yfront - .5 - 1e-9), y1c = Math.ceil(yhem - .5 - 1e-9) - 1;
    const hem = scrUV(G, tu, r4(tv + hd), CLOTH_Z);
    cloths['mesa' + (k + 1)] = { uv: W4([tu, tv + hd, CLOTH_Z]), screen: hem, box: [x0c, y0c, x1c - x0c + 1, y1c - y0c + 1], topRows: ysp - y0c, ax: hem[0] - x0c,
      what: 'the cloth of table ' + (k + 1) + ' (85: ' + (k === 1 ? 'red' : 'blue') + '): the table\'s top (u ' + r4(tu - hw) + ' to ' + r4(tu + hw) + ', v ' + r4(tv - hd) + ' to ' + r4(tv + hd) + ', z ' + TOP_Z + ') and its front down to its hem (z ' + CLOTH_Z + '), the screen box [' + [x0c, y0c, x1c - x0c + 1, y1c - y0c + 1] + ']: ' + (ysp - y0c) + ' rows of top, then ' + (y1c + 1 - ysp) + ' of front; hung with its bottom middle on the hem\'s middle (uv, screen)' };
  }

  // the stand-ins' boxes (the sprites that stay in the sprite layer): how big each is drawn here
  const standins = {};
  standins.platos = { size: SZ.platos, held: 'mesero', what: 'the mesero\'s tall pile of plates at choque (84 step 2), a ' + SZ.platos.join(' x ') + ' stand-in (the spec gives no size: open point): its bottom middle on the mesero\'s middle, 18 px above his feet (z .8: the top of the pile is level with his chin)' };
  standins.taburete = { size: SZ.taburete, at: 'taburete', what: 'the mesero\'s stool (85): a ' + SZ.taburete.join(' x ') + ' stand-in, its bottom middle on the floor under taburete, its seat at z ' + STOOL_Z + ' (13.5 px); the set draws no stool and the spec gives no size: open point' };
  standins.bandeja = { size: SZ.bandeja, what: 'the mesero\'s tray (86): a ' + SZ.bandeja.join(' x ') + ' stand-in, its top row on the row where cosa_a and cosa_b stand (z 1.0), centred on bandeja\'s column; not a thing of the sheet: it only keeps the two things from floating' };
  standins.velas = { size: SZ.vela, step: SZ.velaStep, what: 'three ' + SZ.vela.join(' x ') + ' candles in glass cups, ' + SZ.velaStep + ' px apart: the spec\'s sizes' };

  return {
    scene: 'entrada',
    made: 'node docs/proyecto/pixel/entrada-sheet-make.js, from entrada-set.html (window.ENTRADA.E, E.SEATS) and the design of La entrada (the orchestrator\'s p8-spec, section entrada). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + BENCH_Z + ': the bench\'s seat top; z ' + SEAT_Z + ': a chair\'s seat top; z ' + TOP_Z + ': a table\'s top; z ' + STOOL_Z + ': the mesero\'s stool) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): its bottom middle is on the point. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up, 41 for a child; abuela standing mkAbuela (48 x 51): column 30, rows 0 to 49; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a grown-up or a child sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41, t 7 a child: 33) on (sx, sy); a small thing: see spot. Nobody is drawn turned: the makers draw them from the front (the two at the vellonera face us)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      waist: 'whole from the waist up: the top ' + WAIST + ' rows of a grown-up\'s sprite, the rows above the hips (mkPersona: the hips are an ellipse round row hc = 18 + 2 t - 2 = ' + WAIST_MID + ', 3.4 high either side: they start at row ' + WAIST + '); the spec gives no row: open point (the check also reports the top ' + WAIST_MID + ' rows, to the middle of the hips)',
      tables: 'each table is ' + (2 * E.THW) + ' wide (THW ' + E.THW + ' either side of its middle) and ' + (2 * HD[0]) + ' deep (the chairs of the far side stand .26 beyond its far edge); the far chairs are ' + SPAN[0] + ' either side of its middle, the end chairs ' + r4(E.THW + .4) + ' (E.SEATS: the two far chairs, then the left end, then the right end)',
    },
    setKey: {
      params: { hora: { values: ['ocaso', 'noche', 'tarde_noche'], note: '84 ocaso (every moment: dusk); 85 noche, and tarde_noche after a right move (the window darker still); 86 noche. The spec gives no hora for the moments of 84 other than the start: ocaso is used (open point)' }, cuerda: { values: ['puesta', 'abierta'], note: 'the rope across the way, or unhooked and hanging from its far post (84 ending: abierta; every other moment: puesta; the spec gives no cuerda for 86: puesta is used: open point)' } },
      key: 'hora + cuerda, e.g. "ocaso-puesta"',
      used: USED,
      baked: STATES.map(s => '?hora=' + s.hora + '&cuerda=' + s.cuerda),
    },
    things,
    cloths,
    standins,
    spots,
    groups: {
      familia_puerta: ['puerta1', 'puerta2', 'puerta3', 'puerta4'], cola: ['cola1', 'cola2'], atril_fila: ['atril1', 'atril2', 'atril3', 'atril4'], banco: ['banco_coqui', 'banco1', 'banco2'],
      mesa1: ['mesa1_a', 'mesa1_b', 'mesa1_c', 'mesa1_d', 'mesa1_coqui'], mesa2: ['mesa2_a', 'mesa2_b', 'mesa2_c', 'mesa2_d', 'mesa2_coqui'], mesa3: ['mesa3_a', 'mesa3_b', 'mesa3_c', 'mesa3_d', 'mesa3_coqui'],
      vellonera: ['vellonera1', 'vellonera2'], mesero_paso: ['paso1', 'paso2', 'choque'], velas86: ['velas', 'junto_mesa', 'bandeja', 'cosa_a', 'cosa_b'],
    },
    moves: DEF.filter(d => d.why).map(d => ({ spot: d.name, from: W4(d.spec), to: W4(d.uvz), why: d.why })),
    notes: [
      'every number of a spot is the orchestrator\'s (the p8-spec, "entrada"), given in (u, v, z); the door, the bench, the stand, the tables and their chairs (E.SEATS), the vellonera are read from the set (window.ENTRADA.E). A spot the spec\'s number failed a check on was moved the least distance that passes (`moves`; the spec\'s number stays in the spot\'s `spec`)',
      'ante_cuerda1, ante_cuerda2 are atril1, atril2 and taburete_coqui is ante_atril (the spec: "also"): the same numbers, a spot each; they follow a move of their target',
      'the spec names mesera_fin (the mesera at the ending of 84, (.15, 7.9, 0)), flores and tarjeta (the flowers and the star card on the near table, "near its right end") by place only or not at all: the names are the make\'s',
      'the set draws no stool, no flowers, no cloth of another colour, no card, no candles, no plates: they are sprites (standins, cloths); taburete\'s z ' + STOOL_Z + ' is on a stool the preview draws',
      'cosa_a and cosa_b stand on the mesero\'s tray at z 1.0, menu in abuela\'s hands, dulces on the mesero\'s knee: in the air, held by a sprite: no surface of the set is under them',
      'the two at the vellonera, and the people at the bench, are drawn facing us: the makers have no back view and nobody is drawn turned',
      'the views\'s x0: x0 22 when every spot is inside the window (a person with his sprite whole, a small thing with its box) (check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the stand, the rope\'s posts, the tables and the chairs\' backs, the vellonera and the bench hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El cruce\'s sheet: the upright plane through the feet (a held thing: the plane through its own bottom; a cloth: the plane through its hem)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, mesera: .35, mesero: .35, abuela: .35, abuelo: .35, senor: .35, senora: .35, hombre: .35, mujer: .35, joven: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on a chair, the bench or the stool, or stands on a table (z above 0) casts none: none of those is the floor (a shadow cast at the floor under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(browser, page, sheet, G) {
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
  // the chairs alone: each chair drawn on a cleared depth buffer (a fresh page), read at the spot's pixel: the table in front hides the far chairs in the set, so the set's own pixel there is the table's
  const sp = await browser.newPage();
  await sp.route(BASE + '/**', serve);
  await sp.goto(PAGE);
  const arg = [];
  for (let n = 1; n <= 3; n++) for (const [i, k] of ['a', 'b', 'c', 'd'].entries()) { const s = sheet.spots['mesa' + n + '_' + k]; arg.push({ name: 'mesa' + n + '_' + k, u: s.uv[0], v: s.uv[1], end: i >= 2 ? (i === 2 ? -1 : 1) : 0, screen: s.screen, spec: sheet.spots['mesa' + n + '_' + k].spec || s.uv });
  }
  const seats = await sp.evaluate(a => a.map(c => {
    zb.fill(-1e9);
    const E0 = ENTRADA.E.SEATS[+c.name[4] - 1][['a', 'b', 'c', 'd'].indexOf(c.name[6])];
    if (c.end) FD.chairEnd(E0[0], E0[1], c.end); else FD.chair(E0[0], E0[1]);
    const out = { name: c.name, z: zb[c.screen[1] * W + c.screen[0]], up: zb[(c.screen[1] - 4) * W + c.screen[0]], at: E0 };
    zb.fill(-1e9);
    return out;
  }), arg);
  await sp.close();
  return { spotsPx, seats };
}

function checks(sheet, G, probes, PV) { return checksAsync(sheet, G, probes, PV); }
async function checksAsync(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, BOX = PV.boxes, OUTS = [], E = G.E, ST = E.STAND;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x, Ls = m => PV.inspect[m].layers;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other, but what the layer holds as its own); who covers them
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, cov = 0; const who = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2]) { hid++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && L[b.i].held !== l.id && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].id; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const idxOf = (L, id) => L.findIndex(l => l.id === id);
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  const named = L => L.map(l => l.id + '@' + l.at).join(', ');

  // 0. spec-projection: the spec's arithmetic (sx = OX + 26 u, sy = OY + 13 v - 22.5 z) against the engine's own projection of every spot; PZ.xy against the make's
  {
    const bad = [], ties = [], worst = { dx: 0, dy: 0 };
    for (const [k, s] of Object.entries(S)) {
      const sx = Math.round(G.OX + 26 * s.uv[0]), sy = Math.round(G.OY + 13 * s.uv[1] - 22.5 * s.uv[2]);
      worst.dx = Math.max(worst.dx, Math.abs(sx - s.screen[0])); worst.dy = Math.max(worst.dy, Math.abs(sy - s.screen[1]));
      const tie = Math.abs(Math.abs(G.OX + 26 * s.uv[0] - Math.floor(G.OX + 26 * s.uv[0])) - .5) < 1e-6;                  // u S ends in .5: the engine's float arithmetic rounds it either way: 1 px, not a failure
      if (Math.abs(sx - s.screen[0]) > (tie ? 1 : 0) || Math.abs(sy - s.screen[1]) > 1) bad.push(k + ' ' + s.uv + ': the spec\'s arithmetic gives [' + [sx, sy] + '], the engine ' + s.screen);
      else if (sx !== s.screen[0]) ties.push(k + ' ' + s.uv[0] + ' (' + (G.OX + 26 * s.uv[0]) + ' -> ' + s.screen[0] + ')');
    }
    const q = [(.7 + 1.3) / R2, (1.3 - .7) / R2];
    if (Math.abs(G.pzxy[0] - q[0]) > 1e-9 || Math.abs(G.pzxy[1] - q[1]) > 1e-9) bad.push('PZ.xy(.7, 1.3) = ' + G.pzxy + ' is not ((u + v) / R2, (v - u) / R2) = ' + q);
    add('spec-projection', bad, 'the spec\'s arithmetic (sx = ' + G.OX + ' + 26 u, sy = ' + G.OY + ' + 13 v - 22.5 z, rounded) is the engine\'s projection for all ' + Object.keys(S).length + ' spots (worst difference ' + worst.dx + ' px across, ' + worst.dy + ' px down: the engine does not round z: the spec\'s 22.5 is 22.517' + (ties.length ? '; ' + ties.length + ' spot(s) whose 26 u ends in .5 round the other way in the engine\'s floats: ' + ties.join(', ') : '') + '); PZ.xy is ((u + v) / R2, (v - u) / R2)', ['the spec\'s arithmetic and the engine differ:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box); x0 22 unless a spot is cut
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0, BOX)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const at22 = v.holds.map(k => [k, cutAt(S[k], 22, BOX)]).filter(o => o[1]);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + '; at x0 22: ' + (at22.length ? at22.map(a => a[0] + ' cut by ' + a[1] + ' px').join(', ') : 'no spot is cut'), [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, joined with his drawn silhouette; a small thing's box)
  {
    const bad = [], names = [], hints = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, e = extentOf(s, BOX), [a, b] = e.cols, [top, bottom] = e.rows;
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + s.box + ']') + ' is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k]; let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = JSON.parse(JSON.stringify(s)); t.screen = [sx, s.screen[1]]; if (t.box) t.box[0] += sx - s.screen[0]; const c = extentOf(t, BOX).cols; if (!cutAt(t, x0, BOX) && c[0] >= 0 && c[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u') + ' (v moves nothing sideways)');
    }
    const lm = names.reduce((a, k) => extentOf(S[k], BOX).cols[0] < extentOf(S[a], BOX).cols[0] ? k : a, names[0]), rm = names.reduce((a, k) => extentOf(S[k], BOX).cols[1] > extentOf(S[a], BOX).cols[1] ? k : a, names[0]);
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + extentOf(S[lm], BOX).cols[0] + ' (' + lm + '), the rightmost ' + extentOf(S[rm], BOX).cols[1] + ' (' + rm + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    o.cut = bad;
  }

  // 3. moments-in-view: every sprite of every moment (people and small things) whole inside the picture and the window: no drawn pixel outside
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = Ls(m); let n = 0;
      for (const l of L) {
        const xs = l.px.map(p => p[0]), lo = Math.min(...xs), hi = Math.max(...xs), cut = Math.max(0, x0 - lo) + Math.max(0, hi - (x0 + 195));
        n += l.px.length + l.out;
        if (cut || l.out) bad.push('moment ' + m + ': ' + l.id + ' at ' + (l.at || 'uvz') + ' ' + [l.sx, l.sy] + ': drawn columns ' + lo + ' to ' + hi + ' (window ' + x0 + ' to ' + (x0 + 195) + '): ' + cut + ' px cut by the window, ' + l.out + ' px outside the picture');
      }
      lines.push('m' + m + ' ' + L.length + ' sprites');
    }
    add('moments-in-view', bad, 'every drawn pixel of every sprite of the 7 moments is inside the picture and the window [' + x0 + ', ' + (x0 + 196) + ') (' + lines.join(', ') + ')', [bad.length + ' sprite(s) cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 4. the spots above the floor are on what the set draws: the chairs' seat tops (z .44: the chair drawn alone, its pixel at the spot), the bench's seat top (z .46: the set's own pixel), a table's top (z .74: the set's own pixel).
  //    The reading: the depth of the set's pixel at the spot against the depth the plane z of the spot has at the centre of that pixel (a pixel of a surface at another height has another depth: 2 per unit of z, so .05 is a z of .025, half a pixel; the set's own pixels run .03 over the plane);
  //    the stool (a sprite), the tray, the knee and the hands (in the air) have no surface of the set
  {
    const bad = [], lines = [], px = probes.spotsPx, TOL = .05;
    const dExp = (sy, z) => COS * ((sy + .5 - G.OY + z * COS * G.S) / (G.S * .5)) + .5 * z;
    for (const c of probes.seats) {
      const s = S[c.name], e = dExp(s.screen[1], s.uv[2]), okz = c.z > -1e8 && Math.abs(c.z - e) <= TOL;
      lines.push(c.name + ' z ' + s.uv[2] + ': the chair alone: depth ' + (c.z > -1e8 ? r2(c.z) : 'none') + ' at the spot\'s pixel against ' + r2(e) + ' for the plane z ' + s.uv[2] + ' (' + (c.z > -1e8 ? r2(Math.abs(c.z - e)) : '-') + '); its seat is at (' + c.at.map(r4) + ')');
      if (!okz) bad.push(c.name + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on the seat\'s top: the chair drawn alone has depth ' + (c.z > -1e8 ? r2(c.z) : 'none') + ' there, the plane z ' + s.uv[2] + ' has ' + r2(e));
      if (s.uv[2] !== SEAT_Z) bad.push(c.name + ' z ' + s.uv[2] + ' is not the seat\'s top ' + SEAT_Z);
    }
    const here = k => (px[k] || []).find(r => r.dx === 0 && r.dy === 0);
    for (const k of ['banco_coqui', 'banco1', 'banco2']) {
      const s = S[k], r = here(k), e = dExp(s.screen[1], s.uv[2]);
      const ok = r && r.tag === 'entrada' && Math.abs(r.z - e) <= TOL && s.uv[2] === BENCH_Z;
      lines.push(k + ' z ' + s.uv[2] + ': the set\'s pixel at the spot: part ' + (r ? r.tag + ', depth ' + r2(r.z) + ' against ' + r2(e) + ' for the plane z ' + s.uv[2] + ' (' + r2(Math.abs(r.z - e)) + ')' : 'none') + '; the bench\'s seat top z ' + BENCH_Z);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on the bench\'s seat: ' + (r ? 'the pixel is part ' + r.tag + ' at depth ' + r2(r.z) + ', the plane z ' + s.uv[2] + ' has ' + r2(e) : 'no pixel'));
    }
    const onTop = [['mesa1_coqui', 0], ['mesa2_coqui', 1], ['mesa3_coqui', 2], ['velas', 1], ['flores', 2], ['tarjeta', 2]];
    for (const [k, ti] of onTop) {
      const s = S[k], t = sheet.things['mesa' + (ti + 1)], inTop = s.uv[0] >= t.uv[0] && s.uv[0] <= t.uv[3] && s.uv[1] >= t.uv[1] && s.uv[1] <= t.uv[4] && s.uv[2] === TOP_Z;
      const r = here(k), e = dExp(s.screen[1], s.uv[2]), ok = inTop && r && r.tag === 'salon' && Math.abs(r.z - e) <= TOL;
      lines.push(k + ' z ' + s.uv[2] + ': ' + (inTop ? 'inside table ' + (ti + 1) + '\'s top (u ' + t.uv[0] + ' to ' + t.uv[3] + ', v ' + t.uv[1] + ' to ' + t.uv[4] + ')' : 'NOT inside table ' + (ti + 1) + '\'s top') + '; the set\'s pixel: part ' + (r ? r.tag + ', depth ' + r2(r.z) + ' against ' + r2(e) + ' (' + r2(Math.abs(r.z - e)) + ')' : 'none'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on table ' + (ti + 1) + '\'s top (' + (inTop ? 'in its rectangle' : 'outside its rectangle') + '; ' + (r ? 'part ' + r.tag + ', depth ' + r2(r.z) + ' against ' + r2(e) : 'no pixel') + ')');
    }
    const o = add('spots-on-surface', bad, probes.seats.length + ' chair spots (each chair drawn alone: its seat top is at the spot), 3 bench spots (part entrada, z ' + BENCH_Z + ') and ' + onTop.length + ' table-top spots (mesa1_coqui, mesa2_coqui, mesa3_coqui, velas, flores, tarjeta: inside the top, part salon, z ' + TOP_Z + ') are on a surface the set draws (depth within ' + TOL + ' of the plane of the spot\'s z at its pixel)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       no surface of the set (a sprite or the air): taburete z ' + STOOL_Z + ' (the stool the preview draws), dulces (the mesero\'s knee, z .95), cosa_a and cosa_b (his tray, z 1.0), menu (abuela\'s hands)');
  }

  // 5. the set things' boxes are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of banco, mesa1 to mesa3, puerta and vellonera are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 6. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = Ls(m).filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.id + '@' + a.at, b: b.id + '@' + b.at, an: a.at, bn: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.id + '@' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.id + '@' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 7 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 7 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.an, b: q.bn, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 7. frog-seen: the frog is never behind a person, a thing or the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = Ls(m), M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; for (const b of M.get(key(x, y)) || []) if (b.i !== fi && L[b.i].held !== 'coqui' && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) { boxCov++; break; } }
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 7 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 8. heads-clear: the head (the top 14 rows of the sprite) of everyone who sits at a table is covered by nobody and by nothing (not a person, a thing or the set), in every moment
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = Ls(m), M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'mesa') continue;
        const c = coverOf(L, M, i, null, [0, HEAD_ROWS]), body = coverOf(L, M, i, null);
        lines.push('m' + m + ' ' + l.id + '@' + l.at + ' ' + [l.sx, l.sy] + ': head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; the whole sprite: ' + body.cov + ' under a nearer sprite, ' + body.hid + ' hidden by the set');
        if (c.cov || c.hid || l.out) { bad.push('moment ' + m + ' ' + l.id + '@' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not clear (' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set)'); fails.push([m, i]); }
      }
    }
    const o = add('heads-clear', bad, 'the head (top ' + HEAD_ROWS + ' rows) of everyone who sits at a table is covered by nobody and nothing in the moments they sit (' + lines.length + ' heads: ' + [4, 6, 7].map(m => 'm' + m + ' ' + Ls(m).filter(l => l.group === 'mesa').map(l => l.id).join(', ')).join('; ') + ')', [bad.length + ' head(s) not clear:'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of fails) { const M = PV.moment[m], r = await PV.nearest(M.set, M.layers, i, 0, HEAD_ROWS); o.lines.push('       nearest passing, moment ' + m + ' ' + M.layers[i].at + ' (his head alone): ' + axisTxt(r, M.layers[i].at)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 9. cola-heads: in moments 1 and 3 the heads of the pair at cola1, cola2 are HEAD_GAP px or more above the heads of the grown-ups in front of them (standing, whose box is across from his)
  {
    const bad = [], lines = [];
    for (const m of [1, 3]) {
      const L = Ls(m), top = l => Math.min(...l.px.map(p => p[1])), pair = L.filter(l => l.at === 'cola1' || l.at === 'cola2');
      for (const p of pair) for (const g of L) {
        if (pair.includes(g) || !g.who || g.who === 'coqui' || g.uvz[2] !== 0 || g.sy <= p.sy || Math.abs(g.sx - p.sx) >= (WIDTH[p.who] + WIDTH[g.who]) / 2) continue;
        const gap = top(g) - top(p), kind = g.who === 'adulto';
        lines.push('m' + m + ' ' + p.id + '@' + p.at + ' (head top row ' + top(p) + ') above ' + g.id + '@' + g.at + ' (' + (kind ? 'grown-up' : 'child: not in the rule') + ', head top row ' + top(g) + '): ' + gap + ' px');
        if (kind && gap < HEAD_GAP) bad.push('moment ' + m + ': the head of ' + p.id + '@' + p.at + ' is only ' + gap + ' px above the head of ' + g.id + '@' + g.at + ' (needs ' + HEAD_GAP + ')');
      }
    }
    const o = add('cola-heads', bad, 'in moments 1 and 3 the heads of the pair at cola1, cola2 are ' + HEAD_GAP + ' px or more above the heads of the grown-ups in front of them: ' + lines.filter(l => !/child/.test(l)).join('; '), [bad.length + ' pair(s) too close:'].concat(bad.map(b => '  ' + b)));
    o.lines.push('       the children in front, info, not a check: ' + lines.filter(l => /child/.test(l)).join('; '));
  }

  // 10. bench-seat: nobody covers the bench's seat in moments 1 and 3 (and the frog's place on it, banco_coqui, is free: the frog drawn there is whole); the frog on it in moment 2 is whole (frog-seen)
  {
    const bad = [], lines = [], seat = (await (async () => { const B = E.BENCH, a = scrUV(G, B.u - B.hw, B.v - .26, BENCH_Z), b = scrUV(G, B.u + B.hw, B.v + .26, BENCH_Z); return [a[0], a[1], b[0] - a[0], b[1] - a[1] + 1]; })());
    for (const m of [1, 3]) {
      const L = Ls(m);
      let n = 0, who = {}; L.forEach(l => { if (l.held) return; for (const p of l.px) if (!p[2] && inside(seat, p[0], p[1])) { n++; who[l.id + '@' + l.at] = (who[l.id + '@' + l.at] || 0) + 1; } });
      const st = PV.moment[m].set, specs = PV.moment[m].layers.concat([{ at: 'banco_coqui', s: 'coqui', who: 'coqui', id: 'coqui_banco' }]), LL = await PV.layers(st, specs), MM = planes(LL), fi = LL.length - 1, c = coverOf(LL, MM, fi, null);
      lines.push('m' + m + ': the seat [' + seat + '] (u ' + r4(E.BENCH.u - E.BENCH.hw) + ' to ' + r4(E.BENCH.u + E.BENCH.hw) + ', the top z ' + BENCH_Z + '): ' + n + ' px drawn over it by sprites' + (n ? ' (' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', ') + ')' : '') + '; the frog drawn at banco_coqui: ' + (LL[fi].px.length + LL[fi].out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : ''));
      if (n) bad.push('moment ' + m + ': ' + n + ' px of the bench\'s seat are covered by sprites (' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', ') + ')');
      if (c.hid || c.cov || LL[fi].out) bad.push('moment ' + m + ': the frog\'s place on the bench is not free: his drawing there has ' + c.hid + ' px hidden by the set, ' + c.cov + ' under ' + (whoTxt(c) || 'nothing') + ', ' + LL[fi].out + ' outside');
    }
    {
      const L = Ls(2), fi = L.findIndex(l => l.who === 'coqui'), M = planes(L), c = coverOf(L, M, fi, null);
      lines.push('m2: the frog on the bench at ' + L[fi].at + ' ' + [L[fi].sx, L[fi].sy] + ': ' + (L[fi].px.length + L[fi].out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : ''));
      if (L[fi].at !== 'banco_coqui') bad.push('moment 2: the frog is at ' + L[fi].at + ', not on the bench');
      if (c.hid || c.cov || L[fi].out) bad.push('moment 2: the frog on the bench is not whole: ' + c.hid + ' px hidden by the set, ' + c.cov + ' under ' + (whoTxt(c) || 'nothing') + ', ' + L[fi].out + ' outside');
    }
    add('bench-seat', bad, 'nobody covers the bench\'s seat in moments 1 and 3, the frog\'s place on it is free (his drawing at banco_coqui there is whole), and the frog on it in moment 2 is whole: ' + lines.join('; '), [bad.length + ' problem(s) at the bench:'].concat(bad.map(b => '  ' + b)));
  }

  // 11. mesera-waist: the mesera is whole from the waist up (the top WAIST rows of her sprite: not hidden by the set, not under a nearer sprite) at atril (moments 1, 2) and at tras_cuerda (moment 3)
  {
    const bad = [], lines = [], fails = [];
    for (const m of [1, 2, 3]) {
      const L = Ls(m), M = planes(L), i = L.findIndex(l => l.id === 'mesera'), c = coverOf(L, M, i, null, [0, WAIST]), all = coverOf(L, M, i, null);
      const mid = coverOf(L, M, i, null, [0, WAIST_MID]);
      lines.push('m' + m + ' mesera at ' + L[i].at + ' ' + [L[i].sx, L[i].sy] + ': rows ' + c.top + ' to ' + (c.top + WAIST - 1) + ' (the waist up): ' + c.tot + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + '; the first row the set hides: ' + (() => { const h = L[i].px.filter(p => p[2]).map(p => p[1]); return h.length ? 'sprite row ' + (Math.min(...h) - c.top) : 'none'; })() + '; to the middle of the hips (the top ' + WAIST_MID + ' rows): ' + mid.hid + ' hidden, ' + mid.cov + ' covered');
      if (c.hid || c.cov || L[i].out) { bad.push('moment ' + m + ': the mesera at ' + L[i].at + ' is not whole from the waist up: ' + c.hid + ' px of her top ' + WAIST + ' rows hidden by the set, ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody')); fails.push([m, i]); }
    }
    const o = add('mesera-waist', bad, 'the mesera is whole from the waist up (the top ' + WAIST + ' rows of her sprite, the rows above the hips) at atril (moments 1, 2) and at tras_cuerda (moment 3): ' + lines.join('; '), [bad.length + ' moment(s) where she is not:'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of fails) { const M = PV.moment[m], r = await PV.nearest(M.set, M.layers, i, 0, WAIST); o.lines.push('       nearest passing, moment ' + m + ' ' + M.layers[i].at + ' ' + S[M.layers[i].at].uv + ' (her top ' + WAIST + ' rows): ' + axisTxt(r, M.layers[i].at)); }
    for (const [m, i] of fails) o.lines.push('       info: the whole mesera at ' + Ls(m)[i].at + ' (not a check): ' + lines.find(l => l.startsWith('m' + m)).split('; ')[0]);
  }

  // 12. cloths-clear: the two cloths of moment 5 (a red one on mesa2, a blue one on mesa3) are covered by nobody (and hidden by nothing of the set)
  {
    const bad = [], lines = [], L = Ls(5), M = planes(L);
    for (const id of ['mantel2', 'mantel3']) {
      const i = idxOf(L, id), c = coverOf(L, M, i, null);
      lines.push(id + ' [' + sheet.cloths['mesa' + id[6]].box + ']: ' + c.tot + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : ''));
      if (c.hid || c.cov || c.out) bad.push('moment 5: the cloth of table ' + id[6] + ' has ' + c.hid + ' px hidden by the set and ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
    }
    add('cloths-clear', bad, 'in moment 5 the red cloth (mesa2) and the blue cloth (mesa3) are covered by nobody and hidden by nothing of the set: ' + lines.join('; '), [bad.length + ' cloth(s) covered:'].concat(bad.map(b => '  ' + b)));
  }

  // 13. m7-things: in moment 7 the three candles, cosa_a and cosa_b are covered by nobody, and the candles cover no head
  {
    const bad = [], lines = [], L = Ls(7), M = planes(L), vi = ['vela1', 'vela2', 'vela3'].map(id => idxOf(L, id));
    for (const id of ['vela1', 'vela2', 'vela3', 'cosa_a', 'cosa_b']) {
      const i = idxOf(L, id), c = coverOf(L, M, i, null);
      lines.push(id + ' ' + [L[i].sx, L[i].sy] + ': ' + c.tot + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : ''));
      if (c.hid || c.cov || c.out) bad.push('moment 7: ' + id + ' has ' + c.hid + ' px hidden by the set and ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
    }
    const heads = [];
    for (const [i, l] of L.entries()) {
      if (!l.who || l.who === 'coqui') continue;
      const c = coverOf(L, M, i, vi, [0, HEAD_ROWS]);
      heads.push(l.id + ' ' + c.cov);
      if (c.cov) bad.push('moment 7: the candles cover ' + c.cov + ' px of the head of ' + l.id + '@' + l.at);
    }
    add('m7-things', bad, 'in moment 7 the three candles (velas), cosa_a and cosa_b are covered by nobody and hidden by nothing, and the candles cover no head (px of each head covered by the candles: ' + heads.join(', ') + '): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // info (not checks): what covers the small things the spec lists but no check names: the menu (moment 7), the saucer (moments 5, 6), the flowers and the card (moments 1 to 4), the pile of plates (moment 2), the frog's place at the tables
  {
    const lines = [];
    for (const [m, ids] of [[1, ['flores', 'tarjeta']], [2, ['flores', 'tarjeta', 'platos']], [3, ['flores', 'tarjeta']], [4, ['flores', 'tarjeta']], [5, ['dulces']], [6, ['dulces']], [7, ['menu']]]) {
      const L = Ls(m), M = planes(L);
      for (const id of ids) { const i = idxOf(L, id), c = coverOf(L, M, i, null); lines.push('m' + m + ' ' + id + ': ' + c.tot + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '')); }
    }
    OUTS.push({ name: 'info-small-things', ok: true, lines: ['info-small-things: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
