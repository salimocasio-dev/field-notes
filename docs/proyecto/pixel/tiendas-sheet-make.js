#!/usr/bin/env node
'use strict';
/* Las tiendas' sheet: writes docs/proyecto/pixel/tiendas-sheet.json from tiendas-set.html (window.TIENDAS.E, the constants of the row) and the design (the orchestrator's p5-spec,
   section "tiendas"), then checks it. Run from the repo root:  node docs/proyecto/pixel/tiendas-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set has two states with their own origin: fila = tiendas (the row of four shops: the top level of the sheet) and
   fila = altos (story 55's two buildings: the sheet's `altos` part, as El mostrador's sheet keeps its `calle`). It loads each in headless Chrome, projects every world point with the
   engine's own project() (pp-engine.js), reads the pixels the set drew for the horse and the post box (tags=1), and writes the spots, things, views, shadows and the depth rule.
   The sprites (today's makers, historia/engine.js and escenas/kit.js, and the stand-ins of tiendas-preview.html) are read through the PREVIEW page: its boxes (PREVIEW.boxes), its moments
   (PREVIEW.inspect) and sprites placed alone on a spot (PREVIEW.probe). The sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it prints one line per check and exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with TIENDAS_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'tiendas-sheet.json');
const BASE = process.env.TIENDAS_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/tiendas-set.html';
const PREVIEW = BASE + '/docs/proyecto/pixel/tiendas-preview.html';
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
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, T30 = Math.tan(Math.PI / 6);

const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite (El mostrador's ninos-puerta-heads)
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const UPDOWN = 12;                                       // two sprite boxes that overlap sideways need their feet this many px apart up-down (El mostrador's sprites-apart)
const SEAT_TOP = .46;                                    // the seat's top (the spec); the check seat-top reads the set's pixels there
const HORSE_Z = .72;                                     // the rider's place on the horse (the spec)
const STROLLER_LOW = 10;                                 // pass 2: the stroller may cover the lower 10 rows of a door (a door's lower 10 rows are z up to 10 / (COS * S))
const HORSE_NECK = 30;                                   // pass 2: on the horse the horse's own neck may hide up to 30 px of the frog
const POOL = 40;                                         // pass 2: a child or the stroller may cover up to 40 px of the frog (together), elsewhere
const SIGN = { in: .22, z0: .18, top: .06, bancoUp: .25 };   // the set's own numbers (tiendas-set.html): a sign is .22 in from each side of its front, from DH + .18 to h - .06; the banco's front is .25 higher. Checked against the set's pixels below
const DOOR_FRAME = .12;                                  // calle-base.js doorX: the frame is .12 wider on each side and .12 higher than the door
const HORSE_BOX = [-.52, -.22, 0, .44, .22, 1.08];       // the horse's volume round E.HORSE (tiendas-set.html caballito: its coin box on the left to the mane's top): x, y, z from, to
const TQ = 'fila=tiendas&tags=1', AQ = 'fila=altos&par=a&lado=izq&tags=1';
const TSET = { fila: 'tiendas', hora: 'manana', nube: 0 }, ASET = { fila: 'altos', par: 'a', lado: 'izq', hora: 'manana', nube: 0 };

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const errs = [];
  const page = await browser.newPage();
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  let cur = null;
  const load = async q => { if (cur !== q) { await page.goto(PAGE + '?' + q); cur = q; } };
  // the engine's own projection: [sx, sy, d] for each world point, in the state q of the set
  const proj = async (q, pts) => { await load(q); return page.evaluate(pts => pts.map(p => { const g = project(p[0], p[1], p[2]); return [g.sx, g.sy, g.d]; }), pts); };

  const KB = await spriteBoxes(browser, errs);
  const T = await readSet(page, load, TQ);
  const A = await readSet(page, load, AQ);
  const sheet = await make(T, A, KB, proj, page, load);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');                 // first without the checks: the preview reads the sheet
  const PVD = await previewData(browser, errs, sheet);
  const results = await checks(sheet, T, A, KB, PVD, proj, page, load);
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

/* ---------- the sprites: the boxes the preview's makers draw (PREVIEW.boxes: columns left..right, rows top..bottom - 1 from the spot) ---------- */
async function spriteBoxes(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREVIEW + '?nodraw=1');
  const r = await p.evaluate(() => window.PREVIEW.boxes());
  await p.close();
  return r;
}

/* ---------- the preview's moments and the sprites placed alone on every spot ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREVIEW + '?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const out = { moments: {}, alone: {} };
  for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) out.moments[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m);
  out.alone.tiendas = await p.evaluate(arg => window.PREVIEW.probe(arg.st, arg.items), { st: TSET, items: Object.entries(sheet.spots).filter(([, s]) => s.sprite).map(([at, s]) => ({ at, k: s.sprite })) });
  out.alone.altos = await p.evaluate(arg => window.PREVIEW.probe(arg.st, arg.items), { st: ASET, items: Object.entries(sheet.altos.spots).filter(([, s]) => s.sprite).map(([at, s]) => ({ at, k: s.sprite })) });
  await p.close();
  return out;
}

/* ---------- what a state of the set holds: the row's constants, the pixels of the horse and the post box, the picture ---------- */
async function readSet(page, load, q) {
  await load(q);
  return page.evaluate(() => {
    const E = {}; for (const [k, v] of Object.entries(TIENDAS.E)) if (typeof v !== 'function') E[k] = v;
    const fronts = TIENDAS.E.FRONTS.map(k => ({ k, x0: TIENDAS.E.frontX(k), d0: TIENDAS.E.doorX(k) }));
    const parts = {};
    for (let i = 0; i < TAGS.length; i++) { const t = TAGS[i]; if (!t) continue; const x = i % W, y = (i / W) | 0, b = parts[t] || (parts[t] = [1e9, 1e9, -1, -1, 0]); if (x < b[0]) b[0] = x; if (y < b[1]) b[1] = y; if (x > b[2]) b[2] = x; if (y > b[3]) b[3] = y; b[4]++; }
    return { E, fronts, SET: TIENDAS.SET, scene: PP_SCENE, W, H, S, OX, OY, parts };
  });
}

// the screen point of a world point on a picture with this origin (the same arithmetic as pp-engine.js project, rounded to a pixel)
const scrOf = (G, x, y, z) => [Math.round(G.OX + (x - y) / R2 * G.S), Math.round(G.OY + ((x + y) / R2 * .5 - z * COS) * G.S)];
// the world point of a picture pixel's centre on the vertical plane y = at: [x, z]
const onPlaneY = (G, X, Y, at) => { const x = at + (X + .5 - G.OX) / G.S * R2; return [x, ((x + at) / R2 * .5 - (Y + .5 - G.OY) / G.S) / COS]; };

/* ---------- the geometry of a front, as the set draws it ---------- */
function frontsOf(G) {
  const E = G.E;
  return G.fronts.map(f => {
    const x0 = f.x0, x1 = x0 + E.FW, h = E.H + (f.k === 'banco' ? SIGN.bancoUp : 0), d0 = f.d0, d1 = d0 + E.DW;
    return { k: f.k, x0, x1, h, d0, d1, dm: (d0 + d1) / 2, sign: { x0: x0 + SIGN.in, x1: x1 - SIGN.in, z0: E.DH + SIGN.z0, z1: h - SIGN.top, y: .03 }, frame: { x0: d0 - DOOR_FRAME, x1: d1 + DOOR_FRAME, z1: E.DH + DOOR_FRAME } };
  });
}
function altosOf(G) {
  const E = G.E;
  return { w: E.ALTO.w, doors: E.AX.map(x0 => ({ x0, d0: x0 + E.ALTO.w / 2 - .55, d1: x0 + E.ALTO.w / 2 - .55 + 1.1, dm: x0 + E.ALTO.w / 2 })) };
}

