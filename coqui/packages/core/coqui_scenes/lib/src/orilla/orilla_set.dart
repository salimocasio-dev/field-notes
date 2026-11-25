// Port of docs/proyecto/pixel/orilla-set.html: La orilla's set (place 7, La playa, scene 1: `orilla`), its states, call
// for call (order 62b). Built on La playa's kit (lib/src/playa/playa_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/playa/playa_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// orilla-set.html: ORIGIN.
const List<double> ORILLA_ORIGIN = [0, -30];

/// The engine La orilla's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -30), shadows to (.9, -.1).
PpEngine orillaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORILLA_ORIGIN[0],
  originY: ORILLA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (orilla-set.html: `SET`, from the address): `hora` manana, mediodia, tarde or ocaso;
/// `castillo` (the sand castle with three towers and the patch of damp smooth sand, story 72); `manta` (abuela's
/// blanket, story 74); `bote` (the fishing boat baked for readers' renders only: false in the game, where it is a
/// sprite).
class OrillaState {
  const OrillaState({
    this.hora = 'manana',
    this.castillo = false,
    this.manta = false,
    this.bote = false,
  });

  /// orilla-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory OrillaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return OrillaState(
      hora:
          h != null &&
              const ['manana', 'mediodia', 'tarde', 'ocaso'].contains(h)
          ? h
          : 'manana',
      castillo: q['castillo'] == '1',
      manta: q['manta'] == '1',
      bote: q['bote'] == '1',
    );
  }

  /// A key of the sheet's `setKey` ("hora-castillo-manta", e.g. "manana-1-0") read back.
  factory OrillaState.fromKey(String key) {
    final m = RegExp(r'^(manana|mediodia|tarde|ocaso)-([01])-([01])$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La orilla's set");
    }
    return OrillaState(hora: m[1]!, castillo: m[2] == '1', manta: m[3] == '1');
  }

  final String hora;
  final bool castillo;
  final bool manta;
  final bool bote;

  /// The sheet's key.
  String get key => '$hora-${castillo ? 1 : 0}-${manta ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query =>
      '?hora=$hora&castillo=${castillo ? 1 : 0}&manta=${manta ? 1 : 0}${bote ? '&bote=1' : ''}';
}

/// orilla-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class OrillaE {
  static const PlayaBeach B = PlayaBeach(
    edge: 0,
    wet: .9,
    deep: -2.2,
    hor: -4.6,
  );
  static const List<List<double>> PALMS = [
    [-3.6, 2.0],
    [-1.6, 2.0],
  ];
  static const double ROPE = 1.45;
  static const ({double u, double v, double r, List<double> towers, double th})
  CASTLE = (u: 1.2, v: 3.4, r: 1.15, towers: [.5, 1.2, 1.9], th: .72);
  static const ({double u, double v, double ru, double rv}) PATCH = (
    u: 1.2,
    v: 5.45,
    ru: .85,
    rv: .42,
  );
  static const List<double> BLANKET = [-3.75, 3.2, -.9, 5.0];
  static const List<double> BOAT = [2.5, -3.5];
  static const Map<String, List<num>?> SUN = {
    'manana': [150, 8, 6],
    'mediodia': null,
    'tarde': [40, 9, 6],
    'ocaso': [58, 10, 7],
  };
}

