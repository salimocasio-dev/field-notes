#!/usr/bin/env node
'use strict';
/* El mostrador's sheet (version 3: pass 3 of the orchestrator's brief): writes docs/proyecto/pixel/mostrador-sheet.json from mostrador-set.html and the design (the orchestrator's mostrador-spec, with its v2 changes
   and the calle state), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/mostrador-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set twice: donde=dentro (window.MOSTRADOR.CD: the room's constants) and donde=calle (CF,
   colmado-fuera.js: the shop front), projects every world point with the engine's own project() (pp-engine.js), and writes the spots, things, view, shadows and the depth rule.
   Every place the room exports (CD.GOODS, CD.SILLA, CD.NEVERA, CD.CX0 ..) is read from the set, never typed again from the design.
   Pass 3 adds the alternatives (people who are never in the same picture), the frog's second front place coqui.frente2, the children at the door as a group whose heads must show,
   the frog on the counter that must not overlap the register's body, the calle's sideways distance and the scale, and the checks that read the PREVIEW's moments (mostrador-preview.html,
   PREVIEW.inspect): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with MOSTRADOR_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'mostrador-sheet.json');
const BASE = process.env.MOSTRADOR_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/mostrador-set.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

// every request to BASE is answered from the files of this tree
const serve = route => {
  const u = new URL(route.request().url()), f = path.join(REPO, decodeURIComponent(u.pathname));
  if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
  route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
};
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

// the standing figure is 53 drawn rows (mkPersona, the design's number); at least 28 of them above the counter's top back edge when he is seen from the thighs up
const PERSON = { rows: 53, minAbove: 28 };
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_APART = 10;                                    // px between two people's feet on screen
const CLEAR = 4;                                         // px a spot keeps from the pixels of the register, the freezer or the chair
// what the freezer is drawn with: the spots of story 38 (nevera = 1). The other counter spots (the tray, the dish, the malts ...) belong to stories without it
const NEVERA_STORY = ['coqui.mostrador', 'limber_pepe', 'limber_lejos'];
// v3: the spots whose numbers the brief gives are final: a spot of these that is nearer than CLEAR px to the register, the freezer or the chair is NOT moved (the old rule moved it the least distance):
// the check spots-clear fails and reports the numbers and the nearest x that would pass
const FIXED = new Set(['nino.frente', 'coqui.frente', 'coqui.frente2', 'coqui.mostrador', 'limber_lejos', 'ninos_puerta.1', 'ninos_puerta.2', 'ninos_puerta.3']);
// v3: sprite boxes (width in px, the feet's spot in the middle): the frog 32, a grown-up 24, a child 24; two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const WIDTH = { coqui: 32, adulto: 24, nino: 24 }, UPDOWN = 12;
// v3: the alternatives: spots of one body (or of a story's other version) that are never in the same picture; the people-apart check does not compare them.
// ALT: groups whose members are alternatives of each other. ALT_VS_GROUP: spots that are alternatives of every member of a group (a group is together: its members are compared with each other)
const ALT = [['pepe.mostrador', 'pepe.silla'], ['coqui.mostrador', 'coqui.frente', 'coqui.frente2'], ['abuela.frente', 'abuela.silla'], ['cliente', 'abuela.frente'], ['coqui.frente2', 'cliente'], ['nino.frente', 'nino.puerta_dentro']];
const ALT_VS_GROUP = { ninos_puerta: ['nino.puerta_dentro', 'cola1', 'cola2'] };
const HEAD_ROWS = 14;                                    // the head of a child: the top 14 rows of the sprite
const CALLE_SIDEWAYS = 28;                               // abuela.acera and coqui.acera: px apart sideways
const CALLE_X0 = 22;                                     // the calle view's x0: accepted by the orchestrator, final
const ABUELA_BOX = { w: 24, h: 50 };                     // abuela standing: 24 wide (the brief's grown-up width), 50 rows (mkAbuela draws rows 0 to 49), her feet's spot in the middle of the bottom edge
const SHELF_TOL = .02;                                   // a pixel of the register is the body's when its world x (read back from the baked depth) is not more than this right of the body's right side

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  const load = async (q) => { await page.goto(PAGE + '?' + q); };
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);

  /* ---- inside the shop: the room's constants, and the pixels of the register, the freezer and the chair (all drawn: nevera = 1, tags = 1) ---- */
  await load('props=1&tags=1&nevera=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(MOSTRADOR.CD)) if (typeof v !== 'function') o[k] = v;
    const px = {}; for (const n of ['caja', 'nevera', 'silla']) px[n] = [];
    for (let i = 0; i < TAGS.length; i++) if (px[TAGS[i]]) px[TAGS[i]].push([i % W, (i / W) | 0]);
    // the register's pixels, each with the world x of the point it draws (read back from the baked depth): the body (and its head) ends at x = RG.x1, the side shelf is right of it
    const COS = Math.sqrt(3) / 2, cajaX = [];
    for (const [X, Y] of px.caja) { const i = Y * W + X, b = (X + .5 - OX) / S, syp = (Y + .5 - OY) / S, z = (DEPTH.z[i] - 2 * COS * syp) / 2, a = 2 * (syp + z * COS); cajaX.push((a + b) * Math.SQRT2 / 2); }
    return { CD: o, scene: PP_SCENE, W, H, S, OX, OY, px, cajaX };
  });
  const dentro = await makeDentro(G, proj);
  // the checks that read the set's own pixels: every state of the set (hora x atras x nevera), goods drawn (props=1), each pixel tagged by the part that drew it (tags=1)
  const probes = await probeSets(page, dentro, load);

  /* ---- the shop front, from the street ---- */
  await load('donde=calle&hora=manana&puerta=shut&tags=1');
  const GC = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(CF)) if (typeof v !== 'function') o[k] = v;
    // the scale without its pole, its arm and the chain up to it (the dial, the chains and the plate): the pixels of part pesa not right of the dial's right edge and not above its top (as frutas' sheet)
    const D = CF.PESA_DIAL, dp = project(D.x, D.y, D.z), right = Math.floor(dp.sx) + 7, top = Math.floor(dp.sy) - 7, pesa = [];
    for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'pesa') { const x = i % W, y = (i / W) | 0; if (x <= right && y >= top) pesa.push([x, y]); }
    return { CF: o, scene: PP_SCENE, W, H, S, OX, OY, pesa };
  });
  const calle = await makeCalle(GC, proj, page);
  const callePix = await probeCalle(page, calle, load);

  const sheet = dentro;
  sheet.calle = calle;
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const PVD = await previewData(browser, errs);
  const results = checks(dentro, probes, calle, callePix, G, PVD, GC);
  sheet.checks = { person: PERSON, results };
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


/* ---------- the preview's moments: mostrador-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/mostrador-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const out = {};
  for (const m of [1, 2, 3, 4, 5, 6]) out[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m);
  await p.close();
  return out;
}

/* the distance, in pixels, from a spot's feet pixel (column sx, row sy - 1) to the nearest pixel the set draws for a part */
const feet = ([sx, sy]) => [sx, sy - 1];
const nearest = (f, pix) => { let m = 1e9; for (const [x, y] of pix) { const d = Math.hypot(x - f[0], y - f[1]); if (d < m) m = d; } return m; };
// which objects a spot is kept clear of: a counter-top spot (z = CH) the register, and in story 38 the freezer; a floor spot in front of the counter the chair (not abuela.silla)
const obstaclesOf = (name, w, CD) => w[2] === CD.CH ? ['caja'].concat(NEVERA_STORY.includes(name) ? ['nevera'] : []) : (w[1] > CD.CY1 && name !== 'abuela.silla' ? ['silla'] : []);

