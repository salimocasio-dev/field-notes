#!/usr/bin/env node
'use strict';
/* La música's sheet (place 10, El fuerte, scene 2; stories 111, 112, 113): writes docs/proyecto/pixel/musica-sheet.json from musica-set.html and the design (the orchestrator's p10-spec,
   the rules for every sheet and "musica"), then checks it.
   Run from the repo root:  node docs/proyecto/pixel/musica-sheet-make.js        (needs Node 22 and the pre-installed Playwright, Chrome at /usr/bin/google-chrome)
   A NEW scene: no old scene file, no old positions, no remap. The set is laid out square to the picture: a spot is given in (u, v, z), u across the picture, v down it
   (plaza-base.js: PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world place); the make projects it with the engine's own project() (pp-engine.js).
   In the picture sx = OX + u S and sy = OY + (v / 2 - z cos 30) S (OX 120, OY 74 here). The stage, the stools, the rack, the microphone's place, the notes' places, the bench, the floor stool and the
   dance floor are read from the set (window.MUSICA.E), never typed again from the design. The set draws one frame (nothing sways): window.DEPTH.z is the baked depth.
   It loads the set in headless Chrome (musica-set.html, tags=1: which part drew each pixel; the baked depth), and writes the spots, things, the view (wide), shadows and the depth
   rule. The sprites' silhouettes come from the preview's own makers (PREVIEW.silhouette). The checks that say "covers" or "shows" read the PREVIEW's moments (musica-preview.html,
   PREVIEW.inspect and its queries): the sheet is written first without its checks, the preview reads it, and then the sheet is written again with the checks.
   Then it checks the sheet and prints one line per check; it exits 1 when one fails (the sheet is written first). A second run writes the same bytes.
   The set is asked for at http://127.0.0.1:8765 (the dev server for the repo root; override with MUSICA_BASE), but every request to it is answered
   from the files of THIS tree (the server's root may be another checkout of the repo): a new file here is seen before it is merged. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'musica-sheet.json');
const BASE = process.env.MUSICA_BASE || 'http://127.0.0.1:8765';
const PAGE = BASE + '/docs/proyecto/pixel/musica-set.html';
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

// the numbers of the design (p10-spec: the rules for every sheet, and "musica")
const BIAS = .3;                                         // the depth rule: the feet's depth plus this
const EPS = .001;                                        // two sprite planes this near are a tie: the later layer wins
const WIDTH = { coqui: 32, adulto: 24, nino: 24, perro: 28 }, UPDOWN = 12;     // sprite boxes (the feet's spot in the middle): two that stand together do not overlap sideways unless their feet are UPDOWN px or more apart up-down
const HEAD_ROWS = 14;                                    // the head of a person: the top 14 rows of the sprite
const SEAT_Z = .46;                                      // the bench's seat and the floor stool's top; the músicos' stools' top is the stage's height + this
const SZ = { guitarra: [12, 22], tambor: [12, 14], microfono: [6, 28], nota: [14, 14], camara: [10, 8], guitarra_rodillas: [22, 8] };
const CAM_PX = [0, -5];                                  // the camera on the frog's chest: its bottom middle 5 px above the frog's spot (the frog's belly is rows 12 to 22 of his 26: the box [sx - 5, sy - 13, 10, 8])
const KNEES_PX = [0, 3];                                 // the guitar across the first músico's knees (moment 2): its bottom middle 3 px below the stool's spot
const MOMENTS = [1, 2, 3, 4];
const SILKEY = { adulto: 'abuelo', adultoS: 'abueloS', abuela: 'abuela', abuelaS: 'abuelaS', nino: 'luis', coqui: 'coqui' };       // which preview sprite draws each silhouette name

/* The spec's numbers that failed a check and were moved the least distance (v first, then u; never z; never a spot the set fixes: a seat, a top, a place the set's own numbers give).
   spot: { to: [u, v, z], why }: the spec's own numbers are in defs(); the sheet's notes list each move with the old and the new numbers. */
const MOVES = {
  pista_baile: { to: [1.64, 4.6, 0], why: 'frog-seen: in moment 3 Carmen dancing at pista_baile covered 302 of the 536 px of the frog at centro_coqui (her head and shoulders in front of his right side): u .9 -> 1.64 (+.74; the least that passes: v would need +1.44, and the frog\'s own spot u -.76 or v -1.41)' },
  ronda1: { to: [-.56, 5.4, 0], why: 'frog-seen: in moment 4 ronda1 (dances) covered 160 of the 536 px of the frog at centro_coqui: u .2 -> -.56 (-.76; the least that passes every check: u -.42 clears the frog but then ronda1\'s head covers 28 px of the microphone (mic-clear); v would need +1.57, and the frog\'s own spot u -1.42 or v +2.68)' },
};

/* the spots: { name, uvz, kind, sil, who, what, on, size, anchor, fixed }
   kind: person (a character stands or sits there), place (the frog's), thing (a small thing: the guitar, the drum, the microphone, a paper note)
   sil: which drawing hangs there (adulto = a grown-up standing, adultoS = a grown-up sitting, abuela, abuelaS = abuela standing, sitting, nino = a child standing, coqui) or null for a small thing
   anchor (small things): top = its top middle on the point (it hangs), bottom = its bottom middle on the point
   on: the part of the set it stands on above the floor: patio (the stage, a stool, the bench); air for what hangs (not asked of the set)
   fixed: the set fixes its place (a seat, a hook, the microphone's place), so it is never moved */
