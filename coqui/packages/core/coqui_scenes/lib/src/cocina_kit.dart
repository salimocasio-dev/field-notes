// Port of docs/proyecto/pixel/cocina-kit.js: La cocina's shared kit (orders 37, 38, 39: La mesa, La estufa, La nevera;
// A comer later), call for call. The room is one room seen in three scenes: the same floor, walls, tile band, counters
// and cupboards, window, light and scale. The kit only grows: a function added to cocina-kit.js is added here with the
// same name and parameters, and what a function here draws never changes. The old file's names are kept, capitals
// included, so the port reads line for line against it (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/* ---------- the room's numbers ---------- */

/// cocina-kit.js: `K`. The room's numbers, in world units. One object, as the page's: a set may change a number for one
/// call and put it back (estufa-set.html's `base()` sets `K.CD` to its run's depth around `cocinaBase`).
class CocinaK {
  double
  T = .22,
  WH = 3.2; // the walls' thickness and the height they are cut at (La sala's)
  double TILE = .5; // a floor tile (La sala's porch tiles are .5 too)
  double CZ = 1.3; // the counter's top surface: what stands on a counter stands at z = K.CZ
  double CTOP = .08, COVER = .05; // the counter top's thickness and how far it overhangs the cupboard's front
  double CD = .9; // a base cupboard's depth from the wall, its top included
  double PLINTH = .12, PLINTH_IN = .06; // the dark kick under a base cupboard: its height and how far it is set back
  // the pale blue tile band on the wall behind the counters: from z BAND0 to BAND1, tiles BTILE square
  double BAND0 = 1.3, BAND1 = 2.2, BTILE = .26;
  double UZ0 = 2.32,
      UZ1 = 3.02,
      UD = .46; // a wall cupboard: its bottom and top, its depth
  double STW = 1.06, SD = .9; // the stove: its width along the wall and its depth (its top is at K.CZ, as the counters')
  // the hood's canopy: bottom and top, depth; its chimney runs from HZ1 up to the cut top
  double HZ0 = 2.36, HZ1 = 2.62, HD = .62;
  double SKIRT = .13; // the skirting board at the foot of the walls
  double OUTD = 1.7; // how far behind a wall's outer face the outside (the patio, its bush, the sky) stands
  // above the cut walls: La sala's flat dark grey
  List<int> BACKDROP = const [38, 36, 44];
}

/// cocina-kit.js: `K`.
final CocinaK K = CocinaK();

/// cocina-kit.js: `KC`. The room's colours (`[r, g, b]`; the old pictures' where they had them).
abstract final class KC {
  static const List<int> plaster = [246, 236, 196],
      fleck = [240, 228, 184]; // cream plaster (old #F6ECC4, #F0E4B8)
  static const List<int> skirt = [200, 184, 138],
      skirtLine = [
        122,
        106,
        74,
      ]; // the skirting (old #C8B88A) and its foot line (old #7A6A4A)
  static const List<int> tile = [228, 240, 244],
      grout = [184, 208, 216]; // the tile band (old #E4F0F4, #B8D0D8)
  // the floor's two tiles and the grout (old #E8D8B8, #C8745A, #9A6A54)
  static const List<int> floorA = [232, 216, 184],
      floorB = [200, 116, 90],
      floorG = [154, 106, 84];
  // the cupboards (old RP.wood)
  static const List<int> wood = [146, 96, 46],
      woodD = [110, 66, 32],
      woodL = [184, 128, 64],
      woodLL = [216, 164, 96];
  static const List<int> knob = [
    240,
    192,
    32,
  ]; // the cupboards' brass handles (old #F0C020)
  // the white counter top (old #E8E8F0, #FFFFFF, #B8B8C8)
  static const List<int> top = [236, 236, 244],
      topEdge = [255, 255, 255],
      topDark = [184, 184, 200];
  static const List<int> plinth = [74, 46, 26];
  // the stove
  static const List<int> steel = [242, 242, 248],
      steelD = [200, 200, 212],
      hob = [98, 98, 112],
      burner = [34, 34, 44],
      cap = [72, 72, 86];
  static const List<int> ovenGlass = [52, 52, 66],
      handle = [138, 138, 154],
      red = [208, 48, 42],
      ovenLit = [184, 72, 24];
  static const List<int> hood = [200, 200, 212], hoodLip = [148, 148, 166];
  // the window's wooden frame and sill (old Wd[1], Wd[3])
  static const List<int> frame = [146, 96, 46],
      frameL = [216, 164, 96],
      sill = [184, 128, 64];
  // the sky through a window, top to bottom as La sala's
  static const List<List<int>> sky = [
    [162, 211, 255],
    [120, 186, 250],
    [85, 159, 242],
  ];
  static const List<List<int>> bush = [
    [46, 154, 72],
    [76, 188, 88],
    [132, 220, 120],
  ];
  static const List<List<int>> hedge = [
    [30, 122, 58],
    [58, 168, 72],
  ];
  static const List<int> yard = [232, 216, 184],
      yardTop = [255, 244, 216],
      yardLine = [168, 152, 120];
  static const List<int> white = [244, 240, 228];
  // added (order 37a, La mesa): the panel behind the stove
  static const List<int> guard = [66, 68, 82], guardRim = [118, 120, 136];
}

