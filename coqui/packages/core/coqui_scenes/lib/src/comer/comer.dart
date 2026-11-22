// Port of historia/escenas/comer.js: the scene "A comer", abuela's kitchen table laid for a meal (place 3, La cocina, its
// fourth scene; order 40b). Line for line, minus its background `fondo` and the old table's line (the sheet's `dropped`:
// the set's, and the set's table drawn again at the old table's place in the sorted list, TZ); every screen position
// replaced by what the sheet's `code` list gives for its line (comer_places.dart: a number the rule keeps is checked to
// be one the sheet names there, [ComerPlaces.at]), and the pieces of source the sheet's `moves` list moves, each at its
// line, as comer-preview.html runs them (their places read from the moved source: [ComerPlaces.named], [ComerPlaces.to];
// the moved code checked to be the one ported: [ComerPlaces.movesAre]). comer.js is written on the kit, so this is an
// `Escena`; its set is [ComerSet], its sprites comer_sprites.dart. The file is in four parts: this one (the places, the
// things, the set in front, the frame, the scene's surface), comer_draw.dart (what draw() draws), comer_moves.dart
// (walking, hands, spoons, the stories' helpers) and comer_acts.dart (the acts).
//
// What A comer's sheet has that the earlier ones did not, or uses differently, and how it is kept here (as
// comer-preview.html keeps it, its functions ported pixel for pixel):
// - **Every place at the table steps down along it** (moves line 21: `SY(x, y) = y + (x - 118) / 2`): the seats, the plates
//   and cups in front of them, the lane behind the chairs (ATRAS), the children at the corners, the frog beside a seated
//   one's plate; whoever goes behind the table walks round its right end (XP) and along the lane behind the chairs, and
//   whoever comes in to sit or leaves from behind comes and goes by the doorway (DOOR); the passage at the table's left end
//   (PB) leads to the counter (`atras`).
// - **The table and the chairs in front** (`front.parts`): the old table was an item of the sorted list at TZ; there the
//   set's table (`mesa`, `mesa.patas`) is drawn again over whoever is behind it, and the four chairs (`silla0` .. `silla3`,
//   `sillas.patas`) at sortY 60: each item of the list owns the pixels it drew last ([Comer.item]); a front part's pixels
//   are drawn again only where nearer to the camera than the plane of the floor under the owner's feet ([Comer.front],
//   [Comer.planeOf]); the frog and the things on the cloth are never drawn over. Of two people in one row the one to the
//   right is drawn over the other (`capa`: x / 10000); abuela on her stool keeps her own row.
// - **CARTAS** (moves line 548, `W.respEn` at every frame while the frog chooses: [Comer.CARTAS]) and **LIBRE** (moves
//   lines 565, 566: with the words hidden, an empty bubble goes to the first talk place clear of every other face:
//   [Comer.LIBRE]).
// - **HOPAT** (moves line 692): each new place of the frog is mapped to the old one it stands for, and the hops are
//   counted on the old distance ([Comer.ranaA]).
// - **Speaking turns**: `di_buen`, `di_tambien`, `di_lleno`, `di_poco`, `di_mucho` are one 16 x 10 box over the frog's
//   head; the kit's hit() answers the first, `di_buen` (the sheet's `faults`): kept.
// - `helps`: the steam's darker edge (#5C6C92 over the old #B8C4D4, `vapor`).
// - `shadows` on the clear floor only, from the floor under whoever stands; none for a sitter, the frog, a thing.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_pixel/coqui_pixel.dart' as kit show tarjeta;
import 'package:coqui_scenes/src/comer/comer_places.dart';
import 'package:coqui_scenes/src/comer/comer_set.dart';
import 'package:coqui_scenes/src/comer/comer_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'comer_draw.dart';
part 'comer_moves.dart';
part 'comer_acts.dart';
part 'comer_acts34.dart';
part 'comer_acts35.dart';

/// The scene "comer", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It draws
/// no random number.
Scene createComer() => Comer(sheetOf('comer'));

/// A map of W: a person, a thing, what is held (JSON-shaped, as the old objects).
typedef M = Map<String, dynamic>;

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: `x || 0` for a number of W
num _n(Object? v) => jsTruthy(v) ? v as num : 0;

// JavaScript: `x || d` for a number of W
num _or(Object? v, num d) => jsTruthy(v) ? v as num : d;

// JavaScript: `+x` (a number, or a story's string)
num _plus(Object? v) => v is num
    ? v
    : v is String
    ? (num.tryParse(v.trim()) ?? (v.trim().isEmpty ? 0 : double.nan))
    : v == null
    ? double.nan
    : (v == true ? 1 : 0);

// JavaScript: `!!+x` (a flag a story file gives as 1, "1", 0 or "")
bool _on(Object? v) {
  final n = _plus(v);
  return !n.isNaN && n != 0;
}

// JavaScript: Math.hypot
double _hypot(num a, num b) => math.sqrt(a * a + b * b);

// JavaScript: `p.dir < 0 ? -1 : 1` (a missing dir is not < 0)
int _d(Map? p) =>
    p != null && p['dir'] is num && (p['dir'] as num) < 0 ? -1 : 1;

// JavaScript: how `"" + v` writes a value of W (undefined and null as their names)
String _js(Object? v) => v == null
    ? 'undefined'
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `String(v)` of a value that may be missing (null: "null")
String _jsS(Object? v) => v == null ? 'null' : _js(v);

/// One entry of comer.js's drawing list (`L`): the row it is sorted by, how it is drawn, and whose it is
/// (comer-preview.html, the sheet's front.tags: `id` for a person, the frog, the dog; [front] for a part of the set drawn
/// again).
class ComerItem {
  ComerItem(this.y, this.d, {this.id, this.front});

