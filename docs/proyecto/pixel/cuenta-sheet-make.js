#!/usr/bin/env node
'use strict';
/* La cuenta's sheet: writes docs/proyecto/pixel/cuenta-sheet.json from cuenta-set.html and the design (the orchestrator's p8-spec, section "cuenta"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/cuenta-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene (place 8, La fonda, scene 4; stories 93, 94, 95): no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z),
   u across the picture, v down it (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S. The set's numbers (the counter, the register, the machine's and the jar's u, the frog's u, the table's seats, the next table, the window,
   the door) are read from the set (window.CUENTA.E), never typed again from the design.
   It loads the set in headless Chrome (cuenta-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth rule.
   The checks that say "covers" or "shows" read the PREVIEW's moments (cuenta-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it,
   and then the sheet is written again with the checks. The window's lamps and the guagua's lights are found by re-baking the set with the window's picture marked (the set's own street()).
   Then it prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CUENTA_BASE), but every request to it is answered from the files of THIS tree
   (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'cuenta-sheet.json');
const BASE = process.env.CUENTA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/cuenta-set.html';
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
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, T30 = Math.tan(Math.PI / 6);

// the numbers of the design (p8-spec: the rules for every sheet, and "cuenta")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
// "from the waist up" / "from the chest up": the top rows of the sprite (the spec gives the words, not the rows: open point). A grown-up's ink is 53 rows (torso centre at canvas row 29, hips at 38): the waist is the top of the hips, the
// chest the torso's centre; a child's (41 rows, t 7) are 8 rows less
const UP = { waist: { adulto: 35, nino: 27 }, chest: { adulto: 29, nino: 25 } };
const SEAT_Z = .44;                                      // a seat's top
const CART = { w: 76, h: 22, z: .8 };                    // the dessert cart: a sprite 76 x 22, its top is z .8 (18 px above its feet)
const SIZE = { copa: [8, 10], flanes: [14, 8], mantecado: [12, 10], tapa: [12, 10], maquina: [12, 10], frasco: [10, 12], carrito: [CART.w, CART.h] };   // the stand-ins' sizes (p8-spec)
const CUENTA_SLIP = [8, 10];                             // a slip in a hand: no spot of its own
const MOMENTS = [1, 2, 3, 4, 5, 6, 7];
const STATES = [];
for (const guagua of ['no', 'lejos', 'medio', 'cerca']) for (const sillas of ['abajo', 'arriba']) STATES.push({ guagua, sillas });

/* the moves: where one of the spec's numbers failed a check, the spot moved the least distance that passes (v first, then u; never z): name -> [du, dv, why] added to the spec's (u, v) */
const MOVED = {
  familia1: [-.01, 0, 'sprites-apart, moment 3: abuela at familia1 and Luis at familia3 were 23 px apart sideways (boxes need 24) with their feet 5 px apart up-down. The least move is u -.01 (u +.02 on familia3, or v -.49 on familia1 / +.5 on familia3, also pass)'],
  caja: [0, -.42, 'waist-up, moments 3, 4, 7: at v .45 the register hid her from the first row of her torso (row 47 on the picture, her top 35 rows are rows 18 to 52): 92 px of her waist-up hidden. Moving her back to v .03 (against the wall) puts the waist above the register\'s top (u would have to move 2.9 or more, out from behind the register)'],
  cocina: [0, -.34, 'chest-up, moments 5 and 7: at v .45 the glass case (its top is row 43) hid 12 px of the cocinero\'s right hand and arm in the top 29 rows. v -.34 passes; the u move (-.11) would cut his sprite by 3 px at the window\'s left edge (x0 22)'],
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor }
   kind: person (a character stands there), place (the frog's), thing (a small thing: its box)
   sil: which drawing hangs there (a key of the preview's PREVIEW.boxes: adulto = a standing grown-up, nino = a child, abuelaS / adultoS / ninoS = sitting, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle */
function defs(E) {
  const C = E.COUNTER, H = C.h, D = [], N = E.NEXT, tv = E.TABLE.v, shift = [r4(.2 - 1.45), r4(9.6 - 6.1)];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const SIT = ['abuelaS', 'adultoS', 'ninoS', 'ninoS'], WHO = ['adulto', 'adulto', 'nino', 'nino'], FAMILY = ['abuela', 'abuelo', 'Luis', 'Carmen'];
  E.SEATS.forEach(([u, v], i) => add('silla' + (i + 1), [r4(u), r4(v), SEAT_Z], 'person', SIT[i], WHO[i], FAMILY[i] + '\'s chair at the long table (the far side, left to right: abuela, abuelo, Luis, Carmen): on its seat\'s top, z ' + SEAT_Z + '; whoever sits is hung by the lap', { on: 'mesas', fixed: 1 }));
  add('mostrador_coqui', [E.FROG, 1.25, H], 'place', 'coqui', 'coqui', 'the frog on the counter\'s top (z ' + H + ', v 1.25), left of the register', { on: 'mostrador' });
  add('maquina', [E.MACHINE, 1.3, H], 'thing', null, null, 'the card machine on the counter\'s top: a ' + SIZE.maquina.join(' x ') + ' px stand-in, its bottom middle on the point', { size: SIZE.maquina, anchor: 'bottom', on: 'mostrador' });
  add('frasco', [E.JAR, 1.3, H], 'thing', null, null, 'the glass jar on the counter\'s top: a ' + SIZE.frasco.join(' x ') + ' px stand-in, its bottom middle on the point', { size: SIZE.frasco, anchor: 'bottom', on: 'mostrador' });
  add('caja', [E.REG.u, .45, 0], 'person', 'adulto', 'adulto', 'the mesera behind the register (behind the counter: seen from the waist up)');
  add('paga', [1.9, 2.5, 0], 'person', 'adulto', 'adulto', 'whoever pays: in front of the register, to the right of the machine and the jar');
  add('fila1', [2.75, 3.6, 0], 'person', 'adulto', 'adulto', 'the line behind the one who pays: first');
  add('fila2', [3.3, 4.8, 0], 'person', 'adulto', 'adulto', 'the line behind the one who pays: second');
  add('familia1', [-2.9, 2.6, 0], 'person', 'adulto', 'adulto', 'abuela standing in front of the counter (story 94 opening)');
  add('familia3', [-2.0, 3.0, 0], 'person', 'nino', 'nino', 'Luis standing in front of the counter (story 94 opening)');
  add('familia4', [-1.05, 3.0, 0], 'person', 'nino', 'nino', 'Carmen standing in front of the counter (story 94 opening)');
  // story 93: the dessert cart (a sprite 76 x 22, its top z .8) and what is on it, beside the family's table, then at the next table (the same five places, shifted)
  const cart = (s, mv, c0) => {
    const [du, dv] = mv;
    add('carrito' + s, [r4(1.45 + du), r4(6.1 + dv), 0], 'thing', null, null, 'the dessert cart' + (s ? ' at the next table' : ' beside the family\'s table') + ' (its middle): a sprite ' + CART.w + ' x ' + CART.h + ', its top (z ' + CART.z + ') ' + Math.round(CART.z * 22.5) + ' px above its feet', { size: SIZE.carrito, anchor: 'bottom', cart: 1 });
    add('carrito_coqui' + s, [r4(.65 + du), r4(6.1 + dv), CART.z], 'place', 'coqui', 'coqui', 'the frog on the cart\'s top (z ' + CART.z + ')', { on: 'carrito' });
    add('copa' + s, [r4(1.45 + du), r4(6.1 + dv), CART.z], 'thing', null, null, 'the frog\'s small cup on the cart\'s top: ' + SIZE.copa.join(' x ') + ', bottom middle on the point', { size: SIZE.copa, anchor: 'bottom', on: 'carrito' });
    add('flanes' + s, [r4(1.95 + du), r4(6.1 + dv), CART.z], 'thing', null, null, 'the flans on the cart\'s top: ' + SIZE.flanes.join(' x ') + ', bottom middle on the point', { size: SIZE.flanes, anchor: 'bottom', on: 'carrito' });
    add('mantecado' + s, [r4(2.5 + du), r4(6.1 + dv), CART.z], 'thing', null, null, 'the tub of ice cream on the cart\'s top: ' + SIZE.mantecado.join(' x ') + ', bottom middle on the point', { size: SIZE.mantecado, anchor: 'bottom', on: 'carrito' });
    add('tapa' + s, [r4(2.95 + du), r4(6.1 + dv), .5], 'thing', null, null, 'the domed cover hanging at the cart\'s right side (z .5): ' + SIZE.tapa.join(' x ') + ', its top middle on the point (open point: the spec gives the point, not where it hangs from)', { size: SIZE.tapa, anchor: 'top', on: 'carrito' });
  };
  cart('', [.2, 0]);                                                 // the cart stands .2 further right than the spec said, so that the frog on its top is clear of Carmen at silla4
  add('mesera93', [2.3, 5.3, 0], 'person', 'adulto', 'adulto', 'the mesera behind the cart (the next row back), pushing it');
  cart('2', shift);
  add('mesera93b', [-1.75, 9.3, 0], 'person', 'adulto', 'adulto', 'the mesera with the cart at the next table (to its left)');
  E.NEXTSEATS.forEach((p, i) => add('otra_mesa' + (i + 1), [r4(p[0]), r4(p[1]), SEAT_Z], 'person', 'adultoS', 'adulto', 'a chair of the next table (NEXT u ' + N.u + ', v ' + N.v + '; the far side, ' + (i ? 'right' : 'left') + '): what FD.setTable returned for it, its seat\'s top z ' + SEAT_Z + ' (the spec\'s u NEXT.u -/+ .45, v NEXT.v - .45 - .26 worked out the way FD.setTable does, read from the set)', { on: 'mesas', fixed: 1 }));
  // story 95
  add('junto_mesa', [.75, 5.2, 0], 'person', 'adulto', 'adulto', 'the mesero beside the family\'s table (at its right end)');
  add('cocina', [-3.3, .45, 0], 'person', 'adulto', 'adulto', 'the cocinero in the kitchen\'s door (seen from the chest up at least)');
  add('sillas_mesera', [1.3, 9.6, 0], 'person', 'adulto', 'adulto', 'the mesera putting the chairs up at the next table (to its left)');
  [[2.37, .5, 'adulto', 'abuela'], [3.3, .5, 'adulto', 'abuelo'], [2.37, 1.5, 'nino', 'Luis'], [3.3, 1.5, 'nino', 'Carmen']].forEach(([u, v, who, name], i) => add('umbral' + (i + 1), [u, v, 0], 'person', who, who, name + ' waiting in the doorway'));
  add('puerta_coqui', [2.85, 2.6, 0], 'place', 'coqui', 'coqui', 'the frog on the floor just inside the door');
  add('sale', [2.85, 1.0, 0], 'person', 'adulto', 'adulto', 'a guest going out through the door, past the family');
  for (const d of D) if (MOVED[d.name]) { d.from = d.uvz.slice(); d.moved = MOVED[d.name]; d.uvz = [r4(d.uvz[0] + MOVED[d.name][0]), r4(d.uvz[1] + MOVED[d.name][1]), d.uvz[2]]; }
  return D;
}

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => ({ E: CUENTA.E, scene: PP_SCENE, W, H, S, OX, OY }));
  // a second copy of the set: the tables are drawn again with FD.setTable wrapped to keep what it returns (the chairs' places of every table: the set's own numbers, E.SEATS is the first),
  // then a lone chair is drawn at (0, 8) to read the depth of its seat's top (in the picture the table is in front of every chair's seat: the set's pixel under a sitter's spot is the table's)
  const pp = await browser.newPage();
  pp.on('pageerror', e => errs.push(String(e)));
  await pp.route(BASE + '/**', serve);
  await pp.goto(PAGE + '?tags=1');
  G.tables = await pp.evaluate(() => {
    const calls = [], orig = FD.setTable; FD.setTable = (...a) => { const r = orig(...a); calls.push({ u: a[0], v: a[1], hw: a[2], opt: a[3], seats: r }); return r; };
    zb.fill(-1e9); pix.fill(0); part('mesas', tables); FD.setTable = orig;
    zb.fill(-1e9); pix.fill(0); part('probe', () => FD.chair(0, 8));
    const sx = Math.round(OX), sy = Math.round(OY + 8 * .5 * S - .44 * Math.sqrt(3) / 2 * S), d = 8 * Math.sqrt(3) / 2 + .44 * .5;
    return { calls, chair: { sx, sy, d, z: zb[sy * W + sx] } };
  });
  await pp.close();
  G.E.NEXTSEATS = G.tables.calls[1].seats;
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet);
  const lights = await windowProbe(browser, errs, G);
  const PV = await previewData(browser, errs);
  const results = await checks(sheet, G, probes, PV, lights);
  sheet.checks = { results: results.map(r => ({ name: r.name, ok: r.ok, lines: r.lines })) };
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

