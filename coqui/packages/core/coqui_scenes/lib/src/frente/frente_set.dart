// Port of docs/proyecto/pixel/frente-set.html: El frente's set, every state, call for call (order 07's set reference,
// order 14's port). The page's names are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine El frente's set is built on (frente-set.html: `window.PP_SCENE`, with the page's default origin, which is
/// the sheet's): 240 × 216, S 26, origin (-2, 12), shadows to (.9, -.1).
PpEngine frenteEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -2,
  originY: 12,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (frente-set.html: `SET`, from the address). The values are the page's own strings.
class FrenteState {
  const FrenteState({
    this.door = 'shut',
    this.win = 'shut',
    this.lights = false,
    this.sky = 'day',
    this.hide = false,
    this.rustle = 'none',
    this.side = 1,
  });

  /// frente-set.html: `pick(...)` of each parameter from a query (`?door=half&win=shut&...`); a value the page does not
  /// allow takes its default, as there.
  factory FrenteState.fromQuery(String query) {
    final q = Uri.splitQueryString(query.startsWith('?') ? query.substring(1) : query);
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return FrenteState(
      door: pick('door', const ['shut', 'half', 'open'], 'shut'),
      win: pick('win', const ['shut', 'open'], 'shut'),
      lights: pick('lights', const ['0', '1'], '0') == '1',
      sky: pick('sky', const ['day', 'storm', 'storm2', 'rain', 'dusk', 'sunset'], 'day'),
      hide: pick('hide', const ['0', '1'], '0') == '1',
      rustle: pick('rustle', const ['none', 'palma', 'casa', 'todo'], 'none'),
      side: pick('side', const ['-1', '1'], '1') == '1' ? 1 : -1,
    );
  }

  /// A key of the sheet's `setKey` table (`"shut-shut-0-day-0-none"`, with `-1` or `--1` after a rustle) read back.
  factory FrenteState.fromKey(String key) {
    final m = RegExp(r'^(\w+)-(\w+)-([01])-(\w+)-([01])-(\w+)(?:-(-?1))?$').firstMatch(key);
    if (m == null) throw ArgumentError.value(key, 'key', 'not a key of El frente\'s set');
    return FrenteState(
      door: m[1]!,
      win: m[2]!,
      lights: m[3] == '1',
      sky: m[4]!,
      hide: m[5] == '1',
      rustle: m[6]!,
      side: m[7] == '-1' ? -1 : 1,
    );
  }

  final String door, win, sky, rustle;
  final bool lights, hide;
  final int side;

  /// The sheet's key: door + win + lights + sky + hide + rustle (+ side, only when something rustles).
  String get key =>
      '$door-$win-${lights ? 1 : 0}-$sky-${hide ? 1 : 0}-$rustle${rustle == 'none' ? '' : '-$side'}';
}

/* ---------- the hour: the sky and the light on the set ---------- */

/// frente-set.html: `LIGHT`, by sky.
const Map<String, Light?> LIGHTS = {
  'day': null,
  'storm': Light([.76, .78, .84], [3, 5, 12]),
  'storm2': Light([.7, .73, .8], [4, 6, 14]),
  'rain': Light([.63, .67, .76], [5, 7, 16]),
  // a warm light: the grass blades keep their lit colours, so the lawn stays as calm as by day
  'dusk': Light([.9, .8, .72], [34, 16, 4], litTufts: true),
  'sunset': Light([.62, .54, .66], [24, 10, 30]),
};

/// frente-set.html: one entry of `SKY`.
class SkyTones {
  const SkyTones(this.bands, this.far, this.near, this.sun);

  final List<List<num>> bands, far, near;
  final List<List<num>>? sun;
}

