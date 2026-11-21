#!/usr/bin/env node
'use strict';
/* La esquina's sheet: writes docs/proyecto/pixel/esquina-sheet.json from esquina-set.html (window.ESQUINA.E, calle-base.js) and the design (the orchestrator's p5-spec, section "esquina"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/esquina-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. It loads the set in headless Chrome, projects every world point with the engine's own project() (pp-engine.js),
   reads the places the set exports (E: the street, the pavements, the door, the pole, the hole, the two cement squares; E.LUZ: the three lamps and the button) and the pixels it draws for
   each part (tags=1), and writes the spots, things, view, shadows and the depth rule, the same as El mostrador's sheet (mostrador-sheet-make.js).
   Things that drive are drawn by the set itself (its autos= parameter): the checks that say "covered by a car or a guagua" read the pixels of the set drawn with them.
   The checks that read the preview's moments (esquina-preview.html, PREVIEW.inspect) work as in El mostrador's and La caja's: the sheet is written first without its checks, the preview reads it,
   and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with ESQUINA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'esquina-sheet.json');
const BASE = process.env.ESQUINA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/esquina-set.html';
const PREV = BASE + '/docs/proyecto/pixel/esquina-preview.html';
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

// the numbers of the spec (p5-spec.md: the top part, and the section "esquina"), as the orchestrator's second pass changed them
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const WIDTH = { coqui: 32, adulto: 24, nino: 24 };       // sprite boxes: frog 32, grown-up 24, child 24 (dog 28: none here); the feet's spot in the middle
const UPDOWN = 12;                                       // two that stand together may overlap sideways only if their feet are this many px apart up-down
const HOLE_MIN = .45;                                    // moment 7: the hole shows at least this share of its pixels (the earth's)
const COVER_OK = 40;                                     // the frog: the pole and a child together may hide this many of his pixels; a grown-up, a car or a guagua none
const NEAR_END = 8.6;                                    // the near pavement runs from the kerb to the park's low wall at y 8.6 (esquina-set.html part muro; not exported in E)
const PW = 240, PH = 216, VW = 196;                      // the picture and the window
// where the spec puts a person on the street (everybody else stays off it): the obrero at his paddle (sale_carro and sale_guagua are on the kerb stone, .1 past the street's edge)
const ON_STREET = ['obrero.paleta'];
const STATES = [];
for (const hora of ['manana', 'tarde']) for (const obra of [0, 1]) for (const puerta of ['shut', 'open']) STATES.push({ hora, obra, puerta });
const qOf = (s, autos) => 'hora=' + s.hora + '&obra=' + s.obra + '&puerta=' + s.puerta + (autos ? '&autos=' + encodeURIComponent(autos) : '');
const AUTOS_49 = 'carro@3.5,4.8,i;guagua@6.7,4.8,i';               // story 49: the traffic stopped in the near lane, one behind the other (alto_carro, alto_guagua)
const AUTOS_48 = 'carro@0.7,4.8,i;guagua@4.5,4.8,i';               // story 48: the car and the guagua at the kerb (para48_carro, para48_guagua)
const BASE_STATE = { hora: 'tarde', obra: 0, puerta: 'shut' };

(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);
  const load = async q => { await page.goto(PAGE + '?tags=1&' + q); };
  // the engine's own projection: [sx, sy, d] for each world point
  const proj = pts => page.evaluate(pts => pts.map(p => { const q = project(p[0], p[1], p[2]); return [q.sx, q.sy, q.d]; }), pts);

  await load(qOf(BASE_STATE));
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(ESQUINA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  const parts = await partBoxes(page, load);
  const veh = await vehicleBoxes(page, load);
  const sheet = await make(G, proj, parts, veh);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const PVD = await previewData(browser, errs);
  const ctx = { G, sheet, PVD, veh, page, load, zc: {} };
  const results = await checks(ctx);
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

/* ---------- the preview's moments: esquina-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]),
   and the silhouettes of the characters as the preview draws them (PREVIEW.sil) ---------- */
async function previewData(browser, errs) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(PREV + '?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const out = { moments: {}, sil: {} };
  for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) out.moments[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m);
  for (const n of ['pepe', 'abuela', 'coqui', 'mama', 'papa', 'luis', 'carmen', 'senora', 'senor', 'obrero', 'obreroSentado']) out.sil[n] = await p.evaluate(n => window.PREVIEW.sil(n), n);
  await p.close();
  return out;
}

/* ---------- what the set drew, by part (tags=1): the pixel box [x0, y0, x1, y1] (inclusive) of each part, in the state with the door shut, obra = 0 ---------- */
async function partBoxes(page, load) {
  await load(qOf({ hora: 'manana', obra: 0, puerta: 'shut' }));
  return page.evaluate(() => {
    const parts = {};
    for (let i = 0; i < TAGS.length; i++) { const t = TAGS[i]; if (!t) continue; const x = i % W, y = (i / W) | 0, p = parts[t] || (parts[t] = [1e9, 1e9, -1, -1, 0]); if (x < p[0]) p[0] = x; if (y < p[1]) p[1] = y; if (x > p[2]) p[2] = x; if (y > p[3]) p[3] = y; p[4]++; }
    return parts;
  });
}

/* ---------- the pixel box of each thing that drives, as the set draws it (autos=kind@x,y,heading; tags=1: part 'auto'): [x0, y0, x1, y1], read from a picture larger than the game's so that nothing is clipped ---------- */
const VEH = {                                            // spot: [what the set draws, x, y, heading]
  para48_carro: ['carro', .7, 4.8, 'i'], para48_guagua: ['guagua', 4.5, 4.8, 'i'], alto_carro: ['carro', 3.5, 4.8, 'i'], alto_guagua: ['guagua', 6.7, 4.8, 'i'],
  'carril_a.carro': ['azul', -.9, 4.8, 'd'], 'carril_b.carro': ['carro', 5.1, 4.8, 'i'], 'carril_b.guagua': ['guagua', 6.3, 4.8, 'i'],
};
const BIG = 'pw=480&ph=320&ox=-90&oy=-60&';                // a picture twice the size with the same OX, OY (150, 100): what the set draws beyond the 240 x 216 picture is seen too
async function vehicleBoxes(page, load) {
  const out = {};
  for (const [name, [k, x, y, h]] of Object.entries(VEH)) {
    await load(BIG + qOf(BASE_STATE, k + '@' + x + ',' + y + ',' + h));
    out[name] = await page.evaluate(() => {
      let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1, n = 0;
      for (let i = 0; i < TAGS.length; i++) if (TAGS[i] === 'auto') { const x = i % W, y = (i / W) | 0; n++; if (x < x0) x0 = x; if (y < y0) y0 = y; if (x > x1) x1 = x; if (y > y1) y1 = y; }
      return { box: [x0, y0, x1, y1], px: n };
    });
  }
  return out;
}