/// A window (or a doorway) in a standing wall (cocina-kit.js: `win`): its wall ([face] `'x'` or `'y'`), its hole from
/// [a0] to [a1] along the wall and [z0] to [z1] up; [view] what is seen through it (`'arbusto'`, `'patio'`, or null:
/// `'arbusto'`), or [viewFn] (`fn(a, z)` -> `[r, g, b]`); [bars] `'cruz'`, `'medio'` or `'none'` (null: by [door]);
/// [door] a doorway (no sill, no bottom board); [horizon], [bushA], [bushZ], [bushR] the outside's numbers (null: the
/// kit's defaults); [name] the part it is drawn as (null: `ventana`, `ventana1`, ...).
class CocinaWin {
  const CocinaWin({
    required this.face,
    required this.a0,
    required this.a1,
    required this.z0,
    required this.z1,
    this.view,
    this.viewFn,
    this.bars,
    this.door = false,
    this.horizon,
    this.bushA,
    this.bushZ,
    this.bushR,
    this.name,
  });

  final String face;
  final double a0, a1, z0, z1;
  final String? view;
  final List<num> Function(double a, double z)? viewFn;
  final String? bars;
  final bool door;
  final double? horizon, bushA, bushZ, bushR;
  final String? name;
}

/// The room cut open (cocina-kit.js `cocinaBuild`'s `plan`): how far the back wall ([XR], along x) and the left wall
/// ([YL], along y) run; [windows] (their holes are cut, their frames drawn); [band] where the tile band runs on each wall
/// (`'x'` and `'y'`: `[a0, a1]` each); [furnish] draws the pieces; [shadows] casts the pieces' shadows; [floor], a colour
/// or 0 to override `cocinaFloor` at a point (a door's threshold); [occlusion] `'shade'` (the floor dimmed on the shadow
/// side only), `'none'`, or null (the engine's `bakeOcclusion`).
class CocinaPlan {
  const CocinaPlan({
    required this.XR,
    required this.YL,
    this.windows = const [],
    this.band = const {},
    this.furnish,
    this.shadows,
    this.floor,
    this.occlusion,
  });

  final double XR, YL;
  final List<CocinaWin> windows;
  final Map<String, List<List<double>>> band;
  final void Function()? furnish, shadows;
  final int Function(double x, double y, int ix, int iy, int i)? floor;
  final String? occlusion;
}

/// What `kWallPixel` gives: the point of the wall plane a pixel's middle looks at.
typedef KWallPoint = ({double a, double z, double d, double x, double y});

/// A box's paint (cocina-kit.js `kBox`'s `paint(faceName, p, q, shadeSide)`): a colour, or 0 for none.
typedef KPaint = int Function(String f, double p, double q, bool sh);

/// What `cocinaBase` gives: the z of the top surface, the front of the top, the world box.
typedef CocinaBaseOut = ({double top, double d1, List<double> box});

/// What `cocinaStove` gives: each burner's middle (world), the top, its ends along the wall, the world box, the oven
/// door's world corners.
typedef CocinaStoveOut = ({
  List<List<double>> burners,
  double top,
  double a0,
  double a1,
  List<double> box,
  List<List<double>> ovenDoor,
});

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: `v || d` for an option that may be missing (0 is missing too)
double _or(num? v, num d) => (v == null || v == 0 ? d : v).toDouble();

/// The floor of each engine, laid once (cocina-kit.js `COCINA_FLOOR`: one per page; here one per engine).
final Expando<_CocinaFloor> _floors = Expando<_CocinaFloor>();

class _CocinaFloor {
  _CocinaFloor(this.pix, this.zb, this.kinds, this.ground);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
}

/// Port of cocina-kit.js: every helper of the kitchen's kit, drawing into the engine of [k] (set-kit.js's helpers, whose
/// `part` records the part tags) with mapa.js's helpers. One per set.
class CocinaKit {
  CocinaKit(this.k) : e = k.e, b = k.b;

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  int get W => e.W;
  int get H => e.H;
  double get S => e.S;
  double get ST => b.ST;

  // cocina-kit.js: cocinaCheckScene
  /// A kitchen set's PP_SCENE must carry the kitchen's light and scale: s 26, shadowX .9, shadowY -.1.
  void cocinaCheckScene() {
    if (e.S != 26 || e.SHADOW_X != .9 || e.SHADOW_Y != -.1) {
      throw StateError(
        'cocina-kit: PP_SCENE must have s 26, shadowX .9, shadowY -.1',
      );
    }
  }

  /* ---------- a wall's frame ---------- */

  // cocina-kit.js: kpt
  /// The world point of (a along the wall, d out from it, z up) in the frame of a wall: face 'y' (the back wall) or 'x'.
  List<double> kpt(String face, num a, num d, num z) => face == 'y'
      ? [a.toDouble(), d.toDouble(), z.toDouble()]
      : [d.toDouble(), a.toDouble(), z.toDouble()];

  // cocina-kit.js: kWallPixel
  /// The point of the wall plane (x = at for 'x', y = at for 'y') a screen pixel's middle looks at: a (along the wall),
  /// z, d (depth).
  KWallPoint kWallPixel(String face, num at, int ix, int iy) {
    final u = (ix + .5 - e.OX) / S, kk = (iy + .5 - e.OY) / S;
    final x = face == 'x' ? at.toDouble() : at + u * e.R2,
        y = face == 'x' ? at - u * e.R2 : at.toDouble();
    final v = (x + y) / e.R2, z = (v * e.SIN - kk) / e.COS;
    return (a: face == 'x' ? y : x, z: z, d: v * e.COS + z * e.SIN, x: x, y: y);
  }

