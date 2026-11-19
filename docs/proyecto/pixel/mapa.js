'use strict';
/* Coquí home map on the Pixel Plays engine: one floating island, ten places as small dioramas,
   roads that follow the course's forks, and the coquí hopping between stops.
   World units: u runs across the screen, v runs down it. x = (v + u) / √2, y = (v - u) / √2. */

const KIND_SAND = 1, KIND_WATER = 2, KIND_ROAD = 4;
const XY = (u, v) => ({ x: (v + u) / R2, y: (v - u) / R2 });
const UV = (x, y) => ({ u: (x - y) / R2, v: (x + y) / R2 });

/* ---------- palette ---------- */
const C = {
  sand: [[206, 186, 140], [222, 204, 160], [234, 218, 178], [244, 232, 198]],
  sea: [[28, 74, 112], [34, 98, 128], [44, 126, 140], [70, 160, 156]],
  pond: [[40, 96, 120], [52, 124, 138], [74, 152, 150], [104, 178, 164]],
  path: [[176, 150, 112], [194, 170, 130], [210, 188, 148], [224, 206, 168]],
  pave: [[186, 178, 164], [204, 196, 180], [220, 212, 196], [234, 228, 212]],
  asphalt: [[70, 70, 78], [82, 82, 90], [94, 94, 102], [104, 104, 112]],
  stone: [216, 206, 184], dark: [40, 36, 46], white: [244, 240, 228], wood: [140, 96, 60], woodD: [96, 64, 40],
  teal: [96, 196, 190], pink: [236, 150, 160], yellow: [244, 206, 96], lilac: [170, 140, 210], peach: [244, 178, 120],
  red: [206, 56, 44], orange: [240, 140, 52], green: [70, 140, 70], leaf: [74, 134, 62], palm: [164, 130, 86],
  glass: [70, 110, 150], lamp: [255, 226, 130], grey: [150, 150, 156], fort: [214, 196, 150],
};
const toneOf = (tones, t, ix, iy) => rgb(...tones[clamp(Math.floor(t * 4 + (bayerAt(ix, iy) - .5) * .8), 0, tones.length - 1)]);

/* ---------- layout ---------- */
const PADS = [[0, 40], [-5, 25], [5, 25], [0, 10], [-5, -5], [5, -5], [-5, -20], [5, -20], [0, -34], [0, -46]];
const DIO = [[0, 34.6], [-9.7, 25], [9.7, 25], [0, 4.8], [-9.7, -5], [9.7, -5], [-9.7, -20], [9.7, -20], [-6.8, -34.5], [0, -51.6]];
const ROAD = [[0, 1], [0, 2], [1, 3], [2, 3], [3, 4], [3, 5], [4, 5], [4, 6], [5, 7], [6, 7], [6, 8], [7, 8], [8, 9]];
// a road leaves the lower stop sideways, then climbs straight up to the higher one, like a board-game map
function legs(a, b) {
  const A = PADS[a], B = PADS[b];
  if (A[0] === B[0] || A[1] === B[1]) return [[A, B]];
  return [[A, [B[0], A[1]]], [[B[0], A[1]], B]];
}
const SEGS = ROAD.flatMap(([a, b]) => legs(a, b));
function segDist(u, v, [[u0, v0], [u1, v1]]) {
  const du = u1 - u0, dv = v1 - v0, l = du * du + dv * dv;
  const t = l ? clamp(((u - u0) * du + (v - v0) * dv) / l, 0, 1) : 0;
  return Math.hypot(u - u0 - du * t, v - v0 - dv * t);
}
const roadDist = (u, v) => Math.min(...SEGS.map(s => segDist(u, v, s)));
// the path the frog hops from stop a to stop b: road corners in between
function route(a, b) {
  if (a === b) return [PADS[a]];
  // breadth-first over the road graph
  const prev = { [a]: -1 }, q = [a];
  while (q.length) {
    const n = q.shift();
    if (n === b) break;
    for (const [p, r] of ROAD) {
      const m = p === n ? r : r === n ? p : -1;
      if (m >= 0 && !(m in prev)) { prev[m] = n; q.push(m); }
    }
  }
  const chain = [];
  for (let n = b; n !== -1; n = prev[n]) chain.unshift(n);
  const pts = [PADS[chain[0]]];
  for (let k = 1; k < chain.length; k++) {
    const p = chain[k - 1], n = chain[k], up = PADS[n][1] < PADS[p][1];
    const ls = up ? legs(p, n) : legs(n, p).map(([s, e]) => [e, s]).reverse();
    for (const [, e] of ls) pts.push(e);
  }
  return pts;
}