/* ---------- the sheet ---------- */
async function make(G, proj, parts, veh) {
  const E = G.E, LUZ = E.LUZ;
  const P1 = async p => (await proj([p]))[0];
  const scr = ([sx, sy]) => [Math.round(sx), Math.round(sy)];

  /* ---- spots: the pavement (or the street, or the bucket's top) under the feet; frog scale 1 everywhere ---- */
  const D = [];                                                                       // [name, world, kind, who, what, extra]
  const add = (name, w, kind, who, what, extra) => D.push([name, w, kind, who, what, extra || {}]);
  const person = (name, w, who, what, extra) => add(name, w, who === 'coqui' ? 'frog' : 'person', who, what, extra);
  const car = (name, w, sprite, heading, what) => add(name, w, 'vehicle', null, what, { sprite, heading });
  // the colmado's pavement
  person('puerta', [-1.85, .35, 0], 'adulto', 'at the colmado\'s door, in front of it: abuela coming out (story 49 opening, before the group is there: an alternative of pepe.puerta)');
  person('pepe.puerta', [-1.85, .3, 0], 'adulto', 'don Pepe at the colmado\'s door with his broom (story 49; an alternative of puerta)');
  person('esquina', [.5, 1.25, 0], 'coqui', 'the frog at the corner, always (story 49; there is no esquina2)');
  person('boton_coqui', [1.1, 1.2, 0], 'coqui', 'the frog while he presses the button on the pole (the pole may hide him: he is pressing its button)');
  add('boton', [LUZ.button.x, LUZ.button.y, LUZ.button.z], 'point', null, 'the button on the pole: E.LUZ.button (the red disc on the yellow box, at frog height)');
  person('bordillo1', [-1.1, 1.35, 0], 'adulto', 'at the kerb, the first of the two (story 49: in the opening la señora; in the game one of la señora, el señor, Luis, Carmen)');
  person('bordillo2', [-2.7, 1.35, 0], 'nino', 'at the kerb, the second (story 49: in the opening Luis, the child in front)');
  person('fondo1', [-.3, .45, 0], 'nino', 'behind the kerb row, right: Carmen in the opening of story 49');
  person('fondo2', [-3.4, .5, 0], 'adulto', 'behind the kerb row, left: el señor in the opening of story 49 (the grown-up behind)');
  add('vuelta', [.8, -2.2, 0], 'person', 'adulto', 'where somebody who goes round the corner leaves the picture (an exit: only its point has to be in the window); he walks along the pavement to (0.8, 0.2, 0), then up the side wall to here', { exit: true, path: [[.8, .2, 0], [.8, -2.2, 0]] });
  // the near pavement: a back row at y 6.5 and a front row at y 7.9
  [[.5, 6.5, 'adulto', 'back row 1: papá or mamá (stories 48 and 49: mamá with the bebé on her arm: enfrente)'], [2.1, 6.5, 'adulto', 'back row 2: abuela with the bebé on her arm (story 48), the one who crossed (story 49: cruce_fin), abuela (the ending of story 49)'],
    [3.7, 6.5, 'adulto', 'back row 3: mamá or papá (the end of story 48)'], [5.3, 6.5, 'nino', 'back row 4: Luis with his bicycle (story 48)'],
    [2.4, 7.9, 'coqui', 'front row 5: the frog (the start of story 48, the ending of story 49)'], [4.0, 7.9, 'nino', 'front row 6: Luis (story 50)']].forEach(([x, y, who, what], i) => person('acera' + (i + 1), [x, y, 0], who, what));
  person('enfrente', [.5, 6.5, 0], 'adulto', 'mamá, with the bebé on her arm, on the near pavement (story 49): the same place as acera1', { alias: 'acera1' });
  person('cruce_fin', [2.1, 6.5, 0], 'adulto', 'where somebody who crossed ends and waves (story 49): the same place as acera2', { alias: 'acera2' });
  // what drives, and who gets out of it (story 48: both in the near lane, one behind the other)
  car('para48_carro', [.7, 4.8, 0], 'carro', 'i', 'story 48: where the car stops, the middle of its floor, in the near lane, heading to -x');
  car('para48_guagua', [4.5, 4.8, 0], 'guagua', 'i', 'story 48: where the guagua stops, the middle of its floor, in the near lane behind the car, heading to -x');
  person('sale_carro', [.7, 5.9, 0], 'adulto', 'where somebody gets out of the car (mamá, papá), on the kerb stone beside it; he walks to acera3 (mamá) or acera1 (papá)');
  person('sale_guagua', [3.05, 5.9, 0], 'adulto', 'where somebody gets out of the guagua (its front door), on the kerb stone beside it; he walks to acera3 (mamá) or acera1 (papá)');
  person('toca_carro', [1.3, 6.05, 0], 'coqui', 'the frog knocks at the car, on the near pavement beside the kerb');
  person('toca_guagua', [3.6, 6.05, 0], 'coqui', 'the frog knocks at the guagua, on the near pavement beside the kerb');
  car('alto_carro', [3.5, 4.8, 0], 'carro', 'i', 'story 49: where the car stops at the stop line, the middle of its floor, in the near lane, heading to -x (its front at x 2.4, the stop line at x 2.2); the guagua stops behind it');
  car('alto_guagua', [6.7, 4.8, 0], 'guagua', 'i', 'story 49: where the guagua stops, the middle of its floor, in the near lane behind the car, heading to -x (its front at x 4.5)');
  // story 50
  car('carril_a.carro', [-.9, 4.8, 0], 'azul', 'd', 'carril_a, the left end of the one lane (the near lane): a car\'s middle, heading to +x; the guagua never waits here');
  car('carril_a.bici', [-.5, 4.8, 0], 'bici', 'd', 'carril_a: a bicycle\'s middle, heading to +x (an alternative of the car; the set has no bicycle: a sprite)');
  car('carril_b.carro', [5.1, 4.8, 0], 'carro', 'i', 'carril_b, the right end of the one lane: a car\'s middle, heading to -x');
  car('carril_b.guagua', [6.3, 4.8, 0], 'guagua', 'i', 'carril_b: the guagua\'s middle, heading to -x');
  car('carril_b.bici', [4.5, 4.8, 0], 'bici', 'i', 'carril_b: a bicycle\'s middle, heading to -x (the set has no bicycle: a sprite)');
  person('obrero.paleta', [3.2, 3.6, 0], 'adulto', 'the obrero at the lane with his paddle, on the street at the hole\'s right end', { street: true });
  person('obrero.cubo', [5.3, 6.5, .3], 'adulto', 'the obrero sitting on his bucket (a sprite; its top is z .3); the sitting sprite is anchored by his lap row on the spot\'s row (rules.anchor)', { seated: true });
  person('coqui.cerca', [3.1, 6.1, 0], 'coqui', 'story 50: the frog near the cement, on the pavement right of the wet square');
  person('coqui.cemento', [1.7, 6.6, 0], 'coqui', 'the frog on the wet square (the ending of story 50)');
  person('luis.cemento', [.5, 6.5, 0], 'nino', 'Luis kneeling behind and left of the frog, on the old dry square (the ending of story 50; the preview\'s stand-in is the sitting persona)');
  person('obrero.fin', [3.9, 6.5, 0], 'adulto', 'the obrero standing in the ending of story 50');
  [[1.1, 6.05], [2.3, 6.05], [2.35, 7.15]].forEach(([x, y], i) => add('cono' + (i + 1), [x, y, 0], 'small', null, 'a cone round the wet square (a sprite)' + (i === 1 ? '; the one that is knocked over (in a wrong move, and in the ending of story 50)' : '')));
  LUZ.lamps.forEach((l, i) => add('lamps.' + (i + 1), [l.x, l.y, l.z], 'point', null, 'a lamp of the traffic light, from E.LUZ.lamps, top to bottom: ' + ['red', 'amber', 'green'][i] + '; the lit lamp is a sprite', { lamp: ['red', 'amber', 'green'][i] }));

  const pr = await proj(D.map(d => d[1]));
  const spots = {};
  D.forEach((d, i) => {
    const q = pr[i], s = { world: W4(d[1]), screen: scr(q), depth: r4(q[2]), scale: 1, kind: d[2] };
    if (d[3]) s.who = d[3];
    s.what = d[4];
    Object.assign(s, d[5]);
    if (veh[d[0]]) { s.drawn = veh[d[0]].box; s.drawn_px = veh[d[0]].px; }
    spots[d[0]] = s;
  });
  spots['vuelta'].path = spots['vuelta'].path.map(w => ({ world: w, screen: scr3(G, ...w) }));
  // the routes of what passes: they begin and end outside the picture
  const routes = { trafico: { what: 'traffic passing along street A: it enters at the right and leaves at the left, in its lane; in story 49 it stops at the stop line at alto_carro and alto_guagua. These points are outside the picture on purpose: they are exits, where a sprite enters and leaves, not spots', lanes: {} } };
  for (const [lane, y] of [['lejos', E.LANE1], ['cerca', E.LANE2]]) routes.trafico.lanes[lane] = { entra: { world: [9.5, y, 0], screen: scr3(G, 9.5, y, 0) }, sale: { world: [-6, y, 0], screen: scr3(G, -6, y, 0) } };

  /* ---- the view: chosen from the spots' sprite boxes (the columns the spec's widths give, and the pixels the set draws for a vehicle) ---- */
  const cols = {};
  for (const [k, s] of Object.entries(spots)) {
    const sx = s.screen[0];
    if (s.kind === 'vehicle' && s.drawn) cols[k] = [s.drawn[0], s.drawn[2]];
    else if (s.exit) cols[k] = [sx, sx];
    else if (s.who && WIDTH[s.who]) cols[k] = [sx - WIDTH[s.who] / 2, sx + WIDTH[s.who] / 2 - 1];
    else cols[k] = [sx, sx];
  }
  const tryX0 = x0 => {
    let out = 0, cutN = 0, cutPx = 0;
    for (const [k, s] of Object.entries(spots)) {
      if (s.screen[0] < x0 || s.screen[0] >= x0 + VW) out++;
      // a cut that counts: a person's at either side, a car's or guagua's at the left (at the right of the picture it may be cut: reported, not a failure)
      const c = cols[k], cut = Math.max(0, x0 - c[0]) + (s.kind === 'vehicle' ? 0 : Math.max(0, c[1] - (x0 + VW - 1)));
      if (cut > 0) { cutN++; cutPx += cut; }
    }
    return { x0, out, cutN, cutPx };
  };
  const tries = []; for (let x0 = 0; x0 <= PW - VW; x0++) tries.push(tryX0(x0));
  const sorted = tries.slice().sort((a, b) => a.out - b.out || a.cutN - b.cutN || a.cutPx - b.cutPx || a.x0 - b.x0);
  const tied = sorted.filter(t => t.out === sorted[0].out && t.cutN === sorted[0].cutN && t.cutPx === sorted[0].cutPx), best = tied[(tied.length - 1) >> 1];   // the middle of the x0 that tie: the most room on both sides
  const feasible = tries.filter(t => t.out === 0).map(t => t.x0);
  const x0 = best.x0;
  const midY = (E.S0 + E.S1) / 2, cx = x0 + VW / 2, vx = midY + (cx - G.OX) / G.S * R2;           // the ground point on the street's middle line whose column is the window's middle
  const vq = await P1([vx, midY, 0]), vs = [r2(vq[0]), r2(vq[1])];
  if (Math.max(0, Math.min(PW - VW, Math.round(vs[0] - 98))) !== x0) throw new Error('the view point does not give x0 ' + x0);
  const views = { wide: { world: W4([vx, midY, 0]), screen: vs, zoom: 1, x0, region: [x0, 0, VW, PH],
    what: 'the one view: the 196 x 216 window over the 240 x 216 picture, centred on this point (on the street\'s middle line y ' + midY + '), x0 = clamp(round(sx - 98), 0, 44). x0 ' + x0 + ' is the one that keeps every spot\'s point inside the window (x0 ' + (feasible.length ? feasible[0] + ' to ' + feasible[feasible.length - 1] : 'none') + ' do) with the fewest sprites cut (x0 ' + tied[0].x0 + ' to ' + tied[tied.length - 1].x0 + ' tie; this is their middle): ' + best.cutN + ' cut, ' + best.cutPx + ' px in all; see the check spots-in-view for which and by how much',
    choice: { feasible: feasible.length ? [feasible[0], feasible[feasible.length - 1]] : null, rule: 'every spot\'s point inside the window (vuelta and the traffic\'s entries and exits are exits: the point only); then the fewest spots whose sprite box is cut (a car\'s or a guagua\'s at the right or the bottom does not count); then the fewest px cut; then the middle of the x0 that still tie (' + tied[0].x0 + ' to ' + tied[tied.length - 1].x0 + ': the most room at both sides)', table: tries.filter(t => t.out === 0).map(t => [t.x0, t.cutN, t.cutPx]) } } };

  /* ---- things he can touch ---- */
  const boxOf = async (w, clip) => {
    const cs = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) cs.push([x, y, z]);
    const q = await proj(cs), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    let x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)), x1 = Math.ceil(Math.max(...xs)), y1 = Math.ceil(Math.max(...ys));
    if (clip) { x0 = Math.max(0, x0); y0 = Math.max(0, y0); x1 = Math.min(PW, x1); y1 = Math.min(PH, y1); }
    return [x0, y0, x1 - x0, y1 - y0];
  };
  const T = async (world, what, extra = {}, clip = false) => Object.assign({ set: true, world: W4(world), box: await boxOf(world, clip), what }, extra);
  const pole = E.POLE, un = (...ns) => { const b = [1e9, 1e9, -1, -1]; for (const n of ns) { const p = parts[n]; b[0] = Math.min(b[0], p[0]); b[1] = Math.min(b[1], p[1]); b[2] = Math.max(b[2], p[2]); b[3] = Math.max(b[3], p[3]); } return b; };
  const cb = un('colmado', 'puerta', 'vitrina');
  const things = {
    colmado: { set: true, world: [-10, -9, 0, 0, 0, E.WH], box: [cb[0], cb[1], cb[2] - cb[0] + 1, cb[3] - cb[1] + 1], what: 'the building: the screen box of the pixels the set draws for the parts colmado, puerta and vitrina (its front wall, its top, the side wall, the door, the shop window and its awning); its world box is the block x -10 to 0, y -9 to 0, up to E.WH. It runs off the picture at the left and at the top: a touch on the door (puerta) wins over it' },
    puerta: await T([E.D0, 0, 0, E.D1, .02, E.DH], 'the colmado\'s door, a poke (the doorway, in either state of the door)'),
    boton: await T([pole[0] - .12, pole[1] + .02, .62, pole[0] + .12, pole[1] + .16, .98], 'the button box on the pole (the yellow box with the red button, the pole\'s box(x - .12, y + .02, .62, x + .12, y + .16, .98) of calle-base.js trafficLight): where he touches to press'),
    calle: await T([-9, E.S0, 0, 9, E.S1, 0], 'the street\'s asphalt, the whole of street A from the colmado\'s kerb to the near kerb, as far as the set builds it (x -9 to 9); with obra = 1 the hole is part of it', {}, true),
    esquina: await T([0, 0, 0, E.P, E.P, 0], 'the corner: the colmado\'s pavement from x 0 to ' + E.P + ' (y 0 to ' + E.P + '), where the pole stands'),
    cemento: await T([E.WET[0], E.WET[1], 0, E.WET[2], E.WET[3], 0], 'the wet square of cement (obra = 1), the one with three cones round it', { when: 'obra = 1' }),
  };
  for (const k of ['gente', 'carro', 'azul', 'guagua', 'bicicleta', 'abuela', 'bebe', 'mama', 'papa', 'luis', 'carmen', 'senora', 'senor', 'pepe', 'obrero', 'coqui']) things[k] = 'sprite';

  const groups = { grupo: ['bordillo1', 'bordillo2', 'fondo1', 'fondo2'], bordillo: ['bordillo1', 'bordillo2'], fila_atras: ['acera1', 'acera2', 'acera3', 'acera4'], fila_delante: ['acera5', 'acera6'], lamps: ['lamps.1', 'lamps.2', 'lamps.3'], conos: ['cono1', 'cono2', 'cono3'] };
  const sc = G.scene;
  return {
    scene: 'esquina',
    made: 'node docs/proyecto/pixel/esquina-sheet-make.js, from esquina-set.html (window.ESQUINA.E, calle-base.js) and the design of La esquina (the orchestrator\'s p5-spec). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [VW, PH],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX, OY = H / 2 + originY (here OX ' + G.OX + ', OY ' + G.OY + '). That is sx = OX + (x - y) * 18.38, sy = OY + (x + y) * 9.19 - z * 22.5. A box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)] (clipped to the picture where the thing says so). screen is the projection rounded to whole pixels. The colmado\'s front wall is y = 0 (it faces +y); its pavement runs y 0 to ' + E.P + ', the street A from y ' + E.S0 + ' to ' + E.S1 + ' (lanes at y ' + E.LANE1 + ' far, ' + E.LANE2 + ' near), the near pavement from y ' + (E.S1 + E.K) + ' to ' + NEAR_END,
      spot: 'a spot is a world point of the feet (z 0: the pavement or the street; z .3: the top of the obrero\'s bucket) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). scale is the frog\'s: 1 everywhere. A thing that drives: its spot is the middle of its floor',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing (a 56-row canvas whose lowest row is empty: the lowest drawn row is 54); abuela standing mkAbuela (48 x 51): column 30, drawn rows 0 to 49; the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (so row 25 of the canvas is on sy); the obrero sitting on his bucket (obrero.cubo): the sitting persona (mkPersona with sent = 1), column 24 and the row of his hips, 38, on (sx, sy), the spot being the bucket\'s top (as abuela sitting in El mostrador: lap row on the spot); the bebé on an arm is a part of the carrier\'s sprite; a cone, the bucket, a bicycle: its bottom middle on the point; a car, a guagua: the pixels the set draws for it (its autos= parameter), the spot being the middle of its floor (spots[name].drawn is their screen box)',
      view: 'a view has a zoom (here 1: the 196 x 216 window over the 240 x 216 picture) and x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character. The cars and the guagua are baked into the set (autos=), so the same rule puts them in front of a person standing behind them',
      nearest: 'the make\'s lines "nearest passing": where a number of the spec fails a check, the least move of one spot along x or y (steps of .01, up to 3, either way, staying on its own strip: the colmado\'s pavement y .1 to ' + E.P + ', the street y ' + E.S0 + ' to ' + E.S1 + ', the near pavement y ' + E.S1 + ' to ' + NEAR_END + ') that passes it. The spec\'s numbers are kept in the sheet',
      widths: 'the sprite boxes the checks use: the frog ' + WIDTH.coqui + ' wide, a grown-up ' + WIDTH.adulto + ', a child ' + WIDTH.nino + ' (the spec; the dog\'s 28 is not used here), the feet\'s spot in the middle of the bottom edge; a car or a guagua is the pixels the set draws; a cone, a bicycle, a lamp, the button: the point only (the spec gives no size)',
    },
    setKey: {
      params: { hora: { values: ['manana', 'tarde'] }, obra: { values: [0, 1], note: 'the dug-up far lane with its cones, no stripes, and the two squares of cement in the near pavement (story 50)' }, puerta: { values: ['shut', 'open'], note: 'the colmado\'s door; the set\'s default is shut' }, autos: { note: 'for the readers\' renders and the preview only: "kind@x,y,heading" joined by ";" (carro, azul, guagua; i = to -x, d = to +x). In the game things that drive are sprites and the baked sets have none' }, t: { note: 'wind time, 0 for the reference' } },
      key: 'hora + obra + puerta, e.g. "manana-0-shut"',
      baked: ['manana', 'tarde'].flatMap(h => [0, 1].flatMap(o => ['shut', 'open'].map(p => '?hora=' + h + '&obra=' + o + '&puerta=' + p))),
    },
    things,
    spots,
    groups,
    alternatives: {
      groups: [['puerta', 'pepe.puerta'], ['esquina', 'boton_coqui'], ['sale_carro', 'sale_guagua'], ['toca_carro', 'toca_guagua'], ['para48_carro', 'alto_carro'], ['para48_guagua', 'alto_guagua'], ['carril_a.carro', 'carril_a.bici'], ['carril_b.carro', 'carril_b.guagua', 'carril_b.bici']],
      vsGroup: {},
      aliases: { enfrente: 'acera1', cruce_fin: 'acera2' },
      what: 'spots that are never in the same picture: each list is alternatives of each other (puerta and pepe.puerta: abuela comes out before the group is there; esquina and boton_coqui: the frog stands at one or the other; the cars of story 48 and of story 49; the car, the guagua and the bicycle of one end of the lane). aliases: enfrente is the place acera1, cruce_fin the place acera2 (the spec\'s own names for them)',
    },
    routes,
    notes: [
      'second pass: the spots are the orchestrator\'s new ones (the near pavement now runs to y ' + NEAR_END + ', the park\'s wall); cola1 to cola4, esquina2, abuela.acera, coqui.acera, luis.bici, junto, papa.acera, abuela.enfrente, coqui.enfrente, para_carro, para_guagua and luis.obra are gone',
      'things.gente is a sprite key (the spec gives no box): the people at the kerb, who are the members of the group grupo (bordillo1, bordillo2, fondo1, fondo2) in the opening of story 49 and of the group bordillo in its game',
      'the section of the spec for La esquina has no "step until" rule: every number in it is kept as given, and where it fails a check the make says so and gives the nearest value that passes (rules.nearest)',
      'the preview gives moments 1 to 6 the afternoon and 7 and 8 the morning (the scripts\' hours), the door shut in all; obra = 1 in 7 and 8; the middle cone is knocked over in moment 8',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3), so the colmado\'s wall hides nobody who stands in front of it, and a car or a guagua baked into the set (autos=) hides whoever stands behind it.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet, as El mostrador\'s front; the same test for people and small things',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias',
    },
    shadows: {
      radius: { coqui: .45, adulto: .35, nino: .28, cono: .16 },
      byCharacter: { coqui: .45, pepe: .35, abuela: .35, mama: .35, papa: .35, senora: .35, senor: .35, obrero: .35, luis: .28, carmen: .28, cono: .16 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the ground (z 0); the cones .16 as the set\'s own cones (calle-base.js cone)',
      none: ['obrero.cubo'],
      onBucket: 'the obrero sitting on his bucket (z .3) casts none: the rule casts only for z 0, and the bucket is a sprite',
    },
  };
}

