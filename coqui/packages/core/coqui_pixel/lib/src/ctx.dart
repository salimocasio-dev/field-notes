import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/sprite.dart';

/// What `save` keeps and `restore` brings back: the canvas's drawing state.
class _Saved {
  _Saved({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.f,
    required this.globalAlpha,
    required this.fillStyle,
    required this.strokeStyle,
    required this.lineWidth,
    required this.smoothing,
    required this.clipX0,
    required this.clipY0,
    required this.clipX1,
    required this.clipY1,
    required this.mask,
  });

  final double a, b, c, d, e, f;
  final double globalAlpha, lineWidth;
  final int fillStyle, strokeStyle;
  final bool smoothing;
  final int clipX0, clipY0, clipX1, clipY1;
  final Uint8List? mask;
}

/// A sub-path, its points already in picture coordinates (the canvas transforms a path's points when they are added).
class _Sub {
  final List<double> pts = [];
  bool closed = false;
}

/// How many of the 16 sample points of each pixel a shape covers, over the box `x0, y0, w, h`.
class _Cov {
  _Cov(this.x0, this.y0, this.w, this.h) : n = Uint8List(w * h);

  final int x0, y0, w, h;
  final Uint8List n;
}

const double _twoPi = 2 * math.pi;

/// The software canvas the sprite layer draws with. Same operations and meaning as the browser's 2D canvas,
/// writing into a picture. Images are sampled nearest-neighbour unless `smoothing` is on (the old code turns
/// it on in three places in sala.js; nowhere else).
///
/// Decided Nov 19: the old scene canvas smoothed by default, so sprites at fractional positions were blurred. The
/// new one does not: an unscaled, unrotated drawImage lands on its position rounded to a whole pixel,
/// `(x + 0.5).floor()`. That rule holds while `smoothing` is off; with `smoothing` on the sprite is drawn where
/// it is told, bilinear.
///
/// The picture is `target`, `w` × `h` pixels of `0xAABBGGRR` (straight alpha). A colour is that int.
///
/// - A transform stack: a 2 × 3 matrix, `translate`, `scale`, `rotate`, `save`, `restore`.
/// - Alpha blending in 0 to 255 steps: `source-over`, with `globalAlpha` and the colour's own alpha.
/// - `fillRect`, `clearRect`: a rectangle under the transform, an edge that falls inside a pixel covers that
///   fraction of it (a whole-number rectangle is exact).
/// - `drawImage`, `drawImageRect`: by inverse mapping, the pixel's centre taken back into the sprite, nearest
///   neighbour (bilinear, with a soft edge, when `smoothing` is on).
/// - `arc`, `ellipse`, `rect`, `moveTo`, `lineTo` build a path; `fill` and `stroke` draw it by scanline, 4 × 4
///   samples a pixel; `clip` keeps a stack of rectangles (whole-pixel rectangles) and one path mask (anything else).
class Ctx {
  Ctx(Uint32List target, int w, int h)
    : _t = target,
      _w = w,
      _h = h,
      _clipX1 = w,
      _clipY1 = h {
    if (target.length != w * h) {
      throw ArgumentError(
        'a picture of $w x $h has ${w * h} pixels, not ${target.length}',
      );
    }
  }

  // DECISION(order 02): the starting values are the browser canvas's (alpha 1, black, line width 1),
  // except `smoothing`, off as the sentence above says.
  double globalAlpha = 1;
  int fillStyle = 0xFF000000;
  int strokeStyle = 0xFF000000;
  double lineWidth = 1;
  bool smoothing = false;

  final Uint32List _t;
  final int _w, _h;

  // the transform: x' = a x + c y + e, y' = b x + d y + f
  double _a = 1, _b = 0, _c = 0, _d = 1, _e = 0, _f = 0;

  // the clip: a rectangle of whole pixels, and a coverage mask (0 to 255 a pixel) or none
  int _clipX0 = 0, _clipY0 = 0;
  int _clipX1, _clipY1;
  Uint8List? _mask;

  final List<_Saved> _stack = [];
  List<_Sub> _path = [];

  // ---- state ----

  void save() {
    _stack.add(
      _Saved(
        a: _a,
        b: _b,
        c: _c,
        d: _d,
        e: _e,
        f: _f,
        globalAlpha: globalAlpha,
        fillStyle: fillStyle,
        strokeStyle: strokeStyle,
        lineWidth: lineWidth,
        smoothing: smoothing,
        clipX0: _clipX0,
        clipY0: _clipY0,
        clipX1: _clipX1,
        clipY1: _clipY1,
        mask: _mask,
      ),
    );
  }

  void restore() {
    if (_stack.isEmpty) return;
    final s = _stack.removeLast();
    _a = s.a;
    _b = s.b;
    _c = s.c;
    _d = s.d;
    _e = s.e;
    _f = s.f;
    globalAlpha = s.globalAlpha;
    fillStyle = s.fillStyle;
    strokeStyle = s.strokeStyle;
    lineWidth = s.lineWidth;
    smoothing = s.smoothing;
    _clipX0 = s.clipX0;
    _clipY0 = s.clipY0;
    _clipX1 = s.clipX1;
    _clipY1 = s.clipY1;
    _mask = s.mask;
  }

  void translate(double x, double y) {
    _e += _a * x + _c * y;
    _f += _b * x + _d * y;
  }

  void scale(double x, double y) {
    _a *= x;
    _b *= x;
    _c *= y;
    _d *= y;
  }