/* ---------- island shape ---------- */
function islandSd(u, v) {
  const A = 15.4, B = 52.6, vc = -5.5, r = 7;
  const qx = Math.abs(u) - (A - r), qy = Math.abs(v - vc) - (B - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r + (noise(u * .33 + 4, v * .33) - .5) * 1.8;
}
const patches = []; // ground the dioramas lay down: {hit(x,y), color(x,y,ix,iy,i)}
function inBox(x, y, x0, y0, x1, y1) { return x >= x0 && x <= x1 && y >= y0 && y <= y1; }

const waterPix = [];
function groundColor(x, y, ix, iy, i) {
  const { u, v } = XY2UV(x, y);
  const sd = islandSd(u, v);
  if (sd > 0) return 0;
  if (sd > -.5 && hash(ix, iy) < (sd + .5) / .5 * .8) return 0;
  if (sd > -2.7) {
    kinds[i] = KIND_WATER;
    waterPix.push(i, u, v, sd);
    return toneOf(C.sea, .15 + clamp((-sd) / 2.7, 0, 1) * .75 + (noise(u * .5, v * .3) - .5) * .3, ix, iy);
  }
  const beach = -3.9 - noise(u * .6, v * .6) * 1.1;
  for (const p of patches) if (p.hit(x, y)) { const c = p.color(x, y, ix, iy, i); if (c) return c; }
  for (let k = 0; k < PADS.length; k++) {
    const d = Math.hypot(u - PADS[k][0], v - PADS[k][1]);
    if (d < 1.55) { kinds[i] = KIND_ROAD; return d > 1.25 ? rgb(...C.stone.map(c => c * .62)) : toneOf(C.pave, .55 + noise(u * 3, v * 3) * .45, ix, iy); }
  }
  if (sd > beach) { kinds[i] = KIND_SAND; return toneOf(C.sand, .2 + noise(u * 2, v * 2) * .8, ix, iy); }
  const rd = roadDist(u, v);
  if (rd < .72) {
    kinds[i] = KIND_ROAD;
    const edge = rd > .56;
    return edge ? toneOf(C.path, .05, ix, iy) : toneOf(C.path, .35 + noise(u * 2.5, v * 2.5) * .6 + (hash(ix, iy) - .5) * .3, ix, iy);
  }
  kinds[i] = KIND_GRASS;
  const t = noise(u * .5, v * .5) * 1.15 + (hash(ix, iy) - .5) * .5 - .05;
  return rgb(...GRASS[clamp(Math.floor(t * 4.2), 0, 3)]);
}
const XY2UV = (x, y) => UV(x, y);

/* ---------- building helpers (all in world x, y, z) ---------- */
const ST = .36 / S;
function shade(c, base, a = 0, b = 0, grain = .35) {
  return rampOf(c)[clamp(Math.floor(base + (noise(a * 3, b * 3) - .5) * grain + (hash(a * 40 | 0, b * 40 | 0) - .5) * .25), 0, 4)];
}
// a solid block with its two visible walls and top. Walls facing +y are lit, walls facing +x are in shade
function block(x0, y0, z0, x1, y1, z1, c, top = c) {
  for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) plot(a, b, z1, shade(top, 3.4, a, b));
  for (let a = x0; a <= x1; a += ST) for (let z = z0; z <= z1; z += ST) plot(a, y1, z, shade(c, 2.4, a, z));
  for (let b = y0; b <= y1; b += ST) for (let z = z0; z <= z1; z += ST) plot(x1, b, z, shade(c, 1.3, b, z));
}
// a rectangle painted on a wall: face 'y' sits on y = at, face 'x' on x = at
function onWall(face, at, a0, a1, z0, z1, color) {
  for (let a = a0; a <= a1; a += ST * .8) for (let z = z0; z <= z1; z += ST * .8) {
    if (face === 'y') plot(a, at + .02, z, color); else plot(at + .02, a, z, color);
  }
}
function windowOn(face, at, ca, cz, w, h, frame = C.white, glass = C.glass, lit = false) {
  onWall(face, at, ca - w / 2 - .08, ca + w / 2 + .08, cz - h / 2 - .08, cz + h / 2 + .08, rampOf(frame)[face === 'y' ? 3 : 2]);
  const g = lit ? rgb(...C.lamp) : rampOf(glass)[face === 'y' ? 1 : 0];
  for (let a = ca - w / 2; a <= ca + w / 2; a += ST * .8) for (let z = cz - h / 2; z <= cz + h / 2; z += ST * .8) {
    const bar = Math.abs(a - ca) < .05 || Math.abs(z - cz) < .05;
    const col = bar ? rampOf(frame)[face === 'y' ? 3 : 2] : g;
    if (face === 'y') plot(a, at + .03, z, col); else plot(at + .03, a, z, col);
  }
}
// a gable roof whose ridge runs along x
function gable(x0, y0, x1, y1, z, rise, c, wall) {
  const yc = (y0 + y1) / 2, half = (y1 - y0) / 2;
  for (let x = x0; x <= x1; x += ST * .9) for (let y = y0; y <= y1; y += ST * .9) {
    const q = Math.abs(y - yc) / half, row = Math.floor(q * half * 4) % 2;
    plot(x, y, z + rise * (1 - q), rampOf(c)[clamp((y > yc ? 3 : 1) + row - (hash(x * 4 | 0, y * 9 | 0) > .86 ? 1 : 0), 0, 4)]);
  }
  for (let y = y0 + .15; y <= y1 - .15; y += ST) {
    const q = Math.abs(y - yc) / half;
    for (let h = 0; h <= rise * (1 - q); h += ST) plot(x1 - .15, y, z + h, shade(wall, 1.3, y, h));
  }
}
// a flat roof with a low parapet, the Caribbean concrete house
function flatRoof(x0, y0, x1, y1, z, c) {
  block(x0 - .08, y0 - .08, z, x1 + .08, y1 + .08, z + .14, c, c.map(v => v * .9));
  block(x0 - .08, y0 - .08, z + .14, x1 + .08, y0 + .1, z + .34, c);
  block(x0 - .08, y0 - .08, z + .14, x0 + .1, y1 + .08, z + .34, c);
  block(x0 - .08, y1 - .1, z + .14, x1 + .08, y1 + .08, z + .34, c);
  block(x1 - .1, y0 - .08, z + .14, x1 + .08, y1 + .08, z + .34, c);
}
function shadowBox(x0, y0, x1, y1, z1, r = .5) {
  for (let x = x0; x <= x1; x += .4) for (let y = y0; y <= y1; y += .4) for (let z = .2; z <= z1; z += .5) castShadow(x, y, z, r);
}
function bush(x, y, r, c = C.leaf) {
  sphere(x, y, r * .7, r, c, 'rough');
  sphere(x + r * .5, y - r * .3, r * .55, r * .7, c, 'rough');
  castShadow(x, y, r, r * .9);
}
function palm(x, y, h = 3.4, lean = .5, seed = 0) {
  const top = [x + lean * .7, y - lean * .5, h];
  capsule([x, y, 0], [x + lean * .25, y - lean * .15, h * .5], .16, .13, () => C.palm, 'rough');
  capsule([x + lean * .25, y - lean * .15, h * .5], top, .13, .11, () => C.palm, 'rough');
  for (let f = 0; f < 8; f++) {
    const a = f / 8 * 6.283 + seed, dx = Math.cos(a), dy = Math.sin(a), len = 1.25 + hash(f, seed) * .4;
    for (let t = 0; t <= 1; t += .035) {
      const px = top[0] + dx * len * t, py = top[1] + dy * len * t, pz = top[2] + .25 * t - 1.05 * t * t;
      const w = .2 * Math.sin(t * Math.PI) + .04;
      for (const s of [-1, 0, 1]) {
        const qx = px - dy * w * s * .9, qy = py + dx * w * s * .9;
        plot(qx, qy, pz - Math.abs(s) * .05, rampOf(C.leaf)[clamp(Math.round(2 + (dx + dy) * .7 + (s === 0 ? .6 : -.2) - t * .6), 0, 4)]);
      }
    }
    for (let t = 0; t <= 1; t += .2) castShadow(top[0] + dx * len * t, top[1] + dy * len * t, top[2] - .5 * t, .22);
  }
  sphere(top[0], top[1], top[2] - .12, .18, [120, 92, 48], 'rough');
  for (let z = .4; z < h; z += .5) castShadow(x + lean * z / h * .6, y - lean * z / h * .4, z, .14);
}
const bakeAdd = (a, b, r0, r1, f) => { capsule(a, b, r0, r1, f, 'solid'); pendingShadows.push(a, r0, b, r1); };
function person(x, y, yaw, palette, pose = {}) { figure(x, y, yaw, Object.assign({ scale: .62 }, pose), palette, bakeAdd); }
const FACE = Math.PI / 4; // facing the viewer

