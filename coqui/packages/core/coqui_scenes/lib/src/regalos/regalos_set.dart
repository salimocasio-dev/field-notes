// Port of docs/proyecto/pixel/regalos-set.html: Los regalos's set (place 10, El fuerte, scene 3: `regalos`), call for
// call (order 76). Built on El fuerte's kit (lib/src/fuerte/fuerte_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fuerte/fuerte_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// regalos-set.html: ORIGIN.
const List<double> REGALOS_ORIGIN = [0, -34];

/// The engine Los regalos's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -34), shadows (.9, -.1).
PpEngine regalosEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: REGALOS_ORIGIN[0],
  originY: REGALOS_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The one state of the set (regalos-set.html: `SET = { hora: 'noche' }`; no address parameters).
class RegalosState {
  const RegalosState();

  /// regalos-set.html has no state query parameters; any query gives the one night state.
  factory RegalosState.fromQuery(String query) => const RegalosState();

  /// Accepts `"noche"` (ref folder key) or `""` (sheet's `setKey.key`).
  factory RegalosState.fromKey(String key) {
    if (key == KEY || key.isEmpty) return const RegalosState();
    throw ArgumentError.value(key, 'key', "not a key of Los regalos's set");
  }

  static const String KEY = 'noche';

  String get key => KEY;

  /// The page's query for this state (none).
  String get query => '';
}

/// regalos-set.html: E, the set's places (wall, arch, far dance-floor wall, curtain cord, bench, photos cord, lamps,
/// party table, step stool, low stool).
abstract final class RegalosE {
  static const double WALL = 2.6;
  static const List<double> ARCH = [-3.78, -2.1, 0.0, 2.05];
  static const double FAR = -1.7;
  static const ({double u0, double u1, double z, double v}) CURTAIN = (
    u0: -3.86,
    u1: -2.02,
    z: 2.16,
    v: .06,
  );
  static const ({double u, double v, double hw}) BENCH = (
    u: -1.02,
    v: .45,
    hw: .82,
  );
  static const ({double u0, double u1, double z, double v, List<double> pegs})
  PHOTOS = (u0: .25, u1: 3.3, z: 1.95, v: .05, pegs: [.6, 1.25, 1.9, 2.55]);
  static const List<List<double>> LAMPS = [
    [-1.02, 1.4],
    [3.62, 1.4],
  ];
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: 1.75,
    v: 2.9,
    hw: 1.6,
    hd: .6,
  );
  static const List<double> STEP = [3.2, .9, .3];
  static const List<double> STOOL = [1.75, 4.7, .34];
}

/// Port of regalos-set.html: builds the baked set into [e].
class RegalosSet {
  RegalosSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FT = FuerteBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FuerteBase FT;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  // regalos-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v < RegalosE.FAR) return 0;
    if (v < 0) {
      return (u > RegalosE.ARCH[0] - 1.2 && u < RegalosE.ARCH[1] + 1.2)
          ? FT.flags(u, v, ix, iy, const [255, 232, 160])
          : 0;
    }
    return FT.flags(u, v, ix, iy);
  }

  // regalos-set.html: wall
  void wall() {
    const A = RegalosE.ARCH;
    PZ.wall(
      A[0] - 1.2,
      A[1] + 1.2,
      RegalosE.FAR,
      0,
      1.25,
      (u, z) => FT.stone(u + .3, z, const [255, 226, 160]),
    );
    FT.lights(A[0] - .2, A[1] + .2, RegalosE.FAR + .04, 1.05, .1);
    FT.yardWall(RegalosE.WALL, const [A]);
    for (final l in RegalosE.LAMPS) {
      FT.wallLamp(l[0], 0, l[1], true);
    }
    const C = RegalosE.CURTAIN;
    for (final u in [C.u0, C.u1]) {
      PZ.box(u, .04, C.z - .04, C.z + .06, .04, .04, FuerteBase.IRON);
    }
    FT.cord(C.u0, C.u1, C.v, C.z, C.z, .05);
    const P = RegalosE.PHOTOS;
    for (final u in [P.u0, P.u1]) {
      PZ.box(u, .04, P.z - .04, P.z + .06, .04, .04, FuerteBase.IRON);
    }
    FT.cord(P.u0, P.u1, P.v, P.z, P.z, .08);
    for (final u in P.pegs) {
      PZ.box(u, .07, P.z - .16, P.z - .02, .03, .02, const [226, 190, 120]);
    }
  }

  // regalos-set.html: yard
  void yard() {
    PZ.seat(RegalosE.BENCH.u, RegalosE.BENCH.v, RegalosE.BENCH.hw);
    const T = RegalosE.TABLE;
    FT.table(T.u, T.v, T.hw, T.hd, const [96, 150, 206]);
    final su = RegalosE.STEP[0], sv = RegalosE.STEP[1], sh = RegalosE.STEP[2];
    PZ.box(su, sv, 0, sh, .26, .2, const [
      176,
      122,
      76,
    ], (s, t, z, face) => face == 'top' ? rgb(206, 158, 106) : 0);
    PZ.box(su, sv + .26, 0, sh / 2, .26, .1, const [
      150,
      104,
      62,
    ], (s, t, z, face) => face == 'top' ? rgb(190, 140, 92) : 0);
    PZ.shadow(su, sv, .2, .36);
    FT.stool(
      RegalosE.STOOL[0],
      RegalosE.STOOL[1],
      RegalosE.STOOL[2],
      .3,
      const [190, 140, 92],
    );
  }

  // regalos-set.html: skyOf
  int skyOf(int ix, int iy) => FT.night(ix, iy, 400, const [128, 6, 7]);

  // regalos-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(RegalosState state) {
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
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5);
        final i = iy * W + ix;
        final c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / R2 * COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('muro', wall);
    k.part('patio', yard);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [.86, .8, .8], const [4, 0, 8], false);
    k.skyFill(skyOf);
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // regalos-set.html: frame
  /// Restores the baked set and casts [casts].
  void frame(double t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
