// Port of docs/proyecto/pixel/comer-set.html: A comer's set, its one state, call for call (order 40a's set reference,
// order 40b's port), on the kitchen's kit (cocina_kit.dart). It is La mesa's room (mesa_set.dart) seen closer: the same
// corner, doorway with its leaf, counter (shorter at the door end), window, stove and hood, with A comer's own sink and
// tap, the long table with its gingham cloth hanging over the near side and the ends, its four legs and the four chairs.
// The page's names are kept, capitals included, so the port reads line for line against it (page 12, section 6): the
// lints on names are off in this file.
//
// Not ported: the page's `?noshade=1`, `?empty=1` and `?sin=` (pictures for the maker's checks, not states) and its `ox`,
// `oy` (the origin is the sheet's). `?tags=1` is the kit's `PART_TAGS` (the scene records them at the state's first
// bake), with the page's own tag of the door's reveal (`puerta.jamba`).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cocina_kit.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine A comer's set is built on (comer-set.html: `window.PP_SCENE`, with the page's default origin, which is the
/// sheet's): 240 × 216, S 26, origin (-10, -43), shadows to (.9, -.1): the kitchen's light.
PpEngine comerEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -10,
  originY: -43,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The one state of the set (comer-set.html: "one baked state: A comer's background never changes; the things on the
/// table are the sprite layer's"). Its key is the sheet's `setKey.key`, `"comer"`.
class ComerState {
  const ComerState();

  /// The page's address (`?`): it has no state parameter.
  factory ComerState.fromQuery(String query) => const ComerState();

  /// The sheet's key read back: `"comer"` only.
  factory ComerState.fromKey(String key) {
    if (key != KEY) {
      throw ArgumentError.value(key, 'key', 'not a key of A comer\'s set');
    }
    return const ComerState();
  }

  /// The sheet's key (`setKey.key`: `"comer"`).
  static const String KEY = 'comer';

  String get key => KEY;

  /// The query of the page for this state (none).
  String get query => '';
}

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// comer-set.html: r3
double r3(num v) => _round(v * 1000) / 1000;

/// A table (comer-set.html: `TBL`): x0..x1, y0..y1 on the floor, its top at z, its top's thickness th.
typedef ComerTable = ({
  double x0,
  double x1,
  double y0,
  double y1,
  double z,
  double th,
});

/// A chair (comer-set.html: an entry of `CHAIRS`): its seat's middle.
typedef ComerChair = ({double x, double y});

/// What comer-set.html's `surfaceAt` gives: which surface ([on]: `mesa`, `mostrador`, `mostrador2`, `estufa`, `floor` or
/// `wall`), its height [z] and world point ([x], [y]); on the floor, what stands over it ([under]: `mesa`, `mostrador`,
/// `mostrador2`, `estufa`, `silla0` .. `silla3`, or null: clear floor).
typedef ComerSurface = ({
  String on,
  double z,
  double x,
  double y,
  String? under,
});

/// The plan of A comer's set (comer-set.html, from "La mesa's room" to `STOVE`): every number and place, world units,
/// the same for every engine with the set's settings.
class ComerPlan {
  ComerPlan(this.e) {
    LAPS = [
      for (final l in const [
        [2.421, 3.509],
        [3.726, 3.509],
        [5.032, 3.509],
        [6.337, 3.509],
      ])
        [r3(l[0] + DS), r3(l[1] + DS)],
    ];
    CHAIRS = [for (final l in LAPS) (x: l[0], y: r3(l[1] - .2))];
    LEAF = (
      hx: .05,
      hy: r3(DOOR.a0 - .12),
      len: r3(DOOR.a1 - DOOR.a0),
      ang: -1.0,
    );
    TBL = (
      x0: r3(1.6 + DS),
      x1: r3(8.5 + DS),
      y0: r3(3.672 + DS),
      y1: r3(6.85 + DS),
      z: ZT,
      th: .07,
    );
    LEGS = [
      [TBL.x0 + .2, TBL.y0 + .15],
      [TBL.x1 - .28, TBL.y0 + .15],
      [TBL.x0 + .2, TBL.y1 - .23],
      [TBL.x1 - .28, TBL.y1 - .23],
    ];
    FOOT = {
      'mesa': [TBL.x0, TBL.y0, TBL.x1, TBL.y1],
      'mostrador': [0, A0, K.CD, A1],
      'mostrador2': [STX + K.STW, 0, XR, K.CD],
      'estufa': [STX, 0, STX + K.STW, K.SD],
    };
  }

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  // comer-set.html: Gs. The world point at height z under a screen point
  List<double> Gs(num sx, num sy, [num z = 0]) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
  }

  // comer-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  /* ---------- La mesa's room (mesa-set.html at 4033fc0) ---------- */

  static const double XR = 9, YL = 9;

  // the table and its chairs stand DS nearer on both world axes than La mesa's (4 rows lower on the picture, straight
  // down): the seated faces clear the hint hand under the answer cards on the wall above them (the cards stand right of
  // the rounds card, their glow 4 px inside the view, the hand reaching 54 rows down from 16 rows over the cards' foot)
  static const double DS = .2176;

  // La mesa's four seats (a sitter's lap), DS nearer
  late final List<List<double>> LAPS;

  // the chairs' seat and the table's top
  static const double ZS = .6, ZT = 1.0;

  static const double CH_hw = .25, CH_hd = .22, CH_back = .36, CH_ZB = 1.45;

  late final List<ComerChair> CHAIRS;

  // the counter along the left wall: La mesa's runs from y 2.858, .24 from the doorway's jamb, and its end (.9 deep,
  // 1.3 high) then stands in front of the doorway's lower part on the picture (it hides every wall point within .9 of
  // it): here it starts .9 + .1 past the jamb, so the opening, its threshold and whoever comes in through it are seen
  // whole (round 2); the wall cupboard over it starts with it
  static const double A0 = 3.62, A1 = YL;
  static const List<double> UP = [A0, 5.4];

  // the stove on the back wall
  static const double STX = 4.776;

  static const CocinaWin WIN = CocinaWin(
    face: 'y',
    a0: 2.7,
    a1: 3.85,
    z0: 1.95,
    z1: 2.85,
    view: 'arbusto',
    name: 'ventana',
    bushA: -1.5,
    bushR: .5,
  );

  // (round 2) La mesa's final doorway (main 64aa5f1, mesa-set.html: "a door, not a picture of one"): 2.75 high, its
  // leaf open into the room and back towards the corner with its brass handle, a wooden threshold across the wall's
  // thickness, El patio's stone step and the lawn outside
  static const CocinaWin DOOR = CocinaWin(
    face: 'x',
    a0: 1.6,
    a1: 2.62,
    z0: 0,
    z1: 2.75,
    view: 'patio',
    door: true,
    name: 'puerta',
    horizon: 2.5,
  );

  late final ({double hx, double hy, double len, double ang}) LEAF;

  static const double STEP_D = .42;

  static const Map<String, List<List<double>>> BAND = {
    'x': [
      [A0 - .2, YL],
    ],
    'y': [
      [STX - .18, XR],
    ],
  };

  // A comer's own: the sink set into the counter's top (the old picture's, at the counter's right end) and its tap on
  // the tile band; at the counter's end (round 2: the counter starts further in), whole in the view
  static final ({double a0, double a1, double d0, double d1}) SINK = (
    a0: r3(A0 + .04),
    a1: r3(A0 + .64),
    d0: .2,
    d1: .68,
  );

  /* ---------- the table (La mesa's, larger) ---------- */

  // far edge: La mesa's (y 3.672) + DS; left end: .7 from the counter's front (the passage); right end and near edge:
  // the old places on the cloth
  late final ComerTable TBL;

  // La mesa's wood: the top, the legs, the chairs
  static const List<int> TW = [214, 168, 112],
      TWD = [104, 68, 36],
      CHW = [110, 66, 32];

  // (round 2) the cloth: blue-and-white gingham in small checks. The old cloth's red and white on this floor
  // (terracotta and cream tiles) is a red-and-cream pattern of nearly the floor's own colour (dE 18 between their means):
  // blue reads as a cloth at once (dE 40 and more), and a gingham's three tones (white, a light blue where one stripe
  // runs, a blue where two cross) stand behind a white thing and a dark outline alike. The checks .125 (a period of .25: a
  // quarter of the floor's 1.0). It hangs .32 over the near side and the ends (7 rows), its face a tone darker than the
  // top on the near side and two on the right end, with a hem of the blue at its foot
  static const List<int> CL_white = [250, 250, 246],
      CL_light = [176, 198, 232],
      CL_blue = [78, 116, 192],
      CL_hem = [52, 80, 150];

  // the checks' size; how far the cloth hangs over the near side and the ends
  static const double CHECK = .125, DROP = .32;

  late final List<List<double>> LEGS;

  /* ---------- the door ---------- */

  // El patio's step (mapa.js C.stone)
  static const List<int> STONE = [216, 206, 184];

  /* ---------- what is under a screen point (the sheet's places) ---------- */

  late final Map<String, List<double>> FOOT;

  // comer-set.html: STOVE
  ({double x0, double x1, double y0, double y1, double z}) get STOVE =>
      (x0: STX, x1: STX + K.STW, y0: 0, y1: K.SD, z: K.CZ);

  // comer-set.html: inR
  static bool inR(num x, num y, List<num> r, [num m = 0]) =>
      x >= r[0] - m && x <= r[2] + m && y >= r[1] - m && y <= r[3] + m;

  // comer-set.html: surfaceAt
  ComerSurface surfaceAt(num sx, num sy) {
    for (final (on, z) in [
      ('mesa', ZT),
      ('mostrador', K.CZ),
      ('mostrador2', K.CZ),
      ('estufa', K.CZ),
    ]) {
      final g = Gs(sx, sy, z);
      if (inR(g[0], g[1], FOOT[on]!)) {
        return (on: on, z: z, x: g[0], y: g[1], under: null);
      }
    }
    final g = Gs(sx, sy, 0);
    String? under;
    for (final en in FOOT.entries) {
      if (inR(g[0], g[1], en.value)) {
        under = en.key;
        break;
      }
    }
    if (under == null) {
      for (var k = 0; k < CHAIRS.length; k++) {
        final c = CHAIRS[k];
        if (inR(g[0], g[1], [
          c.x - CH_hw,
          c.y - CH_hd,
          c.x + CH_hw,
          c.y + CH_hd,
        ])) {
          under = 'silla$k';
          break;
        }
      }
    }
    return (
      on: g[0] < 0 || g[1] < 0 ? 'wall' : 'floor',
      z: 0,
      x: g[0],
      y: g[1],
      under: under,
    );
  }

  // comer-set.html: COMER_SET.burners
  List<List<double>> get burners => [
    for (final p in [
      [STX + K.STW * .29, K.SD * .5],
      [STX + K.STW * .71, K.SD * .5],
    ])
      [p[0], p[1], K.CZ],
  ];
}

