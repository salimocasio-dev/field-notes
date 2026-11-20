#!/usr/bin/env node
'use strict';
/* Las frutas' sheet: writes docs/proyecto/pixel/frutas-sheet.json from frutas-set.html and the design (the orchestrator's frutas-spec), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/frutas-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is the street front and the stand of colmado-fuera.js (window.FRUTAS.CF).
   It loads the set in headless Chrome, projects every world point with the engine's own project() (pp-engine.js), reads the pixels the set drew
   for each part (tags=1), and writes the spots, things, view, shadows and the depth rule. The sprites' silhouettes (don Pepe, abuela, the frog) come from
   today's makers (historia/engine.js, historia/escenas/kit.js) loaded in a second, empty page: the checks that say "covers" read real pixels.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with FRUTAS_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'frutas-sheet.json');
const BASE = process.env.FRUTAS_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/frutas-set.html';
const BLANK = BASE + '/__blank__.html';
const CHROME = '/usr/bin/google-chrome';
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png' };

const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

// the numbers of the design
const PERSON = { rows: 53, minAbove: 24 };               // don Pepe behind the stand: of his 53 drawn rows at least 24 above the stand's back board at his column
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_FROG = 30;                                     // px between two of the frog's places on the ledge
const MIN_GOAT = 14;                                     // px between abuela.junto_cabra and cabra.poste
const CART_GAP = 10;                                     // px between the hand cart and abuela.delante
const GOAT = { w: 30, h: 24, ax: 15 };                   // the goat's sprite box (about 30 x 24, its middle column on the spot, its bottom edge on the spot's row)
// the sizes of the small things on the ledge, for the check "the frog's places are clear of them". The coin and the crate are the spec's (coins .2 apart;
// each crate .7 wide); the rest are the stand-ins' of frutas-preview.html (not final art): a coin 7 x 7 px, a crate .7 x .3 x .34 and the basket .9 x .3 x .3 (world x, y, z)
// the frog's place in each story that puts something on the ledge (v3 brief: 43 and 44 at repisa.izq; story 42's place is not in the brief: repisa.izq too, see the report)
const FROG_STORY = [[42, 'repisa.izq'], [43, 'repisa.izq'], [44, 'repisa.izq']];
const FOOT = { moneda: [7, 7], moneda_paso: .2, cajon: [.7, .3, .34], canasta: [.9, .3, .3] };

// the design's states of the set: surtido x carro x puerta in the morning, and the afternoon in two of them
const STATES = [];
for (const surtido of ['verduras', 'frutas']) for (const carro of [0, 1]) for (const puerta of ['open', 'shut']) STATES.push({ hora: 'manana', puerta, carro, surtido });
STATES.push({ hora: 'tarde', puerta: 'open', carro: 0, surtido: 'verduras' }, { hora: 'tarde', puerta: 'shut', carro: 1, surtido: 'frutas' });
const qOf = s => 'hora=' + s.hora + '&puerta=' + s.puerta + '&carro=' + s.carro + '&surtido=' + s.surtido;
const keyOf = s => s.surtido + ' carro ' + s.carro + ' puerta ' + s.puerta + ' ' + s.hora;

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const errs = [];
  const route = async route => {
    const u = new URL(route.request().url());
    if (u.pathname === '/__blank__.html') return route.fulfill({ status: 200, contentType: 'text/html', body: '<!doctype html><html><head><meta charset="utf-8"><title>blank</title></head><body></body></html>' });
    const f = path.join(REPO, decodeURIComponent(u.pathname));
    if (!f.startsWith(REPO + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return route.fulfill({ status: 404, body: 'not found' });
    route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
  };
  const page = await browser.newPage();
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', route);
  const load = async (q) => { await page.goto(PAGE + '?' + q); };
  // a second page with today's sprite makers: the silhouettes of don Pepe, abuela and the frog
  const sp = await browser.newPage();
  sp.on('pageerror', e => errs.push(String(e)));
  await sp.route(BASE + '/**', route);
  const SIL = await silhouettes(sp);

  await load('tags=1&' + qOf(STATES[0]));
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(FRUTAS.CF)) if (typeof v !== 'function') o[k] = v;
    return { CF: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);
  // the set's drawn pixels, by part, in every state; and what each sprite would cover or show
  const base = await partsOf(page);                                           // the base state's part boxes: guineos, pesa, ...
  const bins = {};                                                            // each assortment's bins (the engine's own binBox)
  for (const surtido of ['verduras', 'frutas']) {
    await load('tags=1&hora=manana&puerta=open&carro=0&surtido=' + surtido);
    bins[surtido] = await page.evaluate(() => FRUTAS.CF.BINS.map(k => [k, FRUTAS.CF.binBox(k), FRUTAS.CF.binX(k)]));
  }
  await load('tags=1&' + qOf(STATES[0]));
  const ext = await extents(page, load, STATES, G);                           // the pixels that the window must hold
  const carro = await stepCarro(page, load, SIL);                             // pepe.carro: x stepped down from 1.9 by .1 until he does not cover the cart's handle
  const sheet = await make(G, proj, base, bins, ext, carro);
  const probes = await probeSets(page, sheet, load, SIL);
  const results = checks(sheet, probes, SIL, G);
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

/* ---------- the sprites' silhouettes: [dx, dy] of each drawn pixel from the anchor column and the bottom edge (dy -1 is the feet's row) ---------- */
async function silhouettes(sp) {
  await sp.goto(BLANK);
  for (const f of ['historia/engine.js', 'historia/escenas/kit.js']) await sp.addScriptTag({ url: BASE + '/' + f });
  return sp.evaluate(() => {
    const sil = (cv, ax) => {
      const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, ink = [];
      let bottom = 0;
      for (let y = 0; y < cv.height; y++) for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { ink.push([x, y]); bottom = Math.max(bottom, y + 1); }
      const px = []; let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const [x, y] of ink) { px.push(x - ax, y - bottom); x0 = Math.min(x0, x - ax); x1 = Math.max(x1, x - ax); y0 = Math.min(y0, y - bottom); y1 = Math.max(y1, y - bottom); }
      return { w: cv.width, h: cv.height, ax, bottom, box: [x0, y0, x1, y1], px };
    };
    const PIEL = KIT.PIEL, PELO = KIT.PELO;
    // don Pepe as mostrador-preview.html dresses him (the apron changes no pixel of his outline, but it is the same call)
    const PEPE = { piel: PIEL.c, pelo: PELO.negro, peinado: 'corto', ropa: ['#C8C8D0', '#E4E4EA', '#F6F6FA', '#FFFFFF'], abajo: RP.grey, bigote: 1,
      detalle: (b, X) => { const G = RP.grn; b.rect(X - 4, 18, 1, 4, G[1]); b.rect(X + 3, 18, 1, 4, G[1]); b.rect(X - 5, 22, 10, 24, G[2]); b.rect(X - 5, 45, 10, 1, G[0]); } };
    const SENORA = { piel: PIEL.a, pelo: PELO.castano, peinado: 'corto', ropa: RP.grn, falda: 1, zapato: '#F2F2F8' };
    return { pepe: sil(KIT.mkPersona(PEPE, 'idle', 0, 0), KIT.PX), abuela: sil(mkAbuela('idle', 0), 30), coqui: sil(mkCoqui(1, 0, 0), 16), senora: sil(KIT.mkPersona(SENORA, 'idle', 0, 0), KIT.PX) };
  });
}

