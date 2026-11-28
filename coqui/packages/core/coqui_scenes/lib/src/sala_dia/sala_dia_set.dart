// Port of docs/proyecto/pixel/sala_dia-set.html: La sala, de día's set (place 9, La casa, un día entero, scene 3:
// `sala_dia`), call for call (order 72). Built on La casa's kit (lib/src/casa/casa_base.dart), La fonda's kit
// (lib/src/fonda/fonda_base.dart), and La plaza's painters (lib/src/plaza/plaza_base.dart). The page's names are kept,
// capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/casa/casa_base.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// sala_dia-set.html: ORIGIN.
const List<double> SALA_DIA_ORIGIN = [0, -42];

/// The engine La sala, de día's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows (.9, -.1).
PpEngine salaDiaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: SALA_DIA_ORIGIN[0],
  originY: SALA_DIA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (sala_dia-set.html: `SET`, from the address): `pantalla` = 0 (dark) or 1 (lit).
class SalaDiaState {
  const SalaDiaState({this.pantalla = 0});

  /// sala_dia-set.html: `on('pantalla')` from a query; `'1'` lights the computer screen, anything else is 0.
  factory SalaDiaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    return SalaDiaState(pantalla: q['pantalla'] == '1' ? 1 : 0);
  }

  /// A key of the sheet's `setKey` (`"0"` or `"1"`) read back.
  factory SalaDiaState.fromKey(String key) {
    if (key == '0') return const SalaDiaState(pantalla: 0);
    if (key == '1') return const SalaDiaState(pantalla: 1);
    throw ArgumentError.value(key, 'key', "not a key of La sala, de día's set");
  }

  final int pantalla;

  /// The sheet's key (`"0"` or `"1"`).
  String get key => '$pantalla';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?pantalla=$pantalla';
}

/// sala_dia-set.html: E, the set's places (wall, clock, window, shelf, door, desk, screen, seats, low table, cushions,
/// armchair, side table).
abstract final class SalaDiaE {
  static const double WALL = 3.1;
  static const List<double> CLOCK = [-2.2, 2.3];
  static const List<double> WINDOW = [-1.2, .5, 1.3, 2.45];
  static const ({double u0, double u1, double h, double hd}) SHELF = (
    u0: 1.15,
    u1: 2.45,
    h: 2.0,
    hd: .2,
  );
  static const List<double> DOOR = [2.85, 3.62, 0.0, 2.15];
  static const ({double u, double v, double hw, double hd, double h}) DESK = (
    u: -2.7,
    v: 1.6,
    hw: .9,
    hd: .36,
    h: .72,
  );
  static const ({double u, double hw, double z0, double z1}) SCREEN = (
    u: -3.1,
    hw: .32,
    z0: .82,
    z1: 1.36,
  );
  static const List<double> DESKSEAT = [-2.3, .95];
  static const ({double u, double v, double hw, double hd, double h}) LOW = (
    u: .2,
    v: 4.3,
    hw: 1.3,
    hd: .5,
    h: .4,
  );
  static const List<List<double>> CUSHIONS = [
    [-.4, 3.5],
    [.8, 3.5],
  ];
  static const List<double> ARMCHAIR = [2.75, 2.7];
  static const ({double u, double v, double r, double h}) SIDE = (
    u: 1.6,
    v: 2.85,
    r: .36,
    h: .55,
  );
}

/// Port of sala_dia-set.html: builds the baked set into [e].
class SalaDiaSet {
  SalaDiaSet(this.e, this.b) : k = SetKit(e, b) {
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

  static const List<List<int>> _BOOK_COLS = [
    [196, 70, 60],
    [70, 110, 170],
    [236, 190, 90],
    [86, 150, 110],
    [150, 96, 150],
    [240, 236, 226],
  ];

  // sala_dia-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    return uv[1] < -.02
        ? rgb(84, 70, 70)
        : CS.boards(uv[0], uv[1], ix, iy, const [210, 170, 120]);
  }

