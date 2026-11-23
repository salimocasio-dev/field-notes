// Port of historia/escenas/nevera.js: the scene "La nevera", abuela's fridge (place 3, La cocina; order 39b). Line for
// line, minus its background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background,
// the window's frame and sill, the fridge's inside, door and drawer, the water in the sink and the old stool: the set's);
// every screen position replaced by what the sheet's `code` list gives for its line (nevera_places.dart), and the places
// the sheet's `moves` list moves, each at its line (the moved source's own numbers: NeveraPlaces.to). nevera.js is written
// on the kit, so this is an `Escena`; its set is [NeveraSet], its sprites nevera_sprites.dart.
//
// What La nevera's sheet has that the earlier ones did not, or uses differently, and how it is kept here (as
// nevera-preview.html keeps it, its functions ported pixel for pixel):
// - **Whoever is outside the window** (the sheet's `clips.patio`): what patio() draws between its clip and its restore
//   (the cart, what lies on the yard wall, the birds, whoever stands outside and the hat) is drawn only on the set's
//   pixels that show the outside through the window (the zone `o` of nevera-set.html's zones(): [neveraZones]); every
//   other pixel it drew is put back ([Nevera.clipStart], [Nevera.clipEnd]: the preview's PREVIEW.clipStart, clipEnd). So
//   no pixel of them is ever outside the opening, they are cut below by the sill, and the frame and the sill are the
//   set's, over them. They stand where the sheet's rule puts them (`PA` and the moves' offsets).
// - **The set in front** (`front.parts`: the fridge, its inside and door, the counter, the sink, the stool, the window;
//   sortY 9999): the sorted list is drawn as it is drawn: each item owns the pixels it drew last ([Nevera.item]); after
//   the list the set's own pixels of those parts are drawn again where they are nearer than the plane of the surface
//   their owner stands on ([Nevera.front], [Nevera.plane]: the floor, the counter, the sill, the fridge's top, a shelf,
//   the drawer, the stool, the wall), never over what stands on that surface itself.
// - The things in the fridge (`HUECO`: two places on a shelf, one behind the other), on the counter (`CT`), on the sill
//   (`SL`), on the fridge's top, in the drawer, the cards at `respEn` and on the wall: `moves`, read from the moved
//   source. `talk` ([Nevera.talkPlace], each face measured from its sprite: [Nevera.faceOf]); `hintBox` by state (the
//   fridge's and its inside's: `things.<id>.hintBoxes`, [NeveraThing]); `hops` (none changes); `shadows`
//   ([Nevera.shadows]); `remap` (the stories' and pairs' moved positions; [Nevera.placePair]).
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_pixel/coqui_pixel.dart' as kit show tarjeta;
import 'package:coqui_scenes/src/cocina_kit.dart' show K;
import 'package:coqui_scenes/src/nevera/nevera_places.dart';
import 'package:coqui_scenes/src/nevera/nevera_set.dart';
import 'package:coqui_scenes/src/nevera/nevera_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "nevera", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It
/// draws no random number.
Scene createNevera() => Nevera(sheetOf('nevera'));

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: Math.round of a number that may be NaN (a place that is not set): NaN stays NaN
num _roundN(num v) => v.isNaN ? double.nan : (v + 0.5).floor();

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

// JavaScript: a number of W in arithmetic (a missing one is NaN)
num _num(Object? v) => v is num ? v : _plus(v);

