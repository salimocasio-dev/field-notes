// Port of historia/escenas/campo.js: the scene "El campo", the open field in the park (order 34b). Line for line, minus
// its background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background, which the
// set bakes; the frog's dotted shadow, the dark bars under a ball and under Canelo in the air: the engine casts their
// shadows); every screen position replaced by what the sheet's `code` list gives for its line (campo_places.dart), and
// the places the sheet's `moves` list moves, each at its line. campo.js is written on the kit, so this is an `Escena`;
// its set is [CampoSet].
//
// What El campo's sheet has that the earlier ones did not, and how it is kept here (as campo-preview.html keeps it):
// - `helps.ring`: a ripple ring on the water round whatever floats or wades, drawn by the sprite layer just before the
//   thing ([Campo.under] before a ball, [Campo.wade] before Canelo: the two lines the sheet adds to campo.js).
// - `moves` (27) and `remap`: the places at the shore, the answer cards in the sky (W.respEn at the start of stories 15,
//   16 and 17), the ball in a child's raised hand (manos, line 59), the pairs' own places ([Campo.placePair]); a position
//   an act reads from its story file goes through remap.
// - `hops`: 6 pairs of the frog's places take one hop fewer than the old ones; LUGAR is the sheet's and the acts' own
//   hopTo give their own counts (none of the 6 pairs is walked in a recorded run).
// - `shadows`: the engine casts the shadows of the balls, Canelo, the basket, the children and the frog ([Campo.shadows]).
// - `front`: the reeds are drawn again over whoever is behind them, by the depth test ([Campo.front]), the water's surface
//   taking the place of the ground where someone stands over it (`front.waterDepth`).
// - `talk`: where a bubble goes ([Campo.talkPlace]).
// - things.arbol.hintBox and things.juncos.hintBox: their hint frames are drawn round these.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/campo/campo_places.dart';
import 'package:coqui_scenes/src/campo/campo_set.dart'
    show CampoSet, CampoState, campoEngine, campoShore;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "campo", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It draws
/// no random number.
Scene createCampo() => Campo(sheetOf('campo'));

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

final int _drop0 = hexColour('#5A9AEA'),
    _drop1 = hexColour('#A8CCF8'),
    _blue = hexColour('#2E6CD0'),
    _dust = hexColour('#E8E0C8'),
    _stripe = hexColour('#FFF4E0'),
    _stem = hexColour('#2E8A34'),
    _petal = hexColour('#F06A9A'),
    _heart = hexColour('#F0C020'),
    _wing = hexColour('#F0A0D0'),
    _ground = hexColour('#9494A6'),
    _skin = hexColour('#D09A54'),
    _arrow = hexColour('#2E9A48'),
    _jumpShadow = hexColour('#B0B0C0'),
    _sleeve = hexColour('#3E9A52'),
    _hand = hexColour('#C88A5A'),
    _paw = hexColour('#B07A3C'),
    _empty = hexColour('#C8C8D4');

const int _white = 0xFFFFFFFF;

/* ---------- the balls: told apart by size and pattern ---------- */

// campo.js: BOLA
final Map<String, ({double r, List<int> c, String m})> BOLA = {
  'L': (
    r: 7,
    c: [hexColour('#B03A2E'), hexColour('#D8574A'), hexColour('#F08A7C')],
    m: 'rayas',
  ),
  'C': (
    r: 5.5,
    c: [hexColour('#2E6CD0'), hexColour('#5A9AEA'), hexColour('#A8CCF8')],
    m: 'puntos',
  ),
  'q': (
    r: 5,
    c: [hexColour('#D8A414'), hexColour('#F4CC30'), hexColour('#FFE878')],
    m: 'linea',
  ),
};

// campo.js: mkBola
Sprite mkBola(String k) {
  final d = BOLA[k]!, r = d.r, n = (r * 2 + 3).ceil(), b = Buf(n, n), c = n / 2;
  b.ell(c, c, r, r, d.c);
  if (d.m == 'rayas') {
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final dx = x + .5 - c, dy = y + .5 - c;
        if (dx * dx + dy * dy < r * r - 1 && ((x + y) % 6) < 2) {
          b.px(x, y, _stripe);
        }
      }
    }
  } else if (d.m == 'puntos') {
    for (final p in [
      [c - 2.5, c - 2],
      [c + 2, c - 1],
      [c - 1, c + 2.5],
      [c + 2.5, c + 3],
    ]) {
      b.rect(_round(p[0]), _round(p[1]), 2, 2, _white);
    }
  } else {
    // a white line, like a tennis ball
    for (final dd in const [
      [-4, 1],
      [-3, 0],
      [-2, -1],
      [-1, -1],
      [0, -1],
      [1, 0],
      [2, 1],
      [3, 1],
    ]) {
      b.px(_round(c) + dd[0], _round(c) + dd[1], _white);
    }
    b.px(_round(c) - 2, _round(c) - 3, _white);
  }
  return b.outline().done();
}

// campo.js: radio
double radio(String k) => BOLA[k]!.r;

/// The pixels of each of the sheet's `front` parts (set-kit.js `PART_TAGS`: the part of the set that drew a pixel
/// last), by set key, then by part. A state's are the same on every engine.
final Map<String, Map<String, Int32List>> _frontPixels = {};

