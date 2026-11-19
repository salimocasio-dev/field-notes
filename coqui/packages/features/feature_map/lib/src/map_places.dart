// A port of the ten places of pixel/mapa.js: the `PLACES` builders, one small diorama each, in the order of the
// course's places (casa, parque, cocina, colmado, calle, plaza, playa, fonda, casa2, fuerte). Pure Dart.
//
// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_map/src/map_layout.dart';

/// mapa.js: the ground the dioramas lay down: {hit(x,y), color(x,y,ix,iy,i)}. `owner` is the place that made it
/// (set by the patch pass of `bake`).
class Patch {
  Patch(this.hit, this.color);

  final bool Function(double x, double y) hit;
  final int Function(double x, double y, int ix, int iy, int i) color;
  int? owner;
}

/// mapa.js: PLACES. Each builder draws into the engine [e] with the helpers [b]; the ones that lay down ground
/// (the pond, the street, the square, the beach) hand it to [addPatch].
class MapPlaces {
  MapPlaces(this.e, this.b, this.addPatch, this.waterPix);

  final PpEngine e;
  final PpBuild b;

  /// mapa.js: `patches.push`
  final void Function(Patch p) addPatch;

  /// mapa.js: waterPix, i, u, v, sd four entries a pixel
  final List<num> waterPix;

  PpPalette get C => b.C;
  double get ST => b.ST;
  double get FACE => b.FACE;

  /// The ten builders, in the order of the course's places. Each takes the place's centre in world x, y.
  late final List<void Function(double cx, double cy)> builders = [
    casa,
    parque,
    cocina,
    colmado,
    calle,
    plaza,
    playa,
    fonda,
    casa2,
    fuerte,
  ];

  // Math.round (page 12, section 6)
  int _round(num x) => (x + .5).floor();

  // mapa.js: PLACES.casa. 1 · Grandma's house: a teal concrete casita, red roof, a palm, abuela at the door
  void casa(double cx, double cy) {
    b.block(cx - 1.6, cy - 1.4, 0, cx + 1.6, cy + 1.4, 2, C.teal);
    b.windowOn('y', cy + 1.4, cx - .8, 1.15, .6, .7);
    b.windowOn('x', cx + 1.6, cy - .5, 1.15, .6, .7);
    b.onWall('y', cy + 1.4, cx + .35, cx + 1.05, 0, 1.45, e.rampOf(C.wood)[2]);
    b.onWall('y', cy + 1.4, cx + .9, cx + .95, .65, .75, e.rgb(240, 210, 100));
    b.gable(cx - 1.85, cy - 1.7, cx + 1.85, cy + 1.7, 2, 1.1, C.red, C.teal);
    b.block(cx + .25, cy + 1.4, 0, cx + 1.15, cy + 2.1, .14, C.stone);
    b.shadowBox(cx - 1.6, cy - 1.4, cx + 1.6, cy + 1.4, 2.8, .6);
    b.palm(cx - 2.6, cy + 1.2, 3.2, .7, 1);
    b.bush(cx + 2.2, cy - .6, .45, const [96, 150, 70]);
    for (var k = 0; k < 6; k++) {
      e.sphere(cx - 1.4 + k * .28, cy + 1.75, .12, .13, [
        k.remainder(2) != 0 ? 236 : 250,
        k.remainder(2) != 0 ? 90 : 200,
        k.remainder(2) != 0 ? 120 : 80,
      ], 'solid');
    }
    b.person(cx + .7, cy + 2.4, FACE, const {
      'shirt': [128, 78, 160],
      'stripe': [150, 98, 178],
      'legs': [128, 78, 160],
      'hair': [232, 230, 224],
      'skin': [176, 122, 88],
    });
  }

