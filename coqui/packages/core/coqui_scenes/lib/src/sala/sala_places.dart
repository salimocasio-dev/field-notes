import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen La sala's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, frame offset, view, clip or world box"). Nothing here is a
/// number of its own: each comes from the sheet.
///
/// The sheet's rules (`rules.floor`): the room is built round the old picture, so a place on its floor keeps its
/// screen place. A frog's place `q` is the floor point under `(q.x + 16, q.y + 25)`, a person's `(x, y)` the floor
/// point under `(x, y - 1)`: their numbers are the old ones, but for the few the sheet moves (`moves`). The sheet names
/// each with its world point and gives the number the scene uses as its `new` (spots, the `code` entries, remap); the
/// rest of the old file's places are relative to a person, the frog or a point, or are screen effects, and the sheet's
/// `code` says so for each.
class SalaPlaces {
  SalaPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: its projection, and the origin the low table's depth test uses.
  final PpEngine e;

  /// A spot's place today (`spots.<name>.new`): the frog's `q.x, q.y`, or a person's `x, y`.
  List<int> spot(String name) {
    final s =
        sheet.spots[name] ??
        (throw SheetError('the sheet has no spot "$name"'));
    final n = s.now ?? (throw SheetError('spot "$name" has no new place'));
    return [for (final v in n) v.toInt()];
  }

  /// The old `SITIO.<who>` entry (the sheet's `code`, line 75: `{spot, new}`): `[x, y]`, and a `1` after them for one
  /// who sits there.
  List<num> sitio(String who) {
    for (final c in sheet.code) {
      final to = c.to;
      if (c.line == 75 && to is Map && to['spot'] == 'sitio.$who') {
        final n = (to['new'] as List).cast<num>();
        final s = spot('sitio.$who');
        if (n[0] != s[0] || n[1] != s[1]) {
          throw SheetError(
            'code line 75, SITIO.$who: $n, but the spot is at $s',
          );
        }
        return n;
      }
    }
    throw SheetError('the sheet\'s code has no SITIO.$who (line 75)');
  }

  /// A place of the old file that the floor rule keeps (or `moves` moves): the `code` entry of [line] whose old place
  /// is `x, y` ("mueve / x, y [x,y]", or the old call "...(…,x,y)"), its `new`. A place the sheet does not name stops
  /// the scene (SheetError).
  List<int> floor(int line, num x, num y) {
    final key = '[$x,$y]';
    for (final c in sheet.code) {
      final to = c.to;
      if (c.line == line &&
          to is Map &&
          to['new'] is List &&
          (c.old.endsWith(key) || c.old.contains(',$x,$y)'))) {
        return [for (final v in to['new'] as List) (v as num).toInt()];
      }
    }
    throw SheetError(
      'the sheet of sala names no place $key at sala.js:$line (code): stop and ask, do not guess',
    );
  }

  /// The `code` entry of [line] that is an object with [key], its value (the stars over a photo: line 209's `new`).
  Object? codeOf(int line, String key) {
    for (final c in sheet.code) {
      final to = c.to;
      if (c.line == line && to is Map && to.containsKey(key)) return to[key];
    }
    throw SheetError('the sheet\'s code has no "$key" for sala.js:$line');
  }

  /// A point on the screen (`points.<name>.screen`: `x, y`).
  List<double> pt(String name) => sheet.screenPoint(name).xy;

  /// A rectangle on the screen (`points.<name>.screen`: `x, y, w, h`).
  List<double> rect(String name) => sheet.screenPoint(name).rect;

  /// A list of points on the screen (`points.<name>.screen`).
  List<List<double>> pts(String name) =>
      sheet.screenPoint(name).points ??
      (throw SheetError('point "$name" is not a list of points'));

  /// The touch box of a thing (`things.<id>.box`, as the sheet's `code` for lines 82 and 83 gives it).
  List<int> box(String thing) =>
      (sheet.things[thing] ??
              (throw SheetError('the sheet has no thing "$thing"')))
          .box ??
      (throw SheetError('thing "$thing" has no box'));

  /// The screen quad of a clip (`clips.<name>.screen`): a photo is clipped to its frame's opening there.
  List<List<double>> clipScreen(String clip) =>
      (sheet.clips[clip] ?? (throw SheetError('the sheet has no clip "$clip"')))
          .screen;

  /// A view's camera value `[x, y, w, h]` (zoom 1: 196 × 216).
  List<int> view(String name) => sheet.viewOf(name, e);
}