  void rotate(double a) {
    final cs = math.cos(a), sn = math.sin(a);
    final na = _a * cs + _c * sn, nb = _b * cs + _d * sn;
    final nc = -_a * sn + _c * cs, nd = -_b * sn + _d * cs;
    _a = na;
    _b = nb;
    _c = nc;
    _d = nd;
  }

  // ---- blending ----

  /// The paint's alpha, 0 to 255: the colour's own alpha times `globalAlpha`.
  int _paintAlpha(int alpha8) {
    final g = globalAlpha;
    final ga = g >= 1 ? 1.0 : (g > 0 ? g : 0.0);
    return (alpha8 * ga + 0.5).floor();
  }

  /// `a * b / 255`, rounded.
  static int _mulDiv255(int a, int b) {
    final p = a * b + 128;
    return (p + (p >> 8)) >> 8;
  }

  /// One pixel of a shape: `color`'s rgb at the paint alpha `pa` (0 to 255), over `cover` of the pixel (1 to 255,
  /// 255 all of it), through the clip's mask. `source-over` in 8-bit steps the way Skia, which drew the reference,
  /// does it on a premultiplied picture: the paint's colour times its alpha, times `cover + 1 >> 8`, plus what is
  /// there times `256 - alpha >> 8`.
  void _plot(int x, int y, int color, int pa, int cover) {
    final i = y * _w + x;
    var al = cover;
    final m = _mask;
    if (m != null) {
      final mv = m[i];
      if (mv == 0) return;
      if (mv != 255) al = (al * mv + 127) ~/ 255;
    }
    if (pa <= 0 || al <= 0) return;
    var sr = color & 255, sg = (color >> 8) & 255, sb = (color >> 16) & 255;
    if (pa != 255) {
      sr = _mulDiv255(sr, pa);
      sg = _mulDiv255(sg, pa);
      sb = _mulDiv255(sb, pa);
    }
    var sa = pa;
    if (al != 255) {
      final k = al + 1;
      sr = (sr * k) >> 8;
      sg = (sg * k) >> 8;
      sb = (sb * k) >> 8;
      sa = (pa * k) >> 8;
    }
    if (sa <= 0) return;
    if (sa >= 255) {
      _t[i] = (0xFF000000 | (sb << 16) | (sg << 8) | sr) & 0xFFFFFFFF;
      return;
    }
    _over(i, sr, sg, sb, sa);
  }

  /// `source-over` of a premultiplied colour `sr, sg, sb` at alpha `sa` (1 to 254) on pixel `i`.
  void _over(int i, int sr, int sg, int sb, int sa) {
    final dst = _t[i], da = dst >> 24, keep = 256 - sa;
    if (da == 255) {
      final r = sr + (((dst & 255) * keep) >> 8);
      final g = sg + ((((dst >> 8) & 255) * keep) >> 8);
      final b = sb + ((((dst >> 16) & 255) * keep) >> 8);
      _t[i] = (0xFF000000 | (b << 16) | (g << 8) | r) & 0xFFFFFFFF;
      return;
    }
    // what is there is partly transparent: premultiply it, blend, and turn the result back into a straight colour
    final pr = da == 0 ? 0 : _mulDiv255(dst & 255, da);
    final pg = da == 0 ? 0 : _mulDiv255((dst >> 8) & 255, da);
    final pb = da == 0 ? 0 : _mulDiv255((dst >> 16) & 255, da);
    final oa = sa + ((da * keep) >> 8);
    if (oa <= 0) {
      _t[i] = 0;
      return;
    }
    int straight(int v) => math.min(255, (v * 255 + oa ~/ 2) ~/ oa);
    final r = straight(sr + ((pr * keep) >> 8));
    final g = straight(sg + ((pg * keep) >> 8));
    final b = straight(sb + ((pb * keep) >> 8));
    _t[i] = ((oa << 24) | (b << 16) | (g << 8) | r) & 0xFFFFFFFF;
  }

  /// One pixel of an image: the premultiplied colour `pr, pg, pb` at alpha `pa` (0 to 255), drawn at the paint alpha
  /// `aa` (`globalAlpha`, 0 to 255), over a solid pixel the way the reference's canvas blends an image: at full `aa`
  /// `source + what is there * (256 - alpha) >> 8`, below it `(source * (aa + 1) + what is there * rest) >> 8`.
  void _putImage(int x, int y, int pr, int pg, int pb, int pa, int aa) {
    if (pa <= 0 || aa <= 0) return;
    final i = y * _w + x;
    var g = aa;
    final m = _mask;
    if (m != null) {
      final mv = m[i];
      if (mv == 0) return;
      if (mv != 255) g = (g * mv + 127) ~/ 255;
      if (g <= 0) return;
    }
    if (g >= 255 && pa >= 255) {
      _t[i] = (0xFF000000 | (pb << 16) | (pg << 8) | pr) & 0xFFFFFFFF;
      return;
    }
    final dst = _t[i];
    if ((dst >> 24) == 255) {
      int r, gr, b;
      if (g >= 255) {
        final keep = 256 - pa;
        r = pr + (((dst & 255) * keep) >> 8);
        gr = pg + ((((dst >> 8) & 255) * keep) >> 8);
        b = pb + ((((dst >> 16) & 255) * keep) >> 8);
      } else {
        final ss = g + 1, v = 0xFFFF - pa * ss, ds = (v + (v >> 8)) >> 8;
        r = (pr * ss + (dst & 255) * ds) >> 8;
        gr = (pg * ss + ((dst >> 8) & 255) * ds) >> 8;
        b = (pb * ss + ((dst >> 16) & 255) * ds) >> 8;
      }
      _t[i] =
          (0xFF000000 |
              (math.min(255, b) << 16) |
              (math.min(255, gr) << 8) |
              math.min(255, r)) &
          0xFFFFFFFF;
      return;
    }
    if (g >= 255) {
      _over(i, pr, pg, pb, pa);
    } else {
      final ss = g + 1;
      _over(i, (pr * ss) >> 8, (pg * ss) >> 8, (pb * ss) >> 8, (pa * ss) >> 8);
    }
  }

