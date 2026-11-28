// Port of docs/proyecto/pixel/cuenta-set.html: La cuenta's set (place 8, La fonda, scene 4: `cuenta`), its 8 states,
// call for call (order 69). Built on La fonda's kit (lib/src/fonda/fonda_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// cuenta-set.html: ORIGIN.
const List<double> CUENTA_ORIGIN = [0, -42];

/// The engine La cuenta's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine cuentaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: CUENTA_ORIGIN[0],
  originY: CUENTA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (cuenta-set.html: `SET`, from the address): `guagua` no, lejos, medio, or cerca;
/// `sillas` abajo (chairs on floor) or arriba (chairs up on the next table at closing time).
class CuentaState {
  const CuentaState({this.guagua = 'no', this.sillas = 'abajo'});

  /// cuenta-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory CuentaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final g = q['guagua'];
    final s = q['sillas'];
    return CuentaState(
      guagua: g != null && const ['no', 'lejos', 'medio', 'cerca'].contains(g)
          ? g
          : 'no',
      sillas: s != null && const ['abajo', 'arriba'].contains(s) ? s : 'abajo',
    );
  }

  /// A key of the sheet's `setKey` ("guagua-sillas", e.g. "medio-arriba") read back.
  factory CuentaState.fromKey(String key) {
    final m = RegExp(r'^(no|lejos|medio|cerca)-(abajo|arriba)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La cuenta's set");
    }
    return CuentaState(guagua: m[1]!, sillas: m[2]!);
  }

  final String guagua;
  final String sillas;

  /// The sheet's key.
  String get key => '$guagua-$sillas';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?guagua=$guagua&sillas=$sillas';
}

/// cuenta-set.html: E, the set's places (the sheet reads them: things, spots, counter, tables).
abstract final class CuentaE {
  static const double WALL = 3.1;
  static const List<double> KITCHEN = [-3.76, -3.02, 0, 2.05];
  static const List<double> WINDOW = [.25, 2.0, 1.5, 2.5];
  static const List<double> DOOR = [2.35, 3.62, 0, 2.2];
  static const ({double u0, double u1, double v0, double v1, double h})
  COUNTER = (u0: -3.0, u1: 2.15, v0: .9, v1: 1.5, h: 1.0);
  static const List<double> CASE = [-2.95, -2.15];
  static const double MINTS = .22;
  static const double SPIKE = -.78;
  static const ({double u, double hw}) REG = (u: -.3, hw: .32);
  static const double MACHINE = .68;
  static const double JAR = 1.18;
  static const double FROG = -1.5;
  static const List<double> LAMPS = [.78, .5, .26];
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: -1.7,
    v: 6.0,
    hw: 1.9,
    hd: .6,
  );
  static const ({double u, double v, double hw}) NEXT = (
    u: 2.75,
    v: 9.4,
    hw: .95,
  );
}

/// Port of cuenta-set.html: builds the baked set into [e].
class CuentaSet {
  CuentaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FD = FondaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FondaBase FD;

