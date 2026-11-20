'use strict';
/* Don Pepe's colmado, inside: one room on the Pixel Plays engine, shared by three scene sets of place 4
   (mostrador, estantes, caja). Each <id>-set.html sets PP_SCENE (its own origin) and OPT, loads pp-engine.js, mapa.js,
   set-kit.js and this file, then calls colmadoDentro(OPT) from its buildSet.
   The room (world units; S = 26): two walls meet at the far corner (0, 0). The back wall is y = 0 (it faces +y: lit) and
   carries the shelves; the left wall is x = 0 (it faces +x: in shade) and has the street door. The counter runs along the
   back wall, with don Pepe's aisle between them. Everything that moves (people, goods taken down, coins, bags) is a sprite.
   OPT:
     hora   'manana' | 'tarde'      what shows through the street door, and the patch of light on the floor
     atras  'shut' | 'open'         the back door (to the store room), at the right end of the back wall
     props  true                    stand-in goods on the shelves (for the readers' renders; the game draws them as sprites)
     nevera true                    the little freezer on the counter (story 38)
     escalera true                  the ladder against the shelves (estantes)
     caja   true                    the cash register at the right end of the counter (caja)
     vitrina true                   the shop window in the left wall, with its low table (estantes, caja) */
const CD = (() => {
  const RX1 = 9.6, RY1 = 9.2, WH = 3.3;                       // the room: floor to x, to y; wall height
  const CX0 = 1.3, CX1 = 6.2, CY0 = 2.0, CY1 = 2.75, CH = 1.0;   // the counter
  const SX0 = 1.5, SX1 = 6.5, SD = .36, SXM = 5.5;                          // the shelves: along the back wall, their depth
  const SZ = [1.3, 1.95, 2.6];                                  // the planks' heights
  const BD0 = .15, BD1 = 1.25, DH = 2.55;                        // the back door (x on the back wall), beside the corner: don Pepe's way to the store room
  const PD0 = 3.6, PD1 = 5.0;                                   // the street door (y on the left wall)
  const VW0 = 6.6, VW1 = 8.6, VZ0 = .9, VZ1 = 2.5;              // the shop window (y on the left wall)
  const WALL = [244, 222, 150], DADO = [86, 170, 160], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92], TOP = [224, 196, 150];
  const SILLA = [6.7, 4.0];                                     // the waiting chair, in front of the counter's right end
  const TILE = [[236, 224, 200], [214, 190, 160], [176, 150, 122]];
  const GOODS = [                                              // k, shelf (0 low, 1 middle), x: where each stands (sheet: spots estante.<k>)
    ['leche', 0, 1.95], ['pan', 0, 2.75], ['mantequilla', 0, 3.55], ['queso', 0, 4.35], ['cafe', 0, 5.1],
    ['arroz', 1, 2.2], ['azucar', 1, 3.1], ['jugo', 1, 4.0], ['habichuelas', 1, 4.9],
  ];
  const paneX = (at, b0, b1, z0, z1, fn) => { for (let b = b0; b <= b1; b += ST * .5) for (let z = z0; z <= z1; z += ST * .5) { const c = fn(b, z); if (c) plot(at, b, z, c); } };
  const band = (c, k) => rgb(c[0] * k, c[1] * k, c[2] * k);

  function floorAt(x, y, ix, iy, i) {
    if (x < 0 || y < 0 || x > RX1 || y > RY1) return 0;
    kinds[i] = KIND_ROAD;
    const ta = x / .62, tb = y / .62, ea = ta - Math.floor(ta), eb = tb - Math.floor(tb);
    if (ea < .06 || eb < .06) return rgb(...TILE[2]);
    return rgb(...TILE[(Math.floor(ta) + Math.floor(tb)) % 2 ? 1 : 0]);
  }

  function walls(o) {
    part('pared', () => {
      // the back wall, with the back door's hole; a painted dado along its foot
      wallY(0, 0, RX1, 0, WH, WALL, [[BD0, BD1, 0, DH]]);
      for (let a = 0; a <= RX1; a += ST) { if (a > BD0 && a < BD1) continue; for (let z = 0; z <= .9; z += ST) plot(a, .01, z, shade(DADO, z > .84 ? 1.4 : 2.4, a, z)); }
      // the left wall, with the street door's hole (and the window's)
      const holes = [[PD0, PD1, 0, DH]]; if (o.vitrina) holes.push([VW0, VW1, VZ0, VZ1]);
      for (let b = 0; b <= RY1; b += ST) {
        const hs = holes.filter(h => b > h[0] && b < h[1]);
        for (let z = 0; z <= WH; z += ST) {
          if (hs.some(h => z > h[2] && z < h[3])) continue;
          plot(0, b, z, shade(z <= .9 ? DADO : WALL, z <= .9 ? (z > .84 ? .6 : 1.3) : 1.3, b, z));
        }
      }
    });
    part('puerta_atras', () => {
      // the store room behind: dim
      if (o.atras === 'open') {
        for (let a = Math.max(.02, BD0 - .9); a <= BD1; a += ST) for (let z = 0; z <= DH - .5; z += ST) plot(a, -.9, z, rgb(58 - z * 8, 52 - z * 8, 60 - z * 6));
        for (let a = Math.max(.02, BD0 - .9); a <= BD1; a += ST) for (let b = -.9; b <= 0; b += ST) plot(a, b, 0, rgb(72, 56, 46));
      }
      reveal(0, BD0, BD1, 0, DH, .2, WALL);
      const F = rampOf(WOOD_L), Wd = rampOf(WOOD), w = BD1 - BD0;
      for (let z = 0; z <= DH + .12; z += ST * .5) for (let a = 0; a <= .12; a += ST * .5) { plot(BD0 - .12 + a, .03, z, F[2]); plot(BD1 + a, .03, z, F[2]); }
      for (let a = BD0 - .12; a <= BD1 + .12; a += ST * .5) for (let z = DH; z <= DH + .12; z += ST * .5) plot(a, .03, z, F[3]);
      const panel = (t, z) => { const u = t * w; return Wd[(u < .08 || u > w - .08 || z < .08 || z > DH - .08) ? 1 : (Math.abs(z - 1.25) < .05 ? 1 : 2)]; };
      if (o.atras === 'open') leaf(BD1, -.05, w, 0, DH, Math.PI + 1.3, (t, z) => panel(t, z));
      else paneY(-.05, BD0, BD1, 0, DH, (a, z) => panel((BD1 - a) / w, z));
    });
    part('puerta', () => {
      // the street, through the door: a plane outside the left wall
      const tarde = o.hora === 'tarde';
      const sky = tarde ? [[250, 176, 96], [252, 200, 120], [254, 224, 160]] : [[120, 186, 250], [162, 211, 255], [208, 234, 255]];
      paneX(-.5, PD0 - .5, PD1 + .1, 0, DH + .2, (b, z) => {
        if (z < 1.0) return rgb(...(tarde ? [214, 150, 110] : [186, 200, 196]));               // the house across the street
        if (z < 1.12) return rgb(...(tarde ? [176, 92, 70] : [176, 96, 80]));                  // its eaves
        return rgb(...sky[clamp(Math.floor((z - 1.12) / 1.5 * 3), 0, 2)]);
      });
      for (let a = -.5; a <= 0; a += ST) for (let b = PD0 - .5; b <= PD1 + .1; b += ST) plot(a, b, 0, rgb(...(tarde ? [206, 178, 150] : [190, 186, 176])));   // the pavement
      const F = rampOf(WOOD_L);
      for (let z = 0; z <= DH + .12; z += ST * .5) for (let b = 0; b <= .12; b += ST * .5) { plot(.03, PD0 - .12 + b, z, F[1]); plot(.03, PD1 + b, z, F[1]); }
      for (let b = PD0 - .12; b <= PD1 + .12; b += ST * .5) for (let z = DH; z <= DH + .12; z += ST * .5) plot(.03, b, z, F[2]);
      // the door leaf, open into the shop, flat against the wall towards the corner
      const Wd = rampOf(WOOD);
      paneX(.06, PD0 - (PD1 - PD0) - .1, PD0 - .14, 0, DH, (b, z) => Wd[(z < .08 || z > DH - .08 || Math.abs(z - 1.25) < .05) ? 0 : 1]);
    });
    if (o.vitrina) part('vitrina', () => {
      const tarde = o.hora === 'tarde';
      paneX(-.5, VW0 - .5, VW1 + .1, 0, DH + .2, (b, z) => z < 1.0 ? rgb(...(tarde ? [214, 150, 110] : [186, 200, 196])) : rgb(...(tarde ? [252, 200, 120] : [162, 211, 255])));
      const F = rampOf(WOOD_L);
      for (let b = VW0 - .1; b <= VW1 + .1; b += ST * .5) for (const z of [VZ0 - .1, VZ1]) for (let h = 0; h <= .1; h += ST * .5) plot(.03, b, z + h, F[2]);
      for (let z = VZ0 - .1; z <= VZ1 + .1; z += ST * .5) for (const b of [VW0 - .1, VW1, (VW0 + VW1) / 2 - .04]) for (let h = 0; h <= .08; h += ST * .5) plot(.03, b + h, z, F[2]);
      block(.05, VW0 + .1, 0, 1.05, VW1 - .1, VZ0 - .15, WOOD, TOP);   // the low table in the window
    });
  }

  function counter(o) {
    part('mostrador', () => {
      block(CX0, CY0, 0, CX1, CY1, CH - .07, WOOD);
      block(CX0 - .06, CY0 - .06, CH - .07, CX1 + .06, CY1 + .08, CH, TOP);
      // boards on its front, a darker foot
      for (let a = CX0; a <= CX1; a += ST * .7) for (let z = 0; z <= CH - .08; z += ST * .7) {
        const seam = ((a - CX0) % .5) < .04;
        if (seam || z < .1) plot(a, CY1 + .01, z, rampOf(WOOD)[z < .1 ? 0 : 1]);
      }
    });
    if (o.nevera) part('nevera', () => {
      const x0 = CX1 - 1.15, x1 = CX1 - .15, y0 = CY0 + .1, y1 = CY1 - .08, z0 = CH, z1 = CH + .42;
      block(x0, y0, z0, x1, y1, z1, [236, 240, 244], [176, 214, 232]);
      for (let a = x0 + .05; a <= x1 - .05; a += ST * .6) for (let b = y0 + .05; b <= y1 - .05; b += ST * .6) plot(a, b, z1 + .004, ((a * 9 + b * 5) % 1 < .12) ? rgb(250, 252, 255) : rgb(168, 208, 228));
    });
    if (o.caja) part('caja', () => {
      const x0 = CX1 - 1.05, x1 = CX1 - .2, y0 = CY0 + .08, y1 = CY1 - .1, z0 = CH;
      block(x0, y0, z0, x1, y1, z0 + .34, [120, 126, 134], [150, 156, 164]);             // the body
      block(x0 + .1, y0, z0 + .34, x1 - .1, y0 + .28, z0 + .7, [104, 110, 120], [140, 146, 154]);   // the head with its window
      paneY(y0 + .285, x0 + .16, x1 - .16, z0 + .42, z0 + .62, () => rgb(226, 240, 214));   // the amount window (numerals are sprites)
      for (let r = 0; r < 3; r++) for (let k = 0; k < 4; k++) block(x0 + .1 + k * .17, y0 + .36 + r * .1, z0 + .34, x0 + .2 + k * .17, y0 + .42 + r * .1, z0 + .38, [236, 232, 220]);
      block(x0 + .04, y1, z0 + .02, x1 - .04, y1 + .06, z0 + .2, [92, 98, 108]);          // the drawer's front
    });
  }

  function shelves(o) {
    part('estantes', () => {
      for (const x of [SX0, SXM, SX1]) block(x - .05, .02, 0, x + .05, SD, WH - .25, WOOD);
      for (const z of SZ) block(SX0, .02, z, SX1, SD, z + .06, WOOD_L, TOP);
      block(SX0, .02, 0, SX1, SD + .04, .5, WOOD);                                       // a low cupboard under them
    });
    // stock that never moves: the top shelf, and the right half of the others
    part('surtido', () => {
      const z2 = SZ[2] + .06, z1 = SZ[1] + .06, z0 = SZ[0] + .06;
      const cans = [[204, 60, 50], [70, 130, 190], [236, 190, 70], [90, 160, 96]];
      for (let k = 0; k < 16; k++) { const x = SX0 + .3 + k * .41; if (x > SX1 - .2) break; if (Math.abs(x - SXM) < .2) continue; drum(x, .2, z2, z2 + .3, .13, cans[k % 4]); }
      for (let k = 0; k < 5; k++) { const x = SXM + .3 + k * .42; if (x > SX1 - .2) break; block(x - .15, .06, z1, x + .15, .3, z1 + .36 + (k % 2) * .08, [[226, 150, 80], [150, 110, 170], [240, 232, 210]][k % 3]); }
      for (let k = 0; k < 5; k++) { const x = SXM + .3 + k * .42; if (x > SX1 - .2) break; drum(x, .2, z0, z0 + .42, .1, [[60, 110, 70], [120, 70, 40], [60, 110, 70]][k % 3]); sphere(x, .2, z0 + .47, .05, [200, 200, 190], 'solid'); }
    });
    if (o.props) part('generos', () => {
      for (const [k, s, x] of GOODS) standIn(k, x, .19, SZ[s] + .06);
    });
    if (o.escalera) part('escalera', () => {
      const x = 3.3, Wd = [176, 132, 80];
      for (const dx of [-.3, .3]) for (let t = 0; t <= 1; t += ST * .25) { const y = SD + .9 - t * .85, z = t * 2.9; for (let h = 0; h <= .08; h += ST * .5) plot(x + dx + h - .04, y, z, shade(Wd, 2.4, z, dx)); }
      for (let r = 1; r <= 6; r++) { const t = r / 7, y = SD + .9 - t * .85, z = t * 2.9; for (let a = x - .3; a <= x + .3; a += ST * .5) for (let h = 0; h <= .06; h += ST * .5) plot(a, y, z + h, shade(Wd, 3, a, z)); }
    });
  }
  // a stand-in for one of the nine things that are bought: the size and the colours its sprite has
  function standIn(k, x, y, z) {
    const B = (hw, h, c, top) => block(x - hw, y - .12, z, x + hw, y + .12, z + h, c, top || c);
    const stripe = (hw, z0, z1, c) => paneY(y + .125, x - hw, x + hw, z + z0, z + z1, () => rgb(...c));
    if (k === 'leche') { B(.15, .46, [244, 246, 250]); stripe(.15, .14, .28, [70, 120, 210]); }
    else if (k === 'pan') { B(.26, .2, [196, 132, 64], [226, 170, 96]); }
    else if (k === 'mantequilla') { B(.22, .13, [250, 222, 96], [255, 236, 140]); stripe(.22, 0, .05, [240, 240, 232]); }
    else if (k === 'queso') { B(.2, .26, [246, 176, 60], [252, 200, 90]); sphere(x - .05, y + .13, z + .15, .04, [214, 140, 40], 'solid'); }
    else if (k === 'cafe') { B(.15, .42, [150, 40, 40]); stripe(.15, .16, .26, [240, 200, 90]); }
    else if (k === 'arroz') { B(.19, .4, [240, 236, 222]); stripe(.19, .1, .22, [70, 150, 90]); }
    else if (k === 'azucar') { B(.17, .38, [150, 200, 240]); stripe(.17, .12, .24, [250, 250, 250]); }
    else if (k === 'jugo') { B(.14, .46, [246, 150, 40]); stripe(.14, .3, .4, [250, 240, 200]); }
    else if (k === 'habichuelas') { drum(x, y, z, z + .32, .15, [190, 50, 50]); paneY(y + .155, x - .1, x + .1, z + .1, z + .22, () => rgb(250, 236, 200)); }
  }

  function light(o) {
    // the sun through the street door: a lighter patch on the floor (longer and warmer in the afternoon)
    const tarde = o.hora === 'tarde', len = tarde ? 3.4 : 1.8;
    for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
      const i = iy * W + ix; if (!ground[i] || zb[i] !== groundZ[i]) continue;
      const g = unproject(ix + .5, iy + .5), t = g.x / len;
      if (g.x < .02 || t > 1 || g.y < PD0 + t * .5 || g.y > PD1 + t * 1.2) continue;
      const c = pix[i], r = c & 255, gg = (c >> 8) & 255, b = (c >> 16) & 255, k = tarde ? [1.1, 1.02, .86] : [1.08, 1.07, 1.0];
      pix[i] = rgb(Math.min(255, r * k[0] + 8), Math.min(255, gg * k[1] + 6), Math.min(255, b * k[2]));
    }
  }

  function chairs() {
    // the waiting chair, turned to the camera (as El balcón's small chair)
    part('silla', () => {
      const [x, y] = SILLA, TURN = -Math.PI / 4, hw = .4, hd = .28, Y = [226, 190, 96];
      const at = (s, u) => [x + Math.cos(TURN) * s - Math.sin(TURN) * u, y + Math.sin(TURN) * s + Math.cos(TURN) * u];
      const leg = (s, u, z1) => { const q = at(s, u); turnedBox(q[0], q[1], 0, z1, .05, .05, TURN, Y); };
      leg(-hw + .05, hd - .05, .44); leg(hw - .05, hd - .05, .44); leg(-hw + .05, -hd + .05, 1.0); leg(hw - .05, -hd + .05, 1.0);
      turnedBox(x, y, .38, .45, hw, hd, TURN, Y);
      for (const z of [.62, .86]) { const q = at(0, -hd + .05); turnedBox(q[0], q[1], z, z + .08, hw, .04, TURN, Y); }
    });
  }
  function build(o) {
    walls(o); shelves(o); counter(o); chairs();
    castShadow((CX0 + CX1) / 2, CY1 + .1, .5, .5, .5);
    for (let x = CX0 + .4; x <= CX1 - .2; x += .5) castShadow(x, CY1 - .1, .6, .45, .6);
  }
  return { RX1, RY1, WH, CX0, CX1, CY0, CY1, CH, SX0, SX1, SD, SZ, BD0, BD1, DH, PD0, PD1, VW0, VW1, VZ0, VZ1, GOODS, SILLA, floorAt, build, light, standIn };
})();
