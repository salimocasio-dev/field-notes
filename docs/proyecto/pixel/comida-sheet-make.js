#!/usr/bin/env node
'use strict';
/* La comida's sheet (place 8, La fonda, scene 3): writes docs/proyecto/pixel/comida-sheet.json from comida-set.html and the design (the orchestrator's p8-spec, general rules and section "comida"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/comida-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 60 here). The table, its four chairs (E.SEATS), the mesera's station (low top, shelf, the four things' u),
   the serving table and the pot are read from the set (window.COMIDA.E), never typed again from the design. The pot's box is the set's own pixels (the set built once more with the pot
   moved away: the pixels that change are the pot's), and so is the check that the four chairs' seat tops are where the sheet puts them (the set built once more with the table's top made
   a sliver: the long table hides every seat's top in the real set).
   Nothing in this set sways: DEPTH.z is the baked depth.
   It loads the set in headless Chrome (comida-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (comida-preview.html, PREVIEW.silhouettes: today's makers in historia/engine.js and historia/escenas/kit.js, with the
   outfits of the stand-ins). The checks that say "covers" or "shows" read the PREVIEW's moments (comida-preview.html, PREVIEW.inspect and its queries): the sheet is written first
   without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with COMIDA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'comida-sheet.json');
const BASE = process.env.COMIDA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/comida-set.html';
const PREVIEW = BASE + '/docs/proyecto/pixel/comida-preview.html';
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

// the numbers of the design (p8-spec: the rules for every sheet, and "comida")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = .44, TOP_Z = .74;                         // a chair's seat top; the long table's, the station's and the serving table's low tops
const SZ = { platillo: [14, 8], jarra: [12, 18], vasos: [26, 10], cosa: [10, 12], sopa: [12, 8], tazon: [10, 8], platoPerro: [12, 8] };
const MOMENTS = [1, 2, 3, 4, 5];
const PART = { silla: 'mesa', mesa: 'mesa', estacion: 'auxiliar', repisa: 'auxiliar', servir: 'auxiliar' };     // the set's parts: the long table and its chairs are `mesa`, the station and the serving table are `auxiliar`

/* the spots: { name, uvz, kind, sil, sprites, who, what, on, seat, size, anchor, moved }
   kind: person (a character stands there), place (the frog's), thing (a small thing)
   sil: which drawing hangs there (the first of `sprites`: abuelaS, abueloS, luisS, carmenS = the family sitting; abuela, luis, carmen, senora, senor, joven, mesera, cocinero standing; coqui; perro) or null for a small thing
   sprites: every drawing that hangs there in some moment (the sheet's extents are their union)
   on: what it stands on above the ground: silla (a seat's top), mesa (the long table's top), estacion (the station's low top), repisa (its shelf's top), servir (the serving table's top)
   anchor (small things): bottom = its bottom middle on the point
   moved: [the spec's u, v] when a check moved this spot (the least distance that passes: v first, then u; never z) */
