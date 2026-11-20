'use strict';
/* Don Pepe's colmado, from the street: its front wall, door and awning, and the fruit and vegetable stand under the awning.
   Shared by two scene sets of place 4: frutas (the stand) and mostrador (donde=calle: the shop front, for story 36's first beat).
   Each <id>-set.html sets PP_SCENE (its own origin) and OPT, loads pp-engine.js, mapa.js, set-kit.js and this file.
   World (S = 26): the front wall is y = 0 and faces +y (lit); the pavement runs from it to y = PAVE; the street beyond.
   OPT:
     hora    'manana' | 'tarde'     the sky: a low yellow sun at the left, or a high orange one at the right
     puerta  'shut' | 'open'        the shop door
     camion  true                   don Pepe's truck at the kerb, at the left (story 44)
     muro    true                   the low wall at the right, where the rooster stands (mostrador, calle)
     puesto  true                   the stand, its bins, the scale, the guineos, the low crate and the post (false: only the awning's shade)
   Everything that moves is a sprite: people, the goat, the rooster, what is taken out of a bin, the scale's needle, coins. */
const CF = (() => {
  const WX0 = -3.4, WX1 = 11.0, WH = 3.5, DEEP = -3;             // the building: along x, its height, its depth behind the wall
  const D0 = 1.0, D1 = 2.3, DH = 2.55;                           // the door
  const AX0 = 3.7, AX1 = 8.7, AZ1 = 3.0, AZ0 = 2.78, AY = 1.0;   // the awning: at the wall (high) to its front edge (low). Short and high: from this camera a deep one hides the bins
  const TX0 = 4.0, TX1 = 8.4, TY0 = .95, TY1 = 2.0, TZ1 = 1.15, TZ0 = .78;   // the stand's slanted top: back (high) to front (low)
  const LY1 = 2.32, LZ = .7;                                     // the ledge along its front
  const PAVE = 4.3;                                              // the pavement's width
  const CRATE = [8.95, 1.25, 9.7, 1.95, .34], POST = [10.1, 1.6]; // the low crate; the goat's post
  const BINS = ['tomates', 'cebollas', 'papas', 'platanos', 'aguacates', 'pinas', 'limones'];
  const BW = (TX1 - TX0) / BINS.length;
  const PAINT = [240, 150, 116], TRIM = [86, 160, 150], POLE = [3.55, TY1 + .1], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92];
  const PRODUCE = { tomates: [[226, 60, 50], .1], cebollas: [[214, 170, 190], .1], papas: [[176, 132, 84], .1], platanos: [[110, 170, 70], .09], aguacates: [[52, 96, 56], .11], pinas: [[214, 150, 60], .16], limones: [[214, 220, 80], .08] };
  const tableZ = y => TZ1 - (clamp(y, TY0, TY1) - TY0) / (TY1 - TY0) * (TZ1 - TZ0);
  const binX = k => TX0 + BW * (BINS.indexOf(k) + .5);

  function groundAt(x, y, ix, iy, i, HZ) {
    if (iy + .5 < HZ) return 0;
    kinds[i] = KIND_ROAD;
    if (y <= PAVE) {                                             // the pavement: big slabs
      const ea = ((x + 20) % 1.1) / 1.1, eb = ((y + 20) % 1.1) / 1.1;
      return (ea < .04 || eb < .04) ? rgb(168, 160, 150) : toneOf(C.pave, .45 + hash(Math.floor((x + 20) / 1.1), Math.floor((y + 20) / 1.1)) * .3, ix, iy);
    }
    if (y <= PAVE + .22) return rgb(214, 208, 196);              // the kerb
    return rgb(...((hash(ix >> 1, iy >> 1) < .08) ? [112, 110, 116] : [98, 96, 104]));   // the street
  }

  function building(o) {
    part('colmado', () => {
      blockHoles(WX0, DEEP, 0, WX1, 0, WH, PAINT, [[D0, D1, 0, DH]]);
      for (let a = WX0; a <= WX1; a += ST) { if (a > D0 && a < D1) continue; for (let z = 0; z <= .7; z += ST) plot(a, .01, z, shade(TRIM, z > .64 ? 1.4 : 2.4, a, z)); }   // a painted foot
      for (let a = WX0; a <= WX1; a += ST) for (let z = WH - .3; z <= WH; z += ST) plot(a, .01, z, shade(TRIM, 2.6, a, z));   // a band under the roof
      // a small shuttered window at the left
      const F = rampOf([244, 240, 228]);
      paneY(.02, -2.3, -1.2, 1.2, 2.1, (a, z) => F[(Math.floor((z - 1.2) / .1) % 2) ? 3 : 2]);
      for (let a = -2.4; a <= -1.1; a += ST * .5) for (const z of [1.1, 2.1]) for (let h = 0; h <= .1; h += ST * .5) plot(a, .03, z + h, F[3]);
      // the sign over the door: a board with a picture (a basket of fruit), no words
      paneY(.03, D0 - .5, D1 + .5, DH + .2, DH + .85, (a, z) => { const u = (a - D0 + .5) / (D1 - D0 + 1), v = (z - DH - .2) / .65; if (u < .04 || u > .96 || v < .08 || v > .92) return rgb(120, 76, 44); const dx = (u - .5) * 3.2, dy = v - .42; if (dy < 0 && dy > -.3 && Math.abs(dx) < .62 + dy) return rgb(176, 124, 70); if (Math.hypot(dx + .3, dy - .12) < .2) return rgb(226, 60, 50); if (Math.hypot(dx - .05, dy - .2) < .2) return rgb(244, 200, 70); if (Math.hypot(dx - .36, dy - .1) < .18) return rgb(110, 170, 70); return rgb(250, 244, 226); });
    });
    part('puerta', () => {
      const w = D1 - D0, Wd = rampOf(WOOD), F = rampOf(WOOD_L);
      reveal(0, D0, D1, 0, DH, .2, PAINT);
      for (let a = D0 - .9; a <= D1; a += ST) for (let z = 0; z <= DH + .2; z += ST) plot(a, -1.0, z, z < .14 ? rgb(60, 44, 34) : rgb(84 - z * 10, 78 - z * 10, 70 - z * 8));   // the shop inside: dim
      for (let a = D0 - .9; a <= D1; a += ST) for (let b = -1.0; b <= 0; b += ST) plot(a, b, 0, rgb(120, 104, 88));
      for (let z = 0; z <= DH + .12; z += ST * .5) for (let a = 0; a <= .12; a += ST * .5) { plot(D0 - .12 + a, .03, z, F[2]); plot(D1 + a, .03, z, F[2]); }
      for (let a = D0 - .12; a <= D1 + .12; a += ST * .5) for (let z = DH; z <= DH + .12; z += ST * .5) plot(a, .03, z, F[3]);
      const panel = (t, z) => { const u = t * w, glass = u > .2 && u < w - .2 && z > 1.3 && z < DH - .25; return glass ? rgb(150, 200, 214) : Wd[(u < .08 || u > w - .08 || z < .08 || z > DH - .08) ? 1 : 2]; };
      if (o.puerta === 'open') leaf(D1, .02, w, 0, DH, .25, (t, z) => panel(t, z));     // swung out against the wall, to the right
      else paneY(-.05, D0, D1, 0, DH, (a, z) => panel((D1 - a) / w, z));
    });
    part('toldo', () => {
      // the awning: a slope of red and white stripes, a short skirt along its front edge, two thin posts
      for (let a = AX0; a <= AX1; a += ST * .7) for (let b = 0; b <= AY; b += ST * .7) { const z = AZ1 - b / AY * (AZ1 - AZ0), s = Math.floor((a - AX0) / .42) % 2; plot(a, b, z, shade(s ? [226, 60, 50] : [250, 246, 236], 3.2, a, b)); }
      for (let a = AX0; a <= AX1; a += ST * .7) for (let z = AZ0 - .22; z <= AZ0; z += ST * .7) { const s = Math.floor((a - AX0) / .42) % 2; plot(a, AY, z, shade(s ? [226, 60, 50] : [250, 246, 236], 2.2, a, z)); }
    });
  }

  function stand(o) {
    part('puesto', () => {
      // the body under the slanted top, its front boards, the ledge
      for (let a = TX0; a <= TX1; a += ST) for (let z = 0; z <= TZ0; z += ST) plot(a, TY1, z, shade(WOOD, ((a - TX0) % .5) < .04 ? 1.2 : 2.3, a, z));
      for (let b = TY0; b <= TY1; b += ST) for (let z = 0; z <= tableZ(b); z += ST) plot(TX1, b, z, shade(WOOD, 1.3, b, z));
      block(TX0 - .05, TY1, LZ - .08, TX1 + .05, LY1, LZ, WOOD_L, [224, 196, 150]);
      // the slanted top: a dark bed, the bins' rims
      for (let a = TX0; a <= TX1; a += ST * .7) for (let b = TY0; b <= TY1; b += ST * .7) {
        const u = (a - TX0) / BW, rim = (u - Math.floor(u)) < .07 || b < TY0 + .06 || b > TY1 - .06 || a > TX1 - .05;
        plot(a, b, tableZ(b), rim ? rampOf(WOOD_L)[3] : rgb(104, 72, 48));
      }
      for (let a = TX0; a <= TX1; a += ST) for (let z = TZ1; z <= TZ1 + .16; z += ST) plot(a, TY0, z, shade(WOOD_L, 2.4, a, z));   // the back board
    });
    for (const k of BINS) part(k, () => {
      const [c, r] = PRODUCE[k], x0 = binX(k) - BW / 2 + .12, x1 = binX(k) + BW / 2 - .1, step = r * 1.75;
      let n = 0;
      for (let b = TY0 + .16; b <= TY1 - .14; b += step) for (let a = x0; a <= x1; a += step) {
        const jx = (hash(n, 7) - .5) * r * .5, jy = (hash(n, 13) - .5) * r * .5, z = tableZ(b) + r * .8; n++;
        sphere(a + jx, b + jy, z, r, k === 'cebollas' && n % 3 === 0 ? [240, 226, 200] : c, 'solid');
        if (k === 'pinas') sphere(a + jx, b + jy - .05, z + r * 1.1, r * .55, [70, 140, 70], 'rough');
        if (k === 'tomates' && n % 2) sphere(a + jx, b + jy, z + r * .75, r * .28, [70, 140, 70], 'solid');
      }
    });
    part('pesa', () => {
      // the scale: on a pole at the stand's left end, hanging from its arm in the clear; a round white dial (its two marks and the
      // needle are sprites), a pan under it
      const [px, py] = POLE, x = px - .62, y = py;
      block(px - .04, py - .04, 0, px + .04, py + .04, 2.25, [120, 120, 130]);
      for (let a = x; a <= px; a += ST * .5) for (let h = 0; h <= .05; h += ST * .5) plot(a, y, 2.2 + h, rgb(120, 120, 130));
      for (let z = 1.86; z <= 2.2; z += ST * .5) plot(x, y, z, rgb(90, 90, 100));
      for (let a = -.26; a <= .26; a += ST * .4) for (let z = -.26; z <= .26; z += ST * .4) { const d = Math.hypot(a, z); if (d <= .26) plot(x + a, y + .01, 1.6 + z, d > .21 ? rgb(90, 90, 100) : rgb(250, 248, 240)); }
      for (let z = 1.1; z <= 1.34; z += ST * .5) for (const dx of [-.22, .22]) plot(x + dx * (1 - (z - 1.1) / .24 * .85), y, z, rgb(90, 90, 100));
      drum(x, y - .02, 1.04, 1.1, .26, [176, 180, 190]);
    });
    part('guineos', () => {
      const x = 6.1, y = AY - .02, zt = AZ0 - .22;
      for (let z = zt - .22; z <= zt; z += ST * .5) plot(x, y, z, rgb(120, 92, 50));
      for (let k = 0; k < 5; k++) { sphere(x - .18 + k * .09, y, zt - .28 - Math.abs(k - 2) * .03, .075, [244, 206, 70], 'solid'); sphere(x - .15 + k * .075, y + .01, zt - .43 - Math.abs(k - 2) * .02, .07, [236, 196, 60], 'solid'); }
    });
    part('cajon', () => {
      const [x0, y0, x1, y1, h] = CRATE;
      block(x0, y0, 0, x1, y1, h, WOOD_L, [214, 176, 120]);
      for (let a = x0; a <= x1; a += ST) for (const z of [h * .33, h * .66]) plot(a, y1 + .01, z, rampOf(WOOD)[1]);
    });
    part('poste', () => block(POST[0] - .05, POST[1] - .05, 0, POST[0] + .05, POST[1] + .05, 1.15, WOOD));
  }

  function extras(o) {
    if (o.muro) part('muro', () => {
      block(WX1 + .3, .2, 0, WX1 + 3.2, .55, 1.05, [226, 220, 204], [240, 236, 222]);
      for (let k = 0; k < 4; k++) bush(WX1 + .8 + k * .7, -.3, .5, k % 2 ? C.leaf : [96, 150, 70]);
    });
    if (o.camion) part('camion', () => {
      const x0 = 3.3, x1 = 6.5, y0 = PAVE + .7, y1 = PAVE + 2.1, B = [70, 120, 190];
      block(x0, y0, .45, x0 + 1.9, y1, .9, B);                                  // the bed
      block(x0 + .08, y0 + .08, .9, x0 + 1.82, y1 - .08, .92, [60, 50, 44]);
      block(x0 + 1.9, y0, .45, x1, y1, 1.55, B, [96, 146, 210]);                 // the cab
      paneY(y1 + .01, x0 + 2.05, x1 - .12, 1.0, 1.45, () => rgb(170, 214, 232));
      for (const x of [x0 + .5, x1 - .55]) drum(x, y1 - .1, 0, .46, .26, [44, 42, 48]);
      for (let k = 0; k < 3; k++) block(x0 + .15 + k * .55, y0 + .2, .92, x0 + .6 + k * .55, y1 - .2, 1.2, WOOD_L, [206, 230, 180]);   // crates on the bed
    });
  }

  // the sky, screen space: bands, a sun, far roofs
  function sky(o, HZ) {
    const tarde = o.hora === 'tarde';
    const bands = tarde ? [[236, 120, 70], [246, 156, 84], [250, 190, 110], [252, 214, 150], [254, 234, 190]] : [[80, 150, 236], [110, 176, 246], [150, 200, 252], [190, 222, 255], [226, 240, 255]];
    const sun = tarde ? [W - 44, 20, 11, [[250, 150, 60], [254, 190, 90], [255, 226, 150]]] : [26, HZ - 10, 13, [[250, 206, 90], [254, 230, 130], [255, 246, 196]]];
    return (ix, iy) => skyDisc(sun[0], sun[1], sun[2], sun[3], ix, iy) || skyHills(HZ, tarde ? [[176, 120, 110], [206, 150, 130], [150, 100, 100]] : [[116, 170, 172], [156, 200, 198], [94, 150, 156]], tarde ? [[120, 110, 90], [160, 140, 110], [100, 90, 80]] : [[78, 150, 104], [124, 196, 132], [62, 130, 90]], ix, iy) || skyBands(bands, 0, HZ, ix, iy);
  }

  function build(o) {
    building(o);
    if (o.puesto !== false) stand(o);
    extras(o);
    // shade: under the awning, beside the building's right end
    for (let x = AX0 + .3; x <= AX1 - .2; x += .45) castShadow(x, .5, 1.0, .5, .6);
    if (o.puesto !== false) { castShadow((CRATE[0] + CRATE[2]) / 2, CRATE[3], .2, .4); }
  }
  return { WX0, WX1, WH, D0, D1, DH, AX0, AX1, AZ0, AZ1, AY, TX0, TX1, TY0, TY1, TZ0, TZ1, LY1, LZ, PAVE, CRATE, POST, BINS, BW, POLE, binX, tableZ, groundAt, build, sky };
})();
