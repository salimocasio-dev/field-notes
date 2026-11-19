// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/int32.dart';
import 'package:coqui_pixel/src/js_num.dart';

/// Port of historia/engine.js: Buf, RP, OUT, bay, hs, rgb, fr, every mk* sprite, sky, grass, shadow, face, coqui, bubble, GL, GC.
///
/// A sprite is a picture: w × h pixels, each 0xAABBGGRR (`Uint32List`, RGBA bytes in memory order). In the old code
/// it is a canvas; here a [Buf]'s `done()` gives the picture, and [Ctx] draws into it the way a canvas context does.
///
/// Colours. The old code writes a colour as a string, `"#RRGGBB"`. Here every colour is the int `0xFFBBGGRR` (page 12,
/// section 6): `"#E6863A"` is `0xFF3A86E6`. `"rgba(0,0,0,0)"` is `0x00000000`.
///
/// What is where. Everything that has no state of its own is a top-level name of the old file: [RP], [OUT], [bay],
/// [hs], [Buf], [fr], every `mk*`, [sky], [grass], [face], [pointer], [sparks], [talk], [shadow]. What the old file keeps
/// in globals that change (the sprite cache `SP`, the glyph tables `GL` and `GC` that scene files add to, the colour
/// cache `_rgb`) is fields of [SpriteLib], with the functions that use them ([SpriteLib.spr], [SpriteLib.glyph],
/// [SpriteLib.bubble], [SpriteLib.coqui], [SpriteLib.bgCasa], [SpriteLib.bgParque], [SpriteLib.rgb]).
class Sprite {
  // DECISION(order 02): page 12 gives the fields and no constructor; this is the plain one.
  Sprite(this.w, this.h, this.px);

  final int w, h;
  final Uint32List px;
}

// engine.js: BAY
const List<int> BAY = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];

// engine.js: bay
double bay(num x, num y) =>
    (BAY[(y.truncate() & 3) * 4 + (x.truncate() & 3)] + .5) / 16;

// engine.js: hs
int hs(num x, num y) {
  var n = toInt32(imul(toInt32(x), 374761393) + imul(toInt32(y), 668265263));
  n = imul(n ^ ((n & 0xFFFFFFFF) >> 13), 1274126177);
  return ((n ^ ((n & 0xFFFFFFFF) >> 16)) & 0xFFFFFFFF) % 100;
}

/// The palettes of engine.js (`RP`): five tones of a colour, dark to light (`cloud` repeats white, `grass` is four
/// greens and one more).
abstract final class RP {
  static const List<int> tan = [
    0xFF1E4A7A,
    0xFF2C68A8,
    0xFF3C85C8,
    0xFF5AA8E2,
    0xFF88CCF4,
  ];
  static const List<int> cream = [
    0xFF6A9AB8,
    0xFF8ABCD8,
    0xFFB0DCEE,
    0xFFD2F0FB,
    0xFFEAFBFF,
  ];
  static const List<int> skin = [
    0xFF2A4A7A,
    0xFF38629A,
    0xFF487AB8,
    0xFF6094D0,
    0xFF80B0E4,
  ];
  static const List<int> grey = [
    0xFF806E6E,
    0xFFA69494,
    0xFFC8B8B8,
    0xFFE4D8D8,
    0xFFF8F2F2,
  ];
  static const List<int> purp = [
    0xFF68244A,
    0xFF90366A,
    0xFFB44C8A,
    0xFFD068A8,
    0xFFE890C8,
  ];
  static const List<int> grn = [
    0xFF2D5314,
    0xFF3A7A1E,
    0xFF489A2E,
    0xFF58BC4C,
    0xFF78DC84,
  ];
  static const List<int> red = [
    0xFF1C1C7A,
    0xFF262AA8,
    0xFF3A40D0,
    0xFF5060EC,
    0xFF8090FA,
  ];
  static const List<int> teal = [
    0xFF706E1A,
    0xFF949024,
    0xFFB0B034,
    0xFFC8CC5C,
    0xFFDEE698,
  ];
  static const List<int> wood = [
    0xFF142A4A,
    0xFF20426E,
    0xFF2E6092,
    0xFF4080B8,
    0xFF60A4D8,
  ];
  static const List<int> blue = [
    0xFFA84F1E,
    0xFFD06C2E,
    0xFFE88C4A,
    0xFFF6B078,
    0xFFFFD4B0,
  ];
  static const List<int> yel = [
    0xFF107AB8,
    0xFF20A0E0,
    0xFF38C8F8,
    0xFF70E0FF,
    0xFFB0F4FF,
  ];
  static const List<int> stone = [
    0xFF505E6A,
    0xFF6C808E,
    0xFF8EA6B4,
    0xFFB0C8D4,
    0xFFD4E6EE,
  ];
  static const List<int> orng = [
    0xFF12428A,
    0xFF1C60B8,
    0xFF3084DC,
    0xFF50A6F2,
    0xFF86CBFB,
  ];
  static const List<int> sky = [
    0xFFE6863A,
    0xFFF29F55,
    0xFFFABA78,
    0xFFFFD3A2,
    0xFFFFEAD0,
  ];
  static const List<int> cloud = [
    0xFFEACCB4,
    0xFFF8E6D6,
    0xFFFFF7F0,
    0xFFFFFFFF,
    0xFFFFFFFF,
  ];
  static const List<int> grass = [
    0xFF5ACC62,
    0xFF4CBC52,
    0xFF42AA44,
    0xFF389838,
    0xFF348A2E,
  ];
}

