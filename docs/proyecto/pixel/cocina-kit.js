'use strict';
/* La cocina: the kitchen's shared kit (orders 37, 38, 39: La mesa, La estufa, La nevera). ONE writer: La mesa's designer (order 37).
   Load after pp-engine.js, mapa.js and set-kit.js. Nothing here changes the engine or set-kit.js: each helper only calls plot, planeFace,
   planeQuad, castShadow and the buffers. Once committed, a function here never changes what it draws: the kit only grows.

   The room is one room seen in three scenes, so a learner who has played one knows it again in the next: the same floor, walls, tile band,
   counters and cupboards, window, light and scale. World units as in mapa.js (x and y on the floor, z up), S = 26.

   THE PLAN (as La sala's, order 31a). The corner of the two standing walls is (0, 0); the room is x >= 0, y >= 0.
     the left wall stands on x = 0 and faces +x (in shade); the back wall stands on y = 0 and faces +y (lit). Both are K.T thick.
     The room is cut open as a doll's house: the two near walls are not built, the floor runs off the picture's bottom and sides, the two
     standing walls are cut at K.WH (their cut tops show as a white edge) and above them is the plain dark backdrop K.BACKDROP.
   THE LIGHT (one rule for the whole kitchen, as La sala's indoors): from the upper left, shadows to screen right. Every kitchen set's
     PP_SCENE has s 26, shadowX .9, shadowY -.1 (cocinaCheckScene() throws if not). Furniture casts small, low shadows joined to its foot
     (cocinaShadowBlock, cocinaShadowFoot); a thin thing (a leg, a post) casts only a short contact shadow at its foot, on its shadow side.
   PIECES AGAINST A WALL are placed in the wall's own frame: face 'y' (against the back wall, the front faces +y, lit) or face 'x' (against
     the left wall, the front faces +x, in shade); `a` runs along the wall (world x for 'y', world y for 'x'), `d` out from the wall into the
     room, z up. kpt(face, a, d, z) gives the world point. Of a box in that frame three faces show: its top, its front (d = d1) and its end
     at a = a1 (the other end faces away from the camera).
   Flat faces are drawn one sample a pixel (set-kit.js planeFace / planeQuad), so a whole room bakes in a few tens of ms. */

/* ---------- the room's numbers ---------- */
const K = {
  T: .22, WH: 3.2,                       // the walls' thickness and the height they are cut at (La sala's)
  TILE: .5,                              // a floor tile (La sala's porch tiles are .5 too)
  CZ: 1.3,                               // the counter's top surface: what stands on a counter stands at z = K.CZ
  CTOP: .08, COVER: .05,                 // the counter top's thickness and how far it overhangs the cupboard's front
  CD: .9,                                // a base cupboard's depth from the wall, its top included
  PLINTH: .12, PLINTH_IN: .06,           // the dark kick under a base cupboard: its height and how far it is set back
  BAND0: 1.3, BAND1: 2.2, BTILE: .26,    // the pale blue tile band on the wall behind the counters: from z BAND0 to BAND1, tiles BTILE square
  UZ0: 2.32, UZ1: 3.02, UD: .46,         // a wall cupboard: its bottom and top, its depth
  STW: 1.06, SD: .9,                     // the stove: its width along the wall and its depth (its top is at K.CZ, as the counters')
  HZ0: 2.36, HZ1: 2.62, HD: .62,         // the hood's canopy: bottom and top, depth; its chimney runs from HZ1 up to the cut top
  SKIRT: .13,                            // the skirting board at the foot of the walls
  OUTD: 1.7,                             // how far behind a wall's outer face the outside (the patio, its bush, the sky) stands
};
const KC = {                             // the room's colours ([r, g, b]; the old pictures' where they had them)
  plaster: [246, 236, 196], fleck: [240, 228, 184],                  // cream plaster (old #F6ECC4, #F0E4B8)
  skirt: [200, 184, 138], skirtLine: [122, 106, 74],                  // the skirting (old #C8B88A) and its foot line (old #7A6A4A)
  tile: [228, 240, 244], grout: [184, 208, 216],                      // the tile band (old #E4F0F4, #B8D0D8)
  floorA: [232, 216, 184], floorB: [200, 116, 90], floorG: [154, 106, 84],   // the floor's two tiles and the grout (old #E8D8B8, #C8745A, #9A6A54)
  wood: [146, 96, 46], woodD: [110, 66, 32], woodL: [184, 128, 64], woodLL: [216, 164, 96],   // the cupboards (old RP.wood)
  knob: [240, 192, 32],                                               // the cupboards' brass handles (old #F0C020)
  top: [236, 236, 244], topEdge: [255, 255, 255], topDark: [184, 184, 200],   // the white counter top (old #E8E8F0, #FFFFFF, #B8B8C8)
  plinth: [74, 46, 26],
  steel: [242, 242, 248], steelD: [200, 200, 212], hob: [98, 98, 112], burner: [34, 34, 44], cap: [72, 72, 86],   // the stove
  ovenGlass: [52, 52, 66], handle: [138, 138, 154], red: [208, 48, 42], ovenLit: [184, 72, 24],
  hood: [200, 200, 212], hoodLip: [148, 148, 166],
  frame: [146, 96, 46], frameL: [216, 164, 96], sill: [184, 128, 64],   // the window's wooden frame and sill (old Wd[1], Wd[3])
  sky: [[162, 211, 255], [120, 186, 250], [85, 159, 242]],           // the sky through a window, top to bottom as La sala's
  bush: [[46, 154, 72], [76, 188, 88], [132, 220, 120]], hedge: [[30, 122, 58], [58, 168, 72]], yard: [232, 216, 184], yardTop: [255, 244, 216], yardLine: [168, 152, 120],
  white: [244, 240, 228],
};
K.BACKDROP = [38, 36, 44];               // above the cut walls: La sala's flat dark grey

