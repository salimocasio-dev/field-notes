// Port of docs/proyecto/pixel/entrada-set.html: La entrada's set (place 8, La fonda, scene 1: `entrada`), its states,
// call for call (order 66). Built on La fonda's kit (lib/src/fonda/fonda_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// entrada-set.html: ORIGIN.
const List<double> ENTRADA_ORIGIN = [0, -42];

/// The engine La entrada's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine entradaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ENTRADA_ORIGIN[0],
  originY: ENTRADA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (entrada-set.html: `SET`, from the address): `hora` ocaso, noche or tarde_noche;
/// `cuerda` puesta (across the way) or abierta (unhooked and hanging from its far post).
class EntradaState {
  const EntradaState({this.hora = 'ocaso', this.cuerda = 'puesta'});

  /// entrada-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory EntradaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    final c = q['cuerda'];
    return EntradaState(
      hora: h != null && const ['ocaso', 'noche', 'tarde_noche'].contains(h)
          ? h
          : 'ocaso',
      cuerda: c != null && const ['puesta', 'abierta'].contains(c)
          ? c
          : 'puesta',
    );
  }

  /// A key of the sheet's `setKey` ("hora-cuerda", e.g. "ocaso-puesta") read back.
  factory EntradaState.fromKey(String key) {
    final m = RegExp(r'^(ocaso|noche|tarde_noche)-(puesta|abierta)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La entrada's set");
    }
    return EntradaState(hora: m[1]!, cuerda: m[2]!);
  }

  final String hora;
  final String cuerda;

  /// The sheet's key.
  String get key => '$hora-$cuerda';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&cuerda=$cuerda';
}

/// entrada-set.html: E, the set's places (the sheet reads them: door, rug, bench, stand, rope, tables, window, kitchen,
/// vellonera).
abstract final class EntradaE {
  static const double WALL = 3.1;
  static const List<double> DOOR = [-3.6, -2.55, 0, 2.2];
  static const List<double> RUG = [-3.5, .12, -2.2, 5.3];
  static const ({double u, double v, double hw}) BENCH = (
    u: -1.2,
    v: .38,
    hw: .62,
  );
  static const ({double u, double v, double hw, double hd, double h}) STAND = (
    u: -.95,
    v: 5.0,
    hw: .27,
    hd: .2,
    h: .95,
  );
  static const ({double u, double v0, double v1, double h}) ROPE = (
    u: -.35,
    v0: 1.5,
    v1: 5.6,
    h: .86,
  );
  static const List<List<double>> TABLES = [
    [1.75, 2.9],
    [1.75, 6.0],
    [1.75, 9.1],
  ];
  static const double THW = 1.1;
  static const List<double> WINDOW = [1.0, 2.5, 1.3, 2.35];
  static const List<double> KITCHEN = [2.8, 3.62, 0, 2.05];
  static const ({double u, double v, double hw, double hd, double h})
  VELLONERA = (u: .5, v: .3, hw: .36, hd: .22, h: 1.5);
}

/// Port of entrada-set.html: builds the baked set into [e].
class EntradaSet {
  EntradaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FD = FondaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FondaBase FD;

