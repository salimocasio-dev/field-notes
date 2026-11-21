// Port of docs/proyecto/pixel/colmado-fuera.js: don Pepe's colmado from the street, call for call: its front wall, door
// and awning, and the fruit and vegetable stand under the awning. Shared by two scene sets of place 4: frutas (the stand)
// and mostrador (donde=calle: the shop front, for story 36's first beat). Each set builds its engine with its own origin,
// asks [ColmadoFuera.skyPlan] for the horizon row and the sun's place, and calls [ColmadoFuera.build]. The file's names are
// kept, capitals included, so the port reads line for line against it (page 12, section 6): the lints on names are off.
//
// First writer: order 50b (El mostrador). The builders of the other scenes copy it and add to it only by adding. The
// whole file is ported, also what El mostrador does not use (the fruit assortment, the scale's needle, the hand cart),
// each tested against the JavaScript (test/colmado_kit_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart' show castShadowJs;
import 'package:coqui_scenes/src/set_kit.dart';

/// colmado-fuera.js: OPT.
class CfOpt {
  const CfOpt({
    this.hora = 'manana',
    this.puerta = 'shut',
    this.carro = false,
    this.puesto = true,
    this.surtido = 'verduras',
    this.aguja = '',
    this.solX,
  });

  /// 'manana' | 'tarde': the sky (a pale sun half risen behind the far hills, or a whole, higher one in an orange sky).
  final String hora;

  /// 'shut' | 'open': the shop door.
  final String puerta;

  /// don Pepe's hand cart on the pavement, left of the scale (story 44).
  final bool carro;

  /// `o.puesto !== false`: the stand, its bins, the scale, the guineos, the low crate and the post (false: only the
  /// awning's shade).
  final bool puesto;

  /// 'verduras' | 'frutas': what the stand's bins hold (an unknown name is verduras, as `SURTIDOS[o.surtido] ||`).
  final String surtido;

  /// '' | '0' | 'medio' | 'libra': a red needle on the scale's dial ('': none; in the game the needle is a sprite).
  final String aguja;

  /// The sun's x in the picture, in pixels (null: W - 44).
  final num? solX;
}

/// The world centre of a disc and its radius (colmado-fuera.js: PESA_DIAL, PESA_PLATO).
typedef CfDisc = ({double x, double y, double z, double r});

/// colmado-fuera.js: skyPlan's result: the horizon row and the sun (x, y, radius).
typedef CfSkyPlan = ({int HZ, List<num> sun});

/// Port of colmado-fuera.js (`CF`). World (S = 26): the front wall is y = 0 and faces +y (lit); the pavement runs from
/// it to y = PAVE; the street beyond. Everything that moves is a sprite: people, the goat, the rooster, what is taken out
/// of a bin, the scale's needle, coins. [BINS] and [BW] are the bins of the assortment in use (set by [build];
/// verduras before it).
class ColmadoFuera {
  ColmadoFuera(this.k) : e = k.e, b = k.b;

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  int get W => e.W;
  int get H => e.H;
  double get ST => b.ST;

  static const double WX0 = -3.4,
      WX1 = 11.0,
      WH = 3.5,
      DEEP =
          -2.2; // the building: along x, its height, its depth behind the wall
  static const double D0 = 1.0, D1 = 2.3, DH = 2.55; // the door
  static const double AX0 = 3.7,
      AX1 = 8.7,
      AZ1 = 3.0,
      AZ0 = 2.78,
      AY = 1.0; // the awning: at the wall (high) to its front edge (low)
  static const double TX0 = 4.0,
      TX1 = 8.4,
      TY0 = .95,
      TY1 = 2.0,
      TZ1 = 1.15,
      TZ0 = .78; // the stand's slanted top: back (high) to front (low)
  static const double LEG =
      .2; // the stand's legs: the body stands this high above the pavement
  static const double LY1 = 2.32, LZ = .7; // the ledge along its front
  static const double PAVE = 4.3,
      LINE_Y = 5.9; // the pavement's width; the street's painted line
  static const List<double> CRATE = [8.95, 1.25, 9.7, 1.95, .34],
      POST = [10.1, 1.6]; // the low crate; the goat's post
  static const List<double> WIN = [
    -1.9,
    -.8,
    1.2,
    2.1,
  ]; // the shuttered window: x0, x1, z0, z1
  static const List<double> POT = [.28, .5]; // the flower pot left of the door
  static const List<double> CART = [
    3.9,
    3.35,
  ]; // the hand cart: the middle of its bed
  static const Map<String, List<String>> SURTIDOS = {
    'verduras': ['tomates', 'cebollas', 'papas', 'platanos'],
    'frutas': ['aguacates', 'pinas', 'limones'],
  };

  /// The assortment in use (build sets it): each bin takes an equal slice of the table.
  List<String> BINS = SURTIDOS['verduras']!;
  double BW = (TX1 - TX0) / 4;
  static const List<int> PAINT = [240, 150, 116],
      TRIM = [86, 160, 150],
      WOOD = [150, 98, 56],
      WOOD_L = [196, 148, 92],
      WOOD_D = [92, 62, 40],
      LEGC = [48, 34, 28];
  static const List<double> POLE = [3.55, TY1 + .1];
  static const List<int> METAL = [120, 120, 130], LEAF = [74, 134, 62];

  // colmado-fuera.js: tableZ
  double tableZ(num y) =>
      TZ1 - (e.clamp<num>(y, TY0, TY1) - TY0) / (TY1 - TY0) * (TZ1 - TZ0);

  // colmado-fuera.js: binX
  double binX(String kk) => TX0 + BW * (BINS.indexOf(kk) + .5);

  // colmado-fuera.js: binBox. The bin's space, from the table's low edge to .3 above its back.
  List<double> binBox(String kk) {
    final i = BINS.indexOf(kk);
    return [TX0 + BW * i, TY0, TZ0, TX0 + BW * (i + 1), TY1, TZ1 + .3];
  }

  /// The dial: a disc turned to the camera (its centre on the picture is project(x, y, z); r in picture pixels).
  static const CfDisc PESA_DIAL = (x: 3.55 - .8, y: TY1 + .1, z: 1.7, r: 7.5);

  /// The pan hangs straight under it (r in world units).
  static const CfDisc PESA_PLATO = (x: 3.55 - .8, y: TY1 + .1, z: .72, r: .27);

  // the big flat faces are sampled a little under a pixel: the engine's ST is a third of one, and the walls were most of
  // the bake
  static const double PX = .04, PZ = .035, PA = .03, PP = .024;

  int rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // colmado-fuera.js: wall. A face of the wall's kind, facing +y; fn(a, z) the colour; rectangular holes [a0, a1, z0, z1]
  // (a surface is painted in ONE pass: a second layer a hair in front of it loses pixels to the first wherever the depth
  // varies inside a pixel)
  void wall(
    num at,
    num a0,
    num a1,
    num z0,
    num z1,
    int Function(num a, num z) fn,
    List<List<num>> holes,
  ) {
    for (num a = a0; a <= a1; a += PX) {
      final hs = holes.where((h) => a > h[0] && a < h[1]).toList();
      for (num z = z0; z <= z1; z += PZ) {
        if (hs.any((h) => z > h[2] && z < h[3])) continue;
        e.plot(a, at, z, fn(a, z));
      }
    }
  }

