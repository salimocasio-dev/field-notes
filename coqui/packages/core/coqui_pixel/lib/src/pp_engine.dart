// Pixel Plays engine by AmirMushich, MIT licence (github.com/amirmushichge/pixel-plays). Changed for Coquí: canvas size and scale come from PP_SCENE.
//
// MIT License
//
// Copyright (c) 2026 Amir Mushich
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Changed for Coquí: ported from JavaScript to Dart (pixel/pp-engine.js); the old globals are fields, `STILL` is the `still` argument.
//
// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/int32.dart';

/// What `project` gives: the screen position and the depth of a world point.
typedef Projected = ({double sx, double sy, double d});

/// What `unproject` gives: the ground point (z = 0) under a screen position.
typedef Unprojected = ({double x, double y});

/// The colour a capsule has at a height z (pp-engine.js: `colorOf`). A colour is [r, g, b].
typedef ColorOf = List<num> Function(double z);

/// What `figure` calls for each bone (pp-engine.js: `addBone`).
typedef AddBone = void Function(
  List<num> a,
  List<num> b,
  num r0,
  num r1,
  ColorOf f,
);

/// A figure's colours (pp-engine.js: `palette`): shirt, stripe, legs, skin, hair, each [r, g, b].
typedef FigurePalette = Map<String, List<num>>;

/// A figure's pose (pp-engine.js: `pose`): z, scale, crouch, lean, stance, armR, armL, all optional.
typedef Pose = Map<String, num>;

/// One blade of grass that sways (pp-engine.js: an entry of `tufts`).
class Tuft {
  Tuft({
    required this.ix,
    required this.iy,
    required this.i,
    required this.height,
    required this.base,
    required this.phase,
    required this.bloom,
  });

  final int ix, iy, i, height, base;
  final double phase;

  /// The flower's colour, or 0 for none.
  final int bloom;
}

/// One glint on a set's water (set-kit.js `waterPixel`: an entry of `look.glints`): the pixel `i` at `ix, iy`, and the
/// phase of its cycle. [drawGlints] shows it each frame for part of its cycle.
class Glint {
  Glint({
    required this.i,
    required this.ix,
    required this.iy,
    required this.phase,
  });

  final int i, ix, iy;
  final double phase;
}

// set-kit.js: drawGlints (order 34b)
/// The glints on the water, each frame (wind time [t], stepped as the grass: 8 a second, still when the OS asks for
/// reduced motion): a glint shows 1 or 3 px of [color] on the surface for part of its cycle, and only where the surface
/// itself shows (the frame's depth `zb` is still [refZ]'s there: nothing stands over it).
void drawGlints(
  PpEngine e,
  List<Glint> glints,
  double t,
  Float32List refZ,
  int color,
) {
  final zb = e.zb, pix = e.pix, W = e.W;
  for (final gl in glints) {
    final s = math.sin(t * 1.7 + gl.phase);
    if (s < .35) continue;
    final w = s > .8 ? 1 : 0;
    for (var dx = -w; dx <= w; dx++) {
      final j = gl.i + dx;
      if (gl.ix + dx < 0 || gl.ix + dx >= W || zb[j] != refZ[j]) continue;
      pix[j] = color;
    }
  }
}

/// One leaf of a tree that sways (pp-engine.js: an entry of `leaves`). `pixels` holds ix, iy, depth, colour for
/// each pixel of the leaf, four numbers after four. mapa.js adds `owner` and `orig` to a leaf.
class Leaf {
  Leaf({
    required this.x,
    required this.y,
    required this.z,
    required this.k,
    required this.r,
    required this.pixels,
  });

  final double x, y, z, r;
  final num k;
  final List<num> pixels;
  int? owner;
  List<num>? orig;
}

