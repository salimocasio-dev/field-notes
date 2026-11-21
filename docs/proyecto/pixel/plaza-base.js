'use strict';
/* La plaza (place 6): what its four scene sets share (plaza, reloj, quiosco, calendario).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, calle-base.js (for its tree and its sky) and this file.
   Everything here is laid out square to the picture, in u, v: u runs across the picture (to the right), v runs down it (towards the camera);
   x = (u + v) / R2, y = (v - u) / R2. One u is 26 px across, one v is 13 px down, one z is 22.5 px up. A wall that faces the camera is a
   plane v = const: it is drawn pixel by pixel (planeQuad), so a picture, a numeral or a clock face on it keeps its shape.
   Everything that moves is a sprite: people, the dog, pigeons, cards, what is carried, the hands of the clock. */
const PZ = (() => {
  const A = -Math.PI / 4;
  const uv = (x, y) => [(x - y) / R2, (x + y) / R2], xy = (u, v) => [(u + v) / R2, (v - u) / R2];
  const STONE = [214, 204, 186], STONE_D = [176, 166, 150], WOOD = [150, 104, 62], WOOD_D = [104, 72, 48], IRON = [60, 64, 76], CREAM = [248, 238, 212],
    OCHRE = [236, 190, 112], TILE = [204, 98, 72], EARTH = [112, 82, 60], WHITE = [250, 248, 240];
  const api = { NIGHT: false };

  /* ---- the ground ---- */
  // the square's paving: big stone tiles, every other one a shade darker, thin joints
  function paving(u, v, ix, iy) {
    const K = 1.0, a = ((u + 60.5) % K) / K, b = ((v + 60) % K) / K;
    if (a < .045 || b < .085) return rgb(186, 174, 154);
    const cu = Math.floor(u + 60.5), cv = Math.floor(v + 60), n = hash(cu * 7, cv * 13) * 8, sp = hash(ix, iy) < .035 ? 12 : 0;
    const c = ((cu + cv) & 1) ? [228, 216, 192] : [238, 228, 206];
    return rgb(c[0] - n - sp, c[1] - n - sp, c[2] - n - sp);
  }
  const grass = (u, v, ix, iy) => { const [x, y] = xy(u, v); return CL.grass(x, y, ix, iy); };

  /* ---- painters, square to the picture ---- */
  const P = (u, v, z = 0) => UVW(u, v, z);
  // a box: middle (u, v), half-width hw across, half-depth hd; fn(s, t, z, face) as turnedBox ('front' faces the camera)
  function box(u, v, z0, z1, hw, hd, c, fn = null) { const [x, y] = xy(u, v); turnedBox(x, y, z0, z1, hw, hd, A, c, fn); }
  // a wall that faces the camera, at v, from u0 to u1 and z0 to z1: fn(u, z) gives the colour (0: a hole)
  function wall(u0, u1, v, z0, z1, fn) { planeQuad(P(u0, v, z0), [(u1 - u0) / R2, -(u1 - u0) / R2, 0], [0, 0, z1 - z0], (a, b) => fn(u0 + a * (u1 - u0), z0 + b * (z1 - z0))); }
  // a flat top at z: fn(u, v)
  function flat(u0, v0, u1, v1, z, fn) { planeQuad(P(u0, v0, z), [(u1 - u0) / R2, -(u1 - u0) / R2, 0], [(v1 - v0) / R2, (v1 - v0) / R2, 0], (a, b) => fn(u0 + a * (u1 - u0), v0 + b * (v1 - v0))); }
  // a slope that rises away from the camera (a roof seen from the front): from (v0, z0) at its near edge to (v1, z1) at its far edge
  function slope(u0, u1, v0, z0, v1, z1, fn) { planeQuad(P(u0, v0, z0), [(u1 - u0) / R2, -(u1 - u0) / R2, 0], [(v1 - v0) / R2, (v1 - v0) / R2, z1 - z0], (a, b) => fn(u0 + a * (u1 - u0), b)); }
  const lit = (c, a = 0, b = 0) => shade(c, 2.4, a, b), dim = (c, a = 0, b = 0) => shade(c, 1.5, a, b), up = (c, a = 0, b = 0) => shade(c, 3.4, a, b);
  function post(u, v, z0, z1, r, c) { const [x, y] = xy(u, v); drum(x, y, z0, z1, r, c); for (let z = z0 + .1; z <= z1; z += .1) castShadow(x, y, z, r + .03); }
  function ball(u, v, z, r, c, mode = 'rough') { const [x, y] = xy(u, v); sphere(x, y, z, r, c, mode); }
  function shadow(u, v, z, r) { const [x, y] = xy(u, v); castShadow(x, y, z, r); }
  function tree(u, v, h, r, c, c2) { const [x, y] = xy(u, v); CL.tree(x, y, h, r, c, c2); }

  /* ---- pieces ---- */
  // a seat, long across the picture, its back at the far side
  function seat(u, v, hw, back = true, c = [190, 138, 86]) {
    const L = [214, 164, 104];
    box(u, v, .36, .46, hw, .26, L, (s, t, z, face) => face === 'top' && ((t + .26) % .17) < .03 ? rampOf(c)[2] : 0);                    // the seat: planks
    if (back) {                                                                                                                         // the back: three slats with gaps, on uprights
      for (const z of [.58, .8, 1.02]) wall(u - hw, u + hw, v - .24, z, z + .15, (a, b) => shade(L, 2.6, a * 3, b * 9, .3));
      for (let du = -hw + .08; du <= hw - .05; du += (2 * hw - .16) / Math.max(2, Math.round(hw * 2 / 1.1))) box(u + du, v - .27, .46, 1.17, .045, .03, IRON);
    }
    for (const du of [-hw + .04, hw - .04]) { box(u + du, v - .02, .46, .74, .04, .04, IRON); box(u + du, v - .02, .74, .8, .06, .26, c); }   // arm rests
    for (const du of [-hw + .15, hw - .15]) box(u + du, v, 0, .36, .07, .22, IRON);
    for (let du = -hw; du <= hw; du += .3) shadow(u + du, v, .4, .3);
  }
  // a seat seen from its end: long down the picture (people on it face the left)
  function seatSide(u, v0, v1, c = [190, 138, 86]) {
    const v = (v0 + v1) / 2, hd = (v1 - v0) / 2;
    const L = [214, 164, 104];
    box(u, v, .36, .46, .26, hd, L, (s, t, z, face) => face === 'top' && ((s + .26) % .17) < .03 ? rampOf(c)[2] : 0);
    box(u + .24, v, .46, 1.12, .04, hd, L, (s, t, z, face) => (face === 'front' && (((z - .46) % .22) > .16)) ? rampOf(c)[1] : 0);        // its back, at the right
    box(u - .22, v + hd - .04, .46, .78, .26, .04, c);                                                                                  // the near arm rest
    for (const dv of [-hd + .15, hd - .15]) box(u, v + dv, 0, .36, .22, .07, IRON);
    for (let dv = -hd; dv <= hd; dv += .3) shadow(u, v + dv, .4, .3);
  }
  // a flower bed: a low stone rim, earth, flowers of the given colours
  function bed(u0, v0, u1, v1, cols = [[236, 80, 90], [250, 206, 70], [250, 250, 250]]) {
    const hw = (u1 - u0) / 2, hd = (v1 - v0) / 2;
    box(u0 + hw, v0 + hd, 0, .24, hw, hd, STONE, (s, t, z, face) => face === 'top' && Math.abs(s) < hw - .09 && Math.abs(t) < hd - .09 ? rgb(...EARTH) : 0);
    let k = 0;
    for (let u = u0 + .25; u <= u1 - .2; u += .34) for (let v = v0 + .22; v <= v1 - .15; v += .3) {
      const j = hash(k * 3, k * 7); k++;
      ball(u + (j - .5) * .12, v, .32, .13, [70, 130, 62]); ball(u + (j - .5) * .12, v + .02, .46, .085, cols[k % cols.length], 'smooth');
    }
  }
  // a low hedge along a line
  function hedge(u0, v0, u1, v1) {
    const n = Math.max(1, Math.round(Math.hypot(u1 - u0, v1 - v0) / .34));
    for (let k = 0; k <= n; k++) { const u = u0 + (u1 - u0) * k / n, v = v0 + (v1 - v0) * k / n; ball(u, v, .22, .32, k % 3 ? CL.LEAF : CL.LEAF_L); if (k % 2 === 0) shadow(u, v, .25, .3); }
  }
  // a street lamp of the square: an iron post, an arm, a lantern (lit when api.NIGHT)
  function lamp(u, v, h = 3.0) {
    post(u, v, 0, h, .06, IRON);
    box(u, v, 0, .16, .14, .14, IRON);
    const [x, y] = xy(u, v), on = api.NIGHT, G = on ? [255, 236, 150] : [226, 232, 226];
    for (let z = h; z <= h + .42; z += .03) for (let a = -.13; a <= .13; a += .03) for (let b = -.13; b <= .13; b += .03) {
      const edge = (Math.abs(a) > .1 && Math.abs(b) > .1) || z > h + .38 || z < h + .03;
      const col = edge ? rgb(...IRON) : rgb(...G);
      if (on && !edge) plotGlow(x + a, y + b, z, col); else plot(x + a, y + b, z, col);
    }
    box(u, v, h + .42, h + .5, .17, .17, IRON);
  }
  // paper flags on a string between two points (little triangles hanging), facing the camera
  function flags(u0, z0, u1, z1, v, sag = .18, cols = [[236, 80, 90], [250, 206, 70], [86, 160, 150], [250, 250, 250], [110, 150, 220]]) {
    wall(u0, u1, v, Math.min(z0, z1) - sag - .34, Math.max(z0, z1) + .04, (u, z) => {
      const t = (u - u0) / (u1 - u0), zs = z0 + (z1 - z0) * t - sag * 4 * t * (1 - t);
      if (Math.abs(z - zs) < .025) return rgb(90, 80, 70);
      const k = Math.floor(t * Math.max(3, Math.round((u1 - u0) / .3))), n = Math.max(3, Math.round((u1 - u0) / .3)), f = t * n - k, d = zs - z;
      if (d > 0 && d < .28 && Math.abs(f - .5) < .42 * (1 - d / .28)) return rgb(...cols[k % cols.length]);
      return 0;
    });
  }

  /* ---- far things, in the sky (screen space) ---- */
  // the square's clock tower, far off: its top with the clock, small and pale; (cx, by): the middle of its foot on the picture
  function farTower(cx, by, hgt = 44) {
    return (ix, iy) => {
      const dx = ix + .5 - cx, dy = by - (iy + .5);
      if (dy < 0) return 0;
      if (dy < hgt - 12) {
        if (Math.abs(dx) > 7) return 0;
        const cy = hgt - 22;
        if (Math.hypot(dx, dy - cy) < 4.6) return Math.hypot(dx, dy - cy) > 3.5 ? rgb(150, 120, 100) : ((Math.abs(dx) < .6 && dy - cy > -.5 && dy - cy < 3) || (Math.abs(dy - cy) < .6 && dx > -.5 && dx < 2.4)) ? rgb(70, 60, 60) : rgb(252, 250, 240);
        return dx > 4 ? rgb(214, 196, 170) : rgb(236, 222, 196);
      }
      if (dy < hgt - 10) return Math.abs(dx) < 8.5 ? rgb(206, 186, 160) : 0;
      const t = (dy - (hgt - 10)) / 10;
      return Math.abs(dx) < 8 * (1 - t) ? (dx > 0 ? rgb(176, 84, 66) : rgb(206, 104, 80)) : 0;
    };
  }
  // the sky by the hour, with far things in front of it. hora: manana, mediodia, tarde, ocaso, noche
  function sky(hora, ...far) {
    const base = CL.sky({ manana: 'manana', mediodia: 'manana', tarde: 'manana', ocaso: 'tarde', noche: 'noche' }[hora] || 'manana', null);
    return (ix, iy) => { for (const f of far) { const c = f && f(ix, iy); if (c) return c; } return base(ix, iy); };
  }
  // the light of the hour on everything drawn (call before skyFill)
  function light(hora) {
    const L = { tarde: [[1.0, .95, .86], [8, 3, -6]], ocaso: [[1.0, .88, .78], [14, 0, -10]], noche: [[.62, .62, .82], [-6, -4, 14]] }[hora];
    if (L) lightPass(L[0], L[1]);
  }
  return Object.assign(api, { A, uv, xy, P, STONE, STONE_D, WOOD, WOOD_D, IRON, CREAM, OCHRE, TILE, EARTH, WHITE, paving, grass, box, wall, flat, slope, lit, dim, up, post, ball, shadow, tree, seat, seatSide, bed, hedge, lamp, flags, farTower, sky, light });
})();