  // colmado-fuera.js: box2. block() at the coarse step, its top painted by topFn(a, b) when that gives a colour
  void box2(
    num x0,
    num y0,
    num z0,
    num x1,
    num y1,
    num z1,
    List<int> c, [
    int Function(num a, num b)? topFn,
  ]) {
    for (num a = x0; a <= x1; a += PA) {
      for (num bb = y0; bb <= y1; bb += PA) {
        final t = topFn == null ? 0 : topFn(a, bb);
        e.plot(a, bb, z1, t != 0 ? t : b.shade(c, 3.4, a, bb));
      }
    }
    for (num a = x0; a <= x1; a += PX) {
      for (num z = z0; z <= z1; z += PZ) {
        e.plot(a, y1, z, b.shade(c, 2.4, a, z));
      }
    }
    for (num bb = y0; bb <= y1; bb += PX) {
      for (num z = z0; z <= z1; z += PZ) {
        e.plot(x1, bb, z, b.shade(c, 1.3, bb, z));
      }
    }
  }

  // colmado-fuera.js: pane. A painted plane facing +y: fn(a, z) gives a colour or 0
  void pane(
    num at,
    num a0,
    num a1,
    num z0,
    num z1,
    int Function(num a, num z) fn,
  ) {
    for (num a = a0; a <= a1; a += PP) {
      for (num z = z0; z <= z1; z += PP) {
        final col = fn(a, z);
        if (col != 0) e.plot(a, at, z, col);
      }
    }
  }

  // colmado-fuera.js: groundAt
  int groundAt(num x, num y, int ix, int iy, int i, num HZ) {
    if (iy + .5 < HZ) return 0;
    e.kinds[i] = KIND_ROAD;
    if (y < DEEP - .3) {
      return rgbOf(
        e.GRASS[e.clamp(
          ((.3 + e.noise(x * .7, y * .7) * .7 + (e.hash(ix, iy) - .5) * .3) * 4)
              .floor(),
          0,
          3,
        )],
      ); // the lot behind the building
    }
    if (y <= PAVE) {
      // the pavement: big slabs
      final ea = ((x + 20) % 1.1) / 1.1, eb = ((y + 20) % 1.1) / 1.1;
      return (ea < .04 || eb < .04)
          ? e.rgb(168, 160, 150)
          : b.toneOf(
              b.C.pave,
              .45 +
                  e.hash(((x + 20) / 1.1).floor(), ((y + 20) / 1.1).floor()) *
                      .3,
              ix,
              iy,
            );
    }
    if (y <= PAVE + .22) return e.rgb(214, 208, 196); // the kerb
    if ((y - LINE_Y).abs() < .075 && ((x + 40) % 1.6) < 1.0) {
      return e.rgb(232, 218, 150); // a painted dashed line down the street
    }
    return rgbOf(
      (e.hash(ix >> 1, iy >> 1) < .08)
          ? const [112, 110, 116]
          : const [98, 96, 104],
    ); // the street
  }