/// frente-set.html: `SKY`, by sky.
const Map<String, SkyTones> SKIES = {
  'day': SkyTones(
    [[58, 134, 230], [85, 159, 242], [120, 186, 250], [162, 211, 255], [208, 234, 255]],
    [[116, 180, 162], [156, 208, 188], [94, 158, 144]],
    [[78, 158, 94], [124, 203, 122], [62, 136, 80]],
    [[220, 150, 30], [248, 200, 56], [255, 224, 112], [255, 244, 176]],
  ),
  'storm': SkyTones(
    [[72, 82, 100], [88, 98, 116], [104, 114, 132], [124, 134, 150], [146, 154, 168]],
    [[86, 116, 112], [104, 134, 128], [74, 102, 100]],
    [[60, 104, 72], [80, 124, 88], [50, 90, 62]],
    [[150, 156, 170], [170, 176, 188], [186, 192, 202]],
  ),
  'storm2': SkyTones(
    [[60, 68, 86], [74, 84, 102], [90, 100, 118], [108, 118, 134], [128, 136, 152]],
    [[76, 104, 102], [92, 120, 116], [66, 92, 90]],
    [[52, 94, 66], [70, 112, 80], [44, 80, 56]],
    [[132, 138, 152], [150, 156, 170], [164, 170, 182]],
  ),
  'rain': SkyTones(
    [[50, 56, 74], [62, 70, 88], [76, 84, 102], [92, 100, 118], [110, 118, 134]],
    [[66, 92, 92], [82, 106, 104], [58, 82, 82]],
    [[46, 84, 60], [62, 100, 72], [40, 72, 50]],
    null,
  ),
  'dusk': SkyTones(
    [[86, 128, 214], [120, 156, 226], [176, 180, 214], [236, 196, 170], [252, 214, 160]],
    [[150, 160, 150], [186, 186, 164], [128, 140, 134]],
    [[104, 140, 84], [150, 176, 104], [86, 120, 72]],
    [[226, 120, 40], [246, 160, 60], [255, 200, 100], [255, 232, 160]],
  ),
  'sunset': SkyTones(
    [[60, 44, 104], [96, 58, 120], [160, 76, 120], [226, 112, 96], [250, 164, 96]],
    [[104, 72, 110], [134, 92, 124], [88, 60, 96]],
    [[70, 70, 90], [96, 92, 104], [58, 58, 78]],
    [[214, 72, 40], [240, 110, 50], [252, 160, 80], [255, 210, 130]],
  ),
};

/* ---------- the plan of the place (world units) ---------- */

const double HX0 = -2.3, HX1 = 2.6, HY0 = -1.4, HY1 = 0, HH = 2.9; // the house walls; the front faces +y
const double EAVE = .22, RISE = .8; // the roof: overhang, ridge above the eaves
const double FLOOR = .16; // the porch and the floor inside
const double DOOR0 = .75, DOOR1 = 2.2, DH = 2.55; // the doorway, from the porch up
const double WIN0 = -1.71, WIN1 = -.01, WZ0 = 1.15, WZ1 = 2.4; // the window opening
const double PORCH = 1.0, STEP = 1.4; // the porch slab's depth, the step's front
const List<double> PALM = [-1.33, 3.51], SPALM = [6.15, 3.32], BIRD = [3.05, 5.66]; // the big palm, the small palm, the birdhouse
final double R2 = math.sqrt2;
// where the path leaves the step
final double PATH_U = ((DOOR0 + DOOR1) / 2 - STEP) / R2, PATH_V = ((DOOR0 + DOOR1) / 2 + STEP) / R2;
const List<double> BUSH1 = [3.37, -2.28], BUSH2 = [1.47, 6.8]; // the two bushes
const double PALM_H = 3.6, PALM_LEAN = .3, PALM_SIZE = .62, SPALM_H = 2.1, SPALM_LEAN = .25, SPALM_SIZE = .58;
// the half-open door: turned .34 rad into the room, still across about half the doorway (as the old picture)
const double HALF_ANGLE = math.pi + .34;
const double HZ = 46; // the horizon, in screen rows: sky above
const List<int> TEAL = [92, 190, 186], WOOD = [150, 98, 56], WHITE = [244, 240, 228];
// the sun (screen space): 5 px right of the old one, so its touch circle stays clear of the house's box
const List<num> SUN = [215, 17, 10];