  // cocina-kit.js: kLit
  /// One ramp step of a colour, by light: lit +y faces and tops as they are, +x faces in shade a step darker and cooler.
  List<num> kLit(List<num> c, bool shade) =>
      shade ? [c[0] * .86 + 4, c[1] * .86 + 5, c[2] * .86 + 12] : c;

  // cocina-kit.js: kRgb
  int kRgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // cocina-kit.js: kBox
  /// A box in a wall's frame, every face one sample a pixel: paint(faceName, p, q, shadeSide) gives a colour or 0 for
  /// none. top: p along a (a0..a1), q along d (d0..d1); front (d = d1): p along a, q = z; end (a = a1): p along d, q = z.
  /// shadeSide: true where that face looks +x (in shade): the end of a 'y' piece, the front of an 'x' piece.
  void kBox(
    String face,
    num a0,
    num a1,
    num d0,
    num d1,
    num z0,
    num z1,
    KPaint paint, [
    String faces = 'tfe',
  ]) {
    List<double> P(num a, num d, num z) => kpt(face, a, d, z);
    List<double> sub(List<double> p, List<double> q) => [
      p[0] - q[0],
      p[1] - q[1],
      p[2] - q[2],
    ];
    if (faces.contains('t')) {
      final o = P(a0, d0, z1);
      k.planeQuad(
        o,
        sub(P(a1, d0, z1), o),
        sub(P(a0, d1, z1), o),
        (s, t) => paint('top', a0 + (a1 - a0) * s, d0 + (d1 - d0) * t, false),
      );
    }
    if (faces.contains('f')) {
      final o = P(a0, d1, z0);
      k.planeQuad(
        o,
        sub(P(a1, d1, z0), o),
        sub(P(a0, d1, z1), o),
        (s, t) =>
            paint('front', a0 + (a1 - a0) * s, z0 + (z1 - z0) * t, face == 'x'),
      );
    }
    if (faces.contains('e')) {
      final o = P(a1, d0, z0);
      k.planeQuad(
        o,
        sub(P(a1, d1, z0), o),
        sub(P(a1, d0, z1), o),
        (s, t) =>
            paint('end', d0 + (d1 - d0) * s, z0 + (z1 - z0) * t, face == 'y'),
      );
    }
  }

  // cocina-kit.js: kSolid
  /// A plain box in a wall's frame: top, front and end in one colour by light (top lightest, the lit side, the shade
  /// side).
  void kSolid(
    String face,
    num a0,
    num a1,
    num d0,
    num d1,
    num z0,
    num z1,
    List<num> c, [
    String faces = 'tfe',
  ]) {
    final R = e.rampOf(c);
    kBox(
      face,
      a0,
      a1,
      d0,
      d1,
      z0,
      z1,
      (f, p, q, sh) => f == 'top'
          ? R[3]
          : sh
          ? R[1]
          : R[2],
      faces,
    );
  }

  /* ---------- the floor: the old picture's two-colour checker tiles, laid on the world's axes ---------- */

  // cocina-kit.js: cocinaFloor
  /// The colour of the floor at (x, y), or 0 outside the room (x < 0 or y < 0). Thin grout lines; no texture, the
  /// checker reads at once.
  int cocinaFloor(double x, double y) {
    if (x < 0 || y < 0) return 0;
    final ta = x / K.TILE,
        tb = y / K.TILE,
        ea = ta - ta.floor(),
        eb = tb - tb.floor();
    if (ea < .06 || eb < .06) return kRgb(KC.floorG);
    return kRgb(
      (ta.floor() + tb.floor()).remainder(2) != 0 ? KC.floorB : KC.floorA,
    );
  }

  /* ---------- the walls: cream plaster, the skirting, the pale blue tile band at counter height ---------- */

  // cocina-kit.js: kWallC, kWC (each colour by light worked out once: the same pixels, without an array a pixel)
  static final Expando<List<int>> _kWallC = Expando<List<int>>();
  int kWC(List<int> c, bool shade) {
    var m = _kWallC[c];
    if (m == null) {
      _kWallC[c] = m = [kRgb(kLit(c, false)), kRgb(kLit(c, true))];
    }
    return m[shade ? 1 : 0];
  }

  // cocina-kit.js: cocinaWallColour
  /// fn for planeFace: shade = the face looks +x (the left wall). band: is the tile band behind this point (a run of
  /// counters).
  int cocinaWallColour(bool shade, num a, num z, bool band) {
    if (z < K.SKIRT) {
      return kWC(
        z < .03
            ? KC.skirtLine
            : z > K.SKIRT - .03
            ? KC.white
            : KC.skirt,
        shade,
      );
    }
    if (band && z >= K.BAND0 && z <= K.BAND1) {
      final ta = a / K.BTILE, tz = (z - K.BAND0) / K.BTILE;
      final g =
          ta - ta.floor() < .1 || tz - tz.floor() < .1 || z > K.BAND1 - .03;
      return kWC(g ? KC.grout : KC.tile, shade);
    }
    // sparse flecks in the plaster (the old picture's)
    final f = e.hash((a * 11).floor(), (z * 13).floor()) < .07;
    return kWC(f ? KC.fleck : KC.plaster, shade);
  }