/* ---------- pepe.carro: the brief (v3b) gives (2.35, 3.35, 0) so that he is whole inside the window; if he then covers more than CARRO_MAX pixels of the cart's handle, (1.9, 3.35, 0) is kept.
   He covers the handle where a pixel he draws (not hidden by the depth rule) lies on a pixel of the handle (carro = 1, the morning, the door open, verduras) ---------- */
const CARRO_TRY = 2.35, CARRO_KEEP = 1.9, CARRO_Y = 3.35, CARRO_MAX = 10;
async function stepCarro(page, load, SIL) {
  await load('tags=1&' + qOf({ hora: 'manana', puerta: 'open', carro: 1, surtido: 'verduras' }));
  const r = await page.evaluate(arg => {
    const { px, xs, y, bias } = arg, CF = FRUTAS.CF, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2, T30 = Math.tan(Math.PI / 6), Z = DEPTH.z;
    const edge = CF.CART[0] - .95 - .05;
    const isHandle = i => {
      if (TAGS[i] !== 'carro') return false;
      const X = i % W, Y = (i / W) | 0, b = (X + .5 - OX) / S, syp = (Y + .5 - OY) / S, z = (Z[i] - 2 * COS * syp) / 2, a = 2 * (syp + z * COS);
      return (a + b) * R2 / 2 < edge;
    };
    let handle = 0; for (let i = 0; i < TAGS.length; i++) if (isHandle(i)) handle++;
    return { handle, tries: xs.map(x => {
      const q = project(x, y, 0), sx = Math.round(q.sx), sy = Math.round(q.sy);
      let cov = 0, left = 0;
      for (let n = 0; n < px.length; n += 2) {
        const X = sx + px[n], Y = sy + px[n + 1]; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, plane = q.d + (sy - (Y + .5)) * T30 / S;
        if (Z[i] > plane + bias) continue;
        if (isHandle(i)) cov++;
      }
      return { x, covered: cov, handle, screen: [sx, sy] };
    }) };
  }, { px: SIL.pepe.px, xs: [CARRO_TRY, CARRO_KEEP], y: CARRO_Y, bias: BIAS });
  return { x: r.tries[0].covered > CARRO_MAX ? CARRO_KEEP : CARRO_TRY, tries: r.tries };
}

/* ---------- what the set drew, by part (tags=1): the pixel box of each ---------- */
async function partsOf(page) {
  return page.evaluate(() => {
    const parts = {};
    for (let i = 0; i < TAGS.length; i++) {
      const t = TAGS[i]; if (!t) continue;
      const x = i % W, y = (i / W) | 0, p = parts[t] || (parts[t] = [1e9, 1e9, -1, -1, 0]);
      if (x < p[0]) p[0] = x; if (y < p[1]) p[1] = y; if (x > p[2]) p[2] = x; if (y > p[3]) p[3] = y; p[4]++;
    }
    // the scale without its pole, its arm and the chain up to it: the dial (a disc of radius 7 px) and the pan with the chains between,
    // the pixels not right of the dial's right edge and not above its top
    const D = FRUTAS.CF.PESA_DIAL, dp = project(D.x, D.y, D.z), right = Math.floor(dp.sx) + 7, top = Math.floor(dp.sy) - 7;
    let b = [1e9, 1e9, -1, -1];
    for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'pesa') { const x = i % W, y = (i / W) | 0; if (x <= right && y >= top) { if (x < b[0]) b[0] = x; if (y < b[1]) b[1] = y; if (x > b[2]) b[2] = x; if (y > b[3]) b[3] = y; } }
    parts.pesa_dial_pan = b;
    return parts;
  });
}

// the pixels the window must hold: the door, the scale, the whole stand, the low crate, the post, and (carro = 1) the hand cart
async function extents(page, load, STATES, G) {
  const E = {};
  const add = (name, b) => { E[name] = b; };
  for (const s of [STATES[0], STATES[2]]) {                                 // carro 0, then carro 1 (verduras, door open)
    await load('tags=1&' + qOf(s));
    const parts = await partsOf(page);
    const names = s.carro ? ['carro'] : ['puerta', 'pesa', 'puesto', 'cajon', 'poste'];
    for (const n of names) add(n, parts[n].slice(0, 4));
    if (!s.carro) for (const [n, p] of Object.entries(parts)) if (['tomates', 'cebollas', 'papas', 'platanos'].includes(n)) add(n, p.slice(0, 4));
  }
  await load('tags=1&' + qOf(Object.assign({}, STATES[0], { surtido: 'frutas' })));
  for (const [n, p] of Object.entries(await partsOf(page))) if (['aguacates', 'pinas', 'limones'].includes(n)) add(n, p.slice(0, 4));
  return E;
}

