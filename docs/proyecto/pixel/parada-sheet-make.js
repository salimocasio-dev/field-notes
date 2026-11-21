#!/usr/bin/env node
'use strict';
/* La parada's sheet: writes docs/proyecto/pixel/parada-sheet.json from parada-set.html and the design (the orchestrator's p5-spec, section "parada"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/parada-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set (window.PARADA.E: the stop's constants) in headless Chrome, projects every world point with
   the engine's own project() (pp-engine.js), reads the pixels the set drew for each part (tags=1), and writes the spots, things, view, shadows and the depth rule, the same as
   El mostrador's and Las frutas' sheets. The guaguas are drawn by the set itself (its autos= parameter) for the readers' pictures; in the game they are sprites.
   The sprites' silhouettes (the frog, abuela, the señora and the señor, the children, Canelo and the heads at the guagua's glass) are read from parada-preview.html (PREVIEW.sil(),
   today's makers: historia/engine.js, escenas/kit.js), and the checks that read the preview's moments use PREVIEW.inspect(m): the sheet is written first without its checks,
   the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   A check that fails because a number of the spec fails it is a finding: the spec's number is kept in the sheet, and the check's lines say by how much it fails and give the nearest value that passes
   (along x or y of the spot, steps of .01). The lines marked "info, not a check" report what the spec does not ask for (what a sprite is drawn over, the sun, the lamp).
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with PARADA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'parada-sheet.json');
const BASE = process.env.PARADA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/parada-set.html';
const PREVIEW = BASE + '/docs/proyecto/pixel/parada-preview.html';
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

/* ---------- the numbers of the design (p5-spec, "parada") ---------- */
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (width in px, the feet's spot in the middle): the frog 32, a grown-up 24, a child 24, a dog 28; apart up-down by 12
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const SEAT_TOP = .46, SEAT_DEPTH = .5;                   // the seat: x E.SEAT[0] to E.SEAT[2], y E.SEAT[1] to + SEAT_DEPTH, top z SEAT_TOP
const CANELO_MIN = .6;                                   // Canelo: at least 60% of him shows
const COLA_Y = 6.0;
// the guagua at the stop (spec: 4.4 long, 1.3 wide, heading i: its front end is its -x end, its lit side y = lane + 1.3 / 2; doors and buttons measured from the front end)
const GUAGUA = { length: 4.4, width: 1.3, front: [.35, 1.15], back: [3.2, 4.0], buttons: [1.32, 3.04], buttonZ: .8 };
// read from calle-base.js (vehicle(), the guagua's side): the doors' leaves stand from z .3 (the body's foot) to 1.95, the arrow beside a door is .24 wide (the door's near side), and the row of windows
const GUAGUA_SRC = { doorZ: [.3, 1.95], arrow: .24, windows: { z: [1.15, 1.85], from: 1.55, pane: .54, period: .68 } };
const ARROW_LEFT = { sube: 1.2, baja: 2.92 };            // calle-base.js: the arrows start here (the front door's, the back door's), measured from the front end; the button is .12 on
// a door with its arrow and its button, from the front end: the front door's leaf and the arrow beside it (the button is on the arrow's .12); the back door: its arrow (the button is on it) and the leaf
const DOOR = { sube: [GUAGUA.front[0], ARROW_LEFT.sube + GUAGUA_SRC.arrow], baja: [ARROW_LEFT.baja, GUAGUA.back[1]] };
const WHO_SIL = { adulto: ['adulto', 'abuela', 'senor'], nino: ['nino', 'carmen', 'nino3'], coqui: ['coqui'], perro: ['perro_lie', 'perro_sit'], head: ['cabeza_abuela'], chofer: ['chofer'], sentado: ['abuela_sent', 'senora_sent', 'senor_sent'] };

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  const load = async q => { await page.goto(PAGE + '?' + q); };
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);
  const SIL = await silhouettes(browser, errs);

  await load('tags=1&hora=manana');
  const G = await page.evaluate(() => ({ E: PARADA.E, scene: PP_SCENE, W, H, S, OX, OY }));
  const E = G.E, LANE = E.LANE2;
  const autosQ = list => '&autos=' + encodeURIComponent(list.map(([b, x]) => 'guagua@' + x + ',' + LANE + ',i,' + b).join(';'));
  const extents = await guaguaExtents(page, load, E, autosQ);                      // the pixels each guagua draws
  const parts = await partBoxes(page, load);                                       // the pixel boxes of the sign, the seat and the post
  const sheet = await make(G, proj, SIL, extents, parts);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, load, sheet, SIL, autosQ, G);
  const PVD = await previewData(browser, errs);
  const COV = await coverTags(page, load, PVD);
  const results = checks(sheet, probes, SIL, G, PVD, extents, parts, COV);
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

/* ---------- the sprites' silhouettes: PREVIEW.sil() (the preview's own makers): [dx, dy] of each drawn pixel from the spot's column and row (dy -1 is the feet's row) ---------- */
async function silhouettes(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREVIEW + '?nosheet=1');
  await p.evaluate(() => window.PREVIEW.done);
  const sil = await p.evaluate(() => window.PREVIEW.sil());
  await p.close();
  return sil;
}

/* ---------- the preview's moments: parada-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREVIEW + '?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const out = {};
  for (const m of [1, 2, 3, 4, 5, 6]) out[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m);
  await p.close();
  return out;
}

/* ---------- what each sprite of a moment draws over: the set's part under each shown pixel (tags=1, in the moment's own state) ---------- */
async function coverTags(page, load, PVD) {
  const out = {};
  for (const m of [1, 2, 3, 4, 5, 6]) {
    const st = PVD[m].set;
    await load('tags=1&hora=' + st.hora + (st.autos.length ? '&autos=' + encodeURIComponent(st.autos.map(([b, x]) => 'guagua@' + x + ',4.6,i,' + b).join(';')) : ''));
    out[m] = await page.evaluate(layers => layers.map(l => { const t = { shown: {}, hidden: {}, nearer: {} }, Z = DEPTH.z; for (const p of l) { const i = p[1] * W + p[0], k = TAGS[i] || 'ground', h = p[2] ? t.hidden : t.shown; h[k] = (h[k] || 0) + 1; if (!p[2] && Z[i] > p[3] + 1e-6) t.nearer[k] = (t.nearer[k] || 0) + 1; } return t; }), PVD[m].layers.map(l => l.px.map(p => [p[0], p[1], p[2], p[3]])));
  }
  return out;
}

/* ---------- what the set draws for the two guaguas: the pixels tagged auto, for each (alone, with each of the three boards: the board's plate is a different drawing) ---------- */
async function guaguaExtents(page, load, E, autosQ) {
  const out = {};
  for (const [name, P] of [['parada1', E.P1], ['parada2', E.P2]]) {
    const seen = new Set();
    for (const board of ['arbol', 'toldo', 'casa']) {
      await load('tags=1&hora=manana' + autosQ([[board, P]]));
      const px = await page.evaluate(() => { const o = []; for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'auto') o.push(i); return o; });
      for (const i of px) seen.add(i);
    }
    const W = 240, pix = [...seen].map(i => [i % W, (i / W) | 0]);
    out[name] = { P, pix, count: pix.length, box: [Math.min(...pix.map(p => p[0])), Math.min(...pix.map(p => p[1])), Math.max(...pix.map(p => p[0])), Math.max(...pix.map(p => p[1]))] };
  }
  return out;
}