function defs(E) {
  const T = E.TABLE, TV = T.v, ST = E.STATION, SV = E.SERVE, SE = E.SEATS, L = [];
  const add = (name, uvz, kind, sil, who, what, more) => L.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const SILS = ['abuelaS', 'abueloS', 'luisS', 'carmenS'], WHO = ['adulto', 'adulto', 'nino', 'nino'], PERS = ['abuela', 'abuelo', 'Luis', 'Carmen'];
  SE.forEach(([u, v], k) => add('silla' + (k + 1), [r4(u), r4(v), SEAT_Z], 'person', SILS[k], WHO[k], PERS[k] + ' on chair ' + (k + 1) + ' of the long table, left to right (E.SEATS[' + k + '], z ' + SEAT_Z + ': the seat\'s top); she or he sits, hung by the lap', { on: 'silla', seat: k, sprites: [SILS[k]] }));
  add('mesa_coqui', [-1.2, r4(TV + .58), TOP_Z], 'place', 'coqui', 'coqui', 'the frog on the long table\'s near edge (z ' + TOP_Z + ')', { on: 'mesa', sprites: ['coqui'], moved: [-1.2, r4(TV + .45)] });             // moved v +.13 (the spec: TABLE.v + .45): sprites-apart against abuela and abuelo
  // story 90
  [-.2, .5, 1.2].forEach((u, i) => add('platillo' + (i + 1), [u, r4(TV + (i === 2 ? .43 : .4)), TOP_Z], 'thing', null, null, 'small plate ' + (i + 1) + ' (tostones, pineapple, red peppers) on the table in front of the frog: ' + SZ.platillo.join(' x ') + ' px, bottom middle on the point', Object.assign({ size: SZ.platillo, anchor: 'bottom', on: 'mesa' }, i === 2 ? { moved: [u, r4(TV + .4)] } : {})));      // platillo3: moved v +.03 (the spec: TABLE.v + .4): it covered 3 px of the glasses (table-things-clear)
  add('jarra', [.1, r4(TV - .15), TOP_Z], 'thing', null, null, 'the jar of lemonade in the middle of the table: ' + SZ.jarra.join(' x ') + ' px, bottom middle on the point', { size: SZ.jarra, anchor: 'bottom', on: 'mesa' });
  add('vasos', [.85, r4(TV - .15), TOP_Z], 'thing', null, null, 'the three glasses in a row beside the jar: ' + SZ.vasos.join(' x ') + ' px, bottom middle on the point', { size: SZ.vasos, anchor: 'bottom', on: 'mesa' });
  // story 91
  add('auxiliar_coqui', [ST.u, r4(ST.v + .1), TOP_Z], 'place', 'coqui', 'coqui', 'the frog on the mesera\'s station: its low top (z ' + TOP_Z + ')', { on: 'estacion', sprites: ['coqui'] });
  ['sal', 'azucar', 'hielo', 'servilletas'].forEach((n, i) => add(n, [ST.things[i], ST.sv, ST.shelf], 'thing', null, null, 'the ' + { sal: 'salt shaker', azucar: 'sugar bowl', hielo: 'ice bucket with tongs', servilletas: 'pile of napkins' }[n] + ' on the station\'s shelf (u ' + ST.things[i] + ', v ' + ST.sv + ', z ' + ST.shelf + ' = its top): ' + SZ.cosa.join(' x ') + ' px, bottom middle on the point', { size: SZ.cosa, anchor: 'bottom', on: 'repisa' }));
  [0, 1, 2].forEach(k => add('sopa' + (k + 1), [r4(SE[k][0]), r4(TV - .15), TOP_Z], 'thing', null, null, 'bowl of soup ' + (k + 1) + ' on the table in front of chair ' + (k + 1) + ': ' + SZ.sopa.join(' x ') + ' px, bottom middle on the point', { size: SZ.sopa, anchor: 'bottom', on: 'mesa' }));
  add('ensalada', [r4(SE[3][0]), r4(TV - .15), TOP_Z], 'thing', null, null, 'Carmen\'s salad on the table in front of chair 4: ' + SZ.sopa.join(' x ') + ' px (the spec says "same" as the bowls), bottom middle on the point', { size: SZ.sopa, anchor: 'bottom', on: 'mesa' });
  add('junto_mesa', [-2.35, r4(TV + .4), 0], 'person', 'mesera', 'adulto', 'the mesera at the long table\'s left end', { sprites: ['mesera'] });
  // story 92
  add('detras_olla', [-3.26, 1.3, 0], 'person', 'cocinero', 'adulto', 'the cocinero behind the big pot (behind the serving table)', { sprites: ['cocinero'], moved: [-3.25, 1.3] });             // moved u -.01 (the spec: -3.25): sprites-apart against the frog at servir_coqui
  add('servir_coqui', [-2.2, r4(SV.v + .2), TOP_Z], 'place', 'coqui', 'coqui', 'the frog on the serving table (z ' + TOP_Z + ')', { on: 'servir', sprites: ['coqui'] });
  add('tazon', [-3.68, r4(SV.v + .32), TOP_Z], 'thing', null, null, 'the frog\'s small bowl on the serving table: ' + SZ.tazon.join(' x ') + ' px, bottom middle on the point', { size: SZ.tazon, anchor: 'bottom', on: 'servir', moved: [-3.3, r4(SV.v + .32)] });   // moved u -.38 (the spec: -3.3): at -3.3 it is drawn over 64 px of the pot (line-whole); a v move cannot pass (it would have to leave the table's top, v 2.42)
  add('fila1', [-1.0, 1.96, 0], 'person', 'senora', 'adulto', 'the line in front of the pot, first place (the señora in 92\'s game, abuela in its opening: she holds out a plate towards the pot)', { sprites: ['senora', 'abuela'], moved: [-1.0, 2.0] });
  add('fila2', [0, 1.96, 0], 'person', 'joven', 'adulto', 'the line, second place (the joven; Luis in the opening)', { sprites: ['joven', 'luis'], moved: [0, 2.0] });
  add('fila3', [1.0, 1.96, 0], 'person', 'senor', 'adulto', 'the line, third place (the señor; Carmen in the opening)', { sprites: ['senor', 'carmen'], moved: [1.0, 2.0] });             // fila1 to fila3: moved v -.04 (the spec: 2.0): the chairs' back tops hid 1 or 2 px of the line's feet (line-feet)
  add('bajo_mesa', [-3.15, 3.6, 0], 'person', 'perro', 'perro', 'the fonda\'s dog (Canelo\'s drawing, sitting, as a stand-in) in front of the serving table, on the floor', { sprites: ['perro'] });
  add('plato_perro', [-2.2, 3.7, 0], 'thing', null, null, 'the dog\'s bowl on the floor: ' + SZ.platoPerro.join(' x ') + ' px, bottom middle on the point', { size: SZ.platoPerro, anchor: 'bottom' });
  return L;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0, spots-in-view, spots-on-surface, things-in-view, sprites-apart, frog-seen, on-seat, heads-clear, table-things-clear, shelf-things-clear, frog-station, line-whole, line-feet.
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  const sp = await browser.newPage();
  sp.on('pageerror', e => errs.push(String(e)));
  await sp.route(BASE + '/**', serve);
  const SIL = await silhouettes(sp);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(COMIDA.E)) if (typeof v !== 'function') o[k] = v;
    o.SEATS = COMIDA.E.SEATS.map(s => s.slice());
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const probes = await probeSets(browser, errs, G);
  const sheet = await make(G, proj, SIL, probes);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  probes.spotsPx = await spotPixels(page, sheet);
  const PV = await previewData(browser, errs);
  const results = await checks(sheet, G, SIL, probes, PV);
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

/* ---------- the sprites' silhouettes: [dx, dy] of each drawn pixel from the anchor column and the anchor row (dy -1 is the feet's row of a standing one): the preview's own makers ---------- */
async function silhouettes(sp) {
  await sp.goto(PREVIEW + '?nodraw=1&sil=1');
  await sp.evaluate(() => window.PREVIEW.done);
  return sp.evaluate(() => window.PREVIEW.silhouettes());
}

