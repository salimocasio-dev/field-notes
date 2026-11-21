// The scene-facing names are kept as in the old code (page 12, section 4): the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/src/baked_set.dart';
import 'package:coqui_pixel/src/camera.dart';
import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/pp_engine.dart';
import 'package:coqui_pixel/src/scene.dart';
import 'package:coqui_pixel/src/signs.dart';

/// One shadow a character casts: one call of the engine's `castShadow(x, y, z, r)`, in world coordinates (the ground
/// point under the feet, the height, the radius). A character that casts one shadow has one entry; one that casts it
/// from several heights (El frente's abuela: `z` from .3 to 2 in steps of .35 over her spot) has one entry for each.
typedef ShadowCast = ({double x, double y, double z, double r});

/// A scene whose sprite layer draws parts of the set again over what it has drawn so far (a sheet's `front.parts`:
/// El balcón's furniture, which the old picture drew as sprites after the characters behind it). [drawFrame] calls
/// [setFramed] after step 3, before the sprite layer: [engine]'s `pix` is then the set as this frame shows it (the baked
/// set, the wind, the shadows), and [baked] is the state it was restored from (its `zb` is the set's own depth). The
/// scene keeps what it needs of them and draws them again at its old lines, in its `draw`.
abstract interface class SetOverSprites {
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W);
}

/// The colour the display picture starts as: `"#0E1A24"` (juego.js: `dc.fillStyle="#0E1A24";dc.fillRect(0,0,DW,DH)`).
const int _displayBackground = 0xFF241A0E;

