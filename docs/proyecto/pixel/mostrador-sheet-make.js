#!/usr/bin/env node
'use strict';
/* El mostrador's sheet: writes docs/proyecto/pixel/mostrador-sheet.json from mostrador-set.html and the design (the orchestrator's mostrador-spec), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/mostrador-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set (window.MOSTRADOR.CD: the room's constants) in headless Chrome,
   projects every world point with the engine's own project() (pp-engine.js), and writes the spots, things, view, shadows and the depth rule.
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

// the two numbers of the design for "seen from the thighs up": a person 49 rows tall, of which at least 28 above the counter's top back edge
const PERSON = { rows: 49, minAbove: 28 };
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_APART = 10;                                    // px between two people's feet on screen

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
  await load('props=1&tags=1');
  const G = await page.evaluate(() => { const o = {}; for (const [k, v] of Object.entries(MOSTRADOR.CD)) if (typeof v !== 'function') o[k] = v; return { CD: o, scene: PP_SCENE, W, H, S, OX, OY }; });
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);
  const sheet = await make(G, proj);
  // the checks that read the set's own pixels: every state of the set (hora x atras x nevera), goods drawn (props=1), each pixel tagged by the part that drew it (tags=1)
  const probes = await probeSets(page, sheet, load);
  const results = checks(sheet, probes);
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

/* ---------- the sheet ---------- */
async function make(G, proj) {
  const CD = G.CD, CH = CD.CH, SZ = CD.SZ, GOODS = CD.GOODS;
  const P1 = async p => (await proj([p]))[0];
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];

  /* ---- spots: the ground (or the counter top, or the seat) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, what]
  const person = (name, w, what) => D.push([name, w, 'person', what]);
  const onCounter = (name, x, y, what) => D.push([name, [x, y, CH], 'counter', what]);
  person('pepe.mostrador', [3.6, 1.15, 0], 'don Pepe\'s usual place, behind the counter');
  for (const [k, , x] of GOODS) person('pepe.estante.' + k, [x, .95, 0], 'don Pepe in front of the shelves, reaching up to ' + k);
  person('pepe.atras', [.7, .6, 0], 'don Pepe at the back door');
  person('pepe.silla', [5.2, 1.15, 0], 'don Pepe sitting behind the counter with his fan (story 38)');
  person('coqui.frente', [4.6, 4.3, 0], 'the frog on the floor, in front of the counter');
  person('coqui.mostrador_izq', [2.1, 2.38, CH], 'the frog on the counter top, left (far end from don Pepe\'s chair)');
  person('coqui.mostrador_der', [4.6, 2.38, CH], 'the frog on the counter top, right');
  person('abuela.frente', [3.6, 3.9, 0], 'abuela standing in front of the counter');
  person('abuela.silla', [CD.SILLA[0], CD.SILLA[1], .45], 'abuela sitting in the waiting chair; z .45 is the chair\'s seat top (colmado-dentro.js chairs()); the sitting sprite is anchored by her lap, rules.anchor');
  person('nino.frente', [5.2, 3.8, 0], 'Luis or Carmen at the counter');
  person('nino.puerta_dentro', [1.0, 4.9, 0], 'Carmen looking out of the street door, inside');
  person('cliente', [2.9, 3.75, 0], 'the customer being served');
  person('cola1', [1.9, 4.35, 0], 'waiting, first');
  person('cola2', [1.2, 4.9, 0], 'waiting, second');
  person('puerta', [.45, 4.3, 0], 'just inside the street door');
  person('fuera', [-.35, 4.3, 0], 'on the pavement, seen through the street door (no shadow)');
  [3.85, 4.3, 4.75].forEach((y, i) => person('ninos_fuera.' + (i + 1), [-.35, y, 0], 'child ' + (i + 1) + ' of the three outside the door (no shadow); group ninos_fuera'));
  onCounter('bandeja', 5.5, 2.38, 'the tray of quesitos');
  onCounter('platillo', 3.4, 2.15, 'the coin dish');
  onCounter('cosa_a', 2.75, 2.5, 'the first of the two things in front of the frog');
  onCounter('cosa_b', 3.45, 2.5, 'the second of the two things in front of the frog');
  onCounter('compra', 4.1, 2.5, 'where a thing taken down from a shelf is set');
  onCounter('monedas', 4.7, 2.62, 'the first of Carmen\'s coins; the row runs towards +x (dir)');
  onCounter('maltas', 5.9, 2.25, 'the malts');
  onCounter('limber_pepe', 5.0, 2.45, 'a límber at don Pepe\'s end');
  onCounter('limber_lejos', 2.6, 2.45, 'a límber at the far end');
  onCounter('bolsa', 4.4, 2.55, 'the bag being packed');
  for (const [k, s, x] of GOODS) D.push(['estante.' + k, [x, .19, SZ[s] + .06], 'shelf', 'where ' + k + ' stands on its shelf (the plank\'s top)']);
  const pr = await proj(D.map(d => d[1]));
  const spots = {}, depth = {};
  D.forEach((d, i) => {
    const q = pr[i];
    spots[d[0]] = { world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2], what: d[3] };
    depth[d[0]] = q[2];
  });
  spots['monedas'].dir = [1, 0, 0];
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
  // the freezer: the box colmado-dentro.js counter() draws (x0 = CX1 - 1.15, x1 = CX1 - .15, y0 = CY0 + .1, y1 = CY1 - .08, z0 = CH, z1 = CH + .42)
  const NEV = [CD.CX1 - 1.15, CD.CY0 + .1, CH, CD.CX1 - .15, CD.CY1 - .08, CH + .42];
  const SL = CD.SILLA;
  const things = {
    nevera: await T(NEV, 'the little freezer on the counter, only when nevera = 1 (the box colmado-dentro.js draws)', { when: 'nevera = 1' }),
    mostrador: await T([CD.CX0, CD.CY0, 0, CD.CX1, CD.CY1, CH], 'the counter, a poke'),
    puerta: await T([0, CD.PD0, 0, .02, CD.PD1, CD.DH], 'the street door, a poke'),
    silla: await T([SL[0] - .4, SL[1] - .4, 0, SL[0] + .4, SL[1] + .4, 1.05], 'the waiting chair: a box round CD.SILLA, .8 wide and 1.05 high'),
  };
  for (const k of ['leche', 'pan', 'mantequilla', 'queso', 'cafe', 'arroz', 'azucar', 'jugo', 'habichuelas', 'bolsa', 'limber_a', 'limber_b', 'quesitos', 'pepe', 'abuela', 'luis', 'carmen', 'senora', 'senor', 'ninos', 'coqui', 'si', 'no']) things[k] = 'sprite';

  /* ---- the view ---- */
  const vq = await P1([3.2, 2.9, 0]), vs = [r2(vq[0]), r2(vq[1])], vx0 = Math.max(0, Math.min(G.W - 196, Math.round(vs[0] - 98)));
  const views = { dentro: { world: [3.2, 2.9, 0], screen: vs, zoom: 1, x0: vx0, region: [vx0, 0, 196, 216], what: 'inside the shop: the 196 x 216 window over the 240 x 216 picture, centred on this point (x0 = clamp(round(sx - 98), 0, 44)); donde=calle is another picture, a later order' } };

  const groups = { ninos_fuera: ['ninos_fuera.1', 'ninos_fuera.2', 'ninos_fuera.3'] };
  const sc = G.scene;
  return {
    scene: 'mostrador',
    made: 'node docs/proyecto/pixel/mostrador-sheet-make.js, from mostrador-set.html (window.MOSTRADOR.CD) and the design of El mostrador. A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      spot: 'a spot is a world point of the feet (z 0: the floor; z 1: the counter top; z .45: the seat) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), 46 sitting (a 49-row canvas); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a small thing: its bottom middle on the point',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      person: 'for the check "seen from the thighs up": a person is ' + PERSON.rows + ' rows tall, at least ' + PERSON.minAbove + ' of them above the counter\'s top back edge at his column',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: {
      params: { donde: { values: ['dentro'], later: 'calle: a later order' }, hora: { values: ['manana', 'tarde'] }, atras: { values: ['shut', 'open'] }, nevera: { values: [0, 1] }, props: { values: [0, 1], note: 'props=1 draws stand-in goods on the shelves for readers\' renders; the game uses 0 and draws the goods as sprites' } },
      key: 'hora + atras + nevera, e.g. "manana-shut-0"',
      baked: ['manana', 'tarde'].flatMap(h => ['shut', 'open'].flatMap(a => [0, 1].map(n => '?donde=dentro&hora=' + h + '&atras=' + a + '&nevera=' + n))),
    },
    things,
    later: { colmado: 'the shop front, only in donde=calle: not in this order' },
    spots: spotsOrdered,
    groups,
    views,
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
      none: ['pepe.fuera', 'fuera', 'ninos_fuera.1', 'ninos_fuera.2', 'ninos_fuera.3'],
      onCounter: 'the frog on the counter top (z 1) casts none: the counter top is not ground in colmado-dentro.js (no slab), so a shadow has nothing to land on, and one cast at the floor under him would show in front of the counter',
    },
  };
}

