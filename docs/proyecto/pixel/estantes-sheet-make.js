#!/usr/bin/env node
'use strict';
/* Los estantes' sheet: writes docs/proyecto/pixel/estantes-sheet.json from estantes-set.html and the design (the orchestrator's estantes-spec), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/estantes-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set (window.ESTANTES.CD: the room's constants) in headless Chrome,
   projects every world point with the engine's own project() (pp-engine.js), and writes the spots, things, view, shadows and the depth rule.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with ESTANTES_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged.
   To try another origin without touching the set: ESTANTES_QUERY='ox=-222' ESTANTES_OUT=/tmp/try.json node docs/proyecto/pixel/estantes-sheet-make.js
   (extra address parameters for every load of the set, and a different file to write; the sheet then says the origin it was made with). */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = process.env.ESTANTES_OUT || path.join(__dirname, 'estantes-sheet.json');
const EXTRA = process.env.ESTANTES_QUERY ? '&' + process.env.ESTANTES_QUERY : '';
const BASE = process.env.ESTANTES_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/estantes-set.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

const PERSON_ROWS = 53;                                  // a standing mkPersona draws 53 rows
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_APART = 12;                                    // px between two people's feet on screen
const FLOOR_LEFT = 20;                                   // px of floor wanted left of the table in the view
const DIBUJO_CLEAR = 8;                                  // px between the drawing's point and the hanging plantains
const STATES = [[0, 0], [1, 0], [0, 1], [1, 1]];         // anillos, mesa

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
  const load = async (q) => { await page.goto(PAGE + '?' + q + EXTRA); };
  await load('tags=1&anillos=1&mesa=1');
  const G = await page.evaluate(() => { const o = {}; for (const [k, v] of Object.entries(ESTANTES.CD)) if (typeof v !== 'function') o[k] = v; return { CD: o, scene: PP_SCENE, W, H, S, OX, OY }; });
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);
  // the pixels of the baked set that the checks and the view need, in the state with everything drawn
  const bb = await page.evaluate(() => {
    const out = {};
    for (const name of ['estantes2', 'escalera', 'mesa', 'racimo']) {
      let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
      for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === name) { const x = i % W, y = (i / W) | 0; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      out[name] = x1 < 0 ? null : [x0, y0, x1, y1];
    }
    return out;
  });
  const sheet = await make(G, proj, bb);
  // the checks that read the set's own pixels: every state of the set (anillos x mesa), each pixel tagged by the part that drew it (tags=1)
  const probes = await probeSets(page, sheet, load);
  const results = checks(sheet, probes, bb);
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

