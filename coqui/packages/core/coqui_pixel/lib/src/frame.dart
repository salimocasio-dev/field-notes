// The scene-facing names are kept as in the old code (page 12, section 4): the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/pp_engine.dart';
import 'package:coqui_pixel/src/scene.dart';
import 'package:coqui_pixel/src/signs.dart';

/// One shadow a character casts: one call of the engine's `castShadow(x, y, z, r)`, in world coordinates (the ground
/// point under the feet, the height, the radius). A character that casts one shadow has one entry; one that casts it
/// from several heights (El frente's abuela: `z` from .3 to 2 in steps of .35 over her spot) has one entry for each.
typedef ShadowCast = ({double x, double y, double z, double r});

/// The colour the display picture starts as: `"#0E1A24"` (juego.js: `dc.fillStyle="#0E1A24";dc.fillRect(0,0,DW,DH)`).
const int _displayBackground = 0xFF241A0E;

// juego.js: draw (the frame), as page 12, section 5 gives it: "The frame, every tick"
/// One frame: the same five steps, in this order, every tick. The function holds no state of its own; everything it
/// changes is in what it is given.
///
/// 1. Copy the baked set for the state ([bakedPix], [bakedZ]: what `scene.setKey(W)` names) into the picture
///    ([engine]'s `pix` and `zb`, 240 × 216).
/// 2. `drawLeaves` and `drawTufts`: the wind, in steps of 1 / `WIND_FPS` second, still when the engine is (`STILL`,
///    the OS asking for reduced motion). Time is [F] ticks of [tick] ms.
/// 3. Cast the shadow of each character in [shadows], and `applyShadows` (the leaves' shadows go with them).
/// 4. The sprite layer, [scene]'s `draw(c, W, a)` with `a = F >> 1`, then [signs] (the game's signs: the answer
///    bubbles, the twinkle, the "touch this" frame, the effects, the heart; [Signs.drawSigns]).
/// 5. Copy the window at [cam] (`[x, y, w, h]`) of the picture into [display]; then the scene's `hud` and the hand sign
///    ([handPoint]: where the hand points in the picture, [Signs.handPoint]; null: no hand) are drawn on [display]
///    through [dc]. The window keeps its size: nothing is stretched.
///
/// [c] draws on [engine]'s `pix`, [dc] on [display]. [engine] is the one the baked set was made with, so its ground,
/// `kinds`, `groundZ` and `staticShadow` are the ones of the set (only `pix` and `zb` are copied here).
void drawFrame({
  required PpEngine engine,
  required Uint32List bakedPix,
  required Float32List bakedZ,
  required Scene scene,
  required Map<String, dynamic> W,
  required int F,
  required int tick,
  required List<num> cam,
  required List<ShadowCast> shadows,
  required Ctx c,
  required Uint32List display,
  required Ctx dc,
  required void Function(Ctx c, int a) signs,
  List<num>? handPoint,
}) {
  final a = F >> 1;
  // 1. the baked set
  engine.pix.setAll(0, bakedPix);
  engine.zb.setAll(0, bakedZ);
  // 2. the wind (mapa.js: `windT = STILL ? 0 : Math.floor(time * WIND_FPS) / WIND_FPS`, time in seconds)
  final windT = engine.STILL
      ? 0.0
      : (F * tick * engine.WIND_FPS) ~/ 1000 / engine.WIND_FPS;
  engine.drawLeaves(windT);
  engine.drawTufts(windT);
  // 3. the characters' shadows
  for (final s in shadows) {
    engine.castShadow(s.x, s.y, s.z, s.r);
  }
  engine.applyShadows(engine.groundZ);
  // 4. the sprite layer, then the game's signs
  scene.draw(c, W, a);
  signs(c, a);
  // 5. the window at cam, then hud and the hand
  _copyWindow(engine, display, cam);
  scene.hud(dc, W, a);
  if (handPoint != null) {
    // juego.js: z = DW / cam[2] is 1 now (the window keeps its size), so the picture's point is the display's plus cam
    const k = 3;
    final hx = (handPoint[0] - cam[0] + 0.5).floor() - 4 * k,
        hy = (handPoint[1] - cam[1] + 0.5).floor();
    hand(dc, hx, hy, (F >> 2) % 2 == 1, k);
  }
}

/// The display picture: the window `cam` of the engine's picture, 1 to 1. What the window lies outside the picture
/// (never, for a window the camera made) is the old background colour.
void _copyWindow(PpEngine e, Uint32List display, List<num> cam) {
  final x0 = (cam[0] + 0.5).floor(), y0 = (cam[1] + 0.5).floor();
  final w = (cam[2] + 0.5).floor(), h = (cam[3] + 0.5).floor();
  display.fillRange(0, display.length, _displayBackground);
  for (var j = 0; j < h; j++) {
    final sy = y0 + j;
    if (sy < 0 || sy >= e.H) continue;
    final from = x0 < 0 ? -x0 : 0, to = x0 + w > e.W ? e.W - x0 : w;
    if (to <= from) continue;
    display.setRange(j * w + from, j * w + to, e.pix, sy * e.W + x0 + from);
  }
}

/// The corners of one face of a world box, on screen, in order round the face: from the bottom corner nearest the
/// box's low end, along the bottom, up, and back along the top. [world] is `x0, y0, z0, x1, y1, z1`. A face is named
/// as the building helpers name it (mapa.js: `onWall(face, at, ...)`): `'y'` is the wall on `y = y1`, `'x'` the wall
/// on `x = x1`, the two walls the camera sees. Each corner is the engine's `project` of the corner's world point.
List<({double sx, double sy})> faceCorners(
  PpEngine e,
  List<num> world,
  String face,
) {
  final x0 = world[0], y0 = world[1], z0 = world[2];
  final x1 = world[3], y1 = world[4], z1 = world[5];
  final List<List<num>> pts;
  switch (face) {
    case 'y':
      pts = [
        [x0, y1, z0],
        [x1, y1, z0],
        [x1, y1, z1],
        [x0, y1, z1],
      ];
    case 'x':
      pts = [
        [x1, y0, z0],
        [x1, y1, z0],
        [x1, y1, z1],
        [x1, y0, z1],
      ];
    default:
      throw ArgumentError.value(face, 'face', "a face is 'x' or 'y'");
  }
  return [
    for (final p in pts)
      (() {
        final s = e.project(p[0], p[1], p[2]);
        return (sx: s.sx, sy: s.sy);
      })(),
  ];
}

/// Clips [c] to [face] of [thing]'s world box, as the old code clipped to a window or a doorway: `c.beginPath()`, the
/// face's four corners on screen ([faceCorners]), `c.clip()`. Call it between `save` and `restore`. [thing] must be
/// part of the set (it has a [Thing.world]).
void clipTo(Ctx c, PpEngine engine, Thing thing, String face) {
  final world = thing.world;
  if (world == null) {
    throw ArgumentError('${thing.id} has no world box: it is not in the set');
  }
  final p = faceCorners(engine, world, face);
  c.beginPath();
  c.moveTo(p[0].sx, p[0].sy);
  for (var i = 1; i < p.length; i++) {
    c.lineTo(p[i].sx, p[i].sy);
  }
  c.clip();
}
