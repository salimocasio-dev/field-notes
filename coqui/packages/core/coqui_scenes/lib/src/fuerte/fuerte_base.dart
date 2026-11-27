// Port of docs/proyecto/pixel/fuerte-base.js: El fuerte's shared kit (`FT`), call for call: what the four scene sets
// of place 10 share (subida, musica, regalos, muralla). Built on top of La plaza's painters
// (lib/src/plaza/plaza_base.dart: PZ.box, PZ.wall, PZ.flat, PZ.post, PZ.ball, PZ.shadow, PZ.grass, PZ.xy), SetKit,
// PpEngine, and PpBuild. Laid out square to the picture, in u, v: u across, v down towards the camera, z up. The fort
// is old stone, the colour of sand: a wall that faces the camera is a plane v = const painted pixel by pixel; its top
// has battlements (the sky shows between them); a gate or an arch is a hole with a second plane painted behind it.
// Everything that moves or changes is a sprite: the flag, the paper lanterns, the curtain, people.
//
// First writer: #273 (El fuerte, before orders 74-77). The file's names are kept, capitals included, so the port reads
// line for line against fuerte-base.js (page 12, section 6).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// Port of fuerte-base.js (`FT`).
class FuerteBase {
  FuerteBase(this.PZ) : k = PZ.k, e = PZ.e, b = PZ.b;

  final PlazaBase PZ;
  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  // fuerte-base.js: STONE, STONE_D, STONE_L, MOSS, IRON
  static const List<int> STONE = [214, 186, 140],
      STONE_D = [166, 140, 106],
      STONE_L = [234, 212, 170],
      IRON = [60, 64, 76];

  static const List<int> _MOSS = [150, 150, 104];

  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // fuerte-base.js: stone
  /// The fort's masonry: big blocks in courses, a darker foot, stains.
  int stone(num u, num z, [List<num> c = STONE]) {
    final row = ((z + 9) / .36).floor(),
        off = (row & 1) * .42,
        a = jsMod(u + 60 + off, .84) / .84,
        bb = jsMod(z + 9, .36) / .36;
    if (a < .04 || bb < .1) return e.rgb(c[0] - 44, c[1] - 42, c[2] - 38);
    final kk = ((u + 60 + off) / .84).floor(),
        n = e.hash(kk * 7, row * 13) * 18,
        st = e.noise(u * .8 + 3, z * 1.1) > .62 ? 16 : 0,
        foot = z < .3 ? 22 : 0;
    if (z < .22 && e.noise(u * 2.2, 5) > .58) return _rgb(_MOSS);
    return e.rgb(
      c[0] - n - st - foot,
      c[1] - n - st - foot,
      c[2] - n - st - foot,
    );
  }

  // fuerte-base.js: solid
  /// Battlements: true where the wall is solid at `(u, z)` when its top is [z1]
  /// (merlons .52 wide, gaps .38, .34 high).
  bool solid(num u, num z, num z1) =>
      z <= z1 - .34 || jsMod(u + 60.26, .9) < .52;

  // fuerte-base.js: inArch
  /// An opening with a round top: `r = [u0, u1, z0, z1]`.
  bool inArch(num u, num z, List<num> r, [num grow = 0]) {
    final am = (r[0] + r[1]) / 2,
        ah = (r[1] - r[0]) / 2 + grow,
        zs = r[3] - (r[1] - r[0]) / 2 * .7;
    return u > r[0] - grow &&
        u < r[1] + grow &&
        z >= r[2] &&
        (z < zs ||
            jsHypot((u - am) / ah, (z - zs) / ((r[1] - r[0]) / 2 * .7 + grow)) <
                1);
  }

  // fuerte-base.js: archRing
  /// An arch's stones: the ring of paler blocks round an opening.
  int archRing(num u, num z, List<num> r) =>
      !inArch(u, z, r) && inArch(u, z, r, .16)
      ? (jsMod(
                  math.atan2(
                            z - (r[3] - (r[1] - r[0]) * .35),
                            u - (r[0] + r[1]) / 2,
                          ) *
                          5 +
                      40,
                  1,
                ) <
                .12
            ? _rgb(STONE_D)
            : _rgb(STONE_L))
      : 0;