/* ---------- the ten places ---------- */
const PLACES = {
  // 1 · Grandma's house: a teal concrete casita, red roof, a palm, abuela at the door
  casa(cx, cy) {
    block(cx - 1.6, cy - 1.4, 0, cx + 1.6, cy + 1.4, 2, C.teal);
    windowOn('y', cy + 1.4, cx - .8, 1.15, .6, .7);
    windowOn('x', cx + 1.6, cy - .5, 1.15, .6, .7);
    onWall('y', cy + 1.4, cx + .35, cx + 1.05, 0, 1.45, rampOf(C.wood)[2]);
    onWall('y', cy + 1.4, cx + .9, cx + .95, .65, .75, rgb(240, 210, 100));
    gable(cx - 1.85, cy - 1.7, cx + 1.85, cy + 1.7, 2, 1.1, C.red, C.teal);
    block(cx + .25, cy + 1.4, 0, cx + 1.15, cy + 2.1, .14, C.stone);
    shadowBox(cx - 1.6, cy - 1.4, cx + 1.6, cy + 1.4, 2.8, .6);
    palm(cx - 2.6, cy + 1.2, 3.2, .7, 1);
    bush(cx + 2.2, cy - .6, .45, [96, 150, 70]);
    for (let k = 0; k < 6; k++) sphere(cx - 1.4 + k * .28, cy + 1.75, .12, .13, [k % 2 ? 236 : 250, k % 2 ? 90 : 200, k % 2 ? 120 : 80], 'solid');
    person(cx + .7, cy + 2.4, FACE, { shirt: [128, 78, 160], stripe: [150, 98, 178], legs: [128, 78, 160], hair: [232, 230, 224], skin: [176, 122, 88] });
  },
  // 2 · the park: a pond with a duck, two trees, a bench
  parque(cx, cy) {
    const px = cx + .5, py = cy + .9;
    patches.push({ hit: (x, y) => Math.hypot((x - px) / 1.9, (y - py) / 1.5) < 1, color: (x, y, ix, iy, i) => {
      const d = Math.hypot((x - px) / 1.9, (y - py) / 1.5);
      if (d > .86) return toneOf(C.sand, .4, ix, iy);
      kinds[i] = KIND_WATER; waterPix.push(i, ...Object.values(XY2UV(x, y)), -1);
      return toneOf(C.pond, .2 + d * .7, ix, iy);
    } });
    growTree(cx - 1.3, cy - 1.5, .62, 260, 200);
    growTree(cx + 1.6, cy - 1.9, .52, 220, 700);
    bush(cx + 2.3, cy + .2, .4, [96, 150, 70]);
    block(cx - 1.9, cy + 1.2, .3, cx - 1.6, cy + 2.4, .38, C.wood);
    block(cx - 2.05, cy + 1.2, .38, cx - 1.95, cy + 2.4, .75, C.wood);
    for (const y of [1.3, 2.3]) block(cx - 1.9, cy + y, 0, cx - 1.8, cy + y + .08, .3, C.woodD);
    sphere(px + .3, py + .1, .12, .2, [244, 242, 232], 'solid');
    sphere(px + .42, py + .2, .32, .11, [244, 242, 232], 'solid');
    sphere(px + .5, py + .26, .3, .05, [240, 160, 40], 'solid');
  },
  // 3 · the kitchen: a cut-away room, tiled floor, stove with a pot, table, fridge
  cocina(cx, cy) {
    const x0 = cx - 1.8, y0 = cy - 1.8, x1 = cx + 1.8, y1 = cy + 1.8;
    for (let a = x0; a <= x1; a += ST) for (let b = y0; b <= y1; b += ST) {
      plot(a, b, .12, rampOf((Math.floor(a - x0) * 2 + Math.floor((b - y0) * 2)) % 2 ? [236, 230, 214] : [196, 120, 90])[3]);
    }
    for (let a = x0; a <= x1; a += ST) for (let z = 0; z <= .12; z += ST) plot(a, y1, z, rampOf(C.stone)[2]);
    for (let b = y0; b <= y1; b += ST) for (let z = 0; z <= .12; z += ST) plot(x1, b, z, rampOf(C.stone)[1]);
    block(x0, y0, 0, x0 + .2, y1, 2.3, C.yellow);
    block(x0, y0, 0, x1, y0 + .2, 2.3, C.yellow);
    windowOn('y', y0 + .2, cx + .4, 1.4, .9, .7, C.white, [140, 190, 220]);
    block(x0 + .25, y0 + .25, .12, x0 + .95, y0 + 1.1, 2, C.white);
    onWall('y', y0 + 1.1, x0 + .32, x0 + .88, 1.2, 1.24, rampOf(C.grey)[1]);
    block(x0 + 1.2, y0 + .25, .12, x0 + 2.1, y0 + .95, 1, C.white);
    for (const [dx, dy] of [[.22, .22], [.62, .22], [.22, .55], [.62, .55]]) for (let t = 0; t < 6.3; t += .3) plot(x0 + 1.2 + dx + Math.cos(t) * .12, y0 + .25 + dy + Math.sin(t) * .1, 1.02, rgb(30, 28, 32));
    sphere(x0 + 1.62, y0 + .5, 1.2, .2, [200, 70, 50], 'solid');
    block(x0 + 1.5, y0 + .44, 1.36, x0 + 1.74, y0 + .56, 1.4, [60, 50, 50]);
    block(cx + .1, cy + .2, .9, cx + 1.3, cy + 1.2, 1, [190, 130, 80]);
    for (const [dx, dy] of [[0, 0], [1.1, 0], [0, .9], [1.1, .9]]) block(cx + .1 + dx, cy + .2 + dy, .12, cx + .2 + dx, cy + .3 + dy, .9, C.woodD);
    sphere(cx + .5, cy + .6, 1.06, .16, [244, 240, 228], 'solid');
    sphere(cx + .5, cy + .6, 1.1, .1, [240, 200, 90], 'solid');
    shadowBox(x0, y0, x0 + .2, y1, 2.3); shadowBox(x0, y0, x1, y0 + .2, 2.3);
  },
  // 4 · the corner shop: a yellow colmado, striped awning, fruit crates
  colmado(cx, cy) {
    block(cx - 1.8, cy - 1.3, 0, cx + 1.8, cy + 1.3, 2.1, C.yellow);
    flatRoof(cx - 1.8, cy - 1.3, cx + 1.8, cy + 1.3, 2.1, C.white);
    onWall('y', cy + 1.3, cx - .5, cx + .5, 0, 1.4, rampOf(C.dark)[1]);
    windowOn('y', cy + 1.3, cx - 1.2, .95, .7, .8, C.white, C.glass);
    windowOn('y', cy + 1.3, cx + 1.2, .95, .7, .8, C.white, C.glass);
    onWall('y', cy + 1.3, cx - 1.5, cx + 1.5, 1.75, 2, rampOf(C.red)[3]);
    for (let a = cx - 1.85; a <= cx + 1.85; a += ST) for (let t = 0; t <= .7; t += ST) {
      plot(a, cy + 1.3 + t, 1.6 - t * .55, rampOf(Math.floor((a - cx) * 2.5 + 20) % 2 ? C.red : C.white)[t > .62 ? 2 : 3]);
    }
    for (let a = cx - 1.85; a <= cx + 1.85; a += ST) castShadow(a, cy + 1.6, 1.3, .3);
    const crate = (x, y, fruit) => {
      block(x, y, 0, x + .55, y + .45, .35, C.wood);
      for (let k = 0; k < 4; k++) sphere(x + .14 + (k % 2) * .26, y + .12 + (k >> 1) * .2, .42, .11, fruit, 'solid');
    };
    crate(cx - 1.7, cy + 1.7, [240, 150, 40]); crate(cx - 1.05, cy + 1.75, [120, 180, 60]); crate(cx + 1.0, cy + 1.7, [220, 60, 50]);
    shadowBox(cx - 1.8, cy - 1.3, cx + 1.8, cy + 1.3, 2.4, .6);
    person(cx + .1, cy + 1.75, FACE, { shirt: [236, 236, 228], stripe: [236, 236, 228], legs: [60, 66, 90], hair: [40, 30, 26], skin: [200, 146, 104] });
  },
  // 5 · the street: asphalt, a crossing, a lamp, a bus stop and a parked car
  calle(cx, cy) {
    patches.push({ hit: (x, y) => inBox(x, y, cx - 2.9, cy - .5, cx + 2.9, cy + 1.2), color: (x, y, ix, iy, i) => {
      kinds[i] = KIND_ROAD;
      if (Math.abs(y - cy - .35) < .05 && Math.floor((x - cx) * 2) % 2 === 0) return rgb(240, 214, 90);
      if (x > cx - .9 && x < cx + .1 && Math.floor((y - cy) * 4.5) % 2 === 0) return rgb(236, 236, 230);
      return toneOf(C.asphalt, .3 + noise(x * 3, y * 3) * .6, ix, iy);
    } });
    patches.push({ hit: (x, y) => inBox(x, y, cx - 2.9, cy - 1.6, cx + 2.9, cy - .5), color: (x, y, ix, iy) => toneOf(C.pave, .5 + (Math.floor((x - cx) * 2) % 2) * .2, ix, iy) });
    const lx = cx + 1.9, ly = cy - 1;
    capsule([lx, ly, 0], [lx, ly, 2.6], .07, .06, () => C.dark, 'solid');
    capsule([lx, ly, 2.6], [lx, ly + .5, 2.75], .06, .05, () => C.dark, 'solid');
    sphere(lx, ly + .55, 2.62, .14, C.lamp, 'gloss');
    for (let z = .3; z < 2.6; z += .4) castShadow(lx, ly, z, .1);
    block(cx - 2.2, cy - 1.5, 0, cx - .6, cy - 1.35, 1.6, [120, 170, 210]);
    block(cx - 2.3, cy - 1.6, 1.6, cx - .5, cy - .7, 1.72, C.red);
    for (const x of [cx - 2.2, cx - .65]) block(x, cy - .85, 0, x + .08, cy - .77, 1.6, C.grey);
    block(cx - 2.0, cy - 1.3, .4, cx - .8, cy - 1.0, .5, C.wood);
    shadowBox(cx - 2.3, cy - 1.6, cx - .5, cy - .7, 1.7);
    // the car: body, cabin, wheels
    const kx = cx + .6, ky = cy - .3;
    block(kx - 1, ky, .22, kx + 1, ky + .9, .62, [70, 140, 210]);
    block(kx - .5, ky + .08, .62, kx + .5, ky + .82, 1, [220, 236, 244], [70, 140, 210]);
    for (const dx of [-.6, .6]) for (const dy of [0, .9]) sphere(kx + dx, ky + dy, .2, .2, [30, 30, 34], 'solid');
    shadowBox(kx - 1, ky, kx + 1, ky + .9, 1);
  },
  // 6 · the town square: paving, a clock tower, benches, a flamboyán
  plaza(cx, cy) {
    patches.push({ hit: (x, y) => inBox(x, y, cx - 2.8, cy - 2.6, cx + 2.6, cy + 2.6), color: (x, y, ix, iy, i) => {
      kinds[i] = KIND_ROAD;
      const ring = Math.max(Math.abs(x - cx), Math.abs(y - cy));
      return toneOf(C.pave, (Math.floor(ring * 2) % 2 ? .75 : .4) + (hash(ix >> 1, iy) - .5) * .2, ix, iy);
    } });
    block(cx - .5, cy - .5, 0, cx + .5, cy + .5, 3.4, C.white);
    gable(cx - .65, cy - .65, cx + .65, cy + .65, 3.4, .7, C.red, C.white);
    for (let t = 0; t < 6.3; t += .05) for (let r = 0; r < .34; r += .04) plot(cx + Math.cos(t) * r * .2 - .02, cy + .5 + .02, 2.8 + Math.sin(t) * r, r > .28 ? rgb(40, 36, 46) : rgb(250, 248, 240));
    onWall('y', cy + .5, cx - .02, cx + .02, 2.8, 3.06, rgb(30, 28, 32));
    onWall('y', cy + .5, cx, cx + .18, 2.78, 2.82, rgb(30, 28, 32));
    onWall('y', cy + .5, cx - .2, cx + .2, 0, .9, rampOf(C.dark)[1]);
    shadowBox(cx - .5, cy - .5, cx + .5, cy + .5, 3.6);
    growTree(cx - 1.8, cy - 1.6, .38, 130, 1300);
    for (const [bx, by] of [[cx + 1.2, cy + 1.6], [cx - 1.9, cy + 1.2]]) {
      block(bx, by, .3, bx + 1, by + .3, .38, C.wood);
      block(bx, by, .38, bx + 1, by + .08, .7, C.wood);
      shadowBox(bx, by, bx + 1, by + .3, .5, .3);
    }
    person(cx + 1.6, cy + 1.2, FACE + .4, { shirt: [86, 150, 210], stripe: [86, 150, 210], legs: [200, 180, 140], hair: [176, 170, 160], skin: [214, 160, 122] });
  },
  // 7 · the beach: sand to the water's edge, an umbrella, a towel, a palm
  playa(cx, cy) {
    const c0 = UV(cx, cy);
    patches.push({ hit: (x, y) => { const { u, v } = UV(x, y); return Math.hypot((u - c0.u + 1.2) / 3.6, (v - c0.v) / 3.9) + (noise(u * .9, v * .9) - .5) * .35 < 1; }, color: (x, y, ix, iy, i) => { kinds[i] = KIND_SAND; return toneOf(C.sand, .3 + noise(x * 2, y * 2) * .7, ix, iy); } });
    const ux = cx + .4, uy = cy + .3;
    capsule([ux, uy, 0], [ux, uy, 1.8], .05, .05, () => C.white, 'solid');
    for (let a = 0; a < 6.283; a += .03) for (let r = 0; r <= 1.2; r += .04) {
      plot(ux + Math.cos(a) * r, uy + Math.sin(a) * r, 1.9 - r * .45, rampOf(Math.floor(a / 6.283 * 8) % 2 ? C.red : C.white)[clamp(Math.round(2.6 + (Math.sin(a) - Math.cos(a)) * .5), 1, 4)]);
    }
    for (let a = 0; a < 6.283; a += .4) for (let r = .2; r <= 1.2; r += .4) castShadow(ux + Math.cos(a) * r, uy + Math.sin(a) * r, 1.6, .35);
    for (let a = cx - .6; a <= cx + .2; a += ST) for (let b = cy + 1.1; b <= cy + 2.3; b += ST) plot(a, b, .03, rampOf(Math.floor((b - cy) * 4) % 2 ? [80, 170, 210] : C.yellow)[3]);
    palm(cx - 1.8, cy - 1.4, 3.3, .9, 3);
    sphere(cx + 1.5, cy + 1.4, .22, .22, [240, 90, 70], 'solid');
  },
  // 8 · the diner: an orange fonda with a sign and tables outside
  fonda(cx, cy) {
    block(cx - 1.6, cy - 1.6, 0, cx + 1.6, cy + .9, 2, C.peach);
    flatRoof(cx - 1.6, cy - 1.6, cx + 1.6, cy + .9, 2, C.white);
    onWall('y', cy + .9, cx - .3, cx + .4, 0, 1.4, rampOf(C.wood)[2]);
    windowOn('y', cy + .9, cx - 1.0, 1.0, .7, .7, C.white, C.glass, true);
    windowOn('x', cx + 1.6, cy - .4, 1.0, .9, .7, C.white, C.glass, true);
    block(cx - 1.2, cy + .9, 2.1, cx + .9, cy + 1.0, 2.6, C.red);
    onWall('y', cy + 1.0, cx - 1, cx + .7, 2.25, 2.45, rgb(250, 240, 210));
    shadowBox(cx - 1.6, cy - 1.6, cx + 1.6, cy + .9, 2.3, .6);
    for (const [tx, ty] of [[cx - .9, cy + 1.9], [cx + 1, cy + 1.7]]) {
      capsule([tx, ty, 0], [tx, ty, .6], .05, .05, () => C.dark, 'solid');
      for (let t = 0; t < 6.3; t += .1) for (let r = 0; r < .38; r += .05) plot(tx + Math.cos(t) * r, ty + Math.sin(t) * r, .62, rampOf(C.white)[3]);
      sphere(tx + .1, ty, .7, .1, [240, 200, 90], 'solid');
      for (const d of [-.55, .55]) block(tx + d - .12, ty - .12, .35, tx + d + .12, ty + .12, .4, C.red);
      castShadow(tx, ty, .5, .4);
    }
  },
  // 9 · a whole day at home: a two-storey lilac house, lights on, the moon up
  casa2(cx, cy) {
    block(cx - 1.4, cy - 1.4, 0, cx + 1.4, cy + 1.4, 3.6, C.lilac);
    flatRoof(cx - 1.4, cy - 1.4, cx + 1.4, cy + 1.4, 3.6, C.white);
    block(cx - 1.4, cy + 1.4, 1.8, cx + .6, cy + 2.1, 1.92, C.white);
    for (let a = cx - 1.4; a <= cx + .6; a += .22) block(a, cy + 2.04, 1.92, a + .05, cy + 2.1, 2.4, C.white);
    block(cx - 1.4, cy + 2.04, 2.4, cx + .6, cy + 2.1, 2.46, C.white);
    windowOn('y', cy + 1.4, cx - .5, 2.65, .6, .7, C.white, C.glass, true);
    windowOn('y', cy + 1.4, cx + .8, 2.65, .5, .7, C.white, C.glass, false);
    windowOn('y', cy + 1.4, cx - .8, .9, .6, .7, C.white, C.glass, true);
    onWall('y', cy + 1.4, cx + .45, cx + 1.05, 0, 1.4, rampOf(C.wood)[2]);
    windowOn('x', cx + 1.4, cy - .4, 2.65, .6, .7, C.white, C.glass, true);
    windowOn('x', cx + 1.4, cy - .4, .9, .6, .7, C.white, C.glass, false);
    shadowBox(cx - 1.4, cy - 1.4, cx + 1.4, cy + 1.4, 3.8, .6);
    sphere(cx + 1.7, cy - 2.4, 5.6, .45, [250, 236, 180], 'gloss');
    sphere(cx + 1.85, cy - 2.55, 5.75, .36, [40, 36, 70], 'solid');
    bush(cx + 2, cy + .4, .5);
  },
  // 10 · the fort: thick stone walls, a round sentry box, a flag over the gate
  fuerte(cx, cy) {
    const x0 = cx - 2.9, y0 = cy - 2.9, x1 = cx + 2.9, y1 = cy + 2.9, h = 2;
    block(x0, y0, 0, x1, y1, h, C.fort, C.fort.map(v => v * .94));
    for (let a = x0; a <= x1 - .3; a += .7) block(a, y1 - .3, h, a + .35, y1, h + .4, C.fort);
    for (let a = y0; a <= y1 - .3; a += .7) block(x1 - .3, a, h, x1, a + .35, h + .4, C.fort);
    for (let a = x0; a <= x1; a += ST) for (let z = .1; z < h; z += .55) plot(a, y1 + .02, z, rampOf(C.fort)[1]);
    for (let b = y0; b <= y1; b += ST) for (let z = .1; z < h; z += .55) plot(x1 + .02, b, z, rampOf(C.fort)[0]);
    onWall('y', y1, cx - .45, cx + .45, 0, 1.2, rampOf(C.dark)[1]);
    for (let t = 0; t < 3.15; t += .05) onWall('y', y1, cx + Math.cos(t) * .45 - .03, cx + Math.cos(t) * .45 + .03, 1.2, 1.2 + Math.sin(t) * .4, rampOf(C.dark)[1]);
    // the garita at the front corner
    const gx = x1 - .1, gy = y1 - .1;
    for (let t = 0; t < 6.283; t += .03) {
      const l = -.5 * Math.cos(t) + .85 * Math.sin(t);
      for (let z = h; z <= h + 1.1; z += ST) plot(gx + Math.cos(t) * .5, gy + Math.sin(t) * .5, z, rampOf(C.fort)[clamp(Math.round(2.4 + l * 1.3), 1, 4)]);
      for (let q = 0; q <= 1; q += .04) { const r = .6 * (1 - q); plot(gx + Math.cos(t) * r, gy + Math.sin(t) * r, h + 1.1 + Math.sin(q * 1.5) * .5, rampOf(C.fort)[clamp(Math.round(2.8 + l * 1.2), 1, 4)]); }
    }
    onWall('y', gy + .5, gx - .12, gx + .12, h + .35, h + .8, rampOf(C.dark)[0]);
    sphere(gx, gy, h + 1.7, .1, C.fort, 'solid');
    // the keep, set back
    block(cx - 1.6, cy - 1.6, h, cx + .4, cy + .4, h + 1.3, C.fort);
    windowOn('y', cy + .4, cx - .6, h + .7, .3, .45, C.fort, C.dark);
    capsule([cx - .6, cy - .6, h + 1.3], [cx - .6, cy - .6, h + 3.6], .05, .05, () => C.white, 'solid');
    shadowBox(x0, y0, x1, y1, h + .4, .6);
    shadowBox(cx - 1.6, cy - 1.6, cx + .4, cy + .4, h + 1.3, .5);
    for (let a = x0 - .3; a <= x1 + .3; a += .5) bush(a, y1 + .6 + hash(a * 9 | 0, 3) * .3, .25 + hash(a * 9 | 0, 4) * .15, [70, 120, 60]);
  },
};
const FLAG_POLE = () => { const { x, y } = XY(DIO[9][0], DIO[9][1]); return [x - .6, y - .6, 2 + 3.6]; };

