import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El lago's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the lake and its dock are built round the old picture, so a place keeps its screen
/// place and its world point is the walkable surface under it (the planks, the lawn or the water). A frog's place `q` is
/// under `(q.x + 16, q.y + 25)`; a person's, Canelo's, a duck's, a bird's, a boat's, the bread's, the bag's, the sack's
/// or the flower's `(x, y)` under `(x, y - 1)`: their numbers are the old ones, but for the places the sheet moves
/// (`moves`, and the story files' own in `remap`). The sheet names each (spots, points, the `code` entries of each line,
/// the `moves` with their places and their new source); the rest of the old file's places are relative to a person, the
/// frog, a duck, a bird, a boat, the fish or a named place, or are screen effects, and the sheet's `code` says so.
class LagoPlaces {
  LagoPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's, an animal's, a thing's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  // a code entry that keeps every place on its line it does not move (its `to.floor`, or its note: "the floor rule:
  // every other place here keeps its screen place")
  static bool _keepsLine(SheetCode c) {
    final to = c.to;
    return (to is Map && to['floor'] == true) ||
        (c.note ?? '').contains(
          'every other place here keeps its screen place',
        );
  }

  /// A place of the old file at [line] that the floor rule keeps or `moves` moves:
  /// 1. the sheet's `moves` entry of that line whose old place is `x, y` (its `new`); a move named on several lines
  ///    (the same piece of source) gives its places on the line that lists them;
  /// 2. the `code` entry of that line that keeps every other place on it (`to.floor`, or its note says so): the same
  ///    numbers.
  /// A place the sheet does not name stops the scene (SheetError).
  List<int> floor(int line, num x, num y) {
    for (final m in sheet.moves) {
      if (m.line != line) continue;
      var places = m.places;
      if (places.isEmpty) {
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
    for (final c in sheet.code) {
      if (c.line == line && _keepsLine(c)) return [x.toInt(), y.toInt()];
    }
    throw SheetError(
      'the sheet of lago names no place [$x,$y] at lago.js:$line (code, moves): stop and ask, do not guess',
    );
  }

  /// A row (or an x) of the old file at [line] whose other coordinate is relative (`mueve("luis",b.x+16,154)`): kept, as
  /// the `code` entry of that line keeps every other place on it. SheetError when the line has no such entry.
  num keep(int line, num v) {
    for (final c in sheet.code) {
      if (c.line == line && _keepsLine(c)) return v;
    }
    throw SheetError(
      'the sheet of lago does not keep the places of lago.js:$line: stop and ask, do not guess',
    );
  }

  /// The lines of lago.js whose numbers the sheet's `code` has no entry for, and which only its rules keep ("every
  /// position of lago.js ... keeps its numbers, but those in moves"): acts.turno20 (line 263: the birds lifted by the
  /// bark rise to row 70, in the sky, as the circle of `rules.sky`), acts.suelta (line 276: the bread a bird drops falls
  /// to row `o.y || 178`) and acts.sevanp (line 278: the ducks swim out past the picture's right edge, x 252). Reported
  /// by order 35b; no other line may use [floorRule].
  static const Set<int> floorRuleOnly = {263, 276, 278};

  /// A number of [floorRuleOnly]'s lines: the sheet's `rules.floor` keeps it.
  num floorRule(int line, num v) {
    if (!floorRuleOnly.contains(line)) {
      throw SheetError('lago.js:$line: use floor (the sheet names its places)');
    }
    if (!(sheet.rules['floor'] ?? '').contains(
      'every position of lago.js, its stories and its pairs keeps its numbers',
    )) {
      throw SheetError('the sheet of lago has no floor rule for its positions');
    }
    return v;
  }

  static final RegExp _number = RegExp(r'-?\d+(?:\.\d+)?');

  /// The numbers of the new source the sheet's `moves` gives at [line] for the old source [src] (lago-preview.html
  /// replaces the one with the other), in their order: the moved line's own numbers, as the preview runs them. With
  /// [pattern], the numbers its groups catch in the new source (where a name or a sign would read as a number: `P7`,
  /// `x0`, `-5`).
  List<num> to(int line, String src, [RegExp? pattern]) {
    for (final m in sheet.moves) {
      if (m.line == line && m.src == src) {
        if (pattern == null) {
          return [for (final n in _number.allMatches(m.to)) num.parse(n[0]!)];
        }
        final g =
            pattern.firstMatch(m.to) ??
            (throw SheetError(
              'the moved source at lago.js:$line is not as the port reads it: ${m.to}',
            ));
        return [for (var i = 1; i <= g.groupCount; i++) num.parse(g[i]!)];
      }
    }
    throw SheetError('the sheet moves nothing at lago.js:$line from "$src"');
  }

  /// Where the answer cards stand after the act of [line] (`moves`: `respEn`).
  List<int> respEn(int line) {
    for (final m in sheet.moves) {
      if (m.line == line && m.respEn != null) return m.respEn!;
    }
    throw SheetError('the sheet gives no respEn at lago.js:$line');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`), of a screen point or of a point with a world point.
  List<double> pt(String name) => sheet.screenPoints.containsKey(name)
      ? sheet.screenPoint(name).xy
      : sheet.anchor(name).screen;

  /// The points of a list (`points.<name>.screen`: `[[x, y], ...]`).
  List<List<double>> pts(String name) =>
      sheet.screenPoint(name).points ??
      (throw SheetError('point "$name" is not a list of points'));

  /// The touch box of a thing (`things.<id>.box`, as the sheet's `code` for lines 76 and 77 gives it).
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
