'use strict';
/* Coquí scene sets: helpers that mapa.js's building helpers lack. Shared by every scene set (order 07 on).
   Load after pp-engine.js and mapa.js. World units as in mapa.js: x and y on the ground, z up.
   Every helper that fills a surface steps at ST (= .36 / S) or finer, so a wall has no holes at S = 26.
   Nothing here changes the engine: each helper only calls plot, sphere, capsule, castShadow and the buffers. */

/* ---------- light: pixels that give light keep their colour when the set is dimmed ---------- */
const glowZ = new Float32Array(W * H);
function glowReset() { glowZ.fill(-1e9); }
// plot a pixel that gives light (a lit window, a lit doorway): lightPass leaves it as it is
function plotGlow(x, y, z, color) {
  const p = project(x, y, z), ix = p.sx | 0, iy = p.sy | 0;
  plot(x, y, z, color);
  if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
  const i = iy * W + ix;
  if (zb[i] === Math.fround(p.d)) glowZ[i] = zb[i];
}
// the light of the hour, on everything the set drew (not the sky, not the pixels that give light):
// c' = c * m + a, per channel. darkTufts: the grass blades drawTufts draws each frame take their shaded colours everywhere
// (a dim light: storm, rain, sunset); without it they keep their lit colours (a warm light: dusk)
function lightPass(m, a, darkTufts = true) {
  for (let i = 0; i < W * H; i++) {
    if (zb[i] < -1e8 || glowZ[i] === zb[i]) continue;
    const c = pix[i];
    pix[i] = rgb((c & 255) * m[0] + a[0], (c >> 8 & 255) * m[1] + a[1], (c >> 16 & 255) * m[2] + a[2]);
  }
  if (darkTufts) for (let i = 0; i < W * H; i++) if (kinds[i] === KIND_GRASS) staticShadow[i] = 1;
}
// the same light on one colour, for pixels drawn each frame (swaying leaves)
const lit = (c, L) => L ? [c[0] * L.m[0] + L.a[0], c[1] * L.m[1] + L.a[1], c[2] * L.m[2] + L.a[2]] : c;

/* ---------- the sky: every pixel the ground and the set left empty ---------- */
// fn(ix, iy) gives the colour of the sky at that pixel (screen space: the sky is not in the world)
function skyFill(fn) {
  for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
    const i = iy * W + ix;
    if (zb[i] > -1e8) continue;
    pix[i] = fn(ix, iy);
  }
}
// a sky of dithered bands, from tones[0] at the top to the last tone at the horizon
function skyBands(tones, y0, y1, ix, iy) {
  const t = clamp((iy + .5 - y0) / (y1 - y0), 0, 1) * (tones.length - 1);
  return rgb(...tones[clamp(Math.floor(t + bayerAt(ix, iy) - .5), 0, tones.length - 1)]);
}
// a disc in the sky (the sun), screen space, with a lit rim to the upper left
function skyDisc(cx, cy, r, tones, ix, iy) {
  const dx = ix + .5 - cx, dy = iy + .5 - cy, d = Math.hypot(dx, dy) / r;
  if (d > 1) return 0;
  const l = clamp(1 - d * .55 - (dx + dy) / r * .25, 0, 1);
  return rgb(...tones[clamp(Math.floor(l * (tones.length - .01) + (bayerAt(ix, iy) - .5) * .6), 0, tones.length - 1)]);
}
// far hills on the horizon: two ridges, screen space; returns 0 above them
function skyHills(base, far, near, ix, iy) {
  const y1 = base - 13 - 6 * Math.sin(ix * .029 + 1) - 3 * Math.sin(ix * .083);
  const y2 = base - 6 - 3 * Math.sin(ix * .047 + 3) - 2 * Math.sin(ix * .13);
  if (iy + .5 >= y2) return rgb(...(iy + .5 - y2 < 1 ? near[1] : bayerAt(ix, iy) < (iy - y2) / 10 ? near[2] : near[0]));
  if (iy + .5 >= y1) return rgb(...(iy + .5 - y1 < 1 ? far[1] : bayerAt(ix, iy) < (iy - y1) / 24 ? far[2] : far[0]));
  return 0;
}

