#!/usr/bin/env node
'use strict';
/* El balcón's sheet (order 30a): writes docs/proyecto/pixel/balcon-sheet.json from balcon-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/balcon-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.BALCON) and its part map from balcon-set.html in headless Chrome, projects every world point with the
   engine's own formula, and checks the sheet against coqui/ref/escenas/balcon/ (positions.json, inventory.json, pairs.json).
   A second run writes the same bytes. Every name a builder needs for a screen position of historia/escenas/balcon.js is in `code`, by line. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'balcon-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/balcon');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = {};
  for (const door of ['shut', 'open']) {
    await page.goto('file://' + path.join(__dirname, 'balcon-set.html') + '?tags=1&door=' + door);
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(BALCON)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      // the part map: for each part, the pixels it owns (the checks: nothing decorative over a touch box; the front masks)
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(DEPTH.z) };
    });
    if (!G.F) Object.assign(G, g);
    G['parts.' + door] = g.parts; G['z.' + door] = g.z;
  }
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const sheet = make(G);
  const text = JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';
  fs.writeFileSync(OUT, text);
  const problems = check(sheet, G);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + text.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED:\n  ' + problems.join('\n  ')); process.exit(1); }
  console.log('check: all 13 things, every positions.json entry in remap, every LUGAR and CAM name, every balcon.js position in code, every hop count as the old one, nothing decorative over a touch box, every drink\'s base inside the table top with plain wall behind it, the bird on the window\'s flower box clear of abuela and the drinks, abuela standing on clear floor, the door whole in the wide view, the frog and abuela whole in pair gracias; at every moment of the stories every bubble inside the view, off the boards and off every face, every set of drinks side by side, every hint frame inside its view: ok');
})().catch(e => { console.error(e); process.exit(1); });

/* ---------- the engine's projection, as pp-engine.js has it (the same operations in the same order) ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S }; };
  const onWallY = (sx, sy, c) => { const x = (sx - OX) * R2 / S + c; return [x, c, ((x + c) / R2 * SIN - (sy - OY) / S) / COS]; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  return { W, H, S, R2, OX, OY, project, onWallY, atZ };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const hop = d => d < 3 ? 0 : Math.max(1, Math.min(4, Math.round(d / 30)));   // kit.js:128 acts.ir

/* ---------- the picture bubbles (order 30b), as balcon.js bub2 draws them: twice their size, the tail's tip at (tx, ty) ---------- */
// the glyphs of every bubble a character of this scene can show: balcon.js's BUBL (calor ... feliz), juego.js's BUBL (como, bien, mal, quien, lluvia)
// and BUB (hola, amor). A glyph's width: engine.js GL (q 5, hand 7, gota 5), balcon.js GL (sol 7, jugo 7, agua 7, equis 5); ok and sad are faces, 7
const GLW = { ok: 7, sad: 7, q: 5, hand: 7, gota: 5, sol: 7, jugo: 7, agua: 7, equis: 5 };
const BUBBLES = { calor: ['sol', 'sad'], no: ['equis'], q: ['q'], quiere_agua: ['agua'], no_jugo_si_agua: ['jugo', 'equis', 'agua'], jugo_q: ['jugo', 'q'], agua_q: ['agua', 'q'], feliz: ['ok'],
  como: ['ok', 'q', 'sad'], bien: ['ok'], mal: ['sad'], quien: ['hand', 'q'], lluvia: ['gota', 'sad'], hola: { w: 9, h: 10 }, amor: { w: 7, h: 6 } };
// the screen rectangle [x, y, w, h] of bubble k with its tail's tip at (tx, ty), on either frame of its bob (engine.js bubble, juego.js bub: the
// outline and the tail, at 1x; bub2 doubles them about (tx, ty))
function bubbleRect(k, tx, ty) {
  const b = BUBBLES[k]; if (!b) throw new Error('no bubble ' + k);
  let c0, c1, r0, r1;
  if (Array.isArray(b)) { const w = b.reduce((a, g) => a + GLW[g] + 3, 3), x = Math.round(-w / 2), y = -13 - 5 - 1; c0 = Math.min(x - 1, -3); c1 = Math.max(x + w, 3); r0 = y - 1; r1 = y + 1 + 13 + 3; }
  else { const w = b.w + 6, h = b.h + 6, x = Math.round(-w / 2), y = -h - 5 - 1; c0 = Math.min(x - 1, -2); c1 = Math.max(x + w, 2); r0 = y - 1; r1 = y + 1 + h + 3; }
  return [tx + 2 * c0, ty + 2 * r0, 2 * (c1 - c0 + 1), 2 * (r1 - r0 + 1)];
}

