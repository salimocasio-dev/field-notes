// Port of docs/proyecto/pixel/playa-base.js: La playa's shared kit (`PL`), call for call: what the four scene sets of
// place 7 share (orilla, sombrilla, ropa, cielo). Built on top of La plaza's painters (lib/src/plaza/plaza_base.dart:
// PZ.box, PZ.wall, PZ.flat, PZ.slope, PZ.post, PZ.ball). Laid out square to the picture, in u, v: u across, v down
// towards the camera. The sea is at the top: the water's edge is a line of constant v, the wet sand a strip below it,
// the dry sand below that; beyond the horizon's v there is no ground, and the sky shows.
//
// First writer: order 62b (La playa, scene `orilla`). The builders of sombrilla, ropa and cielo copy it and add to it
// only by adding. The whole file is ported (including umbrella, heap, bucket), matching the JavaScript pixel for pixel.
// The file's names are kept, capitals included, so the port reads line for line against it (page 12, section 6).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// mapa.js: `KIND_SAND` (KIND_NONE 0, SAND 1, WATER 2, GRASS 3, ROAD 4).
const int KIND_SAND = 1;

/// Parameters of a beach's ground (playa-base.js `PL.ground`'s `B`).
class PlayaBeach {
  const PlayaBeach({
    required this.edge,
    required this.wet,
    required this.deep,
    required this.hor,
  });

  final double edge;
  final double wet;
  final double deep;
  final double hor;
}

/// One pixel of [PlayaBase.ground]: its colour and kind (`'mar'`, `'mojada'`, `'arena'`).
typedef PlayaGround = ({int color, String kind});

/// Port of playa-base.js (`PL`).
class PlayaBase {
  PlayaBase(this.PZ) : k = PZ.k, e = PZ.e, b = PZ.b;

  final PlazaBase PZ;
  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  // playa-base.js: SAND, WET, SHALLOW, MID, DEEP, FOAM
  static const List<List<int>> SAND = [
    [206, 186, 140],
    [222, 204, 160],
    [234, 218, 178],
    [244, 232, 198],
  ];
  static const List<List<int>> WET = [
    [150, 132, 104],
    [166, 148, 116],
    [180, 162, 128],
    [194, 176, 142],
  ];
  static const List<int> SHALLOW = [130, 218, 208];
  static const List<int> MID = [78, 182, 210];
  static const List<int> DEEP = [44, 122, 196];
  static const List<int> FOAM = [252, 252, 250];

  // playa-base.js: mix
  static List<double> _mix(List<num> a, List<num> b, double t) => [
    a[0] + (b[0] - a[0]) * t,
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
  ];

  // playa-base.js: ground
  /// The ground of a beach. Returns `(color, kind)` (`'mar'`, `'mojada'`, `'arena'`), or null beyond the horizon.
  PlayaGround? ground(num u, num v, int ix, int iy, PlayaBeach B) {
    if (v < B.hor) return null;
    final wob = math.sin(u * 1.7) * .12 + math.sin(u * 4.1 + 1) * .05;
    if (v < B.edge + wob) {
      final d = (B.edge + wob) - v;
      if (d < .13) {
        return (color: e.rgb(FOAM[0], FOAM[1], FOAM[2]), kind: 'mar');
      }
      final crest = jsMod(
        v * 1.0 + math.sin(u * 1.3 + (v * 1.0).floor() * 2.1) * .22 + 80,
        1.0,
      );
      if (d > .5 && crest < .09 && e.hash(ix >> 1, (v * 6).floor()) < .8) {
        final col = d > (B.edge - B.deep) ? const [176, 214, 240] : FOAM;
        return (color: e.rgb(col[0], col[1], col[2]), kind: 'mar');
      }
      final t = e.clamp<double>(d / math.max(.01, B.edge - B.deep), 0, 1.6);
      final c = t < 1
          ? _mix(SHALLOW, MID, t)
          : _mix(MID, DEEP, e.clamp<double>((t - 1) / .35, 0, 1));
      final dth = (e.bayerAt(ix, iy) - .5) * 14;
      return (
        color: e.rgb(c[0] + dth, c[1] + dth, c[2] + dth * .6),
        kind: 'mar',
      );
    }
    if (v < B.edge + wob + B.wet) {
      final t = (v - B.edge - wob) / B.wet;
      return (
        color: b.toneOf(WET, .3 + t * .5 + e.noise(u * 2, v * 2) * .2, ix, iy),
        kind: 'mojada',
      );
    }
    final rip = math.sin(v * 9 + math.sin(u * 1.1) * 2.5) > .93 ? -.18 : 0.0;
    return (
      color: b.toneOf(
        SAND,
        .5 +
            e.noise(u * 1.3, v * 1.3) * .5 +
            rip +
            (e.hash(ix, iy) < .02 ? -.3 : 0),
        ix,
        iy,
      ),
      kind: 'arena',
    );
  }