/// Port of pixel/pp-engine.js. Every function there becomes a method with the same name and parameters.
///
/// The old file's globals are fields. `SCENE` (`PP_SCENE`) is the constructor's arguments, `STILL` is [still].
/// The caller reads [pix]. The canvas lines of the old file (`canvas`, `ctx`, `image`, `fit`) have no port: the
/// picture is the `Uint32List` [pix].
class PpEngine {
  PpEngine({
    required int w,
    required int h,
    required double s,
    double originX = 0,
    double originY = 0,
    double shadowX = 1.3,
    double shadowY = -.12,
    bool still = false,
  }) : W = w,
       H = h,
       S = s,
       OX = w / 2 + originX,
       OY = h / 2 + originY,
       SHADOW_X = shadowX,
       SHADOW_Y = shadowY,
       STILL = still,
       pix = Uint32List(w * h),
       zb = Float32List(w * h),
       bakedPix = Uint32List(w * h),
       bakedZ = Float32List(w * h),
       ground = Uint8List(w * h),
       shadowMask = Uint8List(w * h),
       groundZ = Float32List(w * h),
       kinds = Uint8List(w * h),
       staticShadow = Uint8List(w * h);

  final int W, H;
  final double S;
  final double SIN = .5;
  final double COS = math.sqrt(3) / 2;
  final double R2 = math.sqrt2;
  final double OX, OY;
  final double SHADOW_X, SHADOW_Y;

  final Uint32List pix;
  final Float32List zb;
  final Uint32List bakedPix;
  final Float32List bakedZ;
  final Uint8List ground;
  final Uint8List shadowMask;
  final Float32List groundZ;

  static const List<double> _bayer = [
    (0 + .5) / 16,
    (8 + .5) / 16,
    (2 + .5) / 16,
    (10 + .5) / 16,
    (12 + .5) / 16,
    (4 + .5) / 16,
    (14 + .5) / 16,
    (6 + .5) / 16,
    (3 + .5) / 16,
    (11 + .5) / 16,
    (1 + .5) / 16,
    (9 + .5) / 16,
    (15 + .5) / 16,
    (7 + .5) / 16,
    (13 + .5) / 16,
    (5 + .5) / 16,
  ];
  final List<double> BAYER = _bayer;
  final List<num> COOL = const [46, 38, 84], WARM = const [255, 232, 180];
  final List<num> SHOE = const [226, 222, 212], BARK = const [92, 74, 60];
  final List<List<int>> GRASS = const [
    [34, 62, 50],
    [52, 88, 52],
    [82, 118, 54],
    [124, 146, 62],
    [168, 172, 76],
  ];
  late final double GRADIENT_Y = COS / (S * SIN);
  final double EDGE = .28;

  // pp-engine.js: ramps (a WeakMap by the colour's identity; an Expando is the same)
  final Expando<List<int>> _ramps = Expando<List<int>>();

  // pp-engine.js: rgb
  int rgb(num r, num g, num b) =>
      (0xFF000000 |
          (math.min(255, toInt32(b)) << 16) |
          (math.min(255, toInt32(g)) << 8) |
          math.min(255, toInt32(r))) &
      0xFFFFFFFF;

  // pp-engine.js: rampOf. A hue-shifted ramp: shadows drift to violet, lights drift to warm yellow
  List<int> rampOf(List<num> c) {
    var ramp = _ramps[c];
    if (ramp != null) return ramp;
    int mix(double m, List<num> tint, double k) => rgb(
      lerp(c[0] * m, tint[0], k),
      lerp(c[1] * m, tint[1], k),
      lerp(c[2] * m, tint[2], k),
    );
    ramp = [
      mix(.4, COOL, .34),
      mix(.62, COOL, .18),
      mix(.84, COOL, .05),
      mix(1, WARM, 0),
      mix(1.1, WARM, .22),
    ];
    _ramps[c] = ramp;
    return ramp;
  }

  // pp-engine.js: bayerAt
  double bayerAt(int ix, int iy) => BAYER[(iy & 3) * 4 + (ix & 3)];

  // pp-engine.js: tint
  void tint(int i, double r, double g, double b) {
    final c = pix[i];
    pix[i] = rgb((c & 255) * r, (c >> 8 & 255) * g, (c >> 16 & 255) * b);
  }

  // pp-engine.js: clamp. Math.max(a, Math.min(b, v)); with ints it gives an int, with doubles a double
  T clamp<T extends num>(T v, T a, T b) => math.max(a, math.min(b, v));

