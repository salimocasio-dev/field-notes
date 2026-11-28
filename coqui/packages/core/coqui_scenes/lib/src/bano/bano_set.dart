// Port of docs/proyecto/pixel/bano-set.html: El baño's set (place 9, La casa, un día entero, scene 2: `bano`),
// call for call (order 71). Built on La casa's kit (lib/src/casa/casa_base.dart), La fonda's helpers
// (lib/src/fonda/fonda_base.dart), and La plaza's painters (lib/src/plaza/plaza_base.dart). The page's names are kept,
// capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/casa/casa_base.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// bano-set.html: ORIGIN.
const List<double> BANO_ORIGIN = [0, -42];

/// The engine El baño's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine banoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: BANO_ORIGIN[0],
  originY: BANO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (bano-set.html: `SET`, from the address): `hora` dia (one state).
class BanoState {
  const BanoState({this.hora = 'dia'});

  /// bano-set.html: `SET.hora` is fixed `'dia'`.
  factory BanoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return BanoState(hora: h != null && const ['dia'].contains(h) ? h : 'dia');
  }

  /// A key of the set ("dia") read back.
  factory BanoState.fromKey(String key) {
    if (key != 'dia') {
      throw ArgumentError.value(key, 'key', "not a key of El baño's set");
    }
    return BanoState(hora: key);
  }

  final String hora;

  /// The set's key.
  String get key => hora;

  /// The page's query for this state.
  String get query => '?hora=$hora';
}

/// bano-set.html: E, the set's places (the sheet reads them: shower, taps, sink, mirror, shelves, heater, door, stool,
/// basket).
abstract final class BanoE {
  static const double WALL = 3.1;
  static const ({
    double u0,
    double u1,
    double v1,
    double wall,
    List<double> head,
  })
  SHOWER = (u0: -3.75, u1: -2.25, v1: 1.6, wall: 1.2, head: [-3.0, 2.35]);
  static const List<double> TAP_SHOWER = [-1.95, 1.35];
  static const ({double u, double v, double hw, double hd, double h}) SINK = (
    u: 0,
    v: .42,
    hw: .5,
    hd: .34,
    h: .8,
  );
  static const List<double> MIRROR = [-.55, .55, 1.4, 2.35];
  static const ({double u0, double u1, double v1, double z}) SHELF_L = (
    u0: -1.72,
    u1: -.62,
    v1: .62,
    z: .8,
  );
  static const ({double u0, double u1, double v1, double z}) SHELF_R = (
    u0: .62,
    u1: 2.0,
    v1: .62,
    z: .8,
  );
  static const ({double u, double z0, double z1, double hw, List<double> gauge})
  HEATER = (u: 2.38, z0: 1.5, z1: 2.45, hw: .3, gauge: [2.38, 1.9]);
  static const List<double> DOOR = [2.8, 3.62, 0, 2.15];
  static const ({double u, double v, double hw, double hd, double h}) STOOL = (
    u: 1.7,
    v: 2.7,
    hw: .5,
    hd: .26,
    h: .4,
  );
  static const List<double> BASKET = [2.75, 1.5];
}

/// Port of bano-set.html: builds the baked set into [e].
class BanoSet {
  BanoSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FD = FondaBase(PZ);
    CS = CasaBase(FD);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FondaBase FD;
  late final CasaBase CS;

  int get W => e.W;
  int get H => e.H;

