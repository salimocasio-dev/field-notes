// Port of docs/proyecto/pixel/nevera-set.html: La nevera's set, every state, call for call (order 39a's set reference,
// order 39b's port), on the kitchen's kit (cocina_kit.dart). The page's names are kept, capitals included, so the port
// reads line for line against it (page 12, section 6): the lints on names are off in this file.
//
// Not ported: the page's `?g=` (design only: overrides of the plan's numbers, `bare` among them) and its `ox`, `oy` (the
// origin is the sheet's); `mark()` draws what its function draws and nothing else (the page records the pixels each named
// piece drew for the sheet maker's checks, with `?tags=1`: no pixel changes); `rows()` (the sheet maker's). `?tags=1` is
// the kit's `PART_TAGS` (the scene records them at a state's first bake), and `zones()` is [neveraZones].
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cocina_kit.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine La nevera's set is built on (nevera-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (-21, -1), shadows to (.9, -.1): the kitchen's light.
PpEngine neveraEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -21,
  originY: -1,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (nevera-set.html: `SET`, from the address).
class NeveraState {
  const NeveraState({
    this.nev = 0,
    int cajon = 0,
    this.pila = '0',
    this.banco = true,
  }) : cajon = nev == 1 ? cajon : 0;

  /// nevera-set.html: `pick(k, allowed, def)` for each parameter; `if (SET.nev !== 1) SET.cajon = 0`.
  factory NeveraState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return allowed.contains(v) ? v! : def;
    }

    return NeveraState(
      nev: int.parse(pick('nev', const ['0', '1', '2'], '0')),
      cajon: int.parse(pick('cajon', const ['0', '1', '2'], '0')),
      pila: pick('pila', const ['0', 'a', 'j'], '0'),
      banco: pick('banco', const ['0', '1'], '1') == '1',
    );
  }

  /// A key of the sheet's `setKey` table (`nev + "." + cajon + "." + pila + "." + banco`: `"1.2.0.1"`) read back.
  factory NeveraState.fromKey(String key) {
    final p = key.split('.');
    if (p.length != 4 ||
        !const ['0', '1', '2'].contains(p[0]) ||
        !const ['0', '1', '2'].contains(p[1]) ||
        !const ['0', 'a', 'j'].contains(p[2]) ||
        !const ['0', '1'].contains(p[3]) ||
        (p[0] != '1' && p[1] != '0')) {
      throw ArgumentError.value(key, 'key', 'not a key of La nevera\'s set');
    }
    return NeveraState(
      nev: int.parse(p[0]),
      cajon: int.parse(p[1]),
      pila: p[2],
      banco: p[3] == '1',
    );
  }

  /// W.nev.abierta: 0 shut, 1 open, 2 half open.
  final int nev;

  /// (open only) the drawer of the lower bin: 0 none, 1 shut (W.nev.cajon), 2 pulled out (W.nev.cajonver).
  final int cajon;

  /// W.pila: `'0'` the sink empty, `'a'` dishwater, `'j'` juice.
  final String pila;

  /// W.banco: the stool.
  final bool banco;

  /// The sheet's key (`setKey.key`).
  String get key => '$nev.$cajon.$pila.${banco ? 1 : 0}';
}

/* ---------- the plan (world units; the kit's frame) ---------- */

const double XR = 9,
    YL = 9; // the walls run past the picture's right and left edges
// the counter: from the corner (a 0) along the back wall; it ends inside the view, so that whoever comes in from the
// right walks in front of it
const double CA1 = 6.8;
// round 2: the window as tall as the old one where the family stands outside (z 1.6 to 4.7: the outside seen through it
// 62 rows and more, its lowest row, over the sill and the reveal, 22 rows over the feet of whoever stands outside, as the
// old sill); the kit's walls are cut at K.WH 3.2, so this set raises its own walls to WALL_H round its call of
// cocinaBuild (the other scenes keep theirs)
const CocinaWin WIN = CocinaWin(
  face: 'y',
  a0: 2.35,
  a1: 8.0,
  z0: 1.6,
  z1: 4.7,
  view: 'patio',
  bars: 'none',
  horizon: 3.3,
  name: 'ventana',
);
const double WALL_H = 4.95;

