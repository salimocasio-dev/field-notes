// Port of docs/proyecto/pixel/reloj-set.html: El reloj's set (place 6, La plaza, scene 2: `reloj`), its
// states, call for call (order 59b). The square's pieces are La plaza's kit (lib/src/plaza/plaza_base.dart). The page's
// names are kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// reloj-set.html: ORIGIN.
const List<double> RELOJ_ORIGIN = [0, 44];

/// The engine El reloj's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, 44), shadows to (.9, -.1).
PpEngine relojEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: RELOJ_ORIGIN[0],
  originY: RELOJ_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (reloj-set.html: `SET`, from the address): `hora` mediodia, tarde or ocaso (the light),
/// `mesas` (the bingo: three round tables, the cage's stand, the prize table; story 65).
class RelojState {
  const RelojState({this.hora = 'mediodia', this.mesas = false});

  /// reloj-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory RelojState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return RelojState(
      hora: h != null && const ['mediodia', 'tarde', 'ocaso'].contains(h)
          ? h
          : 'mediodia',
      mesas: q['mesas'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-mesas", e.g. "mediodia-0") read back.
  factory RelojState.fromKey(String key) {
    final m = RegExp(r'^(mediodia|tarde|ocaso)-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of El reloj's set");
    }
    return RelojState(hora: m[1]!, mesas: m[2] == '1');
  }

  final String hora;
  final bool mesas;

  /// The sheet's key.
  String get key => '$hora-${mesas ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&mesas=${mesas ? 1 : 0}';
}

/// reloj-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class RelojE {
  static const ({double u0, double u1, double v}) TOWER = (
    u0: -1.9,
    u1: 1.9,
    v: -2.0,
  );
  static const ({double u, double z, double r}) FACE = (u: 0, z: 3.92, r: 27);
  static const ({double z, double out, double u0, double u1, double rail})
  BALCON = (z: 2.1, out: .55, u0: -1.75, u1: 1.75, rail: .5);
  static const ({double u, double v0}) LADDER = (u: -1.5, v0: -.95);
  static const ({double u0, double u1, double z0, double z1}) DOOR = (
    u0: 1.12,
    u1: 1.84,
    z0: 2.95,
    z1: 4.6,
  );
  static const ({double u0, double u1, double z0, double z1}) FLAP = (
    u0: -1.82,
    u1: -1.2,
    z0: 3.45,
    z1: 4.15,
  );
  static const ({double u, double v, double hw, double hd}) KIOSK = (
    u: 3.02,
    v: -.25,
    hw: .74,
    hd: .4,
  );
  static const double WALL = -2.7, BACK = -4.2;
  static const List<List<double>> TABLES = [
    [-2.75, 1.7],
    [-1.3, 3.1],
    [2.3, 3.3],
  ];
  static const List<double> CAGE = [1.25, 1.2], SHELF = [-.2, 1.25];
}

int _jsRound(double v) => (v + 0.5).floor();

/* a 3 x 5 figure font, for the clock's numerals */
const List<String> _DIG = [
  '111101101101111',
  '010110010010111',
  '111001111100111',
  '111001111001111',
  '101101111001001',
  '111100111001111',
  '111100111101111',
  '111001001001001',
  '111101111101111',
  '111101111001111',
];

final Set<String> _NUM = () {
  final m = <String>{};
  for (var n = 1; n <= 12; n++) {
    final th = n * math.pi / 6;
    const R = 20.5;
    final cx = _jsRound(math.sin(th) * R);
    final cy = _jsRound(math.cos(th) * R);
    final ds = [for (final c in '$n'.codeUnits) c - 48];
    final w = ds.length * 4 - 1;
    for (var k = 0; k < ds.length; k++) {
      final d = ds[k];
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 3; c++) {
          if (_DIG[d][r * 3 + c] == '1') {
            m.add('${cx - (w >> 1) + k * 4 + c},${cy + 2 - r}');
          }
        }
      }
    }
  }
  return m;
}();

const List<int> _WALLC = [244, 214, 150];
const List<int> _QUOIN = [226, 206, 176];
const List<int> _TRIM = [196, 104, 76];

/// reloj-set.html's buildSet on an engine [e] (made by [relojEngine]).
class RelojSet {
  RelojSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  /// Record which part drew each pixel at the next bakes (reloj-set.html `?tags=1`).
  bool tags = false;

  int rgb(num r, num g, num bb) => e.rgb(r, g, bb);