/* ---------- the sheet ---------- */
async function make(G, proj, base, bins, ext, carro) {
  const CF = G.CF, carroX = carro.x;
  const P1 = async p => (await proj([p]))[0];
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const ym = (CF.TY1 + CF.LY1) / 2;                                                    // the middle of the ledge's depth
  const L0 = CF.TX0 - .05, L1 = CF.TX1 + .05;                                          // the ledge's length: the block the stand draws along its front
  const lx = q => L0 + (L1 - L0) * q;
  const [cx0, cy0, cx1, cy1, ch] = CF.CRATE, cmx = (cx0 + cx1) / 2, cmy = (cy0 + cy1) / 2;

  /* ---- spots: the pavement (or the ledge, or the crate's top) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, what, extra]
  const add = (name, w, kind, what, extra) => D.push([name, w, kind, what, extra]);
  add('pepe.detras', [6.3, .5, 0], 'person', 'don Pepe behind the stand, between it and the wall (the stand hides him up to his waist)');
  add('pepe.puerta', [1.65, .35, 0], 'person', 'don Pepe at the shop door');
  add('pepe.carro', [carroX, 3.35, 0], 'person', 'don Pepe at the hand cart\'s handles: (2.35, 3.35, 0) so that he is whole inside the window, or (1.9, 3.35, 0) if at 2.35 he covers more than ' + CARRO_MAX + ' pixels of the cart\'s handle; `stepped` lists what each covered');
  add('pepe.pesa', [1.9, 2.7, 0], 'person', 'don Pepe beside the scale');
  add('abuela.delante', [7.4, 4.0, 0], 'person', 'abuela in front of the stand');
  add('abuela.junto_cabra', [8.7, 3.0, 0], 'person', 'abuela beside the low crate');
  add('repisa.izq', [4.6, ym, CF.LZ], 'frog', 'the frog on the ledge, left place (x 4.6, in the middle of the ledge\'s depth, z CF.LZ); the frog of stories 42, 43 and 44 (v3: two places on the ledge, not three)');
  add('repisa.der', [7.7, ym, CF.LZ], 'frog', 'the frog on the ledge, right place (x 7.7, in the middle of the ledge\'s depth, z CF.LZ)');
  add('cabra.poste', [9.9, 2.35, 0], 'goat', 'the goat by its post, standing');
  add('cabra.cajon', [cmx, cmy, ch], 'head', 'where the goat\'s head is when it eats from the low crate: the crate\'s top middle (the goat\'s feet stay on cabra.poste)');
  add('senora.puerta', [1.65, .25, 0], 'person', 'la señora leaning out of the shop door');
  add('monedas4', [5.6, ym, CF.LZ], 'ledge', 'abuela\'s four coins in a row on the ledge, .2 apart (story 42); the first coin here, the row runs towards +x', { dir: [1, 0, 0], row: { n: 4, step: FOOT.moneda_paso } });
  add('monedas2', [6.7, ym, CF.LZ], 'ledge', 'her two other coins, .2 apart, under the guineos (story 42)', { dir: [1, 0, 0], row: { n: 2, step: FOOT.moneda_paso } });
  add('canasta', [7.5, ym, CF.LZ], 'ledge', 'abuela\'s basket on the ledge, lined with a cloth with three hollows (story 43)');
  add('cajon_a', [5.9, ym, CF.LZ], 'ledge', 'the first crate of story 44, .7 wide', { width: .7 });
  add('cajon_b', [6.7, ym, CF.LZ], 'ledge', 'the second crate of story 44, .7 wide', { width: .7 });
  add('bolsa', [CF.TX1 - .5, ym, CF.LZ], 'ledge', 'a paper bag on the ledge');
  add('bajo', [cmx, cmy, ch], 'point', 'where a thing lands on the low crate: its top middle');
  add('vuelo', [7.2, 2.7, 1.6], 'point', 'the top of the arc of a tossed thing, between the ledge and abuela\'s basket');
  add('plato', [CF.PESA_PLATO.x, CF.PESA_PLATO.y, CF.PESA_PLATO.z], 'part', 'the scale\'s pan: what is weighed lies on it (CF.PESA_PLATO, the centre of the pan\'s top)');
  add('aguja', [CF.PESA_DIAL.x, CF.PESA_DIAL.y, CF.PESA_DIAL.z], 'part', 'the scale\'s dial: the needle is drawn here, pointing to 12 (rest), 3 (medio) or 6 o\'clock (libra) (CF.PESA_DIAL; the dial faces the camera)');
  const pr = await proj(D.map(d => d[1]));
  const spots = {}, depth = {};
  // the scale is drawn straight into the picture's pixels, a disc turned to the camera, at the dial's depth + .3 (colmado-fuera.js dial(), pan()): nearer than
  // the world point of the pan or the dial. A sprite on them (the needle, what is weighed) needs that depth, not the world point's, or the pan hides it
  const dialQ = await P1([CF.PESA_DIAL.x, CF.PESA_DIAL.y, CF.PESA_DIAL.z]), drawnDepth = r4(dialQ[2] + .3);
  D.forEach((d, i) => {
    const q = pr[i], s = { world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2], what: d[3] };
    if (d[0] === 'plato' || d[0] === 'aguja') s.drawn_depth = drawnDepth;
    if (d[4]) Object.assign(s, d[4]);
    spots[d[0]] = s; depth[d[0]] = q[2];
  });
  spots['pepe.carro'].stepped = { try: CARRO_TRY, keep: CARRO_KEEP, maxHandlePx: CARRO_MAX, handle: 'the pixels of part carro whose world x (read back from the baked depth) is left of the bed\'s left end CF.CART x - .95 by more than .05: the two rails and the cross-grip', tries: carro.tries.map(t => ({ x: t.x, coveredPx: t.covered, handlePx: t.handle })), chosen: carro.x };
  // abuela's list is a card of the game's own
  spots['lista'] = { drawn: false, kind: 'card', what: 'abuela\'s list is a card of the game\'s own, not in the picture' };
  // the hanging hand of guineos: its place is read from what the set drew (part 'guineos', tags=1)
  const gb = base.guineos; if (!gb) throw new Error('the set drew no part named guineos');
  const gbox = [gb[0], gb[1], gb[2] - gb[0] + 1, gb[3] - gb[1] + 1];
  spots['guineos'] = { screen: [gbox[0] + Math.floor(gbox[2] / 2), gbox[1] + Math.floor(gbox[3] / 2)], box: gbox, kind: 'part', what: 'the hand of guineos hanging from the awning: the middle of the screen box of the pixels the set draws for part guineos (tags=1); no world point: the part is drawn pixel by pixel' };
  const names0 = D.map(d => d[0]), ip = names0.indexOf('plato');
  const spotsOrdered = Object.fromEntries([...names0.slice(0, ip), 'lista', ...names0.slice(ip), 'guineos'].map(k => [k, spots[k]]));

  /* ---- things he can touch ---- */
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  const T = async (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: await boxOf(world), what }, extra);
  const things = {};
  const WHAT = { tomates: 'tomatoes', cebollas: 'onions', papas: 'potatoes', platanos: 'plantains', aguacates: 'avocados', pinas: 'pineapples', limones: 'limes' };
  for (const surtido of ['verduras', 'frutas']) for (const [k, bb] of bins[surtido]) things[k] = await T(bb, 'the bin of ' + WHAT[k] + ' (assortment ' + surtido + '): the bin\'s space from the table\'s low edge to .3 above its back (CF.binBox)', { surtido });
  const pb = base.pesa_dial_pan;
  things.pesa = { set: true, box: [pb[0], pb[1], pb[2] - pb[0] + 1, pb[3] - pb[1] + 1], what: 'the scale, the dial and the pan together (the pole and the arm left out): the screen box of the pixels the set draws for part pesa (tags=1) from the dial\'s top row down and no further right than its right edge' };
  things.guineos = { set: true, box: gbox, what: 'the hand of guineos, a poke: the screen box of the pixels the set draws for part guineos (tags=1)' };
  things.cajon = await T([cx0, cy0, 0, cx1, cy1, ch], 'the low crate, a poke');
  things.puerta = await T([CF.D0, 0, 0, CF.D1, .02, CF.DH], 'the shop door, a poke (the doorway, in either state of the door)');
  for (const k of ['fruta_a', 'fruta_b', 'cajon_a', 'cajon_b', 'canasta', 'cabra', 'pepe', 'abuela', 'senora', 'coqui']) things[k] = 'sprite';

  /* ---- the view: one, wide ---- */
  const names = Object.keys(ext), xmin = Math.min(...names.map(n => ext[n][0])), xmax = Math.max(...names.map(n => ext[n][2]));
  const goat = scr(pr[D.findIndex(d => d[0] === 'cabra.poste')]);
  const gx0 = goat[0] - GOAT.ax, gx1 = goat[0] - GOAT.ax + GOAT.w - 1;                // the goat's sprite box at its post
  const lo = Math.min(xmin, gx0), hi = Math.max(xmax, gx1), mid = (lo + hi + 1) / 2;
  const ux = ym + ((mid - G.OX) / G.S) * Math.SQRT2;                                   // the ground point at the ledge's depth whose projection is that column
  const vq = await P1([ux, ym, 0]), vs = [r2(vq[0]), r2(vq[1])];
  const x0 = Math.max(0, Math.min(G.W - 196, Math.round(vs[0] - 98)));
  const views = { wide: { world: W4([ux, ym, 0]), screen: vs, zoom: 1, x0, region: [x0, 0, 196, 216], extent: [lo, hi],
    what: 'the one view: the 196 x 216 window over the 240 x 216 picture. Its point is the ground point (at the ledge\'s depth) under the middle column of what the window must hold: the shop door, the scale, the whole stand, the low crate, the post and the goat at it, and the hand cart when carro = 1 (their pixels span columns ' + lo + ' to ' + hi + '); x0 = clamp(round(sx - 98), 0, 44), as the sheet\'s other views' } };

  const sc = G.scene;
  return {
    scene: 'frutas',
    made: 'node docs/proyecto/pixel/frutas-sheet-make.js, from frutas-set.html (window.FRUTAS.CF, colmado-fuera.js) and the design of Las frutas. A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels. The front wall of the shop is y = 0 (it faces +y); the pavement runs from it to y = ' + CF.PAVE,
      spot: 'a spot is a world point of the feet (z 0: the pavement; z ' + CF.LZ + ': the ledge\'s top; z ' + ch + ': the low crate\'s top) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy); the goat (a new sprite, about ' + GOAT.w + ' x ' + GOAT.h + ' px): its middle column on sx, its bottom edge on sy; in the pose with its neck stretched down its head is at cabra.cajon (the goat\'s feet stay on cabra.poste); a small thing: its bottom middle on the point; things of a row (monedas4, monedas2): the first one\'s bottom middle on the point, the next ones on the points .2 on along dir',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      person: 'for the check "shows enough above the stand\'s back board": don Pepe is ' + PERSON.rows + ' rows tall (mkPersona standing), at least ' + PERSON.minAbove + ' of them above the board\'s top edge at his column',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character. Except plato and aguja, which have drawn_depth too: the set draws the scale (dial, pan, chains) at the dial\'s depth + .3, nearer than their world points, so a sprite on them (the needle, what lies on the pan) must use drawn_depth in front.plane or the scale\'s own pixels hide it',
      footprints: 'what the check "frog-places" takes the small things on the ledge to cover (their stand-ins in frutas-preview.html; the final art may differ): a coin ' + FOOT.moneda.join(' x ') + ' px; a crate ' + FOOT.cajon.join(' x ') + ' (world x, y, z: .7 wide as the design says, a ledge\'s depth less a hair, as high as the low crate); the basket ' + FOOT.canasta.join(' x ') + '; each box is the screen box of the thing\'s projected corners standing on the ledge\'s top at its point, the frog\'s is his drawn box (30 x 24)',
    },
    setKey: {
      params: {
        hora: { values: ['manana', 'tarde'] }, puerta: { values: ['shut', 'open'], note: 'the shop door; the set\'s default is open' }, carro: { values: [0, 1], note: 'don Pepe\'s hand cart on the pavement, left of the scale (story 44)' },
        surtido: { values: ['verduras', 'frutas'], note: 'what the stand\'s bins hold: four bins of verduras (tomates, cebollas, papas, platanos) or three of frutas (aguacates, pinas, limones)' },
        aguja: { values: ['', '0', 'medio', 'libra'], note: 'a red needle on the scale\'s dial for the readers\' renders only; in the game the needle is a sprite and the baked sets have none' },
      },
      key: 'hora + puerta + carro + surtido, e.g. "manana-open-0-verduras"',
      baked: ['manana', 'tarde'].flatMap(h => ['shut', 'open'].flatMap(p => [0, 1].flatMap(c => ['verduras', 'frutas'].map(s => '?hora=' + h + '&puerta=' + p + '&carro=' + c + '&surtido=' + s)))),
    },
    surtidos: CF.SURTIDOS,
    things,
    spots: spotsOrdered,
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so the stand hides don Pepe behind it up to his waist, the bins and the ledge hide nothing that stands in front of them, and the goat is drawn in front of its post (the post is a hair nearer than the goat\'s feet, less than the .3).',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The same rule as El mostrador\'s sheet: the upright plane through the feet; the same test for people, the goat and the things on the ledge',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
    },
    shadows: {
      radius: { adultos: .35, cabra: .4 },
      byCharacter: { pepe: .35, abuela: .35, senora: .35, cabra: .4 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the pavement (z 0)',
      none: ['repisa.izq', 'repisa.der'],
      onLedge: 'the frog on the ledge casts none: the ledge is not ground (a shadow cast at the pavement under him would show in front of the stand)',
    },
  };
}

