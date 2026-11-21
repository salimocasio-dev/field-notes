#!/usr/bin/env node
'use strict';
/* El calendario's sheet: writes docs/proyecto/pixel/calendario-sheet.json from calendario-set.html and the design (the orchestrator's p6-spec, section "calendario"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/calendario-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S. The board's numbers (the columns' edges, the hooks' z, the arch, the step, the seat) are read from the set
   (window.CALENDARIO.E and colU), never typed again from the design.
   It loads the set in headless Chrome (calendario-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from today's makers (historia/engine.js, historia/escenas/kit.js) loaded in a second, empty page. The checks that say "covers" or "shows"
   read the PREVIEW's moments (calendario-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is
   written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CALENDARIO_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'calendario-sheet.json');
const BASE = process.env.CALENDARIO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/calendario-set.html';
const BLANK = BASE + '/__blank__.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

// every request to BASE is answered from the files of this tree
const serve = route => {
  const u = new URL(route.request().url());
  if (u.pathname === '/__blank__.html') return route.fulfill({ status: 200, contentType: 'text/html', body: '<!doctype html><html><head><meta charset="utf-8"><title>blank</title></head><body></body></html>' });
  const f = path.join(REPO, decodeURIComponent(u.pathname));
  if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
  route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
};
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100, sgn = v => (v > 0 ? '+' : '') + r2(v);
const W4 = p => p.map(r4);
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2;

// the numbers of the design (p6-spec: the rules for every sheet, and "calendario")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const CARD = { w: 14, h: 12 };                           // a card on a hook: 14 wide, 12 high, its top at its hook
const SOL = { w: 9, h: 9 };                              // the sun peg on a column: a 9 px square centred on the column's coloured square
const GLOBOS = { w: 24, h: 20 };                         // the balloons: 24 x 20, their foot at the left post's top
const CHIRINGA = { w: 28, h: 14 };                       // the kite lying on the paving
const LAZO = { w: 7, h: 5 };                             // a bow of the kite's tail: the spec gives its place, not its size: open point
const CAJA = { w: 14, h: 10 };                           // the señora's box of cards: the spec gives its place, not its size: open point
const SEAT_Z = .46, POST_TOP = 4.4, ARCH_HOOK = .67;     // the seat's top; the left post's top; the arch's hook above ARCH.z
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STATES = [];
for (const hora of ['manana', 'tarde', 'noche']) for (const tela of [0, 1]) STATES.push({ hora, tela });
const HOOK_COLOUR = [70, 60, 60];                        // the set's hook (rgb(70, 60, 60) in boardFace and in the arch's stem)

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor }
   kind: person (a character stands there), place (the frog's), thing (a small thing: a card, the sun peg, the balloons, the kite, the box), exit (outside the picture on purpose)
   sil: which drawing hangs there (adulto, nino, abuelaS = abuela sitting, adultoS = a grown-up sitting, coqui, perro = Canelo lying) or null for a small thing
   anchor (small things): top = its top middle on the point, bottom = its bottom middle, centre = its middle */