// JavaScript: how `"" + v` writes a value (estado, sprite keys)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `p.dir < 0` (a missing dir is not)
bool _left(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num && (p['dir'] as num) < 0;

int _h(String s) => hexColour(s);

final int _white = _h('#FFFFFF'),
    _smell0 = _h('#6A6A7A'),
    _hedor = _h('#4A8A2A'),
    _star = _h('#F0C020'),
    _cross = _h('#C8401E'),
    _empty = _h('#C8C8D4');

/// The plane of the surface a point of the sprite layer stands on (nevera-preview.html PV.plane): a wall's face
/// ([face] `'x'` or `'y'`, [at]) or a level ([v]: the (x + y) / R2 of its point), and the zones that are that surface
/// itself ([sup]: what stands on it is never drawn over by it).
typedef NeveraPlane = ({String? face, double? at, double? v, String? sup});

/// One entry of nevera.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is (nevera-preview.
/// html's tags: `id` for a person or the frog, `cosa` for a thing of W.cosas), for the sheet's front.
class NeveraItem {
  NeveraItem(this.y, this.d, {this.id, this.cosa});

  final num y;
  final void Function() d;
  final String? id;
  final Map<String, dynamic>? cosa;
}

/// A thing whose hint frame depends on the state (the sheet's `things.<id>.hintBoxes`, nevera-preview.html `hb`): the
/// fridge's by its door, its inside's by the drawer pulled out. Touches answer in its box either way.
class NeveraThing extends Thing {
  NeveraThing({
    required super.id,
    super.box,
    super.si,
    super.hand,
    super.m,
    required this.hintOf,
  });

  /// Its hint box in the state the scene shows now.
  final List<num>? Function() hintOf;

  @override
  List<num>? get hintBox => hintOf();

  @override
  set hintBox(List<num>? v) {}
}

/// The scene "La nevera" (nevera.js: `KIT.escena({id:"nevera", ...})`). Its set is [NeveraSet]; this is the sprite layer
/// and what can happen here.
class Nevera extends Escena implements SetScene, SetOverSprites, PairPlaces {
  Nevera(this.sheet) {
    _p = NeveraPlaces(sheet, neveraEngine());
    final p = _p;
    // nevera.js:15 PISO, ENC, NEV, MOS, BANCO, VEN (sheet: code line 15: the old flat picture's rows and boxes); SILL,
    // PATIO, MURO and the new rows CT, SL, MU, PA, CB, VT, the fridge's boxes NEVERA and the boxes of its inside FRUTAS
    // (moves line 15)
    PISO = p.at(15, 150);
    ENC = p.at(15, 112);
    NEV = [p.at(15, 40), p.at(15, 40), p.at(15, 56), p.at(15, 116)];
    MOS = [p.at(15, 110), p.at(15, 108)];
    BANCO = [p.at(15, 120), p.at(15, 192)];
    VEN = [p.at(15, 150), p.at(15, 36), p.at(15, 64), p.at(15, 62)];
    final l15 = p.to(
      15,
      'SILL=98,PATIO=120,MURO=70;',
      RegExp(
        r'SILL=(\d+),PATIO=(\d+),MURO=(\d+),CT=x=>Math\.round\((-?[\d.]+)\+x/2\),SL=x=>Math\.round\((-?[\d.]+)\+x/2\),'
        r'MU=x=>Math\.round\((-?[\d.]+)\+x/2\),PA=x=>Math\.round\((-?[\d.]+)\+x/2\),CB=x=>Math\.round\((-?[\d.]+)\+x/2\),'
        r'VT=x=>Math\.round\((-?[\d.]+)\+x/2\),NEVERA=\[\[(\d+),(\d+),(\d+),(\d+)\],\[(\d+),(\d+),(\d+),(\d+)\],'
        r'\[(\d+),(\d+),(\d+),(\d+)\]\],FRUTAS=\[\[(\d+),(\d+),(\d+),(\d+)\],\[(\d+),(\d+),(\d+),(\d+)\]\];',
      ),
    );
    SILL = l15[0];
    PATIO = l15[1];
    MURO = l15[2];
    _rows = {
      'CT': l15[3],
      'SL': l15[4],
      'MU': l15[5],
      'PA': l15[6],
      'CB': l15[7],
      'VT': l15[8],
    };
    // the sheet's layout.numbers are these rows
    final nums = (sheet.raw['layout'] as Map)['numbers'] as Map;
    for (final e in _rows.entries) {
      if (nums[e.key] != e.value) {
        throw SheetError(
          'nevera.js:15 moves ${e.key} to ${e.value}, the layout says ${nums[e.key]}',
        );
      }
    }
    NEVERA = [
      for (var i = 0; i < 3; i++)
        [for (var j = 0; j < 4; j++) l15[9 + i * 4 + j]],
    ];
    FRUTAS = [
      for (var i = 0; i < 2; i++)
        [for (var j = 0; j < 4; j++) l15[21 + i * 4 + j]],
    ];
    // nevera.js:16 HUECO (moves line 16: the four places on the fridge's shelves)
    final l16 = p.to(16, 'const HUECO=');
    HUECO = [
      for (var i = 0; i < 4; i++) [l16[i * 2], l16[i * 2 + 1]],
    ];
    // nevera.js:17 EN (moves line 17: the counter's places on CT, the basket on the fridge's top)
    final en = p.toSource(17, 'const EN=');
    EN = {};
    for (final m in RegExp(
      r'(\w+):\[(\d+),(?:CT\((\d+)\)(-\d+)?|(\d+))\]',
    ).allMatches(en)) {
      final x = num.parse(m[2]!);
      EN[m[1]!] = m[3] != null
          ? [x, CT(num.parse(m[3]!)) + (m[4] == null ? 0 : num.parse(m[4]!))]
          : [x, num.parse(m[5]!)];
    }
    if (EN.keys.join(',') != 'pan,frutero,vasos,pila,cesta') {
      throw SheetError('nevera.js:17 is not as the port reads it: $en');
    }
    // nevera.js:107 to :109 (moves): the cart, what lies on the yard wall and the birds on its top (MU + 6, MU + 1)
    _carrito = p.to(
      107,
      'tenida(c,"carrito"',
      RegExp(r'VEN\[0\]\+(\d+):P\.carrito\)\+(\d+)\);'),
    );
    _muroCosa = p.to(
      108,
      '(P.cosas||[])',
      RegExp(r'MU\(o\.x\)\+(\d+),0,0,o\.v'),
    )[0];
    _muroAve = p.to(109, 'tenida(c,"ave"', RegExp(r'MU\(o\.x\)\+(\d+)-'))[0];
    // nevera.js:114 (moves): what stands on the sill (SL), the smell over it
    _repisa = p.to(
      114,
      'tenida(c,o.k,o.x,SILL',
      RegExp(r'hedor\(c,o\.x,SL\(o\.x\)-(\d+)\)'),
    )[0];
    // nevera.js:122 (moves): the fruit in the drawer pulled out
    _cajonG = p.to(
      122,
      'tenida(c,"guineo",x+15',
      RegExp(r'"guineo",(\d+),(\d+)-i\*(\d+)\)'),
    );
    _cajonM = p.to(
      122,
      'tenida(c,"manzana",x+38',
      RegExp(r'"manzana",(\d+),(\d+)-i\*(\d+)\)'),
    );
    // nevera.js:126 (moves): whoever stands outside: the window's glass at their x
    _cajaFuera = p.to(
      126,
      'if(p.fuera)return',
      RegExp(r'\[R\(p\.x\)-(\d+),VT\(p\.x\)\+(\d+),(\d+),(\d+)\]'),
    );
    // nevera.js:130 (moves): a thing of W.cosas with a name: the hint hand at its top (y - 17)
    _handDy = p.to(
      130,
      'box:w=>{const o=w.cosas.find',
      RegExp(r'return o\?\[R\(o\.x\),R\(o\.y\)-(\d+)\]:null'),
    )[0];
    // nevera.js:195 (moves): where a thing thrown out lands (169 + n * 9, MU + 2); the birds' row (kept: 153 + i * 5)
    _alMuro = p.to(
      195,
      'x=169+n*9;await vuela(o,x0,y0,x,MURO+2,8);',
      RegExp(r'x=(\d+)\+n\*(\d+);await vuela\(o,x0,y0,x,MU\(x\)\+(\d+),8\);'),
    );
    _aves = [p.at(195, 153), p.at(195, 5)];
    // nevera.js:346 LUGAR (sheet: lugar: the frog on the stool, its q), CAM (views.wide), heartAt (points.corazon)
    LUGAR = {
      for (final e in sheet.lugar.entries)
        e.key: <num>[e.value.frog[0], e.value.frog[1], e.value.scale],
    };
    for (final l in LUGAR.values) {
      if (l[0] != BANCO[0] - p.at(346, 16) ||
          l[1] != BANCO[1] - p.at(346, 27) ||
          l[2] != 1) {
        throw SheetError('the sheet\'s LUGAR is not nevera.js:346\'s');
      }
    }
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    // nevera.js:347 (moves): where the answer cards stand
    _respEn = p.to(347, 'fresh:()=>({respEn:');
    _talk = sheet.talk!;
    // the sheet's things.nevera.hands (nevera-preview.html adds them as nevera.js's hand), its hint boxes by its door,
    // things.frutas.hintBoxes by the drawer
    final nv = sheet.things['nevera']!.raw;
    List<List<num>> lists(Object? v) => [
      for (final h in v as List) [for (final x in h as List) x as num],
    ];
    _neveraHands = lists(nv['hands']);
    _neveraHints = lists(nv['hintBoxes']);
    _frutasHints = lists(sheet.things['frutas']!.raw['hintBoxes']);
    // the moved boxes are the sheet's things' boxes
    if (NEVERA.map((b) => b.join(',')).join(';') !=
            lists(nv['boxes']).map((b) => b.join(',')).join(';') ||
        FRUTAS.map((b) => b.join(',')).join(';') !=
            lists(sheet.things['frutas']!.raw['boxes'])
                .map((b) => b.join(','))
                .join(';')) {
      throw SheetError(
        'nevera.js:15 NEVERA, FRUTAS are not the things\' boxes',
      );
    }
    // nevera.js:125 to :138 COSAS (sheet: code lines 130 to 138, things.<id>.box, hand and hintBox)
    cosas = [
      for (final id in QUIEN.keys) persona(id),
      for (final k in const ['leche', 'queso', 'mantequilla']) enNevera(k),
      for (final id in const ['red', 'mant', 'jarra']) sinNombre(id),
      for (final id in const [
        'v_verde',
        'v_amarillo',
        'v_rojo',
        'v_azul',
        't_pan',
        't_fruta',
      ])
        porId(id),
      Thing(
        id: 'cesta',
        si: (w) => jsTruthy(w['cesta']),
        box: [EN['cesta']![0] - 18, EN['cesta']![1] - 16, 36, 18],
        m: 0,
      ),
      // moves line 133: its box by the drawer pulled out
      NeveraThing(
        id: 'frutas',
        si: (w) => w['nev'] is Map && (w['nev'] as Map)['abierta'] == 1,
        box: (Map<String, dynamic> w) => FRUTAS[_cajonver(w) ? 1 : 0],
        m: 0,
        hintOf: () => _frutasHints[_setKeyNow().startsWith('1.2') ? 1 : 0],
      ),
      Thing(
        id: 'pan',
        si: (w) => w['mos'] is Map && (w['mos'] as Map)['pan'] != null,
        box: [EN['pan']![0] - 19, EN['pan']![1] - 18, 38, 22],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'guineo',
        si: (w) => _frutero(w, 'guineo'),
        box: [EN['frutero']![0] - 22, EN['frutero']![1] - 22, 15, 22],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'manzana',
        si: (w) => _frutero(w, 'manzana'),
        box: [EN['frutero']![0] - 7, EN['frutero']![1] - 22, 14, 22],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'china',
        si: (w) => _frutero(w, 'china'),
        box: [EN['frutero']![0] + 7, EN['frutero']![1] - 22, 15, 22],
        m: 1,
        z: true,
      ),
      // moves line 138: its box by its door; its hand (the sheet's things.nevera.hands) and hint box by its door
      NeveraThing(
        id: 'nevera',
        box: (Map<String, dynamic> w) => NEVERA[_abierta(w)],
        hand: (Map<String, dynamic> w) => _neveraHands[_abierta(w)],
        m: 0,
        hintOf: () => _neveraHints[int.parse(_setKeyNow()[0])],
      ),
      Thing(
        id: 'cocina',
        box: p.box('cocina'),
        hand: p.hand('cocina'),
        hintBox: p.hintBox('cocina'),
        m: 0,
      ),
    ];
    final ck = p.box('cocina');
    if (ck[0] != p.at(138, 22) ||
        ck[1] != p.at(138, 16) ||
        ck[2] != p.at(138, 196) ||
        ck[3] != p.at(138, 198)) {
      throw SheetError('the kitchen\'s box is not nevera.js:138\'s');
    }
  }

  @override
  final Sheet sheet;

  late final NeveraPlaces _p;

  @override
  String get id => 'nevera';

  @override
  PpEngine newEngine({bool still = false}) => neveraEngine(still: still);

  @override
  PpEngine get projection => _p.e;

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

  /* ---------- where things are ---------- */

  // nevera.js:15 PISO, ENC, NEV, MOS, BANCO, VEN, SILL, PATIO, MURO (moves line 15: the rows CT, SL, MU, PA, CB, VT and the
  // boxes NEVERA, FRUTAS)
  late final num PISO, ENC, SILL, PATIO, MURO;
  late final List<num> NEV, MOS, BANCO, VEN;
  late final Map<String, num> _rows;
  late final List<List<num>> NEVERA, FRUTAS;
  int _row(String k, num x) => _round(_rows[k]! + x / 2);
  int CT(num x) => _row('CT', x);
  int SL(num x) => _row('SL', x);
  int MU(num x) => _row('MU', x);
  int PA(num x) => _row('PA', x);
  int CB(num x) => _row('CB', x);
  int VT(num x) => _row('VT', x);

  // nevera.js:16 HUECO, :17 EN (moves)
  late final List<List<num>> HUECO;
  late final Map<String, List<num>> EN;

  // the moved lines' own numbers (moves 107, 108, 109, 114, 122, 126, 130, 195, 347)
  late final List<num> _carrito, _cajonG, _cajonM, _cajaFuera, _alMuro, _aves;
  late final num _muroCosa, _muroAve, _repisa, _handDy;
  late final List<num> _respEn;

  // the sheet's things: the fridge's hands and hint boxes by its door, its inside's hint boxes by its drawer
  late final List<List<num>> _neveraHands, _neveraHints, _frutasHints;

  // nevera.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  // nevera.js: QUIEN (abuela is drawn by mkAbuela: no `who`)
  static final Map<String, Who?> QUIEN = {
    'luis': FAM['hermano'],
    'carmen': FAM['hermana'],
    'abuelo': FAM['abuelo'],
    'mama': FAM['mama'],
    'papa': FAM['papa'],
    'abuela': null,
  };

  // the numbers of the moved source at [line] that replaces the old source starting with [src], in their order (as
  // nevera-preview.html runs it), read once
  final Map<String, List<num>> _moved = {};
  List<num> _mv(int line, String src) =>
      _moved['$line|$src'] ??= _p.to(line, src);

  // a number of nevera.js's line [line] the sheet keeps (the floor rule): one the sheet's code entry of that line names
  num _at(int line, num v) => _p.at(line, v);

  // JavaScript: `(w.nev&&w.nev.abierta)||0`
  static int _abierta(Map<String, dynamic> w) {
    final n = w['nev'];
    final a = n is Map ? n['abierta'] : null;
    return jsTruthy(a) ? (a as num).toInt() : 0;
  }

  // JavaScript: `w.nev&&w.nev.cajonver`
  static bool _cajonver(Map<String, dynamic> w) {
    final n = w['nev'];
    return n is Map && jsTruthy(n['cajonver']);
  }

  // JavaScript: `w.mos&&w.mos.frutero&&w.mos.frutero[k]>0`
  static bool _frutero(Map<String, dynamic> w, String k) {
    final m = w['mos'];
    if (m is! Map) return false;
    final f = m['frutero'];
    return f is Map && f[k] is num && (f[k] as num) > 0;
  }

  // the state of the set the host shows now (nevera-preview.html hb: a hint box drawn by the signs)
  String _setKeyNow() => setKey(host.W);

  /* ---------- the set ---------- */

  // the sheet's setKey table (setKey.key; nevera-preview.html PV.keyOf): nev (1 open, 2 half open, else shut) . cajon
  // (open only: 2 pulled out, 1 shut, 0 none) . pila ("a", "j" or "0") . banco (1 or 0)
  @override
  String setKey(Map<String, dynamic> W) {
    final n = W['nev'] is Map ? W['nev'] as Map : const {};
    final nev = n['abierta'] == 1
        ? 1
        : n['abierta'] == 2
        ? 2
        : 0;
    final cajon = nev == 1
        ? (jsTruthy(n['cajonver'])
              ? 2
              : jsTruthy(n['cajon'])
              ? 1
              : 0)
        : 0;
    final pila = W['pila'] == 'a' || W['pila'] == 'j' ? W['pila'] : '0';
    return '$nev.$cajon.$pila.${jsTruthy(W['banco']) ? 1 : 0}';
  }

  /// The part that drew each pixel of each baked state (set-kit.js `PART_TAGS`, nevera-set.html `?tags=1`: the
  /// preview's `CUR.tags`) and the state's zones (nevera-set.html zones(): the preview's `fr.ZONES`), recorded at its
  /// first bake. The same on every engine.
  static final Map<String, List<String?>> _tags = {};
  static final Map<String, NeveraZones> _zones = {};

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final state = NeveraState.fromKey(key);
    final s = NeveraSet(e, b, state);
    // the first bake of a state also records which part drew each pixel, and each pixel's zone
    final tag = !_tags.containsKey(key);
    if (tag) s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    if (tag) {
      _tags[key] = s.k.PART_TAGS!;
      _zones[key] = neveraZones(e, _tags[key]!, e.bakedZ, state);
    }
  }

  // the tags and zones of [key], baking it once on an engine of its own when no engine of this scene has
  void _bakeOnce(String key) {
    if (_tags.containsKey(key)) return;
    final e = neveraEngine();
    buildSetFor(e, PpBuild(e), key);
  }

  /// The zones of the state [key] (nevera-set.html zones(): each pixel's zone, the pixels that show the outside).
  NeveraZones zonesOf(String key) {
    _bakeOnce(key);
    return _zones[key]!;
  }

  /// The part that drew each pixel of the state [key] (set-kit.js PART_TAGS).
  List<String?> tagsOf(String key) {
    _bakeOnce(key);
    return _tags[key]!;
  }

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  // nevera-preview.html: PV.frogOn. Where the frog's feet are: on the stool (his place there), on the counter (CT), or on
  // the floor
  String frogOn(Map<String, dynamic> q) {
    final fx = (q['x'] as num) + 16, fy = (q['y'] as num) + 25, ct = CT(fx);
    if (q['x'] == LUGAR['inicio']![0] && q['y'] == LUGAR['inicio']![1]) {
      return 'stool';
    }
    if ((fy - (ct - 2)).abs() <= 2) return 'counter';
    return 'floor';
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  // nevera-preview.html: PV.casts (sheet: shadows). The frog (shown, not .5 or less faded, on the floor, not 3 or more
  // up) at .3 with his radius, from the floor point under (b.x + b.w / 2, q.y + 25); everyone shown inside (not outside
  // the window), placed, not .5 or less faded, from the floor under (x, y - 1), at .3, .65, ... to 1.7 (a child to 1.35)
  // with the people's radius; each thing of W.cosas lying on the floor (z unset, 1 or less, or 300; not 400; not above
  // the counter's foot) at .1 with the things' radius
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final SH = sheet.shadows, e = _p.e;
    ({double x, double y}) on(num sx, num sy) {
      final g = e.unproject(sx, sy);
      return (x: g.x, y: g.y);
    }

    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null &&
        jsTruthy(q['vis']) &&
        !_atMostHalf(q['al']) &&
        frogOn(q) == 'floor' &&
        !(_n(q['dy']) < -3)) {
      final b = frogBox(q), g = on(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: SH['coqui']!.radius));
    }
    final G = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          jsTruthy(p['fuera']) ||
          p['x'] == null ||
          _atMostHalf(p['al'])) {
        continue;
      }
      final g = on(_round(p['x'] as num), _round(p['y'] as num) - 1);
      final nino = QUIEN[en.key]?.nino ?? false;
      for (var z = .3; z <= (nino ? 1.35 : 1.7) + 1e-9; z += .35) {
        out.add((x: g.x, y: g.y, z: z, r: SH['people']!.radius));
      }
    }
    for (final o0 in (W['cosas'] as List?) ?? const []) {
      final o = o0 as Map<String, dynamic>?;
      if (o == null || o['vis'] == 0 || o['x'] == null) continue;
      final z = o['z'];
      if ((z != null && (z as num) > 1 && z != 300) || z == 400) continue;
      if (_round(o['y'] as num) < CB(_round(o['x'] as num)) - 3) continue;
      final g = on(_round(o['x'] as num), _round(o['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .1, r: SH['cosas']!.radius));
    }
    return out;
  }

  /* ---------- the yard through the window and the set in front: the sheet's clips and front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  List<String?>? _tagsNow;
  NeveraZones? _zonesNow;

  // the set as this frame shows it (the shadows cast), before the sprite layer (drawFrame's step 4), its own depth
  // (nevera-preview.html: CUR.img, CUR.z), its part tags (CUR.tags) and zones (CUR.zone, CUR.outside)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    final key = setKey(W);
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = baked.zb;
    _tagsNow = tagsOf(key);
    _zonesNow = zonesOf(key);
  }

  // nevera-preview.html: PV.clipStart. The picture before what patio() draws inside its clip
  Uint32List? _clip;
  void clipStart() {
    final e = _frameEngine;
    _clip = e == null ? null : Uint32List.fromList(e.pix);
  }

  // nevera-preview.html: PV.clipEnd (sheet: clips.patio). What patio() drew shows only on the set's pixels that show the
  // outside; every other pixel is put back. A frame drawn with no set (a player with no screen) is not clipped
  void clipEnd() {
    final e = _frameEngine, a = _clip, z = _zonesNow;
    _clip = null;
    if (e == null || a == null || z == null) return;
    final pix = e.pix, o = z.outside;
    for (var i = 0; i < pix.length; i++) {
      if (!o.contains(i)) pix[i] = a[i];
    }
  }

  static final double _COS = math.sqrt(3) / 2, _T30 = math.tan(math.pi / 6);

  // nevera-preview.html: PV.plane. The plane of the point an item stands on: the zone under its foot says which surface
  // (the floor under (x, y - 1); the counter, the sill, the fridge's top, a shelf or the stool under (x, y) at its
  // height; a card on the wall: the wall's face, a little before it)
  NeveraPlane plane(num x, num y, String zone) {
    final e = _p.e;
    final z0 =
        zone[math.max(0, math.min(215, y.toInt() - 1)) * 240 +
            math.max(0, math.min(239, x.toInt()))];
    List<double> g(num zz) => neveraAt(e, x, y, zz);
    if (z0 == 'c' || z0 == 'p') {
      return (face: 'y', at: g(K.CZ)[1], v: null, sup: 'cp');
    }
    if (z0 == 'v') {
      return (face: 'y', at: g(WIN.z0 - .1)[1], v: null, sup: 'vc');
    }
    if (z0 == 'q') return (face: 'x', at: g(FR.h)[0], v: null, sup: 'q');
    if (z0 == 'b') {
      final q = g(STOOL.h);
      return (face: null, at: null, v: (q[0] + q[1]) / math.sqrt2, sup: 'b');
    }
    if (z0 == 'r') {
      return (face: 'x', at: g(FR.bin[0] + .06)[0], v: null, sup: 'r');
    }
    if (z0 == 'e') {
      double? best;
      for (final zz in [...FR.shelves, FR.bin[1]]) {
        final q = g(zz);
        if (q[0] >= 0 &&
            q[0] <= FR.d &&
            q[1] >= FR.a0 &&
            q[1] <= FR.a1 &&
            (best == null || zz > best)) {
          best = zz;
        }
      }
      return (face: 'x', at: g(best ?? 0)[0], v: null, sup: 'e');
    }
    if (z0 == 't' || z0 == 'w') {
      return x + .5 < e.OX
          ? (face: 'x', at: .05, v: null, sup: null)
          : (face: 'y', at: .05, v: null, sup: null);
    }
    final q = neveraAt(e, x, y - 1, 0);
    return (face: null, at: null, v: (q[0] + q[1]) / math.sqrt2, sup: null);
  }

  // nevera-preview.html: PV.planeDepth. The depth of a plane at a pixel
  double planeDepth(NeveraPlane pl, int ix, int iy) {
    final e = _p.e, OX = e.OX, OY = e.OY;
    const SIN = .5, R2 = math.sqrt2;
    if (pl.v != null) return pl.v! / _COS - (iy + .5 - OY) * _T30 / 26;
    final u = (ix + .5 - OX) / 26, k = (iy + .5 - OY) / 26;
    final x = pl.face == 'y' ? pl.at! + u * R2 : pl.at!,
        y = pl.face == 'y' ? pl.at! : pl.at! - u * R2,
        v = (x + y) / R2,
        z = (v * SIN - k) / _COS;
    return v * _COS + z * SIN;
  }

  // nevera-preview.html: PV.footOf. Where an item of the sorted list stands: the frog's feet, a person's, a thing's
  List<num>? footOf(NeveraItem o, Map<String, dynamic> w) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return [b.x + (b.w.toInt() >> 1), (q['y'] as num) + 26];
    }
    if (o.id != null) {
      final p = (w['gente'] as Map)[o.id] as Map;
      return [_round(p['x'] as num), _round(p['y'] as num)];
    }
    final c = o.cosa;
    if (c != null) return [_round(c['x'] as num), _round(c['y'] as num)];
    return null;
  }

  // nevera-preview.html: PREVIEW.OWN. Which item of the sorted list drew each pixel last (null: none yet this frame)
  List<NeveraItem?>? _own;

  // nevera-preview.html: PREVIEW.item. Every item of the sorted list owns the pixels it drew last (a pixel whose colour it
  // changed). A frame drawn with no set (a player with no screen) owns nothing
  void item(NeveraItem o) {
    final e = _frameEngine;
    if (e == null) return o.d();
    final own = _own ??= List<NeveraItem?>.filled(e.W * e.H, null);
    final pix = e.pix, before = Uint32List.fromList(pix);
    o.d();
    for (var i = 0; i < pix.length; i++) {
      if ((pix[i] & 0xFFFFFF) != (before[i] & 0xFFFFFF)) own[i] = o;
    }
  }

  // nevera-preview.html: PREVIEW.front (sheet: front.parts). After the sorted list, the set's own pixels of the front
  // parts drawn again where their owner stands behind them: not on the owner's own surface (its zones), not within 3 rows
  // over the foot of a thing standing on a raised surface, and only where bakedZ[i] > the plane's depth there
  void front() {
    final e = _frameEngine,
        s = _setFrame,
        Z = _setZ,
        T = _tagsNow,
        O = _own,
        zn = _zonesNow;
    if (e == null || s == null || Z == null || T == null || O == null) return;
    if (zn == null) return;
    final parts = sheet.frontParts.keys.toSet();
    final cache = <NeveraItem, NeveraPlane?>{};
    final pix = e.pix, W0 = e.W, zone = zn.zone;
    for (var i = 0; i < pix.length; i++) {
      final t = T[i], o = O[i];
      if (o == null || t == null || !parts.contains(t)) continue;
      final NeveraPlane? v;
      if (cache.containsKey(o)) {
        v = cache[o];
      } else {
        final f = footOf(o, W);
        v = cache[o] = f == null ? null : plane(f[0], f[1], zone);
      }
      if (v == null) continue;
      if (v.sup != null && v.sup!.contains(zone[i])) continue;
      final y = i ~/ W0;
      if (v.sup != null &&
          v.sup != 'b' &&
          o.cosa != null &&
          y >= _round(o.cosa!['y'] as num) - 3) {
        continue;
      }
      if (!(Z[i] > planeDepth(v, i % W0, y))) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  /* ---------- the picture ---------- */

  // nevera.js: cosa (here cosaSpr: the kit's Escena has a `cosa` of its own, the thing of a key)
  Sprite cosaSpr(String k, [Object? c]) =>
      spr('nv$k${c == null ? '' : _js(c)}', () => neveraCosa(k, c));

  // nevera.js: tenida
  void tenida(
    Ctx c,
    String k,
    num x,
    num y, [
    Object? ang,
    Object? esc,
    Object? v,
  ]) {
    final im = cosaSpr(k, v);
    if (jsTruthy(ang) || jsTruthy(esc)) {
      c.save();
      c.translate(_round(x).toDouble(), _round(y).toDouble());
      if (jsTruthy(ang)) c.rotate((ang as num).toDouble());
      if (jsTruthy(esc)) {
        final s = (esc as num).toDouble();
        c.scale(s, s);
      }
      c.drawImage(im, -(im.w >> 1), -im.h);
      c.restore();
    } else {
      c.drawImage(im, _round(x) - (im.w >> 1), _round(y) - im.h);
    }
  }

  // nevera.js: hedor
  void hedor(Ctx c, num x, num y) {
    final t = (F >> 3) % 2;
    const dxs = [-5, 0, 5];
    for (var i = 0; i < dxs.length; i++) {
      for (var k = 0; k < 6; k++) {
        fr(c, x + dxs[i] + ((k + i + t) % 2), y - k, 1, 1, _hedor);
      }
    }
  }

  // nevera.js: patio (moves 107 to 109, 114; dropped 112, 113: the frame and the sill are the set's). The yard, seen in
  // the window: the cart, the birds and what lies on the wall, whoever stands outside, only on the set's outside pixels
  // (sheet: clips.patio, nevera-preview.html PREVIEW.clipStart, clipEnd); then what stands on the sill
  void patio(Ctx c, int a) {
    final P = (W['patio'] as Map<String, dynamic>?) ?? const {},
        Gt = (W['gente'] as Map<String, dynamic>?) ?? const {};
    clipStart();
    if (jsTruthy(P['carrito'])) {
      final cx = P['carrito'] == 1 ? VEN[0] + _carrito[0] : P['carrito'] as num;
      tenida(c, 'carrito', cx, MU(cx) + _carrito[1]);
    }
    for (final o0 in (P['cosas'] as List?) ?? const []) {
      final o = o0 as Map;
      tenida(
        c,
        o['k'] as String,
        o['x'] as num,
        MU(o['x'] as num) + _muroCosa,
        0,
        0,
        o['v'],
      );
    }
    for (final o0 in (P['aves'] as List?) ?? const []) {
      final o = o0 as Map, come = jsTruthy(o['come']);
      tenida(
        c,
        'ave',
        o['x'] as num,
        MU(o['x'] as num) + _muroAve - 0,
        0,
        0,
        '${come ? 'c' : ''}${come && a % 2 != 0 ? '1' : '0'}',
      );
    }
    final fuera = [
      for (final id in Gt.keys)
        if (Gt[id] != null &&
            jsTruthy((Gt[id] as Map)['fuera']) &&
            (Gt[id] as Map)['vis'] != 0)
          id,
    ];
    // JavaScript's sort is stable: the index breaks a tie
    final byX = [...fuera.indexed]
      ..sort((m, n) {
        final d = _num((Gt[m.$2] as Map)['x'])
            .compareTo(_num((Gt[n.$2] as Map)['x']));
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    for (final (_, id) in byX) {
      gente(c, id, a);
      final p = Gt[id] as Map;
      if (jsTruthy(p['gorro'])) {
        tenida(
          c,
          'sombrero',
          _round(p['x'] as num),
          _round(p['y'] as num) - alto(id) + 6,
        );
      }
    }
    clipEnd();
    for (final o0 in (W['repisa'] as List?) ?? const []) {
      final o = o0 as Map;
      if (o['vis'] != 0) {
        tenida(
          c,
          o['k'] as String,
          o['x'] as num,
          SL(o['x'] as num) + _n(o['dy']),
          jsTruthy(o['rot']) ? o['rot'] : 0,
          jsTruthy(o['e']) ? o['e'] : 0,
          o['v'],
        );
        if (o['v'] == 'manchas') {
          hedor(c, o['x'] as num, SL(o['x'] as num) - _repisa);
        }
      }
    }
  }

  // nevera.js: nevera (moves 16, 122; dropped 118, 119, 122, 123, 124: the fridge's inside, door and drawer are the
  // set's). The basket on its top; open, what stands on its shelves and the fruit in the drawer pulled out
  void nevera(Ctx c, int a) {
    final N = (W['nev'] as Map<String, dynamic>?) ?? const {};
    final cesta = W['cesta'];
    if (jsTruthy(cesta)) {
      tenida(
        c,
        'cesta',
        EN['cesta']![0],
        EN['cesta']![1],
        0,
        0,
        (cesta as Map)['n'],
      );
    }
    if (N['abierta'] == 1) {
      if (jsTruthy(N['soporte'])) {
        tenida(c, 'soporte', HUECO[0][0], HUECO[0][1]);
        tenida(c, 'platoazul', HUECO[1][0], HUECO[1][1] + 1);
      }
      final h = (N['h'] as List?) ?? const [];
      for (var i = 0; i < h.length; i++) {
        final o = h[i];
        if (o is Map && i < HUECO.length) {
          tenida(c, o['k'] as String, HUECO[i][0], HUECO[i][1], 0, 0, o['v']);
        }
      }
      final C = (N['cajon'] as Map?) ?? const {};
      if (jsTruthy(N['cajonver'])) {
        for (var i = 0; i < _n(C['guineo']); i++) {
          tenida(c, 'guineo', _cajonG[0], _cajonG[1] - i * _cajonG[2]);
        }
        for (var i = 0; i < _n(C['manzana']); i++) {
          tenida(c, 'manzana', _cajonM[0], _cajonM[1] - i * _cajonM[2]);
        }
      }
    }
  }

  // nevera.js: alto
  int alto(String id) {
    final w = QUIEN[id];
    return id == 'abuela'
        ? 51
        : w != null && w.nino
        ? 44
        : 56;
  }

  // nevera.js: caja (moves line 126: whoever stands outside: the window's glass at their x)
  List<num>? caja(String id) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return null;
    if (jsTruthy(p['fuera'])) {
      return [
        _round(p['x'] as num) - _cajaFuera[0],
        VT(p['x'] as num) + _cajaFuera[1],
        _cajaFuera[2],
        _cajaFuera[3],
      ];
    }
    final h = alto(id);
    return [_round(p['x'] as num) - 11, _round(p['y'] as num) - h, 22, h];
  }

  // nevera.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // nevera.js: G
  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;

  // nevera.js: ob
  Map<String, dynamic>? ob(String id) =>
      _cosaOf(W, id) as Map<String, dynamic>?;

  static Map? _cosaOf(Map<String, dynamic> w, String id) {
    for (final o in (w['cosas'] as List?) ?? const []) {
      if (o is Map && o['id'] == id) return o;
    }
    return null;
  }

  // nevera.js: porId (moves line 130: the hint hand at its top)
  Thing porId(String id, {num m = 1}) => Thing(
    id: id,
    si: (w) {
      for (final o in (w['cosas'] as List?) ?? const []) {
        if (o is Map && o['id'] == id && o['vis'] != 0) return true;
      }
      return false;
    },
    box: (Map<String, dynamic> w) {
      final o = _cosaOf(w, id)!;
      return [_round(o['x'] as num) - 9, _round(o['y'] as num) - 19, 18, 23];
    },
    hand: (Map<String, dynamic> w) {
      final o = _cosaOf(w, id);
      return o != null
          ? [_round(o['x'] as num), _round(o['y'] as num) - _handDy]
          : null;
    },
    m: m,
    z: true,
  );

  // nevera.js: sinNombre (porId's, m 0, z 1)
  Thing sinNombre(String id) => porId(id, m: 0);

  // nevera.js: enNevera
  Thing enNevera(String k) => Thing(
    id: k,
    si: (w) {
      final n = w['nev'];
      if (n is! Map || !jsTruthy(n['abierta'])) return false;
      return ((n['h'] as List?) ?? const []).any(
        (o) => o is Map && o['k'] == k,
      );
    },
    box: (Map<String, dynamic> w) {
      final i = ((w['nev'] as Map)['h'] as List).indexWhere(
        (o) => o is Map && o['k'] == k,
      );
      return [HUECO[i][0] - 13, HUECO[i][1] - 23, 26, 26];
    },
    m: 1,
    z: true,
  );

  // nevera.js: COSAS
  @override
  late final List<Thing> cosas;

  /* ---------- drawing ---------- */

  // JavaScript: `o.k || o` (a thing held: its kind, or the string itself) and `o.v`
  static String _kOf(Object? o) =>
      o is Map ? (jsTruthy(o['k']) ? o['k'] as String : '$o') : '$o';
  static Object? _vOf(Object? o) => o is Map ? o['v'] : null;

  // JavaScript: `v || d` for a number a story gives
  static num _or(Object? v, num d) => jsTruthy(v) ? _plus(v) : d;

  // nevera.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final w = QUIEN[id],
        x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        d = _left(p) ? -1 : 1;
    final paso = jsTruthy(p['paso']) && a % 2 != 0;
    if (id == 'abuela') {
      final ps = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
          top = y - 50 + (paso ? -1 : 0);
      c.save();
      c.translate(x.toDouble(), top.toDouble());
      if (((ps == 'offer' || ps == 'bless') ? -d : d) < 0) c.scale(-1, 1);
      c.drawImage(spr('ab$ps$habla', () => mkAbuela(ps, habla != 0)), -30, 0);
      c.restore();
      final lleva = p['lleva'];
      if (jsTruthy(lleva)) {
        tenida(c, _kOf(lleva), x + d * 14, y - 17, 0, 0, _vOf(lleva));
      }
      if (jsTruthy(p['bebe'])) {
        tenida(c, 'vaso', x + d * 8, y - 24 - (a % 2), 0, 0, p['bebe']);
      }
      final alza = p['alza'];
      if (jsTruthy(alza)) {
        final z = alza as Map;
        tenida(
          c,
          z['k'] as String,
          x + d * _or(z['dx'], 18),
          y - 22 + _n(z['dy']),
          0,
          _or(z['e'], 2),
          z['v'],
        );
      }
      final come = p['come'];
      if (jsTruthy(come)) {
        final m = come as Map;
        tenida(c, m['k'] as String, x + d * 7, y - 30 + (a % 2), 0, 0, m['v']);
      }
      return;
    }
    final pose = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
        cierra = jsTruthy(p['cierra']),
        w2 = cierra ? w!.copyWith(dormido: true) : w!,
        im = spr(
          'pm$id$pose${habla}0${cierra ? 'c' : ''}',
          () => mkPersona(w2, pose, habla != 0, false),
        ),
        top = y - im.h + 1 + (paso ? -1 : 0) + _n(p['dy']);
    c.save();
    c.translate(x.toDouble(), top.toDouble());
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    final bebe = p['bebe'];
    if (jsTruthy(bebe) && id == 'mama') {
      final e = bebe == 1 ? 'idle' : _js(bebe),
          bi = spr('bb$e${a % 2}', () => mkBebe(e, a % 2 != 0));
      c.drawImage(bi, x + d * 2 - 13 + d * 8, y - 42);
      final bc = p['bebecosa'];
      if (jsTruthy(bc)) {
        final m = bc as Map;
        tenida(c, m['k'] as String, x + d * 16, y - 27, 0, 0, m['v']);
      }
    }
    final lleva = p['lleva'];
    if (jsTruthy(lleva)) {
      tenida(
        c,
        _kOf(lleva),
        x + d * 10,
        top + (w.nino ? 34 : 38),
        0,
        0,
        _vOf(lleva),
      );
    }
    final alza = p['alza'];
    if (jsTruthy(alza)) {
      final az = alza is Map ? alza : const {};
      final ax = x + d * _or(az['dx'], 13),
          ay = top + (w.nino ? 30 : 34) + _n(az['dy']);
      tenida(c, _kOf(alza), ax, ay, 0, _or(az['e'], 2), _vOf(alza));
    }
    if (jsTruthy(bebe) && id != 'mama') {
      final bm = bebe is Map ? bebe : null;
      final hasK = bm != null && jsTruthy(bm['k']);
      tenida(
        c,
        hasK ? bm['k'] as String : 'vaso',
        x + d * 6,
        top + (w.nino ? 26 : 30) - (a % 2),
        0,
        bm != null && jsTruthy(bm['e']) ? bm['e'] : 0,
        hasK ? bm['v'] : bebe,
      );
    }
    final come = p['come'];
    if (jsTruthy(come)) {
      final m = come as Map;
      tenida(c, m['k'] as String, x + d * 6, top + 22 + (a % 2), 0, 0, m['v']);
    }
  }

  // nevera.js: nube. A thought: a thing (and a second one)
  void nube(Ctx g, num x, num y, Map o) {
    fr(g, x - 1, y - 1, 28, 22, OUT);
    fr(g, x, y, 26, 20, _white);
    fr(g, x + 10, y + 20, 4, 4, OUT);
    fr(g, x + 11, y + 21, 2, 2, _white);
    tenida(
      g,
      o['k'] as String,
      x + 13,
      y + 18,
      0,
      jsTruthy(o['e']) ? o['e'] : 0,
      o['v'],
    );
    if (jsTruthy(o['k2'])) {
      tenida(g, o['k2'] as String, x + 19, y + 18, 0, 0, o['v2']);
    }
  }

  // nevera.js: rana
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
    final en = W['encima'];
    if (jsTruthy(en)) {
      final m = en as Map;
      tenida(g, m['k'] as String, cx, b.y + dy + 3, 0, 0, m['v']);
    }
  }

  // nevera.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // nevera.js: draw (dropped 156, 162, 165: the background, the water in the sink, the old stool; moves 160, 161, 163)
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        M = (W['mos'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // nevera.js:156 c.drawImage(spr("nevera",fondo),0,0) -> the set, for setKey(W) (sheet: dropped)
    patio(c, a);
    nevera(c, a);
    // the counter
    if (M['pan'] != null) {
      tenida(c, 'pan', EN['pan']![0], EN['pan']![1], 0, 0, M['pan']);
    }
    final fru = M['frutero'];
    if (jsTruthy(fru)) {
      final f = fru as Map, x = EN['frutero']![0], y = EN['frutero']![1];
      tenida(c, 'frutero', x, y);
      for (var i = 0; i < _n(f['guineo']); i++) {
        tenida(c, 'guineo', x - 14 + i * 2, y - 5 - i * 4);
      }
      for (var i = 0; i < _n(f['manzana']); i++) {
        tenida(c, 'manzana', x - 1 + (i % 2) * 4, y - 5 - i * 5);
      }
      for (var i = 0; i < _n(f['china']); i++) {
        tenida(c, 'china', x + 13 - (i % 2) * 4, y - 5 - i * 5);
      }
    }
    // nevera.js:160 (moves): the counter's cups on CT
    final vasos = (M['vasos'] as List?) ?? const [];
    for (var i = 0; i < vasos.length; i++) {
      final v = vasos[i] as Map;
      final x = v['x'] != null ? v['x'] as num : EN['vasos']![0] - i * 11;
      tenida(c, 'vaso', x, CT(x) - 1, 0, 0, v['de']);
    }
    // nevera.js:161 (moves): the counter's plates on CT
    final platos = (M['platos'] as List?) ?? const [];
    for (var i = 0; i < platos.length; i++) {
      final p = platos[i] as Map;
      final x = p['x'] != null ? p['x'] as num : _at(161, 150) + i * 20,
          y = CT(x);
      tenida(c, 'plato', x, y, 0, 2);
      final items = (p['items'] as List?) ?? const [];
      for (var j = 0; j < items.length; j++) {
        final o = items[j] as Map;
        tenida(c, o['k'] as String, x - 5 + j * 10, y - 3, 0, 0, o['v']);
      }
    }
    // nevera.js:162, the water in the sink, is dropped (sheet: dropped): the set's (setKey pila)
    // nevera.js:163 (moves): the picnic basket on CT + 1
    final can = W['canasta'];
    if (jsTruthy(can)) {
      final K0 = can as Map;
      final ky = jsTruthy(K0['y']) ? K0['y'] as num : CT(K0['x'] as num) + 1;
      tenida(c, 'canasta', K0['x'] as num, ky);
      final items = (K0['items'] as List?) ?? const [];
      for (var i = 0; i < items.length; i++) {
        final o = items[i] as Map;
        tenida(
          c,
          o['k'] == 'platofruta' ? 'manzana' : o['k'] as String,
          (K0['x'] as num) - 13 + i * 13,
          ky - 9,
          0,
          0,
          o['v'],
        );
      }
    }
    final L = <NeveraItem>[];
    // nevera.js:165, the old stool (W.banco), is dropped (sheet: dropped): the set's (setKey banco)
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0 && !jsTruthy(p['fuera'])) {
        L.add(NeveraItem(_num(p['y']), () => gente(c, id, a), id: id));
      }
    }
    for (final o0 in (W['cosas'] as List?) ?? const []) {
      final o = o0 as Map<String, dynamic>;
      if (o['vis'] != 0) {
        L.add(
          NeveraItem(o['z'] != null ? o['z'] as num : (o['y'] as num) + 1, () {
            tenida(
              c,
              o['k'] as String,
              o['x'] as num,
              o['y'] as num,
              o['rot'],
              jsTruthy(o['e']) ? o['e'] : 0,
              o['v'],
            );
            if (o['v'] == 'viejo' || o['v'] == 'vieja') {
              hedor(c, o['x'] as num, (o['y'] as num) - 13);
            }
          }, cosa: o),
        );
      }
    }
    if (jsTruthy(q['vis'])) {
      L.add(NeveraItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
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
    // the sheet's front: the set's own parts drawn again over whoever is behind them (front.parts, sortY 9999)
    front();
    for (final o0 in (W['vuelos'] as List?) ?? const []) {
      final o = o0 as Map<String, dynamic>;
      tenida(
        c,
        o['k'] as String,
        o['x'] as num,
        o['y'] as num,
        o['rot'],
        0,
        o['v'],
      );
    }
    final olf = W['olfato'];
    if (jsTruthy(olf)) {
      final t = (F >> 2) % 2,
          ox = (olf as Map)['x'] as num,
          oy = olf['y'] as num;
      const qs = [
        [-3, -2],
        [2, -6],
        [-1, -10],
      ];
      for (var i = 0; i < qs.length; i++) {
        if ((i + t) % 2 == 0 || i == 1) {
          fr(c, ox + qs[i][0] - 1, oy + qs[i][1] - 1, 4, 4, _smell0);
          fr(c, ox + qs[i][0], oy + qs[i][1], 2, 2, _white);
        }
      }
    }
    final vista = W['vista'];
    if (jsTruthy(vista)) {
      final o = ob((vista as Map)['id'] as String);
      if (o != null) {
        tenida(
          c,
          'vista',
          _round(o['x'] as num),
          _round(o['y'] as num) - 16,
          0,
          0,
          '${_js(o['v'])}:${jsTruthy(o['n']) ? 1 : 0}',
        );
      }
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null &&
          p['vis'] != 0 &&
          !jsTruthy(p['fuera']) &&
          p['alza'] is Map &&
          (p['alza'] as Map)['v'] == 'manchas') {
        hedor(
          c,
          _round(p['x'] as num) + _n((p['alza'] as Map)['dx']),
          _round(p['y'] as num) - alto(id) - 28,
        );
      }
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['piensa']) && p['vis'] != 0) {
        nube(
          c,
          _round(p['x'] as num) - 14 + _n(p['pdx']),
          _round(p['y'] as num) - alto(id) - 26,
          p['piensa'] as Map,
        );
      }
    }
    if (jsTruthy(q['vis']) && jsTruthy(q['piensa'])) {
      final b = frogBox(q);
      nube(c, b.x + (b.w.toInt() >> 1) - 13, b.y - 24, q['piensa'] as Map);
    }
    // nevera.js:176 a person's bubble, where the sheet's talk puts it
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
    // nevera.js:177 the frog's bubble, where the sheet's talk puts it
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
    _tagsNow = null;
    _zonesNow = null;
    _own = null;
  }

  // nevera-preview.html: PV.FACES. Each bare sprite's face, measured on first use: the middle of its top 10 rows and its
  // first row, as drawn at (60, 100) on a 120 x 120 canvas (abuela with her top at 50, 30 px left of her x)
  static final Map<String, List<int>> _faces = {};

  // nevera-preview.html: PV.faceOf (sheet talk.faces). A person's face: [x + hx - 6, y + dy + top + 6, 12, 10]
  List<num> faceOf(String id, Map<String, dynamic> p) {
    final pose = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
        d = _left(p) ? -1 : 1,
        cierra = jsTruthy(p['cierra']);
    final k = '$id|$pose|$d|${cierra ? 1 : 0}';
    final f = _faces[k] ??= () {
      final Sprite im;
      final int ox, oy;
      final bool flip;
      if (id == 'abuela') {
        im = spr('ab${pose}0', () => mkAbuela(pose, false));
        ox = 30;
        oy = 50;
        flip = ((pose == 'offer' || pose == 'bless') ? -d : d) < 0;
      } else {
        final w = QUIEN[id]!, w2 = cierra ? w.copyWith(dormido: true) : w;
        im = mkPersona(w2, pose, false, false);
        ox = PX;
        oy = 100 - im.h + 1;
        flip = (pose == 'offer' ? -d : d) < 0;
      }
      // the canvas column of a sprite column sx: 60 - ox + sx, or flipped 60 + ox - 1 - sx
      var top = -1, lo = 1 << 30, hi = -(1 << 30);
      for (var sy = 0; sy < im.h; sy++) {
        final y = oy + sy;
        if (y < 0 || y >= 120) continue;
        var a = -1, b = -1;
        for (var cx = 0; cx < 120; cx++) {
          final sx = flip ? 60 + ox - 1 - cx : cx - 60 + ox;
          if (sx < 0 || sx >= im.w) continue;
          if ((im.px[sy * im.w + sx] >> 24 & 255) > 40) {
            if (a < 0) a = cx;
            b = cx;
          }
        }
        if (a >= 0) {
          if (top < 0) top = y;
          if (y < top + 10) {
            lo = math.min(lo, a);
            hi = math.max(hi, b);
          }
        }
      }
      return [_round((lo + hi + 1) / 2) - 60, top - 100];
    }();
    return [
      _round(p['x'] as num) + f[0] - 6,
      _round(p['y'] as num) + _round(_n(p['dy'])) + f[1] + 6,
      12,
      10,
    ];
  }

  // nevera-preview.html: PV.faces. Every face shown: each person's (placed, not less than half faded in) and the frog's
  List<List<num>> faces(Map<String, dynamic> w) {
    final out = <List<num>>[];
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          p['x'] == null ||
          (p['al'] != null && (p['al'] as num) < .5)) {
        continue;
      }
      out.add(faceOf(en.key, p));
    }
    final cq = w['cq'] as Map<String, dynamic>?;
    if (cq != null &&
        jsTruthy(cq['vis']) &&
        !(cq['al'] is num && (cq['al'] as num) < .5)) {
      final b = frogBox(cq);
      out.add([b.x + 2, b.y + _round(_n(cq['dy'])), b.w - 4, _round(b.h * .6)]);
    }
    return out;
  }

  // nevera-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside
  // the head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view,
  // clear of the corner card (W.tarjeta: talk.board, + the view's x0) and of every face; if none is, [top] (the old)
  List<num> talkPlace(List<num> top, num h, Object? k, Map<String, dynamic> w) {
    if (!jsTruthy(k) || !sheet.bubbleRects.containsKey(k)) return top;
    final T = _talk, Rc = sheet.bubbleRects[k]!, x0 = host.cam[0];
    final fs = faces(w), boards = <List<num>>[];
    if (jsTruthy(w['tarjeta'])) {
      final b = [...T.boardRect!];
      boards.add([b[0] + x0, b[1], b[2], b[3]]);
    }
    bool meets(List<num> a, List<num> b) =>
        a[0] < b[0] + b[2] &&
        b[0] < a[0] + a[2] &&
        a[1] < b[1] + b[3] &&
        b[1] < a[1] + a[3];
    for (final pl in T.places) {
      final tx = top[0] + pl.side * (h + 16),
          ty = top[1] + pl.dy,
          r = [tx + Rc[0], ty + Rc[1], Rc[2], Rc[3]];
      if (r[0] >= x0 &&
          r[1] >= 0 &&
          r[0] + r[2] <= x0 + 196 &&
          r[1] + r[3] <= 216 &&
          !boards.any((b) => meets(r, b)) &&
          !fs.any((f) => meets(r, f))) {
        return [tx, ty];
      }
    }
    return top;
  }

  // nevera.js: talkAt
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final p =
        (W['gente'] as Map<String, dynamic>?)?[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    if (jsTruthy(p['fuera'])) {
      return [_round(p['x'] as num), _round(p['y'] as num) - alto(who) - 1];
    }
    return [_round(p['x'] as num), _round(p['y'] as num) - alto(who) - 1];
  }

  // nevera.js: respIcon
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    g.smoothing = false;
    final hw = w.toInt() >> 1;
    if (k == 'c_leche') {
      tenida(g, 'leche', x + hw, y + h - 4, 0, 1.5, 4);
    } else if (k == 'c_queso') {
      tenida(g, 'queso', x + hw, y + h - 6, 0, 1.5, 3);
    }
    return null;
  }

  // nevera.js: hud. The card steps aside while three picture bubbles stand at the top
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (!jsTruthy(W['tarjeta'])) return;
    kit.tarjeta(g, 3, 3, 66, 24);
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
        g.fillStyle = _star;
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
        g.fillStyle = _cross;
        for (var k = 0; k < 11; k++) {
          g.fillRect(x + 1 + k, y + 2 + k, 2, 1);
          g.fillRect(x + 11 - k, y + 2 + k, 2, 1);
        }
      } else {
        g.fillStyle = _empty;
        g.fillRect(x + 1, y + 13, 12, 1);
        g.fillRect(x + 1, y + 1, 1, 12);
        g.fillRect(x + 12, y + 1, 1, 12);
        g.fillRect(x + 1, y + 1, 12, 1);
      }
    }
  }

  // nevera.js: marca
  void marca(Object? m) {
    final l = W['marcas'] is List ? W['marcas'] as List : const [];
    final i = l.indexOf(null);
    if (i >= 0) l[i] = m;
  }

  /* ---------- moving things ---------- */

  // nevera.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = _num(p['x']), y0 = _num(p['y']);
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _roundN(math.sqrt(dx * dx + dy * dy) / 6));
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

  // nevera.js: vuela (an arc 10 px high)
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
      v['y'] = y0 + (y1 - y0) * t - math.sin(t * math.pi) * 10;
      await wait(TICK);
    }
    vuelos.remove(v);
  }

  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;

  // nevera.js: cx, pies
  num cx() => (_cq['x'] as num) + 16;
  num pies() => (_cq['y'] as num) + 27;

  // nevera.js: ranaA
  Future<void> ranaA(num x, num y, [num? h]) async {
    final q = _cq,
        dx = x - 16 - (q['x'] as num),
        dy = y - 27 - (q['y'] as num),
        d = math.sqrt(dx * dx + dy * dy);
    if (d < 3) return;
    await hopTo(
      _round(x - 16),
      _round(y - 27),
      (h != null && h != 0 ? h : math.max(1, math.min(3, _round(d / 40))))
          .toInt(),
    );
  }

  // nevera.js: alBanco
  Future<void> alBanco() => ranaA(BANCO[0], BANCO[1]);

  // nevera.js: alMuro (moves line 195: it lands on the yard wall's top, MU + 2). A thing flies out of the window and
  // lands on the yard wall; a bird hops to it and pecks. What was thrown before is gone, unless it was good food (bueno):
  // that stays with its bird
  Future<void> alMuro(
    Map<String, dynamic> o,
    num x0,
    num y0,
    bool bueno,
  ) async {
    final P = W['patio'] as Map<String, dynamic>;
    P['cosas'] = <dynamic>[
      for (final q in P['cosas'] as List)
        if (jsTruthy((q as Map)['bueno'])) q,
    ];
    final aves = P['aves'] as List;
    for (var i = 0; i < aves.length; i++) {
      final a = aves[i] as Map;
      if (!jsTruthy(a['fijo'])) {
        a['come'] = 0;
        a['x'] = _aves[0] + i * _aves[1];
      }
    }
    final n = math.min((P['cosas'] as List).length, 3),
        x = _alMuro[0] + n * _alMuro[1];
    await vuela(o, x0, y0, x, MU(x) + _alMuro[2], 8);
    (P['cosas'] as List).add(<String, dynamic>{
      'x': x,
      'bueno': bueno ? 1 : 0,
      ...o,
    });
    SFX.blip();
    Map? av;
    for (final a in aves) {
      if (!jsTruthy((a as Map)['fijo'])) {
        av = a;
        break;
      }
    }
    if (av != null) {
      av['x'] = x + 6;
      av['come'] = 1;
      if (bueno) av['fijo'] = 1;
    }
    await wait(bueno ? 700 : 450);
  }

  // nevera.js: corre. An act a story lets run on (`suelto`): it goes on while the story does, and `ya` waits for it
  Future<void> corre(Map<String, dynamic>? o, Future<void> pr) {
    if (o != null && jsTruthy(o['suelto'])) {
      W['_mov'] = pr;
      return Future.value();
    }
    return pr;
  }

  // JavaScript: `a.find(f)` (null: undefined)
  static Map? _find(List l, bool Function(Map m) f) {
    for (final m in l) {
      if (m is Map && f(m)) return m;
    }
    return null;
  }

  Map<String, dynamic> get _nev => W['nev'] as Map<String, dynamic>;
  List get _repisaL => W['repisa'] as List;

  // JavaScript: `m[k]--` of a count
  void _dec(Map m, String k) => m[k] = _num(m[k]) - 1;

  // JavaScript: `+(o.ms||d)`
  static num _ms(Map<String, dynamic> o, num d) =>
      jsTruthy(o['ms']) ? _plus(o['ms']) : d;

  // the place of whoever stands outside (moves: PA(x) + dy at x)
  List<num> _pa(int line, String src) {
    final m = _mv(line, src);
    return [m[0], PA(m[1]) + (m.length > 2 ? m[2] : 0)];
  }

  // nevera.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'marca': (o) async {
      marca(o['que']);
      SFX.blip();
      await wait(250);
    },
    'ya': (o) async {
      final p = W['_mov'];
      W['_mov'] = null;
      if (p is Future) await p;
    },
    'g': (o) async {
      final p = G(o['quien'] as String);
      if (p == null) return;
      for (final k in o.keys) {
        if (!const ['act', 'quien', 'ms'].contains(k)) {
          p[k] = o[k] == '' ? null : o[k];
        }
      }
      if (jsTruthy(o['ms'])) await wait(_plus(o['ms']));
    },
    'nota': (o) async {
      V[o['k'] as String] = o['v'] == null ? '1' : _js(o['v']);
    },

    /* ----- story 30: No hay leche ----- */
    // The fridge has one holder for the bottle of milk and one dish for the cheese: W.nev.h[0], W.nev.h[1]. Papá, in the
    // yard, fetches what the frog sends him for, for a coin. Whatever he brings, Luis carries to the fridge: a thing whose
    // place is taken stays on the counter.
    // (moves line 206: papá and Luis outside on PA; line 208: the frog's two cards on the tile band)
    'inicio30': (o) async {
      final pa = _pa(206, 'papa:{x:158,y:PATIO,'),
          lu = _pa(206, 'luis:{x:173,y:PATIO-4,'),
          ct = _mv(208, '{id:"carta_leche"');
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': _at(206, 142),
          'y': _at(206, 180),
          'dir': 1,
          'lleva': <String, dynamic>{'k': 'platopan', 'v': 2},
        },
        'carmen': <String, dynamic>{
          'x': _at(206, 178),
          'y': _at(206, 204),
          'dir': 1,
        },
        'mama': <String, dynamic>{
          'x': _at(206, 205),
          'y': _at(206, 208),
          'dir': -1,
          'bebe': 1,
        },
        'papa': <String, dynamic>{'x': pa[0], 'y': pa[1], 'dir': 1, 'fuera': 1},
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'dir': -1,
          'fuera': 1,
        },
        'abuelo': <String, dynamic>{'vis': 0},
      };
      W['nev'] = <String, dynamic>{
        'abierta': 1,
        'soporte': 1,
        'h': <dynamic>[
          <String, dynamic>{'k': 'leche', 'v': 4},
          <String, dynamic>{'k': 'queso', 'v': 3},
        ],
      };
      W['cesta'] = null;
      W['canasta'] = null;
      W['pila'] = null;
      W['patio'] = <String, dynamic>{};
      W['repisa'] = <dynamic>[
        <String, dynamic>{
          'id': 'tarro',
          'k': 'tarro',
          'v': 3,
          'x': _at(207, 205),
        },
      ];
      W['sobras'] = 0;
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'id': 'carta_leche',
          'k': 'carta',
          'v': 'leche',
          'x': ct[0],
          'y': ct[1],
          'z': ct[2],
        },
        <String, dynamic>{
          'id': 'carta_queso',
          'k': 'carta',
          'v': 'queso',
          'x': ct[3],
          'y': ct[4],
          'z': ct[5],
        },
      ];
    },
    // the first picture: mamá fills the baby's bottle (the holder is empty); abuela lays cheese on bread for Luis
    'consume30': (o) async {
      final m = G('mama')!, N = _nev;
      Future<void> run() async {
        await vuela(
          {'k': 'leche', 'v': 4},
          HUECO[0][0],
          HUECO[0][1],
          (m['x'] as num) - 8,
          (m['y'] as num) - 34,
          9,
        );
        (N['h'] as List)[0] = null;
        m['bebe'] = 'come';
        SFX.blip();
        await wait(900);
        ((N['h'] as List)[1] as Map)['v'] = 1;
        final ca = G('carmen')!;
        await vuela(
          {'k': 'queso', 'v': 1},
          HUECO[1][0],
          HUECO[1][1],
          ca['x'] as num,
          (ca['y'] as num) - 30,
          8,
        );
        ca['come'] = <String, dynamic>{'k': 'rebanada', 'v': 'q'};
        SFX.blip();
        await wait(900);
        ca['come'] = null;
        m['bebe'] = 1;
      }

      return corre(o, run());
    },
    // what is in the fridge now, whether we see it or not (falta: the thing that has run out)
    'setnev': (o) async {
      final h = _nev['h'] as List;
      while (h.length < 2) {
        h.add(null);
      }
      h[0] = o['falta'] == 'leche'
          ? null
          : <String, dynamic>{'k': 'leche', 'v': 4};
      h[1] = o['falta'] == 'queso'
          ? null
          : <String, dynamic>{'k': 'queso', 'v': 3};
    },
    // abuela goes to the fridge: she opens it wide (abre "todo"), or a little and looks in (abre "poco"); toma: she takes
    // the last cheese for her plate. She speaks from there
    'mira30': (o) async {
      final ab = G('abuela')!, N = _nev;
      ab['vis'] = 1;
      ab['pose'] = 'idle';
      ab['lleva'] = null;
      await mueve('abuela', _at(214, 94), _at(214, 174));
      ab['dir'] = -1;
      if (o['abre'] == 'poco') {
        N['abierta'] = 2;
        SFX.blip();
        ab['paso'] = 1;
        await wait(500);
        ab['paso'] = 0;
      } else {
        N['abierta'] = 1;
        SFX.blip();
        await wait(250);
      }
      if (jsTruthy(o['toma'])) {
        (N['h'] as List)[1] = null;
        SFX.blip();
        await wait(300);
      }
    },
    // then she shuts it (if she had only looked in), lays one coin on the sill, takes her plate and goes out of the door
    'sale30': (o) async {
      final ab = G('abuela')!, N = _nev;
      if (N['abierta'] == 2) N['abierta'] = 0;
      await mueve('abuela', _at(216, 172), _at(216, 180));
      ab['dir'] = 1;
      _repisaL.add(<String, dynamic>{
        'id': 'moneda',
        'k': 'moneda',
        'x': _at(216, 178),
      });
      SFX.blip();
      await wait(250);
      ab['lleva'] = <String, dynamic>{'k': 'platopan', 'v': 2};
      await mueve('abuela', _at(216, 244), _at(216, 196));
      ab['vis'] = 0;
      ab['lleva'] = null;
    },
    // the errand. The frog tosses papá the coin from the sill, or one out of his own jar when the sill is bare (carta: he
    // holds that card up first); papá goes off and is back with the thing; Luis carries it to the fridge. Its place is
    // empty: he puts it in. Its place is taken: he throws a hand up and stands it on the counter (moves 219 to 225)
    'mandado': (o) async {
      final k = '${o['k']}'.replaceFirst(RegExp(r'^di_|^c_'), ''),
          pa = G('papa')!,
          l = G('luis')!,
          N = _nev,
          i = k == 'leche' ? 0 : 1,
          R2 = _repisaL,
          mon = _find(R2, (q) => q['id'] == 'moneda'),
          tar = _find(R2, (q) => q['id'] == 'tarro'),
          v = k == 'leche' ? 4 : 3;
      final fr219 = _mv(219, 'ranaA(150,ENC+9)'),
          mon220 = _mv(220, 'vuela({k:"moneda"},mon.x,SILL-4'),
          tar220 = _mv(220, 'vuela({k:"moneda"},tar.x,SILL-10'),
          pa136 = _pa(221, 'mueve("papa",136,PATIO)'),
          pa158 = _pa(221, 'mueve("papa",158,PATIO)'),
          lu230 = _pa(222, 'mueve("luis",230,PATIO-4)'),
          ly225 = _mv(225, 'l.y=PATIO-4;'),
          lu173 = _pa(225, 'mueve("luis",173,PATIO-4)'),
          sobra = _mv(224, 'W.cosas.push({id:"sobra"');
      Future<void> run() async {
        await ranaA(fr219[0], CT(fr219[1]) + fr219[2]);
        final ct = ob('carta_$k');
        if (jsTruthy(o['carta'])) {
          if (ct != null) ct['vis'] = 0;
          W['encima'] = <String, dynamic>{'k': 'carta', 'v': k};
          SFX.blip();
          await wait(450);
        }
        if (mon != null) {
          R2.remove(mon);
          await vuela(
            {'k': 'moneda'},
            mon['x'] as num,
            SL(mon['x'] as num) + mon220[0],
            pa['x'] as num,
            SL(pa['x'] as num) + mon220[1],
            mon220[2],
          );
        } else if (tar != null && _num(tar['v']) > 0) {
          _dec(tar, 'v');
          await vuela(
            {'k': 'moneda'},
            tar['x'] as num,
            SL(tar['x'] as num) + tar220[0],
            pa['x'] as num,
            SL(pa['x'] as num) + tar220[1],
            tar220[2],
          );
        }
        SFX.blip();
        pa['dir'] = -1;
        await mueve('papa', pa136[0], pa136[1]);
        W['encima'] = null;
        if (ct != null) ct['vis'] = 1;
        await alBanco();
        await wait(300);
        pa['alza'] = <String, dynamic>{
          'k': k,
          'v': v,
          'e': 1,
          'dx': 10,
          'dy': -8,
        };
        await mueve('papa', pa158[0], pa158[1]);
        pa['dir'] = 1;
        await wait(150);
        pa['alza'] = null;
        l['alza'] = <String, dynamic>{
          'k': k,
          'v': v,
          'e': 1,
          'dx': 9,
          'dy': -8,
        };
        l['dir'] = 1;
        SFX.blip();
        await mueve('luis', lu230[0], lu230[1]);
        l['fuera'] = 0;
        l['x'] = _at(222, 242);
        l['y'] = _at(222, 188);
        l['alza'] = <String, dynamic>{
          'k': k,
          'v': v,
          'e': 1,
          'dx': 1,
          'dy': -28,
        };
        await mueve('luis', _at(222, 98), _at(222, 170));
        l['dir'] = -1;
        final antes = N['abierta'];
        N['abierta'] = 1;
        SFX.blip();
        await wait(350);
        final h = N['h'] as List;
        while (h.length <= i) {
          h.add(null);
        }
        if (!jsTruthy(h[i])) {
          l['alza'] = null;
          await vuela(
            {'k': k, 'v': v},
            l['x'] as num,
            (l['y'] as num) - 50,
            HUECO[i][0],
            HUECO[i][1],
            5,
          );
          h[i] = <String, dynamic>{'k': k, 'v': v};
          V['puso'] = '1';
          SFX.blip();
          await wait(300);
          if (antes != 1) N['abierta'] = 0;
        } else {
          V['puso'] = '';
          l['pose'] = 'wave0';
          SFX.bonk();
          await wait(600);
          l['pose'] = 'idle';
          l['alza'] = null;
          final x = sobra[0] + _num(W['sobras']) * sobra[1];
          (W['cosas'] as List).add(<String, dynamic>{
            'id': 'sobra',
            'k': k,
            'v': v,
            'x': x,
            'y': CT(x),
            'z': sobra[4],
          });
          await wait(300);
        }
        l['dir'] = 1;
        await mueve('luis', _at(225, 242), _at(225, 188));
        l['fuera'] = 1;
        l['x'] = _at(225, 230);
        l['y'] = PA(ly225[0]) + ly225[1];
        await mueve('luis', lu173[0], lu173[1]);
        l['dir'] = -1;
      }

      return corre(o, run());
    },
    // mamá and the children share out what stands on the counter: its empty bottle, or its rind, stays there
    'comparten': (o) async {
      final t = ob('sobra');
      if (t == null) return;
      final m = G('mama')!, ca = G('carmen')!;
      if (t['k'] == 'leche') {
        m['bebe'] = 'come';
        ca['bebe'] = 'carmen';
      } else {
        ca['come'] = <String, dynamic>{'k': 'queso', 'v': 1};
      }
      SFX.blip();
      await wait(900);
      m['bebe'] = 1;
      ca['bebe'] = null;
      ca['come'] = null;
      t['id'] = null;
      if (t['k'] == 'leche') {
        t['v'] = 0;
      } else {
        t['k'] = 'corteza';
        t['v'] = null;
      }
      W['sobras'] = _num(W['sobras']) + 1;
    },
    // after a miss the sill is bare: the frog takes a coin out of his own jar and lays it on the sill (moves line 229)
    'sacamoneda': (o) async {
      final t = _find(_repisaL, (q) => q['id'] == 'tarro');
      if (t == null || _num(t['v']) <= 0) return;
      final r = _mv(229, 'ranaA(186,ENC+9)'),
          c = _mv(229, 'vuela({k:"moneda"},t.x,SILL-10,178,SILL-2,5)');
      await ranaA(r[0], CT(r[1]) + r[2]);
      t['dy'] = -2;
      await wait(120);
      t['dy'] = 0;
      _dec(t, 'v');
      await vuela(
        {'k': 'moneda'},
        t['x'] as num,
        SL(t['x'] as num) + c[0],
        c[1],
        SL(c[2]) + c[3],
        c[4],
      );
      _repisaL.add(<String, dynamic>{
        'id': 'moneda',
        'k': 'moneda',
        'x': _at(229, 178),
      });
      SFX.bonk();
      await wait(350);
    },
    // the turn: the piragua man's cart; the frog hops to his jar; abuela shows the three coins she has left
    'turno30': (o) async {
      (W['patio'] as Map)['carrito'] = 1;
      // `SFX.right&&SFX.blip()`: juego.js's SFX has a `right`
      SFX.blip();
      await wait(400);
      final r = _mv(219, 'ranaA(150,ENC+9)');
      await ranaA(r[0], CT(r[1]) + r[2]);
      final t = _find(_repisaL, (q) => q['id'] == 'tarro')!;
      for (var i = 0; i < 3; i++) {
        t['dy'] = -2;
        await wait(110);
        t['dy'] = 0;
        await wait(110);
      }
      await alBanco();
      final ab = G('abuela')!;
      if (ab['vis'] == 0) {
        ab['vis'] = 1;
        ab['x'] = _at(231, 244);
        ab['y'] = _at(231, 196);
        await mueve('abuela', _at(231, 142), _at(231, 180));
      }
      ab['dir'] = 1;
      ab['pose'] = 'offer';
      ab['lleva'] = <String, dynamic>{'k': 'moneda'};
      await wait(700);
      ab['pose'] = 'idle';
      ab['lleva'] = null;
    },
    // the ending: the frog tosses papá the coins left in his jar; papá buys a piragua at the cart: one scoop for each coin
    // (moves lines 233 to 235)
    'final30': (o) async {
      final pa = G('papa')!,
          t = _find(_repisaL, (q) => q['id'] == 'tarro')!,
          n = _num(t['v']);
      V['pir'] = n > 0 ? '1' : '';
      final r = _mv(219, 'ranaA(150,ENC+9)'),
          c = _mv(233, 'vuela({k:"moneda"},t.x,SILL-10,pa.x,SILL-22,5)'),
          pa186 = _pa(234, 'mueve("papa",186,PATIO)'),
          pa160 = _pa(234, 'mueve("papa",160,PATIO)'),
          pa158 = _pa(221, 'mueve("papa",158,PATIO)'),
          pir = _mv(234, 'vuela({k:"piragua",v:n},pa.x-8,SILL-12,160,ENC+2,6)');
      await ranaA(r[0], CT(r[1]) + r[2]);
      for (var i = 0; i < n; i++) {
        _dec(t, 'v');
        await vuela(
          {'k': 'moneda'},
          t['x'] as num,
          SL(t['x'] as num) + c[0],
          pa['x'] as num,
          SL(pa['x'] as num) + c[1],
          c[2],
        );
        SFX.blip();
      }
      if (n > 0) {
        pa['dir'] = 1;
        await mueve('papa', pa186[0], pa186[1]);
        await wait(500);
        pa['alza'] = <String, dynamic>{
          'k': 'piragua',
          'v': n,
          'e': 1,
          'dx': -10,
          'dy': -8,
        };
        pa['dir'] = -1;
        await mueve('papa', pa160[0], pa160[1]);
        await wait(200);
        pa['alza'] = null;
        // pir: [-8, -8, -12, 160, 160, -8, 6]: from over the sill at papá's x - 8 to the counter at 160
        await vuela(
          {'k': 'piragua', 'v': n},
          (pa['x'] as num) + pir[0],
          SL((pa['x'] as num) + pir[1]) + pir[2],
          pir[3],
          CT(pir[4]) + pir[5],
          pir[6],
        );
        await mueve('papa', pa158[0], pa158[1]);
        await alBanco();
        (W['cosas'] as List).add(<String, dynamic>{
          'k': 'piragua',
          'v': n,
          'e': 2,
          'x': cx() + 14,
          'y': pies() - 2,
          'z': 400,
        });
        _cq['hace'] = 'come';
        SFX.blip();
      } else {
        await mueve('papa', pa158[0], pa158[1]);
        await alBanco();
        _cq['piensa'] = <String, dynamic>{'k': 'piragua', 'v': 3};
        SFX.bonk();
      }
      await wait(700);
    },

    /* ----- story 31: Para los pájaros ----- */
    // The tray stands on the counter under the window: two places. What the frog or abuelo throws out lands on the yard
    // wall, and a bird comes to it. A good thing thrown out stays there with its bird to the end (bueno); an old one is
    // gone by the next throw. (moves line 239: abuelo outside on PA - 9; line 241: the tray on CT + 1)
    'inicio31': (o) async {
      final ao = _pa(239, 'abuelo:{x:207,y:PATIO,'),
          bj = _mv(241, '{k:"bandeja",x:196,y:ENC+11,z:99}');
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': _at(239, 94),
          'y': _at(239, 174),
          'dir': -1,
        },
        'luis': <String, dynamic>{
          'x': _at(239, 146),
          'y': _at(239, 198),
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': _at(239, 190),
          'y': _at(239, 202),
          'dir': -1,
        },
        'abuelo': <String, dynamic>{
          'x': ao[0],
          'y': ao[1],
          'dir': -1,
          'fuera': 1,
        },
        'mama': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
      };
      W['nev'] = <String, dynamic>{
        'abierta': 1,
        'h': <dynamic>[
          <String, dynamic>{'k': 'platofruta'},
          <String, dynamic>{'k': 'platofruta'},
          <String, dynamic>{'k': 'platofruta'},
          null,
        ],
        'cajon': <String, dynamic>{'guineo': 3, 'manzana': 3},
      };
      W['cesta'] = <String, dynamic>{'n': 3};
      W['canasta'] = <String, dynamic>{
        'x': _at(240, 156),
        'items': <dynamic>[],
      };
      W['pila'] = null;
      W['patio'] = <String, dynamic>{
        'aves': <dynamic>[
          <String, dynamic>{'x': _at(241, 153)},
          <String, dynamic>{'x': _at(241, 158)},
        ],
        'cosas': <dynamic>[],
      };
      W['repisa'] = <dynamic>[];
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'k': 'bandeja',
          'x': bj[0],
          'y': CT(bj[1]) + bj[2],
          'z': bj[3],
        },
      ];
    },
    // abuela pulls the drawer out and tips it towards us (ver), or pushes it shut
    'cajon31': (o) async {
      final ab = G('abuela')!;
      Future<void> run() async {
        await mueve('abuela', _at(243, 94), _at(243, 174));
        ab['dir'] = -1;
        _nev['cajonver'] = jsTruthy(o['ver']) ? 1 : 0;
        SFX.blip();
        await wait(_ms(o, 300));
      }

      return corre(o, run());
    },
    // abuela sets a roll and a plate of fruit on the tray. viejo: which of the two is old; izq: which stands at the left
    // (moves line 246: on CT, z 120)
    'lote': (o) async {
      final ab = G('abuela')!,
          xs = o['izq'] == 'fruta'
              ? {'fruta': _at(245, 187), 'pan': _at(245, 205)}
              : {'pan': _at(245, 187), 'fruta': _at(245, 205)};
      final tp = _mv(246, 'W.cosas.push({id:"t_pan"'),
          tf = _mv(246, 'W.cosas.push({id:"t_fruta"');
      ab['pose'] = 'idle';
      await mueve('abuela', _at(245, 94), _at(245, 174));
      final h = _nev['h'] as List;
      final i = h.indexWhere((q) => jsTruthy(q));
      if (i >= 0) h[i] = null;
      final ce = W['cesta'] as Map;
      if (_num(ce['n']) > 0) _dec(ce, 'n');
      ab['lleva'] = <String, dynamic>{'k': 'platofruta'};
      SFX.blip();
      await mueve('abuela', _at(245, 196), _at(245, 178));
      ab['lleva'] = null;
      (W['cosas'] as List).add(<String, dynamic>{
        'id': 't_pan',
        'k': 'panecillo',
        'x': xs['pan'],
        'y': CT(xs['pan']!) + tp[0],
        'z': tp[1],
        'viejo': o['viejo'] == 'pan',
      });
      (W['cosas'] as List).add(<String, dynamic>{
        'id': 't_fruta',
        'k': 'platofruta',
        'x': xs['fruta'],
        'y': CT(xs['fruta']!),
        'z': tf[0],
        'viejo': o['viejo'] == 'fruta',
      });
      SFX.blip();
      await wait(250);
    },
    // abuela bends over the tray and smells without lifting: one thing (a), or both, one after the other (orden: which
    // first) (moves line 248: before the counter's foot, CB + 2; the smell over the thing, CT + 3)
    'huele31': (o) async {
      final ab = G('abuela')!,
          ids = jsTruthy(o['a'])
              ? ['t_${o['a']}']
              : ('${o['orden']}' == '2'
                    ? ['t_fruta', 't_pan']
                    : ['t_pan', 't_fruta']);
      final hu = _mv(248, 'await mueve("abuela",t.x,176)'),
          ol = _mv(248, 'W.olfato={x:t.x,y:ENC+13};');
      Future<void> run() async {
        ab['lleva'] = null;
        ab['alza'] = jsTruthy(o['pano'])
            ? <String, dynamic>{'k': 'pano', 'e': 1, 'dx': 6, 'dy': 12}
            : null;
        for (final id in ids) {
          final t = ob(id)!;
          await mueve(
            'abuela',
            t['x'] as num,
            math.max(hu[0], CB(t['x'] as num) + hu[1]),
          );
          ab['dir'] = 1;
          W['olfato'] = <String, dynamic>{
            'x': t['x'],
            'y': CT(t['x'] as num) + ol[0],
          };
          ab['paso'] = 1;
          await wait(550);
          ab['paso'] = 0;
          W['olfato'] = null;
          await wait(150);
        }
        await mueve('abuela', _at(248, 134), _at(248, 180));
        ab['dir'] = 1;
      }

      return corre(o, run());
    },
    // the frog hops onto the counter and tosses a thing from the tray out of the window onto the wall; a bird has it
    'tira31': (o) async {
      final t = ob(o['a'] as String)!;
      Future<void> run() async {
        await ranaA((t['x'] as num) - 18, _at(250, 188));
        _cq['dy'] = -10;
        await wait(110);
        _cq['dy'] = 0;
        t['vis'] = 0;
        await alMuro(
          <String, dynamic>{'k': t['k'], 'v': t['v']},
          t['x'] as num,
          (t['y'] as num) - 6,
          jsTruthy(o['bueno']),
        );
        (W['cosas'] as List).remove(t);
        await alBanco();
      }

      return corre(o, run());
    },
    // abuela gives what is left on the tray to a child, who eats it; or (guarda) lays it in the picnic basket; or
    // (voltea) turns it over: spots
    'resto31': (o) async {
      final ab = G('abuela')!,
          t = _find(
            (W['cosas'] as List?) ?? const [],
            (q) => q['id'] == 't_pan' || q['id'] == 't_fruta',
          );
      if (t == null) return;
      Future<void> run() async {
        ab['lleva'] = null;
        await mueve('abuela', (t['x'] as num) - 6, _at(252, 178));
        ab['dir'] = 1;
        if (jsTruthy(o['voltea'])) {
          ab['pose'] = 'wave0';
          SFX.bonk();
          await wait(450);
          ab['pose'] = 'idle';
          t['v'] = t['k'] == 'panecillo' ? 'viejo' : 'vieja';
          await wait(500);
          return;
        }
        (W['cosas'] as List).remove(t);
        ab['lleva'] = <String, dynamic>{'k': t['k']};
        SFX.blip();
        if (jsTruthy(o['guarda'])) {
          await mueve('abuela', _at(255, 146), _at(255, 180));
          ab['lleva'] = null;
          ((W['canasta'] as Map)['items'] as List).add(<String, dynamic>{
            'k': t['k'],
          });
          SFX.blip();
          await wait(250);
        } else {
          final p = G(o['a'] as String)!;
          await mueve('abuela', (p['x'] as num) - 16, (p['y'] as num) - 4);
          ab['lleva'] = null;
          p['come'] = <String, dynamic>{'k': t['k']};
          SFX.blip();
          await wait(900);
          p['come'] = null;
        }
      }

      return corre(o, run());
    },
    // abuela takes a guineo and a manzana out of the drawer; Luis holds one and Carmen the other (luis: which Luis holds)
    'sostienen': (o) async {
      final ab = G('abuela')!,
          l = G('luis')!,
          ca = G('carmen')!,
          C = _nev['cajon'] as Map,
          kl = o['luis'],
          kc = kl == 'guineo' ? 'manzana' : 'guineo';
      ab['pose'] = 'idle';
      ab['lleva'] = null;
      if (!jsTruthy(o['ya'])) {
        await mueve('abuela', _at(259, 94), _at(259, 174));
        ab['dir'] = -1;
        await wait(250);
      }
      _dec(C, 'guineo');
      _dec(C, 'manzana');
      SFX.blip();
      if (!jsTruthy(o['ya'])) {
        await mueve('abuela', _at(259, 134), _at(259, 182));
      }
      l['alza'] = <String, dynamic>{'k': kl, 'e': 2, 'dx': 1, 'dy': -27};
      ca['alza'] = <String, dynamic>{'k': kc, 'e': 2, 'dx': 1, 'dy': -27};
      l['dir'] = 1;
      ca['dir'] = -1;
      SFX.blip();
      await wait(250);
    },
    // she bends to the hands of one, then of the other (orden: which first), and turns to the picnic basket
    'huelemanos': (o) async {
      final ab = G('abuela')!,
          ids = '${o['orden']}' == '2'
              ? ['carmen', 'luis']
              : ['luis', 'carmen'];
      await mueve('abuela', _at(261, 168), _at(261, 196));
      for (final id in ids) {
        final p = G(id)!;
        ab['dir'] = id == 'luis' ? -1 : 1;
        W['olfato'] = <String, dynamic>{
          'x': ((p['x'] as num) + (ab['x'] as num)) / 2,
          'y': (p['y'] as num) - 52,
        };
        ab['paso'] = 1;
        await wait(550);
        ab['paso'] = 0;
        W['olfato'] = null;
        await wait(150);
      }
      await mueve('abuela', _at(261, 134), _at(261, 180));
      ab['dir'] = 1;
    },
    // the frog takes the fruit out of a child's hands and tosses it out of the window
    'quita': (o) async {
      final p = G(o['a'] as String)!, f = p['alza'];
      if (!jsTruthy(f)) return;
      await ranaA(
        (p['x'] as num) + (o['a'] == 'luis' ? 20 : -20),
        (p['y'] as num) + 2,
      );
      _cq['dy'] = -12;
      await wait(110);
      _cq['dy'] = 0;
      p['alza'] = null;
      SFX.blip();
      if (jsTruthy(o['bueno'])) {
        p['pose'] = 'wave0';
        p['dy'] = -2;
      }
      await alMuro(
        <String, dynamic>{'k': (f as Map)['k'], 'v': f['v']},
        p['x'] as num,
        (p['y'] as num) - 64,
        jsTruthy(o['bueno']),
      );
      if (jsTruthy(o['bueno'])) {
        await wait(300);
        p['pose'] = 'idle';
        p['dy'] = 0;
      }
      await alBanco();
    },
    // a child: eats the fruit in his hands (come), lays it in the picnic basket (guarda), or turns it over: black spots
    // (manchas)
    'nino31': (o) async {
      final id = o['a'] as String, p = G(id)!, f = p['alza'];
      if (!jsTruthy(f)) return;
      Future<void> run() async {
        if (jsTruthy(o['manchas'])) {
          SFX.bonk();
          await wait(350);
          (f as Map)['v'] = 'manchas';
          await wait(800);
          return;
        }
        if (jsTruthy(o['guarda'])) {
          final x0 = p['x'] as num, y0 = p['y'] as num;
          await mueve(id, _at(266, 162), _at(266, 192));
          p['alza'] = null;
          ((W['canasta'] as Map)['items'] as List).add(<String, dynamic>{
            'k': (f as Map)['k'],
          });
          SFX.blip();
          await wait(250);
          await mueve(id, x0, y0);
          p['dir'] = 1;
          return;
        }
        p['alza'] = null;
        p['come'] = <String, dynamic>{'k': (f as Map)['k']};
        SFX.blip();
        await wait(900);
        p['come'] = null;
      }

      return corre(o, run());
    },
    // abuelo, in the yard at the window: trae (he lays a guineo and a manzana on the sill; viejo: the one with black spots
    // on our side), tira (he tosses the one named to the birds), come (he eats the one that is left), da (he hands it in
    // and abuela lays it in the picnic basket), mira (he turns the one that is left: spots) (moves line 273: from the sill)
    'abuelo31': (o) async {
      final ao = G('abuelo')!,
          R2 = _repisaL,
          k = '${jsTruthy(o['k']) ? o['k'] : ''}'.replaceFirst(
            RegExp(r'^di_'),
            '',
          ),
          it = _find(R2, (q) => q['id'] == 's_$k');
      List<dynamic> dos(int line) => <dynamic>[
        <String, dynamic>{
          'id': 's_guineo',
          'k': 'guineo',
          'v': o['viejo'] == 'guineo' ? 'manchas' : null,
          'x': _at(line, 166),
          'e': 2,
          'viejo': o['viejo'] == 'guineo',
        },
        <String, dynamic>{
          'id': 's_manzana',
          'k': 'manzana',
          'v': o['viejo'] == 'manzana' ? 'manchas' : null,
          'x': _at(line, 186),
          'e': 2,
          'viejo': o['viejo'] == 'manzana',
        },
      ];
      final que = o['que'];
      if (que == 'trae') {
        ao['x'] = _at(270, 207);
        ao['dir'] = -1;
        ao['alza'] = null;
        W['repisa'] = dos(270);
        SFX.blip();
        await wait(400);
      } else if (que == 'alza') {
        ao['x'] = _at(271, 207);
        ao['dir'] = -1;
        W['repisa'] = dos(271);
        SFX.blip();
        await wait(300);
      } else if (que == 'pone') {
        for (final q in R2) {
          (q as Map)['dy'] = 0;
        }
        SFX.blip();
        for (final id in const ['luis', 'carmen']) {
          G(id)!['dir'] = -1;
        }
        await wait(350);
      } else if (que == 'tira') {
        R2.remove(it);
        ao['pose'] = 'wave0';
        final t = _mv(
          273,
          'alMuro({k:it.k,v:it.viejo?"manchas":null},it.x,SILL-8',
        );
        await alMuro(
          <String, dynamic>{
            'k': it!['k'],
            'v': jsTruthy(it['viejo']) ? 'manchas' : null,
          },
          it['x'] as num,
          SL(it['x'] as num) + t[0],
          !jsTruthy(it['viejo']),
        );
        ao['pose'] = 'idle';
      } else if (que == 'come') {
        final r = R2.isNotEmpty ? R2[0] as Map? : null;
        if (r == null) return;
        Future<void> run() async {
          W['repisa'] = <dynamic>[];
          ao['come'] = <String, dynamic>{'k': r['k']};
          SFX.blip();
          await wait(900);
          ao['come'] = null;
        }

        return corre(o, run());
      } else if (que == 'da') {
        final r = R2.isNotEmpty ? R2[0] as Map? : null;
        if (r == null) return;
        final ab = G('abuela')!;
        ab['lleva'] = null;
        await mueve('abuela', _at(275, 184), _at(275, 178));
        W['repisa'] = <dynamic>[];
        ab['lleva'] = <String, dynamic>{'k': r['k']};
        SFX.blip();
        await mueve('abuela', _at(275, 146), _at(275, 180));
        ab['lleva'] = null;
        ((W['canasta'] as Map)['items'] as List).add(<String, dynamic>{
          'k': r['k'],
        });
        SFX.blip();
        await wait(250);
      } else if (que == 'mira') {
        ao['pose'] = 'wave0';
        SFX.bonk();
        await wait(700);
        ao['pose'] = 'idle';
      }
    },
    'abuelaa31': (o) async {
      final ab = G('abuela')!;
      ab['pose'] = 'idle';
      ab['lleva'] = null;
      ab['alza'] = jsTruthy(o['pano'])
          ? <String, dynamic>{'k': 'pano', 'e': 1, 'dx': 6, 'dy': 12}
          : null;
      await mueve('abuela', _at(277, 134), _at(277, 180));
      ab['dir'] = 1;
    },
    // the turn: abuelo puts his hat on; three more birds; the three last lots come out, one for each hollow: the last roll
    // and plate on the tray (izq, viejo), the last guineo and manzana out of the drawer into the children's hands (luis),
    // and the two abuelo holds up
    'turno31': (o) async {
      final ao = G('abuelo')!, P = W['patio'] as Map;
      ao['gorro'] = 1;
      SFX.blip();
      await wait(300);
      final aves = P['aves'] as List;
      if (aves.length < 3) {
        aves.add(<String, dynamic>{'x': _at(279, 163)});
        SFX.blip();
        await wait(200);
      }
    },
    'lotes31': (o) async {
      await ownActs['lote']!(<String, dynamic>{
        'viejo': o['viejo'],
        'izq': o['izq'],
      });
      final ab = G('abuela')!;
      await mueve('abuela', _at(280, 94), _at(280, 174));
      ab['dir'] = -1;
      _nev['cajonver'] = 1;
      SFX.blip();
      await wait(500);
      await ownActs['sostienen']!(<String, dynamic>{
        'luis': o['luis'],
        'ya': 1,
      });
      await wait(300);
      _nev['cajonver'] = 0;
      await ownActs['abuelo31']!(<String, dynamic>{
        'que': 'alza',
        'viejo': o['abuelo'],
      });
      await mueve('abuela', _at(280, 134), _at(280, 180));
      ab['dir'] = 1;
    },
    // the ending: the lid half shut; Luis carries the picnic basket, and they go
    'final31': (o) async {
      final ab = G('abuela')!,
          l = G('luis')!,
          ca = G('carmen')!,
          K0 = W['canasta'] as Map;
      ab['lleva'] = null;
      ab['alza'] = null;
      l['alza'] = null;
      ca['alza'] = null;
      await mueve('abuela', _at(282, 134), _at(282, 180));
      if ((K0['items'] as List).length < 3) {
        await mueve('luis', _at(282, 160), _at(282, 192));
        l['dir'] = -1;
        l['dy'] = 2;
        await wait(800);
        l['dy'] = 0;
      }
      await wait(500);
    },

    /* ----- story 32: Jugo de china ----- */
    // Four metal cups: green and yellow are the children's, red and blue the grown-ups'. A cup is {id, n: 1 full, 0
    // empty}. The jug has four marks. Nobody sees into a metal cup from the side: a round picture shows it from above when
    // W.vista names it. (moves lines 286 to 291: the people outside on PA, the things on CT, SL, the fridge's top)
    'inicio32': (o) async {
      final pa = _pa(286, 'papa:{x:160,y:PATIO,'),
          ao = _pa(286, 'abuelo:{x:176,y:PATIO,'),
          ma = _pa(286, 'mama:{x:200,y:PATIO,');
      // the moved source's last two numbers: x:<x>,y:CT(<x>), or SL
      Map<String, dynamic> enCT(int line, String src, Map<String, dynamic> m) {
        final n = _p.to(line, src, RegExp(r'x:(\d+),y:CT\((\d+)\),$'));
        return {...m, 'x': n[0], 'y': CT(n[1])};
      }

      Map<String, dynamic> enSL(int line, String src, Map<String, dynamic> m) {
        final n = _p.to(line, src, RegExp(r'x:(\d+),y:SL\((\d+)\),$'));
        return {...m, 'x': n[0], 'y': SL(n[1])};
      }

      final cl = _p.to(
        291,
        '{id:"c1",k:"claro",v:0,x:76,y:NEV[1],z:90}',
        RegExp(
          r'\{id:"c1",k:"claro",v:0,x:(\d+),y:(\d+),z:(\d+)\},\{id:"c2",k:"claro",v:0,x:(\d+),y:(\d+),z:(\d+)\}',
        ),
      );
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': _at(286, 140),
          'y': _at(286, 180),
          'dir': 1,
        },
        'luis': <String, dynamic>{
          'x': _at(286, 166),
          'y': _at(286, 192),
          'dir': -1,
        },
        'carmen': <String, dynamic>{
          'x': _at(286, 184),
          'y': _at(286, 198),
          'dir': -1,
        },
        'papa': <String, dynamic>{'x': pa[0], 'y': pa[1], 'dir': 1, 'fuera': 1},
        'abuelo': <String, dynamic>{
          'x': ao[0],
          'y': ao[1],
          'dir': -1,
          'fuera': 1,
        },
        'mama': <String, dynamic>{
          'x': ma[0],
          'y': ma[1],
          'dir': -1,
          'fuera': 1,
        },
      };
      W['nev'] = <String, dynamic>{'abierta': 0, 'h': <dynamic>[]};
      W['cesta'] = null;
      W['patio'] = <String, dynamic>{};
      W['repisa'] = <dynamic>[];
      W['pila'] = 'a';
      W['perdio'] = null;
      W['cosas'] = <dynamic>[
        enCT(288, '{id:"red",k:"red",v:4,x:142,y:ENC+10,', {
          'id': 'red',
          'k': 'red',
          'v': 4,
          'z': 100,
        }),
        enCT(288, '{id:"jarra",k:"jarra",v:3,x:156,y:ENC+10,', {
          'id': 'jarra',
          'k': 'jarra',
          'v': 3,
          'z': 100,
        }),
        enCT(289, '{id:"v_rojo",k:"vaso",v:"rojo",x:170,y:ENC+10,', {
          'id': 'v_rojo',
          'k': 'vaso',
          'v': 'rojo',
          'z': 100,
          'n': 1,
        }),
        enCT(289, '{id:"v_azul",k:"vaso",v:"azul",x:180,y:ENC+10,', {
          'id': 'v_azul',
          'k': 'vaso',
          'v': 'azul',
          'z': 100,
          'n': 0,
        }),
        enCT(289, '{id:"v_verde",k:"vaso",v:"verde",x:191,y:ENC+10,', {
          'id': 'v_verde',
          'k': 'vaso',
          'v': 'verde',
          'z': 100,
          'n': 1,
        }),
        enCT(289, '{id:"v_amarillo",k:"vaso",v:"amarillo",x:201,y:ENC+10,', {
          'id': 'v_amarillo',
          'k': 'vaso',
          'v': 'amarillo',
          'z': 100,
          'n': 0,
        }),
        enSL(290, '{id:"pan32",k:"platopan",v:2,x:160,y:SILL,', {
          'id': 'pan32',
          'k': 'platopan',
          'v': 2,
          'z': 90,
        }),
        enSL(290, '{id:"mant",k:"mantequilla",v:3,x:178,y:SILL,', {
          'id': 'mant',
          'k': 'mantequilla',
          'v': 3,
          'z': 90,
        }),
        <String, dynamic>{
          'id': 'c1',
          'k': 'claro',
          'v': 0,
          'x': cl[0],
          'y': cl[1],
          'z': cl[2],
        },
        <String, dynamic>{
          'id': 'c2',
          'k': 'claro',
          'v': 0,
          'x': cl[3],
          'y': cl[4],
          'z': cl[5],
        },
      ];
    },
    // abuela squeezes a china into the jug (one mark more); todo: the last ones: she fills the green cup and the yellow
    // cup, and the jug to its fourth mark; the net is empty (moves line 294: a cup comes from the sink to the counter)
    'exprime': (o) async {
      final ab = G('abuela')!, r = ob('red')!, j = ob('jarra')!;
      final mv = _p.to(
        294,
        'if(v.vis===0||v.y<ENC)',
        RegExp(
          r'v\.y<CT\(v\.x\)-(\d+)\)await vuela\(\{k:"vaso",v:v\.v\},EN\.pila\[0\],CT\(EN\.pila\[0\]\)-(\d+),'
          r'X0\[id\],CT\(X0\[id\]\)-(\d+),(\d+)\);',
        ),
      );
      Future<void> run() async {
        ab['pose'] = 'idle';
        await mueve('abuela', _at(293, 148), _at(293, 180));
        ab['dir'] = 1;
        final n = jsTruthy(o['todo']) ? _num(r['v']) : 1;
        for (var i = 0; i < n; i++) {
          _dec(r, 'v');
          ab['lleva'] = <String, dynamic>{'k': 'china'};
          SFX.blip();
          await wait(280);
          ab['lleva'] = <String, dynamic>{'k': 'china', 'v': 'cortada'};
          await wait(220);
          ab['lleva'] = null;
          if (!jsTruthy(o['todo'])) j['v'] = math.min(4, _num(j['v']) + 1);
          SFX.blip();
          await wait(150);
        }
        if (jsTruthy(o['todo'])) {
          final X0 = {
            'v_rojo': _at(294, 170),
            'v_azul': _at(294, 180),
            'v_verde': _at(294, 191),
            'v_amarillo': _at(294, 201),
          };
          for (final id in const [
            'v_rojo',
            'v_azul',
            'v_verde',
            'v_amarillo',
          ]) {
            final v = ob(id)!;
            // mv: [6, 8, 4, 5]: over CT - 6 (on the sill), from over the sink (CT - 8) to over its place (CT - 4)
            if (v['vis'] == 0 || _num(v['y']) < CT(v['x'] as num) - mv[0]) {
              await vuela(
                {'k': 'vaso', 'v': v['v']},
                EN['pila']![0],
                CT(EN['pila']![0]) - mv[1],
                X0[id]!,
                CT(X0[id]!) - mv[2],
                mv[3],
              );
            }
            v['vis'] = 1;
            v['x'] = X0[id];
            v['y'] = CT(v['x'] as num);
            v['n'] = 1;
            SFX.blip();
            await wait(160);
          }
          j['v'] = 4;
          SFX.blip();
        }
        await wait(200);
      }

      return corre(o, run());
    },
    // abuela butters a slice from the plate on the sill and gives it to somebody, who eats it
    'unta': (o) async {
      final ab = G('abuela')!, p = G(o['a'] as String), pl = ob('pan32')!;
      Future<void> run() async {
        await mueve('abuela', _at(296, 158), _at(296, 180));
        ab['dir'] = 1;
        if (_num(pl['v']) > 0) _dec(pl, 'v');
        ab['lleva'] = <String, dynamic>{'k': 'rebanada'};
        SFX.blip();
        await wait(350);
        ab['lleva'] = <String, dynamic>{'k': 'rebanada', 'v': 'm'};
        SFX.blip();
        await wait(450);
        ab['lleva'] = null;
        if (p != null) {
          p['come'] = <String, dynamic>{'k': 'rebanada', 'v': 'm'};
          await wait(_ms(o, 900));
          p['come'] = null;
        }
        pl['v'] = 2;
        await mueve('abuela', _at(296, 140), _at(296, 180));
        ab['dir'] = 1;
      }

      return corre(o, run());
    },
    // the round picture over a cup: on, or off
    'vista': (o) async {
      W['vista'] = jsTruthy(o['a']) ? <String, dynamic>{'id': o['a']} : null;
      if (jsTruthy(o['a'])) SFX.blip();
      await wait(_ms(o, 200));
    },
    // the frog hops onto the counter and tips the big jug from behind it: he cannot see into the cup. Into a full cup the
    // juice runs over: a puddle beside the cup and one under it, with drops between. They stay. The jug is a mark lower
    // either way (moves lines 300, 302, 303)
    'vierte': (o) async {
      final v = ob(o['a'] as String)!, j = ob('jarra')!;
      final al = _mv(300, 'alta=v.y<ENC;'),
          rj = _mv(300, 'ranaA(j.x-16,ENC+9)'),
          rv = _mv(300, 'ranaA(v.x-26,ENC+9)'),
          y2m = _p.to(
            302,
            'const y2=alta?ENC+11:PISO+16;',
            RegExp(r'alta\?CT\(v\.x\+(\d+)\)\+(\d+):CB\(v\.x\+(\d+)\);'),
          ),
          dz = _mv(
            302,
            '[0.35,0.7].forEach(t=>W.cosas.push({k:"gotaj",x:v.x+14,y:R(v.y+5+(y2-v.y-10)*t),z:500}));',
          );
      final alta = _num(v['y']) < CT(v['x'] as num) + al[0];
      Future<void> run() async {
        await ranaA(
          (j['x'] as num) + rj[0],
          CT((j['x'] as num) + rj[1]) + rj[2],
        );
        j['vis'] = 0;
        W['encima'] = <String, dynamic>{'k': 'jarra', 'v': j['v']};
        SFX.blip();
        await ranaA(
          (v['x'] as num) + rv[0],
          CT((v['x'] as num) + rv[1]) + rv[2],
        );
        W['encima'] = null;
        final vuelos = W['vuelos'] as List;
        final jj = <String, dynamic>{
          'k': 'jarra',
          'v': j['v'],
          'x': (v['x'] as num) - 12,
          'y': (v['y'] as num) - 10,
          'rot': 0.8,
        };
        vuelos.add(jj);
        for (var i = 0; i < 3; i++) {
          final g = <String, dynamic>{
            'k': 'gotaj',
            'x': v['x'],
            'y': (v['y'] as num) - 12 + i * 2,
          };
          vuelos.add(g);
          await wait(120);
          vuelos.remove(g);
        }
        if (jsTruthy(v['n'])) {
          V['der'] = '1';
          // y2m: [8, 1, 8]: on the counter (CT + 1) from the sill, or on the floor before the counter's foot (CB)
          final vx = v['x'] as num, vy = v['y'] as num;
          final y2 = alta ? CT(vx + y2m[0]) + y2m[1] : CB(vx + y2m[2]);
          (W['cosas'] as List).add(<String, dynamic>{
            'k': 'charcoj',
            'x': vx + 12,
            'y': vy + 5,
            'z': 98,
          });
          for (final t in const [0.35, 0.7]) {
            (W['cosas'] as List).add(<String, dynamic>{
              'k': 'gotaj',
              'x': vx + 14,
              'y': _round(vy + 5 + (y2 - vy - 10) * t),
              'z': dz[dz.length - 1],
            });
          }
          (W['cosas'] as List).add(<String, dynamic>{
            'k': 'charcoj',
            'x': vx + 8,
            'y': y2,
            'z': alta ? 98 : 1,
          });
          SFX.bonk();
        } else {
          v['n'] = 1;
          V['der'] = '';
          SFX.blip();
        }
        j['v'] = math.max(0, _num(j['v']) - 1);
        jj['v'] = j['v'];
        await wait(350);
        vuelos.remove(jj);
        W['encima'] = <String, dynamic>{'k': 'jarra', 'v': j['v']};
        await ranaA(
          (j['x'] as num) + rj[0],
          CT((j['x'] as num) + rj[1]) + rj[2],
        );
        W['encima'] = null;
        j['vis'] = 1;
        await alBanco();
      }

      return corre(o, run());
    },
    // the children: toman (each takes his cup; bebe: that one drinks his up), dejan (they set the cups on the counter and
    // take bread in both hands, their backs to the cups), salen (out of the door, con: with the cups), entran (in at the
    // door with their cups; vacio: whose is empty), corren (they set the cups down and run out) (moves line 306: on CT)
    'ninos32': (o) async {
      final l = G('luis')!,
          ca = G('carmen')!,
          vv = ob('v_verde')!,
          va = ob('v_amarillo')!;
      Map<String, dynamic> AL() => <String, dynamic>{
        'k': 'vaso',
        'v': 'verde',
        'e': 1,
        'dx': 10,
        'dy': -4,
      };
      Map<String, dynamic> AC() => <String, dynamic>{
        'k': 'vaso',
        'v': 'amarillo',
        'e': 1,
        'dx': 10,
        'dy': -4,
      };
      final al = AL(), ac = AC();
      final pv = _mv(306, 'vv.x=191;va.x=201;vv.y=va.y=ENC+10;');
      void pon() {
        l['alza'] = null;
        ca['alza'] = null;
        vv['vis'] = 1;
        va['vis'] = 1;
        vv['x'] = pv[0];
        va['x'] = pv[1];
        vv['y'] = CT(pv[2]);
        va['y'] = CT(pv[3]);
        SFX.blip();
      }

      Future<void> bebe(Map p, Map v, Map A) async {
        p['alza'] = null;
        p['bebe'] = v['v'];
        SFX.blip();
        await wait(700);
        p['bebe'] = null;
        v['n'] = 0;
        p['alza'] = A;
      }

      final que = o['que'];
      if (que == 'toman') {
        l['alza'] = null;
        ca['alza'] = null;
        await Future.wait([
          mueve('luis', _at(307, 186), _at(307, 190)),
          mueve('carmen', _at(307, 206), _at(307, 198)),
        ]);
        vv['vis'] = 0;
        va['vis'] = 0;
        l['alza'] = al;
        ca['alza'] = ac;
        l['dir'] = 1;
        ca['dir'] = 1;
        SFX.blip();
        await wait(300);
        if (o['bebe'] == 'luis') await bebe(l, vv, al);
        if (o['bebe'] == 'carmen') await bebe(ca, va, ac);
      } else if (que == 'dejan') {
        pon();
        await wait(200);
        await Future.wait([
          mueve('luis', _at(308, 164), _at(308, 192)),
          mueve('carmen', _at(308, 180), _at(308, 198)),
        ]);
        l['dir'] = -1;
        ca['dir'] = -1;
        l['alza'] = <String, dynamic>{
          'k': 'rebanada',
          'v': 'm',
          'e': 1,
          'dx': 8,
          'dy': -2,
        };
        ca['alza'] = <String, dynamic>{
          'k': 'rebanada',
          'v': 'm',
          'e': 1,
          'dx': 8,
          'dy': -2,
        };
      } else if (que == 'salen') {
        if (jsTruthy(o['con'])) {
          vv['vis'] = 0;
          va['vis'] = 0;
          l['alza'] = al;
          ca['alza'] = ac;
        }
        await Future.wait([
          mueve('luis', _at(309, 240), _at(309, 192)),
          mueve('carmen', _at(309, 246), _at(309, 198)),
        ]);
        l['vis'] = 0;
        ca['vis'] = 0;
        l['alza'] = null;
        ca['alza'] = null;
      } else if (que == 'entran') {
        l['vis'] = 1;
        ca['vis'] = 1;
        l['fuera'] = 0;
        ca['fuera'] = 0;
        l['x'] = _at(310, 240);
        ca['x'] = _at(310, 250);
        l['y'] = _at(310, 190);
        ca['y'] = _at(310, 198);
        vv['vis'] = 0;
        va['vis'] = 0;
        vv['n'] = o['vacio'] == 'verde' ? 0 : 1;
        va['n'] = o['vacio'] == 'amarillo' ? 0 : 1;
        l['alza'] = <String, dynamic>{...AL(), 'dx': -10};
        ca['alza'] = <String, dynamic>{...AC(), 'dx': -10};
        await Future.wait([
          mueve('luis', _at(310, 186), _at(310, 190)),
          mueve('carmen', _at(310, 206), _at(310, 198)),
        ]);
      } else if (que == 'corren') {
        pon();
        await wait(250);
        await Future.wait([
          mueve('luis', _at(311, 240), _at(311, 190)),
          mueve('carmen', _at(311, 246), _at(311, 198)),
        ]);
        l['vis'] = 0;
        ca['vis'] = 0;
      }
    },
    // mamá, at the window: trae (she sets the red cup and the blue cup on the sill, looks down into them, and turns her
    // face away; vacio: which is empty), lleva (she carries out the cups that stand on the sill) (moves lines 314, 315)
    'mama32': (o) async {
      final m = G('mama')!, vr = ob('v_rojo')!, vz = ob('v_azul')!;
      final ma198 = _pa(314, 'mueve("mama",198,PATIO)');
      if (o['que'] == 'trae') {
        final ma170 = _pa(314, 'mueve("mama",170,PATIO)'),
            tr = _p.to(
              314,
              'const x1=v===vr?190:203;',
              RegExp(
                r'v===vr\?(\d+):(\d+);if\(v\.y>SL\(v\.x\)\+(\d+)\)await vuela\(\{k:"vaso",v:v\.v\},v\.x,v\.y-(\d+),'
                r'x1,SL\(x1\)-(\d+),(\d+)\);',
              ),
            );
        await mueve('mama', ma198[0], ma198[1]);
        m['dir'] = -1;
        vr['vis'] = 1;
        vz['vis'] = 1;
        if (jsTruthy(o['vacio'])) {
          vr['n'] = o['vacio'] == 'rojo' ? 0 : 1;
          vz['n'] = o['vacio'] == 'azul' ? 0 : 1;
        }
        // tr: [187, 199, 6, 4, 2, 6]: the red one at 187, the blue at 199, on the sill (SL); a cup under SL + 6 flies
        for (final v in [vr, vz]) {
          final x1 = identical(v, vr) ? tr[0] : tr[1];
          if (_num(v['y']) > SL(v['x'] as num) + tr[2]) {
            await vuela(
              {'k': 'vaso', 'v': v['v']},
              v['x'] as num,
              (v['y'] as num) - tr[3],
              x1,
              SL(x1) - tr[4],
              tr[5],
            );
          }
          v['x'] = x1;
          v['y'] = SL(x1);
        }
        SFX.blip();
        m['dy'] = 2;
        await wait(500);
        m['dy'] = 0;
        m['dir'] = -1;
        await mueve('mama', ma170[0], ma170[1]);
        m['dir'] = -1;
        await wait(150);
      } else if (o['que'] == 'lleva') {
        final ll = _mv(315, 'if(vr.y>SILL)');
        await mueve('mama', ma198[0], ma198[1]);
        m['dir'] = -1;
        await wait(250);
        // ll: [6, -4, -8, -8, -6, 5]
        if (_num(vr['y']) > SL(vr['x'] as num) + ll[0]) {
          for (final v in [vr, vz]) {
            await vuela(
              {'k': 'vaso', 'v': v['v']},
              v['x'] as num,
              (v['y'] as num) + ll[1],
              (m['x'] as num) + ll[2],
              SL((m['x'] as num) + ll[3]) + ll[4],
              ll[5],
            );
          }
        }
        vr['vis'] = 0;
        vz['vis'] = 0;
        SFX.blip();
        await wait(200);
        m['dir'] = 1;
        await wait(300);
      }
    },
    // abuela looks into the green cup and the yellow one; then she turns to the bread, or (sale) goes to the door with a
    // plate of bread, her back to the cups (moves line 317)
    'abuelamira': (o) async {
      final ab = G('abuela')!;
      final m1 = _mv(317, 'await mueve("abuela",200,184);'),
          m2 = _mv(
            317,
            'ab.lleva={k:"platopan",v:2};await mueve("abuela",216,196);',
          );
      if (ab['vis'] == 0) {
        ab['vis'] = 1;
        ab['x'] = _at(317, 244);
        ab['y'] = _at(317, 196);
      }
      ab['pose'] = 'idle';
      ab['lleva'] = null;
      await mueve('abuela', m1[0], m1[1]);
      ab['dir'] = 1;
      ab['paso'] = 1;
      await wait(550);
      ab['paso'] = 0;
      if (jsTruthy(o['sale'])) {
        ab['lleva'] = <String, dynamic>{'k': 'platopan', 'v': 2};
        // m2: [2, 216, 210]
        await mueve('abuela', m2[1], m2[2]);
        ab['dir'] = 1;
      } else {
        await mueve('abuela', _at(317, 158), _at(317, 180));
        ab['dir'] = -1;
      }
      await wait(150);
    },
    'abuelasale': (o) async {
      final ab = G('abuela')!;
      if (ab['vis'] == 0) return;
      await mueve('abuela', _at(318, 244), _at(318, 196));
      ab['vis'] = 0;
      ab['lleva'] = null;
    },
    'abuelavuelve': (o) async {
      final ab = G('abuela')!;
      if (ab['vis'] == 0) {
        ab['vis'] = 1;
        ab['x'] = _at(319, 244);
        ab['y'] = _at(319, 196);
      }
      ab['lleva'] = null;
      ab['pose'] = 'idle';
      await mueve('abuela', _at(319, 140), _at(319, 180));
      ab['dir'] = 1;
    },
    // the frog carries a cup to the sink and tips it over the dishwater. A full one: the juice is in the dishwater. The cup
    // goes in to be washed (moves lines 321, 322)
    'lleva32': (o) async {
      final v = ob(o['a'] as String)!;
      final r1 = _mv(321, 'ranaA(v.x-20,ENC+9)'),
          r2 = _mv(321, 'ranaA(EN.pila[0]+22,ENC+9)'),
          tip = _mv(
            321,
            'const vv={k:"vaso",v:v.v,x:EN.pila[0]+8,y:ENC+2,rot:-1.9};',
          ),
          gt = _mv(322, 'const g={k:"gotaj",x:EN.pila[0]+1,y:ENC+2+i};');
      final px = EN['pila']![0];
      await ranaA((v['x'] as num) + r1[0], CT((v['x'] as num) + r1[1]) + r1[2]);
      v['vis'] = 0;
      W['encima'] = <String, dynamic>{'k': 'vaso', 'v': v['v']};
      SFX.blip();
      await ranaA(px + r2[1], CT(px + r2[3]) + r2[4]);
      W['encima'] = null;
      final vuelos = W['vuelos'] as List;
      // tip: [0, 8, 0, 8, -8, -1.9]
      final vv = <String, dynamic>{
        'k': 'vaso',
        'v': v['v'],
        'x': px + tip[1],
        'y': CT(px + tip[3]) + tip[4],
        'rot': tip[5],
      };
      vuelos.add(vv);
      await wait(250);
      if (jsTruthy(v['n'])) {
        // gt: [0, 1, 0, 1, -8]
        for (var i = 0; i < 4; i++) {
          final g = <String, dynamic>{
            'k': 'gotaj',
            'x': px + gt[1],
            'y': CT(px + gt[3]) + gt[4] + i,
          };
          vuelos.add(g);
          await wait(110);
          vuelos.remove(g);
        }
        W['pila'] = 'j';
        W['perdio'] = v['id'];
        V['der'] = '1';
        SFX.bonk();
        await wait(500);
      } else {
        V['der'] = '';
        SFX.blip();
        await wait(400);
      }
      v['n'] = 0;
      vuelos.remove(vv);
      await alBanco();
    },
    // whoever lost his juice in the dishwater comes to the window and looks in (moves line 325)
    'mirapila': (o) async {
      final id = W['perdio'] == 'v_verde' ? 'luis' : 'carmen', p = G(id)!;
      final m = _mv(325, 'p.x=158;p.y=PATIO+8;');
      p['vis'] = 1;
      p['fuera'] = 1;
      p['alza'] = null;
      // m: [158, 158, 2]
      p['x'] = m[0];
      p['y'] = PA(m[1]) + m[2];
      p['dir'] = 1;
      SFX.blip();
      await wait(600);
    },
    // the ending: abuela takes the two clear glasses down and pours what is left: first into the cup of the child whose
    // juice is gone, then into her own glass, then into the frog's (moves lines 327, 329)
    'final32': (o) async {
      final ab = G('abuela')!, j = ob('jarra')!, c1 = ob('c1')!, c2 = ob('c2')!;
      final cs = _mv(327, 'c1.x=132;c2.x=143;c1.y=c2.y=ENC+10;'),
          pv = _mv(329, 'v.x=W.perdio==="v_verde"?191:201;v.y=ENC+10;');
      await mueve('abuela', _at(327, 94), _at(327, 174));
      ab['dir'] = -1;
      await wait(200);
      // cs: [1, 132, 2, 143, 1, 132, 2, 143]
      c1['x'] = cs[1];
      c2['x'] = cs[3];
      c1['y'] = CT(cs[5]);
      c2['y'] = CT(cs[7]);
      c1['z'] = 100;
      c2['z'] = 100;
      SFX.blip();
      await mueve('abuela', _at(327, 146), _at(327, 180));
      ab['dir'] = 1;
      await wait(200);
      final vuelos = W['vuelos'] as List;
      Future<void> vierte(num x, num y) async {
        j['vis'] = 0;
        final jj = <String, dynamic>{
          'k': 'jarra',
          'v': j['v'],
          'x': x + 12,
          'y': y - 10,
          'rot': -0.8,
        };
        vuelos.add(jj);
        await wait(400);
        _dec(j, 'v');
        vuelos.remove(jj);
        j['vis'] = 1;
        SFX.blip();
      }

      if (jsTruthy(W['perdio']) && _num(j['v']) > 0) {
        final v = ob(W['perdio'] as String)!;
        v['vis'] = 1;
        // pv: [191, 201]
        v['x'] = W['perdio'] == 'v_verde' ? pv[0] : pv[1];
        v['y'] = CT(v['x'] as num);
        await vierte((v['x'] as num) - 24, v['y'] as num);
        v['n'] = 1;
        W['vista'] = <String, dynamic>{'id': v['id']};
        await wait(600);
        W['vista'] = null;
      }
      if (_num(j['v']) > 0) {
        await vierte(c1['x'] as num, c1['y'] as num);
        c1['v'] = 1;
        await wait(200);
      }
      if (_num(j['v']) > 0) {
        await vierte(c2['x'] as num, c2['y'] as num);
        c2['v'] = 1;
        await wait(200);
      }
      V['rana'] = jsTruthy(c2['v']) ? '1' : '';
      c1['vis'] = 0;
      ab['lleva'] = <String, dynamic>{'k': 'claro', 'v': c1['v']};
      (W['cosas'] as List).add(<String, dynamic>{
        'k': 'plato',
        'x': cx() + 24,
        'y': pies() + 4,
        'z': 399,
      });
      (W['cosas'] as List).add(<String, dynamic>{
        'k': 'claro',
        'v': c2['v'],
        'x': cx() + 24,
        'y': pies() + 1,
        'z': 400,
      });
      c2['vis'] = 0;
      if (jsTruthy(c2['v'])) _cq['hace'] = 'come';
      await wait(700);
    },

    // everything at once, to look at the drawing (nevera.js:336 to :341: its places as the old, the sheet's code keeps
    // them unchanged)
    'prueba': (o) async {
      final nn = _plus(jsTruthy(o['n']) ? o['n'] : 1), n = nn.isNaN ? 0 : nn;
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': n == 2 ? 102 : _at(336, 128),
          'y': _at(336, 176),
          'dir': -1,
        },
        'luis': <String, dynamic>{
          'x': _at(336, 162),
          'y': _at(336, 186),
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': _at(336, 190),
          'y': _at(336, 192),
          'dir': -1,
          'piensa': n == 1 ? <String, dynamic>{'k': 'guineo'} : null,
        },
        'papa': <String, dynamic>{
          'x': _at(336, 198),
          'y': PATIO,
          'dir': -1,
          'fuera': 1,
        },
        'mama': <String, dynamic>{
          'x': _at(336, 170),
          'y': PATIO,
          'dir': 1,
          'fuera': 1,
          'vis': n == 3 ? 1 : 0,
        },
      };
      W['nev'] = <String, dynamic>{
        'abierta': n == 1
            ? 1
            : n == 2
            ? 2
            : 0,
        'h': <dynamic>[
          <String, dynamic>{'k': 'leche', 'v': n == 1 ? 0 : 4},
          <String, dynamic>{'k': 'queso', 'v': 2},
        ],
        'cajon': <String, dynamic>{'guineo': 3, 'manzana': 3},
      };
      W['cesta'] = n == 3 ? null : <String, dynamic>{'n': 4};
      W['mos'] = n == 3 ? <String, dynamic>{} : <String, dynamic>{'pan': 4};
      W['patio'] = <String, dynamic>{
        'carrito': n == 1 ? 1 : 0,
        'aves': <dynamic>[
          <String, dynamic>{'x': _at(338, 158)},
          <String, dynamic>{'x': _at(338, 170), 'come': 1},
        ],
        'cosas': <dynamic>[
          <String, dynamic>{'k': 'panecillo', 'x': _at(338, 170)},
        ],
      };
      Map<String, dynamic> r(String k, num x, [Object? v, num? dy]) => {
        'k': k,
        'v': ?v,
        'x': _at(339, x),
        'dy': ?dy,
      };
      W['repisa'] = n == 1
          ? <dynamic>[
              r('tarro', 156),
              r('monedas', 172, 4),
              r('leche', 190, 4),
              r('queso', 206, 3),
            ]
          : n == 2
          ? <dynamic>[
              r('bandeja', 186, null, 1),
              r('panecillo', 178),
              r('platofruta', 196, 'vieja'),
            ]
          : <dynamic>[
              r('claro', 158, 1),
              r('claro', 168, 0),
              r('vaso', 190, 'rojo'),
              r('vaso', 202, 'azul'),
            ];
      Map<String, dynamic> c(String k, num x, num y, [Object? v, num? z]) => {
        'k': k,
        'v': ?v,
        'x': _at(340, x),
        'y': y,
        'z': ?z,
      };
      final e10 = ENC + 10;
      W['cosas'] = n == 2
          ? <dynamic>[
              c('bolsa', 132, e10, 'luis:1', 300),
              c('bolsa', 147, e10, 'carmen', 300),
              c('bolsa', 162, e10, 'coqui', 300),
            ]
          : n == 3
          ? <dynamic>[
              c('red', 146, e10, 3, 300),
              c('exprimidor', 162, e10, null, 300),
              c('jarra', 178, e10, 3, 300),
              c('mantequilla', 204, e10, 3, 300),
              c('charcoj', 150, _at(340, 204)),
              c('piragua', 60, _at(340, 200)),
            ]
          : <dynamic>[];
      W['banco'] = 1;
      W['tarjeta'] = 'rondas';
      W['marcas'] = <dynamic>['ok', 'x', null];
    },
  };

  // nevera.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    await wait(200);
  }

  // nevera.js: poke (nothing)
  @override
  dynamic poke(String what) => null;

  // nevera.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if ((g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_roundN(_num(p['x'])))},${jsNum(_roundN(_num(p['y'])))}';
          }(),
    ].join(' ');
    final mos = W['mos'];
    final pan = mos is Map
        ? (mos.containsKey('pan') ? _js(mos['pan']) : 'undefined')
        : 'undefined';
    final marcas = ((W['marcas'] as List?) ?? const [])
        .map((m) => m == null ? '' : _js(m))
        .join(',');
    return 'gente=$gente pan=$pan marcas=$marcas';
  }

  // nevera.js: fresh (moves line 347: where the answer cards stand, respEn)
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'respEn': <num>[_respEn[0], _respEn[1]],
    'olfato': null,
    'canasta': null,
    'pila': null,
    'vista': null,
    'nev': <String, dynamic>{'abierta': 0, 'h': <dynamic>[]},
    'mos': <String, dynamic>{},
    'patio': <String, dynamic>{},
    'repisa': <dynamic>[],
    'cesta': null,
    'gente': <String, dynamic>{},
    'cosas': <dynamic>[],
    'vuelos': <dynamic>[],
    'banco': 1,
    'encima': null,
    'tarjeta': null,
    'marcas': null,
    'cq': <String, dynamic>{
      'x': BANCO[0] - 16,
      'y': BANCO[1] - 27,
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
      'hace': null,
      'piensa': null,
    },
  };

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A point keeps its screen place (the sheet's `new`; those the sheet moved: whatever stood on the
  // counter's or the sill's old row, whoever stood outside); the frog out of a picture is no place (`to.none`) and is
  // given back; an x alone on the sill keeps its x; a pair rectangle gives the crop of the pictures it was; a level
  // picture's rectangle gives itself back.
  @override
  List<num> remap(List<num> xy) {
    switch (xy.length) {
      case 1:
        final r = sheet.remap('x', xy);
        return [r.now?[0] ?? r.x ?? xy[0]];
      case 2:
        final r = sheet.remapPoint(xy[0], xy[1]);
        if (r.now != null) return r.now!;
        final to = r.to;
        if (to.spot != null) return _p.spot(to.spot!);
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

  // nevera-preview.html: PV.pair's PV.remapW for a review picture's own W (the pair's file, cual-nevera): whoever stands
  // outside the window, and each thing of `cosas` on the counter, at a position the sheet moved for that file (the remap's
  // `outside` and `counter` entries: PA and CT at its x, as remapW moves them) to its new one, a person keeping the
  // fraction. The top-level places (cq) are remapped by ScenePictures, as for every scene.
  @override
  void placePair(Map<String, dynamic> set) {
    final rm = [
      for (final e in sheet.remapTable)
        if (e.moved &&
            e.kind == 'point' &&
            e.uses.any((u) => u.startsWith('cual-nevera.json')))
          e,
    ];
    List<num>? find(num x, num y) {
      final rx = _round(x), ry = _round(y);
      for (final e in rm) {
        if (e.old[0] == rx && e.old[1] == ry) return e.now;
      }
      return null;
    }

    final gente = set['gente'];
    if (gente is Map) {
      for (final p in gente.values) {
        if (p is! Map || p['x'] is! num) continue;
        final x = p['x'] as num, y = p['y'] as num;
        final m = find(x, y);
        if (m != null) {
          p['x'] = m[0] + (x - _round(x));
          p['y'] = m[1] + (y - _round(y));
        }
      }
    }
    for (final p in (set['cosas'] as List?) ?? const []) {
      if (p is! Map || p['x'] is! num) continue;
      final m = find(p['x'] as num, p['y'] as num);
      if (m != null) {
        p['x'] = m[0];
        p['y'] = m[1];
      }
    }
  }
}
