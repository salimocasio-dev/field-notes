'use strict';
/* La fonda (place 8): what its four scene sets share (entrada, pedido, comida, cuenta).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, calle-base.js, plaza-base.js and this file.
   Laid out square to the picture, in u, v (plaza-base.js): u across, v down the picture (towards the camera), z up.
   An indoor set is a floor (v >= 0) and a back wall that faces the camera at v = 0, painted pixel by pixel: doors, windows and a hatch are
   holes or pictures in it. There are no side walls and no ceiling (in this camera a ceiling or a beam would hide whoever is under it).
   Tables are long across the picture; whoever sits at one sits along its FAR side, facing us, or at one of its ends.
   Everything that moves or changes is a sprite: people, the cat, the dog, plates, glasses, cloths of another colour, candles, coins. */
const FD = (() => {
  const CREAM = [246, 232, 204], GREEN = [70, 132, 122], GREEN_D = [50, 104, 98], WOOD = [156, 106, 64], WOOD_D = [108, 72, 46], WOOD_L = [198, 150, 98],
    CLOTH = [250, 246, 236], BRASS = [222, 178, 82], RED = [196, 60, 54];
  // the floor of the room: clay tiles, every other one a shade darker, pale joints
  function tiles(u, v, ix, iy) {
    const a = ((u + 60.25) % 1), b = ((v + 60) % 1);
    if (a < .05 || b < .09) return rgb(206, 178, 150);
    const cu = Math.floor(u + 60.25), cv = Math.floor(v + 60), n = hash(cu * 7, cv * 13) * 8;
    const c = ((cu + cv) & 1) ? [196, 112, 80] : [212, 130, 92];
    return rgb(c[0] - n, c[1] - n, c[2] - n);
  }
  // the floor of the terrace: boards that run down the picture
  function planks(u, v, ix, iy) {
    const a = ((u + 60) % .5) / .5, k = Math.floor((u + 60) / .5);
    if (a < .07) return rgb(104, 72, 50);
    const n = hash(k * 5, 3) * 14, j = (((v + k * .37 + 60) % 2.6) < .07) ? 18 : 0;
    return rgb(182 - n - j, 132 - n - j, 88 - n - j);
  }
  // the back wall's paint: boards to the height of a chair's back, a rail, plaster above. Returns a colour for (u, z)
  function paint(u, z, low = GREEN, high = CREAM) {
    if (z < .08) return rgb(...WOOD_D);
    if (z < .95) return ((u + 60) % .34 < .035) ? rgb(...GREEN_D.map((c, i) => low === GREEN ? c : low[i] - 22)) : shade(low, 2.2, u * 3, z * 2, .25);
    if (z < 1.03) return rgb(...WOOD);
    return shade(high, 2.5, u * 1.5, z * 1.5, .22);
  }
  const inside = (u, z, r) => u >= r[0] && u <= r[1] && z >= r[2] && z <= r[3];
  // a frame round a hole or a picture in the wall: true on the frame's own pixels
  const onFrame = (u, z, r, w = .07) => inside(u, z, [r[0] - w, r[1] + w, r[2] - (r[2] > .1 ? w : 0), r[3] + w]) && !inside(u, z, r);
  // what is seen through a door or a window, by the hour: 'ocaso' | 'noche' | 'tarde_noche'. (a, b) run 0 to 1 across and up the opening
  function outside(hora, a, b, ix, iy) {
    if (hora === 'ocaso') { if (b < .28) return rgb(150, 118, 110); if (b < .36) return rgb(96, 84, 96); const t = (b - .36) / .64; return rgb(250 - t * 90, 170 - t * 40, 120 + t * 70); }
    const deep = hora === 'tarde_noche';
    if (b < .28) return deep ? rgb(34, 36, 60) : rgb(52, 54, 84);
    if (b < .34) return deep ? rgb(22, 24, 44) : rgb(36, 38, 64);
    if (hash(ix * 7, iy * 13) < (deep ? .05 : .025)) return rgb(240, 240, 255);
    return deep ? rgb(16, 20, 52) : rgb(34, 44, 96);
  }
  // a wall lamp that glows (a small shade on a bracket), on the wall at v
  function sconce(u, v, z) {
    PZ.box(u, v + .06, z - .1, z - .04, .03, .06, WOOD_D);
    const [x, y] = PZ.xy(u, v + .12);
    for (let dz = 0; dz <= .22; dz += .03) for (let a = -.1; a <= .1; a += .03) plotGlow(x + a * .7, y - a * .7, z + dz, rgb(255, 232, 150));
  }
  // a table, long across the picture: its cloth hangs half way down. c: the cloth's colour
  function table(u, v, hw, hd = .45, c = CLOTH) {
    for (const [du, dv] of [[-hw + .1, -hd + .1], [hw - .1, -hd + .1], [-hw + .1, hd - .1], [hw - .1, hd - .1]]) PZ.post(u + du, v + dv, 0, .4, .045, WOOD_D);
    PZ.box(u, v, .36, .74, hw, hd, c, (s, t, z, face) => face === 'top' ? rgb(...c) : z < .42 ? rgb(...c.map(k => k - 44)) : rgb(...c.map(k => k - 18)));
    for (let du = -hw; du <= hw; du += .3) PZ.shadow(u + du, v, .5, .5);
  }
  // a chair at a table's far side: its back is behind whoever sits on it
  function chair(u, v) {
    PZ.box(u, v, .36, .44, .2, .2, WOOD_L);
    for (const du of [-.17, .17]) { PZ.post(u + du, v - .18, 0, 1.08, .028, WOOD); PZ.post(u + du, v + .16, 0, .36, .028, WOOD); }
    for (const z of [.66, .88]) PZ.wall(u - .17, u + .17, v - .18, z, z + .13, (a, b) => shade(WOOD_L, 2.5, a * 4, b * 8, .3));
  }
  // a chair at a table's end: side = -1 at the left end (its back at the left), 1 at the right end
  function chairEnd(u, v, side) {
    PZ.box(u, v, .36, .44, .2, .2, WOOD_L);
    PZ.box(u + side * .2, v, .44, 1.08, .025, .2, WOOD_L);
    for (const dv of [-.17, .17]) PZ.post(u - side * .16, v + dv, 0, .36, .028, WOOD);
  }
  // a set table with its chairs: seats = how many along the far side; ends = chairs at the ends too. Returns the seats' places [[u, v], ...]
  function setTable(u, v, hw, opt = {}) {
    const hd = opt.hd || .45, n = opt.seats || 2, out = [];
    for (let k = 0; k < n; k++) { const cu = u + (n === 1 ? 0 : (k / (n - 1) - .5) * (opt.span || (2 * hw - .9))); chair(cu, v - hd - .26); out.push([cu, v - hd - .26]); }
    if (opt.ends) { chairEnd(u - hw - .4, v, -1); chairEnd(u + hw + .4, v, 1); out.push([u - hw - .4, v], [u + hw + .4, v]); }
    table(u, v, hw, hd, opt.cloth || CLOTH);
    return out;
  }
  return { CREAM, GREEN, GREEN_D, WOOD, WOOD_D, WOOD_L, CLOTH, BRASS, RED, tiles, planks, paint, inside, onFrame, outside, sconce, table, chair, chairEnd, setTable };
})();