  /// A fraction `1 - cov` of what is on pixel `i` stays (the alpha only: the colour is not touched).
  void _erase(int x, int y, double cov) {
    final i = y * _w + x;
    var k = cov;
    final m = _mask;
    if (m != null) k = k * m[i] / 255;
    if (k <= 0) return;
    final p = _t[i];
    if (k >= 1) {
      _t[i] = 0;
      return;
    }
    final na = (((p >> 24) * (1 - k)) + 0.5).floor();
    _t[i] = na <= 0 ? 0 : (((na << 24) | (p & 0xFFFFFF)) & 0xFFFFFFFF);
  }

  // ---- rectangles ----

  bool get _axisAligned => _b == 0 && _c == 0;

  void fillRect(num x, num y, num w, num h) {
    if (w == 0 || h == 0) return;
    final color = fillStyle, pa = _paintAlpha((color >> 24) & 255);
    if (pa <= 0) return;
    if (_axisAligned) {
      final xa = _a * x + _e, xb = _a * (x + w) + _e;
      final ya = _d * y + _f, yb = _d * (y + h) + _f;
      _fillDeviceRect(
        math.min(xa, xb),
        math.min(ya, yb),
        math.max(xa, xb),
        math.max(ya, yb),
        color,
        pa,
      );
    } else {
      final cov = _raster([_rectPoly(x, y, w, h)]);
      if (cov != null) _paint(cov, color, pa);
    }
  }

  void clearRect(num x, num y, num w, num h) {
    if (w == 0 || h == 0) return;
    if (_axisAligned) {
      final xa = _a * x + _e, xb = _a * (x + w) + _e;
      final ya = _d * y + _f, yb = _d * (y + h) + _f;
      final x0 = math.min(xa, xb), x1 = math.max(xa, xb);
      final y0 = math.min(ya, yb), y1 = math.max(ya, yb);
      final ix0 = math.max(x0.floor(), _clipX0),
          ix1 = math.min(x1.ceil(), _clipX1);
      final iy0 = math.max(y0.floor(), _clipY0),
          iy1 = math.min(y1.ceil(), _clipY1);
      for (var py = iy0; py < iy1; py++) {
        final oy = math.min(y1, py + 1.0) - math.max(y0, py.toDouble());
        for (var px = ix0; px < ix1; px++) {
          final ox = math.min(x1, px + 1.0) - math.max(x0, px.toDouble());
          _erase(px, py, ox * oy);
        }
      }
    } else {
      final cov = _raster([_rectPoly(x, y, w, h)]);
      if (cov == null) return;
      for (var j = 0; j < cov.h; j++) {
        for (var i = 0; i < cov.w; i++) {
          final n = cov.n[j * cov.w + i];
          if (n > 0) _erase(cov.x0 + i, cov.y0 + j, n / 16);
        }
      }
    }
  }

  /// The four corners of a rectangle of the current user space, as picture points.
  List<double> _rectPoly(num x, num y, num w, num h) {
    final xs = [x, x + w, x + w, x], ys = [y, y, y + h, y + h];
    final p = <double>[];
    for (var i = 0; i < 4; i++) {
      p.add(_a * xs[i] + _c * ys[i] + _e);
      p.add(_b * xs[i] + _d * ys[i] + _f);
    }
    return p;
  }

  /// A rectangle of the picture's own coordinates. One of whole pixels is filled as it is; one with an edge inside a
  /// pixel is drawn the way the reference's canvas (Skia, `antifillrect`) draws it, see [_antiFillRect].
  void _fillDeviceRect(
    double x0,
    double y0,
    double x1,
    double y1,
    int color,
    int pa,
  ) {
    final ix0 = math.max(x0.floor(), _clipX0),
        ix1 = math.min(x1.ceil(), _clipX1);
    final iy0 = math.max(y0.floor(), _clipY0),
        iy1 = math.min(y1.ceil(), _clipY1);
    if (ix1 <= ix0 || iy1 <= iy0) return;
    if (x0 == x0.floorToDouble() &&
        x1 == x1.floorToDouble() &&
        y0 == y0.floorToDouble() &&
        y1 == y1.floorToDouble()) {
      _fillWhole(ix0, iy0, ix1, iy1, color, pa);
      return;
    }
    _antiFillRect(x0, y0, x1, y1, color, pa);
  }

