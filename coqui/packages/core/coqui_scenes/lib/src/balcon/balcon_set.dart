// Port of docs/proyecto/pixel/balcon-set.html: El balcón's set, every state, call for call (order 30a's set reference,
// order 30b's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El balcón's set is built on (balcon-set.html: `window.PP_SCENE`, with the page's default origin, which
/// is the sheet's): 240 × 216, S 26, origin (38, 20), shadows to (.9, -.1).
PpEngine balconEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 38,
  originY: 20,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (balcon-set.html: `SET`, from the address). The values are the page's own strings.
class BalconState {
  const BalconState({this.door = 'shut', this.win = 'shut'});

  /// balcon-set.html: `pick(...)` of each parameter from a query (`?door=open&win=shut`); a value the page does not
  /// allow takes its default, as there.
  factory BalconState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return BalconState(
      door: pick('door', const ['shut', 'open'], 'shut'),
      win: pick('win', const ['shut', 'open'], 'shut'),
    );
  }

  /// A key of the sheet's `setKey` table (`"shut-shut"`: door, then win) read back.
  factory BalconState.fromKey(String key) {
    final m = RegExp(r'^(shut|open)-(shut|open)$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', 'not a key of El balcón\'s set');
    }
    return BalconState(door: m[1]!, win: m[2]!);
  }

  final String door, win;

  /// The sheet's key: door + win (`setKey.key`: "door + win, e.g. \"shut-shut\"").
  String get key => '$door-$win';
}

/* ---------- the plan of the place (world units; the porch front faces +y, like El frente's house) ---------- */

const double HX0 = -5.8, HX1 = 7.8, HY1 = 0; // the house wall behind the porch
const double HY0 = -.4; // the house's depth behind the wall (only its roof shows it: shallow, so less roof)
const double FLOOR = .3; // the porch floor, two steps up from the lawn
const double PD = 3.0; // the porch's depth
const double DOOR0 = 2.2,
    DOOR1 = 3.5,
    DH = 2.55; // the doorway, from the porch floor up
// the round table: its middle, radius, height above the floor
const List<double> TABLE = [-.26, 1.1];
const double TABLE_R = .95, TABLE_H = .75;
// the wall behind the table, from the camera (a sight line keeps x - y)
final double XW = TABLE[0] - TABLE[1];
// the window opening: over the table, wider than tall (as the old one)
final double WIN0 = XW - .4, WIN1 = XW + .8;
const double WZ0 = FLOOR + 1.5, WZ1 = FLOOR + 2.35;
// the window's top as the roof, its touch box and pair 1 take it (round 3's head ledge; the ledge is gone, the number stays)
const double WIN_TOP = WZ1 + .2;
// the flower box: under the window, centred on it: the bird's perch (sheet: points.PERCH)
final double BOX0 = WIN0 - .15, BOX1 = WIN1 + .15;
const double BZ0 = WZ0 - .32, BZ1 = WZ0 - .1, BOXD = .3;
// the bare middle of the box (no flowers), where the bird's feet stand on its front edge
const double PERCH_GAP = .8;
const double
EAVE = .25,
RISE =
    .45; // the roof: eaves EAVE past the walls, the ridge RISE above the eaves
const double RY1 =
    1.1; // the roof covers the back of the porch only (over the furniture)