/// engine.js: `OUT`, the dark outline colour.
const int OUT = 0xFF10182A;

const int _white = 0xFFFFFFFF;

/// A `#` pixel of a glyph with no colour of its own in [SpriteLib.GC], and a `b` pixel of the eye: `"#2E6CD0"`.
const int _glyphBlue = 0xFFD06C2E;

// engine.js: Buf
/// A sprite being drawn pixel by pixel: `d` is the image data, `cv` the canvas it is put on by [done], `cx` the
/// canvas's context (the old code draws other sprites on a finished one: bgCasa, bgParque).
class Buf {
  Buf(this.w, this.h)
    : cv = Sprite(w, h, Uint32List(w * h)),
      d = Uint32List(w * h) {
    cx = Ctx(cv.px, w, h);
  }

  final int w, h;
  final Sprite cv;
  late final Ctx cx;
  final Uint32List d;

  void px(num x, num y, int c) {
    final xi = x.floor(), yi = y.floor();
    if (xi < 0 || yi < 0 || xi >= w || yi >= h) return;
    d[yi * w + xi] = c | 0xFF000000;
  }

  bool has(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && (d[y * w + x] >> 24) > 0;

  void rect(num x, num y, num w, num h, int c) {
    final xr = (x + 0.5).floor(), yr = (y + 0.5).floor();
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        px(xr + i, yr + j, c);
      }
    }
  }

  void ell(num cx, num cy, num rx, num ry, List<int> r) {
    final n = r.length;
    for (var y = (cy - ry).floor(); y <= (cy + ry).ceil(); y++) {
      for (var x = (cx - rx).floor(); x <= (cx + rx).ceil(); x++) {
        final nx = (x + .5 - cx) / rx,
            ny = (y + .5 - cy) / ry,
            dd = nx * nx + ny * ny;
        if (dd > 1) continue;
        if (n == 1) {
          px(x, y, r[0]);
          continue;
        }
        final v = (-nx * .5 - ny * .62 + math.sqrt(1 - dd) * .6) * .8 + .22,
            i = (math.max(0, math.min(.999, v)) * (n - 1) + bay(x, y)).floor();
        px(x, y, r[math.max(0, math.min(n - 1, i))]);
      }
    }
  }

  void grad(num x, num y, num w, num h, List<int> r, [bool hz = false]) {
    final n = r.length;
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        final t = hz ? i / w : j / h;
        px(
          x + i,
          y + j,
          r[math.min(
            n - 1,
            (math.min(.999, t) * (n - 1) + bay(x + i, y + j)).floor(),
          )],
        );
      }
    }
  }

  void cap(num x0, num y0, num x1, num y1, num rad, List<int> r) {
    final dx = x1 - x0, dy = y1 - y0;
    final n = math.max(1, math.sqrt(dx * dx + dy * dy).ceil());
    for (var i = 0; i <= n; i++) {
      ell(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, rad, rad, r);
    }
  }

  void line(num x0, num y0, num x1, num y1, int c) {
    final n = math.max(1, math.max((x1 - x0).abs(), (y1 - y0).abs()).ceil());
    for (var i = 0; i <= n; i++) {
      px(
        (x0 + (x1 - x0) * i / n + 0.5).floor(),
        (y0 + (y1 - y0) * i / n + 0.5).floor(),
        c,
      );
    }
  }

  void frame(num x, num y, num w, num h, int c) {
    rect(x, y, w, 1, c);
    rect(x, y + h - 1, w, 1, c);
    rect(x, y, 1, h, c);
    rect(x + w - 1, y, 1, h, c);
  }

  Buf outline([int? c]) {
    final a = <int>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (!has(x, y) &&
            (has(x - 1, y) ||
                has(x + 1, y) ||
                has(x, y - 1) ||
                has(x, y + 1))) {
          a.add(x);
          a.add(y);
        }
      }
    }
    for (var i = 0; i < a.length; i += 2) {
      px(a[i], a[i + 1], c ?? OUT);
    }
    return this;
  }

  Sprite done() {
    cv.px.setAll(0, d);
    return cv;
  }
}

// engine.js: fr
void fr(Ctx c, num x, num y, num w, num h, int col) {
  c.fillStyle = col;
  c.fillRect((x + 0.5).floor(), (y + 0.5).floor(), w, h);
}

/* ---- sprites ---- */