// the sign, the seat and the walking post: the pixels the set draws for each part (tags=1); and the street lamp (lit at noche)
async function partBoxes(page, load) {
  const read = names => page.evaluate(names => {
    const o = {};
    for (const n of names) { let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1, c = 0; const cols = {}; for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === n) { const x = i % W, y = (i / W) | 0; x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); c++; cols[x] = (cols[x] || 0) + 1; } o[n] = { box: [x0, y0, x1 - x0 + 1, y1 - y0 + 1], count: c, cols }; }
    return o;
  }, names);
  await load('tags=1&hora=manana');
  const o = await read(['parada', 'asiento', 'poste']);
  await load('tags=1&hora=noche');
  o.farol = (await read(['farol'])).farol;
  return o;
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL, extents, parts) {
  const E = G.E, LANE = E.LANE2, P1 = E.P1, P2 = E.P2, R2 = Math.SQRT2;
  const side = r4(LANE + GUAGUA.width / 2);                                            // the guagua's lit side
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];

  /* ---- spots: the world point of the feet (z 0: the pavement; z SEAT_TOP: the seat's top); frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, who, what, extra]
  const add = (name, w, kind, who, what, extra) => D.push([name, w.map(r4), kind, who, what, extra || {}]);
  add('bordillo.abuela', [-2.3, 6.4, 0], 'person', 'adulto', 'abuela at the kerb (51\'s start)');
  add('bordillo.coqui', [-1.5, 6.3, 0], 'person', 'coqui', 'the frog at the kerb (51\'s start)');
  add('bordillo.luis', [-3.1, 6.5, 0], 'person', 'nino', 'Luis at the kerb (51\'s start)');
  add('bordillo.carmen', [-.8, 6.5, 0], 'person', 'nino', 'Carmen at the kerb (51\'s start)');
  add('banco1', [.75, 7.6, SEAT_TOP], 'seat', 'adulto', 'on the seat, the first place: the señora (51), the señor (53); a person sits on the top of the seat (z ' + SEAT_TOP + ')', { sil: 'sentado' });
  add('banco2', [1.4, 7.6, SEAT_TOP], 'seat', 'adulto', 'on the seat, the second place: abuela (53)', { sil: 'sentado' });
  add('banco3', [2.05, 7.6, SEAT_TOP], 'seat', null, 'on the seat, the third place: the ball (53); a small thing: its bottom middle on the point');
  add('bajo_banco', [1.5, 8.2, 0], 'person', 'perro', 'Canelo lying in front of the seat');
  // the guaguas that stand at the stop: P is the middle's x. Names without a suffix are the guagua at P1 (the one of story 52's game), `.2` the guagua at P2
  for (const [suf, P, who] of [['', P1, 'first'], ['.2', P2, 'second']]) {
    const g = who + ' guagua (middle x ' + P + ')';
    add('parada' + (suf ? '2' : '1'), [P, LANE, 0], 'vehicle', null, 'where the ' + g + ' stands (its middle, in the stop\'s lane): the set draws it with autos=guagua@' + P + ',' + LANE + ',i,<board>');
    add('puerta_sube' + suf, [P - 1.45, 5.3, 0], 'door', 'adulto', 'the front door of the ' + g + ': in front of its lit side (y ' + side + ')', { street: true });
    add('puerta_baja' + suf, [P + 1.4, 5.3, 0], 'door', 'adulto', 'the back door of the ' + g, { street: true });
    add('espera_sube' + suf, [P - 1.45, 5.95, 0], 'person', 'adulto', 'a person about to get on, at the front door of the ' + g);
    add('espera_baja' + suf, [P + 1.4, 5.95, 0], 'person', 'adulto', 'a person who got off, at the back door of the ' + g);
    add('boton_sube' + suf, [P - .88, 5.26, GUAGUA.buttonZ], 'button', null, 'the front door\'s button (on the lit side, z ' + GUAGUA.buttonZ + ') of the ' + g);
    add('boton_baja' + suf, [P + .84, 5.26, GUAGUA.buttonZ], 'button', null, 'the back door\'s button of the ' + g);
    add('coqui.boton_sube' + suf, [P - .88, 5.85, 0], 'person', 'coqui', 'the frog pressing the front door\'s button of the ' + g + ' (on the pavement, at the button\'s x)');
    add('coqui.boton_baja' + suf, [P + .84, 5.85, 0], 'person', 'coqui', 'the frog pressing the back door\'s button of the ' + g);
  }
  add('coqui.botones', [P1, 5.9, 0], 'person', 'coqui', 'the frog between the two buttons of the guagua at P1 (52\'s game)');
  add('cola1', [P1 - 1.6, COLA_Y, 0], 'person', 'adulto', 'a person waiting to get on at the first guagua');
  add('cola2', [P1 - 2.2, 6.4, 0], 'person', 'adulto', 'a person waiting to get on at the first guagua');
  add('cola3', [P1 - 1.0, 6.5, 0], 'person', 'nino', 'a person waiting to get on at the first guagua');
  add('ventana1', [P1 - .4, side, 1.5], 'head', 'head', 'the first window of the guagua at P1: abuela\'s head at the glass (with the basket of rolls on the sill, z ' + GUAGUA_SRC.windows.z[0] + '); the point is the middle of the face; a sprite detail');
  add('ventana2', [P1 + .3, side, 1.5], 'head', 'head', 'the second window: Luis and the frog are seen here (heads at the glass); a sprite detail');
  add('chofer', [P1 - 2.0, side, 1.5], 'head', 'chofer', 'the driver leaning out at the front end of the guagua at P1 (head and shoulders); a sprite detail');
  add('poste', [E.POST[0], E.POST[1], 0], 'person', 'coqui', 'the walking post (E.POST): the frog stands at it (53); the post is drawn by the set');
  add('coqui.arranca', [E.POST[0] + .7, 9.0, 0], 'person', 'coqui', 'the frog starting to walk off along the path (E.POST x + .7, y 9)');
  add('camino', [(E.PATH[0] + E.PATH[1]) / 2, 10.6, 0], 'exit', 'coqui', 'where the footpath across the grass leaves the picture (the middle of E.PATH, y 10.6): the frog walking off leaves the picture here', { street: true });
  add('senor.llega', [3.6, 8.0, 0], 'person', 'adulto', 'the señor arriving (53); then he sits at banco1');
  add('fin.abuela', [.2, 6.6, 0], 'person', 'adulto', 'story 53\'s ending, on the pavement: abuela (the places are the spec\'s four, in the order its names are listed)');
  add('fin.luis', [1.0, 6.4, 0], 'person', 'nino', 'story 53\'s ending: Luis with the ball');
  add('fin.carmen', [1.8, 6.6, 0], 'person', 'nino', 'story 53\'s ending: Carmen');
  add('fin.coqui', [2.6, 6.4, 0], 'person', 'coqui', 'story 53\'s ending: the frog');
  const pr = await proj(D.map(d => d[1]));
  const spriteBox = (who, key) => {                                                    // the sprite box relative to the spot: the spec's width, and the real drawn pixels
    if (!who) return null;
    const keys = WHO_SIL[key || who], boxes = keys.map(k => SIL[k].box), w = WIDTH[who];
    const x0 = Math.min(...boxes.map(b => b[0]), w ? -w / 2 : 0), x1 = Math.max(...boxes.map(b => b[2]), w ? w / 2 - 1 : 0);
    return [x0, Math.min(...boxes.map(b => b[1])), x1, Math.max(...boxes.map(b => b[3]))];
  };
  const spots = {};
  D.forEach((d, i) => {
    const q = pr[i], [name, w, kind, who, what, extra] = d, s = { world: w, screen: scr(q), depth: r4(q[2]), scale: 1, kind };
    if (who) s.who = who;
    if (who && (WHO_SIL[extra.sil || who])) s.sprite = spriteBox(who === 'head' || who === 'chofer' ? who : who, extra.sil);
    s.what = what;
    if (extra.street) s.on_street = true;
    spots[name] = s;
  });

  /* ---- things he can touch ---- */
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  const things = {};
  // parada: the stop's sign and the seat: two boxes; the screen box of each is the box of the pixels the set draws for that part (tags=1). The worlds are read from parada-set.html's calls (CL.signPole at E.SIGN, 2.3 high, .62 wide; CL.seat at E.SEAT)
  const signW = [E.SIGN[0] - .31, E.SIGN[1] - .045, 0, E.SIGN[0] + .31, E.SIGN[1] + .06, 2.3], seatW = [E.SEAT[0], E.SEAT[1] - .02, 0, E.SEAT[2], E.SEAT[1] + SEAT_DEPTH, 1.0];
  things.parada = { set: true, boxes: [{ part: 'sign', world: W4(signW), box: parts.parada.box }, { part: 'seat', world: W4(seatW), box: parts.asiento.box }],
    what: 'the stop: the sign on its pole (E.SIGN) and the seat (E.SEAT): TWO boxes, a touch on either is a touch on parada; each box is the screen box of the pixels the set draws for that part (tags=1: parada, asiento); from_world is the world box projected (the worlds are read from the set\'s calls)' };
  const postW = [E.POST[0] - .25, E.POST[1] - .045, 0, E.POST[0] + .25, E.POST[1] + .06, 1.5];
  things.parada.boxes[0].from_world = await boxOf(signW); things.parada.boxes[1].from_world = await boxOf(seatW);
  things.poste = { set: true, world: W4(postW), box: parts.poste.box, from_world: await boxOf(postW), what: 'the walking post (E.POST) with its board: the screen box of the pixels the set draws for part poste (tags=1); its world box is read from the set\'s call (CL.signPole, 1.5 high, .5 wide) and from_world is that box projected' };
  const doorBox = (P, which) => {                                                      // a door's world box on the guagua's lit side: the door, the arrow and the button
    const L = P - GUAGUA.length / 2;
    return [r4(L + DOOR[which][0]), side, GUAGUA_SRC.doorZ[0], r4(L + DOOR[which][1]), r4(side + .05), GUAGUA_SRC.doorZ[1]];
  };
  const DOORS = { sube: doorBox(P1, 'sube'), baja: doorBox(P1, 'baja') };
  things.puerta_sube = { set: false, world: DOORS.sube, box: await boxOf(DOORS.sube), what: 'the front door of the guagua at P1 (the one of story 52\'s game) with its arrow and button: on the guagua\'s lit side (y ' + side + '), from the door\'s front edge (' + DOOR.sube[0] + ' from the front end) to the arrow\'s end (' + DOOR.sube[1] + '), z ' + GUAGUA_SRC.doorZ.join(' to ') + '. A guagua is a sprite in the game: this box moves with it (add P - ' + P1 + ' to x)' };
  things.puerta_baja = { set: false, world: DOORS.baja, box: await boxOf(DOORS.baja), what: 'the back door of the guagua at P1 with its arrow and button: from the arrow (' + DOOR.baja[0] + ' from the front end) to the door\'s far edge (' + DOOR.baja[1] + '). A guagua is a sprite: this box moves with it (add P - ' + P1 + ' to x)' };
  for (const k of ['guagua_a', 'guagua_b', 'bola', 'abuela', 'luis', 'carmen', 'senora', 'senor', 'chofer', 'coqui', 'perro']) things[k] = 'sprite';

  /* ---- the view: one, wide. x0 is the window's left edge: chosen so that every spot's sprite is inside (the parts of a sprite that the picture itself lacks are the picture's, not the window's); then the fewest pixels of the two guaguas cut ---- */
  const ink = Object.entries(spots).filter(([, s]) => s.kind !== 'exit').map(([k, s]) => { const b = s.sprite || [0, 0, 0, 0]; return [k, Math.max(0, s.screen[0] + b[0]), Math.min(239, s.screen[0] + b[2])]; });
  const pixCut = (name, x0) => extents[name].pix.filter(p => p[0] < x0 || p[0] >= x0 + 196).length;
  let best = null;
  for (let x0 = 0; x0 <= G.W - 196; x0++) {
    const cutSpots = ink.filter(([, lo, hi]) => lo < x0 || hi >= x0 + 196).map(a => a[0]), g = pixCut('parada1', x0) + pixCut('parada2', x0), cand = [cutSpots.length, g, x0];
    if (!best || cand[0] < best.c[0] || (cand[0] === best.c[0] && (cand[1] < best.c[1] || (cand[1] === best.c[1] && cand[2] < best.c[2])))) best = { x0, c: cand, cutSpots };
  }
  const x0 = best.x0, lo = Math.min(...ink.map(a => a[1])), hi = Math.max(...ink.map(a => a[2])), vy = 6.4, ux = vy + ((x0 + 98 - G.OX) / G.S) * R2;
  const vq = (await proj([[ux, vy, 0]]))[0];
  const views = { wide: { world: W4([ux, vy, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], extent: [lo, hi],
    what: 'the one view: the 196 x 216 window over the 240 x 216 picture. x0 is the least x0 (of 0 to 44) that leaves the fewest spots\' sprites cut, then the fewest pixels of the two guaguas cut (the window can hold the spots\' sprites, columns ' + lo + ' to ' + hi + ', but not both guaguas whole: see the check guaguas-whole). Its point is the ground point (at y ' + vy + ') under the window\'s middle column' } };

  const sc = G.scene;
  return {
    scene: 'parada',
    made: 'node docs/proyecto/pixel/parada-sheet-make.js, from parada-set.html (window.PARADA.E, calle-base.js) and the design of La parada (p5-spec). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels. The houses\' wall is y = 0 (it faces +y); the street runs from y ' + E.S0 + ' to ' + E.S1 + ', the stop\'s lane is y ' + LANE + ', the near pavement from y ' + E.NP + ' to ' + E.NP1,
      spot: 'a spot is a world point of the feet (z 0: the pavement; z ' + SEAT_TOP + ': the seat\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere. kind: person (a character stands there), seat (sits on the seat\'s top), door (a person at the guagua\'s door, y ' + 5.3 + ', in front of its lit side ' + side + '), button (a point on the guagua\'s side, no sprite), head (a head at the guagua\'s glass: a sprite detail, the point is the middle of the face), vehicle (the guagua\'s middle), exit (where something leaves the picture). who: the width class of the sprite box (the frog 32, a grown-up 24, a child 24, a dog 28); sprite: the box the make takes the sprite to fill, [x0, y0, x1, y1] from the spot\'s column and row (the spec\'s width and the real drawn pixels)',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), sitting (sent = 1) the same column, its bottom edge on the seat\'s top; abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting KIT.mkAbuelaS (52 x 50): column 17, its bottom edge on the seat\'s top; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy); Canelo KIT.mkPerro (30 x 22): column 13, its bottom edge on sy; a small thing: its bottom middle on the point; a head at the glass: the middle of the face on the point (abuela mkAbuela row 12 of the canvas, column 30; persona row 11, column 24), shown only through a pane of the guagua\'s window',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0, the window\'s left edge. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      guagua: 'a guagua at the stop stands with its middle at (P, ' + LANE + '), heading i (towards -x): its front end is its -x end; the front door is ' + GUAGUA.front.join(' to ') + ' and the back door ' + GUAGUA.back.join(' to ') + ' from the front end, the buttons ' + GUAGUA.buttons.join(' and ') + ' from the front end at z ' + GUAGUA.buttonZ + '. puerta_sube is the door at x P - 1.45, puerta_baja at x P + 1.4; the person about to get on stands at (P - 1.45, 5.95), the one who got off at (P + 1.4, 5.95); the frog at a button at (the button\'s x, 5.85)',
    },
    setKey: {
      params: { hora: { values: ['temprano', 'manana', 'tarde', 'noche'], note: 'the sky, the sun\'s height, the light; noche lights the lamp' },
        autos: { note: 'for the readers\' renders only: guagua@x,y,i,<board> joined by ";" (board: arbol, toldo, casa); in the game the guaguas are sprites' } },
      key: 'hora, e.g. "manana"',
      baked: ['temprano', 'manana', 'tarde', 'noche'].map(h => '?hora=' + h),
    },
    constants: {
      E: { HH: E.HH, FP: E.FP, S0: E.S0, S1: E.S1, NP: E.NP, NP1: E.NP1, LANE1: E.LANE1, LANE2: E.LANE2, P1: E.P1, P2: E.P2, SIGN: E.SIGN, SEAT: E.SEAT, POST: E.POST, LAMP: E.LAMP, PATH: E.PATH, SUN: E.SUN },
      seat: { x: [E.SEAT[0], E.SEAT[2]], y: [E.SEAT[1], r4(E.SEAT[1] + SEAT_DEPTH)], top: SEAT_TOP },
      guagua: { y: LANE, side, length: GUAGUA.length, width: GUAGUA.width, heading: 'i', front_door: GUAGUA.front, back_door: GUAGUA.back, buttons: GUAGUA.buttons, button_z: GUAGUA.buttonZ, door_z: GUAGUA_SRC.doorZ, door_span: { sube: DOOR.sube, baja: DOOR.baja },
        windows: Object.assign({ note: 'from calle-base.js: panes from the front end, the first at "from", each "pane" wide, one every "period", the last ending before length - from; z from z[0] to z[1]' }, GUAGUA_SRC.windows) },
    },
    things,
    spots,
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus ' + BIAS + '), so the seat hides nothing that stands in front of it and a person at the kerb is in front of the guagua (its lit side is y ' + side + ').',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .4 },
      byCharacter: { coqui: .45, abuela: .35, senora: .35, senor: .35, luis: .28, carmen: .28, perro: .4 },
      at: 'castShadow(x, y, z, radius) at the world x, y, z of the spot (z 0 on the pavement, z ' + SEAT_TOP + ' on the seat), for a character that stands, sits or lies',
      none: ['ventana1', 'ventana2', 'chofer'],
      note: 'a head at the guagua\'s glass casts none',
    },
  };
}