  // fuerte-base.js: flags
  /// Flagstones: the paving of the fort's yard and of the wall's walk.
  int flags(
    num u,
    num v,
    int ix,
    int iy, [
    List<num> c = const [196, 180, 152],
  ]) {
    final row = ((v + 60) / .9).floor(),
        off = (row & 1) * .6,
        a = jsMod(u + 60 + off, 1.2) / 1.2,
        bb = jsMod(v + 60, .9) / .9;
    if (a < .035 || bb < .09) return e.rgb(c[0] - 46, c[1] - 44, c[2] - 40);
    final n = e.hash(((u + 60 + off) / 1.2).floor() * 5, row * 11) * 14,
        sp = e.hash(ix, iy) < .04 ? 10 : 0;
    return e.rgb(c[0] - n - sp, c[1] - n - sp, c[2] - n - sp);
  }

  // fuerte-base.js: grass
  int grass(num u, num v, int ix, int iy) => PZ.grass(u, v, ix, iy);

  // fuerte-base.js: onPath
  /// A path of pale stone on the grass: true inside it (it widens a little towards the camera).
  bool onPath(num u, num v, [num mid = 0, num hw = .62]) =>
      (u - mid).abs() <
      hw + v * .035 + (e.noise(v * 1.3, u > mid ? 2 : 7) - .5) * .12;

  // fuerte-base.js: pathStone
  int pathStone(num u, num v, int ix, int iy) {
    final n = e.hash((u * 2.2 + 40).floor(), (v * 1.6 + 40).floor()) * 16;
    return (jsMod(u * 2.2 + 40, 1) < .08 || jsMod(v * 1.6 + 40, 1) < .12)
        ? e.rgb(206, 190, 160)
        : e.rgb(240 - n, 228 - n, 200 - n);
  }

  // fuerte-base.js: night
  /// The night sky, in screen pixels: a moon, small stars; [hz] = the horizon's row
  /// (below it the sea, with the moon's road on it).
  int night(
    int ix,
    int iy,
    num hz, [
    List<num> moon = const [186, 26, 10],
    bool low = false,
  ]) {
    if (iy >= hz) {
      final d = iy - hz,
          road =
              (ix - moon[0]).abs() < 3 + d * .55 &&
              e.hash(ix * 3, iy * 5) < .5 - d * .012;
      if (road) return e.rgb(214, 220, 240);
      return e.hash(ix * 5, iy * 9) < .06
          ? e.rgb(70, 96, 150)
          : e.rgb(24 + d * .5, 40 + d * .6, 92 + d * .5);
    }
    final dm = jsHypot(ix + .5 - moon[0], iy + .5 - moon[1]);
    if (dm < moon[2]) {
      return (jsHypot(ix - moon[0] + 3, iy - moon[1] + 3) < 2.6 ||
              jsHypot(ix - moon[0] - 3.5, iy - moon[1] - 2) < 2)
          ? e.rgb(216, 220, 228)
          : (low ? e.rgb(255, 236, 190) : e.rgb(250, 250, 244));
    }
    if (dm < moon[2] + 3 && e.bayerAt(ix, iy) < .5) return e.rgb(70, 78, 130);
    if (e.hash(ix * 7, iy * 13) < .014 && iy < hz - 4) {
      return e.hash(ix, iy) < .5 ? e.rgb(250, 250, 255) : e.rgb(180, 190, 236);
    }
    final t = e.clamp<double>(iy / math.max<num>(1, hz), 0, 1);
    return e.rgb(16 + t * 30, 22 + t * 34, 62 + t * 54);
  }

  // fuerte-base.js: day
  /// The late afternoon and the evening sky: [hora] `'tarde'` | `'ocaso'`; [hz] as above (below it the sea).
  int day(String hora, int ix, int iy, num hz) {
    final t = e.clamp<double>(iy / math.max<num>(1, hz), 0, 1),
        dth = (e.bayerAt(ix, iy) - .5) * .08,
        kk = e.clamp<double>(t + dth, 0, 1);
    if (iy >= hz) {
      final d = iy - hz;
      return hora == 'ocaso'
          ? (e.hash(ix * 5, iy * 9) < .08
                ? e.rgb(250, 190, 130)
                : e.rgb(80 + d, 96 + d, 150))
          : (e.hash(ix * 5, iy * 9) < .07
                ? e.rgb(206, 232, 250)
                : e.rgb(56 + d, 132 + d, 196));
    }
    if (hora == 'ocaso') {
      if (jsHypot(ix + .5 - 34, iy + .5 - (hz - 9)) < 8) {
        return e.rgb(255, 214, 120);
      }
      return e.rgb(110 + kk * 140, 110 + kk * 60, 170 - kk * 40);
    }
    final cl = e.noise(ix * .05 + 4, iy * .11);
    if (cl > .7 && iy < hz - 10) return e.rgb(252, 244, 236);
    return e.rgb(110 + kk * 110, 170 + kk * 50, 240 - kk * 10);
  }