  // colmado-fuera.js: building
  void building(CfOpt o) {
    k.part('colmado', () {
      // the wall, its roof and its end; holes where the door, the window and the sign are, each painted flush by its own
      // pass
      int PAINT_(num a, num z) => z < .7
          ? b.shade(TRIM, z > .64 ? 1.4 : 2.4, a, z)
          : z > WH - .3
          ? b.shade(TRIM, 2.6, a, z)
          : b.shade(
              PAINT,
              2.4,
              a,
              z,
            ); // a painted foot and a band under the roof
      final hWin = [WIN[0] - .1, WIN[1] + .1, WIN[2] - .1, WIN[3] + .1],
          hSign = [D0 - .5, D1 + .5, DH + .2, DH + .85],
          hDoor = [D0 - .12, D1 + .12, 0, DH + .12];
      for (num a = WX0; a <= WX1; a += PA) {
        for (num bb = DEEP; bb <= 0; bb += PA) {
          e.plot(a, bb, WH, b.shade(PAINT, 3.4, a, bb));
        }
      }
      wall(0, WX0, WX1, 0, WH, PAINT_, [hDoor, hWin, hSign]);
      for (num bb = DEEP; bb <= 0; bb += PA) {
        for (num z = 0; z <= WH; z += PZ) {
          e.plot(WX1, bb, z, b.shade(PAINT, 1.3, bb, z));
        }
      }
      // a small shuttered window at the left
      final F = e.rampOf(const [244, 240, 228]);
      pane(
        0,
        hWin[0],
        hWin[1],
        hWin[2],
        hWin[3],
        (a, z) => (z < WIN[2] || z > WIN[3])
            ? F[3]
            : F[((z - WIN[2]) / .1).floor() % 2 != 0 ? 3 : 2],
      );
      // the sign over the door: a board with a picture (a basket of fruit), no words
      pane(0, hSign[0], hSign[1], hSign[2], hSign[3], (a, z) {
        final u = (a - D0 + .5) / (D1 - D0 + 1), v = (z - DH - .2) / .65;
        if (u < .04 || u > .96 || v < .08 || v > .92) return e.rgb(120, 76, 44);
        final dx = (u - .5) * 3.2, dy = v - .42;
        if (dy < 0 && dy > -.3 && dx.abs() < .62 + dy) {
          return e.rgb(176, 124, 70);
        }
        double hyp(num p, num q) => math.sqrt(p * p + q * q);
        if (hyp(dx + .3, dy - .12) < .2) return e.rgb(226, 60, 50);
        if (hyp(dx - .05, dy - .2) < .2) return e.rgb(244, 200, 70);
        if (hyp(dx - .36, dy - .1) < .18) return e.rgb(110, 170, 70);
        return e.rgb(250, 244, 226);
      });
    });
    k.part('puerta', () {
      const w = D1 - D0;
      final Wd = e.rampOf(WOOD), F = e.rampOf(WOOD_L);
      k.reveal(0, D0, D1, 0, DH, .2, PAINT);
      pane(
        -1.0,
        D0 - .9,
        D1,
        0,
        DH + .2,
        (a, z) => z < .14
            ? e.rgb(60, 44, 34)
            : e.rgb(84 - z * 10, 78 - z * 10, 70 - z * 8),
      ); // the shop inside: dim
      for (num a = D0 - .9; a <= D1; a += PA) {
        for (num bb = -1.0; bb <= 0; bb += PA) {
          e.plot(a, bb, 0, e.rgb(120, 104, 88));
        }
      }
      pane(
        0,
        D0 - .12,
        D1 + .12,
        0,
        DH + .12,
        (a, z) => (a > D0 && a < D1 && z < DH) ? 0 : (z > DH ? F[3] : F[2]),
      ); // the frame: two jambs and a lintel
      // the leaf: two panels and a glass with two light streaks across it
      int panel(num t, num z) {
        final u = t * w,
            glass = u > .2 && u < w - .2 && z > 1.3 && z < DH - .25;
        if (!glass) {
          return Wd[(u < .08 || u > w - .08 || z < .08 || z > DH - .08)
              ? 1
              : 2];
        }
        final s =
            (u * 1.5 + z * 1.0) % 1.1; // diagonal streaks of reflected light
        return s < .2
            ? e.rgb(232, 246, 250)
            : (s > .32 && s < .4)
            ? e.rgb(206, 232, 240)
            : e.rgb(150, 200, 214);
      }

      if (o.puerta == 'open') {
        // swung out against the wall, to the right
        const ang = .25;
        final dx = math.cos(ang), dy = math.sin(ang);
        for (num t = 0; t <= 1; t += PP / w) {
          for (num z = 0; z <= DH; z += PP) {
            e.plot(D1 + dx * w * t, .02 + dy * w * t, z, panel(t, z));
          }
        }
      } else {
        pane(-.05, D0, D1, 0, DH, (a, z) => panel((D1 - a) / w, z));
      }
    });
    k.part('toldo', () {
      // the awning: a slope of red and white stripes, a short skirt along its front edge
      for (num a = AX0; a <= AX1; a += PA) {
        for (num bb = 0; bb <= AY; bb += PA) {
          final z = AZ1 - bb / AY * (AZ1 - AZ0),
              s = ((a - AX0) / .42).floor() % 2;
          e.plot(
            a,
            bb,
            z,
            b.shade(
              s != 0 ? const [226, 60, 50] : const [250, 246, 236],
              3.2,
              a,
              bb,
            ),
          );
        }
      }
      for (num a = AX0; a <= AX1; a += PX) {
        for (num z = AZ0 - .22; z <= AZ0; z += PZ) {
          final s = ((a - AX0) / .42).floor() % 2;
          e.plot(
            a,
            AY,
            z,
            b.shade(
              s != 0 ? const [226, 60, 50] : const [250, 246, 236],
              2.2,
              a,
              z,
            ),
          );
        }
      }
    });
    // the flower box under the shuttered window, and its flowers (as the house's in El balcón)
    final bx0 = WIN[0] - .12,
        bx1 = WIN[1] + .12,
        bz0 = WIN[2] - .34,
        bz1 = WIN[2] - .1;
    k.part('jardinera', () {
      box2(
        bx0,
        .02,
        bz0,
        bx1,
        .3,
        bz1,
        WOOD,
        (a, bb) => (a > bx0 + .04 && a < bx1 - .04 && bb > .06 && bb < .26)
            ? e.rgb(96, 66, 44)
            : 0,
      );
    });
    k.part('flores', () {
      const FL = [
        [255, 143, 184],
        [255, 224, 112],
        [244, 88, 74],
        [250, 244, 226],
      ];
      const n = 9;
      for (var kk = 0; kk < n; kk++) {
        e.sphere(
          bx0 + .1 + kk * (bx1 - bx0 - .2) / (n - 1),
          .17,
          bz1 + .01 + (kk % 2) * .04,
          .08,
          const [64, 128, 60],
          'rough',
        ); // leaves
      }
      for (var kk = 0; kk < n; kk++) {
        e.sphere(
          bx0 + .1 + kk * (bx1 - bx0 - .2) / (n - 1),
          .16 + (kk % 2) * .03,
          bz1 + .13 + (kk % 3) * .02,
          .075,
          FL[(kk * 5 + 1) % 4],
          'solid',
        ); // blooms
      }
    });
    // a pot with a plant, left of the door
    k.part('maceta', () {
      final x = POT[0], y = POT[1];
      k.drum(x, y, 0, .3, .17, const [
        200,
        104,
        66,
      ], (a, bb) => e.rgb(92, 64, 44));
      for (num z = .25; z <= .3; z += PP) {
        for (num t = 0; t < 6.3; t += .3) {
          e.plot(
            x + math.cos(t) * .175,
            y + math.sin(t) * .175,
            z,
            e.rgb(224, 130, 86),
          ); // the rim
        }
      }
      for (final l in const [
        [0, 0, .5, .17],
        [-.12, .05, .46, .12],
        [.1, -.06, .54, .13],
        [.02, .12, .44, .11],
      ]) {
        e.sphere(x + l[0], y + l[1], l[2], l[3], LEAF, 'rough');
      }
      for (final (dx, dy, dz, c) in const <(double, double, double, List<int>)>[
        (-.08, .1, .62, [244, 88, 74]),
        (.12, .02, .66, [255, 224, 112]),
        (.0, -.1, .72, [255, 143, 184]),
      ]) {
        e.sphere(x + dx, y + dy, dz, .055, c, 'solid');
      }
      e.castShadow(x, y, .35, .2);
    });
  }

  // the scale is drawn straight into the picture's pixels (a disc turned to the camera is a circle on it, a dish seen
  // from above an ellipse), so its rim, its two marks and its chains are exactly one pixel wide. d: how far from the
  // camera, in the engine's depth

  // colmado-fuera.js: spot
  void spot(int ix, int iy, double d, int c) {
    if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
    final i = iy * W + ix;
    if (d <= e.zb[i]) return;
    e.zb[i] = d;
    e.pix[i] = c;
  }

  // colmado-fuera.js: pline. A one-pixel line, fn(k) the colour of the k-th pixel
  void pline(
    int x0,
    int y0,
    int x1,
    int y1,
    double d,
    int Function(int kk) fn,
  ) {
    final n = math.max((x1 - x0).abs(), (y1 - y0).abs());
    final nn = n == 0 ? 1 : n;
    for (var kk = 0; kk <= n; kk++) {
      spot(
        (x0 + (x1 - x0) * kk / nn + .5).floor(),
        (y0 + (y1 - y0) * kk / nn + .5).floor(),
        d,
        fn(kk),
      );
    }
  }

  // colmado-fuera.js: dial
  (int, int, double) dial(CfDisc d, String? needle) {
    final p = e.project(d.x, d.y, d.z),
        cx = p.sx.floor(),
        cy = p.sy.floor(),
        R = d.r,
        dd = p.d + .3;
    final RIM = e.rgb(58, 58, 70),
        FACE = e.rgb(252, 250, 244),
        SHADE = e.rgb(222, 220, 214),
        TICK = e.rgb(40, 40, 52),
        RED = e.rgb(224, 40, 40);
    for (var dy = -8; dy <= 8; dy++) {
      for (var dx = -8; dx <= 8; dx++) {
        final r = math.sqrt(dx * dx + dy * dy);
        if (r > R) continue;
        var c = r > R - 1.1
            ? RIM
            : (dx + dy > 4 && r > R - 2.6)
            ? SHADE
            : FACE;
        if (r <= R - 1.1) {
          // 3 o'clock: half a pound
          if (dy == 0 && dx >= 3 && dx <= 5) c = TICK;
          if (dx == 0 && dy >= 3 && dy <= 5) c = TICK; // 6 o'clock: a pound
          if (needle != null) {
            final nxy = needle == 'medio'
                ? const [1, 0]
                : needle == 'libra'
                ? const [0, 1]
                : const [0, -1];
            for (var kk = 0; kk <= 5; kk++) {
              if (dx == nxy[0] * kk && dy == nxy[1] * kk) c = RED;
            }
            if (dx == 0 && dy == 0) c = TICK;
          }
        }
        spot(cx + dx, cy + dy, dd, c);
      }
    }
    return (cx, cy, dd);
  }