function defs(E) {
  const S = E.STAGE, R = E.RACK, B = E.BENCH, N = E.NOTES, M = E.MIC, ST = E.STOOL, D = [], ZS = r4(S.h + SEAT_Z);
  const add = (name, uvz, kind, sil, who, what, more) => D.push(Object.assign({ name, uvz, kind, sil, who, what }, more || {}));
  // the músicos on their stools, on the stage
  E.STOOLS.forEach(([u, v], i) => add('taburete' + (i + 1), [u, v, ZS], 'person', 'adultoS', 'adulto', 'the músico ' + (i + 1) + (i ? ' (the beard)' : ' (the hat)') + ' on his stool (STOOLS[' + i + '] u ' + u + ', v ' + v + '): its top, z STAGE.h + ' + SEAT_Z + ' = ' + ZS + '; hung by the lap', { on: 'patio', fixed: true }));
  // the instruments on the rack: each hangs from the bar
  add('guitarra_atril', [r4(R.u - .22), R.v, r4(S.h + R.h)], 'thing', null, null, 'the guitar on the rack (RACK.u - .22, RACK.v; the bar\'s underside, z STAGE.h + RACK.h = ' + r4(S.h + R.h) + '): a ' + SZ.guitarra.join(' x ') + ' px stand-in, its top middle on the point (it hangs)', { size: SZ.guitarra, anchor: 'top', on: 'air', fixed: true });
  add('tambor_atril', [r4(R.u + .22), R.v, r4(S.h + R.h)], 'thing', null, null, 'the drum on the rack (RACK.u + .22, RACK.v; z ' + r4(S.h + R.h) + '): a ' + SZ.tambor.join(' x ') + ' px stand-in, its top middle on the point (it hangs)', { size: SZ.tambor, anchor: 'top', on: 'air', fixed: true });
  // the frog on the stage's front edge, abuela beside the stage
  add('borde_coqui', [-1.2, 2.3, S.h], 'place', 'coqui', 'coqui', 'the frog on the stage\'s front edge, below the rack (the stage\'s front edge is v ' + S.v1 + '): the stage\'s top, z STAGE.h = ' + S.h, { on: 'patio' });
  add('junto_escenario', [.15, 1.6, 0], 'person', 'abuela', 'adulto', 'abuela beside the stage (111)', {});
  // the microphone: a sprite on the floor beside the stage; whoever sings stands just behind it
  add('microfono', [M[0], M[1], 0], 'thing', null, null, 'the microphone on its stand (MIC u ' + M[0] + ', v ' + M[1] + '): a ' + SZ.microfono.join(' x ') + ' px stand-in, its bottom middle on the floor at the point', { size: SZ.microfono, anchor: 'bottom', fixed: true });
  add('ante_micro', [M[0], r4(M[1] - .3), 0], 'person', 'adulto', 'adulto', 'whoever sings stands just behind the microphone (MIC.u, MIC.v - .3); abuelo in 112 (m3), the singer ronda2 in 113 (m4)', {});
  add('centro_coqui', [.7, 2.9, 0], 'place', 'coqui', 'coqui', 'the frog between the stage and the floor (112, 113)', {});
  // the three big paper notes over the stage: each hangs
  N.u.forEach((u, i) => add('nota' + (i + 1), [u, S.v0, N.z], 'thing', null, null, 'paper note ' + (i + 1) + ' of 3 over the stage (NOTES.u[' + i + '] = ' + u + ', the stage\'s back edge v ' + S.v0 + ', NOTES.z ' + N.z + '): a ' + SZ.nota.join(' x ') + ' px stand-in, its top middle on the point (it hangs)', { size: SZ.nota, anchor: 'top', on: 'air', fixed: true }));
  // the floor: three couples (111), one dancing (112)
  [[-.2, 4.0], [.75, 4.0], [1.5, 5.6], [2.45, 5.6], [-.6, 6.8], [.35, 6.8]].forEach(([u, v], i) => add('pista' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'the open floor, couple ' + (Math.floor(i / 2) + 1) + ' of 3, ' + (i % 2 ? 'the second' : 'the first') + ' (111)', {}));
  add('pista_baile', [.9, 4.6, 0], 'person', 'nino', 'nino', 'one person dancing on the floor (112: Carmen)', {});
  // the bench: four people
  [-1.43, -.48, .48, 1.43].forEach((du, i) => add('banco' + (i + 1), [r4(B.u + du), B.v, SEAT_Z], 'person', 'adultoS', 'adulto', 'the bench\'s seat ' + (i + 1) + ' of 4 (BENCH u ' + B.u + ' ' + (du < 0 ? '-' : '+') + ' ' + Math.abs(du) + ', v ' + B.v + '): on its top, z ' + SEAT_Z + '; hung by the lap', { on: 'patio', fixed: true }));
  // waiting at the right
  [[1.6, 3.2], [2.55, 3.2], [3.3, 4.4]].forEach(([u, v], i) => add('espera' + (i + 1), [u, v, 0], 'person', 'adulto', 'adulto', 'waiting at the right ' + (i + 1) + ' of 3' + (i === 1 ? ' (Luis in 112)' : ''), {}));
  // abuela on the floor stool
  add('banqueta_abuela', [ST[0], ST[1], SEAT_Z], 'person', 'abuelaS', 'adulto', 'abuela on the stool beside the floor (STOOL u ' + ST[0] + ', v ' + ST[1] + '): its top, z ' + SEAT_Z + '; hung by the lap (113)', { on: 'patio', fixed: true });
  // story 113's five: ronda2 is ante_micro, ronda3 is banco3
  add('ronda1', [.2, 5.4, 0], 'person', 'adulto', 'adulto', 'the five of 113: ronda1 dances', {});
  add('ronda4', [1.7, 6.6, 0], 'person', 'adulto', 'adulto', 'the five of 113: ronda4 laughs', {});
  add('ronda5', [-1.7, 5.8, 0], 'person', 'adulto', 'adulto', 'the five of 113: ronda5 yawns (ronda2 is ante_micro, ronda3 is banco3)', {});
  return D.map(d => MOVES[d.name] ? Object.assign({}, d, { spec: d.uvz, uvz: MOVES[d.name].to, moved: MOVES[d.name].why }) : d);
}

/* the checks (each is a line of the output and of the sheet's checks.results):
   views-x0 (x0 holds every spot), spots-in-view (every spot inside the picture and the window, its sprite whole), spots-on-surface (the spots on a stool, the stage, the bench, the floor stool are on what the set draws),
   things-in-view (the set things' boxes), sprites-apart (the people of a moment), frog-seen (the frog whole in every moment), heads-clear (the head of everyone who sits covered by nobody and by nothing),
   rack-clear (m1), notes-clear (m3), mic-clear (m3, m4), ronda-heads (m4).
   A failing line names its numbers and the nearest value that would pass. */
