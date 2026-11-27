// Port of docs/proyecto/pixel/sombrilla-set.html: La sombrilla's set (place 7, La playa, scene 2: `sombrilla`), its
// states, call for call (order 63b). Built on La playa's kit (lib/src/playa/playa_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/playa/playa_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// sombrilla-set.html: ORIGIN.
const List<double> SOMBRILLA_ORIGIN = [0, -44];

/// The engine La sombrilla's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -44), shadows to (.9, -.1).
PpEngine sombrillaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: SOMBRILLA_ORIGIN[0],
  originY: SOMBRILLA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (sombrilla-set.html: `SET`, from the address): `hora` mediodia, tarde or sol; `dibujo`
/// circulo (big circle for story 75) or figura (whole lying figure for stories 76 and 77).
class SombrillaState {
  const SombrillaState({this.hora = 'mediodia', this.dibujo = 'circulo'});

  /// sombrilla-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory SombrillaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    final d = q['dibujo'];
    return SombrillaState(
      hora: h != null && const ['mediodia', 'tarde', 'sol'].contains(h)
          ? h
          : 'mediodia',
      dibujo: d != null && const ['circulo', 'figura'].contains(d)
          ? d
          : 'circulo',
    );
  }

  /// A key of the sheet's `setKey` ("hora-dibujo", e.g. "mediodia-circulo") read back.
  factory SombrillaState.fromKey(String key) {
    final m = RegExp(r'^(mediodia|tarde|sol)-(circulo|figura)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of La sombrilla's set");
    }
    return SombrillaState(hora: m[1]!, dibujo: m[2]!);
  }

  final String hora;
  final String dibujo;

  /// The sheet's key.
  String get key => '$hora-$dibujo';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora&dibujo=$dibujo';
}

/// sombrilla-set.html: E, the set's places (the sheet reads them: things, spots).
abstract final class SombrillaE {
  static const PlayaBeach B = PlayaBeach(
    edge: 0,
    wet: .7,
    deep: -1.6,
    hor: -3.2,
  );
  static const List<double> UMB = [-3.05, 1.5, 2.1, 1.3];
  static const List<double> BLANKET = [-2.75, 1.2, -.35, 2.9];
  static const ({double u, double v, double ru, double rv}) GROUND = (
    u: 1.05,
    v: 5.2,
    ru: 2.75,
    rv: 3.3,
  );
  static const ({double u, double v, double r}) FACE = (
    u: 1.05,
    v: 4.6,
    r: 1.6,
  );
  static const ({
    double u,
    List<double> head,
    double arms,
    double armLen,
    List<double> body,
    List<double> legs,
    double legDu,
  })
  FIG = (
    u: 1.05,
    head: [3.05, .9],
    arms: 4.5,
    armLen: 1.5,
    body: [3.95, 5.5],
    legs: [5.5, 7.6],
    legDu: .55,
  );
  static const List<double> BUCKET = [3.45, 1.9];
  static const List<double> WEED = [3.5, 3.0];
  static const List<double> BAG = [-2.3, 5.3];

  /// sombrilla-set.html: FACE_AT.
  static const Map<String, List<double>> FACE_AT = {
    'ojo_izq': [1.05 - .62, 4.6 - .55],
    'ojo_der': [1.05 + .62, 4.6 - .55],
    'nariz': [1.05, 4.6 + .1],
    'boca': [1.05, 4.6 + .85],
  };
}

/// Port of sombrilla-set.html: builds the baked set into [e].
class SombrillaSet {
  SombrillaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    PL = PlayaBase(PZ);
    LINE = e.rgb(120, 100, 76);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final PlayaBase PL;
  late final int LINE;

  int get W => e.W;
  int get H => e.H;
  double get R2 => e.R2;
  double get COS => e.COS;
  int rgb(num r, num g, num bl) => e.rgb(r, g, bl);

  // sombrilla-set.html: near
  static bool _near(double d, [double w = .045]) => d.abs() < w;

