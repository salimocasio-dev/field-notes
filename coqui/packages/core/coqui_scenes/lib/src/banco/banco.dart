// Port of historia/escenas/banco.js: the scene "El banco", the benches in the park (order 36b). Line for line, minus its
// background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background, the moon, the
// night's and the evening's colours: the set's, by its light, `setKey`); every screen position replaced by what the
// sheet's `code` list gives for its line (banco_places.dart), and the places the sheet's `moves` list moves, each at its
// line (the moved source's own numbers: BancoPlaces.to). banco.js is written on the kit, so this is an `Escena`; its set
// is [BancoSet].
//
// What El banco's sheet has that the earlier ones did not, or uses differently, and how it is kept here (as
// banco-preview.html keeps it):
// - The draw order "as it is drawn" (`front`): every item of the sorted list owns the pixels it drew last
//   ([Banco.item]); at each front part's entry (the three benches, the cart, the lamp post, the pole, the gate's posts,
//   the hedge: all after everyone) the set's own pixels of the part are drawn again only where the pixel's owner stands
//   behind them, never over whoever sits on that bench or what lies on its seat ([Banco.front], [Banco.frontBox]).
// - The cart (`carro`): the set's while it stands (setKey carro abierto, cerrado); while it rolls (W.carroX) the set has
//   none and the sprite layer draws the set's own cart, pixel for pixel, moved along +y, its touch box with it
//   ([Banco.cart]).
// - The light (`light`, `patch`): evening and night are the set under another light, the lamp lit, the moon and no sun
//   at night; the sprites are not darkened (the old overlays are dropped).
// - `helps`: a pigeon in the air has its shadow (palomaA keeps the ground under it, `o.gs`: [Banco.GS]).
// - `moves` and `remap`: the gate (PORTON) and every way out through it, the cart and its man, the sitters on the seats'
//   edges (SY) and what lies on the seats (AS), the pigeons' perches, the dogs, the frog's home, Carmen, the answer cards
//   (W.respEn); the story files' own positions through remap.
// - `talk` (each sprite's height gives its face), `shadows` (the sun's: none at night), `hintBox` (the park).
//
// banco.js's object of acts names `manos` twice (lines 280 and 407) and `sale` twice (291 and 399): in a JavaScript
// object literal the later wins, so the old game ran 407's and 399's for every story. The port has them so.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco_places.dart';
import 'package:coqui_scenes/src/banco/banco_set.dart'
    show BancoSet, BancoState, bancoEngine;
import 'package:coqui_scenes/src/banco/banco_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "banco", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It draws
/// no random number.
Scene createBanco() => Banco(sheetOf('banco'));

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

// JavaScript: `x || d` for a number a story gives
num _or(Object? v, num d) => jsTruthy(v) ? _plus(v) : d;

// JavaScript: how `"" + v` writes a value of W (estado)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `"" + p[k]` of a field that may be missing
String _jsField(Map<String, dynamic> p, String k) =>
    p.containsKey(k) ? _js(p[k]) : 'undefined';

