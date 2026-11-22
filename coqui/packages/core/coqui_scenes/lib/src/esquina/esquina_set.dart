// Port of docs/proyecto/pixel/esquina-set.html: La esquina's set, its states, call for call (order 54b). The pieces are
// La calle's kit (lib/src/calle/calle_base.dart). The page's names are kept, capitals included (page 12, section 6): the
// lints on names are off in this file.
//
// The page's `autos=` (cars and guaguas baked into the set, for the readers' renders) is not a state of the game: there
// they are sprites (calle_vehicles.dart) and the baked states have none (the sheet's setKey.params.autos).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart' show castShadowJs;
import 'package:coqui_scenes/src/set_kit.dart';

/// esquina-set.html: ORIGIN.
const List<double> ORIGIN = [30, -8];

/// The engine La esquina's set is built on (`window.PP_SCENE`): 240 x 216, S 26, origin (30, -8), shadows (.9, -.1).
PpEngine esquinaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (esquina-set.html: `SET`, from the address): `hora` manana or tarde, `obra` (the dug-up far lane
/// and the two squares of cement), `puerta` (the colmado's door). [autos] is the page's (readers' renders); the game
/// never sets it.
class EsquinaState {
  const EsquinaState({
    this.hora = 'manana',
    this.obra = false,
    this.puerta = 'shut',
    this.autos = '',
  });

  /// esquina-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory EsquinaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return EsquinaState(
      hora: pick('hora', const ['manana', 'tarde'], 'manana'),
      obra: q['obra'] == '1',
      puerta: pick('puerta', const ['shut', 'open'], 'shut'),
      autos: q['autos'] ?? '',
    );
  }

  /// A key of the sheet's `setKey` ("hora + obra + puerta", e.g. "manana-0-shut") read back.
  factory EsquinaState.fromKey(String key) {
    final m = RegExp(r'^(manana|tarde)-([01])-(shut|open)$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La esquina's set");
    }
    return EsquinaState(hora: m[1]!, obra: m[2] == '1', puerta: m[3]!);
  }

  final String hora, puerta, autos;
  final bool obra;

  /// The sheet's key.
  String get key => '$hora-${obra ? 1 : 0}-$puerta';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&obra=${obra ? 1 : 0}&puerta=$puerta';
}

/// esquina-set.html: E, the set's numbers.
abstract final class E {
  static const double WH = 3.5, P = 1.6, K = .2, S0 = 1.8, S1 = 5.8;
  static const double B0 = 1.8, B1 = 4.4;
  static const double D0 = -2.5, D1 = -1.2, DH = 2.55;
  static const List<double> WIN = [-6.3, -4.3, .95, 2.2];
  static const List<double> ZEBRA = [.2, 1.5];
  static const List<double> POLE = [1.66, 1.5];
  static const double LANE1 = 2.8, LANE2 = 4.8;
  static const double STOP = 2.2;
  static const List<double> OBRA = [.4, 2.8];
  static const List<double> WET = [1.2, 6.15, 2.2, 7.05],
      DRY = [-.1, 6.15, .9, 7.05];
}

/// esquina-set.html: the afternoon's light (`lightPass([1.0, .93, .84], [10, 2, -8])`), which the vehicles' sprites
/// take too.
const List<double> TARDE_M = [1.0, .93, .84], TARDE_A = [10, 2, -8];

const List<int> STONE = [196, 186, 168];

