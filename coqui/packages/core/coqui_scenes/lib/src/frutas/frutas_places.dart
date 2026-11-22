// Every place Las frutas uses, read from its sheet (docs/proyecto/pixel/frutas-sheet.json, SceneSheet) once: the spots,
// the things' boxes and world boxes, the view, the depth rule, the shadows, the assortments. No number of the sheet is
// typed in Dart: a world point is projected by the scene's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/frutas/frutas_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef FrutasAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Las frutas' places, from its sheet.
class FrutasPlaces {
  FrutasPlaces(this.sheet) : e = frutasEngine();

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
  FrutasAt atWorld(num x, num y, num z) {
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

  /// Spot [name] with its projection; [dx] moves it along x in the world (the sheet's `monedas4`, `monedas2` rows:
  /// `dir` and `row.step`).
  FrutasAt at(String name, [double dx = 0]) {
    final w = world(name);
    return atWorld(w[0] + dx, w[1], w[2]);
  }

  /// The depth a sprite on spot [name] is drawn at: the spot's `drawn_depth` where the sheet gives one (the scale's pan
  /// and dial: rules.depth), else its depth.
  double drawnDepth(String name) {
    final s = sheet.spot(name);
    final dd = s.raw['drawn_depth'];
    return dd is num ? dd.toDouble() : at(name).d;
  }

  /// The screen point of spot [name] (`screen`: for a spot with no world point, `guineos`).
  List<double> screen(String name) =>
      sheet.spot(name).screen ??
      (throw SheetError('spot $name has no screen point'));

  /// The step along x of a row spot (`row.step`: `monedas4`, `monedas2`) and how many it holds (`row.n`).
  ({double step, int n}) row(String name) {
    final r = sheet.spot(name).raw['row'];
    if (r is! Map) throw SheetError('spot $name is not a row');
    return (step: (r['step'] as num).toDouble(), n: (r['n'] as num).toInt());
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  FrutasAt fromScreen(num sx, num sy, num z) {
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

  /// The assortment a bin belongs to (`things.<bin>.surtido`), or null for a thing that is no bin.
  String? surtidoOf(String id) => sheet.thing(id).raw['surtido'] as String?;

  /// The bins of assortment [s] (the sheet's `surtidos`).
  List<String> surtido(String s) {
    final m = sheet.extras['surtidos'];
    if (m is! Map || m[s] is! List) throw SheetError('no surtido $s');
    return (m[s] as List).cast<String>();
  }

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);
}
