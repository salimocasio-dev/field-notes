import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/still_host.dart';

/// One converted scene, drawn frame by frame on a still host (page 12, section 5, "The frame, every tick"): its baked
/// states, the engine they are drawn on, the 240 × 216 picture and the 196 × 216 display.
class StillFrame {
  StillFrame(this.scene, {bool still = false})
    : host = StillHost(scene),
      bakes = SetBakes(scene, still: still) {
    c = Ctx(bakes.engine.pix, bakes.engine.W, bakes.engine.H);
    dc = Ctx(display, displayW, displayH);
  }

  final SetScene scene;
  final StillHost host;
  final SetBakes bakes;

  PpEngine get engine => bakes.engine;

  /// The scene's picture, 240 × 216 (the engine's `pix`), as the last frame left it.
  Uint32List get picture => bakes.engine.pix;

  /// The display picture, 196 × 216: the view, then hud and the hand.
  final Uint32List display = Uint32List(displayW * displayH);

  late final Ctx c, dc;

  /// Draws one frame of [W] at frame [F] through the view [cam] (`drawFrame`). [tick] is the ms of a tick: the wind's
  /// time is F × tick (0: no wind, as the set reference's own frame at t = 0). [allSigns]: the game's signs (answer
  /// bubbles, twinkle, the "touch this" frame, effects, heart) and the hand; without it, only the answer bubbles, as a
  /// review picture has (cual.js draws `E.draw` and `respDraw`).
  void draw(
    Map<String, dynamic> W, {
    required int F,
    required List<num> cam,
    int tick = 70,
    bool allSigns = true,
  }) {
    host
      ..W = W
      ..F = F
      ..cam = cam;
    W['fx'] ??= <Map<String, dynamic>>[];
    final baked = bakes.bake(W);
    drawFrame(
      engine: bakes.engine,
      baked: baked,
      scene: scene,
      W: W,
      F: F,
      tick: tick,
      cam: cam,
      shadows: scene.shadows(W),
      c: c,
      display: display,
      dc: dc,
      signs: allSigns
          ? host.signs.drawSigns
          : (c, a) {
              if (W['resp'] != null) host.signs.respDraw(c, a);
            },
      handPoint: allSigns ? host.signs.handPoint() : null,
    );
  }
}