/* ---------- the preview's moments: cuenta-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/cuenta-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.boxes = await p.evaluate(() => window.PREVIEW.boxes());
  PV.cartRow = row => p.evaluate(r => window.PREVIEW.cartRow(r), row);
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  return PV;
}

/* ---------- the window's lamps and the guagua's lights: the set re-baked with the window's picture marked (the set's own street(): a lamp's pole and head, the guagua's body and lights) ---------- */
async function windowProbe(browser, errs, G) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('window: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PAGE);
  const res = await p.evaluate(() => {
    const orig = window.street, mag = rgb(255, 0, 255);
    const LAMP = [rgb(96, 96, 110), rgb(255, 236, 150)], GUA = [rgb(255, 250, 190), rgb(150, 190, 220), rgb(70, 130, 180)];
    const out = { lamps: {}, guagua: {} };
    const marked = set => { const o = []; window.street = (a, b) => { const c = orig(a, b); return set.includes(c) ? mag : c; }; buildSet(); for (let i = 0; i < W * H; i++) { const c = bakedPix[i], r = c & 255, g = c >> 8 & 255, bl = c >> 16 & 255; if (r > g + 100 && bl > g + 100) o.push(i); } return o; };
    for (const st of ['no', 'lejos', 'medio', 'cerca']) { SET.guagua = st; out.lamps[st] = marked(LAMP); out.guagua[st] = st === 'no' ? [] : marked(GUA); }
    window.street = orig;
    return out;
  });
  await p.close();
  return res;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : sy - h, w, h];
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
  const E = G.E, sc = G.scene, DEF = defs(E), C = E.COUNTER, H = C.h, vm = (C.v0 + C.v1) / 2, hd = (C.v1 - C.v0) / 2;
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';                                  // what it stands on above the ground: a part of the set (the seat, the counter) or the cart's top
    if (d.fixed) o.fixed = 1;
    if (d.moved) o.moved = { from: W4(d.from), by: [d.moved[0], d.moved[1]], why: d.moved[2] };
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
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [93, 94, 95], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 93, 94 and 95: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment is inside it (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- the set's things he can touch (and the parts the checks use) ---- */
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
  const things = {}, parts = {}, R = E.REG, W = E.WINDOW, Dr = E.DOOR;
  things.gaveta = await setThing(r4(R.u - R.hw), r4(C.v1 - .08), H, r4(R.u + R.hw), r4(C.v1 - .08), r4(H + .13), 'the register\'s drawer: the lower part of its front (the set draws it dark with a brass pull), from the register\'s left edge to its right (u ' + r4(R.u - R.hw) + ' to ' + r4(R.u + R.hw) + ') and from the counter\'s top to .13 above it (z ' + H + ' to ' + r4(H + .13) + '), on the plane v ' + r4(C.v1 - .08) + ' (the register\'s front: COUNTER.v1 - .08); a poke');
  things.mentas = await setThing(r4(E.MINTS - .13), r4(vm - .13), H, r4(E.MINTS + .13), r4(vm + .13), r4(H + .08), 'the bowl of mints on the counter\'s top: the set\'s drum (u ' + E.MINTS + ', v ' + vm + ', radius .13, z ' + H + ' to ' + r4(H + .08) + '), its bounding box; a poke');
  things.ventana = await setThing(W[0], 0, W[2], W[1], 0, W[3], 'the window on the street (the wall\'s hole at v 0: u ' + W[0] + ' to ' + W[1] + ', z ' + W[2] + ' to ' + W[3] + '), without its frame; a poke');
  things.puerta = await setThing(Dr[0], 0, Dr[2], Dr[1], 0, Dr[3], 'the open door to the street (the wall\'s hole at v 0: u ' + Dr[0] + ' to ' + Dr[1] + ', z ' + Dr[2] + ' to ' + Dr[3] + '), without its frame; a poke');
  parts.vitrina = await setThing(E.CASE[0], r4(vm - (hd - .04)), H, E.CASE[1], r4(vm + (hd - .04)), r4(H + .56), 'the glass case of desserts on the counter (not a touch key: the frog must not cover it): u ' + E.CASE[0] + ' to ' + E.CASE[1] + ', v ' + r4(vm - (hd - .04)) + ' to ' + r4(vm + (hd - .04)) + ', z ' + H + ' to ' + r4(H + .56));
  parts.pincho = await setThing(r4(E.SPIKE - .07), r4(vm - .09), H, r4(E.SPIKE + .07), r4(vm + .09), r4(H + .3), 'the spike of slips on the counter (not a touch key: the frog must not cover it): its base, paper and post, u ' + r4(E.SPIKE - .07) + ' to ' + r4(E.SPIKE + .07) + ', z ' + H + ' to ' + r4(H + .3));
  for (const k of ['flanes', 'mantecado', 'tapa', 'copa', 'cuenta', 'maquina', 'frasco', 'mesera', 'mesero', 'cocinero', 'abuela', 'abuelo', 'luis', 'carmen', 'senor', 'senora', 'joven', 'mujer', 'coqui']) things[k] = 'sprite';

  const shiftU = r4(spots.carrito2.uv[0] - spots.carrito.uv[0]), shiftV = r4(spots.carrito2.uv[1] - spots.carrito.uv[1]);
  return {
    scene: 'cuenta',
    made: 'node docs/proyecto/pixel/cuenta-sheet-make.js, from cuenta-set.html (window.CUENTA.E) and the design of La cuenta (the orchestrator\'s p8-spec, section cuenta). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the back wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + H + ': the counter\'s top; z ' + SEAT_Z + ': a seat\'s top; z ' + CART.z + ': the cart\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the cup, the flans, the tub, the machine and the jar have their bottom middle on the spot; the cover (tapa) hangs: its top middle on the spot (z .5, at the cart\'s right side); the cart has its bottom middle on the spot (its feet) and its top surface ' + Math.round(CART.z * 22.5) + ' px above that. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), 41 for a child; abuela standing (engine.js mkAbuela, 48 x 51): column 30 (her middle); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a grown-up or a child sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy); a small thing: see spot. Whoever sits at the table sits on the far side facing the camera: no sprite is turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      cart: 'the dessert cart is a sprite ' + CART.w + ' x ' + CART.h + ' with its feet (bottom middle) on carrito (carrito2 at the next table): its top surface is z ' + CART.z + ', ' + Math.round(CART.z * 22.5) + ' px above its feet, so the things that stand on it have their spot at z ' + CART.z + ' and their bottom edge on the cart\'s top surface (canvas row ' + (CART.h - Math.round(CART.z * 22.5)) + ' of the sprite is the first row below them). The same five places at the next table are the first five shifted by (u ' + sgn(shiftU) + ', v ' + sgn(shiftV) + ')',
      counter: 'things stand on the counter\'s top at z ' + H + ', v 1.2 to 1.3 (the top spans v ' + C.v0 + ' to ' + C.v1 + '); whoever serves stands behind it at v .45 and is hidden below the counter\'s far edge (and below the register) by the depth rule, as the set draws them',
      waist: 'the spec says "whole from the waist up" and "whole from the chest up" without rows: the top ' + UP.waist.adulto + ' rows of a grown-up\'s sprite (' + UP.waist.nino + ' of a child\'s) are the waist up, the top ' + UP.chest.adulto + ' (' + UP.chest.nino + ') the chest up (a grown-up\'s hips are canvas rows 35 to 41, the torso\'s centre is row 29; the head is the top ' + HEAD_ROWS + ' rows)',
    },
    setKey: {
      params: { hora: { values: ['noche'], note: 'always night' }, guagua: { values: ['no', 'lejos', 'medio', 'cerca'], note: 'the guagua\'s lights in the window: none (93, 94, 95 opening), under the far lamp, under the middle lamp, under the near lamp' }, sillas: { values: ['abajo', 'arriba'], note: 'the next table\'s chairs on the floor, or up on the table (closing time: 95)' } },
      key: 'guagua + sillas, e.g. "no-abajo"',
      baked: STATES.map(s => '?guagua=' + s.guagua + '&sillas=' + s.sillas),
    },
    things,
    parts,
    spots,
    groups: {
      sillas: ['silla1', 'silla2', 'silla3', 'silla4'], otra_mesa: ['otra_mesa1', 'otra_mesa2'], fila: ['paga', 'fila1', 'fila2'], familia: ['familia1', 'familia3', 'familia4'], umbral: ['umbral1', 'umbral2', 'umbral3', 'umbral4'],
      carrito: ['carrito', 'carrito_coqui', 'copa', 'flanes', 'mantecado', 'tapa'], carrito2: ['carrito2', 'carrito_coqui2', 'copa2', 'flanes2', 'mantecado2', 'tapa2'],
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p8-spec, "cuenta"), given in (u, v, z); the counter\'s, the register\'s, the machine\'s, the jar\'s, the frog\'s, the table\'s and the next table\'s numbers are read from the set (E)' + (DEF.some(d => d.moved) ? '; the spots that failed a check and were moved the least distance that passes are marked "moved" (from, by)' : ''),
      'silla1 to silla4 are the long table\'s chairs, left to right (abuela, abuelo, Luis, Carmen), read from E.SEATS; otra_mesa1 and otra_mesa2 are the next table\'s two chairs, worked out as FD.setTable does',
      'carrito2, carrito_coqui2, copa2, flanes2, mantecado2 and tapa2 are the cart\'s places at the next table: the first six shifted by (u ' + sgn(shiftU) + ', v ' + sgn(shiftV) + ')',
      'gaveta is the register\'s drawer, its box from the set\'s own front (the dark lower part of the register: z ' + H + ' to ' + r4(H + .13) + ' at v ' + r4(C.v1 - .08) + '); mentas is the bowl of mints\' bounding box; ventana and puerta are the holes of the back wall (without their frames); vitrina and pincho in parts are the dessert case and the spike of slips: not touch keys, the frog must not cover them',
      'cuenta (a slip, ' + CUENTA_SLIP.join(' x ') + ') has no spot: the spec gives it as a thing in a hand; it is a sprite carried by whoever holds it',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the counter, the register and the glass case hide whoever stands behind them from the counter\'s top down, the table hides the lower body of whoever sits at it.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El calendario\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn (the things on the cart, and the frog on it, are a tie with the cart: they are drawn after it)',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, mesera: .35, mesero: .35, cocinero: .35, senor: .35, senora: .35, joven: .35, mujer: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El calendario\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits at a table, stands on the counter or on the cart (z above 0) casts none: none of them is ground (a shadow cast at the floor under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part), in the base state (guagua no, sillas abajo; the depth does not change with the guagua)
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
  // the tags inside each set thing's box (the drawer must be the counter's own pixels)
  const boxTags = await page.evaluate(arg => {
    const o = {};
    for (const [k, b] of Object.entries(arg)) { const t = {}; for (let y = b[1]; y < b[1] + b[3]; y++) for (let x = b[0]; x < b[0] + b[2]; x++) { const g = TAGS[y * W + x] || 'ground'; t[g] = (t[g] || 0) + 1; } o[k] = t; }
    return o;
  }, Object.fromEntries([...Object.entries(sheet.things).filter(([, t]) => t !== 'sprite'), ...Object.entries(sheet.parts)].map(([k, t]) => [k, t.box])));
  return { spotsPx, boxTags };
}

