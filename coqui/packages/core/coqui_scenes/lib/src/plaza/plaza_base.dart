// Port of docs/proyecto/pixel/plaza-base.js: La plaza's kit (`PZ`), call for call: what the four scene sets of place 6
// share (plaza, reloj, quiosco, calendario), and what the kits of the places after it stand on (playa-base.js,
// fonda-base.js, casa-base.js, fuerte-base.js call its painters). Everything is laid out square to the picture, in u, v:
// u runs across the picture (to the right), v runs down it (towards the camera); x = (u + v) / R2, y = (v - u) / R2. A
// wall that faces the camera is a plane v = const, drawn pixel by pixel with set-kit's planeQuad ([PlazaBase.wall],
// [PlazaBase.flat], [PlazaBase.slope]: SetKit.planeQuad, one sample a pixel, the depth test of plot), so a picture, a
// numeral or a clock face on it keeps its shape. The file's names are kept, capitals included, so the port reads line for
// line against it (page 12, section 6): the lints on names are off.
//
// plaza-base.js leans on calle-base.js (`CL`) for three things: its grass painter, its tree and its sky by the hour. La
// calle's kit is ported by another builder at the same time (lib/src/calle/); the three pieces are ported here, call for
// call from calle-base.js, as [PlazaCl] (the same names: CL.grass, CL.tree, CL.sky, CL.LEAF, CL.LEAF_L, CL.NIGHT), so La
// plaza does not wait on La calle. Both ports draw the same pixels (each is tested against the JavaScript).
//
// First writer: order 58b (La plaza, scene `plaza`). The builders of reloj, quiosco and calendario, and of the kits of La
// playa, La fonda, La casa and El fuerte, copy it and add to it only by adding. The whole file is ported, also what
// plaza-set.html does not use (flat, slope's other callers, seatSide, flags, the lamp lit at night, the sky's ocaso and
// noche, the light of ocaso and noche), each tested against the JavaScript (test/plaza_kit_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// JavaScript's `%` (the remainder takes the sign of the dividend, as C's fmod).
double jsMod(num a, num b) => a.remainder(b).toDouble();

/// JavaScript's Math.round.
int jsRoundN(num v) => (v + 0.5).floor();

/// JavaScript's Math.hypot of two numbers, as V8 computes it (the largest first, the sum of the squares of each divided
/// by it with Kahan's compensation, its root times the largest), so a distance compared with a limit falls on the same
/// side as in the JavaScript.
double jsHypot(num a, num b) {
  final x = a.abs().toDouble(), y = b.abs().toDouble();
  if (x.isInfinite || y.isInfinite) return double.infinity;
  if (x.isNaN || y.isNaN) return double.nan;
  final max = math.max(x, y);
  if (max == 0) return 0;
  var sum = 0.0, compensation = 0.0;
  for (final v in [x, y]) {
    final n = v / max,
        summand = n * n - compensation,
        preliminary = sum + summand;
    compensation = (preliminary - sum) - summand;
    sum = preliminary;
  }
  return math.sqrt(sum) * max;
}

/// The colour of a painted face: a whole colour, or 0 (nothing: a hole).
typedef PzPaint = int Function(num u, num z);

/// A turned box's face painter (set-kit.js turnedBox's `fn`): s across, t in depth, z, the face; 0: shaded from the
/// box's colour.
typedef PzFace = int Function(num s, num t, num z, String face);

/// A sky or a far thing in it, screen space: the colour at a pixel, or 0 (nothing there).
typedef PzSky = int Function(int ix, int iy);

/// The three pieces of calle-base.js (`CL`) that plaza-base.js uses, call for call: the grass painter, the tree, the sky
/// by the hour, and the colours LEAF, LEAF_L, TRUNK. [NIGHT] is calle-base.js's `api.NIGHT` (calendario-set.html sets
/// `PZ.NIGHT = CL.NIGHT`); none of these three pieces reads it.
class PlazaCl {
  PlazaCl(this.k) : e = k.e, b = k.b;

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  int get H => e.H;