// juego.js: draw (the frame), as page 12, section 5 gives it: "The frame, every tick"
/// One frame: the same five steps, in this order, every tick. The function holds no state of its own; everything it
/// changes is in what it is given.
///
/// 1. Restore the baked set for the state ([baked]: what `scene.setKey(W)` names) into [engine]: everything a bake leaves
///    behind (the ground, its depth, the kinds, the static shadow, the tufts and leaves; [BakedSet]), and its picture
///    and depth into `pix` and `zb` (240 × 216).
/// 2. `drawLeaves` and `drawTufts`: the wind, in steps of 1 / `WIND_FPS` second, still when the engine is (`STILL`,
///    the OS asking for reduced motion). Time is [F] ticks of [tick] ms. Then `drawGlints` at the same time, for a set
///    whose bake left glints on its water (the engine's `glints`: El campo's); none for the others.
/// 3. Cast the shadow of each character in [shadows], and `applyShadows` (the leaves' shadows go with them).
/// 4. The sprite layer, [scene]'s `draw(c, W, a)` with `a = F >> 1` (a [SetOverSprites] scene is first given the set
///    as framed), then [signs] (the game's signs: the answer
///    bubbles, the twinkle, the "touch this" frame, the effects, the heart; [Signs.drawSigns]).
/// 5. Crop the picture by [cam] (`[x, y, w, h]`: a 196 × 216 window at zoom 1, a 98 × 108 region drawn as 2 × 2 blocks
///    at zoom 2) into [display], 196 × 216; then the scene's `hud` and the hand sign ([handPoint]: where the hand
///    points in the picture, [Signs.handPoint]; null: no hand) are drawn on [display] through [dc]. Any other size of
///    [cam] throws: a fractional scale is never drawn.
///
/// [c] draws on [engine]'s `pix`, [dc] on [display]. One engine can serve every state of a set: each frame starts by
/// putting its state back.
void drawFrame({
  required PpEngine engine,
  required BakedSet baked,
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
  baked.restoreInto(engine);
  // 2. the wind (mapa.js: `windT = STILL ? 0 : Math.floor(time * WIND_FPS) / WIND_FPS`, time in seconds)
  final windT = engine.STILL
      ? 0.0
      : (F * tick * engine.WIND_FPS) ~/ 1000 / engine.WIND_FPS;
  engine.drawLeaves(windT);
  engine.drawTufts(windT);
  // the glints on the water (set-kit.js drawGlints, beside the tufts: campo-set.html `frame`); a set with no water has
  // none, and its frame is drawn as before
  if (engine.glints.isNotEmpty) {
    drawGlints(engine, engine.glints, windT, engine.bakedZ, engine.glintColour);
  }
  // 3. the characters' shadows
  for (final s in shadows) {
    engine.castShadow(s.x, s.y, s.z, s.r);
  }
  engine.applyShadows(engine.groundZ);
  // 4. the sprite layer, then the game's signs
  final over = scene is SetOverSprites ? scene as SetOverSprites : null;
  over?.setFramed(engine, baked, W);
  scene.draw(c, W, a);
  signs(c, a);
  // 5. the window at cam, then hud and the hand
  _copyView(engine, display, cam);
  scene.hud(dc, W, a);
  // juego.js line 77: `E.handAt[W.spot]` with no such key is a TypeError there; here no hand is drawn (the caller gives
  // no handPoint, or `Signs.handPoint` gives null)
  if (handPoint != null) {
    // juego.js: `z = DW / cam[2]` is 1 or 2, `hx = Math.round((p[0] - cam[0]) * z) - 4 * k`
    const k = 3;
    final z = zoomOf(cam);
    final hx = ((handPoint[0] - cam[0]) * z + 0.5).floor() - 4 * k,
        hy = ((handPoint[1] - cam[1]) * z + 0.5).floor();
    hand(dc, hx, hy, (F >> 2) % 2 == 1, k);
  }
}

/// The display picture: the part of the engine's picture the view [cam] shows, each pixel 1 × 1 at zoom 1 and 2 × 2 at
/// zoom 2. What the view lies outside the picture (never, for a view the camera made) is the old background colour.
void _copyView(PpEngine e, Uint32List display, List<num> cam) {
  final zoom = zoomOf(cam);
  if (display.length != displayW * displayH) {
    throw ArgumentError('the display picture is $displayW x $displayH');
  }
  final x0 = (cam[0] + 0.5).floor(), y0 = (cam[1] + 0.5).floor();
  display.fillRange(0, display.length, _displayBackground);
  for (var j = 0; j < displayH; j++) {
    final sy = y0 + j ~/ zoom;
    if (sy < 0 || sy >= e.H) continue;
    for (var i = 0; i < displayW; i++) {
      final sx = x0 + i ~/ zoom;
      if (sx < 0 || sx >= e.W) continue;
      display[j * displayW + i] = e.pix[sy * e.W + sx];
    }
  }
}

/// The world points of one face of a world box, in order round the face: from the bottom corner nearest the box's low
/// end, along the bottom, up, and back along the top. [world] is `x0, y0, z0, x1, y1, z1`. A face is named as the building
/// helpers name it (mapa.js: `onWall(face, at, ...)`): `'y'` is the wall on `y = y1`, `'x'` the wall on `x = x1`, the
/// two walls the camera sees.
List<List<double>> facePoints(List<num> world, String face) {
  final x0 = world[0].toDouble(), y0 = world[1].toDouble();
  final z0 = world[2].toDouble(), x1 = world[3].toDouble();
  final y1 = world[4].toDouble(), z1 = world[5].toDouble();
  switch (face) {
    case 'y':
      return [
        [x0, y1, z0],
        [x1, y1, z0],
        [x1, y1, z1],
        [x0, y1, z1],
      ];
    case 'x':
      return [
        [x1, y0, z0],
        [x1, y1, z0],
        [x1, y1, z1],
        [x1, y0, z1],
      ];
    default:
      throw ArgumentError.value(face, 'face', "a face is 'x' or 'y'");
  }
}

/// A list of world points `[x, y, z]` on the screen: the engine's `project` of each.
List<({double sx, double sy})> projectPoints(
  PpEngine e,
  List<List<num>> points,
) => [
  for (final p in points)
    (() {
      final s = e.project(p[0], p[1], p[2]);
      return (sx: s.sx, sy: s.sy);
    })(),
];

/// The corners of one face of a world box, on screen, in the order of [facePoints]: the engine's `project` of each.
List<({double sx, double sy})> faceCorners(
  PpEngine e,
  List<num> world,
  String face,
) => projectPoints(e, facePoints(world, face));

/// Clips [c] to the polygon the world [points] make on the screen, as the old code clipped to a rectangle (a window, a
/// doorway): `c.beginPath()`, each point projected by the engine, `c.clip()`. A sheet's `clips` are world polygons (four
/// points on a wall); this is what a scene calls for them. Call it between `save` and `restore`.
void clipToWorld(Ctx c, PpEngine engine, List<List<num>> points) {
  final p = projectPoints(engine, points);
  c.beginPath();
  c.moveTo(p[0].sx, p[0].sy);
  for (var i = 1; i < p.length; i++) {
    c.lineTo(p[i].sx, p[i].sy);
  }
  c.clip();
}

/// Clips [c] to [face] of [thing]'s world box: [clipToWorld] of [facePoints]. [thing] must be part of the set (it has a
/// [Thing.world]).
void clipTo(Ctx c, PpEngine engine, Thing thing, String face) {
  final world = thing.world;
  if (world == null) {
    throw ArgumentError('${thing.id} has no world box: it is not in the set');
  }
  clipToWorld(c, engine, facePoints(world, face));
}