// a kitchen set's PP_SCENE must carry the kitchen's light and scale
function cocinaCheckScene() {
  if (S !== 26 || SHADOW_X !== .9 || SHADOW_Y !== -.1) throw new Error('cocina-kit: PP_SCENE must have s 26, shadowX .9, shadowY -.1');
}

/* ---------- a wall's frame ---------- */
const kpt = (face, a, d, z) => face === 'y' ? [a, d, z] : [d, a, z];
// the point of the wall plane (x = at for 'x', y = at for 'y') a screen pixel's middle looks at: { a (along the wall), z, d (depth) }
function kWallPixel(face, at, ix, iy) {
  const u = (ix + .5 - OX) / S, k = (iy + .5 - OY) / S;
  const x = face === 'x' ? at : at + u * R2, y = face === 'x' ? at - u * R2 : at;
  const v = (x + y) / R2, z = (v * SIN - k) / COS;
  return { a: face === 'x' ? y : x, z, d: v * COS + z * SIN, x, y };
}
// one ramp step of a colour, by light: lit +y faces and tops as they are, +x faces in shade a step darker and cooler
const kLit = (c, shade) => shade ? [c[0] * .86 + 4, c[1] * .86 + 5, c[2] * .86 + 12] : c;
const kRgb = c => rgb(c[0], c[1], c[2]);
// a box in a wall's frame, every face one sample a pixel: paint(faceName, p, q, shadeSide) -> a colour (rgb()) or 0 for none.
// top: p along a (a0..a1), q along d (d0..d1); front (d = d1): p along a, q = z; end (a = a1): p along d, q = z.
// shadeSide: true where that face looks +x (in shade): the end of a 'y' piece, the front of an 'x' piece
function kBox(face, a0, a1, d0, d1, z0, z1, paint, faces = 'tfe') {
  const P = (a, d, z) => kpt(face, a, d, z), sub = (p, q) => [p[0] - q[0], p[1] - q[1], p[2] - q[2]];
  if (faces.includes('t')) { const o = P(a0, d0, z1); planeQuad(o, sub(P(a1, d0, z1), o), sub(P(a0, d1, z1), o), (s, t) => paint('top', a0 + (a1 - a0) * s, d0 + (d1 - d0) * t, false)); }
  if (faces.includes('f')) { const o = P(a0, d1, z0); planeQuad(o, sub(P(a1, d1, z0), o), sub(P(a0, d1, z1), o), (s, t) => paint('front', a0 + (a1 - a0) * s, z0 + (z1 - z0) * t, face === 'x')); }
  if (faces.includes('e')) { const o = P(a1, d0, z0); planeQuad(o, sub(P(a1, d1, z0), o), sub(P(a1, d0, z1), o), (s, t) => paint('end', d0 + (d1 - d0) * s, z0 + (z1 - z0) * t, face === 'y')); }
}
// a plain box in a wall's frame: top, front and end in one colour by light (top lightest, the lit side, the shade side)
function kSolid(face, a0, a1, d0, d1, z0, z1, c, faces = 'tfe') {
  const R = rampOf(c);
  kBox(face, a0, a1, d0, d1, z0, z1, (f, p, q, sh) => f === 'top' ? R[3] : sh ? R[1] : R[2], faces);
}

