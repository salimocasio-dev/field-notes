// Port of docs/proyecto/pixel/estufa-set.html: La estufa's set, both states, call for call (order 38a's set reference,
// order 38b's port), on the kitchen's kit (cocina_kit.dart). The page's names are kept, capitals included, so the port
// reads line for line against it (page 12, section 6): the lints on names are off in this file.
//
// Not ported: the page's `?sin=<part>` (it leaves one part out, for the maker's checks of what is behind it) and its
// `ox`, `oy` (the origin is the sheet's). `?tags=1` is the kit's `PART_TAGS` (the scene records them at a state's first
// bake).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cocina_kit.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine La estufa's set is built on (estufa-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (-102, -40), shadows to (.9, -.1): the kitchen's light.
PpEngine estufaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -102,
  originY: -40,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (estufa-set.html: `SET`, from the address): the stool there or not.
class EstufaState {
  const EstufaState({this.banco = true});

  /// estufa-set.html: `banco: Q.get('banco') !== '0'` (any other value, or none, is the stool there).
  factory EstufaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    return EstufaState(banco: q['banco'] != '0');
  }

  /// A key of the sheet's `setKey` table (`"banco1"`, `"banco0"`) read back.
  factory EstufaState.fromKey(String key) {
    if (key != 'banco1' && key != 'banco0') {
      throw ArgumentError.value(key, 'key', 'not a key of La estufa\'s set');
    }
    return EstufaState(banco: key == 'banco1');
  }

  /// W.banco: the stool in front of the stove.
  final bool banco;

  /// The sheet's key (`setKey.key`: `"banco" + (W.banco ? 1 : 0)`).
  String get key => banco ? 'banco1' : 'banco0';
}

/* ---------- the plan (world units; the kit's frame: the back wall on y = 0, the left wall on x = 0) ---------- */

const double D = 1.4; // the run's depth from the wall (the tops; the kit's K.CD is .9: see the header)
// the left counter from the corner to the stove, the stove, the right counter (runs off the picture)
const double AL0 = 0, AS0 = 5.19, AS1 = 7.96, AR1 = 12.4;
// the two burners: [a, d] of each middle, their radius (a pot's foot stands on each)
const List<List<double>> BURN = [
  [5.79, .95],
  [7.36, .45],
];
const double BR = .36;
// the kit's hole, reveal, backdrop and three frame boards (door: no sill of its own: estufa's sill is deeper)
const CocinaWin WIN = CocinaWin(
  name: 'ventana',
  face: 'y',
  a0: 8.1,
  a1: 10.6,
  z0: 1.95,
  z1: 3.1,
  view: 'patio',
  bars: 'none',
  door: true,
  horizon: 2.62,
);
// round 3: the recess .22 deep, the wall's own thickness (was .5): its left side no longer hides the first face. Round 2:
// the window sits in a deep recess (the wall's thickness seen on its far side and bottom); whoever looks in stands outside
// at y = OUTSIDE_Y
const double DEEP = .22, OUTSIDE_Y = -(DEEP + .35);

/// The shelf (estufa-set.html: `SHELF`).
abstract final class SHELF {
  static const double a0 = 1.05, a1 = 3.6, z = 2.55, d = .62;
}

// the old picture's two jars on the shelf (green, blue)
const List<(double, List<int>)> JARS = [
  (2.65, [72, 168, 72]),
  (3.15, [88, 180, 236]),
];

/// round 2: La nevera's stool (nevera-set.html stool(): h .72, r .32, legs .07 square, two cross rails, the seat
/// KC.woodL); its top's middle under the frog's feet (126, 184) (estufa-set.html: `STOOL`).
abstract final class STOOL {
  static const double sx = 126, sy = 184, h = .72, hw = .32, leg = .035;
}

