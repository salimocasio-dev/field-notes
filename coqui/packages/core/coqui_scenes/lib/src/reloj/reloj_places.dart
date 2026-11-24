// Every place El reloj uses, read from its sheet (docs/proyecto/pixel/reloj-sheet.json, SceneSheet) once: the spots,
// the things' boxes, the view, the depth rule, the shadows, the clock hands' pivot and lengths (`hands`, kept by
// SceneSheet as plain data), where the two time cards stand over the frog (things.carta_a, carta_b: their boxes for
// the frog at pie2, rules.cards: the same offsets from wherever he is), and the five squares of abuela's bingo card
// (n40, n60, n80, n90, n100). No number of the sheet is typed in Dart: a world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/reloj/reloj_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef RelojAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

int _round(num v) => (v + 0.5).floor();

/// El reloj's places, from its sheet.
class RelojPlaces {
  RelojPlaces(this.sheet) : e = relojEngine() {
    // rules.cards: the two boxes are those of the frog at pie2; each keeps its offset from his spot's screen point
    final a = box('carta_a'), b = box('carta_b'), at = this.at('pie2');
    final sx = _round(at.sx), sy = _round(at.sy);
    cardA = [a[0] - sx, a[1] - sy, a[2], a[3]];
    cardB = [b[0] - sx, b[1] - sy, b[2], b[3]];

    final h = sheet.raw['hands'];
    if (h is! Map) throw SheetError('reloj sheet has no hands');
    final pw = (h['pivot'] as Map)['world'] as List;
    handPivot = atWorld(pw[0] as num, pw[1] as num, pw[2] as num);
    longHand = (h['long'] as num).toInt();
    shortHand = (h['short'] as num).toInt();
    handWidth = (h['width'] as num).toInt();
  }

  final SceneSheet sheet;

  /// The engine of the picture, for its projection.
  final PpEngine e;

  /// The time cards' boxes relative to the frog's spot (its screen point, rounded): x, y, w, h.
  late final List<int> cardA, cardB;

  /// The clock face's middle on the tower's front (sheet: hands.pivot).
  late final RelojAt handPivot;

  /// The long and short hands' lengths and stroke width in px (sheet: hands).
  late final int longHand, shortHand, handWidth;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ??
        (throw SheetError('spot $name is not drawn (it has no world point)'));
  }

  /// A world point with its projection.
  RelojAt atWorld(num x, num y, num z) {
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
  RelojAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  RelojAt fromScreen(num sx, num sy, num z) {
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

  /// The clock face's disc (centre [x, y] and radius r), from `things.reloj.disc`.
  ({double cx, double cy, double r}) get faceDisc {
    final raw = sheet.raw['things'] as Map;
    final d = (raw['reloj'] as Map)['disc'] as Map;
    final c = d['centre'] as List;
    return (
      cx: (c[0] as num).toDouble(),
      cy: (c[1] as num).toDouble(),
      r: (d['r'] as num).toDouble(),
    );
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