  // calle-base.js: PZ (the sampling step of a face, up)
  static const double PZ = .035;

  // calle-base.js: LEAF, LEAF_L, TRUNK
  static const List<int> LEAF = [74, 134, 62],
      LEAF_L = [112, 176, 84],
      TRUNK = [120, 84, 56];

  // calle-base.js: api.NIGHT
  bool NIGHT = false;

  // calle-base.js: grass
  int grass(num x, num y, int ix, int iy) {
    final g =
        e.GRASS[e.clamp(
          ((.3 + e.noise(x * .7, y * .7) * .7 + (e.hash(ix, iy) - .5) * .3) * 4)
              .floor(),
          0,
          3,
        )];
    return e.rgb(g[0], g[1], g[2]);
  }

  // calle-base.js: tree
  /// A tree: a trunk and a crown of leaf balls.
  void tree(num x, num y, num h, num r, [List<num>? c, List<num>? c2]) {
    final cc = c ?? LEAF, cc2 = c2 ?? LEAF_L;
    for (num z = 0; z <= h; z += PZ) {
      for (num t = 0; t < 6.3; t += .25) {
        e.plot(
          x + math.cos(t) * .13,
          y + math.sin(t) * .13,
          z,
          b.shade(TRUNK, 1.4 + math.cos(t - .8), t, z),
        );
      }
    }
    const B = [
      [0, 0, 0, 1],
      [-.55, .1, -.15, .72],
      [.5, -.15, -.1, .74],
      [.1, .5, -.25, .66],
      [-.15, -.5, .1, .68],
      [.3, .3, .35, .6],
      [-.35, -.2, .4, .58],
    ];
    for (final q in B) {
      final dx = q[0], dy = q[1], dz = q[2], kk = q[3];
      e.sphere(
        x + dx * r,
        y + dy * r,
        h + r * .7 + dz * r,
        r * kk,
        kk > .7 ? cc : cc2,
        'rough',
      );
    }
    e.castShadow(x, y, h, r * 1.2);
    e.castShadow(x + .2, y, h + .4, r);
  }

  // calle-base.js: sky
  /// The sky, screen space: bands by hour and a sun; returns the skyFill function. sun: [sx, sy, r] or null.
  PzSky sky(String hora, [List<num>? sun]) {
    const bands = <String, List<List<int>>>{
      'temprano': [
        [250, 196, 150],
        [252, 214, 170],
        [250, 230, 196],
        [226, 236, 244],
        [190, 222, 250],
      ],
      'manana': [
        [80, 150, 236],
        [110, 176, 246],
        [150, 200, 252],
        [190, 222, 255],
        [226, 240, 255],
      ],
      'tarde': [
        [236, 120, 70],
        [246, 156, 84],
        [250, 190, 110],
        [252, 214, 150],
        [254, 234, 190],
      ],
      'noche': [
        [44, 46, 96],
        [70, 62, 120],
        [120, 84, 130],
        [190, 110, 110],
        [236, 150, 96],
      ],
      'gris': [
        [120, 128, 144],
        [144, 152, 166],
        [170, 178, 190],
        [196, 202, 212],
        [220, 224, 230],
      ],
    };
    final B = bands[hora];
    final T = hora == 'tarde' || hora == 'noche'
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
    return (ix, iy) {
      if (sun != null) {
        final d = k.skyDisc(sun[0], sun[1], sun[2], T, ix, iy);
        if (d != 0) return d;
      }
      return k.skyBands(
        B ??
            const [
              [150, 200, 252],
            ],
        0,
        H,
        ix,
        iy,
      );
    };
  }
}

