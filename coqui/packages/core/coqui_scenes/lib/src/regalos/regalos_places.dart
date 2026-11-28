// Every place Los regalos uses, read from its sheet (docs/proyecto/pixel/regalos-sheet.json, SceneSheet) once:
// the 35 spots (cortina, fondo1..2, tras_cortina, arco, banco1..3, junto_banco, mesa1..3, mesa_coqui, tras_mesa..3,
// cuerda1..4, fotos1..4, caja_velas, taburete, banqueta_coqui, paquete, banqueta_izq, banqueta_der, lista_abuela,
// luis_patio, espera1..3), the set/curtain boxes (cortina, banqueta), the view (wide, x0 19), the depth rule, and
// the shadows. No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/regalos/regalos_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef RegalosAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// Los regalos's places, from its sheet.
class RegalosPlaces {
  RegalosPlaces(this.sheet) : e = regalosEngine();

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
  RegalosAt atWorld(num x, num y, num z) {
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
  RegalosAt at(String name) {
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
  RegalosAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set or curtain thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The half-open box of the curtain (`things.cortina.half`).
  List<int> get curtainHalfBox {
    final things = sheet.raw['things'];
    if (things is Map && things['cortina'] is Map) {
      final b = (things['cortina'] as Map)['half'];
      if (b is List && b.length == 4) {
        return [for (final n in b) (n as num).toInt()];
      }
    }
    throw SheetError('things.cortina has no half box');
  }

  /// The arch hole bounds `[x0, x1, y0, y1]` on screen (for `fondo-head` checks).
  List<double> get archBounds {
    const a = RegalosE.ARCH;
    final p0 = e.project(a[0] / e.R2, -a[0] / e.R2, a[3]);
    final p1 = e.project(a[1] / e.R2, -a[1] / e.R2, a[2]);
    return [p0.sx, p1.sx, p0.sy, p1.sy];
  }

  /// The four wall peg boxes (`set.pegs[i].box`).
  List<List<int>> get pegBoxes {
    final setMap = sheet.raw['set'];
    if (setMap is Map && setMap['pegs'] is List) {
      return [
        for (final p in setMap['pegs'] as List)
          [for (final n in (p as Map)['box'] as List) (n as num).toInt()],
      ];
    }
    return const [];
  }

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

  /// front.bias: how much nearer than a character's feet a set pixel must be to hide it.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) =>
      sheet.shadows.byCharacter[character] ??
      (character == 'pepe' ? sheet.shadows.byCharacter['don_pepe'] : null);

  /// Whether a spot casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);

  /// The spots of group [name].
  List<String> group(String name) =>
      sheet.groups[name] ?? (throw SheetError('no group $name'));
}
