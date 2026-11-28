// Port of docs/proyecto/pixel/comida-set.html: La comida's set (place 8, La fonda, scene 3: `comida`), call for call
// (order 68). Built on La fonda's kit (lib/src/fonda/fonda_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// comida-set.html: ORIGIN.
const List<double> COMIDA_ORIGIN = [0, -48];

/// The engine La comida's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -48), shadows to (.9, -.1).
PpEngine comidaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: COMIDA_ORIGIN[0],
  originY: COMIDA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (comida-set.html: `SET`, from the address): `hora` noche (one state).
class ComidaState {
  const ComidaState({this.hora = 'noche'});

  /// comida-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory ComidaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return ComidaState(
      hora: h != null && const ['noche'].contains(h) ? h : 'noche',
    );
  }

  /// A key of the sheet's `setKey` ("noche") read back.
  factory ComidaState.fromKey(String key) {
    if (key != 'noche') {
      throw ArgumentError.value(key, 'key', "not a key of La comida's set");
    }
    return ComidaState(hora: key);
  }

  final String hora;

  /// The sheet's key.
  String get key => hora;

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora';
}

/// comida-set.html: E, the set's places (the sheet reads them: table, seats, station, serving table, pot).
abstract final class ComidaE {
  static const ({double hor}) B = (hor: -2.7);
  static const ({double v, double h, List<double> posts, double lights}) RAIL =
      (
        v: .15,
        h: .9,
        posts: [-4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4],
        lights: 1.3,
      );
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: .1,
    v: 4.9,
    hw: 1.9,
    hd: .6,
  );
  static const ({
    double u,
    double v,
    double hw,
    double hd,
    double shelf,
    double sv,
    List<double> things,
  })
  STATION = (
    u: 2.78,
    v: 2.0,
    hw: .92,
    hd: .42,
    shelf: 1.6,
    sv: 1.66,
    things: [2.1, 2.55, 3.0, 3.45],
  );
  static const ({
    double u,
    double v,
    double hw,
    double hd,
    List<double> pot,
    List<double> plates,
  })
  SERVE = (
    u: -2.7,
    v: 2.0,
    hw: 1.25,
    hd: .42,
    pot: [-3.05, 1.95, .3],
    plates: [-2.3, 1.85],
  );
}

/// Port of comida-set.html: builds the baked set into [e].
class ComidaSet {
  ComidaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FD = FondaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FondaBase FD;

  /// The long table's four chair seats (`E.SEATS`), populated by [tableLong].
  List<List<double>> SEATS = const [];

  int get W => e.W;
  int get H => e.H;

