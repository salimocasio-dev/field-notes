/// Where the pictures of a Repaso ask or a level-check item go, and how big: the layout arithmetic of the old page,
/// ported by reading and checked against the old code's own functions run in Node (test/layout_test.dart):
/// juego.js `fit` (the whole-number scale, the room under the block), cual.js `gapFor`, `cualSize` (blockDim,
/// blockFit), `placeOpts` (where each frame sits) and `cualGrid` (the end screen's grid).
library;

import 'dart:math' as math;

/// cual.js: DW, PH: the width and height of a picture in art pixels.
const int pictureWidth = 196;
const int pictureHeight = 104;

/// cual.js: cualSize(cols, rows, pw, ph): a block of cols x rows pictures of pw x ph art pixels.
class BlockSpec {
  const BlockSpec(this.cols, this.rows, this.pw, this.ph);
  final int cols;
  final int rows;
  final int pw;
  final int ph;

  /// Repaso: two pictures, one above the other.
  static const review = BlockSpec(1, 2, pictureWidth, pictureHeight);

  /// The level check: four pictures, two by two (nivel.js: CW, CH).
  static const level = BlockSpec(2, 2, 96, 106);
}

/// A frame's place: kept as the page gives it (a Flutter Rect keeps the right and bottom edges, so its width
/// and height can come out one bit off).
class CellRect {
  const CellRect(this.left, this.top, this.width, this.height);
  final double left;
  final double top;
  final double width;
  final double height;
}

class BlockFit {
  BlockFit({
    required this.scale,
    required this.gap,
    required this.width,
    required this.height,
    required this.marginBottom,
    required this.cells,
  });

  /// kd: device pixels to an art pixel, a whole number.
  final int scale;

  /// GAP: art pixels between two pictures.
  final int gap;

  /// The block's size in CSS px.
  final double width;
  final double height;

  /// What the stage's `margin-bottom` is (portrait): the block moves up when the caption would not fit under it.
  final double marginBottom;

  /// Each picture's frame, in CSS px from the block's top left.
  final List<CellRect> cells;
}

// cual.js: gapFor: the art pixels between them: set from the scale so that the gap on screen is at least 22 CSS px
int gapFor(int kd, double dpr) => (22 * dpr / kd).ceil();

/// juego.js: fit(), for a block of [spec].
///
/// [mainWidth] and [mainHeight]: portrait: the size of `#main` (the screen less the top bar and the safe area);
/// on its side: the size of the page less its padding. [landscape]: the page's own media query
/// `(orientation:landscape) and (max-height:600px)`.
BlockFit fitBlock(
  BlockSpec spec, {
  required double dpr,
  required double mainWidth,
  required double mainHeight,
  required bool landscape,
}) {
  final mw = mainWidth;
  final mh = mainHeight;
  final z = mh - 112; // the room above the bottom zone (the start disc and the 40 px under it)
  final double aw;
  final double ah;
  if (landscape) {
    // 16 px left of the picture, 16 between it and a column of at least 240, 16 right of that, 16 above and below
    aw = mw - 16 - 16 - 240 - 16;
    ah = mh - 32;
  } else {
    // 16 px side margins; above and below the picture there stays room for the caption (8 + two lines)
    aw = mw - 32;
    ah = z - 64;
  }
  List<double> dim(int kd) {
    final g = gapFor(kd, dpr);
    return [
      (spec.cols * spec.pw + (spec.cols - 1) * g) * kd / dpr,
      (spec.rows * spec.ph + (spec.rows - 1) * g) * kd / dpr,
    ];
  }

  var kd = 1;
  for (var k = 2; k <= 32; k++) {
    final d = dim(k);
    if (d[0] <= aw + .01 && d[1] <= ah + .01) {
      kd = k;
    } else {
      break;
    }
  }
  final d = dim(kd);
  final gap = gapFor(kd, dpr);
  // cual.js: placeOpts
  final zoom = kd / dpr;
  final cells = [
    for (var k = 0; k < spec.cols * spec.rows; k++)
      CellRect(
        (k % spec.cols) * (spec.pw + gap) * zoom,
        (k ~/ spec.cols) * (spec.ph + gap) * zoom,
        spec.pw * zoom,
        spec.ph * zoom,
      ),
  ];
  return BlockFit(
    scale: kd,
    gap: gap,
    width: d[0],
    height: d[1],
    marginBottom: landscape ? 0 : math.max(0, d[1] + 112 - z),
    cells: cells,
  );
}

/// cual.js: cualGrid: the end screen's grid: three or two to a row at the largest whole scale that fits, 16 px
/// apart; a picture is at most about 140 px wide.
class EndGrid {
  EndGrid({required this.columns, required this.scale, required this.dpr});
  final int columns;

  /// kd
  final int scale;
  final double dpr;

  /// `--pw`: a cell is as wide as its picture.
  double get cellWidth => pictureWidth * scale / dpr;

  /// A picture's height in CSS px.
  double get pictureHeightCss => pictureHeight * scale / dpr;

  /// `--gw`: the grid is one centred block this wide; the title and the lines above it are as wide as it.
  double get width => columns * cellWidth + (columns - 1) * 16;
}

/// [clientWidth]: the width of the end screen's box; [padding]: its left and right padding together.
EndGrid endGridFor({
  required double clientWidth,
  required double padding,
  required double dpr,
}) {
  final w = math.min(480, clientWidth - padding);
  int? bestN;
  var bestKd = 0;
  final top = math.max(1, (140 * dpr / pictureWidth + .001).floor());
  for (final n in [3, 2]) {
    final kd = math.min(top, (((w - (n - 1) * 16) / n) * dpr / pictureWidth + .001).floor());
    if (kd >= 1 && (bestN == null || kd > bestKd)) {
      bestN = n;
      bestKd = kd;
    }
  }
  // a screen too narrow or too low in density for two: one to a row
  return EndGrid(columns: bestN ?? 1, scale: bestN == null ? 1 : bestKd, dpr: dpr);
}