/* ---------- the checks that read the set's pixels: every state of the set ---------- */
async function probeSets(page, sheet, load) {
  const S = sheet.spots, R = [];
  const goods = Object.keys(S).filter(k => k.startsWith('estante.'));
  const pix = [];                                                            // the pixel the point is in, and the pixel at the rounded point
  for (const k of goods) { const sp = S[k].screen, w = S[k].world; pix.push({ k, rounded: sp[1] * 240 + sp[0] }); }
  // exact projection (floor) of each shelf place: the pixel the point is really in
  const ex = await page.evaluate(ws => ws.map(w => { const q = project(w[0], w[1], w[2]); return (Math.floor(q.sy)) * W + Math.floor(q.sx); }), goods.map(k => S[k].world));
  pix.forEach((p, i) => { p.exact = ex[i]; });
  const pepes = Object.keys(S).filter(k => k === 'pepe.mostrador' || k.startsWith('pepe.estante.')).map(k => ({ k, cx: S[k].screen[0], row: S[k].screen[1], d: S[k].depth }));
  for (const hora of ['manana', 'tarde']) for (const atras of ['shut', 'open']) for (const nevera of [0, 1]) {
    await load('props=1&tags=1&donde=dentro&hora=' + hora + '&atras=' + atras + '&nevera=' + nevera);
    const r = await page.evaluate(arg => {
      const out = { goods: {}, bbox: {}, pepes: {} };
      for (const p of arg.pix) out.goods[p.k] = [TAGS[p.exact], TAGS[p.rounded]];
      for (const name of ['nevera', 'silla', 'mostrador', 'puerta']) {
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

function checks(sheet, probes) {
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

  // 2. no two spots of people who can be on screen together closer than 10 px
  {
    const people = at.filter(([, s]) => s.kind === 'person');
    // one character has one body: all pepe.*, all coqui.*, all abuela.* spots are alternatives. nino.frente (Luis or Carmen at the counter) and nino.puerta_dentro (Carmen at the door)
    // can be two children; cliente, cola1, cola2, puerta, fuera and each of the three ninos_fuera are different people. fuera and ninos_fuera.* are the same place on the pavement: alternatives
    const who = n => /^(pepe|coqui|abuela)\./.test(n) ? n.split('.')[0] : n;
    const alt = (a, b) => (a === 'fuera' && b.startsWith('ninos_fuera.')) || (b === 'fuera' && a.startsWith('ninos_fuera.'));
    const near = [];
    for (let i = 0; i < people.length; i++) for (let j = i + 1; j < people.length; j++) {
      const [a, sa] = people[i], [b, sb] = people[j];
      if (who(a) === who(b) || alt(a, b)) continue;
      const d = Math.hypot(sa.screen[0] - sb.screen[0], sa.screen[1] - sb.screen[1]);
      if (d < MIN_APART) near.push([a, b, d]);
    }
    near.sort((p, q) => p[2] - q[2] || (p[0] + p[1]).localeCompare(q[0] + q[1]));
    const pairs = people.length * (people.length - 1) / 2;
    add('people-apart', near, 'no two of the people spots that can be on screen together are closer than ' + MIN_APART + ' px (same character\'s spots and fuera / ninos_fuera are alternatives, not compared)',
      [(near.length) + ' pair(s) closer than ' + MIN_APART + ' px (screen points; pepe.*, coqui.*, abuela.* are each one character; fuera and ninos_fuera.* are alternatives):'].concat(near.map(p => '  ' + p[0] + ' ' + S[p[0]].screen + ' ~ ' + p[1] + ' ' + S[p[1]].screen + ': ' + r2(p[2]) + ' px')));
  }

  // 3. every thing's screen box is inside the view
  {
    const bad = Object.entries(T).filter(([, t]) => t.box).filter(([, t]) => t.box[0] < x0 || t.box[0] + t.box[2] > x0 + 196 || t.box[1] < 0 || t.box[1] + t.box[3] > 216).map(([k, t]) => k + ' box ' + t.box + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    const n = Object.values(T).filter(t => t.box).length;
    add('things-in-view', bad, n + ' things with a box (' + Object.entries(T).filter(([, t]) => t.box).map(([k, t]) => k + ' ' + t.box).join(', ') + ') inside the dentro window', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 4. don Pepe seen from the thighs up: at least 28 rows of a 49-row person above the counter's top back edge at his column
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
    add('pepe-thighs-up', bad, ps.length + ' places: of a ' + rows + '-row person at least ' + minAbove + ' rows above the counter\'s top back edge (minimum, needs ' + min + '), and ' + minDepth + ' rows clear from the top by the depth rule; for the standing mkPersona, which draws 53 rows (info, not a check): ' + r2(minAbove + 53 - rows) + ' rows',
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

  // 6. (extra) the touch boxes of what the set draws cover its pixels
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

  // 7. (extra) the counter-top spots are on the counter top
  {
    const m = T.mostrador.world, bad = Object.entries(S).filter(([, s]) => s.kind === 'counter' || (s.world && s.world[2] === m[5])).filter(([, s]) => s.world[0] < m[0] || s.world[0] > m[3] || s.world[1] < m[1] || s.world[1] > m[4]).map(([k, s]) => k + ' ' + s.world);
    const n = Object.entries(S).filter(([, s]) => s.kind === 'counter' || (s.world && s.world[2] === m[5])).length;
    add('counter-spots-on-top', bad, n + ' spots at z = CH (the counter things and the frog\'s two) are inside the counter top x ' + m[0] + '..' + m[3] + ', y ' + m[1] + '..' + m[4], ['spots off the counter top:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    // info: which counter-top spots lie under the freezer's footprint (they cannot be in a nevera = 1 picture)
    const n0 = T.nevera.world, under = Object.entries(S).filter(([, s]) => s.world && s.world[2] === m[5]).filter(([, s]) => s.world[0] >= n0[0] && s.world[0] <= n0[3] && s.world[1] >= n0[1] && s.world[1] <= n0[4]).map(([k]) => k);
    OUTS[OUTS.length - 1].lines.push('       info, not a check: under the freezer\'s footprint (x ' + r2(n0[0]) + '..' + r2(n0[3]) + ', y ' + r2(n0[1]) + '..' + r2(n0[4]) + '), so not usable while nevera = 1: ' + (under.join(', ') || 'none'));
    OUTS[OUTS.length - 1].under = under;
  }
  return OUTS;
}
