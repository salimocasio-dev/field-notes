import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El campo's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the field is built round the old picture, so a place on its ground keeps its
/// screen place. A frog's place `q` is the ground point under `(q.x + 16, q.y + 25)`; a person's, Canelo's, a ball's or
/// the basket's `(x, y)` the ground point under `(x, y - 1)`: their numbers are the old ones, but for the places the
/// sheet moves (`moves`, and the story files' own in `remap`). The sheet names each (spots, points, the `code` entries of
/// each line, the `moves` with their places); the rest of the old file's places are relative to a person, the frog,
/// Canelo, a ball, the old crown or a named place, or are screen effects, and the sheet's `code` says so for each line.
class CampoPlaces {
  CampoPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's, Canelo's, a ball's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  bool _named(String old, num x, num y) =>
      old.replaceAll(' ', '').contains('[${_js(x)},${_js(y)}]');

  static String _js(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  /// A place of the old file at [line] that the floor rule keeps or `moves` moves:
  /// 1. the sheet's `moves` entry of that line whose old place is `x, y` (its `new`); a move named on several lines
  ///    (the same piece of source, as campo-preview.html replaces it everywhere at once) gives its places on the first
  ///    line it lists them;
  /// 2. a `moves` entry of that line whose new source keeps `x` and `y` as they are (`ar?82:158`: Luis's place under the
  ///    tree, line 238): the same numbers;
  /// 3. the `code` entry of that line that names `[x,y]` (the floor rule: the same numbers), or else the line's entry
  ///    that keeps every place on it (`floor: true`, "every place here keeps its screen place": esconde16's people on
  ///    line 263, bajoarbol's on line 232).
  /// A place the sheet does not name stops the scene (SheetError).
  List<int> floor(int line, num x, num y) {
    for (final m in sheet.moves) {
      if (m.line != line) continue;
      var places = m.places;
      if (places.isEmpty) {
        // the same move named at another line, with its places
        for (final o in sheet.moves) {
          if (o.src == m.src && o.places.isNotEmpty) {
            places = o.places;
            break;
          }
        }
      }
      for (final p in places) {
        if (p.old[0] == x && p.old[1] == y) {
          return [for (final v in p.now) v.toInt()];
        }
      }
    }
    for (final m in sheet.moves) {
      if (m.line == line &&
          m.to.contains('?${_js(x)}:') &&
          m.to.contains('?${_js(y)}:')) {
        return [x.toInt(), y.toInt()];
      }
    }
    SheetCode? whole;
    for (final c in sheet.code) {
      final to = c.to;
      if (c.line != line || to is! Map || to['floor'] != true) continue;
      if (_named(c.old, x, y)) return [x.toInt(), y.toInt()];
      whole ??= c;
    }
    if (whole != null) return [x.toInt(), y.toInt()];
    throw SheetError(
      'the sheet of campo names no place [$x,$y] at campo.js:$line (code, moves): stop and ask, do not guess',
    );
  }

  /// The lines of campo.js whose places the sheet's `code` has no entry for, and which only its `rules.floor` keeps
  /// ("every ground position of campo.js (..., the acts' places) ... keeps its numbers"): acts.aparta (line 233: the
  /// two children back to their places of inicio16, line 228) and the three balls of acts.final16 (line 286, `108 + i *
  /// 18, 196`). Reported by order 34b; no other line may use [floorRule].
  static const Set<int> floorRuleOnly = {233, 286};

  /// A place of [floorRuleOnly]'s lines: the sheet's `rules.floor` keeps its numbers (the same screen place).
  List<num> floorRule(int line, num x, num y) {
    if (!floorRuleOnly.contains(line)) {
      throw SheetError(
        'campo.js:$line: use floor (the sheet names its places)',
      );
    }
    if (!(sheet.rules['floor'] ?? '').contains('the acts\' places')) {
      throw SheetError(
        'the sheet of campo has no floor rule for the acts\' places',
      );
    }
    return [x, y];
  }

  /// Where the answer cards stand after the act of [line] (`moves`: `respEn`).
  List<int> respEn(int line) {
    for (final m in sheet.moves) {
      if (m.line == line && m.respEn != null) return m.respEn!;
    }
    throw SheetError('the sheet gives no respEn at campo.js:$line');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`), of a screen point or of a point with a world point.
  List<double> pt(String name) => sheet.screenPoints.containsKey(name)
      ? sheet.screenPoint(name).xy
      : sheet.anchor(name).screen;

  /// The touch box of a thing (`things.<id>.box`, as the sheet's `code` for lines 66 to 68 gives it).
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