  /* ---------- a window (or a doorway) in a standing wall ---------- */

  // cocina-kit.js: KDROP. How far a sight line falls from a wall's inner face to the backdrop
  double get KDROP => (K.T + K.OUTD) / (e.COS / e.SIN / e.R2);

  // cocina-kit.js: cocinaOutside
  /// The outside seen through a window's hole with depth: a backdrop plane K.OUTD behind the wall (sky, the patio's
  /// yard wall and hedge, a bush). The hole is cut in the wall by cocinaBuild (plan.windows).
  void cocinaOutside(CocinaWin win) {
    final face = win.face, a0 = win.a0, a1 = win.a1, z0 = win.z0, z1 = win.z1;
    final at = -K.T - K.OUTD, mid = (a0 + a1) / 2;
    // the screen box of the hole on the inner face
    final xs = <double>[], ys = <double>[];
    for (final a in [a0, a1]) {
      for (final z in [z0, z1]) {
        final q = kpt(face, a, 0, z), p = e.project(q[0], q[1], q[2]);
        xs.add(p.sx);
        ys.add(p.sy);
      }
    }
    final ix0 = math.max(0, xs.reduce(math.min).floor() - 1),
        ix1 = math.min(W - 1, xs.reduce(math.max).ceil() + 1);
    final iy0 = math.max(0, ys.reduce(math.min).floor() - 1),
        iy1 = math.min(H - 1, ys.reduce(math.max).ceil() + 1);
    final zb = e.zb, pix = e.pix;
    for (var iy = iy0; iy <= iy1; iy++) {
      for (var ix = ix0; ix <= ix1; ix++) {
        final w = kWallPixel(face, 0, ix, iy);
        // the sight line misses the hole
        if (w.a <= a0 || w.a >= a1 || w.z <= z0 || w.z >= z1) continue;
        final o = kWallPixel(face, at, ix, iy), i = iy * W + ix;
        if (o.d <= zb[i]) continue;
        // what is out there, at the backdrop's point (a along the wall, z): sky above, the patio below
        // (z is lifted by the drop of a sight line over the distance, so the window's middle looks at the backdrop's
        // middle height)
        final fn = win.viewFn;
        final c = fn != null
            ? fn(o.a, o.z + KDROP)
            : kView(win.view ?? 'arbusto', o.a - mid, o.z + KDROP, ix, iy, win);
        zb[i] = o.d;
        pix[i] = kRgb(c);
        e.kinds[i] = e.KIND_NONE;
        e.ground[i] = 0;
      }
    }
  }

  // cocina-kit.js: kView
  /// The outside, as a backdrop: r is along the wall from the window's middle, z the height. 'arbusto': sky and one round
  /// bush low at the right (La mesa's and La estufa's old windows); 'patio': sky with a cloud, the yard's cream wall, the
  /// hedge's green before it (La nevera's).
  List<int> kView(
    String kind,
    double r,
    double z,
    int ix,
    int iy,
    CocinaWin win,
  ) {
    // the yard wall's top (z on the backdrop, lifted): by default 42% up the window ('patio') or 30% ('arbusto')
    final horizon =
        win.horizon ??
        win.z0 + (win.z1 - win.z0) * (kind == 'patio' ? .42 : .3);
    final skyT = e.clamp<double>((z - horizon) / 1.8, 0, 1),
        sky =
            KC.sky[e.clamp(
              ((1 - skyT) * 3 + (e.bayerAt(ix, iy) - .5) * .5).floor(),
              0,
              2,
            )];
    if (kind == 'patio') {
      final dr = (r - .4) / .5, dz = (z - horizon - 1.3) / .14;
      final cl = dr * dr + dz * dz;
      if (z > horizon) return cl < 1 ? const [255, 255, 255] : sky;
      if (z > horizon - .1) return KC.yardTop;
      if (z > horizon - .5) {
        return ((r + 20).remainder(.55) - .27).abs() < .03
            ? KC.yardLine
            : KC.yard;
      }
      return KC.hedge[(e.hash((r * 9).floor(), (z * 6).floor()) > .55) ? 0 : 1];
    }
    // a bush: a round green crown, lit from the upper left; under it the patio's green
    final bx = win.bushA ?? .45,
        bz = win.bushZ ?? horizon + .15,
        br = _or(win.bushR, .62);
    final dx = (r - bx) / br, dz = (z - bz) / (br * .9), dd = dx * dx + dz * dz;
    if (dd < 1) {
      return KC.bush[e.clamp(
        (1.6 - dx * .9 + dz * 1.1 + (e.hash(ix, iy) - .5) * .7).floor(),
        0,
        2,
      )];
    }
    if (z < horizon - .35) return KC.hedge[1];
    return sky;
  }

