// Port of docs/proyecto/pixel/camino-set.html: El camino's set, every state, call for call (order 33a's set reference,
// order 33b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El camino's set is built on (camino-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (0, 4), shadows to (.9, -.1).
PpEngine caminoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 4,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (camino-set.html: `SET`, from the address). The value is the page's own string. (The page's
/// `trees=row` is a look candidate, not a state: the sheet is made for `old`, the only one ported.)
class CaminoState {
  const CaminoState({this.gran = '1'});

  /// camino-set.html: `pick('gran', ['0', '1'], '1')`, from a query (`?gran=1`); a value the page does not allow takes
  /// its default, as there.
  factory CaminoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final v = q['gran'];
    return CaminoState(gran: v == '0' || v == '1' ? v! : '1');
  }

  /// A key of the sheet's `setKey` table (`"1"`: gran) read back.
  factory CaminoState.fromKey(String key) {
    if (key != '0' && key != '1') {
      throw ArgumentError.value(key, 'key', 'not a key of El camino\'s set');
    }
    return CaminoState(gran: key);
  }

  final String gran;

  /// The sheet's key: gran (`setKey.key`, e.g. "1").
  String get key => gran;
}

/* ---------- the plan: every thing placed from its old screen point (the ground under it) ---------- */

// camino-set.html: P
List<num> P(num x, num y, [num z = 0]) => [x, y, z];

// the marks on the path (the old MARCA: 0 the arch's end of the path, 1 to 7 the stones, 8 before the big tree)
const List<List<int>> MARCA = [
  [66, 182],
  [79, 175],
  [92, 168],
  [105, 162],
  [118, 156],
  [131, 151],
  [144, 146],
  [157, 142],
  [170, 139],
];
// the three small trees (their feet) and the big tree
const List<List<int>> ARBOL_OLD = [
  [70, 120],
  [112, 116],
  [154, 112],
];
const List<List<int>> ARBOL = ARBOL_OLD;
const List<int> GRAN = [204, 103];
const double HZ = 100;
const double SMALL_CROWN_W =
    2 * 15.6; // a small crown's width (px, its clusters' middles)
const List<int> WOOD = [150, 98, 56],
    TRUNK = [118, 82, 50],
    IRON = [64, 66, 82],
    STONEP = [190, 178, 156];

// the posts at AC +- AH in y (their half width APW, height APH); the arch's rise
const double AH = .55, APW = .08, APH = 2.62, ARISE = .36;
const double PATH_HALF = .6; // its half width (the frog walks at its far edge, Carmen on the lawn on our side)
const double STONE_R = .3;

/* ---------- the ground: the lawn (El frente's grass, calm, as El patio's) and the path ---------- */
const double LAWN_T = 3.45;
const List<int> BLADE = [2, 2, 3, 3, 4];
// trodden earth, the old path's colours (#E8CE96, the specks #D8B67A, the edge #C8A468), worn lighter down its middle
const List<List<int>> PATHC = [
  [184, 150, 96],
  [200, 164, 104],
  [216, 182, 122],
  [232, 206, 150],
  [242, 222, 172],
];

// the small trees' leaves
const List<List<int>> LEAF = [
  [52, 128, 66],
  [66, 148, 76],
  [86, 170, 88],
  [118, 196, 108],
];

// the big tree's lobes [sx, sy, rx, ry, count] and where none of its clusters grows
const List<List<num>> BIG_LOBES = [
  [205, 28, 30, 24, 420],
  [178, 26, 14, 12, 90],
  [188, 48, 11, 10, 60],
  [229, 46, 13, 12, 60],
  [201, 3, 22, 12, 90],
];
const List<num> BIG_CLIP = [174, 64, 160, 72];
const double BIG_R = .37; // the trunk's radius at its foot (a small one's .11)

/* ---------- the sky, the hills, the sun: El frente's by day ---------- */
const List<List<int>> _SKY_BANDS = [
      [58, 134, 230],
      [85, 159, 242],
      [120, 186, 250],
      [162, 211, 255],
      [208, 234, 255],
    ],
    _SKY_FAR = [
      [116, 180, 162],
      [156, 208, 188],
      [94, 158, 144],
    ],
    _SKY_NEAR = [
      [78, 158, 94],
      [124, 203, 122],
      [62, 136, 80],
    ],
    _SKY_SUN = [
      [220, 150, 30],
      [248, 200, 56],
      [255, 224, 112],
      [255, 244, 176],
    ];