/* ---------- the floor: the old picture's two-colour checker tiles, laid on the world's axes ---------- */
// the colour of the floor at (x, y), or 0 outside the room (x < 0 or y < 0). Thin grout lines; no texture, the checker reads at once
function cocinaFloor(x, y) {
  if (x < 0 || y < 0) return 0;
  const ta = x / K.TILE, tb = y / K.TILE, ea = ta - Math.floor(ta), eb = tb - Math.floor(tb);
  if (ea < .06 || eb < .06) return kRgb(KC.floorG);
  return kRgb((Math.floor(ta) + Math.floor(tb)) % 2 ? KC.floorB : KC.floorA);
}

/* ---------- the walls: cream plaster, the skirting, the pale blue tile band at counter height ---------- */
// fn for planeFace: shade = the face looks +x (the left wall). band(a): is the tile band behind this point (a run of counters)
function cocinaWallColour(shade, a, z, band) {
  if (z < K.SKIRT) return kRgb(kLit(z < .03 ? KC.skirtLine : z > K.SKIRT - .03 ? KC.white : KC.skirt, shade));
  if (band && z >= K.BAND0 && z <= K.BAND1) {
    const ta = a / K.BTILE, tz = (z - K.BAND0) / K.BTILE;
    const g = ta - Math.floor(ta) < .1 || tz - Math.floor(tz) < .1 || z > K.BAND1 - .03;
    return kRgb(kLit(g ? KC.grout : KC.tile, shade));
  }
  const f = hash(Math.floor(a * 11), Math.floor(z * 13)) < .07;      // sparse flecks in the plaster (the old picture's)
  return kRgb(kLit(f ? KC.fleck : KC.plaster, shade));
}

