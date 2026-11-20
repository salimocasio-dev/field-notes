import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El balcón's scene uses, read from its sheet once (page 12, section 5: "every screen position
/// in the old file is replaced by the sheet's spot, point, frame offset, view, clip or world box"). Nothing here is a
/// number of its own: each comes from the sheet, projected by the engine where the sheet gives a world point.
///
/// The sheet's rules (`rules`): a frog's spot is the ground under his feet (his box at `round(sx) - 16`,
/// `round(sy) - 25`); abuela standing is at `ab.x = round(sx)`, `ab.y = round(sy) + 1` of her spot (balcon.js draws her
/// at `ab.x - 30`, `ab.y - 50`); a point the old code used as whole pixels (`X2`, `ABS`, `PERCH`, `ASIENTO`, the hands)
/// is its screen position rounded, as balcon-preview.html's `ptR` takes it.
class BalconPlaces {
  BalconPlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: only its projection is used here.
  final PpEngine e;

  /// A named point (`points.<name>`) on the screen: the engine's projection of its world point, or, where the sheet
  /// recorded a screen position that is not that projection (it placed the point on the screen: `ABS`, a sprite's top
  /// left), the recorded one.
  List<num> pt(String name) {
    final a =
        sheet.points[name] ??
        (throw SheetError('the sheet has no point "$name"'));
    final p = sheet.screenOf(name, e);
    if ((p.x - a.screen[0]).abs() > .01 || (p.y - a.screen[1]).abs() > .01) {
      return a.screen;
    }
    return [p.x, p.y];
  }

  /// A point rounded to whole pixels (balcon-preview.html: `ptR`).
  List<int> ptRound(String name) {
    final p = pt(name);
    return [(p[0] + .5).floor(), (p[1] + .5).floor()];
  }

  /// The frog at a spot: his `x`, `y` (the old `q.x`, `q.y`) and his size there.
  ({int x, int y, num scale}) frog(String spot) => sheet.frogAt(spot, e);

  /// Abuela standing at a spot: `ab.x`, `ab.y` (the sheet's rule `abuela`), which the sheet records as the spot's `ab`.
  List<int> abuela(String spot) {
    final p = sheet.screenOf(spot, e),
        ab = [(p.x + .5).floor(), (p.y + .5).floor() + 1],
        rec = sheet.spots[spot]!.ab;
    if (rec == null || rec[0] != ab[0] || rec[1] != ab[1]) {
      throw SheetError(
        'spot "$spot": abuela at $ab by the rule, but the sheet records ${rec ?? 'no ab'}',
      );
    }
    return ab;
  }

  /// The touch box of a thing in the set (from its world box: `Sheet.boxOf`).
  List<int> box(String thing) => sheet.boxOf(thing, e);

  /// The world polygon of a clip, for `clipToWorld`.
  List<List<num>> clipWorld(String clip) =>
      (sheet.clips[clip] ?? (throw SheetError('the sheet has no clip "$clip"')))
          .world;

  /// A view's camera value `[x, y, w, h]` (zoom 1: 196 × 216).
  List<int> view(String name) => sheet.viewOf(name, e);

  /// One of the old file's numbers the sheet gives today's value of (`MESA_Y`, `behind`).
  int number(String name) {
    final n = sheet.numberOf(name);
    if (n != n.truncate()) {
      throw SheetError('the sheet\'s $name is $n, not a whole row');
    }
    return n.toInt();
  }
}
