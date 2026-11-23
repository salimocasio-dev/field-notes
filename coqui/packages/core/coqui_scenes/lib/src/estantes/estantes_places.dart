// Every place Los estantes uses, read from its sheet (docs/proyecto/pixel/estantes-sheet.json, SceneSheet) once: the
// spots, their groups, the things' boxes, the view, the depth rule, the shadows. No number of the sheet is typed in
// Dart: a world point is projected by the set's engine (El mostrador's places, with one picture).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/estantes/estantes_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef EstantesAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Los estantes' places, from its sheet.
class EstantesPlaces {
  EstantesPlaces(this.sheet) : e = estantesEngine();

  /// The sheet.
  final SceneSheet sheet;

  /// The set's engine, for its projection.
  final PpEngine e;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError] (a place with no name is not
  /// placed by eye).
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  EstantesAt atWorld(num x, num y, num z) {
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
  EstantesAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The ground point under spot [name] (`spots.<name>.ground`: the frog's crate stands there), or the spot itself.
  EstantesAt groundOf(String name) {
    final g = sheet.spot(name).raw['ground'];
    if (g is Map && g['world'] is List) {
      final w = (g['world'] as List).cast<num>();
      return atWorld(w[0], w[1], w[2]);
    }
    return at(name);
  }

  /// The footprint of a box spot (`spots.<name>.footprint`: along x, along y).
  List<double> footprint(String name) {
    final f = sheet.spot(name).raw['footprint'];
    if (f is! List) throw SheetError('spot $name has no footprint');
    return [for (final v in f) (v as num).toDouble()];
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  EstantesAt fromScreen(num sx, num sy, num z) {
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

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// front.after: the spots whose character is drawn after a part of the set (`pepe.escalera`: the ladder), and that part.
  Map<String, String> get after {
    final a = sheet.front.raw['after'];
    if (a is! Map) return const {};
    return {
      for (final e in a.entries)
        if ('${e.value}'.contains('part escalera')) '${e.key}': 'escalera',
    };
  }

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name] (`estante.medio`, `estante.alto`, `mesa.fila`).
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
