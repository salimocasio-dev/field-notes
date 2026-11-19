// TEST-ONLY. A port of the parts of pixel/mapa.js that make the map's island with no places: the layout, the
// island's shape, the ground colours, `slabSides`, `freeSpot` and `decorate`, with the calls in the order
// coqui/ref/pp/island/calls.md gives. The map itself is order 13's (feature_map); none of this goes to lib/.
//
// The names of the old file are kept, capitals included.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

/// mapa.js: KIND_SAND, KIND_WATER, KIND_ROAD (the engine has KIND_NONE and KIND_GRASS)
const int KIND_SAND = 1, KIND_WATER = 2, KIND_ROAD = 4;

/// mapa.js: the ground the dioramas lay down: {hit(x,y), color(x,y,ix,iy,i)}
class Patch {
  Patch(this.hit, this.color);
  final bool Function(double x, double y) hit;
  final int Function(double x, double y, int ix, int iy, int i) color;
}

/// Records a call `decorate` makes to the engine: the function and its arguments.
typedef DecorateCall = ({String fn, List<Object?> args});

class IslandBuild {
  IslandBuild(this.e, this.b);

  final PpEngine e;
  final PpBuild b;
  PpPalette get C => b.C;

  // mapa.js: XY, UV
  ({double x, double y}) XY(double u, double v) =>
      (x: (v + u) / e.R2, y: (v - u) / e.R2);
  ({double u, double v}) UV(double x, double y) =>
      (u: (x - y) / e.R2, v: (x + y) / e.R2);

  // ---------- layout ----------
  static const List<List<double>> PADS = [
    [0, 40],
    [-5, 25],
    [5, 25],
    [0, 10],
    [-5, -5],
    [5, -5],
    [-5, -20],
    [5, -20],
    [0, -34],
    [0, -46],
  ];
  static const List<List<double>> DIO = [
    [0, 34.6],
    [-9.7, 25],
    [9.7, 25],
    [0, 4.8],
    [-9.7, -5],
    [9.7, -5],
    [-9.7, -20],
    [9.7, -20],
    [-6.8, -34.5],
    [0, -51.6],
  ];
  static const List<List<int>> ROAD = [
    [0, 1],
    [0, 2],
    [1, 3],
    [2, 3],
    [3, 4],
    [3, 5],
    [4, 5],
    [4, 6],
    [5, 7],
    [6, 7],
    [6, 8],
    [7, 8],
    [8, 9],
  ];

  // mapa.js: legs. A road leaves the lower stop sideways, then climbs straight up to the higher one
  List<List<List<double>>> legs(int a, int b) {
    final A = PADS[a], B = PADS[b];
    if (A[0] == B[0] || A[1] == B[1]) {
      return [
        [A, B],
      ];
    }
    return [
      [
        A,
        [B[0], A[1]],
      ],
      [
        [B[0], A[1]],
        B,
      ],
    ];
  }

  // mapa.js: SEGS
  late final List<List<List<double>>> SEGS = [
    for (final r in ROAD) ...legs(r[0], r[1]),
  ];

  // mapa.js: segDist
  double segDist(double u, double v, List<List<double>> s) {
    final u0 = s[0][0], v0 = s[0][1], u1 = s[1][0], v1 = s[1][1];
    final du = u1 - u0, dv = v1 - v0, l = du * du + dv * dv;
    final t = l != 0
        ? e.clamp(((u - u0) * du + (v - v0) * dv) / l, 0.0, 1.0)
        : 0.0;
    return _hypot(u - u0 - du * t, v - v0 - dv * t);
  }

  // mapa.js: roadDist
  double roadDist(double u, double v) =>
      SEGS.map((s) => segDist(u, v, s)).reduce(math.min);

