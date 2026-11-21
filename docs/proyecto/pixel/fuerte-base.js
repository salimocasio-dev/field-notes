'use strict';
/* El fuerte (place 10): what its four scene sets share (subida, musica, regalos, muralla).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, calle-base.js, plaza-base.js, fonda-base.js and this file.
   Laid out square to the picture, in u, v (plaza-base.js). The fort is old stone, the colour of sand: a wall that faces the camera is a
   plane v = const painted pixel by pixel; its top has battlements (the sky shows between them); a gate or an arch is a hole with a
   second plane painted behind it. Everything that moves or changes is a sprite: the flag, the paper lanterns, the curtain, people. */
const FT = (() => {
  const STONE = [214, 186, 140], STONE_D = [166, 140, 106], STONE_L = [234, 212, 170], MOSS = [150, 150, 104], IRON = [60, 64, 76];
  // the fort's masonry: big blocks in courses, a darker foot, stains
  function stone(u, z, c = STONE) {
    const row = Math.floor((z + 9) / .36), off = (row & 1) * .42, a = ((u + 60 + off) % .84) / .84, b = ((z + 9) % .36) / .36;
    if (a < .04 || b < .1) return rgb(c[0] - 44, c[1] - 42, c[2] - 38);
    const k = Math.floor((u + 60 + off) / .84), n = hash(k * 7, row * 13) * 18, st = noise(u * .8 + 3, z * 1.1) > .62 ? 16 : 0, foot = z < .3 ? 22 : 0;
    if (z < .22 && noise(u * 2.2, 5) > .58) return rgb(...MOSS);
    return rgb(c[0] - n - st - foot, c[1] - n - st - foot, c[2] - n - st - foot);
  }
  // battlements: true where the wall is solid at (u, z) when its top is z1 (merlons .52 wide, gaps .38, .34 high)
  const solid = (u, z, z1) => z <= z1 - .34 || ((u + 60.26) % .9) < .52;
  // an opening with a round top: r = [u0, u1, z0, z1]
  function inArch(u, z, r, grow = 0) {
    const am = (r[0] + r[1]) / 2, ah = (r[1] - r[0]) / 2 + grow, zs = r[3] - (r[1] - r[0]) / 2 * .7;
    return u > r[0] - grow && u < r[1] + grow && z >= r[2] && (z < zs || Math.hypot((u - am) / ah, (z - zs) / ((r[1] - r[0]) / 2 * .7 + grow)) < 1);
  }
  // an arch's stones: the ring of paler blocks round an opening
  const archRing = (u, z, r) => !inArch(u, z, r) && inArch(u, z, r, .16) ? (((Math.atan2(z - (r[3] - (r[1] - r[0]) * .35), u - (r[0] + r[1]) / 2) * 5 + 40) % 1) < .12 ? rgb(...STONE_D) : rgb(...STONE_L)) : 0;
  // flagstones: the paving of the fort's yard and of the wall's walk
  function flags(u, v, ix, iy, c = [196, 180, 152]) {
    const row = Math.floor((v + 60) / .9), off = (row & 1) * .6, a = ((u + 60 + off) % 1.2) / 1.2, b = ((v + 60) % .9) / .9;
    if (a < .035 || b < .09) return rgb(c[0] - 46, c[1] - 44, c[2] - 40);
    const n = hash(Math.floor((u + 60 + off) / 1.2) * 5, row * 11) * 14, sp = hash(ix, iy) < .04 ? 10 : 0;
    return rgb(c[0] - n - sp, c[1] - n - sp, c[2] - n - sp);
  }
  const grass = (u, v, ix, iy) => PZ.grass(u, v, ix, iy);
  // a path of pale stone on the grass: true inside it (it widens a little towards the camera)
  const onPath = (u, v, mid = 0, hw = .62) => Math.abs(u - mid) < hw + v * .035 + (noise(v * 1.3, u > mid ? 2 : 7) - .5) * .12;
  function pathStone(u, v, ix, iy) { const n = hash(Math.floor(u * 2.2 + 40), Math.floor(v * 1.6 + 40)) * 16; return (((u * 2.2 + 40) % 1) < .08 || ((v * 1.6 + 40) % 1) < .12) ? rgb(206, 190, 160) : rgb(240 - n, 228 - n, 200 - n); }
  // the night sky, in screen pixels: a moon, small stars; hz = the horizon's row (below it the sea, with the moon's road on it)
  function night(ix, iy, hz, moon = [186, 26, 10], low = false) {
    if (iy >= hz) {
      const d = iy - hz, road = Math.abs(ix - moon[0]) < 3 + d * .55 && hash(ix * 3, iy * 5) < .5 - d * .012;
      if (road) return rgb(214, 220, 240);
      return (hash(ix * 5, iy * 9) < .06) ? rgb(70, 96, 150) : rgb(24 + d * .5, 40 + d * .6, 92 + d * .5);
    }
    const dm = Math.hypot(ix + .5 - moon[0], iy + .5 - moon[1]);
    if (dm < moon[2]) return (Math.hypot(ix - moon[0] + 3, iy - moon[1] + 3) < 2.6 || Math.hypot(ix - moon[0] - 3.5, iy - moon[1] - 2) < 2) ? rgb(216, 220, 228) : (low ? rgb(255, 236, 190) : rgb(250, 250, 244));
    if (dm < moon[2] + 3 && bayerAt(ix, iy) < .5) return rgb(70, 78, 130);
    if (hash(ix * 7, iy * 13) < .014 && iy < hz - 4) return hash(ix, iy) < .5 ? rgb(250, 250, 255) : rgb(180, 190, 236);
    const t = clamp(iy / Math.max(1, hz), 0, 1);
    return rgb(16 + t * 30, 22 + t * 34, 62 + t * 54);
  }
  // the late afternoon and the evening sky: hora tarde | ocaso; hz as above (below it the sea)
  function day(hora, ix, iy, hz) {
    const t = clamp(iy / Math.max(1, hz), 0, 1), dth = (bayerAt(ix, iy) - .5) * .08, k = clamp(t + dth, 0, 1);
    if (iy >= hz) { const d = iy - hz; return hora === 'ocaso' ? ((hash(ix * 5, iy * 9) < .08) ? rgb(250, 190, 130) : rgb(80 + d, 96 + d, 150)) : ((hash(ix * 5, iy * 9) < .07) ? rgb(206, 232, 250) : rgb(56 + d, 132 + d, 196)); }
    if (hora === 'ocaso') { if (Math.hypot(ix + .5 - 34, iy + .5 - (hz - 9)) < 8) return rgb(255, 214, 120); return rgb(110 + k * 140, 110 + k * 60, 170 - k * 40); }
    const cl = noise(ix * .05 + 4, iy * .11);
    if (cl > .7 && iy < hz - 10) return rgb(252, 244, 236);
    return rgb(110 + k * 110, 170 + k * 50, 240 - k * 10);
  }
  // an iron lantern fixed to a wall (lit at night): at (u, z) on the plane v
  function wallLamp(u, v, z, lit = true) {
    PZ.box(u, v + .07, z + .34, z + .4, .03, .07, IRON);
    const [x, y] = PZ.xy(u, v + .14);
    for (let dz = 0; dz <= .32; dz += .03) for (let a = -.1; a <= .1; a += .03) {
      const edge = Math.abs(a) > .075 || dz < .03 || dz > .29, col = edge ? rgb(...IRON) : (lit ? rgb(255, 232, 150) : rgb(200, 206, 200));
      if (lit && !edge) plotGlow(x + a * .7, y - a * .7, z + dz, col); else plot(x + a * .7, y - a * .7, z + dz, col);
    }
  }
  // a sentry box of stone: a small square tower with a domed top and a knob; on its front a door (door = its colour, or null) and
  // a small window (lit = a light in it). Its middle is (u, v); it is 2 * hw wide.
  function garita(u, v, door = null, lit = true, hw = .62, h = 1.75) {
    const hd = .5;
    PZ.box(u, v, 0, h, hw, hd, STONE, (s, t, z, face) => {
      if (face !== 'front') return face === 'top' ? rgb(...STONE_D) : stone(s + u + t * .3, z, STONE_D);
      if (door && Math.abs(s) < .46 && z < 1.18) {                                                             // the door: .92 wide, so that a head with plaits fits in it
        if (Math.abs(s) > .41 || z > 1.13) return rgb(...door.map(k => k - 60));
        if (Math.hypot((s - .3) * 26, (z - .6) * 22.5) < 1.4) return rgb(240, 206, 110);
        return ((s + .46) % .153) < .02 ? rgb(...door.map(k => k - 34)) : rgb(...door);
      }
      if (Math.abs(s) < .17 && z > 1.3 && z < 1.58) return (Math.abs(s) > .13 || z > 1.54 || z < 1.34) ? rgb(...STONE_D.map(k => k - 30)) : (lit ? rgb(255, 232, 150) : rgb(40, 44, 70));
      return stone(s + u, z);
    });
    PZ.box(u, v, h, h + .12, hw + .07, hd + .07, STONE_L);                                                     // the cornice
    cap(u, v, h + .12, hw - .08);
    for (let du = -hw; du <= hw; du += .3) PZ.shadow(u + du, v, .6, .55);
  }
  // a sentry box's top: a stepped dome (three rings, each smaller) and a knob
  function cap(u, v, z, r) {
    const [x, y] = PZ.xy(u, v), T = [236, 214, 176];
    drum(x, y, z, z + .2, r, STONE_L, () => rgb(...T));
    drum(x, y, z + .2, z + .38, r * .72, STONE_L, () => rgb(...T));
    drum(x, y, z + .38, z + .52, r * .42, STONE_L, () => rgb(...T));
    PZ.ball(u, v, z + .6, .08, [240, 206, 110], 'smooth');
  }
  // a party table, long across the picture: a white top with red squares, an apron that hangs nearly to the ground (top z .74)
  function table(u, v, hw, hd = .5, c = [214, 84, 74]) {
    for (const [du, dv] of [[-hw + .1, -hd + .1], [hw - .1, -hd + .1], [-hw + .1, hd - .1], [hw - .1, hd - .1]]) PZ.post(u + du, v + dv, 0, .7, .04, [120, 84, 52]);
    PZ.box(u, v, .16, .74, hw, hd, [250, 246, 236], (s, t, z, face) => {
      if (face === 'top') return ((Math.floor((s + 20) / .2) + Math.floor((t + 20) / .2)) & 1) ? rgb(...c.map(k => Math.min(255, k + 26))) : rgb(252, 250, 244);
      if (face === 'front') return z < .22 ? (((s + 20) % .2) < .1 ? 0 : rgb(...c)) : (z > .66 ? rgb(...c.map(k => k - 30)) : (((s + 20) % .4) < .2 ? rgb(...c) : rgb(244, 238, 226)));
      return rgb(...c.map(k => k - 40));
    });
    for (let du = -hw; du <= hw; du += .3) PZ.shadow(u + du, v, .4, hd + .1);
  }
  // a line (a cord) across the picture at v, from (u0, z0) to (u1, z1), sagging a little: for lanterns, a curtain, photos
  function cord(u0, u1, v, z0, z1 = z0, sag = .12, c = [70, 60, 60]) {
    const n = Math.ceil((u1 - u0) * 26);
    for (let k = 0; k <= n; k++) { const a = k / n, [x, y] = PZ.xy(u0 + (u1 - u0) * a, v); plot(x, y, z0 + (z1 - z0) * a - Math.sin(a * Math.PI) * sag, rgb(...c)); }
  }
  // a wooden stool
  function stool(u, v, h = .46, r = .22, c = [176, 122, 76], z0 = 0) {
    const [x, y] = PZ.xy(u, v);
    for (const [a, b] of [[-.13, -.13], [.13, -.13], [-.13, .13], [.13, .13]]) PZ.post(u + a, v + b, z0, z0 + h - .06, .03, c.map(k => k - 40));
    drum(x, y, z0 + h - .07, z0 + h, r, c);
    if (!z0) PZ.shadow(u, v, .3, r + .05);
  }
  // the yard's inner wall at v = 0, across the picture: stone, battlements, the sky over it; holes = arches (each [u0, u1, z0, z1])
  function yardWall(h = 2.6, holes = [], u0 = -4.7, u1 = 4.7) {
    PZ.flat(u0, -.6, u1, 0, h - .34, (u, v) => flags(u, v * 2, 0, 0, [176, 156, 124]));
    PZ.wall(u0, u1, 0, 0, h, (u, z) => {
      if (!solid(u, z, h)) return 0;
      for (const r of holes) { if (inArch(u, z, r)) return 0; const c = archRing(u, z, r); if (c) return c; }
      if (z > h - .44 && z < h - .36) return rgb(...STONE_L);
      return stone(u, z);
    });
  }
  // a string of small lights along a wall, at height z, on the plane v (every other one warm)
  function lights(u0, u1, v, z, sag = .1) {
    const n = Math.round((u1 - u0) / .42);
    cord(u0, u1, v, z, z, sag, [60, 56, 60]);
    for (let k = 0; k <= n; k++) { const a = k / n, [x, y] = PZ.xy(u0 + (u1 - u0) * a, v + .02), zz = z - Math.sin(a * Math.PI) * sag - .07; for (const [dx, dz] of [[0, 0], [.03, 0], [0, -.04], [.03, -.04]]) plotGlow(x + dx * .7, y - dx * .7, zz + dz, k % 2 ? rgb(255, 236, 150) : rgb(255, 176, 120)); }
  }
  return { STONE, STONE_D, STONE_L, IRON, stone, solid, inArch, archRing, flags, grass, onPath, pathStone, night, day, wallLamp, garita, cap, table, cord, stool, yardWall, lights };
})();