/* the six ring places on the middle shelf: the x offsets the set draws its rings at (colmado-dentro.js, part 'anillos': [dx, rx, ry] each), read from its source */
function ringOffsets() {
  const src = fs.readFileSync(path.join(__dirname, 'colmado-dentro.js'), 'utf8');
  const m = src.match(/\[\s*\[\s*\.42\s*,[^;]*?\]\s*\]\s*\.forEach\(\(\[dx, rx, ry\]\)/);
  if (!m) throw new Error('colmado-dentro.js: the rings\' list was not found');
  const list = new Function('return ' + m[0].replace(/\.forEach\(.*$/, ''))();
  if (list.length !== 6) throw new Error('colmado-dentro.js: expected six rings, found ' + list.length);
  return list.map(a => a[0]);
}

/* ---------- the sheet ---------- */
async function make(G, proj, bb) {
  const CD = G.CD, SZ = CD.SZ, SD = CD.SD, E0 = CD.E2X0, E1 = CD.E2X1, [MX, MY] = CD.MESA, MH = CD.MESA_H, PIE = CD.ESCALERA_PIE, ALTO = CD.ESCALERA_ALTO;
  const S = G.S, OX = G.OX, OY = G.OY, R2 = Math.SQRT2;
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];

  // the ladder's rungs: colmado-dentro.js draws seven, at z = LTOP * r / 8, and ESCALERA_ALTO is the point at 3/4 of LTOP: so LTOP = ALTO z / .75
  const LTOP = ALTO[2] / .75, rungs = [1, 2, 3, 4, 5, 6, 7].map(r => LTOP * r / 8);
  const rung = rungs.reduce((a, b) => Math.abs(b - 1.3) < Math.abs(a - 1.3) ? b : a);
  const tt = rung / ALTO[2];                                                         // along the ladder's line from the foot to the point at 3/4
  const onLadder = [PIE[0] + (ALTO[0] - PIE[0]) * tt, PIE[1] + (ALTO[1] - PIE[1]) * tt, rung];
  const ringDx = ringOffsets();

  /* ---- the view: one window, zoom 1; x0 the leftmost the picture allows that keeps the whole run, the ladder and the table in it ---- */
  const tableL = bb.mesa[0], tableR = bb.mesa[2], runL = bb.estantes2[0], runR = bb.estantes2[2], ladL = bb.escalera[0], ladR = bb.escalera[2];
  const need = { left: Math.min(runL, ladL, tableL - FLOOR_LEFT), right: Math.max(runR, ladR, tableR) + 1 };
  const lo = Math.max(0, need.right - 196), hi = Math.min(G.W - 196, need.left);
  const x0 = Math.max(0, Math.min(G.W - 196, Math.round((lo + hi) / 2)));
  // the world point the window is centred on: the floor point on the window's middle column, on the line y = 2.9 (so x0 = clamp(round(sx - 98), 0, 44) gives it back)
  const vy = 2.9, vx = vy + (x0 + 98 - OX) * R2 / S;
  // puerta_lata: the left edge of the window at floor level, y 4.0
  const lx = 4.0 + (x0 - OX) * R2 / S;

  /* ---- spots: the ground (or the shelf top, the table top, the rung) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, what, extra]
  const add = (name, w, kind, what, extra) => D.push([name, w, kind, what, extra]);
  add('pepe.pie', [12.3, 1.5, 0], 'person', 'don Pepe at the foot of the ladder, left of it');
  add('pepe.escalera', onLadder, 'person', 'don Pepe on the ladder, his feet on the rung nearest z 1.3 (z ' + r4(rung) + ', the fourth of seven); x and y from the ladder\'s line between ESCALERA_PIE and ESCALERA_ALTO');
  add('pepe.mesa', [12.9, 2.9, 0], 'person', 'don Pepe behind the display table, at its right end, clear of the pyramid');
  add('pepe.entra', [10.6, 3.0, 0], 'person', 'don Pepe coming in from the left with the big box');
  add('coqui.cajon', [15.0, 3.2, .3], 'person', 'the frog on his crate; the crate is a sprite .3 high under him (its bottom middle on ground)');
  add('coqui.piso', [13.5, 4.3, 0], 'person', 'the frog on the floor');
  add('luis.piso', [15.2, 4.4, 0], 'person', 'Luis on the floor');
  add('luis.cajas', [15.4, 3.6, 0], 'person', 'Luis where he counts and holds a box up');
  add('caja_grande', [12.9, 2.4, 0], 'object', 'the big cardboard box of the delivery');
  add('cajon_latas', [13.9, 3.2, 0], 'object', 'the crate of cans (story 40)');
  add('red_a', [13.6, 3.2, .35], 'object', 'the first net of cans, on the crate');
  add('red_b', [14.25, 3.2, .35], 'object', 'the second net of cans, on the crate');
  for (let k = 0; k < 6; k++) add('estante.medio.' + k, [E0 + ringDx[k], .19, SZ[1] + .06], 'shelf', 'ring place ' + k + ' on the middle shelf, at the ring the set draws (x = E2X0 + ' + ringDx[k] + '); the shelf top');
  for (let k = 0; k < 7; k++) add('estante.alto.' + k, [E0 + .5 + k * (E1 - E0 - 1) / 6, .19, SZ[2] + .06], 'shelf', 'bottle place ' + k + ' on the top shelf, evenly from E2X0 + .5 to E2X1 - .5; the shelf top');
  for (let r = 0; r < 4; r++) add('mesa.fila.' + r, [MX, MY, MH + r * .3], 'table', 'the middle of row ' + r + ' of the pyramid on the table top (row 0 on the cloth, each row .3 higher)');
  add('dibujo', [9.6, 0, 1.75], 'wall', 'the drawing pinned on the back wall, between the two runs; its middle on the point');
  add('cola1', [11.0, 3.4, 0], 'person', 'the señora waiting at the left edge');
  add('cola2', [10.7, 4.0, 0], 'person', 'the señor waiting at the left edge');
  add('entra', [10.4, 3.7, 0], 'person', 'where somebody appears coming in');
  add('caja_abuela', [14.4, 4.0, 0], 'box', 'the first bottle box of story 41, on the floor, seen from above (its middle; about 1.0 x .5, the long side along x)', { footprint: [1.0, .5] });
  add('caja_senora', [11.5, 4.5, 0], 'box', 'the señora\'s bottle box (its middle; about 1.0 x .5, the long side along x)', { footprint: [1.0, .5] });
  add('caja_senor', [13.0, 5.0, 0], 'box', 'the señor\'s bottle box (its middle; about 1.0 x .5, the long side along x)', { footprint: [1.0, .5] });
  add('senora.caja', [11.2, 4.1, 0], 'person', 'the señora standing by her box');
  add('senor.caja', [13.6, 5.4, 0], 'person', 'the señor standing by his box');
  add('perro.entra', [10.5, 4.2, 0], 'animal', 'Canelo coming in');
  add('perro.mesa', [11.7, 4.2, 0], 'animal', 'Canelo bumping the table');
  add('perro.rana', [14.5, 4.0, 0], 'animal', 'Canelo sitting beside the frog');
  add('puerta_lata', [lx, 4.0, 0], 'edge', 'where a can rolls out of the picture: the left edge of the window (the first column, x0) at floor level, y 4.0');
  const pr = await proj(D.map(d => d[1]));
  const spots = {};
  D.forEach((d, i) => {
    const q = pr[i];
    spots[d[0]] = Object.assign({ world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2], what: d[3] }, d[4] || {});
  });
  // the crate under the frog stands on the floor under him
  const gw = [D.find(d => d[0] === 'coqui.cajon')[1][0], D.find(d => d[0] === 'coqui.cajon')[1][1], 0];
  const gq = (await proj([gw]))[0];
  spots['coqui.cajon'].ground = { world: W4(gw), screen: scr(gq), depth: r4(gq[2]) };

  /* ---- things he can touch ---- */
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const bx = Math.floor(Math.min(...xs)), by = Math.floor(Math.min(...ys));
    return [bx, by, Math.ceil(Math.max(...xs)) - bx, Math.ceil(Math.max(...ys)) - by];
  };
  const T = async (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: await boxOf(world), what }, extra);
  const things = {
    estante: await T([E0 - .05, .02, 0, E1 + .05, SD + .04, CD.WH - .25], 'the second run of shelves, a poke: from the uprights\' outer faces, from the wall to the low cupboard\'s front, up to the uprights\' tops (what colmado-dentro.js draws as part estantes2)'),
    mesa: await T([MX - .85, MY - .5, 0, MX + .85, MY + .5, MH], 'the low display table, a poke: the cloth\'s top and its hanging edges, down to the floor', { when: 'mesa = 1' }),
  };
  for (const k of ['lata', 'botella', 'caja', 'red_a', 'red_b', 'di_siete', 'di_ocho', 'di_nueve', 'di_diez', 'caja_senora', 'caja_senor', 'pepe', 'luis', 'senora', 'senor', 'coqui', 'perro']) things[k] = 'sprite';

  /* ---- the view ---- */
  const vq = (await proj([[vx, vy, 0]]))[0];
  const feasible = lo <= hi;
  const views = { wide: { world: W4([vx, vy, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], what: 'the one view: the 196 x 216 window over the 240 x 216 picture, x0 = clamp(round(sx - 98), 0, 44) for sx the projection of this world point (the floor point on the window\'s middle column, on y = 2.9). x0 = ' + x0 + ': ' + (feasible ? 'the middle of the x0 values (' + lo + '..' + hi + ') that keep the whole run of shelves (columns ' + runL + '..' + runR + '), the ladder (' + ladL + '..' + ladR + ') and the table (' + tableL + '..' + tableR + ') in the window with ' + FLOOR_LEFT + ' px of floor left of the table' : 'the leftmost the picture allows: no x0 gives the table ' + FLOOR_LEFT + ' px of floor on its left (its left edge is column ' + tableL + '); this keeps the whole run of shelves (columns ' + runL + '..' + runR + '), the ladder (' + ladL + '..' + ladR + ') and the table (' + tableL + '..' + tableR + ') in the window and gives the table the most floor') } };

  const sc = G.scene;
  return {
    scene: 'estantes',
    made: 'node docs/proyecto/pixel/estantes-sheet-make.js, from estantes-set.html (window.ESTANTES.CD) and the design of Los estantes. A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      spot: 'a spot is a world point of the feet (z 0: the floor; z .3: the top of the frog\'s crate; z 1.46: a rung) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); Canelo mkPerro (30 x 22): column 13 (the scenes draw it at -13), its lowest drawn row on sy - 1; a small thing standing (can, bottle, box, crate, net): its bottom middle on the point; a thing lying on the floor (a bottle box seen from above) and the drawing on the wall: its middle on the point',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      rungs: 'the ladder has seven rungs at z = LTOP * r / 8 (colmado-dentro.js), LTOP = ESCALERA_ALTO z / .75 = ' + r4(LTOP) + ': ' + rungs.map(r4).join(', ') + '. pepe.escalera is on the fourth, the one nearest z 1.3',
    },
    setKey: {
      params: { anillos: { values: [0, 1], note: 'six rings of dust on the middle shelf (story 39)' }, mesa: { values: [0, 1], note: 'the low display table (story 40)' }, tags: { values: [0, 1], note: 'dev only: tags each pixel by the part that drew it (the checks read it); the game does not use it' } },
      fixed: 'hora manana, atras shut, the ladder always there, no goods drawn (the goods, the cans and the bottles are sprites)',
      key: 'anillos + mesa, e.g. "1-0"',
      baked: STATES.map(([a, m]) => '?anillos=' + a + '&mesa=' + m),
    },
    things,
    spots,
    groups: { 'estante.medio': [0, 1, 2, 3, 4, 5].map(k => 'estante.medio.' + k), 'estante.alto': [0, 1, 2, 3, 4, 5, 6].map(k => 'estante.alto.' + k), 'mesa.fila': [0, 1, 2, 3].map(k => 'mesa.fila.' + k) },
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so the table hides the legs of don Pepe behind it and nothing behind a character hides him.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón\'s front and El mostrador\'s; the same test for people, the dog, the goods on the shelves and the things on the table',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
      after: { 'pepe.escalera': 'don Pepe on the ladder is drawn after the ladder: the pixels of the set\'s part escalera (the ladder) do not hide him (the depth test is skipped on them); every other set pixel still does' },
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, pepe: .35, senora: .35, senor: .35, luis: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)',
      none: ['pepe.escalera', 'coqui.cajon'],
      off_floor: 'a character off the floor (don Pepe on the ladder, the frog on his crate) casts none: the spot\'s z is not 0 (as the frog on El mostrador\'s counter)',
    },
  };
}

