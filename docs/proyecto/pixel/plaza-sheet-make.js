#!/usr/bin/env node
'use strict';
/* La plaza's sheet (the scene `plaza`, place 6, stories 60 to 62): writes docs/proyecto/pixel/plaza-sheet.json from plaza-set.html and the design (the orchestrator's p6-spec, section "plaza"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/plaza-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   Modelled on cruce-sheet-make.js. A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture and v down it,
   and the set's own PZ.xy(u, v) (plaza-base.js) gives its world place; the make then projects it with the engine's own project() (pp-engine.js). In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S.
   It loads the set in headless Chrome (plaza-set.html, window.PLAZA.E: the set's constants), reads the pixels it drew (tags=1: which part drew each pixel; the baked depth), and writes the spots, things,
   the view (wide), the hooks of the notice board, the bubbles, shadows and the depth rule. The sprites' silhouettes come from the PREVIEW's makers (today's historia/engine.js and escenas/kit.js, with stand-ins).
   The checks that say "covers" or "shows" read the PREVIEW's moments (plaza-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet
   is written again with the checks. It prints one line per check and exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with PLAZA_BASE), but every request to it is answered from the files of THIS tree (the server's root may be
   another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'plaza-sheet.json');
const BASE = process.env.PLAZA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/plaza-set.html';
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

// the numbers of the design (p6-spec: the rules for every sheet, and "plaza")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const BUBBLE = { w: 22, h: 22, gap: 4, above: 3 };       // the two answer bubbles: 22 px squares, 4 px apart, centred over the frog, their foot 3 px above his head
const FOTO = { w: 5, h: 6 };                             // a photo on a hook: a 5 x 6 px stand-in
const QUARTER = .25;
const SEAT_Z = { asiento: .46, respaldo: 1.17 }, CART_TOP = 1.02;      // the seat's top, the top of its back, the cart's top (the spec's numbers: read back from the set's depth: spots-on-surface)
// the board's drawing (plaza-set.html, board()): the two halves, the pictures, the hooks, in fractions of a half's width (hu) and of the board's height (fz)
const BOARD = { pic: { hu: [.08, .92], fz: [.55, .93] }, hooks: { hu: [.04, .96], fz: [.36, .44], at: .4 }, n: 5 };
const MOMENTS = [1, 2, 3, 4, 5, 6], EXTRA_MOMENTS = [7];

// the spots: [name, (u, v, z), kind, silhouette, character kind, what, on]
// silhouette: which drawing hangs there (adulto, nino, adultoS = a grown-up sitting, coqui, perro = Canelo lying, paloma, tarjetas) or null; on = the part of the set it stands on above the ground
const spotsOf = E => {
  const B = E.BOARD, K = E.CART, S = [];
  const add = (name, uvz, kind, sil, who, what, on) => S.push([name, uvz, kind, sil, who, what, on]);
  [[-.9, 'adultoS'], [.1, 'adultoS'], [1.1, 'adultoS'], [2.1, 'coqui']].forEach(([u, sil], i) => add('asiento' + (i + 1), [u, 0, SEAT_Z.asiento], 'person', sil, sil === 'coqui' ? 'coqui' : 'adulto', 'a place on the seat, on its top (z ' + SEAT_Z.asiento + '); whoever sits faces us' + (sil === 'coqui' ? ' (the frog, 32 wide: the seat\'s right end, where nobody stands in front of him)' : ' (a grown-up sitting, 24 wide)'), 'banco'));
  [-1.2, -.3, .6].forEach((u, i) => add('respaldo' + (i + 1), [u, -.24, SEAT_Z.respaldo], 'thing', 'paloma', null, 'a pigeon on the seat\'s back (the top slat, z ' + SEAT_Z.respaldo + ' at v - .24): a sprite', 'banco'));
  add('bajo', [.4, 3.9, 0], 'person', 'perro', 'perro', 'Canelo lying on the paving in front, where nobody stands before him');
  [-3.1, -1.95, -.8, .35, 1.5, 2.65].forEach((u, i) => add('suelo' + (i + 1), [u, 1.3, 0], 'person', 'adulto', 'adulto', 'the first row in front of the seat (v 1.3)'));
  [-2.5, -1.35, -.2, .95, 2.1, 3.25].forEach((u, i) => add('frente' + (i + 1), [u, 2.6, 0], 'person', 'adulto', 'adulto', 'the second row, half a step to the side (v 2.6)'));
  [-3.1, -1.95, -.8, .35, 1.5, 2.65].forEach((u, i) => add('cerca' + (i + 1), [u, 3.9, 0], 'person', 'adulto', 'adulto', 'the third row (v 3.9)'));
  add('tablero1', [-3.2, .9, 0], 'person', 'nino', 'nino', 'in front of the notice board: Ana (story 61)');
  add('tablero2', [-2.05, .7, 0], 'person', 'coqui', 'coqui', 'in front of the notice board: the frog (story 61)');
  add('repisa', [(B.u0 + B.u1) / 2, B.v + .1, B.z0], 'thing', 'tarjetas', null, 'the middle of the board\'s ledge (its top is z0 = ' + B.z0 + ', at v + .1): the three blank cards under their stone: a sprite', 'tablero');
  add('entrada', [-4.7, 2.6, 0], 'entry', 'adulto', 'adulto', 'where people come in, at the left: outside the window on purpose');
  add('carro_pie', [K.u, K.v - K.hd - .18, 0], 'person', 'adulto', 'adulto', 'the piragüero behind his cart: (CART.u, CART.v - CART.hd - .18)');
  add('carro_borde', [K.u - .5, K.v + .2, CART_TOP], 'person', 'coqui', 'coqui', 'the frog on the cart\'s top (z ' + CART_TOP + '): (CART.u - .5, CART.v + .2)', 'carrito');
  add('turno', [1.6, 3.6, 0], 'person', 'adulto', 'adulto', 'the visitor at the cart (story 62)');
  [[.45, 3.8], [-.7, 4.0], [-1.85, 4.2], [-3.0, 4.4]].forEach(([u, v], i) => add('fila' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'the line behind her: place ' + (i + 1)));
  [[.5, 5.2], [1.65, 5.2]].forEach(([u, v], i) => add('ayuda' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'one of the two who come up to help: place ' + (i + 1)));
  return S;
};
// the stand-ins of the preview, for the silhouettes
const SIL_OF = { adulto: 'senor', nino: 'luis', adultoS: 'abuelaAnaS', coqui: 'coqui', perro: 'perro', paloma: 'palomaD', tarjetas: 'tarjetas', foto: 'foto' };

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot but entrada), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on the seat, its back, the ledge and the cart's top are on
   that top: z read back from the set's depth), things-in-view (the things' boxes, the bubbles' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment),
   board-clear (moments 3 and 4: nobody covers the board's pictures or rows of hooks), piraguero-head (his head: neither the awning nor the cart covers it), frog-on-cart (the frog whole, at most a quarter of the
   piragüero's box), bubbles (inside the picture, cover neither the frog nor a pigeon). A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1&tablero=1&carrito=1&hora=mediodia');
  const G = await page.evaluate(() => ({ E: JSON.parse(JSON.stringify(PLAZA.E)), scene: PP_SCENE, W, H, S, OX, OY }));
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const [x, y] = PZ.xy(u, v), q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj, page);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs);
  sheet.rules.anchor = anchorText(PV.SIL);
  const results = await checks(sheet, G, PV.SIL, probes, PV);
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

/* ---------- the preview's moments: plaza-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/plaza-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, SIL: {} };
  for (const [k, name] of Object.entries(SIL_OF)) PV.SIL[k] = await p.evaluate(n => window.PREVIEW.silhouette(n), name);
  for (const m of MOMENTS.concat(EXTRA_MOMENTS)) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow, rows) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow, x.rows), { st, specs, idx, allow: allow || 0, rows: rows || 0 });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];

// the columns a spot's sprite covers, as offsets from its column: a person by the spec's widths (the feet's column in the middle), anything else by its drawn silhouette; null for a bare point
const extOf = (s, SIL) => s.who ? [-WIDTH[s.who] / 2, WIDTH[s.who] / 2 - 1] : s.sprite && SIL[s.sprite] ? [SIL[s.sprite].box[0], SIL[s.sprite].box[2]] : [0, 0];
// how many px of a spot are cut by the window at x0: its sprite's columns outside it; 0 when whole. An entry: its point only
function cutAt(s, x0, SIL) {
  const sx = s.screen[0];
  if (s.kind === 'entry') return sx < x0 ? x0 - sx : sx > x0 + 195 ? sx - x0 - 195 : 0;
  const [l, r] = extOf(s, SIL);
  return Math.max(0, x0 - (sx + l)) + Math.max(0, (sx + r) - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, page) {
  const E = G.E, sc = G.scene, B = E.BOARD, K = E.CART;
  const DEFS = spotsOf(E), pr = await proj(DEFS.map(s => s[1]));
  const spots = {};
  DEFS.forEach((s, i) => {
    const q = pr[i], o = { world: W4([q[3], q[4], s[1][2]]), uv: W4(s[1]), screen: [Math.round(q[0]), Math.round(q[1])], depth: r4(q[2]), scale: 1, kind: s[2], view: 'wide', what: s[5] };
    if (s[3]) o.sprite = s[3];
    if (s[4]) o.who = s[4];
    if (s[1][2] > 0) o.on = s[6] || 'banco';                                  // what it stands on above the ground: a part of the set (the seat, its back, the ledge, the cart's top)
    spots[s[0]] = o;
  });

  /* ---- the view: one window, wide. x0: the window's left edge; the one nearest the picture's middle (22) among those that hold every spot (entrada, outside on purpose, apart) ---- */
  const holds = Object.keys(spots).filter(k => spots[k].kind !== 'entry');
  // the view wants the same widths the checks use: people by the spec's widths, the rest from the stand-ins' drawn silhouettes (a pigeon 29 wide, the cards 16)
  const NOMINAL = { paloma: [-14, 14], tarjetas: [-8, 7] };
  const ext = holds.map(k => { const sp = spots[k]; if (sp.who) return [sp.screen[0] - WIDTH[sp.who] / 2, sp.screen[0] + WIDTH[sp.who] / 2 - 1]; const n = NOMINAL[sp.sprite] || [0, 0]; return [sp.screen[0] + n[0], sp.screen[0] + n[1]]; });
  const lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1])), centre = (G.W - 196) / 2;
  let best = null, okRange = [];
  for (let x0 = 0; x0 <= G.W - 196; x0++) {
    const cut = ext.reduce((n, e) => n + Math.max(0, x0 - e[0]) + Math.max(0, e[1] - (x0 + 195)), 0);
    if (!cut) okRange.push(x0);
    const key = [cut, Math.abs(x0 - centre)];
    if (!best || key[0] < best.key[0] || (key[0] === best.key[0] && key[1] < best.key[1])) best = { x0, key };
  }
  const x0 = best.x0;
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = { wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [60, 61, 62], holds, extent: [lo, hi],
    what: 'the one view of stories 60, 61 and 62: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment inside it with its sprite whole (entrada, outside on purpose, apart). ' + (best.key[0] ? 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px (' + best.key[0] + ')' : 'x0 ' + x0 + ' holds every spot (x0 that do: ' + okRange[0] + ' to ' + okRange[okRange.length - 1] + '; the spots span columns ' + lo + ' to ' + hi + '; ' + x0 + ' is the one nearest the picture\'s centring, ' + centre + ')') + '. The window\'s point is the ground point under its middle column at the picture\'s middle row' } };

  /* ---- the board: its hooks (derived from the set's own drawing, plaza-set.html board()) ---- */
  const wB = B.u1 - B.u0, hB = B.z1 - B.z0, half = wB / 2;
  const uOf = (h, hu) => B.u0 + h * half + hu * half, zOf = fz => B.z0 + fz * hB;
  const hookPts = [];
  for (const h of [0, 1]) for (let i = 0; i < BOARD.n; i++) hookPts.push([uOf(h, (i + .5) / BOARD.n), B.v, zOf(BOARD.hooks.at)]);
  const hq = await proj(hookPts), ganchos = { isla: [], ciudad: [] };
  hookPts.forEach((p, i) => { const q = hq[i], o = { n: (i % BOARD.n) + 1, uvz: W4(p), world: W4([q[3], q[4], p[2]]), screen: [Math.round(q[0]), Math.round(q[1])], depth: r4(q[2]) }; ganchos[i < BOARD.n ? 'isla' : 'ciudad'].push(o); });
  ganchos.rule = 'five hooks in each row, at hu = .1, .3, .5, .7, .9 of the picture\'s half (u from the half\'s left edge), at the height of the hook marks (fz ' + BOARD.hooks.at + ' of the board: z ' + r4(zOf(BOARD.hooks.at)) + '), on the board\'s plane (v ' + B.v + '). The island is the left half, the city the right. A photo (5 x 6 px, a stand-in) hangs by its top middle from a hook: its top row is the hook\'s row (screen), its middle column the hook\'s. In moment 4 the first two hooks of each row hold one';

  /* ---- the bubbles: the rule, and the boxes for the frog at asiento4 (computed from the frog's drawn head: see the checks, where the silhouette is known) ---- */

  /* ---- things he can touch ---- */
  const boxOfUVZ = async (u0, v0, z0, u1, v1, z1) => {                                                  // a box in u, v, z: its world axis box and its screen box (the projected corners)
    const corners = []; for (const u of [u0, u1]) for (const v of [v0, v1]) for (const z of [z0, z1]) corners.push([u, v, z]);
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by] };
  };
  // the screen box of the pixels a part drew (tags=1)
  const tagBox = tag => page.evaluate(t => { let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1; for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === t) { const x = i % W, y = (i / W) | 0; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 - x0 + 1, y1 - y0 + 1]; }, tag);
  const things = {};
  {
    const S = E.SEAT, T = E.TREE, rt = T[3];
    const bb = await boxOfUVZ(S.u - S.hw, S.v - .3, 0, S.u + S.hw, S.v + .26, 1.17);
    things.banco = { set: true, uv: bb.uv, world: bb.world, box: await tagBox('banco'), what: 'the long seat with its back: the screen box of the pixels the set draws for the part banco; its world box is the block u ' + (S.u - S.hw) + ' to ' + (S.u + S.hw) + ', v -.3 to .26, up to z 1.17 (the top of its back); a poke' };
    // the tree: the crown's balls of calle-base.js CL.tree (offsets in world x, y), at the trunk's world place
    const [tx, ty] = (await proj([[T[0], T[1], 0]]))[0].slice(3), BL = [[0, 0, 0, 1], [-.55, .1, -.15, .72], [.5, -.15, -.1, .74], [.1, .5, -.25, .66], [-.15, -.5, .1, .68], [.3, .3, .35, .6], [-.35, -.2, .4, .58]];
    const tw = [tx + rt * Math.min(...BL.map(b => b[0] - b[3])), ty + rt * Math.min(...BL.map(b => b[1] - b[3])), 0, tx + rt * Math.max(...BL.map(b => b[0] + b[3])), ty + rt * Math.max(...BL.map(b => b[1] + b[3])), T[2] + rt * .7 + rt * Math.max(...BL.map(b => b[2] + b[3]))];
    things.arbol = { set: true, world: W4(tw), box: await tagBox('arbol'), what: 'the big tree behind the seat (trunk at u ' + T[0] + ', v ' + T[1] + '): the screen box of the pixels the set draws for the part arbol (it runs off the top of the picture); its world box is the trunk and the crown\'s balls (calle-base.js tree); a poke' };
    const tb = await boxOfUVZ(B.u0 - .12, B.v - .12, 0, B.u1 + .12, B.v + .22, B.z1 + .3);
    things.tablero = { set: true, when: 'tablero = 1', uv: tb.uv, world: tb.world, box: await tagBox('tablero'), what: 'the notice board: the screen box of the pixels the set draws for the part tablero (its two posts, the frame, the two pictures, the hooks, the ledge and its little roof); a poke' };
    for (const [name, h, what] of [['fila_isla', 0, 'the island (the left half): its picture and its row of hooks, one box'], ['fila_ciudad', 1, 'the city (the right half): its picture and its row of hooks, one box']]) {
      const fb = await boxOfUVZ(uOf(h, BOARD.hooks.hu[0]), B.v, zOf(BOARD.hooks.fz[0]), uOf(h, BOARD.hooks.hu[1]), B.v + .02, zOf(BOARD.pic.fz[1]));
      things[name] = { set: true, when: 'tablero = 1', uv: fb.uv, world: fb.world, box: fb.box, what: what + ': from the hooks\' lower edge (fz ' + BOARD.hooks.fz[0] + ' of the board) up to the picture\'s top (fz ' + BOARD.pic.fz[1] + '), across the half (hu ' + BOARD.hooks.hu.join(' to ') + '); a poke. The hooks are in ganchos' };
    }
    things.tarjetas = { sprite: true, at: 'repisa', when: 'tablero = 1', why: 'the blank cards under their stone: a sprite at repisa (a stand-in 16 x 12 in the preview); a poke' };
    const cb = await boxOfUVZ(K.u - K.hw - .12, K.v - K.hd - .1, 0, K.u + K.hw + .12, K.v + K.hd + .14, 3.7);
    things.carrito = { set: true, when: 'carrito = 1', uv: cb.uv, world: cb.world, box: await tagBox('carrito'), what: 'the piragüero\'s cart with its striped awning: the screen box of the pixels the set draws for the part carrito (the body, the two wheels, the four posts, the awning); a poke' };
  }
  things.palomas = { sprite: true, at: ['respaldo1', 'respaldo2', 'respaldo3'], why: 'the pigeons: sprites (a stand-in in the preview: the El parque bird at the size drawAve draws it, 29 x 22)' };
  for (const k of ['ana', 'mama_ana', 'beto', 'abuela_ana', 'luis', 'carmen', 'senor', 'senora', 'hombre', 'mujer', 'joven', 'piraguero', 'turista', 'coqui', 'perro']) things[k] = 'sprite';
  things.burbuja_a = { set: false, at: 'asiento4', box: null, rule: null, what: 'the first answer bubble: a 22 x 22 square, at the left of the two (the act burbujas {izq} says which line is there; a poke)' };
  things.burbuja_b = { set: false, at: 'asiento4', box: null, rule: null, what: 'the second answer bubble: a 22 x 22 square, at the right of the two' };

  const stateKeys = [];
  for (const hora of ['manana', 'mediodia', 'tarde']) for (const tablero of [0, 1]) for (const carrito of [0, 1]) stateKeys.push('?hora=' + hora + '&tablero=' + tablero + '&carrito=' + carrito);
  return {
    scene: 'plaza',
    made: 'node docs/proyecto/pixel/plaza-sheet-make.js, from plaza-set.html (window.PLAZA.E) and the design of La plaza (the orchestrator\'s p6-spec, section plaza). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), z up; the set\'s PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z (a wall that faces the camera is a plane v = const). The seat is at v 0 (u from ' + (E.SEAT.u - E.SEAT.hw) + ' to ' + (E.SEAT.u + E.SEAT.hw) + '), the board at v ' + B.v + ', the cart at (' + K.u + ', ' + K.v + ')',
      spot: 'a spot is a world point of the feet (z 0: the paving; z .46: the seat\'s top; z 1.17: the top of its back; z ' + B.z0 + ': the board\'s ledge; z ' + CART_TOP + ': the cart\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: null,
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = the window\'s left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      bubbles: 'the two answer bubbles (burbuja_a at the left, burbuja_b at the right; the act says which line each carries): two ' + BUBBLE.w + ' x ' + BUBBLE.h + ' px squares, ' + BUBBLE.gap + ' px apart, together centred on the frog\'s middle column, their foot (the bottom edge) ' + BUBBLE.above + ' px above the top row of his head: bottom edge = (his top ink row) - ' + BUBBLE.above + '; so for a frog at a spot (sx, sy) with his top ink row sy - 24: a = [sx - 24, sy - 49, 22, 22] (columns sx - 24 to sx - 3), b = [sx + 2, sy - 49, 22, 22]. The boxes in things are those of the frog at asiento4',
    },
    setKey: {
      params: { hora: { values: ['manana', 'mediodia', 'tarde'], note: '60 manana, 61 tarde, 62 mediodia (the script)' }, tablero: { values: [0, 1], note: 'the notice board with its two pictures, two rows of hooks and ledge (story 61)' }, carrito: { values: [0, 1], note: 'the piragüero\'s cart at the right (story 62)' } },
      key: 'hora + tablero + carrito, e.g. "manana-0-0"',
      used: { 'story 60': '?hora=manana&tablero=0&carrito=0', 'story 61': '?hora=tarde&tablero=1&carrito=0', 'story 62': '?hora=mediodia&tablero=0&carrito=1' },
      baked: stateKeys,
    },
    things,
    ganchos,
    spots,
    groups: {
      asientos: ['asiento1', 'asiento2', 'asiento3', 'asiento4'], respaldos: ['respaldo1', 'respaldo2', 'respaldo3'],
      suelo: [1, 2, 3, 4, 5, 6].map(i => 'suelo' + i), frente: [1, 2, 3, 4, 5, 6].map(i => 'frente' + i), cerca: [1, 2, 3, 4, 5, 6].map(i => 'cerca' + i),
      tablero: ['tablero1', 'tablero2', 'repisa'], carro: ['carro_pie', 'carro_borde', 'turno'], fila: ['fila1', 'fila2', 'fila3', 'fila4'], ayuda: ['ayuda1', 'ayuda2'],
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p6-spec, section plaza), given in (u, v, z); the spots the spec gives as a rule are computed: repisa = ((BOARD.u0 + BOARD.u1) / 2, BOARD.v + .1, BOARD.z0), carro_pie = (CART.u, CART.v - CART.hd - .18, 0), carro_borde = (CART.u - .5, CART.v + .2, 1.02)',
      'entrada is outside the window on purpose (a person walks in from the left)',
      'people with no sprite maker yet are drawn in the preview by the nearest maker (mkPersona, a grown-up or a child) in other clothes, for size: Ana (niña, yellow dress), Beto (niño, red cap), Ana\'s mamá (señora), Ana\'s abuela (señora, white hair, sun hat; sitting at asiento1), the piragüero (the señor\'s drawing, white shirt, red hat), the visitors (grown-ups in other clothes), the two helpers (la mujer, el hombre); Luis and Carmen are the real ones; Canelo lies (mkPerro lie)',
      'the pigeons have no maker: the preview draws the El parque bird (mkAve) at the size drawAve draws it (AVK 1.6: 29 x 22), grey. A different pigeon drawing changes the bubbles\' check (bubbles)',
      'the photos on the hooks (5 x 6), the cards under their stone (16 x 12) and the two bubbles (22 x 22) are stand-ins drawn in the preview',
      'ganchos is not in the spec: it is the board\'s five hooks of each row, read from the set\'s drawing code, so that the photos of moment 4 hang where the hooks are',
      'moment 7 is a dev aid, not one of the spec\'s six: moment 2 with the three pigeons on the seat\'s back (the spec lists none in 2, the story\'s game has them); the bubbles check reads the pigeons\' spots whether or not a moment draws them',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the cart\'s awning, its posts and its body, the seat, the board and its roof hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where the set\'s baked depth (window.DEPTH.z of the set page) is more than depth(r) + bias. The same rule as El cruce\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn. The two bubbles are drawn last, over everything',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, senor: .35, senora: .35, hombre: .35, mujer: .35, joven: .35, piraguero: .35, turista: .35, mama_ana: .35, abuela_ana: .35, luis: .28, carmen: .28, ana: .28, beto: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3: open point)',
      none: Object.keys(spots).filter(k => spots[k].uv[2] > 0),
      onSeat: 'whoever sits on the seat, stands on the ledge or on the cart\'s top (z above 0) casts none: that is not ground (a shadow cast at the pavement under it would show in front of it). The pigeons cast none',
    },
  };
}

