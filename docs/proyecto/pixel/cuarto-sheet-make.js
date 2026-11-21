#!/usr/bin/env node
'use strict';
/* El cuarto's sheet (place 9, La casa, un día entero, scene 1): writes docs/proyecto/pixel/cuarto-sheet.json from cuarto-set.html and the design (the orchestrator's p9-spec, general rules and section "cuarto"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/cuarto-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The beds, the night table, the armchair, the cradle, the chair, the clock, the switch and the door
   are read from the set (window.CUARTO.E), never typed again from the design.
   It loads the set in headless Chrome (cuarto-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rules. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (cuarto-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CUARTO_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'cuarto-sheet.json');
const BASE = process.env.CUARTO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/cuarto-set.html';
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

// the numbers of the design (p9-spec: the rules for every sheet, and "cuarto")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = .44, MATTRESS_Z = .5, PILLOW_TOP = .6;   // an armchair's and a chair's seat top; the mattress's top (spec); the pillow's top (the head's z); the night table's top is E.TABLE.h
const BLANKET_FROM = { lying: 24, sitting: 30 };          // the sprite row the blanket starts at: his chest (a child's torso: mkPersona tc 18 + 7 = 25), his waist (hc 18 + 2 * 7 - 2 = 30)
const BED_PX = 34;                                       // the blanket's width: the bed's (2 * hw * S = 34.3)
const SZ = { almohada: [20, 12], campana: [6, 8], plato: [12, 6], ropa: [12, 10], bebe: [14, 10], zetas: [14, 10], manta_abuelo: [16, 10], nariz: [10, 8], luz: [10, 12] };
const MOMENTS = [1, 2, 3, 4, 5, 6];
const SILKEY = { luisCama: 'luis:lie', carmenCama: 'carmen:lie', luis: 'luis', carmen: 'carmen', abuela: 'abuela', abuelaFoto: 'abuela:foto', abuelo: 'abuelo', abueloS: 'abuelo:S', coqui: 'coqui', perroS: 'perro' };   // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a shelf, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  busca_almohada: { to: [.82, 6.0, 0], why: 'things-clear: in moment 3 the frog at (1.6, 6.0) stood in front of the big pillow (almohada_suelo, 1.6, 5.4) and covered 168 of its px: u 1.6 -> .82 puts him beside it' },
  alfombra: { to: [-2.75, 5.4, 0], why: 'in moment 1 Canelo\'s nose under the bed sat on the frog\'s head: the frog goes to the rug\'s left' },
  foto: { to: [2.3, 2.3, 0], why: 'in moment 6 the shirt on the chair\'s back covered abuela\'s legs: she stands between the bed and the chair' },
  busca_silla: { to: [2.1, 4.57, 0], why: 'frog-busca: the big pillow (1.6, 5.4, in front of him) covered 52 of his px at (2.1, 5.0) in the game\'s picture (moment 3): v 5.0 -> 4.57 (-.43) is the least v that leaves him whole (u 2.1 -> 2.45 (+.35) would also pass, but v is tried first)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed, hang }
   kind: person (a character stands, sits or lies there), place (the frog's), thing (a small thing: a plate, a bell, a pillow, the baby)
   sil: which drawing hangs there (luisCama = a child lying or sitting up in a bed, hung by his highest drawn row and middle column; ninoP = a child standing; abuela, abuelaFoto, abuelo, abueloS = abuelo sitting, coqui, perroS) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle on the point, centre = its middle, at = [ax, ay]: the point is ax px from the box's left and ay px below its top
   on: the part of the set it stands on above the floor: cuarto (a mattress, a pillow, the armchair's seat, the chair, the night table, the cradle)
   fixed: the set fixes its place (a seat), so it is never moved */