  // colmado-fuera.js: pan. A shallow dish seen from above: lighter inside, a darker rim, a foot
  (int, int) pan(CfDisc P, double dd) {
    final p = e.project(P.x, P.y, P.z),
        cx = p.sx.floor(),
        cy = p.sy.floor(),
        a = P.r * e.S,
        bb = a * e.SIN;
    final RIM = e.rgb(88, 92, 106),
        SIDE = e.rgb(64, 66, 80),
        IN = e.rgb(214, 218, 228),
        IN_D = e.rgb(176, 182, 196),
        RIM_L = e.rgb(150, 154, 168);
    for (var dy = 4; dy <= 5; dy++) {
      for (var dx = -3; dx <= 3; dx++) {
        spot(cx + dx, cy + dy, dd, SIDE); // the foot
      }
    }
    for (var lift = 2; lift >= 0; lift--) {
      for (var dy = -5; dy <= 5; dy++) {
        for (var dx = -8; dx <= 8; dx++) {
          final ex = dx / a, ey = dy / bb, en = ex * ex + ey * ey;
          if (en > 1.12) continue;
          if (lift != 0) {
            if (dy > 0) spot(cx + dx, cy + dy + lift, dd, SIDE);
            continue;
          } // the dish's outer wall, below its rim
          spot(
            cx + dx,
            cy + dy,
            dd,
            en > .66 ? (dy > 0 ? RIM_L : RIM) : (dy < 0 ? IN_D : IN),
          );
        }
      }
    }
    return (cx, cy);
  }

  // colmado-fuera.js: scale
  void scale(CfOpt o) {
    final px = POLE[0],
        py = POLE[1],
        x = PESA_DIAL.x,
        y = PESA_DIAL.y,
        CHn = [e.rgb(120, 124, 138), e.rgb(58, 60, 74)];
    b.block(px - .04, py - .04, 0, px + .04, py + .04, 2.35, METAL); // the pole
    for (num a = x; a <= px; a += PP) {
      for (num h = 0; h <= .05; h += PP) {
        e.plot(a, y, 2.3 + h, rgbOf(METAL)); // the arm
      }
    }
    final (cx, cy, dd) = dial(
      PESA_DIAL,
      o.aguja == '0' || o.aguja == 'medio' || o.aguja == 'libra'
          ? o.aguja
          : null,
    );
    final top = e.project(x, y, 2.3).sy.floor() + 1;
    for (var r = top; r <= cy - 7; r++) {
      spot(
        cx,
        r,
        dd,
        CHn[(r - top) % 2],
      ); // the short chain from the arm to the dial
    }
    final (pcx, pcy) = pan(PESA_PLATO, dd);
    // three thin chains from the dial's bottom spread down to the pan's rim: left, right and the back
    for (final ee in const [
      [-7, 0],
      [7, 0],
      [0, -4],
    ]) {
      pline(cx, cy + 7, pcx + ee[0], pcy + ee[1], dd + .1, (kk) => CHn[kk % 2]);
    }
  }

  // colmado-fuera.js: stand
  void stand(CfOpt o) {
    k.part('puesto', () {
      // the body under the slanted top, on four short legs; its front boards, the ledge on two small brackets
      for (num a = TX0; a <= TX1; a += PX) {
        for (num z = LEG; z <= TZ0; z += PZ) {
          e.plot(
            a,
            TY1,
            z,
            b.shade(WOOD, ((a - TX0) % .5) < .04 ? 1.2 : 2.3, a, z),
          );
        }
      }
      for (num bb = TY0; bb <= TY1; bb += PX) {
        for (num z = LEG; z <= tableZ(bb); z += PZ) {
          e.plot(TX1, bb, z, b.shade(WOOD, 1.3, bb, z));
        }
      }
      for (final l in const [
        [TX0, TY0],
        [TX1 - .12, TY0],
        [TX0, TY1 - .12],
        [TX1 - .12, TY1 - .12],
      ]) {
        b.block(l[0], l[1], 0, l[0] + .12, l[1] + .12, LEG + .03, LEGC);
      }
      b.block(TX0 - .05, TY1, LZ - .08, TX1 + .05, LY1, LZ, WOOD_L, const [
        224,
        196,
        150,
      ]);
      for (final bx in const [TX0 + .1, TX1 - .2]) {
        b.block(bx, TY1, LZ - .2, bx + .08, LY1 - .06, LZ - .08, WOOD_D);
      }
      // the slanted top: a dark bed, the bins' rims
      for (num a = TX0; a <= TX1; a += PA) {
        for (num bb = TY0; bb <= TY1; bb += PA) {
          final rim =
              ((a - TX0) % BW) < .05 ||
              bb < TY0 + .06 ||
              bb > TY1 - .06 ||
              a > TX1 - .05;
          e.plot(
            a,
            bb,
            tableZ(bb),
            rim ? e.rampOf(WOOD_L)[3] : e.rgb(104, 72, 48),
          );
        }
      }
      for (num a = TX0; a <= TX1; a += PX) {
        for (num z = TZ1; z <= TZ1 + .16; z += PZ) {
          e.plot(a, TY0, z, b.shade(WOOD_L, 2.4, a, z)); // the back board
        }
      }
    });
    for (final kk in BINS) {
      k.part(kk, () => bin(kk));
    }
    k.part('pesa', () => scale(o));
    k.part('guineos', () {
      const x = 6.1, y = AY - .02, zt = AZ0 - .22;
      for (num z = zt - .22; z <= zt; z += PP) {
        e.plot(x, y, z, e.rgb(120, 92, 50));
      }
      for (var kk = 0; kk < 5; kk++) {
        e.sphere(
          x - .18 + kk * .09,
          y,
          zt - .28 - (kk - 2).abs() * .03,
          .075,
          const [244, 206, 70],
          'solid',
        );
        e.sphere(
          x - .15 + kk * .075,
          y + .01,
          zt - .43 - (kk - 2).abs() * .02,
          .07,
          const [236, 196, 60],
          'solid',
        );
      }
    });
    k.part('cajon', () {
      final x0 = CRATE[0],
          y0 = CRATE[1],
          x1 = CRATE[2],
          y1 = CRATE[3],
          h = CRATE[4];
      b.block(x0, y0, 0, x1, y1, h, WOOD_L, const [214, 176, 120]);
      for (num a = x0; a <= x1; a += ST) {
        for (final z in [h * .33, h * .66]) {
          e.plot(a, y1 + .01, z, e.rampOf(WOOD)[1]);
        }
      }
    });
    k.part(
      'poste',
      () => b.block(
        POST[0] - .05,
        POST[1] - .05,
        0,
        POST[0] + .05,
        POST[1] + .05,
        1.15,
        WOOD,
      ),
    );
  }