// the text of rules.anchor, with the measured sizes of the stand-ins
function anchorText(SIL) {
  const rows = k => -SIL[k].box[1];
  return 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), ' + rows('adulto') + ' rows drawn standing for a grown-up, ' + rows('nino') + ' for a child; the frog mkCoqui(1) (32 x 27): column 16, ' + rows('coqui') + ' rows drawn (row 25 of the canvas is on sy); a grown-up sitting (mkPersona with sent = 1: Ana\'s abuela at asiento1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11: 41) on (sx, sy), ' + rows('adultoS') + ' rows drawn above it; Canelo lying mkPerro(\'lie\') (30 x 22): column 15 and its bottom edge; a pigeon (stand-in: the El parque bird, 29 x 22): its bottom middle on the point; a small thing (the cards, a photo hung by its top middle: its top row on the hook\'s row): a stand-in on the point';
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part). The probe page has the board and the cart both up: the depth of the seat does not change with them
  const spotsPx = await page.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 1; dy++) { const X = s.screen[0], Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X; rows.push({ dy, tag: TAGS[i], z: DEPTH.z[i] }); }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
  const tags = px => page.evaluate(q => q.map(([x, y]) => TAGS[y * W + x] || 'ground'), px);          // the part the set drew at each pixel [x, y]
  return { spotsPx, tags };
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, OUTS = [], E = G.E, B = E.BOARD, K = E.CART;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const hw = who => WIDTH[who] / 2;
  const frogTop = SIL.coqui.box[1];                                                                  // the frog's top ink row relative to his feet's edge (-24)

  // the bubbles' boxes (for the frog at asiento4) go into the sheet's things now that the frog's drawn head is known
  {
    const [sx, sy] = S.asiento4.screen, top = sy + frogTop, y = top - BUBBLE.above - BUBBLE.h, x = sx - (BUBBLE.w + BUBBLE.gap / 2);
    T.burbuja_a.box = [x, y, BUBBLE.w, BUBBLE.h]; T.burbuja_b.box = [x + BUBBLE.w + BUBBLE.gap, y, BUBBLE.w, BUBBLE.h];
    T.burbuja_a.rule = T.burbuja_b.rule = 'for the frog at asiento4 ' + [sx, sy] + ': his top ink row is ' + top + ' (his feet\'s edge ' + sy + ' minus ' + (-frogTop) + '); the foot of the bubbles is ' + BUBBLE.above + ' px above it, so their bottom edge is ' + (top - BUBBLE.above) + ' and their top row ' + y + '; together they span columns ' + x + ' to ' + (x + 2 * BUBBLE.w + BUBBLE.gap - 1) + ', centred on his column ' + sx + ' (rules.bubbles)';
  }

  // 1. the view: x0 holds every spot (a person's sprite whole), entrada apart
  {
    const bad = [], v = V, all = [];
    for (let x0 = 0; x0 <= G.W - 196; x0++) if (v.holds.every(k => !cutAt(S[k], x0, SIL))) all.push(x0);
    const out = v.holds.map(k => [k, cutAt(S[k], v.x0, SIL)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const line = 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots (every one but entrada) span columns ' + Math.min(...v.holds.map(k => S[k].screen[0] + extOf(S[k], SIL)[0])) + ' to ' + Math.max(...v.holds.map(k => S[k].screen[0] + extOf(S[k], SIL)[1])) + ' (of the window\'s 196); x0 that hold them all: ' + (all.length ? all[0] + ' to ' + all[all.length - 1] : 'none') + (out.length ? '; CUT: ' + out.map(o => o[0] + ' by ' + o[1] + ' px').join(', ') : '');
    const o = add('views-x0', bad, line, [bad.length + ' spot(s) cut by the window:', '  ' + line].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: V.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (the frog 32 wide, a grown-up 24, a child 24, the dog 28; the rest by its drawn silhouette; the rows from the silhouette)
  {
    const bad = [], info = [], rows = [], x0 = V.x0;
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H, wOut = sx < x0 || sx > x0 + 195;
      const sil = s.sprite ? SIL[s.sprite] : null, [l, r] = extOf(s, SIL);
      const cutL = Math.max(0, x0 - (sx + l)), cutR = Math.max(0, (sx + r) - (x0 + 195)), picL = Math.max(0, -(sx + l)), picR = Math.max(0, (sx + r) - (G.W - 1));
      const top = sil ? sy + sil.box[1] : sy, bottom = sil ? sy + sil.box[3] : sy, cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      const pic = [picL && ('left ' + picL), picR && ('right ' + picR)].filter(Boolean);
      rows.push(k);
      if (s.kind === 'entry') { info.push(k + ' ' + s.screen + ' (outside on purpose): ' + (pOut ? 'its point is outside the ' + G.W + ' x ' + G.H + ' picture, ' + (sx < 0 ? -sx + ' px left of it' : sx - (G.W - 1) + ' px right of it') : 'its point is inside the picture') + (wOut ? '; ' + (sx < x0 ? x0 - sx + ' px left of' : sx - (x0 + 195) + ' px right of') + ' the window [' + x0 + ', ' + (x0 + 196) + ')' : '')); continue; }
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (wOut) bad.push(k + ' ' + s.screen + ' is ' + (sx < x0 ? x0 - sx + ' px left of' : sx - (x0 + 195) + ' px right of') + ' the window [' + x0 + ', ' + (x0 + 196) + ')' + (pic.length ? '; its sprite is also cut by the picture\'s edge: ' + pic.join(', ') : ''));
      else if (cut.length) bad.push(k + ' ' + s.screen + ': its ' + (s.who || s.sprite) + ' sprite is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')' + (pic.length ? ', and by the picture\'s edge: ' + pic.join(', ') : ''));
    }
    // the nearest value that passes, for a spot cut or outside: the least shift in u, in steps of .01 (v and z kept), that puts the point inside and the sprite whole
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k], [l, r] = extOf(s, SIL);
      const ok = sx => sx + l >= x0 && sx + r <= x0 + 195 && sx + l >= 0 && sx + r <= G.W - 1;
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0]; if (ok(sx)) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, (rows.length - 1) + ' spots (points and sprites) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '), every sprite whole; entrada is outside on purpose', [bad.length + ' spot(s) outside, or with a sprite cut:'].concat(bad.map(b => '  ' + b), hints));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
    o.cut = bad;
  }

  // 3. the spots above the ground are on the surface the set draws: the seat's top, the top of its back, the board's ledge, the cart's top (z read back from the baked depth: the part the set drew there, its depth within .06 of the spot's)
  {
    const bad = [], lines = [], above = Object.entries(S).filter(([, s]) => s.on), res = [];
    for (const [k, s] of above) {
      const rows = probes.spotsPx[k] || [], best = rows.map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === s.on && best.dz < .06;
      res.push({ spot: k, z: s.uv[2], part: best ? best.r.tag : null, depthSet: best ? r2(best.r.z) : null, depthSpot: r2(s.depth), dz: best ? r2(best.dz) : null, ok });
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none') + (ok ? '' : ' (should be part ' + s.on + ')'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (part ' + s.on + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const asientos = above.filter(([k]) => k.startsWith('asiento')).every(([, s]) => s.uv[2] === SEAT_Z.asiento);
    const o = add('spots-on-surface', bad.concat(asientos ? [] : ['an asiento is not at the seat\'s top z ' + SEAT_Z.asiento]), above.length + ' spots above the ground (' + above.map(([k]) => k).join(', ') + ') are on a surface the set draws: its depth within .06 of the spot\'s, drawn by the part named (the seat\'s top z ' + SEAT_Z.asiento + ': whoever sits at asiento1 to 4 sits on it; its back\'s top z ' + SEAT_Z.respaldo + '; the ledge\'s top z ' + B.z0 + '; the cart\'s top z ' + CART_TOP + ')', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.surfaces = res;
  }

  // 4. the things' boxes and the bubbles: the boxes of the set's things lie on the picture (reported where they run off it); the bubbles are inside the picture and the window
  {
    const bad = [], info = [];
    for (const [k, t] of Object.entries(T)) {
      if (!t.box) continue;
      const b = t.box, l = Math.max(0, -b[0]), r = Math.max(0, b[0] + b[2] - G.W), tp = Math.max(0, -b[1]), bt = Math.max(0, b[1] + b[3] - G.H), wl = Math.max(0, V.x0 - b[0]), wr = Math.max(0, b[0] + b[2] - (V.x0 + 196));
      if (k.startsWith('burbuja')) { if (l || r || tp || bt || wl || wr) bad.push('thing ' + k + ' box [' + b + '] is outside the picture or the window [' + V.x0 + ', ' + (V.x0 + 196) + ')'); }
      else info.push(k + ' [' + b + ']' + (l || r || tp || bt ? ': runs off the picture (left ' + l + ', right ' + r + ', top ' + tp + ', bottom ' + bt + ' px)' : '') + (wl || wr ? '; the window cuts ' + [wl && wl + ' px at the left', wr && wr + ' px at the right'].filter(Boolean).join(' and ') : ''));
    }
    const o = add('things-in-view', bad, 'the two bubbles\' boxes (burbuja_a [' + T.burbuja_a.box + '], burbuja_b [' + T.burbuja_b.box + ']) are inside the picture and the window [' + V.x0 + ', ' + (V.x0 + 196) + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
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
    const nearestOf = (name, ok) => {                                                            // the least shift of a spot in u, in v or in z that passes
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a grown-up or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite: a grown-up, a child, a pigeon); a nearer dog is information
  {
    const bad = [], lines = [], fails = [], WHO = { adulto: 'a grown-up', nino: 'a child', coqui: 'the frog', perro: 'the dog' };
    // the least shift of a spot (u or v, steps of .01 up to 3 either way) of the layer that covers the frog, that leaves none of its pixels over the frog's (the pixels are moved on the picture, the depth by dv cos 30)
    const clearShift = (L, fi, ci, axis) => {
      const f = L[fi], c = L[ci], uvz = c.uvz, fp = new Map(f.px.filter(p => !p[2]).map(p => [p[1] * G.W + p[0], p[3]])), live = c.px.filter(p => !p[2]);
      for (let k = 1; k <= 300; k++) for (const sg of [1, -1]) {
        const d = sg * k * .01, u2 = axis === 'u' ? uvz[0] + d : uvz[0], v2 = axis === 'v' ? uvz[1] + d : uvz[1], [sx2, sy2] = scrUV(G, u2, v2, uvz[2]), dx = sx2 - c.sx, dy = sy2 - c.sy, dd = axis === 'v' ? d * COS : 0;
        if (!live.some(p => { const q = fp.get((p[1] + dy) * G.W + p[0] + dx); return q !== undefined && p[3] + dd > q + EPS; })) {
          const h = WIDTH[c.who] / 2, whole = sx2 - h >= V.x0 && sx2 + h - 1 <= V.x0 + 195;
          return axis + ' ' + r4(uvz[axis === 'u' ? 0 : 1]) + ' -> ' + r4(axis === 'u' ? u2 : v2) + ' (' + sgn(d) + (whole ? '' : ', but then it is outside the window') + ')';
        }
      }
      return axis + ': none within 3';
    };
    for (const m of MOMENTS.concat(EXTRA_MOMENTS)) {
      const L = PV.inspect[m].layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi];
      const best = new Map();                                                                    // per pixel: the nearest shown sprite pixel of the other layers
      L.forEach((l, i) => { if (i === fi) return; for (const p of l.px) if (!p[2]) { const k = p[1] * G.W + p[0], b = best.get(k); if (!b || b.plane < p[3]) best.set(k, { plane: p[3], at: l.at, who: l.who, kind: l.kind }); } });
      let hid = 0, cov = 0, dog = 0; const by = {}, who = {}, out = f.out, hidPx = [];
      for (const p of f.px) { if (p[2]) { hid++; hidPx.push([p[0], p[1]]); continue; } const b = best.get(p[1] * G.W + p[0]); if (b && b.plane > p[3] + EPS) { if (b.who === 'perro') dog++; else { cov++; by[b.at] = (by[b.at] || 0) + 1; const wk = WHO[b.who] || b.kind || 'a sprite'; who[wk] = (who[wk] || 0) + 1; } } }
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; const b = best.get(y * G.W + x); if (b && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) boxCov++; }
      const tg = hidPx.length ? await probes.tags(hidPx) : [], byTag = {}; tg.forEach(t => { byTag[t] = (byTag[t] || 0) + 1; });
      const hidCols = hidPx.length ? [...new Set(hidPx.map(p => p[0]))].sort((a, b) => a - b) : [];
      const total = f.px.length + out, shownBy = Object.entries(by).map(([k, v]) => k + ' ' + v).join(', '), whoTxt = Object.entries(who).map(([k, v]) => v + ' by ' + k).join(', ');
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + total + ' px, ' + hid + ' hidden by the set' + (hid ? ' (' + Object.entries(byTag).map(([k, v]) => k + ' ' + v).join(', ') + '; columns ' + hidCols.join(',') + ')' : '') + ', ' + cov + ' under a nearer person' + (cov ? ' (' + shownBy + '; ' + whoTxt + ')' : '') + ', ' + out + ' outside the picture, ' + dog + ' under the dog; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (hid || cov || out) {
        bad.push((EXTRA_MOMENTS.includes(m) ? 'moment ' + m + ' (a dev aid)' : 'moment ' + m) + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (hid + cov + out) + ' of his ' + total + ' px are not seen (' + hid + ' hidden by the set' + (hid ? ': ' + Object.entries(byTag).map(([k, v]) => k + ' ' + v).join(', ') + ', in columns ' + hidCols.join(',') : '') + ', ' + cov + ' under ' + (cov ? shownBy + ' (' + whoTxt + ')' : 'a person') + ', ' + out + ' outside the picture)');
        fails.push([m, fi, Object.keys(by)]);
      }
    }
    const badSpec = bad.filter(b => !b.includes('(a dev aid)'));
    const o = add('frog-seen', badSpec, 'the frog is seen whole in all 6 moments (a nearer dog aside): ' + lines.filter(l => !l.startsWith('m7')).join('; '), [badSpec.length + ' moment(s) where the frog is not seen whole:'].concat(badSpec.map(b => '  ' + b)));
    for (const [m, fi, culprits] of fails) {
      if (EXTRA_MOMENTS.includes(m)) continue;
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi), L = PV.inspect[m].layers;
      o.lines.push('       nearest passing, moment ' + m + ', move the frog: ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[specs[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
      for (const at of culprits) { const ci = L.findIndex(l => l.at === at); o.lines.push('       nearest passing, moment ' + m + ', move ' + at + ' ' + S[at].uv + ' (' + L[ci].s + ') alone off the frog: ' + ['u', 'v'].map(a => clearShift(L, fi, ci, a)).join('; ')); }
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 7. board-clear: in moments 3 and 4 nobody covers a pixel of the board's two pictures or of its two rows of hooks (what a person draws over them: the pixels of his sprite the set does not hide)
  {
    const wB = B.u1 - B.u0, hB = B.z1 - B.z0, half = wB / 2;
    const rect = (h, hu, fz) => { const u0 = B.u0 + h * half + hu[0] * half, u1 = B.u0 + h * half + hu[1] * half, z0 = B.z0 + fz[0] * hB, z1 = B.z0 + fz[1] * hB, sy = z => G.OY + (B.v * .5 - z * COS) * G.S; return [Math.floor(G.OX + u0 * G.S), Math.floor(sy(z1)), Math.ceil(G.OX + u1 * G.S) - 1, Math.ceil(sy(z0)) - 1]; };   // [x0, y0, x1, y1], pixels
    const REG = [['picture of the island', rect(0, BOARD.pic.hu, BOARD.pic.fz)], ['row of hooks of the island', rect(0, BOARD.hooks.hu, BOARD.hooks.fz)], ['picture of the city', rect(1, BOARD.pic.hu, BOARD.pic.fz)], ['row of hooks of the city', rect(1, BOARD.hooks.hu, BOARD.hooks.fz)]];
    const bad = [], lines = [], res = [];
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers;
      for (const l of L) {
        if (!l.who) continue;                                                                     // people: the frog included
        const shown = l.px.filter(p => !p[2]), hits = {};
        for (const [name, [x0, y0, x1, y1]] of REG) { const n = shown.filter(p => p[0] >= x0 && p[0] <= x1 && p[1] >= y0 && p[1] <= y1).length; if (n) hits[name] = n; }
        const top = Math.min(...l.px.map(p => p[1]));
        res.push({ moment: m, at: l.at, topRow: top, covers: hits });
        if (Object.keys(hits).length) bad.push('moment ' + m + ': ' + l.at + ' (' + l.s + ', top row ' + top + ') covers ' + Object.entries(hits).map(([k, v]) => v + ' px of the ' + k).join(', '));
      }
      lines.push('m' + m + ': the people\'s top rows ' + L.filter(l => l.who).map(l => l.at + ' ' + Math.min(...l.px.map(p => p[1]))).join(', '));
    }
    const o = add('board-clear', bad, 'in moments 3 and 4 nobody covers a pixel of the board\'s two pictures or of its two rows of hooks: ' + REG.map(([n, r]) => n + ' px ' + r[0] + '-' + r[2] + ' x ' + r[1] + '-' + r[3]).join(', ') + '; ' + lines.join('; '), [bad.length + ' person(s) over the board:'].concat(bad.map(b => '  ' + b)));
    o.regions = REG.map(([n, r]) => ({ region: n, pixels: r }));
    o.people = res;
    // information: the cards at repisa against the hooks and pictures (a sprite, not a person)
    const cards = PV.inspect[3].layers.find(l => l.kind === 'tarjetas'), over = REG.map(([n, [x0, y0, x1, y1]]) => n + ' ' + cards.px.filter(p => p[0] >= x0 && p[0] <= x1 && p[1] >= y0 && p[1] <= y1).length).join(', ');
    o.lines.push('       info, not a check: the three cards at repisa ' + [cards.sx, cards.sy] + ' (rows ' + Math.min(...cards.px.map(p => p[1])) + ' to ' + Math.max(...cards.px.map(p => p[1])) + ') over the regions: ' + over + ' px');
  }

  // 8. piraguero-head: the top 14 px of the piragüero's sprite at carro_pie (his head) are covered by neither the awning nor the cart (what the set draws nearer than him), nor by a nearer sprite
  {
    const bad = [], lines = [], res = [];
    const cartTopRow = Math.round(G.OY + (K.v - K.hd) * .5 * G.S - CART_TOP * COS * G.S);            // the cart's top at its far edge: rows at or below are the cart's body, above are the awning
    for (const m of [5, 6]) {
      const L = PV.inspect[m].layers, i = L.findIndex(l => l.at === 'carro_pie'), p0 = L[i], top = Math.min(...p0.px.map(p => p[1])), head = p0.px.filter(p => p[1] < top + HEAD_ROWS);
      const hid = head.filter(p => p[2]), tg = hid.length ? await probes.tags(hid.map(p => [p[0], p[1]])) : [], byTag = {};
      tg.forEach(t => { byTag[t] = (byTag[t] || 0) + 1; });
      const awning = hid.filter(p => p[1] < cartTopRow).length, cart = hid.length - awning;
      const sprBy = {}; let sprCov = 0;
      for (const p of head) { if (p[2]) continue; for (const [j, l] of L.entries()) { if (j === i) continue; const q = l.px.find(q => q[0] === p[0] && q[1] === p[1] && !q[2]); if (q && q[3] > p[3] + EPS) { sprCov++; sprBy[l.at] = (sprBy[l.at] || 0) + 1; break; } } }
      const rowsHid = hid.length ? [Math.min(...hid.map(p => p[1])), Math.max(...hid.map(p => p[1]))] : null;
      res.push({ moment: m, headRows: [top, top + HEAD_ROWS - 1], headPx: head.length, coveredBySet: hid.length, awning, cart, byPart: byTag, rowsCovered: rowsHid, coveredBySprites: sprCov });
      lines.push('m' + m + ' carro_pie ' + [p0.sx, p0.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ' (' + head.length + ' px): ' + hid.length + ' covered by the set (' + (hid.length ? awning + ' by the awning, ' + cart + ' by the cart; parts ' + Object.entries(byTag).map(([k, v]) => k + ' ' + v).join(', ') + '; rows ' + rowsHid.join(' to ') : 'none') + '), ' + sprCov + ' by a nearer sprite' + (sprCov ? ' (' + Object.entries(sprBy).map(([k, v]) => k + ' ' + v).join(', ') + ')' : ''));
      if (hid.length || sprCov) bad.push('moment ' + m + ': his head (' + head.length + ' px, rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ') is covered: ' + hid.length + ' px by the set (' + awning + ' awning, ' + cart + ' cart: ' + Object.entries(byTag).map(([k, v]) => k + ' ' + v).join(', ') + '; rows ' + (rowsHid || []).join(' to ') + ')' + (sprCov ? ', ' + sprCov + ' by ' + Object.keys(sprBy).join(', ') : ''));
    }
    const o = add('piraguero-head', bad, 'the top ' + HEAD_ROWS + ' rows of the piragüero\'s sprite at carro_pie ' + S.carro_pie.screen + ' are covered by neither the awning, the cart nor a sprite: ' + lines.join('; '), [bad.length + ' moment(s) where his head is covered:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {
      const M = PV.moment[5], i = M.layers.findIndex(l => l.at === 'carro_pie'), r = await PV.nearest(M.set, M.layers, i, 0, HEAD_ROWS);
      const cp = S.carro_pie.uv, flag = a => {
        const q = r.axis[a]; if (!q) return a + ': none within 3';
        let note = '';
        if (a === 'u') { const sx = scrUV(G, q.to, cp[1], 0)[0]; if (sx - 12 < V.x0 || sx + 11 > V.x0 + 195) note = ', but then he is outside the window (his column ' + sx + ', the window ends at ' + (V.x0 + 195) + ')'; }
        if (a === 'v' && q.to > K.v - K.hd) note = ', but then he stands inside the cart\'s footprint (v ' + r2(K.v - K.hd) + ' to ' + r2(K.v + K.hd) + '): the cart hides him from the waist down';
        return a + ' ' + cp[a === 'u' ? 0 : 1] + ' -> ' + q.to + ' (' + sgn(q.d) + note + ')';
      };
      o.lines.push('       nearest passing (his head clear of the set and of the sprites of moment 5), carro_pie ' + cp + ': ' + ['u', 'v'].map(flag).join('; ') + '; the awning\'s front edge and valance hang over rows ' + Math.min(...res.map(q => q.rowsCovered[0])) + ' to ' + Math.max(...res.map(q => q.rowsCovered[1])) + ' of his head at his spot, so no spot from v ' + r2(cp[1] + (r.axis.v ? -(r.axis.v.d) : -.6)) + ' to the cart\'s back edge (v ' + r2(K.v - K.hd) + ') clears it (the search goes ' + (r.axis.v ? r2(Math.abs(r.axis.v.d)) : 3) + ' either way of his spot)');
      for (const l of lines) o.lines.push('       ' + l);
    }
    o.heads = res;
  }

  // 9. frog-on-cart: the frog at carro_borde is whole (frog-seen) and covers no more than a quarter of the piragüero's box
  {
    const bad = [], lines = [], res = [];
    for (const m of [5, 6]) {
      const L = PV.inspect[m].layers, f = L.find(l => l.at === 'carro_borde'), p0 = L.find(l => l.at === 'carro_pie');
      const top = Math.min(...p0.px.map(q => q[1])), bx0 = p0.sx - WIDTH.adulto / 2, bx1 = p0.sx + WIDTH.adulto / 2 - 1, by0 = top, by1 = p0.sy - 1, area = WIDTH.adulto * (by1 - by0 + 1);     // his box: 24 wide, from his top ink row to his feet's row
      const inside = q => q[0] >= bx0 && q[0] <= bx1 && q[1] >= by0 && q[1] <= by1;
      const fAll = f.px.filter(inside).length, fShown = f.px.filter(q => !q[2] && inside(q)).length;
      const his = new Set(p0.px.filter(q => !q[2]).map(q => q[1] * G.W + q[0])), onHis = f.px.filter(q => !q[2] && his.has(q[1] * G.W + q[0])).length;
      const fbx0 = f.sx - 16, fbx1 = f.sx + 15, fby0 = f.sy - 25, fby1 = f.sy - 1, boxBox = Math.max(0, Math.min(bx1, fbx1) - Math.max(bx0, fbx0) + 1) * Math.max(0, Math.min(by1, fby1) - Math.max(by0, fby0) + 1);
      const frac = fShown / area;
      res.push({ moment: m, pirBox: [bx0, by0, WIDTH.adulto, by1 - by0 + 1], area, frogPxOverBox: fShown, fraction: r4(frac), frogPxOverHisPx: onHis, boxOverBox: boxBox, boxOverBoxFraction: r4(boxBox / area), frogHidden: f.px.filter(q => q[2]).length });
      lines.push('m' + m + ': his box [' + [bx0, by0, WIDTH.adulto, by1 - by0 + 1] + '] (' + area + ' px): the frog\'s drawn pixels over it ' + fShown + ' (' + (100 * frac).toFixed(1) + '%); over his own drawn pixels ' + onHis + '; his 32 x 25 box over it ' + boxBox + ' px (' + (100 * boxBox / area).toFixed(1) + '%); the frog\'s hidden pixels ' + f.px.filter(q => q[2]).length);
      if (frac > QUARTER) bad.push('moment ' + m + ': the frog covers ' + fShown + ' of the ' + area + ' px of the piragüero\'s box (' + (100 * frac).toFixed(1) + '%, most 25%)');
    }
    const o = add('frog-on-cart', bad, 'the frog at carro_borde ' + S.carro_borde.screen + ' covers no more than a quarter of the piragüero\'s box (by his drawn pixels over it): ' + lines.join('; '), [bad.length + ' moment(s) where the frog covers more than a quarter:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {
      const M = PV.moment[5], i = M.layers.findIndex(l => l.at === 'carro_borde');
      for (const l of lines) o.lines.push('       ' + l);
    } else o.lines.push('       info, not a check: ' + lines.join('; '));
    {                                                                                       // the other reading of "covers no more than a quarter of his box": the frog's 32 x 25 box over his 24 x 55 box
      const q = res[0], over = q.boxOverBoxFraction > QUARTER, uvz = S.carro_borde.uv, pir = PV.inspect[5].layers.find(l => l.at === 'carro_pie');
      let hint = '';
      if (over) for (let k = 1; k <= 300 && !hint; k++) for (const sg of [-1, 1]) {
        const d = sg * k * .01, sx2 = scrUV(G, uvz[0] + d, uvz[1], uvz[2])[0], w = Math.max(0, Math.min(q.pirBox[0] + WIDTH.adulto - 1, sx2 + 15) - Math.max(q.pirBox[0], sx2 - 16) + 1), h = Math.max(0, Math.min(q.pirBox[1] + q.pirBox[3] - 1, S.carro_borde.screen[1] - 1) - Math.max(q.pirBox[1], S.carro_borde.screen[1] - 25) + 1);
        if (w * h / q.area <= QUARTER) { hint = ' (by that reading, the nearest passing: carro_borde u ' + uvz[0] + ' -> ' + r4(uvz[0] + d) + ' (' + sgn(d) + '), his column ' + sx2 + ')'; break; }
      }
      o.lines.push('       info, not a check: read as the frog\'s 32 x 25 box over the piragüero\'s box ' + [q.pirBox] + ', it is ' + (100 * q.boxOverBoxFraction).toFixed(1) + '% (' + q.boxOverBox + ' of ' + q.area + ' px)' + (over ? ': MORE than a quarter' : ': within a quarter') + hint);
    }
    o.cover = res;
    o.whole = 'the frog\'s whole drawing at carro_borde is checked by frog-seen (moments 5 and 6)';
  }

  // 10. bubbles: the two bubbles are inside the picture and cover neither the frog nor a pigeon (the three pigeons of respaldo1 to 3 at their spots, whether or not a moment draws them: moment 7 draws them)
  {
    const bad = [], lines = [], ba = T.burbuja_a.box, bb = T.burbuja_b.box;
    const L = PV.inspect[7].layers, frog = L.find(l => l.who === 'coqui'), pig = L.filter(l => l.kind === 'paloma');
    const inRect = (b, p) => p[0] >= b[0] && p[0] < b[0] + b[2] && p[1] >= b[1] && p[1] < b[1] + b[3];
    const coverOf = (b, l) => l.px.filter(p => inRect(b, p)).length;
    const inside = b => b[0] >= 0 && b[1] >= 0 && b[0] + b[2] <= G.W && b[1] + b[3] <= G.H && b[0] >= V.x0 && b[0] + b[2] <= V.x0 + 196;
    lines.push('the frog at asiento4 ' + [frog.sx, frog.sy] + ': his drawn head top row ' + Math.min(...frog.px.map(p => p[1])) + '; burbuja_a [' + ba + '], burbuja_b [' + bb + '] (foot ' + BUBBLE.above + ' px above his head: bottom edge row ' + (ba[1] + ba[3]) + ')');
    if (!inside(ba) || !inside(bb)) bad.push('a bubble is outside the picture or the window');
    const fa = coverOf(ba, frog), fb = coverOf(bb, frog);
    if (fa || fb) bad.push('the bubbles cover ' + (fa + fb) + ' px of the frog (a ' + fa + ', b ' + fb + ')');
    const pcov = pig.map(l => ({ at: l.at, sx: l.sx, sy: l.sy, box: [l.sx - l.ax, Math.min(...l.px.map(p => p[1])), Math.max(...l.px.map(p => p[0])) - (l.sx - l.ax) + 1, l.sy - Math.min(...l.px.map(p => p[1]))], a: coverOf(ba, l), b: coverOf(bb, l), n: l.px.length }));
    for (const c of pcov) lines.push(c.at + ' ' + [c.sx, c.sy] + ' (a ' + c.n + ' px pigeon, rows ' + c.box[1] + ' to ' + (c.sy - 1) + ', columns ' + c.box[0] + ' to ' + (c.box[0] + c.box[2] - 1) + '): covered by burbuja_a ' + c.a + ' px, by burbuja_b ' + c.b + ' px');
    for (const c of pcov) if (c.a || c.b) bad.push('the bubbles cover ' + (c.a + c.b) + ' px of the pigeon at ' + c.at + ' ' + [c.sx, c.sy] + ' (a ' + c.a + ', b ' + c.b + ')');
    const o = add('bubbles', bad, 'both bubbles (a [' + ba + '], b [' + bb + ']) are inside the picture and the window and cover neither the frog nor a pigeon: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {
      for (const l of lines) o.lines.push('       ' + l);
      // the nearest value that passes: the foot higher above his head (the least gap g, in px, that clears every pigeon pixel), the horizontal centring kept; and the least a pigeon's spot would move down the back (z) to clear the bubbles at 3 px
      let g = BUBBLE.above, found = null;
      for (; g <= 200; g++) { const ya = frog.sy + frogTop - g - BUBBLE.h, A2 = [ba[0], ya, ba[2], ba[3]], B2 = [bb[0], ya, bb[2], bb[3]]; if (ya >= 0 && !pig.some(l => coverOf(A2, l) || coverOf(B2, l))) { found = { g, ya }; break; } }
      const feet = S.respaldo1.screen[1] - 1, endRow = ba[1] + ba[3] - 1;
      o.lines.push('       the size of the pigeon does not matter: its feet are on row ' + feet + ' at respaldo1 to 3 and the bubbles end on row ' + endRow + ', so a pigeon taller than ' + (feet - endRow) + ' px at respaldo1 (column ' + S.respaldo1.screen[0] + ', under burbuja_a, columns ' + ba[0] + ' to ' + (ba[0] + ba[2] - 1) + ') or at respaldo2 (column ' + S.respaldo2.screen[0] + ', under burbuja_b, columns ' + bb[0] + ' to ' + (bb[0] + bb[2] - 1) + ') is covered; respaldo3 (column ' + S.respaldo3.screen[0] + ') is clear');
      o.lines.push('       nearest passing: the foot ' + (found ? found.g + ' px above his head instead of ' + BUBBLE.above + ' (the bubbles\' top row ' + found.ya + ', bottom edge ' + (found.ya + BUBBLE.h) + ')' : 'none within 200 px') + ' with the centring kept; sideways no shift clears both pigeons while the bubbles stay centred on him (the two pigeons at respaldo1 and respaldo2 span columns ' + Math.min(...pcov.map(c => c.box[0])) + ' to ' + Math.max(...pcov.map(c => c.box[0] + c.box[2] - 1)) + ' in rows ' + Math.min(...pcov.map(c => c.box[1])) + ' to ' + (Math.max(...pcov.map(c => c.sy)) - 1) + ')');
    }
    o.boxes = { burbuja_a: ba, burbuja_b: bb, frogHeadTopRow: frog.sy + frogTop, pigeons: pcov };
  }

  return OUTS;
}