  // mapa.js: PLACES.parque. 2 · the park: a pond with a duck, two trees, a bench
  void parque(double cx, double cy) {
    final px = cx + .5, py = cy + .9;
    addPatch(
      Patch((x, y) => hypot((x - px) / 1.9, (y - py) / 1.5) < 1, (
        x,
        y,
        ix,
        iy,
        i,
      ) {
        final d = hypot((x - px) / 1.9, (y - py) / 1.5);
        if (d > .86) return b.toneOf(C.sand, .4, ix, iy);
        e.kinds[i] = KIND_WATER;
        final uv = UV(x, y);
        waterPix.addAll([i, uv.u, uv.v, -1]);
        return b.toneOf(C.pond, .2 + d * .7, ix, iy);
      }),
    );
    e.growTree(cx - 1.3, cy - 1.5, .62, 260, 200);
    e.growTree(cx + 1.6, cy - 1.9, .52, 220, 700);
    b.bush(cx + 2.3, cy + .2, .4, const [96, 150, 70]);
    b.block(cx - 1.9, cy + 1.2, .3, cx - 1.6, cy + 2.4, .38, C.wood);
    b.block(cx - 2.05, cy + 1.2, .38, cx - 1.95, cy + 2.4, .75, C.wood);
    for (final y in const [1.3, 2.3]) {
      b.block(cx - 1.9, cy + y, 0, cx - 1.8, cy + y + .08, .3, C.woodD);
    }
    e.sphere(px + .3, py + .1, .12, .2, const [244, 242, 232], 'solid');
    e.sphere(px + .42, py + .2, .32, .11, const [244, 242, 232], 'solid');
    e.sphere(px + .5, py + .26, .3, .05, const [240, 160, 40], 'solid');
  }

  // mapa.js: PLACES.cocina. 3 · the kitchen: a cut-away room, tiled floor, stove with a pot, table, fridge
  void cocina(double cx, double cy) {
    final x0 = cx - 1.8, y0 = cy - 1.8, x1 = cx + 1.8, y1 = cy + 1.8;
    for (num a = x0; a <= x1; a += ST) {
      for (num bb = y0; bb <= y1; bb += ST) {
        e.plot(
          a,
          bb,
          .12,
          e.rampOf(
            (((a - x0).floor() * 2 + ((bb - y0) * 2).floor()).remainder(2) != 0
                ? const [236, 230, 214]
                : const [196, 120, 90]),
          )[3],
        );
      }
    }
    for (num a = x0; a <= x1; a += ST) {
      for (num z = 0; z <= .12; z += ST) {
        e.plot(a, y1, z, e.rampOf(C.stone)[2]);
      }
    }
    for (num bb = y0; bb <= y1; bb += ST) {
      for (num z = 0; z <= .12; z += ST) {
        e.plot(x1, bb, z, e.rampOf(C.stone)[1]);
      }
    }
    b.block(x0, y0, 0, x0 + .2, y1, 2.3, C.yellow);
    b.block(x0, y0, 0, x1, y0 + .2, 2.3, C.yellow);
    b.windowOn('y', y0 + .2, cx + .4, 1.4, .9, .7, C.white, const [
      140,
      190,
      220,
    ]);
    b.block(x0 + .25, y0 + .25, .12, x0 + .95, y0 + 1.1, 2, C.white);
    b.onWall('y', y0 + 1.1, x0 + .32, x0 + .88, 1.2, 1.24, e.rampOf(C.grey)[1]);
    b.block(x0 + 1.2, y0 + .25, .12, x0 + 2.1, y0 + .95, 1, C.white);
    for (final d in const [
      [.22, .22],
      [.62, .22],
      [.22, .55],
      [.62, .55],
    ]) {
      for (num t = 0; t < 6.3; t += .3) {
        e.plot(
          x0 + 1.2 + d[0] + math.cos(t) * .12,
          y0 + .25 + d[1] + math.sin(t) * .1,
          1.02,
          e.rgb(30, 28, 32),
        );
      }
    }
    e.sphere(x0 + 1.62, y0 + .5, 1.2, .2, const [200, 70, 50], 'solid');
    b.block(x0 + 1.5, y0 + .44, 1.36, x0 + 1.74, y0 + .56, 1.4, const [
      60,
      50,
      50,
    ]);
    b.block(cx + .1, cy + .2, .9, cx + 1.3, cy + 1.2, 1, const [190, 130, 80]);
    for (final d in const [
      [0, 0],
      [1.1, 0],
      [0, .9],
      [1.1, .9],
    ]) {
      b.block(
        cx + .1 + d[0],
        cy + .2 + d[1],
        .12,
        cx + .2 + d[0],
        cy + .3 + d[1],
        .9,
        C.woodD,
      );
    }
    e.sphere(cx + .5, cy + .6, 1.06, .16, const [244, 240, 228], 'solid');
    e.sphere(cx + .5, cy + .6, 1.1, .1, const [240, 200, 90], 'solid');
    b.shadowBox(x0, y0, x0 + .2, y1, 2.3);
    b.shadowBox(x0, y0, x1, y0 + .2, 2.3);
  }

