#!/usr/bin/env node
'use strict';
/* El quiosco's sheet (place 6, scene 3): writes docs/proyecto/pixel/quiosco-sheet.json from quiosco-set.html and the design (the orchestrator's p6-spec: the rules for every sheet, and "quiosco"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/quiosco-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture, in (u, v, z): u across the picture, v down it; a spot is given in (u, v, z)
   and the set's PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives its world place; the make projects it with the engine's own project() (pp-engine.js). In the picture sx = OX + u S and
   sy = OY + (v / 2 - z cos 30) S. The set's constants (the counter, the wings, the stools, the table) are read from window.QUIOSCO.E, never typed again.
   It loads the set in headless Chrome (tags=1: which part drew each pixel; the baked depth) and writes the spots, things, the one view (wide), shadows and the depth rule. The checks that say
   "covers" or "shows" read the PREVIEW's six moments (quiosco-preview.html, PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the
   sheet is written again with the checks. It prints one line per check and exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with QUIOSCO_BASE), but every request to it is answered from the files of THIS tree
   (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'quiosco-sheet.json');
const BASE = process.env.QUIOSCO_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/quiosco-set.html';
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
const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2;

// the numbers of the design (p6-spec: the rules for every sheet, and "quiosco")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = { taburete: .68, silla: .42, mesa: .72 }; // the stools' seat top, the chairs' seat top, the table's top (the spec gives them; read back from the set's depth: spots-on-surface)
const SIGN = { u: 0, v: .25, z: 0, r: 10.5 };            // the cup sign on the roof's front (quiosco-set.html: PZ.wall at v = .25, a disc of 10.5 px round (u 0, z ROOF + .54: z is set from the set's ROOF))
const X0 = 22;                                           // the view's x0: the orchestrator's decision (the picture's own centre); the make checks that it holds every spot
const MOMENTS = [1, 2, 3, 4, 5, 6];
const STANDIN = { cupula: 'the glass dome of barra_izq (20 x 18)', torre: 'the cake stand with its tower (20 x 28 inked)', caja: 'the box (16 x 12)', vela_a: 'candle (8 x 12)', vela_b: 'candle (8 x 12)', vela_c: 'candle (8 x 12)' };

// the spots: [name, (u, v, z), kind, silhouette, character kind, on (what it stands on), what, extra]
const spotsOf = E => {
  const CH = E.CH, WG = E.WING, T = E.TABLE, ST = E.STOOLS;
  return [
    ['taburete1', [ST[0][0], ST[0][1], SEAT_Z.taburete], 'person', 'doctor.S', 'adulto', 'stool', 'whoever sits on the first stool (the far left): on its seat, z ' + SEAT_Z.taburete + '; faces right', { face: 'right' }],
    ['taburete2', [ST[1][0], ST[1][1], SEAT_Z.taburete], 'person', 'doctor.S', 'adulto', 'stool', 'the second stool (left, beside the front counter): faces right', { face: 'right' }],
    ['taburete3', [ST[2][0], ST[2][1], SEAT_Z.taburete], 'person', 'doctor.S', 'adulto', 'stool', 'the third stool (right, beside the front counter): faces left', { face: 'left' }],
    ['taburete4', [ST[3][0], ST[3][1], SEAT_Z.taburete], 'person', 'doctor.S', 'adulto', 'stool', 'the fourth stool (the far right): faces left', { face: 'left' }],
    ['barra1', [WG.uL, 1.35, CH], 'person', 'coqui', 'coqui', 'wing', 'the frog on the left wing\'s top, near the camera, beside stool 1: on the wing, z ' + CH],
    ['barra2', [-1.55, .1, CH], 'person', 'coqui', 'coqui', 'wing', 'the frog on the left wing\'s top, at its far end, beside stool 2 (u -1.55: the orchestrator moved it .2 in from the wing\'s middle, so his box clears the sitter of stool 2)'],
    ['barra3', [1.55, .1, CH], 'person', 'coqui', 'coqui', 'wing', 'the frog on the right wing\'s top, at its far end, beside stool 3 (u 1.55: .2 in from the wing\'s middle)'],
    ['barra4', [WG.uR, 1.35, CH], 'person', 'coqui', 'coqui', 'wing', 'the frog on the right wing\'s top, near the camera, beside stool 4'],
    ['barra_c', [0, -.2, CH], 'person', 'coqui', 'coqui', 'counter', 'the frog in the middle of the front counter\'s top (z ' + CH + ')'],
    ['barra_izq', [-1.2, -.2, CH], 'thing', null, null, 'counter', 'the counter\'s left end: the glass dome (66) and the cake stand (68): two sprites at one spot', { standin: ['cupula', 'torre'] }],
    ['barra_fin', [WG.uL, 1.45, CH], 'thing', null, null, 'wing', 'the box with its lid (67), on the near end of the LEFT wing\'s top', { standin: ['caja'] }],
    ['barra_caja', [WG.uL, .5, CH], 'person', 'coqui', 'coqui', 'wing', 'the frog beside the box on the left wing\'s top (67): .7 back along the wing from barra_fin'],
    ['barra_e', [1.0, -.2, CH], 'person', 'coqui', 'coqui', 'counter', 'the frog at the counter\'s right end in story 68'],
    ['vela_a', [-.35, -.15, CH], 'thing', null, null, 'counter', 'a number candle on the tray (68): the first of three, 8 x 12 stand-in', { standin: ['vela_a'] }],
    ['vela_b', [-.05, -.15, CH], 'thing', null, null, 'counter', 'a number candle on the tray: the second', { standin: ['vela_b'] }],
    ['vela_c', [.25, -.15, CH], 'thing', null, null, 'counter', 'a number candle on the tray: the third', { standin: ['vela_c'] }],
    ['limbers', [WG.uR, 1.5, CH], 'thing', null, null, 'wing', 'the three limbers in their cups (67), a row along the right wing\'s top: the spot is the row\'s near end (the front cup); the other two stand .3 and .6 back along the wing', { standin: ['limber_rojo', 'limber_amarillo', 'limber_blanco'] }],
    ['detras', [0, -.78, 0], 'person', 'vendedor', 'adulto', 'ground', 'the vendedor behind his counter, in the booth'],
    ['cola1', [-.78, .75, 0], 'person', 'senora', 'adulto', 'ground', 'the first of the two at the counter (a round\'s two), standing between the wings, left'],
    ['cola2', [.65, .75, 0], 'person', 'senora', 'adulto', 'ground', 'the other of the round\'s two, between the wings, right'],
    ['cola3', [-.65, 2.2, 0], 'person', 'senora', 'adulto', 'ground', 'the next one, behind cola1 (nearer the camera)'],
    ['cola4', [.65, 2.2, 0], 'person', 'senora', 'adulto', 'ground', 'the next one, behind cola2'],
    ['mesa_a', [T[0] - .5, T[1] - .5, SEAT_Z.silla], 'person', 'doctor.S', 'adulto', 'chair', 'the left chair of the round table (abuela\'s place), on its seat, z ' + SEAT_Z.silla + '; the sitter faces the camera, the table in front of him', { face: 'front' }],
    ['mesa_b', [T[0] + .5, T[1] - .5, SEAT_Z.silla], 'person', 'doctor.S', 'adulto', 'chair', 'the right chair of the round table, on its seat, z ' + SEAT_Z.silla, { face: 'front' }],
    ['mesa', [T[0], T[1], SEAT_Z.mesa], 'person', 'coqui', 'coqui', 'table', 'the frog on the table\'s top, z ' + SEAT_Z.mesa],
    ['pie1', [-1.2, 3.3, 0], 'person', 'luis', 'nino', 'ground', 'standing beside the table, right of it (Luis)'],
    ['pie2', [-1.2, 4.4, 0], 'person', 'carmen', 'nino', 'ground', 'standing beside the table, in front of pie1 (Carmen)'],
    ['entrada', [4.7, 2.6, 0], 'entry', 'senor', 'adulto', 'ground', 'where people come in: from the right, just outside the picture on purpose (the picture ends at column 240)'],
  ];
};
// the people of the six moments: the stand-in each is drawn with (the make's report and the sheet's notes)
const STANDINS_PEOPLE = {
  vendedor: 'a grown-up (the señor) in an apron and a 4-row paper hat', maestra: 'a grown-up (the señora)', doctor: 'a grown-up (the hombre) in white', cocinero: 'a grown-up (the hombre) in white', policia: 'a grown-up (the hombre) in blue',
  joven: 'the joven of El parque (the young man)', la_joven: 'a grown-up (the mujer)', mama_ana: 'mamá (a grown-up)', beto: 'a child (Luis\'s drawing, other colours)', ana: 'a child (Carmen\'s drawing, other colours)',
  nino: 'a child (Luis\'s drawing, other colours)', nina: 'a child (Carmen\'s drawing, other colours)', abuela: 'abuela sitting (mkAbuelaS)', luis: 'Luis', carmen: 'Carmen', senor: 'the señor', senora: 'the señora', hombre: 'the hombre', mujer: 'the mujer',
};

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?hora=mediodia&fiesta=0&tags=1');
  const G = await page.evaluate(() => ({ E: JSON.parse(JSON.stringify(QUIOSCO.E)), scene: PP_SCENE, W, H, S, OX, OY, pzxy: PZ.xy(.7, -1.3) }));
  SIGN.z = G.E.ROOF + .54;
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet0 = await make(G, proj, null);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet0, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const PV = await previewData(browser, errs);
  const sheet = await make(G, proj, PV.boxes);
  const probes = await probeSets(page, sheet, G);
  const results = await checks(sheet, G, probes, PV);
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

/* ---------- the preview's moments: quiosco-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its id, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/quiosco-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {} };
  PV.boxes = await p.evaluate(() => window.PREVIEW.boxes());
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow, head, guard, selfOff) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow, x.head, x.guard, x.selfOff), { st, specs, idx, allow: allow || 0, head: head || 0, guard: guard || [], selfOff: !!selfOff });
  return PV;
}

// the screen point of a spot at (u, v, z): the same arithmetic as pp-engine.js project, rounded to a pixel
const scrUV = (G, u, v, z) => [Math.round(G.OX + u * G.S), Math.round(G.OY + (v * .5 - z * COS) * G.S)];

// the ink box of a spot's stand-in: [x0, y0, x1, y1] from the point's column and row; a person's nominal box is its width (the frog 32, a grown-up 24, a child 24)
const halfOf = (s, BOX) => s.who ? WIDTH[s.who] / 2 : (s.standinBox ? s.standinBox.w / 2 : 0);

// how many px of a spot are cut by the window at x0: its point outside, or (a person) his sprite box (the stand-in's box for a small thing); 0 when whole
function cutAt(s, x0) {
  const sx = s.screen[0], h = s.who ? WIDTH[s.who] / 2 : (s.standinBox ? s.standinBox.w / 2 : 0);
  if (s.kind === 'entry') return 0;
  if (!h) return sx < x0 ? x0 - sx : sx > x0 + 195 ? sx - x0 - 195 : 0;
  return Math.max(0, x0 - Math.floor(sx - h)) + Math.max(0, Math.ceil(sx + h - 1) - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj, BOX) {
  const E = G.E, sc = G.scene, SP = spotsOf(E);
  const pr = await proj(SP.map(s => s[1]));
  const spots = {};
  SP.forEach((s, i) => {
    const q = pr[i], o = { world: W4([q[3], q[4], s[1][2]]), uv: W4(s[1]), screen: [Math.round(q[0]), Math.round(q[1])], depth: r4(q[2]), scale: 1, kind: s[2], view: 'wide', what: s[6] };
    if (s[3]) o.sprite = s[3];
    if (s[4]) o.who = s[4];
    o.on = s[5];
    if (s[7] && s[7].face) o.face = s[7].face;
    if (s[7] && s[7].standin) {
      o.standin = s[7].standin;
      if (BOX) { const b = BOX[s[7].standin[0]], w = b.box[2] - b.box[0] + 1; o.standinBox = { w, h: b.box[3] - b.box[1] + 1 }; }
    }
    spots[s[0]] = o;
  });

  /* ---- the view: x0 so that every spot is inside; the window's point is the ground point under its middle column at the picture's middle row ---- */
  // the extent of what the window must hold: a person's sprite box (a small thing: its stand-in's box; the entry: nothing), in columns
  const holds = Object.keys(spots).filter(k => spots[k].kind !== 'entry');
  const ext = holds.map(k => { const sp = spots[k], h = halfOf(sp), sx = sp.screen[0]; return [Math.floor(sx - h), Math.ceil(sx + h - (h ? 1 : 0))]; });
  const lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1])), want = Math.max(0, Math.min(G.W - 196, Math.round((lo + hi) / 2 - 98)));
  // the x0 (0 to 44) at which the fewest spots are cut, then the fewest px, then the nearest to the middle of the spots' extent
  let best = null;
  for (let x0 = 0; x0 <= G.W - 196; x0++) {
    let n = 0, px = 0;
    for (const k of holds) { const c = cutAt(spots[k], x0); if (c) { n++; px += c; } }
    const key = [n, px, Math.abs(x0 - want)];
    let better = !best; if (best) for (let i = 0; i < key.length; i++) { if (key[i] !== best.key[i]) { better = key[i] < best.key[i]; break; } }
    if (better) best = { x0, key };
  }
  const x0 = X0, byRule = best.x0;
  const okAll = []; for (let x = 0; x <= G.W - 196; x++) if (holds.every(k => !cutAt(spots[k], x))) okAll.push(x);
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [66, 67, 68], holds, extent: [lo, hi],
      holdsAll: okAll.length ? [okAll[0], okAll[okAll.length - 1]] : null,
      what: 'the one view of stories 66, 67 and 68: the 196 x 216 window over the 240 x 216 picture. The spec: every spot of every moment inside it with its sprite whole (entrada is outside on purpose). x0 ' + x0 + ' is the orchestrator\'s decision (the picture\'s own centre); ' + (okAll.includes(x0) ? 'it holds them all (the spots span columns ' + lo + ' to ' + hi + '; every x0 from ' + okAll[0] + ' to ' + okAll[okAll.length - 1] + ' holds them; the one nearest the middle of the spots\' extent would be ' + byRule + ')' : 'it cuts ' + holds.filter(k => cutAt(spots[k], x0)).length + ' spot(s); the best by the rule is ' + byRule) + '. The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const CH = E.CH, WG = E.WING, F = E.FRONT, T = E.TABLE;
  // the set's own measures that the constants do not carry (quiosco-set.html: stand(), table()): the roof's edge reaches .35 beyond the wings' middles, its front is at v .22, its top at ROOF + 1.0, the ball .28 above that; the stools' seat is a disc of radius .2; the table's top has radius .52, the chairs .5 either side and .2 half-wide, their backs at .68 back
  const boxOf = async (u0, v0, z0, u1, v1, z1, what) => {
    const corners = []; for (const u of [u0, u1]) for (const v of [v0, v1]) for (const z of [z0, z1]) corners.push([u, v, z]);
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]), fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), bx = fl(Math.min(...xs)), by = fl(Math.min(...ys));
    return { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: [bx, by, ce(Math.max(...xs)) - bx, ce(Math.max(...ys)) - by], what };
  };
  const mid = (F.u0 + F.u1) / 2, roofU0 = WG.uL - .35, roofU1 = WG.uR + .35, ROOFTOP = E.ROOF + 1.0 + .28;
  const things = {};
  things.quiosco = await boxOf(roofU0, E.BACK - .1, 0, roofU1, .22, ROOFTOP, 'the booth: its back wall, posts and roof (the roof\'s edge, its slope, the ball); the counter and the stools are their own things. A poke');
  const dq = (await proj([[SIGN.u, SIGN.v, SIGN.z]]))[0], dx0 = Math.floor(dq[0] - SIGN.r), dy0 = Math.floor(dq[1] - SIGN.r), dw = Math.ceil(dq[0] + SIGN.r) - dx0, dh = Math.ceil(dq[1] + SIGN.r) - dy0;
  const lw = await boxOf(mid - .62, SIGN.v, E.ROOF + .06, mid + .62, SIGN.v, E.ROOF + 1.02, '');
  things.letrero = { set: true, uv: lw.uv, world: lw.world, box: [dx0, dy0, dw, dh], disc: { cx: r2(dq[0]), cy: r2(dq[1]), r: SIGN.r }, what: 'the cup sign on the roof\'s front: a round board of ' + SIGN.r + ' px radius on the wall at v ' + SIGN.v + '; box = the disc\'s square, world = the wall it is drawn on. A poke' };
  things.barra = await boxOf(WG.uL - WG.hw, Math.min(F.v0, WG.v0), 0, WG.uR + WG.hw, WG.v1, CH, 'the counter: the front counter (v ' + F.v0 + ' to ' + F.v1 + ') and the two wings (to v ' + WG.v1 + '), height ' + CH + '. A poke');
  const stool = async (k, [u, v]) => boxOf(u - .2, v - .2, 0, u + .2, v + .2, SEAT_Z.taburete, 'taburete' + (k + 1));
  const each = []; for (const [k, s] of E.STOOLS.entries()) each.push(await stool(k, s));
  const tu0 = Math.min(...E.STOOLS.map(s => s[0])) - .2, tu1 = Math.max(...E.STOOLS.map(s => s[0])) + .2, tv0 = Math.min(...E.STOOLS.map(s => s[1])) - .2, tv1 = Math.max(...E.STOOLS.map(s => s[1])) + .2;
  things.taburetes = Object.assign(await boxOf(tu0, tv0, 0, tu1, tv1, SEAT_Z.taburete, 'the four stools (seat top z ' + SEAT_Z.taburete + '): the box of all four; each stool\'s own box is in `each`. A poke'), { each: each.map(e => e.box) });
  things.mesa = await boxOf(T[0] - .72, T[1] - .71, 0, T[0] + .72, T[1] + .52, .95, 'the round table (top z ' + SEAT_Z.mesa + ', radius .52) and its two chairs (seats z ' + SEAT_Z.silla + ', backs to .95). A poke');
  for (const k of ['caja', 'quesitos', 'torre', 'limbers', 'vela_a', 'vela_b', 'vela_c']) things[k] = 'sprite';
  for (const k of ['vendedor', 'maestra', 'doctor', 'cocinero', 'policia', 'senor', 'senora', 'hombre', 'mujer', 'joven', 'la_joven', 'nino', 'nina', 'beto', 'ana', 'carmen', 'luis', 'abuela', 'mama_ana', 'coqui']) things[k] = 'sprite';

  // the stand-ins' boxes (the sprites that stay in the sprite layer): where each hangs and how big it is drawn here (the spec gives the candles' and the limbers' sizes only in part: the others are this make's stand-ins: open point)
  const standins = {};
  if (BOX) {
    const at = async (k, spr, off) => { const s = spots[k], q = (await proj([[s.uv[0] + off[0], s.uv[1] + off[1], s.uv[2] + off[2]]]))[0], b = BOX[spr], sx = Math.round(q[0]), sy = Math.round(q[1]); return { sx, sy, box: [sx + b.box[0], sy + b.box[1], b.box[2] - b.box[0] + 1, b.box[3] - b.box[1] + 1] }; };
    const one = async (key, k, spr, what) => { const p = await at(k, spr, [0, 0, 0]); standins[key] = { at: k, sprite: spr, size: [p.box[2], p.box[3]], box: p.box, what }; };
    await one('quesitos', 'barra_izq', 'cupula', 'the glass dome with its three quesitos, a 20 x 18 stand-in: its bottom middle on barra_izq (the spec gives no size)');
    await one('torre', 'barra_izq', 'torre', 'the cake stand with Beto\'s tower of three bizcochos and the candle of its 5, a stand-in drawn on a 22 x 28 canvas (inked 20 x 28, see size): its bottom middle on barra_izq (the spec gives no size)');
    await one('caja', 'barra_fin', 'caja', 'the box with its lid, a 16 x 12 stand-in: its bottom middle on barra_fin (the spec gives no size)');
    for (const c of ['a', 'b', 'c']) await one('vela_' + c, 'vela_' + c, 'vela_' + c, 'a number candle, an 8 x 12 stand-in (the spec\'s size): its bottom middle on the spot');
    const cups = [['limber_rojo', 0], ['limber_amarillo', -.3], ['limber_blanco', -.6]], bs = [];
    for (const [spr, dv] of cups) bs.push((await at('limbers', spr, [0, dv, 0])).box);
    const x0b = Math.min(...bs.map(b => b[0])), y0b = Math.min(...bs.map(b => b[1])), x1b = Math.max(...bs.map(b => b[0] + b[2])), y1b = Math.max(...bs.map(b => b[1] + b[3]));
    standins.limbers = { at: 'limbers', sprite: 'limber_rojo + limber_amarillo + limber_blanco', size: [x1b - x0b, y1b - y0b], box: [x0b, y0b, x1b - x0b, y1b - y0b], cups: bs, what: 'three 6 x 7 cups (red, yellow, white) in a row along the right wing, .3 apart in v running back from the spot: the first on the spot, its bottom middle on it' };
    standins.bandeja_rana = { sprite: 'bandejaRana', size: [22, 10], what: 'story 66 game: the frog\'s tray (with a cup), a 22 x 10 stand-in drawn on his head, its bottom edge on the row of his top (the spec says only "with a tray")' };
    standins.cosa_cabeza = { sprite: 'cosa', size: [12, 12], what: 'story 67 game: the thing over the frog\'s head, a 12 px square (the spec\'s size): its bottom edge on the row of his top' };
    standins.bandeja_velas = { sprite: 'bandeja', size: [28, 4], what: 'story 68 game: the tray the candles stand on, a 28 x 4 plate under vela_a to vela_c (not a thing of the sheet: it only keeps the candles from floating)' };
  }

  return {
    scene: 'quiosco',
    made: 'node docs/proyecto/pixel/quiosco-sheet-make.js, from quiosco-set.html (window.QUIOSCO.E) and the design of El quiosco (the orchestrator\'s p6-spec, section quiosco). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is turned 45 degrees: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera); the set\'s PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z. The front counter runs across the picture at v ' + F.v0 + ' to ' + F.v1 + ' (the vendedor stands behind it, in the booth); the two wings come towards the camera at u ' + WG.uL + ' and ' + WG.uR,
      spot: 'a spot is a world point of the feet (z 0: the ground; z ' + SEAT_Z.taburete + ': a stool\'s seat; ' + SEAT_Z.silla + ': a chair\'s; ' + SEAT_Z.mesa + ': the table\'s top; ' + CH + ': the counter\'s and the wings\' top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up, 41 for a child; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a child or a grown-up sitting (mkPersona with sent = 1; the stool, the chair): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 7 a child: 33; t 11 a grown-up: 41) on (sx, sy), the spot being the seat\'s top. The sitting drawing is the front view: whoever sits on a stool faces right (stools 1 and 2) or left (3 and 4) in the game; the sheet says it (spots.*.face), the stand-in does not turn. A small thing: its bottom middle on the point',
      view: 'the view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = the window\'s left column. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      box: 'a person\'s box is its width (the frog 32, a grown-up 24, a child 24, the dog 28) with the feet\'s spot in the middle; the rows come from the drawn sprite',
    },
    setKey: {
      params: { hora: { values: ['mediodia', 'tarde'], note: '66 mediodia (the script: "Es mediodía"), 67 tarde ("an afternoon with no work"), 68 tarde ("Start: afternoon")' }, fiesta: { values: [0, 1], note: 'the paper chains on the roof\'s edge and from the posts (story 68)' } },
      key: 'hora + fiesta, e.g. "tarde-1"',
      baked: ['mediodia', 'tarde'].flatMap(h => [0, 1].map(f => '?hora=' + h + '&fiesta=' + f)),
      used: { 66: 'mediodia-0', 67: 'tarde-0', 68: 'tarde-1' },
    },
    things,
    standins,
    spots,
    groups: { taburetes: ['taburete1', 'taburete2', 'taburete3', 'taburete4'], barras: ['barra1', 'barra2', 'barra3', 'barra4'], velas: ['vela_a', 'vela_b', 'vela_c'], cola: ['cola1', 'cola2', 'cola3', 'cola4'], mesa: ['mesa_a', 'mesa_b', 'mesa', 'pie1', 'pie2'] },
    stands_in_for: STANDINS_PEOPLE,
    notes: [
      'every number of a spot is the orchestrator\'s (the quiosco section of p6-spec), given in (u, v, z); the stools, the wings, the table come from the set\'s own constants (QUIOSCO.E: STOOLS, WING, TABLE, CH), the rest are the spec\'s numbers',
      'the sheet\'s spots are generic: a stool or a chair holds whoever the story puts there (a grown-up or a child: the same 24 px box); `who` is the default box kind',
      'the view is one: wide (x0 ' + x0 + '); the picture\'s right edge is at column 240 and entrada (u 4.7) is at column ' + spots.entrada.screen[0] + ', outside on purpose',
      'the limbers row runs back along the right wing from the spot (the orchestrator: that reading is right)',
      'second pass of the spec (the orchestrator): barra2 and barra3 at u -1.55 and 1.55; barra_e at u 1.0 and the candles at u -.35, -.05, .25; the box at barra_fin on the left wing\'s near end with the frog beside it at barra_caja; cola1 to cola4 at u -.65 and .65; the roof is higher (ROOF 3.25)',
    
      'the tray the frog carries in the game of 66 is drawn on his head, like the thing of 67 (the orchestrator: as drawn)',
      'the vendedor stand-in wears a paper hat 4 rows above the plain grown-up\'s top, so his head check (the top 14 rows) covers the hat',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the roof, its edge and the chains, the counter and the wings, the posts, the table, the trees hide whoever is behind them.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador\'s and El cruce\'s sheets: the upright plane through the feet',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28, perro: .3 },
      byCharacter: { coqui: .45, vendedor: .35, maestra: .35, doctor: .35, cocinero: .35, policia: .35, senor: .35, senora: .35, hombre: .35, mujer: .35, joven: .35, la_joven: .35, mama_ana: .35, abuela: .35, luis: .28, carmen: .28, beto: .28, ana: .28, nino: .28, nina: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0). The spec gives no radius: these are El mostrador\'s and El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: Object.entries(spots).filter(([, s]) => s.uv[2] > 0).map(([k]) => k),
      onSeat: 'whoever sits on a stool or a chair, stands on the table, the counter or a wing (z above 0) casts none: the seat is not ground (a shadow cast at the pavement under it would show in front of it)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the surfaces: for each spot above the ground, a 5 x 5 grid of points (+-.18 in u and v) on the plane z of the spot: the baked depth and the part drawn at each (the engine's project(), the expected depth of the point)
  const surf = await page.evaluate(arg => {
    const o = {};
    for (const [k, uvz] of Object.entries(arg)) {
      const rows = [];
      for (const du of [-.18, -.09, 0, .09, .18]) for (const dv of [-.18, -.09, 0, .09, .18]) {
        const u = uvz[0] + du, v = uvz[1] + dv, q = project((u + v) / Math.SQRT2, (v - u) / Math.SQRT2, uvz[2]), X = Math.floor(q.sx), Y = Math.floor(q.sy);
        if (X < 0 || X >= W || Y < 0 || Y >= H) { rows.push({ du, dv, out: 1 }); continue; }
        rows.push({ du, dv, tag: TAGS[Y * W + X] || 'ground', dz: DEPTH.z[Y * W + X] - q.d });
      }
      o[k] = rows;
    }
    return o;
  }, Object.fromEntries(Object.entries(sheet.spots).filter(([, s]) => s.uv[2] > 0).map(([k, s]) => [k, s.uv])));
  // the feet pixel of the ground spots: the part and depth the set draws there (information)
  const feet = await page.evaluate(arg => { const o = {}; for (const [k, s] of Object.entries(arg)) { const X = s.screen[0], Y = s.screen[1] - 1; if (X < 0 || X >= W || Y < 0 || Y >= H) continue; const i = Y * W + X; o[k] = { tag: TAGS[i] || 'ground', z: DEPTH.z[i] }; } return o; }, Object.fromEntries(Object.entries(sheet.spots).filter(([, s]) => s.uv[2] === 0).map(([k, s]) => [k, { screen: s.screen }])));
  // the parts' pixels: the bounding box and the list, by part
  const parts = await page.evaluate(() => { const o = {}; for (let i = 0; i < TAGS.length; i++) { const t = TAGS[i]; if (!t) continue; (o[t] = o[t] || []).push([i % W, (i / W) | 0]); } return o; });
  // the cup sign: its disc (a screen mask) is the board: cream inside (its face, the cup's red), the roof's tiles outside it
  const sign = await page.evaluate(arg => {
    const d = ctx.getImageData(0, 0, W, H).data, disc = [], inside = [], outside = [], cream = (r, g, b) => Math.abs(r - 252) < 24 && Math.abs(g - 244) < 24 && Math.abs(b - 222) < 30;
    for (let Y = 0; Y < H; Y++) for (let X = 0; X < W; X++) {
      const r = Math.hypot(X + .5 - arg.cx, Y + .5 - arg.cy), i = (Y * W + X) * 4;
      if (r <= arg.r) disc.push([X, Y]);
      if (r <= 8) inside.push(cream(d[i], d[i + 1], d[i + 2])); else if (r >= 11.3 && r <= 12.8) outside.push(cream(d[i], d[i + 1], d[i + 2]));
    }
    return { disc, inside: inside.length, insideCream: inside.filter(Boolean).length, outside: outside.length, outsideCream: outside.filter(Boolean).length };
  }, { cx: sheet.things.letrero.disc.cx, cy: sheet.things.letrero.disc.cy, r: SIGN.r });
  return { surf, feet, parts, sign };
}

