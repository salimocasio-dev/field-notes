// Port of docs/proyecto/pixel/lago-set.html: El lago's set, its one state, call for call (order 35a's set reference,
// order 35b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El lago's set is built on (lago-set.html: `window.PP_SCENE`, with the page's default origin, El camino's
/// and El campo's, which is the sheet's): 240 × 216, S 26, origin (0, 4), shadows to (.9, -.1).
PpEngine lagoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 4,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The one state of the set (lago-set.html: `SET`, from the address). Every old state of the scene is this one baked
/// set (the sheet's `setKey`: the bag, the row of bread, the flower, the brush and the sack are the sprite layer's).
/// The page's `t` (wind time) is the frame's, not the state's; its `dock=narrow` is a look candidate, not a state: the
/// sheet is made for `deck`, the only one ported.
class LagoState {
  const LagoState();

  /// lago-set.html's address (`?`, `?t=1.5`): it names no state, so every query is the one state.
  factory LagoState.fromQuery(String query) => const LagoState();

  /// A key of the sheet's `setKey` table (`"lago"`) read back.
  factory LagoState.fromKey(String key) {
    if (key != 'lago') {
      throw ArgumentError.value(key, 'key', 'not a key of El lago\'s set');
    }
    return const LagoState();
  }

  /// The sheet's key (`setKey.key`: "lago", one baked state).
  String get key => 'lago';
}

/// lago-set.html: `t`, the wind time in seconds a query gives (`?t=1.5`), 0 when it gives none.
double lagoTimeOf(String query) {
  final q = Uri.splitQueryString(
    query.startsWith('?') ? query.substring(1) : query,
  );
  return double.tryParse(q['t'] ?? '') ?? 0;
}

/* ---------- the plan: every thing placed from its old screen point ---------- */

const double HZ = 100; // the horizon (screen row): the park's
// the shore: the line x = BANK (screen sx + 2 sy = SHORE_K); the second shore, on the world's other axis: the right bank,
// the line y = BANK2 (screen sx - 2 sy = SHORE2_K)
const double SHORE_K = 354, SHORE2_K = -40;
const double WDEPTH = .16; // the surface under the lawn: a bank 4 rows high (El campo's)

// lago-set.html: BANK
double lagoBank(PpEngine e) => (SHORE_K - e.OX - 2 * e.OY) / (e.S * e.R2);

// lago-set.html: BANK2
double lagoBank2(PpEngine e) => (SHORE2_K - e.OX + 2 * e.OY) / -(e.S * e.R2);

// lago-set.html: shore. > 0 land (either bank), < 0 over the water (world units). The scene's sprite layer asks it too
// (lago-preview.html: `LAGO_SET.surfaceAt`)
double lagoShore(PpEngine e, double x, double y) => math.max(
  lagoBank(e) + .035 * math.sin(y * 2.3 + 1) + .025 * math.sin(y * 5.1) - x,
  lagoBank2(e) + .03 * math.sin(x * 2.1 + .5) + .02 * math.sin(x * 4.7) - y,
);

// the dock: its deck (top ZD, planks and fascia TH thick); the planks are PW wide, across the dock (long in y)
const double ZD = .28, TH = .15, PW = .25;

/// A rectangle on the ground, x0 to x1, y0 to y1 (lago-set.html: `DECK`, `LANDING`).
typedef LagoRect = ({double x0, double x1, double y0, double y1});

// lago-set.html: DECK (dock=deck; round 3: y0 1.32, so that the mooring posts stand 5 px inside its far edge)
LagoRect lagoDeck(PpEngine e) =>
    (x0: lagoBank(e) - .06, x1: 3.25, y0: 1.32, y1: 5.22);

// lago-set.html: LANDING
LagoRect lagoLanding(PpEngine e) {
  final D = lagoDeck(e);
  return (x0: -.45, x1: D.x0 + .01, y0: 3.82, y1: D.y1);
}

// lago-set.html: onDeck
bool lagoOnDeck(PpEngine e, double x, double y) {
  final DECK = lagoDeck(e), LANDING = lagoLanding(e);
  return (x >= DECK.x0 && x <= DECK.x1 && y >= DECK.y0 && y <= DECK.y1) ||
      (x >= LANDING.x0 &&
          x <= LANDING.x1 &&
          y >= LANDING.y0 &&
          y <= LANDING.y1);
}