/// What the outside seen through the doorway is, per engine (comer-set.html: `PATIO_PX`, filled when the floor is laid,
/// which the kit does once per engine, as the page once per page: kept as long as that floor).
// DECISION(order 40b): the page empties PATIO_PX at each buildSet, but it builds once a page, and the floor is laid
// once a page: here the floor is laid once per engine, so the list is kept with it (as mesa_set.dart's), else a second
// bake on one engine would not put the patio back
final Expando<List<int>> _patioPx = Expando<List<int>>();

/// SetKit with comer-set.html's own wrapper of `revealX`: while the part tags are recorded (`?tags=1`), the pixels the
/// door's reveal draws (the wall's thickness seen in the opening) are kept, to be tagged `puerta.jamba` (`tagReveal`).
class _ComerKit extends SetKit {
  _ComerKit(super.e, super.b);

  // comer-set.html: REVEAL
  final Map<int, int> REVEAL = {};

  @override
  void revealX(num at, num a0, num a1, num z0, num z1, num deep, List<num> c) {
    if (PART_TAGS == null) return super.revealX(at, a0, a1, z0, z1, deep, c);
    final zb = e.zb, b = Float32List.fromList(zb);
    super.revealX(at, a0, a1, z0, z1, deep, c);
    for (var i = 0; i < W * H; i++) {
      if (zb[i] != b[i]) REVEAL[i] = e.pix[i];
    }
  }
}