/* ---------- decoration: palms on the beach, bushes in the grass ---------- */
function freeSpot(u, v, r) {
  if (roadDist(u, v) < r + 1) return false;
  for (const p of PADS) if (Math.hypot(u - p[0], v - p[1]) < r + 2) return false;
  for (const d of DIO) if (Math.abs(u - d[0]) < r + 3.6 && Math.abs(v - d[1]) < r + 4.2) return false;
  return true;
}
function decorate() {
  for (let k = 0; k < 220; k++) {
    const u = (hash(k, 61) - .5) * 30, v = -58 + hash(k, 62) * 106, sd = islandSd(u, v);
    if (sd > -3.8) continue;
    const { x, y } = XY(u, v);
    if (sd > -5.6) { if (hash(k, 63) < .35 && freeSpot(u, v, .8)) palm(x, y, 2.6 + hash(k, 64) * 1, (u > 0 ? 1 : -1) * (.5 + hash(k, 65) * .4) * .7, k); continue; }
    if (hash(k, 66) < .5 && freeSpot(u, v, .5)) bush(x, y, .3 + hash(k, 67) * .35, hash(k, 68) > .5 ? C.leaf : [96, 150, 70]);
    else if (hash(k, 69) < .3 && freeSpot(u, v, .3)) for (let f = 0; f < 5; f++) sphere(x + (hash(k, f) - .5) * .8, y + (hash(f, k) - .5) * .8, .06, .08, f % 2 ? [244, 120, 140] : [250, 230, 120], 'solid');
  }
}