  /// Whole pixels `x0 .. x1 - 1`, `y0 .. y1 - 1` (already inside the clip rectangle) in one colour.
  void _fillWhole(int x0, int y0, int x1, int y1, int color, int pa) {
    if (x1 <= x0 || y1 <= y0) return;
    if (pa >= 255 && _mask == null) {
      final solid = (0xFF000000 | (color & 0xFFFFFF)) & 0xFFFFFFFF;
      for (var py = y0; py < y1; py++) {
        _t.fillRange(py * _w + x0, py * _w + x1, solid);
      }
      return;
    }
    for (var py = y0; py < y1; py++) {
      for (var px = x0; px < x1; px++) {
        _plot(px, py, color, pa, 255);
      }
    }
  }

  /// A rectangle with an edge inside a pixel, the way the reference's canvas (Skia, `antifillrect`) draws it: the
  /// edges in 24.8 fixed point, a partly covered pixel at an alpha of 0 to 255 in steps of 1/256, a corner the
  /// product of the two.
  void _antiFillRect(
    double x0,
    double y0,
    double x1,
    double y1,
    int color,
    int pa,
  ) {
    // `>> 8` of a negative number is not the same on the web (it gives an unsigned number), so a division is used
    int shr8(int v) => (v / 256).floor();
    int dot8(double v) => shr8((v * 65536).truncate() + 0x80);
    final l = dot8(x0), t = dot8(y0), r = dot8(x1), b = dot8(y1);
    if (l >= r || t >= b) return;
    int to255(int a) => a - (a >> 8);
    int mul(int a, int s) => (a * s) >> 8;
    void put(int x, int y, int cover) {
      if (cover <= 0 ||
          x < _clipX0 ||
          x >= _clipX1 ||
          y < _clipY0 ||
          y >= _clipY1) {
        return;
      }
      _plot(x, y, color, pa, cover);
    }

    // a row of the rectangle's height 1, partly covered by `alpha` (its top or bottom edge)
    void scanline(int row, int alpha) {
      if (shr8(l) == shr8(r - 1)) {
        put(shr8(l), row, mul(alpha, to255(r - l)));
        return;
      }
      var x = shr8(l);
      if ((l & 0xFF) != 0) {
        put(x, row, mul(alpha, to255(256 - (l & 0xFF))));
        x++;
      }
      final rite = shr8(r);
      for (; x < rite; x++) {
        put(x, row, alpha);
      }
      if ((r & 0xFF) != 0) put(rite, row, mul(alpha, r & 0xFF));
    }

    final top = shr8(t), bot = shr8(b + 255);
    if (top == bot - 1) {
      scanline(top, b - t - 1);
      return;
    }
    var first = top, end = bot;
    if ((t & 0xFF) != 0) {
      scanline(top, 256 - (t & 0xFF));
      first = top + 1;
    }
    if ((b & 0xFF) != 0) {
      end = bot - 1;
      scanline(end, b & 0xFF);
    }
    var x = shr8(l);
    if ((l & 0xFF) != 0) {
      for (var row = first; row < end; row++) {
        put(x, row, to255(256 - (l & 0xFF)));
      }
      x++;
    }
    final rite = shr8(r);
    _fillWhole(
      math.max(x, _clipX0),
      math.max(first, _clipY0),
      math.min(rite, _clipX1),
      math.min(end, _clipY1),
      color,
      pa,
    );
    if ((r & 0xFF) != 0) {
      for (var row = first; row < end; row++) {
        put(rite, row, r & 0xFF);
      }
    }
  }

  // ---- images ----

  void drawImage(Sprite s, num dx, num dy, [num? dw, num? dh]) =>
      _drawImage(s, 0, 0, s.w, s.h, dx, dy, dw ?? s.w, dh ?? s.h);

  void drawImageRect(
    Sprite s,
    num sx,
    num sy,
    num sw,
    num sh,
    num dx,
    num dy,
    num dw,
    num dh,
  ) => _drawImage(s, sx, sy, sw, sh, dx, dy, dw, dh);