/// esquina-set.html's buildSet on an engine [e] with the page's origin.
class EsquinaSet {
  EsquinaSet(this.e, this.b) : k = SetKit(e, b) {
    cl = CalleBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CalleBase cl;

  /// The places trafficLight gave back at the last bake (esquina-set.html: E.LUZ).
  CalleLight? LUZ;

  /// Record which part drew each pixel at the next bakes (esquina-set.html `?tags=1`).
  bool tags = false;

  /// The pixels each part drew last at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  double _hyp(num a, num b) => math.sqrt(a * a + b * b);

  // esquina-set.html: groundAt
  int groundAt(EsquinaState SET, num x, num y, int ix, int iy) {
    final inA = y >= E.S0 && y <= E.S1,
        inB = x >= E.B0 && x <= E.B1 && y < E.S0;
    if (inA || inB) {
      if (SET.obra && inA && y <= 3.8 && x >= E.OBRA[0] && x <= E.OBRA[1]) {
        // the hole: earth, darker at its edges, stones; a hole with depth: its far walls in the dark, its near rim lit
        final n = e.noise(x * 3, y * 3),
            rim = y > 3.66 || x > E.OBRA[1] - .14,
            deep = y < E.S0 + .5 || x < E.OBRA[0] + .5;
        return rim
            ? e.rgb(196, 170, 130)
            : deep
            ? e.rgb(52, 42, 40)
            : cl.rgbOf(
                e.hash(ix, iy) < .06
                    ? const [150, 140, 128]
                    : n > .62
                    ? const [136, 100, 70]
                    : const [104, 76, 56],
              );
      }
      if (!SET.obra &&
          inA &&
          x >= E.ZEBRA[0] &&
          x <= E.ZEBRA[1] &&
          ((y - E.S0).remainder(.5)) < .28) {
        return cl.paint(CalleBase.WHITE); // the stripes
      }
      if (!SET.obra && inA && x >= E.STOP - .13 && x <= E.STOP) {
        return cl.paint(CalleBase.WHITE); // the stop line
      }
      if (inA &&
          (y - 3.8).abs() < .06 &&
          (x < -.2 || x > 2.2) &&
          ((x + 40).remainder(1.6)) < 1.0) {
        return cl.paint(CalleBase.LINE);
      }
      return cl.asphalt(ix, iy);
    }
    if ((y > E.P && y < E.S0) || (y > E.S1 && y < E.S1 + E.K)) {
      return cl.kerb();
    }
    if (y < E.P && ((x > E.P && x < E.B0) || (x > E.B1 && x < E.B1 + E.K))) {
      return cl.kerb();
    }
    if (y > 8.82) return cl.grass(x, y, ix, iy); // the park
    if (SET.obra && y > E.S1) {
      // the two squares of cement
      bool inq(List<double> q) =>
          x >= q[0] && x <= q[2] && y >= q[1] && y <= q[3];
      bool rim(List<double> q) =>
          x < q[0] + .06 || x > q[2] - .06 || y < q[1] + .06 || y > q[3] - .06;
      if (inq(E.WET)) {
        return rim(E.WET)
            ? e.rgb(150, 150, 156)
            : cl.rgbOf(
                e.hash(ix, iy) < .03
                    ? const [214, 214, 220]
                    : const [200, 200, 208],
              );
      }
      if (inq(E.DRY)) {
        if (rim(E.DRY)) return e.rgb(150, 144, 136);
        final u = x - E.DRY[0], v = y - E.DRY[1];
        final hand =
            _hyp(u - .3, v - .55) < .11 ||
            const [
              [.2, .36],
              [.27, .33],
              [.34, .33],
              [.41, .37],
              [.16, .5],
            ].any((f) => _hyp(u - f[0], v - f[1]) < .035);
        final paw =
            _hyp(u - .68, v - .42) < .08 ||
            const [
              [.6, .28],
              [.67, .25],
              [.74, .27],
              [.8, .32],
            ].any((f) => _hyp(u - f[0], v - f[1]) < .03);
        return (hand || paw) ? e.rgb(132, 126, 120) : e.rgb(178, 172, 164);
      }
    }
    return cl.slab(x, y, ix, iy);
  }

  // esquina-set.html: basket. The colmado's sign: a basket of fruit, as on its front in place 4
  int basket(num u, num v) {
    final dx = (u - .5) * 3.2, dy = v - .42;
    if (dy < 0 && dy > -.3 && dx.abs() < .62 + dy) return e.rgb(176, 124, 70);
    if (_hyp(dx + .3, dy - .12) < .2) return e.rgb(226, 60, 50);
    if (_hyp(dx - .05, dy - .2) < .2) return e.rgb(244, 200, 70);
    if (_hyp(dx - .36, dy - .1) < .18) return e.rgb(110, 170, 70);
    return 0;
  }

  // esquina-set.html: buildSet
  void buildSet(EsquinaState SET) {
    k.PART_TAGS = tags ? List<String?>.filled(e.W * e.H, null) : null;
    final W = e.W, H = e.H;
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
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = groundAt(SET, g.x, g.y, ix, iy);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('colmado', () {
      cl.top(
        -10,
        -9,
        0,
        0,
        E.WH,
        (a, bb) => cl.shade(CalleBase.SALMON, 3.4, a, bb),
      );
      cl.wallAlongX(0, -10, 0, E.WH, CalleBase.SALMON, CalleBase.TEAL, [
        [E.D0 - .12, E.D1 + .12, 0, E.DH + .12],
        [-2.95, -.75, 2.75, 3.42],
        [E.WIN[0] - .1, E.WIN[1] + .1, E.WIN[2] - .1, E.WIN[3] + .1],
      ]);
      cl.wallAlongY(0, -9, 0, E.WH, CalleBase.SALMON, CalleBase.TEAL);
      cl.signX(0, -2.95, -.75, 2.75, 3.42, basket);
    });
    k.part('puerta', () => cl.doorX(0, E.D0, E.D1, E.DH, SET.puerta == 'open'));
    k.part('vitrina', () {
      cl.windowX(0, E.WIN[0], E.WIN[1], E.WIN[2], E.WIN[3]);
      cl.awningX(0, E.WIN[0] - .3, E.WIN[1] + .3, 2.9, 2.6, .8);
    });
    k.part('semaforo', () {
      LUZ = cl.trafficLight(E.POLE[0], E.POLE[1]);
    });
    // the park's low wall, beyond the near pavement
    k.part('muro', () => cl.box(-9, 8.6, 0, 9, 8.82, .5, STONE));
    if (SET.obra) {
      k.part('obra', () {
        // a red and white board along the hole, on two feet
        cl.faceY(
          4.0,
          E.OBRA[0] - .1,
          E.OBRA[1] + .1,
          .5,
          .86,
          (a, z) => (((a + 40) / .3).floor().remainder(2)) != 0
              ? e.rgb(226, 50, 44)
              : e.rgb(252, 252, 250),
        );
        for (final x in [E.OBRA[0], E.OBRA[1]]) {
          cl.box(x - .05, 3.94, 0, x + .05, 4.04, .5, const [70, 74, 84]);
        }
        for (num x = E.OBRA[0] + .3; x <= E.OBRA[1]; x += .9) {
          cl.cone(x, 4.25);
        }
        // a spade standing in the earth
        cl.box(1.55, 2.6, 0, 1.6, 2.65, 1.0, const [150, 104, 62]);
        cl.box(1.48, 2.58, 1.0, 1.67, 2.67, 1.08, const [150, 104, 62]);
        cl.box(1.5, 2.6, .0, 1.65, 2.66, .22, const [120, 124, 134]);
        cl.cone(E.OBRA[0] - .3, 2.3);
        cl.cone(E.OBRA[0] - .3, 3.3);
        cl.cone(E.OBRA[1] + .3, 2.3);
        cl.cone(E.OBRA[1] + .3, 3.3);
        // heaps of earth and stones
        for (final h in const [
          [1.0, 2.5, .26],
          [2.1, 3.0, .3],
        ]) {
          final x = h[0], y = h[1], r = h[2];
          e.sphere(x, y, .05, r, const [124, 92, 66], 'rough');
          e.sphere(x + .25, y + .1, .02, r * .7, const [
            150,
            140,
            128,
          ], 'rough');
        }
      });
    }
    for (final a in SET.autos.split(';').where((s) => s.isNotEmpty)) {
      final kr = a.split('@'), r = kr[1].split(',');
      k.part(
        'auto',
        () => cl.vehicle(
          kr[0],
          double.parse(r[0]),
          double.parse(r[1]),
          r.length > 2 && r[2].isNotEmpty ? r[2] : 'i',
        ),
      );
    }
    for (num a = E.WIN[0]; a <= E.WIN[1]; a += .4) {
      castShadowJs(e, a, .4, 2.6, .4, .6);
    }
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    if (SET.hora == 'tarde') k.lightPass(TARDE_M, TARDE_A);
    k.skyFill((_, _) => e.rgb(150, 200, 252));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // esquina-set.html: frame (what the reference made: the bake at wind time 0, no casts)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
