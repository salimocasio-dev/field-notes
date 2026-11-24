// Every place El quiosco uses, read from its sheet (docs/proyecto/pixel/quiosco-sheet.json, SceneSheet) once:
// the spots, the set things' boxes, the cup sign's disc, the view, the depth rule, and the shadows.
// No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/quiosco/quiosco_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef QuioscoAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// El quiosco's places, from its sheet.
class QuioscoPlaces {
  QuioscoPlaces(this.sheet) : e = quioscoEngine();

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  QuioscoAt atWorld(num x, num y, num z) {
    final p = e.project(x, y, z);
    return (
      x: x.toDouble(),
      y: y.toDouble(),
      z: z.toDouble(),
      sx: p.sx,
      sy: p.sy,
      d: p.d,
    );
  }

  /// Spot [name], with its projection.
  QuioscoAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// Spot [name] shifted in (u, v, z) by ([du], [dv], [dz]) (e.g., the three limber cups running back along the wing).
  QuioscoAt atUvOffset(String name, num du, num dv, [num dz = 0]) {
    final w = world(name);
    final uv = uvOf(w[0], w[1]);
    final xy = xyOf(uv[0] + du, uv[1] + dv);
    return atWorld(xy[0], xy[1], w[2] + dz);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  QuioscoAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The u, v of a world point (plaza-base.js PZ.uv).
  List<double> uvOf(num x, num y) => [(x - y) / e.R2, (x + y) / e.R2];

  /// The world x, y of u, v (plaza-base.js PZ.xy).
  List<double> xyOf(num u, num v) => [(u + v) / e.R2, (v - u) / e.R2];

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of set thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

  /// The cup sign's disc (cx, cy, r), from `things.letrero.disc`.
  ({double cx, double cy, double r}) get signDisc {
    final raw = sheet.raw['things'] as Map;
    final d = (raw['letrero'] as Map)['disc'] as Map;
    return (
      cx: (d['cx'] as num).toDouble(),
      cy: (d['cy'] as num).toDouble(),
      r: (d['r'] as num).toDouble(),
    );
  }

  /// Facing direction of spot [name] (`spots.<name>.face`: `'left'` -> -1, else 1).
  int faceOf(String name) {
    final raw = (sheet.raw['spots'] as Map?)?[name] as Map?;
    return raw?['face'] == 'left' ? -1 : 1;
  }

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
