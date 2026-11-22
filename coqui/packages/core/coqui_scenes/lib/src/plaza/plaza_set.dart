// Port of docs/proyecto/pixel/plaza-set.html: El banco de la plaza's set (place 6, La plaza, scene 1: `plaza`), its
// states, call for call (order 58b). The square's pieces are La plaza's kit (lib/src/plaza/plaza_base.dart). The page's
// names are kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// plaza-set.html: ORIGIN.
const List<double> ORIGIN = [0, 10];

/// The engine La plaza's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, 10), shadows to (.9, -.1).
PpEngine plazaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (plaza-set.html: `SET`, from the address): `hora` manana, mediodia or tarde (the light),
/// `tablero` (the notice board), `carrito` (the piragüero's cart).
class PlazaState {
  const PlazaState({
    this.hora = 'manana',
    this.tablero = false,
    this.carrito = false,
  });

  /// plaza-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory PlazaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return PlazaState(
      hora: h != null && const ['manana', 'mediodia', 'tarde'].contains(h)
          ? h
          : 'manana',
      tablero: q['tablero'] == '1',
      carrito: q['carrito'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-tablero-carrito", e.g. "manana-0-0") read back.
  factory PlazaState.fromKey(String key) {
    final m = RegExp(r'^(manana|mediodia|tarde)-([01])-([01])$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La plaza's set");
    }
    return PlazaState(hora: m[1]!, tablero: m[2] == '1', carrito: m[3] == '1');
  }

  final String hora;
  final bool tablero, carrito;

  /// The sheet's key.
  String get key => '$hora-${tablero ? 1 : 0}-${carrito ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query =>
      '?hora=$hora&tablero=${tablero ? 1 : 0}&carrito=${carrito ? 1 : 0}';
}

/// plaza-set.html: E.BOARD, the notice board: a plane that faces the camera.
typedef PzBoard = ({double u0, double u1, double v, double z0, double z1});

/// plaza-set.html: E.CART, the piragüero's cart.
typedef PzCart = ({double u, double v, double hw, double hd});

/// plaza-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class E {
  /// The long seat: its middle, half its length.
  static const ({double u, double v, double hw}) SEAT = (u: .6, v: 0, hw: 2.0);

  /// The big tree behind it: u, v, the trunk's height, the crown's size.
  static const List<double> TREE = [.6, -2.3, 1.9, 1.45];

  /// The low wall's v; where the ground ends (sky beyond).
  static const double WALL = -3.3, BACK = -5.0;

  static const PzBoard BOARD = (
    u0: -3.72,
    u1: -1.42,
    v: -1.3,
    z0: 1.0,
    z1: 2.62,
  );
  static const PzCart CART = (u: 3.05, v: 3.5, hw: .66, hd: .42);

  /// The far tower's foot on the picture (px).
  static const List<int> TOWER = [206, 55];
}

/// plaza-set.html's buildSet on an engine [e] (made by [plazaEngine]).
class PlazaSet {
  PlazaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  /// Record which part drew each pixel at the next bakes (plaza-set.html `?tags=1`).
  bool tags = false;

  int rgb(num r, num g, num bb) => e.rgb(r, g, bb);

