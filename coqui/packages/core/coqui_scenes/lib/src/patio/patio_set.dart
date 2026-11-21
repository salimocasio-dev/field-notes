// Port of docs/proyecto/pixel/patio-set.html: El patio's set, every state, call for call (order 32a's set reference,
// order 32b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El patio's set is built on (patio-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (0, 4), shadows to (.9, -.1).
PpEngine patioEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 4,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (patio-set.html: `SET`, from the address). The values are the page's own strings.
class PatioState {
  const PatioState({this.hora = 'dia', this.door = 'shut', this.gate = 'shut'});

  static const List<String> HORAS = [
    'dia',
    'tarde',
    'tarde2',
    'ocaso',
    'crepusculo',
    'noche',
  ];

  /// patio-set.html: `pick('hora', ...)`, `pick('door', ...)`, `pick('gate', ...)`, from a query
  /// (`?hora=dia&door=shut&gate=shut`); a value the page does not allow takes its default, as there.
  factory PatioState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return PatioState(
      hora: pick('hora', HORAS, 'dia'),
      door: pick('door', const ['shut', 'open'], 'shut'),
      gate: pick('gate', const ['shut', 'open'], 'shut'),
    );
  }

  /// A key of the sheet's `setKey` table (`"dia-shut-shut"`: hora, door, gate) read back.
  factory PatioState.fromKey(String key) {
    final m = RegExp(
      r'^(dia|tarde|tarde2|ocaso|crepusculo|noche)-(shut|open)-(shut|open)$',
    ).firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', 'not a key of El patio\'s set');
    }
    return PatioState(hora: m[1]!, door: m[2]!, gate: m[3]!);
  }

  final String hora, door, gate;

  /// The sheet's key: hora + "-" + door + "-" + gate (`setKey.key`, e.g. "dia-shut-shut").
  String get key => '$hora-$door-$gate';
}

/* ---------- the plan (world units; x, y on the ground, z up). The yard is x > CX, y > CY ---------- */

// patio-set.html: P
List<num> P(num x, num y, [num z = 0]) => [x, y, z];

const List<int> TEAL = [92, 190, 186],
    WOOD = [150, 98, 56],
    WHITE = [244, 240, 228];
const List<int> FENCEW = [184, 128, 64],
    GATE = [251, 240, 210],
    SOIL = [122, 78, 42];

// round 3: rows the wall's and the fence's lines went up from round 2's
const double LIFT_W = 1, LIFT_F = 1;
// the far corner: the house wall's plane x = CX, the fence's plane y = CY
const double CX = -1.85 - LIFT_W / 18.385, CY = -1.55 - LIFT_F / 18.385;

// patio-set.html: AT. Along a line, from its plane's own coordinate, to screen x sx: x = CY + AT(sx), y = CX - AT(sx)
double AT(num sx) => (sx - 120) / 18.385;

// the house: its back wall on x = CX from its far corner (y = YH) down off the picture's left edge (y = YW); the back door
// in it. The wall's far end (screen x 76), its near end, its height: a strip of wall over the door
final double YH = CX - AT(76), YW = CX + 9.25;
const double HH = 3.24;
const double FLOOR = .1; // the house floor: one step up from the yard
// the door: width, height from the floor, its middle (y): screen x 52 (round 3)
const double DW = 1.5, DH = 2.55;
final double DM = CX - AT(52);
// its opening (D0 the far jamb, upper right on the screen); the white frame's width
final double D0 = DM - DW / 2, D1 = DM + DW / 2;
const double DF = .12;
// the stone step before it: x from, x to, y from, y to
final List<double> STEP = [CX, CX + .28, D0 - DF - .22, D1 + DF + .22];
// the roof: eaves out over the walls, the house's depth (x), the ridge over the eaves
const double EAVE = .25, HDEPTH = 3.2, RISE = .75;
// the fence: boards on y = CY from the corner to off the picture's right edge; the garden gate between two taller posts
const double FX0 = CX,
    FX1 = 6.4,
    FH = 1.33; // the fence's ends (x), its boards' height
// the gate's two posts: their middles (x; screen 133 and 159: round 3), half width, height
final double GP0 = CY + AT(133), GP1 = CY + AT(159);
const double GPW = .07, GPH = 1.9;
// the gate's opening (x); the leaf: height at its sides, its arched top's rise
final double GX0 = GP0 + GPW, GX1 = GP1 - GPW;
const double GH = 1.42, GARCH = .18;
// open (round 3), the leaf is swung INTO the yard on its left post, this far from shut (75 degrees)
const double GATE_OPEN = 78 * math.pi / 180;
final double PERCH = CY + AT(178); // the post the bird perches on (screen 178): its cap's top under its feet
// the fence's own posts (x): the first clear of the sun's way down
final List<double> POSTS = [CX + .25, PERCH, CY + 4.7, CY + 6.25, CY + 7.8];
// a post's half width, its cap's; the perch cap's top row (the bird's feet are on row 83)
const double POSTW = .07, CAPW = .15, PERCH_ROW = 84;
// the flamboyán: its trunk a little in front of the fence (screen x 204); its crown and the nest where the old ones were
const double TREE_OFF = .12; // round 3: the trunk against the fence
const double NEST_CLEAR = 58; // the crown's lowest row over the nest
// the two beds of earth (the old CAMA): ellipses on the lawn, their middles and radii on the screen as the old ones; five
// holes each
const Map<String, ({double sx, double sy})> BEDS = {
  'L': (sx: 68, sy: 186),
  'R': (sx: 172, sy: 186),
};
const double BED_RX = 28, BED_RY = 10;
final Map<String, List<List<int>>> HOLES = {
  'L': [
    for (var i = 0; i < 5; i++) [48 + i * 10, 186],
  ],
  'R': [
    for (var i = 0; i < 5; i++) [192 - i * 10, 186],
  ],
};
// beyond the yard: a field up to the horizon (screen row HZ), low hills behind it; they dip where the sun goes down
const double HZ = 84;

