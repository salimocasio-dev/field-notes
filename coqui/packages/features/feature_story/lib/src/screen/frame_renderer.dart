/// The frame of the play screen: page 12, section 5, as `drawFrame` of coqui_pixel makes it.
library;

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/renderer.dart';
import 'package:feature_story/src/screen/scene_frame.dart';

/// Draws the story's frame: the baked set for the world's state, the wind, the shadows, the scene's sprite layer, the
/// game's signs, the view cropped to the display picture, the hud and the hand. The sets are baked when first needed
/// (`Scene.setKey` names the one a state needs) and kept.
class FrameRenderer implements StoryRenderer {
  FrameRenderer({
    required this.setup,
    this.reduceMotion = false,
    this.tick = 70,
  });

  final SceneFrameSetup setup;
  final bool reduceMotion;

  /// Ms a tick (the story's `TICK`).
  final int tick;
  PpEngine? _engine;
  Ctx? _c;
  final Map<String, BakedSet> _baked = {};

  /// The display picture, 196 × 216: what the screen shows.
  final Uint32List display = Uint32List(displayW * displayH);
  late final Ctx dc = Ctx(display, displayW, displayH);

  /// How many sets were baked.
  int bakes = 0;

  PpEngine get _e => _engine ??= setup.engine(still: reduceMotion);

  @override
  void frame({
    required Scene scene,
    required Map<String, dynamic> W,
    required int F,
    required List<num> cam,
    required void Function(Ctx c, int a) signs,
    List<num>? handPoint,
  }) {
    final e = _e;
    final key = scene.setKey(W);
    var baked = _baked[key];
    if (baked == null) {
      scene.buildSet(e, PpBuild(e), W);
      baked = _baked[key] = BakedSet.capture(e);
      bakes++;
    }
    drawFrame(
      engine: e,
      baked: baked,
      scene: scene,
      W: W,
      F: F,
      tick: tick,
      cam: cam,
      shadows: setup.shadows(W),
      c: _c ??= Ctx(e.pix, e.W, e.H),
      display: display,
      dc: dc,
      signs: signs,
      handPoint: handPoint,
    );
  }
}