  // ---------- island shape ----------
  // mapa.js: islandSd
  double islandSd(double u, double v) {
    const A = 15.4, B = 52.6, vc = -5.5, r = 7;
    final qx = u.abs() - (A - r), qy = (v - vc).abs() - (B - r);
    return _hypot(math.max(qx, 0), math.max(qy, 0)) +
        math.min(math.max(qx, qy), 0) -
        r +
        (e.noise(u * .33 + 4, v * .33) - .5) * 1.8;
  }

  /// mapa.js: patches
  final List<Patch> patches = [];

  /// mapa.js: waterPix, i, u, v, sd four entries a pixel
  final List<num> waterPix = [];

  // mapa.js: groundColor
  int groundColor(double x, double y, int ix, int iy, int i) {
    final uv = UV(x, y), u = uv.u, v = uv.v;
    final sd = islandSd(u, v);
    if (sd > 0) return 0;
    if (sd > -.5 && e.hash(ix, iy) < (sd + .5) / .5 * .8) return 0;
    if (sd > -2.7) {
      e.kinds[i] = KIND_WATER;
      waterPix.addAll([i, u, v, sd]);
      return b.toneOf(
        C.sea,
        .15 +
            e.clamp<double>((-sd) / 2.7, 0, 1) * .75 +
            (e.noise(u * .5, v * .3) - .5) * .3,
        ix,
        iy,
      );
    }
    final beach = -3.9 - e.noise(u * .6, v * .6) * 1.1;
    for (final p in patches) {
      if (p.hit(x, y)) {
        final c = p.color(x, y, ix, iy, i);
        if (c != 0) return c;
      }
    }
    for (var k = 0; k < PADS.length; k++) {
      final d = _hypot(u - PADS[k][0], v - PADS[k][1]);
      if (d < 1.55) {
        e.kinds[i] = KIND_ROAD;
        return d > 1.25
            ? e.rgb(C.stone[0] * .62, C.stone[1] * .62, C.stone[2] * .62)
            : b.toneOf(C.pave, .55 + e.noise(u * 3, v * 3) * .45, ix, iy);
      }
    }
    if (sd > beach) {
      e.kinds[i] = KIND_SAND;
      return b.toneOf(C.sand, .2 + e.noise(u * 2, v * 2) * .8, ix, iy);
    }
    final rd = roadDist(u, v);
    if (rd < .72) {
      e.kinds[i] = KIND_ROAD;
      final edge = rd > .56;
      return edge
          ? b.toneOf(C.path, .05, ix, iy)
          : b.toneOf(
              C.path,
              .35 + e.noise(u * 2.5, v * 2.5) * .6 + (e.hash(ix, iy) - .5) * .3,
              ix,
              iy,
            );
    }
    e.kinds[i] = e.KIND_GRASS;
    final t = e.noise(u * .5, v * .5) * 1.15 + (e.hash(ix, iy) - .5) * .5 - .05;
    final g = e.GRASS[e.clamp((t * 4.2).floor(), 0, 3)];
    return e.rgb(g[0], g[1], g[2]);
  }

  // mapa.js: slabSides. The island floats: under its front edges, a band of deep water and then layered earth
  void slabSides() {
    const T = 14;
    for (var ix = 0; ix < e.W; ix++) {
      var last = -1;
      for (var iy = 0; iy < e.H; iy++) {
        final i = iy * e.W + ix;
        if (e.ground[i] != 0) {
          last = iy;
          continue;
        }
        if (last < 0 || iy - last > T || e.pix[i] != 0) continue;
        final k = iy - last,
            g = e.unproject(ix + .5, last + .5),
            right = UV(g.x, g.y).u > 0;
        int c;
        if (k <= 3) {
          c = e.rampOf(const [30, 90, 120])[right ? 1 : 2];
        } else {
          final layer = k + _round(math.sin(ix * .35) * 1.2);
          final base = layer < 7
              ? const [150, 112, 74]
              : layer < 11
              ? const [120, 88, 62]
              : const [92, 70, 58];
          c =
              e.rampOf(base)[e.clamp(
                (right ? 1 : 2) +
                    (e.bayerAt(ix, iy) > .8 ? 1 : 0) -
                    (e.hash(ix, iy) > .93 ? 1 : 0) -
                    (k == T ? 1 : 0),
                0,
                4,
              )];
        }
        e.pix[i] = c;
      }
    }
  }

