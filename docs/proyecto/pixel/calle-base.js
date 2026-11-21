'use strict';
/* The streets of place 5 (La calle): the painters and the pieces its four scene sets share (esquina, parada, tiendas, cruce).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, colmado-fuera.js (for nothing but its colours' company) and this file.
   World (S = 26). The camera sees the faces that look to +y (lit) and to +x (in shade), and tops. So a building stands at the far side of what it
   faces: a wall "along x" is the plane y = at, seen whole; a wall "along y" is the plane x = at.
   Everything that moves is a sprite: people, the dog, cars, guaguas, bicycles, what is carried, the lamps of a traffic light. */
const CL = (() => {
  const PX = .04, PZ = .035, PA = .03, PP = .024;                 // sampling steps: faces, tops, painted planes
  const ASPH = [98, 96, 104], ASPH_L = [112, 110, 116], KERB = [214, 208, 196], LINE = [232, 218, 150], WHITE = [238, 236, 226];
  const SALMON = [240, 150, 116], TEAL = [86, 160, 150], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92], LEAF = [74, 134, 62], LEAF_L = [112, 176, 84], TRUNK = [120, 84, 56];

  /* ---- painters ---- */
  // a face on the plane y = at (faces +y): fn(a, z) gives the colour, or 0 for a hole
  function faceY(at, a0, a1, z0, z1, fn, step = PX) { for (let a = a0; a <= a1; a += step) for (let z = z0; z <= z1; z += PZ) { const c = fn(a, z); if (c) plot(a, at, z, c); } }
  // a face on the plane x = at (faces +x): fn(b, z)
  function faceX(at, b0, b1, z0, z1, fn, step = PX) { for (let b = b0; b <= b1; b += step) for (let z = z0; z <= z1; z += PZ) { const c = fn(b, z); if (c) plot(at, b, z, c); } }
  function top(x0, y0, x1, y1, z, fn) { for (let a = x0; a <= x1; a += PA) for (let b = y0; b <= y1; b += PA) { const c = fn(a, b); if (c) plot(a, b, z, c); } }
  // a box: its top and its two seen faces
  function box(x0, y0, z0, x1, y1, z1, c, topFn) {
    top(x0, y0, x1, y1, z1, (a, b) => (topFn && topFn(a, b)) || shade(c, 3.4, a, b));
    faceY(y1, x0, x1, z0, z1, (a, z) => shade(c, 2.4, a, z));
    faceX(x1, y0, y1, z0, z1, (b, z) => shade(c, 1.3, b, z));
  }

  /* ---- the ground ---- */
  const slab = (x, y, ix, iy) => { const ea = ((x + 40) % 1.1) / 1.1, eb = ((y + 40) % 1.1) / 1.1; return (ea < .04 || eb < .04) ? rgb(168, 160, 150) : toneOf(C.pave, .45 + hash(Math.floor((x + 40) / 1.1), Math.floor((y + 40) / 1.1)) * .3, ix, iy); };
  const asphalt = (ix, iy) => rgb(...((hash(ix >> 1, iy >> 1) < .08) ? ASPH_L : ASPH));
  const kerb = () => rgb(...KERB);
  const paint = c => rgb(...c);
  const grass = (x, y, ix, iy) => rgb(...GRASS[clamp(Math.floor((.3 + noise(x * .7, y * .7) * .7 + (hash(ix, iy) - .5) * .3) * 4), 0, 3)]);

  /* ---- pieces ---- */
  // a wall along x at y = at, from x0 to x1, h high, painted c with a darker foot and a band under its top; holes [a0, a1, z0, z1]
  function wallAlongX(at, x0, x1, h, c, trim, holes = []) {
    faceY(at, x0, x1, 0, h, (a, z) => holes.some(k => a > k[0] && a < k[1] && z > k[2] && z < k[3]) ? 0 : z < .6 ? shade(trim, z > .54 ? 1.6 : 2.4, a, z) : z > h - .28 ? shade(trim, 2.6, a, z) : shade(c, 2.4, a, z));
  }
  function wallAlongY(at, y0, y1, h, c, trim, holes = []) {
    faceX(at, y0, y1, 0, h, (b, z) => holes.some(k => b > k[0] && b < k[1] && z > k[2] && z < k[3]) ? 0 : z < .6 ? shade(trim, z > .54 ? 1.2 : 1.8, b, z) : z > h - .28 ? shade(trim, 2.0, b, z) : shade(c, 1.85, b, z));
  }
  // a door in a wall along x (hinge side irrelevant: shut, or open inwards so that the dim inside shows)
  function doorX(at, d0, d1, dh, open, wood = WOOD, glassTop = true) {
    const w = d1 - d0, Wd = rampOf(wood), F = rampOf(WOOD_L);
    faceY(at - .9, d0, d1, 0, dh, (a, z) => z < .14 ? rgb(60, 44, 34) : rgb(84 - z * 10, 78 - z * 10, 70 - z * 8), PP);          // the dim inside
    top(d0, at - .9, d1, at, 0, () => rgb(120, 104, 88));
    faceY(at, d0 - .12, d1 + .12, 0, dh + .12, (a, z) => (a > d0 && a < d1 && z < dh) ? 0 : (z > dh ? F[3] : F[2]), PP);          // the frame
    const panel = (t, z) => {
      const u = t * w, glass = glassTop && u > .2 && u < w - .2 && z > 1.3 && z < dh - .25;
      if (!glass) return Wd[(u < .08 || u > w - .08 || z < .08 || z > dh - .08) ? 1 : 2];
      const s = (u * 1.5 + z) % 1.1;
      return s < .2 ? rgb(232, 246, 250) : (s > .32 && s < .4) ? rgb(206, 232, 240) : rgb(150, 200, 214);
    };
    if (open) { const ang = .25, dx = Math.cos(ang), dy = Math.sin(ang); for (let t = 0; t <= 1; t += PP / w) for (let z = 0; z <= dh; z += PP) plot(d1 + dx * w * t, at + .02 + dy * w * t, z, panel(t, z)); }
    else faceY(at - .05, d0, d1, 0, dh, (a, z) => panel((d1 - a) / w, z), PP);
  }
  // a board with a picture on a wall along x: fn(u, v) with u, v from 0 to 1 gives a colour (the board's cream ground otherwise)
  function signX(at, a0, a1, z0, z1, fn) {
    faceY(at + .03, a0, a1, z0, z1, (a, z) => { const u = (a - a0) / (a1 - a0), v = (z - z0) / (z1 - z0); if (u < .05 || u > .95 || v < .09 || v > .91) return rgb(120, 76, 44); return fn(u, v) || rgb(250, 244, 226); }, PP);
  }
  function signY(at, b0, b1, z0, z1, fn) {
    faceX(at + .03, b0, b1, z0, z1, (b, z) => { const u = (b1 - b) / (b1 - b0), v = (z - z0) / (z1 - z0); if (u < .05 || u > .95 || v < .09 || v > .91) return rgb(96, 62, 38); return fn(u, v) || rgb(226, 220, 204); }, PP);
  }
  // a window in a wall along y: a frame, glass with streaks, a sill
  function windowY(at, b0, b1, z0, z1) {
    const F = rampOf([244, 240, 228]);
    faceX(at + .02, b0 - .1, b1 + .1, z0 - .1, z1 + .1, (b, z) => {
      if (b < b0 || b > b1 || z < z0 || z > z1 || Math.abs(b - (b0 + b1) / 2) < .04) return F[1];
      const s = ((b1 - b) * 1.4 + z) % 1.2; return s < .18 ? rgb(196, 226, 232) : rgb(120, 170, 186);
    }, PP);
    box(at, b0 - .16, z0 - .2, at + .14, b1 + .16, z0 - .1, [230, 224, 210]);
  }
  // a striped awning over a stretch of a wall along y
  function awningY(at, b0, b1, z1, z0, out) {
    for (let b = b0; b <= b1; b += PA) for (let a = 0; a <= out; a += PA) { const z = z1 - a / out * (z1 - z0), s = Math.floor((b - b0) / .42) % 2; plot(at + a, b, z, shade(s ? [226, 60, 50] : [250, 246, 236], 3.0, a, b)); }
    faceX(at + out, b0, b1, z0 - .2, z0, (b, z) => shade((Math.floor((b - b0) / .42) % 2) ? [226, 60, 50] : [250, 246, 236], 1.5, b, z));
  }
  // a tree: a trunk and a crown of leaf balls
  function tree(x, y, h, r, c = LEAF, c2 = LEAF_L) {
    for (let z = 0; z <= h; z += PZ) for (let t = 0; t < 6.3; t += .25) plot(x + Math.cos(t) * .13, y + Math.sin(t) * .13, z, shade(TRUNK, 1.4 + Math.cos(t - .8), t, z));
    const B = [[0, 0, 0, 1], [-.55, .1, -.15, .72], [.5, -.15, -.1, .74], [.1, .5, -.25, .66], [-.15, -.5, .1, .68], [.3, .3, .35, .6], [-.35, -.2, .4, .58]];
    for (const [dx, dy, dz, k] of B) sphere(x + dx * r, y + dy * r, h + r * .7 + dz * r, r * k, k > .7 ? c : c2, 'rough');
    castShadow(x, y, h, r * 1.2); castShadow(x + .2, y, h + .4, r);
  }
  // a pole with a traffic light: three dark lamps (the lit one is a sprite) and a button box at frog height. Returns the lamps' and the button's places
  function trafficLight(x, y) {
    const M = [70, 74, 84], Dk = [36, 38, 46];
    for (let z = 0; z <= 2.5; z += PZ) for (let t = 0; t < 6.3; t += .4) plot(x + Math.cos(t) * .055, y + Math.sin(t) * .055, z, shade(M, 1.2 + Math.cos(t - .8) * 1.2, t, z));
    box(x - .2, y - .12, 2.3, x + .2, y + .12, 3.4, Dk);
    const lamps = [];
    for (let k = 0; k < 3; k++) { const z = 3.2 - k * .34; lamps.push({ x, y: y + .125, z }); for (let a = -.12; a <= .12; a += .02) for (let b = -.12; b <= .12; b += .02) if (a * a + b * b < .0144) plot(x + a, y + .125, z + b, rgb(64, 60, 60)); }
    box(x - .12, y + .02, .62, x + .12, y + .16, .98, [236, 196, 60]);
    for (let a = -.05; a <= .05; a += .015) for (let b = -.05; b <= .05; b += .015) if (a * a + b * b < .003) plot(x + a, y + .165, .8 + b, rgb(206, 60, 50));
    for (let z = .15; z <= 2.4; z += .12) castShadow(x, y, z, .07);
    castShadow(x, y, 2.8, .3);
    return { lamps, button: { x, y: y + .165, z: .8 } };
  }
  // a row of traffic cones, baked (the ones a story knocks over are sprites)
  function cone(x, y) {
    for (let z = 0; z <= .5; z += .02) { const r = .13 * (1 - z / .56) + .015, band = z > .2 && z < .3; for (let t = 0; t < 6.3; t += .22) plot(x + Math.cos(t) * r, y + Math.sin(t) * r, z, shade(band ? [250, 246, 236] : [238, 120, 40], 1.6 + Math.cos(t - .8) * 1.1, t, z)); }
    box(x - .15, y - .15, 0, x + .15, y + .15, .04, [226, 104, 36]);
    castShadow(x, y, .25, .16);
  }
  // a window in a wall along x, and a striped awning over a stretch of such a wall
  function windowX(at, a0, a1, z0, z1) {
    const F = rampOf([244, 240, 228]);
    faceY(at + .02, a0 - .1, a1 + .1, z0 - .1, z1 + .1, (a, z) => {
      if (a < a0 || a > a1 || z < z0 || z > z1 || Math.abs(a - (a0 + a1) / 2) < .04) return F[3];
      const s = ((a - a0) * 1.4 + z) % 1.2; return s < .18 ? rgb(226, 244, 248) : (s > .5 && s < .58) ? rgb(196, 226, 236) : rgb(150, 200, 214);
    }, PP);
    box(a0 - .16, at, z0 - .2, a1 + .16, at + .14, z0 - .1, [240, 234, 220]);
  }
  function awningX(at, a0, a1, z1, z0, out) {
    for (let a = a0; a <= a1; a += PA) for (let b = 0; b <= out; b += PA) { const z = z1 - b / out * (z1 - z0), s = Math.floor((a - a0) / .42) % 2; plot(a, at + b, z, shade(s ? [226, 60, 50] : [250, 246, 236], 3.2, a, b)); }
    faceY(at + out, a0, a1, z0 - .22, z0, (a, z) => shade((Math.floor((a - a0) / .42) % 2) ? [226, 60, 50] : [250, 246, 236], 2.2, a, z));
  }
  /* ---- things that drive, built on the engine so that a reader's render and the port's sprites come from one drawing ----
     kind: carro (red), azul (the blue car), guagua. (x, y): the middle of its floor. heading: 'i' it drives towards -x (its right side, the lit
     one with a guagua's door, faces the camera; we see its back end... no: its FRONT is at -x, hidden; the face at +x is its back), 'd' towards +x
     (the face at +x is its front; the side we see is its left). Dark windows: nobody is seen inside. */
  const BOARDS = {                                                    // the pictures of where a guagua goes
    arbol: (u, v) => (Math.hypot(u - .5, v - .62) < .27 || Math.hypot(u - .34, v - .5) < .17 || Math.hypot(u - .66, v - .5) < .17) ? rgb(70, 150, 70) : (Math.abs(u - .5) < .06 && v < .5 && v > .12) ? rgb(120, 84, 56) : 0,
    toldo: (u, v) => (v > .52 && v < .84 && u > .14 && u < .86) ? (Math.floor((u - .14) / .12) % 2 ? rgb(226, 60, 50) : rgb(252, 250, 244)) : (v > .14 && v <= .52 && u > .2 && u < .8) ? (u > .4 && u < .6 ? rgb(120, 76, 44) : rgb(240, 150, 116)) : 0,
    casa: (u, v) => (v > .5 && v < .88 && Math.abs(u - .5) < (.88 - v) * .95) ? rgb(206, 80, 60) : (v > .14 && v <= .5 && u > .26 && u < .74) ? (u > .44 && u < .58 && v < .38 ? rgb(120, 76, 44) : rgb(250, 214, 120)) : 0,
  };
  function vehicle(kind, x, y, heading = 'i', board = null) {
    const bus = kind === 'guagua', L = bus ? 4.4 : 2.2, Wd = bus ? 1.3 : 1.1, c = bus ? [244, 244, 236] : kind === 'azul' ? [70, 120, 206] : [214, 62, 54];
    const x0 = x - L / 2, x1 = x + L / 2, y0 = y - Wd / 2, y1 = y + Wd / 2, G = [44, 52, 66], G2 = [70, 84, 104], TY = [40, 38, 44];
    const front = heading === 'd';                                    // is the face at +x the front?
    const wheel = (wx) => { for (let a = -.26; a <= .26; a += .02) for (let b = -.26; b <= .26; b += .02) { const r = Math.hypot(a, b); if (r < .26) plot(wx + a, y1 + .02, .26 + b, r < .1 ? rgb(170, 170, 176) : rgb(...TY)); } };
    if (bus) {
      const H0 = .3, H1 = 2.15, BAND = [60, 150, 120];
      top(x0, y0, x1, y1, H1, (a, b) => shade([226, 226, 220], 3.4, a, b));
      faceY(y1, x0, x1, H0, H1, (a, z) => {                              // the side: a band, a row of dark windows, the door near the front end
        const u = a - x0, dn = front ? (x1 - a) : u;                     // distance from the front end
        if (dn > .35 && dn < 1.15 && z < H1 - .2) return (Math.abs(dn - .75) < .03) ? rgb(30, 34, 44) : (z > .95 ? rgb(...(((dn * 3 + z) % 1.3) < .2 ? G2 : G)) : rgb(86, 96, 110));   // the door: two leaves with glass
        if (z > 1.15 && z < 1.85 && dn > 1.35 && dn < L - .25 && ((dn - 1.35) % .78) < .62) return rgb(...(((a * 2 + z) % 1.6) < .22 ? G2 : G));
        if (z > .62 && z < .86) return shade(BAND, 2.4, a, z);
        return shade(c, 2.4, a, z);
      });
      faceX(x1, y0, y1, H0, H1, (b, z) => {                              // the end we see: the front (a big windscreen, a picture board over it, two lamps) or the back
        const v = b - y0;
        if (front) { if (z > 1.72 && z < 2.05 && v > .2 && v < Wd - .2) return rgb(250, 244, 226); if (z > .95 && z < 1.66 && v > .1 && v < Wd - .1) return rgb(...G); if (z > .45 && z < .62 && (v < .3 || v > Wd - .3)) return rgb(250, 232, 150); }
        else { if (z > 1.15 && z < 1.8 && v > .15 && v < Wd - .15) return rgb(...G); if (z > .5 && z < .66 && (v < .25 || v > Wd - .25)) return rgb(206, 50, 44); }
        return z > .62 && z < .86 ? shade(BAND, 1.4, b, z) : shade(c, 1.4, b, z);
      });
      if (board && BOARDS[board]) {                                     // where it goes: a picture on a plate that stands on its roof, over the door
        const b0 = front ? x1 - 1.9 : x0 + .5, b1 = b0 + 1.4;
        faceY(y1 - .12, b0, b1, H1, H1 + .78, (a, z) => { const u = (a - b0) / 1.4, v = (z - H1) / .78; return (u < .05 || u > .95 || v < .07 || v > .93) ? rgb(60, 64, 74) : (BOARDS[board](u, v) || rgb(250, 246, 232)); }, PP);
      }
      wheel(x0 + .8); wheel(x1 - .8);
      for (let a = x0; a <= x1; a += .5) castShadow(a, y, 1.2, .8);
    } else {
      const H0 = .22, H1 = .78, C0 = x0 + (front ? .45 : .6), C1 = x1 - (front ? .6 : .45), H2 = 1.22;   // the body, and the cabin on it
      top(x0, y0, x1, y1, H1, (a, b) => (a > C0 && a < C1) ? 0 : shade(c, 3.4, a, b));
      top(C0, y0 + .06, C1, y1 - .06, H2, (a, b) => shade(c, 3.4, a, b));
      faceY(y1, x0, x1, H0, H1, (a, z) => shade(c, 2.4, a, z));
      faceY(y1 - .06, C0, C1, H1, H2, (a, z) => (a > C0 + .1 && a < C1 - .1 && z < H2 - .08 && Math.abs(a - (C0 + C1) / 2) > .04) ? rgb(...(((a * 2 + z) % 1.4) < .2 ? G2 : G)) : shade(c, 2.4, a, z));
      faceX(x1, y0, y1, H0, H1, (b, z) => { const v = b - y0; if (z > .46 && z < .62 && (v < .26 || v > Wd - .26)) return front ? rgb(250, 232, 150) : rgb(206, 50, 44); return shade(c, 1.4, b, z); });
      faceX(C1, y0 + .06, y1 - .06, H1, H2, (b, z) => (b > y0 + .14 && b < y1 - .14 && z < H2 - .08) ? rgb(...G) : shade(c, 1.4, b, z));
      wheel(x0 + .5); wheel(x1 - .5);
      for (let a = x0 + .3; a <= x1; a += .5) castShadow(a, y, .5, .65);
    }
  }
  // a seat with a back, along x (its back at the far side), and a bench without one
  function seat(x0, y0, x1, back = true, c = [150, 104, 62]) {
    const y1 = y0 + .5;
    box(x0, y0, .36, x1, y1, .46, c);
    for (const x of [x0 + .08, x1 - .2]) box(x, y0 + .06, 0, x + .12, y1 - .06, .36, [70, 60, 56]);
    if (back) { box(x0, y0 - .02, .46, x1, y0 + .08, 1.0, c); }
    for (let a = x0; a <= x1; a += .3) castShadow(a, y0 + .25, .4, .3);
  }
  // a thin pole with a board on it, facing +y: fn(u, v) paints the board (0: its ground colour)
  function signPole(x, y, h, bw, bh, ground, fn) {
    for (let z = 0; z <= h; z += PZ) for (let t = 0; t < 6.3; t += .5) plot(x + Math.cos(t) * .045, y + Math.sin(t) * .045, z, shade([90, 94, 104], 1.2 + Math.cos(t - .8) * 1.2, t, z));
    faceY(y + .06, x - bw / 2, x + bw / 2, h - bh, h, (a, z) => { const u = (a - x + bw / 2) / bw, v = (z - h + bh) / bh; return (u < .07 || u > .93 || v < .07 || v > .93) ? rgb(250, 250, 250) : (fn(u, v) || rgb(...ground)); }, PP);
    for (let z = .15; z <= h; z += .12) castShadow(x, y, z, .06);
  }
  // a house front in a wall along x: a painted wall from x0 to x1, a door, a window, a flat roof edge. doorAt, winAt: x of their left edges (null: none)
  function houseX(at, x0, x1, h, c, trim, doorAt, winAt, doorC = WOOD, deep = 1.4) {
    const holes = [];
    if (doorAt != null) holes.push([doorAt - .1, doorAt + 1.2, 0, 2.5]);
    if (winAt != null) holes.push([winAt - .1, winAt + 1.3, 1.0, 2.2]);
    top(x0, at - deep, x1, at, h, (a, b) => shade(trim, 3.2, a, b));
    wallAlongX(at, x0, x1, h, c, trim, holes);
    faceX(x1, at - deep, at, 0, h, (b, z) => shade(c, 1.6, b, z));
    if (doorAt != null) doorX(at, doorAt, doorAt + 1.1, 2.4, false, doorC, false);
    if (winAt != null) windowX(at, winAt, winAt + 1.2, 1.1, 2.1);
  }
  // the sky, screen space: bands by hour and a sun; returns the skyFill function. sun: [sx, sy, r] or null
  function sky(hora, sun) {
    const B = { temprano: [[250, 196, 150], [252, 214, 170], [250, 230, 196], [226, 236, 244], [190, 222, 250]], manana: [[80, 150, 236], [110, 176, 246], [150, 200, 252], [190, 222, 255], [226, 240, 255]],
      tarde: [[236, 120, 70], [246, 156, 84], [250, 190, 110], [252, 214, 150], [254, 234, 190]], noche: [[44, 46, 96], [70, 62, 120], [120, 84, 130], [190, 110, 110], [236, 150, 96]], gris: [[120, 128, 144], [144, 152, 166], [170, 178, 190], [196, 202, 212], [220, 224, 230]] }[hora] || null;
    const T = hora === 'tarde' || hora === 'noche' ? [[250, 150, 60], [254, 190, 90], [255, 226, 150]] : [[246, 222, 130], [252, 238, 168], [255, 250, 212]];
    return (ix, iy) => (sun && skyDisc(sun[0], sun[1], sun[2], T, ix, iy)) || skyBands(B || [[150, 200, 252]], 0, H, ix, iy);
  }
  return { PX, PZ, PA, PP, ASPH, KERB, LINE, WHITE, SALMON, TEAL, WOOD, WOOD_L, LEAF, LEAF_L, faceY, faceX, top, box, slab, asphalt, kerb, paint, grass, wallAlongX, wallAlongY, doorX, signX, signY, windowY, awningY, windowX, awningX, vehicle, tree, trafficLight, cone, seat, signPole, houseX, sky };
})();