const List<num> SUN = [38, 47, 9];
const List<List<num>> CLOUDS = [
  [128, 6, .7],
  [140, 24, .8],
  [120, 44, .8],
];

/// The ground and its grass (camino-set.html: `GROUND_CACHE`): made once per page, so here once per engine (the ground
/// is the same in both states).
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

/// The bench's place (camino-set.html: `BENCH`).
typedef Bench = ({
  double cx,
  double cy,
  double hl,
  double a0,
  double a1,
  double zs,
});

/// The set of El camino in one state, built into an engine (camino-set.html, from "the plan" to "bake one state").
class CaminoSet {
  CaminoSet(this.e, this.b, this.SET) : k = SetKit(e, b) {
    AC = Gs(37, 167.5);
    PATH_PTS = () {
      final m = [for (final p in MARCA) Gs(p[0], p[1])];
      final far = [AC[0] - 4, AC[1], 0.0]; // off the picture's left edge
      final d = [m[8][0] - m[7][0], m[8][1] - m[7][1]],
          l = math.sqrt(d[0] * d[0] + d[1] * d[1]);
      final end = [
        m[8][0] + d[0] / l * 5,
        m[8][1] + d[1] / l * 5,
        0.0,
      ]; // on past the big tree, off the picture's right edge
      return [far, AC, ...m, end];
    }();
    STONES = [for (final p in MARCA.sublist(1, 8)) Gs(p[0], p[1])];
    BENCH = () {
      final fl = Gs(86, 140), hl = .51, a0 = -.24, a1 = .24;
      return (cx: fl[0] - a1, cy: fl[1] - hl, hl: hl, a0: a0, a1: a1, zs: .4);
    }();
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // camino-set.html: SET
  final CaminoState SET;

  int get W => e.W;
  int get H => e.H;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // camino-set.html: Gs. The ground point under a screen point
  List<double> Gs(num sx, num sy) {
    final g = e.unproject(sx, sy);
    return [g.x, g.y, 0];
  }

  // camino-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  /* ---------- the path ---------- */

  // the arch over the path's first leg: its middle on the ground at screen (37, 167.5)
  late final List<double> AC;
  late final List<List<double>> PATH_PTS;

  // camino-set.html: pathDist. Distance (world) from a ground point to the path's middle line
  double pathDist(num x, num y) {
    var best = 1e9;
    for (var kk = 0; kk + 1 < PATH_PTS.length; kk++) {
      final a = PATH_PTS[kk],
          bb = PATH_PTS[kk + 1],
          dx = bb[0] - a[0],
          dy = bb[1] - a[1],
          l = dx * dx + dy * dy;
      final t = e.clamp<double>(((x - a[0]) * dx + (y - a[1]) * dy) / l, 0, 1),
          ex = x - a[0] - dx * t,
          ey = y - a[1] - dy * t,
          d = math.sqrt(ex * ex + ey * ey);
      if (d < best) best = d;
    }
    return best;
  }

  // the stones: flat, worn, grey, at marks 1 to 7
  late final List<List<double>> STONES;

  /* ---------- the ground ---------- */

  List<List<int>> get LAWN => e.GRASS;

  // camino-set.html, at load: the blades take the lawn's tones (tuftLit, tuftDark: this page's own copies of the
  // engine's)
  void _tuftColours() {
    for (var kk = 0; kk < 5; kk++) {
      final c = LAWN[BLADE[kk]];
      e.tuftLit[kk] = _rgbOf(c);
      e.tuftDark[kk] = e.rgb(c[0] * .54, c[1] * .52, c[2] * .72);
    }
  }

  // camino-set.html: lawnAt
  int lawnAt(num x, num y, int ix, int iy) {
    final t =
        LAWN_T +
        (e.noise(x * .3, y * .3) - .5) * .6 +
        (e.bayerAt(ix, iy) - .5) * .8 +
        (e.hash(ix, iy) - .5) * .25;
    return _rgbOf(LAWN[e.clamp(t.floor(), 2, 4)]);
  }

  // camino-set.html: caminoGround
  int caminoGround(double x, double y, int ix, int iy, int i) {
    if (iy + .5 < HZ) return 0; // above the horizon: the hills and the sky
    final d = pathDist(x, y);
    if (d < PATH_HALF) {
      e.kinds[i] = KIND_ROAD;
      final ee = PATH_HALF - d;
      // round 2: the edge is soft earth, ragged into the lawn
      if (ee < .09 &&
          e.bayerAt(ix, iy) > ee / .09 + (e.hash(ix, iy) - .5) * .3) {
        e.kinds[i] = e.KIND_GRASS;
        return lawnAt(x, y, ix, iy);
      }
      final t =
          2.75 +
          (ee > .25 ? .35 : 0) +
          (e.noise(x * 1.7, y * 1.7) - .5) * .9 +
          (e.bayerAt(ix, iy) - .5) * .7 +
          (e.hash(ix, iy) - .5) * .3;
      return _rgbOf(PATHC[e.clamp(t.floor(), 2, 4)]);
    }
    e.kinds[i] = e.KIND_GRASS;
    return lawnAt(x, y, ix, iy);
  }

  // camino-set.html: stones. Low slabs (a lit top, a dark rim on their near side), drawn after the ground
  void stones() {
    final R = e.rampOf(const [176, 168, 150]);
    k.part('camino', () {
      for (final s in STONES) {
        final sp = SCR(s[0], s[1]), sx = sp[0], sy = sp[1];
        // an oval on the screen 13 x 6, its middle at the mark: the world points under it, raised .05
        for (var iy = (sy - 4).floor(); iy <= (sy + 4).ceil(); iy++) {
          for (var ix = (sx - 8).floor(); ix <= (sx + 8).ceil(); ix++) {
            final dx = (ix + .5 - sx) / 6.5,
                dy = (iy + .5 - sy) / 3,
                q = dx * dx + dy * dy;
            if (q > 1) continue;
            final g = e.unproject(ix + .5, iy + .5 + .05 * e.COS * e.S);
            final top = dy < .35 - .25 * dx;
            final col = q > .72 && dy > 0
                ? R[0]
                : top
                ? R[e.clamp(
                    (3.1 -
                            dy * 1.2 +
                            (e.hash(ix, iy) - .5) * .7 +
                            (e.bayerAt(ix, iy) - .5) * .5)
                        .floor(),
                    1,
                    4,
                  )]
                : R[2];
            e.plot(g.x, g.y, .05, col);
          }
        }
      }
    });
  }

  /* ---------- the arch ---------- */

  // camino-set.html: arch. Two square stone posts with caps, an iron arch between their tops, a small ball on each cap
  void arch() {
    k.part('porton', () {
      final ax = AC[0], ay = AC[1], Ir = e.rampOf(IRON);
      for (final s in const [1, -1]) {
        final py = ay + s * AH;
        b.block(ax - APW, py - APW, 0, ax + APW, py + APW, APH, STONEP, [
          for (final v in STONEP) v * 1.08,
        ]);
        b.block(
          ax - APW - .02,
          py - APW - .02,
          APH,
          ax + APW + .02,
          py + APW + .02,
          APH + .1,
          [for (final v in STONEP) v * .96],
          [for (final v in STONEP) math.min(255, v * 1.12)],
        );
        e.sphere(
          ax,
          py,
          APH + .19,
          .085,
          STONEP,
          'solid',
        ); // a stone ball on each cap
        b.block(
          ax - APW - .01,
          py - APW - .01,
          0,
          ax + APW + .01,
          py + APW + .01,
          .22,
          [for (final v in STONEP) v * .8],
        ); // a darker plinth at the foot
      }
      // the iron arch: a band .07 thick rising ARISE over the posts' tops, a second, thinner one under it, and a straight
      // bar across from cap to cap
      void band(num rise, num z0, num th, int lit) {
        for (double t = 0; t <= 1; t += .0015) {
          final a = math.pi * t,
              yy = ay + AH * math.cos(a),
              zz = z0 + rise * math.sin(a);
          for (double w = -.035; w <= .035; w += .012) {
            for (double h = 0; h <= th; h += .012) {
              e.plot(
                ax + w,
                yy,
                zz + h,
                Ir[h > th - .02
                    ? lit
                    : w > 0
                    ? 1
                    : 2],
              );
            }
          }
        }
      }

      band(ARISE, APH + .1, .08, 4);
      band(ARISE * .55, APH + .1, .05, 3);
      for (double yy = ay - AH; yy <= ay + AH; yy += .01) {
        for (double w = -.03; w <= .03; w += .012) {
          for (double h = 0; h <= .06; h += .012) {
            e.plot(ax + w, yy, APH + .04 + h, Ir[h > .04 ? 3 : 1]);
          }
        }
      }
      // short iron bars between the two arcs
      for (final t in const [.2, .35, .5, .65, .8]) {
        final a = math.pi * t,
            yy = ay + AH * math.cos(a),
            z0 = APH + .1 + ARISE * .55 * math.sin(a),
            z1 = APH + .1 + ARISE * math.sin(a);
        for (double z = z0; z <= z1; z += .01) {
          for (double w = -.02; w <= .02; w += .012) {
            e.plot(ax + w, yy, z, Ir[1]);
          }
        }
      }
      // round 2: a small green board hangs under the arch's top, in its plane (the park's sign, no words)
      {
        const bw = .26;
        const bz0 = APH + .1 + ARISE * .55 - .26, bz1 = bz0 + .2;
        final G = e.rampOf(const [70, 140, 80]);
        final edgeC = e.rampOf(const [236, 226, 190])[3];
        for (double yy = ay - bw; yy <= ay + bw; yy += .01) {
          for (double zz = bz0; zz <= bz1; zz += .01) {
            final edge =
                (yy - ay).abs() > bw - .035 || zz < bz0 + .03 || zz > bz1 - .03;
            e.plot(
              ax + .04,
              yy,
              zz,
              edge
                  ? edgeC
                  : G[((yy + zz * 3) * 40).floor().remainder(7) == 0 ? 3 : 2],
            );
          }
        }
        for (final yy in [ay - bw + .06, ay + bw - .06]) {
          for (double zz = bz1; zz <= APH + .1 + ARISE * .55; zz += .01) {
            e.plot(ax + .04, yy, zz, Ir[1]);
          }
        }
      }
      // its shadow (round 3): only a short contact shadow at each post's foot
      for (final s in const [1, -1]) {
        for (double z = .02; z <= .1; z += .04) {
          e.castShadow(ax, ay + s * AH, z, .1, 1, 0);
        }
      }
    });
  }

  /* ---------- the small trees: a straight trunk, a round crown of leaf clusters ---------- */

  // camino-set.html: smallTree. The crown's middle on the screen 30 rows over the foot, as wide and as tall as the old
  void smallTree(int i) {
    final sx = ARBOL[i][0], sy = ARBOL[i][1], f = Gs(sx, sy);
    final fx = f[0], fy = f[1];
    k.part('arbol$i', () {
      final zc = 30 / (e.COS * e.S);
      e.capsule(
        [fx, fy, 0],
        [fx, fy, zc - .1],
        .11,
        .08,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        [fx - .12, fy + .12, 0],
        [fx + .12, fy - .12, 0],
        .07,
        .07,
        (_) => TRUNK,
        'rough',
      );
      // round 2: the trunk's shadow in one piece from its foot to the crown's
      for (double z = .03; z < zc; z += .08) {
        e.castShadow(fx, fy, z, .14, 1, 0);
      }
      // the crown: an ellipsoid of clusters, 16 px across (u), 13 rows (z) round the middle, a little deep in v
      final ru = 15.6 / e.S, rz = 12.6 / (e.COS * e.S);
      const rv = .5;
      const n = 80;
      for (var kk = 0; kk < n; kk++) {
        double h(int a, int bb) => e.hash(kk * 13 + i * 101 + a, bb);
        final th = h(1, 7) * 6.283,
            ph = math.acos(2 * h(2, 8) - 1),
                // Math.cbrt, as the porting table says
                d =
                math.pow(h(3, 9), 1 / 3) * .88;
        final du = math.cos(th) * math.sin(ph) * d,
            dv = math.sin(th) * math.sin(ph) * d,
            dz = math.cos(ph) * d;
        final u = (fx - fy) / e.R2 + du * ru,
            v = (fx + fy) / e.R2 + dv * rv,
            z = zc + dz * rz;
        final tone = h(4, 10) * .6 + dz * .5 - du * .25 + .3;
        final col =
            LEAF[tone > 1
                ? 3
                : tone > .62
                ? 2
                : tone > .25
                ? 1
                : 0];
        final q = k.UVW(u, v, z);
        e.sphere(q[0], q[1], q[2], .16 + h(5, 11) * .1, col, 'rough');
      }
      // the crown's shadow on the lawn (to its right, as the trunk's)
      e.castShadow(fx, fy, zc, .55, 1, .5);
    });
  }

  /* ---------- the bench: on the path's far side, its long side along y, facing the path (+x) ---------- */

  // camino-set.html: BENCH
  late final Bench BENCH;

  // camino-set.html: bench
  void bench() {
    final B = BENCH;
    const LEG = [92, 60, 36];
    k.part('banco', () {
      final cx = B.cx, cy = B.cy, hl = B.hl, a0 = B.a0, a1 = B.a1, zs = B.zs;
      // the legs: a pair at each end, and a stretcher between each pair
      for (final bb in [hl - .07, -hl + .07]) {
        for (final a in [a1 - .06, a0 + .06]) {
          b.block(
            cx + a - .035,
            cy + bb - .035,
            0,
            cx + a + .035,
            cy + bb + .035,
            zs - .05,
            LEG,
          );
        }
        b.block(
          cx + a0 + .06,
          cy + bb - .025,
          .1,
          cx + a1 - .06,
          cy + bb + .025,
          .16,
          LEG,
        );
      }
      // the seat: three planks along y, a dark gap between them, each a step lighter towards the front
      final pw = (a1 - a0) / 3;
      for (var kk = 0; kk < 3; kk++) {
        final s0 = a0 + kk * pw, s1 = s0 + pw - .03;
        b.block(cx + s0, cy - hl, zs - .06, cx + s1, cy + hl, zs, WOOD, [
          for (final v in WOOD) math.min(255, v * (1.12 + kk * .05)),
        ]);
      }
      // its shadow on the lawn
      for (var bb = -hl; bb <= hl; bb += .2) {
        e.castShadow(cx, cy + bb, zs, .22);
      }
    });
  }

  /* ---------- the big tree (round 2): built like the old one, a big old tree at the picture's right ---------- */

  // camino-set.html: bigTree
  void bigTree() {
    if (SET.gran != '1') return;
    final f = Gs(GRAN[0], GRAN[1]),
        fx = f[0],
        fy = f[1],
        tu = (fx - fy) / e.R2,
        tv = (fx + fy) / e.R2;
    List<double> Pu(num u, num v, [num z = 0]) => k.UVW(u, v, z);
    final TOP = (GRAN[1] - 36) / (e.COS * e.S);
    k.part('grande', () {
      e.capsule(
        Pu(tu, tv, 0),
        Pu(tu, tv, TOP),
        BIG_R,
        .27,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu - .38, tv, 0),
        Pu(tu + .38, tv, 0),
        .2,
        .2,
        (_) => TRUNK,
        'rough',
      ); // the flare of its roots
      // its limbs, hidden in the crown
      e.capsule(
        Pu(tu, tv, TOP - .4),
        Pu(tu - .6, tv - .1, TOP + .5),
        .17,
        .12,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu, tv, TOP - .4),
        Pu(tu + .55, tv - .1, TOP + .55),
        .17,
        .12,
        (_) => TRUNK,
        'rough',
      );
      // its shadow, one piece from its foot: the trunk's, cast all the way up
      for (double z = .03; z < TOP + .6; z += .08) {
        final p = Pu(tu, tv);
        e.castShadow(p[0], p[1], z, .3, 1, 0);
      }
      double UX(num sx) => (sx - e.OX) / e.S;
      final cv = tv - .1;
      double SYv(num v, [num z = 0]) => e.OY + (v * e.SIN - z * e.COS) * e.S;
      var n = 0;
      for (final lobe in BIG_LOBES) {
        final sx = lobe[0], sy = lobe[1], rx = lobe[2], ry = lobe[3];
        final count = lobe[4];
        final cu = UX(sx),
            cz = (SYv(cv) - sy) / (e.COS * e.S),
            ru = rx / e.S,
            rz = ry / (e.COS * e.S);
        for (var kk = 0; kk < count; kk++, n++) {
          double h(int a, int bb) => e.hash(n * 13 + 977 + a, bb);
          final th = h(1, 7) * 6.283,
              ph = math.acos(2 * h(2, 8) - 1),
                  // Math.cbrt, as the porting table says
                  d =
                  math.pow(h(3, 9), 1 / 3) * .9;
          final du = math.cos(th) * math.sin(ph) * d,
              dv = math.sin(th) * math.sin(ph) * d,
              dz = math.cos(ph) * d;
          final pu = cu + du * ru, pv = cv + dv * .7, pz = cz + dz * rz;
          final tone = h(4, 10) * .6 + dz * .5 - du * .25 + .3;
          final col =
              LEAF[tone > 1
                  ? 3
                  : tone > .62
                  ? 2
                  : tone > .25
                  ? 1
                  : 0];
          final r = .17 + h(5, 11) * .11,
              q = Pu(pu, pv, pz),
              c = e.project(q[0], q[1], q[2]),
              rp = r * e.S;
          if ((c.sx - rp < BIG_CLIP[0] && c.sy + rp > BIG_CLIP[1]) ||
              c.sx - rp < BIG_CLIP[2] ||
              c.sy + rp > BIG_CLIP[3]) {
            continue;
          }
          e.capture = <num>[];
          e.sphere(q[0], q[1], q[2], r, col, 'rough');
          // k odd: no shadow each frame (the crown's shadow falls off the picture)
          final g = Pu(pu, pv);
          e.leaves.add(
            Leaf(
              x: g[0],
              y: g[1],
              z: pz,
              k: n * 2 + 1,
              r: .3,
              pixels: e.capture!,
            ),
          );
          e.capture = null;
        }
      }
    });
  }

  /* ---------- the sky ---------- */

  // camino-set.html: cloudAt
  int cloudAt(int ix, int iy) {
    for (final cl in CLOUDS) {
      final cx = cl[0], cy = cl[1], s = cl[2];
      bool el(num x0, num y0, num rx, num ry) {
        final dx = (ix + .5 - x0) / rx, dy = (iy + .5 - y0) / ry;
        return dx * dx + dy * dy <= 1;
      }

      if (el(cx, cy, 13 * s, 5 * s) ||
          el(cx - 9 * s, cy + 2, 8 * s, 4 * s) ||
          el(cx + 10 * s, cy + 2, 9 * s, 4 * s)) {
        return iy + .5 > cy + 2 * s
            ? e.rgb(214, 230, 248)
            : e.rgb(244, 248, 255);
      }
    }
    return 0;
  }

  /* ---------- bake one state ---------- */

  // camino-set.html: buildSet
  void buildSet() {
    _tuftColours();
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.pix.fillRange(0, e.pix.length, 0);
    e.kinds.fillRange(0, e.kinds.length, 0);
    e.ground.fillRange(0, e.ground.length, 0);
    e.shadowMask.fillRange(0, e.shadowMask.length, 0);
    e.staticShadow.fillRange(0, e.staticShadow.length, 0);
    e.tufts.clear();
    e.leaves.clear();
    e.pendingShadows.clear();
    k.slabTops.clear();
    k.glowReset();
    final cache = _groundCaches[e];
    if (cache == null) {
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = caminoGround(g.x, g.y, ix, iy, i);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      e.growGrass();
      _groundCaches[e] = _GroundCache(
        Uint32List.fromList(e.pix),
        Float32List.fromList(e.zb),
        Uint8List.fromList(e.kinds),
        Uint8List.fromList(e.ground),
        List.of(e.tufts),
      );
    } else {
      e.pix.setAll(0, cache.pix);
      e.zb.setAll(0, cache.zb);
      e.kinds.setAll(0, cache.kinds);
      e.ground.setAll(0, cache.ground);
      e.tufts.addAll(cache.tufts);
    }
    e.groundZ.setAll(0, e.zb);
    stones();
    arch();
    for (var i = 0; i < 3; i++) {
      smallTree(i);
    }
    bench();
    bigTree();
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.skyFill((ix, iy) {
      final s = k.skyDisc(SUN[0], SUN[1], SUN[2], _SKY_SUN, ix, iy);
      if (s != 0) return s;
      final c = cloudAt(ix, iy);
      if (c != 0) return c;
      final hl = k.skyHills(HZ, _SKY_FAR, _SKY_NEAR, ix, iy);
      return hl != 0 ? hl : k.skyBands(_SKY_BANDS, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