  // mapa.js: PLACES.colmado. 4 · the corner shop: a yellow colmado, striped awning, fruit crates
  void colmado(double cx, double cy) {
    b.block(cx - 1.8, cy - 1.3, 0, cx + 1.8, cy + 1.3, 2.1, C.yellow);
    b.flatRoof(cx - 1.8, cy - 1.3, cx + 1.8, cy + 1.3, 2.1, C.white);
    b.onWall('y', cy + 1.3, cx - .5, cx + .5, 0, 1.4, e.rampOf(C.dark)[1]);
    b.windowOn('y', cy + 1.3, cx - 1.2, .95, .7, .8, C.white, C.glass);
    b.windowOn('y', cy + 1.3, cx + 1.2, .95, .7, .8, C.white, C.glass);
    b.onWall('y', cy + 1.3, cx - 1.5, cx + 1.5, 1.75, 2, e.rampOf(C.red)[3]);
    for (num a = cx - 1.85; a <= cx + 1.85; a += ST) {
      for (num t = 0; t <= .7; t += ST) {
        e.plot(
          a,
          cy + 1.3 + t,
          1.6 - t * .55,
          e.rampOf(
            ((a - cx) * 2.5 + 20).floor().remainder(2) != 0 ? C.red : C.white,
          )[t > .62 ? 2 : 3],
        );
      }
    }
    for (num a = cx - 1.85; a <= cx + 1.85; a += ST) {
      e.castShadow(a, cy + 1.6, 1.3, .3);
    }
    void crate(double x, double y, List<num> fruit) {
      b.block(x, y, 0, x + .55, y + .45, .35, C.wood);
      for (var k = 0; k < 4; k++) {
        e.sphere(
          x + .14 + k.remainder(2) * .26,
          y + .12 + (k >> 1) * .2,
          .42,
          .11,
          fruit,
          'solid',
        );
      }
    }

    crate(cx - 1.7, cy + 1.7, const [240, 150, 40]);
    crate(cx - 1.05, cy + 1.75, const [120, 180, 60]);
    crate(cx + 1.0, cy + 1.7, const [220, 60, 50]);
    b.shadowBox(cx - 1.8, cy - 1.3, cx + 1.8, cy + 1.3, 2.4, .6);
    b.person(cx + .1, cy + 1.75, FACE, const {
      'shirt': [236, 236, 228],
      'stripe': [236, 236, 228],
      'legs': [60, 66, 90],
      'hair': [40, 30, 26],
      'skin': [200, 146, 104],
    });
  }

