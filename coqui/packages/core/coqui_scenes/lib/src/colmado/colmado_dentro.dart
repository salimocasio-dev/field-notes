// Port of docs/proyecto/pixel/colmado-dentro.js: don Pepe's colmado, inside, call for call. One room on the Pixel Plays
// engine, shared by three scene sets of place 4 (mostrador, estantes, caja): each set builds its engine with its own
// origin, then calls [ColmadoDentro.build] from its buildSet. The file's names are kept, capitals included, so the port
// reads line for line against it (page 12, section 6): the lints on names are off in this file.
//
// First writer: order 50b (El mostrador). The builders of estantes, frutas and caja copy it and add to it only by
// adding. The whole file is ported, also the parts El mostrador does not use (the ladder, the rings, the low table,
// the clock, the stand-in goods), each tested against the JavaScript (test/colmado_kit_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// colmado-dentro.js: OPT. What the room shows (each set page's own `SET`, or the parts it fixes).
class CdOpt {
  const CdOpt({
    this.hora = 'manana',
    this.atras = 'shut',
    this.props = false,
    this.nevera = false,
    this.escalera = false,
    this.caja = true,
    this.vitrina = true,
    this.anillos = false,
    this.mesa = false,
    this.reloj = false,
  });

  /// 'manana' | 'tarde': what shows through the street door, and the patch of light on the floor.
  final String hora;

  /// 'shut' | 'open': the back door (to the store room: dim, with sacks and boxes in it).
  final String atras;

  /// Stand-in goods on the shelves (for the readers' renders; the game draws them as sprites).
  final bool props;

  /// The little chest freezer on the counter (story 38).
  final bool nevera;

  /// The ladder against the second run's top shelf (estantes).
  final bool escalera;

  /// `o.caja !== false`: the cash register at the counter's left end (there unless false).
  final bool caja;

  /// `o.vitrina !== false`: the shop window in the left wall (there unless false).
  final bool vitrina;

  /// Six rings of dust on the second run's middle shelf (story 39).
  final bool anillos;

  /// The low display table in front of the second run of shelves (story 40).
  final bool mesa;

  /// The wall clock (off unless asked for: no story of place 4 needs it).
  final bool reloj;
}

/// One of the goods on the shelves (colmado-dentro.js: GOODS): its key, its shelf (0 low, 1 middle), its x.
typedef CdGood = ({String k, int s, double x});

/// The register's box and its parts' measures (colmado-dentro.js: RG).
typedef CdRegister = ({
  double x0,
  double x1,
  double y0,
  double y1,
  double bodyH,
  double headY,
  double headH,
});

/// The register's small side shelf (colmado-dentro.js: SHELF).
typedef CdShelf = ({double x0, double x1, double y0, double y1, double z});

/// The chest freezer on the counter (colmado-dentro.js: NV).
typedef CdFreezer = ({double x0, double x1, double y0, double y1, double h});

/// Port of colmado-dentro.js (`CD`): the room, its constants and what it exports for the sheets, on one engine through
/// the set kit [k]. The room (world units; S = 26): two walls meet at the far corner (0, 0). The back wall is y = 0 (it
/// faces +y: lit) and carries the shelves; the left wall is x = 0 (it faces +x: in shade) and has the shop window and the
/// street door. The counter runs along the back wall, with don Pepe's aisle between them; the back door to the store
/// room is beside the corner.
class ColmadoDentro {
  ColmadoDentro(this.k) : e = k.e, b = k.b;

  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  double get ST => b.ST;
  int get W => e.W;
  int get H => e.H;

  static const double RX1 = 21,
      RY1 = 12,
      WH = 3.3; // the room: floor to x, to y; wall height
  static const double CX0 = 1.3,
      CX1 = 6.2,
      CY0 = 2.0,
      CY1 = 2.85,
      CH = 1.0; // the counter
  static const double SX0 = 1.5,
      SX1 = 6.5,
      SD = .36,
      SXM = 5.5; // the shelves: along the back wall, their depth
  static const List<double> SZ = [1.3, 1.95, 2.6]; // the planks' heights
  static const double BD0 = .15,
      BD1 = 1.25,
      DH = 2.55; // the back door (x on the back wall), beside the corner
  static const double PD0 = 3.6,
      PD1 = 5.0; // the street door (y on the left wall)
  static const double VW0 = 1.45, VW1 = 3.15, VZ0 = 1.0, VZ1 = 2.45; // the shop window (y on the left wall), between the corner and the street door
  static const double E2X0 = 11.0,
      E2X1 = 15.0; // the second run of shelves, far along the back wall
  static const List<int> WALL = [244, 222, 150],
      DADO = [86, 170, 160],
      WOOD = [150, 98, 56],
      WOOD_L = [196, 148, 92],
      TOP = [224, 196, 150];
  static const List<double> MESA = [E2X0 + 1.3, 3.7];
  static const double MESA_H = .55; // the low display table (story 40): its middle, the height of its top (the cloth)
  static const List<double> SILLA = [
    6.9,
    4.5,
  ]; // the waiting chair, in front of the counter's right end
  static const List<List<int>> TILE = [
    [236, 224, 200],
    [214, 190, 160],
    [176, 150, 122],
  ];
  static const List<double> MAT = [
    .08,
    PD0 + .12,
    .8,
    PD1 - .12,
  ]; // the doormat, just inside the street door: x0, y0, x1, y1
  static const double LEAF_TURN =
      .28; // the street door's open leaf stands this many radians off the wall
  static const double XB =
      (SX1 + E2X0) / 2; // the bunch of plantains, between the runs
  static const List<CdGood> GOODS = [
    (k: 'leche', s: 0, x: 1.95),
    (k: 'pan', s: 0, x: 2.75),
    (k: 'mantequilla', s: 0, x: 3.55),
    (k: 'queso', s: 0, x: 4.35),
    (k: 'cafe', s: 0, x: 5.1),
    (k: 'arroz', s: 1, x: 2.2),
    (k: 'azucar', s: 1, x: 3.1),
    (k: 'jugo', s: 1, x: 4.0),
    (k: 'habichuelas', s: 1, x: 4.9),
  ];
  // the ladder: its feet on the floor a unit in front of the second run, its rails resting on the top plank's front edge
  static const double LX = E2X0 + 2.0,
      LY0 = SD + .04 + 1.0,
      LKZ =
          2.6 + .06, // SZ[2] + .06
      LTOP = LKZ + .26,
      LW = .3;
  static const double LSLOPE =
      (SD - LY0) / LKZ; // y moves this far for each unit of z going up
  static double ladderY(num z) => LY0 + LSLOPE * z;
  static const List<double> ESCALERA_PIE = [LX, LY0, 0];
  static final List<double> ESCALERA_ALTO = [
    LX,
    ladderY(LTOP * .75),
    LTOP * .75,
  ];
  // the register at the counter's left end: its box, then its parts' measures
  static const CdRegister RG = (
    x0: CX0 + .1,
    x1: CX0 + 1.15,
    y0: CY0 + .05,
    y1: CY1 - .05,
    bodyH: .32,
    headY: CY0 + .05 + .3,
    headH: .6,
  );
  static const double RGM =
      (CX0 + .1 + (CX0 + 1.15)) / 2; // (RG.x0 + RG.x1) / 2
  static const CdShelf SHELF = (
    x0: CX0 + 1.15,
    x1: CX0 + 1.15 + .3,
    y0: CY0 + .05 + .08,
    y1: CY0 + .05 + .44,
    z: CH + .25,
  ); // the small shelf on the register's right side (12 px wide)
  static const List<double> CAJA_VENTANA = [RGM, CY0 + .05 + .3, CH + .32 + .4];
  static const List<double> CAJA_GAVETA = [RGM, CY1 - .05, CH + .32 / 2];
  static const List<double> CAJA_REPISA = [
    (CX0 + 1.15 + (CX0 + 1.15 + .3)) / 2,
    (CY0 + .05 + .08 + (CY0 + .05 + .44)) / 2,
    CH + .25,
  ];
  static const CdFreezer NV = (
    x0: CX1 - 1.1,
    x1: CX1 - .2,
    y0: CY0 + .15,
    y1: CY0 + .7,
    h: .49,
  ); // the chest freezer on the counter's right end (26 px wide)
  static const List<double> NEVERA = [
    CX1 - 1.1,
    CY0 + .15,
    CH,
    CX1 - .2,
    CY0 + .7,
    CH + .49 + .05,
  ];