// engine.js: mkCoqui
Sprite mkCoqui(num s, int blink, bool open) {
  final w = (30 * s + 0.5).floor() + 2,
      h = (25 * s + 0.5).floor() + 2,
      b = Buf(w, h),
      cx = w / 2,
      T = RP.tan;
  b.ell(cx - 9 * s, 19.5 * s, 5 * s, 3.2 * s, T);
  b.ell(cx + 9 * s, 19.5 * s, 5 * s, 3.2 * s, T);
  b.ell(cx, 14 * s, 11 * s, 8 * s, T);
  b.ell(cx, 16.8 * s, 7 * s, 5 * s, RP.cream);
  for (final dx in const [-6, 6]) {
    b.ell(cx + dx * s, 6.5 * s, 4.6 * s, 4.6 * s, T);
    if (blink != 0) {
      b.rect(cx + dx * s - 3 * s, 6.5 * s, (6 * s + 0.5).floor(), 1, OUT);
    } else {
      b.ell(cx + dx * s, 6.5 * s, 3.1 * s, 3.1 * s, const [0xFFFFFFFF]);
      b.ell(cx + dx * s + .8 * s, 7 * s, 1.7 * s, 1.9 * s, const [0xFF0A1420]);
      if (s > .8) b.px(cx + dx * s, 5.6 * s, 0xFFFFFFFF);
    }
  }
  if (open) {
    b.ell(cx, 12.4 * s, 3.4 * s, 2.1 * s, const [0xFF1C1C7A]);
  } else {
    b.line(cx - 4.5 * s, 12.4 * s, cx + 4.5 * s, 12.4 * s, OUT);
    b.px(cx - 5.5 * s, 11.6 * s, OUT);
    b.px(cx + 5 * s, 11.6 * s, OUT);
  }
  b.ell(cx - 5 * s, 22.4 * s, 3.4 * s, 1.7 * s, [T[4]]);
  b.ell(cx + 5 * s, 22.4 * s, 3.4 * s, 1.7 * s, [T[4]]);
  return b.outline().done();
}

// engine.js: mkAbuela
Sprite mkAbuela(String pose, bool open) {
  final b = Buf(48, 51), X = 30, S = RP.skin, P = RP.purp;
  b.ell(X - 4, 47.5, 3.4, 1.9, const [0xFF14243A]);
  b.ell(X + 4, 47.5, 3.4, 1.9, const [0xFF14243A]);
  b.rect(X - 5, 41, 3, 6, S[2]);
  b.rect(X + 2, 41, 3, 6, S[1]);
  b.ell(X, 31, 9, 12.5, P);
  b.ell(X, 38, 10.5, 5, P);
  for (var i = 0; i < 9; i++) {
    b.px(X - 8 + hs(i, 3) % 17, 34 + hs(i, 5) % 8, P[4]);
  }
  b.ell(X, 33, 5.4, 8.5, RP.cream);
  b.rect(X - 5, 24, 10, 1, RP.cream[1]);
  b.rect(X - 2, 17, 4, 4, S[1]);
  b.ell(X, 10, 8, 8.6, RP.grey);
  b.ell(X, 2.9, 3.6, 2.6, RP.grey);
  b.ell(X, 12.4, 5.8, 6.4, S);
  b.ell(X, 5.8, 6.2, 2.6, RP.grey);
  b.px(X - 3, 12, 0xFF0A1420);
  b.px(X + 2, 12, 0xFF0A1420);
  b.px(X - 4, 14, 0xFF708AE0);
  b.px(X + 3, 14, 0xFF708AE0);
  if (open) {
    b.rect(X - 1, 15, 3, 2, 0xFF1C1C7A);
  } else {
    b.rect(X - 2, 15, 4, 1, 0xFF1A2A7A);
    b.px(X - 3, 14, 0xFF1A2A7A);
    b.px(X + 2, 14, 0xFF1A2A7A);
  }
  b.px(X - 6, 14, 0xFF38C8F8);
  b.px(X + 6, 14, 0xFF38C8F8);
  if (pose == 'wave0' || pose == 'wave1') {
    b.cap(X + 7, 23, X + 12, 13, 2, P);
    b.ell(X + 12.5 + (pose == 'wave1' ? 1.6 : 0), 10, 2.3, 2.3, S);
  } else if (pose == 'dedo0' || pose == 'dedo1') {
    final d = pose == 'dedo1' ? 1 : -1;
    b.cap(X + 7, 23, X + 12, 15, 2, P);
    b.ell(X + 12 + d, 12.5, 2.6, 2.6, S);
    b.rect(X + 11 + d * 2, 4, 2, 7, S[2]);
    b.rect(X + 11 + d * 2, 4, 2, 1, S[4]);
    b.px(X + 10 + d * 2, 4, OUT);
    b.px(X + 13 + d * 2, 4, OUT);
  } // a wagging finger: not now
  else {
    b.cap(X + 8, 23, X + 10, 33, 2, P);
    b.ell(X + 10, 35.5, 2.1, 2.1, S);
  }
  if (pose == 'offer') {
    b.cap(X - 7, 24, X - 16, 27, 2, P);
    b.ell(X - 18.5, 27, 2.3, 2.3, S);
  } else if (pose == 'bless') {
    b.cap(X - 7, 23, X - 15, 19, 2, P);
    b.ell(X - 17.5, 18, 2.3, 2.3, S);
  } else {
    b.cap(X - 8, 23, X - 10, 33, 2, P);
    b.ell(X - 10, 35.5, 2.1, 2.1, S);
  }
  return b.outline().done();
}