function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2]); return [r2(q.sx), r2(q.sy)]; };
  const box = w => { const xs = [], ys = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) { const q = E.project(x, y, z); xs.push(q.sx); ys.push(q.sy); }
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0]; };
  // the world box (square on the ground) whose 8 projected corners have the screen box [sx0, sy0] - [sx1, sy1] (set-kit.js boxAround)
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, SIN = .5, COS = Math.sqrt(3) / 2, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * SIN), vmin = vmax - d, z1 = (vmin * SIN - (sy0 - E.OY) / S) / COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  // a turned piece of furniture: the screen box of its 8 real corners
  const turnedScreen = (c, hw, hd, z0, z1) => { const a = F.TURN, ax = Math.cos(a), ay = Math.sin(a), bx = -ay, by = ax, xs = [], ys = [];
    for (const s of [-hw, hw]) for (const t of [-hd, hd]) for (const z of [z0, z1]) { const q = E.project(c[0] + ax * s + bx * t, c[1] + ay * s + by * t, z); xs.push(q.sx); ys.push(q.sy); }
    return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)]; };
  const winMid = (F.WIN0 + F.WIN1) / 2, doorMid = (F.DOOR0 + F.DOOR1) / 2, f = F.FLOOR;
  const uvXY = (u, v, z) => [(u + v) / 2, (v - u) / 2, z];                     // the set's u = x - y, v = x + y
  const pathAt = d => uvXY(F.PATH_U, F.PATH_V + d, 0);                          // the path's middle line, d below the lower step's front
  const seatZ = f + .45, seat = [F.SILLITA[0], F.SILLITA[1], seatZ];            // the small chair's seat (its top: balcon-set.html furniture())
  const tableTop = f + F.TABLE_H;
  // a point on the table top, s screen pixels right of its middle and DROW rows before it: along u = (1, -1) / R2 the screen row stays the same;
  // along v = (1, 1) / R2 a row is 1 / (S * SIN) of v. The drinks stand DROW rows in front of the middle: more of the top shows behind them
  const DROW = 4, dv = DROW / (E.S * .5) / E.R2;
  const onTable = s => { const k = s / E.S / E.R2; return [F.TABLE[0] + k + dv, F.TABLE[1] - k + dv, tableTop]; };

  /* ---- the frog's spots: the ground under his feet. q.x = round(sx) - 16, q.y = round(sy) - 25 (frogBox: his middle is q.x + 16, his shadow line q.y + 25) ---- */
  // Round 2: each is a whole screen point on the porch floor (or the seat, or the path), fitted so that every hop count acts.ir gives
  // (round(d / 30), 1 to 4) between any two LUGAR places is the old one with 2.6 px or more to a rounding edge (the check below),
  // and so that his box stands clear of the furniture: in front of the table and the small chair, never beside them at their depth
  // round 3: the set moved DX px right in the picture (originX 18 -> 38); every screen point written here as a literal is round 2's plus DX
  const DX = G.scene.originX - 18, atZ = (sx, sy, z) => E.atZ(sx + DX, sy, z), onFloor = (sx, sy) => atZ(sx, sy, f);
  const seatSmall = [F.SILLITA[0], F.SILLITA[1], f + .45];
  const SPOTS = {
    jardin: { world: atZ(113, 200, 0), scale: 1, old: [104, 185], what: 'LUGAR.jardin: on the path, near the bottom: where every story starts (fresh)' },
    sube: { world: atZ(113, 182, 0), scale: .9, old: [104, 168], what: 'acts.sube: hopTo(LUGAR.jardin[0], 168, 1, .9): on the path, at the foot of the steps' },
    balcon: { world: onFloor(125, 152), scale: .8, old: [106, 130], what: 'LUGAR.balcon and LUGAR.ventana: on the porch, before the table (in front of its foot)' },
    mesa: { world: onFloor(116, 158), scale: .86, old: [104, 141], what: 'LUGAR.mesa and LUGAR.junto: on the porch, before the table, near the steps but well inside the porch (where he takes a glass)' },
    decir: { world: onFloor(150, 170), scale: .8, old: [134, 130], what: 'LUGAR.decir: on the porch, out in front of the small chair, clear of it (where he speaks to abuela)' },
    silla_pequena: { world: [seatSmall[0], seatSmall[1], seatSmall[2]], scale: .72, old: [144, 109], what: 'LUGAR.silla_pequena: on the small chair\'s seat (rana(): sitting there he has no shadow)' },
    suelo: { world: onFloor(163, 170), scale: .8, old: [150, 132], what: 'LUGAR.suelo: on the porch floor, out in front of the small chair, towards the door, clear of it' },
    abuela: { world: onFloor(96, 148), scale: .8, old: [84, 129], what: 'LUGAR.abuela and LUGAR.silla_grande: on the porch, out in front of abuela\'s chair and the table\'s left side' },
    puerta: { world: onFloor(188, 158), scale: .76, old: [162, 125], what: 'LUGAR.puerta: on the porch, before the door' },
    // abuela standing: the ground under her feet; her sprite is drawn at (ab.x - 30, ab.y - 50) with ab.x = round(sx), ab.y = round(sy) + 1
    'abuela.puerta': { world: [(F.DOOR0 + F.DOOR1) / 2, F.HY1 + .1, f], old: [178, 125], what: 'AB.puerta: in the doorway (drawn clipped to clips[puerta.hueco])' },
    // round 3: abuela standing stands on clear floor, in front of the gap between her big chair and the table: no furniture is nearer than her
    // there and her box (ab.x +- 13) ends left of the drinks; she is drawn after the furniture and the drinks (behind), as the old drew her at lado
    'abuela.mesa': { world: onFloor(76, 135), old: [98, 143], what: 'AB.mesa: on clear floor at the table\'s left, in front of it and of her chair: nothing of the table or a chair is nearer than her, her box ends left of the drinks; her tray (on her left, as the old one) over the floor before her chair' },
    'abuela.lado': { world: onFloor(75, 125), old: [94, 147], what: 'AB.lado: beside her big chair, on clear floor before its right arm and left of the table: where she stands up from it and sits down in it' },
    'abuela.camina': { world: onFloor(74, 132), old: [106, 148], what: 'pair se sienta.no: abuela standing on clear floor beside her chair (ab en camina at 106, 148)' },
  };
  for (const s of Object.values(SPOTS)) s.world = W4(s.world);
  const screenOf = name => P(SPOTS[name].world);
  const frogQ = name => { const s = screenOf(name); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const abAt = name => { const s = screenOf(name); return [Math.round(s[0]), Math.round(s[1]) + 1]; };

  /* ---- named points: each old literal of balcon.js gets one ---- */
  const PTS = {};
  const pt = (name, def) => { PTS[name] = def; };
  const ptR = n => (PTS[n].screen || P(PTS[n].world)).map(Math.round);
  // abuela in her big chair: KIT.mkAbuelaS (52 x 50) drawn at ABS (its top left). Her body (sprite x 17) over the chair's middle,
  // her lap (row 36) on the seat, her feet (row 47) before it
  const chairSeat = [F.SILLA[0], F.SILLA[1], f + .5];
  { const s = P(chairSeat); pt('ABS', { world: W4(chairSeat), old: [51, 96], screen: [Math.round(s[0]) - 20, Math.round(s[1]) - 36], what: 'ABS: abuela sitting in her big chair (the sprite\'s top left: her middle, sprite x 17, 3 px left of the chair\'s middle so her feet stay before it and off the table; her lap, row 36, on its seat). Everything drawn with her (the fan, her glass, the jug over her head, sweat, the splash and its puddle, her bubble) is relative to it: unchanged' }); }
  // order 30b: her bubble while the score boards are up (el-jugo's game part, W.rondas: they cover the top 29 rows of the view): beside her head, on
  // its right, not over it. Its tail at TALK_LADO; her bubbles then are "no" and "amor" (26 and 30 px wide at twice their size, 38 to 40 rows
  // over the tail): the bubble's left edge 2 px right of her hair (sprite x 25), its top a row under the boards (row 28) (checks: bubbles)
  { const a = ptR('ABS'); pt('talk.lado', { world: W4(chairSeat), old: [68, 95], screen: [a[0] + 25 + 2 + 14, 28 + 2 + 40], what: 'TALK_LADO: the tail of her bubble while she sits and the score boards are up (talkAt with W.rondas): beside her head, on its right, under the boards (old: over her head, ABS + (17, -1), as when no boards are up)' }); }
  // the table top: X2 and MESA_Y. The glasses and jugs stand on a row DROW px in front of the table's middle (their bottom on it), each one's
  // base inside the top (checks.table)
  // order 30b: X2 14 px left and right of the middle (round 4: 12), and the middle one a pixel right of the table's middle (round 4: on it), so that
  // three drinks (a jug at each X2 and the glass abuela puts down between them, acts.aparta) stand side by side, none drawn over another (checks:
  // drinks): a jug's handle reaches x + 9 and its belly x - 7 (its spout, x - 8, is above a glass's straw), a glass n is drawn from x - 5 to x + 5
  for (const [k, s, old, what] of [['mesa.izq', -14, [108, 128], 'X2[0]: the left place on the table top'], ['mesa.der', 14, [132, 128], 'X2[1]: the right place on the table top (also acts.recibe x 132)'],
    ['mesa.centro', 1, [120, 128], 'the middle of the drinks\' row, between the two X2 places (dos("sm") vaso_mesa x 120, acts.aparta x 120: the glass she puts down stands between the two jugs, touching neither; the pairs\' glass or jug at 120; acts.aveva\'s test v.x < 120)'],
    ['mesa.toma', -14, [106, 128], 'pair toma.si: the glass at x 106'], ['mesa.abanico', 1, [121, 128], 'W.fanMesa: medio(c, 121, MESA_Y, 1): her half fan left on the table'],
    ['ave.mesa.toma', 7, [127, 128], 'pair toma.si: the bird on the table, drinking from the glass at 106 (x 127)'], ['ave.mesa.der', 12, [132, 128], 'pair toma.no: the bird asleep on the table at 132']])
    pt(k, { world: W4(onTable(s)), old, what });
  // the small chair's seat: ASIENTO (the glass on it stands at ASIENTO[1] - 1; the bird's feet at ASIENTO)
  pt('ASIENTO', { world: W4(seat), old: [160, 135], what: 'ASIENTO: the small chair\'s seat: vaso_silla stands on it (its bottom at y - 1), the bird sits on it (avesilla, marcador)' });
  // round 4: the bird on the window's flower box, as in the old picture: its feet on the box's top front edge, in the middle (the bare soil there,
  // no flowers), its body in front of the shutters. (Rounds 1 to 3 put it on the window frame, the box's bare end, a ledge over the window:
  // three rounds of fresh readers saw it hover.) The box is well above the drinks: checks.perch
  pt('PERCH', { world: W4([winMid, F.HY1 + F.BOXD, F.BZ1]), old: [120, 86], what: 'PERCH: the bird at the window (aveventana; the pairs gracias): on the window\'s flower box, in the middle: its feet on the box\'s top front edge (bare soil behind them, the flowers at both ends), its body in front of the shutters, as the old picture; clear of abuela, her glass and every drink' });
  // the two halves of her fan, on the floor before her chair
  pt('suelo.abanico.1', { world: W4(E.atZ(ptR('ABS')[0] + 40, ptR('ABS')[1] + 64, f)), old: [98, 157], what: 'W.enSuelo: medio(c, 98, 157, -1): one half of her fan on the floor before her chair' });
  pt('suelo.abanico.2', { world: W4(E.atZ(ptR('ABS')[0] + 52, ptR('ABS')[1] + 66, f)), old: [110, 158], what: 'W.enSuelo: medio(c, 110, 158, 1): the other half' });
  // the heart, the hands
  { const b = ptR('PERCH'); pt('corazon', { world: W4(E.onWallY(b[0] - 13, Math.max(3, b[1] - 50), F.HY1)), old: [107, 31], what: 'heartAt: the heart of a happy ending (its top left, 27 x 24 px): over the bird on the window\'s flower box, clear of it (PERCH), in the middle of the wide view' }); }
  pt('mano.puerta', { world: W4([doorMid, F.HY1, f + F.DH * .62]), old: [178, 84], what: 'cosas puerta hand: on the door, high (above abuela\'s face when she stands in it? no: see checks.hands)' });
  pt('mano.ventana', { world: W4([winMid, F.HY1, (F.WZ0 + F.WZ1) / 2]), old: [120, 70], what: 'cosas ventana hand: the middle of the window' });
  for (const p of Object.values(PTS)) if (!p.screen) p.screen = P(p.world);
  const MESA_Y = ptR('mesa.centro')[1];
  // the frog's hop up the steps: hopTo(LUGAR.jardin[0], 168, ...): x stays jardin's (the path runs straight down the picture)
  const subeQ = frogQ('sube');

  /* ---- things: the 13 touch keys ---- */
  const T = (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: box(world), hit: { world: W4(world), box: box(world) }, what }, extra);
  const turned = (c, hw, hd, z1, what, old) => { const s = turnedScreen(c, hw, hd, f, f + z1), w = boxAround(s[0], s[1], s[2], s[3]);
    return T(w, what, { turned: { centre: W4([c[0], c[1]]), halfWidth: hw, halfDepth: hd, height: r4(f + z1), angle: r4(F.TURN) }, old }); };
  const cajaOf = (x, y, t) => { const VT = { n: [9, 13], g: [11, 17], p: [7, 9] }, s = VT[t]; return [Math.round(x - s[0] / 2) - 4, y - s[1] - 6, s[0] + 8, s[1] + 9]; };   // balcon.js:100 cajaDe, unchanged
  const glass = (what, where) => ({ sprite: true, prop: true, why: what + '. A glass (or a jug, for jugo and agua in que-calor) in the sprite layer: box = cajaDe (balcon.js:100), relative to where it stands: unchanged', where });
  const things = {
    jugo: glass('the glass (or jug) of juice', { table: ['mesa.izq', 'mesa.der', 'mesa.centro'] }),
    agua: glass('the glass (or jug) of water', { table: ['mesa.izq', 'mesa.der', 'mesa.centro'] }),
    vaso_silla: glass('the glass on the small chair', { seat: 'ASIENTO', box: cajaOf(ptR('ASIENTO')[0], ptR('ASIENTO')[1] - 1, 'n') }),
    vaso_mesa: glass('the glass on the table', { table: 'mesa.centro', box: cajaOf(ptR('mesa.centro')[0], MESA_Y, 'n') }),
    vaso_grande: glass('the big glass', { table: ['mesa.izq', 'mesa.der'] }),
    vaso_pequeno: glass('the small glass', { table: ['mesa.izq', 'mesa.der'] }),
    abuela: { sprite: true, why: 'a character (today\'s sprite, drawn 1:1). abCaja (balcon.js:102): in her chair ABS + [4, 0, 34, 50]; standing [ab.x - 13, ab.y - 50, 26, 50]: relative, unchanged',
      box: { silla: { old: [55, 96, 34, 50], new: [ptR('ABS')[0] + 4, ptR('ABS')[1], 34, 50] } } },
    mesa: (() => { const c = P([F.TABLE[0], F.TABLE[1], f + F.TABLE_H]), g = P([F.TABLE[0], F.TABLE[1], f]), r = F.TABLE_R * E.S;
      return T(boxAround(c[0] - r, c[1] - r / 2 - 1, c[0] + r, g[1] + .34 * E.S / 2 + 1), 'the round table, foot to top (round: the box is its screen box, as a square world box, as the turned chairs)', { old: { box: [94, 124, 52, 25] } }); })(),
    silla_pequena: turned(F.SILLITA, F.SILLITA_HW, F.SILLITA_HD, 1.02, 'the small yellow chair (turned to the camera: the box is the screen box of its 8 corners, as a square world box)', { box: [148, 120, 24, 30] }),
    silla_grande: turned(F.SILLA, F.SILLA_HW, F.SILLA_HD, 1.52, 'abuela\'s big chair (turned to the camera, as silla_pequena)', { box: [48, 102, 40, 48] }),
    puerta: T([F.DOOR0 - .14, F.HY1 - .06, 0, F.DOOR1 + .14, F.HY1 + .06, f + F.DH + .14], 'the door with its frame', { old: { box: [162, 54, 32, 68], hand: [178, 84] }, hand: { point: 'mano.puerta', new: ptR('mano.puerta') } }),
    ventana: T([F.WIN0 - .45, F.HY1, F.BZ0, F.WIN1 + .45, F.HY1 + F.BOXD, F.WIN_TOP], 'the window with its frame, its shutters (open, flat on the wall) and the flower box', { old: { box: [93, 54, 54, 36], hand: [120, 70] }, hand: { point: 'mano.ventana', new: ptR('mano.ventana') } }),
    balcon: T([-1.5, 2.1, 0, 3.7, F.PD, f], 'the porch floor: its open front strip, before the furniture, from abuela\'s chair to the door (the whole floor\'s box would take in the wall and the roof\'s posts: with this camera the porch is a slanting band, and a box cannot follow it). Last in the hit order, as before', { old: { box: [42, 122, 156, 34] } }),
  };

  /* ---- clips ---- */
  const quad = (a0, a1, z0, z1, y) => [[a0, y, z0], [a1, y, z0], [a1, y, z1], [a0, y, z1]].map(W4);
  const clip = (thing, face, corners, what) => { const s = corners.map(P), xs = s.map(p => p[0]), ys = s.map(p => p[1]);
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return { thing, face, world: corners, screen: s, box: [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0], what }; };
  const clips = {
    'puerta.hueco': clip('puerta', 'opening', quad(F.DOOR0, F.DOOR1, f - .45, f + F.DH, F.HY1), 'the doorway on the front wall, carried .45 below the floor so her feet stay whole (old rect [165,57,24,69], balcon.js:124): abuela standing in the door (ab.en puerta) is drawn clipped to it'),
  };

  /* ---- views: every old view is zoom 1 here (page 12 section 5: only an old 98 x 108 view is zoom 2; mesa and porche were 1.54 and 1.15) ---- */
  const view = (world, what, old) => { const s = P(world); return { world: W4(world), screen: s, zoom: 1, x0: Math.max(0, Math.min(44, Math.round(s[0] - 98))), region: null, old, what }; };
  // the wide view (round 3: the whole door, its frame and abuela in it, with a margin). Order 30b: the window from the door frame's right edge with 8 px
  // to spare (checks: wide view) to abuela's chair's hint frame (its box - 12: juego.js spot(), pulsing) and her widest bubble over her head, the
  // window in the middle of the x0 those allow (a camera that moved with the chair would cut her bubble again)
  const doorR = E.project(F.DOOR1 + .26, F.HY1 + .03, f).sx, chairBox = things.silla_grande.box, talkSilla = [ptR('ABS')[0] + 17, ptR('ABS')[1] - 1];
  const leftmost = Math.min(chairBox[0] - 12, ...Object.keys(BUBBLES).map(k => bubbleRect(k, talkSilla[0], talkSilla[1])[0]));
  const wideX0 = Math.round((Math.ceil(doorR + 8 - 196) + leftmost) / 2);
  const porchMid = E.atZ(wideX0 + 98, 130, f);                                  // the porch's middle: abuela's chair to the door, the steps and the path below
  // order 30b: one window for all three views, so a change of view moves nothing (it was a 5 px slide for no purpose: the old mesa, a 1.54x close
  // view of the table, cannot be one here: only zoom 1 or 2, and a zoom 2 window of the table leaves abuela and her bubble out)
  const views = {
    wide: view(porchMid, 'the porch from abuela\'s chair to the door, the path and the frog on it: every story\'s usual view', [22, 0, 196, 216]),
    mesa: view(porchMid, 'the table (old: a 1.54x close view of the table): the same window as wide here (order 30b: a zoom 1 window centred on the table slid 5 px for nothing; a zoom 2 one would leave abuela and her bubble out)', [45, 36, 127, 140]),
    porche: view(porchMid, 'the porch (old: a 1.15x view; the same window as wide here)', [35, 20, 170, 187.3]),
  };

  /* ---- the review and level pictures: each its own centre and a whole-number zoom ---- */
  const pic = (world, zoom, what) => { const s = P(world), crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(s[0] - 98))), Math.max(0, Math.min(112, Math.round(s[1] - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(s[0] - 49))), Math.max(0, Math.min(164, Math.round(s[1] - 26))), 98, 52];
    return { world: W4(world), screen: s, zoom, crop, what }; };
  // each picture's centre is a screen point (then a world point on the floor or the wall that lands there)
  const tableC = atZ(113, 112, f), chairSmallC = (() => { const s = P([F.SILLITA[0], F.SILLITA[1], f + .5]); return E.atZ(s[0] + 4, s[1] - 3, f); })();
  // the window whole, from its head to the flower box's bottom (round 3: pair 1's lower picture had the roof in its top half and the box cut)
  const windowAlone = (() => { const t = P([winMid, F.HY1, F.WIN_TOP]), b = P([winMid, F.HY1 + F.BOXD, F.BZ0]); return E.onWallY(t[0], (t[1] + b[1]) / 2 + 1, F.HY1); })();
  const absC = atZ(98, 52, f);                        // abuela in her chair, her bubble over her head, the table beside her
  const tomaC = atZ(113, 109, f);
  // gracias (pair 8): abuela in her chair with her glass, the frog before her whole with his bubble over him, the bird on its perch: round 4
  // centres it between abuela's top (ABS) and the frog's feet (his spot abuela: q.y + 25), so both are whole (round 3 cut the frog off at his eyes)
  const gracC = (() => { const a = ptR('ABS'), q = frogQ('abuela'); return E.atZ(98 + DX, (a[1] + q[1] + 25) / 2, f); })();
  const sitC = atZ(98, 92, f);
  const frogBal = (() => { const q = frogQ('balcon'); return E.atZ(q[0] + 16, q[1] + 13, f); })();
  const PICS = {
    'silla.si': pic(chairSmallC, 2, 'the small yellow chair, close: no table in it'),
    'silla.no': pic(windowAlone, 2, 'the window and its flower box, close: no chair in it (round 2: the whole table cannot be framed at zoom 2 without a chair, so the window, whole, is the picture that is not a chair)'),
    'vaso.si': pic(tableC, 2, 'the table, close: a glass of water on it'),
    'vaso.no': pic(tableC, 2, 'the table, close: a jug of water on it'),
    'jugo.si': pic(tableC, 2, 'the table, close: a glass of juice'),
    'jugo.no': pic(tableC, 2, 'the table, close: a glass of water'),
    'agua.si': pic(tableC, 2, 'the table, close: a jug of water'),
    'agua.no': pic(tableC, 2, 'the table, close: a jug of juice'),
    'se sienta.si': pic(sitC, 1, 'abuela sitting in her big chair, the table beside her'),
    'se sienta.no': pic(sitC, 1, 'abuela standing beside her big chair'),
    'toma.si': pic(tomaC, 2, 'the table, close: the bird drinking from a glass'),
    'toma.no': pic(tomaC, 2, 'the table, close: the bird asleep beside a full glass'),
    'quiero.si': pic(absC, 1, 'abuela in her chair, a bubble: she wants water'),
    'quiero.no': pic(absC, 1, 'abuela in her chair, drinking, a heart'),
    'gracias.si': pic(gracC, 1, 'abuela gives the frog a glass, the frog\'s heart'),
    'gracias.no': pic(gracC, 1, 'abuela without a glass, the frog sad'),
    '¿cómo estás?.si': pic(absC, 1, 'abuela in her chair asks how he is (ok, ?, sad)'),
    '¿cómo estás?.no': pic(absC, 1, 'abuela in her chair asks about water'),
    'bien.si': pic(frogBal, 1, 'the frog on the porch, ok'),
    'bien.no': pic(frogBal, 1, 'the frog on the porch, hot and sweating'),
  };
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'balcon' ? { w: L.w, index: i, picture: p.pair + '.' + p.side, crop: PICS[p.pair + '.' + p.side].crop, zoom: PICS[p.pair + '.' + p.side].zoom, old: p.crop } : null).filter(Boolean));

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const R = (match, to) => ({ match, to });
  const camTo = (p, names) => ({ pictures: names, what: 'the rectangle of the old pair picture: pictures[...] gives the new crop and zoom' });
  const RULES = [
    R(p => p.kind === 'cam' && p.x === 14 && p.y === 52, { pictures: ['quiero.si', 'quiero.no', 'gracias.si', 'gracias.no', '¿cómo estás?.si', '¿cómo estás?.no'], what: 'abuela in her chair' }),
    R(p => p.kind === 'cam' && p.x === 18 && p.y === 84, { pictures: ['se sienta.si', 'se sienta.no'], what: 'abuela and her chair' }),
    R(p => p.kind === 'cam' && p.x === 82 && p.y === 94, { pictures: ['bien.si', 'bien.no'], what: 'the frog on the porch' }),
    R(p => p.kind === 'cam' && p.x === 84 && p.y === 92, { pictures: ['toma.si', 'toma.no'], what: 'the table and the bird' }),
    R(p => p.kind === 'cam' && p.x === 86 && p.y === 98, { pictures: ['vaso.si', 'vaso.no', 'jugo.si', 'jugo.no', 'agua.si', 'agua.no'], what: 'the table top' }),
    R(p => p.kind === 'cam' && p.x === 86 && p.y === 116, { pictures: ['silla.no'], what: 'the table, no chair' }),
    R(p => p.kind === 'cam' && p.x === 126 && p.y === 116, { pictures: ['silla.si'], what: 'the small chair' }),
    R(p => p.kind === 'crop' && p.x === 49.31, { pictures: ['quiero.si', 'quiero.no', '¿cómo estás?.si'], what: 'level: abuela in her chair' }),
    R(p => p.kind === 'crop' && (p.x === 50.2 || p.x === 66.2), { pictures: ['se sienta.si', 'se sienta.no'], what: 'level: abuela and her chair' }),
    R(p => p.kind === 'crop' && p.x === 103.65 && p.y === 98, { pictures: ['jugo.si', 'agua.si'], what: 'level: the table top' }),
    R(p => p.kind === 'crop' && p.x === 103.65 && p.y === 116, { pictures: ['silla.no'], what: 'level: the table' }),
    R(p => p.kind === 'crop' && p.x === 143.65, { pictures: ['silla.si'], what: 'level: the small chair' }),
    R(p => p.kind === 'point' && p.x === 84 && p.y === 129, { spot: 'abuela' }),
    R(p => p.kind === 'point' && p.x === 106 && p.y === 130, { spot: 'balcon' }),
    R(p => p.kind === 'point' && p.x === 94 && p.y === 147, { abuela: 'abuela.lado', what: 'set.ab with en silla: drawn at ABS; x, y are where she stands up to (AB.lado)' }),
    R(p => p.kind === 'point' && p.x === 106 && p.y === 148, { abuela: 'abuela.camina' }),
    R(p => p.kind === 'point' && p.x === 120 && p.y === 86, { point: 'PERCH' }),
    R(p => p.kind === 'point' && p.x === 127 && p.y === 128, { point: 'ave.mesa.toma' }),
    R(p => p.kind === 'point' && p.x === 132 && p.y === 128, { point: 'ave.mesa.der' }),
    R(p => p.kind === 'x' && p.x === 106, { point: 'mesa.toma', what: 'x on the table top (y is MESA_Y)' }),
    R(p => p.kind === 'x' && p.x === 108, { point: 'mesa.izq', what: 'x on the table top (y is MESA_Y)' }),
    R(p => p.kind === 'x' && p.x === 120, { point: 'mesa.centro', what: 'x on the table top (y is MESA_Y)' }),
    R(p => p.kind === 'x' && (p.x === 80 || p.x === 94 || p.x === 96), { what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])', level: true }),
  ];
  const remap = POS.positions.map(p => {
    const rule = RULES.find(r => r.match(p));
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (!rule) { e.to = null; return e; }
    const t = rule.to;
    if (t.spot) { e.to = { spot: t.spot }; e.frog = frogQ(t.spot); e.scale = SPOTS[t.spot].scale; }
    else if (t.abuela) { e.to = { spot: t.abuela }; e.ab = abAt(t.abuela); }
    else if (t.point) { e.to = { point: t.point }; e.screen = ptR(t.point); if (p.kind === 'x') e.x = ptR(t.point)[0]; }
    else if (t.pictures) { e.to = { pictures: t.pictures }; e.crops = Object.fromEntries(t.pictures.map(n => [n, { crop: PICS[n].crop, zoom: PICS[n].zoom }])); }
    else if (t.level) e.to = { level: true };
    if (t.what) e.what = t.what;
    return e;
  });

  /* ---- the sprite layer's order and what covers what: the front masks ---- */
  // the old draw() drew the big chair (127), the small chair (135) and the table (136) after abuela when she stood behind them (ab.y < 144).
  // They are in the set now; to keep what covered what, the set's own pixels of each are drawn again at that line (a mask per baked state)
  const front = {
    how: 'at the old line, draw again each pixel of the set that balcon-set.html\'s part(name) drew last (PART_TAGS), over what the sprite layer has drawn so far, but only where that pixel is nearer to the camera than abuela: bakedZ[i] > vAb / COS - (row + .5 - OY) * tan(30 deg) / S (the depth, at that row, of the upright plane through her facing the camera). vAb = (x + y) / R2 of the point under her: standing, the point at height .3 (the porch) that lands on (ab.x, ab.y - 1); sitting, points.ABS.world. Only abuela (standing, balcon.js:126; sitting, :129 to :134, under the small chair and the table) is drawn before these lines. Why the depth: on the old flat picture "behind the furniture" was a row (ab.y < 144); with this camera the porch is a slanting band and no row separates behind the table from before her chair',
    plane: 'vAb / COS - (row + .5 - OY) * tan(30 deg) / S',
    parts: {
      silla_grande: { line: 127, replaces: 'c.drawImage(spr("sillaG",mkSillaG),SILLA[0],SILLA[1])' },
      silla_pequena: { line: 135, replaces: 'c.drawImage(spr("sillaP",mkSillaP),SILLITA[0],SILLITA[1])' },
      mesa: { line: 136, replaces: 'c.drawImage(spr("mesa",mkMesa),94,125)' },
    },
  };
  // the "behind the furniture" test (balcon.js:126 and :141): ab.y < 144. Between abuela at the table (mesa, behind) and beside her chair (lado, before)
  const yMesa = abAt('abuela.mesa')[1], yLado = abAt('abuela.lado')[1], yCam = abAt('abuela.camina')[1];
  // round 3: every place she stands is on clear floor with nothing nearer than her, so she is drawn at :141, after the furniture and the drinks
  // (as the old drew her at lado): no table, chair or drink is ever drawn over her standing. In the doorway the clip keeps her inside it
  const BEHIND = Math.min(yMesa, yLado, yCam, abAt('abuela.puerta')[1]);

  // hop counts: every pair of LUGAR places, old against new
  const OLDL = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')).given.lugar;
  const lugar = {};
  for (const k of Object.keys(OLDL)) { const sp = k === 'junto' ? 'mesa' : k === 'ventana' ? 'balcon' : k === 'silla_grande' ? 'abuela' : k; lugar[k] = { spot: sp, q: frogQ(sp), scale: SPOTS[sp].scale, old: OLDL[k] }; }
  const hops = [], names = Object.keys(lugar);
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const a = lugar[names[i]], b = lugar[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hops.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) });
  }

  const code = CODE();

  const setKey = {
    params: {
      door: { values: ['shut', 'open'], fromW: 'W.door: 0 shut, 1 open' },
      win: { values: ['shut', 'open'], fromW: 'W.win: 0 shut, 1 open (every story and pair keeps it shut; the old bg() draws both)' },
    },
    key: 'door + win, e.g. "shut-shut"',
    baked: [{ query: '?door=shut&win=shut', reached: 'que-calor, the pairs, every story\'s start' }, { query: '?door=open&win=shut', reached: 'el-jugo, d-agua-pajaro, h-balcon' }, { query: '?door=shut&win=open', reached: 'no story: the old bg(door, win) can draw it' }, { query: '?door=open&win=open', reached: 'no story' }],
    bakedWhy: 'the old background sprite key was "bal" + door + "_" + win; the stories reach bal0_0 and bal1_0 only. The furniture never moves, so it is in the set; what stands on it (glasses, jugs, the fan, the bird) is in the sprite layer',
    notRead: 'every other key of W: the glasses, jugs and fan halves (W.vasos, W.jarras, W.fanMesa, W.enSuelo, W.fanMedio) are drawn by the sprite layer, so they make no new set (order 06 counted 50 states with them)',
  };

  return {
    scene: 'balcon',
    made: 'node docs/proyecto/pixel/balcon-sheet-make.js, from balcon-set.html (window.BALCON) and coqui/ref/escenas/balcon/. Order 30a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      frog: 'a spot is the ground (or seat, or step) under his feet: q.x = round(sx) - 16, q.y = round(sy) - 25; q.s = the spot\'s scale',
      abuela: 'standing: a spot is the ground under her feet: ab.x = round(sx), ab.y = round(sy) + 1 (balcon.js:123 draws her at ab.x - 30, ab.y - 50). Sitting: points.ABS.screen is the sprite\'s top left',
      table: 'a glass or jug on the table stands with its bottom on MESA_Y at the x of a mesa.* point (all on one row, a little in front of the table\'s middle, each base inside the top)',
      relative: 'what the old code draws relative to a character, a glass, ABS or the frog (offsets like ABS[0]+31, v.x+lado*19, b.x+b.w+1) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the red flash (W.rojo), the bird coming in from SW+12, 30, the stars of marcador and fin',
      view: 'a view has a zoom; here all three are zoom 1: the 196 x 216 window with x0 = clamp(round(sx - 98), 0, 44), sx the projection of its world point. Never a fraction',
      viewChange: 'between two zoom 1 views the window slides (camGo, whole pixels)',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window [clamp(round(sx - 98), 0, 44), clamp(round(sy - 52), 0, 112)]; zoom 2 = the 98 x 52 region [clamp(round(sx - 49), 0, 142), clamp(round(sy - 26), 0, 164)] shown nearest-neighbour at 2 x 2 in the 196 x 104 picture. crop is given. The old rectangles (remap cam and crop) say which pictures they were',
      walk: 'abCamina walks abuela in a straight screen line between her spots, as before, now between the new spots',
    },
    roof: { what: 'the roof is round 2\'s roof b, chosen by the orchestrator (round 1\'s roof a and ?roof=a are gone): a short hip roof over the back of the porch, the house 0.4 deep, no posts. Round 3: its eaves are at HF ' + G.F.HF + ', so the wall shows to ' + r2(G.F.WALL_TOP) + ' over the window\'s top: a strip of wall over the door and the window (round 4: the bird is on the flower box again; the eaves stay)', HF: G.F.HF },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, screen: screenOf(k) }, s.scale != null ? { scale: s.scale, frog: frogQ(k) } : { ab: abAt(k) }, { old: s.old, what: s.what })])),
    lugar,
    hops,
    points: PTS,
    MESA_Y: { old: 128, new: MESA_Y, what: 'MESA_Y: the row the glasses and jugs stand on (their bottom): DROW px in front of the table top\'s middle' },
    behind: { old: 144, new: BEHIND, what: 'balcon.js:126 and :141: ab.y < this is drawn at :126 (behind the furniture, which covers her where it is nearer: front), ab.y >= this at :141 (after the furniture and the drinks). Round 3: every place she stands is at or past it (AB.mesa ' + yMesa + ', AB.lado ' + yLado + ', camina ' + yCam + ', the door ' + abAt('abuela.puerta')[1] + '): standing, she is on clear floor and drawn over everything but the frog, the bird and the signs; walking between two places she may pass above this row, as the old' },
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips,
    front,
    shadows: {
      coqui: { radius: .45, at: 'the ground point that lands on his feet on screen (g = unproject(b.x + b.w / 2, q.y + 25), on the porch and the steps too, as El frente\'s porch)', when: 'W.cq.vis and al > .5, and not when he sits on the small chair (rana()\'s sent: the old drew no shadow there either)', cast: 'castShadow(g.x, g.y, .3, .45)' },
      abuela: { radius: .35, at: 'the ground point that lands on her feet on screen (g = unproject(ab.x, ab.y - 1))', when: 'W.ab standing (en puerta, camina; not en silla: she sits in the chair\'s own shadow; not while she fades, al <= .5)', cast: 'for (z = .3; z <= 2; z += .35) castShadow(g.x, g.y, z, .35)' },
      dropped: 'balcon.js:118 rana()\'s dotted shadow under the frog (green on the lawn, tan on the porch) is not drawn: the engine casts his',
    },
    dropped: [
      'balcon.js:121 c.drawImage(bg) -> the set, for setKey(W)',
      'balcon.js:127, :135, :136 the big chair, the small chair, the table sprites -> the set (and front: their pixels again at those lines)',
      'balcon.js:118 the frog\'s dotted shadow -> the engine\'s cast shadow (shadows.coqui)',
      'balcon.js:50 the two hanging plants of bg() are not in the set: from this camera they would hang in front of the window and the door, over their touch boxes (decision 14). The two bushes are; the old posts are not (the short roof stands on none)',
    ],
    code,
    checks: { notes: [] },
  };

  function CODE() {
    const C = [];
    const c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const pn = n => ({ point: n, new: ptR(n) });
    c(79, 'VT n [9,13], g [11,17], p [7,9] (glass sizes)', 'sizes, not places: unchanged');
    c(95, 'X2=[108,132]', { points: ['mesa.izq', 'mesa.der'], new: [ptR('mesa.izq')[0], ptR('mesa.der')[0]] });
    c(95, 'X4=[101,113,127,139]', 'never read by the scene: unchanged');
    c(95, 'MESA_Y=128', { MESA_Y: MESA_Y });
    c(95, 'SILLA=[48,102]', 'the big chair\'s sprite: dropped (the set); its box is things.silla_grande');
    c(95, 'SILLITA=[148,120]', 'the small chair\'s sprite: dropped (the set); its box is things.silla_pequena');
    c(95, 'ABS=[51,96]', pn('ABS'));
    c(95, 'PERCH=[120,86]', pn('PERCH'));
    c(95, 'ASIENTO=[160,135]', pn('ASIENTO'));
    c(96, 'AB.puerta [178,125]', { spot: 'abuela.puerta', new: abAt('abuela.puerta') });
    c(96, 'AB.mesa [98,143]', { spot: 'abuela.mesa', new: abAt('abuela.mesa') });
    c(96, 'AB.lado [94,147]', { spot: 'abuela.lado', new: abAt('abuela.lado') });
    for (const k of Object.keys(OLDL)) c(97, 'LUGAR.' + k + ' ' + JSON.stringify(OLDL[k]), { spot: lugar[k].spot, new: lugar[k].q.concat([lugar[k].scale]) });
    c(100, 'cajaDe: [x - w/2 - 4, y - h - 6, w + 8, h + 9]; a jug [v.x - 9, MESA_Y - 24, 26, 27]', 'relative to the glass or jug: unchanged (MESA_Y is the new one)');
    c(102, 'abCaja silla [55,96,34,50]', { new: things.abuela.box.silla.new }, 'ABS + [4, 0, 34, 50]; standing: relative, unchanged');
    c(105, 'box mesa [94,124,52,25]', { thing: 'mesa', box: things.mesa.box });
    c(105, 'box silla_pequena [SILLITA,24,30] = [148,120,24,30]', { thing: 'silla_pequena', box: things.silla_pequena.box });
    c(105, 'box silla_grande [SILLA,40,48] = [48,102,40,48]', { thing: 'silla_grande', box: things.silla_grande.box });
    c(106, 'box puerta [162,54,32,68]', { thing: 'puerta', box: things.puerta.box });
    c(106, 'hand puerta [178,84]', pn('mano.puerta'));
    c(106, 'box ventana [93,54,54,36]', { thing: 'ventana', box: things.ventana.box });
    c(106, 'hand ventana [120,70]', pn('mano.ventana'));
    c(106, 'box balcon [42,122,156,34]', { thing: 'balcon', box: things.balcon.box });
    c(116, 'bub2: c.scale(2,2), bub(c,k,0,0,a)', 'relative: unchanged (the bubbles are drawn at twice their size)');
    c(117, 'rana: sent = |q.x - LUGAR.silla_pequena[0]| < 3 && |q.y - LUGAR.silla_pequena[1]| < 3', 'reads LUGAR: the new spot');
    c(118, 'rana: the dotted shadow at b.x+2, q.y+25 (green when q.y > 158)', 'dropped: the engine casts his shadow (shadows.coqui)');
    c(121, 'c.drawImage(bg, 0, 0)', 'dropped: the set, for setKey(W)');
    c(123, 'dePie: mkAbuela at ab.x - 30, ab.y - 50; the tray at x + 1, y + 26', 'relative to her: unchanged');
    c(124, 'clip rect(165,57,24,69)', { clip: 'puerta.hueco' });
    c(126, 'ab.y < 144', { behind: BEHIND });
    c(127, 'drawImage(sillaG, SILLA)', { front: 'silla_grande' });
    c(129, 'mkAbuelaS at ABS', pn('ABS'));
    c(130, 'fan at ABS + (31 + d, 16)', 'relative to ABS: unchanged');
    c(131, 'her glass at ABS + (30 or 36, 17 or 28)', 'relative to ABS: unchanged');
    c(132, 'the jug over her head: translate(ABS + (30, -2)), jarra(c, 0, 8)', 'relative to ABS: unchanged');
    c(133, 'the water from the jug: ABS + (16, -10 ...)', 'relative to ABS: unchanged');
    c(134, 'sweat: ABS + (17 + ..., 6 ...)', 'relative to ABS: unchanged');
    c(135, 'drawImage(sillaP, SILLITA)', { front: 'silla_pequena' });
    c(136, 'drawImage(mesa, 94, 125)', { front: 'mesa' });
    c(137, 'vasos at v.x, v.y || MESA_Y', 'v.x from X2, mesa.centro, ASIENTO or the remap; MESA_Y the new one');
    c(138, 'fanMesa: medio(c, 121, MESA_Y, 1)', pn('mesa.abanico'));
    c(139, 'enSuelo: medio(c, 98, 157, -1)', pn('suelo.abanico.1'));
    c(139, 'enSuelo: medio(c, 110, 158, 1)', pn('suelo.abanico.2'));
    c(140, 'jarras at v.x, MESA_Y', 'v.x from X2 or the remap; MESA_Y the new one');
    c(141, 'ab.y >= 144', { behind: BEHIND });
    c(142, 'the falling fan halves: ABS + (34 - t, 16 + 3t), ABS + (38 + t/2, 16 + 3t)', 'relative to ABS: unchanged');
    c(143, 'the frog and what he holds: frogBox', 'relative to the frog: unchanged');
    c(149, 'pouring: ABS + (36, 8 ...)', 'relative to ABS: unchanged');
    c(150, 'drawAve(W.ave)', 'the bird\'s place comes from PERCH, ASIENTO, the glasses or the remap');
    c(151, 'splash: ABS + (17 ..., 2 ...)', 'relative to ABS: unchanged');
    c(152, 'the puddle: ABS + (2, 50), (6, 52)', 'relative to ABS: unchanged');
    c(153, 'W.rojo: fillRect(0, 0, SW, SH)', 'the whole picture: unchanged');
    c(154, 'abuela\'s bubble at talkAt', 'relative: unchanged');
    c(155, 'the frog\'s bubble at frogBox', 'relative: unchanged');
    c(158, 'talkAt: ABS + (17, -39 or -1); standing ab.x, ab.y - 51 (- 38)', { point: 'talk.lado', new: ptR('talk.lado') }, 'order 30b: sitting while the score boards are up (W.rondas): [TALK_LADO[0], TALK_LADO[1] - (ab.bub ? 38 : 0)], her bubble beside her head under the boards; otherwise as before, relative to ABS or to her');
    c(160, 'respIcon: a big glass in the answer bubble', 'relative: unchanged');
    c(179, 'hud: tanteo(g, 5, 5), tanteo(g, DW - 71, 5), termo(g, DW - 51, 7)', 'display: unchanged (hud draws on the 196 x 216 display)');
    c(183, 'abCamina: from AB.lado when in the chair; steps of 6 px', 'AB.lado: the new spot; the step length stays');
    c(186, 'dos(): X2[s], X2[1 - s]', 'X2: line 95');
    c(188, 'dos("sm"): vaso_silla at ASIENTO[0], ASIENTO[1] - 1; vaso_mesa at x 120', { point: 'mesa.centro', new: ptR('mesa.centro') }, 'ASIENTO: line 95');
    c(189, 'dos("fin"): X2[0], X2[1]', 'X2: line 95');
    c(191, 'brillo: stars at v.x, (v.y || MESA_Y) - 20', 'relative to the glasses: unchanged');
    c(193, 'sube: hopTo(LUGAR.jardin[0], 168, 1, .9)', { spot: 'sube', frog: subeQ, x: 'LUGAR.jardin[0] (the same x: ' + (subeQ[0] === frogQ('jardin')[0] ? 'yes' : 'NO') + ')' });
    c(195, 'absienta: abCamina(AB.lado)', 'AB: line 96');
    c(197, 'abentra: abCamina(AB.puerta)', 'AB: line 96');
    c(199, 'absale: abCamina(AB.mesa)', 'AB: line 96');
    c(210, 'aveventana: PERCH', 'PERCH: line 95');
    c(212, 'aveva: lado = v.x < 120 ? 1 : -1; to v.x + lado * 19, v.y || MESA_Y', { point: 'mesa.centro', x: ptR('mesa.centro')[0] }, 'the test x is the table\'s middle; the 19 stays: the bird lands on the table on the middle\'s side of the glass');
    c(214, 'avesilla: ASIENTO', 'ASIENTO: line 95');
    c(217, 'marcador: camGo("wide", 9)', { view: 'wide' });
    c(219, 'marcador stars [60,50],[180,54],[120,42],[96,64],[150,60]', 'screen effect: unchanged (they are over the roof and the wall, as before)');
    c(220, 'marcador: aveVa(ASIENTO), ir balcon', 'ASIENTO: line 95; LUGAR: line 97');
    c(224, 'lleva: ir mesa, abuela, decir', 'LUGAR: line 97');
    c(229, 'aparta: the glass she puts down: x 120', { point: 'mesa.centro', x: ptR('mesa.centro')[0] });
    c(242, 'recibe: his glass: x 132', { point: 'mesa.der', x: ptR('mesa.der')[0] });
    c(244, 'pone: the jugs at X2', 'X2: line 95');
    c(253, 'fin stars [60,50],[180,54],[120,42],[96,64],[150,60]', 'screen effect: unchanged');
    for (const L of [206, 209, 213, 225, 227, 245, 246]) c(L, 'how full: 0.66, 0.33, 0 / 0.4, 0.7, 1', 'not a place: unchanged');
    for (const k of Object.keys(views)) c(262, 'CAM.' + k + ' ' + JSON.stringify(views[k].old), { view: k, zoom: 1, x0: views[k].x0 });
    c(262, 'heartAt [107,31]', pn('corazon'));
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: balcon\'s fresh() puts him at LUGAR.jardin');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86 (the frog of a pair picture)', 'the pairs of cual-balcon set cq themselves when they show him (remap); otherwise he is not seen (vis 0)');
    return C;
  }
}

