'use strict';
/* Don Pepe's colmado, from the street: its front wall, door and awning, and the fruit and vegetable stand under the awning.
   Shared by two scene sets of place 4: frutas (the stand) and mostrador (donde=calle: the shop front, for story 36's first beat).
   Each <id>-set.html sets PP_SCENE (its own origin), loads pp-engine.js, mapa.js, set-kit.js and this file, and asks CF.skyPlan(o) for the
   horizon row and the sun's place (they depend on where the roof's far edge falls in that picture).
   World (S = 26): the front wall is y = 0 and faces +y (lit); the pavement runs from it to y = PAVE; the street beyond.
   OPT:
     hora    'manana' | 'tarde'     the sky: a pale sun half risen behind the far hills in a blue sky, or a whole, higher one in an orange sky
     puerta  'shut' | 'open'        the shop door
     carro   true                   don Pepe's hand cart on the pavement, left of the scale (story 44)
     puesto  true                   the stand, its bins, the scale, the guineos, the low crate and the post (false: only the awning's shade)
     aguja   '' | '0' | 'medio' | 'libra'   a red needle on the scale's dial, at 12, 3 or 6 o'clock ('' : none; in the game the needle is a sprite)
     solX    the sun's x in the picture, in pixels (default W - 44)
   Everything that moves is a sprite: people, the goat, the rooster, what is taken out of a bin, the scale's needle, coins.
   Exports PESA_DIAL ({x, y, z}: the world centre of the scale's dial, r: its radius in picture pixels; the dial faces the camera, so its
   centre on the picture is project(x, y, z)) and PESA_PLATO ({x, y, z}: the world centre of the pan's top, r: its radius in world units). */