/* ---------- the sheet: inside the shop ---------- */
async function makeDentro(G, proj) {
  const CD = G.CD, CH = CD.CH, SZ = CD.SZ, GOODS = CD.GOODS;
  const P1 = async p => (await proj([p]))[0];
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const DY = (CD.PD0 + CD.PD1) / 2;                                                    // the street door's middle, on the left wall (y)

  /* ---- spots: the ground (or the counter top, or the seat) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, what]
  const person = (name, w, what) => D.push([name, w, 'person', what]);
  const onCounter = (name, x, y, what) => D.push([name, [x, y, CH], 'counter', what]);
  person('pepe.mostrador', [3.6, 1.15, 0], 'don Pepe\'s usual place, behind the counter');
  for (const [k, , x] of GOODS) person('pepe.estante.' + k, [x, .95, 0], 'don Pepe in front of the shelves, reaching up to ' + k);
  person('pepe.atras', [.7, .6, 0], 'don Pepe at the back door');
  person('pepe.silla', [5.2, 1.15, 0], 'don Pepe sitting behind the counter with his fan (story 38)');
  person('coqui.frente', [4.4, 3.5, 0], 'the frog on the floor, in front of the counter, in story 36 (with abuela at abuela.frente)');
  person('coqui.frente2', [3.4, 3.7, 0], 'the frog\'s place on the floor whenever a child stands at nino.frente (story 37); an alternative of coqui.frente');
  person('coqui.mostrador', [3.45, 2.38, CH], 'the frog\'s one place on the counter top, right of the register (it casts no shadow); it may overlap the register\'s side shelf, not its body');
  person('abuela.frente', [3.0, 4.1, 0], 'abuela standing in front of the counter');
  person('abuela.silla', [CD.SILLA[0], CD.SILLA[1], .45], 'abuela sitting in the waiting chair (CD.SILLA); z .45 is the chair\'s seat top (colmado-dentro.js chairs()); the sitting sprite is anchored by her lap, rules.anchor');
  person('nino.frente', [5.2, 3.6, 0], 'Luis or Carmen at the counter');
  person('nino.puerta_dentro', [.7, 5.4, 0], 'Carmen looking out of the street door, inside');
  person('cliente', [3.15, 3.75, 0], 'the customer being served (v3b: (3.15, 3.75, 0))');
  person('cola1', [2.3, 4.2, 0], 'waiting, first');
  person('cola2', [1.6, 4.7, 0], 'waiting, second');
  person('puerta', [.45, DY, 0], 'just inside the street door');
  person('fuera', [-.35, DY, 0], 'on the pavement, seen through the street door (no shadow)');
  [[.6, 4.0, 'the one behind'], [1.0, 5.05, 'in front, left'], [1.8, 4.5, 'in front, right']].forEach(([x, y, where], i) => person('ninos_puerta.' + (i + 1), [x, y, 0], 'child ' + (i + 1) + ' of the three just inside the street door, ' + where + ' (story 38: they wait there, each with a coin); group ninos_puerta: all three heads must show (the head is the top ' + HEAD_ROWS + ' rows)'));
  onCounter('bandeja', 5.6, 2.38, 'the tray of quesitos');
  onCounter('platillo', 5.0, 2.15, 'the coin dish');
  onCounter('cosa_a', 3.6, 2.5, 'the first of the two things in front of the frog');
  onCounter('cosa_b', 4.25, 2.5, 'the second of the two things in front of the frog');
  onCounter('compra', 4.4, 2.5, 'where a thing taken down from a shelf is set');
  onCounter('monedas', 4.6, 2.62, 'the first of Carmen\'s coins; the row runs towards +x (dir), .22 apart (step)');
  onCounter('maltas', 5.95, 2.15, 'the malts');
  onCounter('limber_pepe', 4.75, 2.45, 'a límber at don Pepe\'s end');
  onCounter('limber_lejos', 3.95, 2.6, 'a límber at the frog\'s end');
  onCounter('bolsa', 4.45, 2.55, 'the bag being packed');
  for (const [k, s, x] of GOODS) D.push(['estante.' + k, [x, .19, SZ[s] + .06], 'shelf', 'where ' + k + ' stands on its shelf (the plank\'s top)']);

  /* ---- a spot that now collides with the register, the freezer or the chair moves the least distance along the counter that clears it by CLEAR px ----
     collide: the spot's feet pixel is nearer than CLEAR px to a pixel the set draws for that object (part 'caja', 'nevera' in nevera = 1, 'silla'). A counter-top spot is tested against
     the register, and, when it is a spot of story 38 (the only story with the freezer), against the freezer; a floor spot in front of the counter against the chair (not abuela.silla: she
     sits in it). The move is along x (the counter's length), by steps of .01, to whichever side is nearer; a counter-top spot stays on the counter top */
  const moved = [], failing = [];
  const clearance = (name, w, q) => { const f = feet(scr(q)); const o = obstaclesOf(name, w, CD); return o.length ? Math.min(...o.map(n => nearest(f, G.px[n]))) : Infinity; };
  let pr = await proj(D.map(d => d[1]));
  for (let i = 0; i < D.length; i++) {
    const [name, w, kind] = D[i];
    if (kind === 'shelf' || clearance(name, w, pr[i]) >= CLEAR) continue;
    const cands = []; for (let k = 1; k <= 160; k++) for (const s of [-1, 1]) cands.push([w[0] + s * k * .01, w[1], w[2], s * k * .01]);
    const cp = await proj(cands.map(c => c.slice(0, 3)));
    const onTop = c => w[2] !== CH || (c[0] >= CD.CX0 && c[0] <= CD.CX1);
    const j = cands.findIndex((c, n) => onTop(c) && clearance(name, c, cp[n]) >= CLEAR);
    if (FIXED.has(name)) {                                                            // a number of the brief: not moved; reported by spots-clear with the nearest x that would pass
      const jo = cands.findIndex((c, n) => j >= 0 && Math.sign(c[3]) === -Math.sign(cands[j][3]) && onTop(c) && clearance(name, c, cp[n]) >= CLEAR);
      failing.push({ spot: name, at: W4(w), clear: r2(clearance(name, w, pr[i])), against: obstaclesOf(name, w, CD).join(' + '), nearest: j < 0 ? null : { x: r4(cands[j][0]), dx: r4(cands[j][3]) }, otherSide: jo < 0 ? null : { x: r4(cands[jo][0]), dx: r4(cands[jo][3]) } });
      continue;
    }
    if (j < 0) throw new Error('no place along the counter clears ' + name);
    // the nearest clear place on the other side, for the record
    const jo = cands.findIndex((c, n) => Math.sign(c[3]) === -Math.sign(cands[j][3]) && onTop(c) && clearance(name, c, cp[n]) >= CLEAR);
    const was = w.slice();
    D[i][1] = [r4(cands[j][0]), w[1], w[2]];
    moved.push({ spot: name, from: W4(was), to: W4(D[i][1]), dx: r4(cands[j][3]), clearBefore: r2(clearance(name, was, pr[i])), clearAfter: r2(clearance(name, D[i][1], cp[j])), against: obstaclesOf(name, w, CD).join(' + '),
      otherSide: jo < 0 ? null : { to: r4(cands[jo][0]), dx: r4(cands[jo][3]) } });
  }
  pr = await proj(D.map(d => d[1]));
  const spots = {};
  D.forEach((d, i) => {
    const q = pr[i];
    spots[d[0]] = { world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2], what: d[3] };
  });
  for (const m of moved) spots[m.spot].moved = { from: m.from, dx: m.dx, why: 'it was ' + m.clearBefore + ' px from the ' + m.against + '\'s pixels; now ' + m.clearAfter + ' px (needs ' + CLEAR + ')' };
  spots['monedas'].dir = [1, 0, 0]; spots['monedas'].step = .22;
  spots['pepe.fuera'] = { drawn: false, kind: 'person', what: 'don Pepe gone through the back door: not drawn' };
  // keep the design's order: pepe.fuera after pepe.atras
  const order = Object.keys(spots), pf = order.indexOf('pepe.fuera'), pa = order.indexOf('pepe.atras');
  order.splice(pf, 1); order.splice(pa + 1, 0, 'pepe.fuera');
  const spotsOrdered = Object.fromEntries(order.map(k => [k, spots[k]]));

  /* ---- things he can touch ---- */
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  const T = async (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: await boxOf(world), what }, extra);
  const SL = CD.SILLA;
  const things = {
    nevera: await T(CD.NEVERA, 'the little freezer on the counter, only when nevera = 1: CD.NEVERA, the box colmado-dentro.js draws', { when: 'nevera = 1' }),
    mostrador: await T([CD.CX0, CD.CY0, 0, CD.CX1, CD.CY1, CH], 'the counter, a poke'),
    puerta: await T([0, CD.PD0, 0, .02, CD.PD1, CD.DH], 'the street door, a poke'),
    silla: await T([SL[0] - .4, SL[1] - .4, 0, SL[0] + .4, SL[1] + .4, 1.05], 'the waiting chair: a box round CD.SILLA, .8 wide and 1.05 high'),
  };
  for (const k of ['leche', 'pan', 'mantequilla', 'queso', 'cafe', 'arroz', 'azucar', 'jugo', 'habichuelas', 'bolsa', 'limber_a', 'limber_b', 'quesitos', 'pepe', 'abuela', 'luis', 'carmen', 'senora', 'senor', 'ninos', 'coqui', 'si', 'no']) things[k] = 'sprite';

  /* ---- the view ---- */
  const vq = await P1([3.2, 2.9, 0]), vs = [r2(vq[0]), r2(vq[1])], vx0 = Math.max(0, Math.min(G.W - 196, Math.round(vs[0] - 98)));
  const views = { dentro: { world: [3.2, 2.9, 0], screen: vs, zoom: 1, x0: vx0, region: [vx0, 0, 196, 216], what: 'inside the shop: the 196 x 216 window over the 240 x 216 picture, centred on this point (x0 = clamp(round(sx - 98), 0, 44)); donde=calle has its own picture and view (calle.views.calle)' } };

  const groups = { ninos_puerta: ['ninos_puerta.1', 'ninos_puerta.2', 'ninos_puerta.3'] };
  const sc = G.scene;
  const sheet = {
    scene: 'mostrador',
    made: 'node docs/proyecto/pixel/mostrador-sheet-make.js, from mostrador-set.html (window.MOSTRADOR.CD, CF) and the design of El mostrador (version 2, with the calle state, and the orchestrator\'s pass 3). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      spot: 'a spot is a world point of the feet (z 0: the floor; z 1: the counter top; z .45: the seat) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), 46 sitting (a 49-row canvas); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a small thing: its bottom middle on the point',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      person: 'for the check "seen from the thighs up": a person is ' + PERSON.rows + ' rows tall (the standing figure\'s drawn rows), at least ' + PERSON.minAbove + ' of them above the counter\'s top back edge at his column',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      clear: 'a spot keeps ' + CLEAR + ' px from the pixels the set draws for the register (part caja), the freezer (part nevera, nevera = 1) and the chair (part silla): the distance from the spot\'s feet pixel (column sx, row sy - 1) to the nearest such pixel. A spot of the design that was nearer moved along x by the least step of .01 that clears it: spots[name].moved says from where',
    },
    setKey: {
      params: { donde: { values: ['dentro', 'calle'] }, hora: { values: ['manana', 'tarde'] }, atras: { values: ['shut', 'open'], only: 'dentro' }, nevera: { values: [0, 1], only: 'dentro' }, puerta: { values: ['shut', 'open'], only: 'calle', note: 'the shop door seen from the street' }, props: { values: [0, 1], note: 'props=1 draws stand-in goods on the shelves for readers\' renders; the game uses 0 and draws the goods as sprites' } },
      key: 'dentro: hora + atras + nevera, e.g. "manana-shut-0"; calle: hora + puerta, e.g. "manana-shut"',
      baked: ['manana', 'tarde'].flatMap(h => ['shut', 'open'].flatMap(a => [0, 1].map(n => '?donde=dentro&hora=' + h + '&atras=' + a + '&nevera=' + n))),
    },
    things,
    spots: spotsOrdered,
    groups,
    alternatives: {
      groups: ALT,
      vsGroup: ALT_VS_GROUP,
      what: 'spots that are never in the same picture, so the people-apart and sprites-apart checks do not compare them: each list of groups is alternatives of each other (one body has one place at a time; cliente and abuela.frente: abuela is the customer of story 36, the señora of story 38 stands at cliente; coqui.frente2 and cliente never stand together: the frog of story 37 has no customer); vsGroup: the spots listed are alternatives of the whole group (ninos_puerta is together: its three children are compared with each other, never with these)',
    },
    notes: [
      'bandeja, platillo and maltas stay where the design has them: they belong to stories without the freezer (nevera = 0), which is why they may lie under the freezer\'s footprint when nevera = 1 (see the info line of counter-spots-on-top)',
      'v3: the spots whose numbers the orchestrator gave (nino.frente, coqui.frente, coqui.frente2, coqui.mostrador, limber_lejos, cliente, ninos_puerta.1 to .3, the calle spots) are final and are not moved by the old clearance rule; spots-clear reports one that is nearer than ' + CLEAR + ' px and the nearest x that would pass',
      'the calle view\'s x0 ' + CALLE_X0 + ' is accepted by the orchestrator and final (views.calle.final)',
    ],
    views,
    moved,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so the counter hides don Pepe\'s legs and nothing behind him hides him.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón\'s front; the same test for people, things on the counter and goods on the shelves',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, pepe: .35, abuela: .35, senora: .35, senor: .35, luis: .28, carmen: .28, ninos: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)',
      none: ['pepe.fuera', 'fuera', 'gallo'],
      onCounter: 'the frog on the counter top (z 1) casts none: the counter top is not ground in colmado-dentro.js (no slab), so a shadow has nothing to land on, and one cast at the floor under him would show in front of the counter',
    },
  };
  Object.defineProperty(sheet, 'failing', { value: failing, enumerable: false });      // for the checks only, not in the file
  return sheet;
}

