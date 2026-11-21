#!/usr/bin/env node
'use strict';
/* El baño's sheet (place 9, La casa, un día entero, scene 2): writes docs/proyecto/pixel/bano-sheet.json from bano-set.html and the design (the orchestrator's p9-spec, general rules and section "bano"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/bano-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 66 here). The shower, its tap, the sink and its tap, the mirror, the two shelves, the heater's gauge, the door,
   the stool and the basket are read from the set (window.BANO.E), never typed again from the design.
   It loads the set in headless Chrome (bano-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (bano-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with BANO_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'bano-sheet.json');
const BASE = process.env.BANO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/bano-set.html';
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

// the numbers of the design (p9-spec: the rules for every sheet, and "bano")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SHOULDER_ROW = 20;                                 // the shoulders, counted from the top row the drawing draws (mkPersona: the neck is canvas rows 16 to 19, the arms start at row 21; the ink starts at canvas row 2 for a child): about row 20
const BANQUITO_Z = .3;                                   // Carmen on the small stool: the stool's top
const MOMENTS = [1, 2, 3, 4, 5, 6, 7];
const SZ = { toalla: [12, 8], jabon: [8, 5], tubo: [5, 9], cepillito: [6, 4], cosa: [12, 6], manos: [12, 8], llave: [10, 10], barra: [8, 3], banco: [12, 7], toallaCab: [16, 10] };
const SILKEY = { adulto: 'abuelo', abuela: 'abuela', nino: 'luis', lluvia: 'lluvia', coqui: 'coqui', perro: 'perro' };      // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a shelf, a table top's height).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  abuela_bano: { to: [-1.37, 2.6, 0], why: 'sprites-apart: in moment 1 abuela was 22 px sideways from Luis at lavamanos1 (the boxes need 24) and 3 px up-down (needs 12): u -1.3 -> -1.37 (-.07, 2 px); the least move on either axis of either spot that clears every pair of her moments (v 2.6 -> 1.49 would also clear it: -1.11)' },
  ducha_perro: { to: [-3.26, 1.1, 0], why: 'moments-in-view: his tail was 1 px outside the window: u -3.3 -> -3.26. He stays inside the shower, behind its wall and beside abuela: that pair is let off sprites-apart' },
  lavamanos1: { to: [-.45, 2.43, 0], why: 'shelf-things-clear: in moment 6 Luis\'s head covered 3 px of the tube at tubo: v 2.4 -> 2.43 (+.03, 1 px down; u -.45 -> -.52 (-.07) would also clear it)' },
  lavamanos2: { to: [.5, 2.43, 0], why: 'shelf-things-clear: in moment 6 Carmen\'s head covered 4 px of the tiny brush at cepillito: v 2.4 -> 2.43 (+.03, 1 px down; u .5 -> .56 (+.06) would also clear it)' },
  banquito: { to: [.18, 2.3, BANQUITO_Z], why: 'shelf-things-clear: in moment 7 Carmen on the stool covered 25 px of the tube at tubo (her head is over the sink\'s left half): u 0 -> .18 (+.18, 5 px to the right, still before the mirror); the least move (v 2.3 -> 2.79 (+.49) would also clear it)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor }
   kind: person (a character stands there), place (the frog's), thing (a small thing: the soap, a towel, the tube)
   sil: which drawing hangs there (adulto = a grown-up standing, abuela, nino = a child standing, lluvia = the child in the raincoat, perro = Canelo standing, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle on the point, centre = its middle
   on: the part of the set it stands on above the floor: bano (the shelves, the sink, the stool: the part that draws the room), banquito (a stand-in stool drawn by the preview) */
