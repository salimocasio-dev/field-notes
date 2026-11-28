// Every place La muralla uses, read from its sheet (docs/proyecto/pixel/muralla-sheet.json, SceneSheet) once:
// the 62 spots (farol1..3, centro1..7, camara, camara_abuela, junto_camara, ante_todos, juego_coqui, junto_coqui,
// dentro_roja, dentro_azul, ventana_roja, ventana_azul, sale_roja, sale_azul, banco1..4, vela, muro1..3, baile1..6,
// jugo, plato, mesa_coqui, junto_mesa, mesa1..5, junto_mesa_coqui, escalera_abuela, escalera_abuelo, escalera1..4,
// baja, guagua, guagua_se_va, musico_lejos1..2, pretil1..4, pretil_coqui), the set/door boxes (puerta_roja,
// puerta_azul, banco, escalera), the lanterns' cord decor metadata, the view (wide, x0 22), the depth rule, and the
// shadows.
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/muralla/muralla_set.dart';

/// A place on the picture: its world point, its screen point (projection or far-road px) and its depth.
typedef MurallaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
  bool isPx,
});

/// La muralla's places, from its sheet.
class MurallaPlaces {
  MurallaPlaces(this.sheet) : e = murallaEngine();

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  // OPEN: muralla-sheet.json names centro1..centro7; when Carmen exits puerta_roja in story 117 while
  // centro1..7 are already occupied, she takes synthetic 8th front-row spot `centro8` at (u -2.0, v 3.5, z 0),
  // screen (68, 130), 26 px left of centro5, 16 px below centro1, clear of puerta_roja and inside [22, 218).
  static const List<double> _centro8Uv = [-2.0, 3.5, 0.0];

  /// Whether the sheet (or synthetic `centro8`) names spot [name].
  bool has(String name) => name == 'centro8' || sheet.spots.containsKey(name);

  /// Whether spot [name] is a far-road pixel spot (`px: 1` on muralla-sheet.json).
  bool isPxSpot(String name) {
    final spots = sheet.raw['spots'];
    if (spots is Map && spots[name] is Map) {
      return jsTruthy((spots[name] as Map)['px']);
    }
    return false;
  }

  /// Far-road depth matching muralla-preview.html `farD(sy)`.
  double farDepth(num sy) =>
      ((sy - e.OY) / (e.S * math.sin(math.pi / 6))) * e.COS;

  /// The `(u, v, z)` coordinates of spot [name].
  List<double> uv(String name) {
    if (name == 'centro8') return List<double>.from(_centro8Uv);
    final spots = sheet.raw['spots'];
    if (spots is Map && spots[name] is Map) {
      final list = (spots[name] as Map)['uv'];
      if (list is List && list.length >= 3) {
        return [for (final n in list) (n as num).toDouble()];
      }
    }
    throw SheetError('spot $name has no uv');
  }

  /// The world point of spot [name]; `px` spots or missing spots throw [SheetError].
  List<double> world(String name) {
    if (name == 'centro8') {
      final u = _centro8Uv[0], v = _centro8Uv[1], z = _centro8Uv[2];
      return [(u + v) / e.R2, (v - u) / e.R2, z];
    }
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  MurallaAt atWorld(num x, num y, num z) {
    final p = e.project(x, y, z);
    return (
      x: x.toDouble(),
      y: y.toDouble(),
      z: z.toDouble(),
      sx: p.sx,
      sy: p.sy,
      d: p.d,
      isPx: false,
    );
  }

  /// A `uvz` point with its projection.
  MurallaAt atUv(num u, num v, num z) =>
      atWorld((u + v) / e.R2, (v - u) / e.R2, z);

  /// Spot [name], with its projection (or `farDepth` for `px: 1` far-road spots).
  MurallaAt at(String name) {
    if (isPxSpot(name)) {
      final sc = screen(name);
      return (
        x: 0.0,
        y: 0.0,
        z: 0.0,
        sx: sc[0].toDouble(),
        sy: sc[1].toDouble(),
        d: farDepth(sc[1]),
        isPx: true,
      );
    }
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The screen point `[sx, sy]` of spot [name].
  List<int> screen(String name) {
    if (name == 'centro8') {
      final p = at('centro8');
      return [(p.sx + .5).floor(), (p.sy + .5).floor()];
    }
    final sc = sheet.spot(name).screen;
    if (sc != null && sc.length >= 2) {
      return [sc[0].round(), sc[1].round()];
    }
    throw SheetError('spot $name has no screen point');
  }

  /// The world point at height [z] under screen point `(sx, sy)` (pp-engine.js project, inverted on plane `z`).
  MurallaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S;
    final v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atUv(u, v, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box `[x, y, w, h]` of set thing [id] (`puerta_roja`, `puerta_azul`, `banco`, `escalera`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The RGB door colour of `puerta_roja` or `puerta_azul` (`things.<id>.colour`).
  List<int> doorColour(String id) {
    final things = sheet.raw['things'];
    if (things is Map && things[id] is Map) {
      final c = (things[id] as Map)['colour'];
      if (c is List && c.length >= 3) {
        return [for (var i = 0; i < 3; i++) (c[i] as num).toInt()];
      }
    }
    return id == 'puerta_roja' ? const [206, 70, 64] : const [70, 110, 206];
  }

  /// The screen box `[x, y, w, h]` of spot [name].
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

  /// The lanterns' cord geometry (`decor.cuerda`) read from the sheet.
  ({double u0, double u1, double v, double z, double sag, List<int> colour})
  get cordMeta {
    final decor = sheet.raw['decor'];
    final c = decor is Map ? decor['cuerda'] as Map : const {};
    return (
      u0: (c['u0'] as num).toDouble(),
      u1: (c['u1'] as num).toDouble(),
      v: (c['v'] as num).toDouble(),
      z: (c['z'] as num).toDouble(),
      sag: (c['sag'] as num).toDouble(),
      colour: [for (final n in c['colour'] as List) (n as num).toInt()],
    );
  }

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character], or null if none.
  double? radius(String character, {bool isChild = false}) =>
      sheet.shadows.byCharacter[character] ??
      (isChild
          ? sheet.shadows.radius['ninos']
          : sheet.shadows.radius['adultos']);

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
