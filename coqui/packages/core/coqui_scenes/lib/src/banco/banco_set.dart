// Port of docs/proyecto/pixel/banco-set.html: El banco's set, its states, call for call (order 36a's set reference,
// order 36b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El banco's set is built on (banco-set.html: `window.PP_SCENE`, with the page's default origin, El camino's,
/// El campo's and El lago's, which is the sheet's): 240 × 216, S 26, origin (0, 4), shadows to (.9, -.1).
PpEngine bancoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 4,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (banco-set.html: `SET`, from the address): the light of the hour (`luz`: dia, tarde, noche),
/// the moon (`luna`, only at night) and the cart (`carro`: abierto, cerrado, or no: gone, or rolling, when the sprite
/// layer draws it). The page's `t` (wind time) is the frame's, not the state's; its `edge=straight` is a look candidate,
/// not a state: the sheet is made for `steps`, the only one ported.
class BancoState {
  const BancoState({
    this.luz = 'dia',
    this.luna = false,
    this.carro = 'abierto',
  });

  /// banco-set.html: `pick('luz', ...)`, `pick('luna', ...)`, `pick('carro', ...)`, from a query
  /// (`?luz=noche&luna=1&carro=abierto`); a value the page does not allow takes its default, as there. The moon only at
  /// night (`SET.luna = SET.luna && SET.luz === 'noche'`).
  factory BancoState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    final luz = pick('luz', const ['dia', 'tarde', 'noche'], 'dia');
    return BancoState(
      luz: luz,
      luna: pick('luna', const ['0', '1'], '0') == '1' && luz == 'noche',
      carro: pick('carro', const ['abierto', 'cerrado', 'no'], 'abierto'),
    );
  }

  /// A key of the sheet's `setKey` table (`"noche.1.abierto"`: luz, luna, carro) read back.
  factory BancoState.fromKey(String key) {
    final m = RegExp(r'^(dia|tarde|noche)\.([01])\.(abierto|cerrado|no)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', 'not a key of El banco\'s set');
    }
    return BancoState(
      luz: m[1]!,
      luna: m[2] == '1' && m[1] == 'noche',
      carro: m[3]!,
    );
  }

  final String luz, carro;
  final bool luna;

  /// The sheet's key: luz + "." + luna + "." + carro (`setKey.key`, e.g. "dia.0.abierto").
  String get key => '$luz.${luna ? 1 : 0}.$carro';

  /// The query of the page for this state (`luz=dia&luna=0&carro=abierto`).
  String get query => 'luz=$luz&luna=${luna ? 1 : 0}&carro=$carro';
}

/// banco-set.html: `t`, the wind time in seconds a query gives (`?t=1.5`), 0 when it gives none.
double bancoTimeOf(String query) {
  final q = Uri.splitQueryString(
    query.startsWith('?') ? query.substring(1) : query,
  );
  return double.tryParse(q['t'] ?? '') ?? 0;
}

/* ---------- the plan ---------- */

const double HZ = 100; // the horizon (screen row): the park's

// banco-set.html: Gs. The world point at height z under a screen point
List<double> bancoGs(PpEngine e, num sx, num sy, [num z = 0]) {
  final u = (sx - e.OX) / e.S,
      v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
  return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
}

/* ---------- the benches (the old BANCOS: the middle of each seat at (96, 150), (144, 150), (192, 150)) ---------- */

const List<int> BANCOS = [96, 144, 192];
const double ZS = .42, BD = .5, BHL = .85, BACK_H = .6;
const double SEAT_ROW =
    151; // the seat's front edge at each bench's middle (the old seat's edge)
const List<double> BHL_R = [
  BHL,
  BHL,
  .27,
]; // the third bench ends 5 px right of its middle (round 2)

/// A bench on the ground (banco-set.html: an entry of `BENCH`): its old screen x, and its world box x0 to x1, y0 to y1.
typedef BancoBench = ({int B, double x0, double x1, double y0, double y1});

// banco-set.html: BENCH
List<BancoBench> bancoBenches(PpEngine e) => [
  for (var k = 0; k < 3; k++)
    () {
      final B = BANCOS[k], f = bancoGs(e, B, SEAT_ROW, ZS);
      return (
        B: B,
        x0: f[0] - BHL,
        x1: f[0] + BHL_R[k],
        y0: f[1] - BD,
        y1: f[1],
      );
    }(),
];

// banco-set.html: SY. Where whoever sits at column c has their feet
double bancoSY(num c) {
  var k = 0;
  for (var i = 1; i < 3; i++) {
    if ((c - BANCOS[i]).abs() < (c - BANCOS[k]).abs()) k = i;
  }
  return SEAT_ROW + 10 + (c - BANCOS[k]) / 2;
}

const List<int> WOOD = [150, 98, 56],
    LEG = [92, 60, 36],
    TRUNK = [118, 82, 50],
    IRON = [64, 66, 82],
    STONEP = [190, 178, 156];

/* ---------- the paving's far edge: a line of segments on the axes ---------- */

const double EDGE_BACK = 6.5;
const List<int> STEP_AT = [110, 158];
const int TURN_AT = 80;

/* ---------- the hedge and the gate ---------- */

const double HEDGE_K = 604, HEDGE_T = .32, HEDGE_H = .7, HEDGE_H_FAR = .7;
const List<List<int>> GATE = [
  [180, 212],
  [212, 196],
];
const double NEAR_PIECE = .3;
const double POST_W = .11, POST_H = 1.55;

/* ---------- the trees, the pole, the lamp post, the wire ---------- */

const List<List<int>> TREES = [
  [86, 102],
  [121, 114],
  [220, 124],
];

/// banco-set.html: POLE (its foot, its top row, its radius).
const ({List<int> at, int top, double r}) POLE = (
  at: [24, 138],
  top: 48,
  r: .04,
);