  final num y;
  final void Function() d;
  final String? id, front;
}

/// What the set's parts in front are (the sheet's front.parts, each by its part tags): each part's pixels (index),
/// recorded at the state's first bake.
final Map<String, Map<String, Int32List>> _frontPixels = {};

class Comer extends Escena implements SetScene, SetOverSprites, PairPlaces {
  Comer(this.sheet) {
    _p = ComerPlaces(sheet, comerEngine());
    final p = _p;
    _geo = ComerPlan(p.e);
    // the pieces of comer.js the sheet moves are those this port's moved code was written from
    p.movesAre(0xb1ec556c);
    // comer.js:20 MESA (the old table: the set's; MESA[1], its far edge, is still the row caja() reads), SILLA (the seats'
    // x, unchanged; their rows by SY); PISO, MOSTR, ESTUFA, ESTANTE: the old background's (dropped)
    MESA = [
      for (final v in const [66, 112, 120, 60]) p.at(20, v).toInt(),
    ];
    SILLA = [
      for (final x in const [90, 114, 138, 162]) p.at(20, x).toInt(),
    ];
    // moves line 21: the new geometry
    FILA = p.namedNum(21, 'FILA').toInt();
    MED = p.namedNum(21, 'MED').toInt();
    FREN = p.namedNum(21, 'FREN').toInt();
    TZ = p.namedNum(21, 'TZ').toInt();
    ASIENTO = p.namedNum(21, 'ASIENTO').toInt();
    ATRAS = p.namedNum(21, 'ATRAS').toInt();
    FR = p.namedNum(21, 'FR').toInt();
    FLO = p.namedNum(21, 'FLO').toInt();
    const l21 = 'const FILA=124,MED=148';
    final sy = p.to(21, l21, RegExp(r'SY=\(x,y\)=>y\+\(x-(\d+)\)/(\d+),'));
    SYC = sy[0];
    SYD = sy[1];
    XP = p.namedNum(21, 'XP').toInt();
    DOOR = p.named(21, 'DOOR');
    PB = p.named(21, 'PB');
    DETRAS_ = p.to(
      21,
      l21,
      RegExp(
        r'DETRAS=\(x,y\)=>\(y<(\d+)\+x/(\d+)\|\|\(x<(\d+)&&y<(\d+)-x/(\d+)\)\)&&y>(\d+)-x/(\d+)&&x<(\d+),',
      ),
    );
    ENTOP_ = p.to(
      21,
      l21,
      RegExp(
        r'ENTOP=\(x,y\)=>y>=(\d+)\+x/(\d+)&&y<=(\d+)\+x/(\d+)&&y>=(\d+)-x/(\d+)&&y<=(\d+)-x/(\d+),',
      ),
    );
    MESAPIE_ = p.to(
      21,
      l21,
      RegExp(
        r'MESAPIE=\(x,y\)=>y>(\d+)\+x/(\d+)&&y<(\d+)\+x/(\d+)&&y>(\d+)-x/(\d+)&&y<(\d+)-x/(\d+),',
      ),
    );
    FRONTROW_ = p
        .to(
          21,
          l21,
          RegExp(r'FRONTROW=\(x,y\)=>\{while\(MESAPIE\(x,y\)&&y<(\d+)\)'),
        )[0]
        .toInt();
    // moves line 21: CARTAS's places, the sheet's cards (its list of centres and its row)
    final cards = sheet.raw['cards'] as Map<String, dynamic>;
    CARTAS_CX = [for (final v in cards['cx'] as List) (v as num).toInt()];
    CARTAS_Y = (cards['y'] as num).toInt();
    if (!p
        .source(21, l21)
        .contains('for(const cx of [${CARTAS_CX.join(',')}])')) {
      throw SheetError(
        'the sheet\'s cards are not the centres CARTAS tries (moves line 21)',
      );
    }
    // moves line 21: LIBRE's places, the sheet's talk places ([side, dy])
    LIBRE_AT = [
      for (final t in sheet.talk!.places) [t.side, t.dy],
    ];
    if (!p
        .source(21, l21)
        .contains(
          'for(const[s,dy]of [${[for (final t in LIBRE_AT) '[${t[0]},${t[1]}]'].join(',')}])',
        )) {
      throw SheetError(
        'the sheet\'s talk places are not the places LIBRE tries (moves line 21)',
      );
    }
    // comer.js:23 LE, CAR, FOGON, DER, PUERTA (the rule) and AFOGON (moves line 23: abuela on the floor in front of the
    // stove's top)
    LE = p.named(23, 'LE');
    CAR = p.named(23, 'CAR');
    FOGON = p.named(23, 'FOGON');
    AFOGON = p.named(23, 'AFOGON');
    DER = p.named(23, 'DER');
    PUERTA = p.named(23, 'PUERTA');
    // moves line 574: story 34's places
    HIJA = p.named(574, 'HIJA');
    OLLA = p.named(574, 'OLLA');
    PLUIS = p.named(574, 'PLUIS');
    PRANA = p.named(574, 'PRANA');
    CASA34 = p.named(574, 'CASA34');
    EAT34 = p.named(574, 'EAT34');
    LUIS34 = p.named(574, 'LUIS34');
    FU34 = p.named(574, 'FU34');
    PLAT34 = p.named(574, 'PLAT34');
    CONT34 = p.named(574, 'CONT34');
    SIDE34 = p.named(574, 'SIDE34');
    // moves line 578, 579: where Luis meets abuela; the frog's thought
    ENC34 = p.named(578, 'ENC34');
    final n34 = p.to(
      579,
      'const NUBE34=',
      RegExp(
        r'NUBE34=\{barriga:\[(\d+),(\d+)\],montoncor:\[(\d+),(\d+)\]\},AIM34=\[(\d+),(\d+)\]',
      ),
    );
    NUBE34 = {
      'barriga': [n34[0].toInt(), n34[1].toInt()],
      'montoncor': [n34[2].toInt(), n34[3].toInt()],
    };
    AIM34 = [n34[4].toInt(), n34[5].toInt()];
    // moves line 629: story 35's places
    K1 = p.named(629, 'K1');
    K2 = p.named(629, 'K2');
    AZU = p.named(629, 'AZU');
    TRANA = p.named(629, 'TRANA');
    GRECA35 = p.named(629, 'GRECA35');
    GRECA35B = p.named(629, 'GRECA35B');
    TABU = p.named(629, 'TABU');
    CASA35 = p.named(629, 'CASA35');
    CANELO = p.named(629, 'CANELO');
    TAZON = p.named(629, 'TAZON');
    STOOL = p.named(629, 'STOOL');
    NUBE35 = p.named(629, 'NUBE35');
    AIM35 = p.named(629, 'AIM35');
    CAFE35 = p.named(629, 'CAFE35');
    CAZO35 = p.named(629, 'CAZO35');
    // moves line 640: the rows where abuela can stand round the table to pour
    FRENTE = [
      for (final v in RegExp(
        r'FRENTE=\[([\d,]+)\]',
      ).firstMatch(p.source(640, 'const FRENTE='))![1]!.split(','))
        int.parse(v),
    ];
    // moves line 692: HOPAT, each new place of the frog (his feet) and the old place it stands for
    HOPAT = {
      for (final g in RegExp(
        r'"(\d+),(\d+)":\[(\d+),(\d+)\]',
      ).allMatches(p.source(692, 'async function ranaA(')))
        '${g[1]},${g[2]}': [int.parse(g[3]!), int.parse(g[4]!)],
    };
    // comer.js:696 SUBE (the old way up and down at the table's ends: no longer walked, moves lines 698 to 705)
    SUBE = [
      for (final v in const [80, 182]) p.at(696, v).toInt(),
    ];
    // moves line 723: where somebody stands to ask
    final lep = p.to(
      723,
      'const LEP=',
      RegExp(r'NINO\(id\)\?\[(\d+),(\d+)\]:\[(\d+),(\d+)\]'),
    );
    LEP_NINO = [lep[0].toInt(), lep[1].toInt()];
    LEP_ADULTO = [lep[2].toInt(), lep[3].toInt()];
    // moves line 758: story 33's places
    CE33 = p.named(758, 'CE33');
    BU33 = p.named(758, 'BU33');
    CH33 = p.named(758, 'CH33');
    HOME33 = p.named(758, 'HOME33');
    FETCH33 = p.named(758, 'FETCH33');
    HO33 = p.named(758, 'HO33');
    PA33 = p.named(758, 'PA33');
    PA33S = p.named(758, 'PA33S');
    PA0 = [SILLA[1], SY(SILLA[1], FILA)];
    REST33 = HOME33;
    // moves line 759: where the children stand to eat
    final e33 = p.to(
      759,
      'const EST33=',
      RegExp(
        r'luis:\{x:(\d+),y:(\d+),pl:\[(\d+),(\d+)\],dir:(-?1)\},carmen:\{x:(\d+),y:(\d+),pl:\[(\d+),(\d+)\],dir:(-?1)\}',
      ),
    );
    EST33 = {
      'luis': (x: e33[0], y: e33[1], pl: [e33[2], e33[3]], dir: e33[4]),
      'carmen': (x: e33[5], y: e33[6], pl: [e33[7], e33[8]], dir: e33[9]),
    };
    // moves line 812: the tray of rolls on the stove's top
    BANDEJA = p
        .to(
          812,
          '{id:"bandeja"',
          RegExp(r'\{id:"bandeja",k:"bandeja",v:4,x:(\d+),y:(\d+),'),
        )
        .map((v) => v.toInt())
        .toList();
    // comer.js:1237 LUGAR (the frog on the cloth), CAM (views.wide), heartAt [130, 22] (unchanged: on the wall over the
    // table)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [
      for (final v in const [130, 22]) p.at(1237, v),
    ];
    cosas = [
      for (final id in QUIEN.keys) persona(id),
      for (final id in const [
        'di_buen',
        'di_tambien',
        'di_lleno',
        'di_poco',
        'di_mucho',
      ])
        Thing(
          id: id,
          si: (w) => true,
          box: (M w) {
            final b = frogBox(w['cq'] as M);
            return [b.x + (b.w.toInt() >> 1) - 8, b.y - 27, 16, 10];
          },
          m: 0,
        ),
      porId('mant', 26, 18),
      porId('choc', 26, 18),
      porId('cesta', 48, 24, 0),
      porId('cafetera', 24, 28, 0),
      porId('azucarera', 24, 18, 0),
      porId('olla', 30, 26, 0),
      porId('fuente', 56, 22, 0),
      porId('pl_papa', 24, 10, 0),
      porId('pl_rana', 18, 9, 0),
      // the set things: papá's chair (the chair at W.sitio.papa: things.silla_papa.byChair), the table and the room
      // (things.<id>.box, hand, hintBox)
      Thing(
        id: 'silla_papa',
        si: (w) => true,
        box: (M w) {
          final s = w['sitio'] as Map?;
          final i = s != null && s['papa'] != null ? s['papa'] as num : 3;
          return [
            for (final v in (_byChair[i.toInt()] as List)) (v as num).toInt(),
          ];
        },
        hand: p.hand('silla_papa'),
        hintBox: p.hintBox('silla_papa'),
        m: 0,
      ),
      for (final id in const ['mesa', 'cocina'])
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

  late final ComerPlaces _p;

  // the set's geometry (comer-set.html COMER_SET: Gs, surfaceAt, the origin), which the preview's functions read
  // (CUR.set): the same for every state
  late final ComerPlan _geo;

  @override
  String get id => 'comer';

  @override
  PpEngine newEngine({bool still = false}) => comerEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  /// The scene's places, read from its sheet (comer_places.dart).
  ComerPlaces get places => _p;

  /// The set's plan (comer-set.html: Gs, the seats, the table, surfaceAt).
  ComerPlan get plan => _geo;

  List<dynamic> get _byChair =>
      sheet.things['silla_papa']!.raw['byChair'] as List<dynamic>;

  // the old file's globals, through the host
  M get W => host.W;
  M get V => host.V;
  int get F => host.F;
  Sfx get SFX => host.SFX;
  Future<void> wait(num ms) => host.wait(ms);
  int get TICK => host.TICK;
  ({num x, num y, num w, num h}) frogBox(M q) => host.frogBox(q);
  Future<void> hopTo(num x, num y, int n, [num? s]) => host.hopTo(x, y, n, s);
  Sprite spr(String k, Sprite Function() make) => host.lib.spr(k, make);
  List<num> get cam => host.cam;
  String? get TALK => host.TALK;

  // DECISION(order 40b): comer.js reads the page's address for `?txt=no` (SINTXT: a speaker has an empty bubble over
  // him while the words are hidden). The host is the story runner, which keeps the setting as `TXT` (a `TxtMode`,
  // feature_story's); the scene reads it through the host as El balcón reads the runner's `rng`, by name: a host without
  // it (a picture, a still) shows the words, as the page with no `?txt=`
  bool get SINTXT {
    try {
      final t = (host as dynamic).TXT;
      return t is Enum && t.name == 'no';
    } catch (_) {
      return false;
    }
  }

  /* ---------- the constants (comer.js:20 to :23, :574 to :579, :629, :640, :692, :696, :723, :758, :759) ---------- */

  late final List<int> MESA, SILLA;
  late final int FILA, MED, FREN, TZ, ASIENTO, ATRAS, FR, FLO, XP;
  late final num SYC, SYD;
  late final List<int> DOOR, PB;
  late final List<num> DETRAS_, ENTOP_, MESAPIE_;
  late final int FRONTROW_;
  late final List<int> CARTAS_CX;
  late final int CARTAS_Y;
  late final List<List<int>> LIBRE_AT;
  late final List<int> LE, CAR, FOGON, AFOGON, DER, PUERTA;
  late final List<int> HIJA, OLLA, PLUIS, PRANA, CASA34, EAT34, LUIS34, FU34;
  late final List<int> PLAT34, CONT34, SIDE34, ENC34, AIM34;
  late final Map<String, List<int>> NUBE34;
  late final List<int> K1, K2, AZU, TRANA, GRECA35, GRECA35B, TABU, CASA35;
  late final List<int> CANELO, TAZON, STOOL, NUBE35, AIM35, CAFE35, CAZO35;
  late final List<int> FRENTE;
  late final Map<String, List<int>> HOPAT;
  late final List<int> SUBE, LEP_NINO, LEP_ADULTO;
  late final List<int> CE33, BU33, CH33, HOME33, FETCH33, HO33, PA33, PA33S;
  late final List<num> PA0;
  late final List<int> REST33;
  late final Map<String, ({num x, num y, List<num> pl, num dir})> EST33;
  late final List<int> BANDEJA;

  // moves line 21: SY, a row at the table stepping down half a row a pixel to the right (round x 118)
  num SY(num x, num y) => y + (x - SYC) / SYD;

  // moves line 21: DETRAS, a place behind the table (or in the passage at its left end)
  bool DETRAS(num x, num y) {
    final d = DETRAS_;
    return (y < d[0] + x / d[1] || (x < d[2] && y < d[3] - x / d[4])) &&
        y > d[5] - x / d[6] &&
        x < d[7];
  }

  // moves line 21: ENTOP, a foot on the cloth
  bool ENTOP(num x, num y) {
    final d = ENTOP_;
    return y >= d[0] + x / d[1] &&
        y <= d[2] + x / d[3] &&
        y >= d[4] - x / d[5] &&
        y <= d[6] - x / d[7];
  }

  // moves line 21: MESAPIE, a floor point under the table
  bool MESAPIE(num x, num y) {
    final d = MESAPIE_;
    return y > d[0] + x / d[1] &&
        y < d[2] + x / d[3] &&
        y > d[4] - x / d[5] &&
        y < d[6] - x / d[7];
  }

  // moves line 21: FRONTROW, the first row at x in front of the table's foot
  num FRONTROW(num x, num y) {
    var yy = y;
    while (MESAPIE(x, yy) && yy < FRONTROW_) {
      yy++;
    }
    return yy;
  }

  // comer.js:577 SEAT34 (papá's chair, empty until the end, is the one at the right end), :758 SEAT33
  static const Map<String, int> SEAT34 = {
    'mama': 0,
    'carmen': 1,
    'abuelo': 2,
    'papa': 3,
  };
  static const Map<String, int> SEAT33 = {
    'abuelo': 0,
    'abuela': 1,
    'mama': 2,
    'papa': 3,
  };

  // comer.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  /* ---------- what can be touched (comer.js:329 to :337) ---------- */

  // comer.js: NINO
  static bool NINO(String id) => QUIEN[id]?.nino ?? false;

  // comer.js: alto
  int alto(String id) {
    final p = G(id), sent = p != null && jsTruthy(p['sent']);
    return id == 'abuela'
        ? (sent ? 48 : 51)
        : NINO(id)
        ? (sent ? 37 : 44)
        : (sent ? 49 : 56);
  }

  // comer.js: caja (moves line 331: somebody seated is touched down to SY(x, MESA[1] + 14), relative to him). Somebody
  // who sits behind the table is touched from his head down over the edge of the table: the middle of his box is his
  // chest, so the stars of the signal fall beside and above his head, never on his face
  List<num>? caja(String id) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return null;
    final h = alto(id), x = _round(p['x'] as num), y = _round(p['y'] as num);
    return jsTruthy(p['sent'])
        ? [x - 11, y - h, 22, math.max(40, SY(x, MESA[1] + 14) - (y - h))]
        : [x - 11, y - h, 22, h];
  }