/* ---------- walls with openings ---------- */
// the face of a wall that faces +y (lit), at y = at, from a0 to a1 along x, z0 to z1, with rectangular holes [a0, a1, z0, z1]
// boards: the spacing of wooden siding (a darker line under each board), 0 for a plain wall
function wallY(at, a0, a1, z0, z1, c, holes = [], boards = 0) {
  for (let a = a0; a <= a1; a += ST) {
    const hs = holes.filter(h => a > h[0] && a < h[1]);                        // the holes this column crosses
    for (let z = z0; z <= z1; z += ST) {
      let hole = false;
      for (let k = 0; k < hs.length; k++) if (z > hs[k][2] && z < hs[k][3]) { hole = true; break; }
      if (!hole) plot(a, at, z, shade(c, boards && z % boards < boards * .17 ? 1.5 : 2.4, a, z));
    }
  }
}
// a solid block whose +y face has holes: block() with wallY for the lit face
// roofed: the top is under a roof that covers it, so it is not drawn
function blockHoles(x0, y0, z0, x1, y1, z1, c, holes, boards = 0, roofed = false) {
  if (!roofed) for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) plot(a, b, z1, shade(c, 3.4, a, b));
  wallY(y1, x0, x1, z0, z1, c, holes, boards);
  for (let b = y0; b <= y1; b += ST) for (let z = z0; z <= z1; z += ST) plot(x1, b, z, shade(c, boards && z % boards < boards * .17 ? .5 : 1.3, b, z));
}
// the reveal of a hole in a +y wall: the faces of the wall's thickness you see through it from above, `deep` into the wall
// (the left side, which faces +x, and the sill; the lintel's underside cannot be seen from above)
function reveal(at, a0, a1, z0, z1, deep, c) {
  for (let t = 0; t <= deep; t += ST * .5) {
    for (let z = z0; z <= z1; z += ST * .5) plot(a0, at - t, z, rampOf(c)[1]);
    for (let a = a0; a <= a1; a += ST * .5) plot(a, at - t, z0, rampOf(c)[3]);
  }
}
// a flat plane parallel to a +y wall (y = at), painted by fn(a, z) -> colour or 0; glow: the pixels give light
function paneY(at, a0, a1, z0, z1, fn, glow = false) {
  for (let a = a0; a <= a1; a += ST * .5) for (let z = z0; z <= z1; z += ST * .5) {
    const col = fn(a, z);
    if (!col) continue;
    if (glow) plotGlow(a, at, z, col); else plot(a, at, z, col);
  }
}
// a flat leaf (a door, a shutter) hinged on a vertical line at (hx, hy), `len` long, turned by `ang` from the +x direction
// (ang 0: lies along +x; Math.PI: along -x; -Math.PI / 2: into the wall, along -y). fn(t, z): t from the hinge (0) to the free edge (1)
function leaf(hx, hy, len, z0, z1, ang, fn) {
  const dx = Math.cos(ang), dy = Math.sin(ang);
  for (let t = 0; t <= 1; t += ST * .4 / len) for (let z = z0; z <= z1; z += ST * .5) plot(hx + dx * len * t, hy + dy * len * t, z, fn(t, z));
}

/* ---------- a low slab you can stand on (a porch, a step) ---------- */
// block() whose top later takes the characters' shadows like the ground: joinSlabs(), called after bakeOcclusion,
// puts its top pixels into ground and groundZ (so the walls' occlusion does not darken it). kinds: ROAD, so no grass grows on it
const slabTops = [];
function slab(x0, y0, x1, y1, h, c) {
  const before = zb.slice();
  for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) plot(a, b, h, shade(c, 3.4, a, b));
  for (let i = 0; i < W * H; i++) if (zb[i] !== before[i]) slabTops.push(i, zb[i]);
  for (let a = x0; a <= x1; a += ST) for (let z = 0; z <= h; z += ST) plot(a, y1, z, shade(c, 2.4, a, z));
  for (let b = y0; b <= y1; b += ST) for (let z = 0; z <= h; z += ST) plot(x1, b, z, shade(c, 1.3, b, z));
}
function joinSlabs() {
  for (let n = 0; n < slabTops.length; n += 2) { const i = slabTops[n]; if (zb[i] !== slabTops[n + 1]) continue; ground[i] = 1; groundZ[i] = zb[i]; kinds[i] = KIND_ROAD; }
  slabTops.length = 0;
}