/* ---------- the checks ---------- */
function check(sh, G) {
  const P = [], inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const notes = sh.checks.notes;
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  // every review pair side and level picture has a picture
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-balcon.json'), 'utf8'));
  for (const it of cual.items) for (const s of ['si', 'no']) if (!sh.pictures[it.w + '.' + s]) P.push('picture missing: ' + it.w + '.' + s);
  for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'balcon' && !sh.pictures[p.pair + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side);
  const near = b => b[0] > -30 && b[1] > -40 && b[0] + b[2] < 270 && b[1] + b[3] < 246;
  for (const [k, t] of Object.entries(sh.things)) if (t.world && (!near(t.box) || !near(t.hit.box))) P.push('box far off the picture: ' + k + ' ' + JSON.stringify(t.box));
  for (const [k, s] of Object.entries(sh.spots)) if (s.screen[0] < 0 || s.screen[0] > 240 || s.screen[1] < 0 || s.screen[1] > 216) P.push('spot off the picture: ' + k);
  // every place of balcon.js that order 06 found is named in code (by line and numbers)
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('balcon.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; const es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n)))) P.push('balcon.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  // the frog's hop counts (Gate A): every pair of LUGAR places keeps the old count
  let worst = 99;
  for (const h of sh.hops) {
    if (h.old !== h.new) P.push('hops ' + h.a + ' - ' + h.b + ': old ' + h.old + ' (' + h.dOld + ' px), new ' + h.new + ' (' + h.dNew + ' px)');
    if (h.dNew > 0) { const m = Math.min(...[3, 45, 75, 105].map(e => Math.abs(h.dNew - e))); worst = Math.min(worst, m); }
  }
  if (worst < 2) P.push('hops: a distance is ' + worst.toFixed(1) + ' px from a rounding edge (keep 2 px)');
  notes.push('hops: ' + sh.hops.length + ' pairs of LUGAR places, every count as the old one; the nearest to a rounding edge is ' + worst.toFixed(1) + ' px from it');
  // hint frames: order 30b checks them in the VIEW, at every ask of every story (checks: hint frames, at the end); a frame of a thing no story asks
  // for is only noted
  // nothing green or decorative over a touch box (decision 14): the pixels of the bushes, the hanging plants, the posts, the roof inside a set thing's hit box
  const DECOR = ['arbusto', 'plantas', 'postes'];
  for (const door of ['shut', 'open']) {
    const parts = G['parts.' + door];
    for (const [k, t] of Object.entries(sh.things)) {
      if (!t.hit) continue;
      const b = t.hit.box;
      for (const d of DECOR) {
        const n = (parts[d] || []).filter(i => { const x = i % 240, y = (i / 240) | 0; return x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3]; }).length;
        if (n) P.push('door ' + door + ': ' + n + ' pixels of ' + d + ' inside the hit box of ' + k);
      }
    }
  }
  notes.push('decor: no pixel of ' + DECOR.join(', ') + ' inside any set thing\'s hit box (both doors)');

  /* round 2 (the fresh readers' findings 1, 2), round 3 (findings 1, 3, 4) and round 4 (the perch) */
  const E = engine(G), F = G.F, COS = Math.sqrt(3) / 2, T30 = Math.tan(Math.PI / 6);
  const tags = G['parts.shut'], tagAt = {}; for (const [k, list] of Object.entries(tags)) for (const i of list) tagAt[i] = k;
  const countTag = (r, names) => { let n = 0; for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) if (names.includes(tagAt[y * 240 + x])) n++; return n; };
  // 1: every drink's base (a glass n, g or p, or a jug) at every table place stands inside the table top's ellipse, 2 px in from its rim
  const top = E.project(F.TABLE[0], F.TABLE[1], F.FLOOR + F.TABLE_H), ra = F.TABLE_R * E.S - 2, rb = F.TABLE_R * E.S / 2 - 1, MY = sh.MESA_Y.new;
  const BASE = { 'glass n': [-5, 4], 'glass g': [-6, 5], 'glass p': [-4, 3], jug: [-7, 6] }, H = { 'glass n': 13, 'glass g': 22, 'glass p': 9, jug: 22 };
  let worstIn = 99, behind = 0;
  for (const n of ['mesa.izq', 'mesa.der', 'mesa.centro', 'mesa.toma']) { const x = Math.round(sh.points[n].screen[0]);
    for (const [k, [a, b]] of Object.entries(BASE)) for (const px of [x + a, x + b]) {
      const e = Math.pow((px + .5 - top.sx) / ra, 2) + Math.pow((MY - top.sy) / rb, 2);
      if (e > 1) P.push('table: the base of a ' + k + ' at ' + n + ' (x ' + px + ', row ' + MY + ') is not inside the table top');
      worstIn = Math.min(worstIn, ra * Math.sqrt(Math.max(0, 1 - Math.pow((MY - top.sy) / rb, 2))) - Math.abs(px + .5 - top.sx));
      // 2: behind the drink, from its base to its top, no pixel of the window, its shutters or its flower box
      const nb = countTag([px - 1, MY - H[k] - 1, 3, H[k]], ['ventana', 'jardinera', 'flores']); behind += nb; if (nb) notes.push('  behind a ' + k + ' at ' + n + ' (x ' + px + '): ' + nb + ' window pixels');
    } }
  if (behind) P.push('table: ' + behind + ' pixels of the window or its flower box behind the drinks');
  notes.push('table: every drink\'s base (glass n, g, p, jug at mesa.izq, der, centro, toma) inside the table top, ' + worstIn.toFixed(1) + ' px from its rim at the least (2 px more than the check asks); behind them no pixel of the window, the shutters or the flower box');
  // round 4: the bird on PERCH stands on the window's flower box, as the old picture: its feet on the box's top front edge (the box's front face
  // under them, its bare soil over them: no flower within 6 px of its feet in the 4 rows over them (its legs; its body hides what is higher),
  // so it is not sunk into the flowers; the box's top at its feet row, so it does not float). Its box (drawAve: 31 x 25 over its feet) touches nothing it could hide in any story moment: abuela in her chair
  // (with her glass, the jug over her head), abuela standing at any of her places (her whole sprite, 48 x 51, with her tray), the drinks at
  // every table place, the glass on the small chair, the frog at any of his places with what he holds
  { const q = sh.points.PERCH.screen.map(Math.round), w = sh.points.PERCH.world;
    const onEdge = Math.abs(w[1] - (F.HY1 + F.BOXD)) < 1e-3 && Math.abs(w[2] - F.BZ1) < 1e-3 && w[0] > F.BOX0 + .3 && w[0] < F.BOX1 - .3;
    if (!onEdge) P.push('perch: the bird\'s feet are not on the flower box\'s top front edge, in its middle (' + JSON.stringify(w) + ')');
    const face = countTag([q[0] - 4, q[1] + 1, 9, 3], ['jardinera']), feet = countTag([q[0] - 4, q[1], 9, 1], ['jardinera']), soil = countTag([q[0] - 4, q[1] - 3, 9, 3], ['jardinera']);
    const sunk = countTag([q[0] - 6, q[1] - 4, 13, 6], ['flores']);
    if (face < 27) P.push('perch: under the bird\'s feet ' + face + ' of 27 px are the flower box\'s front');
    if (feet < 9 || soil < 27) P.push('perch: the bird\'s feet are not on the flower box\'s top (' + feet + ' of 9 px at its feet, ' + soil + ' of 27 over them)');
    if (sunk) P.push('perch: ' + sunk + ' px of flowers round the bird\'s feet (sunk into the flowers)');
    const bird = [q[0] - 15, q[1] - 23, 31, 25], hit = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
    const gap = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
    const A = sh.points.ABS.screen.map(Math.round), MY = sh.MESA_Y.new, X = n => Math.round(sh.points[n].screen[0]);
    const others = { 'abuela in her chair, her glass, the jug over her head': [A[0] + 4, A[1] - 12, 46, 62] };
    for (const sp of ['abuela.mesa', 'abuela.lado', 'abuela.camina', 'abuela.puerta']) { const ab = sh.spots[sp].ab; others[sp + ' (her sprite, her tray)'] = [ab[0] - 30, ab[1] - 50, 48, 51]; }
    others['the drinks on the table'] = [X('mesa.toma') - 9, MY - 25, X('mesa.der') + 20 - X('mesa.toma') + 9, 26];
    { const a = sh.points.ASIENTO.screen.map(Math.round); others['the glass on the small chair'] = [a[0] - 9, a[1] - 26, 21, 26]; }
    for (const [k, l] of Object.entries(sh.lugar)) { const fw = Math.round(30 * l.scale) + 2, fh = Math.round(25 * l.scale) + 2, fx = Math.round(l.q[0] + (32 - fw) / 2), fy = l.q[1] + 27 - fh;
      others['the frog at ' + k + ' with what he holds'] = [fx, fy - 14, fw + 20, fh + 14]; }
    let near = 99;
    for (const [k, r] of Object.entries(others)) { if (hit(bird, r)) P.push('perch: the bird touches ' + k); near = Math.min(near, gap(bird, r)); }
    notes.push('perch: on the flower box\'s top front edge, in its middle (' + face + ' px of its front under the feet, ' + soil + ' of bare soil over them, ' + sunk + ' px of flowers round them); clear of abuela (sitting, standing anywhere), her glass, every drink and the frog by ' + near + ' px at the least; ' + (MY - 25 - (bird[1] + bird[3])) + ' px over the drinks\' tops'); }
  // round 3, finding 3: abuela standing (at the table, beside her chair, pair se sienta.no) is on clear floor: drawn after the furniture and the
  // drinks (ab.y >= behind), and truly in front of them there: no pixel of the table, a chair or the small chair inside her box is nearer than
  // her, and her box covers no drink at any table place
  { const Z = G['z.shut'], OY = E.OY, ABS = sh.points.ABS.screen;
    const dk = []; for (const n of ['mesa.izq', 'mesa.der', 'mesa.centro', 'mesa.toma']) { const x = Math.round(sh.points[n].screen[0]); dk.push([x - 9, sh.MESA_Y.new - 25, 21, 26]); }
    for (const sp of ['abuela.mesa', 'abuela.lado', 'abuela.camina']) {
      const ab = sh.spots[sp].ab, u = (ab[0] - E.OX) / E.S, v = (ab[1] - 1 - OY + .3 * COS * E.S) / (E.S * .5), vAb = ((u + v) / Math.SQRT2 + (v - u) / Math.SQRT2) / Math.SQRT2;
      let near = 0; for (let y = ab[1] - 50; y < ab[1]; y++) for (let x = ab[0] - 13; x < ab[0] + 13; x++) { const i = y * 240 + x; if (['mesa', 'silla_pequena', 'silla_grande'].includes(tagAt[i]) && Z[i] > vAb / COS - (y + .5 - OY) * T30 / E.S) near++; }
      const cover = dk.filter(d => ab[0] + 13 > d[0] && ab[0] - 13 < d[0] + d[2]).length;
      if (ab[1] < sh.behind.new) P.push(sp + ': drawn before the furniture (ab.y ' + ab[1] + ' < ' + sh.behind.new + ')');
      if (near) P.push(sp + ': ' + near + ' pixels of furniture nearer than her inside her box');
      if (cover) P.push(sp + ': her box covers ' + cover + ' drink places');
      notes.push(sp + ' ' + JSON.stringify(ab) + ': drawn after the furniture and the drinks; ' + near + ' furniture pixels nearer than her in her box; ' + (Math.min(...dk.map(d => d[0])) - (ab[0] + 13)) + ' px from her box to the drinks'); } }
  // round 4: pair 8 (gracias): abuela in her chair (abCaja, her glass at ABS + 36, 28) and the frog's whole box (frogBox at his spot abuela) inside both pictures
  { const A = sh.points.ABS.screen.map(Math.round), l = sh.lugar.abuela, fw = Math.round(30 * l.scale) + 2, fh = Math.round(25 * l.scale) + 2, fx = Math.round(l.q[0] + (32 - fw) / 2), fy = l.q[1] + 27 - fh;
    for (const side of ['si', 'no']) { const c = sh.pictures['gracias.' + side].crop, inside = r => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
      if (!inside([A[0] + 4, A[1], 46, 50])) P.push('pair gracias.' + side + ': abuela or her glass is cut (crop ' + JSON.stringify(c) + ')');
      if (!inside([fx, fy, fw, fh])) P.push('pair gracias.' + side + ': the frog is cut (crop ' + JSON.stringify(c) + ', frog ' + JSON.stringify([fx, fy, fw, fh]) + ')'); }
    const c = sh.pictures['gracias.si'].crop; notes.push('pair gracias: crop ' + JSON.stringify(c) + ', zoom 1: abuela from row ' + A[1] + ', the frog to row ' + (fy + fh) + ', both whole'); }
  // round 3, finding 4: the door, its frame and abuela standing in it are inside the wide view, 8 px or more from its sides
  { const x0 = sh.views.wide.x0, d = sh.things.puerta.box, cl = sh.clips['puerta.hueco'].box, ab = sh.spots['abuela.puerta'].ab;
    const L = Math.min(d[0], Math.max(ab[0] - 30, cl[0])), R = Math.max(d[0] + d[2], Math.min(ab[0] + 18, cl[0] + cl[2]));
    const chair = sh.things.silla_grande.box, mL = L - x0, mR = x0 + 196 - R;
    if (mR < 8 || mL < 8) P.push('wide view: the door or abuela in it ' + Math.min(mL, mR) + ' px from its side (keep 8)');
    if (chair[0] - x0 < 6) P.push('wide view: abuela\'s big chair ' + (chair[0] - x0) + ' px from its left side');
    notes.push('wide view (x0 ' + x0 + '): the door, its frame and abuela in it from x ' + L + ' to ' + R + ', ' + mR + ' px from the right side; the big chair ' + (chair[0] - x0) + ' px from the left side'); }
  storyChecks(sh, P, notes);
  return P;
}