// patio-set.html: bump
double bump(num x, num c, num w) {
  final t = (x - c) / w;
  if (t * t >= 1) return 0;
  final q = 1 - t * t;
  return q * q;
}

// patio-set.html: hillFar, hillNear (round 3: a rise behind the gate, the path goes up it)
double hillFar(num x) =>
    HZ -
    1 -
    15 * bump(x, 30, 62) -
    20 * bump(x, 196, 74) -
    7 * bump(x, 146, 22);
double hillNear(num x) =>
    HZ + 1 - 7 * bump(x, 52, 40) - 9 * bump(x, 214, 46) - 17 * bump(x, 152, 30);

/* ---------- the hour ---------- */

/// patio-set.html: `SKIES`, top to the horizon, as the old cielo(n).
const Map<String, List<List<int>>> SKIES = {
  'dia': [
    [58, 134, 230],
    [85, 159, 242],
    [120, 186, 250],
    [162, 211, 255],
    [208, 234, 255],
  ],
  'tarde': [
    [78, 152, 236],
    [124, 184, 246],
    [176, 214, 250],
    [232, 226, 200],
    [252, 228, 168],
  ],
  'tarde2': [
    [106, 132, 208],
    [168, 146, 204],
    [232, 160, 136],
    [248, 180, 104],
    [255, 210, 124],
  ],
  'ocaso': [
    [52, 48, 110],
    [116, 68, 138],
    [196, 84, 108],
    [238, 116, 68],
    [255, 174, 60],
  ],
  'crepusculo': [
    [40, 38, 92],
    [92, 56, 118],
    [158, 72, 100],
    [200, 98, 70],
    [222, 146, 64],
  ],
  'noche': [
    [10, 14, 42],
    [16, 22, 62],
    [24, 32, 82],
    [34, 48, 106],
    [46, 62, 128],
  ],
};

/// patio-set.html: `LIGHTS`, the light of the hour on the set: c * m + a (set-kit.js lightPass).
const Map<String, Light?> LIGHTS = {
  'dia': null,
  'tarde': Light([.97, .95, .9], [10, 6, 0]),
  // El frente's dusk, less red on the lawn
  'tarde2': Light([.8, .86, .74], [24, 12, 6]),
  // round 2: the sun is down behind the hills: a dim light, a little warm, that leaves the lawn green
  'ocaso': Light([.74, .86, .88], [14, 4, 16]),
  // the dusk after it: dimmer and bluer, the lawn a grey green
  'crepusculo': Light([.62, .74, .86], [8, 6, 26]),
  'noche': Light([.56, .62, .82], [6, 10, 30]),
};

// two clouds (screen), by day and in the afternoon: in the sky, clear of the roof and the crown
const List<List<double>> CLOUDS = [
  [136, 14, 1],
  [64, -1, .8],
];

/// The hills: [body, lit crest, shade]; at dusk and at night silhouettes darker than the sky behind them.
typedef Hills = ({List<List<int>> far, List<List<int>> near});

const Hills _hillsNight = (
  far: [
    [44, 50, 56],
    [52, 58, 62],
    [38, 44, 52],
  ],
  near: [
    [30, 40, 24],
    [36, 48, 28],
    [26, 34, 22],
  ],
);
const Hills _hillsDusk = (
  far: [
    [104, 104, 118],
    [118, 112, 124],
    [92, 94, 110],
  ],
  near: [
    [62, 92, 70],
    [74, 104, 76],
    [54, 82, 64],
  ],
);
const Hills _hillsDay = (
  far: [
    [124, 178, 160],
    [160, 204, 182],
    [104, 158, 142],
  ],
  near: [
    [86, 150, 96],
    [122, 184, 118],
    [70, 130, 82],
  ],
);

/* ---------- the ground ---------- */

// round 4: the lawn is the same grass as El frente's and El balcón's lawns (the engine's GRASS ramp), calm
const double LAWN_T = 3.45;
const List<int> BLADE = [2, 2, 3, 3, 4];

// the hills behind everything, in the sky's place, at a far depth (sheet: behind)
const double HILL_Z = -1e7;

const List<int> TRUNK = [118, 76, 44];

// where the lawn stays plain (no white or yellow blooms in its grass): behind and round the beds' flowers, the crate,
// the ball's places
const List<List<int>> QUIET = [
  [30, 150, 80, 52],
  [130, 150, 80, 52],
  [96, 100, 48, 42],
  [138, 106, 52, 50],
];

// JavaScript: x % m, for a number of either sign
double _mod(num x, num m) => x.remainder(m).toDouble();

/// The ground and its grass (patio-set.html: `GROUND_CACHE`): made once per page, so here once per engine and per
/// ground the hour paints (the field and the path beyond the yard take their colours from it: day, dusk, night).
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<Map<String, _GroundCache>> _groundCaches =
    Expando<Map<String, _GroundCache>>();