  // pp-engine.js: lerp
  double lerp(num a, num b, num t) => (a + (b - a) * t).toDouble();

  // pp-engine.js: ease
  double ease(num t) => (t * t * (3 - 2 * t)).toDouble();

  // pp-engine.js: hash
  double hash(num x, num y) {
    final s = math.sin(x * 127.1 + y * 311.7) * 43758.5453;
    return s - s.floorToDouble();
  }

  // pp-engine.js: noise
  double noise(num x, num y) {
    final ix = x.floorToDouble(),
        iy = y.floorToDouble(),
        fx = ease(x - ix),
        fy = ease(y - iy);
    return lerp(
      lerp(hash(ix, iy), hash(ix + 1, iy), fx),
      lerp(hash(ix, iy + 1), hash(ix + 1, iy + 1), fx),
      fy,
    );
  }

  // pp-engine.js: project
  Projected project(num x, num y, num z) {
    final u = (x - y) / R2, v = (x + y) / R2;
    return (
      sx: OX + u * S,
      sy: OY + (v * SIN - z * COS) * S,
      d: v * COS + z * SIN,
    );
  }

  // pp-engine.js: unproject
  Unprojected unproject(num sx, num sy) {
    final u = (sx - OX) / S, v = (sy - OY) / (S * SIN);
    return (x: (u + v) / R2, y: (v - u) / R2);
  }

  /// When set, `sphere` records pixels instead of drawing them: ix, iy, depth, colour, four numbers a pixel.
  List<num>? capture; // pp-engine.js: capture

  // pp-engine.js: sphere
  void sphere(num x, num y, num z, num r, List<num> c, [String? mode]) {
    final ramp = rampOf(c);
    final p = project(x, y, z), rp = math.max(r * S, .75);
    final y0 = math.max(0, (p.sy - rp).floor()),
        y1 = math.min(H - 1, (p.sy + rp).ceil());
    final x0 = math.max(0, (p.sx - rp).floor()),
        x1 = math.min(W - 1, (p.sx + rp).ceil());
    for (var iy = y0; iy <= y1; iy++) {
      for (var ix = x0; ix <= x1; ix++) {
        final dx = (ix + .5 - p.sx) / rp,
            dy = (iy + .5 - p.sy) / rp,
            nn = dx * dx + dy * dy;
        if (nn > 1) continue;
        final nz = math.sqrt(1 - nn), d = p.d + r * nz, i = iy * W + ix;
        if (d <= zb[i]) continue;
        var l = clamp<double>(-.55 * dx - .6 * dy + .58 * nz, 0, 1);
        if (mode == 'rough') l += (hash(ix, iy) - .5) * .55;
        if (dy > .35) {
          l = math.max(l, .12 + dy * .24); // warm light bouncing off the ground
        }
        final cap = capture;
        if (cap != null) {
          cap.addAll([
            ix,
            iy,
            d,
            ramp[clamp(
              (l * 4.4 + .2 + (bayerAt(ix, iy) - .5) * .7).floor(),
              0,
              4,
            )],
          ]);
          continue;
        }
        zb[i] = d;
        if (mode == 'gloss' && l > .9) {
          pix[i] = rgb(255, 250, 232);
          continue;
        }
        // figures get flat bands with no dither, so they read as sharp shapes against the textured ground
        if (mode == 'solid') {
          pix[i] = ramp[clamp((l * 4.4 + .2).floor(), 1, 4)];
          continue;
        }
        pix[i] =
            ramp[clamp(
              (l * 4.4 + .2 + (bayerAt(ix, iy) - .5) * .7).floor(),
              0,
              4,
            )];
      }
    }
  }