  // cocina-kit.js: cocinaWindow
  /// The frame, bars and sill (called after cocinaBuild has cut the hole, inside plan.furnish).
  void cocinaWindow(CocinaWin win) {
    final face = win.face, a0 = win.a0, a1 = win.a1, z0 = win.z0, z1 = win.z1;
    final Fr = e.rampOf(KC.frame), FL = kRgb(KC.frameL);
    const w = .1, out = .06;
    // the reveal: the wall's thickness, plaster, seen through the hole (set-kit's reveal / revealX)
    if (face == 'y') {
      k.reveal(0, a0, a1, z0, z1, K.T, KC.plaster);
    } else {
      k.revealX(0, a0, a1, z0, z1, K.T, KC.plaster);
    }
    cocinaOutside(win);
    // the bars (in the middle of the wall's thickness): a cross, one upright, or none
    final bars = win.bars ?? (win.door ? 'none' : 'cruz');
    const bw = .05;
    final dm = -K.T * .5, zm = z0 + (z1 - z0) * .5, am = (a0 + a1) / 2;
    if (bars != 'none') {
      kSolid(face, am - bw, am + bw, dm - bw, dm + bw, z0, z1, KC.frame);
    }
    if (bars == 'cruz') {
      kSolid(face, a0, a1, dm - bw, dm + bw, zm - bw, zm + bw, KC.frame);
    }
    // the frame: four boards round the hole, standing `out` from the wall's face, with a lit inner lip
    void board(num b0, num b1, num c0, num c1) => kBox(
      face,
      b0,
      b1,
      0,
      out,
      c0,
      c1,
      (f, p, q, sh) => f == 'top'
          ? FL
          : sh
          ? Fr[1]
          : Fr[2],
    );
    board(a0 - w, a0, z0 - (win.door ? 0 : w), z1 + w);
    board(a1, a1 + w, z0 - (win.door ? 0 : w), z1 + w);
    board(a0 - w, a1 + w, z1, z1 + w);
    if (!win.door) {
      board(a0 - w, a1 + w, z0 - w, z0);
      // the sill: a ledge out into the room under the window, its top lit
      final S0 = e.rampOf(KC.sill);
      kBox(
        face,
        a0 - w - .06,
        a1 + w + .06,
        0,
        .16,
        z0 - w - .05,
        z0 - w,
        (f, p, q, sh) => f == 'top'
            ? S0[3]
            : sh
            ? S0[1]
            : S0[2],
      );
    }
  }

  /* ---------- a base cupboard with its white counter top ---------- */

  // cocina-kit.js: cocinaBase
  /// face, a0..a1 along the wall. [doors] (how many door leaves; null: by width), [drawers] (a row of drawers under the
  /// top; the kit draws none yet), [noEnd] (the end at a1 is against another piece: not drawn). Gives the z of the top
  /// surface, the front of the top and the world box.
  CocinaBaseOut cocinaBase(
    String face,
    num a0,
    num a1, {
    int? doors,
    bool drawers = false,
    bool noEnd = false,
  }) {
    final Wd = e.rampOf(KC.wood), d1 = K.CD - K.COVER, zt = K.CZ - K.CTOP;
    final n = doors != null && doors != 0
        ? doors
        : math.max(1, _round((a1 - a0) / .62));
    final ends = noEnd ? 'tf' : 'tfe';
    // the plinth: dark, set back
    kSolid(
      face,
      a0,
      a1 - (noEnd ? 0 : K.PLINTH_IN),
      0,
      d1 - K.PLINTH_IN,
      0,
      K.PLINTH,
      KC.plinth,
      noEnd ? 'f' : 'fe',
    );
    // the body and its doors: each door a panel with a darker rim and a lit top edge; a brass handle by the meeting edge
    final dw = (a1 - a0) / n;
    kBox(face, a0, a1, 0, d1, K.PLINTH, zt, (f, p, q, sh) {
      if (f != 'front') return Wd[sh ? 1 : 2];
      final kk = math.min(n - 1, ((p - a0) / dw).floor()),
          ee = p - a0 - kk * dw;
      final gap = ee < .025 || ee > dw - .025,
          rim =
              ee < .075 || ee > dw - .075 || q < K.PLINTH + .07 || q > zt - .07;
      if (gap || q > zt - .025) return Wd[0];
      final hx = kk % 2 == 0 ? dw - .13 : .13,
          handle = n > 1
              ? (ee - hx).abs() < .025 && (q - (zt - .32)).abs() < .1
              : (ee - dw / 2).abs() < .1 && (q - (zt - .2)).abs() < .025;
      if (handle) return kRgb(kLit(KC.knob, sh));
      return Wd[rim ? (sh ? 1 : 2) : (sh ? 2 : 3)];
    }, ends.replaceFirst('t', ''));
    // the white top: a slab overhanging the front, its front edge lit, a darker line under it
    kBox(face, a0, a1 + (noEnd ? 0 : K.COVER * .5), 0, K.CD, zt, K.CZ, (
      f,
      p,
      q,
      sh,
    ) {
      if (f == 'top') {
        return kRgb(p > a1 - .01 || q > K.CD - .03 ? KC.topEdge : KC.top);
      }
      return kRgb(kLit(q < zt + .025 ? KC.topDark : KC.topEdge, sh));
    }, ends);
    final box = [kpt(face, a0, 0, 0), kpt(face, a1, K.CD, K.CZ)];
    return (
      top: K.CZ,
      d1: K.CD,
      box: [
        math.min(box[0][0], box[1][0]),
        math.min(box[0][1], box[1][1]),
        0,
        math.max(box[0][0], box[1][0]),
        math.max(box[0][1], box[1][1]),
        K.CZ,
      ],
    );
  }

