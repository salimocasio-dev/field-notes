// Port of docs/proyecto/pixel/caja-set.html: La caja's set, its states, call for call (order 53b). The room is El
// colmado's kit (lib/src/colmado/colmado_dentro.dart), framed on the counter's left end: the register in the middle, the
// shop window and the street door on the left wall. The page's names are kept, capitals included (page 12, section 6):
// the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// caja-set.html: ORIGIN (the register, x 105..142, in the middle of the picture).
const List<double> ORIGIN = [11, -30];

/// The engine La caja's set is built on (`window.PP_SCENE`): 240 × 216, S 26, origin (11, -30), shadows to (.9, -.1).
PpEngine cajaEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: ORIGIN[0],
  originY: ORIGIN[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (caja-set.html: `SET`, from the address): `hora` manana or tarde (the page's default: tarde).
/// The back door is always shut; no props, no freezer.
class CajaState {
  const CajaState({this.hora = 'tarde'});

  /// caja-set.html: `pick('hora', ['manana', 'tarde'], 'tarde')` from a query.
  factory CajaState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    final v = q['hora'];
    return CajaState(
      hora: v != null && const ['manana', 'tarde'].contains(v) ? v : 'tarde',
    );
  }

  /// A key of the sheet's `setKey` ("manana" or "tarde") read back.
  factory CajaState.fromKey(String key) {
    if (key != 'manana' && key != 'tarde') {
      throw ArgumentError.value(key, 'key', "not a key of La caja's set");
    }
    return CajaState(hora: key);
  }

  final String hora;

  /// The sheet's key.
  String get key => hora;

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => '?hora=$hora';
}

/// caja-set.html: DARK, outside the room, above the walls' tops: a warm dark.
const List<int> DARK = [46, 38, 40];

/// caja-set.html's `buildSet` on an engine [e] made by [cajaEngine].
class CajaSet {
  CajaSet(this.e, this.b) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  /// Record which part drew each pixel at the next bakes (caja-set.html `?tags=1`).
  bool tags = false;

  // caja-set.html: buildSet
  void buildSet(CajaState SET) {
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
    final CD = ColmadoDentro(k), o = CdOpt(hora: SET.hora, atras: 'shut');
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

  // caja-set.html: frame (what the reference made: the bake at wind time t, no characters; the set has no wind)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