/* ---------- the pixel tests that read the set: a placed sprite's pixels hidden by the set's baked depth (the front rule) ---------- */
async function probeSets(page, load, sheet, SIL, autosQ, G) {
  const S = sheet.spots, E = G.E, side = sheet.constants.guagua.side;
  const at = (name, key) => { const s = S[name]; return { name, sil: key, sx: s.screen[0], sy: s.screen[1], d: s.depth, wy: s.world[1] }; };
  const sil = {}; for (const k of ['adulto', 'nino', 'coqui', 'perro_lie', 'perro_sit']) sil[k] = SIL[k].px;
  const out = {};
  // both guaguas at the stop (the tree at P1, the awning at P2)
  await load('tags=1&hora=manana' + autosQ([['arbol', E.P1], ['toldo', E.P2]]));
  const place = [];
  for (const suf of ['', '.2']) for (const n of ['puerta_sube', 'puerta_baja', 'espera_sube', 'espera_baja']) place.push(at(n + suf, 'adulto'));
  for (const suf of ['', '.2']) for (const n of ['coqui.boton_sube', 'coqui.boton_baja']) place.push(Object.assign(at(n + suf, 'coqui'), { keep: true }));
  place.push(Object.assign(at('coqui.botones', 'coqui'), { keep: true }));
  for (const n of ['bordillo.abuela', 'bordillo.luis', 'bordillo.carmen', 'cola1', 'cola2', 'cola3']) place.push(at(n, n.includes('luis') || n.includes('carmen') || n === 'cola3' ? 'nino' : 'adulto'));
  place.push(at('bordillo.coqui', 'coqui'));
  place.push(at('bajo_banco', 'perro_lie'), Object.assign(at('bajo_banco', 'perro_sit'), { name: 'bajo_banco.sit' }));
  out.placed = await page.evaluate(arg => {
    const { place, sil, bias } = arg, Z = DEPTH.z, S_ = DEPTH.S, T30 = Math.tan(Math.PI / 6), res = {};
    for (const pl of place) {
      const px = sil[pl.sil], o = { total: 0, hidden: 0, outside: 0, hidBy: {}, shown: [] };
      for (let k = 0; k < px.length; k += 2) {
        const X = pl.sx + px[k], Y = pl.sy + px[k + 1];
        if (X < 0 || X >= W || Y < 0 || Y >= H) { o.outside++; continue; }
        o.total++;
        const i = Y * W + X, plane = pl.d + (pl.sy - (Y + .5)) * T30 / S_;
        if (Z[i] > plane + bias) { o.hidden++; const t = TAGS[i] || 'ground'; o.hidBy[t] = (o.hidBy[t] || 0) + 1; } else if (pl.keep) o.shown.push(X, Y);
      }
      res[pl.name] = o;
    }
    return res;
  }, { place, sil, bias: sheet.front.bias });
  // the nearest y (steps of .01, up to .8 on) at which a grown-up at a door spot has no pixel hidden by the guagua: for a failure's report only
  const targets = []; for (const suf of ['', '.2']) for (const n of ['puerta_sube', 'puerta_baja']) targets.push({ name: n + suf, sil: 'adulto', w: S[n + suf].world });
  out.scan = await page.evaluate(arg => {
    const { targets, sil, bias } = arg, Z = DEPTH.z, T30 = Math.tan(Math.PI / 6), res = {};
    for (const t of targets) {
      const px = sil[t.sil]; let first = null;
      for (let k = 0; k <= 80 && first === null; k++) {
        const y = Math.round((t.w[1] + k * .01) * 1e4) / 1e4, q = project(t.w[0], y, t.w[2]), sx = Math.round(q.sx), sy = Math.round(q.sy);
        let hid = 0;
        for (let n = 0; n < px.length; n += 2) { const X = sx + px[n], Y = sy + px[n + 1]; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X, plane = q.d + (sy - (Y + .5)) * T30 / S; if (Z[i] > plane + bias && TAGS[i] === 'auto') hid++; }
        if (hid === 0) first = y;
      }
      res[t.name] = first;
    }
    return res;
  }, { targets, sil, bias: sheet.front.bias });
  // what the set drew at the places the spec puts things: the colours at the buttons, the glass at the windows, the tags at the seat, the post and the chofer
  const sample = [];
  for (const suf of ['', '.2']) for (const n of ['boton_sube', 'boton_baja']) sample.push({ name: n + suf, sx: S[n + suf].screen[0], sy: S[n + suf].screen[1], r: 2 });
  for (const n of ['ventana1', 'ventana2', 'chofer']) sample.push({ name: n, sx: S[n].screen[0], sy: S[n].screen[1], r: 0 });
  for (const n of ['banco1', 'banco2', 'banco3']) sample.push({ name: n, sx: S[n].screen[0], sy: S[n].screen[1], r: 1 });
  sample.push({ name: 'poste', sx: S.poste.screen[0], sy: S.poste.screen[1], r: 3 });
  out.sample = await page.evaluate(arg => {
    const res = {}, Z = DEPTH.z;
    for (const s of arg) {
      const o = { pix: [], tags: {} };
      for (let dy = -s.r; dy <= s.r; dy++) for (let dx = -s.r; dx <= s.r; dx++) {
        const X = s.sx + dx, Y = s.sy + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, v = bakedPix[i], t = TAGS[i] || 'ground';
        o.pix.push([v & 255, (v >> 8) & 255, (v >> 16) & 255]); o.tags[t] = (o.tags[t] || 0) + 1; if (dx === 0 && dy === 0) { o.z = Z[i]; o.tag = t; }
      }
      res[s.name] = o;
    }
    return res;
  }, sample);
  return out;
}