  // comida-set.html: groundAt
  int groundAt(double x, double y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v >= -.02) return FD.planks(u, v, ix, iy);
    if (v < ComidaE.B.hor) return 0;
    final glint =
        e.hash(ix * 3, iy * 7) < .03 && ((iy + (ix / 5).floor()) % 3 == 0);
    return glint
        ? e.rgb(120, 140, 200)
        : (iy % 4 == 0 && e.hash(ix >> 2, iy) < .3)
        ? e.rgb(30, 44, 96)
        : e.rgb(22, 32, 78);
  }

  // comida-set.html: skyOf
  int skyOf(int ix, int iy) {
    final hz = e.OY + ComidaE.B.hor * 13;
    final t = e.clamp(iy / hz, 0, 1);
    final dx = ix + .5 - 60, dy = iy + .5 - 12;
    if (math.sqrt(dx * dx + dy * dy) < 7) return e.rgb(250, 250, 240);
    if (e.hash(ix * 7, iy * 13) < .02) return e.rgb(240, 240, 255);
    return e.rgb(14 + t * 26, 18 + t * 30, 56 + t * 50);
  }

  // comida-set.html: rail
  void rail() {
    const R = ComidaE.RAIL;
    for (final u in R.posts) {
      PZ.post(u, R.v, 0, R.h, .05, FondaBase.WOOD_L);
    }
    PZ.box(0, R.v, R.h, R.h + .08, 5, .07, FondaBase.WOOD_L);
    PZ.box(0, R.v, .38, .44, 5, .03, FondaBase.WOOD);
    for (final u in const [-4.4, -2.2, 0.0, 2.2, 4.4]) {
      PZ.post(u, R.v, R.h, R.lights + .12, .035, FondaBase.WOOD);
    }
    const cols = [
      [255, 226, 140],
      [255, 170, 120],
      [180, 230, 255],
    ];
    for (var u = -4.4; u <= 4.4; u += .05) {
      final t = (u + 4.4).remainder(2.2) / 2.2;
      final z = R.lights - .22 * 4 * t * (1 - t);
      final p = PZ.xy(u, R.v);
      e.plot(p[0], p[1], z, e.rgb(80, 70, 60));
    }
    var kk = 0;
    for (var u = -4.4 + .28; u < 4.4; u += .37) {
      final t = (u + 4.4).remainder(2.2) / 2.2;
      final z = R.lights - .22 * 4 * t * (1 - t) - .06;
      final p = PZ.xy(u, R.v + .03);
      final c = cols[kk++ % 3];
      for (final off in const [
        [0.0, 0.0],
        [.055, 0.0],
        [0.0, .05],
        [.055, .05],
        [.028, .1],
      ]) {
        k.plotGlow(
          p[0] + off[0] * .7,
          p[1] - off[0] * .7,
          z + off[1],
          e.rgb(c[0], c[1], c[2]),
        );
      }
    }
  }

  // comida-set.html: station
  void station() {
    const S = ComidaE.STATION;
    const W1 = [226, 214, 196];
    for (final du in [-S.hw + .08, S.hw - .08]) {
      PZ.post(S.u + du, S.v + S.hd - .08, 0, .14, .04, FondaBase.WOOD_D);
    }
    PZ.box(S.u, S.v, .12, .74, S.hw, S.hd, FondaBase.WOOD, (s, t, z, face) {
      if (face == 'top') return e.rgb(W1[0], W1[1], W1[2]);
      if (face != 'front') return 0;
      final hx = (s.abs() - .1) * 26, hy = (z - .42) * 22.5;
      if (math.sqrt(hx * hx + hy * hy) < 1.3) {
        return e.rgb(
          FondaBase.BRASS[0],
          FondaBase.BRASS[1],
          FondaBase.BRASS[2],
        );
      }
      if (z > .2 && z < .66 && (s.abs() - S.hw / 2).abs() < S.hw / 2 - .07) {
        return e.rgb(
          FondaBase.WOOD_L[0],
          FondaBase.WOOD_L[1],
          FondaBase.WOOD_L[2],
        );
      }
      return 0;
    });
    PZ.box(S.u, S.sv, .74, S.shelf, S.hw, .12, FondaBase.WOOD, (s, t, z, face) {
      if (face == 'top') return e.rgb(W1[0], W1[1], W1[2]);
      if (face == 'front' &&
          z > .84 &&
          z < S.shelf - .1 &&
          s.abs() < S.hw - .08) {
        return e.rgb(
          FondaBase.WOOD_L[0],
          FondaBase.WOOD_L[1],
          FondaBase.WOOD_L[2],
        );
      }
      return 0;
    });
    for (var du = -S.hw; du <= S.hw; du += .3) {
      PZ.shadow(S.u + du, S.v, .5, .45);
    }
    const V = ComidaE.SERVE;
    FD.table(V.u, V.v, V.hw, V.hd, const [236, 214, 150]);
    final potXy = PZ.xy(V.pot[0], V.pot[1]);
    k.drum(
      potXy[0],
      potXy[1],
      .74,
      1.12,
      V.pot[2],
      const [84, 86, 96],
      (a, bb) => math.sqrt(a * a + bb * bb) < V.pot[2] - .05
          ? e.rgb(238, 206, 110)
          : 0,
    );
    for (final s in const [-1, 1]) {
      PZ.box(
        V.pot[0] + s * (V.pot[2] + .04),
        V.pot[1],
        1.0,
        1.06,
        .05,
        .04,
        const [60, 60, 70],
      );
    }
    for (var kk = 0; kk < 7; kk++) {
      final p = PZ.xy(V.plates[0], V.plates[1]);
      k.drum(
        p[0],
        p[1],
        .74 + kk * .04,
        .74 + kk * .04 + .03,
        .24,
        (kk % 2) != 0 ? const [226, 230, 240] : const [252, 252, 252],
      );
    }
  }

  // comida-set.html: tableLong
  void tableLong() {
    const T = ComidaE.TABLE;
    SEATS = FD.setTable(
      T.u,
      T.v,
      T.hw,
      seats: 4,
      span: 2.85,
      hd: T.hd,
      cloth: const [250, 246, 236],
    );
  }

  // comida-set.html: buildSet
  void buildSet(ComidaState state) {
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
        final guv = PZ.uv(g.x, g.y);
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = guv[1] < -.02 ? KIND_WATER : KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('baranda', rail);
    k.part('auxiliar', station);
    k.part('mesa', tableLong);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [.95, .92, .95], const [2, 0, 4], false);
    k.skyFill(skyOf);
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // comida-set.html: frame
  void frame(double t, [List<ShadowCast> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c.x, c.y, c.z, c.r);
    }
    e.applyShadows(e.groundZ);
  }
}