  /* ---------- a wall cupboard: two doors, brass knobs ---------- */

  // cocina-kit.js: cocinaWallCupboard
  /// [z0], [z1], [depth], [doors]: null (or 0) takes the kit's (K.UZ0, K.UZ1, K.UD, 2). Gives the world box.
  ({List<double> box}) cocinaWallCupboard(
    String face,
    num a0,
    num a1, {
    num? z0,
    num? z1,
    num? depth,
    int? doors,
  }) {
    final Wd = e.rampOf(KC.wood),
        Z0 = _or(z0, K.UZ0),
        Z1 = _or(z1, K.UZ1),
        d1 = _or(depth, K.UD),
        n = doors != null && doors != 0 ? doors : 2,
        dw = (a1 - a0) / n;
    kBox(face, a0, a1, 0, d1, Z0, Z1, (f, p, q, sh) {
      if (f == 'top') return Wd[4];
      if (f == 'end') return Wd[1];
      final kk = math.min(n - 1, ((p - a0) / dw).floor()),
          ee = p - a0 - kk * dw;
      if (ee < .025 || ee > dw - .025 || q < Z0 + .03 || q > Z1 - .03) {
        return Wd[0];
      }
      final hx = kk % 2 == 0 ? dw - .12 : .12;
      if ((ee - hx).abs() < .03 && (q - (Z0 + .2)).abs() < .07) {
        return kRgb(kLit(KC.knob, sh));
      }
      final rim = ee < .09 || ee > dw - .09 || q < Z0 + .1 || q > Z1 - .1;
      return Wd[rim ? (sh ? 1 : 2) : (sh ? 2 : 3)];
    });
    final bb = [kpt(face, a0, 0, Z0), kpt(face, a1, d1, Z1)];
    return (
      box: [
        math.min(bb[0][0], bb[1][0]),
        math.min(bb[0][1], bb[1][1]),
        Z0,
        math.max(bb[0][0], bb[1][0]),
        math.max(bb[0][1], bb[1][1]),
        Z1,
      ],
    );
  }

  /* ---------- a shelf on the wall (La estufa's, for its jars) ---------- */

  // cocina-kit.js: cocinaShelf
  /// [depth]: null (or 0) is .3. Gives the z of its top.
  ({double top}) cocinaShelf(String face, num a0, num a1, num z, {num? depth}) {
    final Wd = e.rampOf(KC.wood), d1 = _or(depth, .3);
    kBox(
      face,
      a0,
      a1,
      0,
      d1,
      z - .06,
      z,
      (f, p, q, sh) => f == 'top' ? Wd[3] : Wd[sh ? 0 : 1],
    );
    for (final a in [a0 + .12, a1 - .16]) {
      kSolid(face, a, a + .04, 0, d1 * .7, z - .26, z - .06, KC.woodD);
    }
    return (top: z.toDouble());
  }

  /* ---------- the stove: a white body, the hob with two burners, a front with knobs and the oven door ---------- */

  // cocina-kit.js: cocinaStove
  /// face, a0 (its left end along the wall); its width K.STW, depth K.SD, top at K.CZ. [knobs] (how many; null: 2),
  /// [horno] (the oven lit: its window glows orange), [noEnd] (a counter stands against its end at a1).
  CocinaStoveOut cocinaStove(
    String face,
    num a0, {
    int? knobs,
    bool horno = false,
    bool noEnd = false,
  }) {
    final a1 = a0 + K.STW, d1 = K.SD, zt = K.CZ;
    const St = KC.steel;
    final nK = knobs ?? 2;
    final panel0 = zt - .2, door1 = zt - .3;
    const door0 = .14, BR = .2;
    final burners = [
      [a0 + K.STW * .29, d1 * .5],
      [a0 + K.STW * .71, d1 * .5],
    ];
    kBox(face, a0, a1, 0, d1, 0, zt, (f, p, q, sh) {
      if (f == 'top') {
        for (final bd in burners) {
          final dx = p - bd[0], dy = (q - bd[1]) * 1;
          final r = math.sqrt(dx * dx + dy * dy);
          if (r < BR * .45) return kRgb(KC.cap);
          if (r < BR) return kRgb(r > BR - .04 ? KC.cap : KC.burner);
        }
        return kRgb(
          p < a0 + .03 || p > a1 - .03 || q > d1 - .03 ? KC.steelD : KC.hob,
        );
      }
      if (f == 'end') return kRgb(kLit(q > zt - .04 ? KC.steelD : St, sh));
      // the front: a panel with the knobs, the oven door with its window and handle, a dark foot
      if (q < .06) return kRgb(KC.burner);
      if (q > zt - .03) return kRgb(kLit(KC.steelD, sh));
      if (q > panel0) {
        for (var kk = 0; kk < nK; kk++) {
          final ka = a0 + K.STW * (kk + 1) / (nK + 1);
          if ((p - ka).abs() < .055 && (q - (panel0 + .1)).abs() < .05) {
            return kRgb(kLit(KC.red, sh));
          }
        }
        return kRgb(kLit(q < panel0 + .025 ? KC.steelD : St, sh));
      }
      final da = p - a0,
          inDoor = da > .08 && da < K.STW - .08 && q > door0 && q < door1;
      if (!inDoor) return kRgb(kLit(St, sh));
      // the door's edge
      if (da < .11 || da > K.STW - .11 || q < door0 + .03 || q > door1 - .03) {
        return kRgb(kLit(KC.steelD, sh));
      }
      // the handle
      if ((q - (door1 - .1)).abs() < .03 && da > .22 && da < K.STW - .22) {
        return kRgb(kLit(KC.handle, sh));
      }
      // the window
      if (da > .22 && da < K.STW - .22 && q > door0 + .14 && q < door1 - .2) {
        return kRgb(kLit(horno ? KC.ovenLit : KC.ovenGlass, sh));
      }
      return kRgb(kLit(St, sh));
    }, noEnd ? 'tf' : 'tfe');
    final bb = [kpt(face, a0, 0, 0), kpt(face, a1, d1, zt)];
    return (
      burners: [for (final bd in burners) kpt(face, bd[0], bd[1], zt)],
      top: zt,
      a0: a0.toDouble(),
      a1: a1.toDouble(),
      box: [
        math.min(bb[0][0], bb[1][0]),
        math.min(bb[0][1], bb[1][1]),
        0,
        math.max(bb[0][0], bb[1][0]),
        math.max(bb[0][1], bb[1][1]),
        zt,
      ],
      ovenDoor: [
        kpt(face, a0 + .22, d1, door0 + .14),
        kpt(face, a1 - .22, d1, door1 - .2),
      ],
    );
  }