// engine.js: mkDog
Sprite mkDog(bool wag) {
  final b = Buf(68, 50), D = RP.orng, C = RP.cream;
  const legs = [
    [14, 30],
    [22, 31],
    [40, 30],
    [48, 31],
  ];
  for (var i = 0; i < legs.length; i++) {
    final q = legs[i];
    b.rect(q[0], q[1], 5, 14, i % 2 != 0 ? D[2] : D[1]);
    b.ell(q[0] + 3, 45, 4, 2.2, [C[2]]);
  }
  b.cap(11, 22, wag ? 4 : 7, wag ? 9 : 7, 2, D);
  b.ell(30, 26, 20, 10, D);
  b.ell(30, 31, 13, 5, C);
  b.ell(24, 21, 5, 3.5, [D[0]]);
  b.ell(47, 19, 7, 8, D);
  b.ell(52, 13, 8.5, 8, D);
  b.ell(60, 16, 5.5, 4, C);
  b.rect(63, 13, 3, 3, 0xFF0A1420);
  b.line(56, 19, 62, 19, OUT);
  b.rect(58, 20, 3, 4, RP.red[3]);
  b.rect(53, 10, 2, 2, 0xFF0A1420);
  b.px(53, 10, 0xFFFFFFFF);
  b.ell(46, 11, 3.5, 7.5, [D[0]]);
  b.rect(44, 23, 3, 7, RP.red[2]);
  b.px(45, 30, RP.yel[2]);
  return b.outline().done();
}

// engine.js: mkTree
Sprite mkTree() {
  final b = Buf(48, 62);
  b.grad(21, 34, 7, 25, RP.wood.reversed.toList(), true);
  b.rect(19, 57, 3, 2, RP.wood[1]);
  b.rect(28, 57, 3, 2, RP.wood[0]);
  for (final e in const [
    [24, 24, 17, 13],
    [13, 28, 10, 8],
    [35, 28, 10, 8],
    [24, 13, 12, 10],
    [16, 18, 9, 8],
    [32, 17, 9, 8],
  ]) {
    b.ell(e[0], e[1], e[2], e[3], RP.grn);
  }
  for (final p in const [
    [14, 22],
    [30, 12],
    [36, 26],
    [20, 30],
  ]) {
    b.px(p[0], p[1], RP.red[3]);
  }
  return b.outline().done();
}

// engine.js: mkPalm
Sprite mkPalm() {
  final b = Buf(56, 74);
  for (var i = 0; i <= 44; i++) {
    final t = i / 44, x = 26 + math.sin(t * 1.6) * 4, y = 70 - i;
    b.ell(x, y, 2.6 - t * .6, 1.6, i % 4 < 1 ? [RP.wood[0]] : RP.wood);
  }
  for (var k = 0; k < 7; k++) {
    final a = -2.9 + k * .45;
    double x = 30, y = 25, vx = math.cos(a) * 2.1, vy = math.sin(a) * 2.1;
    for (var i = 0; i < 12; i++) {
      b.ell(x, y, 3.2 - i * .2, 2.2 - i * .12, RP.grn);
      x += vx;
      y += vy;
      vy += .28;
    }
  }
  b.ell(28, 27, 2.2, 2.2, RP.wood);
  b.ell(32, 27, 2, 2, RP.wood);
  return b.outline().done();
}

// engine.js: mkBall
Sprite mkBall() {
  final b = Buf(22, 22);
  b.ell(11, 11, 9, 9, RP.red);
  b.rect(7, 6, 2, 2, 0xFFFFFFFF);
  b.rect(6, 8, 1, 2, 0xFFFFFFFF);
  for (var i = 3; i < 19; i++) {
    b.px(i, 12 + (math.sin(i / 3) + 0.5).floor(), RP.yel[3]);
  }
  return b.outline().done();
}

// engine.js: mkCup
Sprite mkCup() {
  final b = Buf(22, 30);
  b.rect(5, 7, 12, 20, 0xFFFFF4EA);
  b.grad(6, 10, 10, 16, [RP.orng[4], RP.orng[3], RP.orng[2]]);
  b.rect(6, 9, 10, 1, 0xFFD0F4FF);
  b.rect(15, 8, 1, 18, 0xFFFFFFFF);
  b.line(12, 1, 10, 13, RP.red[2]);
  b.line(13, 1, 11, 13, 0xFFFFFFFF);
  b.ell(5, 7, 4, 4, RP.orng);
  b.rect(4, 6, 2, 2, 0xFFD0F4FF);
  return b.outline().done();
}

// engine.js: mkBush
Sprite mkBush() {
  final b = Buf(34, 22);
  b.ell(12, 13, 10, 8, RP.grn);
  b.ell(23, 14, 9, 7, RP.grn);
  b.ell(17, 9, 8, 7, RP.grn);
  for (final p in const [
    [10, 9],
    [22, 11],
    [16, 5],
  ]) {
    b.px(p[0], p[1], 0xFFB88FFF);
  }
  return b.outline().done();
}

// engine.js: mkPot
Sprite mkPot() {
  final b = Buf(22, 30);
  b.ell(11, 9, 7, 6, RP.grn);
  b.ell(6, 13, 5, 4, RP.grn);
  b.ell(16, 13, 5, 4, RP.grn);
  b.rect(6, 18, 10, 3, RP.orng[2]);
  b.rect(7, 21, 8, 6, RP.orng[1]);
  b.rect(6, 18, 10, 1, RP.orng[3]);
  return b.outline().done();
}