const List<int> _litReveal = [214, 170, 110];

/// The ground and its grass, the same in every state: made once, then copied (frente-set.html: `GROUND_CACHE`). One per
/// engine.
class _GroundCache {
  _GroundCache(this.pix, this.zb, this.kinds, this.ground, this.tufts);

  final Uint32List pix;
  final Float32List zb;
  final Uint8List kinds, ground;
  final List<Tuft> tufts;
}

final Expando<_GroundCache> _groundCaches = Expando<_GroundCache>();

/// The set of El frente in one state, built into an engine (frente-set.html, from "the ground" to "bake one state").
class FrenteSet {
  FrenteSet(this.e, this.b, this.SET) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  // frente-set.html: SET
  final FrenteState SET;

  PpPalette get C => b.C;
  double get ST => b.ST;
  Light? get LIGHT => LIGHTS[SET.sky];
  SkyTones get SKY => SKIES[SET.sky]!;

  /* ---------- the ground ---------- */

  // frente-set.html: frontGround
  int frontGround(double x, double y, int ix, int iy, int i) {
    if (iy + .5 < HZ) return 0; // above the horizon: sky
    // the stone path: from the step it runs straight down the picture (along +x +y), like the map's roads
    final u = (x - y) / R2 - PATH_U,
        v = (x + y) / R2 - PATH_V,
        half = .5 + math.max(0, v) * .04;
    if (v > -.05 && u.abs() < half) {
      e.kinds[i] = KIND_ROAD;
      final r = (v / .5).floor(),
          off = r.remainder(2) != 0 ? .25 : 0,
          c = ((u + 3 + off) / .5).floor();
      final gap =
          v.remainder(.5) < .06 ||
          (u + 3 + off).remainder(.5) < .05 ||
          half - u.abs() < .05;
      return gap
          ? e.rgb(C.stone[0] * .62, C.stone[1] * .62, C.stone[2] * .62)
          : b.toneOf(C.pave, .35 + e.hash(r, c) * .5 + (e.hash(ix, iy) - .5) * .2, ix, iy);
    }
    e.kinds[i] = e.KIND_GRASS;
    final t = e.noise(x * .45, y * .45) * 1.1 + (e.hash(ix, iy) - .5) * .5;
    final g = e.GRASS[e.clamp((t * 4.2).floor() + 1, 0, 4)];
    return e.rgb(g[0], g[1], g[2]);
  }

  /* ---------- the house ---------- */

  // frente-set.html: house
  void house() {
    const holeD = [DOOR0, DOOR1, FLOOR, FLOOR + DH], holeW = [WIN0, WIN1, WZ0, WZ1];
    k.part('casa', () {
      k.blockHoles(HX0, HY0, 0, HX1, HY1, HH, TEAL, [holeD, holeW], .21, true); // wooden siding, like the old picture's
      // a darker band at the foot of the walls, and the shade under the eaves
      b.onWall('y', HY1, HX0, HX1, 0, .3, e.rampOf(TEAL)[1]);
      b.onWall('x', HX1, HY0, HY1, 0, .3, e.rampOf(TEAL)[0]);
      b.onWall('y', HY1, HX0, HX1, HH - .16, HH, e.rampOf(TEAL)[1]);
      b.onWall('x', HX1, HY0, HY1, HH - .16, HH, e.rampOf(TEAL)[0]);
      // white corner boards
      for (num z = 0; z <= HH; z += ST * .5) {
        for (num a = 0; a <= .14; a += ST * .5) {
          e.plot(HX1 - a, HY1 + .02, z, e.rampOf(WHITE)[2]);
          e.plot(HX1 + .02, HY1 - a, z, e.rampOf(WHITE)[1]);
          e.plot(HX0 + a, HY1 + .02, z, e.rampOf(WHITE)[2]);
        }
      }
      k.hipRoof(HX0 - EAVE, HY0 - EAVE, HX1 + EAVE, HY1 + EAVE, HH, RISE, C.red, WHITE);
    });
    k.part('puerta', doorway);
    k.part('ventana', windowAndShutters);
    // the porch slab along the front, and the step before the door
    k.part('porche', () {
      k.slab(HX0 - .1, HY1, HX1 + .1, HY1 + PORCH, FLOOR, C.stone);
      k.slab(DOOR0 - .15, HY1 + PORCH, DOOR1 + .15, STEP, .08, C.stone);
    });
    b.shadowBox(HX0, HY0, HX1, HY1 - .6, HH + .9, .6); // kept off the front: the porch is in the sun
  }