/// The set of El patio in one state, built into an engine (patio-set.html, from "the plan" to "bake one state").
class PatioSet {
  PatioSet(this.e, this.b, this.SET) : k = SetKit(e, b) {
    TREE = [UX(204), (2 * CY + 2 * TREE_OFF + AT(204)) / e.R2];
    NEST = [UX(181), TREE[1] - .08];
    NEST_Z = (SY(TREE[1] - .08) - 68) / (e.COS * e.S);
    PATH_U = (GM - CY) / e.R2;
    PATH_V = (GM + CY) / e.R2;
    PATH_SX = e.OX + PATH_U * e.S;
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // patio-set.html: SET
  final PatioState SET;

  PpPalette get C => b.C;
  int get W => e.W;
  int get H => e.H;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // patio-set.html: UX, SY. Screen-aligned u, v (set-kit.js UVW): u of a screen x; row of (v, z)
  double UX(num sx) => (sx - e.OX) / e.S;
  double SY(num v, [num z = 0]) => e.OY + (v * e.SIN - z * e.COS) * e.S;

  // the flamboyán's trunk (screen-aligned u, v): its foot on the ground at y CY + TREE_OFF, screen x 204
  late final List<double> TREE;
  // the nest's middle on the screen at (181, 68), as the old one
  late final List<double> NEST;
  late final double NEST_Z;

  // the gate's middle (x): the path goes out from it; the path beyond the gate, out through it, then straight away from
  // the camera (along -x - y)
  final double GM = (GX0 + GX1) / 2;
  late final double PATH_U, PATH_V, PATH_SX;

  /* ---------- the hour ---------- */

  Light? get LIGHT => LIGHTS[SET.hora];
  List<List<int>> get SKY => SKIES[SET.hora]!;
  bool get DARK => const ['ocaso', 'crepusculo', 'noche'].contains(SET.hora);
  Hills get HILLS => SET.hora == 'noche'
      ? _hillsNight
      : const ['ocaso', 'crepusculo'].contains(SET.hora)
      ? _hillsDusk
      : _hillsDay;
  bool get DUSK => SET.hora == 'ocaso' || SET.hora == 'crepusculo';
  bool get NIGHT => SET.hora == 'noche';
  // the path up the hill: trodden earth
  List<int> get PATHC => NIGHT
      ? const [150, 140, 116]
      : DUSK
      ? const [140, 124, 98]
      : const [196, 176, 128];
  // the field: by day green; at dusk and at night darker than the sky over them
  List<List<int>> get FIELD => NIGHT
      ? const [
          [30, 46, 14],
          [36, 54, 18],
        ]
      : DUSK
      ? const [
          [60, 104, 54],
          [72, 116, 60],
        ]
      : const [
          [70, 128, 64],
          [88, 146, 70],
        ];
  String get _groundKind => NIGHT
      ? 'night'
      : DUSK
      ? 'dusk'
      : 'day';

  // the lawn's ramp: the engine's GRASS
  List<List<int>> get LAWN => e.GRASS;

  // patio-set.html, at load: the blades take the light of the hour as the lawn under them does (lit, set-kit.js), at
  // every hour (tuftLit, tuftDark: this page's own copies of the engine's)
  void _tuftColours() {
    for (var kk = 0; kk < 5; kk++) {
      final c = lit(LAWN[BLADE[kk]], LIGHT);
      e.tuftLit[kk] = _rgbOf(c);
      e.tuftDark[kk] = e.rgb(c[0] * .54, c[1] * .52, c[2] * .72);
    }
  }

  /* ---------- the ground: the lawn and the beds; beyond the yard the field (and through the gate a path) ---------- */

  // patio-set.html: lawnAt
  int lawnAt(num x, num y, int ix, int iy) {
    final t =
        LAWN_T +
        (e.noise(x * .3, y * .3) - .5) * .6 +
        (e.bayerAt(ix, iy) - .5) * .8 +
        (e.hash(ix, iy) - .5) * .25;
    return _rgbOf(LAWN[e.clamp(t.floor(), 2, 4)]);
  }

  // patio-set.html: inBed
  double inBed(int ix, int iy, String kk) {
    final bd = BEDS[kk]!,
        dx = (ix + .5 - bd.sx) / BED_RX,
        dy = (iy + .5 - bd.sy) / BED_RY,
        a = math.atan2(dy, dx);
    final q =
        1 +
        .04 * math.sin(a * 3 + (kk == 'L' ? 0 : 2)) +
        .03 * math.sin(a * 7 + 1) +
        (e.hash(ix, iy * 3) - .5) * .08;
    return (dx * dx + dy * dy) / (q * q);
  }

  // patio-set.html: bedEarth
  int bedEarth(int ix, int iy, String kk, double r) {
    final E = e.rampOf(SOIL), bd = BEDS[kk]!;
    for (final h in HOLES[kk]!) {
      final hx = (ix + .5 - h[0]) / 3.2,
          hy = (iy + .5 - h[1]) / 1.8,
          q = hx * hx + hy * hy;
      // the pit, its far lip in the light
      if (q <= 1) return hy < -.4 ? e.rgb(78, 48, 24) : e.rgb(28, 14, 6);
      if (q <= 1.8 && hy > .3) return E[3]; // the earth heaped on its near side
    }
    // the rim: thrown-up earth at the back, a dark foot at the front
    if (r > .88) return iy + .5 < bd.sy ? E[3] : e.rgb(50, 28, 12);
    // turned earth: lumps a few pixels across (value noise), each lit on its upper left and dark below; the bed mounded
    // (lighter at its crown)
    double n(num x, num y) => e.noise(x / 2.3 + (kk == 'L' ? 0 : 40), y / 1.5);
    final here = n(ix, iy), up = n(ix - .7, iy - 1);
    var t = 2 - r * 1.1 - (iy + .5 - bd.sy) / BED_RY * .35;
    if (here > .58) {
      t += here - up > .04
          ? -.9
          : 1; // a lump: its top lit, its underside in shade
    } else if (here < .3) {
      t -= .8; // a hollow between lumps
    }
    return E[e.clamp((t + (e.hash(ix, iy) - .5) * .5).floor(), 0, 4)];
  }

  // patio-set.html: patioGround
  int patioGround(double x, double y, int ix, int iy, int i) {
    if (x < CX && y > YH - .02) return 0; // under the house (its wall hides it)
    if (x < CX || y < CY) {
      // beyond the yard: the field, to the horizon
      if (iy + .5 < HZ) return 0;
      final u = (x - y) / e.R2, v = (x + y) / e.R2, pu = (u - PATH_U).abs();
      if (y < CY + .02 && v < PATH_V + .3 && pu < .21) {
        // the path: trodden earth, a darker edge, worn lighter down its middle
        e.kinds[i] = KIND_ROAD;
        final Pc = PATHC,
            ee = pu > .16
                ? .8
                : pu < .07
                ? 1.06
                : 1,
            h = 1 + (e.hash(ix, iy) - .5) * .1;
        return e.rgb(Pc[0] * ee * h, Pc[1] * ee * h, Pc[2] * ee * h);
      }
      final t = e.noise(x * .45, y * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
      return _rgbOf(
        FIELD[t > .55 ? 1 : 0],
      ); // no blades: they would stand as tall as the lawn's
    }
    for (final kk in const ['L', 'R']) {
      final r = inBed(ix, iy, kk);
      if (r > 1) continue;
      e.kinds[i] = KIND_ROAD;
      return bedEarth(ix, iy, kk, r);
    }
    e.kinds[i] = e.KIND_GRASS;
    return lawnAt(x, y, ix, iy);
  }

  // patio-set.html: hills
  // the hills behind everything, in the sky's place: drawn (after the set) only where nothing else is, at a far depth,
  // so the sky objects go behind them (sheet: behind) and the light of the hour falls on them
  void hills() {
    final zb = e.zb, pix = e.pix, Hl = HILLS;
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix, y = iy + .5;
        if (zb[i] > -1e8) continue;
        final yn = hillNear(ix + .5), yf = hillFar(ix + .5);
        List<num>? c;
        // the path from the gate goes on up the rise behind it, narrowing as it climbs, a little to the left at its top
        final ph = HZ + 1 - y,
            pw = 5.4 - ph * .3,
            pc = PATH_SX + 3 * math.sin(ph * .3) - ph * .25;
        if (y >= yn && y < HZ + 1 && pw > .9 && (ix + .5 - pc).abs() < pw) {
          c = (ix + .5 - pc).abs() > pw - 1
              ? Hl.near[2]
              : [for (final v in PATHC) v * (1 - ph * .012)];
        } else if (y >= yn) {
          c = y - yn < 1
              ? Hl.near[1]
              : e.bayerAt(ix, iy) < (y - yn) / 8
              ? Hl.near[2]
              : Hl.near[0];
        } else if (y >= yf) {
          c = y - yf < 1
              ? Hl.far[1]
              : e.bayerAt(ix, iy) < (y - yf) / 18
              ? Hl.far[2]
              : Hl.far[0];
        }
        if (c == null) continue;
        pix[i] = _rgbOf(c);
        zb[i] = HILL_Z;
      }
    }
  }