/* ---------- order 30b: every moment of the scene's stories (the faults a reader found in the real app's frames) ---------- */
// The moments: every state of every run of the scene's stories (right, wrong, alternate), as the old page plays them: coqui/tool/ref/trazas/juega.mjs
// --only <story> --states, into a temp folder (about 1.5 s a story; nothing in the repo is written), W after every step in OLD places, moved to the
// new ones as balcon-preview.html's remapW moves them (the same rule, written again here: remapW below).
const FRAME_OUT = 12;     // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const BOARDS = {          // the boards juego.js hud draws on the view (balcon.js hud, tarjeta): picture rectangles once the view's x0 is added
  rondas: [[2, 2, 72, 27], [122, 2, 71, 27]],                                   // tanteo(5, 5) the frog's, tanteo(DW - 71, 5) the bird's, with their icons
  termo: [[141, 3, 52, 64]],                                                    // termo(DW - 51, 7): the thermometer and its sun
};
function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'balcon') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'balcon-sheet-'));
  try {
    const runs = [];
    for (const st of stories) {
      execFileSync(process.execPath, [path.join(REPO, 'coqui/tool/ref/trazas/juega.mjs'), '--only', st.id, '--out', path.join(tmp, 'trazas', st.id), '--states', path.join(tmp, 'states')], { cwd: REPO, stdio: 'pipe' });
      for (const plan of ['right', 'wrong', 'alternate']) {
        const lines = fs.readFileSync(path.join(tmp, 'states', st.id, plan + '.states.jsonl'), 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
        runs.push({ story: st, plan, lines });
      }
    }
    return runs;
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}
// balcon-preview.html remapW: the frog to the nearest frog spot, abuela to the nearest of hers (within 60, by the same offset); a glass or jug on the table
// to the new place of its old one (X2, the middle, the pair's 106; any other x keeps its offset from the middle); one on the small chair to its seat; the
// bird on the flower box or the small chair to its point, on the table beside a glass as acts.aveva puts it (19 px on the middle's side), else its pair point
function remapW(w0, sh) {
  const w = JSON.parse(JSON.stringify(w0)), ptR = n => sh.points[n].screen.map(Math.round), TC = ptR('mesa.centro')[0];
  const near = (list, x, y) => { let best = null, bd = 60; for (const e of list) { const d = Math.hypot(e.old[0] - x, e.old[1] - y); if (d < bd) { bd = d; best = e; } } return best; };
  const frogs = Object.values(sh.spots).filter(s => s.frog).map(s => ({ old: s.old, new: s.frog })), abs = Object.values(sh.spots).filter(s => s.ab).map(s => ({ old: s.old, new: s.ab }));
  const move = (list, q) => { if (!q || q.x == null) return q; const e = near(list, q.x, q.y); return e ? Object.assign({}, q, { x: q.x + e.new[0] - e.old[0], y: q.y + e.new[1] - e.old[1] }) : q; };
  const TX = { 106: 'mesa.toma', 108: 'mesa.izq', 120: 'mesa.centro', 132: 'mesa.der' }, tableX = x => TX[x] ? ptR(TX[x])[0] : x - 120 + TC;
  const glass = v => v.y != null && Math.abs(v.x - 160) < 2 ? Object.assign({}, v, { x: ptR('ASIENTO')[0], y: ptR('ASIENTO')[1] - 1 }) : Object.assign({}, v, { x: tableX(v.x) });
  const bird = a => { if (!a || a.x == null || a.mode === 'head' || a.mode === 'none') return a; const o = Object.assign({}, a);
    if (Math.abs(a.x - 120) < 2 && Math.abs(a.y - 86) < 2) [o.x, o.y] = ptR('PERCH');
    else if (Math.abs(a.x - 160) < 2 && Math.abs(a.y - 135) < 2) [o.x, o.y] = ptR('ASIENTO');
    else if (Math.abs(a.y - 128) < 2) {
      const v = (w0.vasos || []).concat(w0.jarras || []).find(v => v.y == null && a.x === v.x + (v.x < 120 ? 19 : -19)), PB = { 127: 'ave.mesa.toma', 132: 'ave.mesa.der' };
      if (v) { const nx = tableX(v.x); o.x = nx + (nx < TC ? 19 : -19); } else o.x = PB[a.x] ? ptR(PB[a.x])[0] : a.x - 120 + TC;
      o.y = sh.MESA_Y.new; }
    return o; };
  w.cq = move(frogs, w.cq); if (w.ab) w.ab = move(abs, w.ab);
  if (w.vasos) w.vasos = w.vasos.map(glass); if (w.jarras) w.jarras = w.jarras.map(glass);
  w.ave = bird(w.ave);
  return w;
}
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };   // juego.js frogBox
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
// a glass or a jug on the table, as the rectangles balcon.js vaso and jarra fill (outline and straw; every other pixel is inside them)
function drinkRects(v, MY) {
  const by = v.y != null ? v.y : MY;
  if (v.t) { const VT = { n: [9, 13], g: [11, 17], p: [7, 9] }, [w, h] = VT[v.t], x = Math.round(v.x - w / 2), y = by - h;
    return [[x - 1, y, w + 2, h], [x, by, w, 1]].concat(v.k === 'jugo' ? [[x + w - 3, y - 5, 3, 5]] : []); }
  const x = v.x - 6, y = by - 21;
  return [[x + 1, y, 9, 7], [x - 2, y, 4, 3], [x - 1, y + 6, 13, 15], [x, y + 21, 11, 1], [x + 11, y + 7, 4, 2], [x + 14, y + 8, 2, 8], [x + 11, y + 15, 4, 2]];
}

