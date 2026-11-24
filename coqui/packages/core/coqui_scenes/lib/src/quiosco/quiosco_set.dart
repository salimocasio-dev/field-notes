// Port of docs/proyecto/pixel/quiosco-set.html: El quiosco's set (place 6, La plaza, scene 3: `quiosco`), its
// states, call for call (order 60b). The square's pieces are La plaza's kit (lib/src/plaza/plaza_base.dart). The page's
// names are kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// quiosco-set.html: ORIGIN.
const List<double> QUIOSCO_ORIGIN = [0, 14];

/// The engine El quiosco's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, 14), shadows to (.9, -.1).
PpEngine quioscoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: QUIOSCO_ORIGIN[0],
  originY: QUIOSCO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (quiosco-set.html: `SET`, from the address): `hora` mediodia or tarde (the light),
/// `fiesta` (paper flags from the posts out to each side; story 68).
class QuioscoState {
  const QuioscoState({this.hora = 'mediodia', this.fiesta = false});

  /// quiosco-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory QuioscoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return QuioscoState(
      hora: h != null && const ['mediodia', 'tarde'].contains(h)
          ? h
          : 'mediodia',
      fiesta: q['fiesta'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-fiesta", e.g. "mediodia-0") read back.
  factory QuioscoState.fromKey(String key) {
    final m = RegExp(r'^(mediodia|tarde)-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of El quiosco's set");
    }
    return QuioscoState(hora: m[1]!, fiesta: m[2] == '1');
  }

  final String hora;
  final bool fiesta;

  /// The sheet's key.
  String get key => '$hora-${fiesta ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&fiesta=${fiesta ? 1 : 0}';
}

/// quiosco-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class QuioscoE {
  static const double CH = 1.05;
  static const ({double u0, double u1, double v0, double v1}) FRONT = (
    u0: -1.5,
    u1: 1.5,
    v0: -.5,
    v1: 0,
  );
  static const ({double hw, double v0, double v1, double uL, double uR}) WING =
      (hw: .25, v0: -.5, v1: 1.65, uL: -1.75, uR: 1.75);
  static const List<List<double>> STOOLS = [
    [-2.95, 1.45],
    [-2.6, .15],
    [2.6, .15],
    [2.95, 1.45],
  ];
  static const double BACK = -1.4;
  static const double ROOF = 3.25;
  static const List<double> TABLE = [-2.75, 3.9];
  static const double WALL = -3.4;
  static const double END = -4.9;
  static const List<double> TOWER = [34, 52];
}