  // mapa.js: PLACES.calle. 5 · the street: asphalt, a crossing, a lamp, a bus stop and a parked car
  void calle(double cx, double cy) {
    addPatch(
      Patch((x, y) => inBox(x, y, cx - 2.9, cy - .5, cx + 2.9, cy + 1.2), (
        x,
        y,
        ix,
        iy,
        i,
      ) {
        e.kinds[i] = KIND_ROAD;
        if ((y - cy - .35).abs() < .05 &&
            ((x - cx) * 2).floor().remainder(2) == 0) {
          return e.rgb(240, 214, 90);
        }
        if (x > cx - .9 &&
            x < cx + .1 &&
            ((y - cy) * 4.5).floor().remainder(2) == 0) {
          return e.rgb(236, 236, 230);
        }
        return b.toneOf(C.asphalt, .3 + e.noise(x * 3, y * 3) * .6, ix, iy);
      }),
    );
    addPatch(
      Patch(
        (x, y) => inBox(x, y, cx - 2.9, cy - 1.6, cx + 2.9, cy - .5),
        (x, y, ix, iy, i) => b.toneOf(
          C.pave,
          .5 + ((x - cx) * 2).floor().remainder(2) * .2,
          ix,
          iy,
        ),
      ),
    );
    final lx = cx + 1.9, ly = cy - 1;
    e.capsule([lx, ly, 0], [lx, ly, 2.6], .07, .06, (_) => C.dark, 'solid');
    e.capsule(
      [lx, ly, 2.6],
      [lx, ly + .5, 2.75],
      .06,
      .05,
      (_) => C.dark,
      'solid',
    );
    e.sphere(lx, ly + .55, 2.62, .14, C.lamp, 'gloss');
    for (num z = .3; z < 2.6; z += .4) {
      e.castShadow(lx, ly, z, .1);
    }
    b.block(cx - 2.2, cy - 1.5, 0, cx - .6, cy - 1.35, 1.6, const [
      120,
      170,
      210,
    ]);
    b.block(cx - 2.3, cy - 1.6, 1.6, cx - .5, cy - .7, 1.72, C.red);
    for (final x in [cx - 2.2, cx - .65]) {
      b.block(x, cy - .85, 0, x + .08, cy - .77, 1.6, C.grey);
    }
    b.block(cx - 2.0, cy - 1.3, .4, cx - .8, cy - 1.0, .5, C.wood);
    b.shadowBox(cx - 2.3, cy - 1.6, cx - .5, cy - .7, 1.7);
    // the car: body, cabin, wheels
    final kx = cx + .6, ky = cy - .3;
    b.block(kx - 1, ky, .22, kx + 1, ky + .9, .62, const [70, 140, 210]);
    b.block(
      kx - .5,
      ky + .08,
      .62,
      kx + .5,
      ky + .82,
      1,
      const [220, 236, 244],
      const [70, 140, 210],
    );
    for (final dx in const [-.6, .6]) {
      for (final dy in const [0, .9]) {
        e.sphere(kx + dx, ky + dy, .2, .2, const [30, 30, 34], 'solid');
      }
    }
    b.shadowBox(kx - 1, ky, kx + 1, ky + .9, 1);
  }

