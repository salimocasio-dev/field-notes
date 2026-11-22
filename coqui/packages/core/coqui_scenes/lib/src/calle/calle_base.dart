// Port of docs/proyecto/pixel/calle-base.js: the streets of place 5 (La calle), the painters and the pieces its four
// scene sets share (esquina, parada, tiendas, cruce), call for call, whole: the painters for faces and tops, the
// pavement, the asphalt, the kerb, the grass; a wall along x and along y; a door, a picture sign, a window, an awning;
// a house front; a tree; a traffic light whose three lamps show unlit; a cone; a seat; a sign on a pole; the sky by
// hour; and `vehicle(kind, x, y, heading, board)`: the red car, the blue car and the guagua (in the game they are
// sprites, baked once from this drawing: calle_vehicles.dart). The file's names are kept, capitals included, so the
// port reads line for line against it (page 12, section 6): the lints on names are off.
//
// First writer: order 54b (La esquina). The builders of parada, tiendas and cruce copy it and add to it only by adding.
// Every piece is ported, also what La esquina does not use, each tested against the JavaScript
// (test/calle_kit_test.dart, tool/make_calle_kit_ref.mjs). La cruce's 45 degree turn (`E.xy`, `E.uv`) lives in
// cruce-set.html's own `E`, not in this kit.
//
// Every `%` of the JavaScript is `remainder` here (its sign follows the left side, as in JavaScript).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// A painter of a face or a top: the colour at (a, b) of the plane, or 0 for a hole.
typedef CalleFn = int Function(num a, num b);

/// calle-base.js: trafficLight's result: the three lamps' world points (top to bottom: red, amber, green) and the
/// button's (the red disc on the yellow box, at frog height).
typedef CalleLight = ({
  List<({double x, double y, double z})> lamps,
  ({double x, double y, double z}) button,
});

/// Port of calle-base.js (`CL`). World (S = 26). The camera sees the faces that look to +y (lit) and to +x (in
/// shade), and tops: a wall "along x" is the plane y = at, a wall "along y" the plane x = at. [NIGHT] is `CL.NIGHT`
/// (a set that lights the windows sets it before building).
class CalleBase {
  CalleBase(this.k) : e = k.e, b = k.b;

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  int get W => e.W;
  int get H => e.H;

  /// calle-base.js: `api.NIGHT`: windowX paints a lit window.
  bool NIGHT = false;

  // sampling steps: faces, tops, painted planes
  static const double PX = .04, PZ = .035, PA = .03, PP = .024;
  static const List<int> ASPH = [98, 96, 104],
      ASPH_L = [112, 110, 116],
      KERB = [214, 208, 196],
      LINE = [232, 218, 150],
      WHITE = [238, 236, 226];
  static const List<int> SALMON = [240, 150, 116],
      TEAL = [86, 160, 150],
      WOOD = [150, 98, 56],
      WOOD_L = [196, 148, 92],
      LEAF = [74, 134, 62],
      LEAF_L = [112, 176, 84],
      TRUNK = [120, 84, 56];

  // the colours the pieces use, made once (the engine's ramps are kept by list)
  static const List<int> _RED = [226, 60, 50], _CREAM = [250, 246, 236];
  static const List<int> _FRAME = [244, 240, 228];

