// Port of docs/proyecto/pixel/mesa-set.html: La mesa's set, its states, call for call (order 37a's set reference, order
// 37b's port), on the kitchen's kit (cocina_kit.dart). The page's names are kept, capitals included, so the port reads
// line for line against it (page 12, section 6): the lints on names are off in this file.
//
// Not ported: the page's `?noshade=1` and `?empty=1` (pictures for the maker's checks, not states), `?prof=1` (the time
// each part takes) and its `ox`, `oy` (the origin is the sheet's). `?tags=1` is the kit's `PART_TAGS` (the scene records
// them at a state's first bake), with the page's own tag of the door's reveal (`puerta.jamba`).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cocina_kit.dart';
import 'package:coqui_scenes/src/mesa/mesa_frutas_still.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The engine La mesa's set is built on (mesa-set.html: `window.PP_SCENE`, with the page's default origin, which is the
/// sheet's): 240 × 216, S 26, origin (4, -22), shadows to (.9, -.1): the kitchen's light.
PpEngine mesaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 4,
  originY: -22,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (mesa-set.html: `SET`, from the address): the cloth on the table, the oven lit.
class MesaState {
  const MesaState({this.mantel = false, this.horno = false});

  /// mesa-set.html: `pick('mantel', ['0', '1'], '0') === '1'`, the same for `horno`, from a query
  /// (`?mantel=1&horno=0`); a value the page does not allow takes its default, as there.
  factory MesaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    bool pick(String k) => q[k] == '1';
    return MesaState(mantel: pick('mantel'), horno: pick('horno'));
  }

  /// A key of the sheet's `setKey` table (`"m0h0"`, `"m1h0"`, `"m0h1"`, `"m1h1"`) read back.
  factory MesaState.fromKey(String key) {
    final m = RegExp(r'^m([01])h([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', 'not a key of La mesa\'s set');
    }
    return MesaState(mantel: m[1] == '1', horno: m[2] == '1');
  }

  /// W.mantel: the white cloth on the table.
  final bool mantel;

  /// W.estufa.horno: the oven lit (its window glows).
  final bool horno;

  /// The sheet's key (`setKey.key`: `"m" + mantel + "h" + horno`).
  String get key => 'm${mantel ? 1 : 0}h${horno ? 1 : 0}';

  /// The query of the page for this state (`mantel=0&horno=0`).
  String get query => 'mantel=${mantel ? 1 : 0}&horno=${horno ? 1 : 0}';
}

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// mesa-set.html: r3
double r3(num v) => _round(v * 1000) / 1000;

/// A table (mesa-set.html: `TBL`): x0..x1, y0..y1 on the floor, its top at z, its top's thickness th.
typedef MesaTable = ({
  double x0,
  double x1,
  double y0,
  double y1,
  double z,
  double th,
});

/// A chair (mesa-set.html: an entry of `CHAIRS`): its seat's middle.
typedef MesaChair = ({double x, double y});

/// What mesa-set.html's `surfaceAt` gives: which surface ([on]: `mesa`, `mostrador`, `mostrador2`, `estufa`, `floor` or
/// `wall`), its height [z] and world point ([x], [y]); on the floor, what stands over it ([under]: `mesa`, `mostrador`,
/// `mostrador2`, `estufa`, `silla0` .. `silla3`, or null: clear floor).
typedef MesaSurface = ({
  String on,
  double z,
  double x,
  double y,
  String? under,
});

