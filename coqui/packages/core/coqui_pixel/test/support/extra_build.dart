// TEST-ONLY. The scene tool/make_extra_ref.mjs draws with the old code, repeated call for call with the Dart engine.
// Keep the two the same.
//
// The names of the old file are kept, capitals included.
// ignore_for_file: non_constant_identifier_names
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

/// What the old driver kept after a stage.
class Stage {
  Stage(this.pix, this.zb, this.kinds);
  final Uint32List pix;
  final Float32List zb;
  final Uint8List? kinds;
}

/// The engine settings of the scene (the old `PP_SCENE`).
PpEngine extraEngine() =>
    PpEngine(w: 160, h: 140, s: 14, originY: 10, shadowX: .9, shadowY: -.1);

/// Draws the scene and returns the stages `objects`, `baked` and `frame`, and the hand `figure` returned.
({Map<String, Stage> stages, List<num> hand}) drawExtraScene(
  PpEngine e,
  PpBuild b,
) {
  final stages = <String, Stage>{};
  void keep(String name, {bool withKinds = false}) {
    stages[name] = Stage(
      Uint32List.fromList(e.pix),
      Float32List.fromList(e.zb),
      withKinds ? Uint8List.fromList(e.kinds) : null,
    );
  }

  final C = b.C;
  // grass ground, the way El frente's sceneGround makes it, with the grass kind
  for (var iy = 0; iy < e.H; iy++) {
    for (var ix = 0; ix < e.W; ix++) {
      final g = e.unproject(ix + .5, iy + .5), i = iy * e.W + ix;
      final t =
          e.noise(g.x * .45, g.y * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
      e.kinds[i] = e.KIND_GRASS;
      final c = e.GRASS[e.clamp((t * 4.2).floor() + 1, 0, 4)];
      e.pix[i] = e.rgb(c[0], c[1], c[2]);
      e.ground[i] = 1;
      e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
    }
  }
  e.growGrass();
  e.groundZ.setAll(0, e.zb);
  e.growTree(-3, -2, .8, 120, 11);
  e.growTree(-1, 5, .5, 80, 300);
  e.box(1, -4, 0, 3.5, -2.5, 1.2, const [200, 160, 110], 3);
  e.box(-3, 1, 0, -2, 4, 2, const [120, 150, 200]);
  b.block(4, 0, 0, 6.5, 2.5, 2, C.yellow);
  b.flatRoof(4, 0, 6.5, 2.5, 2, C.white);
  b.windowOn('y', 2.5, 5.2, 1.0, .6, .7, C.white, C.glass, true); // lit
  b.windowOn('x', 6.5, 1.2, 1.0, .5, .7); // the default frame and glass
  b.windowOn('x', 6.5, .4, 1.0, .3, .3, C.red, const [140, 190, 220], true);
  b.shadowBox(4, 0, 6.5, 2.5, 3, .6);
  b.palm(-5, -4, 3.2, .7, 1);
  const palette1 = <String, List<num>>{
    'shirt': [128, 78, 160],
    'stripe': [150, 98, 178],
    'legs': [128, 78, 160],
    'hair': [232, 230, 224],
    'skin': [176, 122, 88],
  };
  const palette2 = <String, List<num>>{
    'shirt': [236, 236, 228],
    'stripe': [60, 66, 90],
    'legs': [60, 66, 90],
    'hair': [40, 30, 26],
    'skin': [200, 146, 104],
  };
  b.person(0, 3, b.FACE, palette1);
  b.person(-3, 3, b.FACE + .4, palette2, {
    'crouch': .4,
    'lean': .2,
    'armR': .5,
    'armL': -.3,
    'stance': .4,
    'z': .1,
    'scale': .8,
  });
  // scale 0 is false in JavaScript: the scale is 1
  b.person(2, 4.5, 1.1, palette1, {'scale': 0, 'stance': 0, 'armL': 0});
  e.flushShadows();
  e.pendingShadows.clear();
  keep('objects', withKinds: true);
  e.bakeOcclusion();
  e.staticShadow.setAll(0, e.shadowMask);
  e.applyShadows(e.groundZ);
  e.shadeEdges();
  e.bakedPix.setAll(0, e.pix);
  e.bakedZ.setAll(0, e.zb);
  keep('baked');
  // one frame at time 1.25: the wind, a figure drawn per frame, the signs
  e.pix.setAll(0, e.bakedPix);
  e.zb.setAll(0, e.bakedZ);
  e.drawLeaves(1.25);
  e.drawTufts(1.25);
  final hand = e.figure(
    -1,
    1.5,
    2.2,
    {'scale': 1.1, 'armR': .9},
    palette2,
    e.dynamicAdd,
  );
  e.sphere(hand[0], hand[1], hand[2], .1, const [250, 200, 60], 'gloss');
  e.flushShadows();
  e.pendingShadows.clear();
  e.applyShadows(e.groundZ);
  e.drawDots(const [
    [-3, 5],
    [2.7, 3.2],
    [159.9, 139.9],
    [160, 10],
    [10, 140],
    [0.5, 0.5],
  ], e.rgb(255, 0, 0));
  e.haloDots(const [
    [100, 100],
    [0, 0],
    [159, 70],
  ]);
  e.drawArrow(40, 60, .4);
  e.drawArrow(3, 8, .7);
  e.drawArrow(158, 138, 1.1);
  e.drawArrow(80.5, 20.5, 0);
  keep('frame');
  return (stages: stages, hand: hand);
}