/// Port of orilla-set.html: builds the baked set into [e].
class OrillaSet {
  OrillaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    PL = PlayaBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final PlayaBase PL;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  // orilla-set.html: groundAt
  PlayaGround? groundAt(num x, num y, int ix, int iy, OrillaState state) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    final g = PL.ground(u, v, ix, iy, OrillaE.B);
    if (g == null) return null;
    if (state.castillo && g.kind == 'arena') {
      const P = OrillaE.PATCH;
      final d = jsHypot((u - P.u) / P.ru, (v - P.v) / P.rv);
      if (d < 1) {
        return (
          color: d > .8
              ? rgb(250, 242, 214)
              : b.toneOf(
                  PlayaBase.WET,
                  .78 + e.noise(u * 3, v * 3) * .1,
                  ix,
                  iy,
                ),
          kind: 'arena',
        );
      }
    }
    return g;
  }

  // orilla-set.html: castle
  void castle() {
    const K = OrillaE.CASTLE;
    const S1 = [232, 212, 168];
    final bp = PZ.xy(K.u, K.v), bx = bp[0], by = bp[1];
    k.drum(bx, by, 0, .12, K.r, S1);
    for (final tu in K.towers) {
      final tp = PZ.xy(tu, K.v), x = tp[0], y = tp[1];
      k.drum(
        x,
        y,
        .12,
        .12 + K.th,
        .26,
        S1,
        (a, bb) => jsHypot(a, bb) < .13 ? rgb(196, 174, 128) : 0,
      );
      PZ.wall(
        tu - .06,
        tu + .06,
        K.v + .27,
        .34,
        .58,
        (uu, z) => jsHypot((uu - tu) * 26, math.max(0.0, (z - .5)) * 22.5) < 1.7
            ? rgb(120, 96, 70)
            : 0,
      );
      for (var kk = 0; kk < 6; kk++) {
        final t = kk * 1.047;
        PZ.box(
          tu + math.cos(t) * .21,
          K.v + math.sin(t) * .21,
          .12 + K.th,
          .12 + K.th + .11,
          .06,
          .06,
          S1,
        );
      }
      e.castShadow(x, y, .4, .3);
    }
    e.castShadow(bx, by, .1, K.r);
  }

  // orilla-set.html: boat
  void boat() {
    final u = OrillaE.BOAT[0], v = OrillaE.BOAT[1];
    const W1 = [250, 248, 240], RED = [206, 62, 54];
    PZ.box(
      u,
      v,
      0,
      .3,
      .62,
      .2,
      W1,
      (s, t, z, face) =>
          face == 'front' && z < .12 ? rgb(RED[0], RED[1], RED[2]) : 0,
    );
    PZ.box(
      u - .18,
      v,
      .3,
      .62,
      .2,
      .15,
      const [86, 160, 190],
      (s, t, z, face) => face == 'front' && s.abs() < .1 && z > .38 && z < .54
          ? rgb(40, 60, 90)
          : 0,
    );
    PZ.post(u + .28, v, .3, 1.0, .02, const [120, 90, 60]);
  }

  // orilla-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(OrillaState state) {
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
        final g = e.unproject(ix + .5, iy + .5);
        final i = iy * W + ix;
        final c = groundAt(g.x, g.y, ix, iy, state);
        if (c == null) continue;
        e.pix[i] = c.color;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / R2 * COS;
        e.kinds[i] = c.kind == 'mar' ? KIND_WATER : KIND_SAND;
      }
    }
    e.groundZ.setAll(0, e.zb);
    final L = const <String, Light>{
      'tarde': Light([1.0, .95, .86], [8, 3, -6]),
      'ocaso': Light([1.0, .86, .74], [16, 0, -12]),
    }[state.hora];
    if (state.bote) k.part('bote', boat);
    if (state.manta) {
      k.part(
        'manta',
        () => PL.blanket(
          OrillaE.BLANKET[0],
          OrillaE.BLANKET[1],
          OrillaE.BLANKET[2],
          OrillaE.BLANKET[3],
        ),
      );
    }
    k.part('palmas', () {
      PL.palm(OrillaE.PALMS[0][0], OrillaE.PALMS[0][1], 3.3, -.5, 2, 1, L);
      PL.palm(OrillaE.PALMS[1][0], OrillaE.PALMS[1][1], 3.0, .45, 5, .92, L);
      PZ.wall(
        OrillaE.PALMS[0][0] - .05,
        OrillaE.PALMS[1][0] + .2,
        OrillaE.PALMS[0][1],
        OrillaE.ROPE - .12,
        OrillaE.ROPE + .03,
        (u, z) {
          final t =
              (u - OrillaE.PALMS[0][0]) /
              (OrillaE.PALMS[1][0] - OrillaE.PALMS[0][0] + .15);
          final zr = OrillaE.ROPE - .09 * 4 * t * (1 - t);
          return (z - zr).abs() < .03 ? rgb(110, 84, 60) : 0;
        },
      );
    });
    if (state.castillo) k.part('castillo', castle);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PL.light(state.hora);
    k.skyFill(PL.sky(state.hora, OrillaE.SUN[state.hora]));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // orilla-set.html: frame(t, casts = [])
  void frame(double t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final windT = e.STILL ? 0.0 : (t * e.WIND_FPS).floor() / e.WIND_FPS;
    e.drawLeaves(windT);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