function storyChecks(sh, P, notes) {
  const inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), OLDCAM = inv.given.CAM;
  const ptR = n => sh.points[n].screen.map(Math.round), ABS = ptR('ABS'), TL = ptR('talk.lado'), MY = sh.MESA_Y.new;
  const viewOf = cam => { const k = Object.keys(OLDCAM).find(k => OLDCAM[k].every((v, i) => Math.abs(v - cam[i]) < .01)); return k ? sh.views[k] : null; };
  const runs = storyStates();
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;

  /* 1. every bubble wholly inside the view, clear of the boards shown, and on no face (abuela's, the frog's) */
  // who can speak at a moment: abuela's bubble (W.ab.bub), and the ones the acts show for a moment inside a step: her "amor" when she is touched
  // (poke: any moment she can be touched) and her "feliz" at the end of que-calor (acts.final, the thermometer up); the frog's (W.cq.bub), and his
  // "amor" and "mal" (acts.gana, cqbebe, marcador: at any of his places)
  const bubblesOf = (w, acts = true) => {
    const out = [], faces = [], ab = w.ab, q = w.cq;
    if (ab && !(ab.al < .5)) {
      const sit = ab.en === 'silla', t = sit ? (w.rondas ? TL : [ABS[0] + 17, ABS[1] - 1]) : [Math.round(ab.x), Math.round(ab.y) - 51];
      faces.push(['abuela\'s face', sit ? [ABS[0] + 10, ABS[1] + 5, 15, 13] : [Math.round(ab.x) - 8, Math.round(ab.y) - 42, 15, 12]]);
      const ks = new Set(ab.bub ? [ab.bub] : []); if (acts && (ab.al == null || ab.al > .5)) ks.add('amor'); if (acts && w.termo && sit) ks.add('feliz');
      for (const k of ks) out.push(['abuela (' + (sit ? 'sitting' : ab.en + ' ' + Math.round(ab.x) + ',' + Math.round(ab.y)) + ') "' + k + '"', bubbleRect(k, t[0], t[1])]);
    }
    if (q && q.vis && !(q.al < .5)) {
      const b = frogBox(q); faces.push(['the frog\'s face', [b.x, b.y, b.w, Math.round(b.h * .6)]]);
      for (const k of new Set((acts ? [q.bub, 'amor', 'mal'] : [q.bub]).filter(Boolean))) out.push(['the frog (' + q.x + ',' + q.y + ') "' + k + '"', bubbleRect(k, b.x + (b.w >> 1), b.y + 2)]);
    }
    return { out, faces };
  };
  let nB = 0, nM = 0, worstView = 99, worstBoard = 99;
  const seen = new Set();
  const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
  const judge = (where, rect, box, boards, faces) => {
    if (!within(rect, box)) { P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is not wholly inside ' + JSON.stringify(box)); return; }
    worstView = Math.min(worstView, rect[0] - box[0], box[0] + box[2] - rect[0] - rect[2], rect[1] - box[1], box[1] + box[3] - rect[1] - rect[3]);
    for (const [bn, b] of boards) { if (meets(rect, b)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is over the ' + bn + ' ' + JSON.stringify(b)); else worstBoard = Math.min(worstBoard, gapTo(rect, b)); }
    for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is on ' + fn + ' ' + JSON.stringify(f));
  };
  for (const r of runs) for (const L of r.lines) {
    const v = viewOf(L.cam); if (!v) { P.push(r.story.id + ' ' + r.plan + ' ' + L.path + ': a view the sheet does not have ' + JSON.stringify(L.cam)); continue; }
    const w = remapW(L.W, sh), boards = [];
    if (w.rondas) for (const b of BOARDS.rondas) boards.push(['score board', [b[0] + v.x0, b[1], b[2], b[3]]]);
    if (w.termo) for (const b of BOARDS.termo) boards.push(['thermometer board', [b[0] + v.x0, b[1], b[2], b[3]]]);
    const { out, faces } = bubblesOf(w); nM++;
    for (const [who, rect] of out) { const key = JSON.stringify([who, rect, v.x0, boards]); if (seen.has(key)) continue; seen.add(key); nB++;
      judge(r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + who, rect, [v.x0, 0, 196, 216], boards, faces); }
  }
  // every review picture of cual-balcon (balcon-preview.html PV.pair: panelW()'s W, then the item's set), in its crop
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-balcon.json'), 'utf8'));
  let nP = 0;
  for (const it of cual.items) for (const side of ['si', 'no']) {
    const spec = it[side], w0 = Object.assign({ ab: { en: 'puerta', x: 178, y: 125, pose: 'idle', bub: null, al: 1, trae: 0 }, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: spec.set && spec.set.resp ? 1 : 0, bub: null } }, JSON.parse(JSON.stringify(spec.set || {})));
    const w = remapW(w0, sh), pc = sh.pictures[it.w + '.' + side], { out, faces } = bubblesOf(w, false);   // a pair shows only the bubbles its W has: no act runs in it
    for (const [who, rect] of out) { nP++; judge('pair ' + it.w + '.' + side + ': ' + who, rect, pc.crop, [], faces); }
  }
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments of ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + '), and ' + nP + ' in the review pictures: each wholly inside the view (' + worstView + ' px from its edge at the least), clear of the score and thermometer boards when they are up (' + worstBoard + ' px at the least), on no face');

  /* 2. every set of drinks the stories put on the table at once: side by side, none drawn over another (and, checked above for every table place:
     their bases inside the table top, plain wall behind them). The sets: every moment of every run, each also with the sides swapped (dos() and pone()
     draw the side: azar), and the sets balcon.js's acts can make */
  const X = n => ptR(n)[0], SW = { [X('mesa.izq')]: X('mesa.der'), [X('mesa.der')]: X('mesa.izq') };
  const sets = new Map(), addSet = (items, from) => { if (items.length < 2) return; const k = JSON.stringify(items.map(v => [v.t || 'jarra', v.k, v.x]).sort()); if (!sets.has(k)) sets.set(k, { items, from }); };
  const onTable = w => (w.vasos || []).filter(v => !v.mano && v.y == null).concat((w.jarras || []).filter(v => !v.mano));
  let fanOver = 0;
  for (const r of runs) for (const L of r.lines) { const w = remapW(L.W, sh), it = onTable(w);
    addSet(it, r.story.id + ' ' + r.plan + ' ' + L.path); addSet(it.map(v => Object.assign({}, v, { x: SW[v.x] != null ? SW[v.x] : v.x })), r.story.id + ' ' + r.plan + ' ' + L.path + ', sides swapped');
    if (w.fanMesa && it.some(v => drinkRects(v, MY).some(a => meets(a, [X('mesa.abanico') - 1, MY - 9, 11, 12])))) fanOver++; }
  for (const s of [0, 1]) { const x2 = [X('mesa.izq'), X('mesa.der')], g = (k, t, x) => ({ k, t, x }), j = (k, x) => ({ k, x });
    addSet([g('jugo', 'n', x2[s]), g('agua', 'n', x2[1 - s])], 'dos("ja")'); addSet([g('jugo', 'g', x2[s]), g('jugo', 'p', x2[1 - s])], 'dos("gp")'); addSet([g('agua', 'n', x2[0]), g('agua', 'n', x2[1])], 'dos("fin")');
    addSet([j('jugo', x2[s]), j('agua', x2[1 - s])], 'pone()'); addSet([j('jugo', x2[s]), j('agua', x2[1 - s]), g('jugo', 'n', X('mesa.centro'))], 'pone() and aparta()'); addSet([j('jugo', x2[s]), j('agua', x2[1 - s]), g('agua', 'n', X('mesa.centro'))], 'pone() and aparta()'); }
  let worstGap = 99;
  for (const { items, from } of sets.values()) for (let a = 0; a < items.length; a++) for (let b = a + 1; b < items.length; b++) {
    const ra = drinkRects(items[a], MY), rb = drinkRects(items[b], MY);
    if (ra.some(p => rb.some(q => meets(p, q)))) P.push('drinks: at ' + from + ' the ' + (items[a].t ? 'glass' : 'jug') + ' at x ' + items[a].x + ' and the ' + (items[b].t ? 'glass' : 'jug') + ' at x ' + items[b].x + ' are drawn over each other');
    else worstGap = Math.min(worstGap, Math.min(...ra.flatMap(p => rb.map(q => gapTo(p, q)))));
  }
  notes.push('drinks: ' + sets.size + ' sets of drinks on the table at once (the stories\' moments, their sides swapped, the acts\' sets): side by side, none drawn over another (' + worstGap + ' px apart at the least' + (worstGap === 0 ? ': touching' : '') + ')' + (fanOver ? '; NOT a drink: her half fan left on the table (fanMesa) is drawn over a drink at ' + fanOver + ' moments, as the old picture drew it' : ''));

  /* 4. every hint frame wholly inside the view it is shown in: at every ask and decide of every run (its thing as the scene boxes it where it stands
     then), and every set thing a story of the scene asks for, in every view */
  const boxOf = (w, k) => {
    const t = sh.things[k]; if (t && t.world) return t.box;
    if (k === 'abuela') { const ab = w.ab; if (!ab) return null; return ab.en === 'silla' ? sh.things.abuela.box.silla.new : [Math.round(ab.x) - 13, Math.round(ab.y) - 50, 26, 50]; }
    const v = (w.vasos || []).find(v => v.id === k) || (w.jarras || []).find(v => v.id === k); if (!v) return null;
    if (v.t) { const VT = { n: [9, 13], g: [11, 17], p: [7, 9] }, s = VT[v.t], y = v.y || MY; return [Math.round(v.x - s[0] / 2) - 4, y - s[1] - 6, s[0] + 8, s[1] + 9]; }   // balcon.js cajaDe
    return [v.x - 9, MY - 24, 26, 27];
  };
  const frameIn = (b, x0) => b[0] - FRAME_OUT >= x0 && b[0] + b[2] + FRAME_OUT <= x0 + 196 && b[1] - FRAME_OUT >= 0 && b[1] + b[3] + FRAME_OUT <= 216;
  let nF = 0, nCards = 0, worstF = 99; const asked = new Set();
  for (const r of runs) { const Ls = r.lines;
    Ls.forEach((L, i) => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(M => M.path === L.path || (M.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const before = Ls[j - 1], st = at(r.story, L.path), V = before.V;
      const spot = st.ask ? sub(st.ask, V) : (sub(st.pick, V) || sub((st.options || [])[0], V));
      const w = remapW(before.W, sh), b = boxOf(w, spot), v = viewOf(before.cam);
      if (!b) { nCards++; return; }                                              // an answer card (de_nada, gracias): the game places it
      asked.add(spot); nF++;
      if (!v || !frameIn(b, v.x0)) P.push('hint frame: ' + r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + spot + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not wholly inside the view from x ' + (v && v.x0));
      else worstF = Math.min(worstF, b[0] - FRAME_OUT - v.x0, v.x0 + 196 - (b[0] + b[2] + FRAME_OUT), b[1] - FRAME_OUT, 216 - (b[1] + b[3] + FRAME_OUT)); }); }
  for (const r of runs) JSON.stringify(r.story).replace(/"(?:ask|pick)":\s*"([a-z_]+)"/g, (m, k) => { if (sh.things[k] && sh.things[k].world) asked.add(k); return m; });
  for (const [k, t] of Object.entries(sh.things)) if (t.world) for (const [vn, v] of Object.entries(sh.views)) if (!frameIn(t.box, v.x0)) {
    if (asked.has(k)) P.push('hint frame: ' + k + ' ' + JSON.stringify(t.box) + ' +- ' + FRAME_OUT + ' is not wholly inside the ' + vn + ' view (x0 ' + v.x0 + ')');
    else if (vn === 'wide') notes.push('hint frame of ' + k + ' (no story of the scene asks for it): ' + JSON.stringify(t.box) + ' +- ' + FRAME_OUT + ' reaches past the view from x ' + v.x0); }
  notes.push('hint frames: ' + nF + ' at the asks of the runs (' + nCards + ' asks for an answer card, the game\'s), and every set thing a story asks for (' + [...asked].filter(k => sh.things[k] && sh.things[k].world).join(', ') + ') in every view: box +- ' + FRAME_OUT + ' wholly inside the view, ' + worstF + ' px from its edge at the least');
}
