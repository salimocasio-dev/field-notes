#!/usr/bin/env node
'use strict';
/* Los regalos' sheet (place 10, El fuerte, scene 3, stories 114 to 116): writes docs/proyecto/pixel/regalos-sheet.json from regalos-set.html and the design (the orchestrator's p10-spec, general rules and section "regalos"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/regalos-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 74 here). The arch, the curtain's cord, the bench, the photos' cord and its pegs, the table, the step stool and the low stool
   are read from the set (window.REGALOS.E: ARCH, CURTAIN, BENCH, PHOTOS, TABLE, STEP and STOOL, the last two arrays [u, v, height]), never typed again from the design.
   It loads the set in headless Chrome (regalos-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (regalos-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with REGALOS_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'regalos-sheet.json');
const BASE = process.env.REGALOS_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/regalos-set.html';
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

// the numbers of the design (p10-spec: the rules for every sheet, and "regalos")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const BENCH_Z = .46, TABLE_Z = .74;                      // the bench's seat; the table's top (the step's and the low stool's tops are E.STEP[2], E.STOOL[2])
const MOMENTS = [1, 2, 3, 4, 5, 6];
const SILKEY = { adulto: 'abuelo', nino: 'luis', coqui: 'coqui' };       // which preview sprite draws each silhouette name
const FOTOS = ['3m', '7m', '3a', '7a'];                  // the four photos: the order of the spec's list of things; the spec does not say which is at which peg or place (open point)

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a top).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  mesa_coqui: { to: [.44, 3.2, TABLE_Z], why: 'sprites-apart: in moments 1, 2 and 6 the frog on the table\'s left end was 19 px sideways and 3 px up-down from whoever stands behind the table (abuela, abuelo in m6: tras_mesa [159,102]); the boxes need 28 across or 12 down: u .75 -> .44 (-.31, 8.1 px; his z is the table\'s top, not moved). The other ways: tras_mesa u +.33 (8.6 px, and it pushes Carmen at tras_mesa2 along), mesa_coqui v -.65 (8.5 px, and it leaves him 2 px up-down from abuelo at junto_banco)' },
  junto_banco: { to: [.05, 1.03, 0], why: 'photos-cord (m4): at u .25 abuelo covered 38 px of the first photo on the cord [130,33,12,12]: u .25 -> .05 (-.20, 5.2 px). The other way, v 1.1 -> 1.58 (+.48), leaves the frog no place on the table\'s left end (sprites-apart in m1 and m2). And sprites-apart (m1, m2): 12 px up-down are needed from the frog at mesa_coqui, abuelo was 11: v 1.1 -> 1.03 (-.07, .9 px; the other way: mesa_coqui v +.05)' },
  banco3: { to: [-.65, .45, BENCH_Z], why: 'bench-things (m1, m2): with abuelo at u .05 his left side (column 109 on rows 53 to 68) covered 23 px of the flowers [101,53,12,16]: u -.5 -> -.65 (-.15, 3.9 px: the flowers\' box now ends at column 108; the seat\'s top z .46 is not moved). The other way, abuelo u +.13, covers the first photo on the cord again (photos-cord)' },
  tras_mesa2: { to: [2.41, 2.0, 0], why: 'sprites-apart (m4, m5): 23 px sideways and 0 up-down from abuela at tras_mesa, the boxes need 24: u 2.4 -> 2.41 (+.01, .3 px). Heads behind the table (m4, m5): her head (rows 61 to 74) was covered by 22 px of the cake\'s candles (the cake\'s box [173,73,18,18]): v 2.15 -> 2.0 (-.15, 2 px: her head rows 59 to 72). The other way: mesa2 v +.11 (1.4 px), which would move the cake of m3 and the packet of m6 off the row of mesa1 to mesa3' },
  fondo2: { to: [-2.5, -.11, 0], why: 'fondo-head (m1): Carmen at fondo2 stood with her feet on row 68 and her head on rows 27 to 40: 52 of its 244 px were outside the arch\'s hole (its top is row 28) and 51 hidden by the wall; she is clear of the half curtain (columns 19 to 43): v -.5 -> -.11 (+.39, 5.1 px: feet on row 73, head rows 32 to 45, all inside the hole). Along u nothing within 4 passes; z is not moved' },
  arco: { to: [-2.9, .81, 0], why: 'sprites-apart (m1): Carmen at fondo2 [55,73] and Luis at the arch [45,83] were 10 px sideways and 10 px up-down (24 across or 12 down are needed); fondo2 cannot go back (fondo-head): v .7 -> .81 (+.11, 1.4 px). The other way: fondo2 v -.2 (+ the head out of the hole again), u +/-.5' },
  banqueta_izq: { to: [.8, 5.04, 0], why: 'frog-seen (m6): Carmen at the low stool\'s left (STOOL.u - .95) stood in front of the frog on the table\'s left end with her head (rows 94 to 108) over his feet (rows to 99): 59 px of the frog were under her: v 4.7 -> 5.04 (+.34, 4.4 px: her head starts on row 100). The other ways: mesa_coqui v -.35 (4.5 px, 7 px up-down from abuela at tras_mesa: sprites-apart), mesa_coqui u +.81' },
  banqueta_der: { to: [2.7, 5.35, 0], why: 'table-things (m6): the guest at the low stool\'s right (STOOL.u + .95; a grown-up 51 rows tall, his head from row 84) covered the packets at mesa2 and mesa3 (rows 77 to 90; 71 and 60 px): v 4.7 -> 5.35 (+.65, 8.5 px: his head starts on row 91). One u cannot clear both packets (mesa2 u +.17, mesa3 u -.15)' },
};

/* the spots: { name, uvz, kind, sil, who, what, ... }
   kind: person (a character stands there), place (the frog's), thing (a small thing on a surface: its bottom middle on the point), hang (a thing that hangs from a cord: its top middle on the point; the curtain),
         shadow (the shadow on the curtain)
   sil: which drawing hangs there (adulto = a grown-up standing, nino = a child standing, coqui) or null for a thing
   size, anchor (things): bottom = its bottom middle on the point, top = its top middle on the point
   on: the part of the set it stands on above the floor: patio (the bench, the table, the step, the low stool), muro (the wall: the cord's pegs)
   (whoever hides behind the table is not seen: no sprite is drawn, there is no spot for him) */
