/// Who draws a frame. The runner calls it once a tick (juego.js: `draw`); the play screen draws the whole frame of
/// page 12, section 5; a player with no screen draws only the layers a scene's code runs in.
library;

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

/// One frame of the story (juego.js: `draw`).
abstract interface class StoryRenderer {
  /// Draws the scene's sprite layer (`scene.draw`), then [signs] (the game's signs, and then the camera moves, as
  /// juego.js does: they are drawn with the view as it was, the picture is cropped with the view as it is now), then
  /// the scene's hud and the hand over the picture ([handPoint], a list the caller may change inside [signs]).
  void frame({
    required Scene scene,
    required Map<String, dynamic> W,
    required int F,
    required List<num> cam,
    required void Function(Ctx c, int a) signs,
    List<num>? handPoint,
  });
}

/// The frame of a player with no screen: no set, no baking, no crop. The scene's `draw` and the signs run on a scratch
/// picture, as they do in the old page, so that whatever they do besides drawing (a scene that draws a random number or
/// moves something in `draw`) happens as it did. Then the hud on a scratch display picture.
class HeadlessRenderer implements StoryRenderer {
  HeadlessRenderer({int w = pictureW, int h = pictureH})
    : pix = Uint32List(w * h),
      display = Uint32List(displayW * displayH) {
    c = Ctx(pix, w, h);
    dc = Ctx(display, displayW, displayH);
  }

  final Uint32List pix;
  final Uint32List display;
  late final Ctx c;
  late final Ctx dc;

  @override
  void frame({
    required Scene scene,
    required Map<String, dynamic> W,
    required int F,
    required List<num> cam,
    required void Function(Ctx c, int a) signs,
    List<num>? handPoint,
  }) {
    final a = F >> 1;
    scene.draw(c, W, a);
    signs(c, a);
    scene.hud(dc, W, a);
  }
}