  // cocina-kit.js: cocinaHood
  /// The hood over the stove: a wide canopy with a darker lip, its chimney up to the cut top of the wall ([top]; null
  /// or 0: K.WH).
  void cocinaHood(String face, num a0, {num? top}) {
    final a1 = a0 + K.STW, H0 = e.rampOf(KC.hood), L = e.rampOf(KC.hoodLip);
    const m = .05;
    kBox(
      face,
      a0 - m,
      a1 + m,
      0,
      K.HD,
      K.HZ0,
      K.HZ0 + .08,
      (f, p, q, sh) => f == 'top' ? L[3] : L[sh ? 1 : 2],
    );
    kBox(
      face,
      a0,
      a1,
      0,
      K.HD - .04,
      K.HZ0 + .08,
      K.HZ1,
      (f, p, q, sh) => f == 'top' ? H0[4] : H0[sh ? 2 : 3],
    );
    kBox(
      face,
      a0 + K.STW * .3,
      a1 - K.STW * .3,
      0,
      K.HD * .5,
      K.HZ1,
      _or(top, K.WH),
      (f, p, q, sh) => f == 'top' ? H0[4] : H0[sh ? 1 : 2],
    );
  }

  /* ---------- shadows (the kitchen's one rule: low, to screen right, joined to the thing) ---------- */

  // cocina-kit.js: cocinaShadowBlock
  /// A block standing on the floor, in world coordinates: a soft low shadow round its foot on the shadow side.
  void cocinaShadowBlock(num x0, num y0, num x1, num y1, [num zs = .3]) {
    for (num x = x0; x <= x1 + 1e-9; x += .25) {
      for (num y = y0; y <= y1 + 1e-9; y += .25) {
        e.castShadow(x, y, zs, .22);
      }
    }
  }

  // cocina-kit.js: cocinaShadowFoot
  /// A thin thing (a leg, a post) at (x, y): a short contact shadow at its foot only.
  void cocinaShadowFoot(num x, num y, [num r = .07]) =>
      e.castShadow(x + .04, y, .05, r, 1, .2);

  /* ---------- the room cut open (La sala's build) ---------- */

