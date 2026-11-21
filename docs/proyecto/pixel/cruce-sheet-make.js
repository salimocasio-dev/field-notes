#!/usr/bin/env node
'use strict';
/* El cruce's sheet: writes docs/proyecto/pixel/cruce-sheet.json from cruce-set.html and the design (the orchestrator's p5-spec, section "cruce"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/cruce-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The streets of the set are turned 45 degrees: a spot is given in (u, v, z), u across the picture and v down it, and
   the set's own E.xy(u, v) gives its world place; the make then projects it with the engine's own project() (pp-engine.js). In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S.
   It loads the set in headless Chrome (cruce-set.html, window.CRUCE.E: the set's constants), reads the pixels it drew (tags=1: which part drew each pixel; the baked depth),
   and writes the spots, things, the two views (wide, plaza), shadows and the depth rule. The sprites' silhouettes come from today's makers (historia/engine.js, historia/escenas/kit.js)
   loaded in a second, empty page. The checks that say "covers" or "shows" read the PREVIEW's moments (cruce-preview.html, PREVIEW.inspect and its queries): the sheet is written
   first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CRUCE_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'cruce-sheet.json');
const BASE = process.env.CRUCE_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/cruce-set.html';
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

// the numbers of the design (p5-spec: the rules for every sheet, and "cruce")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite (as El mostrador's ninos-puerta-heads)
const PLACE_BOX = { w: 24, h: 20 };                      // the frog's four places: a box 24 wide, 20 high, its bottom middle on the place
const STRIPES = { half: .45 };                           // the stripes where they come up run from v = HW to HW + .9: the lower half is the half nearer the camera
const WALK_STEP = .05;                                   // somebody leaving by a street is tried every .05 of the way
const SEAT_Z = { asiento: .46, muro: .55 };              // the seat's top, the top of the low wall: read back from the set's depth (spots-on-surface)
const MOMENTS = [1, 2, 3, 4, 5, 6, 7];

// the spots: [name, (u, v, z), kind, silhouette, character kind, view, what]
// silhouette: which drawing hangs there (adulto, nino, abuela, abuelaS = abuela sitting, luisS = a child sitting, papaRod = kneeling, coqui, perro = Canelo lying, bebe) or null for a small thing
const FROG_PLACES = ['delante_canelo', 'detras_canelo', 'lado_abuela', 'delante_abuela'];
const SPOTS = [
  ['abajo.abuela', [-.5, 4.6, 0], 'person', 'abuela', 'adulto', 'wide', 'where abuela comes up from the bottom (57 opening)'],
  ['abajo.coqui', [.7, 4.2, 0], 'person', 'coqui', 'coqui', 'wide', 'where the frog comes up (57 opening)'],
  ['abajo.bici', [0, 4.5, 0], 'person', 'nino', 'nino', 'wide', 'Luis on his bicycle, heading up the picture (58); the bicycle is a sprite, in front of him'],
  ['coqui.bici', [0, 5.0, .8], 'person', 'coqui', 'coqui', 'wide', 'the frog rides behind Luis on the rack of his bicycle (58), high enough to be seen over Luis\'s back: on a sprite, z .8', 'bicycle'],
  ['centro', [0, -.15, 0], 'person', 'adulto', 'adulto', 'wide', 'somebody asked at the crossing, facing us (don Pepe on his bicycle, the señor, the señora)'],
  ['coqui.cruce', [.3, 1.9, 0], 'person', 'coqui', 'coqui', 'wide', 'the frog on the stripes where they come up, in the game of 57 (moment 2)'],
  ['salida_izq', [-3.3, 0, 0], 'exit', 'adulto', 'adulto', 'wide', 'where the street to the left leaves the picture (only the point is held inside the window)'],
  ['salida_der', [3.9, 0, 0], 'exit', 'adulto', 'adulto', 'wide', 'where the street to the right leaves the picture (only the point is held inside the window)'],
  ['salida_recta', [0, -5.2, 0], 'exit', 'adulto', 'adulto', 'wide', 'where the street straight on leaves the picture (only the point is held inside the window)'],
  ['bajo_arbol', [-.7, -3.6, 0], 'person', 'nino', 'nino', 'wide', 'where Luis stops under the big tree (58)'],
  ['asiento.abuela', [2.75, 4.5, .46], 'person', 'abuelaS', 'adulto', 'wide', 'abuela sitting on the seat (57): on its top, z .46; the sitting sprite hangs by her lap'],
  ['asiento.bolsa', [3.85, 4.5, .46], 'thing', null, null, 'wide', 'her bag on the seat, the bottle standing on it (57)'],
  ['asiento.coqui', [3.3, 5.5, 0], 'person', 'coqui', 'coqui', 'wide', 'the frog arriving at the seat (57)'],
  ['conos.obrero', [3.3, .6, 0], 'person', 'adulto', 'adulto', 'wide', 'the obrero behind the barrier of cones (58)'],
  ['plaza_carrito', [4.3, 5.3, 0], 'person', 'adulto', 'adulto', 'plaza', 'the piragüero with his cart in the square, in the plaza view (58 ending)'],
  ['luis.plaza', [2.5, 5.6, 0], 'person', 'nino', 'nino', 'plaza', 'Luis in the square (58 ending)'],
  ['coqui.plaza', [3.7, 6.7, 0], 'person', 'coqui', 'coqui', 'plaza', 'the frog in the square (58 ending)'],
  ['fila_atras1', [1.75, 2.9, 0], 'person', 'adulto', 'adulto', 'plaza', 'abuelo, first of the back row, well behind the seat (59)'],
  ['fila_atras2', [2.75, 2.9, 0], 'person', 'adulto', 'adulto', 'plaza', 'mamá, second of the back row (59)'],
  ['fila_atras3', [3.85, 2.9, 0], 'person', 'nino', 'nino', 'plaza', 'Carmen, third of the back row (59)'],
  ['bebe_alto', [2.25, 2.9, .9], 'person', 'bebe', 'nino', 'plaza', 'the bebé held up between abuelo and mamá (59): on a sprite, z .9; a child\'s width', 'mama'],
  ['asiento1', [2.75, 4.5, .46], 'person', 'abuelaS', 'adulto', 'plaza', 'abuela sitting on the seat (59)'],
  ['asiento2', [3.85, 4.5, .46], 'person', 'luisS', 'nino', 'plaza', 'Luis sitting on the seat (59)'],
  ['hueco', [3.3, 4.5, .46], 'person', 'coqui', 'coqui', 'plaza', 'the gap on the seat between abuela and Luis: also lado_abuela, and the frog\'s last place (59 ending)'],
  ['suelo_canelo', [4.9, 5.62, 0], 'person', 'perro', 'perro', 'plaza', 'Canelo lying on the ground in front of the seat, at the right (59)'],
  ['papa_camara', [1.9, 7.3, 0], 'person', 'adulto', 'adulto', 'plaza', 'papá with his back to us, taking the photo (59)'],
  ['muro', [2.6, 7.0, .55], 'thing', null, null, 'plaza', 'the camera on the short low wall (59 ending): on its top, z .55'],
  ['papa_rodillas', [1.75, 5.0, 0], 'person', 'papaRod', 'adulto', 'plaza', 'papá kneeling at the seat\'s left end (59 ending)'],
  ['tras_papa', [1.9, 6.55, 0], 'person', 'coqui', 'coqui', 'plaza', 'the frog behind papá, who stands at papa_camara with his back to us (59 start): nearer the family than papá, so papá\'s legs cover part of him: that is meant'],
  ['delante_canelo', [4.9, 6.3, 0], 'place', 'coqui', 'coqui', 'plaza', 'the frog\'s place in front of Canelo (59)'],
  ['detras_canelo', [4.9, 4.62, 0], 'place', 'coqui', 'coqui', 'plaza', 'the frog\'s place behind Canelo, between him and the seat (59)'],
  ['lado_abuela', [3.3, 4.5, .46], 'place', 'coqui', 'coqui', 'plaza', 'the frog\'s place beside abuela, on the seat in the gap: the same point as hueco (59)'],
  ['delante_abuela', [2.9, 5.15, 0], 'place', 'coqui', 'coqui', 'plaza', 'the frog\'s place on the ground in front of abuela (59)'],
];
const SPOT_MAP = Object.fromEntries(SPOTS.map(s => [s[0], s]));
// the views: holds = the spots the spec makes the window hold (a person's sprite whole; an exit its point only)
const VIEWS = {
  wide: { stories: [57, 58], holds: ['coqui.cruce', 'centro', 'abajo.abuela', 'abajo.coqui', 'abajo.bici', 'asiento.abuela', 'salida_izq', 'salida_der', 'salida_recta'], rule: 'The spec: wide holds coqui.cruce, centro, abajo.* and asiento.abuela with their sprites whole, and the points of the three exits' },
  plaza: { stories: [58, 59], holds: SPOTS.filter(s => s[5] === 'plaza').map(s => s[0]), rule: 'The spec: plaza holds every spot of story 59 and of the ending of 58, with sprites whole (58\'s ending is shown in this view)' },
};
const STATES = [];
for (const hora of ['mediodia', 'tarde', 'ocaso']) for (const cerrada of [0, 1]) STATES.push({ hora, cerrada });

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (the spec's spots are inside their window), spots-in-view (every spot inside the picture and its window, its sprite whole), spots-on-surface (the spots on the seat and the wall
   are on their top), things-in-view (the frog's four boxes inside the plaza window; the streets' boxes reach the picture's edge), sprites-apart (the people of a moment), frog-seen (the frog whole in
   every moment), frog-places (each of his six places whole with the family in place), family-heads (every head of the family shows), centro-stripes (a person at centro is clear of the stripes'
   lower half), salida-whole (whoever leaves by a street is seen whole until the picture's edge). A failing line names its numbers and the nearest value that would pass. */
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
    const o = {}; for (const [k, v] of Object.entries(CRUCE.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const [x, y] = CRUCE.E.xy(u, v), q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj, SIL, page);
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
      abuela: sil(mkAbuela('idle', 0), 30), abuelaS: sil(KIT.mkAbuelaS('idle', 0, 0), 17, 36), luisS: sil(KIT.mkPersona(FAM.hermano, 'idle', 0, 1), KIT.PX, lap(FAM.hermano)),
      papaRod: sil(KIT.mkPersona(FAM.papa, 'idle', 0, 1), KIT.PX), coqui: sil(mkCoqui(1, 0, 0), 16), perro: sil(KIT.mkPerro('lie', 0), 15), bebe: sil(KIT.mkBebe('idle', 0), 13),
    };
  });
}

