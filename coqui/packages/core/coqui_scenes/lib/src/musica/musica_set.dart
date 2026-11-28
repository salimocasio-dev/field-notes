// Port of docs/proyecto/pixel/musica-set.html: La música's set (place 10, El fuerte, scene 2: `musica`),
// call for call (order 75). Built on El fuerte's kit (lib/src/fuerte/fuerte_base.dart) and La plaza's painters
// (lib/src/plaza/plaza_base.dart). The page's names are kept, capitals included (page 12, section 6): the lints on
// names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fuerte/fuerte_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// musica-set.html: ORIGIN.
const List<double> MUSICA_ORIGIN = [0, -34];

/// The engine La música's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (0, -34), shadows to (.9, -.1).
PpEngine musicaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: MUSICA_ORIGIN[0],
  originY: MUSICA_ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (musica-set.html: `SET`, from the address): `hora` noche (one state).
class MusicaState {
  const MusicaState({this.hora = 'noche'});

  /// musica-set.html: `SET.hora` is fixed `'noche'`.
  factory MusicaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final h = q['hora'];
    return MusicaState(
      hora: h != null && const ['noche'].contains(h) ? h : 'noche',
    );
  }

  /// A key of the set ("noche") read back.
  factory MusicaState.fromKey(String key) {
    if (key != 'noche') {
      throw ArgumentError.value(key, 'key', "not a key of La música's set");
    }
    return MusicaState(hora: key);
  }

  final String hora;

  /// The set's key.
  String get key => hora;

  /// The page's query for this state.
  String get query => '?hora=$hora';
}

/// musica-set.html: E, the set's places (the sheet reads them: wall, lamps, lights, stage, stools, rack, mic, notes,
/// bench, stool, floor).
abstract final class MusicaE {
  static const double WALL = 2.6;
  static const List<List<double>> LAMPS = [
    [-3.45, 1.35],
    [-1.0, 1.35],
    [1.15, 1.35],
    [3.5, 1.35],
  ];
  static const ({double u0, double u1, double z}) LIGHTS = (
    u0: -4.2,
    u1: 4.2,
    z: 2.05,
  );
  static const ({double u0, double u1, double v0, double v1, double h}) STAGE =
      (u0: -3.72, u1: -.6, v0: .3, v1: 2.5, h: .28);
  static const List<List<double>> STOOLS = [
    [-3.2, 1.25],
    [-2.2, 1.25],
  ];
  static const ({double u, double v, double hw, double h}) RACK = (
    u: -1.2,
    v: .7,
    hw: .42,
    h: 1.3,
  );
  static const List<double> MIC = [-.2, 1.8];
  static const ({List<double> u, double z}) NOTES = (
    u: [-3.2, -2.2, -1.2],
    z: 2.75,
  );
  static const ({double u, double v, double hw}) BENCH = (
    u: 1.85,
    v: .45,
    hw: 1.9,
  );
  static const List<double> STOOL = [2.7, 4.7];
  static const List<double> FLOOR = [-1.0, 2.2, 2.6, 7.6];
}

/// Port of musica-set.html: builds the baked set into [e].
class MusicaSet {
  MusicaSet(this.e, this.b) : k = SetKit(e, b) {
    PZ = PlazaBase(k);
    FT = FuerteBase(PZ);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final PlazaBase PZ;
  late final FuerteBase FT;

  int get W => e.W;
  int get H => e.H;

  // musica-set.html: groundAt
  int groundAt(double x, double y, int ix, int iy) {
    final uv = PZ.uv(x, y);
    final u = uv[0], v = uv[1];
    return v < -.62 ? 0 : FT.flags(u, v, ix, iy);
  }

  // musica-set.html: wall
  void wall() {
    FT.yardWall(MusicaE.WALL);
    for (final l in MusicaE.LAMPS) {
      FT.wallLamp(l[0], 0, l[1], true);
    }
    FT.lights(MusicaE.LIGHTS.u0, MusicaE.LIGHTS.u1, .03, MusicaE.LIGHTS.z, .16);
  }

  // musica-set.html: yard
  void yard() {
    const S = MusicaE.STAGE;
    const W1 = [190, 140, 92];
    final mid = (S.u0 + S.u1) / 2, hw = (S.u1 - S.u0) / 2;
    PZ.box(
      mid,
      (S.v0 + S.v1) / 2,
      0,
      S.h,
      hw,
      (S.v1 - S.v0) / 2,
      W1,
      (s, t, z, face) => face == 'top'
          ? (jsMod(t + 9, .34) < .035
                ? e.rgb(130, 92, 60)
                : b.shade(const [206, 158, 106], 3, s * 2, t * 2, .12))
          : (face == 'front'
                ? (z < .05
                      ? e.rgb(110, 78, 52)
                      : (jsMod(s + 9, .5) < .04 ? e.rgb(130, 92, 60) : 0))
                : 0),
    );
    for (double du = -hw; du <= hw; du += .3) {
      PZ.shadow(mid + du, S.v1 - .1, .2, .3);
    }
    const R = MusicaE.RACK;
    for (final du in [-R.hw, R.hw]) {
      PZ.post(R.u + du, R.v, S.h, S.h + R.h, .04, const [120, 84, 52]);
    }
    PZ.box(R.u, R.v, S.h + R.h, S.h + R.h + .07, R.hw + .06, .04, const [
      150,
      104,
      62,
    ]);
    for (final st in MusicaE.STOOLS) {
      FT.stool(st[0], st[1], .46, .22, const [176, 122, 76], S.h);
    }
    PZ.seat(MusicaE.BENCH.u, MusicaE.BENCH.v, MusicaE.BENCH.hw);
    FT.stool(MusicaE.STOOL[0], MusicaE.STOOL[1]);
  }

  // musica-set.html: skyOf
  int skyOf(int ix, int iy) => FT.night(ix, iy, 400, const [150, 6, 7]);

  // musica-set.html: buildSet
  void buildSet(MusicaState state) {
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
        final c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        e.kinds[i] = KIND_ROAD;
      }
    }
    e.groundZ.setAll(0, e.zb);
    k.part('muro', wall);
    k.part('patio', yard);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.lightPass(const [.86, .8, .8], const [4, 0, 8], false);
    k.skyFill(skyOf);
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // musica-set.html: frame
  void frame(double t, [List<ShadowCast> casts = const []]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    for (final c in casts) {
      e.castShadow(c.x, c.y, c.z, c.r);
    }
    e.applyShadows(e.groundZ);
  }
}