/* ---- shared scene pieces ---- */

// engine.js: sky
void sky(Buf b, num W, num hz) {
  b.grad(0, 0, W, hz, RP.sky);
  b.ell(W - 30, 17, 8, 8, RP.yel.sublist(2));
  for (final c in const [
    [36, 16, 1],
    [112, 9, .7],
    [168, 26, .8],
  ]) {
    final s = c[2];
    b.ell(c[0], c[1], 13 * s, 5 * s, RP.cloud);
    b.ell(c[0] - 9 * s, c[1] + 2, 8 * s, 4 * s, RP.cloud);
    b.ell(c[0] + 10 * s, c[1] + 2, 9 * s, 4 * s, RP.cloud);
    b.ell(c[0] + 2, c[1] - 4 * s, 7 * s, 5 * s, RP.cloud);
  }
  for (var x = 0; x < W; x++) {
    final y1 =
        (hz - 17 - 7 * math.sin(x * .03 + 1) - 4 * math.sin(x * .08) + 0.5)
            .floor();
    for (var y = y1; y < hz; y++) {
      b.px(
        x,
        y,
        y - y1 < 2
            ? 0xFFBCD09C
            : bay(x, y) < (y - y1) / 30
            ? 0xFF909E5E
            : 0xFFA2B474,
      );
    }
    final y2 =
        (hz - 7 - 4 * math.sin(x * .05 + 3) - 2 * math.sin(x * .13) + 0.5)
            .floor();
    for (var y = y2; y < hz; y++) {
      b.px(x, y, y - y2 < 1 ? 0xFF7ACB7C : 0xFF5E9E4E);
    }
  }
}

// engine.js: grass
void grass(Buf b, num y0, num W, num H) {
  b.grad(0, y0, W, H - y0, RP.grass);
  for (var i = 0; i < 220; i++) {
    final x = hs(i, 11) * W / 100 + hs(i, 7) % 3,
        y = y0 + 2 + hs(i, 13) * (H - y0 - 3) / 100;
    b.px(x, y, RP.grn[1]);
    b.px(x + 1, y - 1, RP.grn[4]);
  }
  for (var i = 0; i < 26; i++) {
    final x = hs(i, 21) * W / 100, y = y0 + 4 + hs(i, 23) * (H - y0 - 8) / 100;
    b.px(x, y, const [0xFF70E0FF, 0xFFB88FFF, 0xFFFFFFFF][i % 3]);
    b.px(x, y + 1, RP.grn[0]);
  }
}

/* ---- icons, bubbles, pointers ---- */

// engine.js: face
void face(Ctx c, num cx, num cy, bool ok) {
  for (final r in const [
    [-1, -3, 3],
    [-2, -2, 5],
    [-3, -1, 7],
    [-3, 0, 7],
    [-3, 1, 7],
    [-2, 2, 5],
    [-1, 3, 3],
  ]) {
    fr(c, cx + r[0], cy + r[1], r[2], 1, ok ? 0xFF4AD8FF : 0xFFF0B47C);
  }
  fr(c, cx - 2, cy - 1, 1, 1, OUT);
  fr(c, cx + 1, cy - 1, 1, 1, OUT);
  if (ok) {
    fr(c, cx - 2, cy + 1, 1, 1, OUT);
    fr(c, cx - 1, cy + 2, 3, 1, OUT);
    fr(c, cx + 2, cy + 1, 1, 1, OUT);
  } else {
    fr(c, cx - 2, cy + 2, 1, 1, OUT);
    fr(c, cx - 1, cy + 1, 3, 1, OUT);
    fr(c, cx + 2, cy + 2, 1, 1, OUT);
  }
}

// engine.js: pointer
void pointer(Ctx c, List<num> b, int f) {
  final x = b[0], y = b[1], w = b[2], h = b[3], k = 4, col = 0xFF40E0FF;
  for (final p in [
    [x - 2, y - 2, 1, 1],
    [x + w + 1, y - 2, -1, 1],
    [x - 2, y + h + 1, 1, -1],
    [x + w + 1, y + h + 1, -1, -1],
  ]) {
    fr(
      c,
      math.min<num>(p[0], p[0] + p[2] * k),
      p[1] - (p[3] < 0 ? 0 : 0),
      k + 1,
      2,
      OUT,
    );
    fr(
      c,
      p[0] - (p[2] < 0 ? 1 : 0),
      math.min<num>(p[1], p[1] + p[3] * k),
      2,
      k + 1,
      OUT,
    );
    fr(
      c,
      math.min<num>(p[0], p[0] + p[2] * (k - 1)),
      p[1] + (p[3] < 0 ? 0 : 0),
      k,
      1,
      col,
    );
    fr(
      c,
      p[0] - (p[2] < 0 ? 0 : 0),
      math.min<num>(p[1], p[1] + p[3] * (k - 1)),
      1,
      k,
      col,
    );
  }
  final ax = (x + w / 2 + 0.5).floor(), ay = y - 12 - f.remainder(2) * 2;
  const arrow = [
    [-1, 0, 3],
    [-1, 1, 3],
    [-1, 2, 3],
    [-3, 3, 7],
    [-2, 4, 5],
    [-1, 5, 3],
    [0, 6, 1],
  ];
  for (final r in arrow) {
    fr(c, ax + r[0] - 1, ay + r[1], r[2] + 2, 2, OUT);
  }
  for (final r in arrow) {
    fr(c, ax + r[0], ay + r[1], r[2], 1, col);
  }
}