  // bano-set.html: groundAt
  int groundAt(double x, double y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v < -.02) return e.rgb(84, 70, 70);
    final a = jsMod(u + 60, .5), bb = jsMod(v + 60, .5);
    final kk = (((u + 60) / .5).floor() + ((v + 60) / .5).floor()) & 1;
    return (a < .03 || bb < .05)
        ? e.rgb(170, 190, 200)
        : kk != 0
        ? e.rgb(214, 232, 238)
        : e.rgb(240, 246, 248);
  }

  // bano-set.html: backWall
  void backWall() {
    const S = BanoE.SHOWER;
    PZ.wall(-5, 5, 0, 0, BanoE.WALL, (u, z) {
      if (u > S.u0 && u < S.u1) {
        final d = jsHypot((u - S.head[0]) * 26, (z - S.head[1] + .12) * 22.5);
        if (d < 4.6 && z < S.head[1] - .02) {
          return d > 3.4
              ? e.rgb(120, 126, 140)
              : ((jsRoundN((u - S.head[0]) * 26) + jsRoundN(z * 22.5))
                            .remainder(2) !=
                        0
                    ? e.rgb(90, 96, 110)
                    : e.rgb(176, 182, 196));
        }
        if ((u - S.head[0]).abs() < .035 &&
            z >= S.head[1] - .02 &&
            z < S.head[1] + .4) {
          return e.rgb(150, 156, 170);
        }
        final t = CS.tiles(u, z, const [70, 150, 170]);
        return t == e.rgb(244, 248, 248) ? e.rgb(206, 230, 236) : t;
      }
      const T = BanoE.TAP_SHOWER;
      final dt = jsHypot((u - T[0]) * 26, (z - T[1]) * 22.5);
      if (dt < 4.2) {
        return jsHypot((u - T[0]) * 26 + 1.6, (z - T[1]) * 22.5) < 1.2
            ? e.rgb(226, 80, 70)
            : jsHypot((u - T[0]) * 26 - 1.6, (z - T[1]) * 22.5) < 1.2
            ? e.rgb(70, 130, 220)
            : dt > 3.3
            ? e.rgb(150, 156, 170)
            : e.rgb(226, 230, 238);
      }
      const M = BanoE.MIRROR;
      if (FD.onFrame(u, z, M, .08)) {
        return e.rgb(
          FondaBase.WOOD_L[0],
          FondaBase.WOOD_L[1],
          FondaBase.WOOD_L[2],
        );
      }
      if (FD.inside(u, z, M)) {
        final g = (u - M[0]) + (z - M[2]) * .6;
        return (jsMod(g, .9) - .3).abs() < .06
            ? e.rgb(250, 252, 255)
            : e.rgb(196, 224, 236);
      }
      const H = BanoE.HEATER;
      if ((u - H.u).abs() < H.hw && z > H.z0 && z < H.z1) {
        if ((u - H.gauge[0]).abs() < .16 && (z - H.gauge[1]).abs() < .22) {
          return e.rgb(50, 54, 66);
        }
        return ((u - H.u).abs() > H.hw - .04 ||
                z > H.z1 - .06 ||
                z < H.z0 + .06)
            ? e.rgb(170, 176, 190)
            : e.rgb(246, 248, 250);
      }
      if ((u - H.u + .12).abs() < .03 && z >= H.z1) {
        return e.rgb(170, 176, 190);
      }
      if ((u - H.u - .12).abs() < .03 && z >= H.z1) {
        return e.rgb(226, 120, 100);
      }
      final dc = CS.doorAt(u, z, BanoE.DOOR, true);
      return dc != 0 ? dc : CS.tiles(u, z);
    });
  }

  // bano-set.html: room
  void room() {
    const S = BanoE.SHOWER;
    final mid = (S.u0 + S.u1) / 2, hw = (S.u1 - S.u0) / 2;
    PZ.flat(
      S.u0,
      .02,
      S.u1,
      S.v1,
      .02,
      (u, v) => jsHypot((u - mid) * 26, (v - S.v1 / 2) * 13) < 2.2
          ? e.rgb(90, 96, 110)
          : (jsMod(u + 60, .25) < .03 || jsMod(v + 60, .25) < .04)
          ? e.rgb(96, 150, 170)
          : e.rgb(140, 196, 212),
    );
    PZ.box(
      mid,
      S.v1,
      0,
      S.wall,
      hw + .06,
      .07,
      const [70, 150, 170],
      (s, t, z, face) => face == 'front'
          ? ((jsMod(s + 9, .3) < .03 || jsMod(z, .27) < .035)
                ? e.rgb(52, 118, 136)
                : e.rgb(86, 166, 186))
          : face == 'top'
          ? e.rgb(240, 246, 248)
          : 0,
    );
    const K = BanoE.SINK;
    PZ.box(K.u, K.v, 0, K.h - .2, K.hw - .12, K.hd - .1, const [226, 232, 238]);
    PZ.box(
      K.u,
      K.v,
      K.h - .2,
      K.h,
      K.hw,
      K.hd,
      const [250, 252, 252],
      (s, t, z, face) =>
          face == 'top' &&
              jsHypot(s / (K.hw - .1), (t + .02) / (K.hd - .12)) < 1
          ? e.rgb(190, 222, 234)
          : 0,
    );
    PZ.post(K.u, K.v - K.hd + .08, K.h, K.h + .22, .03, const [176, 182, 196]);
    PZ.box(K.u, K.v - K.hd + .16, K.h + .2, K.h + .25, .03, .1, const [
      176,
      182,
      196,
    ]);
    for (final L in const [BanoE.SHELF_L, BanoE.SHELF_R]) {
      final m = (L.u0 + L.u1) / 2, w = (L.u1 - L.u0) / 2;
      PZ.box(
        m,
        L.v1 / 2,
        L.z - .07,
        L.z,
        w,
        L.v1 / 2,
        FondaBase.WOOD_L,
        (s, t, z, face) => face == 'top'
            ? e.rgb(236, 214, 170)
            : e.rgb(FondaBase.WOOD[0], FondaBase.WOOD[1], FondaBase.WOOD[2]),
      );
      for (final du in [-w + .12, w - .12]) {
        PZ.wall(
          m + du - .03,
          m + du + .03,
          .02,
          L.z - .3,
          L.z - .07,
          (_, _) =>
              e.rgb(FondaBase.WOOD[0], FondaBase.WOOD[1], FondaBase.WOOD[2]),
        );
      }
    }
    const T = BanoE.STOOL;
    PZ.box(T.u, T.v, T.h - .08, T.h, T.hw, T.hd, FondaBase.WOOD_L);
    for (final p in const [
      [-1, -1],
      [1, -1],
      [-1, 1],
      [1, 1],
    ]) {
      PZ.post(
        T.u + p[0] * (T.hw - .08),
        T.v + p[1] * (T.hd - .07),
        0,
        T.h - .08,
        .035,
        FondaBase.WOOD,
      );
    }
    PZ.shadow(T.u, T.v, .3, .5);
    final bxy = PZ.xy(BanoE.BASKET[0], BanoE.BASKET[1]);
    k.drum(bxy[0], bxy[1], 0, .55, .3, const [
      214,
      176,
      120,
    ], (a, bb) => jsHypot(a, bb) < .24 ? e.rgb(250, 246, 236) : 0);
    e.castShadow(bxy[0], bxy[1], .3, .34);
  }

  // bano-set.html: buildSet
  void buildSet(BanoState state) {
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
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('pared', backWall);
    k.part('bano', room);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [1.0, .99, .98], const [2, 2, 2], false);
    k.skyFill((_, _) => e.rgb(30, 24, 30));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // bano-set.html: frame
  void frame(double t, [List<ShadowCast> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c.x, c.y, c.z, c.r);
    }
    e.applyShadows(e.groundZ);
  }
}