/// The fridge on the left wall (nevera-set.html: `FR`): along y from a0 to a1, depth d, height h (round 2: a1 3.6, so
/// that its far side ends inside the view); one door, from the plinth to the top (fz); the two glass shelves (their top
/// surfaces); the lower bin (the drawer's place): from z bin[0] to bin[1].
abstract final class FR {
  static const double a0 = .95, a1 = 3.6, d = 1.35, h = 3.4;
  static const double fz = h - .02;
  static const List<double> shelves = [2.0, .85];
  static const List<double> bin = [.16, .74];
}

/// The basin in the counter top (nevera-set.html: `SINK`), along a from a0 to a1, d from d0 to d1 (round 2: larger, its
/// middle still at the old EN.pila 124).
abstract final class SINK {
  static const double a0 = 1.25, a1 = 2.4, d0 = .12, d1 = .8;
}

/// The stool (nevera-set.html: `STOOL`): its top's middle on the screen (where the frog's feet are), its height and half
/// width.
abstract final class STOOL {
  static const double sx = 120, sy = 190, h = .72, r = .32;
}

const List<int> SHELF_EDGE = [30, 58, 82],
    WHITE = [240, 242, 248],
    WHITE_D = [214, 218, 230],
    INSIDE = [236, 240, 244],
    INSIDE_D = [206, 212, 220],
    GLASS = [150, 196, 214],
    GASKET = [150, 154, 170],
    HANDLE = [96, 100, 118];
// round 2: the inside white (a fridge, not a display case), the shelves white with a dark front edge
const List<int> DARK = [44, 52, 66], SHELF = [226, 230, 236];

// the door: a leaf turned about its hinge (FR.d, a1) by an angle (0 shut). Open (DOOR_OPEN, round 2: 150 degrees) it
// stands out into the room at the fridge's side; half open (DOOR_HALF, 1 degree) its outer face turned a little
const double DOOR_OPEN = 2.62, DOOR_HALF = .02, DRAWER_OUT = .8;

// nevera-set.html: at. The point at height z under a screen point
List<double> neveraAt(PpEngine e, num sx, num sy, [num z = 0]) {
  final u = (sx - e.OX) / e.S,
      v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
  return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
}

// nevera-set.html: stoolFoot. The floor under the stool top's middle
List<double> neveraStoolFoot(PpEngine e) =>
    neveraAt(e, STOOL.sx, STOOL.sy + STOOL.h * e.COS * e.S, 0);

/// What nevera-set.html's `zones()` gives for a baked state: each pixel's zone (s the backdrop, w the plaster, t the tile
/// band, o the outside seen through the window, v the window's frame, bars and sill, c the counter's top, k its cupboard,
/// p the sink and the tap, n the fridge's body, q its top, u its door, d its inside, e a shelf's or the bin's top, r the
/// drawer pulled out, b the stool, f the floor), and the pixels that show the outside.
typedef NeveraZones = ({String zone, Set<int> outside});

