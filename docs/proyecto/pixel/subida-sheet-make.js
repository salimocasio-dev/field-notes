#!/usr/bin/env node
'use strict';
/* El camino al fuerte's sheet (place 10, El fuerte, scene 1, stories 108 to 110): writes docs/proyecto/pixel/subida-sheet.json from subida-set.html and the design (the orchestrator's p10-spec, the general rules and the section "subida"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/subida-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 104 here). The wall, the gate, the pole, the sentry box, the tree, the stone, the table, the hammock's posts and the grass are read from
   the set (window.SUBIDA.E), never typed again from the design.
   It loads the set in headless Chrome (subida-set.html, tags=1: which part drew each pixel; the depth), and writes the spots, things, the view (wide), shadows and the depth rule. The sprites' silhouettes come from the preview's
   own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (subida-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it,
   and then the sheet is written again with the checks.
   THE TREE'S LEAVES SWAY: so the depth the sprites are tested against is the LIVE depth of the still frame (frame(0), t = 0: window.DEPTH.live(): the baked depth and the leaves), not the baked depth alone.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with SUBIDA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'subida-sheet.json');
const BASE = process.env.SUBIDA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/subida-set.html';
const SETQ = 'hora=noche&fiesta=1';                      // the set the make reads its numbers from: the party table and the hammock's posts up (fiesta 1); the geometry is the same in every hour
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

// the numbers of the design (p10-spec: the rules for every sheet, and "subida")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const TABLE_Z = .74, STONE_Z = .2, HOOK_Z = { muralla: 1.6, puerta: 2.1, bandera: 3.0 }, FLAG_Z = 3.95, PAPER_Z = 1.55, HAMMOCK_Z = .7, FAROL_Z = .5;
const WAIST = 16 + 2 * 11;                               // canvas row of a grown-up's waist (mkPersona: hips' centre 16 + 2 t, t 11): the guests behind the table show from here up
const SZ = { gancho: [8, 10], bandera: [16, 10], cartel: [30, 30], canasta: [12, 10], comida: [20, 10], jugos: [16, 12], hamaca: [50, 12], bola: [8, 8], farol: [8, 10] };
const PIC = { size: 12, dx: [2, 16], dy: 16 };           // the paper's two round pictures: 12 x 12, at paper columns 2 and 16 (2 px apart, 2 px from each edge), rows 16 to 27 (its lower half)
const MOMENTS = [1, 2, 3, 4, 5, 6];
const SILKEY = { adulto: 'abuelo', nino: 'luis', coqui: 'coqui', abuela: 'abuela' };       // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a shelf, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  muro_coqui: { to: [1.44, 0, 2.5], why: 'spots-on-surface: at u 1.6 the spot falls in a gap between two merlons ((u + 60.26) mod .9 = .66; merlons are 0 to .52), so the set\'s pixel under the frog\'s feet is the walk behind them (depth .69, not 1.25 = z 2.5 x .5): u 1.6 -> 1.44 (-.16: the nearest u whose pixel is a merlon\'s top: the merlon from u .94 to 1.46; the next one up starts at u 1.84, +.23)' },
  camino2: { to: [.09, 4.6, 0], why: 'sprites-apart: in moments 1 and 2 Luis at camino2 and Carmen at camino_lado were 23 px apart sideways on rows 8 px apart (24 and 12 needed): u .1 -> .09 (-.01; the other spot, camino_lado: u 1 -> 1.02, +.02, or v 4 -> 3.73, -.27; camino2 v 4.6 -> 4.89, +.29)' },
  entra: { to: [.06, 1.3, 0], why: 'sprites-apart: in moment 5 the frog at junto_puerta and the guest at entra were 26 px apart sideways on rows 3 px apart (28 and 12 needed): u 0 -> .06 (+.06; the same distance by the other spot: junto_puerta u -1 -> -1.06; by v: entra v 1.3 -> .65, junto_puerta v 1.5 -> 2.2). Tie: the guest moved, the frog stays' },
  mesa_comida: { to: [2.1, 1.75, 0], why: 'faroles-clear: in moment 5 the guest behind the table\'s food end (1.6, 1.75), nearer the camera than the gate, covered 47 of the 80 px of the second lantern by the gate and 54 of the third (faroles2, faroles3: their boxes are at columns 149 to 156 and 156 to 163, the guest\'s sprite at 150 to 173): u 1.6 -> 2.1 (+.50: the least u that clears both; v .88 would put him behind the lanterns, -.87, beside the gate wall; the lanterns have no free axis)' },
  mesa_jugos: { to: [3.02, 1.75, 0], why: 'sprites-apart: after mesa_comida moved to u 2.1 the two guests behind the table (moment 5) were 20 px apart sideways on the same row (24 needed): u 2.9 -> 3.02 (+.12; the other way, mesa_comida u 2.1 -> 1.98, would put him back over the lanterns)' },
  junto_carmen: { to: [-.75, 3.34, 0], why: 'frog-seen: in moment 3 the flat stone (STONE u -1.25, v 3.9, top z .2) hid 11 px of the frog\'s feet: v 3.6 -> 3.34 (-.26; by u: -.75 -> -.48, +.27)' },
};

const ANCH = { top: 'its top middle on the point', bottom: 'its bottom middle on the point', left: 'its left middle on the point', centre: 'its middle on the point' };

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed }
   kind: person (a character stands there), place (the frog's), thing (a small thing: a lantern, the flag, the paper, the basket, the dish, the jugs, the hammock, the ball)
   sil: which drawing hangs there (adulto = a grown-up standing, nino = a child standing, abuela, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point (hangs), bottom = its bottom middle on the point, left = its left middle on the point, centre = its middle on the point
   on: the part of the set it stands on above the ground: fuerte (the wall, the pole), grama (the lawn: the stone, the table's top, the trunk) */
