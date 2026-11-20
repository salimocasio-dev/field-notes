// Port of docs/proyecto/pixel/set-kit.js: the helpers the scene sets add to mapa.js's building helpers. Shared by every
// scene set of this package (order 07 on). The old file's names and parameters are kept, capitals included, so the
// port reads line for line against it (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

/// mapa.js: `KIND_ROAD` (the engine has `KIND_NONE` and `KIND_GRASS`; mapa.js adds sand, water and road).
const int KIND_ROAD = 4;

/// The light of the hour (frente-set.html: an entry of `LIGHT`): `c' = c * m + a` per channel. [litTufts]: the grass
/// blades keep their lit colours (a warm light).
class Light {
  const Light(this.m, this.a, {this.litTufts = false});

  final List<double> m;
  final List<double> a;
  final bool litTufts;
}

// JavaScript: Math.fround
final Float32List _f32 = Float32List(1);
double _fround(num v) {
  _f32[0] = v.toDouble();
  return _f32[0];
}

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// set-kit.js: lit
/// The same light on one colour, for pixels drawn each frame (swaying leaves).
List<num> lit(List<num> c, Light? L) => L != null
    ? [c[0] * L.m[0] + L.a[0], c[1] * L.m[1] + L.a[1], c[2] * L.m[2] + L.a[2]]
    : c;

/// Port of set-kit.js. Its module-level state (`glowZ`, `slabTops`, `PART_TAGS`, `PART_LEAVES`) is fields; it draws
/// into the engine [e] through mapa.js's helpers [b]. One per engine.
class SetKit {
  SetKit(this.e, this.b) : glowZ = Float32List(e.W * e.H);

  final PpEngine e;
  final PpBuild b;

  double get ST => b.ST;
  int get W => e.W;
  int get H => e.H;

  /* ---------- light: pixels that give light keep their colour when the set is dimmed ---------- */

  // set-kit.js: glowZ
  final Float32List glowZ;

  // set-kit.js: glowReset
  void glowReset() => glowZ.fillRange(0, glowZ.length, -1e9);

  // set-kit.js: plotGlow
  /// Plot a pixel that gives light (a lit window, a lit doorway): lightPass leaves it as it is.
  void plotGlow(num x, num y, num z, int color) {
    final p = e.project(x, y, z), ix = p.sx.truncate(), iy = p.sy.truncate();
    e.plot(x, y, z, color);
    if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
    final i = iy * W + ix;
    if (e.zb[i] == _fround(p.d)) glowZ[i] = e.zb[i];
  }

  // set-kit.js: lightPass
  /// The light of the hour, on everything the set drew (not the sky, not the pixels that give light): c' = c * m + a,
  /// per channel. darkTufts: the grass blades drawTufts draws each frame take their shaded colours everywhere (a dim
  /// light: storm, rain, sunset); without it they keep their lit colours (a warm light: dusk).
  void lightPass(List<double> m, List<double> a, [bool darkTufts = true]) {
    final pix = e.pix, zb = e.zb;
    for (var i = 0; i < W * H; i++) {
      if (zb[i] < -1e8 || glowZ[i] == zb[i]) continue;
      final c = pix[i];
      pix[i] = e.rgb(
        (c & 255) * m[0] + a[0],
        (c >> 8 & 255) * m[1] + a[1],
        (c >> 16 & 255) * m[2] + a[2],
      );
    }
    if (darkTufts) {
      for (var i = 0; i < W * H; i++) {
        if (e.kinds[i] == e.KIND_GRASS) e.staticShadow[i] = 1;
      }
    }
  }

  /* ---------- the sky: every pixel the ground and the set left empty ---------- */