  double get PX => e.S / e.R2; // screen pixels along x - y, per world unit
  double stepDown(num v) => (v / ST).floor() * ST;
  void paneX(
    num at,
    num b0,
    num b1,
    num z0,
    num z1,
    int Function(num b, num z) fn,
  ) {
    for (num bb = b0; bb <= b1; bb += ST * .5) {
      for (num z = z0; z <= z1; z += ST * .5) {
        final c = fn(bb, z);
        if (c != 0) e.plot(at, bb, z, c);
      }
    }
  }

  int rgbOf(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // colmado-dentro.js: pixelsX. A flat picture on the plane x = xp (stood a little off the left wall), judged at the
  // middle of each screen pixel, so a thin line is never lost to its neighbour: fn(b, z) gives a colour or 0; the pixels
  // of the rectangle b0..b1 x z0..z1 are walked and each is drawn where the plane is
  void pixelsX(
    num xp,
    num b0,
    num b1,
    num z0,
    num z1,
    int Function(num b, num z) fn,
  ) {
    final cs = [
      for (final bz in [
        [b0, z0],
        [b1, z0],
        [b0, z1],
        [b1, z1],
      ])
        e.project(xp, bz[0], bz[1]),
    ];
    final ix0 = cs.map((c) => c.sx).reduce(math.min).floor() - 1,
        ix1 = cs.map((c) => c.sx).reduce(math.max).ceil() + 1,
        iy0 = cs.map((c) => c.sy).reduce(math.min).floor() - 1,
        iy1 = cs.map((c) => c.sy).reduce(math.max).ceil() + 1;
    for (var iy = iy0; iy <= iy1; iy++) {
      for (var ix = ix0; ix <= ix1; ix++) {
        final u = (ix + .5 - e.OX) / e.S,
            bb = xp - u * e.R2,
            v = (xp + bb) / e.R2,
            z = (v * e.SIN - (iy + .5 - e.OY) / e.S) / e.COS;
        if (bb < b0 || bb > b1 || z < z0 || z > z1) continue;
        final c = fn(bb, z);
        if (c != 0) e.plot(xp, bb, z, c);
      }
    }
  }

  // colmado-dentro.js: stampY. A picture of one-pixel cells on a +y face (y = at): rows of characters, the middle of the
  // picture on the face point (x, z); key maps a character to a colour (a missing one leaves the face as it is)
  void stampY(num at, num x, num z, List<String> rows, Map<String, int> key) {
    final plane = at + .004,
        p = e.project(x, plane, z),
        cx = p.sx.floor() - (rows[0].length >> 1),
        cy = p.sy.floor() - (rows.length >> 1);
    k.paneY(plane, x - .4, x + .4, z - .4, z + .4, (a, zz) {
      final q = e.project(a, plane, zz),
          r = q.sy.floor() - cy,
          kk = q.sx.floor() - cx;
      if (r < 0 || r >= rows.length) return 0;
      final row = rows[r];
      // rows[r][k] is undefined there: key[undefined] is no colour
      if (kk < 0 || kk >= row.length) return 0;
      return key[row[kk]] ?? 0;
    });
  }

  // colmado-dentro.js: floorAt
  int floorAt(num x, num y, int ix, int iy, int i) {
    if (x < 0 || y < 0 || x > RX1 || y > RY1) return 0;
    e.kinds[i] = KIND_ROAD;
    if (x > MAT[0] && x < MAT[2] && y > MAT[1] && y < MAT[3]) {
      // the doormat: coir, a dark border, stripes across it
      final ed = math.min(
        math.min(x - MAT[0], MAT[2] - x),
        math.min(y - MAT[1], MAT[3] - y),
      );
      if (ed < .06) return e.rgb(70, 46, 34);
      final kk = e.hash(ix, iy) < .16 ? 1.14 : 1,
          stripe = ((y - MAT[1]) / .15).floor() % 2;
      final c = stripe != 0 ? const [138, 94, 64] : const [112, 74, 52];
      return e.rgb(c[0] * kk, c[1] * kk, c[2] * kk);
    }
    final ta = x / .62,
        tb = y / .62,
        ea = ta - ta.floor(),
        eb = tb - tb.floor();
    if (ea < .06 || eb < .06) return rgbOf(TILE[2]);
    return rgbOf(TILE[(ta.floor() + tb.floor()) % 2 != 0 ? 1 : 0]);
  }

  // colmado-dentro.js: storeRoom. A store room seen through the open back door: its floor, its two walls (the back one
  // lit), two sacks and a stack of boxes. Only what a sight line through the doorway reaches is drawn (a sight line runs
  // one unit down for every T units back)
  void storeRoom() {
    final T = math.tan(math.pi / 6) * math.sqrt2;
    const X0 = -1.7, Y0 = -1.9;
    bool seen(num x, num y, num z) {
      final d = x - y, h = z - T * y;
      return d > BD0 - .05 && d < BD1 + .05 && h > -.05 && h < DH + .05;
    }

    void put(num x, num y, num z, int c) {
      if (seen(x, y, z)) e.plot(x, y, z, c);
    }

    final FL = e.rampOf(const [142, 114, 86]),
        BK = e.rampOf(const [112, 88, 66]),
        SDr = e.rampOf(const [
          84,
          66,
          52,
        ]); // the floor is a little lighter than the walls
    for (num a = X0; a <= BD1 + .1; a += ST) {
      for (num bb = Y0; bb <= 0; bb += ST) {
        put(a, bb, 0, FL[((a - bb) / .34).floor().remainder(2) != 0 ? 3 : 2]);
      }
    }
    for (num a = X0; a <= BD1 + .1; a += ST) {
      for (num z = 0; z <= DH + .3; z += ST) {
        put(a, Y0, z, BK[z > 1.6 ? 2 : 3]);
      }
    }
    for (num bb = Y0; bb <= 0; bb += ST) {
      for (num z = 0; z <= DH + .3; z += ST) {
        put(X0, bb, z, SDr[2]);
      }
    }
    // the stack of boxes against the back wall: flat faces, a tape across each
    const y0 = Y0 + .03, y1 = Y0 + .5;
    for (final bx in const <(double, double, double, double, List<int>)>[
      (-.95, -.25, 0, .3, [196, 152, 100]),
      (-.9, -.3, .3, .58, [176, 134, 88]),
      (-.93, -.28, .58, .84, [204, 160, 106]),
      (-.88, -.33, .84, 1.08, [186, 144, 96]),
    ]) {
      final (x0, x1, z0, z1, c) = bx;
      final BX = e.rampOf(c);
      for (num a = x0; a <= x1; a += ST) {
        for (num bb = y0; bb <= y1; bb += ST) {
          put(a, bb, z1, BX[4]);
        }
      }
      for (num a = x0; a <= x1; a += ST) {
        for (num z = z0; z <= z1; z += ST) {
          put(
            a,
            y1,
            z,
            (z1 - z < .035 || z - z0 < .025)
                ? BX[1]
                : ((z - (z0 + z1) / 2).abs() < .025 ? BX[4] : BX[3]),
          );
        }
      }
      for (num bb = y0; bb <= y1; bb += ST) {
        for (num z = z0; z <= z1; z += ST) {
          put(x1, bb, z, BX[1]);
        }
      }
    }
    // two sacks on the floor in front: a round body, a tied neck
    void sack(num x, num y) {
      e.sphere(x, y, .18, .2, const [190, 164, 116], 'solid');
      e.sphere(x, y, .34, .19, const [190, 164, 116], 'solid');
      e.sphere(x, y, .5, .12, const [168, 142, 98], 'solid');
      e.sphere(x + .02, y, .6, .07, const [140, 114, 76], 'solid');
    }

    sack(.2, -.45);
    sack(.43, -.55);
  }

  // colmado-dentro.js: walls
  void walls(CdOpt o) {
    final aLo = math.max<num>(0, stepDown((-6 - e.OX) / PX)),
        aHi = math.min<num>(
          RX1,
          (W + 6 - e.OX) / PX,
        ); // only the stretch of each wall a picture can show is drawn
    final bLo = math.max<num>(0, stepDown((e.OX - W - 6) / PX)),
        bHi = math.min<num>(RY1, (e.OX + 6) / PX);
    k.part('pared', () {
      // the back wall, with the back door's hole; a painted dado along its foot
      k.wallY(0, aLo, aHi, 0, WH, WALL, const [
        [BD0, BD1, 0, DH],
      ]);
      for (num a = aLo; a <= aHi; a += ST) {
        if (a > BD0 && a < BD1) continue;
        for (num z = 0; z <= .9; z += ST) {
          e.plot(a, .01, z, b.shade(DADO, z > .84 ? 1.4 : 2.4, a, z));
        }
      }
      // the left wall, with the street door's hole (and the window's)
      final holes = <List<num>>[
        [PD0, PD1, 0, DH],
      ];
      if (o.vitrina) holes.add(const [VW0, VW1, VZ0, VZ1]);
      for (num bb = bLo; bb <= bHi; bb += ST) {
        final hs = holes.where((h) => bb > h[0] && bb < h[1]).toList();
        for (num z = 0; z <= WH; z += ST) {
          if (hs.any((h) => z > h[2] && z < h[3])) continue;
          e.plot(
            0,
            bb,
            z,
            b.shade(
              z <= .9 ? DADO : WALL,
              z <= .9 ? (z > .84 ? .6 : 1.3) : 1.3,
              bb,
              z,
            ),
          );
        }
      }
    });
    k.part('puerta_atras', () {
      if (o.atras == 'open') storeRoom();
      k.reveal(0, BD0, BD1, 0, DH, .2, WALL);
      final F = e.rampOf(WOOD_L), Wd = e.rampOf(WOOD);
      const w = BD1 - BD0;
      for (num z = 0; z <= DH + .12; z += ST * .5) {
        for (num a = 0; a <= .12; a += ST * .5) {
          e.plot(BD0 - .12 + a, .03, z, F[2]);
          e.plot(BD1 + a, .03, z, F[2]);
        }
      }
      for (num a = BD0 - .12; a <= BD1 + .12; a += ST * .5) {
        for (num z = DH; z <= DH + .12; z += ST * .5) {
          e.plot(a, .03, z, F[3]);
        }
      }
      int panel(num t, num z) {
        final u = t * w,
            edge = u < .08 || u > w - .08 || z < .08 || z > DH - .08;
        return Wd[edge ? 1 : ((z - 1.25).abs() < .05 ? 1 : 2)];
      }

      if (o.atras == 'open') {
        k.leaf(BD1, -.05, w, 0, DH, math.pi + 1.3, (t, z) => panel(t, z));
      } else {
        k.paneY(-.05, BD0, BD1, 0, DH, (a, z) => panel((BD1 - a) / w, z));
      }
    });
    k.part('puerta', () {
      // the street, through the door: a plane outside the left wall
      final tarde = o.hora == 'tarde';
      final sky = tarde
          ? const [
              [250, 176, 96],
              [252, 200, 120],
              [254, 224, 160],
            ]
          : const [
              [120, 186, 250],
              [162, 211, 255],
              [208, 234, 255],
            ];
      paneX(-.5, PD0 - .5, PD1 + .1, 0, DH + .2, (bb, z) {
        if (z < 1.0) {
          return rgbOf(
            tarde ? const [214, 150, 110] : const [186, 200, 196],
          ); // the house across the street
        }
        if (z < 1.12) {
          return rgbOf(
            tarde ? const [176, 92, 70] : const [176, 96, 80],
          ); // its eaves
        }
        return rgbOf(sky[e.clamp(((z - 1.12) / 1.5 * 3).floor(), 0, 2)]);
      });
      for (num a = -.5; a <= 0; a += ST) {
        for (num bb = PD0 - .5; bb <= PD1 + .1; bb += ST) {
          e.plot(
            a,
            bb,
            0,
            rgbOf(tarde ? const [206, 178, 150] : const [190, 186, 176]),
          ); // the pavement
        }
      }
      final F = e.rampOf(WOOD_L);
      for (num z = 0; z <= DH + .12; z += ST * .5) {
        for (num bb = 0; bb <= .12; bb += ST * .5) {
          e.plot(.03, PD0 - .12 + bb, z, F[1]);
          e.plot(.03, PD1 + bb, z, F[1]);
        }
      }
      for (num bb = PD0 - .12; bb <= PD1 + .12; bb += ST * .5) {
        for (num z = DH; z <= DH + .12; z += ST * .5) {
          e.plot(.03, bb, z, F[2]);
        }
      }
      // the door leaf, open into the shop, back against the wall away from the corner (the window is on the corner
      // side), its free edge a little off the wall. The shop front's own door (colmado-fuera.js): a wooden frame, panels
      // below, a pane in the upper half with a light on it, a handle
      const w = PD1 - PD0;
      final R = e.rampOf(WOOD_L);
      const PANE = [
        [150, 200, 214],
        [176, 218, 232],
      ];
      const hx = .05, hy = PD1 + .14;
      k.leaf(hx, hy, w, 0, DH, math.pi / 2 - LEAF_TURN, (t, z) {
        final u = t * w; // from the hinge
        if (t > .985 || z < .03 || z > DH - .02) {
          return R[0]; // the leaf's edges: thick, in its own shadow
        }
        if (u < .1 || u > w - .1 || z < .1 || z > DH - .1) {
          return R[3]; // the frame: stiles and rails
        }
        final glass = u > .2 && u < w - .2 && z > 1.3 && z < DH - .25;
        if (glass) {
          final edge = u < .24 || u > w - .24 || z < 1.34 || z > DH - .29;
          if (edge) return R[1];
          final s = z + 1.15 * u; // diagonal lights
          if ((s > 2.5 && s < 2.66) || (s > 2.86 && s < 2.94)) {
            return e.rgb(244, 252, 255);
          }
          return rgbOf(PANE[z > 1.9 ? 1 : 0]);
        }
        if (z > 1.1 && z < 1.3) return R[3]; // the middle rail
        final inset =
            u > .2 && u < w - .2 && z > .22 && z < 1.1; // the panel below
        if (inset) {
          final ed = u < .25 || u > w - .25 || z < .27 || z > 1.05;
          return ed ? R[1] : R[2];
        }
        return R[3];
      });
      List<num> hp(num t, num z0, int c) {
        final q = [
          hx + math.cos(math.pi / 2 - LEAF_TURN) * w * t,
          hy + math.sin(math.pi / 2 - LEAF_TURN) * w * t,
        ];
        return [q[0] + .02, q[1], z0, c];
      }

      for (final h in [
        hp(.9, 1.15, e.rgb(250, 214, 96)),
        hp(.02, .4, e.rgb(120, 90, 40)),
        hp(.02, 2.05, e.rgb(120, 90, 40)),
      ]) {
        final x = h[0], y = h[1], z = h[2], c = h[3] as int;
        for (num da = -.04; da <= .04; da += ST * .4) {
          for (num dz = -.04; dz <= .04; dz += ST * .4) {
            if (da * da + dz * dz < .0016) {
              e.plot(
                x + .02 - da * math.sin(LEAF_TURN),
                y + da * math.cos(LEAF_TURN),
                z + dz,
                c,
              );
            }
          }
        }
      }
    });
    if (o.vitrina) {
      k.part('vitrina', () {
        final tarde = o.hora == 'tarde';
        paneX(
          -.5,
          VW0 - .5,
          VW1 + .1,
          0,
          DH + .2,
          (bb, z) => z < 1.0
              ? rgbOf(tarde ? const [214, 150, 110] : const [186, 200, 196])
              : rgbOf(tarde ? const [252, 200, 120] : const [162, 211, 255]),
        );
        final F = e.rampOf(WOOD_L);
        for (num bb = VW0 - .1; bb <= VW1 + .1; bb += ST * .5) {
          for (final z in const [VZ0 - .1, VZ1]) {
            for (num h = 0; h <= .1; h += ST * .5) {
              e.plot(.03, bb, z + h, F[2]);
            }
          }
        }
        for (num z = VZ0 - .1; z <= VZ1 + .1; z += ST * .5) {
          for (final bb in const [VW0 - .1, VW1, (VW0 + VW1) / 2 - .04]) {
            for (num h = 0; h <= .08; h += ST * .5) {
              e.plot(.03, bb + h, z, F[2]);
            }
          }
        }
        b.block(
          .03,
          VW0 + .05,
          VZ0 - .12,
          .3,
          VW1 - .05,
          VZ0 - .04,
          WOOD_L,
          TOP,
        ); // the sill inside: a shelf for what is shown in the window
      });
    }
    // a round wall clock above the pier between the window and the door, over everyone's head. Drawn as a picture of
    // one-pixel cells (13 x 13) on the pixel where the wall point (bc, zc) falls, so it is the same in every framing
    if (o.reloj) {
      k.part('reloj', () {
        const bc = (VW1 + .1 + PD0 - .12) / 2, zc = 2.95;
        final c0 = e.project(.08, bc, zc),
            cx = c0.sx.floor(),
            cy = c0.sy.floor();
        final RIM = e.rgb(62, 42, 34),
            FACE = e.rgb(252, 250, 244),
            INK = e.rgb(32, 26, 28);
        const hands = {'0,0', '-1,-1', '1,-1', '2,-1', '3,-2'},
            dots = {'0,-3', '3,0', '0,3', '-3,0'};
        pixelsX(.08, bc - .45, bc + .45, zc - .5, zc + .5, (bb, z) {
          final q = e.project(.08, bb, z),
              dx = q.sx.floor() - cx,
              dy = q.sy.floor() - cy,
              r = math.sqrt(dx * dx + dy * dy);
          if (r > 6.4) return 0;
          if (r > 4.4) return RIM;
          return hands.contains('$dx,$dy') || dots.contains('$dx,$dy')
              ? INK
              : FACE;
        });
      });
    }
    // a hanging bunch of plantains on the bare wall between the two runs of shelves: a nail, a stem, two tiers of fingers
    k.part('racimo', () {
      const x = XB, y = .1;
      const Dk = [78, 58, 40],
          greens = [
            [132, 184, 62],
            [168, 200, 76],
            [112, 164, 56],
          ],
          Ye = [238, 210, 84];
      e.sphere(x, .06, 2.9, .04, const [54, 46, 42], 'solid'); // the nail
      e.capsule(
        const [x, y - .03, 2.88],
        const [x, y - .01, 2.56],
        .018,
        .022,
        (_) => const [150, 118, 74],
        'solid',
      ); // the cord
      e.capsule(
        const [x, y, 2.56],
        const [x, y + .03, 2.3],
        .045,
        .055,
        (_) => const [104, 92, 52],
        'solid',
      ); // the stem
      // two hands of fingers, hanging, each bowed outward and curling back in at the tip
      const tiers = <(double, int, double, double, double)>[
        (2.5, 3, .22, .56, 0),
        (2.36, 4, .2, .52, .04),
      ];
      for (var t = 0; t < tiers.length; t++) {
        final (z0, n, spread, len, dy) = tiers[t];
        for (var kk = 0; kk < n; kk++) {
          final s = (kk - (n - 1) / 2),
              c = (kk + t) % 5 == 2 ? Ye : greens[(kk + t) % 3];
          final a = [x + s * .025, y + .03 + dy, z0],
              m = [x + s * spread, y + .08 + dy, z0 - len * .5],
              en = [x + s * spread * .8, y + .1 + dy, z0 - len];
          e.capsule(a, m, .05, .06, (_) => c, 'solid');
          e.capsule(m, en, .06, .042, (_) => c, 'solid');
          e.sphere(en[0], en[1], en[2] - .02, .026, Dk, 'solid');
        }
      }
    });
  }

  // colmado-dentro.js: counter
  void counter(CdOpt o) {
    k.part('mostrador', () {
      b.block(CX0, CY0, 0, CX1, CY1, CH - .07, WOOD);
      b.block(CX0 - .06, CY0 - .06, CH - .07, CX1 + .06, CY1 + .08, CH, TOP);
      // boards on its front, a darker foot
      for (num a = CX0; a <= CX1; a += ST * .7) {
        for (num z = 0; z <= CH - .08; z += ST * .7) {
          final seam = ((a - CX0) % .5) < .04;
          if (seam || z < .1) {
            e.plot(a, CY1 + .01, z, e.rampOf(WOOD)[z < .1 ? 0 : 1]);
          }
        }
      }
    });
    // the chest freezer: a white body with a blue snowflake and a vent grille on its front, a metal frame round a sliding
    // glass lid (two clear light-blue panes, each with a white diagonal reflection)
    if (o.nevera) {
      k.part('nevera', () {
        final x0 = NV.x0, x1 = NV.x1, y0 = NV.y0, y1 = NV.y1, h = NV.h;
        const z0 = CH;
        final z1 = CH + h, zt = z1 + .05, xm = (x0 + x1) / 2;
        const METAL = [158, 166, 178];
        b.block(
          x0,
          y0,
          z0,
          x1,
          y1,
          z1,
          const [238, 242, 248],
          const [226, 236, 244],
        );
        k.paneY(
          y1 + .005,
          x0,
          x1,
          z0,
          z1,
          (_, _) => e.rgb(250, 252, 255),
        ); // the white front
        for (num bb = y0; bb <= y1; bb += ST * .5) {
          for (num z = z0; z <= z1; z += ST * .5) {
            e.plot(x1 + .005, bb, z, e.rgb(200, 210, 224));
          }
        } // and its side, in shade but still white
        b.block(x0 - .03, y0 - .03, z1, x1 + .03, y1 + .03, zt, METAL, const [
          176,
          184,
          196,
        ]); // the lid's frame
        for (num a = x0 + .02; a <= x1 - .02; a += ST * .6) {
          for (num bb = y0 + .02; bb <= y1 - .02; bb += ST * .6) {
            final ex = math.min(a - x0, x1 - a),
                ey = math.min(bb - y0, y1 - bb);
            int c;
            if (ex < .07 || ey < .07 || (a - xm).abs() < .022) {
              c = rgbOf(METAL); // the frame, and the rail between the two panes
            } else {
              final p = 3 * (a - x0) - (bb - y0), kk = (bb - y0) / (y1 - y0); // lines that run up and to the right on the screen
              if ((p > .46 && p < .8) || (p > 1.86 && p < 2.2)) {
                c = e.rgb(
                  255,
                  255,
                  255,
                ); // the two white reflections, one on each pane
              } else {
                c = e.rgb(
                  176 - 58 * kk,
                  224 - 40 * kk,
                  250 - 12 * kk,
                ); // a clear light blue, paler at the back
              }
            }
            e.plot(a, bb, zt + .004, c);
          }
        }
        const flake = [
              '...#...',
              '#..#..#',
              '.#.#.#.',
              '#######',
              '.#.#.#.',
              '#..#..#',
              '...#...',
            ],
            grille = [
              '######',
              '......',
              '######',
              '......',
              '######',
              '......',
              '######',
            ];
        stampY(y1 + .03, x0 + .27, z0 + h / 2, flake, {
          '#': e.rgb(36, 104, 214),
        });
        stampY(y1 + .03, x1 - .26, z0 + h / 2, grille, {
          '#': e.rgb(92, 106, 126),
        });
      });
    }
    // the old cash register: a dark body, a raised head with a pale amount window and a brass cap and bell, rows of round
    // keys, a drawer front with a handle, and a small shelf on its right side where the frog sits
    if (o.caja) {
      k.part('caja', () {
        final x0 = RG.x0,
            x1 = RG.x1,
            y0 = RG.y0,
            y1 = RG.y1,
            bodyH = RG.bodyH,
            headY = RG.headY,
            headH = RG.headH;
        const z0 = CH;
        final zk = z0 + bodyH, zh = zk + headH;
        const BODY = [58, 62, 76],
            HEAD = [74, 80, 98],
            BRASS = [232, 190, 80],
            BRASS_L = [252, 222, 120];
        b.block(x0, y0, z0, x1, y1, zk, BODY, const [92, 98, 116]); // the body
        b.block(x0 + .08, y0, zk, x1 - .08, headY, zh, HEAD, const [
          104,
          110,
          130,
        ]); // the head, set back and raised
        b.block(
          x0 + .1,
          y0 - .02,
          zh,
          x1 - .1,
          headY + .03,
          zh + .04,
          BRASS,
          const [240, 206, 108],
        ); // its brass cap
        k.paneY(
          headY + .006,
          RGM - .26,
          RGM + .26,
          zk + .27,
          zk + .5,
          (a, z) => ((a - RGM).abs() > .235 || z < zk + .295 || z > zk + .475)
              ? e.rgb(22, 24, 30)
              : e.rgb(226, 242, 212),
        ); // the amount window (numerals are sprites)
        k.paneY(
          headY + .006,
          x0 + .1,
          x1 - .1,
          zk + .1,
          zk + .14,
          (_, _) => rgbOf(BRASS),
        );
        for (var r = 0; r < 3; r++) {
          for (var kk = 0; kk < 5; kk++) {
            // rows of round keys on the body's top
            final cx = x0 + .2 + kk * .17, cy = headY + .1 + r * .13;
            k.drum(
              cx,
              cy,
              zk,
              zk + .035,
              .034,
              kk == 4 ? const [232, 190, 80] : const [238, 232, 216],
              (a, bb) => (a < 0 && bb < 0) ? e.rgb(255, 255, 250) : 0,
            );
          }
        }
        e.sphere(RGM, y0 + .14, zh + .13, .09, BRASS, 'solid'); // the bell
        e.sphere(RGM, y0 + .14, zh + .23, .03, const [60, 50, 40], 'solid');
        // the drawer front, with its handle
        k.paneY(y1 + .006, x0 + .06, x1 - .06, z0 + .04, zk - .03, (a, z) {
          final ed = math.min(
            math.min(a - x0 - .06, x1 - .06 - a),
            math.min(z - z0 - .04, zk - .03 - z),
          );
          if (ed < .02) return e.rgb(26, 28, 36);
          if ((a - RGM).abs() < .17 &&
              z > z0 + bodyH / 2 - .035 &&
              z < z0 + bodyH / 2 + .02) {
            return rgbOf(z > z0 + bodyH / 2 ? BRASS_L : BRASS);
          }
          return e.rgb(104, 110, 128);
        });
        // the side shelf: a board and two braces to the register's side
        final sx0 = SHELF.x0,
            sx1 = SHELF.x1,
            sy0 = SHELF.y0,
            sy1 = SHELF.y1,
            sz = SHELF.z;
        b.block(sx0, sy0, sz - .05, sx1, sy1, sz, WOOD, TOP);
        for (final bb in [sy0 + .04, sy1 - .04]) {
          for (num t = 0; t <= 1; t += ST * .4) {
            for (num d = 0; d < .04; d += ST * .5) {
              e.plot(
                sx0 + (1 - t) * .01 + t * (sx1 - sx0 - .03),
                bb,
                sz - .05 - (1 - t) * .16 - d,
                rgbOf(WOOD),
              );
            }
          }
        }
      });
    }
  }

  // colmado-dentro.js: shelves
  void shelves(CdOpt o) {
    k.part('estantes', () {
      for (final x in const [SX0, SXM, SX1]) {
        b.block(x - .05, .02, 0, x + .05, SD, WH - .25, WOOD);
      }
      for (final z in SZ) {
        b.block(SX0, .02, z, SX1, SD, z + .06, WOOD_L, TOP);
      }
      b.block(
        SX0,
        .02,
        0,
        SX1,
        SD + .04,
        .5,
        WOOD,
      ); // a low cupboard under them
    });
    // stock that never moves: the top shelf, and the right half of the others
    k.part('surtido', () {
      final z2 = SZ[2] + .06, z1 = SZ[1] + .06, z0 = SZ[0] + .06;
      const cans = [
        [204, 60, 50],
        [70, 130, 190],
        [236, 190, 70],
        [90, 160, 96],
      ];
      for (var kk = 0; kk < 16; kk++) {
        final x = SX0 + .3 + kk * .41;
        if (x > SX1 - .2) break;
        if ((x - SXM).abs() < .2) continue;
        k.drum(x, .2, z2, z2 + .3, .13, cans[kk % 4]);
      }
      for (var kk = 0; kk < 5; kk++) {
        final x = SXM + .3 + kk * .42;
        if (x > SX1 - .2) break;
        b.block(
          x - .15,
          .06,
          z1,
          x + .15,
          .3,
          z1 + .36 + (kk % 2) * .08,
          const [
            [226, 150, 80],
            [150, 110, 170],
            [240, 232, 210],
          ][kk % 3],
        );
      }
      for (var kk = 0; kk < 5; kk++) {
        final x = SXM + .3 + kk * .42;
        if (x > SX1 - .2) break;
        k.drum(
          x,
          .2,
          z0,
          z0 + .42,
          .1,
          const [
            [60, 110, 70],
            [120, 70, 40],
            [60, 110, 70],
          ][kk % 3],
        );
        e.sphere(x, .2, z0 + .47, .05, const [200, 200, 190], 'solid');
      }
    });
    if (o.props) {
      k.part('generos', () {
        for (final g in GOODS) {
          standIn(g.k, g.x, .19, SZ[g.s] + .06);
        }
      });
    }
    k.part('estantes2', () {
      for (final x in const [E2X0, E2X1]) {
        b.block(x - .05, .02, 0, x + .05, SD, WH - .25, WOOD);
      }
      for (final z in SZ) {
        b.block(E2X0, .02, z, E2X1, SD, z + .06, WOOD_L, TOP);
      }
      b.block(E2X0, .02, 0, E2X1, SD + .04, .5, WOOD);
      final z0 = SZ[0] + .06; // the low shelf: sacks and boxes that never move
      for (var kk = 0; kk < 8; kk++) {
        final x = E2X0 + .4 + kk * .47;
        b.block(
          x - .17,
          .06,
          z0,
          x + .17,
          .3,
          z0 + .3 + (kk % 3) * .06,
          const [
            [226, 150, 80],
            [240, 232, 210],
            [150, 110, 170],
            [110, 160, 200],
          ][kk % 4],
        );
      }
    });
    // story 39: three small rings (7 px wide) and three large (10 px), on the middle shelf's top: dark ovals one pixel
    // wide, so they read as rings at 1x. The ladder stands in front of the shelf's middle: one small ring shows between
    // its rails, the other five are clear of it
    if (o.anillos) {
      k.part('anillos', () {
        final z = SZ[1] + .06 + .004, ring = e.rgb(136, 104, 72);
        const cy = (.02 + SD) / 2;
        for (final rr in const <(double, double, double)>[
          (.42, .16, .105),
          (.98, .16, .105),
          (1.58, .16, .105),
          (2.4, .22, .145),
          (3.0, .22, .145),
          (3.6, .22, .145),
        ]) {
          final (dx, rx, ry) = rr;
          final cx = E2X0 + dx;
          for (num a = cx - rx - .02; a <= cx + rx + .02; a += ST * .5) {
            for (num bb = cy - ry - .02; bb <= cy + ry + .02; bb += ST * .5) {
              final ax = (a - cx) / rx, by = (bb - cy) / ry;
              final q = math.sqrt(ax * ax + by * by);
              if (q <= 1 && q > .62) e.plot(a, bb, z, ring);
            }
          }
        }
      });
    }
    // the ladder: two rails 3 px thick and seven rungs 2 px thick, drawn pixel by pixel so nothing has gaps; it leans on
    // the top plank's edge
    if (o.escalera) {
      k.part('escalera', () {
        final dpx = 1 / (2 * PX); // a world step that moves a point one screen pixel sideways
        final RAIL = [
              e.rgb(236, 198, 132),
              e.rgb(196, 150, 88),
              e.rgb(126, 86, 50),
            ],
            RUNG = [e.rgb(240, 206, 140), e.rgb(150, 104, 62)];
        const n = 700;
        for (final side in const [-1, 1]) {
          for (var kk = 0; kk <= n; kk++) {
            final z = LTOP * kk / n, y = ladderY(z);
            for (var q = -1; q <= 1; q++) {
              e.plot(LX + side * LW + q * dpx, y - q * dpx, z, RAIL[q + 1]);
            }
          }
        }
        for (var r = 1; r <= 7; r++) {
          final z = LTOP * r / 8, y = ladderY(z);
          for (num a = LX - LW; a <= LX + LW; a += .008) {
            for (var q = 0; q < 2; q++) {
              e.plot(a, y + .01, z - q * .0445, RUNG[q]);
            }
          }
        }
        for (final side in const [-1, 1]) {
          e.castShadow(LX + side * LW, LY0 + .03, .02, .13, 1, .15);
          e.castShadow(LX + side * LW + .1, LY0, .02, .1, 1, .15);
        }
      });
    }
    // the low table: a cloth over a top on four legs, the floor showing between them
    if (o.mesa) {
      k.part('mesa', () {
        final x = MESA[0], y = MESA[1];
        final x0 = x - .8, x1 = x + .8, y0 = y - .45, y1 = y + .45;
        const zp = MESA_H - .08;
        const CLOTH = [246, 240, 224], BORDER = [168, 206, 222];
        for (final l in [
          [x0 + .08, y0 + .08],
          [x1 - .16, y0 + .08],
          [x0 + .08, y1 - .16],
          [x1 - .16, y1 - .16],
        ]) {
          b.block(
            l[0],
            l[1],
            0,
            l[0] + .09,
            l[1] + .09,
            zp,
            WOOD,
            WOOD_L,
          ); // the legs
        }
        b.block(x0, y0, zp - .05, x1, y1, zp, WOOD, TOP); // the top
        final cx0 = x0 - .05, cx1 = x1 + .05, cy0 = y0 - .05, cy1 = y1 + .05;
        const hang = .09;
        for (num a = cx0; a <= cx1; a += ST * .7) {
          for (num bb = cy0; bb <= cy1; bb += ST * .7) {
            // the cloth's top, with a pale blue border
            final ed = math.min(
              math.min(a - cx0, cx1 - a),
              math.min(bb - cy0, cy1 - bb),
            );
            e.plot(
              a,
              bb,
              MESA_H,
              ed > .06 && ed < .1 ? rgbOf(BORDER) : b.shade(CLOTH, 3.4, a, bb),
            );
          }
        }
        for (num a = cx0; a <= cx1; a += ST * .7) {
          for (num z = MESA_H - hang; z <= MESA_H; z += ST * .7) {
            e.plot(
              a,
              cy1,
              z,
              (z - (MESA_H - hang)) < .035
                  ? e.rampOf(BORDER)[2]
                  : b.shade(CLOTH, 2.2, a, z),
            ); // its front edge hanging
          }
        }
        for (num bb = cy0; bb <= cy1; bb += ST * .7) {
          for (num z = MESA_H - hang; z <= MESA_H; z += ST * .7) {
            e.plot(
              cx1,
              bb,
              z,
              (z - (MESA_H - hang)) < .035
                  ? e.rampOf(BORDER)[1]
                  : b.shade(CLOTH, 1.3, bb, z),
            ); // and its right edge
          }
        }
        e.castShadow(x + .15, y + .2, .15, .52, 1, .5);
      });
    }
  }

  // colmado-dentro.js: standIn. A stand-in for one of the nine things that are bought: the size and the colours its sprite
  // has
  void standIn(String kk, num x, num y, num z) {
    void B(num hw, num h, List<int> c, [List<int>? top]) =>
        b.block(x - hw, y - .12, z, x + hw, y + .12, z + h, c, top ?? c);
    void stripe(num hw, num z0, num z1, List<int> c) =>
        k.paneY(y + .125, x - hw, x + hw, z + z0, z + z1, (_, _) => rgbOf(c));
    if (kk == 'leche') {
      B(.15, .46, const [244, 246, 250]);
      stripe(.15, .14, .28, const [70, 120, 210]);
    } else if (kk == 'pan') {
      B(.26, .2, const [196, 132, 64], const [226, 170, 96]);
    } else if (kk == 'mantequilla') {
      B(.22, .13, const [250, 222, 96], const [255, 236, 140]);
      stripe(.22, 0, .05, const [240, 240, 232]);
    } else if (kk == 'queso') {
      B(.2, .26, const [246, 176, 60], const [252, 200, 90]);
      e.sphere(x - .05, y + .13, z + .15, .04, const [214, 140, 40], 'solid');
    } else if (kk == 'cafe') {
      B(.15, .42, const [150, 40, 40]);
      stripe(.15, .16, .26, const [240, 200, 90]);
    } else if (kk == 'arroz') {
      B(.19, .4, const [240, 236, 222]);
      stripe(.19, .1, .22, const [70, 150, 90]);
    } else if (kk == 'azucar') {
      B(.17, .38, const [150, 200, 240]);
      stripe(.17, .12, .24, const [250, 250, 250]);
    } else if (kk == 'jugo') {
      B(.14, .46, const [246, 150, 40]);
      stripe(.14, .3, .4, const [250, 240, 200]);
    } else if (kk == 'habichuelas') {
      k.drum(x, y, z, z + .32, .15, const [190, 50, 50]);
      k.paneY(
        y + .155,
        x - .1,
        x + .1,
        z + .1,
        z + .22,
        (_, _) => e.rgb(250, 236, 200),
      );
    }
  }

  // colmado-dentro.js: light
  void light(CdOpt o) {
    // the contact shadow bakeOcclusion dithers along the walls' feet and the door sills read as a dotted fringe along the
    // floor's edge: take it off again, so the floor meets a wall in a clean line. Round the counter, the chair and the
    // cupboards the contact shadow stays
    bool inRun(num x) =>
        (x > SX0 - .2 && x < SX1 + .2) || (x > E2X0 - .2 && x < E2X1 + .2);
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix;
        if (e.ground[i] == 0 || e.zb[i] != e.groundZ[i]) continue;
        final g = e.unproject(ix + .5, iy + .5);
        if (g.x < .45 || (g.y < .4 && !inRun(g.x))) {
          final c = floorAt(g.x, g.y, ix, iy, i);
          if (c != 0) e.pix[i] = c;
        }
      }
    }
    // the sun through the street door: a lighter patch on the floor (longer and warmer in the afternoon)
    final tarde = o.hora == 'tarde', len = tarde ? 3.4 : 1.8;
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix;
        if (e.ground[i] == 0 || e.zb[i] != e.groundZ[i]) continue;
        final g = e.unproject(ix + .5, iy + .5), t = g.x / len;
        if (g.x < .02 || t > 1 || g.y < PD0 + t * .5 || g.y > PD1 + t * 1.2) {
          continue;
        }
        final c = e.pix[i],
            r = c & 255,
            gg = (c >> 8) & 255,
            bb = (c >> 16) & 255;
        final kk = tarde ? const [1.1, 1.02, .86] : const [1.08, 1.07, 1.0];
        e.pix[i] = e.rgb(
          math.min(255, r * kk[0] + 8),
          math.min(255, gg * kk[1] + 6),
          math.min(255, bb * kk[2]),
        );
      }
    }
  }

  // colmado-dentro.js: chairs
  void chairs() {
    // the waiting chair, turned to the camera (as El balcón's small chair)
    k.part('silla', () {
      final x = SILLA[0], y = SILLA[1];
      const TURN = -math.pi / 4, hw = .4, hd = .28, Y = [226, 190, 96];
      List<num> at(num s, num u) => [
        x + math.cos(TURN) * s - math.sin(TURN) * u,
        y + math.sin(TURN) * s + math.cos(TURN) * u,
      ];
      void leg(num s, num u, num z1) {
        final q = at(s, u);
        k.turnedBox(q[0], q[1], 0, z1, .05, .05, TURN, Y);
      }

      leg(-hw + .05, hd - .05, .44);
      leg(hw - .05, hd - .05, .44);
      leg(-hw + .05, -hd + .05, 1.0);
      leg(hw - .05, -hd + .05, 1.0);
      k.turnedBox(x, y, .38, .45, hw, hd, TURN, Y);
      for (final z in const [.62, .86]) {
        final q = at(0, -hd + .05);
        k.turnedBox(q[0], q[1], z, z + .08, hw, .04, TURN, Y);
      }
    });
  }

  // colmado-dentro.js: build
  void build(CdOpt o) {
    walls(o);
    shelves(o);
    counter(o);
    chairs();
    // castShadow((CX0 + CX1) / 2, CY1 + .1, .5, .5, .5) and, along the counter, castShadow(x, CY1 - .1, .6, .45, .6):
    // their strength (the fifth number) is under 1, and pp-engine.js stores it into the Uint8Array shadowMask, where it
    // becomes 0: these calls change no pixel. They are kept, with the same rule (castShadowJs).
    castShadowJs(e, (CX0 + CX1) / 2, CY1 + .1, .5, .5, .5);
    for (num x = CX0 + .4; x <= CX1 - .2; x += .5) {
      castShadowJs(e, x, CY1 - .1, .6, .45, .6);
    }
  }
}