/// The plan of La mesa's set (mesa-set.html, "the plan": every number and place, world units), the same for every state
/// and every engine with the set's settings.
class MesaPlan {
  MesaPlan(this.e) {
    LAPS = [
      for (var k = 0; k < 4; k++)
        () {
          final p = Gs(SILLA[k], 150 + SD[k] - 8, ZS);
          return [r3(p[0]), r3(p[1])];
        }(),
    ];
    LY = LAPS[0][1];
    TBL = (
      x0: r3(LAPS[0][0] - .6),
      x1: r3(LAPS[3][0] + .5),
      y0: r3(Gs(SILLA[0], 150 + SD[0] - 14, ZT)[1]),
      y1: r3(Gs(SILLA[0], 150 + SD[0] + 11, ZT)[1]),
      z: ZT,
      th: .07,
    );
    CHAIRS = [for (final l in LAPS) (x: l[0], y: r3(l[1] - .2))];
    A0 = r3(.9 + (e.OX - 88) / (e.S / e.R2));
    STX = r3(.9 + (205 - e.OX) / (e.S / e.R2) - K.STW / 2);
    LEAF = (
      hx: .05,
      hy: r3(DOOR.a0 - .12),
      len: r3(DOOR.a1 - DOOR.a0),
      ang: -1.0,
    );
    BAND = {
      'x': [
        [A0 - .2, YL],
      ],
      'y': [
        [STX - .18, XR],
      ],
    };
    FOOT = {
      'mesa': [TBL.x0, TBL.y0, TBL.x1, TBL.y1],
      'mostrador': [0, A0, K.CD, A1],
      'mostrador2': [STX + K.STW, 0, XR, K.CD],
      'estufa': [STX, 0, STX + K.STW, K.SD],
    };
  }

  /// An engine with the set's settings: its projection.
  final PpEngine e;

  // mesa-set.html: Gs. The world point at height z under a screen point
  List<double> Gs(num sx, num sy, [num z = 0]) {
    final u = (sx - e.OX) / e.S,
        v = (sy - e.OY + z * e.COS * e.S) / (e.S * e.SIN);
    return [(u + v) / e.R2, (v - u) / e.R2, z.toDouble()];
  }

  // mesa-set.html: SCR
  List<double> SCR(num x, num y, [num z = 0]) {
    final p = e.project(x, y, z);
    return [p.sx, p.sy];
  }

  // how far the back wall and the left wall run (past the picture's edges)
  static const double XR = 9, YL = 9;

  // the four seats (old SILLA, people at row 150): each steps down the table by SD rows (moves); a sitter's lap at
  // (x, y - 8) is on the seat (ZS)
  static const List<int> SILLA = [104, 128, 152, 176], SD = [-15, -3, 9, 21];

  // the chairs' seat and the table's top
  static const double ZS = .6, ZT = 1.0;

  late final List<List<double>> LAPS;

  // the seats' line (y): every lap on it
  late final double LY;

  // the table: its far edge 14 rows over a sitter's feet row (the old: 20; across a sitter's width the edge rises 5.5
  // rows to the left, so it covers no row of them the old table did not), its near edge 11 rows under it (the spilt
  // things in front of each place, old FRENTE + 2, lie on it); its left end .6 past the first seat, its right end .5
  // past the last (clear of abuela at the stove)
  late final MesaTable TBL;

  // a chair: its seat's middle .2 behind the lap (its front edge .02 behind it), .5 wide and .44 deep; the back at its
  // far edge, up to ZB
  static const double CH_hw = .25, CH_hd = .22, CH_back = .36, CH_ZB = 1.45;

  late final List<MesaChair> CHAIRS;

  // the counter on the left wall: from the corner side A0 (its top's front corner at the old counter's right end,
  // screen x 88) off the picture
  late final double A0;
  static const double A1 = YL;

  // the wall cupboard over it
  static const List<double> UP = [3.3, 5.4];

  // the back wall: the window, the stove (its front's middle at the old stove's, screen x 205), the counter beside it
  late final double STX;

  // (the kit's backdrop stands K.T + K.OUTD behind the wall, and a sight line through the window meets it that far along
  // the wall to the left: the bush's place bushA is on the backdrop, so -1.5 puts it in the window's right half, as the
  // old)
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

  // the doorway to the yard in the left wall, between the corner and the counter (the old picture's door at its left
  // edge): whoever comes in to sit, or leaves, appears and goes there (moves: PUERTA), walking along the walkway behind
  // the chairs (PASO). (round 2) a door, not a picture of one: 2.75 high (whoever stands on its step outside is whole in
  // the opening, their head under its top); its leaf open into the room and back towards the corner (hinged at the jamb
  // on the corner's side: on the other side the counter stands .24 from the jamb), with its brass handle; a wooden
  // threshold across the wall's thickness; through it the patio's ground at the kitchen floor's level: El patio's stone
  // step outside the door (C.stone), then the lawn (the engine's GRASS) out to the yard's wall and hedge (the kit's
  // backdrop, K.T + K.OUTD behind the wall's face)
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

  // its hinge, its width, its turn from the wall's normal (+x) towards -y
  late final ({double hx, double hy, double len, double ang}) LEAF;

