// Port of docs/proyecto/pixel/mostrador-set.html: El mostrador's set, its states, call for call (order 50b). The room
// and the shop front are El colmado's kits (lib/src/colmado/colmado_dentro.dart, colmado_fuera.dart). The page's names
// are kept, capitals included (page 12, section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/colmado/colmado_fuera.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// mostrador-set.html: ORIGIN, inside (dentro: the first run of shelves, the counter and the chair whole; the street door,
/// the shop window and the register inside).
const List<double> ORIGIN_DENTRO = [-7, -32];

/// mostrador-set.html: ORIGIN, in the street (calle: the door and the sign in the middle third, the whole stand, the crate
/// and the post inside the picture).
const List<double> ORIGIN_CALLE = [-46, -6];

PpEngine _engine(List<double> o, bool still) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: o[0],
  originY: o[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The engine El mostrador's set is built on (`window.PP_SCENE` with the inside origin): 240 × 216, S 26, origin
/// (-7, -32), shadows to (.9, -.1). The state `calle` is built on an engine of its own origin ([mostradorCalleEngine])
/// and handed over to this one (see [MostradorSet.buildSet]).
PpEngine mostradorEngine({bool still = false}) => _engine(ORIGIN_DENTRO, still);

/// The engine of the state `calle` (the page with `?donde=calle`: origin (-46, -6)).
PpEngine mostradorCalleEngine({bool still = false}) =>
    _engine(ORIGIN_CALLE, still);

/// One state of the set (mostrador-set.html: `SET`, from the address): `donde` dentro or calle, `hora` manana or tarde,
/// `atras` (the back door) and `nevera` (the freezer on the counter) inside, `puerta` (the shop door) in the street.
/// `props` (stand-in goods, for the readers' renders) is the page's too; the game never sets it.
class MostradorState {
  const MostradorState({
    this.donde = 'dentro',
    this.hora = 'manana',
    this.atras = 'shut',
    this.puerta = 'shut',
    this.nevera = false,
    this.props = false,
  });

  /// mostrador-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory MostradorState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return MostradorState(
      donde: pick('donde', const ['dentro', 'calle'], 'dentro'),
      hora: pick('hora', const ['manana', 'tarde'], 'manana'),
      atras: pick('atras', const ['shut', 'open'], 'shut'),
      puerta: pick('puerta', const ['shut', 'open'], 'shut'),
      nevera: q['nevera'] == '1',
      props: q['props'] == '1',
    );
  }

  /// A key of the sheet's `setKey` (`key`: inside "hora-atras-nevera", e.g. "manana-shut-0"; in the street
  /// "hora-puerta", e.g. "manana-shut") read back.
  factory MostradorState.fromKey(String key) {
    final d = RegExp(r'^(manana|tarde)-(shut|open)-([01])$').firstMatch(key);
    if (d != null) {
      return MostradorState(hora: d[1]!, atras: d[2]!, nevera: d[3] == '1');
    }
    final c = RegExp(r'^(manana|tarde)-(shut|open)$').firstMatch(key);
    if (c != null) {
      return MostradorState(donde: 'calle', hora: c[1]!, puerta: c[2]!);
    }
    throw ArgumentError.value(key, 'key', "not a key of El mostrador's set");
  }

  final String donde, hora, atras, puerta;
  final bool nevera, props;

  /// The sheet's key.
  String get key =>
      donde == 'calle' ? '$hora-$puerta' : '$hora-$atras-${nevera ? 1 : 0}';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => donde == 'calle'
      ? '?donde=calle&hora=$hora&puerta=$puerta'
      : '?donde=dentro&hora=$hora&atras=$atras&nevera=${nevera ? 1 : 0}';
}

/// mostrador-set.html: DARK, outside the room, above the walls' tops: a warm dark.
const List<int> DARK = [46, 38, 40];

/// mostrador-set.html's `buildSet` on an engine [e] with the inside origin. The state `calle` is built, as the page
/// builds it with its own origin, on a second engine (made once per [MostradorSet]), and its buffers are then copied into
/// [e]: the picture, its depth, kinds, ground, ground depth and shadow masks are the page's own, pixel for pixel.
class MostradorSet {
  MostradorSet(this.e, this.b) : k = SetKit(e, b);

  final PpEngine e;
  final PpBuild b;
  final SetKit k;

  PpEngine? _calle;
  SetKit? _calleKit;

  /// The engine `calle` is built on (made on first use).
  PpEngine get calleEngine => _calle ??= mostradorCalleEngine(still: e.STILL);

