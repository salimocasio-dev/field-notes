// Every place La sala, de día uses, read from its sheet (docs/proyecto/pixel/sala_dia-sheet.json, SceneSheet) once:
// the spots (cojin1, cojin2, escritorio, butaca, estante, cocina, ventana_abuela, junto_mesa_coqui, brazo_coqui,
// libro, papel, telefono, pagina1..pagina3, estrellas, foto, oreja_abuelo, boca_abuelo), the set things' boxes
// (computadora, ventana, oreja_abuelo, boca_abuelo), the view (wide, x0 22), the depth rule, and the shadows.
// No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef SalaDiaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La sala, de día's places, from its sheet.
class SalaDiaPlaces {
  SalaDiaPlaces(this.sheet) : e = salaDiaEngine();

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
  SalaDiaAt atWorld(num x, num y, num z) {
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

  /// A (u, v, z) point in the set's frame projected via `PZ.xy`.
  SalaDiaAt atUv(num u, num v, num z) =>
      atWorld((u + v) / e.R2, (v - u) / e.R2, z);

  /// Spot [name], with its projection.
  SalaDiaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The screen point `[sx, sy]` of spot [name].
  List<int> screen(String name) {
    final sc = sheet.spot(name).screen;
    if (sc != null && sc.length >= 2) {
      return [sc[0].round(), sc[1].round()];
    }
    throw SheetError('spot $name has no screen point');
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  SalaDiaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set or overlay thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The screen box of spot [name] (e.g. `libro`, `papel`, `telefono`, `pagina1..3`, `estrellas`, `foto`).
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
