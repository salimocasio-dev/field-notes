// Port of docs/proyecto/pixel/muralla-set.html: La muralla's set (place 10, El fuerte, scene 4: `muralla`), call
// for call (order 77). Built on El fuerte's kit (lib/src/fuerte/fuerte_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fuerte/fuerte_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// muralla-set.html: ORIGIN.
const List<double> MURALLA_ORIGIN = [0, -24];

/// The engine La muralla's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -24), shadows (.9, -.1).
PpEngine murallaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: MURALLA_ORIGIN[0],
  originY: MURALLA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The baked states of La muralla's set (muralla-set.html `SET = { hora }`: noche | tarde_noche).
class MurallaState {
  const MurallaState({this.hora = 'noche'});

  /// Parses `hora=noche` or `hora=tarde_noche`, falling back to `'noche'`.
  factory MurallaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return MurallaState(
      hora: h == 'noche' || h == 'tarde_noche' ? h! : 'noche',
    );
  }

  /// Accepts `"noche"` or `"tarde_noche"`.
  factory MurallaState.fromKey(String key) {
    if (key == 'noche' || key == 'tarde_noche') {
      return MurallaState(hora: key);
    }
    throw ArgumentError.value(key, 'key', "not a key of La muralla's set");
  }

  final String hora;

  bool get isLow => hora == 'tarde_noche';

  String get key => hora;

  /// The page's query for this state.
  String get query => 'hora=$hora';
}

/// muralla-set.html: E, the set's places (parapet, horizon, far land/road, sentry boxes, cord, bench, table, steps).
abstract final class MurallaE {
  static const double PARAPET = 1.0;
  static const int HOR = 34;
  static const ({int x0, int y0, int road}) LAND = (x0: 128, y0: 40, road: 46);
  static const List<({double u, double v, List<int> door})> BOXES = [
    (u: -3.0, v: 1.0, door: [206, 70, 64]),
    (u: 3.0, v: 1.0, door: [70, 110, 206]),
  ];
  static const ({
    double u0,
    double u1,
    double v,
    double z,
    double sag,
    List<double> at,
  })
  CORD = (u0: -2.5, u1: 2.5, v: 1.0, z: 2.38, sag: .25, at: [-1.2, 0, 1.2]);
  static const ({double u, double v, double hw}) BENCH = (
    u: 0,
    v: .45,
    hw: 1.9,
  );
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: -2.1,
    v: 5.7,
    hw: 1.5,
    hd: .6,
  );
  static const ({double u0, double u1, double v0, double v1}) STEPS = (
    u0: 2.2,
    u1: 3.7,
    v0: 6.2,
    v1: 8.4,
  );
  static const List<double> MID = [0, 3.0];
}

/// Port of muralla-set.html: builds the baked set into [e].
class MurallaSet {
  MurallaSet(this.e, this.b) : k = SetKit(e, b) {
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

  // muralla-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    const S = MurallaE.STEPS;
    if (v < 0) return 0;
    if (u > S.u0 && u < S.u1 && v > S.v0 && v < S.v1) {
      final step = ((v - S.v0) / .36).floor();
      final a = jsMod(v - S.v0, .36) / .36;
      return a < .16
          ? rgb(150 - step * 16, 136 - step * 15, 116 - step * 13)
          : rgb(118 - step * 15, 106 - step * 14, 92 - step * 12);
    }
    if (u > S.u0 - .09 && u < S.u1 + .09 && v > S.v0 - .12 && v < S.v1) {
      return rgb(226, 206, 170);
    }
    return FT.flags(u, v, ix, iy);
  }

  // muralla-set.html: parapet
  void parapet() {
    PZ.wall(
      -4.7,
      4.7,
      0,
      0,
      MurallaE.PARAPET,
      (u, z) => FT.solid(u, z, MurallaE.PARAPET)
          ? (z > MurallaE.PARAPET - .44 && z < MurallaE.PARAPET - .36
                ? rgb(
                    FuerteBase.STONE_L[0],
                    FuerteBase.STONE_L[1],
                    FuerteBase.STONE_L[2],
                  )
                : FT.stone(u, z + .1))
          : 0,
    );
    for (final B in MurallaE.BOXES) {
      FT.garita(B.u, B.v, B.door, true);
    }
  }

  // muralla-set.html: walk
  void walk() {
    PZ.seat(MurallaE.BENCH.u, MurallaE.BENCH.v, MurallaE.BENCH.hw, false);
    const T = MurallaE.TABLE;
    FT.table(T.u, T.v, T.hw, T.hd, const [206, 150, 70]);
    const S = MurallaE.STEPS;
    for (final u in [S.u0, S.u1]) {
      PZ.post(u, S.v0 - .06, 0, .8, .04, FuerteBase.IRON);
    }
    PZ.box(
      (S.u0 + S.u1) / 2,
      S.v0 - .06,
      .76,
      .82,
      (S.u1 - S.u0) / 2,
      .03,
      FuerteBase.IRON,
    );
  }

  // muralla-set.html: skyOf
  int skyOf(int ix, int iy, bool low) {
    const L = MurallaE.LAND;
    final top = L.y0 + (240 - ix) * .1;
    if (ix > L.x0 && iy + .5 > top && iy > MurallaE.HOR) {
      if ((iy + .5 - (L.road + (240 - ix) * .1)).abs() < 1.6) {
        return (ix.remainder(9) < 5 &&
                (iy + .5 - (L.road + (240 - ix) * .1)).abs() < .6)
            ? rgb(206, 196, 150)
            : rgb(96, 96, 112);
      }
      return iy + .5 - top < 1.5
          ? rgb(46, 70, 66)
          : (e.hash(ix * 3, iy * 7) < .1 ? rgb(40, 66, 60) : rgb(30, 52, 56));
    }
    return FT.night(
      ix,
      iy,
      MurallaE.HOR,
      low ? const [70, MurallaE.HOR - 9, 9] : const [92, 13, 9],
      low,
    );
  }

  // muralla-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(MurallaState state) {
    final low = state.isLow;
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
    k.part('pretil', parapet);
    k.part('paseo', walk);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [.7, .72, .9], const [-2, -2, 14], false);
    k.skyFill((ix, iy) => skyOf(ix, iy, low));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // muralla-set.html: frame
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