  // mapa.js: freeSpot
  bool freeSpot(double u, double v, double r) {
    if (roadDist(u, v) < r + 1) return false;
    for (final p in PADS) {
      if (_hypot(u - p[0], v - p[1]) < r + 2) return false;
    }
    for (final d in DIO) {
      if ((u - d[0]).abs() < r + 3.6 && (v - d[1]).abs() < r + 4.2) {
        return false;
      }
    }
    return true;
  }

  // mapa.js: decorate. Palms on the beach, bushes in the grass. [onCall] hears each call to palm, bush and sphere
  // that decorate itself makes, so a test can compare the list with decorate-calls.json
  void decorate([void Function(DecorateCall call)? onCall]) {
    void palm(double x, double y, double h, double lean, int seed) {
      onCall?.call((fn: 'palm', args: [x, y, h, lean, seed]));
      b.palm(x, y, h, lean, seed);
    }

    void bush(double x, double y, double r, List<num> c) {
      onCall?.call((fn: 'bush', args: [x, y, r, c]));
      b.bush(x, y, r, c);
    }

    void sphere(
      double x,
      double y,
      double z,
      double r,
      List<num> c,
      String mode,
    ) {
      onCall?.call((fn: 'sphere', args: [x, y, z, r, c, mode]));
      e.sphere(x, y, z, r, c, mode);
    }

    for (var k = 0; k < 220; k++) {
      final u = (e.hash(k, 61) - .5) * 30,
          v = -58 + e.hash(k, 62) * 106,
          sd = islandSd(u, v);
      if (sd > -3.8) continue;
      final xy = XY(u, v), x = xy.x, y = xy.y;
      if (sd > -5.6) {
        if (e.hash(k, 63) < .35 && freeSpot(u, v, .8)) {
          palm(
            x,
            y,
            2.6 + e.hash(k, 64) * 1,
            (u > 0 ? 1 : -1) * (.5 + e.hash(k, 65) * .4) * .7,
            k,
          );
        }
        continue;
      }
      if (e.hash(k, 66) < .5 && freeSpot(u, v, .5)) {
        bush(
          x,
          y,
          .3 + e.hash(k, 67) * .35,
          e.hash(k, 68) > .5 ? C.leaf : const [96, 150, 70],
        );
      } else if (e.hash(k, 69) < .3 && freeSpot(u, v, .3)) {
        for (var f = 0; f < 5; f++) {
          sphere(
            x + (e.hash(k, f) - .5) * .8,
            y + (e.hash(f, k) - .5) * .8,
            .06,
            .08,
            f % 2 != 0 ? const [244, 120, 140] : const [250, 230, 120],
            'solid',
          );
        }
      }
    }
  }

  /// The calls of coqui/ref/pp/island/calls.md, in order: the first statements of `bake()`, the ground loop,
  /// `slabSides`, `growGrass`, `groundZ.set(zb)`, `decorate`. The counts it stops at are for the test to read.
  void build([void Function(DecorateCall call)? onCall]) {
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.pix.fillRange(0, e.pix.length, 0);
    e.kinds.fillRange(0, e.kinds.length, 0);
    waterPix.clear();
    for (var iy = 0; iy < e.H; iy++) {
      for (var ix = 0; ix < e.W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * e.W + ix,
            c = groundColor(g.x, g.y, ix, iy, i);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
      }
    }
    slabSides();
    e.growGrass();
    e.groundZ.setAll(0, e.zb);
    decorate(onCall);
  }
}

// Math.hypot of two numbers (page 12, section 6)
double _hypot(num a, num b) => math.sqrt(a * a + b * b);

// Math.round (page 12, section 6)
int _round(num x) => (x + .5).floor();
