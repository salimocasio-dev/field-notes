// Port of docs/proyecto/pixel/sala-set.html: La sala's set, every state, call for call (order 31a's set reference,
// order 31b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine La sala's set is built on (sala-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (20, -33), shadows to (.9, -.1).
PpEngine salaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 20,
  originY: -33,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (sala-set.html: `SET`, from the address). The values are the page's own strings.
class SalaState {
  const SalaState({this.luz = '1', this.fotos = '000'});

  /// sala-set.html: `pick('luz', ...)` and the `fotos` pattern, from a query (`?luz=1&fotos=010`); a value the page
  /// does not allow takes its default, as there.
  factory SalaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final luz = q['luz'];
    final fotos = q['fotos'] ?? '';
    return SalaState(
      luz: luz != null && const ['0', '1'].contains(luz) ? luz : '1',
      fotos: RegExp(r'^[01]{3}$').hasMatch(fotos) ? fotos : '000',
    );
  }

  /// A key of the sheet's `setKey` table (`"1-000"`: luz, then fotos) read back.
  factory SalaState.fromKey(String key) {
    final m = RegExp(r'^([01])-([01]{3})$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', 'not a key of La sala\'s set');
    }
    return SalaState(luz: m[1]!, fotos: m[2]!);
  }

  final String luz, fotos;

  /// The sheet's key: luz + "-" + fotos (`setKey.key`: `luz + "-" + fotos, e.g. "1-000"`).
  String get key => '$luz-$fotos';
}

/* ---------- the plan of the room (world units). The corner of the two standing walls is (0, 0); the room is x >= 0, y >= 0 ---------- */

// the left wall stands on x = 0 and faces +x (in shade); the back wall stands on y = 0 and faces +y (lit). Both are T thick
const double T = .22,
    WH = 3.2; // the walls' thickness and the height they are cut at
const double YL = 8.2,
    XR =
        6.2; // how far each wall runs (past the picture's left and right edges)
const double D0 = 4.0,
    D1 = 5.3,
    DH = 2.55; // the door to the porch, on the left wall (y from D0 to D1)
// the leaf, open into the room: turned this far from the wall's normal (+x) towards +y
const double LEAF_ANG = 1.0;
// the three picture frames (round 2): each hangs on a wire from a nail in the left wall, an upright picture turned to
// face the camera, so its photo is upright and whole at the old size. NAILS: the nail's pixel in the picture, on the left
// wall; the three nails at one height on the wall (z 2.5), so the frames step up towards the corner with it, 2 px apart,
// over the sofa and clear of the heads of whoever sits or stands before it; 3 px from the door's casing and from the
// corner, so a crooked one (two corners 2.9 px out) stays on the wall
const List<List<int>> NAILS = [
  [83, 49],
  [105, 38],
  [127, 27],
];
// a frame in pixels: width, height, the wire's rows from the nail to its top, the moulding
const int FPW = 20, FPH = 27, FWIRE = 2, FMOULD = 2;
// a crooked frame: turned by this (the old marco's .24, counterclockwise), about its middle (it slid on its wire)
const double TILT = -.24;
const double W0 = 1.86,
    W1 = 3.36,
    WZ0 = 1.3,
    WZ1 = 2.55; // the window, on the back wall (x from W0 to W1)
const double TURN =
    -math.pi /
    4; // the furniture turned to face the camera (as El balcón's chairs)
const List<int> TEAL = [92, 190, 186],
    WOOD = [150, 98, 56],
    WHITE = [244, 240, 228];
// El balcón's porch tiles (the old sala's floor colours too)
const List<List<int>> TILE = [
  [238, 220, 176],
  [224, 198, 144],
  [184, 154, 106],
];
const List<int> WALLP = [
  252,
  238,
  196,
]; // the wallpaper (old: #F4E0B0 .. #F8E8C0)
const List<int> SOFA = [62, 154, 138],
    SOFA_D = [46, 122, 110],
    ORNG = [242, 166, 80],
    ORNG_D = [220, 132, 48];
const List<int> PINK = [255, 184, 212],
    LAMPY = [255, 224, 112],
    CREAMY = [255, 251, 234];
const List<int> BLANKET = [168, 216, 240];