// engine.js: sparks
void sparks(Ctx c, List<List<num>> pts, int f) {
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    if ((i + f).remainder(2) != 0) {
      fr(c, p[0], p[1] - 2, 1, 5, 0xFF40E0FF);
      fr(c, p[0] - 2, p[1], 5, 1, 0xFF40E0FF);
      fr(c, p[0], p[1], 1, 1, 0xFFFFFFFF);
    } else {
      fr(c, p[0], p[1], 1, 1, 0xFF40E0FF);
    }
  }
}

// engine.js: talk
void talk(Ctx c, num x, num y, int f, int dir) {
  for (var i = 0; i < 2 + f.remainder(2); i++) {
    fr(c, x + dir * i * 3 - 1, y - i * 2 - 1, 3, 5 + 4 * i, OUT);
  }
  for (var i = 0; i < 2 + f.remainder(2); i++) {
    fr(c, x + dir * i * 3, y - i * 2, 1, 3 + 4 * i, 0xFFFFFFFF);
  }
}

// engine.js: shadow
void shadow(Ctx c, num x, num y, num w) {
  for (var j = 0; j < 3; j++) {
    for (var i = j == 1 ? 0 : 2; i < w - (j == 1 ? 0 : 2); i++) {
      if ((i + j) % 2 == 0) fr(c, x + i, y + j, 1, 1, 0xFF2A5A1E);
    }
  }
}

/// What engine.js keeps in globals that change, as fields: the sprite cache `SP`, the glyph tables `GL` and `GC`
/// (scene files add glyphs to both: `GL.gota` in juego.js, `GL.sol` in balcon.js), and the colour cache `_rgb`. One
/// per game, so two games and two tests never share a cache.
///
/// Holds the functions that read them: `spr`, `rgb`, `coqui`, `glyph`, `bubble`, and `bgCasa` and `bgParque`
/// (which draw cached sprites on their own picture).
class SpriteLib {
  /// engine.js: `GL`, the pixel pictures of the icons: `#` the glyph's colour (`GC`), `o` the outline, `w` white,
  /// `b` blue, `.` nothing.
  final Map<String, List<String>> GL = {
    'heart': ['.##.##.', '#######', '#######', '.#####.', '..###..', '...#...'],
    'up': [
      '...#...',
      '..###..',
      '.#####.',
      '#######',
      '..###..',
      '..###..',
      '..###..',
    ],
    'go': [
      '...#...',
      '...##..',
      '######.',
      '#######',
      '######.',
      '...##..',
      '...#...',
    ],
    'ven': [
      '...#...',
      '..##...',
      '.######',
      '#######',
      '.######',
      '..##...',
      '...#...',
    ],
    'plus': [
      '..###..',
      '..###..',
      '#######',
      '#######',
      '#######',
      '..###..',
      '..###..',
    ],
    'hand': [
      '#.#.#..',
      '#.#.#..',
      '#.#.#.#',
      '#####.#',
      '######.',
      '.####..',
      '.####..',
    ],
    'q': ['.###.', '#...#', '....#', '...#.', '..#..', '.....', '..#..'],
    'eye': ['..ooooo..', '.owbbbwo.', 'owwbbbwwo', '.owbbbwo.', '..ooooo..'],
  };

  /// engine.js: `GC`, the colour of the `#` pixels of each glyph.
  final Map<String, int> GC = {
    'heart': 0xFF3A40E0,
    'up': 0xFFD06C2E,
    'go': 0xFF489A2E,
    'ven': 0xFFD06C2E,
    'plus': 0xFF489A2E,
    'hand': 0xFF487AB8,
    'q': 0xFF10182A,
  };

  /// engine.js: `SP`, the sprite cache, keyed by a string.
  final Map<String, Sprite> SP = {};

  /// engine.js: `_rgb`.
  final Map<String, List<int>> _rgb = {};

  // engine.js: rgb
  /// `"#RRGGBB"` as [r, g, b]. Nothing in this library needs it (a colour is already an int); it is here for
  /// the scene files that hold a colour as text.
  List<int> rgb(String h) => _rgb[h] ??= [
    int.parse(h.substring(1, 3), radix: 16),
    int.parse(h.substring(3, 5), radix: 16),
    int.parse(h.substring(5, 7), radix: 16),
  ];

  // engine.js: spr
  Sprite spr(String k, Sprite Function() fn) => SP[k] ??= fn();

  // engine.js: coqui
  Sprite coqui(num s, int f, bool open) {
    final bl = f.remainder(19) == 0 ? 1 : 0;
    return spr('cq${jsNum(s)}$bl${open ? 1 : 0}', () => mkCoqui(s, bl, open));
  }

