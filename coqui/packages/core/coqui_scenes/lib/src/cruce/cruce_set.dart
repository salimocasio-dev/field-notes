// Port of docs/proyecto/pixel/cruce-set.html: El cruce's set, its states, call for call (order 57b). The pieces are La
// calle's kit (lib/src/calle/calle_base.dart) and set-kit's turnedBox. The page's names are kept, capitals included
// (page 12, section 6): the lints on names are off in this file.
//
// The streets are turned 45 degrees to the engine's axes: u runs across the picture (to the right), v down it (towards
// the camera); x = (u + v) / R2, y = (v - u) / R2 (E.xy), and back (E.uv). The crossing's middle is u = 0, v = 0.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// cruce-set.html: ORIGIN.
const List<double> ORIGIN = [-24, 10];

/// The engine El cruce's set is built on (`window.PP_SCENE`): 240 x 216, S 26, origin (-24, 10), shadows (.9, -.1).
PpEngine cruceEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (cruce-set.html: `SET`, from the address): `hora` mediodia, tarde or ocaso; `cerrada` (the
/// barrier and the cones across the street to the right, story 58).
class CruceState {
  const CruceState({this.hora = 'mediodia', this.cerrada = false});

  /// cruce-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory CruceState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return CruceState(
      hora: h != null && const ['mediodia', 'tarde', 'ocaso'].contains(h)
          ? h
          : 'mediodia',
      cerrada: q['cerrada'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora + cerrada", e.g. "mediodia-0") read back.
  factory CruceState.fromKey(String key) {
    final m = RegExp(r'^(mediodia|tarde|ocaso)-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of El cruce's set");
    }
    return CruceState(hora: m[1]!, cerrada: m[2] == '1');
  }

  final String hora;
  final bool cerrada;

  /// The sheet's key.
  String get key => '$hora-${cerrada ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&cerrada=${cerrada ? 1 : 0}';
}

/// cruce-set.html: E, the set's numbers and its turn.
abstract final class E {
  static const double HW = 1.25, PV = .7;
  static const List<double> TREE = [-2.5, -4.4];
  static const ({double u0, double v0, double u1, double v1}) PLAZA = (
    u0: 2.2,
    v0: 2.6,
    u1: 5.7,
    v1: 7.6,
  );
  static const ({double u, double v, double hw}) SEAT = (
    u: 3.3,
    v: 4.5,
    hw: 1.1,
  );
  static const List<double> MURITO = [2.6, 7.0];
  static const double CONES = 2.45;
  static final double _R2 = math.sqrt2;

  /// The world point's (u, v).
  static List<double> uv(num x, num y) => [(x - y) / _R2, (x + y) / _R2];

  /// The world point of (u, v).
  static List<double> xy(num u, num v) => [(u + v) / _R2, (v - u) / _R2];
}

/// cruce-set.html's buildSet on an engine [e] with the page's origin.
class CruceSet {
  CruceSet(this.e, this.b) : k = SetKit(e, b) {
    cl = CalleBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CalleBase cl;

  /// Record which part drew each pixel at the next bakes (cruce-set.html `?tags=1`).
  bool tags = false;

  /// The pixels each part drew last at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  // cruce-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    final uv = E.uv(x, y), u = uv[0], v = uv[1];
    final au = u.abs(), av = v.abs();
    const H = E.HW, P = E.PV;
    final inV = au <= H && v < 9, inU = av <= H;
    if (inV || inU) {
      if (inV && inU) return cl.asphalt(ix, iy);
      if (inV &&
          au < .05 &&
          (v < -H - .3 || v > H + .3) &&
          ((v + 40).remainder(1.3)) < .8) {
        return cl.paint(CalleBase.LINE);
      }
      if (inU && av < .05 && ((u + 40).remainder(1.3)) < .8) {
        return cl.paint(CalleBase.LINE);
      }
      if (inV && v > H && v < H + .9 && ((u + H).remainder(.42)) < .24) {
        return cl.paint(CalleBase.WHITE); // the stripes where he comes up
      }
      return cl.asphalt(ix, iy);
    }
    final d = math.min(au - H, av - H); // how far from the nearer street
    if (d < .14) return cl.kerb();
    const pz = E.PLAZA;
    if (u > pz.u0 - 1.2 && v > H && u < pz.u1 && v < pz.v1) {
      // the square's paving
      return (d < P + .1 || (u > pz.u0 && v > pz.v0))
          ? cl.slab(x, y, ix, iy)
          : cl.grass(x, y, ix, iy);
    }
    if (d < P) return cl.slab(x, y, ix, iy);
    return cl.grass(x, y, ix, iy);
  }

  // cruce-set.html: hedge. A low hedge along a line in u, v: a row of leaf balls
  void hedge(num u0, num v0, num u1, num v1) {
    final du = u1 - u0, dv = v1 - v0;
    final n = math.max(1, (math.sqrt(du * du + dv * dv) / .34).round());
    for (var kk = 0; kk <= n; kk++) {
      final p = E.xy(u0 + (u1 - u0) * kk / n, v0 + (v1 - v0) * kk / n);
      final x = p[0], y = p[1];
      e.sphere(
        x,
        y,
        .2,
        .3,
        kk % 3 != 0 ? CalleBase.LEAF : CalleBase.LEAF_L,
        'rough',
      );
      if (kk % 2 == 0) e.castShadow(x, y, .25, .3);
    }
  }

  // cruce-set.html: buildSet
  void buildSet(CruceState SET) {
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
            c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    const H0 = E.HW + E.PV + .3;
    k.part('setos', () {
      // the hedges: behind each pavement, the same on all three ways (none where the square is)
      hedge(-H0, -H0, -H0, -3.2);
      hedge(H0, -H0, H0, -8); // the street straight on
      hedge(-H0, -H0, -5.6, -H0);
      hedge(-H0, H0, -5.6, H0); // the street to the left
      hedge(H0, -H0, 5.6, -H0); // the street to the right, its far side
      hedge(-H0, H0, -H0, 4.6); // the street he comes up, its left side
    });
    k.part('arbol', () {
      final p = E.xy(E.TREE[0], E.TREE[1]);
      cl.tree(p[0], p[1], 1.9, 1.35);
    });
    k.part('plaza', () {
      // low bushes at the square's corners
      for (final q in const [
        [5.2, 2.2],
        [5.55, 2.6],
        [5.3, 7.3],
      ]) {
        final p = E.xy(q[0], q[1]);
        e.sphere(p[0], p[1], .22, .34, CalleBase.LEAF_L, 'rough');
        e.castShadow(p[0], p[1], .25, .3);
      }
      const s = E.SEAT, c = [150, 104, 62];
      final sp = E.xy(s.u, s.v);
      // the seat, long across the picture
      k.turnedBox(sp[0], sp[1], .36, .46, s.hw, .26, -math.pi / 4, c);
      final bp = E.xy(s.u, s.v - .24);
      // its back, at the far side
      k.turnedBox(bp[0], bp[1], .46, 1.0, s.hw, .05, -math.pi / 4, c);
      for (final du in [-s.hw + .15, s.hw - .15]) {
        final lp = E.xy(s.u + du, s.v);
        k.turnedBox(lp[0], lp[1], 0, .36, .07, .22, -math.pi / 4, const [
          70,
          60,
          56,
        ]);
      }
      for (num du = -s.hw; du <= s.hw; du += .3) {
        final qp = E.xy(s.u + du, s.v);
        e.castShadow(qp[0], qp[1], .4, .3);
      }
      // a short piece of low wall at the square's near edge: where the camera is stood
      final mp = E.xy(E.MURITO[0], E.MURITO[1]);
      k.turnedBox(mp[0], mp[1], 0, .55, .45, .12, -math.pi / 4, const [
        196,
        186,
        168,
      ]);
    });
    if (SET.cerrada) {
      k.part('conos', () {
        // the right street is shut: a red and white board on two feet right across it, and cones before it
        final bp = E.xy(E.CONES + .5, 0);
        k.turnedBox(
          bp[0],
          bp[1],
          .5,
          .82,
          .05,
          E.HW + .1,
          -math.pi / 4,
          const [250, 250, 250],
          (s, t, z, face) => ((t + 40) / .3).floor() % 2 != 0
              ? e.rgb(226, 50, 44)
              : e.rgb(252, 252, 250),
        );
        for (final dv in [-E.HW + .15, E.HW - .15]) {
          final fp = E.xy(E.CONES + .5, dv);
          k.turnedBox(fp[0], fp[1], 0, .5, .05, .08, -math.pi / 4, const [
            70,
            74,
            84,
          ]);
          e.castShadow(fp[0], fp[1], .4, .25);
        }
        for (num v = -E.HW + .25; v <= E.HW - .1; v += .75) {
          final p = E.xy(E.CONES, v);
          cl.cone(p[0], p[1]);
        }
      });
    }
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    final L = switch (SET.hora) {
      'tarde' => (const [1.0, .95, .86], const [8.0, 3.0, -6.0]),
      'ocaso' => (const [1.0, .88, .78], const [14.0, 0.0, -10.0]),
      _ => null,
    };
    if (L != null) k.lightPass(L.$1, L.$2);
    k.skyFill(cl.sky(SET.hora == 'ocaso' ? 'tarde' : 'manana', null));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // cruce-set.html: frame (what the reference made: the bake at wind time 0, no casts)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
