#!/usr/bin/env node
'use strict';
/* El frente's sheet (order 07): writes docs/proyecto/pixel/frente-sheet.json from frente-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/frente-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.FRENTE) from frente-set.html in headless Chrome, projects every world point with the engine's own
   formula, and checks the sheet against coqui/ref/escenas/frente/ (positions.json, inventory.json). A second run writes the same bytes.
   Every name a builder needs for a screen position of historia/escenas/frente.js is in `code`, by line. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'frente-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/frente');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.goto('file://' + path.join(__dirname, 'frente-set.html') + '?hide=1');
  const G = await page.evaluate(() => { const o = {}; for (const [k, v] of Object.entries(FRENTE)) if (typeof v !== 'function' && k !== 'SET') o[k] = v; return { F: o, scene: PP_SCENE, W, H, S }; });
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const sheet = make(G);
  const text = JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';
  fs.writeFileSync(OUT, text);
  const problems = check(sheet);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + text.length + ' bytes)');
  if (problems.length) { console.log('CHECK FAILED:\n  ' + problems.join('\n  ')); process.exit(1); }
  console.log('check: all 14 things, every positions.json entry in remap, every LUGAR and CAM name, every frente.js position in code, every box near the picture: ok');
})().catch(e => { console.error(e); process.exit(1); });

/* ---------- the engine's projection, as pp-engine.js has it (the same operations in the same order) ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S }; };
  // the world point on the plane y = c (a +y wall) that lands on screen (sx, sy)
  const onWallY = (sx, sy, c) => { const x = (sx - OX) * R2 / S + c; return [x, c, ((x + c) / R2 * SIN - (sy - OY) / S) / COS]; };
  // the world point at height z that lands on screen (sx, sy)
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  return { W, H, S, R2, project, onWallY, atZ };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);

function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2]); return [r2(q.sx), r2(q.sy)]; };
  const box = w => { const xs = [], ys = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) { const q = E.project(x, y, z); xs.push(q.sx); ys.push(q.sy); }
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0]; };
  const doorMid = (F.DOOR0 + F.DOOR1) / 2, winMid = (F.WIN0 + F.WIN1) / 2;
  const pathAt = d => { const u = F.PATH_U, v = F.PATH_V + d; return [(u + v) / E.R2, (v - u) / E.R2, 0]; };   // the path's middle line, d units below the step

  /* ---- the world points everything is placed from ---- */
  const winC = [winMid, F.HY1, (F.WZ0 + F.WZ1) / 2], doorC = [doorMid, F.HY1, F.FLOOR + F.DH / 2];
  const birdHole = [F.BIRD[0], F.BIRD[1] + .25, 1.55];
  const SPOTS = {
    // the frog: the ground under his feet. q.x = round(sx) - 16, q.y = round(sy) - 25 (frogBox: his middle is q.x + 16, his shadow line q.y + 25)
    inicio: { world: pathAt(3.55), scale: 1, old: [150, 178], what: 'where every story starts: on the path, near the bottom (juego.js:16 fresh(), cq x 150 y 178 s 1)' },
    patio: { world: pathAt(1.8), scale: .86, old: [123, 150], what: 'LUGAR.patio: on the path in front of the house (also cual.js:21, the frog of every pair picture)' },
    puerta: { world: [doorMid - .2, F.HY1 + .62, F.FLOOR], scale: .72, old: [150, 104], what: 'LUGAR.puerta and LUGAR.casa_grande: on the porch, before the door' },
    ventana: { world: [winMid + .05, F.HY1 + .62, F.FLOOR], scale: .72, old: [96, 104], what: 'LUGAR.ventana: on the porch, under the window' },
    palma_grande: { world: [F.PALM[0] + .55, F.PALM[1] - .05, 0], scale: .74, old: [38, 100], what: 'LUGAR.palma_grande: at the foot of the big palm' },
    palma_pequena: { world: [F.SPALM[0] - .55, F.SPALM[1] + .5, 0], scale: .88, old: [150, 150], what: 'LUGAR.palma_pequena: beside the small palm' },
    casa_pequena: { world: [F.BIRD[0] + .5, F.BIRD[1] - .15, 0], scale: .86, old: [86, 150], what: 'LUGAR.casa_pequena: beside the birdhouse' },
    'puerta.dentro': { world: [doorMid, F.HY1 - .25, F.FLOOR], scale: .72, old: [150, 80], what: 'entra por la puerta: hopTo(150,80,2,.72), just inside the doorway' },
    'puerta.escondido': { world: [doorMid - .1, F.HY1 - .45, F.FLOOR], scale: .6, old: [150, 82], what: 'esconde casa_grande: hopTo(150,82,1,.6), behind the door' },
    'ventana.dentro': { world: [winMid, F.HY1 - .05, F.WZ0], scale: .46, old: [98, 58], what: 'entra por la ventana: the jump ends on the sill (q.x 98, q.y 58, s .46)' },
    'casa_pequena.dentro': { world: [birdHole[0], birdHole[1], birdHole[2] - .3], scale: .5, old: [58, 104], what: 'esconde casa_pequena: the frog goes half way to (58,104) four times, into the birdhouse' },
    hola: { world: [doorMid - .35, F.HY1 + .78, F.FLOOR], scale: .62, old: [146, 86], what: 'pairs hola.si / adiós.no: the frog at the door, waving (cq x 146 y 86 s .62)' },
    adios: { world: pathAt(1.15).map((v, i) => i === 0 ? v + .9 : i === 1 ? v - .9 : v), scale: .85, old: [176, 116], what: 'pairs hola.no / adiós.si: the frog going away from the door (cq x 176 y 116 s .85)' },
    // abuela: the ground under her feet; her sprite is drawn at (round(sx) - 30, round(sy) - 49) (anchor (30, 49) in her 48 x 51 sprite)
    'abuela.puerta': { world: [doorMid, F.HY1 + .1, F.FLOOR], old: [135, 55], what: 'ABAT.puerta: in the doorway (and where she peeks from, behind the half-open door)' },
    'abuela.paso': { world: [F.DOOR0 - .5, F.HY1 + .4, F.FLOOR], old: [94, 57], what: 'ABAT.paso: on the porch, left of the door (story 3, with her plate)' },
  };
  for (const s of Object.values(SPOTS)) s.world = W4(s.world);
  const screenOf = (name) => P(SPOTS[name].world);
  const frogQ = name => { const s = screenOf(name); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const abDraw = name => { const s = screenOf(name); return [Math.round(s[0]) - 30, Math.round(s[1]) - 49]; };

  /* ---- translation frames: an old anchor and the new place of the same thing; every old point of the frame moves by the same amount ---- */
  const FRAMES = {
    ventana: { old: [112, 71], world: W4(winC), what: 'the window opening, its middle (old opening [97,61,30,20])' },
    puerta: { old: [166, 78], world: W4(doorC), what: 'the doorway, its middle (old opening [153,53,26,51])' },
    'abuela.puerta': { old: [135, 55], spot: 'abuela.puerta', what: 'abuela in the doorway: where her sprite is drawn' },
    'abuela.paso': { old: [94, 57], spot: 'abuela.paso', what: 'abuela on the porch: where her sprite is drawn' },
    palma: { old: [56, 52], world: W4(F.PALM_TOP), what: 'the big palm\'s crown' },
    palmita: { old: [195, 132], world: W4(F.SPALM_TOP), what: 'the small palm\'s crown' },
    casita: { old: [73, 126], world: W4(birdHole), what: 'the birdhouse\'s round hole' },
    // the right part of the window, for the last picture of story 1 and the cake: the frog (and his towel and drops) and the table
    // sit 2 px right of and 3 px lower than the plain window offset, so the frog with his towel is wholly inside the opening
    'ventana.lado': { old: [112, 71], world: W4(winC), nudge: [2, 3], what: 'beside abuela in the window: the frog (cq.42), his towel and drops, the cake table and its steam' },
  };
  for (const f of Object.values(FRAMES)) {
    f.screen = f.spot ? abDraw(f.spot) : P(f.world);
    const n = f.nudge || [0, 0];
    f.offset = [Math.round(f.screen[0] - f.old[0]) + n[0], Math.round(f.screen[1] - f.old[1]) + n[1]];
  }
  const viaFrame = (fr, old) => [old[0] + FRAMES[fr].offset[0], old[1] + FRAMES[fr].offset[1]];

  /* ---- named points: each old literal of frente.js gets one ---- */
  const PTS = {};
  const pt = (name, def) => { PTS[name] = def; };
  // the bird: (x, y) is under its feet (drawAve draws its bottom at y + 2)
  pt('ave.ventana.posa', { world: [winMid, F.HY1 + .06, F.WZ1 + .14], old: [112, 57], what: 'PERCH.ventana: on top of the window frame' });
  pt('ave.puerta.posa', { world: [doorMid + .1, F.HY1 + F.EAVE - .02, F.HH + .03], old: [166, 49], what: 'PERCH.puerta: on the edge of the roof, over the door (the door frame\'s top is under the eave: the bird would hide in it)' });
  pt('ave.ventana.hueco', { world: winC, old: [112, 71], what: 'HOLE.ventana: the middle of the window (it bonks, it flies in, the slice comes out)' });
  pt('ave.puerta.hueco', { world: [doorMid, F.HY1, F.FLOOR + F.DH * .45], old: [166, 80], what: 'HOLE.puerta and SPOT.casa_grande: the middle of the door' });
  pt('ave.palma', { world: [F.PALM_TOP[0], F.PALM_TOP[1], F.PALM_TOP[2] + .05], old: [56, 52], what: 'SPOT.palma_grande: in the big palm\'s crown' });
  pt('ave.palmita', { world: [F.SPALM_TOP[0], F.SPALM_TOP[1], F.SPALM_TOP[2] + .05], old: [195, 132], what: 'SPOT.palma_pequena: in the small palm\'s crown' });
  pt('ave.casita', { world: [birdHole[0], birdHole[1] + .12, birdHole[2] - .17], old: [73, 129], what: 'SPOT.casa_pequena: at the birdhouse\'s hole, on its perch' });
  pt('ave.casita.techo', { world: [F.BIRD[0], F.BIRD[1], 2.1], old: [73, 112], what: 'busca_ave casa_pequena: on the birdhouse\'s roof' });
  pt('ave.casita.entra', { world: birdHole, old: [73, 126], what: 'avecasa: into the birdhouse\'s hole' });
  pt('ave.puerta.lado', { world: [F.DOOR1 + .3, F.HY1 + .35, F.FLOOR], old: [176, 100], what: 'busca_ave casa_grande: on the porch beside the door' });
  pt('ave.techo', { world: [F.HX1 - .3, (F.HY0 + F.HY1) / 2, F.HH + F.RISE], old: [196, 30], what: 'fin2: on the roof\'s ridge, right end' });
  pt('ave.cesped', { world: [F.HX1 + 1.6, F.HY1 + .9, 0], old: [196, 120], what: 'tapate: on the lawn right of the porch, where it sits with a wing over its eyes' });
  // the hand sign and the heart
  pt('mano.casa', { world: [doorMid - 1.1, F.HY1 - .35, F.HH + F.RISE * .55], old: [141, 24], what: 'handAt.casa and handAt.casa_grande: on the roof' });
  pt('mano.puerta', { world: doorC, old: [166, 76], what: 'handAt.puerta, and abuela\'s hand fallback: the middle of the door' });
  pt('mano.ventana', { world: winC, old: [112, 72], what: 'handAt.ventana: the middle of the window' });
  pt('mano.casa_pequena', { world: [F.BIRD[0], F.BIRD[1], 1.5], old: [73, 128], what: 'handAt.casa_pequena: the birdhouse' });
  pt('mano.palma_grande', { world: [F.PALM_TOP[0], F.PALM_TOP[1], F.PALM_TOP[2] - .25], old: [56, 60], what: 'handAt.palma_grande: the big palm\'s crown' });
  pt('mano.palma_pequena', { world: [F.SPALM_TOP[0], F.SPALM_TOP[1], F.SPALM_TOP[2] - .25], old: [195, 140], what: 'handAt.palma_pequena: the small palm\'s crown' });
  // translated through a frame: the screen point is old + the frame's offset; the world point lies on the frame's plane
  const fpt = (name, fr, old, what, nudge) => { const s0 = viaFrame(fr, old), s = nudge ? [s0[0] + nudge[0], s0[1] + nudge[1]] : s0, fw = FRAMES[fr];
    const world = fw.spot ? E.atZ(s[0], s[1], SPOTS[fw.spot].world[2] + 1.2) : fr === 'ventana' || fr === 'puerta' ? E.onWallY(s[0], s[1], F.HY1) : E.atZ(s[0], s[1], fw.world[2]);
    pt(name, Object.assign({ frame: fr, old, world, what }, nudge ? { nudge } : {})); };
  fpt('corazon', 'ventana', [103, 26], 'heartAt: the heart over the window in the last picture of story 1 (cuadro)');
  fpt('abuela.ventana', 'ventana', [82, 61], 'ABAT.ventana: abuela\'s sprite behind the window (clipped to the opening)');
  fpt('abuela.ventana.mesa', 'ventana', [75, 61], 'abuela behind the window when W.tab or W.mesa (the frog or the cake beside her): 3 px right of the plain window offset, so her head is wholly inside the opening', [3, 0]);
  fpt('cq.ventana', 'ventana.lado', [112, 67], 'the frog beside her in the window (cq.42), 68 when wet: same offset');
  fpt('toalla', 'ventana.lado', [114, 62], 'the towel on his head in the window');
  fpt('globo.ventana', 'ventana', [112, 60], 'abuela\'s bubble in the window');
  fpt('dentro.ventana', 'ventana', [112, 59], 'her voice from behind the shut window (bubble quien)');
  fpt('habla.ventana', 'ventana', [112, 60], 'talkAt abuela in the window (y 38 with a bubble; x 105 with the cake): same offset');
  fpt('habla.dentro.ventana', 'ventana', [112, 37], 'talkAt abuela behind the shut window');
  fpt('mariposa.1', 'ventana', [98, 97], 'the pink butterfly\'s middle (ambient: 98 + 34 sin, 97 + 9 sin)');
  fpt('cq.asoma', 'puerta', [150, 84], 'the frog peeking from behind the half-open door (cq.6), clipped to puerta.hueco');
  fpt('dentro.puerta', 'puerta', [166, 53], 'her voice from behind the shut door (bubble quien)');
  fpt('habla.dentro.puerta', 'puerta', [166, 31], 'talkAt abuela behind the shut door');
  fpt('mariposa.2', 'puerta', [203, 72], 'the yellow butterfly\'s middle (ambient: 203 + 13 sin, 72 + 7 sin)');
  fpt('globo.puerta', 'abuela.puerta', [147, 69], 'abuela\'s bubble at the door, and on the porch (x 141, y 66 for como): same offset');
  fpt('habla.puerta', 'abuela.puerta', [156, 56], 'talkAt abuela at the door (y 47 with a bubble, x 141 for como): same offset');
  fpt('habla.paso', 'abuela.paso', [124, 56], 'talkAt abuela on the porch (y 40 with a bubble): same offset');
  for (const p of Object.values(PTS)) { p.world = W4(p.world); p.screen = p.frame ? viaFrame(p.frame, p.old).map((v, i) => v + (p.nudge ? p.nudge[i] : 0)) : P(p.world); }

  /* ---- things: the 14 touch keys ---- */
  const T = F.THINGS;
  const setThing = (world, hitPad, what, extra = {}) => { const hw = [world[0] - hitPad[0], world[1], world[2], world[3] + hitPad[0], world[4] + hitPad[1], world[5] + hitPad[2]];
    return Object.assign({ set: true, world: W4(world), box: box(world), hit: { world: W4(hw), box: box(hw) }, what }, extra); };
  const things = {
    abuela: { sprite: true, why: 'a character (today\'s sprite, drawn 1:1)', box: { puerta: { frame: 'abuela.puerta', old: [151, 56, 29, 49], new: shift([151, 56, 29, 49], FRAMES['abuela.puerta'].offset) }, paso: { frame: 'abuela.paso', old: [110, 58, 36, 50], new: shift([110, 58, 36, 50], FRAMES['abuela.paso'].offset) }, ventana: { clip: 'ventana.hueco', old: [97, 61, 30, 20], what: 'the window opening: clips[ventana.hueco].box' } } },
    palma_pequena: setThing(T.palma_pequena, [0, 0, 0], 'the small palm (story 3: shown when hide=1)', { old: { box: [174, 114, 42, 56], hit: [172, 112, 46, 60] } }),
    casa_pequena: setThing(T.casa_pequena, [.08, .08, 0], 'the birdhouse on its post (story 3: shown when hide=1)', { old: { box: [60, 110, 26, 58], hit: [58, 108, 30, 62] } }),
    palma_grande: setThing(T.palma, [0, 0, 0], 'the big palm, as a hiding place (story 3). The same world box as palma', { old: { box: [34, 34, 48, 72], hit: [34, 34, 48, 74] } }),
    casa_grande: setThing(T.casa, [0, 0, 0], 'the house, as a hiding place (story 3). The same world box as casa', { old: { box: [60, 17, 166, 90], hit: [57, 16, 171, 95] } }),
    pajaro: { sprite: true, why: 'it flies: the bird is today\'s sprite; its box stays relative to it (hit: |x - p[0]| < 16, p[1] - 24 < y < p[1] + 5)' },
    bizcocho: { hud: true, why: 'the plate in the corner of the display (hud), not in the picture. Its hit (frente.js:190) turns a picture point into display pixels with the old zoom (DW / cam[2]); with no zoom that is x - cam[0], y - cam[1]' },
    coqui: { sprite: true, why: 'a character (frogBox around today\'s sprite)' },
    nube: { sprite: true, sky: true, why: 'the storm cloud moves (W.nube.x eases to its tx): today\'s sprite, in the sky, at the same screen places as before (box [x, 0, 98, 22], hit [x - 2, 0, 102, 24])' },
    puerta: setThing(T.puerta, [0, 0, .12], 'the door with its frame; hit adds a little slack', { old: { box: [151, 51, 30, 54], hit: [145, 46, 42, 62] } }),
    ventana: setThing(T.ventana, [.03, .1, .1], 'the window with its frame, its shutters (open, flat on the wall) and the flower box; hit adds a little slack', { old: { box: [93, 57, 38, 28], hit: [82, 53, 61, 42] } }),
    casa: setThing(T.casa, [0, 0, 0], 'the house: walls and roof. Its hit replaces both old tests (the roof trapezoid, frente.js:195, and the wall rectangle, frente.js:196)', { old: { box: [60, 17, 166, 90], hit: 'roof: 16 <= y < 42, 88 - 30t <= x <= 196 + 30t (t = (y - 16) / 25); walls [57, 41, 171, 70]' } }),
    sol: { set: true, sky: true, screen: { circle: [210, 17, 12], box: [198, 5, 25, 25] }, why: 'the sun is baked into the sky (pale in a storm, none in the rain); the sky is screen space, so it stays where it was: hit (x-210)^2 + (y-17)^2 < 144, box [198, 5, 25, 25]' },
    palma: setThing(T.palma, [0, 0, 0], 'the big palm (stories 1 and 2: a free touch)', { old: { box: [34, 36, 30, 70], hit: [34, 36, 30, 70] } }),
  };

  /* ---- clips ---- */
  const quad = (a0, a1, z0, z1, y) => [[a0, y, z0], [a1, y, z0], [a1, y, z1], [a0, y, z1]].map(W4);
  const gapX = (() => { const w = F.DOOR1 - F.DOOR0, a = F.HALF_ANGLE, ex = F.DOOR1 + Math.cos(a) * w, ey = F.HY1 - .06 + Math.sin(a) * w; return (ex - ey) + F.HY1; })();   // the leaf's free edge, seen on the wall plane
  const clip = (thing, face, corners, what) => { const s = corners.map(P), xs = s.map(p => p[0]), ys = s.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return { thing, face, world: corners, screen: s, box: [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0], what }; };
  const clips = {
    'ventana.hueco': clip('ventana', 'opening', quad(F.WIN0, F.WIN1, F.WZ0, F.WZ1, F.HY1), 'the window opening on the front wall (old rect [97,61,30,20], frente.js:147): abuela, the cake table, the frog beside her, the towel are drawn inside it'),
    'puerta.hueco': clip('puerta', 'gap', quad(F.DOOR0, r4(gapX), F.FLOOR, F.FLOOR + F.DH, F.HY1), 'the gap between the left jamb and the half-open leaf (door=half), on the front wall (old rect [153,53,11,51], frente.js:143-144): who peeks from behind the door'),
  };

  /* ---- views ---- */
  const view = (world, what, old) => { const s = P(world); return { world: W4(world), screen: s, x0: Math.max(0, Math.min(44, Math.round(s[0] - 98))), old, what }; };
  const houseMid = [(F.HX0 + F.HX1) / 2 + .35, F.HY1, F.HH * .5];
  const views = {
    wide: view(houseMid, 'the house, the path and the sky: every story\'s usual view', [44, 0, 196, 216]),
    casa: view(houseMid, 'the house (the same window as wide: the house fits it whole)', [51.7, 15, 180.6, 199]),
    puerta: view(doorC, 'the door', [117, 30, 98, 108]),
    ventana: view(winC, 'the window', [84, 24, 98, 108]),
    cuadro: view(winC, 'story 1\'s last picture: abuela and the frog in the window, the heart over it', [63, 18, 98, 108]),
    'wide@donde-esta-el-pajaro': view([F.PALM[0] + 2.085, F.PALM[1] - 2.085, 0], 'story 3\'s own wide view (cam.wide in donde-esta-el-pajaro.json): the big palm, the house, the birdhouse and the small palm together', [30, 0, 196, 216]),
  };

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const crop = (world) => { const s = P(world); return [Math.max(0, Math.min(44, Math.round(s[0] - 98))), Math.max(0, Math.min(112, Math.round(s[1] - 52))), 196, 104]; };
  const patioQ = frogQ('patio'), resp = (() => { const s = .86, w = Math.round(30 * s) + 2, h = Math.round(25 * s) + 2, bx = Math.round(patioQ[0] + (32 - w) / 2), by = patioQ[1] + 27 - h;
    const cam0 = views.wide.x0, cx = Math.max(cam0 + 60, Math.min(cam0 + 196 - 60, bx + w / 2)), y = Math.max(4, by - 46); return [Math.round(cx - 50), y, 40, 36]; })();
  const respMid = E.atZ(resp[0] + 20, resp[1] + 18, 0);
  const R = (match, to) => ({ match, to });
  const RULES = [
    R(p => p.kind === 'cam' && p.x === 52 && p.y === 8, { point: 'casa.arriba', world: [(F.HX0 + F.HX1) / 2 + .35, F.HY0, F.HH], what: 'the house: its roof and walls (the top of the picture)' }),
    R(p => p.kind === 'cam' && p.x === 44 && p.y === 120, { point: 'patio.abajo', world: pathAt(4.6).map((v, i) => i === 0 ? v - 1.2 : i === 1 ? v + 1.2 : v), what: 'the yard with no house: the bottom of the picture, left (the house\'s foot still shows: see the report)' }),
    R(p => p.kind === 'cam' && p.x === 0 && p.y === 94, { point: 'casa_pequena', world: [F.BIRD[0] + .4, F.BIRD[1] - .4, 1], what: 'the birdhouse' }),
    R(p => p.kind === 'cam' && p.x === 135 && p.y === 46, { point: 'puerta', world: doorC, what: 'the door' }),
    R(p => p.kind === 'cam' && p.x === 55 && p.y === 46, { point: 'ventana', world: winC, what: 'the window' }),
    R(p => p.kind === 'cam' && p.x === 44 && p.y === 40, { point: 'puerta.cq', world: [doorMid - .1, F.HY1 + .5, F.FLOOR + .9], what: 'the door with the frog before it' }),
    R(p => p.kind === 'cam' && (p.x === 55 || p.x === 115) && p.y === 96, { point: 'respuesta', world: respMid, what: 'the answer bubble over the frog at patio (respBox with cam = wide); both sí and no pictures show their one bubble whole' }),
    R(p => p.kind === 'cam' && p.x === 30 && p.y === 0, { view: 'wide@donde-esta-el-pajaro', what: 'story 3\'s wide view' }),
    R(p => p.kind === 'crop' && p.x === 89.36, { point: 'ventana', world: winC, what: 'the window' }),
    R(p => p.kind === 'crop' && p.x === 143.36, { point: 'puerta', world: doorC, what: 'the door' }),
    R(p => p.kind === 'crop' && p.x === 112.91, { point: 'puerta.cq', world: [doorMid - .1, F.HY1 + .5, F.FLOOR + .9], what: 'the door with the frog before it' }),
    R(p => p.kind === 'x' && p.x === 112, { point: 'ventana', world: winC, what: 'the window: its middle x' }),
    R(p => p.kind === 'x' && p.x === 166, { point: 'puerta', world: doorC, what: 'the door: its middle x' }),
    R(p => p.kind === 'x' && p.x === 160, { point: 'puerta.cq', world: [doorMid - .1, F.HY1 + .5, F.FLOOR + .9], what: 'the door with the frog: its middle x' }),
    R(p => p.kind === 'point' && p.x === 146 && p.y === 86, { spot: 'hola' }),
    R(p => p.kind === 'point' && p.x === 176 && p.y === 116, { spot: 'adios' }),
    R(p => p.kind === 'point' && p.x === 0 && p.y === 0, { none: 'set.ave in mode head: x and y are not used (avePos puts the bird on the frog\'s head)' }),
  ];
  /* ---- the review and level pictures: each its own centre and a whole-number zoom (order 07, the orchestrator's decision) ---- */
  // zoom 1: the 196 x 104 window; zoom 2: a 98 x 52 region shown at 2 x 2 screen pixels per picture pixel. Never a fraction.
  const pic = (world, zoom, what) => { const s = P(world), crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(s[0] - 98))), Math.max(0, Math.min(112, Math.round(s[1] - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(s[0] - 49))), Math.max(0, Math.min(164, Math.round(s[1] - 26))), 98, 52];
    return { world: W4(world), screen: s, zoom, crop, what }; };
  const houseTop = [(F.HX0 + F.HX1) / 2 + .35, F.HY0, F.HH], doorUp = [doorMid, F.HY1, F.FLOOR + F.DH * .62];
  // the door alone and the window alone, close: centres put on the wall so that the 98 px wide region holds the one and not the other
  // (the door: its left edge 7 px inside the region's left side, its top in; the window: the region ends 7 px left of the door frame)
  const doorL = Math.min(...['puerta'].map(() => P([F.DOOR0 - .14, F.HY1, F.FLOOR + F.DH])[0]));
  const doorOnly = E.onWallY(Math.floor(doorL) - 7 + 49, P([doorMid, F.HY1, F.FLOOR + F.DH + .14])[1] - 4 + 26, F.HY1);
  const winOnly = E.onWallY(Math.floor(doorL) - 7 - 49, P(winC)[1] + 3, F.HY1);
  const yard = pathAt(3.3), birdC = [F.BIRD[0], F.BIRD[1], 1.15];
  const respC = E.atZ(resp[0] + 20, resp[1] + 18, 0);
  const PICS = {
    'casa.si': pic(houseTop, 1, 'the whole house, its roof at the top'),
    'casa.no': pic(yard, 2, 'the yard: the path and the lawn, no part of the house'),
    'puerta.si': pic(doorOnly, 2, 'the door, close: no window in it'),
    'puerta.no': pic(winOnly, 2, 'the window, close: no door in it'),
    'ventana.si': pic(winOnly, 2, 'the window, close: no door in it'),
    'ventana.no': pic(doorOnly, 2, 'the door, close: no window in it'),
    'abuela.si': pic(doorC, 1, 'the door with abuela in it'),
    'abuela.no': pic(doorC, 1, 'the shut door, nobody'),
    'abre.si': pic(winOnly, 2, 'the window, close: open, abuela in it'),
    'abre.no': pic(winOnly, 2, 'the window, close: shut'),
    'cierra.si': pic(doorUp, 2, 'the door, close: half shut, abuela behind it'),
    'cierra.no': pic(doorUp, 2, 'the door, close: open, abuela in it'),
    'hola.si': pic([doorMid - .1, F.HY1 + .5, F.FLOOR + .9], 1, 'the door with abuela and the frog: day, waving'),
    'hola.no': pic([doorMid - .1, F.HY1 + .5, F.FLOOR + .9], 1, 'the door at sunset, the frog going'),
    'adiós.si': pic([doorMid - .1, F.HY1 + .5, F.FLOOR + .9], 1, 'the door at sunset, the frog going'),
    'adiós.no': pic([doorMid - .1, F.HY1 + .5, F.FLOOR + .9], 1, 'the door with abuela and the frog: day, waving'),
    'sí.si': pic(respC, 2, 'the answer bubble, close: the frog nodding'),
    'sí.no': pic(respC, 2, 'the answer bubble, close: the frog shaking his head'),
    'no.si': pic(respC, 2, 'the answer bubble, close: the frog shaking his head'),
    'no.no': pic(respC, 2, 'the answer bubble, close: the frog nodding'),
    'grande.si': pic(houseTop, 1, 'the whole house'),
    'grande.no': pic(birdC, 2, 'the birdhouse, close'),
    'pequeña.si': pic(birdC, 2, 'the birdhouse, close'),
    'pequeña.no': pic(houseTop, 1, 'the whole house'),
  };
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'frente' ? { w: L.w, index: i, picture: p.pair + '.' + p.side, crop: PICS[p.pair + '.' + p.side].crop, zoom: PICS[p.pair + '.' + p.side].zoom, old: p.crop } : null).filter(Boolean));

  const remap = POS.positions.map(p => {
    const rule = RULES.find(r => r.match(p));
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (!rule) { e.to = null; return e; }
    const t = rule.to;
    if (t.spot) { e.to = { spot: t.spot }; e.screen = screenOf(t.spot); e.frog = frogQ(t.spot); e.scale = SPOTS[t.spot].scale; }
    else if (t.view) { e.to = { view: t.view }; e.x0 = views[t.view].x0; }
    else if (t.none) e.to = { none: t.none };
    else { e.to = { point: t.point, world: W4(t.world) }; e.screen = P(t.world); if (p.kind === 'cam' || p.kind === 'crop') e.crop = crop(t.world); else e.x = Math.round(e.screen[0]); }
    if (t.what) e.what = t.what;
    return e;
  });

  /* ---- the code: every screen position in historia/escenas/frente.js, by line ---- */
  const code = CODE();

  /* ---- the set's states and how W maps to them ---- */
  const setKey = {
    params: {
      door: { values: ['shut', 'half', 'open'], fromW: 'W.door: 0 shut, .5 half, 1 open' },
      win: { values: ['shut', 'open'], fromW: 'W.win: 0 shut, 1 open' },
      lights: { values: ['0', '1'], fromW: 'W.lamp (the lights inside; the old file calls it lamp, there is no porch lamp)' },
      sky: { values: ['day', 'storm', 'storm2', 'rain', 'dusk', 'sunset'], fromW: 'W.dusk 2: sunset; W.dusk 1: dusk; else W.dark >= .33 or W.rain: rain; W.dark >= .27: storm2; W.storm or W.dark > 0: storm; else day' },
      hide: { values: ['0', '1'], fromW: 'W.escondite ? 1 : 0 (story 3: the small palm and the birdhouse stand in the garden)' },
      rustle: { values: ['none', 'palma', 'casa', 'todo'], fromW: 'W.escondite && W.rustle ? W.rustle : none' },
      side: { values: ['-1', '1'], fromW: 'only when rustle is not none: (F >> 1) % 2 ? 1 : -1 (escondite()\'s sh(), frente.js:94); the rustling prop sits one pixel left or right' },
    },
    key: 'door + win + lights + sky + hide + rustle (+ side), e.g. "shut-shut-0-day-0-none"',
    baked: JSON.parse(fs.readFileSync(path.join(REPO, 'coqui/tool/ref/pp/states.json'), 'utf8')).filter(e => e.id.startsWith('frente/')).map(e => ({ ref: 'coqui/ref/pp/' + e.id, query: e.query })),
    bakedWhy: 'every state the stories, pairs and level pictures reach (coqui/ref/escenas/frente and a replay of the five stories), plus the rustle palma states a story can reach; each is a reference in coqui/ref/pp/frente/',
    notRead: 'W.abierto (escondite() reads it into a constant it never uses), W.mesa and W.caliente (the cake inside the window: sprite layer), W.nube, W.nube2, W.nube3, W.rain (moving: sprite layer; W.rain only picks the sky)',
    old: 'the old background sprite key was "fr" + door + "_" + win + "_" + lamp; the old W.storm / W.dark / W.dusk overlays (frente.js:163-165) are now the sky parameter',
  };

  return {
    scene: 'frente',
    made: 'node docs/proyecto/pixel/frente-sheet-make.js, from frente-set.html (window.FRENTE) and coqui/ref/escenas/frente/. Order 07.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      frog: 'a spot is the ground under his feet: q.x = round(sx) - 16, q.y = round(sy) - 25; q.s = the spot\'s scale',
      abuela: 'a spot is the ground under her feet: her sprite is drawn at (round(sx) - 30, round(sy) - 49)',
      bird: 'a point is under its feet: drawAve draws its bottom at y + 2',
      frame: 'a point named with a frame is the old point plus the frame\'s offset (a whole number of pixels); points drawn relative to it (a rect, a sprite) move by the same offset',
      sky: 'the sky is screen space: what lives in it (clouds, rain, the sun, the bird circling, the stars of marcador) keeps its old screen numbers',
      view: 'a view is the 196 x 216 window with x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point (x0 is given)',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window [clamp(round(sx - 98), 0, 44), clamp(round(sy - 52), 0, 112)]; zoom 2 = the 98 x 52 region [clamp(round(sx - 49), 0, 142), clamp(round(sy - 26), 0, 164)] shown nearest-neighbour at 2 x 2 in the 196 x 104 picture. crop is given. remap\'s cam and crop entries say what each old rectangle meant; for the pictures themselves pictures wins',
    },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, screen: screenOf(k) }, s.scale != null ? { scale: s.scale, frog: frogQ(k) } : { abuela: abDraw(k) }, { old: s.old, what: s.what })])),
    lugar: Object.fromEntries(['puerta', 'ventana', 'patio', 'casa_grande', 'palma_grande', 'palma_pequena', 'casa_pequena'].map(k => { const sp = k === 'casa_grande' ? 'puerta' : k; return [k, { spot: sp, frog: frogQ(sp), scale: SPOTS[sp].scale }]; })),
    frames: FRAMES,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips,
    front: { things: [], why: 'nothing in the set covers a character: abuela inside the window and the frog or abuela behind the half-open door are clipped (clips), the birdhouse and the small palm are drawn before the characters as before, and every spot stands in front of what is near it' },
    shadows: {
      coqui: { radius: .45, at: 'his spot (the ground under his feet: unproject his feet, z 0, or the porch\'s .16 on the porch)', when: 'W.cq.vis and he is not in the window (W.tab)', cast: 'castShadow(x, y, .3, .45)' },
      abuela: { radius: .35, at: 'her spot', when: 'W.ab with en puerta or paso (none in the window, none while she peeks)', cast: 'for (z = .3; z <= 2; z += .35) castShadow(x, y, z + spotZ, .35)' },
      dropped: 'juego.js frog()\'s shadow() under the frog is not drawn in El frente (the engine casts his)',
    },
    dropped: [
      'frente.js:140 c.drawImage(bg) -> the set, for setKey(W)',
      'frente.js:97 and :122 c.drawImage(palmita) -> the set (hide=1; its rustle: rustle and side)',
      'frente.js:100 and :125 c.drawImage(casita) -> the set (hide=1; its rustle: rustle and side)',
      'frente.js:163 the pale sun over the sun (W.storm) -> the set (sky storm, storm2: a pale sun; rain: none)',
      'frente.js:164 the W.dark wash over the whole picture -> the set (sky storm, storm2, rain light the set itself)',
      'frente.js:165 the W.dusk washes -> the set (sky dusk, sunset)',
    ],
    code,
  };

  function CODE() {
    const C = [];
    const c = (line, old, to, note) => C.push({ line, old, to, note });
    const fr = (f, old) => ({ frame: f, offset: FRAMES[f].offset, new: shift(old, FRAMES[f].offset) });
    const sky = 'sky: unchanged';
    c(48, '250-(F/4)%310, 0 (the small cloud)', sky);
    c(49, '98+34sin, 97+9sin (pink butterfly)', { point: 'mariposa.1', new: PTS['mariposa.1'].screen }, 'the amplitudes stay');
    c(50, '203+13sin, 72+7sin (yellow butterfly)', { point: 'mariposa.2', new: PTS['mariposa.2'].screen }, 'the amplitudes stay');
    c(61, 'ABAT.puerta [135,55]', { spot: 'abuela.puerta', new: abDraw('abuela.puerta') });
    c(61, 'ABAT.ventana [82,61]', { point: 'abuela.ventana', new: PTS['abuela.ventana'].screen });
    c(61, 'ABAT.paso [94,57]', { spot: 'abuela.paso', new: abDraw('abuela.paso') });
    for (const r of [[108, 75, 20, 2], [108, 77, 20, 1], [110, 78, 2, 3], [124, 78, 2, 3]]) c(64, 'mesa fr ' + JSON.stringify(r), fr('ventana.lado', r));
    for (const r of [[111, 74, 14, 1], [112, 68, 12, 6], [112, 67, 12, 2], [111, 67, 1, 7], [124, 67, 1, 7], [112, 66, 12, 1], [117, 65, 2, 2]]) c(65, 'mesa fr ' + JSON.stringify(r), fr('ventana.lado', r));
    c(66, 'steam 113+k*4, 64-j*3', fr('ventana.lado', [113, 64]), 'the k and j steps stay');
    c(77, 'PERCH.ventana [112,57]', { point: 'ave.ventana.posa', new: PTS['ave.ventana.posa'].screen });
    c(77, 'PERCH.puerta [166,49]', { point: 'ave.puerta.posa', new: PTS['ave.puerta.posa'].screen });
    c(77, 'HOLE.ventana [112,71]', { point: 'ave.ventana.hueco', new: PTS['ave.ventana.hueco'].screen });
    c(77, 'HOLE.puerta [166,80]', { point: 'ave.puerta.hueco', new: PTS['ave.puerta.hueco'].screen });
    c(78, 'avePos head: frogBox + 19 / + 2', 'relative to the frog: unchanged');
    c(79, 'avePos circle 150+56cos, 22+7sin', sky);
    c(83, 'drawAve: p[0], p[1]-H+2', 'relative to the bird: unchanged');
    c(84, 'the slice in its beak: p[0]-19 / +11, p[1]-14', 'relative to the bird: unchanged');
    c(85, 'z of sleep: p[0]+12, p[1]-H-4', 'relative to the bird: unchanged');
    c(86, 'little heart: p[0]-2, p[1]-H-5', 'relative to the bird: unchanged');
    for (const [k, o, p] of [['palma_grande', [56, 52], 'ave.palma'], ['palma_pequena', [195, 132], 'ave.palmita'], ['casa_pequena', [73, 129], 'ave.casita'], ['casa_grande', [166, 80], 'ave.puerta.hueco']]) {
      c(88, 'SPOT.' + k + ' ' + JSON.stringify(o), { point: p, new: PTS[p].screen }); c(113, 'SPOT.' + k + ' ' + JSON.stringify(o) + ' (the copy inside hud)', { point: p, new: PTS[p].screen });
    }
    for (const L of [97, 122]) c(L, 'drawImage(palmita, 174+sh, 114)', 'dropped: the set (hide=1, rustle palma)');
    for (const L of [100, 125]) c(L, 'drawImage(casita, 60+sh, 110)', 'dropped: the set (hide=1, rustle casa)');
    for (const L of [101, 126]) for (const r of [[70, 130, 2, 6], [75, 130, 2, 6], [69, 135, 4, 2], [74, 135, 4, 2]]) c(L, 'legs fr ' + JSON.stringify(r), fr('casita', r));
    for (const L of [102, 127]) { for (const r of [[44, 40, 2, 2], [80, 46, 2, 2]]) c(L, 'rustle leaf fr ' + JSON.stringify(r), fr('palma', r)); for (const r of [[180, 120, 2, 2], [208, 126, 2, 2]]) c(L, 'rustle leaf fr ' + JSON.stringify(r), fr('palmita', r)); }
    c(111, 'hud plato(g,5,6) and (DW-3*17-26, 6)', 'display: unchanged (hud draws on the 196 x 216 display)');
    c(112, 'hud x 5, y 5 (the plate at double size)', 'display: unchanged');
    c(136, 'hud dish x-3, y+19', 'display: unchanged');
    c(140, 'drawImage(bg, 0, 0)', 'dropped: the set');
    c(143, 'clip rect [153,53,11,51]', { clip: 'puerta.hueco' });
    c(143, 'drawImage(cq.6, 150, 84)', { point: 'cq.asoma', new: PTS['cq.asoma'].screen });
    c(144, 'clip rect [153,53,11,51]', { clip: 'puerta.hueco' });
    c(144, 'drawImage(abuela, 135, 55)', { spot: 'abuela.puerta', new: abDraw('abuela.puerta') });
    c(147, 'clip rect [97,61,30,20]', { clip: 'ventana.hueco' });
    c(147, 'drawImage(abuela, 82, 61)', { point: 'abuela.ventana', new: PTS['abuela.ventana'].screen });
    c(147, 'drawImage(abuela, 75, 61) (W.tab || W.mesa)', { point: 'abuela.ventana.mesa', new: PTS['abuela.ventana.mesa'].screen });
    c(148, 'drawImage(cq.42, 112+sh, 67 or 68)', fr('ventana.lado', [112, 67]), 'y 68 when wet: the same offset; +sh stays');
    c(149, 'towel(c, 114, 62)', { point: 'toalla', new: PTS.toalla.screen });
    c(149, 'drips 113+k*13, 70+...', fr('ventana.lado', [113, 70]), 'the steps stay');
    for (const p of [[110, 64], [120, 62], [127, 66]]) c(151, 'drop ' + JSON.stringify(p), fr('ventana.lado', p));
    c(152, 'ABAT.paso + (5+i*4, 27), (3, 30)', 'relative to abuela.paso: unchanged');
    c(155, 'dust at frogBox + [-6,0], [-11,-2], [-16,1]; the back of his head at b.x+b.w+1', 'relative to the frog: unchanged');
    for (const L of [157, 158]) c(L, 'drops around the frog (frogBox)', 'relative to the frog: unchanged');
    c(160, 'wings: p[0] +- (11+f), p[1]-14', 'relative to the bird: unchanged');
    c(161, 'W.trozo x-4, y-4 ...', 'relative to W.trozo (set by come from HOLE and the frog): unchanged');
    c(162, 'leaves fly from W.hojas (set by mira from SPOT) by [-1,-1], [1,-1], [-1,0], [1,0], [0,-1]', 'relative to W.hojas: unchanged');
    c(163, 'arc(210, 17, 10): the pale sun', 'dropped: the set (sky storm)');
    c(164, 'fillRect(0, 0, SW, SH): W.dark', 'dropped: the set (sky)');
    c(165, 'fillRect(0, 0, SW, SH) and (0, 0, SW, 40): W.dusk', 'dropped: the set (sky)');
    c(167, 'drawImage(nube, x, 0)', sky);
    c(168, 'rain under the cloud: x+9.., 21+..', sky);
    c(169, 'rain(): the whole picture', sky);
    c(170, 'flash: fillRect(0,0,SW,SH), the whole picture; bolt at nube.x+44, 21', sky);
    c(172, 'bub at [112,60] (window)', { point: 'globo.ventana', new: PTS['globo.ventana'].screen });
    c(172, 'bub at [147,69] / [141,66] (door, porch)', fr('abuela.puerta', [147, 69]), 'como: [141,66] + the same offset. The old code uses these for abuela on the porch too: kept');
    c(173, 'bub quien at [112,59]', { point: 'dentro.ventana', new: PTS['dentro.ventana'].screen });
    c(173, 'bub quien at [166,53]', { point: 'dentro.puerta', new: PTS['dentro.puerta'].screen });
    c(174, 'the frog\'s bubble at frogBox', 'relative to the frog: unchanged');
    c(178, 'talkAt paso [124, 40 or 56]', fr('abuela.paso', [124, 56]), 'y 40 with a bubble: the same offset');
    c(178, 'talkAt ventana [105 or 112, 38 or 60]', fr('ventana', [112, 60]), 'x 105 with the cake, y 38 with a bubble: the same offset');
    c(178, 'talkAt puerta [141 or 156, 47 or 56]', fr('abuela.puerta', [156, 56]), 'x 141 for como, y 47 with a bubble: the same offset');
    c(179, 'talkAt dentro [112,37]', { point: 'habla.dentro.ventana', new: PTS['habla.dentro.ventana'].screen });
    c(179, 'talkAt dentro [166,31]', { point: 'habla.dentro.puerta', new: PTS['habla.dentro.puerta'].screen });
    c(181, 'box abuela ventana [97,61,30,20]', { clip: 'ventana.hueco', box: clips['ventana.hueco'].box }, 'the window opening\'s box');
    c(181, 'box abuela paso [110,58,36,50]', fr('abuela.paso', [110, 58, 36, 50]));
    c(181, 'box abuela puerta [151,56,29,49]', fr('abuela.puerta', [151, 56, 29, 49]));
    for (const k of ['palma_grande', 'palma_pequena', 'casa_pequena', 'casa_grande']) c(182, 'box ' + k + ' ' + JSON.stringify(things[k].old.box), { thing: k, box: things[k].box });
    c(183, 'box nube [x, 0, 98, 22]', sky);
    for (const k of ['casa', 'puerta', 'ventana']) c(184, 'box ' + k + ' ' + JSON.stringify(things[k].old.box), { thing: k, box: things[k].box });
    c(187, 'hit palma_pequena [172,112,46,60]', { thing: 'palma_pequena', hit: things.palma_pequena.hit.box });
    c(187, 'hit casa_pequena [58,108,30,62]', { thing: 'casa_pequena', hit: things.casa_pequena.hit.box });
    c(187, 'hit palma_grande [34,34,48,74]', { thing: 'palma_grande', hit: things.palma_grande.hit.box });
    c(188, 'hit casa_grande [57,16,171,95]', { thing: 'casa_grande', hit: things.casa_grande.hit.box });
    c(189, 'hit pajaro |x - p[0]| < 16, p[1]-24 < y < p[1]+5', 'relative to the bird: unchanged');
    c(190, 'hit bizcocho: display sx < 66, sy < 36 (with the old zoom)', 'display: x - cam[0] < 66 and y - cam[1] < 36 (no zoom)');
    c(192, 'hit nube [x-2, 0, 102, 24]', sky);
    c(193, 'hit puerta [145,46,42,62]', { thing: 'puerta', hit: things.puerta.hit.box });
    c(194, 'hit ventana [82,53,61,42]', { thing: 'ventana', hit: things.ventana.hit.box });
    c(195, 'hit casa roof: 16 <= y < 42, 88-30t <= x <= 196+30t', { thing: 'casa', hit: things.casa.hit.box }, 'one box replaces both casa tests');
    c(196, 'hit casa [57,41,171,70]', { thing: 'casa', hit: things.casa.hit.box });
    c(197, 'hit sol: (x-210)^2 + (y-17)^2 < 144', sky);
    c(198, 'hit palma [34,36,30,70]', { thing: 'palma', hit: things.palma.hit.box });
    for (const k of ['puerta', 'ventana', 'patio', 'casa_grande', 'palma_grande', 'palma_pequena', 'casa_pequena']) { const sp = k === 'casa_grande' ? 'puerta' : k; c(205, 'LUGAR.' + k + ' ' + JSON.stringify(SPOTS[sp].old.concat([SPOTS[sp].scale])), { spot: sp, frog: frogQ(sp), scale: SPOTS[sp].scale }); }
    c(205, 'NX [22,76,140]', sky);
    c(207, 'ir: hops = round(distance / 28)', 'screen distance: unchanged');
    c(209, 'tocar: the knock at the middle of box(o.en)', 'from things[o.en].box: unchanged');
    c(210, 'luz stars [92,54],[132,56],[112,50]', fr('ventana', [92, 54]), 'each of the three + the same offset: ' + JSON.stringify([[92, 54], [132, 56], [112, 50]].map(p => shift(p, FRAMES.ventana.offset))));
    c(210, 'luz stars [150,47],[182,49],[166,43]', fr('puerta', [150, 47]), 'each of the three + the same offset: ' + JSON.stringify([[150, 47], [182, 49], [166, 43]].map(p => shift(p, FRAMES.puerta.offset))));
    c(220, 'hopTo(150, 80, 2, .72)', { spot: 'puerta.dentro', frog: frogQ('puerta.dentro'), scale: SPOTS['puerta.dentro'].scale });
    c(220, 'q.y -= 2 (five times)', 'relative: unchanged');
    c(222, 'jump to q.x 98, q.y 58, s .72 -> .46, dy -12', { spot: 'ventana.dentro', frog: frogQ('ventana.dentro'), scale: SPOTS['ventana.dentro'].scale }, 'the .72 is where he starts (LUGAR.ventana)');
    c(225, 'nube {x: -100, tx: NX[0]}', sky);
    c(226, 'atras: LUGAR.patio', { spot: 'patio' });
    c(227, 'nube2 {x: -100, tx: 44}, nube3 {x: 250, tx: 176}', sky);
    c(244, 'pajaro: from (-12, 40) to (150+56, 22)', sky);
    c(245, 'bonk: to HOLE', 'HOLE: see line 77');
    c(246, 'bonk: knock at h[0], h[1]-4; then h[0]-dir*6, h[1]+10; then (150, 26)', 'relative to HOLE; (150, 26) is sky: unchanged');
    c(247, 'posa: PERCH', 'PERCH: see line 77');
    c(248, 'come: W.trozo from HOLE', 'HOLE: see line 77');
    c(249, 'come: to the frog; stars at b.x+b.w/2 -+ 8; the slice shrinks k = 1, 0.7, 0.4 (not a place)', 'relative to the frog: unchanged');
    c(250, 'regala: HOLE', 'HOLE: see line 77');
    c(251, 'regala: h[1]-6; to the frog', 'relative: unchanged');
    c(253, 'fin2: aveA(196, 30)', { point: 'ave.techo', new: PTS['ave.techo'].screen });
    c(255, 'fin2: stars at cam + ...', 'relative to the view (cam): unchanged');
    c(258, 'tapa: from (-10, 60)', 'off the left edge: unchanged');
    c(259, 'tapa: away to (250, -20)', 'off the picture: unchanged');
    c(263, 'mira: SPOT[k]', 'SPOT: see line 88');
    c(264, 'sale: SPOT[k]', 'SPOT: see line 88');
    c(267, 'tapate: from (250, 60) to (196, 120)', { point: 'ave.cesped', new: PTS['ave.cesped'].screen }, '(250, 60) is off the right edge: unchanged');
    c(269, 'esconde casa_grande: hopTo(150, 82, 1, .6)', { spot: 'puerta.escondido', frog: frogQ('puerta.escondido'), scale: SPOTS['puerta.escondido'].scale });
    c(270, 'esconde casa_pequena: half way to (58, 104), four times', { spot: 'casa_pequena.dentro', frog: frogQ('casa_pequena.dentro') });
    c(272, 'busca_ave: SPOT[s]', 'SPOT: see line 88');
    c(273, 'busca_ave: [176, 100] (casa_grande)', { point: 'ave.puerta.lado', new: PTS['ave.puerta.lado'].screen });
    c(273, 'busca_ave: [73, 112] (casa_pequena)', { point: 'ave.casita.techo', new: PTS['ave.casita.techo'].screen });
    c(275, 'busca_ave: knock at pa[0], pa[1]-30; ir patio', 'relative to the bird; patio: line 205');
    c(277, 'devuelve: from (250, 30); to b.x+b.w+8, b.y+6', 'sky / relative to the frog: unchanged');
    c(279, 'avecasa: from (200, 40)', sky);
    c(279, 'avecasa: to (73, 126)', { point: 'ave.casita.entra', new: PTS['ave.casita.entra'].screen });
    c(281, 'marcador stars [60,20],[180,24],[120,12],[100,30],[150,30]', sky);
    c(282, 'vetecq: q.x+38, q.y+4', 'relative: unchanged');
    c(284, 'fin: stars at cam + ...', 'relative to the view (cam): unchanged');
    c(290, 'roba: to HOLE', 'HOLE: see line 77');
    c(291, 'roba: out to (h[0]+30, 24)', 'x relative to HOLE; y 24 is sky: unchanged');
    c(296, 'stake: NX[...]', sky);
    for (const k of Object.keys(views).filter(k => !k.includes('@'))) c(299, 'CAM.' + k + ' ' + JSON.stringify(views[k].old), { view: k, x0: views[k].x0 });
    for (const [k, p] of [['casa', 'mano.casa'], ['puerta', 'mano.puerta'], ['ventana', 'mano.ventana'], ['casa_grande', 'mano.casa'], ['casa_pequena', 'mano.casa_pequena'], ['palma_grande', 'mano.palma_grande'], ['palma_pequena', 'mano.palma_pequena']])
      c(300, 'handAt.' + k + ' ' + JSON.stringify(PTS[p].old), { point: p, new: PTS[p].screen.map(Math.round) });
    c(300, 'handAt.abuela fallback [166,76]', { point: 'mano.puerta', new: PTS['mano.puerta'].screen.map(Math.round) });
    c(300, 'heartAt [103,26]', { point: 'corazon', new: PTS.corazon.screen });
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', { spot: 'inicio', frog: frogQ('inicio'), scale: 1 }, 'not in frente.js: the host\'s default frog, for El frente');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', { spot: 'patio', frog: frogQ('patio'), scale: .86 }, 'not in frente.js: the frog of a pair picture');
    return C;
  }
}
function shift(r, o) { const a = r.slice(); a[0] += o[0]; a[1] += o[1]; return a; }

/* ---------- the checks ---------- */
function check(sh) {
  const P = [], inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== 14) P.push('things: ' + Object.keys(sh.things).length + ', not 14');
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.consts.LUGAR.value || inv.given.consts.LUGAR)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  for (const v of inv.storyViews || []) if (!sh.views[v.name]) P.push('story view missing: ' + v.name);
  const near = b => b[0] > -30 && b[1] > -40 && b[0] + b[2] < 270 && b[1] + b[3] < 246;
  for (const [k, t] of Object.entries(sh.things)) if (t.world && (!near(t.box) || !near(t.hit.box))) P.push('box far off the picture: ' + k + ' ' + JSON.stringify(t.box));
  for (const [k, s] of Object.entries(sh.spots)) if (s.screen[0] < 0 || s.screen[0] > 240 || s.screen[1] < 0 || s.screen[1] > 216) P.push('spot off the picture: ' + k);
  // every place of frente.js that order 06 found is named in code (by line and numbers)
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('frente.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; const es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (p.kind === 'point+' && L === '205') continue;
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n)))) P.push('frente.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  return P;
}
