#!/usr/bin/env node
'use strict';
/* La caja's sheet (pass 3): writes docs/proyecto/pixel/caja-sheet.json from caja-set.html and the design (the orchestrator's caja-spec, part B, and the v3 brief), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/caja-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set (window.CAJA.CD: the room's constants) in headless Chrome, projects every world point with the
   engine's own project() (pp-engine.js), and writes the spots, things, view, shadows and the depth rule, the same as El mostrador's sheet (mostrador-sheet-make.js).
   It also loads the sprite makers (historia/engine.js, escenas/kit.js) in a second page to read how many rows and columns today's person, child and frog draw: the checks
   that say "seen from the thighs up" and "shows head and shoulders through the window" place the real silhouette on its spot and test it with the depth rule.
   Pass 3 adds: the frog at coqui.frente on the floor (no coqui.repisa), the amount as a thing (importe), the price tags' etiqueta field, the children outside the shop window placed so that
   they show only through the panes (stepped, or clipped), and the checks that read the PREVIEW's moments (caja-preview.html, PREVIEW.inspect): the sheet is written first without its
   checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with CAJA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'caja-sheet.json');
const BASE = process.env.CAJA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/caja-set.html';
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

const PERSON = { rows: 53, minAbove: 28 };               // the standing figure's drawn rows (the design's number), and the rows of it that must be above the counter's top back edge
const FROG_HEAD_ROWS = 25;                               // the frog's head above CAJA_REPISA, as the design counts it
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const MIN_APART = 12;                                    // px between two people's feet on screen
const CARD = { w: 30, h: 26, gap: 10 };                  // an answer key card, and the space between the two
const CARD_ABOVE = 6;                                    // the cards' bottom edge is this many px above the register's topmost pixel (the design says only: above the register, inside the window)
const MIN_HEAD_ROWS = 20;                                // rows of a child's head and shoulders that show through the shop window (v3: 20)
const FROG_SIDEWAYS = 28;                                // px sideways between coqui.frente and cliente / cola1 (v3)
const FROG_BOX = { w: 32, h: 25 };                       // the frog's box: 32 wide (column 16 on the spot), 25 rows above its spot (the design's FROG_HEAD_ROWS)
const ETIQUETA = { dw: [-0.05, 0.3, 0], box: [11, 10] }; // the price tag of every cosa_* spot: its foot point as a world offset from the thing, and its size (v3)
const IMPORTE = { size: [13, 9], digits: { count: 2, size: [5, 7], gap: 1 } };   // the amount: a pale plate with two numerals, its middle on the screen point of ventana_caja (v3)
const GLASS_X = -.25;                                    // a pixel of part vitrina whose world x (read back from the baked depth) is left of this is the window's glass (the backdrop pane is at x -.5); right of it, the frame or the sill
const NINOS_X = [-.4, -.5, -.6, -.7, -.8, -.9, -1.0, -1.1, -1.2];   // the x's tried for the children outside the window, in this order (v3)
const DOOR_XS = [-.3, -.4, -.5, -.6, -.7, -.8];          // the x's tried for the child in the street doorway (v3b), in this order; his y is the door's middle (PD0 + PD1) / 2 = 4.3
const STREET_X = -.04;                                   // a pixel of part puerta whose world x (read back from the baked depth) is left of this is the street seen through the doorway (the backdrop at x -.5, the pavement); right of it, the frame, the leaf, the wall

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);

  const SP = await sprites(browser);
  await page.goto(PAGE + '?tags=1&hora=tarde');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(CAJA.CD)) if (typeof v !== 'function') o[k] = v;
    // the bounding box of each part's pixels, and the amount window: the pale pane of the register's head (paneY (226, 242, 212)) among the register's pixels
    const bb = {}; for (let i = 0; i < TAGS.length; i++) { const n = TAGS[i]; if (!n) continue; const x = i % W, y = (i / W) | 0, b = bb[n] || (bb[n] = [1e9, 1e9, -1, -1]); if (x < b[0]) b[0] = x; if (x > b[2]) b[2] = x; if (y < b[1]) b[1] = y; if (y > b[3]) b[3] = y; }
    let p0 = [1e9, 1e9, -1, -1];
    for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'caja') { const v = bakedPix[i], r = v & 255, g = (v >> 8) & 255, b = (v >> 16) & 255; if (r >= 200 && g >= 225 && b >= 185 && g > r) { const x = i % W, y = (i / W) | 0; if (x < p0[0]) p0[0] = x; if (x > p0[2]) p0[2] = x; if (y < p0[1]) p0[1] = y; if (y > p0[3]) p0[3] = y; } }
    return { CD: o, scene: PP_SCENE, W, H, S, OX, OY, bb, pane: p0 };
  });
  const ninos = await stepNinos(page, SP, G);                                  // the children outside the window: x stepped until they show only through the panes (or clipped)
  const sheet = await make(G, proj, SP, ninos);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');         // first without the checks: the preview reads the sheet
  // the checks that read the set's own pixels: both hours; and the preview's moments (caja-preview.html, PREVIEW.inspect)
  const probes = await probeSets(page, sheet, SP);
  const PVD = await previewData(browser, errs);
  const results = checks(sheet, probes, SP, G, PVD, ninos);
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


/* ---------- the children outside (v3, v3b): two at the shop window, one in the street doorway ----------
   WINDOW (children 1 and 3): they show ONLY through the panes: not one pixel over the wall, the sill or beside the frame. Child 1's head is in the middle of the pane on the VW0 side, child 3's in the middle
   of the one on the VW1 side (their column on the screen is the pane's middle column: y = the pane's middle y + x, since a point at (x, y) is in the column of the wall point (0, y + x)). Tried for x = -.4,
   -.5 ... -1.2 in that order, the first that shows zero pixels outside the panes and 20 rows or more of each is used. If none does: x = -.5 and a `clip` box on the two spots.
   DOORWAY (child 2, v3b): at (x, 4.3, 0), in the open street doorway, looking in. Tried for x = -.3, -.4 ... -.8 in that order, the first that shows 20 rows or more of him in the door opening and no pixel
   over the wall or the door frame is used. If none does: (-.3, 4.3, 0) is left. */