/* ---------- the sheet ---------- */
async function make(T, A, KB, proj, page, load) {
  const E = T.E, EA = A.E, FR = frontsOf(T), AL = altosOf(A);
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const front = k => FR.find(f => f.k === k);

  /* ---- the sign's numbers are the set's: the board's frame colour (rgb 120, 76, 44) starts within a pixel of each edge of the computed rectangle, and not outside it ---- */
  await load(TQ);
  for (const f of FR) {
    const off = await page.evaluate(arg => {
      const frame = rgb(120, 76, 44), s = arg.s, P = (a, z) => project(a, s.y, z), at = (X, Y) => bakedPix[Math.round(Y) * W + Math.round(X)];
      const mx = (s.x0 + s.x1) / 2, mz = (s.z0 + s.z1) / 2, l = P(s.x0, mz), r = P(s.x1, mz), t = P(mx, s.z1), b = P(mx, s.z0);
      const scanX = (sx, sy, dir) => { for (let k = -4; k <= 6; k++) { const X = sx + dir * k; if (at(X, sy) === frame) return X - sx; } return null; };     // dir 1: from outside to inside
      const scanY = (sx, sy, dir) => { for (let k = -4; k <= 6; k++) { const Y = sy + dir * k; if (at(sx, Y) === frame) return Y - sy; } return null; };
      return { left: scanX(l.sx - 0, l.sy, 1), right: scanX(r.sx, r.sy, -1), top: scanY(t.sx, t.sy, 1), bottom: scanY(b.sx, b.sy, -1) };
    }, { s: f.sign });
    for (const [side, v] of Object.entries(off)) if (v === null || Math.abs(v) > 1) throw new Error('the sign of the ' + f.k + ' is not where the make computes it: its ' + side + ' edge is ' + v + ' px off (' + JSON.stringify(off) + ')');
  }

  /* ---- spots (fila = tiendas): the pavement (or the seat, or the horse) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // {name, w, kind, what, sprite}
  const add = (name, w, kind, what, sprite) => D.push({ name, w, kind, what, sprite });
  for (const f of FR) add('puerta_' + f.k, [f.dm, .4, 0], 'door', 'at the door of the ' + f.k + ' (the door\'s middle, .4 in front of the wall): where somebody goes in', 'abuela');
  for (const f of FR) {
    add('abuela.puerta_' + f.k, [f.dm, .8, 0], 'person', 'abuela at the ' + f.k + '\'s door: the group that goes to a door (abuela at the door\'s middle D, .8; the stroller in front of her; the frog)', 'abuela');
    add('cochecito.puerta_' + f.k, [r4(f.dm + .2), 2.0, 0], 'stroller', 'the stroller with the bebé at the ' + f.k + '\'s door, in front of abuela: D + .2, y 2.0', 'cochecito');
    add('coqui.puerta_' + f.k, [r4(f.dm + 1.7), 1.9, 0], 'frog', 'the frog at the ' + f.k + '\'s door: D + 1.7, y 1.9', 'coqui');
  }
  add('abuela.acera', [-2.0, 1.5, 0], 'person', 'story 54, the start: abuela on the near pavement', 'abuela');
  add('cochecito', [-.4, 1.6, 0], 'stroller', 'story 54, the start: the stroller with the bebé', 'cochecito');
  add('coqui.acera', [-2.8, 2.4, 0], 'frog', 'story 54, the start: the frog on the near pavement', 'coqui');
  add('caballito', [E.HORSE[0], E.HORSE[1], HORSE_Z], 'frog', 'the rider\'s place on the horse (E.HORSE x, y; z ' + HORSE_Z + ', the top of its body): the frog rides here', 'coqui');
  add('abuela.caballito', [-2.4, 1.3, 0], 'person', 'the group at the horse: abuela', 'abuela');
  add('cochecito.caballito', [-2.6, 2.4, 0], 'stroller', 'the group at the horse: the stroller with the bebé', 'cochecito');
  add('banco_acera', [1.5, 2.2, SEAT_TOP], 'seat', 'story 56: abuela sitting on the seat, on its top (z ' + SEAT_TOP + '); the sitting sprite is anchored by her lap (rules.anchor)', 'abuelaS');
  add('pan', [2.4, 2.2, SEAT_TOP], 'small', 'story 56: abuela\'s bread beside her on the seat (z ' + SEAT_TOP + ')', 'pan');
  add('senora.tienda', [front('tienda').dm, .8, 0], 'person', 'story 56: the señora who has just come out of the tienda with her kite (the tienda door\'s middle, y .8)', 'senora');
  add('coqui.56', [-1.6, 2.2, 0], 'frog', 'story 56: the frog on the pavement (also in the ending, nube 2)', 'coqui');
  add('senora.pasa', [-.6, 1.3, 0], 'person', 'story 56, the game: where the señora stops on her way past', 'senora');
  add('abuela.lluvia', [-.6, 1.2, 0], 'person', 'story 56, the ending (nube 2): abuela standing, with the umbrella', 'abuela');
  const pr = await proj(TQ, D.map(d => d.w));
  const spots = {};
  D.forEach((d, i) => { const q = pr[i]; spots[d.name] = { world: W4(d.w), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d.kind, sprite: d.sprite, what: d.what }; });

  /* ---- spots (fila = altos) ---- */
  const DA = [];
  const addA = (name, w, kind, what, sprite) => DA.push({ name, w, kind, what, sprite });
  addA('puerta_izq', [r4(AL.doors[0].dm), .5, 0], 'door', 'in the doorway of the left building (the door\'s middle D, .5 in front of the wall): mamá or papá stands here when this is the building they work in', 'mama');
  addA('puerta_der', [r4(AL.doors[1].dm), .5, 0], 'door', 'in the doorway of the right building (the door\'s middle D, .5 in front of the wall): mamá or papá stands here when this is the building they work in', 'mama');
  addA('luis.puerta_izq', [r4(AL.doors[0].dm - 1.7), 1.3, 0], 'person', 'Luis in front of the left building\'s door (D - 1.7, y 1.3)', 'luis');
  addA('coqui.puerta_izq', [r4(AL.doors[0].dm + .4), 2.1, 0], 'frog', 'the frog in front of the left building\'s door (D + .4, y 2.1)', 'coqui');
  addA('luis.puerta_der', [r4(AL.doors[1].dm - 1.7), 1.3, 0], 'person', 'Luis in front of the right building\'s door (D - 1.7, y 1.3)', 'luis');
  addA('coqui.puerta_der', [r4(AL.doors[1].dm + .4), 2.1, 0], 'frog', 'the frog in front of the right building\'s door (D + .4, y 2.1)', 'coqui');
  addA('bici', [-.9, 2.2, 0], 'person', 'Luis standing with his bicycle (the bicycle is drawn here too)', 'luis');
  addA('coqui.bici', [.8, 2.3, 0], 'frog', 'the frog standing beside the bicycle', 'coqui');
  addA('senor.pasa', [2.4, 1.3, 0], 'person', 'the señor passing', 'senor');
  addA('bordillo1', [-1.0, 2.62, 0], 'person', 'Luis sitting on the kerb', 'luisS');
  addA('bordillo2', [.7, 2.62, 0], 'frog', 'the frog sitting on the kerb', 'coqui');
  const prA = await proj(AQ, DA.map(d => d.w));
  const spotsA = {};
  DA.forEach((d, i) => { const q = prA[i]; spotsA[d.name] = { world: W4(d.w), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d.kind, sprite: d.sprite, what: d.what }; });

  /* ---- things he can touch ---- */
  const boxOf = async (q, w) => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const g = await proj(q, cs), xs = g.map(p => p[0]), ys = g.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  const TH = async (q, world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: await boxOf(q, world), what }, extra);
  const things = {};
  for (const f of FR) things[f.k] = await TH(TQ, [f.x0, 0, 0, f.x1, .02, f.h], 'the front of the ' + f.k + ': its lit wall, a poke (door and sign inside it)');
  for (const f of FR) things['puerta_' + f.k] = await TH(TQ, [f.d0, 0, 0, f.d1, .02, E.DH], 'the door of the ' + f.k + ', a poke (story 56: the door is the thing; the doorway, in any state of the door)');
  things.caballito = await TH(TQ, [E.HORSE[0] + HORSE_BOX[0], E.HORSE[1] + HORSE_BOX[1], HORSE_BOX[2], E.HORSE[0] + HORSE_BOX[3], E.HORSE[1] + HORSE_BOX[4], HORSE_BOX[5]], 'the little horse with its coin box: its volume, a poke');
  { const b = things.caballito.box, h = T.parts.caballito; if (h[0] < b[0] || h[2] >= b[0] + b[2] || h[1] < b[1] || h[3] >= b[1] + b[3]) throw new Error('the horse\'s pixels ' + h.slice(0, 4) + ' are not inside its thing box ' + b); }
  for (const k of ['comida', 'abuela', 'bebe', 'luis', 'mama', 'papa', 'senora', 'senor', 'coqui']) things[k] = 'sprite';
  const thingsA = {};
  for (const [k, h] of [['alto', EA.ALTO.h], ['nuevo', EA.NUEVO.h]]) {
    thingsA[k] = { set: true, by: 'lado', what: 'the ' + (k === 'alto' ? 'tall old' : 'low new') + ' building: its lit wall, a poke (' + (k === 'alto' ? EA.ALTO.h : EA.NUEVO.h) + ' high, ' + EA.ALTO.w + ' wide); izq = lado izq (the tall one on the left), der = lado der' };
    for (const lado of ['izq', 'der']) {
      const tallLeft = lado === 'izq', x0 = (k === 'alto') === tallLeft ? EA.AX[0] : EA.AX[1];
      const w = [x0, 0, 0, x0 + EA.ALTO.w, .02, h];
      thingsA[k][lado] = { world: W4(w), box: await boxOf(AQ, w) };
    }
  }
  thingsA.comida = 'sprite';
  for (const k of ['abuela', 'bebe', 'luis', 'mama', 'papa', 'senora', 'senor', 'coqui']) thingsA[k] = 'sprite';

  /* ---- the groups ---- */
  const groups = { inicio: ['abuela.acera', 'cochecito', 'coqui.acera'], grupo_caballito: ['abuela.caballito', 'cochecito.caballito', 'caballito'] };
  for (const f of FR) groups['grupo_' + f.k] = ['abuela.puerta_' + f.k, 'cochecito.puerta_' + f.k, 'coqui.puerta_' + f.k];
  const groupsA = { puerta_izq: ['puerta_izq', 'luis.puerta_izq', 'coqui.puerta_izq'], puerta_der: ['puerta_der', 'luis.puerta_der', 'coqui.puerta_der'], bici: ['bici', 'coqui.bici'], bordillo: ['bordillo1', 'bordillo2'] };

  /* ---- the views: x0 so that every spot's sprite is whole inside the window and, for tiendas, the horse, the four doors, the four signs and the post box too ---- */
  const boxesT = Object.entries(things).filter(([, t]) => t.box).map(([k, t]) => [k, t.box]);
  const boxesA = Object.entries(thingsA).flatMap(([k, t]) => t.izq ? [[k + ' izq', t.izq.box], [k + ' der', t.der.box]] : []);
  const needsT = await needsOfTiendas(T, FR, spots, KB, proj, boxesT);
  const pickT = pickX0(needsT.items, T.W, needsT.rowItems, needsT.spotsEnd);
  const needsA = await needsOfAltos(A, AL, spotsA, KB, proj, boxesA);
  const pickA = pickX0(needsA.items, A.W, needsA.rowItems, needsA.spotsEnd);
  const mkView = (pick, needs, what) => ({ zoom: 1, x0: pick.x0, region: [pick.x0, 0, 196, 216], needs: { from: needs.from, to: needs.to, picked: pick.how, items: needs.items.map(i => [i.name, i.lo, i.hi]) }, what });
  const views = { tiendas: mkView(pickT, needsT, 'the one view of fila tiendas: the 196 x 216 window over the 240 x 216 picture. x0 = the value in 0 .. 44 that holds what must be inside (the horse, the four doors, the four signs and the post box, and every spot\'s sprite: needs lists each as [name, first column, last column]) with the fewest cut pixels; of those, the one nearest to the middle of the span (x0 = clamp(round((from + to) / 2 - 98), 0, 44)). `needs.picked` says what it holds and what is cut') };
  const viewsA = { altos: mkView(pickA, needsA, 'the one view of fila altos: the 196 x 216 window over the 240 x 216 picture, chosen the same way: it must hold both buildings\' doors (with their frames) and every spot\'s sprite') };

  const sc = T.scene, sa = A.scene;
  const sheet = {
    scene: 'tiendas',
    made: 'node docs/proyecto/pixel/tiendas-sheet-make.js, from tiendas-set.html (window.TIENDAS.E) and the design of Las tiendas (the orchestrator\'s p5-spec, section tiendas). A new scene: no old scene, no remap.',
    S: T.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [T.W, T.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels. The row\'s wall is y = 0 (the fronts face +y); the pavement runs from it to y = ' + E.PV + ', the kerb to y = ' + E.S0 + ', then the street. This is the state fila = tiendas; fila = altos has its own origin, spots and view in `altos`',
      spot: 'a spot is a world point of the feet (z 0: the pavement; z ' + SEAT_TOP + ': the seat\'s top; z ' + HORSE_Z + ': the horse\'s back) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere. spot.sprite says which maker stands there in the preview (the make\'s checks use it); the game may put someone else there',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty), a child 41 rows; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; Luis sitting mkPersona(..., sent = 1): feet on sy; the stroller with the bebé (a stand-in, 24 x 36): column 12, its wheels\' bottom on sy; Luis\'s bicycle (a stand-in, 44 x 34): the handlebar\'s column 28 on sx (the preview draws it 8 px right of bici, behind Luis); a small thing: its bottom middle on the point. Widths of the boxes for the checks: the frog 32, a grown-up 24, a child 24, the stroller 24 (its stand-in\'s own width: the spec gives none)',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0, kept inside 0 .. 44. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point (z counts: d = (x + y) / R2 * COS + z * .5); front.plane turns it into the depth of each row of a character.',
      doors: 'a front is the lit wall x0 .. x1 (E.FW wide), y = 0, h high (E.H, the banco .25 more); its door from x0 + E.DOOR, E.DW wide, E.DH high, with a frame .12 wider on each side and .12 higher; its sign (a board on the wall, y .03) .22 in from each side, from E.DH + .18 to h - .06. fronts[] below lists the numbers the checks use',
    },
    setKey: {
      params: { fila: { values: ['tiendas', 'altos'] }, par: { values: ['a', 'b'], only: 'altos' }, lado: { values: ['izq', 'der'], only: 'altos', note: 'which side the tall building stands on' }, hora: { values: ['manana', 'tarde'] }, nube: { values: [0, 1, 2], note: 'the cloud: at the sky\'s edge, over the street, raining' } },
      key: 'tiendas: hora + nube, e.g. "manana-0"; altos: par + lado + hora, e.g. "a-izq-manana"',
      baked: { tiendas: ['manana', 'tarde'].flatMap(h => [0, 1, 2].map(n => '?fila=tiendas&hora=' + h + '&nube=' + n)), altos: ['a', 'b'].flatMap(p => ['izq', 'der'].flatMap(l => ['manana', 'tarde'].map(h => '?fila=altos&par=' + p + '&lado=' + l + '&hora=' + h))) },
    },
    fronts: Object.fromEntries(FR.map(f => [f.k, { wall: W4([f.x0, f.x1]), h: r4(f.h), door: W4([f.d0, f.d1]), doorMiddle: r4(f.dm), sign: { x: W4([f.sign.x0, f.sign.x1]), z: W4([f.sign.z0, f.sign.z1]), y: f.sign.y } }])),
    things,
    spots,
    groups,
    views,
    notes: [
      'a spot\'s name for the group at a door is abuela.puerta_<k>, cochecito.puerta_<k>, coqui.puerta_<k> (the spec gives their places, not their names); likewise cochecito.caballito, abuela.caballito, pan, abuela.lluvia and, in altos, luis.puerta_izq/der, coqui.puerta_izq/der. Pass 2 (the orchestrator\'s new numbers): the seat is at E.SEAT [.9, 1.95] (x .9 to 2.9), the frog of story 56\'s ending stays at coqui.56 (there is no coqui.lluvia), puerta_izq / puerta_der are the doorway (D, .5, 0), coqui.bici stands beside the bicycle (z 0)',
      'a front\'s thing box is its lit wall (a slab .02 deep, from the wall\'s left end to its right end and from the floor to its height), so that two fronts\' boxes do not overlap; the door\'s box is the door\'s own width and height',
      'readings of the spec the make took where it says less than it needs (the orchestrator may change them): senora.tienda is the tienda door\'s MIDDLE ("door of the tienda"), y .8; bordillo1 is Luis and bordillo2 the frog; in altos the group in front of a door (luis.puerta_*, coqui.puerta_*) is given for both buildings, the spec names only the tall one\'s; the preview\'s hora is manana for moments 1 to 3 and 6 to 8 and tarde for 4 and 5 (story 56 is the afternoon), moment 8 uses lado der as moment 7; the stroller\'s box is 24 wide (its stand-in, narrowed from 26 in pass 2) and its shadow .35 (the spec gives neither); the frog\'s box is 32 x 24 (his drawn rows)',
    ],
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so a front hides nobody who stands in front of it, the seat\'s back hides nobody who sits on it, and a person at a door is whole.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El mostrador\'s front; the same test for people, the stroller and the small things',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; equal depths: the one drawn later',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, cochecito: .35 },
      byCharacter: { coqui: .45, abuela: .35, senora: .35, senor: .35, mama: .35, papa: .35, luis: .28, cochecito: .35 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0)',
      none: ['caballito', 'banco_acera', 'pan'],
      onSeat: 'the frog on the horse and abuela on the seat cast none: they are not on the ground (the horse and the seat cast their own)',
    },
    altos: {
      what: 'the state fila = altos (story 55): two buildings with no sign, a tall old one and a low new one; par a | b picks the pair, lado izq | der says which side the tall one stands on. tiendas-set.html draws it with its own origin; its picture, spots, things and view are here; the depth rule, the anchors and the shadows are the same as above',
      origin: { originX: sa.originX, originY: sa.originY }, picture: [A.W, A.H], view: [196, 216],
      setKey: { params: { par: { values: ['a', 'b'] }, lado: { values: ['izq', 'der'] }, hora: { values: ['manana', 'tarde'] } }, key: 'par + lado + hora, e.g. "a-izq-manana"', baked: ['a', 'b'].flatMap(p => ['izq', 'der'].flatMap(l => ['manana', 'tarde'].map(h => '?fila=altos&par=' + p + '&lado=' + l + '&hora=' + h))) },
      buildings: { width: EA.ALTO.w, left: EA.AX[0], right: EA.AX[1], alto: EA.ALTO.h, nuevo: EA.NUEVO.h, doors: AL.doors.map(d => ({ door: W4([d.d0, d.d1]), doorMiddle: r4(d.dm) })) },
      things: thingsA,
      spots: spotsA,
      groups: groupsA,
      views: viewsA,
      shadows: { byCharacter: { luis: .28, senor: .35, mama: .35, coqui: .45 }, none: [], at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0)' },
    },
  };
  Object.defineProperty(sheet, 'geometry', { value: { FR, AL, needsT, needsA, pickT, pickA }, enumerable: false });
  return sheet;
}

