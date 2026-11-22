// Port of docs/proyecto/pixel/frutas-set.html: Las frutas' set, its states, call for call (order 52b). The shop front
// and the stand are El colmado's street kit (lib/src/colmado/colmado_fuera.dart). The page's names are kept, capitals
// included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_fuera.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// frutas-set.html: `window.PP_SCENE` with the page's defaults: 240 × 216, S 26, origin (-68, -10), shadows to (.9, -.1).
PpEngine frutasEngine({bool still = false}) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: -68,
  originY: -10,
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// One state of the set (frutas-set.html: `SET`, from the address): `hora` manana or tarde, `puerta` (the shop door)
/// shut or open, `carro` (don Pepe's hand cart, story 44), `surtido` (the bins: verduras or frutas). `aguja` (a red
/// needle on the dial, for the readers' renders) is the page's too; the game never sets it (its needle is a sprite).
class FrutasState {
  const FrutasState({
    this.hora = 'manana',
    this.puerta = 'open',
    this.carro = false,
    this.surtido = 'verduras',
    this.aguja = '',
  });

  /// frutas-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory FrutasState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return FrutasState(
      hora: pick('hora', const ['manana', 'tarde'], 'manana'),
      puerta: pick('puerta', const ['shut', 'open'], 'open'),
      carro: q['carro'] == '1',
      surtido: pick('surtido', const ['verduras', 'frutas'], 'verduras'),
      aguja: pick('aguja', const ['0', 'medio', 'libra'], ''),
    );
  }

  /// A key of the sheet's `setKey` ("hora + puerta + carro + surtido", e.g. "manana-open-0-verduras") read back.
  factory FrutasState.fromKey(String key) {
    final m = RegExp(r'^(manana|tarde)-(shut|open)-([01])-(verduras|frutas)$')
        .firstMatch(key);
    if (m == null) {
      throw ArgumentError.value(key, 'key', "not a key of Las frutas' set");
    }
    return FrutasState(
      hora: m[1]!,
      puerta: m[2]!,
      carro: m[3] == '1',
      surtido: m[4]!,
    );
  }

  final String hora, puerta, surtido, aguja;
  final bool carro;

  /// The sheet's key.
  String get key => '$hora-$puerta-${carro ? 1 : 0}-$surtido';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query =>
      '?hora=$hora&puerta=$puerta&carro=${carro ? 1 : 0}&surtido=$surtido';

  /// The kit's options (frutas-set.html: `SET`, `puesto: true`, the sun at the page's default x).
  CfOpt get opt => CfOpt(
    hora: hora,
    puerta: puerta,
    carro: carro,
    puesto: true,
    surtido: surtido,
    aguja: aguja,
  );
}

/// frutas-set.html's `buildSet` on an engine [e] (frutasEngine's origin).
class FrutasSet {
  FrutasSet(this.e, this.b) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => k.PART_TAGS;

  /// Record which part drew each pixel at the next bakes (frutas-set.html `?tags=1`).
  bool tags = false;

  /// The bins of the assortment of the last bake (colmado-fuera.js BINS).
  List<String> get bins => _cf?.BINS ?? const [];
  ColmadoFuera? _cf;

  // frutas-set.html: buildSet
  void buildSet(FrutasState SET) {
    k.PART_TAGS = tags ? List<String?>.filled(e.W * e.H, null) : null;
    final o = SET.opt, CF = _cf = ColmadoFuera(k), HZ = CF.skyPlan(o).HZ;
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
            c = CF.groundAt(g.x, g.y, ix, iy, i, HZ);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
      }
    }
    e.groundZ.setAll(0, e.zb);
    CF.build(o);
    e.flushShadows();
    e.pendingShadows.clear();
    e.bakeOcclusion();
    k.joinSlabs();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    k.skyFill(CF.sky(o, HZ));
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // frutas-set.html: frame (what the reference made: the bake at wind time 0 with no characters; the set has no
  // tufts or leaves, so drawLeaves and drawTufts draw nothing)
  void frame([double t = 0]) {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    final windT = e.STILL ? 0.0 : (t * e.WIND_FPS).floor() / e.WIND_FPS;
    e.drawLeaves(windT);
    e.drawTufts(windT);
    e.applyShadows(e.groundZ);
  }
}