function defs(E) {
  const B = E.BEDS, BED = E.BED, T = E.TABLE, A = E.ARMCHAIR, C = E.CRADLE, CH = E.CHAIR, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const bedHang = { width: BED_PX, z: MATTRESS_Z, plane: 'mattress' };
  // whoever lies or sits up in a bed: the head's place on the pillow, his sprite hung down the bed
  add('cama_luis', [B[0].u, r4(BED.v0 + .3), PILLOW_TOP], 'person', 'luisCama', 'nino', 'Luis lying in his bed (blue), or sitting up: the head\'s place on the pillow (the bed\'s u, v0 + .3, the pillow\'s top z ' + PILLOW_TOP + '); the sprite hangs DOWN the bed from it (its highest drawn row, outline included, and its middle column on the point), cut at the bed\'s foot, with the bed\'s blanket over it from his chest (lying) or his waist (sitting up)', { on: 'cuarto', hang: bedHang, bed: 0 });
  add('cama_carmen', [B[1].u, r4(BED.v0 + .3), PILLOW_TOP], 'person', 'carmenCama', 'nino', 'Carmen lying in her bed (pink), or sitting up: the head\'s place on the pillow (the bed\'s u, v0 + .3, z ' + PILLOW_TOP + '); hung down the bed as cama_luis', { on: 'cuarto', hang: bedHang, bed: 1 });
  add('sentado_luis', [B[0].u, r4(BED.v0 + .3), PILLOW_TOP], 'person', 'luisCama', 'nino', 'NOT IN THE SPEC (an alias, the script\'s Needs names it): Luis sitting up in his bed is the same place as cama_luis (the spec: "lying, or sitting up: the head\'s place")', { on: 'cuarto', hang: bedHang, bed: 0, alias: 'cama_luis' });
  add('sentado_carmen', [B[1].u, r4(BED.v0 + .3), PILLOW_TOP], 'person', 'carmenCama', 'nino', 'NOT IN THE SPEC (an alias, the script\'s Needs names it): Carmen sitting up in her bed is the same place as cama_carmen', { on: 'cuarto', hang: bedHang, bed: 1, alias: 'cama_carmen' });
  // at the beds' feet, and on Carmen's bed
  add('pie_luis', [B[0].u, 4.1, 0], 'person', 'luis', 'nino', 'Luis standing at his bed\'s foot (the bed\'s foot is v ' + BED.v1 + ')');
  add('pie_carmen', [B[1].u, 4.1, 0], 'person', 'carmen', 'nino', 'Carmen standing at her bed\'s foot');
  add('capitana', [B[1].u, 2.3, MATTRESS_Z], 'person', 'carmen', 'nino', 'Carmen standing on her bed like a captain: the mattress\'s top, z ' + MATTRESS_Z, { on: 'cuarto' });
  // the armchair
  add('butaca_abuelo', [A[0], A[1], SEAT_Z], 'person', 'abueloS', 'adulto', 'abuelo asleep in the armchair (ARMCHAIR u ' + A[0] + ', v ' + A[1] + '): on its seat\'s top, z ' + SEAT_Z + '; hung by the lap; a grown-up man (FAM.abuelo)', { on: 'cuarto', fixed: true });
  add('pie_abuelo', [A[0], r4(A[1] + 1.2), 0], 'person', 'abuelo', 'adulto', 'abuelo standing in front of the armchair (v ARMCHAIR.v + 1.2)');
  // abuela
  add('puerta', [3.15, .8, 0], 'person', 'abuela', 'adulto', 'abuela in the door (the door is u ' + E.DOOR[0] + ' to ' + E.DOOR[1] + ' on the back wall)');
  add('foto', [3.0, 1.9, 0], 'person', 'abuelaFoto', 'adulto', 'abuela with her camera, in front of the door (a plain camera drawn on her chest: the spec gives it no size)');
  // the frog
  add('alfombra', [-2.0, 5.2, 0], 'place', 'coqui', 'coqui', 'the frog on the rug (the rug is u ' + E.RUG[0] + ' to ' + E.RUG[2] + ', v ' + E.RUG[1] + ' to ' + E.RUG[3] + ')');
  add('alfombra2', [-.9, 5.6, 0], 'place', 'coqui', 'coqui', 'the frog on the rug, moved (the spec: alfombra moved to (-.9, 5.6, 0)), for story 98');
  add('mesita_coqui', [T.u, 1.7, 0], 'place', 'coqui', 'coqui', 'the frog on the floor between the beds, in front of the night table (u TABLE.u ' + T.u + ')');
  add('cama_coqui', [B[0].u, 2.8, MATTRESS_Z], 'place', 'coqui', 'coqui', 'the frog on Luis\'s bed, near its foot: the mattress\'s top, z ' + MATTRESS_Z, { on: 'cuarto' });
  add('busca_cama', [B[0].u, 3.75, 0], 'place', 'coqui', 'coqui', 'the frog looks at Luis\'s bed (just beyond its foot, v ' + BED.v1 + ')');
  add('busca_almohada', [1.6, 6.0, 0], 'place', 'coqui', 'coqui', 'the frog looks near the big pillow on the floor (almohada_suelo is at v 5.4)');
  add('busca_silla', [2.1, 5.0, 0], 'place', 'coqui', 'coqui', 'the frog looks near the chair (CHAIR u ' + CH[0] + ', v ' + CH[1] + ')');
  add('silla_coqui', [2.0, 5.0, 0], 'place', 'coqui', 'coqui', 'the frog at the chair (the spec: on the chair; its own place is on the floor in front of it, z 0)');
  // the big pillow, and the clothes
  add('almohada_suelo', [1.6, 5.4, 0], 'thing', null, null, 'the big pillow on the floor (a ' + SZ.almohada.join(' x ') + ' px stand-in): its bottom middle on the point', { size: SZ.almohada, anchor: 'bottom' });
  add('vestir', [-2.0, 5.0, 0], 'person', 'luis', 'nino', 'Luis on the rug, dressing');
  // Canelo
  add('bajo_cama', [r4(B[0].u - .4), r4(BED.v1 + .1), 0], 'thing', null, null, 'only Canelo\'s nose under Luis\'s bed, at its foot (a ' + SZ.nariz.join(' x ') + ' px stand-in): its bottom middle on the point', { size: SZ.nariz, anchor: 'bottom' });
  add('junto_mesita', [T.u, 3.9, 0], 'person', 'perroS', 'perro', 'Canelo sitting by the night table, in front of it (his sprite is 28 wide)');
  // on the night table
  add('campana', [r4(T.u - .18), T.v, T.h], 'thing', null, null, 'the bell on the night table (a ' + SZ.campana.join(' x ') + ' px stand-in): its bottom middle on the table\'s top, z TABLE.h ' + T.h, { size: SZ.campana, anchor: 'bottom', on: 'cuarto' });
  add('plato', [r4(T.u + .16), T.v, T.h], 'thing', null, null, 'the plate on the night table (a ' + SZ.plato.join(' x ') + ' px stand-in: three pieces of bread): its bottom middle on the table\'s top, z ' + T.h, { size: SZ.plato, anchor: 'bottom', on: 'cuarto' });
  // on the chair
  add('ropa_a', [CH[0], CH[1], SEAT_Z], 'thing', null, null, 'a thing on the chair\'s seat (a ' + SZ.ropa.join(' x ') + ' px stand-in): its bottom middle on the seat\'s top, z ' + SEAT_Z, { size: SZ.ropa, anchor: 'bottom', on: 'cuarto', fixed: true });
  add('ropa_b', [CH[0], r4(CH[1] - .18), 1.08], 'thing', null, null, 'a thing over the chair\'s back (a ' + SZ.ropa.join(' x ') + ' px stand-in): its bottom middle on the back\'s top, z 1.08 at v CHAIR.v - .18', { size: SZ.ropa, anchor: 'bottom', on: 'cuarto', fixed: true });
  // in the cradle
  add('bebe', [C.u, C.v, .4], 'thing', null, null, 'the baby asleep in the cradle (a ' + SZ.bebe.join(' x ') + ' px stand-in): its bottom middle on the cradle\'s bed, z .4 (CRADLE u ' + C.u + ', v ' + C.v + ')', { size: SZ.bebe, anchor: 'bottom', on: 'cuarto', fixed: true });
  add('zetas', [C.u, C.v, 1.3], 'thing', null, null, 'the baby\'s three Z\'s over the cradle (a ' + SZ.zetas.join(' x ') + ' px stand-in): its bottom middle on the point, z 1.3 (in the air: no surface)', { size: SZ.zetas, anchor: 'bottom', air: true });
  // the blanket on abuelo's knees: not a spot of the spec; its place is the knees of whoever sits at butaca_abuelo
  add('manta_abuelo', [A[0], A[1], SEAT_Z], 'thing', null, null, 'the blanket on abuelo\'s knees (a ' + SZ.manta_abuelo.join(' x ') + ' px stand-in): the point is the lap\'s (his seat\'s top); the box is 8 px either side of it and from 6 px above it to 4 px below (his knees)', { size: SZ.manta_abuelo, anchor: 'at', at: [8, 6], on: 'cuarto', fixed: true, held: 'butaca_abuelo' });
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on a seat, the table, a mattress, the cradle, the chair are on what the set draws),
   things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (the head of everyone who sits or lies covered by nobody and by nothing),
   heads-pillow (the heads of whoever lies or sits up in a bed are on the pillow's pixels), frog-mesita (the frog in front of the night table covers neither the bell nor the plate), things-clear (the bell, the plate, the switch,
   the big pillow and the two things on the chair covered by nobody in their moments), canelo-frog (Canelo by the night table does not cover the frog), frog-busca (the frog at busca_cama, busca_almohada and busca_silla whole).
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  // the set with everything in it (the cradle, the armchair): the spots' pixels are read from this one (every state draws the same geometry; the light only changes the colours)
  await page.goto(PAGE + '?tags=1&hora=manana&luz=1&cuna=1&butaca=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(CUARTO.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
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

/* ---------- the preview's moments: cuarto-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/cuarto-preview.html?nodraw=1');
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
const boxOn = (sx, sy, size, anchor, at) => {
  const [w, h] = size, x = anchor === 'at' ? sx - at[0] : sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h : anchor === 'at' ? sy - at[1] : sy - Math.floor(h / 2), w, h];
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
  const E = G.E, sc = G.scene, DEF = defs(E), BED = E.BED;
  // whoever lies or sits up in a bed hangs down it to the bed's foot: the mattress's front face's bottom edge (z .34, v v1 - .02): the rows between the head's row and it
  const foot = (await proj([[E.BEDS[0].u, r4(BED.v1 - .02), .34]]))[0];
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor, d.at); o.anchor = d.anchor === 'at' ? 'knees' : d.anchor; if (d.anchor === 'at') o.at = d.at; }
    if (d.hang) { const rows = Math.ceil(foot[1]) - sy; o.anchor = 'top'; o.hang = Object.assign({ rows, bed: d.bed, foot: Math.ceil(foot[1]), blanketFrom: BLANKET_FROM }, d.hang); }
    if (d.uvz[2] > 0) o.on = d.air ? 'air' : (d.on || 'ground');
    if (d.fixed) o.fixed = 1;
    if (d.air) o.air = 1;
    if (d.held) o.held = d.held;
    if (d.alias) o.alias = d.alias;
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [96, 97, 98], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 96, 97 and 98: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
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
  const B = E.BEDS, hw = BED.hw, vm = (BED.v0 + BED.v1) / 2 + .06, hdm = (BED.v1 - BED.v0) / 2 - .08, L = E.LIGHT, CK = E.CLOCK, CH = E.CHAIR, C = E.CRADLE;
  const things = {};
  // cama: Luis's mattress (CS.bed: the cover box z .34 to .5, hw - .04 across, from v vm - hdm to vm + hdm)
  things.cama = await setThing(r4(B[0].u - (hw - .04)), r4(vm - hdm), .34, r4(B[0].u + (hw - .04)), r4(vm + hdm), MATTRESS_Z, 'Luis\'s bed: its mattress\'s box on the picture (u ' + r4(B[0].u - (hw - .04)) + ' to ' + r4(B[0].u + (hw - .04)) + ', v ' + r4(vm - hdm) + ' to ' + r4(vm + hdm) + ', z .34 to ' + MATTRESS_Z + '); a poke');
  // luz: the switch's box, made 10 x 12 px around the switch (LIGHT.sw: u, z on the wall)
  { const q = (await proj([[L.sw[0], 0, L.sw[1]]]))[0], sx = Math.round(q[0]), sy = Math.round(q[1]), b = [sx - 5, sy - 6, SZ.luz[0], SZ.luz[1]];
    things.luz = { set: true, uv: W4([L.sw[0], 0, L.sw[1]]), world: W4([q[3], q[4], L.sw[1]]), box: b, what: 'the wall light\'s switch (LIGHT.sw: u ' + L.sw[0] + ', z ' + L.sw[1] + ', on the wall v 0), its box made ' + SZ.luz.join(' x ') + ' px, centred on the switch; a poke' }; }
  // silla: the chair's box (its posts, seat and back: u CHAIR.u +- .2, v from the back's post to the seat's front edge, z 0 to the back's top 1.08)
  things.silla = await setThing(r4(CH[0] - .2), r4(CH[1] - .18 - .028), 0, r4(CH[0] + .2), r4(CH[1] + .2), 1.08, 'the chair (CHAIR u ' + CH[0] + ', v ' + CH[1] + '): its box, from the floor to the back\'s top z 1.08; a poke');
  // reloj: the wall clock's box (CS.clockAt: radius 7.5 px)
  things.reloj = await setThing(r4(CK[0] - 7.5 / G.S), 0, r4(CK[1] - 7.5 / (G.S * COS)), r4(CK[0] + 7.5 / G.S), 0, r4(CK[1] + 7.5 / (G.S * COS)), 'the wall clock (CLOCK u ' + CK[0] + ', z ' + CK[1] + ': radius 7.5 px: its hands are sprites); a poke');
  // cuna: the cradle's box (the bed of slats, its sides and its rockers)
  things.cuna = await setThing(r4(C.u - C.hw - .08), r4(C.v - C.hd), 0, r4(C.u + C.hw + .08), r4(C.v + C.hd + .02), .95, 'the cradle in the right back corner (CRADLE u ' + C.u + ', v ' + C.v + '): its rockers, bed and sides (z 0 to .95); a poke. Present only with cuna = 1');
  // manta_luis, manta_carmen: each bed's blanket, from v BED.v0 + 1.1 to BED.v1 on the mattress's top, the bed's width
  for (const [n, k] of [['manta_luis', 0], ['manta_carmen', 1]]) things[n] = await setThing(r4(B[k].u - hw), r4(BED.v0 + 1.1), MATTRESS_Z, r4(B[k].u + hw), BED.v1, MATTRESS_Z, 'the blanket of ' + (k ? 'Carmen\'s' : 'Luis\'s') + ' bed (a sprite: on, or pulled off): its box on the picture from v BED.v0 + 1.1 = ' + r4(BED.v0 + 1.1) + ' to v BED.v1 = ' + BED.v1 + ', the bed\'s width (u ' + r4(B[k].u - hw) + ' to ' + r4(B[k].u + hw) + '), on the mattress\'s top z ' + MATTRESS_Z + '; a poke');
  const touch = { almohada: 'almohada_suelo', campana: 'campana', plato: 'plato', ropa_a: 'ropa_a', ropa_b: 'ropa_b', manta_abuelo: 'manta_abuelo' };
  for (const k of Object.keys(touch)) things[k] = 'sprite';
  for (const k of ['luis', 'carmen', 'abuela', 'abuelo', 'bebe', 'perro', 'coqui']) things[k] = 'sprite';

  // the pillows (CS.bed: u +- (hw - .2), v v0 + .2 to v0 + .64, z .5 to .6): their screen rectangle, for the check that a head lies on it
  const pill = await Promise.all(B.map(async b => { const c = await proj([[b.u - (hw - .2), BED.v0 + .2, PILLOW_TOP], [b.u + (hw - .2), BED.v0 + .64, MATTRESS_Z]]); return { x: [c[0][0], c[1][0]], y: [c[0][1], c[1][1]], u: [r4(b.u - (hw - .2)), r4(b.u + (hw - .2))], v: [r4(BED.v0 + .2), r4(BED.v0 + .64)] }; }));

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'cuarto',
    made: 'node docs/proyecto/pixel/cuarto-sheet-make.js, from cuarto-set.html (window.CUARTO.E) and the design of El cuarto (the orchestrator\'s p9-spec, general rules and section cuarto). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    beds: E.BEDS.map(b => b.c), pillows: pill.map(p => ({ screen: [r2(p.x[0]), r2(p.y[0]), r2(p.x[1]), r2(p.y[1])], u: p.u, v: p.v, z: [MATTRESS_Z, PILLOW_TOP] })),
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5167 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. The beds are at u ' + E.BEDS.map(b => b.u).join(' and ') + ' (heads at v ' + BED.v0 + ', feet at v ' + BED.v1 + ', hw ' + BED.hw + '), the night table at u ' + E.TABLE.u + ', the armchair at (' + E.ARMCHAIR.join(', ') + '), the cradle at (' + C.u + ', ' + C.v + '), the chair at (' + CH.join(', ') + ')',
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + SEAT_Z + ': a seat\'s top; z ' + MATTRESS_Z + ': a mattress\'s top; z ' + PILLOW_TOP + ': a pillow\'s top, the head\'s place; z ' + E.TABLE.h + ': the night table\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the bell, the plate, the big pillow, the clothes, the baby, the Z\'s and the nose have their bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]); the blanket on abuelo\'s knees is 8 px either side of the spot and from 6 px above it to 4 px below. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), a child 43 rows; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30 (her middle) and her bottom edge; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy); Canelo sitting (KIT.mkPerro, 30 x 22): the middle of his drawn columns and his bottom edge. WHOEVER LIES OR SITS UP IN A BED (cama_luis, cama_carmen): the standing sprite hangs DOWN the bed from the head\'s place: its highest drawn row (outline included: canvas row 2 for a child) and its middle column 24 on (sx, sy); only the rows from there down to the bed\'s foot are drawn (' + spots.cama_luis.hang.rows + ' rows: the mattress\'s front face\'s bottom edge is row ' + spots.cama_luis.hang.foot + '), and over them from his chest (sprite row ' + BLANKET_FROM.lying + ', lying) or his waist (row ' + BLANKET_FROM.sitting + ', sitting up) to the foot a blanket of the bed\'s colour and the bed\'s width (' + BED_PX + ' px). Nobody is drawn turned',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character; front.hung is the rule for whoever lies in a bed',
    },
    setKey: {
      params: { hora: { values: ['alba', 'manana'], note: 'the window and the room\'s light (alba: dim, unless the wall light is on)' }, luz: { values: [0, 1], note: 'the wall light off | on' }, cuna: { values: [0, 1], note: 'the cradle in the right back corner' }, butaca: { values: [0, 1], note: 'the armchair at the far left' } },
      key: 'hora, luz, cuna, butaca, e.g. "alba|0|0|0"',
      baked: ['?hora=alba&luz=0&cuna=0&butaca=0', '?hora=alba&luz=1&cuna=0&butaca=0', '?hora=manana&luz=0&cuna=1&butaca=1', '?hora=manana&luz=0&cuna=0&butaca=0'],
    },
    things,
    spots,
    groups: {
      camas: ['cama_luis', 'cama_carmen'], pies: ['pie_luis', 'pie_carmen', 'pie_abuelo'], busca: ['busca_cama', 'busca_almohada', 'busca_silla'], coqui: ['alfombra', 'alfombra2', 'mesita_coqui', 'cama_coqui', 'busca_cama', 'busca_almohada', 'busca_silla', 'silla_coqui'],
      mesita: ['campana', 'plato'], silla: ['ropa_a', 'ropa_b'], cuna: ['bebe', 'zetas'], perro: ['bajo_cama', 'junto_mesita'],
      touch: Object.assign({}, touch, { luis: 'cama_luis', carmen: 'cama_carmen', abuela: 'puerta', abuelo: 'butaca_abuelo', bebe: 'bebe', perro: 'junto_mesita', coqui: 'mesita_coqui' }),
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p9-spec, "cuarto"), given in (u, v, z); the beds, the night table, the armchair, the cradle, the chair, the switch, the clock and the door are read from the set',
      'things: cama, luz, silla, reloj and cuna are boxes of the set; manta_luis and manta_carmen are boxes on the picture from v BED.v0 + 1.1 to BED.v1 (the blankets are sprites: on, or pulled off); almohada, campana, plato, ropa_a, ropa_b and manta_abuelo are sprites at the spots groups.touch names; the people are sprites. NOT IN THE SPEC, made for the preview and its checks: sentado_luis and sentado_carmen (aliases of the two head places: the script\'s Needs names them), the spots bebe, zetas, manta_abuelo (the blanket on abuelo\'s knees: 16 x 10, 8 px either side of the lap, from 6 px above to 4 px below it) and the thing cuna',
      'whoever lies or sits up in a bed (cama_luis, cama_carmen) is the standing sprite hung by the top of his head and cut at the bed\'s foot, with a blanket of the bed\'s colour over it; he lies on his mattress, so his depth plane is the mattress\'s (front.hung)',
      'the spec gives no shadow radius: El cruce\'s and El calendario\'s are used (frog .45, grown-ups .35, children .28, Canelo .3); whoever lies, sits in the armchair or stands on the bed (z above 0) casts none',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the armchair\'s seat hides the shins of whoever sits in it, the night table\'s front hides what stands behind it.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El pedido\'s: the upright plane through the feet',
      hung: 'whoever lies or sits up in a bed (the spots with a hang): he lies on his mattress, so for his pixel on picture row r: depth(r) = (2 * COS / S) * (r + .5 - OY) + 2 * z0, with z0 = ' + MATTRESS_Z + ' (the mattress\'s top: the plane of a horizontal surface at that height), tested against the baked depth with the same bias. The upright rule would put the rows below his head BEHIND the mattress (they hang down the bed: nearer the camera, with a lower plane), and hide his body',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s and El calendario\'s (open point)',
      none: DEF.filter(d => d.uvz[2] > 0 || d.hang).map(d => d.name),
      onSeat: 'whoever lies in a bed, sits in the armchair, stands on the bed or on the chair (z above 0) casts none: none of those is floor (a shadow cast at the floor under them would show in front of them); the beds cast their own (CS.bed)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot (the baked depth and the part), 5 columns and 6 rows around it
  const spotsPx = await page.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 3; dy++) for (let dx = -2; dx <= 2; dx++) {
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
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && (b.plane > p[3] + EPS || (b.plane >= p[3] - EPS && b.i > t)) && (!nearest || b.plane > nearest.plane)) nearest = b;
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

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, Canelo 28; and his rows from the drawn silhouette; a small thing's box)
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

  // 3. the spots above the floor are on what the set draws: a mattress, a pillow, the armchair's seat, the chair's seat and back, the night table's top, the cradle's bed: part cuarto, the set's depth at the spot's own
  //    (within .1 of the spot's depth, in the pixels around it: a chair's back is a slat, the cradle's bed shows between its slats); a spot in the air (the Z's) has no surface
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (s.air || !s.on || s.on === 'ground') continue;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 2).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === s.on && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ') at (' + best.r.dx + ', ' + best.r.dy + ') from it' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + s.on + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    // the heights the spec says: a seat's top .44 is the armchair's and the chair's own; the mattress's top .5 and the pillow's .6 are CS.bed's; the night table's top is E.TABLE.h; the cradle's bed is .4 (CUARTO set: PZ.box(C.u, C.v, .3, .4))
    const hs = [['butaca_abuelo', SEAT_Z], ['ropa_a', SEAT_Z], ['capitana', MATTRESS_Z], ['cama_coqui', MATTRESS_Z], ['cama_luis', PILLOW_TOP], ['cama_carmen', PILLOW_TOP], ['campana', E.TABLE.h], ['plato', E.TABLE.h], ['bebe', .4]];
    for (const [k, z] of hs) if (S[k].uv[2] !== z) bad.push(k + ': z ' + S[k].uv[2] + ' is not the set\'s ' + z);
    add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface the set draws (part cuarto, the set\'s depth within .1 of the spot\'s): a seat\'s top z ' + SEAT_Z + ', the mattress\'s z ' + MATTRESS_Z + ', the pillow\'s z ' + PILLOW_TOP + ', the night table\'s z ' + E.TABLE.h + ' (the set\'s own pixel under the bell and the plate), the chair\'s back z 1.08, the cradle\'s bed z .4', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l)).lines.push(...lines.map(l => '       ' + l));
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
    add('things-in-view', bad, 'the boxes of ' + lines.join(', ') + ' are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, Canelo 28; the feet's spot in the middle; whoever lies in a bed: the bed's foot) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.fy - b.fy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.fy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.fy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.fy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name]; if (s.fixed) return 'fixed by the set (a seat): not moved';
      const res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the ' + MOMENTS.length + ' moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in ' + MOMENTS.length + ' moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
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
    const o = add('frog-seen', bad, 'the frog is seen whole in all ' + MOMENTS.length + ' moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. heads-clear: everyone who sits or lies (abuelo in the armchair, Luis and Carmen in their beds) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'cama' && l.group !== 'butaca') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'everyone who sits or lies (' + MOMENTS.map(m => 'm' + m + ': ' + (PV.inspect[m].layers.filter(l => l.group === 'cama' || l.group === 'butaca').map(l => l.at).join(', ') || 'none')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the heads of those who sit or lie:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. heads-pillow: the head of whoever lies or sits up in a bed is on the pillow's pixels: the spot (his head's highest drawn row, middle column) is a pixel of the pillow (its rectangle on the picture, PZ.box u +- (hw - .2), v v0 + .2 to v0 + .64, z .5 to .6),
  //    every column of his head is a column of the pillow, and the set's pixel under the spot is the pillow's (part cuarto, the pillow's depth: spots-on-surface). How many of his 14 head rows' pixels lie on the pillow and how many below it (the pillow is 8 rows deep on the picture) are reported
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers;
      for (const l of L) {
        if (l.group !== 'cama') continue;
        const k = S[l.at].hang.bed, P = sheet.pillows[k], [px0, py0, px1, py1] = P.screen, top = Math.min(...l.px.map(p => p[1])), head = l.px.filter(p => p[1] < top + HEAD_ROWS && !p[2]);
        const on = head.filter(p => p[0] + .5 > px0 && p[0] + .5 < px1 && p[1] + .5 > py0 && p[1] + .5 < py1).length, spotOn = l.sx + .5 > px0 && l.sx + .5 < px1 && l.sy + .5 > py0 && l.sy + .5 < py1;
        const cols = [Math.min(...head.map(p => p[0])), Math.max(...head.map(p => p[0]))], within = cols[0] + .5 > px0 && cols[1] + .5 < px1;
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': the pillow\'s rectangle x ' + px0 + ' to ' + px1 + ', y ' + py0 + ' to ' + py1 + '; the spot is ' + (spotOn ? 'on' : 'OFF') + ' it; head columns ' + cols[0] + ' to ' + cols[1] + ' ' + (within ? 'inside' : 'OUTSIDE') + ' its columns; ' + on + ' of the ' + head.length + ' shown head pixels are on the pillow\'s rectangle, ' + (head.length - on) + ' below it (on the mattress)');
        if (!spotOn || !within) bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (spotOn ? '' : 'the spot is not on the pillow\'s rectangle (x ' + px0 + ' to ' + px1 + ', y ' + py0 + ' to ' + py1 + '); ') + (within ? '' : 'his head\'s columns ' + cols[0] + ' to ' + cols[1] + ' are not inside the pillow\'s'));
      }
    }
    const o = add('heads-pillow', bad, 'in every moment someone lies or sits up in a bed (m1 to m4) the spot of his head (the sprite\'s highest drawn row, middle column) is a pixel of the pillow and his head\'s columns are inside the pillow\'s; the set\'s pixel under the spot is the pillow\'s (spots-on-surface)', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 9. frog-mesita: the frog at mesita_coqui covers neither the bell nor the plate: no shown pixel of his inside either thing's box, and neither thing (when drawn) has a pixel under a nearer frog pixel (any moment he is there)
  {
    const bad = [], lines = [], hints = [], boxes = { campana: S.campana.box, plato: S.plato.box };
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, i = idxAt(L, 'mesita_coqui'); if (i < 0) continue;
      const M = planes(L), f = L[i], ns = Object.entries(boxes).map(([n, b]) => [n, shownIn(L, i, b)]), things = L.map((l, j) => [l, j]).filter(([l]) => l.group === 'campana' || l.group === 'plato').map(([l, j]) => ({ at: l.at, c: coverOf(L, M, j, [i]) }));
      lines.push('m' + m + ': the frog\'s top row ' + Math.min(...f.px.map(p => p[1])) + ' (the bell\'s box [' + boxes.campana + '], the plate\'s [' + boxes.plato + ']): ' + ns.map(([n, c]) => c + ' px of his in the ' + n + '\'s box').join(', ') + '; covered by him: ' + (things.map(t => t.at + ' ' + t.c.cov).join(', ') || 'neither drawn'));
      for (const [n, c] of ns) if (c) { bad.push('moment ' + m + ': the frog at mesita_coqui ' + [f.sx, f.sy] + ' has ' + c + ' px inside the ' + n + '\'s box [' + boxes[n] + ']'); hints.push([m, i]); }
      for (const t of things) if (t.c.cov) bad.push('moment ' + m + ': the frog covers ' + t.c.cov + ' px of ' + t.at);
    }
    const o = add('frog-mesita', bad, 'the frog at mesita_coqui ' + S.mesita_coqui.screen + ' covers neither the bell nor the plate (m2, m4, m5): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of hints) { const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, Object.values(boxes)); o.lines.push('       nearest passing, moment ' + m + ' mesita_coqui ' + S.mesita_coqui.uv + ': ' + axisTxt(r, 'mesita_coqui')); }
  }

  // 10. things-clear: the bell (m4), the plate (m1 to m3), the big pillow (m2, m3) and the two things on the chair (m6) are covered by nobody (no sprite pixel nearer over theirs, none hidden by the set) and stand where the set has a surface
  //     (spots-on-surface); the switch (its 10 x 12 box) has no shown pixel of anybody in it in any moment
  {
    const bad = [], lines = [], hints = [], sw = T.luz.box, WHICH = { campana: [4], plato: [1, 2, 3], almohada: [2, 3], ropa: [6] };
    for (const [g, ms] of Object.entries(WHICH)) for (const m of ms) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== g) continue;
        const c = coverOf(L, M, i, null), onSurf = !S[l.at].on || S[l.at].on === 'ground' || surf.includes(l.at);
        lines.push('m' + m + ' ' + l.at + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture');
        if (c.cov || c.hid || c.out || !onSurf) { bad.push('moment ' + m + ' ' + l.at + ' ' + S[l.at].screen + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture' + (onSurf ? '' : '; not on a surface')); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), l.at, w]); }
      }
    }
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, hits = [];
      for (const [i, l] of L.entries()) { const c = shownIn(L, i, sw); if (c) hits.push([l.at, c, i]); }
      lines.push('m' + m + ': the switch\'s box [' + sw + ']: ' + (hits.length ? hits.map(h => h[0] + ' ' + h[1] + ' px').join(', ') : '0 px of anyone in it'));
      for (const h of hits) { bad.push('moment ' + m + ': ' + h[0] + ' ' + S[h[0]].screen + ' has ' + h[1] + ' px inside the switch\'s box [' + sw + ']'); hints.push([m, h[2], 'luz', h[0]]); }
    }
    const o = add('things-clear', bad, 'the bell (m4), the plate (m1 to m3), the big pillow (m2, m3) and the two things on the chair (m6) are covered by nobody, and nobody has a pixel in the switch\'s box in the six moments: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, thing, cat] of hints) {
      const M = PV.moment[m]; if (ci < 0) continue;
      const r = thing === 'luz' ? await PV.nearestFree(M.set, M.layers, ci, [sw]) : await PV.nearestClear(M.set, M.layers, ci, [idxAt(M.layers, thing)], null);
      o.lines.push('       nearest passing, moment ' + m + ' (' + thing + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat));
    }
  }

  // 11. canelo-frog: Canelo at junto_mesita covers none of the frog (m2, m3)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, di = idxAt(L, 'junto_mesita'); if (di < 0) continue;
      const M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), c = coverOf(L, M, fi, [di]);
      lines.push('m' + m + ': the frog at ' + L[fi].at + ' ' + [L[fi].sx, L[fi].sy] + ', Canelo at junto_mesita ' + S.junto_mesita.screen + ': ' + c.cov + ' of his ' + c.tot + ' px under Canelo');
      if (c.cov) { bad.push('moment ' + m + ': Canelo covers ' + c.cov + ' px of the frog'); hints.push([m, di, fi]); }
    }
    const o = add('canelo-frog', bad, 'Canelo at junto_mesita ' + S.junto_mesita.screen + ' covers none of the frog (m2, m3): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, di, fi] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, di, [fi], null); o.lines.push('       nearest passing, moment ' + m + ' junto_mesita ' + S.junto_mesita.uv + ': ' + axisTxt(r, 'junto_mesita')); }
  }

  // 12. frog-busca: the frog at busca_cama, busca_almohada and busca_silla is whole (no pixel hidden by the set or under a person or a thing): in the game's picture (moment 3: Luis sitting up, Carmen lying, the big pillow on the floor, the plate, Canelo);
  //     and, not a check of the spec, the frog at cama_coqui (moment 1's picture) and silla_coqui (moment 6's picture) the same way
  {
    const bad = [], lines = [], info = [], fails = [];
    const ctx = async (m, at) => { const M = PV.moment[m], specs = M.layers.map(l => l.who === 'coqui' ? Object.assign({}, l, { at }) : l), L = await PV.layers(M.set, specs), fi = L.findIndex(l => l.who === 'coqui'); return { M, specs, L, fi }; };
    for (const [at, m, isCheck] of [['busca_cama', 3, 1], ['busca_almohada', 3, 1], ['busca_silla', 3, 1], ['cama_coqui', 1, 0], ['silla_coqui', 6, 0]]) {
      const { M, specs, L, fi } = await ctx(m, at), P = planes(L), f = L[fi], c = coverOf(L, P, fi, null);
      const line = 'the frog at ' + at + ' ' + [f.sx, f.sy] + ' in the picture of moment ' + m + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture';
      (isCheck ? lines : info).push(line);
      if (isCheck && (c.hid || c.cov || f.out)) { bad.push(at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([at, M, specs, fi]); }
    }
    const o = add('frog-busca', bad, 'the frog at busca_cama, busca_almohada and busca_silla is whole (0 px hidden or covered), in the game\'s picture: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [at, M, specs, fi] of fails) { const r = await PV.nearest(M.set, specs, fi); o.lines.push('       nearest passing, ' + at + ' ' + S[at].uv + ': ' + axisTxt(r, at)); }
    o.lines.push('       info, not a check of the spec: ' + info.join('; '));
  }

  // info: the things he can touch that the spec lists no check for (the baby, the Z's, the blanket on abuelo's knees, Canelo's nose), the people over the pillows and the bed things: not checks of the spec
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const [i, l] of L.entries()) if (['bebe', 'zetas', 'manta', 'nariz'].includes(l.group)) { const c = coverOf(L, M, i, null); parts.push(l.at + ' ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); }
      lines.push('m' + m + ': ' + (parts.join(', ') || 'none of them drawn'));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
