import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/sprite.dart';

/// The camera of page 12, section 5, as the orchestrator corrected it on Nov 19.
///
/// The old game drew a 240 × 216 picture and stretched a view rectangle of it to 196 × 216, by amounts that were not
/// whole numbers; page 11-pixel-engine, decision 3, forbids that. The old views were the 196 × 216 window (1×) or a
/// 98 × 108 rectangle (exactly 2×); the one fractional view (1.085×) is 1× now. So:
///
/// - A view is a centre (a screen point on the picture) and a `zoom` of 1 or 2. No other zoom exists: a fractional
///   scale is never drawn, not even for one frame.
/// - Zoom 1: the 196 × 216 window centred on the point, kept inside the picture. Zoom 2: a 98 × 108 region centred on
///   it, kept inside the picture, each picture pixel drawn as a 2 × 2 block: 196 × 216 again.
/// - The camera value the game keeps is the old `cam`, `[x, y, w, h]`: the top-left of the region of the picture the
///   view shows (whole pixels) and its size, 196 × 216 or 98 × 108. So `zoom = 196 / cam[2]`, as in juego.js.
///
/// Every function here takes plain values (a screen point, a size, a list of pixels), not a sheet.

/// The size of the display picture (juego.js: `DW`, `DH`).
const int displayW = 196, displayH = 216;

/// The size of a scene's picture (kit.js: `SW`, `SH`).
const int pictureW = 240, pictureH = 216;

/// The size of a review or level-check picture: 196 wide, 104 high.
const int reviewW = 196, reviewH = 104;

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// A [size]-wide piece of a [pic]-wide line, centred on [c], in whole pixels, kept inside the line. A piece wider than
/// the line starts at 0.
int _centred(num c, int size, int pic) {
  final at = _round(c - size / 2);
  return math.max(0, math.min(at, pic - size));
}

void _checkZoom(int zoom) {
  if (zoom != 1 && zoom != 2) {
    throw ArgumentError.value(zoom, 'zoom', 'a view has zoom 1 or 2');
  }
}

/// The view centred on the screen point ([cx], [cy]) at [zoom] (1 or 2), kept inside the picture: the camera value
/// `[x, y, w, h]`, all whole numbers. Zoom 1: 196 × 216. Zoom 2: 98 × 108.
List<int> viewAt(
  num cx,
  num cy,
  int zoom, {
  int picW = pictureW,
  int picH = pictureH,
}) {
  _checkZoom(zoom);
  final w = displayW ~/ zoom, h = displayH ~/ zoom;
  return [_centred(cx, w, picW), _centred(cy, h, picH), w, h];
}

/// The zoom of a camera value: 1 for a 196-wide view, 2 for a 98-wide one. Throws for any other: a fractional scale is
/// never drawn.
int zoomOf(List<num> cam) {
  final w = cam[2], h = cam[3];
  if (w == displayW && h == displayH) return 1;
  if (w == displayW ~/ 2 && h == displayH ~/ 2) return 2;
  throw ArgumentError('a view is 196 x 216 or 98 x 108, not $w x $h');
}

/// Picture point to display point: where the view shows the picture's point ([x], [y]) on the 196 × 216 display
/// picture (juego.js: `(p[0] - cam[0]) * z`, with `z = DW / cam[2]`; the hand sign and what the old code places
/// through the view). A whole picture pixel gives the top-left display pixel of its block.
({double x, double y}) pictureToDisplay(List<num> cam, num x, num y) {
  final z = zoomOf(cam);
  return (x: ((x - cam[0]) * z).toDouble(), y: ((y - cam[1]) * z).toDouble());
}

/// Display point to picture point: what a tap on the display picture at ([x], [y]) touches in the picture (the inverse
/// of [pictureToDisplay]). A display pixel gives the picture pixel its block belongs to once its coordinates are cut
/// to whole numbers (`floor`).
({double x, double y}) displayToPicture(List<num> cam, num x, num y) {
  final z = zoomOf(cam);
  return (x: cam[0] + x / z, y: cam[1] + y / z);
}

// juego.js: at
/// Whether the view is at [target] (juego.js: `at(k)`, every number within a half).
bool atView(List<num> cam, List<num> target) {
  for (var i = 0; i < 4; i++) {
    if (!((target[i] - cam[i]).abs() < .5)) return false;
  }
  return true;
}

// juego.js: camGo, and its step in draw
/// A move of the view from one place to another (juego.js: `camGo(k, n)` makes `camA = {a, b, f0, n}`; `draw` moves the
/// view by it). It takes the old number of frames: [n] from frame [f0] (9 when null or 0), done when `t = (F - f0) / n`
/// reaches 1, so a story's timing and its recorded run do not change.
///
/// - Between two views of the same zoom it is a slide, in whole picture pixels: the old ease `t * t * (3 - 2 * t)`, x
///   and y rounded, and at the end exactly [to].
/// - Between views of different zoom it is a cut: the camera is at [to] from the first step. It still lasts the same
///   [n] frames.
class CamSlide {
  CamSlide({
    required List<num> from,
    required List<num> to,
    required this.f0,
    int? n,
  }) : from = List<int>.of([for (final v in from) _round(v)]),
       to = List<int>.of([for (final v in to) _round(v)]),
       n = (n == null || n == 0) ? 9 : n {
    zoomOf(this.from);
    zoomOf(this.to);
  }

  /// The view it starts from and the one it ends on, `[x, y, w, h]`.
  final List<int> from, to;

  /// The frame it began on and how many frames it takes.
  final int f0, n;

  /// A cut: the two views are not of the same zoom.
  bool get cut => from[2] != to[2];

  /// The camera at frame [F], `[x, y, w, h]`, and `done` when the move is over, so the camera is exactly [to] and
  /// whoever waits for it goes on (juego.js: `if(t>=1){cam=camA.b.slice();...res();}`).
  ({List<int> cam, bool done}) at(int F) {
    final t = math.min(1.0, (F - f0) / n), e = t * t * (3 - 2 * t);
    if (t >= 1 || cut) return (cam: List<int>.of(to), done: t >= 1);
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

  /// The cameras of frames `f0 + 1` to `f0 + n`: the ones the move goes through, the last one exactly [to].
  List<List<int>> steps() => [for (var k = 1; k <= n; k++) at(f0 + k).cam];
}

/// Where a review or level-check picture looks (decided Nov 19: a whole-number crop, `zoom` 1 or 2): the region of the
/// picture to copy, `x`, `y`, `w`, `h`. Zoom 1: the 196 × 104 window centred on ([cx], [cy]). Zoom 2: a 98 × 52 region
/// centred on it. Either way kept inside the picture, in whole pixels. It is the rule of [viewAt] with a display 104
/// high.
({int x, int y, int w, int h}) reviewRegion(
  num cx,
  num cy,
  int zoom, {
  int picW = pictureW,
  int picH = pictureH,
}) {
  _checkZoom(zoom);
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