/// banco-set.html: FAROL (its foot on the screen, and its lantern: x, top row, bottom row).
const ({List<int> at, List<int> lamp}) FAROL = (
  at: [174, 140],
  lamp: [174, 34, 48],
);

// banco-set.html: cableY (the old wire: banco.js cableY)
int bancoCableY(num x) =>
    (50 + 7 * (1 - math.pow((x - 120) / 98, 2)) + .5).floor();

/* ---------- the cart ---------- */

const List<int> CARRO = [36, 178];
const double WHEEL_R = .3;

/// A box in the world (banco-set.html: `CART`).
typedef BancoBox = ({
  double x0,
  double x1,
  double y0,
  double y1,
  double z0,
  double z1,
});

// banco-set.html: CART
BancoBox bancoCart(PpEngine e) {
  final m = bancoGs(e, CARRO[0] + 4, CARRO[1] - 6 - 1);
  const hl = .72, d = .66;
  final x0 = m[0] + .16;
  return (
    x0: x0,
    x1: x0 + d,
    y0: m[1] - hl + .05,
    y1: m[1] + hl + .05,
    z0: .34,
    z1: .9,
  );
}

const List<int> BLUE = [58, 154, 208],
    UMB_RED = [224, 72, 58],
    UMB_WHITE = [242, 242, 248];

/* ---------- the sky: El camino's by day; by the hour (tarde, noche) ---------- */

/// The sky of an hour (banco-set.html: an entry of `SKIES`).
typedef BancoSky = ({
  List<List<num>> bands,
  List<List<num>> far,
  List<List<num>> near,
  List<List<num>>? sun,
  List<List<num>> cloud,
});

const Map<String, BancoSky> SKIES = {
  'dia': (
    bands: [
      [58, 134, 230],
      [85, 159, 242],
      [120, 186, 250],
      [162, 211, 255],
      [208, 234, 255],
    ],
    far: [
      [116, 180, 162],
      [156, 208, 188],
      [94, 158, 144],
    ],
    near: [
      [78, 158, 94],
      [124, 203, 122],
      [62, 136, 80],
    ],
    sun: [
      [220, 150, 30],
      [248, 200, 56],
      [255, 224, 112],
      [255, 244, 176],
    ],
    cloud: [
      [214, 230, 248],
      [244, 248, 255],
    ],
  ),
  'tarde': (
    bands: [
      [86, 128, 214],
      [120, 156, 226],
      [176, 180, 214],
      [236, 196, 170],
      [252, 214, 160],
    ],
    far: [
      [150, 160, 150],
      [186, 186, 164],
      [128, 140, 134],
    ],
    near: [
      [104, 140, 84],
      [150, 176, 104],
      [86, 120, 72],
    ],
    sun: [
      [226, 120, 40],
      [246, 160, 60],
      [255, 200, 100],
      [255, 232, 160],
    ],
    cloud: [
      [220, 196, 200],
      [250, 228, 214],
    ],
  ),
  'noche': (
    bands: [
      [10, 14, 42],
      [16, 22, 62],
      [24, 32, 82],
      [34, 48, 106],
      [46, 62, 128],
    ],
    far: [
      [44, 50, 70],
      [52, 58, 80],
      [38, 44, 62],
    ],
    near: [
      [30, 44, 40],
      [38, 54, 46],
      [26, 38, 34],
    ],
    sun: null,
    cloud: [
      [58, 66, 104],
      [76, 84, 124],
    ],
  ),
};

/// The light of the hour on the set (banco-set.html: `LIGHTS`): c * m + a; the evening keeps the blades' lit colours.
const Map<String, Light?> LIGHTS = {
  'dia': null,
  'tarde': Light([.9, .9, .9], [25.5, 15, 6], litTufts: true),
  'noche': Light([.56, .62, .82], [6, 10, 30]),
};

const List<num> SUN = [34, 40, 4], MOON = [34, 40, 4];
const List<List<num>> CLOUDS = [
  [150, 12, .7],
  [196, 30, .8],
  [160, 40, .6],
];

/* ---------- the ground ---------- */

const double LAWN_T = 3.45;
const List<int> BLADE = [2, 2, 3, 3, 4];
const List<List<int>> PAVE = [
  [150, 140, 120],
  [184, 174, 152],
  [206, 198, 178],
  [216, 208, 186],
  [226, 218, 198],
];
const double FLAG = .62, FLAGW = .46, JOINT = .035;

/* ---------- the trees ---------- */

const List<List<int>> LEAF = [
  [52, 128, 66],
  [66, 148, 76],
  [86, 170, 88],
  [118, 196, 108],
];

/* ---------- the lamp ---------- */

const Map<String, List<int>> LAMP_GLASS = {
  'dia': [214, 220, 226],
  'tarde': [255, 226, 120],
  'noche': [255, 244, 180],
};
const ({double rx, double ry}) POOL = (rx: 2.4, ry: 2.4);
const Map<String, List<int>> WIRE_COLOUR = {
  'dia': [58, 58, 70],
  'tarde': [46, 38, 54],
  'noche': [206, 212, 236],
};