  // pp-engine.js: capsule
  void capsule(
    List<num> a,
    List<num> b,
    num r0,
    num r1,
    ColorOf colorOf, [
    String? mode,
  ]) {
    final len = _hypot3(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
    final n = math.max(1, (len / (math.min(r0, r1) * .45)).ceil());
    for (var k = 0; k <= n; k++) {
      final t = k / n, z = lerp(a[2], b[2], t);
      sphere(
        lerp(a[0], b[0], t),
        lerp(a[1], b[1], t),
        z,
        lerp(r0, r1, t),
        colorOf(z),
        mode,
      );
    }
  }

  // pp-engine.js: box
  void box(
    num x0,
    num y0,
    num z0,
    num x1,
    num y1,
    num z1,
    List<num> c, [
    num seed = 0,
  ]) {
    final ramp = rampOf(c);
    void paint(num x, num y, num z, double base, double grain) {
      final p = project(x, y, z), ix = p.sx.truncate(), iy = p.sy.truncate();
      if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
      final i = iy * W + ix;
      if (p.d <= zb[i]) return;
      zb[i] = p.d;
      pix[i] =
          ramp[clamp(
            (base + (grain - .5) * 1.3 + (bayerAt(ix, iy) - .5) * .5).floor(),
            0,
            4,
          )];
    }

    const step = .045;
    final longX = x1 - x0 >= y1 - y0;
    for (num a = x0; a <= x1; a += step) {
      for (num b = y0; b <= y1; b += step) {
        paint(
          a,
          b,
          z1,
          3.4,
          longX ? noise(a * .8 + seed, b * 9) : noise(a * 9, b * .8 + seed),
        );
      }
    }
    for (num a = x0; a <= x1; a += step) {
      for (num b = z0; b <= z1; b += step) {
        paint(a, y1, b, 2.3, noise(a * .8 + seed, b * 9));
      }
    }
    for (num a = y0; a <= y1; a += step) {
      for (num b = z0; b <= z1; b += step) {
        paint(x1, a, b, 1.2, noise(a * .8 + seed, b * 9));
      }
    }
  }

  // pp-engine.js: castShadow
  void castShadow(
    num x,
    num y,
    num z,
    num r, [
    int strength = 1,
    double dither = .4,
  ]) {
    final p = project(x + SHADOW_X * z, y + SHADOW_Y * z, 0);
    final rx = r * S * 1.05, ry = rx * SIN + 1;
    final y0 = math.max(0, (p.sy - ry).floor()),
        y1 = math.min(H - 1, (p.sy + ry).ceil());
    final x0 = math.max(0, (p.sx - rx).floor()),
        x1 = math.min(W - 1, (p.sx + rx).ceil());
    for (var iy = y0; iy <= y1; iy++) {
      for (var ix = x0; ix <= x1; ix++) {
        final dx = (ix + .5 - p.sx) / rx, dy = (iy + .5 - p.sy) / ry;
        if (dx * dx + dy * dy + (bayerAt(ix, iy) - .5) * dither > 1) continue;
        final i = iy * W + ix;
        if (shadowMask[i] < strength) shadowMask[i] = strength;
      }
    }
  }

  // pp-engine.js: applyShadows
  void applyShadows(Float32List refZ) {
    for (var i = 0; i < pix.length; i++) {
      final s = shadowMask[i];
      if (s == 0) continue;
      shadowMask[i] = 0;
      if (ground[i] == 0 || zb[i] != refZ[i]) continue;
      if (s == 1) {
        tint(i, .54, .52, .72);
      } else {
        tint(i, .36, .34, .56);
      }
    }
  }

  // pp-engine.js: shadeEdges. Pixel-art edges from the depth buffer. The ground is never touched, so nothing
  // halos around a figure: an object darkens its own silhouette against the ground, and gets a warm rim only
  // over another object
  void shadeEdges() {
    for (var iy = 1; iy < H - 1; iy++) {
      for (var ix = 1; ix < W - 1; ix++) {
        final i = iy * W + ix, d = zb[i];
        if (d < -1e8 || d == groundZ[i]) continue;
        final a = i - W, b = i + W, c = i - 1, e = i + 1;
        if (zb[a] == groundZ[a] ||
            zb[b] == groundZ[b] ||
            zb[c] == groundZ[c] ||
            zb[e] == groundZ[e]) {
          tint(i, .68, .66, .76);
        } else if (d - zb[a] - GRADIENT_Y > EDGE || d - zb[c] > EDGE) {
          final p = pix[i];
          pix[i] = rgb(
            lerp(p & 255, WARM[0], .3),
            lerp(p >> 8 & 255, WARM[1], .3),
            lerp(p >> 16 & 255, WARM[2], .22),
          );
        } else if (zb[e] - d > EDGE || zb[b] - GRADIENT_Y - d > EDGE) {
          tint(i, .74, .72, .82);
        }
      }
    }
  }

  final int KIND_NONE = 0, KIND_GRASS = 3;
  final Uint8List kinds;

  // ---------- wind ----------
  final int WIND_FPS = 8; // stepped on purpose: the sway should feel hand-animated, not simulated

  /// The OS asks for reduced motion: everything stands still (the old `STILL`, `matchMedia`).
  final bool STILL;
  final List<Tuft> tufts = [];
  final List<Leaf> leaves = [];
  final Uint8List staticShadow;
  late final List<int> tuftLit = [for (final c in GRASS) rgb(c[0], c[1], c[2])];
  late final List<int> tuftDark = [
    for (final c in GRASS) rgb(c[0] * .54, c[1] * .52, c[2] * .72),
  ];

  /// The glints on a set's water that come and go each frame (set-kit.js `waterPixel` collects them, `drawGlints`
  /// draws them; campo-set.html keeps them in `LOOK.glints`, order 34b): kept on the engine as the tufts and the leaves
  /// are, so that a bake leaves them for the frame ([BakedSet] keeps them with its state). Empty for a set with no
  /// water, whose frames are drawn as before.
  final List<Glint> glints = [];

  /// The colour the [glints] are drawn in (campo-set.html: `GLINT`); 0 while there are none.
  int glintColour = 0;

  // pp-engine.js: growGrass
  void growGrass() {
    for (var iy = 3; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix;
        if (kinds[i] != KIND_GRASS || hash(ix * 3, iy * 5) > .17) continue;
        final height = 1 + (hash(ix, iy * 2) * 3).truncate();
        tufts.add(
          Tuft(
            ix: ix,
            iy: iy,
            i: i,
            height: height,
            base: _round(noise(ix * .09, iy * .18) * 2.2),
            phase: ix * .11 + iy * .19 + hash(ix, iy) * .9,
            bloom: hash(ix * 7, iy) < .022
                ? (hash(ix, iy) > .5 ? rgb(250, 246, 226) : rgb(240, 200, 84))
                : 0,
          ),
        );
      }
    }
  }