// JavaScript: `p.dir < 0` (a missing dir is not)
num _dir(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num ? p['dir'] as num : 0;

// JavaScript: Math.hypot
double _hypot(num a, num b) => math.sqrt(a * a + b * b);

// JavaScript: `s.startsWith(x)` of a value the old code has made sure is a string
bool _starts(Object? s, String x) => s is String && s.startsWith(x);

/// Who someone is (banco.js: an entry of `QUIEN`): the kit's figure, and what is drawn over it so that each one is his
/// own (`extra`). abuela is drawn by her own sprites ([who] null).
typedef BancoWho = ({Who? who, List<String> extra});

/// One entry of banco.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is
/// (banco-preview.html, sheet front.tags: `id` for a person or the frog, `perro`, `pal` (a pigeon), `cosa` (a thing),
/// `coche`, `carro` (the rolling cart), `front` for a part of the set drawn again).
class BancoItem {
  BancoItem(
    this.y,
    this.d, {
    this.id,
    this.perro,
    this.pal,
    this.cosa,
    this.coche = false,
    this.carro = false,
    this.front,
  });

  final num y;
  final void Function() d;
  final String? id, perro, front;
  final Map<String, dynamic>? pal, cosa;
  final bool coche, carro;
}

class Banco extends Escena implements SetScene, SetOverSprites, PairPlaces {
  Banco(this.sheet) {
    _p = BancoPlaces(sheet, bancoEngine());
    final p = _p;
    _geo = BancoSet(p.e, PpBuild(p.e));
    // banco.js:19 BANCOS (sheet: points.bancos, each bench's seat edge at its old point: kept); CARRO (moves line 19:
    // CARRO=[47,178] -> CARRO=[36,178]); FAROL (the set's: points.farol, things.farol); PORTON (moves line 19:
    // PORTON=[199,203], and the rules SY and AS beside it). SUELO was the background's only (code line 19).
    BANCOS = [
      for (final b in const [
        [96, 150],
        [144, 150],
        [192, 150],
      ])
        p.floor(19, b[0], b[1]),
    ];
    CARRO = [for (final v in p.to(19, 'CARRO=[47,178]')) v.toInt()];
    final po = p.to(
      19,
      'PORTON=[188,197];',
      RegExp(
        r'PORTON=\[(\d+),(\d+)\],SY=x=>\{const k=x<(\d+)\?0:x<(\d+)\?1:2;return Math\.round\((\d+)\+\(x-BANCOS\[k\]\[0\]\)/(\d+)\);\},AS=x=>SY\(x\)-(\d+);',
      ),
    );
    PORTON = [po[0].toInt(), po[1].toInt()];
    _sy = [for (final v in po.sublist(2)) v.toInt()];
    // banco.js:238 POSA (moves line 238: where the pigeons perch on the benches' backs); JUG; JUGEN (moves line 238:
    // the third toy lands in the gate's opening)
    final posa = p.to(238, 'POSA=[[110,127],[158,127],[176,127],[208,127]]');
    POSA = [
      for (var i = 0; i < posa.length; i += 2)
        [posa[i].toInt(), posa[i + 1].toInt()],
    ];
    final jugen = p.to(238, 'JUGEN=[[182,188],[195,196],[183,209],[196,211]]');
    JUGEN = [
      for (var i = 0; i < jugen.length; i += 2)
        [jugen[i].toInt(), jugen[i + 1].toInt()],
    ];
    // banco.js:124 LUGAR (sheet: lugar, the frog's spots frog.inicio, frog.centro)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _talk = sheet.talk!;
    // sheet helps.shadow.gsSource: GS, the ground under a pigeon in the air (its source's numbers)
    final gsSource = sheet.helps!.shadowGsSource!;
    final gm =
        RegExp(
          r'Math\.abs\(y-cableY\(x\)\)<=(\d+)&&y<(\d+)\?\[x,(\d+)\+\(x-(\d+)\)\*([\d.]+)\]:POSA\.some\(p=>Math\.abs\(p\[0\]-x\)<=(\d+)&&Math\.abs\(p\[1\]-y\)<=(\d+)\)\?\[x,y-1\+([\d.]+)\]:\(y>=(\d+)&&y<=(\d+)&&Math\.abs\(y-AS\(x\)\)<=(\d+)&&x>(\d+)&&x<(\d+)\)\?\[x,y-1\+([\d.]+)\]:\[x,y-1\]',
        ).firstMatch(gsSource) ??
        (throw SheetError(
          'the sheet\'s helps.shadow.gsSource is not as the port reads it: $gsSource',
        ));
    _gs = [for (var i = 1; i <= gm.groupCount; i++) num.parse(gm[i]!)];
    // banco.js:426 fresh's respEn (moves line 426: the answer cards in the sky under the rounds card)
    _respEn = [
      for (final v in p.to(426, 'fresh:()=>({respEn:[120,64],')) v.toInt(),
    ];
    // banco.js:130 to :135 COSAS (sheet: code line 133, things.carro, things.farol; :134 the benches; :135 the park:
    // things.<id>.box, hand and hintBox; lines 126 to 132: the people's, the dogs', the pushchair's and the pigeons'
    // boxes relative to them, unchanged)
    final cb = p.box('carro');
    cosas = [
      for (final id in QUIEN.keys) persona(id),
      for (final n in const ['viejo', 'joven', 'canelo']) perroC(n),
      Thing(
        id: 'coche',
        si: (w) => jsTruthy(w['coche']),
        box: (Map<String, dynamic> w) {
          final o = w['coche'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 19,
            _round(o['y'] as num) - 42,
            38,
            44,
          ];
        },
        m: 1,
      ),
      Thing(
        id: 'pajaro',
        si: (w) => ((w['palomas'] as List?) ?? const []).any(
          (o) => (o as Map)['vis'] != 0,
        ),
        box: (Map<String, dynamic> w) {
          final o = [
            for (final q in (w['palomas'] as List?) ?? const [])
              if ((q as Map)['vis'] != 0) q,
          ];
          final xs = [for (final q in o) q['x'] as num],
              ys = [for (final q in o) q['y'] as num];
          final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
          final y0 = ys.reduce(math.min), y1 = ys.reduce(math.max);
          return [x0 - 9, y0 - 14, x1 - x0 + 18, y1 - y0 + 18];
        },
        m: 0,
      ),
      // sheet things.carro.rolling: while it rolls its box moves with it (as banco-preview.html's edit of this line)
      Thing(
        id: 'carro',
        box: (Map<String, dynamic> w) => w['carroX'] != null
            ? [
                cb[0] + _round(w['carroX'] as num) - CARRO[0],
                cb[1] + _round((CARRO[0] - (w['carroX'] as num)) / 2),
                cb[2],
                cb[3],
              ]
            : cb,
        hand: p.hand('carro'),
        m: 0,
      ),
      for (final id in const ['farol', 'banco0', 'banco1', 'banco2', 'parque'])
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

  late final BancoPlaces _p;

  // the set's geometry (banco-set.html BANCO_SET: Gs, BENCH, the origin), which the preview's functions read (CUR.set):
  // the same for every state
  late final BancoSet _geo;

  @override
  String get id => 'banco';

  @override
  PpEngine newEngine({bool still = false}) => bancoEngine(still: still);

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
  void tone(num f0, num at, num dur, [String? type, num? vol, num? f1]) =>
      host.tone(f0, at, dur, type, vol, f1);
  Future<void> hopTo(num x, num y, int n, [num? s]) => host.hopTo(x, y, n, s);
  void bounce([num? h]) => host.bounce(h);
  Sprite spr(String k, Sprite Function() make) => host.lib.spr(k, make);

  /* ---------- the constants (banco.js:19 to :22, :124, :238) ---------- */

  late final List<List<int>> BANCOS;
  late final List<int> CARRO, PORTON;
  late final List<int> _sy;
  late final List<List<int>> POSA, JUGEN;
  late final List<num> _gs;
  late final List<int> _respEn;

  // banco.js:238 B, JUG
  List<List<int>> get B => BANCOS;
  static const List<String> JUG = ['sonajero', 'oso', 'bloque', 'patito'];

  // moves line 19: SY. Where whoever sits on a bench at x has their feet: on its seat's edge
  int SY(num x) {
    final k = x < _sy[0]
        ? 0
        : x < _sy[1]
        ? 1
        : 2;
    return _round(_sy[2] + (x - BANCOS[k][0]) / _sy[3]);
  }

  // moves line 19: AS. A thing put on the seat at x
  int AS(num x) => SY(x) - _sy[4];

  // banco.js: cableY (code line 20: the set's wire lies on its rows)
  int cableY(num x) => _round(50 + 7 * (1 - math.pow((x - 120) / 98, 2)));

  // banco.js: CABLE (code line 21: spots cable.0 to cable.4, unchanged)
  List<int> CABLE(int i) => [66 + i * 17, cableY(66 + i * 17)];

  // sheet helps.shadow.gsSource: GS. The ground under a pigeon's flight: under where it took off and where it lands, as
  // far along as it has flown
  List<num> GS(num x0, num y0, num x1, num y1, num t) {
    final g = _gs;
    List<num> at(num x, num y) {
      if ((y - cableY(x)).abs() <= g[0] && y < g[1]) {
        return [x, g[2] + (x - g[3]) * g[4]];
      }
      if (POSA.any(
        (p) => (p[0] - x).abs() <= g[5] && (p[1] - y).abs() <= g[6],
      )) {
        return [x, y - 1 + g[7]];
      }
      if (y >= g[8] &&
          y <= g[9] &&
          (y - AS(x)).abs() <= g[10] &&
          x > g[11] &&
          x < g[12]) {
        return [x, y - 1 + g[13]];
      }
      return [x, y - 1];
    }

    final a = at(x0, y0), b = at(x1, y1);
    return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
  }

  // banco.js: LUGAR
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

  // banco.js: QUIEN. The people; extra: what is drawn over the kit's figure so that each one is his own
  static final Map<String, BancoWho> QUIEN = {
    'luis': (who: FAM['hermano']!, extra: const []),
    'carmen': (who: FAM['hermana']!, extra: const []),
    'abuela': (who: null, extra: const []),
    'hombre': (
      who: Who(
        piel: PIEL['b']!,
        pelo: PELO['negro']!,
        peinado: 'corto',
        ropa: RP.blue,
        abajo: RP.grey,
      ),
      extra: const ['barba'],
    ),
    'mujer': (
      who: Who(
        piel: PIEL['c']!,
        pelo: PELO['negro']!,
        peinado: 'largo',
        ropa: RP.yel,
        falda: true,
        zapato: hx('#7A4A10'),
      ),
      extra: const [],
    ),
    'senor': (
      who: Who(
        piel: PIEL['a']!,
        pelo: PELO['blanco']!,
        peinado: 'corto',
        ropa: RP.wood,
        abajo: RP.grey,
        bigote: true,
      ),
      extra: const ['sombrero', 'baston'],
    ),
    'joven': (
      who: Who(
        piel: PIEL['b']!,
        pelo: PELO['castano']!,
        peinado: 'corto',
        ropa: RP.cream.sublist(1),
        abajo: RP.blue,
        zapato: hx('#F2F2F8'),
      ),
      extra: const ['gorra', 'mochila'],
    ),
    'senora': (
      who: Who(
        piel: PIEL['a']!,
        pelo: PELO['castano']!,
        peinado: 'corto',
        ropa: RP.grn,
        falda: true,
        zapato: hx('#F2F2F8'),
      ),
      extra: const ['cola'],
    ),
    'piraguero': (
      who: Who(
        piel: PIEL['a']!,
        pelo: PELO['negro']!,
        peinado: 'calvo',
        ropa: [hx('#C8C8D4'), hx('#E8E8F0'), hx('#FFFFFF'), hx('#FFFFFF')],
        abajo: RP.wood,
        bigote: true,
      ),
      extra: const ['delantal'],
    ),
  };

  // JavaScript: `(QUIEN[id]||{}).nino`
  static bool _nino(String id) => QUIEN[id]?.who?.nino ?? false;

  // banco.js: G
  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic> get _perros =>
      (W['perros'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  List get _palomas => W['palomas'] as List;

  // banco.js: alto
  int alto(String id) {
    final p = G(id);
    final sent = p != null && jsTruthy(p['sent']);
    return id == 'abuela'
        ? (sent ? 48 : 51)
        : _nino(id)
        ? (sent ? 40 : 44)
        : (sent ? 49 : 56);
  }

  // banco.js: caja
  List<num>? caja(String id) {
    final p = G(id);
    if (p != null && p['vis'] != 0) {
      return [
        _round(p['x'] as num) - 11,
        _round(p['y'] as num) - alto(id),
        22,
        alto(id),
      ];
    }
    return null;
  }

  // banco.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // banco.js: perroC
  Thing perroC(String n) => Thing(
    id: n == 'canelo' ? 'perro' : 'perro_$n',
    m: 2,
    si: (w) {
      final p = w['perros'] as Map<String, dynamic>?;
      return p != null && p[n] != null && (p[n] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) {
      final o = (w['perros'] as Map)[n] as Map<String, dynamic>;
      return [_round(o['x'] as num) - 15, _round(o['y'] as num) - 22, 30, 24];
    },
  );

  // banco.js: COSAS
  @override
  late final List<Thing> cosas;

  // banco.js: fresh (moves line 426: respEn)
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'respEn': [..._respEn],
    'gente': <String, dynamic>{},
    'palomas': <dynamic>[],
    'cosas': <dynamic>[],
    'perros': <String, dynamic>{},
    'coche': null,
    'bandeja': null,
    'encima': null,
    'manos': null,
    'encaja': <dynamic>[],
    'noche': 0,
    'tarde': 0,
    'carro': 1,
    'carroX': null,
    'seva': 0,
    'posadas': 0,
    'juguetes': 0,
    'tarjeta': null,
    'marcas': null,
    'cq': <String, dynamic>{
      'x': LUGAR['centro']![0],
      'y': LUGAR['centro']![1],
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
      'hace': null,
    },
  };

  /* ---------- the set ---------- */

  // the sheet's setKey table: luz + "." + luna + "." + carro (setKey.params' words)
  @override
  String setKey(Map<String, dynamic> W) {
    final noche = jsTruthy(W['noche']);
    final luz = noche
        ? 'noche'
        : jsTruthy(W['tarde'])
        ? 'tarde'
        : 'dia';
    final luna = noche && jsTruthy(W['luna']) ? 1 : 0;
    final carro = W['carroX'] != null || W['carro'] == 0
        ? 'no'
        : W['carro'] == 'cerrado'
        ? 'cerrado'
        : 'abierto';
    return '$luz.$luna.$carro';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = BancoSet(e, b, BancoState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the benches', the cart's,
    // the lamp post's, the pole's, the gate's posts' and the hedge's own pixels)
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
    }
  }

  final Map<String, Map<String, Int32List>> _frontPixels = {};

  /// The pixels of each front part in the baked state [key], once this scene has baked it (its first bake records them).
  Map<String, Int32List>? frontPixelsOf(String key) => _frontPixels[key];

  /// The scene's places, read from its sheet (banco_places.dart).
  BancoPlaces get places => _p;

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  /* ---------- the shadows (sheet: shadows), as banco-preview.html casts them (PV.casts) ---------- */

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  // every shadow is the sun's, cast from the ground point (z 0) under the screen point of the feet; none at night. The
  // frog at .3; each person at .3, .65, 1, 1.35, 1.7 (sitting: .3, .65, from the ground under their feet); a dog not in
  // the air at .25; the pushchair at .3 and .9; a pigeon on the ground, or in the air over the ground under its flight
  // (helps: o.gs), at .1; a thing lying on the ground (not on a seat, not in the air) at .1 (the box: .4)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    if (jsTruthy(W['noche'])) return out;
    final e = _p.e, SH = sheet.shadows;
    ({double x, double y}) on(num sx, num sy) => e.unproject(sx, sy);
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q), g = on(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: SH['coqui']!.radius));
    }
    final people = SH['people']!.radius;
    final G = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0 || _atMostHalf(p['al'])) continue;
      final sent = jsTruthy(p['sent']);
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      final g = sent ? on(x, y) : on(x, y - 1);
      for (final z
          in sent ? const [.3, .65] : const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: people));
      }
    }
    for (final v in ((W['perros'] as Map?) ?? const {}).values) {
      final o = v as Map<String, dynamic>?;
      if (o == null || o['vis'] == 0 || o['x'] == null || _n(o['dy']) > 3) {
        continue;
      }
      final g = on(_round(o['x'] as num), _round(o['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .25, r: SH['perros']!.radius));
    }
    final co = W['coche'] as Map<String, dynamic>?;
    if (co != null) {
      final g = on(_round(co['x'] as num), _round(co['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .3, r: SH['coche']!.radius));
      out.add((x: g.x, y: g.y, z: .9, r: .4));
    }
    for (final v in (W['palomas'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>?;
      if (o == null || o['vis'] == 0) continue;
      final k = perch(o, W);
      if (k == 'air') {
        final gs = o['gs'];
        if (jsTruthy(gs)) {
          final l = gs as List, g = on(l[0] as num, l[1] as num);
          out.add((x: g.x, y: g.y, z: .1, r: SH['paloma']!.radius));
        }
        continue;
      }
      if (k == 'ground') {
        final g = on(_round(o['x'] as num), _round(o['y'] as num) - 1);
        out.add((x: g.x, y: g.y, z: .1, r: SH['paloma']!.radius));
      }
    }
    for (final v in (W['cosas'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>?;
      if (o == null ||
          o['vis'] == 0 ||
          o['z'] == 400 ||
          (o['z'] != null && (o['z'] as num) > (o['y'] as num) + 30)) {
        continue;
      }
      final x = _round(o['x'] as num), y = _round(o['y'] as num);
      if (onSeat(x, y)) continue;
      final g = on(x, y - 1);
      out.add((
        x: g.x,
        y: g.y,
        z: .1,
        r: o['k'] == 'caja' ? .4 : SH['cosas']!.radius,
      ));
    }
    return out;
  }

  /* ---------- where things rest (banco-preview.html: backTop, onSeat, perch, vOf, vAt) ---------- */

  // banco-set.html: ZS, and ZS + BACK_H - .02 (the back's top)
  static const double _ZS = .42, _BACK_TOP = .42 + .6 - .02;

  // banco-preview.html: PV.backTop. The screen row of a bench's back's top at column x, or null
  double? backTop(num x) {
    final S = _geo, ox = S.e.OX, oy = S.e.OY;
    for (final b in S.BENCH) {
      final yy = b.y0 + .065;
      final wx = (x - ox) / 26 * math.sqrt2 + yy;
      if (wx >= b.x0 + .02 && wx <= b.x1 - .02) {
        final v = (wx + yy) / math.sqrt2;
        return oy + (v * .5 - _BACK_TOP * math.sqrt(3) / 2) * 26;
      }
    }
    return null;
  }

  // banco-preview.html: PV.onSeat. A place (x, y) on a bench's seat
  bool onSeat(num x, num y) {
    if (y >= 172) return false;
    final w = _geo.Gs(x, y - 1, _ZS);
    return _geo.BENCH.any(
      (b) =>
          w[0] >= b.x0 - .02 &&
          w[0] <= b.x1 + .02 &&
          w[1] >= b.y0 - .02 &&
          w[1] <= b.y1 + .02,
    );
  }

  // banco-preview.html: PV.perch. Where a pigeon is: in the air, on the wire, on a bench's back, on a seat, on the
  // pushchair or on the ground
  String perch(Map<String, dynamic> o, Map<String, dynamic>? w) {
    final x = _round(o['x'] as num), y = _round(o['y'] as num);
    if (o['pose'] == 'vuela') return 'air';
    if ((y - cableY(x)).abs() <= 1 && y < 80) return 'wire';
    final bt = backTop(x);
    if (bt != null && (y - 1 - bt).abs() <= 1.5) return 'back';
    if (onSeat(x, y)) return 'seat';
    final co = w?['coche'] as Map<String, dynamic>?;
    if (co != null &&
        (x - _round(co['x'] as num) - 14).abs() <= 2 &&
        (y - _round(co['y'] as num) + 33).abs() <= 2) {
      return 'coche';
    }
    return 'ground';
  }

  // banco-preview.html: vOf. The v = (x + y) / R2 of the ground under a screen point
  double vOf(num sx, num sy) {
    final g = _geo.Gs(sx, sy, 0);
    return (g[0] + g[1]) / math.sqrt2;
  }

  // banco-preview.html: PV.vAt. A thing on a seat or a pigeon on a bench's back: the plane of the point it rests on
  // (at that height), a little in front
  double vAt(num sx, num sy, num z) {
    final g = _geo.Gs(sx, sy, z);
    return (g[0] + g[1]) / math.sqrt2 + .02;
  }

  static String _benchAt(num x) =>
      'banco${x < 120
          ? 0
          : x < 168
          ? 1
          : 2}';

  /* ---------- the set's parts in front, as it is drawn (sheet: front) ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // banco-preview.html: PV.OWN, which item drew each pixel last (null: none)
  List<BancoItem?>? _own;

  // the set as this frame shows it (wind, shadows), before the sprite layer (drawFrame's step 4), and its depth
  // (banco-preview.html: `CUR.img`, `DEPTH.live()`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // banco-preview.html: PV.item. Every item of the sorted list owns the pixels it drew last (their colour changed); a
  // front part's entry draws the set's own pixels again (PV.front). A frame drawn with no set (a player with no screen)
  // keeps no owners.
  void item(BancoItem o) {
    if (o.front != null) return o.d();
    final e = _frameEngine;
    if (e == null) return o.d();
    final own = _own ??= List<BancoItem?>.filled(e.W * e.H, null);
    final pix = e.pix, before = Uint32List.fromList(pix);
    o.d();
    for (var i = 0; i < pix.length; i++) {
      if ((pix[i] ^ before[i]) & 0xFFFFFF != 0) own[i] = o;
    }
  }

  // banco-preview.html: PV.front (sheet: front). At a front part's entry, the set's own pixels of the part are drawn
  // again where the pixel's owner stands behind them: z[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the owner's
  // plane (frontBox), never over whoever sits on that bench or what lies on its seat (the owner's own bench).
  void front(String part) {
    final e = _frameEngine, s = _setFrame, Z = _setZ, O = _own;
    if (e == null || s == null || Z == null || O == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'banco: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final pix = e.pix, W0 = e.W;
    final cache = <BancoItem, ({double v, String? bench})?>{};
    for (final i in list) {
      final o = O[i];
      if (o == null) continue;
      final r = cache.containsKey(o) ? cache[o] : (cache[o] = frontBox(o, W));
      if (r == null || r.bench == part) continue;
      final y = i ~/ W0;
      if (!(Z[i] > r.v / COS - (y + .5 - e.OY) * T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  // banco-preview.html: PV.frontBox. A list item's plane (the v of the ground under it, or of the seat or back it rests
  // on) and the bench it is on: the frog; a person (sitting: their bench's seat front); a dog; a pigeon (not in the air
  // or on the wire: nothing is drawn over those); the pushchair; a thing (on a seat: its bench). Anything else (the
  // rolling cart) is not drawn over. (The preview's box, its first part, is not used by its test.)
  ({double v, String? bench})? frontBox(BancoItem o, Map<String, dynamic> w) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return (v: vOf(b.x + b.w / 2, (q['y'] as num) + 25), bench: null);
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      if (jsTruthy(p['sent'])) {
        final k = x < 120
            ? 0
            : x < 168
            ? 1
            : 2;
        final b = _geo.BENCH[k], g = _geo.Gs(x, y - 11, _ZS);
        return (v: (g[0] + b.y1) / math.sqrt2 + .03, bench: 'banco$k');
      }
      return (v: vOf(x, y - 1), bench: null);
    }
    if (o.perro != null) {
      final p = _perros[o.perro] as Map<String, dynamic>;
      return (
        v: vOf(_round(p['x'] as num), _round(p['y'] as num) - 1),
        bench: null,
      );
    }
    if (o.pal != null) {
      final p = o.pal!, k = perch(p, w);
      if (k == 'air' || k == 'wire') return null;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return (
        v: k == 'back'
            ? vAt(x, y, _ZS + .6)
            : k == 'seat'
            ? vAt(x, y, _ZS)
            : vOf(x, y - 1),
        bench: k == 'back' || k == 'seat' ? _benchAt(x) : null,
      );
    }
    if (o.coche) {
      final p = w['coche'] as Map<String, dynamic>;
      return (
        v: vOf(_round(p['x'] as num), _round(p['y'] as num) - 1),
        bench: null,
      );
    }
    if (o.cosa != null) {
      final p = o.cosa!, x = _round(p['x'] as num), y = _round(p['y'] as num);
      final seat = onSeat(x, y);
      return (
        v: seat ? vAt(x, y + (jsTruthy(p['rot']) ? 5 : 0), _ZS) : vOf(x, y - 1),
        bench: seat ? _benchAt(x) : null,
      );
    }
    return null;
  }

  /* ---------- the rolling cart (sheet: carro.rolling) ---------- */

  // the cart's own pixels (index, colour) in the state with the same light and moon and the cart closed, as that state's
  // frame at time 0 shows them (banco-preview.html PV.cartSprite: `frame(0, [])`, the pixels tagged carro)
  final Map<String, List<int>> _cartSprites = {};

  List<int> _cartSprite(Map<String, dynamic> w) {
    final key = setKey({...w, 'carroX': null, 'carro': 'cerrado'});
    return _cartSprites[key] ??= () {
      final e = bancoEngine(),
          s = BancoSet(e, PpBuild(e), BancoState.fromKey(key));
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      s.frame(0);
      final tags = s.k.PART_TAGS!, out = <int>[];
      for (var i = 0; i < tags.length; i++) {
        if (tags[i] == 'carro') out.addAll([i, e.pix[i]]);
      }
      return out;
    }();
  }

  // sheet carro.sprite.at: dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2). CARRO is banco.js's own as
  // the sheet moves it (moves line 19: 36), as the box (things.carro.rolling), the sorted list (moves line 198) and
  // banco-preview.html's PV.cartAt (spots.carro.new, round 4) take it: the cart starts to roll from where it stands
  List<int> cartAt(Map<String, dynamic> w) {
    final x = w['carroX'] as num;
    return [_round(x) - CARRO[0], _round((CARRO[0] - x) / 2)];
  }

  // banco-preview.html: PV.cart (CARRORUEDA: moves line 198). The cart rolling: the set's own cart, pixel for pixel,
  // moved by cartAt, on the picture the frame draws (none for a player with no screen)
  void cart(Ctx c, Map<String, dynamic> w) {
    final e = _frameEngine;
    if (e == null) return;
    final s = _cartSprite(w), d = cartAt(w), px = e.pix, cw = e.W, ch = e.H;
    for (var n = 0; n < s.length; n += 2) {
      final i = s[n], x = i % 240 + d[0], y = i ~/ 240 + d[1];
      if (x < 0 || y < 0 || x >= cw || y >= ch) continue;
      px[y * cw + x] = 0xFF000000 | (s[n + 1] & 0xFFFFFF);
    }
  }

  /* ---------- drawing ---------- */

  // banco.js: extra. What makes each of the new people his own, drawn over the kit's figure. hx,hy: the middle of the
  // face
  void extra(
    Ctx c,
    String k,
    num h,
    num hy,
    int d,
    Map<String, dynamic> p,
    Sprite im,
  ) {
    final sin = (p['sin'] as Map?) ?? const {};
    if (k == 'barba') {
      fr(c, h - 5, hy + 2, 10, 4, hx('#24160E'));
      fr(c, h - 2, hy + 3, 4, 1, hx('#7A2A1A'));
      fr(c, h - 6, hy - 1, 1, 4, hx('#24160E'));
      fr(c, h + 5, hy - 1, 1, 4, hx('#24160E'));
    } else if (k == 'gorra' && !jsTruthy(sin['gorra'])) {
      fr(c, h - 7, hy - 8, 14, 5, OUT);
      fr(c, h - 6, hy - 7, 12, 3, hx('#D0302A'));
      fr(c, h + d * 5 - (d < 0 ? 5 : 0), hy - 4, 6, 2, OUT);
      fr(c, h + d * 5 - (d < 0 ? 4 : 0), hy - 4, 5, 1, hx('#D0302A'));
    } else if (k == 'mochila' && !jsTruthy(sin['mochila'])) {
      // a rucksack on his back, its straps on his chest
      fr(c, h - d * 11 - (d < 0 ? -1 : 5), hy + 8, 6, 16, OUT);
      fr(c, h - d * 11 - (d < 0 ? 0 : 4), hy + 9, 4, 14, hx('#E88A2A'));
      fr(c, h - 6, hy + 10, 1, 12, hx('#B85A14'));
      fr(c, h + 5, hy + 10, 1, 12, hx('#B85A14'));
    } else if (k == 'sombrero' && !jsTruthy(sin['sombrero'])) {
      fr(c, h - 6, hy - 13, 12, 7, OUT);
      fr(c, h - 5, hy - 12, 10, 5, hx('#6A4A2A'));
      fr(c, h - 5, hy - 8, 10, 1, hx('#2A1A0E'));
      fr(c, h - 9, hy - 7, 18, 3, OUT);
      fr(c, h - 8, hy - 6, 16, 1, hx('#6A4A2A'));
    } else if (k == 'cola') {
      // a ponytail with a yellow band
      fr(c, h - d * 8 - (d < 0 ? 0 : 3), hy - 5, 4, 11, OUT);
      fr(c, h - d * 8 - (d < 0 ? -1 : 2), hy - 4, 2, 9, hx('#44260E'));
      fr(c, h - d * 6 - (d < 0 ? 0 : 2), hy - 6, 3, 3, hx('#F0C020'));
    } else if (k == 'baston' && !jsTruthy(sin['baston'])) {
      // his cane
      final bx = h + d * 12;
      fr(c, bx - 1, hy + 12, 3, im.h - 24, OUT);
      fr(c, bx, hy + 13, 1, im.h - 26, hx('#8A5A2A'));
      fr(c, bx - 3, hy + 11, 6, 3, OUT);
      fr(c, bx - 2, hy + 12, 4, 1, hx('#8A5A2A'));
    } else if (k == 'delantal') {
      fr(c, h - 6, hy + 12, 12, 14, hx('#F2F2F8'));
      fr(c, h - 6, hy + 12, 12, 1, hx('#C8C8D4'));
    }
  }

  // banco.js: animo. How somebody feels, drawn on the face: a tear and a turned-down mouth; a yawn and heavy eyes; a
  // wide smile
  void animo(Ctx c, Object? k, num h, num hy) {
    final t = (F >> 3) % 2;
    if (k == 'triste') {
      // slanted brows, a turned-down mouth, tears down both cheeks
      fr(c, h - 3, hy + 3, 6, 2, hx('#C89A70'));
      fr(c, h - 2, hy + 4, 4, 1, hx('#7A2A1A'));
      fr(c, h - 3, hy + 5, 1, 1, hx('#7A2A1A'));
      fr(c, h + 2, hy + 5, 1, 1, hx('#7A2A1A'));
      fr(c, h - 5, hy - 3, 2, 1, hx('#20140A'));
      fr(c, h - 3, hy - 4, 1, 1, hx('#20140A'));
      fr(c, h + 3, hy - 3, 2, 1, hx('#20140A'));
      fr(c, h + 2, hy - 4, 1, 1, hx('#20140A'));
      fr(c, h - 5, hy + 1, 2, 4 + t, hx('#5AB4F4'));
      fr(c, h + 3, hy + 1, 2, 3 + (1 - t), hx('#5AB4F4'));
      fr(c, h - 5, hy + 8 + t * 2, 2, 2, hx('#5AB4F4'));
    } else if (k == 'cansado') {
      // heavy lids, a flat mouth, sweat, puffs of breath
      fr(c, h - 4, hy - 1, 3, 1, hx('#20140A'));
      fr(c, h + 1, hy - 1, 3, 1, hx('#20140A'));
      fr(c, h - 4, hy, 3, 1, hx('#C89A70'));
      fr(c, h + 1, hy, 3, 1, hx('#C89A70'));
      fr(c, h - 3, hy + 3, 6, 2, hx('#C89A70'));
      fr(c, h - 2, hy + 4, 4, 1, hx('#7A2A1A'));
      fr(c, h + 6, hy - 7 + t, 2, 3, hx('#A8DCF8'));
      fr(c, h - 8, hy - 5 - t, 2, 3, hx('#A8DCF8'));
      const puffs = [
        [8, 2],
        [11, -1],
        [14, -4],
      ];
      for (var i = 0; i < puffs.length; i++) {
        final q = puffs[i];
        if ((F >> 2) % 4 > i) {
          fr(c, h + q[0] - 1, hy + q[1] - 1, 5, 4, OUT);
          fr(c, h + q[0], hy + q[1], 3, 2, hx('#FFFFFF'));
        }
      }
    } else if (k == 'contento') {
      fr(c, h - 3, hy + 3, 6, 2, hx('#7A1C1C'));
      fr(c, h - 2, hy + 3, 4, 1, hx('#FFFFFF'));
      fr(c, h - 4, hy + 2, 1, 1, hx('#7A1C1C'));
      fr(c, h + 3, hy + 2, 1, 1, hx('#7A1C1C'));
    }
  }

  // banco.js: cosa (here cosaSpr: the kit's Escena has a cosa of its own, a thing by its key)
  Sprite cosaSpr(String k) => spr('cs$k', COSA[k] ?? COSA['bolsa']!);

  // banco.js: tenida
  void tenida(Ctx c, String k, num x, num y, [Object? girada]) {
    final im = cosaSpr(k);
    if (jsTruthy(girada)) {
      c.save();
      c.translate(x.toDouble(), y.toDouble());
      c.rotate((girada as num).toDouble());
      c.drawImage(im, -(im.w >> 1), -im.h);
      c.restore();
    } else {
      c.drawImage(im, _round(x) - (im.w >> 1), _round(y) - im.h);
    }
  }

  // banco.js: gente
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
      if (jsTruthy(p['sent'])) {
        final ps = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
            top = y - 48;
        c.drawImage(
          spr('abS$ps$habla', () => mkAbuelaS(ps, habla != 0, false)),
          x - 17,
          top,
        );
        if (jsTruthy(p['ojos'])) {
          fr(c, x - 4, top + 12, 3, 1, hx('#20140A'));
          fr(c, x + 1, top + 12, 3, 1, hx('#20140A'));
        }
        if (jsTruthy(p['lleva'])) {
          tenida(c, p['lleva'] as String, x + 14, top + 16);
        }
        return;
      }
      final ps = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      c.save();
      c.translate(x.toDouble(), (y - 50 + (paso ? -1 : 0)).toDouble());
      if (d < 0) c.scale(-1, 1);
      c.drawImage(spr('ab$ps$habla', () => mkAbuela(ps, habla != 0)), -30, 0);
      c.restore();
      if (jsTruthy(p['lleva'])) {
        tenida(c, p['lleva'] as String, x + d * 12, y - 14);
      }
      return;
    }
    final pose = p['pose'] == 'wave'
        ? 'wave${a % 2}'
        : p['pose'] == 'arriba'
        ? 'wave0'
        : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
    final sent = jsTruthy(p['sent']);
    final im = spr(
      'pb$id$pose$habla${sent ? 1 : 0}',
      () => mkPersona(w!.who!, pose, habla != 0, sent),
    );
    final top =
        y -
        im.h +
        1 +
        (paso ? -1 : 0) -
        _n(p['dy']) +
        (p['animo'] == 'cansado'
            ? 3
            : p['animo'] == 'triste'
            ? 1
            : 0);
    c.save();
    c.translate(x.toDouble(), top.toDouble());
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    for (final k in w?.extra ?? const <String>[]) {
      extra(c, k, x, top + 11, d, p, im);
    }
    if (jsTruthy(p['animo'])) animo(c, p['animo'], x, top + 11);
    if (p['hace'] == 'come') {
      tenida(
        c,
        jsTruthy(p['que']) ? p['que'] as String : 'piragua',
        x + d * 5,
        top + 24 + (a % 2),
      );
    } else if (p['hace'] == 'bebe') {
      tenida(c, 'agua', x + d * 11, top + 7, -d * (a % 2 != 0 ? 2.3 : 2.45));
    } else if (jsTruthy(p['lleva'])) {
      tenida(c, p['lleva'] as String, x + d * 10, top + (_nino(id) ? 34 : 38));
    }
    if (jsTruthy(p['lleva2'])) {
      tenida(c, p['lleva2'] as String, x - d * 11, top + (sent ? 40 : 46));
    }
    if (jsTruthy(p['lee'])) {
      fr(c, x - 8, top + 24, 16, 9, OUT);
      fr(c, x - 7, top + 25, 14, 7, hx('#F2F2F8'));
      fr(c, x, top + 25, 1, 7, hx('#C8C8D4'));
      for (final yy in const [27, 29]) {
        fr(c, x - 6, top + yy, 5, 1, hx('#9494A6'));
        fr(c, x + 2, top + yy, 4, 1, hx('#9494A6'));
      }
    }
  }

  // banco.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 || q['hace'] == 'cansado' ? 1 : 0,
        op =
            (q['bub'] == 'hola' ||
                    host.TALK == 'coqui' ||
                    q['hace'] == 'canta' ||
                    q['hace'] == 'come') &&
                a % 2 != 0
            ? 1
            : 0,
        dy = _round(_n(q['dy'])) + (q['hace'] == 'cansado' ? 2 : 0),
        cx = b.x + (b.w.toInt() >> 1),
        m = (W['manos'] as Map?) ?? const {};
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    final bandeja = W['bandeja'];
    if (jsTruthy(bandeja)) {
      g.drawImage(cosaSpr('bandeja'), cx - 11, b.y + dy - 4);
      if (bandeja != 1) tenida(g, bandeja as String, cx, b.y + dy - 2);
    }
    // what he holds: one thing in each hand; the one he is eating or drinking goes to his mouth
    for (final s in const [('i', -1), ('d', 1)]) {
      final k = m[s.$1];
      if (!jsTruthy(k)) continue;
      final ks = k as String;
      final enboca =
          (q['hace'] == 'come' && ks.startsWith('piragua')) ||
          (q['hace'] == 'bebe' && ks == 'agua');
      if (enboca && ks == 'agua') {
        tenida(
          g,
          ks,
          cx + s.$2 * 3,
          b.y + dy + 10,
          s.$2 * (a % 2 != 0 ? 2.2 : 1.9),
        );
      } else if (enboca) {
        tenida(g, ks, cx + s.$2 * 2, b.y + dy + 21 + (a % 2));
      } else {
        tenida(g, ks, cx + s.$2 * 17, b.y + dy + b.h - 2);
      }
    }
    if (q['hace'] == 'canta') {
      final t = (F >> 2) % 4;
      nota(g, cx + 15 + t, b.y + dy - 8 - t);
    }
    if (q['hace'] == 'quieto') nota(g, cx + 18, b.y + dy - 6, true);
    if (q['hace'] == 'cansado') {
      final t = (F >> 3) % 2;
      fr(g, cx + 13, b.y + dy + 3 + t, 1, 2, hx('#A8CCF8'));
      fr(g, cx - 14, b.y + dy + 5 - t, 1, 2, hx('#A8CCF8'));
    }
    if (jsTruthy(W['encima'])) {
      tenida(g, W['encima'] as String, cx, b.y + dy + 2);
    }
  }

  static const List<String> _Z = ['#####', '...#.', '..#..', '.#...', '#####'];

  // JavaScript: `"" + v` of a value that may be undefined
  static String _js0(Object? v) => v == null ? 'undefined' : '$v';

  // banco.js: perro
  void perro(Ctx c, String n, int a) {
    final o = _perros[n] as Map<String, dynamic>?;
    if (o == null || o['vis'] == 0) return;
    if (jsTruthy(o['ronda'])) {
      // the young dog runs to and fro
      final t = (F - (o['fase'] as num)).remainder(44),
          u = t < 22 ? t / 22 : (44 - t) / 22;
      o['x'] = (o['x0'] as num) + u * 34;
      o['dir'] = t < 22 ? 1 : -1;
    }
    if (jsTruthy(o['paseo'])) {
      // the old dog walks slowly, there and back
      final t = (F - (o['fase'] as num)).remainder(130),
          u = t < 65 ? t / 65 : (130 - t) / 65;
      o['x'] = (o['x0'] as num) - u * 16;
      o['dir'] = t < 65 ? -1 : 1;
    }
    final pose = o['pose'] as String?;
    final anda =
        pose == 'walk' ||
        pose == 'run' ||
        pose == 'bark' ||
        pose == 'come' ||
        pose == 'cansado' ||
        pose == 'triste' ||
        jsTruthy(o['mueve']);
    final f = anda ? (a >> (pose == 'run' ? 0 : 1)) % 2 : 0,
        tp = jsTruthy(o['tipo']) ? o['tipo'] as String : n,
        pena = jsTruthy(o['pena']),
        im = spr(
          'can$tp${_js0(pose)}$f${pena ? 1 : 0}',
          () => mkCan(tp, pose, f, pena),
        );
    c.save();
    c.translate(
      _round(o['x'] as num).toDouble(),
      (_round(o['y'] as num) - im.h + 2 - _n(o['dy'])).toDouble(),
    );
    if (_dir(o) < 0) c.scale(-1, 1);
    c.drawImage(im, -13, 0);
    if (jsTruthy(o['lleva'])) {
      final t = cosaSpr(o['lleva'] as String);
      c.drawImage(
        t,
        16 - (t.w >> 1),
        (pose == 'lie' || pose == 'cansado' ? 17 : 12),
      );
    }
    if (jsTruthy(o['chal'])) c.drawImage(cosaSpr('chal'), -14, 10);
    c.restore();
    if (jsTruthy(o['zzz'])) {
      final t = (F >> 3) % 3;
      const zs = [
        [14, -20],
        [21, -27],
      ];
      for (var k = 0; k < zs.length; k++) {
        final q = zs[k];
        if (k != 0 && t < 1) continue;
        for (var jj = 0; jj < _Z.length; jj++) {
          final rw = _Z[jj];
          for (var ii = 0; ii < 5; ii++) {
            if (rw[ii] == '#') {
              fr(
                c,
                _round(o['x'] as num) + q[0] + ii - 1,
                _round(o['y'] as num) + q[1] + jj - 1,
                3,
                3,
                OUT,
              );
            }
          }
        }
        for (var jj = 0; jj < _Z.length; jj++) {
          final rw = _Z[jj];
          for (var ii = 0; ii < 5; ii++) {
            if (rw[ii] == '#') {
              fr(
                c,
                _round(o['x'] as num) + q[0] + ii,
                _round(o['y'] as num) + q[1] + jj,
                1,
                1,
                hx('#FFFFFF'),
              );
            }
          }
        }
      }
    }
    final correa = o['correa'];
    if (jsTruthy(correa)) {
      final l = correa as List, bx = l[0] as num, by = l[1] as num;
      c.strokeStyle = hx('#A82020');
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(
        _round(o['x'] as num) + (_dir(o) < 0 ? -5 : 5) + .5,
        _round(o['y'] as num) - 10.5,
      );
      c.lineTo(bx + .5, by + .5);
      c.stroke();
    }
  }

  // banco.js: coche
  void coche(Ctx c, int a) {
    final o = W['coche'] as Map<String, dynamic>?;
    if (o == null) return;
    final f = (a >> 1) % 2,
        capota = jsTruthy(o['capota']),
        bebe = o['bebe'] as String?,
        im = spr(
          'coche${capota ? 1 : 0}${bebe ?? ''}$f',
          () => mkCoche(capota, bebe, f),
        ),
        sx = jsTruthy(o['tiembla'])
            ? (a % 2 != 0 ? 1 : -1)
            : jsTruthy(o['mece'])
            ? _round(math.sin(F / 5) * 2)
            : 0,
        x = _round(o['x'] as num) - 19 + sx,
        y = _round(o['y'] as num) - 40;
    c.drawImage(im, x, y);
    if (bebe == 'duerme' && !capota) {
      // z z z
      final t = (F >> 3) % 3;
      fr(c, x + 27, y + 2 - t * 3, 3, 1, hx('#FFFFFF'));
      fr(c, x + 28, y + 3 - t * 3, 1, 1, hx('#FFFFFF'));
      fr(c, x + 27, y + 4 - t * 3, 3, 1, hx('#FFFFFF'));
    }
    if (bebe == 'llora') {
      // tears fly out from under the hood
      final t = (F >> 1) % 6;
      const ps = [
        [-4, -1],
        [2, -3],
        [9, -2],
        [15, -1],
      ];
      for (var i = 0; i < ps.length; i++) {
        final p = ps[i];
        fr(
          c,
          x + 10 + p[0] + (i % 2 != 0 ? t : -t),
          y + 6 + p[1] - ((t * 2 + i * 3) % 9),
          1,
          2,
          hx('#5A9AEA'),
        );
      }
    }
    if (jsTruthy(o['mano'])) {
      final t = (F >> 2) % 2;
      fr(c, x + 13 + t * 2, y + 1, 5, 6, OUT);
      fr(c, x + 14 + t * 2, y + 2, 3, 4, PIEL['b']![2]);
    }
    if (bebe == 'rie' && capota) {
      final t = (F >> 2) % 3;
      fr(c, x + 12, y - 2 - t, 2, 1, hx('#F0C020'));
      fr(c, x + 18, y - 4 - t, 2, 1, hx('#F0C020'));
    }
  }

  // banco.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // banco.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // banco.js:192 to :195, the background, the moon, the night's and the evening's colours, are dropped (sheet:
    // dropped): the set, for setKey(W)
    // moves line 196: the cart goes home, the dogs with it: the old one walks, the young one runs to and fro ahead; the
    // piragua man pushes it from behind along +y
    if (W['seva'] == 1 || W['seva'] == 3) {
      final pi = Gt['piraguero'] as Map<String, dynamic>?,
          v = _perros['viejo'] as Map<String, dynamic>?,
          j = _perros['joven'] as Map<String, dynamic>?;
      W['carroX'] = (W['carroX'] as num) - 1.1;
      final carroX = W['carroX'] as num;
      if (pi != null) {
        pi['x'] = carroX + 30;
        pi['y'] = CARRO[1] + 2 + (CARRO[0] - carroX) / 2;
      }
      if (v != null) v['x'] = (v['x'] as num) - .35;
      if (j != null) {
        final t = F - (j['fase'] as num),
            x = (j['x0'] as num) - t * .5 + 34 * math.sin(t / 7);
        j['dir'] = x < (j['x'] as num) ? -1 : 1;
        j['x'] = x;
      }
    }
    final L = <BancoItem>[];
    // moves line 198: the cart rolling (W.carroX) is the set's own cart, drawn by the sprite layer at its new row;
    // standing, it is the set's
    if (W['carro'] != 0 && W['carroX'] != null) {
      L.add(
        BancoItem(
          CARRO[1] + (CARRO[0] - (W['carroX'] as num)) / 2,
          () => cart(c, W),
          carro: true,
        ),
      );
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(
          BancoItem(
            jsTruthy(p['sent']) ? (p['y'] as num) - 8 : p['y'] as num,
            () => gente(c, id, a),
            id: id,
          ),
        );
      }
    }
    for (final v in (W['palomas'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>;
      if (o['vis'] != 0) {
        L.add(
          BancoItem(o['z'] != null ? o['z'] as num : o['y'] as num, () {
            final f = (a >> (o['pose'] == 'vuela' ? 0 : 1)) % 2,
                pose = o['pose'] as String?,
                im = spr('pal${pose ?? ''}$f', () => mkPaloma(pose, f));
            c.save();
            c.translate(
              _round(o['x'] as num).toDouble(),
              _round(o['y'] as num).toDouble(),
            );
            if (_dir(o) < 0) c.scale(-1, 1);
            c.drawImage(im, -7, -12);
            c.restore();
          }, pal: o),
        );
      }
    }
    for (final v in (W['cosas'] as List?) ?? const []) {
      final o = v as Map<String, dynamic>;
      if (o['vis'] != 0) {
        L.add(
          BancoItem(o['z'] != null ? o['z'] as num : (o['y'] as num) + 1, () {
            tenida(c, o['k'] as String, o['x'] as num, o['y'] as num, o['rot']);
            if (o['k'] == 'caja') {
              final encaja = (W['encaja'] as List?) ?? const [];
              for (var i = 0; i < encaja.length; i++) {
                final im = cosaSpr(encaja[i] as String);
                c.drawImage(
                  im,
                  _round(o['x'] as num) - 13 + i * 9,
                  _round(o['y'] as num) - 9 - im.h + (i % 2) * 2,
                );
              }
            }
            if (o['k'] == 'agua' && jsTruthy(o['charco'])) {
              fr(
                c,
                _round(o['x'] as num) - 9,
                _round(o['y'] as num) - 1,
                16,
                2,
                hx('#9CD8F0'),
              );
              fr(
                c,
                _round(o['x'] as num) - 6,
                _round(o['y'] as num) + 1,
                10,
                1,
                hx('#9CD8F0'),
              );
            }
          }, cosa: o),
        );
      }
    }
    for (final n in _perros.keys) {
      final o = _perros[n] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0) {
        L.add(BancoItem(o['y'] as num, () => perro(c, n, a), perro: n));
      }
    }
    final co = W['coche'] as Map<String, dynamic>?;
    if (co != null) {
      L.add(BancoItem(co['y'] as num, () => coche(c, a), coche: true));
    }
    if (jsTruthy(q['vis'])) {
      L.add(BancoItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    // the sorted list: the entries of the set's parts drawn again over whoever is behind them (sheet: front.parts, each
    // sortY 9999, after everyone); each item owns what it drew last (banco-preview.html PV.item)
    for (final en in sheet.frontParts.entries) {
      final part = en.key;
      L.add(BancoItem(en.value.sortY!, () => front(part), front: part));
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
    // banco.js:207 a person's bubble, where the sheet's talk puts it
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
    // banco.js:208 the frog's bubble, where the sheet's talk puts it
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

  // banco-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
  // head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view, clear
  // of the corner card shown (W.tarjeta: talk.board, + the view's x0) and of every face (PV.faces); if none is, [top].
  List<num> talkPlace(List<num> top, num h, Object? k, Map<String, dynamic> w) {
    if (!jsTruthy(k) || !sheet.bubbleRects.containsKey(k)) return top;
    final T = _talk, R = sheet.bubbleRects[k]!, x0 = host.cam[0];
    final faces = facesOf(w), boards = <List<num>>[];
    if (jsTruthy(w['tarjeta'])) boards.add([...T.boardRect!]);
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

  // banco-preview.html: PV.faces (sheet talk.faces). Every face shown: a person's [x - 6, top + 6, 12, 10], top their
  // sprite's first row (talk.heights; tired + 3, sad + 1); abuela's from her sprite; the frog's
  List<List<num>> facesOf(Map<String, dynamic> w) {
    final T = _talk, faces = <List<num>>[];
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final id = en.key, p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          (p['al'] != null && (p['al'] as num) < .5)) {
        continue;
      }
      final dy = _round(_n(p['dy'])), sent = jsTruthy(p['sent']);
      if (id == 'abuela') {
        final top = _round(p['y'] as num) - (sent ? 48 : 50) - dy,
            hX = sent
                ? _round(p['x'] as num)
                : _round(p['x'] as num) + (_dir(p) < 0 ? 6 : -6);
        faces.add([hX - 6, top + 6, 12, 10]);
        continue;
      }
      final h = T.heights['$id.${sent ? 1 : 0}']!,
          top =
              _round(p['y'] as num) -
              h +
              1 -
              dy +
              (p['animo'] == 'cansado'
                  ? 3
                  : p['animo'] == 'triste'
                  ? 1
                  : 0);
      faces.add([_round(p['x'] as num) - 6, top + 6, 12, 10]);
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

  // banco.js: talkAt (relative to the person: unchanged)
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final k = who;
    final p =
        (W['gente'] as Map<String, dynamic>?)?[k] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    return [
      _round(p['x'] as num),
      _round(p['y'] as num) - alto(k) - 1 - (jsTruthy(p['bub']) ? 38 : 0),
    ];
  }

  // banco.js: nota. A note of music; and the same note crossed out: not a sound
  void nota(Ctx g, num x, num y, [bool no = false]) {
    for (final k in [(OUT, 1), (hx('#2A3C8E'), 0)]) {
      final m = k.$2;
      void u(num a, num b, num w, num h) =>
          fr(g, x + a - m, y + b - m, w + 2 * m, h + 2 * m, k.$1);
      u(3, 0, 1, 10);
      u(11, 0, 1, 9);
      u(3, 0, 9, 2);
      u(0, 8, 4, 3);
      u(8, 7, 4, 3);
    }
    if (no) {
      for (var i = 0; i < 15; i++) {
        fr(g, x - 2 + i, y - 2 + i, 3, 2, hx('#D0302A'));
        fr(g, x + 12 - i, y - 2 + i, 3, 2, hx('#D0302A'));
      }
    }
  }

  // banco.js: respIcon. The doing bubbles: the frog eating, drinking, singing, keeping still. The thing is drawn big
  // beside him
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    final t = (F >> 2) % 2,
        op = (k == 'canta' || k == 'come') && t != 0 ? 1 : 0,
        im = spr('cq.6_0$op', () => mkCoqui(.6, 0, op != 0)),
        fx = x + 2,
        fy = y + h - im.h - 3;
    g.smoothing = false;
    g.drawImage(im, fx, fy);
    if (k == 'come') {
      g.save();
      g.translate((x + 28 - t).toDouble(), (y + 32).toDouble());
      g.scale(2, 2);
      tenida(g, 'piragua', 0, 0);
      g.restore();
    } else if (k == 'bebe') {
      g.save();
      g.translate((x + 31).toDouble(), (y + 31).toDouble());
      g.scale(2, 2);
      tenida(g, 'agua', 0, 0, -.75 - t * .15);
      g.restore();
    } else if (k == 'canta') {
      nota(g, x + 24, y + 5 - t * 2);
      g.fillStyle = hx('#2A3C8E');
      for (final q in const [
        [22, 24],
        [26, 27],
        [31, 23],
      ]) {
        g.fillRect(x + q[0], y + q[1] + t, 2, 2);
      }
    } else if (k == 'quieto') {
      nota(g, x + 24, y + 10, true);
    }
    return null;
  }

  /* ---------- the card in the corner: three rounds; a star, or a cross ---------- */

  // banco.js: hud
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (!jsTruthy(W['tarjeta'])) return;
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

  // banco.js: marca
  void marca(Object? m) {
    final l = W['marcas'] as List?;
    final i = l == null ? -1 : l.indexOf(null);
    if (i >= 0) l![i] = m;
  }

  /* ---------- moving things ---------- */

  // banco.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _round(_hypot(x - x0, y - y0) / 5));
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

  // banco.js: sienta (moves line 231: whoever sits down sits on the seat's edge at their x, SY). No act calls it.
  Future<void> sienta(String id, int i, [num? lado]) async {
    final q = BANCOS[i], p = G(id)!;
    final x = q[0] + _n(lado) * 10;
    await mueve(id, x, SY(x));
    p['sent'] = 1;
    p['dir'] = 1;
  }

  // banco.js: palomaA (sheet helps.lines: it keeps the ground under it, o.gs)
  Future<void> palomaA(
    Map<String, dynamic> o,
    num x,
    num y, [
    num? pasos0,
  ]) async {
    final x0 = o['x'] as num, y0 = o['y'] as num;
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(5, _round(_hypot(x - x0, y - y0) / 9));
    o['pose'] = 'vuela';
    o['z'] = 400;
    if ((x - x0).abs() > 3) o['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= pasos; i++) {
      final t = i / pasos;
      o['x'] = x0 + (x - x0) * t;
      o['y'] = y0 + (y - y0) * t - math.sin(math.pi * t) * 8;
      o['gs'] = GS(x0, y0, x, y, t);
      await wait(TICK);
    }
    o['x'] = x;
    o['y'] = y;
    o['pose'] = '';
    o['gs'] = null;
  }

  // banco.js: perroA
  Future<void> perroA(
    String n,
    num x,
    num y, [
    String? pose0,
    num? pasos0,
  ]) async {
    final o = _perros[n] as Map<String, dynamic>?;
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num, fin = o['pose'];
    final pose = jsTruthy(pose0) ? pose0! : 'walk';
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(
            4,
            _round(
              _hypot(x - x0, y - y0) /
                  (pose == 'run'
                      ? 8
                      : n == 'viejo'
                      ? 2
                      : 4),
            ),
          );
    o['pose'] = pose;
    if ((x - x0).abs() > 3) o['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= pasos; i++) {
      o['x'] = x0 + (x - x0) * i / pasos;
      o['y'] = y0 + (y - y0) * i / pasos;
      await wait(TICK);
    }
    o['x'] = x;
    o['y'] = y;
    o['pose'] = fin == 'walk' || fin == 'run' ? 'idle' : fin;
  }

  // banco.js: pio
  void pio() {
    tone(1500, 0, .05, 'sine', .04, 1900);
    tone(1300, .07, .05, 'sine', .04, 1700);
  }

  // banco.js: ladra
  void ladra([num? n]) {
    for (var k = 0; k < _or(n, 1); k++) {
      tone(520, k * .26, .07, 'square', .05, 300);
      tone(400, k * .26 + .07, .1, 'square', .05, 240);
    }
  }

  /* ---------- helpers for the stories ---------- */

  // banco.js: cx, pies
  num cx() => (_cq['x'] as num) + 16;
  num pies() => (_cq['y'] as num) + 27;

  // banco.js: ranaA
  Future<void> ranaA(num x, num y, [num? h]) async {
    final q = _cq,
        d = _hypot(x - 16 - (q['x'] as num), y - 27 - (q['y'] as num));
    if (d < 3) return;
    await hopTo(
      _round(x - 16),
      _round(y - 27),
      (h != null && h != 0 ? h : math.max(1, math.min(4, _round(d / 34))))
          .toInt(),
    );
  }

  // banco.js: acasa
  Future<void> acasa() {
    final casa = W['casa'] as List;
    return ranaA(casa[0] as num, casa[1] as num);
  }

  // banco.js: carmenDa. She walks over and hands it to him
  Future<void> carmenDa(void Function() f) async {
    final ca = G('carmen')!, x0 = ca['x'] as num, y0 = ca['y'] as num;
    await mueve('carmen', cx() - 30, pies() + 1);
    ca['dir'] = 1;
    ca['pose'] = 'offer';
    await wait(250);
    f();
    SFX.blip();
    await wait(300);
    ca['pose'] = 'idle';
    await mueve('carmen', x0, y0);
    ca['dir'] = 1;
  }

  // banco.js: cosaDe
  Map<String, dynamic>? cosaDe(String id) {
    for (final o in (W['cosas'] as List?) ?? const []) {
      if ((o as Map)['id'] == id) return o as Map<String, dynamic>;
    }
    return null;
  }

  // banco.js: quita
  void quita(String id) {
    W['cosas'] = <dynamic>[
      for (final o in (W['cosas'] as List?) ?? const [])
        if ((o as Map)['id'] != id) o,
    ];
  }

  // banco.js: libre
  Map<String, dynamic>? libre() {
    for (final o in _palomas) {
      if ((o as Map)['en'] == 'cable') return o as Map<String, dynamic>;
    }
    return null;
  }

  // banco.js: alcable
  Future<void> alcable(Map<String, dynamic> o) async {
    final p = CABLE((o['i'] as num).toInt());
    await palomaA(o, p[0], p[1]);
    o['en'] = 'cable';
    o['z'] = null;
    o['dir'] = (o['i'] as num) % 2 != 0 ? 1 : -1;
  }

  // banco.js: posa (moves line 238: POSA)
  Future<void> posa(Map<String, dynamic> o) async {
    final p = POSA[math.min(3, _n(W['posadas']).toInt())];
    W['posadas'] = _n(W['posadas']) + 1;
    await palomaA(o, p[0], p[1]);
    o['en'] = 'banco';
    o['z'] = 140;
    o['dir'] = -1;
  }

  // banco.js: niega
  Future<void> niega(Map<String, dynamic> p) async {
    for (var k = 0; k < 4; k++) {
      p['dir'] = -(p['dir'] as num);
      await wait(150);
    }
  }

  // banco.js: perroDe
  Map<String, dynamic> perroDe(String a) =>
      _perros[a == 'perro' ? 'canelo' : a.replaceFirst('perro_', '')]
          as Map<String, dynamic>;

  // banco.js: llanto, risa, sollozo, gime, grune, coquiS, palmas
  void llanto() {
    for (final t in const [0, .24, .48]) {
      tone(760, t, .2, 'triangle', .07, 520);
    }
  }

  void risa() {
    const ts = [0, .12, .24, .36];
    for (var i = 0; i < ts.length; i++) {
      tone(420 + (i % 2) * 90, ts[i], .09, 'square', .05, 380);
    }
  }

  void sollozo() {
    for (final t in const [0, .3]) {
      tone(330, t, .24, 'sine', .08, 240);
    }
  }

  void gime() => tone(620, 0, .45, 'sine', .07, 860);

  void grune() => tone(120, 0, .45, 'sawtooth', .05, 90);

  void coquiS() {
    for (final t in const [0, .5]) {
      tone(1400, t, .09, 'sine', .025, 1500);
      tone(2100, t + .12, .14, 'sine', .025, 2500);
    }
  }

  void palmas() {
    for (final t in const [0, .14]) {
      tone(900, t, .04, 'square', .06, 500);
    }
  }

  // banco.js: despierta (moves line 238: JUGEN)
  Future<void> despierta() async {
    final o = W['coche'] as Map<String, dynamic>,
        n = _n(W['juguetes']).toInt(),
        k = JUG[math.min(3, n)],
        d = JUGEN[math.min(3, n)];
    o['bebe'] = 'llora';
    o['tiembla'] = 1;
    o['mano'] = 0;
    llanto();
    await wait(350);
    final t = <String, dynamic>{
      'id': 'jug$n',
      'k': k,
      'x': o['x'],
      'y': (o['y'] as num) - 30,
      'z': 400,
    };
    (W['cosas'] as List).add(t);
    W['juguetes'] = n + 1;
    for (var i = 1; i <= 8; i++) {
      final u = i / 8, ox = o['x'] as num, oy = o['y'] as num;
      t['x'] = ox + (d[0] - ox) * u;
      t['y'] = oy - 30 + (d[1] - oy + 30) * u - math.sin(math.pi * u) * 16;
      await wait(TICK);
    }
    t['x'] = d[0];
    t['y'] = d[1];
    t['z'] = null;
    SFX.bonk();
    await wait(450);
  }

  // banco.js: mece
  Future<void> mece() async {
    final o = W['coche'] as Map<String, dynamic>;
    o['tiembla'] = 0;
    o['mece'] = 1;
    await wait(1500);
    o['mece'] = 0;
    o['bebe'] = 'duerme';
    await wait(300);
  }

  // DECISION(order 32b, as El patio's, El camino's, El campo's and El lago's): a position an act reads from the story
  // file (`o.x`, `o.y`: acts.anda, acts.rana, acts.can, acts.pal, acts.cosa, acts.rueda) goes through the sheet's remap,
  // as the runner sends a set step's x and y (page 12, section 5: every position a story file holds; the sheet's remap
  // lists these uses, d-vamos-a-casa's ways out through the gate the ones that move)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  Future<void> _act(String k, Map<String, dynamic> o) => acts[k]!(o);

  // JavaScript: `SFX[name]()` (acts.cosa's `son`): juego.js's sounds by name
  void _sfx(String name) {
    switch (name) {
      case 'right':
        return SFX.right();
      case 'toc':
        return SFX.toc();
      case 'blip':
        return SFX.blip();
      case 'creak':
        return SFX.creak();
      case 'hop':
        return SFX.hop();
      case 'coqui':
        return SFX.coqui();
      case 'win':
        return SFX.win();
      case 'luz':
        return SFX.luz();
      case 'drop':
        return SFX.drop();
      case 'trueno':
        return SFX.trueno();
      case 'lluvia':
        return SFX.lluvia();
      case 'calla':
        return SFX.calla();
      case 'suave':
        return SFX.suave();
      case 'pio':
        return SFX.pio();
      case 'slam':
        return SFX.slam();
      case 'bonk':
        return SFX.bonk();
      case 'munch':
        return SFX.munch();
      case 'swoop':
        return SFX.swoop();
    }
  }

  // A sitter's place as the sheet's move at [line] seats them: x = B[i][0] + d, y = SY(x) (banco_places seat)
  Map<String, dynamic> _seat(int line, String who) {
    final s = _p.seat(line, who), x = B[s.bench][0] + s.dx;
    return <String, dynamic>{'x': x, 'y': SY(x)};
  }

  // banco.js: `[0,1,2,3,4].map(i=>({i,x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1,en:"cable"}))`, the pigeons on the wire
  List<dynamic> _cable() => <dynamic>[
    for (var i = 0; i < 5; i++)
      <String, dynamic>{
        'i': i,
        'x': CABLE(i)[0],
        'y': CABLE(i)[1],
        'dir': i % 2 != 0 ? 1 : -1,
        'en': 'cable',
      },
  ];

  // moves lines 322, 325, 332, 333, 334 (and 315): whoever leaves walks to PORTON[1] + 12, out along the path
  late final num _out12 = _p.to(
    322,
    '246,PORTON[1])',
    RegExp(r'\d+,PORTON\[1\]\+(\d+)\)'),
  )[0];

  // banco.js:399 acts.sale: the frog leaves through the gate (PORTON) and off the picture (the later of the two acts of
  // that name, the one the old game ran: the one at :291, the pigeon flying off with what it took, never ran)
  Future<void> _saleFrog() async {
    final q = _cq;
    await ranaA(PORTON[0] + 4, PORTON[1] + 2);
    await ranaA(_p.keep(399, 236), PORTON[1] + 2, 2);
    q['vis'] = 0;
  }

  // banco.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'pose': (o) async {
      final p = G('${o['quien']}');
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

    /* ----- story 21: La piragua ----- */
    // moves line 267: the three on the benches sit on the seats' edges (SY); code lines 267, 268: every other place the
    // floor rule's
    'inicio21': (o) async {
      final ca = _p.floor(267, 62, 206);
      W['gente'] = <String, dynamic>{
        'piraguero': <String, dynamic>{
          'x': CARRO[0] + 4,
          'y': CARRO[1] - 6,
          'dir': 1,
        },
        'carmen': <String, dynamic>{'x': ca[0], 'y': ca[1], 'dir': 1},
        'hombre': <String, dynamic>{
          ..._seat(267, 'hombre'),
          'dir': 1,
          'sent': 1,
        },
        'mujer': <String, dynamic>{..._seat(267, 'mujer'), 'dir': 1, 'sent': 1},
        'luis': <String, dynamic>{..._seat(267, 'luis'), 'dir': 1, 'sent': 1},
      };
      W['palomas'] = _cable();
      final casa = _p.floor(268, 124, 206);
      W['casa'] = casa;
      _cq
        ..['x'] = casa[0] - 16
        ..['y'] = casa[1] - 27
        ..['s'] = 1;
      W['bandeja'] = 1;
      W['posadas'] = 0;
      W['cosas'] = <dynamic>[];
    },
    'pon': (o) async {
      final de = G(jsTruthy(o['de']) ? o['de'] as String : 'carmen')!;
      await acasa();
      de['pose'] = 'offer';
      await wait(250);
      W['bandeja'] = o['k'];
      SFX.blip();
      await wait(300);
      de['pose'] = 'idle';
    },
    'lleva': (o) async {
      final p = G(o['a'] as String)!, k = W['bandeja'];
      final sent = jsTruthy(p['sent']);
      await ranaA(
        sent ? p['x'] as num : (p['x'] as num) + 26,
        sent ? (p['y'] as num) + 22 : p['y'] as num,
      );
      W['bandeja'] = 1;
      p['que'] = k;
      p['hace'] = k == 'agua' ? 'bebe' : 'come';
      SFX.blip();
      await wait(500);
    },
    'llevamal': (o) async {
      final p = G(o['a'] as String)!;
      final sent = jsTruthy(p['sent']);
      await ranaA(
        sent ? p['x'] as num : (p['x'] as num) + 26,
        sent ? (p['y'] as num) + 22 : p['y'] as num,
      );
      await niega(p);
      p['dir'] = 1;
      _cq['dy'] = -4;
      await wait(300);
      final pg = libre()!;
      pio();
      await palomaA(pg, cx(), pies() - 30);
      pg['pose'] = 'come';
      pg['z'] = 400;
      await wait(900);
      W['bandeja'] = 1;
      pg['pose'] = '';
      _cq['dy'] = 0;
      await posa(pg);
    },
    // moves line 272: the piragua and the bottle left on the seats (AS)
    'dejan': (o) async {
      final h = G('hombre')!, m = G('mujer')!;
      h['hace'] = null;
      h['lleva'] = null;
      h['lee'] = 1;
      m['hace'] = null;
      m['lleva'] = null;
      m['dir'] = -1;
      final d = _p.to(
        272,
        '{id:"pir",k:"piragua",x:101,y:ASIENTO-4,rot:Math.PI/2},{id:"bot",k:"agua",x:153,y:ASIENTO}',
        RegExp(r'x:(\d+),y:AS\(\d+\)-(\d+),.*x:(\d+),y:AS'),
      );
      (W['cosas'] as List).addAll([
        <String, dynamic>{
          'id': 'pir',
          'k': 'piragua',
          'x': d[0],
          'y': AS(d[0]) - d[1],
          'rot': math.pi / 2,
        },
        <String, dynamic>{'id': 'bot', 'k': 'agua', 'x': d[2], 'y': AS(d[2])},
      ]);
      await wait(500);
    },
    'nuevas': (o) async {
      final ca = G('carmen')!;
      final a = _p.floor(273, 104, 182),
          b = _p.floor(273, 150, 182),
          c = _p.floor(273, 62, 206);
      await mueve('carmen', a[0], a[1]);
      G('hombre')!['hace'] = 'come';
      G('hombre')!['que'] = 'piragua';
      SFX.blip();
      await wait(250);
      await mueve('carmen', b[0], b[1]);
      G('mujer')!['hace'] = 'bebe';
      SFX.blip();
      await wait(250);
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = 1;
      await wait(500);
    },
    // moves line 274: the pigeon lands on the seat by the piragua, or by the bottle (AS)
    'paloma': (o) async {
      final pg = libre()!;
      W['ladrona'] = pg;
      pio();
      if (o['k'] == 'come') {
        final x = _p.to(274, 'await palomaA(pg,119,ASIENTO);')[0];
        await palomaA(pg, x, AS(x));
        pg['dir'] = -1;
        pg['pose'] = 'come';
      } else {
        final x = _p.to(274, 'await palomaA(pg,163,ASIENTO);')[0];
        await palomaA(pg, x, AS(x));
        pg['dir'] = -1;
        pg['pose'] = 'bebe';
      }
      pg['z'] = _p.keep(274, 152);
      await wait(700);
    },
    'salva': (o) async {
      final come = o['k'] == 'come',
          p = G(come ? 'hombre' : 'mujer')!,
          pg = W['ladrona'] as Map<String, dynamic>?;
      if (come) {
        p['lee'] = 0;
        quita('pir');
        p['lleva'] = 'piragua';
      } else {
        p['dir'] = 1;
        quita('bot');
        p['lleva'] = 'agua';
      }
      SFX.blip();
      p['dy'] = 3;
      await wait(150);
      p['dy'] = 0;
      if (pg != null) {
        pg['pose'] = '';
        if (jsTruthy(o['medio'])) {
          await posa(pg);
        } else {
          await alcable(pg);
        }
      }
      W['ladrona'] = null;
      await wait(250);
    },
    'miraotra': (o) async {
      final come = o['k'] == 'come', p = G(come ? 'mujer' : 'hombre')!;
      if (come) {
        quita('bot');
        p['lleva'] = 'agua';
      } else {
        p['lee'] = 0;
        quita('pir');
        p['lleva'] = 'piragua';
      }
      SFX.blip();
      await niega(p);
      p['dir'] = 1;
      await wait(300);
    },
    'acaban': (o) async {
      final h = G('hombre')!, m = G('mujer')!, ca = G('carmen')!;
      if (cosaDe('pir') != null) quita('pir');
      if (cosaDe('bot') != null) quita('bot');
      h['lee'] = 0;
      h['lleva'] = null;
      m['lleva'] = null;
      m['dir'] = 1;
      h['hace'] = 'come';
      h['que'] = 'piragua';
      m['hace'] = 'bebe';
      await wait(900);
      h['hace'] = null;
      m['hace'] = null;
      h['lleva'] = 'papel';
      m['lleva'] = 'vacia';
      final a = _p.floor(278, 104, 182),
          b = _p.floor(278, 150, 182),
          c = _p.floor(278, 62, 206);
      await mueve('carmen', a[0], a[1]);
      h['lleva'] = null;
      await mueve('carmen', b[0], b[1]);
      m['lleva'] = null;
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = 1;
      W['bandeja'] = o['bandeja'] == 'no' ? null : 1;
      await wait(200);
    },
    'sinbandeja': (o) async {
      W['bandeja'] = null;
      await wait(150);
    },
    'llena': (o) async {
      final m =
          (W['manos'] as Map<String, dynamic>?) ??
          <String, dynamic>{'i': null, 'd': null};
      bool vale(Object? k) =>
          jsTruthy(k) && (k == 'agua' || _starts(k, 'piragua'));
      bool hay(String k) => const ['i', 'd'].any(
        (q) =>
            vale(m[q]) &&
            (k == 'agua' ? m[q] == 'agua' : _starts(m[q], 'piragua')),
      );
      final falta = [
        for (final k in const ['piragua', 'agua'])
          if (!hay(k)) k,
      ];
      await carmenDa(() {
        for (final q in const ['i', 'd']) {
          if (!vale(m[q])) m[q] = falta.isNotEmpty ? falta.removeAt(0) : null;
        }
        W['manos'] = m;
      });
    },
    'acaba': (o) async {
      final p = G(o['a'] as String)!;
      p['hace'] = p['lleva'] == 'agua' ? 'bebe' : 'come';
      p['que'] = p['lleva'] == 'agua' ? 'agua' : 'piragua';
      p['lleva'] = null;
      await wait(900);
      p['hace'] = null;
    },
    'tragan': (o) async {
      for (final p in (W['gente'] as Map<String, dynamic>).values) {
        (p as Map)['hace'] = null;
        p['lleva'] = null;
      }
      await wait(200);
    },
    'empieza': (o) async {
      final q = _cq;
      q['hace'] = o['que'];
      if (o['que'] == 'come') {
        for (final t in const [0, .2, .4]) {
          tone(300, t, .05, 'square', .03, 240);
        }
      } else {
        for (final t in const [0, .25, .5]) {
          tone(500, t, .08, 'sine', .04, 380);
        }
      }
      await wait(650);
    },
    'termina': (o) async {
      final q = _cq,
          m = (W['manos'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      await wait(350);
      for (final s in const ['i', 'd']) {
        if (o['que'] == 'come' && jsTruthy(m[s]) && _starts(m[s], 'piragua')) {
          m[s] = 'papel';
        }
        if (o['que'] == 'bebe' && m[s] == 'agua') m[s] = 'vacia';
      }
      q['hace'] = null;
      await wait(250);
    },
    'otro': (o) async {
      final que = o['que'] == 'come' ? 'bebe' : 'come',
          m = (W['manos'] as Map<String, dynamic>?) ?? const {},
          cual = que == 'come' ? 'piragua' : 'agua';
      if (!const ['i', 'd'].any((q) => jsTruthy(m[q]) && _starts(m[q], cual))) {
        return;
      }
      await _act('empieza', {'que': que});
      await _act('termina', {'que': que});
    },
    'repone': (o) async {
      final m = (W['manos'] as Map<String, dynamic>?) ?? <String, dynamic>{},
          cual = o['que'] == 'come' ? 'piragua' : 'agua';
      String? l;
      for (final q in const ['i', 'd']) {
        if (!jsTruthy(m[q]) ||
            m[q] == 'papel' && cual == 'piragua' ||
            m[q] == null) {
          l = q;
          break;
        }
      }
      if (l == null) {
        for (final q in const ['i', 'd']) {
          if (m[q] == 'papel' || m[q] == 'vacia') {
            l = q;
            break;
          }
        }
      }
      await carmenDa(() {
        for (final q in const ['i', 'd']) {
          if (m[q] == 'papel' || m[q] == 'vacia') m[q] = null;
        }
        m[l ?? 'i'] = cual;
        W['manos'] = m;
      });
    },
    'limpia': (o) async {
      W['manos'] = null;
      await wait(200);
    },
    'turno21': (o) async {
      final q = _cq,
          m = W['manos'] as Map<String, dynamic>,
          s = jsTruthy(m['i']) && _starts(m['i'], 'piragua') ? -1 : 1,
          pg = libre()!;
      q['dy'] = -5;
      await wait(500);
      pio();
      await palomaA(pg, cx() + s * 17, pies() - 9);
      pg['pose'] = 'come';
      pg['z'] = 400;
      pg['dir'] = -s;
      await wait(1100);
      m[s < 0 ? 'i' : 'd'] = 'papel';
      q['dy'] = 0;
      pg['pose'] = '';
      SFX.bonk();
      await wait(400);
      await posa(pg);
      await wait(300);
    },
    // behind him, dead centre: only the top of it shows
    'acecha': (o) async {
      final pg = libre()!;
      W['ladrona'] = pg;
      pio();
      await palomaA(pg, cx() - 3, (_cq['y'] as num) + 9);
      pg['pose'] = '';
      pg['dir'] = 1;
      pg['z'] = (_cq['y'] as num) + 10;
      await wait(500);
    },
    // banco.js:291 acts.sale (the pigeon flies off, or eats what he holds) is replaced by the act of the same name at
    // :399 (the later wins in the object literal): the frog leaves through the gate
    'sale': (o) async {
      await _saleFrog();
    },
    'final21': (o) async {
      final n = _n(W['posadas']), ca = G('carmen')!, q = _cq;
      // moves line 296: Carmen comes to the frog's right 10 px nearer (cx() + 36)
      final dx = _p.to(296, 'cx()+46,pies()+2', RegExp(r'cx\(\)\+(\d+)'))[0];
      await acasa();
      await mueve('carmen', cx() + dx, pies() + 2);
      ca['dir'] = -1;
      ca['pose'] = 'offer';
      await wait(300);
      W['manos'] = <String, dynamic>{'i': n <= 1 ? 'piragua3' : 'piragua'};
      ca['pose'] = 'idle';
      ca['hace'] = 'bebe';
      SFX.blip();
      q['hace'] = 'come';
      if (n >= 4) {
        const en = [
          [-34, 2],
          [-22, 12],
          [26, 14],
          [44, -6],
        ];
        final enBanco = [
          for (final o in _palomas)
            if ((o as Map)['en'] == 'banco') o as Map<String, dynamic>,
        ];
        await Future.wait([
          for (var i = 0; i < enBanco.length; i++)
            palomaA(
              enBanco[i],
              cx() + en[i % 4][0],
              pies() + en[i % 4][1],
            ).then((_) {
              enBanco[i]['dir'] = en[i % 4][0] < 0 ? 1 : -1;
              enBanco[i]['z'] = null;
            }),
        ]);
      }
      await wait(400);
    },
    'quiere': (o) async {
      Map<String, dynamic>? pg;
      for (final p in _palomas) {
        if ((p as Map)['en'] == 'banco') {
          pg = p as Map<String, dynamic>;
          break;
        }
      }
      if (pg != null) {
        pio();
        pg['dy'] = 2;
        await wait(200);
        pg['x'] = (pg['x'] as num) + (pg['dir'] as num) * 3;
        await wait(300);
      }
    },
    'fin21': (o) async {
      _cq['hace'] = null;
      G('carmen')!['hace'] = null;
      await wait(300);
    },

    /* ----- story 22: ¡Señor! ¡Señora! ----- */
    // moves lines 302 to 305: the four on the benches (SY), Carmen beyond the gate, Luis by the box (moved 14 px right
    // with the frog's home), the handbag and the rucksack on the seats (AS), the box, the two dogs, the frog's home; code
    // lines 302 to 305: every other place the floor rule's
    'inicio22': (o) async {
      final ca = _p.to(302, 'carmen:{x:176,y:208,dir:-1}'),
          lu = _p.to(302, 'luis:{x:148,y:186,dir:1}');
      W['gente'] = <String, dynamic>{
        'piraguero': <String, dynamic>{
          'x': CARRO[0] + 4,
          'y': CARRO[1] - 6,
          'dir': 1,
        },
        'senor': <String, dynamic>{..._seat(302, 'senor'), 'dir': 1, 'sent': 1},
        'mujer': <String, dynamic>{..._seat(302, 'mujer'), 'dir': 1, 'sent': 1},
        'joven': <String, dynamic>{
          ..._seat(302, 'joven'),
          'dir': 1,
          'sent': 1,
          'sin': <String, dynamic>{'mochila': 1},
        },
        'hombre': <String, dynamic>{
          ..._seat(302, 'hombre'),
          'dir': 1,
          'sent': 1,
          'lee': 1,
        },
        'carmen': <String, dynamic>{'x': ca[0], 'y': ca[1], 'dir': -1},
        'luis': <String, dynamic>{'x': lu[0], 'y': lu[1], 'dir': 1},
      };
      final so = _p.floor(303, 72, 163),
          cm = _p.to(
            303,
            '{id:"cartera",k:"cartera",x:157,y:ASIENTO},{id:"mochila",k:"mochila",x:204,y:ASIENTO+1}',
            RegExp(r'x:(\d+),y:AS\(\d+\)\},.*x:(\d+),y:AS\(\d+\)\+(\d+)\}'),
          ),
          cj = _p.to(303, '{id:"caja",k:"caja",x:167,y:187}');
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'id': 'sombrilla',
          'k': 'sombrilla',
          'x': so[0],
          'y': so[1],
        },
        <String, dynamic>{
          'id': 'cartera',
          'k': 'cartera',
          'x': cm[0],
          'y': AS(cm[0]),
        },
        <String, dynamic>{
          'id': 'mochila',
          'k': 'mochila',
          'x': cm[1],
          'y': AS(cm[1]) + cm[2],
        },
        <String, dynamic>{'id': 'caja', 'k': 'caja', 'x': cj[0], 'y': cj[1]},
      ];
      W['encaja'] = <dynamic>[];
      final pv = _p.to(
        304,
        'W.perros={viejo:{x:90,y:193,pose:"sit",dir:1},joven:{x:38,y:193,pose:"sit",dir:1}}',
        RegExp(r'viejo:\{x:(\d+),y:(\d+),.*joven:\{x:(\d+),y:(\d+),'),
      );
      W['perros'] = <String, dynamic>{
        'viejo': <String, dynamic>{
          'x': pv[0],
          'y': pv[1],
          'pose': 'sit',
          'dir': 1,
        },
        'joven': <String, dynamic>{
          'x': pv[2],
          'y': pv[3],
          'pose': 'sit',
          'dir': 1,
        },
      };
      W['palomas'] = _cable();
      final casa = _p.to(
        305,
        'W.casa=[124,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;',
        RegExp(r'W\.casa=\[(\d+),(\d+)\]'),
      );
      W['casa'] = [casa[0], casa[1]];
      _cq
        ..['x'] = casa[0] - 16
        ..['y'] = casa[1] - 27
        ..['s'] = 1;
      W['tarde'] = 1;
      W['fuera'] = null;
      W['sinhueso'] = null;
    },
    // moves line 306: the three queue at the cart nearer
    'alcarro': (o) async {
      final en = _p.to(
        306,
        'const en={senor:[80,184],mujer:[96,188],joven:[112,184]}',
      );
      final at = {
        'senor': [en[0], en[1]],
        'mujer': [en[2], en[3]],
        'joven': [en[4], en[5]],
      };
      await Future.wait([
        for (final id in at.keys)
          () async {
            await mueve(id, at[id]![0], at[id]![1]);
            G(id)!['dir'] = -1;
          }(),
      ]);
      await wait(400);
    },
    'vuelve22': (o) async {
      final id = o['a'] as String,
          p = G(id)!,
          i = const {'senor': 0, 'mujer': 1, 'joven': 2}[id]!;
      p['dir'] = 1;
      await wait(350);
      await mueve(id, B[i][0] - 9, _p.keep(307, 172));
      if (id == 'joven') {
        p['sin'] = <String, dynamic>{};
        quita('mochila');
      } else if (id == 'senor') {
        quita('sombrilla');
        p['lleva2'] = 'sombrilla';
      } else {
        quita('cartera');
        p['lleva2'] = 'cartera';
      }
      SFX.blip();
      p['dy'] = 3;
      await wait(160);
      p['dy'] = 0;
      await wait(250);
    },
    // moves line 308: they sit down again on the seats' edges (SY)
    'sientan': (o) async {
      await Future.wait([
        for (final k in const [
          ['senor', 0, -9, 'piragua'],
          ['mujer', 1, -9, 'agua'],
          ['joven', 2, -9, 'piragua'],
        ])
          () async {
            final p = G(k[0] as String)!;
            final x = B[k[1] as int][0] + (k[2] as int);
            await mueve(k[0] as String, x, SY(x));
            p['sent'] = 1;
            p['dir'] = 1;
            p['lleva'] = k[3];
          }(),
      ]);
      await wait(300);
    },
    // moves lines 309 and 311: where Carmen hands the bag and the bone
    'bolsa': (o) async {
      final a = _p.floor(309, 122, 174),
          b = _p.to(309, 'mueve("carmen",158,210)');
      await mueve('carmen', a[0], a[1]);
      G('carmen')!['lleva'] = 'bolsa';
      SFX.blip();
      await mueve('carmen', b[0], b[1]);
      G('carmen')!['dir'] = -1;
      G('carmen')!['pose'] = 'arriba';
      await wait(300);
    },
    'dabolsa': (o) async {
      final p = G(o['a'] as String)!, ca = G('carmen')!;
      final sent = jsTruthy(p['sent']);
      ca['lleva'] = null;
      ca['pose'] = 'idle';
      W['encima'] = 'bolsa';
      SFX.blip();
      await ranaA(
        sent ? p['x'] as num : (p['x'] as num) + 2,
        sent ? (p['y'] as num) + 22 : (p['y'] as num) + 25,
      );
      if (jsTruthy(o['no'])) {
        await niega(p);
        p['dir'] = jsTruthy(p['sent']) ? 1 : -1;
        return;
      }
      W['encima'] = null;
      p['lleva'] = 'bolsa';
      SFX.blip();
      await wait(400);
    },
    'hueso': (o) async {
      final ca = G('carmen')!;
      final a = _p.floor(311, 146, 176),
          b = _p.to(311, 'mueve("carmen",158,210)');
      await mueve('carmen', a[0], a[1]);
      ca['lleva'] = 'hueso';
      SFX.blip();
      await mueve('carmen', b[0], b[1]);
      ca['dir'] = -1;
      await acasa();
      ca['lleva'] = null;
      W['encima'] = 'hueso';
      SFX.blip();
      await wait(300);
    },
    'dahueso': (o) async {
      final d = perroDe(o['a'] as String);
      await ranaA((d['x'] as num) + 30, (d['y'] as num) + 4);
      W['encima'] = null;
      d['lleva'] = 'hueso';
      d['pose'] = jsTruthy(o['echa']) ? 'lie' : 'come';
      SFX.blip();
      await wait(500);
    },
    'ronda': (o) async {
      final d = _perros['joven'] as Map<String, dynamic>;
      d['ronda'] = jsTruthy(o['fin']) ? 0 : 1;
      if (jsTruthy(o['fin'])) {
        d['pose'] = 'come';
        d['x'] = d['x0'];
        d['dir'] = 1;
      } else {
        d['x0'] = d['x'];
        d['pose'] = 'run';
        d['fase'] = F;
      }
      await wait(200);
    },
    'paseo': (o) async {
      final d = _perros['viejo'] as Map<String, dynamic>;
      d['paseo'] = jsTruthy(o['fin']) ? 0 : 1;
      if (jsTruthy(o['fin'])) {
        d['pose'] = 'sit';
        d['x'] = d['x0'];
        d['dir'] = 1;
      } else {
        d['x0'] = d['x'];
        d['pose'] = 'walk';
        d['fase'] = F;
      }
      await wait(200);
    },
    // moves line 315: the newspaper left on the seat (AS); the way out through the gate (PORTON[1] + 12)
    'turno22': (o) async {
      final h = G('hombre')!;
      h['lee'] = 0;
      final x = _p.to(
        315,
        '{id:"periodico",k:"periodico",x:108,y:ASIENTO}',
        RegExp(r'x:(\d+),y:AS'),
      )[0];
      (W['cosas'] as List).add(<String, dynamic>{
        'id': 'periodico',
        'k': 'periodico',
        'x': x,
        'y': AS(x),
      });
      await wait(400);
      final out = _p.to(
        315,
        '244,PORTON[1])',
        RegExp(r'(\d+),PORTON\[1\]\+(\d+)\)'),
      );
      await mueve('hombre', PORTON[0], PORTON[1]);
      await mueve('hombre', out[0], PORTON[1] + out[1]);
      h['vis'] = 0;
      await wait(300);
    },
    'luisve': (o) async {
      final l = G('luis')!;
      l['dir'] = 1;
      await wait(300);
      final a = _p.floor(316, 112, 178);
      await mueve('luis', a[0], a[1]);
      quita('periodico');
      l['lleva'] = 'periodico';
      await mueve('luis', PORTON[0] - 4, PORTON[1] + 2);
      l['dir'] = 1;
      l['pose'] = 'arriba';
      await wait(200);
    },
    // moves lines 317 and 326: Luis back to his place by the box (moved, inicio22)
    'luiscaja': (o) async {
      final l = G('luis')!;
      l['pose'] = 'idle';
      for (var k = 0; k < 3; k++) {
        l['dir'] = -(l['dir'] as num);
        await wait(160);
      }
      final b = _p.to(317, 'mueve("luis",148,186)');
      await mueve('luis', b[0], b[1]);
      l['dir'] = 1;
      l['lleva'] = null;
      (W['encaja'] as List).add('periodico');
      SFX.blip();
      await wait(300);
    },
    // moves line 318: the dogs move aside to the left, the frog's home with them
    'sale22': (o) async {
      final p = G(o['a'] as String)!,
          v = _perros['viejo'] as Map<String, dynamic>,
          j = _perros['joven'] as Map<String, dynamic>;
      v['lleva'] = null;
      j['lleva'] = null;
      final pd = _p.to(
        318,
        'perroA("viejo",36,193,"walk"),perroA("joven",64,194,"run")',
      );
      await Future.wait([
        perroA('viejo', pd[0], pd[1], 'walk'),
        perroA('joven', pd[2], pd[3], 'run'),
      ]);
      v['pose'] = 'sit';
      j['pose'] = 'sit';
      v['dir'] = 1;
      j['dir'] = 1;
      final casa = _p.to(318, 'W.casa=[100,205];');
      W['casa'] = [casa[0], casa[1]];
      await acasa();
      p['lleva'] = null;
      p['sent'] = 0;
      await mueve(o['a'] as String, (p['x'] as num) + 4, _p.keep(319, 176));
      final t = <String, dynamic>{
        'id': 'billetera',
        'k': 'billetera',
        'x': (p['x'] as num) - 8,
        'y': (p['y'] as num) - 22,
        'z': 400,
      };
      (W['cosas'] as List).add(t);
      for (var i = 1; i <= 6; i++) {
        t['y'] = (p['y'] as num) - 22 + 26 * i / 6;
        await wait(TICK);
      }
      t['y'] = (p['y'] as num) + 4;
      t['z'] = null;
      SFX.bonk();
      t['y'] = (t['y'] as num) - 3;
      await wait(90);
      t['y'] = (t['y'] as num) + 3;
      await wait(350); // it drops from a pocket, in plain sight
      await mueve(o['a'] as String, PORTON[0], PORTON[1]);
      p['dir'] = 1;
      W['fuera'] = o['a'];
      await wait(300);
    },
    'recoge': (o) async {
      final p = G(o['a'] as String)!, t = cosaDe('billetera')!;
      p['dir'] = -1;
      await wait(300);
      await mueve(o['a'] as String, (t['x'] as num) + 10, (t['y'] as num) + 2);
      quita('billetera');
      SFX.blip();
      p['dy'] = 3;
      await wait(160);
      p['dy'] = 0;
      await wait(200);
    },
    // moves line 322: out through the gate's opening along the path (PORTON[1] + 12)
    'adios': (o) async {
      final p = G(o['a'] as String)!;
      p['dir'] = -1;
      p['pose'] = 'wave';
      await wait(600);
      p['pose'] = 'idle';
      await mueve(o['a'] as String, PORTON[0], PORTON[1]);
      await mueve(o['a'] as String, _p.keep(322, 246), PORTON[1] + _out12);
      p['vis'] = 0;
    },
    // moves line 323: who walks through the gate stops just beyond it on the path
    'pasa': (o) async {
      final p = G(o['a'] as String)!;
      final d = _p.to(
        323,
        'await mueve(o.a,PORTON[0]+8,PORTON[1]);',
        RegExp(r'PORTON\[0\]-(\d+),PORTON\[1\]\+(\d+)\)'),
      );
      await mueve(o['a'] as String, PORTON[0], PORTON[1]);
      await mueve(o['a'] as String, PORTON[0] - d[0], PORTON[1] + d[1]);
      p['dir'] = -1;
      await wait(300);
    },
    'duda': (o) async {
      final x = o['x'];
      final id =
          const {
            'di_senor': 'senor',
            'di_senora': 'mujer',
            'di_joven': 'joven',
          }[x] ??
          x as String;
      final p = G(id);
      if (p == null || p['vis'] == 0) return;
      p['dy'] = 3;
      await wait(200);
      p['dy'] = 0;
      await niega(p);
      p['dir'] = jsTruthy(p['sent']) ? 1 : -1;
    },
    // moves line 325: who says goodbye walks out through the gate's opening (PORTON) and along the path
    'sevade': (o) async {
      final p = G(o['a'] as String)!;
      p['dir'] = -1;
      p['pose'] = 'wave';
      await wait(700);
      p['pose'] = 'idle';
      p['dir'] = 1;
      await mueve(o['a'] as String, PORTON[0], PORTON[1]);
      await mueve(o['a'] as String, _p.keep(325, 246), PORTON[1] + _out12);
      p['vis'] = 0;
    },
    'luisguarda': (o) async {
      final l = G('luis')!, t = cosaDe(o['k'] as String);
      if (t != null) {
        await mueve('luis', (t['x'] as num) + 10, (t['y'] as num) + 6);
        quita(o['k'] as String);
      } else {
        await mueve('luis', cx() + 22, pies());
        W['encima'] = null;
        _cq['dy'] = 0;
      }
      l['lleva'] = o['k'];
      final b = _p.to(326, 'mueve("luis",148,186)');
      await mueve('luis', b[0], b[1]);
      l['dir'] = 1;
      l['lleva'] = null;
      (W['encaja'] as List).add(o['k']);
      SFX.blip();
      await wait(300);
    },
    // moves line 327: the dogs' two places, as at the start
    'perros22': (o) async {
      final v = _perros['viejo'] as Map<String, dynamic>,
          j = _perros['joven'] as Map<String, dynamic>;
      final ld = _p.to(327, 'L=[38,193],D=[90,193]');
      final Lp = [ld[0], ld[1]], Dp = [ld[2], ld[3]];
      final pv = o['lado'] == 'vj' ? Lp : Dp, pj = o['lado'] == 'vj' ? Dp : Lp;
      v['lleva'] = null;
      j['lleva'] = null;
      v['paseo'] = 0;
      j['ronda'] = 0;
      await Future.wait([
        perroA('viejo', pv[0], pv[1], 'walk'),
        perroA('joven', pj[0], pj[1], 'run'),
      ]);
      v['pose'] = 'sit';
      j['pose'] = 'sit';
      v['dir'] = 1;
      j['dir'] = 1;
      await acasa();
      await wait(300);
    },
    'sinhueso': (o) async {
      final n = (o['de'] as String).replaceFirst('perro_', '');
      final d = _perros[n] as Map<String, dynamic>;
      d['pose'] = 'triste';
      d['pena'] = 1;
      W['sinhueso'] = n;
      await wait(500);
    },
    'acaricia': (o) async {
      final d = perroDe(o['a'] as String);
      await ranaA((d['x'] as num) + 30, (d['y'] as num) + 4);
      bounce(4);
      await wait(500);
      d['pose'] = 'sit';
      d['pena'] = 1;
    },
    'cola22': (o) async {
      final rem = [
        for (final k in const ['senor', 'mujer', 'joven'])
          if (k != W['fuera']) k,
      ];
      final own = rem[o['k'] == 'a' ? 0 : 1],
          oth = rem[o['k'] == 'a' ? 1 : 0],
          ord = o['lado'] == 'ab' ? rem : rem.reversed.toList();
      final en = [_p.floor(330, 82, 186), _p.floor(330, 104, 186)];
      V['pc'] = own;
      V['oc'] = oth;
      V['qc'] = own == 'mujer' ? 'senora' : own;
      V['ra'] = rem[0];
      V['rb'] = rem[1];
      W['casa'] = _p.floor(331, 128, 205);
      await acasa();
      await Future.wait([
        for (var i = 0; i < ord.length; i++)
          () async {
            final id = ord[i], p = G(id)!;
            p['lleva'] = null;
            await mueve(id, en[i][0], en[i][1]);
            p['dir'] = -1;
          }(),
      ]);
      await wait(300);
    },
    // moves line 332: out through the gate's opening along the path (PORTON[1] + 12)
    'sevan22': (o) async {
      final ids = [
        for (final k in const ['senor', 'mujer', 'joven'])
          if (G(k)!['vis'] != 0) k,
      ];
      await Future.wait([
        for (var i = 0; i < ids.length; i++)
          () async {
            await wait(i * 350);
            final id = ids[i], p = G(id)!;
            await mueve(id, PORTON[0], PORTON[1]);
            await mueve(id, _p.keep(332, 246), PORTON[1] + _out12);
            p['vis'] = 0;
          }(),
      ]);
    },
    // moves line 333: as sevade
    'alza': (o) async {
      final p = G(o['a'] as String)!;
      _cq['dy'] = -7;
      await wait(500);
      p['pose'] = 'wave';
      await wait(700);
      p['pose'] = 'idle';
      p['dir'] = 1;
      await mueve(o['a'] as String, PORTON[0], PORTON[1]);
      await mueve(o['a'] as String, _p.keep(333, 246), PORTON[1] + _out12);
      p['vis'] = 0;
      _cq['dy'] = 0;
    },
    // moves line 334: Carmen waits at the gate in front of its opening; the man who came for his paper leaves through
    // the gate's opening (PORTON) and along the path
    'final22': (o) async {
      W['noche'] = 1;
      W['casa'] = _p.floor(334, 124, 190);
      final ca = _p.to(334, 'mueve("carmen",190,204)');
      await Future.wait([acasa(), mueve('carmen', ca[0], ca[1])]);
      G('carmen')!['dir'] = -1;
      await wait(500);
      if (((W['marcas'] as List?) ?? const []).every((m) => m == 'ok')) {
        final h = G('hombre')!, l = G('luis')!;
        h['vis'] = 1;
        h['x'] = _p.keep(334, 244);
        h['y'] = PORTON[1];
        await mueve('hombre', PORTON[0] - 4, PORTON[1]);
        for (var k = 0; k < 3; k++) {
          h['dir'] = -(h['dir'] as num);
          await wait(200);
        }
        W['encaja'] = <dynamic>[];
        l['lleva'] = 'periodico';
        l['pose'] = 'arriba';
        l['dir'] = 1;
        SFX.blip();
        await wait(400);
        await mueve('hombre', (l['x'] as num) + 20, l['y'] as num);
        l['lleva'] = null;
        l['pose'] = 'idle';
        h['lleva'] = 'periodico';
        SFX.blip();
        h['dir'] = -1;
        h['pose'] = 'wave';
        await wait(700);
        h['pose'] = 'idle';
        await mueve('hombre', PORTON[0], PORTON[1]);
        await mueve('hombre', _p.keep(334, 246), PORTON[1] + _out12);
        h['vis'] = 0;
      } else {
        final l = G('luis')!;
        l['dir'] = 1;
        await niega(l);
        l['dir'] = 1;
        await wait(300);
      }
    },
    // moves line 335: when the cart goes home the two dogs walk nearer
    'carrova': (o) async {
      final pi = G('piraguero')!,
          v = _perros['viejo'] as Map<String, dynamic>,
          j = _perros['joven'] as Map<String, dynamic>;
      W['carro'] = 'cerrado';
      SFX.blip();
      await wait(400);
      pi['x'] = CARRO[0] + 30;
      pi['y'] = CARRO[1] + 2;
      pi['dir'] = -1;
      pi['paso'] = 1;
      v['lleva'] = null;
      j['lleva'] = null;
      v['paseo'] = 0;
      j['ronda'] = 0;
      W['carroX'] = CARRO[0];
      v['pose'] = 'walk';
      j['pose'] = 'run';
      v['dir'] = -1;
      final vy = _p.to(335, 'v.y=196;j.y=204;');
      v['y'] = vy[0];
      j['y'] = vy[1];
      j['x0'] = math.max(j['x'] as num, _p.keep(335, 70));
      j['fase'] = F;
      v['pena'] = W['sinhueso'] == 'viejo' ? 1 : 0;
      j['pena'] = W['sinhueso'] == 'joven' ? 1 : 0;
      W['seva'] = 1;
      await wait(300);
    },
    'carrofin': (o) async {
      final pi = G('piraguero')!;
      W['seva'] = 2;
      pi['paso'] = 0;
      pi['pose'] = 'wave';
      pi['dir'] = 1;
      await wait(900);
      pi['pose'] = 'idle';
      pi['dir'] = -1;
      pi['paso'] = 1;
      W['seva'] = 3;
      await wait(1400);
    },

    /* ----- story 23: El bebé duerme ----- */
    // moves line 339: the three on the benches (SY); code lines 339 to 341: every other place the floor rule's
    'inicio23': (o) async {
      final ca = _p.floor(339, 38, 210);
      W['gente'] = <String, dynamic>{
        'piraguero': <String, dynamic>{
          'x': CARRO[0] + 4,
          'y': CARRO[1] - 6,
          'dir': 1,
        },
        'senora': <String, dynamic>{
          ..._seat(339, 'senora'),
          'dir': 1,
          'sent': 1,
        },
        'luis': <String, dynamic>{
          ..._seat(339, 'luis'),
          'dir': 1,
          'sent': 1,
          'animo': 'cansado',
        },
        'hombre': <String, dynamic>{
          ..._seat(339, 'hombre'),
          'dir': 1,
          'sent': 1,
          'animo': 'triste',
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'dir': 1,
          'lleva': 'mochila',
        },
      };
      final co = _p.floor(340, 164, 176),
          pe = _p.floor(340, 112, 208),
          cd = _p.floor(340, 184, 178);
      W['coche'] = <String, dynamic>{
        'x': co[0],
        'y': co[1],
        'capota': 0,
        'bebe': 'duerme',
      };
      W['perros'] = <String, dynamic>{
        'canelo': <String, dynamic>{
          'x': pe[0],
          'y': pe[1],
          'pose': 'idle',
          'dir': 1,
          'mueve': 1,
        },
      };
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'id': 'caida',
          'k': 'piragua',
          'x': cd[0],
          'y': cd[1],
          'rot': math.pi / 2,
        },
      ];
      W['juguetes'] = 0;
      W['concojin'] = 0;
      W['palomas'] = _cable();
      final casa = _p.floor(341, 156, 207);
      W['casa'] = casa;
      _cq
        ..['x'] = casa[0] - 16
        ..['y'] = casa[1] - 27
        ..['s'] = 1;
      W['tarde'] = 1;
    },
    'alegra': (o) async {
      final p = G(o['a'] as String)!,
          k = jsTruthy(o['k']) ? o['k'] as String : 'piragua';
      final a = _p.floor(342, 70, 190);
      await ranaA(a[0], a[1]);
      W['encima'] = k;
      SFX.blip();
      final sent = jsTruthy(p['sent']);
      await ranaA(
        sent ? (p['x'] as num) - 4 : (p['x'] as num) + 26,
        sent ? (p['y'] as num) + 22 : (p['y'] as num) + 2,
      );
      W['encima'] = null;
      if (jsTruthy(o['no'])) return;
      if (o['a'] == 'hombre') quita('caida');
      quita('hielo');
      p['animo'] = o['a'] == 'hombre' ? 'contento' : null;
      p['hace'] = 'come';
      p['que'] = 'piragua';
      p['lleva'] = null;
      SFX.blip();
      await wait(700);
      p['hace'] = null;
      p['lleva'] = 'piragua';
      await acasa();
    },
    // moves line 343: Carmen puts the rucksack on the first bench as a cushion, at its right end (AS)
    'cojin': (o) async {
      final ca = G('carmen')!;
      await mueve('carmen', B[0][0] - 4, _p.keep(343, 180));
      ca['lleva'] = null;
      final dx = _p.to(
        343,
        '{id:"cojin",k:"mochila",x:B[0][0]-21,y:ASIENTO+1,z:150}',
        RegExp(r'x:B\[0\]\[0\]\+(\d+),y:AS\(B\[0\]\[0\]\+\d+\)\+(\d+),z:(\d+)'),
      );
      (W['cosas'] as List).add(<String, dynamic>{
        'id': 'cojin',
        'k': 'mochila',
        'x': B[0][0] + dx[0],
        'y': AS(B[0][0] + dx[0]) + dx[1],
        'z': dx[2],
      });
      SFX.blip();
      await wait(400);
      final c = _p.floor(343, 38, 210);
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = 1;
    },
    // moves line 344: abuela comes in through the gate's opening; she sits down on the first bench (SY)
    'abuelallega': (o) async {
      final en = _p.to(344, 'W.gente.abuela={x:250,y:204,dir:-1,paso:1}');
      (W['gente'] as Map<String, dynamic>)['abuela'] = <String, dynamic>{
        'x': en[0],
        'y': en[1],
        'dir': -1,
        'paso': 1,
      };
      await mueve('abuela', B[0][0] + 6, _p.keep(344, 176));
      final a = G('abuela')!;
      final dx = _p.to(
        344,
        'a.x=B[0][0]+5;a.y=161;',
        RegExp(r'a\.x=B\[0\]\[0\]\+(\d+);'),
      )[0];
      a['sent'] = 1;
      a['x'] = B[0][0] + dx;
      a['y'] = SY(B[0][0] + dx);
      a['dir'] = 1;
      await wait(400);
      a['ojos'] = 1;
      final c = _p.floor(344, 124, 180);
      await perroA('canelo', c[0], c[1], 'walk');
      final cn = _perros['canelo'] as Map<String, dynamic>;
      cn['pose'] = 'idle';
      cn['mueve'] = 1;
      cn['dir'] = 1;
      await wait(300);
    },
    'canelo23': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>, a = G('abuela')!;
      if (jsTruthy(c['chal'])) {
        a['pose'] = 'vaso';
        await wait(350);
        c['chal'] = 0;
        SFX.blip();
        await wait(250);
      }
      c['correa'] = null;
      c['mueve'] = 0;
      a['lleva'] = null;
      a['pose'] = 'idle';
      if (o['como'] == 'contento') {
        a['pose'] = 'fan0';
        a['lleva'] = 'bola';
        c['pose'] = 'idle';
        c['mueve'] = 1;
        SFX.blip();
        await wait(600);
      } else if (o['como'] == 'cansado') {
        final r = _p.floor(347, 196, 208), h = _p.floor(347, 124, 180);
        for (var k = 0; k < 2; k++) {
          await perroA('canelo', r[0], r[1], 'run');
          await perroA('canelo', h[0], h[1], 'run');
        }
        c['dir'] = 1;
        c['pose'] = 'cansado';
        await wait(500);
      } else {
        a['pose'] = 'vaso';
        await wait(350);
        c['correa'] = [B[0][0] + 19, _p.keep(348, 160)];
        c['pose'] = 'triste';
        SFX.blip();
        a['pose'] = 'idle';
        await wait(500);
      }
    },
    'pelota': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>,
          a = G('abuela')!,
          n = _plus(jsTruthy(o['n']) ? o['n'] : 1);
      final corta = jsTruthy(o['corta']);
      a['pose'] = 'vaso';
      a['lleva'] = null;
      final y0 = _p.keep(349, 178), h = _p.floor(349, 124, 180);
      for (var k = 0; k < n; k++) {
        final t = <String, dynamic>{
          'id': 'bola',
          'k': 'bola',
          'x': (a['x'] as num) + 16,
          'y': y0,
        };
        (W['cosas'] as List).add(t);
        for (var i = 1; i <= 7; i++) {
          t['x'] = (a['x'] as num) + 16 + (corta ? 6 : 0) * i / 7;
          t['y'] = y0 + (corta ? 2 : 30) * i / 7;
          await wait(TICK);
        }
        if (corta) return;
        c['mueve'] = 0;
        await perroA(
          'canelo',
          (t['x'] as num) - 14,
          (t['y'] as num) + 2,
          'run',
        );
        quita('bola');
        c['lleva'] = 'bola';
        await perroA('canelo', h[0], h[1], 'run');
        c['dir'] = 1;
        c['lleva'] = null;
        c['pose'] = 'idle';
        c['mueve'] = 1;
        await wait(200);
      }
      a['pose'] = 'idle';
    },
    'cae': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>;
      c['mueve'] = 0;
      c['pose'] = 'cansado';
      await wait(500);
    },
    'chal': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>, a = G('abuela')!;
      a['pose'] = 'vaso';
      await wait(300);
      c['chal'] = 1;
      if (!jsTruthy(o['mal'])) {
        c['pose'] = 'cansado';
        c['mueve'] = 0;
      }
      SFX.blip();
      await wait(400);
      a['pose'] = 'idle';
    },
    'caricia': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>, a = G('abuela')!;
      a['pose'] = 'vaso';
      await wait(600);
      if (!jsTruthy(o['mal'])) {
        c['correa'] = null;
        c['pose'] = 'idle';
        c['mueve'] = 1;
      }
      await wait(400);
      a['pose'] = 'idle';
    },
    'abuelamal': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>,
          dijo = (o['dijo'] as String).replaceFirst('di_', ''),
          es = o['es'],
          x0 = c['x'] as num;
      if (dijo == 'contento') {
        if (es == 'cansado') {
          await _act('pelota', {'corta': 1});
          quita('bola');
          G('abuela')!['pose'] = 'idle';
          c['dy'] = 3;
          ladra(1);
          await wait(400);
          c['dy'] = 0;
        } else {
          final t = <String, dynamic>{
            'id': 'bola',
            'k': 'bola',
            'x': (G('abuela')!['x'] as num) + 16,
            'y': _p.keep(355, 178),
          };
          (W['cosas'] as List).add(t);
          for (var i = 1; i <= 7; i++) {
            t['x'] = (t['x'] as num) + 8;
            t['y'] = (t['y'] as num) + 2.5;
            await wait(TICK);
          }
          c['pose'] = 'walk';
          for (var i = 0; i < 4; i++) {
            c['x'] = (c['x'] as num) + 3;
            await wait(TICK);
          }
          c['pose'] = 'triste';
          gime();
          await wait(600);
          c['x'] = x0;
          quita('bola');
        }
      } else if (dijo == 'cansado') {
        await _act('chal', {'mal': 1});
        if (es == 'contento') {
          grune();
          for (var i = 0; i < 8; i++) {
            c['x'] = x0 + (i % 2 != 0 ? 3 : -3);
            await wait(90);
          }
          c['x'] = x0;
          ladra(1);
        } else {
          gime();
          await wait(700);
        }
        c['chal'] = 0;
      } else {
        await _act('caricia', {'mal': 1});
        if (es == 'cansado') {
          grune();
          await wait(700);
        } else {
          c['pose'] = 'bark';
          for (var k = 0; k < 2; k++) {
            c['dy'] = 7;
            ladra(1);
            await wait(220);
            c['dy'] = 0;
            await wait(160);
          }
          c['pose'] = 'idle';
        }
      }
      await wait(200);
    },
    'abuelahace': (o) async {
      if (o['que'] == 'contento') {
        await _act('pelota', {'n': 1});
      } else if (o['que'] == 'cansado') {
        await _act('chal', {});
      } else {
        await _act('caricia', {});
      }
      G('abuela')!['lleva'] = null;
    },
    // she reaches over and pulls the hood
    'capota': (o) async {
      final s = G('senora')!;
      s['pose'] = 'offer';
      s['dir'] = -1;
      await wait(300);
      (W['coche'] as Map<String, dynamic>)['capota'] = _plus(o['v']);
      SFX.blip();
      await wait(350);
      s['pose'] = 'idle';
      s['dir'] = 1;
    },
    // moves line 361: the señora leans 4 px to the right along the seat, keeping to its edge (2 rows lower)
    'mira23': (o) async {
      final s = G('senora')!;
      final d = _p.to(
        361,
        's.x+=4;await wait(700);s.x-=4;',
        RegExp(r's\.x\+=(\d+);s\.y\+=(\d+);'),
      );
      s['x'] = (s['x'] as num) + d[0];
      s['y'] = (s['y'] as num) + d[1];
      await wait(700);
      s['x'] = (s['x'] as num) - d[0];
      s['y'] = (s['y'] as num) - d[1];
      await wait(250);
    },
    'manita': (o) async {
      final co = W['coche'] as Map<String, dynamic>;
      co['mano'] = _plus(o['v']);
      if (_plus(o['v']) != 0) co['bebe'] = 'rie';
      await wait(400);
    },
    'quieto': (o) async {
      final q = _cq;
      q['hace'] = 'quieto';
      await wait(1300);
      q['hace'] = null;
    },
    'canta': (o) async {
      final q = _cq;
      q['hace'] = 'canta';
      coquiS();
      await wait(1300);
      q['hace'] = null;
    },
    'rie': (o) async {
      final co = W['coche'] as Map<String, dynamic>;
      co['bebe'] = 'rie';
      co['tiembla'] = 0;
      const ts = [0, .12, .24];
      for (var i = 0; i < ts.length; i++) {
        tone(900 + i * 120, ts[i], .07, 'sine', .03, 1100);
      }
      await wait(800);
      co['mano'] = 0;
    },
    'duerme': (o) async {
      final co = W['coche'] as Map<String, dynamic>;
      co['bebe'] = 'duerme';
      co['mano'] = 0;
      co['tiembla'] = 0;
      await wait(300);
    },
    'despierta': (o) async {
      await despierta();
    },
    'mece': (o) async {
      await mece();
    },
    'turno23a': (o) async {
      final l = G('luis')!;
      l['animo'] = null;
      l['sent'] = 0;
      l['pose'] = 'arriba';
      await wait(500);
      l['pose'] = 'idle';
      final a = _p.floor(369, 92, 192);
      await mueve('luis', a[0], a[1]);
      l['dir'] = -1;
      await wait(300);
      l['lleva'] = 'piragua';
      l['dir'] = 1;
      SFX.blip();
      final pg = libre()!;
      W['ladrona'] = pg;
      pio();
      final co = W['coche'] as Map<String, dynamic>;
      await palomaA(pg, (co['x'] as num) + 14, (co['y'] as num) - 33);
      pg['z'] = 400;
      await wait(400);
    },
    'turno23b': (o) async {
      final pg = W['ladrona'] as Map<String, dynamic>;
      bounce(8);
      await wait(200);
      await Future.wait([alcable(pg), despierta()]);
      W['ladrona'] = null;
      await wait(500);
      await mece();
    },
    'tres23': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>,
          l = G('luis')!,
          h = G('hombre')!,
          a = G('abuela')!,
          pg = libre()!;
      if (jsTruthy(c['chal'])) {
        a['pose'] = 'vaso';
        await wait(300);
        c['chal'] = 0;
        a['pose'] = 'idle';
      }
      c['correa'] = null;
      c['mueve'] = 0;
      a['lleva'] = null;
      a['pose'] = 'idle';
      pio();
      final p1 = _p.floor(372, 190, 204),
          p2 = _p.floor(372, 150, 150),
          r1 = _p.floor(372, 196, 204),
          r2 = _p.floor(372, 124, 199),
          hi = _p.floor(373, 70, 196);
      await Future.wait([
        () async {
          await palomaA(pg, p1[0], p1[1]);
          await wait(200);
          await palomaA(pg, p2[0], p2[1]);
          await alcable(pg);
        }(),
        () async {
          await wait(250);
          await perroA('canelo', r1[0], r1[1], 'run');
          await perroA('canelo', r2[0], r2[1], 'run');
          c['dir'] = 1;
          c['pose'] = 'cansado';
        }(),
        () async {
          await wait(500);
          l['lleva'] = 'papel';
          (W['cosas'] as List).add(<String, dynamic>{
            'id': 'hielo',
            'k': 'piragua',
            'x': hi[0],
            'y': hi[1],
            'rot': math.pi / 2,
          });
          SFX.bonk();
          await wait(300);
          l['animo'] = 'triste';
        }(),
        () async {
          await wait(900);
          h['lleva'] = null;
          h['lee'] = 1;
          h['animo'] = 'contento';
          h['paso'] = 1;
        }(),
      ]);
      await wait(500);
    },
    'ayuda': (o) async {
      final q = o['q'], c = _perros['canelo'] as Map<String, dynamic>;
      if (q == 'cansado') {
        await ranaA(B[0][0] - 8, _p.keep(374, 184));
        quita('cojin');
        W['encima'] = 'mochila';
        SFX.blip();
        await ranaA((c['x'] as num) + 46, (c['y'] as num) + 2);
        W['encima'] = null;
        (W['cosas'] as List).add(<String, dynamic>{
          'id': 'cojin',
          'k': 'mochila',
          'x': (c['x'] as num) + 13,
          'y': (c['y'] as num) + 1,
          'z': (c['y'] as num) - 1,
        });
        W['concojin'] = 1;
        SFX.blip();
        await wait(400);
      } else if (q == 'triste') {
        await _act('alegra', {'a': 'luis'});
      } else {
        final h = G('hombre')!;
        await ranaA((h['x'] as num) - 2, (h['y'] as num) + 24);
        h['dy'] = 2;
        await wait(200);
        h['dy'] = 0;
        for (var k = 0; k < 3; k++) {
          _cq['dy'] = -3;
          await wait(140);
          _cq['dy'] = 0;
          await wait(140);
        }
      }
      await acasa();
    },
    'ayudamal': (o) async {
      final q = o['q'],
          x = o['x'],
          c = _perros['canelo'] as Map<String, dynamic>,
          p = x == 'perro' ? null : G(x as String);
      final sent = p != null && jsTruthy(p['sent']);
      final tx = p != null
              ? (sent ? (p['x'] as num) - 4 : (p['x'] as num) + 24)
              : (c['x'] as num) + 36,
          ty = p != null
              ? (sent ? (p['y'] as num) + 22 : (p['y'] as num) + 2)
              : c['y'] as num;
      if (q == 'cansado') {
        final y0 = _p.keep(379, 184);
        await ranaA(B[0][0] - 8, y0);
        final t = cosaDe('cojin');
        if (t != null) t['vis'] = 0;
        W['encima'] = 'mochila';
        await ranaA(tx, ty);
        if (x == 'luis') {
          p!['dy'] = 3;
          sollozo();
          await wait(700);
          p['dy'] = 0;
        } else {
          risa();
          p!['dy'] = 2;
          await wait(700);
          p['dy'] = 0;
        }
        await ranaA(B[0][0] - 8, y0);
        W['encima'] = null;
        if (t != null) t['vis'] = 1;
      } else if (q == 'triste') {
        final a = _p.floor(380, 70, 190);
        await ranaA(a[0], a[1]);
        W['encima'] = 'piragua';
        await ranaA(tx, ty);
        if (x == 'perro') {
          W['encima'] = null;
          c['pose'] = 'come';
          await wait(500);
          c['pose'] = 'cansado';
          c['dy'] = 4;
          ladra(1);
          await wait(400);
          c['dy'] = 0;
        } else {
          W['encima'] = null;
          p!['lleva'] = 'piragua';
          SFX.blip();
          await wait(300);
        }
      } else {
        await ranaA(tx, ty);
        for (var k = 0; k < 2; k++) {
          _cq['dy'] = -5;
          await wait(150);
          _cq['dy'] = 0;
          await wait(150);
        }
        if (x == 'perro') {
          grune();
          c['dy'] = 2;
          await wait(700);
          c['dy'] = 0;
        } else {
          sollozo();
          p!['dy'] = 3;
          await wait(700);
          p['dy'] = 0;
        }
      }
      await acasa();
    },
    'resto': (o) async {
      final c = _perros['canelo'] as Map<String, dynamic>,
          l = G('luis')!,
          ca = G('carmen')!,
          t = cosaDe('cojin');
      if (!jsTruthy(W['concojin'])) {
        await mueve('carmen', B[0][0] - 6, _p.keep(383, 180));
        if (t != null) quita('cojin');
        ca['lleva'] = 'mochila';
        await mueve('carmen', (c['x'] as num) + 30, (c['y'] as num) + 2);
        ca['lleva'] = null;
        (W['cosas'] as List).add(<String, dynamic>{
          'id': 'cojin',
          'k': 'mochila',
          'x': (c['x'] as num) + 13,
          'y': (c['y'] as num) + 1,
          'z': (c['y'] as num) - 1,
        });
        W['concojin'] = 1;
        SFX.blip();
        await wait(300);
      }
      if (l['animo'] == 'triste') {
        final a = _p.floor(384, 70, 196);
        await mueve('carmen', a[0], a[1]);
        ca['lleva'] = 'piragua';
        await mueve('carmen', (l['x'] as num) + 18, (l['y'] as num) + 4);
        ca['lleva'] = null;
        quita('hielo');
        l['lleva'] = 'piragua';
        l['animo'] = null;
        SFX.blip();
        await wait(300);
      }
      final b = _p.floor(385, 38, 210);
      await mueve('carmen', b[0], b[1]);
      ca['dir'] = 1;
    },
    'final23': (o) async {
      (_perros['canelo'] as Map<String, dynamic>)['pose'] = 'cansado';
      final a = G('abuela')!, n = _n(W['juguetes']);
      List<Map<String, dynamic>> jug() => [
        for (final o in W['cosas'] as List)
          if (jsTruthy((o as Map)['id']) && _starts(o['id'], 'jug'))
            o as Map<String, dynamic>,
      ];
      G('hombre')!['animo'] = null;
      G('hombre')!['lee'] = 0;
      G('hombre')!['paso'] = 0;
      a['ojos'] = 0;
      await wait(400);
      a['sent'] = 0;
      a['x'] = B[0][0] + 10;
      a['y'] = _p.keep(386, 180);
      await wait(300);
      if (n <= 1) {
        final js = jug(), t = js.isEmpty ? null : js[0];
        if (t != null) {
          await ranaA((t['x'] as num) - 14, (t['y'] as num) + 6);
          quita(t['id'] as String);
          W['encima'] = 'sonajero';
          final co = W['coche'] as Map<String, dynamic>;
          await ranaA((co['x'] as num) - 28, (co['y'] as num) + 10);
          W['encima'] = null;
          await wait(300);
        }
      } else {
        // the other toys stay where they fell: that is what the day cost
        final sn = G('senora')!, t = jug()[0];
        await mueve('senora', (t['x'] as num) - 12, (t['y'] as num) + 2);
        quita(t['id'] as String);
        sn['lleva'] = t['k'];
        sn['dir'] = 1;
        await wait(300);
      }
      await acasa();
    },
    'ranacansada': (o) async {
      _cq['hace'] = 'cansado';
      await wait(500);
    },
    // moves line 391: everyone leaves through the gate's opening and out along the path
    'sevan23': (o) async {
      _cq['hace'] = null;
      final c = _perros['canelo'] as Map<String, dynamic>;
      c['pose'] = 'walk';
      quita('cojin');
      G('carmen')!['lleva'] = 'mochila';
      final d = _p.to(
        391,
        'mueve("abuela",250,200),mueve("carmen",250,206),mueve("luis",250,196),perroA("canelo",250,210',
      );
      final r = _p.floor(391, 232, 204);
      await Future.wait([
        mueve('abuela', d[0], d[1]),
        mueve('carmen', d[2], d[3]),
        mueve('luis', d[4], d[5]),
        perroA('canelo', d[6], d[7], 'walk'),
        () async {
          await wait(500);
          await ranaA(r[0], r[1], 4);
        }(),
      ]);
    },

    /* ----- Escuchar: plain acts that the picture stories and the routines are written with ----- */
    // set anything on a person
    'g': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      for (final k in o.keys) {
        if (!const ['act', 'quien', 'ms'].contains(k)) p[k] = o[k];
      }
      if (jsTruthy(o['ms'])) await wait(o['ms'] as num);
    },
    // suelto: the line is said while he walks
    'anda': (o) async {
      final id = o['quien'] as String,
          p = G(id)!,
          xy = _fromFile(o['x'], o['y']);
      final d = _hypot(xy[0] - (p['x'] as num), xy[1] - (p['y'] as num));
      final pr = () async {
        await mueve(
          id,
          xy[0],
          xy[1],
          jsTruthy(o['lento']) ? math.max(4, _round(d / 2)) : null,
        );
        if (jsTruthy(o['dir'])) p['dir'] = o['dir'];
        if (jsTruthy(o['sent'])) {
          p['sent'] = 1;
          p['dir'] = 1;
        }
        if (jsTruthy(o['fuera'])) p['vis'] = 0;
      }();
      if (!jsTruthy(o['suelto'])) await pr;
    },
    'saluda': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      final d = p['dir'];
      if (jsTruthy(o['dir'])) p['dir'] = o['dir'];
      p['pose'] = jsTruthy(o['que']) ? o['que'] : 'wave';
      await wait(_or(o['ms'], 750));
      p['pose'] = 'idle';
      p['dir'] = d;
    },
    'brinco': (o) async {
      final p = o['quien'] == 'perro'
          ? _perros[jsTruthy(o['n']) ? o['n'] as String : 'canelo']
                as Map<String, dynamic>
          : G(o['quien'] as String)!;
      for (var k = 0; k < _or(o['n2'], 2); k++) {
        p['dy'] = _or(o['h'], 4);
        await wait(130);
        p['dy'] = 0;
        await wait(130);
      }
    },
    'rana': (o) async {
      final xy = _fromFile(o['x'], o['y']);
      final pr = ranaA(xy[0], xy[1], o['h'] as num?);
      if (!jsTruthy(o['suelto'])) await pr;
    },
    'encima': (o) async {
      W['encima'] = jsTruthy(o['k']) ? o['k'] : null;
      SFX.blip();
      await wait(200);
    },
    'can': (o) async {
      final d = _perros['${o['n']}'] as Map<String, dynamic>?;
      if (d == null) return;
      final pr = () async {
        if (o['x'] != null) {
          final xy = _fromFile(o['x'], o['y']);
          await perroA(
            o['n'] as String,
            xy[0],
            xy[1],
            jsTruthy(o['modo']) ? o['modo'] as String : 'walk',
          );
        }
        for (final k in o.keys) {
          if (!const [
            'act',
            'n',
            'x',
            'y',
            'modo',
            'ms',
            'suelto',
          ].contains(k)) {
            d[k] = o[k];
          }
        }
      }();
      if (!jsTruthy(o['suelto'])) await pr;
      if (jsTruthy(o['ms'])) await wait(o['ms'] as num);
    },
    'pal': (o) async {
      final pg = o['i'] != null
          ? _palomas[(o['i'] as num).toInt()] as Map<String, dynamic>?
          : libre();
      if (pg == null) return;
      if (jsTruthy(o['cable'])) {
        await alcable(pg);
      } else if (o['x'] != null) {
        pio();
        final xy = _fromFile(o['x'], o['y']);
        await palomaA(pg, xy[0], xy[1]);
        pg['en'] = 'suelo';
      }
      pg['pose'] = jsTruthy(o['pose']) ? o['pose'] : '';
      if (jsTruthy(o['dir'])) pg['dir'] = o['dir'];
      if (jsTruthy(o['z'])) pg['z'] = o['z'];
      await wait(_or(o['ms'], 200));
    },
    'cosa': (o) async {
      if (jsTruthy(o['quita'])) {
        quita(o['quita'] as String);
        return;
      }
      final xy = _fromFile(o['x'], o['y']);
      (W['cosas'] as List).add(<String, dynamic>{
        'id': o['id'],
        'k': o['k'],
        'x': xy[0],
        'y': xy[1],
        'rot': jsTruthy(o['rot']) ? o['rot'] : 0,
        'z': o['z'],
      });
      if (jsTruthy(o['son'])) _sfx(o['son'] as String);
      await wait(_or(o['ms'], 150));
    },
    'rueda': (o) async {
      final t = cosaDe('${o['id']}');
      if (t == null) return;
      final x0 = t['x'] as num, y0 = t['y'] as num, n = _or(o['n'], 10);
      final xy = _fromFile(o['x'], o['y']);
      final pr = () async {
        for (var i = 1; i <= n; i++) {
          t['x'] = x0 + (xy[0] - x0) * i / n;
          t['y'] = y0 + (xy[1] - y0) * i / n;
          await wait(TICK);
        }
        if (jsTruthy(o['fuera'])) quita(o['id'] as String);
      }();
      if (!jsTruthy(o['suelto'])) await pr;
    },
    'luz': (o) async {
      W['noche'] = o['v'];
      if (jsTruthy(o['luna'])) W['luna'] = 1;
      SFX.blip();
      await wait(500);
    },
    'rebota': (o) async {
      final t = cosaDe('${o['id']}');
      if (t == null) return;
      final y0 = t['y'] as num;
      for (var k = 0; k < _or(o['n'], 3); k++) {
        for (final d in const [-6, -10, -6, 0]) {
          t['y'] = y0 + d;
          await wait(60);
        }
        SFX.hop();
      }
    },
    // banco.js:407 acts.manos (W.manos = o.v), which replaces the one at :280 (Carmen hands him what o.i and o.d name:
    // the later wins in the object literal, so that one never ran)
    'manos': (o) async {
      W['manos'] = jsTruthy(o['v']) ? o['v'] : null;
      SFX.blip();
      await wait(200);
    },
    'hace': (o) async {
      _cq['hace'] = jsTruthy(o['que']) ? o['que'] : null;
      await wait(_or(o['ms'], 200));
    },
    'ladra': (o) async {
      ladra(_or(o['n'], 1));
      final d =
          _perros[jsTruthy(o['quien']) ? o['quien'] as String : 'canelo']
              as Map<String, dynamic>?;
      if (d != null) {
        for (var k = 0; k < _or(o['n'], 1); k++) {
          d['dy'] = 3;
          await wait(140);
          d['dy'] = 0;
          await wait(140);
        }
      }
    },
    'ronda1': (o) async {
      final d =
          _perros[jsTruthy(o['n']) ? o['n'] as String : 'joven']
              as Map<String, dynamic>;
      d['x0'] = d['x'];
      d['pose'] = 'run';
      d['fase'] = F;
      d['ronda'] = 1;
      await wait(_or(o['ms'], 1500));
      d['ronda'] = 0;
      d['pose'] = 'sit';
      d['x'] = d['x0'];
      d['dir'] = 1;
    },
    // everybody at once, to look at the drawing (no story calls it; code lines 413 to 420: unchanged)
    'prueba': (o) async {
      _prueba(o);
    },
  };

  // banco.js: acts.prueba
  void _prueba(Map<String, dynamic> o) {
    final b = BANCOS, n = _plus(jsTruthy(o['n']) ? o['n'] : 1);
    W['gente'] = <String, dynamic>{
      'piraguero': <String, dynamic>{
        'x': CARRO[0] + 4,
        'y': CARRO[1] - 6,
        'pose': 'idle',
        'dir': 1,
      },
    };
    W['palomas'] = _cable();
    W['cosas'] = <dynamic>[];
    W['perros'] = <String, dynamic>{};
    if (n == 5) {
      W['gente'] = <String, dynamic>{};
      W['palomas'] = <dynamic>[];
      W['carro'] = 0;
      const poses = [
        'idle',
        'walk',
        'sit',
        'lie',
        'come',
        'triste',
        'cansado',
        'run',
        'duerme',
      ];
      for (var k = 0; k < poses.length; k++) {
        (W['perros'] as Map<String, dynamic>)['x$k'] = <String, dynamic>{
          'x': 50 + (k % 4) * 46,
          'y': 160 + (k >> 2) * 26,
          'pose': poses[k],
          'dir': 1,
          'tipo': o['t'],
          'pena': _plus(_or(o['pena'], 0)),
        };
      }
      _cq['vis'] = 0;
      return;
    }
    final g = W['gente'] as Map<String, dynamic>;
    if (n == 2) {
      g.addAll({
        'senor': <String, dynamic>{
          'x': b[0][0] - 8,
          'y': b[0][1] + 11,
          'dir': 1,
          'sent': 1,
        },
        'mujer': <String, dynamic>{
          'x': b[1][0] - 8,
          'y': b[1][1] + 11,
          'dir': 1,
          'sent': 1,
        },
        'joven': <String, dynamic>{
          'x': b[2][0] - 10,
          'y': b[2][1] + 11,
          'dir': 1,
          'sent': 1,
        },
        'hombre': <String, dynamic>{
          'x': b[2][0] + 11,
          'y': b[2][1] + 11,
          'dir': 1,
          'sent': 1,
          'lee': 1,
        },
        'luis': <String, dynamic>{'x': 186, 'y': 200, 'dir': -1},
        'carmen': <String, dynamic>{
          'x': 150,
          'y': 204,
          'dir': -1,
          'lleva': 'bolsa',
        },
      });
      _cq
        ..['x'] = 112
        ..['y'] = 180
        ..['s'] = 1;
      W['perros'] = <String, dynamic>{
        'viejo': <String, dynamic>{'x': 40, 'y': 204, 'pose': 'lie', 'dir': 1},
        'joven': <String, dynamic>{
          'x': 68,
          'y': 206,
          'pose': 'sit',
          'dir': 1,
          'lleva': 'hueso',
        },
      };
      W['encaja'] = <dynamic>['periodico', 'cartera'];
      W['cosas'] = <dynamic>[
        <String, dynamic>{'k': 'caja', 'x': 168, 'y': 206},
        <String, dynamic>{
          'k': 'sombrilla',
          'x': b[1][0] + 14,
          'y': b[1][1] + 5,
        },
      ];
    } else {
      g.addAll({
        'luis': <String, dynamic>{
          'x': b[0][0] - 13,
          'y': b[0][1] + 11,
          'dir': 1,
          'sent': 1,
          'animo': 'cansado',
        },
        'abuela': <String, dynamic>{
          'x': b[0][0] + 5,
          'y': 161,
          'dir': 1,
          'sent': 1,
          'ojos': 1,
        },
        'senora': <String, dynamic>{
          'x': b[1][0] - 9,
          'y': b[1][1] + 11,
          'dir': 1,
          'sent': 1,
        },
        'hombre': <String, dynamic>{
          'x': b[2][0] + 2,
          'y': b[2][1] + 11,
          'dir': 1,
          'sent': 1,
          'animo': jsTruthy(o['h']) ? o['h'] : 'triste',
        },
        'carmen': <String, dynamic>{
          'x': 52,
          'y': 208,
          'dir': 1,
          'animo': 'contento',
        },
      });
      _cq
        ..['x'] = 130
        ..['y'] = 175
        ..['s'] = 1
        ..['hace'] = jsTruthy(o['rana']) ? o['rana'] : 'canta';
      W['coche'] = <String, dynamic>{
        'x': 164,
        'y': 176,
        'capota': _plus(_or(o['cap'], 0)),
        'bebe': jsTruthy(o['bebe']) ? o['bebe'] : 'duerme',
        'mano': _plus(_or(o['mano'], 0)),
      };
      W['perros'] = <String, dynamic>{
        'canelo': <String, dynamic>{
          'x': 124,
          'y': 180,
          'pose': jsTruthy(o['can']) ? o['can'] : 'triste',
          'dir': 1,
          'chal': _plus(_or(o['chal'], 0)),
          'correa': o['can'] == 'triste' || !jsTruthy(o['can'])
              ? [B[0][0] + 19, 160]
              : null,
        },
      };
      W['cosas'] = <dynamic>[
        for (var i = 0; i < JUG.length; i++)
          <String, dynamic>{'k': JUG[i], 'x': JUGEN[i][0], 'y': JUGEN[i][1]},
      ];
      W['tarde'] = 1;
    }
  }

  // banco.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    SFX.bonk();
    await wait(300);
  }

  // banco.js: poke
  @override
  dynamic poke(String what) {
    if (what == 'pajaro') pio();
    return null;
  }

  // banco.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if ((g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}'
                '${jsTruthy(p['lleva']) ? '[${p['lleva']}]' : ''}';
          }(),
    ].join(' ');
    final palomas = [
      for (final o in (W['palomas'] as List?) ?? const [])
        jsTruthy((o as Map)['en']) ? '${o['en']}' : '?',
    ].join();
    final cosas = [
      for (final o in (W['cosas'] as List?) ?? const [])
        if ((o as Map)['vis'] != 0)
          jsTruthy(o['id']) ? '${o['id']}' : '${o['k']}',
    ].join(',');
    final caja = [
      for (final k in (W['encaja'] as List?) ?? const []) k == null ? '' : '$k',
    ].join(',');
    final manos = jsonEncode(jsTruthy(W['manos']) ? W['manos'] : const {});
    final marcas = [
      for (final m in (W['marcas'] as List?) ?? const [])
        m == null ? '' : _js(m),
    ].join(',');
    final ps = (W['perros'] as Map<String, dynamic>?) ?? const {};
    final perros = [
      for (final k in ps.keys)
        () {
          final d = ps[k] as Map<String, dynamic>;
          return '$k:${_jsField(d, 'pose')}${jsTruthy(d['lleva']) ? '+${d['lleva']}' : ''}';
        }(),
    ].join(',');
    final co = W['coche'] as Map<String, dynamic>?;
    return 'gente=$gente palomas=$palomas posadas=${_js(_n(W['posadas']))} cosas=$cosas caja=$caja'
        ' manos=$manos bandeja=${_jsField(W, 'bandeja')}'
        ' jug=${_js(_n(W['juguetes']))} marcas=$marcas perros=$perros'
        '${co != null ? ' bebe=${_jsField(co, 'bebe')}/${jsTruthy(co['capota']) ? 'capota' : 'abierto'}' : ''}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through
  // the sheet's remap table. A point keeps its screen place (the sheet's `new`; the few the sheet moved: the piragua man
  // with his cart, those who sit on a seat's edge, the ways out through the gate, a thing on a seat); the frog out of a
  // picture is no place (`to.none`) and is given back; a pair rectangle gives the crop of the pictures it was; a level
  // picture's rectangle or x gives itself back (the level pictures are the sheet's, whole).
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

  // banco-preview.html: PV.pair's remapW for a review picture's own W (the pair's file, cual-banco): those who sit, the
  // pigeons, the things, the dogs and those who stand, each at a place of a move or of a story position the sheet moved
  // for cual-banco to its new one. The frog (the top level's `cq`) is ScenePictures' (the sheet's remap).
  @override
  void placePair(Map<String, dynamic> set) => remapW(set, 'cual-banco');

  // banco-preview.html: PV.remapW. A W in old positions, moved by the sheet's rule: whoever sits on a bench at SY(x), the
  // places of moves and of the story positions remap moves ([story]: the file whose positions it holds, null: any); the
  // frog too when [cq] (a recorded W, not a pair's: ScenePictures remaps a pair's frog)
  void remapW(Map<String, dynamic> w, String? story, {bool cq = false}) {
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
        if (e.old[0] == x && e.old[1] == y) return e.now;
      }
      return null;
    }

    // banco-preview.html: SYf
    int syf(num x) {
      final k = x < 120
          ? 0
          : x < 168
          ? 1
          : 2;
      const b = [96, 144, 192];
      return _round(161 + (x - b[k]) / 2);
    }

    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    // the old W's sitters, before any move
    final sitters = [
      for (final p in gente.values)
        if (p is Map &&
            jsTruthy(p['sent']) &&
            _round(p['y'] as num) == 161 &&
            p['vis'] != 0)
          p['x'] as num,
    ];
    for (final en in gente.entries) {
      final p = en.value;
      if (p is! Map ||
          p['x'] == null ||
          !jsTruthy(p['sent']) ||
          _round(p['y'] as num) != 161) {
        continue;
      }
      for (final m in MV) {
        if (m.who == en.key &&
            m.old[0] == _round(p['x'] as num) &&
            m.old[1] == 161) {
          p['x'] = m.now[0] + ((p['x'] as num) - _round(p['x'] as num));
          break;
        }
      }
      p['y'] =
          syf(_round(p['x'] as num)) +
          ((p['y'] as num) - _round(p['y'] as num));
    }
    for (final k in const ['palomas', 'cosas']) {
      final who = k == 'palomas' ? 'paloma' : 'cosa';
      for (final p in (w[k] as List?) ?? const []) {
        if (p is Map && p['x'] != null) {
          final m = find(who, p);
          if (m != null) {
            p['x'] = m[0];
            p['y'] = m[1];
          }
        }
      }
    }
    final perros = (w['perros'] as Map<String, dynamic>?) ?? const {};
    // the old W's dogs, before any move (the frog beside one moves with it)
    final perros0 = [
      for (final d in perros.values)
        if (d is Map && d['x'] != null) [d['x'] as num, d['y'] as num],
    ];
    for (final p in perros.values) {
      if (p is Map && p['x'] != null) {
        final m = find('perro', p);
        if (m != null) {
          p['x'] = m[0];
          p['y'] = m[1];
        }
      }
    }
    if (jsTruthy(w['seva'])) {
      final v = perros['viejo'] as Map?, j = perros['joven'] as Map?;
      if (v != null && v['y'] == 196) v['y'] = 206;
      if (j != null && j['y'] == 204) j['y'] = 210;
    }
    final gentil = RegExp(r' (beats|.*gente)');
    for (final en in gente.entries) {
      final p = en.value;
      if (p is! Map || p['x'] == null || jsTruthy(p['sent'])) continue;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      List<num>? m;
      for (final q in MV) {
        if ((q.who == en.key || q.who == 'porton') &&
            q.old[0] == x &&
            q.old[1] == y) {
          m = q.now;
          break;
        }
      }
      if (m == null) {
        for (final e in RM) {
          if (e.old[0] == x &&
              e.old[1] == y &&
              e.uses.any((u) => gentil.hasMatch(u))) {
            m = e.now;
            break;
          }
        }
      }
      if (m != null) {
        p['x'] = m[0] + ((p['x'] as num) - x);
        p['y'] = m[1] + ((p['y'] as num) - y);
      }
    }
    final q = w['cq'] as Map<String, dynamic>?;
    if (cq && q != null) {
      for (final m2 in MV) {
        if (m2.who == 'cq' && m2.old[0] == q['x'] && m2.old[1] == q['y']) {
          q['x'] = m2.now[0];
          q['y'] = m2.now[1];
          break;
        }
      }
      for (final d in perros0) {
        if (q['x'] != _round(d[0]) + 14 || q['y'] != _round(d[1]) - 23) {
          continue;
        }
        for (final m2 in MV) {
          if (m2.who == 'perro' &&
              m2.old[0] == _round(d[0]) &&
              m2.old[1] == _round(d[1])) {
            q['x'] = (q['x'] as num) + m2.now[0] - m2.old[0];
            q['y'] = (q['y'] as num) + m2.now[1] - m2.old[1];
            break;
          }
        }
        break;
      }
      for (final sx in sitters) {
        final rx = _round(sx);
        if (const [0, -2, -4].contains((q['x'] as num) + 16 - rx) &&
            const [156, 158].contains(q['y'])) {
          num nx = rx;
          for (final m2 in MV) {
            if (m2.old[0] == rx && m2.old[1] == 161 && m2.who != 'sitting') {
              nx = m2.now[0];
              break;
            }
          }
          q['x'] = (q['x'] as num) + nx - rx;
          q['y'] = (q['y'] as num) + syf(nx) - 161;
          break;
        }
      }
    }
    if (w['carroX'] != null) {
      w['carroX'] = (w['carroX'] as num) - 11;
      final pi = gente['piraguero'] as Map?;
      if (pi != null && jsTruthy(w['seva'])) {
        pi['x'] = (pi['x'] as num) - 11;
        pi['y'] = 178 + 2 + (36 - (w['carroX'] as num)) / 2;
      }
    }
  }
}
