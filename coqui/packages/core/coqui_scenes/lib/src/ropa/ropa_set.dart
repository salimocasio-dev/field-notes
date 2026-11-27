// Port of docs/proyecto/pixel/ropa-set.html: La ropa's set (place 7, La playa, scene 3: `ropa`), its states, call
// for call (order 64). Built on La playa's kit (lib/src/playa/playa_base.dart), La calle's kit
// (lib/src/calle/calle_base.dart), and La plaza's painters (lib/src/plaza/plaza_base.dart). The page's names are kept,
// capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/playa/playa_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// ropa-set.html: ORIGIN.
const List<double> ROPA_ORIGIN = [0, -48];

/// The engine La ropa's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -48), shadows to (.9, -.1).
PpEngine ropaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ROPA_ORIGIN[0],
  originY: ROPA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (ropa-set.html: `SET`, from the address): `hora` tarde or ocaso; `guagua` (the guagua
/// standing at the stop on the road, its door open: true in story 80).
class RopaState {
  const RopaState({this.hora = 'tarde', this.guagua = false});

  /// ropa-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory RopaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return RopaState(
      hora: h != null && const ['tarde', 'ocaso'].contains(h) ? h : 'tarde',
      guagua: q['guagua'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-guagua", e.g. "tarde-0") read back.
  factory RopaState.fromKey(String key) {
    final m = RegExp(r'^(tarde|ocaso)-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La ropa's set");
    }
    return RopaState(hora: m[1]!, guagua: m[2] == '1');
  }

  final String hora;
  final bool guagua;

  /// The sheet's key.
  String get key => '$hora-${guagua ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&guagua=${guagua ? 1 : 0}';
}

/// ropa-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class RopaE {
  static const PlayaBeach B = PlayaBeach(
    edge: 0,
    wet: .8,
    deep: -1.8,
    hor: -3.5,
  );
  static const List<List<double>> PALMS = [
    [-1.9, 2.7],
    [1.65, 2.7],
  ];
  static const double LINE = 1.75;
  static const List<double> PEGS = [-1.4, -.72, -.04, .64, 1.32];
  static const ({double u, double v, double hw, double hd, double h}) CABIN = (
    u: -3.1,
    v: 2.4,
    hw: .62,
    hd: .5,
    h: 2.3,
  );
  static const ({double u, double v, double hw}) BENCH = (
    u: 2.55,
    v: 3.7,
    hw: .95,
  );
  static const double ROAD = 9.4;
  static const ({double u0, double u1, double v, double h}) BUS = (
    u0: .9,
    u1: 5.0,
    v: 10.6,
    h: 1.9,
  );
}

/// Port of ropa-set.html: builds the baked set into [e].
class RopaSet {
  RopaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    PL = PlayaBase(PZ);
    CL = CalleBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final PlayaBase PL;
  late final CalleBase CL;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  // ropa-set.html: groundAt
  PlayaGround? groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v > RopaE.ROAD) {
      return (
        color: v < RopaE.ROAD + .16
            ? CL.kerb()
            : ((v - RopaE.ROAD - 2.2).abs() < .06 && jsMod(u + 40, 1.4) < .8)
            ? CL.paint(CalleBase.LINE)
            : CL.asphalt(ix, iy),
        kind: 'calle',
      );
    }
    return PL.ground(u, v, ix, iy, RopaE.B);
  }

  // ropa-set.html: cabin
  void cabin() {
    const K = RopaE.CABIN;
    const WD = [176, 134, 92];
    final Wd = e.rampOf(const [140, 100, 64]);
    PZ.box(K.u, K.v, 0, K.h, K.hw, K.hd, WD, (s, t, z, face) {
      if (face == 'front') {
        if (s.abs() < K.hw - .12 && z < K.h - .4) {
          final stripe = ((s + K.hw) / .18).floor().remainder(2) != 0;
          return z > K.h - .46
              ? rgb(90, 70, 60)
              : b.shade(
                  stripe ? const [86, 160, 190] : const [250, 246, 236],
                  2.3 - (math.sin(s * 9 + z * .5)).abs() * .5,
                  s * 6,
                  z * 2,
                  .2,
                );
        }
        return jsMod(z, .3) < .03 ? Wd[1] : 0;
      }
      return 0;
    });
    PZ.slope(
      K.u - K.hw - .12,
      K.u + K.hw + .12,
      K.v + K.hd + .12,
      K.h,
      K.v - K.hd - .1,
      K.h + .34,
      (u, bb) => b.shade(PlazaBase.TILE, bb > .5 ? 3.0 : 2.4, u * 3, bb * 4),
    );
    for (num du = -K.hw; du <= K.hw; du += .3) {
      PZ.shadow(K.u + du, K.v, 1.4, .5);
    }
  }

  // ropa-set.html: bus
  void bus() {
    const B = RopaE.BUS;
    const C1 = [244, 244, 236];
    const BAND = [60, 150, 120];
    const G = [44, 52, 66];
    const G2 = [70, 84, 104];
    PZ.wall(B.u0, B.u1, B.v, .3, B.h + .3, (u, z) {
      final d = u - B.u0, zz = z - .3;
      if (d > .35 && d < 1.15 && zz < B.h - .2) {
        return (zz < .5 && jsMod(zz, .17) < .03)
            ? rgb(90, 84, 80)
            : (d > 1.02)
            ? rgb(250, 206, 70)
            : (zz < .5 ? rgb(176, 170, 160) : rgb(124, 132, 144));
      }
      if (zz > .85 && zz < 1.55 && d > 1.45 && jsMod(d - 1.45, .68) < .54) {
        final pane = jsMod(u * 2 + z, 1.6) < .22 ? G2 : G;
        return rgb(pane[0], pane[1], pane[2]);
      }
      if (zz > .85 && zz < 1.55 && d < .28) {
        return rgb(G[0], G[1], G[2]);
      }
      if (zz > .32 && zz < .56) return b.shade(BAND, 2.4, u, z);
      return b.shade(C1, 2.4, u, z);
    });
    PZ.flat(
      B.u0,
      B.v - 1.3,
      B.u1,
      B.v,
      B.h + .3,
      (u, v) => b.shade(const [226, 226, 220], 3.4, u, v),
    );
    for (final wu in [B.u0 + .8, B.u0 + 3.4]) {
      PZ.wall(wu - .27, wu + .27, B.v + .02, 0, .54, (u, z) {
        final r = jsHypot((u - wu) * 26, (z - .27) * 22.5);
        return r > 6.6
            ? 0
            : r < 2.4
            ? rgb(170, 170, 176)
            : rgb(40, 38, 44);
      });
    }
    for (num u = B.u0; u <= B.u1; u += .5) {
      PZ.shadow(u, B.v - .6, 1.2, .8);
    }
    PZ.post(B.u0 - .5, RopaE.ROAD - .25, 0, 2.3, .045, const [90, 94, 104]);
    PZ.wall(B.u0 - .84, B.u0 - .16, RopaE.ROAD - .2, 1.7, 2.3, (u, z) {
      final fu = (u - B.u0 + .84) / .68, fz = (z - 1.7) / .6;
      return (fu < .07 || fu > .93 || fz < .08 || fz > .92)
          ? rgb(250, 250, 250)
          : (fz > .3 && fz < .72 && fu > .18 && fu < .82)
          ? rgb(250, 250, 250)
          : (fz > .18 &&
                fz <= .3 &&
                ((fu - .32).abs() < .07 || (fu - .68).abs() < .07))
          ? rgb(30, 30, 40)
          : rgb(40, 110, 200);
    });
  }

  // ropa-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(RopaState state) {
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
        if (c == null) continue;
        e.pix[i] = c.color;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / R2 * COS;
        e.kinds[i] = c.kind == 'mar'
            ? KIND_WATER
            : c.kind == 'calle'
            ? KIND_ROAD
            : KIND_SAND;
      }
    }
    e.groundZ.setAll(0, e.zb);
    final L = const <String, Light>{
      'tarde': Light([1.0, .95, .86], [8, 3, -6]),
      'ocaso': Light([1.0, .86, .74], [16, 0, -12]),
    }[state.hora];
    k.part('caseta', cabin);
    k.part('palmas', () {
      PL.palm(RopaE.PALMS[0][0], RopaE.PALMS[0][1], 4.0, -.35, 2, 1, L);
      PL.palm(RopaE.PALMS[1][0], RopaE.PALMS[1][1], 3.8, .35, 5, .95, L);
      PZ.wall(
        RopaE.PALMS[0][0],
        RopaE.PALMS[1][0],
        RopaE.PALMS[0][1],
        RopaE.LINE - .12,
        RopaE.LINE + .04,
        (u, z) {
          final t =
              (u - RopaE.PALMS[0][0]) / (RopaE.PALMS[1][0] - RopaE.PALMS[0][0]);
          final zr = RopaE.LINE - .07 * 4 * t * (1 - t);
          return (z - zr).abs() < .03 ? rgb(110, 84, 60) : 0;
        },
      );
    });
    k.part(
      'banco',
      () => PZ.seat(RopaE.BENCH.u, RopaE.BENCH.v, RopaE.BENCH.hw),
    );
    if (state.guagua) k.part('guagua', bus);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PL.light(state.hora);
    k.skyFill(
      PL.sky(state.hora, state.hora == 'ocaso' ? const [70, 12, 8] : null),
    );
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // ropa-set.html: frame(t, casts = [])
  void frame(double t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final windT = e.STILL ? 0.0 : (t * e.WIND_FPS).floor() / e.WIND_FPS;
    e.drawLeaves(windT);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