  // pp-engine.js: drawTufts
  void drawTufts(double t) {
    for (final tuft in tufts) {
      final gust =
          math.sin(t * .8 + tuft.phase) +
          .5 * math.sin(t * 2.1 + tuft.phase * 2.3);
      final colors = staticShadow[tuft.i] != 0 ? tuftDark : tuftLit;
      for (var k = 1; k <= tuft.height; k++) {
        final jx = tuft.ix + _round(gust * .95 * k / 3), jy = tuft.iy - k;
        if (jx < 0 || jx >= W) continue;
        final j = jy * W + jx;
        // the old code reads past the start of the array here and gets undefined, which is neither kind
        if (j < 0) continue;
        if ((kinds[j] != KIND_GRASS && kinds[j] != KIND_NONE) ||
            zb[j] != groundZ[j]) {
          continue;
        }
        pix[j] = tuft.bloom != 0 && k == tuft.height
            ? tuft.bloom
            : colors[clamp(tuft.base + k + (gust > 1 ? 1 : 0), 1, 4)];
      }
    }
  }

  // pp-engine.js: drawLeaves
  void drawLeaves(double t) {
    for (final leaf in leaves) {
      final reach = clamp<double>((leaf.z - 2.5) / 3, .3, 1);
      final swayX =
          (math.sin(t * .9 + leaf.x * .5 + leaf.z * .7) +
              .55 * math.sin(t * 2.3 + leaf.k * 1.7)) *
          reach;
      final dx = _round(swayX * .9),
          dy = _round(math.sin(t * 1.3 + leaf.y + leaf.k) * reach * .45);
      final px = leaf.pixels;
      for (var n = 0; n < px.length; n += 4) {
        final ix = (px[n] as int) + dx, iy = (px[n + 1] as int) + dy;
        if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
        final i = iy * W + ix;
        if (px[n + 2] <= zb[i]) continue;
        zb[i] = px[n + 2].toDouble();
        pix[i] = px[n + 3] as int;
      }
      if (leaf.k.remainder(2) == 0) {
        castShadow(leaf.x + swayX * .12, leaf.y, leaf.z, leaf.r);
      }
    }
  }