/* ---------- the moment-level rules: each takes { m, L } (the layers of a moment as the preview packs them) and returns the issues it finds ---------- */
const key = (x, y) => y * 240 + x;
const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
// is shown pixel b (layer i, plane) in front of pixel p of layer t? the nearer plane wins, a tie (within EPS) goes to the later layer (as the picture is drawn)
const nearer = (b, p, t) => b.plane > p[3] + EPS || (b.plane >= p[3] - EPS && b.i > t);
// the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them
function coverOf(L, M, t, by, rows) {
  const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, cov = 0; const who = {};
  for (const p of l.px) {
    if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
    tot++; if (p[2]) { hid++; continue; }
    let best = null;
    for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && nearer(b, p, t) && (!best || b.plane > best.plane)) best = b;
    if (best) { cov++; const a = L[best.i].at; who[a] = (who[a] || 0) + 1; }
  }
  return { tot, hid, cov, who, out: l.out, top };
}
const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
// the shown pixels of any layer but `skip` inside a box: { layer at: count }
function shownInBox(L, box, skip) {
  const who = {}; let n = 0;
  L.forEach((l, i) => { if (skip.includes(i)) return; let c = 0; for (const p of l.px) if (!p[2] && inside(box, p[0], p[1])) c++; if (c) { who[l.at] = c; n += c; } });
  return { n, who };
}
const idxAt = (L, at) => L.findIndex(l => l.at === at);