function defs(E) {
  const W = E.WALL, P = E.POLE, T = E.TABLE, H = E.HAMMOCK, TR = E.TREE, ST = E.STONE, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const th = (name, uvz, size, anchor, what, more) => add(name, uvz, 'thing', null, null, what + ' (' + (size[0] === 8 ? 'an ' : 'a ') + size.join(' x ') + ' px stand-in): ' + ANCH[anchor], Object.assign({ size, anchor }, more || {}));
  // the path
  add('camino1', [0, 3.0, 0], 'person', 'adulto', 'adulto', 'the path, first: somebody coming up (108, 109: not drawn in a moment of the spec)', {});
  add('camino2', [.1, 4.6, 0], 'person', 'nino', 'nino', 'the path, second: Luis (m1, m2)', {});
  add('camino3', [-.1, 6.2, 0], 'person', 'adulto', 'adulto', 'the path, third: a boy (m2), el joven (m4)', {});
  add('camino4', [.1, 7.8, 0], 'person', 'adulto', 'adulto', 'the path, fourth: el piragüero (m4)', {});
  add('camino_lado', [1.0, 4.0, 0], 'person', 'nino', 'nino', 'Carmen beside the path, with her basket (m1, m2)', {});
  // the gate
  add('ante_puerta', [0, .9, 0], 'place', 'coqui', 'coqui', 'the frog at the gate (m1)', {});
  add('junto_puerta', [-1.0, 1.5, 0], 'place', 'coqui', 'coqui', 'the frog beside the gate (m5, story 110)', {});
  add('entra', [0, 1.3, 0], 'person', 'adulto', 'adulto', 'a guest who has just come in at the gate (m5)', {});
  add('puerta_abuela', [2.35, .8, 0], 'person', 'abuela', 'adulto', 'abuela beside the gate (m4, m5, m6)', {});
  add('muro_coqui', [1.6, 0, W.h], 'place', 'coqui', 'coqui', 'the frog on the wall\'s top, right of the gate (u 1.6, v 0, z WALL.h = ' + W.h + ': the battlements\' top)', { on: 'fuerte' });
  // the three hooks and the flag
  th('gancho_muralla', [2.0, .02, HOOK_Z.muralla], SZ.gancho, 'top', 'the hook on the wall for a lantern (108): it hangs (a lantern)', { on: 'fuerte' });
  th('gancho_puerta', [0, .02, HOOK_Z.puerta], SZ.gancho, 'top', 'the hook over the gate for a lantern (108): it hangs (a lantern)', { on: 'fuerte' });
  th('gancho_bandera', [P.u, P.v, HOOK_Z.bandera], SZ.gancho, 'top', 'the hook on the flag\'s pole for a lantern (108): it hangs (a lantern)', { on: 'fuerte' });
  th('bandera', [P.u, P.v, FLAG_Z], SZ.bandera, 'left', 'the flag on its pole (the pole\'s top is z ' + P.z1 + ')', { on: 'fuerte' });
  // by the tree
  add('arbol', [-1.85, 2.7, 0], 'person', 'nino', 'nino', 'Carmen sitting by the tree (108 game): drawn standing', {});
  th('canasta', [-1.3, 3.0, 0], SZ.canasta, 'bottom', 'Carmen\'s basket by the tree (108 game)', {});
  add('junto_carmen', [-.75, 3.6, 0], 'place', 'coqui', 'coqui', 'the frog beside Carmen (108 game)', {});
  th('cartel', [r4(TR[0]), r4(TR[1] + .05), PAPER_Z], SZ.cartel, 'top', 'Luis\'s paper on the tree\'s trunk (TREE u ' + TR[0] + ', v ' + TR[1] + ' + .05; in front of the trunk); its two round pictures are things.cartel_quien and things.cartel_cuando', { on: 'grama' });
  add('piedra', [ST[0], ST[1], STONE_Z], 'place', 'coqui', 'coqui', 'the frog on the flat stone (STONE u ' + ST[0] + ', v ' + ST[1] + '): its top, z ' + STONE_Z, { on: 'grama' });
  add('luis_cartel', [-2.6, 5.2, 0], 'person', 'nino', 'nino', 'Luis below the paper (109)', {});
  add('junto_cartel', [0, 3.3, 0], 'person', 'adulto', 'adulto', 'a passer-by who has stopped at the paper (109)', {});
  add('sale_grama', [-3.2, 7.6, 0], 'person', 'adulto', 'adulto', 'the way off across the lawn (109: a passer-by who walks on; in no moment of the spec)', {});
  // story 110
  add('mesa_comida', [r4(T.u - .65), r4(T.v - T.hd - .1), 0], 'person', 'adulto', 'adulto', 'a guest behind the table\'s food end (TABLE.u - .65, TABLE.v - TABLE.hd - .1; the table is u ' + r4(T.u - T.hw) + ' to ' + r4(T.u + T.hw) + ', v ' + r4(T.v - T.hd) + ' to ' + r4(T.v + T.hd) + ')', {});
  add('mesa_jugos', [r4(T.u + .65), r4(T.v - T.hd - .1), 0], 'person', 'adulto', 'adulto', 'a guest behind the table\'s jugs end (TABLE.u + .65, TABLE.v - TABLE.hd - .1)', {});
  th('comida', [r4(T.u - .65), T.v, TABLE_Z], SZ.comida, 'bottom', 'the dish on the table (TABLE.u - .65, TABLE.v): on its top, z ' + TABLE_Z, { on: 'grama' });
  th('jugos', [r4(T.u + .65), T.v, TABLE_Z], SZ.jugos, 'bottom', 'the two jugs on the table (TABLE.u + .65, TABLE.v): on its top, z ' + TABLE_Z, { on: 'grama' });
  th('hamaca', [r4((H.u0 + H.u1) / 2), H.v, HAMMOCK_Z], SZ.hamaca, 'centre', 'the hammock between its two posts (HAMMOCK u ' + H.u0 + ' and ' + H.u1 + ', v ' + H.v + '; the posts are ' + H.h + ' high): at z ' + HAMMOCK_Z + '; whoever lies in it (Carmen: her head at its left end) is part of the sprite', {});
  th('hamaca_dentro', [r4((H.u0 + H.u1) / 2), H.v, HAMMOCK_Z], SZ.hamaca, 'centre', 'the same point as hamaca: whoever lies in the hammock is part of that sprite', {});
  add('grama1', [1.4, 5.6, 0], 'person', 'nino', 'nino', 'on the grass: Luis (m6)', {});
  add('grama2', [2.6, 6.4, 0], 'person', 'nino', 'nino', 'on the grass: Carmen (m6)', {});
  add('grama3', [1.9, 7.4, 0], 'place', 'coqui', 'coqui', 'on the grass: the frog (m6)', {});
  th('bola', [2.2, 6.0, 0], SZ.bola, 'bottom', 'the ball on the grass (m6)', {});
  [.95, 1.25, 1.55].forEach((u, i) => th('faroles' + (i + 1), [u, .9, FAROL_Z], SZ.farol, 'bottom', 'lantern ' + (i + 1) + ' of 3 by the gate, on its short stake (right of the gate; the spec\'s "faroles": three points)', {}));
  add('bajo_arbol1', [-1.75, 2.9, 0], 'person', 'adulto', 'adulto', 'a guest under the tree, the left one: don Pepe (m6)', {});
  add('bajo_arbol2', [-.8, 2.9, 0], 'person', 'adulto', 'adulto', 'a guest under the tree, the right one: la maestra (m6)', {});
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots above the ground are on what the set draws: the wall, the pole, the stone, the table's top, the trunk),
   things-in-view (the things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (Carmen by the tree and Carmen in the hammock: the head covered by nobody and by nothing),
   hooks-flag (m3), cartel-clear (m4), faroles-clear (m5, m6), mesa-clear (m5: the dish and the jugs), frog-muro (m2), mesa-waist (m5).
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1&' + SETQ);
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(SUBIDA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs, sheet);
  const results = await checks(sheet, G, probes, PV);
  sheet.setKey.baked = [...new Set(MOMENTS.map(m => '?' + ['hora', 'fiesta'].map(k => k + '=' + PV.moment[m].set[k]).join('&')))];
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

/* ---------- the preview's moments: subida-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/subida-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {}, leaf: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(a => window.PREVIEW.silhouette(a.k, a.ctx), { k: v, ctx: { sx: 0, sy: 0 } });
  for (const m of MOMENTS) { const q = JSON.stringify(PV.moment[m].set); if (!PV.leaf[q]) PV.leaf[q] = await p.evaluate(st => window.PREVIEW.leafMask(st), PV.moment[m].set); }
  PV.leafOf = m => PV.leaf[JSON.stringify(PV.moment[m].set)];
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
  const [w, h] = size, x = anchor === 'left' ? sx : sx - Math.floor(w / 2);
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
    if (d.fixed) o.fixed = 1;
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [108, 109, 110], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 108, 109 and 110: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
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
  const things = {}, GT = E.GATE, GR = E.GRASS;
  things.puerta = await setThing(GT[0], 0, GT[2], GT[1], 0, GT[3], 'the gate (the arch: u ' + GT[0] + ' to ' + GT[1] + ', z ' + GT[2] + ' to ' + GT[3] + ' on the wall at v 0: the hole the dark passage shows through); a poke');
  things.muralla = await setThing(1.0, 0, .3, 2.6, 0, 2.1, 'the wall\'s face from u 1.0 to 2.6, z .3 to 2.1 (away from the gate: the frog goes up it and walks along its top; WALL.h ' + E.WALL.h + '); a poke');
  things.grama = await setThing(GR[0], GR[1], 0, GR[2], GR[3], 0, 'the open grass where they play (GRASS u ' + GR[0] + ' to ' + GR[2] + ', v ' + GR[1] + ' to ' + GR[3] + ', on the ground): the GRASS box on the picture; a poke');
  const sp = spots;
  const spriteThing = (name, spot, what) => { things[name] = { sprite: true, spot, anchor: sp[spot].anchor, size: sp[spot].box.slice(2), box: sp[spot].box.slice(), what }; };
  spriteThing('bandera', 'bandera', 'the flag (16 x 10 px, its left middle on the pole at z ' + FLAG_Z + '): a poke; it waves');
  spriteThing('cartel', 'cartel', 'Luis\'s paper on the tree\'s trunk (30 x 30 px, its top middle at (TREE.u, TREE.v + .05, ' + PAPER_Z + ')): a poke');
  const cb = sp.cartel.box;
  things.cartel_quien = { sprite: true, spot: 'cartel', size: [PIC.size, PIC.size], box: [cb[0] + PIC.dx[0], cb[1] + PIC.dy, PIC.size, PIC.size], what: 'the paper\'s left round picture, abuela\'s face (12 x 12 px: the paper\'s columns ' + PIC.dx[0] + ' to ' + (PIC.dx[0] + PIC.size - 1) + ', rows ' + PIC.dy + ' to ' + (PIC.dy + PIC.size - 1) + ', its lower half; the spec gives the size, the order and "2 px apart": the row is the sheet\'s); a poke' };
  things.cartel_cuando = { sprite: true, spot: 'cartel', size: [PIC.size, PIC.size], box: [cb[0] + PIC.dx[1], cb[1] + PIC.dy, PIC.size, PIC.size], what: 'the paper\'s right round picture, a moon over a clock (12 x 12 px: columns ' + PIC.dx[1] + ' to ' + (PIC.dx[1] + PIC.size - 1) + ', rows ' + PIC.dy + ' to ' + (PIC.dy + PIC.size - 1) + ', 2 px from the left one); a poke' };
  spriteThing('canasta', 'canasta', 'Carmen\'s basket (12 x 10 px, its bottom middle on the ground at canasta; in moments 1 and 2 it stands beside Carmen at camino_lado, 18 px to the right of her feet: made for the preview, not a spot of the spec): a poke');
  spriteThing('comida', 'comida', 'the dish of food on the table\'s left end (20 x 10 px, its bottom middle on the table\'s top): a poke');
  spriteThing('jugos', 'jugos', 'the two jugs on the table\'s right end (16 x 12 px, its bottom middle on the table\'s top): a poke');
  spriteThing('hamaca', 'hamaca', 'the hammock (50 x 12 px, its middle at ((HAMMOCK.u0 + HAMMOCK.u1) / 2, HAMMOCK.v, ' + HAMMOCK_Z + ')): a poke; whoever lies in it is part of the sprite');
  const fb = ['faroles1', 'faroles2', 'faroles3'].map(k => sp[k].box), fx0 = Math.min(...fb.map(b => b[0])), fx1 = Math.max(...fb.map(b => b[0] + b[2])), fy0 = Math.min(...fb.map(b => b[1])), fy1 = Math.max(...fb.map(b => b[1] + b[3]));
  things.faroles = { sprite: true, spot: ['faroles1', 'faroles2', 'faroles3'], box: [fx0, fy0, fx1 - fx0, fy1 - fy0], boxes: fb, what: 'the three lanterns by the gate: one box over the three (8 x 10 px each, their bottom middle at faroles1 to faroles3); a poke' };
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'coqui', 'don_pepe', 'maestra', 'piraguero', 'senora', 'joven']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'subida',
    made: 'node docs/proyecto/pixel/subida-sheet-make.js, from subida-set.html (window.SUBIDA.E) and the design of El camino al fuerte (the orchestrator\'s p10-spec, general rules and section subida). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the fort\'s wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the ground; z ' + E.WALL.h + ': the battlements\' top at the wall; z ' + STONE_Z + ': the flat stone\'s top; z ' + TABLE_Z + ': the table\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the basket, the dish, the jugs, the ball and the three lanterns by the gate have their bottom middle on the spot, the three hooks\' lanterns and the paper hang by their top middle, the flag has its left middle on the pole, the hammock its middle (the box [sx - floor(w / 2), sy - h, w, h] for a bottom one; [sx - floor(w / 2), sy, w, h] for a hanging one; [sx, sy - floor(h / 2), w, h] for the flag; [sx - floor(w / 2), sy - floor(h / 2), w, h] for the hammock). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up, 40 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30; a small thing: see spot. Carmen "sitting by the tree" (arbol) is drawn standing. Whoever lies in the hammock is part of the hammock sprite (hamaca_dentro is the same point). Nobody is drawn turned',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character. The tree\'s leaves sway: the depth is the LIVE depth of the still frame (frame(0), t = 0), see front.how',
    },
    setKey: {
      params: { hora: { values: ['tarde', 'ocaso', 'noche'], default: 'tarde', note: 'the sky, the sea and the light (noche: the moon, the gate\'s two lamps lit)' }, fiesta: { values: [0, 1], default: 0, note: 'the party table and the hammock\'s two posts (story 110)' } },
      key: 'hora, fiesta, e.g. "hora=tarde&fiesta=0"',
      baked: [],                                                                       // filled from the preview's moments (the states they draw), below
      note: 'the geometry (and so the depth) is the same in every state but fiesta: the table and the posts are in the depth of fiesta = 1 only. The sheet\'s numbers are read from the set with hora noche and fiesta 1',
    },
    things,
    spots,
    groups: {
      camino: ['camino1', 'camino2', 'camino3', 'camino4'], ganchos: ['gancho_muralla', 'gancho_puerta', 'gancho_bandera'], faroles: ['faroles1', 'faroles2', 'faroles3'], mesa: ['mesa_comida', 'mesa_jugos', 'comida', 'jugos'], grama: ['grama1', 'grama2', 'grama3', 'bola'], hamaca: ['hamaca', 'hamaca_dentro'], bajo_arbol: ['bajo_arbol1', 'bajo_arbol2'],
      touch: { puerta: 'ante_puerta', muralla: 'muro_coqui', bandera: 'bandera', cartel: 'cartel', cartel_quien: 'cartel', cartel_cuando: 'cartel', canasta: 'canasta', comida: 'comida', jugos: 'jugos', hamaca: 'hamaca', grama: 'grama3', faroles: 'faroles2', abuela: 'puerta_abuela', luis: 'luis_cartel', carmen: 'arbol', coqui: 'ante_puerta' },
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p10-spec, "subida"), given in (u, v, z); the wall, the gate, the pole, the tree, the stone, the table and the hammock\'s posts are read from the set',
      'things: puerta, muralla and grama are set things with a box (the gate\'s hole, the wall\'s face, the GRASS box on the picture); bandera, cartel, cartel_quien, cartel_cuando, canasta, comida, jugos, hamaca and faroles are sprites at the spots of the same name; the people are sprites',
      'the three lanterns by the gate: the spec\'s one spot "faroles" holds three points; they are faroles1, faroles2 and faroles3 here (group faroles); the three hooks are gancho_muralla, gancho_puerta and gancho_bandera',
      'cartel_quien and cartel_cuando: the spec gives the size (12 x 12), the order and "2 px apart"; the row (the paper\'s rows 16 to 27, its lower half) and the 2 px margins at the sides are the sheet\'s: left box at the paper\'s column 2, right box at column 16',
      'the basket in moments 1 and 2 stands beside Carmen at camino_lado, 18 px to the right of her feet (layer px [18, 0]): the spec says "beside her" and gives the spot canasta only for moment 3; it is not a spot',
      'the tree\'s leaves sway, so the sprites are tested against the live depth of the still frame (t = 0). The paper and the lanterns are clear of the crown at t = 0 (checks hooks-flag, cartel-clear); the leaves move a pixel or two in the wind: the checks do not cover the other frames',
      'muro_coqui is at z WALL.h (' + E.WALL.h + '), the top of the battlements, where the wall is a plane with no top face: the spec\'s u 1.6 falls in a gap between two merlons ((u + 60.26) mod .9 = ' + r2((1.6 + 60.26) % .9) + ', merlons are 0 to .52), where the set\'s pixel under the feet is the walk behind them (spots-on-surface failed), so the spot moved to u ' + spots.muro_coqui.uv[0] + ' (the end of the merlon from u .94 to 1.46): the picture row is the same (row ' + spots.muro_coqui.screen[1] + '), the frog stands on a merlon\'s top',
      'stand-ins: abuelo is kit\'s FAM.abuelo; don Pepe, la maestra, el piragüero, la señora, el joven and the boy are other makers of mkPersona in other clothes (don Pepe an orange shirt, la maestra blue, el piragüero white with a red cap, la señora green, el joven teal, the boy yellow); in m4 la señora is the passer-by at junto_cartel, el joven camino3, el piragüero camino4; in m5 don Pepe is mesa_comida, la maestra mesa_jugos, el piragüero entra; in m6 don Pepe and la maestra are bajo_arbol1 and bajo_arbol2',
      'the lanterns on short stakes by the gate: the stake is a stand-in sprite on the ground under each lantern (group decor, not a spot of the spec)',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the set\'s depth, with the feet\'s depth plus 0.3): the wall hides what is behind it, the table hides the legs of the guests behind it, the tree\'s trunk and leaves hide what is behind them. The set\'s depth is the baked depth (window.DEPTH.z) plus the tree\'s leaves at the still frame (t = 0: window.DEPTH.live() after frame(0)); with the wind the leaves move a pixel or two, so a sprite that shows at t = 0 may lose a pixel or two behind a leaf at another frame',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where the set\'s depth (window.DEPTH.live() of the set page after frame(0), for the moment\'s state) is more than depth(r) + bias. The same rule as El cruce\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, don_pepe: .35, maestra: .35, piraguero: .35, senora: .35, joven: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSurface: 'the frog on the wall (muro_coqui), on the stone (piedra) casts none: neither is the ground (a shadow cast at the ground under him would show in front of him); the things on the table, on a hook, on the pole, on the trunk or hung between the posts cast none',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the live depth of the still frame and the part)
  const spotsPx = await page.evaluate(arg => {
    const o = {}, live = DEPTH.live();
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
        const X = s.screen[0] + dx, Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, c = bakedPix[i];
        rows.push({ dx, dy, tag: TAGS[i], z: live[i], rgb: [c & 255, c >> 8 & 255, c >> 16 & 255] });
      }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
  const tags = px => page.evaluate(q => q.map(([x, y]) => TAGS[y * W + x] || 'ground'), px);          // the part the set drew at each pixel [x, y]
  return { spotsPx, tags };
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
  const idxAt = (L, at, group) => L.findIndex(l => l.at === at && (!group || l.group === group));
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  const layerName = l => l.at + (l.thing ? ' (' + l.thing + ')' : '');
  // what hid the pixels of layer t that the set hides: the leaves of the tree (the live frame at t = 0) or the part the set drew there
  const hiddenBy = async (m, l) => {
    const hp = l.px.filter(p => p[2]); if (!hp.length) return '';
    const leaf = PV.leafOf(m), by = {}, tg = await probes.tags(hp.map(p => [p[0], p[1]]));
    hp.forEach((p, i) => { const k = leaf[p[1] * G.W + p[0]] ? 'the tree\'s leaves' : 'part ' + tg[i]; by[k] = (by[k] || 0) + 1; });
    return Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ');
  };

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

  // 3. the spots above the ground are on what the set draws: the wall and the pole (part fuerte), the stone, the table's top and the trunk (part grama): the part named, its depth (the live frame) within .1 of the spot's
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground') continue;
      const tol = .1, best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < tol;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the ground (' + surf.join(', ') + ') are on a surface the set draws (depth within .1 of the spot\'s, the live frame): the wall, the pole (part fuerte), the stone z ' + STONE_Z + ', the table\'s top z ' + TABLE_Z + ' and the trunk (part grama)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the things' boxes are inside the picture and the window
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

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
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
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the ' + MOMENTS.length + ' moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in ' + MOMENTS.length + ' moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person or a thing or the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
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

  // 7. heads-clear: whoever sits or lies (Carmen by the tree in m3, drawn standing; Carmen in the hammock in m5: the hammock's 12 rows hold her head) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        const isHead = l.group === 'head', isHam = l.group === 'hamaca' && l.s === 'hamacaCabeza';
        if (!isHead && !isHam) continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set (' + await hiddenBy(m, l) + ')'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'Carmen by the tree (m3, standing) and Carmen in the hammock (m5) are whole in the window and her head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.join('; '), [bad.length + ' problem(s) with the people who sit or lie:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // a "things are clear" check: every layer of a group in the given moments covered by nobody, not hidden by the set (nor by the tree's leaves), inside the picture
  const clearCheck = async (name, moments, pick, intro) => {
    const bad = [], lines = [], hints = [];
    for (const m of moments) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const [i, l] of L.entries()) {
        if (!pick(l)) continue;
        const c = coverOf(L, M, i, null), hb = c.hid ? await hiddenBy(m, l) : '';
        parts.push(layerName(l) + ' [' + S[l.at].box + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set' + (c.hid ? ' (' + hb + ')' : '') + ', ' + c.out + ' outside the picture');
        if (c.cov || c.hid || c.out) { bad.push('moment ' + m + ' ' + layerName(l) + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set' + (c.hid ? ' (' + hb + ')' : '') + ', ' + c.out + ' outside the picture'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
      lines.push('m' + m + ': ' + parts.join('; '));
    }
    const o = add(name, bad, intro + ': ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { if (ci < 0) continue; const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + m + ' (' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    return o;
  };

  // 8. hooks-flag (m3): the three lanterns on their hooks and the flag are covered by nobody and are not hidden by the tree or the set; the flag is inside the picture (and the window)
  {
    const o = await clearCheck('hooks-flag', [3], l => l.group === 'gancho' || l.group === 'bandera', 'in moment 3 the three lanterns on their hooks (gancho_muralla, gancho_puerta, gancho_bandera) and the flag (bandera) are covered by nobody and hidden by nothing (neither the set nor the tree\'s leaves, live frame t = 0)');
    const f = T.bandera.box, cut = Math.max(0, x0 - f[0]) + Math.max(0, f[0] + f[2] - (x0 + 196)) + Math.max(0, -f[1]) + Math.max(0, f[1] + f[3] - G.H);
    if (cut) { o.ok = false; o.lines[0] = o.lines[0].replace(/^hooks-flag: /, 'hooks-flag: the flag [' + f + '] is cut by ' + cut + ' px (outside the picture or the window): '); }
    else o.lines[0] += '; the flag\'s box [' + f + '] is inside the picture (240 x 216) and the window [' + x0 + ', ' + (x0 + 196) + ')';
  }

  // 9. cartel-clear (m4): the paper and its two round pictures are covered by nobody and not hidden by the tree's leaves (or the set); the frog on the stone covers neither picture (no pixel of his on a picture's drawn pixels or in its box)
  {
    const bad = [], lines = [], hints = [], m = 4, L = PV.inspect[m].layers, M = planes(L), pi = idxAt(L, 'cartel'), fi = idxAt(L, 'piedra');
    const c = coverOf(L, M, pi, null), hb = c.hid ? await hiddenBy(m, L[pi]) : '';
    lines.push('cartel [' + S.cartel.box + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set' + (c.hid ? ' (' + hb + ')' : '') + ', ' + c.out + ' outside the picture');
    if (c.cov || c.hid || c.out) { bad.push('moment 4 cartel: ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by ' + (hb || 'nothing') + ', ' + c.out + ' outside the picture'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), pi, 'cartel', w]); }
    for (const q of ['cartel_quien', 'cartel_cuando']) {
      const b = T[q].box, inb = L[pi].px.filter(p => inside(b, p[0], p[1])), hid = inb.filter(p => p[2]).length;
      let cov = 0; const who = {};
      for (const p of inb) { if (p[2]) continue; for (const o of M.get(key(p[0], p[1])) || []) if (o.i !== pi && o.plane > p[3] + EPS) { cov++; who[L[o.i].at] = (who[L[o.i].at] || 0) + 1; break; } }
      let any = 0; for (const [j, l] of L.entries()) if (j !== pi) any += shownIn(L, j, b);
      const n = shownIn(L, fi, b);
      lines.push(q + ' [' + b + ']: ' + inb.length + ' px of the paper in it, ' + cov + ' covered' + (cov ? ' by ' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', ') : '') + ', ' + hid + ' hidden by the set, ' + n + ' px of the frog in its box, ' + any + ' px of anybody in its box');
      if (cov || hid || any) bad.push('moment 4 ' + q + ' [' + b + ']: ' + cov + ' px covered, ' + hid + ' hidden by the set, ' + any + ' px of other sprites in its box (the frog\'s ' + n + ')');
    }
    const o = add('cartel-clear', bad, 'in moment 4 the paper (cartel) and its two round pictures (cartel_quien, cartel_cuando) are covered by nobody and hidden by nothing (not the tree\'s leaves, live frame t = 0), and the frog on the stone (piedra) covers neither picture: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [mm, ci, ti, tat, cat] of hints) { if (ci < 0) continue; const MM = PV.moment[mm], r = await PV.nearestClear(MM.set, MM.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + mm + ' (' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // 10. faroles-clear (m5, m6): the three lanterns by the gate are covered by nobody (and hidden by nothing)
  await clearCheck('faroles-clear', [5, 6], l => l.group === 'farol', 'in moments 5 and 6 the three lanterns by the gate (faroles1 to faroles3) are covered by nobody and hidden by nothing');

  // 11. mesa-clear (m5): the dish and the jugs are covered by nobody (and hidden by nothing)
  await clearCheck('mesa-clear', [5], l => l.group === 'comida' || l.group === 'jugos', 'in moment 5 the dish (comida) and the jugs (jugos) on the table are covered by nobody and hidden by nothing (the guests behind the table are farther)');

  // 12. frog-muro (m2): the frog at muro_coqui is whole (no pixel hidden by the set, outside the picture, or under a nearer sprite) and stands on the wall (spots-on-surface)
  {
    const bad = [], m = 2, L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'muro_coqui'), c = coverOf(L, M, i, null), f = L[i], [a, b] = colsOf(S.muro_coqui);
    const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195));
    if (c.cov || c.hid || c.out || cutL || cutR) bad.push('moment 2: the frog on the wall ' + [f.sx, f.sy] + ': ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + (cutL + cutR) + ' px cut by the window');
    if (!surf.includes('muro_coqui')) bad.push('muro_coqui is not on the wall');
    add('frog-muro', bad, 'the frog at muro_coqui ' + S.muro_coqui.screen + ' (u ' + S.muro_coqui.uv[0] + ', v 0, z ' + S.muro_coqui.uv[2] + ') on the wall\'s top is whole in moment 2: ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + (cutL + cutR) + ' px cut by the window (columns ' + a + ' to ' + b + ' of the window\'s ' + x0 + ' to ' + (x0 + 195) + '); his box over the sky and the walk: nothing of the set is nearer', [bad.length + ' problem(s):'].concat(bad.map(b2 => '  ' + b2)));
  }

  // 13. mesa-waist (m5): the guests behind the table (mesa_comida, mesa_jugos) show from the waist up: every pixel above canvas row 16 + 2 t = 38 (the hips' centre) is shown (not hidden by the table, covered by no person); the table hides no more than their legs
  {
    const bad = [], lines = [], m = 5, L = PV.inspect[m].layers, M = planes(L);
    for (const [i, l] of L.entries()) {
      if (l.group !== 'detras') continue;
      const waistY = l.sy - l.ay + WAIST, top = Math.min(...l.px.map(p => p[1])), people = L.map((o, j) => o.who ? j : -1).filter(j => j >= 0), c = coverOf(L, M, i, people, [0, waistY - top]), things = coverOf(L, M, i, L.map((o, j) => !o.who ? j : -1).filter(j => j >= 0), [0, waistY - top]);
      const hid = l.px.filter(p => p[2]).map(p => p[1]), first = hid.length ? Math.min(...hid) : null;
      lines.push(l.at + ' ' + [l.sx, l.sy] + ': rows ' + top + ' to ' + (waistY - 1) + ' above the waist (row ' + waistY + '): ' + c.tot + ' px, ' + c.cov + ' covered by people, ' + c.hid + ' hidden by the set (the table); the dish or the jugs on the table cover ' + things.cov + ' of them (not counted: a thing on the table in front of her belly); the table hides from row ' + (first === null ? 'none' : first + ' (' + (first - waistY) + ' below the waist)') + ' to the feet (row ' + (l.sy - 1) + ')');
      if (c.cov || c.hid) bad.push('moment 5 ' + l.at + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px above the waist (rows ' + top + ' to ' + (waistY - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set (first hidden row ' + first + ')');
    }
    add('mesa-waist', bad, 'in moment 5 the guests behind the table (mesa_comida, mesa_jugos) show from the waist up (canvas row ' + WAIST + ': the hips\' centre; the set\'s table hides none of the rows above it, no person covers them): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // info: things he can touch that the spec lists no check for (the basket, the hammock, the ball), the people over them: not checks of the spec
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), parts = [];
      for (const [i, l] of L.entries()) if (['canasta', 'hamaca', 'bola'].includes(l.group)) { const c = coverOf(L, M, i, null); parts.push(layerName(l) + ' ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set'); }
      lines.push('m' + m + ': ' + (parts.join(', ') || 'none drawn'));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
