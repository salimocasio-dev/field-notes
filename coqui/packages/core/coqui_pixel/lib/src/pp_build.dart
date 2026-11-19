// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/src/pp_engine.dart';

/// The palette (mapa.js: `C`). Every colour is [r, g, b]; `sand`, `sea`, `pond`, `path`, `pave` and `asphalt`
/// are four tones of one colour, dark to light.
class PpPalette {
  const PpPalette();

  final List<List<int>> sand = const [
    [206, 186, 140],
    [222, 204, 160],
    [234, 218, 178],
    [244, 232, 198],
  ];
  final List<List<int>> sea = const [
    [28, 74, 112],
    [34, 98, 128],
    [44, 126, 140],
    [70, 160, 156],
  ];
  final List<List<int>> pond = const [
    [40, 96, 120],
    [52, 124, 138],
    [74, 152, 150],
    [104, 178, 164],
  ];
  final List<List<int>> path = const [
    [176, 150, 112],
    [194, 170, 130],
    [210, 188, 148],
    [224, 206, 168],
  ];
  final List<List<int>> pave = const [
    [186, 178, 164],
    [204, 196, 180],
    [220, 212, 196],
    [234, 228, 212],
  ];
  final List<List<int>> asphalt = const [
    [70, 70, 78],
    [82, 82, 90],
    [94, 94, 102],
    [104, 104, 112],
  ];
  final List<int> stone = const [216, 206, 184],
      dark = const [40, 36, 46],
      white = const [244, 240, 228],
      wood = const [140, 96, 60],
      woodD = const [96, 64, 40];
  final List<int> teal = const [96, 196, 190],
      pink = const [236, 150, 160],
      yellow = const [244, 206, 96],
      lilac = const [170, 140, 210],
      peach = const [244, 178, 120];
  final List<int> red = const [206, 56, 44],
      orange = const [240, 140, 52],
      green = const [70, 140, 70],
      leaf = const [74, 134, 62],
      palm = const [164, 130, 86];
  final List<int> glass = const [70, 110, 150],
      lamp = const [255, 226, 130],
      grey = const [150, 150, 156],
      fort = const [214, 196, 150];
}

/// Port of the palette and "building helpers" in pixel/mapa.js: C, toneOf, ST, shade, block, onWall, windowOn,
/// gable, flatRoof, shadowBox, bush, palm, person. Plus any helper a set reference adds (order 07 and 30a to 39a).
///
/// The helpers draw into the engine [e] they are made with. mapa.js's globals `C`, `ST` and `FACE` are fields.
/// A helper that mapa.js defines with a default that reads `C` (`windowOn`, `bush`) takes null for that default.
class PpBuild {
  PpBuild(this.e) : ST = .36 / e.S;

  final PpEngine e;

  /// mapa.js: C
  final PpPalette C = const PpPalette();

  /// mapa.js: ST. The helpers step at 0.36 / S: at S = 26 a fixed step left holes in walls.
  final double ST;

  /// mapa.js: FACE. Facing the viewer.
  final double FACE = math.pi / 4;

  // mapa.js: toneOf
  int toneOf(List<List<num>> tones, num t, int ix, int iy) {
    final c =
        tones[e.clamp(
          (t * 4 + (e.bayerAt(ix, iy) - .5) * .8).floor(),
          0,
          tones.length - 1,
        )];
    return e.rgb(c[0], c[1], c[2]);
  }

  // mapa.js: shade
  int shade(List<num> c, num base, [num a = 0, num b = 0, num grain = .35]) {
    return e.rampOf(c)[e.clamp(
      (base +
              (e.noise(a * 3, b * 3) - .5) * grain +
              (e.hash((a * 40).truncate(), (b * 40).truncate()) - .5) * .25)
          .floor(),
      0,
      4,
    )];
  }