async function stepNinos(page, SP, G) {
  const masks = [SP.luis, SP.carmen, SP.nino3].map(m => ({ ax: m.ax, bottom: m.bottom, px: m.px }));
  return page.evaluate(arg => {
    const { masks, XS, DXS, bias, glassX, streetX, minRows } = arg, CD = CAJA.CD, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2, T30 = Math.tan(Math.PI / 6), Z = DEPTH.z;
    const r4 = v => Math.round(v * 1e4) / 1e4;
    const mid = (CD.VW0 + CD.VW1) / 2, m0 = mid - .04, m1 = mid + .04;                // the mullion: y m0 .. m1 on the wall (colmado-dentro.js: a bar .08 wide at (VW0 + VW1) / 2 - .04)
    const pane = [[CD.VW0, m0], [m1, CD.VW1]], yc = pane.map(p => (p[0] + p[1]) / 2);   // the two panes' y ranges on the wall, and their middles
    // what a child shows: the pixels the depth rule leaves visible, over a set pixel that is `inside` (x read back from the baked depth) or not
    const measure = (w, m, inside) => {
      const q = project(w[0], w[1], w[2]), sx = Math.round(q.sx), sy = Math.round(q.sy);
      let vis = 0, outside = 0; const rows = new Set(), over = {};
      for (const [px, py] of m.px) {
        const X = sx - m.ax + px, Y = sy - m.bottom + py; if (X < 0 || X >= W || Y < 0 || Y >= H) continue;
        const i = Y * W + X, plane = q.d + (sy - (Y + .5)) * T30 / S;
        if (Z[i] > plane + bias) continue;
        vis++;
        const b = (X + .5 - OX) / S, syp = (Y + .5 - OY) / S, z = (Z[i] - 2 * COS * syp) / 2, a = 2 * (syp + z * COS), wx = (a + b) * R2 / 2;
        if (inside(TAGS[i], wx)) rows.add(Y); else { outside++; over[(TAGS[i] || 'none')] = (over[(TAGS[i] || 'none')] || 0) + 1; }
      }
      return { world: w, screen: [sx, sy], visible: vis, outside, over, rows: rows.size };
    };
    const glass = (t, wx) => t === 'vitrina' && wx < glassX, street = (t, wx) => t === 'puerta' && wx < streetX;
    const runWin = x => {
      const sp = [[x, yc[0] + x], [x, yc[1] + x]].map(p => [r4(p[0]), r4(p[1]), 0]);
      const kids = sp.map((w, c) => measure(w, masks[c === 0 ? 0 : 2], glass));
      return { x, spots: sp, kids, ok: kids.every(k => k.outside === 0 && k.rows >= minRows) };
    };
    const tried = XS.map(runWin), hit = tried.find(t => t.ok);
    // the panes' screen box (the frame's inner edge: the hole in the wall, y VW0 .. VW1, z VZ0 .. VZ1), for the clip if no x passes
    const cs = []; for (const y of [CD.VW0, CD.VW1]) for (const z of [CD.VZ0, CD.VZ1]) { const q = project(0, y, z); cs.push([q.sx, q.sy]); }
    const x0 = Math.floor(Math.min(...cs.map(c => c[0]))), y0 = Math.floor(Math.min(...cs.map(c => c[1])));
    const box = [x0, y0, Math.ceil(Math.max(...cs.map(c => c[0]))) - x0, Math.ceil(Math.max(...cs.map(c => c[1]))) - y0];
    const used = hit || runWin(-.5);
    // the doorway
    const dy = (CD.PD0 + CD.PD1) / 2;
    const dTried = DXS.map(x => { const k = measure([x, r4(dy), 0], masks[1], street); return Object.assign({ x, ok: k.outside === 0 && k.rows >= minRows }, k); });
    const dHit = dTried.find(t => t.ok), dUsed = dHit || dTried[0];
    return { x: used.x, spots: used.spots, clip: hit ? null : box, tried: tried.map(t => ({ x: t.x, ok: t.ok, kids: t.kids.map(k => ({ outside: k.outside, over: k.over, rows: k.rows })) })), pane: { y: pane, middle: yc, mullion: [m0, m1] },
      door: { ok: !!dHit, x: dUsed.x, spot: dUsed.world, tried: dTried.map(t => ({ x: t.x, ok: t.ok, outside: t.outside, over: t.over, rows: t.rows, visible: t.visible })) } };
  }, { masks, XS: NINOS_X, DXS: DOOR_XS, bias: BIAS, glassX: GLASS_X, streetX: STREET_X, minRows: MIN_HEAD_ROWS });
}

/* ---------- the preview's moments: caja-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/caja-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const out = {};
  for (const m of [1, 2, 3, 4, 'counter']) out[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m);
  await p.close();
  return out;
}

/* ---------- today's sprites: what they draw (rows, columns, the silhouette) ---------- */
async function sprites(browser) {
  const p = await browser.newPage();
  const errs = [];
  p.on('pageerror', e => errs.push(String(e)));
  await p.setContent('<!doctype html><html><body><canvas id="cv" width="196" height="216" hidden></canvas><div hidden><button id="go"></button><button id="again"></button><button id="next"></button><button id="snd"></button><button id="close"></button><button id="home"></button><button id="map"></button></div></body></html>');
  for (const f of ['historia/engine.js', 'historia/palabras.js', 'historia/juego.js', 'historia/escenas/kit.js']) await p.addScriptTag({ path: path.join(REPO, f) });
  const r = await p.evaluate(() => {
    const PIEL = KIT.PIEL, PELO = KIT.PELO, FAM = KIT.FAM;
    const PEPE = { piel: PIEL.c, pelo: PELO.negro, peinado: 'corto', ropa: ['#C8C8D0', '#E4E4EA', '#F6F6FA', '#FFFFFF'], abajo: RP.grey, bigote: 1,
      detalle: (b, X) => { const G = RP.grn; b.rect(X - 4, 18, 1, 4, G[1]); b.rect(X + 3, 18, 1, 4, G[1]); b.rect(X - 5, 22, 10, 24, G[2]); b.rect(X - 5, 22, 2, 24, G[3]); b.rect(X + 3, 22, 2, 24, G[1]); b.rect(X - 5, 45, 10, 1, G[0]); b.rect(X - 5, 22, 10, 1, G[3]); b.rect(X - 3, 34, 6, 4, G[1]); b.rect(X - 3, 34, 6, 1, G[3]); } };
    const NINO3 = { nino: 1, piel: PIEL.c, pelo: PELO.castano, peinado: 'corto', ropa: RP.yel, abajo: RP.grey, zapato: '#F2F2F8' };
    const mask = (cv, ax) => {
      const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, px = []; let bottom = 0, top = 1e9, x0 = 1e9, x1 = -1;
      for (let y = 0; y < cv.height; y++) for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { px.push([x, y]); if (y + 1 > bottom) bottom = y + 1; if (y < top) top = y; if (x < x0) x0 = x; if (x > x1) x1 = x; }
      return { ax, bottom, rows: bottom - top, cols: x1 - x0 + 1, left: x0 - ax, right: x1 - ax, px };
    };
    return {
      pepe: mask(KIT.mkPersona(PEPE, 'idle', 0, 0), KIT.PX), luis: mask(KIT.mkPersona(FAM.hermano, 'idle', 0, 0), KIT.PX), carmen: mask(KIT.mkPersona(FAM.hermana, 'idle', 0, 0), KIT.PX), nino3: mask(KIT.mkPersona(NINO3, 'idle', 0, 0), KIT.PX),
      senora: mask(KIT.mkPersona({ piel: PIEL.a, pelo: PELO.castano, peinado: 'corto', ropa: RP.grn, falda: 1, zapato: '#F2F2F8' }, 'idle', 0, 0), KIT.PX),
      coqui: mask(mkCoqui(1, 0, 0), 16), coqui8: mask(mkCoqui(.8, 0, 0), 13),
    };
  });
  await p.close();
  if (errs.length) throw new Error('sprite page: ' + errs.join('; '));
  return r;
}

