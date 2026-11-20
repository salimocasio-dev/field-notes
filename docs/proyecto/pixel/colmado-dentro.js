'use strict';
/* Don Pepe's colmado, inside: one room on the Pixel Plays engine, shared by three scene sets of place 4
   (mostrador, estantes, caja). Each <id>-set.html sets PP_SCENE (its own origin) and OPT, loads pp-engine.js, mapa.js,
   set-kit.js and this file, then calls colmadoDentro(OPT) from its buildSet.
   The room (world units; S = 26): two walls meet at the far corner (0, 0). The back wall is y = 0 (it faces +y: lit) and
   carries the shelves; the left wall is x = 0 (it faces +x: in shade) and has the shop window and the street door. The counter runs
   along the back wall, with don Pepe's aisle between them; the back door to the store room is beside the corner. The room is far
   bigger than any picture of it (RX1, RY1): every framing shows floor and wall to its left, right and bottom edges, and only above
   the walls' tops is the picture's outside colour (the set pages' DARK). Everything that moves (people, goods taken down, coins,
   bags) is a sprite.
   OPT:
     hora   'manana' | 'tarde'      what shows through the street door, and the patch of light on the floor
     atras  'shut' | 'open'         the back door (to the store room: dim, with sacks and boxes in it)
     props  true                    stand-in goods on the shelves (for the readers' renders; the game draws them as sprites)
     nevera true                    the little chest freezer on the counter (story 38)
     escalera true                  the ladder against the second run's top shelf (estantes)
     caja   false                   no cash register (it stands at the counter's left end unless this is false)
     vitrina false                  no shop window in the left wall (it is there unless this is false)
     anillos true                   six rings of dust on the second run's middle shelf (story 39)
     mesa   true                    the low display table in front of the second run of shelves (story 40)
   Exports for the sheets (world x, y, z): ESCALERA_PIE, ESCALERA_ALTO (the ladder's foot, and the point at 3/4 of its height),
   CAJA_VENTANA, CAJA_GAVETA, CAJA_REPISA (the register's amount window, its drawer front, the top of its side shelf: where the frog sits),
   NEVERA (the freezer's box), MESA, MESA_H (the table and the height of its top). */
