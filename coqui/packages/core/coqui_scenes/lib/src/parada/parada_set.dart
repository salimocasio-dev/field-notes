// Port of docs/proyecto/pixel/parada-set.html: La parada's set, its states, call for call (order 55b). The pieces are
// La calle's kit (lib/src/calle/calle_base.dart). The page's names are kept, capitals included (page 12, section 6): the
// lints on names are off in this file.
//
// The page's `autos=` (guaguas baked into the set, for the readers' renders) is not a state of the game: there they are
// sprites (calle_vehicles.dart) and the baked states have none (the sheet's setKey.params.autos).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// parada-set.html: ORIGIN.
const List<double> ORIGIN = [70, -16];

/// The hours of the set (parada-set.html: `pick('hora', ...)`).
const List<String> PARADA_HORAS = ['temprano', 'manana', 'tarde', 'noche'];

/// The engine La parada's set is built on (`window.PP_SCENE`): 240 x 216, S 26, origin (70, -16), shadows (.9, -.1).
PpEngine paradaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (parada-set.html: `SET`, from the address): `hora` temprano, manana, tarde or noche. [autos]
/// is the page's (readers' renders: `guagua@x,y,i,<board>` joined by `;`); the game never sets it.
class ParadaState {
  const ParadaState({this.hora = 'manana', this.autos = ''});

  /// parada-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory ParadaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return ParadaState(
      hora: h != null && PARADA_HORAS.contains(h) ? h : 'manana',
      autos: q['autos'] ?? '',
    );
  }

  /// A key of the sheet's `setKey` (the hora, e.g. "manana") read back.
  factory ParadaState.fromKey(String key) {
    if (!PARADA_HORAS.contains(key)) {
      throw ArgumentError.value(key, 'key', "not a key of La parada's set");
    }
    return ParadaState(hora: key);
  }

  final String hora, autos;

  /// The sheet's key.
  String get key => hora;

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora';
}

/// parada-set.html: E, the set's numbers.
abstract final class E {
  static const double HH = 2.8, FP = 1.4, S0 = 1.6, S1 = 5.6, NP = 5.8;
  static const double NP1 = 9.2;
  static const double LANE1 = 2.6, LANE2 = 4.6;
  static const double P1 = -1.9, P2 = 3.5;
  static const List<double> SIGN = [1.1, 6.0], SEAT = [1.4, 8.55, 4.2];
  static const List<double> POST = [.3, 9.0], LAMP = [.2, .9];
  static const List<double> PATH = [-.6, .5];
}

/// parada-set.html: the light of each hour after the shadows (`lightPass(m, a)`; manana has none), which the vehicles'
/// sprites take too.
const Map<String, (List<double>, List<double>)> PARADA_LIGHT = {
  'temprano': ([1.0, .95, .86], [8, 4, -4]),
  'tarde': ([1.0, .9, .8], [12, 0, -10]),
  'noche': ([.62, .62, .82], [-6, -4, 14]),
};

/// parada-set.html's buildSet on an engine [e] with the page's origin.
class ParadaSet {
  ParadaSet(this.e, this.b) : k = SetKit(e, b) {
    cl = CalleBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CalleBase cl;

  /// Record which part drew each pixel at the next bakes (parada-set.html `?tags=1`).
  bool tags = false;

  /// The pixels each part drew last at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  /// Where the lamp's pool of light is (parada-set.html: E.GLOW), at the last bake; null when the lamp is not lit.
  List<double>? GLOW;

  // parada-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    if (y < -4.2) return 0;
    if (y < 0) return cl.grass(x, y, ix, iy); // behind the houses: sky
    if (y >= E.S0 && y <= E.S1) {
      return ((y - 3.6).abs() < .06 && ((x + 40).remainder(1.6)) < 1.0)
          ? cl.paint(CalleBase.LINE)
          : cl.asphalt(ix, iy);
    }
    if ((y > E.FP && y < E.S0) || (y > E.S1 && y < E.NP)) return cl.kerb();
    if (y > E.NP1) {
      // grass, and the footpath of beaten earth that winds off across it
      final w = x - (E.PATH[0] + E.PATH[1]) / 2 - math.sin(y * 1.1) * .25;
      return w.abs() < .55
          ? cl.rgbOf(
              e.hash(ix, iy) < .12
                  ? const [176, 140, 100]
                  : w.abs() > .45
                  ? const [186, 160, 112]
                  : const [214, 186, 138],
            )
          : cl.grass(x, y, ix, iy);
    }
    if (y > E.NP && x > E.P1 - 2.2 && x < E.P1 + 2.2 && y < E.NP + .16) {
      return cl.paint(const [236, 196, 60]); // the stop's yellow kerb
    }
    return cl.slab(x, y, ix, iy);
  }

  double _hyp(num a, num b) => math.sqrt(a * a + b * b);