// the lamp in the corner (round 2, from .95, .32): its foot on the floor seen over the sofa's back
const List<double> LAMP = [.34, .22], PLANT = [4.45, .3];
// its height (round 2, from 2.42): as the old one, taller than abuela (64 px to her 51, here 3.0 to 2.55); its shade over the frames
const double LAMP_H = 3.0;

// through the door (round 2): the porch, El balcón's tiled floor, at the room's floor level, PORCH_D out from the wall, then
// its stone edge, and the lawn PORCH_DROP lower (El balcón's FLOOR) beyond it. A floor point (x < 0, y) is seen on the
// sight line that crosses the wall at y - x, -.8165 x high: only the band of sight lines through the doorway (y - x from
// D0 to D1, with a margin) is outside ground, out to OUT_X (the doorway's top); above the cut walls the backdrop shows.
// PORCH_D: El balcón's porch is 3.0 deep, which leaves 2 rows of lawn at the doorway's top; at 2.6 the porch fills its
// lower five sixths and the lawn shows beyond as a strip
const double PORCH_D = 2.6, PORCH_DROP = .3, PORCH_EDGE = .1, OUT_X = -3.6;

// a frame's box and opening in frame coordinates (sala-set.html: FRAME_BOX, FRAME_OPEN)
const List<int> FRAME_BOX = [-FPW ~/ 2, 0, FPW ~/ 2, FPH],
    FRAME_OPEN = [-FPW ~/ 2 + FMOULD, FMOULD, FPW ~/ 2 - FMOULD, FPH - FMOULD];

const List<int> RP_CREAM3 = [251, 240, 210];

// above the cut walls (top=liso, the orchestrator's decision): a flat calm dark grey, a little lighter than the lesson
// screen's #1B1B1F
const List<int> BACKDROP = [38, 36, 44];

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// sala-set.html: rot
List<double> rot(num a, List<num> p) => [
  p[0] * math.cos(a) - p[1] * math.sin(a),
  p[0] * math.sin(a) + p[1] * math.cos(a),
];

/// One frame's geometry (sala-set.html: `frameGeom`): straight or crooked, its nail, where its origin lands (`P`),
/// the screen corners of the frame and of its opening.
class FrameGeom {
  FrameGeom(this.i, this.crooked) : angle = crooked ? TILT : 0 {
    final n = NAILS[i], nx = n[0], ny = n[1];
    final C = [nx, ny + 1 + FWIRE + FPH / 2], d = rot(angle, [0, -FPH / 2]);
    P = [C[0] + d[0], C[1] + d[1]];
    nail = [nx, ny];
    frame = _corners(FRAME_BOX);
    opening = _corners(FRAME_OPEN);
  }

  final int i;
  final bool crooked;
  final double angle;
  late final List<int> nail;
  late final List<double> P;
  late final List<List<double>> frame, opening;

  List<double> toScreen(List<num> q) {
    final r = rot(angle, q);
    return [P[0] + r[0], P[1] + r[1]];
  }

  List<double> toFrame(num sx, num sy) => rot(-angle, [sx - P[0], sy - P[1]]);

  List<List<double>> _corners(List<int> r) => [
    [r[0], r[1]],
    [r[2], r[1]],
    [r[2], r[3]],
    [r[0], r[3]],
  ].map(toScreen).toList();
}

/// The ground and its grass, the same in every state: made once, then copied (sala-set.html: `GROUND_CACHE`). One per
/// engine.
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