  /// The pixels each part of the set drew last (set-kit.js PART_TAGS) at the last bake, when [tags] is on.
  List<String?>? get partTags => _lastKit?.PART_TAGS;
  SetKit? _lastKit;

  /// Record which part drew each pixel at the next bakes (mostrador-set.html `?tags=1`).
  bool tags = false;

  // mostrador-set.html: buildSet
  void buildSet(MostradorState SET) {
    final calle = SET.donde == 'calle';
    final en = calle ? calleEngine : e;
    final kit = calle ? (_calleKit ??= SetKit(en, PpBuild(en))) : k;
    _lastKit = kit;
    kit.PART_TAGS = tags ? List<String?>.filled(en.W * en.H, null) : null;
    final W = en.W, H = en.H;
    en.zb.fillRange(0, en.zb.length, -1e9);
    en.pix.fillRange(0, en.pix.length, 0);
    en.kinds.fillRange(0, en.kinds.length, 0);
    en.ground.fillRange(0, en.ground.length, 0);
    en.shadowMask.fillRange(0, en.shadowMask.length, 0);
    en.staticShadow.fillRange(0, en.staticShadow.length, 0);
    en.tufts.clear();
    en.leaves.clear();
    en.pendingShadows.clear();
    kit.slabTops.clear();
    kit.glowReset();
    if (calle) {
      // the shop front, from the street (story 36's first beat)
      final o = CfOpt(
            hora: SET.hora,
            puerta: SET.puerta,
            puesto: true,
            surtido: 'verduras',
            solX: 206,
          ),
          CF = ColmadoFuera(kit),
          HZ = CF.skyPlan(o).HZ;
      for (var iy = 0; iy < H; iy++) {
        for (var ix = 0; ix < W; ix++) {
          final g = en.unproject(ix + .5, iy + .5),
              i = iy * W + ix,
              c = CF.groundAt(g.x, g.y, ix, iy, i, HZ);
          if (c == 0) continue;
          en.pix[i] = c;
          en.ground[i] = 1;
          en.zb[i] = (g.x + g.y) / en.R2 * en.COS;
        }
      }
      en.groundZ.setAll(0, en.zb);
      CF.build(o);
      en.flushShadows();
      en.pendingShadows.clear();
      en.bakeOcclusion();
      kit.joinSlabs();
      en.staticShadow.setAll(0, en.shadowMask);
      en.applyShadows(en.groundZ);
      en.shadeEdges();
      kit.skyFill(CF.sky(o, HZ));
      en.bakedPix.setAll(0, en.pix);
      en.bakedZ.setAll(0, en.zb);
      _handOver(en);
      return;
    }
    final CD = ColmadoDentro(kit),
        o = CdOpt(
          hora: SET.hora,
          atras: SET.atras,
          nevera: SET.nevera,
          props: SET.props,
        );
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = en.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = CD.floorAt(g.x, g.y, ix, iy, i);
        if (c == 0) continue;
        en.pix[i] = c;
        en.ground[i] = 1;
        en.zb[i] = (g.x + g.y) / en.R2 * en.COS;
      }
    }
    en.groundZ.setAll(0, en.zb);
    CD.build(o);
    en.flushShadows();
    en.pendingShadows.clear();
    en.bakeOcclusion();
    kit.joinSlabs();
    en.staticShadow.setAll(0, en.shadowMask);
    en.applyShadows(en.groundZ);
    en.shadeEdges();
    CD.light(o);
    kit.skyFill((_, _) => en.rgb(DARK[0], DARK[1], DARK[2]));
    en.bakedPix.setAll(0, en.pix);
    en.bakedZ.setAll(0, en.zb);
  }

  // the street's bake, handed to the scene's engine: everything a bake leaves (BakedSet.capture reads it from there)
  void _handOver(PpEngine from) {
    e.pix.setAll(0, from.pix);
    e.zb.setAll(0, from.zb);
    e.bakedPix.setAll(0, from.bakedPix);
    e.bakedZ.setAll(0, from.bakedZ);
    e.kinds.setAll(0, from.kinds);
    e.ground.setAll(0, from.ground);
    e.groundZ.setAll(0, from.groundZ);
    e.staticShadow.setAll(0, from.staticShadow);
    e.shadowMask.setAll(0, from.shadowMask);
    e.tufts
      ..clear()
      ..addAll(from.tufts);
    e.leaves
      ..clear()
      ..addAll(from.leaves);
    e.glints.clear();
  }

  // mostrador-set.html: frame (what the reference made: the bake at wind time t, no characters; the set has no wind)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