// lago-set.html: Gs. The world point at height z under a screen point
List<double> lagoGs(PpEngine e, num sx, num sy, [num z = 0]) {
  final u = (sx - e.OX) / e.S, v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
  return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
}

/// What is under a screen point (lago-set.html: `surfaceAt`): the dock's planks, the lawn or the water's surface.
typedef LagoSurface = ({String on, double z, double x, double y});

// lago-set.html: surfaceAt. The walkable surface under a screen point: the deck's planks (z ZD), the lawn (z 0) or the
// water's surface (z -WDEPTH)
LagoSurface lagoSurfaceAt(PpEngine e, num sx, num sy) {
  final d = lagoGs(e, sx, sy, ZD);
  if (lagoOnDeck(e, d[0], d[1])) return (on: 'dock', z: ZD, x: d[0], y: d[1]);
  final g = lagoGs(e, sx, sy, 0);
  if (lagoShore(e, g[0], g[1]) >= 0 || sy < HZ) {
    return (on: 'lawn', z: 0, x: g[0], y: g[1]);
  }
  final w = lagoGs(e, sx, sy, -WDEPTH);
  return (on: 'water', z: -WDEPTH, x: w[0], y: w[1]);
}

// the mooring posts (the old PM): their tops at the old screen points, PM_H over the deck
const double PM_H = .26, PM_R = .085;
const List<List<int>> _PM_TOPS = [
  [40, 141],
  [133, 141],
];
// the post in the water (the old POSTE: its foot at POSTE[1] + 8, its top at POSTE[1] - 24): moved past the dock's end
const List<int> POSTE = [166, 156];
const double POST_R = .12;
// the reeds: a bed of them in the shallows at the right; clumps round these feet
const List<List<int>> JUNCOS = [
  [197, 161],
  [204, 160],
  [211, 162],
  [201, 167],
  [208, 166],
  [216, 164],
  [214, 171],
];
const List<double> REED_H = [.6, .25];
// the sky, the hills, the sun: El camino's and El campo's
const List<List<int>> _SKY_BANDS = [
      [58, 134, 230],
      [85, 159, 242],
      [120, 186, 250],
      [162, 211, 255],
      [208, 234, 255],
    ],
    _SKY_FAR = [
      [116, 180, 162],
      [156, 208, 188],
      [94, 158, 144],
    ],
    _SKY_NEAR = [
      [78, 158, 94],
      [124, 203, 122],
      [62, 136, 80],
    ],
    _SKY_SUN = [
      [220, 150, 30],
      [248, 200, 56],
      [255, 224, 112],
      [255, 244, 176],
    ];
const List<num> SUN = [31, 47, 8];
const List<List<num>> CLOUDS = [
  [188, 12, .7],
  [204, 34, .8],
  [108, 10, .6],
];

/* ---------- the ground ---------- */
const double LAWN_T = 3.45;
const List<int> BLADE = [2, 2, 3, 3, 4];
const List<double> SHADE_M = [.6, .6, .74];

/* ---------- the dock ---------- */
const List<int> WOOD = [170, 122, 74], WOOD_D = [128, 88, 52], PILE = [112, 80, 52];
const List<double> PLANK = [0, .55, .2, .8, .35, .05, .65, .25, .9, .45, .1, .7];
const double TH_P = .06;

/* ---------- the reeds ---------- */
const List<List<int>> REED_G = [
      [58, 104, 52],
      [92, 142, 62],
      [130, 170, 78],
    ],
    HEAD = [
      [88, 50, 24],
      [132, 80, 38],
    ];

/// One reed (lago-set.html: an entry of `REEDS`; [outer]: the frontmost of its clump, which has the waterline).
class LagoReed {
  LagoReed(
    this.x,
    this.y,
    this.h,
    this.lean,
    this.head,
    this.blade,
    this.k,
    this.foot,
  );

  final double x, y, h, lean;
  final bool head, blade;
  final int k;
  final List<int> foot;
  bool outer = false;
}

/// Where a thing standing in the water meets its surface (lago-set.html: an entry of `FEET`).
typedef LagoFoot = ({double x, double y, double hw, String what});

/// A waterline (lago-set.html: an entry of `WATERLINE`): what stands there, its foot on the screen, its half width and
/// the pixels it lit.
typedef LagoWaterline = ({String what, List<int> foot, double hw, List<int> px});