// a roof edge d in front of the wall hides the wall above HF - T30R2 * d from this camera
final double T30R2 = math.tan(math.pi / 6) * math.sqrt2;
// the wall shows up to here: a strip of wall over the window (round 3's, unchanged)
const double WALL_TOP = WIN_TOP + 1.05;
// the eaves (their fascia .12 deep): as low as lets that wall show (and so a strip of wall over the door too)
final double HF = ((WALL_TOP + T30R2 * RY1 + .12) * 20).ceil() / 20;
// the steps (x), at the porch's front: the path leaves the lower step's front at its middle
const double STEP0 = 1.64, STEP1 = 3.04;
// abuela's big chair, turned to the camera (order 30b: .35 along the wall from round 4's -3.85: its hint frame whole in the wide view, her bubble too)
const List<double> SILLA = [-3.5, .98];
const double SILLA_HW = .74, SILLA_HD = .5;
// the small yellow chair, turned to the camera, clear of the door frame
const List<double> SILLITA = [1.63, .62];
const double SILLITA_HW = .44, SILLITA_HD = .3;
const double TURN = -math.pi / 4; // furniture turned to face the camera
// where the path leaves the lower step's front, at its middle (u = x - y, v = x + y)
const double PATH_U = (STEP0 + STEP1) / 2 - PD - .7,
    PATH_V = (STEP0 + STEP1) / 2 + PD + .7;
const List<double> BUSH1 = [-4.4, 4.6], BUSH2 = [5.2, 4.2];
const double HZ = 40; // the horizon, in screen rows: sky above
const List<int> TEAL = [92, 190, 186],
    WOOD = [150, 98, 56],
    WHITE = [244, 240, 228];
// the old porch's tiles: light, dark, the joints
const List<List<int>> TILE = [
  [238, 220, 176],
  [224, 198, 144],
  [184, 154, 106],
];
const List<int> CANE = [234, 217, 168],
    CANE_D = [201, 168, 102],
    YEL = [244, 200, 70],
    CUSHION = [200, 82, 64],
    CUSHION_L = [232, 120, 92];

/// balcon-set.html: `SKY`.
const List<List<num>> SKY_BANDS = [
  [58, 134, 230],
  [85, 159, 242],
  [120, 186, 250],
  [162, 211, 255],
  [208, 234, 255],
];
const List<List<num>> SKY_FAR = [
  [116, 180, 162],
  [156, 208, 188],
  [94, 158, 144],
];
const List<List<num>> SKY_NEAR = [
  [78, 158, 94],
  [124, 203, 122],
  [62, 136, 80],
];

final double R2 = math.sqrt2;

/* ---------- the roof's height over a ground point (hipRoof's own formula), for clipping the walls under it ---------- */

const double RX0 = HX0 - EAVE, RY0 = HY0 - EAVE, RX1 = HX1 + EAVE;

// balcon-set.html: roofZ
double roofZ(num x, num y) {
  const xc = (RX0 + RX1) / 2,
      yc = (RY0 + RY1) / 2,
      hy = (RY1 - RY0) / 2,
      hx = (RX1 - RX0) / 2;
  final fy = (hy - (y - yc).abs()) / hy, fx = (hx - (x - xc).abs()) / hy;
  return HF + RISE * math.min(math.min(fy, fx), 1);
}

/// The ground and its grass, the same in every state: made once, then copied (balcon-set.html: `GROUND_CACHE`). One
/// per engine.
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

/// The set of El balcón in one state, built into an engine (balcon-set.html, from "the ground" to "bake one state").
class BalconSet {
  BalconSet(this.e, this.b, this.SET) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // balcon-set.html: SET
  final BalconState SET;

  PpPalette get C => b.C;
  double get ST => b.ST;

  int _rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  /* ---------- the ground ---------- */

