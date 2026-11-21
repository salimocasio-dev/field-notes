#!/usr/bin/env node
'use strict';
/* El reloj's sheet: writes docs/proyecto/pixel/reloj-sheet.json from reloj-set.html and the design (the orchestrator's p6-spec, section "reloj"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/reloj-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene (place 6, La plaza, scene 2): no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture and v
   down it, and plaza-base.js's PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives its world place; the make then projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S.
   It loads the set in headless Chrome (reloj-set.html, window.RELOJ.E: the set's constants), reads the pixels it drew (tags=1: which part drew each pixel; the baked depth), and writes the spots,
   things, the view (wide), shadows, the hands of the clock and the depth rule. The sprites' silhouettes come from today's makers (historia/engine.js, historia/escenas/kit.js) loaded in a second,
   empty page. The checks that say "covers" or "shows" read the PREVIEW's moments (reloj-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview
   reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with RELOJ_BASE), but every request to it is answered from the files of THIS tree
   (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'reloj-sheet.json');
const BASE = process.env.RELOJ_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/reloj-set.html';
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

// the numbers of the design (p6-spec: the rules for every sheet, and "reloj")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const TITO_FACE = .08;                                   // don Tito at balcon1 covers no more than 8% of the face's pixels
const HANDS = { long: 19, short: 12, width: 2 };         // the hands of the clock: sprites that turn about the face's middle (stand-ins: dark lines 2 px wide)
const CARD = { w: 22, gap: 4, above: 3 };                // carta_a, carta_b: two 22 px squares, 4 px apart, centred over the frog, their foot 3 px above his head
const CAGE_BOX = { w: 20, h: 22 }, PRIZE_BOX = { w: 16, h: 16 };       // the cage's stand-in; the prizes' stand-ins
const PLATE_BOX = { w: 14, h: 7 };                       // the plate of pastelillos: the spec gives no size (open point): a plate with three half-moons
const AWNING = { near: 3.4, far: 3.66 };                  // the quiosco's awning (reloj-set.html kiosk(): not exported in E)
const PAPER_HAT = 4;                                     // the vendedor's paper hat: the stand-in wears one 4 rows tall, so the head's top 14 rows hold the hat and 10 rows of head
const CARTON = { x: 26, y: 92, sq: 14, gap: 2, nums: ['n40', 'n60', 'n80', 'n90', 'n100'] };       // abuela's card, shown big: five 14 px squares, 2 px apart, its top left at screen (26, 92)
const VIEW_W = 196;
const MOMENTS = [1, 2, 3, 4, 5, 6], EXTRA = [7, 8];     // the spec's six moments; two dev aids (the frog at balcon2 and on the ladder), read for information only
const PLAIN_X0 = 22;                                     // the spec: "22 centres it"

// the spots: [name, (u, v, z), kind, silhouette, character kind, what, on]
// silhouette: which drawing hangs there (adulto, adultoS = a grown-up sitting, abuelaS, nino, luisS = a child sitting, coqui) or null for a small thing; on: what it stands on above the ground (a part of the set, or the hand: a sprite)
const spotsOf = E => {
  const T = E.TOWER, K = E.KIOSK, [T1, T2, T3] = E.TABLES, C = E.CAGE, SH = E.SHELF;
  return [
    ['balcon1', [-1.35, -1.7, 2.1], 'person', 'adulto', 'adulto', 'don Tito on the balcony (standing or sitting: a sitting person hangs by the lap on the same point; the balcony\'s floor, z 2.1)', 'torre'],
    ['balcon2', [1.3, -1.7, 2.1], 'person', 'coqui', 'coqui', 'the frog on the balcony\'s floor', 'torre'],
    ['escalera', [-1.5, -1.2, 1.05], 'person', 'coqui', 'coqui', 'the frog half way up the ladder', 'torre'],
    ['mano_arriba', [0, -1.98, 4.3], 'person', 'coqui', 'coqui', 'the frog on the long hand, the hand pointing up (the 12): on a sprite, z 4.3', 'mano'],
    ['mano_abajo', [0, -1.98, 3.1], 'person', 'coqui', 'coqui', 'the frog on the long hand, the hand pointing down (the 6): his feet at the hand\'s tip: on a sprite, z 3.1', 'mano'],
    ['mano_lado', [.75, -1.98, 3.9], 'person', 'coqui', 'coqui', 'the frog on the long hand, the hand resting at the 3: his feet on the hand\'s line: on a sprite, z 3.9', 'mano'],
    ['pie1', [-.7, -.9, 0], 'person', 'nino', 'nino', 'the tower\'s foot, first of the row (Luis)'],
    ['pie2', [.45, -.9, 0], 'person', 'coqui', 'coqui', 'the tower\'s foot, second of the row (the frog)'],
    ['pie3', [1.6, -.9, 0], 'person', 'nino', 'nino', 'the tower\'s foot, third of the row (Carmen)'],
    ['pie4', [-.1, .3, 0], 'person', null, null, 'the tower\'s foot, a place in front of the row: no moment of the spec puts anybody there, so it is checked with the widest sprite (the frog\'s 32)'],
    ['quiosco', [K.u, r4(K.v - .6), 0], 'person', 'adulto', 'adulto', 'the vendedor behind his counter'],
    ['plato', [r4(K.u + .33), K.v, 1.0], 'thing', null, null, 'the plate of pastelillos on the counter, right of the fryer (the counter\'s top, z 1.0): a plate with three half-moons, 14 x 7 (the spec gives no size: open point)', 'quiosco'],
    ['mesa_abuela.abuela', [r4(T1[0] - .5), r4(T1[1] - .55), .4], 'person', 'abuelaS', 'adulto', 'abuela on her stool at the first table (sitting: the stool\'s top, z .4; the sitting drawing hangs by her lap)', 'mesas'],
    ['mesa_abuela.luis', [r4(T1[0] + 1.15), r4(T1[1] - .9), 0], 'person', 'nino', 'nino', 'Luis standing beside the first table, at its right (the coordinator\'s decision: he does not sit; a child on the ground, z 0)'],
    ['mesa_abuela.coqui', [T1[0], T1[1], .72], 'person', 'coqui', 'coqui', 'the frog on the first table (the cloth\'s top, z .72)', 'mesas'],
    ['mesa_senor', [r4(T2[0] - .5), r4(T2[1] - .55), .4], 'person', 'adultoS', 'adulto', 'the señor on his stool at the second table (z .4)', 'mesas'],
    ['mesa_tito', [r4(T3[0] + .5), r4(T3[1] - .55), .4], 'person', 'adultoS', 'adulto', 'don Tito on his stool at the third table (z .4)', 'mesas'],
    ['jaula', [C[0], C[1], .8], 'thing', null, null, 'the cage of numbered balls on its stand (the stand\'s top, z .8): a 20 x 22 stand-in', 'mesas'],
    ['senora', [C[0], r4(C[1] - .5), 0], 'person', 'adulto', 'adulto', 'the señora who calls the bingo, behind the cage'],
    ['premio1', [r4(SH[0] - .62), SH[1], .7], 'thing', null, null, 'the best prize, at the left of the long prize table (SHELF.u - 0.62, SHELF.v, the table\'s top z .7): a 16 x 16 stand-in', 'mesas'],
    ['premio2', [SH[0], SH[1], .7], 'thing', null, null, 'the second prize, in the middle of the long prize table (SHELF.u, SHELF.v, z .7): a 16 x 16 stand-in', 'mesas'],
    ['premio3', [r4(SH[0] + .62), SH[1], .7], 'thing', null, null, 'the third prize, at the right of the long prize table (SHELF.u + 0.62, SHELF.v, z .7): a 16 x 16 stand-in', 'mesas'],
  ].map(s => { if (!s[6]) s[6] = null; return s; });
};
const THING_BOX = { plato: PLATE_BOX, jaula: CAGE_BOX, premio1: PRIZE_BOX, premio2: PRIZE_BOX, premio3: PRIZE_BOX };
const PEOPLE = ['tito', 'vendedor', 'luis', 'carmen', 'abuela', 'senor', 'senora', 'coqui'];

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (every spot of every moment is inside the window), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (whoever sits or stands above the
   ground is on the top of what the set draws there), things-in-view (the signs and the stand-ins are inside the window), sprites-apart (the people of a moment; the frog on abuela's table is exempt against abuela, who sits behind it), frog-seen (the frog whole in every
   moment: nothing of the set, no grown-up, covers him), frog-on-hand (at mano_arriba, mano_abajo, mano_lado he is whole inside the picture), table-heads (the frog on abuela's table covers neither head at it), tito-face (don Tito at balcon1 covers no more than 8%
   of the face), vendedor-head (nothing covers the top 14 px of the vendedor), cards-clear (the two time cards cover neither the frog, the face nor the vendedor), carton-clear (every square of
   abuela's card is in the window and covered by nobody), bingo-clear (nobody covers the cage and the three prizes). A failing line names its numbers and the nearest value that would pass. */
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

  await page.goto(PAGE + '?tags=1&mesas=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(RELOJ.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const [x, y] = PZ.xy(u, v), q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
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
      adultoS: sil(KIT.mkPersona(SENOR, 'idle', 0, 1), KIT.PX, lap(SENOR)), luisS: sil(KIT.mkPersona(FAM.hermano, 'idle', 0, 1), KIT.PX, lap(FAM.hermano)),
      abuelaS: sil(KIT.mkAbuelaS('idle', 0, 0), 17, 36), coqui: sil(mkCoqui(1, 0, 0), 16),
    };
  });
}