/* ---------- the checks that read the set's pixels: every state of the set ---------- */
async function probeSets(page, sheet, load) {
  const S = sheet.spots, R = [];
  const places = Object.keys(S).filter(k => k.startsWith('estante.'));
  // exact projection (floor) of each point: the pixel the point is really in
  const named = ['pepe.escalera', 'mesa.fila.0', 'dibujo', ...places];
  const ex = await page.evaluate(ws => ws.map(w => { const q = project(w[0], w[1], w[2]); return [q.sx, q.sy]; }), named.map(k => S[k].world));
  const pt = {}; named.forEach((k, i) => { pt[k] = { fx: ex[i][0], fy: ex[i][1], exact: Math.floor(ex[i][1]) * 240 + Math.floor(ex[i][0]), rounded: S[k].screen[1] * 240 + S[k].screen[0] }; });
  for (const [a, m] of STATES) {
    await load('tags=1&anillos=' + a + '&mesa=' + m);
    const r = await page.evaluate(arg => {
      const out = { places: {}, at: {}, bbox: {}, rings: [] };
      for (const k of arg.places) out.places[k] = [TAGS[arg.pt[k].exact], TAGS[arg.pt[k].rounded]];
      for (const k of ['pepe.escalera', 'mesa.fila.0', 'dibujo']) { const e = arg.pt[k].exact; out.at[k] = { here: TAGS[e], below: TAGS[e + W], above: TAGS[e - W] }; }
      for (const name of ['estantes2', 'escalera', 'mesa', 'anillos', 'racimo']) {
        let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
        for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === name) { const x = i % W, y = (i / W) | 0; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
        out.bbox[name] = x1 < 0 ? null : [x0, y0, x1, y1];
      }
      // the distance from the drawing's point to the nearest pixel of the hanging plantains (centre of the pixel)
      const dp = arg.pt.dibujo; let best = 1e9; const rx = [];
      for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'racimo') { const x = i % W, y = (i / W) | 0; const d = Math.hypot(x + .5 - dp.fx, y + .5 - dp.fy); if (d < best) best = d; rx.push(x + .5, y + .5); }
      out.racimoDist = best; out.racimo = rx;
      // the same places with the ladder off: is each one a shelf top? (and the rings, whole: the ladder covers some of their pixels)
      ESTANTES.SET.escalera = false; TAGS.fill(null); buildSet();
      out.noLadder = {}; for (const k of arg.places) out.noLadder[k] = [TAGS[arg.pt[k].exact], TAGS[arg.pt[k].rounded]];
      // the rings: the pixels of part 'anillos', grouped by x (a new ring where a column has none)
      const px = []; for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'anillos') px.push([i % W, (i / W) | 0]);
      px.sort((p, q) => p[0] - q[0]);
      let cur = null; for (const p of px) { if (!cur || p[0] - cur[2] > 1) { cur = [p[0], p[1], p[0], p[1]]; out.rings.push(cur); } cur[2] = p[0]; cur[1] = Math.min(cur[1], p[1]); cur[3] = Math.max(cur[3], p[1]); }
      return out;
    }, { places, pt });
    R.push({ anillos: a, mesa: m, ...r });
  }
  return R;
}