/* ---------- the checks that read the set's pixels: every state of the set ---------- */
async function probeSets(page, sheet, load, SIL) {
  const S = sheet.spots, R = [];
  const at = (name, sil) => { const s = S[name]; return { name, sil, sx: s.screen[0], sy: s.screen[1], d: s.depth }; };
  const place = [at('pepe.detras', 'pepe'), at('pepe.puerta', 'pepe'), at('pepe.carro', 'pepe'), at('pepe.pesa', 'pepe'), at('abuela.delante', 'abuela'), at('abuela.junto_cabra', 'abuela'), at('senora.puerta', 'senora')];
  const sil = {}; for (const [k, v] of Object.entries(SIL)) sil[k] = { px: v.px, box: v.box };
  // the goat: a box (a simple sprite, about 30 x 24)
  const gpx = []; for (let y = -GOAT.h; y < 0; y++) for (let x = -GOAT.ax; x < GOAT.w - GOAT.ax; x++) gpx.push(x, y);
  sil.cabra = { px: gpx, box: [-GOAT.ax, -GOAT.h, GOAT.w - GOAT.ax - 1, -1] };
  const goat = at('cabra.poste', 'cabra');
  for (const st of STATES) {
    await load('tags=1&' + qOf(st));
    const r = await page.evaluate(arg => {
      const { sil, place, goat, bias, rows, pb } = arg, CF = FRUTAS.CF;
      const Z = DEPTH.z, S_ = DEPTH.S, T30 = Math.tan(Math.PI / 6);
      const boardRow = X => project(CF.TY0 + (X + .5 - OX) / S_ * R2, CF.TY0, CF.TZ1 + .16).sy;      // the back board's top edge at pixel column X
      const ledgeRow = X => project(CF.LY1 + (X + .5 - OX) / S_ * R2, CF.LY1, CF.LZ).sy;             // the ledge's front edge (top) at column X
      const tagOf = i => TAGS[i] || 'ground';
      const parts = {};
      for (let i = 0; i < TAGS.length; i++) { const t = TAGS[i]; if (!t) continue; const x = i % W, y = (i / W) | 0, p = parts[t] || (parts[t] = [1e9, 1e9, -1, -1, 0]); if (x < p[0]) p[0] = x; if (y < p[1]) p[1] = y; if (x > p[2]) p[2] = x; if (y > p[3]) p[3] = y; p[4]++; }
      const binNames = CF.BINS.slice();
      let scaleTotal = 0; for (let y = pb[1]; y < pb[1] + pb[3]; y++) for (let x = pb[0]; x < pb[0] + pb[2]; x++) if (TAGS[y * W + x] === 'pesa') scaleTotal++;
      const people = {};
      for (const pl of place) {
        const s = sil[pl.sil];
        const o = { total: 0, vis: 0, outside: 0, hidBy: {}, over: {}, overRows: {}, below: 0, belowOver: {}, minY: 1e9, maxY: -1e9, x0: 1e9, x1: -1e9, onScale: 0 };
        for (let k = 0; k < s.px.length; k += 2) {
          const X = pl.sx + s.px[k], Y = pl.sy + s.px[k + 1];
          if (X < 0 || X >= W || Y < 0 || Y >= H) { o.outside++; continue; }
          o.total++; o.minY = Math.min(o.minY, Y); o.maxY = Math.max(o.maxY, Y); o.x0 = Math.min(o.x0, X); o.x1 = Math.max(o.x1, X);
          const i = Y * W + X, plane = pl.d + (pl.sy - (Y + .5)) * T30 / S_;
          if (Z[i] > plane + bias) { const t = tagOf(i); o.hidBy[t] = (o.hidBy[t] || 0) + 1; continue; }
          o.vis++;
          const t = tagOf(i); o.over[t] = (o.over[t] || 0) + 1;
          if (t === 'pesa' && X >= pb[0] && X < pb[0] + pb[2] && Y >= pb[1] && Y < pb[1] + pb[3]) o.onScale++;
          const rr = o.overRows[t] || (o.overRows[t] = [1e9, -1e9]); rr[0] = Math.min(rr[0], Y); rr[1] = Math.max(rr[1], Y);
          if (Y + .5 > boardRow(X)) { o.below++; o.belowOver[t] = (o.belowOver[t] || 0) + 1; }          // visible and under the back board's top edge
        }
        // the column of his feet: the 53 nominal rows, hidden or not by the depth rule
        const hid = []; for (let k = 0; k < rows; k++) { const Y = pl.sy - rows + k, plane = pl.d + (pl.sy - (Y + .5)) * T30 / S_; hid.push(Z[Y * W + pl.sx] > plane + bias ? 1 : 0); }
        o.column = hid.join('');
        o.boardRow = boardRow(pl.sx); o.ledgeRow = ledgeRow(pl.sx);
        let drawn = -1; for (let y = 0; y < H; y++) if (TAGS[y * W + pl.sx] === 'puesto') { drawn = y; break; }
        o.drawnBoardRow = drawn;
        o.headTop = pl.sy + s.box[1];
        o.box = [pl.sx + s.box[0], pl.sy + s.box[1], pl.sx + s.box[2], pl.sy + s.box[3]];
        people[pl.name] = o;
      }
      // the goat in front of the post: the post's pixels under the goat's box that are nearer than the goat's plane + bias
      const g = { postPx: 0, hides: 0 };
      for (let k = 0; k < sil.cabra.px.length; k += 2) {
        const X = goat.sx + sil.cabra.px[k], Y = goat.sy + sil.cabra.px[k + 1];
        if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X;
        if (TAGS[i] !== 'poste') continue;
        g.postPx++;
        const plane = goat.d + (goat.sy - (Y + .5)) * T30 / S_;
        if (Z[i] > plane + bias) g.hides++;
      }
      // the cart and abuela.delante: the least gap between the cart's pixels and her drawn pixels (rows or columns left empty between them)
      let cart = null;
      if (CF && parts.carro) {
        const ab = place.find(p => p.name === 'abuela.delante'), s = sil[ab.sil], cp = [];
        for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'carro') cp.push(i % W, (i / W) | 0);
        let best = 1e9, bestE = 1e9;
        for (let a = 0; a < cp.length; a += 2) for (let k = 0; k < s.px.length; k += 2) {
          const dx = Math.abs(cp[a] - (ab.sx + s.px[k])), dy = Math.abs(cp[a + 1] - (ab.sy + s.px[k + 1]));
          best = Math.min(best, Math.max(dx, dy) - 1); bestE = Math.min(bestE, Math.hypot(dx, dy));
        }
        cart = { box: parts.carro.slice(0, 4), gapExact: best, euclid: bestE };
      }
      // the produce the stand shows, in pixels, per bin (for "by how much")
      const binPx = {}; for (const b of binNames) binPx[b] = parts[b] ? parts[b][4] : 0;
      // don Pepe at pepe.pesa over the scale: pixels of part pesa under his drawn pixels, shown or hidden
      return { parts, people, goat: g, cart, binPx, binNames, scaleTotal };
    }, { sil, place, goat, bias: BIAS, rows: PERSON.rows, pb: sheet.things.pesa.box });
    R.push({ st, key: keyOf(st), ...r });
  }
  return R;
}

