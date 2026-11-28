// Port of docs/proyecto/pixel/pedido-set.html: El pedido's set (place 8, La fonda, scene 2: `pedido`), call for call
// (order 67). Built on La fonda's kit (lib/src/fonda/fonda_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// pedido-set.html: ORIGIN.
const List<double> PEDIDO_ORIGIN = [0, -42];

/// The engine El pedido's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -42), shadows to (.9, -.1).
PpEngine pedidoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: PEDIDO_ORIGIN[0],
  originY: PEDIDO_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (pedido-set.html: `SET`, from the address): `hora` = noche (the lamps are lit).
class PedidoState {
  const PedidoState({this.hora = 'noche'});

  /// pedido-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory PedidoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return PedidoState(
      hora: h != null && const ['noche'].contains(h) ? h : 'noche',
    );
  }

  /// A key of the sheet's `setKey` ("noche") read back.
  factory PedidoState.fromKey(String key) {
    if (key != 'noche') {
      throw ArgumentError.value(key, 'key', "not a key of El pedido's set");
    }
    return PedidoState(hora: key);
  }

  final String hora;

  /// The sheet's key.
  String get key => hora;

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora';
}

/// pedido-set.html: E, the set's places (the sheet reads them: boards, panels, hatch, shelf, bell, hook, stool, tables).
abstract final class PedidoE {
  static const double WALL = 3.1;
  static const List<List<double>> BOARDS = [
    [-3.7, -2.42, 1.15, 2.6],
    [-2.28, -1.0, 1.15, 2.6],
  ];
  static const List<double> HATCH = [-.85, 2.95, 1.0, 2.62];
  static const ({double z, double v1}) SHELF = (z: 1.0, v1: .5);
  static const List<double> BELL = [.5, .25];
  static const List<double> HOOK = [3.36, 2.2];
  static const List<double> STOOL = [2.55, 1.25];
  static const double KITCHEN = -1.5;
  static const ({double u, double v, double hw, double hd}) TABLE = (
    u: .2,
    v: 5.0,
    hw: 1.9,
    hd: .6,
  );
  static const ({double u, double v, double hw}) NEXT = (
    u: 2.75,
    v: 9.3,
    hw: .95,
  );
  static const ({double u, double v, double hw}) FAR = (
    u: -3.0,
    v: 10.3,
    hw: .95,
  );
  static const double HEAD = .26;

  // pedido-set.html: panels
  static List<List<double>> _panels(List<double> r) {
    final w = (r[1] - r[0] - .3) / 2;
    final h = (r[3] - r[2] - HEAD - .3) / 2;
    final out = <List<double>>[];
    for (var j = 1; j >= 0; j--) {
      for (var i = 0; i < 2; i++) {
        out.add([
          r[0] + .1 + i * (w + .1),
          r[0] + .1 + i * (w + .1) + w,
          r[2] + .1 + j * (h + .1),
          r[2] + .1 + j * (h + .1) + h,
        ]);
      }
    }
    return out;
  }

  /// pedido-set.html: `E.PANELS`, cuadro1 to cuadro4 of each board (top left, top right, bottom left, bottom right).
  static final List<List<List<double>>> PANELS = [
    for (final b in BOARDS) _panels(b),
  ];
}

/// Port of pedido-set.html: builds the baked set into [e].
class PedidoSet {
  PedidoSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FD = FondaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FondaBase FD;

