// Every place El banco de la plaza uses, read from its sheet (docs/proyecto/pixel/plaza-sheet.json, SceneSheet) once: the
// spots, the things' boxes, the view, the depth rule, the shadows, the board's hooks (`ganchos`, kept by SceneSheet as
// plain data) and where the two answer bubbles stand over the frog (things.burbuja_a and burbuja_b: their boxes for the
// frog at asiento4, rules.bubbles: the same offsets from wherever he is). No number of the sheet is typed in Dart: a
// world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef PlazaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

int _round(num v) => (v + 0.5).floor();

/// El banco de la plaza's places, from its sheet.
class PlazaPlaces {
  PlazaPlaces(this.sheet) : e = plazaEngine() {
    // rules.bubbles: the two boxes are those of the frog at asiento4; each keeps its offset from his spot's screen point
    final a = box('burbuja_a'), b = box('burbuja_b'), at = this.at('asiento4');
    final sx = _round(at.sx), sy = _round(at.sy);
    bubbleA = [a[0] - sx, a[1] - sy, a[2], a[3]];
    bubbleB = [b[0] - sx, b[1] - sy, b[2], b[3]];
  }

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  /// The answer bubbles' boxes relative to the frog's spot (its screen point, rounded): x, y, w, h.
  late final List<int> bubbleA, bubbleB;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  PlazaAt atWorld(num x, num y, num z) {
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
  PlazaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  PlazaAt fromScreen(num sx, num sy, num z) {
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

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));

  /// The five hooks of row [fila] (`isla`, `ciudad`) of the notice board (the sheet's `ganchos`): each one's world point.
  List<List<double>> ganchos(String fila) {
    final g = sheet.raw['ganchos'];
    final row = g is Map ? g[fila] : null;
    if (row is! List) throw SheetError('no row of hooks $fila');
    return [
      for (final h in row)
        [for (final v in (h as Map)['world'] as List) (v as num).toDouble()],
    ];
  }
}
