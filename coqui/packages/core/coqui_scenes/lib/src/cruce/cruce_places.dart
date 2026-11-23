// Every place El cruce uses, read from its sheet (docs/proyecto/pixel/cruce-sheet.json, SceneSheet) once: the spots,
// the things' boxes, the two views, the groups, the depth rule, the shadows. No number of the sheet is typed in Dart: a
// world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cruce/cruce_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef CruceAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// El cruce's places, from its sheet.
class CrucePlaces {
  CrucePlaces(this.sheet) : e = cruceEngine();

  final SceneSheet sheet;

  /// The set's engine, for its projection.
  final PpEngine e;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name] (an alias, `alternatives.aliases`, is its own spot in the sheet); a spot the sheet
  /// does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ?? (throw SheetError('spot $name has no world point'));
  }

  /// A world point with its projection.
  CruceAt atWorld(num x, num y, num z) {
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

  /// Spot [name] with its projection.
  CruceAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  CruceAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of set thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

  /// front.bias.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether spot [spot] casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
