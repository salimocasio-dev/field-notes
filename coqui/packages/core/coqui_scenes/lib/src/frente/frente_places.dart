import 'package:coqui_pixel/coqui_pixel.dart';

/// Every place on the screen El frente's scene uses, read from its sheet once (page 12, section 5: "every screen
/// position in the old file is replaced by the sheet's spot, point, frame offset, view, clip or world box"). Nothing
/// here is a number of its own: each comes from the sheet, projected by the engine where the sheet gives a world point.
///
/// The sheet's rules (`rules`): a spot is the ground under the feet (the frog's box at `round(sx) - 16`,
/// `round(sy) - 25`; abuela's sprite at `round(sx) - 30`, `round(sy) - 49`); a point named with a frame is the old point
/// plus the frame's offset, a whole number of pixels; what is drawn relative to an old point moves by the same offset.
class FrentePlaces {
  FrentePlaces(this.sheet, this.e);

  final Sheet sheet;

  /// An engine with the set's settings: only its projection is used here.
  final PpEngine e;

  /// The offset of a translation frame (`frames.<name>.offset`): [dx, dy].
  List<int> off(String frame) =>
      (sheet.frames[frame] ??
              (throw SheetError('the sheet has no frame "$frame"')))
          .offset;

  /// An old point moved by a frame's offset (the sheet's rule `frame`).
  List<num> via(String frame, num x, num y) {
    final o = off(frame);
    return [x + o[0], y + o[1]];
  }

  /// A named point (`points.<name>`) on the screen. A point made through a frame is whole pixels, as the sheet records
  /// it; a point whose recorded screen is not where its world point projects (the sheet placed it on the screen, as
  /// `cq.asoma`) is where the sheet records it; any other is the engine's projection of its world point.
  List<num> pt(String name) {
    final a =
        sheet.points[name] ??
        (throw SheetError('the sheet has no point "$name"'));
    if (a.frame != null) return a.screen;
    final p = sheet.screenOf(name, e);
    if ((p.x - a.screen[0]).abs() > .01 || (p.y - a.screen[1]).abs() > .01) {
      return a.screen;
    }
    return [p.x, p.y];
  }

  /// A point rounded to whole pixels, as the sheet's `code` gives the hand's points (`handAt`).
  List<int> ptRound(String name) {
    final p = pt(name);
    return [(p[0] + .5).floor(), (p[1] + .5).floor()];
  }

  /// The frog at a spot: his `x`, `y` (the old `q.x`, `q.y`) and his size there.
  ({int x, int y, num scale}) frog(String spot) => sheet.frogAt(spot, e);

  /// Where abuela's sprite is drawn at a spot (its top left).
  List<int> abuela(String spot) {
    final a = sheet.abuelaAt(spot, e);
    return [a.x, a.y];
  }

  /// The touch box of a thing in the set (from its world box: `Sheet.boxOf`), and the box its touch hits.
  List<int> box(String thing) => sheet.boxOf(thing, e);
  List<int> hitBox(String thing) => sheet.hitBoxOf(thing, e)!;

  /// The screen box of a clip's polygon.
  List<int> clipBox(String clip) =>
      Sheet.boxOfPoints(sheet.clipPolygon(clip, e));

  /// The world polygon of a clip, for `clipToWorld`.
  List<List<num>> clipWorld(String clip) =>
      (sheet.clips[clip] ?? (throw SheetError('the sheet has no clip "$clip"')))
          .world;

  /// A view's camera value `[x, y, w, h]` (zoom 1: 196 × 216; zoom 2: 98 × 108).
  List<int> view(String name) => sheet.viewOf(name, e);
}