/* ---------- a window (or a doorway) in a standing wall ---------- */
// win = { face, a0, a1, z0, z1, view: 'arbusto' | 'patio' | fn(a, z) -> [r,g,b] | null, bars: 'cruz' | 'medio' | 'none', door: false }
// The hole is cut in the wall by cocinaBuild (plan.windows). Drawn: the reveal (the wall's thickness), the outside seen through it with
// depth (a backdrop plane K.OUTD behind the wall: sky, the patio's yard wall and hedge, a bush), the wooden frame standing out of the wall
// with its own depth, the bars, and the sill under it (a window: a ledge into the room; a doorway: none).
function cocinaOutside(win) {
  const { face, a0, a1, z0, z1 } = win, at = -K.T - K.OUTD, mid = (a0 + a1) / 2;
  // the screen box of the hole on the inner face
  const xs = [], ys = [];
  for (const a of [a0, a1]) for (const z of [z0, z1]) { const p = project(...kpt(face, a, 0, z)); xs.push(p.sx); ys.push(p.sy); }
  const ix0 = Math.max(0, Math.floor(Math.min(...xs)) - 1), ix1 = Math.min(W - 1, Math.ceil(Math.max(...xs)) + 1);
  const iy0 = Math.max(0, Math.floor(Math.min(...ys)) - 1), iy1 = Math.min(H - 1, Math.ceil(Math.max(...ys)) + 1);
  for (let iy = iy0; iy <= iy1; iy++) for (let ix = ix0; ix <= ix1; ix++) {
    const w = kWallPixel(face, 0, ix, iy);
    if (w.a <= a0 || w.a >= a1 || w.z <= z0 || w.z >= z1) continue;          // the sight line misses the hole
    const o = kWallPixel(face, at, ix, iy), i = iy * W + ix;
    if (o.d <= zb[i]) continue;
    // what is out there, at the backdrop's point (a along the wall, z): sky above, the patio below
    // (z is lifted by the drop of a sight line over the distance, so the window's middle looks at the backdrop's middle height)
    const c = typeof win.view === 'function' ? win.view(o.a, o.z + KDROP) : kView(win.view || 'arbusto', o.a - mid, o.z + KDROP, ix, iy, win);
    zb[i] = o.d; pix[i] = kRgb(c); kinds[i] = KIND_NONE; ground[i] = 0;
  }
}
// the outside, as a backdrop: r is along the wall from the window's middle, z the height. 'arbusto': sky and one round bush low at the
// right (La mesa's and La estufa's old windows); 'patio': sky with a cloud, the yard's cream wall, the hedge's green before it (La nevera's)
const KDROP = (K.T + K.OUTD) / (COS / SIN / R2);   // how far a sight line falls from a wall's inner face to the backdrop
function kView(kind, r, z, ix, iy, win) {
  // the yard wall's top (z on the backdrop, lifted): by default 42% up the window ('patio') or 30% ('arbusto')
  const horizon = win.horizon == null ? win.z0 + (win.z1 - win.z0) * (kind === 'patio' ? .42 : .3) : win.horizon;
  const skyT = clamp((z - horizon) / 1.8, 0, 1), sky = KC.sky[clamp(Math.floor((1 - skyT) * 3 + (bayerAt(ix, iy) - .5) * .5), 0, 2)];
  if (kind === 'patio') {
    const cl = ((r - .4) / .5) ** 2 + ((z - horizon - 1.3) / .14) ** 2;
    if (z > horizon) return cl < 1 ? [255, 255, 255] : sky;
    if (z > horizon - .1) return KC.yardTop;
    if (z > horizon - .5) return Math.abs(((r + 20) % .55) - .27) < .03 ? KC.yardLine : KC.yard;
    return KC.hedge[(hash(Math.floor(r * 9), Math.floor(z * 6)) > .55) ? 0 : 1];
  }
  // a bush: a round green crown, lit from the upper left; under it the patio's green
  const bx = win.bushA == null ? .45 : win.bushA, bz = win.bushZ == null ? horizon + .15 : win.bushZ, br = win.bushR || .62;
  const dx = (r - bx) / br, dz = (z - bz) / (br * .9), dd = dx * dx + dz * dz;
  if (dd < 1) return KC.bush[clamp(Math.floor(1.6 - dx * .9 + dz * 1.1 + (hash(ix, iy) - .5) * .7), 0, 2)];
  if (z < horizon - .35) return KC.hedge[1];
  return sky;
}
// the frame, bars and sill (call after cocinaBuild has cut the hole, inside plan.furnish)
function cocinaWindow(win) {
  const { face, a0, a1, z0, z1 } = win, Fr = rampOf(KC.frame), FL = kRgb(KC.frameL), w = .1, out = .06;
  // the reveal: the wall's thickness, plaster, seen through the hole (set-kit's reveal / revealX)
  if (face === 'y') reveal(0, a0, a1, z0, z1, K.T, KC.plaster); else revealX(0, a0, a1, z0, z1, K.T, KC.plaster);
  cocinaOutside(win);
  // the bars (in the middle of the wall's thickness): a cross, one upright, or none
  const bars = win.bars || (win.door ? 'none' : 'cruz'), bw = .05, dm = -K.T * .5, zm = z0 + (z1 - z0) * .5, am = (a0 + a1) / 2;
  if (bars !== 'none') kSolid(face, am - bw, am + bw, dm - bw, dm + bw, z0, z1, KC.frame);
  if (bars === 'cruz') kSolid(face, a0, a1, dm - bw, dm + bw, zm - bw, zm + bw, KC.frame);
  // the frame: four boards round the hole, standing `out` from the wall's face, with a lit inner lip
  const board = (b0, b1, c0, c1) => kBox(face, b0, b1, 0, out, c0, c1, (f, p, q, sh) => f === 'top' ? FL : sh ? Fr[1] : Fr[2]);
  board(a0 - w, a0, z0 - (win.door ? 0 : w), z1 + w);
  board(a1, a1 + w, z0 - (win.door ? 0 : w), z1 + w);
  board(a0 - w, a1 + w, z1, z1 + w);
  if (!win.door) {
    board(a0 - w, a1 + w, z0 - w, z0);
    // the sill: a ledge out into the room under the window, its top lit
    const S0 = rampOf(KC.sill);
    kBox(face, a0 - w - .06, a1 + w + .06, 0, .16, z0 - w - .05, z0 - w, (f, p, q, sh) => f === 'top' ? S0[3] : sh ? S0[1] : S0[2]);
  }
}