  // sombrilla-set.html: drawn
  bool drawn(double u, double v, String dibujo) {
    if (dibujo == 'circulo') {
      const F = SombrillaE.FACE;
      final d = jsHypot(u - F.u, (v - F.v) * 1.0);
      return _near(d - F.r, .05);
    }
    const G = SombrillaE.FIG;
    final du = u - G.u;
    if (_near(jsHypot(du, v - G.head[0]) - G.head[1], .05)) return true;
    if (_near(du, .04) && v > G.body[0] && v < G.body[1]) return true;
    if (_near(v - G.arms, .07) && du.abs() < G.armLen) return true;
    for (final sgn in const [-1, 1]) {
      final hu = sgn * G.armLen;
      for (var kk = -2; kk <= 2; kk++) {
        final a = kk * .38, lu = du - hu, lv = v - G.arms;
        final t = lu * sgn * math.cos(a) + lv * math.sin(a);
        final n = -lu * sgn * math.sin(a) + lv * math.cos(a);
        if (t > 0 && t < .46 && _near(n, .05)) return true;
      }
      final lt = (v - G.legs[0]) / (G.legs[1] - G.legs[0]);
      if (lt > 0 && lt < 1 && _near(du - sgn * G.legDu * lt, .045)) return true;
      if (_near(v - G.legs[1], .07) &&
          (du - sgn * G.legDu) * sgn > 0 &&
          (du - sgn * G.legDu) * sgn < .4) {
        return true;
      }
    }
    return false;
  }

  // sombrilla-set.html: groundAt
  PlayaGround? groundAt(num x, num y, int ix, int iy, SombrillaState state) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    final g = PL.ground(u, v, ix, iy, SombrillaE.B);
    if (g == null) return null;
    if (g.kind == 'arena') {
      const K = SombrillaE.GROUND;
      final d =
          jsHypot((u - K.u) / K.ru, (v - K.v) / K.rv) +
          e.noise(u * 2, v * 2) * .06;
      if (d < 1) {
        if (drawn(u, v, state.dibujo)) {
          return (color: LINE, kind: 'arena');
        }
        return (
          color: b.toneOf(
            PlayaBase.WET,
            d > .9 ? .9 : .62 + e.noise(u * 1.5, v * 1.5) * .12,
            ix,
            iy,
          ),
          kind: 'arena',
        );
      }
    }
    return g;
  }

  // sombrilla-set.html: buildSet
  /// Builds the baked set for [state] into [e].
  void buildSet(SombrillaState state) {
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
    k.part(
      'manta',
      () => PL.blanket(
        SombrillaE.BLANKET[0],
        SombrillaE.BLANKET[1],
        SombrillaE.BLANKET[2],
        SombrillaE.BLANKET[3],
        const [70, 150, 150],
        const [250, 246, 236],
      ),
    );
    k.part(
      'sombrilla',
      () => PL.umbrella(
        SombrillaE.UMB[0],
        SombrillaE.UMB[1],
        SombrillaE.UMB[2],
        SombrillaE.UMB[3],
        true,
      ),
    );
    k.part('cubo', () => PL.bucket(SombrillaE.BUCKET[0], SombrillaE.BUCKET[1]));
    k.part(
      'algas',
      () => PZ.flat(
        SombrillaE.WEED[0] - .55,
        SombrillaE.WEED[1] - .5,
        SombrillaE.WEED[0] + .55,
        SombrillaE.WEED[1] + .5,
        .02,
        (u, v) {
          final du = u - SombrillaE.WEED[0], dv = v - SombrillaE.WEED[1];
          for (var kk = 0; kk < 7; kk++) {
            final a = kk * .9, c = math.cos(a), s2 = math.sin(a);
            final t = du * c + dv * s2;
            final n = -du * s2 + dv * c + math.sin(t * 9 + kk) * .05;
            if (t.abs() < .5 && n.abs() < .045) {
              return kk.remainder(2) != 0 ? rgb(40, 110, 70) : rgb(70, 140, 80);
            }
          }
          return 0;
        },
      ),
    );
    k.part('bolsa', () {
      PZ.box(
        SombrillaE.BAG[0],
        SombrillaE.BAG[1],
        0,
        .46,
        .38,
        .18,
        const [236, 190, 110],
        (s, t, z, face) => face == 'front'
            ? ((((s + 1) / .09).floor() + (z / .08).floor()).remainder(2) != 0
                  ? rgb(214, 160, 84)
                  : 0)
            : 0,
      );
      PZ.wall(
        SombrillaE.BAG[0] - .26,
        SombrillaE.BAG[0] + .26,
        SombrillaE.BAG[1] + .19,
        .46,
        .86,
        (u, z) {
          final r = jsHypot((u - SombrillaE.BAG[0]) * 26, (z - .46) * 22.5);
          return (r > 5 && r < 6.6) ? rgb(150, 100, 60) : 0;
        },
      );
      PZ.shadow(SombrillaE.BAG[0], SombrillaE.BAG[1], .3, .4);
    });
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    PL.light(state.hora);
    k.skyFill(PL.sky(state.hora, null));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // sombrilla-set.html: frame(t, casts = [])
  void frame(double t, [List<List<num>> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c[0], c[1], c[2], c[3]);
    }
    e.applyShadows(e.groundZ);
  }
}