// where the make looks for a layer's thing: the things that must stay free
const FREE = { 1: ['copa', 'flanes', 'mantecado', 'tapa'], 2: ['copa2', 'flanes2', 'mantecado2', 'tapa2'], 3: ['maquina', 'frasco', 'gaveta'], 4: ['maquina', 'frasco', 'gaveta'], 6: ['maquina', 'frasco', 'gaveta'] };
const WAIST = { 1: ['mesera93'], 2: ['mesera93b'], 3: ['caja'], 4: ['caja'], 7: ['caja'] };
const CHEST = { 2: ['otra_mesa1', 'otra_mesa2'], 5: ['cocina'], 7: ['cocina'] };
const HEADS = { 1: ['mesa'], 2: ['mesa', 'otra'], 5: ['mesa'] };
const COUNTER_FROG = [3, 4, 5, 6];

function rulesOf(ctx) {
  const { S, T, parts, lights, G, x0 } = ctx, R = {};
  const box = n => S[n] ? S[n].box : T[n].box;
  // sprites-apart: the people who stand together do not overlap sideways unless their feet are 12 px or more apart up-down
  R['sprites-apart'] = ({ m, L }) => {
    const P = L.filter(l => l.who), out = [];
    for (let i = 0; i < P.length; i++) for (let j = i + 1; j < P.length; j++) {
      const a = P[i], b = P[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy);
      if (dx < half && dy < UPDOWN) out.push({ m, ats: [a.at, b.at], text: 'moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down' });
    }
    return out;
  };
  // frog-seen: no pixel of the frog is hidden by the set, outside the picture or under a nearer sprite
  R['frog-seen'] = ({ m, L }) => {
    const fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, planes(L), fi, null);
    return c.hid || c.cov || f.out ? [{ m, ats: [f.at, ...Object.keys(c.who)], text: 'moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)' }] : [];
  };
  // heads-clear: the head (the top 14 rows) of everyone who sits at a table is covered by nobody and by nothing
  R['heads-clear'] = ({ m, L }) => {
    const out = [], M = planes(L);
    L.forEach((l, i) => {
      if (!l.group || !(HEADS[m] || []).includes(l.group)) return;
      const c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
      if (c.cov || c.hid || l.out) out.push({ m, ats: [l.at, ...Object.keys(c.who)], text: 'moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') ' + c.cov + ' are covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + l.out + ' outside the picture' });
    });
    return out;
  };
  // waist-up / chest-up: the top rows of the sprite are whole (none hidden by the set or under a nearer sprite or outside the picture); the chest-up people are also whole in the window
  const upRule = (name, TAB, rows, cut) => ({ m, L }) => {
    const out = [], M = planes(L);
    for (const at of TAB[m] || []) {
      const i = idxAt(L, at), l = L[i], n = UP[rows][l.who], c = coverOf(L, M, i, null, [0, n]), [a, b] = colsOf(S[at]), cutN = cut ? Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195)) : 0;
      if (c.cov || c.hid || c.out || cutN) out.push({ m, ats: [at, ...Object.keys(c.who)], text: 'moment ' + m + ' ' + at + ' ' + [l.sx, l.sy] + ': of the top ' + n + ' rows (' + rows + ' up; rows ' + c.top + ' to ' + (c.top + n - 1) + ') ' + c.hid + ' are hidden by the set' + (c.hid ? ' (the first hidden row ' + Math.min(...l.px.filter(p => p[2] && p[1] < c.top + n).map(p => p[1])) + ')' : '') + ', ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + c.out + ' outside the picture' + (cutN ? ', ' + cutN + ' px cut by the window' : '') });
    }
    return out;
  };
  R['waist-up'] = upRule('waist-up', WAIST, 'waist', false);
  R['chest-up'] = upRule('chest-up', CHEST, 'chest', true);
  // things-free: the things he can touch are covered by nobody in the moments where it matters: no shown pixel of another layer lies in the thing's box nearer than the thing (its plane: the upright plane through its spot; a tie
  // goes to the later layer, as drawn); the drawer is the set's own front: any shown pixel in its box is over it. On the cart the frog covers none of the four things (he is drawn after them, on the same plane)
  R['things-free'] = ({ m, L }) => {
    const out = [];
    for (const at of FREE[m] || []) {
      const b = box(at), own = idxAt(L, at), sp = S[at], cart = L.map((l, i) => (l.id === 'carrito' ? i : -1)).filter(i => i >= 0), skip = [own, ...(sp && sp.on === 'carrito' ? cart : [])];
      const tp = row => sp.depth + (sp.screen[1] - (row + .5)) * T30 / G.S, who = {}; let n = 0;
      L.forEach((l, i) => {
        if (skip.includes(i)) return; let c = 0;
        for (const p of l.px) if (!p[2] && inside(b, p[0], p[1]) && (!sp || p[3] > tp(p[1]) + EPS || (own >= 0 && Math.abs(p[3] - tp(p[1])) <= EPS && i > own))) c++;
        if (c) { who[l.at] = c; n += c; }
      });
      if (n) out.push({ m, ats: [at, ...Object.keys(who)], text: 'moment ' + m + ': ' + at + ' [' + b + '] is covered by ' + Object.entries(who).map(([k, v]) => k + ' ' + v + ' px').join(', ') });
    }
    return out;
  };
  // frog-counter: the frog on the counter covers neither the dessert case nor the spike
  R['frog-counter'] = ({ m, L }) => {
    if (!COUNTER_FROG.includes(m)) return [];
    const fi = L.findIndex(l => l.who === 'coqui'), out = [];
    for (const [n, p] of Object.entries(parts)) {
      const c = L[fi].px.filter(q => !q[2] && inside(p.box, q[0], q[1])).length;
      if (c) out.push({ m, ats: [L[fi].at], text: 'moment ' + m + ': the frog at ' + L[fi].at + ' covers ' + c + ' px of ' + n + ' [' + p.box + ']' });
    }
    return out;
  };
  // window-lights: in moments 6 and 7 nobody covers the window's lamps or the guagua's lights
  R['window-lights'] = ({ m, L }) => {
    if (![6, 7].includes(m)) return [];
    const st = L.__set ? L.__set.guagua : null, out = [];
    const lamp = new Set(lights.lamps.no), gua = new Set(lights.guagua[st || { 6: 'medio', 7: 'cerca' }[m]]);
    L.forEach(l => { let a = 0, b = 0; for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (lamp.has(k)) a++; if (gua.has(k)) b++; } if (a || b) out.push({ m, ats: [l.at], text: 'moment ' + m + ': ' + l.at + ' covers ' + a + ' px of the window\'s lamps and ' + b + ' px of the guagua\'s lights' }); });
    return out;
  };
  return R;
}

