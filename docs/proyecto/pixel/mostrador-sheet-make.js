#!/usr/bin/env node
'use strict';
/* El mostrador's sheet (version 2): writes docs/proyecto/pixel/mostrador-sheet.json from mostrador-set.html and the design (the orchestrator's mostrador-spec, with its v2 changes
   and the calle state), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/mostrador-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set twice: donde=dentro (window.MOSTRADOR.CD: the room's constants) and donde=calle (CF,
   colmado-fuera.js: the shop front), projects every world point with the engine's own project() (pp-engine.js), and writes the spots, things, view, shadows and the depth rule.
   Every place the room exports (CD.GOODS, CD.SILLA, CD.NEVERA, CD.CX0 ..) is read from the set, never typed again from the design.
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

const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

// the standing figure is 53 drawn rows (mkPersona, the design's number); at least 28 of them above the counter's top back edge when he is seen from the thighs up
const PERSON = { rows: 53, minAbove: 28 };
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_APART = 10;                                    // px between two people's feet on screen
const CLEAR = 4;                                         // px a spot keeps from the pixels of the register, the freezer or the chair
// what the freezer is drawn with: the spots of story 38 (nevera = 1). The other counter spots (the tray, the dish, the malts ...) belong to stories without it
const NEVERA_STORY = ['coqui.mostrador', 'limber_pepe', 'limber_lejos'];

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', route => {
    const u = new URL(route.request().url()), f = path.join(REPO, decodeURIComponent(u.pathname));
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
    route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
  });
  const load = async (q) => { await page.goto(PAGE + '?' + q); };
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);

  /* ---- inside the shop: the room's constants, and the pixels of the register, the freezer and the chair (all drawn: nevera = 1, tags = 1) ---- */
  await load('props=1&tags=1&nevera=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(MOSTRADOR.CD)) if (typeof v !== 'function') o[k] = v;
    const px = {}; for (const n of ['caja', 'nevera', 'silla']) px[n] = [];
    for (let i = 0; i < TAGS.length; i++) if (px[TAGS[i]]) px[TAGS[i]].push([i % W, (i / W) | 0]);
    return { CD: o, scene: PP_SCENE, W, H, S, OX, OY, px };
  });
  const dentro = await makeDentro(G, proj);
  // the checks that read the set's own pixels: every state of the set (hora x atras x nevera), goods drawn (props=1), each pixel tagged by the part that drew it (tags=1)
  const probes = await probeSets(page, dentro, load);

  /* ---- the shop front, from the street ---- */
  await load('donde=calle&hora=manana&puerta=shut&tags=1');
  const GC = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(CF)) if (typeof v !== 'function') o[k] = v;
    return { CF: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  const calle = await makeCalle(GC, proj, page);
  const callePix = await probeCalle(page, calle, load);

  const results = checks(dentro, probes, calle, callePix, G);
  const sheet = dentro;
  sheet.calle = calle;
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
  person('coqui.frente', [4.4, 3.5, 0], 'the frog on the floor, in front of the counter');
  person('coqui.mostrador', [3.0, 2.38, CH], 'the frog\'s one place on the counter top, right of the register (it casts no shadow)');
  person('abuela.frente', [3.0, 4.1, 0], 'abuela standing in front of the counter');
  person('abuela.silla', [CD.SILLA[0], CD.SILLA[1], .45], 'abuela sitting in the waiting chair (CD.SILLA); z .45 is the chair\'s seat top (colmado-dentro.js chairs()); the sitting sprite is anchored by her lap, rules.anchor');
  person('nino.frente', [5.9, 3.6, 0], 'Luis or Carmen at the counter');
  person('nino.puerta_dentro', [.7, 5.4, 0], 'Carmen looking out of the street door, inside');
  person('cliente', [2.9, 3.75, 0], 'the customer being served');
  person('cola1', [2.3, 4.2, 0], 'waiting, first');
  person('cola2', [1.6, 4.7, 0], 'waiting, second');
  person('puerta', [.45, DY, 0], 'just inside the street door');
  person('fuera', [-.35, DY, 0], 'on the pavement, seen through the street door (no shadow)');
  [[.6, 3.9], [.6, 4.5], [1.1, 5.1]].forEach(([x, y], i) => person('ninos_puerta.' + (i + 1), [x, y, 0], 'child ' + (i + 1) + ' of the three just inside the street door (story 38: they wait there, each with a coin); group ninos_puerta'));
  onCounter('bandeja', 5.6, 2.38, 'the tray of quesitos');
  onCounter('platillo', 5.0, 2.15, 'the coin dish');
  onCounter('cosa_a', 3.6, 2.5, 'the first of the two things in front of the frog');
  onCounter('cosa_b', 4.25, 2.5, 'the second of the two things in front of the frog');
  onCounter('compra', 4.4, 2.5, 'where a thing taken down from a shelf is set');
  onCounter('monedas', 4.6, 2.62, 'the first of Carmen\'s coins; the row runs towards +x (dir), .22 apart (step)');
  onCounter('maltas', 5.95, 2.15, 'the malts');
  onCounter('limber_pepe', 4.75, 2.45, 'a límber at don Pepe\'s end');
  onCounter('limber_lejos', 3.55, 2.5, 'a límber at the frog\'s end');
  onCounter('bolsa', 4.45, 2.55, 'the bag being packed');
  for (const [k, s, x] of GOODS) D.push(['estante.' + k, [x, .19, SZ[s] + .06], 'shelf', 'where ' + k + ' stands on its shelf (the plank\'s top)']);

  /* ---- a spot that now collides with the register, the freezer or the chair moves the least distance along the counter that clears it by CLEAR px ----
     collide: the spot's feet pixel is nearer than CLEAR px to a pixel the set draws for that object (part 'caja', 'nevera' in nevera = 1, 'silla'). A counter-top spot is tested against
     the register, and, when it is a spot of story 38 (the only story with the freezer), against the freezer; a floor spot in front of the counter against the chair (not abuela.silla: she
     sits in it). The move is along x (the counter's length), by steps of .01, to whichever side is nearer; a counter-top spot stays on the counter top */
  const moved = [];
  const clearance = (name, w, q) => { const f = feet(scr(q)); const o = obstaclesOf(name, w, CD); return o.length ? Math.min(...o.map(n => nearest(f, G.px[n]))) : Infinity; };
  let pr = await proj(D.map(d => d[1]));
  for (let i = 0; i < D.length; i++) {
    const [name, w, kind] = D[i];
    if (kind === 'shelf' || clearance(name, w, pr[i]) >= CLEAR) continue;
    const cands = []; for (let k = 1; k <= 160; k++) for (const s of [-1, 1]) cands.push([w[0] + s * k * .01, w[1], w[2], s * k * .01]);
    const cp = await proj(cands.map(c => c.slice(0, 3)));
    const onTop = c => w[2] !== CH || (c[0] >= CD.CX0 && c[0] <= CD.CX1);
    const j = cands.findIndex((c, n) => onTop(c) && clearance(name, c, cp[n]) >= CLEAR);
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
  return {
    scene: 'mostrador',
    made: 'node docs/proyecto/pixel/mostrador-sheet-make.js, from mostrador-set.html (window.MOSTRADOR.CD, CF) and the design of El mostrador (version 2, with the calle state). A new scene: no old scene, no remap.',
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
}

/* ---------- the sheet: the shop front, from the street (donde=calle) ---------- */
async function makeCalle(G, proj, page) {
  const CF = G.CF, sc = G.scene;
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const gx = (CF.AX0 + CF.AX1) / 2;
  const D = [
    ['abuela.acera', [2.4, 2.6, 0], 'person', 'abuela on the pavement in front of the door'],
    ['coqui.acera', [3.2, 2.9, 0], 'person', 'the frog on the pavement, right of abuela'],
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
  // the view: nothing in the design gives one for the calle picture. The window is centred on the middle of the bounding box of the calle spots and the colmado box
  const xs = [].concat(Object.values(spots).map(s => s.screen[0]), [things.colmado.box[0], things.colmado.box[0] + things.colmado.box[2]]);
  const mid = (Math.min(...xs) + Math.max(...xs)) / 2, x0 = Math.max(0, Math.min(G.W - 196, Math.round(mid - 98)));
  const views = { calle: { provisional: true, zoom: 1, x0, region: [x0, 0, 196, 216], what: 'PROVISIONAL (the design gives no calle view): the 196 x 216 window centred on the middle of the bounding box of the calle spots and the colmado box, clamped to the picture (x0 = clamp(round(mid - 98), 0, 44))' } };
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

function checks(sheet, probes, calle, callePix, G) {
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
    const TOGETHER = ['pepe.mostrador', 'pepe.silla', 'coqui.mostrador', 'coqui.frente', 'cliente', 'cola1', 'cola2', 'abuela.frente', 'abuela.silla', 'nino.frente', 'nino.puerta_dentro', 'ninos_puerta.1', 'ninos_puerta.2', 'ninos_puerta.3'];
    const ALT = [['pepe.mostrador', 'pepe.silla'], ['coqui.mostrador', 'coqui.frente'], ['abuela.frente', 'abuela.silla'], ['nino.frente', 'nino.puerta_dentro']];
    const alt = (a, b) => ALT.some(p => (p[0] === a && p[1] === b) || (p[0] === b && p[1] === a));
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
    OUTS[OUTS.length - 1].lines.push('       moved from the design to clear it: ' + (mv.join('; ') || 'none'));
    const nearFreezer = at.filter(([k, s]) => s.world && s.world[2] === CD.CH && s.kind !== 'shelf' && !NEVERA_STORY.includes(k) && nearest(feet(s.screen), G.px.nevera) < CLEAR).map(([k, s]) => k + ' ' + r2(nearest(feet(s.screen), G.px.nevera)) + ' px');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: counter-top spots of the stories WITHOUT the freezer (nevera = 0) that lie under or within ' + CLEAR + ' px of its pixels, left where the design has them: ' + (nearFreezer.join(', ') || 'none'));
    OUTS[OUTS.length - 1].leftNearFreezer = nearFreezer;
  }
  return OUTS.concat(checksCalle(calle, callePix));
}

function checksCalle(calle, callePix) {
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
  // c2. abuela and the frog on the pavement, at least MIN_APART px apart
  {
    const a = S['abuela.acera'].screen, b = S['coqui.acera'].screen, d = Math.hypot(a[0] - b[0], a[1] - b[1]);
    add('calle-people-apart', d < MIN_APART ? ['x'] : [], 'abuela.acera ' + a + ' ~ coqui.acera ' + b + ': ' + r2(d) + ' px (needs ' + MIN_APART + ')', ['abuela.acera ' + a + ' ~ coqui.acera ' + b + ': ' + r2(d) + ' px < ' + MIN_APART]);
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