// nevera-set.html: zones. [tags]: the part that drew each pixel (PART_TAGS), [bakedZ] the baked depth, [state] SET
NeveraZones neveraZones(
  PpEngine e,
  List<String?> tags,
  Float32List bakedZ,
  NeveraState state,
) {
  final c = CocinaKit(SetKit(e, PpBuild(e)));
  final W = e.W, H = e.H, zone = StringBuffer(), outside = <int>{};
  double dOn(int ix, int iy, num z) {
    final g = neveraAt(e, ix + .5, iy + .5, z);
    return (g[0] + g[1]) / e.R2 * e.COS + z * e.SIN;
  }

  double back(int ix, int iy) => c.kWallPixel('y', -K.T - K.OUTD, ix, iy).d;
  for (var iy = 0; iy < H; iy++) {
    for (var ix = 0; ix < W; ix++) {
      final i = iy * W + ix, t = tags[i], d = bakedZ[i];
      var z = 'f';
      if (d < -1e8) {
        z = 's';
      } else if (t == 'pared') {
        final wp = ix + .5 < e.OX
            ? c.kWallPixel('x', 0, ix, iy)
            : c.kWallPixel('y', 0, ix, iy);
        z = wp.z >= K.BAND0 && wp.z <= K.BAND1 && ix + .5 >= e.OX && wp.a <= CA1
            ? 't'
            : 'w';
      } else if (t == 'ventana') {
        z = (d - back(ix, iy)).abs() < 1e-3 ? 'o' : 'v';
      } else if (t == 'mostrador') {
        z = (d - dOn(ix, iy, K.CZ)).abs() < .02 ? 'c' : 'k';
      } else if (t == 'pila') {
        z = 'p';
      } else if (t == 'nevera') {
        z = (d - dOn(ix, iy, FR.h)).abs() < .02 ? 'q' : 'n';
      } else if (t == 'nevera.puerta') {
        z = 'u';
      } else if (t == 'nevera.dentro') {
        z = 'd';
        for (final zz in [...FR.shelves, FR.bin[1]]) {
          if ((d - dOn(ix, iy, zz)).abs() < .02) z = 'e';
        }
        if (state.cajon == 2 &&
            (d - dOn(ix, iy, FR.bin[0] + .06)).abs() < .02) {
          z = 'r';
        }
      } else if (t == 'banco') {
        z = 'b';
      }
      zone.write(z);
      if (z == 'o') outside.add(i);
    }
  }
  return (zone: zone.toString(), outside: outside);
}

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// The set of La nevera in one state, built into an engine (nevera-set.html, from "the plan" to `buildSet`).
class NeveraSet {
  NeveraSet(this.e, this.b, this.SET) : k = SetKit(e, b) {
    c = CocinaKit(k);
    CNTZ = Float64List(e.W * e.H)..fillRange(0, e.W * e.H, double.nan);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CocinaKit c;

  // nevera-set.html: SET
  final NeveraState SET;

  int get W => e.W;
  int get H => e.H;

  // nevera-set.html: part (set-kit.js)
  void part(String name, void Function() fn) => k.part(name, fn);

  // nevera-set.html: mark. Records which pixels a named piece drew, for the sheet maker's checks: here it draws only
  void mark(String name, void Function() fn) => fn();

  /* ---------- the fridge ---------- */

  // nevera-set.html: fridge. In the left wall's frame: a along the wall (world y), d out from it (world x), z up. Its front
  // looks +x (d = FR.d), its end at a1 looks +y (lit, the left side on the screen), its top. The door hinges at (FR.d,
  // a1): shut it lies along the front, open it turns back towards +y
  void fridge() {
    const a0 = FR.a0, a1 = FR.a1, d = FR.d, h = FR.h;
    final open = SET.nev == 1, half = SET.nev == 2;
    int paintBody(String f, double p, double q, bool sh) {
      if (f == 'top') {
        return c.kRgb(p > a1 - .03 || q > d - .03 ? WHITE : WHITE_D);
      }
      if (f == 'end') {
        return c.kRgb(
          c.kLit(
            q < .08
                ? const [70, 70, 84]
                : p > d - .04
                ? WHITE_D
                : WHITE,
            false,
          ),
        );
      }
      return 0;
    }

    // the cabinet: its top and its lit end (the left side on the screen); the front is drawn by the doors or the inside
    part('nevera', () {
      c.kBox('x', a0, a1, 0, d, .08, h, paintBody, 'te');
      // the feet: a dark plinth under it
      c.kSolid('x', a0 + .05, a1 - .05, .1, d - .06, 0, .08, const [
        56,
        56,
        66,
      ], 'fe');
      if (!open && !half) doorShut();
    });
    if (open || half) part('nevera.dentro', inside);
    if (open) {
      part('nevera.puerta', doorOpen);
    } else if (half) {
      part('nevera.puerta', doorHalf);
    }
  }

  // nevera-set.html: doorShut. The main door, shut: a white leaf over the front from the plinth to the freezer, its
  // handle a long bar near the free edge
  void doorShut() {
    const a0 = FR.a0, a1 = FR.a1, d = FR.d, fz = FR.fz;
    c.kBox('x', a0, a1, d, d + .06, .08, fz - .02, (f, p, q, sh) {
      if (f == 'top') return c.kRgb(WHITE_D);
      if (f == 'end') return c.kRgb(WHITE_D);
      if (q < .12 || q > fz - .06 || p < a0 + .03 || p > a1 - .03) {
        return c.kRgb(c.kLit(GASKET, sh));
      }
      return c.kRgb(c.kLit(WHITE, sh));
    }, 'tfe');
    // the handle: an upright bar standing off the door
    c.kSolid(
      'x',
      a0 + .3,
      a0 + .38,
      d + .06,
      d + .14,
      fz - 1.45,
      fz - .4,
      HANDLE,
    );
  }

  // nevera-set.html: inside. The back and the walls white, the two shelves (white, a dark front edge), the lower bin;
  // the drawer (shut or pulled out). Half open: the same hollow, unlit (a dark gap seen down past the leaf's top)
  void inside() {
    const a0 = FR.a0, a1 = FR.a1, d = FR.d, fz = FR.fz, w = .09, z0 = .14;
    const z1 = fz - .1;
    final half = SET.nev == 2;
    final In = e.rampOf(half ? DARK : INSIDE);
    final Sh = half ? DARK : SHELF;
    // the hollow, seen through the front: its far wall (the back, x = w) and its floor, its near side wall (a0 + w,
    // looking +y), its roof
    k.planeQuad([w, a0 + w, z0], [0, a1 - a0 - 2 * w, 0], [
      0,
      0,
      z1 - z0,
    ], (_, _) => In[3]);
    k.planeQuad([w, a0 + w, z0], [d - w, 0, 0], [
      0,
      0,
      z1 - z0,
    ], (_, _) => In[2]);
    k.planeQuad([w, a0 + w, z0], [d - w, 0, 0], [
      0,
      a1 - a0 - 2 * w,
      0,
    ], (_, _) => In[3]);
    k.planeQuad([w, a0 + w, z1], [d - w, 0, 0], [
      0,
      a1 - a0 - 2 * w,
      0,
    ], (_, _) => In[1]);
    // the front rim of the cabinet round the opening: its walls' thickness, white, a grey gasket line on its inner edge
    void rim(num b0, num b1, num c0, num c1) => c.kBox(
      'x',
      b0,
      b1,
      d - .06,
      d,
      c0,
      c1,
      (f, p, q, sh) => c.kRgb(f == 'top' ? WHITE_D : c.kLit(WHITE, sh)),
      'tfe',
    );
    mark('rim', () {
      rim(a0, a0 + w, z0, z1);
      rim(a1 - w, a1, z0, z1);
      rim(a0, a1, z1, fz);
      rim(a0, a1, .08, z0);
    });
    // the two shelves: a white plate with a dark front edge (a dark edge all round its top)
    for (final z in FR.shelves) {
      c.kBox(
        'x',
        a0 + w,
        a1 - w,
        w,
        d - .06,
        z - .05,
        z,
        (f, p, q, sh) => f == 'top'
            ? c.kRgb(
                q > d - .08 ||
                        q < w + .06 ||
                        p < a0 + w + .07 ||
                        p > a1 - w - .07
                    ? SHELF_EDGE
                    : Sh,
              )
            : c.kRgb(c.kLit(Sh, sh)),
        'tf',
      );
    }
    // the lower bin: the drawer's place
    final b0 = FR.bin[0], b1 = FR.bin[1];
    if (SET.cajon == 2) {
      // pulled out: a drawer box standing out of the front on the bin's floor, joined to the fridge's foot: its floor,
      // its two sides, its back and its front panel with a dark handle; low, so that the fruit in it shows over its
      // front (the fruit is the sprite layer's)
      const out = DRAWER_OUT,
          x0 = d - .3,
          x1 = d + out,
          s0 = a0 + .2,
          s1 = a1 - .2,
          th = .05;
      final fl = b0 + .06, top = b0 + .3;
      // its floor (zone r)
      k.planeQuad([x0, s0, fl], [x1 - x0, 0, 0], [
        0,
        s1 - s0,
        0,
      ], (_, _) => c.kRgb(const [168, 180, 192]));
      // the far side
      c.kBox(
        'x',
        s0,
        s0 + th,
        x0,
        x1,
        b0,
        top,
        (f, p, q, sh) => c.kRgb(f == 'top' ? WHITE : c.kLit(INSIDE_D, sh)),
        'tfe',
      );
      // the near side (its outer face lit)
      c.kBox(
        'x',
        s1 - th,
        s1,
        x0,
        x1,
        b0,
        top,
        (f, p, q, sh) => c.kRgb(f == 'top' ? WHITE : c.kLit(WHITE_D, sh)),
        'tfe',
      );
      // the front panel
      c.kBox('x', s0, s1, x1 - th, x1, b0, top, (f, p, q, sh) {
        if (f == 'top') return c.kRgb(WHITE);
        if ((q - (top - .1)).abs() < .035 && (p - (s0 + s1) / 2).abs() < .35) {
          return c.kRgb(HANDLE);
        }
        if (q < b0 + .03 || q > top - .03) return c.kRgb(GASKET);
        return c.kRgb(c.kLit(WHITE, sh));
      }, 'tfe');
      // the bin's empty mouth behind it, dark
      k.planeQuad([d - .07, a0 + w, b0], [0, a1 - a0 - 2 * w, 0], [
        0,
        0,
        b1 - b0,
      ], (_, _) => c.kRgb(DARK));
    } else if (SET.cajon == 1) {
      // shut: the drawer's white front across the bin, a dark gap round it and a long dark handle
      c.kBox('x', a0 + w, a1 - w, w, d - .04, b0, b1, (f, p, q, sh) {
        if (f == 'top') return c.kRgb(SHELF);
        if (q > b1 - .05 ||
            q < b0 + .05 ||
            p < a0 + w + .05 ||
            p > a1 - w - .05) {
          return c.kRgb(DARK);
        }
        if ((q - (b1 - .18)).abs() < .04 && (p - (a0 + a1) / 2).abs() < .55) {
          return c.kRgb(HANDLE);
        }
        return c.kRgb(c.kLit(WHITE, sh));
      }, 'tf');
    } else {
      // no drawer: the bin's floor and its low glass lip, the inside behind
      c.kBox(
        'x',
        a0 + w,
        a1 - w,
        w,
        d - .06,
        b0,
        b0 + .06,
        (f, p, q, sh) =>
            f == 'top' ? c.kRgb(Sh) : c.kRgb(c.kLit(SHELF_EDGE, sh)),
        'tf',
      );
    }
  }

  // nevera-set.html: leafAt. The door's leaf turned about its hinge (FR.d, a1) by [ang]; its inner face (white, the
  // racks), its outer face, the free edge's thickness and the handle on the outer side at the free edge
  ({double dx, double dy, double len}) leafAt(double ang) {
    const a0 = FR.a0, a1 = FR.a1, d = FR.d, fz = FR.fz, len = a1 - a0;
    const hx = d, hy = a1, th = .1;
    final dx = math.sin(ang), dy = -math.cos(ang);
    // the leaf's outer face's normal (shut: +x)
    final nx = math.cos(ang), ny = math.sin(ang);
    final P0 = [hx, hy, .08], E1 = [dx * len, dy * len, 0.0];
    const E2 = [0.0, 0.0, fz - .1];
    int outer(double s, double t) {
      final q = .08 + (fz - .1) * t;
      return c.kRgb(
        c.kLit(
          q < .12 || q > fz - .06 || s > .98 ? GASKET : WHITE,
          nx + ny < 0 || (ang > 0 && ang < .5),
        ),
      );
    }

    int inner(double s, double t) {
      final rack =
          [.3, .55, .8].any((r) => (t - r).abs() < .03) && s > .12 && s < .88;
      return c.kRgb(
        s > .95 || s < .05 || t < .03 || t > .97
            ? GASKET
            : rack
            ? SHELF_EDGE
            : INSIDE_D,
      );
    }

    mark(
      'door.outer',
      () =>
          k.planeQuad([P0[0] + nx * th, P0[1] + ny * th, P0[2]], E1, E2, outer),
    );
    mark('door.inner', () => k.planeQuad(P0, E1, E2, inner));
    // the free edge's thickness, and the handle: an upright bar on the outer side at the free edge, standing .1 off it
    final F0 = [P0[0] + E1[0], P0[1] + E1[1], P0[2]];
    k.planeQuad(F0, [nx * th, ny * th, 0], E2, (_, _) => c.kRgb(GASKET));
    final H0 = [F0[0] + nx * th, F0[1] + ny * th, fz - 1.5];
    mark('door.handle', () {
      k.planeQuad(
        H0,
        [nx * .12, ny * .12, 0],
        const [0, 0, 1.1],
        (_, _) => c.kRgb(HANDLE),
      );
      k.planeQuad(
        [H0[0] - dx * .06, H0[1] - dy * .06, H0[2]],
        [nx * .12, ny * .12, 0],
        const [0, 0, 1.1],
        (_, _) => c.kRgb(HANDLE),
      );
    });
    return (dx: dx, dy: dy, len: len);
  }

  // nevera-set.html: doorOpen, doorHalf
  void doorOpen() => leafAt(DOOR_OPEN);
  void doorHalf() => leafAt(DOOR_HALF);

  /* ---------- the sink and its tap ---------- */

  // nevera-set.html: sink
  void sink() {
    const a0 = SINK.a0, a1 = SINK.a1, d0 = SINK.d0, d1 = SINK.d1;
    final z = K.CZ + .004, St = e.rampOf(const [206, 210, 222]);
    part('pila', () {
      // the basin, seen from above: a steel rim, its far inner wall in shade, its bottom; the dishwater (grey-blue, suds)
      // or the juice (orange) filling it (round 2: larger, and what is in it dark enough to tell from the empty steel at
      // a glance)
      mark(
        'basin',
        () => k.planeQuad([a0, d0, z], [a1 - a0, 0, 0], [0, d1 - d0, 0], (
          s,
          t,
        ) {
          final ea = s * (a1 - a0), ed = t * (d1 - d0);
          if (ea < .07 ||
              ea > a1 - a0 - .07 ||
              ed < .07 ||
              ed > d1 - d0 - .07) {
            return St[4];
          }
          // the rim's inner lip, dark
          if (ea < .1 || ed > d1 - d0 - .1) {
            return c.kRgb(const [120, 124, 140]);
          }
          if (SET.pila == 'a') {
            return c.kRgb(
              (((ea * 14).floor() * 7 + (ed * 14).floor() * 3) % 11 == 0)
                  ? const [214, 228, 236]
                  : ed < .2
                  ? const [72, 98, 120]
                  : const [96, 128, 150],
            );
          }
          if (SET.pila == 'j') {
            return c.kRgb(ed < .2 ? const [150, 66, 4] : const [196, 94, 10]);
          }
          // the far inner wall, in shade
          if (ed < .2) return St[1];
          return St[3];
        }),
      );
      // the tap: a pipe up from the counter top at the wall, its spout over the basin's middle
      const ta = (a0 + a1) / 2, Tp = [150, 154, 172];
      c.kSolid('y', ta - .05, ta + .05, .02, .12, K.CZ, K.CZ + .55, Tp);
      c.kSolid('y', ta - .05, ta + .05, .02, .42, K.CZ + .49, K.CZ + .57, Tp);
      c.kSolid('y', ta - .05, ta + .05, .34, .42, K.CZ + .38, K.CZ + .49, Tp);
    });
  }

  /* ---------- the stool: a square wooden seat on four legs ---------- */

  // nevera-set.html: stool. Drawn after the room is baked (so the floor's occlusion makes no ring round its thin legs):
  // its own silhouette is darkened against the floor as shadeEdges does, and each leg casts only a short contact shadow
  // at its foot, on its shadow side (the kit's cocinaShadowFoot)
  void stool() {
    if (!SET.banco) return;
    final foot = neveraStoolFoot(e), cx = foot[0], cy = foot[1];
    const r = STOOL.r, hh = STOOL.h;
    final zb = e.zb, before = Float32List.fromList(zb);
    part('banco', () {
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
      c.kSolid('y', cx - r, cx + r, cy - r, cy + r, hh - .06, hh, KC.woodL);
    });
    // its silhouette against the floor (shadeEdges' rule, for its own pixels only)
    final mine = <int>[];
    for (var i = 0; i < W * H; i++) {
      if (zb[i] != before[i]) mine.add(i);
    }
    final gz = e.groundZ;
    bool onGround(int j) => j < 0 || j >= W * H
        ? true
        : zb[j] == gz[j]; // (JavaScript: undefined === undefined)
    for (final i in mine) {
      if (onGround(i - W) ||
          onGround(i + W) ||
          onGround(i - 1) ||
          onGround(i + 1)) {
        e.tint(i, .68, .66, .76);
      }
    }
    part('banco', () {
      for (final (ex, ey) in const [(1, -1), (1, 1), (-1, 1)]) {
        c.cocinaShadowFoot(cx + ex * (r - .07), cy + ey * (r - .07));
      }
    });
    e.applyShadows(e.groundZ);
  }

  /* ---------- the floor's dimming (round 2) ---------- */

  // nevera-set.html: CNTZ. The depth the counter drew at each pixel (NaN where it drew none)
  late final Float64List CNTZ;

  // nevera-set.html: occlusion. The kit's cocinaOcclusion dims a floor pixel by whatever stands to its left on the
  // screen; the counter's front falls to the right along the back wall, so the floor all along its lit foot was dimmed
  // in a dotted fringe. Here the same dimming, by everything but the counter (its own shade is on its shadow side, its
  // right end, where the kit's light does not reach)
  void occlusion() {
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
          if (zb[j] != gz[j] && zb[j] != CNTZ[j]) hits++;
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

  /* ---------- bake one state ---------- */

  // nevera-set.html: furnish (the plan's: the counter, its depth at each pixel, the sink, the fridge)
  void furnish() {
    final bz = Float32List.fromList(e.zb);
    part('mostrador', () => c.cocinaBase('y', 0, CA1, noEnd: false));
    final zb = e.zb;
    for (var i = 0; i < zb.length; i++) {
      CNTZ[i] = zb[i] != bz[i] ? zb[i] : double.nan;
    }
    sink();
    fridge();
  }

  // nevera-set.html: shadows (the plan's)
  void shadows() {
    part(
      'nevera',
      () => c.cocinaShadowBlock(
        FR.d - .05,
        FR.a0 + .1,
        FR.d + .05,
        FR.a1 - .1,
        .25,
      ),
    );
  }

  // nevera-set.html: buildSet
  void buildSet() {
    c.cocinaCheckScene();
    // round 2: this set's walls are higher than the kit's (the tall window); restored at once after
    final WH0 = K.WH;
    K.WH = WALL_H;
    try {
      c.cocinaBuild(
        CocinaPlan(
          XR: XR,
          YL: YL,
          windows: const [WIN],
          band: const {
            'y': [
              [0, CA1],
            ],
          },
          // round 2: the floor's dimming is this set's own (occlusion(), below)
          occlusion: 'none',
          furnish: furnish,
          shadows: shadows,
        ),
      );
    } finally {
      K.WH = WH0;
    }
    occlusion();
    stool();
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