class Campo extends Escena implements SetScene, SetOverSprites, PairPlaces {
  Campo(this.sheet) {
    _p = CampoPlaces(sheet, campoEngine());
    final p = _p;
    // campo.js:15 ARBOL, COPA, HORQ, SITIO (sheet: points arbol, copa, horq, sitio). The crown's numbers are its old
    // ones (points.copa.old): campo.js uses COPA only for the shaking leaves round the old middle (line 97) and the
    // height of a ball hidden in it (line 264), both "unchanged" (code lines 97 and 264); its box and hand are the
    // sheet's (things.arbol, line 66)
    ARBOL = [for (final v in p.pt('arbol')) _round(v)];
    COPA = [
      for (final v in (sheet.screenPoint('copa').old as List).cast<num>()) v,
    ];
    HORQ = [for (final v in p.pt('horq')) _round(v)];
    SITIO = [for (final v in p.pt('sitio')) _round(v)];
    // campo.js:48 LUGAR (sheet: lugar, the frog's spots frog.centro, frog.inicio)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // campo.js:49 CASA, PIES, CESTA, PILA (sheet: spots luis.casa, carmen.casa, bola.pies, cesta, pila.0 to pila.3)
    CASA = {'luis': p.spot('luis.casa'), 'carmen': p.spot('carmen.casa')};
    PIES = p.spot('bola.pies');
    CESTA = p.spot('cesta');
    PILA = [for (var i = 0; i < 4; i++) p.spot('pila.$i')];
    // campo.js:50 FILA, ORILLA (sheet: spots fila.0 to fila.2, orilla); JUNCO (moves line 50: [180,197] -> [185,205],
    // out into the water among the reeds)
    FILA = [for (var i = 0; i < 3; i++) p.spot('fila.$i')];
    ORILLA = p.spot('orilla');
    JUNCO = p.floor(50, 180, 197);
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _talk = sheet.talk!;
    _ring = sheet.helps!.ring;
    _sortJuncos = sheet.frontParts['juncos']!.sortY!;
    _waterDepth = sheet.frontWaterDepth!;
    // campo.js:63 to :68 COSAS (sheet: code lines 66 to 68, things.<id>.box, hand and hintBox; lines 52, 61, 64: the
    // children's, the balls', Canelo's and the basket's boxes relative to them, unchanged)
    cosas = [
      for (final id in const ['luis', 'carmen']) persona(id),
      for (final n in const ['luis', 'carmen', 'cq']) bolaCosa(n),
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
        id: 'cesta',
        si: (w) => jsTruthy(w['cesta']),
        box: (Map<String, dynamic> w) {
          final c = w['cesta'] as List;
          return [(c[0] as num) - 11, (c[1] as num) - 16, 22, 18];
        },
        m: 1,
      ),
      Thing(
        id: 'arbol',
        box: p.box('arbol'),
        hand: p.hand('arbol'),
        hintBox: p.hintBox('arbol'),
        m: 0,
      ),
      Thing(
        id: 'juncos',
        box: p.box('juncos'),
        hand: p.hand('juncos'),
        hintBox: p.hintBox('juncos'),
        m: 0,
      ),
      Thing(id: 'campo', box: p.box('campo'), m: 0),
    ];
  }

  @override
  final Sheet sheet;

  late final CampoPlaces _p;

  @override
  String get id => 'campo';

  @override
  PpEngine newEngine({bool still = false}) => campoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
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

  /* ---------- the set ---------- */

  // the sheet's setKey table: one baked state ("campo") for every W
  @override
  String setKey(Map<String, dynamic> W) => const CampoState().key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = CampoSet(e, b, CampoState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the reeds' own pixels)
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

  // the ground point under a screen point, and whether it is over the lake (campo-preview.html: `CAMPO_SET.shore`)
  bool _overWater(num sx, num sy) {
    final g = _p.e.unproject(sx, sy);
    return campoShore(_p.e, g.x, g.y) < 0;
  }

  // the sheet's shadows, as campo-preview.html casts them (PV.casts): the frog (W.cq.vis, not .5 or less faded) at .3
  // with his radius, from the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25)); each child
  // shown and not .5 or less faded at .3, .65, 1, 1.35, 1.7, from the ground point under (round(x), round(y) - 1);
  // Canelo, shown, at .25, in the air too (his shadow on the ground under him); the basket at .2; each ball shown and not
  // carried, not floating, not in the tree's crown, not lying on the water, from the ball's middle as it lies there (z
  // its radius), on the ground under it in the air too
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final e = _p.e, sh = sheet.shadows;
    ({double x, double y}) on(num sx, num sy) => e.unproject(sx, sy);
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q), g = on(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: sh['coqui']!.radius));
    }
    final r = sh['people']!.radii!['nino']!;
    final G = W['gente'] as Map<String, dynamic>? ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0 || _atMostHalf(p['al'])) continue;
      final g = on(_round(p['x'] as num), _round(p['y'] as num) - 1);
      for (final z in const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0) {
      final g = on(_round(pe['x'] as num), _round(pe['y'] as num) - 1);
      out.add((x: g.x, y: g.y, z: .25, r: sh['perro']!.radius));
    }
    final ce = W['cesta'];
    if (jsTruthy(ce)) {
      final c = ce as List, g = on(c[0] as num, (c[1] as num) - 1);
      out.add((x: g.x, y: g.y, z: .2, r: sh['cesta']!.radius));
    }
    final bolas = W['bolas'] as Map<String, dynamic>? ?? const {};
    for (final o in bolas.values) {
      final s = ballShadow(o as Map<String, dynamic>?);
      if (s == null) continue;
      final g = on(s[0], s[1] - 1), R = sh['bola']!.radii![(o as Map)['k']]!;
      out.add((x: g.x, y: g.y, z: R, r: R));
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  // campo-preview.html: PV.ballShadow (sheet shadows.bola.when). A ball's shadow point on the screen, or null
  List<int>? ballShadow(Map<String, dynamic>? o) {
    if (o == null ||
        o['vis'] == 0 ||
        jsTruthy(o['con']) ||
        jsTruthy(o['flota'])) {
      return null;
    }
    final p = [
      _round(o['x'] as num),
      _round(o['y'] as num),
      _round(_n(o['z'])),
    ];
    final T = sheet.shadows['bola']!.tree!;
    // in the tree's crown
    if (p[2] >= T.z && (p[0] - T.x).abs() <= T.dx && p[1] <= T.y) return null;
    // lying on the water: its ring instead
    if (p[2] <= 1 && _overWater(p[0] + .5, p[1] - .5)) return null;
    return p;
  }

  /* ---------- the reeds in front: the sheet's front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // the set as this frame shows it (wind, glints, shadows), before the sprite layer (drawFrame's step 4), and its depth
  // (campo-preview.html: `DEPTH.live()`)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
    _frontNow = _frontPixels[setKey(W)];
  }

  // campo-preview.html: vOf. The v = (x + y) / R2 of the ground under a screen point; over the lake, of the water's
  // surface (sheet front.plane, front.waterDepth)
  double vOf(PpEngine e, num sx, num sy) {
    final v0 = (sy - e.OY) / (e.S * .5);
    return _overWater(sx, sy) ? v0 - _waterDepth * math.sqrt(3) : v0;
  }

  // campo-preview.html: PREVIEW.front (sheet: front). The set's own pixels of a part (the reeds), again, inside each item
  // drawn before its entry in the sorted list ([lista], sorted), only where that pixel is nearer to the camera than the
  // item: z[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the ground under it (sheet front.boxes). A frame drawn with
  // no set (a player with no screen) has none to draw again.
  void front(String part, List<CampoItem> lista) {
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'campo: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
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

  // campo-preview.html: PREVIEW.frontBox. A list item's box and the v of the ground under it (sheet front.boxes): a child
  // [x - 24, y - 46 - dy, 48, 49 + dy]; the frog frogBox with dy; Canelo [x - 16, y - 24 - dy, 32, 27 + dy]; a ball
  // [x - ceil(r) - 3, y - z - 2 ceil(r) - 4, 2 ceil(r) + 6, 2 ceil(r) + 6], its ground under (x, sort y - .5 - 1); the
  // basket [x - 12, y - 20, 24, 21]
  ({List<num> box, double v})? frontBox(
    CampoItem o,
    Map<String, dynamic> w,
    PpEngine e,
  ) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      return (
        box: [b.x, b.y + _round(_n(q['dy'])), b.w, b.h],
        v: vOf(e, b.x + b.w / 2, (q['y'] as num) + 25),
      );
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>;
      final dy = _round(_n(p['dy']));
      return (
        box: [
          _round(p['x'] as num) - 24,
          _round(p['y'] as num) - 46 - dy,
          48,
          49 + dy,
        ],
        v: vOf(e, _round(p['x'] as num), _round(p['y'] as num) - 1),
      );
    }
    if (o.k == 'perro') {
      final p = w['perro'] as Map<String, dynamic>, dy = _round(_n(p['dy']));
      return (
        box: [
          _round(p['x'] as num) - 16,
          _round(p['y'] as num) - 24 - dy,
          32,
          27 + dy,
        ],
        v: vOf(e, _round(p['x'] as num), _round(p['y'] as num) - 1),
      );
    }
    if (o.b != null) {
      final B =
          (w['bolas'] as Map<String, dynamic>)[o.b] as Map<String, dynamic>?;
      if (B == null) return null;
      final p = bolaXY(B), r = radio(B['k'] as String).ceil();
      return (
        box: [p[0] - r - 3, p[1] - p[2] - 2 * r - 4, 2 * r + 6, 2 * r + 6],
        v: vOf(e, p[0], o.y - .5 - 1),
      );
    }
    if (o.cesta) {
      final p = w['cesta'] as List;
      return (
        box: [(p[0] as num) - 12, (p[1] as num) - 20, 24, 21],
        v: vOf(e, p[0] as num, (p[1] as num) - 1),
      );
    }
    return null;
  }

  /* ---------- the helps: a ripple ring on the water (sheet: helps) ---------- */

  late final SheetRing _ring;
  late final double _waterDepth;
  late final num _sortJuncos;

  // campo-preview.html: ell. Every pixel (x, y) with inner < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1 takes
  // the colour
  void ell(Ctx c, num cx, num cy, num rx, num ry, num inner, int col) {
    c.fillStyle = col;
    for (var y = (cy - ry - 1).floor(); y <= (cy + ry + 1).ceil(); y++) {
      for (var x = (cx - rx - 1).floor(); x <= (cx + rx + 1).ceil(); x++) {
        final dx = (x + .5 - cx) / rx, dy = (y + .5 - cy) / ry;
        final d = dx * dx + dy * dy;
        if (d > inner && d <= 1) c.fillRect(x, y, 1, 1);
      }
    }
  }

  // campo-preview.html: PREVIEW.under (sheet helps.lines[0], unaBola). A ball not carried that floats, or lies on the
  // water: its ring, at its middle (a floating ball: + its bob), radio + 4 wide, 2.5 high
  void under(Ctx c, Map<String, dynamic>? o, List<num> p, num r) {
    if (o == null || jsTruthy(o['con'])) return;
    final wet =
        jsTruthy(o['flota']) || (p[2] <= 1 && _overWater(p[0] + .5, p[1] - .5));
    if (wet) {
      ell(
        c,
        p[0],
        p[1] + (jsTruthy(o['flota']) ? (F >> 3) % 2 : 0),
        r + _ring.ball.rx,
        _ring.ball.ry,
        _ring.inner,
        _ring.colour,
      );
    }
  }

  // campo-preview.html: PREVIEW.wade (sheet helps.lines[1], perro). Canelo, not in the air, his feet over the water: his
  // ring under them
  void wade(Ctx c, Map<String, dynamic> o) {
    if (_n(o['dy']) > 3) return;
    final x = _round(o['x'] as num), y = _round(o['y'] as num);
    if (_overWater(x + .5, y - .5)) {
      ell(
        c,
        x,
        y + _ring.dog.dy,
        _ring.dog.rx,
        _ring.dog.ry,
        _ring.inner,
        _ring.colour,
      );
    }
  }

  /* ---------- where things are ---------- */

  // campo.js: ARBOL, COPA, HORQ, SITIO
  late final List<int> ARBOL, HORQ, SITIO;
  late final List<num> COPA;

  // campo.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // campo.js: CASA, PIES, CESTA, PILA, FILA, ORILLA, JUNCO
  late final Map<String, List<int>> CASA;
  late final List<int> PIES, CESTA, ORILLA, JUNCO;
  late final List<List<int>> PILA, FILA;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  // campo.js: G, B
  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;
  Map<String, dynamic>? B(String n) =>
      (W['bolas'] as Map<String, dynamic>?)?[n] as Map<String, dynamic>?;
  Map<String, dynamic> get _bolas => W['bolas'] as Map<String, dynamic>;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic> get _pe => W['perro'] as Map<String, dynamic>;

  // campo.js: QUIEN
  static final Map<String, Who> QUIEN = {
    'luis': FAM['hermano']!,
    'carmen': FAM['hermana']!,
  };

  // campo.js: alto
  int alto(String id) => QUIEN[id]!.nino ? 44 : 56;

  // campo.js: caja
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

  // campo.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // campo.js: manos. Where a ball is: in somebody's hands, in the dog's mouth (sheet moves line 59: a ball a child holds
  // up over the head, pose arriba, in the raised hand: 8 px to the side the child faces, h - 3 over the feet)
  List<num> manos(String k) {
    if (k == 'cq') {
      final b = frogBox(_cq);
      return [
        b.x + (b.w.toInt() >> 1),
        (_cq['y'] as num) + 28,
        3 - _round(_cq['dy'] as num),
      ];
    }
    if (k == 'perro') {
      final p = _pe;
      return [
        _round(p['x'] as num) + (_dir(p) < 0 ? -13 : 13),
        _round(p['y'] as num) + 1,
        5 + _n(p['dy']),
      ];
    }
    final p = G(k)!, h = alto(k), d = _dir(p) < 0 ? -1 : 1;
    final pose = p['pose'];
    return [
      _round(p['x'] as num) +
          d *
              (pose == 'offer'
                  ? 11
                  : pose == 'arriba'
                  ? 8
                  : 6),
      _round(p['y'] as num) + 1,
      (pose == 'arriba'
              ? h - 3
              : pose == 'offer'
              ? h - 27
              : h - 24) +
          _n(p['dy']),
    ];
  }

  // campo.js: bolaXY
  List<num> bolaXY(Map<String, dynamic> o) {
    if (jsTruthy(o['con'])) return manos(o['con'] as String);
    return [_round(o['x'] as num), _round(o['y'] as num), _round(_n(o['z']))];
  }

  // campo.js: cajaBola
  List<num>? Function(Map<String, dynamic> w) cajaBola(String n) => (w) {
    final o =
        (w['bolas'] as Map<String, dynamic>? ?? const {})[n]
            as Map<String, dynamic>?;
    if (o == null || o['vis'] == 0) return null;
    final p = bolaXY(o), r = radio(o['k'] as String);
    return [p[0] - r - 2, p[1] - p[2] - 2 * r - 2, 2 * r + 4, 2 * r + 4];
  };

  // campo.js: bolaCosa
  Thing bolaCosa(String n) => Thing(
    id: 'bola_$n',
    z: true,
    m: 3,
    si: (w) {
      final b = w['bolas'] as Map<String, dynamic>?;
      return b != null && b[n] != null && (b[n] as Map)['vis'] != 0;
    },
    box: cajaBola(n),
  );

  // campo.js: COSAS
  @override
  late final List<Thing> cosas;

  // campo.js: fresh
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'gente': <String, dynamic>{},
    'perro': null,
    'bolas': <String, dynamic>{},
    'cesta': null,
    'cestaN': null,
    'tarjeta': null,
    'marcas': null,
    'pila': 0,
    'flotan': 0,
    'mojado': 0,
    'oscuro': 0,
    'cierra': 0,
    'tiembla': null,
    'salpica': null,
    'mariposa': null,
    'tieneBola': null,
    'donde': null,
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

  // campo.js: gotas
  void gotas(Ctx c, num x, num y, num w, num h, num n) {
    for (var i = 0; i < n; i++) {
      final dx = hs(i * 7, 3) % w, t = (F + i * 5) % 12;
      fr(
        c,
        x + dx,
        y + ((hs(i * 3, 9) % h) + t) % h,
        1,
        2,
        i % 2 != 0 ? _drop0 : _drop1,
      );
    }
  }

  // campo.js: gente
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
        : p['pose'] == 'atras'
        ? 'idle'
        : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
    final im = host.lib.spr(
      'pc$id$pose$habla',
      () => mkPersona(QUIEN[id]!, pose, habla != 0, false),
    );
    final dy = _n(p['dy']);
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
              dy)
          .toDouble(),
    );
    if (jsTruthy(p['corre'])) {
      c.translate(0, im.h.toDouble());
      c.rotate(.26 * d);
      c.translate(0, -im.h.toDouble());
    }
    // the kit draws the offering arm on the other side: turn it to the side he faces
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    // an arm across his eyes
    if (jsTruthy(p['ojos'])) {
      fr(c, x - 7, y - h + 9 - dy, 14, 4, QUIEN[id]!.piel[2]);
      fr(c, x - 7, y - h + 8 - dy, 14, 1, OUT);
      fr(c, x - 7, y - h + 13 - dy, 14, 1, OUT);
    }
    if (jsTruthy(p['mojado'])) gotas(c, x - 9, y - h + 4, 18, h - 6, 6);
  }

  // campo.js: perro
  void perro(Ctx c, int a) {
    final o = W['perro'] as Map<String, dynamic>?;
    if (o == null || o['vis'] == 0) return;
    // sheet helps.lines[1]: his ripple ring first, when he wades
    wade(c, o);
    final pose = o['pose'] as String;
    final anda =
        pose == 'walk' ||
        pose == 'run' ||
        pose == 'bark' ||
        pose == 'eat' ||
        pose == 'husmea';
    final f = anda ? (a >> (pose == 'run' ? 0 : 1)) % 2 : 0;
    final im = host.lib.spr('pe$pose$f', () => mkPerro(pose, f != 0)),
        d = _dir(o) < 0 ? -1 : 1,
        sx = jsTruthy(o['sacude']) ? ((F % 2) != 0 ? 1 : -1) : 0;
    // campo.js:78, his dark bar in the air, is dropped (sheet: dropped): the engine casts his shadow
    final x = _round(o['x'] as num), y = _round(o['y'] as num);
    c.save();
    c.translate((x + sx).toDouble(), (y - im.h + 2 - _n(o['dy'])).toDouble());
    if (d < 0) c.scale(-1, 1);
    c.drawImage(im, -13, 0);
    c.restore();
    // dust behind him: he runs
    if (jsTruthy(o['polvo'])) {
      for (var i = 0; i < 3; i++) {
        fr(c, x - d * (16 + i * 6) - 2, y - 3 - i % 2 * 3, 4, 3, _white);
        fr(c, x - d * (16 + i * 6) - 1, y - 2 - i % 2 * 3, 3, 2, _dust);
      }
    }
    // he drips
    if (jsTruthy(o['mojado'])) gotas(c, x - 11, y - 12, 22, 12, 4);
    // he shakes himself: water everywhere
    if (jsTruthy(o['sacude'])) {
      for (var i = 0; i < 14; i++) {
        final t = ((F * 3 + i * 11) % 18), an = i * .45;
        fr(
          c,
          x + _round(math.cos(an) * (6 + t * 1.6)),
          y - 10 + _round(math.sin(an) * (4 + t * 1.1)),
          2,
          2,
          i % 2 != 0 ? _drop0 : _drop1,
        );
      }
    }
    // his bubble, where the sheet's talk puts it (code line 83)
    if (jsTruthy(o['bub'])) {
      final t = talkPlace([x, y - 22], 8, o['bub'], W);
      bub2(c, o['bub'] as String, t[0], t[1], a);
    }
  }

  // campo.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (jsTruthy(W['cierra']) || (F % 47) < 2) ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0,
        dy = _round(q['dy'] as num);
    // campo.js:85, the dotted shadow, is dropped (sheet: dropped): the engine casts his
    final mojado = _n(W['mojado']);
    if (mojado > 0) {
      // the wetter he is, the wider the puddle he stands in
      final m = mojado.toInt();
      final rx = [0, b.w / 2 - 3, b.w / 2 + 6, b.w / 2 + 18][m],
          ry = const [0, 2.5, 4, 6][m];
      g.fillStyle = _blue;
      g.beginPath();
      g.ellipse(b.x + b.w / 2, (q['y'] as num) + 28, rx + 1, ry + 1, 0, 0, 7);
      g.fill();
      g.fillStyle = _drop0;
      g.beginPath();
      g.ellipse(b.x + b.w / 2, (q['y'] as num) + 28, rx, ry, 0, 0, 7);
      g.fill();
      g.fillStyle = _drop1;
      g.fillRect(b.x + 4, (q['y'] as num) + 27, 6, 1);
    }
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      host.lib.spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    if (jsTruthy(W['mojado'])) {
      gotas(g, b.x + 2, b.y + dy + 2, b.w - 4, b.h, mojado * 5);
    }
  }

  // campo.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // campo.js: unaBola
  void unaBola(Ctx c, Map<String, dynamic> o) {
    final p = bolaXY(o), r = radio(o['k'] as String);
    final im = host.lib.spr('bola${o['k']}', () => mkBola(o['k'] as String));
    // sheet helps.lines[0]: its ripple ring first, when it floats or lies on the water
    under(c, o, p, r);
    if (jsTruthy(o['flota'])) {
      // in the pond: half under
      final y = p[1] + ((F >> 3) % 2), cut = _round(r * .7);
      c.drawImageRect(
        im,
        0,
        0,
        im.w,
        im.h - cut,
        p[0] - (im.w >> 1),
        y - im.h + cut,
        im.w,
        im.h - cut,
      );
      fr(c, p[0] - _round(r) - 2, y, 2 * _round(r) + 4, 1, _drop1);
      return;
    }
    // campo.js:92, its dark bar in the air, is dropped (sheet: dropped): the engine casts its shadow
    c.drawImage(im, p[0] - (im.w >> 1), p[1] - p[2] - im.h + 1);
    // lines behind a ball in flight
    final v = o['vuela'];
    if (jsTruthy(v)) {
      final vv = (v as List).cast<num>(), ver = vv[1].abs() > vv[0].abs();
      for (var i = 1; i <= 3; i++) {
        final tx = p[0] - vv[0] * (r + 2 + i * 4),
            ty = p[1] - p[2] - _round(r) - vv[1] * (r + 2 + i * 4);
        if (ver) {
          fr(c, tx - 1, ty - 2, 3, 5, _blue);
          fr(c, tx, ty - 1, 1, 3, _white);
        } else {
          fr(c, tx - 2, ty - 1, 5, 3, _blue);
          fr(c, tx - 1, ty, 3, 1, _white);
        }
      }
    }
  }

  // campo.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        Bs = (W['bolas'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // campo.js:96 c.drawImage(spr("campo",fondo),0,0) -> the set, for setKey(W) (sheet: dropped)
    final ti = W['tiembla'] as Map<String, dynamic>?;
    if (ti != null) {
      final t = F - (ti['f'] as num);
      if (t < 14) {
        final arbol = ti['en'] == 'arbol';
        const da = [
              [-26, -10],
              [24, -14],
              [-18, 14],
              [22, 10],
              [0, -28],
            ],
            dj = [
              [-14, -8],
              [10, -14],
              [20, -4],
              [-4, -18],
            ];
        final ds = arbol ? da : dj;
        // code line 97: relative to the old crown's middle (COPA) and to the reeds' 190, 186: unchanged
        final List<num> o = arbol ? [COPA[0], COPA[1]] : const [190, 186];
        for (var k = 0; k < ds.length; k++) {
          final d = ds[k];
          fr(c, o[0] + d[0] + ((F + k) % 2) * 2, o[1] + d[1], 3, 2, RP.grn[4]);
        }
      }
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
            i % 2 != 0 ? _drop1 : _white,
          );
        }
      }
    }
    // everyone, from the back to the front; each item says who or what it is (sheet front.tags, for the front masks)
    final L = <CampoItem>[];
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(CampoItem(p['y'] as num, () => gente(c, id, a), id: id));
      }
    }
    final pe = W['perro'] as Map<String, dynamic>?;
    if (pe != null && pe['vis'] != 0) {
      L.add(CampoItem(pe['y'] as num, () => perro(c, a), k: 'perro'));
    }
    if (jsTruthy(q['vis'])) {
      L.add(CampoItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    final ce = W['cesta'] as List?;
    if (ce != null) {
      L.add(
        CampoItem(ce[1] as num, () {
          final x = ce[0] as num, y = ce[1] as num;
          final im = host.lib.spr('bolaq', () => mkBola('q'));
          final n = W['cestaN'] == null ? 4 : W['cestaN'] as num;
          for (var i = 0; i < n; i++) {
            c.drawImage(im, x - 10 + i * 5, y - 16 - (i % 2) * 2);
          }
          c.drawImage(host.lib.spr('cesta', mkCesta), x - 10, y - 11);
        }, cesta: true),
      );
    }
    // a ball in somebody's hands is drawn in front of them
    for (final k in Bs.keys) {
      final o = Bs[k] as Map<String, dynamic>?;
      if (o == null || o['vis'] == 0) continue;
      final p = bolaXY(o), con = o['con'];
      final num y = con == 'cq'
          ? (q['y'] as num) + 27.5
          : con == 'perro' && W['perro'] != null
          ? (pe!['y'] as num) + .5
          : jsTruthy(con) && Gt[con] != null
          ? ((Gt[con] as Map)['y'] as num) + .5
          : p[1] + .5;
      L.add(CampoItem(y, () => unaBola(c, o), b: k));
    }
    // a flower (a picture pair)
    final flor = W['flor'] as List?;
    if (flor != null) {
      final x = flor[0] as num, y = flor[1] as num;
      L.add(
        CampoItem(y, () {
          fr(c, x, y - 9, 1, 9, _stem);
          fr(c, x - 3, y - 4, 3, 2, _stem);
          for (final d in const [
            [-3, -13],
            [1, -13],
            [-3, -9],
            [1, -9],
            [-1, -15],
            [-1, -8],
            [-4, -11],
            [2, -11],
          ]) {
            fr(c, x + d[0], y + d[1], 3, 3, _petal);
          }
          fr(c, x - 1, y - 12, 3, 3, _heart);
        }),
      );
    }
    final m = W['mariposa'] as Map<String, dynamic>?;
    if (m != null) {
      L.add(
        CampoItem(999, () {
          final f = (F >> 1) % 2,
              mx = _round(m['x'] as num),
              my = _round(m['y'] as num);
          fr(c, mx - 3 - f, my - 2, 3, 4, _wing);
          fr(c, mx + 1 + f, my - 2, 3, 4, _wing);
          fr(c, mx, my - 2, 1, 5, OUT);
        }),
      );
    }
    // campo.js:107 the sorted list: the reeds' entry (sheet: front.parts.juncos, sortY 9999, after everyone)
    late final List<CampoItem> sorted;
    L.add(
      CampoItem(_sortJuncos, () => front('juncos', sorted), front: 'juncos'),
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
    // campo.js:108 a child's bubble, where the sheet's talk puts it
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
    // campo.js:109 the frog's bubble, where the sheet's talk puts it
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
    // campo.js:110 his eyes are shut: all is dark but him ("rgba(8,12,24," + W.oscuro + ")": 8-bit alpha, rounded)
    if (jsTruthy(W['oscuro'])) {
      final al = ((W['oscuro'] as num) * 255).round().clamp(0, 255);
      c.fillStyle = (al << 24) | (24 << 16) | (12 << 8) | 8;
      c.fillRect(0, 0, SW, SH);
      if (jsTruthy(q['vis']) && (W['oscuro'] as num) > .4) rana(c, q, a);
    }
    // the set as framed is this frame's only (drawFrame gives it again before the next)
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
  }

  // campo-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
  // head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view, clear
  // of the corner card shown (W.tarjeta: talk.board, + the view's x0) and of every face (each visible child's and the
  // frog's, its own too); if none is, [top].
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
      final hd = T.heads[id]!;
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

  // campo.js: talkAt (relative to the child: unchanged)
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

  /* ---------- the pictures in his answer bubbles ---------- */

  // campo.js: flecha
  void flecha(Ctx g, num x, num y, bool up) {
    final C = _arrow;
    fr(g, x + 2, y + (up ? 3 : 0), 3, 7, C);
    for (final r in const [
      [0, 3, 7, 1],
      [1, 2, 5, 1],
      [2, 1, 3, 1],
      [3, 0, 1, 1],
    ]) {
      fr(g, x + r[0], up ? y + r[1] : y + 9 - r[1], r[2], r[3], C);
    }
  }

  // campo.js: respIcon
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    final im = host.lib.spr('cq.6_0', () => mkCoqui(.6, 0, false)),
        bq = host.lib.spr('bolaq', () => mkBola('q')),
        t = (F >> 1) % 8;
    void suelo() => fr(g, x + 4, y + 32, 32, 1, _ground);
    suelo();
    final piel = _skin;
    void flechita(num fx, num fy, num dx, num dy) {
      for (final d in const [
        [0, 0],
        [-1, -1],
        [-1, 1],
        [-2, -2],
        [-2, 2],
      ]) {
        fr(
          g,
          fx + (dx != 0 ? d[0] * dx : d[1]),
          fy + (dx != 0 ? d[1] : d[0] * dy),
          2,
          2,
          _blue,
        );
      }
    }

    if (k == 'tira') {
      // one arm forward; the ball flies away from him
      g.drawImage(im, x + 2, y + 14);
      fr(g, x + 16, y + 24, 8, 4, OUT);
      fr(g, x + 17, y + 25, 6, 2, piel);
      final bx = x + 22 + t,
          by = y + 13 - _round(math.sin(t / 7 * math.pi) * 4);
      for (var i = 1; i <= 2; i++) {
        fr(g, bx - 1 - i * 4, by + 5, 3, 1, _blue);
      }
      g.drawImage(bq, bx, by);
      flechita(x + 37, y + 10, 1, 0);
    } else if (k == 'coge') {
      // both hands up; the ball drops into them
      g.drawImage(im, x + 11, y + 16);
      for (final p in const [
        [9, 10],
        [27, 10],
      ]) {
        fr(g, x + p[0], y + p[1], 3, 9, OUT);
        fr(g, x + p[0] + 1, y + p[1] + 1, 1, 7, piel);
      }
      final by = y + math.min(t, 4);
      g.drawImage(bq, x + 14, by);
      flechita(x + 34, y + 12, 0, 1);
    } else if (k == 'arriba') {
      // stretched tall: up
      g.save();
      g.translate((x + 9).toDouble(), (y + 33).toDouble());
      g.scale(1, 1.3);
      g.drawImage(im, 0, -im.h);
      g.restore();
      flecha(g, x + 30, y + 6, true);
    } else if (k == 'abajo') {
      // crouched flat: down
      g.save();
      g.translate((x + 6).toDouble(), (y + 33).toDouble());
      g.scale(1.15, .65);
      g.drawImage(im, 0, -im.h);
      g.restore();
      flecha(g, x + 31, y + 12, false);
    } else if (k == 'salta') {
      // in the air, his shadow below, lines down to the ground
      final up = const [5, 8, 11, 13, 14, 13, 11, 8][t];
      fr(g, x + 14, y + 31, 13, 2, _jumpShadow);
      g.drawImage(im, x + 11, y + 13 - up);
      for (final d in const [
        [13, 0],
        [25, 0],
      ]) {
        fr(g, x + d[0], y + 31 - up + 2, 1, up - 3, _blue);
      }
    } else if (k == 'corre') {
      final up = (F % 2) != 0 ? 2 : 0;
      g.save();
      g.translate((x + 24).toDouble(), (y + 21 - up).toDouble());
      g.rotate(.3);
      g.drawImage(im, -10, -9);
      g.restore();
      for (var i = 0; i < 3; i++) {
        fr(g, x + 3 + ((F * 2 + i * 5) % 6), y + 12 + i * 6, 9, 2, _blue);
      }
    } else if (k == 'da') {
      // the ball goes from him into a hand that reaches in from the edge
      g.drawImage(im, x + 1, y + 14);
      final hx = x + 26, hy = y + 25;
      fr(g, hx + 5, hy - 2, 9, 7, OUT);
      fr(g, hx + 6, hy - 1, 7, 5, _sleeve);
      fr(g, hx - 1, hy - 1, 8, 5, OUT);
      fr(g, hx, hy, 7, 3, _hand);
      g.drawImage(bq, hx - 3, hy - 11);
      for (final d in const [
        [0, 0],
        [2, 0],
        [4, 0],
        [3, -1],
        [3, 1],
      ]) {
        fr(g, x + 19 + d[0] + ((F >> 2) % 2), y + 12 + d[1], 2, 1, _arrow);
      }
    } else if (k == 'aguanta') {
      // holding the ball, the raised hand of "wait"
      g.drawImage(im, x + 5, y + 13);
      g.drawImage(bq, x + 10, y + 23);
      mano(g, x + 27, y + 6);
    }
    return null;
  }

  /* ---------- the card in the corner: three rounds; a star, or the mark of what went wrong ---------- */

  // campo.js: hud
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
        g.fillStyle = _heart;
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii, y + j + 2, 1, 1);
          }
        }
      } else if (m == 'pata') {
        g.fillStyle = _paw;
        g.fillRect(x + 3, y + 7, 8, 7);
        for (final d in const [
          [1, 3],
          [5, 1],
          [9, 1],
          [13, 3],
        ]) {
          g.fillRect(x + d[0] - 1, y + d[1] + 1, 3, 4);
        }
      } else if (m == 'agua' || m == 'gota') {
        g.fillStyle = _blue;
        for (final r in const [
          [6, 0, 2, 3],
          [5, 3, 4, 3],
          [4, 6, 6, 3],
          [3, 9, 8, 4],
          [4, 13, 6, 1],
        ]) {
          g.fillRect(x + r[0], y + r[1], r[2], r[3]);
        }
        g.fillStyle = _drop1;
        g.fillRect(x + 5, y + 9, 2, 3);
        if (m == 'agua') {
          g.fillStyle = _blue;
          g.fillRect(x, y + 14, 14, 1);
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

  // campo.js: mueve
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

  // campo.js: perroA
  Future<void> perroA(num x, num y, [String? pose0, num? n0]) async {
    final o = W['perro'] as Map<String, dynamic>?;
    if (o == null) return;
    final x0 = o['x'] as num, y0 = o['y'] as num;
    final pose = pose0 == null || pose0.isEmpty ? 'run' : pose0;
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

  Future<void> _perroA(List<num> p, [String? pose, num? n]) =>
      perroA(p[0], p[1], pose, n);

  // campo.js: brinco. A person or the dog jumps (dy is up)
  Future<void> brinco(Map<String, dynamic> o, num h, [num? n0]) async {
    final n = n0 == null || n0 == 0 ? 8 : n0;
    for (var i = 1; i <= n; i++) {
      o['dy'] = h * math.sin(math.pi * i / n);
      await wait(TICK);
    }
    o['dy'] = 0;
  }

  // campo.js: ranaSalta
  Future<void> ranaSalta(num h, [num? n0]) async {
    final q = _cq;
    final n = n0 == null || n0 == 0 ? 10 : n0;
    SFX.hop();
    for (var i = 1; i <= n; i++) {
      q['dy'] = -h * math.sin(math.pi * i / n);
      await wait(TICK);
    }
    q['dy'] = 0;
  }

  // campo.js: suelta
  void suelta(String n) {
    final o = B(n);
    if (o == null) return;
    final p = bolaXY(o);
    o['con'] = null;
    o['x'] = p[0];
    o['y'] = p[1];
    o['z'] = p[2];
  }

  // campo.js: vuela. A ball flies (or, with alto 0, rolls) to a place on the ground, or into somebody's hands
  Future<void> vuela(
    String n,
    Object a, [
    num? alto,
    num? pasos0,
    num? rastro,
  ]) async {
    final o = B(n);
    if (o == null) return;
    suelta(n);
    final x0 = o['x'] as num, y0 = o['y'] as num, z0 = o['z'] as num;
    List<num> to() {
      if (a is String) return manos(a);
      final l = a as List;
      return [l[0] as num, l[1] as num, l.length > 2 ? _n(l[2]) : 0];
    }

    final fin = to();
    final pasos = pasos0 != null && pasos0 != 0
        ? pasos0
        : math.max(
            5,
            _round(
              math.sqrt(
                    (fin[0] - x0) * (fin[0] - x0) +
                        (fin[1] - y0) * (fin[1] - y0),
                  ) /
                  9,
            ),
          );
    final dx = fin[0] - x0;
    final h0 = math.sqrt(dx * dx + (fin[1] - y0) * (fin[1] - y0));
    final dn = h0 == 0 ? 1 : h0;
    if (rastro != 0) o['vuela'] = <num>[dx / dn, 0];
    for (var i = 1; i <= pasos; i++) {
      final t = i / pasos, f = a is String ? manos(a) : fin;
      o['x'] = x0 + (f[0] - x0) * t;
      o['y'] = y0 + (f[1] - y0) * t;
      o['z'] = z0 + (f[2] - z0) * t + _n(alto) * 4 * t * (1 - t);
      await wait(TICK);
    }
    o['vuela'] = null;
    if (a is String) {
      o['con'] = a;
      SFX.blip();
    } else {
      o['x'] = fin[0];
      o['y'] = fin[1];
      o['z'] = fin[2];
    }
  }

  // campo.js: ladra
  Future<void> ladra([num? n]) async {
    final o = _pe, p0 = o['pose'];
    o['pose'] = 'bark';
    final k0 = n == null || n == 0 || n.isNaN ? 2 : n;
    for (var k = 0; k < k0; k++) {
      tone(520, 0, .07, 'square', .05, 300);
      tone(400, .07, .1, 'square', .05, 240);
      await wait(260);
    }
    o['pose'] = p0;
  }

  // campo.js: sacude
  Future<void> sacude([num? ms]) async {
    final o = _pe;
    o['sacude'] = 1;
    for (var k = 0; k < 6; k++) {
      tone(900 - k * 60, 0, .05, 'triangle', .04, 500);
      await wait((ms == null || ms == 0 ? 900 : ms) / 6);
    }
    o['sacude'] = 0;
  }

  // campo.js: marca
  void marca(Object? m) {
    final ms = W['marcas'];
    if (ms is! List) return;
    final i = ms.indexOf(null);
    if (i >= 0) ms[i] = m;
  }

  // campo.js: roba. Canelo takes a ball (out of the air, off the grass or out of somebody's hands) and carries it to his
  // pile (code lines 152 to 154: relative to the ball, the pile's places PILA and Canelo's spot SITIO; the row 206 is a
  // bound, not a place)
  Future<void> roba(String n) async {
    final o = B(n), pe = W['perro'] as Map<String, dynamic>?;
    if (o == null || pe == null) return;
    final p = bolaXY(o);
    await perroA(p[0] - 10, math.min(206, p[1] + 2), 'run');
    if (p[2] > 12) await brinco(pe, math.min(26, p[2] - 4), 5);
    o['con'] = 'perro';
    o['z'] = 0;
    SFX.bonk();
    await wait(150);
    final k = _n(W['pila']).toInt(), q = PILA[math.min(3, k)];
    await perroA(q[0] + 16, q[1], 'run');
    pe['dir'] = -1;
    o['con'] = null;
    o['x'] = q[0];
    o['y'] = q[1];
    o['z'] = 0;
    W['pila'] = k + 1;
    _bolas['pila$k'] = o;
    _bolas.remove(n);
    await perroA(SITIO[0] + 4, SITIO[1] + 3, 'walk', 4);
    pe['pose'] = 'lie';
    pe['dir'] = 1;
    await wait(250);
  }

  // campo.js: alagua. A ball rolls down to the water and in: plop. It floats there (sheet moves line 156: the four
  // places where a ball floats on the lake)
  late final List<List<int>> _flotaEn = [
    for (final d in const [
      [196, 205],
      [207, 198],
      [200, 212],
      [212, 208],
    ])
      _p.floor(156, d[0], d[1]),
  ];

  Future<void> alagua(String n) async {
    final o = B(n);
    if (o == null) return;
    final k = _n(W['flotan']).toInt(), d = _flotaEn[math.min(3, k)];
    await vuela(n, [ORILLA[0], ORILLA[1]], 0, 7, 0);
    await vuela(n, d, 4, 5, 0);
    o['flota'] = 1;
    W['salpica'] = [
      ...((W['salpica'] as List?) ?? const []),
      <String, dynamic>{'x': d[0], 'y': d[1] - 2, 'f': F},
    ];
    tone(300, 0, .12, 'sine', .12, 90);
    tone(180, .08, .2, 'sine', .1, 60);
    W['flotan'] = k + 1;
    _bolas['flota$k'] = o;
    _bolas.remove(n);
    await wait(500);
  }

  // campo.js: nueva. A new small ball out of the basket, to the frog's feet or into somebody's hands
  Future<void> nueva(Object? a) async {
    final ce = W['cesta'] as List;
    _bolas['cq'] = <String, dynamic>{
      'k': 'q',
      'x': ce[0],
      'y': (ce[1] as num) - 12,
      'z': 6,
    };
    SFX.blip();
    W['twinkle'] = 'cesta';
    await wait(450);
    W['twinkle'] = null;
    if (jsTruthy(a) && a != 'pies') {
      await vuela('cq', a!, 10, 6, 0);
    } else {
      await vuela('cq', PIES, 10, 6, 0);
    }
  }

  // DECISION(order 32b, as El patio's and El camino's): a position an act reads from the story file (`+o.x`, `+o.y`:
  // acts.va, acts.perro, acts.ranaa) goes through the sheet's remap, as the runner sends a set step's x and y (page 12,
  // section 5: every position a story file holds; the sheet's remap lists these uses, d-bola-canelo beats.27 and .37 the
  // ones that move)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  Future<void> _act(String k, Map<String, dynamic> o) => acts[k]!(o);

  // campo.js: acts.va, with places of the old file's own (turno17: FILA's, relative), not a story file's
  Future<void> _vaAt(Map<String, dynamic> o, num x, num y) async {
    await mueve('${o['quien']}', x, y, null, o['corre']);
    if (jsTruthy(o['d'])) G('${o['quien']}')!['dir'] = _plus(o['d']);
  }

  Map<String, dynamic> _ball(String k, Object? x, Object? y, Object? z) => {
    'k': k,
    'x': x,
    'y': y,
    'z': z,
  };

  int get _ok =>
      ((W['marcas'] as List?) ?? const []).where((m) => m == 'ok').length;

  static const List<List<int>> _stars = [
    [70, 60],
    [196, 70],
    [136, 50],
    [110, 90],
    [170, 96],
  ];

  static const Map<String, int> _filaOf = {'luis': 0, 'carmen': 1, 'cq': 2};

  // a ball's name as a story writes it (`bola_cq` or `cq`), or [d]
  static String _bolaOf(Object? b, String d) =>
      (jsTruthy(b) ? b as String : d).replaceAll('bola_', '');

  // campo.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'pose': (o) async {
      final p = G('${o['quien']}');
      if (p != null) p['pose'] = o['que'];
    },
    'mira': (o) async {
      final p = G('${o['quien']}');
      if (p != null) p['dir'] = _plus(o['d']);
    },
    'va': (o) async {
      final L = _fromFile(o['x'], o['y']);
      await _vaAt(o, L[0], L[1]);
    },
    'acasa': (o) async {
      await Future.wait([
        for (final k in const ['luis', 'carmen'])
          () async {
            final p = G(k);
            if (p == null) return;
            await mueve(k, CASA[k]![0], CASA[k]![1]);
            p['dir'] = k == 'luis' ? 1 : -1;
            p['pose'] = 'idle';
          }(),
      ]);
    },
    'marca': (o) async {
      marca(o['que']);
      SFX.blip();
      await wait(250);
    },
    'ladra': (o) async {
      await ladra(_plus(jsTruthy(o['n']) ? o['n'] : 2));
    },
    // one throws, another catches: de and a are luis, carmen or cq; b names the ball (it is in de's hands, or at the
    // frog's feet)
    'pasa': (o) async {
      final de = o['de'] as String,
          a = o['a'] as String,
          b = jsTruthy(o['b']) ? o['b'] as String : 'cq';
      if (B(b)!['con'] != de) {
        B(b)!['con'] = de;
        SFX.blip();
        await wait(200);
      }
      if (de != 'cq') {
        final p = G(de)!;
        p['pose'] = 'arriba';
        await wait(160);
      } else {
        bounce(5);
        await wait(140);
      }
      if (a != 'cq') {
        G(a)!['pose'] = 'arriba';
      }
      await vuela(b, a, _plus(jsTruthy(o['alto']) ? o['alto'] : 26));
      if (de != 'cq') G(de)!['pose'] = 'idle';
      if (a == 'cq') {
        bounce(4);
      } else {
        await wait(160);
        G(a)!['pose'] = 'idle';
      }
    },
    // a ball is put down, or rolled, to the frog's feet
    'alpie': (o) async {
      final b = jsTruthy(o['b']) ? o['b'] as String : 'cq';
      final rueda = jsTruthy(o['rueda']);
      await vuela(b, PIES, rueda ? 0 : 6, rueda ? 8 : 5, 0);
    },
    // the frog picks his ball up
    'recoge': (o) async {
      final b = B('cq');
      if (b != null && !jsTruthy(b['con'])) {
        bounce(4);
        await wait(120);
        b['con'] = 'cq';
      }
    },
    // a child fetches the ball from the frog's feet and takes it home
    'sellevan': (o) async {
      final k = o['quien'] as String,
          p = G(k)!,
          b = B(jsTruthy(o['b']) ? o['b'] as String : 'cq')!,
          xy = bolaXY(b);
      await mueve(k, xy[0] + (k == 'luis' ? -22 : 22), xy[1] + 4);
      b['con'] = k;
      SFX.blip();
      await wait(150);
      await mueve(k, CASA[k]![0], CASA[k]![1]);
      p['dir'] = k == 'luis' ? 1 : -1;
    },
    // a child brings the ball over and puts it in the frog's hands
    'trae': (o) async {
      final k = o['quien'] as String,
          p = G(k)!,
          b = B(jsTruthy(o['b']) ? o['b'] as String : 'cq')!,
          q = frogBox(_cq);
      await mueve(
        k,
        k == 'luis' ? q.x - 16 : q.x + q.w + 16,
        (_cq['y'] as num) + 30,
      );
      p['pose'] = 'offer';
      await wait(250);
      b['con'] = 'cq';
      SFX.blip();
      bounce(4);
      await wait(250);
      p['pose'] = 'idle';
      if (!jsTruthy(o['queda'])) {
        await mueve(k, CASA[k]![0], CASA[k]![1]);
        p['dir'] = k == 'luis' ? 1 : -1;
      }
    },
    // the frog carries a ball over to a child and hands it across; the child keeps it, or (vuelve) gives it straight
    // back
    'lleva': (o) async {
      final k = o['a'] as String,
          p = G(k)!,
          bn = jsTruthy(o['b']) ? o['b'] as String : 'cq',
          b = B(bn)!,
          q = _cq,
          x0 = q['x'] as num,
          y0 = q['y'] as num;
      b['con'] = 'cq';
      await hopTo(
        k == 'luis' ? (p['x'] as num) + 8 : (p['x'] as num) - 40,
        (p['y'] as num) - 30,
        2,
      );
      p['pose'] = 'offer';
      await wait(200);
      b['con'] = k;
      SFX.blip();
      await wait(300);
      if (jsTruthy(o['vuelve'])) {
        await wait(200);
        b['con'] = 'cq';
        SFX.blip();
      }
      p['pose'] = 'idle';
      await hopTo(x0, y0, 2);
      if (jsTruthy(o['vuelve'])) await vuela(bn, PIES, 4, 4, 0);
    },
    'roba': (o) async {
      await roba(jsTruthy(o['b']) ? o['b'] as String : 'cq');
    },
    'nueva': (o) async {
      await nueva(o['a']);
    },
    'alagua': (o) async {
      await alagua(jsTruthy(o['b']) ? o['b'] as String : 'juego');
    },

    /* ----- story 15: La bola ----- */
    // sheet moves line 187: `async inicio15(){W.gente=` -> `async inicio15(){W.respEn=[132,32];W.gente=` (the answer
    // cards in the sky); code lines 48, 49: the places are the sheet's spots
    'inicio15': (o) async {
      W['respEn'] = _p.respEn(187);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': CASA['luis']![0],
          'y': CASA['luis']![1],
          'pose': 'idle',
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': CASA['carmen']![0],
          'y': CASA['carmen']![1],
          'pose': 'idle',
          'dir': -1,
        },
      };
      W['perro'] = <String, dynamic>{
        'x': SITIO[0] + 4,
        'y': SITIO[1] + 3,
        'pose': 'sit',
        'dir': 1,
      };
      _cq
        ..['x'] = LUGAR['inicio']![0]
        ..['y'] = LUGAR['inicio']![1]
        ..['s'] = 1;
      W['cesta'] = [...CESTA];
      W['pila'] = 0;
      W['bolas'] = <String, dynamic>{
        'luis': <String, dynamic>{'k': 'L', 'con': 'luis'},
        'carmen': <String, dynamic>{'k': 'C', 'con': 'carmen'},
        'cq': _ball('q', PIES[0], PIES[1], 0),
      };
    },
    /* ----- Escuchar: plain acts for the picture story and the routine ----- */
    // a high ball; the frog jumps for it
    'alta': (o) async {
      await Future.wait([
        _act('pasa', {'de': o['de'], 'a': 'cq', 'b': o['b'], 'alto': 48}),
        () async {
          await wait(TICK * 7);
          await ranaSalta(18);
        }(),
      ]);
    },
    'perro': (o) async {
      final pe = _pe;
      if (o['x'] != null) {
        await _perroA(
          _fromFile(o['x'], o['y']),
          jsTruthy(o['modo']) ? o['modo'] as String : 'run',
        );
      }
      if (jsTruthy(o['que'])) pe['pose'] = o['que'];
      if (jsTruthy(o['dir'])) pe['dir'] = o['dir'];
      if (jsTruthy(o['ms'])) await wait(_plus(o['ms']));
    },
    'deja': (o) async {
      final b = B('${o['b']}'), pe = _pe;
      if (b == null) return;
      b['con'] = null;
      b['x'] = (pe['x'] as num) + 14;
      b['y'] = (pe['y'] as num) + 2;
      b['z'] = 0;
      SFX.blip();
      await wait(200);
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
    'quita': (o) async {
      _bolas.remove(o['b']);
      await wait(100);
    },
    'turno15': (o) async {
      await roba('cq');
      await ladra(1);
      _pe['pose'] = 'lie';
    },
    // he will not let go
    'mueverabo17': (o) async {
      final pe = _pe;
      for (var k = 0; k < 4; k++) {
        pe['dy'] = k % 2 != 0 ? 1 : 0;
        await wait(140);
      }
      pe['dy'] = 0;
    },
    'mueverabo': (o) async {
      final pe = _pe;
      for (var k = 0; k < 4; k++) {
        pe['dir'] = -_dir(pe);
        await wait(140);
      }
      pe['dir'] = 1;
    },
    // the children put their own balls down in the grass beside them, in view
    'bajan': (o) async {
      final l = B('luis'), c = B('carmen');
      await Future.wait([
        l != null && l['con'] == 'luis'
            ? vuela(
                'luis',
                [CASA['luis']![0] - 13, CASA['luis']![1] + 5],
                3,
                4,
                0,
              )
            : Future<void>.value(),
        c != null && c['con'] == 'carmen'
            ? vuela(
                'carmen',
                [CASA['carmen']![0] + 14, CASA['carmen']![1] + 5],
                3,
                4,
                0,
              )
            : Future<void>.value(),
      ]);
    },
    // decision A: Luis holds his big ball, the frog holds his small one
    'listoA': (o) async {
      await _act('acasa', {});
      final l = B('luis')!, b = B('cq');
      if (l['con'] != 'luis') {
        l['con'] = 'luis';
        SFX.blip();
      }
      if (b != null && b['con'] != 'cq') {
        bounce(4);
        await wait(120);
        b['con'] = 'cq';
      }
      await wait(250);
    },
    'bienA': (o) async {
      final lu = G('luis')!;
      if (o['dijo'] == 'tira') {
        final d = vuela(
          'luis',
          [(lu['x'] as num) - 13, (lu['y'] as num) + 5],
          3,
          4,
          0,
        );
        await _act('pasa', {'de': 'cq', 'a': 'luis', 'b': 'cq'});
        await d;
        await vuela('cq', PIES, 0, 8, 0);
        B('luis')!['con'] = 'luis';
      } else {
        final d = vuela('cq', PIES, 3, 4, 0);
        await _act('pasa', {'de': 'luis', 'a': 'cq', 'b': 'luis'});
        await d;
        await _act('pasa', {'de': 'cq', 'a': 'luis', 'b': 'luis'});
      }
    },
    // decision A, wrong: he throws when he should catch / he waits to catch when he should throw
    'malA': (o) async {
      final lu = G('luis')!, q = frogBox(_cq);
      if (o['dijo'] == 'coge') {
        bounce(5);
        lu['pose'] = 'arriba';
        await wait(150);
        final p1 = vuela('luis', [
              q.x + (q.w.toInt() >> 1),
              (_cq['y'] as num) + 28,
              22,
            ], 24),
            p2 = vuela(
              'cq',
              [(lu['x'] as num) - 24, (lu['y'] as num) - 6, 30],
              16,
              8,
            );
        await Future.wait([p1, p2]);
        lu['pose'] = 'idle';
        SFX.bonk();
        bounce(3);
        final back = vuela('luis', 'luis', 8, 7, 0);
        await roba('cq');
        await back;
      } else {
        await vuela('cq', PIES, 3, 4, 0);
        _cq['dy'] = -3;
        await wait(900);
        _cq['dy'] = 0;
        await roba('cq');
      }
    },
    // the hiding game: the two stand side by side, put their heads together, and face us with their hands behind
    // their backs (code line 213: 166, 160 and 190, 156, the floor rule)
    'esconden': (o) async {
      final lu = G('luis')!, ca = G('carmen')!, b = B('cq');
      final bl = B('luis'), bc = B('carmen');
      if (bl != null && bl['con'] == 'luis') {
        await vuela(
          'luis',
          [CASA['luis']![0] - 12, CASA['luis']![1] + 4],
          3,
          4,
          0,
        );
      }
      if (bc != null && bc['con'] == 'carmen') {
        await vuela(
          'carmen',
          [CASA['carmen']![0] + 14, CASA['carmen']![1] + 4],
          3,
          4,
          0,
        );
      }
      if (b != null && b['con'] == 'cq') {
        await vuela('cq', PIES, 4, 4, 0);
      }
      if (b != null && b['con'] != 'carmen') {
        await _act('sellevan', {'quien': 'carmen'});
      }
      final l = _p.floor(213, 166, 160), c = _p.floor(213, 190, 156);
      await Future.wait([
        mueve('luis', l[0], l[1]),
        mueve('carmen', c[0], c[1]),
      ]);
      lu['dir'] = 1;
      ca['dir'] = -1;
      for (var k = 0; k < 3; k++) {
        lu['dy'] = 2;
        ca['dy'] = 2;
        await wait(140);
        lu['dy'] = 0;
        ca['dy'] = 0;
        await wait(140);
      }
      if (B('cq') != null) B('cq')!['vis'] = 0;
      W['tieneBola'] = o['tiene'];
      lu['dir'] = 1;
      ca['dir'] = 1;
      lu['pose'] = 'atras';
      ca['pose'] = 'atras';
      lu['dir'] = -1;
      await wait(300);
    },
    // the one he touched shows what is in his hands
    'ensena': (o) async {
      final k = o['quien'] as String, p = G(k)!, b = B('cq');
      p['pose'] = 'offer';
      if (W['tieneBola'] == k && b != null) {
        b['vis'] = 1;
        b['con'] = k;
        SFX.blip();
      }
      await wait(650);
    },
    'devuelve': (o) async {
      final k = W['tieneBola'], b = B('cq');
      if (b != null && b['con'] == k) {
        await vuela('cq', PIES, 0, 8, 0);
      }
      G('luis')!['pose'] = 'idle';
      G('carmen')!['pose'] = 'idle';
      W['tieneBola'] = null;
      await _act('acasa', {});
    },
    // decision B, wrong: Canelo takes it out of the hands that hold it
    'malB': (o) async {
      await roba('cq');
      G('luis')!['pose'] = 'idle';
      G('carmen')!['pose'] = 'idle';
      W['tieneBola'] = null;
    },
    // decision C: who holds the frog's ball (carmen) or (cq, and Carmen holds up her hands)
    'quien15': (o) async {
      await _act('acasa', {});
      final b = B('cq')!;
      if (o['que'] == 'carmen') {
        if (b['con'] != 'carmen') await _act('sellevan', {'quien': 'carmen'});
      } else {
        if (b['con'] == 'carmen') {
          await _act('trae', {'quien': 'carmen'});
        } else {
          await _act('recoge', {});
        }
        G('carmen')!['pose'] = 'arriba';
      }
      await wait(250);
    },
    'duda': (o) async {
      final ca = G('carmen')!;
      ca['pose'] = o['que'] == 'carmen' ? 'offer' : 'tu';
      SFX.bonk();
      await wait(600);
    },
    // code line 225: the stars, a screen effect, unchanged
    'final15': (o) async {
      final n = _ok, b = B('cq');
      await _act('acasa', {});
      B('luis')!['con'] = 'luis';
      if (b != null) {
        b['vis'] = 1;
        b['con'] = 'cq';
      }
      await wait(300);
      if (b != null) {
        final p = bolaXY(b), h = n == 3 ? 70 : 34;
        b['con'] = null;
        b['x'] = p[0];
        b['y'] = p[1];
        bounce(8);
        for (var i = 1; i <= 14; i++) {
          b['z'] = p[2] + h * math.sin(math.pi * i / 14);
          await wait(TICK);
        }
        b['con'] = 'cq';
      }
      if (n == 3) {
        W['heart'] = 1;
        SFX.win();
        host.fx({'t': 'star', 'n': 36, 'pts': _stars});
      } else if (n > 0) {
        SFX.win();
      } else {
        SFX.coqui();
      }
      await wait(500);
    },

    /* ----- story 16: ¡Arriba! ¡Abajo! ----- */
    // sheet moves line 228: `async inicio16(){W.gente=` -> `async inicio16(){W.respEn=[132,32];W.gente=`; code line
    // 228: every place the floor rule's; line 229: the ball in the fork (HORQ, ARBOL)
    'inicio16': (o) async {
      W['respEn'] = _p.respEn(228);
      final lu = _p.floor(228, 92, 170),
          ca = _p.floor(228, 112, 190),
          pe = _p.floor(228, 46, 178),
          cq = _p.floor(228, 132, 142);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': -1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'idle',
          'dir': -1,
        },
      };
      W['perro'] = <String, dynamic>{
        'x': pe[0],
        'y': pe[1],
        'pose': 'sit',
        'dir': 1,
      };
      _cq
        ..['x'] = cq[0]
        ..['y'] = cq[1]
        ..['s'] = 1;
      W['cesta'] = _p.floor(228, 88, 208);
      W['flotan'] = 0;
      W['bolas'] = <String, dynamic>{
        'juego': _ball('L', HORQ[0], ARBOL[1], ARBOL[1] - HORQ[1] - 3),
      };
    },
    'salta': (o) async {
      if (o['quien'] == 'cq') {
        await ranaSalta(_plus(jsTruthy(o['h']) ? o['h'] : 14));
        return;
      }
      if (o['quien'] == 'perro') {
        await brinco(_pe, _plus(jsTruthy(o['h']) ? o['h'] : 9), 7);
        tone(520, 0, .07, 'square', .05, 300);
        return;
      }
      final p = G('${o['quien']}')!;
      p['pose'] = 'arriba';
      await brinco(p, _plus(jsTruthy(o['h']) ? o['h'] : 9), 8);
      p['pose'] = 'idle';
    },
    // code line 232: the floor rule
    'bajoarbol': (o) async {
      final k = o['quien'] as String;
      if (k == 'cq') {
        final f = _p.floor(232, 52, 138);
        await hopTo(f[0], f[1], 2);
        return;
      }
      final to = k == 'luis' ? _p.floor(232, 78, 166) : _p.floor(232, 70, 172);
      await mueve(k, to[0], to[1]);
      G(k)!['dir'] = -1;
    },
    // campo.js:233: the sheet has no code entry for this line; its rules.floor keeps the places (the children's of
    // inicio16, line 228)
    'aparta': (o) async {
      final k = o['quien'] as String;
      final to = k == 'luis'
          ? _p.floorRule(233, 92, 170)
          : _p.floorRule(233, 112, 190);
      await mueve(k, to[0], to[1]);
      G(k)!['dir'] = -1;
    },
    // the frog jumps higher than anybody and knocks the ball out of the tree; it bounces and rolls down to the reeds
    // (code line 235: the floor rule)
    'tumba': (o) async {
      final f = _p.floor(235, 50, 140), to = _p.floor(235, 104, 190);
      await hopTo(f[0], f[1], 2);
      final q = _cq;
      SFX.hop();
      for (var i = 1; i <= 6; i++) {
        q['dy'] = -46 * math.sin(math.pi / 2 * i / 6);
        await wait(TICK);
      }
      SFX.bonk();
      W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
      final v = vuela('juego', to, 8, 7, 0);
      for (var i = 1; i <= 6; i++) {
        q['dy'] = -46 * math.cos(math.pi / 2 * i / 6);
        await wait(TICK);
      }
      q['dy'] = 0;
      await v;
    },
    // code line 236: the floor rule; JUNCO (moves line 50)
    'ruedabajo': (o) async {
      await vuela('juego', _p.floor(236, 150, 196), 10, 6, 0);
      await vuela('juego', [JUNCO[0], JUNCO[1]], 0, 7, 0);
      W['tiembla'] = <String, dynamic>{'en': 'juncos', 'f': F};
      W['donde'] = 'abajo';
    },
    // Luis goes to where the frog said. arriba: under the tree he holds out his hands and the frog knocks the ball down
    // to him; abajo: he looks in the reeds (sheet moves line 238: `ar?82:166,ar?166:194` -> `ar?82:158,ar?166:186`;
    // code line 239: the floor rule)
    'luisbusca': (o) async {
      final lu = G('luis')!,
          b = B('juego'),
          ar = o['en'] == 'arriba',
          hay = b != null && W['donde'] == o['en'],
          q = _cq;
      lu['ojos'] = 0;
      final to = ar ? _p.floor(238, 82, 166) : _p.floor(238, 166, 194);
      await mueve('luis', to[0], to[1], null, 1);
      if (ar) {
        lu['dir'] = -1;
        lu['pose'] = 'offer';
        await wait(400);
        if (hay) {
          final x0 = q['x'] as num,
              y0 = q['y'] as num,
              f = _p.floor(239, 44, 138);
          await hopTo(f[0], f[1], 2, 1);
          SFX.hop();
          for (var i = 1; i <= 6; i++) {
            q['dy'] = -44 * math.sin(math.pi / 2 * i / 6);
            await wait(TICK);
          }
          W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
          final v = vuela('juego', 'luis', 4, 7, 0);
          for (var i = 1; i <= 6; i++) {
            q['dy'] = -44 * math.cos(math.pi / 2 * i / 6);
            await wait(TICK);
          }
          q['dy'] = 0;
          await v;
          await hopTo(x0, y0, 2);
        } else {
          W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
          await wait(500);
        }
        lu['pose'] = 'idle';
      } else {
        W['tiembla'] = <String, dynamic>{'en': 'juncos', 'f': F};
        await wait(500);
        if (hay) {
          b['vis'] = 1;
          b['con'] = 'luis';
          SFX.blip();
        }
      }
      await wait(300);
      if (hay) {
        await mueve('luis', CASA['luis']![0], CASA['luis']![1]);
        lu['dir'] = 1;
      }
    },
    // ready for the catching game: the frog with his back to the pond, Luis facing him with the ball at his chest (code
    // line 243: the floor rule)
    'listos': (o) async {
      final lu = G('luis')!, ca = G('carmen')!;
      final c = _p.floor(243, 74, 204), f = _p.floor(243, 136, 150);
      await Future.wait([
        mueve('luis', CASA['luis']![0], CASA['luis']![1]),
        mueve('carmen', c[0], c[1]),
        hopTo(f[0], f[1], 2, 1),
      ]);
      lu['dir'] = 1;
      ca['dir'] = 1;
      final pe = W['perro'] as Map<String, dynamic>?;
      if (pe != null) {
        await _perroA(_p.floor(243, 46, 178), 'walk');
        pe['pose'] = 'sit';
        pe['dir'] = 1;
      }
      if (B('juego') == null) {
        final ce = W['cesta'] as List;
        _bolas['juego'] = _ball('q', ce[0], (ce[1] as num) - 12, 6);
      }
      await vuela('juego', 'luis', 8, 6, 0);
    },
    // code line 245: the floor rule (136, 150, the frog's place of listos)
    'listo16': (o) async {
      final lu = G('luis')!, f = _p.floor(245, 136, 150);
      lu['ojos'] = 0;
      if (((_cq['x'] as num) - f[0]).abs() > 3 ||
          ((_cq['y'] as num) - f[1]).abs() > 3) {
        await hopTo(f[0], f[1], 2, 1);
      }
      if (((lu['x'] as num) - CASA['luis']![0]).abs() > 3) {
        await mueve('luis', CASA['luis']![0], CASA['luis']![1]);
      }
      lu['dir'] = 1;
      if (B('juego') == null) {
        final ce = W['cesta'] as List;
        _bolas['juego'] = _ball('q', ce[0], (ce[1] as num) - 12, 6);
      }
      if (B('juego')!['con'] != 'luis') await vuela('juego', 'luis', 8, 6, 0);
    },
    // Luis throws high or rolls it low; the frog does what he chose (arriba: he jumps; abajo: he crouches) (code lines
    // 249, 250: the floor rule)
    'tiro': (o) async {
      final lu = G('luis')!,
          q = _cq,
          alto = o['como'] == 'arriba',
          bien = o['hace'] == o['como'];
      lu['pose'] = alto ? 'arriba' : 'offer';
      await wait(200);
      if (alto) {
        final a = _p.floor(249, 178, 186);
        final v = vuela(
          'juego',
          bien ? 'cq' : [a[0], a[1], 30],
          bien ? 30 : 22,
          9,
        );
        if (o['hace'] == 'arriba') {
          await wait(260);
          await ranaSalta(16, 8);
        } else {
          q['s'] = .86;
          await wait(500);
        }
        await v;
      } else {
        final a = _p.floor(250, 176, 190);
        final v = vuela('juego', bien ? 'cq' : [a[0], a[1], 0], 0, 10, 0);
        if (o['hace'] == 'arriba') {
          await wait(200);
          await ranaSalta(16, 8);
        } else {
          q['s'] = .86;
          await wait(450);
        }
        await v;
      }
      q['s'] = 1;
      lu['pose'] = 'idle';
      if (bien) {
        bounce(4);
        await wait(200);
      } else {
        await alagua('juego');
      }
    },
    'alacesta': (o) async {
      final b = B('juego');
      if (b != null) {
        final ce = W['cesta'] as List;
        await vuela('juego', [ce[0], (ce[1] as num) - 10, 4], 14, 7, 0);
        _bolas.remove('juego');
      }
    },
    // Canelo's go: he jumps when the ball comes low; it rolls under him and into the pond (code line 254: the floor
    // rule)
    'turno16a': (o) async {
      final pe = _pe, j = B('juego');
      if (j != null && j['con'] != 'luis') {
        await vuela('juego', 'luis', 8, 6, 0);
      }
      final f = _p.floor(254, 150, 128);
      await hopTo(f[0], f[1], 2);
      await _perroA(_p.floor(254, 140, 180), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
      await wait(300);
    },
    // code line 255: the floor rule
    'turno16b': (o) async {
      final pe = _pe, lu = G('luis')!, a = _p.floor(255, 176, 190);
      lu['pose'] = 'offer';
      await wait(200);
      final v = vuela('juego', [a[0], a[1], 0], 0, 11, 0);
      await wait(180);
      await brinco(pe, 14, 8);
      tone(520, 0, .07, 'square', .05, 300);
      await v;
      lu['pose'] = 'idle';
      await alagua('juego');
      pe['dir'] = 1;
      pe['pose'] = 'lie';
      await wait(500);
    },
    // after Canelo's miss: Luis takes a ball from the basket and throws it high to Carmen, who takes it over her head
    // and throws it back
    'prepcarmen': (o) async {
      final ca = G('carmen')!, ce = W['cesta'] as List;
      _bolas['juego'] = _ball('q', ce[0], (ce[1] as num) - 12, 6);
      await Future.wait([
        vuela('juego', 'luis', 8, 6, 0),
        mueve('carmen', CASA['carmen']![0], CASA['carmen']![1]),
      ]);
      ca['dir'] = -1;
    },
    // code line 259: the floor rule
    'acarmen': (o) async {
      final lu = G('luis')!, ca = G('carmen')!;
      lu['pose'] = 'arriba';
      await wait(200);
      ca['pose'] = 'arriba';
      final v = vuela('juego', 'carmen', 30, 9);
      await wait(250);
      await brinco(ca, 8, 7);
      await v;
      lu['pose'] = 'idle';
      await wait(300);
      await vuela('juego', 'luis', 22, 8);
      ca['pose'] = 'idle';
      final c = _p.floor(259, 74, 204);
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = 1;
    },
    // code line 260: the floor rule
    'trasturno': (o) async {
      final pe = _pe;
      await _perroA(_p.floor(260, 46, 178), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = 1;
      final f = _p.floor(260, 136, 150);
      await hopTo(f[0], f[1], 2);
    },
    // the picture goes dark: somebody hides the ball (arriba: in the tree; abajo: in the reeds) (code line 263: every
    // place here the floor rule's; line 264: relative to the fork and the old crown, JUNCO moved: moves line 50)
    'esconde16': (o) async {
      W['cierra'] = 1;
      await wait(350);
      for (var i = 1; i <= 5; i++) {
        W['oscuro'] = i * .19;
        await wait(TICK);
      }
      final lu = G('luis')!,
          ca = G('carmen')!,
          pe = W['perro'] as Map<String, dynamic>?;
      for (var k = 0; k < 4; k++) {
        tone(140 + k % 2 * 30, 0, .06, 'square', .05, 90);
        await wait(220);
      }
      final l = _p.floor(263, 96, 180),
          c = _p.floor(263, 122, 184),
          d = _p.floor(263, 110, 198),
          f = _p.floor(263, 136, 136);
      lu['x'] = l[0];
      lu['y'] = l[1];
      lu['dir'] = 1;
      lu['pose'] = 'idle';
      lu['ojos'] = 0;
      ca['x'] = c[0];
      ca['y'] = c[1];
      ca['dir'] = -1;
      ca['pose'] = 'idle';
      if (pe != null) {
        pe['x'] = d[0];
        pe['y'] = d[1];
        pe['pose'] = 'sit';
        pe['dir'] = 1;
      }
      _cq
        ..['x'] = f[0]
        ..['y'] = f[1]
        ..['s'] = 1;
      final ar = o['en'] == 'arriba';
      _bolas['juego'] = <String, dynamic>{
        'k': 'q',
        'x': ar ? HORQ[0] - 4 : JUNCO[0],
        'y': ar ? ARBOL[1] : JUNCO[1],
        'z': ar ? ARBOL[1] - COPA[1] : 0,
        'vis': 0,
      };
      W['donde'] = o['en'];
      for (var i = 4; i >= 0; i--) {
        W['oscuro'] = i * .19;
        await wait(TICK);
      }
      W['oscuro'] = 0;
      W['cierra'] = 0;
      await wait(200);
    },
    // the frog goes to look (arriba: he jumps up into the leaves; abajo: he hops down to the reeds) (code line 268: the
    // floor rule; moves line 269: hopTo(160,166,3,1) -> hopTo(147,153,3,1), on the lawn above the reeds)
    'busca': (o) async {
      final ar = o['en'] == 'arriba',
          b = B('juego'),
          hay = b != null && W['donde'] == o['en'],
          q = _cq;
      if (ar) {
        final f = _p.floor(268, 46, 140);
        await hopTo(f[0], f[1], 3, 1);
        SFX.hop();
        for (var i = 1; i <= 6; i++) {
          q['dy'] = -44 * math.sin(math.pi / 2 * i / 6);
          await wait(TICK);
        }
        W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
        if (hay) {
          b['vis'] = 1;
        }
        await wait(200);
        final v = hay ? vuela('juego', _p.floor(268, 84, 188), 6, 6, 0) : null;
        for (var i = 1; i <= 6; i++) {
          q['dy'] = -44 * math.cos(math.pi / 2 * i / 6);
          await wait(TICK);
        }
        q['dy'] = 0;
        if (v != null) {
          await v;
          final g = _p.floor(268, 70, 160);
          await hopTo(g[0], g[1], 1);
          b!['con'] = 'cq';
          SFX.blip();
        }
      } else {
        final f = _p.floor(269, 160, 166);
        await hopTo(f[0], f[1], 3, 1);
        W['tiembla'] = <String, dynamic>{'en': 'juncos', 'f': F};
        await wait(400);
        if (hay) {
          b['vis'] = 1;
          b['con'] = 'cq';
          SFX.blip();
        }
      }
      if (!hay) {
        SFX.bonk();
        await wait(400);
      }
    },
    // he was wrong: Canelo runs to where the ball really is (he jumps against the tree; or he noses into the reeds) and
    // knocks it loose; he cannot hold it, and it rolls into the pond (code lines 273, 274: the floor rule; moves line
    // 274: perroA(166,198,"run") -> perroA(153,183,"run"), on the lawn by the water)
    'perrotumba': (o) async {
      final b = B('juego'), pe = W['perro'] as Map<String, dynamic>?;
      if (b == null) return;
      final ar = W['donde'] == 'arriba';
      if (ar) {
        await _perroA(_p.floor(273, 80, 166), 'run');
        pe!['dir'] = -1;
        await ladra(1);
        await brinco(pe, 9, 6);
        W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
        SFX.bonk();
        b['vis'] = 1;
        b['con'] = null;
        await vuela('juego', _p.floor(273, 98, 188), 6, 7, 0);
        final c = _perroA(_p.floor(273, 112, 190), 'run');
        await vuela('juego', _p.floor(273, 150, 196), 10, 7, 0);
        await c;
        await _perroA(_p.floor(273, 160, 196), 'run');
      } else {
        await _perroA(_p.floor(274, 166, 198), 'run');
        pe!['pose'] = 'husmea';
        W['tiembla'] = <String, dynamic>{'en': 'juncos', 'f': F};
        await wait(350);
        b['vis'] = 1;
        b['con'] = null;
        await vuela('juego', _p.floor(274, 176, 203), 3, 4, 0);
      }
      await alagua('juego');
      pe['pose'] = 'sit';
      await wait(300);
    },
    // the frog gives the ball he holds to Luis
    'aluis': (o) async {
      final b = B('juego');
      if (b != null && b['con'] != 'luis') {
        bounce(4);
        await vuela('juego', 'luis', 12, 7, 0);
      }
      await wait(200);
    },
    // code line 278: the floor rule
    'vuelve16': (o) async {
      final f = _p.floor(278, 136, 136);
      await hopTo(f[0], f[1], 3, 1);
    },
    // decision C: Luis throws one up with the sun in his eyes; we see where it comes down (code lines 280, 282: the
    // floor rule; JUNCO moved, moves line 50)
    'sol': (o) async {
      final lu = G('luis')!,
          ca = G('carmen')!,
          pe = W['perro'] as Map<String, dynamic>?;
      final l = _p.floor(280, 104, 180),
          c = _p.floor(280, 76, 202),
          f = _p.floor(280, 136, 136);
      await Future.wait([
        mueve('luis', l[0], l[1]),
        mueve('carmen', c[0], c[1]),
        hopTo(f[0], f[1], 2, 1),
      ]);
      lu['dir'] = 1;
      if (pe != null) {
        await _perroA(_p.floor(280, 50, 196), 'walk');
        pe['pose'] = 'sit';
        pe['dir'] = 1;
      }
      ca['dir'] = -1;
      ca['pose'] = 'offer';
      final ce = W['cesta'] as List;
      _bolas['juego'] = _ball('q', ce[0], (ce[1] as num) - 12, 6);
      await vuela('juego', 'luis', 8, 6, 0);
      lu['pose'] = 'arriba';
      await wait(250);
      lu['ojos'] = 1;
      lu['pose'] = 'idle';
      W['donde'] = o['en'];
      if (o['en'] == 'arriba') {
        await vuela(
          'juego',
          [HORQ[0], ARBOL[1], ARBOL[1] - HORQ[1] - 3],
          50,
          12,
        );
        W['tiembla'] = <String, dynamic>{'en': 'arbol', 'f': F};
      } else {
        await vuela('juego', _p.floor(282, 156, 186), 56, 12);
        await vuela('juego', [JUNCO[0] - 2, JUNCO[1] + 2], 5, 6, 0);
        W['tiembla'] = <String, dynamic>{'en': 'juncos', 'f': F};
      }
      await wait(300);
    },
    // sheet moves line 284: `mueve("luis",150,194),mueve("carmen",128,202)` -> `mueve("luis",147,191),
    // mueve("carmen",127,201)` (by the water, 8 px of lawn round their feet); code lines 284, 285: the floor rule; line
    // 286: the three balls (the sheet's rules.floor: no code entry); line 287: the stars, a screen effect
    'final16': (o) async {
      final n = _ok, lu = G('luis')!, ca = G('carmen')!;
      lu['ojos'] = 0;
      ca['pose'] = 'idle';
      if (n == 0) {
        final l = _p.floor(284, 150, 194),
            c = _p.floor(284, 128, 202),
            f = _p.floor(284, 148, 146);
        await Future.wait([
          mueve('luis', l[0], l[1]),
          mueve('carmen', c[0], c[1]),
          hopTo(f[0], f[1], 2, 1),
        ]);
        lu['dir'] = 1;
        ca['dir'] = 1;
        SFX.coqui();
        await wait(700);
      } else {
        final l = _p.floor(285, 96, 180),
            c = _p.floor(285, 168, 176),
            f = _p.floor(285, 118, 142);
        await Future.wait([
          mueve('luis', l[0], l[1]),
          mueve('carmen', c[0], c[1]),
          hopTo(f[0], f[1], 2, 1),
        ]);
        lu['dir'] = 1;
        ca['dir'] = -1;
        lu['pose'] = 'arriba';
        ca['pose'] = 'arriba';
        final k = n == 3 ? 3 : 1;
        for (var i = 0; i < k; i++) {
          final f = _p.floorRule(286, 108 + i * 18, 196);
          _bolas['f$i'] = _ball('q', f[0], f[1], 8);
        }
        Future<void> sube(String nm, num d) async {
          final o = B(nm)!, z0 = o['z'] as num;
          await wait(d);
          for (var j = 1; j <= 14; j++) {
            o['z'] = z0 + 52 * math.sin(math.pi * j / 14);
            await wait(TICK);
          }
          o['z'] = z0;
        }

        final s = <Future<void>>[];
        for (var i = 0; i < k; i++) {
          s.add(sube('f$i', i * 120));
        }
        await Future.wait([...s, ranaSalta(24, 12)]);
        if (n == 3) {
          W['heart'] = 1;
          SFX.win();
          host.fx({'t': 'star', 'n': 36, 'pts': _stars});
        } else {
          SFX.win();
        }
        lu['pose'] = 'idle';
        ca['pose'] = 'idle';
      }
      await wait(300);
    },
    'saltan': (o) async {
      final lu = G('luis')!, ca = G('carmen')!;
      await Future.wait([
        brinco(lu, 9, 8),
        brinco(ca, 9, 8),
        ranaSalta(40, 14),
      ]);
      await ranaSalta(40, 14);
      final pe = W['perro'] as Map<String, dynamic>?;
      if (pe != null) {
        pe['dir'] = 1;
        await ladra(2);
      }
    },

    /* ----- story 17: ¡Otra vez! ----- */
    // sheet moves line 292: `async inicio17(){W.gente=` -> `async inicio17(){W.respEn=[132,32];W.gente=`; code line
    // 292: every place the floor rule's
    'inicio17': (o) async {
      W['respEn'] = _p.respEn(292);
      final lu = _p.floor(292, 84, 174),
          ca = _p.floor(292, 58, 198),
          pe = _p.floor(292, 196, 204),
          cq = _p.floor(292, 112, 140);
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
          'dir': 1,
        },
      };
      W['perro'] = <String, dynamic>{
        'x': pe[0],
        'y': pe[1],
        'pose': 'walk',
        'dir': -1,
        'mojado': 1,
      };
      _cq
        ..['x'] = cq[0]
        ..['y'] = cq[1]
        ..['s'] = 1;
      W['mojado'] = 0;
      W['bolas'] = <String, dynamic>{
        'carmen': <String, dynamic>{'k': 'C', 'con': 'carmen'},
        'cq': _ball('q', FILA[2][0], FILA[2][1], 0),
        'luis': <String, dynamic>{'k': 'L', 'con': 'perro'},
      };
    },
    // code line 294: the floor rule
    'carmenfila': (o) async {
      final ca = G('carmen')!;
      ca['pose'] = 'idle';
      await mueve('carmen', FILA[1][0] - 12, FILA[1][1] + 2);
      final b = B('carmen')!;
      b['con'] = null;
      b['x'] = FILA[1][0];
      b['y'] = FILA[1][1];
      b['z'] = 0;
      SFX.blip();
      final c = _p.floor(294, 58, 198);
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = 1;
    },
    // Canelo comes up from the water with the ball in his mouth and stops in front of the frog (moves line 296:
    // perroA(160,190,"walk") -> perroA(155,178,"walk"), on the lawn)
    'sube17': (o) async {
      final pe = _pe;
      await _perroA(_p.floor(296, 160, 190), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
      await wait(300);
    },
    // Canelo puts the ball he holds into its place in the row (moves line 298: by the small ball's place, i 2, he goes
    // to his place by the water, as perroA(160, 190), line 296; perroA(164,188,"walk") -> perroA(157,177,"walk"))
    'alafila': (o) async {
      final n = o['b'] as String, i = _filaOf[n]!, pe = _pe;
      await _perroA(
        i == 2 ? _p.floor(296, 160, 190) : [FILA[i][0] + 16, FILA[i][1] - 4],
        'walk',
      );
      pe['dir'] = -1;
      final b = B(n)!;
      b['con'] = null;
      b['x'] = FILA[i][0];
      b['y'] = FILA[i][1];
      b['z'] = 0;
      SFX.blip();
      await wait(200);
      await _perroA(_p.floor(298, 164, 188), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
    },
    // Canelo picks a ball out of the row and stands with it in front of the frog and Luis (moves line 300: 16 px right
    // of the small ball is within 8 px of the bank, so there he goes to his place by the water, 155, 178;
    // perroA(160,190,"walk") -> perroA(155,178,"walk"))
    'perrocoge': (o) async {
      final n = o['b'] as String, pe = _pe, b = B(n)!, p = bolaXY(b);
      final mv = _p.floor(300, 160, 191);
      await _perroA(p[0] + 16 > mv[0] ? mv : [p[0] + 16, p[1] - 3], 'walk');
      pe['dir'] = -1;
      b['con'] = 'perro';
      SFX.blip();
      await wait(200);
      await _perroA(_p.floor(300, 160, 190), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
      await wait(200);
    },
    // Canelo drops the ball he holds at the frog's feet (the small ball's place in the row)
    'suelta17': (o) async {
      final n = jsTruthy(o['b']) ? o['b'] as String : 'cq', b = B(n);
      if (b != null && b['con'] == 'perro') {
        await vuela(n, FILA[_filaOf[n]!], 4, 5, 0);
      }
    },
    // a ball is thrown down toward the pond (by the frog, or by Luis); Canelo fetches it (aire: he takes it out of the
    // air) and puts it back in its place in the row. sacude: "no" = he does not shake himself by the water (code line
    // 306: the floor rule; moves line 307: perroA(ORILLA[0]-12,ORILLA[1]+2,"run") -> perroA(183,201,"run"), wading;
    // moves line 310: by the small ball's place he goes to 155, 178, and perroA(164,188,"walk") ->
    // perroA(157,177,"walk"))
    'tira17': (o) async {
      final n = _bolaOf(o['b'], 'cq'),
          b = B(n)!,
          pe = _pe,
          i = _filaOf[n]!,
          de = jsTruthy(o['de']) ? o['de'] as String : 'cq';
      if (b['con'] != de) {
        b['con'] = de;
        SFX.blip();
        await wait(150);
      }
      if (de == 'cq') {
        bounce(6);
        await wait(160);
      } else {
        G(de)!['pose'] = 'arriba';
        await wait(200);
      }
      if (jsTruthy(o['aire'])) {
        final a = _p.floor(306, 176, 186);
        final v = vuela(n, [a[0], a[1], 22], 26, 9);
        await _perroA(_p.floor(306, 168, 188), 'run');
        await brinco(pe, 16, 5);
        await v;
        b['con'] = 'perro';
        SFX.blip();
      } else {
        final v = vuela(n, [ORILLA[0], ORILLA[1] + 2], 30, 10);
        pe['pose'] = 'run';
        await wait(120);
        await _perroA(_p.floor(307, ORILLA[0] - 12, ORILLA[1] + 2), 'run');
        await v;
        W['salpica'] = [
          ...((W['salpica'] as List?) ?? const []),
          <String, dynamic>{'x': ORILLA[0], 'y': ORILLA[1], 'f': F},
        ];
        tone(300, 0, .12, 'sine', .12, 90);
        b['con'] = 'perro';
        pe['mojado'] = 1;
        await wait(250);
        if (o['sacude'] != 'no') {
          pe['dir'] = -1;
          await sacude(700);
        }
      }
      if (de != 'cq') G(de)!['pose'] = 'idle';
      await _perroA(
        i == 2 ? _p.floor(296, 160, 190) : [FILA[i][0] + 16, FILA[i][1] - 4],
        'run',
      );
      pe['dir'] = -1;
      b['con'] = null;
      b['x'] = FILA[i][0];
      b['y'] = FILA[i][1];
      b['z'] = 0;
      SFX.blip();
      await wait(150);
      await _perroA(_p.floor(310, 164, 188), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
    },
    // he carries the small ball to Luis and puts it in his hands; Luis throws it for Canelo himself (solo: Luis only
    // puts it back in the row) (code lines 312, 313: the floor rule)
    'da17': (o) async {
      final b = B('cq')!, lu = G('luis')!;
      b['con'] = 'cq';
      await hopTo((lu['x'] as num) + 8, (lu['y'] as num) - 34, 2);
      lu['pose'] = 'offer';
      await wait(200);
      b['con'] = 'luis';
      SFX.blip();
      await wait(250);
      lu['pose'] = 'idle';
      final f = _p.floor(312, 112, 140);
      await hopTo(f[0], f[1], 2);
      if (jsTruthy(o['solo'])) {
        await mueve('luis', FILA[2][0] - 14, FILA[2][1] - 3);
        b['con'] = null;
        b['x'] = FILA[2][0];
        b['y'] = FILA[2][1];
        b['z'] = 0;
        SFX.blip();
        final l = _p.floor(313, 84, 174);
        await mueve('luis', l[0], l[1]);
        lu['dir'] = 1;
      } else {
        await _act('tira17', {'b': 'cq', 'de': 'luis'});
      }
    },
    // decision B: what he chose to do (mal: it was not what Luis called, so nothing follows from it)
    'hazB': (o) async {
      final q = o['que'];
      if (q == 'tira') {
        await _act('tira17', {
          'b': 'cq',
          'sacude': jsTruthy(o['mal']) ? 'no' : null,
        });
      } else if (q == 'da') {
        await _act('da17', {'solo': o['mal']});
      } else {
        await _act('aguanta', {'bebe': jsTruthy(o['mal']) ? 'no' : null});
      }
    },
    // decision A, wrong: he throws another ball; it lands a little way off and Canelo does not go after it (moves line
    // 317: [168,206] -> [166,207], at the water's edge, in the water)
    'malA17': (o) async {
      final n = _bolaOf(o['b'], 'cq'), b = B(n)!;
      b['con'] = 'cq';
      bounce(6);
      await wait(160);
      await vuela(n, _p.floor(317, 168, 206), 22, 8);
      _pe['pose'] = 'sit';
      await wait(500);
    },
    // code line 318: the floor rule; moves line 318: perroA(164,188,"walk") -> perroA(157,177,"walk")
    'vuelvefila': (o) async {
      final n = _bolaOf(o['b'], 'cq'), i = _filaOf[n]!, pe = _pe;
      await _perroA(_p.floor(318, 180, 204), 'walk');
      pe['dir'] = -1;
      pe['pose'] = 'husmea';
      final v = vuela(n, FILA[i], 0, 10, 0);
      await perroA(FILA[i][0] + 16, FILA[i][1] - 2, 'walk');
      await v;
      await _perroA(_p.floor(318, 164, 188), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
    },
    // moves line 319: perroA(150,192,"walk",8) -> perroA(146,188,"walk",8), on the lawn
    'jadea': (o) async {
      final pe = _pe;
      await _perroA(_p.floor(319, 150, 192), 'walk', 8);
      pe['dir'] = -1;
      pe['pose'] = 'bark';
      await wait(700);
      pe['pose'] = 'sit';
    },
    'luisno': (o) async {
      final p = G('luis')!;
      for (var k = 0; k < 4; k++) {
        p['dir'] = -_dir(p);
        await wait(140);
      }
      p['dir'] = 1;
      SFX.bonk();
      await wait(250);
    },
    'empuja2': (o) async {
      final pe = _pe;
      pe['pose'] = 'husmea';
      await wait(500);
      pe['pose'] = 'lie';
    },
    // code line 322: the floor rule
    'lleva17': (o) async {
      final n = _bolaOf(o['b'], 'luis'),
          b = B(n)!,
          lu = G('luis')!,
          p = bolaXY(b);
      await hopTo(p[0] - 16, p[1] - 50, 1);
      b['con'] = 'cq';
      SFX.blip();
      await hopTo((lu['x'] as num) + 8, (lu['y'] as num) - 34, 2);
      lu['pose'] = 'offer';
      await wait(200);
      b['con'] = 'luis';
      SFX.blip();
      await wait(250);
      final f = _p.floor(322, 112, 140);
      await hopTo(f[0], f[1], 2);
    },
    // code line 323: the floor rule
    'luisfila': (o) async {
      final lu = G('luis')!;
      await mueve('luis', FILA[0][0] - 12, FILA[0][1] - 3);
      final b = B('luis')!;
      b['con'] = null;
      b['x'] = FILA[0][0];
      b['y'] = FILA[0][1];
      b['z'] = 0;
      lu['pose'] = 'idle';
      SFX.blip();
      final l = _p.floor(323, 84, 174);
      await mueve('luis', l[0], l[1]);
      lu['dir'] = 1;
    },
    // moves line 324: perroA(FILA[2][0]+14,FILA[2][1]-4,"walk") -> perroA(153,183,"walk"), 8 px of lawn round his feet
    'empuja': (o) async {
      final pe = _pe;
      await _perroA(_p.floor(324, FILA[2][0] + 14, FILA[2][1] - 4), 'walk');
      pe['dir'] = -1;
      pe['pose'] = 'husmea';
      await wait(350);
      pe['pose'] = 'sit';
      await ladra(2);
    },
    // he holds the ball and stands still; Canelo goes down and drinks (moves line 326:
    // perroA(ORILLA[0]-10,ORILLA[1]+2,"walk") -> perroA(180,204,"walk"), the open bank down the shore from the reeds;
    // perroA(164,188,"walk") -> perroA(157,177,"walk"))
    'aguanta': (o) async {
      final b = B('cq')!, pe = _pe;
      bounce(4);
      await wait(120);
      b['con'] = 'cq';
      await wait(500);
      if (o['bebe'] != 'no') {
        await _perroA(_p.floor(326, ORILLA[0] - 10, ORILLA[1] + 2), 'walk');
        pe['dir'] = 1;
        pe['pose'] = 'eat';
        await wait(900);
        pe['mojado'] = 1;
        await _perroA(_p.floor(326, 164, 188), 'walk');
        pe['pose'] = 'sit';
        pe['dir'] = -1;
      }
      await vuela('cq', FILA[2], 4, 4, 0);
    },
    // Canelo shakes himself beside somebody: water everywhere (moves line 328: perroA(164,188,"walk") ->
    // perroA(157,177,"walk"))
    'sacude': (o) async {
      final pe = _pe, k = o['junto'];
      if (k == 'cq') {
        final q = frogBox(_cq);
        await perroA(q.x + q.w + 12, (_cq['y'] as num) + 30, 'walk');
        pe['dir'] = -1;
        pe['pose'] = 'sit';
        await wait(600);
        await sacude(900);
        W['mojado'] = math.min(3, _n(W['mojado']) + 1);
        SFX.bonk();
        await wait(300);
        await _perroA(_p.floor(328, 164, 188), 'walk');
        pe['pose'] = 'sit';
        pe['dir'] = -1;
      } else {
        final p = G('$k')!;
        await perroA((p['x'] as num) + 22, (p['y'] as num) + 2, 'walk');
        pe['dir'] = -1;
        pe['pose'] = 'sit';
        await wait(900);
        await sacude(900);
        p['mojado'] = 1;
        SFX.bonk();
        await wait(300);
      }
    },
    // the turn: Carmen has the ball but watches a butterfly (code line 331: the floor rule; the butterfly's flight is
    // relative to its place)
    'turno17': (o) async {
      final ca = G('carmen')!;
      await _vaAt({'quien': 'carmen'}, FILA[2][0] - 12, FILA[2][1] - 2);
      B('cq')!['con'] = 'carmen';
      SFX.blip();
      final c = _p.floor(331, 58, 198), m0 = _p.floor(331, 40, 150);
      await mueve('carmen', c[0], c[1]);
      ca['dir'] = -1;
      final m = <String, dynamic>{'x': m0[0], 'y': m0[1]};
      W['mariposa'] = m;
      for (var i = 0; i < 10; i++) {
        m['x'] = m0[0] - i * 1.5 + math.sin(i) * 3;
        m['y'] = m0[1] - i + math.cos(i * 1.3) * 3;
        await wait(TICK * 2);
      }
    },
    // moves line 332: perroA(164,188,"walk") -> perroA(157,177,"walk")
    'trasturno17': (o) async {
      final pe = _pe;
      W['mariposa'] = null;
      G('carmen')!['dir'] = 1;
      await vuela('cq', FILA[2], 0, 9, 0);
      await _perroA(_p.floor(332, 164, 188), 'walk');
      pe['pose'] = 'sit';
      pe['dir'] = -1;
    },
    // moves line 333: Canelo lies down by the water with the small ball, perroA(160,196,"walk") ->
    // perroA(149,182,"walk") and vuela("cq",[170,197],0,4,0) -> vuela("cq",[159,183],0,4,0), on the lawn; code line
    // 334: the stars, a screen effect
    'final17': (o) async {
      final n = _ok, pe = _pe, ca = G('carmen')!, b = B('cq');
      await _perroA(_p.floor(333, 160, 196), 'walk');
      if (b != null) {
        await vuela('cq', _p.floor(333, 170, 197), 0, 4, 0);
      }
      pe['pose'] = 'lie';
      pe['dir'] = 1;
      await wait(400);
      if (n == 3) {
        ca['pose'] = 'tu';
        ca['rie'] = 1;
        await wait(500);
        bounce(6);
        await wait(300);
        bounce(6);
        ca['rie'] = 0;
        ca['pose'] = 'idle';
        W['heart'] = 1;
        SFX.win();
        host.fx({'t': 'star', 'n': 36, 'pts': _stars});
        await wait(600);
      } else if (n > 0) {
        SFX.win();
        await wait(500);
      } else {
        SFX.coqui();
        await wait(700);
      }
    },
    'rien': (o) async {
      final lu = G('luis')!, ca = G('carmen')!;
      lu['rie'] = 1;
      ca['rie'] = 1;
      bounce(5);
      await wait(700);
      lu['rie'] = 0;
      ca['rie'] = 0;
    },
  };

  // campo.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    SFX.bonk();
    await wait(300);
  }

  // campo.js: poke
  @override
  dynamic poke(String what) {
    if (what == 'perro' && jsTruthy(W['perro'])) unawaited(ladra(1));
    return null;
  }

  // JavaScript: `"" + p[k]` of a field that may be missing ("undefined")
  static String _jsField(Map<String, dynamic> p, String k) =>
      p.containsKey(k) ? _js(p[k]) : 'undefined';

  // campo.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        () {
          final p = g[k] as Map<String, dynamic>;
          return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}:${_jsField(p, 'pose')}';
        }(),
    ].join(' ');
    final pe = W['perro'] as Map<String, dynamic>?;
    final perro = pe != null
        ? '${jsNum(_round(pe['x'] as num))},${jsNum(_round(pe['y'] as num))}:${_jsField(pe, 'pose')}'
        : '-';
    final bs = (W['bolas'] as Map<String, dynamic>?) ?? const {};
    final bolas = [
      for (final k in bs.keys)
        () {
          final b = bs[k] as Map<String, dynamic>;
          return k +
              (jsTruthy(b['con'])
                  ? '>${_js(b['con'])}'
                  : '@${jsNum(_round(b['x'] as num))},${jsNum(_round(b['y'] as num))}') +
              (b['vis'] == 0 ? '(oculta)' : '');
        }(),
    ].join(' ');
    final marcas = ((W['marcas'] as List?) ?? const [])
        .map((m) => m == null ? '' : _js(m))
        .join();
    return 'gente=$gente perro=$perro bolas=$bolas marcas=$marcas'
        ' pila=${_js(_n(W['pila']))} flotan=${_js(_n(W['flotan']))} mojado=${_js(_n(W['mojado']))}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through
  // the sheet's remap table. A ground point (a child's feet, the frog's, Canelo's, a ball's, the flower's) keeps its
  // screen place (the sheet's `new`; the few the sheet moved: the pairs dame, mi, tu, salta and bola up the lawn with
  // their pictures, Canelo by the water, a ball in the reeds); a point in the air keeps its screen numbers (`to.screen`:
  // where the answer cards stand); a ball's flight lines are no place (`to.none`) and are given back; a pair rectangle
  // gives the crop of the pictures it was; a level picture's rectangle or x gives itself back (the level pictures are
  // the sheet's, whole).
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

  // campo-preview.html: PV.pair's remapW for a review picture's own W (the pair's file, cual-campo): the children's feet
  // (gente.<id>), the balls where they lie (bolas.<k>, not carried) and the flower (flor: [x, y]) through the sheet's
  // remap, as the top-level places (cq, perro) are by ScenePictures; a ball's height is kept
  @override
  void placePair(Map<String, dynamic> set) {
    final gente = set['gente'];
    if (gente is Map) {
      for (final p in gente.values) {
        if (p is Map && p['x'] is num && p['y'] is num) {
          final r = remap([p['x'] as num, p['y'] as num]);
          p['x'] = r[0];
          p['y'] = r[1];
        }
      }
    }
    final bolas = set['bolas'];
    if (bolas is Map) {
      for (final o in bolas.values) {
        if (o is Map && !jsTruthy(o['con']) && o['x'] is num && o['y'] is num) {
          final r = remap([o['x'] as num, o['y'] as num]);
          o['x'] = r[0];
          o['y'] = r[1];
        }
      }
    }
    final flor = set['flor'];
    if (flor is List && flor.length == 2) {
      final r = remap([flor[0] as num, flor[1] as num]);
      set['flor'] = [r[0], r[1]];
    }
  }
}

/// One entry of campo.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is
/// (campo-preview.html, sheet front.tags: `id` for a child or the frog, `k` for Canelo, `b` for a ball, `cesta` for the
/// basket, `front` for a part of the set drawn again).
class CampoItem {
  CampoItem(
    this.y,
    this.d, {
    this.id,
    this.k,
    this.b,
    this.cesta = false,
    this.front,
  });

  final num y;
  final void Function() d;
  final String? id, k, b, front;
  final bool cesta;
}