/* ---------- the preview's moments: cruce-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/cruce-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.walk = (st, spr, who, a, b, n) => p.evaluate(x => window.PREVIEW.walk(x.st, x.spr, x.who, x.a, x.b, x.n), { st, spr, who, a, b, n });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];

// how many px of a spot are cut by the window at x0: its point outside, or (a person who is not at an exit) his sprite box; 0 when whole
function cutAt(s, x0) {
  const sx = s.screen[0], h = s.who ? WIDTH[s.who] / 2 : 0;
  if (!s.who || s.kind === 'exit') return sx < x0 ? x0 - sx : sx > x0 + 195 ? sx - x0 - 195 : 0;
  return Math.max(0, x0 - (sx - h)) + Math.max(0, (sx + h - 1) - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, SIL, page) {
  const E = G.E, sc = G.scene;
  const pr = await proj(SPOTS.map(s => s[1]));
  const spots = {};
  SPOTS.forEach((s, i) => {
    const q = pr[i], o = { world: W4([q[3], q[4], s[1][2]]), uv: W4(s[1]), screen: [Math.round(q[0]), Math.round(q[1])], depth: r4(q[2]), scale: 1, kind: s[2], view: s[5], what: s[6] };
    if (s[3]) o.sprite = s[3];
    if (s[4]) o.who = s[4];
    if (s[1][2] > 0) o.on = s[7] || 'plaza';                                  // what it stands on above the ground: a part of the set (the seat, its back, the low wall) or a sprite
    spots[s[0]] = o;
  });

  /* ---- the views: x0 so that the spec's spots are inside; the window's point is the ground point under its middle column at the picture's middle row ---- */
  const views = {};
  for (const [name, V] of Object.entries(VIEWS)) {
    // the extent of what the window must hold: a person's sprite box (an exit: its point), in columns
    const ext = V.holds.map(k => { const sp = spots[k], h = sp.who && sp.kind !== 'exit' ? WIDTH[sp.who] / 2 : 0; return [sp.screen[0] - h, sp.screen[0] + h - (h ? 1 : 0)]; });
    const lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1])), want = Math.max(0, Math.min(G.W - 196, Math.round((lo + hi) / 2 - 98)));
    // the x0 (0 to 44) at which the fewest of the spec's spots are cut, then the fewest px; then the fewest of all the view's spots, then the fewest px; then the nearest to the middle of the spec's extent.
    // A spot is cut when its point is outside the window or, for a person (not an exit), when his sprite box is (the frog 32 wide, a grown-up 24, a child 24, the dog 28)
    let best = null;
    for (let x0 = 0; x0 <= G.W - 196; x0++) {
      let n = 0, px = 0, na = 0, pa = 0;
      for (const [k, s] of Object.entries(spots)) if (s.view === name) { const c = cutAt(s, x0); if (c) { na++; pa += c; if (V.holds.includes(k)) { n++; px += c; } } }
      const key = [n, px, na, pa, Math.abs(x0 - want)];
      let better = !best; if (best) for (let i = 0; i < key.length; i++) { if (key[i] !== best.key[i]) { better = key[i] < best.key[i]; break; } }
      if (better) best = { x0, key };
    }
    const x0 = best.x0;
    const u = (x0 + 98 - G.OX) / G.S, v = (G.H / 2 - G.OY) / (G.S * .5), q = (await proj([[u, v, 0]]))[0];
    views[name] = { world: W4([q[3], q[4], 0]), uv: W4([u, v, 0]), screen: [r2(q[0]), r2(q[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: V.stories, holds: V.holds, extent: [lo, hi],
      what: 'the ' + name + ' view of stories ' + V.stories.join(' and ') + ': the 196 x 216 window over the 240 x 216 picture. ' + V.rule + '. ' + (best.key[0] ? 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest of them (' + best.key[0] + ', ' + best.key[1] + ' px)' : 'x0 ' + x0 + ' holds them all' + (best.key[2] ? ', and cuts ' + best.key[2] + ' other spot(s) of the view (' + best.key[3] + ' px)' : ', and every other spot of the view') + ' (the spots held span columns ' + lo + ' to ' + hi + '; the x0 nearest their middle among those that hold them)') + '. The window\'s point is the ground point under its middle column at the picture\'s middle row (wide and plaza are the same picture, two windows)' };
  }

  /* ---- things he can touch ---- */
  const HW = E.HW, uL = (0 - G.OX) / G.S, uR = (G.W - G.OX) / G.S, vT = (0 - G.OY) / (G.S * .5);         // the picture's left, right and top edges on the ground, in u, v
  const boxOfUV = async (u0, v0, u1, v1) => {
    const corners = [[u0, v0, 0], [u1, v0, 0], [u1, v1, 0], [u0, v1, 0]], q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], quad: q.map(p => W4([p[3], p[4], 0])), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), 0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), 0]) };
  };
  const street = async (u0, v0, u1, v1, what) => { const b = await boxOfUV(u0, v0, u1, v1); return { set: true, uv: W4([u0, v0, 0, u1, v1, 0]), world: b.world, quad: b.quad, box: b.box, what }; };
  const things = {
    calle_izq: await street(uL, -HW, -HW, HW, 'the street to the left, from the crossing\'s edge (u -' + HW + ') to the picture\'s left edge, the whole road across (v -' + HW + ' .. ' + HW + '): the screen rectangle on the ground. world is the world-axis box round it (the street is turned 45 degrees: use uv or quad for its shape); a poke'),
    calle_der: await street(HW, -HW, uR, HW, 'the street to the right, from the crossing\'s edge (u ' + HW + ') to the picture\'s right edge (cerrada = 1: the cones close it, touching it does nothing); a poke'),
    calle_recta: await street(-HW, vT, HW, -HW, 'the street straight on, from the crossing\'s edge (v -' + HW + ') to the picture\'s top edge; a poke'),
  };
  for (const k of FROG_PLACES) {
    const s = spots[k], [sx, sy] = s.screen;
    things[k] = { set: false, at: k, world: s.world, uv: s.uv, box: [sx - PLACE_BOX.w / 2, sy - PLACE_BOX.h, PLACE_BOX.w, PLACE_BOX.h], what: 'the frog\'s place ' + k + ': a box ' + PLACE_BOX.w + ' wide and ' + PLACE_BOX.h + ' high, its bottom middle on the spot (the spec gives the size, not where the box sits: open point); a poke' };
  }
  for (const k of ['pepe', 'senor', 'senora', 'obrero', 'piraguero', 'abuela', 'abuelo', 'mama', 'papa', 'luis', 'carmen', 'bebe', 'perro', 'coqui']) things[k] = 'sprite';

  return {
    scene: 'cruce',
    made: 'node docs/proyecto/pixel/cruce-sheet-make.js, from cruce-set.html (window.CRUCE.E) and the design of El cruce (the orchestrator\'s p5-spec, section cruce). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the streets are turned 45 degrees: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the crossing\'s middle at (0, 0); the set\'s E.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. Half a street\'s width is E.HW = ' + HW + '; the picture holds u from ' + r2(uL) + ' to ' + r2(uR) + ' and, on the ground, v from ' + r2(vT) + ' to ' + r2((G.H - G.OY) / (G.S * .5)),
      spot: 'a spot is a world point of the feet (z 0: the ground; z .46: the seat\'s top; z .9 and .8: on a sprite; z .55: the low wall\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere. People walk on the roadway in this scene (there are no cars): no spot is kept off the street',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), 41 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a child or a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 7 a child: 33; t 11 a grown-up: 41) on (sx, sy); kneeling (papa_rodillas): the sitting drawing with its feet on the spot (stand-in); Canelo lying mkPerro(\'lie\') (30 x 22): column 15 and its bottom edge; the bebé mkBebe (26 x 28): column 13 and its bottom edge (a stand-in: it is a sitting baby; mamá holds him up, z .9); a small thing: its bottom middle on the point',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the middle of the columns of the spots the view must hold. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      box: 'a place of the frog (the six of story 59) is a poke box ' + PLACE_BOX.w + ' x ' + PLACE_BOX.h + ': its bottom middle on the spot, so [sx - 12, sy - 20, 24, 20]',
    },
    setKey: {
      params: { hora: { values: ['mediodia', 'tarde', 'ocaso'], note: '57 mediodia, 58 tarde, 59 ocaso (the script says: midday, afternoon hot, late afternoon, a soft light: my reading, open point)' }, cerrada: { values: [0, 1], note: 'the cones across the street to the right (story 58)' } },
      key: 'hora + cerrada, e.g. "mediodia-0"',
      baked: ['mediodia', 'tarde', 'ocaso'].flatMap(h => [0, 1].map(c => '?hora=' + h + '&cerrada=' + c)),
    },
    things,
    spots,
    groups: { familia: ['fila_atras1', 'fila_atras2', 'fila_atras3', 'bebe_alto', 'asiento1', 'asiento2', 'suelo_canelo', 'papa_camara', 'papa_rodillas'], atras: ['fila_atras1', 'fila_atras2', 'fila_atras3', 'bebe_alto'] },
    notes: [
      'every number of a spot is the orchestrator\'s (pass 2 of the cruce spec), given in (u, v, z); lado_abuela and hueco are the same point (3.3, 4.5, .46)',
      'the salida_* spots are exits: a person walks out of the picture along the street, so only their point is held inside the window (spots-in-view reports the sprite\'s cut as information)',
      'the plaza view also shows the ending of 58: plaza_carrito, luis.plaza and coqui.plaza are plaza spots',
      'the view\'s x0: the x0 that cuts the fewest of the spots the spec names, then the fewest of the view\'s spots, then the one nearest the middle of the spec\'s spots (views.*.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the hedges, the trees\' crowns and trunks, the seat and the walls hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador\'s sheet: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn (the frog on the handlebar ties with Luis exactly: z .9 lifts him by the same depth as his place on the picture)',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, mama: .35, papa: .35, pepe: .35, senor: .35, senora: .35, obrero: .35, piraguero: .35, luis: .28, carmen: .28, bebe: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El mostrador\'s (frog .45, grown-ups .35, children .28) and .3 for the dog (open point)',
      none: SPOTS.filter(s => s[1][2] > 0).map(s => s[0]),
      onSeat: 'whoever sits on the seat, stands on its back or on the wall (z above 0) casts none: the seat is not ground (a shadow cast at the pavement under it would show in front of it)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part), in the base state (the depth does not change with hora; cerrada adds the barrier, away from the spots)
  const spotsPx = await page.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -2; dy <= 1; dy++) { const X = s.screen[0], Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X; rows.push({ dy, tag: TAGS[i], z: DEPTH.z[i] }); }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
  // the stripes where they come up: the pixels the set paints white, from the set's own groundAt, with their (u, v)
  const stripes = await page.evaluate(() => {
    const E = CRUCE.E, white = CL.paint(CL.WHITE), out = [];
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const g = unproject(ix + .5, iy + .5), [u, v] = E.uv(g.x, g.y);
      if (v > E.HW && v < E.HW + .9 && Math.abs(u) <= E.HW && groundAt(g.x, g.y, ix, iy) === white) out.push([ix, iy, +v.toFixed(3)]);
    }
    return { px: out, HW: E.HW };
  });
  const tags = px => page.evaluate(q => q.map(([x, y]) => TAGS[y * W + x] || 'ground'), px);          // the part the set drew at each pixel [x, y]
  return { spotsPx, stripes, tags };
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [];
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const hw = who => WIDTH[who] / 2;

  // 1. the views: x0 holds the spots the spec names (a person's sprite whole; an exit: its point), and says which x0 do
  {
    const bad = [], lines = [];
    for (const [name, v] of Object.entries(V)) {
      const out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
      const ok = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (v.holds.every(k => !cutAt(S[k], x0))) ok.push(x0);
      const all = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (Object.entries(S).filter(([, s]) => s.view === name).every(([, s]) => !cutAt(s, x0))) all.push(x0);
      lines.push(name + ': x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the spec\'s spots (' + v.holds.length + ') span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (ok.length ? ok[0] + ' to ' + ok[ok.length - 1] : 'none') + '; that hold every spot of the view too: ' + (all.length ? all[0] + ' to ' + all[all.length - 1] : 'none') + (out.length ? '; CUT: ' + out.map(o => o[0] + ' by ' + o[1] + ' px').join(', ') : ''));
      for (const o of out) bad.push(name + ': ' + o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    }
    const o = add('views-x0', bad, lines.join('; '), [bad.length + ' of the spec\'s spots cut by their view\'s window:'].concat(lines.map(l => '  ' + l)));
    o.x0 = { wide: V.wide.x0, plaza: V.plaza.x0 };
  }

  // 2. every spot inside the picture, and inside its view's window with its sprite whole (a sprite's box: the frog 32 wide, a grown-up 24, a child 24, the dog 28; and its rows, from the drawn silhouette)
  {
    const bad = [], info = [], rows = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, v = V[s.view], x0 = v.x0;
      const pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H, wOut = sx < x0 || sx > x0 + 195;
      const sil = s.sprite ? SIL[s.sprite] : null, h = s.who ? hw(s.who) : 0;
      const cutL = s.who ? Math.max(0, x0 - (sx - h)) : 0, cutR = s.who ? Math.max(0, (sx + h - 1) - (x0 + 195)) : 0;
      const picL = s.who ? Math.max(0, -(sx - h)) : 0, picR = s.who ? Math.max(0, (sx + h - 1) - (G.W - 1)) : 0;
      const top = sil ? sy + sil.box[1] : sy, bottom = sil ? sy + sil.box[3] : sy, cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      const pic = [picL && ('left ' + picL), picR && ('right ' + picR)].filter(Boolean);
      rows.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (wOut) bad.push(k + ' (' + s.view + ') ' + s.screen + ' is ' + (sx < x0 ? x0 - sx + ' px left of' : sx - (x0 + 195) + ' px right of') + ' its window [' + x0 + ', ' + (x0 + 196) + ')' + (pic.length ? '; its sprite is also cut by the picture\'s edge: ' + pic.join(', ') : ''));
      else if (cut.length) {
        if (s.kind === 'exit') info.push(k + ' ' + s.screen + ' (an exit, the sprite leaves the picture there): its ' + s.who + ' sprite is cut ' + cut.join(', ') + ' px in the ' + s.view + ' window' + (pic.length ? ' (the picture\'s own edge: ' + pic.join(', ') + ')' : ''));
        else bad.push(k + ' (' + s.view + ') ' + s.screen + ': its ' + s.who + ' sprite is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')' + (pic.length ? ', and by the picture\'s edge: ' + pic.join(', ') : ''));
      }
    }
    // the nearest value that passes, for a spot cut or outside: the least shift in u, in steps of .01 (v and z kept), that puts the point inside and the sprite whole
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k], v = V[s.view], h = s.who && s.kind !== 'exit' ? hw(s.who) : 0;       // an exit: its point only
      const ok = (sx) => sx >= v.x0 + h && sx - 1 + h <= v.x0 + 195 && sx - h >= 0 && sx + h - 1 <= G.W - 1;
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0]; if (ok(sx)) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, rows.length + ' spots (points and sprites) inside the ' + G.W + ' x ' + G.H + ' picture and their view\'s window (wide x0 ' + V.wide.x0 + ', plaza x0 ' + V.plaza.x0 + ')', [bad.length + ' spot(s) outside, or with a sprite cut:'].concat(bad.map(b => '  ' + b), hints));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
    o.cut = bad;
  }

  // 3. the spots above the ground are on a surface the set draws: the seat's top, the top of its back, the low wall's top (z read back from the baked depth: the depth there is the spot's, within .1, drawn by part plaza)
  {
    const bad = [], lines = [], seatSpots = Object.entries(S).filter(([, s]) => s.on === 'plaza'), groundSpots = Object.entries(S).filter(([, s]) => s.uv[2] === 0), behind = [];
    for (const [k, s] of seatSpots) {
      const rows = probes.spotsPx[k] || [], best = rows.map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0];
      const ok = best && best.r.tag === 'plaza' && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws: ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    for (const [k, s] of groundSpots) {                                                                // information: a ground spot whose feet pixel the set draws nearer than the feet (the person stands behind it)
      if (s.screen[0] < 0 || s.screen[0] >= G.W || s.screen[1] < 0 || s.screen[1] >= G.H) continue;
      const feet = (probes.spotsPx[k] || []).find(r => r.dy === -1);
      if (feet && feet.z > s.depth + .08) behind.push(k + ' ' + s.screen + ' (' + (feet.tag || 'ground') + ' ' + r2(feet.z - s.depth) + ' nearer)');
    }
    const o = add('spots-on-surface', bad, seatSpots.length + ' spots above the ground (' + seatSpots.map(([k]) => k).join(', ') + ') are on a surface the set draws: its depth within .1 of the spot\'s, drawn by part plaza (the seat\'s top z ' + SEAT_Z.asiento + ', the wall\'s ' + SEAT_Z.muro + '); coqui.bici (z .8) and bebe_alto (z .9) are on sprites', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       info, not a check: ground spots whose feet pixel the set draws nearer than the feet (the person stands behind it: the depth rule hides what it covers): ' + (behind.join(', ') || 'none'));
  }

  // 4. the frog's boxes, the streets' boxes
  {
    const bad = [], v = V.plaza, x0 = v.x0, lines = [];
    for (const k of FROG_PLACES) {
      const b = T[k].box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), t = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || t > 0 || bt > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the plaza window [' + x0 + ', ' + (x0 + 196) + ')' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (pr > 0 ? ' (the picture ends ' + pr + ' px sooner)' : ''));
    }
    const sb = [['calle_izq', 'wide'], ['calle_der', 'wide'], ['calle_recta', 'wide'], ['calle_izq', 'plaza'], ['calle_der', 'plaza'], ['calle_recta', 'plaza']].map(([k, vn]) => { const b = T[k].box, x0v = V[vn].x0, cl = Math.max(0, x0v - b[0]), cr = Math.max(0, b[0] + b[2] - (x0v + 196)); return k + ' in ' + vn + ': ' + (cl || cr ? 'the window cuts ' + [cl && cl + ' px at the left', cr && cr + ' px at the right'].filter(Boolean).join(' and ') + ' of its ' + b[2] + ' columns' : 'whole'); });
    // each street's box lies inside the picture, runs from the crossing's edge to the picture's edge
    const edge = [];
    const bi = T.calle_izq.box, bd = T.calle_der.box, br = T.calle_recta.box;
    if (bi[0] !== 0) edge.push('calle_izq starts at column ' + bi[0] + ', not the picture\'s left edge');
    if (bd[0] + bd[2] !== G.W) edge.push('calle_der ends at column ' + (bd[0] + bd[2]) + ', not the picture\'s right edge ' + G.W);
    if (br[1] !== 0) edge.push('calle_recta starts at row ' + br[1] + ', not the picture\'s top edge');
    const o = add('things-in-view', bad.concat(edge), 'the frog\'s four boxes (' + lines.join(', ') + ') are inside the plaza window [' + x0 + ', ' + (x0 + 196) + ') and the picture; the three streets\' boxes run from the crossing\'s edge to the picture\'s edge (calle_izq [' + bi + '], calle_der [' + bd + '], calle_recta [' + br + '])', ['things outside:'].concat(bad, edge).map((l, i) => i ? '  ' + l : l));
    for (const l of sb) o.lines.push('       info, not a check: ' + l);
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24, the dog 28; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down.
  //    Not counted (reported as information): a pair of which one is in the back row and the other is on the seat or on the ground in front; the frog in hueco (or lado_abuela, the same point) against abuela and Luis
  {
    const bad = [], per = [], all = [], hints = [], info = [], hueco = S['hueco'].uv.join(',');
    const exempt = (a, b) => {
      if ((a.row === 'atras') !== (b.row === 'atras')) return 'back row against the seat or the ground in front';
      const inGap = l => l.who === 'coqui' && l.uvz.join(',') === hueco, sitter = l => l.at === 'asiento1' || l.at === 'asiento2';
      if ((inGap(a) && sitter(b)) || (inGap(b) && sitter(a))) return 'the frog in hueco against abuela or Luis';
      return null;
    };
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN, ex = exempt(a, b);
        const rec = { m, a: a.at, b: b.at, dx, dy, half, over, ok, ex }; all.push(rec);
        const txt = 'moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + ')';
        if (!ok && ex) info.push(txt + ' (' + ex + ')');
        else if (!ok) { hints.push({ m, a, b, half }); bad.push(txt + ': short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const counted = all.filter(q => !q.ex);
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {                                                            // the least shift of a spot in u, in v or in z that passes
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, counted.length + ' pairs counted (' + (all.length - counted.length) + ' more not counted) in the 7 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the counted pairs that do overlap sideways: ' + (counted.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + counted.length + ' counted pairs in 7 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) if (S[h.a.at] && S[h.b.at]) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest counted pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = counted.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    for (const t of info) o.lines.push('       info, not counted: ' + t);
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok, notCounted: q.ex }));
  }

  // 6. frog-seen: the frog is never behind a grown-up, a car or a guagua: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer person); a nearer dog is information (frog-places gives it its own rule)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi];
      const best = new Map();                                                                    // per pixel: the nearest shown sprite pixel of the other layers
      L.forEach((l, i) => { if (i === fi) return; for (const p of l.px) if (!p[2]) { const k = p[1] * G.W + p[0], b = best.get(k); if (!b || b.plane < p[3]) best.set(k, { plane: p[3], at: l.at, who: l.who }); } });
      let hid = 0, cov = 0, dog = 0; const by = {}, out = f.out;
      for (const p of f.px) { if (p[2]) { hid++; continue; } const b = best.get(p[1] * G.W + p[0]); if (b && b.plane > p[3] + EPS) { if (b.who === 'perro') dog++; else { cov++; by[b.at] = (by[b.at] || 0) + 1; } } }
      let boxCov = 0;                                                                            // information: the pixels of his 32 x 25 box where another sprite is nearer than he is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; const b = best.get(y * G.W + x); if (b && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) boxCov++; }
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + out) + ' px, ' + hid + ' hidden by the set, ' + cov + ' under a nearer person' + (cov ? ' (' + Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ') + ')' : '') + ', ' + out + ' outside the picture, ' + dog + ' under the dog; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      if (hid || cov || out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (hid + cov + out) + ' of his ' + (f.px.length + out) + ' px are not seen (' + hid + ' hidden by the set, ' + cov + ' under ' + (Object.keys(by).join(', ') || 'a person') + ', ' + out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 7 moments (a nearer dog aside): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[specs[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 7. frog-places: the frog's four places, with the family in place (moment 5's: abuelo, mamá with the bebé held up, Carmen, abuela, Luis, Canelo lying, papá at papa_camara) in the plaza window:
  //    at delante_canelo, lado_abuela and delante_abuela he is seen whole; at detras_canelo 60% or more of him shows (his pixels not hidden by the set, not outside the picture, not under a sprite nearer than he is)
  {
    const NEED = { detras_canelo: .6 };
    const M5 = PV.moment[5], family = M5.layers.filter(l => l.who !== 'coqui'), bad = [], lines = [], fails = [], res = [];
    for (const k of FROG_PLACES) {
      const specs = family.concat([{ at: k, s: 'coqui', who: 'coqui' }]), L = await PV.layers(M5.set, specs), fi = L.length - 1, f = L[fi];
      const best = new Map();
      L.forEach((l, i) => { if (i === fi) return; for (const p of l.px) if (!p[2]) { const kk = p[1] * G.W + p[0], b = best.get(kk); if (!b || b.plane < p[3]) best.set(kk, { plane: p[3], at: l.at }); } });
      let hid = 0, cov = 0; const by = {}, out = f.out;
      for (const p of f.px) { if (p[2]) { hid++; continue; } const b = best.get(p[1] * G.W + p[0]); if (b && b.plane > p[3] + EPS) { cov++; by[b.at] = (by[b.at] || 0) + 1; } }
      const total = f.px.length + out, shown = total - hid - cov - out, need = NEED[k] || 1, ok = shown >= need * total - 1e-9;
      const box = T[k].box, x0 = V.plaza.x0, inside = box[0] >= x0 && box[0] + box[2] <= x0 + 196 && box[0] >= 0 && box[0] + box[2] <= G.W;
      res.push({ place: k, px: total, shown, hiddenBySet: hid, underSprites: cov, outsidePicture: out, by, needShown: need, boxInsideWindow: inside });
      const why = hid + cov + out + ' of ' + total + ' px not seen (' + hid + ' hidden by the set, ' + cov + ' under ' + (Object.keys(by).join(', ') || 'sprites') + ', ' + out + ' outside the picture)';
      lines.push(k + ' ' + [f.sx, f.sy] + ': ' + shown + ' of ' + total + ' px show (' + Math.round(100 * shown / total) + '%, needs ' + Math.round(100 * need) + '%): ' + why + '; box ' + (inside ? 'inside' : 'OUTSIDE') + ' the window');
      if (!ok || !inside) { bad.push(k + ' ' + [f.sx, f.sy] + ': ' + shown + ' of ' + total + ' px show (' + Math.round(100 * shown / total) + '%, needs ' + Math.round(100 * need) + '%): ' + why + (inside ? '' : '; its box [' + box + '] is outside the plaza window [' + x0 + ', ' + (x0 + 196) + ') or the picture')); if (!ok) fails.push([k, specs, fi, 1 - need]); }
    }
    const o = add('frog-places', bad, 'the frog is seen whole at delante_canelo, lado_abuela and delante_abuela and 60% or more of him shows at detras_canelo, with the family in place (moment 5\'s, papá at papa_camara): ' + lines.join('; '), [bad.length + ' of the 4 places fail in the plaza window:'].concat(bad.map(b => '  ' + b)));
    for (const [k, specs, fi, allow] of fails) {
      const r = await PV.nearest(M5.set, specs, fi, allow);
      o.lines.push('       nearest passing, ' + k + ' ' + S[k].uv + ': ' + (['u', 'v', 'z'].map((a, i) => r.axis[a] ? a + ' ' + S[k].uv[i] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: each place: ' + lines.join('; '));
    {                                                                                       // tras_papa: the frog behind papá: papá's legs cover part of him, that is meant: the pixels that show
      const specs = family.concat([{ at: 'tras_papa', s: 'coqui', who: 'coqui' }]), L = await PV.layers(M5.set, specs), f = L[L.length - 1], best = new Map();
      L.forEach((l, i) => { if (i === L.length - 1) return; for (const p of l.px) if (!p[2]) { const kk = p[1] * G.W + p[0], b = best.get(kk); if (!b || b.plane < p[3]) best.set(kk, { plane: p[3], at: l.at }); } });
      let hid = 0, cov = 0; const by = {};
      for (const p of f.px) { if (p[2]) { hid++; continue; } const b = best.get(p[1] * G.W + p[0]); if (b && b.plane > p[3] + EPS) { cov++; by[b.at] = (by[b.at] || 0) + 1; } }
      const total = f.px.length + f.out, shown = total - hid - cov - f.out, rows = f.px.filter(p => !p[2] && !(best.get(p[1] * G.W + p[0]) && best.get(p[1] * G.W + p[0]).plane > p[3] + EPS)).map(p => p[1]);
      o.lines.push('       info, not a check: the frog at tras_papa ' + [f.sx, f.sy] + ' behind papá at papa_camara ' + S['papa_camara'].screen + ' (the family of moment 5 in place): ' + shown + ' of ' + total + ' px show (' + Math.round(100 * shown / total) + '%): ' + hid + ' hidden by the set, ' + cov + ' under ' + (Object.keys(by).join(', ') || 'sprites') + ', ' + f.out + ' outside the picture; the pixels that show lie in rows ' + (rows.length ? Math.min(...rows) + ' to ' + Math.max(...rows) : 'none') + ' (his rows ' + Math.min(...f.px.map(p => p[1])) + ' to ' + Math.max(...f.px.map(p => p[1])) + ')');
      o.traspapa = { px: total, shown, underSprites: cov, by };
    }
    o.places = res;
  }

  // 8. family-heads: every head of the back row (abuelo, mamá, Carmen) shows 100 px or more (the top 14 rows of the sprite: the pixels the set does not hide and no nearer sprite covers: above whoever sits in front) in moments 5 to 7.
  //    The bodies of the back row may be hidden by those on the seat; the others' heads are information
  {
    const HEAD_MIN = 100, BACK = ['fila_atras1', 'fila_atras2', 'fila_atras3'];
    const bad = [], lines = [], res = [];
    for (const m of [5, 6, 7]) {
      const L = PV.inspect[m].layers, best = new Map();
      L.forEach((l, i) => { for (const p of l.px) if (!p[2]) { const kk = p[1] * G.W + p[0], b = best.get(kk) || []; b.push({ plane: p[3], at: l.at, i }); best.set(kk, b); } });
      for (const [i, a] of L.entries()) {
        if (a.group !== 'familia' || a.who === 'perro') continue;
        const top = Math.min(...a.px.map(p => p[1])); let tot = 0, shown = 0, cov = 0; const by = {};
        for (const p of a.px) {
          if (p[1] >= top + HEAD_ROWS) continue;
          tot++; if (p[2]) continue; shown++;
          for (const b of best.get(p[1] * G.W + p[0]) || []) if (b.i !== i && b.plane > p[3] + EPS) { cov++; by[b.at] = (by[b.at] || 0) + 1; break; }
        }
        const see = shown - cov, back = BACK.includes(a.at);
        res.push({ moment: m, at: a.at, backRow: back, headPx: tot, hiddenBySet: tot - shown, coveredBySprites: cov, shows: see });
        lines.push('m' + m + ' ' + a.at + ' ' + [a.sx, a.sy] + (back ? ' (back row)' : '') + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ': ' + see + ' of ' + tot + ' px show (' + (tot - shown) + ' hidden by the set, ' + cov + ' covered' + (cov ? ' by ' + Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ') : '') + ')');
        if (back && see < HEAD_MIN) bad.push('moment ' + m + ' ' + a.at + ': its head shows ' + see + ' of ' + tot + ' px (needs ' + HEAD_MIN + '): ' + (tot - shown) + ' hidden by the set, ' + cov + ' covered by ' + (Object.keys(by).join(', ') || 'sprites'));
      }
    }
    const o = add('family-heads', bad, 'the head of each of the back row shows ' + HEAD_MIN + ' px or more in moments 5, 6 and 7: ' + lines.filter(l => l.includes('(back row)')).join('; '), [bad.length + ' head(s) of the back row show fewer than ' + HEAD_MIN + ' px (the top ' + HEAD_ROWS + ' rows):'].concat(bad.map(b => '  ' + b)));
    for (const l of lines) o.lines.push('       ' + l);
    o.heads = res;
  }

  // 9. centro-stripes: a person at `centro` covers no part of the stripes' lower half, where the frog stands (moment 2: coqui.cruce)
  {
    const bad = [], lines = [], st = probes.stripes, cut = G.E.HW + STRIPES.half, low = new Set(st.px.filter(p => p[2] >= cut).map(p => p[1] * G.W + p[0]));
    const rows = st.px.filter(p => p[2] >= cut).map(p => p[1]), r0 = Math.min(...rows), r1 = Math.max(...rows), cols = st.px.filter(p => p[2] >= cut).map(p => p[0]);
    for (const m of [1, 2, 3]) {
      const L = PV.inspect[m].layers, cs = L.filter(l => l.at === 'centro'), frog = L.find(l => l.who === 'coqui');
      for (const c of cs) {
        const shown = c.px.filter(p => !p[2]), on = shown.filter(p => low.has(p[1] * G.W + p[0])), lowest = Math.max(...shown.map(p => p[1]));
        const fr = new Set(frog.px.filter(p => !p[2]).map(p => p[1] * G.W + p[0])), onFrog = shown.filter(p => fr.has(p[1] * G.W + p[0])).length;
        const ftop = Math.min(...frog.px.map(p => p[1]));
        lines.push('m' + m + ' ' + c.at + ' ' + c.s + ' (sprite feet at row ' + c.sy + ', lowest shown row ' + lowest + '): ' + on.length + ' px on the stripes\' lower half (the frog at ' + frog.at + ' ' + [frog.sx, frog.sy] + ' has its top at row ' + ftop + ', ' + (ftop - lowest - 1) + ' rows below him; ' + onFrog + ' px of the two overlap)');
        if (on.length) bad.push('moment ' + m + ' ' + c.at + ' ' + c.s + ': ' + on.length + ' px on the stripes\' lower half');
      }
    }
    const o = add('centro-stripes', bad, 'a person at centro covers none of the ' + low.size + ' pixels of the stripes\' lower half (v ' + r2(cut) + ' to ' + r2(G.E.HW + .9) + ': rows ' + r0 + ' to ' + r1 + ', columns ' + Math.min(...cols) + ' to ' + Math.max(...cols) + ') in moments 1 to 3: ' + lines.join('; '), ['a person at centro over the stripes:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 10. salida-whole: somebody leaving by each street is seen whole until the picture's edge: a grown-up walks from the crossing's middle along the street's middle line to where all of him is out of the picture; at every step (.05)
  //     none of his pixels inside the picture is hidden by the set
  {
    const bad = [], lines = [], N = x => Math.ceil(x / WALK_STEP);
    const WALKS = [['salida_izq', 'the street to the left', [0, 0, 0], [-4.4, 0, 0], N(4.4), [0, 1]], ['salida_der', 'the street to the right', [0, 0, 0], [6.2, 0, 0], N(6.2), [0]], ['salida_recta', 'the street straight on', [0, 0, 0], [0, -9.4, 0], N(9.4), [0, 1]]];
    for (const [spot, name, a, b, n, cerr] of WALKS) for (const c of cerr) {
      const st = { hora: 'mediodia', cerrada: c }, w = await PV.walk(st, 'senor', 'adulto', a, b, n);
      const worst = w.reduce((x, y) => (y.hidden > x.hidden ? y : x), w[0]), hid = w.filter(p => p.hidden), at = w.find(p => p.sx === S[spot].screen[0] || false);
      const gone = w.findIndex(p => p.inside === 0), last = gone < 0 ? w[w.length - 1] : w[gone];
      lines.push(name + ' (cerrada ' + c + '): ' + w.length + ' steps from (0, 0) to ' + (gone < 0 ? 'the end of the walk' : 'where nothing of him is inside the picture, at ' + last.uvz) + '; ' + (hid.length ? hid.length + ' step(s) with pixels hidden, most ' + worst.hidden + ' at ' + worst.uvz + ' (feet ' + [worst.sx, worst.sy] + ')' : 'no pixel hidden at any step'));
      if (hid.length) {
        const f0 = hid[0], i0 = w.indexOf(f0), L = await PV.layers(st, [{ uvz: f0.uvz, s: 'senor', who: 'adulto' }]), hp = L[0].px.filter(q => q[2]).map(q => [q[0], q[1]]), tg = await probes.tags(hp), by = {};
        for (const t of tg) by[t] = (by[t] || 0) + 1;
        bad.push(name + ' (cerrada ' + c + '): first hidden at ' + f0.uvz + ' (feet ' + [f0.sx, f0.sy] + '): ' + f0.hidden + ' of his pixels hidden by part ' + Object.entries(by).map(([t, n]) => t + ' ' + n).join(', ') + '; the last whole step before it is ' + (i0 ? w[i0 - 1].uvz : 'none') + '; most hidden ' + worst.hidden + ' at ' + worst.uvz + '; ' + hid.length + ' step(s) in all, to ' + hid[hid.length - 1].uvz + ' (the street runs to the picture\'s edge at ' + (b[0] > 0 ? 'u ' + r2((G.W - G.OX) / G.S) : b[0] < 0 ? 'u ' + r2(-G.OX / G.S) : 'v ' + r2(-G.OY / (G.S * .5))) + ')');
      }
    }
    const o = add('salida-whole', bad, 'somebody leaving by each street is seen whole until the picture\'s edge: ' + lines.join('; ') + (' (with cerrada = 1 the right street is shut by the cones: nobody leaves by it)'), ['somebody leaving by a street is hidden by the set:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // info: how the spec's own rules apply here
  OUTS.push({ name: 'info-street', ok: true, lines: ['info-street: not a check. "Nobody stands on the street unless this spec puts him there": in this scene people walk on the roadway (the spec says so), so no spot is kept off it. "A person at a door": there is no door.'] });
  return OUTS;
}