  // playa-base.js: palm
  /// A palm at (u, v): h high, leaning by lean (set-kit's swayPalm; its fronds sway: the set's frame() calls drawLeaves).
  List<num> palm(
    num u,
    num v,
    num h,
    num lean,
    num seed, [
    num size = 1,
    Light? L,
  ]) {
    final p = PZ.xy(u, v);
    return k.swayPalm(p[0], p[1], h, lean, seed, size, L);
  }

  // playa-base.js: blanket
  /// A blanket or a towel flat on the sand: stripes across.
  void blanket(
    num u0,
    num v0,
    num u1,
    num v1, [
    List<num> a = const [214, 62, 54],
    List<num> bb = const [250, 246, 236],
  ]) {
    PZ.flat(
      u0,
      v0,
      u1,
      v1,
      .03,
      (u, v) => (u - u0 < .08 || u1 - u < .08)
          ? e.rgb(bb[0], bb[1], bb[2])
          : (((u - u0) / .32).floor().remainder(2) != 0)
          ? b.shade(a, 3.2, u * 4, v * 4, .2)
          : b.shade(bb, 3.2, u * 4, v * 4, .2),
    );
  }

  // playa-base.js: umbrella
  /// A beach umbrella stuck in the sand: a pole and a striped canopy (eight panels seen from in front and above), open or shut.
  void umbrella(
    num u,
    num v, [
    num h = 2.6,
    num r = 1.5,
    bool open = true,
    List<num> a = const [226, 60, 50],
    List<num> bb = const [250, 246, 236],
  ]) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    PZ.post(u, v, 0, h, .045, const [230, 226, 214]);
    if (!open) {
      for (num z = h - 1.5; z <= h; z += .02) {
        final rr = .05 + (h - z) * .09;
        for (num t = 0; t < 6.3; t += .2) {
          e.plot(
            x + math.cos(t) * rr,
            y + math.sin(t) * rr,
            z,
            b.shade(
              ((t / .79).floor().remainder(2) != 0) ? a : bb,
              1.6 + math.cos(t - .8),
              t,
              z,
            ),
          );
        }
      }
      return;
    }
    for (num kk = 0; kk <= 1; kk += .012) {
      final rr = r * kk, z = h + .28 - .5 * kk * kk;
      for (num t = 0; t < 6.3; t += .012 / math.max(.08, kk)) {
        e.plot(
          x + math.cos(t) * rr,
          y + math.sin(t) * rr,
          z,
          b.shade(
            (((t + .39) / .785).floor().remainder(2) != 0) ? a : bb,
            2.2 + math.cos(t - .9) * 1.1,
            t * 3,
            kk * 6,
            .25,
          ),
        );
      }
    }
    PZ.ball(u, v, h + .32, .07, const [250, 206, 70]);
    for (num t = 0; t < 6.3; t += .4) {
      for (final kk in const [.4, .8]) {
        e.castShadow(
          x + math.cos(t) * r * kk,
          y + math.sin(t) * r * kk,
          h - .3,
          r * .3,
          1,
          .25,
        );
      }
    }
    e.castShadow(x, y, h - .3, r * .5, 1, .25);
  }

  // playa-base.js: heap
  /// A heap of sand.
  void heap(num u, num v, [num r = .6, num h = .34]) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    for (var kk = 0; kk < 14; kk++) {
      final a = kk * 2.4, d = r * .55 * math.sqrt(kk / 14);
      e.sphere(
        x + math.cos(a) * d,
        y + math.sin(a) * d,
        h * (1 - d / r) * .6,
        r * (.55 - d / r * .25),
        const [240, 226, 190],
        'rough',
      );
    }
    e.castShadow(x, y, .2, r * .8);
  }

  // playa-base.js: bucket
  /// A bucket on the sand.
  void bucket(num u, num v, [List<num> c = const [226, 60, 70]]) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    k.drum(
      x,
      y,
      0,
      .34,
      .17,
      c,
      (a, bb) => jsHypot(a, bb) < .13 ? e.rgb(60, 40, 40) : 0,
    );
    e.castShadow(x, y, .2, .2);
  }

  // playa-base.js: sky
  /// The sky by the hour with a sun; hora: manana, mediodia, tarde, ocaso, gris, noche. sun: [sx, sy, r] or null.
  PzSky sky(String hora, [List<num>? sun]) => PZ.CL.sky(
    const {
          'manana': 'manana',
          'mediodia': 'manana',
          'sol': 'manana',
          'tarde': 'manana',
          'ocaso': 'tarde',
          'gris': 'gris',
          'noche': 'noche',
        }[hora] ??
        'manana',
    sun,
  );

  // playa-base.js: light
  /// The light of the hour on everything drawn (call before skyFill).
  Light? light(String hora) {
    const L = <String, Light>{
      'tarde': Light([1.0, .95, .86], [8, 3, -6]),
      'ocaso': Light([1.0, .86, .74], [16, 0, -12]),
      'sol': Light([1.06, 1.04, .98], [6, 6, 2]),
      'gris': Light([.8, .82, .88], [0, 0, 6]),
      'noche': Light([.55, .58, .82], [-6, -4, 16]),
    };
    final l = L[hora];
    if (l != null) k.lightPass(l.m, l.a, false);
    return l;
  }
}