const CD = (() => {
  const RX1 = 21, RY1 = 12, WH = 3.3;                          // the room: floor to x, to y; wall height. Big, so no framing shows an edge
  const CX0 = 1.3, CX1 = 6.2, CY0 = 2.0, CY1 = 2.85, CH = 1.0;   // the counter
  const SX0 = 1.5, SX1 = 6.5, SD = .36, SXM = 5.5;                          // the shelves: along the back wall, their depth
  const SZ = [1.3, 1.95, 2.6];                                  // the planks' heights
  const BD0 = .15, BD1 = 1.25, DH = 2.55;                        // the back door (x on the back wall), beside the corner: don Pepe's way to the store room
  const PD0 = 3.6, PD1 = 5.0;                                   // the street door (y on the left wall)
  const VW0 = 1.45, VW1 = 3.15, VZ0 = 1.0, VZ1 = 2.45;            // the shop window (y on the left wall), between the corner and the street door
  const E2X0 = 11.0, E2X1 = 15.0;                               // the second run of shelves, far along the back wall, with open floor in front (estantes): the mostrador framing never shows it
  const WALL = [244, 222, 150], DADO = [86, 170, 160], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92], TOP = [224, 196, 150];
  const MESA = [E2X0 + 1.3, 3.7], MESA_H = .55;                 // the low display table (story 40): its middle, the height of its top (the cloth)
  const SILLA = [6.9, 4.5];                                     // the waiting chair, in front of the counter's right end, clear of it (a half unit further out and a fifth to the right: it did seem stuck to the counter)
  const TILE = [[236, 224, 200], [214, 190, 160], [176, 150, 122]];
  const MAT = [.08, PD0 + .12, .8, PD1 - .12];                  // the doormat, on the floor just inside the street door: x0, y0, x1, y1
  const LEAF_TURN = .28;                                        // the street door's open leaf stands this many radians off the wall
  const XB = (SX1 + E2X0) / 2;                                  // the bunch of plantains hangs in the middle of the bare wall between the runs
  const GOODS = [                                              // k, shelf (0 low, 1 middle), x: where each stands (sheet: spots estante.<k>)
    ['leche', 0, 1.95], ['pan', 0, 2.75], ['mantequilla', 0, 3.55], ['queso', 0, 4.35], ['cafe', 0, 5.1],
    ['arroz', 1, 2.2], ['azucar', 1, 3.1], ['jugo', 1, 4.0], ['habichuelas', 1, 4.9],
  ];
  // the ladder: its feet on the floor a unit in front of the second run, its rails resting on the top plank's front edge
  const LX = E2X0 + 2.0, LY0 = SD + .04 + 1.0, LKZ = SZ[2] + .06, LTOP = LKZ + .26, LW = .3;   // x of its middle, y of its feet, z of the plank's edge, z of the rails' tops, half the width between rails
  const LSLOPE = (SD - LY0) / LKZ;                              // y moves this far for each unit of z going up
  const ladderY = z => LY0 + LSLOPE * z;
  const ESCALERA_PIE = [LX, LY0, 0], ESCALERA_ALTO = [LX, ladderY(LTOP * .75), LTOP * .75];
  // the register at the counter's left end: its box, then its parts' measures
  const RG = { x0: CX0 + .1, x1: CX0 + 1.15, y0: CY0 + .05, y1: CY1 - .05, bodyH: .32, headY: CY0 + .05 + .3, headH: .6 };
  const RGM = (RG.x0 + RG.x1) / 2;
  const SHELF = { x0: RG.x1, x1: RG.x1 + .3, y0: RG.y0 + .08, y1: RG.y0 + .44, z: CH + .25 };   // the small shelf on the register's right side (12 px wide)
  const CAJA_VENTANA = [RGM, RG.headY, CH + RG.bodyH + .4];
  const CAJA_GAVETA = [RGM, RG.y1, CH + RG.bodyH / 2];
  const CAJA_REPISA = [(SHELF.x0 + SHELF.x1) / 2, (SHELF.y0 + SHELF.y1) / 2, SHELF.z];
  const NV = { x0: CX1 - 1.1, x1: CX1 - .2, y0: CY0 + .15, y1: CY0 + .7, h: .49 };   // the chest freezer on the counter's right end (26 px wide)
  const NEVERA = [NV.x0, NV.y0, CH, NV.x1, NV.y1, CH + NV.h + .05];
  const PX = S / R2;                                            // screen pixels along x - y, per world unit
  const stepDown = v => Math.floor(v / ST) * ST;
  const paneX = (at, b0, b1, z0, z1, fn) => { for (let b = b0; b <= b1; b += ST * .5) for (let z = z0; z <= z1; z += ST * .5) { const c = fn(b, z); if (c) plot(at, b, z, c); } };
  const band = (c, k) => rgb(c[0] * k, c[1] * k, c[2] * k);
  // a flat picture on the plane x = xp (stood a little off the left wall), judged at the middle of each screen pixel, so a thin line is never lost to its neighbour:
  // fn(b, z) gives a colour or 0; the pixels of the rectangle b0..b1 x z0..z1 are walked and each is drawn where the plane is
  function pixelsX(xp, b0, b1, z0, z1, fn) {
    const cs = [[b0, z0], [b1, z0], [b0, z1], [b1, z1]].map(([b, z]) => project(xp, b, z));
    const ix0 = Math.floor(Math.min(...cs.map(c => c.sx))) - 1, ix1 = Math.ceil(Math.max(...cs.map(c => c.sx))) + 1, iy0 = Math.floor(Math.min(...cs.map(c => c.sy))) - 1, iy1 = Math.ceil(Math.max(...cs.map(c => c.sy))) + 1;
    for (let iy = iy0; iy <= iy1; iy++) for (let ix = ix0; ix <= ix1; ix++) {
      const u = (ix + .5 - OX) / S, b = xp - u * R2, v = (xp + b) / R2, z = (v * SIN - (iy + .5 - OY) / S) / COS;
      if (b < b0 || b > b1 || z < z0 || z > z1) continue;
      const c = fn(b, z);
      if (c) plot(xp, b, z, c);
    }
  }
  // a picture of one-pixel cells on a +y face (y = at): rows of characters, the middle of the picture on the face point (x, z);
  // key maps a character to a colour (a missing one leaves the face as it is)
  function stampY(at, x, z, rows, key) {
    const plane = at + .004, p = project(x, plane, z), cx = Math.floor(p.sx) - (rows[0].length >> 1), cy = Math.floor(p.sy) - (rows.length >> 1);
    paneY(plane, x - .4, x + .4, z - .4, z + .4, (a, zz) => {
      const q = project(a, plane, zz), r = Math.floor(q.sy) - cy, k = Math.floor(q.sx) - cx;
      return r >= 0 && r < rows.length ? key[rows[r][k]] : 0;
    });
  }

  function floorAt(x, y, ix, iy, i) {
    if (x < 0 || y < 0 || x > RX1 || y > RY1) return 0;
    kinds[i] = KIND_ROAD;
    if (x > MAT[0] && x < MAT[2] && y > MAT[1] && y < MAT[3]) {      // the doormat: coir, a dark border, stripes across it
      const e = Math.min(x - MAT[0], MAT[2] - x, y - MAT[1], MAT[3] - y);
      if (e < .06) return rgb(70, 46, 34);
      const k = hash(ix, iy) < .16 ? 1.14 : 1, stripe = Math.floor((y - MAT[1]) / .15) % 2;
      return rgb(...(stripe ? [138, 94, 64] : [112, 74, 52]).map(v => v * k));
    }
    const ta = x / .62, tb = y / .62, ea = ta - Math.floor(ta), eb = tb - Math.floor(tb);
    if (ea < .06 || eb < .06) return rgb(...TILE[2]);
    return rgb(...TILE[(Math.floor(ta) + Math.floor(tb)) % 2 ? 1 : 0]);
  }

  // a store room seen through the open back door: its floor, its two walls (the back one lit), two sacks and a stack of boxes.
  // Only what a sight line through the doorway reaches is drawn (a sight line runs one unit down for every T units back)
  function storeRoom() {
    const T = Math.tan(Math.PI / 6) * Math.SQRT2, X0 = -1.7, Y0 = -1.9;
    const seen = (x, y, z) => { const d = x - y, h = z - T * y; return d > BD0 - .05 && d < BD1 + .05 && h > -.05 && h < DH + .05; };
    const put = (x, y, z, c) => { if (seen(x, y, z)) plot(x, y, z, c); };
    const FL = rampOf([142, 114, 86]), BK = rampOf([112, 88, 66]), SD = rampOf([84, 66, 52]);   // the floor is a little lighter than the walls
    for (let a = X0; a <= BD1 + .1; a += ST) for (let b = Y0; b <= 0; b += ST) put(a, b, 0, FL[Math.floor((a - b) / .34) % 2 ? 3 : 2]);
    for (let a = X0; a <= BD1 + .1; a += ST) for (let z = 0; z <= DH + .3; z += ST) put(a, Y0, z, BK[z > 1.6 ? 2 : 3]);
    for (let b = Y0; b <= 0; b += ST) for (let z = 0; z <= DH + .3; z += ST) put(X0, b, z, SD[2]);
    // the stack of boxes against the back wall: flat faces, a tape across each
    const y0 = Y0 + .03, y1 = Y0 + .5;
    [[-.95, -.25, 0, .3, [196, 152, 100]], [-.9, -.3, .3, .58, [176, 134, 88]], [-.93, -.28, .58, .84, [204, 160, 106]], [-.88, -.33, .84, 1.08, [186, 144, 96]]].forEach(([x0, x1, z0, z1, c]) => {
      const BX = rampOf(c);
      for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) put(a, b, z1, BX[4]);
      for (let a = x0; a <= x1; a += ST) for (let z = z0; z <= z1; z += ST) put(a, y1, z, (z1 - z < .035 || z - z0 < .025) ? BX[1] : (Math.abs(z - (z0 + z1) / 2) < .025 ? BX[4] : BX[3]));
      for (let b = y0; b <= y1; b += ST) for (let z = z0; z <= z1; z += ST) put(x1, b, z, BX[1]);
    });
    // two sacks on the floor in front: a round body, a tied neck
    const sack = (x, y) => {
      sphere(x, y, .18, .2, [190, 164, 116], 'solid'); sphere(x, y, .34, .19, [190, 164, 116], 'solid');
      sphere(x, y, .5, .12, [168, 142, 98], 'solid'); sphere(x + .02, y, .6, .07, [140, 114, 76], 'solid');
    };
    sack(.2, -.45); sack(.43, -.55);
  }

  function walls(o) {
    const aLo = Math.max(0, stepDown((-6 - OX) / PX)), aHi = Math.min(RX1, (W + 6 - OX) / PX);       // only the stretch of each wall a picture can show is drawn
    const bLo = Math.max(0, stepDown((OX - W - 6) / PX)), bHi = Math.min(RY1, (OX + 6) / PX);
    part('pared', () => {
      // the back wall, with the back door's hole; a painted dado along its foot
      wallY(0, aLo, aHi, 0, WH, WALL, [[BD0, BD1, 0, DH]]);
      for (let a = aLo; a <= aHi; a += ST) { if (a > BD0 && a < BD1) continue; for (let z = 0; z <= .9; z += ST) plot(a, .01, z, shade(DADO, z > .84 ? 1.4 : 2.4, a, z)); }
      // the left wall, with the street door's hole (and the window's)
      const holes = [[PD0, PD1, 0, DH]]; if (o.vitrina !== false) holes.push([VW0, VW1, VZ0, VZ1]);
      for (let b = bLo; b <= bHi; b += ST) {
        const hs = holes.filter(h => b > h[0] && b < h[1]);
        for (let z = 0; z <= WH; z += ST) {
          if (hs.some(h => z > h[2] && z < h[3])) continue;
          plot(0, b, z, shade(z <= .9 ? DADO : WALL, z <= .9 ? (z > .84 ? .6 : 1.3) : 1.3, b, z));
        }
      }
    });
    part('puerta_atras', () => {
      if (o.atras === 'open') storeRoom();
      reveal(0, BD0, BD1, 0, DH, .2, WALL);
      const F = rampOf(WOOD_L), Wd = rampOf(WOOD), w = BD1 - BD0;
      for (let z = 0; z <= DH + .12; z += ST * .5) for (let a = 0; a <= .12; a += ST * .5) { plot(BD0 - .12 + a, .03, z, F[2]); plot(BD1 + a, .03, z, F[2]); }
      for (let a = BD0 - .12; a <= BD1 + .12; a += ST * .5) for (let z = DH; z <= DH + .12; z += ST * .5) plot(a, .03, z, F[3]);
      const panel = (t, z) => { const u = t * w, edge = u < .08 || u > w - .08 || z < .08 || z > DH - .08; return Wd[edge ? 1 : (Math.abs(z - 1.25) < .05 ? 1 : 2)]; };
      if (o.atras === 'open') leaf(BD1, -.05, w, 0, DH, Math.PI + 1.3, (t, z) => panel(t, z));
      else paneY(-.05, BD0, BD1, 0, DH, (a, z) => panel((BD1 - a) / w, z));
    });
    part('puerta', () => {
      // the street, through the door: a plane outside the left wall
      const tarde = o.hora === 'tarde';
      const sky = tarde ? [[250, 176, 96], [252, 200, 120], [254, 224, 160]] : [[120, 186, 250], [162, 211, 255], [208, 234, 255]];
      paneX(-.5, PD0 - .5, PD1 + .1, 0, DH + .2, (b, z) => {
        if (z < 1.0) return rgb(...(tarde ? [214, 150, 110] : [186, 200, 196]));               // the house across the street
        if (z < 1.12) return rgb(...(tarde ? [176, 92, 70] : [176, 96, 80]));                  // its eaves
        return rgb(...sky[clamp(Math.floor((z - 1.12) / 1.5 * 3), 0, 2)]);
      });
      for (let a = -.5; a <= 0; a += ST) for (let b = PD0 - .5; b <= PD1 + .1; b += ST) plot(a, b, 0, rgb(...(tarde ? [206, 178, 150] : [190, 186, 176])));   // the pavement
      const F = rampOf(WOOD_L);
      for (let z = 0; z <= DH + .12; z += ST * .5) for (let b = 0; b <= .12; b += ST * .5) { plot(.03, PD0 - .12 + b, z, F[1]); plot(.03, PD1 + b, z, F[1]); }
      for (let b = PD0 - .12; b <= PD1 + .12; b += ST * .5) for (let z = DH; z <= DH + .12; z += ST * .5) plot(.03, b, z, F[2]);
      // the door leaf, open into the shop, back against the wall away from the corner (the window is on the corner side), its free edge a little
      // off the wall. The shop front's own door (colmado-fuera.js): a wooden frame, panels below, a pane in the upper half with a light on it, a handle
      const w = PD1 - PD0, R = rampOf(WOOD_L), PANE = [[150, 200, 214], [176, 218, 232]];
      const hx = .05, hy = PD1 + .14;
      leaf(hx, hy, w, 0, DH, Math.PI / 2 - LEAF_TURN, (t, z) => {
        const u = t * w;                                                                          // from the hinge
        if (t > .985 || z < .03 || z > DH - .02) return R[0];                                     // the leaf's edges: thick, in its own shadow
        if (u < .1 || u > w - .1 || z < .1 || z > DH - .1) return R[3];                           // the frame: stiles and rails
        const glass = u > .2 && u < w - .2 && z > 1.3 && z < DH - .25;
        if (glass) {
          const edge = u < .24 || u > w - .24 || z < 1.34 || z > DH - .29;
          if (edge) return R[1];
          const s = z + 1.15 * u;                                                                 // diagonal lights
          if ((s > 2.5 && s < 2.66) || (s > 2.86 && s < 2.94)) return rgb(244, 252, 255);
          return rgb(...PANE[z > 1.9 ? 1 : 0]);
        }
        if (z > 1.1 && z < 1.3) return R[3];                                                     // the middle rail
        const inset = u > .2 && u < w - .2 && z > .22 && z < 1.1;                                 // the panel below
        if (inset) { const e = u < .25 || u > w - .25 || z < .27 || z > 1.05; return e ? R[1] : R[2]; }
        return R[3];
      });
      const hp = (t, z0, c) => { const q = [hx + Math.cos(Math.PI / 2 - LEAF_TURN) * w * t, hy + Math.sin(Math.PI / 2 - LEAF_TURN) * w * t]; return [q[0] + .02, q[1], z0, c]; };
      for (const [x, y, z, c] of [hp(.9, 1.15, rgb(250, 214, 96)), hp(.02, .4, rgb(120, 90, 40)), hp(.02, 2.05, rgb(120, 90, 40))])
        for (let da = -.04; da <= .04; da += ST * .4) for (let dz = -.04; dz <= .04; dz += ST * .4) if (da * da + dz * dz < .0016) plot(x + .02 - da * Math.sin(LEAF_TURN), y + da * Math.cos(LEAF_TURN), z + dz, c);
    });
    if (o.vitrina !== false) part('vitrina', () => {
      const tarde = o.hora === 'tarde';
      paneX(-.5, VW0 - .5, VW1 + .1, 0, DH + .2, (b, z) => z < 1.0 ? rgb(...(tarde ? [214, 150, 110] : [186, 200, 196])) : rgb(...(tarde ? [252, 200, 120] : [162, 211, 255])));
      const F = rampOf(WOOD_L);
      for (let b = VW0 - .1; b <= VW1 + .1; b += ST * .5) for (const z of [VZ0 - .1, VZ1]) for (let h = 0; h <= .1; h += ST * .5) plot(.03, b, z + h, F[2]);
      for (let z = VZ0 - .1; z <= VZ1 + .1; z += ST * .5) for (const b of [VW0 - .1, VW1, (VW0 + VW1) / 2 - .04]) for (let h = 0; h <= .08; h += ST * .5) plot(.03, b + h, z, F[2]);
      block(.03, VW0 + .05, VZ0 - .12, .3, VW1 - .05, VZ0 - .04, WOOD_L, TOP);   // the sill inside: a shelf for what is shown in the window
    });
    // a round wall clock above the pier between the window and the door, over everyone's head. Drawn as a picture of one-pixel cells (13 x 13) on the
    // pixel where the wall point (bc, zc) falls, so it is the same in every framing: a dark rim 2 px thick, a white face, two dark hands (10 past 10)
    // and four dark dots at 12, 3, 6 and 9, nothing else
    if (o.reloj) part('reloj', () => {      // off unless asked for: at 13 px it was read as a vent or a plate, and no story of place 4 needs a clock
      const bc = (VW1 + .1 + PD0 - .12) / 2, zc = 2.95, c0 = project(.08, bc, zc), cx = Math.floor(c0.sx), cy = Math.floor(c0.sy);
      const RIM = rgb(62, 42, 34), FACE = rgb(252, 250, 244), INK = rgb(32, 26, 28);
      const hands = new Set(['0,0', '-1,-1', '1,-1', '2,-1', '3,-2']), dots = new Set(['0,-3', '3,0', '0,3', '-3,0']);
      pixelsX(.08, bc - .45, bc + .45, zc - .5, zc + .5, (b, z) => {
        const q = project(.08, b, z), dx = Math.floor(q.sx) - cx, dy = Math.floor(q.sy) - cy, r = Math.hypot(dx, dy);
        if (r > 6.4) return 0;
        if (r > 4.4) return RIM;
        return hands.has(dx + ',' + dy) || dots.has(dx + ',' + dy) ? INK : FACE;
      });
    });
    // a hanging bunch of plantains on the bare wall between the two runs of shelves: a nail, a stem, two tiers of fingers
    part('racimo', () => {
      const x = XB, y = .1, Dk = [78, 58, 40], greens = [[132, 184, 62], [168, 200, 76], [112, 164, 56]], Ye = [238, 210, 84];
      sphere(x, .06, 2.9, .04, [54, 46, 42], 'solid');                                            // the nail
      capsule([x, y - .03, 2.88], [x, y - .01, 2.56], .018, .022, () => [150, 118, 74], 'solid');   // the cord
      capsule([x, y, 2.56], [x, y + .03, 2.3], .045, .055, () => [104, 92, 52], 'solid');         // the stem
      // two hands of fingers, hanging, each bowed outward and curling back in at the tip
      [[2.5, 3, .22, .56, 0], [2.36, 4, .2, .52, .04]].forEach(([z0, n, spread, len, dy], t) => {
        for (let k = 0; k < n; k++) {
          const s = (k - (n - 1) / 2), c = (k + t) % 5 === 2 ? Ye : greens[(k + t) % 3];
          const a = [x + s * .025, y + .03 + dy, z0], m = [x + s * spread, y + .08 + dy, z0 - len * .5], e = [x + s * spread * .8, y + .1 + dy, z0 - len];
          capsule(a, m, .05, .06, () => c, 'solid'); capsule(m, e, .06, .042, () => c, 'solid');
          sphere(e[0], e[1], e[2] - .02, .026, Dk, 'solid');
        }
      });
    });
  }

  function counter(o) {
    part('mostrador', () => {
      block(CX0, CY0, 0, CX1, CY1, CH - .07, WOOD);
      block(CX0 - .06, CY0 - .06, CH - .07, CX1 + .06, CY1 + .08, CH, TOP);
      // boards on its front, a darker foot
      for (let a = CX0; a <= CX1; a += ST * .7) for (let z = 0; z <= CH - .08; z += ST * .7) {
        const seam = ((a - CX0) % .5) < .04;
        if (seam || z < .1) plot(a, CY1 + .01, z, rampOf(WOOD)[z < .1 ? 0 : 1]);
      }
    });
    // the chest freezer: a white body with a blue snowflake and a vent grille on its front, a metal frame round a sliding glass lid
    // (two clear light-blue panes, each with a white diagonal reflection)
    if (o.nevera) part('nevera', () => {
      const { x0, x1, y0, y1, h } = NV, z0 = CH, z1 = CH + h, zt = z1 + .05, xm = (x0 + x1) / 2, METAL = [158, 166, 178];
      block(x0, y0, z0, x1, y1, z1, [238, 242, 248], [226, 236, 244]);
      paneY(y1 + .005, x0, x1, z0, z1, () => rgb(250, 252, 255));                                  // the white front
      for (let b = y0; b <= y1; b += ST * .5) for (let z = z0; z <= z1; z += ST * .5) plot(x1 + .005, b, z, rgb(200, 210, 224));   // and its side, in shade but still white
      block(x0 - .03, y0 - .03, z1, x1 + .03, y1 + .03, zt, METAL, [176, 184, 196]);                // the lid's frame
      for (let a = x0 + .02; a <= x1 - .02; a += ST * .6) for (let b = y0 + .02; b <= y1 - .02; b += ST * .6) {
        const ex = Math.min(a - x0, x1 - a), ey = Math.min(b - y0, y1 - b);
        let c;
        if (ex < .07 || ey < .07 || Math.abs(a - xm) < .022) c = rgb(...METAL);                      // the frame, and the rail between the two panes
        else {
          const p = 3 * (a - x0) - (b - y0), k = (b - y0) / (y1 - y0);                               // lines that run up and to the right on the screen
          if ((p > .46 && p < .8) || (p > 1.86 && p < 2.2)) c = rgb(255, 255, 255);                // the two white reflections, one on each pane
          else c = rgb(176 - 58 * k, 224 - 40 * k, 250 - 12 * k);                                    // a clear light blue, paler at the back
        }
        plot(a, b, zt + .004, c);
      }
      const flake = ['...#...', '#..#..#', '.#.#.#.', '#######', '.#.#.#.', '#..#..#', '...#...'], grille = ['######', '......', '######', '......', '######', '......', '######'];
      stampY(y1 + .03, x0 + .27, z0 + h / 2, flake, { '#': rgb(36, 104, 214) });
      stampY(y1 + .03, x1 - .26, z0 + h / 2, grille, { '#': rgb(92, 106, 126) });
    });
    // the old cash register: a dark body, a raised head with a pale amount window and a brass cap and bell, rows of round keys, a drawer front
    // with a handle, and a small shelf on its right side where the frog sits
    if (o.caja !== false) part('caja', () => {
      const { x0, x1, y0, y1, bodyH, headY, headH } = RG, z0 = CH, zk = z0 + bodyH, zh = zk + headH;
      const BODY = [58, 62, 76], HEAD = [74, 80, 98], BRASS = [232, 190, 80], BRASS_L = [252, 222, 120];
      block(x0, y0, z0, x1, y1, zk, BODY, [92, 98, 116]);                                           // the body
      block(x0 + .08, y0, zk, x1 - .08, headY, zh, HEAD, [104, 110, 130]);                         // the head, set back and raised
      block(x0 + .1, y0 - .02, zh, x1 - .1, headY + .03, zh + .04, BRASS, [240, 206, 108]);            // its brass cap
      paneY(headY + .006, RGM - .26, RGM + .26, zk + .27, zk + .5, (a, z) => (Math.abs(a - RGM) > .235 || z < zk + .295 || z > zk + .475) ? rgb(22, 24, 30) : rgb(226, 242, 212));   // the amount window (numerals are sprites)
      paneY(headY + .006, x0 + .1, x1 - .1, zk + .1, zk + .14, () => rgb(...BRASS));
      for (let r = 0; r < 3; r++) for (let k = 0; k < 5; k++) {                                       // rows of round keys on the body's top
        const cx = x0 + .2 + k * .17, cy = headY + .1 + r * .13;
        drum(cx, cy, zk, zk + .035, .034, k === 4 ? [232, 190, 80] : [238, 232, 216], (a, b) => (a < 0 && b < 0) ? rgb(255, 255, 250) : 0);
      }
      sphere(RGM, y0 + .14, zh + .13, .09, BRASS, 'solid');                                         // the bell
      sphere(RGM, y0 + .14, zh + .23, .03, [60, 50, 40], 'solid');
      // the drawer front, with its handle
      paneY(y1 + .006, x0 + .06, x1 - .06, z0 + .04, zk - .03, (a, z) => {
        const e = Math.min(a - x0 - .06, x1 - .06 - a, z - z0 - .04, zk - .03 - z);
        if (e < .02) return rgb(26, 28, 36);
        if (Math.abs(a - RGM) < .17 && z > z0 + bodyH / 2 - .035 && z < z0 + bodyH / 2 + .02) return rgb(...(z > z0 + bodyH / 2 ? BRASS_L : BRASS));
        return rgb(104, 110, 128);
      });
      // the side shelf: a board and two braces to the register's side
      const { x0: sx0, x1: sx1, y0: sy0, y1: sy1, z: sz } = SHELF;
      block(sx0, sy0, sz - .05, sx1, sy1, sz, WOOD, TOP);
      for (const b of [sy0 + .04, sy1 - .04]) for (let t = 0; t <= 1; t += ST * .4) for (let d = 0; d < .04; d += ST * .5) plot(sx0 + (1 - t) * .01 + t * (sx1 - sx0 - .03), b, sz - .05 - (1 - t) * .16 - d, rgb(...WOOD));
    });
  }

  function shelves(o) {
    part('estantes', () => {
      for (const x of [SX0, SXM, SX1]) block(x - .05, .02, 0, x + .05, SD, WH - .25, WOOD);
      for (const z of SZ) block(SX0, .02, z, SX1, SD, z + .06, WOOD_L, TOP);
      block(SX0, .02, 0, SX1, SD + .04, .5, WOOD);                                       // a low cupboard under them
    });
    // stock that never moves: the top shelf, and the right half of the others
    part('surtido', () => {
      const z2 = SZ[2] + .06, z1 = SZ[1] + .06, z0 = SZ[0] + .06;
      const cans = [[204, 60, 50], [70, 130, 190], [236, 190, 70], [90, 160, 96]];
      for (let k = 0; k < 16; k++) { const x = SX0 + .3 + k * .41; if (x > SX1 - .2) break; if (Math.abs(x - SXM) < .2) continue; drum(x, .2, z2, z2 + .3, .13, cans[k % 4]); }
      for (let k = 0; k < 5; k++) { const x = SXM + .3 + k * .42; if (x > SX1 - .2) break; block(x - .15, .06, z1, x + .15, .3, z1 + .36 + (k % 2) * .08, [[226, 150, 80], [150, 110, 170], [240, 232, 210]][k % 3]); }
      for (let k = 0; k < 5; k++) { const x = SXM + .3 + k * .42; if (x > SX1 - .2) break; drum(x, .2, z0, z0 + .42, .1, [[60, 110, 70], [120, 70, 40], [60, 110, 70]][k % 3]); sphere(x, .2, z0 + .47, .05, [200, 200, 190], 'solid'); }
    });
    if (o.props) part('generos', () => {
      for (const [k, s, x] of GOODS) standIn(k, x, .19, SZ[s] + .06);
    });
    part('estantes2', () => {
      for (const x of [E2X0, E2X1]) block(x - .05, .02, 0, x + .05, SD, WH - .25, WOOD);
      for (const z of SZ) block(E2X0, .02, z, E2X1, SD, z + .06, WOOD_L, TOP);
      block(E2X0, .02, 0, E2X1, SD + .04, .5, WOOD);
      const z0 = SZ[0] + .06;                                                     // the low shelf: sacks and boxes that never move
      for (let k = 0; k < 8; k++) { const x = E2X0 + .4 + k * .47; block(x - .17, .06, z0, x + .17, .3, z0 + .3 + (k % 3) * .06, [[226, 150, 80], [240, 232, 210], [150, 110, 170], [110, 160, 200]][k % 4]); }
    });
    // story 39: three small rings (7 px wide) and three large (10 px), on the middle shelf's top: dark ovals one pixel wide, so they read as rings at 1x.
    // The ladder stands in front of the shelf's middle: one small ring shows between its rails, the other five are clear of it
    if (o.anillos) part('anillos', () => {
      const z = SZ[1] + .06 + .004, ring = rgb(136, 104, 72), cy = (.02 + SD) / 2;
      [[.42, .16, .105], [.98, .16, .105], [1.58, .16, .105], [2.4, .22, .145], [3.0, .22, .145], [3.6, .22, .145]].forEach(([dx, rx, ry]) => {
        const cx = E2X0 + dx;
        for (let a = cx - rx - .02; a <= cx + rx + .02; a += ST * .5) for (let b = cy - ry - .02; b <= cy + ry + .02; b += ST * .5) {
          const q = Math.hypot((a - cx) / rx, (b - cy) / ry);
          if (q <= 1 && q > .62) plot(a, b, z, ring);
        }
      });
    });
    // the ladder: two rails 3 px thick and seven rungs 2 px thick, drawn pixel by pixel so nothing has gaps; it leans on the top plank's edge
    if (o.escalera) part('escalera', () => {
      const dpx = 1 / (2 * PX);                                                   // a world step that moves a point one screen pixel sideways (x up, y down by it: the same depth)
      const RAIL = [rgb(236, 198, 132), rgb(196, 150, 88), rgb(126, 86, 50)], RUNG = [rgb(240, 206, 140), rgb(150, 104, 62)];
      const n = 700;
      for (const side of [-1, 1]) for (let k = 0; k <= n; k++) {
        const z = LTOP * k / n, y = ladderY(z);
        for (let q = -1; q <= 1; q++) plot(LX + side * LW + q * dpx, y - q * dpx, z, RAIL[q + 1]);
      }
      for (let r = 1; r <= 7; r++) {
        const z = LTOP * r / 8, y = ladderY(z);
        for (let a = LX - LW; a <= LX + LW; a += .008) for (let q = 0; q < 2; q++) plot(a, y + .01, z - q * .0445, RUNG[q]);
      }
      for (const side of [-1, 1]) { castShadow(LX + side * LW, LY0 + .03, .02, .13, 1, .15); castShadow(LX + side * LW + .1, LY0, .02, .1, 1, .15); }
    });
    // the low table: a cloth over a top on four legs, the floor showing between them
    if (o.mesa) part('mesa', () => {
      const [x, y] = MESA, x0 = x - .8, x1 = x + .8, y0 = y - .45, y1 = y + .45, zp = MESA_H - .08, CLOTH = [246, 240, 224], BORDER = [168, 206, 222];
      for (const [lx, ly] of [[x0 + .08, y0 + .08], [x1 - .16, y0 + .08], [x0 + .08, y1 - .16], [x1 - .16, y1 - .16]]) block(lx, ly, 0, lx + .09, ly + .09, zp, WOOD, WOOD_L);   // the legs
      block(x0, y0, zp - .05, x1, y1, zp, WOOD, TOP);                                                                                                                            // the top
      const cx0 = x0 - .05, cx1 = x1 + .05, cy0 = y0 - .05, cy1 = y1 + .05, hang = .09;
      for (let a = cx0; a <= cx1; a += ST * .7) for (let b = cy0; b <= cy1; b += ST * .7) {                                                                                        // the cloth's top, with a pale blue border
        const e = Math.min(a - cx0, cx1 - a, b - cy0, cy1 - b);
        plot(a, b, MESA_H, e > .06 && e < .1 ? rgb(...BORDER) : shade(CLOTH, 3.4, a, b));
      }
      for (let a = cx0; a <= cx1; a += ST * .7) for (let z = MESA_H - hang; z <= MESA_H; z += ST * .7) plot(a, cy1, z, (z - (MESA_H - hang)) < .035 ? rampOf(BORDER)[2] : shade(CLOTH, 2.2, a, z));     // its front edge hanging
      for (let b = cy0; b <= cy1; b += ST * .7) for (let z = MESA_H - hang; z <= MESA_H; z += ST * .7) plot(cx1, b, z, (z - (MESA_H - hang)) < .035 ? rampOf(BORDER)[1] : shade(CLOTH, 1.3, b, z));   // and its right edge
      castShadow(x + .15, y + .2, .15, .52, 1, .5);
    });
  }
  // a stand-in for one of the nine things that are bought: the size and the colours its sprite has
  function standIn(k, x, y, z) {
    const B = (hw, h, c, top) => block(x - hw, y - .12, z, x + hw, y + .12, z + h, c, top || c);
    const stripe = (hw, z0, z1, c) => paneY(y + .125, x - hw, x + hw, z + z0, z + z1, () => rgb(...c));
    if (k === 'leche') { B(.15, .46, [244, 246, 250]); stripe(.15, .14, .28, [70, 120, 210]); }
    else if (k === 'pan') { B(.26, .2, [196, 132, 64], [226, 170, 96]); }
    else if (k === 'mantequilla') { B(.22, .13, [250, 222, 96], [255, 236, 140]); stripe(.22, 0, .05, [240, 240, 232]); }
    else if (k === 'queso') { B(.2, .26, [246, 176, 60], [252, 200, 90]); sphere(x - .05, y + .13, z + .15, .04, [214, 140, 40], 'solid'); }
    else if (k === 'cafe') { B(.15, .42, [150, 40, 40]); stripe(.15, .16, .26, [240, 200, 90]); }
    else if (k === 'arroz') { B(.19, .4, [240, 236, 222]); stripe(.19, .1, .22, [70, 150, 90]); }
    else if (k === 'azucar') { B(.17, .38, [150, 200, 240]); stripe(.17, .12, .24, [250, 250, 250]); }
    else if (k === 'jugo') { B(.14, .46, [246, 150, 40]); stripe(.14, .3, .4, [250, 240, 200]); }
    else if (k === 'habichuelas') { drum(x, y, z, z + .32, .15, [190, 50, 50]); paneY(y + .155, x - .1, x + .1, z + .1, z + .22, () => rgb(250, 236, 200)); }
  }

  function light(o) {
    // the contact shadow bakeOcclusion dithers along the walls' feet and the door sills read as a dotted fringe along the floor's edge: take it off again,
    // so the floor meets a wall in a clean line (the floor is repainted from floorAt; nothing casts a shadow there). Round the counter, the chair and
    // the cupboards the contact shadow stays
    const inRun = x => (x > SX0 - .2 && x < SX1 + .2) || (x > E2X0 - .2 && x < E2X1 + .2);
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const i = iy * W + ix; if (!ground[i] || zb[i] !== groundZ[i]) continue;
      const g = unproject(ix + .5, iy + .5);
      if (g.x < .45 || (g.y < .4 && !inRun(g.x))) { const c = floorAt(g.x, g.y, ix, iy, i); if (c) pix[i] = c; }
    }
    // the sun through the street door: a lighter patch on the floor (longer and warmer in the afternoon)
    const tarde = o.hora === 'tarde', len = tarde ? 3.4 : 1.8;
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const i = iy * W + ix; if (!ground[i] || zb[i] !== groundZ[i]) continue;
      const g = unproject(ix + .5, iy + .5), t = g.x / len;
      if (g.x < .02 || t > 1 || g.y < PD0 + t * .5 || g.y > PD1 + t * 1.2) continue;
      const c = pix[i], r = c & 255, gg = (c >> 8) & 255, b = (c >> 16) & 255, k = tarde ? [1.1, 1.02, .86] : [1.08, 1.07, 1.0];
      pix[i] = rgb(Math.min(255, r * k[0] + 8), Math.min(255, gg * k[1] + 6), Math.min(255, b * k[2]));
    }
  }

  function chairs() {
    // the waiting chair, turned to the camera (as El balcón's small chair)
    part('silla', () => {
      const [x, y] = SILLA, TURN = -Math.PI / 4, hw = .4, hd = .28, Y = [226, 190, 96];
      const at = (s, u) => [x + Math.cos(TURN) * s - Math.sin(TURN) * u, y + Math.sin(TURN) * s + Math.cos(TURN) * u];
      const leg = (s, u, z1) => { const q = at(s, u); turnedBox(q[0], q[1], 0, z1, .05, .05, TURN, Y); };
      leg(-hw + .05, hd - .05, .44); leg(hw - .05, hd - .05, .44); leg(-hw + .05, -hd + .05, 1.0); leg(hw - .05, -hd + .05, 1.0);
      turnedBox(x, y, .38, .45, hw, hd, TURN, Y);
      for (const z of [.62, .86]) { const q = at(0, -hd + .05); turnedBox(q[0], q[1], z, z + .08, hw, .04, TURN, Y); }
    });
  }
  function build(o) {
    walls(o); shelves(o); counter(o); chairs();
    castShadow((CX0 + CX1) / 2, CY1 + .1, .5, .5, .5);
    for (let x = CX0 + .4; x <= CX1 - .2; x += .5) castShadow(x, CY1 - .1, .6, .45, .6);
  }
  return { RX1, RY1, WH, CX0, CX1, CY0, CY1, CH, SX0, SX1, SD, SZ, BD0, BD1, DH, PD0, PD1, VW0, VW1, VZ0, VZ1, GOODS, SILLA, MESA, MESA_H, E2X0, E2X1,
    ESCALERA_PIE, ESCALERA_ALTO, CAJA_VENTANA, CAJA_GAVETA, CAJA_REPISA, NEVERA, floorAt, build, light, standIn };
})();