  // balcon-set.html: yardGround
  int yardGround(double x, double y, int ix, int iy, int i) {
    if (iy + .5 < HZ) return 0;
    // u = x - y, v = x + y (world, not scaled)
    final u = (x - y) / R2 * R2, v = (x + y);
    // round 3: as wide as the lower step where it leaves it, and it opens out towards the camera (the old path's wedge)
    final pu = u - PATH_U, pv = v - PATH_V, half = .95 + math.max(0, pv) * .22;
    // it starts along the lower step's front edge
    if (y > PD + .66 && pv > -1.5 && pu.abs() < half) {
      e.kinds[i] = KIND_ROAD;
      // (pq: the rows counted from above the step, so never negative)
      final pq = pv + 2.1,
          r = (pq / .7).floor(),
          off = r.remainder(2) != 0 ? .35 : 0,
          c = ((pu + 3 + off) / .7).floor();
      final gap =
          pq.remainder(.7) < .08 ||
          (pu + 3 + off).remainder(.7) < .07 ||
          half - pu.abs() < .07;
      return gap
          ? e.rgb(C.stone[0] * .62, C.stone[1] * .62, C.stone[2] * .62)
          : b.toneOf(
              C.pave,
              .35 + e.hash(r, c) * .5 + (e.hash(ix, iy) - .5) * .2,
              ix,
              iy,
            );
    }
    e.kinds[i] = e.KIND_GRASS;
    final t = e.noise(x * .45, y * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
    return _rgbOf(e.GRASS[e.clamp((t * 4.2).floor() + 1, 0, 4)]);
  }

  // balcon-set.html: wallUnderRoof
  // a +y wall up to the roof: wallY's siding, holes, and its top cut where the roof comes down
  // (above HF - .817 d, d the roof's reach in front of the wall at that column, the roof hides the wall from this
  // camera: not drawn, the same picture)
  void wallUnderRoof(
    num at,
    num a0,
    num a1,
    List<num> c,
    List<List<num>> holes,
    num boards,
  ) {
    for (num a = a0; a <= a1; a += ST) {
      final reach = math.min(RY1 - at, RX1 - a),
          hid = HF - math.tan(math.pi / 6) * math.sqrt2 * reach + .25;
      final hs = holes.where((h) => a > h[0] && a < h[1]).toList(),
          top = math.min(roofZ(a, at) - .04, hid);
      for (num z = 0; z <= top; z += ST) {
        var hole = false;
        for (var kk = 0; kk < hs.length; kk++) {
          if (z > hs[kk][2] && z < hs[kk][3]) {
            hole = true;
            break;
          }
        }
        if (!hole) {
          e.plot(
            a,
            at,
            z,
            b.shade(
              c,
              boards != 0 && z.remainder(boards) < boards * .17 ? 1.5 : 2.4,
              a,
              z,
            ),
          );
        }
      }
    }
  }

  /* ---------- the house wall, the door, the window ---------- */

  // balcon-set.html: house
  void house() {
    final holeD = <num>[DOOR0, DOOR1, FLOOR, FLOOR + DH],
        holeW = <num>[WIN0, WIN1, WZ0, WZ1];
    k.part('casa', () {
      wallUnderRoof(HY1, HX0, HX1, TEAL, [holeD, holeW], .21);
      for (num bb = HY0; bb <= HY1; bb += ST) {
        final top = roofZ(HX1, bb) - .04;
        for (num z = 0; z <= top; z += ST) {
          e.plot(
            HX1,
            bb,
            z,
            b.shade(TEAL, z.remainder(.21) < .21 * .17 ? .5 : 1.3, bb, z),
          );
        }
      }
      b.onWall('y', HY1, HX0, HX1, FLOOR, FLOOR + .3, e.rampOf(TEAL)[1]);
      // white corner boards at the right end
      for (num z = 0; z <= roofZ(HX1, HY1); z += ST * .5) {
        for (num a = 0; a <= .14; a += ST * .5) {
          e.plot(HX1 - a, HY1 + .02, z, e.rampOf(WHITE)[2]);
          e.plot(HX1 + .02, HY1 - a, z, e.rampOf(WHITE)[1]);
        }
      }
    });
    k.part('puerta', doorway);
    k.part('ventana', windowAndShutters);
    k.part('jardinera', flowerBox);
    k.part('flores', flowers);
  }

  // the room behind an opening (as El frente's, lights off: a dim room, not a hole)
  static const double BACK =
      -1.2; // as deep as round 1's: only the doorway and the window show it

  // balcon-set.html: room
  void room(num a0, num a1, bool floor) {
    const d = HY1 - BACK;
    for (
      num a = math.max(HX0 + .02, a0 - d - .15);
      a <= math.min(HX1 - .02, a1 - d + .1);
      a += ST
    ) {
      for (num z = FLOOR; z <= FLOOR + DH + .4; z += ST) {
        final kk = (z - FLOOR) / 2;
        e.plot(
          a,
          BACK,
          z,
          z < FLOOR + .16
              ? e.rgb(44, 32, 26)
              : e.rgb(66 - kk * 14, 72 - kk * 14, 74 - kk * 12),
        );
      }
    }
    if (floor) {
      for (
        num a = math.max(HX0 + .02, a0 - d - .15);
        a <= math.min(HX1 - .02, a1 + .05);
        a += ST
      ) {
        for (num bb = BACK; bb <= HY1 - .01; bb += ST) {
          final seam = (a + 5).remainder(.22) < .03;
          e.plot(a, bb, FLOOR, seam ? e.rgb(58, 40, 28) : e.rgb(70, 50, 36));
        }
      }
    }
  }

  // balcon-set.html: doorway
  void doorway() {
    const z0 = FLOOR, z1 = FLOOR + DH, w = DOOR1 - DOOR0;
    k.reveal(HY1, DOOR0, DOOR1, z0, z1, .22, TEAL);
    room(DOOR0, DOOR1, true);
    final F = e.rampOf(WHITE);
    for (num z = z0; z <= z1 + .14; z += ST * .5) {
      for (num a = 0; a <= .12; a += ST * .5) {
        e.plot(DOOR0 - .14 + a, HY1 + .03, z, F[3]);
        e.plot(DOOR1 + .02 + a, HY1 + .03, z, F[2]);
      }
    }
    for (num a = DOOR0 - .14; a <= DOOR1 + .14; a += ST * .5) {
      for (num z = z1; z <= z1 + .14; z += ST * .5) {
        e.plot(a, HY1 + .03, z, F[3]);
      }
    }
    final Wd = e.rampOf(WOOD);
    int panel(num t, num z) {
      final u = t * w,
          edge = u < .08 || u > w - .08 || z < z0 + .08 || z > z1 - .08;
      final inPanel =
          u > .22 &&
          u < w - .22 &&
          ((z > z0 + .3 && z < z0 + 1.1) || (z > z0 + 1.3 && z < z1 - .25));
      final rim =
          inPanel &&
          (u < .28 ||
              u > w - .28 ||
              (z - (z0 + .3)).abs() < .06 ||
              (z - (z0 + 1.1)).abs() < .06 ||
              (z - (z0 + 1.3)).abs() < .06 ||
              (z - (z1 - .25)).abs() < .06);
      return Wd[edge
          ? 1
          : rim
          ? 1
          : inPanel
          ? 3
          : 2];
    }

    if (SET.door == 'shut') {
      k.paneY(
        HY1 - .06,
        DOOR0,
        DOOR1,
        z0,
        z1,
        (a, z) => panel((DOOR1 - a) / w, z),
      );
      for (num a = 0; a <= .1; a += ST * .4) {
        for (num z = 0; z <= .1; z += ST * .4) {
          e.plot(
            DOOR0 + .14 + a,
            HY1 - .03,
            z0 + 1.15 + z,
            e.rgb(250, 210, 80),
          );
        }
      }
    } else {
      k.leaf(
        DOOR1,
        HY1 - .06,
        w,
        z0,
        z1,
        math.pi + 1.45,
        (t, z) => t > .96 ? Wd[0] : panel(t, z),
      );
    }
  }

  // balcon-set.html: windowAndShutters
  void windowAndShutters() {
    final ww = WIN1 - WIN0, F = e.rampOf(WHITE);
    k.reveal(HY1, WIN0, WIN1, WZ0, WZ1, .22, TEAL);
    room(WIN0, WIN1, false);
    for (num a = WIN0 - .12; a <= WIN1 + .12; a += ST * .5) {
      for (final z in const [WZ0 - .12, WZ1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a, HY1 + .03, z + h, F[3]);
        }
      }
    }
    for (num z = WZ0 - .12; z <= WZ1 + .12; z += ST * .5) {
      for (final a in [WIN0 - .12, WIN1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a + h, HY1 + .03, z, F[3]);
        }
      }
    }
    int slats(num u, num z, num w) {
      final s = ((z - WZ0) / .1).floor().remainder(2),
          edge = u < .06 || u > w - .06 || z < WZ0 + .06 || z > WZ1 - .06;
      return F[edge
          ? 2
          : s != 0
          ? 3
          : 2];
    }