  // mapa.js: PLACES.plaza. 6 · the town square: paving, a clock tower, benches, a flamboyán
  void plaza(double cx, double cy) {
    addPatch(
      Patch((x, y) => inBox(x, y, cx - 2.8, cy - 2.6, cx + 2.6, cy + 2.6), (
        x,
        y,
        ix,
        iy,
        i,
      ) {
        e.kinds[i] = KIND_ROAD;
        final ring = math.max((x - cx).abs(), (y - cy).abs());
        return b.toneOf(
          C.pave,
          ((ring * 2).floor().remainder(2) != 0 ? .75 : .4) +
              (e.hash(ix >> 1, iy) - .5) * .2,
          ix,
          iy,
        );
      }),
    );
    b.block(cx - .5, cy - .5, 0, cx + .5, cy + .5, 3.4, C.white);
    b.gable(cx - .65, cy - .65, cx + .65, cy + .65, 3.4, .7, C.red, C.white);
    for (num t = 0; t < 6.3; t += .05) {
      for (num r = 0; r < .34; r += .04) {
        e.plot(
          cx + math.cos(t) * r * .2 - .02,
          cy + .5 + .02,
          2.8 + math.sin(t) * r,
          r > .28 ? e.rgb(40, 36, 46) : e.rgb(250, 248, 240),
        );
      }
    }
    b.onWall('y', cy + .5, cx - .02, cx + .02, 2.8, 3.06, e.rgb(30, 28, 32));
    b.onWall('y', cy + .5, cx, cx + .18, 2.78, 2.82, e.rgb(30, 28, 32));
    b.onWall('y', cy + .5, cx - .2, cx + .2, 0, .9, e.rampOf(C.dark)[1]);
    b.shadowBox(cx - .5, cy - .5, cx + .5, cy + .5, 3.6);
    e.growTree(cx - 1.8, cy - 1.6, .38, 130, 1300);
    for (final p in [
      [cx + 1.2, cy + 1.6],
      [cx - 1.9, cy + 1.2],
    ]) {
      final bx = p[0], by = p[1];
      b.block(bx, by, .3, bx + 1, by + .3, .38, C.wood);
      b.block(bx, by, .38, bx + 1, by + .08, .7, C.wood);
      b.shadowBox(bx, by, bx + 1, by + .3, .5, .3);
    }
    b.person(cx + 1.6, cy + 1.2, FACE + .4, const {
      'shirt': [86, 150, 210],
      'stripe': [86, 150, 210],
      'legs': [200, 180, 140],
      'hair': [176, 170, 160],
      'skin': [214, 160, 122],
    });
  }

  // mapa.js: PLACES.playa. 7 · the beach: sand to the water's edge, an umbrella, a towel, a palm
  void playa(double cx, double cy) {
    final c0 = UV(cx, cy);
    addPatch(
      Patch(
        (x, y) {
          final p = UV(x, y);
          return hypot((p.u - c0.u + 1.2) / 3.6, (p.v - c0.v) / 3.9) +
                  (e.noise(p.u * .9, p.v * .9) - .5) * .35 <
              1;
        },
        (x, y, ix, iy, i) {
          e.kinds[i] = KIND_SAND;
          return b.toneOf(C.sand, .3 + e.noise(x * 2, y * 2) * .7, ix, iy);
        },
      ),
    );
    final ux = cx + .4, uy = cy + .3;
    e.capsule([ux, uy, 0], [ux, uy, 1.8], .05, .05, (_) => C.white, 'solid');
    for (num a = 0; a < 6.283; a += .03) {
      for (num r = 0; r <= 1.2; r += .04) {
        e.plot(
          ux + math.cos(a) * r,
          uy + math.sin(a) * r,
          1.9 - r * .45,
          e.rampOf(
            (a / 6.283 * 8).floor().remainder(2) != 0 ? C.red : C.white,
          )[e.clamp(_round(2.6 + (math.sin(a) - math.cos(a)) * .5), 1, 4)],
        );
      }
    }
    for (num a = 0; a < 6.283; a += .4) {
      for (num r = .2; r <= 1.2; r += .4) {
        e.castShadow(ux + math.cos(a) * r, uy + math.sin(a) * r, 1.6, .35);
      }
    }
    for (num a = cx - .6; a <= cx + .2; a += ST) {
      for (num bb = cy + 1.1; bb <= cy + 2.3; bb += ST) {
        e.plot(
          a,
          bb,
          .03,
          e.rampOf(
            ((bb - cy) * 4).floor().remainder(2) != 0
                ? const [80, 170, 210]
                : C.yellow,
          )[3],
        );
      }
    }
    b.palm(cx - 1.8, cy - 1.4, 3.3, .9, 3);
    e.sphere(cx + 1.5, cy + 1.4, .22, .22, const [240, 90, 70], 'solid');
  }