/// Port of plaza-base.js (`PZ`). World (S = 26): u across the picture, v down it; one u is 26 px across, one v is 13 px
/// down, one z is 22.5 px up. Everything that moves is a sprite: people, the dog, pigeons, cards, what is carried, the
/// hands of the clock. [NIGHT] is the file's `api.NIGHT`: the lamps are lit ([lamp]).
class PlazaBase {
  PlazaBase(this.k) : e = k.e, b = k.b, CL = PlazaCl(k);

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  /// calle-base.js's three pieces this kit uses.
  final PlazaCl CL;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;

  // plaza-base.js: A
  static const double A = -math.pi / 4;

  // plaza-base.js: uv, xy
  /// The u, v of a world point x, y.
  List<double> uv(num x, num y) => [(x - y) / R2, (x + y) / R2];

  /// The world x, y of u, v.
  List<double> xy(num u, num v) => [(u + v) / R2, (v - u) / R2];

  // plaza-base.js: STONE, STONE_D, WOOD, WOOD_D, IRON, CREAM, OCHRE, TILE, EARTH, WHITE
  static const List<int> STONE = [214, 204, 186],
      STONE_D = [176, 166, 150],
      WOOD = [150, 104, 62],
      WOOD_D = [104, 72, 48],
      IRON = [60, 64, 76],
      CREAM = [248, 238, 212],
      OCHRE = [236, 190, 112],
      TILE = [204, 98, 72],
      EARTH = [112, 82, 60],
      WHITE = [250, 248, 240];

  // plaza-base.js: api.NIGHT
  bool NIGHT = false;

  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  /* ---- the ground ---- */

  // plaza-base.js: paving
  /// The square's paving: big stone tiles, every other one a shade darker, thin joints.
  int paving(num u, num v, int ix, int iy) {
    const K = 1.0;
    final a = jsMod(u + 60.5, K) / K, bb = jsMod(v + 60, K) / K;
    if (a < .045 || bb < .085) return e.rgb(186, 174, 154);
    final cu = (u + 60.5).floor(),
        cv = (v + 60).floor(),
        n = e.hash(cu * 7, cv * 13) * 8,
        sp = e.hash(ix, iy) < .035 ? 12 : 0;
    final c = ((cu + cv) & 1) != 0
        ? const [228, 216, 192]
        : const [238, 228, 206];
    return e.rgb(c[0] - n - sp, c[1] - n - sp, c[2] - n - sp);
  }

  // plaza-base.js: grass
  int grass(num u, num v, int ix, int iy) {
    final p = xy(u, v);
    return CL.grass(p[0], p[1], ix, iy);
  }

  /* ---- painters, square to the picture ---- */

  // plaza-base.js: P
  List<double> P(num u, num v, [num z = 0]) => k.UVW(u, v, z);

  // plaza-base.js: box
  /// A box: middle (u, v), half-width hw across, half-depth hd; fn(s, t, z, face) as turnedBox ('front' faces the camera).
  void box(
    num u,
    num v,
    num z0,
    num z1,
    num hw,
    num hd,
    List<num> c, [
    PzFace? fn,
  ]) {
    final p = xy(u, v);
    k.turnedBox(p[0], p[1], z0, z1, hw, hd, A, c, fn);
  }

  // plaza-base.js: wall
  /// A wall that faces the camera, at v, from u0 to u1 and z0 to z1: fn(u, z) gives the colour (0: a hole).
  void wall(num u0, num u1, num v, num z0, num z1, PzPaint fn) {
    k.planeQuad(
      P(u0, v, z0),
      [(u1 - u0) / R2, -(u1 - u0) / R2, 0],
      [0, 0, z1 - z0],
      (a, bb) => fn(u0 + a * (u1 - u0), z0 + bb * (z1 - z0)),
    );
  }

  // plaza-base.js: flat
  /// A flat top at z: fn(u, v).
  void flat(num u0, num v0, num u1, num v1, num z, PzPaint fn) {
    k.planeQuad(
      P(u0, v0, z),
      [(u1 - u0) / R2, -(u1 - u0) / R2, 0],
      [(v1 - v0) / R2, (v1 - v0) / R2, 0],
      (a, bb) => fn(u0 + a * (u1 - u0), v0 + bb * (v1 - v0)),
    );
  }

