// Port of docs/proyecto/pixel/calendario-set.html: El calendario's set (place 6, La plaza, scene 4: `calendario`), its
// states, call for call (order 61b). The square's pieces are La plaza's kit (lib/src/plaza/plaza_base.dart). The page's
// names are kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// calendario-set.html: ORIGIN.
const List<double> CALENDARIO_ORIGIN = [0, 12];

/// The engine El calendario's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, 12), shadows to (.9, -.1).
PpEngine calendarioEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: CALENDARIO_ORIGIN[0],
  originY: CALENDARIO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (calendario-set.html: `SET`, from the address): `hora` manana, tarde or noche (the light;
/// noche lights the lamps), `tela` (a cloth over the last three columns; story 69).
class CalendarioState {
  const CalendarioState({this.hora = 'manana', this.tela = false});

  /// calendario-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory CalendarioState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return CalendarioState(
      hora: h != null && const ['manana', 'tarde', 'noche'].contains(h)
          ? h
          : 'manana',
      tela: q['tela'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-tela", e.g. "manana-0") read back.
  factory CalendarioState.fromKey(String key) {
    final m = RegExp(r'^(manana|tarde|noche)-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of El calendario's set");
    }
    return CalendarioState(hora: m[1]!, tela: m[2] == '1');
  }

  final String hora;
  final bool tela;

  /// The sheet's key.
  String get key => '$hora-${tela ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&tela=${tela ? 1 : 0}';
}

/// calendario-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class CalendarioE {
  static const double BOARD_U0 = -2.5;
  static const double BOARD_CW = .68;
  static const double BOARD_V = 0;
  static const double BOARD_Z0 = 1.4;
  static const double BOARD_Z1 = 4.05;
  static const double BOARD_U1 = BOARD_U0 + .06 + 7 * BOARD_CW + .06;
  static const List<double> HEAD = [3.62, 3.95];
  static const List<double> HOOKS = [3.44, 2.8, 2.16];
  static const ({double z, double h}) ARCH = (z: 4.05, h: .82);
  static const ({double v0, double v1, double h}) STEP = (
    v0: .12,
    v1: .62,
    h: .3,
  );
  static const List<double> SEAT = [3.15, .2, 3.7];
  static const List<List<double>> LAMPS = [
    [-3.55, -1.0],
    [3.8, -.7],
  ];
  static const ({double u, double v}) STAND = (u: 3.6, v: -2.6);
  static const double WALL = -3.5;
  static const double END = -4.9;

  /// calendario-set.html: `colU(k)` — the left edge of column k (1 to 7; 8 is the right edge of column 7).
  static double colU(int kk) => BOARD_U0 + .06 + (kk - 1) * BOARD_CW;
}

/// Port of calendario-set.html: builds the baked set into [e].
class CalendarioSet {
  CalendarioSet(this.e, this.b) : k = SetKit(e, b) {
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

  static const List<int> GREEN = [96, 176, 96];
  static const List<int> ORANGE = [244, 150, 60];
  static const List<int> CORK = [240, 226, 196];
  static const List<int> FRAME = [120, 80, 52];

  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    if (v < CalendarioE.END) return 0;
    if (v < CalendarioE.WALL - .1) return PZ.grass(u, v, ix, iy);
    return PZ.paving(u, v, ix, iy);
  }

  int _boardFace(num u, num z) {
    if (u < CalendarioE.BOARD_U0 + .06 ||
        u > CalendarioE.BOARD_U1 - .06 ||
        z < CalendarioE.BOARD_Z0 + .06 ||
        z > CalendarioE.BOARD_Z1 - .05) {
      return rgb(FRAME[0], FRAME[1], FRAME[2]);
    }
    final kk = math.min(
      7,
      ((u - CalendarioE.BOARD_U0 - .06) / CalendarioE.BOARD_CW).floor() + 1,
    );
    final f = (u - CalendarioE.colU(kk)) / CalendarioE.BOARD_CW;
    if (f < .035 || f > .965) return rgb(206, 186, 150);
    if (z > CalendarioE.HEAD[0] &&
        z < CalendarioE.HEAD[1] &&
        f > .14 &&
        f < .86) {
      final c = kk <= 5 ? GREEN : ORANGE;
      return rgb(c[0], c[1], c[2]);
    }
    if (z > CalendarioE.HEAD[0] - .04 &&
        z < CalendarioE.HEAD[1] + .04 &&
        f > .1 &&
        f < .9) {
      final c = kk <= 5 ? const [60, 120, 70] : const [190, 104, 40];
      return rgb(c[0], c[1], c[2]);
    }
    for (final h in CalendarioE.HOOKS) {
      if ((z - h).abs() < .035 && (f - .5).abs() < .07) return rgb(70, 60, 60);
    }
    return kk > 5 ? rgb(250, 232, 200) : rgb(CORK[0], CORK[1], CORK[2]);
  }

  void board(CalendarioState state) {
    const mid = (CalendarioE.BOARD_U0 + CalendarioE.BOARD_U1) / 2;
    PZ.post(CalendarioE.BOARD_U0 + .02, -.07, 0, 4.4, .07, PlazaBase.WOOD_D);
    PZ.post(
      CalendarioE.BOARD_U1 - .02,
      -.07,
      0,
      CalendarioE.BOARD_Z1,
      .07,
      PlazaBase.WOOD_D,
    );
    PZ.wall(
      CalendarioE.BOARD_U0,
      CalendarioE.BOARD_U1,
      CalendarioE.BOARD_V,
      CalendarioE.BOARD_Z0,
      CalendarioE.BOARD_Z1,
      _boardFace,
    );
    PZ.slope(
      CalendarioE.BOARD_U0 - .1,
      CalendarioE.colU(6) - .05,
      CalendarioE.BOARD_V + .2,
      CalendarioE.BOARD_Z1,
      CalendarioE.BOARD_V - .14,
      CalendarioE.BOARD_Z1 + .26,
      (u, bb) => b.shade(PlazaBase.TILE, bb > .5 ? 3.0 : 2.4, u * 3, bb),
    );
    final a0 = CalendarioE.colU(6) + .04;
    final a1 = CalendarioE.colU(8) - .04;
    final am = (a0 + a1) / 2;
    const A = CalendarioE.ARCH;
    const flagCols = [
      [236, 80, 90],
      [250, 206, 70],
      [86, 160, 150],
      [250, 250, 250],
      [110, 150, 220],
    ];
    PZ.wall(a0, a1, CalendarioE.BOARD_V, A.z, A.z + A.h + .06, (u, z) {
      final t = (u - a0) / (a1 - a0);
      final top =
          A.z + A.h * math.pow(math.sin(math.pi * e.clamp(t, 0.0, 1.0)), .6);
      if ((u - am).abs() < .03 && z < top - .07 && z > A.z + .6) {
        return rgb(70, 60, 60);
      }
      if (z > top || z < top - .4) return 0;
      if (z > top - .07) return rgb(FRAME[0], FRAME[1], FRAME[2]);
      final kk = (t * 5).floor(), ff = t * 5 - kk, d = (top - .07) - z;
      if (d < .32 && (ff - .5).abs() < .46 * (1 - d / .32)) {
        final c = flagCols[kk % 5];
        return rgb(c[0], c[1], c[2]);
      }
      return 0;
    });
    PZ.box(
      mid,
      (CalendarioE.STEP.v0 + CalendarioE.STEP.v1) / 2,
      0,
      CalendarioE.STEP.h,
      (CalendarioE.BOARD_U1 - CalendarioE.BOARD_U0) / 2 + .1,
      (CalendarioE.STEP.v1 - CalendarioE.STEP.v0) / 2,
      PlazaBase.STONE,
    );
    if (state.tela) {
      final u5 = CalendarioE.colU(5);
      PZ.wall(
        u5 - .02,
        CalendarioE.BOARD_U1 + .04,
        CalendarioE.BOARD_V + .04,
        CalendarioE.BOARD_Z0 - .25,
        CalendarioE.BOARD_Z1 + .04,
        (u, z) {
          final f = (u - u5) / (CalendarioE.BOARD_U1 - u5);
          final hem = CalendarioE.BOARD_Z0 - .25 + .12 * math.sin(f * 9).abs();
          if (z < hem) return 0;
          if (z > CalendarioE.BOARD_Z1 - .02) return rgb(120, 90, 60);
          if (z < hem + .07) return rgb(170, 60, 56);
          return ((f * 9).floor() % 2 != 0)
              ? (math.sin(f * 30 + z) > .8
                    ? rgb(190, 70, 64)
                    : rgb(214, 84, 76))
              : (math.sin(f * 30 + z) > .8
                    ? rgb(226, 216, 196)
                    : rgb(246, 238, 220));
        },
      );
    }
    for (num u = CalendarioE.BOARD_U0; u <= CalendarioE.BOARD_U1; u += .35) {
      PZ.shadow(u, CalendarioE.BOARD_V, 2.2, .4);
    }
  }

  void bandstand() {
    const K = CalendarioE.STAND, hw = 1.25, hd = .7;
    PZ.box(
      K.u,
      K.v,
      0,
      .7,
      hw,
      hd,
      PlazaBase.STONE,
      (s, t, z, face) => face == 'front' && s.abs() < .45
          ? (jsMod(z, .234) < .03
                ? rgb(
                    PlazaBase.STONE_D[0],
                    PlazaBase.STONE_D[1],
                    PlazaBase.STONE_D[2],
                  )
                : 0)
          : 0,
    );
    for (final d in const [
      [-hw + .1, hd - .1],
      [hw - .1, hd - .1],
      [-hw + .1, -hd + .1],
      [hw - .1, -hd + .1],
    ]) {
      PZ.post(K.u + d[0], K.v + d[1], .7, 2.1, .06, PlazaBase.WHITE);
    }
    PZ.slope(K.u - hw - .2, K.u + hw + .2, K.v + hd + .15, 2.1, K.v, 2.8, (
      u,
      bb,
    ) {
      final inset = bb * .42 * (2 * hw + .4);
      final d = u - (K.u - hw - .2);
      return (d < inset || d > 2 * hw + .4 - inset)
          ? 0
          : b.shade(PlazaBase.TILE, 2.8, u * 3, bb * 6);
    });
    PZ.ball(K.u, K.v, 2.9, .13, const [250, 206, 70], 'gloss');
    for (num du = -hw; du <= hw; du += .4) {
      PZ.shadow(K.u + du, K.v, 2.0, .6);
    }
  }

  /// Builds the baked set for [state] into [e].
  void buildSet(CalendarioState state) {
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
    PZ.NIGHT = PZ.CL.NIGHT = state.hora == 'noche';
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
        e.kinds[i] = uv[1] < CalendarioE.WALL - .1 ? e.KIND_GRASS : KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('fondo', () {
      for (final tr in const [
        [-4.4, 1.9, 1.15],
        [-1.2, 1.5, .95],
        [1.4, 1.7, 1.05],
      ]) {
        PZ.tree(tr[0], CalendarioE.WALL - .8, tr[1], tr[2]);
      }
      PZ.hedge(-5.4, CalendarioE.END + .25, 5.4, CalendarioE.END + .25);
    });
    k.part(
      'muro',
      () => PZ.box(0, CalendarioE.WALL, 0, .55, 5.4, .13, PlazaBase.STONE),
    );
    k.part('glorieta', bandstand);
    k.part('faroles', () {
      for (final l in CalendarioE.LAMPS) {
        PZ.lamp(l[0], l[1]);
      }
    });
    k.part('tablero', () => board(state));
    k.part(
      'banco',
      () => PZ.seatSide(
        CalendarioE.SEAT[0],
        CalendarioE.SEAT[1],
        CalendarioE.SEAT[2],
      ),
    );
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PZ.light(state.hora);
    if (state.hora == 'noche') {
      for (final l in CalendarioE.LAMPS) {
        final xy = PZ.xy(l[0], l[1] + .5);
        final p = e.project(xy[0], xy[1], 0);
        for (var iy = 0; iy < H; iy++) {
          for (var ix = 0; ix < W; ix++) {
            final i = iy * W + ix;
            if (e.ground[i] == 0 || e.zb[i] != e.groundZ[i]) continue;
            final d = jsHypot((ix - p.sx) / 30, (iy - p.sy) / 15);
            if (d >= 1) continue;
            final kk = (1 - d) * (e.bayerAt(ix, iy) < (1 - d) * 1.4 ? .55 : .3);
            final c = e.pix[i];
            e.pix[i] = rgb(
              e.lerp(c & 255, 255, kk * .7),
              e.lerp((c >> 8) & 255, 226, kk * .6),
              e.lerp((c >> 16) & 255, 150, kk * .3),
            );
          }
        }
      }
    }
    k.skyFill(PZ.sky(state.hora));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  /// calendario-set.html: `frame(t, casts = [])`.
  void frame([List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