/* ---------- the window: what it must hold (columns), and the x0 that holds the most of it ---------- */
// the first and the last picture column of a flat rectangle on the plane y = at (its 4 corners projected)
async function colsOfRect(proj, q, at, a0, a1, z0, z1) {
  const g = await proj(q, [[a0, at, z0], [a1, at, z0], [a0, at, z1], [a1, at, z1]]), xs = g.map(p => p[0]);
  return [Math.floor(Math.min(...xs)), Math.ceil(Math.max(...xs)) - 1];
}
// a sprite's columns on its spot: the box of its class (centred, width by class) and the pixels the maker draws, together; the rows its pixels reach
function spriteCols(KB, kind, sx, sy) {
  const b = KB[kind], hw = b.width ? b.width / 2 : 0;
  return { lo: sx + Math.min(b.left, b.width ? -hw : b.left), hi: sx + Math.max(b.right, b.width ? hw - 1 : b.right), top: sy + b.top, bottom: sy + b.bottom - 1 };
}
async function needsOfTiendas(G, FR, spots, KB, proj, boxes) {
  const items = [];
  const horse = G.parts.caballito, post = G.parts.buzon;
  items.push({ name: 'caballito (the horse\'s pixels)', lo: horse[0], hi: horse[2] }, { name: 'buzon (the post box\'s pixels)', lo: post[0], hi: post[2] });
  for (const f of FR) {
    const d = await colsOfRect(proj, TQ, 0, f.frame.x0, f.frame.x1, 0, f.frame.z1), s = await colsOfRect(proj, TQ, f.sign.y, f.sign.x0, f.sign.x1, f.sign.z0, f.sign.z1);
    items.push({ name: 'door ' + f.k, lo: d[0], hi: d[1] }, { name: 'sign ' + f.k, lo: s[0], hi: s[1] });
  }
  const row = items.length;
  for (const [k, s] of Object.entries(spots)) { const c = spriteCols(KB, s.sprite, s.screen[0], s.screen[1]); items.push({ name: 'spot ' + k, lo: c.lo, hi: c.hi }); }
  const spotsEnd = items.length;
  for (const [name, b] of boxes) items.push({ name: 'thing ' + name, lo: b[0], hi: b[0] + b[2] - 1 });
  return { items, rowItems: row, spotsEnd, from: Math.min(...items.slice(0, spotsEnd).map(i => i.lo)), to: Math.max(...items.slice(0, spotsEnd).map(i => i.hi)) };
}
async function needsOfAltos(G, AL, spotsA, KB, proj, boxes) {
  const items = [];
  for (const [n, d] of AL.doors.entries()) { const c = await colsOfRect(proj, AQ, 0, d.d0 - DOOR_FRAME, d.d1 + DOOR_FRAME, 0, 2.4 + DOOR_FRAME); items.push({ name: 'door ' + (n ? 'der' : 'izq'), lo: c[0], hi: c[1] }); }
  const row = items.length;
  for (const [k, s] of Object.entries(spotsA)) { const c = spriteCols(KB, s.sprite, s.screen[0], s.screen[1]); items.push({ name: 'spot ' + k, lo: c.lo, hi: c.hi }); }
  const spotsEnd = items.length;
  for (const [name, b] of boxes) items.push({ name: 'thing ' + name, lo: b[0], hi: b[0] + b[2] - 1 });
  return { items, rowItems: row, spotsEnd, from: Math.min(...items.slice(0, spotsEnd).map(i => i.lo)), to: Math.max(...items.slice(0, spotsEnd).map(i => i.hi)) };
}
// the x0 in 0 .. W - 196, in this order: (1) no cut pixel of the row (the items before rowItems: for tiendas the horse, the doors, the signs and the post box; for altos the doors), (2) the fewest cut pixels
// of the spots' sprites (the items up to spotsEnd), (3) the fewest cut pixels of the things' boxes (the rest), (4) nearest to the middle of the row and the spots' span. If no x0 holds the row, the fewest cut pixels in it come first
function pickX0(items, W, rowItems, spotsEnd) {
  const core = items.slice(0, spotsEnd), lo = Math.min(...core.map(i => i.lo)), hi = Math.max(...core.map(i => i.hi)), mid = Math.max(0, Math.min(W - 196, Math.round((lo + hi) / 2 - 98)));
  const cutOf = (x0, list) => { let cut = 0, n = 0; for (const i of list) { const c = Math.max(0, x0 - i.lo) + Math.max(0, i.hi - (x0 + 195)); if (c) n++; cut += c; } return [cut, n]; };
  const table = [];
  for (let x0 = 0; x0 <= W - 196; x0++) { const [rc, rn] = cutOf(x0, items.slice(0, rowItems)), [sc, sn] = cutOf(x0, items.slice(rowItems, spotsEnd)), [bc, bn] = cutOf(x0, items.slice(spotsEnd)); table.push({ x0, rowCut: rc, rowItemsCut: rn, spotCut: sc, spotsCut: sn, boxCut: bc, boxesCut: bn }); }
  const key = t => [t.rowCut, t.spotCut, t.boxCut, Math.abs(t.x0 - mid)];
  const best = table.slice().sort((p, q) => { const a = key(p), b = key(q); for (let i = 0; i < 4; i++) if (a[i] !== b[i]) return a[i] - b[i]; return 0; })[0];
  const feas = table.filter(t => t.rowCut === 0).map(t => t.x0), feasSpots = table.filter(t => t.rowCut === 0 && t.spotCut === 0).map(t => t.x0);
  const how = (best.rowCut ? 'no x0 holds the row (the horse, the doors, the signs, the post box): x0 ' + best.x0 + ' cuts it by ' + best.rowCut + ' px; ' : 'x0 ' + best.x0 + ' holds the whole row (it does for x0 ' + (feas.length ? feas[0] + ' to ' + feas[feas.length - 1] : 'none') + '); ')
    + (best.spotCut ? 'no x0 holds every spot\'s sprite as well: with this one ' + best.spotsCut + ' spot sprite(s) are cut by ' + best.spotCut + ' px in all' : 'every spot\'s sprite is inside as well (row and spots both fit for x0 ' + (feasSpots.length ? feasSpots[0] + ' to ' + feasSpots[feasSpots.length - 1] : 'none') + ')') + '; the things\' boxes are cut by ' + best.boxCut + ' px in all' + ' (span of the row and the spots: columns ' + lo + ' to ' + hi + ')';
  return Object.assign({}, best, { how, mid, table, feas });
}