  // mapa.js: block. A solid block with its two visible walls and top. Walls facing +y are lit, walls facing +x
  // are in shade
  void block(
    num x0,
    num y0,
    num z0,
    num x1,
    num y1,
    num z1,
    List<num> c, [
    List<num>? top,
  ]) {
    final topC = top ?? c;
    for (num a = x0; a <= x1; a += ST) {
      for (num b = y0; b <= y1; b += ST) {
        e.plot(a, b, z1, shade(topC, 3.4, a, b));
      }
    }
    for (num a = x0; a <= x1; a += ST) {
      for (num z = z0; z <= z1; z += ST) {
        e.plot(a, y1, z, shade(c, 2.4, a, z));
      }
    }
    for (num b = y0; b <= y1; b += ST) {
      for (num z = z0; z <= z1; z += ST) {
        e.plot(x1, b, z, shade(c, 1.3, b, z));
      }
    }
  }

  // mapa.js: onWall. A rectangle painted on a wall: face 'y' sits on y = at, face 'x' on x = at
  void onWall(String face, num at, num a0, num a1, num z0, num z1, int color) {
    for (num a = a0; a <= a1; a += ST * .8) {
      for (num z = z0; z <= z1; z += ST * .8) {
        if (face == 'y') {
          e.plot(a, at + .02, z, color);
        } else {
          e.plot(at + .02, a, z, color);
        }
      }
    }
  }

  // mapa.js: windowOn
  void windowOn(
    String face,
    num at,
    num ca,
    num cz,
    num w,
    num h, [
    List<num>? frame,
    List<num>? glass,
    bool lit = false,
  ]) {
    final frameC = frame ?? C.white, glassC = glass ?? C.glass;
    onWall(
      face,
      at,
      ca - w / 2 - .08,
      ca + w / 2 + .08,
      cz - h / 2 - .08,
      cz + h / 2 + .08,
      e.rampOf(frameC)[face == 'y' ? 3 : 2],
    );
    final g = lit
        ? e.rgb(C.lamp[0], C.lamp[1], C.lamp[2])
        : e.rampOf(glassC)[face == 'y' ? 1 : 0];
    for (num a = ca - w / 2; a <= ca + w / 2; a += ST * .8) {
      for (num z = cz - h / 2; z <= cz + h / 2; z += ST * .8) {
        final bar = (a - ca).abs() < .05 || (z - cz).abs() < .05;
        final col = bar ? e.rampOf(frameC)[face == 'y' ? 3 : 2] : g;
        if (face == 'y') {
          e.plot(a, at + .03, z, col);
        } else {
          e.plot(at + .03, a, z, col);
        }
      }
    }
  }

  // mapa.js: gable. A gable roof whose ridge runs along x
  void gable(
    num x0,
    num y0,
    num x1,
    num y1,
    num z,
    num rise,
    List<num> c,
    List<num> wall,
  ) {
    final yc = (y0 + y1) / 2, half = (y1 - y0) / 2;
    for (num x = x0; x <= x1; x += ST * .9) {
      for (num y = y0; y <= y1; y += ST * .9) {
        final q = (y - yc).abs() / half,
            row = (q * half * 4).floor().remainder(2);
        e.plot(
          x,
          y,
          z + rise * (1 - q),
          e.rampOf(c)[e.clamp(
            (y > yc ? 3 : 1) +
                row -
                (e.hash((x * 4).truncate(), (y * 9).truncate()) > .86 ? 1 : 0),
            0,
            4,
          )],
        );
      }
    }
    for (num y = y0 + .15; y <= y1 - .15; y += ST) {
      final q = (y - yc).abs() / half;
      for (num h = 0; h <= rise * (1 - q); h += ST) {
        e.plot(x1 - .15, y, z + h, shade(wall, 1.3, y, h));
      }
    }
  }