/* ---------- bake ---------- */
const owner = new Int8Array(W * H).fill(-1);
let colourPix = null;
function bake() {
  zb.fill(-1e9);
  pix.fill(0);
  kinds.fill(0);
  waterPix.length = 0;
  // the places lay down their ground first (pond, street, plaza, beach)
  const placeIds = CURSO.lugares.map(l => l.id);
  const builds = placeIds.map((id, k) => () => { const { x, y } = XY(DIO[k][0], DIO[k][1]); PLACES[id](x, y); });
  // register ground patches by running each place once into a throwaway pass: patches are pushed at build time,
  // so build order is: patches (cheap) → ground → buildings. Patches only need the centre, so call with a flag.
  PATCH_ONLY = true; builds.forEach(b => b()); PATCH_ONLY = false;
  for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
    const g = unproject(ix + .5, iy + .5), i = iy * W + ix, c = groundColor(g.x, g.y, ix, iy, i);
    if (!c) continue;
    pix[i] = c; ground[i] = 1;
    zb[i] = (g.x + g.y) / R2 * COS;
  }
  slabSides();
  growGrass();
  groundZ.set(zb);
  decorate();
  // buildings, back to front, recording which pixels each place owns so locked places can be greyed
  const order = placeIds.map((_, k) => k).sort((a, b) => DIO[a][1] - DIO[b][1]);
  for (const k of order) {
    const zBefore = zb.slice();
    const l0 = leaves.length;
    builds[k]();
    for (let j = l0; j < leaves.length; j++) { leaves[j].owner = k; leaves[j].orig = leaves[j].pixels.slice(); }
    flushShadows(); pendingShadows.length = 0;
    for (let i = 0; i < pix.length; i++) if (zb[i] !== zBefore[i]) owner[i] = k;
  }
  // the ground a place laid down belongs to it too
  for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
    const i = iy * W + ix;
    if (owner[i] >= 0 || !ground[i]) continue;
    const g = unproject(ix + .5, iy + .5), { u, v } = UV(g.x, g.y);
    for (let k = 0; k < DIO.length; k++) if (Math.abs(u - DIO[k][0]) < 3.4 && Math.abs(v - DIO[k][1]) < 3.8 && patches.some(p => p.owner === k && p.hit(g.x, g.y))) owner[i] = k;
  }
  bakeOcclusion();
  staticShadow.set(shadowMask);
  applyShadows(groundZ);
  shadeEdges();
  colourPix = pix.slice();
  bakedZ.set(zb);
}
// the island floats: under its front edges, a band of deep water and then layered earth
function slabSides() {
  const T = 14;
  for (let ix = 0; ix < W; ix++) {
    let last = -1;
    for (let iy = 0; iy < H; iy++) {
      const i = iy * W + ix;
      if (ground[i]) { last = iy; continue; }
      if (last < 0 || iy - last > T || pix[i]) continue;
      const k = iy - last, g = unproject(ix + .5, last + .5), right = UV(g.x, g.y).u > 0;
      let c;
      if (k <= 3) c = rampOf([30, 90, 120])[right ? 1 : 2];
      else {
        const layer = k + Math.round(Math.sin(ix * .35) * 1.2);
        const base = layer < 7 ? [150, 112, 74] : layer < 11 ? [120, 88, 62] : [92, 70, 58];
        c = rampOf(base)[clamp((right ? 1 : 2) + (bayerAt(ix, iy) > .8 ? 1 : 0) - (hash(ix, iy) > .93 ? 1 : 0) - (k === T ? 1 : 0), 0, 4)];
      }
      pix[i] = c;
    }
  }
}
let PATCH_ONLY = false;
{
  // wrap each place so that, in the patch pass, only its patches.push calls run, tagged with their owner
  for (const [k, id] of ['casa', 'parque', 'cocina', 'colmado', 'calle', 'plaza', 'playa', 'fonda', 'casa2', 'fuerte'].entries()) {
    const real = PLACES[id];
    PLACES[id] = (x, y) => {
      if (!PATCH_ONLY) { const n = patches.length; patches.push = () => n; real(x, y); delete patches.push; return; }
      const n = patches.length;
      const noop = () => {};
      const saved = { plot, sphere, capsule, castShadow };
      // in the patch pass nothing is drawn: drawing helpers write into scratch buffers we restore after
      const pixSave = pix.slice(), zbSave = zb.slice(), maskSave = shadowMask.slice(), leavesN = leaves.length, pendN = pendingShadows.length;
      real(x, y);
      pix.set(pixSave); zb.set(zbSave); shadowMask.set(maskSave); leaves.length = leavesN; pendingShadows.length = pendN;
      for (let j = n; j < patches.length; j++) patches[j].owner = k;
      void noop; void saved;
    };
  }
}

