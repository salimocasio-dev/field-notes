#!/usr/bin/env node
'use strict';
/* La muralla's sheet (place 10, El fuerte, scene 4, stories 117 to 119): writes docs/proyecto/pixel/muralla-sheet.json from muralla-set.html and the design (the orchestrator's p10-spec, general rules and section "muralla"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/muralla-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   Add --suggest to print, for every failing check, the nearest place of each spot it names that would pass (v first, then u; never z).
   Add --cord-ok to read the checks with the cord's own pixels (the 1 px line of the set between the two boxes, nearer than the bench and the road) counted as hiding nothing: the default counts them (the spec says
   "covered by nobody and by nothing" for a head and "hidden by nothing of the set" for the guagua); the sheet's numbers do not depend on it.
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 84 here). The parapet, the sentry boxes (and their doors), the cord, the bench, the table, the steps and the road
   are read from the set (window.MURALLA.E), never typed again from the design.
   It loads the set in headless Chrome (muralla-set.html, tags=1: which part drew each pixel; the baked depth) and writes the spots, things, the view (wide), shadows and the depth rule.
   The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (muralla-preview.html,
   PREVIEW.inspect): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with MURALLA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'muralla-sheet.json');
const BASE = process.env.MURALLA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/muralla-set.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };
const SUGGEST = process.argv.includes('--suggest');
const CORD_OK = process.argv.includes('--cord-ok');       // an alternative reading of the spec (see the checks heads-clear and guagua-clear): the cord's own 1 px line hides nothing

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

// the numbers of the design (p10-spec: the rules for every sheet, and "muralla")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = .46, TABLE_Z = .74, DOOR_Z = 1.18;        // the bench's seat; the table's top; the top of a sentry box's door
const SZ = { farol: [10, 12], camara: [12, 22], vela: [8, 16], jugo: [6, 10], plato: [12, 6], silla: [14, 24], guitarra: [10, 22], sombrero: [12, 8], bolsa: [10, 12], caja: [12, 10], libro: [10, 8], guagua: [22, 10], lejos: [4, 7] };
const MOMENTS = [1, 2, 3, 4, 5, 6];
const SILKEY = { adulto: 'abuelo', adultoS: 'senorS', nino: 'luis', coqui: 'coqui' };       // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a shelf, a table top's height).
   spot: { to: [u, v, z] (or screen: [column, row] for a spot given in picture px), why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  ventana_azul: { to: [2.15, 1.42, 0], why: 'sprites-apart: in moment 3 Luis at the blue box\'s window was 17 px sideways from centro4 and his feet 8 px above theirs (needs 24 across or 12 down): v 1.7 -> 1.42 (-.28; the other way, centro4 v 2.3 -> 2.58, +.28, would move the group\'s back row)' },
  mesa_coqui: { to: [-1.56, 5.8, TABLE_Z], why: 'sprites-apart: in moment 4 the frog on the table was 18 px sideways from the dancer at baile4 and his feet 2 px apart (needs 28 across or 12 down): u -1.2 -> -1.56 (-.36; no v on the table\'s top passes; the other way, baile4 u -.5 -> -.13, +.37, or v 4.4 -> 5.43, +1.03)' },
  escalera_abuela: { to: [1.40, 5.6, 0], why: 'sprites-apart: in moment 5 abuela at the head of the steps was 14 px sideways from the guest at escalera1 and 3 px above him (needs 24 across or 12 down): u 1.75 -> 1.40 (-.35; v 5.6 -> 6.27, +.67, also passes)' },
  pretil_coqui: { to: [1.37, 1.9, 0], why: 'sprites-apart: in moment 6 the frog at the parapet was 26 px sideways from Luis at pretil3 and 4 px below him (needs 28 across or 12 down): u 1.3 -> 1.37 (+.07; v 1.9 -> 2.58, +.68, also passes)' },
  juego_coqui: { to: [.91, 5.0, 0], why: 'frog-seen: in moments 2 and 3 the frog in the game stood behind abuela (v 6.9) and the camera (v 6.0): 319 of his 536 px were under them: u .2 -> .91 (+.71; v 5.0 -> 7.81, +2.81, also passes)' },
  vela: { to: [-1.52, 0, 1.0], why: 'candle-clear: in moment 4 the lantern farol3 (u 1.2, v 1.0, nearer than the parapet) covers 58 of the candle\'s 98 px at u 1.1. The parapet holds a candle only on a merlon (u .94 to 1.46, 1.84 to 2.36 ... every .9); to the right of farol3 the next merlon has muro2 in front of it (5 px of the candle\'s last row at u 1.99), in the middle the músicos\' heads and farol2 fill the way: u 1.1 -> -1.52 (-2.62, the least that leaves the candle uncovered on a merlon; v is the parapet\'s, 0). The other way: u 1.99 (+.89) with muro2 v 2.2 -> 2.28 (+.08, a second spot)' },
  guagua: { screen: [167, 53], why: 'guagua-clear: in moment 5 the lantern farol3 (box [146, 48, 10, 12]) covers 29 px of the guagua (box [149, 44, 22, 10]): column 160 -> 167 (+7, the least that clears it: its box [156, 43, 22, 10]); the road\'s row there is 53. It now overlaps the columns of the two músicos walking off (170 to 178: not in a moment with it). The cord is not cured by a column: see the open point of guagua-clear' },
  pretil1: { to: [-1.6, 1.66, 0], why: 'heads-clear: in moment 6 abuela at the parapet covered 2 px of the head of the guest sitting at banco1: v 1.6 -> 1.66 (+.06; u -1.6 -> -1.68, -.08, also passes)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed, clip, px }
   kind: person (a character stands or sits there), place (the frog's), thing (a small thing: a lantern, the camera, the candle, the glass, the guagua ...)
   sil: which drawing hangs there (adulto = a grown-up standing, adultoS = a grown-up sitting, nino = a child standing, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point (a lantern hangs), bottom = its bottom middle on the point
   on: the part of the set it stands on above the floor: paseo (the bench's or the table's top), pretil (the parapet's top), cuerda (a lantern hangs from the cord)
   px: given in picture pixels (the road, far below the wall): uvz is then the line of sight at z 0 through the pixel; its depth is far (behind everything the set bakes)
   fixed: the set fixes its place (a seat), so it is never moved
   clip: a person drawn inside a sentry box: only what falls inside the door's box shows */
