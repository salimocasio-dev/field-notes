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
// c' = c * m + a, per channel. It also darkens the grass blades that drawTufts draws each frame.
function lightPass(m, a) {
  for (let i = 0; i < W * H; i++) {
    if (zb[i] < -1e8 || glowZ[i] === zb[i]) continue;
    const c = pix[i];
    pix[i] = rgb((c & 255) * m[0] + a[0], (c >> 8 & 255) * m[1] + a[1], (c >> 16 & 255) * m[2] + a[2]);
  }
  for (let i = 0; i < W * H; i++) if (kinds[i] === KIND_GRASS) staticShadow[i] = 1;
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
  for (let a = a0; a <= a1; a += ST) for (let z = z0; z <= z1; z += ST) {
    if (holes.some(h => a > h[0] && a < h[1] && z > h[2] && z < h[3])) continue;
    plot(a, at, z, shade(c, boards && z % boards < boards * .17 ? 1.5 : 2.4, a, z));
  }
}
// a solid block whose +y face has holes: block() with wallY for the lit face
function blockHoles(x0, y0, z0, x1, y1, z1, c, holes, boards = 0) {
  for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) plot(a, b, z1, shade(c, 3.4, a, b));
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