/* ---------- the sheet ---------- */
async function make(G, proj, SP, ninos) {
  const CD = G.CD, CH = CD.CH;
  const P1 = async p => (await proj([p]))[0];
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];
  const RGM = CD.CAJA_VENTANA[0], WMID = (CD.VW0 + CD.VW1) / 2, DY = (CD.PD0 + CD.PD1) / 2;

  /* ---- spots: the ground (or the counter top, the shelf, the sill, the register's face) under the feet; frog scale 1 unless given ---- */
  const D = [];                                                                       // [name, world, kind, what, extra]
  const person = (name, w, what, extra) => D.push([name, w, 'person', what, extra]);
  const onCounter = (name, x, y, what) => D.push([name, [x, y, CH], 'counter', what]);
  person('pepe.caja', [1.925, 1.0, 0], 'don Pepe behind the register (v3: (1.925, 1.0, 0); x is the register\'s middle, CD.CAJA_VENTANA[0])');
  person('pepe.empaca', [3.6, 1.2, 0], 'don Pepe packing bags beside the register');
  person('coqui.frente', [4.3, 3.6, 0], 'the frog on the floor in front of the counter, as in El mostrador (v3: not on the register\'s shelf and not on the counter)');
  person('cliente', [2.7, 4.0, 0], 'the customer at the register');
  person('cola1', [3.5, 4.5, 0], 'the line, first: running away from the door');
  person('cola2', [4.3, 5.0, 0], 'the line, second');
  person('cola3', [5.1, 5.5, 0], 'the line, third');
  onCounter('cosa_cliente', 2.95, 2.6, 'what the customer sets down; its price tag stands in front of it');
  onCounter('cosa_a', 3.6, 2.55, 'the first of the two things of story 46; its price tag in front');
  onCounter('cosa_b', 4.3, 2.55, 'the second of the two things of story 46; its price tag in front');
  onCounter('papel', 5.2, 2.3, 'the holder of gift paper');
  onCounter('taza_abuela', 4.85, 2.25, 'the cup set aside');
  onCounter('frasco', 3.35, 2.2, 'the children\'s jar');
  D.push(['clip', [CD.CAJA_GAVETA[0] + .35, CD.CAJA_GAVETA[1], CD.CAJA_GAVETA[2] + .3], 'face', 'the frog\'s bills, clipped on the register\'s front face at its right top corner (CD.CAJA_GAVETA: .35 to the right, .3 up)']);
  D.push(['ventana_caja', CD.CAJA_VENTANA.slice(), 'window', 'the register\'s amount window (CD.CAJA_VENTANA): the numerals of the amount are drawn here, two digits, about 5 x 7 px each']);
  D.push(['bola', [.16, WMID, CD.VZ0 - .04], 'sill', 'the ball on the sill inside the shop window (x .16, the window\'s middle y, the sill\'s top)']);
  [ninos.spots[0], ninos.door.spot, ninos.spots[1]].forEach((w, i) => person('ninos_fuera.' + (i + 1), w, i === 1
    ? 'child 2 of the three outside, in the open street doorway, looking in (no shadow); group ninos_fuera. v3b: (x, 4.3, 0), the first x of -0.3 to -0.8 (steps of 0.1) that shows ' + MIN_HEAD_ROWS + ' rows or more of him in the door opening and no pixel over the wall or the door frame' + (ninos.door.ok ? ': x ' + ninos.door.x : ': none passed, so (-0.3, 4.3, 0) is left')
    : 'child ' + (i + 1) + ' of the three outside, at the shop window, seen through its panes only (no shadow); group ninos_fuera. v3: its head in the middle of the ' + (i === 0 ? 'pane on the VW0 side' : 'pane on the VW1 side') + '; x ' + ninos.x + (ninos.clip ? ', no x passed, so x -0.5 and a clip box' : ', the first x of -0.4 to -1.2 (steps of 0.1) that shows zero pixels outside the panes and ' + MIN_HEAD_ROWS + ' rows or more of the child; no clip'), i !== 1 && ninos.clip ? { clip: ninos.clip } : undefined));
  [[1.1, 4.4], [1.7, 4.9], [2.4, 5.4]].forEach(([x, y], i) => person('ninos_dentro.' + (i + 1), [x, y, 0], 'child ' + (i + 1) + ' of the three inside; group ninos_dentro'));
  person('puerta', [.5, DY, 0], 'just inside the street door');
  const pr = await proj(D.map(d => d[1]));
  const spots = {};
  D.forEach((d, i) => {
    const q = pr[i];
    spots[d[0]] = Object.assign({ world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2], what: d[3] }, d[4] || {});
  });

  /* ---- things he can touch ---- */
  const boxOf = async w => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys));
    return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0];
  };
  // the register: the box of the set's part 'caja'. colmado-dentro.js exports its middle (RGM), its front (CAJA_GAVETA y), the height of its body (CAJA_GAVETA z - CH = bodyH / 2) and its shelf's middle
  // (CAJA_REPISA); the rest is its own constants (RG: x0 = CX0 + .1, y0 = CY0 + .05, headH .6, the bell's top .26 over the head). The box covers the register and its side shelf (x1 = the shelf's far side)
  const bodyH = 2 * (CD.CAJA_GAVETA[2] - CH), rx0 = CD.CX0 + .1, rx1 = 2 * RGM - rx0, shx1 = 2 * CD.CAJA_REPISA[0] - rx1;
  const CAJA_W = [rx0, CD.CY0 + .05, CH, shx1, CD.CAJA_GAVETA[1], CH + bodyH + .6 + .26];
  const things = { caja: Object.assign({ set: true, world: W4(CAJA_W), box: await boxOf(CAJA_W), what: 'the register with its side shelf: the box of the set\'s part \'caja\'' }) };
  for (const k of ['tecla_a', 'tecla_b', 'cosa_a', 'cosa_b', 'frasco', 'papel', 'bola', 'pepe', 'luis', 'carmen', 'senora', 'senor', 'ninos', 'coqui']) things[k] = 'sprite';

  /* ---- the view `wide`: zoom 1, x0 so that the register, the shop window, the street door with its open leaf and the floor in front of the counter are inside ---- */
  const bb = G.bb;
  const parts = { register: bb.caja, 'shop window': bb.vitrina, 'street door (with its open leaf)': bb.puerta, counter: bb.mostrador };
  const floor = ['pepe.empaca', 'coqui.frente', 'cliente', 'cola1', 'cola2', 'cola3', 'ninos_dentro.1', 'ninos_dentro.2', 'ninos_dentro.3', 'puerta'];
  const xs = [].concat(Object.values(parts).flatMap(b => [b[0], b[2] + 1]), floor.flatMap(k => [spots[k].screen[0] - 12, spots[k].screen[0] + 12]));
  const lo = Math.min(...xs), hi = Math.max(...xs), x0 = Math.max(0, Math.min(G.W - 196, Math.round((lo + hi) / 2 - 98)));
  const views = { wide: { zoom: 1, x0, region: [x0, 0, 196, 216], needs: { from: lo, to: hi, parts: Object.fromEntries(Object.entries(parts).map(([k, b]) => [k, [b[0], b[2] + 1]])) }, what: 'the 196 x 216 window over the 240 x 216 picture. x0 = clamp(round(the middle of what must be inside - 98), 0, 44): what must be inside is the register, the shop window, the street door with its open leaf and the counter (the columns of the pixels the set draws for those parts) and the floor in front of the counter (the spots pepe.empaca, coqui.frente, cliente, cola1 to cola3, ninos_dentro.1 to .3 and puerta, 12 px to each side); `needs` gives that span [from, to)' } };

  /* ---- the two answer key cards: screen boxes, side by side, centred above the register ---- */
  const rm = await P1([RGM, (CAJA_W[1] + CAJA_W[4]) / 2, CH]), cx = Math.round(rm[0]);
  const top = bb.caja[1], bottom = top - CARD_ABOVE, cy = bottom - CARD.h, ax = cx - (CARD.w * 2 + CARD.gap) / 2;
  const cards = { final: true, centre: cx, registerTop: top, bottomAbove: CARD_ABOVE };
  spots.tecla_a = { kind: 'card', box: [ax, cy, CARD.w, CARD.h], what: 'the first answer key, a card over the picture (the game draws it): ' + CARD.w + ' x ' + CARD.h + ' px, centred above the register with tecla_b, ' + CARD.gap + ' px gap; its bottom edge is ' + CARD_ABOVE + ' px above the register\'s topmost pixel' };
  spots.tecla_b = { kind: 'card', box: [ax + CARD.w + CARD.gap, cy, CARD.w, CARD.h], what: 'the second answer key, to the right of tecla_a' };

  // the amount window as the set draws it: the pale pane
  const pane = G.pane[2] < 0 ? null : [G.pane[0], G.pane[1], G.pane[2] - G.pane[0] + 1, G.pane[3] - G.pane[1] + 1];
  spots.ventana_caja.pane = pane;
  spots.ventana_caja.digits = Object.assign({ count: IMPORTE.digits.count }, { size: IMPORTE.digits.size, gap: IMPORTE.digits.gap });
  // v3: the price tag of every cosa_* spot: the tag's foot point as a world offset from the thing, and its size
  for (const k of Object.keys(spots)) if (k.startsWith('cosa_')) spots[k].etiqueta = { dw: ETIQUETA.dw.slice(), box: ETIQUETA.box.slice() };
  // v3: the amount, a sprite: a pale plate 13 x 9 with two numerals of 5 x 7, its middle (column 6, row 4 of the plate) on the screen point of ventana_caja, drawn in front of the register
  const vs = spots.ventana_caja.screen, ib = [vs[0] - (IMPORTE.size[0] >> 1), vs[1] - (IMPORTE.size[1] >> 1), IMPORTE.size[0], IMPORTE.size[1]];
  things.importe = { sprite: true, at: 'ventana_caja', size: IMPORTE.size.slice(), box: ib, digits: { count: IMPORTE.digits.count, size: IMPORTE.digits.size.slice(), gap: IMPORTE.digits.gap }, what: 'the amount the register shows: a sprite, a pale plate ' + IMPORTE.size.join(' x ') + ' with two numerals of ' + IMPORTE.digits.size.join(' x ') + ' (' + (IMPORTE.digits.count * IMPORTE.digits.size[0] + IMPORTE.digits.gap) + ' wide with a ' + IMPORTE.digits.gap + ' px gap), its middle on the screen point of spots.ventana_caja; drawn in front of the register (hidden only by a sprite nearer than the window)' };

  const groups = { ninos_fuera: ['ninos_fuera.1', 'ninos_fuera.2', 'ninos_fuera.3'], ninos_dentro: ['ninos_dentro.1', 'ninos_dentro.2', 'ninos_dentro.3'], cola: ['cola1', 'cola2', 'cola3'] };
  const sc = G.scene;
  return {
    scene: 'caja',
    made: 'node docs/proyecto/pixel/caja-sheet-make.js, from caja-set.html (window.CAJA.CD) and the design of La caja. A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      spot: 'a spot is a world point of the feet (z 0: the floor; z 1: the counter top; z .96: the sill) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54), a child 41 rows (a 44-row canvas); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy, as juego.js frogBox: his shadow line q.y + 25); a small thing: its bottom middle on the point',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0, kept inside 0 .. 44. Never a fraction',
      person: 'for the check "seen from the thighs up": a person is ' + PERSON.rows + ' rows tall (the standing figure\'s drawn rows), at least ' + PERSON.minAbove + ' of them above the counter\'s top back edge at his column',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
      cards: 'tecla_a and tecla_b have a screen box (x, y, w, h) in picture pixels and no world point: the game draws them over the picture',
    },
    setKey: {
      params: { hora: { values: ['manana', 'tarde'] } },
      key: 'hora, e.g. "tarde" (the back door is always shut; no props, no freezer)',
      baked: ['manana', 'tarde'].map(h => '?hora=' + h),
    },
    things,
    spots,
    groups,
    views,
    cards,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so the counter hides don Pepe\'s legs, nothing behind him hides him, and the wall hides the three children outside the shop window below the sill.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El balcón\'s front; the same test for people and for things on the counter',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, pepe: .35, senora: .35, senor: .35, luis: .28, carmen: .28, ninos: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0)',
      none: ['ninos_fuera.1', 'ninos_fuera.2', 'ninos_fuera.3'],
    },
  };
}