/// The ground, its grass, the dock's shade on the water and the glints on its water (lago-set.html: `GROUND_CACHE`,
/// `SHADED` and `LOOK.glints`, which only the first bake fills): made once per page, so here once per engine.
class _GroundCache {
  _GroundCache(
    this.pix,
    this.zb,
    this.kinds,
    this.ground,
    this.tufts,
    this.glints,
    this.shaded,
  );

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground, shaded;
  final List<Tuft> tufts;
  final List<Glint> glints;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: Math.fround
final Float32List _f32 = Float32List(1);
double _fround(num v) {
  _f32[0] = v.toDouble();
  return _f32[0];
}

/// The set of El lago, built into an engine (lago-set.html, from "the plan" to "bake the one state").
class LagoSet {
  LagoSet(this.e, this.b, [this.SET = const LagoState()]) : k = SetKit(e, b) {
    BANK = lagoBank(e);
    BANK2 = lagoBank2(e);
    DECK = lagoDeck(e);
    LANDING = lagoLanding(e);
    PM = [
      for (final t in _PM_TOPS)
        () {
          final g = Gs(t[0], t[1] + PM_H * e.COS * e.S, ZD);
          return (x: g[0], y: g[1], top: t);
        }(),
    ];
    POST = () {
      final g = Gs(POSTE[0], POSTE[1] + 8, -WDEPTH),
          topZ = -WDEPTH + 32 / (e.COS * e.S);
      return (x: g[0], y: g[1], top: topZ);
    }();
    LOOK = WaterLook(
      deep: const [46, 116, 156],
      shallow: const [70, 146, 166],
      bank: const [120, 92, 60],
      wet: const [52, 42, 34],
      sky: const [214, 238, 248],
      reflect: .12,
      fade: 1.4,
      glints: <Glint>[],
      noShade: true,
    );
    REEDS = _reeds();
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // lago-set.html: SET
  final LagoState SET;

  int get W => e.W;
  int get H => e.H;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // lago-set.html: Gs
  List<double> Gs(num sx, num sy, [num z = 0]) => lagoGs(e, sx, sy, z);

  // lago-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  late final double BANK, BANK2;
  late final LagoRect DECK, LANDING;
  late final List<({double x, double y, List<int> top})> PM;
  late final ({double x, double y, double top}) POST;

  // lago-set.html: shore
  double shore(double x, double y) => lagoShore(e, x, y);

  // lago-set.html: onDeck
  bool onDeck(double x, double y) => lagoOnDeck(e, x, y);

  // lago-set.html: cloudAt
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
        return iy + .5 > cy + 2 * s
            ? e.rgb(214, 230, 248)
            : e.rgb(244, 248, 255);
      }
    }
    return 0;
  }

  /* ---------- the ground: the lawn, the bank, the lake; the dock's shade on the water ---------- */

  List<List<int>> get LAWN => e.GRASS;

  // lago-set.html, at load: the blades take the lawn's tones (tuftLit, tuftDark)
  void _tuftColours() {
    for (var kk = 0; kk < 5; kk++) {
      final c = LAWN[BLADE[kk]];
      e.tuftLit[kk] = _rgbOf(c);
      e.tuftDark[kk] = e.rgb(c[0] * .54, c[1] * .52, c[2] * .72);
    }
  }

  // lago-set.html: lawnAt
  int lawnAt(num x, num y, int ix, int iy) {
    final t =
        LAWN_T +
        (e.noise(x * .3, y * .3) - .5) * .6 +
        (e.bayerAt(ix, iy) - .5) * .8 +
        (e.hash(ix, iy) - .5) * .25;
    return _rgbOf(LAWN[e.clamp(t.floor(), 2, 4)]);
  }

  // El campo's water (the same look), but no shadow is cast on its surface (look.noShade)
  late final WaterLook LOOK;

  // lago-set.html: SHADE_H, the dock's underside over the water
  double get SHADE_H => ZD - TH + WDEPTH;

  // lago-set.html: inShade
  bool inShade(double wx, double wy) =>
      onDeck(wx, wy) ||
      onDeck(wx - e.SHADOW_X * SHADE_H, wy - e.SHADOW_Y * SHADE_H);

  // lago-set.html: SHADED, the water in the dock's shade (made with the ground)
  late Uint8List SHADED;

  // lago-set.html: GLINT
  late final int GLINT = e.rgb(236, 246, 252);

  // lago-set.html: lagoGround. 0: the sky's; -1: the lake drew it (its own depth and kind)
  int lagoGround(double x, double y, int ix, int iy, int i, Unprojected g) {
    if (iy + .5 < HZ) return 0; // above the horizon: the hills and the sky
    final s = shore(x, y);
    if (s < 0) {
      k.waterPixel(ix, iy, i, g, WDEPTH, shore, LOOK);
      if (e.kinds[i] == KIND_WATER) {
        final wx = x - WDEPTH * k.WSTEP, wy = y - WDEPTH * k.WSTEP;
        if (inShade(wx, wy)) {
          final c = e.pix[i];
          e.pix[i] = e.rgb(
            (c & 255) * SHADE_M[0],
            (c >> 8 & 255) * SHADE_M[1],
            (c >> 16 & 255) * SHADE_M[2],
          );
          SHADED[i] = 1;
        }
      }
      return -1;
    }
    // the lip of the bank: a thin strip of damp earth, ragged into the lawn
    if (s < .07 && e.bayerAt(ix, iy) > s / .07 - .15) {
      e.kinds[i] = KIND_ROAD;
      return e.hash(ix, iy) > .5 ? e.rgb(168, 134, 88) : e.rgb(150, 118, 76);
    }
    e.kinds[i] = e.KIND_GRASS;
    return lawnAt(x, y, ix, iy);
  }

  /* ---------- the dock ---------- */

  // lago-set.html: plankTone
  double plankTone(int kk) =>
      PLANK[((kk.remainder(12)) + 12).remainder(12)];

  // lago-set.html: deckTop. One sample a pixel (planeQuad), the planks across the dock: a dark gap every PW along x, each
  // plank its own tone
  void deckTop(LagoRect R) {
    k.planeQuad([R.x0, R.y0, ZD], [R.x1 - R.x0, 0, 0], [0, R.y1 - R.y0, 0], (
      a,
      bb,
    ) {
      final x = R.x0 + a * (R.x1 - R.x0),
          y = R.y0 + bb * (R.y1 - R.y0),
          f = (x - DECK.x0 + 40 * PW) / PW,
          kk = f.floor(),
          fr = f - kk;
      if (fr < .14) return e.rampOf(WOOD)[0]; // the gap between two planks
      if (fr > .86) {
        return e.rampOf(WOOD)[1]; // its shaded edge, the same on every plank
      }
      // round 4: each plank one even tone along its whole length: its two wood tones mixed by a fixed dither
      final p = e.project(x, y, ZD);
      return e.rampOf(WOOD)[e.bayerAt(p.sx.floor(), p.sy.floor()) <
              plankTone(kk) * .85
          ? 3
          : 2];
    });
  }

  // lago-set.html: deckSides. The dock's edge on the two sides the camera sees: the plank ends (the top TH_P), the fascia
  // board under them
  void deckSides(LagoRect R, String sides) {
    const z0 = ZD - TH;
    if (sides.contains('y')) {
      k.planeQuad([R.x0, R.y1, z0], [R.x1 - R.x0, 0, 0], [0, 0, TH], (a, bb) {
        final x = R.x0 + a * (R.x1 - R.x0),
            z = z0 + bb * TH,
            f = (x - DECK.x0 + 40 * PW) / PW,
            kk = f.floor(),
            fr = f - kk;
        if (z > ZD - TH_P) {
          return fr < .14
              ? e.rampOf(WOOD)[0]
              : e.rampOf(WOOD)[e.clamp(
                  (2 + plankTone(kk) * .6).floor(),
                  1,
                  3,
                )]; // the plank ends
        }
        return e.rampOf(
          WOOD_D,
        )[z > ZD - TH_P - .025 ? 1 : 2]; // the fascia, a shadow line under the planks
      });
    }
    if (sides.contains('x')) {
      k.planeQuad([R.x1, R.y0, z0], [0, R.y1 - R.y0, 0], [0, 0, TH], (a, bb) {
        final z = z0 + bb * TH, y = R.y0 + a * (R.y1 - R.y0);
        if (z > ZD - TH_P) {
          return e.rampOf(WOOD)[e.clamp(
            (1.4 + e.noise(y * 3, 1) * .8).floor(),
            1,
            2,
          )]; // the end of the last plank
        }
        return e.rampOf(WOOD_D)[z > ZD - TH_P - .025 ? 0 : 1];
      });
    }
  }

  // lago-set.html: landingSides. Over the lawn the dock's side goes down to the ground (a solid landing)
  void landingSides(LagoRect R) {
    k.planeQuad(
      [R.x0, R.y1, 0],
      [R.x1 - R.x0, 0, 0],
      [0, 0, ZD - TH],
      (a, bb) => e.rampOf(WOOD_D)[1],
    );
  }

  // lago-set.html: FEET. Where a thing standing in the water meets its surface (round 2: their waterlines)
  final List<LagoFoot> FEET = [];

  // lago-set.html: piling. A square post from under the water up to the deck's underside, just inside the edge
  void piling(double x, double y, double z1, [double w = .13]) {
    const z0 = -WDEPTH - .5;
    FEET.add((x: x + w / 2, y: y + w / 2, hw: 2.5, what: 'piling'));
    k.planeQuad(
      [x - w / 2, y + w / 2, z0],
      [w, 0, 0],
      [0, 0, z1 - z0],
      (a, bb) => e.rampOf(PILE)[a < .3 ? 2 : 1],
    );
    k.planeQuad(
      [x + w / 2, y - w / 2, z0],
      [0, w, 0],
      [0, 0, z1 - z0],
      (a, bb) => e.rampOf(PILE)[0],
    );
  }

  // lago-set.html: mooringPost. A round post through the deck, PM_H over it, a darker cap; its contact shadow on the
  // planks
  void mooringPost(({double x, double y, List<int> top}) p) {
    k.drum(
      p.x,
      p.y,
      ZD,
      ZD + PM_H,
      PM_R,
      PILE,
      (dx, dy) => e.rampOf(PILE)[dx + dy < -.02 ? 3 : 2],
    );
    // from the ground point under its foot on the screen, as every shadow on the planks
    final f = SCR(p.x, p.y, ZD), g = Gs(f[0], f[1], 0);
    e.castShadow(g[0], g[1], .03, PM_R * 1.3, 1, 0);
  }

  // lago-set.html: dock
  void dock() {
    k.part('muelle', () {
      deckTop(DECK);
      deckTop(LANDING);
      deckSides(DECK, 'xy');
      deckSides(LANDING, 'y');
      landingSides(LANDING);
      // the part of the main deck that stands on the lawn: its side down to the ground too
      k.planeQuad(
        [DECK.x0, DECK.y1, 0],
        [math.max(0, BANK - DECK.x0), 0, 0],
        [0, 0, ZD - TH],
        (a, bb) => e.rampOf(WOOD_D)[1],
      );
      // the pilings along the near side and the end
      const zU = ZD - TH;
      for (var x = DECK.x0 + .55; x <= DECK.x1 - .05; x += .82) {
        piling(math.min(x, DECK.x1 - .07), DECK.y1 - .07, zU);
      }
      for (var y = DECK.y0 + .07; y <= DECK.y1 - .3; y += .82) {
        piling(DECK.x1 - .07, y, zU);
      }
      piling(DECK.x1 - .07, DECK.y1 - .07, zU);
    });
    k.part('muelle.postes', () {
      for (final p in PM) {
        mooringPost(p);
      }
    });
  }

  // lago-set.html: post
  void post() {
    k.part('poste', () {
      k.drum(
        POST.x,
        POST.y,
        -WDEPTH - .6,
        POST.top,
        POST_R,
        PILE,
        (dx, dy) => e.rampOf(PILE)[dx + dy < 0 ? 3 : 2],
      );
      // its front, where the camera sees it meet the water
      FEET.add((
        x: POST.x + POST_R * .7,
        y: POST.y + POST_R * .7,
        hw: 3.5,
        what: 'poste',
      ));
    });
  }

  /* ---------- the reeds (El campo's kind): stalks with brown heads, a few long blades, in the shallows ---------- */

  // lago-set.html: REEDS
  late final List<LagoReed> REEDS;

  List<LagoReed> _reeds() {
    final out = <LagoReed>[];
    var kk = 0;
    for (final s in JUNCOS) {
      final c = Gs(s[0], s[1], -WDEPTH);
      for (var j = 0; j < 5; j++) {
        final x = c[0] + (e.hash(kk, j * 7 + 1) - .5) * .4,
            y = c[1] + (e.hash(kk, j * 7 + 2) - .5) * .4,
            h = REED_H[0] + e.hash(kk, j * 7 + 3) * REED_H[1];
        final f = SCR(x, y, -WDEPTH);
        out.add(
          LagoReed(
            x,
            y,
            h,
            (e.hash(kk, j * 7 + 4) - .5) * .12,
            e.hash(kk, j * 7 + 5) < .6,
            e.hash(kk, j * 7 + 6) < .25,
            kk * 10 + j,
            [_round(f[0]), _round(f[1])],
          ),
        );
      }
      // round 3: the frontmost reed of each clump has the waterline
      final cl = out.sublist(out.length - 5);
      var f = cl[0];
      for (final r in cl) {
        if (r.x + r.y > f.x + f.y) f = r;
      }
      f.outer = true;
      kk++;
    }
    return out;
  }

  // lago-set.html: reeds
  void reeds() {
    k.part('juncos', () {
      for (final r in REEDS) {
        const z0 = -WDEPTH;
        final top = z0 + r.h, G = REED_G[r.k % 3];
        for (double z = z0; z <= top; z += .012) {
          final f = (z - z0) / r.h;
          e.plot(r.x + r.lean * f, r.y, z, _rgbOf(f < .3 ? REED_G[0] : G));
        }
        if (r.head) {
          final hz = top - .1;
          for (double z = hz - .18; z <= hz + .06; z += .01) {
            for (final w in const [-.016, .016]) {
              e.plot(
                r.x + r.lean * (z - z0) / r.h + w,
                r.y - w,
                z,
                _rgbOf(HEAD[z > hz - .04 && w < 0 ? 1 : 0]),
              );
            }
          }
        }
        if (r.outer) FEET.add((x: r.x, y: r.y, hw: 1, what: 'junco'));
        if (r.blade) {
          final s = r.k % 2 != 0 ? 1 : -1;
          for (double t = 0; t <= 1; t += .01) {
            e.plot(
              r.x + .04 * t,
              r.y + s * .22 * t * t,
              z0 + r.h * .75 * math.sin(t * 1.3),
              _rgbOf(REED_G[t > .5 ? 2 : 1]),
            );
          }
        }
      }
    });
  }

  /* ---------- round 2: the waterlines ---------- */

  // lago-set.html: WATERLINE
  final List<LagoWaterline> WATERLINE = [];

  // lago-set.html: waterlines. Where the post, a piling that shows and a reed meet the surface, a short line of the water's
  // own ripple light round its foot: only on the surface where it shows, never on the thing
  void waterlines() {
    WATERLINE.clear();
    final TAKEN = <int>{};
    final pix = e.pix, kinds = e.kinds, zb = e.zb, groundZ = e.groundZ;
    for (final ft in FEET) {
      final hw = ft.hw;
      final reed = ft.what == 'junco',
          p = e.project(ft.x, ft.y, -WDEPTH),
          px = <int>[],
          rx = hw + (reed ? 2.5 : 3),
          ry = reed ? .7 : 1.8; // a reed: one short dash, one row
      for (var iy = (p.sy - ry).floor(); iy <= (p.sy + ry).ceil(); iy++) {
        for (
          var ix = (p.sx - rx - 1).floor();
          ix <= (p.sx + rx + 1).ceil();
          ix++
        ) {
          if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
          final i = iy * W + ix,
              dx = (ix + .5 - p.sx) / rx,
              dy = (iy + .5 - p.sy) / ry;
          if (dx * dx + dy * dy > 1 ||
              (ix + .5 - p.sx).abs() < hw - .5 ||
              kinds[i] != KIND_WATER ||
              zb[i] != groundZ[i]) {
            continue;
          }
          // separate dashes, never a merged patch
          if (reed &&
              (TAKEN.contains(i - 1) ||
                  TAKEN.contains(i + 1) ||
                  TAKEN.contains(i - W) ||
                  TAKEN.contains(i + W) ||
                  TAKEN.contains(i - W - 1) ||
                  TAKEN.contains(i - W + 1) ||
                  TAKEN.contains(i + W - 1) ||
                  TAKEN.contains(i + W + 1))) {
            continue;
          }
          // the ripple light of the water as it is out of the dock's shade
          final c = pix[i];
          final u = SHADED[i] != 0 ? SHADE_M : const [1.0, 1.0, 1.0];
          pix[i] = e.rgb(
            e.lerp((c & 255) / u[0], LOOK.sky[0], .55),
            e.lerp((c >> 8 & 255) / u[1], LOOK.sky[1], .55),
            e.lerp((c >> 16 & 255) / u[2], LOOK.sky[2], .55),
          );
          px.add(i);
        }
      }
      TAKEN.addAll(px);
      WATERLINE.add((
        what: ft.what,
        foot: [_round(p.sx), _round(p.sy)],
        hw: hw,
        px: px,
      ));
    }
  }

  /* ---------- bake the one state ---------- */

  // lago-set.html: buildSet. It also leaves the glints of the water in the engine (`glints`, `glintColour`), which the
  // page's frame draws each frame (drawGlints, beside drawLeaves and drawTufts)
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
    var cache = _groundCaches[e];
    if (cache == null) {
      LOOK.glints!.clear();
      SHADED = Uint8List(W * H);
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = lagoGround(g.x, g.y, ix, iy, i, g);
          if (c == 0) continue;
          if (c == -1) continue; // the lake drew it (its own depth and kind)
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      // no glint in the dock's shade
      LOOK.glints!.removeWhere((gl) => SHADED[gl.i] != 0);
      e.growGrass();
      cache = _groundCaches[e] = _GroundCache(
        Uint32List.fromList(e.pix),
        Float32List.fromList(e.zb),
        Uint8List.fromList(e.kinds),
        Uint8List.fromList(e.ground),
        List.of(e.tufts),
        List.of(LOOK.glints!),
        SHADED,
      );
    } else {
      e.pix.setAll(0, cache.pix);
      e.zb.setAll(0, cache.zb);
      e.kinds.setAll(0, cache.kinds);
      e.ground.setAll(0, cache.ground);
      e.tufts.addAll(cache.tufts);
      SHADED = cache.shaded;
      LOOK.glints!
        ..clear()
        ..addAll(cache.glints);
    }
    e.groundZ.setAll(0, e.zb);
    // the deck's top: walked on, so it takes the characters' shadows like the ground (joinSlabs, after the occlusion)
    FEET.clear();
    final before = Float32List.fromList(e.zb);
    dock();
    for (var i = 0; i < W * H; i++) {
      if (e.zb[i] != before[i] && DECK_TOP(i)) k.slabTops.addAll([i, e.zb[i]]);
    }
    post();
    reeds();
    waterlines();
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.skyFill((ix, iy) {
      final s = k.skyDisc(SUN[0], SUN[1], SUN[2], _SKY_SUN, ix, iy);
      if (s != 0) return s;
      final c = cloudAt(ix, iy);
      if (c != 0) return c;
      final hl = k.skyHills(HZ, _SKY_FAR, _SKY_NEAR, ix, iy);
      return hl != 0 ? hl : k.skyBands(_SKY_BANDS, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
    // round 4: a glint registered by the ground pass where the dock, the post or a reed now stands is dropped
    LOOK.glints!.removeWhere(
      (gl) => !(e.kinds[gl.i] == KIND_WATER && e.bakedZ[gl.i] == e.groundZ[gl.i]),
    );
    // the glints the frame draws (lago-set.html `frame`: drawGlints(LOOK.glints, windT, bakedZ, GLINT))
    e.glints
      ..clear()
      ..addAll(LOOK.glints!);
    e.glintColour = GLINT;
  }

  // lago-set.html: DECK_TOP. A pixel of the deck's top: its depth is the plane z = ZD's at that pixel (the sides and the
  // posts are not)
  bool DECK_TOP(int i) {
    final ix = i % W, iy = i ~/ W, g = Gs(ix + .5, iy + .5, ZD);
    if (!onDeck(g[0], g[1])) return false;
    return (e.zb[i] - _fround(e.project(g[0], g[1], ZD).d)).abs() < 1e-3;
  }

  // lago-set.html: frame (what the reference made: the bake, then the wind and the glints at wind time [t], no
  // characters). The frame recipe (coqui_pixel's drawFrame) does the same each frame.
  void frame(double t) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final windT = e.STILL ? 0.0 : (t * e.WIND_FPS).floor() / e.WIND_FPS;
    e.drawLeaves(windT);
    e.drawTufts(windT);
    k.drawGlints(e.glints, windT, e.bakedZ, GLINT);
    e.applyShadows(e.groundZ);
  }
}