  /* ---------- the house ---------- */

  // patio-set.html: house
  void house() {
    final Tr = e.rampOf(TEAL), Wh = e.rampOf(WHITE);
    k.part('casa', () {
      // the back wall (faces +x, in shade as El frente's side wall): wooden siding (a darker line under each board), a
      // darker band at its foot, the shade under the eaves, the white corner board at its far end
      k.planeFace('x', CX, YH, YW, 0, HH, (a, z) {
        if (a > D0 && a < D1 && z < FLOOR + DH) return 0; // the doorway
        if (a < YH + .14) return Wh[1]; // the corner board
        if (z < .3 || z > HH - .16) return Tr[0];
        return b.shade(TEAL, _mod(z, .21) < .21 * .17 ? .5 : 1.3, a, z);
      });
      roof();
    });
    k.part('puerta', doorway);
    k.part(
      'escalon',
      () => k.slab(STEP[0], STEP[2], STEP[1], STEP[3], FLOOR, C.stone),
    );
  }

  // patio-set.html: roof
  // the roof: a hip roof, its ridge along y (the house's length), the hip over the far corner; red tiles in rows (El
  // frente's hipRoof look: the slope facing +x the darkest, the others a step lighter). Three flat slopes drawn pixel
  // by pixel (planeQuad), each cut at the hips
  void roof() {
    final R = e.rampOf(C.red), E = e.rampOf(WHITE);
    const ROW = .19, TILE = .3, z0 = HH;
    final xe = CX + EAVE,
        xw = CX - HDEPTH - EAVE,
        ye = YH - EAVE,
        run = (xe - xw) / 2,
        xr = xe - run,
        yfar = YW + 1;
    // along: up the slope from its eave; across: along the eave
    int tile(double along, double across, int base, bool cap, int kk) {
      final r = (along / ROW).floor(),
          t = _mod(along, ROW) / ROW,
          s = _mod(_mod(across / TILE + _mod(r, 2) * .5, 1) + 1, 1),
          n = (across / TILE + _mod(r, 2) * .5).floor();
      var lit = base;
      if (t < .22) {
        lit -= 1;
      } else if (s < .1) {
        lit -= 1;
      } else if (t > .8 && base > 1) {
        lit += 1;
      }
      final h = e.hash(n * 3 + r, r * 7 + kk);
      if (h > .9) {
        lit += 1;
      } else if (h < .07) {
        lit -= 1;
      }
      if (cap) lit = base + 2;
      return R[e.clamp(lit, 0, 4)];
    }

    // the slope facing +x (the yard): from the eave (xe, z0) up to the ridge (xr, z0 + RISE), from the hip down off the
    // picture
    k.planeQuad(P(xe, ye, z0), [0, yfar - ye, 0], [xr - xe, 0, RISE], (a, bb) {
      final y = ye + a * (yfar - ye), up = bb * run;
      if (up > y - ye + 1e-6) return 0; // past the hip
      return tile(up, y, 1, (up - (y - ye)).abs() < .05 || bb > .975, 0);
    });
    // the hip end over the far corner (faces -y): from the eave along y = ye up to the ridge's end
    k.planeQuad(P(xw, ye, z0), [xe - xw, 0, 0], [0, run, RISE], (a, bb) {
      final x = xw + a * (xe - xw), up = bb * run;
      if (up > math.min(xe - x, x - xw) + 1e-6) return 0;
      return tile(up, x, 2, (up - math.min(xe - x, x - xw)).abs() < .05, 50);
    });
    // the far slope (faces -x), seen over the ridge
    k.planeQuad(P(xw, ye, z0), [0, yfar - ye, 0], [run, 0, RISE], (a, bb) {
      final y = ye + a * (yfar - ye), up = bb * run;
      if (up > y - ye + 1e-6) return 0;
      return tile(up, y, 2, bb > .975, 90);
    });
    // the fascia: a white board along the eave over the yard, in front of the tiles' edge
    k.planeFace('x', xe + .01, ye, yfar, z0 - .12, z0, (a, z) => E[1]);
  }