  // set-kit.js: skyFill
  /// fn(ix, iy) gives the colour of the sky at that pixel (screen space: the sky is not in the world).
  void skyFill(int Function(int ix, int iy) fn) {
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix;
        if (e.zb[i] > -1e8) continue;
        e.pix[i] = fn(ix, iy);
      }
    }
  }

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // set-kit.js: skyBands
  /// A sky of dithered bands, from tones[0] at the top to the last tone at the horizon.
  int skyBands(List<List<num>> tones, num y0, num y1, int ix, int iy) {
    final t =
        e.clamp<double>((iy + .5 - y0) / (y1 - y0), 0, 1) * (tones.length - 1);
    return _rgbOf(
      tones[e.clamp((t + e.bayerAt(ix, iy) - .5).floor(), 0, tones.length - 1)],
    );
  }

  // set-kit.js: skyDisc
  /// A disc in the sky (the sun), screen space, with a lit rim to the upper left. 0 outside it.
  int skyDisc(num cx, num cy, num r, List<List<num>> tones, int ix, int iy) {
    final dx = ix + .5 - cx,
        dy = iy + .5 - cy,
        d = math.sqrt(dx * dx + dy * dy) / r;
    if (d > 1) return 0;
    final l = e.clamp<double>(1 - d * .55 - (dx + dy) / r * .25, 0, 1);
    return _rgbOf(
      tones[e.clamp(
        (l * (tones.length - .01) + (e.bayerAt(ix, iy) - .5) * .6).floor(),
        0,
        tones.length - 1,
      )],
    );
  }

  // set-kit.js: skyHills
  /// Far hills on the horizon: two ridges, screen space; 0 above them.
  int skyHills(
    num base,
    List<List<num>> far,
    List<List<num>> near,
    int ix,
    int iy,
  ) {
    final y1 =
        base - 13 - 6 * math.sin(ix * .029 + 1) - 3 * math.sin(ix * .083);
    final y2 = base - 6 - 3 * math.sin(ix * .047 + 3) - 2 * math.sin(ix * .13);
    if (iy + .5 >= y2) {
      return _rgbOf(
        iy + .5 - y2 < 1
            ? near[1]
            : e.bayerAt(ix, iy) < (iy - y2) / 10
            ? near[2]
            : near[0],
      );
    }
    if (iy + .5 >= y1) {
      return _rgbOf(
        iy + .5 - y1 < 1
            ? far[1]
            : e.bayerAt(ix, iy) < (iy - y1) / 24
            ? far[2]
            : far[0],
      );
    }
    return 0;
  }

  /* ---------- walls with openings ---------- */

  // set-kit.js: wallY
  /// The face of a wall that faces +y (lit), at y = at, from a0 to a1 along x, z0 to z1, with rectangular holes
  /// [a0, a1, z0, z1]. boards: the spacing of wooden siding (a darker line under each board), 0 for a plain wall.
  void wallY(
    num at,
    num a0,
    num a1,
    num z0,
    num z1,
    List<num> c, [
    List<List<num>> holes = const [],
    num boards = 0,
  ]) {
    for (num a = a0; a <= a1; a += ST) {
      final hs = holes
          .where((h) => a > h[0] && a < h[1])
          .toList(); // the holes this column crosses
      for (num z = z0; z <= z1; z += ST) {
        var hole = false;
        for (var k = 0; k < hs.length; k++) {
          if (z > hs[k][2] && z < hs[k][3]) {
            hole = true;
            break;
          }
        }
        if (!hole) {
          e.plot(
            a,
            at,
            z,
            b.shade(
              c,
              boards != 0 && z.remainder(boards) < boards * .17 ? 1.5 : 2.4,
              a,
              z,
            ),
          );
        }
      }
    }
  }

  // set-kit.js: blockHoles
  /// A solid block whose +y face has holes: block() with wallY for the lit face. roofed: the top is under a roof that
  /// covers it, so it is not drawn.
  void blockHoles(
    num x0,
    num y0,
    num z0,
    num x1,
    num y1,
    num z1,
    List<num> c,
    List<List<num>> holes, [
    num boards = 0,
    bool roofed = false,
  ]) {
    if (!roofed) {
      for (num a = x0; a <= x1; a += ST) {
        for (num bb = y0; bb <= y1; bb += ST) {
          e.plot(a, bb, z1, b.shade(c, 3.4, a, bb));
        }
      }
    }
    wallY(y1, x0, x1, z0, z1, c, holes, boards);
    for (num bb = y0; bb <= y1; bb += ST) {
      for (num z = z0; z <= z1; z += ST) {
        e.plot(
          x1,
          bb,
          z,
          b.shade(
            c,
            boards != 0 && z.remainder(boards) < boards * .17 ? .5 : 1.3,
            bb,
            z,
          ),
        );
      }
    }
  }

  // set-kit.js: reveal
  /// The reveal of a hole in a +y wall: the faces of the wall's thickness you see through it from above, `deep` into
  /// the wall (the left side, which faces +x, and the sill; the lintel's underside cannot be seen from above).
  void reveal(num at, num a0, num a1, num z0, num z1, num deep, List<num> c) {
    for (num t = 0; t <= deep; t += ST * .5) {
      for (num z = z0; z <= z1; z += ST * .5) {
        e.plot(a0, at - t, z, e.rampOf(c)[1]);
      }
      for (num a = a0; a <= a1; a += ST * .5) {
        e.plot(a, at - t, z0, e.rampOf(c)[3]);
      }
    }
  }

  // set-kit.js: paneY
  /// A flat plane parallel to a +y wall (y = at), painted by fn(a, z) -> colour or 0; glow: the pixels give light.
  void paneY(
    num at,
    num a0,
    num a1,
    num z0,
    num z1,
    int Function(num a, num z) fn, [
    bool glow = false,
  ]) {
    for (num a = a0; a <= a1; a += ST * .5) {
      for (num z = z0; z <= z1; z += ST * .5) {
        final col = fn(a, z);
        if (col == 0) continue;
        if (glow) {
          plotGlow(a, at, z, col);
        } else {
          e.plot(a, at, z, col);
        }
      }
    }
  }

  // set-kit.js: leaf
  /// A flat leaf (a door, a shutter) hinged on a vertical line at (hx, hy), `len` long, turned by `ang` from the +x
  /// direction (ang 0: lies along +x; pi: along -x; -pi / 2: into the wall, along -y). fn(t, z): t from the hinge (0)
  /// to the free edge (1).
  void leaf(
    num hx,
    num hy,
    num len,
    num z0,
    num z1,
    num ang,
    int Function(num t, num z) fn,
  ) {
    final dx = math.cos(ang), dy = math.sin(ang);
    for (num t = 0; t <= 1; t += ST * .4 / len) {
      for (num z = z0; z <= z1; z += ST * .5) {
        e.plot(hx + dx * len * t, hy + dy * len * t, z, fn(t, z));
      }
    }
  }

  /* ---------- a low slab you can stand on (a porch, a step) ---------- */

  // set-kit.js: slabTops
  final List<num> slabTops = [];

  // set-kit.js: slab
  /// block() whose top later takes the characters' shadows like the ground: joinSlabs(), called after bakeOcclusion,
  /// puts its top pixels into ground and groundZ (so the walls' occlusion does not darken it). kinds: ROAD, so no grass
  /// grows on it.
  void slab(num x0, num y0, num x1, num y1, num h, List<num> c) {
    final zb = e.zb, before = Float32List.fromList(zb);
    for (num a = x0; a <= x1; a += ST) {
      for (num bb = y0; bb <= y1; bb += ST) {
        e.plot(a, bb, h, b.shade(c, 3.4, a, bb));
      }
    }
    for (var i = 0; i < W * H; i++) {
      if (zb[i] != before[i]) slabTops.addAll([i, zb[i]]);
    }
    for (num a = x0; a <= x1; a += ST) {
      for (num z = 0; z <= h; z += ST) {
        e.plot(a, y1, z, b.shade(c, 2.4, a, z));
      }
    }
    for (num bb = y0; bb <= y1; bb += ST) {
      for (num z = 0; z <= h; z += ST) {
        e.plot(x1, bb, z, b.shade(c, 1.3, bb, z));
      }
    }
  }

  // set-kit.js: joinSlabs
  void joinSlabs() {
    for (var n = 0; n < slabTops.length; n += 2) {
      final i = slabTops[n] as int;
      if (e.zb[i] != slabTops[n + 1]) continue;
      e.ground[i] = 1;
      e.groundZ[i] = e.zb[i];
      e.kinds[i] = KIND_ROAD;
    }
    slabTops.clear();
  }

  /* ---------- a hip roof: four slopes, the ridge along x, rows of tiles ---------- */

  // set-kit.js: hipRoof
  /// Eaves at height z over [x0, x1] x [y0, y1]; rise: the ridge above the eaves. c: tiles; edge: the fascia.
  void hipRoof(
    num x0,
    num y0,
    num x1,
    num y1,
    num z,
    num rise,
    List<num> c,
    List<num> edge,
  ) {
    final xc = (x0 + x1) / 2,
        yc = (y0 + y1) / 2,
        hy = (y1 - y0) / 2,
        hx = (x1 - x0) / 2;
    final R = e.rampOf(c);
    const ROW = .19, TILE = .3;
    for (num x = x0; x <= x1; x += ST * .7) {
      for (num y = y0; y <= y1; y += ST * .7) {
        final fy = (hy - (y - yc).abs()) / hy,
            fx = (hx - (x - xc).abs()) / hy,
            f = math.min(math.min(fy, fx), 1);
        {
          // off the picture: plot() would drop it (order 30a: skipped before the work, the same pixels)
          final p = e.project(x, y, z + rise * f),
              ix = p.sx.truncate(),
              iy = p.sy.truncate();
          if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
        }
        final front = fy <= fx,
            along =
                (front ? fy : fx) * hy; // how far up the slope from the eave
        final r = (along / ROW).floor(), t = along.remainder(ROW) / ROW;
        // along the eave, the tiles staggered row by row
        final run = front ? x : y,
            s = ((run / TILE + r.remainder(2) * .5).remainder(1) + 1).remainder(
              1,
            );
        final tile = (run / TILE + r.remainder(2) * .5).floor();
        var lit = front ? (y > yc ? 3 : 2) : (x > xc ? 1 : 2);
        if (t < .22) {
          lit -= 1; // the shadow under each row
        } else if (s < .1) {
          lit -= 1; // the gap between two tiles
        } else if (t > .8) {
          lit += front ? 1 : 0; // the lit lip of a tile
        }
        final h = e.hash(tile * 3 + r, r * 7 + (front ? 0 : 50));
        if (h > .9) {
          lit += 1;
        } else if (h < .07) {
          lit -= 1;
        }
        if ((fy - fx).abs() * hy < .045 || f > .985) {
          lit = front ? 4 : 3; // the hips and the ridge: capped, light
        }
        e.plot(x, y, z + rise * f, R[e.clamp(lit, 0, 4)]);
      }
    }
    // the fascia: a thin board round the eaves, in front of the tiles' edge
    final E = e.rampOf(edge);
    for (num x = x0; x <= x1; x += ST * .5) {
      for (num h = -.12; h <= 0; h += ST * .5) {
        e.plot(x, y1 + .01, z + h, E[2]);
      }
    }
    for (num y = y0; y <= y1; y += ST * .5) {
      for (num h = -.12; h <= 0; h += ST * .5) {
        e.plot(x1 + .01, y, z + h, E[1]);
      }
    }
  }

  /* ---------- swaying leaves the set owns: drawn each frame by drawLeaves, like growTree's ---------- */

  // set-kit.js: keepPlot
  /// The pixel the engine's plot would write, kept in a list instead: [ix, iy, depth, colour].
  void keepPlot(List<num> list, num x, num y, num z, int color) {
    final p = e.project(x, y, z), ix = p.sx.truncate(), iy = p.sy.truncate();
    if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
    list.addAll([ix, iy, _fround(p.d), color]);
  }

  // set-kit.js: swayPalm
  /// A palm whose fronds sway in the wind (pp-engine's drawLeaves). Trunk and coconuts are baked. Each frond is one
  /// leaf of `leaves`; L: the light of the hour (lightPass's m and a), so the fronds match the set.
  List<num> swayPalm(
    num x,
    num y,
    num h,
    num lean,
    num seed, [
    num size = 1,
    Light? L,
  ]) {
    final top = [x + lean * .7, y - lean * .5, h], palmC = lit(b.C.palm, L);
    e.capsule(
      [x, y, 0],
      [x + lean * .25, y - lean * .15, h * .5],
      .2 * size,
      .16 * size,
      (_) => palmC,
      'rough',
    );
    e.capsule(
      [x + lean * .25, y - lean * .15, h * .5],
      top,
      .16 * size,
      .13 * size,
      (_) => palmC,
      'rough',
    );
    final R = e.rampOf(lit(b.C.leaf, L));
    const n = 9;
    for (var f = 0; f < n; f++) {
      final a = f / n * 6.283 + seed,
          dx = math.cos(a),
          dy = math.sin(a),
          len = (1.5 + e.hash(f, seed) * .45) * size;
      final pixels = <num>[];
      for (num t = 0; t <= 1; t += .012 / size) {
        final px = top[0] + dx * len * t,
            py = top[1] + dy * len * t,
            pz = top[2] + .3 * t * size - 1.3 * t * t * size,
            w = (.3 * math.sin(t * math.pi) + .03) * size;
        for (num s = -1; s <= 1; s += .12) {
          final leaflet = s.abs() > .2 && (t * 40).truncate().remainder(2) == 0;
          if (leaflet && s.abs() > .7) continue;
          keepPlot(
            pixels,
            px - dy * w * s,
            py + dx * w * s,
            pz - s.abs() * w * .5,
            R[e.clamp(
              _round(2.2 + (dx + dy) * .6 - s.abs() * .8 + (s > 0 ? .4 : -.2)),
              0,
              4,
            )],
          );
        }
      }
      // odd k: drawLeaves casts no shadow for it each frame; the frond's shadow is baked here, along its length
      e.leaves.add(
        Leaf(
          x: (top[0] + dx * len * .45).toDouble(),
          y: (top[1] + dy * len * .45).toDouble(),
          z: (top[2] - .2 * size).toDouble(),
          k: f * 2 + 1,
          r: (.3 * size).toDouble(),
          pixels: pixels,
        ),
      );
      for (num t = .1; t <= 1; t += .1) {
        e.castShadow(
          top[0] + dx * len * t,
          top[1] + dy * len * t,
          top[2] + .3 * t * size - 1.3 * t * t * size,
          (.06 + .2 * math.sin(t * math.pi)) * size,
          1,
          .2,
        );
      }
    }
    e.sphere(
      top[0],
      top[1],
      top[2] - .15 * size,
      .22 * size,
      lit(const [120, 92, 48], L),
      'rough',
    );
    for (var k = 0; k < 3; k++) {
      e.sphere(
        top[0] + math.cos(k * 2.1 + seed) * .18 * size,
        top[1] + math.sin(k * 2.1 + seed) * .18 * size,
        top[2] - .3 * size,
        .11 * size,
        lit(const [96, 120, 52], L),
        'rough',
      );
    }
    for (num z = .2; z < h; z += .15) {
      e.castShadow(
        x + lean * z / h * .5,
        y - lean * z / h * .3,
        z,
        .15 * size,
        1,
        .1,
      );
    }
    return top;
  }

  /* ---------- a birdhouse on a post ---------- */

  // set-kit.js: birdhouse
  void birdhouse(num x, num y, [Light? L]) {
    final wood = lit(b.C.wood, L),
        box = lit(const [244, 206, 96], L),
        roof = lit(b.C.red, L);
    b.block(x - .07, y - .07, 0, x + .07, y + .07, 1.25, wood);
    b.block(x - .28, y - .24, 1.25, x + .28, y + .24, 1.78, box);
    // the round hole on the front (+y) face, and a perch under it
    for (num a = -.12; a <= .12; a += ST * .4) {
      for (num z = -.12; z <= .12; z += ST * .4) {
        if (a * a + z * z < .0144) {
          e.plot(x + a, y + .25, 1.55 + z, e.rgb(32, 20, 10));
        }
      }
    }
    b.block(x - .03, y + .24, 1.36, x + .03, y + .38, 1.4, wood);
    // a pitched roof, its ridge along x
    for (num a = -.4; a <= .4; a += ST * .5) {
      for (num bb = -.38; bb <= .38; bb += ST * .5) {
        final q = bb.abs() / .38;
        e.plot(
          x + a,
          y + bb,
          1.78 + .3 * (1 - q),
          e.rampOf(roof)[e.clamp(
            (bb > 0 ? 3 : 2) + ((q * 4).floor().remainder(2) != 0 ? 0 : -1),
            0,
            4,
          )],
        );
      }
    }
    for (num bb = -.36; bb <= .36; bb += ST * .5) {
      for (num h = 0; h <= .3 * (1 - bb.abs() / .38); h += ST * .5) {
        e.plot(x + .28, y + bb, 1.78 + h, e.rampOf(box)[1]);
      }
    }
    b.shadowBox(x - .28, y - .24, x + .28, y + .24, 2, .3);
    for (num z = .2; z < 1.25; z += .3) {
      e.castShadow(x, y, z, .1);
    }
  }

  /* ---------- a touch box for something round (a palm's crown, a post) ---------- */

  // set-kit.js: boxAround
  /// The world box (x0, y0, z0, x1, y1, z1), square on the ground, whose 8 projected corners have the screen bounding
  /// box [sx0, sy0] - [sx1, sy1]: for a thing whose 3D extent would give far too big a box (a palm's fronds).
  List<double> boxAround(num sx0, num sy0, num sx1, num sy1) {
    final S = e.S, OX = e.OX, OY = e.OY, SIN = e.SIN, COS = e.COS, R2 = e.R2;
    // a box with x and y extents e projects 2e/R2 wide in u and in v
    final d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - OX) / S;
    final vmax = (sy1 - OY) / (S * SIN),
        vmin = vmax - d,
        z1 = (vmin * SIN - (sy0 - OY) / S) / COS;
    final xc = (uc + (vmin + vmax) / 2) / R2,
        yc = ((vmin + vmax) / 2 - uc) / R2,
        ex = d * R2 / 4;
    return [xc - ex, yc - ex, 0, xc + ex, yc + ex, z1];
  }

  /* ---------- furniture turned to any angle (order 30a, El balcón) ---------- */

  // set-kit.js: faceBase
  /// The shade of a vertical face by the way it faces: like block()'s walls, +y faces lit (2.4), +x faces in shade (1.3),
  /// in between by angle. (nx, ny): the face's outward normal on the ground.
  double faceBase(num nx, num ny) =>
      e.clamp<double>(1.3 + 1.1 * math.atan2(ny, nx) / (math.pi / 2), 1, 2.9);

  // set-kit.js: turnedBox
  /// A box turned by ang: its width axis along (cos ang, sin ang), half-width hw; its depth axis along (-sin ang,
  /// cos ang), half-depth hd. ang = -pi / 4 turns its front (+depth) to the camera. fn(s, t, z, face) may give a colour
  /// (s across, t in depth; face 'top' or the side: 'front', 'back', 'left', 'right'); otherwise (0, or no fn) the face
  /// is shaded from c. Only faces turned towards the camera are drawn.
  void turnedBox(
    num cx,
    num cy,
    num z0,
    num z1,
    num hw,
    num hd,
    num ang,
    List<num> c, [
    int Function(num s, num t, num z, String face)? fn,
  ]) {
    final ax = math.cos(ang), ay = math.sin(ang), bx = -ay, by = ax;
    List<num> P(num s, num t) => [cx + ax * s + bx * t, cy + ay * s + by * t];
    void put(num s, num t, num z, String face, num base, num g1, num g2) {
      final p = P(s, t), col = fn == null ? 0 : fn(s, t, z, face);
      e.plot(p[0], p[1], z, col != 0 ? col : b.shade(c, base, g1, g2));
    }

    for (num s = -hw; s <= hw + 1e-9; s += ST * .7) {
      for (num t = -hd; t <= hd + 1e-9; t += ST * .7) {
        put(s, t, z1, 'top', 3.4, cx + s, cy + t);
      }
    }
    final sides = <(String, double, double, List<num> Function(num), num)>[
      ('front', bx, by, (s) => [s, hd], hw),
      ('back', -bx, -by, (s) => [s, -hd], hw),
      ('right', ax, ay, (t) => [hw, t], hd),
      ('left', -ax, -ay, (t) => [-hw, t], hd),
    ];
    for (final (face, nx, ny, at, half) in sides) {
      if (nx + ny < -1e-6) continue; // turned away from the camera
      final base = faceBase(nx, ny);
      for (num k = -half; k <= half + 1e-9; k += ST * .7) {
        for (num z = z0; z <= z1 + 1e-9; z += ST * .7) {
          final st = at(k);
          put(st[0], st[1], z, face, base, k + cx, z);
        }
      }
    }
  }

  // set-kit.js: drum
  /// An upright cylinder (a table's top, its foot, a flower pot): the top disc and the side that faces the camera.
  /// top(dx, dy) may colour the disc (0: shaded from c).
  void drum(
    num cx,
    num cy,
    num z0,
    num z1,
    num r,
    List<num> c, [
    int Function(num a, num b)? top,
  ]) {
    for (num a = -r; a <= r; a += ST * .7) {
      for (num bb = -r; bb <= r; bb += ST * .7) {
        if (a * a + bb * bb > r * r) continue;
        final col = top == null ? 0 : top(a, bb);
        e.plot(
          cx + a,
          cy + bb,
          z1,
          col != 0 ? col : b.shade(c, 3.4, cx + a, cy + bb),
        );
      }
    }
    final n = math.max(12, (2 * math.pi * r / (ST * .6)).ceil());
    for (var k = 0; k < n; k++) {
      final f = k / n * 2 * math.pi, nx = math.cos(f), ny = math.sin(f);
      if (nx + ny < -.3) continue;
      final base = faceBase(nx, ny);
      for (num z = z0; z <= z1 + 1e-9; z += ST * .7) {
        e.plot(cx + nx * r, cy + ny * r, z, b.shade(c, base, f * 3, z));
      }
    }
  }

  /* ---------- for the checks: which object drew each pixel ---------- */

  // set-kit.js: PART_TAGS, PART_LEAVES
  /// When a list, [part] records per pixel the last part that drew it.
  List<String?>? PART_TAGS;
  final Map<String, List<int>> PART_LEAVES = {};

  // set-kit.js: part
  /// Runs fn; when [PART_TAGS] is a list it also records, per pixel, the last part that drew it.
  void part(String name, void Function() fn) {
    final tags = PART_TAGS;
    if (tags == null) return fn();
    final before = Float32List.fromList(e.zb), l0 = e.leaves.length;
    fn();
    for (var i = 0; i < W * H; i++) {
      if (e.zb[i] != before[i]) tags[i] = name;
    }
    if (e.leaves.length > l0) PART_LEAVES[name] = [l0, e.leaves.length];
  }

  // set-kit.js: tagLeaves
  /// After a frame: tag the pixels the swaying leaves of each part drew (where they are at that frame).
  void tagLeaves(Float32List frameZ) {
    final tags = PART_TAGS;
    if (tags == null) return;
    for (final en in PART_LEAVES.entries) {
      for (var j = en.value[0]; j < en.value[1]; j++) {
        final px = e.leaves[j].pixels;
        for (var n = 0; n < px.length; n += 4) {
          for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
              final ix = (px[n] as int) + dx, iy = (px[n + 1] as int) + dy;
              if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
              final i = iy * W + ix;
              if (frameZ[i] == px[n + 2]) tags[i] = en.key;
            }
          }
        }
      }
    }
  }
}
