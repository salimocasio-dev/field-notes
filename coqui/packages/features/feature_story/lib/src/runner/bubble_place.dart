/// Where the speech bubble stands over the picture: juego.js's `placeBub`, as a function of numbers.
///
/// The old page measured the bubble's element and the canvas's size and set the bubble's left, top and class. Here the
/// screen measures and calls [placeBubble], and the runner calls it too for `habCubre` (does the turn's bubble cover a
/// person?). Every number is in the stage's own pixels: the picture as it is shown, the top left being its corner.
library;

import 'dart:math' as math;

/// Where the bubble's tail comes from.
enum BubbleSideMode {
  /// Above the point it speaks from, tail down (`#bub.on`).
  above,

  /// To the right of the frog, tail to the left (`#bub.der`).
  right,

  /// To the left of the frog, tail to the right (`#bub.izq`).
  left,
}

/// The place [placeBubble] found.
class BubblePlacement {
  const BubblePlacement({
    required this.left,
    required this.top,
    required this.mode,
    this.maxWidth,
    this.tail,
  });

  /// juego.js `bubEl.style.left` and `.top`: the anchor the bubble's transform is taken from (`translate(-50%, -100%)`
  /// for [BubbleSideMode.above], `translate(0, -50%)` for right, `translate(-100%, -50%)` for left).
  final double left, top;
  final BubbleSideMode mode;

  /// `bubEl.style.maxWidth` (px), when the bubble sits beside the frog; null: the css's 72%.
  final double? maxWidth;

  /// `--tx`: where the tail is along an above bubble, px from its left edge.
  final double? tail;
}

// JavaScript: Math.round
double _round(num v) => (v + 0.5).floorToDouble();

/// The mic button, in the stage's pixels, for a turn's bubble that sits above it (`BUBQ === "mic"`).
class MicAnchor {
  const MicAnchor({
    required this.cx,
    required this.top,
    required this.viewLeft,
    required this.viewRight,
  });

  /// The button's middle x and its top.
  final double cx, top;

  /// The window's left and right edges.
  final double viewLeft, viewRight;
}

/// juego.js: `placeBub` for a bubble that points at the mic button. Null: there is no button to sit above.
BubblePlacement? placeAboveMic(MicAnchor? mic, double bw) {
  if (mic == null) return null;
  final l = math.max(
    bw / 2 + 4 + mic.viewLeft,
    math.min(mic.viewRight - bw / 2 - 4, mic.cx),
  );
  return BubblePlacement(
    left: _round(l),
    top: _round(mic.top - 24),
    mode: BubbleSideMode.above,
    tail: _round(math.max(14, math.min(bw - 14, mic.cx - l + bw / 2))),
  );
}

/// juego.js: `placeBub` for a bubble that points at [at] in the picture (`donde(BUBQ)`), or beside the frog when [who]
/// is "coqui" and there is room. [cam] is the view `[x, y, w, h]`; [cw], [ch] the stage's size; [bw], [bh] the
/// bubble's. [frog] is `frogBox(W.cq)` and [frogDy] `W.cq.dy`. Null: the speaker is not seen (the bubble is hidden).
BubblePlacement? placeBubble({
  required String who,
  required List<num> cam,
  required double cw,
  required double ch,
  required double bw,
  required double bh,
  required ({num x, num y, num w, num h}) frog,
  required num frogDy,
  required List<num>? at,
}) {
  if (at == null) return null;
  double x(num v) => (v - cam[0]) / cam[2] * cw;
  double y(num v) => (v - cam[1]) / cam[3] * ch;
  if (who == 'coqui') {
    // the frog talks from beside himself, so his bubble never hides abuela
    final xr = x(frog.x + frog.w) + 4,
        xl = x(frog.x) - 4,
        yy = y(frog.y + frog.h * .45 + _round(frogDy)),
        rR = cw - xr - 18,
        rL = xl - 18,
        right = rR >= rL,
        room = math.min(right ? rR : rL, cw * .72);
    if (room >= 110) {
      return BubblePlacement(
        left: _round(right ? xr + 12 : xl - 12),
        top: _round(math.max(bh / 2 + 4, math.min(ch - bh / 2 - 4, yy))),
        mode: right ? BubbleSideMode.right : BubbleSideMode.left,
        maxWidth: room.floorToDouble(),
      );
    }
  }
  final ax = x(at[0]), ay = y(at[1]);
  final l = math.max(bw / 2 + 4, math.min(cw - bw / 2 - 4, ax));
  return BubblePlacement(
    left: _round(l),
    top: _round(math.max(bh + 4, ay)),
    mode: BubbleSideMode.above,
    tail: _round(math.max(14, math.min(bw - 14, ax - l + bw / 2))),
  );
}

/// What the screen measures for the runner (juego.js read these from the page's elements): the stage's size, the
/// speech bubble's size, and where the mic button is. Asked when a turn decides where its bubble sits.
class BubbleMetrics {
  const BubbleMetrics({
    required this.cw,
    required this.ch,
    required this.bw,
    required this.bh,
    this.mic,
  });

  final double cw, ch, bw, bh;
  final MicAnchor? mic;
}
