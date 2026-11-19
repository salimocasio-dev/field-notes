// The scene's own names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

// A scene of our own for the dev entry and the widget tests: a flat picture (sky, grass, a house) with the things a story
// touches drawn as boxes, so that the play screen can be seen on the fakes. Not El frente: that one is built by the scenes
// package (order 14).
import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/feature_story.dart';

import 'stand_in_scene.dart';

const int _sky = 0xFFE6A83C,
    _grass = 0xFF48A83C,
    _wall = 0xFFA89A30,
    _roof = 0xFF3C44E8,
    _doorC = 0xFF30609C,
    _winC = 0xFFE8D8A0;

/// The things of the dev scene, with the boxes the old El frente has for them.
List<Thing> devThings() => [
  Thing(id: 'puerta', box: [150, 96, 30, 54]),
  Thing(id: 'ventana', box: [70, 96, 40, 34]),
  Thing(id: 'casa', box: [40, 60, 160, 92]),
  Thing(id: 'palma', box: [8, 80, 24, 70]),
  Thing(id: 'sol', box: [200, 14, 22, 22], si: (W) => W['storm'] != true),
];

class DevScene extends StandInScene {
  DevScene({required super.sceneId, required super.cam})
    : super(
        things: devThings(),
        talk: {
          'abuela': [100, 80],
        },
      );

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {
    final w = e.W, h = e.H;
    void rect(int x0, int y0, int x1, int y1, int c) {
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          e.pix[y * w + x] = c;
        }
      }
    }

    rect(0, 0, w, 150, _sky);
    rect(0, 150, w, h, _grass);
    rect(40, 80, 200, 152, _wall);
    rect(30, 60, 210, 82, _roof);
    rect(150, 96, 180, 150, _doorC);
    rect(70, 96, 110, 130, _winC);
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    super.draw(c, W, a);
    if (W['storm'] == true) {
      c.fillStyle = 0x66402010;
      c.fillRect(0, 0, 240, 150);
    }
  }
}

/// The dev scene of the scene [sceneId], with a view for every name the `cam` steps of [stories] use, each its own.
StoryScene devStoryScene(
  String sceneId,
  Iterable<Map<String, dynamic>> stories,
) => StoryScene(
  scene: DevScene(sceneId: sceneId, cam: camsOfStory(stories)),
  frame: SceneFrameSetup(
    engine: ({required still}) => PpEngine(w: 240, h: 216, s: 26, still: still),
    shadows: (W) => const [],
  ),
);

/// A view for every name the `cam` steps of [stories] use, each its own (see `camsOf` in juega.dart).
Map<String, List<num>> camsOfStory(Iterable<Map<String, dynamic>> stories) {
  final names = <String>{'wide'};
  void walk(Object? x) {
    if (x is Map) {
      final c = x['cam'];
      if (c is String) names.add(c);
      x.values.forEach(walk);
    } else if (x is List) {
      x.forEach(walk);
    }
  }

  stories.forEach(walk);
  var i = 0;
  return {
    for (final n in names) n: [i++, 0, 196, 216],
  };
}

/// The scene factory of the dev entry: the dev scene of a scene id, for the stories among [stories] that use it.
SceneFactory devScenes(Iterable<Map<String, dynamic>> stories) =>
    (String id, Rng rng) =>
        devStoryScene(id, stories.where((x) => x['scene'] == id));