function defs(E, colU) {
  const B = E.BOARD, c = k => r4(colU[k - 1] + B.cw / 2), D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  for (let k = 1; k <= 7; k++) add('escalon' + k, [c(k), .37, E.STEP.h], 'place', 'coqui', 'coqui', 'the frog on the step under column ' + k + ': the step\'s top (z ' + E.STEP.h + ')', { on: 'tablero' });
  add('izq', [-3.2, .5, 0], 'person', 'adulto', 'adulto', 'the señora, left of the board');
  add('caja', [-3.35, 1.0, 0], 'thing', null, null, 'her box of cards on the paving (a ' + CAJA.w + ' x ' + CAJA.h + ' px stand-in: the spec gives no size)', { size: [CAJA.w, CAJA.h], anchor: 'bottom' });
  [.85, 1.85, 2.85].forEach((v, i) => add('asiento' + (i + 1), [E.SEAT[0], v, SEAT_Z], 'person', i ? 'adultoS' : 'abuelaS', 'adulto', 'the seat\'s place ' + (i + 1) + ' (whoever sits faces left): on its top, z ' + SEAT_Z + '; the sitting sprite hangs by the lap', { on: 'banco' }));
  [-1.9, -.75, .4, 1.55].forEach((u, i) => add('suelo' + (i + 1), [u, 2.3, 0], 'person', 'nino', 'nino', 'a place of the row on the paving in front of the board'));
  add('poste', [-2.75, 1.6, 0], 'person', 'nino', 'nino', 'Beto under the balloons');
  add('globos', [r4(B.u0 + .02), -.07, POST_TOP], 'thing', null, null, 'the balloons, tied to the top of the board\'s left post (the set\'s PZ.post at u ' + r4(B.u0 + .02) + ', v -.07, top z ' + POST_TOP + '): a ' + GLOBOS.w + ' x ' + GLOBOS.h + ' px stand-in, its foot on the post\'s top', { size: [GLOBOS.w, GLOBOS.h], anchor: 'bottom', on: 'tablero' });
  add('chiringa', [.3, 1.25, 0], 'thing', null, null, 'the kite lying on the paving (a ' + CHIRINGA.w + ' x ' + CHIRINGA.h + ' px stand-in)', { size: [CHIRINGA.w, CHIRINGA.h], anchor: 'bottom' });
  [[.9, 1.3], [1.2, 1.35], [1.5, 1.4]].forEach(([u, v], i) => add('lazo' + (i + 1), [u, v, 0], 'thing', null, null, 'the kite\'s tail: bow ' + (i + 1) + ' of 3 (a ' + LAZO.w + ' x ' + LAZO.h + ' px stand-in: the spec gives no size)', { size: [LAZO.w, LAZO.h], anchor: 'bottom' }));
  add('perro', [2.1, 1.5, 0], 'person', 'perro', 'perro', 'Canelo (lying)');
  add('ronda', [.4, 3.9, 0], 'person', 'adulto', 'adulto', 'where the one who is misled walks round');
  add('entrada', [-4.7, 2.6, 0], 'exit', 'adulto', 'adulto', 'where people come in: outside the picture on purpose (only the point)');
  for (let k = 1; k <= 7; k++) for (let j = 1; j <= 3; j++) add('gancho.' + k + '.' + j, [c(k), 0, E.HOOKS[j - 1]], 'thing', null, null, 'hook ' + j + ' (1 the top one) of column ' + k + ': a card (' + CARD.w + ' x ' + CARD.h + ') hangs with its top at the hook', { size: [CARD.w, CARD.h], anchor: 'top', on: 'tablero', hook: 1 });
  add('arco_gancho', [r4((c(6) + c(7)) / 2), 0, r4(E.ARCH.z + ARCH_HOOK)], 'thing', null, null, 'the hook at the arch\'s middle (ARCH.z + ' + ARCH_HOOK + '): a card hangs there under the hoop', { size: [CARD.w, CARD.h], anchor: 'top', on: 'tablero', hook: 1 });
  for (let k = 1; k <= 7; k++) add('sol' + k, [c(k), 0, r4((E.HEAD[0] + E.HEAD[1]) / 2)], 'thing', null, null, 'the sun peg on column ' + k + ': a ' + SOL.w + ' px square centred on its coloured square', { size: [SOL.w, SOL.h], anchor: 'centre', on: 'tablero' });
  add('muestra', [-2.95, .5, 1.6], 'thing', null, null, 'the card the señora holds up (a ' + CARD.w + ' x ' + CARD.h + ' card; its bottom middle on the point: the spec gives the point only)', { size: [CARD.w, CARD.h], anchor: 'bottom' });
  return D;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on the seat, the step, the hooks, the
   post's top are on what the set draws there), things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment),
   frog-hooks (the frog on any step covers no hook and no lowest-row card), senora-col1, arch-card, balloons, seat-heads, beto-clear, kite-canelo.
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
    const o = {}; for (const [k, v] of Object.entries(CALENDARIO.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, colU: [1, 2, 3, 4, 5, 6, 7, 8].map(k => CALENDARIO.colU(k)), scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj, SIL);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
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

/* ---------- the sprites' silhouettes: [dx, dy] of each drawn pixel from the anchor column and the anchor row (dy -1 is the feet's row) ---------- */
async function silhouettes(sp) {
  await sp.goto(BLANK);
  for (const f of ['historia/engine.js', 'historia/escenas/kit.js']) await sp.addScriptTag({ url: BASE + '/' + f });
  return sp.evaluate(() => {
    const sil = (cv, ax, ay) => {
      const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, ink = [];
      let bottom = 0;
      for (let y = 0; y < cv.height; y++) for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { ink.push([x, y]); bottom = Math.max(bottom, y + 1); }
      const row = ay == null ? bottom : ay;
      let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const [x, y] of ink) { x0 = Math.min(x0, x - ax); x1 = Math.max(x1, x - ax); y0 = Math.min(y0, y - row); y1 = Math.max(y1, y - row); }
      return { w: cv.width, h: cv.height, ax, ay: row, box: [x0, y0, x1, y1] };
    };
    const PIEL = KIT.PIEL, PELO = KIT.PELO, FAM = KIT.FAM, SENOR = { piel: PIEL.a, pelo: PELO.blanco, peinado: 'corto', ropa: RP.wood, abajo: RP.grey, bigote: 1 };
    const lap = w => 16 + 2 * (w.nino ? 7 : 11) + 3;
    return {
      adulto: sil(KIT.mkPersona(SENOR, 'idle', 0, 0), KIT.PX), nino: sil(KIT.mkPersona(FAM.hermano, 'idle', 0, 0), KIT.PX),
      abuelaS: sil(KIT.mkAbuelaS('idle', 0, 0), 17, 36), adultoS: sil(KIT.mkPersona(SENOR, 'idle', 0, 1), KIT.PX, lap(SENOR)),
      coqui: sil(mkCoqui(1, 0, 0), 16), perro: sil(KIT.mkPerro('lie', 0), 15),
    };
  });
}

/* ---------- the preview's moments: calendario-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/calendario-preview.html?nodraw=1');
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
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'top' ? sy : anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle; a small thing: its box) takes: [first, last]
const colsOf = s => s.who ? [s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1] : s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
// how many px of a spot are cut by the window at x0 (0 when whole); an exit is outside on purpose
function cutAt(s, x0) {
  if (s.kind === 'exit') return 0;
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL) {
  const E = G.E, sc = G.scene, B = E.BOARD, DEF = defs(E, G.colU);
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';                                  // what it stands on above the ground: a part of the set (the step, the seat, the board, the post) or nothing (held in the air)
    if (d.hook) o.hook = 1;
    spots[d.name] = o;
  });

  /* ---- the view: x0 so that every spot is inside the picture and the window (an exit: outside on purpose) ---- */
  const held = Object.entries(spots).filter(([, s]) => s.kind !== 'exit');
  const ext = held.map(([, s]) => colsOf(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0))) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [69, 70, 71], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 69, 70 and 71: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment is inside it (a person with his sprite whole, a small thing with its box whole; entrada is outside on purpose). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async (corners) => {
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
  const colU = G.colU, things = {};
  things.tabla = await setThing(B.u0, B.v, B.z0, r4(B.u1), B.v, B.z1, 'the whole board: its face, from the left edge to the right edge (u ' + B.u0 + ' to ' + r4(B.u1) + ') and from its foot to its top (z ' + B.z0 + ' to ' + B.z1 + '), on the plane v ' + B.v + '; a poke (the posts, the little roof and the arch are not in it: the arch is arco)');
  for (let k = 1; k <= 7; k++) things['dia' + k] = await setThing(r4(colU[k - 1]), B.v, B.z0, r4(colU[k - 1] + B.cw), B.v, E.HEAD[1], 'column ' + k + ' (' + (k <= 5 ? 'green' : 'orange') + '): from the top of its coloured square (z ' + E.HEAD[1] + ') to the board\'s foot (z ' + B.z0 + '), across its own width (' + B.cw + '); a poke');
  const a0 = r4(colU[5] + .04), a1 = r4(colU[7] - .04);
  things.arco = await setThing(a0, B.v, E.ARCH.z, a1, B.v, r4(E.ARCH.z + E.ARCH.h + .06), 'the arch of flags over columns 6 and 7: the wall the set draws for it (u ' + a0 + ' to ' + a1 + ', z ' + E.ARCH.z + ' to ' + r4(E.ARCH.z + E.ARCH.h + .06) + '); a poke');
  things.escalon = await setThing(r4(B.u0 - .1), E.STEP.v0, 0, r4(B.u1 + .1), E.STEP.v1, E.STEP.h, 'the low step along the board\'s foot (the set\'s box: u ' + r4(B.u0 - .1) + ' to ' + r4(B.u1 + .1) + ', v ' + E.STEP.v0 + ' to ' + E.STEP.v1 + ', z 0 to ' + E.STEP.h + '); a poke');
  things.banco = await setThing(r4(E.SEAT[0] - .26), E.SEAT[1], 0, r4(E.SEAT[0] + .28), E.SEAT[2], 1.12, 'the seat for three, seen from its end (PZ.seatSide: u ' + r4(E.SEAT[0] - .26) + ' to ' + r4(E.SEAT[0] + .28) + ' with its back at the right, v ' + E.SEAT[1] + ' to ' + E.SEAT[2] + ', up to its back\'s top z 1.12); a poke');
  for (const k of ['senora', 'luis', 'carmen', 'beto', 'abuela', 'tito', 'senor', 'coqui', 'perro', 'sol', 'globos', 'chiringa', 'caja']) things[k] = 'sprite';

  return {
    scene: 'calendario',
    made: 'node docs/proyecto/pixel/calendario-sheet-make.js, from calendario-set.html (window.CALENDARIO.E and colU) and the design of El calendario (the orchestrator\'s p6-spec, section calendario). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the board\'s face at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. Column k\'s middle is c(k) = colU(k) + cw / 2 (cw ' + B.cw + '): ' + [1, 2, 3, 4, 5, 6, 7].map(k => 'c' + k + ' ' + r4(colU[k - 1] + B.cw / 2)).join(', ') + '; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the paving; z ' + E.STEP.h + ': the step\'s top; z ' + SEAT_Z + ': the seat\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): a card on a hook hangs with its top row on sy and its middle on sx; the sun peg is centred on its spot; the balloons, the kite, the bows, the box of cards and the card held up at muestra have their bottom middle on the spot. scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), 41 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41) on (sx, sy); Canelo lying mkPerro(\'lie\') (30 x 22): column 15 and its bottom edge; a small thing: see spot. Whoever sits on the seat faces left: no sprite is turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      cards: 'a card (' + CARD.w + ' x ' + CARD.h + ') on gancho.k.j hangs with its top at the hook: its box is [sx - 7, sy, ' + CARD.w + ', ' + CARD.h + '] (the hooks are ' + r2((E.HOOKS[0] - E.HOOKS[1]) * 22.5) + ' px apart down the column, a column is ' + r2(B.cw * 26) + ' px wide); a card on arco_gancho hangs the same way under the hoop',
      sol: 'sol1 to sol7: a ' + SOL.w + ' px square centred on the middle of column k\'s coloured square (u c(k), z ' + r4((E.HEAD[0] + E.HEAD[1]) / 2) + '): the box [sx - 4, sy - 4, 9, 9]',
      globos: 'the balloons: a ' + GLOBOS.w + ' x ' + GLOBOS.h + ' px stand-in whose foot (its bottom middle) is at the top of the board\'s left post (u ' + r4(B.u0 + .02) + ', v -.07, z ' + POST_TOP + '): the box [sx - 12, sy - 20, 24, 20]',
    },
    setKey: {
      params: { hora: { values: ['manana', 'tarde', 'noche'], note: '69 manana (the opening and the game), 70 tarde, 71 manana for its opening and noche for its ending (the lamps lit); tarde is used by 70 only' }, tela: { values: [0, 1], note: 'the cloth over the last three columns (story 69)' } },
      key: 'hora + tela, e.g. "manana-1"',
      baked: STATES.map(s => '?hora=' + s.hora + '&tela=' + s.tela),
    },
    things,
    spots,
    groups: {
      escalones: DEF.filter(d => d.name.startsWith('escalon')).map(d => d.name), asiento: ['asiento1', 'asiento2', 'asiento3'], suelo: ['suelo1', 'suelo2', 'suelo3', 'suelo4'],
      ganchos: DEF.filter(d => d.name.startsWith('gancho.')).map(d => d.name), soles: DEF.filter(d => d.name.startsWith('sol')).map(d => d.name), lazos: ['lazo1', 'lazo2', 'lazo3'],
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p6-spec, "calendario"), given in (u, v, z); the board\'s numbers (c(k), HOOKS, ARCH, STEP, SEAT) are read from the set',
      'gancho.k.j is the spec\'s hook k, j (j 1 the top one); sol1 to sol7 are the spec\'s `sol` on column k; lazo1 to lazo3 are the three bows of the kite\'s tail; entrada is outside the picture on purpose (only its point)',
      'the spec gives no size for the bows of the kite\'s tail (' + LAZO.w + ' x ' + LAZO.h + ' used) nor for the señora\'s box of cards (' + CAJA.w + ' x ' + CAJA.h + ' used), and no anchor for the card held up at muestra (its bottom middle on the point used): open points',
      'tabla is the board\'s face (the posts, the little roof and the arch are not in it); arco is the arch\'s wall; the globos\' spot is the set\'s left post: u ' + r4(B.u0 + .02) + ', v -.07 (the spec gives only its top, z ' + POST_TOP + ')',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the board\'s roof and posts, the seat, the lamps and the trees hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El cruce\'s sheet: the upright plane through the feet (a card on a hook is the plane through its top, on the board\'s face)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, senora: .35, abuela: .35, tito: .35, senor: .35, beto: .28, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on the seat or stands on the step (z above 0) casts none: neither is ground (a shadow cast at the paving under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part), in the base state (hora manana, tela 0; the depth does not change with hora; the cloth is over columns 5 to 7)
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

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, B = E.BOARD;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, hw = who => WIDTH[who] / 2, key = (x, y) => y * G.W + x;
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
      if (nearest) { cov++; const a = L[nearest.i].at; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  // the shown pixels of layer i inside a box
  const shownIn = (L, i, box) => L[i].px.filter(p => !p[2] && inside(box, p[0], p[1])).length;
  const idxAt = (L, at) => L.findIndex(l => l.at === at);

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box; an exit is outside on purpose)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture); entrada is outside on purpose (screen ' + S.entrada.screen + ')', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, the dog 28; and his rows from the drawn silhouette; a small thing's box)
  {
    const bad = [], info = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sil = s.sprite ? SIL[s.sprite] : null;
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else if (sil) { top = sy + sil.box[1]; bottom = sy + sil.box[3]; } else { top = sy; bottom = sy; }
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      if (s.kind === 'exit') { info.push(k + ' ' + s.screen + ' (outside on purpose): ' + (pOut ? 'its point is outside the picture' : 'its point is inside the picture') + ', ' + (sx < x0 ? x0 - sx + ' px left of' : sx > x0 + 195 ? sx - x0 - 195 + ' px right of' : 'inside') + ' the window [' + x0 + ', ' + (x0 + 196) + ')'); continue; }
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
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the card of the arch\'s hook arco_gancho is box [' + S.arco_gancho.box + '], the balloons globos [' + S.globos.box + ']', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
    o.cut = bad;
  }

  // 3. the spots above the ground are on what the set draws: the seat's top (part banco), the step's top (part tablero), the hooks (a dark pixel of the hook's colour within 1 px of the spot),
  //    the balloons' foot (the post's top: part tablero within 2 px below the spot), the coloured squares (part tablero, depth the spot's)
  {
    const bad = [], lines = [], px = probes.spotsPx, near = (k, f) => (px[k] || []).filter(f);
    const surf = [];
    for (const [k, s] of Object.entries(S)) {
      if (s.on === 'banco' || (s.on === 'tablero' && s.kind === 'place')) {                                      // the seat and the step: a pixel within 2 px of the spot with the right part and the spot's depth within .1
        const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
        const ok = best && best.r.tag === tag && best.dz < .1;
        lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
        if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws: ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
      }
    }
    const hooks = Object.entries(S).filter(([k, s]) => s.hook && k !== 'arco_gancho'), missed = [];
    let farthest = 0;
    for (const [k, s] of hooks) {
      const d = near(k, r => Math.abs(r.rgb[0] - HOOK_COLOUR[0]) <= 8 && Math.abs(r.rgb[1] - HOOK_COLOUR[1]) <= 8 && Math.abs(r.rgb[2] - HOOK_COLOUR[2]) <= 8).map(r => Math.max(Math.abs(r.dx), Math.abs(r.dy))).sort((a, b) => a - b)[0];
      if (d === undefined || d > 1) missed.push(k + ' ' + s.screen + (d === undefined ? ': no pixel of the hook\'s colour within 2 px' : ': the hook\'s pixel is ' + d + ' px away')); else farthest = Math.max(farthest, d);
    }
    for (const m of missed) bad.push('hook ' + m);
    const g = near('globos', r => r.dx === 0 && r.dy >= 0 && r.dy <= 2 && r.tag === 'tablero');
    if (!g.length) bad.push('globos ' + S.globos.screen + ': no pixel of the post (part tablero) 0 to 2 px below the spot: the post\'s top is not there');
    const sols = [], solBad = [];
    for (let k = 1; k <= 7; k++) { const s = S['sol' + k], r = (px['sol' + k] || []).find(r => r.dx === 0 && r.dy === 0), want = k <= 5 ? [96, 176, 96] : [244, 150, 60], ok = r && r.tag === 'tablero' && Math.abs(r.rgb[0] - want[0]) <= 12 && Math.abs(r.rgb[1] - want[1]) <= 12 && Math.abs(r.rgb[2] - want[2]) <= 12; sols.push('sol' + k + ' ' + (r ? r.rgb : 'none')); if (!ok) solBad.push('sol' + k + ' ' + s.screen + ': the pixel under its middle is ' + (r ? 'part ' + r.tag + ' rgb ' + r.rgb : 'none') + ', not the ' + (k <= 5 ? 'green' : 'orange') + ' square'); }
    for (const m of solBad) bad.push(m);
    const o = add('spots-on-surface', bad, surf.length + ' spots on the seat and the step (' + surf.join(', ') + ') are on a surface the set draws (the seat\'s top z ' + SEAT_Z + ' part banco, the step\'s top z ' + E.STEP.h + ' part tablero: depth within .1 of the spot\'s); the ' + hooks.length + ' hook spots have a pixel of the set\'s hook within ' + farthest + ' px; the balloons\' foot is the left post\'s top; the 7 sun spots are on their column\'s coloured square', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       the sun spots read ' + sols.join('; '));
    { const a = near('arco_gancho', r => Math.abs(r.rgb[0] - HOOK_COLOUR[0]) <= 8 && Math.abs(r.rgb[1] - HOOK_COLOUR[1]) <= 8 && Math.abs(r.rgb[2] - HOOK_COLOUR[2]) <= 8);
      o.lines.push('       info, not a check (a finding about the set, calendario-set.html, which this make does not edit): arco_gancho ' + S.arco_gancho.screen + ': ' + (a.length ? 'a pixel of the hook\'s colour within 2 px' : 'no pixel of the hook\'s colour within 2 px: the set\'s arch draws the hook\'s stem only where z < top - .4 and z > ARCH.z + .66, and at the arch\'s middle top - .4 = ARCH.z + .42, so the stem is never drawn (a white flag hangs there); the spot ARCH.z + .67 is the spec\'s, and the card hangs over the flag') + '; the part there is ' + (((px.arco_gancho || []).find(r => r.dx === 0 && r.dy === 0) || {}).tag || 'none')); }
  }

  // 4. the set things' boxes are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of tabla, dia1 to dia7, arco, escalon and banco are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
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
    const nearestOf = (name, ok) => {
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

  // 6. frog-seen: the frog is never behind a grown-up or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; for (const b of M.get(key(x, y)) || []) if (b.i !== fi && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) { boxCov++; break; } }
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[specs[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 7. frog-hooks: the frog on any step (escalon1 to escalon7) covers no hook (the 3 x 3 px round each of the 21 hooks and the arch's) and no card of the lowest row (the 7 boxes of gancho.k.3)
  {
    const bad = [], lines = [], st = { hora: 'manana', tela: 0 };
    const hookBoxes = Object.entries(S).filter(([, s]) => s.hook).map(([k, s]) => [k, [s.screen[0] - 1, s.screen[1] - 1, 3, 3]]);
    const lowCards = [1, 2, 3, 4, 5, 6, 7].map(k => ['gancho.' + k + '.3', S['gancho.' + k + '.3'].box]);
    let tightest = 1e9;
    for (let k = 1; k <= 7; k++) {
      const L = await PV.layers(st, [{ at: 'escalon' + k, s: 'coqui', who: 'coqui' }]), f = L[0], shown = f.px.filter(p => !p[2]), top = Math.min(...shown.map(p => p[1]));
      const hit = [];
      for (const [n, b] of hookBoxes.concat(lowCards)) { const c = shown.filter(p => inside(b, p[0], p[1])).length; if (c) hit.push(n + ' ' + c + ' px'); }
      const gap = top - Math.max(...lowCards.map(([, b]) => b[1] + b[3] - 1)) - 1;
      tightest = Math.min(tightest, gap);
      lines.push('escalon' + k + ' ' + [f.sx, f.sy] + ': his top row ' + top + ', ' + gap + ' rows below the lowest row of cards (bottom row ' + Math.max(...lowCards.map(([, b]) => b[1] + b[3] - 1)) + ')');
      if (hit.length) bad.push('the frog at escalon' + k + ' ' + [f.sx, f.sy] + ' covers ' + hit.join(', '));
    }
    add('frog-hooks', bad, 'the frog on each of the 7 steps covers no hook and no card of the lowest row (the tightest: ' + tightest + ' rows clear): ' + lines.join('; '), ['the frog on a step covers a hook or a lowest-row card:'].concat(bad.map(b => '  ' + b)));
  }

  // 8. senora-col1: the señora at izq covers no pixel of column 1 (dia1's box), in every moment she is in
  {
    const bad = [], lines = [], b1 = T.dia1.box;
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, i = idxAt(L, 'izq'); if (i < 0) continue;
      const shown = L[i].px.filter(p => !p[2]), n = shownIn(L, i, b1), right = Math.max(...shown.map(p => p[0]));
      lines.push('m' + m + ': ' + n + ' px in column 1 [' + b1 + '] (her rightmost shown column ' + right + ', column 1 starts at ' + b1[0] + ')');
      if (n) bad.push('moment ' + m + ': the señora at izq ' + [L[i].sx, L[i].sy] + ' covers ' + n + ' px of column 1 [' + b1 + ']');
    }
    add('senora-col1', bad, 'the señora at izq covers no pixel of column 1 in the moments she is in: ' + lines.join('; '), ['the señora covers column 1:'].concat(bad.map(b => '  ' + b)));
  }

  // 9. arch-card: a card on the arch's hook is inside the picture (and the window)
  {
    const s = S.arco_gancho, b = s.box, bad = [];
    if (b[0] < 0 || b[1] < 0 || b[0] + b[2] > G.W || b[1] + b[3] > G.H) bad.push('arco_gancho ' + s.screen + ': its card box [' + b + '] is outside the ' + G.W + ' x ' + G.H + ' picture');
    if (b[0] < x0 || b[0] + b[2] > x0 + 196) bad.push('arco_gancho ' + s.screen + ': its card box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ')');
    const L = PV.inspect[3].layers, i = idxAt(L, 'arco_gancho');
    add('arch-card', bad, 'the card on arco_gancho ' + s.screen + ' is box [' + b + ']: inside the picture (' + b[1] + ' rows from its top, ' + (G.H - b[1] - b[3]) + ' from its bottom) and the window; drawn in moment 3, ' + (i < 0 ? 'not found' : L[i].out + ' of its px outside the picture'), ['the arch\'s card is outside:'].concat(bad.map(x => '  ' + x)));
  }

  // 10. balloons: whole inside the picture (and the window)
  {
    const s = S.globos, b = s.box, bad = [];
    if (b[0] < 0 || b[1] < 0 || b[0] + b[2] > G.W || b[1] + b[3] > G.H) bad.push('globos ' + s.screen + ': its box [' + b + '] is outside the ' + G.W + ' x ' + G.H + ' picture (its top row is ' + b[1] + ')');
    if (b[0] < x0 || b[0] + b[2] > x0 + 196) bad.push('globos ' + s.screen + ': its box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ')');
    const outs = [1, 2].map(m => { const L = PV.inspect[m].layers, i = idxAt(L, 'globos'); return 'm' + m + ' ' + (i < 0 ? 'not found' : L[i].out + ' px outside'); });
    add('balloons', bad, 'the balloons at globos ' + s.screen + ' (the post\'s top, u ' + s.uv[0] + ' v ' + s.uv[1] + ' z ' + s.uv[2] + ') are the box [' + b + ']: whole inside the picture (its top row ' + b[1] + ') and the window; drawn: ' + outs.join(', '), ['the balloons are cut:'].concat(bad.map(x => '  ' + x)));
  }

  // 11. seat-heads: the people on the seat are whole in the window and the head (the top 14 px of the sprite) of each is covered by nobody
  {
    const bad = [], lines = [], hidSet = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'asiento') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]), body = coverOf(L, M, i, null);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture; head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; the whole sprite: ' + body.cov + ' under a nearer sprite, ' + body.hid + ' hidden by the set');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + c.cov + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are covered by ' + whoTxt(c)); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
        if (c.hid) hidSet.push('m' + m + ' ' + l.at + ' ' + c.hid);
      }
    }
    const o = add('seat-heads', bad, 'every person on the seat is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody: ' + lines.join('; '), [bad.length + ' problem(s) with the people on the seat:'].concat(bad.map(b => '  ' + b)));
    o.lines.push('       the seat\'s three places are ' + (S.asiento2.screen[1] - S.asiento1.screen[1]) + ' px apart up-down (' + [1, 2, 3].map(i => 'asiento' + i + ' row ' + S['asiento' + i].screen[1]).join(', ') + ') and a head is ' + HEAD_ROWS + ' rows: whoever sits in front of another at the same column covers the last row(s) of the head behind (the spec\'s sprites-apart rule needs 12)');
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[cat].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
    o.lines.push('       head px hidden by the set (the seat\'s back, not a person): ' + (hidSet.join(', ') || 'none'));
  }

  // 12. beto-clear: Beto at poste covers neither the frog at escalon1 (moment 1) nor the señora's face (the top 14 px of her sprite) (moments 1 and 2)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [1, 2]) {
      const L = PV.inspect[m].layers, M = planes(L), bi = idxAt(L, 'poste'), si = idxAt(L, 'izq'), fi = L.findIndex(l => l.who === 'coqui');
      const face = coverOf(L, M, si, [bi], [0, HEAD_ROWS]), body = coverOf(L, M, si, [bi]);
      lines.push('m' + m + ': the señora\'s face (rows ' + face.top + ' to ' + (face.top + HEAD_ROWS - 1) + ') ' + face.cov + ' of ' + face.tot + ' px covered by Beto (her body ' + body.cov + ')');
      if (face.cov) { bad.push('moment ' + m + ': Beto at poste ' + [L[bi].sx, L[bi].sy] + ' covers ' + face.cov + ' px of the señora\'s face'); hints.push([m, bi, [si], [0, HEAD_ROWS], 'the señora\'s face']); }
      if (m === 1) {
        const c = coverOf(L, M, fi, [bi]);
        lines.push('m1: the frog at ' + L[fi].at + ' ' + [L[fi].sx, L[fi].sy] + ': ' + c.cov + ' of his ' + c.tot + ' px covered by Beto (Beto\'s box ' + [L[bi].sx - 12, L[bi].sx + 11] + ' across, the frog\'s ' + [L[fi].sx - 16, L[fi].sx + 15] + '; Beto\'s top row ' + Math.min(...L[bi].px.map(p => p[1])) + ', the frog\'s bottom row ' + Math.max(...L[fi].px.map(p => p[1])) + ')');
        if (c.cov) { bad.push('moment 1: Beto at poste ' + [L[bi].sx, L[bi].sy] + ' covers ' + c.cov + ' of the frog\'s ' + c.tot + ' px at escalon1 ' + [L[fi].sx, L[fi].sy]); hints.push([1, bi, [fi], null, 'the frog']); }
      }
    }
    const o = add('beto-clear', bad, 'Beto at poste covers neither the frog at escalon1 nor the señora\'s face: ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, bi, others, rows, what] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, bi, others, rows); o.lines.push('       nearest passing, moment ' + m + ' poste ' + S.poste.uv + ' (' + what + '): ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S.poste.uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 13. kite-canelo: the kite, its bows and Canelo cover nobody on the step (the frog at escalon6 and escalon7, moments 3 and 4)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui');
      const by = ['chiringa', 'lazo1', 'lazo2', 'lazo3', 'perro'].map(a => idxAt(L, a)), c = coverOf(L, M, fi, by);
      const frogBottom = Math.max(...L[fi].px.map(p => p[1])), tops = by.map(i => [L[i].at, Math.min(...L[i].px.map(p => p[1]))]);
      lines.push('m' + m + ': the frog at ' + L[fi].at + ' ' + [L[fi].sx, L[fi].sy] + ' (his bottom row ' + frogBottom + '): ' + c.cov + ' of his ' + c.tot + ' px covered (' + tops.map(t => t[0] + ' top row ' + t[1]).join(', ') + ')');
      if (c.cov) { bad.push('moment ' + m + ': ' + c.cov + ' px of the frog at ' + L[fi].at + ' are covered by ' + whoTxt(c)); for (const i of by) if (coverOf(L, M, fi, [i]).cov) hints.push([m, i, [fi], null, L[i].at]); }
    }
    const o = add('kite-canelo', bad, 'the kite, its three bows and Canelo cover nobody on the step: ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, others, rows, what] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, i, others, rows); o.lines.push('       nearest passing, moment ' + m + ' ' + what + ' ' + S[what].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[what].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
  }

  // info: how the stand-ins touch the señora (not checks of the spec)
  {
    const lines = [];
    for (const m of [1, 2]) {
      const L = PV.inspect[m].layers, M = planes(L), si = idxAt(L, 'izq'), ci = idxAt(L, 'caja'), mi = idxAt(L, 'muestra');
      const feet = coverOf(L, M, si, [ci]), face = mi < 0 ? null : coverOf(L, M, si, [mi], [0, HEAD_ROWS]), body = mi < 0 ? null : coverOf(L, M, si, [mi]);
      lines.push('m' + m + ': her box at caja covers ' + feet.cov + ' px of the señora' + (face ? '; the card at muestra covers ' + face.cov + ' px of her face (top ' + HEAD_ROWS + ' rows) and ' + body.cov + ' of her sprite in all' : ''));
    }
    // where the card at muestra hangs from its point (the spec gives the point only): how many px of the señora's face (her top 14 rows) the card covers, by anchor
    const alt = [];
    for (const [name, px] of [['bottom middle on the point (used)', [0, 0]], ['middle of the card on the point', [0, 6]], ['bottom left corner on the point', [7, 0]], ['middle of the left edge on the point', [7, 6]]]) {
      const L = await PV.layers({ hora: 'manana', tela: 1 }, [{ at: 'izq', s: 'senora', who: 'adulto' }, { at: 'muestra', s: 'held:cafe', px, dd: .05 }]), sn = L[0], cd = new Set(L[1].px.filter(q => !q[2]).map(q => key(q[0], q[1]))), top = Math.min(...sn.px.map(q => q[1]));
      alt.push(name + ': ' + sn.px.filter(q => !q[2] && q[1] < top + HEAD_ROWS && cd.has(key(q[0], q[1]))).length + ' px of her face, ' + sn.px.filter(q => !q[2] && cd.has(key(q[0], q[1]))).length + ' of her sprite');
    }
    OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check. ' + lines.join('; '), '       the card at muestra, by where it hangs from the point (open point): ' + alt.join('; ')] });
  }
  return OUTS;
}
