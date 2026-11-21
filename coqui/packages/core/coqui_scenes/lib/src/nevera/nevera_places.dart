import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen La nevera's scene uses, read from its sheet once (page 12, section 5: "every screen
/// position in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its
/// own: each comes from the sheet, or is checked against it.
///
/// The sheet's rules (`rules.floor`): the kitchen is built round the old picture, so a place on the floor keeps its screen
/// place and its world point is the floor under it; a place on the old level rows of the counter, the sill, the yard wall
/// or outside keeps its x and stands on the new sloping row there (CT, SL, MU, PA: `moves`); the fridge's places are the
/// nearest that show whole (`moves`). Every position of nevera.js, its stories and its pairs keeps its numbers, but those
/// the sheet moves (`moves`, and the stories' and pairs' own in `remap`). The sheet names each line that holds numbers (`code`: 246 entries, each line's numbers by kind), so a
/// number kept by the floor rule is checked to be one the sheet names at its line ([at]), and a moved one is read from
/// the moved source itself ([to]).
class NeveraPlaces {
  NeveraPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's, a thing's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  // the code entry of nevera.js's line [line]
  SheetCode _code(int line) {
    for (final c in sheet.code) {
      if (c.line == line) return c;
    }
    throw SheetError(
      'the sheet of nevera has no code entry for nevera.js:$line: stop and ask, do not guess',
    );
  }

  // whether the code entry keeps the numbers of its line it does not move: "unchanged", the floor rule (`to.floor`), or
  // a moved line whose other places keep their screen place
  static bool _keeps(SheetCode c) {
    final to = c.to;
    return to == 'unchanged' ||
        (to is Map && to['floor'] == true) ||
        (to is Map &&
            (to['spots'] != null ||
                to['points'] != null ||
                to['things'] != null ||
                to['view'] != null)) ||
        (c.note ?? '').contains(
          'every other place here keeps its screen place',
        );
  }

  /// A number of nevera.js's line [line] that the sheet keeps (the floor rule, unchanged): it must be one of the numbers
  /// the sheet's `code` entry of that line names (any kind: a place, an offset, a count). A number the sheet does not
  /// name at that line stops the scene (SheetError).
  num at(int line, num v) {
    final c = _code(line);
    if (!_keeps(c)) {
      throw SheetError(
        'nevera.js:$line: the sheet does not keep its numbers (${c.to}): stop and ask, do not guess',
      );
    }
    final nums = c.raw['numbers'];
    final s = jsNum(v);
    if (nums is Map) {
      for (final l in nums.values) {
        if (l is List && l.contains(s)) return v;
      }
    }
    throw SheetError(
      'the sheet of nevera names no number $s at nevera.js:$line (code): stop and ask, do not guess',
    );
  }

  static final RegExp _number = RegExp(r'-?\d+(?:\.\d+)?');

  /// The numbers of the new source the sheet's `moves` gives at [line] for the old source that starts with [src]
  /// (nevera-preview.html replaces the one with the other), in their order: the moved line's own numbers, as the preview
  /// runs them. With [pattern], the numbers its groups catch in the new source.
  List<num> to(int line, String src, [RegExp? pattern]) {
    for (final m in sheet.moves) {
      if (m.line == line && m.src.startsWith(src)) {
        if (pattern == null) {
          return [for (final n in _number.allMatches(m.to)) num.parse(n[0]!)];
        }
        final g =
            pattern.firstMatch(m.to) ??
            (throw SheetError(
              'the moved source at nevera.js:$line is not as the port reads it: ${m.to}',
            ));
        return [for (var i = 1; i <= g.groupCount; i++) num.parse(g[i]!)];
      }
    }
    throw SheetError('the sheet moves nothing at nevera.js:$line from "$src"');
  }

  /// The new source the sheet's `moves` gives at [line] for the old source that starts with [src].
  String toSource(int line, String src) {
    for (final m in sheet.moves) {
      if (m.line == line && m.src.startsWith(src)) return m.to;
    }
    throw SheetError('the sheet moves nothing at nevera.js:$line from "$src"');
  }

  /// A point on the screen (`points.<name>.screen`).
  List<double> pt(String name) => sheet.screenPoints.containsKey(name)
      ? sheet.screenPoint(name).xy
      : sheet.anchor(name).screen;

  /// The touch box of a thing (`things.<id>.box`).
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