  // fuerte-base.js: wallLamp
  /// An iron lantern fixed to a wall (lit at night): at `(u, z)` on the plane [v].
  void wallLamp(num u, num v, num z, [bool lit = true]) {
    PZ.box(u, v + .07, z + .34, z + .4, .03, .07, IRON);
    final p = PZ.xy(u, v + .14), x = p[0], y = p[1];
    for (double dz = 0; dz <= .32; dz += .03) {
      for (double a = -.1; a <= .1; a += .03) {
        final edge = a.abs() > .075 || dz < .03 || dz > .29,
            col = edge
                ? _rgb(IRON)
                : (lit ? e.rgb(255, 232, 150) : e.rgb(200, 206, 200));
        if (lit && !edge) {
          k.plotGlow(x + a * .7, y - a * .7, z + dz, col);
        } else {
          e.plot(x + a * .7, y - a * .7, z + dz, col);
        }
      }
    }
  }

  // fuerte-base.js: garita
  /// A sentry box of stone: a small square tower with a domed top and a knob; on its front a door
  /// ([door] = its colour, or null) and a small window ([lit] = a light in it). Its middle is `(u, v)`;
  /// it is `2 * hw` wide.
  void garita(
    num u,
    num v, [
    List<num>? door,
    bool lit = true,
    num hw = .62,
    num h = 1.75,
  ]) {
    const hd = .5;
    PZ.box(u, v, 0, h, hw, hd, STONE, (s, t, z, face) {
      if (face != 'front') {
        return face == 'top'
            ? _rgb(STONE_D)
            : stone(s + u + t * .3, z, STONE_D);
      }
      if (door != null && s.abs() < .46 && z < 1.18) {
        // the door: .92 wide, so that a head with plaits fits in it
        if (s.abs() > .41 || z > 1.13) {
          return e.rgb(door[0] - 60, door[1] - 60, door[2] - 60);
        }
        if (jsHypot((s - .3) * 26, (z - .6) * 22.5) < 1.4) {
          return e.rgb(240, 206, 110);
        }
        return jsMod(s + .46, .153) < .02
            ? e.rgb(door[0] - 34, door[1] - 34, door[2] - 34)
            : _rgb(door);
      }
      if (s.abs() < .17 && z > 1.3 && z < 1.58) {
        return (s.abs() > .13 || z > 1.54 || z < 1.34)
            ? e.rgb(STONE_D[0] - 30, STONE_D[1] - 30, STONE_D[2] - 30)
            : (lit ? e.rgb(255, 232, 150) : e.rgb(40, 44, 70));
      }
      return stone(s + u, z);
    });
    PZ.box(u, v, h, h + .12, hw + .07, hd + .07, STONE_L); // the cornice
    cap(u, v, h + .12, hw - .08);
    for (double du = -hw.toDouble(); du <= hw; du += .3) {
      PZ.shadow(u + du, v, .6, .55);
    }
  }