/* a place's nearest world point along x or y (steps of .01, up to 3) where ok(screen x, screen y) holds, as text: for a failure's report only; the brief's number is kept */
function scr3(sheet, x, y, z) {
  const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, OX = sheet.picture[0] / 2 + sheet.origin.originX, OY = sheet.picture[1] / 2 + sheet.origin.originY;
  return [Math.round(OX + (x - y) / R2 * sheet.S), Math.round(OY + ((x + y) / R2 * .5 - z * COS) * sheet.S)];
}
function nearestPass(sheet, spot, ok) {
  const w = sheet.spots[spot].world;
  for (let k = 1; k <= 300; k++) {
    const hits = [];
    for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); const [sx, sy] = scr3(sheet, q[0], q[1], q[2]); if (ok(sx, sy, q)) hits.push((ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')'); }
    if (hits.length) return hits.join(' or ');
  }
  return 'none within 3';
}

function checks(sheet, probes, SIL, G, PVD, extents, parts, COV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, E = sheet.constants.E, side = sheet.constants.guagua.side, OUTS = [];
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const x0 = V.region[0], W_ = sheet.picture[0], H_ = sheet.picture[1];
  const boxAt = (s, sx, sy) => { const b = s.sprite || [0, 0, 0, 0]; return [sx + b[0], sy + b[1], sx + b[2], sy + b[3]]; };
  // how much of a box [x0, y0, x1, y1] lies outside a frame [fx, fy, fw, fh]: [left, right, top, bottom] in px
  const cutOf = (b, f) => [Math.max(0, f[0] - b[0]), Math.max(0, b[2] - (f[0] + f[2] - 1)), Math.max(0, f[1] - b[1]), Math.max(0, b[3] - (f[1] + f[3] - 1))];
  const sum = a => a.reduce((x, y) => x + y, 0);
  const cutText = c => [c[0] && c[0] + ' px left', c[1] && c[1] + ' px right', c[2] && c[2] + ' px above', c[3] && c[3] + ' px below'].filter(Boolean).join(', ');
  const COUNTED = Object.entries(S).filter(([, s]) => s.kind !== 'exit');

  // 1. in-view: every spot (its sprite whole) inside the picture and inside the view's window; every thing's box too; the exit leaves
  {
    const bad = [], PICT = [0, 0, W_, H_], WIN = [x0, 0, 196, H_], hints = [];
    for (const [k, s] of COUNTED) {
      const b = boxAt(s, ...s.screen), cp = cutOf(b, PICT), cw = cutOf(b, WIN), pointIn = s.screen[0] >= 0 && s.screen[0] < W_ && s.screen[1] >= 0 && s.screen[1] <= H_;
      if (sum(cp)) bad.push(k + ' ' + s.screen + ' (' + (s.who || s.kind) + ', sprite box columns ' + b[0] + ' to ' + b[2] + ', rows ' + b[1] + ' to ' + b[3] + '): outside the picture by ' + cutText(cp) + (sum(cw) ? '; outside the window [' + x0 + ', ' + (x0 + 196) + ') by ' + cutText(cw) : ''));
      else if (sum(cw)) bad.push(k + ' ' + s.screen + ' (' + (s.who || s.kind) + ', sprite box columns ' + b[0] + ' to ' + b[2] + '): outside the window [' + x0 + ', ' + (x0 + 196) + ') by ' + cutText(cw));
      if (sum(cp) || sum(cw)) hints.push('nearest passing ' + k + ' ' + s.world + ': ' + nearestPass(sheet, k, (sx, sy) => { const bb = boxAt(s, sx, sy); return !sum(cutOf(bb, PICT)) && !sum(cutOf(bb, WIN)); }));
      void pointIn;
    }
    const things = [];
    for (const [k, t] of Object.entries(T)) for (const [n, box] of (t.boxes ? t.boxes.map(q => [k + '.' + q.part, q.box]) : t.box ? [[k, t.box]] : [])) {
      things.push(n + ' [' + box + ']');
      if (box[0] < x0 || box[0] + box[2] > x0 + 196 || box[1] < 0 || box[1] + box[3] > H_) bad.push('thing ' + n + ' box ' + box + ' outside the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    // the exit leaves the picture: its point is outside the picture's bottom edge (the footpath is beyond it)
    const ex = S.camino, exOut = ex.screen[1] - H_ + 1, exInfo = 'camino ' + ex.screen + ' is ' + (ex.screen[0] < 0 || ex.screen[0] >= W_ || ex.screen[1] >= H_ ? 'OUTSIDE' : 'inside') + ' the picture: ' + (ex.screen[1] >= H_ ? exOut + ' rows below its bottom edge (rows 0 to ' + (H_ - 1) + ')' : 'its row ' + ex.screen[1]);
    add('in-view', bad, COUNTED.length + ' spots (every spot but the exit camino) with their sprites whole inside the ' + sheet.picture.join(' x ') + ' picture and the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216) (x0 ' + x0 + '), and ' + things.length + ' thing boxes (' + things.join(', ') + ') inside the window; ' + exInfo,
      [bad.length + ' finding(s) (spots\' sprite boxes: the spec\'s width and the real drawn pixels, rules.spot):'].concat(bad.map(b => '  ' + b), hints.map(h => '    ' + h), ['  ' + exInfo + ' (the spec puts camino where the path leaves the picture: it is by design outside; the frog starting to walk is coqui.arranca)']));
    OUTS[OUTS.length - 1].x0 = x0;
    OUTS[OUTS.length - 1].lines.push('       sprite boxes used, [x0, y0, x1, y1] from the spot (the spec\'s width and the real drawn pixels): ' + ['adulto', 'nino', 'coqui', 'perro', 'head', 'chofer'].map(w => { const t = Object.values(S).find(s => s.who === w && s.sprite); return t ? w + ' [' + t.sprite + ']' : ''; }).filter(Boolean).join(', ') + ', seated adulto [' + S.banco1.sprite + ']; real ink columns of the drawn sprites: ' + ['adulto', 'abuela', 'senor', 'nino', 'carmen', 'coqui', 'perro_lie', 'perro_sit'].map(k => k + ' ' + SIL[k].box[0] + ' to ' + SIL[k].box[2]).join(', '));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the screen box of each set thing\'s pixels (tags=1) against its world box projected [x, y, w, h]: ' + [['sign', T.parada.boxes[0]], ['seat', T.parada.boxes[1]], ['post', T.poste]].map(([n, t]) => n + ' [' + t.box + '] vs [' + t.from_world + ']').join(', '));
    {
      const sun = Object.entries(E.SUN).filter(([, v]) => v).map(([h, v]) => { const lo = v[0] - v[2], hi = v[0] + v[2], inside = lo >= x0 && hi < x0 + 196; return h + ' sun [x ' + v[0] + ', y ' + v[1] + ', r ' + v[2] + '] columns ' + lo + ' to ' + hi + ': ' + (inside ? 'inside' : 'OUTSIDE') + ' the window [' + x0 + ', ' + (x0 + 196) + ') (it needs x0 ' + Math.max(0, hi + 1 - 196) + ' or more)'; });
      const fl = parts.farol, cut = Object.entries(fl.cols).filter(([x]) => +x < x0 || +x >= x0 + 196).reduce((a, [, v]) => a + v, 0);
      OUTS[OUTS.length - 1].lines.push('       info, not a check: the sun (E.SUN: the picture\'s pixels, hora temprano and tarde): ' + sun.join('; ') + '; the street lamp (part farol, lit at noche) pixels columns ' + fl.box[0] + ' to ' + (fl.box[0] + fl.box[2] - 1) + ', rows ' + fl.box[1] + ' to ' + (fl.box[1] + fl.box[3] - 1) + ': ' + cut + ' of its ' + fl.count + ' px outside the window');
    }
    OUTS[OUTS.length - 1].lines.push('       view: x0 ' + x0 + '; the spots\' sprites span columns ' + V.extent[0] + ' to ' + V.extent[1] + ' (' + (V.extent[1] - V.extent[0] + 1) + ' px, those the picture itself holds); every spot but those listed above is inside');
    OUTS[OUTS.length - 1].lines.push('       ' + exInfo);
  }

  // 2. sprites-apart: for every pair that stands together in a moment of the preview (the characters), the two sprite boxes (the frog 32 wide, a grown-up 24, a child 24, a dog 28, the feet's spot in the middle) do not overlap sideways, unless their feet are UPDOWN px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of [1, 2, 3, 4, 5, 6]) {
      const L = PVD[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' px across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down:'].concat(bad));
    for (const h of hints) {
      const pass = other => (sx, sy) => Math.abs(sx - other.sx) >= h.half || Math.abs(sy - other.sy) >= UPDOWN;
      OUTS[OUTS.length - 1].lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].world + ': ' + nearestPass(sheet, h.a.at, pass(h.b)) + '; or ' + h.b.at + ' ' + S[h.b.at].world + ': ' + nearestPass(sheet, h.b.at, pass(h.a)));
    }
    OUTS[OUTS.length - 1].lines.push('       closest in each moment (px across / px down): ' + [1, 2, 3, 4, 5, 6].map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    OUTS[OUTS.length - 1].pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 3. frog-seen: the frog is never behind a grown-up, a car or a guagua: in every moment his whole box is seen: no drawn pixel of his hidden by the set (the guagua, the seat, the sign) and none covered by a nearer sprite pixel
  {
    const bad = [], lines = [], hintLines = [];
    for (const m of [1, 2, 3, 4, 5, 6]) for (const f of PVD[m].layers.filter(l => l.who === 'coqui')) {
      const others = PVD[m].layers.filter(l => l !== f), hid = f.px.filter(p => p[2]).length;
      let cov = 0; const by = {};
      for (const p of f.px) { if (p[2]) continue; for (const o of others) if (o.who || o.at) for (const q of o.px) if (q[0] === p[0] && q[1] === p[1] && !q[2] && q[3] > p[3]) { cov++; by[o.at] = (by[o.at] || 0) + 1; break; } }
      const fb = [f.sx - 16, f.sy - 25, f.sx + 15, f.sy - 1];                                        // his box: 32 wide (the spec), the 25 rows he draws
      let boxCov = 0; for (const o of others) for (const q of o.px) if (!q[2] && q[0] >= fb[0] && q[0] <= fb[2] && q[1] >= fb[1] && q[1] <= fb[3] && q[3] > f.d + (f.sy - (q[1] + .5)) * Math.tan(Math.PI / 6) / G.S) boxCov++;
      lines.push('moment ' + m + ' ' + f.at + ' [' + f.sx + ',' + f.sy + ']: ' + f.px.length + ' px drawn, ' + hid + ' hidden by the set, ' + cov + ' covered by a nearer sprite' + (cov ? ' (' + Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ') + ')' : '') + '; ' + boxCov + ' px of other sprites lie over his 32 x 25 box');
      if (hid || cov) {
        bad.push('moment ' + m + ' ' + f.at + ': ' + hid + ' px hidden by the set, ' + cov + ' px covered by ' + Object.keys(by).join(', '));
        // the nearest place of the frog (along x or y, steps of .01, up to 3) with none of his pixels under a nearer pixel of another sprite of the moment (the others stay where they are; the set is not re-tested)
        const top = new Map(); for (const o of others) for (const q of o.px) if (!q[2]) { const key = q[1] * 240 + q[0]; if (!top.has(key) || top.get(key) < q[3]) top.set(key, q[3]); }
        const px = SIL.coqui.px, R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, T30 = Math.tan(Math.PI / 6), w = f.world, hits = [];
        const clear = q => { const [sx, sy] = scr3(sheet, q[0], q[1], q[2]), d = (q[0] + q[1]) / R2 * COS + q[2] * .5; for (let n = 0; n < px.length; n += 2) { const X = sx + px[n], Y = sy + px[n + 1]; if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue; const pl = top.get(Y * 240 + X); if (pl !== undefined && pl > d + (sy - (Y + .5)) * T30 / G.S) return false; } return true; };
        for (let k = 1; k <= 300 && !hits.length; k++) for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); if (clear(q)) hits.push((ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')'); }
        hintLines.push('nearest passing, moment ' + m + ' ' + f.at + ' ' + S[f.at].world + ' (the other sprites where they are): ' + (hits.join(' or ') || 'none within 3'));
      }
    }
    add('frog-seen', bad, 'in all ' + lines.length + ' moments the frog is whole: no pixel hidden by the set, none covered by a nearer sprite: ' + lines.join('; '), ['the frog not whole:'].concat(bad.map(b => '  ' + b), hintLines.map(h => '    ' + h)));
    if (bad.length) OUTS[OUTS.length - 1].lines.push(...lines.map(l => '       ' + l));
  }

  // 4. door-front: a person at a door stands in front of it, not inside the wall: his spot's y is beyond the guagua's lit side, and no pixel of him is hidden by the guagua (both guaguas, the tree at P1 and the awning at P2).
  //    Pixels hidden by another part of the set (the stop's sign) are not the wall: listed as info
  {
    const bad = [], lines = [], other = [], hints = [];
    for (const suf of ['', '.2']) for (const n of ['puerta_sube', 'puerta_baja', 'espera_sube', 'espera_baja', 'coqui.boton_sube', 'coqui.boton_baja']) {
      const k = n + suf, s = S[k], o = probes.placed[k], auto = o.hidBy.auto || 0, rest = Object.entries(o.hidBy).filter(([t]) => t !== 'auto');
      lines.push(k + ' ' + s.screen + ' y ' + s.world[1] + ': ' + auto + ' of ' + o.total + ' px hidden by the guagua');
      if (rest.length) other.push(k + ': ' + rest.reduce((a, r) => a + r[1], 0) + ' of ' + o.total + ' px hidden by ' + rest.map(([t, v]) => t + ' ' + v).join(', '));
      if (!(s.world[1] > side)) bad.push(k + ' y ' + s.world[1] + ' is not in front of the lit side y ' + side);
      if (auto) { bad.push(k + ' ' + s.screen + ' y ' + s.world[1] + ': ' + auto + ' of ' + o.total + ' px (' + r2(100 * auto / o.total) + '%) hidden by the guagua: the right side of his sprite lies inside the wall'); if (probes.scan[k] != null) hints.push('nearest passing ' + k + ' ' + s.world + ': y ' + s.world[1] + ' -> ' + probes.scan[k] + ' (+' + r2(probes.scan[k] - s.world[1]) + ')'); }
    }
    add('door-front', bad, 'at both guaguas a person at puerta_sube, puerta_baja (y 5.3), espera_sube, espera_baja (y 5.95) and the frog at the two buttons (y 5.85) is in front of the guagua\'s lit side (y ' + side + ') and shows whole (0 px hidden by the guagua): ' + lines.join('; '),
      ['a person at a door is partly inside the guagua\'s wall (a grown-up\'s sprite, 24 wide: the columns more than about 9 px right of his feet lie behind the lit side when his feet are .05 in front of it):'].concat(bad.map(b => '  ' + b), hints.map(h => '    ' + h)));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the pixels these places lose to another part of the set (the stop\'s sign): ' + (other.join('; ') || 'none'));
  }

  // 5. seat-top: a person on the seat sits on its top: the spot's z is the seat's top, its x, y are on the top, and the set draws the seat's top there; Canelo lies in front of the seat
  {
    const bad = [], lines = [], SE = sheet.constants.seat;
    for (const n of ['banco1', 'banco2', 'banco3']) {
      const s = S[n], w = s.world, smp = probes.sample[n];
      const onTop = w[2] === SE.top && w[0] >= SE.x[0] && w[0] <= SE.x[1] && w[1] >= SE.y[0] && w[1] <= SE.y[1], seatPx = smp.tags.asiento || 0, dz = Math.abs(smp.z - s.depth);
      lines.push(n + ' ' + w + ': on the seat\'s top ' + (onTop ? 'yes' : 'NO') + ', ' + seatPx + ' of the 3 x 3 pixels at its point are the seat\'s (part asiento), the set\'s depth there is ' + r2(dz) + ' from the spot\'s');
      if (!onTop) bad.push(n + ' ' + w + ' is not on the seat\'s top (x ' + SE.x + ', y ' + SE.y + ', z ' + SE.top + ')');
      if (!seatPx) bad.push(n + ': the set draws no seat pixel at its point');
      else if (dz > .15) bad.push(n + ': the set\'s depth at its point differs from the spot\'s by ' + r2(dz) + ' (a top at z ' + SE.top + ' agrees)');
    }
    const c = S.bajo_banco.world, frontOf = c[1] > SE.y[1];
    lines.push('bajo_banco ' + c + ': ' + (frontOf ? 'in front of the seat (y > ' + SE.y[1] + ')' : 'NOT in front of the seat'));
    if (!frontOf) bad.push('bajo_banco y ' + c[1] + ' is not in front of the seat (its front edge y ' + SE.y[1] + ')');
    add('seat-top', bad, 'banco1 to banco3 are on the seat\'s top (z ' + SE.top + ', x ' + SE.x + ', y ' + SE.y + '), drawn by the set there; Canelo in front of it: ' + lines.join('; '), ['the seat:'].concat(bad.map(b => '  ' + b)));
  }

  // 6. nobody-on-street: every spot where somebody stands (z 0) is on the near pavement (y E.NP to E.NP1), unless the spec puts it elsewhere (the door spots, y 5.3, in front of the guagua; the exit camino on the path)
  {
    const bad = [], exc = [];
    for (const [k, s] of Object.entries(S)) {
      if (!['person', 'door', 'seat', 'exit'].includes(s.kind) || s.world[2] !== 0 && s.kind !== 'seat') continue;
      if (s.on_street) { exc.push(k + ' y ' + s.world[1]); continue; }
      if (!(s.world[1] >= E.NP && s.world[1] <= E.NP1)) bad.push(k + ' y ' + s.world[1] + ' is not on the near pavement (y ' + E.NP + ' to ' + E.NP1 + ')');
    }
    const n = Object.values(S).filter(s => ['person', 'seat'].includes(s.kind)).length;
    add('nobody-on-street', bad, n + ' places where somebody stands or sits are on the near pavement (y ' + E.NP + ' to ' + E.NP1 + '); the street is y ' + E.S0 + ' to ' + E.S1 + '; the spec puts ' + exc.length + ' spots elsewhere: ' + exc.join(', '), ['somebody on the street or beyond the pavement:'].concat(bad.map(b => '  ' + b)));
  }

  // 7. spots-on-set: what the set draws at the places the spec gives: the buttons are round and coloured, the windows are glass, the chofer's place is on the guagua, the seat and the post exist
  {
    const bad = [], lines = [], smp = probes.sample;
    const green = c => c[1] > c[0] + 30 && c[1] > c[2] + 20, orange = c => c[0] > c[1] + 40 && c[1] > c[2] + 30, dark = c => Math.max(...c) < 150;
    for (const suf of ['', '.2']) {
      const a = smp['boton_sube' + suf], b = smp['boton_baja' + suf], g = a.pix.filter(green).length, o = b.pix.filter(orange).length;
      lines.push('boton_sube' + suf + ' ' + g + ' green px of 25, boton_baja' + suf + ' ' + o + ' orange px of 25');
      if (!g) bad.push('boton_sube' + suf + ' ' + S['boton_sube' + suf].screen + ': no green pixel within 2 px of its point (the front button is green)');
      if (!o) bad.push('boton_baja' + suf + ' ' + S['boton_baja' + suf].screen + ': no orange pixel within 2 px of its point (the back button is orange)');
    }
    for (const n of ['ventana1', 'ventana2']) { const p = smp[n].pix[0], t = smp[n].tag; lines.push(n + ' pixel ' + p.join(',') + ' (' + t + ')'); if (t !== 'auto') bad.push(n + ' ' + S[n].screen + ': the set draws part ' + t + ' at its point (colour ' + p + '), not the guagua\'s glass: the window is behind it'); else if (!dark(p)) bad.push(n + ' ' + S[n].screen + ': the pixel at its point (' + p + ') is not dark glass'); }
    const cz = smp.chofer; lines.push('chofer pixel tag ' + cz.tag); if (cz.tag !== 'auto') bad.push('chofer ' + S.chofer.screen + ': the pixel at its point is ' + cz.tag + ', not the guagua (auto)');
    const pz = smp.poste; lines.push('poste ' + (pz.tags.poste || 0) + ' px of the post within 3 px'); if (!pz.tags.poste) bad.push('poste ' + S.poste.screen + ': no post pixel within 3 px of the spot');
    // the windows' panes (calle-base.js): ventana1 and ventana2 are in a pane's middle in x
    const WN = sheet.constants.guagua.windows, L = sheet.constants.guagua.length, paneOf = x => { const dn = x - (E.P1 - L / 2), k = Math.floor((dn - WN.from) / WN.period); return { dn: r2(dn), k, in: dn > WN.from && dn < L - WN.from && ((dn - WN.from) % WN.period) < WN.pane, mid: r2(WN.from + k * WN.period + WN.pane / 2) }; };
    for (const n of ['ventana1', 'ventana2']) { const p = paneOf(S[n].world[0]); lines.push(n + ' x ' + S[n].world[0] + ' from the front end ' + p.dn + ': ' + (p.in ? 'in pane ' + (p.k + 1) + ' (its middle ' + p.mid + ')' : 'NOT in a pane')); if (!p.in) bad.push(n + ' x ' + S[n].world[0] + ' (' + p.dn + ' from the front end) is not in a pane of the guagua\'s windows'); if (!(S[n].world[2] > WN.z[0] && S[n].world[2] < WN.z[1])) bad.push(n + ' z ' + S[n].world[2] + ' is not in the glass (z ' + WN.z + ')'); }
    const dn = S.chofer.world[0] - (E.P1 - L / 2); lines.push('chofer ' + r2(dn) + ' from the front end'); if (!(dn >= 0 && dn < sheet.constants.guagua.front_door[0])) bad.push('chofer x is ' + r2(dn) + ' from the front end: not in front of the front door (' + sheet.constants.guagua.front_door[0] + ')');
    add('spots-on-set', bad, 'the set draws what the spec puts at its places: ' + lines.join('; '), ['the set does not draw it there:'].concat(bad.map(b => '  ' + b)));
  }

  // 8. guaguas-whole: both guaguas whole in the window (the pixels the set draws for each, any of the three boards)
  {
    const bad = [], lines = [], hints = [];
    for (const [k, e] of Object.entries(extents)) {
      const left = e.pix.filter(p => p[0] < x0), right = e.pix.filter(p => p[0] >= x0 + 196), cl = Math.max(0, x0 - e.box[0]), cr = Math.max(0, e.box[2] - (x0 + 195));
      lines.push(k + ' (P ' + e.P + ') pixels columns ' + e.box[0] + ' to ' + e.box[2] + ', rows ' + e.box[1] + ' to ' + e.box[3] + ': ' + (left.length + right.length) + ' of its ' + e.count + ' px outside the window [' + x0 + ', ' + (x0 + 196) + '): ' + cl + ' column(s) at the left (' + left.length + ' px), ' + cr + ' at the right (' + right.length + ' px)');
      if (left.length + right.length) bad.push(k + ': ' + (left.length + right.length) + ' px cut (' + cl + ' columns left, ' + cr + ' columns right)');
    }
    // the window that cuts least of both together
    let bx = 0, bc = 1e9; for (let x = 0; x <= sheet.picture[0] - 196; x++) { const c = Object.values(extents).reduce((a, e) => a + e.pix.filter(p => p[0] < x || p[0] >= x + 196).length, 0); if (c < bc) { bc = c; bx = x; } }
    const span = Math.max(...Object.values(extents).map(e => e.box[2])) - Math.min(...Object.values(extents).map(e => e.box[0])) + 1;
    hints.push('the two guaguas together span columns ' + Math.min(...Object.values(extents).map(e => e.box[0])) + ' to ' + Math.max(...Object.values(extents).map(e => e.box[2])) + ' = ' + span + ' px, more than the 196-wide window: the least cut of both is ' + bc + ' px, at x0 ' + bx + (bx === x0 ? '' : ' (' + Object.entries(extents).map(([k, e]) => k + ' ' + e.pix.filter(p => p[0] < bx || p[0] >= bx + 196).length).join(', ') + '), where the spots\' sprites at the left are cut: ' + COUNTED.filter(([, s]) => boxAt(s, ...s.screen)[0] < bx).map(([k]) => k).join(', ')));
    add('guaguas-whole', bad, 'both guaguas (the pixels the set draws for each) are whole inside the window [' + x0 + ', ' + (x0 + 196) + '): ' + lines.join('; '), [bad.length + ' guagua(s) cut by the window [' + x0 + ', ' + (x0 + 196) + '):'].concat(lines.map(l => '  ' + l), hints.map(h => '  ' + h)));
  }

  // 9. kerb-front: every person at the kerb is in front of the guagua: in every moment with a guagua (1 to 4), no pixel of a character that stands on the pavement is hidden by the set
  {
    const bad = [], lines = [];
    for (const m of [1, 2, 3, 4]) {
      const L = PVD[m].layers.filter(l => l.who && l.world[1] > side), parts_ = [];
      for (const l of L) {
        const hid = l.px.filter(p => p[2]).length, by = Object.entries(COV[m][PVD[m].layers.indexOf(l)].hidden).map(([t, v]) => (t === 'parada' ? 'the sign' : t === 'asiento' ? 'the seat' : t === 'auto' ? 'the guagua' : t) + ' ' + v).join(', ');
        parts_.push(l.at + ' ' + hid + '/' + l.px.length + (hid ? ' (' + by + ')' : ''));
        if (hid) bad.push('moment ' + m + ' ' + l.at + ': ' + hid + ' of ' + l.px.length + ' px hidden by ' + by);
      }
      lines.push('m' + m + ': ' + parts_.join(', '));
    }
    add('kerb-front', bad, 'in moments 1 to 4 (a guagua at the stop) every character that stands or sits in front of the guagua\'s lit side (y > ' + side + ') shows whole, hidden px / drawn px: ' + lines.join('; '), ['hidden by the set:'].concat(bad.map(b => '  ' + b), lines.map(l => '  ' + l)));
    // info, all six moments: what each character draws over (shown pixels over the sign, the post, the guagua, the seat) and what hides him
    const inf = [], hide = [];
    for (const m of [1, 2, 3, 4, 5, 6]) PVD[m].layers.forEach((l, i) => {
      if (!l.who) return;
      const c = COV[m][i], over = ['parada', 'poste'].filter(t => c.shown[t]).map(t => (t === 'parada' ? 'the sign' : 'the post') + ' ' + c.shown[t]), hid = l.px.filter(p => p[2]).length;
      if (over.length) inf.push('m' + m + ' ' + l.at + ' is drawn over ' + over.join(', ') + ' px');
      if (hid) hide.push('m' + m + ' ' + l.at + ' ' + hid + '/' + l.px.length + ' px hidden by ' + Object.entries(c.hidden).map(([t, v]) => (t === 'parada' ? 'the sign' : t === 'asiento' ? 'the seat' : t === 'auto' ? 'the guagua' : t) + ' ' + v).join(', '));
    });
    OUTS[OUTS.length - 1].lines.push('       info, not a check: characters drawn over the stop\'s sign or the walking post (their pixels shown over the sign\'s or the post\'s): ' + (inf.join('; ') || 'none'));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: characters with pixels hidden by the set, in all six moments: ' + (hide.join('; ') || 'none'));
    const nr = [];
    for (const m of [1, 2, 3, 4, 5, 6]) PVD[m].layers.forEach((l, i) => { if (!l.who) return; const c = COV[m][i], t = Object.entries(c.nearer).filter(([k]) => ['parada', 'poste', 'auto', 'asiento'].includes(k)); if (t.length) nr.push('m' + m + ' ' + l.at + ' over ' + t.map(([k, v]) => (k === 'parada' ? 'the sign' : k === 'asiento' ? 'the seat' : k === 'auto' ? 'the guagua' : 'the post') + ' ' + v).join(', ')); });
    OUTS[OUTS.length - 1].lines.push('       info, not a check: shown pixels that lie over a set pixel nearer than the sprite\'s own plane (the bias ' + BIAS + ' lets them through): ' + (nr.join('; ') || 'none'));
  }

  // 10. frog-button-door: the frog at a button does not cover the other door (the door with its arrow and button, the face's x and z read back from the screen pixel)
  {
    const bad = [], lines = [], OX = G.OX, OY = G.OY, Sc = G.S, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
    const face = (X, Y) => { const x = side + (X + .5 - OX) / Sc * R2; return [x, ((x + side) / R2 * .5 - (Y + .5 - OY) / Sc) / COS]; };
    const GG = sheet.constants.guagua, doorX = (P, w) => { const L = P - GG.length / 2; return [L + GG.door_span[w][0], L + GG.door_span[w][1]]; };
    const cases = [['', E.P1], ['.2', E.P2]];
    for (const [suf, P] of cases) for (const [spot, own, other] of [['coqui.boton_sube', 'sube', 'baja'], ['coqui.boton_baja', 'baja', 'sube']]) {
      const k = spot + suf, o = probes.placed[k], dr = doorX(P, other), dz = GG.door_z;
      let n = 0, nOwn = 0; const ow = doorX(P, own);
      for (let i = 0; i < o.shown.length; i += 2) { const [fx, fz] = face(o.shown[i], o.shown[i + 1]); if (fx >= dr[0] && fx <= dr[1] && fz >= dz[0] && fz <= dz[1]) n++; if (fx >= ow[0] && fx <= ow[1] && fz >= dz[0] && fz <= dz[1]) nOwn++; }
      lines.push(k + ' ' + S[k].screen + ': covers ' + n + ' px of the ' + other + ' door (x ' + r2(dr[0]) + ' to ' + r2(dr[1]) + '), ' + nOwn + ' px of its own');
      if (n) bad.push(k + ' covers ' + n + ' px of the ' + other + ' door');
    }
    const mid = probes.placed['coqui.botones'], cv = {}; for (const w of ['sube', 'baja']) { const dr = doorX(E.P1, w); let n = 0; for (let i = 0; i < mid.shown.length; i += 2) { const [fx, fz] = face(mid.shown[i], mid.shown[i + 1]); if (fx >= dr[0] && fx <= dr[1] && fz >= GG.door_z[0] && fz <= GG.door_z[1]) n++; } cv[w] = n; }
    lines.push('info: the frog between the buttons, coqui.botones ' + S['coqui.botones'].screen + ', covers ' + cv.sube + ' px of the front door and ' + cv.baja + ' of the back door');
    add('frog-button-door', bad, 'the frog at each button (coqui.boton_sube, coqui.boton_baja, at both guaguas) covers 0 px of the other door: ' + lines.join('; '), ['the frog covers the other door:'].concat(bad.map(b => '  ' + b), lines.map(l => '  ' + l)));
  }

  // 11. canelo-shown: Canelo is not hidden by the seat: 60% or more of him shows (lying and sitting, at bajo_banco; and in moments 3 and 4 with the other sprites)
  {
    const bad = [], lines = [];
    for (const [k, label] of [['bajo_banco', 'lying'], ['bajo_banco.sit', 'sitting']]) {
      const o = probes.placed[k], shown = o.total - o.hidden, pc = 100 * shown / o.total;
      lines.push(label + ': ' + shown + ' of ' + o.total + ' px show (' + r2(pc) + '%)' + (o.hidden ? ', hidden by ' + Object.entries(o.hidBy).map(([t, v]) => t + ' ' + v).join(', ') : ''));
      if (pc < CANELO_MIN * 100) bad.push(label + ': ' + r2(pc) + '% shows (needs ' + CANELO_MIN * 100 + '%)');
    }
    for (const m of [3, 4]) { const l = PVD[m].layers.find(q => q.who === 'perro'), shown = l.px.filter(p => !p[2]).length; lines.push('moment ' + m + ' (lying, with the people of the moment): ' + shown + ' of ' + l.px.length + ' px shown by the set'); if (shown < CANELO_MIN * l.px.length) bad.push('moment ' + m + ': ' + shown + ' of ' + l.px.length + ' px show'); }
    add('canelo-shown', bad, 'Canelo at bajo_banco ' + S.bajo_banco.screen + ' shows 60% or more: ' + lines.join('; '), ['Canelo hidden:'].concat(bad.map(b => '  ' + b)));
  }
  return OUTS;
}