/* ---------- state: which places are open, done, and where the frog is ---------- */
const STATE = { hecho: [], abierto: [], aqui: 0 };
function setState(st) {
  Object.assign(STATE, st);
  // locked places drop to a cool grey, like a model not yet painted
  pix.set(colourPix);
  for (let i = 0; i < pix.length; i++) {
    const k = owner[i];
    if (k < 0 || STATE.abierto[k]) continue;
    pix[i] = greyOf(pix[i]);
  }
  bakedPix.set(pix);
  for (const leaf of leaves) {
    if (leaf.owner == null) continue;
    const src = leaf.orig, dst = leaf.pixels, lock = !STATE.abierto[leaf.owner];
    for (let n = 3; n < src.length; n += 4) dst[n] = lock ? greyOf(src[n]) : src[n];
  }
}
function greyOf(c) { const r = c & 255, g = c >> 8 & 255, b = c >> 16 & 255, l = r * .3 + g * .55 + b * .15; return rgb(l * .72 + 38, l * .74 + 42, l * .8 + 56); }

/* ---------- the frog ---------- */
const TAN = [200, 133, 60], CREAM = [238, 220, 176], EYE = [250, 250, 245], PUPIL = [32, 20, 10];
const frogBone = (a, b, r0, r1, f) => { capsule(a, b, r0, r1, f, 'solid'); pendingShadows.push(a, r0, b, r1); };
function drawFrog(x, y, z, yaw, squash = 0) {
  const fx = Math.cos(yaw), fy = Math.sin(yaw), sx = -fy, sy = fx, k = 1.5;
  const P = (a, b, c) => [x + (fx * a + sx * b) * k, y + (fy * a + sy * b) * k, z + c * k];
  const s = 1 - squash * .25, frogAdd = (a, b, r0, r1, f) => frogBone(a, b, r0 * k, r1 * k, f);
  frogAdd(P(-.15, 0, .3 * s), P(.15, 0, .34 * s), .3, .28, () => TAN);
  frogAdd(P(.22, 0, .2 * s), P(.22, 0, .22 * s), .16, .16, () => CREAM);
  for (const side of [-1, 1]) {
    frogAdd(P(-.18, side * .3, .1), P(.05, side * .36, .06), .12, .09, () => TAN);
    frogAdd(P(.2, side * .22, .06), P(.3, side * .26, .04), .07, .06, () => TAN);
    frogAdd(P(.2, side * .17, .58 * s), P(.2, side * .17, .58 * s), .14, .14, () => TAN);
    frogAdd(P(.27, side * .17, .6 * s), P(.27, side * .17, .6 * s), .1, .1, () => EYE);
    frogAdd(P(.34, side * .17, .6 * s), P(.34, side * .17, .6 * s), .05, .05, () => PUPIL);
  }
}
const FROG = { at: 0, x: 0, y: 0, z: 0, yaw: FACE, path: null, t: 0, squash: 0, onArrive: null };
function placeFrog(k) { const { x, y } = XY(...PADS[k]); Object.assign(FROG, { at: k, x, y, z: 0, path: null }); }
function hopTo(k, done) {
  const pts = route(FROG.at, k).map(p => XY(p[0], p[1]));
  // break long legs into hops of about 2.2 units
  const hops = [];
  for (let n = 1; n < pts.length; n++) {
    const a = pts[n - 1], b = pts[n], d = Math.hypot(b.x - a.x, b.y - a.y), m = Math.max(1, Math.round(d / 2.2));
    for (let j = 1; j <= m; j++) hops.push({ x0: lerp(a.x, b.x, (j - 1) / m), y0: lerp(a.y, b.y, (j - 1) / m), x1: lerp(a.x, b.x, j / m), y1: lerp(a.y, b.y, j / m) });
  }
  Object.assign(FROG, { path: hops, t: 0, target: k, onArrive: done });
}
function updateFrog(dt) {
  if (!FROG.path) { FROG.squash = Math.max(0, FROG.squash - dt * 4); return; }
  FROG.t += dt / .2;
  const h = FROG.path[0], t = Math.min(1, FROG.t);
  FROG.x = lerp(h.x0, h.x1, t); FROG.y = lerp(h.y0, h.y1, t); FROG.z = Math.sin(t * Math.PI) * .9;
  FROG.yaw = Math.atan2(h.y1 - h.y0, h.x1 - h.x0);
  if (t >= 1) {
    FROG.path.shift(); FROG.t = 0; FROG.squash = 1; sfxHop();
    if (!FROG.path.length) { FROG.path = null; FROG.at = FROG.target; FROG.yaw = FACE; FROG.onArrive && FROG.onArrive(); }
  }
}

