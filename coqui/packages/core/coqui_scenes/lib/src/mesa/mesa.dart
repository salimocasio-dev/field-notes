// Port of historia/escenas/mesa.js: the scene "La mesa", abuela's kitchen table (order 37b). Line for line, minus its
// background functions `fondo` and `mkPuesto`, the old table `mkMesa` and the lit oven (the sheet's `dropped`: the set's,
// by its key `mantel`, `horno`); every screen position replaced by what the sheet's `code` list gives for its line
// (mesa_places.dart), and the places the sheet's `moves` list moves, each at its line (the moved source's own numbers:
// MesaPlaces.to). mesa.js is written on the kit, so this is an `Escena`; its set is [MesaSet].
//
// What La mesa's sheet has that the earlier ones did not, or uses differently, and how it is kept here (as
// mesa-preview.html keeps it):
// - The seats stepped down the table (`SD`, moves line 21): whoever sits at seat i has their feet at 150 + SD[i]; what
//   stands at a place (FILA + SD[i]) and what is spilt in front of it (FRENTE + SD[i]) step down with it; the walkway
//   behind the chairs (`PASO`); the places in front of each seat for the frog (FRX, FR, FT), Luis (FL), abuela (FAX,
//   FA), Canelo (FP) and what falls (FC, FI), moves line 24.
// - The doorway (`PUERTA`, moves line 21): whoever comes in to sit appears on the patio's step outside, seen in the
//   opening, and whoever leaves goes there; the left wall, the door's frame and reveal and the threshold are front parts
//   drawn over whoever is behind them (`front`).
// - The draw order "as it is drawn" (`front`), as El banco's: every item of the sorted list owns the pixels it drew last
//   ([Mesa.item]); at each front part's entry (the table, its legs, the chairs, their legs, the counters, the stove, the
//   wall, the door's frame, threshold and reveal: all after everyone) the set's own pixels of the part are drawn again
//   only where the pixel's owner stands behind them, never a chair over whoever sits ([Mesa.front], [Mesa.frontBox]).
// - The cards' place per story (`respEn`, moves lines 241, 273, 311: set by the stories' inicio acts).
// - A story file's own moves come before the general moves (`storyMoves`, mesa-preview.html remapRule): the pairs of
//   cual-mesa ([Mesa.placePair]).
// - The pair `cocina.no` is drawn on another scene's set (El colmado's stall, frutas-set.html?surtido=frutas), which is
//   not in Dart yet: a stored still ([mesaFrutas]), its set key `frutas`, abuela drawn on it at the sheet's spot.
// - `talk`: each face measured from its sprite as it is drawn ([Mesa.faceOf]), the rounds card a rectangle.
// - `shadows` on the clear floor only; `hops`: one pair changes (frog.ranaa - rana.2, 3 to 2), walked in no run.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/mesa/mesa_places.dart';
import 'package:coqui_scenes/src/mesa/mesa_set.dart';
import 'package:coqui_scenes/src/mesa/mesa_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "mesa", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It draws
/// its random numbers (acts.elige25) from [rng], the game's one random source.
Scene createMesa({Rng? rng}) => Mesa(sheetOf('mesa'), rng: rng);

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: `x || 0` for a number of W
num _n(Object? v) => jsTruthy(v) ? v as num : 0;

// JavaScript: `+x` (a number, or a story's string)
num _plus(Object? v) => v is num
    ? v
    : v is String
    ? (num.tryParse(v.trim()) ?? (v.trim().isEmpty ? 0 : double.nan))
    : v == null
    ? double.nan
    : (v == true ? 1 : 0);

// JavaScript: Math.hypot
double _hypot(num a, num b) => math.sqrt(a * a + b * b);

