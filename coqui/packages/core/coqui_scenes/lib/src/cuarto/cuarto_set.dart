// Port of docs/proyecto/pixel/cuarto-set.html: El cuarto's set (place 9, La casa, un día entero, scene 1: `cuarto`),
// call for call (order 70). Built on La casa's shared kit (`CasaBase`), La fonda's (`FondaBase`), and La plaza's
// painters (`PlazaBase`). The page's names are kept, capitals included (page 12, section 6): the lints on names are off
// in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/casa/casa_base.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// cuarto-set.html: ORIGIN.
const List<double> CUARTO_ORIGIN = [0, -42];

/// The engine El cuarto's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine cuartoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: CUARTO_ORIGIN[0],
  originY: CUARTO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (cuarto-set.html: `SET`, from the address):
/// `hora` = alba | manana; `luz` = 0 | 1; `cuna` = 0 | 1; `butaca` = 0 | 1.
class CuartoState {
  const CuartoState({
    this.hora = 'manana',
    this.luz = 0,
    this.cuna = 0,
    this.butaca = 0,
  });

  /// cuarto-set.html: `pick` and `on` from a query; disallowed values take defaults as there.
  factory CuartoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    int on(String k) => q[k] == '1' ? 1 : 0;
    return CuartoState(
      hora: h != null && const ['alba', 'manana'].contains(h) ? h : 'manana',
      luz: on('luz'),
      cuna: on('cuna'),
      butaca: on('butaca'),
    );
  }

  /// A key of the sheet's `setKey` (`hora|luz|cuna|butaca`, e.g. `"alba|0|0|0"`).
  factory CuartoState.fromKey(String key) {
    final parts = key.split('|');
    if (parts.length != 4) {
      throw ArgumentError.value(key, 'key', "not a key of El cuarto's set");
    }
    final h = parts[0];
    if (!const ['alba', 'manana'].contains(h)) {
      throw ArgumentError.value(key, 'key', 'invalid hora in cuarto key');
    }
    int bit(String s) {
      if (s == '0') return 0;
      if (s == '1') return 1;
      throw ArgumentError.value(key, 'key', 'invalid flag in cuarto key');
    }

    return CuartoState(
      hora: h,
      luz: bit(parts[1]),
      cuna: bit(parts[2]),
      butaca: bit(parts[3]),
    );
  }

  /// State from a scene's world map [w].
  factory CuartoState.fromWorld(Map<String, dynamic> w) {
    final h = w['hora'];
    final hora = h == 'alba' ? 'alba' : 'manana';
    return CuartoState(
      hora: hora,
      luz: jsTruthy(w['luz']) ? 1 : 0,
      cuna: jsTruthy(w['cuna']) ? 1 : 0,
      butaca: jsTruthy(w['butaca']) ? 1 : 0,
    );
  }

  final String hora;
  final int luz;
  final int cuna;
  final int butaca;

  /// The sheet's key (`hora|luz|cuna|butaca`).
  String get key => '$hora|$luz|$cuna|$butaca';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&luz=$luz&cuna=$cuna&butaca=$butaca';
}

/// cuarto-set.html: `E`, the set's places (the sheet reads them: wall, light, window, clock, door, beds, table,
/// armchair, cradle, chair, rug).
abstract final class CuartoE {
  static const double WALL = 3.1;
  static const ({double u, double z, List<double> sw}) LIGHT = (
    u: -2.55,
    z: 2.2,
    sw: [-2.55, 1.3],
  );
  static const List<double> WINDOW = [-1.75, -.25, 1.35, 2.45];
  static const List<double> CLOCK = [.75, 2.25];
  static const List<double> DOOR = [2.75, 3.62, 0, 2.15];
  static const List<({double u, List<int> c})> BEDS = [
    (u: -1.5, c: [110, 150, 220]),
    (u: 1.2, c: [236, 150, 170]),
  ];
  static const ({double v0, double v1, double hw}) BED = (
    v0: .25,
    v1: 3.2,
    hw: .66,
  );
  static const ({double u, double v, double hw, double hd, double h}) TABLE = (
    u: -.15,
    v: .55,
    hw: .4,
    hd: .28,
    h: .55,
  );
  static const List<double> ARMCHAIR = [-3.15, 1.3];
  static const ({double u, double v, double hw, double hd}) CRADLE = (
    u: 2.28,
    v: .75,
    hw: .33,
    hd: .3,
  );
  static const List<double> CHAIR = [2.9, 4.3];
  static const List<double> RUG = [-3.3, 4.2, -.7, 5.9];
}

/// Port of cuarto-set.html: builds the baked set into [e].
class CuartoSet {
  CuartoSet(this.e, this.b) : k = SetKit(e, b) {
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

  // cuarto-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    return uv[1] < -.02 ? rgb(84, 70, 70) : CS.boards(uv[0], uv[1], ix, iy);
  }