// the screen point of a world point on this sheet (the same arithmetic as pp-engine.js project, rounded to a pixel)
const scr3 = (G, x, y, z) => [Math.round(G.OX + (x - y) / R2 * G.S), Math.round(G.OY + ((x + y) / R2 * .5 - z * COS) * G.S)];
const dep3 = (x, y, z) => (x + y) / R2 * COS + z * .5;

/* ---------- the checks ---------- */
async function checks(ctx) {
  const { G, sheet, PVD, veh } = ctx, S = sheet.spots, T = sheet.things, V = sheet.views.wide, [x0] = V.region, OUTS = [];
  const add = (name, bad, okLine, failLines) => OUTS.push({ name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] });
  const SIL = PVD.sil;
  const inWin = (x, y) => x >= x0 && x < x0 + VW && y >= 0 && y < PH;
  const here = (name, who) => ({ name, who, sx: S[name].screen[0], sy: S[name].screen[1], d: S[name].depth, world: S[name].world });
  // the set's depth and part tags in a state (with the autos it is asked for), as the preview draws it
  const zOf = async (state, autos = state.autos) => {
    const q = qOf(state, autos);
    if (!ctx.zc[q]) { await ctx.load(q); const r = await ctx.page.evaluate(() => ({ Z: Array.from(DEPTH.z), T: TAGS })); ctx.zc[q] = { Z: Float32Array.from(r.Z), T: r.T }; }
    return ctx.zc[q];
  };
  // a sprite's pixels (rel: flat dx, dy from the spot's column and row) at a screen point and depth: how many the set hides by the depth rule, by which part
  const hiddenBy = (zt, rel, sx, sy, d) => {
    let tot = 0, hid = 0; const by = {};
    for (let k = 0; k < rel.length; k += 2) {
      const X = sx + rel[k], Y = sy + rel[k + 1]; if (X < 0 || X >= PW || Y < 0 || Y >= PH) continue;
      tot++; const i = Y * PW + X, plane = d + (sy - (Y + .5)) * T30 / G.S;
      if (zt.Z[i] > plane + BIAS) { hid++; const t = zt.T[i] || 'ground'; by[t] = (by[t] || 0) + 1; }
    }
    return { tot, hid, by };
  };
  const byText = by => Object.entries(by).map(([t, n]) => n + ' by ' + t).join(', ');
  // the nearest place along x or y of a spot's world point (steps of .01, up to 3) where ok(screen x, screen y, depth) holds: for a failure's report only: the spec's number is kept
  // the spot stays on its own strip: the colmado's pavement (y .1 to E.P), the street (y E.S0 to E.S1), the near pavement (y E.S1 to NEAR_END), and inside the picture
  const E_ = G.E, zone = w => w[1] < E_.S0 ? [.1, E_.P] : w[1] > E_.S1 ? [E_.S1, NEAR_END] : [E_.S0, E_.S1];
  const nearestPass = (spot, ok) => {
    const w = S[spot].world, zn = zone(w);
    for (let k = 1; k <= 300; k++) {
      const hits = [];
      for (const ax of [0, 1]) for (const sg of [-1, 1]) { const q = w.slice(); q[ax] = r4(q[ax] + sg * k * .01); if (q[1] < zn[0] || q[1] > zn[1]) continue; const [sx, sy] = scr3(G, ...q); if (sx < 0 || sx >= PW || sy < 0 || sy >= PH) continue; if (ok(sx, sy, dep3(...q), q)) hits.push((ax ? 'y ' : 'x ') + w[ax] + ' -> ' + q[ax] + ' (' + (sg > 0 ? '+' : '-') + r2(k * .01) + ')'); }
      if (hits.length) return hits.join(' or ');
    }
    return 'none within 3';
  };
  // the sprite of each spot: the stand-in the preview draws there (for its rows and its silhouette)
  const SILOF = { puerta: 'abuela', 'pepe.puerta': 'pepe', esquina: 'coqui', boton_coqui: 'coqui', bordillo1: 'senora', bordillo2: 'luis', fondo1: 'carmen', fondo2: 'senor', vuelta: 'senor',
    acera1: 'mama', acera2: 'abuela', acera3: 'mama', acera4: 'luis', acera5: 'coqui', acera6: 'luis', enfrente: 'mama', cruce_fin: 'abuela', sale_carro: 'mama', sale_guagua: 'mama', toca_carro: 'coqui', toca_guagua: 'coqui',
    'obrero.paleta': 'obrero', 'obrero.cubo': 'obreroSentado', 'coqui.cerca': 'coqui', 'coqui.cemento': 'coqui', 'luis.cemento': 'luis', 'obrero.fin': 'obrero' };

  // 1. every spot's point is inside the picture and inside the window, and its sprite is whole: the columns of the spec's width (a car or a guagua: the pixels the set draws; a cone, a bicycle, a lamp, the button: the point
  //    only) and the rows of the stand-in's silhouette; what is cut is reported by how many pixels. Not failures: a car's or a guagua's sprite cut by the window at the picture's right or bottom, and vuelta (an exit: only its point)
  {
    const bad = [], cut = [], rows = [], allowed = [];
    const entries = Object.entries(S);
    for (const [k, s] of entries) {
      const [sx, sy] = s.screen;
      if (sx < 0 || sx >= PW || sy < 0 || sy >= PH) { bad.push(k + ' ' + s.screen + ' outside the picture'); continue; }
      if (!inWin(sx, sy)) bad.push(k + ' ' + s.screen + ' outside the window [' + x0 + ', ' + (x0 + VW) + ') x [0, ' + PH + ')');
      let c = [sx, sx], r = [sy, sy];
      const veh = s.kind === 'vehicle' && s.drawn;
      if (veh) { c = [s.drawn[0], s.drawn[2]]; r = [s.drawn[1], s.drawn[3]]; }
      else if (s.who && WIDTH[s.who]) { c = [sx - WIDTH[s.who] / 2, sx + WIDTH[s.who] / 2 - 1]; const b = SIL[SILOF[k] || (s.who === 'coqui' ? 'coqui' : s.who === 'nino' ? 'luis' : 'pepe')].box; r = [sy + b[1], sy + b[3]]; }
      const left = Math.max(0, x0 - c[0]), right = Math.max(0, c[1] - (x0 + VW - 1)), top = Math.max(0, -r[0]), bottom = Math.max(0, r[1] - (PH - 1));
      const txt = (a, b, an, bn) => (a ? a + ' ' + an : '') + (a && b ? ', ' : '') + (b ? b + ' ' + bn : '');
      if (s.exit) { const sc = SIL[SILOF[k]], cl = Math.max(0, x0 - (sx + sc.box[0])), cr = Math.max(0, sx + sc.box[2] - (x0 + VW - 1)); if (cl || cr) allowed.push(k + ' ' + s.screen + ' is an exit, only its point has to be inside; the stand-in sprite would be cut by ' + txt(cl, cr, 'px at the left', 'px at the right')); continue; }
      if (left || (right && !veh)) cut.push(k + ' (' + (s.who || s.kind) + ') ' + s.screen + ': sprite cut by the window: ' + txt(left, veh ? 0 : right, 'px at the left', 'px at the right'));
      if (veh && right) allowed.push(k + ' (vehicle) ' + s.screen + ': cut by the window ' + right + ' px at the right (its drawn pixels reach column ' + c[1] + ', the window ends at ' + (x0 + VW - 1) + ')');
      if (top || (bottom && !veh)) rows.push(k + ' ' + s.screen + ': sprite cut by the picture: ' + txt(top, veh ? 0 : bottom, 'rows at the top', 'rows at the bottom'));
      if (veh && bottom) allowed.push(k + ' (vehicle) ' + s.screen + ': cut by the picture ' + bottom + ' rows at the bottom (its drawn pixels reach row ' + r[1] + ', the picture ends at ' + (PH - 1) + ')');
    }
    bad.push(...cut, ...rows);
    const ch = V.choice;
    add('spots-in-view', bad, entries.length + ' spots: every point inside the ' + sheet.picture.join(' x ') + ' picture and the window [' + x0 + ', ' + (x0 + VW) + ') x [0, ' + PH + ') and every sprite whole (a vehicle may be cut at the right and the bottom of the picture, vuelta is an exit: ' + allowed.length + ' such cut(s), below)',
      [bad.length + ' finding(s) (window x0 ' + x0 + '; every spot point is ' + (ch.feasible ? 'inside for x0 ' + ch.feasible[0] + ' to ' + ch.feasible[1] : 'inside for no x0') + '; ' + (cut.length + rows.length) + ' sprite(s) cut):'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].x0 = x0;
    for (const a of allowed) OUTS[OUTS.length - 1].lines.push('       not a failure: ' + a);
    // for each x0 that keeps every point inside: the sprites it cuts
    const tab = ch.table.map(([a, n, p]) => 'x0 ' + a + ': ' + n + ' sprite(s), ' + p + ' px').join('; ');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the x0 that keep every spot point inside, with the sprites each cuts that count (columns only: the spec\'s widths and the car\'s and the guagua\'s drawn pixels): ' + tab);
    // the stand-in sprites' own drawn pixels (not the spec's boxes) that the window cuts, for the people spots
    const real = [];
    for (const [k, s] of entries) { const n = SILOF[k]; if (!n || s.exit) continue; const r = SIL[n].rel; let l = 0, rr = 0; for (let i = 0; i < r.length; i += 2) { const X = s.screen[0] + r[i]; if (X < x0) l++; else if (X > x0 + VW - 1) rr++; } if (l || rr) real.push(k + ' ' + (l ? l + ' px at the left' : '') + (l && rr ? ', ' : '') + (rr ? rr + ' px at the right' : '')); }
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the pixels the stand-in people actually draw that the window cuts (the check above uses the spec\'s widths): ' + (real.join('; ') || 'none'));
    const ppl = Object.entries(S).filter(([, s]) => s.who && WIDTH[s.who] && !s.exit).map(([k, s]) => [k, s.screen[0] - WIDTH[s.who] / 2, s.screen[0] + WIDTH[s.who] / 2 - 1]);
    const L0 = ppl.slice().sort((a, b) => a[1] - b[1])[0], R0 = ppl.slice().sort((a, b) => b[2] - a[2])[0];
    OUTS[OUTS.length - 1].lines.push('       info, not a check: the people sprites (the frog and the grown-ups and children, not vuelta nor the vehicles) span columns ' + L0[1] + ' (' + L0[0] + ') to ' + R0[2] + ' (' + R0[0] + '): ' + (R0[2] - L0[1] + 1) + ' px, the window is ' + VW + ' wide' + (R0[2] - L0[1] + 1 > VW ? ', so no window holds them all whole' : ''));
  }

  // 2. sprites-apart: for every pair that stands together in a moment of the preview (the people and the frog: the layers with a character kind), the two sprite boxes (the frog 32 wide, a grown-up 24, a child 24,
  //    the feet's spot in the middle) do not overlap sideways, unless their feet are UPDOWN px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) {
      const L = PVD.moments[m].layers.filter(l => l.who && WIDTH[l.who]);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + L.map(l => l.at).join(', ') + ')');
    }
    add('sprites-apart', bad, all.length + ' pairs in the 8 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down (the frog ' + WIDTH.coqui + ' wide, grown-up ' + WIDTH.adulto + ', child ' + WIDTH.nino + '); the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' px across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down:'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) {                                                           // the nearest spot value that would pass (the spec's numbers are kept)
      const pass = other => (sx, sy) => Math.abs(sx - other.sx) >= h.half || Math.abs(sy - other.sy) >= UPDOWN;
      OUTS[OUTS.length - 1].lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].world + ': ' + nearestPass(h.a.at, pass(h.b)) + '; or ' + h.b.at + ' ' + S[h.b.at].world + ': ' + nearestPass(h.b.at, pass(h.a)));
    }
    OUTS[OUTS.length - 1].lines.push('       closest in each moment (px across / px down): ' + [1, 2, 3, 4, 5, 6, 7, 8].map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    // the pairs the scripts put together that no preview moment shows (not a check: the spec's check reads the moments)
    const TOG = [['sale_carro', 'toca_carro'], ['sale_guagua', 'toca_guagua']];
    OUTS[OUTS.length - 1].lines.push('       info, not a check: pairs of spots the scripts put together but no moment shows (px across / px down; the boxes need 28 across for a grown-up and the frog, 24 for two grown-ups, or 12 down): ' + TOG.map(([a, b]) => a + ' ~ ' + b + ' ' + Math.abs(S[a].screen[0] - S[b].screen[0]) + '/' + Math.abs(S[a].screen[1] - S[b].screen[1])).join('; '));
    OUTS[OUTS.length - 1].pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 3. the frog is never behind a grown-up, a car or a guagua: in every moment of the preview none of his drawn pixels is hidden by a pixel of a car or a guagua (part auto of the set) or by a nearer grown-up sprite.
  //    The pole and a child (and any other thing: a cone, the bucket) may hide up to COVER_OK of his pixels together; they are reported
  {
    const bad = [], lines = [], res = [];
    const classify = (zt, L, own, fi, rel, sx, sy, d) => {
      const r = { drawn: 0, car: 0, grown: 0, soft: 0, by: {} }, note = k => { r.by[k] = (r.by[k] || 0) + 1; };
      for (let k = 0; k < rel.length; k += 2) {
        const X = sx + rel[k], Y = sy + rel[k + 1]; if (X < 0 || X >= PW || Y < 0 || Y >= PH) continue;
        r.drawn++; const i = Y * PW + X, plane = d + (sy - (Y + .5)) * T30 / G.S;
        if (zt.Z[i] > plane + BIAS) { const t = zt.T[i] || 'ground'; if (t === 'auto') { r.car++; note('car or guagua'); } else { r.soft++; note(t === 'semaforo' ? 'the pole' : 'set part ' + t); } continue; }
        const o = own.get(i);
        if (o && (o.plane > plane || (o.plane === plane && o.idx > fi))) { const lw = L[o.idx]; if (lw.who === 'adulto') { r.grown++; note('grown-up at ' + lw.at); } else { r.soft++; note((lw.who === 'nino' ? 'child at ' : 'thing at ') + lw.at); } }
      }
      r.ok = r.car === 0 && r.grown === 0 && r.soft <= COVER_OK;
      return r;
    };
    for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) {
      const M = PVD.moments[m], L = M.layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi];
      const zt = await zOf(M.set), own = ownerMap(L, fi), r = classify(zt, L, own, fi, relOf(f), f.sx, f.sy, f.d);
      // by which of the cars: the set drawn with each vehicle alone
      const perCar = {};
      if (r.car && M.set.autos) for (const a of M.set.autos.split(';')) { const z1 = await zOf(Object.assign({}, M.set), a), hb = hiddenBy(z1, relOf(f), f.sx, f.sy, f.d); if (hb.by.auto) perCar[a.split('@')[0] + ' at ' + a.split('@')[1].split(',').slice(0, 2).join(',')] = hb.by.auto; }
      const line = 'moment ' + m + ' the frog at ' + f.at + ' [' + f.sx + ',' + f.sy + ']: ' + r.drawn + ' px drawn; hidden by a car or a guagua ' + r.car + (r.car && Object.keys(perCar).length ? ' (' + Object.entries(perCar).map(([k, n]) => n + ' by ' + k).join(', ') + ')' : '') + ', by a grown-up ' + r.grown + ', by the pole, a child or other things ' + r.soft + ' of the ' + COVER_OK + ' allowed' + (Object.keys(r.by).length ? ' (' + byText(r.by) + ')' : '');
      lines.push(line); res.push({ moment: m, at: f.at, drawn: r.drawn, car: r.car, grownUp: r.grown, poleChildOther: r.soft, by: r.by, ok: r.ok });
      if (!r.ok) bad.push(line);
    }
    add('frog-seen', bad, 'in all 8 moments of the preview no car, guagua or grown-up hides any pixel of the frog, and the pole and the children together hide at most ' + COVER_OK + ' of them: ' + res.map(r => 'm' + r.moment + ' ' + r.at + ' ' + r.drawn + ' px, ' + r.car + ' by cars, ' + r.grownUp + ' by grown-ups, ' + r.poleChildOther + ' by pole/child/other').join('; '),
      [bad.length + ' moment(s) where a car, a guagua or a grown-up hides the frog, or the pole and the children hide more than ' + COVER_OK + ' px of him:'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].lines.push('       all moments (px hidden: by cars and guaguas / by grown-ups / by the pole, children and other things, of the ' + COVER_OK + ' allowed): ' + res.map(r => 'm' + r.moment + ' ' + r.at + ' ' + r.car + ' / ' + r.grownUp + ' / ' + r.poleChildOther + (r.poleChildOther ? ' (' + byText(r.by) + ')' : '')).join('; '));
    // the nearest place of the frog's spot (along x or y of it) where he passes in that moment: the spec's number is kept
    for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) {
      const r0 = res[m - 1]; if (r0.ok) continue;
      const M = PVD.moments[m], L = M.layers, fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], zt = await zOf(M.set), own = ownerMap(L, fi), rel = relOf(f);
      OUTS[OUTS.length - 1].lines.push('       nearest passing, moment ' + m + ' ' + f.at + ' ' + S[f.at].world + ': ' + nearestPass(f.at, (sx, sy, d) => classify(zt, L, own, fi, rel, sx, sy, d).ok));
    }
    OUTS[OUTS.length - 1].frog = res;
  }

  // 4. a person at a door stands in front of it, not inside the wall: puerta and pepe.puerta are in front of the wall (y > 0) and inside the door's span x, and no pixel of the sprite standing there is hidden by the wall or the door
  //    (every state of the set: both hours, obra 0 and 1, the door shut and open)
  {
    const bad = [], lines = [];
    const D0 = G.E.D0, D1 = G.E.D1;
    for (const [k, sil] of [['puerta', 'abuela'], ['pepe.puerta', 'pepe']]) {
      const s = S[k];
      if (!(s.world[1] > 0)) bad.push(k + ' y ' + s.world[1] + ' is not in front of the wall y 0');
      if (!(s.world[0] >= D0 && s.world[0] <= D1)) bad.push(k + ' x ' + s.world[0] + ' is not in the door\'s span ' + D0 + ' to ' + D1);
      let worst = 0, worstBy = {}, tot = 0;
      for (const st of STATES) { const zt = await zOf(st), hb = hiddenBy(zt, SIL[sil].rel, s.screen[0], s.screen[1], s.depth); tot = hb.tot; if (hb.hid > worst) { worst = hb.hid; worstBy = hb.by; } }
      lines.push(k + ' ' + s.screen + ' (y ' + s.world[1] + ' in front of the wall y 0; x ' + s.world[0] + ' in the door x ' + D0 + ' to ' + D1 + ', ' + r2(s.world[0] - D0) + ' from its left jamb and ' + r2(D1 - s.world[0]) + ' from its right): ' + worst + ' of the ' + tot + ' pixels of ' + sil + ' hidden by the set in the worst of the ' + STATES.length + ' states' + (worst ? ' (' + byText(worstBy) + ')' : ''));
      if (worst) bad.push(k + ': ' + worst + ' pixels of ' + sil + ' hidden by the set (' + byText(worstBy) + ')');
    }
    add('door-people', bad, 'puerta and pepe.puerta stand in front of the colmado\'s door and none of their pixels is hidden by the wall or the door in any of the ' + STATES.length + ' states of the set: ' + lines.join('; '), ['a person at the door is not in front of it:'].concat(bad.map(b => '  ' + b), lines.map(l => '  ' + l)));
    const op = (await zOf({ hora: 'manana', obra: 0, puerta: 'open' })), sh = await zOf({ hora: 'manana', obra: 0, puerta: 'shut' }), a = S['pepe.puerta'];
    // the open leaf swings out of the door to the right (x up to E.D1 + 1.3) and forwards (y up to .34): where it is, relative to don Pepe
    const leaf = []; for (let i = 0; i < PW * PH; i++) if (op.T[i] === 'puerta' && sh.T[i] !== 'puerta') leaf.push(i);
    const lb = leaf.length ? [Math.min(...leaf.map(i => i % PW)), Math.min(...leaf.map(i => (i / PW) | 0)), Math.max(...leaf.map(i => i % PW)), Math.max(...leaf.map(i => (i / PW) | 0))] : null;
    const pe = SIL.pepe.box;
    OUTS[OUTS.length - 1].lines.push('       info, not a check: with the door open its leaf is drawn over pixels [' + lb + '] (columns, rows) that the shut door leaves to the wall; don Pepe at pepe.puerta draws columns ' + (a.screen[0] + pe[0]) + ' to ' + (a.screen[0] + pe[2]) + ', rows ' + (a.screen[1] + pe[1]) + ' to ' + (a.screen[1] + pe[3]));
  }

  // 5. nobody stands on the street unless the spec puts him there: every person spot's feet are off the street (y ' + S0 + ' to ' + S1 + '), the hole and the cement squares, but the ones the spec puts there
  {
    const E = G.E, bad = [], on = [], near = [], onFoot = [];
    const inRect = (w, r) => w[0] >= r[0] && w[0] <= r[2] && w[1] >= r[1] && w[1] <= r[3];
    // the two squares of cement are there only with obra = 1: the spots of the moments with obra = 1 are kept off them (the frog on the wet square at coqui.cemento excepted)
    const obra1 = new Set(); for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) if (PVD.moments[m].set.obra === 1) for (const l of PVD.moments[m].layers) if (l.at) obra1.add(l.at);
    for (const [k, s] of Object.entries(S)) {
      if (s.kind !== 'person' && s.kind !== 'frog') continue;
      const w = s.world, street = w[1] > E.S0 && w[1] < E.S1, hole = inRect(w, [E.OBRA[0], E.S0, E.OBRA[1], 3.8]);
      if (street && !ON_STREET.includes(k)) bad.push(k + ' ' + w + ' is on the street (y ' + E.S0 + ' to ' + E.S1 + ')');
      if (!street && ON_STREET.includes(k)) bad.push(k + ' ' + w + ' is listed as on the street but is not');
      if (street) on.push(k + ' y ' + w[1]);
      if (hole) bad.push(k + ' ' + w + ' is in the hole (x ' + E.OBRA[0] + ' to ' + E.OBRA[1] + ', y ' + E.S0 + ' to 3.8)');
      const dry = inRect(w, E.DRY), wet = inRect(w, E.WET);
      if (obra1.has(k) && ((dry && k !== 'luis.cemento') || (wet && k !== 'coqui.cemento'))) bad.push(k + ' ' + w + ' is on the ' + (dry ? 'old dry' : 'wet') + ' square of cement');
      if (!obra1.has(k) && (dry || wet)) onFoot.push(k + ' ' + w + ' (' + (dry ? 'dry' : 'wet') + ')');
      if (w[1] > NEAR_END) bad.push(k + ' ' + w + ' is past the near pavement (its end, the park\'s wall, is y ' + NEAR_END + ')');
      if (w[1] >= E.S1 && w[1] < E.S1 + E.K) near.push(k + ' y ' + w[1] + ' is ' + r2(w[1] - E.S1) + ' past the street\'s edge y ' + E.S1 + ', on the kerb stone (the kerb is y ' + E.S1 + ' to ' + r2(E.S1 + E.K) + ')');
    }
    add('street-people', bad, 'every person and the frog (' + Object.values(S).filter(s => s.kind === 'person' || s.kind === 'frog').length + ' spots) stands off the street (y ' + E.S0 + ' to ' + E.S1 + ') and the hole, except the ones the spec puts on the street: ' + on.join(', ') + '; ' + near.join('; ') + '; the spots of the moments with obra = 1 (' + [...obra1].join(', ') + ') are off the two squares of cement but the frog on the wet one at coqui.cemento and Luis, kneeling, on the old dry one at luis.cemento', ['somebody stands where the spec does not put him:'].concat(bad.map(b => '  ' + b)));
    OUTS[OUTS.length - 1].lines.push('       info, not a check: spots of the stories without the dug-up street that lie on the footprint of a cement square (the squares are there only with obra = 1): ' + (onFoot.join(', ') || 'none'));
  }

  // 6. a person on a seat sits on its top (z of the seat): the set has no seat; the one thing a person sits on is the obrero's bucket (a sprite), at obrero.cubo z .3, and nobody else is off the ground
  {
    const bad = [], up = Object.entries(S).filter(([, s]) => (s.kind === 'person' || s.kind === 'frog') && s.world[2] !== 0).map(([k, s]) => k + ' z ' + s.world[2]);
    if (up.length !== 1 || !up[0].startsWith('obrero.cubo')) bad.push('the person spots that are not at z 0: ' + up.join(', '));
    const c = S['obrero.cubo'], b = PVD.moments[7].layers.find(l => l.bucket), o = PVD.moments[7].layers.find(l => l.at === 'obrero.cubo' && !l.bucket);
    add('seat-top', bad, 'the set has no seat; the only person off the ground is the obrero at obrero.cubo (z ' + c.world[2] + ', the top of his bucket): the preview draws the bucket on the ground under him (its base on row ' + b.sy + ', ' + (b.sy - c.screen[1]) + ' rows below the spot\'s row ' + c.screen[1] + ', which is z .3 = 6.75 px up) and his lap row ' + o.ay + ' on the spot\'s row', ['seats:'].concat(bad.map(x => '  ' + x)));
  }

  // 7. (extra) the frog at esquina and at boton_coqui (his two places in story 49; esquina2 is gone) is not covered by a vehicle standing at the stop line, alto_carro or alto_guagua: the pixels of his sprite that a
  //    pixel of the car or the guagua (part auto of the set drawn with them) hides by the depth rule; the pole's own pixels that hide him are reported apart
  {
    const bad = [], lines = [], zs = { carro: await zOf(BASE_STATE, 'carro@3.5,4.8,i'), guagua: await zOf(BASE_STATE, 'guagua@6.7,4.8,i'), both: await zOf(BASE_STATE, AUTOS_49) };
    const res = {}, auto = (zt, sx, sy, d) => hiddenBy(zt, SIL.coqui.rel, sx, sy, d).by.auto || 0;
    for (const k of ['esquina', 'boton_coqui']) {
      const s = S[k], r = {}, tot = hiddenBy(zs.both, SIL.coqui.rel, s.screen[0], s.screen[1], s.depth);
      for (const n of ['carro', 'guagua', 'both']) r[n] = auto(zs[n], s.screen[0], s.screen[1], s.depth);
      const base = hiddenBy(await zOf(BASE_STATE, ''), SIL.coqui.rel, s.screen[0], s.screen[1], s.depth);
      res[k] = { drawn: tot.tot, car: r.carro, guagua: r.guagua, both: r.both, hiddenByThePole: base.by.semaforo || 0 };
      lines.push(k + ' ' + s.screen + ' (' + tot.tot + ' px drawn): ' + r.carro + ' covered by the car at alto_carro, ' + r.guagua + ' by the guagua at alto_guagua, ' + r.both + ' by both (apart from these, ' + (base.by.semaforo || 0) + ' hidden by the pole' + (k === 'boton_coqui' ? ': allowed there, he is pressing its button' : '') + ')');
      if (r.both) bad.push(lines[lines.length - 1]);
    }
    add('frog-clear-of-vehicles', bad, 'the frog at esquina and at boton_coqui is not covered by the car at alto_carro or the guagua at alto_guagua: ' + lines.join('; '), ['the frog is covered by what stands at the stop line:'].concat(bad.map(b => '  ' + b)));
    for (const k of ['esquina', 'boton_coqui']) if (res[k].both) OUTS[OUTS.length - 1].lines.push('       nearest passing, ' + k + ' ' + S[k].world + ': ' + nearestPass(k, (sx, sy, d) => auto(zs.both, sx, sy, d) === 0));
    // story 48: the frog at toca_carro, toca_guagua and acera5 against the car and the guagua at the kerb (not in the spec's check: for information)
    const z48 = await zOf(BASE_STATE, AUTOS_48), l48 = ['toca_carro', 'toca_guagua', 'acera5'].map(k => k + ' ' + S[k].screen + ': ' + auto(z48, S[k].screen[0], S[k].screen[1], S[k].depth) + ' px covered by the car at para48_carro or the guagua at para48_guagua');
    OUTS[OUTS.length - 1].lines.push('       info, not a check: story 48: ' + l48.join('; '));
    // the footprints of the things that drive standing together in a moment (the car 2.2 x 1.1, the guagua 4.4 x 1.3, the middle of the floor at the spot): do they overlap in the world (not a check)
    const fp = [];
    for (const m of [1, 2, 3, 4, 5, 6, 7, 8]) {
      const au = (PVD.moments[m].set.autos || '').split(';').filter(Boolean).map(a => { const [k, r] = a.split('@'), [x, y] = r.split(','), bus = k === 'guagua', L = bus ? 4.4 : 2.2, W = bus ? 1.3 : 1.1; return { k, x: +x, y: +y, L, W }; });
      for (let i = 0; i < au.length; i++) for (let j = i + 1; j < au.length; j++) {
        const a = au[i], b = au[j], ox = Math.min(a.x + a.L / 2, b.x + b.L / 2) - Math.max(a.x - a.L / 2, b.x - b.L / 2), oy = Math.min(a.y + a.W / 2, b.y + b.W / 2) - Math.max(a.y - a.W / 2, b.y - b.W / 2);
        fp.push('moment ' + m + ' ' + a.k + '@' + a.x + ',' + a.y + ' ~ ' + b.k + '@' + b.x + ',' + b.y + ': ' + (ox > 1e-9 && oy > 1e-9 ? 'the floors overlap by ' + r2(ox) + ' in x (and ' + r2(oy) + ' in y)' : 'floors apart (' + r2(-ox) + ' in x' + (oy > 0 ? ', same lane' : '') + ')'));
      }
    }
    OUTS[OUTS.length - 1].lines.push('       info, not a check: things that drive standing together: ' + (fp.join('; ') || 'none'));
    OUTS[OUTS.length - 1].covered = res;
  }

  // 8. (extra) mamá at enfrente = acera1 (with the bebé on her arm: the sprite of moments 4, 5 and 6) is whole inside the window
  {
    const bad = [], lines = [];
    for (const m of [4, 5, 6]) {
      const l = PVD.moments[m].layers.find(q => q.at === 'acera1'), xs = l.px.map(p => p[0]), ys = l.px.map(p => p[1]), a = Math.min(...xs), b = Math.max(...xs), c = Math.min(...ys), d = Math.max(...ys);
      const ok = l.px.length === l.total && a >= x0 && b <= x0 + VW - 1 && c >= 0 && d <= PH - 1;
      lines.push('moment ' + m + ': columns ' + a + ' to ' + b + ', rows ' + c + ' to ' + d + ' (' + l.px.length + ' of ' + l.total + ' px in the picture; ' + (a - x0) + ' px from the window\'s left edge, ' + (x0 + VW - 1 - b) + ' from its right)');
      if (!ok) bad.push(lines[lines.length - 1]);
    }
    add('enfrente-in-window', bad, 'mamá at enfrente ' + S['enfrente'].screen + ' is whole inside the window [' + x0 + ', ' + (x0 + VW) + '): ' + lines.join('; '), ['mamá at enfrente is cut:'].concat(bad.map(b => '  ' + b)));
  }

  // 9. (extra) moment 7: the hole shows 45% or more of its pixels (not covered by a vehicle or a person). The hole's pixels (A, the one the check uses): those the set (obra = 1, no autos) draws as the street's ground
  //    inside the hole x .4 to 2.8, y 1.8 to 3.8, that is the earth, its dark far walls and its lit rim; the pixels of its barrier, cones, heaps of earth and spade are not the hole's (B counts them: the whole image of the
  //    hole's rectangle, reported apart)
  {
    const M = PVD.moments[7], L = M.layers, own = ownerMap(L), hole = await holePixels(ctx);
    const share = async (autos, set) => {
      const z1 = await zOf(M.set, autos); let car = 0, spr = 0; const sprBy = {};
      for (const i of set) { if (z1.T[i] === 'auto') { car++; continue; } const o = own.get(i); if (o) { spr++; const n = L[o.idx].who === 'cono' ? 'cone' : L[o.idx].bucket ? 'bucket' : L[o.idx].at; sprBy[n] = (sprBy[n] || 0) + 1; } }
      return { car, spr, sprBy, shown: set.length - car - spr, frac: (set.length - car - spr) / set.length };
    };
    const A = await share(M.set.autos, hole.a), B = await share(M.set.autos, hole.b);
    const perCar = {};
    for (const a of M.set.autos.split(';')) { const za = await zOf(M.set, a); perCar[a.split('@')[0] + ' at ' + a.split('@')[1].split(',').slice(0, 2).join(',')] = hole.a.filter(i => za.T[i] === 'auto').length; }
    const ok = A.frac >= HOLE_MIN;
    const text = 'moment 7: the hole shows ' + A.shown + ' of its ' + hole.a.length + ' pixels (' + r2(A.frac * 100) + '%, needs ' + r2(HOLE_MIN * 100) + '%); covered: ' + A.car + ' by the vehicles (' + Object.entries(perCar).map(([k, n]) => n + ' by ' + k + ' alone').join(', ') + '), ' + A.spr + ' by sprites' + (A.spr ? ' (' + byText(A.sprBy) + ')' : '');
    add('hole-shows', ok ? [] : ['x'], text, [text]);
    OUTS[OUTS.length - 1].lines.push('       info, not a check: counting the whole image of the hole\'s rectangle (' + hole.b.length + ' pixels, with its barrier, cones, heaps and spade) the vehicles and people cover ' + (B.car + B.spr) + ' and ' + B.shown + ' show: ' + r2(B.frac * 100) + '%');
    if (!ok) {                                                                          // the nearest place of the guagua at carril_b (along its lane) where the hole shows the share it needs (the spec's number is kept)
      const g = S['carril_b.guagua'].world, other = M.set.autos.split(';').filter(a => !a.startsWith('guagua')).join(';'), at = async x => (await share((other ? other + ';' : '') + 'guagua@' + x + ',' + g[1] + ',i', hole.a)).frac;
      let hit = null, last = g[0];
      for (let x = r4(g[0] + .05); x <= 9.5 && hit === null; x = r4(x + .05)) { if ((await at(x)) >= HOLE_MIN) hit = x; else last = x; }
      if (hit !== null) for (let x = r4(last + .01); x <= hit; x = r4(x + .01)) if ((await at(x)) >= HOLE_MIN) { hit = x; break; }
      OUTS[OUTS.length - 1].lines.push('       nearest passing: carril_b.guagua ' + g + ': x ' + g[0] + ' -> ' + (hit === null ? 'none up to 9.5' : hit + ' (+' + r2(hit - g[0]) + ')') + ' (the guagua drawn there with the blue car at carril_a.carro: the hole shows ' + (hit === null ? '' : r2((await at(hit)) * 100) + '%') + ')');
    }
    OUTS[OUTS.length - 1].hole = { pixels: hole.a.length, shown: A.shown, byVehicles: A.car, bySprites: A.spr, share: r4(A.frac), wholeImage: { pixels: hole.b.length, shown: B.shown, share: r4(B.frac) } };
  }

  // 10. the touch boxes: each is inside the picture; puerta, boton, esquina and cemento stay whole inside the window; a thing's drawn pixel is the part it names: the pixel at the middle of the door's box and of the
  //     button's box, and the one the projected middle of the street's, the corner's and the cement's world box falls on, is drawn by the door, the pole's light and the ground
  {
    const bad = [], info = [];
    const boxes = Object.entries(T).filter(([, t]) => t.box);
    for (const [k, t] of boxes) {
      const b = t.box;
      if (b[0] < 0 || b[1] < 0 || b[0] + b[2] > PW || b[1] + b[3] > PH) bad.push(k + ' box [' + b + '] outside the picture');
      const l = Math.max(0, x0 - b[0]), r = Math.max(0, b[0] + b[2] - (x0 + VW));
      if (l || r) info.push(k + ' [' + b + '] is cut by the window: ' + l + ' px at the left, ' + r + ' at the right');
      if (['puerta', 'boton', 'esquina', 'cemento'].includes(k) && (l || r)) bad.push(k + ' box [' + b + '] is not whole inside the window [' + x0 + ', ' + (x0 + VW) + ')');
    }
    // the part that draws a thing: for the door and the button the pixel at the middle of the world box; for a flat thing (the street, the corner, the cement) the 9 pixels at the 1/6, 3/6, 5/6 of the box in x and in y (the pole
    // and its button box stand on the corner: some of the 9 are theirs); the thing's part has to draw most of them
    const sample = (st, w, flat) => zOf(st).then(zt => { const t = {}, f = [1 / 6, .5, 5 / 6], pts = flat ? f.flatMap(a => f.map(b => [w[0] + (w[3] - w[0]) * a, w[1] + (w[4] - w[1]) * b, 0])) : [[(w[0] + w[3]) / 2, (w[1] + w[4]) / 2, (w[2] + w[5]) / 2]]; for (const q of pts) { const c = scr3(G, ...q), g = zt.T[c[1] * PW + c[0]] || 'ground'; t[g] = (t[g] || 0) + 1; } return t; });
    const dry = { hora: 'manana', obra: 0, puerta: 'shut' }, pt = {};
    for (const [k, st, flat] of [['puerta', dry, false], ['boton', dry, false], ['calle', dry, true], ['esquina', dry, true], ['cemento', { hora: 'manana', obra: 1, puerta: 'shut' }, true]]) pt[k] = await sample(st, T[k].world, flat);
    const want = { puerta: 'puerta', boton: 'semaforo', calle: 'ground', esquina: 'ground', cemento: 'ground' };
    for (const k of Object.keys(want)) { const n = pt[k][want[k]] || 0, all = Object.values(pt[k]).reduce((a, b) => a + b, 0); if (k === 'puerta' ? !((pt[k].puerta || 0) + (pt[k].colmado || 0)) : n * 2 < all) bad.push(k + ': its world box is drawn by ' + JSON.stringify(pt[k]) + ', not by ' + want[k]); }
    add('things-in-view', bad, boxes.length + ' things with a box (' + boxes.map(([k, t]) => k + ' [' + t.box + ']').join(', ') + ') inside the picture; puerta, boton, esquina and cemento whole inside the window; what draws each world box (the middle pixel, or 9 pixels for a flat one): ' + Object.entries(pt).map(([k, v]) => k + ' ' + Object.entries(v).map(([a, n]) => n + ' ' + a).join(' + ')).join(', ') + '; ' + (info.length ? info.join('; ') : 'none cut by the window'),
      ['things:'].concat(bad.map(b => '  ' + b)));
  }

  return OUTS;
}