/// pp-engine.js: castShadow with any strength, as the JavaScript runs it: `if (shadowMask[i] < strength) shadowMask[i] =
/// strength` on a Uint8Array, so a strength that is not a whole number is stored cut to one (`.5` stores 0: nothing
/// changes, since the test `mask < .5` only passes where the mask is already 0). A whole strength is the engine's own
/// castShadow.
void castShadowJs(
  PpEngine e,
  num x,
  num y,
  num z,
  num r, [
  num strength = 1,
  double dither = .4,
]) {
  if (strength == strength.truncate()) {
    e.castShadow(x, y, z, r, strength.toInt(), dither);
    return;
  }
  final p = e.project(x + e.SHADOW_X * z, y + e.SHADOW_Y * z, 0);
  final rx = r * e.S * 1.05, ry = rx * e.SIN + 1;
  final y0 = math.max(0, (p.sy - ry).floor()),
      y1 = math.min(e.H - 1, (p.sy + ry).ceil());
  final x0 = math.max(0, (p.sx - rx).floor()),
      x1 = math.min(e.W - 1, (p.sx + rx).ceil());
  final stored = strength.truncate().clamp(0, 255);
  for (var iy = y0; iy <= y1; iy++) {
    for (var ix = x0; ix <= x1; ix++) {
      final dx = (ix + .5 - p.sx) / rx, dy = (iy + .5 - p.sy) / ry;
      if (dx * dx + dy * dy + (e.bayerAt(ix, iy) - .5) * dither > 1) continue;
      final i = iy * e.W + ix;
      if (e.shadowMask[i] < strength) e.shadowMask[i] = stored;
    }
  }
}