  // comer.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as M?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (M w) => caja(id),
  );

  // comer.js: G, ob
  M? G(Object? id) => (W['gente'] as M?)?['$id'] as M?;
  M? ob(String id) {
    for (final o in (W['cosas'] as List?) ?? const []) {
      if (o is Map && o['id'] == id) return o as M;
    }
    return null;
  }

  // comer.js: porId (z: in front of the frog, 1 when not given)
  Thing porId(String id, int w, int h, [int? z]) => Thing(
    id: id,
    si: (M w2) => ((w2['cosas'] as List?) ?? const []).any(
      (o) => o is Map && o['id'] == id && o['vis'] != 0,
    ),
    box: (M w2) {
      final o = (w2['cosas'] as List).firstWhere(
        (o) => o is Map && o['id'] == id,
      );
      return [
        _round(o['x'] as num) - (w >> 1),
        _round(o['y'] as num) - h,
        w,
        h,
      ];
    },
    m: 1,
    z: (z ?? 1) != 0,
  );

  // comer.js: COSAS
  @override
  late final List<Thing> cosas;

  // comer.js: fresh (code line 1238: respEn and the frog's first place, unchanged)
  @override
  M fresh(M story) => {
    'respEn': [
      for (final v in const [130, 22]) _p.at(1238, v),
    ],
    'gente': <String, dynamic>{},
    'sitio': <String, dynamic>{},
    'cosas': <dynamic>[],
    'vuelos': <dynamic>[],
    'perro': null,
    'tarjeta': null,
    'marcas': null,
    'cq': <String, dynamic>{
      'x': _p.at(1238, 108),
      'y': _p.at(1238, 141),
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'sobre': 1,
      'bub': null,
      'hace': null,
      'piensa': null,
      'tiene': <dynamic>[],
    },
  };

  /* ---------- the set ---------- */

  // the sheet's setKey: one baked state, "comer"
  @override
  String setKey(M W) => ComerState.KEY;

  @override
  void buildSet(PpEngine e, PpBuild b, M W) => buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = ComerSet(e, b, ComerState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the chairs' and the table's
    // own pixels)
    final tag = !_frontPixels.containsKey(key);
    if (tag) s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    if (tag) {
      final tags = s.k.PART_TAGS!;
      _frontPixels[key] = {
        for (final en in sheet.frontParts.entries)
          en.key: () {
            final parts = (en.value.raw['parts'] as List).cast<String>();
            return Int32List.fromList([
              for (var i = 0; i < tags.length; i++)
                if (parts.contains(tags[i])) i,
            ]);
          }(),
      };
      s.k.PART_TAGS = null;
    }
  }

  /// The pixels of each front part in the baked state [key], once this scene has baked it (its first bake records them).
  Map<String, Int32List>? frontPixelsOf(String key) => _frontPixels[key];

  // the frog is comer.js's own (rana): the old flat shadow juego.js's frog() draws is not drawn, and the sheet casts none
  // (shadows.coqui: none)
  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  /* ---------- the shadows (sheet: shadows), as comer-preview.html casts them (PV.casts) ---------- */

  // the kitchen's one light: whoever stands on the clear floor casts a small shadow from the floor point under their
  // feet (at .3, .65, 1, 1.35, 1.7: shadows.people.radius by id, a child's, or the other); the dog at .2; whoever sits,
  // the frog and what stands on the table cast none
  @override
  List<ShadowCast> shadows(M W) {
    final out = <ShadowCast>[];
    final SH = sheet.shadows, radii = SH['people']!.radii!;
    final G = (W['gente'] as M?) ?? const {};
    for (final en in G.entries) {
      final p = en.value as M?;
      if (p == null ||
          p['vis'] == 0 ||
          (p['al'] != null && (p['al'] as num) <= .5) ||
          jsTruthy(p['sent'])) {
        continue;
      }
      final s = _geo.surfaceAt(
        _round(p['x'] as num),
        _round(p['y'] as num) - 1,
      );
      if (s.on != 'floor' || s.under != null) continue;
      final r =
          radii[en.key] ?? (NINO(en.key) ? radii['nino']! : radii['other']!);
      for (final z in const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: s.x, y: s.y, z: z, r: r));
      }
    }
    final pe = W['perro'] as M?;
    if (pe != null && pe['vis'] != 0) {
      final s = _geo.surfaceAt(
        _round(pe['x'] as num),
        _round(pe['y'] as num) - 1,
      );
      if (s.on == 'floor' && s.under == null) {
        out.add((x: s.x, y: s.y, z: .2, r: SH['perro']!.radius));
      }
    }
    return out;
  }

  /* ---------- the set's parts in front, as it is drawn (sheet: front) ---------- */

  // comer-preview.html: vOf. The v = (x + y) / R2 of the floor point under a screen point
  double vOf(num sx, num sy) {
    final g = _geo.Gs(sx, sy, 0);
    return (g[0] + g[1]) / math.sqrt2;
  }

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // comer-preview.html: PV.OWN, which item drew each pixel last (null: none)
  List<ComerItem?>? _own;

  // the set as this frame shows it (shadows), before the sprite layer (drawFrame's step 4), and its depth
  // (comer-preview.html: `CUR.img`, `CUR.z`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, M W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // comer-preview.html: PV.item. Every item of the sorted list owns the pixels it drew last (their colour changed); a
  // front part's entry draws the set's own pixels again (PV.front). A frame drawn with no set (a player with no screen)
  // keeps no owners.
  void item(ComerItem o) {
    if (o.front != null) return o.d();
    final e = _frameEngine;
    if (e == null) return o.d();
    final own = _own ??= List<ComerItem?>.filled(e.W * e.H, null);
    final pix = e.pix, before = Uint32List.fromList(pix);
    o.d();
    for (var i = 0; i < pix.length; i++) {
      if ((pix[i] ^ before[i]) & 0xFFFFFF != 0) own[i] = o;
    }
  }

  // comer-preview.html: PV.front (sheet: front). At a front part's entry, its own pixels are drawn again where their
  // owner stands behind them: z[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the owner's plane (planeOf)
  void front(String name) {
    final e = _frameEngine, s = _setFrame, Z = _setZ, O = _own;
    if (e == null || s == null || Z == null || O == null) return;
    final list = _frontNow?[name];
    if (list == null) {
      throw StateError(
        'comer: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final pix = e.pix, W0 = e.W;
    final cache = <ComerItem, double?>{};
    for (final i in list) {
      final o = O[i];
      if (o == null) continue;
      final r = cache.containsKey(o) ? cache[o] : (cache[o] = planeOf(o, W));
      if (r == null) continue;
      final y = i ~/ W0;
      if (!(Z[i] > r / COS - (y + .5 - e.OY) * T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  // comer-preview.html: PV.planeOf. A list item's plane: the v of the floor point under a person's or the dog's feet;
  // the frog and the things on the cloth: none (nothing of the set is drawn again over them)
  double? planeOf(ComerItem o, M w) {
    if (o.id == 'coqui' || o.id == null) return null;
    if (o.id == 'perro') {
      final pe = w['perro'] as M?;
      return pe != null
          ? vOf(_round(pe['x'] as num), _round(pe['y'] as num) - 1)
          : null;
    }
    final p = (w['gente'] as M?)?[o.id] as M?;
    return p != null
        ? vOf(_round(p['x'] as num), _round(p['y'] as num) - 1)
        : null;
  }

  /* ---------- the frame (comer.js:546 to :569) ---------- */

  // moves line 535: enMesa, a foot on the cloth
  bool enMesa(M o) => ENTOP(o['x'] as num, o['y'] as num);

  // moves line 546: detrasMesa. ONE rule for the layers, for every scene and every frame: whoever is behind the table
  // (not seated, his feet behind the table, in the lane behind the chairs or the passage) is drawn behind everybody who
  // sits, together with everything he holds and his arms
  bool detrasMesa(M p) =>
      !jsTruthy(p['sent']) &&
      !jsTruthy(p['est']) &&
      p['z'] == null &&
      DETRAS(p['x'] as num, p['y'] as num) &&
      (p['x'] as num) < 186 &&
      (p['y'] as num) - ((p['x'] as num) - SYC) / SYD < ATRAS + 3;

  // moves line 547: capa. The seated and the children at the corners (est) have their hands over the cloth, sorted by
  // their row along the table (of two in one row the one to the right is drawn over the other; abuela on her stool keeps
  // her own row); everybody else by his feet
  List<num> capa(M p) {
    final x = p['x'] as num, y = p['y'] as num;
    if (p['z'] != null) return [p['z'] as num, (p['z'] as num) + .001];
    if (jsTruthy(p['sent']) || jsTruthy(p['est'])) {
      return [x < 186 ? y - (x - SYC) / SYD + x / 10000 : y, TZ + .9];
    }
    if (detrasMesa(p)) {
      return [
        40 + (y - (x - SYC) / SYD) / 100,
        40.5 + (y - (x - SYC) / SYD) / 100,
      ];
    }
    return [y, y < TZ ? TZ + .9 : y + .001];
  }

  // comer.js: draw
  @override
  void draw(Ctx c, M W, int a) {
    final q = W['cq'] as M, Gt = (W['gente'] as M?) ?? <String, dynamic>{};
    c.smoothing = false;
    // moves line 548: the answer cards' place, at every frame while the frog chooses (CARTAS)
    if (jsTruthy(W['resp'])) W['respEn'] = CARTAS(W);
    // comer.js:549, the background (fondo), is dropped (sheet: dropped): the set
    final L = <ComerItem>[];
    for (final id in Gt.keys) {
      final p = Gt[id] as M?;
      if (p == null || p['vis'] == 0) continue;
      final cp = capa(p);
      L.add(ComerItem(cp[0], () => cuerpo(c, id, a), id: id));
      L.add(ComerItem(cp[1], () => objetos(c, id, a), id: id));
    }
    // comer.js:552, the old table (mkMesa), is dropped (sheet: dropped): at its place in the sorted list the set's table
    // is drawn again over whoever is behind it (front.parts.mesa)
    L.add(ComerItem(TZ, () => front('mesa'), front: 'mesa'));
    for (final v in (W['cosas'] as List?) ?? const []) {
      final o = v as M;
      if (o['vis'] == 0) continue;
      L.add(
        ComerItem(
          o['z'] != null
              ? o['z'] as num
              : enMesa(o)
              ? TZ + (o['y'] as num) / 1000
              : (o['y'] as num) + 1,
          () => cosaDibuja(c, o, a),
        ),
      );
    }
    final pe = W['perro'] as M?;
    if (pe != null && pe['vis'] != 0) {
      L.add(ComerItem(pe['y'] as num, () => perro(c, pe, a), id: 'perro'));
    }
    if (jsTruthy(q['vis'])) {
      L.add(
        ComerItem(
          q['sobre'] == 0
              ? (q['y'] as num) + 27
              : TZ + ((q['y'] as num) + 27) / 1000,
          () => rana(c, q, a),
          id: 'coqui',
        ),
      );
    }
    // the other front parts (sheet: front.parts, the chairs at sortY 60), before the sort; each item owns what it drew
    // last (comer-preview.html PV.item)
    for (final en in sheet.frontParts.entries) {
      if (en.key == 'mesa') continue;
      final part = en.key;
      L.add(ComerItem(en.value.sortY!, () => front(part), front: part));
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
    for (final v in [...(W['vuelos'] as List?) ?? const []]) {
      final o = v as M;
      if (o['k'] == 'chorro') {
        chorro(
          c,
          o['x'] as num,
          o['y'] as num,
          (o['y'] as num) + (o['h'] as num),
          jsTruthy(o['col']) ? o['col'] as String : '#5A2E14',
        );
      } else {
        tenidaC(
          c,
          o['k'] as String,
          o['x'] as num,
          o['y'] as num,
          _or(o['e'], 1),
          o['v'],
          o['flip'],
        );
      }
    }
    if (SINTXT) {
      // the words are hidden: whoever speaks has an empty speech bubble over him (a tail to his head), clear of what is
      // around him
      final T = TALK;
      if (T == 'coqui' && jsTruthy(q['vis'])) {
        final b = frogBox(q),
            fx = b.x + (b.w.toInt() >> 1),
            fy = b.y + _round(_n(q['dy']));
        // moves line 565: at the first talk place clear of every other face (LIBRE)
        final u = LIBRE('coqui', fx, fy - 3, b.w.toInt() >> 1);
        hab(c, u[0], u[1], u[0]);
      } else if (T != null && Gt[T] != null && (Gt[T] as Map)['vis'] != 0) {
        final t = talkAt(T, W), p = Gt[T] as M;
        if (t != null) {
          if (T == 'abuela' &&
              (p['x'] as num) > _p.at(566, 190) &&
              (p['y'] as num) < _p.at(566, 170)) {
            hab(c, t[0] - 6, t[1] + 9, t[0] - 19);
          } else {
            // moves line 566: at the first talk place clear of every other face (LIBRE)
            final u = LIBRE(T, t[0], t[1] - 1, 6);
            hab(c, u[0], u[1], u[0]);
          }
        }
      }
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as M?;
      if (p != null && jsTruthy(p['piensa']) && p['vis'] != 0) {
        nube(
          c,
          _round(p['x'] as num) - 20 + _n(p['pdx']),
          _round(p['y'] as num) - alto(id) - 38,
          p['piensa'] as M,
        );
      }
    }
    if (jsTruthy(q['vis']) && jsTruthy(q['piensa'])) {
      final b = frogBox(q),
          n =
              (q['nube'] as List?)?.cast<num>() ??
              [b.x + (b.w.toInt() >> 1) - 20, b.y - 44];
      nube(
        c,
        n[0],
        n[1],
        q['piensa'] as M,
        q['ndir'],
        (q['nubeAim'] as List?)?.cast<num>(),
      );
    }
    // the set as framed is this frame's only (drawFrame gives it again before the next)
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
    _own = null;
  }

  // comer.js: talkAt
  @override
  List<num>? talkAt(String who, M W) {
    final p = (W['gente'] as M?)?[who] as M?;
    if (p == null || p['vis'] == 0) return null;
    return [_round(p['x'] as num), _round(p['y'] as num) - alto(who) - 1];
  }

  // comer.js: respIcon (draws nothing)
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) => null;

  // comer.js: hud. Two places: every story has two scored rounds
  @override
  void hud(Ctx c, M W, int a) {
    final g = c;
    if (!jsTruthy(W['tarjeta'])) return;
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
    kit.tarjeta(g, 3, 3, 6 + 20 * marcas.length, 24);
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

  // comer.js: marca
  void marca(Object? m) {
    final l = W['marcas'] as List?;
    final i = l == null ? -1 : l.indexOf(null);
    if (i >= 0) l![i] = m;
  }

  // comer.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    await wait(200);
  }

  // comer.js: poke
  @override
  dynamic poke(String what) => null;

  // comer.js: acts
  @override
  late final Map<String, Act> ownActs = _comerActs();

  // comer.js: estado
  @override
  String estado(M W) {
    final C = (W['cosas'] as List?) ?? const [];
    M? find(bool Function(M o) f) {
      for (final o in C) {
        if (o is Map && f(o as M)) return o;
      }
      return null;
    }

    final f = find((o) => o['id'] == 'fuente'),
        ce = find((o) => o['id'] == 'cesta'),
        tb = find((o) => o['id'] == 'tabla');
    final g = (W['gente'] as M?) ?? const {};
    String roll(Object? r) {
      final m = r as Map;
      return '${jsTruthy(m['mal']) ? 'ma' : _js(m['st'])}${jsTruthy(m['con']) ? _js(m['con']) : ''}';
    }

    final gente = [
      for (final k in g.keys)
        if ((g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as M, tiene = (p['tiene'] as List?) ?? const [];
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}'
                '${jsTruthy(p['sent']) ? 's' : ''}'
                '${tiene.isNotEmpty ? '^${[for (final t in tiene) _js((t as Map)['k'])].join('+')}' : ''}'
                '${jsTruthy(p['come']) ? '(${_js((p['come'] as Map)['k'])})' : ''}';
          }(),
    ].join(' ');
    final platos = [
      for (final o in C)
        if (o is Map && (o['k'] == 'plato' || o['k'] == 'platoc'))
          '${(o['id'] as String).substring(3)}:${jsTruthy(o['v']) ? _js(o['v']) : ''}/${[for (final r in (o['rollos'] as List?) ?? const []) roll(r)].join('+')}',
      for (final k in const ['abuela'])
        if (g[k] != null)
          () {
            Map? pt;
            for (final t in ((g[k] as Map)['tiene'] as List?) ?? const []) {
              if ((t as Map)['k'] == 'plato') {
                pt = t;
                break;
              }
            }
            return pt != null
                ? 'ab_en_mano:${jsTruthy(pt['v']) ? _js(pt['v']) : ''}/${[for (final r in (pt['rollos'] as List?) ?? const []) roll(r)].join('+')}'
                : 'ab_en_mano:/';
          }(),
    ].join('|');
    final tabla = tb != null && jsTruthy(tb['rollo'])
        ? '${_js((tb['rollo'] as Map)['st'])}${jsTruthy((tb['rollo'] as Map)['con']) ? _js((tb['rollo'] as Map)['con']) : ''}'
        : '-';
    final malos = tb != null && jsTruthy(tb['malos'])
        ? (tb['malos'] as List).length
        : 0;
    String vOf(String id) {
      final o = find((o) => o['id'] == id);
      return o != null && jsTruthy(o['v']) ? _js(o['v']) : '-';
    }

    final tazas = [
      for (final o in C)
        if (o is Map && o['k'] == 'taza')
          '${(o['id'] as String).substring(2)}:${_js(o['v'])}${jsTruthy(o['vapor']) ? '*' : ''}${o['vis'] == 0 ? '^' : ''}',
    ].join('|');
    final fuente = f != null
        ? '${(f['montones'] as List).where((m) => (m as Map)['g'] == 'm').length}m'
              '${(f['montones'] as List).where((m) => (m as Map)['g'] == 'p').length}p'
        : '-';
    final marcas = [
      for (final m in (W['marcas'] as List?) ?? const [])
        m == null ? '' : _js(m),
    ].join(',');
    return 'gente=$gente cesta=${ce != null ? _js(ce['v']) : '-'} fuente=$fuente platos=$platos'
        ' tabla=$tabla malos=$malos mant=${vOf('mant')} choc=${vOf('choc')}'
        ' tazas=$tazas pmont=${_js(V['pmont'])} marcas=$marcas';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A point keeps its screen place (the sheet's `new`; the few the sheet moved: cual-comer's things
  // on the cloth, people off the table's foot); the frog out of a picture is no place (`to.none`) and is given back; a
  // pair rectangle gives the crop of the pictures it was; a level picture's rectangle gives itself back (the level
  // pictures are the sheet's).
  @override
  List<num> remap(List<num> xy) {
    switch (xy.length) {
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
        throw SheetError('a position is 2 or 4 numbers, not $xy');
    }
  }

  // comer-preview.html: PV.pair's remapW for a review picture's own W (the pair's file, cual-comer): each person, thing
  // and thing in the air at a place of a move or of a moved remap entry the sheet gives for cual-comer to its new one. The
  // top level's dog and frog are ScenePictures' (the sheet's remap).
  @override
  void placePair(M set) => remapW(set, 'cual-comer', top: false);

  // comer-preview.html: PV.remapW. A W in old positions, moved by the sheet's rule: the places of moves (MV), and the
  // story positions the sheet moved (RM: moved points whose uses are [story]'s, any when null); a person's fraction of a
  // pixel is kept; the frog by his feet (`cq.feet`) or by a remap entry of his own. [top]: the top level's dog and frog
  // too (ScenePictures moves those itself)
  void remapW(M w, String? story, {bool top = true}) {
    final MV = [for (final m in sheet.moves) ...m.places];
    final RM = [
      for (final e in sheet.remapTable)
        if (e.moved &&
            e.kind == 'point' &&
            (story == null || e.uses.any((u) => u.startsWith('$story.json'))))
          e,
    ];
    List<num>? find(String who, Map p) {
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      for (final q in MV) {
        if (q.who == who && q.old[0] == x && q.old[1] == y) return q.now;
      }
      for (final e in RM) {
        if (e.old[0] == x && e.old[1] == y) return e.now!;
      }
      return null;
    }

    for (final en in ((w['gente'] as M?) ?? const {}).entries) {
      final p = en.value;
      if (p is! Map || p['x'] == null) continue;
      final m = find(en.key, p);
      if (m != null) {
        final px = p['x'] as num, py = p['y'] as num;
        p['x'] = m[0] + (px - _round(px));
        p['y'] = m[1] + (py - _round(py));
      }
    }
    for (final o in [
      ...(w['cosas'] as List?) ?? const [],
      ...(w['vuelos'] as List?) ?? const [],
    ]) {
      if (o is Map && o['x'] != null) {
        final m = find('cosa', o);
        if (m != null) {
          o['x'] = m[0];
          o['y'] = m[1];
        }
      }
    }
    if (!top) return;
    final pe = w['perro'];
    if (pe is Map && pe['x'] != null) {
      final m = find('perro', pe);
      if (m != null) {
        pe['x'] = m[0];
        pe['y'] = m[1];
      }
    }
    final q = w['cq'];
    if (q is Map) {
      for (final m in MV) {
        if (m.who == 'cq.feet' &&
            m.old[0] == (q['x'] as num) + 16 &&
            m.old[1] == (q['y'] as num) + 27) {
          q['x'] = m.now[0] - 16;
          q['y'] = m.now[1] - 27;
          return;
        }
      }
      for (final e in RM) {
        if (e.old[0] == q['x'] &&
            e.old[1] == q['y'] &&
            e.uses.every((u) => u.endsWith('.cq'))) {
          q['x'] = e.now![0];
          q['y'] = e.now![1];
          return;
        }
      }
    }
  }
}