  // engine.js: glyph
  void glyph(Ctx c, String k, num x, num y) {
    final rows = GL[k]!;
    for (var j = 0; j < rows.length; j++) {
      final rw = rows[j];
      for (var i = 0; i < rw.length; i++) {
        final ch = rw[i];
        if (ch != '.') {
          fr(
            c,
            x + i,
            y + j,
            1,
            1,
            ch == '#'
                ? GC[k]!
                : ch == 'o'
                ? OUT
                : ch == 'w'
                ? _white
                : _glyphBlue,
          );
        }
      }
    }
  }

  // engine.js: bubble
  // a speech bubble holding icons; tx,ty is where its tail points
  void bubble(Ctx c, List<String> list, num tx, num ty, int f) {
    final ws = [
          for (final k in list) k == 'ok' || k == 'sad' ? 7 : GL[k]![0].length,
        ],
        w = ws.fold<int>(3, (a, b) => a + b + 3),
        h = 13,
        x = (tx - w / 2 + 0.5).floor(),
        y = ty - h - 5 - f.remainder(2);
    fr(c, x - 1, y - 1, w + 2, h + 2, OUT);
    fr(c, x, y, w, h, _white);
    fr(c, x - 1, y - 1, 1, 1, 0x00000000);
    fr(c, tx - 2, y + h, 5, 1, _white);
    fr(c, tx - 3, y + h, 1, 2, OUT);
    fr(c, tx + 3, y + h, 1, 2, OUT);
    fr(c, tx - 2, y + h + 1, 5, 1, _white);
    fr(c, tx - 2, y + h + 2, 5, 1, OUT);
    fr(c, tx - 1, y + h + 2, 3, 1, _white);
    fr(c, tx - 1, y + h + 3, 3, 1, OUT);
    var px = x + 3;
    for (var i = 0; i < list.length; i++) {
      final k = list[i];
      if (k == 'ok' || k == 'sad') {
        face(c, px + 3, y + 6, k == 'ok');
      } else {
        glyph(c, k, px, y + ((h - GL[k]!.length) / 2).floor());
      }
      px += ws[i] + 3;
    }
  }

  /* ---- Casa ---- */

  // engine.js: bgCasa
  Sprite bgCasa(bool open) {
    final b = Buf(240, 150),
        T = RP.teal,
        C = RP.cream,
        W = RP.wood,
        ST = RP.stone;
    sky(b, 240, 96);
    grass(b, 96, 240, 150);
    for (var y = 118; y < 150; y++) {
      final t = (y - 118) / 31,
          xl = (142 - 108 * t + 0.5).floor(),
          xr = (188 - 38 * t + 0.5).floor();
      for (var x = xl; x <= xr; x++) {
        b.px(
          x,
          y,
          x == xl || x == xr
              ? ST[0]
              : (y % 6 == 0 || (x + (y / 6).floor() * 7) % 13 == 0)
              ? ST[1]
              : hs(x, y) < 8
              ? ST[4]
              : ST[3],
        );
      }
    }
    b.grad(70, 44, 144, 60, [T[3], T[3], T[2], T[2], T[1]], true);
    for (var y = 49; y < 104; y += 5) {
      for (var x = 70; x < 214; x++) {
        b.px(x, y, T[1]);
      }
    }
    for (var y = 44; y < 51; y++) {
      for (var x = 70; x < 214; x++) {
        if (bay(x, y) < (51 - y) / 8) b.px(x, y, T[0]);
      }
    }
    b.rect(69, 44, 1, 60, 0xFF4C4A13);
    b.rect(214, 44, 1, 60, 0xFF4C4A13);
    for (var y = 16; y < 42; y++) {
      final t = (y - 16) / 25,
          xl = (88 - 30 * t + 0.5).floor(),
          xr = (196 + 30 * t + 0.5).floor(),
          k = (y - 16) % 5,
          rw = ((y - 16) / 5).floor();
      for (var x = xl; x <= xr; x++) {
        b.px(
          x,
          y,
          x == xl || x == xr || y == 41
              ? 0xFF10124A
              : y == 16
              ? RP.red[4]
              : k == 4
              ? RP.red[0]
              : (x + rw * 4) % 8 == 0
              ? RP.red[1]
              : bay(x, y) < t * .8
              ? RP.red[2]
              : RP.red[3],
        );
      }
    }
    b.rect(58, 42, 169, 3, C[3]);
    b.rect(58, 44, 169, 1, C[1]);
    b.frame(57, 41, 171, 4, OUT);
    b.rect(86, 58, 7, 26, 0xFFFFFFFF);
    b.rect(131, 58, 7, 26, 0xFFFFFFFF);
    for (var y = 60; y < 84; y += 3) {
      b.rect(86, y, 7, 1, ST[2]);
      b.rect(131, y, 7, 1, ST[2]);
    }
    b.frame(85, 57, 9, 28, OUT);
    b.frame(130, 57, 9, 28, OUT);
    b.rect(94, 58, 36, 26, C[3]);
    b.grad(97, 61, 30, 20, [RP.blue[4], RP.blue[3], RP.blue[2]]);
    b.rect(111, 61, 2, 20, C[3]);
    b.rect(97, 70, 30, 2, C[3]);
    for (var i = 0; i < 7; i++) {
      b.px(100 + i, 67 - i, 0xFFFFFFFF);
      b.px(116 + i, 78 - i, 0xFFFFFFFF);
    }
    b.frame(93, 57, 38, 28, OUT);
    b.frame(96, 60, 32, 22, C[0]);
    b.rect(90, 86, 44, 5, W[2]);
    b.rect(90, 86, 44, 1, W[4]);
    b.frame(89, 85, 46, 7, OUT);
    for (var i = 0; i < 9; i++) {
      b.ell(93 + i * 4.8, 83.5, 2.2, 2.2, [
        const [0xFFB88FFF, 0xFF70E0FF, 0xFF4A58F4][i % 3],
      ]);
      b.px(93 + i * 4.8, 85, RP.grn[1]);
    }
    b.rect(150, 50, 32, 54, C[3]);
    b.frame(149, 49, 34, 56, OUT);
    if (open) {
      b.grad(153, 53, 24, 51, [0xFF060A14, 0xFF0C1422, 0xFF1A2032]);
      b.rect(177, 53, 4, 51, W[2]);
      b.rect(177, 53, 1, 51, W[4]);
      b.frame(152, 52, 26, 53, OUT);
    } else {
      b.grad(153, 53, 26, 51, [W[3], W[2], W[2], W[1]], true);
      b.frame(152, 52, 28, 53, OUT);
      for (final p in const [
        [156, 57, 20, 18],
        [156, 80, 20, 20],
      ]) {
        b.frame(p[0], p[1], p[2], p[3], W[0]);
        b.rect(p[0] + 1, p[1] + 1, p[2] - 2, 1, W[4]);
        b.rect(p[0] + 1, p[1] + 1, 1, p[3] - 2, W[4]);
      }
      b.rect(174, 77, 2, 2, RP.yel[2]);
    }
    b.rect(187, 60, 4, 6, RP.yel[3]);
    b.frame(186, 59, 6, 8, OUT);
    b.rect(188, 57, 2, 2, ST[0]);
    b.rect(62, 104, 160, 6, ST[3]);
    b.rect(62, 104, 160, 1, ST[4]);
    b.rect(62, 109, 160, 1, ST[1]);
    b.frame(61, 103, 162, 8, OUT);
    b.rect(146, 111, 38, 4, ST[2]);
    b.rect(146, 111, 38, 1, ST[4]);
    b.rect(142, 115, 46, 4, ST[3]);
    b.rect(142, 115, 46, 1, ST[4]);
    b.rect(142, 118, 46, 1, ST[0]);
    b.rect(146, 114, 38, 1, ST[0]);
    b.rect(153, 104, 24, 2, RP.red[1]);
    final cv = b.done(), c = b.cx;
    c.drawImage(spr('palm', mkPalm), 2, 34);
    c.drawImage(spr('bush', mkBush), 206, 92);
    c.drawImage(spr('pot', mkPot), 192, 78);
    c.drawImage(spr('bush', mkBush), 40, 96);
    return cv;
  }