  void _drawImage(
    Sprite s,
    num sx0,
    num sy0,
    num sw0,
    num sh0,
    num dx0,
    num dy0,
    num dw0,
    num dh0,
  ) {
    final sx = sx0.toDouble(), sy = sy0.toDouble();
    final sw = sw0.toDouble(), sh = sh0.toDouble();
    final dx = dx0.toDouble(), dy = dy0.toDouble();
    final dw = dw0.toDouble(), dh = dh0.toDouble();
    if (sw == 0 || sh == 0 || dw == 0 || dh == 0) return;
    if (!(sx + sy + sw + sh + dx + dy + dw + dh).isFinite) return;
    if (_paintAlpha(255) <= 0) return;

    // the sprite's pixel space (u, v) to the picture: x = A11 u + A12 v + T1, y = A21 u + A22 v + T2
    final kx = dw / sw, ky = dh / sh;
    final a11 = _a * kx, a12 = _c * ky, a21 = _b * kx, a22 = _d * ky;
    var t1 = _a * (dx - sx * kx) + _c * (dy - sy * ky) + _e;
    var t2 = _b * (dx - sx * kx) + _d * (dy - sy * ky) + _f;

    // the part of the sprite that is drawn: the source rectangle inside the picture of the sprite
    final fullL = math.min(sx, sx + sw), fullR = math.max(sx, sx + sw);
    final fullT = math.min(sy, sy + sh), fullB = math.max(sy, sy + sh);
    final uL = math.max(fullL, 0.0), uR = math.min(fullR, s.w.toDouble());
    final vT = math.max(fullT, 0.0), vB = math.min(fullB, s.h.toDouble());
    if (uL >= uR || vT >= vB) return;

    final aligned = a12 == 0 && a21 == 0;
    if (!smoothing &&
        aligned &&
        (a11.abs() - 1).abs() < 1e-9 &&
        (a22.abs() - 1).abs() < 1e-9) {
      // not scaled, not turned (a flip is still not scaled): it lands on a whole pixel
      final xa = a11 * fullL + t1, xb = a11 * fullR + t1;
      final ya = a22 * fullT + t2, yb = a22 * fullB + t2;
      final left = math.min(xa, xb), top = math.min(ya, yb);
      t1 += (left + 0.5).floor() - left;
      t2 += (top + 0.5).floor() - top;
    }

    final det = a11 * a22 - a12 * a21;
    if (det.abs() < 1e-12) return;
    final i11 = a22 / det, i12 = -a12 / det, i21 = -a21 / det, i22 = a11 / det;

    // the box of the picture the sprite can reach
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final u in [uL, uR]) {
      for (final v in [vT, vB]) {
        final x = a11 * u + a12 * v + t1, y = a21 * u + a22 * v + t2;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }
    final ix0 = math.max(minX.floor(), _clipX0),
        ix1 = math.min(maxX.ceil(), _clipX1);
    final iy0 = math.max(minY.floor(), _clipY0),
        iy1 = math.min(maxY.ceil(), _clipY1);
    if (ix1 <= ix0 || iy1 <= iy0) return;

    // The pixels it goes on. A sprite that is not turned fills the pixels between its edges rounded to whole pixels
    // (the reference's canvas draws no soft edge there); one that is turned, the pixels whose centre it covers.
    var bx0 = ix0, bx1 = ix1, by0 = iy0, by1 = iy1;
    if (aligned) {
      final xa = a11 * uL + t1, xb = a11 * uR + t1;
      final ya = a22 * vT + t2, yb = a22 * vB + t2;
      bx0 = math.max(bx0, (math.min(xa, xb) + 0.5).floor());
      bx1 = math.min(bx1, (math.max(xa, xb) + 0.5).floor());
      by0 = math.max(by0, (math.min(ya, yb) + 0.5).floor());
      by1 = math.min(by1, (math.max(ya, yb) + 0.5).floor());
    }
    final iL = uL.floor(),
        iR = uR.ceil() - 1,
        iT = vT.floor(),
        iB = vB.ceil() - 1;
    int clampX(int v) => math.min(math.max(v, iL), iR);
    int clampY(int v) => math.min(math.max(v, iT), iB);
    final aa = _paintAlpha(255), px = s.px, sw1 = s.w;
    // a texel's colour multiplied by its alpha
    int pm(int c, int a) => a == 255 ? c : _mulDiv255(c, a);
    for (var py = by0; py < by1; py++) {
      final yy = py + .5 - t2;
      for (var pxl = bx0; pxl < bx1; pxl++) {
        final xx = pxl + .5 - t1;
        final u = i11 * xx + i12 * yy, v = i21 * xx + i22 * yy;
        if (!aligned && (u < uL || u >= uR || v < vT || v >= vB)) continue;
        if (!smoothing) {
          // the nearest pixel; a centre exactly between two takes the lower one
          final p =
              px[clampY((v - 1e-9).floor()) * sw1 + clampX((u - 1e-9).floor())];
          final a = p >> 24;
          if (a == 0) continue;
          _putImage(
            pxl,
            py,
            pm(p & 255, a),
            pm((p >> 8) & 255, a),
            pm((p >> 16) & 255, a),
            a,
            aa,
          );
          continue;
        }
        // bilinear: the four pixels round the point, weighted in sixteenths (Skia's own, 4 bits a side)
        final fu = u - .5, fv = v - .5;
        final u0 = fu.floor(), v0 = fv.floor();
        final fx = math.min(15, ((fu - u0) * 16).floor());
        final fy = math.min(15, ((fv - v0) * 16).floor());
        final xy = fx * fy;
        final xa = clampX(u0), xb = clampX(u0 + 1);
        final ya = clampY(v0), yb = clampY(v0 + 1);
        final p00 = px[ya * sw1 + xa], p01 = px[ya * sw1 + xb];
        final p10 = px[yb * sw1 + xa], p11 = px[yb * sw1 + xb];
        final w00 = 256 - 16 * fx - 16 * fy + xy;
        final w01 = 16 * fx - xy, w10 = 16 * fy - xy, w11 = xy;
        int mix(int shift, bool premultiplied) {
          int ch(int p) {
            final a = p >> 24, c = (p >> shift) & 255;
            return premultiplied ? pm(c, a) : c;
          }

          return (ch(p00) * w00 +
                  ch(p01) * w01 +
                  ch(p10) * w10 +
                  ch(p11) * w11) >>
              8;
        }

        final a =
            (((p00 >> 24) * w00 +
                (p01 >> 24) * w01 +
                (p10 >> 24) * w10 +
                (p11 >> 24) * w11) >>
            8);
        if (a == 0) continue;
        _putImage(pxl, py, mix(0, true), mix(8, true), mix(16, true), a, aa);
      }
    }
  }

  // ---- paths ----

  void beginPath() {
    _path = [];
  }

  _Sub _newSub(double x, double y) {
    final s = _Sub();
    s.pts
      ..add(x)
      ..add(y);
    _path.add(s);
    return s;
  }

  double _px(num x, num y) => _a * x + _c * y + _e;
  double _py(num x, num y) => _b * x + _d * y + _f;

