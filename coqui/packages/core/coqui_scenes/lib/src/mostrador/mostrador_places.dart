// Every place El mostrador uses, read from its sheet (docs/proyecto/pixel/mostrador-sheet.json, SceneSheet) once:
// the spots, the things' boxes, the views, the depth rule, the shadows, inside and in the street (the sheet's part
// `calle`). No number of the sheet is typed in Dart: a world point is projected by the engine of its picture.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_set.dart';

/// A place on one of the two pictures: its world point, its screen point (the projection, not rounded) and its depth.
typedef MostradorAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// El mostrador's places, from its sheet.
class MostradorPlaces {
  MostradorPlaces(this.sheet)
    : calle = sheet.part('calle'),
      e = mostradorEngine(),
      ec = mostradorCalleEngine();

  /// The sheet (inside) and its part `calle` (the street: its own origin, spots, things, views, shadows).
  final SceneSheet sheet, calle;

  /// The engines of the two pictures, for their projections.
  final PpEngine e, ec;

  /// The sheet (or its part) of picture [donde] (`dentro`, `calle`).
  SceneSheet of(String donde) => donde == 'calle' ? calle : sheet;

  /// The engine of picture [donde].
  PpEngine engineOf(String donde) => donde == 'calle' ? ec : e;

  /// Whether the sheet names spot [name] in picture [donde].
  bool has(String name, [String donde = 'dentro']) =>
      of(donde).spots.containsKey(name);

  /// The world point of spot [name] in picture [donde]; a spot the sheet does not name throws [SheetError] (a place
  /// with no name is not placed by eye).
  List<double> world(String name, [String donde = 'dentro']) {
    final s = of(donde).spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point of picture [donde] with its projection.
  MostradorAt atWorld(num x, num y, num z, [String donde = 'dentro']) {
    final p = engineOf(donde).project(x, y, z);
    return (
      x: x.toDouble(),
      y: y.toDouble(),
      z: z.toDouble(),
      sx: p.sx,
      sy: p.sy,
      d: p.d,
    );
  }

  /// Spot [name] of picture [donde], with its projection; [dx] moves it along x in the world (the sheet's `monedas`
  /// row: `dir` and `step`).
  MostradorAt at(String name, [String donde = 'dentro', double dx = 0]) {
    final w = world(name, donde);
    return atWorld(w[0] + dx, w[1], w[2], donde);
  }

  /// The world point at height [z] under screen point (sx, sy) of picture [donde] (pp-engine.js project, inverted on
  /// the plane z).
  MostradorAt fromScreen(num sx, num sy, num z, [String donde = 'dentro']) {
    final en = engineOf(donde);
    final u = (sx - en.OX) / en.S,
        v = (sy - en.OY + z * en.COS * en.S) / (en.S * en.SIN);
    return atWorld((u + v) / en.R2, (v - u) / en.R2, z, donde);
  }

  /// The view [name] as `cam`: `[x, y, w, h]` (`dentro` the sheet's, `calle` its part's).
  List<num> view(String name) =>
      (name == 'calle' ? calle : sheet).view(name).cam;

  /// The screen box of set thing [id] in picture [donde] (the sheet's `box`).
  List<int> box(String id, [String donde = 'dentro']) =>
      of(donde).thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of set thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id, [String donde = 'dentro']) =>
      of(donde).thing(id).world ??
      (throw SheetError('thing $id has no world box'));

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] in picture [donde] (`shadows.byCharacter`), or null: none.
  double? radius(String character, [String donde = 'dentro']) =>
      of(donde).shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot, [String donde = 'dentro']) =>
      of(donde).shadows.none.contains(spot);

  /// The spots of group [name] (inside).
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