/* ---------- the checks that read the set's pixels and the sprites' silhouettes ---------- */
async function probeSets(page, sheet, SP) {
  const S = sheet.spots, R = {};
  const place = (name, sp) => ({ name, sx: S[name].screen[0], sy: S[name].screen[1], d: S[name].depth, ax: sp.ax, bottom: sp.bottom, px: sp.px, clip: S[name].clip || null });
  const sp = (m, ax) => Object.assign({ ax }, m);
  const jobs = {
    pepe: place('pepe.caja', sp(SP.pepe, SP.pepe.ax)),
    kids: [['ninos_fuera.1', SP.luis], ['ninos_fuera.2', SP.carmen], ['ninos_fuera.3', SP.nino3]].map(([n, m]) => place(n, sp(m, m.ax))),
    pepeEmpaca: place('pepe.empaca', sp(SP.pepe, SP.pepe.ax)),
  };
  for (const hora of ['manana', 'tarde']) {
    await page.goto(PAGE + '?tags=1&hora=' + hora);
    R[hora] = await page.evaluate(arg => {
      const T30 = Math.tan(Math.PI / 6);
      // each ink pixel of the sprite placed on its spot: hidden by the depth rule, and which part of the set is under it
      const run = j => {
        const COS = Math.sqrt(3) / 2, out = []; for (const [px, py] of j.px) {
          const X = j.sx - j.ax + px, Y = j.sy - j.bottom + py;
          if (X < 0 || X >= W || Y < 0 || Y >= H) { out.push([px, py, 1, null, null]); continue; }
          const plane = j.d + (j.sy - (Y + .5)) * T30 / DEPTH.S, i = Y * W + X;
          // the world x of the set pixel under it, read back from the baked depth (the glass is at x -.5, the frame and the sill right of -.25)
          const b = (X + .5 - OX) / S, syp = (Y + .5 - OY) / S, z = (DEPTH.z[i] - 2 * COS * syp) / 2, a = 2 * (syp + z * COS), wx = (a + b) * Math.SQRT2 / 2;
          const clipped = j.clip && (X < j.clip[0] || X >= j.clip[0] + j.clip[2] || Y < j.clip[1] || Y >= j.clip[1] + j.clip[3]);   // a clip box: nothing outside it is drawn
          out.push([px, py, clipped || DEPTH.z[i] > plane + arg.bias ? 1 : 0, TAGS[i], wx]);
        }
        return { name: j.name, px: out };
      };
      // the counter's top back edge (y = CY0, z = CH) in the column cx, on the screen
      const edge = cx => { const u = (cx - OX) / S, x = CAJA.CD.CY0 + u * Math.SQRT2, y = CAJA.CD.CY0, sy = OY + (((x + y) / Math.SQRT2) * .5 - CAJA.CD.CH * Math.sqrt(3) / 2) * S; return { x, sy }; };
      return { pepe: run(arg.jobs.pepe), kids: arg.jobs.kids.map(run), pepeEmpaca: run(arg.jobs.pepeEmpaca), edge: edge(arg.jobs.pepe.sx), edgeEmpaca: edge(arg.jobs.pepeEmpaca.sx), bias: arg.bias };
    }, { jobs, bias: BIAS });
  }
  return R;
}