  void moveTo(num x, num y) {
    _newSub(_px(x, y), _py(x, y));
  }

  /// The sub-path a line or an arc goes on: the open one at the end of the path, or, when the last was closed (a
  /// `rect`), a new one at its first point.
  _Sub? _openSub() {
    if (_path.isEmpty) return null;
    final last = _path.last;
    if (!last.closed) return last;
    return _newSub(last.pts[0], last.pts[1]);
  }

  void lineTo(num x, num y) {
    final s = _openSub();
    if (s == null) {
      moveTo(x, y);
      return;
    }
    s.pts
      ..add(_px(x, y))
      ..add(_py(x, y));
  }

  void rect(num x, num y, num w, num h) {
    final s = _Sub()..closed = true;
    s.pts.addAll(_rectPoly(x, y, w, h));
    _path.add(s);
  }

  void arc(num x, num y, num r, num a0, num a1) =>
      ellipse(x, y, r, r, 0, a0, a1);

  void ellipse(num x, num y, num rx, num ry, num rot, num a0, num a1) {
    if (rx < 0 || ry < 0) {
      throw ArgumentError('a negative radius: $rx, $ry');
    }
    var sweep = (a1 - a0).toDouble();
    var full = false;
    if (sweep >= _twoPi) {
      sweep = _twoPi;
      full = true;
    } else if (sweep < 0) {
      sweep = sweep % _twoPi;
    }
    // how many straight pieces: the curve stays within a tenth of a pixel of the circle
    final scale = math.sqrt((_a * _d - _b * _c).abs());
    final rmax = math.max(rx, ry) * scale;
    final step = rmax <= 0.2 ? math.pi / 2 : 2 * math.acos(1 - 0.1 / rmax);
    final n = math.max(4, math.min(720, (sweep / step).ceil()));
    final cr = math.cos(rot), sr = math.sin(rot);
    final pts = <double>[];
    for (var i = 0; i <= n; i++) {
      final t = a0 + sweep * i / n;
      final ux = rx * math.cos(t), uy = ry * math.sin(t);
      final wx = ux * cr - uy * sr + x, wy = ux * sr + uy * cr + y;
      pts
        ..add(_px(wx, wy))
        ..add(_py(wx, wy));
    }
    final open = _openSub();
    if (open == null) {
      final s = _newSub(pts[0], pts[1]);
      for (var i = 2; i < pts.length; i++) {
        s.pts.add(pts[i]);
      }
      if (full) {
        // the last point is the first: drop it and close the shape
        s.pts.removeRange(s.pts.length - 2, s.pts.length);
        s.closed = true;
      }
    } else {
      open.pts.addAll(pts);
    }
  }

  // ---- filling ----

  /// The path's rectangle in picture coordinates, when it is one rectangle with its sides along the axes.
  List<double>? _alignedRect() {
    if (_path.length != 1) return null;
    final p = _path.first.pts;
    if (p.length != 8) return null;
    final x0 = math.min(math.min(p[0], p[2]), math.min(p[4], p[6]));
    final x1 = math.max(math.max(p[0], p[2]), math.max(p[4], p[6]));
    final y0 = math.min(math.min(p[1], p[3]), math.min(p[5], p[7]));
    final y1 = math.max(math.max(p[1], p[3]), math.max(p[5], p[7]));
    bool onSide(double v, double a, double b) =>
        (v - a).abs() < 1e-9 || (v - b).abs() < 1e-9;
    for (var i = 0; i < 8; i += 2) {
      if (!onSide(p[i], x0, x1) || !onSide(p[i + 1], y0, y1)) return null;
    }
    // every side runs along an axis: neighbours share an x or a y
    for (var i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      final sameX = (p[i * 2] - p[j * 2]).abs() < 1e-9;
      final sameY = (p[i * 2 + 1] - p[j * 2 + 1]).abs() < 1e-9;
      if (!sameX && !sameY) return null;
    }
    return [x0, y0, x1, y1];
  }

  void fill() {
    final color = fillStyle, pa = _paintAlpha((color >> 24) & 255);
    if (pa <= 0) return;
    final r = _alignedRect();
    if (r != null) {
      _fillDeviceRect(r[0], r[1], r[2], r[3], color, pa);
      return;
    }
    final cov = _raster([
      for (final s in _path)
        if (s.pts.length >= 6) s.pts,
    ]);
    if (cov != null) _paint(cov, color, pa);
  }

  void stroke() {
    final color = strokeStyle, pa = _paintAlpha((color >> 24) & 255);
    if (pa <= 0) return;
    final cov = _raster(_strokePolys());
    if (cov != null) _paint(cov, color, pa);
  }

  void _paint(_Cov cov, int color, int pa) {
    for (var j = 0; j < cov.h; j++) {
      for (var i = 0; i < cov.w; i++) {
        final n = cov.n[j * cov.w + i];
        if (n > 0) {
          _plot(cov.x0 + i, cov.y0 + j, color, pa, math.min(255, n * 16));
        }
      }
    }
  }

