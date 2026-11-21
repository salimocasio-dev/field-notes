// Port of historia/escenas/patio.js: the scene "El patio", abuela's back yard (order 32b). Line for line, minus its
// background functions `cielo` and `fondo` and minus what the sheet's `dropped` list says is dropped (the sky, the
// background, the light of the hour and W.osc over everything, which the set bakes; the frog's dotted shadow); every
// screen position replaced by what the sheet's `code` list gives for its line (patio_places.dart), and the places the
// sheet's `moves` list moves, each at its line. patio.js is written on the kit, so this is an `Escena`; its set is
// [PatioSet].
//
// What El patio's sheet has that the earlier ones did not, and how it is kept here (as patio-preview.html keeps it):
// - `behind`: the sun, the moon and the stars are drawn first, then the set's own pixels again wherever the set has
//   drawn anything, the leaves of this frame included ([Patio.behind], patio-preview.html `PREVIEW.behind`).
// - `flowerLeaves`: every flower planted in a bed's hole is drawn with its own clump of leaves immediately before it
//   ([Patio.flowerLeaves], the sheet's `moves` at line 135), not dimmed.
// - `moves`: thirteen pieces of patio.js's source and their replacements, each applied at its line (a comment says so):
//   the sun's highest row, the sixth star, the frog's two places at the gate (so 8 pairs of places take one hop more:
//   the sheet's `hops`; the kit counts the hops from the places, as it always did), abuela in the door, the walks to
//   the door and to the gate, the people the three stories start with, and where the answer cards stand in story 11.
// - `talk`: where a bubble goes ([Patio.talkPlace], patio-preview.html `PREVIEW.talk`).
// - `shadows`: the ball's shadow on the lawn, besides the frog's and the people's.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_scenes/src/patio/patio_places.dart';
import 'package:coqui_scenes/src/patio/patio_set.dart'
    show CX, CY, PatioSet, PatioState, patioEngine;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "patio", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`), drawing its
/// random numbers from [rng], the game's one random source.
Scene createPatio({Rng? rng}) => Patio(sheetOf('patio'), rng: rng);

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
num _dir(Map<String, dynamic> p) => p['dir'] is num ? p['dir'] as num : 0;

List<Map<String, dynamic>> _ms(Object? l) => l == null
    ? <Map<String, dynamic>>[]
    : (l as List).cast<Map<String, dynamic>>();

const int _white = 0xFFFFFFFF;

// patio.js: CAMA (the sheet's code line 16: the beds; the set paints each at the old ellipse, hoyo() unchanged: the
// holes are the sheet's points hoyos.L, hoyos.R, which the scene's tests hold to these)
const Map<String, List<int>> CAMA = {
  'L': [40, 176, 56, 20],
  'R': [144, 176, 56, 20],
};

// patio.js: FLOR
final List<int> FLOR = [
  hexColour('#FF8FB8'),
  hexColour('#FFE070'),
  hexColour('#F4584A'),
  hexColour('#FFFFFF'),
  hexColour('#C890E8'),
];

// patio.js: CIELO[4][1], the night sky the moon's dark part takes
final int _cielo41 = hexColour('#10163E');

final int _star = hexColour('#FFF4B0'),
    _moon = hexColour('#FFFBEA'),
    _pit = hexColour('#2A1408'),
    _eye = hexColour('#20140A'),
    _eyeBlue = hexColour('#2E6CD0'),
    _ray = hexColour('#F8C838'),
    _trail = hexColour('#9494A6'),
    _hop = hexColour('#2E9A48'),
    _ground = hexColour('#C8C8D4'),
    _dust = hexColour('#E8E0C8'),
    _fly0 = hexColour('#5A6A30'),
    _fly1 = hexColour('#F4FF9A'),
    _fly2 = hexColour('#C8D870'),
    _vasoTop = hexColour('#E8F4FF'),
    _sponge = hexColour('#F2D08A'),
    _frost = hexColour('#FF8FB8'),
    _icing = hexColour('#FFFDF4'),
    _maceta = hexColour('#FFE070'),
    _cardSky = hexColour('#BFE0F0'),
    _sunDown = hexColour('#F47A3C'),
    _sunUp = hexColour('#F8C838'),
    _sunPast = hexColour('#DCEEFF'),
    _luzOn = hexColour('#F8E040'),
    _luzGone = hexColour('#9494A6'),
    _luzGoneX = hexColour('#B8B8C8'),
    _luzOff = hexColour('#6E6E80'),
    _luzOffIn = hexColour('#D8E890');

// patio.js sol: its three colours at sunset (n >= 3), late afternoon (n === 2) and by day
final List<int> _sun3 = [
      hexColour('#E8502C'),
      hexColour('#F47A3C'),
      hexColour('#FFA050'),
    ],
    _sun2 = [hexColour('#F09A28'), hexColour('#F8B838'), hexColour('#FFD860')],
    _sun0 = [hexColour('#F8C838'), hexColour('#FFE070'), hexColour('#FFF4B0')];

// "rgba(240,255,120,.28)" and ".16": a firefly's glow (.28 and .16 of 255, rounded: 71, 41)
const int _glowHi = 0x4778FFF0, _glowLo = 0x2978FFF0;
// "rgba(248,224,64,.4)": a firefly the frog has, on the card (.4 of 255: 102)
const int _luzHalo = 0x6640E0F8;

// patio.js: mkCaja
Sprite mkCaja() {
  final b = Buf(32, 24), Wd = RP.wood;
  b.rect(1, 12, 30, 11, Wd[3]);
  for (var x = 1; x < 31; x += 6) {
    b.rect(x, 12, 1, 11, Wd[1]);
  }
  b.rect(1, 12, 30, 1, Wd[4]);
  b.rect(1, 17, 30, 1, Wd[2]);
  b.rect(1, 22, 30, 1, Wd[0]);
  for (var i = 0; i < 5; i++) {
    final x = 4 + i * 6;
    b.rect(x, 6, 1, 6, RP.grn[1]);
    b.ell(x + .5, 4, 2.6, 2.6, [FLOR[i % FLOR.length]]);
    b.px(x, 4, RP.orng[2]);
    b.rect(x + 1, 9, 2, 1, RP.grn[3]);
  }
  return b.outline().done();
}

// patio.js: mkSaco
Sprite mkSaco(bool ab) {
  final b = Buf(26, 24), T = RP.tan;
  b.ell(13, 15, 11, 8.5, T.sublist(1));
  b.ell(8, 13, 4, 3, [T[3], T[4]]);
  b.ell(17, 17, 4, 3, [T[2], T[3]]);
  if (ab) {
    b.ell(13, 7, 8, 3.2, [_pit]);
    b.rect(5, 6, 16, 1, T[4]);
  } else {
    b.rect(10, 3, 6, 5, T[2]);
    b.rect(9, 6, 8, 1, RP.red[2]);
    b.rect(8, 1, 10, 3, T[3]);
  }
  return b.outline().done();
}

// patio.js: mkCanasta
Sprite mkCanasta() {
  final b = Buf(18, 17), T = RP.orng;
  for (var a = 0; a <= 24; a++) {
    final t = math.pi * a / 24;
    b.px(9 - 7 * math.cos(t), 7 - 6 * math.sin(t), T[1]);
    b.px(9 - 7 * math.cos(t), 8 - 6 * math.sin(t), T[1]);
  }
  b.rect(2, 8, 14, 8, T[2]);
  for (var y = 8; y < 16; y += 2) {
    for (var x = 2; x < 16; x += 2) {
      b.px(x + (y >> 1) % 2, y, T[0]);
    }
  }
  b.rect(1, 7, 16, 2, T[3]);
  return b.outline().done();
}

// patio.js: mkCosa
// the small things of this place, one drawing each: flor, vaso, silla, bizcocho, bola, maceta
Sprite mkCosa(String k) {
  final b = Buf(14, 14), Wd = RP.wood;
  if (k == 'flor') {
    b.rect(6, 6, 1, 8, RP.grn[1]);
    b.rect(3, 9, 3, 2, RP.grn[3]);
    b.rect(7, 10, 3, 2, RP.grn[3]);
    b.ell(6.5, 4, 4, 4, [_frost]);
    b.ell(6.5, 4, 1.6, 1.6, [RP.yel[2]]);
  } else if (k == 'vaso') {
    for (var y = 3; y < 13; y++) {
      final i = y >= 10 ? 1 : 0;
      b.rect(3 + i, y, 8 - 2 * i, 1, y >= 6 ? RP.orng[3] : _vasoTop);
    }
    b.rect(3, 6, 8, 1, RP.orng[4]);
    b.rect(4, 3, 1, 9, _white);
    b.rect(3, 2, 8, 1, _white);
    b.rect(8, 0, 1, 8, RP.red[2]);
    b.px(9, 0, RP.red[2]);
  } else if (k == 'silla') {
    b.rect(3, 1, 2, 12, Wd[2]);
    b.rect(3, 2, 7, 1, Wd[3]);
    b.rect(3, 4, 7, 1, Wd[3]);
    b.rect(9, 1, 1, 6, Wd[2]);
    b.rect(3, 7, 9, 2, Wd[3]);
    b.rect(10, 9, 2, 4, Wd[2]);
  } else if (k == 'bizcocho') {
    b.rect(1, 12, 12, 1, _white);
    b.rect(2, 7, 10, 5, _sponge);
    b.rect(2, 5, 10, 3, _frost);
    b.rect(2, 9, 10, 1, _icing);
    b.rect(6, 3, 2, 2, RP.red[2]);
    b.px(4, 8, _frost);
    b.px(9, 8, _frost);
  } else if (k == 'bola') {
    b.ell(7, 7.5, 5.5, 5.5, RP.red.sublist(1));
    b.rect(2, 7, 10, 2, _white);
  } else {
    b.rect(4, 9, 6, 1, RP.orng[3]);
    b.rect(5, 10, 4, 3, RP.orng[1]);
    b.rect(6, 5, 1, 4, RP.grn[1]);
    b.ell(6.5, 3, 3, 3, [_maceta]);
    b.px(6, 3, RP.orng[2]);
    b.rect(8, 6, 2, 1, RP.grn[3]);
  }
  return b.outline().done();
}

// patio.js: hoyo
List<int> hoyo(String k, int i) => [
  k == 'L' ? CAMA['L']![0] + 8 + i * 10 : CAMA['R']![0] + 48 - i * 10,
  CAMA[k]![1] + 10,
];

// patio.js: tarjeta
void tarjeta(Ctx g, num x, num y, num w, num h) {
  g.fillStyle = OUT;
  g.fillRect(x - 1, y, w + 2, h);
  g.fillRect(x, y - 1, w, h + 2);
  g.fillStyle = _icing;
  g.fillRect(x, y, w, h);
}

/// The scene "El patio" (patio.js: `KIT.escena({id:"patio", ...})`). Its set is [PatioSet]; this is the sprite layer and
/// what can happen here.
class Patio extends Escena implements SetScene, SetOverSprites {
  /// [rng] is the game's one random source (patio.js `azar`: `Math.random()`): the story runner's. A scene made without
  /// it (a picture, a test of its sprites) draws no random number.
  Patio(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = PatioPlaces(sheet, patioEngine());
    final p = _p;
    // patio.js:16 SOLX, SOLY (sheet: points sol, its x and heights; moves line 16: SOLY=[24,...] -> SOLY=[26,...])
    final sol = sheet.screenPoint('sol');
    SOLX = sol.x;
    SOLY = sol.heights!;
    // patio.js:58 ESTRELLAS (sheet: points estrellas; moves line 58: the sixth, [112,58] -> [100,44])
    ESTRELLAS = p.pts('estrellas');
    // patio.js:85, :86 LUGAR (sheet: lugar, the frog's spots frog.*; moves line 86: porton [128,104] -> [126,86], sale
    // [134,84] -> [130,68], so 8 pairs take one hop more: sheet hops)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // patio.js:87 DETRAS, ESPERA, LADOS (sheet: spots detras.*, espera.*, lados.*)
    DETRAS = {'L': p.spot('detras.L'), 'R': p.spot('detras.R')};
    ESPERA = {'luis': p.spot('espera.luis'), 'carmen': p.spot('espera.carmen')};
    LADOS = [p.spot('lados.0'), p.spot('lados.1')];
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _luna = p.pt('luna');
    _caja = p.pt('caja');
    _nido = p.anchorScreen('nido');
    _cercaAve = p.pt('cerca.ave');
    _talk = sheet.talk!;
    // patio.js:91 COSAS (sheet: code lines 93 to 95, things.<id>.box; the gate's hand point: things.porton.hand)
    cosas = [
      for (final id in const [
        'luis',
        'carmen',
        'bebe',
        'abuela',
        'abuelo',
        'mama',
        'papa',
      ])
        persona(id),
      Thing(
        id: 'bola',
        si: (w) => jsTruthy(w['bola']),
        box: (Map<String, dynamic> w) {
          final b = w['bola'] as Map<String, dynamic>;
          return [
            _round(b['x'] as num) - 7,
            _round(b['y'] as num) - 13,
            14,
            14,
          ];
        },
        m: 2,
      ),
      Thing(
        id: 'saco',
        si: (w) => jsTruthy(w['saco']),
        box: (Map<String, dynamic> w) {
          final s = w['saco'] as Map<String, dynamic>;
          return [
            _round(s['x'] as num) - 13,
            _round(s['y'] as num) - 23,
            26,
            24,
          ];
        },
        m: 1,
      ),
      Thing(
        id: 'caja',
        si: (w) => jsTruthy(w['caja']),
        box: p.box('caja'),
        m: 0,
      ),
      Thing(id: 'camaL', box: p.box('camaL'), m: 2),
      Thing(id: 'camaR', box: p.box('camaR'), m: 2),
      Thing(
        id: 'sol',
        si: (w) => !jsTruthy(w['noche']) && (w['soly'] as num) < 80,
        box: (Map<String, dynamic> w) => [
          SOLX - 14,
          _round(w['soly'] as num) - 14,
          28,
          28,
        ],
        m: 3,
      ),
      Thing(id: 'porton', box: p.box('porton'), hand: p.hand('porton'), m: 1),
      Thing(id: 'nido', box: p.box('nido'), m: 1),
      Thing(id: 'arbol', box: p.box('arbol'), m: 0),
      Thing(
        id: 'pajaro',
        si: (w) =>
            jsTruthy(w['ave']) &&
            (w['ave'] as Map<String, dynamic>)['mode'] != 'none',
        box: (Map<String, dynamic> w) {
          final pp = avePos(w['ave'] as Map<String, dynamic>);
          return [pp[0] - 10, pp[1] - 20, 20, 22];
        },
        m: 0,
      ),
      Thing(id: 'puerta', box: p.box('puerta'), m: 0),
      Thing(id: 'casa', box: p.box('casa'), m: 0),
      Thing(id: 'cerca', box: p.box('cerca'), m: 0),
      Thing(id: 'patio', box: p.box('patio'), m: 0),
    ];
  }

  @override
  final Sheet sheet;

  late final PatioPlaces _p;
  final Rng? _rngGiven;

  @override
  String get id => 'patio';

  @override
  PpEngine newEngine({bool still = false}) => patioEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the host: the bubble patio.js adds when it loads (`Object.assign(BUBL, {q: ["q"]})`) goes into the game's table when
  // the scene is given its host
  SceneHost? _host;
  @override
  SceneHost get host => _host!;
  @override
  set host(SceneHost h) {
    _host = h;
    // patio.js:115
    h.BUBL.addAll(const {
      'q': ['q'],
    });
  }

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  Map<String, dynamic> get V => host.V;
  Map<String, dynamic> get S => host.S;
  Sfx get SFX => host.SFX;
  Future<void> wait(num ms) => host.wait(ms);
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      host.frogBox(q);

  /* ---------- the set ---------- */

  // the sheet's setKey table, from W (setKey.params.*.fromW), as patio-preview.html's setOf reads it: hora = W.noche ?
  // noche : n = min(3, W.sol || 0): n < 3 ? [dia, tarde, tarde2][n] : (W.osc >= .25 ? crepusculo : ocaso); door =
  // W.pdoor ? open : shut; gate = W.porton ? open : shut
  @override
  String setKey(Map<String, dynamic> W) {
    final n = math.min(3, _n(W['sol']));
    final hora = jsTruthy(W['noche'])
        ? 'noche'
        : n < 3
        ? const ['dia', 'tarde', 'tarde2'][n.toInt()]
        : _n(W['osc']) >= .25
        ? 'crepusculo'
        : 'ocaso';
    return PatioState(
      hora: hora,
      door: jsTruthy(W['pdoor']) ? 'open' : 'shut',
      gate: jsTruthy(W['porton']) ? 'open' : 'shut',
    ).key;
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      PatioSet(e, b, PatioState.fromKey(key)).buildSet();

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  // the sheet's shadows, as patio-preview.html casts them: the frog (W.cq.vis, not .5 or less faded) at .3 with his
  // radius, from the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25)); everyone visible, not
  // .5 or less faded and not in someone's arms (z), from the ground point under their feet on screen (unproject(round(x),
  // round(y) - 1)): the baby at .2, one sitting on the grass at .3, the others at .3, .65, 1, 1.35, 1.7, each with the
  // radius of their kind; the ball (W.bola) at .05 with its radius, from the ground point under it on screen, when that
  // point is on the lawn (x > CX, y > CY: not in the tree)
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
      if (p == null ||
          p['vis'] == 0 ||
          _atMostHalf(p['al']) ||
          jsTruthy(p['z'])) {
        continue;
      }
      final id = en.key;
      final r = id == 'bebe'
          ? radii['bebe']!
          : (id == 'luis' || id == 'carmen')
          ? radii['nino']!
          : radii['grown']!;
      final zs = id == 'bebe'
          ? const [.2]
          : jsTruthy(p['sent'])
          ? const [.3]
          : const [.3, .65, 1.0, 1.35, 1.7];
      final g = e.unproject(_round(p['x'] as num), _round(p['y'] as num) - 1);
      for (final z in zs) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    final bola = W['bola'];
    if (jsTruthy(bola)) {
      final b = bola as Map<String, dynamic>,
          g = e.unproject(_round(b['x'] as num), _round(b['y'] as num) - 1);
      if (g.x > CX + .05 && g.y > CY + .05) {
        out.add((x: g.x, y: g.y, z: .05, r: sh['bola']!.radius));
      }
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  /* ---------- the sky objects behind the set: the sheet's behind ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;

  // the set as this frame shows it (wind, shadows) and its depth with this frame's leaves (patio-preview.html:
  // `DEPTH.live()`), before the sprite layer (drawFrame's step 4)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = Float32List.fromList(engine.zb);
  }

  // patio-preview.html: PREVIEW.behind (sheet: behind). What the sprite layer has drawn so far (the stars, the moon, the
  // sun) is behind the set: the set's own pixels go back over it wherever the set has drawn anything (its depth this
  // frame over -1e8: everything but the sky, the hills and the leaves of this frame included). A frame drawn with no
  // set (a player with no screen) has none to draw again.
  void behind() {
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null || sheet.behind == null) return;
    final pix = e.pix;
    for (var i = 0; i < pix.length; i++) {
      if (Z[i] > -1e8) pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  /* ---------- where things are ---------- */

  // patio.js: SOLX, SOLY, ESTRELLAS, LUGAR, DETRAS, ESPERA, LADOS (sheet: points sol, estrellas; lugar; spots)
  late final double SOLX;
  late final List<double> SOLY;
  late final List<List<double>> ESTRELLAS;
  late final Map<String, List<num>> LUGAR;
  late final Map<String, List<int>> DETRAS, ESPERA;
  late final List<List<int>> LADOS;

  // the moon (points luna: code line 131), the crate (points caja: line 136), the bird on its nest (points nido: lines
  // 250, 252, 284, 330) and on the fence (points cerca.ave: line 291)
  late final List<double> _luna, _caja, _nido, _cercaAve;

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

  // patio.js: QUIEN
  static final Map<String, Who> QUIEN = {
    'luis': FAM['hermano']!,
    'carmen': FAM['hermana']!,
    'mama': FAM['mama']!,
    'papa': FAM['papa']!,
    'abuelo': FAM['abuelo']!,
  };

  // patio.js: alto
  int alto(String id) {
    if (id == 'abuela') return 51;
    if (id == 'bebe') return 28;
    final p = G(id), sent = p != null && jsTruthy(p['sent']);
    if (QUIEN[id]!.nino) return sent ? 40 : 44;
    return sent ? 49 : 56;
  }

  // patio.js: caja
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

  // patio.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // patio.js: COSAS
  @override
  late final List<Thing> cosas;

  // patio.js: fresh
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'gente': <String, dynamic>{},
    'flores': <String, dynamic>{'L': <dynamic>[], 'R': <dynamic>[]},
    'sol': 0,
    'soly': SOLY[0],
    'osc': 0,
    'noche': 0,
    'luna': 0,
    'estrella': 0,
    'porton': 0,
    'pdoor': 0,
    'caja': 0,
    'bola': null,
    'saco': null,
    'canasta': null,
    'nido': <dynamic>[],
    'tanteo': 0,
    'tarjeta': null,
    'muestra': null,
    'luces': <dynamic>[],
    'brillo': 0,
    'aro': 0,
    'mari': <dynamic>[],
    'lleva': null,
    'vuela': null,
    'polvo': null,
    'rizo': null,
    'brilla': 0,
    // the bird on its nest (sheet: points nido, code line 330)
    'ave': <String, dynamic>{
      'mode': 'sit',
      'x': _nido[0],
      'y': _nido[1],
      'dir': -1,
      'st': 'n',
    },
    'cq': <String, dynamic>{
      'x': LUGAR['centro']![0],
      'y': LUGAR['centro']![1],
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
  };

  /* ---------- the picture ---------- */

  // patio.js: sol
  void sol(Ctx c, num x, num y, num n, bool brilla) {
    final col = n >= 3
            ? _sun3
            : n == 2
            ? _sun2
            : _sun0,
        r = 11,
        ray = brilla
            ? 10
            : (F >> 3) % 2 != 0
            ? 5
            : 4;
    for (var k = 0; k < 8; k++) {
      final an = k * math.pi / 4 + ((F >> 3) % 2 != 0 ? 0 : .39),
          x1 = x + math.cos(an) * (r + 3),
          y1 = y + math.sin(an) * (r + 3);
      for (var i = 0; i < ray; i++) {
        fr(
          c,
          _round(x1 + math.cos(an) * i) - 1,
          _round(y1 + math.sin(an) * i) - 1,
          2,
          2,
          col[1],
        );
      }
    }
    c.fillStyle = OUT;
    c.beginPath();
    c.arc(x, y, r + 1, 0, 7);
    c.fill();
    c.fillStyle = col[1];
    c.beginPath();
    c.arc(x, y, r, 0, 7);
    c.fill();
    c.fillStyle = col[2];
    c.beginPath();
    c.arc(x - 2, y - 2, r - 4, 0, 7);
    c.fill();
  }

  // patio.js: luna
  void luna(Ctx c, num x, num y) {
    c.fillStyle = _moon;
    c.beginPath();
    c.arc(x, y, 9, 0, 7);
    c.fill();
    c.fillStyle = _cielo41;
    c.beginPath();
    c.arc(x + 4, y - 2, 8, 0, 7);
    c.fill();
  }

  // patio.js: cosa (renamed: the kit's `cosa` is the lookup of a thing by its key)
  void pintaCosa(Ctx g, String k, num x, num y, [num? s0]) {
    final s = s0 == null || s0 == 0 ? 1 : s0;
    final im = host.lib.spr('cosa$k', () => mkCosa(k));
    g.smoothing = false;
    g.drawImage(
      im,
      _round(x - 7 * s),
      _round(y - 14 * s),
      _round(14 * s),
      _round(14 * s),
    );
  }

  // patio.js: florEn
  // a flower in a bed: open, or a bud that stays shut
  void florEn(Ctx g, num x, num y, Map<String, dynamic> f) {
    if (!jsTruthy(f['k'])) {
      fr(g, x, y - 5, 1, 6, RP.grn[1]);
      fr(g, x - 2, y - 10, 5, 6, OUT);
      fr(g, x - 1, y - 9, 3, 4, RP.grn[3]);
      fr(g, x, y - 10, 1, 1, RP.grn[4]);
      return;
    }
    final col = FLOR[(f['c'] as num).toInt() % FLOR.length];
    fr(g, x, y - 9, 1, 10, RP.grn[1]);
    fr(g, x - 3, y - 4, 3, 2, RP.grn[3]);
    fr(g, x + 1, y - 6, 3, 2, RP.grn[3]);
    fr(g, x - 3, y - 18, 7, 9, OUT);
    fr(g, x - 4, y - 17, 9, 7, OUT);
    fr(g, x - 2, y - 17, 5, 7, col);
    fr(g, x - 3, y - 16, 7, 5, col);
    fr(g, x - 1, y - 15, 3, 3, col == FLOR[1] ? RP.orng[2] : RP.yel[2]);
  }

  // patio-preview.html: flowerLeaves (sheet: flowerLeaves; moves line 135). A flower in the ground comes with its own
  // clump of leaves, drawn first, at its foot, by its stage (open: f.k; else the bud), 1:1, not dimmed: pixel
  // (x + x0 + col, y + y0 + row) of rows[row][col] is the palette's colour of that letter, "." none
  void flowerLeaves(Ctx g, num x, num y, Map<String, dynamic> f) {
    final L = sheet.flowerLeaves!,
        st = L.stage(jsTruthy(f['k']) ? 'open' : 'bud');
    for (var j = 0; j < st.rows.length; j++) {
      final r = st.rows[j];
      for (var c = 0; c < r.length; c++) {
        final ch = r[c];
        if (ch == '.') continue;
        g.fillStyle = L.palette[ch]!;
        g.fillRect(x + st.x0 + c, y + st.y0 + j, 1, 1);
      }
    }
  }

  /* ---------- drawing ---------- */

  // patio.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        h = alto(id),
        d = _dir(p) < 0 ? -1 : 1;
    c.globalAlpha = p['al'] == null ? 1 : (p['al'] as num).toDouble();
    if (id == 'bebe') {
      final e = jsTruthy(p['est']) ? p['est'] as String : 'idle';
      c.drawImage(
        host.lib.spr('bb$e${a % 2}', () => mkBebe(e, a % 2 != 0)),
        x - 13,
        y - 28,
      );
    } else if (id == 'abuela') {
      final pose = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      c.save();
      c.translate(x.toDouble(), (y - 50).toDouble());
      if (d < 0) c.scale(-1, 1);
      c.drawImage(
        host.lib.spr('ab$pose$habla', () => mkAbuela(pose, habla != 0)),
        -30,
        0,
      );
      c.restore();
    } else {
      final pose = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : p['pose'] == 'alto'
          ? 'wave0'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      final sent = jsTruthy(p['sent']);
      final im = host.lib.spr(
        'pp$id$pose$habla${sent ? 1 : 0}',
        () => mkPersona(QUIEN[id]!, pose, habla != 0, sent),
      );
      c.save();
      c.translate(
        x.toDouble(),
        (y - im.h + 1 + (jsTruthy(p['rie']) && a % 2 != 0 ? -1 : 0)).toDouble(),
      );
      if (d < 0) c.scale(-1, 1);
      c.drawImage(im, -PX, 0);
      c.restore();
      // a flower in her hair
      if (jsTruthy(p['pelo'])) {
        fr(c, x + 3, y - h + 2, 6, 6, OUT);
        fr(c, x + 4, y - h + 3, 4, 4, _frost);
        fr(c, x + 5, y - h + 4, 2, 2, RP.yel[2]);
      }
    }
    if (jsTruthy(p['lleva'])) {
      final k = p['lleva'] as String;
      if (p['pose'] == 'alto') {
        pintaCosa(c, k, x + d * 14, y - h + 13, 2);
      } else if (p['pose'] == 'offer') {
        pintaCosa(c, k, x - d * 20, y - h + 30, 1.4);
      } else {
        pintaCosa(c, k, x, y - h + (jsTruthy(p['sent']) ? 34 : 38), 1.4);
      }
    }
    if (jsTruthy(p['encima'])) {
      pintaCosa(c, p['encima'] as String, x, y - h + 3, 1.4);
    }
    c.globalAlpha = 1;
  }

  // patio.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0,
        dy = _round(q['dy'] as num);
    // patio.js:108, the dotted shadow, is dropped (sheet: shadows.dropped): the engine casts his
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      host.lib.spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    if (jsTruthy(q['ojos'])) {
      // eyes wide: he is looking
      for (final u in const [.3, .7]) {
        final ex = b.x + b.w * u, ey = b.y + dy + 7 * s, r = 4.5 * s;
        g.fillStyle = OUT;
        g.beginPath();
        g.arc(ex, ey, r + 1, 0, 7);
        g.fill();
        g.fillStyle = _white;
        g.beginPath();
        g.arc(ex, ey, r, 0, 7);
        g.fill();
        g.fillStyle = _eye;
        g.beginPath();
        g.arc(
          ex + _n(q['ojx']) * 1.6 * s,
          ey + (q['ojy'] == null ? -1 : q['ojy'] as num) * 1.6 * s,
          r * .5,
          0,
          7,
        );
        g.fill();
      }
    }
    g.globalAlpha = 1;
    if (jsTruthy(W['lleva'])) {
      pintaCosa(
        g,
        W['lleva'] as String,
        b.x + (b.w.toInt() >> 1),
        b.y + dy + 1,
        1.4,
      );
    }
    if (jsTruthy(W['canasta'])) {
      g.drawImage(
        host.lib.spr('canasta', mkCanasta),
        b.x + b.w - 6,
        b.y + b.h - 17,
      );
    }
  }

  // patio.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // patio.js: luzPos
  // a firefly: where it is. en = with someone (Carmen's finger, abuelo's napkin, or the middle of the yard); con = flying
  // beside the frog.
  List<num> luzPos(Map<String, dynamic> l, int i) {
    final Gm = (W['gente'] as Map<String, dynamic>?) ?? const {},
        q = W['cq'] as Map<String, dynamic>,
        b = frogBox(q);
    if (l['est'] == 'en') {
      if (l['id'] == 'carmen' && Gm['carmen'] != null) {
        final p = Gm['carmen'] as Map<String, dynamic>,
            d = _dir(p) < 0 ? -1 : 1;
        return [(p['x'] as num) + d * 13, (p['y'] as num) - alto('carmen') + 4];
      }
      if (l['id'] == 'abuelo' && Gm['abuelo'] != null) {
        final p = Gm['abuelo'] as Map<String, dynamic>;
        return [
          (p['x'] as num) +
              (p['pose'] == 'offer' ? -(_dir(p) < 0 ? -1 : 1) * 20 : 0),
          (p['y'] as num) - alto('abuelo') + 14,
        ];
      }
      // (a firefly with no x0 or y0 is at NaN, as in JavaScript: it is not drawn)
      final x0 = l['x0'] is num ? l['x0'] as num : double.nan,
          y0 = l['y0'] is num ? l['y0'] as num : double.nan;
      return [x0 + 4 * math.sin(F / 9 + i), y0 + 3 * math.cos(F / 7 + i)];
    }
    if (l['est'] == 'con') {
      final an = F / 8 + i * 2.09, rr = jsTruthy(W['aro']) ? 20 : 15;
      return [
        b.x + b.w / 2 + rr * math.cos(an),
        b.y + 4 + (jsTruthy(W['aro']) ? 9 : 6) * math.sin(an) - 4,
      ];
    }
    return [l['x'] as num, l['y'] as num];
  }

  // patio.js: luciernaga
  void luciernaga(Ctx c, num x0, num y0, bool br, Object? al) {
    // JavaScript draws nothing at NaN
    if (x0.isNaN || y0.isNaN) return;
    final x = _round(x0), y = _round(y0);
    c.globalAlpha = al == null ? 1 : (al as num).toDouble();
    if (br) {
      final k = (F >> 2) % 3;
      c.fillStyle = k != 0 ? _glowHi : _glowLo;
      c.beginPath();
      c.arc(x + 1, y + 1, k != 0 ? 7 : 5, 0, 7);
      c.fill();
      fr(c, x - 1, y - 1, 4, 4, _fly1);
      fr(c, x, y, 2, 2, _white);
    } else {
      fr(c, x - 1, y - 1, 4, 4, _fly0);
      fr(c, x, y, 2, 2, (F >> 3) % 2 != 0 ? _fly1 : _fly2);
    }
    c.globalAlpha = 1;
  }

  // patio.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gm = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        n = jsTruthy(W['noche']) ? 4 : math.min(3, _n(W['sol']));
    // patio.js:129 c.drawImage(spr("cielo"+n)) -> the set's sky, for setKey(W) (sheet: dropped)
    // patio.js:130 the stars, behind the set (sheet: behind; points estrellas)
    if (jsTruthy(W['estrella']) || jsTruthy(W['noche'])) {
      final m = jsTruthy(W['noche']) ? 8 : 1;
      for (var i = 0; i < m && i < ESTRELLAS.length; i++) {
        final p = ESTRELLAS[i], t = (F + i * 7) % 24 < 3;
        fr(c, p[0], p[1], t ? 1 : 2, t ? 1 : 2, _white);
        if (!t) {
          fr(c, p[0] - 1, p[1], 4, 1, _star);
          fr(c, p[0], p[1] - 1, 1, 4, _star);
        }
      }
    }
    // patio.js:131 the moon (points luna) or the sun (points sol: SOLX), behind the set (sheet: behind)
    if (jsTruthy(W['luna'])) {
      luna(c, _luna[0], _luna[1]);
    } else if ((W['soly'] as num) < 110) {
      sol(
        c,
        SOLX,
        _round(W['soly'] as num),
        n,
        jsTruthy(W['brilla']) && F - (W['brilla'] as num) < 10,
      );
    }
    // patio.js:132 c.drawImage(spr("patio"...), fondo()) -> the set, for setKey(W) (sheet: dropped); then the set's own
    // pixels again over the sky objects (sheet: behind)
    behind();
    final L = <PatioItem>[
      for (final id in Gm.keys)
        if (Gm[id] != null && (Gm[id] as Map)['vis'] != 0)
          PatioItem(
            jsTruthy((Gm[id] as Map)['z'])
                ? (Gm[id] as Map)['z'] as num
                : (Gm[id] as Map)['y'] as num,
            () => gente(c, id, a),
          ),
    ];
    final flores = (W['flores'] as Map<String, dynamic>?) ?? const {};
    for (final k in CAMA.keys) {
      final fl = _ms(flores[k]);
      // sheet moves line 135: `const h=hoyo(k,i);florEn(c,h[0],h[1],f);` ->
      // `const h=hoyo(k,i);flowerLeaves(c,h[0],h[1],f);florEn(c,h[0],h[1],f);` (sheet: flowerLeaves)
      L.add(
        PatioItem(CAMA[k]![1] + 12, () {
          for (var i = 0; i < fl.length; i++) {
            final h = hoyo(k, i);
            flowerLeaves(c, h[0], h[1], fl[i]);
            florEn(c, h[0], h[1], fl[i]);
          }
        }),
      );
    }
    // the crate (points caja: code line 136)
    if (jsTruthy(W['caja'])) {
      L.add(
        PatioItem(
          136,
          () => c.drawImage(host.lib.spr('caja', mkCaja), _caja[0], _caja[1]),
        ),
      );
    }
    if (jsTruthy(W['saco'])) {
      final s = W['saco'] as Map<String, dynamic>;
      L.add(
        PatioItem(
          (s['y'] as num) + 1,
          () => c.drawImage(
            host.lib.spr(
              'saco${jsTruthy(s['ab']) ? 1 : 0}',
              () => mkSaco(jsTruthy(s['ab'])),
            ),
            _round(s['x'] as num) - 13,
            _round(s['y'] as num) - 23,
          ),
        ),
      );
    }
    if (jsTruthy(W['bola'])) {
      final bo = W['bola'] as Map<String, dynamic>;
      L.add(
        PatioItem(
          bo['y'] as num,
          () => pintaCosa(
            c,
            'bola',
            bo['x'] as num,
            (bo['y'] as num) - _n(bo['h']),
            1,
          ),
        ),
      );
    }
    if (jsTruthy(q['vis'])) {
      L.add(PatioItem((q['y'] as num) + 27, () => rana(c, q, a)));
    }
    // JavaScript's sort is stable: the index breaks a tie
    final byRow = [...L.indexed]
      ..sort((m, n) {
        final d = m.$2.y.compareTo(n.$2.y);
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    for (final o in byRow) {
      o.$2.d();
    }
    // dust and speed lines behind a hop
    if (jsTruthy(W['polvo'])) {
      final p = W['polvo'] as Map<String, dynamic>,
          dir = p['dir'] as num,
          px = p['x'] as num,
          py = p['y'] as num;
      for (var i = 0; i < 3; i++) {
        fr(c, px + dir * (4 + i * 6) - 2, py - 2 - i % 2 * 3, 4, 3, _white);
        fr(c, px + dir * (4 + i * 6) - 1, py - 1 - i % 2 * 3, 3, 2, _dust);
      }
      for (var i = 0; i < 3; i++) {
        fr(c, px + dir * 8, py - 12 - i * 5, 9, 1, _white);
      }
    }
    // the loop the bird has just flown
    if (jsTruthy(W['rizo'])) {
      final z = W['rizo'] as Map<String, dynamic>;
      if (z['f'] == null || F - (z['f'] as num) < 36) {
        c.strokeStyle = _white;
        c.lineWidth = 1;
        c.setLineDash([2, 3]);
        c.beginPath();
        c.arc(
          z['x'] as num,
          z['y'] as num,
          jsTruthy(z['r']) ? z['r'] as num : 12,
          0,
          7,
        );
        c.stroke();
        c.setLineDash([]);
      }
    }
    if (jsTruthy(W['ave']) &&
        (W['ave'] as Map<String, dynamic>)['mode'] != 'none') {
      final ave = W['ave'] as Map<String, dynamic>;
      drawAve(c, ave);
      if (jsTruthy(ave['lleva'])) {
        final p = avePos(ave);
        pintaCosa(
          c,
          ave['lleva'] as String,
          p[0] + (jsTruthy(ave['dir']) ? ave['dir'] as num : 1) * 9,
          p[1] + 8,
          1,
        );
      }
    }
    final mari = _ms(W['mari']);
    for (var i = 0; i < mari.length; i++) {
      final m = mari[i],
          x = _round((m['x'] as num) + 5 * math.sin(F / 6 + i * 2)),
          y = _round((m['y'] as num) + 3 * math.cos(F / 5 + i)),
          w = (F >> 1) % 2 != 0 ? 4 : 2,
          col = FLOR[(i + 1) % FLOR.length];
      fr(c, x - w - 1, y - 3, w + 2, 7, OUT);
      fr(c, x, y - 3, w + 2, 7, OUT);
      fr(c, x - w, y - 2, w, 5, col);
      fr(c, x + 1, y - 2, w, 5, col);
      fr(c, x, y - 2, 1, 5, OUT);
    }
    if (jsTruthy(W['vuela'])) {
      final v = W['vuela'] as Map<String, dynamic>;
      pintaCosa(
        c,
        v['k'] as String,
        v['x'] as num,
        v['y'] as num,
        jsTruthy(v['s']) ? v['s'] as num : 1,
      );
    }
    // patio.js:147 the light of the hour and :148 W.osc over everything -> baked into the set (sheet: dropped)
    final luces = _ms(W['luces']);
    for (var i = 0; i < luces.length; i++) {
      final l = luces[i];
      if (l['est'] == 'fuera') continue;
      final p = luzPos(l, i);
      luciernaga(
        c,
        p[0],
        p[1],
        jsTruthy(W['brillo']) || l['est'] == 'con',
        l['al'],
      );
    }
    // patio.js:150 a person's bubble, where the sheet's talk puts it
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
    // patio.js:151 the frog's bubble, where the sheet's talk puts it
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = frogBox(q),
          t = talkPlace(
            [
              b.x + (b.w.toInt() >> 1),
              b.y + 2 - (jsTruthy(W['lleva']) ? 18 : 0),
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

  // patio-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
  // head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view, clear
  // of the corner cards shown and of every face (each visible person's and the frog's, its own too); if none is, [top].
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
          T.heads[id +
              (jsTruthy(p['sent']) && id != 'abuela' && id != 'bebe'
                  ? '.sent'
                  : '')]!;
      final flip = _dir(p) < 0 && id != 'bebe',
          x = _round(p['x'] as num),
          y = _round(p['y'] as num);
      final hx = flip ? x - hd.head + (id == 'abuela' ? 0 : 1) : x + hd.head;
      faces.add([_round(hx - 6), y + hd.top + (id == 'bebe' ? 4 : 5), 12, 10]);
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
    num field(String f) => f == 'canasta.length'
        ? ((w['canasta'] as List?) ?? const []).length
        : _n(w[f]);
    if (w['tarjeta'] == 'sol') boards.addAll(T.boardsOf('tarjeta sol', field));
    if (w['tarjeta'] == 'luces') {
      boards.addAll(T.boardsOf('tarjeta luces', field));
    }
    if (jsTruthy(w['tanteo'])) boards.addAll(T.boardsOf('tanteo', field));
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

  // patio.js: talkAt (sheet: code line 153, relative to the person: unchanged)
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

  // patio.js: respIcon
  // the two doing bubbles: ir = the frog in the middle of a hop; ver = his two big eyes
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    if (k == 'ir') {
      final up = a % 2 != 0 ? 1 : 0;
      fr(g, x + 4, y + 32, 32, 1, _trail);
      for (var i = 0; i <= 12; i++) {
        final t = i / 12,
            px = x + 5 + 30 * t,
            py = y + 31 - 22 * math.sin(math.pi * t);
        if (i % 2 == 0) fr(g, _round(px), _round(py), 2, 2, _hop);
      }
      g.drawImage(
        host.lib.spr('cq.6_0', () => mkCoqui(.6, 0, false)),
        x + 10,
        y + 2 - up,
      );
      fr(g, x + 15, y + 29, 10, 2, _ground);
    } else {
      for (final ex in const [13, 27]) {
        g.fillStyle = OUT;
        g.beginPath();
        g.arc(x + ex, y + 17, 8, 0, 7);
        g.fill();
        g.fillStyle = _white;
        g.beginPath();
        g.arc(x + ex, y + 17, 7, 0, 7);
        g.fill();
        g.fillStyle = _eyeBlue;
        g.beginPath();
        g.arc(x + ex, y + 16 - (a % 2), 4, 0, 7);
        g.fill();
        g.fillStyle = _eye;
        g.beginPath();
        g.arc(x + ex, y + 16 - (a % 2), 2, 0, 7);
        g.fill();
      }
      for (final p in const [
        [4, 6],
        [20, 3],
        [36, 6],
      ]) {
        fr(g, x + p[0], y + p[1], 1, 4, _ray);
      }
    }
    return null;
  }

  /* ---------- what is at stake, in the corner of the screen ---------- */

  // patio.js: hud
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c, DW = host.DW;
    if (W['tarjeta'] == 'sol') {
      // the sun on its way down to the fence
      final k = W['muestra'] != null ? W['muestra'] as num : _n(W['lost']);
      tarjeta(g, 3, 3, 34, 52);
      g.fillStyle = _cardSky;
      g.fillRect(5, 5, 30, 40);
      for (var i = 0; i < 4; i++) {
        final y = 11 + i * 10;
        if (i == k) {
          g.fillStyle = OUT;
          g.beginPath();
          g.arc(20, y, 6, 0, 7);
          g.fill();
          g.fillStyle = i >= 3 ? _sunDown : _sunUp;
          g.beginPath();
          g.arc(20, y, 5, 0, 7);
          g.fill();
        } else {
          g.fillStyle = i < k ? _sunPast : _white;
          g.fillRect(18, y - 1, 4, 3);
        }
      }
      for (var x = 5; x < 35; x += 5) {
        g.fillStyle = RP.wood[2];
        g.fillRect(x, 43, 4, 10);
        g.fillStyle = RP.wood[4];
        g.fillRect(x, 43, 1, 10);
      }
      g.fillStyle = OUT;
      g.fillRect(5, 42, 30, 1);
    }
    if (jsTruthy(W['tanteo'])) {
      final mio = (W['canasta'] as List?) ?? const [],
          suyo = (W['nido'] as List?) ?? const [];
      tarjeta(g, 3, 3, 24 + math.max(3, mio.length) * 15, 26);
      g.drawImage(host.lib.spr('canasta', mkCanasta), 5, 7);
      for (var i = 0; i < mio.length; i++) {
        pintaCosa(g, mio[i] as String, 36 + i * 15, 25, 1);
      }
      const w = 28 + 3 * 15;
      tarjeta(g, DW - w - 3, 3, w, 26);
      g.drawImage(host.lib.spr('kaven0', () => mkAve('n', false)), DW - 24, 8);
      g.fillStyle = RP.wood[1];
      g.fillRect(DW - 27, 22, 22, 4);
      for (var i = 0; i < suyo.length; i++) {
        pintaCosa(g, suyo[i] as String, DW - w + 6 + i * 15, 25, 1);
      }
    }
    if (W['tarjeta'] == 'luces') {
      tarjeta(g, 3, 3, 84, 30);
      g.drawImage(host.lib.spr('cq.7_0', () => mkCoqui(.7, 0, false)), 5, 9);
      final luces = _ms(W['luces']);
      for (var i = 0; i < luces.length && i < 3; i++) {
        final l = luces[i], x = 42 + i * 15, y = 18;
        if (l['est'] == 'con') {
          g.fillStyle = _luzHalo;
          g.beginPath();
          g.arc(x, y, 7, 0, 7);
          g.fill();
          g.fillStyle = OUT;
          g.fillRect(x - 4, y - 4, 8, 8);
          g.fillStyle = _luzOn;
          g.fillRect(x - 3, y - 3, 6, 6);
          g.fillStyle = _white;
          g.fillRect(x - 1, y - 1, 2, 2);
        } else if (l['est'] == 'ido') {
          g.fillStyle = _luzGone;
          g.fillRect(x - 4, y - 4, 8, 8);
          g.fillStyle = _icing;
          g.fillRect(x - 3, y - 3, 6, 6);
          g.fillStyle = _luzGoneX;
          for (var k = -2; k <= 2; k++) {
            g.fillRect(x + k, y + k, 1, 1);
            g.fillRect(x + k, y - k, 1, 1);
          }
        } else {
          g.fillStyle = _luzOff;
          g.fillRect(x - 3, y - 3, 6, 6);
          g.fillStyle = _luzOffIn;
          g.fillRect(x - 2, y - 2, 4, 4);
        }
      }
    }
  }

  /* ---------- what can happen here ---------- */

  // DECISION(order 31b, as El balcón's and La sala's): the scene's random draws come from the game's one Rng, as
  // Math.random was one: the one the registry's factory is given (`createPatio`, from the story runner's `rng`)
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'El patio was made without a random source (Rng) but draws a random number',
      ));

  // patio.js: azar
  bool azar() => _rng.next() < .5;

  // patio.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _round(math.sqrt(dx * dx + dy * dy) / 6));
    p['sent'] = 0;
    if ((x - x0).abs() > 3) p['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n - (i % 2);
      await wait(host.TICK);
    }
    p['x'] = x;
    p['y'] = y;
  }

  // patio.js: vuelaA
  Future<void> vuelaA(
    String k,
    num x0,
    num y0,
    num x1,
    num y1, [
    num? s,
  ]) async {
    final v = <String, dynamic>{
      'k': k,
      'x': x0,
      'y': y0,
      's': s == null || s == 0 ? 1 : s,
    };
    W['vuela'] = v;
    for (var i = 1; i <= 7; i++) {
      v['x'] = x0 + (x1 - x0) * i / 7;
      v['y'] = y0 + (y1 - y0) * i / 7 - math.sin(math.pi * i / 7) * 12;
      await wait(host.TICK);
    }
    W['vuela'] = null;
  }

  // patio.js: ranaXY
  List<num> ranaXY() {
    final b = frogBox(W['cq'] as Map<String, dynamic>);
    return [b.x + (b.w.toInt() >> 1), b.y + 6];
  }

  // patio.js: mira
  void mira(String id) {
    final p = G(id), q = W['cq'] as Map<String, dynamic>;
    if (p != null) {
      p['dir'] = (q['x'] as num) + 16 < (p['x'] as num) ? -1 : 1;
    }
  }

  // patio.js: bolaA
  Future<void> bolaA(num x, num y, [num? n0]) async {
    final b = W['bola'] as Map<String, dynamic>,
        x0 = b['x'] as num,
        y0 = b['y'] as num;
    final n = n0 == null || n0 == 0 ? 6 : n0;
    for (var i = 1; i <= n; i++) {
      b['x'] = x0 + (x - x0) * i / n;
      b['y'] = y0 + (y - y0) * i / n;
      b['h'] = math.sin(math.pi * i / n) * 18;
      await wait(host.TICK);
    }
    b['h'] = 0;
    SFX.blip();
  }

  Map<String, dynamic> get _flores => W['flores'] as Map<String, dynamic>;
  List<dynamic> _fl(String k) => _flores[k] as List<dynamic>;

  // patio.js: cantidad
  int cantidad() => _fl('L').length + _fl('R').length;

  // patio.js: camas
  void camas() {
    final mem = V['mem_flores'];
    final m = (jsTruthy(mem) ? '$mem' : '11111-11111').split('-');
    var n = 0;
    for (final (j, k) in const ['L', 'R'].indexed) {
      final s = j < m.length && m[j].isNotEmpty ? m[j] : '11111';
      _flores[k] = <dynamic>[
        for (final ch in s.substring(0, math.min(5, s.length)).split(''))
          <String, dynamic>{'k': ch == '1' ? 1 : 0, 'c': n++},
      ];
    }
  }

  // patio.js: siembra
  List<int>? siembra(String k, bool ok) {
    final fl = _fl(k);
    if (fl.length >= 5) return null;
    fl.add(<String, dynamic>{'k': ok ? 1 : 0, 'c': cantidad()});
    final h = hoyo(k, fl.length - 1);
    if (ok) {
      SFX.luz();
      host.fx({
        't': 'star',
        'n': 8,
        'pts': [
          [h[0], h[1] - 14],
        ],
      });
    } else {
      SFX.drop();
    }
    return h;
  }

  // patio.js: luzA
  Future<void> luzA(
    Map<String, dynamic> l,
    num x,
    num y, [
    num? n0,
    num? al,
  ]) async {
    final p = luzPos(l, _ms(W['luces']).indexOf(l));
    l['est'] = 'mov';
    l['x'] = p[0];
    l['y'] = p[1];
    final x0 = l['x'] as num, y0 = l['y'] as num;
    final n = n0 == null || n0 == 0 ? 10 : n0;
    for (var i = 1; i <= n; i++) {
      l['x'] = x0 + (x - x0) * i / n;
      l['y'] = y0 + (y - y0) * i / n - math.sin(math.pi * i / n) * 8;
      if (al != null) l['al'] = 1 + (al - 1) * i / n;
      await wait(host.TICK);
    }
  }

  // patio.js: acts.ir (the kit's), as the old acts call it
  Future<void> ir(Object? a) => acts['ir']!({'a': a});

  // DECISION(order 32b): a position an act reads from the story file (`+o.x`, `+o.y`: acts.anda, pon, alcentro) goes
  // through the sheet's remap, as the runner sends a set step's x and y (page 12, section 5: every position a story file
  // holds; the sheet's remap lists these uses, h-patio beats.20 the one that moves)
  List<num> _fromFile(Object? x, Object? y) => remap([_plus(x), _plus(y)]);

  // patio.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'anda': (o) async {
      final L = o['a'] == 'espera'
          ? ESPERA['${o['quien']}']!
          : o['a'] == 'detras'
          ? DETRAS['${o['cama']}']!
          : _fromFile(o['x'], o['y']);
      await mueve('${o['quien']}', L[0], L[1]);
      if (jsTruthy(o['dir'])) {
        G('${o['quien']}')!['dir'] = _plus(o['dir']);
      } else if (jsTruthy(o['a'])) {
        G('${o['quien']}')!['dir'] = 1;
      }
    },
    'burbuja': (o) async {
      if (o['quien'] == 'cq') {
        (W['cq'] as Map<String, dynamic>)['bub'] = o['que'];
        SFX.coqui();
        host.bounce(6);
      } else if (G('${o['quien']}') != null) {
        G('${o['quien']}')!['bub'] = o['que'];
      }
    },
    'calla': (o) async {
      for (final p in (W['gente'] as Map<String, dynamic>).values) {
        if (p != null) (p as Map<String, dynamic>)['bub'] = null;
      }
      (W['cq'] as Map<String, dynamic>)['bub'] = null;
    },
    'pose': (o) async {
      final p = G('${o['quien']}');
      if (p != null) p['pose'] = o['que'];
    },
    'saluda': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      if (o['quien'] == 'bebe') {
        p['est'] = 'clap';
        SFX.pio();
      } else {
        p['pose'] = 'wave';
      }
      await wait(_plusOr(o['ms'], 700));
      if (o['quien'] == 'bebe') {
        p['est'] = 'idle';
      } else {
        p['pose'] = 'idle';
      }
    },
    'rie': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      p['rie'] = 1;
      await wait(_plusOr(o['ms'], 700));
      p['rie'] = 0;
    },
    'ojos': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      q['ojos'] = o['on'] == '0' ? 0 : 1;
      q['ojx'] = _plusOr(o['x'], 0);
      q['ojy'] = o['y'] == null ? -1 : _plus(o['y']);
      if (jsTruthy(q['ojos'])) {
        SFX.blip();
        await wait(350);
      }
    },
    /* ---- story 9: the flowers ---- */
    // sheet moves line 195: carmen:{x:86,y:136} -> carmen:{x:94,y:137} (code line 195: luis, the ball, the floor rule)
    'inicio9': (o) async {
      final lu = _p.floor(195, 160, 128),
          ca = _p.floor(195, 86, 136),
          bo = _p.floor(195, 174, 128);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{'x': lu[0], 'y': lu[1], 'pose': 'idle'},
        'carmen': <String, dynamic>{'x': ca[0], 'y': ca[1], 'pose': 'idle'},
      };
      W['caja'] = 1;
      W['bola'] = <String, dynamic>{'x': bo[0], 'y': bo[1]};
      (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    },
    'sale': (o) async {
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR['puerta']!;
      W['pdoor'] = 1;
      SFX.creak();
      q['x'] = L[0];
      q['y'] = L[1] - 14;
      q['s'] = .7;
      q['vis'] = 1;
      await wait(250);
      await host.hopTo(L[0], L[1], 1, L[2]);
      await ir('inicio');
      W['pdoor'] = 0;
    },
    // Luis kicks the ball up and catches it
    'juega': (o) async {
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'luis')!,
          b = W['bola'] as Map<String, dynamic>;
      b['x'] = (p['x'] as num) + 12;
      b['y'] = p['y'];
      for (var k = 0; k < 2; k++) {
        p['pose'] = 'wave';
        SFX.blip();
        for (var i = 1; i <= 8; i++) {
          b['h'] = math.sin(math.pi * i / 8) * 30;
          await wait(host.TICK);
        }
        b['h'] = 0;
      }
      p['pose'] = 'idle';
    },
    'maceta': (o) async {
      final p = G('${o['quien']}')!;
      p['lleva'] = jsTruthy(o['suelta']) ? null : 'maceta';
      p['pose'] = jsTruthy(o['suelta']) ? 'idle' : 'alto';
      SFX.blip();
      await wait(500);
    },
    'brilla': (o) async {
      W['brilla'] = F;
      SFX.luz();
      await wait(700);
    },
    // the frog takes a pot from the crate to a bed and plants it; open if it is the right bed, a shut bud if not. Then
    // back to the crate.
    'planta': (o) async {
      final cama = '${o['cama']}',
          k = cama.substring(cama.length - 1),
          ok = o['ok'] != '0';
      await ir('caja');
      W['lleva'] = 'maceta';
      SFX.blip();
      await wait(200);
      await ir('cama$k');
      await wait(120);
      W['lleva'] = null;
      siembra(k, ok);
      await wait(450);
      if (ok && jsTruthy(o['mari'])) {
        (W['mari'] as List).add(<String, dynamic>{
          'x': hoyo(k, _fl(k).length - 1)[0],
          'y': CAMA[k]![1] - 14,
        });
      }
      await ir('caja');
    },
    // the sun card shows once what it is for
    'ensena': (o) async {
      W['tarjeta'] = 'sol';
      for (final k in const [0, 1, 2, 3]) {
        W['muestra'] = k;
        if (k != 0) SFX.drop();
        await wait(k != 0 ? 420 : 600);
      }
      await wait(300);
      W['muestra'] = 0;
      SFX.luz();
      await wait(500);
      W['muestra'] = null;
    },
    // the two children left and right of the crate, hands out; which side each is on is drawn fresh
    'lados': (o) async {
      final s = azar() ? 0 : 1;
      await Future.wait([
        mueve('luis', LADOS[s][0], LADOS[s][1]),
        mueve('carmen', LADOS[1 - s][0], LADOS[1 - s][1]),
      ]);
      for (final id in const ['luis', 'carmen']) {
        G(id)!['pose'] = 'ojos';
        G(id)!['dir'] = 1;
      }
    },
    // sheet moves line 208: W.gente.abuela={x:42,y:116,...} -> {x:52,y:108,...} (spot asoma)
    'asoma': (o) async {
      W['pdoor'] = 1;
      SFX.creak();
      final at = _p.spot('asoma');
      (W['gente'] as Map<String, dynamic>)['abuela'] = <String, dynamic>{
        'x': at[0],
        'y': at[1],
        'pose': 'wave',
        'dir': 1,
      };
      await wait(500);
      G('abuela')!['pose'] = 'idle';
    },
    'entra': (o) async {
      if (G('abuela') != null) G('abuela')!['vis'] = 0;
      W['pdoor'] = 0;
    },
    // the frog hands a pot to a child, who plants it in the nearer bed
    'dale': (o) async {
      final who = '${o['a']}',
          p = G(who)!,
          ok = o['ok'] != '0',
          k = (p['x'] as num) < 120 ? 'L' : 'R',
          x0 = p['x'] as num,
          y0 = p['y'] as num,
          f = ranaXY();
      await ir('caja');
      await vuelaA('maceta', f[0], f[1], p['x'] as num, (p['y'] as num) - 24);
      p['lleva'] = 'maceta';
      SFX.blip();
      await wait(250);
      await mueve(who, DETRAS[k]![0], DETRAS[k]![1]);
      p['lleva'] = null;
      siembra(k, ok);
      await wait(350);
      if (ok) {
        p['pose'] = 'wave';
        p['rie'] = 1;
        await wait(600);
        p['rie'] = 0;
      }
      p['pose'] = 'ojos';
      await mueve(who, x0, y0);
      p['dir'] = 1;
    },
    'manos': (o) async {
      for (final id in const ['luis', 'carmen']) {
        if (G(id) != null) G(id)!['pose'] = 'idle';
      }
    },
    // the children plant what is left in the crate; then the yard as the sun left it
    'final9': (o) async {
      final n = _n(W['lost']);
      for (final id in const ['luis', 'carmen']) {
        G(id)!['pose'] = 'idle';
      }
      await Future.wait([
        mueve('carmen', DETRAS['L']![0], DETRAS['L']![1]),
        mueve('luis', DETRAS['R']![0], DETRAS['R']![1]),
      ]);
      for (final k in const ['L', 'R']) {
        while (_fl(k).length < 5) {
          _fl(k).add(<String, dynamic>{'k': 1, 'c': cantidad()});
          SFX.blip();
          await wait(160);
        }
      }
      // the beds as he left them, for the next stories
      String ks(String k) => _ms(_fl(k)).map((f) => _js(f['k'])).join();
      V['flores'] = '${ks('L')}-${ks('R')}';
      await ir('caja');
      await wait(300);
      if (n == 0) {
        // the butterflies over the lawn, the stars (sheet: code line 219, a screen effect: unchanged)
        W['mari'] = <dynamic>[
          for (var i = 0; i < 7; i++)
            <String, dynamic>{
              'x': 48 + i * 24 + (i % 2) * 6,
              'y': 150 + (i % 3) * 8,
            },
        ];
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 36,
          'pts': const [
            [60, 150],
            [180, 150],
            [120, 120],
            [90, 170],
            [150, 170],
          ],
        });
        await wait(1200);
      } else if (n >= 3) {
        // a firefly over the lawn (code line 220: unchanged)
        W['luces'] = <dynamic>[
          <String, dynamic>{'id': 'medio', 'est': 'en', 'x0': 150, 'y0': 150},
        ];
        W['brillo'] = 1;
        SFX.coqui();
        await wait(1200);
      } else {
        SFX.win();
        await wait(900);
      }
    },
    // the ball goes from one to the other, and then to the frog's head (code line 223: the floor rule)
    'pelota': (o) async {
      final l = G('luis')!,
          ca = G('carmen')!,
          b = W['bola'] as Map<String, dynamic>;
      final lu = _p.floor(223, 166, 150), cm = _p.floor(223, 60, 150);
      await Future.wait([
        mueve('luis', lu[0], lu[1]),
        mueve('carmen', cm[0], cm[1]),
      ]);
      l['dir'] = -1;
      ca['dir'] = 1;
      b['x'] = (l['x'] as num) - 12;
      b['y'] = l['y'];
      l['pose'] = 'wave';
      await bolaA((ca['x'] as num) + 12, ca['y'] as num, 7);
      l['pose'] = 'idle';
      ca['pose'] = 'wave';
      await bolaA((l['x'] as num) - 12, l['y'] as num, 7);
      ca['pose'] = 'idle';
    },
    'pelota2': (o) async {
      final l = G('luis')!, f = ranaXY();
      l['pose'] = 'wave';
      await bolaA(f[0], f[1] + 4, 7);
      l['pose'] = 'idle';
      W['bola'] = null;
      W['lleva'] = 'bola';
      for (var k = 0; k < 3; k++) {
        host.bounce(8);
        SFX.blip();
        await wait(380);
      }
    },
    /* ---- Escuchar: picture stories and do-this routines ---- */
    'flores': (o) async {
      camas();
    },
    'pon': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      final at = _fromFile(o['x'], o['y']);
      p['x'] = at[0];
      p['y'] = at[1];
      if (jsTruthy(o['dir'])) p['dir'] = _plus(o['dir']);
    },
    'deja': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      p['lleva'] = null;
      p['pose'] = 'idle';
    },
    'apunta': (o) async {
      final p = G('${o['quien']}')!;
      p['pose'] = jsTruthy(o['no']) ? 'idle' : 'alto';
      await wait(300);
    },
    // Luis kicks the ball so high that it stays up in the tree, by the nest (code line 231: the crown is where it was:
    // unchanged)
    'bolaarbol': (o) async {
      final p = G('luis')!, b = W['bola'] as Map<String, dynamic>;
      b['x'] = (p['x'] as num) + 12;
      b['y'] = p['y'];
      p['pose'] = 'wave';
      SFX.blip();
      final x0 = b['x'] as num, y0 = b['y'] as num;
      for (var i = 1; i <= 12; i++) {
        final t = i / 12;
        b['x'] = x0 + (196 - x0) * t;
        b['y'] = y0 + (64 - y0) * t - math.sin(math.pi * t) * 40;
        await wait(host.TICK);
      }
      b['x'] = 196;
      b['y'] = 64;
      SFX.bonk();
      p['pose'] = 'idle';
      await wait(400);
    },
    // by the nest, in the air (code line 232: unchanged)
    'avesale': (o) async {
      await aveVa(184, 60, 5, 1);
      SFX.pio();
      await wait(400);
    },
    // the bird pecks the ball; it falls onto the frog's head and bounces over to Luis
    'avepica2': (o) async {
      final v = W['ave'] as Map<String, dynamic>,
          b = W['bola'] as Map<String, dynamic>,
          f = ranaXY(),
          l = G('luis')!;
      for (var k = 0; k < 2; k++) {
        v['dip'] = 3;
        SFX.pio();
        await wait(170);
        v['dip'] = 0;
        await wait(170);
      }
      final x0 = b['x'] as num, y0 = b['y'] as num;
      await wait(300);
      for (var i = 1; i <= 14; i++) {
        b['x'] = x0 + (f[0] - x0) * i / 14;
        b['y'] = y0 + (f[1] + 6 - y0) * (i / 14) * (i / 14);
        await wait(host.TICK);
      }
      SFX.bonk();
      host.bounce(7);
      await wait(700);
      await bolaA((l['x'] as num) - 12, l['y'] as num, 9);
      await wait(300);
    },
    // the ball goes round the three of them
    'pelota3': (o) async {
      final l = G('luis')!, ca = G('carmen')!, f = ranaXY();
      for (var k = 0; k < 2; k++) {
        l['pose'] = 'wave';
        await bolaA((ca['x'] as num) + 12, ca['y'] as num, 6);
        l['pose'] = 'idle';
        ca['pose'] = 'wave';
        await bolaA(f[0], f[1] + 10, 6);
        ca['pose'] = 'idle';
        host.bounce(6);
        await bolaA((l['x'] as num) - 12, l['y'] as num, 6);
      }
    },
    'llama': (o) async {
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'mama')!;
      p['pose'] = 'wave';
      await wait(600);
    },
    // someone goes in at the back door (sheet moves line 240: mueve(id,44,118) -> mueve(id,59,115), spot seva)
    'seva': (o) async {
      final at = _p.spot('seva');
      for (final id in '${o['quien']}'.split('+')) {
        final p = G(id);
        if (p == null) continue;
        p['pose'] = 'idle';
        if (id == 'mama' && G('bebe') != null) G('bebe')!['vis'] = 0;
        await mueve(id, at[0], at[1]);
        p['vis'] = 0;
        SFX.blip();
      }
    },
    'cierra': (o) async {
      W['pdoor'] = 0;
      SFX.slam();
      await wait(500);
    },
    'noche': (o) async {
      for (var i = 0; i <= 10; i++) {
        W['osc'] = .3 + .03 * i;
        await wait(host.TICK);
      }
      W['noche'] = 1;
      W['brillo'] = 1;
      await wait(500);
    },
    'aveduerme': (o) async {
      (W['ave'] as Map<String, dynamic>)['st'] = 'round';
      await wait(600);
    },
    // fireflies over the lawn (code line 244: the same screen places)
    'luzsale': (o) async {
      const P = [
        [70, 160],
        [150, 150],
        [112, 190],
      ];
      final luces = W['luces'] as List, i = luces.length;
      luces.add(<String, dynamic>{
        'id': 'l$i',
        'est': 'en',
        'x0': P[i % 3][0],
        'y0': P[i % 3][1],
      });
      SFX.luz();
      await wait(500);
    },
    'canta': (o) async {
      for (var k = 0; k < 3; k++) {
        SFX.coqui();
        host.bounce(6);
        await wait(700);
      }
      for (var k = 0; k < 3; k++) {
        for (final l in _ms(W['luces'])) {
          l['al'] = .25;
        }
        await wait(150);
        for (final l in _ms(W['luces'])) {
          l['al'] = 1;
        }
        await wait(220);
      }
    },
    'abreporton': (o) async {
      W['porton'] = 1;
      SFX.creak();
      await wait(600);
    },
    /* ---- story 10: the sack ---- */
    // sheet moves line 248: carmen:{x:50,y:160,...} -> carmen:{x:37,y:178,...} (code line 248: luis, the sack, the floor
    // rule)
    'inicio10': (o) async {
      camas();
      final lu = _p.floor(248, 190, 160),
          ca = _p.floor(248, 50, 160),
          sa = _p.floor(248, 164, 165);
      W['gente'] = <String, dynamic>{
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'sent': 1,
          'dir': 1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'idle',
          'dir': 1,
        },
      };
      W['saco'] = <String, dynamic>{'x': sa[0], 'y': sa[1], 'ab': 0};
      W['canasta'] = <dynamic>[];
      W['nido'] = <dynamic>[];
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR['puerta']!;
      q['x'] = L[0];
      q['y'] = L[1];
      q['s'] = L[2];
    },
    // the bird flies a loop over the tree and comes back to its nest (code line 250: the loop on the screen, unchanged;
    // the nest: points nido)
    'aveloop': (o) async {
      final v = W['ave'] as Map<String, dynamic>;
      v['mode'] = 'fly';
      SFX.pio();
      const cx = 150, cy = 40, r = 18;
      W['rizo'] = null;
      for (var i = 0; i <= 20; i++) {
        final an = -math.pi / 2 + math.pi * 2 * i / 20 + 1.2;
        v['x'] = cx + r * math.cos(an);
        v['y'] = cy + r * math.sin(an);
        v['dir'] = math.sin(an) < 0 ? 1 : -1;
        await wait(host.TICK);
      }
      W['rizo'] = <String, dynamic>{'x': cx, 'y': cy, 'r': r, 'f': F};
      await aveVa(_nido[0], _nido[1], 7, -1);
    },
    'avecabeza': (o) async {
      W['rizo'] = null;
      final f = ranaXY();
      await aveVa(f[0], f[1] - 2, 8);
      (W['ave'] as Map<String, dynamic>)['mode'] = 'head';
      (W['ave'] as Map<String, dynamic>)['st'] = 'feliz';
      SFX.pio();
      await wait(900);
    },
    // (points nido: code line 252)
    'avenido': (o) async {
      (W['ave'] as Map<String, dynamic>)['st'] = 'n';
      (W['ave'] as Map<String, dynamic>)['lleva'] = null;
      await aveVa(_nido[0], _nido[1], 8, -1);
    },
    'acaricia': (o) async {
      final who = jsTruthy(o['quien']) ? '${o['quien']}' : 'carmen',
          p = G(who)!;
      mira(who);
      p['pose'] = 'offer';
      p['dir'] = -(p['dir'] as num);
      p['bub'] = 'amor';
      SFX.blip();
      await wait(900);
      p['bub'] = null;
      p['pose'] = 'idle';
    },
    // Luis pulls a thing out of the sack and holds it up
    'saca': (o) async {
      final p = G('luis')!, saco = W['saco'] as Map<String, dynamic>;
      saco['ab'] = 1;
      SFX.blip();
      await wait(250);
      p['dir'] = 1;
      p['lleva'] = o['que'];
      p['pose'] = 'alto';
      saco['ab'] = 0;
      host.fx({
        't': 'star',
        'n': 6,
        'pts': [
          [_round(p['x'] as num) + 14, _round(p['y'] as num) - 58],
        ],
      });
      await wait(400);
    },
    // what Luis holds goes to Carmen's hair, or into the frog's basket
    'alpelo': (o) async {
      final p = G('luis')!, ca = G('carmen')!;
      if (!jsTruthy(p['lleva'])) return;
      p['lleva'] = null;
      p['pose'] = 'idle';
      await vuelaA(
        'flor',
        (p['x'] as num) + 14,
        (p['y'] as num) - 50,
        (ca['x'] as num) + 5,
        (ca['y'] as num) - 40,
      );
      ca['pelo'] = 1;
      SFX.luz();
      await wait(400);
    },
    'alcanasta': (o) async {
      final de = jsTruthy(o['de']) ? '${o['de']}' : 'luis',
          p = G(de),
          f = ranaXY();
      if (de == 'cq') {
        if (!jsTruthy(W['lleva'])) return;
        final k = W['lleva'];
        await wait(200);
        W['lleva'] = null;
        (W['canasta'] as List).add(k);
        SFX.luz();
        host.fx({
          't': 'star',
          'n': 8,
          'pts': [
            [f[0] + 12, f[1] + 12],
          ],
        });
        await wait(500);
        return;
      }
      if (p == null || !jsTruthy(p['lleva'])) return;
      final k = p['lleva'] as String;
      p['lleva'] = null;
      p['encima'] = null;
      p['pose'] = 'idle';
      await vuelaA(
        k,
        p['x'] as num,
        (p['y'] as num) - 40,
        f[0] + 12,
        f[1] + 12,
      );
      (W['canasta'] as List).add(k);
      SFX.luz();
      host.fx({
        't': 'star',
        'n': 8,
        'pts': [
          [f[0] + 12, f[1] + 12],
        ],
      });
      await wait(500);
    },
    // the frog's turn at the sack: he pulls something out and does not know what it is
    'turno': (o) async {
      final q = W['cq'] as Map<String, dynamic>,
          saco = W['saco'] as Map<String, dynamic>;
      saco['ab'] = 1;
      await ir('luis');
      SFX.blip();
      await wait(300);
      W['lleva'] = o['que'];
      saco['ab'] = 0;
      host.bounce(5);
      await wait(300);
      q['bub'] = 'q';
      SFX.coqui();
      await wait(1000);
      q['bub'] = null;
    },
    'quita': (o) async {
      (W['cq'] as Map<String, dynamic>)['bub'] = null;
    },
    // the frog hands what he holds to Carmen
    'acarmen': (o) async {
      final ca = G('carmen')!, f = ranaXY(), k = W['lleva'];
      if (!jsTruthy(k)) return;
      W['lleva'] = null;
      await vuelaA(
        k as String,
        f[0],
        f[1],
        ca['x'] as num,
        (ca['y'] as num) - 24,
      );
      ca['lleva'] = k;
      ca['pose'] = 'ojos';
      SFX.blip();
      await wait(300);
    },
    // the bird comes down and pulls at the sack; from now on the two scores show
    'avepica': (o) async {
      final saco = W['saco'] as Map<String, dynamic>;
      await aveVa((saco['x'] as num) - 2, (saco['y'] as num) - 20, 9, 1);
      final ave = W['ave'] as Map<String, dynamic>;
      for (var k = 0; k < 3; k++) {
        ave['dip'] = 3;
        SFX.pio();
        saco['x'] = (saco['x'] as num) + 1;
        await wait(170);
        ave['dip'] = 0;
        saco['x'] = (saco['x'] as num) - 1;
        await wait(170);
      }
    },
    'marcador': (o) async {
      W['tanteo'] = 1;
      SFX.luz();
      await wait(600);
    },
    // decision A: Carmen across the yard with the glass; the frog back at the door (code line 270: the floor rule)
    'prepA': (o) async {
      final ca = G('carmen')!, at = _p.floor(270, 150, 140);
      await Future.wait([mueve('carmen', at[0], at[1]), ir('puerta')]);
      ca['dir'] = -1;
      ca['pose'] = 'ojos';
      if (!jsTruthy(ca['lleva'])) ca['lleva'] = 'vaso';
      await wait(200);
    },
    // she said ven and he came: the glass goes in his basket (or her hands are empty, and she laughs)
    'llega': (o) async {
      final ca = G('carmen')!;
      await ir('carmenA');
      if (jsTruthy(ca['lleva'])) {
        await acts['alcanasta']!({'de': 'carmen'});
      } else {
        ca['pose'] = 'ojos';
        await acts['rie']!({'quien': 'carmen'});
        ca['pose'] = 'idle';
      }
    },
    // she said mira and he looked: she spins with the glass on her head, bows, and brings it over
    'gira': (o) async {
      final ca = G('carmen')!,
          k = ca['lleva'],
          q = W['cq'] as Map<String, dynamic>;
      q['ojos'] = 1;
      q['ojx'] = 1;
      q['ojy'] = 0;
      ca['lleva'] = null;
      ca['encima'] = k;
      ca['pose'] = 'idle';
      for (var i = 0; i < 8; i++) {
        ca['dir'] = -_dir(ca);
        SFX.blip();
        await wait(130);
      }
      ca['dir'] = -1;
      host.fx({
        't': 'star',
        'n': 10,
        'pts': [
          [_round(ca['x'] as num), _round(ca['y'] as num) - 54],
        ],
      });
      ca['rie'] = 1;
      await wait(500);
      ca['rie'] = 0;
      q['ojos'] = 0;
      if (jsTruthy(k)) {
        ca['encima'] = null;
        ca['lleva'] = k;
        ca['pose'] = 'ojos';
        final b = frogBox(q);
        if ((b.x + b.w / 2 - (ca['x'] as num)).abs() > 40) {
          await mueve('carmen', b.x + b.w + 16, b.y + b.h + 2);
        }
        await acts['alcanasta']!({'de': 'carmen'});
      }
    },
    // wrong: he only looked. She waits, arm out; the bird takes the glass.
    'mirasolo': (o) async {
      final ca = G('carmen')!, q = W['cq'] as Map<String, dynamic>;
      q['ojos'] = 1;
      q['ojx'] = 1;
      q['ojy'] = 0;
      ca['pose'] = 'offer';
      ca['dir'] = 1;
      await wait(900);
      await acts['roba']!({'de': 'carmen'});
      q['ojos'] = 0;
      ca['pose'] = 'idle';
      ca['dir'] = -1;
    },
    // wrong: he hopped over as she began her spin. A bump; the glass flies up; the bird catches it.
    'choca': (o) async {
      final ca = G('carmen')!, k = ca['lleva'];
      ca['lleva'] = null;
      ca['encima'] = k;
      ca['pose'] = 'idle';
      ca['dir'] = 1;
      await ir('carmenA');
      SFX.bonk();
      ca['rie'] = 1;
      host.bounce(5);
      ca['encima'] = null;
      final v = <String, dynamic>{
        'k': k,
        'x': ca['x'],
        'y': (ca['y'] as num) - 50,
        's': 1.4,
      };
      W['vuela'] = v;
      Future<void> flyUp() async {
        for (var i = 1; i <= 6; i++) {
          v['y'] = (ca['y'] as num) - 50 - i * 5;
          await wait(host.TICK);
        }
      }

      final fly = flyUp();
      await Future.wait([fly, aveVa(ca['x'] as num, (ca['y'] as num) - 84, 7)]);
      W['vuela'] = null;
      ca['rie'] = 0;
      (W['ave'] as Map<String, dynamic>)['lleva'] = k;
      SFX.pio();
      await wait(250);
      await acts['alnido']!({});
      ca['dir'] = -1;
    },
    // the bird snatches what someone holds and takes it to its nest
    'roba': (o) async {
      final de = '${o['de']}',
          p = de == 'cq' ? null : G(de),
          f = ranaXY(),
          k = p != null ? p['lleva'] : W['lleva'];
      if (!jsTruthy(k)) return;
      final List<num> at = p != null
          ? [
              (p['x'] as num) +
                  (p['pose'] == 'alto'
                      ? (_dir(p) < 0 ? -14 : 14)
                      : p['pose'] == 'offer'
                      ? -(_dir(p) < 0 ? -1 : 1) * 20
                      : 0),
              (p['y'] as num) -
                  (p['pose'] == 'alto' ? alto(de) : alto(de) - 24),
            ]
          : [f[0], f[1] - 8];
      await aveVa(at[0], at[1], 8);
      if (p != null) {
        p['lleva'] = null;
        if (p['pose'] == 'alto') p['pose'] = 'idle';
      } else {
        W['lleva'] = null;
      }
      (W['ave'] as Map<String, dynamic>)['lleva'] = k;
      SFX.pio();
      await wait(200);
      await acts['alnido']!({});
    },
    // (points nido: code line 284)
    'alnido': (o) async {
      final ave = W['ave'] as Map<String, dynamic>, k = ave['lleva'];
      await aveVa(_nido[0], _nido[1], 9, -1);
      ave['lleva'] = null;
      if (jsTruthy(k)) (W['nido'] as List).add(k);
      SFX.drop();
      await wait(300);
    },
    'encoge': (o) async {
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'luis')!;
      p['bub'] = 'q';
      await wait(800);
      p['bub'] = null;
    },
    // the stars of a happy ending (code line 287: a screen effect, in the sky: unchanged)
    'final10': (o) async {
      final mio = (W['canasta'] as List).length, f = ranaXY();
      (W['saco'] as Map<String, dynamic>)['ab'] = 0;
      G('luis')!['pose'] = 'idle';
      G('luis')!['lleva'] = null;
      if (mio >= 3) {
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 36,
          'pts': const [
            [60, 40],
            [150, 44],
            [104, 30],
            [80, 60],
            [130, 56],
          ],
        });
        await wait(1000);
      } else if (mio != 0) {
        SFX.win();
        await wait(700);
      } else {
        SFX.coqui();
        await wait(700);
      }
      final nido = W['nido'] as List,
          k = nido.isNotEmpty ? nido.removeLast() : 'flor',
          ave = W['ave'] as Map<String, dynamic>;
      ave['lleva'] = k;
      ave['st'] = 'feliz';
      await aveVa(f[0] + 14, f[1] - 6, 10);
      ave['lleva'] = null;
      (W['canasta'] as List).add(k);
      SFX.luz();
      host.fx({
        't': 'star',
        'n': 8,
        'pts': [
          [f[0] + 12, f[1] + 12],
        ],
      });
      await wait(500);
      await aveVa(f[0], f[1] - 2, 4);
      ave['mode'] = 'head';
      await wait(500);
    },
    /* ---- story 11: going home ---- */
    // sheet moves line 290: abuela [34,136] -> [46,136], abuelo [60,126] -> [70,129], mama [86,136] -> [92,136], bebe
    // [97,109] -> [103,109] (z 137, in mamá's arms), papa [112,126] -> [114,136]; line 291: luis [150,160] -> [178,126],
    // carmen [188,158] -> [200,168], and W.respEn=[164,4] (the answer cards in the sky); the bird on the fence (points
    // cerca.ave)
    'inicio11': (o) async {
      camas();
      final ab = _p.floor(290, 34, 136),
          au = _p.floor(290, 60, 126),
          ma = _p.floor(290, 86, 136),
          be = _p.floor(290, 97, 109),
          pa = _p.floor(290, 112, 126),
          lu = _p.floor(291, 150, 160),
          ca = _p.floor(291, 188, 158);
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': ab[0],
          'y': ab[1],
          'pose': 'idle',
          'dir': 1,
        },
        'abuelo': <String, dynamic>{
          'x': au[0],
          'y': au[1],
          'pose': 'ojos',
          'lleva': 'bizcocho',
          'dir': 1,
        },
        'mama': <String, dynamic>{'x': ma[0], 'y': ma[1], 'pose': 'idle'},
        'bebe': <String, dynamic>{
          'x': be[0],
          'y': be[1],
          'z': _p.floorZ(290, 97, 109),
          'est': 'idle',
        },
        'papa': <String, dynamic>{'x': pa[0], 'y': pa[1], 'pose': 'idle'},
        'luis': <String, dynamic>{
          'x': lu[0],
          'y': lu[1],
          'pose': 'idle',
          'dir': -1,
        },
        'carmen': <String, dynamic>{
          'x': ca[0],
          'y': ca[1],
          'pose': 'alto',
          'dir': -1,
        },
      };
      W['pdoor'] = 1;
      W['respEn'] = _p.respEn(291);
      W['sol'] = 3;
      W['soly'] = SOLY[3];
      W['osc'] = .12;
      W['ave'] = <String, dynamic>{
        'mode': 'sit',
        'x': _cercaAve[0],
        'y': _cercaAve[1],
        'dir': -1,
        'st': 'n',
      };
      W['luces'] = <dynamic>[
        <String, dynamic>{'id': 'carmen', 'est': 'en'},
        <String, dynamic>{'id': 'abuelo', 'est': 'en'},
        <String, dynamic>{'id': 'medio', 'est': 'en', 'x0': 120, 'y0': 156},
      ];
    },
    'puesta': (o) async {
      for (var i = 0; i <= 12; i++) {
        W['soly'] = SOLY[3] + i * 3;
        W['osc'] = .12 + .015 * i;
        await wait(host.TICK);
      }
      W['estrella'] = 1;
      SFX.luz();
      await wait(600);
    },
    // two go to the gate together, side by side (sheet moves line 295: mueve(id,170,124) -> mueve(id,165,116), spot
    // juntos)
    'juntos': (o) async {
      final id = jsTruthy(o['quien']) ? '${o['quien']}' : 'luis',
          p = G(id)!,
          at = _p.spot('juntos');
      p['pose'] = 'idle';
      await Future.wait([mueve(id, at[0], at[1]), ir('porton')]);
      p['dir'] = -1;
    },
    // (code line 296: the floor rule)
    'vuelveluis': (o) async {
      final at = _p.floor(296, 138, 138);
      await mueve('luis', at[0], at[1]);
      G('luis')!['dir'] = 1;
    },
    // (code line 297: the floor rule for its default; a place from the story file through the sheet's remap)
    'alcentro': (o) async {
      final who = '${o['quien']}', p = G(who), d = _p.floor(297, 160, 190);
      final x = _plusOr(o['x'], d[0]), y = _plusOr(o['y'], d[1]);
      final at = jsTruthy(o['x']) || jsTruthy(o['y']) ? remap([x, y]) : [x, y];
      await Future.wait([mueve(who, at[0], at[1]), ir('centro')]);
      p!['dir'] = -1;
    },
    'junto': (o) async {
      final who = '${o['quien']}',
          p = G(who)!,
          b = frogBox(W['cq'] as Map<String, dynamic>);
      await mueve(who, b.x + b.w + 14, b.y + b.h + 2);
      p['dir'] = -1;
    },
    'oscurece': (o) async {
      for (var i = 0; i <= 10; i++) {
        W['osc'] = .3 + .03 * i;
        await wait(host.TICK);
      }
      W['noche'] = 1;
      W['brillo'] = 1;
      SFX.luz();
      await wait(300);
      W['tarjeta'] = 'luces';
      await wait(500);
    },
    // someone comes up to the frog for a goodbye: Carmen from the right, abuelo from the left (code line 301: the floor
    // rule)
    'viene': (o) async {
      if (o['quien'] == 'carmen') {
        final at = _p.floor(301, 186, 174);
        await mueve('carmen', at[0], at[1]);
        G('carmen')!['dir'] = -1;
        G('carmen')!['pose'] = 'alto';
      } else {
        final at = _p.floor(301, 52, 174);
        await mueve('abuelo', at[0], at[1]);
        G('abuelo')!['dir'] = 1;
        G('abuelo')!['pose'] = 'ojos';
      }
    },
    // that one's firefly comes to the frog, for good (if it has not gone)
    'luz': (o) async {
      Map<String, dynamic>? l;
      for (final x in _ms(W['luces'])) {
        if (x['id'] == o['cual']) {
          l = x;
          break;
        }
      }
      if (l == null || l['est'] != 'en') return;
      final f = ranaXY();
      await luzA(l, f[0] + 12, f[1] - 8, 10);
      l['est'] = 'con';
      SFX.luz();
      host.fx({
        't': 'star',
        'n': 6,
        'pts': [
          [f[0] + 12, f[1] - 8],
        ],
      });
      await wait(350);
    },
    'toma': (o) async {
      final p = G('abuelo')!, f = ranaXY();
      if (jsTruthy(p['lleva'])) {
        final k = p['lleva'] as String;
        p['lleva'] = null;
        p['pose'] = 'idle';
        await vuelaA(k, p['x'] as num, (p['y'] as num) - 24, f[0], f[1] - 2);
        W['lleva'] = k;
        SFX.blip();
        await wait(400);
      }
    },
    'guarda': (o) async {
      W['lleva'] = null;
    },
    'duda': (o) async {
      final p = o['quien'] == 'cq'
          ? W['cq'] as Map<String, dynamic>
          : G('${o['quien']}')!;
      p['bub'] = 'q';
      if (o['quien'] == 'cq') SFX.coqui();
      await wait(700);
      p['bub'] = null;
    },
    'abrazo': (o) async {
      final p = G('luis')!, q = W['cq'] as Map<String, dynamic>;
      p['pose'] = 'offer';
      p['dir'] = 1;
      q['bub'] = 'amor';
      SFX.coqui();
      host.bounce(5);
      await wait(800);
      q['bub'] = null;
      p['pose'] = 'idle';
    },
    // (sheet moves line 308: mueve("luis",170,124,8) -> mueve("luis",165,116,8), spot juntos)
    'luiscorre': (o) async {
      final at = _p.spot('juntos');
      await mueve('luis', at[0], at[1], 8);
      G('luis')!['dir'] = -1;
    },
    'abre': (o) async {
      final p = G('luis')!;
      p['pose'] = 'offer';
      p['dir'] = 1;
      await wait(250);
      W['porton'] = 1;
      SFX.creak();
      await wait(500);
      p['pose'] = 'idle';
    },
    'adios': (o) async {
      for (final id in const [
        'abuela',
        'abuelo',
        'mama',
        'papa',
        'carmen',
        'luis',
      ]) {
        final p = G(id);
        if (p != null) {
          p['pose'] = 'wave';
          p['lleva'] = null;
        }
      }
      G('bebe')!['est'] = 'clap';
      SFX.pio();
      await wait(300);
    },
    // by the fireflies he has; then he sings and they blink back; with none, one comes out of the dark (code lines 313,
    // 316: the stars a screen effect, the firefly from 214, 120 over the yard: unchanged)
    'final11': (o) async {
      final con = _ms(W['luces']).where((l) => l['est'] == 'con').length;
      if (con >= 3) {
        W['aro'] = 1;
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 36,
          'pts': const [
            [110, 70],
            [170, 66],
            [140, 56],
            [124, 96],
            [160, 96],
          ],
        });
        await wait(1100);
      } else if (con != 0) {
        SFX.win();
        await wait(700);
      } else {
        await wait(700);
      }
      SFX.coqui();
      host.bounce(7);
      await wait(700);
      if (con != 0) {
        for (var k = 0; k < 3; k++) {
          W['brillo'] = 0;
          for (final l in _ms(W['luces'])) {
            if (l['est'] == 'con') l['al'] = .3;
          }
          await wait(150);
          for (final l in _ms(W['luces'])) {
            l['al'] = 1;
          }
          await wait(200);
        }
        W['brillo'] = 1;
      } else {
        final l = <String, dynamic>{
          'id': 'nueva',
          'est': 'mov',
          'x': 214,
          'y': 120,
          'al': 0,
        };
        (W['luces'] as List).add(l);
        final f = ranaXY();
        await luzA(l, f[0] + 12, f[1] - 8, 14, 1);
        l['est'] = 'con';
        SFX.luz();
        host.fx({
          't': 'star',
          'n': 6,
          'pts': [
            [f[0] + 12, f[1] - 8],
          ],
        });
        await wait(500);
      }
    },
    // out through the gate, the bird beside him (code line 318: the bird in the air, unchanged; the frog to LUGAR.sale,
    // moved: sheet moves line 86)
    'sevan': (o) async {
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR['sale']!;
      (W['ave'] as Map<String, dynamic>)['mode'] = 'fly';
      final av = aveA(150, 70, 10);
      await host.hopTo(L[0], L[1], 3, L[2]);
      await av;
      for (var i = 1; i <= 6; i++) {
        q['al'] = 1 - i / 6;
        for (final l in _ms(W['luces'])) {
          if (l['est'] == 'con') l['al'] = 1 - i / 8;
        }
        await wait(host.TICK);
      }
      q['vis'] = 0;
      for (final l in _ms(W['luces'])) {
        if (l['est'] == 'con') l['al'] = 0;
      }
      (W['ave'] as Map<String, dynamic>)['mode'] = 'none';
      await wait(500);
      host.tone(1500, 0, .11, 'sine', .04);
      host.tone(2300, .17, .2, 'sine', .04, 2750);
      await wait(900);
    },
  };

  // patio.js: stake
  // the thing at stake takes a step (code line 323: the firefly leaves to the top right, unchanged)
  @override
  Future<void> stake(int lost, int max, String en) async {
    final t = (S['stake'] as Map<String, dynamic>)['thing'];
    if (t == 'sol') {
      final y0 = W['soly'] as num, y1 = SOLY[math.min(3, lost)];
      SFX.drop();
      for (var i = 1; i <= 10; i++) {
        W['soly'] = y0 + (y1 - y0) * i / 10;
        await wait(host.TICK);
      }
      W['sol'] = math.min(3, lost);
      host.tone(300, 0, .25, 'triangle', .07, 150);
      await wait(500);
      return;
    }
    if (t == 'luces') {
      Map<String, dynamic>? l;
      for (final x in _ms(W['luces'])) {
        if (x['id'] == en) {
          l = x;
          break;
        }
      }
      if (l != null && l['est'] == 'en') {
        SFX.drop();
        await luzA(l, 226, 58, 14, 0);
        l['est'] = 'ido';
      }
      await wait(300);
      return;
    }
    SFX.bonk();
    await wait(300);
  }

  // patio.js: poke
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
    return null;
  }

  // patio.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if (g[k] != null && (g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}'
                '${jsTruthy(p['lleva']) ? '(${p['lleva']})' : ''}${jsTruthy(p['bub']) ? '[${p['bub']}]' : ''}';
          }(),
    ].join(' ');
    final fl = W['flores'] as Map<String, dynamic>;
    String ks(String k) => _ms(fl[k]).map((f) => _js(f['k'])).join();
    final canasta = W['canasta'];
    final q = W['cq'] as Map<String, dynamic>;
    return 'gente=$gente flores=L${ks('L')} R${ks('R')} sol=${_js(W['sol'])}'
        ' lleva=${jsTruthy(W['lleva']) ? W['lleva'] : '-'}'
        ' canasta=${jsTruthy(canasta) ? (canasta as List).join('+') : '-'}'
        ' nido=${((W['nido'] as List?) ?? const []).join('+')}'
        ' luces=${_ms(W['luces']).map((l) => '${l['id']}:${l['est']}').join(',')}'
        ' porton=${_js(W['porton'])} ojos=${_js(jsTruthy(q['ojos']) ? q['ojos'] : 0)}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A ground point (a person's feet, the frog's, the ball's) keeps its screen place (the sheet's
  // `new`; two of the stories' own the sheet moved); a point in the air keeps its screen numbers (`to.screen`); a point
  // that is no place (the frog's eyes' direction) is given back; a pair rectangle gives the crop of the pictures it was;
  // a level picture's rectangle or x gives itself back (the level pictures are the sheet's, whole).
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
}

/// One entry of patio.js's drawing list (`L`): the row it is sorted by and how it is drawn.
class PatioItem {
  PatioItem(this.y, this.d);

  final num y;
  final void Function() d;
}
