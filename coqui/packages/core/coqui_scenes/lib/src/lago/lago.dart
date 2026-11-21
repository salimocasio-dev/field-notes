// Port of historia/escenas/lago.js: the scene "El lago", the lake in the park (order 35b). Line for line, minus its
// background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background, which the set
// bakes; the old reeds, mkJunco, which are the set's bed of reeds now); every screen position replaced by what the
// sheet's `code` list gives for its line (lago_places.dart), and the places the sheet's `moves` list moves, each at its
// line (the moved source's own numbers: LagoPlaces.to). lago.js is written on the kit, so this is an `Escena`; its set
// is [LagoSet].
//
// What El lago's sheet has that the earlier ones did not, and how it is kept here (as lago-preview.html keeps it):
// - `helps.ring`: El campo's ripple ring round whatever floats or swims at the surface, a size per kind (a duck
//   swimming, a boat on the water or in the reeds, the bread on the water: [Lago.ring]); and the fish's patch
//   (`helps.ring.pez`: [Lago.patch], an ellipse of paler water under the fish at the surface, its edge dithered into the
//   lake, the lake's ripple dashes going on inside it). Both only where the set's water shows. The lines the sheet adds
//   to lago.js (`helps.lines`): pato, bote and pez draw their help first; the bread on the water its ring.
// - `moves` (23) and `remap`: the post, Carmen on the right bank in los-botes, the boats' row at her feet (slotC), the
//   boats on the deck, the bread row on the planks, where boats stick in the reeds (PEGA), the flower, the ducks' and
//   the fish's places and paths, the answer cards (W.respEn), the story files' own positions through remap.
// - `front`: the reeds, the post and the mooring posts are drawn again over whoever is behind them, by the depth test on
//   the surface under each (the planks', the lawn's or the water's: [Lago.front]).
// - `shadows`: people, animals and things cast on the lawn and the planks only; the water takes none (`noShade`).
// - `talk`: where a bubble goes ([Lago.talkPlace]); a sitting child's head is its own (`heads.<id>.s`).
// - things.juncos, muelle, agua and lago carry a hint box.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file. lago.js's own `aveA` is [Lago.pajaroA] here: the
// kit gives every scene its own bird's `aveA`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/lago/lago_places.dart';
import 'package:coqui_scenes/src/lago/lago_set.dart'
    show LagoSet, LagoState, lagoEngine, lagoSurfaceAt;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/set_kit.dart' show KIND_WATER;
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "lago", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It draws
/// its random numbers from [rng], the game's one random source.
Scene createLago({Rng? rng}) => Lago(sheetOf('lago'), rng: rng);

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