  void clip() {
    final r = _alignedRect();
    if (r != null) {
      final whole = [for (final v in r) (v - v.roundToDouble()).abs() < 1e-9]
          .every((b) => b);
      if (whole) {
        // a rectangle of whole pixels: the stack of rectangles
        _clipX0 = math.max(_clipX0, r[0].round());
        _clipY0 = math.max(_clipY0, r[1].round());
        _clipX1 = math.min(_clipX1, r[2].round());
        _clipY1 = math.min(_clipY1, r[3].round());
        _emptyIfCrossed();
        return;
      }
      // a rectangle with an edge inside a pixel: the path mask, with the exact share of each pixel
      final x0 = math.max(r[0].floor(), _clipX0),
          x1 = math.min(r[2].ceil(), _clipX1);
      final y0 = math.max(r[1].floor(), _clipY0),
          y1 = math.min(r[3].ceil(), _clipY1);
      if (x1 <= x0 || y1 <= y0) {
        _emptyClip();
        return;
      }
      final cov = _Cov(x0, y0, x1 - x0, y1 - y0);
      final share = Float64List(cov.w * cov.h);
      for (var j = 0; j < cov.h; j++) {
        final oy =
            math.min(r[3], y0 + j + 1.0) - math.max(r[1], (y0 + j).toDouble());
        for (var i = 0; i < cov.w; i++) {
          final ox =
              math.min(r[2], x0 + i + 1.0) -
              math.max(r[0], (x0 + i).toDouble());
          share[j * cov.w + i] = ox * oy;
        }
      }
      _applyMask(cov, (k) => share[k]);
      return;
    }
    final cov = _raster([
      for (final s in _path)
        if (s.pts.length >= 6) s.pts,
    ]);
    if (cov == null) {
      _emptyClip();
      return;
    }
    _applyMask(cov, (k) => cov.n[k] / 16);
  }

  void _emptyClip() {
    _clipX1 = _clipX0;
    _clipY1 = _clipY0;
  }

  void _emptyIfCrossed() {
    if (_clipX1 < _clipX0) _clipX1 = _clipX0;
    if (_clipY1 < _clipY0) _clipY1 = _clipY0;
  }

  /// Keeps what a shape covers: the coverage of `cov` (0 to 1 at each of its pixels) times the mask there already is.
  void _applyMask(_Cov cov, double Function(int k) share) {
    final old = _mask, m = Uint8List(_w * _h);
    for (var j = 0; j < cov.h; j++) {
      for (var i = 0; i < cov.w; i++) {
        final v = (share(j * cov.w + i) * 255 + 0.5).floor().clamp(0, 255);
        if (v == 0) continue;
        final at = (cov.y0 + j) * _w + cov.x0 + i;
        m[at] = old == null ? v : (old[at] * v + 127) ~/ 255;
      }
    }
    _mask = m;
    _clipX0 = math.max(_clipX0, cov.x0);
    _clipY0 = math.max(_clipY0, cov.y0);
    _clipX1 = math.min(_clipX1, cov.x0 + cov.w);
    _clipY1 = math.min(_clipY1, cov.y0 + cov.h);
    _emptyIfCrossed();
  }

  // ---- the stroke's outline, as shapes ----