function checks(sheet, probes, SP, G, PVD, ninos) {
  const S = sheet.spots, T = sheet.things, V = sheet.views.wide, OUTS = [], CD = G.CD;
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const pts = Object.entries(S).filter(([, s]) => s.screen);                         // the spots that have a point (the cards have a box)
  const [x0] = V.region, W0 = sheet.picture[0], H0 = sheet.picture[1];

  // 1. every spot and thing inside the picture and the window (the two cards have a box, the register a box)
  {
    const bad = [];
    for (const [k, s] of pts) {
      if (s.screen[0] < 0 || s.screen[0] >= W0 || s.screen[1] < 0 || s.screen[1] >= H0) bad.push(k + ' ' + s.screen + ' outside the picture');
      else if (s.screen[0] < x0 || s.screen[0] >= x0 + 196 || s.screen[1] < 0 || s.screen[1] >= 216) bad.push(k + ' ' + s.screen + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    }
    const boxes = Object.entries(T).filter(([, t]) => t.box).map(([k, t]) => [k, t.box]).concat(['tecla_a', 'tecla_b'].map(k => [k, S[k].box]));
    for (const [k, b] of boxes) if (b[0] < x0 || b[0] + b[2] > x0 + 196 || b[1] < 0 || b[1] + b[3] > 216) bad.push(k + ' box ' + b + ' outside the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)');
    add('in-view', bad, pts.length + ' spot points and ' + boxes.length + ' boxes (' + boxes.map(([k, b]) => k + ' ' + b).join(', ') + ') inside the ' + sheet.picture.join(' x ') + ' picture and the window [' + x0 + ', ' + (x0 + 196) + ') x [0, 216)', ['outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    OUTS[OUTS.length - 1].lines.push('       the window x0 = ' + x0 + ' holds what must be inside, which spans columns ' + V.needs.from + ' to ' + V.needs.to + ' (' + Object.entries(V.needs.parts).map(([k, b]) => k + ' ' + b[0] + '..' + b[1]).join(', ') + ')');
    const part = Object.entries(V.needs.parts).filter(([, b]) => b[0] < x0 || b[1] > x0 + 196).map(([k]) => k);
    if (part.length) { OUTS[OUTS.length - 1].ok = false; OUTS[OUTS.length - 1].lines[0] = OUTS[OUTS.length - 1].lines[0].replace('in-view:', 'in-view: NOT HELD BY THE WINDOW: ' + part.join(', ') + ';'); }
  }

  // 2. people on screen together at least 12 px apart: pepe.caja, coqui.frente, cliente, cola1, cola2, cola3; ninos_dentro.1 to .3 with cliente. (info: pepe.empaca, the same body as pepe.caja, in the line)
  {
    const A = ['pepe.caja', 'coqui.frente', 'cliente', 'cola1', 'cola2', 'cola3'], pairs = [];
    for (let i = 0; i < A.length; i++) for (let j = i + 1; j < A.length; j++) pairs.push([A[i], A[j]]);
    for (const k of ['ninos_dentro.1', 'ninos_dentro.2', 'ninos_dentro.3']) pairs.push([k, 'cliente']);
    const d = ([a, b]) => Math.hypot(S[a].screen[0] - S[b].screen[0], S[a].screen[1] - S[b].screen[1]);
    const all = pairs.map(p => [p[0], p[1], d(p)]).sort((p, q) => p[2] - q[2]), near = all.filter(p => p[2] < MIN_APART);
    add('people-apart', near, all.length + ' pairs (' + A.join(', ') + '; and ninos_dentro.1 to .3 with cliente) at least ' + MIN_APART + ' px apart on screen (closest: ' + all.slice(0, 3).map(p => p[0] + ' ~ ' + p[1] + ' ' + r2(p[2]) + ' px').join(', ') + ')',
      [near.length + ' pair(s) closer than ' + MIN_APART + ' px (screen points):'].concat(near.map(p => '  ' + p[0] + ' ' + S[p[0]].screen + ' ~ ' + p[1] + ' ' + S[p[1]].screen + ': ' + r2(p[2]) + ' px')));
    const emp = ['coqui.frente', 'cliente', 'cola1', 'cola2', 'cola3'].map(k => [k, d(['pepe.empaca', k])]).sort((a, b) => a[1] - b[1]);
    OUTS[OUTS.length - 1].lines.push('       info, not a check: pepe.empaca (the same body as pepe.caja) is ' + emp.map(e => e[0] + ' ' + r2(e[1]) + ' px').join(', ') + ' from the others');
  }

  // 2b. (v3) the frog at coqui.frente is FROG_SIDEWAYS px or more sideways (columns) from cliente and from cola1
  {
    const f = S['coqui.frente'].screen, bad = [], got = [];
    for (const k of ['cliente', 'cola1']) { const dx = Math.abs(f[0] - S[k].screen[0]); got.push(k + ' ' + S[k].screen + ' ' + dx + ' px'); if (dx < FROG_SIDEWAYS) bad.push('coqui.frente ' + f + ' is ' + dx + ' px sideways from ' + k + ' ' + S[k].screen + ' (needs ' + FROG_SIDEWAYS + ')'); }
    add('frog-sideways-apart', bad, 'coqui.frente ' + f + ' is at least ' + FROG_SIDEWAYS + ' px sideways from cliente and from cola1: ' + got.join(', '), ['coqui.frente:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 3. don Pepe at pepe.caja seen from the thighs up: at least 28 of 53 rows above the counter's back edge, and not hidden by the register for more than a third of his width
  {
    const rows = PERSON.rows, min = PERSON.minAbove, st = S['pepe.caja'], feet = st.screen[1];
    const tarde = probes.tarde, ed = tarde.edge, inX = ed.x >= CD.CX0 && ed.x <= CD.CX1;
    const hidden = feet - ed.sy, above = rows - hidden;
    // the real silhouette on its spot: the columns it covers, and those where the register (part 'caja') nearer than he is covers some of him
    const px = tarde.pepe.px, cols = new Set(px.map(p => p[0])), hid = new Set(px.filter(p => p[2] && p[3] === 'caja').map(p => p[0]));
    const nHid = px.filter(p => p[2] && p[3] === 'caja').length, nHidAny = px.filter(p => p[2]).length;
    const frac = hid.size / cols.size;
    // and the worst single row: the share of that row's ink the register covers
    const rowT = {}, rowH = {}; for (const q of px) { rowT[q[1]] = (rowT[q[1]] || 0) + 1; if (q[2] && q[3] === 'caja') rowH[q[1]] = (rowH[q[1]] || 0) + 1; }
    const worst = Math.max(0, ...Object.keys(rowH).map(r => rowH[r] / rowT[r]));
    // the rows of the figure above the counter by the depth rule: the first hidden row from the top (any part)
    const rowsHidden = new Set(px.filter(p => p[2]).map(p => p[1])), top = Math.min(...px.map(p => p[1])), firstHid = Math.min(...[...rowsHidden]);
    const clear = firstHid - top;
    const bad = [];
    if (!inX) bad.push('the counter\'s back edge at his column is off the counter (x ' + r2(ed.x) + ')');
    if (above < min) bad.push(r2(above) + ' rows above the counter\'s back edge (needs ' + min + ')');
    if (frac > 1 / 3) bad.push(hid.size + ' of his ' + cols.size + ' columns are hidden by the register (' + r2(frac * 100) + ' %, needs at most 33.3 %)');
    add('pepe-thighs-up', bad, 'pepe.caja ' + st.screen + ': ' + r2(above) + ' of ' + rows + ' rows above the counter\'s back edge (' + r2(hidden) + ' rows hidden under it, edge at row ' + r2(ed.sy) + '; needs ' + min + '); the register hides ' + hid.size + ' of his ' + cols.size + ' columns (' + r2(frac * 100) + ' %, at most 33.3 %; worst single row ' + r2(worst * 100) + ' %), ' + nHid + ' of his ' + px.length + ' pixels (' + r2(nHid / px.length * 100) + ' %); by the depth rule ' + clear + ' rows are clear from the top, ' + nHidAny + ' pixels hidden in all (counter and register)', ['pepe.caja:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    if (bad.length) OUTS[OUTS.length - 1].lines.push('       the numbers: pepe.caja ' + st.screen + ': ' + r2(above) + ' of ' + rows + ' rows above the counter\'s back edge (' + r2(hidden) + ' hidden under it, edge at row ' + r2(ed.sy) + '; needs ' + min + '); the register hides ' + hid.size + ' of his ' + cols.size + ' columns (' + r2(frac * 100) + ' %), worst single row ' + r2(worst * 100) + ' %, ' + nHid + ' of his ' + px.length + ' pixels (' + r2(nHid / px.length * 100) + ' %); by the depth rule ' + clear + ' rows are clear from the top, ' + nHidAny + ' pixels hidden in all (counter and register)');
    OUTS[OUTS.length - 1].pepe = { above: r2(above), hiddenRows: r2(hidden), edgeRow: r2(ed.sy), columns: cols.size, columnsHiddenByRegister: hid.size, fraction: r4(frac), worstRowFraction: r4(worst), pixels: px.length, pixelsHiddenByRegister: nHid, rowsClearFromTop: clear };
  }

  // 4. (v3) the children at the window (1 and 3) show ONLY through the panes: not one pixel over the wall, the sill or beside the frame; each shows MIN_HEAD_ROWS rows or more (rows with a pixel the depth rule leaves visible
  //    over the glass). Measured on the sheet's own spots in both hours (a clip box, if the sheet has one, hides what lies outside it); `ninos` is the stepping that chose x
  {
    const bad = [], info = [], over = [], WIN = ['ninos_fuera.1', 'ninos_fuera.3'];
    for (const hora of ['manana', 'tarde']) for (const k of probes[hora].kids.filter(k => WIN.includes(k.name))) {
      const vis = k.px.filter(p => !p[2]), glass = vis.filter(p => p[3] === 'vitrina' && p[4] < GLASS_X), outsideP = vis.filter(p => !(p[3] === 'vitrina' && p[4] < GLASS_X));
      const rowsV = [...new Set(glass.map(p => p[1]))].sort((a, b) => a - b), top = Math.min(...k.px.map(p => p[1]));
      const contiguous = (() => { let n = 0; for (let r = top; rowsV.includes(r); r++) n++; return n; })();
      const where = {}; for (const p of outsideP) where[p[3] || 'none'] = (where[p[3] || 'none'] || 0) + 1;
      if (hora === 'tarde') info.push(k.name + ' ' + rowsV.length + ' rows (' + contiguous + ' from the top of the head; ' + glass.length + ' of ' + k.px.length + ' pixels)');
      over.push(hora + ' ' + k.name + ' ' + outsideP.length + ' px outside the panes' + (outsideP.length ? ' (' + Object.entries(where).map(([t, n]) => n + ' over ' + t).join(', ') + ')' : ''));
      if (outsideP.length) bad.push(hora + ' ' + k.name + ': ' + outsideP.length + ' pixels show outside the panes (' + Object.entries(where).map(([t, n]) => n + ' over ' + t).join(', ') + ')');
      if (rowsV.length < MIN_HEAD_ROWS) bad.push(hora + ' ' + k.name + ': ' + rowsV.length + ' rows through the panes (needs ' + MIN_HEAD_ROWS + ')');
    }
    const kids = WIN.map(k => k + ' ' + S[k].world + ' -> ' + S[k].screen);
    add('ninos-fuera-through-window', bad, 'the way chosen: ' + (ninos.clip ? 'a clip box ' + ninos.clip + ' on the two spots, x -.5' : 'PLACEMENT, x ' + ninos.x + ', no clip') + '. Zero pixels of the two children at the window show outside the panes (over the wall, the sill or the frame) in both hours, and each shows at least ' + MIN_HEAD_ROWS + ' rows through the glass: ' + info.join('; ') + ' (' + kids.join('; ') + ')', ['children at the window:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    OUTS[OUTS.length - 1].lines.push('       the x\'s tried, in order (outside the panes / rows through the glass of child 1, 3, in the afternoon): ' + ninos.tried.map(t => 'x ' + t.x + ' ' + t.kids.map(k => k.outside + '/' + k.rows).join(' ') + (t.ok ? ' PASSES' : ' no')).join('; '));
    OUTS[OUTS.length - 1].lines.push('       pane middles on the wall (y): ' + ninos.pane.middle.map(r2).join(', ') + ' (VW0-side pane y ' + ninos.pane.y[0].map(r2) + ', mullion ' + ninos.pane.mullion.map(r2) + ', VW1-side pane y ' + ninos.pane.y[1].map(r2) + '); a pixel of part vitrina is glass when its world x (from the baked depth) is left of ' + GLASS_X);
    OUTS[OUTS.length - 1].lines.push('       ' + over.join('; '));
    OUTS[OUTS.length - 1].way = ninos.clip ? 'clip' : 'placement';
    OUTS[OUTS.length - 1].ninos = { x: ninos.x, clip: ninos.clip, tried: ninos.tried };
  }

  // 4b. (v3b) child 2 in the open street doorway, looking in (ninos_fuera.2): MIN_HEAD_ROWS rows or more of him show in the door opening (rows with a pixel the depth rule leaves visible over the street seen through
  //     it) and no pixel of him shows over the wall or the door frame (any other set pixel). Both hours; his x was stepped -.3 ... -.8 (first that passes; none: (-.3, 4.3, 0) is left)
  {
    const k0 = 'ninos_fuera.2', bad = [], lines = [];
    for (const hora of ['manana', 'tarde']) {
      const k = probes[hora].kids.find(q => q.name === k0), vis = k.px.filter(p => !p[2]), st = vis.filter(p => p[3] === 'puerta' && p[4] < STREET_X), outsideP = vis.filter(p => !(p[3] === 'puerta' && p[4] < STREET_X));
      const rowsV = new Set(st.map(p => p[1])), where = {}; for (const p of outsideP) where[p[3] || 'none'] = (where[p[3] || 'none'] || 0) + 1;
      lines.push(hora + ': ' + rowsV.size + ' rows in the door opening (' + st.length + ' of ' + k.px.length + ' pixels), ' + outsideP.length + ' px over the wall or the door frame' + (outsideP.length ? ' (' + Object.entries(where).map(([t, n]) => n + ' over ' + t).join(', ') + ')' : ''));
      if (rowsV.size < MIN_HEAD_ROWS) bad.push(hora + ': ' + rowsV.size + ' rows in the door opening (needs ' + MIN_HEAD_ROWS + ')');
      if (outsideP.length) bad.push(hora + ': ' + outsideP.length + ' pixels over the wall or the door frame (' + Object.entries(where).map(([t, n]) => n + ' over ' + t).join(', ') + ')');
    }
    const dr = ninos.door;
    add('nino-fuera-in-doorway', bad, k0 + ' ' + S[k0].world + ' -> ' + S[k0].screen + ' (x ' + dr.x + (dr.ok ? ', the first of ' + DOOR_XS.join(', ') + ' that passes' : ': NONE PASSED, (-0.3, 4.3, 0) is left') + '): ' + lines.join('; '), [k0 + ' ' + S[k0].world + ' -> ' + S[k0].screen + ':'].concat(bad).map((l, i) => i ? '  ' + l : l));
    OUTS[OUTS.length - 1].lines.push('       the x\'s tried (rows in the opening / px over the wall or the frame, afternoon): ' + dr.tried.map(t => 'x ' + t.x + ' ' + t.rows + '/' + t.outside + (t.ok ? ' PASSES' : ' no')).join('; ') + '; a pixel of part puerta is the street when its world x (from the baked depth) is left of ' + STREET_X + ' (the backdrop at x -.5 and the pavement; the frame is at x .03)');
    // info: in moment 4's finished picture
    {
      const L = PVD[4].layers, win = new Map();
      for (const [n, l] of L.entries()) for (const p of l.px) if (!p[2]) { const k = p[0] + ',' + p[1], w = win.get(k); if (!w || p[3] > w[0]) win.set(k, [p[3], n]); }
      const shown = L.map((l, n) => ({ at: l.at, n })).filter(o => o.at && o.at.startsWith('ninos_fuera.')).map(o => {
        const px = L[o.n].px.filter(p => !p[2] && win.get(p[0] + ',' + p[1])[1] === o.n);
        return o.at + ' ' + px.length + ' px in ' + new Set(px.map(p => p[1])).size + ' rows' + (px.length ? ' (columns ' + Math.min(...px.map(p => p[0])) + '..' + Math.max(...px.map(p => p[0])) + ')' : '');
      });
      OUTS[OUTS.length - 1].lines.push('       info, not a check: in moment 4\'s finished picture what is left of each child outside: ' + shown.join('; '));
    }
    OUTS[OUTS.length - 1].door = { x: dr.x, ok: dr.ok, tried: dr.tried };
  }

  // 5. the two key cards inside the window and clear of the frog's head (coqui.frente, 25 rows) and of a 53-row customer at cliente
  {
    const A = S.tecla_a.box, B = S.tecla_b.box, bad = [];
    const rep = S['coqui.frente'].screen, cl = S.cliente.screen, frog = [rep[0] - 16, rep[1] - FROG_HEAD_ROWS, 32, FROG_HEAD_ROWS], cust = [cl[0] + SP.senora.left, cl[1] - PERSON.rows, SP.senora.cols, PERSON.rows];
    const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
    const gap = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
    for (const [k, b] of [['tecla_a', A], ['tecla_b', B]]) {
      if (b[0] < x0 || b[0] + b[2] > x0 + 196 || b[1] < 0 || b[1] + b[3] > 216) bad.push(k + ' ' + b + ' is not inside the window');
      if (meets(b, frog)) bad.push(k + ' ' + b + ' covers the frog\'s head box ' + frog);
      if (meets(b, cust)) bad.push(k + ' ' + b + ' covers the customer\'s box ' + cust);
    }
    if (A[1] + A[3] !== B[1] + B[3] || B[0] - (A[0] + A[2]) !== CARD.gap || A[2] !== CARD.w || A[3] !== CARD.h) bad.push('the two cards are not ' + CARD.w + ' x ' + CARD.h + ' side by side with a ' + CARD.gap + ' px gap');
    add('key-cards', bad, 'tecla_a [' + A + '] and tecla_b [' + B + '] (' + CARD.w + ' x ' + CARD.h + ', gap ' + CARD.gap + ') inside the window; clear of the frog\'s head box [' + frog + '] by ' + Math.min(gap(A, frog), gap(B, frog)) + ' px and of the customer\'s box [' + cust + '] by ' + Math.min(gap(A, cust), gap(B, cust)) + ' px; the register\'s topmost pixel is row ' + G.bb.caja[1] + ', the cards\' bottom edge row ' + (A[1] + A[3]) + ' (' + CARD_ABOVE + ' px above it); their middle column ' + (A[0] + CARD.w + CARD.gap / 2) + ' is the middle of the register\'s body (its side shelf not counted)',
      ['key cards:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 6. (extra) the register's touch box covers the pixels of the set's part 'caja'
  {
    const bb = G.bb.caja, b = T.caja.box, tol = 1, bad = [];
    const cov = bb[0] >= b[0] - tol && bb[1] >= b[1] - tol && bb[2] <= b[0] + b[2] + tol && bb[3] <= b[1] + b[3] + tol;
    if (!cov) bad.push('caja: its pixels span [' + bb + '] (x0, y0, x1, y1), its box is [' + b + '] (x, y, w, h), more than ' + tol + ' px out');
    add('box-covers-set', bad, 'caja pixels [' + bb + '] in box [' + b + '] (1 px tolerance)', ['the touch box does not cover what the set draws:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 7. (extra) the counter-top spots are on the counter top; the frog's shelf, the sill and the clip are where the set draws them
  {
    const bad = [], cnt = Object.entries(S).filter(([, s]) => s.kind === 'counter');
    for (const [k, s] of cnt) if (s.world[0] < CD.CX0 || s.world[0] > CD.CX1 || s.world[1] < CD.CY0 || s.world[1] > CD.CY1) bad.push(k + ' ' + s.world + ' is off the counter top x ' + CD.CX0 + '..' + CD.CX1 + ', y ' + CD.CY0 + '..' + CD.CY1);
    // the bills' clip on the register's front face: right of the drawer front's middle, inside the register's x range
    const c = S.clip.world; if (c[0] < T.caja.world[0] || c[0] > T.caja.world[3]) bad.push('clip x ' + c[0] + ' is off the register');
    add('counter-spots-on-top', bad, cnt.length + ' counter-top spots (' + cnt.map(([k]) => k).join(', ') + ') inside the counter top x ' + CD.CX0 + '..' + CD.CX1 + ', y ' + CD.CY0 + '..' + CD.CY1 + '; the clip is on the register', ['spots off:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    // info: the amount window against the numerals
    const pane = S.ventana_caja.pane, dg = S.ventana_caja.digits, w = dg.count * dg.size[0] + (dg.count - 1) * dg.gap, h = dg.size[1];
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the amount window\'s pale pane is ' + (pane ? pane[2] + ' x ' + pane[3] + ' px (at ' + pane[0] + ',' + pane[1] + ')' : 'not found') + '; the numerals of the design (' + dg.count + ' digits of ' + dg.size.join(' x ') + ', ' + dg.gap + ' px gap) are ' + w + ' x ' + h + ' px' + (pane && (w > pane[2] || h > pane[3]) ? ': they do NOT fit in it (' + (w > pane[2] ? (w - pane[2]) + ' px too wide' : '') + (w > pane[2] && h > pane[3] ? ', ' : '') + (h > pane[3] ? (h - pane[3]) + ' px too tall' : '') + ')' : ''));
    OUTS[OUTS.length - 1].window = { pane, digits: w + ' x ' + h, fits: !!pane && w <= pane[2] && h <= pane[3], plate: T.importe.box };
  }
  // 8. (v3) the frog's box at coqui.frente (32 wide, 25 rows above its spot) covers no pixel of anything that stands on the counter at cosa_cliente, cosa_a, cosa_b, frasco, papel, taza_abuela
  //    (the preview's stand-ins, with the price tags of the cosa_*), and no pixel of importe (the plate 13 x 9)
  {
    const f = S['coqui.frente'].screen, fb = [f[0] - FROG_BOX.w / 2, f[1] - FROG_BOX.h, FROG_BOX.w, FROG_BOX.h];
    const inBox = (x, y) => x >= fb[0] && x < fb[0] + fb[2] && y >= fb[1] && y < fb[1] + fb[3];
    const seen = {}, rows = [], bad = [];
    for (const l of PVD.counter.layers) {
      const label = l.at + (seen[l.at] ? ' tag' : ''); seen[l.at] = 1;
      const xs = l.px.map(p => p[0]), ys = l.px.map(p => p[1]), box = [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
      const n = l.px.filter(p => inBox(p[0], p[1])).length;
      rows.push([label, l.px.length, box, n]);
      if (n) bad.push(label + ' (' + l.px.length + ' px, box [' + box + ']): the frog\'s box covers ' + n + ' of its pixels');
    }
    const ib = T.importe.box; let nI = 0;
    for (let y = ib[1]; y < ib[1] + ib[3]; y++) for (let x = ib[0]; x < ib[0] + ib[2]; x++) if (inBox(x, y)) nI++;
    rows.push(['importe', ib[2] * ib[3], [ib[0], ib[1], ib[0] + ib[2] - 1, ib[1] + ib[3] - 1], nI]);
    if (nI) bad.push('importe (plate [' + ib + ']): the frog\'s box covers ' + nI + ' of its pixels');
    const gap = r => { const b = r[2]; return Math.max(0, b[0] - (fb[0] + fb[2] - 1), fb[0] - b[2], b[1] - (fb[1] + fb[3] - 1), fb[1] - b[3]); };
    add('frog-clear-of-counter', bad, 'the frog\'s box [' + fb + '] at coqui.frente ' + f + ' covers no pixel of ' + rows.map(r => r[0] + ' (' + r[1] + ' px, ' + gap(r) + ' px clear)').join(', '), ['the frog\'s box [' + fb + '] at coqui.frente ' + f + ':'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 9. (v3) nothing that stands in any moment covers a pixel of importe: no pixel of a sprite of the moment (people, things, tags, held things), not hidden by the set, nearer than the amount window
  //    (its plane deeper than the window's depth), lies on the 13 x 9 plate
  {
    const ib = T.importe.box, vc = S[T.importe.at], bad = [], per = [];
    for (const m of [1, 2, 3, 4]) {
      const d = PVD[m], hits = {};
      let tot = 0;
      for (const l of d.layers) for (const p of l.px) {
        if (p[2]) continue;                                                         // hidden by the set
        if (p[0] < ib[0] || p[0] >= ib[0] + ib[2] || p[1] < ib[1] || p[1] >= ib[1] + ib[3]) continue;
        if (!(p[3] > vc.depth)) continue;                                           // behind the amount window: the plate is drawn over it
        tot++; hits[l.at || 'a sprite'] = (hits[l.at || 'a sprite'] || 0) + 1;
      }
      per.push('m' + m + ' ' + d.layers.length + ' sprites, ' + tot + ' px');
      if (tot) bad.push('moment ' + m + ': ' + Object.entries(hits).map(([k, n]) => n + ' px of the sprite at ' + k).join(', ') + ' cover the plate [' + ib + ']');
    }
    add('importe-clear', bad, 'in the 4 moments no pixel of any sprite that stands there covers importe\'s plate [' + ib + '] (13 x 9, middle on ventana_caja ' + vc.screen + ', depth ' + vc.depth + '): ' + per.join(', '), ['moments:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }
  return OUTS;
}
