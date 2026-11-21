'use strict';
/* La casa, un día entero (place 9): what its four scene sets share (cuarto, bano, sala_dia, noche).
   Each <id>-set.html sets PP_SCENE, loads pp-engine.js, mapa.js, set-kit.js, calle-base.js, plaza-base.js, fonda-base.js and this file.
   Indoor sets, as La fonda's (fonda-base.js): a floor (v >= 0) and a back wall that faces the camera at v = 0, painted pixel by pixel.
   No side walls, no ceiling. A bed stands with its head to the back wall and runs towards the camera, so that whoever lies in it is seen
   whole, head at the top; a sofa and an armchair face the camera. Everything that moves or changes is a sprite. */
const CS = (() => {
  const inside = FD.inside, onFrame = FD.onFrame;
  // a wooden floor: boards that run across the picture
  function boards(u, v, ix, iy, c = [202, 160, 112]) {
    const k = Math.floor((v + 60) / .46), a = ((v + 60) % .46) / .46;
    if (a < .1) return rgb(c[0] - 62, c[1] - 58, c[2] - 50);
    const n = hash(k * 5, 3) * 12, j = (((u + k * 1.37 + 60) % 3.1) < .05) ? 22 : 0;
    return rgb(c[0] - n - j, c[1] - n - j, c[2] - n - j);
  }
  // the wall's paint: a skirting board, a plain colour, a pale line near the top
  function paint(u, z, c = [232, 222, 196]) {
    if (z < .14) return rgb(250, 246, 236);
    if (z > 2.62 && z < 2.68) return rgb(...c.map(k => k - 26));
    return shade(c, 2.5, u * 1.5, z * 1.5, .18);
  }
  // white tiles with a coloured band (a bathroom's wall)
  function tiles(u, z, band = [96, 176, 190]) {
    if (((u + 60) % .34) < .03 || (z % .3) < .035) return rgb(196, 210, 216);
    if (z > 1.2 && z < 1.5) return rgb(...band);
    return rgb(244, 248, 248);
  }
  // what a window shows by the hour: alba | manana | tarde | noche. (a, b) run 0 to 1 across and up the pane
  function sky(hora, a, b, ix, iy) {
    if (hora === 'alba') return rgb(120 + b * 40, 130 + b * 30, 170 - b * 10 + (b < .3 ? 40 : 0));
    if (hora === 'manana') { if (Math.hypot((a - .72) * 30, (b - .68) * 22) < 5) return rgb(255, 240, 150); return rgb(150 + (1 - b) * 60, 206 + (1 - b) * 30, 250); }
    if (hora === 'tarde') { if (Math.hypot((a - .3) * 30, (b - .45) * 22) < 5.5) return rgb(255, 214, 120); return rgb(250 - b * 40, 196 - b * 20, 130 + b * 60); }
    if (Math.hypot((a - .66) * 30, (b - .64) * 22) < 5) return rgb(250, 250, 236);                                        // noche: the moon
    return (hash(ix * 7, iy * 13) < .04) ? rgb(240, 240, 255) : rgb(24, 30, 76);
  }
  // a window in the wall paint: returns a colour for (u, z) inside r = [u0, u1, z0, z1] or its frame, else 0
  function windowAt(u, z, r, hora) {
    if (onFrame(u, z, r, .08)) return rgb(250, 246, 236);
    if (!inside(u, z, r)) return 0;
    const a = (u - r[0]) / (r[1] - r[0]), b = (z - r[2]) / (r[3] - r[2]);
    if (Math.abs(a - .5) < .025 || Math.abs(b - .5) < .035) return rgb(250, 246, 236);
    return sky(hora, a, b, Math.round(u * 26), Math.round(z * 22.5));
  }
  // a round wall clock with no hands (the hands are sprites): colour for (u, z) or 0
  function clockAt(u, z, cu, cz) {
    const d = Math.hypot((u - cu) * 26, (z - cz) * 22.5);
    if (d > 7.5) return 0;
    if (d > 6) return rgb(120, 84, 56);
    for (let k = 0; k < 12; k++) { const an = k * Math.PI / 6; if (Math.hypot((u - cu) * 26 - Math.sin(an) * 4.6, (z - cz) * 22.5 - Math.cos(an) * 4.6) < .7) return rgb(70, 60, 60); }
    return rgb(252, 250, 240);
  }
  // a door in the wall paint: a leaf with two panels and a knob; open = a dark opening with a pale floor strip
  function doorAt(u, z, r, open, c = [176, 122, 76]) {
    if (onFrame(u, z, r, .08)) return rgb(250, 246, 236);
    if (!inside(u, z, r)) return 0;
    if (open) return z < .5 ? rgb(150, 124, 100) : rgb(84, 70, 70);
    const a = (u - r[0]) / (r[1] - r[0]), b = (z - r[2]) / (r[3] - r[2]);
    if (Math.hypot((a - .84) * (r[1] - r[0]) * 26, (b - .48) * (r[3] - r[2]) * 22.5) < 1.5) return rgb(240, 206, 110);
    if (a > .14 && a < .86 && ((b > .08 && b < .44) || (b > .54 && b < .92))) return rgb(...c.map(k => k + 16));
    return rgb(...c);
  }
  // a bed: its head to the wall at v0, its foot at v1; whoever lies in it has his head on the pillow, at the top
  function bed(u, v0, v1, hw, c = [110, 150, 220]) {
    const mid = (v0 + v1) / 2, hd = (v1 - v0) / 2, W1 = [176, 122, 76], SH = [250, 248, 240];
    PZ.wall(u - hw, u + hw, v0 + .02, 0, 1.15, (a, b) => (Math.abs(a - u) > hw - .08 || b > 1.05) ? rgb(...W1.map(k => k - 30)) : shade(W1, 2.5, a * 3, b * 3, .2));   // the headboard
    PZ.box(u, mid + .06, 0, .34, hw, hd - .06, W1);
    PZ.box(u, mid + .06, .34, .5, hw - .04, hd - .08, SH, (s, t, z, face) => face === 'top' ? (t > -hd + .75 ? rgb(...c) : rgb(...SH)) : (face === 'front' ? rgb(...c.map(k => k - 30)) : 0));   // the mattress: a sheet at the head, the cover below
    PZ.box(u, v0 + .42, .5, .6, hw - .2, .22, [255, 255, 250]);                                                                                                       // the pillow
    for (let dv = -hd; dv <= hd; dv += .3) PZ.shadow(u, mid + dv, .3, hw);
  }
  // an armchair that faces the camera (its seat's top is z .44)
  function armchair(u, v, c = [176, 96, 80]) {
    const D = c.map(k => k - 34);
    PZ.box(u, v - .3, 0, 1.15, .46, .1, c, (s, t, z, face) => face === 'front' ? shade(c, 2.3, s * 3, z * 2, .2) : 0);     // the back
    PZ.box(u, v, 0, .44, .46, .3, c, (s, t, z, face) => face === 'top' ? rgb(...c.map(k => k + 22)) : 0);                 // the seat
    for (const s of [-1, 1]) PZ.box(u + s * .5, v - .02, 0, .7, .09, .32, D);                                             // the arms
    PZ.shadow(u, v, .4, .6);
  }
  // a sofa that faces the camera: seats = how many (each .95 wide); returns the seats' u
  function sofa(u, v, hw, c = [96, 150, 140]) {
    const D = c.map(k => k - 34);
    PZ.box(u, v - .32, 0, 1.1, hw, .1, c, (s, t, z, face) => face === 'front' ? shade(c, 2.3, s * 2, z * 2, .2) : 0);
    PZ.box(u, v, 0, .44, hw, .32, c, (s, t, z, face) => face === 'top' ? (Math.abs(((s + hw) % .98) - .02) < .03 ? rgb(...D) : rgb(...c.map(k => k + 22))) : 0);
    for (const s of [-1, 1]) PZ.box(u + s * (hw + .1), v - .02, 0, .72, .12, .34, D);
    for (let du = -hw; du <= hw; du += .3) PZ.shadow(u + du, v, .4, .5);
  }
  // a rug on the floor
  function rug(u0, v0, u1, v1, c = [196, 76, 70], c2 = [240, 206, 120]) {
    PZ.flat(u0, v0, u1, v1, .012, (u, v) => (u - u0 < .12 || u1 - u < .12 || v - v0 < .2 || v1 - v < .2) ? rgb(...c2) : shade(c, 3.2, u * 2, v, .1));
  }
  // lamps: lit ones glow
  function glowBox(u, v, z0, z1, hw, lit, c = [250, 232, 170]) {
    const [x, y] = PZ.xy(u, v);
    for (let z = z0; z <= z1; z += .03) { const w = hw * (.55 + .45 * (z1 - z) / (z1 - z0)); for (let a = -w; a <= w; a += .03) { const col = lit ? rgb(255, 236, 150) : rgb(...c.map(k => k - 70)); if (lit) plotGlow(x + a * .7, y - a * .7, z, col); else plot(x + a * .7, y - a * .7, z, col); } }
  }
  function lampStanding(u, v, lit) { PZ.box(u, v, 0, .06, .16, .16, [90, 80, 80]); PZ.post(u, v, 0, 1.62, .035, [90, 80, 80]); glowBox(u, v, 1.6, 2.05, .3, lit); }
  function lampSmall(u, v, z, lit) { PZ.box(u, v, z, z + .2, .07, .07, [150, 96, 70]); glowBox(u, v, z + .2, z + .52, .2, lit); }
  function lampWall(u, z, lit) { PZ.box(u, .07, z - .1, z - .04, .04, .07, [90, 80, 80]); glowBox(u, .13, z, z + .3, .16, lit); }
  return { boards, paint, tiles, sky, windowAt, clockAt, doorAt, bed, armchair, sofa, rug, lampStanding, lampSmall, lampWall, glowBox };
})();