  // the room behind an opening [a0, a1] of the front wall: a plank floor and the back wall with a skirting board (no
  // picture: its frame read as lines over abuela's head when she stands in the doorway).
  // Only the part that shows through the opening is drawn (a point of the back wall shows through the front at
  // x + depth, and lower). Dim when the lights are off (a room, not a hole); warm, and giving light, when they are on
  static const double BACK = HY0 + .08;

  // frente-set.html: room
  void room(num a0, num a1, bool floor) {
    final on = SET.lights, d = HY1 - BACK;
    final F = on
        ? const [[236, 196, 134], [242, 204, 142], [222, 180, 118]]
        : const [[70, 50, 36], [82, 60, 42], [58, 40, 28]];
    int wallC(num a, num z) {
      if (z < FLOOR + .16) return on ? e.rgb(170, 110, 64) : e.rgb(44, 32, 26); // skirting board
      final kk = (z - FLOOR) / 2;
      return on
          ? e.rgb(255, 230 - kk * 20, 168 - kk * 30)
          : e.rgb(66 - kk * 14, 72 - kk * 14, 74 - kk * 12);
    }

    // inside the house only
    for (num a = math.max(HX0 + .02, a0 - d - .15); a <= math.min(HX1 - .02, a1 - d + .1); a += ST) {
      for (num z = FLOOR; z <= HH - .3; z += ST) {
        final c = wallC(a, z);
        if (on) {
          k.plotGlow(a, BACK, z, c);
        } else {
          e.plot(a, BACK, z, c);
        }
      }
    }
    if (floor) {
      for (num a = math.max(HX0 + .02, a0 - d - .15); a <= math.min(HX1 - .02, a1 + .05); a += ST) {
        for (num bb = BACK; bb <= HY1 - .01; bb += ST) {
          final seam = (a + 5).remainder(.22) < .03; // plain boards: no light pool, no blotches
          final fc = F[seam ? 2 : 0];
          final c = e.rgb(fc[0], fc[1], fc[2]);
          if (on) {
            k.plotGlow(a, bb, FLOOR, c);
          } else {
            e.plot(a, bb, FLOOR, c);
          }
        }
      }
    }
  }