  // patio-set.html: BACK, room
  // the room behind the open back door: a dim floor, the far wall and the side wall. Only what shows through the door
  static const double BACK = CX - 1.3;
  void room() {
    int wallC(num a, num z) {
      if (z < FLOOR + .16) return e.rgb(22, 14, 10);
      final kk = (z - FLOOR) / 2.6;
      return e.rgb(46 - kk * 18, 32 - kk * 14, 26 - kk * 10);
    }

    // inside the house only
    final y0 = math.max(D0 - .9, YH + .06), y1 = D1 + .2;
    // the far wall (faces +x)
    k.planeFace('x', BACK, y0, y1, FLOOR, FLOOR + DH + .4, wallC);
    // the side wall (faces +y)
    k.planeFace('y', y0, BACK, CX - .02, FLOOR, FLOOR + DH + .4, (a, z) {
      final c = wallC(a, z);
      return e.rgb(
        (c & 255) * 1.12,
        (c >> 8 & 255) * 1.12,
        (c >> 16 & 255) * 1.1,
      );
    });
    k.planeQuad(P(BACK, y0, FLOOR), [CX - .02 - BACK, 0, 0], [0, y1 - y0, 0], (
      a,
      bb,
    ) {
      final x = BACK + a * (CX - BACK);
      return _mod(x + 5, .22) < .03 ? e.rgb(30, 20, 14) : e.rgb(44, 30, 22);
    });
  }

  // patio-set.html: doorway
  void doorway() {
    const z0 = FLOOR, z1 = FLOOR + DH;
    final Fw = e.rampOf(WHITE), Wd = e.rampOf(WOOD);
    // the reveal: the wall's thickness seen through the opening (the far jamb, which faces +y, and the sill), in the
    // wall's shade
    k.revealX(CX, D0, D1, z0, z1, .22, [for (final v in TEAL) v * .45]);
    if (SET.door == 'open') room();
    // t: from the hinge (the far jamb, D0) to the knob's edge
    int panel(num t, num z) {
      final uu = t * DW,
          edge = uu < .08 || uu > DW - .08 || z < z0 + .08 || z > z1 - .08;
      final inPanel =
          uu > .2 &&
          uu < DW - .2 &&
          ((z > z0 + .3 && z < z0 + 1.1) || (z > z0 + 1.3 && z < z1 - .25));
      final rim =
          inPanel &&
          (uu < .26 ||
              uu > DW - .26 ||
              (z - (z0 + .3)).abs() < .06 ||
              (z - (z0 + 1.1)).abs() < .06 ||
              (z - (z0 + 1.3)).abs() < .06 ||
              (z - (z1 - .25)).abs() < .06);
      return edge || rim
          ? 0
          : inPanel
          ? 2
          : 1;
    }

    if (SET.door == 'shut') {
      // in the opening, a little behind the wall's face, in shade as the wall; the knob at the near side
      k.planeFace('x', CX - .06, D0, D1, z0, z1, (a, z) {
        final t = (a - D0) / DW;
        if (t > (DW - .22) / DW &&
            t < (DW - .12) / DW &&
            (z - z0 - 1.15).abs() < .05) {
          return e.rgb(250, 210, 80);
        }
        return Wd[panel(t, z)];
      });
    } else {
      // open: the leaf swung in on the near jamb (left on the screen), back towards the inside of the wall: only its
      // edge and a sliver of its face at the opening's left, the dark room filling the doorway
      k.leaf(
        CX - .06,
        D1 - .03,
        DW,
        z0,
        z1,
        math.pi + 1.42,
        (t, z) => t > .94 ? Wd[0] : Wd[math.max(0, panel(t, z) - 1)],
      );
    }
    // the white frame round the opening, on the wall's face
    const fz1 = z1 + DF;
    k.planeFace('x', CX + .03, D0 - DF, D0, 0, fz1, (a, z) => Fw[2]);
    k.planeFace('x', CX + .03, D1, D1 + DF, 0, fz1, (a, z) => Fw[2]);
    k.planeFace('x', CX + .03, D0 - DF, D1 + DF, z1, fz1, (a, z) => Fw[2]);
  }