// the splashback behind the stove: brushed steel, a light mid grey (white steam and dark smoke both stand out from it by
// 2.0 and more)
const List<int> SPLASH = [172, 176, 188];
// the hood's canopy, higher and shallower than the kit's (2.36, .62): the steam over the pots rises against the
// splashback, under it
const List<double> HOOD_Z = [2.8, 3.05];
const double HOOD_D = .45;
// the splashback reaches past the stove's left end: the steam over the left pot rises in front of it, not in front of the
// pale tiles
const List<double> SPLASH_A = [4.05, AS1];
// the hood's darker underside
const List<int> _HOOD_UNDER = [76, 76, 90];
// the jars' white lids
const List<int> _LID = [242, 242, 248];

// estufa-set.html: STOOL_C. The floor under the stool top's middle
List<double> estufaStoolC(PpEngine e) {
  final g = e.unproject(STOOL.sx, STOOL.sy + STOOL.h * e.COS * e.S);
  return [g.x, g.y];
}

/* ---------- what is under a screen point: the stool's top, a top of the run, the floor (for the sheet's places) ---------- */

// estufa-set.html: atZ. The world point at height z under a screen point
List<double> estufaAtZ(PpEngine e, num sx, num sy, num z) {
  final u = (sx - e.OX) / e.S,
      v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
  return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
}

/// What estufa-set.html's `surfaceAt` gives: which surface ([on]: `banco`, `izq`, `estufa`, `der`, `estante`, `suelo`,
/// `mueble` or `pared`) and its world point [w].
typedef EstufaSurface = ({String on, List<double> w});

// estufa-set.html: surfaceAt. [banco]: the state has the stool (SET.banco)
EstufaSurface estufaSurfaceAt(
  PpEngine e,
  num sx,
  num sy, {
  required bool banco,
}) {
  if (banco) {
    final s = estufaAtZ(e, sx, sy, STOOL.h), c = estufaStoolC(e);
    if ((s[0] - c[0]).abs() <= STOOL.hw && (s[1] - c[1]).abs() <= STOOL.hw) {
      return (on: 'banco', w: s);
    }
  }
  final t = estufaAtZ(e, sx, sy, K.CZ);
  if (t[1] >= 0 && t[1] <= D && t[0] >= AL0 && t[0] <= AR1) {
    return (
      on: t[0] < AS0
          ? 'izq'
          : t[0] <= AS1
          ? 'estufa'
          : 'der',
      w: t,
    );
  }
  final sl = estufaAtZ(e, sx, sy, SHELF.z);
  if (sl[1] >= 0 &&
      sl[1] <= SHELF.d &&
      sl[0] >= SHELF.a0 &&
      sl[0] <= SHELF.a1) {
    return (on: 'estante', w: sl);
  }
  final g = estufaAtZ(e, sx, sy, 0);
  if (g[0] >= 0 && g[1] > D) return (on: 'suelo', w: g);
  return (on: g[1] >= 0 ? 'mueble' : 'pared', w: g);
}

// estufa-set.html: topRow. The screen row of a top of the run at column sx and depth d from the wall
double estufaTopRow(PpEngine e, num sx, num d) {
  final a = d + (sx - e.OX) / e.S * e.R2;
  return e.project(a, d, K.CZ).sy;
}

