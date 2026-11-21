#!/usr/bin/env node
'use strict';
/* La sombrilla's sheet: writes docs/proyecto/pixel/sombrilla-sheet.json from sombrilla-set.html and the design (the orchestrator's p7-spec, section "sombrilla"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/sombrilla-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S. The set's numbers (the blanket, the face and the figure, FACE_AT) are read from the set
   (window.SOMBRILLA.E and FACE_AT), never typed again from the design.
   It loads the set in headless Chrome (sombrilla-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. Nothing in this set sways (no palm, no frond): frame(0) is the whole picture. The sprites' silhouettes come from the preview's own makers (today's historia/engine.js and
   escenas/kit.js, and the plain stand-ins drawn in sombrilla-preview.html: PREVIEW.sil). The checks that say "covers" or "shows" read the PREVIEW's moments (sombrilla-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with SOMBRILLA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'sombrilla-sheet.json');
const BASE = process.env.SOMBRILLA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/sombrilla-set.html';
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
const COS = Math.sqrt(3) / 2;

// the numbers of the design (p7-spec: the rules for every sheet, and "sombrilla")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const FACE_BOX = { w: 14, h: 10 };                       // ojo_izq, ojo_der, nariz, boca: 14 x 10 boxes centred on FACE_AT
const ARM_H = 6, HAND = { w: 12, h: 10 }, FOOT = { w: 12, h: 8 };            // an arm's box is 6 px high; a hand 12 x 10; a foot 12 x 8
const SIZE = { cubo75: [12, 12], concha: [5, 5], caracoles: [28, 8], pieza: [16, 12], bola: [9, 9] };      // the bucket 12 x 12; a shell of the face 5; three spirals 8 px each (28 wide with a 2 px gap: mine); a thing in the row 16 x 12; the ball (no size in the spec: the cielo's 9 x 9)
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STATES = [];
for (const dibujo of ['circulo', 'figura']) for (const hora of ['mediodia', 'tarde', 'sol']) STATES.push({ hora, dibujo });
const FACE_NAMES = ['ojo_izq', 'ojo_der', 'nariz', 'boca'];
const SIL_OF = { abuelaL: 'abuelaL', abuelaP: 'abuelaP', abuela: 'abuela', nino: 'luis', coqui: 'coqui', perro: 'perro' };     // the sheet's drawing names -> the preview's sprite makers
let SIL = null;

/* the spots: { name, uvz, kind, sil, who, what, size, anchor }
   kind: person (a character stands there), place (the frog's), thing (a small thing: shells, the bucket, the row of three things)
   sil: which drawing hangs there: abuelaL (abuela lying), abuelaP (abuela sitting on the blanket, mkAbuelaS with her legs out), abuela (standing), nino (Luis, Carmen), coqui, perro (Canelo, head down)
        an array when the spot takes more than one (the first is the one the preview draws first)
   anchor (small things): bottom = its bottom middle on the point, centre = its middle */
