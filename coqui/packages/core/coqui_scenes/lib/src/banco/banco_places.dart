import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El banco's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the corner is built round the old picture, so a place keeps its screen place and
/// its world point is the ground (or the seat, the wire, a bench's back) under it: their numbers are the old ones, but
/// for the places the sheet moves (`moves`, and the story files' own in `remap`). The sheet's maker read banco.js itself:
/// every line that holds a number has its `code` entry, which says what becomes of each (moved, the floor rule, a set
/// thing, dropped, or a number that is no place).
class BancoPlaces {
  BancoPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`).
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  // the moves of a line: those whose piece of source is on it (its `line`, or one of its `lines`)
  Iterable<SheetMove> _movesAt(int line) =>
      sheet.moves.where((m) => m.line == line || m.lines.contains(line));

  // the code entry of a line, which keeps the places on it that no move names (the floor rule, unchanged, a spot, a
  // point or a set thing of the sheet); not a dropped line
  SheetCode? _entry(int line) {
    for (final c in sheet.code) {
      if (c.line != line) continue;
      final to = c.to;
      if (to is Map && to.containsKey('dropped')) return null;
      if (to is String && to.startsWith('dropped')) return null;
      return c;
    }
    return null;
  }

  /// A place of the old file at [line] that the floor rule keeps or `moves` moves:
  /// 1. the sheet's `moves` entry on that line whose old place is `x, y` (its `new`); a move named on several lines (the
  ///    same piece of source) gives its places on the line that lists them;
  /// 2. the `code` entry of that line (the floor rule, or the place unchanged): the same numbers.
  /// A place the sheet does not name stops the scene (SheetError).
  List<int> floor(int line, num x, num y) {
    for (final m in _movesAt(line)) {
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
    if (_entry(line) != null) return [x.toInt(), y.toInt()];
    throw SheetError(
      'the sheet of banco names no place [$x,$y] at banco.js:$line (code, moves): stop and ask, do not guess',
    );
  }

  /// One number of a place at [line] whose other coordinate is relative or moved (`mueve("luis",112,178)` is
  /// [floor]; `x:CARRO[0]+4` is not): kept, as the `code` entry of that line keeps it. SheetError when the line has no
  /// such entry.
  num keep(int line, num v) {
    if (_entry(line) != null) return v;
    throw SheetError(
      'the sheet of banco does not keep the places of banco.js:$line: stop and ask, do not guess',
    );
  }

  static final RegExp _number = RegExp(r'-?\d+(?:\.\d+)?');

  /// The numbers of the new source the sheet's `moves` gives at [line] for the old source [src] (banco-preview.html
  /// replaces the one with the other), in their order: the moved line's own numbers, as the preview runs them. With
  /// [pattern], the numbers its groups catch in the new source.
  List<num> to(int line, String src, [RegExp? pattern]) {
    for (final m in _movesAt(line)) {
      if (m.src == src) {
        if (pattern == null) {
          return [for (final n in _number.allMatches(m.to)) num.parse(n[0]!)];
        }
        final g =
            pattern.firstMatch(m.to) ??
            (throw SheetError(
              'the moved source at banco.js:$line is not as the port reads it: ${m.to}',
            ));
        return [for (var i = 1; i <= g.groupCount; i++) num.parse(g[i]!)];
      }
    }
    throw SheetError('the sheet moves nothing at banco.js:$line from "$src"');
  }

  /// The source a move gives at [line] for [src] (its `to`), as it is.
  String source(int line, String src) {
    for (final m in _movesAt(line)) {
      if (m.src == src) return m.to;
    }
    throw SheetError('the sheet moves nothing at banco.js:$line from "$src"');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`).
  List<double> pt(String name) => sheet.screenPoint(name).xy;

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
