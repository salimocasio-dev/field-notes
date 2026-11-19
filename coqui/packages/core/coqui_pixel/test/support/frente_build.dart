// TEST-ONLY. A port of pixel/frente-set.html: El frente's set, the one state it draws today (door open, shutters
// open, a porch lamp lit), with S = 26, originX = -30, originY = 40. It repeats the page's calls in order. The set
// of El frente is order 14's (coqui_scenes); none of this goes to lib/.
//
// The names of the old file are kept, capitals included.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

import 'island_build.dart' show KIND_ROAD;

/// The engine El frente is built on (frente-set.html: `PP_SCENE`).
PpEngine frenteEngine() => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -30,
  originY: 40,
  shadowX: .9,
  shadowY: -.1,
);

class FrenteBuild {
  FrenteBuild(this.e, this.b);

  final PpEngine e;
  final PpBuild b;
  PpPalette get C => b.C;
  double get ST => b.ST;

  static const double HX0 = -4.2,
      HX1 = 3.0,
      HY0 = -3.6,
      HY1 = 0,
      HH = 3.3,
      DOOR0 = .45,
      DOOR1 = 1.85,
      DH = 2.55;
  static const List<int> TEAL = [92, 190, 186];

  // frente-set.html: sceneGround
  int sceneGround(double x, double y, int ix, int iy, int i) {
    // porch slab and step are blocks; the path runs from the step to the front of the frame
    final pathHalf = .75 + math.max(0, y - 1.7) * .12;
    if (y > 1.6 && (x - (DOOR0 + DOOR1) / 2).abs() < pathHalf) {
      e.kinds[i] = KIND_ROAD;
      final sx = ((y - 1.6) / .9).floor(),
          stone = e.hash(sx, ((x + 8) / .9).floor());
      final gap =
          ((y - 1.6).remainder(.9)) < .1 ||
          ((x + 8 + sx * .45).remainder(.9)).abs() < .08;
      return gap
          ? e.rgb(C.stone[0] * .6, C.stone[1] * .6, C.stone[2] * .6)
          : b.toneOf(
              C.pave,
              .3 + stone * .6 + (e.hash(ix, iy) - .5) * .2,
              ix,
              iy,
            );
    }
    if (y > -4.6 && y < -3.6 && x > HX0 - 1 && x < HX1 + 1) {
      e.kinds[i] = e.KIND_GRASS;
    }
    e.kinds[i] = e.KIND_GRASS;
    final t = e.noise(x * .45, y * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
    final g = e.GRASS[e.clamp((t * 4.2).floor() + 1, 0, 4)];
    return e.rgb(g[0], g[1], g[2]);
  }

  // frente-set.html: bigPalm
  void bigPalm(double x, double y, double h, double lean, num seed) {
    final top = [x + lean * .7, y - lean * .5, h];
    e.capsule(
      [x, y, 0],
      [x + lean * .25, y - lean * .15, h * .5],
      .2,
      .16,
      (_) => C.palm,
      'rough',
    );
    e.capsule(
      [x + lean * .25, y - lean * .15, h * .5],
      top,
      .16,
      .13,
      (_) => C.palm,
      'rough',
    );
    for (var f = 0; f < 9; f++) {
      final a = f / 9 * 6.283 + seed,
          dx = math.cos(a),
          dy = math.sin(a),
          len = 1.6 + e.hash(f, seed) * .5;
      for (num t = 0; t <= 1; t += .012) {
        final px = top[0] + dx * len * t,
            py = top[1] + dy * len * t,
            pz = top[2] + .3 * t - 1.3 * t * t,
            w = .32 * math.sin(t * math.pi) + .03;
        for (num s = -1; s <= 1; s += .12) {
          final leaflet =
              s.abs() > .2 && ((t * 40).truncate().remainder(2)) == 0;
          if (leaflet && s.abs() > .7) continue;
          e.plot(
            px - dy * w * s,
            py + dx * w * s,
            pz - s.abs() * w * .5,
            e.rampOf(C.leaf)[e.clamp(
              _round(2.2 + (dx + dy) * .6 - s.abs() * .8 + (s > 0 ? .4 : -.2)),
              0,
              4,
            )],
          );
        }
      }
      for (num t = 0; t <= 1; t += .15) {
        e.castShadow(
          top[0] + dx * len * t,
          top[1] + dy * len * t,
          top[2] - .6 * t,
          .3,
        );
      }
    }
    e.sphere(top[0], top[1], top[2] - .15, .22, const [120, 92, 48], 'rough');
    for (num z = .4; z < h; z += .4) {
      e.castShadow(x + lean * z / h * .6, y - lean * z / h * .4, z, .18);
    }
  }

  // frente-set.html: louvre. A white shutter flat against the front wall
  void louvre(double a0, double a1, double z0, double z1) {
    for (num a = a0; a <= a1; a += ST * .6) {
      for (num z = z0; z <= z1; z += ST * .6) {
        final slat = ((z - z0) / .11).floor().remainder(2),
            edge = a - a0 < .06 || a1 - a < .06 || z - z0 < .06 || z1 - z < .06;
        e.plot(
          a,
          HY1 + .05,
          z,
          e.rampOf(C.white)[edge
              ? 2
              : slat != 0
              ? 3
              : 2],
        );
      }
    }
  }

  // frente-set.html: buildSet
  void buildSet() {
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.pix.fillRange(0, e.pix.length, 0);
    for (var iy = 0; iy < e.H; iy++) {
      for (var ix = 0; ix < e.W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * e.W + ix,
            c = sceneGround(g.x, g.y, ix, iy, i);
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
      }
    }
    e.growGrass();
    e.groundZ.setAll(0, e.zb);
    // the house
    b.block(HX0, HY0, 0, HX1, HY1, HH, TEAL);
    // a darker band at the foot of the walls
    b.onWall('y', HY1, HX0, HX1, 0, .35, e.rampOf(TEAL)[1]);
    b.onWall('x', HX1, HY0, HY1, 0, .35, e.rampOf(TEAL)[0]);
    // window with open louvred shutters, and a flower box
    const wa = -2.3, wz = 1.75, ww = 1.4, wh = 1.25;
    b.onWall(
      'y',
      HY1,
      wa - ww / 2 - .1,
      wa + ww / 2 + .1,
      wz - wh / 2 - .1,
      wz + wh / 2 + .1,
      e.rampOf(C.white)[3],
    );
    for (num a = wa - ww / 2; a <= wa + ww / 2; a += ST * .5) {
      for (num z = wz - wh / 2; z <= wz + wh / 2; z += ST * .5) {
        final bar = (a - wa).abs() < .05 || (z - wz).abs() < .05,
            curtain =
                (a < wa - ww / 2 + .28 || a > wa + ww / 2 - .28) &&
                z > wz - wh / 2 + .15;
        e.plot(
          a,
          HY1 + .04,
          z,
          bar
              ? e.rampOf(C.white)[3]
              : curtain
              ? e.rampOf(const [236, 120, 130])[2 +
                    ((a * 14).truncate().remainder(2))]
              : e.rampOf(const [70, 96, 130])[z > wz + .25 ? 2 : 1],
        );
      }
    }
    louvre(wa - ww / 2 - .75, wa - ww / 2 - .12, wz - wh / 2, wz + wh / 2);
    louvre(wa + ww / 2 + .12, wa + ww / 2 + .75, wz - wh / 2, wz + wh / 2);
    b.block(
      wa - ww / 2 - .15,
      HY1,
      wz - wh / 2 - .42,
      wa + ww / 2 + .15,
      HY1 + .35,
      wz - wh / 2 - .12,
      C.wood,
    );
    const flowers = [
      [255, 143, 184],
      [255, 224, 112],
      [244, 88, 74],
    ];
    for (var k = 0; k < 9; k++) {
      e.sphere(
        wa - ww / 2 + k * .17,
        HY1 + .2,
        wz - wh / 2 - .02,
        .1,
        flowers[k % 3],
        'solid',
      );
    }
    // the door, open, dark inside, the leaf swung in
    b.onWall(
      'y',
      HY1,
      DOOR0 - .14,
      DOOR1 + .14,
      0,
      DH + .14,
      e.rampOf(C.white)[3],
    );
    for (num a = DOOR0; a <= DOOR1; a += ST * .5) {
      for (num z = 0; z <= DH; z += ST * .5) {
        e.plot(
          a,
          HY1 + .04,
          z,
          e.rampOf(const [52, 36, 28])[z > 1.9
              ? 1
              : z > .9
              ? 1
              : 0],
        );
      }
    }
    for (num t = 0; t <= 1; t += ST * .4) {
      for (num z = 0; z <= DH; z += ST * .5) {
        e.plot(
          DOOR1 - .06 - t * .45,
          HY1 + .04 - t * .88,
          z,
          e.rampOf(C.wood)[t > .92 ? 3 : 2],
        );
      }
    }
    // the porch lamp, lit
    b.block(DOOR1 + .35, HY1, 2.05, DOOR1 + .6, HY1 + .18, 2.4, C.dark);
    e.sphere(DOOR1 + .47, HY1 + .26, 2.25, .14, C.lamp, 'gloss');
    // side window
    b.windowOn('x', HX1, HY0 + 1.6, 1.8, 1, 1, C.white, C.glass);
    // red gable roof, ridge along x
    b.gable(HX0 - .35, HY0 - .45, HX1 + .35, HY1 + .45, HH, 1.35, C.red, TEAL);
    // porch slab and step
    b.block(HX0 - .1, HY1, 0, HX1 + .1, HY1 + 1.25, .16, C.stone);
    b.block(DOOR0 - .2, HY1 + 1.25, 0, DOOR1 + .2, HY1 + 1.65, .08, C.stone);
    // garden
    bigPalm(HX1 + 2.2, HY0 - 1.4, 5.2, .5, 2);
    b.bush(HX1 + .9, HY1 + .6, .45, const [96, 150, 70]);
    b.bush(HX0 - .6, HY1 + 2.2, .5);
    b.bush(HX1 + .9, HY0 + .6, .6);
    b.block(HX1 - .75, HY1 + .55, .16, HX1 - .35, HY1 + .95, .6, const [
      220,
      120,
      60,
    ]);
    e.sphere(HX1 - .55, HY1 + .75, .85, .32, C.leaf, 'rough');
    // shadows
    b.shadowBox(HX0, HY0, HX1, HY1, HH + 1, .6);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // frente-set.html: window.SPOTS. Where the characters stand, so the composite can place them and the engine can
  // cast their shadows
  static const Map<String, List<double>> SPOTS = {
    'abuela': [(DOOR0 + DOOR1) / 2 - .1, HY1 + .2, .16],
    'coqui': [(DOOR0 + DOOR1) / 2 - .1, HY1 + 3.0, 0],
  };

  /// The page's script: `buildSet()`, then the characters' shadows cast by the engine onto the porch and the
  /// path, then `drawLeaves(0); drawTufts(0)`. What the page leaves in `pix`, `zb` and `kinds` is the reference.
  void run() {
    buildSet();
    // the characters' shadows, cast by the engine onto the porch and the path
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final abuela = SPOTS['abuela']!, coqui = SPOTS['coqui']!;
    for (num z = .3; z <= 2; z += .35) {
      e.castShadow(abuela[0], abuela[1], z + abuela[2], .35);
    }
    e.castShadow(coqui[0], coqui[1], .3, .45);
    e.applyShadows(e.groundZ);
    e.drawLeaves(0);
    e.drawTufts(0);
  }
}

// Math.round (page 12, section 6)
int _round(num x) => (x + .5).floor();
