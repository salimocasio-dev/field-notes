#!/usr/bin/env node
'use strict';
/* La sala, de día's sheet (place 9, La casa, un día entero, scene 3; stories 102, 103, 104): writes docs/proyecto/pixel/sala_dia-sheet.json from sala_dia-set.html and the design
   (the orchestrator's p9-spec: the rules for every sheet, and "sala_dia"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/sala_dia-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The desk, the computer's screen, the chair behind the desk, the low table, the cushions, the armchair,
   the small table and the window are read from the set (window.SALA_DIA.E), never typed again from the design.
   It loads the set in headless Chrome (sala_dia-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette): abuelo's ear and mouth boxes are placed on his drawn head. The checks that say "covers" or "shows"
   read the PREVIEW's moments (sala_dia-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks (and without abuelo's two boxes), the preview reads it,
   and then the sheet is written again with the boxes and the checks.
   Then it prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with SALA_DIA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'sala_dia-sheet.json');
const BASE = process.env.SALA_DIA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/sala_dia-set.html';
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

// the numbers of the design (p9-spec: the rules for every sheet, and "sala_dia")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const CHEST_ROW = { adulto: 29, nino: 25 };              // "the chest": the torso's centre row of the sprite (mkPersona tc = 18 + t, t 11 a grown-up, 7 a child): the low table may hide a child only from this row down (the spec gives the word, not the row: open point)
const SEAT_Z = .44, CUSHION_Z = .12;                     // a chair's, an armchair's top; a cushion's top
const PHOTO_UP = 8;                                      // the photo in Carmen's hands: its bottom edge 8 px above her lap
const SZ = { libro: [12, 8], papel: [12, 8], telefono: [10, 6], pagina: [16, 12], estrellas: [8, 6], foto: [10, 8] };      // the spec's sizes of the small things
const BOX = { oreja: [12, 10], boca: [12, 10] };         // abuelo's two boxes
const MOMENTS = [1, 2, 3, 4, 5];
const SILKEY = { abuela: 'abuela', abueloS: 'abuelo.S', luisS: 'luis.S', carmenS: 'carmen.S', coqui: 'coqui' };       // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  brazo_coqui: { to: [1.68, 2.6, .55], why: 'frog-seen, moments 3 and 4: at the table\'s middle (u 1.6, v 2.85) 19 of the frog\'s 536 px (his left foot) were under Carmen\'s right braid at cojin2 (she is nearer the camera). No move along v alone passes (the first v that does, 2.37, is off the small table\'s top, v 2.49 to 3.21), and the only move along u alone that passes (u 1.6 -> 1.75) fails sprites-apart (the frog at column 166, abuelo at 192, feet on the same row: 26 px across, 28 needed). The least move in u and v together that passes every check, found by scanning the table\'s top in steps of .01: u +.08 and v -.25 (.262 from the middle, inside the top\'s radius .36): u 1.6 -> 1.68, v 2.85 -> 2.6, z .55 kept. OPEN POINT: a move in two axes is not what the brief names (v first, then u)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed }
   kind: person (a character sits or stands there), place (the frog's), thing (a small thing: its box)
   sil: which drawing hangs there (abuela = a grown-up woman standing, abueloS = a grown-up man sitting, luisS / carmenS = a child sitting, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle on the point, centre = its middle
   on: the part of the set it stands on above the floor: cojin, silla (the desk's chair), butaca, mesa (the low table's top), mesita (the small table's top)
   fixed: the set fixes its place (a seat), so it is never moved */