/// The ground and its grass (banco-set.html: `GROUND_CACHE`, made once per page for its one `edge`), so here once per
/// engine.
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// The set of El banco, built into an engine (banco-set.html, from "the plan" to "bake one state").
class BancoSet {
  BancoSet(this.e, this.b, [this.SET = const BancoState()]) : k = SetKit(e, b) {
    BENCH = bancoBenches(e);
    GATE_W = [for (final p in GATE) Gs(p[0], p[1])];
    HEDGE_X = GATE_W[0][0] + HEDGE_T / 2;
    CART = bancoCart(e);
    CART_C = [(CART.x0 + CART.x1) / 2, (CART.y0 + CART.y1) / 2];
    WIRE = _wire();
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // banco-set.html: SET
  final BancoState SET;

  int get W => e.W;
  int get H => e.H;

  bool get NIGHT => SET.luz == 'noche';
  bool get DUSK => SET.luz == 'tarde';

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // banco-set.html: Gs
  List<double> Gs(num sx, num sy, [num z = 0]) => bancoGs(e, sx, sy, z);

  // banco-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  late final List<BancoBench> BENCH;
  late final List<List<double>> GATE_W;
  late final double HEDGE_X;
  late final BancoBox CART;
  late final List<double> CART_C;

  /// banco-set.html: WIRE. At each quarter column from the pole on: the column, and the world point (x, y, z) where
  /// the wire hangs.
  late final List<List<double>> WIRE;

  List<List<double>> _wire() {
    final P = Gs(POLE.at[0], POLE.at[1]),
        F = Gs(FAROL.at[0], FAROL.at[1]),
        out = <List<double>>[];
    final p0 = SCR(P[0], P[1])[0], f0 = SCR(F[0], F[1])[0];
    for (double sx = POLE.at[0].toDouble(); sx <= 244; sx += .25) {
      final t = (sx - p0) / (f0 - p0),
          x = e.lerp(P[0], F[0], t),
          y = e.lerp(P[1], F[1], t),
          g = SCR(x, y, 0);
      final yy = 50 + 7 * (1 - math.pow((sx - 120) / 98, 2));
      out.add([sx, x, y, (g[1] - yy) / (e.COS * e.S)]);
    }
    return out;
  }

  BancoSky get SKY => SKIES[SET.luz]!;
  Light? get LIGHT => LIGHTS[SET.luz];

  // banco-set.html: backRow. The back legs' feet (z 0, y = y0) at column c
  double backRow(int kk, num c) =>
      SEAT_ROW + (c - BANCOS[kk]) / 2 - BD * e.S / e.R2 + ZS * e.COS * e.S;

  // banco-set.html: SEGROW
  double SEGROW(int kk, num c) => backRow(kk, c) - EDGE_BACK;

  // banco-set.html: EDGEROW (edge=steps). The paving's far edge's row at column c (the paving is below it)
  double EDGEROW(num c) {
    if (c <= TURN_AT) return SEGROW(0, TURN_AT) + (TURN_AT - c) / 2;
    for (var kk = 0; kk < 3; kk++) {
      if (kk == 2 || c <= STEP_AT[kk]) return SEGROW(kk, c);
      final r0 = SEGROW(kk, STEP_AT[kk]),
          r = r0 - (c - STEP_AT[kk]) / 2; // the step along y
      if (r >= SEGROW(kk + 1, c)) return r;
    }
    return SEGROW(2, c);
  }

  // banco-set.html: cloudAt
  int cloudAt(int ix, int iy) {
    for (final cl in CLOUDS) {
      final cx = cl[0], cy = cl[1], s = cl[2];
      bool el(num x0, num y0, num rx, num ry) {
        final dx = (ix + .5 - x0) / rx, dy = (iy + .5 - y0) / ry;
        return dx * dx + dy * dy <= 1;
      }

      if (el(cx, cy, 13 * s, 5 * s) ||
          el(cx - 9 * s, cy + 2, 8 * s, 4 * s) ||
          el(cx + 10 * s, cy + 2, 9 * s, 4 * s)) {
        return _rgbOf(SKY.cloud[iy + .5 > cy + 2 * s ? 0 : 1]);
      }
    }
    return 0;
  }

  // banco-set.html: moonAt
  int moonAt(int ix, int iy) {
    final dx = ix + .5 - MOON[0],
        dy = iy + .5 - MOON[1],
        d = math.sqrt(dx * dx + dy * dy);
    if (d > MOON[2]) return 0;
    if (d > MOON[2] - 1) return e.rgb(196, 192, 160);
    final q = MOON[2] / 4;
    final ax = dx + 2 * q, ay = dy + 2 * q, bx = dx - 2.5 * q, by = dy - q;
    final spot =
        math.sqrt(ax * ax + ay * ay) < 1.8 * q ||
        math.sqrt(bx * bx + by * by) < 1.3 * q;
    return spot ? e.rgb(226, 218, 172) : e.rgb(255, 248, 216);
  }

  /* ---------- the ground: the paving, the lawn, the path through the gate ---------- */

  List<List<int>> get LAWN => e.GRASS;

  // banco-set.html, at load: the blades take the lawn's tones (tuftLit, tuftDark)
  void _tuftColours() {
    for (var kk = 0; kk < 5; kk++) {
      final c = LAWN[BLADE[kk]];
      e.tuftLit[kk] = _rgbOf(c);
      e.tuftDark[kk] = e.rgb(c[0] * .54, c[1] * .52, c[2] * .72);
    }
  }

  // banco-set.html: lawnAt
  int lawnAt(num x, num y, int ix, int iy) {
    final t =
        LAWN_T +
        (e.noise(x * .3, y * .3) - .5) * .6 +
        (e.bayerAt(ix, iy) - .5) * .8 +
        (e.hash(ix, iy) - .5) * .25;
    return _rgbOf(LAWN[e.clamp(t.floor(), 2, 4)]);
  }

  // banco-set.html: paveAt
  int paveAt(num x, num y, int ix, int iy) {
    final r = (y / FLAGW).floor(),
        fx = x / FLAG + (r.remainder(2) != 0 ? .5 : 0),
        kk = fx.floor();
    final jy = y - r * FLAGW, jx = (fx - kk) * FLAG;
    if (jy < JOINT || jx < JOINT) return _rgbOf(PAVE[1]);
    final h = e.hash(kk * 7 + 3, r * 5 + 1),
        t =
            3 +
            (h > .78
                ? .6
                : h < .2
                ? -.45
                : 0) +
            (e.bayerAt(ix, iy) - .5) * .5 +
            (e.hash(ix >> 1, iy >> 1) < .06 ? -.7 : 0);
    return _rgbOf(PAVE[e.clamp(t.floor(), 2, 4)]);
  }

  // banco-set.html: onHedgeLine. < HEDGE_K: the plaza's side
  static double onHedgeLine(num sx, num sy) => (sx + 2 * sy).toDouble();

  // banco-set.html: groundKind. What the ground is under a ground point (x, y): 'pave' (the plaza, and the path out
  // through the gate), 'lawn' (beyond the paving's far edge, and beyond the hedge)
  String groundKind(double x, double y) {
    final s = SCR(x, y, 0), sx = s[0], sy = s[1];
    if (sy + .5 < HZ) return 'sky';
    if (onHedgeLine(sx, sy) >= HEDGE_K) {
      return y > GATE_W[1][1] - .02 && y < GATE_W[0][1] + .02 ? 'pave' : 'lawn';
    }
    return sy >= EDGEROW(sx) ? 'pave' : 'lawn';
  }

  // banco-set.html: bancoGround
  int bancoGround(double x, double y, int ix, int iy, int i) {
    if (iy + .5 < HZ) return 0; // above the horizon: the hills and the sky
    final kk = groundKind(x, y);
    if (kk == 'pave') {
      e.kinds[i] = KIND_ROAD;
      return paveAt(x, y, ix, iy);
    }
    e.kinds[i] = e.KIND_GRASS;
    return lawnAt(x, y, ix, iy);
  }

  /* ---------- the benches ---------- */

  // banco-set.html: bench
  void bench(int kk) {
    final bb = BENCH[kk];
    k.part('banco$kk', () {
      final x0 = bb.x0, x1 = bb.x1, y0 = bb.y0, y1 = bb.y1;
      // the legs: a pair at each end (front and back) and a stretcher between them; the back legs go on up as the
      // back's uprights
      for (final a in [x0 + .07, x1 - .07]) {
        b.block(a - .035, y1 - .07, 0, a + .035, y1 - .0, ZS - .05, LEG);
        b.block(a - .035, y0, 0, a + .035, y0 + .07, ZS + BACK_H, LEG);
        b.block(a - .025, y0 + .06, .1, a + .025, y1 - .06, .16, LEG);
      }
      // the seat: three planks along x, a dark gap between them, each a step lighter towards the front
      const pw = BD / 3;
      for (var n = 0; n < 3; n++) {
        final s0 = y0 + n * pw + .01, s1 = s0 + pw - .03;
        b.block(x0, s0, ZS - .06, x1, s1, ZS, WOOD, [
          for (final v in WOOD) math.min(255, v * (1.08 + n * .05)),
        ]);
      }
      // the back: two planks along x on the uprights
      for (final zz in const [
        [ZS + .06, ZS + .3],
        [ZS + .35, ZS + BACK_H - .02],
      ]) {
        b.block(x0 + .02, y0 + .04, zz[0], x1 - .02, y0 + .09, zz[1], WOOD, [
          for (final v in WOOD) math.min(255, v * 1.12),
        ]);
      }
      // its shadow on the paving: under the seat, and the back's, short, at its foot
      if (!NIGHT) {
        for (var a = x0 + .1; a <= x1 - .1; a += .2) {
          e.castShadow(a, (y0 + y1) / 2, ZS - .1, .2);
          e.castShadow(a, y0 + .05, ZS + .2, .12);
        }
      }
    });
  }

  /* ---------- the trees: El camino's small trees ---------- */

  // banco-set.html: CROWN_SHADE
  final List<List<double>> CROWN_SHADE = [];

  // banco-set.html: smallTree
  void smallTree(int i) {
    final f = Gs(TREES[i][0], TREES[i][1]);
    final fx = f[0], fy = f[1];
    k.part('arbol$i', () {
      final zc = 30 / (e.COS * e.S);
      e.capsule(
        [fx, fy, 0],
        [fx, fy, zc - .1],
        .11,
        .08,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        [fx - .12, fy + .12, 0],
        [fx + .12, fy - .12, 0],
        .07,
        .07,
        (_) => TRUNK,
        'rough',
      );
      if (!NIGHT) {
        for (double z = .03; z < zc; z += .08) {
          e.castShadow(fx, fy, z, .14, 1, 0);
        }
      }
      final ru = 15.6 / e.S, rz = 12.6 / (e.COS * e.S);
      const rv = .5;
      for (var kk = 0; kk < 80; kk++) {
        double h(int a, int bb) => e.hash(kk * 13 + i * 101 + a, bb);
        final th = h(1, 7) * 6.283,
            ph = math.acos(2 * h(2, 8) - 1),
                // Math.cbrt, as the porting table says
                d =
                math.pow(h(3, 9), 1 / 3) * .88;
        final du = math.cos(th) * math.sin(ph) * d,
            dv = math.sin(th) * math.sin(ph) * d,
            dz = math.cos(ph) * d;
        final u = (fx - fy) / e.R2 + du * ru,
            v = (fx + fy) / e.R2 + dv * rv,
            z = zc + dz * rz;
        final tone = h(4, 10) * .6 + dz * .5 - du * .25 + .3;
        final q = k.UVW(u, v, z);
        e.sphere(
          q[0],
          q[1],
          q[2],
          .16 + h(5, 11) * .1,
          LEAF[tone > 1
              ? 3
              : tone > .62
              ? 2
              : tone > .25
              ? 1
              : 0],
          'rough',
        );
      }
      // the crown's shadow on the lawn: a lone tree's, lighter and solid (El campo's rule), cast after the bake
      CROWN_SHADE.add([fx, fy, zc]);
    });
  }

  // banco-set.html: CROWN_PX
  final Set<int> CROWN_PX = {};

  // banco-set.html: crownShades. El campo's lone tree's shade: one even tone, the lawn's next darker, on the lawn only,
  // an ellipse where the engine would cast the crown's
  void crownShades() {
    if (NIGHT) return;
    for (final c in CROWN_SHADE) {
      final fx = c[0], fy = c[1], zc = c[2];
      final p = e.project(fx + e.SHADOW_X * zc, fy + e.SHADOW_Y * zc, 0),
          rx = .55 * e.S * 1.05,
          ry = rx * e.SIN + 1;
      for (var iy = (p.sy - ry).floor(); iy <= (p.sy + ry).ceil(); iy++) {
        for (var ix = (p.sx - rx).floor(); ix <= (p.sx + rx).ceil(); ix++) {
          if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
          final dx = (ix + .5 - p.sx) / rx, dy = (iy + .5 - p.sy) / ry;
          if (dx * dx + dy * dy > 1) continue;
          final i = iy * W + ix;
          if (e.kinds[i] != e.KIND_GRASS || e.zb[i] != e.groundZ[i]) continue;
          e.pix[i] = _rgbOf(LAWN[2]);
          CROWN_PX.add(i);
        }
      }
    }
  }

  /* ---------- the pole, the lamp post, the wire ---------- */

  // banco-set.html: PZ. A height in rows, as world z
  double PZ(num sy0, num sy1) => (sy0 - sy1) / (e.COS * e.S);

  // banco-set.html: pole
  void pole() {
    k.part('poste', () {
      final g = Gs(POLE.at[0], POLE.at[1]), h = PZ(POLE.at[1], POLE.top);
      e.capsule(
        [g[0], g[1], 0],
        [g[0], g[1], h],
        POLE.r,
        POLE.r * .9,
        (_) => IRON,
        'solid',
      );
      b.block(
        g[0] - .035,
        g[1] - .035,
        0,
        g[0] + .035,
        g[1] + .035,
        .18,
        IRON,
      ); // its foot
      e.sphere(g[0], g[1], h + .03, .035, IRON, 'solid');
      if (!NIGHT) {
        for (double z = .02; z <= .1; z += .04) {
          e.castShadow(g[0], g[1], z, .08, 1, 0);
        }
      }
    });
  }

  // banco-set.html: FAROL_PX, POOL_PX, POOL_IN
  final Set<int> FAROL_PX = {}, POOL_PX = {}, POOL_IN = {};

  // banco-set.html: lampPost
  void lampPost() {
    final before = Float32List.fromList(e.zb);
    FAROL_PX.clear();
    k.part('farol', () {
      final g = Gs(FAROL.at[0], FAROL.at[1]),
          top = PZ(FAROL.at[1], FAROL.lamp[1]),
          bot = PZ(FAROL.at[1], FAROL.lamp[2]);
      // its foot: a short round plinth; the post; the lantern (four glass faces under a cap) at the old lantern's rows
      k.drum(
        g[0],
        g[1],
        0,
        .22,
        .13,
        IRON,
        (dx, dy) => e.rampOf(IRON)[dx + dy < 0 ? 3 : 2],
      );
      e.capsule(
        [g[0], g[1], .2],
        [g[0], g[1], bot],
        .06,
        .05,
        (_) => IRON,
        'solid',
      );
      const hw = .12;
      final lit = SET.luz != 'dia', G = LAMP_GLASS[SET.luz]!;
      // the glass: its two faces turned to the camera (+x, +y), lit at dusk and at night (they give light:
      // plotGlow), the frame's bars dark
      for (final face in const ['y', 'x']) {
        for (num a = -hw; a <= hw; a += k.ST * .4) {
          for (num z = bot + .06; z <= top - .12; z += k.ST * .4) {
            final bar = a.abs() > hw - .035 || z < bot + .1 || z > top - .16;
            final x = face == 'y' ? g[0] + a : g[0] + hw,
                y = face == 'y' ? g[1] + hw : g[1] + a;
            if (bar) {
              e.plot(x, y, z, e.rampOf(IRON)[face == 'y' ? 2 : 1]);
            } else if (lit) {
              k.plotGlow(x, y, z, _rgbOf(G));
            } else {
              final m = face == 'y' ? 1 : .9;
              e.plot(x, y, z, e.rgb(G[0] * m, G[1] * m, G[2] * m));
            }
          }
        }
      }
      b.block(
        g[0] - hw - .03,
        g[1] - hw - .03,
        top - .12,
        g[0] + hw + .03,
        g[1] + hw + .03,
        top - .06,
        IRON,
      );
      e.sphere(g[0], g[1], top - .02, .07, IRON, 'solid');
      b.block(
        g[0] - .05,
        g[1] - .05,
        bot - .02,
        g[0] + .05,
        g[1] + .05,
        bot + .06,
        IRON,
      );
      if (!NIGHT) {
        for (double z = .02; z <= .14; z += .04) {
          e.castShadow(g[0], g[1], z, .15, 1, 0);
        }
      }
    });
    for (var i = 0; i < W * H; i++) {
      if (e.zb[i] != before[i]) FAROL_PX.add(i);
    }
  }

  // banco-set.html: lampPool. The lamp's light (lit at dusk and at night): a pool on the ground round its foot, under
  // the lantern, joined to it; brighter at night
  void lampPool() {
    if (SET.luz == 'dia') return;
    final g = Gs(FAROL.at[0], FAROL.at[1]), str = NIGHT ? 1 : .6;
    final fx = FAROL.at[0], fy = FAROL.at[1];
    final pix = e.pix, zb = e.zb;
    for (var iy = math.max(0, fy - 33); iy < math.min(H, fy + 34); iy++) {
      for (var ix = math.max(0, fx - 64); ix < math.min(W, fx + 65); ix++) {
        final i = iy * W + ix;
        if (zb[i] < -1e8 || FAROL_PX.contains(i)) continue;
        final w = e.unproject(ix + .5, iy + .5),
            ddx = (w.x - g[0]) / POOL.rx,
            ddy = (w.y - g[1]) / POOL.ry,
            d = math.sqrt(ddx * ddx + ddy * ddy);
        if (d > 1) continue;
        if (d < .5) POOL_IN.add(i);
        final f = (1 - d) * 2.2;
        // a soft edge: dithered over its outer part
        if (e.bayerAt(ix, iy) > f) continue;
        final c = pix[i], kk = str * (.2 + .45 * (1 - d));
        pix[i] = e.rgb(
          e.lerp(c & 255, 255, kk),
          e.lerp(c >> 8 & 255, 236, kk),
          e.lerp(c >> 16 & 255, 170, kk),
        );
        POOL_PX.add(i);
      }
    }
  }

  // banco-set.html: wire
  void wire() {
    k.part('cable', () {
      final WC = WIRE_COLOUR[SET.luz]!;
      for (final w in WIRE) {
        if (w[0] < POLE.at[0] + 1.5) continue;
        k.plotGlow(w[1], w[2], w[3], _rgbOf(WC));
      }
    });
  }

  /* ---------- the cart ---------- */

  // banco-set.html: UMBRELLA, the open umbrella, for its shade on the cart (umbrellaShade)
  ({double ux, double uy, double zr, double R0})? UMBRELLA;

  // banco-set.html: PART_TAGS_CART
  final Set<int> PART_TAGS_CART = {};

  static const List<List<int>> _SQUARES = [
    [224, 72, 58],
    [240, 192, 32],
    [62, 154, 82],
    [122, 86, 176],
  ];
  static const List<List<int>> _BOTTLES = [
    [224, 72, 58],
    [240, 192, 32],
    [62, 154, 82],
  ];

  // banco-set.html: cart
  void cart() {
    PART_TAGS_CART.clear();
    UMBRELLA = null;
    if (SET.carro == 'no') return;
    final before = Float32List.fromList(e.zb);
    k.part('carro', () {
      final x0 = CART.x0,
          x1 = CART.x1,
          y0 = CART.y0,
          y1 = CART.y1,
          z0 = CART.z0,
          z1 = CART.z1,
          cx = CART_C[0],
          cy = CART_C[1];
      // the body: its +x face a white panel with four colour squares (the old), its +y end, its top
      b.block(x0, y0, z0, x1, y1, z1, BLUE, const [122, 196, 236]);
      k.planeQuad(
        [x1 + .005, y0 + .16, z0 + .1],
        [0, y1 - y0 - .32, 0],
        [0, 0, z1 - z0 - .22],
        (a, bb) {
          final kk = (a * 4).floor(), f = a * 4 - kk;
          if (bb > .3 && bb < .78 && f > .25 && f < .75) {
            return _rgbOf(_SQUARES[kk]);
          }
          return bb < .08 || bb > .92
              ? e.rgb(208, 214, 224)
              : e.rgb(242, 242, 248);
        },
      );
      b.block(
        x0 - .02,
        y0 - .02,
        z1 - .04,
        x1 + .02,
        y1 + .02,
        z1 + .02,
        const [30, 106, 154],
      );
      // the handle at the man's side (-x): two short bars
      for (final yy in [y0 + .12, y1 - .12]) {
        b.block(x0 - .18, yy - .02, z1 - .08, x0, yy + .02, z1 - .04, IRON);
      }
      // the glass case with the block of ice (its back half), and three bottles of syrup (red, yellow, green) in
      // front of it
      b.block(
        x0 + .06,
        y0 + .14,
        z1 + .02,
        x0 + .34,
        y0 + .66,
        z1 + .3,
        const [176, 214, 240],
        const [220, 240, 255],
      );
      b.block(x0 + .1, y0 + .2, z1 + .04, x0 + .3, y0 + .58, z1 + .16, const [
        236,
        246,
        252,
      ]);
      for (var kk = 0; kk < _BOTTLES.length; kk++) {
        final c = _BOTTLES[kk], yy = y1 - .2 - kk * .2;
        e.capsule(
          [x1 - .18, yy, z1 + .02],
          [x1 - .18, yy, z1 + .3],
          .055,
          .05,
          (_) => c,
          'solid',
        );
        e.sphere(x1 - .18, yy, z1 + .34, .03, const [200, 200, 212], 'solid');
      }
      // the wheels: at the two ends of its +x side, in the plane x = x1 + .04: a dark tyre, a grey hub, spokes
      for (final wy in [y0 + .3, y1 - .3]) {
        final wc = [x1 + .04, wy, WHEEL_R];
        for (double a = 0; a < 6.283; a += .012) {
          for (double r = 0; r <= WHEEL_R; r += .012) {
            final yy = wc[1] + math.cos(a) * r,
                zz = wc[2] + math.sin(a) * r,
                spoke = math.sin(a * 3).abs() < .12;
            final col = r > WHEEL_R - .06
                ? e.rgb(52, 52, 64)
                : r < .07
                ? e.rgb(200, 200, 212)
                : spoke
                ? e.rgb(138, 138, 154)
                : 0;
            if (col != 0) e.plot(wc[0], yy, zz, col);
          }
        }
        if (!NIGHT) e.castShadow(wc[0], wy, .05, .12, 1, 0);
      }
      // the umbrella: its pole from the cart's middle; open, a shallow cone of eight panels, red and white; closed,
      // furled round its pole
      final ux = cx + .05, uy = cy;
      const ztop = 3.6;
      e.capsule(
        [ux, uy, z1],
        [ux, uy, ztop],
        .03,
        .03,
        (_) => const [110, 110, 128],
        'solid',
      );
      if (SET.carro == 'abierto') {
        const R0 = .7, zr = 3.25;
        for (double r = 0; r <= R0; r += .008) {
          for (double a = 0; a < 6.283; a += .006 / math.max(r, .05)) {
            final panel = (((a / 6.283) * 8 + 8.5) % 8).floor(),
                z = ztop - (ztop - zr) * (r / R0);
            final red = panel % 2 == 0, base = red ? UMB_RED : UMB_WHITE;
            final lit = math.cos(a - 3.93) * .5 + (r > R0 - .04 ? -.6 : 0);
            e.plot(
              ux + math.cos(a) * r,
              uy + math.sin(a) * r,
              z,
              e.rampOf(base)[e.clamp(_round(2.6 + lit), 1, 4)],
            );
          }
        }
        for (double a = 0; a < 6.283; a += .01) {
          e.plot(
            ux + math.cos(a) * (R0 + .01),
            uy + math.sin(a) * (R0 + .01),
            zr - .03,
            e.rgb(184, 48, 42),
          ); // the rim's valance
        }
        e.sphere(ux, uy, ztop + .04, .05, UMB_RED, 'solid');
        // its shade (the sun's: day and evening): on the cart only
        if (!NIGHT) UMBRELLA = (ux: ux, uy: uy, zr: zr, R0: R0);
      } else {
        for (double z = 1.8; z <= ztop - .05; z += .008) {
          final r = .1 * math.sin((z - 1.75) / (ztop - 1.75) * math.pi) + .02;
          for (double a = 0; a < 6.283; a += .05) {
            final red = (a / 6.283 * 4 + z * 2).floor() % 2 == 0;
            e.plot(
              ux + math.cos(a) * r,
              uy + math.sin(a) * r,
              z,
              e.rampOf(red ? UMB_RED : UMB_WHITE)[math.cos(a - .78) > 0
                  ? 3
                  : 2],
            );
          }
        }
        e.sphere(ux, uy, ztop + .02, .045, UMB_RED, 'solid');
      }
      // the body's shadow on the paving
      if (!NIGHT) {
        for (var y = y0 + .15; y <= y1 - .15; y += .25) {
          e.castShadow((x0 + x1) / 2, y, z1 * .6, .28);
        }
      }
    });
    for (var i = 0; i < W * H; i++) {
      if (e.zb[i] != before[i]) PART_TAGS_CART.add(i);
    }
  }

  // banco-set.html: umbrellaShade. The open umbrella's shade on the cart: every pixel of the cart (not the umbrella)
  // whose sun ray meets the canopy's disc takes the shadow's tint
  void umbrellaShade() {
    final U = UMBRELLA;
    if (U == null || PART_TAGS_CART.isEmpty) return;
    final ux = U.ux, uy = U.uy, zr = U.zr, R0 = U.R0;
    for (final i in PART_TAGS_CART) {
      final ix = i % W, iy = i ~/ W, d = e.zb[i];
      final kk = (iy + .5 - e.OY) / e.S,
          u = (ix + .5 - e.OX) / e.S,
          v = kk * e.SIN + d * e.COS,
          z = d * e.SIN - kk * e.COS;
      if (z > zr - .3) continue;
      final x = (u + v) / e.R2,
          y = (v - u) / e.R2,
          t = zr - z,
          hx = x - e.SHADOW_X * t - ux,
          hy = y - e.SHADOW_Y * t - uy;
      if (hx * hx + hy * hy < R0 * R0) e.tint(i, .62, .6, .78);
    }
  }

  /* ---------- the hedge and the gate ---------- */

  // banco-set.html: POST_PX, NOPOST_Z
  final Set<int> POST_PX = {};
  Float32List? NOPOST_Z;

  // banco-set.html: hedge
  void hedge() {
    k.part('seto', () {
      final yA = GATE_W[0][1], yB = GATE_W[1][1], xF = HEDGE_X;
      for (var y = yB - 4; y <= yA + NEAR_PIECE; y += .11) {
        if (y > yB - .1 && y < yA + .1) continue;
        if (y > yB - .1 && y < yA + .1) continue; // the opening
        for (double z = .05; z <= HEDGE_H; z += .11) {
          final h = e.hash(_round(y * 50), _round(z * 50));
          e.sphere(xF - .05, y, z, .1 + h * .05, LEAF[h > .7 ? 2 : 1], 'rough');
        }
        for (var x = xF - HEDGE_T; x <= xF; x += .11) {
          final h = e.hash(_round(x * 50) + 7, _round(y * 50));
          e.sphere(
            x,
            y,
            HEDGE_H - .04 + h * .05,
            .11 + h * .04,
            LEAF[h > .6 ? 3 : 2],
            'rough',
          );
        }
        // right of the gate, where nobody stands, the hedge is taller (it runs off the picture's right edge)
        if (y < yB - .5) {
          for (double z = HEDGE_H; z <= HEDGE_H_FAR; z += .11) {
            final h = e.hash(_round(y * 50) + 11, _round(z * 50));
            e.sphere(
              xF - .05,
              y,
              z,
              .1 + h * .05,
              LEAF[h > .7 ? 2 : 1],
              'rough',
            );
            if (z > HEDGE_H_FAR - .12) {
              for (var x = xF - HEDGE_T; x <= xF; x += .11) {
                e.sphere(
                  x,
                  y,
                  HEDGE_H_FAR + e.hash(_round(x * 50), _round(y * 50)) * .05,
                  .11,
                  LEAF[3],
                  'rough',
                );
              }
            }
          }
        }
      }
      // the hedge's cut ends at the opening
      for (var x = xF - HEDGE_T; x <= xF; x += .1) {
        for (double z = .05; z <= HEDGE_H; z += .1) {
          final h = e.hash(_round(x * 40), _round(z * 40));
          e.sphere(x, yB - .08, z, .09 + h * .04, LEAF[1], 'rough');
        }
      }
      // left of the gate the hedge ends at its post
      if (!NIGHT) {
        for (var y = yB - 4; y <= yA + NEAR_PIECE; y += .2) {
          if (y > yB - .1 && y < yA + .1) continue;
          e.castShadow(xF - HEDGE_T / 2, y, HEDGE_H * .5, .22);
        }
      }
    });
    final before = Float32List.fromList(e.zb);
    POST_PX.clear();
    NOPOST_Z = before;
    k.part('porton', () {
      for (final pw in GATE_W) {
        final x = pw[0], py = pw[1];
        b.block(
          x - POST_W,
          py - POST_W,
          0,
          x + POST_W,
          py + POST_W,
          POST_H,
          STONEP,
          [for (final v in STONEP) v * 1.08],
        );
        b.block(
          x - POST_W - .03,
          py - POST_W - .03,
          POST_H,
          x + POST_W + .03,
          py + POST_W + .03,
          POST_H + .09,
          [for (final v in STONEP) v * .96],
          [for (final v in STONEP) math.min(255, v * 1.12)],
        );
        e.sphere(x, py, POST_H + .19, .095, STONEP, 'solid');
        b.block(
          x - POST_W - .015,
          py - POST_W - .015,
          0,
          x + POST_W + .015,
          py + POST_W + .015,
          .18,
          [for (final v in STONEP) v * .8],
        );
        if (!NIGHT) {
          for (double z = .02; z <= .1; z += .04) {
            e.castShadow(x + .1, py, z, .14, 1, 0);
          }
        }
      }
    });
    for (var i = 0; i < W * H; i++) {
      if (e.zb[i] != before[i]) POST_PX.add(i);
    }
  }

  // banco-set.html: unOccludePosts. Where only a post made the ground's pixel occluded, the pixel is put back; where
  // others did too, it is occluded again by them alone (bakeOcclusion's rule)
  void unOccludePosts(Uint32List preAO) {
    if (POST_PX.isEmpty) return;
    final offsets = <List<int>>[];
    for (final r in const [2, 4]) {
      for (var kk = 0; kk < 8; kk++) {
        offsets.add([
          _round(math.cos(kk * math.pi / 4) * r),
          _round(math.sin(kk * math.pi / 4) * r * .7),
        ]);
      }
    }
    final pix = e.pix, zb = e.zb, gz = e.groundZ, ground = e.ground;
    final nz = NOPOST_Z!;
    for (final p in POST_PX) {
      final px = p % W, py = p ~/ W;
      for (var dy = -3; dy <= 3; dy++) {
        for (var dx = -4; dx <= 4; dx++) {
          final ix = px + dx, iy = py + dy, i = iy * W + ix;
          if (ix < 4 ||
              iy < 4 ||
              ix >= W - 4 ||
              iy >= H - 4 ||
              pix[i] == preAO[i] ||
              ground[i] == 0 ||
              zb[i] != gz[i]) {
            continue;
          }
          var other = 0;
          for (final o in offsets) {
            final j = (iy + o[1]) * W + ix + o[0];
            if (nz[j] != gz[j]) other++;
          }
          pix[i] = preAO[i];
          if (other >= 8) {
            e.tint(i, .56, .54, .72);
          } else if (other != 0 && other / 8 > e.bayerAt(ix, iy)) {
            e.tint(i, .74, .72, .84);
          }
        }
      }
    }
  }

  /* ---------- bake one state ---------- */

  // banco-set.html: buildSet
  void buildSet() {
    _tuftColours();
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
    CROWN_SHADE.clear();
    CROWN_PX.clear();
    POOL_PX.clear();
    POOL_IN.clear();
    var cache = _groundCaches[e];
    if (cache == null) {
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = bancoGround(g.x, g.y, ix, iy, i);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      e.growGrass();
      cache = _groundCaches[e] = _GroundCache(
        Uint32List.fromList(e.pix),
        Float32List.fromList(e.zb),
        Uint8List.fromList(e.kinds),
        Uint8List.fromList(e.ground),
        List.of(e.tufts),
      );
    } else {
      e.pix.setAll(0, cache.pix);
      e.zb.setAll(0, cache.zb);
      e.kinds.setAll(0, cache.kinds);
      e.ground.setAll(0, cache.ground);
      e.tufts.addAll(cache.tufts);
    }
    e.groundZ.setAll(0, e.zb);
    for (var i = 0; i < 3; i++) {
      smallTree(i);
    }
    pole();
    wire();
    lampPost();
    cart();
    for (var kk = 0; kk < 3; kk++) {
      bench(kk);
    }
    hedge();
    e.flushShadows();
    e.pendingShadows.clear();
    final preAO = Uint32List.fromList(e.pix);
    e.bakeOcclusion();
    unOccludePosts(preAO);
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    crownShades();
    umbrellaShade();
    e.shadeEdges();
    final L = LIGHT;
    if (L != null) k.lightPass(L.m, L.a, !L.litTufts);
    lampPool();
    final sky = SKY;
    k.skyFill((ix, iy) {
      final sun = sky.sun;
      if (sun != null) {
        final s = k.skyDisc(SUN[0], SUN[1], SUN[2], sun, ix, iy);
        if (s != 0) return s;
      }
      if (SET.luna) {
        final m = moonAt(ix, iy);
        if (m != 0) return m;
      }
      final c = cloudAt(ix, iy);
      if (c != 0) return c;
      final hl = k.skyHills(HZ, sky.far, sky.near, ix, iy);
      return hl != 0 ? hl : k.skyBands(sky.bands, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // banco-set.html: surfaceAt. The walkable surface under a screen point (rules.floor): the paving or the lawn (z 0)
  ({String on, double x, double y, double z}) surfaceAt(num sx, num sy) {
    final g = Gs(sx, sy, 0);
    return (
      on: sy < HZ ? 'sky' : groundKind(g[0], g[1]),
      x: g[0],
      y: g[1],
      z: 0,
    );
  }

  // banco-set.html: frame (what the reference made: the bake, then the wind at wind time [t], no characters). The
  // frame recipe (coqui_pixel's drawFrame) does the same each frame.
  void frame(double t) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final windT = e.STILL ? 0.0 : (t * e.WIND_FPS).floor() / e.WIND_FPS;
    e.drawLeaves(windT);
    e.drawTufts(windT);
    e.applyShadows(e.groundZ);
  }
}