  // fuerte-base.js: cap
  /// A sentry box's top: a stepped dome (three rings, each smaller) and a knob.
  void cap(num u, num v, num z, num r) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    const T = [236, 214, 176];
    k.drum(x, y, z, z + .2, r, STONE_L, (_, _) => _rgb(T));
    k.drum(x, y, z + .2, z + .38, r * .72, STONE_L, (_, _) => _rgb(T));
    k.drum(x, y, z + .38, z + .52, r * .42, STONE_L, (_, _) => _rgb(T));
    PZ.ball(u, v, z + .6, .08, const [240, 206, 110], 'smooth');
  }

  // fuerte-base.js: table
  /// A party table, long across the picture: a white top with red squares, an apron that hangs nearly to the ground
  /// (top z .74).
  void table(
    num u,
    num v,
    num hw, [
    num hd = .5,
    List<num> c = const [214, 84, 74],
  ]) {
    for (final p in [
      [-hw + .1, -hd + .1],
      [hw - .1, -hd + .1],
      [-hw + .1, hd - .1],
      [hw - .1, hd - .1],
    ]) {
      PZ.post(u + p[0], v + p[1], 0, .7, .04, const [120, 84, 52]);
    }
    PZ.box(u, v, .16, .74, hw, hd, const [250, 246, 236], (s, t, z, face) {
      if (face == 'top') {
        return (((((s + 20) / .2).floor() + ((t + 20) / .2).floor()) & 1) != 0)
            ? e.rgb(
                math.min<num>(255, c[0] + 26),
                math.min<num>(255, c[1] + 26),
                math.min<num>(255, c[2] + 26),
              )
            : e.rgb(252, 250, 244);
      }
      if (face == 'front') {
        return z < .22
            ? (jsMod(s + 20, .2) < .1 ? 0 : _rgb(c))
            : (z > .66
                  ? e.rgb(c[0] - 30, c[1] - 30, c[2] - 30)
                  : (jsMod(s + 20, .4) < .2 ? _rgb(c) : e.rgb(244, 238, 226)));
      }
      return e.rgb(c[0] - 40, c[1] - 40, c[2] - 40);
    });
    for (double du = -hw.toDouble(); du <= hw; du += .3) {
      PZ.shadow(u + du, v, .4, hd + .1);
    }
  }

  // fuerte-base.js: cord
  /// A line (a cord) across the picture at [v], from `(u0, z0)` to `(u1, z1)`, sagging a little:
  /// for lanterns, a curtain, photos.
  void cord(
    num u0,
    num u1,
    num v,
    num z0, [
    num? z1,
    num sag = .12,
    List<num> c = const [70, 60, 60],
  ]) {
    final zz1 = z1 ?? z0;
    final n = ((u1 - u0) * 26).ceil();
    for (var kk = 0; kk <= n; kk++) {
      final a = kk / n, p = PZ.xy(u0 + (u1 - u0) * a, v), x = p[0], y = p[1];
      e.plot(x, y, z0 + (zz1 - z0) * a - math.sin(a * math.pi) * sag, _rgb(c));
    }
  }

  // fuerte-base.js: stool
  /// A wooden stool.
  void stool(
    num u,
    num v, [
    num h = .46,
    num r = .22,
    List<num> c = const [176, 122, 76],
    num z0 = 0,
  ]) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    final leg = <num>[c[0] - 40, c[1] - 40, c[2] - 40];
    for (final q in const [
      [-.13, -.13],
      [.13, -.13],
      [-.13, .13],
      [.13, .13],
    ]) {
      PZ.post(u + q[0], v + q[1], z0, z0 + h - .06, .03, leg);
    }
    k.drum(x, y, z0 + h - .07, z0 + h, r, c);
    if (z0 == 0) PZ.shadow(u, v, .3, r + .05);
  }

  // fuerte-base.js: yardWall
  /// The yard's inner wall at `v = 0`, across the picture: stone, battlements, the sky over it;
  /// [holes] = arches (each `[u0, u1, z0, z1]`).
  void yardWall([
    num h = 2.6,
    List<List<num>> holes = const [],
    num u0 = -4.7,
    num u1 = 4.7,
  ]) {
    PZ.flat(
      u0,
      -.6,
      u1,
      0,
      h - .34,
      (u, v) => flags(u, v * 2, 0, 0, const [176, 156, 124]),
    );
    PZ.wall(u0, u1, 0, 0, h, (u, z) {
      if (!solid(u, z, h)) return 0;
      for (final r in holes) {
        if (inArch(u, z, r)) return 0;
        final c = archRing(u, z, r);
        if (c != 0) return c;
      }
      if (z > h - .44 && z < h - .36) return _rgb(STONE_L);
      return stone(u, z);
    });
  }

  // fuerte-base.js: lights
  /// A string of small lights along a wall, at height [z], on the plane [v] (every other one warm).
  void lights(num u0, num u1, num v, num z, [num sag = .1]) {
    final n = jsRoundN((u1 - u0) / .42);
    cord(u0, u1, v, z, z, sag, const [60, 56, 60]);
    for (var kk = 0; kk <= n; kk++) {
      final a = kk / n,
          p = PZ.xy(u0 + (u1 - u0) * a, v + .02),
          x = p[0],
          y = p[1],
          zz = z - math.sin(a * math.pi) * sag - .07;
      final col = kk.remainder(2) != 0
          ? e.rgb(255, 236, 150)
          : e.rgb(255, 176, 120);
      for (final d in const [
        [0.0, 0.0],
        [.03, 0.0],
        [0.0, -.04],
        [.03, -.04],
      ]) {
        k.plotGlow(x + d[0] * .7, y - d[0] * .7, zz + d[1], col);
      }
    }
  }
}
