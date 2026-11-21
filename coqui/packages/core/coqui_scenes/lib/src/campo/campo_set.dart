// Port of docs/proyecto/pixel/campo-set.html: El campo's set, its one state, call for call (order 34a's set reference,
// order 34b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El campo's set is built on (campo-set.html: `window.PP_SCENE`, with the page's default origin, El
/// camino's, which is the sheet's): 240 × 216, S 26, origin (0, 4), shadows to (.9, -.1).
PpEngine campoEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 4,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The one state of the set (campo-set.html: `SET`, from the address). Every old state of the scene is this one baked
/// set (the sheet's `setKey`: the basket, the balls, the flower, the frog's puddle and the darkness of his shut eyes are
/// the sprite layer's). The page's `t` (wind time) is the frame's, not the state's; its `water=still` is a look
/// candidate, not a state: the sheet is made for `lake`, the only one ported.
class CampoState {
  const CampoState();

  /// campo-set.html's address (`?`, `?t=1.5`): it names no state, so every query is the one state.
  factory CampoState.fromQuery(String query) => const CampoState();

  /// A key of the sheet's `setKey` table (`"campo"`) read back.
  factory CampoState.fromKey(String key) {
    if (key != 'campo') {
      throw ArgumentError.value(key, 'key', 'not a key of El campo\'s set');
    }
    return const CampoState();
  }

  /// The sheet's key (`setKey.key`: "campo", one baked state).
  String get key => 'campo';
}

/// campo-set.html: `t`, the wind time in seconds a query gives (`?t=1.5`), 0 when it gives none.
double campoTimeOf(String query) {
  final q = Uri.splitQueryString(
    query.startsWith('?') ? query.substring(1) : query,
  );
  return double.tryParse(q['t'] ?? '') ?? 0;
}

/* ---------- the plan: every thing placed from its old screen point (the ground under it) ---------- */

const double HZ = 100; // the horizon (screen row): the old picture's
// the old tree: its foot, its crown's middle and radii on the screen, the fork where a ball sticks; Canelo's spot
const List<int> ARBOL = [60, 152],
    COPA = [60, 100, 30, 26],
    HORQ = [64, 116],
    SITIO = [46, 168];
const double TCROWN_CX = 63,
    TCROWN_CY = 99,
    CROWN_SH_R = .85; // the crown's middle on the screen; its shadow's radius (world)
const double WDEPTH = .16; // the surface under the lawn: a bank 4 rows high
// the reeds (round 3): a sparse row along the whole shore in the view, standing on the lip of the bank and just into the
// water (REED_X0 to REED_X1), from the screen's x REED_FROM to past the picture's right edge
const double REED_Y0 = 4.3, REED_Y1 = -.7, REED_FROM = 178;
const List<int> REED_LOW = [200, 178];
// the sky, the hills, the sun: El camino's (El frente's by day), the sun in the same place
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
const List<num> SUN = [38, 47, 9];
// the old picture's three clouds, moved clear of the corner board's place, of the sun, of the crown and of the answer
// cards' place in the sky (sheet moves: respEn)
const List<List<num>> CLOUDS = [
  [188, 12, .7],
  [204, 34, .8],
  [108, 10, .6],
];

/* ---------- the ground: the lawn (El frente's grass, calm, as El camino's), the crown's shade on it, the lake ---------- */
const double LAWN_T = 3.45;
const List<int> BLADE = [2, 2, 3, 3, 4];

/* ---------- the tree: El camino's kind ---------- */
const List<int> TRUNK = [118, 82, 50];
const List<List<int>> LEAF = [
  [52, 128, 66],
  [66, 148, 76],
  [86, 170, 88],
  [118, 196, 108],
];
// on the screen: its middle and radii; the hollow over the fork
const ({double cx, double cy, double rx, double ry}) TCROWN = (
  cx: TCROWN_CX,
  cy: TCROWN_CY,
  rx: 25,
  ry: 25,
);
const ({double cx, double cy, double rx, double ry}) HOLLOW = (
  cx: 64,
  cy: 111,
  rx: 10,
  ry: 9,
);

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

