// Port of docs/proyecto/pixel/noche-set.html: La noche's set (place 9, La casa, un día entero, scene 4: `noche`),
// its baked states, call for call (order 73). Built on La casa's kit (lib/src/casa/casa_base.dart), La fonda's
// kit (lib/src/fonda/fonda_base.dart), and La plaza's painters (lib/src/plaza/plaza_base.dart). The page's names are
// kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/casa/casa_base.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// noche-set.html: ORIGIN.
const List<double> NOCHE_ORIGIN = [0, -42];

/// The engine La noche's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine nocheEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: NOCHE_ORIGIN[0],
  originY: NOCHE_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (noche-set.html: `SET`, from the address): `luz1`, `luz2`, `luz3` (0|1 lamps), `tele` (0|1),
/// `mesa` (0|1), and `oscuro` (0|1; when 1, every lamp is forced out).
class NocheState {
  const NocheState({
    int luz1 = 0,
    int luz2 = 1,
    int luz3 = 0,
    this.tele = 0,
    this.mesa = 0,
    this.oscuro = 0,
  }) : luz1 = oscuro == 1 ? 0 : luz1,
       luz2 = oscuro == 1 ? 0 : luz2,
       luz3 = oscuro == 1 ? 0 : luz3;

  /// noche-set.html: `on(...)` from a query; missing `luz2` defaults to 1, others to 0; `oscuro=1` forces all lamps off.
  factory NocheState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    int on(String k, [int def = 0]) =>
        q.containsKey(k) ? (q[k] == '1' ? 1 : 0) : def;
    final oscuro = on('oscuro');
    return NocheState(
      luz1: oscuro == 1 ? 0 : on('luz1'),
      luz2: oscuro == 1 ? 0 : on('luz2', 1),
      luz3: oscuro == 1 ? 0 : on('luz3'),
      tele: on('tele'),
      mesa: on('mesa'),
      oscuro: oscuro,
    );
  }

  /// A key of the sheet's `setKey` ("luz1-luz2-luz3-tele-mesa-oscuro" or query string) read back.
  factory NocheState.fromKey(String key) {
    if (key.contains('=')) return NocheState.fromQuery(key);
    final m = RegExp(r'^([01])-([01])-([01])-([01])-([01])-([01])$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La noche's set");
    }
    final oscuro = int.parse(m[6]!);
    return NocheState(
      luz1: oscuro == 1 ? 0 : int.parse(m[1]!),
      luz2: oscuro == 1 ? 0 : int.parse(m[2]!),
      luz3: oscuro == 1 ? 0 : int.parse(m[3]!),
      tele: int.parse(m[4]!),
      mesa: int.parse(m[5]!),
      oscuro: oscuro,
    );
  }

  final int luz1;
  final int luz2;
  final int luz3;
  final int tele;
  final int mesa;
  final int oscuro;

  /// The canonical key.
  String get key => '$luz1-$luz2-$luz3-$tele-$mesa-$oscuro';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query =>
      '?luz1=$luz1&luz2=$luz2&luz3=$luz3&tele=$tele&mesa=$mesa&oscuro=$oscuro';
}

/// noche-set.html: E, the set's places.
abstract final class NocheE {
  static const double WALL = 3.1;
  static const List<double> ARCH = [-3.72, -2.0, 0.0, 2.3];
  static const double ROOM = -2.9;
  static const ({double u, double v0, double v1, double hw}) BED = (
    u: -2.86,
    v0: -2.8,
    v1: -.3,
    hw: .66,
  );
  static const List<double> LAMP1 = [-1.62, .42];
  static const List<double> WINDOW = [-1.25, -.05, 1.35, 2.45];
  static const ({double u, double z}) LAMP2 = (u: .55, z: 1.25);
  static const List<double> CLOCK = [1.3, 2.35];
  static const ({double u, double v, double hw, double hd, double h})
  SIDEBOARD = (u: 2.3, v: .4, hw: 1.32, hd: .3, h: .9);
  static const List<double> LAMP3 = [3.3, 1.9];
  static const ({double u, double v, double hw}) SOFA = (
    u: -.35,
    v: 2.7,
    hw: 1.5,
  );
  static const List<double> ARMCHAIR = [-2.75, 2.7];
  static const List<double> RUG = [-2.3, 3.5, .9, 4.9];
  static const ({double u, double v, double hw, double z0, double z1}) TV = (
    u: -3.0,
    v: 5.9,
    hw: .6,
    z0: .45,
    z1: 1.2,
  );
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: 1.9,
    v: 5.7,
    hw: 1.75,
    hd: .6,
  );
  static const List<double> BOWL = [3.35, 1.7];
}