/* ---------- a base cupboard with its white counter top ---------- */
// face, a0..a1 along the wall. opts: doors (how many door leaves, default by width), drawers: true for a row of drawers under the top,
// noEnd: the end at a1 is against another piece (not drawn). Returns { top: z of the top surface, d1: the front of the top, box }
function cocinaBase(face, a0, a1, opts = {}) {
  const Wd = rampOf(KC.wood), d1 = K.CD - K.COVER, zt = K.CZ - K.CTOP, n = opts.doors || Math.max(1, Math.round((a1 - a0) / .62));
  const ends = opts.noEnd ? 'tf' : 'tfe';
  // the plinth: dark, set back
  kSolid(face, a0, a1 - (opts.noEnd ? 0 : K.PLINTH_IN), 0, d1 - K.PLINTH_IN, 0, K.PLINTH, KC.plinth, opts.noEnd ? 'f' : 'fe');
  // the body and its doors: each door a panel with a darker rim and a lit top edge; a brass handle by the meeting edge
  const dw = (a1 - a0) / n;
  kBox(face, a0, a1, 0, d1, K.PLINTH, zt, (f, p, q, sh) => {
    if (f !== 'front') return Wd[sh ? 1 : 2];
    const k = Math.min(n - 1, Math.floor((p - a0) / dw)), e = p - a0 - k * dw;
    const gap = e < .025 || e > dw - .025, rim = e < .075 || e > dw - .075 || q < K.PLINTH + .07 || q > zt - .07;
    if (gap || q > zt - .025) return Wd[0];
    const hx = k % 2 === 0 ? dw - .13 : .13, handle = n > 1 ? Math.abs(e - hx) < .025 && Math.abs(q - (zt - .32)) < .1 : Math.abs(e - dw / 2) < .1 && Math.abs(q - (zt - .2)) < .025;
    if (handle) return kRgb(kLit(KC.knob, sh));
    return Wd[rim ? (sh ? 1 : 2) : (sh ? 2 : 3)];
  }, ends.replace('t', ''));
  // the white top: a slab overhanging the front, its front edge lit, a darker line under it
  kBox(face, a0, a1 + (opts.noEnd ? 0 : K.COVER * .5), 0, K.CD, zt, K.CZ, (f, p, q, sh) => {
    if (f === 'top') return kRgb(p > a1 - .01 || q > K.CD - .03 ? KC.topEdge : KC.top);
    return kRgb(kLit(q < zt + .025 ? KC.topDark : KC.topEdge, sh));
  }, ends);
  const box = [kpt(face, a0, 0, 0), kpt(face, a1, K.CD, K.CZ)];
  return { top: K.CZ, d1: K.CD, box: [Math.min(box[0][0], box[1][0]), Math.min(box[0][1], box[1][1]), 0, Math.max(box[0][0], box[1][0]), Math.max(box[0][1], box[1][1]), K.CZ] };
}