function defs(E) {
  const SH = E.SHOWER, K = E.SINK, SL = E.SHELF_L, SR = E.SHELF_R, ST = E.STOOL, D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const lip = r4(K.v + K.hd - .08);                                    // the sink's front edge: v .68
  // the people, in the door and in the room
  add('puerta1', [3.2, .7, 0], 'person', 'adulto', 'adulto', 'in the door: abuelo (100 opening), abuela (100 game, 101 opening)');
  add('puerta2', [2.55, 1.6, 0], 'person', 'adulto', 'adulto', 'just inside the door (no moment of the preview has anyone here)');
  add('lavamanos1', [-.45, 2.4, 0], 'person', 'nino', 'nino', 'a child at the sink\'s left, in front of it (the sink is at u ' + K.u + '): Luis (99 opening and game, 101 game)');
  add('lavamanos2', [.5, 2.4, 0], 'person', 'nino', 'nino', 'a child at the sink\'s right, in front of it: Carmen (99 opening, 100 opening, 101 game)');
  add('banquito', [0, 2.3, BANQUITO_Z], 'person', 'nino', 'nino', 'Carmen standing on a small stool at the sink, before the mirror (101 opening): the stool is a ' + SZ.banco.join(' x ') + ' px stand-in drawn under her, its top row on her feet\'s row (z ' + BANQUITO_Z + ' is ' + Math.round(BANQUITO_Z * 22.517) + ' px up); the set draws no stool here', { on: 'banquito' });
  add('ante_espejo', [0, 2.5, 0], 'person', 'adulto', 'adulto', 'abuelo before the mirror (100 ending; no moment of the preview has him)');
  add('ducha_dentro', [r4((SH.u0 + SH.u1) / 2), .8, 0], 'person', 'adulto', 'adulto', 'someone in the shower, in the middle of it (the shower runs u ' + SH.u0 + ' to ' + SH.u1 + '; the low front wall is at v ' + SH.v1 + '): abuela (99 game), Luis (100 opening, a child)');
  add('ducha_perro', [r4(SH.u0 + .45), 1.1, 0], 'person', 'perro', 'perro', 'Canelo in the shower, at its left end (the low wall hides what it hides of him)');
  add('centro', [-1.2, 3.3, 0], 'person', 'lluvia', 'nino', 'a child in a raincoat with its hood up, in the middle of the room, as far from the shower as from the sink (100 game)');
  add('abuela_bano', [-1.3, 2.6, 0], 'person', 'abuela', 'adulto', 'abuela standing in the room (99 opening and ending)');
  add('piso_perro', [1.2, 4.0, 0], 'person', 'perro', 'perro', 'Canelo on the floor of the room (99 opening): the spec gives the place, (1.2, 4.0, 0), not a name: the name is the make\'s');
  // the frog
  add('piso_coqui', [-.3, 3.9, 0], 'place', 'coqui', 'coqui', 'the frog on the floor, in front of the sink');
  add('repisa_coqui', [r4((SL.u0 + SL.u1) / 2), .32, SL.z], 'place', 'coqui', 'coqui', 'the frog on the left shelf, in the middle of it (SHELF_L u ' + SL.u0 + ' to ' + SL.u1 + ', v to ' + SL.v1 + '): its top, z ' + SL.z, { on: 'bano' });
  add('lavamanos_coqui', [K.u, K.v, K.h], 'place', 'coqui', 'coqui', 'the frog sitting in the sink (SINK u ' + K.u + ', v ' + K.v + '): its top, z ' + K.h, { on: 'bano' });
  // the two towels on the stool
  add('toalla_a', [r4(ST.u - .25), ST.v, ST.h], 'thing', null, null, 'the first folded towel on the stool (a ' + SZ.toalla.join(' x ') + ' px stand-in): its bottom middle on the stool\'s top, z ' + ST.h, { size: SZ.toalla, anchor: 'bottom', on: 'bano' });
  add('toalla_b', [r4(ST.u + .25), ST.v, ST.h], 'thing', null, null, 'the second folded towel on the stool: its bottom middle on the stool\'s top, z ' + ST.h, { size: SZ.toalla, anchor: 'bottom', on: 'bano' });
  // on the sink's front edge (v SINK.v + SINK.hd - .08)
  add('jabon', [r4(K.u + .3), lip, K.h], 'thing', null, null, 'the bar of soap on the sink\'s front edge (a ' + SZ.jabon.join(' x ') + ' px stand-in): its bottom middle on the sink\'s top, z ' + K.h + ', v ' + lip, { size: SZ.jabon, anchor: 'bottom', on: 'bano' });
  add('tubo', [r4(K.u - .3), lip, K.h], 'thing', null, null, 'the tube of toothpaste on the sink\'s front edge, at its left (a ' + SZ.tubo.join(' x ') + ' px stand-in): its bottom middle on the sink\'s top', { size: SZ.tubo, anchor: 'bottom', on: 'bano' });
  add('cepillito', [r4(K.u + .3), lip, K.h], 'thing', null, null, 'the frog\'s tiny brush on the sink\'s front edge, at its right (a ' + SZ.cepillito.join(' x ') + ' px stand-in; the spec gives it the soap\'s u, they are never in one moment): its bottom middle on the sink\'s top', { size: SZ.cepillito, anchor: 'bottom', on: 'bano' });
  // on the right shelf (v .32)
  add('cosa_a', [.95, .32, SR.z], 'thing', null, null, 'the first of the two things on the right shelf (a ' + SZ.cosa.join(' x ') + ' px stand-in: the toothbrush with its squeeze or the comb): its bottom middle on the shelf\'s top, z ' + SR.z, { size: SZ.cosa, anchor: 'bottom', on: 'bano' });
  add('cosa_b', [1.55, .32, SR.z], 'thing', null, null, 'the second of the two things on the right shelf: its bottom middle on the shelf\'s top, z ' + SR.z, { size: SZ.cosa, anchor: 'bottom', on: 'bano' });
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   spec-projection (the spec's arithmetic is the engine's), views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), moments-in-view (every drawn pixel of
   every sprite of the moments inside the picture and the window), spots-on-surface (the spots on a shelf, the sink, the stool are on what the set draws), things-in-view (the set things' boxes),
   sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (Carmen on the stool: her head covered by nobody and by nothing), ducha-body (whoever stands in the shower
   shows his top 14 rows over the low wall), fixtures-clear (both taps, the mirror and the gauge covered by nobody in moments 4 and 5), shelf-things-clear (cosa_a, cosa_b, tubo, cepillito in moments 6 and 7),
   towels-clear (the two towels in moment 2), frog-shelf (the frog on the left shelf stands on its top and covers neither tap), frog-sink (the frog in the sink is whole and on its top), bars-in-gauge.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(BANO.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY, pzxy: PZ.xy(.7, 1.3) };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  let sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs);
  let lo = 1e9, hi = -1e9; for (const m of MOMENTS) for (const l of PV.inspect[m].layers) for (const p of l.px) { lo = Math.min(lo, p[0]); hi = Math.max(hi, p[0]); }
  sheet = await make(G, proj, [lo, hi]);                                                  // second pass: x0 holds the drawn pixels of the moments too
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');
  await addHands(sheet, PV, G);
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