function defs(E, G) {
  const B = E.BOXES, C = E.CORD, T = E.TABLE, S = E.STEPS, BN = E.BENCH, L = E.LAND, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const cordZ = u => r4(C.z - Math.sin(Math.PI * (u - C.u0) / (C.u1 - C.u0)) * C.sag);
  // the three lanterns on the cord
  C.at.forEach((u, i) => add('farol' + (i + 1), [u, C.v, cordZ(u)], 'thing', null, null, 'lantern ' + (i + 1) + ' of 3 (' + SZ.farol.join(' x ') + ' px stand-in), hanging from the cord (CORD.at[' + i + '] = ' + u + ', CORD.v = ' + C.v + ', the cord\'s height there CORD.z - sin(pi (u - u0) / (u1 - u0)) sag = ' + cordZ(u) + '): its top middle on the point', { size: SZ.farol, anchor: 'top', on: 'cuerda', fixed: true }));
  // the group under the lanterns
  [-1.5, -.5, .5, 1.5].forEach((u, i) => add('centro' + (i + 1), [u, 2.3, 0], 'person', 'adulto', 'adulto', 'the back row of the group under the lanterns, place ' + (i + 1) + ' of 4 (u ' + u + ', v 2.3): grown-ups', {}));
  [-1.0, 0, 1.0].forEach((u, i) => add('centro' + (i + 5), [u, 3.5, 0], 'person', 'nino', 'nino', 'the front row of the group, place ' + (i + 1) + ' of 3 (u ' + u + ', v 3.5): children', {}));
  add('camara', [0, 6.0, 0], 'thing', null, null, 'abuela\'s camera on its three legs (' + SZ.camara.join(' x ') + ' px stand-in): its bottom middle on the point', { size: SZ.camara, anchor: 'bottom' });
  add('camara_abuela', [0, 6.9, 0], 'person', 'adulto', 'adulto', 'abuela at her camera, her back to us (drawn standing, as everybody: nobody is drawn turned); v 6.9, nearer the camera of the picture than the tripod (v 6.0)', {});
  add('junto_camara', [1.25, 6.9, 0], 'place', 'coqui', 'coqui', 'the frog beside the camera (117, opening)', {});
  add('ante_todos', [0, 4.7, 0], 'place', 'coqui', 'coqui', 'the frog in front of the others (117, "aqui")', {});
  add('juego_coqui', [.2, 5.0, 0], 'place', 'coqui', 'coqui', 'the frog in the game (117)', {});
  add('junto_coqui', [-1.0, 5.0, 0], 'person', 'nino', 'nino', 'Luis beside the frog (117, the game)', {});
  // the doors: the red one at the left box, the blue one at the right (the door boxes are things); whoever is inside is clipped to the door's box
  add('dentro_roja', [B[0].u, r4(B[0].v + .52), 0], 'person', 'nino', 'nino', 'whoever is inside the red box (BOXES[0].u, BOXES[0].v + .52): drawn standing there and CLIPPED to puerta_roja\'s box (only what falls inside the door shows); Carmen (117, the game)', { clip: 'puerta_roja' });
  add('dentro_azul', [B[1].u, r4(B[1].v + .52), 0], 'person', 'nino', 'nino', 'whoever is inside the blue box (BOXES[1].u, BOXES[1].v + .52): as dentro_roja, clipped to puerta_azul\'s box', { clip: 'puerta_azul' });
  add('ventana_roja', [r4(B[0].u + .85), r4(B[0].v + .7), 0], 'person', 'nino', 'nino', 'Luis beside the red box, looking in at its window (BOXES[0].u + .85, BOXES[0].v + .7)', {});
  add('ventana_azul', [r4(B[1].u - .85), r4(B[1].v + .7), 0], 'person', 'nino', 'nino', 'Luis beside the blue box, looking in at its window (BOXES[1].u - .85, BOXES[1].v + .7)', {});
  add('sale_roja', [-2.1, 2.4, 0], 'person', 'nino', 'nino', 'someone who has just come out of the red box (117: Carmen; a child)', {});
  add('sale_azul', [2.1, 2.4, 0], 'person', 'adulto', 'adulto', 'someone who has just come out of the blue box (117: a grown-up)', {});
  // the bench
  [-1.43, -.48, .48, 1.43].forEach((d, i) => add('banco' + (i + 1), [r4(BN.u + d), BN.v, SEAT_Z], 'person', 'adultoS', 'adulto', 'the bench\'s place ' + (i + 1) + ' of 4 (BENCH.u ' + (d > 0 ? '+ ' : '- ') + Math.abs(d) + ', BENCH.v ' + BN.v + '): on its top, z ' + SEAT_Z + '; whoever sits faces us and is hung by the lap', { on: 'paseo' }));
  add('vela', [1.1, 0, E.PARAPET], 'thing', null, null, 'the candle in its glass (' + SZ.vela.join(' x ') + ' px stand-in) on the parapet\'s top (u 1.1, v 0, z PARAPET ' + E.PARAPET + '): its bottom middle on the top; the parapet must be solid under all its columns', { size: SZ.vela, anchor: 'bottom', on: 'pretil' });
  [[-2.1, 2.2], [2.1, 2.2], [2.6, 3.6]].forEach(([u, v], i) => add('muro' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'a person who does not dance, place ' + (i + 1) + ' of 3 (u ' + u + ', v ' + v + ')', {}));
  [[-1.0, 3.0], [0, 3.0], [1.0, 3.0], [-.5, 4.4], [.5, 4.4], [1.5, 4.4]].forEach(([u, v], i) => add('baile' + (i + 1), [u, v, 0], 'person', i < 2 ? 'nino' : 'adulto', i < 2 ? 'nino' : 'adulto', 'a dancer, place ' + (i + 1) + ' of 6 (u ' + u + ', v ' + v + ')', {}));
  // the small table at the left front
  add('jugo', [r4(T.u - 1.1), r4(T.v - .2), TABLE_Z], 'thing', null, null, 'the glass of juice (118; ' + SZ.jugo.join(' x ') + ' px stand-in) on the table\'s top (TABLE.u - 1.1, TABLE.v - .2): its bottom middle on the top, z ' + TABLE_Z, { size: SZ.jugo, anchor: 'bottom', on: 'paseo' });
  add('plato', [r4(T.u - .5), r4(T.v - .2), TABLE_Z], 'thing', null, null, 'the plate (118; ' + SZ.plato.join(' x ') + ' px stand-in) on the table\'s top (TABLE.u - .5, TABLE.v - .2): its bottom middle on the top, z ' + TABLE_Z, { size: SZ.plato, anchor: 'bottom', on: 'paseo' });
  add('mesa_coqui', [r4(T.u + .9), r4(T.v + .1), TABLE_Z], 'place', 'coqui', 'coqui', 'the frog on the table\'s right end (118; TABLE.u + .9, TABLE.v + .1): the table\'s top, z ' + TABLE_Z, { on: 'paseo' });
  add('junto_mesa', [r4(T.u + 1.9), r4(T.v - .1), 0], 'thing', null, null, 'the chair (118; a ' + SZ.silla.join(' x ') + ' px sprite) beside the table (TABLE.u + 1.9, TABLE.v - .1): its bottom middle on the point', { size: SZ.silla, anchor: 'bottom' });
  [[-1.25, 'guitarra', 'the guitar'], [-.82, 'sombrero', 'the hat'], [-.39, 'bolsa', 'the bag'], [.04, 'caja', 'the box'], [.47, 'libro', 'the book']].forEach(([d, k, w], i) =>
    add('mesa' + (i + 1), [r4(T.u + d), r4(T.v - .2), TABLE_Z], 'thing', null, null, w + ' (119; ' + SZ[k].join(' x ') + ' px stand-in), place ' + (i + 1) + ' of 5 in a row on the table\'s top (TABLE.u ' + (d > 0 ? '+ ' : '- ') + Math.abs(d) + ', TABLE.v - .2): its bottom middle on the top, z ' + TABLE_Z, { size: SZ[k], anchor: 'bottom', on: 'paseo', thingName: k }));
  add('junto_mesa_coqui', [r4(T.u + 2.0), r4(T.v + .6), 0], 'place', 'coqui', 'coqui', 'the frog on the floor beside the table (119; TABLE.u + 2.0, TABLE.v + .6)', {});
  // the steps
  add('escalera_abuela', [1.75, 5.6, 0], 'person', 'adulto', 'adulto', 'abuela at the head of the steps, seeing people off (119)', {});
  add('escalera_abuelo', [1.6, 7.3, 0], 'person', 'adulto', 'adulto', 'abuelo at the head of the steps (119)', {});
  [[2.3, 5.4], [3.25, 5.4], [2.3, 4.2], [3.25, 4.2]].forEach(([u, v], i) => add('escalera' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'guest ' + (i + 1) + ' of 4 at the head of the steps, his back to us (drawn facing us: nobody is drawn turned) (119)', {}));
  add('baja', [r4((S.u0 + S.u1) / 2), r4(S.v0 + .6), 0], 'person', 'adulto', 'adulto', 'the way down the steps: the only place on the steps\' hole where somebody stands (STEPS u middle, v0 + .6)', {});
  // far away on the road (picture px: its row is LAND.road + (240 - column) .1)
  const road = col => Math.round(L.road + (240 - col) * .1);
  add('guagua', [0, 0, 0], 'thing', null, null, 'the guagua on the road (' + SZ.guagua.join(' x ') + ' px stand-in), far below the wall: its bottom middle at column 160 on the road\'s row (LAND.road + (240 - 160) .1 = ' + r2(L.road + 80 * .1) + ')', { size: SZ.guagua, anchor: 'bottom', px: [160, road(160)] });
  add('guagua_se_va', [0, 0, 0], 'thing', null, null, 'the guagua going off (119, the end): column 136 on the road\'s row (' + r2(L.road + 104 * .1) + '); not a name of the spec', { size: SZ.guagua, anchor: 'bottom', px: [136, road(136)] });
  add('musico_lejos1', [0, 0, 0], 'thing', null, null, 'the first of the two músicos walking off along the road (119, step 2): a ' + SZ.lejos.join(' x ') + ' figure, bottom middle at column 172 on the road\'s row (' + r2(L.road + 68 * .1) + '); not a name of the spec', { size: SZ.lejos, anchor: 'bottom', px: [172, road(172)] });
  add('musico_lejos2', [0, 0, 0], 'thing', null, null, 'the second músico walking off: a ' + SZ.lejos.join(' x ') + ' figure, bottom middle at column 177 on the road\'s row (' + r2(L.road + 63 * .1) + '); not a name of the spec', { size: SZ.lejos, anchor: 'bottom', px: [177, road(177)] });
  // at the end: the family at the parapet
  [[-1.6, 1.6, 'adulto', 'abuela'], [-.65, 1.6, 'adulto', 'abuelo'], [.3, 1.6, 'nino', 'Luis'], [-2.5, 2.6, 'nino', 'Carmen']].forEach(([u, v, w, who], i) => add('pretil' + (i + 1), [u, v, 0], 'person', w, w, 'at the parapet at the end (119), place ' + (i + 1) + ' of 4 (u ' + u + ', v ' + v + '): ' + who, {}));
  add('pretil_coqui', [1.3, 1.9, 0], 'place', 'coqui', 'coqui', 'the frog at the parapet at the end (119)', {});
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.px ? d.px : d.uvz, uvz: MOVES[d.name].to || d.uvz, px: MOVES[d.name].screen || d.px, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on the bench, the table, the parapet are on what the set draws),
   things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (the head of everyone who sits covered by nobody and by nothing),
   lanterns-clear, doors-clear, candle-clear, table-clear (m4), table-clear5 (m5), guagua-clear, steps-clear.
   A failing line names its numbers; with --suggest, the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => ({ E: MURALLA.E, scene: PP_SCENE, W, H, S, OX, OY }));
  // a second copy of the set with the cord left out: the pixels that differ are the cord's (the guagua is far behind it)
  const pp = await browser.newPage();
  pp.on('pageerror', e => errs.push(String(e)));
  await pp.route(BASE + '/**', serve);
  await pp.goto(PAGE + '?tags=1');
  G.cord = await pp.evaluate(() => {
    const was = Float32Array.from(bakedZ); FT.cord = () => {}; buildSet();
    const cells = []; for (let i = 0; i < W * H; i++) if (was[i] !== bakedZ[i]) cells.push([i % W, Math.floor(i / W)]);
    return cells;
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs, sheet);
  const results = await checks(sheet, G, probes, PV);
  sheet.setKey.baked = [...new Set(MOMENTS.map(m => '?hora=' + PV.moment[m].set.hora))];
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

/* ---------- the preview's moments: muralla-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/muralla-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(a => window.PREVIEW.silhouette(a.k), { k: v });
  // the moment's layers with the layers at one spot placed by an override (the others are the same)
  PV.try = async (m, ov) => {
    const at = Object.keys(ov)[0], one = await p.evaluate(a => window.PREVIEW.inspectAt(a.m, a.at, a.ov), { m, at, ov });
    return { layers: PV.inspect[m].layers.map(l => l.at === at ? one.shift() : l) };
  };
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
  const E = G.E, sc = G.scene, DEF = defs(E, G);
  const pr = await proj(DEF.map(d => d.uvz));
  const SIN = .5, spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i];
    let sx = Math.round(q[0]), sy = Math.round(q[1]), depth = q[2], world = [q[3], q[4], d.uvz[2]], uv = d.uvz;
    if (d.px) {                                                                    // given in picture pixels: the line of sight at z 0 through the pixel
      sx = d.px[0]; sy = d.px[1];
      const v = (sy - G.OY) / (G.S * SIN), u = (sx - G.OX) / G.S;
      uv = [u, v, 0]; world = [(u + v) / R2, (v - u) / R2, 0]; depth = v * COS;
    }
    const o = { world: W4(world), uv: W4(uv), screen: [sx, sy], depth: r4(depth), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.px) o.px = 1;
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.clip) o.clip = d.clip;
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.thingName) o.thing = d.thingName;
    if (d.fixed) o.fixed = 1;
    if (d.moved) { o.spec = d.px ? d.spec.slice() : W4(d.spec); o.moved = d.moved; }
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [117, 118, 119], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 117, 118 and 119: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what, more) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    const t = { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
    if (v0 === v1 && z0 !== z1) t.quad = [0, 1, 5, 4].map(i => W4([q[i][3], q[i][4], corners[i][2]]));          // a plane facing the camera: its four corners
    return Object.assign(t, more || {});
  };
  const things = {};
  const BX = E.BOXES, T = E.TABLE, ST = E.STEPS, BN = E.BENCH;
  const doorV = r4(BX[0].v + .5);                                                   // the boxes' front face
  things.puerta_roja = await setThing(r4(BX[0].u - .3), doorV, 0, r4(BX[0].u + .3), doorV, DOOR_Z, 'the red sentry box\'s door (BOXES[0] u ' + BX[0].u + ', v ' + BX[0].v + ': its front face is at v ' + doorV + ', the door from u ' + r4(BX[0].u - .3) + ' to ' + r4(BX[0].u + .3) + ', z 0 to ' + DOOR_Z + '); a touch', { colour: BX[0].door });
  things.puerta_azul = await setThing(r4(BX[1].u - .3), doorV, 0, r4(BX[1].u + .3), doorV, DOOR_Z, 'the blue sentry box\'s door (BOXES[1] u ' + BX[1].u + ': as puerta_roja); a touch', { colour: BX[1].door });
  things.banco = await setThing(r4(BN.u - BN.hw), r4(BN.v - .26), 0, r4(BN.u + BN.hw), r4(BN.v + .26), SEAT_Z, 'the bench against the parapet (BENCH u ' + BN.u + ', v ' + BN.v + ', hw ' + BN.hw + ': the seat\'s box u ' + r4(BN.u - BN.hw) + ' to ' + r4(BN.u + BN.hw) + ', v ' + r4(BN.v - .26) + ' to ' + r4(BN.v + .26) + ', z 0 to ' + SEAT_Z + '); a touch');
  things.escalera = await setThing(ST.u0, ST.v0, 0, ST.u1, ST.v1, 0, 'the head of the steps: the hole in the walk (STEPS u ' + ST.u0 + ' to ' + ST.u1 + ', v ' + ST.v0 + ' to ' + ST.v1 + ', on the floor, z 0; the rail at its far side is not in the box); a touch');
  for (const k of ['camara', 'silla', 'jugo', 'plato', 'vela', 'guitarra', 'sombrero', 'bolsa', 'caja', 'libro', 'guagua', 'farol1', 'farol2', 'farol3']) things[k] = 'sprite';
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'coqui']) things[k] = 'sprite';
  const touch = { camara: 'camara', silla: 'junto_mesa', jugo: 'jugo', plato: 'plato', vela: 'vela', guitarra: 'mesa1', sombrero: 'mesa2', bolsa: 'mesa3', caja: 'mesa4', libro: 'mesa5', guagua: 'guagua', farol1: 'farol1', farol2: 'farol2', farol3: 'farol3' };

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: d.px ? d.spec.slice() : W4(d.spec), now: d.px ? d.px.slice() : W4(d.uvz), why: d.moved }));
  const farNote = 'the guagua and the two walking músicos are far below the wall, on the road: given in picture pixels (the spot has px 1: its screen point is the one of the spec, its uv the line of sight through it at z 0, its depth that of that plane (' + r2(spots.guagua.depth) + '), behind every pixel the set bakes: the sky, the sea and the land are not baked)';
  return {
    scene: 'muralla',
    made: 'node docs/proyecto/pixel/muralla-sheet-make.js, from muralla-set.html (window.MURALLA.E) and the design of La muralla (the orchestrator\'s p10-spec, general rules and section muralla). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY, OX: G.OX, OY: G.OY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the parapet at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z (22.52 exactly); the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the walk; z ' + SEAT_Z + ': the bench\'s top; z ' + TABLE_Z + ': the table\'s top; z ' + E.PARAPET + ': the parapet\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the camera, the candle, the glass, the plate, the chair, the table\'s five things, the guagua and the two walking músicos have their bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]); a lantern HANGS: its top middle on the spot (the box [sx - 5, sy, 10, 12]). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41) on (sx, sy), the spot being the bench\'s top; a small thing: see spot. Nobody is drawn turned: whoever is said to have his back to us (abuela at her camera, the guests at the steps) is drawn facing us',
      clip: 'whoever is inside a sentry box (dentro_roja, dentro_azul) is drawn standing at the spot and CLIPPED to the door\'s box (things.puerta_roja.box, things.puerta_azul.box): only the pixels that fall inside it show; the door is drawn open (a dark inside) under him. He casts no shadow',
      far: farNote,
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: {
      params: { hora: { values: ['noche', 'tarde_noche'], default: 'noche', note: 'noche: the moon high; tarde_noche (story 119): the moon low over the sea, and yellow' } },
      key: 'hora, e.g. "hora=noche"',
      baked: [],                                                                       // filled from the preview's moments (the states they draw), below
      note: 'the geometry (and so the depth) is the same in both states: the sheet\'s numbers are read from the set with hora noche. The lanterns, the candle, the camera, the guagua and everything on the table are sprites',
    },
    things,
    spots,
    groups: {
      centro: ['centro1', 'centro2', 'centro3', 'centro4', 'centro5', 'centro6', 'centro7'], banco: ['banco1', 'banco2', 'banco3', 'banco4'], baile: ['baile1', 'baile2', 'baile3', 'baile4', 'baile5', 'baile6'], muro: ['muro1', 'muro2', 'muro3'],
      farol: ['farol1', 'farol2', 'farol3'], mesa: ['mesa1', 'mesa2', 'mesa3', 'mesa4', 'mesa5'], escalera: ['escalera1', 'escalera2', 'escalera3', 'escalera4'], pretil: ['pretil1', 'pretil2', 'pretil3', 'pretil4'],
      touch,
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p10-spec, "muralla"), given in (u, v, z); the parapet, the boxes, the cord, the bench, the table, the steps and the road are read from the set',
      'things: puerta_roja, puerta_azul (the two doors\' faces, from u BOX.u - .3 to + .3, z 0 to ' + DOOR_Z + ', on the boxes\' front face at v ' + doorV + '), banco (the bench\'s seat box) and escalera (the steps\' hole on the floor) are set things with a box; camara, silla, jugo, plato, vela, guitarra, sombrero, bolsa, caja, libro, guagua and farol1 to farol3 are sprites at the spots of the same name (silla at junto_mesa, guitarra to libro at mesa1 to mesa5); the people are sprites',
      'the spec gives no name for the guagua going off (column 136), the two walking músicos (columns 172 and 177), nor for the place of the guagua\'s own column in a second moment: guagua_se_va, musico_lejos1 and musico_lejos2 are the make\'s names (open points)',
      'whoever sits on the bench (banco1 to banco4) is hung by the lap on the seat\'s top; the spot\'s sprite is a grown-up sitting; in the preview the two músicos of story 118 sit at banco2 and banco3 and a guest at banco1 in story 119',
      'the spec gives no sizes for the glass of juice\'s and plate\'s sprites other than 6 x 10 and 12 x 6, the chair 14 x 24, the table\'s five things 10 x 22, 12 x 8, 10 x 12, 12 x 10 and 10 x 8, the camera 12 x 22, the candle 8 x 16, the lantern 10 x 12 and the guagua 22 x 10: those are used; the preview\'s drawings of them are stand-ins',
      'the spec gives no radius for the shadows: El cruce\'s are used (frog .45, grown-ups .35, children .28)',
      'abuelo is kit\'s FAM.abuelo (a grown-up man); the two músicos, don Pepe, the maestra, the piragüero, the señor, the señora and two guest children are kit\'s mkPersona in other colours (the preview says which)',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the table hides the legs of whoever stands behind it, the sentry boxes hide what stands behind them, the parapet hides what is on the road. The guagua and the two walking músicos: rules.far.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet. A hanging lantern: the plane through its spot (the cord\'s own plane, v ' + E.CORD.v + ')',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0 || d.clip).map(d => d.name),
      onSeat: 'whoever sits on the bench, stands on the table, or is inside a sentry box casts none (a shadow cast at the floor under them would show in front of them); the things (lanterns, camera, candle, glass, plate, chair, the table\'s things, the guagua) cast none',
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
  }, Object.fromEntries(Object.entries(sheet.spots).filter(([, s]) => s.on).map(([k, s]) => [k, { screen: s.screen }])));
  // the parapet's top: for rows 58 to 66 and every column, the part and the depth the set drew there (-1e9: nothing: sky)
  const top = await page.evaluate(() => { const o = {}; for (let Y = 58; Y <= 66; Y++) { const r = []; for (let X = 0; X < W; X++) r.push([TAGS[Y * W + X] || null, DEPTH.z[Y * W + X]]); o[Y] = r; } return o; });
  return { spotsPx, top };
}

function checks(sheet, G, probes, PV) { return checksAsync(sheet, G, probes, PV); }
async function checksAsync(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, SIL = PV.sil;
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const cordCells = new Set(G.cord.map(c => key(c[0], c[1])));
  const fixCord = ins => { if (CORD_OK) for (const l of ins.layers) for (const p of l.px) if (p[2] && cordCells.has(key(p[0], p[1]))) p[2] = 0; return ins; };
  if (CORD_OK) { for (const m of MOMENTS) fixCord(PV.inspect[m]); const t = PV.try; PV.try = async (m, ov) => fixCord(await t(m, ov)); }

  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = l.px.length ? Math.min(...l.px.map(p => p[1])) : 0; let tot = 0, hid = 0, cov = 0, cord = 0; const who = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2]) { hid++; if (cordCells.has(key(p[0], p[1]))) cord++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].at; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top, cord };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const shownIn = (L, i, box) => L[i].px.filter(p => !p[2] && inside(box, p[0], p[1])).length;
  const idxAt = (L, at) => L.findIndex(l => l.at === at);

  /* ---- the checks of one moment, from its layers: each returns records { check, m, spots: [the spots it names], text } ---- */
  const doors = [['puerta_roja', T.puerta_roja.box], ['puerta_azul', T.puerta_azul.box]];
  const boxOfLayer = l => { const b = S[l.at].box; return [b[0] + l.sx - S[l.at].screen[0], b[1] + l.sy - S[l.at].screen[1], b[2], b[3]]; };      // a thing's box where the layer is drawn (a spot tried with an override has moved)
  function momentRecords(m, L, o) {
    o = o || {};
    const R = [], M = planes(L), rec = (check, spots, text) => R.push({ check, m, spots, text });
    // sprites-apart: the people who stand together: the sprite boxes do not overlap sideways unless their feet are UPDOWN px or more apart up-down
    const P = L.filter(l => l.who);
    for (let i = 0; i < P.length; i++) for (let j = i + 1; j < P.length; j++) {
      const a = P[i], b = P[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy);
      if (dx < half && dy < UPDOWN) rec('sprites-apart', [a.at, b.at], 'moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down');
    }
    // frog-seen: the frog is never behind a person or a thing of the set
    const fi = L.findIndex(l => l.who === 'coqui');
    if (fi >= 0) {
      const f = L[fi], c = coverOf(L, M, fi, null);
      if (c.hid || c.cov || f.out) rec('frog-seen', [f.at, ...Object.keys(c.who)], 'moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (whoTxt(c) || 'a sprite') + ', ' + f.out + ' outside the picture)');
    }
    // heads-clear: everyone who sits (on the bench) is whole in the window and his head (the top 14 rows) is covered by nobody and by nothing
    for (const [i, l] of L.entries()) {
      if (l.group !== 'head') continue;
      const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, o.x0 - a), cutR = Math.max(0, b - (o.x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
      if (cutL || cutR || l.out) rec('heads-clear', [l.at], 'moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
      if (c.cov || c.hid) rec('heads-clear', [l.at, ...Object.keys(c.who)], 'moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set (' + c.cord + ' of them by the cord)');
    }
    // lanterns-clear: the lanterns are covered by nobody and not hidden by the set
    for (const [i, l] of L.entries()) {
      if (l.group !== 'farol') continue;
      const c = coverOf(L, M, i, null);
      if (c.cov || c.hid || c.out) rec('lanterns-clear', [l.at, ...Object.keys(c.who)], 'moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + c.cov + ' of its ' + c.tot + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture');
    }
    // doors-clear (moments 2 and 3): the two doors' boxes are covered by nobody; whoever is inside is clipped to the door
    if (m === 2 || m === 3) {
      for (const [dn, box] of doors) for (const [i, l] of L.entries()) {
        if (l.group === 'puerta' || l.clip === dn) continue;
        const n = shownIn(L, i, box); if (n) rec('doors-clear', [l.at], 'moment ' + m + ': ' + l.at + ' covers ' + n + ' px of ' + dn + ' [' + box + ']');
      }
      for (const [i, l] of L.entries()) if (l.clip) {
        const box = T[l.clip].box, off = l.px.filter(p => !inside(box, p[0], p[1])).length, hid = l.px.filter(p => p[2]).length;
        if (off || hid) rec('doors-clear', [l.at], 'moment ' + m + ': ' + l.at + ' inside ' + l.clip + ' is not clipped to its box [' + box + ']: ' + off + ' px outside it, ' + hid + ' hidden by the set');
      }
    }
    // candle-clear (moment 4): the candle is covered by nobody and nothing of the set but the cord's own line hides it (the spec says "covered by nobody")
    if (m === 4) {
      const i = L.findIndex(l => l.group === 'vela');
      if (i >= 0) { const c = coverOf(L, M, i, null); if (c.cov || c.out || c.hid - c.cord) rec('candle-clear', [L[i].at, ...Object.keys(c.who)], 'moment ' + m + ' vela ' + [L[i].sx, L[i].sy] + ': ' + c.cov + ' of its ' + c.tot + ' px covered by ' + (whoTxt(c) || 'nobody') + ' (' + c.hid + ' hidden by the set, ' + c.cord + ' of them by the cord), ' + c.out + ' outside the picture'); }
    }
    // table-clear (moments 4 and 5): the things on the table (and the chair) are covered by nobody, and the frog covers none
    if (m === 4 || m === 5) {
      const fr = L.findIndex(l => l.who === 'coqui');
      for (const [i, l] of L.entries()) {
        if (l.group !== 'mesa' && l.group !== 'silla' && !(m === 5 && /^mesa\d$/.test(l.at))) continue;
        const c = coverOf(L, M, i, null), n = fr >= 0 ? shownIn(L, fr, boxOfLayer(l)) : 0;
        if (c.cov || c.hid || c.out) rec('table-clear', [l.at, ...Object.keys(c.who)], 'moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + c.cov + ' of its ' + c.tot + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture');
        if (n) rec('table-clear', [l.at, L[fr].at], 'moment ' + m + ': the frog at ' + L[fr].at + ' has ' + n + ' px of his in the box of ' + l.at + ' [' + boxOfLayer(l) + ']');
      }
    }
    // guagua-clear (moments 5 and 6): the guagua's box is covered by nobody and hidden by nothing of the set
    if (m === 5 || m === 6) {
      const i = L.findIndex(l => l.group === 'guagua');
      if (i >= 0) {
        const c = coverOf(L, M, i, null), box = boxOfLayer(L[i]), others = [];
        for (const [j, l] of L.entries()) if (j !== i) { const n = shownIn(L, j, box); if (n) others.push(l.at + ' ' + n); }
        if (c.cov || c.hid || c.out || others.length) rec('guagua-clear', [L[i].at, ...new Set([...Object.keys(c.who), ...others.map(s => s.split(' ')[0])])], 'moment ' + m + ' ' + L[i].at + ' ' + [L[i].sx, L[i].sy] + ' box [' + box + ']: ' + c.cov + ' of its ' + c.tot + ' px covered by ' + (whoTxt(c) || 'nobody') + '; other sprites have shown pixels in its box: ' + (others.join(', ') || 'none') + '; ' + c.hid + ' px hidden by the set (' + c.cord + ' of them by the cord, ' + (c.hid - c.cord) + ' by the rest of the set), ' + c.out + ' outside the picture');
      }
    }
    return R;
  }
  PV.records = (m, L, o) => momentRecords(m, L, Object.assign({ x0 }, o));
  const recordsAll = (m, L) => momentRecords(m, L, { x0 });

  // gather every record of every moment
  const REC = {}; for (const m of MOMENTS) REC[m] = recordsAll(m, PV.inspect[m].layers);
  const recOf = name => MOMENTS.flatMap(m => REC[m].filter(r => r.check === name));

  /* ---- the nearest passing place of a spot (v first, then u, never z) ---- */
  const T_ = E.TABLE, BN_ = E.BENCH, ST_ = E.STEPS, BXS = E.BOXES, PARAPET_D = S.vela.depth;                  // the parapet's own plane at its top: the candle's depth
  const solidUnder = (sx, sy, w) => { const [a, b] = [sx - Math.floor(w / 2), sx - Math.floor(w / 2) + w - 1]; for (let c = a; c <= b; c++) { const ok = [sy, sy + 1].some(r => { const p = probes.top[r] && probes.top[r][c]; return p && p[0] === 'pretil' && Math.abs(p[1] - PARAPET_D) < .12; }); if (!ok) return false; } return true; };
  const allowed = (name, uvz) => {
    const s = S[name], [u, v, z] = uvz, sc = scrUV(G, u, v, z), t = Object.assign({}, s, { screen: sc });
    if (s.box) t.box = [s.box[0] + sc[0] - s.screen[0], s.box[1] + sc[1] - s.screen[1], s.box[2], s.box[3]];
    if (cutAt(t, x0) || colsOf(t)[0] < 0 || colsOf(t)[1] > G.W - 1 || sc[1] < 0 || sc[1] > G.H - 1) return false;
    if (s.on === 'paseo' && z === TABLE_Z) return u >= T_.u - T_.hw + .08 && u <= T_.u + T_.hw - .08 && v >= T_.v - T_.hd + .05 && v <= T_.v + T_.hd - .05;
    if (s.on === 'paseo') return v === BN_.v && u >= BN_.u - BN_.hw + .15 && u <= BN_.u + BN_.hw - .15;
    if (s.on === 'pretil') return v === 0 && solidUnder(sc[0], sc[1], s.size ? s.size[0] : 8);
    if (z === 0 && !s.clip && !s.px) {                                                                         // on the walk: not inside a box, the table, the bench or the steps' hole (baja stands in it)
      for (const B of BXS) if (Math.abs(u - B.u) < .62 + .15 && v > B.v - .5 - .1 && v < B.v + .5 + .05) return false;
      if (u > T_.u - T_.hw - .1 && u < T_.u + T_.hw + .1 && v > T_.v - T_.hd - .05 && v < T_.v + T_.hd + .05 && s.kind !== 'thing') return false;
      if (name !== 'baja' && u > ST_.u0 && u < ST_.u1 && v > ST_.v0 && v < ST_.v1) return false;
      if (v < BN_.v + .35) return false;
    }
    return true;
  };
  const momentsOf = name => MOMENTS.filter(m => PV.moment[m].layers.some(l => l.at === name));
  async function nearest(name) {
    const s = S[name], res = {};
    if (s.fixed) return 'fixed by the set: not moved';
    if (s.px) {                                                                    // a spot in picture px: its column
      for (let k = 1; k <= 120; k++) for (const sg of [-1, 1]) {
        const col = s.screen[0] + sg * k, row = Math.round(E.LAND.road + (240 - col) * .1), ov = { [name]: { screen: [col, row] } };
        if (col < 0 || col + 11 > G.W - 1 || col < E.LAND.x0) continue;
        let bad = 0;
        for (const m of momentsOf(name)) { const ins = await PV.try(m, ov); if (momentRecords(m, ins.layers, { x0 }).some(r => r.spots.includes(name))) { bad = 1; break; } }
        if (!bad) return 'column ' + s.screen[0] + ' -> ' + col + ' (' + sgn(sg * k) + ' px)';
      }
      return 'no column within 120 px passes';
    }
    for (const [ax, lab] of [[1, 'v'], [0, 'u']]) {
      const seen = new Set([s.screen.join(',')]);                                 // only the first (least) shift that lands on each new screen point is tried
      for (let k = 1; k <= 300 && !res[lab]; k++) {
        for (const sg of [-1, 1]) {
          const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * k * .01); if (!allowed(name, q)) continue;
          const sc = scrUV(G, q[0], q[1], q[2]).join(','); if (seen.has(sc)) continue; seen.add(sc);
          const ov = { [name]: { uvz: q } }; let bad = 0;
          const me = s.who ? { who: s.who, sx: scrUV(G, q[0], q[1], q[2])[0], sy: scrUV(G, q[0], q[1], q[2])[1] } : null;
          if (me) for (const m of momentsOf(name)) for (const o of PV.inspect[m].layers) if (o.who && o.at !== name) { if (Math.abs(o.sx - me.sx) < (WIDTH[o.who] + WIDTH[me.who]) / 2 && Math.abs(o.sy - me.sy) < UPDOWN) bad = 1; }
          if (bad) continue;
          for (const m of momentsOf(name)) { const ins = await PV.try(m, ov); if (momentRecords(m, ins.layers, { x0 }).some(r => r.spots.includes(name))) { bad = 1; break; } }
          if (!bad) { res[lab] = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * k * .01) + ')'; break; }
        }
      }
    }
    return [res.v || 'v: none within 3', res.u || 'u: none within 3'].join('; ');
  }
  const hint = async (o, recs) => { if (!SUGGEST) return; const names = [...new Set(recs.flatMap(r => r.spots))]; for (const n of names) o.lines.push('       nearest passing, ' + n + ' ' + (S[n].px ? S[n].screen : S[n].uv) + ': ' + await nearest(n)); };

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole
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
    const left = Object.entries(S).sort((p, q) => colsOf(p[1])[0] - colsOf(q[1])[0])[0], right = Object.entries(S).sort((p, q) => colsOf(q[1])[1] - colsOf(p[1])[1])[0];
    add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + colsOf(left[1])[0] + ' (' + left[0] + '), the rightmost ' + colsOf(right[1])[1] + ' (' + right[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 3. the spots above the floor are on what the set draws: the bench's top (z .46) and the table's top (z .74) part paseo, the parapet's top part pretil (solid under every column of the candle)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground' || s.on === 'cuerda') continue;
      const tol = .1;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      let ok = best && best.r.tag === tag && best.dz < tol;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
      if (s.on === 'pretil' && s.box) {                                            // the parapet is solid under every column of the candle's box (a merlon, not a gap)
        const w = s.box[2], a = s.box[0], gaps = []; for (let c = a; c < a + w; c++) if (!solidUnder(c, s.screen[1], 1)) gaps.push(c);
        lines.push(k + ': the parapet under its ' + w + ' columns (' + a + ' to ' + (a + w - 1) + '): ' + (gaps.length ? 'a gap at column(s) ' + gaps.join(', ') : 'solid (a merlon: u from ' + r4((s.box[0] - G.OX) / G.S) + ' to ' + r4((a + w - G.OX) / G.S) + ')'));
        if (gaps.length) bad.push(k + ' ' + s.screen + ': the parapet is not solid under the candle\'s columns (gap at ' + gaps.join(', ') + ')');
      }
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface the set draws (the bench\'s top z ' + SEAT_Z + ' and the table\'s top z ' + TABLE_Z + ' part paseo, the parapet\'s top z ' + E.PARAPET + ' part pretil: depth within .1 of the spot\'s; the parapet solid under all the candle\'s columns)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
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

  // 5. sprites-apart
  {
    const bad = recOf('sprites-apart'), all = [];
    for (const m of MOMENTS) { const P = PV.inspect[m].layers.filter(l => l.who); for (let i = 0; i < P.length; i++) for (let j = i + 1; j < P.length; j++) { const a = P[i], b = P[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy); all.push({ m, a: a.at, b: b.at, dx, dy, half, over: dx < half }); } }
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + MOMENTS.map(m => 'm' + m + ' (' + PV.inspect[m].layers.filter(l => l.who).map(l => l.at).join(', ') + ')').join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b.text)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: !(q.over && q.dy < UPDOWN) }));
    await hint(o, bad);
  }

  // 6. frog-seen
  {
    const bad = recOf('frog-seen'), lines = [];
    for (const m of MOMENTS) { const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null); lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture'); }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b.text)));
    await hint(o, bad);
  }

  // 7. heads-clear
  {
    const bad = recOf('heads-clear'), lines = [];
    for (const m of MOMENTS) { const L = PV.inspect[m].layers, M = planes(L); for (const [i, l] of L.entries()) { if (l.group !== 'head') continue; const c = coverOf(L, M, i, null, [0, HEAD_ROWS]); lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); } }
    const o = add('heads-clear', bad, 'everyone who sits (' + MOMENTS.map(m => 'm' + m + ': ' + (PV.inspect[m].layers.filter(l => l.group === 'head').map(l => l.at).join(', ') || 'nobody')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people who sit:'].concat(bad.map(b => '  ' + b.text)));
    o.lines.push('       info, not a check: ' + lines.join('; '));
    if (bad.length) {
      let cov = 0, hid = 0, cord = 0;
      for (const m of MOMENTS) { const L = PV.inspect[m].layers, M = planes(L); for (const [i, l] of L.entries()) if (l.group === 'head') { const c = coverOf(L, M, i, null, [0, HEAD_ROWS]); cov += c.cov; hid += c.hid; cord += c.cord; } }
      o.lines.push('       OPEN POINT: ' + cov + ' px of the heads are covered by a person and ' + hid + ' are hidden by the set, ' + cord + ' of those by the cord (a 1 px line of the set at v ' + E.CORD.v + ', z ' + r2(E.CORD.z - E.CORD.sag) + ' to ' + E.CORD.z + ': nearer than the bench at v ' + E.BENCH.v + ', it crosses the head of everyone who sits anywhere under it: rows ' + (() => { const rs = G.cord.filter(c => c[0] >= 55 && c[0] <= 185).map(c => c[1]); return Math.min(...rs) + ' to ' + Math.max(...rs); })() + ' against heads at rows 38 to 55); no place on the bench passes while the cord counts. Read with --cord-ok (the cord\'s pixels hide nothing) the check ' + (hid === cord && cov === 0 ? 'passes' : 'still fails'));
    }
    await hint(o, bad);
  }

  // 8. lanterns-clear: in every moment the lanterns are covered by nobody (and not hidden by the set)
  {
    const bad = recOf('lanterns-clear'), lines = [];
    for (const m of MOMENTS) { const L = PV.inspect[m].layers, M = planes(L); lines.push('m' + m + ': ' + L.map((l, i) => [l, i]).filter(([l]) => l.group === 'farol').map(([l, i]) => { const c = coverOf(L, M, i, null); return l.at + ' [' + S[l.at].box + '] ' + c.cov + ' covered, ' + c.hid + ' hidden'; }).join(', ')); }
    const o = add('lanterns-clear', bad, 'the lanterns (m1 to m5: farol1 to farol3; m6: farol2) are covered by nobody and hidden by nothing of the set in every moment: ' + lines.join('; '), [bad.length + ' covering(s):'].concat(bad.map(b => '  ' + b.text)));
    await hint(o, bad);
  }

  // 9. doors-clear (moments 2 and 3)
  {
    const bad = recOf('doors-clear'), lines = [];
    for (const m of [2, 3]) {
      const L = PV.inspect[m].layers, clipped = L.filter(l => l.clip);
      lines.push('m' + m + ': ' + (clipped.length ? clipped.map(l => l.at + ' (' + l.s + ') is inside ' + l.clip + ' [' + T[l.clip].box + '], ' + l.px.length + ' px shown, ' + l.clipped + ' px cut off by the clip, ' + l.px.filter(p => !inside(T[l.clip].box, p[0], p[1])).length + ' px outside the box').join('; ') : 'nobody inside; both doors\' boxes under nobody'));
    }
    const o = add('doors-clear', bad, 'in moments 2 and 3 the two doors\' boxes (puerta_roja [' + T.puerta_roja.box + '], puerta_azul [' + T.puerta_azul.box + ']) are covered by nobody, and whoever is inside is clipped to the door: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    await hint(o, bad);
  }

  // 10. candle-clear (moment 4): the candle is covered by nobody (the músicos' heads: heads-clear)
  {
    const bad = recOf('candle-clear'), L = PV.inspect[4].layers, M = planes(L), i = L.findIndex(l => l.group === 'vela'), c = coverOf(L, M, i, null);
    const o = add('candle-clear', bad, 'in moment 4 the candle (vela ' + [L[i].sx, L[i].sy] + ' box [' + S.vela.box + ']) is covered by nobody: ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set (' + c.cord + ' of them by the cord\'s line; the spec says "covered by nobody": nothing else of the set hides it), on a merlon of the parapet; the músicos\' heads are heads-clear', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    await hint(o, bad);
  }

  // 11. table-clear (moments 4 and 5): the glass, the plate, the chair (m4) and the four things (m5) are covered by nobody and the frog covers none
  {
    const bad = recOf('table-clear'), lines = [];
    for (const m of [4, 5]) {
      const L = PV.inspect[m].layers, M = planes(L), fr = L.findIndex(l => l.who === 'coqui'), parts = [];
      for (const [i, l] of L.entries()) { if (!(l.group === 'mesa' || l.group === 'silla' || (m === 5 && /^mesa\d$/.test(l.at)))) continue; const c = coverOf(L, M, i, null); parts.push(l.at + ' [' + S[l.at].box + '] ' + c.cov + ' covered, ' + c.hid + ' hidden, ' + shownIn(L, fr, S[l.at].box) + ' px of the frog in its box'); }
      lines.push('m' + m + ' (the frog at ' + L[fr].at + ' ' + [L[fr].sx, L[fr].sy] + '): ' + parts.join('; '));
    }
    const o = add('table-clear', bad, 'the glass, the plate and the chair (m4) and the four things on the table (m5: mesa2 to mesa5) are covered by nobody, not hidden by the set, and the frog covers none (none of his pixels on theirs or in their boxes): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    await hint(o, bad);
  }

  // 12. guagua-clear (moments 5 and 6)
  {
    const bad = recOf('guagua-clear'), lines = []; let rest = 0;                                                  // rest: what is left to fail when the cord is not counted
    for (const m of [5, 6]) { const L = PV.inspect[m].layers, M = planes(L), i = L.findIndex(l => l.group === 'guagua'), c = coverOf(L, M, i, null); rest += c.cov + c.hid - c.cord + c.out + L.reduce((a, l, j) => a + (j === i ? 0 : shownIn(L, j, boxOfLayer(L[i]))), 0); lines.push('m' + m + ' ' + L[i].at + ' ' + [L[i].sx, L[i].sy] + ' box [' + S[L[i].at].box + ']: ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set (' + c.cord + ' by the cord)'); }
    const o = add('guagua-clear', bad, 'the guagua\'s box is covered by nobody and hidden by nothing of the set in moments 5 and 6: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) o.lines.push('       OPEN POINT: ' + lines.join('; ') + '. The cord (a 1 px line of the set at v ' + E.CORD.v + ', nearer than the road) crosses the guagua\'s box in the rows ' + (() => { const rs = G.cord.filter(c => { const b = S.guagua.box; return c[0] >= b[0] && c[0] < b[0] + b[2]; }).map(c => c[1]); return rs.length ? Math.min(...rs) + ' to ' + Math.max(...rs) : 'none'; })() + ' and hides one pixel of it per column wherever the guagua stands on the road (the road, from column ' + E.LAND.x0 + ', lies under the cord, which runs from column ' + Math.round(G.OX + E.CORD.u0 * G.S) + ' to ' + Math.round(G.OX + E.CORD.u1 * G.S) + ', at every column of it): no column passes "hidden by nothing of the set" while the cord counts. Read with --cord-ok it ' + (rest === 0 ? 'passes' : 'still fails'));
    await hint(o, bad);
  }

  // 13. steps-clear: nobody stands on the steps' hole except at baja
  {
    const bad = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      if (!s.who || s.px) continue;
      const [u, v] = s.uv, inHole = u > E.STEPS.u0 && u < E.STEPS.u1 && v > E.STEPS.v0 && v < E.STEPS.v1;
      names.push(k);
      if (inHole && k !== 'baja') bad.push(k + ' (u ' + u + ', v ' + v + ') stands on the steps\' hole (u ' + E.STEPS.u0 + ' to ' + E.STEPS.u1 + ', v ' + E.STEPS.v0 + ' to ' + E.STEPS.v1 + ')');
    }
    const b = S.baja.uv;
    add('steps-clear', bad, 'none of the ' + names.length + ' places of people stands on the steps\' hole (u ' + E.STEPS.u0 + ' to ' + E.STEPS.u1 + ', v ' + E.STEPS.v0 + ' to ' + E.STEPS.v1 + ') except baja (' + b[0] + ', ' + b[1] + ')', [bad.length + ' on the hole:'].concat(bad.map(x => '  ' + x)));
  }

  // info: the groups of places of people that are never all drawn together in a moment (the bench's four places, the six dancers ...): the same box rule, not a check of the spec
  {
    const bad = [], names = Object.entries(sheet.groups).filter(([k]) => k !== 'touch' && k !== 'mesa' && k !== 'farol');
    for (const [gn, g] of names) for (let i = 0; i < g.length; i++) for (let j = i + 1; j < g.length; j++) {
      const a = S[g[i]], b = S[g[j]]; if (!a.who || !b.who) continue;
      const half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.screen[0] - b.screen[0]), dy = Math.abs(a.screen[1] - b.screen[1]);
      if (dx < half && dy < UPDOWN) bad.push(gn + ': ' + g[i] + ' ~ ' + g[j] + ' ' + dx + '/' + dy);
    }
    OUTS.push({ name: 'info-groups', ok: true, lines: ['info-groups: not a check. Pairs of one group (' + names.map(([k]) => k).join(', ') + ') whose boxes overlap sideways with feet closer than ' + UPDOWN + ' px up-down: ' + (bad.join(', ') || 'none')] });
  }

  // info: the things he can touch that the spec lists no check for (the camera, the bench), who stands over them: not checks of the spec
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const [i, l] of L.entries()) if (l.s === 'camara') { const c = coverOf(L, M, i, null); parts.push('camara ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '')); }
      for (const [i, l] of L.entries()) if (l.s === 'puertaRoja') parts.push('the red door is open (a stand-in)');
      lines.push('m' + m + ': ' + (parts.join(', ') || 'no camera'));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