/* ---------- a wall cupboard: two doors, brass knobs ---------- */
function cocinaWallCupboard(face, a0, a1, opts = {}) {
  const Wd = rampOf(KC.wood), z0 = opts.z0 || K.UZ0, z1 = opts.z1 || K.UZ1, d1 = opts.depth || K.UD, n = opts.doors || 2, dw = (a1 - a0) / n;
  kBox(face, a0, a1, 0, d1, z0, z1, (f, p, q, sh) => {
    if (f === 'top') return Wd[4];
    if (f === 'end') return Wd[1];
    const k = Math.min(n - 1, Math.floor((p - a0) / dw)), e = p - a0 - k * dw;
    if (e < .025 || e > dw - .025 || q < z0 + .03 || q > z1 - .03) return Wd[0];
    const hx = k % 2 === 0 ? dw - .12 : .12;
    if (Math.abs(e - hx) < .03 && Math.abs(q - (z0 + .2)) < .07) return kRgb(kLit(KC.knob, sh));
    const rim = e < .09 || e > dw - .09 || q < z0 + .1 || q > z1 - .1;
    return Wd[rim ? (sh ? 1 : 2) : (sh ? 2 : 3)];
  });
  const b = [kpt(face, a0, 0, z0), kpt(face, a1, d1, z1)];
  return { box: [Math.min(b[0][0], b[1][0]), Math.min(b[0][1], b[1][1]), z0, Math.max(b[0][0], b[1][0]), Math.max(b[0][1], b[1][1]), z1] };
}

/* ---------- a shelf on the wall (La estufa's, for its jars) ---------- */
function cocinaShelf(face, a0, a1, z, opts = {}) {
  const Wd = rampOf(KC.wood), d1 = opts.depth || .3;
  kBox(face, a0, a1, 0, d1, z - .06, z, (f, p, q, sh) => f === 'top' ? Wd[3] : Wd[sh ? 0 : 1]);
  for (const a of [a0 + .12, a1 - .16]) kSolid(face, a, a + .04, 0, d1 * .7, z - .26, z - .06, KC.woodD);
  return { top: z };
}

/* ---------- the stove: a white body, the hob with two burners, a front with knobs and the oven door ---------- */
// face, a0 (its left end along the wall); its width K.STW, depth K.SD, top at K.CZ. opts: knobs (how many, default 2), horno (the oven
// lit: its window glows orange), noEnd (a counter stands against its end at a1). Returns { burners: [world [x, y, z] of each burner's
// middle], top, box, ovenDoor: [p0, p1] world corners of the door }
function cocinaStove(face, a0, opts = {}) {
  const a1 = a0 + K.STW, d1 = K.SD, zt = K.CZ, St = KC.steel, nK = opts.knobs == null ? 2 : opts.knobs;
  const panel0 = zt - .2, door1 = zt - .3, door0 = .14, BR = .2;
  const burners = [[a0 + K.STW * .29, d1 * .5], [a0 + K.STW * .71, d1 * .5]];
  kBox(face, a0, a1, 0, d1, 0, zt, (f, p, q, sh) => {
    if (f === 'top') {
      for (const [ba, bd] of burners) {
        const r = Math.hypot(p - ba, (q - bd) * 1);
        if (r < BR * .45) return kRgb(KC.cap);
        if (r < BR) return kRgb(r > BR - .04 ? KC.cap : KC.burner);
      }
      return kRgb(p < a0 + .03 || p > a1 - .03 || q > d1 - .03 ? KC.steelD : KC.hob);
    }
    if (f === 'end') return kRgb(kLit(q > zt - .04 ? KC.steelD : St, sh));
    // the front: a panel with the knobs, the oven door with its window and handle, a dark foot
    if (q < .06) return kRgb(KC.burner);
    if (q > zt - .03) return kRgb(kLit(KC.steelD, sh));
    if (q > panel0) {
      for (let k = 0; k < nK; k++) { const ka = a0 + K.STW * (k + 1) / (nK + 1); if (Math.abs(p - ka) < .055 && Math.abs(q - (panel0 + .1)) < .05) return kRgb(kLit(KC.red, sh)); }
      return kRgb(kLit(q < panel0 + .025 ? KC.steelD : St, sh));
    }
    const da = p - a0, inDoor = da > .08 && da < K.STW - .08 && q > door0 && q < door1;
    if (!inDoor) return kRgb(kLit(St, sh));
    if (da < .11 || da > K.STW - .11 || q < door0 + .03 || q > door1 - .03) return kRgb(kLit(KC.steelD, sh));       // the door's edge
    if (Math.abs(q - (door1 - .1)) < .03 && da > .22 && da < K.STW - .22) return kRgb(kLit(KC.handle, sh));       // the handle
    if (da > .22 && da < K.STW - .22 && q > door0 + .14 && q < door1 - .2) return kRgb(kLit(opts.horno ? KC.ovenLit : KC.ovenGlass, sh));   // the window
    return kRgb(kLit(St, sh));
  }, opts.noEnd ? 'tf' : 'tfe');
  const b = [kpt(face, a0, 0, 0), kpt(face, a1, d1, zt)];
  return {
    burners: burners.map(([a, d]) => kpt(face, a, d, zt)), top: zt, a0, a1,
    box: [Math.min(b[0][0], b[1][0]), Math.min(b[0][1], b[1][1]), 0, Math.max(b[0][0], b[1][0]), Math.max(b[0][1], b[1][1]), zt],
    ovenDoor: [kpt(face, a0 + .22, d1, door0 + .14), kpt(face, a1 - .22, d1, door1 - .2)],
  };
}
// the hood over the stove: a wide canopy with a darker lip, its chimney up to the cut top of the wall
function cocinaHood(face, a0, opts = {}) {
  const a1 = a0 + K.STW, m = .05, H = rampOf(KC.hood), L = rampOf(KC.hoodLip);
  kBox(face, a0 - m, a1 + m, 0, K.HD, K.HZ0, K.HZ0 + .08, (f, p, q, sh) => f === 'top' ? L[3] : L[sh ? 1 : 2]);
  kBox(face, a0, a1, 0, K.HD - .04, K.HZ0 + .08, K.HZ1, (f, p, q, sh) => f === 'top' ? H[4] : H[sh ? 2 : 3]);
  kBox(face, a0 + K.STW * .3, a1 - K.STW * .3, 0, K.HD * .5, K.HZ1, opts.top || K.WH, (f, p, q, sh) => f === 'top' ? H[4] : H[sh ? 1 : 2]);
}