  /// pedido-set.html: `E.SEATS`, the family table's four chair places set by [tables].
  List<List<double>> seats = const [];

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);
  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // pedido-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    return uv[1] < -.02 ? rgb(150, 150, 156) : FD.tiles(uv[0], uv[1], ix, iy);
  }

  // pedido-set.html: backWall
  void backWall() {
    const Hh = PedidoE.HATCH;
    // the kitchen: white tiles, a rail of pans, a shelf of pots
    PZ.wall(-1.6, 3.6, PedidoE.KITCHEN, 0, 3.2, (u, z) {
      if (z < .95) {
        return (z > .86)
            ? rgb(70, 70, 80)
            : (jsMod(u + 9, .9) < .04)
            ? rgb(120, 122, 130)
            : rgb(168, 170, 178);
      }
      if (z > 1.5 && z < 1.55) return rgb(90, 90, 100);
      for (final (pu, r, col) in const [
        (-.2, 4.2, [60, 60, 70]),
        (.6, 3.4, [176, 96, 60]),
        (1.9, 4.6, [70, 70, 80]),
        (2.55, 3.2, [176, 96, 60]),
      ]) {
        final d = jsHypot((u - pu) * 26, (z - 1.28) * 22.5);
        if (d < r) {
          return d > r - 1.2
              ? rgb(col[0] - 24, col[1] - 24, col[2] - 24)
              : rgb(col[0], col[1], col[2]);
        }
        if ((u - pu).abs() < .03 && z > 1.32 && z < 1.5) {
          return rgb(60, 60, 70);
        }
      }
      return (jsMod(u + 9, .32) < .03 || jsMod(z, .3) < .035)
          ? rgb(206, 208, 214)
          : rgb(240, 240, 236);
    });
    PZ.wall(-5, 5, 0, 0, PedidoE.WALL, (u, z) {
      if (FD.inside(u, z, Hh)) return 0;
      if (FD.onFrame(u, z, Hh, .08)) return _rgb(FondaBase.WOOD);
      for (var kk = 0; kk < 2; kk++) {
        final B = PedidoE.BOARDS[kk];
        if (FD.onFrame(u, z, B, .06)) return _rgb(FondaBase.WOOD_L);
        if (FD.inside(u, z, B)) {
          final slate = kk != 0 ? const [44, 60, 84] : const [40, 72, 64];
          final mid = (B[0] + B[1]) / 2;
          final px = (u - mid) * 26;
          final pz = (z - (B[3] - PedidoE.HEAD / 2 - .02)) * 22.5;
          final chalk = rgb(236, 236, 226);
          if (z > B[3] - PedidoE.HEAD) {
            if (kk == 0) {
              if (((px + 3).abs() < .7 && pz.abs() < 2.4) ||
                  ((px + 3).abs() < 1.7 &&
                      pz > .6 &&
                      pz < 2.4 &&
                      (px + 3 + 0.5).floor() != 0) ||
                  ((px - 3).abs() < .7 && pz.abs() < 2.4) ||
                  (px > 2.4 && px < 4.4 && pz > 0 && pz < 2.4)) {
                return chalk;
              }
            } else {
              if ((px.abs() < 2.2 &&
                      pz > -.4 &&
                      pz < 2.4 &&
                      (px.abs() > 1.3 || pz < .4)) ||
                  (px.abs() < .6 && pz < -.4 && pz > -1.8) ||
                  (px.abs() < 1.8 && pz < -1.8 && pz > -2.6)) {
                return chalk;
              }
            }
            return _rgb(slate);
          }
          for (final p in PedidoE.PANELS[kk]) {
            if (FD.inside(u, z, p)) {
              return rgb(slate[0] + 26, slate[1] + 26, slate[2] + 26);
            }
            if (FD.onFrame(u, z, p, .035)) return chalk;
          }
          return _rgb(slate);
        }
      }
      const hk = PedidoE.HOOK;
      if ((u - hk[0]).abs() < .03 && z > hk[1] - .02 && z < hk[1] + .2) {
        return rgb(60, 60, 70);
      }
      return FD.paint(u, z);
    });
    final mid = (Hh[0] + Hh[1]) / 2, hw = (Hh[1] - Hh[0]) / 2 + .12;
    PZ.box(
      mid,
      PedidoE.SHELF.v1 / 2,
      PedidoE.SHELF.z - .08,
      PedidoE.SHELF.z,
      hw,
      PedidoE.SHELF.v1 / 2,
      FondaBase.WOOD_L,
      (s, t, z, face) => face == 'top'
          ? b.shade(FondaBase.WOOD_L, 3.3, s, t, .15)
          : _rgb(FondaBase.WOOD),
    );
    // shelf brackets
    for (final du in [-hw + .15, hw - .15]) {
      PZ.box(
        mid + du,
        PedidoE.SHELF.v1 * .45,
        PedidoE.SHELF.z - .4,
        PedidoE.SHELF.z - .08,
        .04,
        PedidoE.SHELF.v1 * .4,
        FondaBase.WOOD,
      );
    }
    final bp = PZ.xy(PedidoE.BELL[0], PedidoE.BELL[1]);
    final bx = bp[0], by = bp[1];
    e.sphere(bx, by, PedidoE.SHELF.z + .06, .1, FondaBase.BRASS, 'gloss');
    k.drum(
      bx,
      by,
      PedidoE.SHELF.z + .14,
      PedidoE.SHELF.z + .19,
      .025,
      FondaBase.BRASS,
    );
    PZ.box(
      PedidoE.HOOK[0],
      .08,
      PedidoE.HOOK[1] - .04,
      PedidoE.HOOK[1],
      .03,
      .08,
      const [60, 60, 70],
    );
    final sp = PZ.xy(PedidoE.STOOL[0], PedidoE.STOOL[1]);
    final sx = sp[0], sy = sp[1];
    k.drum(sx, sy, .3, .38, .24, FondaBase.WOOD_L);
    for (final (aa, bb) in const [(-.15, -.1), (.15, -.1), (0.0, .16)]) {
      PZ.post(
        PedidoE.STOOL[0] + aa,
        PedidoE.STOOL[1] + bb,
        0,
        .3,
        .03,
        FondaBase.WOOD,
      );
    }
    e.castShadow(sx, sy, .3, .28);
  }

  // pedido-set.html: tables
  void tables() {
    const T = PedidoE.TABLE;
    seats = FD.setTable(T.u, T.v, T.hw, seats: 4, span: 2.85, hd: T.hd);
    FD.setTable(
      PedidoE.NEXT.u,
      PedidoE.NEXT.v,
      PedidoE.NEXT.hw,
      seats: 2,
      span: .94,
      cloth: const [236, 214, 150],
    );
    FD.setTable(
      PedidoE.FAR.u,
      PedidoE.FAR.v,
      PedidoE.FAR.hw,
      seats: 2,
      span: .9,
      cloth: const [200, 222, 214],
    );
  }

  // pedido-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(PedidoState state) {
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
    k.part('mesas', tables);
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

  // pedido-set.html: frame
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