  // cocina-kit.js: cocinaBuild
  /// Resets the buffers, lays the floor (kept after the first bake: one per engine), stands the walls, furnishes,
  /// shades, fills the backdrop and bakes.
  void cocinaBuild(CocinaPlan plan) {
    final zb = e.zb, pix = e.pix;
    zb.fillRange(0, zb.length, -1e9);
    pix.fillRange(0, pix.length, 0);
    e.kinds.fillRange(0, e.kinds.length, 0);
    e.ground.fillRange(0, e.ground.length, 0);
    e.shadowMask.fillRange(0, e.shadowMask.length, 0);
    e.staticShadow.fillRange(0, e.staticShadow.length, 0);
    e.tufts.clear();
    e.leaves.clear();
    e.pendingShadows.clear();
    k.slabTops.clear();
    k.glowReset();
    final had = _floors[e];
    if (had == null) {
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5), i = iy * W + ix;
          final own = plan.floor?.call(g.x, g.y, ix, iy, i) ?? 0;
          final c = own != 0 ? own : cocinaFloor(g.x, g.y);
          if (c == 0) continue;
          pix[i] = c;
          e.ground[i] = 1;
          zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = KIND_ROAD;
        }
      }
      _floors[e] = _CocinaFloor(
        Uint32List.fromList(pix),
        Float32List.fromList(zb),
        Uint8List.fromList(e.kinds),
        Uint8List.fromList(e.ground),
      );
    } else {
      pix.setAll(0, had.pix);
      zb.setAll(0, had.zb);
      e.kinds.setAll(0, had.kinds);
      e.ground.setAll(0, had.ground);
    }
    e.groundZ.setAll(0, zb);
    // (the holes and the band of each wall listed once, not for every pixel: the same pixels, faster)
    final HOLES = {
      'x': [
        for (final w in plan.windows)
          if (w.face == 'x') w,
      ],
      'y': [
        for (final w in plan.windows)
          if (w.face == 'y') w,
      ],
    };
    final BANDS = {
      'x': plan.band['x'] ?? const [],
      'y': plan.band['y'] ?? const [],
    };
    bool inBand(String f, num a) {
      final L = BANDS[f]!;
      for (var kk = 0; kk < L.length; kk++) {
        if (a >= L[kk][0] && a <= L[kk][1]) return true;
      }
      return false;
    }

    bool inHole(String f, num a, num z) {
      final L = HOLES[f]!;
      for (var kk = 0; kk < L.length; kk++) {
        final w = L[kk];
        if (a > w.a0 && a < w.a1 && z > w.z0 && z < w.z1) return true;
      }
      return false;
    }

    void wall(String f, num len) => k.planeFace(
      f,
      0,
      0,
      len,
      0,
      K.WH,
      (a, z) =>
          inHole(f, a, z) ? 0 : cocinaWallColour(f == 'x', a, z, inBand(f, a)),
    );
    k.part('pared', () {
      wall('x', plan.YL);
      wall('y', plan.XR);
      // the cut tops: the wall's thickness, white, a lit edge along the room side
      final E = e.rampOf(KC.white), T = K.T;
      k.planeQuad([-T, -T, K.WH], [T, 0, 0], [
        0,
        plan.YL + T,
        0,
      ], (_, _) => E[3]);
      k.planeQuad([0, -T, K.WH], [plan.XR, 0, 0], [0, T, 0], (_, _) => E[3]);
      for (num bb = 0; bb <= plan.YL; bb += ST * .8) {
        e.plot(0, bb, K.WH - .02, E[2]);
      }
      for (num a = 0; a <= plan.XR; a += ST * .8) {
        e.plot(a, 0, K.WH - .02, E[2]);
      }
    });
    for (final (kk, w) in plan.windows.indexed) {
      k.part(w.name ?? 'ventana${kk != 0 ? kk : ''}', () => cocinaWindow(w));
    }
    plan.furnish?.call();
    plan.shadows?.call();
    e.flushShadows();
    e.pendingShadows.clear();
    if (plan.occlusion == 'shade') {
      cocinaOcclusion();
    } else if (plan.occlusion != 'none') {
      e.bakeOcclusion();
    }
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    final back = kRgb(K.BACKDROP);
    k.skyFill((ix, iy) => back);
    e.bakedPix.setAll(0, pix);
    e.bakedZ.setAll(0, zb);
  }

  /* ---------- added (order 37a, La mesa): the floor's dimming by what stands on it, on the shadow side only ---------- */

  // cocina-kit.js: cocinaOcclusion
  /// bakeOcclusion (the engine's) dims the floor round everything on every side, so a chair's leg or a stool's foot
  /// gets a dark ring on its lit side (upper left) too. This dims a floor pixel only by what stands to its left on the
  /// screen (the light comes from the upper left): the same offsets and tints as bakeOcclusion, those with a negative
  /// dx. cocinaBuild uses it when plan.occlusion is 'shade'.
  void cocinaOcclusion() {
    final offsets = <List<int>>[];
    for (final r in const [2, 4]) {
      for (var kk = 0; kk < 8; kk++) {
        final ox = _round(math.cos(kk * math.pi / 4) * r),
            oy = _round(math.sin(kk * math.pi / 4) * r * .7);
        if (ox < 0) offsets.add([ox, oy]);
      }
    }
    final n = offsets.length, zb = e.zb, gz = e.groundZ;
    for (var iy = 4; iy < H - 4; iy++) {
      for (var ix = 4; ix < W - 4; ix++) {
        final i = iy * W + ix;
        if (e.ground[i] == 0 || zb[i] != gz[i]) continue;
        var hits = 0;
        for (final o in offsets) {
          final j = (iy + o[1]) * W + ix + o[0];
          if (zb[j] != gz[j]) hits++;
        }
        if (hits == 0) continue;
        if (hits >= n) {
          e.tint(i, .56, .54, .72);
        } else if (hits / n > e.bayerAt(ix, iy)) {
          e.tint(i, .74, .72, .84);
        }
      }
    }
  }

  /* ---------- added (order 37a, La mesa): the panel behind the stove ---------- */

  // cocina-kit.js: cocinaBackguard
  /// A dark steel panel on the wall behind the stove, from the hob up to the hood's lip ([top]; null or 0: K.HZ0), as
  /// wide as the stove and its hood: what rises from a pot (steam, white) is seen against it. Its rim a step lighter.
  void cocinaBackguard(String face, num a0, {num? top}) {
    final a1 = a0 + K.STW,
        z0 = K.CZ,
        z1 = _or(top, K.HZ0),
        G = kRgb(KC.guard),
        Rm = kRgb(KC.guardRim);
    const m = .05;
    kBox(
      face,
      a0 - m,
      a1 + m,
      0,
      .015,
      z0,
      z1,
      (f, p, q, sh) => f != 'front'
          ? 0
          : (p < a0 - m + .04 || p > a1 + m - .04 || q > z1 - .04)
          ? Rm
          : G,
      'f',
    );
  }
}