/* ---------- shadows (the kitchen's one rule: low, to screen right, joined to the thing) ---------- */
// a block standing on the floor, in world coordinates: a soft low shadow round its foot on the shadow side
function cocinaShadowBlock(x0, y0, x1, y1, zs = .3) {
  for (let x = x0; x <= x1 + 1e-9; x += .25) for (let y = y0; y <= y1 + 1e-9; y += .25) castShadow(x, y, zs, .22);
}
// a thin thing (a leg, a post) at (x, y): a short contact shadow at its foot only
function cocinaShadowFoot(x, y, r = .07) { castShadow(x + .04, y, .05, r, 1, .2); }

/* ---------- the room cut open (La sala's build) ---------- */
// plan = { XR, YL: how far the back wall (along x) and the left wall (along y) run; windows: [win, ...] (their holes are cut, their frames
// drawn); band: { x: [[a0, a1], ...], y: [...] } where the tile band runs on each wall; furnish(): draws the pieces; shadows(): casts the
// pieces' shadows; floor(x, y, ix, iy, i): optional, a colour or 0 to override cocinaFloor at a point (a door's threshold) }
// It resets the buffers, lays the floor (kept after the first bake), stands the walls, furnishes, shades, fills the backdrop and bakes.
let COCINA_FLOOR = null;
function cocinaBuild(plan) {
  zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0); shadowMask.fill(0); staticShadow.fill(0);
  tufts.length = 0; leaves.length = 0; pendingShadows.length = 0; slabTops.length = 0; glowReset();
  if (!COCINA_FLOOR) {
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = (plan.floor && plan.floor(g.x, g.y, ix, iy, i)) || cocinaFloor(g.x, g.y);
      if (!c) continue;
      pix[i] = c; ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = KIND_ROAD;
    }
    COCINA_FLOOR = { pix: pix.slice(), zb: zb.slice(), kinds: kinds.slice(), ground: ground.slice() };
  } else {
    pix.set(COCINA_FLOOR.pix); zb.set(COCINA_FLOOR.zb); kinds.set(COCINA_FLOOR.kinds); ground.set(COCINA_FLOOR.ground);
  }
  groundZ.set(zb);
  const holes = f => (plan.windows || []).filter(w => w.face === f);
  const inBand = (f, a) => ((plan.band || {})[f] || []).some(([b0, b1]) => a >= b0 && a <= b1);
  const wall = (f, len) => planeFace(f, 0, 0, len, 0, K.WH, (a, z) => holes(f).some(w => a > w.a0 && a < w.a1 && z > w.z0 && z < w.z1) ? 0 : cocinaWallColour(f === 'x', a, z, inBand(f, a)));
  const P = typeof part === 'function' ? part : (n, fn) => fn();
  P('pared', () => {
    wall('x', plan.YL); wall('y', plan.XR);
    // the cut tops: the wall's thickness, white, a lit edge along the room side
    const E = rampOf(KC.white), T = K.T;
    planeQuad([-T, -T, K.WH], [T, 0, 0], [0, plan.YL + T, 0], () => E[3]);
    planeQuad([0, -T, K.WH], [plan.XR, 0, 0], [0, T, 0], () => E[3]);
    for (let b = 0; b <= plan.YL; b += ST * .8) plot(0, b, K.WH - .02, E[2]);
    for (let a = 0; a <= plan.XR; a += ST * .8) plot(a, 0, K.WH - .02, E[2]);
  });
  (plan.windows || []).forEach((w, k) => P(w.name || 'ventana' + (k ? k : ''), () => cocinaWindow(w)));
  if (plan.furnish) plan.furnish();
  if (plan.shadows) plan.shadows();
  flushShadows(); pendingShadows.length = 0;
  if (plan.occlusion === 'shade') cocinaOcclusion(); else if (plan.occlusion !== 'none') bakeOcclusion();
  staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges();
  skyFill(() => kRgb(K.BACKDROP));
  bakedPix.set(pix); bakedZ.set(zb);
}