  // the stone step's depth out from the wall's outer face
  static const double STEP_D = .42;

  // the walkway behind the chairs (y), its end in the doorway; out: where whoever comes in appears (on the step, just
  // outside the threshold, its sight line through the opening's middle: x - y as the walkway's end at screen x 84, so
  // they come straight in onto the walkway)
  static const double WALK_y = 2.2;
  static const List<double> WALK_door = [.024, 2.2], WALK_out = [-.25, 1.926];

  late final Map<String, List<List<double>>> BAND;

  // El patio's step (mapa.js C.stone)
  static const List<int> STONE = [216, 206, 184];

  // the table's wood (old #D8B078 ...), its legs, the chairs (old Wd[0]..Wd[1]): legs and chairs dark enough to stand
  // out from both floor tiles (WCAG contrast 2 and more: sheet checks.thin)
  static const List<int> TW = [214, 168, 112], TWD = [104, 68, 36];
  static const List<int> CHW = [110, 66, 32];

  // the cloth (old #FBFBFF, #D8D8E4, its red band #D0302A)
  static const List<int> CLOTH = [250, 250, 255],
      CLOTHD = [222, 222, 236],
      CLOTHR = [208, 48, 42];

  // what is under a screen point (the sheet's floor rule): the footprints
  late final Map<String, List<double>> FOOT;

  // mesa-set.html: STOVE
  ({double x0, double x1, double y0, double y1, double z}) get STOVE =>
      (x0: STX, x1: STX + K.STW, y0: 0, y1: K.SD, z: K.CZ);

  // mesa-set.html: inR
  static bool inR(num x, num y, List<num> r, [num m = 0]) =>
      x >= r[0] - m && x <= r[2] + m && y >= r[1] - m && y <= r[3] + m;

  // mesa-set.html: surfaceAt. What is under a screen point (the sheet's floor rule): the table's top, a counter's top,
  // the stove's top, or the floor (z 0); on the floor, whether the point is under the table or a chair, in a counter's
  // or the stove's footprint (not clear floor)
  MesaSurface surfaceAt(num sx, num sy) {
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
}

/// What the outside seen through the doorway is, per engine (mesa-set.html: `PATIO_PX`, filled when the floor is laid,
/// which the kit does once per engine: kept as long as that floor).
final Expando<List<int>> _patioPx = Expando<List<int>>();

/// SetKit with mesa-set.html's own wrapper of `revealX`: while the part tags are recorded (`?tags=1`), the pixels the
/// door's reveal draws (the wall's thickness seen in the opening) are kept, to be tagged `puerta.jamba` (`tagReveal`).
class _MesaKit extends SetKit {
  _MesaKit(super.e, super.b);