  static const String NIGHT = 'noche';

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);
  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // cuenta-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    return uv[1] < -.02 ? rgb(46, 48, 76) : FD.tiles(uv[0], uv[1], ix, iy);
  }

  // cuenta-set.html: street
  int street(num a, num bb, CuentaState state) {
    if (bb < .34) {
      if ((bb - .2 - (a - .5) * .1).abs() < .03 &&
          (a * 14).floor().remainder(2) != 0) {
        return rgb(200, 190, 120);
      }
      return rgb(50, 52, 74);
    }
    const L = CuentaE.LAMPS;
    final g = const {'lejos': 2, 'medio': 1, 'cerca': 0}[state.guagua];
    for (var kk = 0; kk < 3; kk++) {
      final s = 1 - kk * .28, la = L[kk], top = .34 + .52 * s;
      if ((a - la).abs() < .012 * s + .006 && bb >= .3 && bb < top) {
        return rgb(96, 96, 110);
      }
      if (jsHypot((a - la) * 44, (bb - top) * 22) < 2.6 * s + .6) {
        return rgb(255, 236, 150);
      }
      if (g == kk) {
        final ga = la - .13 * s, w = .11 * s + .03, h = .2 * s + .06;
        const gb = .3;
        if (a > ga - w && a < ga + w && bb > gb && bb < gb + h) {
          if (bb < gb + h * .4 &&
              ((a - ga + w * .6).abs() < .018 ||
                  (a - ga - w * .6).abs() < .018)) {
            return rgb(255, 250, 190);
          }
          return bb > gb + h * .55 ? rgb(150, 190, 220) : rgb(70, 130, 180);
        }
      }
    }
    return e.hash((a * 90).floor() * 7, (bb * 50).floor() * 13) < .04
        ? rgb(240, 240, 255)
        : rgb(22, 28, 66);
  }

  // cuenta-set.html: backWall
  void backWall(CuentaState state) {
    PZ.wall(-5, 5, 0, 0, CuentaE.WALL, (u, z) {
      const D = CuentaE.DOOR, W = CuentaE.WINDOW, K = CuentaE.KITCHEN;
      if (FD.inside(u, z, D)) return 0;
      if (FD.onFrame(u, z, D, .09)) return _rgb(FondaBase.WOOD);
      if (FD.inside(u, z, W)) {
        return street(
          (u - W[0]) / (W[1] - W[0]),
          (z - W[2]) / (W[3] - W[2]),
          state,
        );
      }
      if (FD.onFrame(u, z, W, .07)) return _rgb(FondaBase.WOOD_L);
      if (FD.inside(u, z, K)) {
        final d = jsHypot((u - (K[0] + K[1]) / 2) * 26, (z - 1.45) * 22.5);
        if (d < 3.8) {
          return d > 2.8 ? _rgb(FondaBase.BRASS) : rgb(255, 226, 150);
        }
        return z < .3
            ? rgb(
                FondaBase.BRASS[0] - 30,
                FondaBase.BRASS[1] - 30,
                FondaBase.BRASS[2] - 30,
              )
            : b.shade(const [214, 96, 70], 2.3, u * 4, z * 2, .2);
      }
      if (FD.onFrame(u, z, K, .06)) return _rgb(FondaBase.WOOD_D);
      return FD.paint(u, z);
    });
    PZ.wall(
      CuentaE.DOOR[0] - .2,
      CuentaE.DOOR[1] + .2,
      -1.2,
      0,
      3.2,
      (u, z) => FD.outside(
        NIGHT,
        .5,
        (z + .2) / 3.0,
        jsRoundN(u * 26),
        jsRoundN(z * 22.5),
      ),
    );
    for (final u in const [-2.4, -.6]) {
      FD.sconce(u, 0, 2.2);
    }
    const W = CuentaE.WINDOW;
    PZ.box(
      (W[0] + W[1]) / 2,
      .06,
      W[2] - .14,
      W[2] - .07,
      (W[1] - W[0]) / 2 + .12,
      .07,
      FondaBase.WOOD_L,
    );
    PZ.flat(
      CuentaE.DOOR[0] + .08,
      .1,
      CuentaE.DOOR[1] - .08,
      .85,
      .012,
      (u, v) =>
          (u - CuentaE.DOOR[0] < .2 ||
              CuentaE.DOOR[1] - u < .2 ||
              v < .22 ||
              v > .73)
          ? rgb(120, 90, 60)
          : rgb(170, 130, 84),
    );
  }

  // cuenta-set.html: counter
  void counter() {
    const C = CuentaE.COUNTER;
    final mid = (C.u0 + C.u1) / 2,
        hw = (C.u1 - C.u0) / 2,
        vm = (C.v0 + C.v1) / 2,
        hd = (C.v1 - C.v0) / 2;
    const TOP = [226, 196, 150];
    PZ.box(
      mid,
      vm,
      0,
      C.h,
      hw,
      hd,
      FondaBase.WOOD,
      (s, t, z, face) => face == 'top'
          ? b.shade(TOP, 3.3, s, t, .1)
          : (face == 'front' &&
                z > .14 &&
                z < C.h - .14 &&
                jsMod(s + hw, .8) > .08)
          ? b.shade(FondaBase.WOOD_L, 2.2, s * 3, z)
          : 0,
    );
    final cm = (CuentaE.CASE[0] + CuentaE.CASE[1]) / 2,
        chw = (CuentaE.CASE[1] - CuentaE.CASE[0]) / 2;
    const desserts = [
      [236, 170, 80],
      [250, 240, 230],
      [240, 150, 170],
      [190, 120, 70],
    ];
    PZ.box(cm, vm, C.h, C.h + .56, chw, hd - .04, const [190, 220, 236], (
      s,
      t,
      z,
      face,
    ) {
      if (face != 'front') return face == 'top' ? rgb(214, 232, 242) : 0;
      final zz = z - C.h;
      if ((s.abs() - chw).abs() < .04 || zz > .52 || zz < .03) {
        return rgb(120, 130, 150);
      }
      for (final zs in const [.05, .3]) {
        if (zz >= zs && zz < zs + .03) return rgb(150, 160, 176);
        final kk = ((s + chw) / .2).floor(), f = jsMod((s + chw) / .2, 1);
        if (zz >= zs + .03 && zz < zs + .15 && f > .2 && f < .8) {
          return _rgb(desserts[(kk + (zs > .2 ? 1 : 0)) % 4]);
        }
      }
      return rgb(206, 228, 240);
    });
    final mp = PZ.xy(CuentaE.MINTS, vm);
    k.drum(
      mp[0],
      mp[1],
      C.h,
      C.h + .08,
      .13,
      const [250, 250, 250],
      (a, bb) => jsHypot(a, bb) < .1
          ? (((a * 30).floor() + (bb * 30).floor()).remainder(2) != 0
                ? rgb(120, 200, 170)
                : rgb(250, 250, 250))
          : 0,
    );
    PZ.box(CuentaE.SPIKE, vm, C.h, C.h + .03, .07, .07, FondaBase.WOOD_D);
    PZ.post(CuentaE.SPIKE, vm, C.h, C.h + .3, .012, const [80, 80, 90]);
    PZ.box(CuentaE.SPIKE, vm, C.h + .05, C.h + .14, .07, .09, const [
      250,
      248,
      240,
    ]);
    const R = CuentaE.REG;
    PZ.box(
      R.u,
      vm,
      C.h,
      C.h + .2,
      R.hw,
      .22,
      const [84, 88, 100],
      (s, t, z, face) => face == 'front'
          ? (z < C.h + .13
                ? (s.abs() < .06 && z > C.h + .05 && z < C.h + .09
                      ? _rgb(FondaBase.BRASS)
                      : rgb(64, 68, 80))
                : 0)
          : 0,
    );
    PZ.box(
      R.u,
      vm - .05,
      C.h + .2,
      C.h + .42,
      R.hw - .06,
      .14,
      const [104, 108, 122],
      (s, t, z, face) => face == 'front'
          ? ((((s + .3) / .09).floor() + ((z - C.h) / .07).floor()).remainder(
                      2,
                    ) !=
                    0
                ? rgb(230, 230, 236)
                : rgb(150, 154, 168))
          : 0,
    );
    for (double du = -hw; du <= hw; du += .3) {
      PZ.shadow(mid + du, vm, .7, .45);
    }
  }

  // cuenta-set.html: tables
  void tables(CuentaState state) {
    const T = CuentaE.TABLE, N = CuentaE.NEXT;
    FD.setTable(T.u, T.v, T.hw, seats: 4, span: 2.85, hd: T.hd);
    if (state.sillas == 'arriba') {
      FD.table(N.u, N.v, N.hw, .45, const [236, 214, 150]);
      for (final du in const [-.45, .45]) {
        PZ.box(N.u + du, N.v, .74, .8, .2, .2, FondaBase.WOOD_L);
        for (final (a, bb) in const [
          (-.16, -.16),
          (.16, -.16),
          (-.16, .16),
          (.16, .16),
        ]) {
          PZ.post(N.u + du + a, N.v + bb, .8, 1.16, .028, FondaBase.WOOD);
        }
      }
    } else {
      FD.setTable(
        N.u,
        N.v,
        N.hw,
        seats: 2,
        span: .94,
        cloth: const [236, 214, 150],
      );
    }
  }

  // cuenta-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(CuentaState state) {
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
    k.part('pared', () => backWall(state));
    k.part('mostrador', counter);
    k.part('mesas', () => tables(state));
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [1.0, .97, .9], const [4, 1, -4], false);
    k.skyFill((ix, iy) => rgb(30, 24, 30));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // cuenta-set.html: frame
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
