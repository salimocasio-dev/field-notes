// Port of docs/proyecto/pixel/cielo-set.html: El cielo's set (place 7, La playa, scene 4: `cielo`), its states, call
// for call (order 65). Built on La playa's kit (lib/src/playa/playa_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/playa/playa_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// cielo-set.html: ORIGIN.
const List<double> CIELO_ORIGIN = [0, 44];

/// The engine El cielo's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, 44), shadows to (.9, -.1).
PpEngine cieloEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: CIELO_ORIGIN[0],
  originY: CIELO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (cielo-set.html: `SET`, from the address): `cielo` azul, nublado, gris, rosa or noche;
/// `toldo` arriba (rolled up on its beam) or abajo (down behind the table).
class CieloState {
  const CieloState({this.cielo = 'azul', this.toldo = 'arriba'});

  /// cielo-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory CieloState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final c = q['cielo'];
    final t = q['toldo'];
    return CieloState(
      cielo:
          c != null &&
              const ['azul', 'nublado', 'gris', 'rosa', 'noche'].contains(c)
          ? c
          : 'azul',
      toldo: t != null && const ['arriba', 'abajo'].contains(t) ? t : 'arriba',
    );
  }

  /// A key of the sheet's `setKey` ("cielo-toldo", e.g. "gris-abajo") read back.
  factory CieloState.fromKey(String key) {
    final m = RegExp(r'^(azul|nublado|gris|rosa|noche)-(arriba|abajo)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of El cielo's set");
    }
    return CieloState(cielo: m[1]!, toldo: m[2]!);
  }

  final String cielo;
  final String toldo;

  /// The sheet's key.
  String get key => '$cielo-$toldo';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?cielo=$cielo&toldo=$toldo';
}

/// cielo-set.html: E, the set's places (the sheet reads them: things, spots, sky).
abstract final class CieloE {
  static const PlayaBeach B = PlayaBeach(
    edge: -1.9,
    wet: .6,
    deep: -2.9,
    hor: -3.7,
  );
  static const ({double u0, double u1, double v0, double v1, double h}) DECK = (
    u0: -4.1,
    u1: -1.2,
    v0: .3,
    v1: 2.7,
    h: .25,
  );
  static const double BEAM = 2.6;
  static const List<double> TABLE = [-2.0, 1.6];
  static const List<double> CHAIR = [-3.3, 1.7];
  static const List<double> BLANKET = [.1, 2.3, 2.7, 3.9];
  static const List<double> PALM = [3.7, .9];
  static const ({
    List<num> sun,
    List<num> cloud,
    List<num> moon,
    List<num> star,
    List<num> long,
  })
  SKY = (
    sun: [196, 26, 9],
    cloud: [150, 34],
    moon: [42, 30, 12],
    star: [196, 30],
    long: [118, 46],
  );
}