function defs(E) {
  const T = E.TABLE, B = E.BENCH, C = E.CURTAIN, P = E.PHOTOS, [su, sv, sh] = E.STEP, [qu, qv, qh] = E.STOOL, D = [];
  const far = r4(T.v - T.hd - .15), add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz: uvz.map(r4), kind, sil, who, what }, more || {}));
  // beyond the arch, the curtain
  add('cortina', [(C.u0 + C.u1) / 2, C.v, 0], 'hang', null, null, 'the curtain: a sprite that hangs from the cord (CURTAIN u ' + C.u0 + ' to ' + C.u1 + ', z ' + C.z + ', v ' + C.v + '); the spot is its bottom middle; its box is u ' + C.u0 + ' to ' + C.u1 + ', z 0 to ' + C.z + ' at v ' + C.v + ' (things.cortina.box: shut = the whole box; half open = its left half, things.cortina.half): m1 half open, m2 and m3 shut', { size: null, curtain: true });
  add('fondo1', [-3.2, -.9, 0], 'person', 'adulto', 'adulto', 'a grown-up dancer seen in the hole, beyond the wall (in no moment of the spec); standing, his feet on the dance floor beyond', {});
  add('fondo2', [-2.5, -.5, 0], 'person', 'nino', 'nino', 'Carmen seen dancing in the arch\'s hole, on the open side of the half curtain (m1); a child standing, her feet on the dance floor beyond', {});
  add('tras_cortina', [-2.9, -.25, 0], 'shadow', null, null, 'a shadow on the curtain, cast from beyond it (in no moment of the spec; the spec gives no size)', {});
  add('arco', [-2.9, .7, 0], 'person', 'nino', 'nino', 'Luis in front of the arch (m1, m2); Carmen coming in at the arch (m3)', {});
  // the bench
  [['banco1', B.u - .52, [16, 12], 'the cake (16 x 12; m1 under its net cover, m2 uncovered)'], ['banco2', B.u, [14, 14], 'the box with a bow (14 x 14; m1; the box of candles, 10 x 8, stands here in m4 and m5: things.caja_velas)'], ['banco3', B.u + .52, [12, 16], 'the flowers in a jar (12 x 16; m1, m2)']].forEach(([n, u, size, w]) =>
    add(n, [u, B.v, BENCH_Z], 'thing', null, null, w + ' on the bench (BENCH u ' + B.u + ', v ' + B.v + ': u ' + (n === 'banco1' ? 'BENCH.u - .52' : n === 'banco2' ? 'BENCH.u' : 'BENCH.u + .52') + '): its bottom middle on the seat\'s top, z ' + BENCH_Z, { size, anchor: 'bottom', on: 'patio' }));
  add('junto_banco', [.25, 1.1, 0], 'person', 'adulto', 'adulto', 'abuelo right of the bench (m1, m2, m4)', {});
  // the table
  [['mesa1', 0], ['mesa2', .65], ['mesa3', 1.3]].forEach(([n, du]) => add(n, [T.u + du, T.v - .3, TABLE_Z], 'thing', null, null, 'a thing or a packet on the table (14 x 14; m2 the box at mesa1; m3 the box, the cake and the flowers at mesa1 to mesa3; m4 and m5 the cake with its candles at mesa2; m6 two packets at mesa2 and mesa3) (TABLE u ' + T.u + ', v ' + T.v + '; TABLE.u + ' + du + ', TABLE.v - .3): its bottom middle on the table\'s top, z ' + TABLE_Z, { size: [14, 14], anchor: 'bottom', on: 'patio' }));
  add('mesa_coqui', [T.u - 1.0, T.v + .3, TABLE_Z], 'place', 'coqui', 'coqui', 'the frog on the table\'s left end (TABLE.u - 1.0, TABLE.v + .3): the table\'s top, z ' + TABLE_Z + ' (m1, m2, m3, m6)', { on: 'patio' });
  add('tras_mesa', [T.u - .25, far, 0], 'person', 'adulto', 'adulto', 'abuela behind the table (TABLE.u - .25, TABLE.v - TABLE.hd - .15 = ' + far + '; the table\'s far edge is v ' + r4(T.v - T.hd) + '): m1, m2, m4, m5; abuelo in m6', {});
  add('tras_mesa2', [T.u + .65, far, 0], 'person', 'nino', 'nino', 'Carmen behind the table, behind her cake (TABLE.u + .65, TABLE.v - TABLE.hd - .15): m4, m5', {});
  add('tras_mesa3', [T.u + 1.25, far, 0], 'person', 'nino', 'nino', 'Luis behind the table\'s right end (TABLE.u + 1.25, TABLE.v - TABLE.hd - .15): m3, after he has jumped up', {});
  // the photos
  P.pegs.forEach((u, i) => add('cuerda' + (i + 1), [u, P.v, r4(P.z - .1)], 'hang', null, null, 'photo ' + (i + 1) + ' of 4 on the photos\' cord (PHOTOS peg u ' + u + ', v ' + P.v + ', z PHOTOS.z - .1 = ' + r4(P.z - .1) + '; 12 x 12): its top middle on the point, hung by the peg (m4: ' + FOTOS[i] + ')', { size: [12, 12], anchor: 'top', on: 'muro', hang: true }));
  [-1.25, -.78, -.31, .16].forEach((du, i) => add('fotos' + (i + 1), [T.u + du, T.v + .35, TABLE_Z], 'thing', null, null, 'photo ' + (i + 1) + ' of 4 lying on the table (TABLE.u ' + (du > 0 ? '+ ' : '- ') + Math.abs(du) + ', TABLE.v + .35; 11 x 10): its bottom middle on the table\'s top, z ' + TABLE_Z + ' (m5: ' + FOTOS[i] + ')', { size: [11, 10], anchor: 'bottom', on: 'patio' }));
  add('caja_velas', [B.u, B.v, BENCH_Z], 'thing', null, null, 'the box of candles on the bench at banco2 (10 x 8; m4, m5): its bottom middle on the seat\'s top, z ' + BENCH_Z, { size: [10, 8], anchor: 'bottom', on: 'patio', alias: 'banco2' });
  // the step stool, the low stool
  add('taburete', [su, sv, sh], 'person', 'adulto', 'adulto', 'abuelo on the step stool, his back to us (drawn standing; m5): the step\'s top (STEP u ' + su + ', v ' + sv + ', height ' + sh + ')', { on: 'patio' });
  add('banqueta_coqui', [qu, qv, qh], 'place', 'coqui', 'coqui', 'the frog on the low stool (m4, m5): the stool\'s top (STOOL u ' + qu + ', v ' + qv + ', height ' + qh + ')', { on: 'patio' });
  add('paquete', [qu, qv, qh], 'thing', null, null, 'the packet on the low stool (14 x 12; m6): its bottom middle on the stool\'s top (the same point as banqueta_coqui)', { size: [14, 12], anchor: 'bottom', on: 'patio' });
  add('banqueta_izq', [r4(qu - .95), qv, 0], 'person', 'nino', 'nino', 'Carmen at the stool\'s left (STOOL.u - .95; m6)', {});
  add('banqueta_der', [r4(qu + .95), qv, 0], 'person', 'adulto', 'adulto', 'a guest at the stool\'s right (STOOL.u + .95; m6: the piragüero, a stand-in)', {});
  // the rest
  add('lista_abuela', [-.6, 3.9, 0], 'person', 'adulto', 'adulto', 'abuela with her sheet of paper (m6)', {});
  add('luis_patio', [-2.3, 2.3, 0], 'person', 'nino', 'nino', 'Luis in the courtyard (m4, m5, m6)', {});
  [-3.0, -2.0, -1.0].forEach((u, i) => add('espera' + (i + 1), [u, 6.2, 0], 'person', 'adulto', 'adulto', 'a guest who waits, number ' + (i + 1) + ' of 3, in a row at the left front' + (i < 2 ? ' (m4, m5, m6: don Pepe, the maestra)' : ' (in no moment of the spec)'), {}));
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(REGALOS.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs, sheet);
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
const ITEM = '(?:-?[\\d.]+|"[\\w.=+&?:-]+")';
const compact = t => t.replace(new RegExp('\\[\\n\\s+(' + ITEM + '(?:,\\n\\s+' + ITEM + ')*)\\n\\s+\\]', 'g'), (m, a) => '[' + a.replace(/,\n\s+/g, ', ') + ']');