/* convex polygons on screen: the least penetration along the edges' normals (> 0: they overlap by that many px, <= 0: they are apart by that many) */
const hull = pts => {
  const P = pts.slice().sort((a, b) => a[0] - b[0] || a[1] - b[1]), cr = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  const lo = [], up = [];
  for (const p of P) { while (lo.length >= 2 && cr(lo[lo.length - 2], lo[lo.length - 1], p) <= 0) lo.pop(); lo.push(p); }
  for (const p of P.slice().reverse()) { while (up.length >= 2 && cr(up[up.length - 2], up[up.length - 1], p) <= 0) up.pop(); up.push(p); }
  return lo.slice(0, -1).concat(up.slice(0, -1));
};
const penetration = (A, B) => {
  let least = Infinity;
  for (const poly of [A, B]) for (let i = 0; i < poly.length; i++) {
    const p = poly[i], q = poly[(i + 1) % poly.length], nx = q[1] - p[1], ny = p[0] - q[0], n = Math.hypot(nx, ny);
    const pr = P => P.map(v => (v[0] * nx + v[1] * ny) / n), a = pr(A), b = pr(B);
    const o = Math.min(Math.max(...a), Math.max(...b)) - Math.max(Math.min(...a), Math.min(...b));
    if (o < least) least = o;
  }
  return least;
};

