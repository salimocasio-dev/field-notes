// Port of historia/escenas/camino.js: the scene "El camino", the path in the park (order 33b). Line for line, minus its
// background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background, which the set
// bakes; the frog's dotted shadow, which the engine casts); every screen position replaced by what the sheet's `code`
// list gives for its line (camino_places.dart), and the places the sheet's `moves` list moves, each at its line.
// camino.js is written on the kit, so this is an `Escena`; its set is [CaminoSet].
//
// What El camino's sheet has that the earlier ones did not, and how it is kept here (as camino-preview.html keeps it):
// - `things.grande.hintBox`: the big tree's hint frame and twinkle are drawn round its hint box (`Thing.hintBox`, which
//   coqui_pixel's signs read); a touch still answers in its box, which runs off the picture.
// - `sevan` (the sheet's `moves` at line 258): at the end of story 14 everyone leaves through the arch in a file, 3 ticks
//   apart, fading past its line; Canelo fades too (`moves` at line 84: animal() draws with its `al`).
// - `moves`: where the answer cards stand in the sky (W.respEn, set at the start of stories 12, 13 and 14), Canelo's x
//   capped at marks 7 and 8, the cat's place on the bench, the bird's on the bench, the cat's hint hand, the frog's place
//   at the first tree.
// - `front`: the bench and the arch are set things someone can be behind: at their entries in the sorted list their own
//   pixels are drawn again over whoever is behind them, by the depth test ([Camino.front]); the cat on the bench takes
//   the seat's depth (`points.gato_banco.v`).
// - `talk`: where a bubble goes ([Camino.talkPlace]); `shadows`: the frog's, the people's, Canelo's, the cat's (not on
//   the bench) and the bush's.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/camino/camino_places.dart';
import 'package:coqui_scenes/src/camino/camino_set.dart'
    show CaminoSet, CaminoState, caminoEngine;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "camino", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`), drawing
/// its random numbers from [rng], the game's one random source.
Scene createCamino({Rng? rng}) => Camino(sheetOf('camino'), rng: rng);

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

// JavaScript: `+x || d`
num _plusOr(Object? v, num d) {
  final n = _plus(v);
  return n.isNaN || n == 0 ? d : n;
}

// JavaScript: how `"" + v` writes a value of W (estado)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `p.dir < 0` (a missing dir is not)
num _dir(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num ? p['dir'] as num : 0;

final int _gr0 = hexColour('#5A5A6A'),
    _gr1 = hexColour('#7E7E90'),
    _gr2 = hexColour('#A2A2B2'),
    _gr3 = hexColour('#C8C8D4'),
    _pink = hexColour('#FF8FB8'),
    _catEye = hexColour('#F8C838'),
    _shell = hexColour('#EAD9A2'),
    _biscuit = hexColour('#E8B060'),
    _biscuitMark = hexColour('#B07A3C'),
    _ring0 = hexColour('#FFE040'),
    _ring1 = hexColour('#FFF4B0'),
    _leash = hexColour('#7A1C1C'),
    _leashEnd = hexColour('#C88A4A'),
    _dust = hexColour('#E8E0C8'),
    _speed = hexColour('#2E6CD0'),
    _trail = hexColour('#9494A6'),
    _cardDust = hexColour('#C8C8D4'),
    _step = hexColour('#C89858'),
    _leaf = hexColour('#2E9A48'),
    _paw = hexColour('#B07A3C'),
    _slot = hexColour('#D8D8E4');

const int _white = 0xFFFFFFFF;

/* ---------- the picture ---------- */

// camino.js: mkGato
Sprite mkGato(String pose, bool f) {
  final b = Buf(26, 20), Gr = [_gr0, _gr1, _gr2, _gr3];
  const X = 12, Y = 11;
  if (pose == 'cara') {
    b.ell(X, Y, 6, 5, Gr);
    b.rect(X - 6, Y - 7, 3, 4, Gr[1]);
    b.rect(X + 3, Y - 7, 3, 4, Gr[1]);
    b.px(X - 5, Y - 6, _pink);
    b.px(X + 4, Y - 6, _pink);
    b.rect(X - 3, Y - 1, 2, 2, _catEye);
    b.rect(X + 2, Y - 1, 2, 2, _catEye);
    b.px(X - 3, Y, OUT);
    b.px(X + 2, Y, OUT);
    b.px(X, Y + 2, _pink);
    return b.outline().done();
  }
  if (pose == 'cola') {
    b.cap(X, 1, X + (f ? 2 : -2), 12, 2.2, Gr);
    b.cap(X + (f ? 2 : -2), 12, X + (f ? 5 : -5), 15, 2.2, Gr);
    for (final y in const [4, 8, 12]) {
      b.rect(X - 2 + (f ? 1 : -1) * (y > 8 ? 1 : 0), y, 5, 1, Gr[0]);
    }
    return b.outline().done();
  }
  if (pose == 'duerme') {
    b.ell(X, Y + 4, 9, 5, Gr);
    b.ell(X + 5, Y + 3, 4, 3.4, Gr);
    b.rect(X + 3, Y - 1, 2, 2, Gr[1]);
    b.rect(X + 7, Y - 1, 2, 2, Gr[1]);
    b.rect(X + 4, Y + 3, 2, 1, OUT);
    b.cap(X - 8, Y + 6, X - 2, Y + 8, 1.3, [Gr[1]]);
    return b.outline().done();
  }
  final run = pose == 'run', low = pose == 'walk', a = f ? 1 : -1;
  b.cap(X - 8, Y + (run ? 0 : 1), X - 11, Y - (run ? 2 : 6), 1.3, [Gr[1]]);
  if (pose == 'sit' || pose == 'lava') {
    b.ell(X - 1, Y + 3, 5.6, 6, Gr);
    b.rect(X + 2, Y + 4, 2, 6, Gr[1]);
    b.ell(X - 3, Y + 8, 4, 2, [Gr[1]]);
    if (pose == 'lava' && f) b.rect(X + 4, Y, 2, 5, Gr[2]);
  } else {
    b.ell(X, Y + (low ? 3 : 1), 9, low ? 3.6 : 4.4, Gr);
    if (run) {
      b.cap(X - 5, Y + 4, X - 10 + a * 2, Y + 8, 1.2, [Gr[1]]);
      b.cap(X + 5, Y + 4, X + 10 + a * 2, Y + 8, 1.2, [Gr[1]]);
      b.cap(X + 7, Y + 4, X + 12 - a, Y + 9, 1.2, [Gr[2]]);
    } else {
      b.rect(X - 6 + a, Y + 5, 2, 4, Gr[1]);
      b.rect(X - 3 - a, Y + 5, 2, 4, Gr[0]);
      b.rect(X + 4 + a, Y + 5, 2, 4, Gr[1]);
      b.rect(X + 6 - a, Y + 5, 2, low ? 3 : 4, Gr[2]);
    }
  }
  final hx = X + 8,
      hy = (pose == 'sit' || pose == 'lava') ? Y - 4 : Y - (low ? 0 : 3);
  b.ell(hx, hy, 4.6, 4.2, Gr);
  b.rect(hx - 4, hy - 6, 3, 3, Gr[1]);
  b.rect(hx + 2, hy - 6, 3, 3, Gr[1]);
  b.px(hx - 1, hy - 1, _catEye);
  b.px(hx + 2, hy - 1, _catEye);
  b.px(hx + 1, hy + 1, _pink);
  return b.outline().done();
}

// camino.js: mkCaracol
Sprite mkCaracol(bool f) {
  final b = Buf(18, 13), e = f ? 1 : 0;
  b.rect(1, 9, 13 + e, 3, _shell);
  b.rect(12 + e, 4, 2, 6, _shell);
  b.rect(15 + e, 5, 1, 5, _shell);
  b.px(12 + e, 3, OUT);
  b.px(15 + e, 4, OUT);
  b.ell(6, 6, 5, 4.6, [RP.orng[0], RP.orng[2], RP.orng[3]]);
  b.ell(6, 6, 2.6, 2.4, [RP.orng[1]]);
  b.px(6, 6, RP.orng[4]);
  return b.outline().done();
}

// camino.js: mkArbusto
Sprite mkArbusto() {
  final b = Buf(44, 30), G = RP.grn;
  b.ell(14, 18, 13, 11, G);
  b.ell(30, 17, 13, 12, G);
  b.ell(22, 11, 12, 10, G);
  for (var i = 0; i < 10; i++) {
    b.px(6 + hs(i, 3) % 32, 8 + hs(i, 7) % 16, G[4]);
  }
  return b.outline().done();
}

// camino.js: mkPajarito
Sprite mkPajarito(bool f) {
  final b = Buf(11, 9), B = RP.blue;
  b.ell(5, 5, 3.6, 2.8, B);
  b.ell(7.6, 3, 2.2, 2, B);
  b.px(8, 3, OUT);
  b.rect(10, 3, 1, 1, RP.yel[2]);
  b.cap(2, 5, 0, 4 + (f ? 1 : 0), 1, [B[1]]);
  return b.outline().done();
}

// camino.js: galleta
// a biscuit in the shape of a fish
void galleta(Ctx g, num x, num y, [num? k0]) {
  final k = k0 == null || k0 == 0 ? 1 : k0, C = _biscuit;
  void u(num a, num b, num w, num h, int col) =>
      fr(g, x + a * k, y + b * k, w * k, h * k, col);
  for (final r in const [
    [1, 0, 5, 5],
    [0, 1, 7, 3],
    [7, 0, 1, 5],
    [8, -1, 1, 7],
    [6, 1, 1, 3],
  ]) {
    fr(g, x + r[0] * k - 1, y + r[1] * k - 1, r[2] * k + 2, r[3] * k + 2, OUT);
  }
  u(1, 0, 5, 5, C);
  u(0, 1, 7, 3, C);
  u(6, 1, 1, 3, C);
  u(7, 0, 1, 5, C);
  u(8, -1, 1, 7, C);
  u(1, 1, 1, 1, OUT);
  u(3, 3, 2, 1, _biscuitMark);
}

// camino.js: guineo
// a guineo (small banana)
void guineo(Ctx g, num x, num y, [num? k0]) {
  final k = k0 == null || k0 == 0 ? 1 : k0, Y = RP.yel;
  const rs = [
    [0, 2, 2, 2],
    [1, 3, 3, 2],
    [3, 4, 4, 2],
    [6, 3, 3, 2],
    [8, 1, 2, 3],
  ];
  for (final r in rs) {
    fr(g, x + r[0] * k - 1, y + r[1] * k - 1, r[2] * k + 2, r[3] * k + 2, OUT);
  }
  for (final r in rs) {
    fr(g, x + r[0] * k, y + r[1] * k, r[2] * k, r[3] * k, Y[2]);
  }
  fr(g, x + 9 * k, y, k, k, RP.wood[1]);
}

/// The pixels of each of the sheet's `front` parts (set-kit.js `PART_TAGS`: the part of the set that drew a pixel
/// last), by set key, then by part. A state's are the same on every engine.
final Map<String, Map<String, Int32List>> _frontPixels = {};

class Camino extends Escena implements SetScene, SetOverSprites {
  /// [rng] is the game's one random source (camino.js gatoarbol: `Math.random()`): the story runner's. A scene made
  /// without it (a picture, a test of its sprites) draws no random number.
  Camino(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = CaminoPlaces(sheet, caminoEngine());
    final p = _p;
    // camino.js:17 ARBOL (sheet: points arbol.0 to arbol.2, unchanged); MARCA, GRAN and BANCO were the background's,
    // the places' and the boxes' only (code lines 16, 17): the places and the boxes are the sheet's
    ARBOL = [for (var i = 0; i < 3; i++) p.pt('arbol.$i')];
    // camino.js:18 NIDO (sheet: points nido, relative to a small tree's foot)
    NIDO = p.pts('nido');
    // camino.js:59, :60, :61 ranaEn, ninaEn, perroEn (sheet: spots rana.i, nina.i, perro.i; moves line 61: perroEn's x
    // at most 188, perro.7 and perro.8)
    _rana = [for (var i = 0; i < 9; i++) p.frogSpot('rana.$i')];
    _nina = [for (var i = 0; i < 9; i++) p.spot('nina.$i')];
    _perro = [for (var i = 0; i < 9; i++) p.spot('perro.$i')];
    // camino.js:62 LUGAR (sheet: lugar, the frog's spots frog.*; moves line 62: arbol0 [44,122] -> [49,121])
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // camino.js:220 carmenva: Carmen at a small tree (sheet: spots carmenva.0 to carmenva.2)
    _carmenva = [for (var i = 0; i < 3; i++) p.spot('carmenva.$i')];
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    // camino.js:112 the bird on the bench (sheet: points ave_banco; moves line 112)
    _aveBanco = p.pt('ave_banco');
    // the cat on the bench (sheet: points gato_banco: its place, and the depth the front test takes for it)
    final gb = sheet.screenPoint('gato_banco');
    _gatoBanco = [_round(gb.xy[0]), _round(gb.xy[1])];
    _gatoBancoV = gb.v ?? (throw SheetError('points.gato_banco has no v'));
    _talk = sheet.talk!;
    _sortBanco = sheet.frontParts['banco']!.sortY!;
    _sortPorton = sheet.frontParts['porton']!.sortY!;
    // camino.js:66 AVES (sheet: things ave<i><k>.box, relative to the tree: unchanged)
    final aves = <Thing>[
      for (var i = 0; i < 3; i++)
        for (var k = 0; k < 3; k++)
          Thing(
            id: 'ave$i$k',
            m: 1,
            si: (w) {
              final pj = w['pajaros'] is List ? w['pajaros'] as List : const [];
              return i < pj.length && (pj[i] as num) > k;
            },
            box: p.box('ave$i$k'),
          ),
    ];
    // camino.js:67 to :72 COSAS (sheet: code lines 70 to 72, things.<id>.box and hand; moves line 69: the cat's hand;
    // things.grande.hintBox)
    cosas = [
      for (final id in const ['luis', 'carmen', 'abuela']) persona(id),
      ...aves,
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
        m: 2,
      ),
      Thing(
        id: 'gato',
        si: (w) =>
            jsTruthy(w['gato']) &&
            (w['gato'] as Map)['vis'] != 0 &&
            (w['gato'] as Map)['en'] == null,
        box: (Map<String, dynamic> w) {
          final o = w['gato'] as Map<String, dynamic>;
          return [
            _round(o['x'] as num) - 12,
            _round(o['y'] as num) - 18,
            24,
            20,
          ];
        },
        // sheet moves line 69: `hand:w=>[R(w.gato.x)+12,R(w.gato.y)-10]`
        hand: (Map<String, dynamic> w) {
          final o = w['gato'] as Map<String, dynamic>;
          return [_round(o['x'] as num) + 12, _round(o['y'] as num) - 10];
        },
        m: 2,
      ),
      for (var i = 0; i < 3; i++)
        Thing(
          id: 'arbol$i',
          box: p.box('arbol$i'),
          hand: p.hand('arbol$i'),
          m: 0,
        ),
      Thing(id: 'banco', box: p.box('banco'), m: 1),
      Thing(
        id: 'grande',
        box: p.box('grande'),
        hand: p.hand('grande'),
        hintBox: p.hintBox('grande'),
        m: 0,
      ),
      Thing(id: 'porton', box: p.box('porton'), m: 0),
      Thing(id: 'camino', box: p.box('camino'), m: 0),
      Thing(id: 'parque', box: p.box('parque'), m: 0),
    ];
  }

  @override
  final Sheet sheet;

  late final CaminoPlaces _p;
  final Rng? _rngGiven;

  @override
  String get id => 'camino';

  @override
  PpEngine newEngine({bool still = false}) => caminoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the host: the bubble camino.js adds when it loads (`Object.assign(BUBL, {q: ["q"]})`) goes into the game's table
  // when the scene is given its host
  SceneHost? _host;
  @override
  SceneHost get host => _host!;
  @override
  set host(SceneHost h) {
    _host = h;
    // camino.js:92
    h.BUBL.addAll(const {
      'q': ['q'],
    });
  }

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  Map<String, dynamic> get V => host.V;
  Sfx get SFX => host.SFX;
  Future<void> wait(num ms) => host.wait(ms);
  int get TICK => host.TICK;
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      host.frogBox(q);
  void tone(num f0, num at, num dur, [String? type, num? vol, num? f1]) =>
      host.tone(f0, at, dur, type, vol, f1);

  /* ---------- the set ---------- */

  // the sheet's setKey table, from W (setKey.params.gran.fromW): W.sinGran ? "0" : "1"
  @override
  String setKey(Map<String, dynamic> W) =>
      CaminoState(gran: jsTruthy(W['sinGran']) ? '0' : '1').key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = CaminoSet(e, b, CaminoState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the bench's and the arch's
    // own pixels)
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

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  // the sheet's shadows, as camino-preview.html casts them: the frog (W.cq.vis, not .5 or less faded) at .3 with his
  // radius, from the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25)); everyone visible and
  // not .5 or less faded, from the ground point under their feet on screen (unproject(round(x), round(y) - 1)): sitting
  // (sent) at .3, standing at .3, .65, 1, 1.35, 1.7, abuela with the grown radius, the children with theirs; Canelo and
  // the cat (shown, on the ground, not .5 or less faded; the cat not on the bench's seat, points.gato_banco) at .25 with
  // theirs; the bush (W.arbusto) at .3 with its radius, from the ground point under (arbusto[0], arbusto[1] - 1)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final e = _p.e, sh = sheet.shadows;
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q),
          g = e.unproject(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: sh['coqui']!.radius));
    }
    final radii = sh['people']!.radii!;
    final G = W['gente'] as Map<String, dynamic>? ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0 || _atMostHalf(p['al'])) continue;
      final r = en.key == 'abuela' ? radii['grown']! : radii['nino']!;
      final zs = jsTruthy(p['sent'])
          ? const [.3]
          : const [.3, .65, 1.0, 1.35, 1.7];
      final g = e.unproject(_round(p['x'] as num), _round(p['y'] as num) - 1);
      for (final z in zs) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    for (final k in const ['perro', 'gato']) {
      final o = W[k] as Map<String, dynamic>?;
      if (o == null ||
          o['vis'] == 0 ||
          o['en'] != null ||
          _atMostHalf(o['al'])) {
        continue;
      }
      // on the bench's seat
      if (k == 'gato' &&
          _gatoBanco[0] == _round(o['x'] as num) &&
          _gatoBanco[1] == _round(o['y'] as num)) {
        continue;
      }
      final g = e.unproject(_round(o['x'] as num), _round(o['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .25, r: sh[k]!.radius));
    }
    final ar = W['arbusto'];
    if (jsTruthy(ar)) {
      final a = ar as List, g = e.unproject(a[0] as num, (a[1] as num) - 1);
      out.add((x: g.x, y: g.y, z: .3, r: sh['arbusto']!.radius));
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  /* ---------- the bench and the arch in front: the sheet's front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // the set as this frame shows it (wind, shadows), before the sprite layer (drawFrame's step 4), and its depth with
  // this frame's leaves (camino-preview.html: `DEPTH.live()`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // camino-preview.html: PREVIEW.front (sheet: front). The set's own pixels of a part (the bench, the arch), again,
  // inside each character drawn before its entry in the sorted list ([lista], sorted), only where that pixel is nearer
  // to the camera than the character: z[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the ground point under the
  // character's feet (sheet front.boxes). A frame drawn with no set (a player with no screen) has none to draw again.
  void front(String part, List<CaminoItem> lista) {
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'camino: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final me = lista.indexWhere((o) => o.front == part);
    final pix = e.pix, W0 = e.W, H0 = e.H;
    for (final o in lista.sublist(0, me < 0 ? 0 : me)) {
      final r = frontBox(o, W, e);
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

  // camino-preview.html: PREVIEW.frontBox. A list item's box and the v of the ground under its feet (sheet
  // front.boxes): a person [x - 24, y - alto - 2, 48, alto + 3]; the frog frogBox with dy; Canelo or the cat [x - 16,
  // y - 24, 32, 27]; the cat on the bench (at points.gato_banco) takes points.gato_banco.v
  ({List<num> box, double v})? frontBox(
    CaminoItem o,
    Map<String, dynamic> w,
    PpEngine e,
  ) {
    // the ground under a screen point: v = (x + y) / R2
    double vOf(num sy) => (sy - e.OY) / (e.S * .5);
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return (
        box: [b.x, b.y + _round(_n(q['dy'])), b.w, b.h],
        v: vOf((q['y'] as num) + 25),
      );
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>;
      final h = o.id == 'abuela' ? 51 : (jsTruthy(p['sent']) ? 40 : 44);
      return (
        box: [
          _round(p['x'] as num) - 24,
          _round(p['y'] as num) - h - 2,
          48,
          h + 3,
        ],
        v: vOf(_round(p['y'] as num) - 1),
      );
    }
    if (o.k != null) {
      final p = w[o.k] as Map<String, dynamic>,
          x = _round(p['x'] as num),
          y = _round(p['y'] as num);
      final onBench = o.k == 'gato' && x == _gatoBanco[0] && y == _gatoBanco[1];
      return (
        box: [x - 16, y - 24, 32, 27],
        v: onBench ? _gatoBancoV : vOf(y - 1),
      );
    }
    return null;
  }

  /* ---------- where things are ---------- */

  // camino.js: ARBOL, NIDO (sheet: points)
  late final List<List<double>> ARBOL, NIDO;
  late final List<List<num>> _rana;
  late final List<List<int>> _nina, _perro, _carmenva;
  late final List<double> _aveBanco;
  late final List<int> _gatoBanco;
  late final double _gatoBancoV;
  late final num _sortBanco, _sortPorton;

  // camino.js: ranaEn (sheet: spots rana.i). The frog walks on the far side of the path
  List<num> ranaEn(num i) => _rana[i.toInt()];

  // camino.js: ninaEn (sheet: spots nina.i). Carmen on our side
  List<int> ninaEn(num i) => _nina[i.toInt()];

  // camino.js: perroEn (sheet: spots perro.i; moves line 61: x at most 188). Canelo a little ahead of the frog
  List<int> perroEn(num i) => _perro[i.toInt()];

  // camino.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;

  // camino.js: QUIEN
  static final Map<String, Who> QUIEN = {
    'luis': FAM['hermano']!,
    'carmen': FAM['hermana']!,
  };

  // camino.js: alto
  int alto(String id) {
    if (id == 'abuela') return 51;
    if (QUIEN[id]!.nino) {
      final p = G(id);
      return p != null && jsTruthy(p['sent']) ? 40 : 44;
    }
    return 56;
  }

  // camino.js: caja
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

  // camino.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // camino.js: COSAS
  @override
  late final List<Thing> cosas;

  // camino.js: fresh
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'gente': <String, dynamic>{},
    'perro': null,
    'gato': null,
    'pajaros': <dynamic>[0, 0, 0],
    'vuelan': 0,
    'sinGran': 0,
    'lit': null,
    'caracol': null,
    'arbusto': null,
    'arrastra': 0,
    'correaDe': null,
    'marcas': null,
    'pos': <String, dynamic>{'cq': 0, 'carmen': 0},
    't': 1,
    'correaA': null,
    'tiembla': 0,
    'avebanco': 0,
    'correa': 0,
    'guineos': null,
    'galletas': null,
    'galleta': 0,
    'tarjeta': null,
    'vuela': null,
    'polvo': null,
    'tumbo': 0,
    'ave': null,
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

  // camino.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        d = _dir(p) < 0 ? -1 : 1,
        h = alto(id);
    c.globalAlpha = p['al'] == null ? 1 : (p['al'] as num).toDouble();
    if (id == 'abuela') {
      final ps = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      c.save();
      c.translate(x.toDouble(), (y - 50).toDouble());
      if (d < 0) c.scale(-1, 1);
      c.drawImage(
        host.lib.spr('ab$ps$habla', () => mkAbuela(ps, habla != 0)),
        -30,
        0,
      );
      c.restore();
      if (p['lleva'] == 'cesta') {
        c.drawImage(host.lib.spr('cesta', mkCesta), x + 2, y - 26);
        for (var i = 0; i < _n(p['guineos']); i++) {
          guineo(c, x + 3 + i * 6, y - 31 - (i % 2), .7);
        }
      }
      c.globalAlpha = 1;
      return;
    }
    final pose = p['pose'] == 'wave'
        ? 'wave${a % 2}'
        : p['pose'] == 'alto'
        ? 'wave0'
        : p['pose'] == 'dedos'
        ? 'wave0'
        : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
    final sent = jsTruthy(p['sent']);
    final im = host.lib.spr(
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
                  : 0))
          .toDouble(),
    );
    if (jsTruthy(p['corre'])) {
      c.translate(0, im.h.toDouble());
      c.rotate(.26 * d);
      c.translate(0, -im.h.toDouble());
    }
    if (d < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    if (p['lleva'] == 'cesta') {
      fr(c, x - 8, y - h + 20, 2, 7, RP.orng[0]);
      fr(c, x + 6, y - h + 20, 2, 7, RP.orng[0]);
      fr(c, x - 8, y - h + 19, 16, 2, RP.orng[0]);
      c.drawImage(host.lib.spr('cesta', mkCesta), x - 10, y - h + 26);
      final gt = W['gato'] as Map<String, dynamic>?;
      if (gt != null && gt['en'] == 'cesta') {
        c.drawImage(
          host.lib.spr('gtduerme0', () => mkGato('duerme', false)),
          x - 13,
          y - h + 12,
        );
      }
    }
    // counting on his fingers
    if (jsTruthy(p['dedos'])) {
      for (var i = 0; i < (p['dedos'] as num); i++) {
        fr(c, x + d * 9 + i * 4 - 1, y - h - 9, 4, 8, OUT);
        fr(c, x + d * 9 + i * 4, y - h - 8, 2, 6, QUIEN[id]!.piel[3]);
      }
    }
    c.globalAlpha = 1;
  }

  // camino.js: animal
  void animal(Ctx c, String k, int a) {
    final o = W[k] as Map<String, dynamic>?;
    if (o == null || o['vis'] == 0 || o['en'] != null) return;
    final pose = o['pose'] as String;
    final f =
        (pose == 'walk' ||
            pose == 'husmea' ||
            pose == 'run' ||
            pose == 'bark' ||
            pose == 'eat' ||
            pose == 'lava')
        ? (a >> (pose == 'run' ? 0 : 1)) % 2
        : 0;
    final im = k == 'perro'
        ? host.lib.spr('pe$pose$f', () => mkPerro(pose, f != 0))
        : host.lib.spr('gt$pose$f', () => mkGato(pose, f != 0));
    final d = _dir(o) < 0 ? -1 : 1;
    c.save();
    // sheet moves line 84: `c.save();c.translate(...)` -> `c.save();c.globalAlpha=o.al==null?1:o.al;c.translate(...)`
    c.globalAlpha = o['al'] == null ? 1 : (o['al'] as num).toDouble();
    c.translate(
      _round(o['x'] as num).toDouble(),
      (_round(o['y'] as num) - im.h + 2 + _n(o['dy'])).toDouble(),
    );
    if (d < 0) c.scale(-1, 1);
    c.drawImage(im, -13, 0);
    c.restore();
    // its bubble, where the sheet's talk puts it (code line 85)
    if (jsTruthy(o['bub'])) {
      final t = talkPlace(
        [_round(o['x'] as num), _round(o['y'] as num) - 22],
        8,
        o['bub'],
        W,
      );
      bub2(c, o['bub'] as String, t[0], t[1], a);
    }
  }

  // camino.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0,
        dy = _round(q['dy'] as num);
    // camino.js:87, the dotted shadow, is dropped (sheet: shadows.dropped): the engine casts his
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    final im = host.lib.spr(
      'cq${jsNum(s)}_$bl$op',
      () => mkCoqui(s, bl, op != 0),
    );
    if (jsTruthy(W['arrastra'])) {
      // pulled off his feet by the leash
      g.save();
      g.translate(b.x + b.w / 2, b.y + dy + b.h / 2 - 5);
      g.rotate(-.5 * ((W['arrastra'] as num) < 0 ? -1 : 1));
      g.drawImage(im, -b.w / 2, -b.h / 2);
      g.restore();
    } else {
      g.drawImage(im, b.x, b.y + dy);
    }
    g.globalAlpha = 1;
    if (W['guineos'] != null) {
      final cx = b.x + (b.w.toInt() >> 1) + _round(_n(W['tumbo']));
      g.drawImage(host.lib.spr('cesta', mkCesta), cx - 10, b.y + dy - 9);
      for (var i = 0; i < (W['guineos'] as num); i++) {
        guineo(g, cx - 9 + i * 6, b.y + dy - 14 - (i % 2), .7);
      }
    }
    if (jsTruthy(W['galleta'])) {
      galleta(g, b.x + (b.w.toInt() >> 1) - 4, b.y + dy - 8, 1);
    }
  }

  // camino.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // camino.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gm = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // camino.js:95 c.drawImage(spr("camino"...), fondo()) -> the set, for setKey(W) (sheet: dropped)
    // a tree that has been counted stays lit
    final lit = W['lit'] is List ? W['lit'] as List : const [];
    for (final i in lit) {
      final p = ARBOL[(i as num).toInt()];
      c.strokeStyle = (F >> 2) % 2 != 0 ? _ring0 : _ring1;
      c.lineWidth = 2;
      c.beginPath();
      c.ellipse(p[0], p[1] - 30, 19, 16, 0, 0, 7);
      c.stroke();
    }
    // the birds in the three trees; the cat's tail or face, if it is up one
    if (jsTruthy(W['tiembla']) && F - (W['tiembla'] as num) < 10) {
      for (final p in ARBOL) {
        const ds = [
          [-18, -36],
          [16, -40],
          [-14, -18],
          [18, -22],
        ];
        for (var k = 0; k < ds.length; k++) {
          final d = ds[k];
          fr(c, p[0] + d[0] + ((F + k) % 2) * 2, p[1] + d[1], 3, 2, RP.grn[4]);
        }
      }
    }
    final pajaros = W['pajaros'] is List ? W['pajaros'] as List : const [];
    for (var i = 0; i < pajaros.length; i++) {
      final n = pajaros[i] as num;
      for (var k = 0; k < n; k++) {
        final p = NIDO[k], f = ((F >> 3) + k) % 2;
        final im = host.lib.spr('pj$f', () => mkPajarito(f != 0));
        c.smoothing = false;
        c.drawImage(
          im,
          ARBOL[i][0] + p[0] - 8,
          ARBOL[i][1] +
              p[1] -
              6 -
              (jsTruthy(W['vuelan']) ? _round(W['vuelan'] as num) : 0),
          15,
          12,
        );
      }
    }
    final gato = W['gato'] as Map<String, dynamic>?;
    if (gato != null && gato['en'] != null && gato['en'] is num) {
      final p = ARBOL[(gato['en'] as num).toInt()], f = (F >> 3) % 2;
      if (gato['pose'] == 'cara') {
        c.drawImage(
          host.lib.spr('gtcara0', () => mkGato('cara', false)),
          p[0] - 12,
          p[1] - 34,
        );
      } else if (gato['pose'] == 'cola') {
        c.drawImage(
          host.lib.spr('gtcola$f', () => mkGato('cola', f != 0)),
          p[0] + (jsTruthy(gato['lado']) ? gato['lado'] as num : 1) * 9 - 12,
          p[1] - 20,
        );
      }
    }
    // everyone, from the back to the front; each item says who it is (for the front masks)
    final L = <CaminoItem>[];
    for (final id in Gm.keys) {
      final p = Gm[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(CaminoItem(p['y'] as num, () => gente(c, id, a), id: id));
      }
    }
    for (final k in const ['perro', 'gato']) {
      final o = W[k] as Map<String, dynamic>?;
      if (o != null && o['vis'] != 0 && o['en'] == null) {
        L.add(CaminoItem(o['y'] as num, () => animal(c, k, a), k: k));
      }
    }
    if (jsTruthy(q['vis'])) {
      L.add(CaminoItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    final caracol = W['caracol'] as Map<String, dynamic>?;
    if (caracol != null) {
      L.add(
        CaminoItem(caracol['y'] as num, () {
          final f = (F >> 3) % 2;
          c.drawImage(
            host.lib.spr('car$f', () => mkCaracol(f != 0)),
            _round(caracol['x'] as num) - 9,
            _round(caracol['y'] as num) - 12,
          );
        }),
      );
    }
    final ar = W['arbusto'] as List?;
    if (ar != null) {
      L.add(
        CaminoItem((ar[1] as num) + 2, () {
          c.drawImage(
            host.lib.spr('arbusto', mkArbusto),
            (ar[0] as num) - 22,
            (ar[1] as num) - 28,
          );
          final pe = W['perro'] as Map<String, dynamic>?;
          if (pe != null && pe['vis'] == 0 && jsTruthy(W['correaA'])) {
            final x = (ar[0] as num) - 25, y = (ar[1] as num) - 9;
            fr(c, x - 1, y - 1, 7, 5, OUT);
            fr(c, x - 3, y - 5, 5, 6, OUT);
            fr(c, x, y, 5, 3, _leashEnd);
            fr(c, x - 2, y - 4, 3, 4, _leashEnd);
          }
        }),
      );
    }
    // camino.js:107 the sorted list: the bench's entry and the arch's (sheet: front.parts.banco, sortY 134.5;
    // front.parts.porton, sortY 9999, after everyone)
    late final List<CaminoItem> sorted;
    L.add(CaminoItem(_sortBanco, () => front('banco', sorted), front: 'banco'));
    L.add(
      CaminoItem(_sortPorton, () => front('porton', sorted), front: 'porton'),
    );
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
    // the leash, from the frog's hand to the dog's collar
    final pe = W['perro'] as Map<String, dynamic>?;
    if (jsTruthy(W['correa']) &&
        pe != null &&
        (jsTruthy(q['vis']) || jsTruthy(W['correaDe']))) {
      final b = frogBox(q),
          lu = jsTruthy(W['correaDe'])
              ? Gm[W['correaDe']] as Map<String, dynamic>?
              : null;
      final num x0 = lu != null
          ? _round(lu['x'] as num) +
                ((pe['x'] as num) < (lu['x'] as num) ? -10 : 10)
          : ((pe['x'] as num) < (q['x'] as num) + 16 ? b.x + 3 : b.x + b.w - 3);
      final num y0 = lu != null
          ? _round(lu['y'] as num) - 18
          : b.y + _round(q['dy'] as num) + b.h - 9;
      final ca = W['correaA'] as List?;
      final num x1 = ca != null
          ? ca[0] as num
          : _round(pe['x'] as num) + (_dir(pe) < 0 ? -8 : 8);
      final num y1 = ca != null ? ca[1] as num : _round(pe['y'] as num) - 11;
      const n = 14;
      final sag = W['correa'] == 'floja' ? 6 : 1;
      c.fillStyle = _leash;
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        c.fillRect(
          _round(x0 + (x1 - x0) * t),
          _round(y0 + (y1 - y0) * t + math.sin(math.pi * t) * sag),
          2,
          1,
        );
      }
    }
    if (jsTruthy(W['vuela'])) {
      final v = W['vuela'] as Map<String, dynamic>;
      (v['k'] == 'guineo' ? guineo : galleta)(
        c,
        _round(v['x'] as num),
        _round(v['y'] as num),
        1,
      );
    }
    if (jsTruthy(W['polvo'])) {
      final p = W['polvo'] as Map<String, dynamic>,
          dir = p['dir'] as num,
          px = p['x'] as num,
          py = p['y'] as num;
      for (var i = 0; i < 3; i++) {
        fr(c, px + dir * (4 + i * 6) - 2, py - 2 - i % 2 * 3, 4, 3, _white);
        fr(c, px + dir * (4 + i * 6) - 1, py - 1 - i % 2 * 3, 3, 2, _dust);
      }
      if (jsTruthy(p['lin'])) {
        for (var i = 0; i < 3; i++) {
          final lx = px + dir * 10 - (i % 2) * 4, ly = py - 10 - i * 5;
          fr(c, lx - 1, ly - 1, 16, 4, _speed);
          fr(c, lx, ly, 14, 2, _white);
        }
      }
    }
    // a bird on the bench (a picture pair): sheet moves line 112, at points.ave_banco
    if (jsTruthy(W['avebanco'])) {
      final im = host.lib.spr('pj0', () => mkPajarito(false));
      c.smoothing = false;
      c.drawImage(im, _aveBanco[0], _aveBanco[1], 15, 12);
    }
    // camino.js:113 a person's bubble, where the sheet's talk puts it
    for (final id in Gm.keys) {
      final p = Gm[id] as Map<String, dynamic>?;
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
    // camino.js:114 the frog's bubble, where the sheet's talk puts it
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = frogBox(q),
          t = talkPlace(
            [
              b.x + (b.w.toInt() >> 1),
              b.y + 2 - (W['guineos'] != null ? 16 : 0),
            ],
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

  // camino-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside
  // the head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view,
  // clear of the corner card shown and of every face (each visible person's and the frog's, its own too); if none is,
  // [top].
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
      final hd =
          T.heads[id + (jsTruthy(p['sent']) && id != 'abuela' ? '.sent' : '')]!;
      final flip = _dir(p) < 0,
          x = _round(p['x'] as num),
          y = _round(p['y'] as num);
      final hx = flip ? x - hd.head + (id == 'abuela' ? 0 : 1) : x + hd.head;
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
    num field(String f) => _n(w[f]);
    if (w['tarjeta'] == 'galletas') {
      boards.addAll(T.boardsOf('tarjeta galletas', field));
    }
    if (w['tarjeta'] == 'guineos') {
      boards.addAll(T.boardsOf('tarjeta guineos', field));
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

  // camino.js: talkAt (sheet: code line 116, relative to the person: unchanged)
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

  // camino.js: respIcon
  // the doing bubbles, moving pictures: camina (easy steps), corre (flat out, dust), espera (quite still), despacio
  // (tiny steps, a snail keeps up), rapido (long quick steps)
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    final im = host.lib.spr('cq.6_0', () => mkCoqui(.6, 0, false));
    void suelo() => fr(g, x + 4, y + 32, 32, 1, _trail);
    void lin(int n, num l, int col) {
      for (var i = 0; i < n; i++) {
        fr(g, x + 3 + ((F * 2 + i * 5) % 6), y + 12 + i * 6, l, 2, col);
      }
    }

    suelo();
    if (k == 'espera') {
      g.drawImage(im, x + 6, y + 12);
      fr(g, x + 9, y + 30, 5, 2, RP.tan[1]);
      fr(g, x + 18, y + 30, 5, 2, RP.tan[1]);
      mano(g, x + 27, y + 5);
    } else if (k == 'corre') {
      final up = (F % 2) != 0 ? 2 : 0;
      g.save();
      g.translate((x + 24).toDouble(), (y + 21 - up).toDouble());
      g.rotate(.3);
      g.drawImage(im, -10, -9);
      g.restore();
      lin(3, 9, _speed);
      for (final p in const [
        [5, 29],
        [11, 27],
      ]) {
        fr(g, x + p[0] - (F % 3), y + p[1], 4, 3, _cardDust);
      }
    } else if (k == 'rapido') {
      final up = (F % 2) != 0 ? 2 : 0;
      g.drawImage(im, x + 15, y + 12 - up);
      lin(3, 6, _speed);
      const ps = [
        [18, 30],
        [27, 30],
      ];
      for (var i = 0; i < ps.length; i++) {
        fr(g, x + ps[i][0] + ((F + i) % 2) * 3, y + ps[i][1], 5, 2, RP.tan[1]);
      }
    } else if (k == 'despacio') {
      final up = (F >> 3) % 2 != 0 ? 1 : 0;
      g.drawImage(im, x + 14, y + 12 - up);
      final f = (F >> 3) % 2;
      g.drawImage(
        host.lib.spr('car$f', () => mkCaracol(f != 0)),
        x + 2,
        y + 23,
      );
      for (final p in const [
        [18, 30],
        [25, 30],
      ]) {
        fr(g, x + p[0], y + p[1], 4, 2, RP.tan[1]);
      }
    } else {
      final up = (F >> 2) % 2 != 0 ? 3 : 0;
      g.drawImage(im, x + 12, y + 11 - up);
      const ps = [
        [2, 29],
        [7, 25],
      ];
      for (var i = 0; i < ps.length; i++) {
        if (((F >> 2) + i) % 3 != 0) {
          fr(g, x + ps[i][0] - 1, y + ps[i][1] - 1, 6, 4, OUT);
          fr(g, x + ps[i][0], y + ps[i][1], 4, 2, _step);
        }
      }
      final ax = x + 33 + ((F >> 2) % 2), ay = y + 20;
      fr(g, ax - 1, ay, 6, 3, _leaf);
      for (final r in const [
        [5, -3, 2, 9],
        [7, -1, 2, 5],
        [9, 0, 1, 3],
      ]) {
        fr(g, ax + r[0], ay + r[1], r[2], r[3], _leaf);
      }
    }
    return null;
  }

  /* ---------- what is at stake, in the corner of the screen ---------- */

  // camino.js: hud
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (W['tarjeta'] == 'galletas') {
      // one biscuit a round: a heart if the cat got it, a paw mark if Canelo did
      tarjeta(g, 3, 3, 88, 30);
      g.drawImage(host.lib.spr('gtsit0', () => mkGato('sit', false)), 5, 7);
      final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
      for (var i = 0; i < marcas.length; i++) {
        final m = marcas[i], x = 34 + i * 18, y = 10;
        if (m == 'c') {
          heart(g, x, y + 1, 2);
        } else if (m == 'p') {
          g.fillStyle = _paw;
          g.fillRect(x + 3, y + 8, 8, 7);
          for (final d in const [
            [1, 3],
            [5, 1],
            [9, 1],
            [13, 3],
          ]) {
            g.fillRect(x + d[0] - 1, y + d[1] + 1, 3, 4);
          }
        } else {
          galleta(g, x, y + 3, 1.5);
        }
      }
    }
    if (W['tarjeta'] == 'guineos') {
      tarjeta(g, 3, 3, 84, 30);
      g.drawImage(host.lib.spr('cesta', mkCesta), 5, 13);
      for (var i = 0; i < 3; i++) {
        if (i < _n(W['guineos'])) {
          guineo(g, 30 + i * 17, 10, 1.5);
        } else {
          g.fillStyle = _slot;
          g.fillRect(30 + i * 17, 24, 12, 2);
        }
      }
    }
  }

  /* ---------- what can happen here ---------- */

  // DECISION(order 31b, as El balcón's, La sala's and El patio's): the scene's random draws come from the game's one Rng,
  // as Math.random was one: the one the registry's factory is given (`createCamino`, from the story runner's `rng`)
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'El camino was made without a random source (Rng) but draws a random number',
      ));

  // camino.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0, Object? corre]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(
            3,
            _round(math.sqrt(dx * dx + dy * dy) / (jsTruthy(corre) ? 10 : 5)),
          );
    p['sent'] = 0;
    p['paso'] = 1;
    p['corre'] = jsTruthy(corre) ? 1 : 0;
    if ((x - x0).abs() > 3) p['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n;
      await wait(TICK);
    }
    p['x'] = x;
    p['y'] = y;
    p['paso'] = 0;
    p['corre'] = 0;
  }

  // camino.js: animalA
  Future<void> animalA(String k, num x, num y, String pose, [num? n0]) async {
    final o = W[k] as Map<String, dynamic>?;
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num;
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(
            3,
            _round(math.sqrt(dx * dx + dy * dy) / (pose == 'run' ? 11 : 5)),
          );
    o['pose'] = pose;
    if ((x - x0).abs() > 3) o['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      o['x'] = x0 + (x - x0) * i / n;
      o['y'] = y0 + (y - y0) * i / n;
      await wait(TICK);
    }
    o['x'] = x;
    o['y'] = y;
  }

  // camino.js: enT (sheet: code line 138, the floor rule: the same screen places). The frog on the walk back (story 14)
  List<num> enT(num t) {
    final x = 40 + 146 * t, y = 194 - 58 * t - 8 * math.sin(math.pi * t);
    return [_round(x - 10), _round(y - 14), 1 - .14 * t];
  }

  // camino.js: perroT (sheet: code line 139, the floor rule: the same screen places). The dog on the walk back
  List<num> perroT(num t) {
    final tt = math.max(0, t - .12),
        x = 40 + 146 * tt,
        y = 194 - 58 * tt - 8 * math.sin(math.pi * tt);
    return [_round(x) - 2, _round(y) + 16];
  }

  // camino.js: ranaXY
  List<num> ranaXY() {
    final b = frogBox(W['cq'] as Map<String, dynamic>);
    return [b.x + (b.w.toInt() >> 1), b.y + 6];
  }

  // camino.js: junto. Where the dog stands: a little ahead of the frog
  List<int> junto() {
    final pos = W['pos'] as Map<String, dynamic>?;
    return perroEn(pos != null ? pos['cq'] as num : 0);
  }

  // camino.js: ladra
  Future<void> ladra([num? n0]) async {
    final o = W['perro'] as Map<String, dynamic>;
    o['pose'] = 'bark';
    final n = n0 == null || n0 == 0 || n0.isNaN ? 2 : n0;
    for (var k = 0; k < n; k++) {
      tone(520, 0, .07, 'square', .05, 300);
      tone(400, .07, .1, 'square', .05, 240);
      await wait(330);
    }
    o['pose'] = 'sit';
  }

  // DECISION(order 32b, as El patio's): a position an act reads from the story file (`+o.x`, `+o.y`: acts.anda, perroa,
  // gatoa) goes through the sheet's remap, as the runner sends a set step's x and y (page 12, section 5: every position a
  // story file holds; the sheet's remap lists these uses, d-corre beats.49 the one that moves)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic> get _pe => W['perro'] as Map<String, dynamic>;
  Map<String, dynamic> get _gt => W['gato'] as Map<String, dynamic>;
  Map<String, dynamic> get _pos => W['pos'] as Map<String, dynamic>;
  List<dynamic> get _pajaros => W['pajaros'] as List<dynamic>;

  Future<void> _va(Map<String, dynamic> o) => acts['va']!(o);

  // camino.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'anda': (o) async {
      final L = _fromFile(o['x'], o['y']);
      await mueve('${o['quien']}', L[0], L[1], null, o['corre']);
      if (jsTruthy(o['dir'])) G('${o['quien']}')!['dir'] = _plus(o['dir']);
    },
    'burbuja': (o) async {
      if (o['quien'] == 'cq') {
        _cq['bub'] = o['que'];
        SFX.coqui();
        host.bounce(6);
      } else if (o['quien'] == 'perro' || o['quien'] == 'gato') {
        (W['${o['quien']}'] as Map<String, dynamic>)['bub'] = o['que'];
      } else if (G('${o['quien']}') != null) {
        G('${o['quien']}')!['bub'] = o['que'];
      }
    },
    'calla': (o) async {
      for (final p in (W['gente'] as Map<String, dynamic>).values) {
        if (p != null) (p as Map<String, dynamic>)['bub'] = null;
      }
      _cq['bub'] = null;
      if (jsTruthy(W['perro'])) _pe['bub'] = null;
      if (jsTruthy(W['gato'])) _gt['bub'] = null;
    },
    'pose': (o) async {
      if (o['quien'] == 'perro' || o['quien'] == 'gato') {
        (W['${o['quien']}'] as Map<String, dynamic>)['pose'] = o['que'];
        return;
      }
      final p = G('${o['quien']}');
      if (p != null) {
        p['pose'] = o['que'];
        if (jsTruthy(o['dir'])) p['dir'] = _plus(o['dir']);
      }
    },
    'saluda': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      p['pose'] = 'wave';
      await wait(_plusOr(o['ms'], 700));
      p['pose'] = 'idle';
    },
    'rie': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      p['rie'] = 1;
      await wait(_plusOr(o['ms'], 700));
      p['rie'] = 0;
    },
    'ladra': (o) async {
      await ladra(_plusOr(o['n'], 2));
    },
    'perroa': (o) async {
      final j = o['a'] == 'junto' ? junto() : _fromFile(o['x'], o['y']);
      await animalA('perro', j[0], j[1], jsTruthy(o['corre']) ? 'run' : 'walk');
      _pe['pose'] = jsTruthy(o['que']) ? o['que'] : 'sit';
      if (jsTruthy(o['dir'])) _pe['dir'] = _plus(o['dir']);
    },
    'gatoa': (o) async {
      _gt['en'] = null;
      final L = _fromFile(o['x'], o['y']);
      await animalA('gato', L[0], L[1], jsTruthy(o['corre']) ? 'run' : 'walk');
      _gt['pose'] = jsTruthy(o['que']) ? o['que'] : 'sit';
      if (jsTruthy(o['dir'])) _gt['dir'] = _plus(o['dir']);
    },
    // Luis counts on his fingers: one, two, three
    'cuenta': (o) async {
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'luis')!;
      if (jsTruthy(o['fin'])) {
        p['dedos'] = 0;
        p['pose'] = 'idle';
        return;
      }
      p['pose'] = 'dedos';
      for (var i = 1; i <= 3; i++) {
        p['dedos'] = i;
        SFX.blip();
        await wait(_plusOr(o['ms'], 330));
      }
      if (jsTruthy(o['fin'])) {
        p['dedos'] = 0;
        p['pose'] = 'idle';
        return;
      }
      // queda: the three fingers stay up while the line is said
      if (jsTruthy(o['queda'])) return;
      await wait(250);
      p['dedos'] = 0;
      p['pose'] = 'idle';
    },
    // Escuchar: the frog alone goes to a stone (the dog stays where he is); a tree shakes
    'ranaa': (o) async {
      final L = ranaEn(_plus(o['a']));
      await host.hopTo(L[0], L[1], _plusOr(o['h'], 2).toInt(), L[2]);
      _pos['cq'] = _plus(o['a']);
    },
    'sacude': (o) async {
      W['twinkle'] = o['en'];
      SFX.swoop();
      await wait(500);
      W['twinkle'] = null;
    },
    'lame': (o) async {
      final f = ranaXY(), pe = _pe;
      await animalA('perro', f[0] - 14, f[1] + 22, 'walk');
      pe['dir'] = 1;
      pe['pose'] = 'eat';
      _cq['bub'] = 'amor';
      SFX.coqui();
      host.bounce(5);
      await wait(900);
      _cq['bub'] = null;
      pe['pose'] = 'sit';
    },
    /* ---- story 12: do what Luis calls ---- */
    // sheet moves line 160: `async inicio12(){W.gente=...` -> `async inicio12(){W.respEn=[134,14];W.gente=...` (code line
    // 160: luis at 174, 138, the floor rule)
    'inicio12': (o) async {
      W['respEn'] = _p.respEn(160);
      final lu = _p.floor(160, 174, 138), n0 = ninaEn(0);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'wave',
          'dir': -1,
        },
        'carmen': <String, dynamic>{'x': n0[0], 'y': n0[1], 'pose': 'idle'},
      };
      W['pos'] = <String, dynamic>{'cq': 0, 'carmen': 0};
      final L = ranaEn(0);
      _cq
        ..['x'] = L[0]
        ..['y'] = L[1]
        ..['s'] = L[2];
      final j = junto();
      W['perro'] = <String, dynamic>{
        'x': j[0],
        'y': j[1],
        'pose': 'bark',
        'dir': 1,
      };
      await wait(500);
      G('luis')!['pose'] = 'idle';
      _pe['pose'] = 'sit';
    },
    // one of them goes to a stone, in one of three ways: camina (easy steps), corre (flat out, dust), espera (stands
    // quite still)
    'va': (o) async {
      final quien = o['quien'], modo = o['modo'];
      final i = math.max(0, math.min(8, _plus(o['a'])));
      if (quien == 'carmen') {
        final p = G('carmen')!, t = ninaEn(i);
        if (modo == 'espera') {
          p['pose'] = 'idle';
          await wait(900);
        } else {
          await mueve('carmen', t[0], t[1], null, modo == 'corre');
        }
        _pos['carmen'] = modo == 'espera' ? _pos['carmen'] : i;
        return;
      }
      final q = _cq, L = ranaEn(i);
      if (modo == 'espera') {
        await wait(900);
        return;
      }
      if (modo == 'corre') {
        W['polvo'] = <String, dynamic>{
          'x': frogBox(q).x,
          'y': (q['y'] as num) + 26,
          'dir': -1,
          'lin': 1,
        };
        final pe = animalA('perro', perroEn(i)[0], perroEn(i)[1], 'run');
        await host.hopTo(L[0], L[1], 1, L[2]);
        await pe;
        W['polvo'] = null;
      } else {
        final pe = animalA('perro', perroEn(i)[0], perroEn(i)[1], 'walk', 16);
        await host.hopTo(L[0], L[1], 3, L[2]);
        await pe;
      }
      _pe['pose'] = 'sit';
      _pe['dir'] = 1;
      _pos['cq'] = i;
    },
    'luisno': (o) async {
      final p = G('luis')!;
      for (var k = 0; k < 4; k++) {
        p['dir'] = -_dir(p);
        await wait(140);
      }
      p['dir'] = -1;
      SFX.bonk();
      await wait(250);
    },
    'luisrie': (o) async {
      final p = G('luis')!;
      p['rie'] = 1;
      p['pose'] = 'wave';
      await wait(650);
      p['rie'] = 0;
      p['pose'] = 'idle';
    },
    // one call for both of them. Right (or under the sign): both do it and end one stone on. After a wrong move that
    // was put right: the frog does it on the spot.
    'ronda': (o) async {
      final m = o['modo'],
          bien = V['ok'] != '',
          mal = o['mal'],
          pc = _pos['cq'] as num,
          pk = _pos['carmen'] as num;
      if (jsTruthy(mal)) {
        final mov = mal != 'espera';
        await Future.wait([
          _va({'quien': 'cq', 'modo': mal, 'a': mov ? pc + 1 : pc}),
          _va({'quien': 'carmen', 'modo': m, 'a': pk + 1}),
        ]);
        await acts['luisno']!({});
        if (mov) {
          await _va({'quien': 'cq', 'modo': 'camina', 'a': pc});
        }
        return;
      }
      if (!bien) {
        if (m == 'espera') {
          await wait(700);
          await acts['luisrie']!({});
          await _va({'quien': 'carmen', 'modo': 'camina', 'a': pk + 1});
        } else {
          host.bounce(m == 'corre' ? 9 : 5);
          await wait(350);
          host.bounce(m == 'corre' ? 9 : 5);
          await wait(500);
        }
        return;
      }
      if (m == 'espera') {
        await Future.wait([
          _va({'quien': 'cq', 'modo': 'espera', 'a': pc}),
          _va({'quien': 'carmen', 'modo': 'espera', 'a': pk}),
        ]);
        await acts['luisrie']!({});
        await Future.wait([
          _va({'quien': 'cq', 'modo': 'camina', 'a': pc + 1}),
          _va({'quien': 'carmen', 'modo': 'camina', 'a': pk + 1}),
        ]);
      } else {
        await Future.wait([
          _va({'quien': 'cq', 'modo': m, 'a': pc + 1}),
          _va({'quien': 'carmen', 'modo': m, 'a': pk + 1}),
        ]);
      }
    },
    // a call for each of them: f is the frog's, c is Carmen's
    'ronda2': (o) async {
      final f = o['f'],
          cm = o['c'],
          bien = V['ok'] != '',
          mal = o['mal'],
          pc = _pos['cq'] as num,
          pk = _pos['carmen'] as num;
      Future<void> car() async {
        if (cm == 'espera') {
          await _va({'quien': 'carmen', 'modo': 'espera', 'a': pk});
        } else {
          await _va({'quien': 'carmen', 'modo': cm, 'a': pk + 1});
        }
      }

      if (jsTruthy(mal)) {
        final mov = mal != 'espera';
        await Future.wait([
          _va({'quien': 'cq', 'modo': mal, 'a': mov ? pc + 1 : pc}),
          car(),
        ]);
        await acts['luisno']!({});
        if (mov) await _va({'quien': 'cq', 'modo': 'camina', 'a': pc});
        if (cm == 'espera') {
          await acts['luisrie']!({});
          await _va({'quien': 'carmen', 'modo': 'camina', 'a': pk + 1});
        }
        return;
      }
      if (!bien) {
        if (f == 'espera') {
          await wait(700);
        } else {
          host.bounce(f == 'corre' ? 9 : 5);
          await wait(350);
          host.bounce(f == 'corre' ? 9 : 5);
          await wait(500);
        }
        return;
      }
      await Future.wait([
        _va({'quien': 'cq', 'modo': f, 'a': f == 'espera' ? pc : pc + 1}),
        car(),
      ]);
      if (f == 'espera' || cm == 'espera') {
        await acts['luisrie']!({});
        await Future.wait([
          f == 'espera'
              ? _va({'quien': 'cq', 'modo': 'camina', 'a': pc + 1})
              : Future<void>.value(),
          cm == 'espera'
              ? _va({'quien': 'carmen', 'modo': 'camina', 'a': pk + 1})
              : Future<void>.value(),
        ]);
      }
    },
    'alinicio': (o) async {
      final n0 = ninaEn(0);
      await Future.wait([
        _va({'quien': 'cq', 'modo': 'camina', 'a': 0}),
        mueve('carmen', n0[0], n0[1]),
      ]);
      W['pos'] = <String, dynamic>{'cq': 0, 'carmen': 0};
      G('carmen')!['dir'] = 1;
    },
    // the rule, shown once: Canelo cannot wait; Luis shakes his head; Canelo walks back
    'demo': (o) async {
      final pe = _pe, L = perroEn(math.min(8, (_pos['cq'] as num) + 2));
      await wait(300);
      await animalA('perro', L[0], L[1], 'run');
      pe['pose'] = 'sit';
      await acts['luisno']!({});
    },
    'demo2': (o) async {
      final pe = _pe, j = junto();
      await animalA('perro', j[0], j[1], 'walk', 14);
      pe['pose'] = 'sit';
      pe['dir'] = 1;
      await wait(300);
    },
    // code line 186: Carmen to 160, 146 (the floor rule); the dog to LUGAR.gran - (12, -28); code line 187: the stars,
    // a screen effect, unchanged
    'final12': (o) async {
      final n = _n(W['lost']), ca = G('carmen')!, L = LUGAR['gran']!;
      final cp = _p.floor(186, 160, 146);
      Future<void> car() => mueve('carmen', cp[0], cp[1]);
      Future<void> yo() async {
        final pe = animalA('perro', L[0] - 12, L[1] + 28, 'run');
        await host.hopTo(L[0], L[1], 3, L[2]);
        await pe;
        _pe['pose'] = 'sit';
      }

      if (n == 0) {
        await Future.wait([car(), yo()]);
        host.bounce(8);
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 36,
          'pts': const [
            [150, 60],
            [196, 70],
            [176, 50],
            [160, 90],
            [200, 96],
          ],
        });
        await wait(900);
      } else if (n < 3) {
        await car();
        ca['pose'] = 'wave';
        await yo();
        ca['pose'] = 'idle';
        SFX.win();
        await wait(600);
      } else {
        await car();
        ca['sent'] = 1;
        G('luis')!['sent'] = 1;
        await wait(500);
        await yo();
        SFX.coqui();
        await wait(600);
      }
      ca['sent'] = 1;
      G('luis')!['sent'] = 1;
      await wait(400);
    },
    'ladra3': (o) async {
      await ladra(3);
    },
    /* ---- story 13: the cat in the trees ---- */
    // sheet moves line 193: `async inicio13(){W.sinGran=1;` -> `async inicio13(){W.sinGran=1;W.respEn=[120,34];`; code
    // line 193: luis, carmen, the dog (the floor rule); moves line 194: the cat on the bench, 113, 134 -> 92, 123
    // (points gato_banco)
    'inicio13': (o) async {
      W['sinGran'] = 1;
      W['respEn'] = _p.respEn(193);
      final lu = _p.floor(193, 62, 188),
          ca = _p.floor(193, 92, 198),
          pe = _p.floor(193, 54, 206),
          gt = _p.floor(194, 113, 134);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'idle',
          'lleva': 'cesta',
        },
      };
      W['perro'] = <String, dynamic>{
        'x': pe[0],
        'y': pe[1],
        'pose': 'sit',
        'dir': 1,
      };
      W['correa'] = 'floja';
      W['correaDe'] = 'luis';
      W['gato'] = <String, dynamic>{
        'x': gt[0],
        'y': gt[1],
        'pose': 'lava',
        'dir': -1,
        'en': null,
      };
      final L = LUGAR['centro']!;
      _cq
        ..['x'] = L[0]
        ..['y'] = L[1]
        ..['s'] = L[2];
    },
    // the birds fly up and settle again: how many sit in each tree
    'posan': (o) async {
      final List<num> n = jsTruthy(o['p'])
          ? [for (final ch in '${o['p']}'.split('')) _plus(ch)]
          : [_plus(o['a']), _plus(o['b']), _plus(o['c'])];
      if (_pajaros.any(jsTruthy)) {
        SFX.pio();
        for (var i = 1; i <= 6; i++) {
          W['vuelan'] = i * 5;
          await wait(TICK);
        }
      }
      W['pajaros'] = n;
      for (var i = 6; i >= 0; i--) {
        W['vuelan'] = i * 5;
        await wait(TICK);
      }
      W['vuelan'] = 0;
      SFX.pio();
      await wait(200);
    },
    // the cat goes to a tree; the story learns which count sits in it (n), the other two (oa, ob, in an order drawn
    // fresh), and one other for a bubble (m)
    'gatoarbol': (o) async {
      final i = _plus(o['en']).toInt(), g = _gt;
      var otros = [
        for (final k in const [0, 1, 2])
          if (k != i) _js(_pajaros[k]),
      ];
      if (_rng.next() < .5) otros = otros.reversed.toList();
      V['n'] = _js(_pajaros[i]);
      V['oa'] = otros[0];
      V['ob'] = otros[1];
      V['m'] = otros[_rng.next() < .5 ? 0 : 1];
      V['tm'] = _js(_pajaros.indexOf(_plus(V['m'])));
      if (g['en'] == null) {
        g['pose'] = 'run';
        await animalA('gato', ARBOL[i][0], ARBOL[i][1], 'run');
        SFX.swoop();
      } else if (o['que'] != 'nada') {
        SFX.swoop();
        await wait(250);
      }
      g['en'] = i;
      g['pose'] = jsTruthy(o['que']) ? o['que'] : 'cola';
      g['lado'] = i == 2 ? -1 : 1;
      await wait(300);
    },
    'asoma': (o) async {
      final g = _gt;
      if (o['en'] != null) g['en'] = _plus(o['en']);
      g['pose'] = 'cara';
      SFX.blip();
      tone(700, 0, .18, 'sine', .05, 900);
      await wait(500);
    },
    'lit': (o) async {
      W['lit'] = o['n'] == '0'
          ? null
          : const [0, 1, 2].sublist(0, math.min(3, _plus(o['n']).toInt()));
      SFX.blip();
      await wait(150);
    },
    'saca': (o) async {
      W['galleta'] = 1;
      SFX.blip();
      await wait(250);
    },
    'ronronea': (o) async {
      final g = _gt;
      g['pose'] = 'sit';
      g['bub'] = 'amor';
      tone(180, 0, .5, 'sawtooth', .02, 160);
      await wait(900);
      g['bub'] = null;
      g['pose'] = 'lava';
    },
    // the tree with that many birds twinkles
    'luzn': (o) async {
      W['twinkle'] = o['n'] == '0'
          ? null
          : 'arbol${_pajaros.indexOf(_plus(o['n']))}';
      await wait(80);
    },
    // the cat's face goes back in; all three trees shake; where it goes next is not seen
    'esconde': (o) async {
      final g = _gt;
      if (g['en'] == 'cesta') return;
      g['pose'] = 'nada';
      W['tiembla'] = F;
      SFX.swoop();
      await wait(350);
      SFX.swoop();
      await wait(350);
    },
    // code line 210: Carmen back to 92, 198 (the floor rule)
    'carmenvuelve': (o) async {
      final L = _p.floor(210, 92, 198);
      await mueve('carmen', L[0], L[1]);
      G('carmen')!['dir'] = 1;
    },
    // the cat eats this round's biscuit: a heart in the corner, for good
    'gatocome': (o) async {
      final marcas = W['marcas'] as List?;
      final i = marcas != null ? marcas.indexOf(null) : -1;
      await acts['asoma']!({});
      await wait(200);
      W['galleta'] = 0;
      SFX.munch();
      if (i >= 0 && V['ok'] != '') (W['marcas'] as List)[i] = 'c';
      await wait(600);
    },
    // Canelo jumps and gobbles it: a paw mark in the corner (code line 214: back to 54, 206, the floor rule)
    'perrocome': (o) async {
      final pe = _pe, f = ranaXY(), i = (W['marcas'] as List).indexOf(null);
      W['correa'] = 0;
      await animalA('perro', f[0] - 12, f[1] + 20, 'run');
      pe['pose'] = 'eat';
      pe['dy'] = -6;
      W['galleta'] = 0;
      SFX.munch();
      if (i >= 0) (W['marcas'] as List)[i] = 'p';
      await wait(500);
      pe['dy'] = 0;
      await wait(300);
      final L = _p.floor(214, 54, 206);
      await animalA('perro', L[0], L[1], 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = 1;
      W['correa'] = 'floja';
    },
    'acaricia': (o) async {
      await acts['asoma']!({});
      _cq['bub'] = 'amor';
      SFX.coqui();
      host.bounce(4);
      await wait(800);
      _cq['bub'] = null;
    },
    // the dog pulls loose; the birds fly up; the cat jumps about and is gone in the leaves (code line 217: Canelo to
    // 150, 150, the floor rule)
    'escapa': (o) async {
      final g = _gt;
      await ladra(2);
      W['correa'] = 0;
      final L = _p.floor(217, 150, 150);
      final corre = animalA('perro', L[0], L[1], 'run');
      SFX.pio();
      for (var i = 1; i <= 6; i++) {
        W['vuelan'] = i * 5;
        await wait(TICK);
      }
      for (var k = 0; k < 5; k++) {
        g['en'] = k % 3;
        g['pose'] = 'cola';
        SFX.swoop();
        await wait(200);
      }
      g['pose'] = 'nada';
      await corre;
      await ladra(1);
    },
    // code line 218: back to 54, 206 (the floor rule)
    'agarra': (o) async {
      final L = _p.floor(218, 54, 206);
      await animalA('perro', L[0], L[1], 'walk');
      _pe['pose'] = 'sit';
      _pe['dir'] = 1;
      W['correa'] = 'floja';
      await wait(200);
    },
    'cuentaaves': (o) async {
      for (final n in const [1, 2, 3]) {
        W['twinkle'] = 'arbol${_pajaros.indexOf(n)}';
        await wait(60);
      }
    },
    // code line 220: Carmen at a small tree (spots carmenva.i, relative to the tree: unchanged)
    'carmenva': (o) async {
      final i = _plus(o['en']).toInt(), L = _carmenva[i];
      await mueve('carmen', L[0], L[1]);
      G('carmen')!['dir'] = -1;
      await wait(250);
    },
    'mirarriba': (o) async {
      G('carmen')!['bub'] = 'q';
      await wait(700);
      G('carmen')!['bub'] = null;
    },
    'gatocesta': (o) async {
      final g = _gt;
      SFX.swoop();
      await wait(300);
      g['en'] = 'cesta';
      g['pose'] = 'duerme';
      SFX.luz();
      await wait(500);
    },
    'galletacesta': (o) async {
      final marcas = W['marcas'] as List?;
      final i = marcas != null ? marcas.indexOf(null) : -1;
      SFX.munch();
      if (i >= 0 && V['ok'] != '') (W['marcas'] as List)[i] = 'c';
      await wait(600);
    },
    // code line 224: back to 54, 206 (the floor rule)
    'perrocome2': (o) async {
      final pe = _pe, c = G('carmen')!, i = (W['marcas'] as List).indexOf(null);
      W['correa'] = 0;
      await animalA('perro', (c['x'] as num) - 14, (c['y'] as num) + 2, 'run');
      pe['pose'] = 'eat';
      SFX.munch();
      if (i >= 0) (W['marcas'] as List)[i] = 'p';
      await wait(700);
      final L = _p.floor(224, 54, 206);
      await animalA('perro', L[0], L[1], 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = 1;
      W['correa'] = 'floja';
    },
    // code line 225: Carmen to 156, 196 (the floor rule); line 226: the stars, a screen effect, unchanged
    'final13': (o) async {
      final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
      final n = marcas.where((m) => m == 'c').length,
          c = G('carmen')!,
          pe = _pe;
      final L = _p.floor(225, 156, 196);
      await mueve('carmen', L[0], L[1]);
      c['dir'] = -1;
      if (n >= 3) {
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 30,
          'pts': const [
            [90, 150],
            [150, 150],
            [120, 130],
            [100, 176],
            [140, 176],
          ],
        });
        await wait(900);
      } else if (n != 0) {
        SFX.win();
        await wait(700);
      } else {
        SFX.coqui();
        await wait(700);
      }
      W['correa'] = 0;
      await animalA('perro', (c['x'] as num) - 26, (c['y'] as num) + 4, 'walk');
      pe['pose'] = 'lie';
      pe['dir'] = 1;
      pe['bub'] = 'amor';
      await wait(900);
      pe['bub'] = null;
    },
    /* ---- story 14: the walk back with the dog ---- */
    // sheet moves line 229: `async inicio14(){W.gente={abuela:` -> `async inicio14(){W.respEn=[134,34];W.gente={abuela:`;
    // code line 229: abuela, luis, carmen (the floor rule); the bush at perroT(.46) + (16, 5) (relative: unchanged)
    'inicio14': (o) async {
      W['respEn'] = _p.respEn(229);
      final ab = _p.floor(229, 66, 182),
          lu = _p.floor(229, 88, 200),
          ca = _p.floor(229, 46, 202);
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': ab[0],
          'y': ab[1],
          'pose': 'idle',
          'dir': 1,
        },
        'luis': <String, dynamic>{'x': lu[0], 'y': lu[1], 'pose': 'idle'},
        'carmen': <String, dynamic>{'x': ca[0], 'y': ca[1], 'pose': 'idle'},
      };
      W['guineos'] = 3;
      W['t'] = 1;
      {
        final p = perroT(.46);
        W['arbusto'] = <dynamic>[_round(p[0]) + 16, _round(p[1]) + 5];
      }
      final f = enT(1);
      _cq
        ..['x'] = f[0]
        ..['y'] = f[1]
        ..['s'] = f[2];
      final d = perroT(1);
      W['perro'] = <String, dynamic>{
        'x': d[0],
        'y': d[1],
        'pose': 'sit',
        'dir': -1,
      };
      W['correa'] = 'floja';
    },
    // the two of them go on down the path. modo: trota (his easy trot), husmea (creeping, the snail keeps up), corre
    // (flat out, the frog pulled off his feet), ligero (long quick steps)
    'paseo': (o) async {
      final m = o['modo'] == 'despacio'
          ? 'husmea'
          : o['modo'] == 'rapido'
          ? 'ligero'
          : o['modo'];
      final d = _plus(jsTruthy(o['d']) ? o['d'] : .1),
          t1 = math.max(.02, (W['t'] as num) - d),
          pasos = m == 'husmea'
              ? 26
              : m == 'corre'
              ? 7
              : m == 'ligero'
              ? 9
              : 15,
          q = _cq,
          pe = _pe,
          t0 = W['t'] as num,
          solo = o['solo'];
      pe['pose'] = m == 'corre' ? 'run' : 'walk';
      pe['dir'] = -1;
      W['correa'] = m == 'corre' ? 'tensa' : 'floja';
      if (m == 'corre' && !jsTruthy(solo)) W['arrastra'] = -1;
      if (m == 'husmea') {
        W['caracol'] = <String, dynamic>{
          'x': (pe['x'] as num) - 4,
          'y': (pe['y'] as num) + 8,
        };
      } else if (solo != 'cq') {
        W['caracol'] = null;
      }
      for (var i = 1; i <= pasos; i++) {
        final t = t0 + (t1 - t0) * i / pasos,
            f = enT(solo == 'perro' ? t0 : t),
            p = perroT(solo == 'cq' ? t0 : t);
        if (solo != 'perro') {
          q['x'] = f[0];
          q['y'] = f[1] - (m == 'corre' ? 4 : 0);
          q['s'] = f[2];
          q['dy'] = m == 'corre' ? 0 : -(i % 2) * (m == 'ligero' ? 3 : 2);
        }
        if (solo != 'cq') {
          pe['x'] = p[0];
          pe['y'] = p[1];
        }
        final cr = W['caracol'] as Map<String, dynamic>?;
        if (cr != null) {
          cr['x'] = (pe['x'] as num) - 4;
          cr['y'] = (pe['y'] as num) + 8;
        }
        if (m == 'corre' || m == 'ligero') {
          W['polvo'] = <String, dynamic>{
            'x': _round(pe['x'] as num) + 10,
            'y': _round(pe['y'] as num),
            'dir': 1,
          };
        }
        if (i % 3 == 0) (m == 'corre' ? SFX.hop : SFX.blip)();
        await wait(TICK);
      }
      q['dy'] = 0;
      W['polvo'] = null;
      W['arrastra'] = 0;
      if (!jsTruthy(solo)) W['t'] = t1;
      if (m == 'corre') {
        final f = enT(W['t'] as num);
        q['y'] = f[1];
      }
      pe['pose'] = 'sit';
    },
    // the dog stops dead, nose in a flower
    'para': (o) async {
      final pe = _pe;
      W['caracol'] = null;
      pe['pose'] = 'husmea';
      W['correa'] = 'floja';
      SFX.blip();
      await wait(700);
    },
    // what the dog is doing, for him to see: he bolts and keeps pulling, or he has stopped
    'situacion': (o) async {
      final pe = _pe;
      if (o['que'] == 'corre') {
        await acts['paseo']!({'modo': 'corre', 'd': .03});
        pe['pose'] = 'run';
        W['correa'] = 'tensa';
        W['arrastra'] = -1;
      } else {
        await acts['para']!({});
      }
    },
    // wrong word: even more of the same
    'masde': (o) async {
      final pe = _pe;
      if (o['que'] == 'corre') {
        await acts['paseo']!({'modo': 'corre', 'd': .03});
      } else {
        pe['pose'] = 'lie';
        await wait(600);
      }
    },
    // the dog goes at the pace that was called, the frog at the other: the leash jerks
    'desigual': (o) async {
      await Future.wait([
        acts['paseo']!({'modo': o['p'], 'd': .07, 'solo': 'perro'}),
        acts['paseo']!({'modo': o['f'], 'd': .03, 'solo': 'cq'}),
      ]);
      W['caracol'] = null;
    },
    'vuelveperro': (o) async {
      final p = perroT(W['t'] as num);
      await animalA('perro', p[0], p[1], 'walk');
      _pe['pose'] = 'sit';
      _pe['dir'] = -1;
    },
    'trota': (o) async {
      W['caracol'] = null;
      _pe['pose'] = 'sit';
      W['correa'] = 'floja';
      await acts['paseo']!({'modo': 'trota', 'd': .06});
    },
    'tropieza': (o) async {
      final q = _cq;
      SFX.bonk();
      for (final x in const [3, -3, 4, -2, 0]) {
        W['tumbo'] = x;
        q['dy'] = -x.abs();
        await wait(TICK * 1.5);
      }
      q['dy'] = 0;
      _pe['pose'] = 'bark';
      await wait(300);
      _pe['pose'] = 'sit';
      W['tarjeta'] = 'guineos';
      SFX.luz();
      await wait(600);
    },
    // the leash jerks, a guineo falls out, and Canelo eats it
    'cae': (o) async {
      final q = _cq, b = frogBox(q), pe = _pe;
      SFX.bonk();
      W['correa'] = 'tensa';
      for (final x in const [4, -4, 3, 0]) {
        W['tumbo'] = x;
        await wait(TICK);
      }
      W['guineos'] = math.max(0, (W['guineos'] as num) - 1);
      final v = <String, dynamic>{
        'k': 'guineo',
        'x': b.x + b.w / 2,
        'y': b.y - 12,
      };
      W['vuela'] = v;
      for (var i = 1; i <= 6; i++) {
        v['x'] = b.x + b.w / 2 + ((pe['x'] as num) - b.x - b.w / 2) * i / 6;
        v['y'] =
            b.y -
            12 +
            ((pe['y'] as num) - 10 - b.y + 12) * i / 6 -
            math.sin(math.pi * i / 6) * 10;
        await wait(TICK);
      }
      W['vuela'] = null;
      pe['pose'] = 'eat';
      SFX.munch();
      await wait(700);
      pe['pose'] = 'sit';
      W['correa'] = 'floja';
    },
    // behind the bush: only the leash shows
    'arbusto': (o) async {
      final pe = _pe, ar = W['arbusto'] as List;
      await animalA('perro', (ar[0] as num) + 2, (ar[1] as num) - 4, 'walk');
      pe['vis'] = 0;
      W['correaA'] = <dynamic>[(ar[0] as num) + 6, (ar[1] as num) - 10];
      await wait(300);
    },
    'sale': (o) async {
      final pe = _pe;
      if (pe['vis'] != 0) {
        await acts['trota']!({});
        return;
      }
      pe['vis'] = 1;
      W['correaA'] = null;
      final p = perroT((W['t'] as num) - .16), ar = W['arbusto'] as List;
      pe['x'] = (ar[0] as num) - 8;
      pe['y'] = ar[1];
      await animalA('perro', p[0], p[1], o['modo'] == 'corre' ? 'run' : 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
      W['t'] = (W['t'] as num) - .1;
      final f = enT(W['t'] as num);
      await host.hopTo(f[0], f[1], 2, f[2]);
    },
    'tira': (o) async {
      final q = _cq;
      W['correa'] = 'tensa';
      for (var k = 0; k < 3; k++) {
        q['dy'] = -3;
        SFX.hop();
        await wait(160);
        q['dy'] = 0;
        await wait(160);
      }
    },
    // code line 256: the stars, a screen effect, unchanged
    'final14': (o) async {
      final n = _n(W['guineos']), ab = G('abuela')!, pe = _pe;
      W['caracol'] = null;
      final f = enT(.06);
      pe['pose'] = 'walk';
      await Future.wait([
        host.hopTo(f[0], f[1], 2, f[2]),
        animalA('perro', (ab['x'] as num) + 16, (ab['y'] as num) + 10, 'walk'),
      ]);
      pe['pose'] = 'sit';
      W['t'] = .06;
      await wait(250);
      ab['pose'] = 'offer';
      await wait(300);
      W['guineos'] = null;
      W['tarjeta'] = null;
      ab['lleva'] = 'cesta';
      ab['guineos'] = n;
      SFX.blip();
      await wait(400);
      ab['pose'] = 'idle';
      if (n >= 3) {
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 30,
          'pts': const [
            [40, 120],
            [90, 130],
            [64, 110],
            [50, 150],
            [90, 160],
          ],
        });
        await wait(900);
      } else if (n != 0) {
        SFX.win();
        await wait(700);
      } else {
        pe['pose'] = 'eat';
        ab['rie'] = 1;
        SFX.coqui();
        await wait(900);
        ab['rie'] = 0;
        pe['pose'] = 'sit';
      }
      W['correa'] = 'floja';
      W['correaDe'] = 'abuela';
      pe['bub'] = 'amor';
      await wait(700);
      pe['bub'] = null;
    },
    // sheet moves line 258 (sheet: sevan): everyone leaves the park through the arch in a file, one after another
    // (abuela, Carmen, Luis, Canelo, the frog, 3 ticks apart: sevan.delay): each walks in 4 steps to the same point just
    // inside the opening, then in 4 more through it to just past its line (sevan.points), fading as the old (al 1 - i /
    // 8) and gone; Canelo walks and fades too (moves line 84), the frog hops twice and fades
    'sevan': (o) async {
      final q = _cq, pe = _pe, SV = sheet.sevan!;
      W['correa'] = 0;
      pe['pose'] = 'walk';
      List<int> pu(String who) {
        final pts = SV.points[who]!;
        return [pts[0][0], pts[0][1], pts[1][0], pts[1][1]];
      }

      Future<void> fila(
        Map<String, dynamic> o,
        List<int> u,
        int d, [
        bool f = false,
      ]) async {
        await wait(d * TICK);
        final x0 = o['x'] as num, y0 = o['y'] as num;
        for (var i = 0; i < 8; i++) {
          final List<num> a = i < 4
              ? [x0, y0, u[0], u[1], (i + 1) / 4]
              : [u[0], u[1], u[2], u[3], (i - 3) / 4];
          o['x'] = a[0] + (a[2] - a[0]) * a[4];
          o['y'] = a[1] + (a[3] - a[1]) * a[4];
          o['al'] = 1 - i / 8;
          if (f) {
            o['x'] = _round(o['x'] as num);
            o['y'] = _round(o['y'] as num);
            if (i % 4 == 0) SFX.hop();
            o['dy'] = -7 * math.sin(math.pi * (i % 4 + 1) / 4);
          }
          await wait(TICK);
        }
        if (f) o['dy'] = 0;
        o['vis'] = 0;
      }

      await Future.wait([
        fila(G('abuela')!, pu('abuela'), SV.delay['abuela']!),
        fila(G('carmen')!, pu('carmen'), SV.delay['carmen']!),
        fila(G('luis')!, pu('luis'), SV.delay['luis']!),
        fila(pe, pu('perro'), SV.delay['perro']!),
        fila(q, pu('cq'), SV.delay['cq']!, true),
      ]);
      q['vis'] = 0;
      pe['vis'] = 0;
      await wait(500);
    },
  };

  // camino.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    SFX.bonk();
    await wait(300);
  }

  // camino.js: poke
  @override
  dynamic poke(String what) {
    final p = G(what);
    if (p != null && !jsTruthy(p['bub'])) {
      p['bub'] = 'amor';
      final my = host.runId;
      unawaited(
        host.sleep(1400 / host.FAST).then((_) {
          if (my == host.runId && p['bub'] == 'amor') p['bub'] = null;
        }),
      );
    }
    if (what == 'perro' && jsTruthy(W['perro'])) {
      unawaited(ladra(1));
    }
    return null;
  }

  // camino.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if (g[k] != null && (g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}';
          }(),
    ].join(' ');
    final pe = W['perro'] as Map<String, dynamic>?,
        gt = W['gato'] as Map<String, dynamic>?;
    final perro = pe != null
        ? '${jsNum(_round(pe['x'] as num))},${jsNum(_round(pe['y'] as num))}:${_js(pe['pose'])}'
        : '-';
    final String gato;
    if (gt == null) {
      gato = '-';
    } else {
      final where = gt['en'] != null
          ? 'en${_js(gt['en'])}'
          : '${jsNum(_round(gt['x'] as num))},${jsNum(_round(gt['y'] as num))}';
      gato = '$where:${_js(gt['pose'])}';
    }
    final pj = W['pajaros'] is List ? W['pajaros'] as List : const [];
    return 'gente=$gente perro=$perro gato=$gato pajaros=${pj.map(_js).join()}'
        ' galletas=${_js(W['galletas'])} guineos=${_js(W['guineos'])}'
        ' correa=${_js(jsTruthy(W['correa']) ? W['correa'] : 0)}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A ground point (a person's feet, the frog's, an animal's) keeps its screen place (the sheet's
  // `new`; the few the sheet moved: the cat on the bench, Canelo at the first tree); a point in the air keeps its screen
  // numbers (`to.screen`: where the answer cards stand); three counts are no place (`numbers`: W.pajaros) and are given
  // back; a pair rectangle gives the crop of the pictures it was; a level picture's rectangle or x gives itself back
  // (the level pictures are the sheet's, whole).
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
      case 3:
        final r = sheet.remap('numbers', xy);
        if (r.to.none != null) return xy;
        throw SheetError('the remap of $xy names no numbers');
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
        throw SheetError('a position is 1, 2, 3 or 4 numbers, not $xy');
    }
  }
}

/// One entry of camino.js's drawing list (`L`): the row it is sorted by, how it is drawn, and who it is
/// (camino-preview.html: `id` for a person or the frog, `k` for an animal, `front` for a part of the set drawn again).
class CaminoItem {
  CaminoItem(this.y, this.d, {this.id, this.k, this.front});

  final num y;
  final void Function() d;
  final String? id, k, front;
}
