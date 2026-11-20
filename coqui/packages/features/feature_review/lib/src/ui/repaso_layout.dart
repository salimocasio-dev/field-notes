/// The arithmetic of Repaso's game screens, with no widget in it: how big ¿Dónde?'s pictures are and how many there
/// are. The book's pictures are 196 x 216 picture pixels; a whole number of device pixels goes to each (nothing is
/// smoothed), and the pictures stand one above another.
library;

import 'dart:math' as math;

import 'package:feature_review/src/ui/book_image.dart'
    show bookPictureHeight, bookPictureWidth;

/// Three pictures of ¿Dónde? are shown only when each is at least this wide (logical px); otherwise the item has two.
const double whereMinWidth = 150;

/// The gap between two pictures of a column.
const double whereGap = 12;

/// The largest whole scale (device pixels to a picture pixel) at which [n] book pictures, one above another, [gap]
/// apart, fit in [width] x [height] logical pixels at [dpr]; 0 when not even scale 1 fits.
int whereScaleFor({
  required int n,
  required double width,
  required double height,
  required double dpr,
  double gap = whereGap,
}) {
  final kw = (width * dpr / bookPictureWidth).floor();
  final kh = ((height - (n - 1) * gap) * dpr / (n * bookPictureHeight)).floor();
  return math.max(0, math.min(kw, kh));
}

/// How ¿Dónde?'s pictures are laid out in the game's area, [width] x [height]: [available] pictures (3 or 2) the item
/// has. The pictures are stacked at the largest whole scale at which all of them fit; if three cannot be at least
/// [whereMinWidth] wide each that way, the item uses two (its own and the farthest wrong one). With two, scale 1 at
/// least, whatever the room (the screen then scrolls).
({int count, int k}) planWhere({
  required int available,
  required double width,
  required double height,
  required double dpr,
  double gap = whereGap,
}) {
  if (available >= 3) {
    final k = whereScaleFor(
      n: 3,
      width: width,
      height: height,
      dpr: dpr,
      gap: gap,
    );
    if (k >= 1 && bookPictureWidth * k / dpr >= whereMinWidth) {
      return (count: 3, k: k);
    }
  }
  final n = math.min(available, 2);
  final k = whereScaleFor(
    n: n,
    width: width,
    height: height,
    dpr: dpr,
    gap: gap,
  );
  return (count: n, k: math.max(1, k));
}