/* ---------- a hip roof: four slopes, the ridge along x, rows of tiles ---------- */
// eaves at height z over [x0, x1] x [y0, y1]; rise: the ridge above the eaves. c: tiles; edge: the fascia
function hipRoof(x0, y0, x1, y1, z, rise, c, edge) {
  const xc = (x0 + x1) / 2, yc = (y0 + y1) / 2, hy = (y1 - y0) / 2, hx = (x1 - x0) / 2;
  const R = rampOf(c), ROW = .19, TILE = .3;
  for (let x = x0; x <= x1; x += ST * .7) for (let y = y0; y <= y1; y += ST * .7) {
    const fy = (hy - Math.abs(y - yc)) / hy, fx = (hx - Math.abs(x - xc)) / hy, f = Math.min(fy, fx, 1);
    { const p = project(x, y, z + rise * f), ix = p.sx | 0, iy = p.sy | 0; if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue; }   // off the picture: plot() would drop it (order 30a: skipped before the work, the same pixels)
    const front = fy <= fx, along = (front ? fy : fx) * hy;                     // how far up the slope from the eave
    const r = Math.floor(along / ROW), t = (along % ROW) / ROW;
    const run = front ? x : y, s = ((run / TILE + (r % 2) * .5) % 1 + 1) % 1;   // along the eave, the tiles staggered row by row
    const tile = Math.floor(run / TILE + (r % 2) * .5);
    let lit = front ? (y > yc ? 3 : 2) : (x > xc ? 1 : 2);
    if (t < .22) lit -= 1;                                                    // the shadow under each row
    else if (s < .1) lit -= 1;                                                // the gap between two tiles
    else if (t > .8) lit += front ? 1 : 0;                                    // the lit lip of a tile
    const h = hash(tile * 3 + r, r * 7 + (front ? 0 : 50));
    if (h > .9) lit += 1; else if (h < .07) lit -= 1;
    if (Math.abs(fy - fx) * hy < .045 || f > .985) lit = front ? 4 : 3;       // the hips and the ridge: capped, light
    plot(x, y, z + rise * f, R[clamp(lit, 0, 4)]);
  }
  // the fascia: a thin board round the eaves, in front of the tiles' edge
  const E = rampOf(edge);
  for (let x = x0; x <= x1; x += ST * .5) for (let h = -.12; h <= 0; h += ST * .5) plot(x, y1 + .01, z + h, E[2]);
  for (let y = y0; y <= y1; y += ST * .5) for (let h = -.12; h <= 0; h += ST * .5) plot(x1 + .01, y, z + h, E[1]);
}

/* ---------- swaying leaves the set owns: drawn each frame by drawLeaves, like growTree's ---------- */
// the pixel the engine's plot would write, kept in a list instead: [ix, iy, depth, colour]
function keepPlot(list, x, y, z, color) {
  const p = project(x, y, z), ix = p.sx | 0, iy = p.sy | 0;
  if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
  list.push(ix, iy, Math.fround(p.d), color);
}
// a palm whose fronds sway in the wind (pp-engine's drawLeaves). Trunk and coconuts are baked.
// Each frond is one leaf of `leaves`; L: the light of the hour (lightPass's m and a), so the fronds match the set
function swayPalm(x, y, h, lean, seed, size = 1, L = null) {
  const top = [x + lean * .7, y - lean * .5, h], palmC = lit(C.palm, L);
  capsule([x, y, 0], [x + lean * .25, y - lean * .15, h * .5], .2 * size, .16 * size, () => palmC, 'rough');
  capsule([x + lean * .25, y - lean * .15, h * .5], top, .16 * size, .13 * size, () => palmC, 'rough');
  const R = rampOf(lit(C.leaf, L)), n = 9;
  for (let f = 0; f < n; f++) {
    const a = f / n * 6.283 + seed, dx = Math.cos(a), dy = Math.sin(a), len = (1.5 + hash(f, seed) * .45) * size;
    const pixels = [];
    for (let t = 0; t <= 1; t += .012 / size) {
      const px = top[0] + dx * len * t, py = top[1] + dy * len * t, pz = top[2] + .3 * t * size - 1.3 * t * t * size, w = (.3 * Math.sin(t * Math.PI) + .03) * size;
      for (let s = -1; s <= 1; s += .12) {
        const leaflet = Math.abs(s) > .2 && ((t * 40 | 0) % 2) === 0;
        if (leaflet && Math.abs(s) > .7) continue;
        keepPlot(pixels, px - dy * w * s, py + dx * w * s, pz - Math.abs(s) * w * .5, R[clamp(Math.round(2.2 + (dx + dy) * .6 - Math.abs(s) * .8 + (s > 0 ? .4 : -.2)), 0, 4)]);
      }
    }
    // odd k: drawLeaves casts no shadow for it each frame; the frond's shadow is baked here, along its length
    leaves.push({ x: top[0] + dx * len * .45, y: top[1] + dy * len * .45, z: top[2] - .2 * size, k: f * 2 + 1, r: .3 * size, pixels });
    for (let t = .1; t <= 1; t += .1) castShadow(top[0] + dx * len * t, top[1] + dy * len * t, top[2] + .3 * t * size - 1.3 * t * t * size, (.06 + .2 * Math.sin(t * Math.PI)) * size, 1, .2);
  }
  sphere(top[0], top[1], top[2] - .15 * size, .22 * size, lit([120, 92, 48], L), 'rough');
  for (let k = 0; k < 3; k++) sphere(top[0] + Math.cos(k * 2.1 + seed) * .18 * size, top[1] + Math.sin(k * 2.1 + seed) * .18 * size, top[2] - .3 * size, .11 * size, lit([96, 120, 52], L), 'rough');
  for (let z = .2; z < h; z += .15) castShadow(x + lean * z / h * .5, y - lean * z / h * .3, z, .15 * size, 1, .1);
  return top;
}