  /* ---------- the fence and the gate ---------- */

  // patio-set.html: post
  // a square post with a flat cap (the cap's top takes a perching bird's feet): block()'s faces, +y lit, +x in shade
  void post(num x, num y, num h, num cap, List<num> c) {
    b.block(x - POSTW, y - POSTW, 0, x + POSTW, y + POSTW, h, c, c);
    b.block(x - cap, y - cap, h, x + cap, y + cap, h + .07, c, [
      for (final v in c) math.min(255, v * 1.12),
    ]);
  }

  // patio-set.html: capTop
  // the height of a cap's top that puts its far corner (its highest point on the screen) on row PERCH_ROW
  double capTop(num x, num y) =>
      (e.OY + (x + y - 2 * CAPW) / e.R2 * e.SIN * e.S - PERCH_ROW) /
      (e.COS * e.S);

  // patio-set.html: fence
  void fence() {
    final Fr = e.rampOf(FENCEW);
    k.part('cerca', () {
      // the boards: 7 px wide (x .38), a dark gap between them, their tops cut a little unevenly; two rails across
      // their fronts
      const BW = 7 / 18.385,
          rails = [
            [.36, .46],
            [.92, 1.02],
          ];
      double top(int kk) =>
          FH +
          ((kk * 7).remainder(3) == 0
              ? .04
              : (kk * 5).remainder(4) == 1
              ? -.05
              : 0);
      for (final span in [
        [FX0, GP0 - GPW],
        [GP1 + GPW, FX1],
      ]) {
        final x0 = span[0], x1 = span[1];
        k.planeFace('y', CY, x0, x1, 0, FH + .1, (a, z) {
          final kk = ((a + 10) / BW).floor(), f = (a + 10) / BW - kk;
          if (z > top(kk)) return 0;
          if (f > .86) return Fr[0]; // the gap
          return Fr[e.clamp(
            (2.6 +
                    (f < .16 ? .8 : 0) -
                    (z < .25 ? .6 : 0) +
                    (e.hash(kk, 3) - .5) * .7 +
                    (e.bayerAt((a * 400).truncate(), (z * 90).truncate()) -
                            .5) *
                        .4)
                .floor(),
            0,
            4,
          )];
        });
        // the boards' tops (their thickness, seen from above)
        for (num a = x0; a < x1; a += BW) {
          final kk = ((a + 10 + BW / 2) / BW).floor(),
              a2 = math.min(x1, a + BW * .86);
          k.planeQuad(
            P(a, CY - .07, top(kk)),
            [a2 - a, 0, 0],
            [0, .07, 0],
            (_, _) => Fr[4],
          );
        }
        for (final rail in rails) {
          final z0 = rail[0], z1 = rail[1];
          k.planeFace(
            'y',
            CY + .05,
            x0,
            x1,
            z0,
            z1,
            (a, z) => Fr[z > z0 + (z1 - z0) * .7 ? 3 : 1],
          );
          k.planeQuad(
            P(x0, CY, z1),
            [x1 - x0, 0, 0],
            [0, .05, 0],
            (_, _) => Fr[4],
          );
        }
      }
      // the posts, in front of the boards, a little taller, with caps; the perch's cap has its top at row PERCH_ROW
      for (final x in POSTS) {
        const y = CY + .07;
        final h = x == PERCH ? capTop(x, y) - .07 : FH + .04;
        post(x, y, h, CAPW, FENCEW);
      }
    });
    k.part('porton', () {
      // the two gate posts, taller, with caps
      for (final x in [GP0, GP1]) {
        post(x, CY + .02, GPH, GPW + .04, FENCEW);
      }
      // the leaf: cream boards, an arched top, two rails, the yellow latch at the far post. Open (round 3), it is swung
      // into the yard on its left post, GATE_OPEN from shut: its face is seen, its latch out at its free edge; the
      // opening is empty and the path is seen through it
      final G = e.rampOf(GATE), gw = GX1 - GX0, open = SET.gate == 'open';
      // t: from the hinge (the left post) to the latch
      int leafCol(num t, num z) {
        final uu = t * gw,
            kk = (uu / (gw / 6)).floor(),
            f = uu / (gw / 6) - kk,
            arch = GH + GARCH * math.sin(math.pi * t),
            d = open ? 1 : 0;
        if (z > arch) return 0;
        if (arch - z < .05) return G[1]; // the arch's edge
        if ((z - .55).abs() < .05 || (z - 1.05).abs() < .05) {
          return G[2 - d]; // the rails
        }
        if (t > .8 && t < .92 && z > .76 && z < .9) {
          return e.rgb(244, 196, 56); // the latch
        }
        return G[(f > .85
                ? 1
                : f < .14
                ? 4
                : 3) -
            d];
      }

      if (!open) {
        k.planeFace(
          'y',
          CY - .03,
          GX0,
          GX1,
          .05,
          .05 + GH + GARCH,
          (a, z) => leafCol((a - GX0) / gw, z - .05),
        );
      } else {
        final dx = math.cos(GATE_OPEN) * gw, dy = math.sin(GATE_OPEN) * gw;
        k.planeQuad(
          P(GX0, CY + .02, .05),
          [dx, dy, 0],
          [0, 0, GH + GARCH],
          (a, bb) => leafCol(a, bb * (GH + GARCH)),
        );
        // its shadow on the lawn
        for (num t = .1; t <= 1; t += .15) {
          for (num z = .2; z <= GH; z += .3) {
            e.castShadow(GX0 + dx * t, CY + .02 + dy * t, z, .1);
          }
        }
      }
    });
  }