/* ---------- the checks ---------- */
// the nearest place along x or y of a world point (steps of .01, up to 3) where ok(screen x, screen y) holds: the hits at the least distance, as text. For a failure's report only: the spec's number is kept
function nearestPass(G, w, ok) {
  for (let k = 1; k <= 300; k++) {
    const hits = [];
    for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); const [sx, sy] = scrOf(G, q[0], q[1], q[2]); if (ok(sx, sy, q)) hits.push((ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')'); }
    if (hits.length) return hits.join(' or ');
  }
  return 'none within 3';
}


/* the depth plane of a placed sprite at picture row Y: the upright plane through its feet (the sheet's front rule) */
const planeAt = (o, Y, S) => o.d + (o.sy - (Y + .5)) * T30 / S;
const depthOf = w => (w[0] + w[1]) / R2 * COS + w[2] * .5;
// every candidate place of a spot, nearest first: both axes, both signs, steps of .01 up to 3 (as nearestPass)
function candidates(G, w) {
  const out = [];
  for (let k = 1; k <= 300; k++) for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); const [sx, sy] = scrOf(G, q[0], q[1], q[2]); out.push({ k, ax, sg, w: q, sx, sy, d: depthOf(q), label: (ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')' }); }
  return out;
}
// the nearest candidates (all the hits at the least distance) where ok(candidate, index) holds, as text
const firstHits = (cands, ok) => { let k = 0; const hits = []; for (let i = 0; i < cands.length; i++) { if (hits.length && cands[i].k !== k) break; if (ok(cands[i], i)) { k = cands[i].k; hits.push(cands[i].label); } } return hits.length ? hits.join(' or ') : 'none within 3'; };