/// The set of La sala in one state, built into an engine (sala-set.html, from "the plan of the room" to "bake one
/// state").
class SalaSet {
  SalaSet(this.e, this.b, this.SET)
    : k = SetKit(e, b),
      FRAME_OWNER = Int8List(e.W * e.H),
      FRAME_HITS = Uint8List(e.W * e.H) {
    final S = e.S, SIN = e.SIN;
    SOFA_C = at(114, 127 - .45 * S * SIN);
    SOFA_HW = 46 / S;
    BUT_C = at(181, 127 - .44 * S * SIN);
    BUT_HW = 21 / S;
    MES_C = at(121, 166 - .36 * S * SIN);
    MES_HW = 23 / S;
    MANTA_C = at(78, 188);
    MANTA_HW = 29 / S;
    MANTA_HD = 11 / (S * SIN);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // sala-set.html: SET
  final SalaState SET;
  bool get luz => SET.luz == '1';

  PpPalette get C => b.C;
  double get ST => b.ST;
  int get W => e.W;
  int get H => e.H;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  /* where the furniture stands: a centre on the floor, half-width (across the screen) and half-depth, the height */

  // sala-set.html: at. The floor point under a screen point
  List<double> at(num sx, num sy) {
    final g = e.unproject(sx, sy);
    return [g.x, g.y];
  }

  late final List<double> SOFA_C, BUT_C, MES_C, MANTA_C;
  late final double SOFA_HW, BUT_HW, MES_HW, MANTA_HW, MANTA_HD;
  static const double SOFA_HD = .45, BUT_HD = .44, MES_HD = .36, MES_H = .44;

  /* ---------- the floor: El balcón's porch tiles; through the door the porch itself, in the sun, its edge, and the lawn beyond ---------- */

  // sala-set.html: tileAt
  int tileAt(num a, num bb, num kk) {
    final ta = a / .5, tb = bb / .5, ea = ta - ta.floor(), eb = tb - tb.floor();
    if (ea < .07 || eb < .07) {
      return e.rgb(TILE[2][0] * kk, TILE[2][1] * kk, TILE[2][2] * kk);
    }
    final c = TILE[(ta.floor() + tb.floor()).remainder(2) != 0 ? 1 : 0];
    return e.rgb(c[0] * kk, c[1] * kk, c[2] * kk);
  }

  // sala-set.html: floorGround
  int floorGround(double x, double y, int ix, int iy, int i) {
    if (x >= 0 && y >= 0) {
      e.kinds[i] = KIND_ROAD;
      return tileAt(x, y, 1);
    }
    if (x < 0 && x > OUT_X && x - y > -D1 - .4 && x - y < -D0 + .4) {
      if (x > -PORCH_D + PORCH_EDGE) {
        e.kinds[i] = KIND_ROAD;
        return tileAt(x, y, 1.04);
      }
      // the porch's edge, its top lit
      if (x > -PORCH_D) {
        e.kinds[i] = KIND_ROAD;
        return e.rampOf(C.stone)[3];
      }
      // the lawn, PORCH_DROP below the porch: the sight line through this pixel meets it further out (x and y less by
      // PORCH_DROP * COS / SIN / R2)
      final kk = PORCH_DROP * e.COS / e.SIN / e.R2, gx = x - kk, gy = y - kk;
      e.kinds[i] = e.KIND_GRASS;
      final t = e.noise(gx * .45, gy * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
      return _rgbOf(e.GRASS[e.clamp((t * 4.2).floor() + 1, 0, 4)]);
    }
    return 0;
  }

  /* ---------- the walls ---------- */

  // sala-set.html: paper
  // the wallpaper: plain, a faint stripe; on the face in shade (+x) one ramp step darker, as block() shades its +x faces
  int paper(bool lit, num a, num z) {
    // the skirting board, its lit top edge
    if (z < .16) {
      return e.rampOf(WOOD)[z > .13
          ? 3
          : lit
          ? 2
          : 1];
    }
    final stripe = ((a + 10).remainder(.48)) < .05 ? -.45 : 0;
    return e.rampOf(WALLP)[e.clamp(
      ((lit ? 3.3 : 2.35) +
              stripe +
              (e.bayerAt((a * 72).truncate(), (z * 83).truncate()) - .5) * .3)
          .floor(),
      0,
      4,
    )];
  }

  // sala-set.html: walls
  void walls() {
    k.part('pared', () {
      // the left wall (faces +x), the door cut out of it; the back wall (faces +y), the window cut out of it
      // (pixel by pixel on the screen: set-kit.js planeFace; the walls were most of the bake with wallX's ST steps)
      k.planeFace(
        'x',
        0,
        0,
        YL,
        0,
        WH,
        (a, z) => a > D0 && a < D1 && z < DH ? 0 : paper(false, a, z),
      );
      k.planeFace(
        'y',
        0,
        0,
        XR,
        0,
        WH,
        (a, z) =>
            a > W0 && a < W1 && z > WZ0 && z < WZ1 ? 0 : paper(true, a, z),
      );
      // their cut tops: the wall's thickness, white
      final E = e.rampOf(WHITE);
      for (num bb = -T; bb <= YL; bb += ST * .8) {
        for (num t = -T; t <= 0; t += ST * .8) {
          e.plot(t, bb, WH, E[bb < 0 ? 3 : 3]);
        }
      }
      for (num a = 0; a <= XR; a += ST * .8) {
        for (num t = -T; t <= 0; t += ST * .8) {
          e.plot(a, t, WH, E[3]);
        }
      }
      for (num bb = -T; bb <= YL; bb += ST * .8) {
        e.plot(0, bb, WH - .02, E[2]);
      }
      for (num a = 0; a <= XR; a += ST * .8) {
        e.plot(a, 0, WH - .02, E[3]);
      }
    });
    k.part('puerta', doorway);
    k.part('ventana', windowAndCurtains);
    k.part('fotos', frames);
  }

  /* ---------- the door to the porch: the frame, the porch seen through it, the leaf open against the wall ---------- */

  // sala-set.html: doorway
  void doorway() {
    final F = e.rampOf(WHITE), Wd = e.rampOf(WOOD);
    const w = D1 - D0;
    k.revealX(0, D0, D1, 0, DH, T, WALLP);
    // the white casing round the opening (as El balcón's door frame)
    for (num z = 0; z <= DH + .14; z += ST * .5) {
      for (num a = 0; a <= .12; a += ST * .5) {
        e.plot(.03, D0 - .14 + a, z, F[2]);
        e.plot(.03, D1 + .02 + a, z, F[2]);
      }
    }
    for (num a = D0 - .14; a <= D1 + .14; a += ST * .5) {
      for (num z = DH; z <= DH + .14; z += ST * .5) {
        e.plot(.03, a, z, F[2]);
      }
    }
    // the leaf, open into the room and back against the wall, hinged at the far jamb (El balcón's panels)
    int panel(num t, num z) {
      final u = t * w, edge = u < .08 || u > w - .08 || z < .08 || z > DH - .08;
      final inPanel =
          u > .22 &&
          u < w - .22 &&
          ((z > .3 && z < 1.1) || (z > 1.3 && z < DH - .25));
      final rim =
          inPanel &&
          (u < .28 ||
              u > w - .28 ||
              (z - .3).abs() < .06 ||
              (z - 1.1).abs() < .06 ||
              (z - 1.3).abs() < .06 ||
              (z - (DH - .25)).abs() < .06);
      return Wd[edge
          ? 0
          : rim
          ? 0
          : inPanel
          ? 2
          : 1];
    }

    k.leaf(
      .06,
      D1 + .16,
      w,
      0,
      DH,
      LEAF_ANG,
      (t, z) => t > .96 ? Wd[0] : panel(t, z),
    );
    // the knob
    {
      final hx = .06 + math.cos(LEAF_ANG) * (w - .16),
          hy = D1 + .16 + math.sin(LEAF_ANG) * (w - .16);
      for (num a = 0; a <= .1; a += ST * .4) {
        for (num z = 0; z <= .1; z += ST * .4) {
          e.plot(hx + .03, hy + a, 1.15 + z, e.rgb(250, 210, 80));
        }
      }
    }
  }

  /* ---------- the window: white frame and bars, the sky and a branch outside, pink curtains on a wooden rod ---------- */

  // sala-set.html: windowAndCurtains
  void windowAndCurtains() {
    final F = e.rampOf(WHITE);
    k.reveal(0, W0, W1, WZ0, WZ1, T, WALLP);
    const mid = (W0 + W1) / 2, zm = WZ0 + (WZ1 - WZ0) * .55;
    k.paneY(-T + .02, W0, W1, WZ0, WZ1, (a, z) {
      final bar = (a - mid).abs() < .05 || (z - zm).abs() < .05;
      if (bar) return F[3];
      final lx = (a - (W1 - .35)) / .42,
          lz = (z - (WZ1 - .32)) / .2,
          lx2 = (a - (W1 - .75)) / .3,
          lz2 = (z - (WZ1 - .2)) / .14;
      if (lx * lx + lz * lz < 1 || lx2 * lx2 + lz2 * lz2 < 1) {
        return _rgbOf(
          lz < -.3 && lx2 * lx2 + lz2 * lz2 >= 1
              ? const [46, 154, 72]
              : const [76, 188, 88],
        );
      }
      final kk = (z - WZ0) / (WZ1 - WZ0);
      return _rgbOf(
        const [
          [162, 211, 255],
          [120, 186, 250],
          [85, 159, 242],
        ][e.clamp(
          (kk * 3 +
                  (e.hash((a * 40).truncate(), (z * 40).truncate()) - .5) * .6)
              .floor(),
          0,
          2,
        )],
      );
    });
    // the frame round the opening and the sill
    for (num a = W0 - .12; a <= W1 + .12; a += ST * .5) {
      for (final z in const [WZ0 - .12, WZ1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a, .03, z + h, F[3]);
        }
      }
    }
    for (num z = WZ0 - .12; z <= WZ1 + .12; z += ST * .5) {
      for (final a in const [W0 - .12, W1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a + h, .03, z, F[3]);
        }
      }
    }
    b.block(W0 - .2, 0, WZ0 - .2, W1 + .2, .14, WZ0 - .12, WHITE);
    // the curtains, gathered at each side, and the rod
    final P = e.rampOf(PINK);
    const cw = .42, cz0 = WZ0 - .45, cz1 = WZ1 + .3;
    for (final (a0, side) in const [(W0 - cw - .02, -1), (W1 + .02, 1)]) {
      for (num a = 0; a <= cw; a += ST * .4) {
        for (num z = cz0; z <= cz1; z += ST * .5) {
          final fold = math.sin((a / cw) * math.pi * 3), y = .1 + .05 * fold;
          e.plot(
            a0 + a,
            y,
            z,
            P[e.clamp(_round(2.6 + fold * .9 + (side < 0 ? -.2 : 0)), 0, 4)],
          );
        }
      }
    }
    final Wd = e.rampOf(WOOD);
    for (num a = W0 - cw - .15; a <= W1 + cw + .15; a += ST * .5) {
      for (num h = 0; h <= .07; h += ST * .5) {
        e.plot(a, .16, cz1 + .02 + h, Wd[2]);
        e.plot(a, .16 + h * .5, cz1 + .02, Wd[1]);
      }
    }
    for (final a in const [W0 - cw - .17, W1 + cw + .13]) {
      for (num h = 0; h <= .1; h += ST * .4) {
        for (num q = 0; q <= .06; q += ST * .4) {
          e.plot(a + q, .17, cz1 - .01 + h, Wd[3]);
        }
      }
    }
  }