function defs(E, FA) {
  const D = [];
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  const ABU = ['abuelaP', 'abuelaL'];
  add('manta', [-1.55, 2.0, 0], 'person', ABU, 'adulto', 'abuela, lying or sitting, on the blanket in the umbrella\'s shade (stories 75 to 77)');
  add('manta2', [-1.75, 2.6, 0], 'person', ABU, 'adulto', 'a second place for abuela on the blanket in the shade (77 ending: she lies here, out of the game)');
  add('manta3', [-0.8, 2.55, 0], 'person', ABU, 'adulto', 'a third place for abuela on the blanket in the shade');
  // story 75 (dibujo circulo)
  add('luis.cara', [-1.15, 5.1, 0], 'person', 'nino', 'nino', 'Luis, left of the circle (75)');
  add('carmen.cara', [3.3, 5.1, 0], 'person', 'nino', 'nino', 'Carmen, right of the circle (75)');
  add('coqui.cara', [1.05, 7.7, 0], 'place', 'coqui', 'coqui', 'the frog, below the circle (75)');
  add('cubo75', [2.2, 7.6, 0], 'thing', null, null, 'his bucket of shells (a ' + SIZE.cubo75.join(' x ') + ' px stand-in)', { size: SIZE.cubo75, anchor: 'bottom' });
  for (const n of FACE_NAMES) add(n, [FA[n][0], FA[n][1], 0], 'thing', null, null, 'the place of the face\'s ' + { ojo_izq: 'left eye', ojo_der: 'right eye', nariz: 'nose', boca: 'mouth' }[n] + ' (SOMBRILLA.FACE_AT.' + n + '): a ' + SIZE.concha.join(' x ') + ' px shell is pressed in here, centred on the point; the touch box is things.' + n, { size: SIZE.concha, anchor: 'centre' });
  // story 76 (dibujo figura)
  add('luis.figura', [-0.3, 3.0, 0], 'person', 'nino', 'nino', 'Luis, behind the figure\'s head, left (76)');
  add('carmen.figura', [2.6, 2.6, 0], 'person', 'nino', 'nino', 'Carmen, behind the figure\'s head, right (76)');
  add('coqui.figura', [-1.3, 7.8, 0], 'place', 'coqui', 'coqui', 'the frog, below the figure at the left (76)');
  add('caracoles', [-1.2, 5.9, 0], 'thing', null, null, 'the three spiral shells in a row (8 px each, centres 10 px apart: a ' + SIZE.caracoles.join(' x ') + ' px row, its bottom middle on the point; the spec gives no gap: mine)', { size: SIZE.caracoles, anchor: 'bottom' });
  add('perro', [-2.1, 6.3, 0], 'person', 'perro', 'perro', 'Canelo, sniffing at the row of spiral shells (76)');
  add('hoyo', [-3.0, 7.2, 0], 'person', 'perro', 'perro', 'Canelo digging (76 after a miss)');
  // story 77 (dibujo figura)
  add('sol1', [-0.6, 9.6, 0], 'person', 'abuela', 'adulto', 'player 1 in the sun (abuela, 77 opening)');
  add('sol2', [1.05, 10.3, 0], 'person', 'nino', 'nino', 'player 2 in the sun (Luis, with the ball)');
  add('sol3', [2.7, 9.6, 0], 'person', 'nino', 'nino', 'player 3 in the sun (Carmen)');
  add('coqui.bolsa', [-2.4, 8.0, 0], 'place', 'coqui', 'coqui', 'the frog, beside abuela\'s bag (77)');
  for (const [n, u, w] of [['sombreros', -2.6, 'the sun hats'], ['gafas', -1.9, 'the dark glasses'], ['chancletas', -1.2, 'the sandals']]) add(n, [u, 6.0, 0], 'thing', null, null, w + ': one of the three things in a row on the sand in front of the bag (a ' + SIZE.pieza.join(' x ') + ' px stand-in, its bottom middle on the point)', { size: SIZE.pieza, anchor: 'bottom' });
  return D;
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-ground (each spot is on the sand, the blanket's spots on the blanket),
   things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), no-seat (nobody sits on a seat here),
   face-clear (75: nobody covers a face box), figure-clear (76: nobody covers the head, an arm or a hand), feet-things-clear (77 opening: nobody covers the feet or the three things),
   players-whole (the players at sol1 to sol3 are whole), abuela-manta (abuela's place is inside the blanket; info: the umbrella's shade).
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  SIL = await silhouettes(browser, errs);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(SOMBRILLA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, FA: SOMBRILLA.FACE_AT, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs);
  const results = await checks(sheet, G, probes, PV, page);
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

/* ---------- the sprites' silhouettes: [dx0, dy0, dx1, dy1] of each drawn pixel from the anchor column and the anchor row (dy -1 is the feet's row), read from the preview's makers (its sheet is a stub: PREVIEW.sil needs none) ---------- */
async function silhouettes(browser, errs) {
  const sp = await browser.newPage();
  sp.on('pageerror', e => errs.push('silhouettes: ' + String(e)));
  await sp.route(BASE + '/**', serve);
  await sp.route(BASE + '/docs/proyecto/pixel/sombrilla-sheet.json', r => r.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
  await sp.goto(BASE + '/docs/proyecto/pixel/sombrilla-preview.html?nodraw=1');
  await sp.evaluate(() => window.PREVIEW.done);
  const o = {};
  for (const [k, v] of Object.entries(SIL_OF)) o[k] = await sp.evaluate(n => window.PREVIEW.sil(n), v);
  await sp.close();
  return o;
}

/* ---------- the preview's moments: sombrilla-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/sombrilla-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  PV.nearestOutside = (st, specs, idx, boxes) => p.evaluate(x => window.PREVIEW.nearestOutside(x.st, x.specs, x.idx, x.boxes), { st, specs, idx, boxes });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];
// the box of a small thing on its point
const boxOn = (sx, sy, size, anchor) => {
  const [w, h] = size, x = sx - Math.floor(w / 2);
  return [x, anchor === 'bottom' ? sy - h : sy - Math.floor(h / 2), w, h];
};
const silsOf = s => (s.sprites || (s.sprite ? [s.sprite] : [])).map(k => SIL[k]);
// the columns a spot's sprite (a person: his sprite box, the feet's spot in the middle, and the drawn silhouette if it is wider; a small thing: its box) takes: [first, last]
const colsOf = s => {
  if (s.who) { let a = s.screen[0] - WIDTH[s.who] / 2, b = s.screen[0] + WIDTH[s.who] / 2 - 1; for (const q of silsOf(s)) { a = Math.min(a, s.screen[0] + q.box[0]); b = Math.max(b, s.screen[0] + q.box[2]); } return [a, b]; }
  return s.box ? [s.box[0], s.box[0] + s.box[2] - 1] : [s.screen[0], s.screen[0]];
};
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj) {
  const E = G.E, FA = G.FA, sc = G.scene, DEF = defs(E, FA);
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) { const a = [].concat(d.sil); o.sprite = a[0]; if (a.length > 1) o.sprites = a; }
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = 'ground';
    spots[d.name] = o;
  });

  /* ---- the view: x0 so that every spot is inside the picture and the window ---- */
  const held = Object.entries(spots);
  const ext = held.map(([, s]) => colsOf(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0) && colsOf(s)[0] >= 0 && colsOf(s)[1] <= G.W - 1)) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [75, 76, 77], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 75, 76 and 77: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment is inside it (a person with his sprite whole, a small thing with its box whole). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async (corners) => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  // something flat on the ground (z0 = z1) or a wall's plane: the screen bounding box of its projected corners
  const setThing = async (u0, v0, z0, u1, v1, z1, what) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    return { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
  };
  // a thing given as a pixel box on the sand (z 0): its uv rectangle and world box are the box's corners put back on the ground
  const pxThing = async (box, what, more) => {
    const [bx, by, bw, bh] = box, u0 = (bx - G.OX) / G.S, u1 = (bx + bw - G.OX) / G.S, v0 = (by - G.OY) / (G.S / 2), v1 = (by + bh - G.OY) / (G.S / 2);
    const q = await proj([[u0, v0, 0], [u1, v0, 0], [u1, v1, 0], [u0, v1, 0]]);
    return Object.assign({ set: true, uv: W4([u0, v0, 0, u1, v1, 0]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), 0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), 0]), box, what }, more);
  };
  const sxOf = u => Math.round(G.OX + u * G.S), syOf = v => Math.round(G.OY + v * .5 * G.S);       // a point on the sand (z 0), rounded to a pixel
  const F = E.FACE, FG = E.FIG, things = {};
  things.cara = await setThing(F.u - F.r, F.v - F.r, 0, F.u + F.r, F.v + F.r, 0, 'the circle drawn on the damp sand (dibujo circulo): the box of its circle, middle (u ' + F.u + ', v ' + F.v + '), radius ' + F.r + '; a poke');
  const qf = await proj(FACE_NAMES.map(n => [FA[n][0], FA[n][1], 0]));
  for (const [i, n] of FACE_NAMES.entries()) {
    const sx = Math.round(qf[i][0]), sy = Math.round(qf[i][1]);
    things[n] = await pxThing([sx - FACE_BOX.w / 2, sy - FACE_BOX.h / 2, FACE_BOX.w, FACE_BOX.h], 'the place of the face\'s ' + { ojo_izq: 'left eye', ojo_der: 'right eye', nariz: 'nose', boca: 'mouth' }[n] + ': a ' + FACE_BOX.w + ' x ' + FACE_BOX.h + ' px box centred on SOMBRILLA.FACE_AT.' + n + ' (u ' + r4(FA[n][0]) + ', v ' + r4(FA[n][1]) + '); a poke', { place: true, screen: [sx, sy], size: [FACE_BOX.w, FACE_BOX.h] });
  }
  things.cabeza = await setThing(FG.u - FG.head[1], FG.head[0] - FG.head[1], 0, FG.u + FG.head[1], FG.head[0] + FG.head[1], 0, 'the figure\'s head (dibujo figura): the box of its circle, middle (u ' + FG.u + ', v ' + FG.head[0] + '), radius ' + FG.head[1] + '; a poke');
  // each arm: from the body (u FIG.u) to its hand (u FIG.u -+ armLen) along v FIG.arms, a box 6 px high centred on the line; izq is the one at the left of the picture
  const ay = syOf(FG.arms), xb = sxOf(FG.u), xl = sxOf(FG.u - FG.armLen), xr = sxOf(FG.u + FG.armLen);
  things.brazo_izq = await pxThing([xl, ay - ARM_H / 2, xb - xl, ARM_H], 'the figure\'s left arm (the one at the left of the picture): the line from the body (u ' + FG.u + ') to its hand (u ' + r4(FG.u - FG.armLen) + ') at v ' + FG.arms + ', a box ' + ARM_H + ' px high centred on it; a poke');
  things.brazo_der = await pxThing([xb, ay - ARM_H / 2, xr - xb, ARM_H], 'the figure\'s right arm: the line from the body (u ' + FG.u + ') to its hand (u ' + r4(FG.u + FG.armLen) + ') at v ' + FG.arms + ', a box ' + ARM_H + ' px high centred on it; a poke');
  // each hand: a 12 x 10 box at the arm's end, on the outer side (the five short lines go outward: .46 = 12 px), centred on the arm's line
  things.mano_izq = await pxThing([xl - HAND.w, ay - HAND.h / 2, HAND.w, HAND.h], 'the figure\'s left hand: a ' + HAND.w + ' x ' + HAND.h + ' px box with its inner edge at the arm\'s end (u ' + r4(FG.u - FG.armLen) + '), going outward, centred on the arm\'s line; a poke');
  things.mano_der = await pxThing([xr, ay - HAND.h / 2, HAND.w, HAND.h], 'the figure\'s right hand: a ' + HAND.w + ' x ' + HAND.h + ' px box with its inner edge at the arm\'s end (u ' + r4(FG.u + FG.armLen) + '), going outward, centred on the arm\'s line; a poke');
  // the feet: one thing, two 12 x 8 boxes, each with its inner edge at the leg's end, going outward, centred on the foot's line (v FIG.legs[1])
  const fy = syOf(FG.legs[1]), fl = sxOf(FG.u - FG.legDu), fr = sxOf(FG.u + FG.legDu), foot = [[fl - FOOT.w, fy - FOOT.h / 2, FOOT.w, FOOT.h], [fr, fy - FOOT.h / 2, FOOT.w, FOOT.h]];
  things.pies = await pxThing([foot[0][0], foot[0][1], foot[1][0] + FOOT.w - foot[0][0], FOOT.h], 'the figure\'s two feet at the legs\' ends (u ' + r4(FG.u - FG.legDu) + ' and ' + r4(FG.u + FG.legDu) + ', v ' + FG.legs[1] + '): one thing, two ' + FOOT.w + ' x ' + FOOT.h + ' px boxes (boxes), each with its inner edge at the leg\'s end, going outward; box is the two together; a poke', { boxes: foot });
  for (const k of ['sombreros', 'gafas', 'chancletas', 'caracoles', 'luis', 'carmen', 'abuela', 'coqui', 'perro', 'bola']) things[k] = 'sprite';
  const bl = E.BLANKET, blanket = await setThing(bl[0], bl[1], .03, bl[2], bl[3], .03, 'the blanket in the umbrella\'s shade (E.BLANKET: u ' + bl[0] + ' to ' + bl[2] + ', v ' + bl[1] + ' to ' + bl[3] + ', its top at z .03): not a thing he touches; abuela\'s place (manta) is inside it');

  return {
    scene: 'sombrilla',
    made: 'node docs/proyecto/pixel/sombrilla-sheet-make.js, from sombrilla-set.html (window.SOMBRILLA.E and FACE_AT) and the design of La sombrilla (the orchestrator\'s p7-spec, section sombrilla). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the water\'s edge at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S) + ' and v (on the sand) from ' + r2((0 - G.OY) / (G.S / 2)) + ' to ' + r2((G.H - G.OY) / (G.S / 2)),
      spot: 'a spot is a world point of the feet (z 0: the sand; the blanket\'s top is z .03, under 1 px: the spec\'s z 0 is kept) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): the bucket, the row of three spiral shells and the three things in the row have their bottom middle on the spot; a shell of the face is centred on its place (the touch box of the place is things.<name>, 14 x 10). The ball has no spot: it is held (the preview draws it at Luis\'s side). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 41 rows drawn standing for a child (Luis, Carmen); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51, engine.js): column 30; abuela sitting on the blanket: mkAbuelaS (52 x 50) with pies (her legs out in front, to the right), column 17 and her lowest drawn row on sy; abuela lying: a plain stand-in (52 x 18, no maker yet: the spec gives no size), her middle column on sx and her lowest row on sy, head at the left; Canelo mkPerro(\'husmea\') (30 x 22), head down, sniffing or digging: column 15 and its bottom edge; a small thing: see spot. Nobody is turned (the makers draw them from the front)',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      face: 'ojo_izq, ojo_der, nariz, boca: 14 x 10 boxes centred on SOMBRILLA.FACE_AT (the eyes at u ' + r4(FA.ojo_izq[0]) + ' and ' + r4(FA.ojo_der[0]) + ', v ' + r4(FA.ojo_izq[1]) + '; the nose v ' + r4(FA.nariz[1]) + '; the mouth v ' + r4(FA.boca[1]) + '): the box is [sx - 7, sy - 5, 14, 10]; a shell is 5 px, centred on the point',
      figure: 'cabeza and cara are the boxes of their circles; brazo_izq / brazo_der: from the body to the hand along the arms\' line, 6 px high; mano_izq / mano_der: 12 x 10, inner edge at the arm\'s end, going outward; pies: two 12 x 8 boxes, inner edge at the leg\'s end (u ' + r4(FG.u - FG.legDu) + ' and ' + r4(FG.u + FG.legDu) + ' at v ' + FG.legs[1] + '), going outward. izq is the one at the left of the picture',
    },
    setKey: {
      params: { hora: { values: ['mediodia', 'tarde', 'sol'], note: '75 mediodia, 76 tarde, 77 sol (the hottest hour, hard and bright light)' }, dibujo: { values: ['circulo', 'figura'], note: 'what is drawn on the damp sand: 75 circulo (the big circle), 76 and 77 figura (head, arms, hands, body, legs, feet)' } },
      key: 'hora + dibujo, e.g. "mediodia-circulo"',
      used: ['?hora=mediodia&dibujo=circulo', '?hora=tarde&dibujo=figura', '?hora=sol&dibujo=figura'],
      baked: STATES.map(s => '?hora=' + s.hora + '&dibujo=' + s.dibujo),
    },
    things,
    blanket,
    spots,
    groups: {
      manta: ['manta', 'manta2', 'manta3'], cara: ['luis.cara', 'carmen.cara', 'coqui.cara', 'cubo75'], cara_lugares: FACE_NAMES, figura: ['luis.figura', 'carmen.figura', 'coqui.figura', 'caracoles', 'perro', 'hoyo'],
      sol: ['sol1', 'sol2', 'sol3', 'coqui.bolsa'], fila: ['sombreros', 'gafas', 'chancletas'],
    },
    notes: [
      'every number of a spot is the orchestrator\'s (the p7-spec, "sombrilla"), given in (u, v, z); the blanket, the face (FACE_AT) and the figure (FIG) are read from the set',
      'the spec gives no size for abuela lying (a plain 52 x 18 stand-in used), no gap for the three spiral shells (8 px each, centres 10 px apart: a 28 x 8 row), no size for the ball (the cielo\'s 9 x 9) and no spot for it (the preview holds it at Luis\'s side), no place for the frog in moment 6 (coqui.bolsa used) and no shadow radii (El cruce\'s: frog .45, grown-ups .35, children .28, the dog .3): open points',
      'izq / der of the arms, hands and eyes are the left and the right of the PICTURE; a hand\'s and a foot\'s box lies outward of the arm\'s or leg\'s end (the spec gives the size, not which side of the end)',
      'abuela sitting on the blanket is mkAbuelaS with her legs out in front (pies): the maker\'s only pose for sitting on the ground; abuela lying is a stand-in',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the umbrella\'s canopy hides whoever is behind it. Nothing in this set sways (no palm, no frond), so the baked depth is the whole depth.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as La plaza\'s sheets: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, abuela: .35, luis: .28, carmen: .28, perro: .3 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the sand (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28, the dog .3) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      lying: 'abuela lying casts none of her own: she is in the umbrella\'s shade',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the part and the kind of ground), and the umbrella's cast shadow (rebuilt once with a hook on applyShadows: where the shadow mask is set, before the ground filter)
  return page.evaluate(arg => {
    const o = { spots: {}, shade: [] };
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -1; dy <= 0; dy++) { const X = s.screen[0], Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X; rows.push({ dy, tag: TAGS[i], ground: ground[i], kind: kinds[i], sand: kinds[i] === KIND_SAND }); }
      o.spots[k] = rows;
    }
    const orig = window.applyShadows, seen = new Uint8Array(W * H);
    window.applyShadows = refZ => { for (let i = 0; i < seen.length; i++) if (shadowMask[i]) seen[i] = 1; return orig(refZ); };
    try { buildSet(); } finally { window.applyShadows = orig; }
    o.shade = Array.from(seen);
    buildSet(); frame(0);                                                       // leave the page as it was
    o.parts = {};                                                               // the box of each part of the set (sombrilla, manta, cubo, algas, bolsa): [x0, y0, x1, y1]
    for (let i = 0; i < W * H; i++) { const t = TAGS[i]; if (!t) continue; const x = i % W, y = (i / W) | 0, b = o.parts[t] || (o.parts[t] = [x, y, x, y]); b[0] = Math.min(b[0], x); b[1] = Math.min(b[1], y); b[2] = Math.max(b[2], x); b[3] = Math.max(b[3], y); }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).map(([k, s]) => [k, { screen: s.screen }])));
}

