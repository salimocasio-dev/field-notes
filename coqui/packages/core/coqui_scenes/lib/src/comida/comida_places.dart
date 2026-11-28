// Every place La comida uses, read from its sheet (docs/proyecto/pixel/comida-sheet.json, SceneSheet) once:
// the 28 spots (silla1..4, mesa_coqui, platillo1..3, jarra, vasos, auxiliar_coqui, sal, azucar, hielo, servilletas,
// sopa1..3, ensalada, junto_mesa, detras_olla, servir_coqui, tazon, fila1..3, bajo_mesa, plato_perro), the set thing
// box (olla), the view (wide, x0 22), the depth rule, and the shadows. No number of the sheet is typed in Dart: a
// world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/comida/comida_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef ComidaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La comida's places, from its sheet.
class ComidaPlaces {
  ComidaPlaces(this.sheet) : e = comidaEngine();

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// Whether spot [name] has a world point.
  bool hasWorld(String name) => sheet.spots[name]?.world != null;

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  ComidaAt atWorld(num x, num y, num z) {
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
  ComidaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  ComidaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The screen box of spot [name] (e.g. `platillo1`, `jarra`, `sal`, `sopa1`, `tazon`, `plato_perro`).
  List<int> spotBox(String name) {
    final spots = sheet.raw['spots'];
    if (spots is Map && spots[name] is Map) {
      final b = (spots[name] as Map)['box'];
      if (b is List && b.length == 4) {
        return [for (final n in b) (n as num).toInt()];
      }
    }
    throw SheetError('spot $name has no box');
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
