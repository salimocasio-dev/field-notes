import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El camino's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the park is built round the old picture, so a place on its ground keeps its screen
/// place. A frog's place `q` is the ground point under `(q.x + 16, q.y + 25)`, a person's or an animal's `(x, y)` the
/// ground point under `(x, y - 1)`: their numbers are the old ones, but for the few the sheet moves (`moves`, and the
/// story files' own in `remap`). The sheet names each with its world point (spots, remap, the `code` entries with their
/// `new`); the rest of the old file's places are relative to a person, the frog, an animal, a tree or a mark, or are
/// screen effects, and the sheet's `code` says so for each.
class CaminoPlaces {
  CaminoPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's or an animal's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  /// A frog's spot today with his size there: `[q.x, q.y, scale]` (`spots.<name>`: `new` and `scale`).
  List<num> frogSpot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = spot(name);
    return [
      n[0],
      n[1],
      s.scale ?? (throw SheetError('spot "$name" has no scale')),
    ];
  }

  /// A place of the old file at [line] that the floor rule keeps or `moves` moves: the place of the sheet's `moves`
  /// entry of that line whose old place is `x, y` (its `new`), or else the `code` entry of that line that names `x, y`
  /// among its `new` places (the floor rule: the same numbers). A place the sheet does not name stops the scene
  /// (SheetError).
  List<int> floor(int line, num x, num y) {
    for (final m in sheet.moves) {
      if (m.line != line) continue;
      for (final p in m.places) {
        if (p.old[0] == x && p.old[1] == y) {
          return [for (final v in p.now) v.toInt()];
        }
      }
    }
    bool same(Object? p) =>
        p is List && p.length == 2 && p[0] == x && p[1] == y;
    for (final c in sheet.code) {
      final to = c.to;
      if (c.line != line || to is! Map || to['new'] is! List) continue;
      final n = to['new'] as List;
      if (same(n) || n.any(same)) return [x.toInt(), y.toInt()];
    }
    throw SheetError(
      'the sheet of camino names no place [$x,$y] at camino.js:$line (code, moves): stop and ask, do not guess',
    );
  }

  /// Where the answer cards stand after the act of [line] (`moves`: `respEn`).
  List<int> respEn(int line) {
    for (final m in sheet.moves) {
      if (m.line == line && m.respEn != null) return m.respEn!;
    }
    throw SheetError('the sheet gives no respEn at camino.js:$line');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`), of a screen point or of a point with a world point.
  List<double> pt(String name) => sheet.screenPoints.containsKey(name)
      ? sheet.screenPoint(name).xy
      : sheet.anchor(name).screen;

  /// A list of points on the screen (`points.<name>.screen`).
  List<List<double>> pts(String name) =>
      sheet.screenPoint(name).points ??
      (throw SheetError('point "$name" is not a list of points'));

  /// The touch box of a thing (`things.<id>.box`, as the sheet's `code` for lines 66 to 72 gives it).
  List<int> box(String thing) =>
      (sheet.things[thing] ??
              (throw SheetError('the sheet has no thing "$thing"')))
          .box ??
      (throw SheetError('thing "$thing" has no box'));

  /// The hint hand's point of a thing (`things.<id>.hand`), or null.
  List<int>? hand(String thing) =>
      (sheet.things[thing] ??
              (throw SheetError('the sheet has no thing "$thing"')))
          .hand;

  /// Where the hint frame of a thing is drawn (`things.<id>.hintBox`), or null: round its box.
  List<int>? hintBox(String thing) =>
      (sheet.things[thing] ??
              (throw SheetError('the sheet has no thing "$thing"')))
          .hintBox;

  /// A view's camera value `[x, y, w, h]` (zoom 1: 196 × 216).
  List<int> view(String name) => sheet.viewOf(name, e);
}