  // pp-engine.js: bakeOcclusion
  void bakeOcclusion() {
    final offsets = <List<int>>[];
    for (final r in const [2, 4]) {
      for (var k = 0; k < 8; k++) {
        offsets.add([
          _round(math.cos(k * math.pi / 4) * r),
          _round(math.sin(k * math.pi / 4) * r * .7),
        ]);
      }
    }
    for (var iy = 4; iy < H - 4; iy++) {
      for (var ix = 4; ix < W - 4; ix++) {
        final i = iy * W + ix;
        if (ground[i] == 0 || zb[i] != groundZ[i]) continue;
        var hits = 0;
        for (final o in offsets) {
          final j = (iy + o[1]) * W + ix + o[0];
          if (zb[j] != groundZ[j]) hits++;
        }
        if (hits == 0) continue;
        if (hits >= 8) {
          tint(i, .56, .54, .72);
        } else if (hits / 8 > bayerAt(ix, iy)) {
          tint(i, .74, .72, .84);
        }
      }
    }
  }

  // pp-engine.js: plot
  void plot(num x, num y, num z, int color) {
    final p = project(x, y, z), ix = p.sx.truncate(), iy = p.sy.truncate();
    if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
    final i = iy * W + ix;
    if (p.d <= zb[i]) return;
    zb[i] = p.d;
    pix[i] = color;
  }

  // a gnarled trunk, then a dark core under silver-green leaf clusters that sway in drawLeaves
  final List<List<double>> CROWN = const [
    [.1, 0, 3.7, 1.6],
    [-1.4, -.7, 3.3, 1.2],
    [1.6, .7, 3.4, 1.25],
    [-.6, 1.1, 3.9, 1.1],
    [.9, -1.1, 4, 1.1],
    [.2, .1, 4.9, 1.05],
  ];
  final List<num> LEAF_DEEP = const [58, 84, 62],
      LEAF_MID = const [100, 126, 78],
      LEAF_SILVER = const [146, 162, 112];

  // pp-engine.js: growTree
  void growTree(num x, num y, [num scale = 1, int count = 420, num seed = 0]) {
    List<num> bark(double z) => BARK;
    capsule(
      [x, y, 0],
      [x + .3 * scale, y + .1 * scale, 2.2 * scale],
      .36 * scale,
      .22 * scale,
      bark,
      'rough',
    );
    capsule(
      [x + .3 * scale, y + .1 * scale, 2.2 * scale],
      [x - .8 * scale, y - .4 * scale, 3.3 * scale],
      .2 * scale,
      .13 * scale,
      bark,
      'rough',
    );
    capsule(
      [x + .3 * scale, y + .1 * scale, 2.2 * scale],
      [x + 1.2 * scale, y + .4 * scale, 3.4 * scale],
      .2 * scale,
      .13 * scale,
      bark,
      'rough',
    );
    for (var n = 0; n < count; n++) {
      final k = n + seed, crown = CROWN[n % CROWN.length];
      final cx = crown[0], cy = crown[1], cz = crown[2], spread = crown[3];
      final a = hash(k, 7) * 6.283,
          tilt = hash(k, 8) * 2 - 1,
              // Math.cbrt, as the porting table says
              d =
              math.pow(hash(k, 9), 1 / 3) * spread,
          flat = math.sqrt(1 - tilt * tilt);
      final rx = cx + math.cos(a) * flat * d,
          ry = cy + math.sin(a) * flat * d,
          rz = cz + tilt * d * .8;
      final tone = hash(k, 10) + (rz - 4.2) * .22 + (d / spread - .5) * .3;
      final leaf = tone > .72
          ? LEAF_SILVER
          : tone > .3
          ? LEAF_MID
          : LEAF_DEEP;
      final cap = capture = <num>[];
      sphere(
        x + rx * scale,
        y + ry * scale,
        rz * scale,
        (.2 + hash(k, 11) * .22) * scale,
        leaf,
        'rough',
      );
      leaves.add(
        Leaf(
          x: (x + rx * scale).toDouble(),
          y: (y + ry * scale).toDouble(),
          z: (rz * scale).toDouble(),
          k: k,
          r: (.42 * scale).toDouble(),
          pixels: cap,
        ),
      );
      capture = null;
    }
  }

