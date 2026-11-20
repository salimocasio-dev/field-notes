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
     surtido 'verduras' | 'frutas'  what the stand's bins hold: verduras, FOUR bins of a quarter of the table each (tomates, cebollas, papas, platanos,
                                    left to right), or frutas, THREE of a third each (aguacates, pinas, limones). Default verduras
     aguja   '' | '0' | 'medio' | 'libra'   a red needle on the scale's dial, at 12, 3 or 6 o'clock ('' : none; in the game the needle is a sprite)
     solX    the sun's x in the picture, in pixels (default W - 44)
   Everything that moves is a sprite: people, the goat, the rooster, what is taken out of a bin, the scale's needle, coins.
   Exports BINS and BW (the bins of the assortment in use, and each one's width: set by build(o); verduras before it), SURTIDOS (both lists),
   binX(k) (the x of a bin's middle) and binBox(k) ([x0, y0, z0, x1, y1, z1]: the bin's space, from the table's low edge to .3 above its back),
   PESA_DIAL ({x, y, z}: the world centre of the scale's dial, r: its radius in picture pixels; the dial faces the camera, so its
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
  const CART = [3.9, 3.35];                                      // the hand cart: the middle of its bed. In front of the stand's left end, so that it and the post at the right end fit one 196-px window
  const SURTIDOS = { verduras: ['tomates', 'cebollas', 'papas', 'platanos'], frutas: ['aguacates', 'pinas', 'limones'] };
  let BINS = SURTIDOS.verduras, BW = (TX1 - TX0) / BINS.length;     // the assortment in use (build sets them): each bin takes an equal slice of the table
  const PAINT = [240, 150, 116], TRIM = [86, 160, 150], POLE = [3.55, TY1 + .1], WOOD = [150, 98, 56], WOOD_L = [196, 148, 92], WOOD_D = [92, 62, 40], LEGC = [48, 34, 28];
  const METAL = [120, 120, 130], LEAF = [74, 134, 62];
  const tableZ = y => TZ1 - (clamp(y, TY0, TY1) - TY0) / (TY1 - TY0) * (TZ1 - TZ0);
  const binX = k => TX0 + BW * (BINS.indexOf(k) + .5);
  const binBox = k => { const i = BINS.indexOf(k); return [TX0 + BW * i, TY0, TZ0, TX0 + BW * (i + 1), TY1, TZ1 + .3]; };
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
        const rim = ((a - TX0) % BW) < .05 || b < TY0 + .06 || b > TY1 - .06 || a > TX1 - .05;
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

  /* ---------- the bins: four (verduras) or three (frutas) on one table, each inside its own slice of the top, nothing past its rims ---------- */
  // A kind is drawn pixel by pixel in the picture, like the scale: a stamp of one-pixel cells standing on a world point of the bed (its bottom middle
  // on that point), so it can be bigger than a shaded ball and carry what makes it itself (a tomato's star, an onion's point, a potato's eyes ...).
  // A stamp is a little nearer the camera than the bed under it (SPR), so it beats the rims and what lies behind it; nearer stamps beat farther ones
  const SPR = .14;
  const pal = m => { const r = {}; for (const k in m) r[k] = rgb(...m[k]); return r; };
  function draw(w, h, x, y, z, fn, dd = 0) {                         // fn(c, r) -> a colour or 0, for the cell c across and r down (r = h - 1 is the feet)
    const p = project(x, y, z), cx = Math.floor(p.sx) - (w >> 1), cy = Math.floor(p.sy) - (h - 1), d = p.d + SPR + dd;
    for (let r = 0; r < h; r++) for (let c = 0; c < w; c++) { const q = fn(c, r); if (q) spot(cx + c, cy + r, d, q); }
  }
  const stamp = (rows, P, x, y, z, dd) => draw(rows[0].length, rows.length, x, y, z, (c, r) => P[rows[r][c]], dd);
  // the spot of a bin's picture at (u, v) from 0 to 1 over the room left inside its rims for a thing `half` wide (world units)
  function lay(k, half, u, v) {
    const i = BINS.indexOf(k), x0 = TX0 + BW * i + .07 + half, x1 = TX0 + BW * (i + 1) - .07 - half, y0 = TY0 + .09 + half, y1 = TY1 - .09 - half;
    return [x0 + (x1 - x0) * u, y0 + (y1 - y0) * v];
  }
  const jit = (n, a) => (hash(n, 7) - .5) * a;

  // tomatoes: round and red, a green star of a stem on top
  const P_TOM = pal({ R: [218, 50, 46], L: [250, 134, 108], D: [164, 34, 46], K: [110, 26, 44], g: [84, 156, 62], G: [146, 210, 88], s: [40, 88, 48] });
  const S_TOM = [[
    '...s...',
    '.gGGGg.',
    'RLRgRRD',
    'LRRRRRD',
    'RRRRRDD',
    '.RDDDD.',
  ], [
    '...s...',
    '.gGGGg.',
    'RRgRRRD',
    'RLRRRRD',
    'RRRRRDD',
    '.RDDDD.',
  ]];
  // yellow onions: round with a pointed top, golden-brown papery skin with one lighter stripe, a tuft of dry stem above, a few roots below
  const P_ONI = pal({ y: [236, 182, 86], Y: [208, 148, 64], S: [252, 226, 134], D: [156, 102, 50], K: [106, 68, 42], t: [232, 208, 142], T: [128, 88, 52], r: [222, 200, 150] });
  const S_ONI = [
    '...T...',
    '...t...',
    '..ySD..',
    '.ySYYD.',
    'ySYYYYD',
    'ySYYYYD',
    'yYSYYDD',
    '.yYSDD.',
    '..YDK..',
    '..r.r..',
  ];
  // the cut onion (9 x 11): the same pointed shape, a golden skin round it, rings of white and pale beige inside
  const P_ONC = pal({ Y: [208, 148, 64], D: [156, 102, 50], W: [254, 250, 238], V: [186, 150, 106], t: [232, 208, 142] });
  function onionCut(x, y, z) {
    draw(9, 11, x, y, z, (c, r) => {
      const dx = c - 4, dy = r - 6.5, q = Math.hypot(dx * (dy < 0 ? 1 + .2 * -dy : 1), dy * (dy < 0 ? .82 : 1));
      if (q > 4.5) return r === 0 && c === 4 ? P_ONC.t : 0;
      if (q > 3.5) return dx + dy > 2 ? P_ONC.D : P_ONC.Y;
      return q > 2.6 ? P_ONC.W : q > 1.7 ? P_ONC.V : q > .8 ? P_ONC.W : P_ONC.V;
    });
  }
  // potatoes: lumpy brown ovals with two or three darker eyes, dull (no light spot)
  const P_POT = pal({ p: [190, 160, 118], P: [168, 136, 96], D: [128, 100, 72], d: [96, 74, 56], e: [84, 62, 44] });
  const S_POT = [[
    '...ppPP.',
    '.pPPPPPD',
    'pPePPPPD',
    'PPPPPeDD',
    'PePPDDD.',
    '.dDDdd..',
  ], [
    '..pPPP..',
    '.pPPPePD',
    'PPePPPPD',
    'PPPPPDDD',
    '.DPeDDD.',
    '..dddd..',
  ], [
    '.ppPP...',
    'pPPPPPD.',
    'PPPePPPD',
    '.PPPPPeD',
    '.dDPDDD.',
    '...dddd.',
  ]];
  // plantains: two big hands of long curved green fingers, each hand joined at a dark stem, each finger fat in the middle and ending in a dark tip.
  // A finger is a curve in world space along x (its ends lifted, bowed a little), painted in pixels: lit on its top edge, dark on its lower, up to 4 px thick
  const P_PLA = pal({ G: [154, 208, 86], g: [108, 166, 62], d: [56, 100, 50], T: [44, 42, 28], S: [58, 40, 26], s: [170, 130, 78] });
  function hand(xs, ys, n, L, gap, fan, lift, lay) {                   // the stem at (xs, ys) on the bed; n fingers run along +x, `gap` apart along y at the stem, `fan` more at each tip
    for (let i = 0; i < n; i++) {
      const f = i - (n - 1) / 2, y0 = ys + i * gap, y1 = y0 + f * fan, len = L * (1 - .05 * Math.abs(f));
      for (let t = 0; t <= 1.0001; t += .006) {
        const x = xs + len * t, y = y0 + (y1 - y0) * t + .06 * Math.sin(t * Math.PI), z = tableZ(y) + .1 + lay + lift * (2 * t - 1) ** 2;
        const p = project(x, y, z), sx = Math.floor(p.sx), sy = p.sy, d = p.d + SPR + .02 * i;
        const w = 1.6 + 2.2 * Math.pow(Math.sin(Math.PI * Math.min(1, t * 1.08)), .6), top = Math.round(sy - w / 2 + .01), bot = Math.round(sy + w / 2 - .01);
        for (let Y = top; Y <= bot; Y++) spot(sx, Y, d, t > .93 ? P_PLA.T : Y === top ? P_PLA.G : (Y === bot && bot > top) ? P_PLA.d : P_PLA.g);
      }
    }
    for (let i = 0; i < n; i++) {                                     // the stem: a dark block across the roots, lit on its top edge
      const y0 = ys + i * gap, p = project(xs - .03, y0, tableZ(y0) + .1 + lay + lift), sx = Math.floor(p.sx), sy = Math.floor(p.sy);
      for (let c = 0; c < 3; c++) for (let k = -1; k <= 0; k++) spot(sx - c, sy + k, p.d + SPR + .02 * n + .05, k === -1 ? P_PLA.s : P_PLA.S);
    }
  }

  // avocados: dark green pears (a round bottom, a narrow neck) with a light spot, 8 x 10; and one cut in half and open
  const P_AGU = pal({ a: [96, 152, 74], A: [62, 112, 58], H: [196, 234, 154], D: [38, 76, 50], K: [26, 52, 42] });
  const S_AGU = [[
    '...aA...',
    '...aA...',
    '..aAAA..',
    '.aHAAAA.',
    'aHHAAAAD',
    'aHAAAADD',
    'aAAADAAD',
    'AAAAAADD',
    '.AAADDD.',
    '..DDDK..',
  ], [
    '...aA...',
    '..aAAA..',
    '..aHAA..',
    '.aHHAAA.',
    'aHAAAADD',
    'aAADAAAD',
    'aAAAAADD',
    'AAAAADAD',
    '.AAADDD.',
    '..DDDK..',
  ]];
  const P_AGC = pal({ skin: [34, 66, 42], rim: [96, 150, 58], fl: [208, 224, 118], fh: [232, 238, 158], st: [112, 72, 42], sl: [170, 118, 72], sd: [76, 48, 32] });
  function avocadoCut(x, y, z) {
    draw(11, 12, x, y, z, (c, r) => {
      const px = c + .5 - 5.5, py = r + .5;
      const q1 = Math.hypot(px / 5, (py - 7.3) / 4.7), q2 = Math.hypot(px / 3.1, (py - 3.5) / 3.4), q = Math.min(q1, q2);
      if (q > 1) return 0;
      const dep = 1 - q;                                              // how far in from the skin, 0 to 1
      if (dep < .17) return P_AGC.skin;
      const sx = px, sy = py - 8.1, sr = Math.hypot(sx, sy);
      if (sr < 2.3) return sr > 1.5 && sx + sy > 1.2 ? P_AGC.sd : (sx < -.2 && sy < -.2 && sr > .4) ? P_AGC.sl : P_AGC.st;   // the stone
      return dep < .3 ? P_AGC.rim : dep < .46 ? P_AGC.fl : P_AGC.fh;
    });
  }

  // pineapples (15 x 20, a body 13 wide): a golden-orange oval with a dark diamond criss-cross, a tall spiky crown of seven leaves
  const P_PIN = { hi: rgb(252, 204, 90), mid: rgb(240, 160, 52), lo: rgb(206, 116, 42), dk: rgb(150, 84, 40),
    hiL: rgb(150, 78, 24), midL: rgb(128, 64, 22), loL: rgb(104, 52, 26), dkL: rgb(80, 40, 28),
    lv: [rgb(122, 196, 86), rgb(84, 156, 70), rgb(54, 120, 62), rgb(40, 94, 56)] };
  const CROWN = [[.8, 5.4], [2.9, 2.8], [5.2, 1.0], [7.5, .2], [9.8, 1.0], [12.1, 2.8], [14.2, 5.4]];   // the seven leaves' tips
  function pineapple(x, y, z) {
    const BX = 7.5, BY = 14.6, HW = 6.5, HH = 5.5;
    draw(15, 20, x, y, z, (c, r) => {
      const px = c + .5, py = r + .5, nx = (px - BX) / HW, ny = (py - BY) / HH, nn = nx * nx + ny * ny;
      if (nn <= 1) {
        const l = -.55 * nx - .6 * ny + .58 * Math.sqrt(1 - nn), band = l > .78 ? 'hi' : l > .5 ? 'mid' : l > .2 ? 'lo' : 'dk';
        const i = c - 7, j = r - 14, m = k => ((k % 4) + 4) % 4;
        if (m(i + j) === 0 || m(i - j) === 0) return P_PIN[band + 'L'];
        return m(i + j) === 2 && m(i - j) === 2 && band !== 'dk' ? P_PIN.hi : P_PIN[band];
      }
      let best = 9;                                                     // a leaf: the pixel is within its width of the line from the crown's foot to its tip
      for (let k = 0; k < 7; k++) {
        const [tx, ty] = CROWN[k], bx = BX + (k - 3) * .9, by = 10.6 - (k === 3 ? 0 : 0), ex = tx - bx, ey = ty - by, len2 = ex * ex + ey * ey;
        const t = clamp(((px - bx) * ex + (py - by) * ey) / len2, 0, 1), dist = Math.hypot(px - bx - ex * t, py - by - ey * t);
        if (dist <= 1.05 * (1 - t) + .42) best = Math.min(best, Math.abs(k - 3));
      }
      return best < 9 ? P_PIN.lv[best] : 0;
    });
  }

  // limes: bright yellow-green rounds (6 x 6) with dark gaps between them; and one cut in half (9 x 9), pale, with segment lines
  const P_LIM = pal({ l: [216, 244, 110], L: [172, 218, 58], D: [120, 172, 46], d: [76, 120, 44] });
  const S_LIM = [
    '.llLL.',
    'lllLLD',
    'lLLLLD',
    'LLLLDD',
    '.LLDD.',
    '..dd..',
  ];
  const P_LIC = pal({ skin: [78, 142, 40], rind: [204, 228, 132], fl: [172, 210, 80], ln: [242, 251, 196] });
  function limeCut(x, y, z) {
    draw(9, 9, x, y, z, (c, r) => {
      const dx = c - 4, dy = r - 4, q = Math.hypot(dx, dy);
      if (q > 4.4) return 0;
      if (q > 3.7) return P_LIC.skin;
      if (q > 3.0) return P_LIC.rind;
      if (q > .9 && (dx === 0 || dy === 0 || Math.abs(dx) === Math.abs(dy))) return P_LIC.ln;
      return P_LIC.fl;
    });
  }

  function bin(k) {
    const bz = y => tableZ(y);
    const put = (rows, P, h, u, v, n) => { const [x, y] = lay(k, h, u, v); stamp(rows, P, x + jit(n, .02), y + jit(n + 5, .02), bz(y)); };
    if (k === 'tomates') {
      [[0, 0], [.5, 0], [1, 0], [0, .5], [.33, .5], [.67, .5], [1, .5], [0, 1], [.5, 1], [1, 1]].forEach(([u, v], n) => put(S_TOM[n % 2], P_TOM, .135, u, v, n));
    } else if (k === 'cebollas') {
      [[0, 0], [.5, 0], [1, 0], [0, .5], [.33, .5], [.67, .5], [1, .5], [0, 1], [1, 1]].forEach(([u, v], n) => put(S_ONI, P_ONI, .135, u, v, n + 20));
      const [x, y] = lay(k, .17, .5, .93); onionCut(x, y, bz(y));
    } else if (k === 'papas') {
      [[0, 0], [.5, 0], [1, 0], [.1, .5], [.55, .5], [1, .5], [0, 1], [.5, 1], [1, 1]].forEach(([u, v], n) => put(S_POT[n % 3], P_POT, .154, u, v, n + 40));
    } else if (k === 'platanos') {
      const x0 = TX0 + BW * BINS.indexOf(k);
      hand(x0 + .22, 1.16, 5, .8, .15, .07, .1, 0);
      hand(x0 + .26, 1.33, 4, .76, .15, .07, .1, .07);
    } else if (k === 'aguacates') {
      [[0, 0], [.45, 0], [.2, .5], [.7, .5], [1, .45], [0, 1], [1, 1]].forEach(([u, v], n) => put(S_AGU[n % 2], P_AGU, .154, u, v, n + 60));
      const [x, y] = lay(k, .2, .5, .95); avocadoCut(x, y, bz(y));
    } else if (k === 'pinas') {
      const [xa, ya] = lay(k, .29, 0, .22), [xb, yb] = lay(k, .29, 1, .52);
      pineapple(xa, ya, bz(ya)); pineapple(xb, yb, bz(yb));
    } else {                                                          // limones
      for (let j = 0; j < 3; j++) for (let c = 0; c < (j === 1 ? 4 : 5); c++) {
        if (j === 2 && c === 2) continue;
        const [x, y] = lay(k, .115, j === 1 ? (c + .5) / 4 : c / 4, j / 2); stamp(S_LIM, P_LIM, x + jit(j * 7 + c, .02), y + jit(j * 7 + c + 3, .02), bz(y));
      }
      const [x, y] = lay(k, .17, .5, .9); limeCut(x, y, bz(y));
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
    BINS = SURTIDOS[o.surtido] || SURTIDOS.verduras; BW = (TX1 - TX0) / BINS.length; api.BINS = BINS; api.BW = BW;
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
  const api = { WX0, WX1, WH, D0, D1, DH, AX0, AX1, AZ0, AZ1, AY, TX0, TX1, TY0, TY1, TZ0, TZ1, LEG, LY1, LZ, PAVE, CRATE, POST, CART, BINS, BW, SURTIDOS, POLE, PESA_DIAL, PESA_PLATO, binX, binBox, tableZ, groundAt, build, sky, skyPlan };
  return api;
})();