  // mapa.js: PLACES.fonda. 8 · the diner: an orange fonda with a sign and tables outside
  void fonda(double cx, double cy) {
    b.block(cx - 1.6, cy - 1.6, 0, cx + 1.6, cy + .9, 2, C.peach);
    b.flatRoof(cx - 1.6, cy - 1.6, cx + 1.6, cy + .9, 2, C.white);
    b.onWall('y', cy + .9, cx - .3, cx + .4, 0, 1.4, e.rampOf(C.wood)[2]);
    b.windowOn('y', cy + .9, cx - 1.0, 1.0, .7, .7, C.white, C.glass, true);
    b.windowOn('x', cx + 1.6, cy - .4, 1.0, .9, .7, C.white, C.glass, true);
    b.block(cx - 1.2, cy + .9, 2.1, cx + .9, cy + 1.0, 2.6, C.red);
    b.onWall('y', cy + 1.0, cx - 1, cx + .7, 2.25, 2.45, e.rgb(250, 240, 210));
    b.shadowBox(cx - 1.6, cy - 1.6, cx + 1.6, cy + .9, 2.3, .6);
    for (final p in [
      [cx - .9, cy + 1.9],
      [cx + 1, cy + 1.7],
    ]) {
      final tx = p[0], ty = p[1];
      e.capsule([tx, ty, 0], [tx, ty, .6], .05, .05, (_) => C.dark, 'solid');
      for (num t = 0; t < 6.3; t += .1) {
        for (num r = 0; r < .38; r += .05) {
          e.plot(
            tx + math.cos(t) * r,
            ty + math.sin(t) * r,
            .62,
            e.rampOf(C.white)[3],
          );
        }
      }
      e.sphere(tx + .1, ty, .7, .1, const [240, 200, 90], 'solid');
      for (final d in const [-.55, .55]) {
        b.block(tx + d - .12, ty - .12, .35, tx + d + .12, ty + .12, .4, C.red);
      }
      e.castShadow(tx, ty, .5, .4);
    }
  }

  // mapa.js: PLACES.casa2. 9 · a whole day at home: a two-storey lilac house, lights on, the moon up
  void casa2(double cx, double cy) {
    b.block(cx - 1.4, cy - 1.4, 0, cx + 1.4, cy + 1.4, 3.6, C.lilac);
    b.flatRoof(cx - 1.4, cy - 1.4, cx + 1.4, cy + 1.4, 3.6, C.white);
    b.block(cx - 1.4, cy + 1.4, 1.8, cx + .6, cy + 2.1, 1.92, C.white);
    for (num a = cx - 1.4; a <= cx + .6; a += .22) {
      b.block(a, cy + 2.04, 1.92, a + .05, cy + 2.1, 2.4, C.white);
    }
    b.block(cx - 1.4, cy + 2.04, 2.4, cx + .6, cy + 2.1, 2.46, C.white);
    b.windowOn('y', cy + 1.4, cx - .5, 2.65, .6, .7, C.white, C.glass, true);
    b.windowOn('y', cy + 1.4, cx + .8, 2.65, .5, .7, C.white, C.glass, false);
    b.windowOn('y', cy + 1.4, cx - .8, .9, .6, .7, C.white, C.glass, true);
    b.onWall('y', cy + 1.4, cx + .45, cx + 1.05, 0, 1.4, e.rampOf(C.wood)[2]);
    b.windowOn('x', cx + 1.4, cy - .4, 2.65, .6, .7, C.white, C.glass, true);
    b.windowOn('x', cx + 1.4, cy - .4, .9, .6, .7, C.white, C.glass, false);
    b.shadowBox(cx - 1.4, cy - 1.4, cx + 1.4, cy + 1.4, 3.8, .6);
    e.sphere(cx + 1.7, cy - 2.4, 5.6, .45, const [250, 236, 180], 'gloss');
    e.sphere(cx + 1.85, cy - 2.55, 5.75, .36, const [40, 36, 70], 'solid');
    b.bush(cx + 2, cy + .4, .5);
  }

