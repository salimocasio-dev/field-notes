// Every place El cuarto uses, read from its sheet (docs/proyecto/pixel/cuarto-sheet.json, SceneSheet) once:
// all 30 spots, 7 set boxes (cama, luz, silla, reloj, cuna, manta_luis, manta_carmen), beds, pillows, spot hang
// metadata, views.wide (x0 = 22), front.bias (0.3), shadows, and groups. Zero hardcoded sheet coordinates.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cuarto/cuarto_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef CuartoAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Hang metadata for a bed spot (`cama_luis`, `cama_carmen`, `sentado_luis`, `sentado_carmen`).
typedef CuartoHang = ({
  int rows,
  int bed,
  int foot,
  int lyingFrom,
  int sittingFrom,
  int width,
  double z,
});

/// Pillow geometry on a bed (`pillows[i]` in cuarto-sheet.json).
typedef CuartoPillow = ({
  List<double> screen,
  List<double> u,
  List<double> v,
  List<double> z,
});

/// El cuarto's places, from its sheet.
class CuartoPlaces {
  CuartoPlaces(this.sheet) : e = cuartoEngine();

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
  CuartoAt atWorld(num x, num y, num z) {
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
  CuartoAt at(String name) {
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
  CuartoAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// Center of the wall clock projected from `things.reloj.quad`.
  CuartoAt get clockCenter {
    final q = sheet.thing('reloj').raw['quad'];
    if (q is List && q.length == 4) {
      var sx = 0.0, sy = 0.0, sz = 0.0;
      for (final p in q) {
        final c = p as List;
        sx += (c[0] as num).toDouble();
        sy += (c[1] as num).toDouble();
        sz += (c[2] as num).toDouble();
      }
      return atWorld(sx / 4, sy / 4, sz / 4);
    }
    final b = box('reloj');
    return fromScreen(b[0] + b[2] / 2, b[1] + b[3] / 2, 0);
  }

  /// The screen box of spot [name] (e.g. `almohada_suelo`, `campana`, `plato`, `ropa_a`, `ropa_b`, `bebe`, `zetas`,
  /// `manta_abuelo`, `bajo_cama`).
  List<int> spotBox(String name) {
    final b = sheet.spot(name).raw['box'];
    if (b is List && b.length == 4) {
      return [for (final n in b) (n as num).toInt()];
    }
    throw SheetError('spot $name has no box');
  }

  /// Optional `[ax, ay]` anchor offset on spot [name] (e.g. `manta_abuelo` knees `[8, 6]`).
  List<int>? spotAtOffset(String name) {
    final a = sheet.spot(name).raw['at'];
    if (a is List && a.length == 2) {
      return [(a[0] as num).toInt(), (a[1] as num).toInt()];
    }
    return null;
  }

  /// Hang metadata for spot [name], or null if not a hung bed spot.
  CuartoHang? hang(String name) {
    final h = sheet.spot(name).raw['hang'];
    if (h is! Map) return null;
    final bf = h['blanketFrom'] as Map;
    return (
      rows: (h['rows'] as num).toInt(),
      bed: (h['bed'] as num).toInt(),
      foot: (h['foot'] as num).toInt(),
      lyingFrom: (bf['lying'] as num).toInt(),
      sittingFrom: (bf['sitting'] as num).toInt(),
      width: (h['width'] as num).toInt(),
      z: (h['z'] as num).toDouble(),
    );
  }

  /// Bed blanket RGB triples (`beds` in cuarto-sheet.json).
  late final List<List<int>> beds = [
    for (final b in (sheet.raw['beds'] as List))
      [for (final c in (b as List)) (c as num).toInt()],
  ];

  /// Bed pillow geometry (`pillows` in cuarto-sheet.json).
  late final List<CuartoPillow> pillows = [
    for (final p in (sheet.raw['pillows'] as List))
      (
        screen: [
          for (final v in (p as Map)['screen'] as List) (v as num).toDouble(),
        ],
        u: [for (final v in p['u'] as List) (v as num).toDouble()],
        v: [for (final v in p['v'] as List) (v as num).toDouble()],
        z: [for (final v in p['z'] as List) (v as num).toDouble()],
      ),
  ];

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));

  /// The touch map (`groups.touch` in cuarto-sheet.json).
  late final Map<String, String> touchSpots = {
    for (final e in (sheet.raw['groups']['touch'] as Map).entries)
      e.key as String: e.value as String,
  };
}