// the whole set of issues for a moment's layers
const issuesOf = (R, m, L) => Object.entries(R).flatMap(([name, f]) => f({ m, L }).map(i => Object.assign({ check: name }, i)));

// the least move of a spot (v first, then u; never z), in steps of .01 up to 3 either way, after which the moment has no issue that names the spot; one result per axis
async function nearestPassing(PV, R, m, at, wanted) {
  const M = PV.moment[m], specs = M.layers, idx = specs.findIndex(s => s.at === at), res = {};
  if (idx < 0) return res;
  for (const [ax, lab] of [[1, 'v'], [0, 'u']]) {
    for (let n = 1; n <= 300 && !res[lab]; n++) for (const sg of [-1, 1]) {
      const off = [0, 0, 0]; off[ax] = r4(sg * n * .01);
      const L = await PV.layers(M.set, specs.map((s, i) => i === idx ? Object.assign({}, s, { off }) : s));
      L.__set = M.set;
      if (!issuesOf(R, m, L).some(i => i.ats.includes(at) && wanted.includes(i.check))) { res[lab] = { d: off[ax], n: r4(sg * n * .01) }; break; }
    }
  }
  return res;
}

async function checks(sheet, G, probes, PV, lights) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, parts = sheet.parts;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, ctx = { S, T, parts, lights, G, x0 }, R = rulesOf(ctx);
  const LAY = {}; for (const m of MOMENTS) { LAY[m] = PV.inspect[m].layers; LAY[m].__set = PV.inspect[m].set; }
  const issues = name => MOMENTS.flatMap(m => R[name]({ m, L: LAY[m] }).map(i => Object.assign({ check: name }, i)));
  const hintsFor = async (list, wanted) => {
    const lines = [], seen = new Set();
    for (const i of list) for (const at of i.ats) {
      const k = i.m + ':' + at; if (seen.has(k) || !S[at] || S[at].fixed) continue; seen.add(k);   // a seat is fixed by the set
      const r = await nearestPassing(PV, R, i.m, at, Object.keys(R));
      lines.push('       nearest passing, moment ' + i.m + ' ' + at + ' ' + S[at].uv + ': ' + (['v', 'u'].map(a => r[a] ? a + ' ' + S[at].uv[a === 'u' ? 0 : 1] + ' -> ' + r4(S[at].uv[a === 'u' ? 0 : 1] + r[a].d) + ' (' + sgn(r[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    return lines;
  };

  // 1. the view: x0 holds every spot
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box and his rows from the drawn silhouette; a small thing's box)
  {
    const SILK = { adulto: 'senor', nino: 'luis', abuelaS: 'abuela.S', adultoS: 'abuelo.S', ninoS: 'luis.S', coqui: 'coqui' }, bad = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sil = s.sprite ? PV.boxes[SILK[s.sprite]] : null;
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else { top = sy + sil.box[1]; bottom = sy + sil.box[3]; }
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB), picL && 'picture\'s left edge ' + picL, picR && 'picture\'s right edge ' + picR].filter(Boolean);
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + s.box + ']') + ' is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ') or the picture');
    }
    add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the cart carrito is box [' + S.carrito.box + '], carrito2 [' + S.carrito2.box + ']; the leftmost sprite column is ' + V.wide.extent[0] + ' (cocina), the rightmost ' + V.wide.extent[1], [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 3. the spots above the ground are on what the set draws: a seat's top (part mesas), the counter's top (part mostrador); on the cart: the cart's own top surface (the sprite's row)
  {
    const bad = [], lines = [], px = probes.spotsPx, surf = [];
    // the chairs: the spot is the chair's own place (E.SEATS, and what FD.setTable returned for the next table) and the chair drawn alone has its seat's top at the spot's depth; in the picture the table is in
    // front of every chair's seat (the set's pixel under a sitter's spot is the table's), so the pixel under the spot cannot be asked
    const ch = G.tables.chair, chairOk = Math.abs(ch.z - ch.d) < .1;
    const seatsOk = E.SEATS.every((p, i) => S['silla' + (i + 1)].uv[0] === r4(p[0]) && S['silla' + (i + 1)].uv[1] === r4(p[1])) && G.tables.calls[0].seats.every((p, i) => p[0] === E.SEATS[i][0] && p[1] === E.SEATS[i][1]) && E.NEXTSEATS.every((p, i) => S['otra_mesa' + (i + 1)].uv[0] === r4(p[0]) && S['otra_mesa' + (i + 1)].uv[1] === r4(p[1]));
    if (!chairOk) bad.push('a chair drawn alone at (0, 8): its seat\'s top at row ' + ch.sy + ' has depth ' + r2(ch.z) + ', not ' + r2(ch.d) + ' (z ' + SEAT_Z + ')');
    if (!seatsOk) bad.push('silla1 to silla4 or otra_mesa1, otra_mesa2 are not the chairs FD.setTable returned');
    for (const [k, s] of Object.entries(S)) {
      if (s.on !== 'mesas') continue;
      const best = (px[k] || []).find(r => r.dx === 0 && r.dy === 0);
      lines.push(k + ' z ' + s.uv[2] + ': the chair\'s own place (' + (k.startsWith('silla') ? 'E.SEATS' : 'FD.setTable\'s return for the next table') + '); drawn alone its seat\'s top is at depth ' + r2(ch.z) + ' against the ' + r2(ch.d) + ' of a spot at z ' + SEAT_Z + '; in the picture the table hides it (the pixel under the spot is part ' + (best ? best.tag + ' at depth ' + r2(best.z) : 'none') + ', the table\'s)'); surf.push(k);
    }
    for (const [k, s] of Object.entries(S)) {
      if (s.on !== 'mostrador') continue;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === s.on && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws: ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    // the cart: its top surface is z .8 (18 px above its feet), so each thing's bottom edge is on the cart's own row; the sprite's slab is under it (the cart's ink on that row at the thing's column)
    const topRow = CART.h - Math.round(CART.z * 22.5), cartLines = [];
    for (const [c, names] of [['carrito', ['carrito_coqui', 'copa', 'flanes', 'mantecado']], ['carrito2', ['carrito_coqui2', 'copa2', 'flanes2', 'mantecado2']]]) {
      const cs = S[c], ink = new Set(await PV.cartRow(topRow));
      for (const n of names) { const s = S[n], col = s.screen[0] - (cs.screen[0] - 38), rowOk = s.moved ? s.moved.by[0] === 0 && s.uv[2] === CART.z : s.screen[1] === cs.screen[1] - Math.round(CART.z * 22.5), inkOk = ink.has(col); cartLines.push(n + ' column ' + col + ' row ' + s.screen[1]); if (!rowOk || !inkOk) bad.push(n + ' ' + s.screen + ' is not on the cart\'s top: ' + (rowOk ? '' : 'its row is not the cart\'s top row ' + (cs.screen[1] - Math.round(CART.z * 22.5)) + ' ') + (inkOk ? '' : 'the cart has no ink under it (cart column ' + col + ')')); }
      const t = S[c === 'carrito' ? 'tapa' : 'tapa2'], tb = t.box, cb = cs.box;
      if (tb[0] + tb[2] <= cb[0] || tb[0] >= cb[0] + cb[2]) bad.push((t === S.tapa ? 'tapa' : 'tapa2') + ' box [' + tb + '] does not touch the cart [' + cb + ']');
    }
    // the shift between the two carts is the same for the five places
    const du = r4(S.carrito2.uv[0] - S.carrito.uv[0]), dv = r4(S.carrito2.uv[1] - S.carrito.uv[1]);
    for (const [a, b] of [['carrito_coqui', 'carrito_coqui2'], ['copa', 'copa2'], ['flanes', 'flanes2'], ['mantecado', 'mantecado2'], ['tapa', 'tapa2']]) if (r4(S[b].uv[0] - S[a].uv[0]) !== du || r4(S[b].uv[1] - S[a].uv[1]) !== dv) if (!(S[a].moved || S[b].moved)) bad.push(b + ' is not ' + a + ' shifted by (' + du + ', ' + dv + ')');
    const o = add('spots-on-surface', bad, surf.length + ' spots on the seats and the counter (' + surf.join(', ') + ') are on a surface the set draws (the chairs\' own places, a chair drawn alone has its seat\'s top at the depth of a spot at z ' + SEAT_Z + '; the counter\'s top z ' + E.COUNTER.h + ' part mostrador: depth within .1 of the spot\'s); the cart\'s ' + cartLines.length + ' places stand on its top surface (z ' + CART.z + ', canvas row ' + topRow + ': the cart\'s own ink is under each, tapa touches the cart) and the next table\'s five are the first five shifted by (' + du + ', ' + dv + ')', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the set things' boxes: inside the picture and the window, and the drawer, the mints' bowl, the window and the door are what the set draws there
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      const tg = probes.boxTags[k], n = Object.values(tg).reduce((a, c) => a + c, 0);
      lines.push(k + ' [' + b + '] ' + Object.entries(tg).map(([g, c]) => g + ' ' + c).join(', '));
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture');
      if (k === 'gaveta' && (tg.mostrador || 0) < n) bad.push('gaveta [' + b + ']: only ' + (tg.mostrador || 0) + ' of its ' + n + ' px are the counter\'s (the register\'s front)');
    }
    for (const [k, p] of Object.entries(parts)) { const tg = probes.boxTags[k], n = Object.values(tg).reduce((a, c) => a + c, 0); lines.push('part ' + k + ' [' + p.box + '] ' + Object.entries(tg).map(([g, c]) => g + ' ' + c).join(', ')); if ((tg.mostrador || 0) < n * .5) bad.push('part ' + k + ' [' + p.box + ']: only ' + (tg.mostrador || 0) + ' of its ' + n + ' px are the counter\'s'); }
    add('things-in-view', bad, 'the boxes of gaveta, mentas, ventana and puerta are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture; the drawer is the register\'s own front (' + lines.join('; ') + ')', ['things outside or not on what the set draws:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: every moment
  {
    const bad = issues('sprites-apart'), all = [];
    for (const m of MOMENTS) { const P = LAY[m].filter(l => l.who); for (let i = 0; i < P.length; i++) for (let j = i + 1; j < P.length; j++) { const a = P[i], b = P[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy); all.push({ m, a: a.at, b: b.at, dx, dy, half, over: dx < half }); } }
    const o = add('sprites-apart', bad, all.length + ' pairs in the 7 moments of the preview: no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'), [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['sprites-apart'])) o.lines.push(l);
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
  }

  // 6. frog-seen: the frog is whole in every moment
  {
    const bad = issues('frog-seen'), lines = [];
    for (const m of MOMENTS) { const L = LAY[m], fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, planes(L), fi, null); lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite, ' + f.out + ' outside the picture'); }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 7 moments (0 px hidden or covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['frog-seen'])) o.lines.push(l);
  }

  // 7. heads-clear
  {
    const bad = issues('heads-clear'), lines = [];
    for (const m of MOMENTS) { const L = LAY[m], M = planes(L); L.forEach((l, i) => { if (!l.group || !(HEADS[m] || []).includes(l.group)) return; const c = coverOf(L, M, i, null, [0, HEAD_ROWS]); lines.push('m' + m + ' ' + l.at + ' (' + l.id + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ', ' + c.tot + ' px, ' + c.cov + ' covered, ' + c.hid + ' hidden by the set'); }); }
    const o = add('heads-clear', bad, 'the head (the top ' + HEAD_ROWS + ' rows) of everyone who sits at a table (the family at the long table in moments 1, 2 and 5; the two guests at the next table in moment 2) is covered by nobody and hidden by nothing: ' + lines.join('; '), [bad.length + ' head(s) covered:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['heads-clear'])) o.lines.push(l);
  }

  // 8. waist-up: the mesera at caja (moments 3, 4, 7) and behind the cart (1, 2) is whole from the waist up
  {
    const bad = issues('waist-up'), lines = [];
    for (const m of MOMENTS) for (const at of WAIST[m] || []) { const L = LAY[m], i = idxAt(L, at), c = coverOf(L, planes(L), i, null, [0, UP.waist[L[i].who]]); lines.push('m' + m + ' ' + at + ' ' + [L[i].sx, L[i].sy] + ': top ' + UP.waist[L[i].who] + ' rows (' + c.top + ' to ' + (c.top + UP.waist[L[i].who] - 1) + '): ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite'); }
    const o = add('waist-up', bad, 'the mesera is whole from the waist up (the top ' + UP.waist.adulto + ' rows of her sprite) at caja (moments 3, 4, 7) and behind the cart (moment 1 mesera93, moment 2 mesera93b): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) { for (const l of await hintsFor(bad, ['waist-up'])) o.lines.push(l); o.lines.push('       info, not a check: ' + lines.join('; ')); }
  }

  // 9. chest-up: the guests at otra_mesa (moment 2) are whole from the chest up and inside the window; the cocinero at cocina (5, 7) is whole from the chest up
  {
    const bad = issues('chest-up'), lines = [];
    for (const m of MOMENTS) for (const at of CHEST[m] || []) { const L = LAY[m], i = idxAt(L, at), c = coverOf(L, planes(L), i, null, [0, UP.chest[L[i].who]]); lines.push('m' + m + ' ' + at + ' ' + [L[i].sx, L[i].sy] + ': top ' + UP.chest[L[i].who] + ' rows: ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite, window cut ' + cutAt(S[at], x0)); }
    const o = add('chest-up', bad, 'the guests at otra_mesa1 and otra_mesa2 (moment 2) and the cocinero at cocina (moments 5, 7) are whole from the chest up (the top ' + UP.chest.adulto + ' rows) and inside the window: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) { for (const l of await hintsFor(bad, ['chest-up'])) o.lines.push(l); o.lines.push('       info, not a check: ' + lines.join('; ')); }
  }

  // 10. things-free: the machine, the jar and the drawer in moments 3, 4 and 6; the cup, the flans, the tub and the cover on the cart in moments 1 and 2 (the frog covers none of them)
  {
    const bad = issues('things-free'), lines = [];
    for (const m of MOMENTS) for (const at of FREE[m] || []) lines.push('m' + m + ' ' + at + ' [' + (S[at] || T[at]).box + ']' + (bad.some(b => b.m === m && b.ats[0] === at) ? ' covered' : ' free'));
    const o = add('things-free', bad, 'the machine, the jar and the drawer are covered by nobody in moments 3, 4 and 6 (the payer\'s box starts at column ' + (S.paga.screen[0] - 12) + ', the jar\'s ends at column ' + (S.frasco.box[0] + S.frasco.box[2] - 1) + '), and the cup, the flans, the tub and the cover are covered by nobody (the frog among them) on the cart in moments 1 and 2: ' + lines.join('; '), [bad.length + ' thing(s) covered:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['things-free'])) o.lines.push(l);
  }

  // 11. frog-counter: the frog on the counter stands on its top (see spots-on-surface) and covers neither the dessert case nor the spike
  {
    const bad = issues('frog-counter'), lines = [];
    for (const m of COUNTER_FROG) { const L = LAY[m], fi = L.findIndex(l => l.who === 'coqui'), sh = L[fi].px.filter(q => !q[2]), xs = sh.map(q => q[0]); lines.push('m' + m + ': the frog\'s columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ' (the case ends at column ' + (parts.vitrina.box[0] + parts.vitrina.box[2] - 1) + ', the spike starts at ' + parts.pincho.box[0] + ')'); }
    const o = add('frog-counter', bad, 'the frog at mostrador_coqui (moments 3, 4, 5, 6) covers no pixel of the dessert case [' + parts.vitrina.box + '] nor of the spike [' + parts.pincho.box + ']: ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['frog-counter'])) o.lines.push(l);
  }

  // 12. window-lights: in moments 6 and 7 nobody covers the window's lamps or the guagua's lights; what the family in the doorway covers of the window
  {
    const bad = issues('window-lights'), lines = [], vb = T.ventana.box;
    const nLamp = lights.lamps.no.length, nGua = { medio: lights.guagua.medio.length, cerca: lights.guagua.cerca.length };
    for (const m of [6, 7]) {
      const L = LAY[m], per = L.map(l => { let c = 0; for (const p of l.px) if (!p[2] && inside(vb, p[0], p[1])) c++; return [l.at, c]; }).filter(q => q[1]);
      lines.push('m' + m + ' what is drawn over the window [' + vb + '] (' + vb[2] * vb[3] + ' px): ' + (per.map(q => q[0] + ' ' + q[1] + ' px').join(', ') || 'nobody'));
    }
    const o = add('window-lights', bad, 'in moments 6 (guagua medio: ' + nGua.medio + ' px of lights) and 7 (guagua cerca: ' + nGua.cerca + ' px) nobody covers the window\'s ' + nLamp + ' px of lamps or the guagua\'s lights (the lamps and lights found by re-baking the set with the street picture marked); ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b.text)));
    if (bad.length) for (const l of await hintsFor(bad, ['window-lights'])) o.lines.push(l);
  }

  // info: how the stand-ins touch (not checks of the spec)
  {
    const lines = [];
    for (const m of [3, 4, 7]) { const L = LAY[m], i = idxAt(L, 'caja'), sh = L[i].px.filter(p => !p[2]), top = Math.min(...L[i].px.map(p => p[1])), last = Math.max(...sh.map(p => p[1])); lines.push('m' + m + ' the mesera at caja ' + [L[i].sx, L[i].sy] + ': her top row ' + top + ', the lowest row of hers that shows is ' + last + ' (sprite row ' + (last - top) + ' of ' + (L[i].px.reduce((a, p) => Math.max(a, p[1]), 0) - top + 1) + '), the counter\'s far edge is row ' + (E.COUNTER.v0 * 13 + G.OY - E.COUNTER.h * 22.5)); }
    OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