/* ---------- the preview's moments: bano-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/bano-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {}, spr: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(k => window.PREVIEW.silhouette(k), v);
  for (const k of ['luisYo']) PV.spr[k] = await p.evaluate(k => window.PREVIEW.sprite(k), k);
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
async function make(G, proj, ink) {
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
    if (d.moved) { o.spec = W4(d.spec); o.moved = d.moved; }
    spots[d.name] = o;
  });

  /* ---- the view: x0 so that every spot is inside the picture and the window ---- */
  const held = Object.entries(spots);
  const ext = held.map(([, s]) => colsOf(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0)) && (!ink || (x0 <= ink[0] && x0 + 195 >= ink[1]))) ok0.push(x0);       // ink: the first and the last column any sprite of any moment draws (the second pass, once the preview has been read)
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const cutBy = held.filter(([, s]) => cutAt(s, centred)).map(([k, s]) => k + ' (' + cutAt(s, centred) + ' px)').concat(ink && (ink[0] < centred || ink[1] > centred + 195) ? ['the drawn pixels of the moments (columns ' + ink[0] + ' to ' + ink[1] + ')'] : []);
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [99, 100, 101], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 99, 100 and 101: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (cutBy.length ? 'At x0 ' + centred + ' ' + cutBy.join(', ') + ' would be cut. ' : '') + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + (ink ? '; the sprites of the 7 moments draw columns ' + ink[0] + ' to ' + ink[1] : '') + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what, clip) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    if (clip && b.box[1] < 0) { b.box[3] += b.box[1]; b.box[1] = 0; }                  // the wall runs above the picture's top: the box stops at the picture
    const t = { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
    if (v0 === v1) t.quad = [0, 1, 5, 4].map(i => W4([q[i][3], q[i][4], corners[i][2]]));          // a plane facing the camera: its four corners
    return t;
  };
  // a box of a given size centred on a point of the wall or of a fixture
  const centreThing = async (u, v, z, size, what) => {
    const q = (await proj([[u, v, z]]))[0], sx = Math.round(q[0]), sy = Math.round(q[1]);
    return { set: true, uv: W4([u, v, z]), world: W4([q[3], q[4], z]), box: [sx - size[0] / 2, sy - size[1] / 2, size[0], size[1]], what };
  };
  const SH = E.SHOWER, TS = E.TAP_SHOWER, K = E.SINK, M = E.MIRROR, HT = E.HEATER, BK = E.BASKET, things = {};
  things.ducha = await setThing(SH.u0, 0, 0, SH.u1, 0, E.WALL, 'the shower\'s corner of the back wall: its dark tiles, u ' + SH.u0 + ' to ' + SH.u1 + ', from the floor (z 0) up (the wall is z ' + E.WALL + ', the picture stops at its top row), on the wall (v 0). The low front wall (v ' + SH.v1 + ') and the shower\'s floor are not in it (open point)', true);
  things.llave_ducha = await centreThing(TS[0], 0, TS[1], SZ.llave, 'a ' + SZ.llave.join(' x ') + ' px box on the shower\'s tap (TAP_SHOWER u ' + TS[0] + ', z ' + TS[1] + ': the round plate with the red and the blue knob, on the wall outside the shower)');
  const tapV = r4(K.v - K.hd + .08), tapZ = r4(K.h + .125);
  things.llave_lavamanos = await centreThing(K.u, tapV, tapZ, SZ.llave, 'a ' + SZ.llave.join(' x ') + ' px box on the sink\'s tap (the tap is on the sink\'s top at its back: u ' + K.u + ', v ' + tapV + ', from z ' + K.h + ' to ' + r4(K.h + .25) + '; the box is centred on its middle, z ' + tapZ + ')');
  things.espejo = await setThing(r4(M[0] - .08), 0, r4(M[2] - .08), r4(M[1] + .08), 0, r4(M[3] + .08), 'the mirror with its frame: u ' + M[0] + ' to ' + M[1] + ', z ' + M[2] + ' to ' + M[3] + ' (the frame .08 round it), on the wall (v 0)');
  things.calentador = await setThing(r4(HT.gauge[0] - .16), 0, r4(HT.gauge[1] - .22), r4(HT.gauge[0] + .16), 0, r4(HT.gauge[1] + .22), 'the water heater\'s gauge: the dark rectangle u ' + r4(HT.gauge[0] - .16) + ' to ' + r4(HT.gauge[0] + .16) + ', z ' + r4(HT.gauge[1] - .22) + ' to ' + r4(HT.gauge[1] + .22) + ' (HEATER.gauge ' + HT.gauge + '), on the wall (v 0). Its three red bars are sprites, each ' + SZ.barra.join(' x ') + ' px (bars: their boxes, top to bottom, 3 px apart, centred on the gauge: the make\'s numbers, open point)');
  things.calentador.gauge = W4(HT.gauge);
  { const g = scrUV(G, HT.gauge[0], 0, HT.gauge[1]); things.calentador.bars = [-3, 0, 3].map(dy => [g[0] - 4, g[1] + dy - 1, SZ.barra[0], SZ.barra[1]]); }
  things.canasta = await setThing(r4(BK[0] - .3), r4(BK[1] - .3), 0, r4(BK[0] + .3), r4(BK[1] + .3), .55, 'the basket (BASKET u ' + BK[0] + ', v ' + BK[1] + ': a drum of radius .3, z 0 to .55)');
  const touch = { jabon: 'jabon', toalla_a: 'toalla_a', toalla_b: 'toalla_b', cosa_a: 'cosa_a', cosa_b: 'cosa_b', tubo: 'tubo', cepillito: 'cepillito' };
  for (const k of Object.keys(touch)) things[k] = 'sprite';
  for (const k of ['abuela', 'abuelo', 'luis', 'carmen', 'perro', 'coqui']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'bano',
    made: 'node docs/proyecto/pixel/bano-sheet-make.js, from bano-set.html (window.BANO.E) and the design of El baño (the orchestrator\'s p9-spec, general rules and section bano). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + BANQUITO_Z + ': the small stool Carmen stands on; z ' + E.SHELF_L.z + ': the shelves\' tops and the sink\'s top; z ' + E.STOOL.h + ': the stool\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): its bottom middle on the spot (the box [sx - floor(w / 2), sy - h, w, h]). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX); a grown-up (abuelo) draws 51 rows of a 56-row canvas, a child 41 of 44 (the raincoat child 43: the hood), their lowest canvas rows empty; abuela standing mkAbuela (48 x 51): column 30, 50 rows drawn; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); Canelo standing mkPerro (30 x 22): column 15 and its bottom edge, 30 columns of ink (his box is 28); a small thing: see spot. The stool under Carmen (12 x 7): its top row on her feet\'s row sy, its middle column on sx, so its bottom edge is on the floor point of her spot (sy + 7). A towel over a head (16 x 10): its top row on the top row of the child\'s drawing, its middle column on his. The gauge\'s three bars (8 x 3): centred on the gauge, 3 px apart. Nobody is drawn turned: whoever stands in the shower or at the sink faces us',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      ducha: 'ducha_dentro (' + r4((SH.u0 + SH.u1) / 2) + ', .8, 0) is behind the shower\'s low front wall (v ' + SH.v1 + ', z 0 to ' + SH.wall + '): the depth rule hides what the wall covers (the wall\'s top edge is on picture row ' + r2(G.OY + (SH.v1 + .07) * 13 - SH.wall * 22.5) + ', the feet of someone at v .8 on row ' + r2(G.OY + .8 * 13) + ': see the ducha-body check)',
    },
    setKey: {
      params: {},
      key: 'none: one state (hora dia)',
      baked: ['bano-set.html'],
    },
    things,
    spots,
    groups: {
      touch,
      persons: { abuela: ['abuela_bano', 'ducha_dentro', 'puerta1'], abuelo: ['puerta1', 'ante_espejo'], luis: ['lavamanos1', 'ducha_dentro'], carmen: ['lavamanos2', 'banquito'], perro: ['ducha_perro', 'piso_perro'] },
      repisa_izq: ['repisa_coqui'], repisa_der: ['cosa_a', 'cosa_b'], lavamanos: ['jabon', 'tubo', 'cepillito'], toallas: ['toalla_a', 'toalla_b'],
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p9-spec, "bano"), given in (u, v, z); the shower, the sink, the shelves, the stool, the heater\'s gauge and the basket are read from the set',
      'things: ducha, llave_ducha, llave_lavamanos, espejo, calentador, canasta are boxes on the picture (ducha: the corner of the back wall only); manos_luis is a 12 x 8 box at Luis\'s hands when he stands at lavamanos1 with his hands held up (the preview draws him with the maker\'s "yo" pose, both hands up at his chest: the box is centred on them); jabon, toalla_a, toalla_b, cosa_a, cosa_b, tubo and cepillito are sprites at the spots groups.touch names; the people are sprites. calentador.bars: the three bars\' boxes',
      'whoever stands (every person here) is hung by the feet on the spot; Carmen at banquito stands on a stand-in stool 12 x 7 (z ' + BANQUITO_Z + ' is 7 px); abuelo is KIT.FAM.abuelo (the family\'s grandfather, a grown-up man); mama is only a voice',
      'abuela, abuelo and Luis are at ducha_dentro in different moments (abuela 99 game, Luis 100 opening): one spot for a grown-up or a child (the sprite box is 24 wide for both)',
      'the spec gives no radius for Canelo\'s shadow: .3 used (as El calendario: open point); the others are El cruce\'s (frog .45, grown-ups .35, children .28)',
      'OPEN POINTS (choices the spec does not settle, made in the preview only): the gauge\'s three bars are drawn in moments 4 and 5 (story 100) and nowhere else; the tiny brush is not drawn in moment 7 (the spec\'s moment lists only the tube: info-touch says what it would be under); Luis at lavamanos1 in moments 1 and 2 is drawn with his hands up (the maker\'s "yo" pose), in moment 6 standing; the towels on the stool are red and blue, the two things on the right shelf the toothbrush at cosa_a and the comb at cosa_b; Canelo is drawn standing; the child in the raincoat is Luis\'s maker in yellow with a yellow hood',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite box, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the shower\'s low front wall hides the lower rows of whoever stands in the shower, the sink and the stool hide the legs of whoever stands behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El pedido\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) and .3 for Canelo (as El calendario; open point)',
      none: DEF.filter(d => d.uvz[2] > 0 || (d.kind === 'person' && d.uvz[0] > SH.u0 && d.uvz[0] < SH.u1 && d.uvz[1] < SH.v1)).map(d => d.name),
      onSeat: 'whoever stands on the stool, the frog on a shelf or in the sink, the things on the stool, the sink and the shelves (z above 0) cast none: none of those is floor; whoever stands inside the shower (a spot with u between SHOWER.u0 and u1 and v less than SHOWER.v1: ducha_dentro, and ducha_perro when it is inside) casts none: the shower has its own floor behind its low wall (a shadow cast at the ground under it would be the room\'s)',
    },
  };
}

