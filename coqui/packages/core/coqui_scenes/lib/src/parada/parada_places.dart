// Every place La parada uses, read from its sheet (docs/proyecto/pixel/parada-sheet.json, SceneSheet) once: the spots,
// the things' boxes (the stop's two: its sign and its seat), the guagua's numbers (constants.guagua: the doors, the
// buttons, the panes of its windows), the view, the depth rule, the shadows. No number of the sheet is typed in Dart: a
// world point is projected by the set's engine.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/parada/parada_set.dart';

/// A place on the picture: its world point, its screen point (the projection, not rounded) and its depth.
typedef ParadaAt = ({
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double d,
});

/// La parada's places, from its sheet.
class ParadaPlaces {
  ParadaPlaces(this.sheet) : e = paradaEngine() {
    final c =
        sheet.extras['constants'] as Map? ??
        (throw SheetError('parada: no constants'));
    final g =
        c['guagua'] as Map? ??
        (throw SheetError('parada: no constants.guagua'));
    final en = c['E'] as Map? ?? (throw SheetError('parada: no constants.E'));
    double n(Object? v) => (v as num).toDouble();
    lane = n(g['y']);
    side = n(g['side']);
    length = n(g['length']);
    final w = g['windows'] as Map;
    paneZ = [for (final z in w['z'] as List) n(z)];
    paneFrom = n(w['from']);
    pane = n(w['pane']);
    period = n(w['period']);
    farLane = n(en['LANE1']);
    p1 = n(en['P1']);
    p2 = n(en['P2']);
    final stop =
        sheet.thing('parada').raw['boxes'] as List? ??
        (throw SheetError('parada: things.parada has no boxes'));
    stopBoxes = {
      for (final b in stop.cast<Map>())
        b['part'] as String: [
          for (final v in b['box'] as List) (v as num).toInt(),
        ],
    };
    stopWorlds = {
      for (final b in stop.cast<Map>())
        b['part'] as String: [
          for (final v in b['world'] as List) (v as num).toDouble(),
        ],
    };
  }

  final SceneSheet sheet;

  /// The set's engine, for its projection.
  final PpEngine e;

  /// The stop's lane (constants.guagua.y, rules.guagua: "a guagua at the stop stands with its middle at (P, 4.6)"), the
  /// plane of a guagua's lit side (constants.guagua.side), its length; the far lane (constants.E.LANE1); the middles of
  /// the two that stand at the stop (constants.E.P1, P2: the spots parada1, parada2).
  late final double lane, side, length, farLane, p1, p2;

  /// The panes of a guagua's windows (constants.guagua.windows): z from [paneZ] 0 to 1, from the front end the first at
  /// [paneFrom], each [pane] wide, one every [period], the last ending before length - from.
  late final List<double> paneZ;
  late final double paneFrom, pane, period;

  /// The stop's two boxes (things.parada.boxes: `sign`, `seat`): the screen box and the world box of each.
  late final Map<String, List<int>> stopBoxes;
  late final Map<String, List<double>> stopWorlds;

  /// Whether the sheet names spot [name].
  bool has(String name) => sheet.spots.containsKey(name);

  /// The world point of spot [name]; a spot the sheet does not name throws [SheetError].
  List<double> world(String name) {
    final s = sheet.spot(name);
    return s.world ?? (throw SheetError('spot $name has no world point'));
  }

  /// A world point with its projection.
  ParadaAt atWorld(num x, num y, num z) {
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
  ParadaAt at(String name) {
    final w = world(name);
    return atWorld(w[0], w[1], w[2]);
  }

  /// The world point at height [z] under screen point (sx, sy) (pp-engine.js project, inverted on the plane z).
  ParadaAt fromScreen(num sx, num sy, num z) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return atWorld((u + v) / e.R2, (v - u) / e.R2, z);
  }

  /// The world point on the plane y = [y], at height [z]... under screen point (sx, sy): the plane y = [y] (a guagua's
  /// lit side) read back from a screen pixel (parada-preview.html inPane).
  ({double x, double z}) onSide(num sx, num sy, double y) {
    final x = y + (sx - e.OX) / e.S * e.R2;
    final z = ((x + y) / e.R2 * .5 - (sy - e.OY) / e.S) / e.COS;
    return (x: x, z: z);
  }

  /// Whether screen pixel ([X], [Y]) is in a pane of the windows of a guagua whose middle is at x [mid] (heading `i`:
  /// its front end at mid - length / 2) (parada-preview.html inPane).
  bool inPane(num mid, int X, int Y) {
    final p = onSide(X + .5, Y + .5, side);
    final dn = p.x - (mid - length / 2);
    return p.z > paneZ[0] &&
        p.z < paneZ[1] &&
        dn > paneFrom &&
        dn < length - paneFrom &&
        ((dn - paneFrom).remainder(period)) < pane;
  }

  /// The view [name] as `cam`: `[x, y, w, h]`.
  List<num> view(String name) => sheet.view(name).cam;

  /// The screen box of set thing [id] (the sheet's `box`).
  List<int> box(String id) =>
      sheet.thing(id).box ?? (throw SheetError('thing $id has no box'));

  /// The world box of thing [id] (x0, y0, z0, x1, y1, z1).
  List<double> worldBox(String id) =>
      sheet.thing(id).world ?? (throw SheetError('thing $id has no world box'));

  /// The screen box of the world box [w] moved by [dx] along x: the bounding box of its 8 projected corners (rules.project).
  List<int> boxOf(List<double> w, [double dx = 0]) {
    var x0 = double.infinity, y0 = double.infinity;
    var x1 = double.negativeInfinity, y1 = double.negativeInfinity;
    for (final x in [w[0] + dx, w[3] + dx]) {
      for (final y in [w[1], w[4]]) {
        for (final z in [w[2], w[5]]) {
          final p = e.project(x, y, z);
          if (p.sx < x0) x0 = p.sx;
          if (p.sx > x1) x1 = p.sx;
          if (p.sy < y0) y0 = p.sy;
          if (p.sy > y1) y1 = p.sy;
        }
      }
    }
    final fx = x0.floor(), fy = y0.floor();
    return [fx, fy, x1.ceil() - fx, y1.ceil() - fy];
  }

  /// front.bias.
  double get bias => sheet.front.bias;

  /// The shadow radius of [character] (`shadows.byCharacter`), or null: none.
  double? radius(String character) => sheet.shadows.byCharacter[character];

  /// Whether spot [spot] casts no shadow (`shadows.none`).
  bool noShadow(String spot) => sheet.shadows.none.contains(spot);
}