function checks(sheet, probes, bb) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, OUTS = [];
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const list = (head, bad) => [head].concat(bad.map(l => '  ' + l));
  const at = Object.entries(S);
  const x0 = V.x0, OX = sheet.picture[0] / 2 + sheet.origin.originX, OY = sheet.picture[1] / 2 + sheet.origin.originY, R2 = Math.SQRT2, COS = Math.sqrt(3) / 2;
  const pj = (x, y, z) => [OX + (x - y) / R2 * sheet.S, OY + ((x + y) / R2 * .5 - z * COS) * sheet.S];

  // 1. every spot's screen point is inside the picture and inside the view's window
  {
    const bad = at.filter(([, s]) => s.screen[0] < 0 || s.screen[0] >= sheet.picture[0] || s.screen[1] < 0 || s.screen[1] >= sheet.picture[1]).map(([k, s]) => k + ' ' + s.screen + ' outside the picture');
    const out = at.filter(([, s]) => s.screen[0] < x0 || s.screen[0] >= x0 + 196 || s.screen[1] < 0 || s.screen[1] >= 216).map(([k, s]) => k + ' ' + s.screen + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    const both = bad.concat(out.filter(l => !bad.some(b => b.split(' ')[0] === l.split(' ')[0]))).concat([]);
    add('spots-in-view', both, at.length + ' spot points inside the ' + sheet.picture.join(' x ') + ' picture and the wide window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)', list('spots outside' + (out.length ? ' (the window\'s edge is x0 ' + x0 + ')' : '') + ':', both));
  }

  // 2. every thing's screen box is inside the view
  {
    const withBox = Object.entries(T).filter(([, t]) => t.box);
    const bad = withBox.filter(([, t]) => t.box[0] < x0 || t.box[0] + t.box[2] > x0 + 196 || t.box[1] < 0 || t.box[1] + t.box[3] > 216).map(([k, t]) => k + ' box ' + t.box + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    add('things-in-view', bad, withBox.length + ' things with a box (' + withBox.map(([k, t]) => k + ' ' + t.box).join(', ') + ') inside the wide window', list('things outside:', bad));
  }

  // 3. the people who are on screen together at least 12 px apart (screen points)
  {
    const groups = [
      ['group 1', ['pepe.pie', 'coqui.cajon', 'luis.piso', 'cola1', 'cola2']],
      ['group 2', ['pepe.mesa', 'coqui.piso', 'luis.cajas', 'perro.mesa']],
      ['group 3', ['senora.caja', 'senor.caja', 'luis.cajas', 'coqui.piso']],
    ];
    const near = [], seen = [];
    for (const [g, ns] of groups) {
      let least = Infinity;
      for (let i = 0; i < ns.length; i++) for (let j = i + 1; j < ns.length; j++) {
        const a = S[ns[i]].screen, b = S[ns[j]].screen, d = Math.hypot(a[0] - b[0], a[1] - b[1]);
        least = Math.min(least, d);
        if (d < MIN_APART) near.push(g + ': ' + ns[i] + ' ' + a + ' ~ ' + ns[j] + ' ' + b + ': ' + r2(d) + ' px');
      }
      seen.push(g + ' (' + ns.join(', ') + ') least ' + r2(least) + ' px');
    }
    add('people-apart', near, 'every pair in each group at least ' + MIN_APART + ' px apart: ' + seen.join('; '), list(near.length + ' pair(s) closer than ' + MIN_APART + ' px (screen points):', near));
  }

  // 3b. (v2) the frog and the things near him: screen points at least 14 px apart; and don Pepe's column behind the table at least 22 px from the pyramid's axis
  {
    const apart = (name, a, b, min, why) => {
      const pa = S[a].screen, pb = S[b].screen, d = Math.hypot(pa[0] - pb[0], pa[1] - pb[1]);
      add(name, d < min ? [1] : [], a + ' ' + pa + ' is ' + r2(d) + ' px from ' + b + ' ' + pb + ' (at least ' + min + ')' + why, [a + ' ' + pa + ' is ' + r2(d) + ' px from ' + b + ' ' + pb + ', closer than ' + min + ' px']);
    };
    apart('frog-crate-apart-big-box', 'coqui.cajon', 'caja_grande', 14, '');
    apart('frog-floor-apart-crate-of-cans', 'coqui.piso', 'cajon_latas', 14, '');
    apart('frog-floor-apart-abuela-box', 'coqui.piso', 'caja_abuela', 14, '');
    const a = S['pepe.mesa'].screen[0], b = S['mesa.fila.0'].screen[0], d = Math.abs(a - b);
    add('pepe-mesa-column-apart-pyramid', d < 22 ? [1] : [], 'pepe.mesa\'s column ' + a + ' is ' + d + ' px from the pyramid\'s axis (mesa.fila.0, column ' + b + ') (at least 22)', ['pepe.mesa\'s column ' + a + ' is ' + d + ' px from the pyramid\'s axis (mesa.fila.0, column ' + b + '), closer than 22 px']);
  }

  // 4. the shelf places: each on a shelf top (part estantes2, tags=1), and the ones the ladder is in front of
  {
    const medio = [0, 1, 2, 3, 4, 5].map(k => 'estante.medio.' + k), alto = [0, 1, 2, 3, 4, 5, 6].map(k => 'estante.alto.' + k), all = medio.concat(alto);
    const offShelf = [], behind = new Set();
    for (const p of probes) for (const k of all) {
      const t = p.places[k], nl = p.noLadder[k], tag = 'anillos ' + p.anillos + ', mesa ' + p.mesa;
      const top = v => v === 'estantes2' || (p.anillos === 1 && v === 'anillos');         // with the rings drawn, a ring's pixel is on the shelf top too
      if (!top(nl[0]) || !top(nl[1])) offShelf.push(k + ' (' + tag + ', ladder off): the pixel at its point is ' + nl[0] + ', at the rounded point ' + nl[1]);
      if (!top(t[0]) || !top(t[1])) { if (t.includes('escalera')) behind.add(k); else offShelf.push(k + ' (' + tag + '): the pixel at its point is ' + t[0] + ', at the rounded point ' + t[1] + ', not the ladder'); }
    }
    const m = medio.filter(k => !behind.has(k)), a = alto.filter(k => !behind.has(k));
    const bad = offShelf.slice();
    if (m.length < 5) bad.push('only ' + m.length + ' of the 6 middle places are clear of the ladder (needs 5)');
    if (a.length < 6) bad.push('only ' + a.length + ' of the 7 top places are clear of the ladder (needs 6)');
    const behindList = [...behind].sort();
    add('shelf-places', bad, '13 places x ' + probes.length + ' states of the set (anillos x mesa): each point, exact and rounded, is on a shelf top (part estantes2; with the rings drawn a ring pixel counts, it lies on the top; ladder off); clear of the ladder: ' + m.length + ' of 6 middle, ' + a.length + ' of 7 top; behind the ladder: ' + (behindList.join(', ') || 'none'),
      list('shelf places off:', bad).concat(['  behind the ladder: ' + (behindList.join(', ') || 'none')]));
  }

  // 5. pepe.escalera: his whole figure (53 rows) inside the picture, and his feet on a rung of the set
  {
    const s = S['pepe.escalera'], top = s.screen[1] - PERSON_ROWS, bad = [];
    if (top < 0 || s.screen[1] > sheet.picture[1]) bad.push('rows ' + top + '..' + (s.screen[1] - 1) + ' of the 53-row figure are outside rows 0..' + (sheet.picture[1] - 1));
    // his column: the 48-px canvas centred on sx (info)
    const cols = [s.screen[0] - 24, s.screen[0] + 23];
    add('pepe-escalera-in-picture', bad, 'rows ' + top + '..' + (s.screen[1] - 1) + ' of his 53 (feet on row ' + (s.screen[1] - 1) + ', top on row ' + top + ') inside rows 0..' + (sheet.picture[1] - 1) + '; his 48-px canvas spans columns ' + cols + ' of 0..' + (sheet.picture[0] - 1), list('his figure is outside the picture:', bad));
    const onRung = probes.every(p => [p.at['pepe.escalera'].here, p.at['pepe.escalera'].below, p.at['pepe.escalera'].above].includes('escalera'));
    add('pepe-on-rung', onRung ? [] : ['no ladder pixel at or beside his feet'], 'his feet point (' + s.world + ') is on a ladder pixel (part escalera) or one row above or below it, in all ' + probes.length + ' states', ['the pixel at his feet is ' + probes[0].at['pepe.escalera'].here + ' (above ' + probes[0].at['pepe.escalera'].above + ', below ' + probes[0].at['pepe.escalera'].below + '), not the ladder']);
  }

  // 6. the three bottle boxes do not overlap each other or the table on screen (their footprints on the floor, the table's box)
  {
    const names = ['caja_abuela', 'caja_senora', 'caja_senor'];
    const poly = n => { const [cx, cy] = S[n].world, [fw, fd] = S[n].footprint; return hull([[cx - fw / 2, cy - fd / 2], [cx + fw / 2, cy - fd / 2], [cx + fw / 2, cy + fd / 2], [cx - fw / 2, cy + fd / 2]].map(p => pj(p[0], p[1], 0))); };
    const mw = T.mesa.world, tablePoly = hull([[mw[0], mw[1], mw[2]], [mw[3], mw[1], mw[2]], [mw[3], mw[4], mw[2]], [mw[0], mw[4], mw[2]], [mw[0], mw[1], mw[5]], [mw[3], mw[1], mw[5]], [mw[3], mw[4], mw[5]], [mw[0], mw[4], mw[5]]].map(p => pj(p[0], p[1], p[2])));
    const bad = [], info = [];
    for (let i = 0; i < names.length; i++) {
      for (let j = i + 1; j < names.length; j++) { const p = penetration(poly(names[i]), poly(names[j])); info.push(names[i] + ' / ' + names[j] + ' ' + (p > 0 ? 'overlap ' : 'apart ') + r2(Math.abs(p)) + ' px'); if (p > 0) bad.push(names[i] + ' and ' + names[j] + ' overlap on screen by ' + r2(p) + ' px'); }
      const p = penetration(poly(names[i]), tablePoly); info.push(names[i] + ' / mesa ' + (p > 0 ? 'overlap ' : 'apart ') + r2(Math.abs(p)) + ' px'); if (p > 0) bad.push(names[i] + ' and the table overlap on screen by ' + r2(p) + ' px');
    }
    add('bottle-boxes-apart', bad, 'the three boxes\' footprints (1.0 x .5, long side along x) do not overlap each other or the table\'s box on screen: ' + info.join('; '), list('boxes overlapping on screen (least penetration along the edges\' normals, of the footprint\'s parallelogram; the table by the hull of its box):', bad).concat(['  all pairs: ' + info.join('; ')]));
  }

  // 7. (from the spec's first paragraph) the window holds the whole run of shelves, the ladder, the table, and at least 20 px of floor left of the table
  {
    const win = [x0, x0 + 195], run = [bb.estantes2[0], bb.estantes2[2]], lad = [bb.escalera[0], bb.escalera[2]], tab = [bb.mesa[0], bb.mesa[2]];
    const bad = [];
    for (const [n, r] of [['the run of shelves', run], ['the ladder', lad], ['the table', tab]]) if (r[0] < win[0] || r[1] > win[1]) bad.push(n + ' spans columns ' + r + ', outside the window ' + win);
    const floor = tab[0] - x0;
    if (floor < FLOOR_LEFT) bad.push('the table\'s left edge is column ' + tab[0] + ': only ' + floor + ' px of floor between the window\'s left edge (x0 ' + x0 + ') and the table, not ' + FLOOR_LEFT + (x0 === 0 ? ' (x0 is already 0: the picture has no more room on the left)' : ''));
    add('view-holds-set', bad, 'x0 ' + x0 + ': the run (columns ' + run + '), the ladder (' + lad + ') and the table (' + tab + ') are in the window ' + win + ', with ' + floor + ' px of floor left of the table', list('the window does not hold what the design asks:', bad));
  }

  // 8. (from the spec) dibujo: inside the window and at least 8 px clear of the hanging plantains; else where it could go
  {
    const d = S.dibujo, p0 = probes[0], dist = p0.racimoDist, bad = [];
    if (d.screen[0] < x0 || d.screen[0] >= x0 + 196) bad.push('the point ' + d.screen + ' is outside the window');
    if (dist < DIBUJO_CLEAR) bad.push('the point is ' + r2(dist) + ' px from the plantains (needs ' + DIBUJO_CLEAR + ')');
    let alt = '';
    if (bad.length) {                                                          // the nearest x on the back wall (same y, z) that is clear, between the first run's end and the second run's start
      const rx = p0.racimo; let best = null;
      for (let x = S.dibujo.world[0] - 3; x <= S.dibujo.world[0] + 1.3; x += .05) {
        const q = pj(x, 0, S.dibujo.world[2]); let m = 1e9; for (let i = 0; i < rx.length; i += 2) m = Math.min(m, Math.hypot(rx[i] - q[0], rx[i + 1] - q[1]));
        if (m >= DIBUJO_CLEAR && q[0] >= x0 && q[0] < x0 + 196 && (best === null || Math.abs(x - S.dibujo.world[0]) < Math.abs(best - S.dibujo.world[0]))) best = r2(x);
      }
      alt = ' it could go at x ' + best + ' (y 0, z ' + S.dibujo.world[2] + ')';
    }
    const tags = probes.map(p => p.at.dibujo.here);
    if (!tags.every(t => t === 'pared')) bad.push('the pixel at the point is ' + [...new Set(tags)].join('/') + ', not the wall');
    add('dibujo-clear', bad, 'the drawing\'s point ' + d.screen + ' is inside the window, on the wall, ' + r2(dist) + ' px from the nearest plantain pixel (needs ' + DIBUJO_CLEAR + ')', list('the drawing:', bad).concat(alt ? [' ' + alt] : []));
  }

  // 9. (extra) the six ring places are where the set draws its rings (the centre of each ring's pixels, in the state with the rings)
  {
    const p = probes.find(q => q.anillos === 1), bad = [], seen = [];
    if (p.rings.length !== 6) bad.push('the set draws ' + p.rings.length + ' rings, not 6');
    else for (let k = 0; k < 6; k++) {
      const r = p.rings[k], c = [(r[0] + r[2] + 1) / 2, (r[1] + r[3] + 1) / 2], q = S['estante.medio.' + k].screen, ex = pj(...S['estante.medio.' + k].world);
      const d = Math.hypot(c[0] - ex[0], c[1] - ex[1]); seen.push(k + ': ' + r2(d));
      if (d > 1.5) bad.push('estante.medio.' + k + ' point ' + [r2(ex[0]), r2(ex[1])] + ' is ' + r2(d) + ' px from the centre of its ring\'s pixels ' + c);
    }
    add('rings-match', bad, 'each of the six ring places is within 1.5 px of the centre of the pixels of one of the set\'s six rings (distances ' + seen.join(', ') + ')', list('ring places off:', bad));
  }

  // 10. (extra) the touch boxes cover what the set draws
  {
    const bad = [], seen = [];
    for (const [name, part, st] of [['estante', 'estantes2', probes[0]], ['mesa', 'mesa', probes.find(q => q.mesa === 1)]]) {
      const b = st.bbox[part], bx = T[name].box, tol = 1;
      if (!b) { bad.push(name + ': the set draws no pixel for it'); continue; }
      seen.push(name + ' pixels [' + b + '] in box [' + bx + ']');
      if (!(b[0] >= bx[0] - tol && b[1] >= bx[1] - tol && b[2] <= bx[0] + bx[2] + tol && b[3] <= bx[1] + bx[3] + tol)) bad.push(name + ': its pixels span [' + b + '] (x0, y0, x1, y1), its box is [' + bx + '] (x, y, w, h), more than ' + tol + ' px out');
    }
    add('boxes-cover-set', bad, seen.join('; ') + ' (1 px tolerance)', list('a touch box does not cover what the set draws:', bad));
  }

  // 11. (extra) mesa.fila.0 is on the cloth
  {
    const p = probes.filter(q => q.mesa === 1), bad = p.filter(q => q.at['mesa.fila.0'].here !== 'mesa').map(q => 'anillos ' + q.anillos + ': the pixel at mesa.fila.0 is ' + q.at['mesa.fila.0'].here);
    add('mesa-fila-on-cloth', bad, 'the pixel at mesa.fila.0 ' + S['mesa.fila.0'].screen + ' is drawn by part mesa (the cloth), in both states with the table', list('mesa.fila.0 off the cloth:', bad));
  }
  return OUTS;
}