  /// The seat places returned by the last `room()` call (`E.SEATS`).
  List<List<List<double>>> seats = const [];

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);
  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // entrada-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy, EntradaState state) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    return v < -.02
        ? (state.hora == 'ocaso'
              ? rgb(150, 118, 110)
              : state.hora == 'noche'
              ? rgb(52, 54, 84)
              : rgb(34, 36, 60))
        : FD.tiles(u, v, ix, iy);
  }

  // entrada-set.html: backWall
  void backWall(EntradaState state) {
    PZ.wall(-5, 5, 0, 0, EntradaE.WALL, (u, z) {
      const D = EntradaE.DOOR, W2 = EntradaE.WINDOW, K = EntradaE.KITCHEN;
      if (FD.inside(u, z, D)) return 0;
      if (FD.onFrame(u, z, D, .09)) return _rgb(FondaBase.WOOD);
      if (FD.inside(u, z, W2)) {
        final a = (u - W2[0]) / (W2[1] - W2[0]);
        final bb = (z - W2[2]) / (W2[3] - W2[2]);
        if ((a - .5).abs() < .02 || (bb - .5).abs() < .03) {
          return _rgb(FondaBase.WOOD_L);
        }
        return 0;
      }
      if (FD.onFrame(u, z, W2)) return _rgb(FondaBase.WOOD_L);
      if (FD.inside(u, z, K)) {
        final mid = (K[0] + K[1]) / 2;
        final a = (u - mid).abs();
        final leaf = u < mid ? K[0] + (mid - K[0]) / 2 : mid + (K[1] - mid) / 2;
        if (a < .012) return rgb(60, 50, 44);
        final dist = jsHypot((u - leaf) * 26, (z - 1.45) * 22.5);
        if (dist < 3.6) {
          return dist > 2.6 ? _rgb(FondaBase.BRASS) : rgb(255, 226, 150);
        }
        if (z < .3) {
          return rgb(
            FondaBase.BRASS[0] - 30,
            FondaBase.BRASS[1] - 30,
            FondaBase.BRASS[2] - 30,
          );
        }
        return b.shade(const [214, 96, 70], 2.3, u * 4, z * 2, .2);
      }
      if (FD.onFrame(u, z, K, .06)) return _rgb(FondaBase.WOOD_D);
      return FD.paint(u, z);
    });
    // behind the holes: the street in the door, the sky in the window
    PZ.wall(EntradaE.DOOR[0] - .2, EntradaE.DOOR[1] + .2, -1.2, 0, 3.2, (u, z) {
      final sx = jsRoundN(u * 26), sy = jsRoundN(z * 22.5);
      return FD.outside(state.hora, .5, (z + .2) / 3.0, sx, sy);
    });
    PZ.wall(EntradaE.WINDOW[0] - .2, EntradaE.WINDOW[1] + .2, -.5, 1.0, 2.7, (
      u,
      z,
    ) {
      final sx = jsRoundN(u * 26), sy = jsRoundN(z * 22.5);
      return FD.outside(state.hora, .5, .4 + (z - 1.0) / 2.8, sx, sy);
    });
    for (final u in const [-2.2, -.1, 2.66]) {
      FD.sconce(u, 0, 1.95);
    }
  }

  // entrada-set.html: entry
  void entry(EntradaState state) {
    const R = EntradaE.RUG;
    PZ.flat(
      R[0],
      R[1],
      R[2],
      R[3],
      .012,
      (u, v) =>
          (u - R[0] < .1 || R[2] - u < .1 || v - R[1] < .16 || R[3] - v < .16)
          ? rgb(236, 196, 96)
          : b.shade(const [176, 52, 58], 3.2, u * 2, v, .12),
    );
    PZ.seat(EntradaE.BENCH.u, EntradaE.BENCH.v, EntradaE.BENCH.hw, true, const [
      176,
      118,
      70,
    ]);
    const S = EntradaE.STAND;
    PZ.box(
      S.u,
      S.v,
      0,
      S.h,
      S.hw,
      S.hd,
      FondaBase.WOOD,
      (s, t, z, face) =>
          face == 'front' && z > .12 && z < S.h - .12 && s.abs() < S.hw - .07
          ? b.shade(FondaBase.WOOD_L, 2.2, s * 4, z)
          : face == 'top'
          ? b.shade(FondaBase.WOOD_L, 3.3, s, t)
          : 0,
    );
    PZ.box(S.u, S.v - .02, S.h, S.h + .05, .17, .13, const [250, 248, 240]);
    PZ.shadow(S.u, S.v, .6, .35);
    const P = EntradaE.ROPE;
    const brassDark = [192, 148, 52]; // FD.BRASS.map(c => c - 30)
    for (final v in [P.v0, P.v1]) {
      PZ.box(P.u, v, 0, .06, .13, .13, brassDark);
      PZ.post(P.u, v, 0, P.h, .04, FondaBase.BRASS);
      PZ.ball(P.u, v, P.h + .05, .07, FondaBase.BRASS, 'gloss');
    }
    if (state.cuerda == 'puesta') {
      const n = 40;
      for (var kk = 0; kk <= n; kk++) {
        final t = kk / n;
        final v = P.v0 + (P.v1 - P.v0) * t;
        final z = P.h - .08 - .22 * 4 * t * (1 - t);
        PZ.box(
          P.u,
          v,
          z - .045,
          z + .045,
          .045,
          (P.v1 - P.v0) / n * .6,
          (kk % 4 < 2) ? const [250, 214, 110] : const [214, 168, 70],
        );
      }
    } else {
      PZ.box(P.u + .06, P.v0 + .03, .14, P.h - .06, .04, .04, const [
        236,
        196,
        96,
      ]);
    }
  }

  // entrada-set.html: room
  void room() {
    const V = EntradaE.VELLONERA;
    PZ.box(V.u, V.v, 0, V.h, V.hw, V.hd, const [150, 60, 70], (s, t, z, face) {
      if (face != 'front') return 0;
      final px = s * 26, pz = (z - V.h + .36) * 22.5;
      if (z > V.h - .5 && jsHypot(px, math.max(0, pz)) > 7.4) {
        return rgb(250, 206, 70);
      }
      if (z > V.h - .62) {
        return px.abs() < 5.5
            ? (((px + 6) / 2).floor().remainder(2) != 0
                  ? rgb(70, 60, 70)
                  : rgb(200, 220, 240))
            : rgb(250, 150, 70);
      }
      if (z > V.h - .7) return rgb(250, 206, 70);
      if (z > .2 && z < V.h - .8 && px.abs() < 6.5) {
        return (z * 22.5).floor().remainder(2) != 0
            ? rgb(90, 50, 56)
            : rgb(222, 178, 82);
      }
      return 0;
    });
    PZ.shadow(V.u, V.v + .2, .6, .45);
    seats = [
      for (final tv in EntradaE.TABLES)
        FD.setTable(
          tv[0],
          tv[1],
          EntradaE.THW,
          seats: 2,
          span: 1.1,
          ends: true,
          hd: .6,
        ),
    ];
  }

  // entrada-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(EntradaState state) {
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
        final c = groundAt(g.x, g.y, ix, iy, state);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / R2 * COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('pared', () => backWall(state));
    k.part('entrada', () => entry(state));
    k.part('salon', room);
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

  // entrada-set.html: frame
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