/* ---------- the sheet: the shop front, from the street (donde=calle) ---------- */
async function makeCalle(G, proj, page) {
  const CF = G.CF, sc = G.scene;
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const gx = (CF.AX0 + CF.AX1) / 2;
  const D = [
    ['abuela.acera', [1.2, 2.7, 0], 'person', 'abuela on the pavement in front of the door (v3: (1.2, 2.7, 0))'],
    ['coqui.acera', [3.0, 2.9, 0], 'person', 'the frog on the pavement, right of abuela (v3: (3.0, 2.9, 0))'],
    ['puerta_calle', [1.65, .4, 0], 'door', 'where they go in: the middle of the shop door (x = the middle of CF.D0 .. CF.D1), on the pavement at the wall'],
    ['gallo', [gx, CF.AY, CF.AZ0], 'small', 'the rooster on the awning\'s front edge, at its middle (x = the middle of CF.AX0 .. CF.AX1, y = CF.AY, z = CF.AZ0); a small sprite, no shadow'],
  ];
  const pr = await proj(D.map(d => d[1]));
  const spots = {};
  D.forEach((d, i) => { spots[d[0]] = { world: W4(d[1]), screen: scr(pr[i]), depth: r4(pr[i][2]), scale: 1, kind: d[2], what: d[3] }; });
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  // the door and the sign over it: the sign is a board 0.5 wider than the door on each side (colmado-fuera.js hSign: x D0 - .5 .. D1 + .5, z DH + .2 .. DH + .85), on the wall y = 0
  const cw = [CF.D0 - .5, 0, 0, CF.D1 + .5, 0, CF.DH + .85];
  const things = { colmado: { set: true, world: W4(cw), box: await boxOf(cw), what: 'the shop front\'s door together with the sign over it: the screen box of the wall rectangle x CF.D0 - .5 .. CF.D1 + .5, z 0 .. CF.DH + .85 (the sign\'s top)' } };
  // the view: x0 22, accepted by the orchestrator and final (v3). The window [22, 218) holds the calle spots and the colmado box: calle-in-view checks it
  const x0 = CALLE_X0;
  const views = { calle: { final: true, zoom: 1, x0, region: [x0, 0, 196, 216], what: 'FINAL (accepted by the orchestrator): the 196 x 216 window over the 240 x 216 calle picture at x0 ' + x0 + '; the check calle-in-view holds every calle spot and the colmado box inside it' } };
  return {
    what: 'the state donde=calle: the shop front from the street (colmado-fuera.js, drawn by mostrador-set.html?donde=calle); its own origin, picture and view. The depth rule, the anchors and the shadows are the same as inside (the top level of this sheet)',
    origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    setKey: { params: { hora: { values: ['manana', 'tarde'] }, puerta: { values: ['shut', 'open'] } }, key: 'hora + puerta, e.g. "manana-shut"', baked: ['manana', 'tarde'].flatMap(h => ['shut', 'open'].map(p => '?donde=calle&hora=' + h + '&puerta=' + p)) },
    spots, things, views,
    shadows: { byCharacter: { abuela: .35, coqui: .45 }, none: ['gallo', 'puerta_calle'], at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for abuela and the frog on the pavement' },
    constants: { 'CF.D0': CF.D0, 'CF.D1': CF.D1, 'CF.DH': CF.DH, 'CF.AX0': CF.AX0, 'CF.AX1': CF.AX1, 'CF.AY': CF.AY, 'CF.AZ0': CF.AZ0, 'CF.PAVE': CF.PAVE },
  };
}

/* ---------- the checks that read the set's pixels: every state of the set ---------- */
async function probeSets(page, sheet, load) {
  const S = sheet.spots, R = [];
  const goods = Object.keys(S).filter(k => k.startsWith('estante.'));
  const pix = [];                                                            // the pixel the point is in, and the pixel at the rounded point
  for (const k of goods) { const sp = S[k].screen; pix.push({ k, rounded: sp[1] * 240 + sp[0] }); }
  // exact projection (floor) of each shelf place: the pixel the point is really in
  const ex = await page.evaluate(ws => ws.map(w => { const q = project(w[0], w[1], w[2]); return (Math.floor(q.sy)) * W + Math.floor(q.sx); }), goods.map(k => S[k].world));
  pix.forEach((p, i) => { p.exact = ex[i]; });
  const pepes = Object.keys(S).filter(k => k === 'pepe.mostrador' || k.startsWith('pepe.estante.')).map(k => ({ k, cx: S[k].screen[0], row: S[k].screen[1], d: S[k].depth }));
  for (const hora of ['manana', 'tarde']) for (const atras of ['shut', 'open']) for (const nevera of [0, 1]) {
    await load('props=1&tags=1&donde=dentro&hora=' + hora + '&atras=' + atras + '&nevera=' + nevera);
    const r = await page.evaluate(arg => {
      const out = { goods: {}, bbox: {}, pepes: {} };
      for (const p of arg.pix) out.goods[p.k] = [TAGS[p.exact], TAGS[p.rounded]];
      for (const name of ['nevera', 'silla', 'mostrador', 'puerta', 'caja']) {
        let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
        for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === name) { const x = i % W, y = (i / W) | 0; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
        out.bbox[name] = x1 < 0 ? null : [x0, y0, x1, y1];
      }
      const T30 = Math.tan(Math.PI / 6);
      for (const p of arg.pepes) {
        const hid = []; for (let k = 0; k < arg.rows; k++) { const Y = p.row - arg.rows + k, plane = p.d + (p.row - (Y + .5)) * T30 / DEPTH.S; hid.push(DEPTH.z[Y * W + p.cx] > plane + arg.bias ? 1 : 0); }
        let edge = -1; for (let y = 0; y < H; y++) if (TAGS[y * W + p.cx] === 'mostrador') { edge = y; break; }
        out.pepes[p.k] = { hidden: hid.join(''), edge };
      }
      return out;
    }, { pix, pepes, rows: PERSON.rows, bias: BIAS });
    R.push({ hora, atras, nevera, ...r });
  }
  return R;
}

// the calle set: the pixel the rooster's point is in, and the ones above and below it (part tags)
async function probeCalle(page, calle, load) {
  const out = {};
  for (const hora of ['manana', 'tarde']) for (const puerta of ['shut', 'open']) {
    await load('donde=calle&tags=1&hora=' + hora + '&puerta=' + puerta);
    out[hora + '-' + puerta] = await page.evaluate(w => {
      const q = project(w[0], w[1], w[2]), at = (x, y) => TAGS[Math.floor(y) * W + Math.floor(x)];
      return { gallo: [at(q.sx, q.sy), at(q.sx, q.sy + 1), at(q.sx, q.sy - 1)] };
    }, calle.spots.gallo.world);
  }
  return out;
}

// the screen point of a world point on this sheet (the same arithmetic as pp-engine.js project, rounded to a pixel)
function scr3(sheet, x, y, z) {
  const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, OX = sheet.picture[0] / 2 + sheet.origin.originX, OY = sheet.picture[1] / 2 + sheet.origin.originY;
  return [Math.round(OX + (x - y) / R2 * sheet.S), Math.round(OY + ((x + y) / R2 * .5 - z * COS) * sheet.S)];
}
// the nearest place along x or y of a spot's world point (steps of .01, up to 3) where ok(screen x, screen y) holds: the hits at the least distance, as text. For a failure's report only: the brief's number is kept
function nearestPass(sheet, spot, ok) {
  const w = sheet.spots[spot].world;
  for (let k = 1; k <= 300; k++) {
    const hits = [];
    for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); const [sx, sy] = scr3(sheet, q[0], q[1], q[2]); if (ok(sx, sy, q)) hits.push((ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')'); }
    if (hits.length) return hits.join(' or ');
  }
  return 'none within 3';
}