  // plaza-base.js: slope
  /// A slope that rises away from the camera (a roof seen from the front): from (v0, z0) at its near edge to (v1, z1)
  /// at its far edge. fn(u, b): b from 0 at the near edge to 1 at the far edge.
  void slope(num u0, num u1, num v0, num z0, num v1, num z1, PzPaint fn) {
    k.planeQuad(
      P(u0, v0, z0),
      [(u1 - u0) / R2, -(u1 - u0) / R2, 0],
      [(v1 - v0) / R2, (v1 - v0) / R2, z1 - z0],
      (a, bb) => fn(u0 + a * (u1 - u0), bb),
    );
  }

  // plaza-base.js: lit, dim, up
  int lit(List<num> c, [num a = 0, num bb = 0]) => b.shade(c, 2.4, a, bb);
  int dim(List<num> c, [num a = 0, num bb = 0]) => b.shade(c, 1.5, a, bb);
  int up(List<num> c, [num a = 0, num bb = 0]) => b.shade(c, 3.4, a, bb);

  // plaza-base.js: post
  void post(num u, num v, num z0, num z1, num r, List<num> c) {
    final p = xy(u, v), x = p[0], y = p[1];
    k.drum(x, y, z0, z1, r, c);
    for (num z = z0 + .1; z <= z1; z += .1) {
      e.castShadow(x, y, z, r + .03);
    }
  }

  // plaza-base.js: ball
  void ball(num u, num v, num z, num r, List<num> c, [String mode = 'rough']) {
    final p = xy(u, v);
    e.sphere(p[0], p[1], z, r, c, mode);
  }

  // plaza-base.js: shadow
  void shadow(num u, num v, num z, num r) {
    final p = xy(u, v);
    e.castShadow(p[0], p[1], z, r);
  }

  // plaza-base.js: tree
  void tree(num u, num v, num h, num r, [List<num>? c, List<num>? c2]) {
    final p = xy(u, v);
    CL.tree(p[0], p[1], h, r, c, c2);
  }

  /* ---- pieces ---- */

  // plaza-base.js: seat
  /// A seat, long across the picture, its back at the far side.
  void seat(
    num u,
    num v,
    num hw, [
    bool back = true,
    List<num> c = const [190, 138, 86],
  ]) {
    const L = [214, 164, 104];
    // the seat: planks
    box(
      u,
      v,
      .36,
      .46,
      hw,
      .26,
      L,
      (s, t, z, face) =>
          face == 'top' && jsMod(t + .26, .17) < .03 ? e.rampOf(c)[2] : 0,
    );
    if (back) {
      // the back: three slats with gaps, on uprights
      for (final z in const [.58, .8, 1.02]) {
        wall(
          u - hw,
          u + hw,
          v - .24,
          z,
          z + .15,
          (a, bb) => b.shade(L, 2.6, a * 3, bb * 9, .3),
        );
      }
      for (
        num du = -hw + .08;
        du <= hw - .05;
        du += (2 * hw - .16) / math.max(2, jsRoundN(hw * 2 / 1.1))
      ) {
        box(u + du, v - .27, .46, 1.17, .045, .03, IRON);
      }
    }
    for (final du in [-hw + .04, hw - .04]) {
      box(u + du, v - .02, .46, .74, .04, .04, IRON);
      box(u + du, v - .02, .74, .8, .06, .26, c);
    } // arm rests
    for (final du in [-hw + .15, hw - .15]) {
      box(u + du, v, 0, .36, .07, .22, IRON);
    }
    for (num du = -hw; du <= hw; du += .3) {
      shadow(u + du, v, .4, .3);
    }
  }