/* ---------- a birdhouse on a post ---------- */
function birdhouse(x, y, L = null) {
  const wood = lit(C.wood, L), box = lit([244, 206, 96], L), roof = lit(C.red, L);
  block(x - .07, y - .07, 0, x + .07, y + .07, 1.25, wood);
  block(x - .28, y - .24, 1.25, x + .28, y + .24, 1.78, box);
  // the round hole on the front (+y) face, and a perch under it
  for (let a = -.12; a <= .12; a += ST * .4) for (let z = -.12; z <= .12; z += ST * .4) if (a * a + z * z < .0144) plot(x + a, y + .25, 1.55 + z, rgb(32, 20, 10));
  block(x - .03, y + .24, 1.36, x + .03, y + .38, 1.4, wood);
  // a pitched roof, its ridge along x
  for (let a = -.4; a <= .4; a += ST * .5) for (let b = -.38; b <= .38; b += ST * .5) {
    const q = Math.abs(b) / .38;
    plot(x + a, y + b, 1.78 + .3 * (1 - q), rampOf(roof)[clamp((b > 0 ? 3 : 2) + (Math.floor(q * 4) % 2 ? 0 : -1), 0, 4)]);
  }
  for (let b = -.36; b <= .36; b += ST * .5) for (let h = 0; h <= .3 * (1 - Math.abs(b) / .38); h += ST * .5) plot(x + .28, y + b, 1.78 + h, rampOf(box)[1]);
  shadowBox(x - .28, y - .24, x + .28, y + .24, 2, .3);
  for (let z = .2; z < 1.25; z += .3) castShadow(x, y, z, .1);
}

/* ---------- a touch box for something round (a palm's crown, a post) ---------- */
// the world box (x0, y0, z0, x1, y1, z1), square on the ground, whose 8 projected corners have the screen bounding box
// [sx0, sy0] - [sx1, sy1]: for a thing whose 3D extent would give far too big a box (a palm's fronds)
function boxAround(sx0, sy0, sx1, sy1) {
  const d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - OX) / S;           // a box with x and y extents e projects 2e/R2 wide in u and in v
  const vmax = (sy1 - OY) / (S * SIN), vmin = vmax - d, z1 = (vmin * SIN - (sy0 - OY) / S) / COS;
  const xc = (uc + (vmin + vmax) / 2) / R2, yc = ((vmin + vmax) / 2 - uc) / R2, e = d * R2 / 4;
  return [xc - e, yc - e, 0, xc + e, yc + e, z1];
}

