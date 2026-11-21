#!/usr/bin/env node
'use strict';
/* El cielo's sheet (place 7, La playa, scene 4): writes docs/proyecto/pixel/cielo-sheet.json from cielo-set.html and the design (the orchestrator's p7-spec, section "cielo"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/cielo-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 152 here). The deck, the beam, the table, the chair, the blanket, the palm and the sky's things
   are read from the set (window.CIELO.E), never typed again from the design.
   The set has a palm whose fronds sway: the preview takes the depth and the pixels after frame(0) (window.DEPTH.live()), so a frond in front of a spot counts as covering it.
   It loads the set in headless Chrome (cielo-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from today's makers (historia/engine.js, historia/escenas/kit.js) loaded in a second, empty page. The checks that say "covers" or "shows"
   read the PREVIEW's moments (cielo-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is
   written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CIELO_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'cielo-sheet.json');
const BASE = process.env.CIELO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/cielo-set.html';
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

// the numbers of the design (p7-spec: the rules for every sheet, and "cielo")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const FOOT_GAP = 4;                                      // every spot's feet are above the picture's last row by this many px or more
const SZ = {
  radio: [12, 9], vela: [6, 10], velaStep: 7, tapaPuesta: [26, 18], tapa: [18, 16], chal: [10, 8], cuerdaW: 10, bandeja: [20, 10],
  sombrillaShut: [8, 44], canopy: [64, 16], canopyFoot: 44, chiringa: [20, 12], bola: [9, 9], telescopio: [14, 22],
  nube: [30, 22], estrella: [18, 18], visor: [186, 104, 28, 28],
};
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STATES = [];
for (const cielo of ['azul', 'nublado', 'gris', 'rosa', 'noche']) for (const toldo of ['arriba', 'abajo']) STATES.push({ cielo, toldo });
const USED = ['azul-arriba', 'nublado-arriba', 'gris-arriba', 'gris-abajo', 'noche-arriba', 'rosa-arriba'];   // the sets the six moments use

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor }
   kind: person (a character stands there), place (the frog's), thing (a small thing: the radio, the candles, the tray...), exit (outside the picture on purpose), overlay (on the screen)
   sil: which drawing hangs there (nino = Luis and Carmen, abuelaS = abuela sitting, coqui) or null for a small thing
   anchor (small things): bottom = its bottom middle on the point, centre = its middle */
function defs(E) {
  const D = E.DECK, T = E.TABLE, C = E.CHAIR, TOP = r4(D.h + .72), SEAT = r4(D.h + .44), L = [];
  const add = (name, uvz, kind, sil, who, what, more) => L.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  add('mecedora', [C[0], C[1], SEAT], 'person', 'abuelaS', 'adulto', 'abuela in her rocking chair: on the seat\'s top (z DECK.h + .44 = ' + SEAT + '); she sits, hung by the lap', { on: 'porche' });
  add('mesa1', [-2.3, .8, D.h], 'person', 'nino', 'nino', 'Luis, behind the table, on the deck\'s floor (z ' + D.h + ')', { on: 'porche' });
  add('mesa2', [-.6, 1.9, 0], 'person', 'nino', 'nino', 'Carmen, on the sand beside the deck');
  add('piso', [-2.65, 2.35, D.h], 'place', 'coqui', 'coqui', 'the frog on the deck\'s floor (z ' + D.h + ')', { on: 'porche' });
  add('salida', [-4.8, 1.5, 0], 'exit', null, 'adulto', 'where abuela goes off: outside the picture on purpose (only the point)');
  add('radio', [r4(T[0] - .2), r4(T[1] - .1), TOP], 'thing', null, null, 'the radio on the table (z = its top ' + TOP + '): a ' + SZ.radio.join(' x ') + ' px stand-in, its bottom middle on the point', { size: SZ.radio, anchor: 'bottom', on: 'porche' });
  add('velas', [r4(T[0] + .05), r4(T[1] + .1), TOP], 'thing', null, null, 'the three candles in jars on the table: the middle one on the point, the others ' + SZ.velaStep + ' px either side (centre to centre), each ' + SZ.vela.join(' x ') + ' px, bottom edge on the point', { size: [2 * SZ.velaStep + SZ.vela[0], SZ.vela[1]], anchor: 'bottom', on: 'porche' });
  add('tapa_puesta', [r4(T[0] + .05), r4(T[1] + .1), TOP], 'thing', null, null, 'the glass cover over the candles (same point as velas): ' + SZ.tapaPuesta.join(' x ') + ' px, bottom middle on the point', { size: SZ.tapaPuesta, anchor: 'bottom', on: 'porche' });
  add('tapa', [-1.6, 2.35, D.h], 'thing', null, null, 'the glass cover standing on the deck\'s floor: ' + SZ.tapa.join(' x ') + ' px, bottom middle on the point', { size: SZ.tapa, anchor: 'bottom', on: 'porche' });
  add('chal', [r4(C[0] + .32), C[1], r4(D.h + .75)], 'thing', null, null, 'the shawl on the chair\'s arm (z DECK.h + .75): ' + SZ.chal.join(' x ') + ' px, bottom middle on the point (open point: the spec gives the size, not the anchor; the set draws no arm there)', { size: SZ.chal, anchor: 'bottom', on: 'porche' });
  add('cuerda', [r4(D.u1 - .115), r4(D.v0 + .12), 1.2], 'thing', null, null, 'the blind\'s cord by the right post (the set\'s wall at u ' + r4(D.u1 - .13) + ' to ' + r4(D.u1 - .1) + ', v ' + r4(D.v0 + .12) + '): a box ' + SZ.cuerdaW + ' px wide from z 1.2 to z BEAM - .2 = ' + r4(E.BEAM - .2), { cord: true, on: 'porche' });
  add('manta', [.6, 3.1, 0], 'place', 'coqui', 'coqui', 'the frog on the blanket');
  add('bandeja', [1.7, 3.1, 0], 'thing', null, null, 'the tray of three glasses on the sand: ' + SZ.bandeja.join(' x ') + ' px, bottom middle on the point', { size: SZ.bandeja, anchor: 'bottom' });
  add('sombrilla', [1.2, 2.45, 0], 'thing', null, null, 'the umbrella\'s foot on the sand: shut, ' + SZ.sombrillaShut.join(' x ') + ' px (bottom middle on the point); open, a canopy ' + SZ.canopy.join(' x ') + ' px whose foot is ' + SZ.canopyFoot + ' px above the sand', { size: SZ.sombrillaShut, anchor: 'bottom', umbrella: true });
  add('chiringa_pie', [3.15, 2.2, 0], 'person', 'nino', 'nino', 'Luis with the kite');
  add('chiringa', [3.1, 3.4, 0], 'thing', null, null, 'the kite on the sand: ' + SZ.chiringa.join(' x ') + ' px, bottom middle on the point', { size: SZ.chiringa, anchor: 'bottom' });
  add('bola1', [-1.0, 4.4, 0], 'person', 'nino', 'nino', 'Carmen with the ball (a place of the ball game)');
  add('bola2', [3.0, 4.45, 0], 'person', 'nino', 'nino', 'the other place of the ball game (a child: the spec names no moment and no person here)');
  add('bola', [.5, 4.55, 0], 'thing', null, null, 'the ball on the sand: ' + SZ.bola.join(' x ') + ' px, bottom middle on the point', { size: SZ.bola, anchor: 'bottom' });
  add('telescopio', [1.4, 3.0, 0], 'thing', null, null, 'the telescope\'s stand on the sand: ' + SZ.telescopio.join(' x ') + ' px, bottom middle on the point', { size: SZ.telescopio, anchor: 'bottom' });
  add('coqui.telescopio', [1.4, 3.0, .9], 'place', 'coqui', 'coqui', 'the frog on the telescope (z .9, in the air over the stand: on a sprite, not on the set)', { on: 'telescopio' });
  add('luis.tel', [.2, 3.3, 0], 'person', 'nino', 'nino', 'Luis at the telescope');
  add('carmen.tel', [2.6, 3.3, 0], 'person', 'nino', 'nino', 'Carmen at the telescope');
  return L;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0, spots-in-view, spots-on-surface, things-in-view, sprites-apart, frog-seen, on-seat, abuela-head, sky-clear, candles-clear, frog-piso, umbrella-canopy, feet-above-foot, visor.
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
    const o = {}; for (const [k, v] of Object.entries(CIELO.E)) if (typeof v !== 'function') o[k] = v;
    let hz = 1e9; for (let i = 0; i < W * H; i++) if (ground[i]) hz = Math.min(hz, Math.floor(i / W));
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY, horizon: hz };
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
    const FAM = KIT.FAM;
    return { nino: sil(KIT.mkPersona(FAM.hermano, 'idle', 0, 0), KIT.PX), abuelaS: sil(KIT.mkAbuelaS('idle', 0, 0), 17, 36), coqui: sil(mkCoqui(1, 0, 0), 16), perro: sil(KIT.mkPerro('lie', 0), 15) };
  });
}