function checks(sheet, probes, calle, callePix, G, PVD, GC) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.dentro, OUTS = [];
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const at = Object.entries(S).filter(([, s]) => s.screen);                         // the spots that have a point (pepe.fuera is not drawn)
  const [x0] = V.region;

  // 1. every spot's screen point is inside the picture and inside the dentro view's window
  {
    const bad = at.filter(([, s]) => s.screen[0] < 0 || s.screen[0] >= sheet.picture[0] || s.screen[1] < 0 || s.screen[1] >= sheet.picture[1]).map(([k, s]) => k + ' ' + s.screen + ' outside the picture');
    const out = at.filter(([, s]) => s.screen[0] < x0 || s.screen[0] >= x0 + 196 || s.screen[1] < 0 || s.screen[1] >= 216).map(([k, s]) => k + ' ' + s.screen + ' outside the dentro window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    add('spots-in-view', bad.concat(out), at.length + ' spot points (every spot but pepe.fuera) inside the ' + sheet.picture.join(' x ') + ' picture and the dentro window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)', ['spots outside:'].concat(bad, out).map((l, i) => i ? '  ' + l : l));
  }

  // 2. no two people who are on screen together in a story closer than MIN_APART px: don Pepe at pepe.mostrador (or sitting at pepe.silla, story 38), the frog at coqui.mostrador
  //    (or at coqui.frente), a customer at cliente, cola1, cola2, abuela at abuela.frente or abuela.silla, a child at nino.frente or nino.puerta_dentro, the three ninos_puerta.
  //    One body has one place at a time: the alternatives are not compared. pepe.atras and pepe.estante.* are passing places and are not compared
  {
    const TOGETHER = ['pepe.mostrador', 'pepe.silla', 'coqui.mostrador', 'coqui.frente', 'coqui.frente2', 'cliente', 'cola1', 'cola2', 'abuela.frente', 'abuela.silla', 'nino.frente', 'nino.puerta_dentro', 'ninos_puerta.1', 'ninos_puerta.2', 'ninos_puerta.3'];
    // the sheet's alternatives: groups of spots that are alternatives of each other, and spots that are alternatives of a whole group (alternatives.groups, alternatives.vsGroup)
    const AL = sheet.alternatives, alt = (a, b) => AL.groups.some(g => g.includes(a) && g.includes(b)) || Object.entries(AL.vsGroup).some(([gn, list]) => (sheet.groups[gn].includes(a) && list.includes(b)) || (sheet.groups[gn].includes(b) && list.includes(a)));
    const near = [], all = [];
    for (let i = 0; i < TOGETHER.length; i++) for (let j = i + 1; j < TOGETHER.length; j++) {
      const a = TOGETHER[i], b = TOGETHER[j]; if (alt(a, b)) continue;
      const d = Math.hypot(S[a].screen[0] - S[b].screen[0], S[a].screen[1] - S[b].screen[1]);
      all.push([a, b, d]); if (d < MIN_APART) near.push([a, b, d]);
    }
    near.sort((p, q) => p[2] - q[2] || (p[0] + p[1]).localeCompare(q[0] + q[1])); all.sort((p, q) => p[2] - q[2]);
    add('people-apart', near, all.length + ' pairs of the ' + TOGETHER.length + ' people spots that are on screen together are at least ' + MIN_APART + ' px apart (closest: ' + all.slice(0, 3).map(p => p[0] + ' ~ ' + p[1] + ' ' + r2(p[2]) + ' px').join(', ') + '; alternatives of one body, pepe.atras and pepe.estante.* are not compared)',
      [(near.length) + ' pair(s) closer than ' + MIN_APART + ' px (screen points):'].concat(near.map(p => '  ' + p[0] + ' ' + S[p[0]].screen + ' ~ ' + p[1] + ' ' + S[p[1]].screen + ': ' + r2(p[2]) + ' px')));
    OUTS[OUTS.length - 1].lines.push('       closest pairs: ' + all.slice(0, 5).map(p => p[0] + ' ' + S[p[0]].screen + ' ~ ' + p[1] + ' ' + S[p[1]].screen + ' ' + r2(p[2]) + ' px').join('; '));
    const rest = all.filter(p => p[2] >= MIN_APART);
    if (near.length) OUTS[OUTS.length - 1].lines.push('       without ' + near.map(p => p[0] + ' ~ ' + p[1]).join(', ') + ' the closest pair is ' + (rest[0] ? rest[0][0] + ' ~ ' + rest[0][1] + ' ' + r2(rest[0][2]) + ' px' : 'none'));
  }

  // 3. every thing's screen box is inside the view
  {
    const bad = Object.entries(T).filter(([, t]) => t.box).filter(([, t]) => t.box[0] < x0 || t.box[0] + t.box[2] > x0 + 196 || t.box[1] < 0 || t.box[1] + t.box[3] > 216).map(([k, t]) => k + ' box ' + t.box + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    const n = Object.values(T).filter(t => t.box).length;
    add('things-in-view', bad, n + ' things with a box (' + Object.entries(T).filter(([, t]) => t.box).map(([k, t]) => k + ' ' + t.box).join(', ') + ') inside the dentro window', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 4. don Pepe seen from the thighs up: at least 28 rows of a 53-row person above the counter's top back edge
  {
    const rows = PERSON.rows, min = PERSON.minAbove;
    const ps = Object.keys(S).filter(k => k === 'pepe.mostrador' || k.startsWith('pepe.estante.'));
    const base = probes.find(p => p.hora === 'manana' && p.atras === 'shut' && p.nevera === 0);
    const info = [], bad = [];
    for (const k of ps) {
      const s = S[k], cx = s.screen[0], feet = s.screen[1];
      // the counter's top back edge (y = CY0, z = CH) in the column cx: x - y = (cx - OX) * R2 / S there
      const u = (cx - (sheet.picture[0] / 2 + sheet.origin.originX)) / sheet.S, x = sheet.things.mostrador.world[1] + u * Math.SQRT2, y = sheet.things.mostrador.world[1];
      const inX = x >= sheet.things.mostrador.world[0] && x <= sheet.things.mostrador.world[3];
      const edgeSy = (sheet.picture[1] / 2 + sheet.origin.originY) + (((x + y) / Math.SQRT2) * .5 - sheet.things.mostrador.world[5] * Math.sqrt(3) / 2) * sheet.S;
      const hidden = feet - edgeSy, above = rows - hidden;
      const pr = base.pepes[k], hid = pr.hidden, firstHidden = hid.indexOf('1'), cnt = hid.split('1').length - 1;
      const byDepth = firstHidden < 0 ? rows : firstHidden;
      info.push({ k, above: r2(above), hidden: r2(hidden), edgeRow: r2(edgeSy), drawnEdgeRow: pr.edge, byDepth, hiddenByDepth: cnt });
      if (!inX || above < min || byDepth < min) bad.push(k + ': ' + r2(above) + ' rows above the edge' + (inX ? '' : ' (the edge column is off the counter, x ' + r2(x) + ')') + ', ' + byDepth + ' by the depth rule');
    }
    const minAbove = Math.min(...info.map(i => i.above)), minDepth = Math.min(...info.map(i => i.byDepth));
    const line = (i) => i.k + ' ' + i.above + ' (' + i.hidden + ' rows hidden under the edge at row ' + i.edgeRow + '; the set draws it at row ' + i.drawnEdgeRow + '; depth rule: ' + i.byDepth + ' rows clear from the top, ' + i.hiddenByDepth + ' hidden)';
    add('pepe-thighs-up', bad, ps.length + ' places: of the ' + rows + '-row standing figure at least ' + minAbove + ' rows above the counter\'s top back edge (minimum, needs ' + min + '), and ' + minDepth + ' rows clear from the top by the depth rule',
      [bad.length + ' place(s) with fewer than ' + min + ' rows above the edge:'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].lines.push(...info.map(i => '       ' + line(i)));
    OUTS[OUTS.length - 1].pepe = info;
  }

  // 5. each good's shelf place is drawn by part 'generos' (not hidden by the counter), in every state of the set
  {
    const goods = Object.keys(S).filter(k => k.startsWith('estante.')), bad = [];
    for (const p of probes) for (const k of goods) { const t = p.goods[k]; if (t[0] !== 'generos' || t[1] !== 'generos') bad.push(k + ' in ' + p.hora + '-' + p.atras + '-' + p.nevera + ': pixel at its point is ' + t[0] + ', at the rounded point ' + t[1]); }
    add('goods-not-hidden', bad, goods.length + ' shelf places x ' + probes.length + ' states of the set (hora x atras x nevera): the pixel at each point, exact and rounded, is drawn by part \'generos\' (props=1 tags=1)', ['places hidden:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 6. the touch boxes of what the set draws cover its pixels (nevera box = CD.NEVERA)
  {
    const bad = [], seen = [];
    for (const [name, tol] of [['nevera', 1], ['silla', 1]]) {
      const p = probes.find(q => q.nevera === (name === 'nevera' ? 1 : 0) && q.hora === 'manana' && q.atras === 'shut'), bb = p.bbox[name], b = T[name].box;
      if (!bb) { bad.push(name + ': the set draws no pixel for it'); continue; }
      const cov = bb[0] >= b[0] - tol && bb[1] >= b[1] - tol && bb[2] <= b[0] + b[2] + tol && bb[3] <= b[1] + b[3] + tol;
      seen.push(name + ' pixels [' + bb + '] in box [' + b + ']');
      if (!cov) bad.push(name + ': its pixels span [' + bb + '] (x0, y0, x1, y1), its box is [' + b + '] (x, y, w, h), more than ' + tol + ' px out');
    }
    add('boxes-cover-set', bad, seen.join('; ') + ' (1 px tolerance)', ['a touch box does not cover what the set draws:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 7. the counter-top spots are on the counter top
  {
    const m = T.mostrador.world, bad = Object.entries(S).filter(([, s]) => s.kind === 'counter' || (s.world && s.world[2] === m[5])).filter(([, s]) => s.world[0] < m[0] || s.world[0] > m[3] || s.world[1] < m[1] || s.world[1] > m[4]).map(([k, s]) => k + ' ' + s.world);
    const n = Object.entries(S).filter(([, s]) => s.kind === 'counter' || (s.world && s.world[2] === m[5])).length;
    add('counter-spots-on-top', bad, n + ' spots at z = CH (the counter things and the frog\'s one) are inside the counter top x ' + m[0] + '..' + m[3] + ', y ' + m[1] + '..' + m[4], ['spots off the counter top:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    // info: which counter-top spots lie under the freezer's footprint (they cannot be in a nevera = 1 picture)
    const n0 = T.nevera.world, under = Object.entries(S).filter(([, s]) => s.world && s.world[2] === m[5]).filter(([, s]) => s.world[0] >= n0[0] && s.world[0] <= n0[3] && s.world[1] >= n0[1] && s.world[1] <= n0[4]).map(([k]) => k);
    OUTS[OUTS.length - 1].lines.push('       info, not a check: under the freezer\'s footprint (CD.NEVERA x ' + r2(n0[0]) + '..' + r2(n0[3]) + ', y ' + r2(n0[1]) + '..' + r2(n0[4]) + '), so not usable while nevera = 1 (these are spots of stories without the freezer, left where the design has them): ' + (under.join(', ') || 'none'));
    OUTS[OUTS.length - 1].under = under;
  }

  // 8. the spots keep CLEAR px from the register, the freezer (story 38) and the chair: measured again on the final points
  {
    const CD = G.CD, bad = [], rows = [];
    for (const [k, s] of at) {
      if (s.kind === 'shelf') continue;
      const o = obstaclesOf(k, s.world, CD); if (!o.length) continue;
      const f = feet(s.screen), d = Math.min(...o.map(n => nearest(f, G.px[n])));
      rows.push([k, o.join('+'), d]);
      if (d < CLEAR) bad.push(k + ' ' + s.screen + ' is ' + r2(d) + ' px from the ' + o.join(' + ') + ' pixels (needs ' + CLEAR + ')');
    }
    rows.sort((a, b) => a[2] - b[2]);
    const mv = sheet.moved.map(m => m.spot + ' x ' + m.from[0] + ' -> ' + m.to[0] + ' (' + (m.dx > 0 ? '+' : '') + m.dx + ', ' + m.against + ': ' + m.clearBefore + ' -> ' + m.clearAfter + ' px; the nearest clear place on the other side: ' + (m.otherSide ? 'x ' + m.otherSide.to + ', ' + (m.otherSide.dx > 0 ? '+' : '') + m.otherSide.dx : 'none on the counter') + ')');
    add('spots-clear', bad, rows.length + ' spots (counter-top ones from the register; ' + NEVERA_STORY.join(', ') + ' also from the freezer; floor spots in front of the counter from the chair) keep at least ' + CLEAR + ' px from those pixels; nearest: ' + rows.slice(0, 3).map(r => r[0] + ' ' + r2(r[2]) + ' px (' + r[1] + ')').join(', '), ['spots too near:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const f of sheet.failing || []) OUTS[OUTS.length - 1].lines.push('       ' + f.spot + ' ' + f.at + ' is ' + f.clear + ' px from the ' + f.against + ' pixels; the nearest x along the counter that clears it by ' + CLEAR + ' px: ' + (f.nearest ? f.nearest.x + ' (' + (f.nearest.dx > 0 ? '+' : '') + f.nearest.dx + ')' : 'none') + (f.otherSide ? ', on the other side x ' + f.otherSide.x + ' (' + (f.otherSide.dx > 0 ? '+' : '') + f.otherSide.dx + ')' : '') + '; the brief\'s number is kept');
    OUTS[OUTS.length - 1].lines.push('       moved from the design to clear it: ' + (mv.join('; ') || 'none'));
    const nearFreezer = at.filter(([k, s]) => s.world && s.world[2] === CD.CH && s.kind !== 'shelf' && !NEVERA_STORY.includes(k) && nearest(feet(s.screen), G.px.nevera) < CLEAR).map(([k, s]) => k + ' ' + r2(nearest(feet(s.screen), G.px.nevera)) + ' px');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: counter-top spots of the stories WITHOUT the freezer (nevera = 0) that lie under or within ' + CLEAR + ' px of its pixels, left where the design has them: ' + (nearFreezer.join(', ') || 'none'));
    OUTS[OUTS.length - 1].leftNearFreezer = nearFreezer;
  }
  // 9. (v3) sprites-apart: for every pair that stands together in a moment of the preview (the people and the frog: layers with a character kind), the two sprite boxes (the frog 32 wide, a grown-up 24, a child 24,
  //    the feet's spot in the middle) do not overlap sideways, unless their feet are UPDOWN px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of [1, 2, 3, 4, 5, 6]) {
      const L = PVD[m].layers.filter(l => l.who), pairs = [];
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        pairs.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok }); all.push(pairs[pairs.length - 1]);
        if (!ok) hints.push({ m, a, b, half });
        if (!ok) bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down');
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down (the frog ' + WIDTH.coqui + ' wide, grown-up ' + WIDTH.adulto + ', child ' + WIDTH.nino + '); the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' px across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down:'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) {                                                           // the nearest spot value that would pass (the brief's numbers are kept)
      const pass = (me, other) => (sx, sy) => Math.abs(sx - other.sx) >= h.half || Math.abs(sy - other.sy) >= UPDOWN;
      OUTS[OUTS.length - 1].lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + sheet.spots[h.a.at].world + ': ' + nearestPass(sheet, h.a.at, pass(h.a, h.b)) + '; or ' + h.b.at + ' ' + sheet.spots[h.b.at].world + ': ' + nearestPass(sheet, h.b.at, pass(h.b, h.a)));
    }
    OUTS[OUTS.length - 1].lines.push('       closest in each moment (px across / px down): ' + [1, 2, 3, 4, 5, 6].map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    OUTS[OUTS.length - 1].pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 10. (v3) ninos-puerta-heads: the three children at the door are a group: every head (the top HEAD_ROWS rows of a child) shows: no pixel of it is covered by another child (a pixel of another child, shown by the set,
  //     nearer than it). Reported: the rows of each head that another child covers
  {
    const L = PVD[5].layers.filter(l => l.at && l.at.startsWith('ninos_puerta.')), bad = [], lines = [];
    for (const a of L) {
      const top = Math.min(...a.px.map(p => p[1])), rows = {}, by = {};
      let tot = 0, shown = 0;
      for (const p of a.px) {
        if (p[1] >= top + HEAD_ROWS) continue;
        tot++; if (!p[2]) shown++;
        if (p[2]) continue;
        for (const b of L) if (b !== a) for (const q of b.px) if (q[0] === p[0] && q[1] === p[1] && !q[2] && q[3] > p[3]) { rows[p[1] - top] = (rows[p[1] - top] || 0) + 1; by[b.at] = (by[b.at] || 0) + 1; }
      }
      const n = Object.values(rows).reduce((x, y) => x + y, 0), rl = Object.keys(rows).map(Number).sort((x, y) => x - y);
      lines.push(a.at + ' ' + [a.sx, a.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ' (' + tot + ' px, ' + shown + ' shown by the set); ' + (n ? n + ' px covered by another child, in ' + rl.length + ' row(s): ' + rl.map(r => 'row ' + r + ' of the head (picture row ' + (top + r) + '): ' + rows[r] + ' px').join(', ') + ' (by ' + Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ') + ')' : 'no row covered'));
      if (n) bad.push(a.at + ': ' + n + ' px of its head covered, rows ' + rl.map(r => top + r) + ' of the picture (' + rl.length + ' of ' + HEAD_ROWS + ')');
    }
    add('ninos-puerta-heads', bad, 'the three heads (top ' + HEAD_ROWS + ' rows of each child) show in moment 5: ' + lines.join('; '), ['heads covered:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    if (bad.length) OUTS[OUTS.length - 1].lines.push(...lines.map(l => '       ' + l));
    OUTS[OUTS.length - 1].heads = lines;
  }

  // 11. (v3) the frog on the counter (coqui.mostrador, moments 3 and 5) may overlap the register's side shelf, not the register's body: the pixels of the frog (shown by the set) on pixels of the register's body
  //     (and its head), and on the shelf, in px
  {
    const bodyX = G.CD.CAJA_VENTANA[0] * 2 - (G.CD.CX0 + .1) + SHELF_TOL;               // the body's right side RG.x1 (+ the tolerance): the body's pixels have a world x up to it, the shelf's are right of it
    const body = new Set(), shelf = new Set();
    G.px.caja.forEach((p, i) => (G.cajaX[i] <= bodyX ? body : shelf).add(p[0] + ',' + p[1]));
    const bb = a => { const xs = [...a].map(k => +k.split(',')[0]), ys = [...a].map(k => +k.split(',')[1]); return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)]; };
    const bad = [], lines = [], res = [];
    for (const m of [3, 5]) {
      const f = PVD[m].layers.find(l => l.at === 'coqui.mostrador'), shown = f.px.filter(p => !p[2]);
      const onBody = shown.filter(p => body.has(p[0] + ',' + p[1])), onShelf = shown.filter(p => shelf.has(p[0] + ',' + p[1]));
      const fb = [Math.min(...shown.map(p => p[0])), Math.min(...shown.map(p => p[1])), Math.max(...shown.map(p => p[0])), Math.max(...shown.map(p => p[1]))], rb = bb(body);
      const bx = Math.min(fb[2], rb[2]) - Math.max(fb[0], rb[0]) + 1, by = Math.min(fb[3], rb[3]) - Math.max(fb[1], rb[1]) + 1;
      lines.push('moment ' + m + ' the frog at coqui.mostrador [' + f.sx + ',' + f.sy + '] (' + shown.length + ' px shown, box [' + fb + ']): ' + onBody.length + ' px on the register\'s body (' + body.size + ' px, box [' + rb + ']; the boxes overlap ' + (bx > 0 && by > 0 ? bx + ' across, ' + by + ' down' : 'not at all') + '), ' + onShelf.length + ' px on the side shelf (' + shelf.size + ' px)');
      res.push({ moment: m, bodyPx: onBody.length, shelfPx: onShelf.length, boxOverlap: bx > 0 && by > 0 ? [bx, by] : null });
      if (onBody.length) bad.push('moment ' + m + ': ' + onBody.length + ' px of the frog lie on the register\'s body');
    }
    add('frog-register-body', bad, 'the frog on the counter at coqui.mostrador ' + S['coqui.mostrador'].screen + ' overlaps the register\'s body by 0 px (it may overlap the side shelf): ' + lines.join('; '), ['the frog on the counter:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    if (bad.length) OUTS[OUTS.length - 1].lines.push(...lines.map(l => '       ' + l));
    if (bad.length) {                                                                  // the nearest place of the frog (along x or y of coqui.mostrador) with 0 px on the body; its clearance from the register and the freezer
      const f = PVD[3].layers.find(l => l.at === 'coqui.mostrador'), near = (pts, X, Y) => Math.min(...pts.map(p => Math.hypot(p[0] - X, p[1] - Y)));
      const ok = (sx, sy) => !f.px.some(p => body.has((p[0] + sx - f.sx) + ',' + (p[1] + sy - f.sy)));
      const at = nearestPass(sheet, 'coqui.mostrador', ok);
      const first = (() => { const w = S['coqui.mostrador'].world; for (let k = 1; k <= 300; k++) for (const sg of [1, -1]) { const q = [r4(w[0] + sg * k * .01), w[1], w[2]], [sx, sy] = scr3(sheet, ...q); if (ok(sx, sy)) return { q, sx, sy }; } return null; })();
      OUTS[OUTS.length - 1].lines.push('       nearest passing for coqui.mostrador ' + S['coqui.mostrador'].world + ' (0 px on the body): ' + at + (first ? '; along x alone: x ' + first.q[0] + ' [' + first.sx + ',' + first.sy + '], its feet are ' + r2(near(G.px.caja, first.sx, first.sy - 1)) + ' px from the register\'s pixels and ' + r2(near(G.px.nevera, first.sx, first.sy - 1)) + ' px from the freezer\'s' : ''));
    }
    OUTS[OUTS.length - 1].overlap = res;
  }
  return OUTS.concat(checksCalle(calle, callePix, PVD, GC));
}

function checksCalle(calle, callePix, PVD, GC) {
  const OUTS = [], S = calle.spots, T = calle.things, V = calle.views.calle, [x0] = V.region;
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  // c1. every calle spot and the colmado box inside the calle picture and the calle window
  {
    const bad = [];
    for (const [k, s] of Object.entries(S)) {
      if (s.screen[0] < 0 || s.screen[0] >= calle.picture[0] || s.screen[1] < 0 || s.screen[1] >= calle.picture[1]) bad.push(k + ' ' + s.screen + ' outside the picture');
      else if (s.screen[0] < x0 || s.screen[0] >= x0 + 196) bad.push(k + ' ' + s.screen + ' outside the calle window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    for (const [k, t] of Object.entries(T)) if (t.box[0] < x0 || t.box[0] + t.box[2] > x0 + 196 || t.box[1] < 0 || t.box[1] + t.box[3] > 216) bad.push(k + ' box ' + t.box + ' outside the calle window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    add('calle-in-view', bad, Object.keys(S).length + ' spots (' + Object.entries(S).map(([k, s]) => k + ' ' + s.screen).join(', ') + ') and the colmado box [' + T.colmado.box + '] inside the calle picture and the calle window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)', ['calle things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }
  // c2. (v3) abuela and the frog on the pavement, CALLE_SIDEWAYS px or more apart sideways (columns)
  {
    const a = S['abuela.acera'].screen, b = S['coqui.acera'].screen, d = Math.abs(a[0] - b[0]);
    add('calle-people-apart', d < CALLE_SIDEWAYS ? ['x'] : [], 'abuela.acera ' + a + ' ~ coqui.acera ' + b + ': ' + d + ' px sideways (needs ' + CALLE_SIDEWAYS + '); ' + Math.abs(a[1] - b[1]) + ' px up-down', ['abuela.acera ' + a + ' ~ coqui.acera ' + b + ': ' + d + ' px sideways < ' + CALLE_SIDEWAYS + '; short by ' + (CALLE_SIDEWAYS - d) + ' px']);
  }
  // c2b. (v3) abuela's box (24 wide, 50 rows, her feet's spot in the middle of the bottom edge) does not touch the scale's pixels (the dial, its chains and the plate, part pesa of the calle set)
  {
    const a = S['abuela.acera'].screen, box = [a[0] - ABUELA_BOX.w / 2, a[1] - ABUELA_BOX.h, ABUELA_BOX.w, ABUELA_BOX.h];
    const inside = GC.pesa.filter(p => p[0] >= box[0] && p[0] < box[0] + box[2] && p[1] >= box[1] && p[1] < box[1] + box[3]);
    const gap = Math.min(...GC.pesa.map(p => Math.max(0, box[0] - p[0], p[0] - (box[0] + box[2] - 1), box[1] - p[1], p[1] - (box[1] + box[3] - 1))));
    const pb = [Math.min(...GC.pesa.map(p => p[0])), Math.min(...GC.pesa.map(p => p[1])), Math.max(...GC.pesa.map(p => p[0])), Math.max(...GC.pesa.map(p => p[1]))];
    // her real silhouette (moment 6), the same test
    const ab = PVD[6].layers.find(l => l.at === 'abuela.acera'), ink = ab.px.filter(p => !p[2]);
    const sil = Math.min(...ink.map(q => Math.min(...GC.pesa.map(p => Math.hypot(p[0] - q[0], p[1] - q[1])))));
    add('calle-abuela-clear-of-scale', inside.length ? ['x'] : [], 'abuela.acera ' + a + ': her box [' + box + '] holds none of the ' + GC.pesa.length + ' scale pixels (dial, chains, plate; their box columns ' + pb[0] + '..' + pb[2] + ', rows ' + pb[1] + '..' + pb[3] + '); the box is ' + gap + ' px clear of them (her drawn silhouette in moment 6 is ' + r2(sil) + ' px from the nearest)',
      [inside.length + ' scale pixel(s) inside abuela\'s box [' + box + '] at ' + a + ': ' + inside.slice(0, 6).map(p => p.join(',')).join(' ') + (inside.length > 6 ? ' ...' : '') + '; the scale\'s box columns ' + pb[0] + '..' + pb[2] + ', rows ' + pb[1] + '..' + pb[3]]);
  }
  // c3. the pavement spots are on the pavement, puerta_calle is in the door (and inside the colmado box), the rooster stands on the awning's front edge, in every calle state
  {
    const K = calle.constants, bad = [], P = (n) => S[n].world;
    for (const n of ['abuela.acera', 'coqui.acera']) if (!(P(n)[1] > K['CF.AY'] && P(n)[1] <= K['CF.PAVE'])) bad.push(n + ' y ' + P(n)[1] + ' is not on the pavement (CF.AY .. CF.PAVE = ' + K['CF.AY'] + ' .. ' + K['CF.PAVE'] + ')');
    if (!(P('puerta_calle')[0] >= K['CF.D0'] && P('puerta_calle')[0] <= K['CF.D1'])) bad.push('puerta_calle x ' + P('puerta_calle')[0] + ' is not in the door ' + K['CF.D0'] + ' .. ' + K['CF.D1']);
    const b = T.colmado.box, p = S.puerta_calle.screen;
    if (p[0] < b[0] || p[0] > b[0] + b[2] || p[1] < b[1] || p[1] > b[1] + b[3]) bad.push('puerta_calle ' + p + ' is outside the colmado box [' + b + ']');
    const g = P('gallo');
    if (Math.abs(g[0] - (K['CF.AX0'] + K['CF.AX1']) / 2) > 1e-6 || g[1] !== K['CF.AY'] || g[2] !== K['CF.AZ0']) bad.push('gallo ' + g + ' is not at the middle of the awning\'s front edge');
    const tags = Object.entries(callePix).map(([st, r]) => [st, r && r.gallo]);
    for (const [st, t] of tags) if (!t || t[0] !== 'toldo') bad.push('gallo in ' + st + ': the pixel at its point is ' + (t && t[0]) + ', not the awning (toldo)');
    add('calle-places', bad, 'abuela.acera and coqui.acera on the pavement (y ' + P('abuela.acera')[1] + ', ' + P('coqui.acera')[1] + ' <= CF.PAVE ' + K['CF.PAVE'] + '); puerta_calle x ' + P('puerta_calle')[0] + ' in the door (CF.D0 .. CF.D1 = ' + K['CF.D0'] + ' .. ' + K['CF.D1'] + ') and inside the colmado box; gallo at x ' + r2(g[0]) + ', y ' + g[1] + ', z ' + g[2] + ' (the awning\'s front edge, its middle) and the pixel there is the awning in all ' + tags.length + ' calle states', ['calle places wrong:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }
  return OUTS;
}