  /* ---------- the bins: four (verduras) or three (frutas) on one table, each inside its own slice of the top ---------- */
  // A kind is drawn pixel by pixel in the picture, like the scale: a stamp of one-pixel cells standing on a world point
  // of the bed (its bottom middle on that point), so it can be bigger than a shaded ball and carry what makes it itself.
  // A stamp is a little nearer the camera than the bed under it (SPR), so it beats the rims and what lies behind it;
  // nearer stamps beat farther ones
  static const double SPR = .14;
  Map<String, int> pal(Map<String, List<int>> m) => {
    for (final en in m.entries) en.key: rgbOf(en.value),
  };

  // colmado-fuera.js: draw. fn(c, r) -> a colour or 0, for the cell c across and r down (r = h - 1 is the feet)
  void draw(
    int w,
    int h,
    num x,
    num y,
    num z,
    int Function(int c, int r) fn, [
    num dd = 0,
  ]) {
    final p = e.project(x, y, z),
        cx = p.sx.floor() - (w >> 1),
        cy = p.sy.floor() - (h - 1),
        d = p.d + SPR + dd;
    for (var r = 0; r < h; r++) {
      for (var c = 0; c < w; c++) {
        final q = fn(c, r);
        if (q != 0) spot(cx + c, cy + r, d, q);
      }
    }
  }

  // colmado-fuera.js: stamp
  void stamp(
    List<String> rows,
    Map<String, int> P,
    num x,
    num y,
    num z, [
    num dd = 0,
  ]) => draw(rows[0].length, rows.length, x, y, z, (c, r) {
    final row = rows[r];
    return c < row.length ? (P[row[c]] ?? 0) : 0;
  }, dd);

  // colmado-fuera.js: lay. The spot of a bin's picture at (u, v) from 0 to 1 over the room left inside its rims for a
  // thing `half` wide (world units)
  List<double> lay(String kk, num half, num u, num v) {
    final i = BINS.indexOf(kk),
        x0 = TX0 + BW * i + .07 + half,
        x1 = TX0 + BW * (i + 1) - .07 - half,
        y0 = TY0 + .09 + half,
        y1 = TY1 - .09 - half;
    return [x0 + (x1 - x0) * u, y0 + (y1 - y0) * v];
  }

  double jit(num n, num a) => (e.hash(n, 7) - .5) * a;