/// Port of cielo-set.html: builds the baked set into [e].
class CieloSet {
  CieloSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    PL = PlayaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final PlayaBase PL;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  // cielo-set.html: groundAt
  PlayaGround? groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    return PL.ground(uv[0], uv[1], ix, iy, CieloE.B);
  }

  // cielo-set.html: deck
  void deck(CieloState state) {
    const D = CieloE.DECK;
    const W1 = [196, 150, 100];
    final mid = (D.u0 + D.u1) / 2, hw = (D.u1 - D.u0) / 2;
    PZ.box(
      mid,
      (D.v0 + D.v1) / 2,
      0,
      D.h,
      hw,
      (D.v1 - D.v0) / 2,
      W1,
      (s, t, z, face) => face == 'top'
          ? (jsMod(s + hw, .36) < .035 ? rgb(140, 100, 64) : 0)
          : (face == 'front' && z < .05 ? rgb(120, 86, 56) : 0),
    );
    for (final u in [D.u0 + .08, D.u1 - .08]) {
      PZ.post(u, D.v0 + .08, D.h, CieloE.BEAM, .06, const [240, 232, 212]);
    }
    PZ.box(mid, D.v0 + .08, CieloE.BEAM, CieloE.BEAM + .12, hw, .06, const [
      240,
      232,
      212,
    ]);
    if (state.toldo == 'arriba') {
      PZ.box(
        mid,
        D.v0 + .1,
        CieloE.BEAM - .2,
        CieloE.BEAM,
        hw - .12,
        .09,
        const [86, 160, 190],
        (s, t, z, face) =>
            face == 'front' && ((s + hw) / .3).floor().remainder(2) != 0
            ? rgb(250, 246, 236)
            : 0,
      );
    } else {
      PZ.wall(
        D.u0 + .14,
        D.u1 - .14,
        D.v0 + .1,
        D.h + .1,
        CieloE.BEAM,
        (u, z) => (z < D.h + .18)
            ? rgb(120, 86, 56)
            : b.shade(
                ((u - D.u0) / .3).floor().remainder(2) != 0
                    ? const [250, 246, 236]
                    : const [86, 160, 190],
                2.4,
                u * 3,
                z,
                .2,
              ),
      );
    }
    PZ.wall(
      D.u1 - .13,
      D.u1 - .1,
      D.v0 + .12,
      1.2,
      CieloE.BEAM - .2,
      (u, z) => rgb(90, 70, 56),
    );
    final tp = PZ.xy(CieloE.TABLE[0], CieloE.TABLE[1]);
    final tx = tp[0], ty = tp[1];
    k.drum(tx, ty, D.h, D.h + .64, .07, PlazaBase.IRON);
    k.drum(tx, ty, D.h + .64, D.h + .72, .5, const [
      250,
      246,
      236,
    ], (a, bb) => jsHypot(a, bb) > .43 ? rgb(226, 90, 80) : 0);
    e.castShadow(tx, ty, .7, .5);
    final cu = CieloE.CHAIR[0], cv = CieloE.CHAIR[1];
    const WD = [196, 144, 92];
    PZ.box(cu, cv, D.h + .34, D.h + .44, .3, .26, WD);
    PZ.box(
      cu,
      cv - .26,
      D.h + .44,
      D.h + 1.25,
      .3,
      .04,
      WD,
      (s, t, z, face) =>
          face == 'front' && (jsMod(s + .3, .15) - .075).abs() < .03
          ? rgb(120, 84, 52)
          : 0,
    );
    for (final du in const [-.26, .26]) {
      PZ.box(cu + du, cv, D.h, D.h + .08, .05, .42, const [120, 86, 56]);
    }
    for (final (du, dv) in const [
      (-.24, .2),
      (.24, .2),
      (-.24, -.2),
      (.24, -.2),
    ]) {
      PZ.post(cu + du, cv + dv, D.h + .06, D.h + .34, .03, WD);
    }
    PZ.shadow(cu, cv, .5, .4);
  }

  // cielo-set.html: disc
  static bool _disc(int ix, int iy, List<num> c, num r) =>
      jsHypot(ix + .5 - c[0], iy + .5 - c[1]) < r;

  // cielo-set.html: puff
  static bool _puff(int ix, int iy, num cx, num cy, [num kk = 1]) {
    const blobs = [
      (0.0, 0.0, 9.0),
      (-9.0, 2.0, 6.5),
      (9.0, 2.0, 7.0),
      (-3.0, -4.0, 6.0),
      (5.0, -4.0, 5.5),
    ];
    for (final (dx, dy, r) in blobs) {
      if (jsHypot(ix + .5 - cx - dx * kk, (iy + .5 - cy - dy * kk) * 1.25) <
          r * kk) {
        return true;
      }
    }
    return false;
  }

  // cielo-set.html: skyOf
  int skyOf(int ix, int iy, CieloState state) {
    const K = CieloE.SKY;
    final hz = e.OY + CieloE.B.hor * 13;
    final t = e.clamp<double>(iy / hz, 0, 1);
    final dth = (e.bayerAt(ix, iy) - .5) * .08;
    int band(List<num> A, List<num> B) {
      final f = e.clamp<double>(t + dth, 0, 1);
      return rgb(
        A[0] + (B[0] - A[0]) * f,
        A[1] + (B[1] - A[1]) * f,
        A[2] + (B[2] - A[2]) * f,
      );
    }

    if (state.cielo == 'noche') {
      final M = K.moon, S2 = K.star;
      if (_disc(ix, iy, M, M[2])) {
        return (jsHypot(ix - M[0] + 4, iy - M[1] + 3) < 3 ||
                jsHypot(ix - M[0] - 4, iy - M[1] - 2) < 2.2)
            ? rgb(214, 218, 226)
            : rgb(250, 250, 244);
      }
      final dx = (ix + .5 - S2[0]).abs(), dy = (iy + .5 - S2[1]).abs();
      if ((dx < 1.2 && dy < 8) || (dy < 1.2 && dx < 8) || dx + dy < 4.2) {
        return rgb(255, 250, 214);
      }
      if (jsHypot(
            (ix + .5 - K.long[0]) / 42,
            (iy + .5 - K.long[1]) / 5 - math.sin(ix * .12) * .25,
          ) <
          1) {
        return rgb(96, 104, 150);
      }
      if (e.hash(ix * 7, iy * 13) < .012 && iy < hz - 6) {
        return e.hash(ix, iy) < .5 ? rgb(250, 250, 255) : rgb(190, 200, 240);
      }
      return band(const [18, 24, 66], const [50, 60, 120]);
    }
    if (state.cielo == 'gris') {
      if (iy > hz - 9) {
        return band(const [236, 150, 80], const [246, 176, 96]);
      }
      final n = e.noise(ix * .05, iy * .09);
      return n > .55
          ? rgb(120, 126, 140)
          : n > .42
          ? rgb(144, 150, 164)
          : rgb(168, 174, 186);
    }
    if (state.cielo == 'rosa') {
      if (iy > hz - 12) {
        return band(const [250, 170, 150], const [252, 196, 170]);
      }
      final n = e.noise(ix * .05 + 9, iy * .09);
      return n > .66
          ? rgb(190, 176, 196)
          : band(const [110, 130, 190], const [236, 170, 170]);
    }
    if (state.cielo == 'nublado') {
      final n = e.noise(ix * .045, iy * .08) + (ix / W - .5) * .5;
      if (n > .5) {
        return n > .62 ? rgb(236, 238, 244) : rgb(214, 220, 232);
      }
      return band(const [96, 150, 226], const [176, 208, 246]);
    }
    if (_disc(ix, iy, K.sun, K.sun[2])) return rgb(255, 240, 170);
    if (_puff(ix, iy, K.cloud[0], K.cloud[1])) {
      return (iy > K.cloud[1] + 3) ? rgb(226, 234, 246) : rgb(252, 252, 255);
    }
    return band(const [80, 150, 236], const [190, 222, 255]);
  }

  // cielo-set.html: L
  static Light? _lightOf(String cielo) => const <String, Light>{
    'nublado': Light([.9, .92, .96], [0, 0, 4]),
    'gris': Light([.78, .8, .88], [0, 0, 6]),
    'rosa': Light([1.0, .9, .86], [10, 0, -4]),
    'noche': Light([.5, .54, .8], [-6, -4, 18]),
  }[cielo];

  // cielo-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(CieloState state) {
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
        e.kinds[i] = c.kind == 'mar' ? KIND_WATER : KIND_SAND;
      }
    }
    e.groundZ.setAll(0, e.zb);
    final L = _lightOf(state.cielo);
    k.part(
      'manta',
      () => PL.blanket(
        CieloE.BLANKET[0],
        CieloE.BLANKET[1],
        CieloE.BLANKET[2],
        CieloE.BLANKET[3],
        const [236, 150, 60],
        const [250, 246, 236],
      ),
    );
    k.part('porche', () => deck(state));
    k.part(
      'palma',
      () => PL.palm(CieloE.PALM[0], CieloE.PALM[1], 3.6, .4, 3, 1, L),
    );
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    if (L != null) k.lightPass(L.m, L.a, false);
    k.skyFill((ix, iy) => skyOf(ix, iy, state));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // cielo-set.html: frame
  /// Restores the baked set, draws swaying palm fronds at wind time [t], and casts [casts].
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