  // frente-set.html: doorway
  // the doorway: the frame, what is seen inside, the leaf (shut, half open, open)
  void doorway() {
    const z0 = FLOOR, z1 = FLOOR + DH, w = DOOR1 - DOOR0;
    final on = SET.lights;
    k.reveal(HY1, DOOR0, DOOR1, z0, z1, .22, on ? _litReveal : TEAL);
    room(DOOR0, DOOR1, true);
    // the frame
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
    // the leaf: hinged on the right, it swings in
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
      k.paneY(HY1 - .06, DOOR0, DOOR1, z0, z1, (a, z) => panel((DOOR1 - a) / w, z));
      // the knob, on the left (free) side
      for (num a = 0; a <= .1; a += ST * .4) {
        for (num z = 0; z <= .1; z += ST * .4) {
          e.plot(DOOR0 + .14 + a, HY1 - .03, z0 + 1.15 + z, e.rgb(250, 210, 80));
        }
      }
      // the lights on inside: a thin line of light round the shut door
      if (on) {
        final glow = e.rgb(255, 222, 120), hot = e.rgb(255, 244, 180);
        for (num z = z0; z <= z1; z += ST * .4) {
          for (num d = 0; d <= .07; d += ST * .3) {
            k.plotGlow(DOOR0 + d, HY1 + .015, z, glow);
            k.plotGlow(DOOR1 - d, HY1 + .015, z, glow);
          }
        }
        for (num a = DOOR0; a <= DOOR1; a += ST * .4) {
          for (num d = 0; d <= .07; d += ST * .3) {
            k.plotGlow(a, HY1 + .015, z1 - d, glow);
          }
          for (num d = 0; d <= .1; d += ST * .3) {
            k.plotGlow(a, HY1 + .015, z0 + d, hot);
          }
        }
      }
    } else {
      // hinged on the right, it swings in: half open it still hides most of the doorway, a dark gap on its left; open,
      // it is out of sight (the sheet's door gap, clip puerta.hueco, is worked out from HALF_ANGLE)
      final ang = SET.door == 'half' ? HALF_ANGLE : math.pi + 1.45;
      // the leaf as the shut door looks: its panels and its knob, a dark line at its free edge against the gap
      k.leaf(
        DOOR1,
        HY1 - .06,
        w,
        z0,
        z1,
        ang,
        (t, z) => t > .96
            ? Wd[0]
            : t > .82 && t < .9 && (z - z0 - 1.17).abs() < .06
            ? e.rgb(250, 210, 80)
            : panel(t, z),
      );
    }
  }

  // frente-set.html: windowAndShutters
  // the window: the opening, the room behind, louvred shutters (shut: in the opening; open: flat on the wall each
  // side), the flower box
  void windowAndShutters() {
    final on = SET.lights, F = e.rampOf(WHITE);
    const ww = WIN1 - WIN0;
    k.reveal(HY1, WIN0, WIN1, WZ0, WZ1, .22, on ? _litReveal : TEAL);
    room(WIN0, WIN1, false);
    // the frame
    for (num a = WIN0 - .12; a <= WIN1 + .12; a += ST * .5) {
      for (final z in const [WZ0 - .12, WZ1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a, HY1 + .03, z + h, F[3]);
        }
      }
    }
    for (num z = WZ0 - .12; z <= WZ1 + .12; z += ST * .5) {
      for (final a in const [WIN0 - .12, WIN1]) {
        for (num h = 0; h <= .12; h += ST * .5) {
          e.plot(a + h, HY1 + .03, z, F[3]);
        }
      }
    }
    // a louvred shutter: white boards, slats every .1
    final glowCol = e.rgb(255, 214, 110);
    int slats(num u, num z, num w, bool glow) {
      final s = ((z - WZ0) / .1).floor().remainder(2),
          edge = u < .06 || u > w - .06 || z < WZ0 + .06 || z > WZ1 - .06;
      if (glow && !edge && s != 0) return glowCol;
      return F[edge
          ? 2
          : s != 0
          ? 3
          : 2];
    }

    const half = ww / 2;
    if (SET.win == 'shut') {
      // two leaves meeting in the middle; with the lights on, the light comes through between the slats
      for (num a = WIN0; a <= WIN1; a += ST * .4) {
        for (num z = WZ0; z <= WZ1; z += ST * .4) {
          final u = a < WIN0 + half ? a - WIN0 : a - WIN0 - half,
              col = slats(u, z, half, on);
          if (on && col == glowCol) {
            k.plotGlow(a, HY1 - .06, z, col);
          } else {
            e.plot(a, HY1 - .06, z, col);
          }
        }
      }
      // the two knobs in the middle
      for (final a in const [WIN0 + half - .1, WIN0 + half + .04]) {
        for (num p = 0; p <= .06; p += ST * .3) {
          for (num q = 0; q <= .06; q += ST * .3) {
            e.plot(a + p, HY1 - .02, (WZ0 + WZ1) / 2 + q, e.rgb(60, 44, 34));
          }
        }
      }
    } else {
      // open: each leaf (a little narrower than half the window) flat on the wall beside it
      const lw = .4; // each leaf folds in two (a fold line down its middle), so it is narrower than half the window
      for (num a = 0; a <= lw; a += ST * .4) {
        for (num z = WZ0; z <= WZ1; z += ST * .4) {
          final fold = (a - lw / 2).abs() < .03,
              col = fold ? e.rampOf(WHITE)[1] : slats(a, z, lw, false);
          e.plot(WIN0 - .14 - lw + a, HY1 + .05, z, col);
          e.plot(WIN1 + .14 + a, HY1 + .05, z, col);
        }
      }
    }
    // the flower box under the window
    b.block(WIN0 - .15, HY1, WZ0 - .45, WIN1 + .15, HY1 + .32, WZ0 - .17, C.wood);
    const flowers = [
      [255, 143, 184],
      [255, 224, 112],
      [244, 88, 74],
    ];
    for (var kk = 0; kk < 9; kk++) {
      e.sphere(
        WIN0 - .05 + kk * (ww + .1) / 8,
        HY1 + .18,
        WZ0 - .14,
        .1,
        flowers[kk % 3],
        'solid',
      );
    }
  }

  /* ---------- the garden ---------- */

  // frente-set.html: garden
  void garden() {
    // the big palm's shadow stays off the stone path: on the pale stones it read as a stain (the grass keeps it)
    final before = Uint8List.fromList(e.shadowMask);
    k.part('palma', () => k.swayPalm(PALM[0], PALM[1], PALM_H, PALM_LEAN, 2, PALM_SIZE, LIGHT));
    for (var i = 0; i < e.W * e.H; i++) {
      if (e.kinds[i] == KIND_ROAD) e.shadowMask[i] = before[i];
    }
    // two bushes, like the old garden's, where no touch box reaches (right of the house; the front left corner)
    k.part('arbusto', () {
      b.bush(BUSH1[0], BUSH1[1], .5, lit(const [96, 150, 70], LIGHT));
      b.bush(BUSH2[0], BUSH2[1], .45, lit(C.leaf, LIGHT));
    });
    if (SET.hide) {
      // one pixel to the side on screen
      double sh(String side) =>
          SET.rustle == side || SET.rustle == 'todo' ? SET.side / (e.S * R2) : 0;
      k.part(
        'palma_pequena',
        () => k.swayPalm(
          SPALM[0] + sh('palma'),
          SPALM[1] - sh('palma'),
          SPALM_H,
          SPALM_LEAN,
          5,
          SPALM_SIZE,
          LIGHT,
        ),
      );
      k.part('casa_pequena', () => k.birdhouse(BIRD[0] + sh('casa'), BIRD[1] - sh('casa'), LIGHT));
    }
  }

  /* ---------- bake one state ---------- */

  // frente-set.html: buildSet
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
    // the ground and its grass are the same in every state: made once, then copied (a second bake in the same page
    // reuses them)
    final cache = _groundCaches[e];
    if (cache == null) {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5), i = iy * e.W + ix, c = frontGround(g.x, g.y, ix, iy, i);
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
    house();
    garden();
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    final L = LIGHT;
    if (L != null) k.lightPass(L.m, L.a, !L.litTufts);
    // the sky: bands, far hills, the sun
    final sky = SKY;
    k.skyFill((ix, iy) {
      final sun = sky.sun;
      if (sun != null) {
        final s = k.skyDisc(SUN[0], SUN[1], SUN[2], sun, ix, iy);
        if (s != 0) return s;
      }
      final h = k.skyHills(HZ, sky.far, sky.near, ix, iy);
      return h != 0 ? h : k.skyBands(sky.bands, 0, HZ, ix, iy);
    });
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }
}