// Luis's hands: a 12 x 8 box at them when he stands at lavamanos1 with his hands held up (the preview's "yo" pose: both hands on his chest; mkPersona: the hands are the two skin ellipses at row sh + 3.5 = 24.5 of the canvas, 2.5 px each side of the middle column)
async function addHands(sheet, PV, G) {
  const s = sheet.spots.lavamanos1, sp = PV.spr.luisYo, yc = s.screen[1] - (sp.ay - 24.5);
  sheet.things.manos_luis = { set: true, uv: s.uv.slice(0, 2).concat([0]), world: s.world, box: [s.screen[0] - SZ.manos[0] / 2, Math.round(yc - SZ.manos[1] / 2), SZ.manos[0], SZ.manos[1]], hands: [s.screen[0], r2(yc)], what: 'a ' + SZ.manos.join(' x ') + ' px box at Luis\'s hands when he stands at lavamanos1 (' + s.screen + ') with his hands held up: centred on his middle column and on the row of his hands (row 24.5 of the canvas of the "yo" pose, ' + r2(sp.ay - 24.5) + ' px above his feet\'s row: the sprite is ' + sp.h + ' rows tall, its lowest drawn row is ' + (sp.ay - 1) + ')' };
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
      if (nearest) { cov++; const a = L[nearest.i].at || L[nearest.i].group; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  // the shown pixels of layer i inside a box
  const shownIn = (L, i, box) => L[i].px.filter(p => !p[2] && inside(box, p[0], p[1])).length;
  const idxAt = (L, at) => L.findIndex(l => l.at === at && !l.group);                                // the person or the frog at a spot (a thing, the stool, the towel at the same spot has a group)
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  const lname = l => l.at || l.group || l.s;

  // 0. the spec's arithmetic is the engine's projection: sx = OX + 26 u, sy = OY + 13 v - 22.5 z (rounded)
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

  // 1. the view: x0 holds every spot (a person with his sprite box, a small thing with its box); x0 22 unless a spot is cut
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const at22 = v.holds.map(k => [k, cutAt(S[k], 22)]).filter(o => o[1]);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + (v.x0 === 22 ? ' (22, the window centred on the picture)' : '; at the spec\'s 22 these are cut: ' + (at22.map(a => a[0] + ' ' + a[1] + ' px').join(', ') || 'none') + ' (so x0 ' + v.x0 + ', the nearest to 22 that holds them all)'), [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
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

  // 3. moments-in-view: every sprite of every moment (people and small things) whole inside the picture and the window: no drawn pixel outside
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers; let n = 0;
      for (const l of L) {
        const xs = l.px.map(p => p[0]), lo = Math.min(...xs), hi = Math.max(...xs), cut = Math.max(0, x0 - lo) + Math.max(0, hi - (x0 + 195));
        n += l.px.length + l.out;
        if (cut || l.out) bad.push('moment ' + m + ': ' + lname(l) + ' ' + [l.sx, l.sy] + ': drawn columns ' + lo + ' to ' + hi + ' (window ' + x0 + ' to ' + (x0 + 195) + '): ' + cut + ' px cut by the window, ' + l.out + ' px outside the picture');
      }
      lines.push('m' + m + ' ' + L.length + ' sprites');
    }
    add('moments-in-view', bad, 'every drawn pixel of every sprite of the 7 moments is inside the picture and the window [' + x0 + ', ' + (x0 + 196) + ') (' + lines.join(', ') + ')', [bad.length + ' sprite(s) cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 4. the spots above the floor are on what the set draws: the shelves' tops, the sink's top, the stool's top (part bano: the room; the pixel under the spot at the spot's depth, within .1)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground') continue;
      if (s.on === 'banquito') {                                          // the stand-in stool: the set draws none; its top is on her feet's row and its bottom edge on the floor point
        const floor = scrUV(G, s.uv[0], s.uv[1], 0)[1], h = floor - s.screen[1], ok = h === SZ.banco[1];
        lines.push(k + ' z ' + s.uv[2] + ': a stand-in stool ' + SZ.banco.join(' x ') + ' drawn under her: its top row on row ' + s.screen[1] + ', its bottom edge on the floor point\'s row ' + floor + ' (' + h + ' px up from the floor, the stool is ' + SZ.banco[1] + ' rows); the set draws no stool there'); surf.push(k);
        if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ': the floor point is ' + h + ' px below her feet, the stand-in stool is ' + SZ.banco[1] + ' rows');
        continue;
      }
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface (the shelves\' tops z ' + E.SHELF_L.z + ', the sink\'s top z ' + E.SINK.h + ', the stool\'s top z ' + E.STOOL.h + ': part bano, depth within .1 of the spot\'s; banquito: its stand-in stool)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 5. the set things' boxes are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      for (const [nm, b] of [[k, t.box]].concat((t.bars || []).map((bb, i) => [k + '.bar' + (i + 1), bb]))) {
        const l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
        lines.push(nm + ' [' + b + ']');
        if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + nm + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
      }
    }
    add('things-in-view', bad, 'the boxes of ' + Object.keys(T).filter(k => T[k] !== 'sprite').join(', ') + ' (and the three bars) are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 6. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [], partners = {};
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN || (a.at.startsWith('ducha') && b.at.startsWith('ducha'));   // abuela and the dog she washes share the shower
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        (partners[a.at] = partners[a.at] || []).push({ m, o: b, half }); (partners[b.at] = partners[b.at] || []).push({ m, o: a, half });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    // the least move of a spot along an axis (steps of .01, up to 4 either way) that clears every pair the spot is in, in every moment (the others stay where they are)
    const nearestOf = name => {
      const s = S[name], res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) {
        let f = null;
        for (const sg of [-1, 1]) {
          const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]);
          if ((partners[name] || []).every(p => Math.abs(sx - p.o.sx) >= p.half || Math.abs(sy - p.o.sy) >= UPDOWN)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; }
        }
        if (f) { res.push(f); break; }
      }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 7 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 7 moments):'].concat(bad.map(b => '  ' + b)));
    const seen = new Set();
    for (const h of hints) for (const nm of [h.a.at, h.b.at]) { if (seen.has(h.m + nm + (nm === h.a.at ? h.b.at : h.a.at))) continue; seen.add(h.m + nm + (nm === h.a.at ? h.b.at : h.a.at)); o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + nm + ' ' + S[nm].uv + ': ' + nearestOf(nm) + ' (clears every pair the spot is in, in every moment)'); }
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 7. frog-seen: the frog is never behind a person or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
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

  // 8. heads-clear: Carmen on the small stool (banquito, moment 7), the one raised on a seat: whole in the window and her head (the top 14 rows of the sprite) covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.at !== 'banquito' || !l.who) continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of her head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) if (S[w]) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'nobody sits or lies in El baño; the one raised on a seat, Carmen on the stool at banquito (m7), is whole in the window and her head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' head, 0 px covered, 0 hidden by the set (' + lines.join('; ') + ')', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // 9. ducha-body: whoever stands at ducha_dentro (abuela in moment 2, Luis in moment 4) shows his top 14 rows over the low wall (none hidden by the set, none covered), and the wall hides him below (the rows it hides are counted).
  //    The spec says "hidden below the shoulders": where the wall begins to hide him is reported, and the wall height that would hide him from the shoulders down (open point when it is not)
  {
    const bad = [], lines = [], open = [], SHW = E.SHOWER;
    const wallTop = G.OY + (SHW.v1 + .07) * 13 - SHW.wall * 22.5;                                   // the screen row of the low wall's top edge (its front face's top, v v1 + .07)
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.at !== 'ducha_dentro' || !l.who) continue;
        const top = Math.min(...l.px.map(p => p[1])), bot = Math.max(...l.px.map(p => p[1])), rows = bot - top + 1;
        const c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        let firstHid = null; for (let y = top; y <= bot && firstHid === null; y++) if (l.px.some(p => p[1] === y && p[2])) firstHid = y - top;
        const hidPx = l.px.filter(p => p[2]).length, hidRows = firstHid === null ? 0 : rows - firstHid;
        lines.push('m' + m + ' ' + l.s + ' ' + [l.sx, l.sy] + ': ' + rows + ' rows (' + top + ' to ' + bot + '), head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered; the wall hides ' + hidPx + ' px from sprite row ' + (firstHid === null ? 'none' : firstHid) + ' down (' + hidRows + ' rows of ' + rows + '); the shoulders are about row ' + SHOULDER_ROW);
        if (c.hid || c.cov) bad.push('moment ' + m + ': the head (the top ' + HEAD_ROWS + ' rows) of ' + l.s + ' at ducha_dentro: ' + c.hid + ' px hidden by the set, ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody'));
        if (!hidPx) bad.push('moment ' + m + ': the low wall hides none of ' + l.s + ' at ducha_dentro');
        if (firstHid === null || firstHid > SHOULDER_ROW) {
          const need = (G.OY + (SHW.v1 + .07) * 13 - (l.sy - (rows - SHOULDER_ROW))) / 22.5;           // the wall's z that puts its top edge on the shoulders' row
          open.push('OPEN POINT (a set number, not a spot of the spec): in moment ' + m + ' the low wall (z ' + SHW.wall + ' at v ' + SHW.v1 + ') hides ' + l.s + ' only from sprite row ' + (firstHid === null ? 'none' : firstHid) + ' down (' + hidRows + ' of ' + rows + ' rows: its top edge is on picture row ' + r2(wallTop) + ', his feet on row ' + l.sy + '), not below the shoulders (about row ' + SHOULDER_ROW + '); it would take a wall of z ' + r2(need) + ' for him at v .8, and no v of his behind the wall hides more than the wall\'s own height (z ' + SHW.wall + ' is ' + r2(SHW.wall * 22.5) + ' px)');
        }
      }
    }
    const o = add('ducha-body', bad, 'whoever stands at ducha_dentro (abuela m2, Luis m4) shows his top ' + HEAD_ROWS + ' rows over the low wall (0 px hidden, 0 covered) and the wall hides him below: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const l of open) o.lines.push('       ' + l);
    // Canelo in the shower: how much of him the wall hides (the spec says "hidden"; info)
    for (const m of MOMENTS) { const L = PV.inspect[m].layers, i = idxAt(L, 'ducha_perro'); if (i < 0) continue; const l = L[i], hid = l.px.filter(p => p[2]).length, pc = Math.round(100 * hid / l.px.length); o.lines.push('       ' + (pc < 50 ? 'OPEN POINT (the spec\'s description, not a check): ' : 'info, not a check: ') + 'm' + m + ' Canelo at ducha_perro ' + [l.sx, l.sy] + ' (uv ' + S.ducha_perro.uv + '): the wall hides ' + hid + ' of his ' + l.px.length + ' px (' + pc + '%); the spec says "Canelo in it: hidden"' + (pc < 50 ? '; at the spec\'s (' + (S.ducha_perro.spec || S.ducha_perro.uv) + ') he is hidden ' + (S.ducha_perro.moved ? 'about 70% but 8 px sideways and 4 px up-down from abuela (sprites-apart), and no spot of his inside the shower is 12 px below her' : '') : '')); }
  }

  // 10. fixtures-clear (moments 4 and 5): both taps, the mirror and the gauge are covered by nobody: no shown pixel of a person, the frog or a thing (the gauge's own bars excepted) lies in their boxes
  {
    const bad = [], lines = [], hints = [], boxes = [['llave_ducha', T.llave_ducha.box], ['llave_lavamanos', T.llave_lavamanos.box], ['espejo', T.espejo.box], ['calentador', T.calentador.box]];
    for (const m of [4, 5]) {
      const L = PV.inspect[m].layers, hits = [];
      for (const [i, l] of L.entries()) { if (l.group === 'barra') continue; for (const [n, b] of boxes) { const c = shownIn(L, i, b); if (c) hits.push([n, lname(l), c, i]); } }
      lines.push('m' + m + ': ' + (hits.length ? hits.map(h => h[1] + ' covers ' + h[0] + ' ' + h[2] + ' px').join(', ') : '0 px of the two taps, the mirror and the gauge covered by anyone'));
      for (const h of hits) { bad.push('moment ' + m + ': ' + h[1] + ' covers ' + h[2] + ' px of ' + h[0] + ' [' + T[h[0]].box + ']'); hints.push([m, h[3], h[1]]); }
    }
    const seen = new Set(), o = add('fixtures-clear', bad, 'in moments 4 and 5 the shower\'s tap [' + T.llave_ducha.box + '], the sink\'s tap [' + T.llave_lavamanos.box + '], the mirror [' + T.espejo.box + '] and the gauge [' + T.calentador.box + '] are covered by nobody: ' + lines.join('; '), [bad.length + ' covering(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { if (seen.has(m + at) || !S[at]) continue; seen.add(m + at); const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, boxes.map(b => b[1])); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + axisTxt(r, at)); }
  }

  // 11. shelf-things-clear (moments 6 and 7): the two things on the right shelf (cosa_a, cosa_b), the tube and the tiny brush are covered by nobody, hidden by nothing of the set, and stand on the sink's or the shelf's top
  {
    const bad = [], lines = [], hints = [];
    for (const m of [6, 7]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (!['cosa', 'tubo', 'cepillito'].includes(l.group)) continue;
        const c = coverOf(L, M, i, null), onTop = surf.includes(l.at);
        lines.push('m' + m + ' ' + l.at + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; on its top ' + (onTop ? 'yes' : 'NO'));
        if (c.cov || c.hid || c.out || !onTop) { bad.push('moment ' + m + ' ' + l.at + ' ' + S[l.at].screen + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture' + (onTop ? '' : '; not on a top')); for (const w of Object.keys(c.who)) if (S[w]) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('shelf-things-clear', bad, 'the two things on the right shelf (cosa_a, cosa_b: m6, m7), the tube (m6, m7) and the tiny brush (m6) are covered by nobody and stand on their tops: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + m + ' (' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // 12. towels-clear (moment 2): the two towels on the stool are covered by nobody and hidden by nothing of the set
  {
    const bad = [], lines = [], m = 2, L = PV.inspect[m].layers, M = planes(L);
    for (const [i, l] of L.entries()) {
      if (l.group !== 'toalla') continue;
      const c = coverOf(L, M, i, null), onTop = surf.includes(l.at);
      lines.push(l.at + ' ' + [l.sx, l.sy] + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; on the stool\'s top ' + (onTop ? 'yes' : 'NO'));
      if (c.cov || c.hid || c.out || !onTop) bad.push('moment 2 ' + l.at + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture' + (onTop ? '' : '; not on the stool\'s top'));
    }
    add('towels-clear', bad, 'in moment 2 the two towels (toalla_a, toalla_b) are covered by nobody, hidden by nothing, and stand on the stool\'s top: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 13. frog-shelf: the frog at repisa_coqui stands on the left shelf's top (spots-on-surface) and covers neither tap (no pixel of his in the two taps' boxes) in moments 4 to 7
  {
    const bad = [], lines = [], hints = [], taps = [T.llave_ducha.box, T.llave_lavamanos.box];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, i = idxAt(L, 'repisa_coqui'); if (i < 0) continue;
      const f = L[i], n1 = shownIn(L, i, taps[0]), n2 = shownIn(L, i, taps[1]), shown = f.px.filter(p => !p[2]), left = Math.min(...shown.map(p => p[0])), right = Math.max(...shown.map(p => p[0]));
      lines.push('m' + m + ': the frog\'s columns ' + left + ' to ' + right + ' (the shower\'s tap box [' + taps[0] + '], the sink\'s [' + taps[1] + ']): ' + n1 + ' px on the shower\'s tap, ' + n2 + ' on the sink\'s');
      if (n1 || n2) { bad.push('moment ' + m + ': the frog at repisa_coqui ' + [f.sx, f.sy] + ' covers ' + n1 + ' px of the shower\'s tap and ' + n2 + ' px of the sink\'s'); hints.push([m, i]); }
    }
    if (!surf.includes('repisa_coqui')) bad.push('the frog at repisa_coqui is not on the shelf\'s top');
    const o = add('frog-shelf', bad, 'the frog at repisa_coqui ' + S.repisa_coqui.screen + ' stands on the left shelf\'s top (z ' + S.repisa_coqui.uv[2] + ') and covers neither tap in moments 4 to 7: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i] of hints) { const M = PV.moment[m], r = await PV.nearestFree(M.set, M.layers, i, taps); o.lines.push('       nearest passing, moment ' + m + ' repisa_coqui ' + S.repisa_coqui.uv + ': ' + axisTxt(r, 'repisa_coqui')); }
  }

  // 14. frog-sink: the frog in the sink (moment 3) stands on the sink's top (spots-on-surface) and is whole (frog-seen: 0 px hidden, covered or outside)
  {
    const bad = [], m = 3, L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'lavamanos_coqui'), c = coverOf(L, M, i, null);
    if (c.hid || c.cov || c.out) bad.push('moment 3: the frog at lavamanos_coqui: ' + c.hid + ' px hidden by the set, ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.out + ' outside the picture');
    if (!surf.includes('lavamanos_coqui')) bad.push('the frog at lavamanos_coqui is not on the sink\'s top');
    add('frog-sink', bad, 'the frog at lavamanos_coqui ' + S.lavamanos_coqui.screen + ' (moment 3) stands on the sink\'s top (z ' + S.lavamanos_coqui.uv[2] + ') and is whole: ' + (L[i].px.length + L[i].out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' covered, ' + c.out + ' outside the picture', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 15. bars-in-gauge: the gauge's three bars as the preview draws them (moments 4 and 5) are the boxes of the sheet, inside the gauge's box
  {
    const bad = [], gb = T.calentador.box, lines = [];
    for (const m of [4, 5]) {
      const L = PV.inspect[m].layers, bars = L.filter(l => l.group === 'barra');
      if (bars.length !== 3) bad.push('moment ' + m + ': ' + bars.length + ' bars drawn, not 3');
      bars.forEach((l, k) => {
        const xs = l.px.map(p => p[0]), ys = l.px.map(p => p[1]), bb = [Math.min(...xs), Math.min(...ys), Math.max(...xs) - Math.min(...xs) + 1, Math.max(...ys) - Math.min(...ys) + 1], want = T.calentador.bars[k];
        if (bb.join() !== want.join()) bad.push('moment ' + m + ': bar ' + (k + 1) + ' is drawn at [' + bb + '], the sheet says [' + want + ']');
        if (!(bb[0] >= gb[0] && bb[1] >= gb[1] && bb[0] + bb[2] <= gb[0] + gb[2] && bb[1] + bb[3] <= gb[1] + gb[3])) bad.push('moment ' + m + ': bar ' + (k + 1) + ' [' + bb + '] is not inside the gauge\'s box [' + gb + ']');
        if (l.px.some(p => p[2])) bad.push('moment ' + m + ': bar ' + (k + 1) + ' is hidden by the set');
      });
      lines.push('m' + m + ': ' + bars.map(l => { const ys = l.px.map(p => p[1]); return 'y ' + Math.min(...ys) + ' to ' + Math.max(...ys); }).join(', '));
    }
    add('bars-in-gauge', bad, 'the gauge\'s three bars (' + SZ.barra.join(' x ') + ' px each, centred on the gauge, 3 px apart) are drawn at the sheet\'s boxes ' + JSON.stringify(T.calentador.bars) + ' inside the gauge\'s box [' + gb + '], whole (' + lines.join('; ') + ')', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // info: what the spec lists no check for (the soap, the shower's box, manos_luis, the tiny brush in moment 7), not checks
  {
    const lines = [];
    for (const m of [1, 2]) {
      const L = PV.inspect[m].layers, M = planes(L), i = L.findIndex(l => l.at === 'jabon'), c = coverOf(L, M, i, null);
      lines.push('m' + m + ' the soap ' + c.cov + ' of ' + c.tot + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : ''));
    }
    { const L = PV.inspect[1].layers, M = planes(L), li = idxAt(L, 'lavamanos1'), mb = T.manos_luis.box; lines.push('m1 manos_luis [' + mb + '] holds ' + shownIn(L, li, mb) + ' of Luis\'s shown px'); }
    // the tiny brush in moment 7 (the spec lists only the tube there; the extra check names both): what it would be, standing at cepillito
    { const m = 7, L = PV.inspect[m].layers, b = T.cepillito === 'sprite' ? S.cepillito.box : null; if (b) { const n = L.map((l, i) => [lname(l), shownIn(L, i, b)]).filter(a => a[1]); lines.push('m7 the tiny brush\'s box [' + b + '] is under ' + (n.map(a => a[0] + ' ' + a[1] + ' px').join(', ') || 'nobody') + ' (not drawn in moment 7: the spec\'s moment lists only the tube)'); } }
    for (const m of [2, 4]) { const L = PV.inspect[m].layers, i = idxAt(L, 'ducha_dentro'); if (i >= 0) lines.push('m' + m + ' the shower\'s box [' + T.ducha.box + '] holds ' + shownIn(L, i, T.ducha.box) + ' of ' + L[i].s + '\'s ' + L[i].px.length + ' px'); }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