/* ---------- per frame ---------- */
const DIGITS = { 0: '111101101101111', 1: '010110010010111', 2: '111001111100111', 3: '111001111001111', 4: '101101111001001', 5: '111100111001111', 6: '111100111101111', 7: '111001010010010', 8: '111101111101111', 9: '111101111001111' };
function rect(x, y, w, h, c) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) { const X = x + i, Y = y + j; if (X >= 0 && Y >= 0 && X < W && Y < H) pix[Y * W + X] = c; } }
function plate(k, sx, sy) {
  const n = String(k + 1), w = n.length * 4 + 3, x = Math.round(sx - w / 2), y = Math.round(sy);
  const fill = STATE.hecho[k] ? rgb(255, 214, 10) : STATE.abierto[k] ? rgb(255, 255, 255) : rgb(150, 154, 166);
  rect(x - 1, y - 1, w + 2, 9, INK);
  rect(x, y, w, 7, fill);
  [...n].forEach((ch, j) => { const d = DIGITS[ch]; for (let r = 0; r < 5; r++) for (let q = 0; q < 3; q++) if (d[r * 3 + q] === '1') pix[(y + 1 + r) * W + x + 2 + j * 4 + q] = INK; });
}
function drawFlag(x, y, z, t, col) {
  capsule([x, y, z], [x, y, z + 1.6], .04, .04, () => C.white, 'solid');
  for (let a = 0; a <= .9; a += .03) for (let b = 0; b <= .5; b += .03) {
    const wave = Math.sin(a * 6 - t * 6) * .1 * a;
    plot(x + a * .7, y - a * .7 + wave, z + 1.6 - b, rampOf(col)[clamp(Math.round(3 + Math.sin(a * 6 - t * 6)), 1, 4)]);
  }
}
function drawSea(t) {
  const lit = rgb(176, 222, 214), soft = rgb(120, 190, 186), foam = rgb(244, 248, 240);
  for (let n = 0; n < waterPix.length; n += 4) {
    const i = waterPix[n], u = waterPix[n + 1], v = waterPix[n + 2], sd = waterPix[n + 3];
    if (zb[i] !== groundZ[i]) continue;
    if (sd > -2.7 && sd < -2.35 && Math.sin(u * 1.7 + v * .9 + t * 2.4) > -.2) { pix[i] = foam; continue; }
    const ph = (v * .8 + Math.sin(u * .6) * 1.4 + t * .7) % 3.2;
    if (ph > 0 && ph < .22 && hash(i % W >> 1, i / W | 0) > .4) pix[i] = staticShadow[i] ? soft : lit;
  }
}
let time = 0;
function draw() {
  pix.set(bakedPix);
  zb.set(bakedZ);
  pendingShadows.length = 0;
  const windT = STILL ? 0 : Math.floor(time * WIND_FPS) / WIND_FPS;
  drawSea(windT);
  drawLeaves(windT);
  drawTufts(windT);
  for (let k = 0; k < PADS.length; k++) if (STATE.hecho[k]) { const { x, y } = XY(PADS[k][0] + .9, PADS[k][1] - .9); drawFlag(x, y, 0, windT, C.red); }
  { const [x, y, z] = FLAG_POLE(); drawFlag(x, y, z, windT, STATE.abierto[9] ? C.red : [150, 150, 160]); }
  drawFrog(FROG.x, FROG.y, FROG.z, FROG.yaw, FROG.squash);
  flushShadows();
  applyShadows(groundZ);
  for (let k = 0; k < PADS.length; k++) { const { x, y } = XY(...PADS[k]), p = project(x, y, 0); plate(k, p.sx, p.sy + 7); }
  if (!FROG.path) { const p = project(FROG.x, FROG.y, 1.2 + FROG.z); drawArrow(p.sx, p.sy - 2, time); }
  ctx.putImageData(image, 0, 0);
}