    final half = ww / 2;
    if (SET.win == 'shut') {
      for (num a = WIN0; a <= WIN1; a += ST * .4) {
        for (num z = WZ0; z <= WZ1; z += ST * .4) {
          final u = a < WIN0 + half ? a - WIN0 : a - WIN0 - half;
          e.plot(a, HY1 - .06, z, slats(u, z, half));
        }
      }
      for (final a in [WIN0 + half - .1, WIN0 + half + .04]) {
        for (num p = 0; p <= .06; p += ST * .3) {
          for (num q = 0; q <= .06; q += ST * .3) {
            e.plot(a + p, HY1 - .02, (WZ0 + WZ1) / 2 + q, e.rgb(60, 44, 34));
          }
        }
      }
    } else {
      const lw = .4;
      for (num a = 0; a <= lw; a += ST * .4) {
        for (num z = WZ0; z <= WZ1; z += ST * .4) {
          final fold = (a - lw / 2).abs() < .03,
              col = fold ? e.rampOf(WHITE)[1] : slats(a, z, lw);
          e.plot(WIN0 - .14 - lw + a, HY1 + .05, z, col);
          e.plot(WIN1 + .14 + a, HY1 + .05, z, col);
        }
      }
    }
  }

  // balcon-set.html: flowerBox
  // the flower box: under the window, centred on it (as El frente's); the bird stands on its top front edge, in the middle
  void flowerBox() {
    b.block(BOX0, HY1, BZ0, BOX1, HY1 + BOXD, BZ1, C.wood);
    for (num a = BOX0 + .04; a <= BOX1 - .04; a += ST * .5) {
      for (num bb = HY1 + .04; bb <= HY1 + BOXD - .04; bb += ST * .5) {
        e.plot(a, bb, BZ1 + .005, e.rgb(96, 66, 44));
      }
    }
  }

  // balcon-set.html: flowers
  // its flowers: a clump of three at each end; the middle (PERCH_GAP wide) is bare soil, so the bird's feet show on the
  // front edge, not among the flowers
  void flowers() {
    final mid = (WIN0 + WIN1) / 2;
    const FL = [
      [255, 143, 184],
      [255, 224, 112],
      [244, 88, 74],
    ];
    for (final side in const [-1, 1]) {
      for (var kk = 0; kk < 3; kk++) {
        e.sphere(
          mid + side * (PERCH_GAP / 2 + kk * .11),
          HY1 + .16,
          BZ1 + .03,
          .1,
          FL[(kk + (side > 0 ? 1 : 0)) % 3],
          'solid',
        );
      }
    }
  }

  /* ---------- the porch: the tiled floor, the stone base and steps, the roof ---------- */

  // balcon-set.html: slabTiles
  int slabTiles(num a, num bb) {
    final ta = (a - HX0) / .5,
        tb = bb / .5,
        ea = ta - ta.floor(),
        eb = tb - tb.floor();
    if (ea < .07 || eb < .07) return _rgbOf(TILE[2]);
    return _rgbOf(TILE[(ta.floor() + tb.floor()).remainder(2) != 0 ? 1 : 0]);
  }

  // balcon-set.html: porch
  void porch() {
    k.part('balcon', () {
      // the floor: a slab whose top takes the characters' shadows (slab's way), tiled
      final zb = e.zb, before = Float32List.fromList(zb);
      for (num a = HX0; a <= HX1 + .1; a += ST) {
        for (num bb = HY1; bb <= PD; bb += ST) {
          e.plot(a, bb, FLOOR, slabTiles(a, bb));
        }
      }
      for (var i = 0; i < e.W * e.H; i++) {
        if (zb[i] != before[i]) k.slabTops.addAll([i, zb[i]]);
      }
      for (num a = HX0; a <= HX1 + .1; a += ST) {
        for (num z = 0; z <= FLOOR; z += ST) {
          e.plot(a, PD, z, b.shade(C.stone, z > FLOOR - .05 ? 3 : 2.1, a, z));
        }
      }
      for (num bb = HY1; bb <= PD; bb += ST) {
        for (num z = 0; z <= FLOOR; z += ST) {
          e.plot(HX1 + .1, bb, z, b.shade(C.stone, 1.3, bb, z));
        }
      }
    });
    k.part('escalones', () {
      k.slab(STEP0, PD, STEP1, PD + .35, FLOOR * 2 / 3, C.stone);
      k.slab(STEP0 - .25, PD + .35, STEP1 + .25, PD + .7, FLOOR / 3, C.stone);
    });
    k.part(
      'techo',
      () => k.hipRoof(RX0, RY0, RX1, RY1, HF, RISE, C.red, WHITE),
    );
  }

  /* ---------- the furniture ---------- */

  // balcon-set.html: furniture
  void furniture() {
    const Wd = WOOD;
    // abuela's big chair: a wooden frame, a woven back and seat, arms; turned to the camera
    k.part('silla_grande', () {
      final x = SILLA[0], y = SILLA[1];
      const hw = SILLA_HW, hd = SILLA_HD, f = FLOOR;
      List<num> at(num s, num t) => [
        x + math.cos(TURN) * s - math.sin(TURN) * t,
        y + math.sin(TURN) * s + math.cos(TURN) * t,
      ];
      void leg(num s, num t, num z1) {
        final p = at(s, t);
        k.turnedBox(p[0], p[1], f, f + z1, .07, .07, TURN, Wd);
      }

      leg(-hw + .07, hd - .07, .5);
      leg(hw - .07, hd - .07, .5);
      leg(-hw + .07, -hd + .07, 1.55);
      leg(hw - .07, -hd + .07, 1.55);
      k.turnedBox(
        x,
        y,
        f + .42,
        f + .5,
        hw,
        hd,
        TURN,
        Wd,
        (s, t, z, face) =>
            face == 'top' && s.abs() < hw - .1 && t > -hd + .12 && t < hd - .06
            ? _rgbOf(
                (((s + 2) / .07).floor() + ((t + 2) / .07).floor()).remainder(
                          2,
                        ) !=
                        0
                    ? CANE
                    : CANE_D,
              )
            : 0,
      );
      // the seat shows from this camera: a red cushion on it (round 3: the empty chair read as a screen), its front face darker
      k.turnedBox(
        x,
        y,
        f + .5,
        f + .6,
        hw - .1,
        hd - .06,
        TURN,
        CUSHION,
        (s, t, z, face) => face == 'top'
            ? _rgbOf((s.abs() > hw - .17 || t > hd - .13) ? CUSHION_L : CUSHION)
            : 0,
      );
      // the back: a woven panel between the back legs
      final bp = at(0, -hd + .05);
      final l0 = at(-hw + .12, -hd + .05);
      k.leaf(l0[0], l0[1], 2 * (hw - .12), f + .55, f + 1.38, TURN, (tt, z) {
        final s = tt * 2 * (hw - .12);
        return _rgbOf(
          ((s / .07).floor() + (z / .07).floor()).remainder(2) != 0
              ? CANE
              : CANE_D,
        );
      });
      k.turnedBox(bp[0], bp[1], f + 1.38, f + 1.5, hw, .06, TURN, Wd);
      // the arms
      for (final s in const [-hw + .05, hw - .05]) {
        final p = at(s, 0);
        k.turnedBox(p[0], p[1], f + .78, f + .84, .07, hd, TURN, Wd);
        final q = at(s, hd - .07);
        k.turnedBox(q[0], q[1], f + .5, f + .78, .05, .05, TURN, Wd);
      }
    });
    // the small round table: a foot, a post, the top
    k.part('mesa', () {
      final x = TABLE[0], y = TABLE[1];
      const f = FLOOR;
      k.drum(x, y, f, f + .06, .34, Wd);
      k.drum(x, y, f + .06, f + TABLE_H - .07, .07, Wd);
      k.drum(x, y, f + TABLE_H - .07, f + TABLE_H, TABLE_R, Wd, (a, bb) {
        final r = math.sqrt(a * a + bb * bb);
        return r > TABLE_R - .07
            ? e.rampOf(Wd)[2]
            : b.shade(
                Wd,
                3.4 + (e.hash((a * 30).truncate(), 1) - .5) * .3,
                a * 4,
                bb * 4,
              );
      });
    });
    // the small yellow chair
    k.part('silla_pequena', () {
      final x = SILLITA[0], y = SILLITA[1];
      const hw = SILLITA_HW, hd = SILLITA_HD, f = FLOOR;
      List<num> at(num s, num t) => [
        x + math.cos(TURN) * s - math.sin(TURN) * t,
        y + math.sin(TURN) * s + math.cos(TURN) * t,
      ];
      void leg(num s, num t, num z1) {
        final p = at(s, t);
        k.turnedBox(p[0], p[1], f, f + z1, .05, .05, TURN, YEL);
      }

      leg(-hw + .05, hd - .05, .44);
      leg(hw - .05, hd - .05, .44);
      leg(-hw + .05, -hd + .05, 1.0);
      leg(hw - .05, -hd + .05, 1.0);
      k.turnedBox(x, y, f + .38, f + .45, hw, hd, TURN, YEL);
      for (final z in const [.62, .86]) {
        final p = at(0, -hd + .05);
        k.turnedBox(p[0], p[1], f + z, f + z + .08, hw, .04, TURN, YEL);
      }
    });
  }

  /* ---------- the garden ---------- */

  // balcon-set.html: garden
  void garden() {
    k.part('arbusto', () {
      b.bush(BUSH1[0], BUSH1[1], .55, const [96, 150, 70]);
      b.bush(BUSH2[0], BUSH2[1], .5, C.leaf);
    });
  }

  /* ---------- bake one state ---------- */

  // balcon-set.html: buildSet
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
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * e.W + ix,
              c = yardGround(g.x, g.y, ix, iy, i);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / R2 * e.COS;
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
    porch();
    house();
    furniture();
    garden();
    // the furniture's shadows on the floor
    // (kept small and low: the table top's and the chairs' seats, not their whole height, so they do not lie across the
    // porch as dark pools)
    e.castShadow(TABLE[0], TABLE[1], FLOOR + .45, TABLE_R * .8);
    for (final (c, hw) in const [(SILLA, SILLA_HW), (SILLITA, SILLITA_HW)]) {
      e.castShadow(c[0], c[1], FLOOR + .3, hw * .85);
    }
    // the house and the roof shade the porch (the sun is behind the house, as in El frente: shadows fall to screen right)
    b.shadowBox(HX0, HY0, HX1, HY1 - .4, HF + .5, .6);
    // the roof's own shadow would fall on the porch floor and cut it in two: kept off it (as El frente keeps the house's
    // off the porch); the lawn takes it
    {
      final before = Uint8List.fromList(e.shadowMask);
      for (num x = RX0; x <= RX1; x += .4) {
        for (num y = HY1; y <= RY1; y += .4) {
          e.castShadow(x, y, roofZ(x, y), .5);
        }
      }
      for (var n = 0; n < k.slabTops.length; n += 2) {
        final i = k.slabTops[n] as int;
        e.shadowMask[i] = before[i];
      }
    }
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.skyFill((ix, iy) {
      final h = k.skyHills(HZ, SKY_FAR, SKY_NEAR, ix, iy);
      return h != 0 ? h : k.skyBands(SKY_BANDS, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
