// Every place La sombrilla uses, read from its sheet (docs/proyecto/pixel/sombrilla-sheet.json, SceneSheet) once:
// the spots (manta, manta2, manta3, luis.cara, carmen.cara, coqui.cara, cubo75, ojo_izq, ojo_der, nariz, boca,
// luis.figura, carmen.figura, coqui.figura, caracoles, perro, hoyo, sol1, sol2, sol3, coqui.bolsa, sombreros, gafas,
// chancletas), the set things' boxes (cara, ojo_izq, ojo_der, nariz, boca, cabeza, brazo_izq, brazo_der, mano_izq,
// mano_der, pies and its sub-boxes), the blanket box, the view (wide, x0 22), the depth rule, and the shadows.
// No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef SombrillaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La sombrilla's places, from its sheet.
class SombrillaPlaces {
  SombrillaPlaces(this.sheet) : e = sombrillaEngine();

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
  SombrillaAt atWorld(num x, num y, num z) {
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
  SombrillaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  SombrillaAt fromScreen(num sx, num sy, num z) {
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

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// Sub-boxes of a multi-box set thing (e.g. `pies`'s two foot boxes), if present in raw sheet JSON.
  List<List<int>> boxesOf(String id) {
    final raw = sheet.raw['things'];
    if (raw is Map && raw[id] is Map) {
      final bs = (raw[id] as Map)['boxes'];
      if (bs is List) {
        return [
          for (final b in bs) [for (final n in b as List) (n as num).toInt()],
        ];
      }
    }
    return [box(id)];
  }

  /// The blanket's screen box (`sombrilla-sheet.json` `blanket.box`).
  List<int> get blanketBox {
    final raw = sheet.raw['blanket'];
    if (raw is Map && raw['box'] is List) {
      return [for (final n in raw['box'] as List) (n as num).toInt()];
    }
    throw SheetError('sombrilla-sheet.json missing blanket.box');
  }

  /// The world box of set thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

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