async function checks(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, BOX = PV.boxes, OUTS = [], x0 = V.x0;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const hw = who => WIDTH[who] / 2;
  const inWin = X => X >= x0 && X <= x0 + 195;

  // 0. spec-projection: the spec's arithmetic (sx = OX + 26 u, sy = OY + 13 v - 22.5 z) against the engine's own projection of every spot; PZ.xy against the make's
  {
    const bad = [];
    for (const [k, s] of Object.entries(S)) {
      const sx = G.OX + s.uv[0] * 26, sy = G.OY + s.uv[1] * 13 - s.uv[2] * 22.5;
      if (Math.abs(sx - s.screen[0]) > .51 || Math.abs(sy - s.screen[1]) > .51 + s.uv[2] * .02) bad.push(k + ': the spec\'s formula gives ' + r2(sx) + ', ' + r2(sy) + ', the engine ' + s.screen);
    }
    const [px, py] = [(.7 - 1.3) / R2, (-1.3 - .7) / R2];
    if (Math.abs(G.pzxy[0] - px) > 1e-9 || Math.abs(G.pzxy[1] - py) > 1e-9) bad.push('PZ.xy(.7, -1.3) is ' + G.pzxy + ', the make\'s is ' + [px, py]);
    add('spec-projection', bad, 'OX ' + G.OX + ', OY ' + G.OY + ' read from the set; every spot\'s screen point is the spec\'s sx = OX + 26 u, sy = OY + 13 v - 22.5 z within half a pixel (the engine\'s cos 30 * 26 is 22.52), and PZ.xy is the make\'s', ['the spec\'s arithmetic and the engine disagree:'].concat(bad));
  }

  // 1. views-x0: the one window holds every spot (a person's sprite whole; a small thing: its stand-in's box; entrada is outside on purpose)
  {
    const out = V.holds.map(k => [k, cutAt(S[k], V.x0)]).filter(o => o[1]);
    const bad = out.map(o => o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + V.x0);
    const ent = S.entrada.screen[0];
    const o = add('views-x0', bad, 'wide: x0 ' + V.x0 + ' (window columns ' + V.x0 + ' to ' + (V.x0 + 195) + '); the ' + V.holds.length + ' spots span columns ' + V.extent[0] + ' to ' + V.extent[1] + ' (' + (V.extent[1] - V.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (V.holdsAll ? V.holdsAll[0] + ' to ' + V.holdsAll[1] : 'none') + '; entrada is at column ' + ent + ' (the picture ends at ' + G.W + '): outside on purpose', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: V.x0 };
  }

  // 2. spots-in-view: every spot inside the picture and the window, its sprite whole (a sprite's box: the frog 32 wide, a grown-up 24, a child 24; rows from the drawn silhouette)
  {
    const bad = [], info = [], rows = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen;
      if (s.kind === 'entry') { info.push(k + ' ' + s.screen + ' is ' + (sx - (G.W - 1)) + ' px right of the picture\'s last column, outside on purpose (where people come in: the sprite walks in from the picture\'s edge)'); continue; }
      const sil = s.sprite && BOX[s.sprite] ? BOX[s.sprite].box : null, h = s.who ? hw(s.who) : (s.standinBox ? s.standinBox.w / 2 : 0);
      const pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H, wOut = sx < x0 || sx > x0 + 195;
      const cutL = h ? Math.max(0, x0 - Math.floor(sx - h)) : 0, cutR = h ? Math.max(0, Math.ceil(sx + h - 1) - (x0 + 195)) : 0;
      const top = sil ? sy + sil[1] : sy, bottom = sil ? sy + sil[3] : sy, cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      rows.push(k);
      if (pOut) bad.push(k + ' ' + s.screen + ' is outside the ' + G.W + ' x ' + G.H + ' picture');
      else if (wOut) bad.push(k + ' ' + s.screen + ' is ' + (sx < x0 ? x0 - sx + ' px left of' : sx - (x0 + 195) + ' px right of') + ' the window [' + x0 + ', ' + (x0 + 196) + ')');
      else if (cut.length) bad.push(k + ' ' + s.screen + ': its ' + (s.who || 'stand-in') + ' sprite is cut ' + cut.join(', ') + ' px by the window [' + x0 + ', ' + (x0 + 196) + ') or the picture');
    }
    const hints = [];
    for (const b of bad) {
      const k = b.split(' ')[0], s = S[k], h = s.who ? hw(s.who) : (s.standinBox ? s.standinBox.w / 2 : 0);
      const ok = sx => Math.floor(sx - h) >= x0 && Math.ceil(sx + h - 1) <= x0 + 195 && sx - h >= 0 && sx + h - 1 <= G.W - 1;
      let found = null;
      for (let n = 1; n <= 400 && !found; n++) for (const sg of [-1, 1]) { const u = r4(s.uv[0] + sg * n * .01), sx = scrUV(G, u, s.uv[1], s.uv[2])[0]; if (ok(sx)) { found = 'u ' + s.uv[0] + ' -> ' + u + ' (' + sgn(sg * n * .01) + ', column ' + sx + ')'; break; } }
      hints.push('    nearest passing, ' + k + ': ' + (found || 'none within 4 in u'));
    }
    const o = add('spots-in-view', bad, rows.length + ' spots (points and sprites; entrada apart) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '), their sprites whole', [bad.length + ' spot(s) outside, or with a sprite cut:'].concat(bad.map(b => '  ' + b), hints));
    for (const l of info) o.lines.push('       info, not a check: ' + l);
    o.cut = bad;
  }

  // 3. moments-in-view: every sprite of every moment (people and small things) whole inside the picture and the window: no drawn pixel outside
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      let n = 0;
      for (const l of PV.inspect[m].layers) {
        const xs = l.px.map(p => p[0]), cutL = Math.max(0, x0 - Math.min(...xs)), cutR = Math.max(0, Math.max(...xs) - (x0 + 195));
        n++;
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + (l.id || l.s) + ' at ' + l.at + ': ' + [cutL && 'cut ' + cutL + ' px at the window\'s left', cutR && 'cut ' + cutR + ' px at its right', l.out && l.out + ' px outside the picture'].filter(Boolean).join(', '));
      }
      lines.push('m' + m + ' ' + n + ' sprites');
    }
    add('moments-in-view', bad, 'every sprite of the six moments (' + lines.join(', ') + ') is whole inside the picture and the window [' + x0 + ', ' + (x0 + 196) + ')', [bad.length + ' sprite(s) cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 4. spots-on-surface: whoever sits or stands above the ground is on a surface the set draws: a 5 x 5 grid (+-.18) on the plane z round the spot meets the set's depth (within .1, as El cruce's: 2 dz in depth for a spot z off) drawn by part quiosco or mesa
  //    a point nearer than that (the table in front of a chair's seat, a post in front of a wing's top) is a part drawn in front of it, and is counted apart
  {
    const bad = [], lines = [], above = Object.entries(S).filter(([, s]) => s.uv[2] > 0), behind = [], TOL = .1;
    for (const [k, s] of above) {
      const rows = probes.surf[k], part = r => !r.out && (r.tag === 'quiosco' || r.tag === 'mesa'), match = rows.filter(r => part(r) && Math.abs(r.dz) < TOL).length, near = rows.filter(r => part(r) && r.dz >= TOL).length, far = rows.length - match - near, centre = rows[12];
      lines.push(k + ' z ' + s.uv[2] + ' (' + s.on + '): ' + match + ' of ' + rows.length + ' grid points on the surface' + (near ? ', ' + near + ' behind a nearer part' : '') + (far ? ', ' + far + ' off it' : '') + '; its own pixel: ' + (centre.out ? 'outside' : centre.tag + ' ' + sgn(centre.dz)));
      if (match < 3) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' (' + s.on + ') is not on a surface the set draws: ' + match + ' of ' + rows.length + ' grid points meet the set\'s depth');
    }
    for (const [k, s] of Object.entries(S)) if (s.uv[2] === 0 && s.kind !== 'entry') { const f = probes.feet[k]; if (f) { const d = f.z - s.depth; if (d > .08) behind.push(k + ' ' + s.screen + ' (' + f.tag + ' ' + r2(d) + ' nearer)'); } }
    const o = add('spots-on-surface', bad, above.length + ' spots above the ground (' + above.map(([k]) => k).join(', ') + ') are on a surface the set draws: the stools\' seat z ' + SEAT_Z.taburete + ', the chairs\' ' + SEAT_Z.silla + ', the table\'s ' + SEAT_Z.mesa + ', the counter\'s and the wings\' ' + G.E.CH, ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
    o.lines.push('       info, not a check: ground spots whose feet pixel the set draws nearer than the feet (the person stands behind it: the depth rule hides what it covers): ' + (behind.join(', ') || 'none'));
  }

  // 5. things-in-set: the set's own boxes hold every pixel the set drew by part (quiosco: the booth, the counter, the stools; mesa: the table and chairs)
  {
    const bad = [], lines = [], inBox = (b, X, Y) => X >= b[0] - 1 && X < b[0] + b[2] + 1 && Y >= b[1] - 1 && Y < b[1] + b[3] + 1;
    for (const [part, boxes] of [['quiosco', [T.quiosco.box, T.letrero.box, T.barra.box, T.taburetes.box, ...T.taburetes.each]], ['mesa', [T.mesa.box]]]) {
      const px = probes.parts[part] || [], out = px.filter(([X, Y]) => !boxes.some(b => inBox(b, X, Y)));
      const xs = px.map(p => p[0]), ys = px.map(p => p[1]);
      lines.push('part ' + part + ': ' + px.length + ' px, columns ' + Math.min(...xs) + ' to ' + Math.max(...xs) + ', rows ' + Math.min(...ys) + ' to ' + Math.max(...ys) + '; ' + out.length + ' outside the box(es) (1 px slack)');
      if (out.length) bad.push('part ' + part + ': ' + out.length + ' px outside the boxes of ' + (part === 'quiosco' ? 'quiosco, letrero, barra and taburetes' : 'mesa') + ', e.g. ' + out.slice(0, 4).map(p => p.join(',')).join(' '));
    }
    // each box inside the picture, and the window
    for (const k of ['quiosco', 'letrero', 'barra', 'taburetes', 'mesa']) { const b = T[k].box; if (b[0] < 0 || b[1] < 0 || b[0] + b[2] > G.W || b[1] + b[3] > G.H) bad.push(k + ' box [' + b + '] leaves the picture'); if (b[0] < x0 || b[0] + b[2] > x0 + 196) bad.push(k + ' box [' + b + '] leaves the window [' + x0 + ', ' + (x0 + 196) + ')'); }
    const o = add('things-in-set', bad, 'the boxes of the set\'s things (quiosco [' + T.quiosco.box + '], letrero [' + T.letrero.box + '], barra [' + T.barra.box + '], taburetes [' + T.taburetes.box + '], mesa [' + T.mesa.box + ']) hold every pixel the set drew by part and lie inside the picture and the window', ['set things\' boxes:'].concat(bad.map(b => '  ' + b)));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 6. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down. No pair is exempt
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, ai: a.id, bi: b.id, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.id + ' at ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.id + ' at ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {                                                            // the least shift of a spot in u, in v or in z that passes
      const s = S[name], res = [];
      for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 6 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.ai + ' ~ ' + q.bi + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 6 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.ai + ' ~ ' + q.bi + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.ai + '@' + q.a, b: q.bi + '@' + q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // the least shift (u, v or z, steps of .01) of the layer that covers a victim, which frees the victim (the victim and the shifted layer are layers of a moment, by id)
  const freeing = async (m, coverer, victim) => {
    const M = PV.moment[m], ci = M.layers.findIndex(l => l.id === coverer || l.at === coverer);
    if (ci < 0) return '';
    const r = await PV.nearest(M.set, M.layers, ci, 0, 0, [victim], true), at = M.layers[ci].at, uv = S[at].uv;
    return coverer + ' at ' + at + ' ' + uv + ': ' + ['u', 'v', 'z'].map((a, i) => r.axis[a] ? a + ' ' + uv[i] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  };
  // the coverage of one layer by the others: per drawn pixel hidden by the set (p[2]), or under a nearer shown sprite pixel (not the layers attached to him: held)
  const coverage = (L, ti, keep = () => true, skip = l => l.held === L[ti].id || l.held === 'velas') => {
    const best = new Map();
    L.forEach((l, i) => { if (i === ti || skip(l)) return; for (const p of l.px) if (!p[2]) { const k = p[1] * G.W + p[0], b = best.get(k); if (!b || b.plane < p[3]) best.set(k, { plane: p[3], id: l.id || l.at }); } });
    const t = L[ti], px = t.px.filter(keep); let hid = 0, cov = 0; const by = {};
    for (const p of px) { if (p[2]) { hid++; continue; } const b = best.get(p[1] * G.W + p[0]); if (b && b.plane > p[3] + EPS) { cov++; by[b.id] = (by[b.id] || 0) + 1; } }
    return { total: px.length, hid, cov, by, best };
  };
  const byTxt = by => Object.entries(by).map(([k, v]) => k + ' ' + v).join(', ');

  // 7. frog-seen: the frog is never behind a grown-up or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer person or thing: the tray and the thing he carries are his own)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverage(L, fi);
      let boxCov = 0;                                                                            // his 32 x 25 box: the pixels where a nearer sprite is (drawn or not by him)
      for (let y = f.sy - 25; y < f.sy; y++) for (let x = f.sx - 16; x < f.sx + 16; x++) { if (x < 0 || x >= G.W || y < 0 || y >= G.H) continue; const b = c.best.get(y * G.W + x); if (b && b.plane > f.d + (f.sy - (y + .5)) * Math.tan(Math.PI / 6) / G.S + EPS) boxCov++; }
      const cT = coverage(L, fi, () => true, l => l.held === 'coqui'), trayPx = cT.cov - c.cov;
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + (trayPx ? ' (the tray stand-in of the candles, not a spec thing, would add ' + trayPx + ' px)' : '') + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer person or thing' + (c.cov ? ' (' + byTxt(c.by) + ')' : '') + ', ' + f.out + ' outside the picture; his 32 x 25 box: ' + boxCov + ' px with a nearer sprite on them');
      const hp = f.px.filter(p => p[2]), post = scrUV(G, G.E.WING.uR + .1, .1, 0)[0];
      const where = hp.length ? ' [the set hides columns ' + Math.min(...hp.map(p => p[0])) + ' to ' + Math.max(...hp.map(p => p[0])) + ', rows ' + Math.min(...hp.map(p => p[1])) + ' to ' + Math.max(...hp.map(p => p[1])) + ': the front post of the right wing stands at column ' + post + ' (u ' + r2(G.E.WING.uR + .1) + ', v .1: quiosco-set.html, stand())]' : '';
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.by).join(', ') || 'a person') + ', ' + f.out + ' outside the picture)' + where); fails.push([m, fi]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 6 moments: ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi] of fails) {
      const cv = coverage(PV.inspect[m].layers, fi);
      for (const id of Object.keys(cv.by)) { const t = await freeing(m, id, 'coqui'); if (t) o.lines.push('       or, moment ' + m + ', the one that covers him moves: ' + t); }
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi, 0, 0, m === 6 ? ['vela_a', 'vela_b', 'vela_c'] : []);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[specs[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. frog-bar: the frog at barra_c (moment 1), barra_caja (3, 4) and barra_e (5, 6) is covered by nobody (the pixels reported: by the set, by each person or thing)
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi];
      if (f.at !== 'barra_c' && f.at !== 'barra_e' && f.at !== 'barra_caja') continue;
      const c = coverage(L, fi);
      lines.push('m' + m + ' ' + f.at + ': ' + (c.hid + c.cov) + ' of his ' + c.total + ' px covered (' + c.hid + ' by the set, ' + c.cov + ' by people or things' + (c.cov ? ': ' + byTxt(c.by) : '') + ')');
      if (c.hid + c.cov) bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ' is covered at ' + (c.hid + c.cov) + ' of his ' + c.total + ' px (' + c.hid + ' by the set, ' + c.cov + ' by ' + (byTxt(c.by) || 'sprites') + ')');
    }
    const o = add('frog-bar', bad, 'the frog at barra_c, barra_caja and barra_e is covered by nobody: ' + lines.join('; '), [bad.length + ' moment(s) with the frog covered:'].concat(bad.map(b => '  ' + b)));
    for (const m of MOMENTS) { const M = PV.moment[m], fi = M.layers.findIndex(l => l.who === 'coqui'); if (!bad.some(b => b.startsWith('moment ' + m + ':'))) continue; for (const id of Object.keys(coverage(PV.inspect[m].layers, fi).by)) { const t = await freeing(m, id, 'coqui'); if (t) o.lines.push('       or, moment ' + m + ', the one that covers him moves: ' + t); } const r = await PV.nearest(M.set, M.layers, fi, 0, 0, m === 6 ? ['vela_a', 'vela_b', 'vela_c'] : []); o.lines.push('       nearest passing, moment ' + m + ' ' + M.layers[fi].at + ' ' + S[M.layers[fi].at].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + (S[M.layers[fi].at].uv[['u', 'v', 'z'].indexOf(a)]) + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
  }

  // 9. frog-stool: the frog at barra1 to barra4 does not overlap the box of the one on the stool beside him (the box: its width, 32 and 24, round the spot's column; its rows from the drawn sprite: the frog 25 rows above his feet, a grown-up sitting from the lap row up and down)
  {
    const bad = [], lines = [], hints = [], frogB = BOX.coqui.box, sitB = BOX['doctor.S'].box, childB = BOX['ana.S'].box;
    const overlap = (fx, fy, sx, sy, sb) => { const ox = Math.min(fx + 15, sx + 11) - Math.max(fx - 16, sx - 12) + 1, oy = Math.min(fy + frogB[3], sy + sb[3]) - Math.max(fy + frogB[1], sy + sb[1]) + 1; return ox > 0 && oy > 0 ? [ox, oy] : null; };
    const inkOver = (fx, fy, sx, sy, sb) => { const ox = Math.min(fx + frogB[2], sx + sb[2]) - Math.max(fx + frogB[0], sx + sb[0]) + 1, oy = Math.min(fy + frogB[3], sy + sb[3]) - Math.max(fy + frogB[1], sy + sb[1]) + 1; return ox > 0 && oy > 0 ? [ox, oy] : null; };
    for (let k = 1; k <= 4; k++) {
      const f = S['barra' + k], t = S['taburete' + k], io = inkOver(f.screen[0], f.screen[1], t.screen[0], t.screen[1], sitB), o = overlap(f.screen[0], f.screen[1], t.screen[0], t.screen[1], sitB), oc = overlap(f.screen[0], f.screen[1], t.screen[0], t.screen[1], childB), dx = Math.abs(f.screen[0] - t.screen[0]);
      lines.push('barra' + k + ' [' + f.screen + '] ~ taburete' + k + ' [' + t.screen + ']: ' + dx + ' px sideways (the boxes need 28)' + (o ? ', boxes overlap ' + o[0] + ' x ' + o[1] + ' px' + (io ? ' (the drawn pixels\' boxes ' + io[0] + ' x ' + io[1] + ')' : ' (the drawn pixels\' boxes do not)') : ', apart'));
      if (o) {
        bad.push('barra' + k + ' ' + f.screen + ' (the frog\'s 32 x 25 box) overlaps the box of the one on taburete' + k + ' ' + t.screen + ' (24 wide, sitting): ' + dx + ' px sideways, the boxes need 28; they overlap ' + o[0] + ' px across and ' + o[1] + ' px down (' + oc[0] + ' x ' + oc[1] + ' for a child)');
        const ok = (sx, sy) => !overlap(sx, sy, t.screen[0], t.screen[1], sitB), res = [];
        for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let r = null; for (const sg of [-1, 1]) { const q = f.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { r = lab + ' ' + f.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (r) { res.push(r); break; } }
        const ok2 = (sx, sy) => !overlap(f.screen[0], f.screen[1], sx, sy, sitB), res2 = [];
        for (const [ax, lab] of [[0, 'u'], [1, 'v'], [2, 'z']]) for (let n = 1; n <= 400; n++) { let r = null; for (const sg of [-1, 1]) { const q = t.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); if (q[2] < 0) continue; const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok2(sx, sy)) { r = lab + ' ' + t.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (r) { res2.push(r); break; } }
        hints.push('    nearest passing, barra' + k + ' ' + f.uv + ': ' + (res.join(' or ') || 'none within 3') + '; or taburete' + k + ' ' + t.uv + ': ' + (res2.join(' or ') || 'none within 3'));
      }
    }
    const o = add('frog-stool', bad, 'the frog at barra1 to barra4 is clear of the box of the one on the stool beside him: ' + lines.join('; '), [bad.length + ' of the 4 frog places overlap the stool\'s sitter:'].concat(bad.map(b => '  ' + b), hints));
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 10. stools-whole: the people on the stools in the moments are whole in the window (every drawn pixel inside the picture and [x0, x0 + 196))
  {
    const bad = [], lines = [];
    for (const m of MOMENTS) for (const l of PV.inspect[m].layers) {
      if (!/^taburete/.test(l.at || '')) continue;
      const xs = l.px.map(p => p[0]), a = Math.min(...xs), b = Math.max(...xs), ys = l.px.map(p => p[1]), cut = Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
      lines.push('m' + m + ' ' + l.id + ' at ' + l.at + ': columns ' + a + ' to ' + b + ', rows ' + Math.min(...ys) + ' to ' + Math.max(...ys));
      if (cut || l.out) bad.push('moment ' + m + ' ' + l.id + ' at ' + l.at + ': cut ' + cut + ' px by the window, ' + l.out + ' outside the picture');
    }
    const o = add('stools-whole', bad, lines.length + ' people on the stools, all whole in the window [' + x0 + ', ' + (x0 + 196) + ')', [bad.length + ' sitter(s) cut:'].concat(bad.map(b => '  ' + b)));
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 11. vendedor-head: in every moment the vendedor's head (the top 14 rows of his sprite) is covered by nothing: not the roof's edge, not the chains, not a person or a thing (the pixels reported)
  {
    const bad = [], lines = [], fixes = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, vi = L.findIndex(l => l.id === 'vendedor'), v = L[vi], top = Math.min(...v.px.map(p => p[1]));
      const c = coverage(L, vi, p => p[1] < top + HEAD_ROWS, () => false);
      // skip nothing but himself; the share of the chains: the same head with the set's fiesta off
      let flags = 0, set0 = c.hid;
      if (PV.inspect[m].set.fiesta) { const L0 = await PV.layers({ hora: PV.inspect[m].set.hora, fiesta: 0 }, PV.moment[m].layers), c0 = coverage(L0, L0.findIndex(l => l.id === 'vendedor'), p => p[1] < top + HEAD_ROWS); set0 = c0.hid; flags = c.hid - c0.hid; }
      lines.push('m' + m + ' vendedor at detras ' + [v.sx, v.sy] + ': head rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ': ' + (c.hid + c.cov) + ' of ' + c.total + ' px covered (' + c.hid + ' by the set' + (PV.inspect[m].set.fiesta ? ': ' + set0 + ' the roof, ' + flags + ' the chains' : '') + ', ' + c.cov + ' by people or things' + (c.cov ? ': ' + byTxt(c.by) : '') + ')');
      if (c.hid + c.cov) { bad.push('moment ' + m + ': the vendedor\'s head at detras ' + [v.sx, v.sy] + ' (rows ' + top + ' to ' + (top + HEAD_ROWS - 1) + ') is covered at ' + (c.hid + c.cov) + ' of ' + c.total + ' px: ' + c.hid + ' by the set' + (PV.inspect[m].set.fiesta ? ' (' + set0 + ' by the roof, ' + flags + ' by the chains)' : ' (the roof\'s edge)') + ', ' + c.cov + ' by ' + (byTxt(c.by) || 'nobody')); fixes.push(m); }
    }
    const o = add('vendedor-head', bad, 'the vendedor\'s head is covered by nothing in all 6 moments: ' + lines.join('; '), [bad.length + ' moment(s) with his head covered:'].concat(bad.map(b => '  ' + b)));
    for (const m of fixes) {
      const M = PV.moment[m], vi = M.layers.findIndex(l => l.id === 'vendedor'), r = await PV.nearest(M.set, M.layers, vi, 0, HEAD_ROWS);
      o.lines.push('       nearest passing, moment ' + m + ' detras ' + S.detras.uv + ' (head only): ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S.detras.uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ')));
    }
    o.lines.push('       info, not a check: ' + lines.join('; '));
    o.lines.push('       info, not a check: the stand-in wears a white paper hat 4 rows above the plain 53-row grown-up\'s top (57 rows in all), and the head is its top 14 rows: the hat and the top of the hair');
  }

  // 12. candles-clear: in moment 6 no candle is covered (not by the set, not by a person or the frog)
  {
    const bad = [], lines = [], m = 6, L = PV.inspect[m].layers;
    for (const id of ['vela_a', 'vela_b', 'vela_c']) {
      const ci = L.findIndex(l => l.id === id), c = coverage(L, ci, () => true, () => false);
      lines.push(id + ' at ' + L[ci].at + ' ' + [L[ci].sx, L[ci].sy] + ': ' + (c.hid + c.cov) + ' of ' + c.total + ' px covered (' + c.hid + ' by the set, ' + c.cov + ' by ' + (byTxt(c.by) || 'nobody') + ')');
      if (c.hid + c.cov) bad.push('moment 6: ' + id + ' at ' + L[ci].at + ' ' + [L[ci].sx, L[ci].sy] + ' is covered at ' + (c.hid + c.cov) + ' of ' + c.total + ' px (' + c.hid + ' by the set, ' + c.cov + ' by ' + (byTxt(c.by) || 'sprites') + ')');
    }
    const o = add('candles-clear', bad, 'in moment 6 no candle is covered: ' + lines.join('; '), [bad.length + ' candle(s) covered in moment 6:'].concat(bad.map(b => '  ' + b)));
    for (const id of ['vela_a', 'vela_b', 'vela_c']) { if (!bad.some(b => b.includes(id))) continue; const ci0 = L.findIndex(l => l.id === id); for (const cid of Object.keys(coverage(L, ci0, () => true, () => false).by)) { const t = await freeing(m, cid, id); if (t) o.lines.push('       or the one that covers ' + id + ' moves: ' + t); } const M = PV.moment[m], ci = M.layers.findIndex(l => l.id === id), r = await PV.nearest(M.set, M.layers, ci); o.lines.push('       nearest passing, ' + id + ' ' + S[id].uv + ': ' + (['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[id].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; '))); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 13. sign-clear: nobody covers the cup sign: in no moment does a sprite pixel that is shown lie on the sign's disc
  {
    const bad = [], lines = [], sg = probes.sign, disc = new Set(sg.disc.map(p => p[1] * G.W + p[0]));
    const found = sg.insideCream >= .3 * sg.inside && sg.outsideCream <= .1 * sg.outside;
    if (!found) bad.push('the sign\'s disc is not where the make looks for it: ' + sg.insideCream + ' of ' + sg.inside + ' px inside it are the board\'s cream, ' + sg.outsideCream + ' of ' + sg.outside + ' px just outside it (centre ' + T.letrero.disc.cx + ', ' + T.letrero.disc.cy + ', radius ' + SIGN.r + ')');
    for (const m of MOMENTS) {
      const by = {}; let n = 0;
      for (const l of PV.inspect[m].layers) { let k = 0; for (const p of l.px) if (!p[2] && disc.has(p[1] * G.W + p[0])) k++; if (k) { by[l.id || l.at] = k; n += k; } }
      lines.push('m' + m + ': ' + n + ' px' + (n ? ' (' + byTxt(by) + ')' : ''));
      if (n) bad.push('moment ' + m + ': ' + n + ' px of sprites lie on the cup sign (' + byTxt(by) + ')');
    }
    add('sign-clear', bad, 'nobody covers the cup sign (its disc: ' + sg.disc.length + ' px, centre ' + T.letrero.disc.cx + ', ' + T.letrero.disc.cy + ', radius ' + SIGN.r + '; found in the picture: ' + sg.insideCream + ' of ' + sg.inside + ' px inside it are the board\'s cream, ' + sg.outsideCream + ' of ' + sg.outside + ' just outside): ' + lines.join('; '), [bad.length + ' problem(s) with the cup sign:'].concat(bad.map(b => '  ' + b)));
  }

  // 14. things-seen (information, not a check: the spec asks nothing of them): how much of each small thing of a moment is seen (the dome, the cake stand, the box, the limbers, the candles)
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, ids = [...new Set(L.filter(l => !l.who && ['quesitos', 'torre', 'caja', 'limbers', 'vela_a', 'vela_b', 'vela_c'].includes(l.id)).map(l => l.id))];
      for (const id of ids) {
        let tot = 0, hid = 0, cov = 0; const by = {};
        L.forEach((l, i) => { if (l.id !== id) return; const c = coverage(L, i, () => true, o => o.id === id); tot += c.total; hid += c.hid; cov += c.cov; for (const [k, v] of Object.entries(c.by)) by[k] = (by[k] || 0) + v; });
        lines.push('m' + m + ' ' + id + ': ' + (tot - hid - cov) + ' of ' + tot + ' px seen' + (hid + cov ? ' (' + hid + ' hidden by the set, ' + cov + ' under ' + byTxt(by) + ')' : ''));
      }
    }
    OUTS.push({ name: 'things-seen', ok: true, lines: ['things-seen: not a check (the spec asks nothing of the small things but the candles): ' + lines.join('; ')] });
  }

  // the stand-ins, the facing, the open points
  OUTS.push({ name: 'info-standins', ok: true, lines: ['info-standins: not a check. Stand-ins for the people with no sprite maker (size only): ' + Object.entries(STANDINS_PEOPLE).map(([k, v]) => k + ' = ' + v).join('; ') + '. Sitting people are the front view of the sitting drawing: the sheet gives their facing (taburete1, 2 right; 3, 4 left; the chairs front) but the stand-in does not turn. Things: the dome 20 x 18, the cake stand 20 x 28 inked, the box 16 x 12, the limbers three 6 x 7 cups, the candles 8 x 12, the thing over the frog 12 x 12, the frog\'s tray 22 x 10 on his head (the spec gives the candles\' and the thing\'s sizes only)'] });
  return OUTS;
}