/* ---------- furniture turned to any angle (order 30a, El balcón) ---------- */
// the shade of a vertical face by the way it faces: like block()'s walls, +y faces lit (2.4), +x faces in shade (1.3), in between by angle
// (nx, ny): the face's outward normal on the ground
function faceBase(nx, ny) { return clamp(1.3 + 1.1 * Math.atan2(ny, nx) / (Math.PI / 2), 1, 2.9); }
// a box turned by ang: its width axis along (cos ang, sin ang), half-width hw; its depth axis along (-sin ang, cos ang), half-depth hd.
// ang = -Math.PI / 4 turns its front (+depth) to the camera. fn(s, t, z, face) may give a colour (s across, t in depth; face 'top' or the
// side: 'front', 'back', 'left', 'right'); otherwise the face is shaded from c. Only faces turned towards the camera are drawn
function turnedBox(cx, cy, z0, z1, hw, hd, ang, c, fn = null) {
  const ax = Math.cos(ang), ay = Math.sin(ang), bx = -ay, by = ax;
  const P = (s, t) => [cx + ax * s + bx * t, cy + ay * s + by * t];
  const put = (s, t, z, face, base, g1, g2) => { const p = P(s, t), col = fn && fn(s, t, z, face); plot(p[0], p[1], z, col || shade(c, base, g1, g2)); };
  for (let s = -hw; s <= hw + 1e-9; s += ST * .7) for (let t = -hd; t <= hd + 1e-9; t += ST * .7) put(s, t, z1, 'top', 3.4, cx + s, cy + t);
  const sides = [['front', bx, by, s => [s, hd], hw], ['back', -bx, -by, s => [s, -hd], hw], ['right', ax, ay, t => [hw, t], hd], ['left', -ax, -ay, t => [-hw, t], hd]];
  for (const [face, nx, ny, at, half] of sides) {
    if (nx + ny < -1e-6) continue;                                            // turned away from the camera
    const base = faceBase(nx, ny);
    for (let k = -half; k <= half + 1e-9; k += ST * .7) for (let z = z0; z <= z1 + 1e-9; z += ST * .7) { const [s, t] = at(k); put(s, t, z, face, base, k + cx, z); }
  }
}
// an upright cylinder (a table's top, its foot, a flower pot): the top disc and the side that faces the camera. top(dx, dy) may colour the disc
function drum(cx, cy, z0, z1, r, c, top = null) {
  for (let a = -r; a <= r; a += ST * .7) for (let b = -r; b <= r; b += ST * .7) {
    if (a * a + b * b > r * r) continue;
    const col = top && top(a, b);
    plot(cx + a, cy + b, z1, col || shade(c, 3.4, cx + a, cy + b));
  }
  const n = Math.max(12, Math.ceil(2 * Math.PI * r / (ST * .6)));
  for (let k = 0; k < n; k++) {
    const f = k / n * 2 * Math.PI, nx = Math.cos(f), ny = Math.sin(f);
    if (nx + ny < -.3) continue;
    const base = faceBase(nx, ny);
    for (let z = z0; z <= z1 + 1e-9; z += ST * .7) plot(cx + nx * r, cy + ny * r, z, shade(c, base, f * 3, z));
  }
}

/* ---------- for the checks: which object drew each pixel ---------- */
// part(name, fn) runs fn; when PART_TAGS is an array it also records, per pixel, the last part that drew it
let PART_TAGS = null;
const PART_LEAVES = {};
function part(name, fn) {
  if (!PART_TAGS) return fn();
  const before = zb.slice(), l0 = leaves.length, r = fn();
  for (let i = 0; i < W * H; i++) if (zb[i] !== before[i]) PART_TAGS[i] = name;
  if (leaves.length > l0) PART_LEAVES[name] = [l0, leaves.length];
  return r;
}
// after a frame: tag the pixels the swaying leaves of each part drew (where they are at that frame)
function tagLeaves(frameZ) {
  for (const [name, [a, b]] of Object.entries(PART_LEAVES)) for (let j = a; j < b; j++) {
    const px = leaves[j].pixels;
    for (let n = 0; n < px.length; n += 4) for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
      const ix = px[n] + dx, iy = px[n + 1] + dy;
      if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
      const i = iy * W + ix;
      if (frameZ[i] === px[n + 2]) PART_TAGS[i] = name;
    }
  }
}

