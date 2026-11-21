import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El patio's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the yard is built round the old picture, so a place on its lawn keeps its screen
/// place. A frog's place `q` is the ground point under `(q.x + 16, q.y + 25)`, a person's `(x, y)` the ground point
/// under `(x, y - 1)`: their numbers are the old ones, but for the few the sheet moves (`moves`). The sheet names each
/// with its world point (spots, remap, the `code` entries with their `new`); the rest of the old file's places are
/// relative to a person, the frog or a point, or are screen effects, and the sheet's `code` says so for each.
class PatioPlaces {
  PatioPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
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
      'the sheet of patio names no place [$x,$y] at patio.js:$line (code, moves): stop and ask, do not guess',
    );
  }

  /// Who the sheet's `moves` entry of [line] moves, and the sort row it gives one ([SheetMove.places] `z`), by the old
  /// place: the baby in mamá's arms (patio.js:290).
  num? floorZ(int line, num x, num y) {
    for (final m in sheet.moves) {
      if (m.line != line) continue;
      for (final p in m.places) {
        if (p.old[0] == x && p.old[1] == y) return p.z;
      }
    }
    throw SheetError('the sheet moves no place [$x,$y] at patio.js:$line');
  }

  /// Where the answer cards stand after the act of [line] (`moves`: `respEn`).
  List<int> respEn(int line) {
    for (final m in sheet.moves) {
      if (m.line == line && m.respEn != null) return m.respEn!;
    }
    throw SheetError('the sheet gives no respEn at patio.js:$line');
  }

  /// The values of W a move of [line] changes (`moves`: `values`), by key: the old value and the new.
  ({num old, num now}) value(int line, String key) {
    for (final m in sheet.moves) {
      if (m.line != line) continue;
      for (final v in m.values) {
        if (v.key == key) return (old: v.old, now: v.now);
      }
    }
    throw SheetError('the sheet moves no value $key at patio.js:$line');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`).
  List<double> pt(String name) => sheet.screenPoint(name).xy;

  /// A list of points on the screen (`points.<name>.screen`).
  List<List<double>> pts(String name) =>
      sheet.screenPoint(name).points ??
      (throw SheetError('point "$name" is not a list of points'));

  /// A point given with a world point (`points.<name>`: the nest): the screen place the sheet gives it (the bird's feet
  /// on the nest), not the projection of the world point (the nest's middle).
  List<double> anchorScreen(String name) => sheet.anchor(name).screen;

  /// The touch box of a thing (`things.<id>.box`, as the sheet's `code` for lines 93 to 95 gives it).
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

  /// A view's camera value `[x, y, w, h]` (zoom 1: 196 × 216).
  List<int> view(String name) => sheet.viewOf(name, e);
}