/* ---------- the preview's moments: regalos-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/regalos-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(a => window.PREVIEW.silhouette(a.k, a.ctx), { k: v, ctx: { sx: 0, sy: 0 } });
  PV.nearest = (specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.specs, x.idx, x.allow), { specs, idx, allow: allow || 0 });
  PV.nearestClear = (specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.specs, x.idx, x.others, x.rows), { specs, idx, others, rows: rows || null });
  PV.layers = specs => p.evaluate(s => window.PREVIEW.inspectLayers(s), specs);
  PV.nearestFree = (specs, idx, boxes) => p.evaluate(x => window.PREVIEW.nearestFree(x.specs, x.idx, x.boxes), { specs, idx, boxes });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle; a small thing, the curtain: its box) takes: [first, last]
const colsOf = s => s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj) {
  const E = G.E, sc = G.scene, DEF = defs(E), T = E.TABLE, B = E.BENCH, C = E.CURTAIN, P = E.PHOTOS, A = E.ARCH, [su, sv, sh] = E.STEP, [qu, qv, qh] = E.STOOL;
  const pr = await proj(DEF.map(d => d.uvz));
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  const cube = (u0, v0, z0, u1, v1, z1) => { const c = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) c.push([u, v, z]); return c; };
  const setThing = async (u0, v0, z0, u1, v1, z1, what) => {
    const b = await boxOfCorners(cube(u0, v0, z0, u1, v1, z1)), q = b.q;
    const t = { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
    if (v0 === v1) t.quad = [0, 1, 5, 4].map(i => W4([q[i][3], q[i][4], cube(u0, v0, z0, u1, v1, z1)[i][2]]));
    return t;
  };
  // the curtain: its box on the picture (the whole, and its left half)
  const cw = await boxOfCorners(cube(C.u0, C.v, 0, C.u1, C.v, C.z)), ch = await boxOfCorners(cube(C.u0, C.v, 0, r4((C.u0 + C.u1) / 2), C.v, C.z));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.curtain) { o.box = cw.box; o.half = ch.box; o.anchor = 'bottom'; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.hang) o.hang = 1;
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [114, 115, 116], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 114, 115 and 116: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing and the curtain with their boxes). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const things = {};
  const sp = n => spots[n];
  const place = (spot, size, anchorKind, moments, note) => { const s = sp(spot), b = boxOn(s.screen[0], s.screen[1], size, anchorKind); return Object.assign({ spot, size, anchor: anchorKind, box: b, moments }, note ? { note } : {}); };
  things.cortina = { sprite: true, spot: 'cortina', box: cw.box, half: ch.box, uv: W4([C.u0, C.v, 0, C.u1, C.v, C.z]), what: 'the curtain\'s box: u ' + C.u0 + ' to ' + C.u1 + ', z 0 to ' + C.z + ', at v ' + C.v + ' (it hangs from the cord): box = shut (the whole box; m2, m3), half = half open (its left half; m1). A sprite, a poke' };
  things.banqueta = await setThing(r4(qu - .3), r4(qv - .3), 0, r4(qu + .3), r4(qv + .3), qh, 'the low stool\'s box (STOOL u ' + qu + ', v ' + qv + ', top z ' + qh + ': the seat\'s radius is .3, FT.stool): u ' + r4(qu - .3) + ' to ' + r4(qu + .3) + ', v ' + r4(qv - .3) + ' to ' + r4(qv + .3) + ', z 0 to ' + qh + '; a poke');
  things.bizcocho = { sprite: true, what: 'the cake: 16 x 12 at banco1 (m1 under its net cover, m2); 14 x 14 on the table at mesa2 (m3); with seven candles 4 px tall, 18 x 14 and the candles, so 18 x 18, at mesa2 (m4, m5); a poke', places: [place('banco1', [16, 12], 'bottom', [1, 2]), place('mesa2', [14, 14], 'bottom', [3]), place('mesa2', [18, 18], 'bottom', [4, 5], 'the cake 18 x 14 and its 7 candles 4 px tall (lit in m5)')] };
  things.regalo = { sprite: true, what: 'the box with a bow: 14 x 14 at banco2 (m1); on the table at mesa1 (m2, m3); a poke', places: [place('banco2', [14, 14], 'bottom', [1]), place('mesa1', [14, 14], 'bottom', [2, 3])] };
  things.flores = { sprite: true, what: 'the flowers in a jar: 12 x 16 at banco3 (m1, m2); 14 x 14 on the table at mesa3 (m3); a poke', places: [place('banco3', [12, 16], 'bottom', [1, 2]), place('mesa3', [14, 14], 'bottom', [3])] };
  things.caja_velas = { sprite: true, what: 'the box of candles: 10 x 8 at banco2 (m4, m5); a poke', places: [place('banco2', [10, 8], 'bottom', [4, 5])] };
  FOTOS.forEach((k, i) => { things['foto_' + k] = { sprite: true, what: 'the photo of Carmen at ' + (k[0] === '3' ? 'three' : 'seven') + (k[1] === 'm' ? ' months' : ' years') + ': 12 x 12 hung at cuerda' + (i + 1) + ' (m4, its top middle on the peg), 11 x 10 lying at fotos' + (i + 1) + ' (m5); the spec does not say which photo is at which peg or place: the order of its list of things is used; a poke', places: [place('cuerda' + (i + 1), [12, 12], 'top', [4]), place('fotos' + (i + 1), [11, 10], 'bottom', [5])] }; });
  things.paquete = { sprite: true, what: 'the packet on the low stool: 14 x 12 at paquete (m6); the packets on the table (14 x 14, at mesa1 to mesa3) are not things he can touch; a poke', places: [place('paquete', [14, 12], 'bottom', [6])] };
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'don_pepe', 'maestra', 'piraguero', 'coqui']) things[k] = 'sprite';

  // the set's own numbers the checks read: the pegs (a peg: the box .06 across, z PHOTOS.z - .16 to - .02, v .07 deep .04)
  const pegs = [];
  for (const u of P.pegs) { const b = await boxOfCorners(cube(r4(u - .03), .05, r4(P.z - .16), r4(u + .03), .09, r4(P.z - .02))); pegs.push({ u, box: b.box }); }
  const ar = await boxOfCorners(cube(A[0], 0, A[2], A[1], 0, A[3]));

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  const touch = { cortina: 'cortina', bizcocho: 'banco1', regalo: 'banco2', flores: 'banco3', caja_velas: 'banco2', banqueta: 'banqueta_coqui', paquete: 'paquete', abuela: 'tras_mesa', abuelo: 'junto_banco', luis: 'arco', carmen: 'tras_mesa2', don_pepe: 'espera1', maestra: 'espera2', piraguero: 'banqueta_der', coqui: 'mesa_coqui' };
  FOTOS.forEach((k, i) => { touch['foto_' + k] = 'cuerda' + (i + 1); });
  return {
    scene: 'regalos',
    made: 'node docs/proyecto/pixel/regalos-sheet-make.js, from regalos-set.html (window.REGALOS.E) and the design of Los regalos (the orchestrator\'s p10-spec, general rules and section regalos). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. E.STEP and E.STOOL are arrays [u, v, height] in the set (STEP.u, STEP.v, STEP.h of the spec are E.STEP[0], [1], [2])',
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + BENCH_Z + ': the bench\'s seat; z ' + TABLE_Z + ': the table\'s top; z ' + sh + ': the step stool\'s top; z ' + qh + ': the low stool\'s top; the photos\' cord is z ' + P.z + ', a photo hangs from z ' + r4(P.z - .1) + ') and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): a thing on a surface has its bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]); a thing that hangs (a photo on the cord) has its top middle on the spot (the box [sx - floor(w / 2), sy, w, h]). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 51 rows drawn standing for a grown-up (rows 4 to 54 of a 56-row canvas whose lowest row is empty), 41 for a child (rows 2 to 42 of 44); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30, rows 0 to 49; a small thing: see spot. The curtain: the sprite is things.cortina.box (or .half), its left column on the box\'s left column and its bottom edge on the spot\'s row. Nobody is drawn turned',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: { params: {}, key: '', baked: [''], note: 'one state: regalos-set.html has no address parameters (the set is drawn once, night); the curtain, the people, the things and the photos are sprites' },
    set: { arch: { uv: W4(A), box: ar.box }, curtainCord: { u0: C.u0, u1: C.u1, z: C.z, v: C.v }, photosCord: { u0: P.u0, u1: P.u1, z: P.z, v: P.v }, pegs, bench: { u: B.u, v: B.v, hw: B.hw, seatZ: BENCH_Z }, table: { u: T.u, v: T.v, hw: T.hw, hd: T.hd, topZ: TABLE_Z }, step: { u: su, v: sv, h: sh }, stool: { u: qu, v: qv, h: qh }, far: E.FAR },
    things,
    spots,
    groups: {
      banco: ['banco1', 'banco2', 'banco3'], mesa: ['mesa1', 'mesa2', 'mesa3'], tras_mesa: ['tras_mesa', 'tras_mesa2', 'tras_mesa3'], cuerda: ['cuerda1', 'cuerda2', 'cuerda3', 'cuerda4'], fotos: ['fotos1', 'fotos2', 'fotos3', 'fotos4'],
      espera: ['espera1', 'espera2', 'espera3'], fondo: ['fondo1', 'fondo2'], banqueta: ['banqueta_coqui', 'banqueta_izq', 'banqueta_der', 'paquete'], touch,
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p10-spec, "regalos"), given in (u, v, z); the arch, the curtain\'s cord, the bench, the photos\' cord and its pegs, the table, the step stool and the low stool are read from the set',
      'things: cortina is a sprite with a box (things.cortina.box whole, .half the left half); banqueta is a set thing (the low stool\'s box); bizcocho, regalo, flores, caja_velas, foto_3m, foto_7m, foto_3a, foto_7a and paquete are sprites with a box at each place they stand (things.*.places: spot, size, box, moments); the people are sprites; the packets on the table (m6) are 14 x 14 stand-ins, not things he can touch',
      'the spec does not say which of the four photos hangs at which peg or lies at which place: the order of its list of things (3 months, 7 months, 3 years, 7 years) is used for both; the real order is drawn at play (open point)',
      'the three things on the table in m3 (mesa1 to mesa3): the box, the cake and the flowers in that order (the box is at mesa1 in m2; the cake is at mesa2 in m4 and m5; the flowers go on last); the spec does not say which is where (open point)',
      'stand-ins: don Pepe (El colmado\'s man without his apron) and the maestra (mkPersona, teal blouse and skirt) wait at espera1 and espera2; the piragüero (mkPersona, orange shirt) is the guest at banqueta_der; each has other clothes than the family',
      'the spec\'s m4 has the cake with seven candles 4 px tall at mesa2; the script says the cake has no candles yet at the start of 115: the preview draws the candles, unlit (m4), lit (m5) (open point)',
      'tras_cortina (a shadow on the curtain) and fondo1 (a grown-up dancer beyond the arch) are in no moment of the spec: they are spots with no sprite drawn; espera3 is in no moment either',
      'escondidos: hidden behind the table, no sprite is drawn; they come up at tras_mesa, tras_mesa3 and junto_banco',
      'the guests wait in a row at the left front: espera1 (-3.0, 6.2), espera2 (-2.0, 6.2), espera3 (-1.0, 6.2); luis_patio is (-2.3, 2.3) (the numbers of the coordinator, not moves)',
      'the checks "covered by nobody" (the things on the bench, the table and the stool, the photos, the cake, the packets) read people: no character\'s shown pixel on a pixel of the thing or in its box, nearer than it; a thing over a thing is info (m5: the box of fotos4 touches the cake\'s box in 3 x 1 px, not moved); the heads (rule 14) are covered by nobody and by nothing: no person, no thing, not the set',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing and the curtain with their boxes), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the table hides the legs of whoever stands behind it, the stool and the step hide what is behind them, the wall\'s rim hides what is outside the arch\'s hole (the dancers beyond it).',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as La noche\'s sheet: the upright plane through the feet (for a thing that hangs, through its top: the same plane)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn. The curtain (v ' + C.v + ') is nearer than whoever is beyond the arch (fondo1, fondo2) and farther than whoever stands in front of it (arco)',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, don_pepe: .35, maestra: .35, piraguero: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever stands on the step, the frog on the table or on the low stool (z above 0) casts none: none of those is floor (a shadow cast at the floor under them would show in front of them); the things on the bench, the table, the stool and the cord cast none',
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
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, SIL = PV.sil, T30 = Math.tan(Math.PI / 6);
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  const planeOf = (l, Y) => l.d + (l.sy - (Y + .5)) * T30 / G.S;                         // the layer's upright plane at picture row Y
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
  // the shown pixels of the layers `by` (indices; null: any other) that lie in a box and are nearer than layer t's plane there: who they are (the box of a thing; "covers" is read on the box, a little stricter than on the drawn pixels)
  const boxCover = (L, t, box, by) => {
    const who = {}; let n = 0;
    L.forEach((l, i) => { if (i === t || (by && !by.includes(i))) return; for (const p of l.px) if (!p[2] && inside(box, p[0], p[1]) && p[3] > planeOf(L[t], p[1]) + EPS) { n++; who[l.at] = (who[l.at] || 0) + 1; } });
    return { n, who };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const idxAt = (L, at) => L.findIndex(l => l.at === at);
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  const layerName = l => l.at + (l.thing ? ' (' + l.thing + ')' : '');
  const placeOf = (thing, spot, m) => { const t = T[thing]; return t && t.places ? t.places.find(p => p.spot === spot && p.moments.includes(m)) : null; };
  const boxOfLayer = (l, m) => l.thing === 'cortina' ? (l.s === 'cortinaH' ? T.cortina.half : T.cortina.box) : (placeOf(l.thing, l.at, m) || { box: l.rect }).box;

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing and the curtain with their boxes)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24; and his rows from the drawn silhouette; a small thing's and the curtain's box)
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
    add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things and the curtain with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + colsOf(left[1])[0] + ' (' + left[0] + '), the rightmost ' + colsOf(right[1])[1] + ' (' + right[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
  }

  // 3. the spots above the floor are on what the set draws: the bench's seat, the table's top, the step's top, the low stool's top (part patio, depth within .1 of the spot's); a photo on the cord hangs at its peg (the peg's u)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground') continue;
      if (s.hang) {
        const i = +k.slice(-1) - 1, peg = sheet.set.pegs[i], ok = peg && Math.abs(peg.u - s.uv[0]) < 1e-6 && s.uv[2] > E.PHOTOS.z - .16 - .001 && s.uv[2] < E.PHOTOS.z - .02 + .001 && Math.abs(s.uv[1] - E.PHOTOS.v) < .001 + .0;
        lines.push(k + ' z ' + s.uv[2] + ': hangs at the peg of u ' + (peg ? peg.u : '?') + ' (the pegs are z ' + r4(E.PHOTOS.z - .16) + ' to ' + r4(E.PHOTOS.z - .02) + ' at v .07; the cord v ' + E.PHOTOS.v + ')'); surf.push(k);
        if (!ok) bad.push(k + ' ' + s.screen + ': not at a peg of the photos\' cord (u ' + s.uv[0] + ', z ' + s.uv[2] + ', v ' + s.uv[1] + ')');
        continue;
      }
      const tol = .1;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < tol;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface the set draws (the bench\'s seat z ' + BENCH_Z + ', the table\'s top z ' + TABLE_Z + ', the step\'s top z ' + E.STEP[2] + ', the low stool\'s top z ' + E.STOOL[2] + ': part patio, depth within .1 of the spot\'s; the four photos on the cord at their pegs)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the boxes of the things (the curtain, the low stool, and each place of a sprite thing) are inside the picture and the window; and the curtain's box on its own (a check of the spec)
  {
    const bad = [], lines = [];
    const test = (k, b) => { const l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W; lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : '')); };
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      if (t.places) t.places.forEach(p => test(k + '@' + p.spot + (p.size ? ' ' + p.size.join('x') : ''), p.box)); else test(k, t.box);
    }
    add('things-in-view', bad, 'the boxes of ' + lines.map(l => l.split(' ')[0]).join(', ') + ' are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    const cb = T.cortina.box, bad2 = [];
    if (cb[0] < x0 || cb[0] + cb[2] > x0 + 196 || cb[0] < 0 || cb[0] + cb[2] > G.W || cb[1] < 0 || cb[1] + cb[3] > G.H) bad2.push('the curtain\'s box [' + cb + '] is not inside the window [' + x0 + ', ' + (x0 + 196) + ')');
    add('curtain-in-window', bad2, 'the curtain\'s box [' + cb + '] (u ' + E.CURTAIN.u0 + ' to ' + E.CURTAIN.u1 + ', z 0 to ' + E.CURTAIN.z + ' at v ' + E.CURTAIN.v + '; its left half [' + T.cortina.half + ']) is inside the window columns ' + x0 + ' to ' + (x0 + 195) + ' (its left column ' + cb[0] + ', its right ' + (cb[0] + cb[2] - 1) + ')', bad2);
  }

  // 4b. the boxes the preview draws are the sheet's boxes (every thing of a moment: its drawn box is its place's box)
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) for (const l of PV.inspect[m].layers) {
      if (!l.thing || l.thing === 'paquete_mesa') continue;
      const want = boxOfLayer(l, m), got = l.rect; lines.push('m' + m + ' ' + l.at + ' (' + l.thing + ') [' + got + ']');
      if (want.join() !== got.join()) bad.push('moment ' + m + ' ' + l.at + ' (' + l.thing + '): the preview draws it in [' + got + '], the sheet\'s box is [' + want + ']');
    }
    add('things-boxes', bad, lines.length + ' things in the 6 moments are drawn in their sheet boxes', [bad.length + ' thing(s) drawn out of their box:'].concat(bad.map(b => '  ' + b)));
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
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ', ' + Math.round(n * .01 * (ax ? 13 : 26) * 10) / 10 + ' px)'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
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
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) { const specs = PV.moment[m].layers, r = await PV.nearest(specs, fi); o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at)); }
  }

  // 7. heads-behind-table: the head (the top 14 rows of the sprite) of everyone who stands behind the table (tras_mesa, tras_mesa2, tras_mesa3) is whole in the window and covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'head' ) continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-behind-table', bad, 'everyone who stands behind the table (' + MOMENTS.map(m => 'm' + m + ': ' + PV.inspect[m].layers.filter(l => l.group === 'head').map(l => l.at).join(', ')).filter(s => !/: $/.test(s)).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people behind the table:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. fondo-head (moment 1): Carmen at fondo2 (the open side of the half curtain) has her head (the top 14 rows of the sprite) inside the arch's hole on the picture: every px shown (none hidden by the wall's rim) and none behind the half curtain
  {
    const bad = [], A = E.ARCH, am = (A[0] + A[1]) / 2, ah = (A[1] - A[0]) / 2, zs = A[3] - (A[1] - A[0]) / 2 * .7, zh = (A[1] - A[0]) / 2 * .7, half = T.cortina.half;
    const inHole = (X, Y) => { const u = (X + .5 - G.OX) / G.S, z = (G.OY - (Y + .5)) / 22.5; return u > A[0] && u < A[1] && z >= A[2] && (z < zs || Math.hypot((u - am) / ah, (z - zs) / zh) < 1); };
    const m = 1, L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'fondo2'), l = L[i];
    const top = Math.min(...l.px.map(p => p[1])), head = l.px.filter(p => p[1] < top + HEAD_ROWS), outside = head.filter(p => !inHole(p[0], p[1])), hid = head.filter(p => p[2]);
    const curt = idxAt(L, 'cortina'), cc = coverOf(L, M, i, [curt], [0, HEAD_ROWS]), all = coverOf(L, M, i, [curt], null);
    const hole = [G.OX + A[0] * G.S, G.OX + A[1] * G.S, G.OY - A[3] * 22.5, G.OY].map(r2);
    if (outside.length || hid.length || cc.cov) bad.push('moment 1 fondo2 ' + [l.sx, l.sy] + ': the head (rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ', columns ' + Math.min(...head.map(p => p[0])) + ' to ' + Math.max(...head.map(p => p[0])) + '): ' + outside.length + ' of ' + head.length + ' px outside the arch\'s hole [x ' + hole[0] + ' to ' + hole[1] + ', y ' + hole[2] + ' to ' + hole[3] + '], ' + hid.length + ' hidden by the set, ' + cc.cov + ' behind the half curtain [' + half + ']');
    const o = add('fondo-head', bad, 'in moment 1 Carmen at fondo2 ' + [l.sx, l.sy] + ' has her head (rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ', columns ' + Math.min(...head.map(p => p[0])) + ' to ' + Math.max(...head.map(p => p[0])) + ') inside the arch\'s hole (x ' + hole[0] + ' to ' + hole[1] + ', y ' + hole[2] + ' to ' + hole[3] + ') and clear of the half curtain [' + half + ']: ' + head.length + ' px, ' + outside.length + ' outside, ' + hid.length + ' hidden by the set, ' + cc.cov + ' behind the curtain', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {
      const base = PV.moment[m].layers[i], headOK = lay => { const tp = Math.min(...lay.px.map(p => p[1])), hd = lay.px.filter(p => p[1] < tp + HEAD_ROWS); return hd.every(p => !p[2] && inHole(p[0], p[1]) && !inside(half, p[0], p[1])); }, res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) {
        let f = null;
        for (let k = 1; k <= 400 && !f; k++) for (const sg of [1, -1]) { const uvz = S.fondo2.uv.slice(); uvz[ax] = r4(uvz[ax] + sg * k * .01); const lay = (await PV.layers([Object.assign({}, base, { at: null, uvz, off: null })]))[0]; if (headOK(lay)) { f = lab + ' ' + S.fondo2.uv[ax] + ' -> ' + uvz[ax] + ' (' + sgn(sg * k * .01) + ', ' + r2(k * .01 * (ax ? 13 : 26)) + ' px)'; break; } }
        res.push(f || lab + ': none within 4');
      }
      o.lines.push('       nearest passing, moment 1 fondo2 ' + S.fondo2.uv + ': ' + res.join('; ') + '; z is not moved');
    }
    o.lines.push('       info, not a check: the half curtain covers ' + all.cov + ' of her ' + all.tot + ' px (' + cc.cov + ' of her head\'s ' + cc.tot + ')');
  }

  // the checks "X is covered by nobody": per moment the things of a group: no person's shown pixel on a pixel of the thing or in its box nearer than it (a thing that overlaps a thing is info, not a check: "nobody" is a person),
  // and the thing not hidden by the set; a hint: the least shift of whoever covers it that clears the box
  const peopleOf = L => L.map((l, i) => l.who ? i : -1).filter(i => i >= 0);
  const thingCheck = async (name, moments, group, intro) => {
    const bad = [], lines = [], hints = [], infos = [];
    for (const m of moments) {
      const L = PV.inspect[m].layers, M = planes(L), people = peopleOf(L), parts = [];
      for (const [i, l] of L.entries()) {
        if (l.group !== group) continue;
        const box = boxOfLayer(l, m), c = coverOf(L, M, i, people), bc = boxCover(L, i, box, people), ov = boxCover(L, i, box, L.map((q, j) => j !== i && !q.who ? j : -1).filter(j => j >= 0)), fi = L.findIndex(q => q.who === 'coqui'), fb = boxCover(L, i, box, [fi]);
        parts.push(l.at + ' (' + l.thing + ') [' + box + ']: ' + c.tot + ' px, ' + c.cov + ' covered by people, ' + bc.n + ' nearer px of people in its box' + (bc.n ? ' (' + whoTxt(bc) + ')' : '') + ', ' + fb.n + ' px of the frog in its box, ' + c.hid + ' hidden by the set');
        if (ov.n) infos.push('m' + m + ' ' + l.at + ' (' + l.thing + '): ' + ov.n + ' nearer px of other things in its box (' + whoTxt(ov) + ')');
        if (c.cov || c.hid || c.out || bc.n) { bad.push('moment ' + m + ' ' + l.at + ' (' + l.thing + '): ' + c.cov + ' px covered, ' + bc.n + ' nearer px of ' + (whoTxt(bc) || 'nobody') + ' in its box, ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture'); for (const w of Object.keys(bc.who)) hints.push([m, i, w, box]); }
      }
      lines.push('m' + m + ': ' + parts.join('; '));
    }
    const o = add(name, bad, intro + ': ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b2 => '  ' + b2)));
    const seen = new Set();
    for (const [m, i, w, box] of hints) { if (seen.has(m + w + box)) continue; seen.add(m + w + box); const Mo = PV.moment[m], j = Mo.layers.findIndex(q => q.at === w); if (j >= 0) { const r = await PV.nearestFree(Mo.layers, j, [box]); o.lines.push('       nearest passing, moment ' + m + ' (' + w + ' over the thing at ' + PV.inspect[m].layers[i].at + '): ' + w + ' ' + S[w].uv + ': ' + axisTxt(r, w)); } }
    if (infos.length) o.lines.push('       info, not a check: ' + infos.join('; '));
    return o;
  };

  // 9. the things on the bench are covered by nobody (moments 1 and 2): the cake, the box with the bow, the flowers
  await thingCheck('bench-things', [1, 2], 'banco', 'in moments 1 and 2 the things on the bench (m1: cake, box, flowers; m2: cake, flowers) are covered by nobody and hidden by nothing');
  // 10. the things and packets on the table are covered by nobody (moments 2, 3 and 6), and the frog at mesa_coqui covers none of them (no pixel of his on a thing's pixels or in its box)
  await thingCheck('table-things', [2, 3, 6], 'mesa', 'in moments 2, 3 and 6 the things and packets on the table (m2: box; m3: box, cake, flowers; m6: two packets) are covered by nobody (the frog at mesa_coqui covers none: 0 px of his in any box) and hidden by nothing');
  // 11. the four photos on the cord are covered by nobody (moment 4)
  await thingCheck('photos-cord', [4], 'fotoC', 'in moment 4 the four photos on the cord are covered by nobody and hidden by nothing');
  // 12. the four photos on the table are covered by nobody and the frog on the low stool covers none (moment 5)
  await thingCheck('photos-table', [5], 'fotoT', 'in moment 5 the four photos on the table are covered by nobody (the frog on the low stool covers none: 0 px of his in any box) and hidden by nothing');
  // 13. the cake is covered by nobody (moments 4 and 5): the cake and its seven candles
  await thingCheck('cake', [4, 5], 'cake', 'in moments 4 and 5 the cake with its seven candles at mesa2 is covered by nobody and hidden by nothing');

  // 14. abuelo on the step stool covers no photo and no peg (moment 5): none of his shown pixels in the boxes of the four photos on the cord and of the four pegs, and none nearer than a photo of the four on the table in its box
  {
    const bad = [], m = 5, L = PV.inspect[m].layers, i = idxAt(L, 'taburete'), l = L[i], parts = [], top = Math.min(...l.px.map(p => p[1]));
    const boxes = [...['cuerda1', 'cuerda2', 'cuerda3', 'cuerda4'].map(k => [k, S[k].box]), ...['fotos1', 'fotos2', 'fotos3', 'fotos4'].map(k => [k, S[k].box]), ...sheet.set.pegs.map((p, j) => ['peg' + (j + 1), p.box])];
    for (const [n, b] of boxes) {
      let k;
      if (n.startsWith('fotos')) { const f = L.find(q => q.at === n); k = l.px.filter(p => !p[2] && inside(b, p[0], p[1]) && p[3] > planeOf(f, p[1]) + EPS).length; }
      else k = l.px.filter(p => !p[2] && inside(b, p[0], p[1])).length;
      parts.push(n + ' [' + b + ']: ' + k);
      if (k) bad.push('moment 5 abuelo at taburete ' + [l.sx, l.sy] + ' covers ' + k + ' px of ' + n + ' [' + b + ']');
    }
    const o = add('step-clear', bad, 'in moment 5 abuelo on the step stool (taburete ' + [l.sx, l.sy] + ', his drawn columns ' + Math.min(...l.px.map(p => p[0])) + ' to ' + Math.max(...l.px.map(p => p[0])) + ', rows ' + top + ' to ' + Math.max(...l.px.map(p => p[1])) + ') covers no photo and no peg: 0 px of his in the boxes of the four photos on the cord, of the four on the table (nearer than them) and of the four pegs (' + parts.join(', ') + ')', [bad.length + ' problem(s):'].concat(bad.map(b2 => '  ' + b2)));
    if (bad.length) { const specs = PV.moment[m].layers, r = await PV.nearestFree(specs, i, boxes.filter(b2 => !b2[0].startsWith('fotos')).map(b2 => b2[1])); o.lines.push('       nearest passing, moment 5 taburete ' + S.taburete.uv + ': ' + axisTxt(r, 'taburete') + ' (z is the step\'s top: not moved)'); }
  }

  // 15. the packet on the low stool is covered by nobody (moment 6)
  await thingCheck('packet-stool', [6], 'paquete', 'in moment 6 the packet on the low stool (paquete) is covered by nobody and hidden by nothing');

  // info: what the spec lists no check for: the people over the box of the low stool, the curtain's box (m1 to m3) covered by whom
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, parts = [];
      const ci = L.findIndex(l => l.thing === 'cortina');
      if (ci >= 0) { const bc = boxCover(L, ci, boxOfLayer(L[ci], m), null); parts.push('the curtain\'s box: ' + bc.n + ' nearer px of others' + (bc.n ? ' (' + whoTxt(bc) + ')' : '')); }
      const qb = T.banqueta.box; let k = 0; for (const [i, l] of L.entries()) if (!l.thing && l.at !== 'banqueta_coqui') k += l.px.filter(p => !p[2] && inside(qb, p[0], p[1])).length; parts.push('the low stool\'s box [' + qb + ']: ' + k + ' px under anyone but the frog on it');
      lines.push('m' + m + ': ' + parts.join(', '));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
