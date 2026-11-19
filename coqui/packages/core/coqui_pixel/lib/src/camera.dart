import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/sprite.dart';

/// The camera of page 12, section 5. The old game drew a 240 × 216 picture and stretched a view rectangle of it to
/// 196 × 216 by amounts that were not whole numbers; page 11-pixel-engine, decision 3, forbids that. So a view never
/// zooms: it is a 196 × 216 window that slides over the 240 × 216 picture, in whole pixels.
///
/// Every function here takes plain values (a screen point, a size, a list of pixels), not a sheet.

/// The size of the display picture, the window (juego.js: `DW`, `DH`).
const int windowW = 196, windowH = 216;

/// The size of a scene's picture (kit.js: `SW`, `SH`).
const int pictureW = 240, pictureH = 216;

/// The size of a review or level-check picture: the 196-wide window, 104 high.
const int reviewW = 196, reviewH = 104;

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// A [size]-wide piece of a [pic]-wide line, centred on [c], in whole pixels, kept inside the line. A piece wider than
/// the line starts at 0.
int _centred(num c, int size, int pic) {
  final at = _round(c - size / 2);
  return math.max(0, math.min(at, pic - size));
}

/// The window centred on the screen point ([cx], [cy]) and kept inside the picture: `[x, y, w, h]`, all whole numbers
/// (page 12, section 5: "A view's place"). The size is the window's, 196 × 216, whatever the point.
List<int> viewAt(
  num cx,
  num cy, {
  int picW = pictureW,
  int picH = pictureH,
  int winW = windowW,
  int winH = windowH,
}) => [_centred(cx, winW, picW), _centred(cy, winH, picH), winW, winH];

// juego.js: at
/// Whether the view is at [target] (juego.js: `at(k)`, every number within a half).
bool atView(List<num> cam, List<num> target) {
  for (var i = 0; i < 4; i++) {
    if (!((target[i] - cam[i]).abs() < .5)) return false;
  }
  return true;
}

// juego.js: camGo, and its step in draw
/// A slide of the window from one place to another (juego.js: `camGo(k, n)` makes `camA = {a, b, f0, n}`; `draw` moves
/// the view by it). The old slide's timing and easing are kept: [n] frames (9 when null or 0) from frame [f0], the
/// ease `t * t * (3 - 2 * t)` of `t = (F - f0) / n`. What changes is that the window keeps its size and sits on whole
/// pixels: x and y are rounded, and at the end the window is exactly [to].
class CamSlide {
  CamSlide({
    required List<num> from,
    required List<num> to,
    required this.f0,
    int? n,
  }) : from = List<int>.of([for (final v in from) _round(v)]),
       to = List<int>.of([for (final v in to) _round(v)]),
       n = (n == null || n == 0) ? 9 : n;

  /// The window it starts from and the one it ends on, `[x, y, w, h]`.
  final List<int> from, to;

  /// The frame it began on and how many frames it takes.
  final int f0, n;

  /// The window at frame [F]: `[x, y, w, h]` (the size of [from]), and `done` when the slide is over, so the window
  /// is exactly [to] and whoever waits for the slide goes on (juego.js: `if(t>=1){cam=camA.b.slice();...res();}`).
  ({List<int> cam, bool done}) at(int F) {
    final t = math.min(1.0, (F - f0) / n), e = t * t * (3 - 2 * t);
    if (t >= 1) return (cam: [to[0], to[1], from[2], from[3]], done: true);
    return (
      cam: [
        _round(from[0] + (to[0] - from[0]) * e),
        _round(from[1] + (to[1] - from[1]) * e),
        from[2],
        from[3],
      ],
      done: false,
    );
  }

  /// The windows of frames `f0 + 1` to `f0 + n`: the ones the slide goes through, the last one exactly [to].
  List<List<int>> steps() => [for (var k = 1; k <= n; k++) at(f0 + k).cam];
}

/// Where a review or level-check picture looks (decided Nov 19: a whole-number crop, `zoom` 1 or 2): the region of the
/// picture to copy, `x`, `y`, `w`, `h`. Zoom 1: the 196 × 104 window centred on ([cx], [cy]). Zoom 2: a 98 × 52 region
/// centred on it. Either way kept inside the picture, in whole pixels. No other zoom exists.
({int x, int y, int w, int h}) reviewRegion(
  num cx,
  num cy,
  int zoom, {
  int picW = pictureW,
  int picH = pictureH,
}) {
  if (zoom != 1 && zoom != 2) {
    throw ArgumentError.value(zoom, 'zoom', 'a review crop has zoom 1 or 2');
  }
  final w = reviewW ~/ zoom, h = reviewH ~/ zoom;
  return (x: _centred(cx, w, picW), y: _centred(cy, h, picH), w: w, h: h);
}

/// A review or level-check picture: 196 × 104, the region [reviewRegion] names copied out of [picture]
/// (`picW` × `picH`), each pixel drawn 1 × 1 at zoom 1 and 2 × 2 at zoom 2. No stretch.
Sprite reviewCrop(
  Uint32List picture,
  int picW,
  int picH,
  num cx,
  num cy,
  int zoom,
) {
  final r = reviewRegion(cx, cy, zoom, picW: picW, picH: picH);
  final out = Uint32List(reviewW * reviewH);
  for (var j = 0; j < reviewH; j++) {
    final sy = r.y + j ~/ zoom;
    for (var i = 0; i < reviewW; i++) {
      final sx = r.x + i ~/ zoom;
      out[j * reviewW + i] = (sx < picW && sy < picH)
          ? picture[sy * picW + sx]
          : 0;
    }
  }
  return Sprite(reviewW, reviewH, out);
}