/* ---------- sound: a soft hop, made in the browser ---------- */
let audio = null;
function sfxHop() {
  if (!audio) return;
  const o = audio.createOscillator(), g = audio.createGain(), now = audio.currentTime;
  o.type = 'square'; o.frequency.setValueAtTime(320, now); o.frequency.exponentialRampToValueAtTime(520, now + .07);
  g.gain.setValueAtTime(.025, now); g.gain.exponentialRampToValueAtTime(.0005, now + .09);
  o.connect(g).connect(audio.destination); o.start(now); o.stop(now + .1);
}
function wakeAudio() { if (!audio) { const AC = window.AudioContext || window.webkitAudioContext; if (AC) audio = new AC(); } else if (audio.state === 'suspended') audio.resume(); }

/* ---------- tap: nearest stop or place ---------- */
function stopAt(cx, cy) {
  let best = -1, bd = 22;
  for (let k = 0; k < PADS.length; k++) {
    for (const p of [PADS[k], DIO[k]]) {
      const { x, y } = XY(p[0], p[1]), s = project(x, y, p === DIO[k] ? 1 : 0), d = Math.hypot(s.sx - cx, s.sy - cy);
      if (d < bd) { bd = d; best = k; }
    }
  }
  return best;
}

window.MAPA = { bake, setState, placeFrog, hopTo, updateFrog, draw, stopAt, wakeAudio, PADS, XY, project, STATE, FROG,
  tick(dt) { time += dt; updateFrog(dt); draw(); } };