  // mapa.js: flatRoof. A flat roof with a low parapet, the Caribbean concrete house
  void flatRoof(num x0, num y0, num x1, num y1, num z, List<num> c) {
    block(x0 - .08, y0 - .08, z, x1 + .08, y1 + .08, z + .14, c, [
      for (final v in c) v * .9,
    ]);
    block(x0 - .08, y0 - .08, z + .14, x1 + .08, y0 + .1, z + .34, c);
    block(x0 - .08, y0 - .08, z + .14, x0 + .1, y1 + .08, z + .34, c);
    block(x0 - .08, y1 - .1, z + .14, x1 + .08, y1 + .08, z + .34, c);
    block(x1 - .1, y0 - .08, z + .14, x1 + .08, y1 + .08, z + .34, c);
  }

  // mapa.js: shadowBox
  void shadowBox(num x0, num y0, num x1, num y1, num z1, [num r = .5]) {
    for (num x = x0; x <= x1; x += .4) {
      for (num y = y0; y <= y1; y += .4) {
        for (num z = .2; z <= z1; z += .5) {
          e.castShadow(x, y, z, r);
        }
      }
    }
  }

  // mapa.js: bush
  void bush(num x, num y, num r, [List<num>? c]) {
    final col = c ?? C.leaf;
    e.sphere(x, y, r * .7, r, col, 'rough');
    e.sphere(x + r * .5, y - r * .3, r * .55, r * .7, col, 'rough');
    e.castShadow(x, y, r, r * .9);
  }

  // mapa.js: palm
  void palm(num x, num y, [num h = 3.4, num lean = .5, num seed = 0]) {
    final top = [x + lean * .7, y - lean * .5, h];
    e.capsule(
      [x, y, 0],
      [x + lean * .25, y - lean * .15, h * .5],
      .16,
      .13,
      (_) => C.palm,
      'rough',
    );
    e.capsule(
      [x + lean * .25, y - lean * .15, h * .5],
      top,
      .13,
      .11,
      (_) => C.palm,
      'rough',
    );
    for (var f = 0; f < 8; f++) {
      final a = f / 8 * 6.283 + seed,
          dx = math.cos(a),
          dy = math.sin(a),
          len = 1.25 + e.hash(f, seed) * .4;
      for (num t = 0; t <= 1; t += .035) {
        final px = top[0] + dx * len * t,
            py = top[1] + dy * len * t,
            pz = top[2] + .25 * t - 1.05 * t * t;
        final w = .2 * math.sin(t * math.pi) + .04;
        for (final s in const [-1, 0, 1]) {
          final qx = px - dy * w * s * .9, qy = py + dx * w * s * .9;
          e.plot(
            qx,
            qy,
            pz - s.abs() * .05,
            e.rampOf(C.leaf)[e.clamp(
              _round(2 + (dx + dy) * .7 + (s == 0 ? .6 : -.2) - t * .6),
              0,
              4,
            )],
          );
        }
      }
      for (num t = 0; t <= 1; t += .2) {
        e.castShadow(
          top[0] + dx * len * t,
          top[1] + dy * len * t,
          top[2] - .5 * t,
          .22,
        );
      }
    }
    e.sphere(top[0], top[1], top[2] - .12, .18, const [120, 92, 48], 'rough');
    for (num z = .4; z < h; z += .5) {
      e.castShadow(x + lean * z / h * .6, y - lean * z / h * .4, z, .14);
    }
  }

  // mapa.js: bakeAdd
  void bakeAdd(List<num> a, List<num> b, num r0, num r1, ColorOf f) {
    e.capsule(a, b, r0, r1, f, 'solid');
    e.pendingShadows.addAll([a, r0, b, r1]);
  }

  // mapa.js: person
  void person(
    num x,
    num y,
    num yaw,
    FigurePalette palette, [
    Pose pose = const {},
  ]) {
    e.figure(x, y, yaw, {'scale': .62, ...pose}, palette, bakeAdd);
  }
}

// Math.round (page 12, section 6)
int _round(num x) => (x + .5).floor();