/// Port of noche-set.html: builds the baked set into [e].
class NocheSet {
  NocheSet(this.e, this.b) : k = SetKit(e, b) {
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
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);
  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // noche-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    return v < NocheE.ROOM
        ? 0
        : CS.boards(
            u,
            v,
            ix,
            iy,
            v < -.02 ? const [170, 140, 110] : const [196, 150, 104],
          );
  }

  // noche-set.html: backWall
  void backWall(NocheState state) {
    PZ.wall(
      NocheE.ARCH[0] - .3,
      NocheE.ARCH[1] + .3,
      NocheE.ROOM,
      0,
      3.4,
      (u, z) => CS.paint(u, z, const [200, 196, 226]),
    );
    CS.bed(NocheE.BED.u, NocheE.BED.v0, NocheE.BED.v1, NocheE.BED.hw, const [
      236,
      190,
      110,
    ]);
    PZ.wall(-5, 5, 0, 0, NocheE.WALL, (u, z) {
      const A = NocheE.ARCH;
      final am = (A[0] + A[1]) / 2, ah = (A[1] - A[0]) / 2;
      final inArch =
          u > A[0] &&
          u < A[1] &&
          (z < A[3] - ah * .5 ||
              jsHypot((u - am) / ah, (z - (A[3] - ah * .5)) / (ah * .5)) < 1);
      if (inArch) return 0;
      if (u > A[0] - .1 &&
          u < A[1] + .1 &&
          z < A[3] + .1 &&
          (z < A[3] - ah * .5 ||
              jsHypot(
                    (u - am) / (ah + .1),
                    (z - (A[3] - ah * .5)) / (ah * .5 + .1),
                  ) <
                  1)) {
        return rgb(250, 246, 236);
      }
      const L = NocheE.LAMP2;
      if (z > L.z - .07 && z < L.z && (u - L.u).abs() < .34) {
        return _rgb(FondaBase.WOOD);
      }
      final w = CS.windowAt(u, z, NocheE.WINDOW, 'noche');
      if (w != 0) return w;
      final cl = CS.clockAt(u, z, NocheE.CLOCK[0], NocheE.CLOCK[1]);
      if (cl != 0) return cl;
      return CS.paint(u, z, const [226, 206, 180]);
    });
    PZ.box(
      NocheE.LAMP2.u,
      .12,
      NocheE.LAMP2.z - .07,
      NocheE.LAMP2.z,
      .34,
      .12,
      FondaBase.WOOD_L,
    );
    CS.lampSmall(NocheE.LAMP2.u, .12, NocheE.LAMP2.z, state.luz2 == 1);
    CS.lampStanding(NocheE.LAMP1[0], NocheE.LAMP1[1], state.luz1 == 1);
    CS.lampWall(NocheE.LAMP3[0], NocheE.LAMP3[1], state.luz3 == 1);
  }

  // noche-set.html: room
  void room(NocheState state) {
    const S = NocheE.SIDEBOARD;
    for (final du in [-S.hw + .1, S.hw - .1]) {
      PZ.post(S.u + du, S.v + S.hd - .08, 0, .14, .04, FondaBase.WOOD_D);
    }
    PZ.box(S.u, S.v, .12, S.h, S.hw, S.hd, FondaBase.WOOD, (s, t, z, face) {
      if (face == 'top') return rgb(226, 196, 150);
      if (face != 'front') return 0;
      if (jsHypot(((s.abs() - S.hw / 2).abs() - .08) * 26, (z - .5) * 22.5) <
          1.3) {
        return _rgb(FondaBase.BRASS);
      }
      if (z > .2 &&
          z < S.h - .1 &&
          (s.abs() - S.hw / 2).abs() < S.hw / 2 - .07 &&
          (s.abs() - S.hw / 2).abs() > .03) {
        return _rgb(FondaBase.WOOD_L);
      }
      return 0;
    });
    for (double du = -S.hw; du <= S.hw; du += .3) {
      PZ.shadow(S.u + du, S.v, .5, .4);
    }
    final bp = PZ.xy(NocheE.BOWL[0], NocheE.BOWL[1]);
    k.drum(bp[0], bp[1], 0, .12, .16, const [
      196,
      60,
      54,
    ], (a, bb) => jsHypot(a, bb) < .11 ? rgb(120, 84, 60) : 0);
    CS.rug(
      NocheE.RUG[0],
      NocheE.RUG[1],
      NocheE.RUG[2],
      NocheE.RUG[3],
      const [150, 90, 110],
      const [240, 220, 170],
    );
    CS.armchair(NocheE.ARMCHAIR[0], NocheE.ARMCHAIR[1], const [176, 110, 90]);
    CS.sofa(NocheE.SOFA.u, NocheE.SOFA.v, NocheE.SOFA.hw, const [96, 140, 150]);
    const T = NocheE.TV;
    PZ.box(
      T.u,
      T.v,
      0,
      T.z0,
      T.hw + .1,
      .26,
      FondaBase.WOOD,
      (s, t, z, face) => face == 'top' ? _rgb(FondaBase.WOOD_L) : 0,
    );
    PZ.box(T.u, T.v - .02, T.z0, T.z1, T.hw, .08, const [50, 52, 62], (
      s,
      t,
      z,
      face,
    ) {
      if (face == 'front' &&
          s.abs() < T.hw - .06 &&
          z > T.z0 + .06 &&
          z < T.z1 - .06) {
        return state.tele == 1
            ? (((s * 9 + 9).floor() + (z * 9).floor()).remainder(3) == 0
                  ? rgb(250, 220, 120)
                  : rgb(120, 200, 240))
            : rgb(30, 34, 46);
      }
      return 0;
    });
    PZ.shadow(T.u, T.v, .4, .6);
    if (state.mesa == 1) {
      FD.setTable(
        NocheE.TABLE.u,
        NocheE.TABLE.v,
        NocheE.TABLE.hw,
        seats: 4,
        span: 2.78,
        hd: NocheE.TABLE.hd,
      );
    }
  }

  // noche-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(NocheState state) {
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
    k.part('sala', () => room(state));
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    final lit = state.oscuro == 1
        ? 0
        : (state.luz1 + state.luz2 + state.luz3).clamp(0, 3);
    const lits = <List<double>>[
      [.5, .54, .8],
      [.84, .8, .82],
      [.94, .9, .86],
      [1.0, .97, .9],
    ];
    const dirs = <List<double>>[
      [-6, -4, 18],
      [2, 0, 6],
      [3, 1, 2],
      [4, 2, -2],
    ];
    k.lightPass(lits[lit], dirs[lit], false);
    k.skyFill((ix, iy) => rgb(30, 24, 30));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // noche-set.html: frame
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
