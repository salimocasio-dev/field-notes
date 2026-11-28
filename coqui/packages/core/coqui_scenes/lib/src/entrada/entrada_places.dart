// Every place La entrada uses, read from its sheet (docs/proyecto/pixel/entrada-sheet.json, SceneSheet) once:
// the 51 spots (cola1..2, puerta1..4, felpudo, banco_coqui, banco1..2, atril, taburete, ante_atril, taburete_coqui,
// atril1..4, ante_cuerda1..2, tras_cuerda, paso1..2, choque, mesa1_a..d, mesa1_coqui, mesa2_a..d, mesa2_coqui,
// mesa3_a..d, mesa3_coqui, vellonera1..2, velas, junto_mesa, bandeja, cosa_a, cosa_b, menu, dulces, mesera_fin,
// flores, tarjeta), the set things' boxes (banco, mesa1..3, puerta, vellonera), the table cloths (`cloths.mesa2`,
// `cloths.mesa3`), the view (wide, x0 21), the depth rule, and the shadows.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/entrada/entrada_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef EntradaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Cloth geometry from `entrada-sheet.json` (`cloths.<tableId>`).
typedef EntradaCloth = ({
  List<double> uv,
  List<int> screen,
  List<int> box,
  int topRows,
  int ax,
});

/// La entrada's places, from its sheet.
class EntradaPlaces {
  EntradaPlaces(this.sheet) : e = entradaEngine();

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
  EntradaAt atWorld(num x, num y, num z) {
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

  /// A (u, v, z) point square to the picture, projected via PZ.xy.
  EntradaAt atUv(num u, num v, num z) =>
      atWorld((u + v) / e.R2, (v - u) / e.R2, z);

  /// Spot [name], with its projection.
  EntradaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The (u, v, z) coordinates of spot [name] from `entrada-sheet.json`.
  List<double> uv(String name) {
    final spots = sheet.raw['spots'];
    if (spots is Map && spots[name] is Map) {
      final raw = (spots[name] as Map)['uv'];
      if (raw is List && raw.length >= 3) {
        return [
          (raw[0] as num).toDouble(),
          (raw[1] as num).toDouble(),
          (raw[2] as num).toDouble(),
        ];
      }
    }
    throw SheetError('spot $name has no uv');
  }

  /// The screen point `[sx, sy]` of spot [name] from `entrada-sheet.json`.
  List<int> screen(String name) {
    final sc = sheet.spot(name).screen;
    if (sc != null && sc.length >= 2) {
      return [sc[0].round(), sc[1].round()];
    }
    throw SheetError('spot $name has no screen point');
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  EntradaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The screen box of spot [name] (e.g. `velas`, `cosa_a`, `cosa_b`, `menu`, `dulces`, `flores`, `tarjeta`).
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

  /// Cloth descriptor for [tableId] (`mesa2` or `mesa3`) from `entrada-sheet.json`.
  EntradaCloth cloth(String tableId) {
    final cloths = sheet.raw['cloths'];
    if (cloths is Map && cloths[tableId] is Map) {
      final m = cloths[tableId] as Map;
      final uvRaw = m['uv'] as List;
      final scRaw = m['screen'] as List;
      final boxRaw = m['box'] as List;
      return (
        uv: [for (final n in uvRaw) (n as num).toDouble()],
        screen: [for (final n in scRaw) (n as num).toInt()],
        box: [for (final n in boxRaw) (n as num).toInt()],
        topRows: (m['topRows'] as num).toInt(),
        ax: (m['ax'] as num).toInt(),
      );
    }
    throw SheetError('entrada-sheet.json missing cloths.$tableId');
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