/* ---------- the preview's moments: comida-preview.html, read through PREVIEW.inspect (every layer of a moment: its id, its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREVIEW + '?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size) => { const [w, h] = size; return [sx - Math.floor(w / 2), sy - h, w, h]; };
// what a spot takes of the picture: columns [first, last] and rows [top, bottom] (a person: his sprite box, the feet's spot in the middle, joined with the drawn silhouettes of every drawing that hangs there; a small thing: its box)
function extentOf(s, SIL) {
  const [sx, sy] = s.screen;
  if (s.who) {
    let c0 = sx - WIDTH[s.who] / 2, c1 = sx + WIDTH[s.who] / 2 - 1, r0 = 1e9, r1 = -1e9;
    for (const k of s.sprites || []) { const b = SIL[k].box; c0 = Math.min(c0, sx + b[0]); c1 = Math.max(c1, sx + b[2]); r0 = Math.min(r0, sy + b[1]); r1 = Math.max(r1, sy + b[3]); }
    if (r0 > r1) { r0 = sy; r1 = sy; }
    return { cols: [c0, c1], rows: [r0, r1] };
  }
  if (s.box) return { cols: [s.box[0], s.box[0] + s.box[2] - 1], rows: [s.box[1], s.box[1] + s.box[3] - 1] };
  return { cols: [sx, sx], rows: [sy, sy] };
}
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0, SIL) {
  const [a, b] = extentOf(s, SIL).cols;
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL, probes) {
  const E = G.E, sc = G.scene, DEF = defs(E), ST = E.STATION, SV = E.SERVE, T = E.TABLE;
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.sprites) o.sprites = d.sprites;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.seat !== undefined) o.seat = d.seat;                                    // which chair of E.SEATS (0 to 3, left to right)
    if (d.moved) o.moved = d.moved;
    spots[d.name] = o;
  });

  /* ---- the view: x0 22 (the window centred on the picture) unless a spot is cut, then the x0 that holds them all ---- */
  const held = Object.entries(spots);
  const ext = held.map(([, s]) => extentOf(s, SIL).cols), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0, SIL))) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x, SIL), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [90, 91, 92], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 90, 91 and 92: the 196 x 216 window over the 240 x 216 picture. The spec: x0 ' + centred + ' (the window centred on the picture) unless a spot is cut. ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold every spot (a person with his sprite whole, a small thing with its box)' + (ok0.includes(centred) ? '; x0 ' + x0 + ' is the one nearest ' + centred : '; x0 ' + x0 + ' is the one nearest ' + centred) : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const things = {};
  {
    const b = probes.pot.box, pu = SV.pot[0], pv = SV.pot[1], pr_ = SV.pot[2], xy = (u, v) => [(u + v) / R2, (v - u) / R2];
    const corners = [[pu - pr_, pv - pr_], [pu + pr_, pv - pr_], [pu + pr_, pv + pr_], [pu - pr_, pv + pr_]].map(([u, v]) => xy(u, v));
    things.olla = { set: true, uv: W4([pu - pr_, pv - pr_, TOP_Z, pu + pr_, pv + pr_, 1.12]), world: W4([Math.min(...corners.map(c => c[0])), Math.min(...corners.map(c => c[1])), TOP_Z, Math.max(...corners.map(c => c[0])), Math.max(...corners.map(c => c[1])), 1.12]), box: b, pixels: probes.pot.n,
      what: 'the big pot on the serving table (E.SERVE.pot [' + SV.pot + ']: u, v, radius; z ' + TOP_Z + ' to 1.12, with its two handles at z 1.0 to 1.06): the screen box of the ' + probes.pot.n + ' pixels the set draws for it (the set built once more with the pot moved away: the pixels that change are the pot\'s). A poke' };
  }
  for (const k of ['platillo1', 'platillo2', 'platillo3', 'jarra', 'sal', 'azucar', 'hielo', 'servilletas', 'sopas', 'plato_perro', 'tazon', 'abuela', 'abuelo', 'luis', 'carmen', 'mesera', 'cocinero', 'senor', 'senora', 'joven', 'mujer', 'coqui', 'perro']) things[k] = 'sprite';

  return {
    scene: 'comida',
    made: 'node docs/proyecto/pixel/comida-sheet-make.js, from comida-set.html (window.COMIDA.E) and the design of La comida (the orchestrator\'s p8-spec, general rules and section comida). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), z up; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '. The rail is at v ' + E.RAIL.v + '; the long table is at u ' + T.u + ', v ' + T.v + ' (half-width ' + T.hw + ', half-depth ' + T.hd + '); the four chairs along its far side are E.SEATS: ' + G.E.SEATS.map(s => '(' + r4(s[0]) + ', ' + r4(s[1]) + ')').join(', ') + ' (seat top z ' + SEAT_Z + '; the table\'s top z ' + TOP_Z + ')',
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + SEAT_Z + ': a chair\'s seat top; z ' + TOP_Z + ': the long table\'s, the station\'s low or the serving table\'s top; z ' + ST.shelf + ': the station\'s shelf) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): its bottom middle is on the spot. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), 41 for a child; abuela standing mkAbuela (48 x 51): column 30 (her middle), her feet on the bottom edge; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41, t 7 a child: 33) on (sx, sy); the dog mkPerro(\'sit\') (30 x 22): column 15 and its bottom edge; a small thing: see spot. Nobody is drawn turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      seat: 'whoever sits at the long table sits along its far side, facing us, hung by the lap on the seat\'s top (z ' + SEAT_Z + '); the table\'s top (z ' + TOP_Z + ') is nearer the camera than the seat and hides whoever sits from about the waist down (the set\'s depth hides them: check on-seat, heads-clear)',
      olla: 'olla: the pot\'s box on the picture [' + probes.pot.box + '] (' + probes.pot.n + ' pixels, from the set\'s own pixels; its handles included): the cocinero stands behind it (detras_olla) and the serving table\'s top hides his body below the table\'s far edge',
    },
    setKey: {
      params: { hora: { values: ['noche'], note: 'one state: the lights along the rail, the lamps on the tables. Stories 90, 91 and 92 use it' } },
      key: 'hora, e.g. "noche"',
      used: ['noche'],
      baked: ['?hora=noche'],
    },
    things,
    spots,
    groups: { sillas: ['silla1', 'silla2', 'silla3', 'silla4'], platillos: ['platillo1', 'platillo2', 'platillo3'], estacion: ['sal', 'azucar', 'hielo', 'servilletas'], sopas: ['sopa1', 'sopa2', 'sopa3'], fila: ['fila1', 'fila2', 'fila3'], mesa: ['mesa_coqui', 'platillo1', 'platillo2', 'platillo3', 'jarra', 'vasos', 'sopa1', 'sopa2', 'sopa3', 'ensalada'] },
    notes: [
      'every number of a spot is the orchestrator\'s (the p8-spec, "comida"), given in (u, v, z); the table, its chairs (E.SEATS), the station (u, v, shelf, sv, things), the serving table and the pot are read from the set (window.COMIDA.E); a spot marked `moved` was moved by a check, the least distance that passes (v first, then u; never z), and carries the spec\'s u, v',
      'platillo1 to platillo3 are the three small plates in front of the frog (tostones, pineapple, red peppers: their order is drawn each round); jarra and vasos are the jar of lemonade and the three glasses (vasos is one box, 26 x 10, the three glasses in a row); sopa1 to sopa3 are the bowls in front of chairs 1 to 3 and ensalada is Carmen\'s plate in front of chair 4 (the spec gives it the bowls\' 12 x 8)',
      'sal, azucar, hielo and servilletas stand on the station\'s shelf at E.STATION.things (u ' + ST.things.join(', ') + '), v ' + ST.sv + ', z ' + ST.shelf + '; the frog stands on the station\'s low top (z ' + TOP_Z + ') at auxiliar_coqui',
      'olla is the only thing of the set: the pot on the serving table, its box from the set\'s own pixels; the dog\'s bowl (plato_perro), the frog\'s small bowl (tazon) and every person are sprites',
      'fila1 holds out a plate towards the pot: the spec gives no size for it and no spot, so the previews draw nobody holding it',
      'bajo_mesa (-3.15, 3.6) is the spec\'s name for the dog\'s place: it is on the floor in front of the serving table (v 3.6; the serving table is at v ' + SV.v + '), not under it',
      'the views\'s x0: x0 22 when every spot is inside the window (a person with his sprite whole, a small thing with its box); here ' + (x0 === centred ? 'x0 22 holds them all' : 'x0 ' + x0 + ' is the only one that holds them all (x0 ' + (ok0.length ? ok0[0] + ' to ' + ok0[ok0.length - 1] : 'none') + '): the moved tazon\'s box begins at column ' + spots.tazon.box[0] + ' and the servilletas\' ends at column ' + (spots.servilletas.box[0] + spots.servilletas.box[2] - 1) + ' (check views-x0)'),
      'tazon was moved from u -3.3 to u -3.68: at -3.3 its box is drawn over 64 px of the pot; the serving table\'s top ends at u ' + r4(SV.u - SV.hw) + ' (column ' + r2(G.OX + (SV.u - SV.hw) * G.S) + '), so the 10 px bowl (box columns ' + spots.tazon.box[0] + ' to ' + (spots.tazon.box[0] + 9) + ') hangs about ' + Math.max(0, Math.round(G.OX + (SV.u - SV.hw) * G.S - spots.tazon.box[0])) + ' px over the table\'s left end: its point is on the top, its box is not wholly (open point)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the long table and its chairs, the station, the serving table and the pot hide whoever is behind them. Nothing in this set sways.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El cruce\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, mesera: .35, cocinero: .35, senor: .35, senora: .35, joven: .35, mujer: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on a chair or stands on a table (z above 0) casts none: neither is ground (a shadow cast at the floor under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
// the set built more than once in a fresh page: the pot's pixels (the set with the pot moved away), the four seats' tops (the set with the long table's top a sliver: in the real set the table hides them)
async function probeSets(browser, errs, G) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('probe: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PAGE + '?tags=1');
  const r = await p.evaluate(() => {
    const E = COMIDA.E, W_ = W, H_ = H, full = Float32Array.from(bakedZ), tags = Array.from(TAGS, t => t || ''), keep = E.SERVE.pot.slice(), hw = E.TABLE.hw;
    E.SERVE.pot = [60, 60, keep[2]]; COMIDA.buildSet();
    const idx = []; let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
    for (let i = 0; i < W_ * H_; i++) if (full[i] !== bakedZ[i]) { idx.push(i); const x = i % W_, y = Math.floor(i / W_); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    E.SERVE.pot = keep; E.TABLE.hw = .01; COMIDA.buildSet();
    const seats = Float32Array.from(bakedZ), seatTags = Array.from(TAGS, t => t || '');
    return { idx, box: idx.length ? [x0, y0, x1 - x0 + 1, y1 - y0 + 1] : null, tags, seats: Array.from(seats), seatTags, hw };
  });
  await p.close();
  return { pot: { idx: r.idx, n: r.idx.length, box: r.box }, tags: r.tags, seatZ: r.seats, seatTags: r.seatTags };
}
// the spots' pixels: what the set drew at each spot's feet (the baked depth and the part), in the real set
async function spotPixels(page, sheet) {
  return page.evaluate(arg => {
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
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, TB = E.TABLE, ST = E.STATION, SV = E.SERVE;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them. hid: hidden by the set
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, cov = 0; const who = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2]) { hid++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].id; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const idxAt = (L, id) => L.findIndex(l => l.id === id);
  const axisTxt = (r, at) => ['u', 'v'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ') + '; z never';
  const potSet = new Set(probes.pot.idx);

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box); x0 22 unless a spot is cut
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0, SIL)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const at22 = v.holds.map(k => [k, cutAt(S[k], 22, SIL)]).filter(o => o[1]);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + '; at x0 22: ' + (at22.length ? at22.map(a => a[0] + ' cut by ' + a[1] + ' px').join(', ') : 'no spot is cut'), [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, the dog 28; joined with his drawn silhouettes; a small thing's box)
  {
    const bad = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, e = extentOf(s, SIL), [a, b] = e.cols, [top, bottom] = e.rows;
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
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = JSON.parse(JSON.stringify(s)); t.screen = [sx, s.screen[1]]; if (t.box) t.box[0] += sx - s.screen[0]; const c = extentOf(t, SIL).cols; if (!cutAt(t, x0, SIL) && c[0] >= 0 && c[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const ex = names.map(k => [k, extentOf(S[k], SIL)]), left = ex.reduce((a, b) => b[1].cols[0] < a[1].cols[0] ? b : a), right = ex.reduce((a, b) => b[1].cols[1] > a[1].cols[1] ? b : a), topmost = ex.reduce((a, b) => b[1].rows[0] < a[1].rows[0] ? b : a), lowest = ex.reduce((a, b) => b[1].rows[1] > a[1].rows[1] ? b : a);
    add('spots-in-view', bad, names.length + ' spots (persons with their sprites, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + left[1].cols[0] + ' (' + left[0] + '), the rightmost ' + right[1].cols[1] + ' (' + right[0] + '); the highest row ' + topmost[1].rows[0] + ' (' + topmost[0] + '), the lowest ' + lowest[1].rows[1] + ' (' + lowest[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
  }

  // 3. the spots above the ground are on what the set draws: a chair's seat top, the long table's top, the station's low top, its shelf's top, the serving table's top. Two readings: where the set puts that surface (E: the seat box, the table's
  //    rectangle, the station's, the shelf's, the serving table's, at the spot's z), and the set's own pixel at the spot (part mesa or auxiliar, depth within .1 of the spot's). In the real set the long table is nearer than the chairs and hides each seat's top
  //    (the set's pixel at a chair spot is the table: a nearer depth): for the chairs the set is read once more with the table's top a sliver (probes.seatZ): the seat's own pixel there.
  {
    const bad = [], lines = [], px = probes.spotsPx, eq = (a, b) => Math.abs(a - b) < 1e-6, SE = E.SEATS;
    const geo = (k, s) => {
      const [u, v, z] = s.uv, e = 1e-9;
      if (s.on === 'silla') { const c = SE[s.seat]; return Math.abs(u - c[0]) <= .2 + e && Math.abs(v - c[1]) <= .2 + e && eq(z, SEAT_Z) ? 'the seat\'s top (u ' + r4(c[0] - .2) + ' to ' + r4(c[0] + .2) + ', v ' + r4(c[1] - .2) + ' to ' + r4(c[1] + .2) + ', z ' + SEAT_Z + ')' : null; }
      if (s.on === 'mesa') return Math.abs(u - TB.u) <= TB.hw + e && Math.abs(v - TB.v) <= TB.hd + e && eq(z, TOP_Z) ? 'the long table\'s top (u ' + r4(TB.u - TB.hw) + ' to ' + r4(TB.u + TB.hw) + ', v ' + r4(TB.v - TB.hd) + ' to ' + r4(TB.v + TB.hd) + ', z ' + TOP_Z + ')' : null;
      if (s.on === 'estacion') return Math.abs(u - ST.u) <= ST.hw + e && Math.abs(v - ST.v) <= ST.hd + e && eq(z, TOP_Z) ? 'the station\'s low top (u ' + r4(ST.u - ST.hw) + ' to ' + r4(ST.u + ST.hw) + ', v ' + r4(ST.v - ST.hd) + ' to ' + r4(ST.v + ST.hd) + ', z ' + TOP_Z + ')' : null;
      if (s.on === 'repisa') return Math.abs(u - ST.u) <= ST.hw + e && Math.abs(v - ST.sv) <= .12 + e && eq(z, ST.shelf) ? 'the shelf\'s top (u ' + r4(ST.u - ST.hw) + ' to ' + r4(ST.u + ST.hw) + ', v ' + r4(ST.sv - .12) + ' to ' + r4(ST.sv + .12) + ', z ' + ST.shelf + ')' : null;
      if (s.on === 'servir') return Math.abs(u - SV.u) <= SV.hw + e && Math.abs(v - SV.v) <= SV.hd + e && eq(z, TOP_Z) ? 'the serving table\'s top (u ' + r4(SV.u - SV.hw) + ' to ' + r4(SV.u + SV.hw) + ', v ' + r4(SV.v - SV.hd) + ' to ' + r4(SV.v + SV.hd) + ', z ' + TOP_Z + ')' : null;
      return null;
    };
    let hiddenSeats = 0;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground') continue;
      const want = PART[s.on], real = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && Math.abs(r.dy) <= 1).map(r => ({ r, dz: r.z - s.depth })).sort((a, b) => Math.abs(a.dz) - Math.abs(b.dz))[0];
      let near = real, note = '';
      if (s.on === 'silla') {                                                                                    // the seat's own pixel: the set with the table's top a sliver
        const cand = []; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const X = s.screen[0] + dx, Y = s.screen[1] + dy, i = Y * G.W + X; cand.push({ r: { dx, dy, tag: probes.seatTags[i], z: probes.seatZ[i] }, dz: probes.seatZ[i] - s.depth }); }
        near = cand.sort((a, b) => Math.abs(a.dz) - Math.abs(b.dz))[0];
        if (real && real.dz >= .1) { hiddenSeats++; note = '; in the real set the table is in front of it (the pixel there is part ' + real.r.tag + ' at depth ' + r2(real.r.z) + ')'; }
      }
      const seen = near && near.r.tag === want && Math.abs(near.dz) < .1, hidden = near && near.dz >= .1 && s.on !== 'silla';
      const g = geo(k, s);
      lines.push(k + ' z ' + s.uv[2] + ': ' + (g ? 'inside ' + g + '; ' : 'NOT on a set surface; ') + 'the set\'s pixel' + (s.on === 'silla' ? ' (table\'s top a sliver)' : '') + ' ' + (near ? 'part ' + near.r.tag + ', depth ' + r2(near.r.z) + ' against the spot\'s ' + r2(s.depth) + (seen ? ' (' + r2(Math.abs(near.dz)) + ')' : hidden ? ': nearer: something of the set is in front of the spot' : ': farther') : 'none') + note);
      if (!g) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + s.uv + ')');
      else if (!seen) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ': the set\'s pixel there is ' + (near ? 'part ' + near.r.tag + ' at depth ' + r2(near.r.z) + ', the spot\'s is ' + r2(s.depth) : 'none'));
    }
    const o = add('spots-on-surface', bad, lines.length + ' spots above the ground are on a surface the set draws (a seat\'s top z ' + SEAT_Z + ', the long table\'s, the station\'s low and the serving table\'s top z ' + TOP_Z + ', the shelf\'s top z ' + ST.shelf + '); the set\'s own pixel at each (part mesa or auxiliar, depth within .1 of the spot\'s) agrees; for the 4 chairs the set was read with the table\'s top a sliver (' + hiddenSeats + ' of them are hidden by the table in the real set)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the set things' boxes are inside the picture and the window; the pot's pixels are where E.SERVE puts it
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    const pq = scrUV(G, SV.pot[0], SV.pot[1], 1.12), b = T.olla.box;
    if (!(pq[0] >= b[0] && pq[0] < b[0] + b[2] && pq[1] >= b[1] && pq[1] < b[1] + b[3])) bad.push('olla box [' + b + '] does not hold the pot\'s top middle ' + pq + ' (E.SERVE.pot [' + SV.pot + '], z 1.12)');
    add('things-in-view', bad, 'the box of olla [' + b + '] (' + T.olla.pixels + ' px of the set, the pot and its handles: it holds the pot\'s top middle ' + pq + ') is inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture; every other touch key is a sprite', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.id, b: b.id, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.id + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.id + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.id).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 5 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 5 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.id + ' ~ ' + h.b.id + ': ' + h.a.id + ' (' + h.a.at + ') ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.id + ' (' + h.b.at + ') ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person, a thing or the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; for (const b of M.get(key(x, y)) || []) if (b.i !== fi && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) { boxCov++; break; } }
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 5 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].id + ' (' + specs[fi].at + ') ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. on-seat: whoever sits at the table sits on a seat's top: each of the four is at z .44, the seat's top (the set's own pixel is part mesa, as spots-on-surface reads it), and hung by the lap on the spot's row
  {
    const bad = [], lines = [], sils = ['abuelaS', 'abueloS', 'luisS', 'carmenS'];
    for (const k of [0, 1, 2, 3]) {
      const n = 'silla' + (k + 1), s = S[n], seat = E.SEATS[k];
      if (s.uv[2] !== SEAT_Z) bad.push(n + ' z ' + s.uv[2] + ' is not the seat\'s top ' + SEAT_Z);
      if (Math.abs(s.uv[0] - seat[0]) > 1e-3 || Math.abs(s.uv[1] - seat[1]) > 1e-3) bad.push(n + ' [' + s.uv + '] is not E.SEATS[' + k + '] [' + r4(seat[0]) + ', ' + r4(seat[1]) + ']');
      const near = [-1, 0, 1].flatMap(dy => [-1, 0, 1].map(dx => { const i = (s.screen[1] + dy) * G.W + s.screen[0] + dx; return { tag: probes.seatTags[i], dz: probes.seatZ[i] - s.depth }; })).sort((a, b) => Math.abs(a.dz) - Math.abs(b.dz))[0];
      if (near.tag !== 'mesa' || Math.abs(near.dz) >= .1) bad.push(n + ' ' + s.screen + ': the set\'s pixel under the spot is part ' + near.tag + ' at ' + r2(near.dz) + ' from the spot\'s depth: not the seat\'s top');
      for (const m of [1, 2, 3]) {
        const L = PV.inspect[m].layers, l = L[idxAt(L, ['abuela', 'abuelo', 'luis', 'carmen'][k])];
        if (l.sy !== s.screen[1] || l.ay !== SIL[sils[k]].ay) bad.push('moment ' + m + ' ' + l.id + ' is not hung by the lap: drawn on row ' + l.sy + ', its lap row ' + l.ay + ' of the sprite (should be ' + SIL[sils[k]].ay + ' on ' + s.screen[1] + ')');
      }
      lines.push(n + ' ' + s.screen + ' ' + ['abuela', 'abuelo', 'Luis', 'Carmen'][k] + ': z ' + s.uv[2] + ', the seat\'s pixel part ' + near.tag + ' at ' + r2(Math.abs(near.dz)) + '; the sprite hangs by its lap row ' + SIL[sils[k]].ay + ' on row ' + s.screen[1] + ' (feet ' + (SIL[sils[k]].box[3] + 1) + ' rows below it, behind the table)');
    }
    add('on-seat', bad, 'the four at the long table sit on the seats\' tops (z ' + SEAT_Z + ', E.SEATS), the set\'s own pixel under each spot is part mesa at the seat\'s depth, and each sprite hangs by its lap row on the spot\'s row: ' + lines.join('; '), ['not on the seats:'].concat(bad.map(b => '  ' + b)));
  }

  // 8. heads-clear: the head (the top 14 rows of the sprite) of each of the four who sit at the table is covered by nobody and by nothing of the set, in moments 1, 2 and 3 (and they are whole in the window)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [1, 2, 3]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'silla') continue;
        const [a, b] = extentOf(S[l.at], SIL).cols, cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]), body = coverOf(L, M, i, null);
        lines.push('m' + m + ' ' + l.id + ' ' + [l.sx, l.sy] + ': window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture; head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; the whole sprite: ' + body.cov + ' under a nearer sprite, ' + body.hid + ' hidden by the set (the table)');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.id + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.id + ' ' + [l.sx, l.sy] + ': ' + c.cov + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.id, w]); }
      }
    }
    const o = add('heads-clear', bad, 'the four at the table (abuela, abuelo, Luis, Carmen) are whole in the window and their heads (the top ' + HEAD_ROWS + ' rows) are covered by nobody and by nothing of the set in moments 1, 2 and 3: ' + lines.join('; '), [bad.length + ' problem(s) with the people at the table:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tid, cid] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tid + ' covered by ' + cid + '): ' + cid + ' (' + M.layers[ci].at + ') ' + S[M.layers[ci].at].uv + ': ' + axisTxt(r, M.layers[ci].at)); }
  }

  // 9. table-things-clear: in moment 1 the three small plates, the jar and the glasses are covered by nobody (and not hidden by the set); they stand on the table's top (spots-on-surface)
  {
    const bad = [], lines = [], hints = [], L = PV.inspect[1].layers, M = planes(L);
    for (const id of ['platillo1', 'platillo2', 'platillo3', 'jarra', 'vasos']) {
      const ci = idxAt(L, id), c = coverOf(L, M, ci, null);
      lines.push(id + ' ' + S[id].box + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set');
      if (c.cov || c.hid || c.out) { bad.push('moment 1 ' + id + ' [' + S[id].box + ']: ' + c.cov + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture'); for (const w of Object.keys(c.who)) hints.push([ci, idxAt(L, w), id, w]); }
    }
    const o = add('table-things-clear', bad, 'in moment 1 the small plates, the jar and the glasses are covered by nobody and not hidden by the set: ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [ti, ci, tid, cid] of hints) { const Mo = PV.moment[1], r = await PV.nearestClear(Mo.set, Mo.layers, ci, [ti], null); o.lines.push('       nearest passing (' + tid + ' covered by ' + cid + '): ' + cid + ' (' + Mo.layers[ci].at + ') ' + S[Mo.layers[ci].at].uv + ': ' + axisTxt(r, Mo.layers[ci].at)); }
    const L3 = PV.inspect[3].layers, M3 = planes(L3), inf = ['sopa1', 'sopa2', 'sopa3', 'ensalada'].map(id => { const c = coverOf(L3, M3, idxAt(L3, id), null); return id + ' ' + c.cov + ' covered, ' + c.hid + ' hidden'; });
    o.lines.push('       info, not a check: moment 3\'s bowls and salad: ' + inf.join('; '));
  }

  // 10. shelf-things-clear: in moments 2 and 3 the four things on the station's shelf are covered by nobody (the frog included) and not hidden by the set; they stand on the shelf's top (spots-on-surface)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [2, 3]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const id of ['sal', 'azucar', 'hielo', 'servilletas']) {
        const ci = idxAt(L, id), c = coverOf(L, M, ci, null);
        lines.push('m' + m + ' ' + id + ' ' + S[id].box + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set');
        if (c.cov || c.hid || c.out) { bad.push('moment ' + m + ' ' + id + ' [' + S[id].box + ']: ' + c.cov + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture'); for (const w of Object.keys(c.who)) hints.push([m, ci, idxAt(L, w), id, w]); }
      }
    }
    const o = add('shelf-things-clear', bad, 'the salt, the sugar, the ice and the napkins are covered by nobody and not hidden by the set in moments 2 and 3 (they stand on the shelf\'s top z ' + ST.shelf + '): ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ti, ci, tid, cid] of hints) { const Mo = PV.moment[m], r = await PV.nearestClear(Mo.set, Mo.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + m + ' (' + tid + ' covered by ' + cid + '): ' + cid + ' (' + Mo.layers[ci].at + ') ' + S[Mo.layers[ci].at].uv + ': ' + axisTxt(r, Mo.layers[ci].at)); }
  }

  // 11. frog-station: the frog at auxiliar_coqui stands on the station's low top (spots-on-surface: z .74 on part auxiliar) and his top row is below the four things' bottom row (moments 2 and 3)
  {
    const bad = [], lines = [];
    for (const m of [2, 3]) {
      const L = PV.inspect[m].layers, fi = idxAt(L, 'coqui'), f = L[fi], shown = f.px.filter(p => !p[2]), top = Math.min(...shown.map(p => p[1]));
      const things = ['sal', 'azucar', 'hielo', 'servilletas'].map(id => [id, S[id].box]), bottomRow = Math.max(...things.map(([, b]) => b[1] + b[3] - 1)), gap = top - bottomRow - 1;
      const hit = things.filter(([, b]) => shown.some(p => inside(b, p[0], p[1]))).map(([id]) => id);
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': his top row ' + top + ', the things\' bottom row ' + bottomRow + ' (rows ' + Math.min(...things.map(([, b]) => b[1])) + ' to ' + bottomRow + '): ' + gap + ' rows clear' + (hit.length ? '; he is inside the box of ' + hit.join(', ') : ''));
      if (gap < 0 || hit.length) bad.push('moment ' + m + ': the frog at auxiliar_coqui [' + f.sx + ', ' + f.sy + ']: his top row ' + top + ' is not below the things\' bottom row ' + bottomRow + ' (' + gap + ' rows clear)' + (hit.length ? '; he draws inside the box of ' + hit.join(', ') : ''));
    }
    const s = S.auxiliar_coqui;
    add('frog-station', bad, 'the frog at auxiliar_coqui ' + s.screen + ' (z ' + s.uv[2] + ' = the station\'s low top, part auxiliar: spots-on-surface) has his top row below the four things\' bottom row: ' + lines.join('; '), ['the frog and the shelf:'].concat(bad.map(b => '  ' + b)));
  }

  // 12. line-whole: in moments 4 and 5 the pot, the dog's bowl and the person at fila1 are whole (the three things he can touch): nobody (the frog, the cocinero, the line, the dog) draws over the pot's pixels; the bowl is covered by nobody and not hidden by the set;
  //     the person at fila1 is covered by nobody and not hidden by the set. The frog covers no part of the pot
  {
    const bad = [], lines = [], hints = [], potHints = [];
    for (const m of [4, 5]) {
      const L = PV.inspect[m].layers, M = planes(L), over = {};
      let n = 0;
      for (const l of L) for (const p of l.px) if (!p[2] && potSet.has(key(p[0], p[1]))) { over[l.id] = (over[l.id] || 0) + 1; n++; }
      const ci = idxAt(L, 'cocinero'), cp = L[ci].px.filter(p => p[2] && potSet.has(key(p[0], p[1]))).length, chidden = L[ci].px.filter(p => p[2]).length;
      const bi = idxAt(L, 'plato_perro'), bc = coverOf(L, M, bi, null), f1 = L.findIndex(l => l.at === 'fila1'), pc = coverOf(L, M, f1, null), fi = idxAt(L, 'coqui');
      lines.push('m' + m + ': pot [' + T.olla.box + '] (' + potSet.size + ' px): ' + n + ' px drawn over by sprites' + (n ? ' (' + Object.entries(over).map(([k, v]) => k + ' ' + v).join(', ') + ')' : '') + ', the frog ' + (over.coqui || 0) + ' (his columns ' + (L[fi].sx - 16) + ' to ' + (L[fi].sx + 15) + ', the pot\'s ' + T.olla.box[0] + ' to ' + (T.olla.box[0] + T.olla.box[2] - 1) + '); the dog\'s bowl ' + S.plato_perro.box + ': ' + bc.cov + ' covered' + (bc.cov ? ' by ' + whoTxt(bc) : '') + ', ' + bc.hid + ' hidden by the set; ' + L[f1].id + ' at fila1 ' + [L[f1].sx, L[f1].sy] + ': ' + pc.tot + ' px, ' + pc.cov + ' covered' + (pc.cov ? ' by ' + whoTxt(pc) : '') + ', ' + pc.hid + ' hidden by the set, ' + pc.out + ' outside the picture; (the cocinero behind the pot: the pot and the table hide ' + cp + ' of his px, ' + chidden + ' hidden in all)');
      if (n) { bad.push('moment ' + m + ': ' + n + ' px of sprites are drawn over the pot (' + Object.entries(over).map(([k, v]) => k + ' ' + v).join(', ') + ')'); for (const k of Object.keys(over)) potHints.push([m, k]); }
      if (bc.cov || bc.hid || bc.out) { bad.push('moment ' + m + ': the dog\'s bowl [' + S.plato_perro.box + ']: ' + bc.cov + ' px covered' + (bc.cov ? ' by ' + whoTxt(bc) : '') + ', ' + bc.hid + ' hidden by the set'); for (const w of Object.keys(bc.who)) hints.push([m, bi, idxAt(L, w), 'the dog\'s bowl', w]); }
      if (pc.cov || pc.hid || pc.out) { bad.push('moment ' + m + ': the person at fila1 (' + L[f1].id + ') ' + [L[f1].sx, L[f1].sy] + ': ' + pc.cov + ' px covered' + (pc.cov ? ' by ' + whoTxt(pc) : '') + ', ' + pc.hid + ' hidden by the set, ' + pc.out + ' outside the picture'); for (const w of Object.keys(pc.who)) hints.push([m, f1, idxAt(L, w), L[f1].id + ' at fila1', w]); }
    }
    const o = add('line-whole', bad, 'in moments 4 and 5 the pot (' + potSet.size + ' px), the dog\'s bowl and the person at fila1 are whole: no sprite is drawn over the pot (the frog covers none of it), the bowl and the person are covered by nobody and not hidden by the set: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ti, ci, tid, cid] of hints) { const Mo = PV.moment[m], r = await PV.nearestClear(Mo.set, Mo.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + m + ' (' + tid + ' covered by ' + cid + '): ' + cid + ' (' + Mo.layers[ci].at + ') ' + S[Mo.layers[ci].at].uv + ': ' + axisTxt(r, Mo.layers[ci].at)); }
    for (const [m, id] of potHints) {                                                                          // the least shift of the layer that draws over no pot pixel and over no nearer-hidden sprite pixel (v and u, steps of .01)
      const Mo = PV.moment[m], ti = Mo.layers.findIndex(l => l.id === id), at = Mo.layers[ti].at, st = S[at].uv, found = {};
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let k = 1; k <= 150 && !found[lab]; k++) for (const sg of [1, -1]) {
        const uvz = st.slice(); uvz[ax] = r4(uvz[ax] + sg * k * .01);
        const L = await PV.layers(Mo.set, Mo.layers.map((l, i) => i === ti ? Object.assign({}, l, { at: null, uvz, off: null }) : l)), t = L[ti], top = new Map();
        L.forEach((l, i) => { if (i !== ti) for (const p of l.px) if (!p[2]) top.set(key(p[0], p[1]), Math.max(top.get(key(p[0], p[1])) || -1e9, p[3])); });
        const bd = t.px.filter(p => !p[2] && (potSet.has(key(p[0], p[1])) || (top.has(key(p[0], p[1])) && p[3] > top.get(key(p[0], p[1])) + EPS))).length + t.px.filter(p => p[2]).length + t.out;
        if (!bd) { found[lab] = lab + ' ' + st[ax] + ' -> ' + uvz[ax] + ' (' + sgn(sg * k * .01) + ')'; break; }
      }
      o.lines.push('       nearest passing, moment ' + m + ' (' + id + ' drawn over the pot, or over a sprite): ' + id + ' (' + at + ') ' + st + ': ' + (found.v || 'v: none within 1.5') + '; or ' + (found.u || 'u: none within 1.5') + '; z never');
    }
  }

  // 13. line-feet: in moments 4 and 5 the feet of the line (the bottom 8 rows of each of fila1 to fila3) are not behind the long table's chairs: no pixel of them is hidden by the set; the whole sprites' hidden pixels are reported by part
  {
    const bad = [], lines = [], hints = [];
    for (const m of [4, 5]) {
      const L = PV.inspect[m].layers;
      for (const l of L.filter(l => l.group === 'fila')) {
        const bottom = Math.max(...l.px.map(p => p[1])), feet = l.px.filter(p => p[1] > bottom - 8), hidFeet = feet.filter(p => p[2]), hid = l.px.filter(p => p[2]), parts = {};
        for (const p of hid) { const t = probes.tags[key(p[0], p[1])] || '(sky)'; parts[t] = (parts[t] || 0) + 1; }
        lines.push('m' + m + ' ' + l.id + ' ' + [l.sx, l.sy] + ': feet rows ' + (bottom - 7) + ' to ' + bottom + ' (' + feet.length + ' px), ' + hidFeet.length + ' hidden by the set; the whole sprite ' + hid.length + ' hidden' + (hid.length ? ' (' + Object.entries(parts).map(([k, v]) => 'part ' + k + ' ' + v).join(', ') + ')' : ''));
        if (hidFeet.length) { bad.push('moment ' + m + ' ' + l.id + ' at ' + l.at + ' ' + [l.sx, l.sy] + ': ' + hidFeet.length + ' px of its feet are hidden by the set'); hints.push([m, l.id]); }
      }
    }
    // where the chairs' backs are, on the picture, against the line's feet
    const chairTop = Math.min(...E.SEATS.map(s => scrUV(G, s[0], s[1] - .18, 1.08)[1])), chairCols = E.SEATS.map(s => scrUV(G, s[0], s[1], 0)[0]);
    const o = add('line-feet', bad, 'the feet of the line (the bottom 8 rows of fila1 to fila3) are not hidden by the set in moments 4 and 5; the chairs\' backs begin at row ' + chairTop + ' (columns ' + chairCols.join(', ') + ' +-5) and the line\'s feet are at row ' + S.fila1.screen[1] + ': ' + lines.join('; '), ['the line\'s feet are behind the set:'].concat(bad.map(b => '  ' + b)));
    for (const [m, id] of hints) { const Mo = PV.moment[m], ci = Mo.layers.findIndex(l => l.id === id), r = await PV.nearest(Mo.set, Mo.layers, ci); o.lines.push('       nearest passing, moment ' + m + ' (' + id + ' behind the set): ' + id + ' (' + Mo.layers[ci].at + ') ' + S[Mo.layers[ci].at].uv + ': ' + axisTxt(r, Mo.layers[ci].at)); }
  }

  // info: how the people and the stand-ins touch each other (not checks of the spec: findings of its numbers)
  {
    const lines = [], L1 = PV.inspect[1].layers, M1 = planes(L1), fi1 = idxAt(L1, 'coqui');
    const byFrog = ['abuela', 'abuelo', 'luis', 'carmen'].map(id => { const c = coverOf(L1, M1, idxAt(L1, id), [fi1]); return id + ' ' + c.cov; });
    lines.push('moment 1: the frog at mesa_coqui ' + S.mesa_coqui.screen + ' covers, of the family\'s px: ' + byFrog.join(', ') + ' (heads are checked in heads-clear)');
    const L2 = PV.inspect[2].layers, M2 = planes(L2), mi = idxAt(L2, 'mesera');
    lines.push('moment 2: the mesera at junto_mesa ' + S.junto_mesa.screen + ': ' + coverOf(L2, M2, mi, null).hid + ' of her ' + L2[mi].px.length + ' px hidden by the set; her columns ' + (S.junto_mesa.screen[0] - 12) + ' to ' + (S.junto_mesa.screen[0] + 11) + ', the long table\'s left edge is at column ' + scrUV(G, TB.u - TB.hw, TB.v, 0)[0]);
    const L4 = PV.inspect[4].layers, M4 = planes(L4), ci = idxAt(L4, 'cocinero'), c4 = coverOf(L4, M4, ci, null), head = coverOf(L4, M4, ci, null, [0, HEAD_ROWS]);
    lines.push('moment 4: the cocinero at detras_olla ' + S.detras_olla.screen + ' stands behind the serving table and the pot: ' + c4.hid + ' of his ' + c4.tot + ' px are hidden by the set (rows ' + Math.min(...L4[ci].px.filter(p => p[2]).map(p => p[1])) + ' to ' + Math.max(...L4[ci].px.filter(p => p[2]).map(p => p[1])) + '), his head (rows ' + head.top + ' to ' + (head.top + HEAD_ROWS - 1) + ') ' + head.hid + ' hidden; the frog\'s box and his overlap ' + Math.max(0, (S.detras_olla.screen[0] + 12) - (S.servir_coqui.screen[0] - 16)) + ' columns, their feet are ' + Math.abs(S.detras_olla.screen[1] - S.servir_coqui.screen[1]) + ' px apart up-down');
    OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check, findings of the spec\'s numbers:'].concat(lines.map(l => '       ' + l)) });
  }

  return OUTS;
}