  /* ---------- the three picture frames (round 2): upright pictures hanging on wires from nails in the left wall ---------- */

  // sala-set.html: frameGeom
  // Each frame is turned to face the camera, as the furniture is, so it shows as an upright rectangle: drawn pixel by
  // pixel on the screen, in front of the wall (the wall's own depth at that pixel, a hair nearer), so the furniture and
  // the lamp still stand in front of it. Frame coordinates (the old marco()'s): x across, y down, its origin at (0, 0);
  // the frame [-10, 10) x [0, FPH), the opening (a photo in it is the sprite layer's) [-8, 8) x [FMOULD, FPH - FMOULD);
  // the nail's pixel centre at (.5, -FWIRE - .5) of a straight frame. A crooked frame (fotos[i] = 1) is turned by TILT
  // about its middle (0, FPH / 2), as a picture that slid on its wire: the nail stays, the wire runs from it to the
  // turned frame's top.
  FrameGeom frameGeom(int i, [bool? crooked]) =>
      FrameGeom(i, crooked ?? SET.fotos[i] == '1');

  // sala-set.html: onLeftWall
  // the left wall's face (x = 0) under a pixel: its point (y, z) and depth, as planeFace finds it
  ({double y, double z, double d}) onLeftWall(int ix, int iy) {
    final u = (ix + .5 - e.OX) / e.S,
        kk = (iy + .5 - e.OY) / e.S,
        y = -u * e.R2,
        v = y / e.R2,
        z = (v * e.SIN - kk) / e.COS;
    return (y: y, z: z, d: v * e.COS + z * e.SIN);
  }

