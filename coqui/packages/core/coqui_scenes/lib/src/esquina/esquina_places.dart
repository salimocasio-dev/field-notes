// Every place La esquina uses, read from its sheet (docs/proyecto/pixel/esquina-sheet.json, SceneSheet) once: the spots,
// the things' boxes, the view, the traffic's lanes (`routes.trafico`, kept by SceneSheet as plain data and read here),
// the depth rule, the shadows. No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/esquina/esquina_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef EsquinaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La esquina's places, from its sheet.
class EsquinaPlaces {
  EsquinaPlaces(this.sheet) : e = esquinaEngine() {
    final tr =
        ((sheet.extras['routes'] as Map?)?['trafico'] as Map?)?['lanes']
            as Map? ??
        (throw SheetError('esquina: no routes.trafico.lanes'));
    lanes = {
      for (final l in tr.entries)
        l.key as String: (
          entra: _w(((l.value as Map)['entra'] as Map)['world']),
          sale: _w(((l.value as Map)['sale'] as Map)['world']),
        ),
    };
  }

  static List<double> _w(Object? v) => [
    for (final x in (v as List)) (x as num).toDouble(),
  ];

  final SceneSheet sheet;

  /// The set's engine, for its projection.
  final PpEngine e;

  /// The traffic's two lanes of street A (`routes.trafico.lanes`: `lejos` the far one, `cerca` the near one): where a
  /// thing that drives enters the picture at the right and leaves it at the left, as world points.
  late final Map<String, ({List<double> entra, List<double> sale})> lanes;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name] (an alias, `alternatives.aliases`, is its own spot in the sheet); a spot the sheet
  /// does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ?? (throw SheetError('spot $name has no world point'));
  }

  /// A world point with its projection.
  EsquinaAt atWorld(num x, num y, num z) {
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
  EsquinaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  EsquinaAt fromScreen(num sx, num sy, num z) {
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