/// One reed (campo-set.html: an entry of `REEDS`).
typedef Reed = ({
  double x,
  double y,
  double h,
  double lean,
  bool head,
  bool blade,
  int k,
  List<int> foot,
});

/// The ground, its grass and the glints on its water (campo-set.html: `GROUND_CACHE`, and `LOOK.glints`, which only the
/// first bake fills): made once per page, so here once per engine.
class _GroundCache {
  _GroundCache(
    this.pix,
    this.zb,
    this.kinds,
    this.ground,
    this.tufts,
    this.glints,
  );

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
  final List<Glint> glints;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

/// The set of El campo, built into an engine (campo-set.html, from "the plan" to "bake the one state").
class CampoSet {
  CampoSet(this.e, this.b, [this.SET = const CampoState()]) : k = SetKit(e, b) {
    BANK = (556 - 344) / (e.S * e.R2);
    REED_X0 = BANK - .08;
    REED_X1 = BANK + .14;
    CROWN_SH = () {
      final f = Gs(ARBOL[0], ARBOL[1]),
          tv = (f[0] + f[1]) / e.R2,
          cu = (TCROWN_CX - e.OX) / e.S,
          zc = (e.OY + tv * e.SIN * e.S - TCROWN_CY) / (e.COS * e.S);
      final g = k.UVW(cu, tv),
          p = e.project(g[0] + e.SHADOW_X * zc, g[1] + e.SHADOW_Y * zc, 0),
          rx = CROWN_SH_R * e.S * 1.05;
      return (cx: p.sx, cy: p.sy, rx: rx, ry: rx * e.SIN + 1);
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
    );
    REEDS = _reeds();
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // campo-set.html: SET
  final CampoState SET;

  int get W => e.W;
  int get H => e.H;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // campo-set.html: Gs. The ground point under a screen point
  List<double> Gs(num sx, num sy) {
    final g = e.unproject(sx, sy);
    return [g.x, g.y, 0];
  }

  // campo-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  // the lake's shore (round 3): the line x = BANK (screen sx + 2 sy = 556)
  late final double BANK, REED_X0, REED_X1;

  // campo-set.html: shore. > 0 land; the shore wavers a little, along y
  double shore(double x, double y) =>
      BANK +
      .035 * math.sin(y * 2.3 + 1) +
      .025 * math.sin(y * 5.1) -
      x;

  // campo-set.html: cloudAt
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

  /* ---------- the ground ---------- */

  List<List<int>> get LAWN => e.GRASS;

  // campo-set.html, at load: the blades take the lawn's tones (tuftLit, tuftDark: this page's own copies of the engine's)
  void _tuftColours() {
    for (var kk = 0; kk < 5; kk++) {
      final c = LAWN[BLADE[kk]];
      e.tuftLit[kk] = _rgbOf(c);
      e.tuftDark[kk] = e.rgb(c[0] * .54, c[1] * .52, c[2] * .72);
    }
  }

  // campo-set.html: lawnAt
  int lawnAt(num x, num y, int ix, int iy, [int down = 0]) {
    final t =
        LAWN_T +
        (e.noise(x * .3, y * .3) - .5) * .6 +
        (e.bayerAt(ix, iy) - .5) * .8 +
        (e.hash(ix, iy) - .5) * .25;
    return _rgbOf(LAWN[e.clamp(t.floor(), 2, 4) - down]);
  }

  // the crown's shade (round 3): where the crown's shadow falls (castShadow's ellipse for the crown, no dither edge), the
  // lawn takes its own next darker tone
  late final ({double cx, double cy, double rx, double ry}) CROWN_SH;

  // campo-set.html: inCrownShade
  bool inCrownShade(int ix, int iy) {
    final dx = (ix + .5 - CROWN_SH.cx) / CROWN_SH.rx,
        dy = (iy + .5 - CROWN_SH.cy) / CROWN_SH.ry;
    return dx * dx + dy * dy <= 1;
  }

  // the water (round 2): lighter and bluer than round 1's; the bank's lip keeps its dark wet line
  late final WaterLook LOOK;

  // campo-set.html: GLINT
  late final int GLINT = e.rgb(236, 246, 252);

  // campo-set.html: campoGround. 0: the sky's; -1: the lake drew it (its own depth and kind)
  int campoGround(double x, double y, int ix, int iy, int i, Unprojected g) {
    if (iy + .5 < HZ) return 0; // above the horizon: the hills and the sky
    final s = shore(x, y);
    if (s < 0) {
      k.waterPixel(ix, iy, i, g, WDEPTH, shore, LOOK);
      return -1;
    }
    // the lip of the bank: a thin strip of damp earth, ragged into the lawn
    if (s < .07 && e.bayerAt(ix, iy) > s / .07 - .15) {
      e.kinds[i] = KIND_ROAD;
      return e.hash(ix, iy) > .5 ? e.rgb(168, 134, 88) : e.rgb(150, 118, 76);
    }
    e.kinds[i] = e.KIND_GRASS;
    return lawnAt(x, y, ix, iy, inCrownShade(ix, iy) ? 1 : 0);
  }

  /* ---------- the tree ---------- */

  // campo-set.html: tree
  void tree() {
    final f = Gs(ARBOL[0], ARBOL[1]),
        fx = f[0],
        fy = f[1],
        tu = (fx - fy) / e.R2,
        tv = (fx + fy) / e.R2;
    List<double> Pu(num u, num v, [num z = 0]) => k.UVW(u, v, z);
    final ZF = (ARBOL[1] - HORQ[1]) / (e.COS * e.S); // the fork's height
    double UX(num sx) => (sx - e.OX) / e.S;
    double ZS(num sy) => (e.OY + tv * e.SIN * e.S - sy) / (e.COS * e.S);
    k.part('arbol', () {
      e.capsule(
        Pu(tu, tv, 0),
        Pu(tu, tv, ZF + .15),
        .2,
        .16,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu - .22, tv, 0),
        Pu(tu + .22, tv, 0),
        .11,
        .11,
        (_) => TRUNK,
        'rough',
      ); // the flare of its roots
      // the fork: two limbs up into the crown, one to each side, a little back
      e.capsule(
        Pu(tu, tv, ZF - .05),
        Pu(tu - .5, tv - .08, ZF + .85),
        .14,
        .09,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu, tv, ZF - .05),
        Pu(tu + .48, tv - .08, ZF + .9),
        .14,
        .09,
        (_) => TRUNK,
        'rough',
      );
      e.capsule(
        Pu(tu, tv, ZF),
        Pu(tu + .04, tv - .35, ZF + 1),
        .1,
        .07,
        (_) => TRUNK,
        'rough',
      );
      // its shadow, one piece from its foot: the trunk's, cast up to the crown, then the crown's
      for (double z = .03; z < ZF + .3; z += .08) {
        e.castShadow(fx, fy, z, .17, 1, 0);
      }
      final zc = ZS(TCROWN.cy),
          ru = TCROWN.rx / e.S,
          rz = TCROWN.ry / (e.COS * e.S),
          rv = .75,
          cu = UX(TCROWN.cx);
      // the crown's own shadow: the shade the ground pass lays (CROWN_SH, round 3)
      const n = 300;
      for (var kk = 0; kk < n; kk++) {
        double h(int a, int bb) => e.hash(kk * 13 + 211 + a, bb);
        final th = h(1, 7) * 6.283,
            ph = math.acos(2 * h(2, 8) - 1),
            // Math.cbrt, as the porting table says
            d = math.pow(h(3, 9), 1 / 3) * .9;
        final du = math.cos(th) * math.sin(ph) * d,
            dv = math.sin(th) * math.sin(ph) * d,
            dz = math.cos(ph) * d;
        final u = cu + du * ru,
            v = tv + dv * rv,
            z = zc + dz * rz,
            r = .17 + h(5, 11) * .11;
        final q = Pu(u, v, z), c = e.project(q[0], q[1], q[2]);
        // the hollow over the fork: no cluster in front of the trunk's plane whose disc reaches into it
        final hx = (c.sx - HOLLOW.cx) / (HOLLOW.rx + r * e.S * .6),
            hy = (c.sy - HOLLOW.cy) / (HOLLOW.ry + r * e.S * .6);
        final inHollow = hx * hx + hy * hy < 1;
        if (dv > -.1 && inHollow) continue;
        final tone =
            h(4, 10) * .6 +
            dz * .5 -
            du * .25 +
            .3 -
            (dv < -.2 ? .25 : 0) -
            (inHollow ? .7 : 0); // in the hollow: the crown's inside, in its own shade
        e.sphere(
          q[0],
          q[1],
          q[2],
          r,
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
    });
  }

  /* ---------- the reeds ---------- */

  // campo-set.html: REEDS
  late final List<Reed> REEDS;

  List<Reed> _reeds() {
    final out = <Reed>[];
    var kk = 0;
    for (double y = REED_Y1; y <= REED_Y0; y += .2) {
      final clump = 1 + (e.hash(kk, 3) * 2).truncate();
      for (var j = 0; j < clump; j++) {
        final x = REED_X0 + e.hash(kk, j * 7 + 1) * (REED_X1 - REED_X0),
            yy = y + (e.hash(kk, j * 7 + 2) - .5) * .16,
            z0 = shore(x, yy) < 0 ? -WDEPTH : 0.0;
        final f = SCR(x, yy, z0);
        if (f[0] < REED_FROM) continue;
        // 16 to 25 rows tall, as the old; lower where REED_LOW says
        final h = math.min(
          .7 + e.hash(kk, j * 7 + 3) * .4,
          f[0] < REED_LOW[0] ? (f[1] - REED_LOW[1]) / (e.COS * e.S) : 9,
        );
        if (h < .4) continue;
        out.add((
          x: x,
          y: yy,
          h: h.toDouble(),
          lean: (e.hash(kk, j * 7 + 4) - .5) * .12,
          head: e.hash(kk, j * 7 + 5) < .6,
          blade: e.hash(kk, j * 7 + 6) < .15 && f[0] > REED_LOW[0] + 4,
          k: kk * 10 + j,
          foot: [(f[0] + .5).floor(), (f[1] + .5).floor()],
        ));
      }
      kk++;
    }
    return out;
  }

  // campo-set.html: reeds
  void reeds() {
    k.part('juncos', () {
      for (final r in REEDS) {
        final z0 = shore(r.x, r.y) < 0 ? -WDEPTH : 0.0,
            top = z0 + r.h,
            G =
                REED_G[r.k % 3 == 0
                    ? 0
                    : r.k % 3 == 1
                    ? 1
                    : 2];
        // the stalk: 1 px, a little lean towards x (the light side darker below)
        for (double z = z0; z <= top; z += .012) {
          final f = (z - z0) / r.h;
          e.plot(
            r.x + r.lean * f,
            r.y,
            z,
            _rgbOf(f < .3 ? REED_G[0] : G),
          );
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
        if (r.blade) {
          // a long blade from the foot, bending out along y
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
      // a short contact shadow at the foot of each reed on the land (on the water: the bank's reflection is enough)
      for (final r in REEDS) {
        if (shore(r.x, r.y) >= 0) e.castShadow(r.x, r.y, .02, .06, 1, 0);
      }
    });
  }

  /* ---------- bake the one state ---------- */

  // campo-set.html: buildSet. It also leaves the glints of the water in the engine (`glints`, `glintColour`), which the
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
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = campoGround(g.x, g.y, ix, iy, i, g);
          if (c == 0) continue;
          if (c == -1) continue; // the lake drew it (its own depth and kind)
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
        List.of(LOOK.glints!),
      );
    } else {
      e.pix.setAll(0, cache.pix);
      e.zb.setAll(0, cache.zb);
      e.kinds.setAll(0, cache.kinds);
      e.ground.setAll(0, cache.ground);
      e.tufts.addAll(cache.tufts);
    }
    e.groundZ.setAll(0, e.zb);
    tree();
    reeds();
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
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
    // the glints the frame draws (campo-set.html `frame`: drawGlints(LOOK.glints, windT, bakedZ, GLINT))
    e.glints
      ..clear()
      ..addAll(cache.glints);
    e.glintColour = GLINT;
  }

  // campo-set.html: frame (what the reference made: the bake, then the wind and the glints at wind time [t], no
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