  int rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);
  int shade(List<num> c, num base, [num a = 0, num bb = 0]) =>
      b.shade(c, base, a, bb);

  /* ---- painters ---- */

  // calle-base.js: faceY. A face on the plane y = at (faces +y): fn(a, z) gives the colour, or 0 for a hole
  void faceY(
    num at,
    num a0,
    num a1,
    num z0,
    num z1,
    CalleFn fn, [
    double step = PX,
  ]) {
    for (num a = a0; a <= a1; a += step) {
      for (num z = z0; z <= z1; z += PZ) {
        final c = fn(a, z);
        if (c != 0) e.plot(a, at, z, c);
      }
    }
  }

  // calle-base.js: faceX. A face on the plane x = at (faces +x): fn(b, z)
  void faceX(
    num at,
    num b0,
    num b1,
    num z0,
    num z1,
    CalleFn fn, [
    double step = PX,
  ]) {
    for (num bb = b0; bb <= b1; bb += step) {
      for (num z = z0; z <= z1; z += PZ) {
        final c = fn(bb, z);
        if (c != 0) e.plot(at, bb, z, c);
      }
    }
  }

  // calle-base.js: top
  void top(num x0, num y0, num x1, num y1, num z, CalleFn fn) {
    for (num a = x0; a <= x1; a += PA) {
      for (num bb = y0; bb <= y1; bb += PA) {
        final c = fn(a, bb);
        if (c != 0) e.plot(a, bb, z, c);
      }
    }
  }

  // calle-base.js: box. Its top and its two seen faces
  void box(
    num x0,
    num y0,
    num z0,
    num x1,
    num y1,
    num z1,
    List<num> c, [
    CalleFn? topFn,
  ]) {
    top(x0, y0, x1, y1, z1, (a, bb) {
      final t = topFn == null ? 0 : topFn(a, bb);
      return t != 0 ? t : shade(c, 3.4, a, bb);
    });
    faceY(y1, x0, x1, z0, z1, (a, z) => shade(c, 2.4, a, z));
    faceX(x1, y0, y1, z0, z1, (bb, z) => shade(c, 1.3, bb, z));
  }

  /* ---- the ground ---- */

  // calle-base.js: slab
  int slab(num x, num y, int ix, int iy) {
    final ea = ((x + 40).remainder(1.1)) / 1.1,
        eb = ((y + 40).remainder(1.1)) / 1.1;
    return (ea < .04 || eb < .04)
        ? e.rgb(168, 160, 150)
        : b.toneOf(
            b.C.pave,
            .45 +
                e.hash(((x + 40) / 1.1).floor(), ((y + 40) / 1.1).floor()) * .3,
            ix,
            iy,
          );
  }

  // calle-base.js: asphalt
  int asphalt(int ix, int iy) =>
      rgbOf((e.hash(ix >> 1, iy >> 1) < .08) ? ASPH_L : ASPH);

  // calle-base.js: kerb
  int kerb() => rgbOf(KERB);

  // calle-base.js: paint
  int paint(List<num> c) => rgbOf(c);

  // calle-base.js: grass
  int grass(num x, num y, int ix, int iy) => rgbOf(
    e.GRASS[e.clamp(
      ((.3 + e.noise(x * .7, y * .7) * .7 + (e.hash(ix, iy) - .5) * .3) * 4)
          .floor(),
      0,
      3,
    )],
  );

  /* ---- pieces ---- */

  static bool _inHole(List<List<num>> holes, num a, num z) =>
      holes.any((k) => a > k[0] && a < k[1] && z > k[2] && z < k[3]);

  // calle-base.js: wallAlongX. A wall along x at y = at, from x0 to x1, h high, painted c with a darker foot and a band
  // under its top; holes [a0, a1, z0, z1]
  void wallAlongX(
    num at,
    num x0,
    num x1,
    num h,
    List<num> c,
    List<num> trim, [
    List<List<num>> holes = const [],
  ]) {
    faceY(
      at,
      x0,
      x1,
      0,
      h,
      (a, z) => _inHole(holes, a, z)
          ? 0
          : z < .6
          ? shade(trim, z > .54 ? 1.6 : 2.4, a, z)
          : z > h - .28
          ? shade(trim, 2.6, a, z)
          : shade(c, 2.4, a, z),
    );
  }

  // calle-base.js: wallAlongY
  void wallAlongY(
    num at,
    num y0,
    num y1,
    num h,
    List<num> c,
    List<num> trim, [
    List<List<num>> holes = const [],
  ]) {
    faceX(
      at,
      y0,
      y1,
      0,
      h,
      (bb, z) => _inHole(holes, bb, z)
          ? 0
          : z < .6
          ? shade(trim, z > .54 ? 1.2 : 1.8, bb, z)
          : z > h - .28
          ? shade(trim, 2.0, bb, z)
          : shade(c, 1.85, bb, z),
    );
  }

  // calle-base.js: doorX. A door in a wall along x (shut, or open inwards so that the dim inside shows)
  void doorX(
    num at,
    num d0,
    num d1,
    num dh,
    bool open, [
    List<num> wood = WOOD,
    bool glassTop = true,
  ]) {
    final w = d1 - d0, Wd = e.rampOf(wood), F = e.rampOf(WOOD_L);
    faceY(
      at - .9,
      d0,
      d1,
      0,
      dh,
      (a, z) => z < .14
          ? e.rgb(60, 44, 34)
          : e.rgb(84 - z * 10, 78 - z * 10, 70 - z * 8),
      PP,
    ); // the dim inside
    top(d0, at - .9, d1, at, 0, (_, _) => e.rgb(120, 104, 88));
    faceY(
      at,
      d0 - .12,
      d1 + .12,
      0,
      dh + .12,
      (a, z) => (a > d0 && a < d1 && z < dh) ? 0 : (z > dh ? F[3] : F[2]),
      PP,
    ); // the frame
    int panel(num t, num z) {
      final u = t * w,
          glass = glassTop && u > .2 && u < w - .2 && z > 1.3 && z < dh - .25;
      if (!glass) {
        return Wd[(u < .08 || u > w - .08 || z < .08 || z > dh - .08) ? 1 : 2];
      }
      final s = (u * 1.5 + z).remainder(1.1);
      return s < .2
          ? e.rgb(232, 246, 250)
          : (s > .32 && s < .4)
          ? e.rgb(206, 232, 240)
          : e.rgb(150, 200, 214);
    }

    if (open) {
      const ang = .25;
      final dx = math.cos(ang), dy = math.sin(ang);
      for (num t = 0; t <= 1; t += PP / w) {
        for (num z = 0; z <= dh; z += PP) {
          e.plot(d1 + dx * w * t, at + .02 + dy * w * t, z, panel(t, z));
        }
      }
    } else {
      faceY(at - .05, d0, d1, 0, dh, (a, z) => panel((d1 - a) / w, z), PP);
    }
  }

  // calle-base.js: signX. A board with a picture on a wall along x: fn(u, v) with u, v from 0 to 1 gives a colour (the
  // board's cream ground otherwise)
  void signX(num at, num a0, num a1, num z0, num z1, CalleFn fn) {
    faceY(at + .03, a0, a1, z0, z1, (a, z) {
      final u = (a - a0) / (a1 - a0), v = (z - z0) / (z1 - z0);
      if (u < .05 || u > .95 || v < .09 || v > .91) return e.rgb(120, 76, 44);
      final c = fn(u, v);
      return c != 0 ? c : e.rgb(250, 244, 226);
    }, PP);
  }

  // calle-base.js: signY
  void signY(num at, num b0, num b1, num z0, num z1, CalleFn fn) {
    faceX(at + .03, b0, b1, z0, z1, (bb, z) {
      final u = (b1 - bb) / (b1 - b0), v = (z - z0) / (z1 - z0);
      if (u < .05 || u > .95 || v < .09 || v > .91) return e.rgb(96, 62, 38);
      final c = fn(u, v);
      return c != 0 ? c : e.rgb(226, 220, 204);
    }, PP);
  }

  // calle-base.js: windowY. A window in a wall along y: a frame, glass with streaks, a sill
  void windowY(num at, num b0, num b1, num z0, num z1) {
    final F = e.rampOf(_FRAME);
    faceX(at + .02, b0 - .1, b1 + .1, z0 - .1, z1 + .1, (bb, z) {
      if (bb < b0 ||
          bb > b1 ||
          z < z0 ||
          z > z1 ||
          (bb - (b0 + b1) / 2).abs() < .04) {
        return F[1];
      }
      final s = ((b1 - bb) * 1.4 + z).remainder(1.2);
      return s < .18 ? e.rgb(196, 226, 232) : e.rgb(120, 170, 186);
    }, PP);
    box(at, b0 - .16, z0 - .2, at + .14, b1 + .16, z0 - .1, const [
      230,
      224,
      210,
    ]);
  }

  // calle-base.js: awningY. A striped awning over a stretch of a wall along y
  void awningY(num at, num b0, num b1, num z1, num z0, num out) {
    for (num bb = b0; bb <= b1; bb += PA) {
      for (num a = 0; a <= out; a += PA) {
        final z = z1 - a / out * (z1 - z0),
            s = ((bb - b0) / .42).floor().remainder(2);
        e.plot(at + a, bb, z, shade(s != 0 ? _RED : _CREAM, 3.0, a, bb));
      }
    }
    faceX(
      at + out,
      b0,
      b1,
      z0 - .2,
      z0,
      (bb, z) => shade(
        (((bb - b0) / .42).floor().remainder(2)) != 0 ? _RED : _CREAM,
        1.5,
        bb,
        z,
      ),
    );
  }

  static const List<List<double>> _CROWN = [
    [0, 0, 0, 1],
    [-.55, .1, -.15, .72],
    [.5, -.15, -.1, .74],
    [.1, .5, -.25, .66],
    [-.15, -.5, .1, .68],
    [.3, .3, .35, .6],
    [-.35, -.2, .4, .58],
  ];

  // calle-base.js: tree. A trunk and a crown of leaf balls
  void tree(
    num x,
    num y,
    num h,
    num r, [
    List<num> c = LEAF,
    List<num> c2 = LEAF_L,
  ]) {
    for (num z = 0; z <= h; z += PZ) {
      for (num t = 0; t < 6.3; t += .25) {
        e.plot(
          x + math.cos(t) * .13,
          y + math.sin(t) * .13,
          z,
          shade(TRUNK, 1.4 + math.cos(t - .8), t, z),
        );
      }
    }
    for (final q in _CROWN) {
      final dx = q[0], dy = q[1], dz = q[2], kk = q[3];
      e.sphere(
        x + dx * r,
        y + dy * r,
        h + r * .7 + dz * r,
        r * kk,
        kk > .7 ? c : c2,
        'rough',
      );
    }
    e.castShadow(x, y, h, r * 1.2);
    e.castShadow(x + .2, y, h + .4, r);
  }

  static const List<List<int>> _DIM = [
    [150, 50, 46],
    [150, 120, 40],
    [50, 120, 66],
  ];

  // calle-base.js: trafficLight. A pole with a traffic light: three dark lamps (the lit one is a sprite) and a button
  // box at frog height. Returns the lamps' and the button's places
  CalleLight trafficLight(num x, num y) {
    const M = [70, 74, 84], Dk = [36, 38, 46];
    for (num z = 0; z <= 2.5; z += PZ) {
      for (num t = 0; t < 6.3; t += .4) {
        e.plot(
          x + math.cos(t) * .055,
          y + math.sin(t) * .055,
          z,
          shade(M, 1.2 + math.cos(t - .8) * 1.2, t, z),
        );
      }
    }
    box(x - .24, y - .12, 2.25, x + .24, y + .12, 3.5, Dk);
    final lamps = <({double x, double y, double z})>[];
    // unlit, each lamp still shows its colour: red, amber, green
    for (var kk = 0; kk < 3; kk++) {
      final z = 3.27 - kk * .39;
      lamps.add((x: x.toDouble(), y: (y + .125).toDouble(), z: z));
      for (num a = -.16; a <= .16; a += .02) {
        for (num bb = -.16; bb <= .16; bb += .02) {
          final r = a * a + bb * bb;
          if (r < .0256) {
            e.plot(
              x + a,
              y + .125,
              z + bb,
              r > .017 ? e.rgb(20, 20, 26) : rgbOf(_DIM[kk]),
            );
          }
        }
      }
    }
    box(x - .12, y + .02, .62, x + .12, y + .16, .98, const [236, 196, 60]);
    for (num a = -.05; a <= .05; a += .015) {
      for (num bb = -.05; bb <= .05; bb += .015) {
        if (a * a + bb * bb < .003) {
          e.plot(x + a, y + .165, .8 + bb, e.rgb(206, 60, 50));
        }
      }
    }
    for (num z = .15; z <= 2.4; z += .12) {
      e.castShadow(x, y, z, .07);
    }
    e.castShadow(x, y, 2.8, .18);
    return (
      lamps: lamps,
      button: (x: x.toDouble(), y: (y + .165).toDouble(), z: .8),
    );
  }

  static const List<int> _CONE = [238, 120, 40], _BAND = [250, 246, 236];

  // calle-base.js: cone. A traffic cone, baked (the ones a story knocks over are sprites)
  void cone(num x, num y) {
    for (num z = 0; z <= .5; z += .02) {
      final r = .13 * (1 - z / .56) + .015, band = z > .2 && z < .3;
      for (num t = 0; t < 6.3; t += .22) {
        e.plot(
          x + math.cos(t) * r,
          y + math.sin(t) * r,
          z,
          shade(band ? _BAND : _CONE, 1.6 + math.cos(t - .8) * 1.1, t, z),
        );
      }
    }
    box(x - .15, y - .15, 0, x + .15, y + .15, .04, const [226, 104, 36]);
    e.castShadow(x, y, .25, .16);
  }

  // calle-base.js: windowX. A window in a wall along x
  void windowX(num at, num a0, num a1, num z0, num z1) {
    final F = e.rampOf(_FRAME);
    faceY(at + .02, a0 - .1, a1 + .1, z0 - .1, z1 + .1, (a, z) {
      if (a < a0 ||
          a > a1 ||
          z < z0 ||
          z > z1 ||
          (a - (a0 + a1) / 2).abs() < .04) {
        return F[3];
      }
      if (NIGHT) return e.rgb(255, 226, 140); // a lit window
      final s = ((a - a0) * 1.4 + z).remainder(1.2);
      return s < .18
          ? e.rgb(226, 244, 248)
          : (s > .5 && s < .58)
          ? e.rgb(196, 226, 236)
          : e.rgb(150, 200, 214);
    }, PP);
    box(a0 - .16, at, z0 - .2, a1 + .16, at + .14, z0 - .1, const [
      240,
      234,
      220,
    ]);
  }

  // calle-base.js: awningX. A striped awning over a stretch of a wall along x
  void awningX(num at, num a0, num a1, num z1, num z0, num out) {
    for (num a = a0; a <= a1; a += PA) {
      for (num bb = 0; bb <= out; bb += PA) {
        final z = z1 - bb / out * (z1 - z0),
            s = ((a - a0) / .42).floor().remainder(2);
        e.plot(a, at + bb, z, shade(s != 0 ? _RED : _CREAM, 3.2, a, bb));
      }
    }
    faceY(
      at + out,
      a0,
      a1,
      z0 - .22,
      z0,
      (a, z) => shade(
        (((a - a0) / .42).floor().remainder(2)) != 0 ? _RED : _CREAM,
        2.2,
        a,
        z,
      ),
    );
  }

  /* ---- things that drive ---- */

  // calle-base.js: BOARDS. The pictures of where a guagua goes
  late final Map<String, CalleFn> BOARDS = {
    'arbol': (u, v) =>
        (_hyp(u - .5, v - .62) < .27 ||
            _hyp(u - .34, v - .5) < .17 ||
            _hyp(u - .66, v - .5) < .17)
        ? e.rgb(70, 150, 70)
        : ((u - .5).abs() < .06 && v < .5 && v > .12)
        ? e.rgb(120, 84, 56)
        : 0,
    // the colmado: the basket of fruit of its own sign
    'toldo': (u, v) {
      final dx = (u - .5) * 2.6, dy = v - .46;
      if (dy < 0 && dy > -.34 && dx.abs() < .7 + dy) {
        return e.rgb(176, 124, 70);
      }
      if (_hyp(dx + .34, dy - .13) < .22) return e.rgb(226, 60, 50);
      if (_hyp(dx - .02, dy - .22) < .22) return e.rgb(244, 200, 70);
      if (_hyp(dx - .38, dy - .11) < .2) return e.rgb(110, 170, 70);
      return 0;
    },
    'casa': (u, v) => (v > .5 && v < .88 && (u - .5).abs() < (.88 - v) * .95)
        ? e.rgb(206, 80, 60)
        : (v > .14 && v <= .5 && u > .26 && u < .74)
        ? (u > .44 && u < .58 && v < .38
              ? e.rgb(120, 76, 44)
              : e.rgb(250, 214, 120))
        : 0,
  };

  static double _hyp(num a, num b) => math.sqrt(a * a + b * b);

  static const List<int> _BUS = [244, 244, 236],
      _AZUL = [70, 120, 206],
      _ROJO = [214, 62, 54];
  static const List<int> _G = [44, 52, 66],
      _G2 = [70, 84, 104],
      _TY = [40, 38, 44];
  static const List<int> _BUS_TOP = [226, 226, 220], _BUS_BAND = [60, 150, 120];
  static const List<int> _IN = [40, 170, 90], _OUT = [240, 140, 40];

  // calle-base.js: vehicle. kind: carro (red), azul (the blue car), guagua. (x, y): the middle of its floor. heading: 'i'
  // it drives towards -x (its right side, the lit one with a guagua's door, faces the camera; the face at +x is its
  // back), 'd' towards +x (the face at +x is its front; the side we see is its left). Dark windows: nobody is seen
  // inside. board: a guagua's roof picture (`arbol`, `toldo`, `casa`) or null.
  void vehicle(
    String kind,
    num x,
    num y, [
    String heading = 'i',
    String? board,
  ]) {
    final bus = kind == 'guagua',
        L = bus ? 4.4 : 2.2,
        Wd = bus ? 1.3 : 1.1,
        c = bus
            ? _BUS
            : kind == 'azul'
            ? _AZUL
            : _ROJO;
    final x0 = x - L / 2, x1 = x + L / 2, y0 = y - Wd / 2, y1 = y + Wd / 2;
    final front = heading == 'd'; // is the face at +x the front?
    void wheel(num wx) {
      for (num a = -.26; a <= .26; a += .02) {
        for (num bb = -.26; bb <= .26; bb += .02) {
          final r = _hyp(a, bb);
          if (r < .26) {
            e.plot(
              wx + a,
              y1 + .02,
              .26 + bb,
              r < .1 ? e.rgb(170, 170, 176) : rgbOf(_TY),
            );
          }
        }
      }
    }

    if (bus) {
      const H0 = .3, H1 = 2.15;
      top(x0, y0, x1, y1, H1, (a, bb) => shade(_BUS_TOP, 3.4, a, bb));
      // the side: a band, a row of dark windows, the door near the front end
      faceY(y1, x0, x1, H0, H1, (a, z) {
        final u = a - x0,
            dn = front ? (x1 - a) : u; // distance from the front end
        bool door(num d) => d > 0 && d < .8;
        int leaf(num d) => ((d - .4).abs() < .03)
            ? e.rgb(30, 34, 44)
            : (z > .95
                  ? rgbOf((((d * 3 + z).remainder(1.3)) < .2) ? _G2 : _G)
                  : e.rgb(86, 96, 110));
        if (z < H1 - .2 && door(dn - .35)) {
          return leaf(dn - .35); // the front door: two leaves with glass
        }
        if (z < H1 - .2 && door(dn - (L - 1.2))) {
          return leaf(dn - (L - 1.2)); // the back door
        }
        // beside each door: an arrow (in: green, towards the door; out: orange, away from it) and a round button
        for (final (d0, col, out) in [(1.2, _IN, 0), (L - 1.48, _OUT, 1)]) {
          final q = dn - d0, zz = z - 1.32;
          if (q > 0 && q < .24 && zz.abs() < .2) {
            final t = out != 0
                ? (d0 > L / 2 ? q : .24 - q)
                : (d0 > L / 2 ? .24 - q : q);
            if (zz.abs() < .05 || zz.abs() < (t < .1 ? t * 1.8 : 0)) {
              return rgbOf(col);
            }
            return e.rgb(250, 250, 250);
          }
          if (_hyp(q - .12, z - .8) < .075) return rgbOf(col);
        }
        if (z > 1.15 &&
            z < 1.85 &&
            dn > 1.55 &&
            dn < L - 1.55 &&
            ((dn - 1.55).remainder(.68)) < .54) {
          return rgbOf((((a * 2 + z).remainder(1.6)) < .22) ? _G2 : _G);
        }
        if (z > .62 && z < .86) return shade(_BUS_BAND, 2.4, a, z);
        return shade(c, 2.4, a, z);
      });
      // the end we see: the front (a big windscreen, a picture board over it, two lamps) or the back
      faceX(x1, y0, y1, H0, H1, (bb, z) {
        final v = bb - y0;
        if (front) {
          if (z > 1.72 && z < 2.05 && v > .2 && v < Wd - .2) {
            return e.rgb(250, 244, 226);
          }
          if (z > .95 && z < 1.66 && v > .1 && v < Wd - .1) return rgbOf(_G);
          if (z > .45 && z < .62 && (v < .3 || v > Wd - .3)) {
            return e.rgb(250, 232, 150);
          }
        } else {
          if (z > 1.15 && z < 1.8 && v > .15 && v < Wd - .15) return rgbOf(_G);
          if (z > .46 && z < .72 && (v < .3 || v > Wd - .3)) {
            return e.rgb(226, 40, 40);
          }
        }
        return z > .62 && z < .86
            ? shade(_BUS_BAND, 1.4, bb, z)
            : shade(c, 1.4, bb, z);
      });
      final pic = board == null ? null : BOARDS[board];
      if (pic != null) {
        // where it goes: a picture on a plate that stands on its roof, over the door
        final b0 = front ? x1 - 1.9 : x0 + .5, b1 = b0 + 1.4;
        faceY(y1 - .12, b0, b1, H1, H1 + .78, (a, z) {
          final u = (a - b0) / 1.4, v = (z - H1) / .78;
          if (u < .05 || u > .95 || v < .07 || v > .93) {
            return e.rgb(60, 64, 74);
          }
          final p = pic(u, v);
          return p != 0 ? p : e.rgb(250, 246, 232);
        }, PP);
      }
      wheel(x0 + .8);
      wheel(x1 - .8);
      for (num a = x0; a <= x1; a += .5) {
        e.castShadow(a, y, 1.2, .8);
      }
    } else {
      // the body, and the cabin on it
      const H0 = .22, H1 = .78, H2 = 1.22;
      final C0 = x0 + (front ? .45 : .6), C1 = x1 - (front ? .6 : .45);
      top(
        x0,
        y0,
        x1,
        y1,
        H1,
        (a, bb) => (a > C0 && a < C1) ? 0 : shade(c, 3.4, a, bb),
      );
      top(C0, y0 + .06, C1, y1 - .06, H2, (a, bb) => shade(c, 3.4, a, bb));
      faceY(y1, x0, x1, H0, H1, (a, z) => shade(c, 2.4, a, z));
      faceY(
        y1 - .06,
        C0,
        C1,
        H1,
        H2,
        (a, z) =>
            (a > C0 + .1 &&
                a < C1 - .1 &&
                z < H2 - .08 &&
                (a - (C0 + C1) / 2).abs() > .04)
            ? rgbOf((((a * 2 + z).remainder(1.4)) < .2) ? _G2 : _G)
            : shade(c, 2.4, a, z),
      );
      faceX(x1, y0, y1, H0, H1, (bb, z) {
        final v = bb - y0;
        if (z > .42 && z < .66 && (v < .3 || v > Wd - .3)) {
          return front ? e.rgb(255, 240, 160) : e.rgb(226, 40, 40);
        }
        if (front && z > .34 && z < .6 && v > .36 && v < Wd - .36) {
          return ((v / .06).floor().remainder(2)) != 0
              ? e.rgb(40, 40, 48)
              : e.rgb(120, 120, 130);
        }
        if (!front && z > .3 && z < .42 && v > .3 && v < Wd - .3) {
          return e.rgb(250, 250, 250);
        }
        return shade(c, 1.4, bb, z);
      });
      faceX(
        C1,
        y0 + .06,
        y1 - .06,
        H1,
        H2,
        (bb, z) => (bb > y0 + .14 && bb < y1 - .14 && z < H2 - .08)
            ? rgbOf(_G)
            : shade(c, 1.4, bb, z),
      );
      wheel(x0 + .5);
      wheel(x1 - .5);
      for (num a = x0 + .3; a <= x1; a += .5) {
        e.castShadow(a, y, .5, .65);
      }
    }
  }

  // calle-base.js: seat. A seat with a back, along x (its back at the far side), or a bench without one
  void seat(
    num x0,
    num y0,
    num x1, [
    bool back = true,
    List<num> c = const [150, 104, 62],
  ]) {
    final y1 = y0 + .5;
    box(x0, y0, .36, x1, y1, .46, c);
    for (final x in [x0 + .08, x1 - .2]) {
      box(x, y0 + .06, 0, x + .12, y1 - .06, .36, const [70, 60, 56]);
    }
    if (back) box(x0, y0 - .02, .46, x1, y0 + .08, 1.0, c);
    for (num a = x0; a <= x1; a += .3) {
      e.castShadow(a, y0 + .25, .4, .3);
    }
  }

  static const List<int> _POLE = [90, 94, 104];

  // calle-base.js: signPole. A thin pole with a board on it, facing +y: fn(u, v) paints the board (0: its ground colour)
  void signPole(
    num x,
    num y,
    num h,
    num bw,
    num bh,
    List<num> ground,
    CalleFn fn,
  ) {
    for (num z = 0; z <= h; z += PZ) {
      for (num t = 0; t < 6.3; t += .5) {
        e.plot(
          x + math.cos(t) * .045,
          y + math.sin(t) * .045,
          z,
          shade(_POLE, 1.2 + math.cos(t - .8) * 1.2, t, z),
        );
      }
    }
    faceY(y + .06, x - bw / 2, x + bw / 2, h - bh, h, (a, z) {
      final u = (a - x + bw / 2) / bw, v = (z - h + bh) / bh;
      if (u < .07 || u > .93 || v < .07 || v > .93) {
        return e.rgb(250, 250, 250);
      }
      final c = fn(u, v);
      return c != 0 ? c : rgbOf(ground);
    }, PP);
    for (num z = .15; z <= h; z += .12) {
      e.castShadow(x, y, z, .06);
    }
  }

  // calle-base.js: houseX. A house front in a wall along x: a painted wall from x0 to x1, a door, a window, a flat roof
  // edge. doorAt, winAt: x of their left edges (null: none)
  void houseX(
    num at,
    num x0,
    num x1,
    num h,
    List<num> c,
    List<num> trim,
    num? doorAt,
    num? winAt, [
    List<num> doorC = WOOD,
    num deep = 1.4,
  ]) {
    final holes = <List<num>>[];
    if (doorAt != null) holes.add([doorAt - .1, doorAt + 1.2, 0, 2.5]);
    if (winAt != null) holes.add([winAt - .1, winAt + 1.3, 1.0, 2.2]);
    top(x0, at - deep, x1, at, h, (a, bb) => shade(trim, 3.2, a, bb));
    wallAlongX(at, x0, x1, h, c, trim, holes);
    faceX(x1, at - deep, at, 0, h, (bb, z) => shade(c, 1.6, bb, z));
    if (doorAt != null) {
      doorX(at, doorAt, doorAt + 1.1, 2.4, false, doorC, false);
    }
    if (winAt != null) windowX(at, winAt, winAt + 1.2, 1.1, 2.1);
  }

  static const Map<String, List<List<num>>> _SKY = {
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
  static const List<List<num>> _SKY_NONE = [
    [150, 200, 252],
  ];
  static const List<List<num>> _SUN_LATE = [
    [250, 150, 60],
    [254, 190, 90],
    [255, 226, 150],
  ];
  static const List<List<num>> _SUN = [
    [246, 222, 130],
    [252, 238, 168],
    [255, 250, 212],
  ];

  // calle-base.js: sky. The sky, screen space: bands by hour and a sun; returns the skyFill function. sun: [sx, sy, r]
  // or null
  int Function(int ix, int iy) sky(String hora, List<num>? sun) {
    final B = _SKY[hora];
    final T = hora == 'tarde' || hora == 'noche' ? _SUN_LATE : _SUN;
    return (ix, iy) {
      if (sun != null) {
        final d = k.skyDisc(sun[0], sun[1], sun[2], T, ix, iy);
        if (d != 0) return d;
      }
      return k.skyBands(B ?? _SKY_NONE, 0, H, ix, iy);
    };
  }
}