/* ---------- a room seen from inside (order 31a, La sala) ---------- */
// the reveal of a hole in a +x wall: the faces of the wall's thickness seen through it from above, `deep` into the wall
// (the jamb at a0, which faces +y, and the sill)
function revealX(at, a0, a1, z0, z1, deep, c) {
  for (let t = 0; t <= deep; t += ST * .5) {
    for (let z = z0; z <= z1; z += ST * .5) plot(at - t, a0, z, rampOf(c)[2]);
    for (let a = a0; a <= a1; a += ST * .5) plot(at - t, a, z0, rampOf(c)[3]);
  }
}
// a wall face drawn pixel by pixel on the screen (order 31a): every pixel of the picture whose sight line meets the plane x = at (face 'x', facing
// +x) or y = at (face 'y', facing +y) inside [a0, a1] (along the wall) x [z0, z1] takes fn(a, z) there (0: a hole, nothing drawn), with the depth
// test of plot(). One sample a pixel, where wallX / wallY step every ST (about 13 a pixel at S = 26): the same picture of a flat face, far cheaper
function planeFace(face, at, a0, a1, z0, z1, fn) {
  const xs = [], ys = [];
  for (const a of [a0, a1]) for (const z of [z0, z1]) { const p = face === 'x' ? project(at, a, z) : project(a, at, z); xs.push(p.sx); ys.push(p.sy); }
  const ix0 = Math.max(0, Math.floor(Math.min(...xs))), ix1 = Math.min(W - 1, Math.ceil(Math.max(...xs))), iy0 = Math.max(0, Math.floor(Math.min(...ys))), iy1 = Math.min(H - 1, Math.ceil(Math.max(...ys)));
  for (let iy = iy0; iy <= iy1; iy++) for (let ix = ix0; ix <= ix1; ix++) {
    const u = (ix + .5 - OX) / S, k = (iy + .5 - OY) / S;                    // u = (x - y) / R2; k = v SIN - z COS
    const x = face === 'x' ? at : at + u * R2, y = face === 'x' ? at - u * R2 : at, a = face === 'x' ? y : x;
    if (a < a0 || a > a1) continue;
    const v = (x + y) / R2, z = (v * SIN - k) / COS;
    if (z < z0 || z > z1) continue;
    const d = v * COS + z * SIN, i = iy * W + ix;
    if (d <= zb[i]) continue;
    const col = fn(a, z);
    if (!col) continue;
    zb[i] = d; pix[i] = col;
  }
}

/* ---------- a yard seen square on (order 32a, El patio) ---------- */
// screen-aligned ground coordinates: u across the picture (to the right), v towards the camera (down the picture); world x, y from them.
// A face at v = const faces the camera square on (its normal (1, 1) / R2): a wall, a fence, a gate drawn with it shows as a flat rectangle
const UVW = (u, v, z = 0) => [(u + v) / R2, (v - u) / R2, z];
// a flat parallelogram P0 + a e1 + b e2 (a, b from 0 to 1), drawn pixel by pixel on the screen with plot()'s depth test: every pixel whose
// middle's sight line meets it takes fn(a, b) there (0: nothing drawn). One sample a pixel, as planeFace, for a face of any direction
// (a wall turned to the camera, a roof slope, a gate leaf). P0, e1, e2: world [x, y, z]. A face seen edge on draws nothing
function planeQuad(P0, e1, e2, fn) {
  const p0 = project(P0[0], P0[1], P0[2]);
  const d = e => { const q = project(P0[0] + e[0], P0[1] + e[1], P0[2] + e[2]); return [q.sx - p0.sx, q.sy - p0.sy, q.d - p0.d]; };
  const A = d(e1), B = d(e2), det = A[0] * B[1] - A[1] * B[0];
  if (Math.abs(det) < 1e-6) return;
  const xs = [0, A[0], B[0], A[0] + B[0]].map(s => s + p0.sx), ys = [0, A[1], B[1], A[1] + B[1]].map(s => s + p0.sy);
  const ix0 = Math.max(0, Math.floor(Math.min(...xs))), ix1 = Math.min(W - 1, Math.ceil(Math.max(...xs))), iy0 = Math.max(0, Math.floor(Math.min(...ys))), iy1 = Math.min(H - 1, Math.ceil(Math.max(...ys)));
  for (let iy = iy0; iy <= iy1; iy++) for (let ix = ix0; ix <= ix1; ix++) {
    const dx = ix + .5 - p0.sx, dy = iy + .5 - p0.sy, a = (dx * B[1] - dy * B[0]) / det, b = (A[0] * dy - A[1] * dx) / det;
    if (a < 0 || a > 1 || b < 0 || b > 1) continue;
    const dd = Math.fround(p0.d + a * A[2] + b * B[2]), i = iy * W + ix;
    if (dd <= zb[i]) continue;
    const col = fn(a, b);
    if (!col) continue;
    zb[i] = dd; pix[i] = col;
  }
}