  // sala-set.html: FRAME_OWNER, FRAME_HITS
  // which frame drew each pixel, and what (for the checks: FRAME_OWNER = frame * 4 + 0 moulding, 1 opening, 2 wire, 3
  // nail; FRAME_HITS: how many frames)
  final Int8List FRAME_OWNER;
  final Uint8List FRAME_HITS;

  // JavaScript reads past the end of a typed array as undefined: `undefined >> 2` and `undefined & 3` are 0
  int _owner(int j) => j >= 0 && j < FRAME_OWNER.length ? FRAME_OWNER[j] : 0;

  // sala-set.html: frames
  void frames() {
    final Wd = e.rampOf(WOOD),
        DARK = e.rgb(42, 24, 16),
        WIRE = e.rgb(60, 44, 34),
        NAIL = e.rgb(40, 30, 24),
        PAPER = _rgbOf(RP_CREAM3),
        PAPER_D = e.rgb(214, 196, 150);
    FRAME_OWNER.fillRange(0, FRAME_OWNER.length, -1);
    FRAME_HITS.fillRange(0, FRAME_HITS.length, 0);
    final zb = e.zb, pix = e.pix;
    void put(int ix, int iy, int col, int i, int kind) {
      if (ix < 0 || iy < 0 || ix >= W || iy >= H) return;
      final w = onLeftWall(ix, iy), j = iy * W + ix, d = w.d + .01;
      // two frames on one pixel: the checks refuse it
      if (FRAME_OWNER[j] >= 0 && FRAME_OWNER[j] >> 2 != i) {
        FRAME_HITS[j] = 2;
        return;
      }
      // (its own pixels: the nail goes over the wire's end)
      if (d <= zb[j] && FRAME_OWNER[j] < 0) return;
      zb[j] = d;
      pix[j] = col;
      FRAME_HITS[j] = 1;
      FRAME_OWNER[j] = i * 4 + kind;
    }

    for (var i = 0; i < 3; i++) {
      final g = frameGeom(i),
          xs = g.frame.map((p) => p[0]),
          ys = g.frame.map((p) => p[1]);
      for (
        var iy = ys.reduce(math.min).floor() - 1;
        iy <= ys.reduce(math.max).ceil() + 1;
        iy++
      ) {
        for (
          var ix = xs.reduce(math.min).floor() - 1;
          ix <= xs.reduce(math.max).ceil() + 1;
          ix++
        ) {
          final f = g.toFrame(ix + .5, iy + .5), fx = f[0], fy = f[1];
          if (fx < FRAME_BOX[0] ||
              fx >= FRAME_BOX[2] ||
              fy < FRAME_BOX[1] ||
              fy >= FRAME_BOX[3]) {
            continue;
          }
          final cx = fx.floor(), cy = fy.floor();
          if (fx >= FRAME_OPEN[0] &&
              fx < FRAME_OPEN[2] &&
              fy >= FRAME_OPEN[1] &&
              fy < FRAME_OPEN[3]) {
            // the paper, the moulding's shadow on its top and left
            put(
              ix,
              iy,
              cy == FRAME_OPEN[1] || cx == FRAME_OPEN[0] ? PAPER_D : PAPER,
              i,
              1,
            );
            continue;
          }
          final edge =
              cx == FRAME_BOX[0] ||
              cx == FRAME_BOX[2] - 1 ||
              cy == FRAME_BOX[1] ||
              cy == FRAME_BOX[3] - 1;
          put(
            ix,
            iy,
            edge
                ? DARK
                : cy == FRAME_BOX[1] + 1
                ? Wd[4]
                : cx == FRAME_BOX[2] - 2 || cy == FRAME_BOX[3] - 2
                ? Wd[1]
                : Wd[2],
            i,
            0,
          );
        }
      }
      // the wire, from the nail to two points on the frame's top, and the nail
      final nc = [g.nail[0] + .5, g.nail[1] + .5];
      for (final tx in const [-4.5, 5.5]) {
        final en = g.toScreen([tx, .5]);
        for (num t = 0; t <= 1; t += .05) {
          final sx = nc[0] + (en[0] - nc[0]) * t,
              sy = nc[1] + (en[1] - nc[1]) * t,
              ix = sx.floor(),
              iy = sy.floor();
          final o = _owner(iy * W + ix);
          if (o >> 2 == i && (o & 3) != 2) continue;
          put(ix, iy, WIRE, i, 2);
        }
      }
      put(g.nail[0], g.nail[1], NAIL, i, 3);
    }
  }

