// Port of docs/proyecto/pixel/estantes-set.html: Los estantes' set, its states, call for call (order 51b). The room is
// El colmado's kit (lib/src/colmado/colmado_dentro.dart): this page frames its second run of shelves, whole, with the
// ladder, the low table and open floor in front. The page's names are kept, capitals included (page 12, section 6): the
// lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// estantes-set.html: ORIGIN (the second run of shelves, the ladder, the table and 60 px of open floor under the run;
/// only wall and floor at the left edge).
const List<double> ORIGIN = [-222, -95];

/// The engine Los estantes' set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (-222, -95), shadows to
/// (.9, -.1).
PpEngine estantesEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (estantes-set.html: `SET`, from the address): `anillos` (six rings of dust on the middle shelf,
/// story 39), `mesa` (the low display table, story 40). Fixed, as the page has them: `hora` manana, `atras` shut, the
/// ladder always there.
class EstantesState {
  const EstantesState({this.anillos = false, this.mesa = false});

  /// estantes-set.html: `Q.get('anillos') === '1'`, `Q.get('mesa') === '1'`.
  factory EstantesState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    return EstantesState(anillos: q['anillos'] == '1', mesa: q['mesa'] == '1');
  }

  /// A key of the sheet's `setKey` (`key`: "anillos + mesa, e.g. "1-0"") read back.
  factory EstantesState.fromKey(String key) {
    final m = RegExp(r'^([01])-([01])$').firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of Los estantes' set");
    }
    return EstantesState(anillos: m[1] == '1', mesa: m[2] == '1');
  }

  final bool anillos, mesa;

  /// The sheet's key.
  String get key => '${anillos ? 1 : 0}-${mesa ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?anillos=${anillos ? 1 : 0}&mesa=${mesa ? 1 : 0}';

  /// estantes-set.html: `SET` as colmado-dentro.js reads it (`hora: 'manana', atras: 'shut', escalera: true`).
  CdOpt get opt => CdOpt(
    hora: 'manana',
    atras: 'shut',
    escalera: true,
    anillos: anillos,
    mesa: mesa,
  );
}

/// estantes-set.html: DARK, outside the room, above the walls' tops: a warm dark.
const List<int> DARK = [46, 38, 40];

/// estantes-set.html's `buildSet` on an engine [e] (with the page's origin).
class EstantesSet {
  EstantesSet(this.e, this.b) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  /// Record which part drew each pixel at the next bakes (estantes-set.html `?tags=1`: `PART_TAGS`).
  bool tags = false;

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  // estantes-set.html: buildSet
  void buildSet(EstantesState SET) {
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
    final CD = ColmadoDentro(k), o = SET.opt;
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = CD.floorAt(g.x, g.y, ix, iy, i);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
      }
    }
    e.groundZ.setAll(0, e.zb);
    CD.build(o);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    CD.light(o);
    k.skyFill((_, _) => e.rgb(DARK[0], DARK[1], DARK[2]));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // estantes-set.html: frame (what the reference made: the bake at wind time 0, no characters; the set has no wind)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