// a sprite layer's drawn pixels relative to its spot: flat dx, dy
const relOf = l => { const r = []; for (const p of l.px) r.push(p[0] - l.sx, p[1] - l.sy); return r; };
// who owns each pixel of the picture in a moment: the layer whose shown pixel has the greatest plane (the later layer on a tie), as the preview draws; `skip` leaves a layer out
function ownerMap(L, skip) {
  const own = new Map();
  L.forEach((l, idx) => { if (idx === skip) return; for (const p of l.px) { if (p[2]) continue; const i = p[1] * PW + p[0], o = own.get(i); if (!o || p[3] >= o.plane) own.set(i, { plane: p[3], idx }); } });
  return own;
}
// is a sprite (rel) whole at a screen point and depth: no pixel hidden by the set (zt) nor by a nearer pixel of another layer (own, built without it)
function seenWhole(zt, own, rel, sx, sy, d) {
  for (let k = 0; k < rel.length; k += 2) {
    const X = sx + rel[k], Y = sy + rel[k + 1]; if (X < 0 || X >= PW || Y < 0 || Y >= PH) continue;
    const i = Y * PW + X, plane = d + (sy - (Y + .5)) * T30 / 26;
    if (zt.Z[i] > plane + BIAS) return false;
    const o = own.get(i); if (o && o.plane > plane) return false;
  }
  return true;
}
// the hole's pixels, as indexes of the picture: a = those the set (obra = 1, no autos) draws as ground (no part drew over them) inside the dug-up stretch of the far lane, b = every pixel
// whose ground point is inside that stretch, whatever is drawn there (its barrier, cones, heaps of earth and spade included)
async function holePixels(ctx) {
  await ctx.load(qOf({ hora: 'manana', obra: 1, puerta: 'shut' }));
  return ctx.page.evaluate(() => {
    const E = ESQUINA.E, a = [], b = [];
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const i = iy * W + ix, g = unproject(ix + .5, iy + .5);
      if (g.x >= E.OBRA[0] && g.x <= E.OBRA[1] && g.y >= E.S0 && g.y <= 3.8) { b.push(i); if (!TAGS[i]) a.push(i); }
    }
    return { a, b };
  });
}