  /* ---------- the furniture, turned to face the camera ---------- */

  // sala-set.html: cloth
  // flat bands for upholstery (shade()'s grain reads as dirt on cloth): the top lit, the front a step down, the side in shade
  int Function(num s, num t, num z, String face) cloth(List<int> c) =>
      (s, t, z, face) =>
          e.rampOf(c)[face == 'top'
              ? 3
              : face == 'front'
              ? 2
              : 1];

  // sala-set.html: atT
  List<double> atT(List<double> c, num s, num t) => [
    c[0] + math.cos(TURN) * s - math.sin(TURN) * t,
    c[1] + math.sin(TURN) * s + math.cos(TURN) * t,
  ];

  // sala-set.html: furniture
  void furniture() {
    final S = e.S, SIN = e.SIN;
    // the long sofa: feet, a base, two seat cushions, the back, the arms
    k.part('sofa', () {
      final c = SOFA_C, hw = SOFA_HW;
      const hd = SOFA_HD;
      for (final s in [-hw + .12, hw - .12]) {
        for (final t in const [-hd + .1, hd - .1]) {
          final p = atT(c, s, t);
          k.turnedBox(p[0], p[1], 0, .12, .05, .05, TURN, WOOD);
        }
      }
      k.turnedBox(c[0], c[1], .12, .38, hw, hd, TURN, SOFA_D, cloth(SOFA_D));
      for (final kk in const [-1, 1]) {
        final p = atT(c, kk * (hw - .2) / 2 + kk * .0, .05);
        k.turnedBox(
          p[0],
          p[1],
          .38,
          .52,
          (hw - .26) / 2 - .02,
          hd - .05,
          TURN,
          SOFA,
          (s, t, z, face) => face == 'top' && (t > hd - .14)
              ? e.rgb(138, 208, 190)
              : cloth(SOFA)(s, t, z, face),
        );
      }
      {
        final p = atT(c, 0, -hd + .14);
        k.turnedBox(
          p[0],
          p[1],
          .38,
          1.32,
          hw - .1,
          .14,
          TURN,
          SOFA,
          (s, t, z, face) =>
              face == 'front' &&
                  ((s + 4) * S).truncate().remainder(3) == 0 &&
                  (z * S * .87).truncate().remainder(3) == 0 &&
                  z < 1.25 &&
                  z > .55
              ? e.rampOf(SOFA)[1]
              : cloth(SOFA)(s, t, z, face),
        );
      }
      for (final kk in const [-1, 1]) {
        final p = atT(c, kk * (hw - .12), 0);
        k.turnedBox(p[0], p[1], .12, .78, .12, hd, TURN, SOFA, cloth(SOFA));
      }
    });
    // abuelo's armchair (la butaca), orange
    k.part('butaca', () {
      final c = BUT_C, hw = BUT_HW;
      const hd = BUT_HD;
      for (final s in [-hw + .1, hw - .1]) {
        for (final t in const [-hd + .1, hd - .1]) {
          final p = atT(c, s, t);
          k.turnedBox(p[0], p[1], 0, .12, .05, .05, TURN, WOOD);
        }
      }
      k.turnedBox(c[0], c[1], .12, .38, hw, hd, TURN, ORNG_D, cloth(ORNG_D));
      {
        final p = atT(c, 0, .05);
        k.turnedBox(
          p[0],
          p[1],
          .38,
          .52,
          hw - .26,
          hd - .05,
          TURN,
          ORNG,
          cloth(ORNG),
        );
      }
      {
        final p = atT(c, 0, -hd + .14);
        k.turnedBox(
          p[0],
          p[1],
          .38,
          1.22,
          hw - .1,
          .14,
          TURN,
          ORNG,
          (s, t, z, face) =>
              face == 'front' &&
                  (((s + 2).remainder(.27)) - .135).abs() < .025 &&
                  (((z + 2).remainder(.27)) - .135).abs() < .025
              ? e.rgb(138, 66, 18)
              : cloth(ORNG)(s, t, z, face),
        );
      }
      for (final kk in const [-1, 1]) {
        final p = atT(c, kk * (hw - .13), 0);
        k.turnedBox(p[0], p[1], .12, .8, .13, hd, TURN, ORNG, cloth(ORNG));
      }
    });
    // the low table: four legs, a stretcher, the top
    k.part('mesita', () {
      final c = MES_C, hw = MES_HW;
      const hd = MES_HD, h = MES_H;
      for (final s in [-hw + .12, hw - .12]) {
        for (final t in const [-hd + .08, hd - .08]) {
          final p = atT(c, s, t);
          k.turnedBox(p[0], p[1], 0, h - .08, .05, .05, TURN, WOOD);
        }
      }
      k.turnedBox(c[0], c[1], .16, .2, hw - .14, .03, TURN, WOOD);
      k.turnedBox(
        c[0],
        c[1],
        h - .08,
        h,
        hw,
        hd,
        TURN,
        WOOD,
        (s, t, z, face) => face == 'top'
            ? b.shade(
                WOOD,
                3.3 + (t.abs() > hd - .05 || s.abs() > hw - .05 ? .6 : 0),
                s * 3,
                t * 9,
              )
            : 0,
      );
    });
    // the floor lamp in the corner: a round foot, a thin pole, the shade (lit: warm yellow; off: cream)
    k.part('lampara', () {
      final x = LAMP[0], y = LAMP[1];
      const G = [148, 148, 166];
      k.drum(x, y, 0, .05, .22, G);
      k.drum(x, y, .05, LAMP_H - .5, .035, G);
      final sh = luz ? LAMPY : CREAMY, R = e.rampOf(sh);
      const z0 = LAMP_H - .52;
      for (num z = z0; z <= LAMP_H; z += ST * .6) {
        final kk = (z - z0) / .52,
            r = .34 - .16 * kk,
            n = (2 * math.pi * r / (ST * .5)).ceil();
        for (var m = 0; m < n; m++) {
          final f = m / n * 2 * math.pi, nx = math.cos(f), ny = math.sin(f);
          if (nx + ny < -.4) continue;
          e.plot(
            x + nx * r,
            y + ny * r,
            z,
            R[e.clamp(
              _round((luz ? 3.2 : 2.6) + (nx + ny) * .35 + (kk > .9 ? .6 : 0)),
              0,
              4,
            )],
          );
        }
      }
      k.drum(x, y, LAMP_H - .02, LAMP_H, .18, sh);
    });
    // the baby's blanket on the floor: pale blue, white squares
    k.part('manta', () {
      final c = MANTA_C;
      k.turnedBox(c[0], c[1], 0, .025, MANTA_HW, MANTA_HD, TURN, BLANKET, (
        s,
        t,
        z,
        face,
      ) {
        if (face != 'top') return e.rgb(120, 170, 200);
        final ps = (s + MANTA_HW) * S / 4, pt = (t + MANTA_HD) * S * SIN / 4;
        if (t < -MANTA_HD + .06) return e.rgb(220, 238, 255);
        return (ps.truncate() + pt.truncate()).remainder(2) != 0 &&
                (ps.remainder(1)) < .5 &&
                (pt.remainder(1)) < .5
            ? e.rgb(255, 255, 255)
            : _rgbOf(BLANKET);
      });
    });
    // a plant in a pot by the back wall, at the right
    k.part('planta', () {
      final x = PLANT[0], y = PLANT[1];
      k.drum(x, y, 0, .42, .24, const [206, 112, 64]);
      k.drum(x, y, .38, .44, .27, const [226, 132, 80]);
      for (final l in const [
        [0, 0, .74, .28],
        [-.17, .12, .64, .19],
        [.15, .14, .66, .2],
        [.04, -.1, .9, .17],
      ]) {
        e.sphere(x + l[0], y + l[1], l[2], l[3], C.leaf, 'rough');
      }
    });
  }

  /* ---------- bake one state ---------- */

  // sala-set.html: buildSet
  void buildSet() {
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
    final cache = _groundCaches[e];
    if (cache == null) {
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = floorGround(g.x, g.y, ix, iy, i);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      e.growGrass();
      _groundCaches[e] = _GroundCache(
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
    walls();
    furniture();
    // the furniture's shadows on the floor: small and low, under each piece (as El balcón's)
    e.castShadow(SOFA_C[0], SOFA_C[1], .3, SOFA_HW * .7);
    e.castShadow(BUT_C[0], BUT_C[1], .3, BUT_HW * .85);
    e.castShadow(MES_C[0], MES_C[1], .25, MES_HW * .6);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.skyFill((ix, iy) => _rgbOf(BACKDROP));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