  // cuarto-set.html: backWall
  void backWall(CuartoState state) {
    PZ.wall(-5, 5, 0, 0, CuartoE.WALL, (u, z) {
      const L = CuartoE.LIGHT;
      final sw = (u - L.sw[0]).abs() < .13 && (z - L.sw[1]).abs() < .16;
      if (sw) {
        return ((u - L.sw[0]).abs() < .05 && (z - L.sw[1]).abs() < .07)
            ? rgb(120, 120, 130)
            : rgb(252, 250, 244);
      }
      var c = CS.windowAt(u, z, CuartoE.WINDOW, state.hora);
      if (c != 0) return c;
      c = CS.clockAt(u, z, CuartoE.CLOCK[0], CuartoE.CLOCK[1]);
      if (c != 0) return c;
      c = CS.doorAt(u, z, CuartoE.DOOR, true);
      if (c != 0) return c;
      return CS.paint(u, z, const [226, 214, 236]);
    });
    CS.lampWall(CuartoE.LIGHT.u, CuartoE.LIGHT.z, state.luz != 0);
  }

  // cuarto-set.html: room
  void room(CuartoState state) {
    CS.rug(
      CuartoE.RUG[0],
      CuartoE.RUG[1],
      CuartoE.RUG[2],
      CuartoE.RUG[3],
      const [86, 150, 150],
      const [240, 230, 200],
    );
    if (state.butaca != 0) {
      CS.armchair(CuartoE.ARMCHAIR[0], CuartoE.ARMCHAIR[1], const [
        150,
        110,
        170,
      ]);
    }
    for (final bd in CuartoE.BEDS) {
      CS.bed(bd.u, CuartoE.BED.v0, CuartoE.BED.v1, CuartoE.BED.hw, bd.c);
    }
    const T = CuartoE.TABLE;
    PZ.box(
      T.u,
      T.v,
      0,
      T.h,
      T.hw,
      T.hd,
      FondaBase.WOOD,
      (s, t, z, face) => face == 'top'
          ? _rgb(FondaBase.WOOD_L)
          : (face == 'front' && z > .1 && z < T.h - .1 && s.abs() < T.hw - .07)
          ? (jsHypot(s * 26, (z - .3) * 22.5) < 1.4
                ? _rgb(FondaBase.BRASS)
                : _rgb(FondaBase.WOOD_L))
          : 0,
    );
    if (state.cuna != 0) {
      const C = CuartoE.CRADLE;
      // the cradle: a bed of slats on rockers
      PZ.box(C.u, C.v, .3, .4, C.hw, C.hd, const [
        250,
        246,
        236,
      ], (s, t, z, face) => face == 'top' ? rgb(250, 226, 150) : 0);
      PZ.wall(
        C.u - C.hw,
        C.u + C.hw,
        C.v - C.hd,
        .4,
        .95,
        (a, bb) =>
            (bb > .88 || ((a - C.u + C.hw) / .09).floor().remainder(2) == 0)
            ? rgb(250, 246, 236)
            : 0,
      );
      PZ.wall(
        C.u - C.hw,
        C.u + C.hw,
        C.v + C.hd,
        .4,
        .78,
        (a, bb) =>
            (bb > .72 ||
                (a - C.u).abs() > C.hw - .05 ||
                ((a - C.u + C.hw) / .09).floor().remainder(2) == 0)
            ? rgb(250, 246, 236)
            : 0,
      );
      PZ.wall(C.u - C.hw - .08, C.u + C.hw + .08, C.v + C.hd + .02, 0, .3, (
        a,
        bb,
      ) {
        final d = (a - C.u) / (C.hw + .08);
        return (bb - (.02 + d * d * .2)).abs() < .045
            ? _rgb(FondaBase.WOOD_L)
            : (((a - C.u).abs() - C.hw + .06).abs() < .03
                  ? _rgb(FondaBase.WOOD_L)
                  : 0);
      });
      PZ.shadow(C.u, C.v, .3, .4);
    }
    FD.chair(CuartoE.CHAIR[0], CuartoE.CHAIR[1]);
    PZ.shadow(CuartoE.CHAIR[0], CuartoE.CHAIR[1], .4, .3);
  }

  // cuarto-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(CuartoState state) {
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
    k.part('cuarto', () => room(state));
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    final dim = state.hora == 'alba' && state.luz == 0;
    k.lightPass(
      dim ? const [.66, .68, .84] : const [1.0, .97, .92],
      dim ? const [-4, -2, 16] : const [3, 1, -3],
      false,
    );
    k.skyFill((ix, iy) => rgb(30, 24, 30));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // cuarto-set.html: frame
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
