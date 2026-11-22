import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen A comer's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, view or world box"). Nothing here is a number of its own: each
/// comes from the sheet, or is checked against it.
///
/// The sheet's rules (`rules.layout`): every place at the table steps down half a row a pixel to the right round column
/// 118 (`SY`, moves line 21); every other place keeps its screen point if what stands there stands on what it stood on,
/// else it moves the least distance that does (`moves`, `remap`). The sheet names each line of comer.js that holds
/// numbers (`code`: 831 entries, each line's numbers by kind), so a number the rule keeps is checked to be one the sheet
/// names at its line ([at]), and a moved one is read from the moved source itself ([named], [to]). The moved pieces of
/// source that are code (the new geometry's functions, `CARTAS`, `LIBRE`, `atras`, `HOPAT`, the moved walks) are ported
/// as they read; [movesAre] checks at the scene's start that the sheet's moves are the ones they were ported from.
class ComerPlaces {
  ComerPlaces(this.sheet, this.e);

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

  // the code entry of comer.js's line [line]
  SheetCode _code(int line) {
    for (final c in sheet.code) {
      if (c.line == line) return c;
    }
    throw SheetError(
      'the sheet of comer has no code entry for comer.js:$line: stop and ask, do not guess',
    );
  }

  // whether the code entry keeps the numbers of its line it does not move: "unchanged", the rule (`to.rule`), the set's
  // things, points, spots or view (their numbers unchanged), or a moved line whose other places keep their screen point
  static bool _keeps(SheetCode c) {
    final to = c.to;
    return to == 'unchanged' ||
        (to is Map && to['rule'] == true) ||
        (to is Map &&
            (to['spots'] != null ||
                to['points'] != null ||
                to['things'] != null ||
                to['view'] != null)) ||
        (c.note ?? '').contains('every other place here keeps its screen point');
  }

  /// A number of comer.js's line [line] that the sheet keeps (the rule, unchanged): it must be one of the numbers the
  /// sheet's `code` entry of that line names (any kind: a place, an offset, a count). A number the sheet does not name at
  /// that line stops the scene (SheetError).
  num at(int line, num v) {
    final c = _code(line);
    if (!_keeps(c)) {
      throw SheetError(
        'comer.js:$line: the sheet does not keep its numbers (${c.to}): stop and ask, do not guess',
      );
    }
    final nums = c.raw['numbers'];
    final s = jsNum(v);
    if (nums is Map) {
      for (final l in nums.values) {
        if (l is List && (l.contains(s) || l.contains(_short(s)))) return v;
      }
    }
    throw SheetError(
      'the sheet of comer names no number $s at comer.js:$line (code): stop and ask, do not guess',
    );
  }

  // "0.5" as comer.js writes it: ".5"
  static String _short(String s) => s.startsWith('0.')
      ? s.substring(1)
      : s.startsWith('-0.')
      ? '-${s.substring(2)}'
      : s;

  // the moves of a line: those whose piece of source is on it (its `line`, or one of its `lines`)
  Iterable<SheetMove> _movesAt(int line) =>
      sheet.moves.where((m) => m.line == line || m.lines.contains(line));

  /// The new source the sheet's `moves` gives at [line] for the old source that starts with [src].
  String source(int line, String src) {
    for (final m in _movesAt(line)) {
      if (m.src.startsWith(src)) return m.to;
    }
    throw SheetError('the sheet moves nothing at comer.js:$line from "$src"');
  }

  /// The numbers [pattern]'s groups catch in the new source the sheet's `moves` gives at [line] for the old source that
  /// starts with [src].
  List<num> to(int line, String src, RegExp pattern) {
    final t = source(line, src);
    final g =
        pattern.firstMatch(t) ??
        (throw SheetError(
          'the moved source at comer.js:$line is not as the port reads it: $t',
        ));
    return [for (var i = 1; i <= g.groupCount; i++) num.parse(g[i]!)];
  }

  /// A place the moved source at [line] names (`NAME=[x,y]`).
  List<int> named(int line, String name) {
    for (final m in _movesAt(line)) {
      final g = RegExp(
        '(?<![A-Za-z0-9_])$name=\\[(-?\\d+),(-?\\d+)\\]',
      ).firstMatch(m.to);
      if (g != null) return [int.parse(g[1]!), int.parse(g[2]!)];
    }
    throw SheetError('the sheet moves no place $name at comer.js:$line');
  }

  /// A number the moved source at [line] names (`NAME=v`).
  num namedNum(int line, String name) {
    for (final m in _movesAt(line)) {
      final g = RegExp(
        '(?<![A-Za-z0-9_])$name=(-?\\d+(?:\\.\\d+)?)(?![\\d.])',
      ).firstMatch(m.to);
      if (g != null) return num.parse(g[1]!);
    }
    throw SheetError('the sheet moves no number $name at comer.js:$line');
  }

  /// The hash of every move's line, old and new source (FNV-1a, 32 bits): what the moved code of the port was written
  /// from. [movesAre] fails when the sheet's moves are not those.
  int get movesHash {
    var h = 0x811C9DC5;
    for (final m in sheet.moves) {
      for (final u in '${m.line}\u0000${m.src}\u0000${m.to}\u0001'.codeUnits) {
        h ^= u;
        h = (h * 0x01000193) & 0xFFFFFFFF;
      }
    }
    return h;
  }

  /// Stops the scene (SheetError) when the sheet's moves are not the ones the port's moved code was written from.
  void movesAre(int hash) {
    if (movesHash != hash) {
      throw SheetError(
        'the sheet of comer moves other pieces of comer.js than the port was written from '
        '(hash ${movesHash.toRadixString(16)}, the port\'s ${hash.toRadixString(16)}): port the new moves',
      );
    }
  }

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