// JavaScript: `p.dir < 0` (a missing dir is not)
num _dir(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num ? p['dir'] as num : 0;

// JavaScript: `al <= .5` (a missing `al` is not)
bool _atMostHalf(Object? al) => al is num && al <= .5;

// JavaScript: `String(k || "")`
String _str(Object? k) => !jsTruthy(k) ? '' : (k is num ? jsNum(k) : '$k');

// JavaScript: how `"" + v` writes a value of W (estado)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

// mesa.js: solo
String solo(Object? k) => _str(k)
    .replaceFirst(RegExp(r'^di_'), '')
    .replaceFirstMapped(RegExp(r'^(plato|taza|comida|vaso)s$'), (m) => m[1]!);

// mesa.js: cual
String cual(Object? k0) {
  final k = solo(k0);
  return k == 'hambre' || k == 'comida' ? 'comida' : 'agua';
}

// mesa.js: cosaDe
Map<String, dynamic> cosaDe(Object? k) => cual(k) == 'comida'
    ? <String, dynamic>{'k': 'plato', 'con': 'comida'}
    : <String, dynamic>{'k': 'vaso', 'con': 'agua'};

/// One entry of mesa.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is (mesa-preview.html,
/// sheet front.tags: `id` for a person or the frog, `perro` for Canelo, `mesa` for the places at the table, `cosa` for a
/// thing of W.cosas or W.suelo, `front` for a part of the set drawn again).
class MesaItem {
  MesaItem(
    this.y,
    this.d, {
    this.id,
    this.perro = false,
    this.mesa = false,
    this.cosa,
    this.front,
  });

  final num y;
  final void Function() d;
  final String? id, front;
  final bool perro, mesa;
  final Map<String, dynamic>? cosa;
}

/// What the set's parts in front are, by state key: each part's pixels (index), recorded at a state's first bake.
final Map<String, Map<String, Int32List>> _frontPixels = {};

class Mesa extends Escena implements SetScene, SetOverSprites, PairPlaces {
  /// [rng] is the game's one random source (mesa.js acts.elige25: `Math.random()`): the story runner's. A scene made
  /// without it (a picture, a test of its sprites) draws no random number.
  Mesa(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = MesaPlaces(sheet, mesaEngine());
    final p = _p;
    _geo = MesaPlan(p.e);
    // mesa.js:21 PISO (the old floor's first row: the set's floor, no place), MESA (the table: the set's, its box the
    // sheet's things.mesa; MESA[1] + MESA[3] is still the row its places are sorted by, moves line 171), SILLA (spots
    // silla.i: the seats' x, unchanged), MOSTR (the counter: the set's; MOSTR[1] the row ENQ keeps), ESTUFA (the stove:
    // the set's, its things moved onto its top, moves line 159), FILA, FRENTE (moves line 21: unchanged, + SD[i])
    MESA = [
      for (final v in const [92, 130, 96, 30]) p.keep(21, v).toInt(),
    ];
    SILLA = [
      for (final x in const [104, 128, 152, 176]) p.floor(21, x, 150)[0],
    ];
    MOSTR = [
      for (final v in const [24, 106, 62, 12]) p.keep(21, v).toInt(),
    ];
    ESTUFA = [
      for (final v in const [190, 104, 30, 42]) p.keep(21, v).toInt(),
    ];
    final l21 = p.to(
      21,
      'FILA=148,FRENTE=157;',
      RegExp(
        r'^FILA=(\d+),FRENTE=(\d+),SD=\[(-?\d+),(-?\d+),(-?\d+),(-?\d+)\],PUERTA=\[(\d+),(\d+)\],PASO=x=>Math\.round\(([\d.]+)\+x/(\d+)\);$',
      ),
    );
    FILA = l21[0].toInt();
    FRENTE = l21[1].toInt();
    SD = [for (final v in l21.sublist(2, 6)) v.toInt()];
    PUERTA = [l21[6].toInt(), l21[7].toInt()];
    _paso = [l21[8], l21[9]];
    // mesa.js:23 EN (moves line 23: each kind of thing on the counter moved onto its top) and ENQ (the old EN: where
    // the frog, abuela and Canelo stand at the counter)
    final l23 = p.to(
      23,
      'const EN={platos:[36,MOSTR[1]+7],tazas:[54,MOSTR[1]+6],bandeja:[44,MOSTR[1]+8],comidas:[38,MOSTR[1]+8],vasos:[61,MOSTR[1]+8],jarron:[78,MOSTR[1]+6]};',
      RegExp(
        r'^const EN=\{platos:\[(\d+),(\d+)\],tazas:\[(\d+),(\d+)\],bandeja:\[(\d+),(\d+)\],comidas:\[(\d+),(\d+)\],vasos:\[(\d+),(\d+)\],jarron:\[(\d+),(\d+)\]\},ENQ=\{platos:\[(\d+),MOSTR\[1\]\+(\d+)\],tazas:\[(\d+),MOSTR\[1\]\+(\d+)\],bandeja:\[(\d+),MOSTR\[1\]\+(\d+)\],comidas:\[(\d+),MOSTR\[1\]\+(\d+)\],vasos:\[(\d+),MOSTR\[1\]\+(\d+)\],jarron:\[(\d+),MOSTR\[1\]\+(\d+)\]\};$',
      ),
    );
    const kinds = ['platos', 'tazas', 'bandeja', 'comidas', 'vasos', 'jarron'];
    EN = {
      for (var i = 0; i < 6; i++)
        kinds[i]: [l23[i * 2].toInt(), l23[i * 2 + 1].toInt()],
    };
    ENQ = {
      for (var i = 0; i < 6; i++)
        kinds[i]: [
          l23[12 + i * 2].toInt(),
          MOSTR[1] + l23[12 + i * 2 + 1].toInt(),
        ],
    };
    // mesa.js:24 LUIS, CAN (the floor rule, spots luis, canelo), FOGON (moves line 24: spot fogon) and the places in
    // front of each seat (moves line 24: FRX, FAX, FR, FT, FL, FA, FP, FC, FI)
    const fronts = ['FRX', 'FAX', 'FR', 'FT', 'FL', 'FA', 'FP', 'FC', 'FI'];
    final l24 = p.to(
      24,
      'const LUIS=[75,160],FOGON=[205,170],CAN=[196,204];',
      RegExp(
        '^const LUIS=\\[(\\d+),(\\d+)\\],FOGON=\\[(\\d+),(\\d+)\\],CAN=\\[(\\d+),(\\d+)\\],'
        '${[for (final k in fronts) '$k=\\[(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)\\]'].join(',')};\$',
      ),
    );
    LUIS = p.floor(24, l24[0], l24[1]);
    FOGON = [l24[2].toInt(), l24[3].toInt()];
    CAN = p.floor(24, l24[4], l24[5]);
    List<int> four(int k) => [
      for (var j = 0; j < 4; j++) l24[6 + k * 4 + j].toInt(),
    ];
    FRX = four(0);
    FAX = four(1);
    FR = four(2);
    FT = four(3);
    FL = four(4);
    FA = four(5);
    FP = four(6);
    FC = four(7);
    FI = four(8);
    // mesa.js:119 LUGAR (sheet: lugar, the frog's spots frog.inicio, frog.centro)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // mesa.js:373 CAM and heartAt (code line 373: views.wide, points.corazon)
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _talk = sheet.talk!;
    // moves lines 241, 273, 311: where the answer cards stand in each story (W.respEn, set by its inicio act)
    _respEn24 = _respEnOf(241, 'async inicio24(){W.mantel=1;');
    _respEn25 = _respEnOf(273, 'async inicio25(){W.mantel=1;');
    _respEn26 = _respEnOf(311, 'async inicio26(){W.mantel=0;');
    // moves line 238: where abuela waits in the middle (acts.abuelaa centro)
    _centro = [
      for (final v in p.to(238, 'await mueve("abuela",142,207)')) v.toInt(),
    ];
    // moves line 353: abuela gives Canelo his bone 3 rows lower (`CAN[0]-34,CAN[1]-8+3`)
    _hueso = [
      for (final v in p.to(
        353,
        'await mueve("abuela",CAN[0]-34,CAN[1]-8);',
        RegExp(r'CAN\[0\]-(\d+),CAN\[1\]-(\d+)\+(\d+)\)'),
      ))
        v.toInt(),
    ];
    // mesa.js:121 to :132 COSAS (sheet: code line 130, things.olla, things.mesa, things.estufa; :132 the kitchen:
    // things.<id>.box, hand and hintBox; lines 121 to 129: the people's, the counter's stacks', the shown thing's,
    // abuela's offer's, the baby's and Canelo's boxes relative to them, unchanged)
    cosas = [
      for (final id in QUIEN.keys) persona(id),
      for (final k in const ['platos', 'tazas', 'bandeja', 'comidas', 'vasos'])
        enMostr(k),
      Thing(
        id: 'muestra',
        si: (w) => jsTruthy(w['muestra']),
        box: (Map<String, dynamic> w) {
          final m = w['muestra'] as Map<String, dynamic>;
          final g = jsTruthy(m['g']);
          return [
            (m['x'] as num) - 9,
            (m['y'] as num) - (g ? 38 : 14),
            18,
            g ? 40 : 16,
          ];
        },
        m: 0,
      ),
      Thing(
        id: 'ofrece',
        si: (w) {
          final ab = (w['gente'] as Map?)?['abuela'] as Map?;
          return ab != null && jsTruthy(ab['ofrece']);
        },
        box: (Map<String, dynamic> w) {
          final p = (w['gente'] as Map)['abuela'] as Map<String, dynamic>;
          return [
            _round(p['x'] as num) - 29,
            _round(p['y'] as num) - 42,
            20,
            18,
          ];
        },
        m: 0,
      ),
      Thing(
        id: 'bebe',
        si: (w) {
          final m = (w['gente'] as Map?)?['mama'] as Map?;
          return m != null && jsTruthy(m['bebe']) && m['vis'] != 0;
        },
        box: (Map<String, dynamic> w) {
          final p = (w['gente'] as Map)['mama'] as Map<String, dynamic>;
          return [
            _round(p['x'] as num) + 3,
            _round(p['y'] as num) - 38,
            18,
            18,
          ];
        },
        m: 1,
      ),
      Thing(
        id: 'perro',
        si: (w) => jsTruthy(w['perro']) && (w['perro'] as Map)['vis'] != 0,
        box: (Map<String, dynamic> w) {
          final o = w['perro'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 14,
            _round(o['y'] as num) - 20,
            28,
            22,
          ];
        },
        m: 1,
      ),
      Thing(
        id: 'olla',
        si: (w) =>
            jsTruthy(w['estufa']) && jsTruthy((w['estufa'] as Map)['olla']),
        box: p.box('olla'),
        m: 1,
      ),
      for (final id in const ['mesa', 'estufa', 'cocina'])
        Thing(
          id: id,
          box: p.box(id),
          hand: p.hand(id),
          hintBox: p.hintBox(id),
          m: 0,
        ),
    ];
  }

  @override
  final Sheet sheet;

  late final MesaPlaces _p;

  // the set's geometry (mesa-set.html MESA_SET: Gs, ZS, surfaceAt, the origin), which the preview's functions read
  // (CUR.set): the same for every state
  late final MesaPlan _geo;

  @override
  String get id => 'mesa';

  @override
  PpEngine newEngine({bool still = false}) => mesaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  /// The scene's places, read from its sheet (mesa_places.dart).
  MesaPlaces get places => _p;

  /// The set's plan (mesa-set.html: Gs, the seats, the table, surfaceAt).
  MesaPlan get plan => _geo;

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
  Map<String, dynamic> get V => host.V;
  int get F => host.F;
  Sfx get SFX => host.SFX;
  Future<void> wait(num ms) => host.wait(ms);
  int get TICK => host.TICK;
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      host.frogBox(q);
  Future<void> hopTo(num x, num y, int n, [num? s]) => host.hopTo(x, y, n, s);
  Sprite spr(String k, Sprite Function() make) => host.lib.spr(k, make);

  // DECISION(order 31b, as El balcón's, La sala's, El patio's, El camino's and El lago's): the scene's random draws come
  // from the game's one Rng, as Math.random was one: the one the registry's factory is given (`createMesa`, from the
  // story runner's `rng`)
  final Rng? _rngGiven;
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'La mesa was made without a random source (Rng) but draws a random number',
      ));

  /* ---------- the constants (mesa.js:21 to :27, :111, :119) ---------- */

  late final List<int> MESA, SILLA, MOSTR, ESTUFA;
  late final int FILA, FRENTE;
  late final List<int> SD, PUERTA;
  late final List<num> _paso;
  late final Map<String, List<int>> EN, ENQ;
  late final List<int> LUIS, FOGON, CAN;
  late final List<int> FRX, FAX, FR, FT, FL, FA, FP, FC, FI;
  late final List<int> _respEn24, _respEn25, _respEn26, _centro, _hueso;

  List<int> _respEnOf(int line, String src) => [
    for (final v in _p.to(line, src, RegExp(r'W\.respEn=\[(\d+),(\d+)\];')))
      v.toInt(),
  ];

  // moves line 21: PASO. The row of the walkway behind the chairs at x (the world line y = 2.2)
  int PASO(num x) => _round(_paso[0] + x / _paso[1]);

  // mesa.js:25
  static const Map<String, String> UTIL = {
    'sopa': 'cuchara',
    'espa': 'tenedor',
    'pan': 'cuchillo',
  };
  static const Map<String, String> PLATODE = {
    'cuchara': 'sopa',
    'tenedor': 'espa',
    'cuchillo': 'pan',
  };
  static const Map<String, String> TINTE = {
    'sopa': '#E8A030',
    'espa': '#D0302A',
    'pan': '#F0D040',
  };

  // mesa.js:111 BX
  static const Map<String, int> BX = {
    'cuchara': -9,
    'tenedor': 0,
    'cuchillo': 9,
  };

  // mesa.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  /* ---------- the people ---------- */

  // mesa.js:22 QUIEN. abuela is drawn by her own sprites (null)
  static final Map<String, Who?> QUIEN = {
    'luis': FAM['hermano']!,
    'carmen': FAM['hermana']!,
    'abuelo': FAM['abuelo']!,
    'mama': FAM['mama']!,
    'papa': FAM['papa']!,
    'abuela': null,
  };

  // JavaScript: `(QUIEN[id]||{}).nino`
  static bool _nino(String id) => QUIEN[id]?.nino ?? false;

  // mesa.js: G
  Map<String, dynamic>? G(Object? id) =>
      (W['gente'] as Map<String, dynamic>?)?['$id'] as Map<String, dynamic>?;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic> get _sitio => W['sitio'] as Map<String, dynamic>;
  List get _puestos => W['puestos'] as List;
  Map<String, dynamic>? _puesto(Object? i) => i is num
      ? _puestos[i.toInt()] as Map<String, dynamic>?
      : (throw StateError('mesa: no place at the table for $i'));

  // mesa.js: alto
  int alto(String id) {
    final p = G(id);
    final sent = p != null && jsTruthy(p['sent']);
    return id == 'abuela'
        ? 51
        : _nino(id)
        ? (sent ? 37 : 44)
        : (sent ? 49 : 56);
  }

  // mesa.js: caja (moves line 121: whoever sits is touched down to their feet row + 1, relative to them)
  List<num>? caja(String id) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return null;
    final h = alto(id), x = _round(p['x'] as num), y = _round(p['y'] as num);
    return jsTruthy(p['sent'])
        ? [x - 11, y - h, 22, h + 1]
        : [x - 11, y - h, 22, h];
  }

  // mesa.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // mesa.js: enMostr (its box relative to EN, which moves line 23 moved)
  Thing enMostr(String k) => Thing(
    id: k,
    m: 2,
    z: true,
    si: (w) => jsTruthy(w['mostrador']) && jsTruthy((w['mostrador'] as Map)[k]),
    box: (Map<String, dynamic> w) {
      final e = EN[k]!;
      return k == 'comidas'
          ? [e[0] - 15, e[1] - 16, 30, 18]
          : k == 'vasos'
          ? [e[0] - 9, e[1] - 18, 19, 20]
          : [e[0] - 12, e[1] - 18, 24, 22];
    },
  );

  // mesa.js: COSAS
  @override
  late final List<Thing> cosas;

  // mesa.js: fresh (code line 374: respEn, the frog's home and first place, unchanged)
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final cq = _p.floor(374, 104, 161);
    return {
      'respEn': [
        for (final v in const [125, 28]) _p.keep(374, v),
      ],
      'gente': <String, dynamic>{},
      'sitio': <String, dynamic>{},
      'puestos': <dynamic>[
        for (var i = 0; i < 4; i++)
          <String, dynamic>{
            'plato': null,
            'taza': null,
            'uts': <dynamic>[],
            'frente': <dynamic>[],
          },
      ],
      'mostrador': <String, dynamic>{},
      'estufa': <String, dynamic>{},
      'mantel': 0,
      'cosas': <dynamic>[],
      'afuera': 0,
      'vuelos': <dynamic>[],
      'suelo': <dynamic>[],
      'vacios': <dynamic>[],
      'bandeja': <dynamic>[],
      'origen': <String, dynamic>{},
      'tuvo': <String, dynamic>{},
      'perdio': <String, dynamic>{},
      'reb': 3,
      'choc': 9,
      'contado': 0,
      'perro': null,
      'encima': null,
      'muestra': null,
      'vierte': null,
      'casa': <dynamic>[..._p.floor(374, 120, 188)],
      'tarjeta': null,
      'marcas': null,
      'cq': <String, dynamic>{
        'x': cq[0],
        'y': cq[1],
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
        'hace': null,
        'piensa': null,
      },
    };
  }

  /* ---------- the set ---------- */

  /// The set key of the still of El colmado's stall under cual-mesa's cocina.no (W.afuera): not a state of La mesa's
  /// set; [buildSetFor] puts the still in place of a bake.
  static const String FRUTAS = 'frutas';

  // the sheet's setKey table: "m" + mantel + "h" + horno (setKey.params' words); W.afuera, the stall (one review
  // picture, cocina.no), is El colmado's: its stored still
  @override
  String setKey(Map<String, dynamic> W) {
    if (jsTruthy(W['afuera'])) return FRUTAS;
    final e = W['estufa'];
    final horno = jsTruthy(e) && jsTruthy((e as Map)['horno']) ? 1 : 0;
    return 'm${jsTruthy(W['mantel']) ? 1 : 0}h$horno';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    if (key == FRUTAS) return _bakeFrutas(e);
    final s = MesaSet(e, b, MesaState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the table's, the chairs',
    // the counters', the stove's, the wall's and the door's own pixels)
    final tag = !_frontPixels.containsKey(key);
    if (tag) s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    if (tag) {
      final tags = s.k.PART_TAGS!;
      _frontPixels[key] = {
        for (final part in sheet.frontParts.keys)
          part: Int32List.fromList([
            for (var i = 0; i < tags.length; i++)
              if (tags[i] == part) i,
          ]),
      };
      s.k.PART_TAGS = null;
    }
  }

  // DECISION(order 37b): cocina.no's picture is El colmado's stall (the sheet's pictures["cocina.no"].port), whose set
  // is not in Dart yet: its picture as frutas-set.html?surtido=frutas draws it, stored once (mesaFrutas), is the "baked
  // state": nothing of it is ground, nothing casts a shadow on it, nothing of it is drawn over anyone (no front parts)
  void _bakeFrutas(PpEngine e) {
    e.pix.setAll(0, mesaFrutas());
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.kinds.fillRange(0, e.kinds.length, 0);
    e.ground.fillRange(0, e.ground.length, 0);
    e.groundZ.setAll(0, e.zb);
    e.shadowMask.fillRange(0, e.shadowMask.length, 0);
    e.staticShadow.fillRange(0, e.staticShadow.length, 0);
    e.tufts.clear();
    e.leaves.clear();
    e.pendingShadows.clear();
    e.glints.clear();
    e.bakedPix.setAll(0, e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  /// The pixels of each front part in the baked state [key], once this scene has baked it (its first bake records them).
  Map<String, Int32List>? frontPixelsOf(String key) => _frontPixels[key];

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  /* ---------- the shadows (sheet: shadows), as mesa-preview.html casts them (PV.casts) ---------- */

  // the kitchen's one light: every shadow cast from the ground point under the thing's feet, on the clear floor only
  // (not under the table or a chair, not on a top): the frog at .3; each person standing at .3, .65, 1, 1.35, 1.7 (whoever
  // sits casts none: they are under the table's top); Canelo at .25; a thing lying on the floor (W.cosas with no z or z
  // 0, W.suelo) at .05. None on El colmado's stall.
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    if (jsTruthy(W['afuera'])) return out;
    final e = _p.e, SH = sheet.shadows;
    bool floor(num sx, num sy) {
      final s = _geo.surfaceAt(sx, sy);
      return s.on == 'floor' && s.under == null;
    }

    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q);
      if (floor(b.x + b.w / 2, (q['y'] as num) + 25)) {
        final g = e.unproject(b.x + b.w / 2, (q['y'] as num) + 25);
        out.add((x: g.x, y: g.y, z: .3, r: SH['coqui']!.radius));
      }
    }
    final radii = SH['people']!.radii!;
    final G = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          _atMostHalf(p['al']) ||
          jsTruthy(p['sent']) ||
          p['x'] == null) {
        continue;
      }
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      if (!floor(x, y - 1)) continue;
      final g = e.unproject(x, y - 1);
      final r = const ['luis', 'carmen'].contains(en.key)
          ? radii['nino']!
          : radii['adulto']!;
      for (final z in const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0 && pe['x'] != null) {
      final x = _round(pe['x'] as num), y = _round(pe['y'] as num);
      if (floor(x, y - 1)) {
        final g = e.unproject(x, y - 1);
        out.add((x: g.x, y: g.y, z: .25, r: SH['perro']!.radius));
      }
    }
    for (final v in [
      ...(W['cosas'] as List?) ?? const [],
      ...(W['suelo'] as List?) ?? const [],
    ]) {
      final o = v as Map<String, dynamic>?;
      if (o == null ||
          o['vis'] == 0 ||
          o['x'] == null ||
          !(o['z'] == null || o['z'] == 0)) {
        continue;
      }
      final x = _round(o['x'] as num), y = _round(o['y'] as num);
      if (!floor(x, y - 1)) continue;
      final g = e.unproject(x, y - 1);
      out.add((x: g.x, y: g.y, z: .05, r: SH['cosas']!.radius));
    }
    return out;
  }

  /* ---------- the set's parts in front, as it is drawn (sheet: front) ---------- */

  // mesa-preview.html: vOf. The v = (x + y) / R2 of the surface at height z under a screen point
  double vOf(num sx, num sy, [num z = 0]) {
    final g = _geo.Gs(sx, sy, z);
    return (g[0] + g[1]) / math.sqrt2;
  }

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // mesa-preview.html: PV.OWN, which item drew each pixel last (null: none)
  List<MesaItem?>? _own;

  // the set as this frame shows it (shadows), before the sprite layer (drawFrame's step 4), and its depth
  // (mesa-preview.html: `CUR.img`, `CUR.z`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // mesa-preview.html: PV.item. Every item of the sorted list owns the pixels it drew last (their colour changed); a
  // front part's entry draws the set's own pixels again (PV.front). A frame drawn with no set (a player with no screen)
  // keeps no owners.
  void item(MesaItem o) {
    if (o.front != null) return o.d();
    final e = _frameEngine;
    if (e == null) return o.d();
    final own = _own ??= List<MesaItem?>.filled(e.W * e.H, null);
    final pix = e.pix, before = Uint32List.fromList(pix);
    o.d();
    for (var i = 0; i < pix.length; i++) {
      if ((pix[i] ^ before[i]) & 0xFFFFFF != 0) own[i] = o;
    }
  }

  // mesa-preview.html: PV.front (sheet: front). At a front part's entry, the set's own pixels of the part are drawn
  // again where the pixel's owner stands behind them: z[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the owner's
  // plane (frontBox); a chair never over whoever sits (sheet front.chairs).
  void front(String part) {
    final e = _frameEngine, s = _setFrame, Z = _setZ, O = _own;
    if (e == null || s == null || Z == null || O == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'mesa: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final pix = e.pix, W0 = e.W, chairs = part.startsWith('sillas');
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final cache = <MesaItem, double?>{};
    for (final i in list) {
      final o = O[i];
      if (o == null) continue;
      if (chairs && o.id != null) {
        final g = gente[o.id] as Map<String, dynamic>?;
        if (g != null && jsTruthy(g['sent'])) continue;
      }
      final r = cache.containsKey(o) ? cache[o] : (cache[o] = frontBox(o, W));
      if (r == null) continue;
      final y = i ~/ W0;
      if (!(Z[i] > r / COS - (y + .5 - e.OY) * T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  // mesa-preview.html: PV.frontBox. A list item's plane (the v of the surface it stands on, sheet front.how): whoever
  // sits, their lap on the seat (+ .03); the frog, the floor under (b.x + b.w / 2, q.y + 25); anyone else, the floor
  // under their foot; Canelo the same; the places at the table: none (never drawn over); a thing on the floor (or on the
  // wall's side of it), the floor under it; on a top: none. Anything else (the pulled cloth) is not drawn over.
  double? frontBox(MesaItem o, Map<String, dynamic> w) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return vOf(b.x + b.w / 2, (q['y'] as num) + 25);
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>?;
      if (p == null) return null;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return jsTruthy(p['sent'])
          ? vOf(x, y - 8, MesaPlan.ZS) + .03
          : vOf(x, y - 1);
    }
    if (o.perro) {
      final p = w['perro'] as Map<String, dynamic>;
      return vOf(_round(p['x'] as num), _round(p['y'] as num) - 1);
    }
    if (o.mesa) return null;
    if (o.cosa != null) {
      final p = o.cosa!,
          x = _round(p['x'] as num),
          y = _round(p['y'] as num),
          s = _geo.surfaceAt(x, y - 1);
      return s.on == 'floor' || s.on == 'wall' ? vOf(x, y - 1) : null;
    }
    return null;
  }

  /* ---------- drawing ---------- */

  // mesa.js: cosa (here cosaSpr: the kit's Escena has a cosa of its own, a thing by its key)
  Sprite cosaSpr(String k, [Object? c]) => spr(
    'ms$k${c == null ? '' : _js(c)}',
    () => (COSA[k] ?? COSA['plato']!)(c),
  );

  // mesa.js: tenida
  void tenida(Ctx c, String k, num x, num y, [num? ang, num? esc, Object? v]) {
    final im = cosaSpr(k, v);
    if (jsTruthy(ang) || jsTruthy(esc)) {
      c.save();
      c.translate(_round(x).toDouble(), _round(y).toDouble());
      if (jsTruthy(ang)) c.rotate(ang!.toDouble());
      if (jsTruthy(esc)) c.scale(esc!.toDouble(), esc.toDouble());
      c.drawImage(im, -(im.w >> 1), -im.h);
      c.restore();
    } else {
      c.drawImage(im, _round(x) - (im.w >> 1), _round(y) - im.h);
    }
  }

  // mesa.js: conTodo. A plate or a cup with what is in it
  void conTodo(Ctx c, Map<String, dynamic> o, num x, num y) {
    final k = o['k'], con = o['con'];
    if (k == 'plato') {
      final n = jsTruthy(o['n']) ? (o['n'] as num).toInt() : 1,
          hondo = con == 'sopa';
      for (var j = 0; j < n; j++) {
        if (j == 1 && jsTruthy(o['plano'])) {
          fr(c, x - 6, y - 4, 12, 2, OUT);
          fr(c, x - 5, y - 4, 10, 1, hx('#E8B050'));
        }
        tenida(c, hondo && j == n - 1 ? 'hondo' : 'plato', x, y - j * 3);
      }
      final yt = y - (n - 1) * 3;
      if (con == 'bizcocho') {
        tenida(c, 'bizcocho', x, yt - 2);
      } else if (con == 'choco') {
        tenida(c, 'charco', x, yt - 1);
      } else if (con == 'espa' || con == 'pan' || con == 'comida') {
        tenida(c, con as String, x, yt - 2);
      }
      if (jsTruthy(o['vapor'])) {
        final t = (F >> 3) % 2;
        fr(c, x - 3 + t, yt - 10, 1, 3, hx('#FFFFFF'));
        fr(c, x + 1 - t, yt - 12, 1, 3, hx('#FFFFFF'));
        fr(c, x + 4 + t, yt - 9, 1, 2, hx('#FFFFFF'));
      }
      if (con == 'migas') {
        fr(c, x - 3, yt - 4, 1, 1, hx('#C89A40'));
        fr(c, x + 2, yt - 5, 1, 1, hx('#C89A40'));
        fr(c, x, yt - 3, 1, 1, hx('#C89A40'));
      }
      return;
    }
    if (k == 'taza') {
      final n = jsTruthy(o['n']) ? (o['n'] as num).toInt() : 1;
      tenida(c, con == 'choco' && n == 1 ? 'tazall' : 'taza', x, y);
      if (n > 1) tenida(c, con == 'choco' ? 'tazall' : 'taza', x + 1, y - 4);
      if (con == 'choco') {
        final t = (F >> 3) % 2;
        fr(c, x - 3 + t, y - 13, 1, 2, hx('#FFFFFF'));
        fr(c, x - t, y - 15, 1, 2, hx('#FFFFFF'));
      }
      return;
    }
    if (k == 'vaso') {
      tenida(c, con == 'agua' ? 'vaso' : 'vacio', x, y);
      return;
    }
    tenida(c, '$k', x, y);
  }

  // mesa.js: fila. What stands at a place, left to right, with the x of each
  List<({String key, Map<String, dynamic> o, num x, num dy})> fila(int i) {
    final L = <({String key, Map<String, dynamic> o, num x, num dy})>[];
    final ps = i < _puestos.length
        ? _puestos[i] as Map<String, dynamic>?
        : null;
    if (ps == null) return L;
    String? q;
    for (final en in ((W['sitio'] as Map?) ?? const {}).entries) {
      if (en.value == i) {
        q = en.key as String;
        break;
      }
    }
    final gq = q == null ? null : G(q);
    final bebe = gq != null && gq['hace'] == 'bebe';
    final tz = jsTruthy(ps['taza']) && !bebe, dos = jsTruthy(ps['plato']) && tz;
    if (tz) {
      final t = ps['taza'] as Map<String, dynamic>;
      L.add((
        key: 'taza',
        o: <String, dynamic>{...t, 'k': jsTruthy(t['k']) ? t['k'] : 'taza'},
        x: SILLA[i] + (dos ? 6 : 0),
        dy: dos ? -3 : 0,
      ));
    }
    if (jsTruthy(ps['plato'])) {
      L.add((
        key: 'plato',
        o: <String, dynamic>{
          'k': 'plato',
          ...ps['plato'] as Map<String, dynamic>,
        },
        x: SILLA[i] - (dos ? 4 : 0),
        dy: 0,
      ));
    }
    return L;
  }

  // mesa.js: xDe, dyDe
  num xDe(int i, String key) {
    for (final e in fila(i)) {
      if (e.key == key) return e.x;
    }
    return SILLA[i];
  }

  num dyDe(int i, String key) {
    for (final e in fila(i)) {
      if (e.key == key) return e.dy;
    }
    return 0;
  }

  // mesa.js: nube. A thought: what he would like
  void nube(Ctx g, num x, num y, Map<String, dynamic> o) {
    fr(g, x - 1, y - 1, 24, 20, OUT);
    fr(g, x, y, 22, 18, hx('#FFFFFF'));
    fr(g, x - 4, y + 17, 4, 4, OUT);
    fr(g, x - 3, y + 18, 2, 2, hx('#FFFFFF'));
    fr(g, x - 8, y + 22, 3, 3, OUT);
    conTodo(g, o, x + 11, y + 16);
  }

  // JavaScript: `typeof v === "string" ? {k: v} : v`
  static Map<String, dynamic> _cosa(Object? v) =>
      v is String ? <String, dynamic>{'k': v} : v as Map<String, dynamic>;

  // mesa.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final w = QUIEN[id],
        x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        d = _dir(p) < 0 ? -1 : 1;
    final paso = jsTruthy(p['paso']) && a % 2 != 0;
    if (id == 'abuela') {
      final ps = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      final top = y - 50 + (paso ? -1 : 0);
      c.save();
      c.translate(x.toDouble(), top.toDouble());
      if (d < 0) c.scale(-1, 1);
      c.drawImage(spr('ab$ps$habla', () => mkAbuela(ps, habla != 0)), -30, 0);
      c.restore();
      if (jsTruthy(p['lleva'])) {
        final l = p['lleva'] as String;
        tenida(
          c,
          l,
          x - 14,
          y - 17,
          0,
          0,
          l == 'tabla' ? math.max(0, math.min(3, W['reb'] as num)) : null,
        );
      }
      if (jsTruthy(p['lleva2'])) {
        tenida(c, p['lleva2'] as String, x + 13, y - 15);
      }
      if (jsTruthy(p['alza'])) {
        tenida(c, p['alza'] as String, x - 19, y - 18, 0, 2);
      }
      if (jsTruthy(p['ofrece'])) {
        fr(c, x - 16, y - 27, 7, 3, OUT);
        fr(c, x - 15, y - 26, 6, 2, RP.skin[2]);
        conTodo(c, p['ofrece'] as Map<String, dynamic>, x - 19, y - 26);
      }
      return;
    }
    final pose = p['pose'] == 'wave'
        ? 'wave${a % 2}'
        : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
    final sent = jsTruthy(p['sent']);
    final im = spr(
      'pm$id$pose$habla${sent ? 1 : 0}',
      () => mkPersona(w!, pose, habla != 0, sent),
    );
    final top = y - im.h + 1 + (paso ? -1 : 0) + _n(p['dy']);
    c.save();
    c.translate(x.toDouble(), top.toDouble());
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    if (jsTruthy(p['bebe'])) {
      final e = p['bebe'] == 1 ? 'idle' : p['bebe'] as String;
      final bi = spr('bb$e${a % 2}', () => mkBebe(e, a % 2 != 0));
      c.drawImage(bi, x - 1, y - (sent ? 39 : 40));
    }
    final nino = w?.nino ?? false;
    final hy = top + (nino ? 22 : 26);
    if (p['hace'] == 'come') {
      final que = p['que'];
      if (que == 'bizcocho' || que == 'pan' || que == 'panecillo') {
        tenida(
          c,
          que == 'pan' ? 'panecillo' : que as String,
          x + 5,
          hy + 4 + (a % 2) * 2,
        );
      } else {
        tenida(
          c,
          jsTruthy(que) ? que as String : 'cuchara',
          x + 6,
          hy + 12 + (a % 2) * 2,
        );
      }
    } else if (p['hace'] == 'bebe') {
      tenida(
        c,
        p['que'] == 'vaso' ? 'vaso' : 'tazall',
        x + 6,
        hy + 6 - (a % 2),
      );
    } else if (jsTruthy(p['mano'])) {
      // moves line 147: what a sitter holds lies at the table's edge in front of them, relative to them
      tenida(c, p['mano'] as String, x + 8, sent ? y - 13 : hy + 18);
    }
    if (jsTruthy(p['alza'])) {
      // held up to be seen, twice the size, in a raised hand beside the head
      final ax =
              x +
              (sent ? 10 : d * (jsTruthy(p['alzax']) ? p['alzax'] as num : 13)),
          ay = sent ? top + 25 : hy + 8;
      tenida(c, p['alza'] as String, ax, ay, 0, 2);
      fr(c, ax - 3, ay - 4, 6, 5, OUT);
      fr(c, ax - 2, ay - 3, 4, 3, (w?.piel ?? RP.skin)[2]);
    }
    if (jsTruthy(p['lleva'])) {
      final o = _cosa(p['lleva']);
      conTodo(c, o, x + d * 10, top + (nino ? 34 : 38));
      if (o['k'] == 'bandeja') {
        for (final k in (W['bandeja'] as List?) ?? const []) {
          tenida(
            c,
            k as String,
            x + d * 10 + BX[k]!,
            top + (nino ? 34 : 38) - 2,
          );
        }
      }
    }
    if (jsTruthy(p['lleva2'])) {
      final o = _cosa(p['lleva2']);
      conTodo(c, o, x - d * 10, top + (nino ? 34 : 38));
    }
  }

  // mesa.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op =
            (q['bub'] == 'hola' ||
                    host.TALK == 'coqui' ||
                    jsTruthy(q['hace'])) &&
                a % 2 != 0
            ? 1
            : 0,
        dy = _round(_n(q['dy'])),
        cx = b.x + (b.w.toInt() >> 1);
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    if (jsTruthy(W['encima'])) {
      conTodo(g, W['encima'] as Map<String, dynamic>, cx, b.y + dy + 3);
    }
  }

  // mesa.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // mesa.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    if (jsTruthy(W['afuera'])) return _drawAfuera(c, W, a);
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        M = (W['mostrador'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        E = (W['estufa'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // mesa.js:156 and :157, the background and the lit oven, are dropped (sheet: dropped): the set, for setKey(W)
    // on the stove (moves line 159: the pot and its lid over the left burner, the steam with it; line 160: the cake, the
    // jug and the pink cake on the top)
    final E0 = ESTUFA[0], E1 = ESTUFA[1];
    if (E['olla'] == 2) {
      tenida(c, 'ollavacia', E0 + 16, E1 + 5);
    } else if (jsTruthy(E['olla'])) {
      tenida(c, 'olla', E0 + 16, E1 + 5);
      if (jsTruthy(E['tapa'])) tenida(c, 'tapa', E0 + 16, E1 - 7);
      if (jsTruthy(E['vapor'])) {
        final t = (F >> 2) % 6;
        const st = [
          [9, -14],
          [14, -18],
          [18, -13],
        ];
        for (var i = 0; i < st.length; i++) {
          final p = st[i];
          fr(
            c,
            E0 + 3 + p[0] + ((t + i) % 3) - 1,
            E1 + 2 + p[1] - ((t + i * 2) % 6),
            2,
            3,
            hx('#FFFFFF'),
          );
        }
      }
    }
    if (jsTruthy(E['bizcocho'])) tenida(c, 'entero', E0 + 17, E1 + 5);
    if (jsTruthy(E['jarra'])) tenida(c, 'jarra', E0 + 24, E1 + 0);
    if (jsTruthy(E['pastel'])) tenida(c, 'pastel', E0 + 11, E1 + 6);
    // on the counter (EN: moves line 23)
    for (var i = 0; i < _n(M['platos']); i++) {
      tenida(c, 'plato', EN['platos']![0], EN['platos']![1] - i * 2);
    }
    for (var i = 0; i < _n(M['tazas']); i++) {
      tenida(
        c,
        'taza',
        EN['tazas']![0] - 5 + (i % 2) * 11,
        EN['tazas']![1] - (i >> 1) * 5,
      );
    }
    if (jsTruthy(M['bandeja'])) {
      final e = EN['bandeja']!;
      tenida(c, 'bandeja', e[0], e[1]);
      for (final k in (W['bandeja'] as List?) ?? const []) {
        tenida(c, k as String, e[0] + BX[k]!, e[1] - 2);
      }
    }
    for (var i = 0; i < _n(M['comidas']); i++) {
      conTodo(
        c,
        <String, dynamic>{'k': 'plato', 'con': 'comida'},
        EN['comidas']![0] - 7 + (i % 2) * 15,
        EN['comidas']![1] - (i >> 1) * 6,
      );
    }
    for (var i = 0; i < _n(M['vasos']); i++) {
      tenida(
        c,
        'vaso',
        EN['vasos']![0] - 4 + (i % 2) * 9,
        EN['vasos']![1] - (i >> 1) * 3,
      );
    }
    if (jsTruthy(M['jarron'])) {
      tenida(
        c,
        M['jarron'] == 2 ? 'jarronv' : 'jarron',
        EN['jarron']![0] + 4,
        EN['jarron']![1],
      );
    }
    final L = <MesaItem>[];
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(
          MesaItem(
            p['z'] != null ? p['z'] as num : p['y'] as num,
            () => gente(c, id, a),
            id: id,
          ),
        );
      }
    }
    // the places at the table (moves lines 171, 172, 173: sorted after whoever sits at every seat; each place's plate and
    // cup on the table's top at its seat, FILA + SD[i], sliding half a row a px when the cloth is pulled; what is spilt in
    // front of it, FRENTE + SD[i]); the old table itself (mkMesa) is the set's (dropped)
    if (!jsTruthy(W['afuera'])) {
      L.add(
        MesaItem(MESA[1] + MESA[3] + 6 + SD[3], () {
          final pu = (W['puestos'] as List?) ?? const [];
          for (var i = 0; i < pu.length; i++) {
            final ps = pu[i] as Map<String, dynamic>?;
            if (ps == null) continue;
            final dy = jsTruthy(ps['alza']) ? -12 : 0, dx = _n(ps['dx']);
            for (final e in fila(i)) {
              conTodo(
                c,
                e.o,
                e.x + dx,
                FILA + SD[i] + _round(dx / 2) + dy + e.dy,
              );
            }
            final fe = (ps['frente'] as List?) ?? const [];
            for (var j = 0; j < fe.length; j++) {
              final m = fe[j] as Map<String, dynamic>;
              final x = SILLA[i] - 4 + j * 7, y = FRENTE + SD[i] + (j % 2) * 2;
              if (m['k'] == 'mancha') {
                c.drawImage(cosaSpr('mancha', m['c']), x - 5, y - 7);
              } else if (jsTruthy(m['o'])) {
                conTodo(c, m['o'] as Map<String, dynamic>, x + 2, y);
              } else {
                tenida(c, m['k'] as String, x, y);
              }
            }
          }
        }, mesa: true),
      );
    }
    // the cloth the baby pulls (moves lines 174: after the places; its corner relative to mamá)
    if (jsTruthy(W['tiron']) && Gt['mama'] != null) {
      L.add(
        MesaItem(MESA[1] + MESA[3] + 7 + SD[3], () {
          final m = Gt['mama'] as Map<String, dynamic>,
              x = _round(m['x'] as num) + 8;
          final my = _round(m['y'] as num);
          for (var j = 0; j < 12; j++) {
            fr(
              c,
              x + 2 - (j >> 2),
              my - 30 + j,
              4,
              1,
              j % 3 != 0 ? hx('#FFFFFF') : hx('#E4E4EE'),
            );
          }
          fr(c, x, my - 19, 6, 2, hx('#D0302A'));
        }),
      );
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0) {
      L.add(
        MesaItem(pe['y'] as num, () {
          final o = pe, pose = o['pose'];
          final f =
              pose == 'bark' ||
                  pose == 'walk' ||
                  pose == 'eat' ||
                  jsTruthy(o['cola'])
              ? (a >> 1) % 2
              : 0;
          final im = spr(
            'pe${_jsPose(pose)}$f',
            () => mkPerro('$pose', f != 0),
          );
          c.save();
          c.translate(
            _round(o['x'] as num).toDouble(),
            (_round(o['y'] as num) - im.h + 2 - _n(o['dy'])).toDouble(),
          );
          if (_dir(o) < 0) c.scale(-1, 1);
          c.drawImage(im, -13, 0);
          c.restore();
          if (jsTruthy(o['lleva'])) {
            conTodo(
              c,
              o['lleva'] as Map<String, dynamic>,
              _round(o['x'] as num) + (o['dir'] as num) * 16,
              _round(o['y'] as num),
            );
          }
        }, perro: true),
      );
    }
    for (final v in (W['cosas'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>;
      if (o['vis'] != 0) {
        L.add(
          MesaItem(o['z'] != null ? o['z'] as num : (o['y'] as num) + 1, () {
            if (jsTruthy(o['rot'])) {
              tenida(
                c,
                o['k'] as String,
                o['x'] as num,
                o['y'] as num,
                o['rot'] as num,
              );
            } else {
              conTodo(c, o, o['x'] as num, o['y'] as num);
            }
          }, cosa: o),
        );
      }
    }
    for (final v in (W['suelo'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>;
      L.add(
        MesaItem(
          (o['y'] as num) - 4,
          () => tenida(
            c,
            o['k'] as String,
            o['x'] as num,
            o['y'] as num,
            o['rot'] as num?,
          ),
          cosa: o,
        ),
      );
    }
    if (jsTruthy(q['vis'])) {
      L.add(MesaItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    // the sorted list: the entries of the set's parts drawn again over whoever is behind them (sheet: front.parts, each
    // sortY 9999, after everyone); each item owns what it drew last (mesa-preview.html PV.item)
    for (final en in sheet.frontParts.entries) {
      final part = en.key;
      L.add(MesaItem(en.value.sortY!, () => front(part), front: part));
    }
    _own = null;
    // JavaScript's sort is stable: the index breaks a tie
    final byRow = [...L.indexed]
      ..sort((m, n) {
        final d = m.$2.y.compareTo(n.$2.y);
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    for (final o in byRow) {
      item(o.$2);
    }
    // things in the air, the jug that pours, what is held up to be looked at
    for (final v in [...(W['vuelos'] as List?) ?? const []]) {
      final o = v as Map<String, dynamic>;
      if (jsTruthy(o['rot'])) {
        tenida(
          c,
          o['k'] as String,
          o['x'] as num,
          o['y'] as num,
          o['rot'] as num,
        );
      } else {
        conTodo(c, o, o['x'] as num, o['y'] as num);
      }
    }
    final vi = W['vierte'] as Map<String, dynamic>?;
    if (vi != null) {
      tenida(c, 'jarra', (vi['x'] as num) + 9, (vi['y'] as num) - 6, -0.6);
      fr(
        c,
        (vi['x'] as num) + 1,
        (vi['y'] as num) - 10,
        2,
        jsTruthy(vi['h']) ? vi['h'] as num : 10,
        hx('#6A3214'),
      );
    }
    final mu = W['muestra'] as Map<String, dynamic>?;
    if (mu != null) {
      if (jsTruthy(mu['g'])) {
        tenida(c, mu['k'] as String, mu['x'] as num, mu['y'] as num, 0, 2);
      } else {
        conTodo(
          c,
          <String, dynamic>{'k': mu['k']},
          mu['x'] as num,
          mu['y'] as num,
        );
      }
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['piensa']) && p['vis'] != 0) {
        nube(
          c,
          _round(p['x'] as num) + 7,
          _round(p['y'] as num) - alto(id) - 21,
          cosaDe(p['piensa']),
        );
      }
    }
    if (jsTruthy(q['vis']) && jsTruthy(q['piensa'])) {
      final b = frogBox(q);
      nube(c, b.x + (b.w.toInt() >> 1) + 12, b.y - 24, cosaDe(q['piensa']));
    }
    // mesa.js:187 a person's bubble, where the sheet's talk puts it
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['bub']) && p['vis'] != 0) {
        final t = talkPlace(
          [_round(p['x'] as num), _round(p['y'] as num) - alto(id) - 1],
          6,
          p['bub'],
          W,
        );
        bub2(c, p['bub'] as String, t[0], t[1], a);
      }
    }
    // mesa.js:188 the frog's bubble, where the sheet's talk puts it
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = frogBox(q),
          t = talkPlace(
            [b.x + (b.w.toInt() >> 1), b.y + 2],
            b.w.toInt() >> 1,
            q['bub'],
            W,
          );
      bub2(c, q['bub'] as String, t[0], t[1], a);
    }
    // the set as framed is this frame's only (drawFrame gives it again before the next)
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
    _own = null;
  }

  // JavaScript: `"" + pose` of a pose that may be undefined
  static String _jsPose(Object? v) => v == null ? 'undefined' : '$v';

  // mesa-preview.html: PV.render with `scene: 'frutas'` (cual-mesa's cocina.no, W.afuera): over El colmado's stall
  // (the still the set key `frutas` puts in place) only the sprite layer's people are drawn, each as the scene draws
  // them, with what they hold, think and say; nothing else of mesa.js (its old stall, mkPuesto, is dropped; the places
  // at the table are skipped when W.afuera, as the old)
  void _drawAfuera(Ctx c, Map<String, dynamic> W, int a) {
    final Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      gente(c, id, a);
      if (jsTruthy(p['piensa'])) {
        nube(
          c,
          _round(p['x'] as num) + 7,
          _round(p['y'] as num) - alto(id) - 21,
          cosaDe(p['piensa']),
        );
      }
      if (jsTruthy(p['bub'])) {
        final t = talkPlace(
          [_round(p['x'] as num), _round(p['y'] as num) - alto(id) - 1],
          6,
          p['bub'],
          <String, dynamic>{
            ...W,
            'gente': <String, dynamic>{id: p},
          },
        );
        bub2(c, p['bub'] as String, t[0], t[1], a);
      }
    }
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
    _own = null;
  }

  // mesa-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
  // head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view, clear
  // of the corner card shown (W.tarjeta: talk.board + the view's x0, hidden while three picture bubbles stand at the top)
  // and of every face (PV.faces); if none is, [top].
  List<num> talkPlace(List<num> top, num h, Object? k, Map<String, dynamic> w) {
    if (!jsTruthy(k) || !sheet.bubbleRects.containsKey(k)) return top;
    final T = _talk, R = sheet.bubbleRects[k]!, x0 = host.cam[0];
    final faces = facesOf(w), boards = <List<num>>[];
    final resp = w['resp'];
    if (jsTruthy(w['tarjeta']) &&
        !(jsTruthy(resp) &&
            (resp as List).any(
              (q) => const ['cuchara', 'tenedor', 'cuchillo'].contains(q),
            ))) {
      boards.add([...T.boardRect!]);
    }
    for (var i = 0; i < boards.length; i++) {
      boards[i] = [boards[i][0] + x0, ...boards[i].skip(1)];
    }
    bool meets(List<num> a, List<num> b) =>
        a[0] < b[0] + b[2] &&
        b[0] < a[0] + a[2] &&
        a[1] < b[1] + b[3] &&
        b[1] < a[1] + a[3];
    for (final pl in T.places) {
      final tx = top[0] + pl.side * (h + 16),
          ty = top[1] + pl.dy,
          r = [tx + R[0], ty + R[1], R[2], R[3]];
      if (r[0] >= x0 &&
          r[1] >= 0 &&
          r[0] + r[2] <= x0 + 196 &&
          r[1] + r[3] <= 216 &&
          !boards.any((b) => meets(r, b)) &&
          !faces.any((f) => meets(r, f))) {
        return [tx, ty];
      }
    }
    return top;
  }

  // mesa-preview.html: FACE, PV.faceOf (sheet talk.faces). A face: the middle of the sprite's top 10 rows, 6 rows under
  // its top (eyes to chin), measured from the sprite as gente() draws it (pose, dir, sitting; a = 0, no talking): its x
  // off the person's x and its top off their y, by id, pose, dir and sitting
  final Map<String, List<num>> _face = {};

  List<num> faceOf(String id, Map<String, dynamic> p) {
    final d = _dir(p) < 0 ? -1 : 1, sent = jsTruthy(p['sent']);
    final key = '$id|${_str(p['pose'])}|$d|${sent ? 1 : 0}';
    final f = _face[key] ??= () {
      // gente() at (120, 150), frame a = 0
      final pose0 = p['pose'] == 'wave'
          ? 'wave0'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      final Sprite im;
      final int top, ox;
      final bool flip;
      if (id == 'abuela') {
        im = spr('ab${pose0}0', () => mkAbuela(pose0, false));
        top = 150 - 50;
        ox = -30;
        flip = d < 0;
      } else {
        im = spr(
          'pm$id${pose0}0${sent ? 1 : 0}',
          () => mkPersona(QUIEN[id]!, pose0, false, sent),
        );
        top = 150 - im.h + 1;
        ox = -PX;
        flip = (pose0 == 'offer' ? -d : d) < 0;
      }
      var first = -1;
      for (var r = 0; r < im.h && first < 0; r++) {
        for (var cc = 0; cc < im.w; cc++) {
          if (im.px[r * im.w + cc] >>> 24 != 0 &&
              im.px[r * im.w + cc] & 0xFFFFFF != 0) {
            first = r;
            break;
          }
        }
      }
      var lo = 1 << 30, hi = -(1 << 30);
      for (var r = first; r < im.h && r < first + 10; r++) {
        for (var cc = 0; cc < im.w; cc++) {
          final v = im.px[r * im.w + cc];
          if (v >>> 24 == 0 || v & 0xFFFFFF == 0) continue;
          final sx = flip ? 120 - ox - 1 - cc : 120 + ox + cc;
          lo = math.min(lo, sx);
          hi = math.max(hi, sx);
        }
      }
      return <num>[(lo + hi + 1) / 2 - 120, top + first - 150];
    }();
    final dy = _round(_n(p['dy']));
    return [
      _round(_round(p['x'] as num) + f[0] - 6),
      _round(p['y'] as num) + f[1] - dy + 6,
      12,
      10,
    ];
  }

  // mesa-preview.html: PV.faces. Every face shown: each person's (faceOf), the frog's
  List<List<num>> facesOf(Map<String, dynamic> w) {
    final faces = <List<num>>[];
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          (p['al'] != null && (p['al'] as num) < .5) ||
          p['x'] == null) {
        continue;
      }
      faces.add(faceOf(en.key, p));
    }
    final cq = w['cq'] as Map<String, dynamic>?;
    if (cq != null &&
        jsTruthy(cq['vis']) &&
        !(cq['al'] is num && (cq['al'] as num) < .5)) {
      final b = frogBox(cq);
      faces.add([
        b.x + 2,
        b.y + _round(_n(cq['dy'])),
        b.w - 4,
        _round(b.h * .6),
      ]);
    }
    return faces;
  }

  // mesa.js: talkAt (relative to the person: unchanged)
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final p =
        (W['gente'] as Map<String, dynamic>?)?[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    return [
      _round(p['x'] as num),
      _round(p['y'] as num) -
          alto(who) -
          1 -
          (jsTruthy(p['alza']) && jsTruthy(p['sent']) ? 12 : 0),
    ];
  }

  // mesa.js: respIcon. Picture bubbles: a spoon, a fork, a knife, drawn big
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    if (!COSA.containsKey(k)) return null;
    c.smoothing = false;
    tenida(c, k, x + (w.toInt() >> 1), y + h - 2, 0, 2);
    return null;
  }

  // mesa.js: hud. The card steps aside while three picture bubbles stand at the top
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c, resp = W['resp'];
    if (!jsTruthy(W['tarjeta']) ||
        (jsTruthy(resp) &&
            COSA.containsKey((resp as List).isEmpty ? null : resp[0]))) {
      return;
    }
    tarjeta(g, 3, 3, 66, 24);
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
    for (var i = 0; i < marcas.length; i++) {
      final m = marcas[i], x = 10 + i * 20, y = 6;
      if (m == 'ok') {
        const st = [
          '......#......',
          '.....###.....',
          '.....###.....',
          '#############',
          '.###########.',
          '..#########..',
          '...#######...',
          '..#########..',
          '.####...####.',
          '.###.....###.',
          '##.........##',
        ];
        g.fillStyle = OUT;
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii - 1, y + j + 1, 3, 3);
          }
        }
        g.fillStyle = hx('#F0C020');
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii, y + j + 2, 1, 1);
          }
        }
      } else if (jsTruthy(m)) {
        g.fillStyle = OUT;
        for (var k = 0; k < 11; k++) {
          g.fillRect(x + k, y + 1 + k, 4, 3);
          g.fillRect(x + 10 - k, y + 1 + k, 4, 3);
        }
        g.fillStyle = hx('#C8401E');
        for (var k = 0; k < 11; k++) {
          g.fillRect(x + 1 + k, y + 2 + k, 2, 1);
          g.fillRect(x + 11 - k, y + 2 + k, 2, 1);
        }
      } else {
        g.fillStyle = hx('#C8C8D4');
        g.fillRect(x + 1, y + 13, 12, 1);
        g.fillRect(x + 1, y + 1, 1, 12);
        g.fillRect(x + 12, y + 1, 1, 12);
        g.fillRect(x + 1, y + 1, 12, 1);
      }
    }
  }

  // mesa.js: marca
  void marca(Object? m) {
    final l = W['marcas'] as List?;
    final i = l == null ? -1 : l.indexOf(null);
    if (i >= 0) l![i] = m;
  }

  /* ---------- moving things ---------- */

  // mesa.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _round(_hypot(x - x0, y - y0) / 6));
    p['sent'] = 0;
    p['paso'] = 1;
    if ((x - x0).abs() > 3) p['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n;
      await wait(TICK);
    }
    p['x'] = x;
    p['y'] = y;
    p['paso'] = 0;
  }

  // mesa.js: vuela
  Future<void> vuela(
    Map<String, dynamic> o,
    num x0,
    num y0,
    num x1,
    num y1, [
    num? n0,
  ]) async {
    final v = <String, dynamic>{'x': x0, 'y': y0, ...o};
    final vuelos = W['vuelos'] as List;
    vuelos.add(v);
    final n = n0 != null && n0 != 0 ? n0 : 5;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      v['x'] = x0 + (x1 - x0) * t;
      v['y'] = y0 + (y1 - y0) * t - math.sin(t * math.pi) * 8;
      await wait(TICK);
    }
    final l = W['vuelos'] as List, j = l.indexOf(v);
    // JavaScript: `splice(-1, 1)` takes the last when it is gone
    if (j >= 0) {
      l.removeAt(j);
    } else if (l.isNotEmpty) {
      l.removeLast();
    }
  }

  // mesa.js: cx, pies
  num cx() => (_cq['x'] as num) + 16;
  num pies() => (_cq['y'] as num) + 27;

  // mesa.js: ranaA (the hop count by the distance, 40 px a hop, 1 to 3: the sheet's hops)
  Future<void> ranaA(num x, num y, [Object? h]) async {
    final q = _cq,
        d = _hypot(x - 16 - (q['x'] as num), y - 27 - (q['y'] as num));
    if (d < 3) return;
    await hopTo(
      _round(x - 16),
      _round(y - 27),
      (jsTruthy(h) ? _plus(h) : math.max(1, math.min(3, _round(d / 40))))
          .toInt(),
    );
  }

  // mesa.js: acasa
  Future<void> acasa() {
    final casa = W['casa'] as List;
    return ranaA(casa[0] as num, casa[1] as num);
  }

  // mesa.js: sitio
  Object? sitio(Object? a) => _sitio['$a'];

  // mesa.js: sienta (moves line 208: whoever is outside appears on the step outside the doorway, PUERTA, walks along the
  // walkway behind the chairs, PASO, to their chair and sits on it, 150 + SD[i])
  Future<void> sienta(String id, int i) async {
    final p = G(id)!;
    _sitio[id] = i;
    if (p['vis'] == 0) {
      p['vis'] = 1;
      p['x'] = PUERTA[0];
      p['y'] = PUERTA[1];
      p['sent'] = 0;
    }
    await mueve(id, p['x'] as num, PASO(p['x'] as num), 2);
    await mueve(id, SILLA[i], PASO(SILLA[i]));
    p['sent'] = 1;
    p['y'] = 150 + SD[i];
    p['dir'] = 1;
    SFX.blip();
  }

  // mesa.js: sale (moves line 209: up onto the walkway behind the chairs and out by the doorway)
  Future<void> sale(String id) async {
    final p = G(id)!;
    p['sent'] = 0;
    p['hace'] = null;
    p['mano'] = null;
    await mueve(id, p['x'] as num, PASO(p['x'] as num), 2);
    await mueve(id, PUERTA[0], PUERTA[1]);
    p['vis'] = 0;
    _sitio.remove(id);
  }

  // mesa.js: abuelaEn (moves line 210: she serves place i in front of the table, FAX, FA; she walks round the front of
  // the table, down or across to the lower row first)
  Future<void> abuelaEn(Object? i) async {
    final ab = G('abuela')!;
    final none = i is! num;
    final x = none ? FOGON[0] : SILLA[i.toInt()] + FAX[i.toInt()],
        y = none ? FOGON[1] : 204 + FA[i.toInt()];
    final ax = ab['x'] as num, ay = ab['y'] as num;
    if (_hypot(ax - x, ay - y) > 3) {
      final vy = math.max(ay, y), vx = ay < y ? ax : x;
      if (_hypot(ax - vx, ay - vy) > 3) await mueve('abuela', vx, vy);
      await mueve('abuela', x, y);
    }
    ab['dir'] = -1;
  }

  // mesa.js: alBebe
  void alBebe(bool si) {
    final m = G('mama'), ab = G('abuela');
    if (m == null || !jsTruthy(m['bebe']) || !jsTruthy(W['contado'])) return;
    m['bebe'] = si ? 'clap' : 1;
    if (si && (m['x'] as num) > (ab!['x'] as num)) ab['dir'] = 1;
  }

  // mesa.js: luisEn (moves line 212: Luis serves place i in front of the table, FL)
  Future<void> luisEn(Object? i) async {
    final p = G('luis')!;
    final none = i is! num;
    final x = none ? LUIS[0] : SILLA[i.toInt()] - 15,
        y = none ? LUIS[1] : 202 + FL[i.toInt()];
    if (_hypot((p['x'] as num) - x, (p['y'] as num) - y) > 3) {
      await mueve('luis', x, y);
    }
    p['dir'] = 1;
  }

  // mesa.js: perroA
  Future<void> perroA(num x, num y) async {
    final pe = W['perro'] as Map<String, dynamic>,
        x0 = pe['x'] as num,
        y0 = pe['y'] as num,
        n = math.max(3, _round(_hypot(x - x0, y - y0) / 7));
    pe['pose'] = 'walk';
    pe['dir'] = x < x0 ? -1 : 1;
    for (var s = 1; s <= n; s++) {
      pe['x'] = x0 + (x - x0) * s / n;
      pe['y'] = y0 + (y - y0) * s / n;
      await wait(TICK);
    }
  }

  // the id who sits at place i (`Object.keys(W.sitio).find(x => W.sitio[x] === i)`)
  String? _at(Object? i) {
    for (final en in _sitio.entries) {
      if (en.value == i) return en.key;
    }
    return null;
  }

  // mesa.js: susto. A thing is set down at a place: where the same thing already stands it goes on top of it, and what
  // was in that one is ruined
  void susto(Object? i) {
    final id = _at(i), p = id == null ? null : G(id);
    if (p == null) return;
    p['pose'] = 'wave0';
    p['dy'] = -2;
    unawaited(
      wait(900).then((_) {
        p['pose'] = 'idle';
        p['dy'] = 0;
      }, onError: (Object _) {}),
    );
  }

  // mesa.js: coloca
  int coloca(Object? i, String k) {
    final ps = _puesto(i)!, o = ps[k] as Map<String, dynamic>?;
    if (o == null) {
      ps[k] = <String, dynamic>{'n': 1, 'con': null};
      SFX.blip();
      return 0;
    }
    if (jsTruthy(o['con']) && o['con'] != 'migas') {
      final frente = ps['frente'] as List;
      if (k == 'plato') {
        o['n'] = 2;
        frente.add(<String, dynamic>{'k': 'roto'});
      } else {
        frente.add(<String, dynamic>{'k': 'charco'});
      }
      o['con'] = null;
      SFX.bonk();
      susto(i);
      return 1;
    }
    if (k == 'plato') o['n'] = 2;
    SFX.blip();
    return 0;
  }

  // mesa.js: ranaTrae (moves line 219: the frog fetching from whoever sits at place j stands in front of the table, FT;
  // line 220: at the counter where he did, ENQ)
  Future<void> ranaTrae(Object? k, [Object? de]) async {
    final M = W['mostrador'] as Map<String, dynamic>;
    if (jsTruthy(de)) {
      final p = G(de)!, j = sitio(de);
      await ranaA(
        j is num ? SILLA[j.toInt()] - 10 : (p['x'] as num) - 16,
        j is num ? 190 + FT[j.toInt()] : (p['y'] as num) + 8,
      );
    } else {
      final key = '${_str(k)}s', e = ENQ[M[key] != null ? key : 'bandeja']!;
      await ranaA(e[0] + 2, _p.keep(220, 171));
      if (jsTruthy(M[key])) M[key] = (M[key] as num) - 1;
    }
  }

  // mesa.js: ranaAl (moves line 221: the frog serving place i stands in front of the table, FRX, FR)
  Future<void> ranaAl(Object? i) {
    final k = (i as num).toInt();
    return ranaA(SILLA[k] - 14 + FRX[k], 190 + FR[k]);
  }

  // mesa.js: tiene, quienTiene
  Object? tiene(Object? id) {
    final p = G(id);
    if (p == null) return null;
    return jsTruthy(p['mano'])
        ? p['mano']
        : jsTruthy(p['alza'])
        ? p['alza']
        : null;
  }

  String? quienTiene(Object? k) {
    for (final id in (W['gente'] as Map<String, dynamic>).keys) {
      if (G(id)!['vis'] != 0 && tiene(id) == k) return id;
    }
    return null;
  }

  // mesa.js: pone26
  void pone26(Object? id, String k) {
    final ps = _puesto(sitio(id))!;
    if (k == 'comida') {
      ps['plato'] = <String, dynamic>{'n': 1, 'con': 'comida'};
    } else {
      ps['taza'] = <String, dynamic>{'n': 1, 'con': 'agua', 'k': 'vaso'};
    }
    final tuvo = W['tuvo'] as Map<String, dynamic>;
    ((tuvo['$id'] ??= <String, dynamic>{}) as Map<String, dynamic>)[k] = 1;
  }

  // mesa.js: corre. suelto: the act goes on while the story does; acts.ya waits for it
  Future<void> corre(Map<String, dynamic> o, Future<void> pr) {
    if (jsTruthy(o['suelto'])) {
      // (an act left running whose play is left meanwhile ends in "stop", as an unawaited promise did: not an error of
      // its own; acts.ya, which waits for it, still gets it)
      unawaited(pr.then((_) {}, onError: (Object _) {}));
      W['_mov'] = pr;
      return Future.value();
    }
    return pr;
  }

  // DECISION(order 32b, as El patio's, El camino's, El campo's, El lago's and El banco's): a position an act reads from
  // the story file (`o.x`, `o.y`: acts.g, acts.rana) goes through the sheet's remap, as the runner sends a set step's x
  // and y (page 12, section 5: every position a story file holds; the sheet's remap lists these uses: h-mesa's sitters
  // move to their chairs, 150 + SD)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  Future<void> _act(String k, Map<String, dynamic> o) => acts[k]!(o);

  // JavaScript: `[...].sort((a, b) => sitio(a[0]) - sitio(b[0]))`, a stable sort
  List<List<Object?>> _bySitio(List<List<Object?>> l) {
    final out = [...l];
    for (var i = 1; i < out.length; i++) {
      final e = out[i];
      var j = i - 1;
      while (j >= 0 && ((sitio(out[j][0]) as num) - (sitio(e[0]) as num)) > 0) {
        out[j + 1] = out[j];
        j--;
      }
      out[j + 1] = e;
    }
    return out;
  }

  // JavaScript: `M[k]--` of a count
  static void _less(Map<String, dynamic> M, String k) => M[k] = _plus(M[k]) - 1;

  // mesa.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'pose': (o) async {
      final p = G(o['quien']);
      if (p != null) p['pose'] = o['que'];
    },
    'marca': (o) async {
      marca(o['que']);
      SFX.blip();
      await wait(250);
    },
    'casa': (o) async {
      await acasa();
    },
    'ya': (o) async {
      final p = W['_mov'];
      W['_mov'] = null;
      if (p is Future) await p;
    },
    // a position the story file gives (x, y) goes through remap (h-mesa beats.2 to .5)
    'g': (o) async {
      final p = G(o['quien']);
      if (p == null) return;
      for (final k in o.keys) {
        if (!const ['act', 'quien', 'ms'].contains(k)) {
          p[k] = o[k] == '' ? null : o[k];
        }
      }
      if (o['x'] is num && o['y'] is num) {
        final xy = _fromFile(o['x'], o['y']);
        p['x'] = xy[0];
        p['y'] = xy[1];
      }
      if (jsTruthy(o['ms'])) await wait(_plus(o['ms']));
    },
    'entra': (o) async =>
        corre(o, sienta('${o['quien']}', _plus(o['silla']).toInt())),
    'sale': (o) async => corre(o, sale('${o['quien']}')),
    'rana': (o) async {
      final xy = _fromFile(o['x'], o['y']);
      return corre(o, ranaA(xy[0], xy[1], o['h']));
    },
    // one of a kind is lifted off the counter, or out of the tray, to be looked at
    'muestra': (o) async {
      final k = solo(o['k']);
      if (k.isEmpty) {
        W['muestra'] = null;
        return;
      }
      final b = jsTruthy((W['mostrador'] as Map)['bandeja']);
      final e = EN[b ? 'bandeja' : '${k}s'] ?? EN['platos']!;
      W['muestra'] = <String, dynamic>{
        'k': k,
        'g': b,
        'x': e[0] + (b ? (BX[k] ?? double.nan) : 0),
        'y': e[1] - (b ? 6 : 20),
      };
      SFX.blip();
      await wait(200);
    },
    // abuela goes to somebody's place, or back to the stove. sirve: with the slices and the jug in her hands
    'abuelaa': (o) async {
      final ab = G('abuela')!;
      final pr = () async {
        if (jsTruthy(o['nada'])) {
          ab['lleva'] = null;
          ab['lleva2'] = null;
          ab['ofrece'] = null;
          final E = W['estufa'] as Map<String, dynamic>;
          if (jsTruthy(E['bizcocho'])) E['jarra'] = 1;
        }
        if (jsTruthy(o['centro'])) {
          // moves line 238: where abuela waits in the middle
          await mueve('abuela', _centro[0], _centro[1]);
        } else {
          await abuelaEn(jsTruthy(o['a']) ? sitio(o['a']) : null);
        }
        ab['dir'] = -1;
        if (jsTruthy(o['sirve'])) {
          ab['lleva'] = 'tabla';
          ab['lleva2'] = 'jarra';
          (W['estufa'] as Map<String, dynamic>)['jarra'] = 0;
        }
      }();
      return corre(o, pr);
    },

    /* ----- story 24: La mesa ----- */
    // moves line 241: the answer cards (W.respEn); code line 241: every other place the floor rule's
    'inicio24': (o) async {
      W['respEn'] = [..._respEn24];
      W['mantel'] = 1;
      W['mostrador'] = <String, dynamic>{'platos': 6, 'tazas': 6};
      W['estufa'] = <String, dynamic>{'bizcocho': 1, 'jarra': 1, 'pastel': 1};
      W['reb'] = 3;
      W['choc'] = 9;
      W['contado'] = 0;
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{'x': FOGON[0], 'y': FOGON[1], 'dir': -1},
        'luis': <String, dynamic>{'x': LUIS[0], 'y': LUIS[1], 'dir': 1},
        'abuelo': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
        'mama': <String, dynamic>{'vis': 0, 'bebe': 1},
        'carmen': <String, dynamic>{'vis': 0},
      };
      W['casa'] = <dynamic>[..._p.floor(241, 52, 200)];
      final q = _p.floor(241, 36, 173);
      _cq.addAll(<String, dynamic>{'x': q[0], 'y': q[1], 's': 1});
    },
    'entran24': (o) async {
      final pr = () async {
        final a = sienta('abuelo', 0);
        await wait(TICK * 6);
        final b = sienta('papa', 1);
        await wait(TICK * 6);
        await sienta('mama', 3);
        await a;
        await b;
      }();
      return corre(o, pr);
    },
    // the frog fetches a plate or a cup from the counter and sets it down at somebody's place
    'pon': (o) async {
      final k = solo(o['k']), i = sitio(o['a']);
      final pr = () async {
        await ranaTrae(k);
        W['encima'] = <String, dynamic>{'k': k};
        SFX.blip();
        await ranaAl(i);
        await wait(120);
        W['encima'] = null;
        V['lio'] = coloca(i, k) != 0 ? '1' : '';
        await wait(250);
      }();
      return corre(o, pr);
    },
    'luispone': (o) async {
      final k = solo(o['k']), i = sitio(o['a']), p = G('luis')!;
      final pr = () async {
        await luisEn(null);
        final key = '${k}s', M = W['mostrador'] as Map<String, dynamic>;
        if (jsTruthy(M[key])) _less(M, key);
        p['lleva'] = k;
        SFX.blip();
        await luisEn(i);
        await wait(120);
        p['lleva'] = null;
        V['lio'] = coloca(i, k) != 0 ? '1' : '';
        await wait(250);
        await luisEn(null);
      }();
      return corre(o, pr);
    },
    // abuela serves: the slice onto the plate, the chocolate into the cup (moves lines 248, 249: at the place's row,
    // FILA + SD[i])
    'sirve': (o) async {
      final k = solo(o['k']),
          i = sitio(o['a']),
          ps = _puesto(i)!,
          ab = G('abuela')!;
      final pr = () async {
        await abuelaEn(i);
        if (!jsTruthy(ab['lleva'])) {
          ab['lleva'] = 'tabla';
          ab['lleva2'] = 'jarra';
          (W['estufa'] as Map<String, dynamic>)['jarra'] = 0;
        }
        if (!jsTruthy(ps[k])) return;
        if (jsTruthy(W['contado']) &&
            _plus(k == 'plato' ? W['reb'] : W['choc']) <= 0) {
          return;
        }
        if (jsTruthy(W['contado'])) {
          if (k == 'plato') {
            W['reb'] = _plus(W['reb']) - 1;
          } else {
            W['choc'] = _plus(W['choc']) - 1;
          }
        }
        alBebe(true);
        final ii = (i as num).toInt();
        if (k == 'plato') {
          final pl = ps['plato'] as Map<String, dynamic>;
          await vuela(
            <String, dynamic>{'k': 'bizcocho'},
            (ab['x'] as num) - 14,
            (ab['y'] as num) - 24,
            xDe(ii, 'plato'),
            FILA + SD[ii] - 2 - (_plus(pl['n']) - 1) * 3,
            5,
          );
          pl['con'] = 'bizcocho';
        } else {
          ab['lleva2'] = null;
          W['vierte'] = <String, dynamic>{
            'x': xDe(ii, 'taza') - 2,
            'y': FILA + SD[ii] - 8 + dyDe(ii, 'taza'),
          };
          await wait(TICK * 6);
          W['vierte'] = null;
          ab['lleva2'] = 'jarra';
          (ps['taza'] as Map<String, dynamic>)['con'] = 'choco';
        }
        SFX.blip();
        await wait(250);
        alBebe(false);
      }();
      return corre(o, pr);
    },
    // she serves what she asked for onto what he brought: the slice breaks on the cup, the chocolate runs off the plate
    // (moves lines 252, 253: at the place's row)
    'sirvemal': (o) async {
      final k = solo(o['k']),
          i = sitio(o['a']),
          ps = _puesto(i)!,
          ab = G('abuela')!;
      await abuelaEn(i);
      if (!jsTruthy(ab['lleva'])) {
        ab['lleva'] = 'tabla';
        ab['lleva2'] = 'jarra';
        (W['estufa'] as Map<String, dynamic>)['jarra'] = 0;
      }
      if (jsTruthy(W['contado'])) {
        if (k == 'plato') {
          W['reb'] = _plus(W['reb']) - 1;
        } else {
          W['choc'] = _plus(W['choc']) - 1;
        }
      }
      alBebe(true);
      final ii = (i as num).toInt();
      if (k == 'plato') {
        final x = xDe(ii, 'taza');
        await vuela(
          <String, dynamic>{'k': 'bizcocho'},
          (ab['x'] as num) - 14,
          (ab['y'] as num) - 24,
          x - 1,
          FILA + SD[ii] - 8,
          5,
        );
        final v = <String, dynamic>{
          'k': 'bizcocho',
          'x': x - 1,
          'y': FILA + SD[ii] - 8,
        };
        (W['vuelos'] as List).add(v);
        await wait(TICK * 5);
        v['x'] = (v['x'] as num) - 3;
        v['y'] = (v['y'] as num) + 3;
        v['rot'] = -0.6;
        await wait(TICK * 3);
        final l = W['vuelos'] as List, j = l.indexOf(v);
        if (j >= 0) {
          l.removeAt(j);
        } else if (l.isNotEmpty) {
          l.removeLast();
        }
        (ps['frente'] as List).add(<String, dynamic>{'k': 'roto'});
      } else {
        final x = xDe(ii, 'plato');
        ab['lleva2'] = null;
        W['vierte'] = <String, dynamic>{
          'x': x - 2,
          'y': FILA + SD[ii] - 6,
          'h': 8,
        };
        await wait(TICK * 4);
        (ps['plato'] as Map<String, dynamic>)['con'] = 'choco';
        await wait(TICK * 5);
        W['vierte'] = null;
        ab['lleva2'] = 'jarra';
        await wait(TICK * 3);
        (ps['plato'] as Map<String, dynamic>)['con'] = null;
        (ps['frente'] as List).add(<String, dynamic>{'k': 'charco'});
      }
      SFX.bonk();
      susto(i);
      await wait(500);
      alBebe(false);
    },
    // Luis deals: a plate to one, a cup to the other
    'reparte24': (o) async {
      final p = G('luis')!, a = sitio(o['p']), b = sitio(o['t']);
      await luisEn(null);
      final M = W['mostrador'] as Map<String, dynamic>;
      _less(M, 'platos');
      _less(M, 'tazas');
      p['lleva'] = 'plato';
      p['lleva2'] = 'taza';
      SFX.blip();
      final aFirst = a is num && b is num && a < b;
      final pri = aFirst
          ? [
              [a, 'plato', 'lleva'],
              [b, 'taza', 'lleva2'],
            ]
          : [
              [b, 'taza', 'lleva2'],
              [a, 'plato', 'lleva'],
            ];
      for (final e in pri) {
        await luisEn(e[0]);
        await wait(120);
        p[e[2] as String] = null;
        coloca(e[0], e[1] as String);
        await wait(200);
      }
      await luisEn(null);
    },
    // the baby pulls the cloth: everything slides to mamá's end and over the edge. Abuelo lifts his in time (moves line
    // 261: the bundle in front of her place, FI)
    'tira24': (o) async {
      final m = G('mama')!, im = (sitio('mama') as num).toInt();
      m['bebe'] = 'clap';
      W['tiron'] = 1;
      SFX.blip();
      await wait(500);
      _puesto(sitio('abuelo'))!['alza'] = 1;
      for (var s = 1; s <= 5; s++) {
        for (var i = 0; i < _puestos.length; i++) {
          final ps = _puestos[i] as Map<String, dynamic>;
          if (!jsTruthy(ps['alza'])) ps['dx'] = (SILLA[im] - SILLA[i]) * s / 5;
        }
        await wait(TICK);
      }
      for (final v in _puestos) {
        final ps = v as Map<String, dynamic>;
        if (!jsTruthy(ps['alza'])) {
          ps['plato'] = null;
          ps['taza'] = null;
          ps['dx'] = 0;
        }
      }
      W['mantel'] = 0;
      W['tiron'] = 0;
      (W['cosas'] as List).add(<String, dynamic>{
        'id': 'lio',
        'k': 'lio',
        'x': SILLA[im] - 6,
        'y': 200 + FI[im],
      });
      SFX.bonk();
      await wait(500);
      m['bebe'] = 1;
    },
    // moves line 262: Luis picks the bundle up in front of mamá's place (FL); code lines 262, 263: where he goes out and
    // comes back in at the left edge, the floor rule's
    'recoge24': (o) async {
      final p = G('luis')!, im = (sitio('mama') as num).toInt();
      await mueve('luis', SILLA[im] - 26, 204 + FL[im]);
      await wait(150);
      W['cosas'] = <dynamic>[
        for (final c in W['cosas'] as List)
          if ((c as Map)['id'] != 'lio') c,
      ];
      p['lleva'] = 'lio';
      SFX.blip();
      final out = _p.floor(262, 4, 190);
      await mueve('luis', out[0], out[1]);
      p['vis'] = 0;
      p['lleva'] = null;
      _puesto(sitio('abuelo'))!['alza'] = 0;
      SFX.blip();
      await wait(300);
      final back = _p.floor(263, 6, 170);
      p['vis'] = 1;
      p['x'] = back[0];
      p['y'] = back[1];
      p['lleva'] = 'plato';
      p['lleva2'] = 'taza';
      await luisEn(null);
      p['lleva'] = null;
      p['lleva2'] = null;
      final M = W['mostrador'] as Map<String, dynamic>;
      M['platos'] = _plus(M['platos']) + 3;
      M['tazas'] = _plus(M['tazas']) + 3;
      SFX.blip();
      await wait(200);
    },
    // after the turn: three slices on the board, three cups of chocolate in the jug
    'corta24': (o) async {
      final ab = G('abuela')!;
      await abuelaEn(null);
      W['reb'] = 3;
      W['choc'] = 3;
      W['contado'] = 1;
      final E = W['estufa'] as Map<String, dynamic>;
      E['bizcocho'] = 0;
      E['jarra'] = 0;
      ab['lleva'] = 'tabla';
      ab['lleva2'] = 'jarra';
      SFX.blip();
      await wait(300);
    },
    'lista24': (o) async {
      final ab = G('abuela')!;
      ab['lleva'] = null;
      ab['lleva2'] = null;
      await abuelaEn(null);
      await acasa();
    },
    'final24': (o) async {
      var j = 0;
      for (final id in [..._sitio.keys]) {
        final ps = _puesto(sitio(id))!, p = G(id)!;
        final pl = ps['plato'] as Map<String, dynamic>?,
            tz = ps['taza'] as Map<String, dynamic>?;
        final bz = pl != null && pl['con'] == 'bizcocho',
            ch = tz != null && tz['con'] == 'choco';
        if (bz && (j % 2 == 0 || !ch)) {
          p['hace'] = 'come';
          p['que'] = 'bizcocho';
          pl['con'] = 'migas';
        } else if (ch) {
          p['hace'] = 'bebe';
          p['que'] = 'taza';
        }
        j++;
      }
      SFX.blip();
      await wait(900);
      if (!jsTruthy(W['lost'])) {
        final ab = G('abuela')!;
        (W['estufa'] as Map<String, dynamic>)['pastel'] = 0;
        ab['ofrece'] = <String, dynamic>{'k': 'pastel'};
        await mueve('abuela', cx() + 40, pies() + 8);
        ab['dir'] = -1;
        await wait(200);
        ab['ofrece'] = null;
        (W['cosas'] as List).add(<String, dynamic>{
          'k': 'pastel',
          'x': cx() + 15,
          'y': pies() + 3,
        });
        _cq['hace'] = 'come';
        SFX.blip();
      }
      await wait(900);
    },

    /* ----- story 25: La cuchara ----- */
    // There is one spoon, one fork and one knife. Each is in the tray (W.bandeja), held up (alza) or in a hand at a dish
    // (mano). Moves line 273: the answer cards (W.respEn) and the four at the table on their chairs (150 + SD); code line
    // 273: every other place the floor rule's
    'inicio25': (o) async {
      W['respEn'] = [..._respEn25];
      W['mantel'] = 1;
      W['mostrador'] = <String, dynamic>{'bandeja': 1};
      W['bandeja'] = <dynamic>['cuchara', 'tenedor', 'cuchillo'];
      W['estufa'] = <String, dynamic>{'olla': 1, 'vapor': 1};
      Map<String, dynamic> sits(int i) => <String, dynamic>{
        'x': SILLA[i],
        'y': 150 + SD[i],
        'sent': 1,
        'dir': 1,
      };
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{'x': FOGON[0], 'y': FOGON[1], 'dir': -1},
        'luis': <String, dynamic>{'x': LUIS[0], 'y': LUIS[1], 'dir': 1},
        'abuelo': sits(0),
        'mama': sits(1),
        'papa': sits(2),
        'carmen': sits(3),
      };
      W['sitio'] = <String, dynamic>{
        'abuelo': 0,
        'mama': 1,
        'papa': 2,
        'carmen': 3,
      };
      W['casa'] = <dynamic>[..._p.floor(273, 52, 200)];
      W['origen'] = <String, dynamic>{};
      final q = _p.floor(273, 36, 173);
      _cq.addAll(<String, dynamic>{'x': q[0], 'y': q[1], 's': 1});
    },
    // abuela brings a dish from the stove. d: sopa, espa, pan; or para: the thing it is eaten with
    'plato25': (o) async {
      final i = sitio(o['a']),
          ps = _puesto(i)!,
          ab = G('abuela')!,
          d = jsTruthy(o['d']) ? o['d'] : PLATODE[solo(o['para'])];
      if (jsTruthy(ps['plato'])) return;
      final pr = () async {
        await abuelaEn(null);
        ab['ofrece'] = <String, dynamic>{'k': 'plato', 'con': d};
        SFX.blip();
        await abuelaEn(i);
        await wait(120);
        ab['ofrece'] = null;
        ps['plato'] = <String, dynamic>{'n': 1, 'con': d};
        SFX.blip();
        await wait(200);
        if (!jsTruthy(o['queda'])) await abuelaEn(null);
      }();
      return corre(o, pr);
    },
    // the frog takes a spoon, a fork or a knife to somebody: out of the tray, or from whoever has it. vuelve: the wrong
    // one in that hand goes back to where it came from
    'util': (o) async {
      final i = sitio(o['a']), p = G(o['a'])!;
      Object? de = jsTruthy(o['de']) && o['de'] != 'bandeja' ? o['de'] : null;
      Object? k = solo(o['k']);
      final bandeja = W['bandeja'] as List;
      if (jsTruthy(de)) {
        k = tiene(de);
      } else if (!bandeja.contains(k)) {
        de = quienTiene(k);
      }
      if (de == o['a']) {
        p['mano'] = k;
        p['alza'] = null;
        return;
      }
      await ranaTrae(k, de);
      if (jsTruthy(de)) {
        final q = G(de)!;
        q['alza'] = null;
        q['mano'] = null;
        q['hace'] = null;
      } else {
        W['bandeja'] = <dynamic>[
          for (final x in W['bandeja'] as List)
            if (x != k) x,
        ];
      }
      W['encima'] = <String, dynamic>{'k': k};
      SFX.blip();
      await ranaAl(i);
      await wait(120);
      W['encima'] = null;
      final vieja = tiene(o['a']);
      p['alza'] = null;
      p['hace'] = null;
      p['mano'] = k;
      SFX.blip();
      await wait(200);
      if (jsTruthy(vieja)) {
        final origen = W['origen'] as Map<String, dynamic>;
        final a = origen['$vieja'];
        final q = jsTruthy(a) && a != o['a'] ? G(a) : null;
        if (q != null) {
          await vuela(
            <String, dynamic>{'k': vieja},
            (p['x'] as num) + 8,
            (p['y'] as num) - 24,
            q['x'] as num,
            (q['y'] as num) - alto('$a') - 4,
            6,
          );
          q['alza'] = vieja;
        } else {
          (W['bandeja'] as List).add(vieja);
        }
        SFX.blip();
      }
      (W['origen'] as Map<String, dynamic>)['$k'] = jsTruthy(de) ? de : null;
    },
    'luisalza': (o) async {
      final p = G('luis')!, k = solo(o['k']);
      await luisEn(null);
      W['bandeja'] = <dynamic>[
        for (final x in W['bandeja'] as List)
          if (x != k) x,
      ];
      p['alza'] = k;
      SFX.blip();
      await wait(300);
    },
    // the frog calls for one: whoever has it passes it along and gets the other one's thing back
    'llama': (o) async {
      final a = '${o['a']}',
          p = G(a)!,
          k = solo(o['k']),
          de = quienTiene(k),
          mia = tiene(a);
      if (de == a || de == null) {
        // he has it already: he holds it up, shrugs, and keeps it
        p['dy'] = -3;
        await wait(250);
        p['dy'] = 0;
        await wait(200);
        p['mano'] = mia;
        p['alza'] = null;
        return;
      }
      final q = G(de)!;
      q['alza'] = null;
      q['mano'] = null;
      q['hace'] = null;
      p['alza'] = null;
      p['mano'] = null;
      SFX.blip();
      final one = vuela(
        <String, dynamic>{'k': k},
        q['x'] as num,
        (q['y'] as num) - alto(de) - 4,
        (p['x'] as num) + 8,
        (p['y'] as num) - 22,
        6,
      );
      final two = jsTruthy(mia)
          ? vuela(
              <String, dynamic>{'k': mia},
              p['x'] as num,
              (p['y'] as num) - alto(a) - 4,
              q['x'] as num,
              (q['y'] as num) - alto(de) - 4,
              6,
            )
          : Future<void>.value();
      await Future.wait([one, two]);
      p['mano'] = k;
      if (jsTruthy(mia)) q['alza'] = mia;
      SFX.blip();
      await wait(200);
    },
    // he eats with what he has in his hand; with the wrong thing the food drops onto the cloth
    'come25': (o) async {
      final i = sitio(o['a']), ps = _puesto(i)!, p = G(o['a'])!;
      if (!jsTruthy(ps['plato']) || !jsTruthy(p['mano'])) return;
      final d = (ps['plato'] as Map<String, dynamic>)['con'];
      p['que'] = p['mano'];
      p['hace'] = 'come';
      if (UTIL[d] != null && UTIL[d] == p['mano']) {
        V['lio'] = '';
        if (d == 'pan') p['que'] = 'pan';
        await wait(500);
        return;
      }
      await wait(800);
      p['hace'] = null;
      (ps['frente'] as List).add(<String, dynamic>{
        'k': 'mancha',
        'c': TINTE[d],
      });
      V['lio'] = '1';
      SFX.bonk();
      await wait(500);
    },
    // a dish is finished: abuela takes it, and the thing goes up to be seen
    'termina25': (o) async {
      for (final id in '${o['a']}'.split(',')) {
        final i = sitio(id), ps = _puesto(i)!, p = G(id)!;
        if (!jsTruthy(ps['plato'])) continue;
        p['hace'] = null;
        await abuelaEn(i);
        ps['plato'] = null;
        if (jsTruthy(p['mano'])) {
          p['alza'] = p['mano'];
          p['mano'] = null;
        }
        SFX.blip();
        await wait(150);
      }
      if (!jsTruthy(o['queda'])) await abuelaEn(null);
    },
    // whoever went without the thing for his dish gets it back from the one who holds it
    'arregla25': (o) async {
      for (final id in [..._sitio.keys]) {
        final ps = _puesto(sitio(id))!, p = G(id)!;
        final pl = ps['plato'] as Map<String, dynamic>?;
        if (pl == null) continue;
        final k = UTIL[pl['con']];
        // JavaScript: `p.mano !== UTIL[con]` (undefined for a dish with no thing: then no one holds it)
        if (k == null || p['mano'] == k) continue;
        final qt = quienTiene(k);
        if (qt != null && qt != id) {
          await _act('llama', <String, dynamic>{'a': id, 'k': k});
          p['que'] = pl['con'] == 'pan' ? 'pan' : k;
          p['hace'] = 'come';
        }
      }
    },
    // the turn: Luis gathers the three into the tray and takes it out; abuela has more; he comes back and deals them out
    // again (code lines 299, 300: where he goes out and comes in at the left edge, the floor rule's)
    'turno25a': (o) async {
      final l = G('luis')!;
      await luisEn(null);
      (W['mostrador'] as Map<String, dynamic>)['bandeja'] = 0;
      W['bandeja'] = <dynamic>[];
      l['lleva'] = 'bandeja';
      SFX.blip();
      for (var i = 0; i < 4; i++) {
        final id = _at(i), p = G(id);
        if (!jsTruthy(tiene(id))) continue;
        await luisEn(i);
        (W['bandeja'] as List).add(tiene(id));
        p!['alza'] = null;
        p['mano'] = null;
        SFX.blip();
        await wait(150);
      }
      final out = _p.floor(299, 4, 196);
      await mueve('luis', out[0], out[1]);
      l['vis'] = 0;
    },
    'turno25b': (o) async {
      final l = G('luis')!;
      (W['estufa'] as Map<String, dynamic>)['tapa'] = 0;
      final back = _p.floor(300, 6, 196);
      l['vis'] = 1;
      l['x'] = back[0];
      l['y'] = back[1];
      W['bandeja'] = <dynamic>['cuchara', 'tenedor', 'cuchillo'];
      l['lleva'] = 'bandeja';
      for (final e in _bySitio([
        [o['ha'], 'cuchara'],
        [o['hb'], 'tenedor'],
        [o['hc'], 'cuchillo'],
      ])) {
        await luisEn(sitio(e[0]));
        W['bandeja'] = <dynamic>[
          for (final k in W['bandeja'] as List)
            if (k != e[1]) k,
        ];
        G(e[0])!['alza'] = e[1];
        (W['origen'] as Map<String, dynamic>)['${e[1]}'] = null;
        SFX.blip();
        await wait(200);
      }
      await luisEn(null);
      l['lleva'] = null;
      (W['mostrador'] as Map<String, dynamic>)['bandeja'] = 1;
      W['bandeja'] = <dynamic>[];
    },
    // round B: one of the two who still hold a thing up gets the dish for the other one's thing. The old page's `?pb=`
    // and `?tb=` (a fixed pick, for its tests) are not the app's: the pick is drawn
    'elige25': (o) async {
      final hs2 = [
        for (final id in _sitio.keys)
          if (jsTruthy(G(id)!['alza']) && id != o['no']) id,
      ];
      final pb = hs2[(_rng.next() * hs2.length).floor()];
      final ops = [
        for (final k in const ['cuchara', 'tenedor', 'cuchillo'])
          if (k != G(pb)!['alza']) k,
      ];
      V['pb'] = pb;
      V['tb'] = ops[(_rng.next() * ops.length).floor()];
    },
    // bread for everybody
    'pan25': (o) async {
      final ab = G('abuela')!, l = G('luis')!;
      await luisEn(null);
      (W['mostrador'] as Map<String, dynamic>)['bandeja'] = 0;
      l['lleva'] = 'bandeja';
      for (var i = 0; i < 4; i++) {
        final id = _at(i), p = G(id)!;
        if (!jsTruthy(p['alza'])) continue;
        await luisEn(i);
        (W['bandeja'] as List).add(p['alza']);
        p['alza'] = null;
        SFX.blip();
        await wait(120);
      }
      await luisEn(null);
      l['lleva'] = null;
      (W['mostrador'] as Map<String, dynamic>)['bandeja'] = 1;
      await abuelaEn(null);
      ab['lleva'] = 'cesta';
      for (var i = 3; i >= 0; i--) {
        final id = _at(i), p = G(id)!;
        await abuelaEn(i);
        if (!(p['hace'] == 'come')) {
          p['hace'] = 'come';
          p['que'] = 'panecillo';
        }
        SFX.blip();
        await wait(120);
      }
      if (!jsTruthy(W['lost'])) {
        await acasa();
        await mueve('abuela', cx() + 40, pies() + 8);
        ab['dir'] = -1;
        await wait(200);
        (W['cosas'] as List).add(<String, dynamic>{
          'k': 'panecillo',
          'x': cx() + 15,
          'y': pies() + 3,
        });
        _cq['hace'] = 'come';
        SFX.blip();
      } else {
        await abuelaEn(null);
      }
      ab['lleva'] = null;
      await wait(900);
    },

    /* ----- story 26: Tengo hambre ----- */
    // From the turn on there are four plates and four glasses, one of each for abuelo, mamá, papá and the frog.
    // W.tuvo[who] is what he has had; W.perdio[who] is what Canelo had instead. Moves line 311: the answer cards
    // (W.respEn); code line 311: every other place the floor rule's
    'inicio26': (o) async {
      W['respEn'] = [..._respEn26];
      W['mantel'] = 0;
      W['mostrador'] = <String, dynamic>{'jarron': 1};
      W['estufa'] = <String, dynamic>{'olla': 1, 'tapa': 1};
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{'x': FOGON[0], 'y': FOGON[1], 'dir': -1},
        'luis': <String, dynamic>{'vis': 0},
        'carmen': <String, dynamic>{'vis': 0},
        'abuelo': <String, dynamic>{'vis': 0},
        'mama': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
      };
      W['casa'] = <dynamic>[..._p.floor(311, 70, 192)];
      W['vacios'] = <dynamic>[];
      W['tuvo'] = <String, dynamic>{};
      W['perdio'] = <String, dynamic>{};
      final q = _p.floor(311, 54, 165);
      _cq.addAll(<String, dynamic>{'x': q[0], 'y': q[1], 's': 1});
    },
    'tapa26': (o) async {
      final E = W['estufa'] as Map<String, dynamic>;
      E['tapa'] = 0;
      E['vapor'] = 1;
      SFX.blip();
      await wait(400);
    },
    // abuela fills plates and glasses and stands them on the counter. fin: the pot and the jug are empty after that
    // (moves line 314: she stands at the counter where she did, ENQ)
    'llena26': (o) async {
      final M = W['mostrador'] as Map<String, dynamic>,
          n = _plus(jsTruthy(o['n']) ? o['n'] : 2),
          ab = G('abuela')!;
      final pr = () async {
        await mueve('abuela', ENQ['jarron']![0] + 26, 182);
        ab['dir'] = -1;
        for (final k in const ['comidas', 'vasos']) {
          while (_n(M[k]) < n) {
            M[k] = _n(M[k]) + 1;
            SFX.blip();
            await wait(200);
          }
        }
        if (jsTruthy(o['fin'])) {
          W['tuvo'] = <String, dynamic>{};
          W['perdio'] = <String, dynamic>{};
          await abuelaEn(null);
          final E = W['estufa'] as Map<String, dynamic>;
          E['vapor'] = 0;
          E['olla'] = 2;
          M['jarron'] = 2;
          SFX.blip();
          await wait(500);
        }
      }();
      return corre(o, pr);
    },
    // a thought: what he would like
    'piensa': (o) async {
      final k = jsTruthy(o['k']) ? cual(o['k']) : null;
      if (o['quien'] == 'coqui') {
        _cq['piensa'] = k;
      } else {
        G(o['quien'])!['piensa'] = k;
      }
      if (k != null) SFX.blip();
      await wait(250);
    },
    // abuela takes a plate or a glass off the counter and puts it on the floor in front of the frog (moves line 318: at
    // the counter where she stood, ENQ)
    'abuelada': (o) async {
      final ab = G('abuela')!,
          k = cual(o['k']),
          it = cosaDe(k),
          key = k == 'comida' ? 'comidas' : 'vasos';
      final pr = () async {
        await mueve('abuela', ENQ['jarron']![0] + 26, 182);
        ab['dir'] = -1;
        final M = W['mostrador'] as Map<String, dynamic>;
        if (jsTruthy(M[key])) _less(M, key);
        ab['ofrece'] = it;
        SFX.blip();
        await mueve('abuela', cx() + 54, pies() + 10);
        ab['dir'] = -1;
        await wait(150);
        ab['ofrece'] = null;
        final cosas = W['cosas'] as List;
        if (!cosas.any((c) => (c as Map)['id'] == 'mat')) {
          cosas.add(<String, dynamic>{
            'id': 'mat',
            'k': 'mantelito',
            'x': cx() + 23,
            'y': pies() + 5,
            'z': 0,
          });
        }
        cosas.add(<String, dynamic>{
          'id': 'cq$k',
          'x': cx() + (k == 'comida' ? 16 : 29),
          'y': pies() + 3,
          ...it,
        });
        V['cq'] = k;
        SFX.blip();
        await wait(250);
      }();
      return corre(o, pr);
    },
    // the frog has what stands in front of him
    'ranatoma': (o) async {
      final k = V['cq'];
      Map<String, dynamic>? c;
      for (final x in W['cosas'] as List) {
        if ((x as Map)['id'] == 'cq$k') {
          c = x as Map<String, dynamic>;
          break;
        }
      }
      if (c == null) return;
      _cq['hace'] = k == 'comida' ? 'come' : 'bebe';
      _cq['piensa'] = null;
      final tuvo = W['tuvo'] as Map<String, dynamic>;
      ((tuvo['coqui'] ??= <String, dynamic>{}) as Map<String, dynamic>)['$k'] =
          1;
      await wait(1100);
      _cq['hace'] = null;
      c['con'] = k == 'comida' ? 'migas' : null;
      SFX.blip();
      await wait(200);
    },
    // the mat stays
    'quita26': (o) async {
      W['cosas'] = <dynamic>[
        for (final c in W['cosas'] as List)
          if (!_str((c as Map)['id']).startsWith('cq')) c,
      ];
    },
    // abuela takes a plate or a glass off the counter and holds it out (moves line 323: at the counter where she stood)
    'ofrece26': (o) async {
      final ab = G('abuela')!,
          k = cual(o['k']),
          key = k == 'comida' ? 'comidas' : 'vasos';
      await mueve('abuela', ENQ['jarron']![0] + 26, 182);
      ab['dir'] = -1;
      final M = W['mostrador'] as Map<String, dynamic>;
      if (jsTruthy(M[key])) _less(M, key);
      ab['ofrece'] = cosaDe(k);
      SFX.blip();
      await wait(300);
    },
    // the frog takes a plate or a glass to somebody: from the counter, or out of abuela's hand (moves line 326: he
    // fetches at the counter where he did, ENQ)
    'lleva26': (o) async {
      final k = cual(o['k']), i = sitio(o['a']), ab = G('abuela')!;
      if (jsTruthy(ab['ofrece']) && o['de'] == 'abuela') {
        await ranaA((ab['x'] as num) - 30, (ab['y'] as num) + 10);
        await wait(120);
        ab['ofrece'] = null;
      } else {
        final key = k == 'comida' ? 'comidas' : 'vasos';
        await ranaA(ENQ[key]![0] + 4, _p.keep(326, 173));
        final M = W['mostrador'] as Map<String, dynamic>;
        if (jsTruthy(M[key])) _less(M, key);
      }
      W['encima'] = cosaDe(k);
      SFX.blip();
      await ranaAl(i);
      await wait(120);
      W['encima'] = null;
      pone26(o['a'], k);
      SFX.blip();
      await wait(250);
    },
    // moves line 328: at the counter where she stood
    'abuelalleva': (o) async {
      final k = cual(o['k']),
          i = sitio(o['a']),
          ab = G('abuela')!,
          key = k == 'comida' ? 'comidas' : 'vasos';
      await mueve('abuela', ENQ['jarron']![0] + 26, 182);
      ab['dir'] = -1;
      final M = W['mostrador'] as Map<String, dynamic>;
      if (jsTruthy(M[key])) _less(M, key);
      ab['ofrece'] = cosaDe(k);
      SFX.blip();
      await abuelaEn(i);
      await wait(120);
      ab['ofrece'] = null;
      pone26(o['a'], k);
      SFX.blip();
      await wait(200);
      await abuelaEn(null);
    },
    // he eats, or drinks, what stands in front of him
    'toma26': (o) async {
      final p = G(o['a'])!, ps = _puesto(sitio(o['a']))!;
      p['piensa'] = null;
      final pl = ps['plato'] as Map<String, dynamic>?,
          tz = ps['taza'] as Map<String, dynamic>?;
      if (pl != null &&
          pl['con'] == 'comida' &&
          !(jsTruthy(o['k']) && cual(o['k']) == 'agua')) {
        p['hace'] = 'come';
        p['que'] = 'tenedor';
      } else if (tz != null && jsTruthy(tz['con'])) {
        p['hace'] = 'bebe';
        p['que'] = 'vaso';
      }
      await wait(600);
    },
    'acaba26': (o) async {
      for (final id in '${o['quien']}'.split(',')) {
        final p = G(id)!, ps = _puesto(sitio(id))!;
        ps['plato'] = null;
        ps['taza'] = null;
        p['hace'] = null;
      }
      SFX.blip();
      await wait(300);
    },
    // Canelo has it: what was put aside at the edge of the table, or what stands untouched in front of the frog (moves
    // line 336: he begs in front of the place, FP; what was set aside falls from the table, FRENTE + SD[i], to the floor
    // in front of it, 202 + FC[i])
    'canelo': (o) async {
      final pe = W['perro'] as Map<String, dynamic>;
      Map<String, dynamic>? c;
      Object? k;
      if (o['de'] == 'coqui') {
        k = V['cq'];
        for (final x in W['cosas'] as List) {
          if ((x as Map)['id'] == 'cq$k') {
            c = x as Map<String, dynamic>;
            break;
          }
        }
        if (c == null) return;
        await wait(500);
        await perroA((c['x'] as num) + 18, (c['y'] as num) + 2);
        final perdio = W['perdio'] as Map<String, dynamic>;
        ((perdio['coqui'] ??= <String, dynamic>{})
                as Map<String, dynamic>)['$k'] =
            1;
      } else {
        final i = (sitio(o['a']) as num).toInt(),
            ps = _puesto(i)!,
            p = G(o['a'])!;
        k = cual(o['k']);
        for (final d in const [-1, 1, -1, 1]) {
          p['dir'] = d;
          await wait(180);
        }
        final it = cosaDe(k);
        if (k == 'comida') {
          ps['plato'] = null;
        } else {
          ps['taza'] = null;
        }
        (ps['frente'] as List).add(<String, dynamic>{'k': 'aparte', 'o': it});
        final perdio = W['perdio'] as Map<String, dynamic>;
        ((perdio['${o['a']}'] ??= <String, dynamic>{})
                as Map<String, dynamic>)['$k'] =
            1;
        final tuvo = W['tuvo'] as Map<String, dynamic>;
        if (jsTruthy(tuvo['${o['a']}'])) {
          (tuvo['${o['a']}'] as Map<String, dynamic>).remove('$k');
        }
        SFX.blip();
        await wait(500);
        await perroA(SILLA[i] + 16, 194 + FP[i]);
        pe['pose'] = 'sit';
        pe['dir'] = -1;
        pe['dy'] = 5;
        await wait(300);
        ps['frente'] = <dynamic>[
          for (final m in ps['frente'] as List)
            if ((m as Map)['k'] != 'aparte') m,
        ];
        susto(i);
        final cc = <String, dynamic>{
          'x': SILLA[i] - 2,
          'y': FRENTE + SD[i],
          ...it,
        };
        c = cc;
        (W['cosas'] as List).add(cc);
        for (var s = 1; s <= 4; s++) {
          cc['y'] = FRENTE + SD[i] + (202 + FC[i] - FRENTE - SD[i]) * s / 4;
          await wait(TICK);
        }
        pe['dy'] = 0;
      }
      // he drags it to his corner and has it there
      final cc = c;
      W['cosas'] = <dynamic>[
        for (final x in W['cosas'] as List)
          if (!identical(x, cc)) x,
      ];
      pe['lleva'] = <String, dynamic>{'k': cc['k'], 'con': cc['con']};
      await perroA(CAN[0], CAN[1]);
      pe['lleva'] = null;
      pe['dir'] = -1;
      final j = (W['vacios'] as List).length, vx = CAN[0] - 24 - j * 17;
      if (cc['k'] == 'plato') {
        final v = <String, dynamic>{
          'k': 'plato',
          'con': 'comida',
          'x': vx,
          'y': CAN[1] + 6,
        };
        (W['cosas'] as List).add(v);
        pe['pose'] = 'eat';
        SFX.blip();
        await wait(900);
        v['con'] = null;
      } else {
        (W['cosas'] as List)
          ..add(<String, dynamic>{
            'k': 'agua',
            'x': vx - 3,
            'y': CAN[1] + 9,
            'z': 0,
          })
          ..add(<String, dynamic>{'k': 'caido', 'x': vx + 2, 'y': CAN[1] + 5});
        SFX.bonk();
        pe['pose'] = 'husmea';
        await wait(900);
      }
      (W['vacios'] as List).add(cc['k']);
      pe['pose'] = 'lie';
      pe['cola'] = 1;
      await wait(400);
      pe['cola'] = 0;
    },
    'salen26': (o) async {
      final a = sale('luis');
      await wait(TICK * 4);
      await sale('carmen');
      await a;
      for (final v in _puestos) {
        final ps = v as Map<String, dynamic>;
        ps['plato'] = null;
        ps['taza'] = null;
      }
    },
    // the turn: Canelo comes in, sits down in front of the counter and whines (moves line 345: in front of the counter
    // where he did, ENQ; code line 345: where he comes in at the left edge, the floor rule's)
    'canelo26': (o) async {
      final at = _p.floor(345, 4, 200);
      W['perro'] = <String, dynamic>{
        'x': at[0],
        'y': at[1],
        'pose': 'walk',
        'dir': 1,
      };
      final pe = W['perro'] as Map<String, dynamic>;
      await perroA(ENQ['comidas']![0] + 52, _p.keep(345, 198));
      pe['pose'] = 'sit';
      pe['dir'] = -1;
      await wait(300);
      pe['pose'] = 'bark';
      await wait(600);
      pe['pose'] = 'sit';
    },
    'echa26': (o) async {
      final pe = W['perro'] as Map<String, dynamic>;
      await perroA(CAN[0], CAN[1]);
      pe['dir'] = -1;
      pe['pose'] = 'lie';
      await wait(300);
    },
    // the ending: what is left on the counter goes round, a plate and a glass for each, as far as it goes (moves line
    // 348: abuela at the counter where she stood; line 350: what goes round lands at each place, FILA + SD)
    'reparte26': (o) async {
      final ab = G('abuela')!, M = W['mostrador'] as Map<String, dynamic>;
      await mueve('abuela', ENQ['jarron']![0] + 26, 182);
      ab['dir'] = -1;
      final tuvo = W['tuvo'] as Map<String, dynamic>,
          perdio = W['perdio'] as Map<String, dynamic>;
      for (final id in const ['abuelo', 'mama', 'papa', 'coqui']) {
        for (final k in const ['comida', 'agua']) {
          if ((jsTruthy(tuvo[id]) && jsTruthy((tuvo[id] as Map)[k])) ||
              (jsTruthy(perdio[id]) && jsTruthy((perdio[id] as Map)[k]))) {
            continue;
          }
          final key = k == 'comida' ? 'comidas' : 'vasos';
          if (!jsTruthy(M[key])) continue;
          _less(M, key);
          final x1 = id == 'coqui'
                  ? cx() + (k == 'comida' ? 16 : 29)
                  : SILLA[(sitio(id) as num).toInt()],
              y1 = id == 'coqui'
                  ? pies() + 3
                  : FILA + SD[(sitio(id) as num).toInt()];
          await vuela(cosaDe(k), EN[key]![0], EN[key]![1], x1, y1, 6);
          if (id == 'coqui') {
            final cosas = W['cosas'] as List;
            if (!cosas.any((c) => (c as Map)['id'] == 'mat')) {
              cosas.add(<String, dynamic>{
                'id': 'mat',
                'k': 'mantelito',
                'x': cx() + 23,
                'y': pies() + 5,
                'z': 0,
              });
            }
            cosas.add(<String, dynamic>{
              'id': 'cq$k',
              'x': x1,
              'y': y1,
              ...cosaDe(k),
            });
            ((tuvo['coqui'] ??= <String, dynamic>{})
                    as Map<String, dynamic>)[k] =
                1;
          } else {
            pone26(id, k);
          }
          SFX.blip();
          await wait(120);
        }
      }
      await abuelaEn(null);
    },
    // moves line 353: abuela gives Canelo his bone 3 rows lower
    'final26': (o) async {
      for (final id in [..._sitio.keys]) {
        final p = G(id)!, ps = _puesto(sitio(id))!;
        p['piensa'] = null;
        final pl = ps['plato'] as Map<String, dynamic>?,
            tz = ps['taza'] as Map<String, dynamic>?;
        if (pl != null && pl['con'] == 'comida') {
          p['hace'] = 'come';
          p['que'] = 'tenedor';
        } else if (tz != null && jsTruthy(tz['con'])) {
          p['hace'] = 'bebe';
          p['que'] = 'vaso';
        } else {
          p['hace'] = null;
        }
      }
      _cq['hace'] =
          (W['cosas'] as List).any(
            (c) => _str((c as Map)['id']).startsWith('cq'),
          )
          ? 'come'
          : null;
      await wait(700);
      final pe = W['perro'] as Map<String, dynamic>;
      if (!jsTruthy(W['lost'])) {
        final ab = G('abuela')!;
        ab['lleva'] = 'hueso';
        await mueve(
          'abuela',
          CAN[0] - _hueso[0],
          CAN[1] - _hueso[1] + _hueso[2],
        );
        ab['dir'] = 1;
        await wait(200);
        ab['lleva'] = null;
        (W['cosas'] as List).add(<String, dynamic>{
          'k': 'hueso',
          'x': CAN[0] - 14,
          'y': CAN[1] + 6,
        });
        pe['pose'] = 'sit';
        pe['cola'] = 1;
        SFX.blip();
      } else {
        pe['pose'] = 'lie';
        pe['cola'] = 1;
      }
      await wait(900);
    },

    // everybody at once, to look at the drawing (moves line 358: the four on their chairs, 150 + SD; code lines 364 to
    // 366: every other place the floor rule's)
    'prueba': (o) async => _prueba(o),
  };

  // mesa.js: acts.prueba
  void _prueba(Map<String, dynamic> o) {
    final n = _plus(jsTruthy(o['n']) ? o['n'] : 1);
    W['gente'] = <String, dynamic>{
      'abuela': <String, dynamic>{
        'x': FOGON[0],
        'y': FOGON[1],
        'dir': -1,
        'lleva': n == 1 ? 'tabla' : null,
        'lleva2': n == 1 ? 'jarra' : null,
        'ofrece': n == 3
            ? <String, dynamic>{'k': 'plato', 'con': 'comida'}
            : null,
      },
      'luis': <String, dynamic>{
        'x': LUIS[0],
        'y': LUIS[1],
        'dir': 1,
        'alza': n == 2 ? 'cuchillo' : null,
      },
      'abuelo': <String, dynamic>{
        'x': SILLA[0],
        'y': 150 + SD[0],
        'dir': 1,
        'sent': 1,
        'alza': n == 2 ? 'cuchara' : null,
        'piensa': n == 3 ? 'sed' : null,
      },
      'papa': <String, dynamic>{
        'x': SILLA[1],
        'y': 150 + SD[1],
        'dir': 1,
        'sent': 1,
        'hace': n == 2 ? 'come' : null,
        'que': 'tenedor',
      },
      'mama': <String, dynamic>{
        'x': SILLA[2],
        'y': 150 + SD[2],
        'dir': 1,
        'sent': 1,
        'bebe': n == 1 ? 1 : 0,
        'mano': n == 2 ? 'cuchillo' : null,
      },
      'carmen': <String, dynamic>{
        'x': SILLA[3],
        'y': 150 + SD[3],
        'dir': 1,
        'sent': 1,
        'alza': n == 2 ? 'tenedor' : null,
        'hace': n == 3 ? 'bebe' : null,
        'que': 'vaso',
      },
    };
    W['sitio'] = <String, dynamic>{
      'abuelo': 0,
      'papa': 1,
      'mama': 2,
      'carmen': 3,
    };
    W['mostrador'] = n == 3
        ? <String, dynamic>{'comidas': 4, 'vasos': 4, 'jarron': 2}
        : n == 2
        ? <String, dynamic>{'bandeja': 1}
        : <String, dynamic>{'platos': 5, 'tazas': 4};
    W['bandeja'] = <dynamic>['cuchara', 'cuchillo'];
    W['reb'] = 2;
    W['estufa'] = n == 1
        ? <String, dynamic>{'bizcocho': 1, 'pastel': 1}
        : <String, dynamic>{'olla': n == 3 ? 2 : 1, 'vapor': n == 2 ? 1 : 0};
    W['mantel'] = n == 2 ? 1 : 0;
    final can = _p.floor(364, CAN[0], CAN[1]);
    W['perro'] = n == 3
        ? <String, dynamic>{'x': can[0], 'y': can[1], 'pose': 'lie', 'dir': -1}
        : null;
    Map<String, dynamic> P([
      Map<String, dynamic>? pl,
      Map<String, dynamic>? tz,
      List<dynamic>? uts,
      List<dynamic>? fr,
    ]) => <String, dynamic>{
      'plato': pl,
      'taza': tz,
      'uts': uts ?? <dynamic>[],
      'frente': fr ?? <dynamic>[],
    };
    W['puestos'] = n == 1
        ? <dynamic>[
            P({'n': 1, 'con': 'bizcocho'}, {'n': 1, 'con': 'choco'}),
            P({'n': 2, 'con': 'bizcocho', 'plano': 1}, {'n': 1}, [], [
              {'k': 'roto'},
            ]),
            P({'n': 1}, {'n': 1}, [], [
              {'k': 'charco'},
              {'k': 'tazacaida'},
            ]),
            P(
              {'n': 1, 'con': 'choco'},
              null,
              [],
              [
                {'k': 'roto'},
                {'k': 'charco'},
              ],
            ),
          ]
        : n == 2
        ? <dynamic>[
            P({'n': 1, 'con': 'sopa'}, null, ['cuchara']),
            P({'n': 1, 'con': 'espa'}),
            P({'n': 1, 'con': 'pan'}, null, ['tenedor'], [
              {'k': 'mancha', 'c': TINTE['sopa']},
              {'k': 'mancha', 'c': TINTE['espa']},
            ]),
            P({'n': 1, 'con': 'sopa'}, null, ['cuchillo'], [
              {'k': 'mancha', 'c': TINTE['pan']},
            ]),
          ]
        : <dynamic>[
            P({'n': 1, 'con': 'comida'}),
            P(null, {'n': 1, 'con': 'agua', 'k': 'vaso'}),
            P(null, null, [], [
              {
                'k': 'aparte',
                'o': {'k': 'plato', 'con': 'comida'},
              },
            ]),
            P(),
          ];
    W['cosas'] = n == 3
        ? <dynamic>[
            <String, dynamic>{'k': 'plato', 'x': CAN[0] - 24, 'y': CAN[1] + 3},
            <String, dynamic>{
              'k': 'agua',
              'x': CAN[0] - 42,
              'y': CAN[1] + 5,
              'z': 0,
            },
            <String, dynamic>{'k': 'caido', 'x': CAN[0] - 41, 'y': CAN[1] + 2},
          ]
        : n == 1
        ? <dynamic>[
            <String, dynamic>{
              'k': 'lio',
              'x': _p.floor(364, 146, 200)[0],
              'y': _p.floor(364, 146, 200)[1],
            },
          ]
        : <dynamic>[];
    W['suelo'] = n == 2
        ? <dynamic>[
            for (final s in const [
              [110, 196, 1],
              [140, 204, 2.2],
              [166, 192, 0.6],
            ])
              <String, dynamic>{
                'k': s == const [110, 196, 1]
                    ? 'cuchara'
                    : s == const [140, 204, 2.2]
                    ? 'tenedor'
                    : 'cuchillo',
                'x': _p.floor(365, s[0], s[1])[0],
                'y': _p.floor(365, s[0], s[1])[1],
                'rot': s[2],
              },
          ]
        : <dynamic>[];
    final cq = _p.floor(366, 104, 163);
    _cq.addAll(<String, dynamic>{'x': cq[0], 'y': cq[1], 's': 1});
    W['encima'] = n == 1
        ? <String, dynamic>{'k': 'plato'}
        : n == 2
        ? <String, dynamic>{'k': 'cuchara'}
        : <String, dynamic>{'k': 'vaso', 'con': 'agua'};
    _cq['piensa'] = n == 3 ? 'hambre' : null;
    W['muestra'] = n == 2
        ? <String, dynamic>{
            'k': 'tenedor',
            'g': 1,
            'x': EN['bandeja']![0],
            'y': EN['bandeja']![1] - 6,
          }
        : null;
    W['tarjeta'] = 'rondas';
    W['marcas'] = <dynamic>['ok', 'x', null];
  }

  // mesa.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    await wait(200);
  }

  // mesa.js: poke
  @override
  dynamic poke(String what) => null;

  // mesa.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if ((g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}'
                '${jsTruthy(p['sent']) ? 's' : ''}'
                '${jsTruthy(p['alza']) ? '^${p['alza']}' : ''}'
                '${jsTruthy(p['mano']) ? '[${p['mano']}]' : ''}'
                '${jsTruthy(p['hace']) ? '(${p['hace']})' : ''}';
          }(),
    ].join(' ');
    final puestos = [
      for (final v in (W['puestos'] as List?) ?? const [])
        () {
          final p = v as Map<String, dynamic>;
          final pl = p['plato'] as Map<String, dynamic>?,
              tz = p['taza'] as Map<String, dynamic>?;
          final uts = p['uts'] as List, fe = p['frente'] as List;
          return '${pl != null ? 'P${_js(pl['n'])}${jsTruthy(pl['con']) ? ':${pl['con']}' : ''}${jsTruthy(pl['plano']) ? '_' : ''}' : ''}'
              '${tz != null ? 'T${_js(tz['n'])}${jsTruthy(tz['con']) ? ':${tz['con']}' : ''}' : ''}'
              '${uts.isNotEmpty ? 'u:${uts.join('+')}' : ''}'
              '${fe.isNotEmpty ? '!${[for (final m in fe) (m as Map)['k']].join('+')}' : ''}';
        }(),
    ].join('|');
    final vacios = [for (final v in (W['vacios'] as List?) ?? const []) '$v']
        .join('+');
    final marcas = [
      for (final m in (W['marcas'] as List?) ?? const [])
        m == null ? '' : _js(m),
    ].join(',');
    return 'gente=$gente puestos=$puestos mostr=${jsonEncode(W['mostrador'] ?? const {})}'
        ' vacios=$vacios marcas=$marcas';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A point keeps its screen place (the sheet's `new`; the few the sheet moved: those who sit, on
  // their chairs, 150 + SD; cual-mesa's things on the table's top and the people who hold things up; abuela at El
  // colmado's stall); the frog out of a picture is no place (`to.none`) and is given back; a pair rectangle gives the
  // crop of the pictures it was; a level picture's rectangle gives itself back (the level pictures are the sheet's).
  @override
  List<num> remap(List<num> xy) {
    switch (xy.length) {
      case 1:
        final r = sheet.remap('x', xy);
        if (r.to.level) return xy;
        return [r.x!];
      case 2:
        final r = sheet.remapPoint(xy[0], xy[1]);
        if (r.now != null) return r.now!;
        final to = r.to;
        if (to.spot != null && to.scene == null) return _p.spot(to.spot!);
        if (to.screen != null) return to.screen!;
        if (to.none != null) return xy;
        throw SheetError('the remap of $xy names no place');
      case 4:
        SheetRemap r;
        try {
          r = sheet.remapCam(xy);
        } on SheetError {
          r = sheet.remapCrop(xy);
        }
        final to = r.to;
        if (to.level) return xy;
        if (to.view != null) return sheet.viewOf(to.view!, _p.e);
        if (r.crop != null) return r.crop!;
        final crops = <String, List<int>>{
          for (final c
              in r.crops?.values ??
                  [
                    for (final n in to.pictures ?? const <String>[])
                      (
                        crop: sheet.pictures[n]!.crop,
                        zoom: sheet.pictures[n]!.zoom,
                      ),
                  ])
            '${c.zoom}:${c.crop.join(',')}': c.crop,
        };
        if (crops.length != 1) {
          throw SheetError(
            'the old rectangle $xy is ${to.pictures} in the sheet, which crops them differently: ask for a picture by its name',
          );
        }
        return crops.values.first;
      default:
        throw SheetError('a position is 1, 2 or 4 numbers, not $xy');
    }
  }

  // mesa-preview.html: PV.pair's remapW for a review picture's own W (the pair's file, cual-mesa): those who sit, on their
  // chairs (150 + SD); those who stand and the things, each at a place of a move or of a story move the sheet gives for
  // cual-mesa to its new one (the story file's own first); the frog (the top level's `cq`) is ScenePictures' (the sheet's
  // remap). At El colmado's stall (W.afuera: cocina.no) everyone stands at its spot (the sheet's storyMoves: scene
  // frutas, spot abuela.delante, as the preview's `at`).
  @override
  void placePair(Map<String, dynamic> set) {
    remapW(set, 'cual-mesa');
    if (jsTruthy(set['afuera'])) {
      final sm = sheet.storyMoves.firstWhere(
        (m) => m.scene == 'frutas',
        orElse: () => throw SheetError(
          'the sheet of mesa has no story move to El colmado\'s stall',
        ),
      );
      for (final p
          in ((set['gente'] as Map<String, dynamic>?) ?? const {}).values) {
        if (p is Map) {
          p['x'] = sm.now[0];
          p['y'] = sm.now[1];
        }
      }
    }
  }

  // mesa-preview.html: remapRule (the same as mesa-sheet-make.js remapW). A W in old positions, moved by the sheet's
  // rule: whoever sits at SILLA[i] to 150 + SD[i]; a place that moves (moves' places, the story moves of [story]'s file:
  // null, any) to its new point, a story file's own move first; the jug pouring by its seat; the frog when he stands at a
  // move's place.
  void remapW(Map<String, dynamic> w, String? story) {
    final SIL = SILLA;
    final MV = [for (final m in sheet.moves) ...m.places];
    final RM = [
      for (final e in sheet.storyMoves)
        if (e.scene == null &&
            (e.uses == null ||
                story == null ||
                e.uses!.any((u) => u.startsWith(story))))
          e,
    ];
    List<int>? find(String who, int x, int y) {
      for (final e in RM) {
        if (e.who != 'sitting' &&
            e.uses != null &&
            e.old[0] == x &&
            e.old[1] == y) {
          return e.now;
        }
      }
      for (final q in MV) {
        if ((q.who == 'whoever' || q.who == who) &&
            q.old[0] == x &&
            q.old[1] == y) {
          return [for (final v in q.now) v.toInt()];
        }
      }
      for (final e in RM) {
        if (e.who != 'sitting' && e.old[0] == x && e.old[1] == y) return e.now;
      }
      return null;
    }

    void mv(String who, Map p) {
      final m = find(who, _round(p['x'] as num), _round(p['y'] as num));
      if (m != null) {
        p['x'] = m[0];
        p['y'] = m[1];
      }
    }

    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value;
      if (p is! Map || p['x'] == null) continue;
      if (jsTruthy(p['sent'])) {
        final k = SIL.indexOf(_round(p['x'] as num));
        if (k >= 0 && _round(p['y'] as num) == 150) p['y'] = 150 + SD[k];
      } else {
        mv(en.key, p);
      }
    }
    final pe = w['perro'];
    if (pe is Map && pe['x'] != null) mv('perro', pe);
    for (final o in (w['cosas'] as List?) ?? const []) {
      if (o is Map && o['x'] != null) mv('cosa', o);
    }
    final mu = w['muestra'];
    if (mu is Map) mv('muestra', mu);
    final vi = w['vierte'];
    if (vi is Map) {
      var k = 0;
      for (var i = 1; i < 4; i++) {
        if (((vi['x'] as num) - SIL[i]).abs() <
            ((vi['x'] as num) - SIL[k]).abs()) {
          k = i;
        }
      }
      vi['y'] = (vi['y'] as num) + SD[k];
    }
    final q = w['cq'];
    if (q is Map) {
      for (final m in MV) {
        if (m.who == 'cq' && m.old[0] == q['x'] && m.old[1] == q['y']) {
          q['x'] = m.now[0];
          q['y'] = m.now[1];
          break;
        }
      }
    }
  }
}