function checks(sheet, G, probes, PV, page) { return checksAsync(sheet, G, probes, PV, page); }
async function checksAsync(sheet, G, probes, PV, page) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
  const inside = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  const axisHint = (r, uv, what) => ['u', 'v', 'z'].map((a, i) => r.axis[a] ? a + ' ' + uv[i] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  // a layer's name: its spot, and its drawing when it is not a person (the ball is held at sol2 beside Luis)
  const lab = l => l.at + (l.who ? '' : ' (' + l.s + ')');
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
      if (nearest) { cov++; const a = lab(L[nearest.i]); who[a] = (who[a] || 0) + 1; }
    }
    return { tot, hid, cov, who, out: l.out, top };
  };
  const whoTxt = c => Object.entries(c.who).map(([k, v]) => k + ' ' + v).join(', ');
  // the shown pixels of layer i inside a box
  const shownIn = (L, i, box) => L[i].px.filter(p => !p[2] && inside(box, p[0], p[1])).length;
  // the least Chebyshev distance (px) from a shown pixel of layer i to a box (0: inside it)
  const gapTo = (L, i, box) => { let g = 1e9; for (const p of L[i].px) if (!p[2]) { const dx = Math.max(box[0] - p[0], 0, p[0] - (box[0] + box[2] - 1)), dy = Math.max(box[1] - p[1], 0, p[1] - (box[1] + box[3] - 1)); g = Math.min(g, Math.max(dx, dy)); } return g; };
  const idxAt = (L, at) => { const w = L.findIndex(l => l.at === at && l.who); return w >= 0 ? w : L.findIndex(l => l.at === at); };
  const tag = (L, i) => L[i].at + (L[i].s ? ' (' + L[i].s + ')' : '');

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
    const cuts = Object.entries(probes.parts).map(([t, b]) => [t, b, Math.max(0, v.x0 - b[0]), Math.max(0, b[2] - (v.x0 + 195))]);
    o.lines.push('       the set\'s own parts against the window (info, not a check): ' + cuts.map(([t, b, l, r]) => t + ' columns ' + b[0] + ' to ' + b[2] + (l || r ? ' (cut ' + (l ? l + ' px at the left' : '') + (r ? r + ' px at the right' : '') + ')' : ' (whole)')).join('; '));
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24, the dog 28, and the drawn silhouette if it is wider; his rows from the drawn silhouette; a small thing's box)
  {
    const bad = [], info = [], names = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sils = silsOf(s);
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else if (sils.length) { top = sy + Math.min(...sils.map(q => q.box[1])); bottom = sy + Math.max(...sils.map(q => q.box[3])); } else { top = sy; bottom = sy; }
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      names.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length || picL || picR) bad.push(k + ' ' + s.screen + ': its ' + (s.who ? s.who + ' sprite' : 'box [' + s.box + ']') + ' is cut ' + (cut.concat([picL && 'by the picture\'s left edge ' + picL, picR && 'by the picture\'s right edge ' + picR].filter(Boolean))).join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ')');
      if (sils.length && s.who) info.push(k + ' ' + s.screen + ': ' + (s.sprites || [s.sprite]).map(n => n + ' drawn columns ' + (sx + SIL[n].box[0]) + ' to ' + (sx + SIL[n].box[2]) + ', rows ' + (sy + SIL[n].box[1]) + ' to ' + (sy + SIL[n].box[3])).join('; '));
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k];
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0], t = Object.assign({}, s, { screen: [sx, s.screen[1]] }); if (s.box) t.box = [s.box[0] + sx - s.screen[0], s.box[1], s.box[2], s.box[3]]; if (!cutAt(t, x0) && colsOf(t)[0] >= 0 && colsOf(t)[1] <= G.W - 1) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, names.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    o.lines.push('       the people\'s drawn silhouettes (info, not a check): ' + info.join('; '));
    o.cut = bad;
  }

  // 3. every spot is on what the set draws there: the sand (no sea, no part of the set) for all but abuela's three places, which are on the blanket (part manta)
  {
    const bad = [], lines = [], px = probes.spots;
    for (const [k, s] of Object.entries(S)) {
      const rows = px[k] || [], blanket = s.sprites && s.sprites.includes('abuelaL');
      const ok = blanket ? rows.every(r => r.tag === 'manta') : rows.every(r => !r.tag && r.ground === 1 && r.sand);
      if (!ok) bad.push(k + ' ' + s.screen + ' is not on ' + (blanket ? 'the blanket' : 'the sand') + ': ' + rows.map(r => 'row ' + (s.screen[1] + r.dy) + ' part ' + (r.tag || 'none') + ', ground ' + r.ground + ', kind ' + r.kind).join('; '));
    }
    const o = add('spots-on-ground', bad, Object.keys(S).length + ' spots: abuela\'s three places (manta, manta2, manta3) are on the blanket (part manta); every other spot is on the sand, on no part of the set (the pixel at the spot and the one above it)', ['spots off their ground:'].concat(bad.map(b => '  ' + b)));
    o.lines.push('       the blanket\'s top is z .03 (under 1 px): the spots stay at the spec\'s z 0');
  }

  // 4. the set things' boxes are inside the picture and the window
  {
    const bad = [], lines = [];
    const boxes = [];
    for (const [k, t] of Object.entries(T)) { if (t === 'sprite') continue; if (t.boxes) t.boxes.forEach((b, i) => boxes.push([k + '[' + i + ']', b])); boxes.push([k, t.box]); }
    for (const [k, b] of boxes) {
      const l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of cara, ojo_izq, ojo_der, nariz, boca, cabeza, brazo_izq, brazo_der, mano_izq, mano_der and pies are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
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

  // 6. frog-seen: the frog is never behind a person or a thing or the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
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
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisHint(r, S[specs[fi].at].uv));
    }
  }

  // 7. no-seat: the rule "a person on a seat sits on its top" has nothing to check here: nobody sits on a seat (abuela sits or lies on the blanket, on the sand)
  {
    const seats = Object.entries(S).filter(([, s]) => s.on && s.on !== 'ground').map(([k]) => k);
    add('no-seat', seats, 'no seat in this scene: every spot is on the sand (z 0), none above it; abuela sits or lies on the blanket (its top is z .03)', ['spots above the sand: ' + seats.join(', ')]);
  }

  // 8. face-clear (moments 1 and 2): nobody covers a pixel of the four face boxes (the shells in them are the point and are not people)
  {
    const bad = [], lines = [], hints = [], boxes = FACE_NAMES.map(n => T[n].box);
    let nearest = null;
    for (const m of [1, 2]) {
      const L = PV.inspect[m].layers;
      for (const [i, l] of L.entries()) {
        if (!l.who) continue;
        const per = FACE_NAMES.map((n, k) => [n, shownIn(L, i, boxes[k])]), g = Math.min(...boxes.map(b => gapTo(L, i, b)));
        lines.push('m' + m + ' ' + tag(L, i) + ': ' + (per.filter(q => q[1]).map(q => q[0] + ' ' + q[1]).join(', ') || '0 px in the four boxes') + '; nearest shown pixel ' + g + ' px from a box');
        if (!nearest || g < nearest[0]) nearest = [g, m, l.at];
        if (per.some(q => q[1])) { bad.push('moment ' + m + ': ' + l.at + ' ' + [l.sx, l.sy] + ' covers ' + per.filter(q => q[1]).map(q => q[1] + ' px of ' + q[0] + ' [' + T[q[0]].box + ']').join(', ')); hints.push([m, i, l.at]); }
      }
    }
    const o = add('face-clear', bad, 'in moments 1 and 2 nobody (abuela, Luis, Carmen, the frog) covers a pixel of the four face boxes (' + FACE_NAMES.map(n => n + ' [' + T[n].box + ']').join(', ') + '); the nearest anyone comes: ' + nearest[0] + ' px (' + nearest[2] + ', moment ' + nearest[1] + ')', [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { const M = PV.moment[m], r = await PV.nearestOutside(M.set, M.layers, i, boxes); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + axisHint(r, S[at].uv)); }
    o.lines.push('       per person (info): ' + lines.join('; '));
  }

  // 9. figure-clear (moments 3 and 4): nobody covers the head, an arm or a hand of the figure
  {
    const bad = [], lines = [], hints = [], names = ['cabeza', 'brazo_izq', 'brazo_der', 'mano_izq', 'mano_der'], boxes = names.map(n => T[n].box);
    let nearest = null;
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers;
      for (const [i, l] of L.entries()) {
        if (!l.who) continue;
        const per = names.map((n, k) => [n, shownIn(L, i, boxes[k])]), g = Math.min(...boxes.map(b => gapTo(L, i, b)));
        lines.push('m' + m + ' ' + tag(L, i) + ': ' + (per.filter(q => q[1]).map(q => q[0] + ' ' + q[1]).join(', ') || '0 px') + '; nearest ' + g + ' px');
        if (!nearest || g < nearest[0]) nearest = [g, m, l.at];
        if (per.some(q => q[1])) { bad.push('moment ' + m + ': ' + l.at + ' ' + [l.sx, l.sy] + ' covers ' + per.filter(q => q[1]).map(q => q[1] + ' px of ' + q[0] + ' [' + T[q[0]].box + ']').join(', ')); hints.push([m, i, l.at]); }
      }
    }
    const o = add('figure-clear', bad, 'in moments 3 and 4 nobody (abuela, Luis, Carmen, the frog, Canelo) covers the head, an arm or a hand (' + names.map(n => n + ' [' + T[n].box + ']').join(', ') + '); the nearest anyone comes: ' + nearest[0] + ' px (' + nearest[2] + ', moment ' + nearest[1] + ')', [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { const M = PV.moment[m], r = await PV.nearestOutside(M.set, M.layers, i, boxes); o.lines.push('       nearest passing, moment ' + m + ' ' + at + ' ' + S[at].uv + ': ' + axisHint(r, S[at].uv)); }
    o.lines.push('       per person (info): ' + lines.join('; '));
  }

  // 10. feet-things-clear (moment 5): nobody covers the feet's boxes or any of the three things (sombreros, gafas, chancletas)
  {
    const bad = [], lines = [], hints = [], boxes = T.pies.boxes, L = PV.inspect[5].layers, M = planes(L);
    const who = L.map((l, i) => l.who ? i : -1).filter(i => i >= 0);
    let nearest = null;
    for (const i of who) {
      const per = boxes.map(b => shownIn(L, i, b)), g = Math.min(...boxes.map(b => gapTo(L, i, b)));
      lines.push(tag(L, i) + ': ' + per[0] + ' px in the left foot box [' + boxes[0] + '], ' + per[1] + ' in the right [' + boxes[1] + ']; nearest ' + g + ' px');
      if (!nearest || g < nearest[0]) nearest = [g, L[i].at];
      if (per[0] || per[1]) { bad.push('moment 5: ' + L[i].at + ' ' + [L[i].sx, L[i].sy] + ' covers ' + (per[0] + per[1]) + ' px of the feet\'s boxes'); hints.push([i, L[i].at, boxes]); }
    }
    const bboxOf = l => { const xs = l.px.map(p => p[0]), ys = l.px.map(p => p[1]), x = Math.min(...xs), y = Math.min(...ys); return [x, y, Math.max(...xs) - x + 1, Math.max(...ys) - y + 1]; };
    for (const n of ['sombreros', 'gafas', 'chancletas']) {
      const ti = idxAt(L, n), c = coverOf(L, M, ti, who);
      lines.push(n + ' ' + [L[ti].sx, L[ti].sy] + ' box [' + bboxOf(L[ti]) + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set');
      if (c.cov || c.hid) {
        bad.push('moment 5: ' + n + ' ' + [L[ti].sx, L[ti].sy] + ': ' + c.cov + ' of its ' + c.tot + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set');
        for (const w of Object.keys(c.who)) { const wi = idxAt(L, w.split(' ')[0]); if (wi >= 0) hints.push([wi, L[wi].at, [bboxOf(L[ti])]]); }
      }
    }
    const o = add('feet-things-clear', bad, 'in moment 5 nobody (abuela at sol1, Luis at sol2, Carmen at sol3, the frog) covers a pixel of the figure\'s feet (the boxes [' + boxes.join('], [') + ']) or of the three things (sombreros, gafas, chancletas: every drawn pixel shown, none covered); the nearest anyone comes to the feet: ' + nearest[0] + ' px (' + nearest[1] + ')', [bad.length + ' covering:'].concat(bad.map(b => '  ' + b)));
    for (const [i, at, bx] of hints) { const M5 = PV.moment[5], r = await PV.nearestOutside(M5.set, M5.layers, i, bx); o.lines.push('       nearest passing, moment 5 ' + at + ' ' + S[at].uv + ': ' + axisHint(r, S[at].uv)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 11. players-whole: the players at sol1 to sol3 are whole in the picture (and the window): no pixel outside the picture, none hidden by the set
  {
    const bad = [], lines = [];
    for (const m of [5, 6]) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const at of ['sol1', 'sol2', 'sol3']) {
        const i = idxAt(L, at); if (i < 0) continue;
        const l = L[i], c = coverOf(L, M, i, null), xs = l.px.map(p => p[0]), ys = l.px.map(p => p[1]);
        const cutL = Math.max(0, x0 - Math.min(...xs)), cutR = Math.max(0, Math.max(...xs) - (x0 + 195));
        lines.push('m' + m + ' ' + at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ', rows ' + Math.min(...ys) + ' to ' + Math.max(...ys) + ' of 0 to ' + (G.H - 1) + '; ' + l.out + ' px outside the picture, ' + c.hid + ' hidden by the set, ' + (cutL + cutR) + ' cut by the window' + (c.cov ? ', ' + c.cov + ' under ' + whoTxt(c) : ''));
        if (l.out || c.hid || cutL || cutR) bad.push('moment ' + m + ': ' + at + ' ' + [l.sx, l.sy] + ': ' + l.out + ' px outside the picture, ' + c.hid + ' hidden by the set, ' + (cutL + cutR) + ' px cut by the window');
      }
    }
    add('players-whole', bad, 'the players at sol1, sol2, sol3 are whole in the picture and the window in moments 5 and 6 (none outside, none hidden by the set): ' + lines.join('; '), [bad.length + ' player(s) not whole:'].concat(bad.map(b => '  ' + b)));
  }

  // 12. abuela-manta: abuela at manta is inside the blanket's box (her place and her feet's width); info: how much of her the umbrella's shade covers
  {
    const bad = [], lines = [], B = sheet.blanket, bl = E.BLANKET, s = S.manta, shade = probes.shade;
    const inUV = k => { const [u, v] = S[k].uv; return u >= bl[0] && u <= bl[2] && v >= bl[1] && v <= bl[3]; };
    const bx0 = B.box[0], bx1 = B.box[0] + B.box[2] - 1;
    if (!inUV('manta')) bad.push('manta (u ' + S.manta.uv[0] + ', v ' + S.manta.uv[1] + ') is outside the blanket (u ' + bl[0] + ' to ' + bl[2] + ', v ' + bl[1] + ' to ' + bl[3] + ')');
    for (const k of ['manta', 'manta2', 'manta3']) {                              // the spec asks it of manta only; manta2 and manta3 are listed as information
      const sx = S[k].screen[0], a = sx - WIDTH.adulto / 2, b = sx + WIDTH.adulto / 2 - 1, out = a < bx0 || b > bx1;
      if (k === 'manta' && out) bad.push(k + ' ' + S[k].screen + ': the grown-up\'s 24 px box (columns ' + a + ' to ' + b + ') is not inside the blanket\'s box (columns ' + bx0 + ' to ' + bx1 + ')');
      let near = '';
      if (out) { for (let n = 1; n <= 400 && !near; n++) for (const sg of [-1, 1]) { const u = r4(S[k].uv[0] + sg * n * .01), x = scrUV(G, u, S[k].uv[1], 0)[0]; if (x - 12 >= bx0 && x + 11 <= bx1) { near = '; nearest u that fits: ' + S[k].uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ')'; break; } } }
      lines.push((k === 'manta' ? '' : ' ') + k + ' ' + S[k].screen + ': the 24 px box is columns ' + a + ' to ' + b + ' against the blanket\'s ' + bx0 + ' to ' + bx1 + (out ? ' (' + (a < bx0 ? bx0 - a + ' px over its left edge' : b - bx1 + ' px over its right edge') + ')' + near : ' (inside)') + (k === 'manta' ? '' : ' (not a check: the spec asks it of manta)'));
      for (const n of S[k].sprites) {
        const q = SIL[n], da = sx + q.box[0], db = sx + q.box[2], st = da < bx0 ? bx0 - da : 0, en = db > bx1 ? db - bx1 : 0;
        lines.push('  the stand-in ' + n + ' at ' + k + ' drawn columns ' + da + ' to ' + db + (st || en ? ': ' + (st ? st + ' px over the blanket\'s left edge' : '') + (st && en ? ', ' : '') + (en ? en + ' px over its right edge' : '') : ': inside'));
      }
    }
    // how much of her the umbrella covers: pixels of her drawn sprite hidden by the set (the canopy), and pixels standing in the umbrella's cast shade (the shade mask at her feet's row for a sitting figure; at the pixel itself lying)
    const shadeInfo = [];
    for (const m of [1, 2, 3, 4, 6]) {
      const L = PV.inspect[m].layers, i = L.findIndex(l => l.at === 'manta' || l.at === 'manta2'); if (i < 0) continue;
      const l = L[i], shownPx = l.px.filter(p => !p[2]);
      const inShade = shownPx.filter(p => l.lying ? shade[p[1] * G.W + p[0]] : shade[(l.sy - 1) * G.W + p[0]]).length;
      shadeInfo.push('m' + m + ' ' + l.at + ' (' + l.s + '): ' + l.px.length + ' px, ' + l.px.filter(p => p[2]).length + ' hidden by the umbrella\'s canopy, ' + inShade + ' of the ' + shownPx.length + ' shown (' + Math.round(100 * inShade / shownPx.length) + '%) in the umbrella\'s cast shade');
    }
    const o = add('abuela-manta', bad, 'abuela at manta is inside the blanket (u ' + bl[0] + ' to ' + bl[2] + ', v ' + bl[1] + ' to ' + bl[3] + '; box [' + B.box + ']): her 24 px box (the spec\'s grown-up width) is inside the blanket\'s box; the drawn stand-ins, wider or narrower, are listed below (info)', [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const l of lines) o.lines.push('       ' + (l[0] === ' ' ? 'info, not a check:' : '') + l);
    for (const l of shadeInfo) o.lines.push('       info, not a check: ' + l);
  }

  // info: who covers what in each moment (not checks of the spec): every layer with pixels under a nearer sprite or hidden by the set; abuela's head (the top 14 rows sitting or standing, the 14 leftmost columns lying)
  {
    const lines = [], heads = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        const c = coverOf(L, M, i, null);
        if (c.cov && (l.who || !l.at.startsWith('sol')) && !Object.keys(c.who).some(w => w.includes('(bola)'))) for (const w of Object.keys(c.who)) { const wi = idxAt(L, w.split(' ')[0]); if (wi >= 0) hints.push([m, i, wi]); }
        if (c.cov || c.hid) lines.push('m' + m + ' ' + lab(l) + ': ' + c.cov + ' of its ' + c.tot + ' px under ' + (whoTxt(c) || 'nothing') + (c.hid ? ', ' + c.hid + ' hidden by the set' : ''));
        if (l.who === 'adulto' && l.at.startsWith('manta')) {
          const left = Math.min(...l.px.map(p => p[0])), top = Math.min(...l.px.map(p => p[1])), head = l.lying ? l.px.filter(p => p[0] < left + 14) : l.px.filter(p => p[1] < top + 14);
          let cov = 0; const who = {};
          for (const p of head) { if (p[2]) continue; for (const b of M.get(key(p[0], p[1])) || []) if (b.i !== i && b.plane > p[3] + EPS) { cov++; who[lab(L[b.i])] = 1; break; } }
          heads.push('m' + m + ' ' + l.at + ' (' + l.s + '): ' + cov + ' of her ' + head.length + ' head px covered' + (cov ? ' by ' + Object.keys(who).join(', ') : ''));
        }
      }
    }
    const out = { name: 'info-covers', ok: true, lines: ['info-covers: not a check. What is under a nearer sprite, or hidden by the set, in the six moments (everything not listed is seen whole): ' + (lines.join('; ') || 'nothing'), '       abuela\'s head: ' + heads.join('; ')] };
    for (const [m, i, wi] of hints) {                                                                  // the least shift (u or v) of the one in front that leaves the other whole
      const M = PV.moment[m], L = M.layers, r = await PV.nearestClear(M.set, L, wi, [i], null);
      out.lines.push('       nearest that leaves ' + (L[i].at) + (L[i].who ? '' : ' (' + L[i].s + ')') + ' whole, moment ' + m + ': ' + L[wi].at + ' ' + S[L[wi].at].uv + ': ' + ['u', 'v'].map((a, k) => r.axis[a] ? a + ' ' + S[L[wi].at].uv[k] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '));
    }
    OUTS.push(out);
  }
  return OUTS;
}