// JavaScript: `p.dir < 0` (a missing dir is not)
num _dir(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num ? p['dir'] as num : 0;

// JavaScript: `a[i]` of a list that may be shorter (undefined): [_undefined]
const Object _undefined = Object();
Object? _at(List? l, int i) =>
    l != null && i >= 0 && i < l.length ? l[i] : _undefined;

// JavaScript: `"" + v` of a value that may be undefined
String _js0(Object? v) =>
    identical(v, _undefined) || v == null ? 'undefined' : '$v';

const int _white = 0xFFFFFFFF;
final int _foam = hexColour('#EAF6FA'),
    _clear = hexColour('#7FB4C8'),
    _pico = hexColour('#E88A2A'),
    _beak = hexColour('#F0C020'),
    _mast = hexColour('#5A3A1A'),
    _stem = hexColour('#2E8A34'),
    _heart = hexColour('#B85A14'),
    _brush = hexColour('#E8E8F0'),
    _star = hexColour('#F0C020'),
    _cross = hexColour('#C8401E'),
    _empty = hexColour('#C8C8D4'),
    _sack0 = hexColour('#B89858'),
    _sack1 = hexColour('#D8BE80'),
    _sack2 = hexColour('#8A6E3A');

// lago.js: COLOR. Light orange-red, middle blue, dark blue-green: the three differ in lightness too
final Map<String, List<int>> COLOR = {
  'rojo': ['#C8401E', '#F4683C', '#FFA07A'].map(hexColour).toList(),
  'azul': ['#1A3C8E', '#2A5CC8', '#5A8AE8'].map(hexColour).toList(),
  'verde': ['#2A520E', '#4A8420', '#7AB03C'].map(hexColour).toList(),
  'pardo': ['#4A3A1E', '#7A6234', '#A88E58'].map(hexColour).toList(),
  'amarillo': ['#B8860C', '#F0B81C', '#FFD84A'].map(hexColour).toList(),
  'blanco': ['#B8B8C8', '#E6E6F0', '#FFFFFF'].map(hexColour).toList(),
  'negro': ['#16161E', '#30303C', '#50505E'].map(hexColour).toList(),
  'naranja': ['#B85A14', '#E88A2A', '#F8B860'].map(hexColour).toList(),
  'madera': ['#8A5A2A', '#B8854A', '#D8AA70'].map(hexColour).toList(),
};

/* ---------- the animals and the things ---------- */

// lago.js: mkPato. A duck, side on. nada: on the water, feet hidden; vuela: wings out; anda: on its feet
Sprite mkPato(String k, String pose, int f) {
  final C = COLOR[k]!, b = Buf(26, 22);
  const X = 11, Y = 12;
  final pico = _pico;
  if (pose == 'vuela') {
    b.ell(X, Y, 8, 4, C);
    b.ell(X + 8, Y - 3, 3.6, 3.2, C);
    b.rect(X + 11, Y - 3, 4, 2, pico);
    b.px(X + 9, Y - 4, k == 'negro' ? _white : OUT);
    if (f != 0) {
      b.cap(X - 2, Y - 2, X - 8, Y - 10, 2.4, [C[2]]);
      b.cap(X + 1, Y - 2, X - 3, Y - 11, 2.2, [C[1]]);
    } else {
      b.cap(X - 2, Y, X - 9, Y + 6, 2.4, [C[2]]);
      b.cap(X + 1, Y, X - 4, Y + 7, 2.2, [C[1]]);
    }
    b.rect(X - 9, Y + 1, 3, 2, C[1]);
    return b.outline().done();
  }
  b.ell(X, Y + 1, 8, 5, C);
  b.cap(X - 7, Y, X - 10, Y - 4, 1.6, [C[2]]);
  b.ell(X + 6, Y - 5, 3.6, 3.4, C);
  b.rect(X + 4, Y - 3, 4, 4, C[1]);
  b.rect(X + 9, Y - 5, 4, 2, pico);
  b.px(X + 7, Y - 6, k == 'negro' ? _white : OUT);
  b.ell(X - 1, Y + 1, 4, 2.4, [C[0], C[1]]);
  if (pose == 'anda') {
    final g = f != 0 ? 1 : 0;
    b.rect(X - 3 + g, Y + 6, 2, 4, pico);
    b.rect(X + 2 - g, Y + 6, 2, 4, pico);
    b.rect(X - 4 + g, Y + 9, 4, 1, pico);
    b.rect(X + 1 - g, Y + 9, 4, 1, pico);
  }
  return b.outline().done();
}

// lago.js: mkPez
Sprite mkPez(String c) {
  final C = COLOR[c]!, b = Buf(18, 11);
  b.ell(8, 5, 6, 3.4, C);
  b.cap(13, 5, 16, 2, 1.4, [C[1]]);
  b.cap(13, 5, 16, 8, 1.4, [C[1]]);
  b.px(4, 4, OUT);
  b.px(4, 3, _white);
  b.rect(7, 2, 3, 1, C[0]);
  return b.outline().done();
}

// lago.js: mkPajaro
Sprite mkPajaro(String c, int f, int vuela) {
  final C = COLOR[c]!, b = Buf(15, 12);
  b.ell(6, 7, 4.4, 3.2, C);
  b.ell(10, 4.5, 2.8, 2.6, C);
  b.px(11, 4, c == 'negro' ? _white : OUT);
  b.rect(13, 5, 2, 1, _beak);
  b.cap(2, 7, 0, 5, 1.2, [C[0]]);
  if (vuela != 0) {
    if (f != 0) {
      b.cap(6, 6, 3, 0, 1.8, [C[2]]);
    } else {
      b.cap(6, 8, 3, 11, 1.6, [C[2]]);
    }
  } else {
    b.ell(5, 7, 2.6, 1.8, [C[0], C[1]]);
    b.rect(6, 10, 1, 2, _beak);
    b.rect(8, 10, 1, 2, _beak);
  }
  return b.outline().done();
}

// lago.js: mkBote. A toy boat: a hull and one sail, all one colour (madera: bare wood, a white sail)
Sprite mkBote(String c) {
  final C = COLOR[c]!,
      b = Buf(20, 20),
      V = c == 'madera' ? COLOR['blanco']! : C;
  b.rect(9, 2, 1, 13, _mast);
  for (var y = 0; y < 11; y++) {
    b.rect(10, 3 + y, 1 + (y * .7).floor(), 1, V[y < 3 ? 2 : 1]);
  }
  for (var y = 0; y < 8; y++) {
    b.rect(8 - (y * .5).floor(), 6 + y, (y * .5).floor() + 1, 1, V[2]);
  }
  b.rect(2, 15, 16, 2, C[1]);
  b.rect(3, 17, 14, 1, C[1]);
  b.rect(4, 18, 12, 1, C[0]);
  b.rect(2, 15, 16, 1, C[2]);
  return b.outline().done();
}

// lago.js: mkPote
Sprite mkPote(String c) {
  final C = COLOR[c]!, b = Buf(16, 16);
  b.rect(1, 4, 14, 11, hexColour('#C8C8D4'));
  b.rect(1, 4, 3, 11, hexColour('#E8E8F0'));
  b.ell(8, 4, 7, 2.6, [C[0], C[1], C[2]]);
  b.rect(3, 8, 10, 5, C[1]);
  b.rect(3, 8, 10, 1, C[2]);
  return b.outline().done();
}

// lago.js: mkPan
Sprite mkPan() {
  final b = Buf(11, 10), crumb = hexColour('#F4E2B4');
  b.rect(1, 2, 9, 7, crumb);
  b.ell(3.5, 2.5, 2.6, 2, [crumb]);
  b.ell(7.5, 2.5, 2.6, 2, [crumb]);
  b.rect(1, 8, 9, 1, hexColour('#B07A3C'));
  b.rect(1, 3, 1, 6, hexColour('#C8904A'));
  b.rect(9, 3, 1, 6, hexColour('#C8904A'));
  b.px(4, 5, hexColour('#E0C890'));
  b.px(6, 6, hexColour('#E0C890'));
  return b.outline().done();
}

// lago.js: mkBolsa
Sprite mkBolsa() {
  final b = Buf(12, 13);
  b.rect(1, 3, 10, 9, hexColour('#C8A468'));
  b.rect(1, 3, 3, 9, hexColour('#D8B67A'));
  b.rect(1, 3, 10, 2, hexColour('#B08A54'));
  for (final p in const [
    [2, 0],
    [5, 1],
    [8, 0],
  ]) {
    b.ell(p[0] + 1, p[1] + 2, 1.8, 1.6, [
      hexColour('#D8AA70'),
      hexColour('#F0D8A8'),
    ]);
  }
  return b.outline().done();
}

/// The pixels of each of the sheet's `front` parts (set-kit.js `PART_TAGS`: the part of the set that drew a pixel
/// last), by set key, then by part. A state's are the same on every engine.
final Map<String, Map<String, Int32List>> _frontPixels = {};

/// Where the set's water shows, by set key (lago-set.html `waterShown`: the surface, kind water, and nothing standing
/// over it: `bakedZ` is the ground's). A state's are the same on every engine.
final Map<String, Uint8List> _waterShownOf = {};

class Lago extends Escena implements SetScene, SetOverSprites, PairPlaces {
  /// [rng] is the game's one random source (lago.js mueven and rina: `Math.random()`): the story runner's. A scene made
  /// without it (a picture, a test of its sprites) draws no random number.
  Lago(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = LagoPlaces(sheet, lagoEngine());
    final p = _p;
    // lago.js:17 POSTE (moves line 17: POSTE=[152,146] -> POSTE=[166,156], past the dock's end); PM (sheet:
    // points.postes, the mooring posts' tops at the old points); ORILLA (moves line 17, Carmen's far bank on the right
    // bank: ORILLA=[178,116] -> ORILLA=[188,109]). MUELLE and JUNCOS were the background's and the boxes' only (code
    // line 17): the dock and the reeds are the set's, their boxes the sheet's. AGUA (118, where the old water started)
    // is kept as lago.js:115 uses it: the row the fish at the surface is sorted by, not a place.
    POSTE = [for (final v in p.to(17, 'POSTE=[152,146]')) v.toInt()];
    PM = [
      for (final t in p.pts('postes')) [_round(t[0]), _round(t[1])],
    ];
    ORILLA = [for (final v in p.to(17, 'ORILLA=[178,116]')) v.toInt()];
    // lago.js:60 LUGAR (sheet: lugar, the frog's spots frog.inicio, frog.muelle)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // lago.js:61 FX, FY (moves line 61: FX=[46,68,90],FY=165 -> FX=[46,66,85],FY=165,FYB=[154,164,174]: the boats'
    // row on the planks); SALE (sheet: spots sale.0 to sale.2, unchanged); PEGA (moves line 61, where a drifting boat
    // sticks in the reeds)
    final fx = p.to(61, 'FX=[46,68,90],FY=165');
    FX = [fx[0].toInt(), fx[1].toInt(), fx[2].toInt()];
    FY = fx[3].toInt();
    FYB = [fx[4].toInt(), fx[5].toInt(), fx[6].toInt()];
    SALE = [for (var i = 0; i < 3; i++) p.spot('sale.$i')];
    final pega = p.to(61, 'PEGA=[[182,166],[196,172],[210,168],[190,178]]');
    PEGA = [
      for (var i = 0; i < pega.length; i += 2)
        [pega[i].toInt(), pega[i + 1].toInt()],
    ];
    // lago.js:62 slotC (moves line 62: the row at Carmen's feet on the right bank: const SLOTC=[[160,122],...],
    // slotC=i=>SLOTC[Math.min(i,11)]; its last number is the 11)
    final sl = p.to(62, 'const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];');
    SLOTC = [
      for (var i = 0; i + 1 < sl.length - 1; i += 2)
        [sl[i].toInt(), sl[i + 1].toInt()],
    ];
    _slotMax = sl.last.toInt();
    // lago.js:63 P7 (moves line 63: const P7=i=>[134+(i-1)*9.5,177+(i-1)*2] -> [156+(i-1)*4.5,186+(i-1)*1]); OFF and
    // PK unchanged (code line 63)
    _p7 = p.to(
      63,
      'const P7=i=>[134+(i-1)*9.5,177+(i-1)*2]',
      RegExp(r'\[([\d.]+)\+\(i-1\)\*([\d.]+),([\d.]+)\+\(i-1\)\*([\d.]+)\]'),
    );
    // lago.js:121 the row of bread (moves line 121: L.push({y:158,d:()=>c.drawImage(spr("pan",mkPan),54+i*12-5,149)}),
    // on the planks, in front of the people)
    _fila = p.to(
      121,
      'L.push({y:FY+1,d:()=>c.drawImage(spr("pan",mkPan),36+i*12-5,FY-8)})',
      RegExp(r'y:(\d+),.*mkPan\),(\d+)\+i\*(\d+)-(\d+),(\d+)\)'),
    );
    // lago.js:86 the fish's circle (moves line 86); :87 the fish beside a boat (moves line 87)
    _circula = p.to(86, 'o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t)');
    _sigue = p.to(87, 'const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;');
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _talk = sheet.talk!;
    _ring = sheet.helps!.ring;
    // lago.js:65 to :77 COSAS (sheet: code lines 76 and 77, things.<id>.box, hand and hintBox; lines 65, 68 to 75: the
    // children's, the ducks', the birds', the boats', the fish's, Canelo's and the flower's boxes relative to them,
    // unchanged)
    cosas = [
      for (final id in const ['luis', 'carmen']) persona(id),
      for (final n in PK) patoCosa(n),
      for (final n in const ['blanco', 'negro']) aveCosa(n),
      for (final c in const ['rojo', 'azul', 'verde']) boteCosa(c),
      Thing(
        id: 'pez',
        z: true,
        m: 3,
        si: (w) {
          final p = w['peces'] as Map<String, dynamic>?;
          return p != null && p['a'] != null && (p['a'] as Map)['vis'] != 0;
        },
        box: (Map<String, dynamic> w) {
          final o = (w['peces'] as Map)['a'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 11,
            _round(o['y'] as num) - 10 - _n(o['dy']),
            22,
            18,
          ];
        },
      ),
      Thing(
        id: 'pajaro',
        z: true,
        m: 3,
        si: (w) {
          final a = w['aves'] as Map<String, dynamic>?;
          return a != null && a['a'] != null && (a['a'] as Map)['vis'] != 0;
        },
        box: (Map<String, dynamic> w) {
          final o = (w['aves'] as Map)['a'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 10,
            _round(o['y'] as num) - 15,
            20,
            18,
          ];
        },
      ),
      Thing(
        id: 'perro',
        si: (w) => jsTruthy(w['perro']) && (w['perro'] as Map)['vis'] != 0,
        box: (Map<String, dynamic> w) {
          final o = w['perro'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 14,
            _round(o['y'] as num) - 14,
            28,
            16,
          ];
        },
        m: 1,
      ),
      Thing(
        id: 'flor',
        si: (w) => jsTruthy(w['flor']),
        box: (Map<String, dynamic> w) {
          final f = w['flor'] as List;
          return [(f[0] as num) - 5, (f[1] as num) - 16, 10, 17];
        },
        m: 2,
      ),
      for (final (id, m) in const [
        ('juncos', 0),
        ('poste', 1),
        ('muelle', 0),
        ('agua', 0),
        ('lago', 0),
      ])
        Thing(
          id: id,
          box: p.box(id),
          hand: p.hand(id),
          hintBox: p.hintBox(id),
          m: m,
        ),
    ];
  }

  @override
  final Sheet sheet;

  late final LagoPlaces _p;

  @override
  String get id => 'lago';

  @override
  PpEngine newEngine({bool still = false}) => lagoEngine(still: still);

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
  void fx(Map<String, dynamic> e) => host.fx(e);
  Sprite spr(String k, Sprite Function() make) => host.lib.spr(k, make);

  /* ---------- the set ---------- */

  // the sheet's setKey table: one baked state ("lago") for every W
  @override
  String setKey(Map<String, dynamic> W) => const LagoState().key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = LagoSet(e, b, LagoState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the reeds', the post's and
    // the mooring posts' own pixels)
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
    _waterShownOf[key] ??= _waterOf(e);
  }

  // lago-set.html: waterShown, for every pixel of the baked state in [e]
  static Uint8List _waterOf(PpEngine e) {
    final n = e.W * e.H, out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      if (e.kinds[i] == KIND_WATER && e.bakedZ[i] == e.groundZ[i]) out[i] = 1;
    }
    return out;
  }

  // lago-set.html: waterShown(x, y). A scene that has not baked its state yet (a player with no screen) bakes it once
  // on an engine of its own to know
  bool waterShown(int x, int y) {
    if (x < 0 || y < 0 || x >= 240 || y >= 216) return false;
    final key = setKey(W);
    var m = _waterShownOf[key];
    if (m == null) {
      final e = lagoEngine();
      buildSetFor(e, PpBuild(e), key);
      m = _waterShownOf[key]!;
    }
    return m[y * 240 + x] != 0;
  }

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  // lago-preview.html: `LAGO_SET.surfaceAt(sx, sy).on`: the dock, the lawn or the water
  String _surf(num sx, num sy) => lagoSurfaceAt(_p.e, sx, sy).on;

  // the sheet's shadows, as lago-preview.html casts them (PV.casts): every shadow from the ground point (z 0) under the
  // screen point of the feet, only on the lawn and the planks (the water takes none: lago-set.html LOOK.noShade). The
  // frog (W.cq.vis, not .5 or less faded) at .3; each child shown and not .5 or less faded at .3, .65, 1, 1.35, 1.7
  // (sitting: to 1.35); Canelo at .25; a duck that walks, not over the water, at .2; a bird standing, not flying and not
  // on a post's top, not over the water, at .1; a boat on the dock at .15; each piece of the row of bread at .1; the
  // bread lying, not over the water, at .1; the bag and the sack at .15
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final e = _p.e, SH = sheet.shadows;
    ({double x, double y}) on(num sx, num sy) => e.unproject(sx, sy);
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q), g = on(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: SH['coqui']!.radius));
    }
    final nino = SH['people']!.radii!['nino']!;
    final G = W['gente'] as Map<String, dynamic>? ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0 || _atMostHalf(p['al'])) continue;
      final g = on(_round(p['x'] as num), _round(p['y'] as num) - 1);
      for (final z
          in jsTruthy(p['sent'])
              ? const [.3, .65, 1.0, 1.35]
              : const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: nino));
      }
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0) {
      final g = on(_round(pe['x'] as num), _round(pe['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .25, r: SH['perro']!.radius));
    }
    for (final v in ((W['patos'] as Map?) ?? const {}).values) {
      final o = v as Map<String, dynamic>?;
      if (o == null ||
          o['vis'] == 0 ||
          o['pose'] != 'anda' ||
          (o['dy'] is num && (o['dy'] as num) > 3)) {
        continue;
      }
      final x = _round(o['x'] as num), y = _round(o['y'] as num) - 1;
      if (_surf(x, y) != 'water') {
        final g = on(x, y);
        out.add((x: g.x, y: g.y, z: .2, r: SH['pato']!.radius));
      }
    }
    for (final v in ((W['aves'] as Map?) ?? const {}).values) {
      final o = v as Map<String, dynamic>?;
      if (o == null ||
          o['vis'] == 0 ||
          jsTruthy(o['vuela']) ||
          jsTruthy(o['ronda']) ||
          perched(o)) {
        continue;
      }
      final x = _round(o['x'] as num), y = _round(o['y'] as num) - 1;
      if (_surf(x, y) != 'water') {
        final g = on(x, y);
        out.add((x: g.x, y: g.y, z: .1, r: SH['ave']!.radius));
      }
    }
    for (final v in ((W['botes'] as Map?) ?? const {}).values) {
      final o = v as Map<String, dynamic>?;
      if (o == null || o['vis'] == 0 || o['en'] != 'muelle') continue;
      final g = on(_round(o['x'] as num), _round(o['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .15, r: SH['bote']!.radius));
    }
    for (var i = 0; i < _n(W['fila']); i++) {
      final p = breadAt(i), g = on(p[0], p[1] - 1);
      out.add((x: g.x, y: g.y, z: .1, r: SH['pan']!.radius));
    }
    final pan = W['pan'] as Map<String, dynamic>?;
    if (pan != null &&
        pan['con'] == null &&
        pan['vis'] != 0 &&
        _n(pan['z']) <= 1 &&
        _surf(_round(pan['x'] as num), _round(pan['y'] as num) - 1) !=
            'water') {
      final g = on(_round(pan['x'] as num), _round(pan['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .1, r: SH['pan']!.radius));
    }
    final bolsa = W['bolsa'];
    if (jsTruthy(bolsa)) {
      final b = bolsa as List, g = on(b[0] as num, (b[1] as num) - 1);
      out.add((x: g.x, y: g.y, z: .15, r: SH['bolsa']!.radius));
    }
    final saco = W['saco'];
    if (jsTruthy(saco)) {
      final s = saco as List, g = on(s[0] as num, (s[1] as num) - 1);
      out.add((x: g.x, y: g.y, z: .15, r: SH['saco']!.radius));
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  // lago-preview.html: PV.perched. A bird on a post's top (the mooring posts' or the post's): it perches, no shadow
  bool perched(Map<String, dynamic> o) {
    final x = _round(o['x'] as num), y = _round(o['y'] as num);
    final poste = _p.pt('poste');
    for (final t in [..._p.pts('postes'), poste]) {
      final dy = identical(t, poste) ? 0 : 1;
      if ((x - t[0]).abs() <= 2 && (y - (t[1] - dy)).abs() <= 2) return true;
    }
    return false;
  }

  // lago-preview.html: PV.breadAt. The row of bread's places, as the moved line draws them (moves line 121): [x, bottom
  // row] of piece i
  List<num> breadAt(int i) => [
    (_fila[1] + i * _fila[2] - _fila[3]) + 5,
    _fila[4] + 10,
  ];

  /* ---------- the reeds, the post and the mooring posts in front: the sheet's front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // the set as this frame shows it (wind, glints, shadows), before the sprite layer (drawFrame's step 4), and its depth
  // (lago-preview.html: `DEPTH.live()`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // lago-preview.html: vOf. The v = (x + y) / R2 of the surface under a screen point (sheet rules.floor: the planks', the
  // lawn's or the water's)
  double vOf(num sx, num sy) {
    final s = lagoSurfaceAt(_p.e, sx, sy);
    return (s.x + s.y) / math.sqrt2;
  }

  // lago-preview.html: PREVIEW.front (sheet: front). The set's own pixels of a part, again, inside each item drawn before
  // its entry in the sorted list ([lista], sorted), only where that pixel is nearer to the camera than the item: z[i] > v
  // / COS - (row + .5 - OY) * tan 30 / S, v of the surface under it (sheet front.boxes). A frame drawn with no set (a
  // player with no screen) has none to draw again.
  void front(String part, List<LagoItem> lista) {
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'lago: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final me = lista.indexWhere((o) => o.front == part);
    final pix = e.pix, W0 = e.W, H0 = e.H;
    for (final o in lista.sublist(0, me < 0 ? 0 : me)) {
      final r = frontBox(o, W);
      if (r == null) continue;
      final bx = r.box, v = r.v;
      final y0 = math.max(0, bx[1]),
          y1 = math.min(H0, bx[1] + bx[3]),
          x0 = math.max(0, bx[0]),
          x1 = math.min(W0, bx[0] + bx[2]);
      for (final i in list) {
        final y = i ~/ W0, x = i - y * W0;
        if (y < y0 || y >= y1 || x < x0 || x >= x1) continue;
        if (!(Z[i] > v / COS - (y + .5 - e.OY) * T30 / e.S)) continue;
        pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
      }
    }
  }

  // lago-preview.html: PREVIEW.frontBox. A list item's box and the v of the surface under it: a child [x - 24, y - 46 -
  // dy, 48, 49 + dy]; the frog frogBox with dy; Canelo [x - 16, y - 24 - dy, 32, 27 + dy]; a duck not flying [x - 14,
  // y - 23 - dy, 28, 26]; a boat [x - 12, y - 22, 24, 26]; the fish [x - 11, y - 9 - dy, 22, 16]; its surface under (x,
  // y - 1). Anything else (a bird, the bread, the bag, the sack: the preview's function gives none) is not drawn over
  ({List<num> box, double v})? frontBox(LagoItem o, Map<String, dynamic> w) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return (
        box: [b.x, b.y + _round(_n(q['dy'])), b.w, b.h],
        v: vOf(b.x + b.w / 2, (q['y'] as num) + 25),
      );
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>;
      final dy = _round(_n(p['dy'])),
          x = _round(p['x'] as num),
          y = _round(p['y'] as num);
      return (box: [x - 24, y - 46 - dy, 48, 49 + dy], v: vOf(x, y - 1));
    }
    if (o.k == 'perro') {
      final p = w['perro'] as Map<String, dynamic>, dy = _round(_n(p['dy']));
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return (box: [x - 16, y - 24 - dy, 32, 27 + dy], v: vOf(x, y - 1));
    }
    if (o.pato != null) {
      final p =
          (w['patos'] as Map<String, dynamic>?)?[o.pato]
              as Map<String, dynamic>?;
      if (p == null || p['pose'] == 'vuela') return null;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return (
        box: [x - 14, y - 23 - _round(_n(p['dy'])), 28, 26],
        v: vOf(x, y - 1),
      );
    }
    if (o.bote != null) {
      final p =
          (w['botes'] as Map<String, dynamic>)[o.bote] as Map<String, dynamic>;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return (box: [x - 12, y - 22, 24, 26], v: vOf(x, y - 1));
    }
    if (o.pez != null) {
      final p =
          (w['peces'] as Map<String, dynamic>)[o.pez] as Map<String, dynamic>;
      final x = _round(p['x'] as num), y = _round(p['y'] as num);
      return (
        box: [x - 11, y - 9 - _round(_n(p['dy'])), 22, 16],
        v: vOf(x, y - 1),
      );
    }
    return null;
  }

  /* ---------- the helps: El campo's ripple ring, the fish's patch (sheet: helps) ---------- */

  late final SheetRing _ring;

  // lago-preview.html: ringOn. Every pixel (x, y) with inner < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1
  // that shows the water takes the ring's colour
  void ringOn(Ctx c, num cx, num cy, num rx, num ry) {
    c.fillStyle = _ring.colour;
    for (var y = (cy - ry - 1).floor(); y <= (cy + ry + 1).ceil(); y++) {
      for (var x = (cx - rx - 1).floor(); x <= (cx + rx + 1).ceil(); x++) {
        final dx = (x + .5 - cx) / rx, dy = (y + .5 - cy) / ry;
        final d = dx * dx + dy * dy;
        if (d > _ring.inner && d <= 1 && waterShown(x, y)) {
          c.fillRect(x, y, 1, 1);
        }
      }
    }
  }

  // lago-preview.html: PV.ringWhere. Where a thing's ring goes, by kind, or null: a duck swimming (pose nada, or
  // flapping; not in the air: dy 3 at most; rx scaled .78 for the yellow one); a boat not on the dock (bobbing on the
  // water or in the reeds); the bread lying on the water (not carried, shown, z 1 at most, its point over the water).
  // The fish has its patch instead
  List<num>? ringWhere(String kind, Map<String, dynamic>? o) {
    if (kind == 'pato') {
      final o0 = o!, pose = o0['pose'];
      if ((pose != 'nada' && !jsTruthy(o0['aletea'])) ||
          _n(o0['dy']) > 3 ||
          pose == 'vuela' ||
          pose == 'anda') {
        return null;
      }
      final s = o0['k'] == 'amarillo' ? .78 : 1;
      final R = _ring.kind('pato');
      return [_round(o0['x'] as num), _round(o0['y'] as num), R.rx * s, R.ry];
    }
    if (kind == 'bote') {
      final o0 = o!;
      if (o0['en'] == 'muelle') return null;
      final bob = o0['en'] == 'agua' || o0['en'] == 'juncos'
          ? ((F >> 3) % 2)
          : 0;
      final R = _ring.kind('bote');
      return [_round(o0['x'] as num), _round(o0['y'] as num) + bob, R.rx, R.ry];
    }
    if (kind == 'pez') return null; // the fish has its patch (patch)
    if (kind == 'pan') {
      if (o == null || o['con'] != null || o['vis'] == 0 || _n(o['z']) > 1) {
        return null;
      }
      final x = _round(o['x'] as num), y = _round(o['y'] as num);
      if (_surf(x, y - 1) != 'water') return null;
      final R = _ring.kind('pan');
      return [x, y, R.rx, R.ry];
    }
    return null;
  }

  // lago-preview.html: PREVIEW.ring (sheet helps.lines: pato, bote, the bread on the water)
  void ring(Ctx c, String kind, Map<String, dynamic>? o) {
    final r = ringWhere(kind, o);
    if (r != null) ringOn(c, r[0], r[1], r[2], r[3]);
  }

  // lago-preview.html: the 4 x 4 Bayer matrix of PV.patchAt
  static const List<int> _bayer16 = [
    0,
    8,
    2,
    10,
    12,
    4,
    14,
    6,
    3,
    11,
    1,
    9,
    15,
    7,
    13,
    5,
  ];

  // lago-preview.html: hs (pp-engine.js hash)
  static double _hs(num a, num b) {
    final s = math.sin(a * 127.1 + b * 311.7) * 43758.5453;
    return s - s.floorToDouble();
  }

  // lago-preview.html: PV.patchAt (sheet helps.ring.pez). The colour of the fish's patch at (x, y), or null: an ellipse
  // of lighter water centred on the fish; its outer soft px break into the lake by a Bayer dither; inside it the lake's
  // own ripple dashes go on (waterPixel's rows and runs) in the patch's dash colour
  int? patchAt(Map<String, dynamic> o, int x, int y) {
    final H = _ring.patch('pez');
    final cx = _round(o['x'] as num) + H.centre[0],
        cy = _round(o['y'] as num) + H.centre[1],
        dx = x + .5 - cx,
        dy = y + .5 - cy,
        ex = dx / H.rx,
        ey = dy / H.ry,
        d = math.sqrt(ex * ex + ey * ey);
    if (d > 1) return null;
    final gx = dx / (H.rx * H.rx), gy = dy / (H.ry * H.ry);
    final g = math.sqrt(gx * gx + gy * gy) / math.max(d, 1e-6),
        t = (1 - d) / g; // t: px inside its edge
    // its edge breaks into the lake by dither
    if (t < H.soft && _bayer16[(y & 3) * 4 + (x & 3)] / 16 >= t / H.soft) {
      return null;
    }
    final rowH = _hs(y * 7, 13),
        run = ((x + rowH * 40) / (5 + (rowH * 4).truncate())).floor();
    return _hs(run, y) < .16 && _hs(run * 3, y + 1) > .3 ? H.dash : H.patch;
  }

  // lago-preview.html: PREVIEW.patch (sheet helps.lines: pez). The fish at the surface (dy 4 at most) swims in its pale
  // patch, only where the water shows
  void patch(Ctx c, Map<String, dynamic>? o) {
    if (o == null || _n(o['dy']) > 4) return;
    final H = _ring.patch('pez');
    final ox = _round(o['x'] as num), oy = _round(o['y'] as num);
    for (var y = (oy - H.ry - 2).floor(); y <= (oy + H.ry + 2).ceil(); y++) {
      for (var x = (ox - H.rx - 2).floor(); x <= (ox + H.rx + 2).ceil(); x++) {
        if (!waterShown(x, y)) continue;
        final col = patchAt(o, x, y);
        if (col != null) {
          c.fillStyle = col;
          c.fillRect(x, y, 1, 1);
        }
      }
    }
  }

  /* ---------- where things are ---------- */

  // lago.js: AGUA (where the old water started: the row lago.js:115 sorts the fish at the surface by)
  static const int AGUA = 118;

  // lago.js: POSTE, PM, ORILLA
  late final List<int> POSTE, ORILLA;
  late final List<List<int>> PM;

  // lago.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // lago.js: FX, FY, FYB, SALE, PEGA
  late final List<int> FX, FYB;
  late final int FY;
  late final List<List<int>> SALE, PEGA;

  // lago.js: slotC (moves line 62: SLOTC, slotC=i=>SLOTC[Math.min(i,11)])
  late final List<List<int>> SLOTC;
  late final int _slotMax;
  List<int> slotC(int i) => SLOTC[math.min(i, _slotMax)];

  // lago.js: P7 (moves line 63), OFF, PK
  late final List<num> _p7;
  List<num> P7(num i) => [_p7[0] + (i - 1) * _p7[1], _p7[2] + (i - 1) * _p7[3]];
  static const List<List<int>> OFF = [
    [-14, -9],
    [14, -7],
    [0, 12],
  ];
  static const List<String> PK = ['blanco', 'negro', 'amarillo'];

  // the numbers of the moved lines 121 (the row of bread), 86 (the fish's circle) and 87 (the fish beside a boat)
  late final List<num> _fila, _circula, _sigue;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  // lago.js: G
  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic> get _patos => W['patos'] as Map<String, dynamic>;
  Map<String, dynamic> get _aves => W['aves'] as Map<String, dynamic>;
  Map<String, dynamic> get _botes => W['botes'] as Map<String, dynamic>;
  Map<String, dynamic>? _pato(String k) => _patos[k] as Map<String, dynamic>?;
  Map<String, dynamic>? _ave(String k) => _aves[k] as Map<String, dynamic>?;
  Map<String, dynamic>? _bote(String k) =>
      (W['botes'] as Map<String, dynamic>?)?[k] as Map<String, dynamic>?;
  Map<String, dynamic>? _pez(String k) =>
      (W['peces'] as Map<String, dynamic>?)?[k] as Map<String, dynamic>?;

  // lago.js: QUIEN
  static final Map<String, Who> QUIEN = {
    'luis': FAM['hermano']!,
    'carmen': FAM['hermana']!,
  };

  // lago.js: alto
  int alto(String id) {
    if (!QUIEN[id]!.nino) return 56;
    final p = G(id);
    return p != null && jsTruthy(p['sent']) ? 40 : 44;
  }

  // lago.js: caja
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

  // lago.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // lago.js: patoCosa
  Thing patoCosa(String n) => Thing(
    id: 'pato_$n',
    z: true,
    m: 0,
    si: (w) {
      final p = w['patos'] as Map<String, dynamic>?;
      return p != null && p[n] != null && (p[n] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) {
      final o = (w['patos'] as Map)[n] as Map<String, dynamic>;
      return [
        _round(o['x'] as num) - 12,
        _round(o['y'] as num) - 17 - _n(o['dy']),
        24,
        18,
      ];
    },
  );

  // lago.js: aveCosa
  Thing aveCosa(String n) => Thing(
    id: 'ave_$n',
    z: true,
    m: 3,
    si: (w) {
      final a = w['aves'] as Map<String, dynamic>?;
      return a != null && a[n] != null && (a[n] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) {
      final o = (w['aves'] as Map)[n] as Map<String, dynamic>;
      return [_round(o['x'] as num) - 10, _round(o['y'] as num) - 15, 20, 18];
    },
  );

  // lago.js: boteCosa
  Thing boteCosa(String c) => Thing(
    id: 'bote_$c',
    z: true,
    m: 1,
    si: (w) {
      final b = w['botes'] as Map<String, dynamic>?;
      return b != null && jsTruthy(b['f_$c']);
    },
    box: (Map<String, dynamic> w) {
      final o = (w['botes'] as Map)['f_$c'] as Map<String, dynamic>;
      return [_round(o['x'] as num) - 10, _round(o['y'] as num) - 20, 20, 22];
    },
  );

  // lago.js: COSAS
  @override
  late final List<Thing> cosas;

  // lago.js: fresh
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'gente': <String, dynamic>{},
    'patos': <String, dynamic>{},
    'peces': <String, dynamic>{},
    'aves': <String, dynamic>{},
    'botes': <String, dynamic>{},
    'pan': null,
    'fila': 0,
    'bolsa': null,
    'saco': null,
    'flor': null,
    'perro': null,
    'pincel': null,
    'tarjeta': null,
    'marcas': null,
    'salpica': null,
    'lugarP': 0,
    'orden': null,
    'ladron': null,
    'pregunto': 0,
    'nb': 0,
    'enC': 0,
    'enJ': 0,
    'cq': <String, dynamic>{
      'x': LUGAR['inicio']![0],
      'y': LUGAR['inicio']![1],
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
  };

  /* ---------- drawing ---------- */

  // lago.js: anima. Things that go on moving while he chooses: a bird or the duck flying round, the duck paddling round
  // the post, a fish swimming to and fro or in a circle, things on their way somewhere
  void anima() {
    for (final v in ((W['aves'] as Map?) ?? const {}).values.toList()) {
      final o = v as Map<String, dynamic>?;
      if (o == null) continue;
      if (jsTruthy(o['ronda'])) {
        final t = F / 16 + _n(o['fase']);
        o['x'] = 150 + 46 * math.cos(t);
        o['y'] = 58 + 16 * math.sin(t);
        o['dir'] = math.sin(t) < 0 ? 1 : -1;
        o['vuela'] = 1;
      } else if (jsTruthy(o['sale'])) {
        o['x'] = (o['x'] as num) + 2.2;
        o['y'] = (o['y'] as num) - 1.1;
        o['vuela'] = 1;
        o['dir'] = 1;
        if ((o['x'] as num) > 250) o['vis'] = 0;
      }
    }
    for (final v in ((W['patos'] as Map?) ?? const {}).values.toList()) {
      final o = v as Map<String, dynamic>?;
      if (o == null) continue;
      if (jsTruthy(o['ronda'])) {
        final t = F / 16 + _n(o['fase']);
        o['x'] = 150 + 46 * math.cos(t);
        o['y'] = 58 + 16 * math.sin(t);
        o['dir'] = math.sin(t) < 0 ? 1 : -1;
        o['pose'] = 'vuela';
      } else if (jsTruthy(o['rema'])) {
        // round the post (moves line 17: POSTE)
        final t = F / 22 + _n(o['fase']);
        o['x'] = POSTE[0] + 20 * math.cos(t);
        o['y'] = POSTE[1] + 16 + 7 * math.sin(t);
        o['dir'] = math.sin(t) < 0 ? 1 : -1;
        o['pose'] = 'nada';
      } else if (jsTruthy(o['sale'])) {
        o['sale'] = (o['sale'] as num) + 1;
        o['dir'] = 1;
        if ((o['sale'] as num) < 26) {
          o['x'] = (o['x'] as num) + 1.3;
          o['pose'] = 'nada';
        } else {
          o['x'] = (o['x'] as num) + 2.2;
          o['y'] = (o['y'] as num) - 2;
          o['pose'] = 'vuela';
        }
        if ((o['x'] as num) > 250 || (o['y'] as num) < -10) o['vis'] = 0;
      }
    }
    for (final v in ((W['peces'] as Map?) ?? const {}).values.toList()) {
      final o = v as Map<String, dynamic>?;
      if (o == null) continue;
      if (jsTruthy(o['vaiven'])) {
        final t = F / 14;
        o['x'] = (o['x0'] as num) + 12 * math.sin(t);
        o['dir'] = math.cos(t) > 0 ? 1 : -1;
      } else if (jsTruthy(o['circula'])) {
        // moves line 86: o.x=132+8*Math.cos(t);o.y=190+4*Math.sin(t)
        final t = F / 12;
        o['x'] = _circula[0] + _circula[1] * math.cos(t);
        o['y'] = _circula[2] + _circula[3] * math.sin(t);
        o['dir'] = math.sin(t) < 0 ? 1 : -1;
      } else if (jsTruthy(o['sale'])) {
        o['x'] = (o['x'] as num) + 1.8;
        o['dir'] = 1;
        if ((o['x'] as num) > 236) o['vis'] = 0;
      } else if (jsTruthy(o['sigue']) &&
          jsTruthy(_bote(o['sigue'] as String))) {
        // moves line 87: const b=W.botes[o.sigue];o.x=b.x+10;o.y=b.y+12;
        final b = _bote(o['sigue'] as String)!;
        o['x'] = (b['x'] as num) + _sigue[0];
        o['y'] = (b['y'] as num) + _sigue[1];
        o['dir'] = 1;
      }
    }
    for (final v in ((W['botes'] as Map?) ?? const {}).values.toList()) {
      final o = v as Map<String, dynamic>?;
      if (o == null || !jsTruthy(o['meta'])) continue;
      final meta = o['meta'] as List;
      final dx = (meta[0] as num) - (o['x'] as num),
          dy = (meta[1] as num) - (o['y'] as num),
          d = math.sqrt(dx * dx + dy * dy),
          vv = _or(meta.length > 2 ? meta[2] : null, 1.5);
      if (d <= vv) {
        o['x'] = meta[0];
        o['y'] = meta[1];
        o['meta'] = null;
      } else {
        o['x'] = (o['x'] as num) + dx / d * vv;
        o['y'] = (o['y'] as num) + dy / d * vv;
      }
    }
  }

  // lago.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        d = _dir(p) < 0 ? -1 : 1,
        h = alto(id);
    final pose = p['pose'] == 'wave'
        ? 'wave${a % 2}'
        : p['pose'] == 'arriba'
        ? 'wave0'
        : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
    final sent = jsTruthy(p['sent']);
    final im = spr(
      'pc$id$pose$habla${sent ? 1 : 0}',
      () => mkPersona(QUIEN[id]!, pose, habla != 0, sent),
    );
    c.save();
    c.translate(
      x.toDouble(),
      (y -
              im.h +
              1 +
              ((jsTruthy(p['paso']) && a % 2 != 0) ||
                      (jsTruthy(p['rie']) && a % 2 != 0)
                  ? -1
                  : 0) -
              _n(p['dy']))
          .toDouble(),
    );
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    if (p['lleva'] == 'bolsa') {
      c.drawImage(spr('bolsa', mkBolsa), x + d * 6 - 6, y - h + 22);
    }
    if (jsTruthy(p['pan'])) {
      c.drawImage(spr('pan', mkPan), x + d * 9 - 5, y - h + 22);
    }
    // boats in his hands
    final botes = (p['botes'] as List?) ?? const [];
    for (var i = 0; i < botes.length; i++) {
      final k = botes[i] as String, im2 = spr('bt$k', () => mkBote(k));
      c.drawImage(im2, x + d * (8 + i * 9) - 10, y - h + 10 + i * 2);
    }
    if (jsTruthy(p['pincel'])) {
      fr(c, x + d * 14, y - h + 12, 1, 8, _mast);
      fr(
        c,
        x + d * 14 - 1,
        y - h + 19,
        3,
        3,
        COLOR[p['pincel']] != null ? COLOR[p['pincel']]![1] : _brush,
      );
    }
  }

  // lago.js: pato
  void pato(Ctx c, Map<String, dynamic>? o, int a) {
    if (o == null || o['vis'] == 0) return;
    // sheet helps.lines: its ripple ring first
    ring(c, 'pato', o);
    final anim =
        o['pose'] == 'vuela' ||
        o['pose'] == 'anda' ||
        jsTruthy(o['come']) ||
        jsTruthy(o['aletea']);
    final f = anim ? (a >> 1) % 2 : 0,
        pose = jsTruthy(o['aletea'])
            ? 'vuela'
            : (jsTruthy(o['pose']) ? o['pose'] as String : 'nada'),
        k = o['k'] as String,
        im = spr('pt$k$pose$f', () => mkPato(k, pose, f)),
        d = _dir(o) < 0 ? -1 : 1,
        s = k == 'amarillo' ? .78 : 1.0,
        x = _round(o['x'] as num),
        y = _round(o['y'] as num) - _n(o['dy']);
    c.save();
    c.translate(x.toDouble(), y.toDouble());
    if (d < 0) c.scale(-1, 1);
    c.scale(s, s);
    if (pose == 'nada') {
      c.drawImageRect(
        im,
        0,
        0,
        26,
        18,
        -13,
        -18 + (jsTruthy(o['come']) && f != 0 ? 2 : 0),
        26,
        18,
      );
    } else {
      c.drawImage(im, -13, -21);
    }
    c.restore();
    if (pose == 'nada') {
      // the water line; a wake behind it
      fr(c, x - _round(11 * s), y, _round(22 * s), 1, _foam);
      if ((F >> 3) % 2 != 0) {
        fr(c, x - d * _round(14 * s) - 2, y + 1, 4, 1, _foam);
      }
    }
  }

  // lago.js: pez
  void pez(Ctx c, Map<String, dynamic>? o) {
    if (o == null || o['vis'] == 0) return;
    // sheet helps.lines: its pale patch first
    patch(c, o);
    final col = o['c'] as String;
    final im = spr('pz$col', () => mkPez(col)),
        d = _dir(o) < 0 ? -1 : 1,
        x = _round(o['x'] as num),
        y = _round(o['y'] as num) - _round(_n(o['dy'])),
        fuera = _n(o['dy']) > 4;
    c.save();
    c.translate(x.toDouble(), y.toDouble());
    if (d > 0) c.scale(-1, 1);
    if (fuera) c.rotate(-.5);
    c.drawImage(im, -9, -6);
    c.restore();
    // just under the clear water: its colour shows
    if (!fuera) {
      fr(c, x - 9, y - 7, 18, 1, _foam);
      fr(c, x - 6, y + 5, 12, 1, _clear);
    }
  }

  // lago.js: ave
  void ave(Ctx c, Map<String, dynamic>? o, int a) {
    if (o == null || o['vis'] == 0) return;
    final f = (a >> 1) % 2,
        v = jsTruthy(o['vuela']) || jsTruthy(o['aletea']) ? 1 : 0,
        col = o['c'] as String,
        im = spr('pj$col$f$v', () => mkPajaro(col, f, v)),
        d = _dir(o) < 0 ? -1 : 1,
        y = _round(o['y'] as num) - _n(o['dy']);
    c.save();
    c.translate(_round(o['x'] as num).toDouble(), y.toDouble());
    if (d < 0) c.scale(-1, 1);
    c.drawImage(im, -7, -12);
    c.restore();
    if (jsTruthy(o['pan'])) {
      c.drawImage(spr('pan', mkPan), _round(o['x'] as num) + d * 9 - 5, y - 11);
    }
  }

  // lago.js: bote
  void bote(Ctx c, Map<String, dynamic>? o) {
    if (o == null || o['vis'] == 0) return;
    // sheet helps.lines: its ripple ring first
    ring(c, 'bote', o);
    final col = o['c'] as String;
    final im = spr('bt$col', () => mkBote(col)),
        x = _round(o['x'] as num),
        y = _round(o['y'] as num),
        enAgua = o['en'] == 'agua' || o['en'] == 'juncos',
        bob = enAgua ? ((F >> 3) % 2) : 0;
    c.save();
    c.translate(x.toDouble(), (y + bob).toDouble());
    if (o['en'] == 'juncos') c.rotate(.3);
    c.drawImage(im, -10, -19);
    c.restore();
    if (enAgua) fr(c, x - 10, y + bob, 20, 1, _foam);
  }

  // lago.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0,
        dy = _round(q['dy'] as num);
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    final pan = W['pan'] as Map<String, dynamic>?;
    if (pan != null && pan['con'] == 'cq') {
      g.drawImage(
        spr('pan', mkPan),
        b.x + (b.w.toInt() >> 1) - 5,
        b.y + dy + b.h - 11,
      );
    }
    final pincel = W['pincel'];
    if (jsTruthy(pincel)) {
      fr(g, b.x + b.w - 4, b.y + dy + 10, 1, 9, _mast);
      fr(
        g,
        b.x + b.w - 5,
        b.y + dy + 8,
        3,
        3,
        COLOR[pincel] != null ? COLOR[pincel]![1] : _brush,
      );
    }
  }

  // lago.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // lago.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    anima();
    // lago.js:112 c.drawImage(spr("lago",fondo),0,0) -> the set, for setKey(W) (sheet: dropped)
    final flor = W['flor'] as List?;
    if (flor != null) {
      final x = flor[0] as num, y = flor[1] as num;
      fr(c, x, y - 10, 1, 10, _stem);
      fr(c, x - 3, y - 5, 3, 2, _stem);
      for (final d in const [
        [-3, -14],
        [1, -14],
        [-3, -10],
        [1, -10],
        [-1, -16],
        [-1, -9],
        [-4, -12],
        [2, -12],
      ]) {
        fr(c, x + d[0], y + d[1], 3, 3, COLOR['amarillo']![1]);
      }
      fr(c, x - 1, y - 13, 3, 3, _heart);
    }
    // everyone, from the back to the front; each item says who or what it is (sheet front.tags, for the front masks)
    final L = <LagoItem>[];
    final peces = (W['peces'] as Map<String, dynamic>?) ?? const {};
    for (final k in peces.keys) {
      final o = peces[k] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0) {
        L.add(
          LagoItem(
            _n(o['dy']) > 4 ? (o['y'] as num) + 40 : AGUA + 1,
            () => pez(c, o),
            pez: k,
          ),
        );
      }
    }
    // lago.js:116, the old reeds (mkJunco), is dropped (sheet: dropped): the set's bed of reeds (front.juncos)
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(LagoItem(p['y'] as num, () => gente(c, id, a), id: id));
      }
    }
    final patos = (W['patos'] as Map<String, dynamic>?) ?? const {};
    for (final k in patos.keys) {
      final o = patos[k] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0) {
        L.add(
          LagoItem(
            o['pose'] == 'vuela' ? (o['y'] as num) + 200 : o['y'] as num,
            () => pato(c, o, a),
            pato: k,
          ),
        );
      }
    }
    final aves = (W['aves'] as Map<String, dynamic>?) ?? const {};
    for (final k in aves.keys) {
      final o = aves[k] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0) {
        L.add(LagoItem((o['y'] as num) + 200, () => ave(c, o, a), ave: k));
      }
    }
    final botes = (W['botes'] as Map<String, dynamic>?) ?? const {};
    for (final k in botes.keys) {
      final o = botes[k] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0) {
        L.add(
          LagoItem(
            (o['y'] as num) + (o['en'] == 'juncos' ? 14 : 1),
            () => bote(c, o),
            bote: k,
          ),
        );
      }
    }
    // lago.js:121 the row of bread (moves line 121: on the planks, in front of the people)
    for (var i = 0; i < _n(W['fila']); i++) {
      L.add(
        LagoItem(_fila[0], () {
          c.drawImage(
            spr('pan', mkPan),
            _fila[1] + i * _fila[2] - _fila[3],
            _fila[4],
          );
        }),
      );
    }
    final bolsa = W['bolsa'];
    if (jsTruthy(bolsa)) {
      final b = bolsa as List;
      L.add(
        LagoItem(b[1] as num, () {
          c.drawImage(
            spr('bolsa', mkBolsa),
            (b[0] as num) - 6,
            (b[1] as num) - 12,
          );
        }),
      );
    }
    final saco = W['saco'];
    if (jsTruthy(saco)) {
      final s = saco as List;
      L.add(
        LagoItem(s[1] as num, () {
          final x = s[0] as num, y = s[1] as num;
          fr(c, x - 8, y - 10, 16, 11, OUT);
          fr(c, x - 7, y - 9, 14, 9, _sack0);
          fr(c, x - 7, y - 9, 4, 9, _sack1);
          fr(c, x - 5, y - 12, 10, 3, _sack2);
        }),
      );
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0) {
      L.add(
        LagoItem(pe['y'] as num, () {
          final o = pe, pose = o['pose'] as String;
          final f = pose == 'bark' ? (a >> 1) % 2 : 0,
              im = spr('pe$pose$f', () => mkPerro(pose, f != 0));
          c.save();
          c.translate(
            _round(o['x'] as num).toDouble(),
            (_round(o['y'] as num) - im.h + 2).toDouble(),
          );
          if (_dir(o) < 0) c.scale(-1, 1);
          c.drawImage(im, -13, 0);
          c.restore();
        }, k: 'perro'),
      );
    }
    if (jsTruthy(q['vis'])) {
      L.add(LagoItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    final pan = W['pan'] as Map<String, dynamic>?;
    if (pan != null && pan['con'] == null && pan['vis'] != 0) {
      L.add(
        LagoItem(999, () {
          // sheet helps.lines: the bread on the water has its ring first
          ring(c, 'pan', pan);
          c.drawImage(
            spr('pan', mkPan),
            _round(pan['x'] as num) - 5,
            _round(pan['y'] as num) - _round(_n(pan['z'])) - 7,
          );
        }),
      );
    }
    // lago.js:127 the sorted list: the entries of the set's parts drawn again over whoever is behind them (sheet:
    // front.parts juncos, poste, muelle.postes, each sortY 9999, after everyone)
    late final List<LagoItem> sorted;
    for (final en in sheet.frontParts.entries) {
      final part = en.key;
      L.add(LagoItem(en.value.sortY!, () => front(part, sorted), front: part));
    }
    // JavaScript's sort is stable: the index breaks a tie
    final byRow = [...L.indexed]
      ..sort((m, n) {
        final d = m.$2.y.compareTo(n.$2.y);
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    sorted = [for (final o in byRow) o.$2];
    for (final o in sorted) {
      o.d();
    }
    for (final e in (W['salpica'] as List?) ?? const []) {
      final s = e as Map<String, dynamic>, t = F - (s['f'] as num);
      if (t < 10) {
        for (var i = 0; i < 7; i++) {
          final an = math.pi + i * math.pi / 6;
          fr(
            c,
            (s['x'] as num) + _round(math.cos(an) * (3 + t * 1.2)),
            (s['y'] as num) +
                _round(math.sin(an) * (2 + t * 1.4)) +
                _round(t * t * .12),
            2,
            2,
            i % 2 != 0 ? _clear : _white,
          );
        }
      }
    }
    // lago.js:129 a child's bubble, where the sheet's talk puts it
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
    // lago.js:130 the frog's bubble, where the sheet's talk puts it
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
  }

  // lago-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
  // head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view, clear
  // of the corner card shown (W.tarjeta: talk.board, + the view's x0) and of every face (each visible child's, sitting
  // or standing, and the frog's, its own too); if none is, [top].
  List<num> talkPlace(List<num> top, num h, Object? k, Map<String, dynamic> w) {
    if (!jsTruthy(k) || !sheet.bubbleRects.containsKey(k)) return top;
    final T = _talk, R = sheet.bubbleRects[k]!, x0 = host.cam[0];
    final faces = <List<num>>[], boards = <List<num>>[];
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final id = en.key, p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          (p['al'] != null && (p['al'] as num) < .5)) {
        continue;
      }
      final hd = T.heads[id + (jsTruthy(p['sent']) ? '.s' : '')]!;
      final flip = _dir(p) < 0,
          x = _round(p['x'] as num),
          y = _round(p['y'] as num) - _round(_n(p['dy']));
      final hx = flip ? x - hd.head + 1 : x + hd.head;
      faces.add([_round(hx - 6), y + hd.top + 5, 12, 10]);
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

  // lago.js: talkAt (relative to the child: unchanged)
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

  // lago.js: respIcon. The picture in an answer bubble: a pot of paint
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c, col = k.replaceFirst('pote_', '');
    if (COLOR[col] == null) return null;
    final im = spr('po$col', () => mkPote(col));
    g.smoothing = false;
    g.drawImage(im, x + _round(w / 2) - 14, y + 4, 28, 28);
    return null;
  }

  /* ---------- the card in the corner: three rounds; a star, or the mark of what went wrong ---------- */

  // lago.js: hud
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
        g.fillStyle = _star;
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii, y + j + 2, 1, 1);
          }
        }
      } else if (jsTruthy(m)) {
        // a cross: this round went wrong (what went wrong shows in the picture)
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

  /* ---------- moving things ---------- */

  // DECISION(order 31b, as El balcón's, La sala's, El patio's and El camino's): the scene's random draws come from the
  // game's one Rng, as Math.random was one: the one the registry's factory is given (`createLago`, from the story
  // runner's `rng`)
  final Rng? _rngGiven;
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'El lago was made without a random source (Rng) but draws a random number',
      ));

  // lago.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _round(math.sqrt(dx * dx + dy * dy) / 5));
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

  // lago.js: patoA
  Future<void> patoA(
    String n,
    num x,
    num y, [
    String? pose0,
    num? pasos0,
  ]) async {
    final o = _pato(n);
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num;
    final pose = jsTruthy(pose0)
        ? pose0!
        : (jsTruthy(o['pose']) ? o['pose'] as String : 'nada');
    final dx = x - x0, dy = y - y0;
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(
            4,
            _round(math.sqrt(dx * dx + dy * dy) / (pose == 'vuela' ? 8 : 3)),
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
  }

  // lago.js: salpica
  void salpica(num x, num y) {
    W['salpica'] = [
      for (final e in (W['salpica'] as List?) ?? const [])
        if (F - ((e as Map)['f'] as num) < 12) e,
      <String, dynamic>{'x': _round(x), 'y': _round(y), 'f': F},
    ];
    tone(300, 0, .1, 'sine', .1, 90);
  }

  // lago.js: cuac
  void cuac([num? n]) {
    for (var k = 0; k < _or(n, 1); k++) {
      tone(420, k * .16, .07, 'sawtooth', .05, 330);
      tone(330, k * .16 + .07, .06, 'sawtooth', .04, 280);
    }
  }

  // lago.js: pio
  void pio() {
    tone(1500, 0, .05, 'sine', .06, 2000);
    tone(1800, .06, .05, 'sine', .05, 1500);
  }

  // lago.js: pezSalta
  Future<void> pezSalta(String n, [num? h]) async {
    final o = _pez(n);
    if (o == null) return;
    salpica(o['x'] as num, (o['y'] as num) - 6);
    for (var i = 1; i <= 10; i++) {
      o['dy'] = _or(h, 22) * math.sin(math.pi * i / 10);
      await wait(TICK);
    }
    o['dy'] = 0;
    salpica(o['x'] as num, (o['y'] as num) - 6);
  }

  // lago.js: pezA
  Future<void> pezA(String n, num x, num y, [num? pasos0]) async {
    final o = _pez(n);
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num, dx = x - x0, dy = y - y0;
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(4, _round(math.sqrt(dx * dx + dy * dy) / 4));
    if ((x - x0).abs() > 3) o['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= pasos; i++) {
      o['x'] = x0 + (x - x0) * i / pasos;
      o['y'] = y0 + (y - y0) * i / pasos;
      await wait(TICK);
    }
  }

  // lago.js: aveA (here pajaroA: the kit's aveA is every scene's own bird's)
  Future<void> pajaroA(String n, num x, num y, [num? pasos0]) async {
    final o = _ave(n);
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num, dx = x - x0, dy = y - y0;
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(5, _round(math.sqrt(dx * dx + dy * dy) / 7));
    o['vuela'] = 1;
    if ((x - x0).abs() > 3) o['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= pasos; i++) {
      final t = i / pasos;
      o['x'] = x0 + (x - x0) * t;
      o['y'] = y0 + (y - y0) * t - 10 * math.sin(math.pi * t);
      await wait(TICK);
    }
    o['x'] = x;
    o['y'] = y;
    o['vuela'] = 0;
  }

  // lago.js: panA. The bread flies from whoever has it to a place (a place, or a function that says where its mark is
  // now); then it is there
  Future<void> panA(Object a, [num? alto, num? pasos0]) async {
    final pn = W['pan'] as Map<String, dynamic>?;
    if (pn == null) return;
    num x0, y0;
    final con = pn['con'];
    if (con == 'cq') {
      final b = frogBox(_cq);
      x0 = b.x + (b.w.toInt() >> 1);
      y0 = (_cq['y'] as num) + 18;
      bounce(5);
    } else if (jsTruthy(con) && G(con as String) != null) {
      final p = G(con)!;
      x0 = (p['x'] as num) + 8;
      y0 = (p['y'] as num) - 22;
      p['pan'] = 0;
    } else {
      x0 = pn['x'] as num;
      y0 = pn['y'] as num;
    }
    pn['con'] = null;
    pn['vis'] = 1;
    final pasos = pasos0 != null && pasos0 != 0 ? pasos0 : 9;
    for (var i = 1; i <= pasos; i++) {
      final t = i / pasos,
          f = a is List<num> Function() ? a() : (a as List).cast<num>();
      pn['x'] = x0 + (f[0] - x0) * t;
      pn['y'] = y0 + (f[1] - y0) * t;
      pn['z'] = _or(alto, 18) * 4 * t * (1 - t);
      await wait(TICK);
    }
    pn['z'] = 0;
  }

  // lago.js: boteA
  Future<void> boteA(String n, num x, num y, [num? pasos0]) async {
    final o = _bote(n);
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num, dx = x - x0, dy = y - y0;
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(5, _round(math.sqrt(dx * dx + dy * dy) / 3));
    for (var i = 1; i <= pasos; i++) {
      o['x'] = x0 + (x - x0) * i / pasos;
      o['y'] = y0 + (y - y0) * i / pasos;
      await wait(TICK);
    }
    o['x'] = x;
    o['y'] = y;
  }

  // lago.js: llegan
  Future<void> llegan() async {
    for (
      var k = 0;
      k < 400 &&
          _botes.values.any((o) => o != null && jsTruthy((o as Map)['meta']));
      k++
    ) {
      await wait(TICK);
    }
  }

  // lago.js: marca
  void marca(Object? m) {
    final l = W['marcas'] as List?;
    final i = l == null ? -1 : l.indexOf(null);
    if (i >= 0) l![i] = m;
  }

  // lago.js: quien
  Map<String, dynamic> quien(String a) {
    if (a == 'pez') return _pez('a')!;
    if (a == 'pajaro') return _ave('a')!;
    if (a.startsWith('ave_')) return _ave(a.substring(4))!;
    final k = a.replaceFirst('pato_', '');
    return _pato(k.isEmpty ? 'blanco' : k) ?? _pato('blanco')!;
  }

  // lago.js: boca. Where the mouth of an animal is now
  List<num> Function() boca(String a) => () {
    final o = quien(a);
    if (a == 'pez') return [o['x'] as num, (o['y'] as num) - 8];
    if (a == 'pajaro' || a.startsWith('ave_')) {
      return [(o['x'] as num) + (_dir(o) < 0 ? -6 : 6), (o['y'] as num) - 6];
    }
    return [
      (o['x'] as num) + (_dir(o) < 0 ? -11 : 11),
      (o['y'] as num) - (o['pose'] == 'nada' ? 6 : 10),
    ];
  };

  // lago.js: come. An animal gets the bread that is in somebody's hands (de: cq, luis, carmen) and eats it
  Future<void> come(String a, [String? de]) async {
    if (!jsTruthy(W['pan'])) {
      W['pan'] = <String, dynamic>{'con': jsTruthy(de) ? de : 'cq'};
    } else if (jsTruthy(de)) {
      (W['pan'] as Map<String, dynamic>)['con'] = de;
    }
    final o = quien(a);
    if (jsTruthy(de) && de != 'cq' && G(de!) != null) {
      G(de)!['pose'] = 'arriba';
      await wait(200);
    }
    if (a == 'pez') {
      final v = o['vaiven'], ci = o['circula'];
      o['vaiven'] = 0;
      o['circula'] = 0;
      await panA([o['x'] as num, (o['y'] as num) - 8], 18);
      salpica(o['x'] as num, (o['y'] as num) - 8);
      W['pan'] = null;
      await pezSalta('a', 7);
      o['vaiven'] = v;
      o['circula'] = ci;
    } else if (a == 'pajaro' || a.startsWith('ave_')) {
      await panA(boca(a), jsTruthy(o['ronda']) ? 8 : 20);
      W['pan'] = null;
      pio();
      o['dy'] = 2;
      await wait(150);
      o['dy'] = 0;
    } else {
      await panA(boca(a), o['pose'] == 'vuela' ? 8 : 20);
      W['pan'] = null;
      o['come'] = 1;
      cuac(1);
      await wait(450);
      if (!jsTruthy(W['sigueComiendo'])) o['come'] = 0;
    }
    if (jsTruthy(de) && de != 'cq' && G(de!) != null) G(de)!['pose'] = 'idle';
    await wait(200);
  }

  // DECISION(order 32b, as El patio's, El camino's and El campo's): a position an act reads from the story file (`o.x`,
  // `o.y`: acts.anda, acts.ranaa, acts.avea, acts.tirapan, acts.patoa) goes through the sheet's remap, as the runner
  // sends a set step's x and y (page 12, section 5: every position a story file holds; the sheet's remap lists these
  // uses, d-pato-pequeno beats.33 and .34 the ones that move)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  Future<void> _act(String k, Map<String, dynamic> o) => acts[k]!(o);

  int get _ok =>
      ((W['marcas'] as List?) ?? const []).where((m) => m == 'ok').length;

  // JavaScript: `W.marcas&&W.marcas[2]===null`
  bool get _third => W['marcas'] is List && _at(W['marcas'] as List, 2) == null;

  // JavaScript: `W.marcas&&W.marcas[2]!==null`
  bool get _thirdTaken =>
      W['marcas'] is List && _at(W['marcas'] as List, 2) != null;

  // code lines 197, 238, 272: the stars of a happy ending, a screen effect, unchanged
  static const List<List<int>> _stars = [
    [70, 60],
    [196, 70],
    [136, 50],
    [110, 90],
    [170, 96],
  ];

  int _countAgua() => _botes.values
      .where((x) => (x as Map)['en'] == 'agua' && !jsTruthy(x['meta']))
      .length;

  // lago.js: acts
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
    'come': (o) async {
      W['sigueComiendo'] = jsTruthy(o['sigue']) ? 1 : 0;
      await come(o['a'] as String, o['de'] as String?);
      W['sigueComiendo'] = 0;
    },
    'traga': (o) async {
      for (final d in _patos.values) {
        (d as Map)['come'] = 0;
      }
    },

    /* ----- story 18: Pan para el pato ----- */
    // sheet moves line 176: `async inicio18(){W.gente=` -> `async inicio18(){W.respEn=[121,75];W.gente=`; line 177: the
    // fish to and fro on open water in front of the dock's end (moves); code lines 176 and 177: every other place the
    // floor rule's
    'inicio18': (o) async {
      W['respEn'] = _p.respEn(176);
      final lu = _p.floor(176, 44, 154),
          ca = _p.floor(176, 72, 154),
          cq = _p.floor(176, 100, 125),
          pa = _p.floor(177, 142, 184),
          pz = _p.to(
            177,
            'W.peces={a:{c:"pardo",x:92,y:192,x0:92,dir:1,vaiven:1}}',
            RegExp(r'x:(\d+),y:(\d+),x0:(\d+)'),
          );
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': 1,
          'sent': 1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'idle',
          'dir': 1,
          'lleva': 'bolsa',
        },
      };
      _cq
        ..['x'] = cq[0]
        ..['y'] = cq[1]
        ..['s'] = 1;
      W['patos'] = <String, dynamic>{
        'blanco': <String, dynamic>{
          'k': 'blanco',
          'x': pa[0],
          'y': pa[1],
          'pose': 'nada',
          'dir': -1,
        },
      };
      W['peces'] = <String, dynamic>{
        'a': <String, dynamic>{
          'c': 'pardo',
          'x': pz[0],
          'y': pz[1],
          'x0': pz[2],
          'dir': 1,
          'vaiven': 1,
        },
      };
      W['aves'] = <String, dynamic>{
        'a': <String, dynamic>{
          'c': 'azul',
          'x': POSTE[0],
          'y': POSTE[1] - 24,
          'dir': -1,
        },
      };
      W['fila'] = 0;
      W['pan'] = null;
    },
    // the bird, or the duck, takes off and goes on flying round over the pond (rules.sky: the circle, unchanged)
    'sube': (o) async {
      final a0 = math.pi * .7,
          tx = 150 + 46 * math.cos(a0),
          ty = 58 + 16 * math.sin(a0);
      if (o['quien'] == 'pato') {
        final d = _pato('blanco')!;
        d['rema'] = 0;
        cuac(1);
        await patoA('blanco', tx, ty, 'vuela');
        d['fase'] = a0 - F / 16;
        d['ronda'] = 1;
      } else {
        final b = _ave('a')!;
        pio();
        await pajaroA('a', tx, ty);
        b['vuela'] = 1;
        b['fase'] = a0 - F / 16;
        b['ronda'] = 1;
      }
    },
    // code line 180: the floor rule
    'baja': (o) async {
      if (o['quien'] == 'pato') {
        final d = _pato('blanco')!;
        d['ronda'] = 0;
        d['rema'] = 0;
        final c = _p.floor(180, 142, 184);
        await patoA(
          'blanco',
          c[0],
          c[1],
          d['pose'] == 'vuela' ? 'vuela' : 'nada',
        );
        if (d['pose'] == 'vuela') salpica(c[0], c[1]);
        d['pose'] = 'nada';
        d['dir'] = -1;
      } else {
        final b = _ave('a')!;
        b['ronda'] = 0;
        await pajaroA('a', POSTE[0], POSTE[1] - 24);
        b['dir'] = -1;
      }
    },
    // the duck paddles round and round the post (relative to POSTE)
    'rema': (o) async {
      final d = _pato('blanco')!;
      d['ronda'] = 0;
      await patoA('blanco', POSTE[0] + 20, POSTE[1] + 16, 'nada');
      d['fase'] = -F / 22;
      d['rema'] = 1;
    },
    'giro': (o) async {
      final d = _pato('blanco')!, x0 = d['x'] as num;
      for (var k = 0; k < 2; k++) {
        await patoA('blanco', x0 - 10, (d['y'] as num) + 3, 'nada', 6);
        await patoA('blanco', x0, (d['y'] as num) - 3, 'nada', 6);
      }
      d['dir'] = -1;
    },
    // the duck climbs out onto the far bank and stands there (moves line 185: it swims to the shore up the lake,
    // patoA("blanco",124,126) -> (132,124), and walks out onto the lawn, patoA("blanco",120,118) -> (102,110))
    'orilla': (o) async {
      final d = _pato('blanco')!;
      d['rema'] = 0;
      d['ronda'] = 0;
      final a = _p.floor(185, 124, 126), b = _p.floor(185, 120, 118);
      await patoA('blanco', a[0], a[1], 'nada');
      d['pose'] = 'anda';
      await patoA('blanco', b[0], b[1], 'anda', 4);
      d['dir'] = -1;
      for (var k = 0; k < 3; k++) {
        d['dy'] = 1;
        await wait(100);
        d['dy'] = 0;
        await wait(100);
      }
    },
    // it slides back in and paddles home (moves line 186: back into the water where it came out,
    // patoA("blanco",132,124,"anda",4);d.pose="nada";salpica(132,126); code line 186: patoA(142,184), the floor rule)
    'alagua': (o) async {
      final d = _pato('blanco')!;
      if (d['pose'] == 'anda') {
        final n = _p.to(
          186,
          'await patoA("blanco",124,126,"anda",4);d.pose="nada";salpica(124,128);',
        );
        await patoA('blanco', n[0], n[1], 'anda', n[2]);
        d['pose'] = 'nada';
        salpica(n[3], n[4]);
      }
      d['rema'] = 0;
      d['ronda'] = 0;
      final c = _p.floor(186, 142, 184);
      await patoA('blanco', c[0], c[1], 'nada');
      d['dir'] = -1;
    },
    // the frog takes a piece of bread: from Carmen's bag, or (once the row is out) from the row on the dock
    'toma': (o) async {
      if (_n(W['fila']) > 0) W['fila'] = _n(W['fila']) - 1;
      W['pan'] = <String, dynamic>{'con': 'cq'};
      SFX.blip();
      bounce(4);
      await wait(250);
    },
    'luispan': (o) async {
      final lu = G('luis')!;
      if (_n(W['fila']) > 0) W['fila'] = _n(W['fila']) - 1;
      W['pan'] = <String, dynamic>{'con': 'luis'};
      lu['pan'] = 1;
      SFX.blip();
      await wait(300);
    },
    // the one the bread was for goes off a little way; then it comes back
    'seva': (o) async {
      final a = o['a'] as String, ob = quien(a);
      if (a == 'pez') {
        salpica(ob['x'] as num, (ob['y'] as num) - 6);
        ob['vis'] = 0;
      } else {
        ob['dir'] = 1;
      }
      await wait(450);
    },
    'vuelve': (o) async {
      final a = o['a'] as String, ob = quien(a);
      if (a == 'pez') {
        ob['vis'] = 1;
      } else {
        ob['dir'] = -1;
      }
      await wait(300);
    },
    'turno18': (o) async {
      await _act('luispan', {});
      await come('pez', 'luis');
      final d = _pato('blanco')!;
      d['dir'] = 1;
      await wait(500);
    },
    'vuelca': (o) async {
      final ca = G('carmen')!;
      ca['pose'] = 'offer';
      ca['lleva'] = null;
      _pato('blanco')!['dir'] = -1;
      for (var i = 1; i <= 6; i++) {
        W['fila'] = i;
        SFX.blip();
        await wait(120);
      }
      ca['pose'] = 'idle';
      await wait(300);
    },
    // code line 197: the stars, a screen effect
    'final18': (o) async {
      final n = math.min(3, _n(W['fila'])),
          ca = G('carmen')!,
          d = _pato('blanco')!;
      d['rema'] = 0;
      d['ronda'] = 0;
      const quienes = [
        ['pato_blanco', 'carmen'],
        ['pez', 'luis'],
        ['pajaro', 'cq'],
      ];
      for (var i = 0; i < n; i++) {
        W['fila'] = _n(W['fila']) - 1;
        W['pan'] = <String, dynamic>{'con': quienes[i][1]};
        await come(quienes[i][0], quienes[i][1]);
      }
      if (n == 3) {
        W['heart'] = 1;
        SFX.win();
        fx({'t': 'star', 'n': 36, 'pts': _stars});
        await wait(700);
      } else if (n > 0) {
        SFX.win();
        await wait(500);
      } else {
        ca['pose'] = 'tu';
        SFX.coqui();
        await wait(900);
        ca['pose'] = 'idle';
      }
    },
    // the goodbye: each goes its own way, and goes on going while the line is said
    'sale': (o) async {
      final a = o['a'] as String, ob = quien(a);
      if (a == 'pez') {
        ob['vaiven'] = 0;
        ob['circula'] = 0;
      } else if (a == 'pajaro') {
        ob['ronda'] = 0;
        pio();
      } else {
        ob['rema'] = 0;
        ob['ronda'] = 0;
        cuac(1);
      }
      ob['sale'] = 1;
      await wait(350);
    },

    /* ----- story 19: Los botes ----- */
    // sheet moves line 202: `async inicio19(){W.gente=` -> `async inicio19(){W.respEn=[127,31];W.gente=`; Carmen on
    // the right bank (moves line 17: ORILLA, ORILLA + (18, 1)); code line 202: every other place the floor rule's
    'inicio19': (o) async {
      W['respEn'] = _p.respEn(202);
      final lu = _p.floor(202, 128, 154),
          cq = _p.floor(202, 60, 125),
          sa = _p.floor(202, 110, 153);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': ORILLA[0] + 18,
          'y': ORILLA[1] + 1,
          'pose': 'idle',
          'dir': -1,
        },
      };
      _cq
        ..['x'] = cq[0]
        ..['y'] = cq[1]
        ..['s'] = 1;
      W['saco'] = [sa[0], sa[1]];
      W['botes'] = <String, dynamic>{};
      W['nb'] = 0;
      W['enC'] = 0;
      W['enJ'] = 0;
      W['peces'] = <String, dynamic>{};
      W['aves'] = <String, dynamic>{};
      W['patos'] = <String, dynamic>{};
      await _act('repone', {'o': 'rav'});
    },
    // the row on the dock always holds a red, a blue and a green boat (o: their order, e.g. "var") (moves line 205:
    // each boat of the row at its own row, FYB)
    'repone': (o) async {
      const C = {'r': 'rojo', 'a': 'azul', 'v': 'verde'};
      final ord =
          (jsTruthy(o['o'])
                  ? '${o['o']}'
                  : jsTruthy(W['ord19'])
                  ? '${W['ord19']}'
                  : 'rav')
              .split('');
      W['ord19'] = ord.join();
      for (var i = 0; i < ord.length; i++) {
        final c = C[ord[i]], id = 'f_$c';
        if (!jsTruthy(_botes[id])) {
          _botes[id] = <String, dynamic>{
            'c': c,
            'x': FX[i],
            'y': FYB[i],
            'en': 'muelle',
          };
          SFX.blip();
        } else {
          _bote(id)!['x'] = FX[i];
          _bote(id)!['y'] = FYB[i];
        }
      }
      await wait(250);
    },
    // the frog pushes a boat from the row along the dock to Luis, who sets it on the water (moves line 207:
    // boteA(id,134,FY,7) -> boteA(id,112,160,7), on the planks before Luis's feet)
    'empuja': (o) async {
      final c = '${o['c']}'.replaceFirst('bote_', ''),
          b = _botes['f_$c'] as Map<String, dynamic>,
          lu = G('luis')!,
          k = _countAgua(),
          id = 'b${W['nb']}';
      W['nb'] = (W['nb'] as num) + 1;
      bounce(5);
      _botes.remove('f_$c');
      _botes[id] = b;
      final n = _p.to(207, 'await boteA(id,134,FY,7)');
      await boteA(id, n[0], n[1], n[2]);
      lu['pose'] = 'offer';
      await wait(150);
      await boteA(id, SALE[k % 3][0], SALE[k % 3][1], 5);
      b['en'] = 'agua';
      salpica(b['x'] as num, b['y'] as num);
      lu['pose'] = 'idle';
      await wait(200);
    },
    // Luis takes the boat himself (moves line 208: boteA(id,134,FY-6,8) -> boteA(id,120,156,8), before his feet; code
    // line 208: mueve("luis",128,154), his row 154 and the boat's FY - 6, the floor rule)
    'luiscoge': (o) async {
      final c = o['c'],
          b = _botes['f_$c'] as Map<String, dynamic>,
          lu = G('luis')!,
          k = _countAgua(),
          id = 'b${W['nb']}';
      W['nb'] = (W['nb'] as num) + 1;
      await mueve('luis', (b['x'] as num) + 16, _p.keep(208, 154));
      lu['pose'] = 'offer';
      lu['dir'] = -1;
      await wait(200);
      _botes.remove('f_$c');
      _botes[id] = b;
      b['y'] = _p.keep(208, FY - 6);
      b['x'] = (lu['x'] as num) - 8;
      SFX.blip();
      final l = _p.floor(208, 128, 154);
      final g = mueve('luis', l[0], l[1]);
      final n = _p.to(208, 'await boteA(id,134,FY-6,8)');
      await boteA(id, n[0], n[1], n[2]);
      await g;
      lu['dir'] = 1;
      await boteA(id, SALE[k % 3][0], SALE[k % 3][1], 5);
      b['en'] = 'agua';
      salpica(b['x'] as num, b['y'] as num);
      lu['pose'] = 'idle';
      await wait(200);
    },
    // Luis has his head down in his bag; mira: he looks at Carmen, away from the water
    'bolso': (o) async {
      final lu = G('luis')!;
      lu['dir'] = -1;
      lu['pose'] = jsTruthy(o['fin']) ? 'idle' : 'offer';
      if (jsTruthy(o['fin'])) lu['dir'] = 1;
      await wait(250);
    },
    'miracarmen': (o) async {
      final lu = G('luis')!;
      lu['dir'] = 1;
      lu['pose'] = jsTruthy(o['fin']) ? 'idle' : 'wave';
      await wait(250);
    },
    // Luis blows: every boat waiting by the dock sails across to Carmen (it does not wait for them to arrive)
    'sopla': (o) async {
      final lu = G('luis')!;
      lu['pose'] = 'ojos';
      tone(700, 0, .3, 'sine', .05, 500);
      for (final v in _botes.values.toList()) {
        final b = v as Map<String, dynamic>;
        if (b['en'] == 'agua' &&
            !jsTruthy(b['meta']) &&
            !jsTruthy(b['deriva'])) {
          final s = slotC((W['enC'] as num).toInt());
          W['enC'] = (W['enC'] as num) + 1;
          b['meta'] = [s[0], s[1], 1.9];
          b['rumbo'] = 'carmen';
        }
      }
      await wait(400);
      lu['pose'] = 'idle';
    },
    'llegan': (o) async {
      await llegan();
      for (final v in _botes.values) {
        final b = v as Map<String, dynamic>;
        if (b['rumbo'] == 'carmen') {
          b['en'] = 'carmen';
          b['rumbo'] = null;
        }
      }
      final ca = G('carmen')!;
      ca['pose'] = 'offer';
      await wait(250);
      ca['pose'] = 'idle';
    },
    // a boat on the water that nobody blows drifts out to the reeds and sticks there (moves line 61: PEGA)
    'deriva': (o) async {
      final e = [
        for (final en in _botes.entries)
          if ((en.value as Map)['en'] == 'agua' &&
              !jsTruthy((en.value as Map)['meta']) &&
              !jsTruthy((en.value as Map)['rumbo']))
            en,
      ];
      if (e.isEmpty) return;
      final id = e.last.key,
          b = e.last.value as Map<String, dynamic>,
          s = PEGA[math.min(3, (W['enJ'] as num).toInt())];
      b['deriva'] = 1;
      await wait(500);
      await boteA(id, s[0], s[1], 34);
      b['en'] = 'juncos';
      W['enJ'] = (W['enJ'] as num) + 1;
      SFX.bonk();
      await wait(400);
    },
    // Luis takes a boat out of his bag (c: a colour, or madera for a bare one) and holds it; alagua19: he sets what he
    // holds on the water
    'saca': (o) async {
      final lu = G('luis')!;
      lu['botes'] = <Object?>[
        ...((lu['botes'] as List?) ?? const []),
        ...(jsTruthy(o['c']) ? '${o['c']}' : 'madera').split(','),
      ];
      SFX.blip();
      await wait(300);
    },
    'alagua19': (o) async {
      final lu = G('luis')!;
      for (final c in [...((lu['botes'] as List?) ?? const [])]) {
        final k = _countAgua(), id = 'b${W['nb']}';
        W['nb'] = (W['nb'] as num) + 1;
        _botes[id] = <String, dynamic>{
          'c': c,
          'x': (lu['x'] as num) + 10,
          'y': (lu['y'] as num) - 20,
          'en': 'agua',
        };
        await boteA(id, SALE[k % 3][0], SALE[k % 3][1], 6);
        salpica(SALE[k % 3][0], SALE[k % 3][1]);
      }
      lu['botes'] = <Object?>[];
      await wait(200);
    },
    'luisve': (o) async {
      final lu = G('luis')!;
      for (var k = 0; k < 4; k++) {
        lu['dir'] = -_dir(lu);
        await wait(140);
      }
      lu['dir'] = 1;
      SFX.bonk();
      await wait(250);
    },
    // a fish of one colour swims up to the dock, jumps once and circles there (code line 222: x 232, y 192, the floor
    // rule; moves line 222: pezA("a",134,192,16) -> pezA("a",140,190,16), up to its circle)
    'pezviene': (o) async {
      final p0 = _p.floor(222, 232, 192);
      W['peces'] = <String, dynamic>{
        'a': <String, dynamic>{'c': o['c'], 'x': p0[0], 'y': p0[1], 'dir': -1},
      };
      final n = _p.to(222, 'await pezA("a",134,192,16)');
      await pezA('a', n[0], n[1], n[2]);
      await pezSalta('a', 24);
      _pez('a')!['circula'] = 1;
      await wait(300);
    },
    'pezsalta': (o) async {
      final f = _pez('a');
      if (f == null) return;
      final ci = f['circula'];
      f['circula'] = 0;
      await pezSalta('a', 24);
      f['circula'] = ci;
    },
    'pezseva': (o) async {
      final f = _pez('a');
      if (f != null) {
        f['circula'] = 0;
        f['sigue'] = null;
        f['sale'] = 1;
      }
      await wait(300);
    },
    // Luis paints the first bare boat he holds (c: the colour)
    'luispinta': (o) async {
      final lu = G('luis')!, b = (lu['botes'] as List?) ?? const [];
      final i = b.indexOf('madera');
      if (i < 0) return;
      lu['pincel'] = o['c'];
      await wait(350);
      (lu['botes'] as List)[i] = o['c'];
      SFX.blip();
      await wait(350);
      lu['pincel'] = null;
    },
    // the frog paints the first bare boat Luis holds out (relative to Luis: frog.ranapinta)
    'ranapinta': (o) async {
      final lu = G('luis')!,
          c = (jsTruthy(o['c']) ? '${o['c']}' : '').replaceFirst('pote_', ''),
          i = ((lu['botes'] as List?) ?? const []).indexOf('madera');
      if (i < 0) return;
      final q = _cq, x0 = q['x'] as num;
      W['pincel'] = c;
      await hopTo((lu['x'] as num) - 44, q['y'] as num, 1);
      await wait(250);
      (lu['botes'] as List)[i] = c;
      SFX.blip();
      await wait(300);
      W['pincel'] = null;
      await hopTo(x0, q['y'] as num, 1);
    },
    // the boat Luis holds goes onto the water and across, the fish swimming beside it (moves line 230: the fish comes to
    // the boat's right, pezA("a",SALE[0][0]-4,SALE[0][1]+9,6) -> pezA("a",SALE[0][0]+10,SALE[0][1]+12,6)); no one blows:
    // the fish pushes it
    'conpez': (o) async {
      final lu = G('luis')!,
          c = _at(lu['botes'] as List?, 0),
          id = 'b${W['nb']}',
          f = _pez('a');
      W['nb'] = (W['nb'] as num) + 1;
      lu['botes'] = <Object?>[];
      _botes[id] = <String, dynamic>{
        'c': identical(c, _undefined) ? null : c,
        'x': (lu['x'] as num) + 10,
        'y': (lu['y'] as num) - 20,
        'en': 'agua',
      };
      await boteA(id, SALE[0][0], SALE[0][1], 6);
      salpica(SALE[0][0], SALE[0][1]);
      if (f != null) {
        f['circula'] = 0;
        final n = _p.to(
          230,
          'await pezA("a",SALE[0][0]-4,SALE[0][1]+9,6)',
          RegExp(r'SALE\[0\]\[0\]\+(\d+),SALE\[0\]\[1\]\+(\d+),(\d+)\)'),
        );
        await pezA('a', SALE[0][0] + n[0], SALE[0][1] + n[1], n[2]);
        f['sigue'] = id;
      }
      final sl = slotC((W['enC'] as num).toInt()), b = _bote(id)!;
      W['enC'] = (W['enC'] as num) + 1;
      b['meta'] = [sl[0], sl[1], 1.6];
      b['rumbo'] = 'carmen';
      await wait(300);
    },
    'llegapez': (o) async {
      await _act('llegan', {});
      final f = _pez('a');
      if (f != null) {
        f['sigue'] = null;
        f['sale'] = 1;
      }
    },
    // the last decision: which of the two colours he has done, and what is still to do (it sets V for the story file)
    'dosbotes': (o) async {
      final lu = G('luis')!;
      lu['botes'] = <Object?>['madera', 'madera'];
      W['c2'] = [o['c1'], o['c2']];
      W['hechos'] = <Object?>[];
      V['falta'] = 'pote_${_js0(o['c1'])}';
      V['fc'] = o['c1'];
      V['vale'] = 'pote_${_js0(o['c2'])}';
      V['pu'] = 'pote_rojo';
      V['pd'] = 'pote_azul';
      SFX.blip();
      await wait(300);
    },
    'pintado': (o) async {
      final c = '${V['ok'] != '' ? o['x'] : V['falta']}'.replaceFirst(
        'pote_',
        '',
      );
      await _act('ranapinta', {'c': c});
      final hechos = W['hechos'] as List;
      hechos.add(c);
      final resto = [
        for (final k in W['c2'] as List)
          if (!hechos.contains(k)) k,
      ];
      V['falta'] = resto.isNotEmpty ? 'pote_${_js0(resto[0])}' : '';
      V['fc'] = resto.isNotEmpty && jsTruthy(resto[0]) ? resto[0] : '';
      V['vale'] = '';
      final libres = [
        for (final k in const ['rojo', 'azul', 'verde'])
          if (!hechos.contains(k)) k,
      ];
      V['pu'] = 'pote_${_js0(_at(libres, 0))}';
      V['pd'] = 'pote_${_js0(_at(libres, 1))}';
    },
    'pintamal': (o) async {
      final lu = G('luis')!, c = '${o['x']}'.replaceFirst('pote_', '');
      await _act('ranapinta', {'c': c});
      final botes = lu['botes'] as List;
      final i = botes.indexOf(c);
      // JavaScript: splice(i, 1), and splice(-1, 1) takes the last
      if (i >= 0) {
        botes.removeAt(i);
      } else if (botes.isNotEmpty) {
        botes.removeLast();
      }
      final id = 'b${W['nb']}';
      W['nb'] = (W['nb'] as num) + 1;
      _botes[id] = <String, dynamic>{
        'c': c,
        'x': (lu['x'] as num) + 10,
        'y': (lu['y'] as num) - 20,
        'en': 'agua',
      };
      await boteA(id, SALE[2][0], SALE[2][1], 6);
      salpica(SALE[2][0], SALE[2][1]);
      await _act('luisve', {});
      await _act('deriva', {});
      if (_third) marca('bote');
      (lu['botes'] as List).add('madera');
    },
    'findos': (o) async {
      await _act('alagua19', {});
      await _act('sopla', {});
      await _act('llegan', {});
      if (_third) {
        marca('ok');
        SFX.blip();
      }
    },
    // lago.js:237 ends in a comment that holds the rest of its line (the boats knocked free, the wait, Carmen's idle
    // pose): that code never ran, and the port keeps it so (reported); code line 238: the stars, a screen effect
    'final19': (o) async {
      final n = (W['enJ'] as num?) ?? double.nan, ca = G('carmen')!;
      ca['pose'] = 'ojos';
      tone(700, 0, .3, 'sine', .05, 500);
      if (n <= 1) {
        W['heart'] = 1;
        SFX.win();
        fx({'t': 'star', 'n': 36, 'pts': _stars});
      } else if (n < 4) {
        SFX.win();
      } else {
        SFX.coqui();
      }
      await wait(1200);
    },

    /* ----- story 20: ¿Cuál? ----- */
    // sheet moves line 241: `async inicio20(){W.gente=` -> `async inicio20(){W.respEn=[132,32];W.gente=`; the flower on
    // the right bank (moves line 241: W.flor=[196,119] -> W.flor=[204,112]); code lines 241, 242: every other place the
    // floor rule's
    'inicio20': (o) async {
      W['respEn'] = _p.respEn(241);
      final lu = _p.floor(241, 74, 118),
          ca = _p.floor(241, 112, 154),
          cq = _p.floor(241, 62, 125),
          bo = _p.floor(241, 96, 153),
          pe = _p.floor(241, 46, 119),
          fl = _p.floor(241, 196, 119),
          z = _p.floor(242, 0, 0);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': 1,
          'sent': 1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'idle',
          'dir': -1,
        },
      };
      _cq
        ..['x'] = cq[0]
        ..['y'] = cq[1]
        ..['s'] = 1;
      W['bolsa'] = [bo[0], bo[1]];
      W['flor'] = [fl[0], fl[1]];
      W['perro'] = <String, dynamic>{
        'x': pe[0],
        'y': pe[1],
        'pose': 'lie',
        'dir': 1,
      };
      W['lugarP'] = 3;
      W['orden'] = [0, 1, 2];
      W['patos'] = <String, dynamic>{};
      for (final k in PK) {
        _patos[k] = <String, dynamic>{
          'k': k,
          'x': z[0],
          'y': z[1],
          'pose': 'nada',
          'dir': -1,
        };
      }
      W['aves'] = <String, dynamic>{};
      W['pan'] = null;
      W['botes'] = <String, dynamic>{};
      W['peces'] = <String, dynamic>{};
      _pon();
    },
    '_pon': (o) async => _pon(),
    // the ducks paddle d places (minus: nearer the dock); baraja: they stop in a new order (moves line 63: P7)
    'mueven': (o) async {
      final d = _plus(_or(o['d'], 0));
      W['lugarP'] = math.max(1, math.min(7, (W['lugarP'] as num) + d));
      if (jsTruthy(o['baraja'])) {
        final a = [...(W['orden'] as List)];
        for (var i = a.length - 1; i > 0; i--) {
          final j = (_rng.next() * (i + 1)).floor();
          final t = a[i];
          a[i] = a[j];
          a[j] = t;
        }
        if (a.join(',') == (W['orden'] as List).join(',')) {
          a.add(a.removeAt(0));
        }
        W['orden'] = a;
      }
      final p = P7(W['lugarP'] as num);
      await Future.wait([
        for (var i = 0; i < PK.length; i++)
          () {
            final f = OFF[((W['orden'] as List)[i] as num).toInt()];
            return patoA(
              PK[i],
              p[0] + f[0],
              p[1] + f[1],
              'nada',
              jsTruthy(o['baraja']) ? 12 : null,
            );
          }(),
      ]);
      for (final k in PK) {
        _pato(k)!['dir'] = -1;
      }
    },
    'toma20': (o) async {
      W['pan'] = <String, dynamic>{'con': 'cq'};
      SFX.blip();
      bounce(4);
      await wait(250);
    },
    'miran': (o) async {
      for (final k in PK) {
        _pato(k)!['dy'] = 2;
      }
      await wait(160);
      for (final k in PK) {
        _pato(k)!['dy'] = 0;
      }
      await wait(120);
    },
    // the one that was left out flaps and squawks; the noise sends the ducks out
    'ruido': (o) async {
      final a = o['a'] as String, ob = quien(a);
      ob['aletea'] = 1;
      if (a.startsWith('ave_')) {
        for (var k = 0; k < 3; k++) {
          pio();
          ob['dy'] = 4;
          await wait(130);
          ob['dy'] = 0;
          await wait(110);
        }
      } else {
        cuac(3);
        for (var k = 0; k < 3; k++) {
          ob['dy'] = 3;
          await wait(130);
          ob['dy'] = 0;
          await wait(110);
        }
      }
      ob['aletea'] = 0;
    },
    // he throws the bread out without knowing which duck: all three go for it (relative to the duck)
    'rina': (o) async {
      final ob = quien(o['a'] as String),
          x = ob['x'] as num,
          y = ob['y'] as num;
      await panA([x, y - 4], 20);
      salpica(x, y - 4);
      W['pan'] = null;
      cuac(3);
      await Future.wait([
        for (final k in PK)
          patoA(
            k,
            x + (_rng.next() * 10 - 5),
            y + (_rng.next() * 6 - 3),
            'nada',
            5,
          ),
      ]);
      for (final k in PK) {
        _pato(k)!['aletea'] = 1;
      }
      await wait(600);
      for (final k in PK) {
        _pato(k)!['aletea'] = 0;
      }
    },
    // two birds land on the posts of the dock (lado: "bn" = white on the left, black on the right; "nb" the other way)
    // (code line 254: where they come from, the floor rule; PM: points.postes)
    'llegan20': (o) async {
      final izq = o['lado'] == 'nb' ? 'negro' : 'blanco',
          der = izq == 'negro' ? 'blanco' : 'negro';
      final a = _p.floor(254, -10, 60), b = _p.floor(254, 250, 50);
      W['aves'] = <String, dynamic>{
        izq: <String, dynamic>{
          'c': izq,
          'x': a[0],
          'y': a[1],
          'dir': 1,
          'casa': [PM[0][0], PM[0][1] - 1],
        },
        der: <String, dynamic>{
          'c': der,
          'x': b[0],
          'y': b[1],
          'dir': -1,
          'casa': [PM[1][0], PM[1][1] - 1],
        },
      };
      pio();
      await Future.wait([
        pajaroA(izq, PM[0][0], PM[0][1] - 1),
        pajaroA(der, PM[1][0], PM[1][1] - 1),
      ]);
      _ave(izq)!['dir'] = 1;
      _ave(der)!['dir'] = -1;
    },
    // one bird hops down, takes a crust from beside Carmen's bag and goes back to its post with the crust in its beak
    'roba': (o) async {
      final c = o['c'] as String,
          ca = G('carmen')!,
          b = _ave(c)!,
          h = (b['casa'] as List).cast<num>();
      ca['pose'] = 'offer';
      ca['dir'] = -1;
      await wait(350);
      final bolsa = W['bolsa'] as List;
      await pajaroA(c, (bolsa[0] as num) + 10, (bolsa[1] as num) - 1, 5);
      await wait(200);
      b['pan'] = 1;
      SFX.blip();
      await pajaroA(c, h[0], h[1], 6);
      b['dir'] = h[0] < 80 ? 1 : -1;
      W['ladron'] = c;
      await wait(250);
      ca['pose'] = 'idle';
      ca['dy'] = 2;
      await wait(150);
      ca['dy'] = 0;
    },
    // Carmen claps her hands at one bird. If it has the crust, it drops it in the water and the crust floats out to the
    // ducks; if not, it squawks, and the other one flies off to the post with the crust (code line 259: the row 172, the
    // floor rule)
    'palmas': (o) async {
      final ca = G('carmen')!,
          c = o['c'] as String,
          b = _ave(c)!,
          t = _ave('${W['ladron']}'),
          enposte = ((b['x'] as num) - POSTE[0]).abs() < 4;
      ca['dir'] = enposte
          ? 1
          : ((b['casa'] as List)[0] as num) < 80
          ? -1
          : 1;
      ca['pose'] = 'arriba';
      for (var k = 0; k < 2; k++) {
        tone(900, 0, .03, 'square', .06, 700);
        ca['dy'] = 2;
        await wait(120);
        ca['dy'] = 0;
        await wait(120);
      }
      ca['pose'] = 'idle';
      if (c == W['ladron']) {
        b['pan'] = 0;
        if (o['cerca'] != '0') await _act('mueven', {'d': -1});
        final p = P7(W['lugarP'] as num);
        W['pan'] = <String, dynamic>{
          'con': null,
          'x': b['x'],
          'y': (b['y'] as num) - 4,
          'z': 0,
          'vis': 1,
        };
        b['dy'] = 3;
        await panA(
          [(b['x'] as num) + (enposte ? -8 : 10), _p.keep(259, 172)],
          4,
          6,
        );
        b['dy'] = 0;
        final pan = W['pan'] as Map<String, dynamic>;
        salpica(pan['x'] as num, pan['y'] as num);
        await panA([p[0], p[1] - 6], 0, 22);
        W['pan'] = null;
        cuac(2);
        for (final k in PK) {
          _pato(k)!['come'] = 1;
        }
        await wait(500);
        for (final k in PK) {
          _pato(k)!['come'] = 0;
        }
        if (enposte) {
          final casa = (b['casa'] as List).cast<num>();
          await pajaroA(c, casa[0], casa[1]);
          b['dir'] = casa[0] < 80 ? 1 : -1;
        }
      } else {
        await _act('ruido', {'a': 'ave_$c'});
        await _act('mueven', {'d': 1});
        await pajaroA('${W['ladron']}', POSTE[0], POSTE[1] - 24);
        t!['dir'] = -1;
      }
    },
    // the bark lifts the birds (lago.js:263: they rise to row 70, in the sky; the sheet's code has no entry for it:
    // LagoPlaces.floorRule)
    'turno20': (o) async {
      final pe = W['perro'] as Map<String, dynamic>;
      pe['pose'] = 'bark';
      for (var k = 0; k < 3; k++) {
        tone(520, 0, .07, 'square', .05, 300);
        tone(400, .07, .1, 'square', .05, 240);
        await wait(260);
      }
      cuac(3);
      for (final k in PK) {
        _pato(k)!['aletea'] = 1;
      }
      final up = [
        for (final n in _aves.keys.toList())
          pajaroA(
            n,
            (_ave(n)!['x'] as num) + ((_ave(n)!['x'] as num) < 80 ? 30 : -30),
            _p.floorRule(263, 70),
            6,
          ),
      ];
      await Future.wait(up);
      for (final k in PK) {
        _pato(k)!['aletea'] = 0;
      }
      await _act('mueven', {'d': 1});
    },
    // the birds, lifted by the bark, land again: which post each takes is drawn fresh
    'posan20': (o) async {
      final izq = o['lado'] == 'nb' ? 'negro' : 'blanco',
          der = izq == 'negro' ? 'blanco' : 'negro';
      _ave(izq)!['casa'] = [PM[0][0], PM[0][1] - 1];
      _ave(der)!['casa'] = [PM[1][0], PM[1][1] - 1];
      await Future.wait([
        pajaroA(izq, PM[0][0], PM[0][1] - 1),
        pajaroA(der, PM[1][0], PM[1][1] - 1),
      ]);
      _ave(izq)!['dir'] = 1;
      _ave(der)!['dir'] = -1;
    },
    'echado': (o) async {
      (W['perro'] as Map<String, dynamic>)['pose'] = 'lie';
      await wait(200);
    },
    // he asked when she had already said which one: while he waits for her to say it again, a bird takes the bread out
    // of his hand
    'robamano': (o) async {
      if (_aves.isEmpty) return;
      final n = _aves.keys.first, b = _ave(n);
      if (b == null) return;
      final q = frogBox(_cq);
      await pajaroA(n, q.x + (q.w.toInt() >> 1), q.y + 12, 6);
      W['pan'] = null;
      b['pan'] = 1;
      SFX.bonk();
      await pajaroA(n, POSTE[0], POSTE[1] - 24, 7);
      await wait(300);
      b['pan'] = 0;
      final casa = (b['casa'] as List).cast<num>();
      await pajaroA(n, casa[0], casa[1]);
      b['dir'] = casa[0] < 80 ? 1 : -1;
      if (_third) {
        marca('pan');
        SFX.blip();
      }
    },
    'premio20': (o) async {
      if (_thirdTaken) return;
      await _act('mueven', {'d': -1});
      marca('ok');
      SFX.blip();
      await wait(250);
    },
    'marcaC': (o) async {
      if (_third) {
        marca(o['que']);
        SFX.blip();
        await wait(250);
      }
    },
    // the ducks gather before the dock's end (moves line 272: patoA(k,136,172,"nada",6) -> patoA(k,150,184,"nada",6)),
    // then waddle onto it (code line 272: xs and the row 154, the floor rule; the stars, a screen effect)
    'final20': (o) async {
      final ca = G('carmen')!;
      if (W['lugarP'] == 1) {
        final xs = [
          for (final x in const [104, 118, 131]) _p.floor(272, x, 154),
        ];
        final n = _p.to(272, 'await patoA(k,136,172,"nada",6)');
        await Future.wait([
          for (var i = 0; i < PK.length; i++)
            () async {
              final k = PK[i], d = _pato(k)!;
              await patoA(k, n[0], n[1], 'nada', n[2]);
              d['pose'] = 'anda';
              await patoA(k, xs[i][0], xs[i][1], 'anda', 8);
              d['dir'] = -1;
            }(),
        ]);
        cuac(2);
        W['heart'] = 1;
        SFX.win();
        fx({'t': 'star', 'n': 36, 'pts': _stars});
        await wait(700);
      } else {
        W['pan'] = <String, dynamic>{'con': 'carmen'};
        ca['dir'] = 1;
        await come('pato_blanco', 'carmen');
        ca['dir'] = -1;
        if (_ok != 0) {
          SFX.win();
        } else {
          SFX.coqui();
        }
        await wait(500);
      }
    },

    /* ----- Escuchar: plain acts for the picture story and the routine ----- */
    'avea': (o) async {
      final c = o['c'] as String, b = _ave(c);
      if (b == null) return;
      pio();
      if (jsTruthy(o['sobre'])) {
        final d = quien(o['sobre'] as String);
        await pajaroA(c, (d['x'] as num) - 4, (d['y'] as num) - 46);
      } else if (jsTruthy(o['casa'])) {
        final casa = (b['casa'] as List).cast<num>();
        await pajaroA(c, casa[0], casa[1]);
        b['dir'] = casa[0] < 80 ? 1 : -1;
      } else {
        final L = _fromFile(o['x'], o['y']);
        await pajaroA(c, L[0], L[1]);
      }
      if (jsTruthy(o['ronda'])) b['vuela'] = 1;
    },
    // (lago.js:276: the bread falls to row `o.y || 178`; the sheet's code has no entry for it: LagoPlaces.floorRule)
    'suelta': (o) async {
      final b = _ave(o['c'] as String);
      if (b == null) return;
      b['pan'] = 0;
      final p = W['pan'] = <String, dynamic>{
        'con': null,
        'x': b['x'],
        'y': (b['y'] as num) + 4,
        'z': 0,
        'vis': 1,
      };
      final y1 = _or(o['y'], _p.floorRule(276, 178));
      SFX.blip();
      for (var i = 1; i <= 8; i++) {
        p['y'] = (b['y'] as num) + 4 + (y1 - (b['y'] as num) - 4) * i / 8;
        await wait(TICK);
      }
      salpica(p['x'] as num, p['y'] as num);
      await wait(250);
    },
    'cuacp': (o) async {
      final d = _pato('${o['k']}');
      if (d == null) return;
      cuac(1);
      for (var k = 0; k < 2; k++) {
        d['dy'] = 3;
        await wait(140);
        d['dy'] = 0;
        await wait(120);
      }
    },
    // (lago.js:278: they swim out past the picture's right edge, x 252; the sheet's code has no entry for it:
    // LagoPlaces.floorRule)
    'sevanp': (o) async {
      await Future.wait([
        for (final k
            in (jsTruthy(o['k']) ? '${o['k']}' : 'negro,amarillo').split(','))
          () async {
            final d = _pato(k);
            if (d == null) return;
            d['dir'] = 1;
            await patoA(k, _p.floorRule(278, 252), (d['y'] as num) + 8, 'nada');
            d['vis'] = 0;
          }(),
      ]);
    },
    'mecebote': (o) async {
      String? id;
      for (final k in _botes.keys) {
        if ((_botes[k] as Map)['c'] == o['c']) {
          id = k;
          break;
        }
      }
      final b = id == null ? null : _bote(id);
      if (b == null) return;
      SFX.blip();
      final y0 = b['y'] as num;
      for (final d in const [-2, 1, -1, 0]) {
        b['y'] = y0 + d;
        await wait(110);
      }
      b['y'] = y0;
      if (b['en'] == 'agua') salpica(b['x'] as num, b['y'] as num);
    },
    'pezsalta1': (o) async {
      await pezSalta('a', 20);
    },
    'anda': (o) async {
      final L = _fromFile(o['x'], o['y']);
      await mueve('${o['quien']}', L[0], L[1]);
      if (jsTruthy(o['dir'])) G('${o['quien']}')!['dir'] = o['dir'];
    },
    'saluda': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      p['pose'] = jsTruthy(o['que']) ? o['que'] : 'wave';
      await wait(_or(o['ms'], 700));
      p['pose'] = 'idle';
    },
    'ranaa': (o) async {
      final L = _fromFile(o['x'], o['y']);
      await hopTo(L[0], L[1], _or(o['h'], 2).toInt());
    },
    // a piece of bread is thrown onto the water; the ducks race for it: the one named gets there first and eats it, the
    // small yellow one is too slow
    'tirapan': (o) async {
      final de = jsTruthy(o['de']) ? o['de'] as String : 'carmen',
          ca = G(de)!,
          L = _fromFile(o['x'], o['y']);
      W['pan'] = <String, dynamic>{'con': de};
      ca['pose'] = 'arriba';
      await wait(250);
      await panA([L[0], L[1]], 22);
      salpica(L[0], L[1]);
      W['pan'] = <String, dynamic>{
        'con': null,
        'x': L[0],
        'y': L[1],
        'z': 0,
        'vis': 1,
      };
      ca['pose'] = 'idle';
      await wait(150);
    },
    'gana': (o) async {
      final p = W['pan'] as Map<String, dynamic>?,
          k = o['k'] as String,
          d = _pato(k),
          am = _pato('amarillo');
      if (p == null) return;
      final x = p['x'] as num, y = p['y'] as num;
      await Future.wait([
        patoA(k, x + ((d!['x'] as num) < x ? -11 : 11), y + 5, 'nada', 6),
        patoA(
          'amarillo',
          (am!['x'] as num) + (x - (am['x'] as num)) * .45,
          (am['y'] as num) + (y + 5 - (am['y'] as num)) * .45,
          'nada',
          9,
        ),
      ]);
      d['dir'] = (d['x'] as num) < x ? 1 : -1;
      W['pan'] = null;
      d['come'] = 1;
      cuac(1);
      await wait(600);
      d['come'] = 0;
      am['dy'] = -2;
      await wait(300);
      am['dy'] = 0;
    },
    'patoa': (o) async {
      final k = '${o['k']}', d = _pato(k), L = _fromFile(o['x'], o['y']);
      await patoA(k, L[0], L[1], 'nada', o['pasos'] as num?);
      if (jsTruthy(o['dir'])) d!['dir'] = o['dir'];
    },
    'dip': (o) async {
      final b = _ave('a');
      if (b == null) return;
      pio();
      b['dy'] = 6;
      await wait(250);
      b['dy'] = 0;
      await wait(200);
    },
    'cuac': (o) async {
      cuac(1);
      final d = _pato('amarillo');
      if (d != null) {
        d['dy'] = 3;
        await wait(150);
        d['dy'] = 0;
      }
    },
  };

  // lago.js: acts._pon (moves line 63: P7)
  void _pon() {
    final p = P7(W['lugarP'] as num);
    for (var i = 0; i < PK.length; i++) {
      final o = OFF[((W['orden'] as List)[i] as num).toInt()];
      final d = _pato(PK[i])!;
      d['x'] = p[0] + o[0];
      d['y'] = p[1] + o[1];
    }
  }

  // lago.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    SFX.bonk();
    await wait(300);
  }

  // lago.js: poke
  @override
  dynamic poke(String what) {
    if (what.startsWith('pato_')) {
      cuac(1);
    } else if (what == 'pajaro' || what.startsWith('ave_')) {
      pio();
    }
    return null;
  }

  // JavaScript: `"" + p[k]` of a field that may be missing ("undefined")
  static String _jsField(Map<String, dynamic> p, String k) =>
      p.containsKey(k) ? _js(p[k]) : 'undefined';

  // lago.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final ps = (W['patos'] as Map<String, dynamic>?) ?? const {};
    final patos = [
      for (final k in ps.keys)
        () {
          final p = ps[k] as Map<String, dynamic>;
          return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}:${_jsField(p, 'pose')}';
        }(),
    ].join(' ');
    final marcas = ((W['marcas'] as List?) ?? const [])
        .map((m) => m == null ? '' : _js(m))
        .join();
    return 'patos=$patos lugar=${_js(_n(W['lugarP']))} fila=${_js(_n(W['fila']))}'
        ' enC=${_js(_n(W['enC']))} enJ=${_js(_n(W['enJ']))}'
        ' botes=${((W['botes'] as Map?) ?? const {}).length} marcas=$marcas';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through
  // the sheet's remap table. A point keeps its screen place (the sheet's `new`; the few the sheet moved: d-pato-pequeno's
  // ducks and Luis in h-lago and d-pato-pequeno, the bird on the post in h-lago, the bird of pájaro.si on the right
  // bank); the frog out of a picture is no place (`to.none`) and is given back; a pair rectangle gives the crop of the
  // pictures it was; a level picture's rectangle or x gives itself back (the level pictures are the sheet's, whole).
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

  // lago-preview.html: PV.pair's remapW for a review picture's own W (the pair's file, cual-lago): the ducks (one
  // paddling round the post moves with it: moves.shift), the birds (and their post, casa), the boats (one that reached
  // Carmen to its slot in the new row), the fish, and the flower, the bag and the sack: each at a place of a move of
  // every act (`*`) goes to its new one, else at a story position the sheet moved for cual-lago to its new one, as the
  // top-level places (cq, pan, perro) are by ScenePictures
  @override
  void placePair(Map<String, dynamic> set) {
    final mv = [
      for (final m in sheet.moves)
        if (m.act == '*') ...m.places,
    ];
    final rm = [
      for (final e in sheet.remapTable)
        if (e.moved && e.uses.any((u) => u.startsWith('cual-lago.json'))) e,
    ];
    List<num>? find(String who, num x, num y) {
      final rx = _round(x), ry = _round(y);
      for (final q in mv) {
        if ((q.who == 'whoever' || q.who == who) &&
            q.old[0] == rx &&
            q.old[1] == ry) {
          return q.now;
        }
      }
      for (final e in rm) {
        if (e.old[0] == rx && e.old[1] == ry) return e.now;
      }
      return null;
    }

    void mv1(String who, Map p) {
      final m = find(who, p['x'] as num, p['y'] as num);
      if (m != null) {
        p['x'] = m[0];
        p['y'] = m[1];
      }
    }

    ({String who, String when, List<num> by})? sh;
    for (final m in sheet.moves) {
      if (m.shift != null) {
        sh = m.shift;
        break;
      }
    }
    for (final o in ((set['patos'] as Map?) ?? const {}).values) {
      if (o is! Map || o['x'] == null) continue;
      if (sh != null && jsTruthy(o[sh.when])) {
        o['x'] = (o['x'] as num) + sh.by[0];
        o['y'] = (o['y'] as num) + sh.by[1];
      } else {
        mv1('pato', o);
      }
    }
    for (final o in ((set['aves'] as Map?) ?? const {}).values) {
      if (o is! Map || o['x'] == null) continue;
      mv1('ave', o);
      final casa = o['casa'];
      if (casa is List) {
        final m = find('ave', casa[0] as num, casa[1] as num);
        if (m != null) o['casa'] = [...m];
      }
    }
    for (final o in ((set['botes'] as Map?) ?? const {}).values) {
      if (o is! Map || o['x'] == null) continue;
      if (o['en'] == 'carmen') {
        final s = slotOf(o['x'] as num, o['y'] as num);
        if (s != null) {
          o['x'] = s[0];
          o['y'] = s[1];
        }
      } else {
        mv1('bote', o);
      }
    }
    for (final o in ((set['peces'] as Map?) ?? const {}).values) {
      if (o is! Map || o['x'] == null) continue;
      mv1('pez', o);
    }
    for (final k in const ['flor', 'bolsa', 'saco']) {
      final v = set[k];
      if (v is List && v.length == 2) {
        final m = find(k, v[0] as num, v[1] as num);
        if (m != null) set[k] = [...m];
      }
    }
  }

  // lago-preview.html: PV.slot. A boat that reached Carmen: the old slotC(i) row to the new one (moves line 62: SLOTC)
  List<int>? slotOf(num x, num y) {
    final i = _round((x - 98) / 6) + (y > 121 ? 13 : 0);
    if (i < 0 || i > 25) return null;
    return [...slotC(i)];
  }
}

/// One entry of lago.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is
/// (lago-preview.html, sheet front.tags: `id` for a child or the frog, `k` for Canelo, `pato`, `ave`, `bote` and `pez`
/// for an animal or a boat by its key, `front` for a part of the set drawn again).
class LagoItem {
  LagoItem(
    this.y,
    this.d, {
    this.id,
    this.k,
    this.pato,
    this.ave,
    this.bote,
    this.pez,
    this.front,
  });

  final num y;
  final void Function() d;
  final String? id, k, pato, ave, bote, pez, front;
}