  // plaza-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final p = PZ.uv(x, y), u = p[0], v = p[1];
    if (v < E.BACK) return 0;
    if (v < E.WALL - .1) return PZ.grass(u, v, ix, iy);
    return PZ.paving(u, v, ix, iy);
  }

  /* the board's two pictures. u, v from 0 to 1 (v up) */

  // plaza-set.html: island
  int island(num u, num v) {
    if (v < .3) {
      return (jsMod(u * 9 + v * 3, 1) < .18 && v > .08 && v < .24)
          ? rgb(170, 214, 240)
          : rgb(70, 140, 214); // the sea
    }
    final hump =
        .3 +
        .34 *
            math.sin(math.pi * e.clamp<double>((u - .08) / .84, 0, 1)) *
            (u < .5 ? 1 : .8);
    if (v < hump) {
      return v > hump - .07
          ? rgb(120, 190, 96)
          : rgb(70, 150, 76); // the green island
    }
    if ((u - .68 - (v - .5) * .1).abs() < .025 && v < .82) {
      return rgb(140, 100, 66); // a palm's trunk
    }
    if (v > .7 &&
        jsHypot((u - .7) * 1.0, (v - .84) * 1.6) < .2 &&
        (jsMod(u * 20 + v * 9, 1)) < .7) {
      return rgb(60, 140, 70); // its leaves
    }
    if (jsHypot(u - .18, v - .84) < .09) return rgb(252, 220, 110); // the sun
    return rgb(176, 220, 250);
  }

  // plaza-set.html: city
  int city(num u, num v) {
    const T = [
      [.06, .2, .62],
      [.22, .36, .88],
      [.4, .56, .7],
      [.6, .74, .94],
      [.78, .94, .56],
    ];
    for (final t in T) {
      final a = t[0], bb = t[1], h = t[2];
      if (u >= a && u <= bb && v < h) {
        final wx = jsMod((u - a) / (bb - a) * 3, 1), wy = jsMod(v * 9, 1);
        return (wx > .3 && wx < .75 && wy > .3 && wy < .75 && v < h - .06)
            ? rgb(250, 232, 150)
            : (((u - a) / (bb - a) * 3).floor() + jsRoundN(a * 10)) % 2 != 0
            ? rgb(120, 130, 156)
            : rgb(140, 150, 176);
      }
    }
    return v < .08 ? rgb(96, 100, 116) : rgb(196, 210, 232);
  }

  // plaza-set.html: board
  void board() {
    final B = E.BOARD,
        W2 = PlazaBase.WOOD,
        Wd = e.rampOf(PlazaBase.WOOD_D),
        mid = (B.u0 + B.u1) / 2;
    for (final u in [B.u0 + .06, B.u1 - .06]) {
      PZ.post(u, B.v - .05, 0, B.z1 + .1, .06, PlazaBase.WOOD_D);
    }
    PZ.wall(B.u0, B.u1, B.v, B.z0, B.z1, (u, z) {
      final fu = u - B.u0,
          w = B.u1 - B.u0,
          half = fu < w / 2 ? 0 : 1,
          hu = (fu - half * w / 2) / (w / 2),
          fz = (z - B.z0) / (B.z1 - B.z0);
      if (fu < .05 || fu > w - .05 || fz < .04 || fz > .96) {
        return Wd[1]; // the frame
      }
      if ((fu - w / 2).abs() < .03) return Wd[2];
      if (fz > .5) {
        final pu = (hu - .08) / .84, pv = (fz - .55) / .38;
        if (pu >= 0 && pu <= 1 && pv >= 0 && pv <= 1) {
          return half != 0 ? city(pu, pv) : island(pu, pv);
        }
        return rgb(244, 234, 208);
      }
      if (fz > .36 && fz < .44) {
        final kk = hu * 5 - (hu * 5).floor();
        if (hu > .04 && hu < .96 && (kk - .5).abs() < .1) {
          return rgb(90, 70, 60); // five hooks
        }
      }
      return rgb(244, 234, 208); // cork: where the photos hang
    });
    // the ledge along its foot
    PZ.box(mid, B.v + .1, B.z0 - .08, B.z0, (B.u1 - B.u0) / 2 + .04, .1, W2);
    // a little roof
    PZ.slope(
      B.u0 - .12,
      B.u1 + .12,
      B.v + .22,
      B.z1 + .02,
      B.v - .12,
      B.z1 + .3,
      (u, bb) => b.shade(PlazaBase.TILE, bb > .5 ? 3.0 : 2.4, u, bb),
    );
    for (num u = B.u0; u <= B.u1; u += .3) {
      PZ.shadow(u, B.v, 1.6, .28);
    }
  }

  // plaza-set.html: cart
  void cart() {
    final K = E.CART;
    const RED = [214, 62, 54], WH = [250, 246, 236];
    PZ.box(K.u, K.v, .42, 1.02, K.hw, K.hd, WH, (s, t, z, face) {
      if (face == 'top') {
        // the block of ice under its lid of glass
        return (s.abs() < K.hw - .1 && t.abs() < K.hd - .08)
            ? rgb(206, 232, 244)
            : 0;
      }
      if (face == 'front') {
        // painted on its side: a big piragua of three colours
        final d = jsHypot(s * 1.0, (z - .74) * 1.2);
        if (z > .52 && z < .7 && s.abs() < (z - .5) * .5 + .02) {
          return rgb(244, 234, 200); // the paper cone
        }
        if (z >= .7 && d < .2) {
          return s < -.06
              ? rgb(226, 60, 70)
              : s > .06
              ? rgb(80, 130, 220)
              : rgb(250, 206, 70);
        }
        return (z < .5 || z > .96) ? rgb(RED[0], RED[1], RED[2]) : 0;
      }
      return 0;
    });
    // two big wheels
    for (final du in [-K.hw + .12, K.hw - .12]) {
      final p = PZ.xy(K.u + du, K.v + K.hd + .02), x = p[0], y = p[1];
      for (num a = -.3; a <= .3; a += .02) {
        for (num bb = -.3; bb <= .3; bb += .02) {
          final r = jsHypot(a, bb);
          if (r < .3) {
            e.plot(
              x + a / e.R2,
              y - a / e.R2,
              .3 + bb,
              r < .06
                  ? rgb(60, 60, 66)
                  : r > .24
                  ? rgb(70, 60, 56)
                  : (a.abs() < .03 || bb.abs() < .03)
                  ? rgb(150, 110, 70)
                  : rgb(196, 150, 96),
            );
          }
        }
      }
    }
    for (final q in [
      [-K.hw + .05, -K.hd + .05],
      [K.hw - .05, -K.hd + .05],
      [-K.hw + .05, K.hd - .05],
      [K.hw - .05, K.hd - .05],
    ]) {
      PZ.post(K.u + q[0], K.v + q[1], 1.02, 3.48, .03, PlazaBase.IRON);
    }
    // a striped awning
    PZ.slope(
      K.u - K.hw - .12,
      K.u + K.hw + .12,
      K.v + K.hd + .14,
      3.45,
      K.v - K.hd - .1,
      3.7,
      (u, bb) {
        final c = (((u - K.u + 4) / .24).floor() % 2) != 0
            ? (bb > .5 ? const [236, 84, 74] : RED)
            : (bb > .5 ? WH : const [232, 228, 218]);
        return rgb(c[0], c[1], c[2]);
      },
    );
    PZ.wall(
      K.u - K.hw - .12,
      K.u + K.hw + .12,
      K.v + K.hd + .14,
      3.3,
      3.45,
      (u, z) => (((u - K.u + 4) / .24).floor() % 2) != 0
          ? rgb(190, 50, 46)
          : rgb(226, 222, 210),
    );
    // bottles of syrup along the back
    for (final (du, c) in const [
      (-.4, [226, 60, 70]),
      (-.13, [250, 206, 70]),
      (.14, [80, 130, 220]),
      (.4, [110, 190, 90]),
    ]) {
      PZ.box(K.u + du, K.v - K.hd + .1, 1.02, 1.36, .07, .07, c);
    }
    for (num du = -K.hw; du <= K.hw; du += .3) {
      PZ.shadow(K.u + du, K.v, .7, .5);
    }
  }

  // plaza-set.html: buildSet
  void buildSet(PlazaState SET) {
    k.PART_TAGS = tags ? List<String?>.filled(e.W * e.H, null) : null;
    k.PART_LEAVES.clear();
    final W = e.W, H = e.H;
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
    e.glints.clear();
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        final v = PZ.uv(g.x, g.y)[1];
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = v < E.WALL - .1 ? e.KIND_GRASS : KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    // behind the low wall: small trees against the sky
    k.part('fondo', () {
      for (final t in const [
        [-3.9, 1.5, .95],
        [-1.9, 1.2, .8],
        [4.7, 1.4, .9],
      ]) {
        PZ.tree(t[0], E.WALL - .9, t[1], t[2]);
      }
      PZ.hedge(-5, E.BACK + .25, 5, E.BACK + .25);
    });
    k.part('muro', () => PZ.box(0, E.WALL, 0, .55, 5.4, .13, PlazaBase.STONE));
    k.part('flores', () {
      PZ.bed(-1.2, E.WALL + .35, -.1, E.WALL + 1.0);
      PZ.bed(2.4, E.WALL + .35, 4.6, E.WALL + 1.0, const [
        [250, 250, 250],
        [236, 120, 170],
        [250, 206, 70],
      ]);
    });
    k.part('arbol', () => PZ.tree(E.TREE[0], E.TREE[1], E.TREE[2], E.TREE[3]));
    k.part('farol', () => PZ.lamp(-3.95, E.WALL + .7));
    k.part('banco', () => PZ.seat(E.SEAT.u, E.SEAT.v, E.SEAT.hw));
    if (SET.tablero) k.part('tablero', board);
    if (SET.carrito) k.part('carrito', cart);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PZ.light(SET.hora);
    k.skyFill(PZ.sky(SET.hora, [PZ.farTower(E.TOWER[0], E.TOWER[1])]));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // plaza-set.html: frame (what the reference made: the bake at wind time t, no characters; the set has no wind)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