  /* ---------- the flamboyán, its branch and the nest (screen-aligned u, v: set-kit.js UVW) ---------- */

  // patio-set.html: tree
  void tree() {
    final tu = TREE[0], tv = TREE[1];
    List<double> Pu(num u, num v, [num z = 0]) => k.UVW(u, v, z);
    // the trunk's top: row 58 over its foot, under the crown
    final TOP = (SY(tv) - 58) / (e.COS * e.S);
    k.part('arbol', () {
      // the trunk, a flare at its foot, two limbs into the crown
      e.capsule(
        Pu(tu, tv, 0),
        Pu(tu - .05, tv, TOP),
        .26,
        .2,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu - .2, tv, 0),
        Pu(tu + .2, tv, 0),
        .16,
        .16,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu - .05, tv, TOP - .1),
        Pu(tu - .7, tv - .1, TOP + .7),
        .15,
        .1,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu - .05, tv, TOP - .1),
        Pu(tu + .6, tv - .2, TOP + .8),
        .15,
        .1,
        (_) => TRUNK,
        'rough',
      );
      // patio-set.html: `castShadow(...Pu(tu, tv), z, .2)`. Pu gives three numbers (x, y and its z, 0), so the call is
      // castShadow(x, y, 0, z, .2): height 0, radius z, strength .2, which the shadow mask (a Uint8Array) stores as 0.
      // Ported as it is: strength 0, so it marks nothing, as there
      for (num z = .2; z < TOP; z += .3) {
        final p = Pu(tu, tv);
        e.castShadow(p[0], p[1], p[2], z, (.2).truncate());
      }
      // the crown: leaf clusters that sway (as growTree's), in three lobes as the old one, the flamboyán's red and orange
      // flowers on its outside
      const lobes = [
        [204, 34, 38, 27, 300],
        [184, 46, 16, 13, 60],
        [229, 48, 17, 14, 60],
      ];
      final cv = tv - .1;
      const LEAF = [
            [62, 150, 84],
            [84, 176, 96],
            [118, 204, 112],
          ],
          FLOWER = [
            [240, 80, 64],
            [248, 134, 64],
          ];
      var n = 0;
      for (final lobe in lobes) {
        final sx = lobe[0], sy = lobe[1], rx = lobe[2], ry = lobe[3];
        final count = lobe[4];
        final cu = UX(sx),
            cz = (SY(cv) - sy) / (e.COS * e.S),
            ru = rx / e.S,
            rz =
                math.sqrt(
                  math.max(
                    .01,
                    ry * ry - (ru * e.S * e.SIN) * (ru * e.S * e.SIN),
                  ),
                ) /
                (e.COS * e.S);
        for (var kk = 0; kk < count; kk++, n++) {
          final a = e.hash(n, 7) * 6.283,
              tilt = e.hash(n, 8) * 2 - 1,
                  // Math.cbrt, as the porting table says
                  d =
                  math.pow(e.hash(n, 9), 1 / 3) * .92,
              flat = math.sqrt(1 - tilt * tilt);
          final du = math.cos(a) * flat * d,
              dv = math.sin(a) * flat * d,
              dz = tilt * d;
          final pu = cu + du * ru, pv = cv + dv * ru, pz = cz + dz * rz;
          final outside = d > .55 && (dz > -.35 || dv > .1),
              fl = outside && e.hash(n, 12) < .5;
          final tone = e.hash(n, 10) + dz * .35 + (dv + du * -.3) * .2;
          final col = fl
              ? FLOWER[e.hash(n, 13) < .6 ? 0 : 1]
              : LEAF[tone > .78
                    ? 2
                    : tone > .35
                    ? 1
                    : 0];
          e.capture = <num>[];
          final q = Pu(pu, pv, pz);
          e.sphere(
            q[0],
            q[1],
            q[2],
            (fl ? .13 : .17 + e.hash(n, 11) * .16),
            lit(col, LIGHT),
            fl ? 'solid' : 'rough',
          );
          // over the nest the crown stops at row NEST_CLEAR, and on its left it stops at x 166
          final px = e.capture!;
          final kept = <num>[];
          for (var m = 0; m < px.length; m += 4) {
            if (!(px[m + 1] > NEST_CLEAR && px[m] >= 166 && px[m] <= 196) &&
                px[m] >= 166) {
              kept.addAll([px[m], px[m + 1], px[m + 2], px[m + 3]]);
            }
          }
          // k odd: the leaves cast no shadow (round 3); the trunk's is kept
          final g = Pu(pu, pv);
          e.leaves.add(
            Leaf(x: g[0], y: g[1], z: pz, k: n * 2 + 1, r: .3, pixels: kept),
          );
          e.capture = null;
        }
      }
    });
    // the branch to the nest, and the nest (a bowl of twigs): baked, still, so the bird sits on it
    k.part('nido', () {
      final nu = NEST[0], nv = NEST[1], nz = NEST_Z;
      e.capsule(
        Pu(tu - .1, tv - .02, nz - .45),
        Pu(nu + .25, nv - .02, nz - .2),
        .09,
        .07,
        (_) => TRUNK,
        'rough',
      );
      const N = [
        [96, 62, 32],
        [132, 90, 50],
        [160, 116, 66],
      ];
      for (num a = 0; a < 6.283; a += .12) {
        for (num r = .1; r <= .35; r += .05) {
          for (num h = -.14; h <= 0; h += .035) {
            final rr = r * (1 + h * 1.2),
                col =
                    N[e.clamp(
                      (e.hash((a * 30).truncate(), (h * 99).truncate()) * 2.4 +
                              (r > .3 ? .6 : 0))
                          .floor(),
                      0,
                      2,
                    )];
            if (r < .3 && h > -.02) continue; // the hollow
            final p = Pu(
              nu + math.cos(a) * rr,
              nv + math.sin(a) * rr * .9,
              nz + h,
            );
            e.plot(p[0], p[1], p[2], _rgbOf(col));
          }
        }
      }
      for (num a = 0; a < 6.283; a += .2) {
        for (num r = 0; r < .3; r += .05) {
          final p = Pu(
            nu + math.cos(a) * r,
            nv + math.sin(a) * r * .9,
            nz - .04,
          );
          e.plot(p[0], p[1], p[2], e.rgb(48, 26, 12));
        }
      }
      // patio-set.html: `castShadow(...Pu(nu, nv), nz, .3)`: castShadow(x, y, 0, nz, .3), strength .3 stored as 0, as
      // the trunk's above: it marks nothing
      final p = Pu(nu, nv);
      e.castShadow(p[0], p[1], p[2], nz, (.3).truncate());
    });
  }

  /* ---------- bake one state ---------- */

  // patio-set.html: buildSet
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
    final caches = _groundCaches[e] ??= {};
    final cache = caches[_groundKind];
    if (cache == null) {
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = patioGround(g.x, g.y, ix, iy, i);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      e.growGrass();
      caches[_groundKind] = _GroundCache(
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
    // after sunset the grass has no flowers: a white or yellow bloom on a dark lawn reads as a firefly; and none, at any
    // hour, behind the beds' flowers, the crate's and the ball's places
    bool calm(int x, int y) => QUIET.any(
      (r) => x >= r[0] && x < r[0] + r[2] && y >= r[1] && y < r[1] + r[3],
    );
    final tufts = e.tufts, dark = DARK;
    for (var kk = 0; kk < tufts.length; kk++) {
      final t = tufts[kk];
      if (t.bloom != 0 && (dark || calm(t.ix, t.iy))) {
        tufts[kk] = Tuft(
          ix: t.ix,
          iy: t.iy,
          i: t.i,
          height: t.height,
          base: t.base,
          phase: t.phase,
          bloom: 0,
        );
      }
    }
    e.groundZ.setAll(0, e.zb);
    house();
    fence();
    tree();
    // the shadows: the fence's along its foot (it is low), the gate posts'; the house's kept behind it
    for (num x = FX0 + .1; x <= FX1; x += .25) {
      for (num z = .2; z <= FH; z += .3) {
        e.castShadow(x, CY - .04, z, .16);
      }
    }
    for (final x in [GP0, GP1]) {
      for (num z = .2; z <= GPH; z += .3) {
        e.castShadow(x, CY + .02, z, .1);
      }
    }
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    hills();
    final L = LIGHT;
    if (L != null)
      k.lightPass(L.m, L.a, false); // (the blades are lit already: tuftLit)
    final day = SET.hora == 'dia' || SET.hora == 'tarde', sky = SKY;
    k.skyFill((ix, iy) {
      if (day) {
        for (final cl in CLOUDS) {
          final cx = cl[0], cy = cl[1], s = cl[2];
          bool el(num x0, num y0, num rx, num ry) {
            final dx = (ix + .5 - x0) / rx, dy = (iy + .5 - y0) / ry;
            return dx * dx + dy * dy <= 1;
          }

          if (el(cx, cy, 13 * s, 5 * s) ||
              el(cx - 9 * s, cy + 2, 8 * s, 4 * s) ||
              el(cx + 10 * s, cy + 2, 9 * s, 4 * s)) {
            return iy + .5 > cy + 2 * s
                ? e.rgb(214, 230, 248)
                : e.rgb(244, 248, 255);
          }
        }
      }
      return k.skyBands(sky, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