async function checks(sheet, T, A, KB, PVD, proj, page, load) {
  const OUTS = [], GEO = Object.getOwnPropertyDescriptor(sheet, 'geometry').value, FR = GEO.FR, AL = GEO.AL;
  const add = (name, bad, okLine, failLines) => { OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }); return OUTS[OUTS.length - 1]; };
  const E = T.E, EA = A.E, S = T.S;
  const FILAS = [
    { id: 'tiendas', G: T, spots: sheet.spots, view: sheet.views.tiendas, needs: GEO.needsT, pick: GEO.pickT, set: TSET },
    { id: 'altos', G: A, spots: sheet.altos.spots, view: sheet.altos.views.altos, needs: GEO.needsA, pick: GEO.pickA, set: ASET },
  ];
  const Wp = sheet.picture[0], Hp = sheet.picture[1];
  const FG = { tiendas: FILAS[0], altos: FILAS[1] };
  const MS = Object.keys(PVD.moments).map(Number);
  const qOfSet = st => 'fila=' + st.fila + (st.fila === 'altos' ? '&par=' + st.par + '&lado=' + st.lado : '') + '&hora=' + st.hora + '&nube=' + st.nube + '&tags=1';
  // the part of the set that drew each of these pixels (picture indices), in a state of the set
  const tagsOf = async (st, pxs) => { await load(qOfSet(st)); return page.evaluate(idx => idx.map(i => TAGS[i] || 'ground'), pxs.map(p => p[1] * Wp + p[0])); };
  const tally = tags => { const t = {}; for (const x of tags) t[x] = (t[x] || 0) + 1; return t; };
  const tallyText = t => Object.entries(t).map(([k, v]) => v + ' by ' + k).join(', ');
  // how many of a sprite's template pixels (offsets from its anchor) a state of the set hides, for each candidate place: one evaluate for all of them
  const hiddenAt = async (st, tpl, cands) => { await load(qOfSet(st)); return page.evaluate(arg => arg.cands.map(c => { let n = 0; for (const [dx, dy] of arg.tpl) { const X = c[0] + dx, Y = c[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; if (DEPTH.z[Y * W + X] > c[2] + (c[1] - (Y + .5)) * arg.t30 / DEPTH.S + arg.bias) n++; } return n; }), { tpl, cands: cands.map(c => [c.sx, c.sy, c.d]), t30: T30, bias: BIAS }); };
  const tplOf = (l, shownOnly) => l.px.filter(p => !shownOnly || !p[2]).map(p => [p[0] - l.sx, p[1] - l.sy]);
  // the pixels of `box` (columns x0 .. x1, rows y0 .. y1) that the sprites `others` draw nearer than the frog `fr` does; `ink` of them are pixels the frog draws
  const coverage = (fr, frTpl, others, box) => {
    const ink = new Set(frTpl.map(([dx, dy]) => (fr.sx + dx) + ',' + (fr.sy + dy))), boxCov = new Set(), inkCov = new Set(), by = {};
    for (const o of others) for (const [dx, dy] of o.tpl) {
      const X = o.sx + dx, Y = o.sy + dy; if (X < box.x0 || X > box.x1 || Y < box.y0 || Y > box.y1) continue;
      const po = planeAt(o, Y, S), pf = planeAt(fr, Y, S);
      if (!(po > pf + 1e-9 || (Math.abs(po - pf) <= 1e-9 && o.order > fr.order))) continue;
      const key = X + ',' + Y; boxCov.add(key); if (ink.has(key)) inkCov.add(key);
      const b = by[o.at] || (by[o.at] = { box: new Set(), ink: new Set() }); b.box.add(key); if (ink.has(key)) b.ink.add(key);
    }
    return { box: boxCov.size, ink: inkCov.size, by: Object.fromEntries(Object.entries(by).map(([k, v]) => [k, { box: v.box.size, ink: v.ink.size }])) };
  };
  const byText = by => Object.entries(by).map(([k, v]) => k + ' ' + v.ink + ' of his pixels, ' + v.box + ' of his box').join('; ');

  // 1. every spot inside the picture and inside the view's window with its sprite whole (report each cut, by how many pixels); the things' boxes inside the picture
  {
    const bad = [], info = [], lines = [];
    let n = 0;
    for (const F of FILAS) {
      const x0 = F.view.x0;
      for (const [k, s] of Object.entries(F.spots)) {
        n++;
        const c = spriteCols(KB, s.sprite, s.screen[0], s.screen[1]);
        const left = Math.max(0, x0 - c.lo), right = Math.max(0, c.hi - (x0 + 195)), picL = Math.max(0, -c.lo), picR = Math.max(0, c.hi - (Wp - 1)), top = Math.max(0, -c.top), bot = Math.max(0, c.bottom - (Hp - 1));
        if (left || right || picL || picR || top || bot) {
          const near = nearestPass(F.G, s.world, (sx, sy) => { const q = spriteCols(KB, s.sprite, sx, sy); return q.lo >= x0 && q.hi <= x0 + 195 && q.lo >= 0 && q.hi <= Wp - 1 && q.top >= 0 && q.bottom <= Hp - 1; });
          bad.push(F.id + ' ' + k + ' ' + s.screen + ' (' + s.sprite + ' box columns ' + c.lo + ' to ' + c.hi + ', rows ' + c.top + ' to ' + c.bottom + ') is cut: ' + [left && left + ' px left of the window x0 ' + x0, right && right + ' px right of the window (' + (x0 + 195) + ')', picL && picL + ' px left of the picture', picR && picR + ' px right of the picture', top && top + ' rows above the picture', bot && bot + ' rows under the picture'].filter(Boolean).join(', ') + '; nearest spot value that holds it whole: ' + near);
        }
      }
      for (const [k, t] of Object.entries(F.id === 'tiendas' ? sheet.things : sheet.altos.things)) {
        const boxes = t.box ? [[k, t.box]] : (t.izq ? [[k + ' izq', t.izq.box], [k + ' der', t.der.box]] : []);
        for (const [name, b] of boxes) {
          if (b[0] < 0 || b[0] + b[2] > Wp || b[1] < 0 || b[1] + b[3] > Hp) bad.push(F.id + ' thing ' + name + ' box ' + b + ' is outside the picture');
          else if (b[0] < x0 || b[0] + b[2] > x0 + 196) info.push(F.id + ' thing ' + name + ' box columns ' + b[0] + ' to ' + (b[0] + b[2] - 1) + ' are partly outside the window [' + x0 + ', ' + (x0 + 196) + ') by ' + (Math.max(0, x0 - b[0]) + Math.max(0, b[0] + b[2] - 1 - (x0 + 195))) + ' px');
        }
      }
      lines.push(F.id + ' window [' + x0 + ', ' + (x0 + 196) + '): ' + F.view.needs.picked);
    }
    const r = add('in-view', bad, n + ' spots (every spot of both filas) have their sprite whole inside the picture and the window; ' + lines.join('; '), [bad.length + ' spot(s) with a cut sprite or a thing outside the picture (a spot\'s sprite is its class box, 32 / 24 / 24 / 24 wide, together with the pixels its maker draws):'].concat(bad.map(b => '  ' + b), lines.map(l => '  ' + l)));
    for (const F of FILAS) { const clean = F.pick.table.filter(t => !t.rowCut && !t.spotCut).map(t => t.x0); r.lines.push('       info, not a check: ' + F.id + ' x0 trade-off, each x0 as (px of the row cut / px of spots\' sprites cut / px of things\' boxes cut): ' + F.pick.table.filter(t => (F.id === 'tiendas' ? t.x0 <= 10 : t.x0 % 2 === 1 || t.x0 === F.pick.x0) && t.x0 <= (F.id === 'tiendas' ? 10 : 22)).map(t => t.x0 + ': ' + t.rowCut + '/' + t.spotCut + '/' + t.boxCut).join(', ') + '; row and spots both whole for x0 ' + (clean.length ? clean[0] + ' to ' + clean[clean.length - 1] : 'none') + '; chosen ' + F.pick.x0); }
    for (const i of info) r.lines.push('       info, not a check: ' + i);
  }

  // 2. fila tiendas: the horse, the four doors, the four signs and the post box are all inside one window (report x0); fila altos: both buildings' doors
  {
    const bad = [], tx = FG.tiendas.view.x0, ax = FG.altos.view.x0, lines = [];
    const rowT = GEO.needsT.items.slice(0, GEO.needsT.rowItems), rowA = GEO.needsA.items.slice(0, GEO.needsA.rowItems);
    for (const it of rowT) { const c = Math.max(0, tx - it.lo) + Math.max(0, it.hi - (tx + 195)); if (c) bad.push('tiendas: ' + it.name + ' columns ' + it.lo + ' to ' + it.hi + ' is cut by ' + c + ' px in the window [' + tx + ', ' + (tx + 196) + ')'); }
    for (const it of rowA) { const c = Math.max(0, ax - it.lo) + Math.max(0, it.hi - (ax + 195)); if (c) bad.push('altos: ' + it.name + ' columns ' + it.lo + ' to ' + it.hi + ' is cut by ' + c + ' px in the window [' + ax + ', ' + (ax + 196) + ')'); }
    const loT = Math.min(...rowT.map(i => i.lo)), hiT = Math.max(...rowT.map(i => i.hi)), loA = Math.min(...rowA.map(i => i.lo)), hiA = Math.max(...rowA.map(i => i.hi));
    lines.push('tiendas: the row\'s own span is columns ' + loT + ' to ' + hiT + ' (' + (hiT - loT + 1) + ' wide): it fits one window for x0 ' + Math.max(0, hiT - 195) + ' to ' + Math.min(Wp - 196, loT) + ' (' + rowT.map(i => i.name.replace(/ \(.*/, '') + ' ' + i.lo + '..' + i.hi).join(', ') + ')');
    lines.push('altos: both doors span columns ' + loA + ' to ' + hiA + ' (' + rowA.map(i => i.name + ' ' + i.lo + '..' + i.hi).join(', ') + ')');
    add('row-in-window', bad, 'tiendas: the horse, the four doors, the four signs and the post box are inside the window x0 ' + tx + ' ([' + tx + ', ' + (tx + 196) + ')); altos: both doors are inside x0 ' + ax, ['the row is not inside its window:'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].lines.push(...lines.map(l => '       ' + l));
  }

  // 3. people who stand together in a moment: sprite boxes do not overlap sideways unless their feet are 12 px or more apart up-down (El mostrador's sprites-apart)
  {
    const bad = [], all = [], hints = [];
    for (const m of MS) {
      const M = PVD.moments[m], G = FG[M.fila].G, L = M.layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (KB[a.k].width + KB[b.k].width) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, ka: a.k, kb: b.k, dx, dy, half, over, ok });
        if (!ok) { bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + KB[a.k].width + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + KB[b.k].width + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); hints.push({ m, a, b, half, G }); }
      }
    }
    const r = add('sprites-apart', bad, all.length + ' pairs in the 8 moments of the preview: no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' px across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (the frog 32 wide, a grown-up 24, a child 24, the stroller 24):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) {                                                           // the nearest spot value that would pass (the spec's numbers are kept)
      const pass = other => (sx, sy) => Math.abs(sx - other.sx) >= h.half || Math.abs(sy - other.sy) >= UPDOWN;
      r.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + h.a.world + ': ' + nearestPass(h.G, h.a.world, pass(h.b)) + '; or ' + h.b.at + ' ' + h.b.world + ': ' + nearestPass(h.G, h.b.world, pass(h.a)));
    }
    r.lines.push('       closest in each moment (px across / px down): ' + MS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    r.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 4. (pass 2) the frog is never behind a grown-up, a car or a guagua: in every moment he is seen. His drawn pixels are counted. The set hides none of them, except on the horse, where the horse's own neck may hide up to
  //    HORSE_NECK (30) px. A grown-up (or any other thing) covers none of them; a child or the stroller may cover up to POOL (40) px of him, together
  {
    const bad = [], lines = [], hints = [];
    const fb = KB.coqui;
    for (const m of MS) {
      const M = PVD.moments[m], G = FG[M.fila].G, fr = M.layers.find(l => l.k === 'coqui'), onHorse = fr.at === 'caballito';
      const frT = { sx: fr.sx, sy: fr.sy, d: fr.d, order: fr.order, tpl: tplOf(fr) };
      const hid = fr.px.filter(p => p[2]), hidTags = tally(await tagsOf(M.set, hid)), neck = hidTags.caballito || 0;
      const hidOver = onHorse ? hid.length - neck + Math.max(0, neck - HORSE_NECK) : hid.length;
      const mk = o => ({ at: o.at, sx: o.sx, sy: o.sy, d: o.d, order: o.order, who: o.who, tpl: tplOf(o, true) });
      const others = M.layers.filter(o => o !== fr).map(mk);
      const isPool = o => o.who === 'nino' || o.who === 'cochecito';
      const verdict = (frp, oth) => {
        const bx = { x0: frp.sx - 16, x1: frp.sx + 15, y0: frp.sy + fb.top, y1: frp.sy - 1 };
        const big = coverage(frp, frT.tpl, oth.filter(o => !isPool(o)), bx), small = coverage(frp, frT.tpl, oth.filter(isPool), bx);
        return { big: big.ink, pool: small.ink, by: Object.assign({}, big.by, small.by) };
      };
      const ok = q => q.big === 0 && q.pool <= POOL;
      const v = verdict(frT, others);
      const line = 'moment ' + m + ' the frog at ' + fr.at + ' [' + fr.sx + ',' + fr.sy + ']: ' + fr.px.length + ' drawn pixels, ' + hid.length + ' hidden by the set' + (hid.length ? ' (' + tallyText(hidTags) + (onHorse ? '; up to ' + HORSE_NECK + ' by the horse allowed' : '') + ')' : '') + ', ' + v.big + ' covered by grown-ups or things (needs 0), ' + v.pool + ' by a child or the stroller (up to ' + POOL + ' allowed)' + (v.big + v.pool ? ' [' + byText(v.by) + ']' : '');
      lines.push(line);
      if (hidOver || !ok(v)) {
        bad.push(line);
        // the nearest place that clears it: the frog's own spot, and each covering sprite's spot alone (the rest stay; a moved sprite's hidden pixels are not counted)
        const cands = candidates(G, fr.world), hc = await hiddenAt(M.set, frT.tpl, cands);
        const frogHit = firstHits(cands, (c, i) => hc[i] === 0 && ok(verdict({ sx: c.sx, sy: c.sy, d: c.d, order: fr.order }, others)));
        const alone = [];
        for (const o of Object.keys(v.by).filter(k => v.by[k].ink)) {
          const ol = M.layers.find(l => l.at === o), oc = candidates(G, ol.world);
          alone.push(o + ' ' + ol.world + ' -> ' + firstHits(oc, c => ok(verdict(frT, others.map(x => x.at === o ? Object.assign({}, x, { sx: c.sx, sy: c.sy, d: c.d }) : x)))));
        }
        const setLeft = hidOver ? ' (the ' + hidOver + ' px the set hides beyond what is allowed, ' + tallyText(hidTags) + ', stay hidden)' : '';
        hints.push('       nearest passing, moment ' + m + ' (one spot moved, the others stay): ' + (onHorse ? 'the frog\'s spot caballito is the horse\'s back (E.HORSE, z ' + HORSE_Z + '), it does not move; ' : 'either the frog\'s spot ' + fr.at + ' ' + fr.world + ': ' + frogHit + '; or ') + (alone.length ? (alone.length > 1 ? 'all of these together (each clears only its own cover)' : 'this') + setLeft + ': ' + alone.join(' AND ') : ''));
      }
    }
    const r = add('frog-seen', bad, 'in all ' + MS.length + ' moments the frog is seen: ' + lines.map(l => l.replace(/ the frog at ([^ ]+) \[[^\]]*\]: \d+ drawn pixels, /, ' $1: ')).join('; '), [bad.length + ' moment(s) in which the frog is hidden or covered beyond what is allowed (the set hides none of him, but up to ' + HORSE_NECK + ' px by the horse\'s neck on the horse; grown-ups cover none; a child or the stroller up to ' + POOL + ' px together):'].concat(bad.map(b => '  ' + b)));
    r.lines.push(...hints);
  }

  // 5. a person at a door stands in front of it, not inside the wall: his x is inside the door's width, his y is in front of the wall (y > 0) and no pixel of him is hidden by the front's wall (a pixel hidden by something else standing there, the post box, is reported)
  {
    const bad = [], lines = [], R = [], FRONT = FR.map(f => f.k);
    for (const f of FR) for (const name of ['puerta_' + f.k, 'abuela.puerta_' + f.k]) R.push(['tiendas', name, sheet.spots[name], f.d0, f.d1, TSET]);
    AL.doors.forEach((d, n) => { const name = n ? 'puerta_der' : 'puerta_izq'; R.push(['altos', name, sheet.altos.spots[name], d.d0, d.d1, ASET]); });
    for (const [id, name, s, d0, d1, st] of R) {
      const l = PVD.alone[id].find(q => q.at === name), hid = l.px.filter(p => p[2]), tg = tally(await tagsOf(st, hid)), wall = Object.entries(tg).filter(([t]) => FRONT.includes(t) || t === 'alto' || t === 'nuevo').reduce((a, [, v]) => a + v, 0), x = s.world[0], y = s.world[1];
      lines.push(name + ' x ' + x + ' (door ' + r2(d0) + ' to ' + r2(d1) + '), y ' + y + ', ' + wall + ' pixels hidden by a wall' + (hid.length - wall ? ' (and ' + (hid.length - wall) + ' of its ' + l.px.length + ' by other things: ' + tallyText(Object.fromEntries(Object.entries(tg).filter(([t]) => !(FRONT.includes(t) || t === 'alto' || t === 'nuevo')))) + ')' : ''));
      if (x < d0 || x > d1 || y <= 0 || wall) bad.push(name + ': x ' + x + ' door ' + r2(d0) + ' to ' + r2(d1) + ', y ' + y + ' (the wall is y 0), ' + wall + ' pixels hidden by a wall');
    }
    add('door-front', bad, R.length + ' spots at a door (the four puerta_<k> and their abuela.puerta_<k> in tiendas, puerta_izq and puerta_der in altos) are in front of their door: inside its width, in front of the wall and not hidden by it: ' + lines.join('; '), [bad.length + ' person(s) at a door inside or behind the wall:'].concat(bad.map(b => '  ' + b)));
  }

  // 6. a person on a seat sits on its top: the spot's z is the seat's top, its x, y are on the seat, and the set draws the seat (part asiento) with that depth at the spot's pixel; the frog on the horse the same, on the horse's back
  {
    await load(TQ);
    const seat = [E.SEAT[0], E.SEAT[0] + 2.0, E.SEAT[1], E.SEAT[1] + .5];
    const rd = await page.evaluate(names => names.map(([name, w]) => { const g = project(w[0], w[1], w[2]), i = Math.floor(g.sy) * W + Math.floor(g.sx); return [name, TAGS[i], DEPTH.z[i], g.d]; }), ['banco_acera', 'pan', 'caballito'].map(n => [n, sheet.spots[n].world]));
    const bad = [], lines = [];
    for (const [name, tag, z, d] of rd) {
      const w = sheet.spots[name].world, onSeat = name !== 'caballito';
      const want = onSeat ? 'asiento' : 'caballito', inX = !onSeat || (w[0] >= seat[0] && w[0] <= seat[1] && w[1] >= seat[2] && w[1] <= seat[3]), zOk = onSeat ? w[2] === SEAT_TOP : w[2] === HORSE_Z;
      lines.push(name + ' ' + w + ': the set\'s pixel there is part ' + tag + ', its depth ' + r4(z) + ' against the spot\'s ' + r4(d) + ' (' + r4(Math.abs(z - d)) + ' apart)');
      if (tag !== want || Math.abs(z - d) > .05 || !inX || !zOk) bad.push(name + ' ' + w + ': pixel part ' + tag + ' (wants ' + want + '), depth ' + r4(z) + ' vs ' + r4(d) + (inX ? '' : ', not on the seat x ' + seat.slice(0, 2) + ' y ' + seat.slice(2)) + (zOk ? '' : ', z is not the top'));
    }
    add('seat-top', bad, 'banco_acera and pan sit at z ' + SEAT_TOP + ' on the seat (x ' + seat[0] + ' to ' + seat[1] + ', y ' + seat[2] + ' to ' + seat[3] + ') and caballito at z ' + HORSE_Z + ' on the horse: the set draws the surface there at that depth: ' + lines.join('; '), ['a spot is not on the top of its seat:'].concat(bad.map(b => '  ' + b)));
  }

  // 7. nobody stands on the street unless the spec puts him there: every standing spot is on the pavement (y up to PV); the kerb (PV to S0) only where the spec says (bordillo1, bordillo2: Luis and the frog sit on it)
  {
    const bad = [], kerb = [];
    let my = -1, mn = '';
    for (const F of FILAS) for (const [k, s] of Object.entries(F.spots)) {
      if (!s.sprite || s.kind === 'small') continue;
      const y = s.world[1];
      if (y > E.S0 - .0001) bad.push(F.id + ' ' + k + ' y ' + y + ' is on the street (from y ' + E.S0 + ')');
      else if (y > E.PV) { if (['bordillo1', 'bordillo2'].includes(k)) kerb.push(k + ' y ' + y); else bad.push(F.id + ' ' + k + ' y ' + y + ' is on the kerb (y ' + E.PV + ' to ' + E.S0 + '), which the spec gives only to bordillo1 and bordillo2'); }
      else if (y > my) { my = y; mn = F.id + ' ' + k; }
    }
    add('street-clear', bad, 'no standing spot is on the street (from y ' + E.S0 + '); the pavement ends at y ' + E.PV + '; only ' + kerb.join(' and ') + ' (sitting on the kerb, as the spec says) are on the kerb; the nearest to the street of the rest is ' + mn + ' at y ' + my, ['somebody is on the street or the kerb:'].concat(bad.map(b => '  ' + b)));
  }

  // 8. nobody covers a sign: in the five moments of fila tiendas, and every spot's sprite on its own, no pixel a sprite draws (not hidden by the set) lies on a sign's board
  {
    const bad = [], signs = FR.map(f => f.sign);
    const hit = l => {
      const res = {};
      for (const p of l.px) {
        if (p[2]) continue;
        const [x, z] = onPlaneY(T, p[0], p[1], signs[0].y);
        for (const [n, s] of signs.entries()) if (x >= s.x0 && x <= s.x1 && z >= s.z0 && z <= s.z1) res[FR[n].k] = (res[FR[n].k] || 0) + 1;
      }
      return res;
    };
    for (const m of [1, 2, 3, 4, 5]) for (const l of PVD.moments[m].layers) { const h = hit(l); if (Object.keys(h).length) bad.push('moment ' + m + ' ' + l.at + ' (' + l.k + ') covers ' + Object.entries(h).map(([k, v]) => v + ' px of the ' + k + '\'s sign').join(', ')); }
    for (const l of PVD.alone.tiendas) { const h = hit(l); if (Object.keys(h).length) bad.push('spot ' + l.at + ' (' + l.k + ') alone covers ' + Object.entries(h).map(([k, v]) => v + ' px of the ' + k + '\'s sign').join(', ')); }
    // the least clearance: the lowest row of a sign's board against the topmost row any sprite draws at the board's columns (info)
    let least = 1e9, leastAt = '';
    for (const l of PVD.alone.tiendas) for (const p of l.px) { if (p[2]) continue; for (const [n, s] of signs.entries()) { const [x] = onPlaneY(T, p[0], p[1], s.y); if (x >= s.x0 && x <= s.x1) { const rowBoard = Math.floor(T.OY + ((x + s.y) / R2 * .5 - s.z0 * COS) * T.S), d = p[1] - rowBoard; if (d < least) { least = d; leastAt = l.at + ' under the ' + FR[n].k + '\'s sign'; } } } }
    add('signs-clear', bad, 'in moments 1 to 5 and for every spot of fila tiendas alone (' + PVD.alone.tiendas.length + ' sprites) no pixel a sprite draws covers any of the four signs\' boards; the closest a sprite\'s topmost pixel comes under a board\'s bottom edge row: ' + least + ' rows (' + leastAt + ')', [bad.length + ' sprite(s) cover a sign:'].concat(bad.map(b => '  ' + b)));
  }

  // 9. (pass 2) a group at a door does not cover the right-hand neighbour's door (the door and its frame); the stroller may cover its lower STROLLER_LOW (10) rows
  {
    const bad = [], lines = [], hints = [], frames = FR.map(f => f.frame), lowZ = STROLLER_LOW / (COS * T.S);
    // is the picture pixel on the frame of the neighbour's door; for the stroller its lower rows (z up to lowZ) do not count
    const hit = (X, Y, fr, k) => { const [x, z] = onPlaneY(T, X, Y, 0); return x >= fr.x0 && x <= fr.x1 && z >= 0 && z <= fr.z1 && !(k === 'cochecito' && z <= lowZ); };
    for (const [n, f] of FR.entries()) {
      const names = ['abuela.puerta_' + f.k, 'cochecito.puerta_' + f.k, 'coqui.puerta_' + f.k];
      if (n + 1 >= FR.length) { lines.push('the ' + f.k + ' group: no right-hand neighbour'); continue; }
      const nb = n + 1, fr = frames[nb], who = {}, low = {};
      for (const name of names) {
        const l = PVD.alone.tiendas.find(q => q.at === name);
        const shown = l.px.filter(p => !p[2]);
        const c = shown.filter(p => hit(p[0], p[1], fr, l.k)).length, all = shown.filter(p => hit(p[0], p[1], fr, null)).length;
        if (c) who[name] = c;
        if (all - c) low[name] = all - c;
      }
      const cov = Object.values(who).reduce((a, b) => a + b, 0);
      lines.push('the ' + f.k + ' group over the ' + FR[nb].k + '\'s door: ' + cov + ' px' + (cov ? ' (' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', ') + ')' : '') + (Object.keys(low).length ? '; the stroller\'s ' + Object.values(low).join(', ') + ' px in the door\'s lower ' + STROLLER_LOW + ' rows are allowed' : ''));
      if (cov) {
        bad.push('the group at the ' + f.k + ' covers ' + cov + ' px of the ' + FR[nb].k + '\'s door: ' + Object.entries(who).map(([k, v]) => k + ' ' + v).join(', '));
        for (const name of Object.keys(who)) {
          const l = PVD.alone.tiendas.find(q => q.at === name), tpl = tplOf(l), cands = candidates(T, l.world);
          hints.push('       nearest passing, the ' + f.k + ' group over the ' + FR[nb].k + '\'s door: ' + name + ' ' + l.world + ' alone: ' + firstHits(cands, c => !tpl.some(([dx, dy]) => hit(c.sx + dx, c.sy + dy, fr, l.k))));
        }
      }
    }
    const r = add('group-door-clear', bad, 'no group at a door covers the right-hand front\'s door (the stroller may cover its lower ' + STROLLER_LOW + ' rows): ' + lines.join('; '), [bad.length + ' covering of the right-hand front\'s door by a group at a door:'].concat(bad.map(b => '  ' + b)));
    r.lines.push(...hints);
    r.lines.push('       ' + lines.join('; '));
  }

  // 10. fila altos: both buildings' doors and the top of the tall one inside the picture, for both lado values and both pairs (the rows cut at the top are reported). The rows are read from the set itself,
  //     drawn on a picture 60 rows taller (ph 276, the origin 60 rows lower): the highest row each building draws there, less 60, is its row in the real picture; a negative row is cut
  {
    const bad = [], lines = [], SH = 60;
    let worst = 0;
    for (const par of ['a', 'b']) for (const lado of ['izq', 'der']) {
      await load('fila=altos&par=' + par + '&lado=' + lado + '&tags=1&ph=276&oy=' + (A.scene.originY + SH / 2));
      const top = await page.evaluate(() => { const o = {}; for (let i = 0; i < TAGS.length; i++) { const t = TAGS[i]; if (t !== 'alto' && t !== 'nuevo') continue; const y = (i / W) | 0; if (o[t] === undefined || y < o[t]) o[t] = y; } return o; });
      const rT = top.alto - SH, rN = top.nuevo - SH, cutT = Math.max(0, -rT), cutN = Math.max(0, -rN);
      worst = Math.max(worst, cutT, cutN);
      lines.push('par ' + par + ' lado ' + lado + ': the tall one (x ' + (lado === 'izq' ? EA.AX[0] : EA.AX[1]) + ', ' + EA.ALTO.h + ' high) draws as high as row ' + rT + (cutT ? ': ' + cutT + ' row(s) are above the picture' : ' (inside)') + '; the low one (' + EA.NUEVO.h + ' high) as high as row ' + rN + (cutN ? ': ' + cutN + ' row(s) above the picture' : ''));
      if (cutT) bad.push('par ' + par + ' lado ' + lado + ': the tall building\'s roof is cut at the top by ' + cutT + ' row(s) (its highest drawn row would be ' + rT + ')');
      if (cutN) bad.push('par ' + par + ' lado ' + lado + ': the low building\'s roof is cut at the top by ' + cutN + ' row(s)');
    }
    for (const [n, d] of AL.doors.entries()) {
      const x0 = d.d0 - DOOR_FRAME, x1 = d.d1 + DOOR_FRAME, lo = Math.floor(A.OX + x0 / R2 * A.S), hi = Math.ceil(A.OX + x1 / R2 * A.S) - 1, top = A.OY + (x0 / R2 * .5 - (EA.DH + DOOR_FRAME) * COS) * A.S, bottom = A.OY + (x1 / R2 * .5) * A.S;
      lines.push('door ' + (n ? 'der' : 'izq') + ': its frame spans columns ' + lo + ' to ' + hi + ' and rows ' + r2(top) + ' to ' + r2(bottom) + ' (in either lado)');
      if (lo < 0 || hi >= Wp || top < 0 || bottom >= Hp) bad.push('door ' + (n ? 'der' : 'izq') + ' is not inside the picture');
    }
    const lowest = Math.max(...Object.values(sheet.altos.spots).map(s => spriteCols(KB, s.sprite, s.screen[0], s.screen[1]).bottom));
    const r = add('altos-top', bad, 'both doors and the top of the tall building are inside the picture for lado izq and der, pars a and b: ' + lines.join('; '), ['fila altos:'].concat(bad.map(b => '  ' + b)));
    for (const l of lines) r.lines.push('       ' + l);
    if (worst) r.lines.push('       nearest value that passes: the origin\'s y ' + A.scene.originY + ' -> ' + (A.scene.originY + worst) + ' (+' + worst + '), i.e. everything ' + worst + ' rows lower; the lowest sprite row of any altos spot is then ' + (lowest + worst) + ' of ' + (Hp - 1) + (lowest + worst <= Hp - 1 ? ', which still fits' : ', which does NOT fit'));
  }

  // info: how much of each sprite the set hides when it stands alone on its spot (and by which part); who is covered by whom in each moment; the preview's sprites outside the window
  {
    const hidLines = [], cover = [], cut = [];
    for (const id of ['tiendas', 'altos']) for (const l of PVD.alone[id]) { const h = l.px.filter(p => p[2]); if (h.length) hidLines.push(id + ' ' + l.at + ' (' + l.k + '): ' + h.length + ' of ' + l.px.length + ' pixels (' + tallyText(tally(await tagsOf(FG[id].set, h))) + ')'); }
    for (const m of MS) {
      const M = PVD.moments[m], best = new Map();
      for (const l of M.layers) for (const p of l.px) { if (p[2]) continue; const key = p[1] * 240 + p[0], b = best.get(key); if (!b || p[3] > b.plane + 1e-9 || (Math.abs(p[3] - b.plane) <= 1e-9 && l.order > b.order)) best.set(key, { plane: p[3], order: l.order, at: l.at }); }
      for (const l of M.layers) { if (!l.who) continue; const shown = l.px.filter(p => !p[2]), by = {}; let n = 0; for (const p of shown) { const b = best.get(p[1] * 240 + p[0]); if (b.at !== l.at) { n++; by[b.at] = (by[b.at] || 0) + 1; } } if (n) cover.push('m' + m + ' ' + l.at + ' (' + l.k + '): ' + n + ' of ' + shown.length + ' shown pixels covered by ' + Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ')); }
      const x0 = FG[M.fila].view.x0;
      for (const l of M.layers) { const lo = Math.min(...l.px.map(p => p[0])), hi = Math.max(...l.px.map(p => p[0])), c = Math.max(0, x0 - lo) + Math.max(0, hi - (x0 + 195)); if (c) cut.push('m' + m + ' ' + l.at + ' (' + l.k + ') drawn columns ' + lo + ' to ' + hi + ': ' + c + ' px outside the window [' + x0 + ', ' + (x0 + 196) + ')'); }
    }
    const heads = [];
    for (const m of MS) {
      const M = PVD.moments[m], G = FG[M.fila].G;
      for (const l of M.layers) {
        if (!l.who || l.who === 'coqui') continue;
        const top = Math.min(...l.px.map(p => p[1])), hd = { sx: l.sx, sy: l.sy, d: l.d, order: l.order }, tpl = tplOf(l), headTpl = tpl.filter(([dx, dy]) => l.sy + dy < top + HEAD_ROWS);
        const others = M.layers.filter(o => o !== l).map(o => ({ at: o.at, sx: o.sx, sy: o.sy, d: o.d, order: o.order, tpl: tplOf(o, true) }));
        const box = { x0: -1e9, x1: 1e9, y0: top, y1: top + HEAD_ROWS - 1 };
        const cov = coverage(hd, headTpl, others, box);
        if (!cov.ink) continue;
        // a place frees the head when no pixel of any other sprite lies on it, whichever is nearer (a move that only turns the depth round would put him in front of the frog)
        const cands = candidates(G, l.world), otherPx = new Set();
        for (const o of others) for (const [dx, dy] of o.tpl) otherPx.add((o.sx + dx) + ',' + (o.sy + dy));
        const near = firstHits(cands, c => !headTpl.some(([dx, dy]) => otherPx.has((c.sx + dx) + ',' + (c.sy + dy))));
        heads.push('m' + m + ' ' + l.at + ' (' + l.k + '): ' + cov.ink + ' of the ' + headTpl.length + ' pixels of its head (the top ' + HEAD_ROWS + ' rows) are covered by ' + Object.entries(cov.by).filter(([, v]) => v.ink).map(([k, v]) => k + ' ' + v.ink).join(', ') + '; nearest place of this spot alone where no other sprite touches the head: ' + near);
      }
    }
    OUTS.push({ name: 'info-people', ok: true, lines: ['info-people: not a check; what the set hides of each sprite alone on its spot, who is covered by whom in the moments, and the preview\'s sprites (held things included) outside the window', '       hidden by the set (alone): ' + (hidLines.join('; ') || 'none'), '       covered by a nearer sprite in the moments: ' + (cover.join('; ') || 'none'), '       heads (the top ' + HEAD_ROWS + ' rows of a person) a nearer sprite covers: ' + (heads.join('; ') || 'none'), '       outside the window: ' + (cut.join('; ') || 'none')] });
  }
  return OUTS;
}