/// The set of La estufa in one state, built into an engine (estufa-set.html, from "the plan" to `buildSet`).
class EstufaSet {
  EstufaSet(this.e, this.b, this.SET) : k = SetKit(e, b) {
    c = CocinaKit(k);
    STOOL_C = estufaStoolC(e);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CocinaKit c;

  // estufa-set.html: SET
  final EstufaState SET;

  // estufa-set.html: STOOL_C
  late final List<double> STOOL_C;

  int get W => e.W;
  int get H => e.H;
  double get CZ => K.CZ;

  // estufa-set.html: P (the page's `?sin=` is not ported: every part is drawn)
  void P(String name, void Function() fn) => k.part(name, fn);

  /* ---------- the stove: the kit's look (its colours, the hob, the knobs on the front panel, the oven door), as wide as two pots need ---------- */

  // estufa-set.html: stove
  void stove() {
    const a0 = AS0, a1 = AS1, d1 = D;
    final zt = CZ, panel0 = zt - .2, door1 = zt - .3;
    const St = KC.steel, door0 = .14, Wd = a1 - a0;
    c.kBox('y', a0, a1, 0, d1, 0, zt, (f, p, q, sh) {
      if (f == 'top') {
        for (final bd in BURN) {
          final dx = p - bd[0], dy = q - bd[1];
          final r = math.sqrt(dx * dx + dy * dy);
          if (r < BR * .4) return c.kRgb(KC.cap);
          if (r < BR) {
            return c.kRgb(
              r > BR - .05 || (r - BR * .7).abs() < .03 ? KC.cap : KC.burner,
            );
          }
        }
        return c.kRgb(
          p < a0 + .04 || p > a1 - .04 || q > d1 - .04 ? KC.steelD : KC.hob,
        );
      }
      if (f == 'end') {
        return c.kRgb(c.kLit(q > zt - .04 ? KC.steelD : St, sh));
      }
      if (q < .06) return c.kRgb(KC.burner);
      if (q > zt - .03) return c.kRgb(c.kLit(KC.steelD, sh));
      // the panel: a knob before each burner
      if (q > panel0) {
        for (final bd in BURN) {
          if ((p - bd[0]).abs() < .07 && (q - (panel0 + .1)).abs() < .055) {
            return c.kRgb(c.kLit(KC.red, sh));
          }
        }
        return c.kRgb(c.kLit(q < panel0 + .025 ? KC.steelD : St, sh));
      }
      final da = p - a0,
          inDoor = da > .12 && da < Wd - .12 && q > door0 && q < door1;
      if (!inDoor) return c.kRgb(c.kLit(St, sh));
      if (da < .16 || da > Wd - .16 || q < door0 + .03 || q > door1 - .03) {
        return c.kRgb(c.kLit(KC.steelD, sh));
      }
      if ((q - (door1 - .1)).abs() < .03 && da > .35 && da < Wd - .35) {
        return c.kRgb(c.kLit(KC.handle, sh));
      }
      if (da > .35 && da < Wd - .35 && q > door0 + .14 && q < door1 - .2) {
        return c.kRgb(c.kLit(KC.ovenGlass, sh));
      }
      return c.kRgb(c.kLit(St, sh));
    }, 'tf');
  }

  // estufa-set.html: splash. The splashback: a steel panel on the wall behind the stove, from its top to the hood
  void splash() => c.kSolid(
    'y',
    SPLASH_A[0],
    SPLASH_A[1],
    0,
    .03,
    CZ,
    HOOD_Z[0],
    SPLASH,
    'tf',
  );

  // estufa-set.html: hood. Round 2: the hood joined to the wall: its canopy's back on the wall's own line (y = 0) above
  // the splashback, its top lit, its front a step darker, the dark underside's lip along its foot (where the steam goes
  // in), its duct up to the wall's cut edge
  void hood() {
    const a0 = AS0 - .06, a1 = AS1 + .02, dd = HOOD_D, w = a1 - a0;
    final z0 = HOOD_Z[0], zl = z0 + .07, zt = z0 + .2;
    final H0 = e.rampOf(KC.hood), U = c.kRgb(_HOOD_UNDER);
    P(
      'campana.bajo',
      () => c.kBox('y', a0, a1, 0, dd, z0, zl, (f, p, q, sh) => U, 'fe'),
    );
    P(
      'campana',
      () => c.kBox(
        'y',
        a0,
        a1,
        0,
        dd,
        zl,
        zt,
        (f, p, q, sh) => H0[sh ? 1 : 2],
        'fe',
      ),
    );
    P(
      'campana.arriba',
      () => c.kBox('y', a0, a1, 0, dd, zl, zt, (f, p, q, sh) => H0[4], 't'),
    );
    P(
      'campana.tubo',
      () => c.kBox(
        'y',
        a0 + w * .2,
        a1 - w * .2,
        0,
        dd * .7,
        zt,
        K.WH,
        (f, p, q, sh) => f == 'top' ? H0[4] : H0[sh ? 1 : 3],
      ),
    );
  }

  // estufa-set.html: base. The kit's base cupboard with its top, as deep as this run (cocinaBase reads K.CD for its depth)
  CocinaBaseOut base(num a0, num a1, {int? doors, bool noEnd = false}) {
    final c0 = K.CD;
    K.CD = D;
    try {
      return c.cocinaBase('y', a0, a1, doors: doors, noEnd: noEnd);
    } finally {
      K.CD = c0;
    }
  }

  // estufa-set.html: shelf
  void shelf() {
    P(
      'estante',
      () => c.cocinaShelf('y', SHELF.a0, SHELF.a1, SHELF.z, depth: SHELF.d),
    );
    // round 2: two brackets under it, seen (the kit's own sit under the board, hidden by it)
    for (final a in [SHELF.a0 + .3, SHELF.a1 - .35]) {
      P(
        'estante.mensula',
        () => c.kSolid(
          'y',
          a - .05,
          a + .05,
          0,
          SHELF.d * .85,
          SHELF.z - .44,
          SHELF.z - .06,
          KC.woodD,
        ),
      );
    }
    // the old picture's two jars on it (green, blue), white lids, at its back
    for (final (a, col) in JARS) {
      P('estante', () {
        c.kSolid('y', a - .13, a + .13, .06, .25, SHELF.z, SHELF.z + .42, col);
        c.kSolid(
          'y',
          a - .13,
          a + .13,
          .06,
          .25,
          SHELF.z + .42,
          SHELF.z + .5,
          _LID,
        );
      });
    }
  }

  // estufa-set.html: stool. A square wooden seat on four legs, on the world's axes. It is drawn after the room is baked
  // (cocinaBuild), so the engine's ambient occlusion makes no ring round its thin legs. It casts no shadow: a contact
  // shadow at each foot read as four loose specks on the tiles
  void stool() {
    final cx = STOOL_C[0], cy = STOOL_C[1];
    const r = STOOL.hw, hh = STOOL.h;
    final zb = e.zb, before = Float32List.fromList(zb);
    P('banco.patas', () {
      for (final (ex, ey) in const [(-1, -1), (1, -1), (-1, 1), (1, 1)]) {
        c.kSolid(
          'y',
          cx + ex * (r - .07) - .035,
          cx + ex * (r - .07) + .035,
          cy + ey * (r - .07) - .035,
          cy + ey * (r - .07) + .035,
          0,
          hh - .06,
          KC.woodD,
          'fe',
        );
      }
      c.kSolid(
        'y',
        cx - r + .07,
        cx + r - .07,
        cy - .02,
        cy + .02,
        .22,
        .28,
        KC.woodD,
        'fe',
      );
      c.kSolid(
        'y',
        cx - .02,
        cx + .02,
        cy - r + .07,
        cy + r - .07,
        .22,
        .28,
        KC.woodD,
        'fe',
      );
    });
    P(
      'banco',
      () =>
          c.kSolid('y', cx - r, cx + r, cy - r, cy + r, hh - .06, hh, KC.woodL),
    );
    // its silhouette against the floor (shadeEdges' rule, for its own pixels only), as La nevera's; no shadow (no ring, no
    // specks on the floor)
    final b0 = e.project(cx - r, cy + r, 0),
        b1 = e.project(cx + r, cy - r, 0),
        b2 = e.project(cx - r, cy - r, hh),
        b3 = e.project(cx + r, cy + r, 0);
    final gz = e.groundZ;
    for (var iy = b2.sy.floor() - 1; iy <= b3.sy.ceil() + 1; iy++) {
      for (var ix = b0.sx.floor() - 1; ix <= b1.sx.ceil() + 1; ix++) {
        final i = iy * W + ix;
        if (zb[i] == before[i]) continue;
        final a = i - W, bb = i + W, cc = i - 1, ee = i + 1;
        if (zb[a] == gz[a] ||
            zb[bb] == gz[bb] ||
            zb[cc] == gz[cc] ||
            zb[ee] == gz[ee]) {
          e.tint(i, .68, .66, .76);
        }
      }
    }
  }

  // estufa-set.html: furnish
  void furnish() {
    P('izq', () => base(AL0, AS0, noEnd: true, doors: 6));
    P('estufa', stove);
    P('der', () => base(AS1, AR1, noEnd: true, doors: 6));
    P('salpicadero', splash);
    hood();
    shelf();
    windowDeep();
  }

  // estufa-set.html: windowDeep. Round 2: the window's deep recess, its sill and the sill's shadow on the wall. The left
  // jamb (x = a0, facing the room's +x) and the bottom (z = z0, facing up) of the recess run DEEP back from the wall's
  // face; the kit's backdrop (the patio's yard wall, the hedge, the sky) is K.OUTD behind its outer face. The sill stands
  // .3 out into the room at the opening's foot, a frame board under it, its shadow under that
  void windowDeep() {
    final a0 = WIN.a0, a1 = WIN.a1, z0 = WIN.z0, z1 = WIN.z1;
    final Pl = e.rampOf(KC.plaster),
        Sl = e.rampOf(KC.sill),
        Fr = e.rampOf(KC.frame);
    // (a hair in front of the kit's own reveal, which is the same faces .22 deep: these are drawn over it)
    P('ventana.hondo', () {
      k.planeQuad([a0 + .02, 0, z0], [0, -DEEP, 0], [
        0,
        0,
        z1 - z0,
      ], (_, _) => Pl[1]);
      k.planeQuad([a0, 0, z0 + .02], [a1 - a0, 0, 0], [
        0,
        -DEEP,
        0,
      ], (s, t) => t > .9 ? Pl[2] : Pl[3]);
    });
    P('ventana.alfeizar', () {
      c.kBox(
        'y',
        a0 - .14,
        a1 + .14,
        0,
        .3,
        z0 - .07,
        z0,
        (f, p, q, sh) => f == 'top' ? Sl[4] : Sl[sh ? 1 : 2],
      );
      c.kBox(
        'y',
        a0 - .1,
        a1 + .1,
        0,
        .05,
        z0 - .2,
        z0 - .07,
        (f, p, q, sh) => f == 'top' ? Fr[3] : Fr[sh ? 1 : 2],
      );
    });
    // the sill's shadow: the wall a little under the board, darker (the light from the upper left, the sill .3 out)
    final q0 = e.project(a0 - .04, 0, z0 - .2),
        q1 = e.project(a1 + .2, 0, z0 - .32);
    final zb = e.zb;
    for (var iy = q0.sy.floor() - 1; iy <= q1.sy.ceil() + 1; iy++) {
      for (var ix = q0.sx.floor() - 1; ix <= q1.sx.ceil() + 1; ix++) {
        final w = c.kWallPixel('y', 0, ix, iy), i = iy * W + ix;
        if (w.a < a0 - .04 ||
            w.a > a1 + .2 ||
            w.z < z0 - .32 ||
            w.z > z0 - .2 ||
            (zb[i] - w.d).abs() > 1e-4) {
          continue;
        }
        e.tint(i, .78, .76, .86);
      }
    }
  }

  // estufa-set.html: PLAN. The run stands against the back wall, its fronts lit: its shadow would fall to screen right,
  // along the wall, past its end off the picture. So it casts none here (a shadow on its lit side, in front of it, would
  // be a fringe). The floor dimmed on the shadow side only (the kit's, as La mesa's)
  late final CocinaPlan PLAN = CocinaPlan(
    XR: AR1 + 2,
    YL: 6,
    windows: const [WIN],
    band: {
      'y': [
        [0, SPLASH_A[0]],
        [SPLASH_A[1], AR1 + 2],
      ],
    },
    furnish: furnish,
    occlusion: 'shade',
  );

  // estufa-set.html: buildSet
  void buildSet() {
    c.cocinaCheckScene();
    c.cocinaBuild(PLAN);
    if (SET.banco) {
      stool();
      e.bakedPix.setAll(0, e.pix);
      e.bakedZ.setAll(0, e.zb);
    }
  }
}