/// The set of A comer, built into an engine (comer-set.html, from the plan to `buildSet`).
class ComerSet {
  ComerSet(this.e, this.b, [this.SET = const ComerState()])
    : k = _ComerKit(e, b) {
    c = CocinaKit(k);
    P = ComerPlan(e);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CocinaKit c;

  /// The plan's numbers (comer-set.html: the constants, `FOOT`, `STOVE`).
  late final ComerPlan P;

  // comer-set.html: SET
  final ComerState SET;

  int get W => e.W;
  int get H => e.H;
  double get ST => b.ST;

  /* ---------- the table ---------- */

  // comer-set.html: tableLegs
  void tableLegs() {
    for (final l in P.LEGS) {
      c.kSolid(
        'y',
        l[0],
        l[0] + .08,
        l[1],
        l[1] + .08,
        0,
        P.TBL.z - ComerPlan.DROP,
        ComerPlan.TWD,
      );
    }
  }

  // comer-set.html: GING
  static List<int> GING(int k) =>
      [ComerPlan.CL_white, ComerPlan.CL_light, ComerPlan.CL_blue][k];

  // comer-set.html: clothTone
  static List<int> clothTone(List<int> c, int n) => [
    for (final v in c) _round(v * const [1, .86, .72][n]),
  ];

  // comer-set.html: table
  void table() {
    final t = P.TBL, x0 = t.x0, x1 = t.x1, y0 = t.y0, y1 = t.y1, z = t.z;
    const m = .03, CHECK = ComerPlan.CHECK, DROP = ComerPlan.DROP;
    int st(double a) => (((a / CHECK).floor() % 2) + 2) % 2;
    // white, light (one stripe), blue (two)
    List<int> cell(double a, double bb) => GING(st(a - x0) + st(bb - y0));
    c.kBox('y', x0 - m, x1 + m, y0 - m, y1 + m, z - DROP, z + .012, (
      f,
      p,
      q,
      sh,
    ) {
      if (f == 'top') return c.kRgb(cell(p, q));
      // the near side a tone darker, the ends two; how far down
      final n = f == 'front' ? 1 : 2, h = z + .012 - q;
      // the hem
      if (h > DROP - .05) return c.kRgb(clothTone(ComerPlan.CL_hem, n - 1));
      return c.kRgb(
        clothTone(GING(st((f == 'front' ? p - x0 : p - y0)) + st(h)), n),
      );
    });
  }

  // comer-set.html: chairLegs
  void chairLegs() {
    for (final ch in P.CHAIRS) {
      final xa = ch.x - ComerPlan.CH_hw,
          xb = ch.x + ComerPlan.CH_hw,
          ya = ch.y - ComerPlan.CH_hd,
          yb = ch.y + ComerPlan.CH_hd;
      for (final lx in [xa, xb - .05]) {
        for (final ly in [ya, yb - .05]) {
          c.kSolid(
            'y',
            lx,
            lx + .05,
            ly,
            ly + .05,
            0,
            ComerPlan.ZS - .06,
            ComerPlan.CHW,
          );
        }
      }
    }
  }

  // comer-set.html: chair
  void chair(ComerChair ch) {
    final R = e.rampOf(ComerPlan.CHW);
    const ZS = ComerPlan.ZS, ZB = ComerPlan.CH_ZB;
    final xa = ch.x - ComerPlan.CH_hw,
        xb = ch.x + ComerPlan.CH_hw,
        ya = ch.y - ComerPlan.CH_hd,
        yb = ch.y + ComerPlan.CH_hd;
    c.kBox(
      'y',
      xa,
      xb,
      ya,
      yb,
      ZS - .06,
      ZS,
      (f, p, q, sh) => f == 'top' ? R[3] : R[sh ? 1 : 2],
    );
    for (final px in [xa, xb - .06]) {
      c.kSolid('y', px, px + .06, ya, ya + .06, ZS, ZB, ComerPlan.CHW);
    }
    for (final r in const [
      [ZB - .2, ZB],
      [ZB - .5, ZB - .38],
    ]) {
      c.kBox(
        'y',
        xa,
        xb,
        ya,
        ya + .05,
        r[0],
        r[1],
        (f, p, q, sh) => f == 'top' ? R[4] : R[sh ? 1 : 3],
      );
    }
  }

  // comer-set.html: sink. A steel basin set into the counter's top, its tap on the wall behind it
  void sink() {
    final S = ComerPlan.SINK,
        a0 = S.a0,
        a1 = S.a1,
        d0 = S.d0,
        d1 = S.d1,
        z = K.CZ + .004,
        St = e.rampOf(const [200, 204, 216]);
    c.kBox('x', a0, a1, d0, d1, z - .002, z, (f, p, q, sh) {
      final rim = p < a0 + .05 || p > a1 - .05 || q < d0 + .05 || q > d1 - .05;
      return rim ? St[3] : (q < d0 + .14 ? St[1] : St[2]);
    }, 't');
    final am = (a0 + a1) / 2;
    c.kSolid('x', am - .035, am + .035, .02, .09, K.CZ, K.CZ + .32, const [
      138,
      142,
      160,
    ]);
    c.kSolid('x', am - .035, am + .035, .02, .3, K.CZ + .26, K.CZ + .32, const [
      138,
      142,
      160,
    ]);
  }

  /* ---------- the door (round 2, La mesa's: main 64aa5f1) ---------- */

  // comer-set.html: PATIO_PX, kept with this engine's floor
  List<int> get PATIO_PX => _patioPx[e] ??= <int>[];

  // comer-set.html: patioGround
  int patioGround(double x, double y, int ix, int iy, int i) {
    final col = patioColour(x, y);
    if (col != 0) PATIO_PX.addAll([i, col]);
    return col;
  }

  // comer-set.html: patioColour
  int patioColour(double x, double y) {
    if (x >= -K.T || x < -K.T - K.OUTD) return 0;
    final a = y - x;
    if (a < ComerPlan.DOOR.a0 - .3 || a > ComerPlan.DOOR.a1 + .3) return 0;
    final Rr = e.rampOf(ComerPlan.STONE);
    if (x > -K.T - ComerPlan.STEP_D + .04) return Rr[3];
    if (x > -K.T - ComerPlan.STEP_D) return Rr[1];
    final g = e.GRASS[3];
    return e.rgb(g[0], g[1], g[2]);
  }

  // comer-set.html: doorExtras
  void doorExtras() {
    final Wd = e.rampOf(KC.wood);
    final a0 = ComerPlan.DOOR.a0, a1 = ComerPlan.DOOR.a1;
    final z1 = ComerPlan.DOOR.z1, w = P.LEAF.len;
    k.part(
      'puerta.umbral',
      () => c.kBox(
        'x',
        a0,
        a1,
        -K.T,
        .1,
        0,
        .05,
        (f, p, q, sh) => f == 'top' ? c.kRgb(KC.woodL) : Wd[1],
        'tf',
      ),
    );
    int panel(num t, num z) {
      final u = t * w, edge = u < .07 || u > w - .07 || z < .07 || z > z1 - .07;
      final inPanel =
          u > .2 &&
          u < w - .2 &&
          ((z > .3 && z < 1.15) || (z > 1.35 && z < z1 - .25));
      final rim =
          inPanel &&
          (u < .26 ||
              u > w - .26 ||
              (z - .3).abs() < .06 ||
              (z - 1.15).abs() < .06 ||
              (z - 1.35).abs() < .06 ||
              (z - (z1 - .25)).abs() < .06);
      return Wd[edge
          ? 0
          : rim
          ? 1
          : inPanel
          ? 3
          : 2];
    }

    k.part('puerta.hoja', () {
      final L = P.LEAF;
      k.leaf(
        L.hx,
        L.hy,
        w,
        0,
        z1 - .02,
        L.ang,
        (t, z) => t > .96 ? Wd[0] : panel(t, z),
      );
      final hx = L.hx + math.cos(L.ang) * (w - .14),
          hy = L.hy + math.sin(L.ang) * (w - .14),
          Kn = c.kRgb(KC.knob),
          KnD = c.kRgb(c.kLit(KC.knob, true));
      for (num a = 0; a <= .1; a += ST * .4) {
        for (num z = 0; z <= .1; z += ST * .4) {
          e.plot(hx + .03, hy - a, 1.1 + z, z > .07 ? Kn : KnD);
        }
      }
    });
  }

  // comer-set.html: tagReveal
  void tagReveal() {
    final tags = k.PART_TAGS, R = (k as _ComerKit).REVEAL;
    if (tags == null) return;
    for (final en in R.entries) {
      if (tags[en.key] == 'puerta' && e.pix[en.key] == en.value) {
        tags[en.key] = 'puerta.jamba';
      }
    }
    R.clear();
  }

  // comer-set.html: undimPatio
  void undimPatio() {
    final px = PATIO_PX, zb = e.zb, gz = e.groundZ, pix = e.pix;
    for (var kk = 0; kk < px.length; kk += 2) {
      final i = px[kk];
      if (zb[i] == gz[i] && e.kinds[i] == KIND_ROAD && e.shadowMask[i] == 0) {
        pix[i] = px[kk + 1];
      }
    }
    e.bakedPix.setAll(0, pix);
  }

  /* ---------- bake ---------- */

  // comer-set.html: PLAN.furnish
  void furnish() {
    doorExtras();
    k.part('mostrador', () {
      c.cocinaBase('x', ComerPlan.A0, ComerPlan.A1);
    });
    k.part('fregadero', sink);
    k.part('alacena', () {
      c.cocinaWallCupboard('x', ComerPlan.UP[0], ComerPlan.UP[1]);
    });
    k.part('estufa', () {
      c.cocinaStove('y', ComerPlan.STX, noEnd: true);
    });
    k.part('salpicadero', () {
      c.cocinaBackguard('y', ComerPlan.STX);
    });
    k.part('campana', () {
      c.cocinaHood('y', ComerPlan.STX);
    });
    k.part('mostrador2', () {
      c.cocinaBase('y', ComerPlan.STX + K.STW, ComerPlan.XR);
    });
    k.part('sillas.patas', chairLegs);
    for (var i = 0; i < P.CHAIRS.length; i++) {
      final ch = P.CHAIRS[i];
      k.part('silla$i', () => chair(ch));
    }
    k.part('mesa.patas', tableLegs);
    k.part('mesa', table);
  }

  // comer-set.html: PLAN.shadows
  void shadows() {
    k.part('mesa.patas', () {
      for (final l in P.LEGS) {
        c.cocinaShadowFoot(l[0] + .04, l[1] + .04, .08);
      }
    });
  }

  // comer-set.html: PLAN
  late final CocinaPlan PLAN = CocinaPlan(
    XR: ComerPlan.XR,
    YL: ComerPlan.YL,
    windows: const [ComerPlan.WIN, ComerPlan.DOOR],
    band: ComerPlan.BAND,
    occlusion: 'shade',
    floor: patioGround,
    furnish: furnish,
    shadows: shadows,
  );

  // comer-set.html: buildSet (and buildSet0, with neither `noshade` nor `empty`)
  void buildSet() {
    c.cocinaCheckScene();
    c.cocinaBuild(PLAN);
    undimPatio();
    tagReveal();
  }

  // comer-set.html: frame. The baked set, with the casts given
  void frame(num t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.shadowMask.fillRange(0, e.shadowMask.length, 0);
    for (final cc in casts) {
      e.castShadow(cc[0], cc[1], cc[2], cc[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