/* ---------- the preview's moments: reloj-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/reloj-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  for (const m of MOMENTS.concat(EXTRA)) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.nearestCover = (m, idx, victim) => p.evaluate(x => window.PREVIEW.nearestCover(x.m, x.idx, x.victim), { m, idx, victim });
  PV.nearest = (m, idx, allow, headRows) => p.evaluate(x => window.PREVIEW.nearest(x.m, x.idx, x.allow, x.headRows), { m, idx, allow: allow || 0, headRows: headRows || 0 });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];

// the columns a spot needs in the window: a thing or a sign its box, a person his sprite box (the frog 32 wide, a grown-up 24, a child 24; a person nobody is put on: the widest), a point its column
function span(s) {
  if (s.box) return [s.box[0], s.box[0] + s.box[2] - 1];
  const h = s.kind === 'person' ? (s.who ? WIDTH[s.who] : WIDTH.coqui) / 2 : 0;
  return h ? [s.screen[0] - h, s.screen[0] + h - 1] : [s.screen[0], s.screen[0]];
}
// how many px of a spot are cut by the window at x0; 0 when whole
const cutAt = (s, x0) => { const [l, r] = span(s); return Math.max(0, x0 - l) + Math.max(0, r - (x0 + VIEW_W - 1)); };

/* ---------- the sheet ---------- */
async function make(G, proj, SIL) {
  const E = G.E, sc = G.scene, T = E.TOWER, F = E.FACE, B = E.BALCON, D = E.DOOR, P = E.FLAP, K = E.KIOSK, L = E.LADDER;
  const SPOTS = spotsOf(E);
  const pr = await proj(SPOTS.map(s => s[1]));
  const spots = {};
  SPOTS.forEach((s, i) => {
    const q = pr[i], o = { world: W4([q[3], q[4], s[1][2]]), uv: W4(s[1]), screen: [Math.round(q[0]), Math.round(q[1])], depth: r4(q[2]), scale: 1, kind: s[2], view: 'wide', what: s[5] };
    if (s[3]) o.sprite = s[3];
    if (s[4]) o.who = s[4];
    if (s[1][2] > 0) o.on = s[6] || 'torre';                                    // what it stands on above the ground: a part of the set (the balcony, the counter, a stool, a table, the cage's stand, the prize table) or the hand (a sprite)
    if (THING_BOX[s[0]]) { const b = THING_BOX[s[0]]; o.box = [o.screen[0] - b.w / 2, o.screen[1] - b.h, b.w, b.h]; }
    spots[s[0]] = o;
  });

  /* ---- the face and the hands ---- */
  const [fq] = await proj([[F.u, T.v, F.z]]);
  const cx = fq[0], cy = fq[1], R = F.r;
  const disc = [];                                                               // the face's pixels: the pixel's middle within R px of the engine's projection of the face's middle
  for (let y = 0; y < G.H; y++) for (let x = 0; x < G.W; x++) if (Math.hypot(x + .5 - cx, y + .5 - cy) < R) disc.push([x, y]);
  const bbox = pts => { const x0 = Math.min(...pts.map(p => p[0])), y0 = Math.min(...pts.map(p => p[1])); return [x0, y0, Math.max(...pts.map(p => p[0])) - x0 + 1, Math.max(...pts.map(p => p[1])) - y0 + 1]; };
  const band = f => disc.filter(p => f(p[1] + .5 - cy));
  const pivot = [Math.round(cx), Math.round(cy)];
  const tip = (len, deg) => [r2(pivot[0] + Math.sin(deg * Math.PI / 180) * len), r2(pivot[1] - Math.cos(deg * Math.PI / 180) * len)];
  const dseg = (p, a, b) => { const dx = b[0] - a[0], dy = b[1] - a[1], t = Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy))); const q = [a[0] + t * dx, a[1] + t * dy]; return { dist: r2(Math.hypot(p[0] - q[0], p[1] - q[1])), along: r2(t * Math.hypot(dx, dy)), at: q.map(r2) }; };
  const FROG_HAND = { mano_arriba: ['up', 0], mano_abajo: ['down', 180], mano_lado: ['the 3', 90] };
  const hands = {
    pivot: { world: W4([fq[3], fq[4], F.z]), uv: W4([F.u, T.v, F.z]), screen: pivot, exact: [r2(cx), r2(cy)], depth: r4(fq[2]) },
    long: HANDS.long, short: HANDS.short, width: HANDS.width,
    what: 'the two hands are sprites that turn about the face\'s middle (the pivot, on the tower\'s front: the plane v ' + T.v + '): the long one ' + HANDS.long + ' px, the short one ' + HANDS.short + ' px (stand-ins: dark lines ' + HANDS.width + ' px wide), drawn with the depth of the pivot (the tower\'s front) so that the frog, who stands .02 in front of it, is drawn over them',
    turn: 'an angle is degrees clockwise from the 12 (straight up): a hand of length len at angle a ends at (pivot x + len sin a, pivot y - len cos a). The short hand at hour h and m minutes is at 30 (h mod 12) + m / 2 degrees',
    long_at: { up: { deg: 0, tip: tip(HANDS.long, 0) }, down: { deg: 180, tip: tip(HANDS.long, 180) }, three: { deg: 90, tip: tip(HANDS.long, 90) } },
    frog_on: Object.fromEntries(Object.entries(FROG_HAND).map(([k, [name, deg]]) => [k, Object.assign({ hand: name, deg, tip: tip(HANDS.long, deg) }, dseg(spots[k].screen, pivot, tip(HANDS.long, deg)))])),
    note: 'frog_on: for each of the frog\'s three places on the long hand, the distance (px) from his feet\'s spot to the hand\'s line (the segment from the pivot to the tip) and where along it (px from the pivot, the hand being ' + HANDS.long + '): the spec\'s z values put his feet on the hand at mano_arriba and beyond or beside its end at the other two',
  };

  /* ---- the signs: the two time cards over the frog at pie2, and abuela's card ---- */
  const frogTop = SIL.coqui.box[1];                                              // the frog's top row, from his feet's row (negative)
  const pie2 = spots.pie2, headTop = pie2.screen[1] + frogTop, cardY = headTop - CARD.above - CARD.w;
  const cardA = [pie2.screen[0] - CARD.w - CARD.gap / 2, cardY, CARD.w, CARD.w], cardB = [pie2.screen[0] + CARD.gap / 2, cardY, CARD.w, CARD.w];
  spots.carta_a = { kind: 'sign', view: 'wide', over: 'pie2', screen: [cardA[0] + CARD.w / 2, cardA[1] + CARD.w], box: cardA, what: 'the first time card, over the frog (here at pie2): a ' + CARD.w + ' px square, its foot ' + CARD.above + ' px above his head, ' + CARD.gap + ' px from the other, the two centred on him' };
  spots.carta_b = { kind: 'sign', view: 'wide', over: 'pie2', screen: [cardB[0] + CARD.w / 2, cardB[1] + CARD.w], box: cardB, what: 'the second time card, to the right of the first' };
  const sqBox = i => [CARTON.x + i * (CARTON.sq + CARTON.gap), CARTON.y, CARTON.sq, CARTON.sq];
  spots.carton = { kind: 'sign', view: 'wide', screen: [CARTON.x, CARTON.y], box: [CARTON.x, CARTON.y, CARTON.nums.length * CARTON.sq + (CARTON.nums.length - 1) * CARTON.gap, CARTON.sq], what: 'abuela\'s card, shown big: a row of five ' + CARTON.sq + ' px squares, ' + CARTON.gap + ' px apart, its top left at screen (' + CARTON.x + ', ' + CARTON.y + '): n40, n60, n80, n90, n100 from left to right' };

  /* ---- the view: x0 so that every spot of every moment is inside ---- */
  const all = Object.entries(spots), x0max = G.W - VIEW_W;
  const holds = all.map(([k]) => k), ext = all.map(([, s]) => span(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const okX = []; for (let x = 0; x <= x0max; x++) if (all.every(([, s]) => !cutAt(s, x))) okX.push(x);
  let x0, bestCut = null;
  if (okX.length) x0 = okX.reduce((a, b) => (Math.abs(b - PLAIN_X0) < Math.abs(a - PLAIN_X0) ? b : a));
  else { for (let x = 0; x <= x0max; x++) { const n = all.filter(([, s]) => cutAt(s, x)).length, px = all.reduce((a, [, s]) => a + cutAt(s, x), 0); if (!bestCut || n < bestCut.n || (n === bestCut.n && px < bestCut.px)) bestCut = { x, n, px }; } x0 = bestCut.x; }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, VIEW_W, 216], stories: [63, 64, 65], holds, extent: [lo, hi],
      what: 'the one view of stories 63, 64 and 65: the ' + VIEW_W + ' x 216 window over the 240 x 216 picture. The spec: x0 is the window\'s left edge, 22 centres it, and every spot of every moment is inside with its sprite whole. ' + (okX.length ? 'x0 ' + x0 + ' holds them all: x0 ' + okX[0] + ' to ' + okX[okX.length - 1] + ' do, and ' + x0 + ' is the one nearest 22' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest (' + bestCut.n + ' spots, ' + bestCut.px + ' px)') + ' (the spots, with their sprites, signs and stand-ins, span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const box3 = async pts => {                                                    // a solid or a plane: the screen box and the world box round its corners
    const q = await proj(pts), xs = q.map(p => p[0]), ys = q.map(p => p[1]), fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by], world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), Math.min(...pts.map(p => p[2])), Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), Math.max(...pts.map(p => p[2]))]) };
  };
  const solid = (u0, u1, v0, v1, z0, z1) => [u0, u1].flatMap(u => [v0, v1].flatMap(v => [z0, z1].map(z => [u, v, z])));
  const setThing = async (u0, u1, v0, v1, z0, z1, what) => { const b = await box3(solid(u0, u1, v0, v1, z0, z1)); return { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: b.world, box: b.box, what }; };
  const dFace = { centre: [r2(cx), r2(cy)], r: R };
  const zr = R / (G.S * COS);                                                    // the face's radius in z
  const faceThing = (px, what) => {                                              // a part of the face: its pixel box, and the (u, z) rectangle round it on the tower's front
    const b = bbox(px), u0 = (b[0] - G.OX) / G.S, u1 = (b[0] + b[2] - G.OX) / G.S, zOf = y => (G.OY + (T.v * .5) * G.S - y) / (G.S * COS);
    return { set: true, uv: W4([u0, T.v, zOf(b[1] + b[3]), u1, T.v, zOf(b[1])]), disc: dFace, box: b, px: px.length, what };
  };
  const wallWorld = async (th) => { const u = th.uv, b = await box3(solid(u[0], u[3], u[1], u[4], u[2], u[5])); th.world = b.world; return th; };
  const things = {};
  things.reloj = await wallWorld(faceThing(disc, 'the clock face: the disc of radius ' + R + ' px about the face\'s middle (disc), on the tower\'s front (the plane v ' + T.v + '); box is the disc\'s bounding box, px its pixel count (the pixels whose middle is within ' + R + ' px of the middle); the poke is the disc'));
  things.arriba = await wallWorld(faceThing(band(dy => dy < -R / 3), 'the upper third of the face: the part of the disc above the line ' + r2(R / 3) + ' px over its middle (a third of its 54 px height), the 12 in it; box is the part\'s bounding box; the poke is the part of the disc inside it'));
  things.abajo = await wallWorld(faceThing(band(dy => dy > R / 3), 'the lower third of the face: the part of the disc below the line ' + r2(R / 3) + ' px under its middle, the 6 in it; box is the part\'s bounding box; the poke is the part of the disc inside it'));
  things.puertita = await setThing(D.u0, D.u1, T.v, T.v, D.z0, D.z1, 'the little door of the three figures, in the tower\'s front, right of the face (DOOR); a poke');
  things.tapa = await setThing(P.u0, P.u1, T.v, T.v, P.z0, P.z1, 'the iron flap of the works, in the tower\'s front, left of the face (FLAP); a poke');
  things.balcon = await setThing(B.u0, B.u1, T.v, r4(T.v + B.out), r4(B.z - .46), r4(B.z + B.rail), 'the balcony: its floor, brackets and rail (u ' + B.u0 + ' to ' + B.u1 + ', out to v ' + r4(T.v + B.out) + ', z ' + r4(B.z - .46) + ' to ' + r4(B.z + B.rail) + ')');
  things.escalera = await setThing(r4(L.u - .26), r4(L.u + .26), r4(T.v + B.out), L.v0, 0, r4(B.z + .02), 'the ladder, leaning from its foot (v ' + L.v0 + ') to the balcony\'s front edge (v ' + r4(T.v + B.out) + '): the box of its two rails');
  things.quiosco = await setThing(r4(K.u - K.hw - .12), r4(K.u + K.hw + .12), r4(K.v - K.hd - .1), r4(K.v + K.hd + .14), 0, AWNING.far, 'the quiosco: the counter, the fryer and the awning on its four posts (KIOSK: the counter\'s top z 1.0, the awning from z ' + AWNING.near + ' at its front edge to z ' + AWNING.far + ' at its back: the set\'s own numbers, not in E)');
  things.pastelillos = 'sprite';
  things.carta_a = { set: false, at: 'carta_a', box: cardA, what: 'the first time card (a sign over the frog; here for the frog at pie2): a poke' };
  things.carta_b = { set: false, at: 'carta_b', box: cardB, what: 'the second time card: a poke' };
  CARTON.nums.forEach((k, i) => { things[k] = { set: false, sign: true, box: sqBox(i), what: 'the square of ' + k.slice(1) + ' on abuela\'s card (shown big, a sign): a poke' }; });
  for (const k of PEOPLE) things[k] = 'sprite';

  return {
    scene: 'reloj',
    made: 'node docs/proyecto/pixel/reloj-sheet-make.js, from reloj-set.html (window.RELOJ.E) and the design of El reloj (the orchestrator\'s p6-spec, section reloj). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [VIEW_W, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the tower\'s front at v ' + T.v + '; plaza-base.js\'s PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.52 z (one z is ' + r2(G.S * COS) + ' px up). The picture holds u from ' + r2(-G.OX / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the ground; z .4: a stool\'s top; z .72: the table\'s cloth; z .8: the cage\'s stand; z 1.0: the counter\'s top; z 2.1: the balcony\'s floor; z 4.3, 2.78, 3.55: on the long hand, a sprite) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty), 41 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy: his head\'s top is on row sy - 24); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the stool; a child or a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 7 a child: 33; t 11 a grown-up: 41) on (sx, sy); a small thing (the plate, the cage, a prize): its bottom edge on sy, its middle column on sx (the box in the spot); a sign (a card, a square): its top left on the box\'s corner',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = the window\'s left edge, in whole pixels, 0 to 44. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      hands: 'the hands: see hands (the pivot, the lengths, the angle convention)',
      cards: 'carta_a, carta_b: two ' + CARD.w + ' px squares ' + CARD.gap + ' px apart, centred over the frog, their foot ' + CARD.above + ' px above his head: with the frog\'s feet on (sx, sy) his head\'s top row is sy ' + frogTop + ' (' + (frogTop < 0 ? 'sy - ' + -frogTop : 'sy + ' + frogTop) + '), so both squares have their top at y = sy ' + (frogTop - CARD.above - CARD.w) + ' and end at row sy ' + (frogTop - CARD.above - 1) + '; carta_a\'s left is sx - ' + (CARD.w + CARD.gap / 2) + ', carta_b\'s is sx + ' + CARD.gap / 2 + ' (box [x, y, ' + CARD.w + ', ' + CARD.w + ']). For the frog at pie2 (sx ' + pie2.screen[0] + ', sy ' + pie2.screen[1] + '): carta_a ' + JSON.stringify(cardA) + ', carta_b ' + JSON.stringify(cardB),
      carton: 'abuela\'s card: five ' + CARTON.sq + ' px squares ' + CARTON.gap + ' px apart, the first\'s top left at screen (' + CARTON.x + ', ' + CARTON.y + '): square i (0 to 4) at x ' + CARTON.x + ' + ' + (CARTON.sq + CARTON.gap) + ' i, y ' + CARTON.y,
    },
    setKey: {
      params: { hora: { values: ['mediodia', 'tarde', 'ocaso'], note: 'the light: 63 mediodia, 64 and 65 tarde (the spec\'s moments); ocaso is in the set and in no moment of the spec' }, mesas: { values: [0, 1], note: 'the bingo: three round tables with their stools, the cage\'s stand and the long prize table (story 65)' } },
      key: 'hora + mesas, e.g. "tarde-1"',
      baked: ['mediodia', 'tarde', 'ocaso'].flatMap(h => [0, 1].map(c => '?hora=' + h + '&mesas=' + c)),
    },
    things,
    spots,
    hands,
    groups: { pie: ['pie1', 'pie2', 'pie3', 'pie4'], mano: ['mano_arriba', 'mano_abajo', 'mano_lado'], mesas: ['mesa_abuela.abuela', 'mesa_abuela.luis', 'mesa_abuela.coqui', 'mesa_senor', 'mesa_tito'], bingo: ['jaula', 'senora', 'premio1', 'premio2', 'premio3'], signs: ['carta_a', 'carta_b', 'carton'], carton: CARTON.nums },
    notes: [
      'every number of a spot is the orchestrator\'s (p6-spec, section reloj), given in (u, v, z); where the spec writes E.KIOSK, E.TABLES, E.CAGE, E.SHELF the make reads them from the set (window.RELOJ.E)',
      'the spec\'s six moments are 1 (63 opening), 2 (63 game), 3 to 5 (64), 6 (65); the preview also draws two dev aids that are not among them: 7 (the frog at balcon2), 8 (the frog at escalera)',
      'the prize table is a long low table (SHELF: hw .95, hd .2, top z .7) with three places side by side, the best at the left: premio1 at SHELF.u - 0.62, premio2 at SHELF.u, premio3 at SHELF.u + 0.62 (the coordinator\'s decision)',
      'the long hand rests at the 3 (the script says so): mano_lado is (0.75, -1.98, 3.9), his feet on the hand\'s line; mano_abajo is (0, -1.98, 3.1), his feet at the hand\'s tip',
      'the frog on abuela\'s table stands in front of abuela, who sits behind it: he is exempt from sprites-apart against mesa_abuela.abuela only; Luis stands beside the table (mesa_abuela.luis is on the ground at T1.u + 1.15, T1.v - 0.9; the first numbers were T1.u + 0.95, T1.v - 0.55). table-heads: the frog covers no more than 10% of abuela\'s head (the top 14 rows of her sprite) and none of Luis\'s',
      'carta_a, carta_b and the card of numerals are signs: they are placed on the screen, not in the world, and drawn over everything',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the awning, the counter, the stands and the tables hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador\'s and El cruce\'s sheets: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn. The hands are sprites on the tower\'s front: their plane goes through the pivot (the tower\'s front), so the frog, who stands .02 in front of it at the three places on the long hand, is nearer. The signs (the two time cards, the card of numerals and its beans) are drawn over everything',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, tito: .35, vendedor: .35, abuela: .35, senor: .35, senora: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El mostrador\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: all.filter(([, s]) => s.uv && s.uv[2] > 0).map(([k]) => k),
      onSeat: 'whoever stands or sits above the ground (the balcony, the ladder, a stool, the table, the hand, the counter, the cage\'s stand, the prize table) casts none: it is not ground (a shadow cast at the pavement under it would show in front of it)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew round each spot's feet (the part and the baked depth), mesas = 1 (the depth does not change with hora)
  const spotsPx = await page.evaluate(arg => {
    const o = {};
    for (const [k, s] of Object.entries(arg)) {
      const rows = [];
      for (let dy = -3; dy <= 1; dy++) for (let dx = -8; dx <= 8; dx++) { const X = s.screen[0] + dx, Y = s.screen[1] + dy; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X; rows.push({ dx, dy, tag: TAGS[i], z: DEPTH.z[i] }); }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).filter(([, s]) => s.uv).map(([k, s]) => [k, { screen: s.screen }])));
  const tags = px => page.evaluate(q => q.map(([x, y]) => TAGS[y * W + x] || 'ground'), px);          // the part the set drew at each pixel [x, y]
  return { spotsPx, tags };
}

function checks(sheet, G, SIL, probes, PV) { return checksAsync(sheet, G, SIL, probes, PV); }
async function checksAsync(sheet, G, SIL, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, OUTS = [], x0 = V.x0, win = [x0, x0 + VIEW_W - 1];
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const key = (x, y) => y * G.W + x, lbl = l => l.at || l.thing || l.s;
  const layersOf = m => PV.inspect[m].layers;
  const person = l => l.who && l.who !== null;
  // the pixels a layer shows (not hidden by the set), by pixel: its plane
  const shownMap = l => { const m = new Map(); for (const p of l.px) if (!p[2]) m.set(key(p[0], p[1]), p[3]); return m; };
  // for a layer: how many of its drawn pixels are hidden by the set, outside the picture, and under a nearer layer (by label)
  const coverage = (L, i, rows) => {
    const f = L[i], best = new Map();
    L.forEach((l, j) => { if (j === i) return; for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]), b = best.get(k); if (!b || b.plane < p[3]) best.set(k, { plane: p[3], at: lbl(l) }); } });
    const px = rows ? f.px.filter(p => rows(p)) : f.px;
    let hid = 0, cov = 0; const by = {}, hidPx = [];
    for (const p of px) { if (p[2]) { hid++; hidPx.push([p[0], p[1]]); continue; } const b = best.get(key(p[0], p[1])); if (b && b.plane > p[3] + EPS) { cov++; by[b.at] = (by[b.at] || 0) + 1; } }
    return { total: px.length + (rows ? 0 : f.out), hid, cov, by, out: rows ? 0 : f.out, hidPx };
  };
  const byTxt = by => Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ');
  const nearestTxt = (res, uv, what) => ['u', 'v', 'z'].map((a, i) => res.axis[a] ? a + ' ' + uv[i] + ' -> ' + res.axis[a].to + ' (' + sgn(res.axis[a].d) + ')' : a + ': none within 3').join('; ');

  // 1. the view: x0 holds every spot of every moment (a person's sprite, a thing's or a sign's box whole), and says which x0 do
  {
    const bad = [];
    const out = Object.entries(S).map(([k, s]) => [k, cutAt(s, x0)]).filter(o => o[1]);
    const ok = []; for (let x = 0; x <= G.W - VIEW_W; x++) if (Object.values(S).every(s => !cutAt(s, x))) ok.push(x);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + x0);
    const line = 'wide: x0 ' + x0 + ' (window columns ' + win[0] + ' to ' + win[1] + '); the ' + Object.keys(S).length + ' spots span columns ' + V.extent[0] + ' to ' + V.extent[1] + ' (' + (V.extent[1] - V.extent[0] + 1) + ' of the window\'s ' + VIEW_W + '); x0 that hold them all: ' + (ok.length ? ok[0] + ' to ' + ok[ok.length - 1] : 'none') + ' (the spec: 22 centres it)';
    const o = add('views-x0', bad, line, [bad.length + ' spots cut by the window:', '  ' + line].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: x0, holdsAll: ok.length ? [ok[0], ok[ok.length - 1]] : [] };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a sprite's box: the frog 32 wide, a grown-up 24, a child 24; and its rows, from the drawn silhouette)
  {
    const bad = [], rows = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, [l, r] = span(s);
      const sil = s.sprite ? SIL[s.sprite] : null;
      const top = s.box ? s.box[1] : sil ? sy + sil.box[1] : sy, bottom = s.box ? s.box[1] + s.box[3] - 1 : sil ? sy + sil.box[3] : sy;
      const cutL = Math.max(0, x0 - l), cutR = Math.max(0, r - (x0 + VIEW_W - 1)), picL = Math.max(0, -l), picR = Math.max(0, r - (G.W - 1)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      rows.push(k);
      if (sx < 0 || sx >= G.W || sy < 0 || sy >= G.H) bad.push(k + ' ' + S[k].screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (cut.length) bad.push(k + ' ' + s.screen + ': its ' + (s.who || s.kind) + ' ' + (s.box ? 'box' : 'sprite') + ' is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + VIEW_W) + ') or the picture' + (picL || picR ? ' (the picture\'s own edge: ' + [picL && 'left ' + picL, picR && 'right ' + picR].filter(Boolean).join(', ') + ')' : ''));
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k]; if (!s.uv) continue;
      const w = s.box ? s.box[2] : s.who ? WIDTH[s.who] : WIDTH.coqui;
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0]; if (sx - w / 2 >= x0 && sx + w / 2 - 1 <= x0 + VIEW_W - 1 && sx - w / 2 >= 0) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, rows.length + ' spots (people with their sprites, things and signs with their boxes) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + ')', [bad.length + ' spot(s) outside, or with a sprite cut:'].concat(bad.map(b => '  ' + b), hints));
    o.cut = bad;
    {                                                                                             // information: the drawn ink of each sprite against the window (the boxes above are the spec's widths)
      const edge = [];
      for (const [k, s] of Object.entries(S)) if (s.sprite && SIL[s.sprite]) { const b = SIL[s.sprite].box, l = s.screen[0] + b[0], r = s.screen[0] + b[2]; edge.push({ k, l: l - x0, r: x0 + VIEW_W - 1 - r }); }
      const tl = edge.reduce((a, b) => (b.l < a.l ? b : a)), tr = edge.reduce((a, b) => (b.r < a.r ? b : a));
      o.lines.push('       info, not a check: the drawn ink of the sprites (not the spec\'s boxes): the nearest to the window\'s left edge is ' + tl.k + ' (' + tl.l + ' px inside), to its right edge ' + tr.k + ' (' + tr.r + ' px inside)' + (tl.l < 0 || tr.r < 0 ? ' CUT' : ''));
    }
  }

  // 3. the spots above the ground are on a surface the set draws: the pixels round the spot's feet include one drawn by the part it stands on (the balcony and the ladder: torre; the counter: quiosco;
  //    a stool, a table, the cage's stand, the prize table: mesas) whose depth is within .1 of the spot's; the three places on the long hand stand on a sprite
  {
    const bad = [], lines = [], on = Object.entries(S).filter(([, s]) => s.on && s.on !== 'mano'), behind = [];
    for (const [k, s] of on) {
      const rows = (probes.spotsPx[k] || []).filter(r => r.tag === s.on).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz || (Math.abs(a.r.dx) + Math.abs(a.r.dy)) - (Math.abs(b.r.dx) + Math.abs(b.r.dy)))[0];
      const ok = rows && rows.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + s.on + ', ' + (rows ? 'depth ' + r2(rows.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(rows.dz) + ') at ' + rows.r.dx + ', ' + rows.r.dy + ' px from the spot' : 'none'));
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (part ' + s.on + '): ' + (rows ? 'the nearest pixel of it is at depth ' + r2(rows.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel of that part within 8 px across and 3 rows up of the spot'));
    }
    for (const [k, s] of Object.entries(S)) {                                                         // information: a ground spot whose feet pixel the set draws nearer than the feet (the person stands behind it)
      if (!s.uv || s.uv[2] !== 0) continue;
      const feet = (probes.spotsPx[k] || []).find(r => r.dx === 0 && r.dy === -1);
      if (feet && feet.z > s.depth + .08) behind.push(k + ' ' + s.screen + ' (' + (feet.tag || 'ground') + ' ' + r2(feet.z - s.depth) + ' nearer)');
    }
    const o = add('spots-on-surface', bad, on.length + ' spots above the ground (' + on.map(([k]) => k).join(', ') + ') are on the top of what the set draws there (its depth within .1 of the spot\'s: the balcony\'s floor z 2.1, the ladder, the counter\'s top z 1.0, a stool\'s top z .4, the table\'s cloth z .72, the cage\'s stand z .8, the prize table z .7); mano_arriba, mano_abajo and mano_lado are on a sprite (the hand)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       info, not a check: ground spots whose feet pixel the set draws nearer than the feet (the person stands behind it: the depth rule hides what it covers): ' + (behind.join(', ') || 'none'));
  }

  // 4. the signs and the small things are inside the window and the picture; the set's own things (the face, the door, the flap, the balcony, the ladder, the quiosco) are reported
  {
    const bad = [], lines = [], info = [];
    const boxed = [['carta_a', T.carta_a.box], ['carta_b', T.carta_b.box], ...['n40', 'n60', 'n80', 'n90', 'n100'].map(k => [k, T[k].box]), ...['plato', 'jaula', 'premio1', 'premio2', 'premio3'].map(k => [k, S[k].box])];
    for (const [k, b] of boxed) {
      const l = x0 - b[0], r = b[0] + b[2] - (x0 + VIEW_W), t = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || t > 0 || bt > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + VIEW_W) + ')' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (t > 0 ? ' by ' + t + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : '') + (pl > 0 || pr > 0 ? ' (the picture ends first)' : ''));
    }
    for (const k of ['reloj', 'arriba', 'abajo', 'puertita', 'tapa', 'balcon', 'escalera', 'quiosco']) { const b = T[k].box, cl = Math.max(0, x0 - b[0]), cr = Math.max(0, b[0] + b[2] - (x0 + VIEW_W)); info.push(k + ' [' + b + ']: ' + (cl || cr ? 'the window cuts ' + [cl && cl + ' px at the left', cr && cr + ' px at the right'].filter(Boolean).join(' and ') + ' of its ' + b[2] + ' columns' : 'whole in the window')); }
    const o = add('things-in-view', bad, 'the signs and the small things (' + lines.join(', ') + ') are inside the window [' + x0 + ', ' + (x0 + VIEW_W) + ') and the picture', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of info) o.lines.push('       info, not a check: the set\'s ' + l);
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [], info = [];
    // the frog on abuela's table stands in front of abuela, who sits behind it (the coordinator's decision): exempt against her only (Luis stands beside the table); table-heads checks his heads
    const exempt = (a, b) => ((a.at === 'mesa_abuela.coqui' && b.at === 'mesa_abuela.abuela') || (b.at === 'mesa_abuela.coqui' && a.at === 'mesa_abuela.abuela')) ? 'the frog on the table, in front of abuela who sits behind it (see table-heads)' : null;
    for (const m of MOMENTS) {
      const L = layersOf(m).filter(person);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN, ex = exempt(a, b);
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok, ex });
        if (!ok && ex) info.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] ~ ' + b.at + ' [' + b.sx + ',' + b.sy + ']: ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (' + ex + ')');
        else if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {                                                            // the least shift of a spot in u, in v or in z that passes
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const counted = all.filter(q => !q.ex);
    const o = add('sprites-apart', bad, counted.length + ' pairs counted (' + (all.length - counted.length) + ' more not counted) in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the counted pairs that do overlap sideways: ' + (counted.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + counted.length + ' counted pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = counted.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    for (const t of info) o.lines.push('       info, not counted: ' + t);
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok, notCounted: q.ex }));
  }

  // 5b. table-heads: the frog on abuela's table (moment 6) covers no more than 10% of the head (the top 14 rows of the sprite) of abuela, and none of Luis's
  {
    const LIMIT = { 'mesa_abuela.abuela': .1, 'mesa_abuela.luis': 0 };
    const bad = [], lines = [], L = layersOf(6), fi = L.findIndex(l => l.at === 'mesa_abuela.coqui'), fails = [];
    for (const k of ['mesa_abuela.abuela', 'mesa_abuela.luis']) {
      const i = L.findIndex(l => l.at === k), a = L[i], top = Math.min(...a.px.map(p => p[1])), c = coverage(L, i, p => p[1] < top + HEAD_ROWS), byFrog = c.by['mesa_abuela.coqui'] || 0, lim = LIMIT[k] * c.total;
      lines.push(k + ' ' + [a.sx, a.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ': ' + byFrog + ' of ' + c.total + ' px under the frog (' + (100 * byFrog / c.total).toFixed(1) + '%, the limit ' + (LIMIT[k] * 100) + '% = ' + Math.floor(lim) + ' px)' + (c.cov - byFrog ? ' (and ' + (c.cov - byFrog) + ' under ' + byTxt(Object.fromEntries(Object.entries(c.by).filter(([n]) => n !== 'mesa_abuela.coqui'))) + ')' : '') + (c.hid ? ', ' + c.hid + ' hidden by the set' : ''));
      if (byFrog > lim + 1e-9) { bad.push(k + ': the frog covers ' + byFrog + ' of the ' + c.total + ' px of its head (rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + '), the limit is ' + Math.floor(lim)); fails.push([i, k, LIMIT[k]]); }
    }
    const o = add('table-heads', bad, 'in moment 6 the frog on abuela\'s table covers no more than 10% of the head (the top ' + HEAD_ROWS + ' rows of the sprite) of abuela and none of Luis\'s: ' + lines.join('; '), ['the frog covers too much of a head at the table:'].concat(bad.map(b => '  ' + b)));
    for (const [i, k, lim] of fails) { const rc = await PV.nearestCover(6, fi, i); o.lines.push('       nearest passing, move the frog mesa_abuela.coqui ' + S['mesa_abuela.coqui'].uv + ' so that he covers none of ' + k + '\'s head (the search ignores the 10% allowance and clears it entirely): ' + nearestTxt(rc, S['mesa_abuela.coqui'].uv)); }
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 6. frog-seen: the frog is never behind a grown-up or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer person, thing or sign);
  //    his 32 x 25 box is reported too (the pixels of the box where the set or another sprite is nearer than he is, drawn by him or not)
  {
    const bad = [], lines = [], fails = [], fx = [];
    for (const m of MOMENTS.concat(EXTRA)) {
      const L = layersOf(m), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverage(L, fi);
      const bx = await boxCovOf(PV, m, fi);
      const txt = 'm' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + c.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer person, thing or sign' + (c.cov ? ' (' + byTxt(c.by) + ')' : '') + ', ' + c.out + ' outside the picture; his 32 x 25 box: ' + bx.setN + ' px where the set is nearer, ' + bx.sprN + ' where another sprite is' + (bx.sprN ? ' (' + byTxt(bx.by) + ')' : '');
      lines.push(txt);
      if (EXTRA.includes(m)) continue;
      if (c.hid || c.cov || c.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + c.out) + ' of his ' + (f.px.length + c.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.by).join(', ') || 'a person') + ', ' + c.out + ' outside the picture)'); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments (the spec\'s): ' + lines.filter((l, i) => i < MOMENTS.length).join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const L = layersOf(m), r = await PV.nearest(m, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + L[fi].at + ' ' + S[L[fi].at].uv + ': ' + nearestTxt(r, S[L[fi].at].uv));
      for (const nm of Object.keys(coverage(L, fi).by)) { const ci = L.findIndex(l => lbl(l) === nm); if (ci < 0 || !L[ci].at || !S[L[ci].at]) continue; const rc = await PV.nearestCover(m, ci, fi); o.lines.push('       or, moment ' + m + ', move ' + nm + ' ' + S[nm].uv + ' (the one that covers him): ' + nearestTxt(rc, S[nm].uv)); }
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 7. frog-on-hand: the frog at mano_arriba, mano_abajo and mano_lado is whole inside the picture (moments 3, 4, 5)
  {
    const bad = [], lines = [];
    for (const [m, k] of [[3, 'mano_arriba'], [4, 'mano_abajo'], [5, 'mano_lado']]) {
      const L = layersOf(m), f = L.find(l => l.at === k), ys = f.px.map(p => p[1]), xs = f.px.map(p => p[0]);
      const sp = S[k], fh = sheet.hands.frog_on[k];
      lines.push('m' + m + ' ' + k + ' ' + sp.screen + ': his drawing spans columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ', rows ' + Math.min(...ys) + ' to ' + Math.max(...ys) + ' of the ' + G.W + ' x ' + G.H + ' picture (' + f.out + ' px outside); his feet are ' + fh.dist + ' px from the long hand\'s line, ' + fh.along + ' px along it (the hand is ' + HANDS.long + ' px: the tip at ' + fh.tip + ')');
      if (f.out) bad.push('moment ' + m + ' ' + k + ': ' + f.out + ' of his px are outside the picture');
    }
    const o = add('frog-on-hand', bad, 'the frog at mano_arriba, mano_abajo and mano_lado is whole inside the picture: ' + lines.join('; '), ['the frog on the hand is cut by the picture:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 8. tito-face: don Tito at balcon1 covers no more than 8% of the face's pixels (the disc of radius 27 about the face's middle): what he draws, not hidden by the set, on it
  {
    const cx = sheet.things.reloj.disc.centre[0], cy = sheet.things.reloj.disc.centre[1], R = sheet.things.reloj.disc.r;
    const inDisc = (x, y) => Math.hypot(x + .5 - cx, y + .5 - cy) < R;
    const total = sheet.things.reloj.px, bad = [], lines = [], fl = T.tapa.box, dr = T.puertita.box;
    const inBox = (b, p) => p[0] >= b[0] && p[0] < b[0] + b[2] && p[1] >= b[1] && p[1] < b[1] + b[3];
    for (const m of MOMENTS.concat(EXTRA)) {
      const t = layersOf(m).find(l => l.at === 'balcon1'); if (!t) continue;
      const shown = t.px.filter(p => !p[2]), on = shown.filter(p => inDisc(p[0], p[1])).length, ratio = on / total, onFlap = shown.filter(p => inBox(fl, p)).length;
      lines.push('m' + m + ' don Tito at balcon1 ' + [t.sx, t.sy] + ': ' + on + ' of the face\'s ' + total + ' px (' + (100 * ratio).toFixed(2) + '%); ' + onFlap + ' px of the flap\'s box [' + fl + ']');
      if (ratio > TITO_FACE && !EXTRA.includes(m)) bad.push('moment ' + m + ': don Tito covers ' + on + ' of ' + total + ' px of the face (' + (100 * ratio).toFixed(2) + '%), the limit is ' + (TITO_FACE * 100) + '% = ' + Math.floor(TITO_FACE * total) + ' px');
    }
    const o = add('tito-face', bad, 'don Tito at balcon1 covers no more than ' + (TITO_FACE * 100) + '% (' + Math.floor(TITO_FACE * total) + ' of ' + total + ' px) of the face: ' + lines.join('; '), ['don Tito covers too much of the face:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 9. vendedor-head: the vendedor's head (the top 14 rows of his sprite) is covered by nothing (the set's awning, the roof's edge, a nearer sprite or a sign), in the moments that draw him (1, 2, 6)
  {
    const bad = [], lines = [], fails = [];
    for (const m of [1, 2, 6]) {
      const L = layersOf(m), vi = L.findIndex(l => l.at === 'quiosco'), v = L[vi], top = Math.min(...v.px.map(p => p[1])), c = coverage(L, vi, p => p[1] < top + HEAD_ROWS);
      const tg = c.hidPx.length ? await probes.tags(c.hidPx) : [], parts = {}; for (const t of tg) parts[t] = (parts[t] || 0) + 1;
      const hrows = c.hidPx.map(p => p[1]);
      lines.push('m' + m + ' vendedor at quiosco ' + [v.sx, v.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ': ' + (c.total - c.hid - c.cov) + ' of ' + c.total + ' px show (' + c.hid + ' hidden by the set' + (c.hid ? ': ' + byTxt(parts) + ', rows ' + Math.min(...hrows) + ' to ' + Math.max(...hrows) : '') + ', ' + c.cov + ' covered' + (c.cov ? ' by ' + byTxt(c.by) : '') + ')');
      if (c.hid || c.cov) { bad.push('moment ' + m + ': the vendedor\'s head is covered on ' + (c.hid + c.cov) + ' of ' + c.total + ' px (' + c.hid + ' hidden by the set' + (c.hid ? ' (' + byTxt(parts) + ', rows ' + Math.min(...hrows) + ' to ' + Math.max(...hrows) + ')' : '') + ', ' + c.cov + ' by ' + (Object.keys(c.by).join(', ') || 'sprites') + ')'); fails.push([m, vi]); }
    }
    const o = add('vendedor-head', bad, 'nothing covers the top ' + HEAD_ROWS + ' rows of the vendedor\'s sprite (his paper hat, ' + PAPER_HAT + ' rows, and 10 rows of head) in moments 1, 2 and 6 (the awning and its edge included): ' + lines.join('; '), [bad.length + ' moment(s) where the vendedor\'s head is covered:'].concat(bad.map(b => '  ' + b)));
    const done = new Set();
    for (const [m, vi] of fails) { if (done.has(layersOf(m)[vi].sx + ',' + layersOf(m)[vi].sy)) continue; done.add(layersOf(m)[vi].sx + ',' + layersOf(m)[vi].sy); const r = await PV.nearest(m, vi, 0, HEAD_ROWS); o.lines.push('       nearest passing, quiosco ' + S.quiosco.uv + ' (the counter itself stands at v ' + r4(G.E.KIOSK.v - G.E.KIOSK.hd) + ' to ' + r4(G.E.KIOSK.v + G.E.KIOSK.hd) + '): ' + nearestTxt(r, S.quiosco.uv)); }
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 10. cards-clear: in moment 2 the two time cards are placed by the rule (the frog's head, 3 px) and cover neither the frog, the face nor the vendedor
  {
    const bad = [], lines = [], L = layersOf(2), f = L.find(l => l.who === 'coqui'), vend = L.find(l => l.at === 'quiosco'), tito = L.find(l => l.at === 'balcon1');
    const cards = [['carta_a', T.carta_a.box], ['carta_b', T.carta_b.box]];
    const cx = sheet.things.reloj.disc.centre[0], cy = sheet.things.reloj.disc.centre[1], R = sheet.things.reloj.disc.r;
    const inBox = (b, x, y) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
    const frogTop = Math.min(...f.px.map(p => p[1]));
    const rule = cards.every(([, b]) => b[1] + b[3] === frogTop - CARD.above) && cards[0][1][0] + CARD.w + CARD.gap === cards[1][1][0] && (cards[0][1][0] + cards[1][1][0] + CARD.w) / 2 === f.sx;
    lines.push('the frog at pie2 ' + [f.sx, f.sy] + ': his head\'s top row ' + frogTop + '; carta_a ' + JSON.stringify(cards[0][1]) + ' and carta_b ' + JSON.stringify(cards[1][1]) + ': their foot (the row after their last) is at row ' + (cards[0][1][1] + CARD.w) + ', ' + (frogTop - cards[0][1][1] - CARD.w) + ' px above his head\'s top row ' + frogTop + ', ' + (cards[1][1][0] - cards[0][1][0] - CARD.w) + ' px apart, centred on column ' + f.sx);
    if (!rule) bad.push('the cards do not follow the rule (foot ' + CARD.above + ' px above the head, ' + CARD.gap + ' apart, centred on the frog): the sheet\'s boxes ' + JSON.stringify(cards.map(c => c[1])) + ' against the frog\'s top row ' + frogTop + ' and column ' + f.sx);
    for (const [k, b] of cards) {
      const inside = b[0] >= x0 && b[0] + b[2] <= x0 + VIEW_W && b[1] >= 0 && b[1] + b[3] <= G.H;
      const onFrog = f.px.filter(p => !p[2] && inBox(b, p[0], p[1])).length;
      let onFace = 0; for (let y = b[1]; y < b[1] + b[3]; y++) for (let x = b[0]; x < b[0] + b[2]; x++) if (Math.hypot(x + .5 - cx, y + .5 - cy) < R) onFace++;
      const onVend = vend.px.filter(p => !p[2] && inBox(b, p[0], p[1])).length, onTito = tito.px.filter(p => !p[2] && inBox(b, p[0], p[1])).length;
      lines.push(k + ' ' + JSON.stringify(b) + ': ' + (inside ? 'inside' : 'OUTSIDE') + ' the picture and the window; covers ' + onFrog + ' px of the frog, ' + onFace + ' of the face, ' + onVend + ' of the vendedor (and ' + onTito + ' of don Tito, information)');
      if (!inside) bad.push(k + ' ' + JSON.stringify(b) + ' is outside the window [' + x0 + ', ' + (x0 + VIEW_W) + ') or the picture');
      if (onFrog || onFace || onVend) bad.push(k + ' ' + JSON.stringify(b) + ' covers ' + onFrog + ' px of the frog, ' + onFace + ' of the face, ' + onVend + ' of the vendedor');
    }
    const o = add('cards-clear', bad, 'in moment 2 the two cards (carta_a ' + JSON.stringify(cards[0][1]) + ', carta_b ' + JSON.stringify(cards[1][1]) + ': ' + CARD.w + ' px squares ' + CARD.gap + ' px apart, centred on the frog at pie2, their foot ' + CARD.above + ' px above his head) are inside the window and cover neither the frog, the face nor the vendedor: ' + lines.join('; '), ['the cards:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  // 11. carton-clear: in moment 6 every square of abuela's card is in the window and covered by nobody (nobody's drawing, shown, lies on it); if not, the least move of the row that clears it
  {
    const L = layersOf(6), others = L.filter(l => !l.overlay && l.px.length), bad = [], lines = [];
    const sqs = ['n40', 'n60', 'n80', 'n90', 'n100'].map(k => [k, T[k].box]);
    const hit = (b, dx, dy) => { let n = 0; const by = {}; for (const l of others) for (const p of l.px) if (!p[2] && p[0] >= b[0] + dx && p[0] < b[0] + dx + b[2] && p[1] >= b[1] + dy && p[1] < b[1] + dy + b[3]) { n++; by[lbl(l)] = (by[lbl(l)] || 0) + 1; } return { n, by }; };
    for (const [k, b] of sqs) {
      const inside = b[0] >= x0 && b[0] + b[2] <= x0 + VIEW_W && b[1] >= 0 && b[1] + b[3] <= G.H, h = hit(b, 0, 0);
      lines.push(k + ' ' + JSON.stringify(b) + ': ' + (inside ? 'in the window' : 'OUTSIDE the window') + ', ' + h.n + ' px of other sprites on it' + (h.n ? ' (' + byTxt(h.by) + ')' : ''));
      if (!inside) bad.push(k + ' ' + JSON.stringify(b) + ' is outside the window [' + x0 + ', ' + (x0 + VIEW_W) + ')');
      if (h.n) bad.push(k + ' ' + JSON.stringify(b) + ' is covered: ' + h.n + ' px of ' + byTxt(h.by));
    }
    const o = add('carton-clear', bad, 'in moment 6 every square of abuela\'s card (n40, n60, n80, n90, n100: ' + sqs.map(s => JSON.stringify(s[1])).join(', ') + ') is in the window [' + x0 + ', ' + (x0 + VIEW_W) + ') and covered by nobody: ' + lines.join('; '), ['the card of numerals:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) {                                                                                       // the least move of the row (whole pixels, by distance) that clears it
      let best = null;
      for (let r = 0; r <= 60 && !best; r++) for (let dy = -r; dy <= r && !best; dy++) for (let dx = -r; dx <= r; dx++) { if (Math.max(Math.abs(dx), Math.abs(dy)) !== r) continue; const d = Math.hypot(dx, dy); if (best && d >= best.d) continue; if (sqs.every(([, b]) => b[0] + dx >= x0 && b[0] + dx + b[2] <= x0 + VIEW_W && b[1] + dy >= 0 && b[1] + dy + b[3] <= G.H && !hit(b, dx, dy).n)) best = { dx, dy, d }; }
      o.lines.push('       nearest passing: ' + (best ? 'move the row by (' + best.dx + ', ' + best.dy + '): its top left at (' + (CARTON.x + best.dx) + ', ' + (CARTON.y + best.dy) + ')' : 'none within 60 px') + ' (the spec: "move the row the least distance that clears it and report where")');
      for (const l of lines) o.lines.push('       ' + l);
    }
  }

  // 12. bingo-clear: in moment 6 the cage and the three prizes are covered by nobody: no person, no sign and no other prize or thing nearer than they are, and nothing of the set, on their pixels
  {
    const L = layersOf(6), bad = [], lines = [];
    for (const k of ['jaula', 'premio1', 'premio2', 'premio3']) {
      const i = L.findIndex(l => l.at === k), f = L[i], c = coverage(L, i), n = Object.values(c.by).reduce((a, b) => a + b, 0);
      lines.push(k + ' ' + [f.sx, f.sy] + ' (' + f.px.length + ' px): ' + c.hid + ' hidden by the set, ' + n + ' under others' + (n ? ' (' + byTxt(c.by) + ')' : ''));
      if (c.hid || n) bad.push(k + ' ' + [f.sx, f.sy] + ': ' + c.hid + ' px hidden by the set, ' + n + ' under ' + (Object.keys(c.by).join(', ') || 'others'));
    }
    const o = add('bingo-clear', bad, 'in moment 6 the cage and the three prizes are covered by nobody (no person, sign or other prize nearer, nothing of the set; the prizes stand side by side on the long table: boxes ' + ['premio1', 'premio2', 'premio3'].map(k => JSON.stringify(S[k].box)).join(', ') + '): ' + lines.join('; '), ['the cage or a prize is covered:'].concat(bad.map(b => '  ' + b)));
    if (bad.length) for (const l of lines) o.lines.push('       ' + l);
  }

  OUTS.push({ name: 'info-stand-ins', ok: true, lines: ['info-stand-ins: not a check. Stand-ins used for size: don Tito, the señor and the vendedor are grown-up men (mkPersona; the vendedor with a paper hat, 4 rows taller than the stand-in\'s head: his head\'s top 14 rows are the hat and 10 rows of head), the señora who calls the bingo is a grown-up woman (mkPersona, skirt), abuela sits (mkAbuelaS), Luis and Carmen are the family\'s children, the frog is mkCoqui(1). The hands, the two time cards, the plate, the cage, the prizes, the card of numerals and its beans are drawn in the preview as plain stand-ins.'] });
  return OUTS;
}

// the frog's box: the pixels of his 32 x 25 box where the set's baked depth is nearer than he is, and where another sprite is (the preview's picture, read through PREVIEW.inspect)
async function boxCovOf(PV, m, fi) {
  const L = PV.inspect[m].layers, f = L[fi], best = new Map(), key = (x, y) => y * 240 + x;
  L.forEach((l, j) => { if (j === fi) return; for (const p of l.px) if (!p[2]) { const k = key(p[0], p[1]), b = best.get(k); if (!b || b.plane < p[3]) best.set(k, { plane: p[3], at: l.at || l.thing || l.s }); } });
  const Z = await PV.page.evaluate(async m => (await window.PREVIEW.zrow(m)), m);
  let setN = 0, sprN = 0; const by = {};
  for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) {
    if (x < 0 || x >= 240 || y < 0 || y >= 216) continue;
    const plane = f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / 26;
    if (Z[key(x, y)] > plane + BIAS) { setN++; continue; }
    const b = best.get(key(x, y)); if (b && b.plane > plane + EPS) { sprN++; by[b.at] = (by[b.at] || 0) + 1; }
  }
  return { setN, sprN, by };
}