(async () => {
  const browser = await chromium.launch(fs.existsSync(CHROME) ? { executablePath: CHROME } : {});
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.route(BASE + '/**', serve);

  await page.goto(PAGE + '?tags=1');
  const G = await page.evaluate(() => {
    const o = {}; for (const [k, v] of Object.entries(MUSICA.E)) if (typeof v !== 'function') o[k] = v;
    return { E: o, scene: PP_SCENE, W, H, S, OX, OY };
  });
  // the engine's own projection of (u, v, z): [sx, sy, depth, world x, world y]
  const proj = uvz => page.evaluate(a => a.map(([u, v, z]) => { const x = (u + v) / Math.SQRT2, y = (v - u) / Math.SQRT2, q = project(x, y, z); return [q.sx, q.sy, q.d, x, y]; }), uvz);
  const sheet = await make(G, proj);
  fs.writeFileSync(OUT, compact(JSON.stringify(sheet, null, 1)) + '\n');          // first without the checks: the preview reads the sheet
  const probes = await probeSets(page, sheet, G);
  const PV = await previewData(browser, errs, sheet);
  const results = await checks(sheet, G, probes, PV);
  sheet.setKey.baked = [''];
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
const ITEM = '(?:-?[\\d.]+|"[\\w.=+&?:-]+")';
const compact = t => t.replace(new RegExp('\\[\\n\\s+(' + ITEM + '(?:,\\n\\s+' + ITEM + ')*)\\n\\s+\\]', 'g'), (m, a) => '[' + a.replace(/,\n\s+/g, ', ') + ']');

/* ---------- the preview's moments: musica-preview.html, read through PREVIEW.inspect (every layer of a moment: its spot, its kind, its drawn pixels [X, Y, hidden by the set, plane]) ---------- */
async function previewData(browser, errs, sheet) {
  const p = await browser.newPage();
  p.on('pageerror', e => errs.push('preview: ' + String(e)));
  await p.route(BASE + '/**', serve);
  await p.goto(BASE + '/docs/proyecto/pixel/musica-preview.html?nodraw=1');
  await p.evaluate(() => window.PREVIEW.done);
  const PV = { page: p, inspect: {}, moment: {}, sil: {} };
  for (const m of MOMENTS) { PV.inspect[m] = await p.evaluate(m => window.PREVIEW.inspect(m), m); PV.moment[m] = await p.evaluate(m => window.PREVIEW.moment(m), m); }
  for (const [k, v] of Object.entries(SILKEY)) PV.sil[k] = await p.evaluate(a => window.PREVIEW.silhouette(a.k, a.ctx), { k: v, ctx: { sx: 0, sy: 0 } });
  PV.layers = (st, specs) => p.evaluate(a => window.PREVIEW.inspectLayers(a.st, a.specs), { st, specs });
  PV.nearest = (st, specs, idx, allow) => p.evaluate(x => window.PREVIEW.nearest(x.st, x.specs, x.idx, x.allow), { st, specs, idx, allow: allow || 0 });
  PV.nearestClear = (st, specs, idx, others, rows) => p.evaluate(x => window.PREVIEW.nearestClear(x.st, x.specs, x.idx, x.others, x.rows), { st, specs, idx, others, rows: rows || null });
  PV.nearestFree = (st, specs, idx, boxes) => p.evaluate(x => window.PREVIEW.nearestFree(x.st, x.specs, x.idx, x.boxes), { st, specs, idx, boxes });
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
// how many px of a spot are cut by the window at x0 (0 when whole)
function cutAt(s, x0) {
  const [a, b] = colsOf(s);
  return Math.max(0, x0 - a) + Math.max(0, b - (x0 + 195));
}

/* ---------- the sheet ---------- */
async function make(G, proj) {
  const E = G.E, sc = G.scene, DEF = defs(E);
  const pr = await proj(DEF.map(d => d.uvz));
  const spots = {};
  DEF.forEach((d, i) => {
    const q = pr[i], sx = Math.round(q[0]), sy = Math.round(q[1]);
    const o = { world: W4([q[3], q[4], d.uvz[2]]), uv: W4(d.uvz), screen: [sx, sy], depth: r4(q[2]), scale: 1, kind: d.kind, view: 'wide', what: d.what };
    if (d.sil) o.sprite = d.sil;
    if (d.who) o.who = d.who;
    if (d.size) { o.box = boxOn(sx, sy, d.size, d.anchor); o.anchor = d.anchor; }
    if (d.uvz[2] > 0) o.on = d.on || 'ground';
    if (d.fixed) o.fixed = 1;
    if (d.moved) { o.spec = W4(d.spec); o.moved = d.moved; }
    spots[d.name] = o;
  });

  /* ---- the view: x0 so that every spot is inside the picture and the window ---- */
  const held = Object.entries(spots);
  const ext = held.map(([, s]) => colsOf(s)), lo = Math.min(...ext.map(e => e[0])), hi = Math.max(...ext.map(e => e[1]));
  const ok0 = []; for (let x0 = 0; x0 <= G.W - 196; x0++) if (held.every(([, s]) => !cutAt(s, x0))) ok0.push(x0);
  const centred = Math.round((G.W - 196) / 2);                                  // the window centred on the picture: 22
  let x0 = null, best = 1e9;
  if (ok0.length) { for (const x of ok0) if (Math.abs(x - centred) < best) { best = Math.abs(x - centred); x0 = x; } }
  else { let bn = 1e9; for (let x = 0; x <= G.W - 196; x++) { const n = held.reduce((a, [, s]) => a + cutAt(s, x), 0); if (n < bn) { bn = n; x0 = x; } } }
  const vu = (x0 + 98 - G.OX) / G.S, vv = (G.H / 2 - G.OY) / (G.S * .5), vq = (await proj([[vu, vv, 0]]))[0];
  const views = {
    wide: { world: W4([vq[3], vq[4], 0]), uv: W4([vu, vv, 0]), screen: [r2(vq[0]), r2(vq[1])], zoom: 1, x0, region: [x0, 0, 196, 216], stories: [111, 112, 113], holds: held.map(([k]) => k), extent: [lo, hi], x0Range: ok0.length ? [ok0[0], ok0[ok0.length - 1]] : null,
      what: 'the one view of stories 111, 112 and 113: the 196 x 216 window over the 240 x 216 picture. The spec: x0 22 (the window centred on the picture) unless a spot is cut (a person with his sprite whole, a small thing with its box). ' + (ok0.length ? 'x0 ' + ok0[0] + ' to ' + ok0[ok0.length - 1] + ' hold them all; x0 ' + x0 + ' is the one nearest ' + centred + ', the window centred on the picture' : 'No x0 holds them all: x0 ' + x0 + ' cuts the fewest px') + ' (the spots held span columns ' + lo + ' to ' + hi + '). The window\'s point is the ground point under its middle column at the picture\'s middle row' },
  };

  /* ---- things he can touch ---- */
  const boxOfCorners = async corners => {
    const q = await proj(corners), xs = q.map(p => p[0]), ys = q.map(p => p[1]);
    const fl = v => Math.floor(v + 1e-9), ce = v => Math.ceil(v - 1e-9), x0 = fl(Math.min(...xs)), y0 = fl(Math.min(...ys));
    return { box: [x0, y0, ce(Math.max(...xs)) - x0, ce(Math.max(...ys)) - y0], q };
  };
  const setThing = async (u0, v0, z0, u1, v1, z1, what) => {
    const corners = []; for (const z of [z0, z1]) for (const [u, v] of [[u0, v0], [u1, v0], [u1, v1], [u0, v1]]) corners.push([u, v, z]);
    const b = await boxOfCorners(corners), q = b.q;
    return { set: true, uv: W4([u0, v0, z0, u1, v1, z1]), world: W4([Math.min(...q.map(p => p[3])), Math.min(...q.map(p => p[4])), z0, Math.max(...q.map(p => p[3])), Math.max(...q.map(p => p[4])), z1]), box: b.box, what };
  };
  const things = {};
  const S = E.STAGE, B = E.BENCH, F = E.FLOOR;
  things.escenario = await setThing(S.u0, S.v0, 0, S.u1, S.v1, S.h, 'the stage (STAGE u ' + S.u0 + ' to ' + S.u1 + ', v ' + S.v0 + ' to ' + S.v1 + ', z 0 to ' + S.h + '): its box on the picture; a poke');
  things.pista = await setThing(F[0], F[1], 0, F[2], F[3], 0, 'the open floor where people dance (FLOOR u ' + F[0] + ' to ' + F[2] + ', v ' + F[1] + ' to ' + F[3] + ', z 0): its box on the picture; a poke');
  things.banco = await setThing(r4(B.u - B.hw), r4(B.v - .27), 0, r4(B.u + B.hw), r4(B.v + .26), 1.17, 'the bench (BENCH u ' + r4(B.u - B.hw) + ' to ' + r4(B.u + B.hw) + ', the seat v ' + r4(B.v - .26) + ' to ' + r4(B.v + .26) + ', its back to v ' + r4(B.v - .27) + ', z 0 to 1.17 the back\'s top): the whole bench\'s box on the picture; a poke (OPEN POINT: the spec gives no box, the seat alone is z 0 to ' + SEAT_Z + ')');
  // the small things at their spots: guitar, drum, microphone, paper notes: the box is the spot's
  const sprite = (k, spot, w) => { things[k] = { sprite: true, spot, size: spots[spot].box.slice(2), anchor: spots[spot].anchor, box: spots[spot].box.slice(), what: w }; };
  sprite('guitarra', 'guitarra_atril', 'the guitar on the rack (a ' + SZ.guitarra.join(' x ') + ' px stand-in, hangs from the bar): its box is the spot\'s; a poke (it goes into a músico\'s hands in the game: the box is where it hangs)');
  sprite('tambor', 'tambor_atril', 'the drum on the rack (a ' + SZ.tambor.join(' x ') + ' px stand-in, hangs from the bar): its box is the spot\'s; a poke');
  sprite('microfono', 'microfono', 'the microphone on its stand (a ' + SZ.microfono.join(' x ') + ' px stand-in): its box is the spot\'s; a poke');
  for (let i = 1; i <= 3; i++) sprite('nota' + i, 'nota' + i, 'the paper note ' + i + ' over the stage (a ' + SZ.nota.join(' x ') + ' px stand-in, hangs): its box is the spot\'s');
  // things held: sprites at a pixel offset from a person's spot (not spots of the spec: made for the preview, from the spec's words)
  const fs0 = spots.centro_coqui.screen, ks = spots.taburete1.screen;
  things.camara = { sprite: true, on: 'coqui', px: CAM_PX, sprite_name: 'camara', anchor: 'bottom', size: SZ.camara, box: boxOn(fs0[0] + CAM_PX[0], fs0[1] + CAM_PX[1], SZ.camara, 'bottom'),
    what: 'abuela\'s camera on the frog\'s chest (a ' + SZ.camara.join(' x ') + ' px box): its bottom middle ' + -CAM_PX[1] + ' px above the frog\'s spot, its middle on his column (px is relative to the frog\'s spot, wherever he stands; the box here is for centro_coqui, moment 4)' };
  things.guitarra_rodillas = { sprite: true, on: 'taburete1', px: KNEES_PX, sprite_name: 'guitarraH', anchor: 'bottom', size: SZ.guitarra_rodillas, box: boxOn(ks[0] + KNEES_PX[0], ks[1] + KNEES_PX[1], SZ.guitarra_rodillas, 'bottom'),
    what: 'the guitar across the first músico\'s knees (moment 2; a ' + SZ.guitarra_rodillas.join(' x ') + ' px stand-in, not in the spec as a spot): its bottom middle ' + KNEES_PX[1] + ' px below taburete1\'s point, its middle on his column' };
  for (const k of ['musico1', 'musico2', 'abuela', 'abuelo', 'luis', 'carmen', 'coqui']) things[k] = 'sprite';

  const moves = DEF.filter(d => d.moved).map(d => ({ spot: d.name, spec: W4(d.spec), now: W4(d.uvz), why: d.moved }));
  return {
    scene: 'musica',
    made: 'node docs/proyecto/pixel/musica-sheet-make.js, from musica-set.html (window.MUSICA.E) and the design of La música (the orchestrator\'s p10-spec, general rules and section musica). A new scene: no old scene, no remap.',
    S: G.S, origin: { originX: sc.originX, originY: sc.originY }, picture: [G.W, G.H], view: [196, 216],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin: sx = OX + (x - y) / R2 * S, sy = OY + ((x + y) / R2 * .5 - z * COS) * S, depth d = (x + y) / R2 * COS + z * .5 (R2 = sqrt 2, COS = sqrt 3 / 2); OX = W / 2 + originX = ' + G.OX + ', OY = H / 2 + originY = ' + G.OY + '. A box is the screen bounding box of its projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]. screen is the projection rounded to whole pixels',
      uv: 'the set is laid out square to the picture: a spot is given in (u, v, z), u across the picture (to the right), v down it (towards the camera), the fort\'s wall at v 0; plaza-base.js PZ.xy(u, v) = ((u + v) / R2, (v - u) / R2) gives the world x, y (world is that). On the picture sx = OX + u * S = ' + G.OX + ' + 26 u, and sy = OY + (v / 2 - z * COS) * S = ' + G.OY + ' + 13 v - 22.5 z; the picture holds u from ' + r2((0 - G.OX) / G.S) + ' to ' + r2((G.W - G.OX) / G.S),
      spot: 'a spot is a world point of the feet (z 0: the floor; z ' + S.h + ': the stage\'s top; z ' + r4(S.h + SEAT_Z) + ': a músico\'s stool on the stage; z ' + SEAT_Z + ': the bench\'s seat and the floor stool) and, drawn there, a character stands with its feet (the lowest row the sprite draws, outline included) resting on the screen row sy, i.e. the sprite\'s bottom edge on sy, and its middle column on the column sx (rules.anchor). A small thing has a box (the spot\'s box): a thing that hangs (the guitar, the drum, the paper notes) has its top middle on the point (the box [sx - floor(w / 2), sy, w, h]); the microphone has its bottom middle on the floor at the point (the box [sx - floor(w / 2), sy - h, w, h]). scale is the frog\'s: 1 everywhere',
      anchor: 'the column of the sprite that is on sx; its feet (its lowest drawn row, outline included) rest on row sy - 1, so its bottom edge is on sy. mkPersona (48 wide): column 24 (KIT.PX), 53 rows drawn standing for a grown-up (a 56-row canvas whose lowest row is empty); the frog mkCoqui(1) (32 x 27): column 16, drawn rows 1 to 24 (row 25 of the canvas is on sy); abuela standing mkAbuela (48 x 51): column 30; abuela sitting mkAbuelaS (52 x 50): column 17 (her middle) and row 36 (her lap) on (sx, sy), the spot being the seat; a grown-up sitting (mkPersona with sent = 1): column 24 and the lap row, the bottom of the hips: row 16 + 2 t + 3 (t 11 a grown-up: 41; t 7 a child: 33) on (sx, sy), the spot being the seat\'s top (the músicos on their stools: z ' + r4(S.h + SEAT_Z) + '); a small thing: see spot. The camera on the frog\'s chest: things.camara.px from the frog\'s spot. Nobody is drawn turned: whoever sits faces us',
      view: 'one window, wide, zoom 1: the 196 x 216 window over the 240 x 216 picture, x0 = its left edge (22 centres it). Never a fraction',
      depth: 'a spot\'s depth is the engine\'s d of its world point; front.plane turns it into the depth of each row of a character',
    },
    setKey: { params: {}, key: '', baked: [], note: 'one state: the set draws one frame (nothing sways: window.DEPTH.z is the baked depth). The sheet\'s numbers are read from the set as it is' },
    things,
    spots,
    groups: {
      taburetes: ['taburete1', 'taburete2'], atril: ['guitarra_atril', 'tambor_atril'], notas: ['nota1', 'nota2', 'nota3'], pista: ['pista1', 'pista2', 'pista3', 'pista4', 'pista5', 'pista6'], banco: ['banco1', 'banco2', 'banco3', 'banco4'],
      espera: ['espera1', 'espera2', 'espera3'], ronda: { ronda1: 'ronda1', ronda2: 'ante_micro', ronda3: 'banco3', ronda4: 'ronda4', ronda5: 'ronda5' },
      touch: { escenario: 'escenario', guitarra: 'guitarra_atril', tambor: 'tambor_atril', microfono: 'microfono', pista: 'pista', banco: 'banco', camara: 'camara', nota1: 'nota1', nota2: 'nota2', nota3: 'nota3', musico1: 'taburete1', musico2: 'taburete2', abuela: 'junto_escenario', abuelo: 'ante_micro', luis: 'espera2', carmen: 'pista_baile', coqui: 'centro_coqui' },
    },
    moves,
    notes: [
      'every number of a spot is the orchestrator\'s (the p10-spec, "musica"), given in (u, v, z); the stage, the stools, the rack, the microphone\'s place, the notes\' places, the bench, the floor stool and the dance floor are read from the set (MUSICA.E)',
      'things: escenario, pista and banco are set things with a box on the picture (the stage; the FLOOR rectangle; the whole bench, seat and back: an open point, the spec gives no box); guitarra, tambor, microfono and nota1 to nota3 are sprites with the box of the spot of their name (guitarra: guitarra_atril, tambor: tambor_atril); camara is a 10 x 8 px box on the frog\'s chest (things.camara.px from his spot); guitarra_rodillas (the guitar across the knees in moment 2) is NOT in the spec as a spot: made for the preview; the people are sprites',
      'whoever sits (taburete1, taburete2, banco1 to banco4, banqueta_abuela) is hung by the lap on the seat\'s top; the músicos are stand-ins (kit\'s mkPersona with a hat or a beard drawn on, colours of their own), as are the other grown-ups (kit\'s mkPersona); abuela, abuelo, Luis, Carmen and the frog are today\'s makers',
      'story 113\'s five (moment 4): ronda1, ronda4 and ronda5 are grown-up stand-ins (the tallest, so the checks hold for any child), ronda2 is ante_micro (abuelo at the microphone), ronda3 is banco3 (sitting on the bench); the spec says "drawn from the family and the people of every place"',
      'the spec gives no shadow radii for this scene: El cruce\'s are used (frog .45, grown-ups .35, children .28); (open point)',
      'in moments 3 and 4 the spec lists the músicos and no instruments: the rack is empty and their hands are empty (the instruments are in their hands in the game, not drawn here)',
      'the view\'s x0: the x0 that holds every spot (a person with his sprite whole, a small thing with its box), the one nearest the window centred on the picture (views.wide.what; check views-x0)',
      moves.length ? 'moves: ' + moves.map(m => m.spot + ' [' + m.spec + '] -> [' + m.now + '] (' + m.why + ')').join('; ') : 'no spot of the spec was moved',
    ],
    views,
    front: {
      list: null,
      how: 'no list. A character is hidden by every set pixel that is nearer the camera than the character\'s feet (depth test against the baked depth, with the feet\'s depth plus 0.3): the stage\'s front, the bench and the stools hide what is behind them by more than the bias. A thing that hangs is the plane through its spot.',
      bias: BIAS,
      plane: 'for the character\'s pixel on picture row r (r = 0 at the top): depth(r) = d + (sy - (r + .5)) * tan(30 deg) / S, where d is the spot\'s depth and sy its screen row; the pixel is hidden where bakedZ[r * 240 + x] > depth(r) + bias (bakedZ: window.DEPTH.z of the set page). The upright plane through the feet; a thing that hangs from its top middle has its plane through the same point (a pixel below the point is nearer the ground by the same slope)',
      sprites: 'between two sprites the nearer pixel wins: the same depth(r), no bias; two planes within ' + EPS + ' are a tie and the later layer is drawn',
    },
    shadows: {
      radius: { coqui: .45, adultos: .35, ninos: .28 },
      byCharacter: { coqui: .45, abuela: .35, abuelo: .35, musico1: .35, musico2: .35, luis: .28, carmen: .28 },
      at: 'castShadow(x, y, 0, radius) at the world x, y of the spot, for a character standing on the floor (z 0). The spec gives no radius: these are El cruce\'s (frog .45, grown-ups .35, children .28) (open point)',
      none: DEF.filter(d => d.uvz[2] > 0).map(d => d.name),
      onSeat: 'whoever sits on a stool or the bench, or stands on the stage (z above 0) casts none: none of those is floor (a shadow cast at the floor under them would show in front of them); the things that hang cast none; the microphone casts none (a sprite on the floor: open point)',
    },
  };
}

/* ---------- the checks that read the set's own pixels ---------- */
async function probeSets(page, sheet, G) {
  // the spots' pixels: what the set drew at each spot's feet (the baked depth and the part)
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

function checks(sheet, G, probes, PV) { return checksAsync(sheet, G, probes, PV); }
async function checksAsync(sheet, G, probes, PV) {
  const S = sheet.spots, T = sheet.things, V = sheet.views, OUTS = [], E = G.E, SIL = PV.sil;
  const add = (name, bad, okLine, failLines) => { const o = { name, ok: !bad.length, lines: bad.length ? [name + ': ' + failLines[0], ...failLines.slice(1)] : [name + ': ' + okLine] }; OUTS.push(o); return o; };
  const x0 = V.wide.x0, key = (x, y) => y * G.W + x;
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
  const axisTxt = (r, at) => ['u', 'v', 'z'].map(a => r.axis[a] ? a + ' ' + S[at].uv[['u', 'v', 'z'].indexOf(a)] + ' -> ' + r.axis[a].to + ' (' + sgn(r.axis[a].d) + ')' : a + ': none within 3').join('; ');
  const layerName = l => l.at + (l.thing ? ' (' + l.thing + ')' : '');
  const names = L => L.filter(l => l.who).map(l => l.at).join(', ');

  // 1. the view: x0 holds every spot (a person with his sprite whole, a small thing with its box)
  {
    const v = V.wide, bad = [], out = v.holds.map(k => [k, cutAt(S[k], v.x0)]).filter(o => o[1]);
    for (const o of out) bad.push(o[0] + ' ' + S[o[0]].screen + ' is cut by ' + o[1] + ' px at x0 ' + v.x0);
    const o = add('views-x0', bad, 'wide: x0 ' + v.x0 + ' (window columns ' + v.x0 + ' to ' + (v.x0 + 195) + '); the ' + v.holds.length + ' spots held span columns ' + v.extent[0] + ' to ' + v.extent[1] + ' (' + (v.extent[1] - v.extent[0] + 1) + ' of the window\'s 196); x0 that hold them all: ' + (v.x0Range ? v.x0Range[0] + ' to ' + v.x0Range[1] : 'none') + ' (the one nearest 22, the window centred on the picture)', [bad.length + ' spot(s) cut by the window:'].concat(bad.map(b => '  ' + b)));
    o.x0 = { wide: v.x0 };
  }

  // 2. every spot inside the picture, and inside the window with its sprite whole (a person's box: the frog 32 wide, a grown-up 24, a child 24; and his rows from the drawn silhouette; a small thing's box)
  {
    const bad = [], names2 = [];
    for (const [k, s] of Object.entries(S)) {
      const [sx, sy] = s.screen, sil = s.sprite ? SIL[s.sprite] : null;
      let top, bottom; const [a, b] = colsOf(s);
      if (s.box) { top = s.box[1]; bottom = s.box[1] + s.box[3] - 1; } else if (sil) { top = sy + sil.box[1]; bottom = sy + sil.box[3]; } else { top = sy; bottom = sy; }
      const cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), cutT = Math.max(0, -top), cutB = Math.max(0, bottom - (G.H - 1));
      const picL = Math.max(0, -a), picR = Math.max(0, b - (G.W - 1)), pOut = sx < 0 || sx >= G.W || sy < 0 || sy >= G.H;
      const cut = [cutL && ('left ' + cutL), cutR && ('right ' + cutR), cutT && ('top ' + cutT), cutB && ('bottom ' + cutB)].filter(Boolean);
      names2.push(k);
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
    const left = Object.entries(S).sort((p, q) => colsOf(p[1])[0] - colsOf(q[1])[0])[0], right = Object.entries(S).sort((p, q) => colsOf(q[1])[1] - colsOf(p[1])[1])[0];
    const o = add('spots-in-view', bad, names2.length + ' spots (persons with their sprite, small things with their box) inside the ' + G.W + ' x ' + G.H + ' picture and the window (x0 ' + x0 + '); the leftmost column any takes is ' + colsOf(left[1])[0] + ' (' + left[0] + '), the rightmost ' + colsOf(right[1])[1] + ' (' + right[0] + ')', [bad.length + ' spot(s) outside, or cut:'].concat(bad.map(b => '  ' + b), hints));
    const inkCut = [];                                   // info: the real drawn ink of today's makers against the window (the spec's width is the rule)
    for (const [k, s] of Object.entries(S)) { const sil = s.sprite ? SIL[s.sprite] : null; if (!sil) continue; const a = s.screen[0] + sil.box[0], b = s.screen[0] + sil.box[2], l = Math.max(0, x0 - a), r = Math.max(0, b - (x0 + 195)); if (l || r) inkCut.push(k + ' (' + s.sprite + ' ink columns ' + a + ' to ' + b + ': ' + (l ? l + ' px left' : r + ' px right') + ' of the window)'); }
    o.lines.push('       info, not a check (the real drawn ink of today\'s makers against the window; the spec\'s width is the rule): ' + (inkCut.join('; ') || 'no sprite\'s ink is cut'));
  }

  // 3. the spots above the floor are on what the set draws: a stool's top, the stage's top, the bench's seat, the floor stool's top (part patio, depth within .1 of the spot's)
  const surf = [];
  {
    const bad = [], lines = [], px = probes.spotsPx;
    for (const [k, s] of Object.entries(S)) {
      if (!s.on || s.on === 'ground' || s.on === 'air') continue;
      const best = (px[k] || []).filter(r => Math.abs(r.dx) <= 1 && r.dy >= -1 && r.dy <= 1).map(r => ({ r, dz: Math.abs(r.z - s.depth) })).sort((a, b) => a.dz - b.dz)[0], tag = s.on;
      const ok = best && best.r.tag === tag && best.dz < .1;
      lines.push(k + ' z ' + s.uv[2] + ': part ' + (best ? best.r.tag + ', depth ' + r2(best.r.z) + ' against the spot\'s ' + r2(s.depth) + ' (' + r2(best.dz) + ')' : 'none')); surf.push(k);
      if (!ok) bad.push(k + ' ' + s.screen + ' z ' + s.uv[2] + ' is not on a surface the set draws (' + tag + '): ' + (best ? 'the nearest pixel is part ' + best.r.tag + ' at depth ' + r2(best.r.z) + ', the spot\'s is ' + r2(s.depth) : 'no pixel in the picture'));
    }
    const o = add('spots-on-surface', bad, surf.length + ' spots above the floor (' + surf.join(', ') + ') are on a surface the set draws (the stools\' tops on the stage z ' + r4(E.STAGE.h + SEAT_Z) + ', the stage\'s top z ' + E.STAGE.h + ', the bench\'s seat and the floor stool z ' + SEAT_Z + ': part patio, depth within .1 of the spot\'s)', ['spots off their surface:'].concat(bad).map((l, i) => i ? '  ' + l : l));
    for (const l of lines) o.lines.push('       ' + l);
  }

  // 4. the set things' boxes (and the held things' boxes) are inside the picture and the window
  {
    const bad = [], lines = [];
    for (const [k, t] of Object.entries(T)) {
      if (t === 'sprite') continue;
      const b = t.box, l = x0 - b[0], r = b[0] + b[2] - (x0 + 196), tp = -b[1], bt = b[1] + b[3] - G.H, pl = -b[0], pr = b[0] + b[2] - G.W;
      lines.push(k + ' [' + b + ']');
      if (l > 0 || r > 0 || tp > 0 || bt > 0 || pl > 0 || pr > 0) bad.push('thing ' + k + ' box [' + b + '] is outside the window [' + x0 + ', ' + (x0 + 196) + ') or the picture' + (l > 0 ? ' by ' + l + ' left' : '') + (r > 0 ? ' by ' + r + ' right' : '') + (tp > 0 ? ' by ' + tp + ' top' : '') + (bt > 0 ? ' by ' + bt + ' bottom' : ''));
    }
    add('things-in-view', bad, 'the boxes of ' + lines.map(l => l.split(' ')[0]).join(', ') + ' are inside the window [' + x0 + ', ' + (x0 + 196) + ') and the picture (' + lines.join(', ') + ')', ['things outside:'].concat(bad).map((l, i) => i ? '  ' + l : l));
  }

  // 5. sprites-apart: the people who stand together in a moment: the sprite boxes (the frog 32, a grown-up 24, a child 24; the feet's spot in the middle) do not overlap sideways unless their feet are 12 px or more apart up-down
  {
    const bad = [], per = [], all = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers.filter(l => l.who);
      for (let i = 0; i < L.length; i++) for (let j = i + 1; j < L.length; j++) {
        const a = L[i], b = L[j], half = (WIDTH[a.who] + WIDTH[b.who]) / 2, dx = Math.abs(a.sx - b.sx), dy = Math.abs(a.sy - b.sy), over = dx < half, ok = !over || dy >= UPDOWN;
        all.push({ m, a: a.at, b: b.at, dx, dy, half, over, ok });
        if (!ok) { hints.push({ m, a, b, half }); bad.push('moment ' + m + ': ' + a.at + ' [' + a.sx + ',' + a.sy + '] (' + WIDTH[a.who] + ' wide) ~ ' + b.at + ' [' + b.sx + ',' + b.sy + '] (' + WIDTH[b.who] + ' wide): ' + dx + ' px sideways (the boxes need ' + half + '), ' + dy + ' px up-down (needs ' + UPDOWN + '): short by ' + r2(half - dx) + ' px sideways or ' + (UPDOWN - dy) + ' px up-down'); }
      }
      per.push('m' + m + ' (' + names(PV.inspect[m].layers) + ')');
    }
    const pass = (other, half) => (sx, sy) => Math.abs(sx - other.sx) >= half || Math.abs(sy - other.sy) >= UPDOWN;
    const nearestOf = (name, ok) => {
      const s = S[name]; if (s.fixed) return 'fixed by the set (a seat): not moved';
      const res = [];
      for (const [ax, lab] of [[1, 'v'], [0, 'u']]) for (let n = 1; n <= 400; n++) { let f = null; for (const sg of [-1, 1]) { const q = s.uv.slice(); q[ax] = r4(q[ax] + sg * n * .01); const [sx, sy] = scrUV(G, q[0], q[1], q[2]); if (ok(sx, sy)) { f = lab + ' ' + s.uv[ax] + ' -> ' + q[ax] + ' (' + sgn(sg * n * .01) + ')'; break; } } if (f) { res.push(f); break; } }
      return res.length ? res.join(' or ') : 'none within 4';
    };
    const o = add('sprites-apart', bad, all.length + ' pairs in the 4 moments of the preview (' + per.join('; ') + '): no two sprite boxes overlap sideways unless their feet are ' + UPDOWN + ' px or more apart up-down; the pairs that do overlap sideways: ' + (all.filter(q => q.over).map(q => 'm' + q.m + ' ' + q.a + ' ~ ' + q.b + ' (' + q.dx + ' across, ' + q.dy + ' down)').join(', ') || 'none'),
      [bad.length + ' pair(s) with overlapping boxes and feet closer than ' + UPDOWN + ' px up-down (of ' + all.length + ' pairs in 4 moments):'].concat(bad.map(b => '  ' + b)));
    for (const h of hints) o.lines.push('       nearest passing, moment ' + h.m + ' ' + h.a.at + ' ~ ' + h.b.at + ': ' + h.a.at + ' ' + S[h.a.at].uv + ': ' + nearestOf(h.a.at, pass(h.b, h.half)) + '; or ' + h.b.at + ' ' + S[h.b.at].uv + ': ' + nearestOf(h.b.at, pass(h.a, h.half)));
    o.lines.push('       closest pair in each moment (px across / px down): ' + MOMENTS.map(m => 'm' + m + ' ' + (() => { const q = all.filter(x => x.m === m).sort((x, y) => (x.dx - x.half) - (y.dx - y.half))[0]; return q ? q.a + ' ~ ' + q.b + ' ' + q.dx + '/' + q.dy + ' (needs ' + q.half + ' across or ' + UPDOWN + ' down)' : 'none'; })()).join('; '));
    o.pairs = all.map(q => ({ moment: q.m, a: q.a, b: q.b, across: q.dx, down: q.dy, needAcross: q.half, ok: q.ok }));
  }

  // 6. frog-seen: the frog is never behind a person or a thing of the set: in every moment his whole drawing is seen (no pixel hidden by the set, outside the picture, or under a nearer sprite)
  {
    const bad = [], lines = [], fails = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L), fi = L.findIndex(l => l.who === 'coqui'), f = L[fi], c = coverOf(L, M, fi, L.map((l, i) => l.group === 'held' ? -1 : i).filter(i => i >= 0));      // what he wears (the camera) is part of him
      lines.push('m' + m + ' ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (f.px.length + f.out) + ' px, ' + c.hid + ' hidden by the set, ' + c.cov + ' under a nearer sprite' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + f.out + ' outside the picture');
      if (c.hid || c.cov || f.out) { bad.push('moment ' + m + ': the frog at ' + f.at + ' ' + [f.sx, f.sy] + ': ' + (c.hid + c.cov + f.out) + ' of his ' + (f.px.length + f.out) + ' px are not seen (' + c.hid + ' hidden by the set, ' + c.cov + ' under ' + (Object.keys(c.who).join(', ') || 'a sprite') + ', ' + f.out + ' outside the picture)'); fails.push([m, fi, c]); }
    }
    const o = add('frog-seen', bad, 'the frog is seen whole in all 4 moments (0 px covered by anything): ' + lines.join('; '), [bad.length + ' moment(s) where the frog is not seen whole:'].concat(bad.map(b => '  ' + b)));
    for (const [m, fi, c] of fails) {
      const M = PV.moment[m], specs = M.layers, r = await PV.nearest(M.set, specs, fi);
      o.lines.push('       nearest passing, moment ' + m + ' ' + specs[fi].at + ' ' + S[specs[fi].at].uv + ': ' + axisTxt(r, specs[fi].at));
      for (const w of Object.keys(c.who)) { const ci = idxAt(specs, w); if (ci < 0) continue; const q = await PV.nearestClear(M.set, specs, ci, [fi]); o.lines.push('       or move the one that covers him, moment ' + m + ' ' + w + ' ' + S[w].uv + ': ' + axisTxt(q, w)); }
    }
  }

  // 7. heads-clear: everyone who sits (the músicos in all four moments, the four on the bench in moment 2, banco3 and abuela on the floor stool in moment 4) is whole in the window and his head (the top 14 rows of the sprite) is covered by nobody and by nothing (no person, no thing, not the set)
  {
    const bad = [], lines = [], hints = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, M = planes(L);
      for (const [i, l] of L.entries()) {
        if (l.group !== 'head') continue;
        const [a, b] = colsOf(S[l.at]), cutL = Math.max(0, x0 - a), cutR = Math.max(0, b - (x0 + 195)), c = coverOf(L, M, i, null, [0, HEAD_ROWS]);
        lines.push('m' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ' (' + l.s + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set; window cut ' + (cutL + cutR) + ' px, ' + l.out + ' px outside the picture');
        if (cutL || cutR || l.out) bad.push('moment ' + m + ' ' + l.at + ': not whole in the window (' + (cutL + cutR) + ' px cut by the window, ' + l.out + ' px outside the picture)');
        if (c.cov || c.hid) { bad.push('moment ' + m + ' ' + l.at + ' ' + [l.sx, l.sy] + ': ' + (c.cov + c.hid) + ' of the ' + c.tot + ' px of his head (rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ') are not seen: ' + c.cov + ' covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), i, l.at, w]); }
      }
    }
    const o = add('heads-clear', bad, 'every person who sits (' + MOMENTS.map(m => 'm' + m + ': ' + PV.inspect[m].layers.filter(l => l.group === 'head').map(l => l.at).join(', ')).join('; ') + ') is whole in the window and his head (the top ' + HEAD_ROWS + ' rows) is covered by nobody and by nothing: ' + lines.length + ' heads, 0 px covered, 0 hidden by the set', [bad.length + ' problem(s) with the people who sit:'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, tat, cat] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment ' + m + ' (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
    o.lines.push('       info, not a check: ' + lines.join('; '));
  }

  // 8. rack-clear (moment 1): the guitar and the drum hang under the rack's bar, covered by nobody and by nothing, and the frog at borde_coqui covers neither (moment 2: the drum, info)
  {
    const bad = [], lines = [], hints = [];
    for (const m of [1]) {
      const L = PV.inspect[m].layers, M = planes(L), fi = idxAt(L, 'borde_coqui');
      for (const at of ['guitarra_atril', 'tambor_atril']) {
        const i = idxAt(L, at), c = coverOf(L, M, i, null), box = S[at].box, n = shownIn(L, fi, box), fr = coverOf(L, M, i, [fi]);
        lines.push('m' + m + ' ' + at + ' [' + box + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture; the frog: ' + fr.cov + ' px of it under him, ' + n + ' px of his in its box');
        if (c.cov || c.hid || c.out || n) { bad.push('moment ' + m + ' ' + at + ': ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture; ' + n + ' px of the frog at borde_coqui lie in its box [' + box + ']'); hints.push([m, i, at]); }
      }
    }
    const o = add('rack-clear', bad, 'in moment 1 the guitar (guitarra_atril [' + S.guitarra_atril.box + ']) and the drum (tambor_atril [' + S.tambor_atril.box + ']) hang under the rack\'s bar (z ' + S.guitarra_atril.uv[2] + ') covered by nobody and by nothing (0 px covered, 0 hidden by the set), and the frog at borde_coqui ' + S.borde_coqui.screen + ' covers neither (no pixel of his in their boxes): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, i, at] of hints) { const M = PV.moment[m], fi = idxAt(M.layers, 'borde_coqui'), r = await PV.nearestFree(M.set, M.layers, fi, [S.guitarra_atril.box, S.tambor_atril.box]); o.lines.push('       nearest passing, moment ' + m + ' (' + at + '): the frog borde_coqui ' + S.borde_coqui.uv + ': ' + axisTxt(r, 'borde_coqui')); }
    const L2 = PV.inspect[2].layers, M2 = planes(L2), i2 = idxAt(L2, 'tambor_atril'), c2 = coverOf(L2, M2, i2, null);
    o.lines.push('       info, not a check: m2 tambor_atril ' + c2.tot + ' px, ' + c2.cov + ' covered, ' + c2.hid + ' hidden by the set');
  }

  // 9. notes-clear (moment 3): the three paper notes are inside the picture (and the window) and covered by nobody (and by nothing)
  {
    const bad = [], lines = [], m = 3, L = PV.inspect[m].layers, M = planes(L);
    for (const i of [1, 2, 3]) {
      const at = 'nota' + i, li = idxAt(L, at), c = coverOf(L, M, li, null), b = S[at].box, cut = cutAt(S[at], x0), pic = b[0] < 0 || b[1] < 0 || b[0] + b[2] > G.W || b[1] + b[3] > G.H;
      lines.push(at + ' [' + b + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + cut + ' px cut by the window');
      if (c.cov || c.hid || c.out || cut || pic) bad.push('moment 3 ' + at + ' [' + b + ']: ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture, ' + cut + ' px cut by the window');
    }
    add('notes-clear', bad, 'in moment 3 the three paper notes (the top row of each at y ' + S.nota1.box[1] + ') are inside the picture and the window and covered by nobody (0 px covered, 0 hidden by the set): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
  }

  // 10. mic-clear (moments 3, 4): the microphone is covered by nobody and by nothing (the singer stands behind it: the microphone is in front of him, he cannot cover it); the singer's head (the top 14 rows) is clear
  {
    const bad = [], lines = [], hints = [];
    for (const m of [3, 4]) {
      const L = PV.inspect[m].layers, M = planes(L), mi = idxAt(L, 'microfono'), si = idxAt(L, 'ante_micro'), c = coverOf(L, M, mi, null), h = coverOf(L, M, si, null, [0, HEAD_ROWS]), mic = coverOf(L, M, si, [mi]);
      lines.push('m' + m + ' microfono [' + S.microfono.box + ']: ' + c.tot + ' px, ' + c.cov + ' covered' + (c.cov ? ' by ' + whoTxt(c) : '') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture; the singer (ante_micro ' + [L[si].sx, L[si].sy] + ') head rows ' + h.top + ' to ' + (h.top + HEAD_ROWS - 1) + ': ' + h.tot + ' px, ' + h.cov + ' covered' + (h.cov ? ' by ' + whoTxt(h) : '') + ', ' + h.hid + ' hidden by the set (the microphone covers ' + mic.cov + ' px of the singer\'s body, none of his head)');
      if (c.cov || c.hid || c.out) { bad.push('moment ' + m + ' microfono: ' + c.cov + ' px covered by ' + (whoTxt(c) || 'nobody') + ', ' + c.hid + ' hidden by the set, ' + c.out + ' outside the picture'); for (const w of Object.keys(c.who)) hints.push([m, idxAt(L, w), mi, w, 'microfono']); }
      if (h.cov || h.hid) { bad.push('moment ' + m + ' the singer\'s head: ' + h.cov + ' px covered by ' + (whoTxt(h) || 'nobody') + ', ' + h.hid + ' hidden by the set'); for (const w of Object.keys(h.who)) hints.push([m, idxAt(L, w), si, w, 'ante_micro head']); }
    }
    const o = add('mic-clear', bad, 'in moments 3 and 4 the microphone (microfono [' + S.microfono.box + ']) is covered by nobody and by nothing, and the singer\'s head (ante_micro, the top ' + HEAD_ROWS + ' rows) is clear: ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [m, ci, ti, cat, what] of hints) { const M = PV.moment[m], r = await PV.nearestClear(M.set, M.layers, ci, [ti]); o.lines.push('       nearest passing, moment ' + m + ' (' + what + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // 11. ronda-heads (moment 4): none of the five (ronda1, ante_micro, banco3, ronda4, ronda5) covers another's head (the top 14 rows); info: what else covers them
  {
    const bad = [], lines = [], hints = [], m = 4, L = PV.inspect[m].layers, M = planes(L), five = L.map((l, i) => l.five ? i : -1).filter(i => i >= 0);
    for (const i of five) {
      const c = coverOf(L, M, i, five, [0, HEAD_ROWS]), any = coverOf(L, M, i, null, [0, HEAD_ROWS]);
      lines.push(L[i].five + ' (' + L[i].at + ' ' + [L[i].sx, L[i].sy] + '): head rows ' + c.top + ' to ' + (c.top + HEAD_ROWS - 1) + ': ' + c.tot + ' px, ' + c.cov + ' covered by the other four' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + '; by anyone ' + any.cov);
      if (c.cov) { bad.push('moment 4 ' + L[i].five + ' (' + L[i].at + '): ' + c.cov + ' px of his head are covered by ' + whoTxt(c)); for (const w of Object.keys(c.who)) hints.push([idxAt(L, w), i, w, L[i].at]); }
    }
    const o = add('ronda-heads', bad, 'in moment 4 none of the five (' + five.map(i => L[i].five + ' ' + L[i].at).join(', ') + ') covers another\'s head (the top ' + HEAD_ROWS + ' rows): ' + lines.join('; '), [bad.length + ' problem(s):'].concat(bad.map(b => '  ' + b)));
    for (const [ci, ti, cat, tat] of hints) { const M4 = PV.moment[m], r = await PV.nearestClear(M4.set, M4.layers, ci, [ti], [0, HEAD_ROWS]); o.lines.push('       nearest passing, moment 4 (the head of ' + tat + ' covered by ' + cat + '): ' + cat + ' ' + S[cat].uv + ': ' + axisTxt(r, cat)); }
  }

  // info: the things he can touch that the spec lists no check for (the camera on the frog's chest, the stage, the floor, the bench), the people over them: not checks of the spec
  {
    const lines = [];
    for (const m of MOMENTS) {
      const L = PV.inspect[m].layers, parts = [];
      for (const n of ['escenario', 'pista', 'banco']) { let k = 0; for (const [i, l] of L.entries()) if (l.who) k += shownIn(L, i, T[n].box); parts.push(n + ' [' + T[n].box + '] ' + k + ' px under people'); }
      const ci = L.findIndex(l => l.thing === 'camara');
      if (ci >= 0) { const M = planes(L), c = coverOf(L, M, ci, L.map((l, i) => l.who === 'coqui' ? -1 : i).filter(i => i >= 0)); parts.push('camara ' + c.cov + ' of ' + c.tot + ' px covered by anyone but the frog' + (c.cov ? ' (' + whoTxt(c) + ')' : '') + ', ' + c.hid + ' hidden by the set'); }
      lines.push('m' + m + ': ' + parts.join(', '));
    }
    OUTS.push({ name: 'info-touch', ok: true, lines: ['info-touch: not a check. ' + lines.join('; ')] });
  }
  return OUTS;
}
