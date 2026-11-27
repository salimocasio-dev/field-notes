// Every place El cielo uses, read from its sheet (docs/proyecto/pixel/cielo-sheet.json, SceneSheet) once:
// the spots (mecedora, mesa1, mesa2, piso, salida, radio, velas, tapa_puesta, tapa, chal, cuerda, manta, bandeja,
// sombrilla, chiringa_pie, chiringa, bola1, bola2, bola, telescopio, coqui.telescopio, luis.tel, carmen.tel, visor),
// the set things' boxes (cielo, nube, luna, estrella, cuerda), the sky positions, the view (wide, x0 22), the depth
// rule, and the shadows. No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cielo/cielo_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef CieloAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// El cielo's places, from its sheet.
class CieloPlaces {
  CieloPlaces(this.sheet) : e = cieloEngine();

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// Whether spot [name] has a world point (false for screen-only overlays like `visor`).
  bool hasWorld(String name) => sheet.spots[name]?.world != null;

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  CieloAt atWorld(num x, num y, num z) {
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
  CieloAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The screen point `[sx, sy]` of spot [name] (used for overlay spots like `visor` or exact sheet points).
  List<int> screen(String name) {
    final sc = sheet.spot(name).screen;
    if (sc != null && sc.length >= 2) {
      return [sc[0].round(), sc[1].round()];
    }
    throw SheetError('spot $name has no screen point');
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  CieloAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The screen box of spot [name] (e.g. `visor`, `sombrilla`, `velas`, `radio`).
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

  /// Sky landmark screen point `[x, y]` from `sky.<name>.screen` in cielo-sheet.json.
  List<int> skyScreen(String name) {
    final sky = sheet.raw['sky'];
    if (sky is Map && sky[name] is Map) {
      final sc = (sky[name] as Map)['screen'];
      if (sc is List && sc.length >= 2) {
        return [(sc[0] as num).toInt(), (sc[1] as num).toInt()];
      }
    }
    throw SheetError('cielo-sheet.json missing sky.$name.screen');
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