  // tomatoes: round and red, a green star of a stem on top
  late final Map<String, int> P_TOM = pal(const {
    'R': [218, 50, 46],
    'L': [250, 134, 108],
    'D': [164, 34, 46],
    'K': [110, 26, 44],
    'g': [84, 156, 62],
    'G': [146, 210, 88],
    's': [40, 88, 48],
  });
  static const List<List<String>> S_TOM = [
    ['...s...', '.gGGGg.', 'RLRgRRD', 'LRRRRRD', 'RRRRRDD', '.RDDDD.'],
    ['...s...', '.gGGGg.', 'RRgRRRD', 'RLRRRRD', 'RRRRRDD', '.RDDDD.'],
  ];
  // yellow onions: round with a pointed top, golden-brown papery skin with one lighter stripe, a tuft of dry stem above,
  // a few roots below
  late final Map<String, int> P_ONI = pal(const {
    'y': [236, 182, 86],
    'Y': [208, 148, 64],
    'S': [252, 226, 134],
    'D': [156, 102, 50],
    'K': [106, 68, 42],
    't': [232, 208, 142],
    'T': [128, 88, 52],
    'r': [222, 200, 150],
  });
  static const List<String> S_ONI = [
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
  late final Map<String, int> P_ONC = pal(const {
    'Y': [208, 148, 64],
    'D': [156, 102, 50],
    'W': [254, 250, 238],
    'V': [186, 150, 106],
    't': [232, 208, 142],
  });

  // colmado-fuera.js: onionCut
  void onionCut(num x, num y, num z) {
    draw(9, 11, x, y, z, (c, r) {
      final dx = c - 4, dy = r - 6.5;
      final ax = dx * (dy < 0 ? 1 + .2 * -dy : 1),
          ay = dy * (dy < 0 ? .82 : 1),
          q = math.sqrt(ax * ax + ay * ay);
      if (q > 4.5) return r == 0 && c == 4 ? P_ONC['t']! : 0;
      if (q > 3.5) return dx + dy > 2 ? P_ONC['D']! : P_ONC['Y']!;
      return q > 2.6
          ? P_ONC['W']!
          : q > 1.7
          ? P_ONC['V']!
          : q > .8
          ? P_ONC['W']!
          : P_ONC['V']!;
    });
  }

  // potatoes: lumpy brown ovals with two or three darker eyes, dull (no light spot)
  late final Map<String, int> P_POT = pal(const {
    'p': [190, 160, 118],
    'P': [168, 136, 96],
    'D': [128, 100, 72],
    'd': [96, 74, 56],
    'e': [84, 62, 44],
  });
  static const List<List<String>> S_POT = [
    ['...ppPP.', '.pPPPPPD', 'pPePPPPD', 'PPPPPeDD', 'PePPDDD.', '.dDDdd..'],
    ['..pPPP..', '.pPPPePD', 'PPePPPPD', 'PPPPPDDD', '.DPeDDD.', '..dddd..'],
    ['.ppPP...', 'pPPPPPD.', 'PPPePPPD', '.PPPPPeD', '.dDPDDD.', '...dddd.'],
  ];
  // plantains: two big hands of long curved green fingers, each hand joined at a dark stem, each finger fat in the middle
  // and ending in a dark tip. A finger is a curve in world space along x (its ends lifted, bowed a little), painted in
  // pixels: lit on its top edge, dark on its lower, up to 4 px thick
  late final Map<String, int> P_PLA = pal(const {
    'G': [154, 208, 86],
    'g': [108, 166, 62],
    'd': [56, 100, 50],
    'T': [44, 42, 28],
    'S': [58, 40, 26],
    's': [170, 130, 78],
  });

  // colmado-fuera.js: hand. The stem at (xs, ys) on the bed; n fingers run along +x, `gap` apart along y at the stem, `fan`
  // more at each tip
  void hand(
    num xs,
    num ys,
    int n,
    num L,
    num gap,
    num fan,
    num lift,
    num layZ,
  ) {
    for (var i = 0; i < n; i++) {
      final f = i - (n - 1) / 2,
          y0 = ys + i * gap,
          y1 = y0 + f * fan,
          len = L * (1 - .05 * f.abs());
      for (num t = 0; t <= 1.0001; t += .006) {
        final x = xs + len * t,
            y = y0 + (y1 - y0) * t + .06 * math.sin(t * math.pi),
            tt = 2 * t - 1,
            z = tableZ(y) + .1 + layZ + lift * (tt * tt);
        final p = e.project(x, y, z),
            sx = p.sx.floor(),
            sy = p.sy,
            d = p.d + SPR + .02 * i;
        final w =
                1.6 +
                2.2 *
                    math
                        .pow(math.sin(math.pi * math.min(1, t * 1.08)), .6)
                        .toDouble(),
            top = (sy - w / 2 + .01 + .5).floor(),
            bot = (sy + w / 2 - .01 + .5).floor();
        for (var Y = top; Y <= bot; Y++) {
          spot(
            sx,
            Y,
            d,
            t > .93
                ? P_PLA['T']!
                : Y == top
                ? P_PLA['G']!
                : (Y == bot && bot > top)
                ? P_PLA['d']!
                : P_PLA['g']!,
          );
        }
      }
    }
    for (var i = 0; i < n; i++) {
      // the stem: a dark block across the roots, lit on its top edge
      final y0 = ys + i * gap,
          p = e.project(xs - .03, y0, tableZ(y0) + .1 + layZ + lift),
          sx = p.sx.floor(),
          sy = p.sy.floor();
      for (var c = 0; c < 3; c++) {
        for (var kk = -1; kk <= 0; kk++) {
          spot(
            sx - c,
            sy + kk,
            p.d + SPR + .02 * n + .05,
            kk == -1 ? P_PLA['s']! : P_PLA['S']!,
          );
        }
      }
    }
  }

  // avocados: dark green pears (a round bottom, a narrow neck) with a light spot, 8 x 10; and one cut in half and open
  late final Map<String, int> P_AGU = pal(const {
    'a': [96, 152, 74],
    'A': [62, 112, 58],
    'H': [196, 234, 154],
    'D': [38, 76, 50],
    'K': [26, 52, 42],
  });
  static const List<List<String>> S_AGU = [
    [
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
    ],
    [
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
    ],
  ];
  late final Map<String, int> P_AGC = pal(const {
    'skin': [34, 66, 42],
    'rim': [96, 150, 58],
    'fl': [208, 224, 118],
    'fh': [232, 238, 158],
    'st': [112, 72, 42],
    'sl': [170, 118, 72],
    'sd': [76, 48, 32],
  });

  // colmado-fuera.js: avocadoCut
  void avocadoCut(num x, num y, num z) {
    draw(11, 12, x, y, z, (c, r) {
      final px = c + .5 - 5.5, py = r + .5;
      final a1 = px / 5,
          b1 = (py - 7.3) / 4.7,
          a2 = px / 3.1,
          b2 = (py - 3.5) / 3.4;
      final q1 = math.sqrt(a1 * a1 + b1 * b1),
          q2 = math.sqrt(a2 * a2 + b2 * b2),
          q = math.min(q1, q2);
      if (q > 1) return 0;
      final dep = 1 - q; // how far in from the skin, 0 to 1
      if (dep < .17) return P_AGC['skin']!;
      final sx = px, sy = py - 8.1, sr = math.sqrt(sx * sx + sy * sy);
      if (sr < 2.3) {
        return sr > 1.5 && sx + sy > 1.2
            ? P_AGC['sd']!
            : (sx < -.2 && sy < -.2 && sr > .4)
            ? P_AGC['sl']!
            : P_AGC['st']!; // the stone
      }
      return dep < .3
          ? P_AGC['rim']!
          : dep < .46
          ? P_AGC['fl']!
          : P_AGC['fh']!;
    });
  }

  // pineapples (15 x 20, a body 13 wide): a golden-orange oval with a dark diamond criss-cross, a tall spiky crown of
  // seven leaves
  late final Map<String, int> P_PIN = {
    'hi': e.rgb(252, 204, 90),
    'mid': e.rgb(240, 160, 52),
    'lo': e.rgb(206, 116, 42),
    'dk': e.rgb(150, 84, 40),
    'hiL': e.rgb(150, 78, 24),
    'midL': e.rgb(128, 64, 22),
    'loL': e.rgb(104, 52, 26),
    'dkL': e.rgb(80, 40, 28),
  };
  late final List<int> P_PIN_lv = [
    e.rgb(122, 196, 86),
    e.rgb(84, 156, 70),
    e.rgb(54, 120, 62),
    e.rgb(40, 94, 56),
  ];
  static const List<List<double>> CROWN = [
    [.8, 5.4],
    [2.9, 2.8],
    [5.2, 1.0],
    [7.5, .2],
    [9.8, 1.0],
    [12.1, 2.8],
    [14.2, 5.4],
  ]; // the seven leaves' tips

  // colmado-fuera.js: pineapple
  void pineapple(num x, num y, num z) {
    const BX = 7.5, BY = 14.6, HW = 6.5, HH = 5.5;
    draw(15, 20, x, y, z, (c, r) {
      final px = c + .5,
          py = r + .5,
          nx = (px - BX) / HW,
          ny = (py - BY) / HH,
          nn = nx * nx + ny * ny;
      if (nn <= 1) {
        final l = -.55 * nx - .6 * ny + .58 * math.sqrt(1 - nn),
            band = l > .78
                ? 'hi'
                : l > .5
                ? 'mid'
                : l > .2
                ? 'lo'
                : 'dk';
        final i = c - 7, j = r - 14;
        int m(int kk) => ((kk % 4) + 4) % 4;
        if (m(i + j) == 0 || m(i - j) == 0) return P_PIN['${band}L']!;
        return m(i + j) == 2 && m(i - j) == 2 && band != 'dk'
            ? P_PIN['hi']!
            : P_PIN[band]!;
      }
      var best = 9; // a leaf: the pixel is within its width of the line from the crown's foot to its tip
      for (var kk = 0; kk < 7; kk++) {
        final tx = CROWN[kk][0], ty = CROWN[kk][1];
        final bx = BX + (kk - 3) * .9,
            by = 10.6 - (kk == 3 ? 0 : 0),
            ex = tx - bx,
            ey = ty - by,
            len2 = ex * ex + ey * ey;
        final t = e.clamp<double>(
              ((px - bx) * ex + (py - by) * ey) / len2,
              0,
              1,
            ),
            qx = px - bx - ex * t,
            qy = py - by - ey * t,
            dist = math.sqrt(qx * qx + qy * qy);
        if (dist <= 1.05 * (1 - t) + .42) {
          best = math.min(best, (kk - 3).abs());
        }
      }
      return best < 9 ? P_PIN_lv[best] : 0;
    });
  }

  // limes: bright yellow-green rounds (6 x 6) with dark gaps between them; and one cut in half (9 x 9), pale, with
  // segment lines
  late final Map<String, int> P_LIM = pal(const {
    'l': [216, 244, 110],
    'L': [172, 218, 58],
    'D': [120, 172, 46],
    'd': [76, 120, 44],
  });
  static const List<String> S_LIM = [
    '.llLL.',
    'lllLLD',
    'lLLLLD',
    'LLLLDD',
    '.LLDD.',
    '..dd..',
  ];
  late final Map<String, int> P_LIC = pal(const {
    'skin': [78, 142, 40],
    'rind': [204, 228, 132],
    'fl': [172, 210, 80],
    'ln': [242, 251, 196],
  });

  // colmado-fuera.js: limeCut
  void limeCut(num x, num y, num z) {
    draw(9, 9, x, y, z, (c, r) {
      final dx = c - 4, dy = r - 4, q = math.sqrt(dx * dx + dy * dy);
      if (q > 4.4) return 0;
      if (q > 3.7) return P_LIC['skin']!;
      if (q > 3.0) return P_LIC['rind']!;
      if (q > .9 && (dx == 0 || dy == 0 || dx.abs() == dy.abs())) {
        return P_LIC['ln']!;
      }
      return P_LIC['fl']!;
    });
  }

  // colmado-fuera.js: bin
  void bin(String kk) {
    double bz(num y) => tableZ(y);
    void put(
      List<String> rows,
      Map<String, int> P,
      num h,
      num u,
      num v,
      int n,
    ) {
      final xy = lay(kk, h, u, v);
      stamp(rows, P, xy[0] + jit(n, .02), xy[1] + jit(n + 5, .02), bz(xy[1]));
    }

    if (kk == 'tomates') {
      const uv = [
        [0, 0],
        [.5, 0],
        [1, 0],
        [0, .5],
        [.33, .5],
        [.67, .5],
        [1, .5],
        [0, 1],
        [.5, 1],
        [1, 1],
      ];
      for (var n = 0; n < uv.length; n++) {
        put(S_TOM[n % 2], P_TOM, .135, uv[n][0], uv[n][1], n);
      }
    } else if (kk == 'cebollas') {
      const uv = [
        [0, 0],
        [.5, 0],
        [1, 0],
        [0, .5],
        [.33, .5],
        [.67, .5],
        [1, .5],
        [0, 1],
        [1, 1],
      ];
      for (var n = 0; n < uv.length; n++) {
        put(S_ONI, P_ONI, .135, uv[n][0], uv[n][1], n + 20);
      }
      final xy = lay(kk, .17, .5, .93);
      onionCut(xy[0], xy[1], bz(xy[1]));
    } else if (kk == 'papas') {
      const uv = [
        [0, 0],
        [.5, 0],
        [1, 0],
        [.1, .5],
        [.55, .5],
        [1, .5],
        [0, 1],
        [.5, 1],
        [1, 1],
      ];
      for (var n = 0; n < uv.length; n++) {
        put(S_POT[n % 3], P_POT, .154, uv[n][0], uv[n][1], n + 40);
      }
    } else if (kk == 'platanos') {
      final x0 = TX0 + BW * BINS.indexOf(kk);
      hand(x0 + .22, 1.16, 5, .8, .15, .07, .1, 0);
      hand(x0 + .26, 1.33, 4, .76, .15, .07, .1, .07);
    } else if (kk == 'aguacates') {
      const uv = [
        [0, 0],
        [.45, 0],
        [.2, .5],
        [.7, .5],
        [1, .45],
        [0, 1],
        [1, 1],
      ];
      for (var n = 0; n < uv.length; n++) {
        put(S_AGU[n % 2], P_AGU, .154, uv[n][0], uv[n][1], n + 60);
      }
      final xy = lay(kk, .2, .5, .95);
      avocadoCut(xy[0], xy[1], bz(xy[1]));
    } else if (kk == 'pinas') {
      final a = lay(kk, .29, 0, .22), bb = lay(kk, .29, 1, .52);
      pineapple(a[0], a[1], bz(a[1]));
      pineapple(bb[0], bb[1], bz(bb[1]));
    } else {
      // limones
      for (var j = 0; j < 3; j++) {
        for (var c = 0; c < (j == 1 ? 4 : 5); c++) {
          if (j == 2 && c == 2) continue;
          final xy = lay(kk, .115, j == 1 ? (c + .5) / 4 : c / 4, j / 2);
          stamp(
            S_LIM,
            P_LIM,
            xy[0] + jit(j * 7 + c, .02),
            xy[1] + jit(j * 7 + c + 3, .02),
            bz(xy[1]),
          );
        }
      }
      final xy = lay(kk, .17, .5, .9);
      limeCut(xy[0], xy[1], bz(xy[1]));
    }
  }

  /* ---------- the hand cart (story 44): a flat wooden bed, two spoked wheels, a long handle to the left, three slatted crates ---------- */

  // colmado-fuera.js: cart
  void cart() {
    k.part('carro', () {
      final cx = CART[0], cy = CART[1];
      final B0 = cx - .95,
          B1 = cx + 1.2,
          Y0 = cy - .42,
          Y1 = cy + .42,
          WX = cx - .5;
      const BZ0 = .5, BZ1 = .57, WR = .42;
      final Dk = e.rgb(46, 36, 30), WD = e.rampOf(WOOD), WL = e.rampOf(WOOD_L);
      // the handle: two long rails sloping down to the pavement, a cross-grip between their ends
      for (final s in const [-1, 1]) {
        e.capsule(
          [B0 + .05, cy + s * .3, BZ0 + .02],
          [B0 - .65, cy + s * .3, .1],
          .04,
          .04,
          (_) => WOOD,
          'solid',
        );
      }
      e.capsule(
        [B0 - .65, cy - .3, .1],
        [B0 - .65, cy + .3, .1],
        .04,
        .04,
        (_) => WOOD_D,
        'solid',
      );
      // the bed, in one pass: planks along its length with a dark seam between them; its edges
      for (num a = B0; a <= B1; a += PA) {
        for (num bb = Y0; bb <= Y1; bb += PA) {
          final kk = (bb - Y0) / .14;
          e.plot(
            a,
            bb,
            BZ1,
            (kk - kk.floor()) < .1 ? WD[1] : WD[3 - (kk.floor() % 2)],
          );
        }
      }
      for (num a = B0; a <= B1; a += PX) {
        for (num z = BZ0; z <= BZ1; z += PZ) {
          e.plot(a, Y1, z, WD[1]);
        }
      }
      for (num bb = Y0; bb <= Y1; bb += PX) {
        for (num z = BZ0; z <= BZ1; z += PZ) {
          e.plot(B1, bb, z, WD[0]);
        }
      }
      // the axle, and the wheels: a dark rim, eight spokes, a hub; the far wheel shows above the bed's back edge
      for (num y = cy - .5; y <= cy + .5; y += .02) {
        e.plot(WX, y, WR, Dk);
      }
      for (final s in const [-1, 1]) {
        final y = cy + s * .5;
        for (num th = 0; th < 6.283; th += .03) {
          for (final rd in const [
            [WR, 0],
            [WR, .04],
            [WR - .04, 0],
            [WR - .04, .04],
          ]) {
            e.plot(
              WX + math.cos(th) * rd[0],
              y + rd[1],
              WR + math.sin(th) * rd[0],
              e.rgb(58, 46, 40),
            );
          }
        }
        for (var sp = 0; sp < 8; sp++) {
          final th = sp / 8 * 6.283 + .2;
          for (num rr = .04; rr <= WR - .03; rr += .014) {
            for (final dy in const [0, .03]) {
              e.plot(
                WX + math.cos(th) * rr,
                y + dy,
                WR + math.sin(th) * rr,
                WL[sp % 2 != 0 ? 3 : 2],
              );
            }
          }
        }
        for (num a = -.05; a <= .05; a += .012) {
          for (num bb = -.05; bb <= .05; bb += .012) {
            if (a * a + bb * bb < .0025) {
              for (final dy in const [-.01, .03, .05]) {
                e.plot(WX + a, y + dy, WR + bb, Dk);
              }
            }
          }
        }
      }
      // three slatted crates on the bed, in front of the wheels: leaves, tomatoes, leaves
      const LV = [
            [78, 150, 62],
            [112, 184, 84],
            [56, 122, 54],
          ],
          TO = [226, 60, 50];
      const CHt = .3, CL = .38;
      for (var n = 0; n < 3; n++) {
        final ccx = cx + .1 + n * .44,
            x0 = ccx - CL / 2,
            x1 = ccx + CL / 2,
            y0 = cy - .36,
            y1 = cy + .36;
        const z0 = BZ1, z1 = BZ1 + CHt;
        bool gap(num z) {
          final s = (z - z0) / CHt;
          return (s > .22 && s < .37) || (s > .6 && s < .75);
        }

        for (num a = x0; a <= x1; a += PA * .6) {
          for (num z = z0; z <= z1; z += PP) {
            e.plot(
              a,
              y1,
              z,
              gap(z)
                  ? Dk
                  : (a < x0 + .04 || a > x1 - .04)
                  ? WD[2]
                  : b.shade(const [226, 188, 132], 2.7, a, z),
            );
          }
        }
        for (num bb = y0; bb <= y1; bb += PA * .6) {
          for (num z = z0; z <= z1; z += PP) {
            e.plot(
              x1,
              bb,
              z,
              gap(z) ? Dk : b.shade(const [226, 188, 132], 1.5, bb, z),
            );
          }
        }
        for (num a = x0; a <= x1; a += PA) {
          for (num bb = y0; bb <= y1; bb += PA) {
            e.plot(a, bb, z1, e.rgb(64, 46, 36));
          }
        }
        if (n == 1) {
          for (var j = 0; j < 3; j++) {
            for (var c = 0; c < 4; c++) {
              e.sphere(
                ccx - .1 + (j % 2) * .06 + (e.hash(j, c) - .5) * .03,
                y0 + .1 + c * .17,
                z1 + .04 + (j == 2 ? .08 : 0),
                .075,
                TO,
                'solid',
              );
            }
          }
        } else {
          for (var j = 0; j < 3; j++) {
            for (var c = 0; c < 3; c++) {
              e.sphere(
                ccx - .1 + (j % 2) * .08 + (c % 2) * .03,
                y0 + .1 + c * .25 + (j % 2) * .04,
                z1 + .02 + (j > 1 ? .1 : 0),
                .1,
                LV[(j + c + n) % 3],
                'rough',
              );
            }
          }
        }
      }
      for (var n = 0; n < 3; n++) {
        e.castShadow(cx + .1 + n * .44, cy, .8, .38);
      }
      e.castShadow(WX, cy + .5, .2, .35, 1, .2);
    });
  }

  // colmado-fuera.js: extras
  void extras(CfOpt o) {
    k.part('arbusto', () {
      // a bush at the building's far right end
      b.bush(WX1 + 1.5, .8, .55, const [96, 150, 70]);
      b.bush(WX1 + 2.1, .45, .4, LEAF);
    });
    if (o.carro) cart();
  }

  // colmado-fuera.js: skyPlan. Where the roof's far edge falls on the picture at column sx, and from it the horizon row and
  // the sun: the sun's disc sits on the far hills at that column, clear of the roof (morning: half risen behind the
  // hills; afternoon: whole, higher up)
  CfSkyPlan skyPlan(CfOpt o) {
    final R = o.hora == 'tarde' ? 11 : 10, sx = o.solX ?? W - 44;
    final p0 = e.project(WX0, DEEP, WH), edge = p0.sy + .5 * (sx - p0.sx);
    final cyM = edge - 10 * .5 - 6, cyT = math.max<num>(R + 8, cyM - 24);
    final HZ =
        (cyM + 13 + 6 * math.sin(sx * .029 + 1) + 3 * math.sin(sx * .083) + .5)
            .floor();
    return (HZ: HZ, sun: [sx, o.hora == 'tarde' ? cyT : cyM, R]);
  }

  // colmado-fuera.js: sky. The sky, screen space: bands, a sun, far hills
  int Function(int ix, int iy) sky(CfOpt o, num HZ) {
    final tarde = o.hora == 'tarde';
    final bands = tarde
        ? const [
            [236, 120, 70],
            [246, 156, 84],
            [250, 190, 110],
            [252, 214, 150],
            [254, 234, 190],
          ]
        : const [
            [80, 150, 236],
            [110, 176, 246],
            [150, 200, 252],
            [190, 222, 255],
            [226, 240, 255],
          ];
    final sun = skyPlan(o).sun, sx = sun[0], sy = sun[1], R = sun[2];
    final tones = tarde
        ? const [
            [250, 150, 60],
            [254, 190, 90],
            [255, 226, 150],
          ]
        : const [
            [246, 222, 130],
            [252, 238, 168],
            [255, 250, 212],
          ];
    final far = tarde
        ? const [
            [176, 120, 110],
            [206, 150, 130],
            [150, 100, 100],
          ]
        : const [
            [116, 170, 172],
            [156, 200, 198],
            [94, 150, 156],
          ];
    final near = tarde
        ? const [
            [120, 110, 90],
            [160, 140, 110],
            [100, 90, 80],
          ]
        : const [
            [78, 150, 104],
            [124, 196, 132],
            [62, 130, 90],
          ];
    return (ix, iy) {
      final h = k.skyHills(HZ, far, near, ix, iy);
      if (h != 0) return h;
      final d = k.skyDisc(sx, sy, R, tones, ix, iy);
      if (d != 0) return d;
      return k.skyBands(bands, 0, HZ, ix, iy);
    };
  }

  // colmado-fuera.js: build
  void build(CfOpt o) {
    BINS = SURTIDOS[o.surtido] ?? SURTIDOS['verduras']!;
    BW = (TX1 - TX0) / BINS.length;
    building(o);
    if (o.puesto) stand(o);
    extras(o);
    // shade: under the awning, and the awning's own shadow (to the right, like every shadow here). The first one's
    // strength (.6) is under 1: pp-engine.js stores it as 0, so it changes no pixel (castShadowJs keeps that rule)
    for (num x = AX0 + .3; x <= AX1 - .2; x += .45) {
      castShadowJs(e, x, .5, 1.0, .5, .6);
    }
    for (num x = AX0; x <= AX1 + .3; x += .35) {
      e.castShadow(x, AY, AZ0, .32, 1, .25);
    }
    if (o.puesto) {
      for (num x = TX0; x <= TX1; x += .4) {
        for (final y in const [TY0 + .2, (TY0 + TY1) / 2, TY1 - .1]) {
          e.castShadow(x, y, .85, .32); // the stand's
        }
      }
      for (num x = TX0; x <= TX1; x += .8) {
        e.castShadow(
          x,
          (TY0 + LY1) / 2,
          .06,
          .5,
          2,
          .1,
        ); // the dark under it, between the legs
      }
      for (num z = .3; z <= 2.2; z += .3) {
        e.castShadow(POLE[0], POLE[1], z, .1); // the pole's
      }
      e.castShadow(PESA_DIAL.x, PESA_DIAL.y, PESA_DIAL.z, .3); // the dial's
      e.castShadow((CRATE[0] + CRATE[2]) / 2, CRATE[3], .2, .4);
      for (num z = .3; z <= 1.1; z += .3) {
        e.castShadow(POST[0], POST[1], z, .1);
      }
    }
  }
}