function defs(E) {
  const L = E.LOW, SD = E.SIDE, D = [], tv = r4(L.v + .05);
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  // the seats
  add('cojin1', [E.CUSHIONS[0][0], E.CUSHIONS[0][1], CUSHION_Z], 'person', 'luisS', 'nino', 'the first cushion (E.CUSHIONS[0]) along the low table\'s far side: Luis sitting on it (a child hung by the lap), its top z ' + CUSHION_Z, { on: 'cojin', fixed: 1 });
  add('cojin2', [E.CUSHIONS[1][0], E.CUSHIONS[1][1], CUSHION_Z], 'person', 'carmenS', 'nino', 'the second cushion (E.CUSHIONS[1]): Carmen sitting on it (a child hung by the lap), its top z ' + CUSHION_Z, { on: 'cojin', fixed: 1 });
  add('escritorio', [r4(E.DESKSEAT[0]), r4(E.DESKSEAT[1]), SEAT_Z], 'person', 'luisS', 'nino', 'the chair behind the desk (E.DESKSEAT: FD.chair\'s place): Luis sitting on it, facing us, its seat\'s top z ' + SEAT_Z, { on: 'silla', fixed: 1 });
  add('butaca', [r4(E.ARMCHAIR[0]), r4(E.ARMCHAIR[1]), SEAT_Z], 'person', 'abueloS', 'adulto', 'the armchair (E.ARMCHAIR: CS.armchair\'s place): abuelo sitting in it (a grown-up man, hung by the lap), its seat\'s top z ' + SEAT_Z, { on: 'butaca', fixed: 1 });
  // abuela
  add('estante', [1.8, 1.0, 0], 'person', 'abuela', 'adulto', 'abuela on the floor in front of the shelf of books (the shelf runs from u ' + E.SHELF.u0 + ' to ' + E.SHELF.u1 + ', its front is v ' + r4(E.SHELF.hd * 2) + ')');
  add('cocina', [3.22, .7, 0], 'person', 'abuela', 'adulto', 'abuela in the kitchen\'s door (the door runs from u ' + E.DOOR[0] + ' to ' + E.DOOR[1] + ', in the back wall)');
  add('ventana_abuela', [-.3, 1.0, 0], 'person', 'abuela', 'adulto', 'abuela by the window (the window runs from u ' + E.WINDOW[0] + ' to ' + E.WINDOW[1] + ')');
  // the frog
  add('junto_mesa_coqui', [-1.75, 4.7, 0], 'place', 'coqui', 'coqui', 'the frog on the floor at the low table\'s left end (the table runs from u ' + r4(L.u - L.hw) + ' to ' + r4(L.u + L.hw) + ', v ' + r4(L.v - L.hd) + ' to ' + r4(L.v + L.hd) + ')');
  add('brazo_coqui', [SD.u, SD.v, SD.h], 'place', 'coqui', 'coqui', 'the frog on the small table\'s top (SIDE u ' + SD.u + ', v ' + SD.v + ', its top z ' + SD.h + '), beside abuelo\'s head', { on: 'mesita' });
  // on the low table (z LOW.h, v LOW.v + .05)
  const thing = (name, u, size, what, more) => add(name, [u, tv, L.h], 'thing', null, null, what + ' (a ' + size.join(' x ') + ' px stand-in): its bottom middle on the low table\'s top, z ' + L.h + ', v ' + tv, Object.assign({ size, anchor: 'bottom', on: 'mesa' }, more || {}));
  thing('libro', 0, SZ.libro, 'the book');
  thing('papel', .75, SZ.papel, 'Carmen\'s pad of paper');
  thing('telefono', 1.3, SZ.telefono, 'the telephone');
  thing('pagina1', -.25, SZ.pagina, 'the album\'s first page (the morning)');
  thing('pagina2', .4, SZ.pagina, 'the album\'s second page (the afternoon)');
  thing('pagina3', 1.05, SZ.pagina, 'the album\'s third page (the night)');
  thing('estrellas', -.85, SZ.estrellas, 'the box of stars');
  for (const d of D) if (MOVES[d.name] && MOVES[d.name].to[2] !== d.uvz[2]) throw new Error('MOVES.' + d.name + ' changes z: never');
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the seats are drawn tops at the spots' depth; the things on the low table
   and the frog on the small table are on what the set draws), things-in-view (the boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (the head of everyone
   who sits covered by nobody and by nothing), low-table (it hides the children on the cushions only below the chest), desk-head (Luis at the desk), touch-clear (the book, the pad, the telephone, the pages, the stars),
   frog-brazo (the frog beside abuelo's head covers neither of his boxes; each box holds his pixels or touches them).
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(SALA_DIA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // a second copy of the set, to draw the seats and the small table alone: in the picture the low table is in front of the cushions, so the set's pixel under a sitter's spot is the table's
  const pp = await browser.newPage();
  pp.on('pageerror', e => errs.push(String(e)));
  await pp.route(BASE + '/**', serve);
  await pp.goto(PAGE + '?tags=1');
  G.alone = await pp.evaluate(E => {
    const px = (u, v, z) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [Math.round(q.sx), Math.round(q.sy), q.d]; };
    const read = (name, uvz, draw) => {
      zb.fill(-1e9); pix.fill(0); part('probe', draw);
      const [sx, sy, d] = px(...uvz);                                                                      // the drawn top's depth under the spot's own pixel
      return { name, sx, sy, d, z: zb[sy * W + sx] };
    };
    const o = {};
    E.CUSHIONS.forEach(([cu, cv], i) => { o['cojin' + (i + 1)] = read('cojin' + (i + 1), [cu, cv, .12], () => PZ.box(cu, cv, 0, .12, .36, .3, [226, 120, 90], (s, t, z, face) => face === 'top' ? rgb(240, 150, 110) : 0)); });
    o.escritorio = read('escritorio', [E.DESKSEAT[0], E.DESKSEAT[1], .44], () => FD.chair(E.DESKSEAT[0], E.DESKSEAT[1]));
    o.butaca = read('butaca', [E.ARMCHAIR[0], E.ARMCHAIR[1], .44], () => CS.armchair(E.ARMCHAIR[0], E.ARMCHAIR[1], [110, 140, 96]));
    o.mesita = read('mesita', [E.SIDE.u, E.SIDE.v, E.SIDE.h], () => { const [x, y] = PZ.xy(E.SIDE.u, E.SIDE.v); drum(x, y, 0, E.SIDE.h - .06, .05, FD.WOOD); drum(x, y, E.SIDE.h - .06, E.SIDE.h, E.SIDE.r, FD.WOOD_L); });
    return o;
  }, G.E);
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);

  let sheet = await make(G, proj, null);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks and without abuelo's boxes: the preview reads the sheet
  let PV = await previewData(browser, errs, false);
  sheet = await make(G, proj, PV.sil);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');
  await PV.page.close();
  PV = await previewData(browser, errs, true);
  const probes = await probeSets(page, sheet, G, proj);
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

/* ---------- the preview's moments: sala_dia-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, full) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/sala_dia-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  if (full) for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
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
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle; a small thing or a box: its box) takes: [first, last]
const colsOf = s => s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL) {
  const E = G.E, sc = G.scene, DEF = defs(E);
  // derived spots (not in the spec's lists, made for the things the spec names): the photo in Carmen's hands, and abuelo's ear and mouth on his drawn head
  const cj2 = DEF.find(d => d.name === 'cojin2'), bt = DEF.find(d => d.name === 'butaca');
  DEF.push({ name: 'foto', uvz: [cj2.uvz[0], cj2.uvz[1], r4(cj2.uvz[2] + PHOTO_UP / 22.5)], kind: 'thing', sil: null, who: null, what: 'the photo in Carmen\'s hands (a ' + SZ.foto.join(' x ') + ' px stand-in): its bottom middle ' + PHOTO_UP + ' px above her lap (cojin2\'s spot, z ' + cj2.uvz[2] + ' + ' + PHOTO_UP + ' / 22.5 = ' + r4(cj2.uvz[2] + PHOTO_UP / 22.5) + '): the box [sx - 5, sy - ' + (PHOTO_UP + SZ.foto[1]) + ', ' + SZ.foto.join(', ') + '] with (sx, sy) her lap', size: SZ.foto, anchor: 'bottom', on: 'carmen' });
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.fixed) o.fixed = 1;
    if (d.moved) { o.spec = W4(d.spec); o.moved = d.moved; }
    spots[d.name] = o;
  });
  // abuelo's ear and mouth: boxes on his drawn head. T is the row of the top of his drawn head (his top ink row), sx his middle column. The ear (his side towards the frog, the left one): 12 x 10, centred
  // on the tuft of hair at his temple (6 columns left of his middle), its top on the head's top row; the mouth: 12 x 10, centred on his middle, its top on the row 10 below the head's top (the moustache's
  // top row), so it holds the mouth, the chin and the neck. The two boxes do not overlap (rows T to T + 9, and T + 10 to T + 19). The spec gives the sizes and the words, not the numbers: open point
  {
    const [sx, sy] = spots.butaca.screen, T = SIL ? sy + SIL.abueloS.box[1] : sy - 37;
    const mkBox = (name, box, what) => {
      const cx = box[0] + box[2] / 2, cy = box[1] + box[3] / 2, u = r4((cx - G.OX) / G.S), z = r4(bt.uvz[2] + (sy - cy) / 22.5);
      spots[name] = { world: null, uv: [u, bt.uvz[1], z], screen: [Math.round(cx), Math.round(cy)], depth: spots.butaca.depth, scale: 1, kind: 'thing', view: 'wide', what, box, anchor: 'centre', on: 'abuelo' };
      return spots[name];
    };
    mkBox('oreja_abuelo', [sx - 12, T, BOX.oreja[0], BOX.oreja[1]], 'abuelo\'s ear, on the side of his head towards the frog (the left one): a ' + BOX.oreja.join(' x ') + ' box centred on the tuft at his temple, its top on his head\'s top row; on the plane of his sprite through his lap (v ' + bt.uvz[1] + ')');
    mkBox('boca_abuelo', [sx - 6, T + 10, BOX.boca[0], BOX.boca[1]], 'abuelo\'s mouth: a ' + BOX.boca.join(' x ') + ' box at the lower middle of his head and below it (the mouth, the chin, the neck), centred on his middle column, its top 10 rows below his head\'s top row; on the plane of his sprite through his lap');
    for (const n of ['oreja_abuelo', 'boca_abuelo']) { const q = (await proj([[spots[n].uv[0], spots[n].uv[1], spots[n].uv[2]]]))[0]; spots[n].world = W4([q[3], q[4], spots[n].uv[2]]); spots[n].depth = r4(q[2]); }
  }

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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [102, 103, 104], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 102, 103 and 104: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing or a box with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
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
  for (const k of ['libro', 'papel', 'telefono', 'pagina1', 'pagina2', 'pagina3', 'estrellas', 'foto']) things[k] = 'sprite';
  const SC = E.SCREEN, DK = E.DESK, sv = r4(DK.v - .1 + .04);
  things.computadora = await setThing(r4(SC.u - SC.hw), sv, SC.z0, r4(SC.u + SC.hw), sv, SC.z1, 'the computer\'s screen (the box on the desk\'s left end: SCREEN u ' + SC.u + ' +- ' + SC.hw + ', z ' + SC.z0 + ' to ' + SC.z1 + '), its front face at v ' + sv + ' (the desk\'s v ' + DK.v + ' - .1 + the screen\'s half depth .04); a poke');
  things.oreja_abuelo = { box: spots.oreja_abuelo.box, on: 'abuelo', what: 'abuelo\'s ear: the box of the spot oreja_abuelo (' + BOX.oreja.join(' x ') + ' on the picture); a poke' };
  things.boca_abuelo = { box: spots.boca_abuelo.box, on: 'abuelo', what: 'abuelo\'s mouth: the box of the spot boca_abuelo (' + BOX.boca.join(' x ') + ' on the picture); a poke' };
  const W_ = E.WINDOW;
  things.ventana = await setThing(W_[0], 0, W_[2], W_[1], 0, W_[3], 'the window in the back wall: u ' + W_[0] + ' to ' + W_[1] + ', z ' + W_[2] + ' to ' + W_[3] + ', on the wall (v 0); a poke');
  for (const k of ['luis', 'carmen', 'abuela', 'abuelo', 'coqui']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'sala_dia',
    made: 'node docs/proyecto/pixel/sala_dia-sheet-make.js, from sala_dia-set.html (window.SALA_DIA.E) and the design of La sala, de día (the orchestrator\'s p9-spec, general rules and section sala_dia). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. The seats are the set\'s own: the cushions E.CUSHIONS (cojin1 (' + E.CUSHIONS[0] + '), cojin2 (' + E.CUSHIONS[1] + '), tops z ' + CUSHION_Z + '), the desk\'s chair E.DESKSEAT (' + E.DESKSEAT + '), the armchair E.ARMCHAIR (' + E.ARMCHAIR + '), tops z ' + SEAT_Z,
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + CUSHION_Z + ': a cushion\'s top; z ' + SEAT_Z + ': a chair\'s or the armchair\'s top; z ' + E.LOW.h + ': the low table\'s top; z ' + E.SIDE.h + ': the small table\'s top) and, drawn there, a character stands (or, who sits, is hung by the lap) with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the book, the pad, the telephone, the three pages and the box of stars have their bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]); the photo\'s spot is cojin2\'s lifted ' + PHOTO_UP + ' px (z + ' + PHOTO_UP + ' / 22.5); abuelo\'s ear and mouth are boxes on his drawn head (the spots oreja_abuelo and boca_abuelo: their screen point is the box\'s middle, their uv a point on the plane of his sprite through his lap). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. abuela standing, mkAbuela (48 wide): column 30 (her middle), its lowest drawn row; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); whoever sits, mkPersona with sent = 1 (48 wide): column 24 (KIT.PX) and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy), the spot being the seat\'s top; a small thing: see spot. Nobody is drawn turned: whoever sits faces us',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: {
      params: { pantalla: { values: [0, 1], note: 'the computer\'s screen: 0 dark, 1 lit (?pantalla=1). The set has one hour, the afternoon, and no hora parameter' } },
      key: 'pantalla, e.g. "0"',
      baked: ['?pantalla=0', '?pantalla=1'],
    },
    things,
    spots,
    groups: {
      sentados: ['cojin1', 'cojin2', 'escritorio', 'butaca'], abuela: ['estante', 'cocina', 'ventana_abuela'], rana: ['junto_mesa_coqui', 'brazo_coqui'],
      mesa: ['libro', 'papel', 'telefono', 'pagina1', 'pagina2', 'pagina3', 'estrellas'], paginas: ['pagina1', 'pagina2', 'pagina3'], abuelo: ['oreja_abuelo', 'boca_abuelo'],
      touch: { libro: 'libro', papel: 'papel', telefono: 'telefono', pagina1: 'pagina1', pagina2: 'pagina2', pagina3: 'pagina3', estrellas: 'estrellas', foto: 'foto', oreja_abuelo: 'oreja_abuelo', boca_abuelo: 'boca_abuelo', luis: 'cojin1', carmen: 'cojin2', abuela: 'estante', abuelo: 'butaca', coqui: 'junto_mesa_coqui' },
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p9-spec, "sala_dia"), given in (u, v, z); the cushions, the desk\'s chair, the armchair, the low table, the small table, the screen and the window are read from the set',
      'things: libro, papel, telefono, pagina1 to pagina3, estrellas and foto are sprites at the spots of the same name; computadora and ventana are the set\'s boxes; oreja_abuelo and boca_abuelo are boxes on abuelo\'s drawn head; the people are sprites. NOT IN THE SPEC\'S LIST OF SPOTS, made for the things it names: foto (cojin2\'s spot lifted ' + PHOTO_UP + ' px), and the numbers of abuelo\'s two boxes (the spec gives the sizes and the words: the ear 12 x 10 on the side of his head towards the frog, the mouth 12 x 10 at the lower middle of his head and below it): see the spots\' text',
      'abuelo is kit\'s FAM.abuelo (a grown-up man: bald, a white moustache, glasses, a cream shirt); abuela standing is mkAbuela; Luis and Carmen are FAM.hermano and FAM.hermana; whoever sits is hung by the lap on the seat\'s top; in moment 5 Luis sits at the desk (escritorio) and Carmen holds the photo (foto)',
      'the spec gives no radius for the shadows: El cruce\'s are used (frog .45, grown-ups .35, children .28); nobody on a cushion, a chair, the armchair or the small table casts one (none of them is floor)',
      '"the chest" (the low table hides the children only below it) is the torso\'s centre row of the sprite (row 25 of a child\'s ink, 29 of a grown-up\'s): the spec gives the word, not the row',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing or a box with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the low table hides the lap and legs of the children on the cushions, the desk hides Luis from the lap down, the armchair\'s arms hide the edges of abuelo.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where the set\'s baked depth (window.DEPTH.z of the set page) bakedZ[r * 240 + x] > depth(r) + bias. The same rule as El cruce\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name).concat(['oreja_abuelo', 'boca_abuelo']),
      onSeat: 'whoever sits on a cushion, a chair or the armchair, and the frog on the small table, cast none: none of those is floor (a shadow cast at the floor under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G, proj) {
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
  // the desk's box on the picture (its top, its front panel, its legs: u, v, z 0 to its top)
  const D = G.E.DESK, corners = []; for (const z of [0, D.h]) for (const [u, v] of [[D.u - D.hw, D.v - D.hd], [D.u + D.hw, D.v - D.hd], [D.u + D.hw, D.v + D.hd], [D.u - D.hw, D.v + D.hd]]) corners.push([u, v, z]);
  const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]), x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
  return { spotsPx, desk: [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0] };
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

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing or a box with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24; and his rows from the drawn silhouette; a small thing's or a box's box)
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
    add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things and boxes with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + colsOf(left[1])[0] + ' (' + left[0] + '), the rightmost ' + colsOf(right[1])[1] + ' (' + right[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
  }

  // 3. the spots above the floor are on what the set draws: a seat's top (the cushions, the desk's chair, the armchair: drawn alone, its top at the spot's depth: in the picture the low table and the desk are in
  //    front of them), the low table's top and the small table's top (the set's own pixel under the spot: part sala at the spot's depth)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground') continue;
      if (s.on === 'carmen' || s.on === 'abuelo') continue;                                // the photo and abuelo's boxes: on a person, not on the set
      if (s.fixed) {
        const a = G.alone[k], dz = Math.abs(a.z - s.depth), want = s.on === 'cojin' ? CUSHION_Z : SEAT_Z, ok = dz < .1 && a.sx === s.screen[0] && a.sy === s.screen[1] && s.uv[2] === want;
        const here = (px[k] || []).find(r => r.dx === 0 && r.dy === 0);
        lines.push(k + ' z ' + s.uv[2] + ': drawn alone its top is at depth ' + r2(a.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(dz) + '); in the picture the pixel under the spot is part ' + (here ? here.tag + ' at depth ' + r2(here.z) : 'none')); surf.push(k);
        if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on the top of its ' + s.on + ' (z ' + want + '): drawn alone the top has depth ' + r2(a.z) + ' at ' + [a.sx, a.sy] + ', the spot\'s is ' + r2(s.depth));
      } else {
        const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
        const ok = best && best.r.tag === 'sala' && best.dz < .1;
        lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
        if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + s.on + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
      }
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on what the set draws (the seats: z ' + CUSHION_Z + ' the cushions\' tops, z ' + SEAT_Z + ' the chair\'s and the armchair\'s tops, each drawn alone at the spot\'s depth; the low table\'s top z ' + E.LOW.h + ' and the small table\'s top z ' + E.SIDE.h + ': the set\'s own pixel under the spot, part sala, depth within .1 of the spot\'s)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the set things' boxes (and abuelo's two boxes) are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of computadora, ventana, oreja_abuelo and boca_abuelo are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who are together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
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
      const s = S[name]; if (s.fixed) return 'fixed by the set (a seat): not moved';
      const res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 5 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 5 moments):'].concat(bad.map(b => '  ' + b)));
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
    const o = add('frog-seen', bad, 'the frog is seen whole in all 5 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. heads-clear: everyone who sits (the children on the cushions, Luis at the desk, abuelo in the armchair) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'sentado') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.id + ' at ' + l.at + ' ' + [l.sx, l.sy] + ': head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.id + ' at ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.id + ' at ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'everyone who sits (' + MOMENTS.map(m => 'm' + m + ': ' + PV.inspect[m].layers.filter(l => l.group === 'sentado').map(l => l.id + '@' + l.at).join(', ')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people who sit:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. low-table: the low table hides the two children on the cushions only below the chest: every pixel of theirs that the set hides is on the sprite's row CHEST_ROW.nino (25) or lower, and the top 25 rows are shown whole
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers;
      for (const l of L) {
        if (l.group !== 'sentado' || !/^cojin/.test(l.at)) continue;
        const top = Math.min(...l.px.map(p => p[1])), hid = l.px.filter(p => p[2]), rows = hid.map(p => p[1] - top), first = hid.length ? Math.min(...rows) : null, chest = CHEST_ROW.nino;
        const above = hid.filter(p => p[1] - top < chest).length;
        lines.push('m' + m + ' ' + l.id + ' at ' + l.at + ': ' + hid.length + ' of ' + l.px.length + ' px hidden by the set, from sprite row ' + first + ' down (the chest is row ' + chest + '); ' + above + ' hidden above it');
        if (above || !hid.length) bad.push('moment ' + m + ' ' + l.id + ' at ' + l.at + ': ' + (hid.length ? above + ' px hidden above the chest (row ' + chest + '), the first hidden row is ' + first : 'the table hides none of him'));
      }
    }
    add('low-table', bad, 'in every moment the low table hides the children on the cushions only below the chest (sprite row ' + CHEST_ROW.nino + ' of the child\'s ink, the torso\'s centre): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 9. desk-head: Luis at the desk (moment 5): his head (the top 14 rows) is covered by neither the screen nor the desk: none of it is hidden by the set, and none of it is under a person or a thing
  {
    const bad = [], lines = [], m = 5, L = PV.inspect[m].layers, M = planes(L), i = L.findIndex(l => l.at === 'escritorio');
    const l = L[i], c = coverOf(L, M, i, null, [0, HEAD_ROWS]), top = c.top, head = l.px.filter(p => p[1] < top + HEAD_ROWS);
    const inScreen = head.filter(p => inside(T.computadora.box, p[0], p[1])).length, inDesk = head.filter(p => inside(probes.desk, p[0], p[1])).length;
    const hidScreen = head.filter(p => p[2] && inside(T.computadora.box, p[0], p[1])).length, hidDesk = head.filter(p => p[2] && inside(probes.desk, p[0], p[1])).length;
    lines.push('Luis at escritorio ' + [l.sx, l.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ' (columns ' + Math.min(...head.map(p => p[0])) + ' to ' + Math.max(...head.map(p => p[0])) + '): ' + c.hid + ' px hidden by the set (' + hidScreen + ' under the screen\'s box [' + T.computadora.box + '], ' + hidDesk + ' under the desk\'s box [' + probes.desk + ']), ' + c.cov + ' covered by sprites; ' + inScreen + ' of his head px lie over the screen\'s box, ' + inDesk + ' over the desk\'s; the desk\'s box starts at row ' + probes.desk[1] + ', his head ends at row ' + (top + HEAD_ROWS - 1));
    if (c.hid || c.cov || hidScreen || hidDesk) bad.push('Luis at escritorio ' + [l.sx, l.sy] + ': ' + c.hid + ' px of his head hidden by the set (' + hidScreen + ' under the screen, ' + hidDesk + ' under the desk), ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
    add('desk-head', bad, 'Luis at the desk (moment 5): his head (the top ' + HEAD_ROWS + ' rows) is covered by neither the screen nor the desk: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 10. touch-clear: the book and the pad (moments 1, 2), the telephone (4), the three pages and the box of stars (5) are covered by nobody (no person, not the frog, not the set) and stand on the low table's top (spots-on-surface)
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'cosa') continue;
        const c = coverOf(L, M, i, null), top = surf.includes(l.at);
        lines.push('m' + m + ' ' + l.at + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; on the low table\'s top ' + (top ? 'yes' : 'NO'));
        if (c.cov || c.hid || c.out || !top) bad.push('moment ' + m + ' ' + l.at + ' ' + S[l.at].screen + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture' + (top ? '' : '; not on the low table\'s top'));
      }
    }
    add('touch-clear', bad, 'the book and the pad (m1, m2), the telephone (m4), the three pages and the box of stars (m5) are covered by nobody and stand on the low table\'s top: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 11. frog-brazo: the frog at brazo_coqui (moments 3, 4) stands on the small table's top (spots-on-surface), covers neither of abuelo's boxes (no shown pixel of his inside either box), and each box holds
  //     at least 60 of abuelo's drawn pixels or touches them (a drawn pixel of his within one pixel of the box); the two boxes do not overlap
  {
    const bad = [], lines = [], hints = [], bo = T.oreja_abuelo.box, bb = T.boca_abuelo.box, grow = b => [b[0] - 1, b[1] - 1, b[2] + 2, b[3] + 2];
    const overlap = bo[0] < bb[0] + bb[2] && bb[0] < bo[0] + bo[2] && bo[1] < bb[1] + bb[3] && bb[1] < bo[1] + bo[3];
    if (overlap) bad.push('the two boxes overlap: oreja [' + bo + '] and boca [' + bb + ']');
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers, fi = idxAt(L, 'brazo_coqui'), ai = idxAt(L, 'butaca'), M = planes(L);
      const parts = [];
      for (const [n, b] of [['oreja_abuelo', bo], ['boca_abuelo', bb]]) {
        const cover = shownIn(L, fi, b), own = shownIn(L, ai, b), near = shownIn(L, ai, grow(b));
        const holds = own >= 60 || near > 0;
        parts.push(n + ' [' + b + ']: the frog covers ' + cover + ' px, abuelo has ' + own + ' px in it (' + near + ' within one px of it)');
        if (cover) { bad.push('moment ' + m + ': the frog at brazo_coqui covers ' + cover + ' px of ' + n + ' [' + b + ']'); hints.push([m, fi, b]); }
        if (!holds) bad.push('moment ' + m + ': ' + n + ' [' + b + '] holds ' + own + ' of abuelo\'s px and does not touch them');
      }
      lines.push('m' + m + ': ' + parts.join('; ') + '; the frog on the small table\'s top ' + (surf.includes('brazo_coqui') ? 'yes' : 'NO'));
    }
    if (!surf.includes('brazo_coqui')) bad.push('the frog at brazo_coqui is not on the small table\'s top');
    const o = add('frog-brazo', bad, 'the frog at brazo_coqui ' + S.brazo_coqui.screen + ' stands on the small table\'s top and covers neither oreja_abuelo [' + bo + '] nor boca_abuelo [' + bb + '], which do not overlap each other and each hold at least 60 of abuelo\'s drawn px or touch them: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi, b] of hints) { const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, fi, [bo, bb]); o.lines.push('       nearest passing, moment ' + m + ' brazo_coqui ' + S.brazo_coqui.uv + ': ' + axisTxt(r, 'brazo_coqui')); }
  }

  // info: who else touches abuelo's boxes, the photo, the computer's screen and the window: not checks of the spec
  {
    const lines = [], bo = T.oreja_abuelo.box, bb = T.boca_abuelo.box;
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, parts = [];
      let screen = 0, win = 0; for (const [i, l] of L.entries()) { if (l.group === 'foto') continue; screen += shownIn(L, i, T.computadora.box); win += shownIn(L, i, T.ventana.box); }
      parts.push('computadora [' + T.computadora.box + '] ' + screen + ' px under anyone, ventana [' + T.ventana.box + '] ' + win + ' px under anyone');
      const ai = idxAt(L, 'butaca'); if (ai >= 0) { let oo = 0, bq = 0; for (const [i, l] of L.entries()) { if (i === ai) continue; oo += shownIn(L, i, bo); bq += shownIn(L, i, bb); } parts.push('under others: oreja_abuelo ' + oo + ' px, boca_abuelo ' + bq + ' px'); }
      lines.push('m' + m + ': ' + parts.join(', '));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
    const ov = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const [i, l] of L.entries()) { if (!l.who) continue; const c = coverOf(L, M, i, L.map((q, j) => q.who ? j : -1).filter(j => j >= 0)); if (c.cov) parts.push(l.id + ' at ' + l.at + ': ' + c.cov + ' of ' + c.tot + ' px under ' + whoTxt(c)); }
      ov.push('m' + m + ': ' + (parts.join(', ') || 'no person or frog is under another'));
    }
    const hd = [];
    for (const m of MOMENTS) {
      const parts = [];
      for (const l of PV.inspect[m].layers) { if (!l.who) continue; const top = Math.min(...l.px.map(p => p[1])), h = l.px.filter(p => p[2]); if (h.length) parts.push(l.id + ' at ' + l.at + ': ' + h.length + ' of ' + l.px.length + ' px hidden by the set, from sprite row ' + Math.min(...h.map(p => p[1] - top)) + ' down'); }
      hd.push('m' + m + ': ' + (parts.join(', ') || 'nobody is hidden by the set'));
    }
    OUTS.push({ name: 'info-hidden', ok: true, lines: ['info-hidden: not a check (the people and the frog hidden by the set, from the sprite row of his ink: the low table and the desk hide whoever sits behind them; the armchair\'s back hides abuela\'s feet at cocina). ' + hd.join('; ')] });
    OUTS.push({ name: 'info-overlap', ok: true, lines: ['info-overlap: not a check (the people and the frog covered by another person or the frog). ' + ov.join('; ')] });
  }
  return OUTS;
}
