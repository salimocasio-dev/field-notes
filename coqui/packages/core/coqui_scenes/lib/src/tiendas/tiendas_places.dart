// Every place Las tiendas uses, read from its sheet (docs/proyecto/pixel/tiendas-sheet.json, SceneSheet) once: the spots,
// the things' boxes, the views, the groups, the depth rule, the shadows, for the row of shops (the sheet's top level) and
// for story 55's two buildings (the sheet's part `altos`, with its own origin). No number of the sheet is typed in Dart: a
// world point is projected by the engine of its picture.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/tiendas/tiendas_set.dart';

/// A place on one of the two pictures: its world point, its screen point (the projection, not rounded) and its depth.
typedef TiendasAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Las tiendas' places, from its sheet.
class TiendasPlaces {
  TiendasPlaces(this.sheet)
    : altos = sheet.part('altos'),
      e = tiendasEngine(),
      ea = tiendasAltosEngine();

  /// The sheet (the row, `fila=tiendas`) and its part `altos` (story 55's buildings: its own origin, spots, things,
  /// views, shadows).
  final SceneSheet sheet, altos;

  /// The engines of the two pictures, for their projections.
  final PpEngine e, ea;

  /// The sheet (or its part) of picture [fila] (`tiendas`, `altos`).
  SceneSheet of(String fila) => fila == 'altos' ? altos : sheet;

  /// The engine of picture [fila].
  PpEngine engineOf(String fila) => fila == 'altos' ? ea : e;

  /// Whether the sheet names spot [name] in picture [fila].
  bool has(String name, [String fila = 'tiendas']) =>
      of(fila).spots.containsKey(name);

  /// The world point of spot [name] in picture [fila]; a spot the sheet does not name throws [SheetError] (a place with
  /// no name is not placed by eye).
  List<double> world(String name, [String fila = 'tiendas']) {
    final s = of(fila).spot(name);
    return s.world ?? (throw SheetError('spot $name has no world point'));
  }

  /// A world point of picture [fila] with its projection.
  TiendasAt atWorld(num x, num y, num z, [String fila = 'tiendas']) {
    final p = engineOf(fila).project(x, y, z);
    return (
      x: x.toDouble(),
      y: y.toDouble(),
      z: z.toDouble(),
      sx: p.sx,
      sy: p.sy,
      d: p.d,
    );
  }

  /// Spot [name] of picture [fila], with its projection.
  TiendasAt at(String name, [String fila = 'tiendas']) {
    final w = world(name, fila);
    return atWorld(w[0], w[1], w[2], fila);
  }

  /// The world point at height [z] under screen point (sx, sy) of picture [fila] (pp-engine.js project, inverted on the
  /// plane z).
  TiendasAt fromScreen(num sx, num sy, num z, [String fila = 'tiendas']) {
    final en = engineOf(fila);
    final u = (sx - en.OX) / en.S,
        v = (sy - en.OY + z * en.COS * en.S) / (en.S * en.SIN);
    return atWorld((u + v) / en.R2, (v - u) / en.R2, z, fila);
  }

  /// The view of picture [fila] as `cam`: `[x, y, w, h]` (views.tiendas, altos.views.altos).
  List<num> view(String fila) => of(fila).view(fila).cam;

  /// The screen box of set thing [id] of the row (the sheet's `things.<id>.box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of set thing [id] of the row (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

  /// The screen box of story 55's building [id] (`alto`, `nuevo`) when the tall one stands on side [lado] (`izq`,
  /// `der`): the part's `things.<id>.<lado>.box`.
  List<int> buildingBox(String id, String lado) {
    final t = altos.thing(id).raw[lado];
    final b = t is Map ? t['box'] : null;
    if (b is! List) throw SheetError('altos: thing $id has no box for $lado');
    return [for (final x in b) (x as num).round()];
  }

  /// The world box of story 55's building [id] when the tall one stands on side [lado].
  List<double> buildingWorld(String id, String lado) {
    final t = altos.thing(id).raw[lado];
    final w = t is Map ? t['world'] : null;
    if (w is! List) throw SheetError('altos: thing $id has no world for $lado');
    return [for (final x in w) (x as num).toDouble()];
  }

  /// The side (`izq`, `der`) of story 55's building [id] when the tall one stands on side [lado]: the tall one on the
  /// side [lado] names, the low one on the other.
  static String sideOf(String id, String lado) =>
      (id == 'alto') == (lado == 'izq') ? 'izq' : 'der';

  /// front.bias.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] in picture [fila] (`shadows.byCharacter`), or null: none.
  double? radius(String character, [String fila = 'tiendas']) =>
      of(fila).shadows.byCharacter[character];

  /// Whether spot [spot] casts no shadow (`shadows.none`).
  bool noShadow(String spot, [String fila = 'tiendas']) =>
      of(fila).shadows.none.contains(spot);

  /// The spots of group [name] of picture [fila].
  List<String> group(String name, [String fila = 'tiendas']) =>
      of(fila).groups[name] ?? (throw SheetError('no group $name'));
}