  /* ---- Parque ---- */

  // engine.js: bgParque
  // (the old code also declares `ST=RP.stone` here and never uses it)
  Sprite bgParque() {
    final b = Buf(240, 150);
    sky(b, 240, 84);
    for (var x = 0; x < 240; x++) {
      final h =
          7 + (3 * math.sin(x * .21) + 2 * math.sin(x * .07) + 0.5).floor();
      for (var y = 84 - h; y < 86; y++) {
        b.px(
          x,
          y,
          y == 84 - h
              ? RP.grn[3]
              : bay(x, y) < .4
              ? RP.grn[1]
              : RP.grn[2],
        );
      }
    }
    grass(b, 86, 240, 150);
    for (var y = 98; y < 150; y++) {
      final t = (y - 98) / 52,
          xc = 118 + math.sin(t * 2.2) * 34,
          hw = 8 + t * 10;
      for (var x = (xc - hw + 0.5).floor(); x <= (xc + hw + 0.5).floor(); x++) {
        b.px(
          x,
          y,
          (x - xc).abs() > hw - 1
              ? RP.orng[1]
              : hs(x, y) < 10
              ? RP.cream[1]
              : RP.cream[2],
        );
      }
    }
    for (final p in const [
      [162, 112],
      [212, 112],
    ]) {
      b.cap(p[0] - 5, p[1], p[0], 58, 1.6, RP.red);
      b.cap(p[0] + 5, p[1], p[0], 58, 1.6, RP.red);
    }
    b.rect(158, 56, 58, 4, RP.red[2]);
    b.rect(158, 56, 58, 1, RP.red[4]);
    b.rect(158, 59, 58, 1, RP.red[0]);
    b.frame(157, 55, 60, 6, OUT);
    b.rect(20, 104, 26, 3, RP.wood[3]);
    b.rect(20, 99, 26, 3, RP.wood[3]);
    b.rect(22, 102, 2, 10, RP.wood[1]);
    b.rect(42, 102, 2, 10, RP.wood[1]);
    b.frame(19, 98, 28, 5, OUT);
    b.frame(19, 103, 28, 5, OUT);
    final cv = b.done(), c = b.cx;
    c.drawImage(spr('tree', mkTree), 4, 28);
    c.drawImage(spr('bush', mkBush), 92, 74);
    c.drawImage(spr('bush', mkBush), -6, 124);
    return cv;
  }
}