const CF = (() => {
  const WX0 = -3.4, WX1 = 11.0, WH = 3.5, DEEP = -2.2;           // the building: along x, its height, its depth behind the wall
  const D0 = 1.0, D1 = 2.3, DH = 2.55;                           // the door
  const AX0 = 3.7, AX1 = 8.7, AZ1 = 3.0, AZ0 = 2.78, AY = 1.0;   // the awning: at the wall (high) to its front edge (low). Short and high: from this camera a deep one hides the bins
  const TX0 = 4.0, TX1 = 8.4, TY0 = .95, TY1 = 2.0, TZ1 = 1.15, TZ0 = .78;   // the stand's slanted top: back (high) to front (low)
  const LEG = .2;                                                // the stand's legs: the body stands this high above the pavement
  const LY1 = 2.32, LZ = .7;                                     // the ledge along its front
  const PAVE = 4.3, LINE_Y = 5.9;                                // the pavement's width; the street's painted line
  const CRATE = [8.95, 1.25, 9.7, 1.95, .34], POST = [10.1, 1.6]; // the low crate; the goat's post
  const WIN = [-1.9, -.8, 1.2, 2.1];                             // the shuttered window: x0, x1, z0, z1
  const POT = [.28, .5];                                         // the flower pot left of the door
  const CART = [3.1, 3.5];                                       // the hand cart: the middle of its bed
  const BINS = ['tomates', 'cebollas', 'papas', 'platanos', 'aguacates', 'pinas', 'limones'];
  const BW = (TX1 - TX0) / BINS.length;
  const PAINT = [240, 150, 116], TRIM = [86, 160, 150], POLE = [3.55, TY1 + .1], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92], WOOD_D = [92, 62, 40], LEGC = [48, 34, 28];
  const METAL = [120, 120, 130], LEAF = [74, 134, 62];
  const PRODUCE = { tomates: [[226, 60, 50], .1], cebollas: [[214, 170, 190], .1], papas: [[176, 132, 84], .1] };
  const tableZ = y => TZ1 - (clamp(y, TY0, TY1) - TY0) / (TY1 - TY0) * (TZ1 - TZ0);
  const binX = k => TX0 + BW * (BINS.indexOf(k) + .5);
  const PESA_DIAL = { x: POLE[0] - .8, y: POLE[1], z: 1.7, r: 7.5 };        // the dial: a disc turned to the camera
  const PESA_PLATO = { x: POLE[0] - .8, y: POLE[1], z: .72, r: .27 };       // the pan hangs straight under it

  // the big flat faces are sampled a little under a pixel: the engine's ST is a third of one, and the walls were most of the bake
  const PX = .04, PZ = .035, PA = .03, PP = .024;
  // (a surface is painted in ONE pass: a second layer a hair in front of it loses pixels to the first wherever the depth varies inside a pixel)
  function wall(at, a0, a1, z0, z1, fn, holes) {                     // a face of the wall's kind, facing +y; fn(a, z) the colour; rectangular holes [a0, a1, z0, z1]
    for (let a = a0; a <= a1; a += PX) {
      const hs = holes.filter(h => a > h[0] && a < h[1]);
      for (let z = z0; z <= z1; z += PZ) { if (hs.some(h => z > h[2] && z < h[3])) continue; plot(a, at, z, fn(a, z)); }
    }
  }
  function box2(x0, y0, z0, x1, y1, z1, c, topFn) {                  // block() at the coarse step, its top painted by topFn(a, b) when that gives a colour
    for (let a = x0; a <= x1; a += PA) for (let b = y0; b <= y1; b += PA) plot(a, b, z1, (topFn && topFn(a, b)) || shade(c, 3.4, a, b));
    for (let a = x0; a <= x1; a += PX) for (let z = z0; z <= z1; z += PZ) plot(a, y1, z, shade(c, 2.4, a, z));
    for (let b = y0; b <= y1; b += PX) for (let z = z0; z <= z1; z += PZ) plot(x1, b, z, shade(c, 1.3, b, z));
  }
  function pane(at, a0, a1, z0, z1, fn) {                             // a painted plane facing +y: fn(a, z) gives a colour or 0
    for (let a = a0; a <= a1; a += PP) for (let z = z0; z <= z1; z += PP) { const col = fn(a, z); if (col) plot(a, at, z, col); }
  }
  function groundAt(x, y, ix, iy, i, HZ) {
    if (iy + .5 < HZ) return 0;
    kinds[i] = KIND_ROAD;
    if (y < DEEP - .3) return rgb(...GRASS[clamp(Math.floor((.3 + noise(x * .7, y * .7) * .7 + (hash(ix, iy) - .5) * .3) * 4), 0, 3)]);   // the lot behind the building
    if (y <= PAVE) {                                             // the pavement: big slabs
      const ea = ((x + 20) % 1.1) / 1.1, eb = ((y + 20) % 1.1) / 1.1;
      return (ea < .04 || eb < .04) ? rgb(168, 160, 150) : toneOf(C.pave, .45 + hash(Math.floor((x + 20) / 1.1), Math.floor((y + 20) / 1.1)) * .3, ix, iy);
    }
    if (y <= PAVE + .22) return rgb(214, 208, 196);              // the kerb
    if (Math.abs(y - LINE_Y) < .075 && ((x + 40) % 1.6) < 1.0) return rgb(232, 218, 150);   // a painted dashed line down the street
    return rgb(...((hash(ix >> 1, iy >> 1) < .08) ? [112, 110, 116] : [98, 96, 104]));      // the street
  }

  function building(o) {
    part('colmado', () => {
      // the wall, its roof and its end; holes where the door, the window and the sign are, each painted flush by its own pass
      const PAINT_ = (a, z) => z < .7 ? shade(TRIM, z > .64 ? 1.4 : 2.4, a, z) : z > WH - .3 ? shade(TRIM, 2.6, a, z) : shade(PAINT, 2.4, a, z);   // a painted foot and a band under the roof
      const hWin = [WIN[0] - .1, WIN[1] + .1, WIN[2] - .1, WIN[3] + .1], hSign = [D0 - .5, D1 + .5, DH + .2, DH + .85], hDoor = [D0 - .12, D1 + .12, 0, DH + .12];
      for (let a = WX0; a <= WX1; a += PA) for (let b = DEEP; b <= 0; b += PA) plot(a, b, WH, shade(PAINT, 3.4, a, b));
      wall(0, WX0, WX1, 0, WH, PAINT_, [hDoor, hWin, hSign]);
      for (let b = DEEP; b <= 0; b += PA) for (let z = 0; z <= WH; z += PZ) plot(WX1, b, z, shade(PAINT, 1.3, b, z));
      // a small shuttered window at the left
      const F = rampOf([244, 240, 228]);
      pane(0, hWin[0], hWin[1], hWin[2], hWin[3], (a, z) => (z < WIN[2] || z > WIN[3]) ? F[3] : F[(Math.floor((z - WIN[2]) / .1) % 2) ? 3 : 2]);
      // the sign over the door: a board with a picture (a basket of fruit), no words
      pane(0, hSign[0], hSign[1], hSign[2], hSign[3], (a, z) => { const u = (a - D0 + .5) / (D1 - D0 + 1), v = (z - DH - .2) / .65; if (u < .04 || u > .96 || v < .08 || v > .92) return rgb(120, 76, 44); const dx = (u - .5) * 3.2, dy = v - .42; if (dy < 0 && dy > -.3 && Math.abs(dx) < .62 + dy) return rgb(176, 124, 70); if (Math.hypot(dx + .3, dy - .12) < .2) return rgb(226, 60, 50); if (Math.hypot(dx - .05, dy - .2) < .2) return rgb(244, 200, 70); if (Math.hypot(dx - .36, dy - .1) < .18) return rgb(110, 170, 70); return rgb(250, 244, 226); });
    });
    part('puerta', () => {
      const w = D1 - D0, Wd = rampOf(WOOD), F = rampOf(WOOD_L);
      reveal(0, D0, D1, 0, DH, .2, PAINT);
      pane(-1.0, D0 - .9, D1, 0, DH + .2, (a, z) => z < .14 ? rgb(60, 44, 34) : rgb(84 - z * 10, 78 - z * 10, 70 - z * 8));   // the shop inside: dim
      for (let a = D0 - .9; a <= D1; a += PA) for (let b = -1.0; b <= 0; b += PA) plot(a, b, 0, rgb(120, 104, 88));
      pane(0, D0 - .12, D1 + .12, 0, DH + .12, (a, z) => (a > D0 && a < D1 && z < DH) ? 0 : (z > DH ? F[3] : F[2]));       // the frame: two jambs and a lintel
      // the leaf: two panels and a glass with two light streaks across it
      const panel = (t, z) => {
        const u = t * w, glass = u > .2 && u < w - .2 && z > 1.3 && z < DH - .25;
        if (!glass) return Wd[(u < .08 || u > w - .08 || z < .08 || z > DH - .08) ? 1 : 2];
        const s = (u * 1.5 + z * 1.0) % 1.1;                                // diagonal streaks of reflected light
        return s < .2 ? rgb(232, 246, 250) : (s > .32 && s < .4) ? rgb(206, 232, 240) : rgb(150, 200, 214);
      };
      if (o.puerta === 'open') {                                             // swung out against the wall, to the right
        const ang = .25, dx = Math.cos(ang), dy = Math.sin(ang);
        for (let t = 0; t <= 1; t += PP / w) for (let z = 0; z <= DH; z += PP) plot(D1 + dx * w * t, .02 + dy * w * t, z, panel(t, z));
      } else pane(-.05, D0, D1, 0, DH, (a, z) => panel((D1 - a) / w, z));
    });
    part('toldo', () => {
      // the awning: a slope of red and white stripes, a short skirt along its front edge
      for (let a = AX0; a <= AX1; a += PA) for (let b = 0; b <= AY; b += PA) { const z = AZ1 - b / AY * (AZ1 - AZ0), s = Math.floor((a - AX0) / .42) % 2; plot(a, b, z, shade(s ? [226, 60, 50] : [250, 246, 236], 3.2, a, b)); }
      for (let a = AX0; a <= AX1; a += PX) for (let z = AZ0 - .22; z <= AZ0; z += PZ) { const s = Math.floor((a - AX0) / .42) % 2; plot(a, AY, z, shade(s ? [226, 60, 50] : [250, 246, 236], 2.2, a, z)); }
    });
    // the flower box under the shuttered window, and its flowers (as the house's in El balcón)
    const bx0 = WIN[0] - .12, bx1 = WIN[1] + .12, bz0 = WIN[2] - .34, bz1 = WIN[2] - .1;
    part('jardinera', () => {
      box2(bx0, .02, bz0, bx1, .3, bz1, WOOD, (a, b) => (a > bx0 + .04 && a < bx1 - .04 && b > .06 && b < .26) ? rgb(96, 66, 44) : 0);
    });
    part('flores', () => {
      const FL = [[255, 143, 184], [255, 224, 112], [244, 88, 74], [250, 244, 226]], n = 9;
      for (let k = 0; k < n; k++) sphere(bx0 + .1 + k * (bx1 - bx0 - .2) / (n - 1), .17, bz1 + .01 + (k % 2) * .04, .08, [64, 128, 60], 'rough');             // leaves
      for (let k = 0; k < n; k++) sphere(bx0 + .1 + k * (bx1 - bx0 - .2) / (n - 1), .16 + (k % 2) * .03, bz1 + .13 + (k % 3) * .02, .075, FL[(k * 5 + 1) % 4], 'solid');   // blooms
    });
    // a pot with a plant, left of the door
    part('maceta', () => {
      const [x, y] = POT;
      drum(x, y, 0, .3, .17, [200, 104, 66], (a, b) => rgb(92, 64, 44));
      for (let z = .25; z <= .3; z += PP) for (let t = 0; t < 6.3; t += .3) plot(x + Math.cos(t) * .175, y + Math.sin(t) * .175, z, rgb(224, 130, 86));   // the rim
      for (const [dx, dy, dz, r] of [[0, 0, .5, .17], [-.12, .05, .46, .12], [.1, -.06, .54, .13], [.02, .12, .44, .11]]) sphere(x + dx, y + dy, dz, r, LEAF, 'rough');
      for (const [dx, dy, dz, c] of [[-.08, .1, .62, [244, 88, 74]], [.12, .02, .66, [255, 224, 112]], [.0, -.1, .72, [255, 143, 184]]]) sphere(x + dx, y + dy, dz, .055, c, 'solid');
      castShadow(x, y, .35, .2);
    });
  }

  // the scale is drawn straight into the picture's pixels (a disc turned to the camera is a circle on it, a dish seen from above an ellipse),
  // so its rim, its two marks and its chains are exactly one pixel wide. d: how far from the camera, in the engine's depth
  const spot = (ix, iy, d, c) => { if (ix < 0 || iy < 0 || ix >= W || iy >= H) return; const i = iy * W + ix; if (d <= zb[i]) return; zb[i] = d; pix[i] = c; };
  function pline(x0, y0, x1, y1, d, fn) {                              // a one-pixel line, fn(k) the colour of the k-th pixel
    const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0));
    for (let k = 0; k <= n; k++) spot(Math.round(x0 + (x1 - x0) * k / (n || 1)), Math.round(y0 + (y1 - y0) * k / (n || 1)), d, fn(k));
  }
  function dial(d, needle) {
    const p = project(d.x, d.y, d.z), cx = Math.floor(p.sx), cy = Math.floor(p.sy), R = d.r, dd = p.d + .3;
    const RIM = rgb(58, 58, 70), FACE = rgb(252, 250, 244), SHADE = rgb(222, 220, 214), TICK = rgb(40, 40, 52), RED = rgb(224, 40, 40);
    for (let dy = -8; dy <= 8; dy++) for (let dx = -8; dx <= 8; dx++) {
      const r = Math.hypot(dx, dy);
      if (r > R) continue;
      let c = r > R - 1.1 ? RIM : (dx + dy > 4 && r > R - 2.6) ? SHADE : FACE;
      if (r <= R - 1.1) {
        if (dy === 0 && dx >= 3 && dx <= 5) c = TICK;                  // 3 o'clock: half a pound
        if (dx === 0 && dy >= 3 && dy <= 5) c = TICK;                  // 6 o'clock: a pound
        if (needle) {
          const [nx, ny] = needle === 'medio' ? [1, 0] : needle === 'libra' ? [0, 1] : [0, -1];
          for (let k = 0; k <= 5; k++) if (dx === nx * k && dy === ny * k) c = RED;
          if (dx === 0 && dy === 0) c = TICK;
        }
      }
      spot(cx + dx, cy + dy, dd, c);
    }
    return [cx, cy, dd];
  }
  function pan(P, dd) {                                                // a shallow dish seen from above: lighter inside, a darker rim, a foot
    const p = project(P.x, P.y, P.z), cx = Math.floor(p.sx), cy = Math.floor(p.sy), a = P.r * S, b = a * SIN;
    const RIM = rgb(88, 92, 106), SIDE = rgb(64, 66, 80), IN = rgb(214, 218, 228), IN_D = rgb(176, 182, 196), RIM_L = rgb(150, 154, 168);
    for (let dy = 4; dy <= 5; dy++) for (let dx = -3; dx <= 3; dx++) spot(cx + dx, cy + dy, dd, SIDE);   // the foot
    for (let lift = 2; lift >= 0; lift--) for (let dy = -5; dy <= 5; dy++) for (let dx = -8; dx <= 8; dx++) {
      const e = (dx / a) ** 2 + (dy / b) ** 2;
      if (e > 1.12) continue;
      if (lift) { if (dy > 0) spot(cx + dx, cy + dy + lift, dd, SIDE); continue; }               // the dish's outer wall, below its rim
      spot(cx + dx, cy + dy, dd, e > .66 ? (dy > 0 ? RIM_L : RIM) : (dy < 0 ? IN_D : IN));
    }
    return [cx, cy];
  }
  function scale(o) {
    const [px, py] = POLE, x = PESA_DIAL.x, y = PESA_DIAL.y, CH = [rgb(120, 124, 138), rgb(58, 60, 74)];
    block(px - .04, py - .04, 0, px + .04, py + .04, 2.35, METAL);                                  // the pole
    for (let a = x; a <= px; a += PP) for (let h = 0; h <= .05; h += PP) plot(a, y, 2.3 + h, rgb(...METAL));   // the arm
    const [cx, cy, dd] = dial(PESA_DIAL, o.aguja === '0' || o.aguja === 'medio' || o.aguja === 'libra' ? o.aguja : null);
    const top = Math.floor(project(x, y, 2.3).sy) + 1;
    for (let r = top; r <= cy - 7; r++) spot(cx, r, dd, CH[(r - top) % 2]);                         // the short chain from the arm to the dial
    const [pcx, pcy] = pan(PESA_PLATO, dd);
    // three thin chains from the dial's bottom spread down to the pan's rim: left, right and the back
    for (const [ex, ey] of [[-7, 0], [7, 0], [0, -4]]) pline(cx, cy + 7, pcx + ex, pcy + ey, dd + .1, k => CH[k % 2]);
  }

  function stand(o) {
    part('puesto', () => {
      // the body under the slanted top, on four short legs; its front boards, the ledge on two small brackets
      for (let a = TX0; a <= TX1; a += PX) for (let z = LEG; z <= TZ0; z += PZ) plot(a, TY1, z, shade(WOOD, ((a - TX0) % .5) < .04 ? 1.2 : 2.3, a, z));
      for (let b = TY0; b <= TY1; b += PX) for (let z = LEG; z <= tableZ(b); z += PZ) plot(TX1, b, z, shade(WOOD, 1.3, b, z));
      for (const [lx, ly] of [[TX0, TY0], [TX1 - .12, TY0], [TX0, TY1 - .12], [TX1 - .12, TY1 - .12]]) block(lx, ly, 0, lx + .12, ly + .12, LEG + .03, LEGC);
      block(TX0 - .05, TY1, LZ - .08, TX1 + .05, LY1, LZ, WOOD_L, [224, 196, 150]);
      for (const bx of [TX0 + .1, TX1 - .2]) block(bx, TY1, LZ - .2, bx + .08, LY1 - .06, LZ - .08, WOOD_D);
      // the slanted top: a dark bed, the bins' rims
      for (let a = TX0; a <= TX1; a += PA) for (let b = TY0; b <= TY1; b += PA) {
        const u = (a - TX0) / BW, rim = (u - Math.floor(u)) < .07 || b < TY0 + .06 || b > TY1 - .06 || a > TX1 - .05;
        plot(a, b, tableZ(b), rim ? rampOf(WOOD_L)[3] : rgb(104, 72, 48));
      }
      for (let a = TX0; a <= TX1; a += PX) for (let z = TZ1; z <= TZ1 + .16; z += PZ) plot(a, TY0, z, shade(WOOD_L, 2.4, a, z));   // the back board
    });
    for (const k of BINS) part(k, () => bin(k));
    part('pesa', () => scale(o));
    part('guineos', () => {
      const x = 6.1, y = AY - .02, zt = AZ0 - .22;
      for (let z = zt - .22; z <= zt; z += PP) plot(x, y, z, rgb(120, 92, 50));
      for (let k = 0; k < 5; k++) { sphere(x - .18 + k * .09, y, zt - .28 - Math.abs(k - 2) * .03, .075, [244, 206, 70], 'solid'); sphere(x - .15 + k * .075, y + .01, zt - .43 - Math.abs(k - 2) * .02, .07, [236, 196, 60], 'solid'); }
    });
    part('cajon', () => {
      const [x0, y0, x1, y1, h] = CRATE;
      block(x0, y0, 0, x1, y1, h, WOOD_L, [214, 176, 120]);
      for (let a = x0; a <= x1; a += ST) for (const z of [h * .33, h * .66]) plot(a, y1 + .01, z, rampOf(WOOD)[1]);
    });
    part('poste', () => block(POST[0] - .05, POST[1] - .05, 0, POST[0] + .05, POST[1] + .05, 1.15, WOOD));
  }

  /* ---------- the seven bins: each inside its own slice of the top, nothing past its rims ---------- */
  const G_PLAT = [128, 182, 66], G_TIP = [58, 78, 36], G_STEM = [96, 92, 46], AGUA = [32, 62, 40], AGUA_H = rgb(150, 198, 120), PINA = [214, 140, 52], CROWN = [[56, 126, 60], [108, 184, 80]], LIMA = [176, 214, 54];
  function bin(k) {
    const mid = binX(k), hw = BW / 2 - .08, bz = y => tableZ(y);
    if (PRODUCE[k]) {                                              // tomatoes, onions, potatoes: small rounds in a grid
      const [c, r] = PRODUCE[k], x0 = mid - BW / 2 + .12, x1 = mid + BW / 2 - .1, step = r * 1.75;
      let n = 0;
      for (let b = TY0 + .16; b <= TY1 - .14; b += step) for (let a = x0; a <= x1; a += step) {
        const jx = (hash(n, 7) - .5) * r * .5, jy = (hash(n, 13) - .5) * r * .5, z = bz(b) + r * .8; n++;
        sphere(a + jx, b + jy, z, r, k === 'cebollas' && n % 3 === 0 ? [240, 226, 200] : c, 'solid');
        if (k === 'tomates' && n % 2) sphere(a + jx, b + jy, z + r * .75, r * .28, [70, 140, 70], 'solid');
      }
    } else if (k === 'platanos') {                                 // plantains: long green fingers, curved, fanned from a dark stem; three loose hands; dark tips
      const r = .05;
      for (const [hx, hy] of [[mid - .045, 1.02], [mid + .05, 1.27], [mid - .03, 1.46]]) {
        capsule([hx - .085, hy - .015, bz(hy) + r + .02], [hx + .085, hy - .015, bz(hy) + r + .02], r * .85, r * .85, () => G_STEM, 'solid');   // the stem the fingers hang from
        for (const s of [-1, 0, 1]) {
          const x0 = hx + s * .02, y1 = hy + Math.abs(s) * .02, y2 = y1 + .42 - Math.abs(s) * .03, x2 = hx + s * .15;
          const A = [x0, y1, bz(y1) + r + .02], B = [(x0 + x2) / 2 + s * .12, (y1 + y2) / 2, bz((y1 + y2) / 2) + r - .02], Cc = [x2, y2, bz(y2) + r + .07];
          for (let n = 22, k = 0; k <= n; k++) {                      // a curve of spheres: fat in the middle, thin and dark at the tip, dark at the stem
            const t = k / n, u = 1 - t, c = (v, i) => u * u * A[i] + 2 * u * t * B[i] + t * t * Cc[i];
            sphere(c(0, 0), c(0, 1), c(0, 2), r * (1 + .15 * Math.sin(t * 3.14) - .3 * t * t), t > .86 || t < .07 ? G_TIP : G_PLAT, 'solid');
          }
        }
      }
    } else if (k === 'aguacates') {                                // avocados: dark pears (a round bottom, a narrow neck), a lighter patch on each, no tops
      for (let j = 0; j < 3; j++) for (let c = 0; c < 2; c++) {
        const x = mid + (c - .5) * .22 + (j % 2 ? .04 : -.04) - .01, y = 1.17 + j * .33 + c * .07 - .02, z = bz(y), lean = (j + c) % 2 ? .02 : -.01;
        sphere(x, y, z + .1, .1, AGUA, 'solid');
        sphere(x - lean, y + lean, z + .17, .073, AGUA, 'solid');
        sphere(x - lean * 2, y + lean * 2, z + .225, .05, AGUA, 'solid');
        const p = project(x, y, z + .1), i = (Math.floor(p.sy) - 2) * W + Math.floor(p.sx) - 2;                   // the highlight: two pixels, upper left
        if (zb[i] > -1e8) { pix[i] = AGUA_H; pix[i + 1] = AGUA_H; }
      }
    } else if (k === 'pinas') {                                    // pineapples: three, big, a diamond pattern and a spiky crown each
      [[mid + .05, 1.13], [mid + .08, 1.45], [mid + .05, 1.76]].forEach(([x, y]) => pineapple(x, y, bz(y) + .175));
    } else {                                                       // limes: small bright rounds with dark gaps between them
      for (let j = 0; j < 5; j++) for (let c = 0; c < 2; c++) {
        const x = mid + (c - .5) * .21 + (j % 2 ? .045 : -.045), y = 1.07 + j * .2 + (hash(c, j) - .5) * .02;
        sphere(x, y, bz(y) + .066, .066, LIMA, 'solid');
      }
    }
  }
  function pineapple(x, y, z) {
    const r = .175;
    capture = [];
    sphere(x, y, z, r, PINA, 'solid');
    sphere(x, y, z + .05, r * .95, PINA, 'solid');                 // a little taller than wide: an oval
    const px = capture; capture = null;
    const p = project(x, y, z), cx = Math.round(p.sx), cy = Math.round(p.sy);
    for (let n = 0; n < px.length; n += 4) {                       // the skin's diamonds: darker lines across the body, both ways
      const ix = px[n], iy = px[n + 1], d = px[n + 2], dx = ix - cx, dy = iy - cy, i = iy * W + ix;
      let c = px[n + 3];
      if ((((dx + dy) & 3) === 0) || (((dx - dy) & 3) === 0)) c = rgb((c & 255) * .7, (c >> 8 & 255) * .62, (c >> 16 & 255) * .8);
      if (d <= zb[i]) continue;
      zb[i] = d; pix[i] = c;
    }
    const zt = z + r * .85;
    for (let f = 0; f < 7; f++) {                                  // the crown: leaves fanned up and out
      const a = f / 7 * 6.283 + .4, dx = Math.cos(a), dy = Math.sin(a), out = f === 0 ? 0 : .09, up = f === 0 ? .25 : .18;
      capsule([x, y, zt - .02], [x + dx * out, y + dy * out, zt + up], .04, .014, () => CROWN[f % 2], 'solid');
    }
  }

  /* ---------- the hand cart (story 44): a flat wooden bed, two spoked wheels, a long handle to the left, three slatted crates ---------- */
  function cart() {
    part('carro', () => {
      const [cx, cy] = CART, B0 = cx - .95, B1 = cx + 1.2, Y0 = cy - .42, Y1 = cy + .42, BZ0 = .5, BZ1 = .57, WR = .42, WX = cx - .5;
      const Dk = rgb(46, 36, 30), WD = rampOf(WOOD), WL = rampOf(WOOD_L);
      // the handle: two long rails sloping down to the pavement, a cross-grip between their ends
      for (const s of [-1, 1]) capsule([B0 + .05, cy + s * .3, BZ0 + .02], [B0 - .65, cy + s * .3, .1], .04, .04, () => WOOD, 'solid');
      capsule([B0 - .65, cy - .3, .1], [B0 - .65, cy + .3, .1], .04, .04, () => WOOD_D, 'solid');
      // the bed, in one pass: planks along its length with a dark seam between them; its edges
      for (let a = B0; a <= B1; a += PA) for (let b = Y0; b <= Y1; b += PA) { const k = (b - Y0) / .14; plot(a, b, BZ1, (k - Math.floor(k)) < .1 ? WD[1] : WD[3 - (Math.floor(k) % 2)]); }
      for (let a = B0; a <= B1; a += PX) for (let z = BZ0; z <= BZ1; z += PZ) plot(a, Y1, z, WD[1]);
      for (let b = Y0; b <= Y1; b += PX) for (let z = BZ0; z <= BZ1; z += PZ) plot(B1, b, z, WD[0]);
      // the axle, and the wheels: a dark rim, eight spokes, a hub; the far wheel shows above the bed's back edge
      for (let y = cy - .5; y <= cy + .5; y += .02) plot(WX, y, WR, Dk);
      for (const s of [-1, 1]) {
        const y = cy + s * .5;
        for (let th = 0; th < 6.283; th += .03) for (const [rr, dy] of [[WR, 0], [WR, .04], [WR - .04, 0], [WR - .04, .04]]) plot(WX + Math.cos(th) * rr, y + dy, WR + Math.sin(th) * rr, rgb(58, 46, 40));
        for (let sp = 0; sp < 8; sp++) {
          const th = sp / 8 * 6.283 + .2;
          for (let rr = .04; rr <= WR - .03; rr += .014) for (const dy of [0, .03]) plot(WX + Math.cos(th) * rr, y + dy, WR + Math.sin(th) * rr, WL[sp % 2 ? 3 : 2]);
        }
        for (let a = -.05; a <= .05; a += .012) for (let b = -.05; b <= .05; b += .012) if (a * a + b * b < .0025) for (const dy of [-.01, .03, .05]) plot(WX + a, y + dy, WR + b, Dk);
      }
      // three slatted crates on the bed, in front of the wheels: leaves, tomatoes, leaves
      const LV = [[78, 150, 62], [112, 184, 84], [56, 122, 54]], TO = [226, 60, 50], CH = .3, CL = .38;
      for (let n = 0; n < 3; n++) {
        const ccx = cx + .1 + n * .44, x0 = ccx - CL / 2, x1 = ccx + CL / 2, y0 = cy - .36, y1 = cy + .36, z0 = BZ1, z1 = BZ1 + CH;
        const gap = z => { const s = (z - z0) / CH; return (s > .22 && s < .37) || (s > .6 && s < .75); };
        for (let a = x0; a <= x1; a += PA * .6) for (let z = z0; z <= z1; z += PP) plot(a, y1, z, gap(z) ? Dk : (a < x0 + .04 || a > x1 - .04) ? WD[2] : shade([226, 188, 132], 2.7, a, z));
        for (let b = y0; b <= y1; b += PA * .6) for (let z = z0; z <= z1; z += PP) plot(x1, b, z, gap(z) ? Dk : shade([226, 188, 132], 1.5, b, z));
        for (let a = x0; a <= x1; a += PA) for (let b = y0; b <= y1; b += PA) plot(a, b, z1, rgb(64, 46, 36));
        if (n === 1) { for (let j = 0; j < 3; j++) for (let c = 0; c < 4; c++) sphere(ccx - .1 + (j % 2) * .06 + (hash(j, c) - .5) * .03, y0 + .1 + c * .17, z1 + .04 + (j === 2 ? .08 : 0), .075, TO, 'solid'); }
        else for (let j = 0; j < 3; j++) for (let c = 0; c < 3; c++) sphere(ccx - .1 + (j % 2) * .08 + (c % 2) * .03, y0 + .1 + c * .25 + (j % 2) * .04, z1 + .02 + (j > 1 ? .1 : 0), .1, LV[(j + c + n) % 3], 'rough');
      }
      for (let n = 0; n < 3; n++) castShadow(cx + .1 + n * .44, cy, .8, .38);
      castShadow(WX, cy + .5, .2, .35, 1, .2);
    });
  }

  function extras(o) {
    part('arbusto', () => {                                          // a bush at the building's far right end
      bush(WX1 + 1.5, .8, .55, [96, 150, 70]);
      bush(WX1 + 2.1, .45, .4, LEAF);
    });
    if (o.carro) cart();
  }

  // where the roof's far edge falls on the picture at column sx, and from it the horizon row and the sun: the sun's disc sits on the far hills
  // at that column, clear of the roof (morning: half risen behind the hills; afternoon: whole, higher up)
  function skyPlan(o) {
    const R = o.hora === 'tarde' ? 11 : 10, sx = o.solX == null ? W - 44 : o.solX;
    const p0 = project(WX0, DEEP, WH), edge = p0.sy + .5 * (sx - p0.sx);
    const cyM = edge - 10 * .5 - 6, cyT = Math.max(R + 8, cyM - 24);
    const HZ = Math.round(cyM + 13 + 6 * Math.sin(sx * .029 + 1) + 3 * Math.sin(sx * .083));
    return { HZ, sun: [sx, o.hora === 'tarde' ? cyT : cyM, R] };
  }
  // the sky, screen space: bands, a sun, far hills
  function sky(o, HZ) {
    const tarde = o.hora === 'tarde';
    const bands = tarde ? [[236, 120, 70], [246, 156, 84], [250, 190, 110], [252, 214, 150], [254, 234, 190]] : [[80, 150, 236], [110, 176, 246], [150, 200, 252], [190, 222, 255], [226, 240, 255]];
    const [sx, sy, R] = skyPlan(o).sun;
    const tones = tarde ? [[250, 150, 60], [254, 190, 90], [255, 226, 150]] : [[246, 222, 130], [252, 238, 168], [255, 250, 212]];
    const far = tarde ? [[176, 120, 110], [206, 150, 130], [150, 100, 100]] : [[116, 170, 172], [156, 200, 198], [94, 150, 156]];
    const near = tarde ? [[120, 110, 90], [160, 140, 110], [100, 90, 80]] : [[78, 150, 104], [124, 196, 132], [62, 130, 90]];
    return (ix, iy) => skyHills(HZ, far, near, ix, iy) || skyDisc(sx, sy, R, tones, ix, iy) || skyBands(bands, 0, HZ, ix, iy);
  }

  function build(o) {
    building(o);
    if (o.puesto !== false) stand(o);
    extras(o);
    // shade: under the awning, and the awning's own shadow (to the right, like every shadow here)
    for (let x = AX0 + .3; x <= AX1 - .2; x += .45) castShadow(x, .5, 1.0, .5, .6);
    for (let x = AX0; x <= AX1 + .3; x += .35) castShadow(x, AY, AZ0, .32, 1, .25);
    if (o.puesto !== false) {
      for (let x = TX0; x <= TX1; x += .4) for (const y of [TY0 + .2, (TY0 + TY1) / 2, TY1 - .1]) castShadow(x, y, .85, .32);   // the stand's
      for (let x = TX0; x <= TX1; x += .8) castShadow(x, (TY0 + LY1) / 2, .06, .5, 2, .1);                                      // the dark under it, between the legs
      for (let z = .3; z <= 2.2; z += .3) castShadow(POLE[0], POLE[1], z, .1);                                                  // the pole's
      castShadow(PESA_DIAL.x, PESA_DIAL.y, PESA_DIAL.z, .3);                                                                    // the dial's
      castShadow((CRATE[0] + CRATE[2]) / 2, CRATE[3], .2, .4);
      for (let z = .3; z <= 1.1; z += .3) castShadow(POST[0], POST[1], z, .1);
    }
  }
  return { WX0, WX1, WH, D0, D1, DH, AX0, AX1, AZ0, AZ1, AY, TX0, TX1, TY0, TY1, TZ0, TZ1, LEG, LY1, LZ, PAVE, CRATE, POST, CART, BINS, BW, POLE, PESA_DIAL, PESA_PLATO, binX, tableZ, groundAt, build, sky, skyPlan };
})();