  // mapa.js: PLACES.fuerte. 10 · the fort: thick stone walls, a round sentry box, a flag over the gate
  void fuerte(double cx, double cy) {
    final x0 = cx - 2.9, y0 = cy - 2.9, x1 = cx + 2.9, y1 = cy + 2.9;
    const h = 2;
    b.block(x0, y0, 0, x1, y1, h, C.fort, [for (final v in C.fort) v * .94]);
    for (num a = x0; a <= x1 - .3; a += .7) {
      b.block(a, y1 - .3, h, a + .35, y1, h + .4, C.fort);
    }
    for (num a = y0; a <= y1 - .3; a += .7) {
      b.block(x1 - .3, a, h, x1, a + .35, h + .4, C.fort);
    }
    for (num a = x0; a <= x1; a += ST) {
      for (num z = .1; z < h; z += .55) {
        e.plot(a, y1 + .02, z, e.rampOf(C.fort)[1]);
      }
    }
    for (num bb = y0; bb <= y1; bb += ST) {
      for (num z = .1; z < h; z += .55) {
        e.plot(x1 + .02, bb, z, e.rampOf(C.fort)[0]);
      }
    }
    b.onWall('y', y1, cx - .45, cx + .45, 0, 1.2, e.rampOf(C.dark)[1]);
    for (num t = 0; t < 3.15; t += .05) {
      b.onWall(
        'y',
        y1,
        cx + math.cos(t) * .45 - .03,
        cx + math.cos(t) * .45 + .03,
        1.2,
        1.2 + math.sin(t) * .4,
        e.rampOf(C.dark)[1],
      );
    }
    // the garita at the front corner
    final gx = x1 - .1, gy = y1 - .1;
    for (num t = 0; t < 6.283; t += .03) {
      final l = -.5 * math.cos(t) + .85 * math.sin(t);
      for (num z = h; z <= h + 1.1; z += ST) {
        e.plot(
          gx + math.cos(t) * .5,
          gy + math.sin(t) * .5,
          z,
          e.rampOf(C.fort)[e.clamp(_round(2.4 + l * 1.3), 1, 4)],
        );
      }
      for (num q = 0; q <= 1; q += .04) {
        final r = .6 * (1 - q);
        e.plot(
          gx + math.cos(t) * r,
          gy + math.sin(t) * r,
          h + 1.1 + math.sin(q * 1.5) * .5,
          e.rampOf(C.fort)[e.clamp(_round(2.8 + l * 1.2), 1, 4)],
        );
      }
    }
    b.onWall(
      'y',
      gy + .5,
      gx - .12,
      gx + .12,
      h + .35,
      h + .8,
      e.rampOf(C.dark)[0],
    );
    e.sphere(gx, gy, h + 1.7, .1, C.fort, 'solid');
    // the keep, set back
    b.block(cx - 1.6, cy - 1.6, h, cx + .4, cy + .4, h + 1.3, C.fort);
    b.windowOn('y', cy + .4, cx - .6, h + .7, .3, .45, C.fort, C.dark);
    e.capsule(
      [cx - .6, cy - .6, h + 1.3],
      [cx - .6, cy - .6, h + 3.6],
      .05,
      .05,
      (_) => C.white,
      'solid',
    );
    b.shadowBox(x0, y0, x1, y1, h + .4, .6);
    b.shadowBox(cx - 1.6, cy - 1.6, cx + .4, cy + .4, h + 1.3, .5);
    for (num a = x0 - .3; a <= x1 + .3; a += .5) {
      b.bush(
        a,
        y1 + .6 + e.hash((a * 9).truncate(), 3) * .3,
        .25 + e.hash((a * 9).truncate(), 4) * .15,
        const [70, 120, 60],
      );
    }
  }
}