  // plaza-base.js: seatSide
  /// A seat seen from its end: long down the picture (people on it face the left).
  void seatSide(num u, num v0, num v1, [List<num> c = const [190, 138, 86]]) {
    final v = (v0 + v1) / 2, hd = (v1 - v0) / 2;
    const L = [214, 164, 104];
    box(
      u,
      v,
      .36,
      .46,
      .26,
      hd,
      L,
      (s, t, z, face) =>
          face == 'top' && jsMod(s + .26, .17) < .03 ? e.rampOf(c)[2] : 0,
    );
    // its back, at the right
    box(
      u + .24,
      v,
      .46,
      1.12,
      .04,
      hd,
      L,
      (s, t, z, face) =>
          (face == 'front' && (jsMod(z - .46, .22) > .16)) ? e.rampOf(c)[1] : 0,
    );
    box(u - .22, v + hd - .04, .46, .78, .26, .04, c); // the near arm rest
    for (final dv in [-hd + .15, hd - .15]) {
      box(u, v + dv, 0, .36, .22, .07, IRON);
    }
    for (num dv = -hd; dv <= hd; dv += .3) {
      shadow(u, v + dv, .4, .3);
    }
  }

  // plaza-base.js: bed
  /// A flower bed: a low stone rim, earth, flowers of the given colours.
  void bed(
    num u0,
    num v0,
    num u1,
    num v1, [
    List<List<num>> cols = const [
      [236, 80, 90],
      [250, 206, 70],
      [250, 250, 250],
    ],
  ]) {
    final hw = (u1 - u0) / 2, hd = (v1 - v0) / 2;
    box(
      u0 + hw,
      v0 + hd,
      0,
      .24,
      hw,
      hd,
      STONE,
      (s, t, z, face) =>
          face == 'top' && s.abs() < hw - .09 && t.abs() < hd - .09
          ? _rgb(EARTH)
          : 0,
    );
    var kk = 0;
    for (num u = u0 + .25; u <= u1 - .2; u += .34) {
      for (num v = v0 + .22; v <= v1 - .15; v += .3) {
        final j = e.hash(kk * 3, kk * 7);
        kk++;
        ball(u + (j - .5) * .12, v, .32, .13, const [70, 130, 62]);
        ball(
          u + (j - .5) * .12,
          v + .02,
          .46,
          .085,
          cols[kk % cols.length],
          'smooth',
        );
      }
    }
  }

  // plaza-base.js: hedge
  /// A low hedge along a line.
  void hedge(num u0, num v0, num u1, num v1) {
    final n = math.max(1, jsRoundN(jsHypot(u1 - u0, v1 - v0) / .34));
    for (var kk = 0; kk <= n; kk++) {
      final u = u0 + (u1 - u0) * kk / n, v = v0 + (v1 - v0) * kk / n;
      ball(u, v, .22, .32, kk % 3 != 0 ? PlazaCl.LEAF : PlazaCl.LEAF_L);
      if (kk % 2 == 0) shadow(u, v, .25, .3);
    }
  }

  // plaza-base.js: lamp
  /// A street lamp of the square: an iron post, an arm, a lantern (lit when [NIGHT]).
  void lamp(num u, num v, [num h = 3.0]) {
    post(u, v, 0, h, .06, IRON);
    box(u, v, 0, .16, .14, .14, IRON);
    final p = xy(u, v),
        x = p[0],
        y = p[1],
        on = NIGHT,
        G = on ? const [255, 236, 150] : const [226, 232, 226];
    for (num z = h; z <= h + .42; z += .03) {
      for (num a = -.13; a <= .13; a += .03) {
        for (num bb = -.13; bb <= .13; bb += .03) {
          final edge =
              (a.abs() > .1 && bb.abs() > .1) || z > h + .38 || z < h + .03;
          final col = edge ? _rgb(IRON) : _rgb(G);
          if (on && !edge) {
            k.plotGlow(x + a, y + bb, z, col);
          } else {
            e.plot(x + a, y + bb, z, col);
          }
        }
      }
    }
    box(u, v, h + .42, h + .5, .17, .17, IRON);
  }