  // sala_dia-set.html: backWall
  void backWall() {
    const B = SalaDiaE.SHELF;
    PZ.wall(-5, 5, 0, 0, SalaDiaE.WALL, (u, z) {
      var c = CS.windowAt(u, z, SalaDiaE.WINDOW, 'tarde');
      if (c != 0) return c;
      c = CS.clockAt(u, z, SalaDiaE.CLOCK[0], SalaDiaE.CLOCK[1]);
      if (c != 0) return c;
      c = CS.doorAt(u, z, SalaDiaE.DOOR, true);
      if (c != 0) return c;
      return CS.paint(u, z, const [236, 222, 190]);
    });
    final m = (B.u0 + B.u1) / 2, w = (B.u1 - B.u0) / 2;
    PZ.box(m, B.hd, 0, B.h, w, B.hd, FondaBase.WOOD, (s, t, z, face) {
      if (face != 'front') return face == 'top' ? _rgb(FondaBase.WOOD_L) : 0;
      if (s.abs() > w - .06 || z < .08) return 0;
      final row = ((z - .08) / .48).floor();
      final zz = (z - .08).remainder(.48);
      if (zz > .4) return 0;
      final kk = ((s + w) / .11).floor();
      final hgt = .26 + e.hash(kk * 3, row * 7) * .12;
      if (zz > hgt) return rgb(96, 66, 44);
      final idx = (kk * 5 + row * 3).remainder(6);
      final col = _BOOK_COLS[idx < 0 ? idx + 6 : idx];
      return rgb(col[0], col[1], col[2]);
    });
    PZ.shadow(m, B.hd + .2, .6, .6);
  }

  // sala_dia-set.html: room
  void room(SalaDiaState state) {
    const D = SalaDiaE.DESK, C = SalaDiaE.SCREEN;
    FD.chair(SalaDiaE.DESKSEAT[0], SalaDiaE.DESKSEAT[1]);
    PZ.box(D.u, D.v, D.h - .08, D.h, D.hw, D.hd, FondaBase.WOOD_L);
    for (final (aa, bb) in const [(-1, -1), (1, -1), (-1, 1), (1, 1)]) {
      PZ.post(
        D.u + aa * (D.hw - .08),
        D.v + bb * (D.hd - .07),
        0,
        D.h - .08,
        .045,
        FondaBase.WOOD,
      );
    }
    PZ.box(D.u, D.v + D.hd - .04, .3, D.h - .08, D.hw, .03, FondaBase.WOOD);
    PZ.box(C.u, D.v - .1, D.h, C.z0, .1, .06, const [70, 74, 86]);
    PZ.box(C.u, D.v - .1, C.z0, C.z1, C.hw, .04, const [70, 74, 86], (
      s,
      t,
      z,
      face,
    ) {
      if (face == 'front' &&
          s.abs() < C.hw - .05 &&
          z > C.z0 + .05 &&
          z < C.z1 - .05) {
        return state.pantalla != 0 ? rgb(150, 220, 250) : rgb(40, 46, 60);
      }
      return 0;
    });
    PZ.box(C.u, D.v + .14, D.h, D.h + .04, .26, .09, const [200, 204, 214]);
    for (double du = -D.hw; du <= D.hw; du += .3) {
      PZ.shadow(D.u + du, D.v, .5, .4);
    }
    const L = SalaDiaE.LOW;
    for (final c in SalaDiaE.CUSHIONS) {
      PZ.box(c[0], c[1], 0, .12, .36, .3, const [
        226,
        120,
        90,
      ], (s, t, z, face) => face == 'top' ? rgb(240, 150, 110) : 0);
    }
    PZ.box(
      L.u,
      L.v,
      L.h - .08,
      L.h,
      L.hw,
      L.hd,
      FondaBase.WOOD_L,
      (s, t, z, face) =>
          face == 'top' ? b.shade(FondaBase.WOOD_L, 3.3, s, t, .1) : 0,
    );
    for (final (aa, bb) in const [(-1, -1), (1, -1), (-1, 1), (1, 1)]) {
      PZ.post(
        L.u + aa * (L.hw - .1),
        L.v + bb * (L.hd - .1),
        0,
        L.h - .08,
        .05,
        FondaBase.WOOD,
      );
    }
    for (double du = -L.hw; du <= L.hw; du += .3) {
      PZ.shadow(L.u + du, L.v, .3, .5);
    }
    CS.armchair(SalaDiaE.ARMCHAIR[0], SalaDiaE.ARMCHAIR[1], const [
      110,
      140,
      96,
    ]);
    final sp = PZ.xy(SalaDiaE.SIDE.u, SalaDiaE.SIDE.v);
    final sx = sp[0], sy = sp[1];
    k.drum(sx, sy, 0, SalaDiaE.SIDE.h - .06, .05, FondaBase.WOOD);
    k.drum(
      sx,
      sy,
      SalaDiaE.SIDE.h - .06,
      SalaDiaE.SIDE.h,
      SalaDiaE.SIDE.r,
      FondaBase.WOOD_L,
    );
    e.castShadow(sx, sy, .4, .4);
  }

  // sala_dia-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(SalaDiaState state) {
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
    k.part('pared', backWall);
    k.part('sala', () => room(state));
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [1.0, .96, .88], const [6, 2, -6], false);
    k.skyFill((ix, iy) => rgb(30, 24, 30));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // sala_dia-set.html: frame
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