/* ---------- the preview's moments: cielo-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden: 1 by the set, 2 by a frond only, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/cielo-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.boxes = (st, boxes) => p.evaluate(a => window.PREVIEW.boxes(a.st, a.boxes), { st, boxes });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
// every box a spot's thing can take (the umbrella: shut and open)
const boxesOf = s => [s.box].concat(s.open ? [s.open.box] : []).filter(Boolean);
// what a spot takes of the picture: columns [first, last] and rows [top, bottom] (a person: his sprite box, the feet's spot in the middle, joined with the drawn silhouette; a small thing: its box or boxes; an overlay: its box)
function extentOf(s, SIL) {
  const [sx, sy] = s.screen;
  if (s.who && s.sprite) { const sil = SIL[s.sprite]; return { cols: [Math.min(sx - WIDTH[s.who] / 2, sx + sil.box[0]), Math.max(sx + WIDTH[s.who] / 2 - 1, sx + sil.box[2])], rows: [sy + sil.box[1], sy + sil.box[3]] }; }
  if (s.who) return { cols: [sx - WIDTH[s.who] / 2, sx + WIDTH[s.who] / 2 - 1], rows: [sy, sy] };
  const bs = boxesOf(s);
  if (bs.length) return { cols: [Math.min(...bs.map(b => b[0])), Math.max(...bs.map(b => b[0] + b[2] - 1))], rows: [Math.min(...bs.map(b => b[1])), Math.max(...bs.map(b => b[1] + b[3] - 1))] };
  return { cols: [sx, sx], rows: [sy, sy] };
}
// how many px of a spot are cut by the window at x0 (0 when whole); an exit is outside on purpose
function cutAt(s, x0, SIL) {
  if (s.kind === 'exit') return 0;
  const [a, b] = extentOf(s, SIL).cols;
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL) {
  const E = G.E, sc = G.scene, DEF = defs(E), D = E.DECK;
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.name === 'velas') { o.parts = [-1, 0, 1].map(k => [sx - Math.floor(SZ.vela[0] / 2) + k * SZ.velaStep, sy - SZ.vela[1], SZ.vela[0], SZ.vela[1]]); }
    if (d.umbrella) o.open = { box: [sx - 32, sy - SZ.canopyFoot - SZ.canopy[1], SZ.canopy[0], SZ.canopy[1]], foot: SZ.canopyFoot, what: 'open: the canopy ' + SZ.canopy.join(' x ') + ' px, its foot (lower edge) ' + SZ.canopyFoot + ' px above the sand; the pole runs from it to the sand' };
    if (d.cord) {                                                                                         // a box SZ.cuerdaW wide from z 1.2 (the point) to z BEAM - .2, at the cord
      const y0 = Math.floor(G.OY + (d.uvz[1] * .5 - (E.BEAM - .2) * COS) * G.S + 1e-9), y1 = Math.ceil(G.OY + (d.uvz[1] * .5 - 1.2 * COS) * G.S - 1e-9);
      o.box = [sx - Math.floor(SZ.cuerdaW / 2), y0, SZ.cuerdaW, y1 - y0];
      o.top = r4(E.BEAM - .2); o.anchor = 'box';
    }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';                                  // what it stands on above the ground: a part of the set (the deck, the chair, the table) or a sprite (the telescope)
    spots[d.name] = o;
  });
  // the round picture: on the screen, not in the world
  spots.visor = { screen: [SZ.visor[0] + SZ.visor[2] / 2, SZ.visor[1] + SZ.visor[3] / 2], box: SZ.visor.slice(), kind: 'overlay', overlay: true, view: 'wide', anchor: 'screen', what: 'the round picture beside the telescope (story 83): a 28 px disc whose box is [' + SZ.visor + '] in screen pixels (not a world point: drawn over everything)' };

  /* ---- the view: x0 22 (the window centred on the picture) unless a spot is cut, then the x0 that holds them all ---- */
  const held = Object.entries(spots).filter(([, s]) => s.kind !== 'exit');
  const ext = held.map(([, s]) => extentOf(s, SIL).cols), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0, SIL))) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x, SIL), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [81, 82, 83], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 81, 82 and 83: the 196 x 216 window over the 240 x 216 picture. The spec: x0 ' + centred + ' (the window centred on the picture) unless a spot is cut. ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold every spot (a person with his sprite whole, a small thing with its box; salida is outside on purpose); x0 ' + x0 + ' is the one nearest ' + centred : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by], q };
  };
  const K = E.SKY, things = {};
  things.cielo = { set: true, box: [0, 0, G.W, G.horizon], what: 'the sky above the horizon: the whole width of the picture, from its top to the sea\'s line (the first row the set draws ground on is row ' + G.horizon + '). Screen pixels: the sky is not in the world. The sky\'s picture changes with the state (cielo); the box does not' };
  things.nube = { set: true, screen: K.cloud.slice(), box: [K.cloud[0] - SZ.nube[0] / 2, K.cloud[1] - SZ.nube[1] / 2, SZ.nube[0], SZ.nube[1]], what: 'the small cloud of the blue sky: a ' + SZ.nube.join(' x ') + ' px box centred on SKY.cloud [' + K.cloud + ']' };
  things.luna = { set: true, screen: [K.moon[0], K.moon[1]], box: [K.moon[0] - K.moon[2], K.moon[1] - K.moon[2], 2 * K.moon[2], 2 * K.moon[2]], what: 'the moon of the night sky: the box of its disc (SKY.moon [' + K.moon + ']: centre and radius)' };
  things.estrella = { set: true, screen: K.star.slice(), box: [K.star[0] - SZ.estrella[0] / 2, K.star[1] - SZ.estrella[1] / 2, SZ.estrella[0], SZ.estrella[1]], what: 'the big four-pointed star of the night sky: a ' + SZ.estrella.join(' x ') + ' px box centred on SKY.star [' + K.star + ']' };
  {
    const c = spots.cuerda, cu = c.uv[0], cv = c.uv[1], corners = [];
    for (const z of [c.uv[2], c.top]) for (const [u, v] of [[cu - .015, cv], [cu + .015, cv]]) corners.push([u, v, z]);
    const q = (await boxOfCorners(corners)).q;
    things.cuerda = { set: true, uv: W4([cu - .015, cv, c.uv[2], cu + .015, cv, c.top]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), c.uv[2], Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), c.top]), box: c.box.slice(),
      what: 'the blind\'s cord: the set draws it as a wall at u ' + r4(D.u1 - .13) + ' to ' + r4(D.u1 - .1) + ', v ' + r4(D.v0 + .12) + ', z 1.2 to ' + c.top + '; the touch box is ' + SZ.cuerdaW + ' px wide round it (the spec), from z 1.2 to z BEAM - .2' };
  }
  for (const k of ['sombrilla', 'chiringa', 'bola', 'chal', 'tapa', 'radio', 'velas', 'bandeja', 'telescopio', 'abuela', 'luis', 'carmen', 'coqui', 'perro']) things[k] = 'sprite';

  return {
    scene: 'cielo',
    made: 'node docs/proyecto/pixel/cielo-sheet-make.js, from cielo-set.html (window.CIELO.E) and the design of El cielo (the orchestrator\'s p7-spec, section cielo). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), z up; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + '; its last row (' + (G.H - 1) + ') is at v 4.9',
      spot: 'a spot is a world point of the feet (z 0: the sand; z ' + D.h + ': the deck\'s floor; z ' + r4(D.h + .44) + ': the rocking chair\'s seat; z ' + r4(D.h + .72) + ': the table\'s top; z .9 over the telescope\'s foot: the frog on it) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): its bottom middle is on the spot (bottom), except the cord (a box from z 1.2 to z BEAM - .2 round the set\'s cord) and the round picture (a box on the screen). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 41 rows drawn standing for a child (Luis and Carmen); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her head\'s middle) and row 36 (her lap) on (sx, sy), the spot being the seat; she faces right and her knees run to column 17 + 25; her head is the top 14 rows (rows -36 to -23 from the lap); a small thing: see spot. Nobody is drawn turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      cord: 'cuerda: a box ' + SZ.cuerdaW + ' px wide from z 1.2 to z BEAM - .2 = ' + r4(E.BEAM - .2) + ' at the set\'s cord (u ' + spots.cuerda.uv[0] + ', v ' + spots.cuerda.uv[1] + ': the middle of the wall the set draws, ' + r4(D.u1 - .13) + ' to ' + r4(D.u1 - .1) + '; the right post is at u ' + r4(D.u1 - .08) + '): the box [' + spots.cuerda.box + ']',
      sky: 'the sky is screen space (the set\'s skyOf): E.SKY gives the sun [x, y, r], the small cloud [x, y], the moon [x, y, r], the big star [x, y] and the long cloud [x, y] in picture pixels; they do not move with the state (the sun and the small cloud are drawn by cielo azul, the moon, the star and the long cloud by cielo noche)',
    },
    setKey: {
      params: { cielo: { values: ['azul', 'nublado', 'gris', 'rosa', 'noche'], note: '81 azul (opening) and nublado (game); 82 gris (opening and game), rosa (ending); 83 noche' }, toldo: { values: ['arriba', 'abajo'], note: 'the blind: rolled up on its beam, or down behind the table (82 game: abajo; every other moment: arriba)' } },
      key: 'cielo + toldo, e.g. "gris-abajo"',
      used: USED,
      baked: STATES.map(s => '?cielo=' + s.cielo + '&toldo=' + s.toldo),
    },
    sky: { horizon: G.horizon, sun: { screen: [K.sun[0], K.sun[1]], r: K.sun[2], box: [K.sun[0] - K.sun[2], K.sun[1] - K.sun[2], 2 * K.sun[2], 2 * K.sun[2]], inSky: 'azul' }, cloud: { screen: K.cloud.slice(), box: things.nube.box, inSky: 'azul' }, moon: { screen: [K.moon[0], K.moon[1]], r: K.moon[2], box: things.luna.box, inSky: 'noche' }, star: { screen: K.star.slice(), box: things.estrella.box, inSky: 'noche' }, long: { screen: K.long.slice(), inSky: 'noche' } },
    things,
    spots,
    groups: { sitio: ['mecedora', 'mesa1', 'mesa2', 'piso', 'manta', 'chiringa_pie', 'bola1', 'bola2', 'luis.tel', 'carmen.tel', 'coqui.telescopio'], mesa: ['radio', 'velas', 'tapa_puesta'], velas: ['vela1', 'vela2', 'vela3'] },
    notes: [
      'every number of a spot is the orchestrator\'s (the p7-spec, "cielo"), given in (u, v, z); the deck, the beam, the table, the chair, the blanket and the sky\'s things are read from the set (window.CIELO.E)',
      'velas is the middle of the three candles (6 x 10 each, 7 px centre to centre): the spot\'s box is the three together [sx - 10, sy - 10, 20, 10], parts the three boxes; tapa_puesta is at the same point as velas; tapa is the same cover standing on the floor',
      'the cord: the spec says "at the post"; the set draws the cord as a wall at u ' + r4(D.u1 - .13) + ' to ' + r4(D.u1 - .1) + ', v ' + r4(D.v0 + .12) + ', so the box is centred on that wall (the right post is .035 to the right of it: the box covers both)',
      'sombrilla: box is the umbrella shut (8 x 44, bottom middle on the point); open.box is the canopy (64 x 16, foot 44 px above the sand); the pole of the open one runs from the canopy to the sand',
      'visor is a screen box, not a world point: it is drawn over everything; its depth is the nearest of all',
      'chal: the spec gives the shawl\'s size and its point (CHAIR.u + .32, CHAIR.v, DECK.h + .75) but not its anchor: the bottom middle is on the point (open point); the set draws no arm on the chair: the point is in the air .31 above the seat\'s right edge',
      'bola2 and bola1 are the two places of the ball game; no moment of the spec puts anybody at bola2; it is a child\'s place here (open point). In moment 1 the ball is "with" Carmen: drawn at her feet 15 px to her right (open point: the spec gives no spot for it)',
      'the views\'s x0: x0 22 when every spot is inside the window (a person with his sprite whole, a small thing with its box); salida is outside on purpose (check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel (or frond) that is nearer the camera than the character\'s feet (depth test against the set\'s depth after frame(0), with the feet\'s depth plus 0.3): the deck\'s posts, the beam and the table hide whoever is behind them; the palm\'s fronds hide whoever is under them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where Z[r * 240 + x] > depth(r) + bias. Z is window.DEPTH.live() of the set page after frame(0) (the baked depth, window.DEPTH.z, with the swaying fronds drawn at t 0); the baked depth alone does not see the fronds. The same rule as El cruce\'s sheet: the upright plane through the feet',
      fronds: 'the palm\'s fronds sway: frame(t) draws them every tick (8 steps a second). The sheet and its checks take the depth and the pixels after frame(0); a frond that covers a spot at frame 0 counts as covering it. A frond at another moment of the sway can cover a little more or a little less',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on the chair, stands on the deck or sits on the telescope (z above 0) casts none: none of those is ground (a shadow cast at the sand under them would show in front of them)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part), in the base state (the depth does not change with the sky; the blind changes it behind the table)
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
  }, Object.fromEntries(Object.entries(sheet.spots).filter(([, s]) => !s.overlay).map(([k, s]) => [k, { screen: s.screen }])));
  // the highest row the set draws anything on (baked), and the highest row of a frond at frame 0 (DEPTH.live() against the baked depth)
  const tops = await page.evaluate(() => { frame(0); const live = DEPTH.live(); let a = 1e9, b = 1e9; const low = new Array(W).fill(-1); for (let i = 0; i < W * H; i++) { const y = Math.floor(i / W), x = i % W; if (bakedZ[i] > -1e8) a = Math.min(a, y); if (live[i] !== bakedZ[i]) { b = Math.min(b, y); low[x] = Math.max(low[x], y); } } return [a, b, low]; });
  return { spotsPx, topSet: tops[0], topLive: tops[1], frondLow: tops[2] };
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, D = E.DECK;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  // per pixel the shown pixels of every layer of a moment: key -> [{plane, i}]
  const planes = L => { const M = new Map(); L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]); if (!M.has(k)) M.set(k, []); M.get(k).push({ plane: p[3], i }); } }); return M; };
  // the pixels of layer t (its top `rows` rows only when given: [from, to)) covered by a nearer shown pixel of the layers `by` (indices; null: any other); who covers them
  // hid: hidden by the set's baked pixels; fron: hidden by a frond only
  const coverOf = (L, M, t, by, rows) => {
    const l = L[t], top = Math.min(...l.px.map(p => p[1])); let tot = 0, hid = 0, fron = 0, cov = 0; const who = {};
    for (const p of l.px) {
      if (rows && !(p[1] >= top + rows[0] && p[1] < top + rows[1])) continue;
      tot++; if (p[2] === 1) { hid++; continue; } if (p[2] === 2) { fron++; continue; }
      let nearest = null;
      for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== t && (!by || by.includes(b.i)) && b.plane > p[3] + EPS && (!nearest || b.plane > nearest.plane)) nearest = b;
      if (nearest) { cov++; const a = L[nearest.i].id; who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, fron, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  const idxAt = (L, id) => L.findIndex(l => l.id === id);
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box; an exit is outside on purpose); x0 22 unless a spot is cut
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0, SIL)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const at22 = v.holds.map(k => [k, cutAt(S[k], 22, SIL)]).filter(o => o[1]);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + '; at x0 22: ' + (at22.length ? at22.map(a => a[0] + ' cut by ' + a[1] + ' px').join(', ') : 'no spot is cut') + '; salida is outside on purpose (screen ' + S.salida.screen + ')', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, joined with his drawn silhouette; and his rows from the silhouette; a small thing's box, the open umbrella's too)
  {
    const bad = [], info = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, e = extentOf(s, SIL), [a, b] = e.cols, [top, bottom] = e.rows;
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      if (s.kind === 'exit') { info.push(k + ' ' + s.screen + ' (outside on purpose): ' + (pOut ? 'its point is outside the picture' : 'its point is inside the picture') + ', ' + (sx < x0 ? x0 - sx + ' px left of' : sx > x0 + 195 ? sx - x0 - 195 + ' px right of' : 'inside') + ' the window [' + x0 + ', ' + (x0 + 196) + ')'); continue; }
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + boxesOf(s).join('] [') + ']') + ' is cut ' + (cut.concat([picL && 'by the picture\'s left edge ' + picL, picR && 'by the picture\'s right edge ' + picR].filter(Boolean))).join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k]; if (!s.uv) continue;
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = JSON.parse(JSON.stringify(s)); t.screen = [sx, s.screen[1]]; if (t.box) t.box[0] += sx - s.screen[0]; if (t.open) t.open.box[0] += sx - s.screen[0]; const c = extentOf(t, SIL).cols; if (!cutAt(t, x0, SIL) && c[0] >= 0 && c[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box, the open umbrella\'s canopy, the round picture) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + Math.min(...names.map(k => extentOf(S[k], SIL).cols[0])) + ' (' + names.reduce((a, k) => extentOf(S[k], SIL).cols[0] < extentOf(S[a], SIL).cols[0] ? k : a, names[0]) + '), the rightmost ' + Math.max(...names.map(k => extentOf(S[k], SIL).cols[1])) + ' (' + names.reduce((a, k) => extentOf(S[k], SIL).cols[1] > extentOf(S[a], SIL).cols[1] ? k : a, names[0]) + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
    o.cut = bad;
  }

  // 3. the spots above the ground are on what the set draws: the chair's seat, the deck's floor, the table's top. Two readings: where the set puts that surface (E: the seat box, the deck's rectangle, the table's disc, at the spot's z),
  //    and the set's own pixel at the spot (part porche, depth within .1 of the spot's); a pixel with a nearer depth is a thing of the set in front of the spot (the table in front of whoever stands behind it): the spot is hidden there, not off its surface.
  //    The cord is part porche at its foot; the frog on the telescope is on a sprite; the shawl's point has no arm under it (a finding, not a check)
  {
    const bad = [], lines = [], px = probes.spotsPx, finding = [], C = E.CHAIR, T0 = E.TABLE, eq = (a, b) => Math.abs(a - b) < 1e-6;
    const geo = (k, s) => {
      const [u, v, z] = s.uv;
      if (k === 'mecedora') return Math.abs(u - C[0]) <= .3 && Math.abs(v - C[1]) <= .26 && eq(z, r4(D.h + .44)) ? 'the seat\'s top (u ' + r4(C[0] - .3) + ' to ' + r4(C[0] + .3) + ', v ' + r4(C[1] - .26) + ' to ' + r4(C[1] + .26) + ', z ' + r4(D.h + .44) + ')' : null;
      if (['radio', 'velas', 'tapa_puesta'].includes(k)) return Math.hypot(u - T0[0], v - T0[1]) <= .5 && eq(z, r4(D.h + .72)) ? 'the table\'s top (' + r2(Math.hypot(u - T0[0], v - T0[1])) + ' from its middle, radius .5, z ' + r4(D.h + .72) + ')' : null;
      if (['mesa1', 'piso', 'tapa'].includes(k)) return u >= D.u0 && u <= D.u1 && v >= D.v0 && v <= D.v1 && eq(z, D.h) ? 'the deck\'s floor (u ' + D.u0 + ' to ' + D.u1 + ', v ' + D.v0 + ' to ' + D.v1 + ', z ' + D.h + ')' : null;
      return null;
    };
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground' || s.overlay) continue;
      if (s.on === 'telescopio') { lines.push(k + ' z ' + s.uv[2] + ': on the telescope\'s stand (a sprite: the stand\'s top row is ' + (S.telescopio.box[1]) + ', the frog\'s feet row ' + s.screen[1] + ')'); continue; }
      const cord = !!s.top, near = (px[k] || []).filter(r => Math.abs(r.dx) <= (cord ? 2 : 1) && r.dy >= (cord ? -2 : -1) && r.dy <= (cord ? 0 : 1)).map(r => ({ r, dz: r.z - s.depth })).sort((a, b) => Math.abs(a.dz) - Math.abs(b.dz))[0];
      const seen = near && near.r.tag === 'porche' && Math.abs(near.dz) < .1, hidden = near && near.dz >= .1;
      if (k === 'chal') { finding.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ': ' + (seen ? 'part porche at depth ' + r2(near.r.z) : 'the set draws nothing of the deck there' + (near ? ' (the nearest pixel is part ' + near.r.tag + ' at depth ' + r2(near.r.z) + ', the spot\'s is ' + r2(s.depth) + ')' : ''))); continue; }
      const g = cord ? 'the cord (the wall the set draws at u ' + r4(D.u1 - .13) + ' to ' + r4(D.u1 - .1) + ')' : geo(k, s);
      lines.push(k + ' z ' + s.uv[2] + ': ' + (g ? 'inside ' + g + '; ' : 'NOT on a set surface; ') + 'the set\'s pixel ' + (near ? 'part ' + near.r.tag + ', depth ' + r2(near.r.z) + ' against the spot\'s ' + r2(s.depth) + (seen ? ' (' + r2(Math.abs(near.dz)) + ')' : hidden ? ': nearer: something of the set is in front of the spot' + (k === 'mesa1' ? ' (the table, which he stands behind)' : '') : ': farther') : 'none'));
      if (!g) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + s.uv + ')');
      else if (!seen && !hidden) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ': the set\'s pixel there is ' + (near ? 'part ' + near.r.tag + ' at depth ' + r2(near.r.z) + ', the spot\'s is ' + r2(s.depth) : 'none'));
    }
    const o = add('spots-on-surface', bad, lines.length + ' spots above the ground are on a surface the set draws (the seat top z ' + r4(D.h + .44) + ', the deck floor z ' + D.h + ', the table top z ' + r4(D.h + .72) + ', the cord at z 1.2) or on the telescope\'s stand; the set\'s own pixel at each (part porche, depth within .1 of the spot\'s) agrees, but at mesa1, where the table is in front of him', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    for (const l of finding) o.lines.push('       finding, not a check: ' + l + ' (the chair has no arm)');
  }

  // 4. the set things' boxes are inside the picture and the window (the sky's box is the whole width: inside the picture only)
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      const win = k !== 'cielo';
      if ((win && (l > 0 || r > 0)) || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the ' + (win ? 'window [' + x0 + ', ' + (x0 + 196) + ') or the ' : '') + 'picture' + (l > 0 && win ? ' by ' + l + ' left' : '') + (r > 0 && win ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of ' + lines.join(', ') + ' are inside the picture, and (all but the sky, which is the picture\'s whole width) inside the window [' + x0 + ', ' + (x0 + 196) + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
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
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.id + ' ~ ' + h.b.id + ': ' + h.a.id + ' ' + S[h.a.id].uv + ': ' + nearestOf(h.a.id, pass(h.b, h.half)) + '; or ' + h.b.id + ' ' + S[h.b.id].uv + ': ' + nearestOf(h.b.id, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person, a thing or the set (nor a frond): in every moment his whole drawing is seen (no pixel hidden by the set or a frond, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, null);
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; for (const b of M.get(key(x, y)) || []) if (b.i !== fi && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) { boxCov++; break; } }
      lines.push('m' + m + ' ' + f.id + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (c.hid || c.fron || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.id + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.fron + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].id + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
    }
  }

  // 7. on-seat: a person on a seat sits on its top (z of the seat): abuela at mecedora is at z DECK.h + .44, the seat's top, and hung by her lap on the spot's row
  {
    const s = S.mecedora, bad = [], px = probes.spotsPx.mecedora, c = px.filter(r => Math.abs(r.dx) <= 1 && Math.abs(r.dy) <= 1).sort((a, b) => Math.abs(a.z - s.depth) - Math.abs(b.z - s.depth))[0], seatTop = r4(D.h + .44);
    if (s.uv[2] !== seatTop) bad.push('mecedora z ' + s.uv[2] + ' is not the seat\'s top ' + seatTop);
    if (!c || c.tag !== 'porche' || Math.abs(c.z - s.depth) >= .1) bad.push('mecedora ' + s.screen + ': the set\'s pixel under the spot is ' + (c ? 'part ' + c.tag + ' at depth ' + r2(c.z) + ', the spot\'s is ' + r2(s.depth) : 'none') + ': not the seat\'s top');
    const lap = PV.inspect[1].layers[idxAt(PV.inspect[1].layers, 'mecedora')];
    if (lap.sy !== s.screen[1] || lap.ay !== SIL.abuelaS.ay) bad.push('mecedora is not hung by the lap: drawn on row ' + lap.sy + ', its lap row ' + lap.ay + ' of the sprite (should be ' + SIL.abuelaS.ay + ' on ' + s.screen[1] + ')');
    add('on-seat', bad, 'abuela at mecedora ' + s.screen + ' sits at z ' + s.uv[2] + ' = DECK.h ' + D.h + ' + .44 = the chair\'s seat top (CHAIR [' + E.CHAIR + '] seat z ' + seatTop + '): the set draws part ' + c.tag + ' at depth ' + r2(c.z) + ' there (the spot\'s ' + r2(s.depth) + '); her sprite hangs by its lap row ' + lap.ay + ' on row ' + lap.sy + ' (feet ' + (SIL.abuelaS.box[3] + 1) + ' rows below it, ' + (lap.sy + SIL.abuelaS.box[3]) + ' on the deck\'s floor row ' + scrUV(G, s.uv[0], s.uv[1], D.h)[1] + ')', ['abuela does not sit on the seat:'].concat(bad.map(b => '  ' + b)));
  }

  // 8. abuela-head: abuela's head (the top 14 rows of her sprite) is covered by nobody and by nothing of the set (the beam, the blind, the posts, a frond) in every moment
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), i = idxAt(L, 'mecedora'), c = coverOf(L, M, i, null, [0, HEAD_ROWS]), body = coverOf(L, M, i, null);
      lines.push('m' + m + ': rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ' (' + c.tot + ' px): ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond' + '; her whole sprite: ' + body.cov + ' under a nearer sprite, ' + body.hid + ' hidden by the set, ' + body.fron + ' by a frond');
      if (c.cov || c.hid || c.fron) { bad.push('moment ' + m + ': abuela\'s head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + '): ' + c.cov + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, w]); }
    }
    const o = add('abuela-head', bad, 'abuela\'s head (the top ' + HEAD_ROWS + ' rows of her sprite) is covered by nobody and by nothing of the set in all 6 moments: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (her head covered by ' + cat + '): ' + cat + ' ' + S[M.layers[ci].at].uv + ': ' + axisTxt(r, M.layers[ci].at)); }
  }

  // 9. sky-clear: nobody and no frond covers the sun, the small cloud, the moon or the big star (their boxes; in every moment; the set's baked pixels over them are reported too)
  {
    const bad = [], lines = [], K = sheet.sky, objs = [['sun', K.sun.box], ['cloud', K.cloud.box], ['moon', K.moon.box], ['star', K.star.box]], drawn = {};
    for (const [n, , ] of objs) drawn[n] = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, bx = await PV.boxes(PV.moment[m].set, objs.map(o => o[1]));
      objs.forEach(([n, b], k) => {
        const spr = {}; let nspr = 0;
        for (const l of L) for (const p of l.px) if (!p[2] && inside(b, p[0], p[1])) { spr[l.id] = (spr[l.id] || 0) + 1; nspr++; }
        if (K[n].inSky === PV.moment[m].set.cielo) drawn[n].push(m);
        const txt = n + ' [' + b + ']: ' + nspr + ' px of sprites' + (nspr ? ' (' + Object.entries(spr).map(([a, c]) => a + ' ' + c).join(', ') + ')' : '') + ', ' + bx[k].frond + ' px of fronds, ' + bx[k].set + ' px of the set\'s baked pixels';
        lines.push('m' + m + ' ' + txt);
        if (nspr || bx[k].frond || bx[k].set) bad.push('moment ' + m + ' (cielo ' + PV.moment[m].set.cielo + '): ' + txt);
      });
    }
    add('sky-clear', bad, 'nobody, no frond and nothing of the set covers the sun [' + K.sun.box + '] (drawn in moments ' + drawn.sun + '), the small cloud [' + K.cloud.box + '] (' + drawn.cloud + '), the moon [' + K.moon.box + '] (' + drawn.moon + '), the big star [' + K.star.box + '] (' + drawn.star + ') in any of the 6 moments: 0 px in all 24 boxes; the highest sprite pixel of any moment is row ' + Math.min(...MOMENTS.map(m => Math.min(...PV.inspect[m].layers.map(l => Math.min(...l.px.map(p => p[1])))))) + ' (the round picture\'s top, moment 5; the highest person\'s pixel is row ' + Math.min(...MOMENTS.map(m => Math.min(...PV.inspect[m].layers.filter(l => l.who).map(l => Math.min(...l.px.map(p => p[1])))))) + '), the set\'s highest pixel is row ' + probes.topSet + ' and the palm\'s highest frond pixel at frame 0 is row ' + probes.topLive + ' (the four boxes end at row ' + Math.max(...objs.map(o => o[1][1] + o[1][3] - 1)) + ' at the lowest: ' + (probes.topLive - Math.max(...objs.map(o => o[1][1] + o[1][3] - 1)) - 1) + ' rows clear of the palm; the fronds sway a pixel or two, not that far)', ['something covers the sky\'s things:'].concat(bad.map(b => '  ' + b)));
  }

  // 10. candles-clear: the three candles on the table are covered by nobody (the glass cover, which you see through, is not counted: only its edge is drawn, and it is reported)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [3, 4, 6]) {
      const L = PV.inspect[m].layers, M = planes(L), glass = idxAt(L, 'tapa_puesta');
      const by = L.map((l, i) => i).filter(i => !L[i].id.startsWith('vela') && i !== glass);
      for (const id of ['vela1', 'vela2', 'vela3']) {
        const ci = idxAt(L, id), c = coverOf(L, M, ci, by), g = glass < 0 ? null : coverOf(L, M, ci, [glass]);
        lines.push('m' + m + ' ' + id + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond' + (g ? ', ' + g.cov + ' under the glass\'s edge' : ''));
        if (c.cov || c.hid || c.fron) { bad.push('moment ' + m + ' ' + id + ': ' + c.cov + ' px covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.fron + ' by a frond'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), ci, w]); }
      }
    }
    const glassPx = PV.inspect[4].layers.length ? ['vela1', 'vela2', 'vela3'].map(a => { const L = PV.inspect[4].layers; return coverOf(L, planes(L), idxAt(L, a), [idxAt(L, 'tapa_puesta')]).cov; }).reduce((a, b) => a + b, 0) : 0;
    const o = add('candles-clear', bad, 'the three candles are covered by nobody (and not hidden by the set) in moments 3, 4 and 6; the glass cover of moment 4 is not counted (the spec puts it over them; it is drawn as an edge only, which crosses ' + glassPx + ' px of them): ' + lines.join('; '), [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], null); o.lines.push('       nearest passing, moment ' + m + ' (' + M.layers[ti].id + ' covered by ' + cat + '): ' + cat + ' ' + S[M.layers[ci].at].uv + ': ' + axisTxt(r, M.layers[ci].at)); }
  }

  // 11. frog-piso: the frog at piso is whole: the table and the chair are not in front of him (no pixel of him hidden by the set, nor under anybody); information: how much of his 32 x 25 box the set has in front of it
  {
    const bad = [], lines = [];
    for (const m of [3, 4, 6]) {
      const L = PV.inspect[m].layers, M = planes(L), fi = idxAt(L, 'piso'), f = L[fi], c = coverOf(L, M, fi, null);
      const zl = await PV.layers(PV.moment[m].set, [{ at: 'piso', s: 'coqui', who: 'coqui' }]), z0 = zl[0];
      lines.push('m' + m + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set (the table and the chair included), ' + c.fron + ' by a frond, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + '; alone on the porch: ' + z0.px.filter(p => p[2]).length + ' hidden');
      if (c.hid || c.fron || c.cov || f.out) bad.push('moment ' + m + ': the frog at piso ' + [f.sx, f.sy] + ': ' + c.hid + ' px hidden by the set, ' + c.fron + ' by a frond, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture');
    }
    add('frog-piso', bad, 'the frog at piso ' + S.piso.screen + ' is whole in moments 3, 4 and 6: the table (TABLE [' + E.TABLE + ']) and the chair (CHAIR [' + E.CHAIR + ']) are not in front of him: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad));
  }

  // 12. umbrella-canopy: the open umbrella's canopy covers neither the frog on the blanket nor the tray (moment 2): by the nearer sprite pixel, and by plain overlap of the drawn pixels
  {
    const bad = [], L = PV.inspect[2].layers, M = planes(L), ui = idxAt(L, 'sombrilla'), fi = idxAt(L, 'manta'), ti = idxAt(L, 'bandeja'), cb = S.sombrilla.open.box;
    const lines = [];
    for (const [n, i] of [['the frog at manta', fi], ['the tray', ti]]) {
      const c = coverOf(L, M, i, [ui]);
      const lay = L[i], over = lay.px.filter(p => inside(cb, p[0], p[1])).length;
      const top = Math.min(...lay.px.map(p => p[1])), canopyBottom = cb[1] + cb[3] - 1;
      lines.push(n + ': ' + c.cov + ' px under the umbrella, ' + over + ' px inside the canopy\'s box [' + cb + '] (his top row ' + top + ', the canopy\'s bottom row ' + canopyBottom + ': ' + (top - canopyBottom - 1) + ' rows clear)');
      if (c.cov || over) bad.push(n + ': ' + c.cov + ' px covered by the umbrella, ' + over + ' px inside the canopy\'s box');
    }
    const pole = L[ui].px.filter(p => !p[2] && p[1] >= cb[1] + cb[3]);
    const poleOnFrog = pole.filter(p => L[fi].px.some(q => q[0] === p[0] && q[1] === p[1] && !q[2])).length;
    add('umbrella-canopy', bad, 'the open umbrella\'s canopy [' + cb + '] (foot ' + S.sombrilla.open.foot + ' px above the sand) covers neither the frog on the blanket nor the tray: ' + lines.join('; ') + '; its pole (2 px wide) and the frog: ' + poleOnFrog + ' px in common (the frog is nearer, v ' + S.manta.uv[1] + ' against the umbrella\'s ' + S.sombrilla.uv[1] + ')', ['the canopy covers something:'].concat(bad.map(b => '  ' + b)));
  }

  // 13. feet-above-foot: every spot's feet are above the picture's last row by 4 px or more (the point's row sy; the last row is H - 1)
  {
    const bad = [], rows = [];
    for (const [k, s] of Object.entries(S)) {
      if (s.overlay) continue;
      const gap = G.H - 1 - s.screen[1];
      rows.push([k, gap]);
      if (gap < FOOT_GAP) bad.push(k + ' ' + s.screen + ': its feet row ' + s.screen[1] + ' is ' + gap + ' px above the last row ' + (G.H - 1) + ' (needs ' + FOOT_GAP + ')');
    }
    const lowest = rows.slice().sort((a, b) => a[1] - b[1]).slice(0, 4);
    add('feet-above-foot', bad, 'every one of the ' + rows.length + ' spots with a point has its feet ' + FOOT_GAP + ' px or more above the picture\'s last row ' + (G.H - 1) + ' (v 4.9 is row ' + Math.round(G.OY + 4.9 * 13) + '): the lowest are ' + lowest.map(([k, g]) => k + ' ' + S[k].screen[1] + ' (' + g + ' px)').join(', '), ['spots too near the picture\'s foot:'].concat(bad.map(b => '  ' + b)));
  }

  // 14. visor: the round picture (moment 5) is inside the window and covers nobody's head (the top 14 rows of a person's sprite): its disc and its box
  {
    const bad = [], L = PV.inspect[5].layers, M = planes(L), vi = idxAt(L, 'visor'), vb = S.visor.box, cx = vb[0] + vb[2] / 2, cy = vb[1] + vb[3] / 2, lines = [];
    const cutL = Math.max(0, x0 - vb[0]), cutR = Math.max(0, vb[0] + vb[2] - (x0 + 196)), pic = vb[0] < 0 || vb[1] < 0 || vb[0] + vb[2] > G.W || vb[1] + vb[3] > G.H;
    if (cutL || cutR || pic) bad.push('the round picture [' + vb + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture');
    for (const [i, l] of L.entries()) {
      if (!l.who || l.who === 'coqui') continue;
      const c = coverOf(L, M, i, [vi], [0, HEAD_ROWS]), body = coverOf(L, M, i, [vi]);
      const top = c.top, inBox = l.px.filter(p => p[1] >= top && p[1] < top + HEAD_ROWS && inside(vb, p[0], p[1])).length;
      lines.push(l.id + ' ' + [l.sx, l.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ', ' + c.cov + ' px covered by the picture (' + inBox + ' in its box), the whole sprite ' + body.cov);
      if (c.cov || inBox) bad.push(l.id + '\'s head: ' + c.cov + ' px covered by the round picture, ' + inBox + ' px inside its box');
    }
    const fr = L.find(l => l.who === 'coqui'), frc = coverOf(L, M, L.indexOf(fr), [vi]);
    lines.push('the frog (not a person): ' + frc.cov + ' px under it');
    add('visor', bad, 'the round picture [' + vb + '] (centre ' + [cx, cy] + ') is inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture and covers nobody\'s head in moment 5: ' + lines.join('; '), ['the round picture:'].concat(bad.map(b => '  ' + b)));
  }

  // info: how the people and the stand-ins touch each other (not checks of the spec: findings of its numbers)
  {
    const low = (a, b) => Math.max(...probes.frondLow.slice(a, b + 1)), lines = [], L3 = PV.inspect[3].layers, M3 = planes(L3), rows =(L, i, f) => { const r = L[i].px.filter(f).map(p => p[1]); return r.length ? 'rows ' + Math.min(...r) + ' to ' + Math.max(...r) : 'no rows'; };
    {                                                                                          // the radio and the candles
      const ri = idxAt(L3, 'radio'), c = coverOf(L3, M3, ri, ['vela1', 'vela2', 'vela3'].map(a => idxAt(L3, a)));
      lines.push('the radio and the candles (moments 3, 6; 4 the same): the candles cover ' + c.cov + ' of the radio\'s ' + c.tot + ' px (the radio box [' + S.radio.box + '], the candles\' [' + S.velas.box + ']: the left candle begins ' + (S.radio.box[0] + S.radio.box[2] - S.velas.parts[0][0]) + ' columns inside the radio\'s right end and stands in front of it: v ' + S.velas.uv[1] + ' against the radio\'s ' + S.radio.uv[1] + ')');
      const L4 = PV.inspect[4].layers, M4 = planes(L4), g = coverOf(L4, M4, idxAt(L4, 'radio'), [idxAt(L4, 'tapa_puesta')]);
      lines.push('moment 4: the glass cover\'s edge covers ' + g.cov + ' px of the radio and ' + ['vela1', 'vela2', 'vela3'].map(a => coverOf(L4, M4, idxAt(L4, a), [idxAt(L4, 'tapa_puesta')]).cov).reduce((a, b) => a + b, 0) + ' px of the candles (the glass is drawn as an edge only: you see through it)');
    }
    {                                                                                          // abuela, the frog, Luis, the shawl
      const ai = idxAt(L3, 'mecedora'), fi = idxAt(L3, 'piso'), li = idxAt(L3, 'mesa1'), ci = idxAt(L3, 'chal');
      const byFrog = coverOf(L3, M3, ai, [fi]), byShawl = coverOf(L3, M3, ai, [ci]), sh = coverOf(L3, M3, ci, [ai]), tl = L3[li].px.filter(p => p[2] === 1).length;
      lines.push('moment 3 (4 and 6 the same): the frog at piso covers ' + byFrog.cov + ' of abuela\'s ' + byFrog.tot + ' px (' + rows(L3, ai, p => !p[2] && M3.get(key(p[0], p[1])).some(b => b.i === fi && b.plane > p[3] + EPS)) + ': her lap and knees; her head is rows ' + coverOf(L3, M3, ai, null, [0, HEAD_ROWS]).top + ' to ' + (coverOf(L3, M3, ai, null, [0, HEAD_ROWS]).top + HEAD_ROWS - 1) + ', clear); the boxes overlap ' + (L3[ai].sx + 12 - (L3[fi].sx - 16)) + ' columns (her 24-wide box and his 32), her feet are ' + (L3[fi].sy - L3[ai].sy) + ' px above his');
      const both = L3[ci].px.filter(p => L3[ai].px.some(q => q[0] === p[0] && q[1] === p[1])).length;
      lines.push('moment 3: the shawl [' + S.chal.box + '] and abuela share ' + both + ' drawn pixels (the shawl covers ' + byShawl.cov + ' of her, she covers ' + sh.cov + ' of its ' + sh.tot + '); its point hangs 7 px above the chair seat\'s right edge (the set draws no arm)');
      lines.push('moment 3: the table hides ' + tl + ' of Luis\'s ' + L3[li].px.length + ' px (' + rows(L3, li, p => p[2] === 1) + '; his head, rows ' + coverOf(L3, M3, li, null, [0, HEAD_ROWS]).top + ' to ' + (coverOf(L3, M3, li, null, [0, HEAD_ROWS]).top + HEAD_ROWS - 1) + ', is clear)');
      const a = L3[ai].px.filter(p => p[2] === 1);
      lines.push('abuela: ' + a.length + ' px of her sprite are hidden by the set in every moment (' + rows(L3, ai, p => p[2] === 1) + ': her shoes behind the chair\'s rockers); none by a frond');
    }
    {                                                                                          // the ball, the kite, Luis and the palm
      const L1 = PV.inspect[1].layers, M1 = planes(L1), ci = idxAt(L1, 'bola'), ki = idxAt(L1, 'bola1');
      lines.push('moment 1: the ball at Carmen\'s feet (15 px to her right: an open point) covers ' + coverOf(L1, M1, ki, [ci]).cov + ' px of her');
      let fr = 0; const per = []; for (const m of MOMENTS) for (const l of PV.inspect[m].layers) { const n = l.px.filter(p => p[2] === 2).length; fr += n; if (n) per.push('m' + m + ' ' + l.id + ' ' + n); }
      lines.push('fronds at frame 0: ' + fr + ' px of sprites hidden by a frond in all 6 moments' + (per.length ? ' (' + per.join(', ') + ')' : '') + '; the frond that reaches lowest over Luis at chiringa_pie (columns ' + (S.chiringa_pie.screen[0] - 12) + ' to ' + (S.chiringa_pie.screen[0] + 11) + ') ends at row ' + low(S.chiringa_pie.screen[0] - 12, S.chiringa_pie.screen[0] + 11) + ' and his head begins at row ' + (S.chiringa_pie.screen[1] - 41) + '; over the open umbrella\'s canopy (columns ' + S.sombrilla.open.box[0] + ' to ' + (S.sombrilla.open.box[0] + 63) + ') at row ' + low(S.sombrilla.open.box[0], S.sombrilla.open.box[0] + 63) + ' (the canopy begins at row ' + S.sombrilla.open.box[1] + '); over the kite (columns ' + S.chiringa.box[0] + ' to ' + (S.chiringa.box[0] + 19) + ') at row ' + low(S.chiringa.box[0], S.chiringa.box[0] + 19) + ' (the kite begins at row ' + S.chiringa.box[1] + ')');
    }
    OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check, findings of the spec\'s numbers:'].concat(lines.map(l => '       ' + l)) });
  }

  return OUTS;
}