  /// A shape of the stroke, its points in order with a positive area (so that all of them together, filled with the
  /// non-zero rule, are their union).
  void _addPoly(List<List<double>> out, List<double> p) {
    var area = 0.0;
    final n = p.length ~/ 2;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += p[i * 2] * p[j * 2 + 1] - p[j * 2] * p[i * 2 + 1];
    }
    if (area == 0) return;
    if (area > 0) {
      out.add(p);
      return;
    }
    final r = <double>[];
    for (var i = n - 1; i >= 0; i--) {
      r
        ..add(p[i * 2])
        ..add(p[i * 2 + 1]);
    }
    out.add(r);
  }

  List<List<double>> _strokePolys() {
    final scale = math.sqrt((_a * _d - _b * _c).abs());
    final hw = lineWidth * scale / 2;
    final out = <List<double>>[];
    if (!(hw > 0)) return out;
    for (final sub in _path) {
      // the points, a point that repeats the one before dropped
      final p = <double>[];
      for (var i = 0; i < sub.pts.length; i += 2) {
        if (p.length >= 2 &&
            p[p.length - 2] == sub.pts[i] &&
            p[p.length - 1] == sub.pts[i + 1]) {
          continue;
        }
        p
          ..add(sub.pts[i])
          ..add(sub.pts[i + 1]);
      }
      var m = p.length ~/ 2;
      var closed = sub.closed;
      if (closed &&
          m > 1 &&
          p[0] == p[(m - 1) * 2] &&
          p[1] == p[(m - 1) * 2 + 1]) {
        p.removeRange((m - 1) * 2, m * 2);
        m--;
      }
      if (m < 2) continue;
      if (m == 2) closed = false;
      final segs = closed ? m : m - 1;
      // the unit direction of each segment
      final ux = List<double>.filled(segs, 0),
          uy = List<double>.filled(segs, 0);
      for (var i = 0; i < segs; i++) {
        final j = (i + 1) % m;
        final dx = p[j * 2] - p[i * 2], dy = p[j * 2 + 1] - p[i * 2 + 1];
        final len = math.sqrt(dx * dx + dy * dy);
        ux[i] = dx / len;
        uy[i] = dy / len;
      }
      for (var i = 0; i < segs; i++) {
        final j = (i + 1) % m;
        final nx = -uy[i] * hw, ny = ux[i] * hw;
        final x0 = p[i * 2],
            y0 = p[i * 2 + 1],
            x1 = p[j * 2],
            y1 = p[j * 2 + 1];
        _addPoly(out, [
          x0 + nx, y0 + ny, //
          x1 + nx, y1 + ny,
          x1 - nx, y1 - ny,
          x0 - nx, y0 - ny,
        ]);
        // the join at the end of this segment: a mitre, or a bevel when the corner is too sharp
        final k = (i + 1) % segs;
        if (!closed && i == segs - 1) continue;
        final cross = ux[i] * uy[k] - uy[i] * ux[k];
        final dot = ux[i] * ux[k] + uy[i] * uy[k];
        if (cross.abs() < 1e-9 && dot > 0) continue;
        final sgn = cross > 0 ? -1.0 : 1.0;
        final n1x = -uy[i] * hw * sgn, n1y = ux[i] * hw * sgn;
        final n2x = -uy[k] * hw * sgn, n2y = ux[k] * hw * sgn;
        final cosPhi = dot;
        if (1 + cosPhi > 1e-9 && math.sqrt(2 / (1 + cosPhi)) <= 10) {
          final f = 1 / (1 + cosPhi);
          _addPoly(out, [
            x1, y1, //
            x1 + n1x, y1 + n1y,
            x1 + (n1x + n2x) * f, y1 + (n1y + n2y) * f,
            x1 + n2x, y1 + n2y,
          ]);
        } else {
          _addPoly(out, [x1, y1, x1 + n1x, y1 + n1y, x1 + n2x, y1 + n2y]);
        }
      }
    }
    return out;
  }

  // ---- the rasteriser ----

  /// How many of the 16 sample points (4 across, 4 down, in the middle of each quarter) of each pixel the shapes
  /// cover, by the non-zero rule, scanline by scanline. Only the part inside the clip rectangle. Each shape is
  /// closed by its last point to its first.
  _Cov? _raster(List<List<double>> polys) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    var edges = 0;
    for (final p in polys) {
      for (var i = 0; i < p.length; i += 2) {
        minX = math.min(minX, p[i]);
        maxX = math.max(maxX, p[i]);
        minY = math.min(minY, p[i + 1]);
        maxY = math.max(maxY, p[i + 1]);
      }
      edges += p.length ~/ 2;
    }
    if (edges == 0 ||
        !(minX.isFinite && maxX.isFinite && minY.isFinite && maxY.isFinite)) {
      return null;
    }
    final x0 = math.max(minX.floor(), _clipX0),
        x1 = math.min(maxX.ceil(), _clipX1);
    final y0 = math.max(minY.floor(), _clipY0),
        y1 = math.min(maxY.ceil(), _clipY1);
    if (x1 <= x0 || y1 <= y0) return null;
    final cov = _Cov(x0, y0, x1 - x0, y1 - y0);
    // the edges, each from its upper end to its lower end, with the way it goes
    final ex = Float64List(edges), ey = Float64List(edges);
    final ex2 = Float64List(edges), ey2 = Float64List(edges);
    final dir = Int8List(edges);
    var ne = 0;
    for (final p in polys) {
      final n = p.length ~/ 2;
      for (var i = 0; i < n; i++) {
        final j = (i + 1) % n;
        final ax = p[i * 2],
            ay = p[i * 2 + 1],
            bx = p[j * 2],
            by = p[j * 2 + 1];
        if (ay == by) continue;
        if (ay < by) {
          ex[ne] = ax;
          ey[ne] = ay;
          ex2[ne] = bx;
          ey2[ne] = by;
          dir[ne] = 1;
        } else {
          ex[ne] = bx;
          ey[ne] = by;
          ex2[ne] = ax;
          ey2[ne] = ay;
          dir[ne] = -1;
        }
        ne++;
      }
    }
    final xs = <double>[], ds = <int>[];
    final left = x0 * 4, right = x1 * 4;
    for (var py = y0; py < y1; py++) {
      for (var s = 0; s < 4; s++) {
        final sy = py + (s + .5) / 4;
        xs.clear();
        ds.clear();
        for (var k = 0; k < ne; k++) {
          if (sy < ey[k] || sy >= ey2[k]) continue;
          final x = ex[k] + (sy - ey[k]) * (ex2[k] - ex[k]) / (ey2[k] - ey[k]);
          var at = xs.length;
          while (at > 0 && xs[at - 1] > x) {
            at--;
          }
          xs.insert(at, x);
          ds.insert(at, dir[k]);
        }
        var wind = 0;
        for (var m = 0; m + 1 < xs.length; m++) {
          wind += ds[m];
          if (wind == 0) continue;
          // the sample points (k + .5) / 4 from xs[m] up to xs[m + 1]
          var ks = (xs[m] * 4 - .5).ceil(), ke = (xs[m + 1] * 4 - .5).ceil();
          if (ks < left) ks = left;
          if (ke > right) ke = right;
          for (var k = ks; k < ke; k++) {
            cov.n[(py - y0) * cov.w + (k >> 2) - x0]++;
          }
        }
      }
    }
    return cov;
  }

  // ---- reading back ----

  /// A copy of part of the picture (sala.js, banco.js). What lies outside the picture is transparent.
  Sprite snapshot(int x, int y, int w, int h) {
    final out = Uint32List(w * h);
    for (var j = 0; j < h; j++) {
      final sy = y + j;
      if (sy < 0 || sy >= _h) continue;
      for (var i = 0; i < w; i++) {
        final sx = x + i;
        if (sx < 0 || sx >= _w) continue;
        out[j * w + i] = _t[sy * _w + sx];
      }
    }
    return Sprite(w, h, out);
  }
}
