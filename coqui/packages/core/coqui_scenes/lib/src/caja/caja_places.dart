// Every place La caja uses, read from its sheet (docs/proyecto/pixel/caja-sheet.json, SceneSheet) once: the spots, the
// things' boxes, the two key cards, the amount plate, the price tag's offset (`etiqueta`), the view, the depth rule, the
// shadows. No number of the sheet is typed in Dart: a world point is projected by the engine of the picture (as
// El mostrador's places, mostrador_places.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/caja/caja_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef CajaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La caja's places, from its sheet.
class CajaPlaces {
  CajaPlaces(this.sheet) : e = cajaEngine();

  /// The sheet.
  final SceneSheet sheet;

  /// The engine of the picture, for its projections.
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
  CajaAt atWorld(num x, num y, num z) {
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
  CajaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  CajaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `things.<id>.box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of set thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

  /// The box of a key card (`spots.tecla_a`, `spots.tecla_b`: kind card, a screen box and no world point).
  List<int> card(String name) {
    final b = sheet.spot(name).raw['box'];
    if (b is! List || b.length != 4) {
      throw SheetError('spot $name has no card box');
    }
    return [for (final v in b) (v as num).round()];
  }

  /// The amount plate (`things.importe`): its box on the picture, its spot (`at`, the register's window) and the depth
  /// it is drawn at (that spot's).
  ({List<int> box, String at, double d}) get importe {
    final t = sheet.thing('importe');
    final at = t.raw['at'] as String;
    final b = t.box ?? (throw SheetError('thing importe has no box'));
    return (box: b, at: at, d: this.at(at).d);
  }

  /// The price tag's world offset from its thing (`spots.<spot>.etiqueta.dw`), or null: that spot has no tag.
  List<double>? etiqueta(String spot) {
    final t = sheet.spot(spot).raw['etiqueta'];
    if (t is! Map) return null;
    final dw = t['dw'];
    if (dw is! List) return null;
    return [for (final v in dw) (v as num).toDouble()];
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
