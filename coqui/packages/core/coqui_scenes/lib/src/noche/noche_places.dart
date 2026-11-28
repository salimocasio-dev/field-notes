// Every place La noche uses, read from its sheet (docs/proyecto/pixel/noche-sheet.json, SceneSheet) once:
// the 25 spots (sofa1..3, butaca, brazo_coqui, alfombra1..2, ventana_abuelo, ventana_coqui, silla1..4, junto_mesa,
// ensalada, aparador_coqui, jugo, flan, queso, frutas, vela, mesa_coqui, perro, cama1..2), the set thing boxes
// (television, luz1..3, reloj, mesa, aparador, cama, sofa), the bed blanket metadata (cama.foot, cama.blanket,
// cama.colour), held-item offsets (bufanda, lana, libro), the view (wide, x0 22), the depth rule, and the shadows.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/noche/noche_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef NocheAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La noche's places, from its sheet.
class NochePlaces {
  NochePlaces(this.sheet) : e = nocheEngine();

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
  NocheAt atWorld(num x, num y, num z) {
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
  NocheAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The (u, v, z) coordinates of spot [name].
  List<double> uv(String name) {
    final raw = sheet.raw['spots'];
    if (raw is Map && raw[name] is Map) {
      final list = (raw[name] as Map)['uv'];
      if (list is List && list.length >= 3) {
        return [for (final n in list) (n as num).toDouble()];
      }
    }
    throw SheetError('spot $name has no uv');
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
  NocheAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The screen box of spot [name].
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

  /// Held-item anchor (`things.<name>.on` + `px` offset).
  ({String on, int dx, int dy}) heldOffset(String name) {
    final things = sheet.raw['things'];
    if (things is Map && things[name] is Map) {
      final m = things[name] as Map;
      final on = m['on'] as String?;
      final px = m['px'] as List?;
      if (on != null && px != null && px.length >= 2) {
        return (on: on, dx: (px[0] as num).toInt(), dy: (px[1] as num).toInt());
      }
    }
    throw SheetError('thing $name missing on/px');
  }

  /// Bed blanket metadata from `things.cama`.
  ({int footX, int footY, int width, int centerX, List<int> colour})
  get camaMeta {
    final things = sheet.raw['things'];
    if (things is Map && things['cama'] is Map) {
      final m = things['cama'] as Map;
      final foot = m['foot'] as List;
      final blanket = m['blanket'] as List;
      final col = m['colour'] as List;
      return (
        footX: (foot[0] as num).toInt(),
        footY: (foot[1] as num).toInt(),
        width: (blanket[0] as num).toInt(),
        centerX: (blanket[1] as num).toInt(),
        colour: [for (final c in col) (c as num).toInt()],
      );
    }
    throw SheetError('noche-sheet.json missing things.cama metadata');
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