/* ---------- added (order 37a, La mesa): the floor's dimming by what stands on it, on the shadow side only ----------
   bakeOcclusion (the engine's) dims the floor round everything on every side, so a chair's leg or a stool's foot gets a dark ring on its lit side
   (upper left) too. cocinaOcclusion dims a floor pixel only by what stands to its left on the screen (the light comes from the upper left):
   the same offsets and tints as bakeOcclusion, those with a negative dx. cocinaBuild uses it when plan.occlusion is 'shade' (without it,
   cocinaBuild draws as before). plan.occlusion 'none': no dimming at all (for a check's picture of the set without its shadows). */
function cocinaOcclusion() {
  const offsets = [];
  for (const r of [2, 4]) for (let k = 0; k < 8; k++) {
    const ox = Math.round(Math.cos(k * Math.PI / 4) * r), oy = Math.round(Math.sin(k * Math.PI / 4) * r * .7);
    if (ox < 0) offsets.push([ox, oy]);
  }
  const n = offsets.length;
  for (let iy = 4; iy < H - 4; iy++) for (let ix = 4; ix < W - 4; ix++) {
    const i = iy * W + ix;
    if (!ground[i] || zb[i] !== groundZ[i]) continue;
    let hits = 0;
    for (const [ox, oy] of offsets) { const j = (iy + oy) * W + ix + ox; if (zb[j] !== groundZ[j]) hits++; }
    if (!hits) continue;
    if (hits >= n) tint(i, .56, .54, .72);
    else if (hits / n > bayerAt(ix, iy)) tint(i, .74, .72, .84);
  }
}

/* ---------- added (order 37a, La mesa): the panel behind the stove ----------
   A dark steel panel on the wall behind the stove, from the hob up to the hood's lip (K.HZ0), as wide as the stove and its hood: what rises from
   a pot (steam, white) is seen against it (the tile band and the plaster are too pale for white: contrast under 2). Its rim a step lighter. */
KC.guard = [66, 68, 82]; KC.guardRim = [118, 120, 136];
function cocinaBackguard(face, a0, opts = {}) {
  const a1 = a0 + K.STW, m = .05, z0 = K.CZ, z1 = opts.top || K.HZ0, G = kRgb(KC.guard), Rm = kRgb(KC.guardRim);
  kBox(face, a0 - m, a1 + m, 0, .015, z0, z1, (f, p, q, sh) => f !== 'front' ? 0 : (p < a0 - m + .04 || p > a1 + m - .04 || q > z1 - .04) ? Rm : G, 'f');
}