  // mesa-set.html: REVEAL
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

/// The set of La mesa in one state, built into an engine (mesa-set.html, from "the plan" to `buildSet`).
class MesaSet {
  MesaSet(this.e, this.b, this.SET) : k = _MesaKit(e, b) {
    c = CocinaKit(k);
    P = MesaPlan(e);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CocinaKit c;

  /// The plan's numbers (mesa-set.html: the constants from `XR` to `BAND`, `FOOT`, `STOVE`).
  late final MesaPlan P;

  // mesa-set.html: SET
  final MesaState SET;

  int get W => e.W;
  int get H => e.H;
  double get ST => b.ST;

  /* ---------- the table and its chairs ---------- */

  // mesa-set.html: tableLegs
  void tableLegs() {
    final t = P.TBL;
    for (final lx in [t.x0 + .12, t.x1 - .2]) {
      for (final ly in [t.y0 + .1, t.y1 - .18]) {
        c.kSolid(
          'y',
          lx,
          lx + .08,
          ly,
          ly + .08,
          0,
          t.z - t.th - .16,
          MesaPlan.TWD,
        );
      }
    }
  }

  // mesa-set.html: table
  void table() {
    final t = P.TBL, x0 = t.x0, x1 = t.x1, y0 = t.y0, y1 = t.y1, z = t.z;
    final th = t.th, R = e.rampOf(MesaPlan.TW), L = e.rampOf(MesaPlan.TWD);
    // the legs, inset from the corners, and the apron under the top
    c.kBox(
      'y',
      x0 + .1,
      x1 - .1,
      y0 + .08,
      y1 - .08,
      z - th - .16,
      z - th,
      (f, p, q, sh) => f == 'top' ? 0 : L[sh ? 1 : 2],
    );
    // the top: planks along the table, a lit rim
    c.kBox('y', x0, x1, y0, y1, z - th, z, (f, p, q, sh) {
      if (f == 'top') {
        final ee = q - y0, plank = ee.remainder(.3) < .022;
        return R[p > x1 - .03 || q > y1 - .03
            ? 4
            : plank
            ? 2
            : 3];
      }
      return R[sh ? 1 : 2];
    });
  }

  // mesa-set.html: cloth. The cloth on the table (mantel): over the top, hanging over its near side and its right end, a
  // red band near the hem
  void cloth() {
    final t = P.TBL, x0 = t.x0, x1 = t.x1, y0 = t.y0, y1 = t.y1, z = t.z;
    const m = .03, drop = .2;
    final C = c.kRgb(MesaPlan.CLOTH),
        CD = c.kRgb(MesaPlan.CLOTHD),
        CR = c.kRgb(MesaPlan.CLOTHR);
    c.kBox('y', x0 - m, x1 + m, y0 - m, y1 + m, z - drop, z + .012, (
      f,
      p,
      q,
      sh,
    ) {
      if (f == 'top') return C;
      final h = z + .012 - q; // how far down from the top's edge
      if (h > drop - .035) return CD; // the hem
      if (h > drop - .1 && h < drop - .06) return CR; // the red band
      return sh ? CD : C;
    });
  }

  // mesa-set.html: chairLegs
  void chairLegs() {
    for (final ch in P.CHAIRS) {
      final xa = ch.x - MesaPlan.CH_hw,
          xb = ch.x + MesaPlan.CH_hw,
          ya = ch.y - MesaPlan.CH_hd,
          yb = ch.y + MesaPlan.CH_hd;
      for (final lx in [xa, xb - .05]) {
        for (final ly in [ya, yb - .05]) {
          c.kSolid(
            'y',
            lx,
            lx + .05,
            ly,
            ly + .05,
            0,
            MesaPlan.ZS - .06,
            MesaPlan.CHW,
          );
        }
      }
    }
  }

  // mesa-set.html: chairs
  void chairs() {
    final R = e.rampOf(MesaPlan.CHW);
    const ZS = MesaPlan.ZS, ZB = MesaPlan.CH_ZB;
    for (final ch in P.CHAIRS) {
      final xa = ch.x - MesaPlan.CH_hw,
          xb = ch.x + MesaPlan.CH_hw,
          ya = ch.y - MesaPlan.CH_hd,
          yb = ch.y + MesaPlan.CH_hd;
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
      // the back: two posts and two rails at the seat's far edge (the old chairs: two posts, two slats)
      for (final px in [xa, xb - .06]) {
        c.kSolid('y', px, px + .06, ya, ya + .06, ZS, ZB, MesaPlan.CHW);
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
  }

  /* ---------- the door (round 2) ---------- */

  // mesa-set.html: PATIO_PX (the outside's pixels and colours: the floor's dimming is not theirs), kept with this
  // engine's floor (the kit lays it once per engine, as the page once per page)
  List<int> get PATIO_PX => _patioPx[e] ??= <int>[];

  // mesa-set.html: patioGround. The floor outside: the patio's ground seen through the doorway (cocinaBuild plan.floor):
  // every floor point outside the wall (x < -K.T) whose sight line crosses the wall's plane in the opening (y - x from
  // a0 - .3 to a1 + .3), out to the backdrop: the step, its outer edge a darker line, then the lawn, flat (one tone: no
  // speck)
  int patioGround(double x, double y, int ix, int iy, int i) {
    final col = patioColour(x, y);
    if (col != 0) PATIO_PX.addAll([i, col]);
    return col;
  }

  // mesa-set.html: patioColour
  int patioColour(double x, double y) {
    if (x >= -K.T || x < -K.T - K.OUTD) return 0;
    final a = y - x;
    if (a < MesaPlan.DOOR.a0 - .3 || a > MesaPlan.DOOR.a1 + .3) return 0;
    final R = e.rampOf(MesaPlan.STONE);
    if (x > -K.T - MesaPlan.STEP_D + .04) return R[3];
    if (x > -K.T - MesaPlan.STEP_D) return R[1];
    final g = e.GRASS[3];
    return e.rgb(g[0], g[1], g[2]);
  }

  // mesa-set.html: doorExtras
  void doorExtras() {
    final Wd = e.rampOf(KC.wood);
    final a0 = MesaPlan.DOOR.a0, a1 = MesaPlan.DOOR.a1, z1 = MesaPlan.DOOR.z1;
    final w = P.LEAF.len;
    // the threshold: a wooden sill across the wall's thickness and a little into the room, its top lit
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
    // the outside under the opening: the wall's thickness has no floor of its own (the reveal's bottom is the
    // threshold's). The leaf: a wooden door of four panels, as El balcón's and La sala's; its free edge darker
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
      // its handle: brass, near the free edge, at hand height
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

  /* ---------- bake one state ---------- */

  // mesa-set.html: PLAN.furnish
  void furnish() {
    doorExtras();
    k.part('mostrador', () {
      c.cocinaBase('x', P.A0, MesaPlan.A1);
    });
    k.part('alacena', () {
      c.cocinaWallCupboard('x', MesaPlan.UP[0], MesaPlan.UP[1]);
    });
    k.part('estufa', () {
      c.cocinaStove('y', P.STX, noEnd: true, horno: SET.horno);
    });
    k.part('campana', () {
      c.cocinaBackguard('y', P.STX);
      c.cocinaHood('y', P.STX);
    });
    k.part('mostrador2', () {
      c.cocinaBase('y', P.STX + K.STW, MesaPlan.XR);
    });
    k.part('sillas.patas', chairLegs);
    k.part('sillas', chairs);
    k.part('mesa.patas', tableLegs);
    k.part('mesa', () {
      table();
      if (SET.mantel) cloth();
    });
  }

  // mesa-set.html: PLAN.shadows. The table's legs and the chairs' legs: a short contact shadow at each foot (thin
  // things); the table's top: a low shade under it
  void shadows() {
    final t = P.TBL;
    k.part('mesa.patas', () {
      for (final lx in [t.x0 + .16, t.x1 - .16]) {
        for (final ly in [t.y0 + .14, t.y1 - .14]) {
          c.cocinaShadowFoot(lx, ly, .08);
        }
      }
    });
    // (the chairs' front legs stand under the table's top: no shadow is seen there)
    k.part('sillas.patas', () {
      for (final ch in P.CHAIRS) {
        for (final lx in [
          ch.x - MesaPlan.CH_hw + .025,
          ch.x + MesaPlan.CH_hw - .025,
        ]) {
          c.cocinaShadowFoot(lx, ch.y - MesaPlan.CH_hd + .025, .035);
        }
      }
    });
  }

  // mesa-set.html: PLAN
  late final CocinaPlan PLAN = CocinaPlan(
    XR: MesaPlan.XR,
    YL: MesaPlan.YL,
    windows: const [MesaPlan.WIN, MesaPlan.DOOR],
    band: P.BAND,
    occlusion: 'shade',
    floor: patioGround,
    furnish: furnish,
    shadows: shadows,
  );

  // mesa-set.html: tagReveal. (tags=1 only) the door's reveal (the kit's revealX: the wall's thickness seen in the
  // opening) tagged puerta.jamba
  void tagReveal() {
    final tags = k.PART_TAGS, R = (k as _MesaKit).REVEAL;
    if (tags == null) return;
    for (final en in R.entries) {
      if (tags[en.key] == 'puerta' && e.pix[en.key] == en.value) {
        tags[en.key] = 'puerta.jamba';
      }
    }
    R.clear();
  }

  // mesa-set.html: undimPatio
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

  // mesa-set.html: noSpecks. (round 2) no speck on the floor: a group of fewer than 6 floor pixels of one colour with no
  // pixel of its colour round it (a 1 px gap between a leg of the table and a chair's, a dot of the dimming's dither)
  // takes the colour most of the floor round it has (or, with no floor round it, the darkest pixel round it: it reads as
  // the leg's or the shade's)
  void noSpecks() {
    final pix = e.pix, zb = e.zb, gz = e.groundZ, ground = e.ground;
    bool isF(int i) => ground[i] != 0 && zb[i] == gz[i];
    const N8 = [
      [-1, -1],
      [0, -1],
      [1, -1],
      [-1, 0],
      [1, 0],
      [-1, 1],
      [0, 1],
      [1, 1],
    ];
    const N4 = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];
    for (var pass = 0; pass < 4; pass++) {
      var changed = 0;
      final seen = Uint8List(W * H);
      for (var i = 0; i < W * H; i++) {
        if (seen[i] != 0 || !isF(i)) continue;
        final col = pix[i], grp = <int>[i], q = <int>[i];
        seen[i] = 1;
        while (q.isNotEmpty && grp.length < 6) {
          final j = q.removeLast(), x = j % W, y = j ~/ W;
          for (final d in N4) {
            final nx = x + d[0], ny = y + d[1], m = ny * W + nx;
            if (nx < 0 ||
                nx >= W ||
                ny < 0 ||
                ny >= H ||
                seen[m] != 0 ||
                !isF(m) ||
                pix[m] != col) {
              continue;
            }
            seen[m] = 1;
            grp.add(m);
            q.add(m);
          }
        }
        if (grp.length >= 6) continue;
        final S = grp.toSet(), cnt = <int, int>{};
        var same = false, dark = 0, darkL = 1e9;
        for (final j in grp) {
          final x = j % W, y = j ~/ W;
          for (final d in N8) {
            final nx = x + d[0], ny = y + d[1], m = ny * W + nx;
            if (nx < 0 || nx >= W || ny < 0 || ny >= H || S.contains(m)) {
              continue;
            }
            if (pix[m] == col) {
              same = true;
              break;
            }
            if (isF(m)) {
              cnt[pix[m]] = (cnt[pix[m]] ?? 0) + 1;
            } else if (zb[m] > -1e8) {
              final v = pix[m],
                  L = (v & 255) + ((v >> 8) & 255) + ((v >> 16) & 255);
              if (L < darkL) {
                darkL = L.toDouble();
                dark = v;
              }
            }
          }
          if (same) break;
        }
        if (same) continue;
        var to = dark, best = 0;
        for (final en in cnt.entries) {
          if (en.value > best) {
            best = en.value;
            to = en.key;
          }
        }
        if (to == 0) continue;
        for (final j in grp) {
          pix[j] = to;
        }
        changed++;
      }
      if (changed == 0) break;
    }
    e.bakedPix.setAll(0, pix);
  }

  // mesa-set.html: buildSet (and buildSet0, with neither `noshade` nor `empty`)
  void buildSet() {
    c.cocinaCheckScene();
    c.cocinaBuild(PLAN);
    undimPatio();
    noSpecks();
    tagReveal();
  }

  // mesa-set.html: frame. The baked set, with the casts given
  void frame(num t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final cc in casts) {
      e.castShadow(cc[0], cc[1], cc[2], cc[3]);
    }
    e.applyShadows(e.groundZ);
  }
}

/// The still of El colmado's stall (cual-mesa's cocina.no: the sheet's `pictures["cocina.no"].port`): the picture
/// frutas-set.html?surtido=frutas draws, 240 × 216, as coqui/tool/ref/pp/make.js baked it once
/// (coqui/ref/pp/mesa/frutas-surtido-frutas/, written into mesa_frutas_still.dart by tool/make_mesa_still.dart), each
/// pixel `0xAABBGGRR`. It goes when El colmado's `frutas` is ported (order 52): its set at that state draws it then.
Uint32List mesaFrutas() => _frutas ??= () {
  final parts = mesaFrutasStill.trim().split('\n\n');
  final colours = [
    for (final h in parts[0].split(RegExp(r'\s+'))) int.parse(h, radix: 16),
  ];
  final runs = base64Decode(parts[1].replaceAll('\n', ''));
  final out = Uint32List(240 * 216);
  var i = 0, at = 0;
  while (at < runs.length) {
    final c = colours[runs[at] | (runs[at + 1] << 8)];
    at += 2;
    var n = 0, shift = 0;
    while (true) {
      final b = runs[at++];
      n |= (b & 127) << shift;
      if (b < 128) break;
      shift += 7;
    }
    out.fillRange(i, i + n, c);
    i += n;
  }
  if (i != out.length) {
    throw StateError('the still of El colmado\'s stall is not 240 x 216');
  }
  return out;
}();

Uint32List? _frutas;