  // plaza-base.js: flags
  /// Paper flags on a string between two points (little triangles hanging), facing the camera.
  void flags(
    num u0,
    num z0,
    num u1,
    num z1,
    num v, [
    num sag = .18,
    List<List<num>> cols = const [
      [236, 80, 90],
      [250, 206, 70],
      [86, 160, 150],
      [250, 250, 250],
      [110, 150, 220],
    ],
  ]) {
    wall(u0, u1, v, math.min(z0, z1) - sag - .34, math.max(z0, z1) + .04, (
      u,
      z,
    ) {
      final t = (u - u0) / (u1 - u0),
          zs = z0 + (z1 - z0) * t - sag * 4 * t * (1 - t);
      if ((z - zs).abs() < .025) return e.rgb(90, 80, 70);
      final kk = (t * math.max(3, jsRoundN((u1 - u0) / .3))).floor(),
          n = math.max(3, jsRoundN((u1 - u0) / .3)),
          f = t * n - kk,
          d = zs - z;
      if (d > 0 && d < .28 && (f - .5).abs() < .42 * (1 - d / .28)) {
        return _rgb(cols[kk % cols.length]);
      }
      return 0;
    });
  }

  /* ---- far things, in the sky (screen space) ---- */

  // plaza-base.js: farTower
  /// The square's clock tower, far off: its top with the clock, small and pale; (cx, by): the middle of its foot on the
  /// picture.
  PzSky farTower(num cx, num by, [num hgt = 44]) {
    return (ix, iy) {
      final dx = ix + .5 - cx, dy = by - (iy + .5);
      if (dy < 0) return 0;
      if (dy < hgt - 12) {
        if (dx.abs() > 7) return 0;
        final cy = hgt - 22;
        if (jsHypot(dx, dy - cy) < 4.6) {
          return jsHypot(dx, dy - cy) > 3.5
              ? e.rgb(150, 120, 100)
              : ((dx.abs() < .6 && dy - cy > -.5 && dy - cy < 3) ||
                    ((dy - cy).abs() < .6 && dx > -.5 && dx < 2.4))
              ? e.rgb(70, 60, 60)
              : e.rgb(252, 250, 240);
        }
        return dx > 4 ? e.rgb(214, 196, 170) : e.rgb(236, 222, 196);
      }
      if (dy < hgt - 10) return dx.abs() < 8.5 ? e.rgb(206, 186, 160) : 0;
      final t = (dy - (hgt - 10)) / 10;
      return dx.abs() < 8 * (1 - t)
          ? (dx > 0 ? e.rgb(176, 84, 66) : e.rgb(206, 104, 80))
          : 0;
    };
  }

  // plaza-base.js: sky
  /// The sky by the hour, with far things in front of it. hora: manana, mediodia, tarde, ocaso, noche.
  PzSky sky(String hora, [List<PzSky?> far = const []]) {
    final base = CL.sky(
      const {
            'manana': 'manana',
            'mediodia': 'manana',
            'tarde': 'manana',
            'ocaso': 'tarde',
            'noche': 'noche',
          }[hora] ??
          'manana',
      null,
    );
    return (ix, iy) {
      for (final f in far) {
        final c = f == null ? 0 : f(ix, iy);
        if (c != 0) return c;
      }
      return base(ix, iy);
    };
  }

  // plaza-base.js: light
  /// The light of the hour on everything drawn (call before skyFill).
  void light(String hora) {
    const L = <String, List<List<double>>>{
      'tarde': [
        [1.0, .95, .86],
        [8, 3, -6],
      ],
      'ocaso': [
        [1.0, .88, .78],
        [14, 0, -10],
      ],
      'noche': [
        [.62, .62, .82],
        [-6, -4, 14],
      ],
    };
    final l = L[hora];
    if (l != null) k.lightPass(l[0], l[1]);
  }
}