  // parada-set.html: busPic. The stop's sign: a guagua, side on
  int busPic(num u, num v) {
    if (v > .3 && v < .78 && u > .16 && u < .84) {
      return (v > .5 && v < .7 && ((u - .2).remainder(.2)) < .13)
          ? e.rgb(60, 80, 110)
          : e.rgb(250, 250, 250);
    }
    if (_hyp(u - .32, v - .26) < .09 || _hyp(u - .68, v - .26) < .09) {
      return e.rgb(40, 40, 50);
    }
    return 0;
  }

  // parada-set.html: walkPic. The post: a walking person
  int walkPic(num u, num v) {
    if (_hyp(u - .5, v - .8) < .1) return e.rgb(250, 250, 250);
    if ((u - .5).abs() < .07 && v > .42 && v < .7) return e.rgb(250, 250, 250);
    if (v <= .42 &&
        v > .12 &&
        (((u - .5).abs()) - (.42 - v) * .55).abs() < .06) {
      return e.rgb(250, 250, 250);
    }
    if (v > .5 && v < .62 && (u - .5).abs() < .24) return e.rgb(250, 250, 250);
    return 0;
  }

  // parada-set.html: buildSet
  void buildSet(ParadaState SET) {
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
    GLOW = null;
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    cl.NIGHT = SET.hora == 'noche';
    k.part('casas', () {
      cl.houseX(
        0,
        -13,
        -8.6,
        E.HH,
        const [250, 214, 120],
        const [206, 150, 70],
        -11.4,
        -10.0,
      );
      cl.houseX(
        0,
        -8.6,
        -4.2,
        E.HH + .3,
        const [150, 200, 214],
        const [86, 140, 160],
        -7.9,
        -6.4,
        const [120, 70, 50],
      );
      cl.houseX(
        0,
        -4.2,
        .2,
        E.HH,
        const [244, 170, 150],
        const [200, 110, 96],
        -1.6,
        -3.4,
      );
      cl.houseX(
        0,
        .2,
        4.6,
        E.HH + .2,
        const [196, 220, 150],
        const [120, 160, 90],
        .9,
        2.6,
        const [96, 70, 110],
      );
    });
    k.part('arbol', () => cl.tree(6.4, -1.6, 1.3, .9));
    k.part(
      'parada',
      () => cl.signPole(
        E.SIGN[0],
        E.SIGN[1],
        2.3,
        .62,
        .62,
        const [40, 110, 200],
        busPic,
      ),
    );
    k.part('asiento', () => cl.seat(E.SEAT[0], E.SEAT[1], E.SEAT[2]));
    k.part(
      'poste',
      () => cl.signPole(
        E.POST[0],
        E.POST[1],
        1.5,
        .5,
        .5,
        const [60, 150, 90],
        walkPic,
      ),
    );
    k.part('farol', () {
      final x = E.LAMP[0], y = E.LAMP[1], lit = SET.hora == 'noche';
      for (num z = 0; z <= 3.3; z += CalleBase.PZ) {
        for (num t = 0; t < 6.3; t += .5) {
          e.plot(
            x + math.cos(t) * .05,
            y + math.sin(t) * .05,
            z,
            b.shade(const [70, 74, 84], 1.2 + math.cos(t - .8) * 1.2, t, z),
          );
        }
      }
      cl.box(x - .16, y - .1, 3.3, x + .16, y + .5, 3.42, const [60, 64, 74]);
      if (lit) {
        // the lit lamp
        cl.box(
          x - .14,
          y + .08,
          3.16,
          x + .14,
          y + .46,
          3.3,
          const [255, 236, 150],
        );
      }
      if (lit) GLOW = [x, y + .6];
      for (num z = .15; z <= 3.2; z += .12) {
        e.castShadow(x, y, z, .06);
      }
    });
    for (final a in SET.autos.split(';').where((s) => s.isNotEmpty)) {
      final kr = a.split('@'), r = kr[1].split(',');
      k.part(
        'auto',
        () => cl.vehicle(
          kr[0],
          double.parse(r[0]),
          double.parse(r[1]),
          r.length > 2 && r[2].isNotEmpty ? r[2] : 'i',
          r.length > 3 && r[3].isNotEmpty ? r[3] : null,
        ),
      );
    }
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    cl.NIGHT = SET.hora == 'noche';
    final L = PARADA_LIGHT[SET.hora];
    if (L != null) k.lightPass(L.$1, L.$2);
    final glow = GLOW;
    if (glow != null) {
      // the lamp's pool of light: the ground under it gets back its day colours, fading out
      final p = e.project(glow[0], glow[1], 0);
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final i = iy * W + ix,
              d = _hyp((ix - p.sx) / 34, (iy - p.sy) / 17);
          if (d >= 1 || e.ground[i] == 0) continue;
          final kk = (1 - d) * .75 + (e.bayerAt(ix, iy) - .5) * .12,
              c = e.pix[i],
              r = c & 255,
              g = (c >> 8) & 255,
              bb = (c >> 16) & 255;
          e.pix[i] = e.rgb(
            math.min(255, r + 120 * kk),
            math.min(255, g + 100 * kk),
            math.min(255, bb + 20 * kk),
          );
        }
      }
    }
    k.skyFill(cl.sky(SET.hora, null));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // parada-set.html: frame (what the reference made: the bake at wind time 0, no casts)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