  // pp-engine.js: figure
  List<num> figure(
    num px,
    num py,
    num yaw,
    Pose pose,
    FigurePalette palette,
    AddBone addBone,
  ) {
    final fx = math.cos(yaw),
        fy = math.sin(yaw),
        sx = -fy,
        sy = fx,
        base = _orElse(pose['z'], 0),
        k = _orElse(pose['scale'], 1);
    List<double> P(num a, num b, num c) => [
      px + (fx * a + sx * b) * k,
      py + (fy * a + sy * b) * k,
      c * k + base,
    ];
    void add(List<num> a, List<num> b, num r0, num r1, ColorOf f) =>
        addBone(a, b, r0 * k, r1 * k, f);
    final t = palette;
    // about 3px bands: thinner ones read as noise
    List<num> shirt(double z) =>
        ((z * 3.2).floor().remainder(2) != 0 ? t['shirt'] : t['stripe'])!;
    List<num> legs(double z) => t['legs']!;
    List<num> skin(double z) => t['skin']!;
    final crouch = _orElse(pose['crouch'], 0), lean = _orElse(pose['lean'], 0);
    final hipZ = 1.28 - crouch * .4;
    final hipA = -crouch * .15;
    final shA = hipA + math.sin(lean) * .95, shZ = hipZ + math.cos(lean) * .95;
    final neck = P(shA, 0, shZ + .08),
        head = P(shA + math.sin(lean) * .32, 0, shZ + .36);
    final stance = pose['stance'] ?? .2;
    final footB = P(-stance * 1.2, .2, .12), footF = P(stance * 2, -.2, .12);
    final kneeB = P(-stance * .4 + crouch * .12, .22, .68 - crouch * .1);
    final kneeF = P(stance * 1.2 + crouch * .34, -.22, .72 - crouch * .08);
    final hipB = P(hipA, .15, hipZ), hipF = P(hipA, -.15, hipZ);
    add(hipB, kneeB, .17, .13, legs);
    add(kneeB, footB, .13, .1, legs);
    add(hipF, kneeF, .17, .13, legs);
    add(kneeF, footF, .13, .1, legs);
    add(footB, P(-stance * 1.2 + .16, .2, .08), .1, .09, (_) => SHOE);
    add(footF, P(stance * 2 + .16, -.2, .08), .1, .09, (_) => SHOE);
    add(P(hipA, 0, hipZ), neck, .3, .32, shirt);
    add(neck, head, .11, .12, skin);
    sphere2(add, head, .24, t['skin']!);
    sphere2(
      add,
      [head[0] - fx * .06, head[1] - fy * .06, head[2] + .08],
      .205,
      t['hair']!,
    );
    final shR = P(shA, .36, shZ - .03), shL = P(shA, -.36, shZ - .03);
    final armR = pose['armR'] ?? 0, armL = pose['armL'] ?? .08;
    final elbowR = P(
      shA + math.sin(armR) * .46,
      .4,
      shZ - .03 - math.cos(armR) * .46,
    );
    final handR = P(
      shA + math.sin(armR + .18) * .95,
      .42,
      shZ - .03 - math.cos(armR + .18) * .95,
    );
    final elbowL = P(
      shA + math.sin(armL) * .46,
      -.42,
      shZ - .03 - math.cos(armL) * .46,
    );
    final handL = P(
      shA + math.sin(armL + .2) * .9,
      -.43,
      shZ - .03 - math.cos(armL + .2) * .9,
    );
    add(shR, elbowR, .12, .1, shirt);
    add(elbowR, handR, .09, .08, skin);
    add(shL, elbowL, .12, .1, shirt);
    add(elbowL, handL, .09, .08, skin);
    return handR;
  }