function checks(sheet, probes, SIL, G) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, OUTS = [];
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const at = Object.entries(S).filter(([, s]) => s.screen);                           // the spots that have a point (lista is a card)
  const x0 = V.region[0], inWin = (x, y) => x >= x0 && x < x0 + 196 && y >= 0 && y < 216, inPic = (x, y) => x >= 0 && x < sheet.picture[0] && y >= 0 && y < sheet.picture[1];
  const base = probes[0], cart1 = probes.find(p => p.st.carro === 1 && p.st.surtido === 'verduras' && p.st.puerta === 'open' && p.st.hora === 'manana');
  const px = k => S[k].screen;

  // 1. every spot's screen point and every thing's screen box is inside the picture and inside the window, in both assortments and with carro = 1
  {
    const bad = [];
    for (const [k, s] of at) { if (!inPic(...s.screen)) bad.push(k + ' ' + s.screen + ' outside the picture'); else if (!inWin(...s.screen)) bad.push(k + ' ' + s.screen + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)'); }
    const boxes = Object.entries(T).filter(([, t]) => t.box);
    for (const [k, t] of boxes) if (t.box[0] < x0 || t.box[0] + t.box[2] > x0 + 196 || t.box[1] < 0 || t.box[1] + t.box[3] > 216) bad.push('thing ' + k + ' box ' + t.box + ' outside the window');
    // what the set draws in each state: the parts' pixel boxes (the bins of the assortment in use, the cart with carro = 1) and don Pepe's place at the cart
    const parts = ['puerta', 'pesa', 'puesto', 'cajon', 'poste'], seen = [];
    for (const p of probes) {
      const names = parts.concat(p.binNames, p.st.carro ? ['carro'] : []);
      for (const n of names) { const b = p.parts[n]; if (!b) { bad.push(n + ' is not drawn in ' + p.key); continue; } if (b[0] < x0 || b[2] >= x0 + 196 || b[1] < 0 || b[3] >= 216) bad.push(n + ' pixels [' + b.slice(0, 4) + '] outside the window in ' + p.key); }
    }
    const cb = cart1.parts.carro;
    seen.push('hand cart (carro = 1) pixels [' + cb.slice(0, 4) + ']', 'pepe.carro ' + px('pepe.carro'));
    const goatBox = [px('cabra.poste')[0] - GOAT.ax, px('cabra.poste')[0] - GOAT.ax + GOAT.w - 1];
    if (goatBox[0] < x0 || goatBox[1] >= x0 + 196) bad.push('the goat\'s box at cabra.poste, columns ' + goatBox + ', is outside the window');
    add('in-view', bad, at.length + ' spot points (every spot but lista) and ' + boxes.length + ' thing boxes inside the ' + sheet.picture.join(' x ') + ' picture and the wide window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216); in all ' + probes.length + ' states of the set (surtido verduras and frutas, carro 0 and 1, the door shut and open, both hours) the drawn pixels of the door, the scale, the stand, its bins, the low crate and the post, and with carro = 1 the cart, are inside it (' + seen.join(', ') + '); the goat\'s 30-px box at its post is inside', ['outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 2. don Pepe at pepe.detras: of his 53 rows at least 24 above the stand's back board at his column; he covers no bin's produce
  {
    const rows = PERSON.rows, min = PERSON.minAbove, bad = [];
    let worstAbove = 1e9, worstShown = 1e9, worstProduce = 0, lowest = -1e9, worstBelow = 0;
    const per = [];
    for (const p of probes) {
      const o = p.people['pepe.detras'], top = S['pepe.detras'].screen[1] - rows, edge = Math.floor(o.boardRow);
      const above = edge - top, drawnAbove = o.drawnBoardRow - top;
      let shown = 0, hiddenAbove = 0, lowVis = -1;
      for (let k = 0; k < rows; k++) { if (o.column[k] === '0') { lowVis = top + k; if (top + k < edge) shown++; } else if (top + k < edge) hiddenAbove++; }
      const produce = p.binNames.reduce((a, b) => a + (o.over[b] || 0), 0);
      worstAbove = Math.min(worstAbove, above); worstShown = Math.min(worstShown, shown); worstProduce = Math.max(worstProduce, produce); lowest = Math.max(lowest, lowVis); worstBelow = Math.max(worstBelow, o.below);
      per.push([p, above, drawnAbove, shown, hiddenAbove, lowVis, produce]);
      if (above < min || drawnAbove < min || shown < min || produce > 0 || lowVis >= o.drawnBoardRow) bad.push(p.key + ': ' + above + ' rows above the board (the set draws its top edge at row ' + o.drawnBoardRow + ', ' + drawnAbove + ' rows), ' + shown + ' of them shown (' + hiddenAbove + ' hidden by the depth rule), lowest shown row ' + lowVis + ' (the board\'s top edge is at row ' + o.drawnBoardRow + '), ' + produce + ' shown pixels over produce');
    }
    const o0 = base.people['pepe.detras'], top0 = S['pepe.detras'].screen[1] - rows, p0 = per[0];
    add('pepe-over-stand', bad, 'don Pepe at pepe.detras ' + px('pepe.detras') + ': of his ' + rows + ' rows (top row ' + top0 + ') ' + worstAbove + ' are above the stand\'s back board at his column (the board\'s top edge is at row ' + r2(o0.boardRow) + ', the set draws it at row ' + o0.drawnBoardRow + ') and ' + worstShown + ' of those are shown by the depth rule (needs ' + min + '; the awning hides ' + p0[4] + ' rows of his head in ' + base.key + '); his lowest shown row is ' + lowest + ', above the board; none of his shown pixels is over produce (worst of ' + probes.length + ' states, both assortments)',
      ['don Pepe at pepe.detras:'].concat(bad.map(b => '  ' + b)));
    const oc = base.people['pepe.detras'], of = probes.find(p => p.st.surtido === 'frutas').people['pepe.detras'];
    const hid = o => Object.entries(o.hidBy).map(([t, n]) => n + ' by ' + t).join(', ');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: of his ' + oc.total + ' drawn pixels ' + oc.vis + ' show with the verduras bins (hidden: ' + hid(oc) + '), ' + of.vis + ' with the frutas bins (hidden: ' + hid(of) + ')');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: ' + worstBelow + ' of his shown pixels lie under the board\'s top edge (his left hand, over ' + Object.entries(oc.belowOver).map(([t, n]) => n + ' of part ' + t).join(', ') + '): the .3 of the depth rule lets a hand at the board\'s top edge show over it');
    OUTS[OUTS.length - 1].pepe = { above: worstAbove, shown: worstShown };
  }

  // 3. abuela at abuela.delante covers no bin: her head's top is below the ledge's front edge row at her column, or she stands clear to the side
  {
    const bad = [], lines = [];
    const sp = S['abuela.delante'];
    let anyCover = false;
    for (const surtido of ['verduras', 'frutas']) {
      const p = probes.find(q => q.st.surtido === surtido && q.st.carro === 0 && q.st.puerta === 'open' && q.st.hora === 'manana'), o = p.people['abuela.delante'];
      const below = o.headTop > Math.floor(o.ledgeRow);
      const cov = p.binNames.map(b => [b, o.over[b] || 0, p.binPx[b], o.overRows[b]]).filter(c => c[1] > 0);
      const covered = cov.reduce((a, c) => a + c[1], 0);
      if (covered) anyCover = true;
      const rowsCovered = [];                                                    // the rows of her silhouette that lie over a bin
      lines.push(surtido + ': her head\'s top is at row ' + o.headTop + ', the ledge\'s front edge at her column ' + sp.screen[0] + ' is at row ' + r2(o.ledgeRow) + ' (' + (below ? 'below' : (o.ledgeRow - o.headTop >= 0 ? r2(o.ledgeRow - o.headTop) + ' rows above' : 'level')) + '); her drawn box columns ' + o.box[0] + ' to ' + o.box[2] + ', rows ' + o.box[1] + ' to ' + o.box[3] + '; she covers ' + (cov.length ? cov.map(c => c[0] + ' ' + c[1] + ' of its ' + c[2] + ' px (' + Math.round(100 * c[1] / c[2]) + '%, rows ' + c[3][0] + ' to ' + c[3][1] + ')').join(', ') : 'no bin') + '; she also shows over: ' + Object.entries(o.over).filter(([t]) => !p.binNames.includes(t)).map(([t, n]) => t + ' ' + n).join(', '));
      if (!below && covered) bad.push(surtido + ': head top row ' + o.headTop + ' is above the ledge\'s front edge row ' + r2(o.ledgeRow) + ' and she covers ' + covered + ' px of bins');
    }
    add('abuela-clear-of-bins', bad, 'abuela at abuela.delante ' + sp.screen + ' covers no bin in either assortment', [bad.length + ' assortment(s) with a bin covered by abuela at abuela.delante ' + sp.screen + ' (mkAbuela, 26 x 50 px drawn, her pixels over the bins\' pixels, not hidden by the depth rule):'].concat(lines.map(l => '  ' + l)));
    if (!bad.length) OUTS[OUTS.length - 1].lines.push(...lines.map(l => '       ' + l));
  }

  // 4. the frog's two places on the ledge: at least 30 px apart, and in each story the frog's place is clear of the small things on the ledge of that story
  //    (v3: 43 and 44 put the frog at repisa.izq, the brief says so; story 42's place is NOT in the brief: it is taken as repisa.izq too, an open point of the report)
  {
    const bad = [], lines = [];
    const pl = ['repisa.izq', 'repisa.der'];
    const d = (a, b) => Math.hypot(px(a)[0] - px(b)[0], px(a)[1] - px(b)[1]);
    const sep = [[pl[0], pl[1], d(pl[0], pl[1])]];
    for (const [a, b, v] of sep) if (v < MIN_FROG) bad.push(a + ' ' + px(a) + ' ~ ' + b + ' ' + px(b) + ': ' + r2(v) + ' px (needs ' + MIN_FROG + '; horizontally ' + Math.abs(px(a)[0] - px(b)[0]) + ')');
    // the boxes: [x0, y0, x1, y1] in pixels, inclusive
    const cb = SIL.coqui.box, frog = n => [px(n)[0] + cb[0], px(n)[1] + cb[1], px(n)[0] + cb[2], px(n)[1] + cb[3]];
    const wbox = (x, wdt, dep, h) => {                                           // a thing standing on the ledge's top, centred on (x, the ledge's middle): the screen box of its 8 corners
      const w = S['monedas4'].world, y = w[1], z = CF_LZ(S);
      const q = []; for (const xx of [x - wdt / 2, x + wdt / 2]) for (const yy of [y - dep / 2, y + dep / 2]) for (const zz of [z, z + h]) q.push(project3(G, xx, yy, zz));
      return [Math.floor(Math.min(...q.map(p => p[0]))), Math.floor(Math.min(...q.map(p => p[1]))), Math.ceil(Math.max(...q.map(p => p[0]))) - 1, Math.ceil(Math.max(...q.map(p => p[1]))) - 1];
    };
    const coin = (name, n, x0) => { const w = S[name].world, out = []; for (let i = 0; i < n; i++) { const q = project3(G, (x0 === undefined ? w[0] : x0) + i * FOOT.moneda_paso, w[1], w[2]), sx = Math.round(q[0]), sy = Math.round(q[1]); out.push([sx - (FOOT.moneda[0] >> 1), sy - FOOT.moneda[1], sx - (FOOT.moneda[0] >> 1) + FOOT.moneda[0] - 1, sy - 1]); } return [Math.min(...out.map(b => b[0])), Math.min(...out.map(b => b[1])), Math.max(...out.map(b => b[2])), Math.max(...out.map(b => b[3]))]; };
    const things = [['monedas4', 42, coin('monedas4', 4)], ['monedas2', 42, coin('monedas2', 2)],
      ['canasta', 43, wbox(S['canasta'].world[0], FOOT.canasta[0], FOOT.canasta[1], FOOT.canasta[2])],
      ['cajon_a', 44, wbox(S['cajon_a'].world[0], FOOT.cajon[0], FOOT.cajon[1], FOOT.cajon[2])], ['cajon_b', 44, wbox(S['cajon_b'].world[0], FOOT.cajon[0], FOOT.cajon[1], FOOT.cajon[2])]];
    const overlap = (a, b) => { const w = Math.min(a[2], b[2]) - Math.max(a[0], b[0]) + 1, h = Math.min(a[3], b[3]) - Math.max(a[1], b[1]) + 1; return w > 0 && h > 0 ? [w, h] : null; };
    const hits = [];
    for (const p of pl) for (const [t, story, box] of things) { const o = overlap(frog(p), box); if (o) hits.push([p, t, story, o]); }
    for (const [story, place] of FROG_STORY) {
      for (const [t, st, box] of things) if (st === story) {
        const o = overlap(frog(place), box);
        if (o) bad.push('story ' + story + ': ' + place + ' ' + px(place) + ' (frog box [' + frog(place) + ']) overlaps ' + t + ' (box [' + box + ']) by ' + o[0] + ' px across and ' + o[1] + ' down');
      }
    }
    // where a number of the brief makes a story fail: the nearest x (steps of .01) of the thing, and of the frog's place, that clears the overlap; the brief's own numbers are kept
    const nearestClear = (story, place, t) => {
      const wx = S[t].world[0], px0 = S[place].world[0], ym2 = S[place].world[1], lz = S[place].world[2];
      const thingBox = x => t.startsWith('moneda') ? coin(t, t === 'monedas4' ? 4 : 2, x) : wbox(x, t === 'canasta' ? FOOT.canasta[0] : FOOT.cajon[0], t === 'canasta' ? FOOT.canasta[1] : FOOT.cajon[1], t === 'canasta' ? FOOT.canasta[2] : FOOT.cajon[2]);
      const frogBox = x => { const q = project3(G, x, ym2, lz), sx = Math.round(q[0]), sy = Math.round(q[1]); return [sx + cb[0], sy + cb[1], sx + cb[2], sy + cb[3]]; };
      const find = (f) => { for (let k = 1; k <= 200; k++) for (const sg of [1, -1]) { const dx = sg * k * .01; if (f(dx)) return dx; } return null; };
      const dThing = find(dx => !overlap(frogBox(px0), thingBox(wx + dx))), dFrog = find(dx => !overlap(frogBox(px0 + dx), thingBox(wx)));
      const fmt = (v, base) => v === null ? 'none within 2.0' : r2(base + v) + ' (' + (v > 0 ? '+' : '') + r2(v) + ')';
      return 'nearest passing: ' + t + ' at x ' + fmt(dThing, wx) + ' (now ' + wx + '), or ' + place + ' at x ' + fmt(dFrog, px0) + ' (now ' + px0 + ')';
    };
    const hints = [];
    for (const [story, place] of FROG_STORY) for (const [t, st, box] of things) if (st === story && overlap(frog(place), box)) hints.push('    ' + nearestClear(story, place, t));
    // (v3b) the two crates of story 44: their boxes do not overlap each other (reported, not moved): its own check below
    const cA = things.find(t => t[0] === 'cajon_a')[2], cB = things.find(t => t[0] === 'cajon_b')[2], cOv = overlap(cA, cB);
    let cHint = '';
    if (cOv) {
      const wa = S['cajon_a'].world[0], wb = S['cajon_b'].world[0], bx = x => wbox(x, FOOT.cajon[0], FOOT.cajon[1], FOOT.cajon[2]);
      const find = f => { for (let k = 1; k <= 200; k++) for (const sg of [1, -1]) { const dx = sg * k * .01; if (f(dx)) return dx; } return null; };
      const dB = find(dx => !overlap(cA, bx(wb + dx))), dA = find(dx => !overlap(bx(wa + dx), cB));
      cHint = 'nearest passing: cajon_b at x ' + (dB === null ? 'none within 2.0' : r2(wb + dB) + ' (' + (dB > 0 ? '+' : '') + r2(dB) + ')') + ' (now ' + wb + '), or cajon_a at x ' + (dA === null ? 'none within 2.0' : r2(wa + dA) + ' (' + (dA > 0 ? '+' : '') + r2(dA) + ')') + ' (now ' + wa + ')';
    }
    const mline = FROG_STORY.map(([story, place]) => 'story ' + story + ' ' + place + ': ' + things.filter(t => t[1] === story).map(t => { const h = hits.find(x => x[0] === place && x[1] === t[0]); return t[0] + (h ? ' overlaps by ' + h[3][0] + ' px across, ' + h[3][1] + ' down' : ' clear'); }).join(', ')).join('; ');
    const other = pl.map(p => p + ' against every thing: ' + (things.map(t => { const h = hits.find(x => x[0] === p && x[1] === t[0]); return t[0] + (h ? ' overlaps ' + h[3][0] + ' x ' + h[3][1] : ' clear'); }).join(', '))).join('; ');
    add('frog-places', bad, 'the two places are ' + r2(sep[0][2]) + ' px apart (needs ' + MIN_FROG + ') and in each story the frog\'s box clears the small things on the ledge: ' + mline,
      [bad.length + ' finding(s) on the frog\'s two places on the ledge (places ' + pl.map(p => px(p)).join(' ') + '; ledge things\' sizes: rules.footprints):'].concat(bad.map(b => '  ' + b), hints));
    OUTS[OUTS.length - 1].lines.push('       info: the frog\'s boxes ' + pl.map(p => p + ' [' + frog(p) + ']').join(', ') + '; the things\' boxes ' + things.map(t => t[0] + ' [' + t[2] + ']').join(', '));
    OUTS[OUTS.length - 1].lines.push('       info: each place against every thing, whatever the story: ' + other);
    OUTS[OUTS.length - 1].frog = { sep: sep.map(([a, b, v]) => [a, b, r2(v)]), story: FROG_STORY, hits: hits.map(h => [h[0], h[1], h[2], h[3]]) };
    const wcA = S['cajon_a'].world[0], wcB = S['cajon_b'].world[0];
    add('cajones-apart', cOv ? [1] : [], 'story 44\'s two crates do not overlap each other: cajon_a (x ' + wcA + ') box [' + cA + '] and cajon_b (x ' + wcB + ') box [' + cB + ']', ['cajon_a (x ' + wcA + ') box [' + cA + '] and cajon_b (x ' + wcB + ') box [' + cB + '] overlap by ' + (cOv ? cOv[0] : 0) + ' px across and ' + (cOv ? cOv[1] : 0) + ' down (the brief\'s x are kept; a crate is .7 wide, so a stand-in ' + FOOT.cajon.join(' x ') + ')', '    ' + cHint]);
  }

  // 5. abuela.junto_cabra and cabra.poste at least 14 px apart; the goat's head at cabra.cajon reaches the crate's top
  {
    const bad = [], a = px('abuela.junto_cabra'), g = px('cabra.poste'), h = px('cabra.cajon'), dd = Math.hypot(a[0] - g[0], a[1] - g[1]);
    if (dd < MIN_GOAT) bad.push('abuela.junto_cabra ' + a + ' ~ cabra.poste ' + g + ': ' + r2(dd) + ' px (needs ' + MIN_GOAT + ')');
    // the head: cabra.cajon's point must lie in the goat's box over cabra.poste (30 x 24), above its feet, and be the crate's top
    const dx = h[0] - g[0], dy = h[1] - g[1], cm = T.cajon.world;
    const inBox = dx >= -GOAT.ax && dx <= GOAT.w - GOAT.ax - 1 && dy <= -1 && dy >= -GOAT.h;
    const crateTop = S['cabra.cajon'].world[2] === cm[5] && S['cabra.cajon'].world[0] > cm[0] && S['cabra.cajon'].world[0] < cm[3] && S['cabra.cajon'].world[1] > cm[1] && S['cabra.cajon'].world[1] < cm[4];
    if (!inBox) bad.push('cabra.cajon ' + h + ' is ' + dx + ', ' + dy + ' from the goat\'s feet: outside its ' + GOAT.w + ' x ' + GOAT.h + ' box (columns ' + -GOAT.ax + ' to ' + (GOAT.w - GOAT.ax - 1) + ', rows -' + GOAT.h + ' to -1)');
    if (!crateTop) bad.push('cabra.cajon ' + S['cabra.cajon'].world + ' is not on the low crate\'s top ' + cm);
    const gp = base.goat;
    add('goat-reach', bad, 'abuela.junto_cabra ' + a + ' and cabra.poste ' + g + ' are ' + r2(dd) + ' px apart (needs ' + MIN_GOAT + '); the goat\'s head at cabra.cajon ' + h + ' is ' + dx + ' across and ' + -dy + ' rows above its feet, inside its ' + GOAT.w + ' x ' + GOAT.h + ' box, on the low crate\'s top middle (z ' + cm[5] + '); its neck stretched down must put the head tip there',
      ['the goat:'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the goat drawn in front of the post: ' + gp.postPx + ' post pixels under its box, ' + gp.hides + ' of them nearer than its plane + ' + BIAS + ' (hide it)');
    const cs = T.cajon.world, ws = S['cabra.poste'].world, inFoot = ws[0] >= cs[0] && ws[0] <= cs[3] && ws[1] >= cs[1] && ws[1] <= cs[4];
    OUTS[OUTS.length - 1].lines.push('       info, not a check: cabra.poste ' + ws + ' is ' + (inFoot ? 'INSIDE' : 'outside') + ' the low crate\'s footprint (x ' + cs[0] + ' to ' + cs[3] + ', y ' + cs[1] + ' to ' + cs[4] + ')');
  }

  // 6. with carro = 1: pepe.carro inside the window and the cart clear of abuela.delante by 10 px
  {
    const bad = [], s = S['pepe.carro'], c = cart1.cart, ab = cart1.people['abuela.delante'].box;
    if (!inWin(...s.screen)) bad.push('pepe.carro ' + s.screen + ' is outside the window');
    const b = c.box, gx = Math.max(0, ab[0] - b[2] - 1, b[0] - ab[2] - 1), gy = Math.max(0, ab[1] - b[3] - 1, b[1] - ab[3] - 1), gap = Math.max(gx, gy);
    if (c.gapExact < CART_GAP) bad.push('the cart is ' + c.gapExact + ' px from abuela at abuela.delante (needs ' + CART_GAP + ')');
    const po = cart1.people['pepe.carro'];
    add('cart-clear', bad, 'carro = 1: pepe.carro ' + s.screen + ' is inside the window; the cart (pixels [' + b + ']) is ' + c.gapExact + ' px clear of abuela at abuela.delante (her pixels columns ' + ab[0] + ' to ' + ab[2] + ', rows ' + ab[1] + ' to ' + ab[3] + '; the boxes are ' + gap + ' px apart; needs ' + CART_GAP + ')',
      ['with carro = 1:'].concat(bad.map(x => '  ' + x)));
    const hs = sheet.spots['pepe.carro'].stepped, cut = Math.max(0, x0 - po.box[0]);
    OUTS[OUTS.length - 1].lines.push('       info, not a check: pepe.carro: tried x ' + hs.try + ' (kept only if he covers at most ' + hs.maxHandlePx + ' handle pixels, else ' + hs.keep + '): ' + hs.tries.map(t => 'x ' + t.x + ' covers ' + t.coveredPx + ' of the ' + t.handlePx + ' handle pixels').join('; ') + ' -> x ' + sheet.spots['pepe.carro'].world[0] + (hs.chosen === hs.keep ? ' (the fallback: he covers more than ' + hs.maxHandlePx + ' at ' + hs.try + ')' : ''));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: his drawn box at pepe.carro is columns ' + po.box[0] + ' to ' + po.box[2] + ', rows ' + po.box[1] + ' to ' + po.box[3] + ' and the window starts at column ' + x0 + ': ' + (cut ? cut + ' of his ' + (po.box[2] - po.box[0] + 1) + ' columns are left of the window' : 'all of him is inside the window'));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: don Pepe at pepe.carro: ' + po.vis + ' of his ' + po.total + ' drawn pixels show (' + Object.entries(po.hidBy).map(([t, n]) => n + ' hidden by ' + t).join(', ') + ')');
  }

  // info: how much of each person the set hides, per spot (not a check)
  {
    const lines = [];
    for (const p of [probes[0], cart1]) for (const [k, o] of Object.entries(p.people)) if (o.vis < o.total || o.outside) lines.push('       ' + k + ' ' + S[k].screen + ' in ' + p.key + ': ' + o.vis + ' of ' + o.total + ' drawn pixels show' + (o.outside ? ', ' + o.outside + ' fall outside the picture' : '') + (o.vis < o.total ? ' (' + Object.entries(o.hidBy).map(([t, n]) => n + ' hidden by ' + t).join(', ') + ')' : ''));
    const pesaK = 'pepe.pesa', pe = probes[0].people[pesaK], pe1 = cart1.people[pesaK];
    OUTS.push({ name: 'info-people', ok: true, lines: ['info-people: not a check; the share of each person\'s drawn pixels the set hides, by the depth rule (only the spots where something is hidden)'].concat(lines, ['       pepe.pesa stands ' + (S['pepe.pesa'].screen[0] - S['aguja'].screen[0]) + ' px right of the dial\'s column and ' + (S['pepe.pesa'].screen[1] - S['aguja'].screen[1]) + ' rows below its centre: his box columns ' + pe.box[0] + ' to ' + pe.box[2] + ', rows ' + pe.box[1] + ' to ' + pe.box[3] + ' against the dial and pan box ' + T.pesa.box.join(', ') + ' (x, y, w, h); his shown pixels lie over ' + pe.onScale + ' of the ' + probes[0].scaleTotal + ' pixels the set draws in the dial and pan box (carro 0), and with carro = 1 ' + pe1.onScale + ' (the cart hides ' + (pe1.hidBy.carro || 0) + ' of his pixels)']) });
  }
  return OUTS;
}

// the ledge's top, from the spots: monedas4's z
const CF_LZ = S => S['monedas4'].world[2];
// a world point's projection, from the sheet's own origin: [sx, sy] (the same arithmetic as pp-engine.js project)
function project3(G, x, y, z) {
  const R2 = Math.SQRT2, COS = Math.sqrt(3) / 2, OX = G.W / 2 + G.scene.originX, OY = G.H / 2 + G.scene.originY, u = (x - y) / R2, v = (x + y) / R2;
  return [OX + u * G.S, OY + (v * .5 - z * COS) * G.S];
}