  // reloj-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final p = PZ.uv(x, y), u = p[0], v = p[1];
    if (v < RelojE.BACK) return 0;
    if (v < RelojE.WALL - .1) return PZ.grass(u, v, ix, iy);
    return PZ.paving(u, v, ix, iy);
  }

  // reloj-set.html: towerFront
  int towerFront(num u, num z) {
    const T = RelojE.TOWER, F = RelojE.FACE;
    final px = ((u - F.u) * 26).floor();
    final py = ((z - F.z) * 22.5).floor();
    final d = jsHypot(px + .5, py + .5);
    if (d < F.r) {
      if (d > F.r - 2) return rgb(96, 70, 56);
      if (d > F.r - 3) return rgb(190, 150, 90);
      if (d < 1.6) return rgb(70, 56, 50);
      if (_NUM.contains('$px,$py')) return rgb(60, 50, 60);
      return (d > F.r - 4.2 &&
              jsMod(math.atan2(px + .5, py + .5) / math.pi * 30 + 60.5, 1) <
                  .22)
          ? rgb(150, 130, 120)
          : rgb(252, 250, 240);
    }
    if (d < F.r + 2) return rgb(_TRIM[0], _TRIM[1], _TRIM[2]);
    const D = RelojE.DOOR;
    if (u > D.u0 - .06 && u < D.u1 + .06 && z > D.z0 - .06 && z < D.z1 + .06) {
      if (u < D.u0 || u > D.u1 || z < D.z0 || z > D.z1) return rgb(120, 76, 50);
      final kIdx = math.min(2, ((z - D.z0) / ((D.z1 - D.z0) / 3)).floor());
      final fu = (u - D.u0) / (D.u1 - D.u0);
      final fz = ((z - D.z0) / ((D.z1 - D.z0) / 3)) - kIdx;
      if (fz < .07 || fz > .93 || fu < .06 || fu > .94) return rgb(150, 98, 60);
      final x = fu - .5, y = fz - .5;
      if (kIdx == 2) {
        if (jsHypot(x - .14, y - .3) < .07 || jsHypot(x - .08, y - .36) < .05) {
          return rgb(226, 50, 50);
        }
        if (jsHypot(x * 1.0, (y + .08) * 1.2) < .2 ||
            jsHypot(x - .12, y - .16) < .12) {
          return rgb(250, 250, 244);
        }
        if (x > .22 && x < .36 && (y - .15).abs() < .05) {
          return rgb(250, 190, 60);
        }
        if (x < -.14 &&
            x > -.34 &&
            y > -.05 &&
            y < .3 &&
            (x + .34) > (y + .05) * .4) {
          return rgb(60, 110, 70);
        }
        if (x.abs() < .03 && y < -.24 && y > -.4) return rgb(250, 190, 60);
      }
      if (kIdx == 1) {
        if (jsHypot(x + .12, y - .22) < .1) return rgb(232, 180, 140);
        if ((x + .12).abs() < .1 && y > -.3 && y < .12) {
          return rgb(80, 110, 190);
        }
        if (jsHypot(x - .12, y + .08) < .15) return rgb(190, 130, 70);
        if (y > -.02 && y < .04 && x > .1 && x < .36) return rgb(120, 80, 50);
      }
      if (kIdx == 0) {
        if (jsHypot(x * .9, y * 1.3) < .22) return rgb(110, 180, 80);
        if (jsHypot(x + .1, y - .16) < .07 || jsHypot(x - .1, y - .16) < .07) {
          return rgb(250, 250, 240);
        }
      }
      return rgb(206, 160, 104);
    }
    const P = RelojE.FLAP;
    if (u > P.u0 && u < P.u1 && z > P.z0 && z < P.z1) {
      final edge =
          u < P.u0 + .05 || u > P.u1 - .05 || z < P.z0 + .05 || z > P.z1 - .05;
      final cu = (u - (P.u0 + P.u1) / 2) * 26;
      final cz = (z - (P.z0 + P.z1) / 2) * 22.5;
      final rr = jsHypot(cu, cz);
      final an = math.atan2(cz, cu);
      return edge
          ? rgb(52, 56, 68)
          : rr < 1.4
          ? rgb(84, 90, 104)
          : rr < 4.2 + (math.cos(an * 8) > 0 ? 1.4 : 0)
          ? rgb(226, 190, 96)
          : ((u - P.u0 - .1).abs() < .03 &&
                ((z - P.z0 - .15).abs() < .06 || (z - P.z1 + .15).abs() < .06))
          ? rgb(40, 42, 52)
          : rgb(84, 90, 104);
    }
    if (z < .62) return b.shade(PlazaBase.STONE_D, z > .56 ? 1.4 : 2.2, u, z);
    if (u.abs() < .5 && z < 1.62 && jsHypot(u, math.max(0.0, z - 1.12)) < .5) {
      return u.abs() < .03
          ? rgb(70, 46, 36)
          : b.shade(PlazaBase.WOOD_D, 2.0, u * 6, z);
    }
    if (u.abs() < .6 && z < 1.74 && jsHypot(u, math.max(0.0, z - 1.12)) < .6) {
      return rgb(_TRIM[0], _TRIM[1], _TRIM[2]);
    }
    if (u < T.u0 + .26 || u > T.u1 - .26) {
      final row = (z / .32).floor();
      final inn = (row % 2) != 0 ? .26 : .16;
      if (u < T.u0 + inn || u > T.u1 - inn) {
        return jsMod(z, .32) < .03
            ? rgb(190, 170, 144)
            : b.shade(_QUOIN, 2.4, u, z);
      }
    }
    if (z > 5.5 && z < 5.68) return rgb(_TRIM[0], _TRIM[1], _TRIM[2]);
    return b.shade(_WALLC, 2.4, u * 2, z * 2, .5);
  }

  // reloj-set.html: tower
  void tower() {
    const T = RelojE.TOWER, B = RelojE.BALCON;
    PZ.wall(T.u0, T.u1, T.v, 0, 9.2, towerFront);
    PZ.box(
      0,
      T.v + B.out / 2,
      B.z - .14,
      B.z,
      (B.u1 - B.u0) / 2,
      B.out / 2,
      PlazaBase.STONE,
    );
    for (final u in [B.u0 + .3, 0.0, B.u1 - .3]) {
      PZ.box(u, T.v + .14, B.z - .46, B.z - .14, .09, .14, PlazaBase.STONE_D);
    }
    PZ.wall(B.u0, B.u1, T.v + B.out, B.z, B.z + B.rail, (u, z) {
      if (u < RelojE.LADDER.u + .32) {
        return u > RelojE.LADDER.u + .26
            ? rgb(PlazaBase.IRON[0], PlazaBase.IRON[1], PlazaBase.IRON[2])
            : 0;
      }
      final kk = jsMod(u - B.u0, .22) / .22;
      return (z > B.z + B.rail - .07 || z < B.z + .05 || kk < .16)
          ? rgb(PlazaBase.IRON[0], PlazaBase.IRON[1], PlazaBase.IRON[2])
          : 0;
    });
    const L = RelojE.LADDER;
    final top = T.v + B.out;
    k.planeQuad(
      PZ.P(L.u - .26, L.v0, 0),
      [.52 / e.R2, -.52 / e.R2, 0],
      [(top - L.v0) / e.R2, (top - L.v0) / e.R2, B.z + .02],
      (a, bb) => (a < .12 || a > .88)
          ? rgb(150, 104, 62)
          : jsMod(bb * 9, 1) < .2
          ? rgb(176, 124, 76)
          : 0,
    );
    for (num z = .3; z <= B.z; z += .4) {
      PZ.shadow(L.u, L.v0 - z * .22, z, .16);
    }
    for (num u = T.u0; u <= T.u1; u += .4) {
      PZ.shadow(u, T.v + .2, 1.2, .5);
      PZ.shadow(u, T.v + .3, B.z, .4);
    }
  }

  // reloj-set.html: kiosk
  void kiosk() {
    const K = RelojE.KIOSK;
    const TEAL = [70, 150, 150];
    const WH = [250, 246, 236];
    PZ.box(K.u, K.v, 0, 1.0, K.hw, K.hd, WH, (s, t, z, face) {
      if (face == 'front') {
        return (z > .14 && z < .86 && s.abs() < K.hw - .1)
            ? b.shade(TEAL, 2.2, s * 4, z)
            : 0;
      }
      if (face == 'top') return b.shade(const [226, 214, 196], 3.4, s, t);
      return 0;
    });
    PZ.box(K.u - .34, K.v - .05, 1.0, 1.26, .2, .17, const [70, 70, 80], (
      s,
      t,
      z,
      face,
    ) {
      return face == 'top' && s.abs() < .15 && t.abs() < .12
          ? rgb(214, 160, 60)
          : 0;
    });
    for (final q in [
      [-K.hw + .05, -K.hd + .05],
      [K.hw - .05, -K.hd + .05],
      [-K.hw + .05, K.hd - .05],
      [K.hw - .05, K.hd - .05],
    ]) {
      PZ.post(K.u + q[0], K.v + q[1], 1.0, 3.44, .03, PlazaBase.IRON);
    }
    PZ.slope(
      K.u - K.hw - .12,
      K.u + K.hw + .12,
      K.v + K.hd + .14,
      3.4,
      K.v - K.hd - .1,
      3.66,
      (u, bb) {
        final c = (((u - K.u + 4) / .24).floor() % 2) != 0
            ? (bb > .5 ? const [90, 170, 168] : TEAL)
            : (bb > .5 ? WH : const [232, 228, 218]);
        return rgb(c[0], c[1], c[2]);
      },
    );
    PZ.wall(
      K.u - K.hw - .12,
      K.u + K.hw + .12,
      K.v + K.hd + .14,
      3.26,
      3.4,
      (u, z) => (((u - K.u + 4) / .24).floor() % 2) != 0
          ? rgb(56, 124, 126)
          : rgb(226, 222, 210),
    );
    for (num du = -K.hw; du <= K.hw; du += .3) {
      PZ.shadow(K.u + du, K.v, 1.6, .5);
    }
  }

  // reloj-set.html: table
  void table(num u, num v) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    k.drum(x, y, 0, .62, .07, PlazaBase.IRON);
    k.drum(x, y, .62, .72, .5, const [
      250,
      246,
      236,
    ], (a, bb) => jsHypot(a, bb) > .42 ? rgb(226, 90, 80) : 0);
    for (final du in const [-.5, .5]) {
      final sp = PZ.xy(u + du, v - .55), sx = sp[0], sy = sp[1];
      k.drum(sx, sy, 0, .4, .15, PlazaBase.WOOD);
      e.castShadow(sx, sy, .3, .2);
    }
    e.castShadow(x, y, .6, .55);
  }

  // reloj-set.html: bingo
  void bingo() {
    for (final t in RelojE.TABLES) {
      table(t[0], t[1]);
    }
    final cu = RelojE.CAGE[0], cv = RelojE.CAGE[1];
    PZ.box(cu, cv, 0, .8, .3, .22, PlazaBase.WOOD, (s, t, z, face) => 0);
    PZ.shadow(cu, cv, .6, .35);
    final su = RelojE.SHELF[0], sv = RelojE.SHELF[1];
    PZ.box(su, sv, 0, .7, .95, .2, const [250, 246, 236], (s, t, z, face) {
      if (face != 'front') return 0;
      if (z > .6) return rgb(226, 90, 80);
      return (((s + 4) / .2).floor() % 2) != 0 ? rgb(244, 236, 220) : 0;
    });
    for (num du = -.9; du <= .9; du += .3) {
      PZ.shadow(su + du, sv, .5, .3);
    }
  }

  // reloj-set.html: buildSet
  void buildSet(RelojState SET) {
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
        e.kinds[i] = v < RelojE.WALL - .1 ? e.KIND_GRASS : KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('fondo', () {
      for (final t in const [
        [-3.6, 2.2, 1.25],
        [3.5, 2.4, 1.3],
        [-5.2, 1.6, 1.0],
        [5.2, 1.6, 1.0],
      ]) {
        PZ.tree(t[0], RelojE.WALL - .8, t[1], t[2]);
      }
      PZ.hedge(-5.4, RelojE.BACK + .25, -2, RelojE.BACK + .25);
      PZ.hedge(2, RelojE.BACK + .25, 5.4, RelojE.BACK + .25);
    });
    k.part('muro', () {
      PZ.box(-3.7, RelojE.WALL, 0, .55, 1.8, .13, PlazaBase.STONE);
      PZ.box(3.7, RelojE.WALL, 0, .55, 1.8, .13, PlazaBase.STONE);
    });
    k.part('flores', () {
      PZ.bed(-4.6, RelojE.WALL + .3, -2.15, RelojE.WALL + .9);
      PZ.bed(2.15, RelojE.WALL + .3, 4.6, RelojE.WALL + .9, const [
        [250, 250, 250],
        [236, 120, 170],
        [250, 206, 70],
      ]);
    });
    k.part('torre', tower);
    k.part('quiosco', kiosk);
    if (SET.mesas) k.part('mesas', bingo);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PZ.light(SET.hora);
    k.skyFill(PZ.sky(SET.hora));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // reloj-set.html: frame (the bake at wind time t, no characters; the set has no wind)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