  // pp-engine.js: sphere2
  void sphere2(AddBone add, List<num> c, num r, List<num> color) =>
      add(c, c, r, r, (_) => color);

  // pp-engine.js: dynamicAdd
  void dynamicAdd(List<num> a, List<num> b, num r0, num r1, ColorOf f) {
    capsule(a, b, r0, r1, f, 'solid');
    pendingShadows.addAll([a, r0, b, r1]);
  }

  /// What the bones asked to be shadowed, four entries a bone: a, r0, b, r1 (the old `pendingShadows`).
  final List<Object> pendingShadows = [];

  // pp-engine.js: flushShadows
  void flushShadows() {
    for (var i = 0; i < pendingShadows.length; i += 4) {
      final a = pendingShadows[i] as List<num>,
          ra = pendingShadows[i + 1] as num,
          c = pendingShadows[i + 2] as List<num>;
      final n = math.max(
        1,
        (_hypot3(c[0] - a[0], c[1] - a[1], c[2] - a[2]) / .25).ceil(),
      );
      for (var k = 0; k <= n; k++) {
        final t = k / n;
        castShadow(
          lerp(a[0], c[0], t),
          lerp(a[1], c[1], t),
          lerp(a[2], c[2], t),
          ra * .9,
          1,
          0,
        );
      }
      if (a[2] < .25) {
        castShadow(a[0], a[1], 0, .2, 2, 0); // contact under the feet
      }
    }
  }

  // pp-engine.js: drawDots
  void drawDots(List<List<num>> points, int color) {
    for (final p in points) {
      final ix = p[0].truncate(), iy = p[1].truncate();
      if (ix >= 0 && iy >= 0 && ix < W && iy < H) pix[iy * W + ix] = color;
    }
  }

  final List<String> ARROW = const [
    '....ooooo....',
    '....oXXXo....',
    '....oXXXo....',
    '....oXXXo....',
    'oooooXXXooooo',
    'oXXXXXXXXXXXo',
    '.oXXXXXXXXXo.',
    '..oXXXXXXXo..',
    '...oXXXXXo...',
    '....oXXXo....',
    '.....oXo.....',
    '......o......',
  ];
  late final int INK = rgb(28, 27, 25),
      SIGNAL = rgb(255, 214, 10),
      PAPER = rgb(255, 255, 255);

  // pp-engine.js: haloDots. Signals get a white halo, so they separate from whatever busy detail sits behind them
  void haloDots(List<List<num>> points) {
    final halo = <List<num>>[];
    for (final p in points) {
      for (final d in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        halo.add([p[0] + d[0], p[1] + d[1]]);
      }
    }
    drawDots(halo, PAPER);
  }

  // pp-engine.js: drawArrow. A bobbing arrow whose tip points at (sx, sy)
  void drawArrow(num sx, num sy, num time) {
    final bob = STILL ? 0 : (time * 3).floor().remainder(2) * 2;
    final left = _round(sx) - 6, top = _round(sy) - ARROW.length - bob;
    final ink = <List<num>>[], fill = <List<num>>[];
    for (var y = 0; y < ARROW.length; y++) {
      final row = ARROW[y];
      for (var x = 0; x < row.length; x++) {
        final cell = row[x];
        if (cell == 'o') ink.add([left + x, top + y]);
        if (cell == 'X') fill.add([left + x, top + y]);
      }
    }
    haloDots(ink);
    drawDots(ink, INK);
    drawDots(fill, SIGNAL);
  }

  // Math.round (page 12, section 6)
  static int _round(num x) => (x + .5).floor();

  // Math.hypot of three numbers (page 12, section 6)
  static double _hypot3(num a, num b, num c) =>
      math.sqrt(a * a + b * b + c * c);

  // `pose.k || dflt`: JavaScript takes the default for undefined, 0 and NaN
  static double _orElse(num? v, num dflt) =>
      (v == null || v == 0 || v.isNaN ? dflt : v).toDouble();
}