/// Port of quiosco-set.html: builds the baked set into [e].
class QuioscoSet {
  QuioscoSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  static const List<int> TEAL = [70, 150, 150];
  static const List<int> TEAL_D = [52, 118, 120];
  static const List<int> WH = [250, 246, 236];
  static const List<int> TOPC = [226, 214, 196];

  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v < QuioscoE.END) return 0;
    if (v < QuioscoE.WALL - .1) return PZ.grass(u, v, ix, iy);
    return PZ.paving(u, v, ix, iy);
  }

  int _panel(num s, num z, num hw) =>
      (z > .14 && z < QuioscoE.CH - .16 && s.abs() < hw - .1)
      ? b.shade(TEAL, 2.2, s * 4, z)
      : 0;

  void stand(QuioscoState state) {
    const F = QuioscoE.FRONT, Wg = QuioscoE.WING;
    final mid = (F.u0 + F.u1) / 2;
    const shelfCols = [
      [214, 62, 54],
      [250, 206, 70],
      [86, 160, 150],
      [250, 250, 250],
      [150, 90, 60],
    ];
    PZ.wall(F.u0 - .1, F.u1 + .1, QuioscoE.BACK, 0, QuioscoE.ROOF, (u, z) {
      if (z < 1.0) return b.shade(TEAL_D, 1.8, u * 3, z);
      for (final zs in const [1.2, 1.72]) {
        if (z > zs - .06 && z < zs) return rgb(150, 104, 62);
        if (z >= zs && z < zs + .36) {
          final kk = ((u + 4) / .22).floor();
          final f = jsMod((u + 4) / .22, 1);
          if (f > .2 &&
              f < .8 &&
              (z - zs) < .16 + (e.hash(kk, (zs * 10).toInt()) * .2)) {
            final c = shelfCols[(kk + (zs > 1.5 ? 2 : 0)) % 5];
            return rgb(c[0], c[1], c[2]);
          }
        }
      }
      return jsMod(u + 4, .5) < .03
          ? rgb(206, 196, 176)
          : b.shade(const [240, 232, 212], 2.2, u, z);
    });
    PZ.box(
      mid,
      (F.v0 + F.v1) / 2,
      0,
      QuioscoE.CH,
      (F.u1 - F.u0) / 2,
      (F.v1 - F.v0) / 2,
      WH,
      (s, t, z, face) => face == 'front'
          ? _panel(s, z, (F.u1 - F.u0) / 2)
          : face == 'top'
          ? b.shade(TOPC, 3.4, s, t)
          : 0,
    );
    for (final u in [Wg.uL, Wg.uR]) {
      PZ.box(
        u,
        (Wg.v0 + Wg.v1) / 2,
        0,
        QuioscoE.CH,
        Wg.hw,
        (Wg.v1 - Wg.v0) / 2,
        WH,
        (s, t, z, face) => face == 'front'
            ? _panel(s, z, Wg.hw + .06)
            : face == 'top'
            ? b.shade(TOPC, 3.4, s, t)
            : 0,
      );
    }
    PZ.box(
      -.8,
      -.36,
      QuioscoE.CH,
      QuioscoE.CH + .5,
      .16,
      .1,
      const [176, 60, 50],
      (s, t, z, face) =>
          face == 'front' && z > QuioscoE.CH + .3 && s.abs() < .09
          ? rgb(60, 50, 50)
          : 0,
    );
    for (var kk = 0; kk < 3; kk++) {
      PZ.box(
        -.52,
        -.36,
        QuioscoE.CH + kk * .1,
        QuioscoE.CH + kk * .1 + .08,
        .07,
        .07,
        const [250, 250, 250],
      );
    }
    for (final u in [Wg.uL - .1, Wg.uR + .1]) {
      PZ.post(u, .1, QuioscoE.CH, QuioscoE.ROOF - .12, .06, const [
        240,
        232,
        212,
      ]);
    }
    final r0 = Wg.uL - .35,
        r1 = Wg.uR + .35,
        vf = .22,
        vb = QuioscoE.BACK - .1,
        zt = QuioscoE.ROOF + 1.0,
        vm = (vf + vb) / 2;
    PZ.wall(
      r0,
      r1,
      vf,
      QuioscoE.ROOF - .14,
      QuioscoE.ROOF + .02,
      (u, z) => (((u + 6) / .24).floor() % 2 != 0)
          ? rgb(56, 124, 126)
          : rgb(232, 228, 216),
    );
    k.planeQuad(
      PZ.P(r0, vf, QuioscoE.ROOF),
      [(r1 - r0) / R2, -(r1 - r0) / R2, 0],
      [(vm - vf) / R2, (vm - vf) / R2, zt - QuioscoE.ROOF],
      (a, bb) {
        final inset = bb * .32;
        if (a < inset || a > 1 - inset) return 0;
        final f = (a - inset) / (1 - 2 * inset);
        return (f < .3 - bb * .02 || f > .7 + bb * .02)
            ? b.shade(PlazaBase.TILE, 2.0, a * 20, bb * 8)
            : b.shade(PlazaBase.TILE, 2.9, a * 20, bb * 8);
      },
    );
    PZ.ball(mid, vm, zt + .12, .16, const [250, 206, 70], 'gloss');
    PZ.wall(
      mid - .62,
      mid + .62,
      vf + .03,
      QuioscoE.ROOF + .06,
      QuioscoE.ROOF + 1.02,
      (u, z) {
        final px = (u - mid) * 26,
            pz = (z - QuioscoE.ROOF - .54) * 22.5,
            d = jsHypot(px, pz);
        if (d > 10.5) return 0;
        if (d > 9) return rgb(120, 76, 50);
        if (pz < 1.5 &&
            pz > -5.5 &&
            (px + 1).abs() < 4.6 - (pz < -3 ? (-3 - pz) * .8 : 0)) {
          return pz > .4 ? rgb(90, 56, 40) : rgb(210, 60, 54);
        }
        if (px > 3.4 &&
            px < 6.6 &&
            pz < 0 &&
            pz > -3.8 &&
            !(px < 5.4 && pz < -1 && pz > -2.8)) {
          return rgb(210, 60, 54);
        }
        if (pz < -5.5 && pz > -6.8 && px.abs() < 6.5) {
          return rgb(250, 250, 250);
        }
        if (pz > 2.4 &&
            pz < 7.4 &&
            ((px + 3 - math.sin(pz * 1.3) * 1.1).abs() < .8 ||
                (px - 1 - math.sin(pz * 1.3) * 1.1).abs() < .8)) {
          return rgb(170, 160, 150);
        }
        return rgb(252, 244, 222);
      },
    );
    for (num u = r0; u <= r1; u += .4) {
      for (final v in const [-.9, -.3]) {
        PZ.shadow(u, v, 2.4, .5);
      }
    }
    for (final st in QuioscoE.STOOLS) {
      final p = PZ.xy(st[0], st[1]);
      k.drum(p[0], p[1], 0, .6, .05, PlazaBase.IRON);
      k.drum(p[0], p[1], .6, .68, .2, const [214, 62, 54]);
      e.castShadow(p[0], p[1], .5, .22);
    }
    if (state.fiesta) {
      PZ.flags(Wg.uL - .1, QuioscoE.ROOF - .5, -3.6, 2.2, .14, .25);
      PZ.flags(Wg.uR + .1, QuioscoE.ROOF - .5, 3.6, 2.2, .14, .25);
    }
  }

  void table() {
    final u = QuioscoE.TABLE[0], v = QuioscoE.TABLE[1];
    final p = PZ.xy(u, v);
    for (final du in const [-.5, .5]) {
      PZ.box(u + du, v - .5, 0, .42, .2, .2, PlazaBase.WOOD);
      PZ.box(u + du, v - .68, .42, .95, .2, .03, PlazaBase.WOOD);
      PZ.shadow(u + du, v - .5, .3, .25);
    }
    k.drum(p[0], p[1], 0, .62, .07, PlazaBase.IRON);
    k.drum(p[0], p[1], .62, .72, .52, const [
      250,
      246,
      236,
    ], (a, bb) => jsHypot(a, bb) > .44 ? rgb(70, 150, 150) : 0);
    e.castShadow(p[0], p[1], .6, .55);
  }

  /// Builds the baked set for [state] into [e].
  void buildSet(QuioscoState state) {
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
        final uv = PZ.uv(g.x, g.y);
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / R2 * COS;
        e.kinds[i] = uv[1] < QuioscoE.WALL - .1 ? e.KIND_GRASS : KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('fondo', () {
      for (final tr in const [
        [-4.6, 1.5, .95],
        [3.4, 2.0, 1.2],
        [5.2, 1.4, .9],
      ]) {
        PZ.tree(tr[0], QuioscoE.WALL - .8, tr[1], tr[2]);
      }
      PZ.hedge(-5.4, QuioscoE.END + .25, 5.4, QuioscoE.END + .25);
    });
    k.part(
      'muro',
      () => PZ.box(0, QuioscoE.WALL, 0, .55, 5.4, .13, PlazaBase.STONE),
    );
    k.part('flores', () {
      PZ.bed(-4.6, QuioscoE.WALL + .3, -2.4, QuioscoE.WALL + .9);
      PZ.bed(2.4, QuioscoE.WALL + .3, 4.6, QuioscoE.WALL + .9, const [
        [250, 250, 250],
        [236, 120, 170],
        [250, 206, 70],
      ]);
    });
    k.part('quiosco', () => stand(state));
    k.part('mesa', table);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PZ.light(state.hora);
    k.skyFill(
      PZ.sky(state.hora, [PZ.farTower(QuioscoE.TOWER[0], QuioscoE.TOWER[1])]),
    );
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  /// quiosco-set.html: `frame(t, casts = [])`.
  void frame([List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
